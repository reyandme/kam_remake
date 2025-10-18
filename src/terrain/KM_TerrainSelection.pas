unit KM_TerrainSelection;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math,
  Clipbrd,
  KromUtils,
  {$IFDEF MSWindows} Windows, {$ENDIF}
  KM_CommonClasses, KM_Points, KM_Terrain, KM_TerrainTypes, KM_TerrainPainter, KM_RenderPool, KM_ResTilesetTypes,
  KM_MapEdTypes, KM_Defaults;


type
  TKMSelectionEdit = (seNone, seNewRect, seResizeX1, seResizeY1, seResizeX2, seResizeY2, seMove);
  TKMSelectionMode = (smSelecting, smPasting);

  //*
  TKMFlipAxis = (faHorizontal, faVertical);

  TKMBufferData = record
                    BaseLayer: TKMTerrainLayer;
                    LayersCnt: Byte;
                    Layer: array [0..2] of TKMTerrainLayer;
                    Height: Byte;
                    Obj: Byte;
                    IsCustom: Boolean;
                    BlendingLvl: Byte;
                    TerKind: TKMTerrainKind; //Used for brushes
                    TileOverlay: TKMTileOverlay;
                    TileOwner: TKMHandID;
                    FieldAge: Byte;
                    CornOrWine: Byte; //Indicate Corn or Wine field placed on the tile (without altering terrain)
                    CornOrWineTerrain: Byte; //We use fake terrain for maped to be able delete or alter it if needed
                  end;

  TKMSelection = class
  private class var
    CF_MAPDATA: Word; // Our own custom clipboard format
  private
    fTerrainPainter: TKMTerrainPainter;
    fSelectionEdit: TKMSelectionEdit;
    fSelPrevX, fSelPrevY: Integer;

    fPasteTypes: TKMTerrainSelectionPasteTypeSet;
    fSelectionRectF: TKMRectF; //Cursor selection bounds (can have inverted bounds)
    fSelectionRect: TKMRect; //Tile-space selection, at least 1 tile
    fSelectionMode: TKMSelectionMode;
    fSelectionBuffer: array of array of TKMBufferData;
    fLandTemp: TKMLand;
    fLandMapEdTemp: TKMMapEdLand;
    fLandTerKindTemp: TKMLandTerKind;
    fLastTiles : array[0..MAX_MAP_SIZE - 1,0..MAX_MAP_SIZE - 1] of Integer;

    function CheckTilesAround(const aX, aY, aTile: Integer): Boolean;

    procedure TileToBuffer(const aTile: TKMTerrainTile; const aMapEdTile: TKMMapEdTerrainTile;
                           const aPaintedTile: TKMPainterTile; var aBuffer: TKMBufferData);
    procedure BufferToTile(const aLandLoc: TKMPoint;
                           var aTile: TKMTerrainTile; var aMapEdTile: TKMMapEdTerrainTile;
                           var aPaintedTile: TKMPainterTile; const aBuffer: TKMBufferData);
    procedure Selection_SyncCellRect;
    procedure CopyBufferToTempLand(aUpdateMainLand: Boolean = False; aUpdateAll: Boolean = True);
    procedure DuplicateLandToTemp;
    procedure SyncTempLand;

    procedure SetMainLands;
    procedure SetTempLands;
  public
    constructor Create(aTerrainPainter: TKMTerrainPainter);
    destructor Destroy; override;

    procedure Resize;
    procedure Start;
    function HasDataInBuffer: Boolean;
    procedure Prepare;
    procedure RefreshLand;
    procedure Cancel;
    procedure CopyLandToBuffer; //Copies the selected are into buffer
    procedure PasteBegin; //Pastes the area from buffer and lets move it with cursor
    procedure PasteApply; //Do the actual paste from buffer to terrain
    procedure PasteCancel;
    procedure Flip(aAxis: TKMFlipAxis);
    procedure IncludePasteType(aPasteType: TKMTerrainSelectionPasteType);
    procedure ExcludePasteType(aPasteType: TKMTerrainSelectionPasteType);
    procedure ChangeSelectionRectangle(aLeft, aTop, aRight, aBottom: Integer);

    procedure SetNiceCoal; //Do the actual paste from buffer to terrain

    function TileWithinPastePreview(aX, aY: Word): Boolean;
    procedure Paint(aLayer: TKMPaintLayer; const aClipRect: TKMRect);
  end;


implementation
uses
  SysUtils,
  KM_Resource, KM_ResTileset,
  KM_HandsCollection,
  KM_GameParams, KM_GameSettings,
  KM_Game, KM_Cursor, KM_RenderAux, KM_CommonUtils;


{ TKMSelection }
constructor TKMSelection.Create(aTerrainPainter: TKMTerrainPainter);
begin
  inherited Create;

  if CF_MAPDATA = 0 then
  begin
    {$IFDEF WDC}
    CF_MAPDATA := RegisterClipboardFormat(PWideChar('KaM Remake ' + string(GAME_REVISION) + ' Map Data'));
    {$ENDIF}
  end;

  fTerrainPainter := aTerrainPainter;
  fPasteTypes := [ptTerrain, ptHeight, ptObject, ptOverlay]; // All assets by default

  SetLength(fLandTerKindTemp, MAX_MAP_SIZE + 1, MAX_MAP_SIZE + 1);
end;


destructor TKMSelection.Destroy;
begin
  // Set gTerrain to default land, since our tempLand is going to be destroyed,
  // we can't leave gTerrain.Land pointing to nowhere
  SetMainLands;

  inherited;
end;


procedure TKMSelection.Selection_SyncCellRect;
begin
  //Convert RawRect values that can be inverted to tilespace Rect
  fSelectionRect.Left   := Trunc(Max(0, Math.Min(fSelectionRectF.Left, fSelectionRectF.Right)));
  fSelectionRect.Top    := Trunc(Max(0, Math.Min(fSelectionRectF.Top, fSelectionRectF.Bottom)));
  fSelectionRect.Right  := Ceil(Max3(0, fSelectionRectF.Left, fSelectionRectF.Right));
  fSelectionRect.Bottom := Ceil(Max3(0, fSelectionRectF.Top, fSelectionRectF.Bottom));
  //Selection must be at least one tile
  if fSelectionRect.Left = fSelectionRect.Right then Inc(fSelectionRect.Right);
  if fSelectionRect.Top = fSelectionRect.Bottom then Inc(fSelectionRect.Bottom);
end;


procedure TKMSelection.Resize;
var
  RectO, rectOld: TKMRect;
  CursorFloat: TKMPointF;
  CursorCell: TKMPoint;
  MoveX, MoveY: Integer;
begin
  //Last row/col of the map is not visible or selectable
  CursorFloat.X := EnsureRange(gCursor.Float.X, 0.1, gTerrain.MapX-1 - 0.1);
  CursorFloat.Y := EnsureRange(gCursor.Float.Y, 0.1, gTerrain.MapY-1 - 0.1);
  CursorCell.X := EnsureRange(gCursor.Cell.X, 1, gTerrain.MapX-1);
  CursorCell.Y := EnsureRange(gCursor.Cell.Y, 1, gTerrain.MapY-1);

  rectOld := KMRectGrow(fSelectionRect, 2);

  case fSelectionEdit of
    seNone:       ;
    seNewRect:    begin
                    fSelectionRectF.Right := CursorFloat.X;
                    fSelectionRectF.Bottom := CursorFloat.Y;
                  end;
    seResizeX1:   fSelectionRectF.Left := CursorFloat.X;
    seResizeY1:   fSelectionRectF.Top := CursorFloat.Y;
    seResizeX2:   fSelectionRectF.Right := CursorFloat.X;
    seResizeY2:   fSelectionRectF.Bottom := CursorFloat.Y;
    seMove:       begin
                    MoveX := CursorCell.X - fSelPrevX;
                    MoveY := CursorCell.Y - fSelPrevY;
                    //Don't allow the selection to be moved out of the map bounds
                    MoveX := EnsureRange(MoveX, -fSelectionRect.Left, gTerrain.MapX-1-fSelectionRect.Right);
                    MoveY := EnsureRange(MoveY, -fSelectionRect.Top, gTerrain.MapY-1-fSelectionRect.Bottom);
                    RectO := KMRectMove(fSelectionRect, MoveX, MoveY);
                    fSelectionRectF := KMRectF(RectO);

                    fSelPrevX := CursorCell.X;
                    fSelPrevY := CursorCell.Y;
                  end;
  end;

  Selection_SyncCellRect;

  if fSelectionMode = smPasting then
  begin
    DuplicateLandToTemp;
    CopyBufferToTempLand;
    // Update everything on old selection rect to fix old tempLand
    gTerrain.UpdateAll(rectOld);
  end;
end;


procedure TKMSelection.Start;
const
  EDGE = 0.25;
var
  CursorFloat: TKMPointF;
  CursorCell: TKMPoint;
begin
  //Last row/col of the map is not visible or selectable
  CursorFloat.X := EnsureRange(gCursor.Float.X, 0.1, gTerrain.MapX-1 - 0.1);
  CursorFloat.Y := EnsureRange(gCursor.Float.Y, 0.1, gTerrain.MapY-1 - 0.1);
  CursorCell.X := EnsureRange(gCursor.Cell.X, 1, gTerrain.MapX-1);
  CursorCell.Y := EnsureRange(gCursor.Cell.Y, 1, gTerrain.MapY-1);

  if fSelectionMode = smSelecting then
  begin
    if InRange(CursorFloat.Y, fSelectionRect.Top, fSelectionRect.Bottom)
    and (Abs(CursorFloat.X - fSelectionRect.Left) < EDGE) then
      fSelectionEdit := seResizeX1
    else
    if InRange(CursorFloat.Y, fSelectionRect.Top, fSelectionRect.Bottom)
    and (Abs(CursorFloat.X - fSelectionRect.Right) < EDGE) then
      fSelectionEdit := seResizeX2
    else
    if InRange(CursorFloat.X, fSelectionRect.Left, fSelectionRect.Right)
    and (Abs(CursorFloat.Y - fSelectionRect.Top) < EDGE) then
      fSelectionEdit := seResizeY1
    else
    if InRange(CursorFloat.X, fSelectionRect.Left, fSelectionRect.Right)
    and (Abs(CursorFloat.Y - fSelectionRect.Bottom) < EDGE) then
      fSelectionEdit := seResizeY2
    else
    if KMInRect(CursorFloat, fSelectionRect) then
    begin
      fSelectionEdit := seMove;
      fSelPrevX := CursorCell.X;
      fSelPrevY := CursorCell.Y;
    end
    else
    begin
      fSelectionEdit := seNewRect;
      fSelectionRectF := KMRectF(CursorFloat);
      Selection_SyncCellRect;
    end;
  end
  else
  begin
    if KMInRect(CursorFloat, fSelectionRect) then
    begin
      fSelectionEdit := seMove;
      //Grab and move
      fSelPrevX := CursorCell.X;
      fSelPrevY := CursorCell.Y;
    end
    else
    begin
      fSelectionEdit := seMove;
      //Selection edge will jump to under cursor
      fSelPrevX := EnsureRange(CursorCell.X, fSelectionRect.Left + 1, fSelectionRect.Right);
      fSelPrevY := EnsureRange(CursorCell.Y, fSelectionRect.Top + 1, fSelectionRect.Bottom);
    end;
  end;
end;


procedure TKMSelection.TileToBuffer(const aTile: TKMTerrainTile; const aMapEdTile: TKMMapEdTerrainTile;
                                    const aPaintedTile: TKMPainterTile; var aBuffer: TKMBufferData);
var
  L: Integer;
begin
  aBuffer.BaseLayer.Terrain  := aTile.BaseLayer.Terrain;
  aBuffer.BaseLayer.Rotation := aTile.BaseLayer.Rotation;
  aBuffer.BaseLayer.CopyCorners(aTile.BaseLayer);
  aBuffer.LayersCnt   := aTile.LayersCnt;
  aBuffer.Height      := aTile.Height;
  aBuffer.Obj         := aTile.Obj;
  aBuffer.IsCustom    := aTile.IsCustom;
  aBuffer.BlendingLvl := aTile.BlendingLvl;
  aBuffer.TerKind     := aPaintedTile.TerKind;
  aBuffer.TileOverlay := aTile.TileOverlay;
  aBuffer.TileOwner   := aTile.TileOwner;
  aBuffer.FieldAge    := aTile.FieldAge;
  aBuffer.CornOrWine  := aMapEdTile.CornOrWine;
  aBuffer.CornOrWineTerrain := aMapEdTile.CornOrWineTerrain;
  for L := 0 to 2 do
  begin
    aBuffer.Layer[L].Terrain  := aTile.Layer[L].Terrain;
    aBuffer.Layer[L].Rotation := aTile.Layer[L].Rotation;
    aBuffer.Layer[L].CopyCorners(aTile.Layer[L]);
  end;
end;


procedure TKMSelection.BufferToTile(const aLandLoc: TKMPoint; var aTile: TKMTerrainTile; var aMapEdTile: TKMMapEdTerrainTile;
                                    var aPaintedTile: TKMPainterTile; const aBuffer: TKMBufferData);
var
  L: Integer;
begin
  if ptTerrain in fPasteTypes then
  begin
    aTile.BaseLayer.Terrain := aBuffer.BaseLayer.Terrain;
    aTile.BaseLayer.Rotation := aBuffer.BaseLayer.Rotation;
    aTile.BaseLayer.CopyCorners(aBuffer.BaseLayer);
    aTile.LayersCnt       := aBuffer.LayersCnt;
    aTile.IsCustom        := aBuffer.IsCustom;
    aTile.BlendingLvl     := aBuffer.BlendingLvl;
    for L := 0 to 2 do
    begin
      aTile.Layer[L].Terrain  := aBuffer.Layer[L].Terrain;
      aTile.Layer[L].Rotation := aBuffer.Layer[L].Rotation;
      aTile.Layer[L].CopyCorners(aBuffer.Layer[L]);
    end;
    aPaintedTile.TerKind  := aBuffer.TerKind;
  end;

  if ptHeight in fPasteTypes then
    aTile.Height := aBuffer.Height;

  if ptOverlay in fPasteTypes then
  begin
    aTile.TileOverlay     := aBuffer.TileOverlay;
    aTile.TileOwner       := aBuffer.TileOwner;
    aTile.FieldAge        := aBuffer.FieldAge;
    aMapEdTile.CornOrWine  := aBuffer.CornOrWine;
    aMapEdTile.CornOrWineTerrain := aBuffer.CornOrWineTerrain;
  end;

  // Check Object last, as we also want to copy object in case of corn / wine objects
  // since we don't allow corn (stage 4-5) or wine fields without objects
  if (ptObject in fPasteTypes)
    or gTerrain.TileIsCornField(aLandLoc)
    or gTerrain.TileIsWineField(aLandLoc) then
    aTile.Obj := aBuffer.Obj;
end;


function TKMSelection.HasDataInBuffer: Boolean;
begin
  Result := Clipboard.HasFormat(CF_MAPDATA);
end;


function TKMSelection.CheckTilesAround(const aX, aY, aTile: Integer): Boolean;
var
  A,B,C,D: Integer;
begin
  Result := False;

  A := fSelectionRect.Left;
  B := fSelectionRect.Right;
  C := fSelectionRect.Top;
  D := fSelectionRect.Bottom;

  if    (fLastTiles[EnsureRange(aX-1, A, B), aY]                      = aTile)
    and (fLastTiles[EnsureRange(aX+1, A, B), aY]                      = aTile)
    and (fLastTiles[aX,                      EnsureRange(aY-1, C, D)] = aTile)
    and (fLastTiles[aX,                      EnsureRange(aY+1, C, D)] = aTile) then
    Result := True;
end;


procedure TKMSelection.DuplicateLandToTemp;
var
  I, K: Integer;
begin
  // Copy land to temp array
  // todo: optimise copying process
  for I := 1 to gTerrain.MapY do
    for K := 1 to gTerrain.MapX do
    begin
      fLandTemp[I,K] := gTerrain.MainLand^[I,K];
      fLandMapEdTemp[I,K] := gGame.MapEditor.MainLandMapEd^[I,K];
    end;

  for I := 0 to gTerrain.MapY do
    fLandTerKindTemp[I] := Copy(gGame.TerrainPainter.MainLandTerKind[I], 0, gTerrain.MapX + 1);
end;


procedure TKMSelection.Prepare;
begin
  fSelectionMode := smSelecting;

  DuplicateLandToTemp;
end;


procedure TKMSelection.RefreshLand;
begin
  DuplicateLandToTemp; // gTerrain.MainLand was altered outside of this module (f.e. via MapEd.History)
  // Copy Buffer onto TempLand only while pasting
  if fSelectionMode = smPasting then
    CopyBufferToTempLand(False, False); // Do not update terrain, since we are going to make full update

  // Update all on TempLand
  gTerrain.UpdateAll;
end;


procedure TKMSelection.Cancel;
begin
  SetMainLands;
  gTerrain.UpdateAll;
end;


//Copy terrain section into buffer
procedure TKMSelection.CopyLandToBuffer;
var
  I, K: Integer;
  Sx, Sy: Word;
  Bx, By: Word;
  {$IFDEF WDC}
    hMem: THandle;
    BufPtr: Pointer;
  {$ENDIF}
  BufferStream: TKMemoryStream;
begin
  Sx := fSelectionRect.Right - fSelectionRect.Left + 1; // Add +1 for the last col (we save vertex Height from there)
  Sy := fSelectionRect.Bottom - fSelectionRect.Top + 1; // Add +1 for the last row (we save vertex Height from there)
  SetLength(fSelectionBuffer, Sy, Sx);

  BufferStream := TKMemoryStreamBinary.Create;
  BufferStream.Write(Sx);
  BufferStream.Write(Sy);

  for I := fSelectionRect.Top to fSelectionRect.Bottom do
    for K := fSelectionRect.Left to fSelectionRect.Right do
      if gTerrain.VerticeInMapCoords(K+1, I+1) then
      begin
        Bx := K - fSelectionRect.Left;
        By := I - fSelectionRect.Top;
        if InRange(I, 0, fSelectionRect.Bottom - 1) and InRange(K, 0, fSelectionRect.Right - 1) then
        begin
          TileToBuffer(gTerrain.MainLand^[I+1, K+1], gGame.MapEditor.MainLandMapEd^[I+1, K+1], fTerrainPainter.LandTerKind[I+1, K+1],
                       fSelectionBuffer[By,Bx]);
          BufferStream.Write(fSelectionBuffer[By,Bx], SizeOf(fSelectionBuffer[By,Bx]));
        end
        else
        begin
          // Write last row/col height into buffer
          fSelectionBuffer[By,Bx].Height := gTerrain.MainLand^[I+1, K+1].Height;
          // Write all tile anyway, for simplicity. Saving ~20 bytes does not make sense
          BufferStream.Write(fSelectionBuffer[By,Bx], SizeOf(fSelectionBuffer[By,Bx]));
        end;
      end;

  // Sx and Sy has +1 sizes of selectionRect
  if (Sx - 1)*(Sy - 1) <> 0 then
  begin
    {$IFDEF WDC}
    hMem := GlobalAlloc(GMEM_DDESHARE or GMEM_MOVEABLE, BufferStream.Size);
    BufPtr := GlobalLock(hMem);
    Move(BufferStream.Memory^, BufPtr^, BufferStream.Size);
    Clipboard.SetAsHandle(CF_MAPDATA, hMem);
    GlobalUnlock(hMem);
    {$ENDIF}
    {$IFDEF FPC}
    Clipboard.SetFormat(CF_MAPDATA, BufferStream);
    {$ENDIF}
  end;
  BufferStream.Free;
end;


procedure TKMSelection.PasteBegin;
var
  I, K: Integer;
  Sx, Sy: Word;
  {$IFDEF WDC}
  hMem: THandle;
  BufPtr: Pointer;
  {$ENDIF}
  BufferStream: TKMemoryStream;
begin
  BufferStream := TKMemoryStreamBinary.Create;
  {$IFDEF WDC}
  hMem := Clipboard.GetAsHandle(CF_MAPDATA);
  if hMem = 0 then Exit;
  BufPtr := GlobalLock(hMem);
  if BufPtr = nil then Exit;
  BufferStream.WriteBuffer(BufPtr^, GlobalSize(hMem));
  GlobalUnlock(hMem);
  {$ENDIF}
  {$IFDEF FPC}
  if not Clipboard.GetFormat(CF_MAPDATA, BufferStream) then Exit;
  {$ENDIF}
  BufferStream.Position := 0;
  BufferStream.Read(Sx);
  BufferStream.Read(Sy);
  SetLength(fSelectionBuffer, Sy, Sx);

  for I := 0 to Sy - 1 do
    for K := 0 to Sx - 1 do
      BufferStream.Read(fSelectionBuffer[I,K], SizeOf(fSelectionBuffer[I,K]));
  BufferStream.Free;

  // Mapmaker could have changed selection rect, sync it with Buffer size
  // SelectionRect does not contain last row / col, which we use to save height there
  fSelectionRect.Right := fSelectionRect.Left + Length(fSelectionBuffer[0]) - 1;
  fSelectionRect.Bottom := fSelectionRect.Top + Length(fSelectionBuffer) - 1;

  fSelectionMode := smPasting;

  SetTempLands;

  SyncTempLand;
end;


procedure TKMSelection.SetMainLands;
begin
  gTerrain.SetMainLand;
  gGame.MapEditor.SetMainLandMapEd;
  gGame.TerrainPainter.SetMainLandTerKind;
end;


procedure TKMSelection.SetTempLands;
begin
  gTerrain.Land := @fLandTemp;
  gGame.MapEditor.LandMapEd := @fLandMapEdTemp;
  gGame.TerrainPainter.LandTerKind := fLandTerKindTemp;
end;


procedure TKMSelection.PasteApply;
begin
  CopyBufferToTempLand(True); //Update MainLand as well, since we are doing Paste

  SetMainLands;

  // Update terrain kind info
  // fSelectionRect - [0..255,0..255], but TerKindInfo - [1..256,1..256])
  gGame.TerrainPainter.FixTerrainKindInfo(KMRectMove(fSelectionRect, 1, 1));

  gTerrain.UpdateAll(fSelectionRect);

  fSelectionMode := smSelecting;
end;


procedure TKMSelection.PasteCancel;
begin
  fSelectionMode := smSelecting;

  DuplicateLandToTemp;

  gTerrain.UpdateAll;
end;


procedure TKMSelection.Flip(aAxis: TKMFlipAxis);

  procedure SwapLayers(var Layer1, Layer2: TKMTerrainLayer);
  begin
    SwapInt(Layer1.Terrain, Layer2.Terrain);
    SwapInt(Layer1.Rotation, Layer2.Rotation);
    Layer1.SwapCorners(Layer2);
  end;

  function IsCornOrWineWithObj(aX, aY: Integer): Boolean;
  var
    P: TKMPoint;
  begin
    P := KMPoint(aX, aY);
    Result := (gTerrain.TileIsCornField(P) and (gTerrain.Land^[aY,aX].Obj in [CORN_STAGE5_OBJ_ID, CORN_STAGE6_OBJ_ID]))
            or gTerrain.TileIsWineField(P);
  end;

  procedure SwapTiles(X1, Y1, X2, Y2: Word);
    procedure SwapHeight(aX1, aY1, aX2, aY2: Word);
    var
      tmpHeight: Integer;
    begin
      tmpHeight := gTerrain.Land^[aY1,aX1].Height;
      gTerrain.Land^[aY1,aX1].Height := gTerrain.Land^[aY2,aX2].Height;
      gTerrain.Land^[aY2,aX2].Height := tmpHeight;
      gTerrain.UpdateRenderHeight(aX1, aY1);
      gTerrain.UpdateRenderHeight(aX2, aY2);
    end;

  var
    L: Integer;
    swapObj, skipObj, cornOrWineWObj: Boolean;
    tmpTerKind: TKMTerrainKind;
    tmpOverlay: TKMTileOverlay;
  begin
    if ptTerrain in fPasteTypes then
    begin
      SwapLayers(gTerrain.Land^[Y1,X1].BaseLayer, gTerrain.Land^[Y2,X2].BaseLayer);
      SwapInt(gTerrain.Land^[Y1,X1].LayersCnt, gTerrain.Land^[Y2,X2].LayersCnt);
      SwapInt(gTerrain.Land^[Y1,X1].BlendingLvl, gTerrain.Land^[Y2,X2].BlendingLvl);
      SwapBool(gTerrain.Land^[Y1,X1].IsCustom, gTerrain.Land^[Y2,X2].IsCustom);
      for L := 0 to 2 do
        SwapLayers(gTerrain.Land^[Y1,X1].Layer[L], gTerrain.Land^[Y2,X2].Layer[L]);

      tmpTerKind := fTerrainPainter.LandTerKind[Y1, X1].TerKind;
      fTerrainPainter.LandTerKind[Y1, X1].TerKind := fTerrainPainter.LandTerKind[Y2, X2].TerKind;
      fTerrainPainter.LandTerKind[Y2, X2].TerKind := tmpTerKind;
    end;

    if ptHeight in fPasteTypes then
      //Heights are vertex based not tile based, so it gets flipped slightly differently
      case aAxis of
        faHorizontal: SwapHeight(X1, Y1, X2+1, Y2);
        faVertical:   SwapHeight(X1, Y1, X2,   Y2+1);
      end;

    swapObj := False;
    skipObj := False;
    cornOrWineWObj := IsCornOrWineWithObj(X1, Y1) or IsCornOrWineWithObj(X2, Y2);

    if ptOverlay in fPasteTypes then
    begin
      tmpOverlay := gTerrain.Land^[Y1,X1].TileOverlay;
      gTerrain.Land^[Y1,X1].TileOverlay := gTerrain.Land^[Y2,X2].TileOverlay;
      gTerrain.Land^[Y2,X2].TileOverlay := tmpOverlay;

      SwapInt(gTerrain.Land^[Y1,X1].TileOwner, gTerrain.Land^[Y2,X2].TileOwner);
      SwapInt(gTerrain.Land^[Y1,X1].FieldAge, gTerrain.Land^[Y2,X2].FieldAge);

      if cornOrWineWObj then
        swapObj := True; // swap object of corn / wine field

      if (gGame.MapEditor <> nil) then
      begin
        SwapInt(gGame.MapEditor.LandMapEd^[Y1,X1].CornOrWine, gGame.MapEditor.LandMapEd^[Y2,X2].CornOrWine);
        SwapInt(gGame.MapEditor.LandMapEd^[Y1,X1].CornOrWineTerrain, gGame.MapEditor.LandMapEd^[Y2,X2].CornOrWineTerrain);
      end;
    end
    else
      // Do not swap object of corn / wine field
      skipObj := cornOrWineWObj;

    if not skipObj
      and (swapObj or (ptObject in fPasteTypes)) then
      SwapInt(gTerrain.Land^[Y1,X1].Obj, gTerrain.Land^[Y2,X2].Obj);
  end;

  procedure FixTerrain(X, Y: Integer);
    procedure FixLayer(var aLayer: TKMTerrainLayer; aFixRotation: Boolean);
    var
      I, J: Integer;
      rot: Byte;
      corners: array[0..3] of Integer;
    begin
      J := 0;

      for I := 0 to 3 do
        if aLayer.Corner[I] then
        begin
          corners[J] := I;
          Inc(J);
        end;

      // Lets try to get initial Rot from Corners information, if possible
      case J of
        0,4:  Exit;  //nothing to fix here
        1:    begin
                // For 1 corner - corner is equal to rotation
                rot := corners[0];
                if (rot in [0,2]) xor (aAxis = faVertical) then
                  rot := (rot+1) mod 4
                else
                  rot := (rot+3) mod 4;
                aLayer.SetCorners([rot]);
              end;
        2:    begin
                if Abs(corners[0] - corners[1]) = 2 then  //Opposite corners
                begin
                  if aFixRotation then
                    rot := aLayer.Rotation // for opposite corners its not possible to get rotation from corners, as 1 rot equal to 3 rot etc.
                  else
                    rot := corners[0];
                  // Fixed Rot is same as for 1 corner
                  if (rot in [0,2]) xor (aAxis = faVertical) then
                    rot := (rot+1) mod 4
                  else
                    rot := (rot+3) mod 4;
                  aLayer.SetCorners([(corners[0] + 1) mod 4, (corners[1] + 1) mod 4]); //no difference for +1 or +3, as they are same on (mod 4)
                end else begin
                  if (corners[0] = 0) and (corners[1] = 3) then // left vertical straight  = initial Rot = 3
                    rot := 3
                  else
                    rot := corners[0];
                  // Fixed Rot calculation
                  if (rot in [1,3]) xor (aAxis = faVertical) then
                  begin
                    rot := (rot+2) mod 4;
                    aLayer.SetCorners([(corners[0] + 2) mod 4, (corners[1] + 2) mod 4]);
                  end;
                end;
              end;
        3:    begin
                // Initial Rot - just go through all 4 possibilities
                if (corners[0] = 0) and (corners[2] = 3) then
                  rot := IfThen(corners[1] = 1, 0, 3)
                else
                  rot := Round((corners[0] + corners[2]) / 2);
                // Fixed Rot calculation same as for corner
                if (rot in [0,2]) xor (aAxis = faVertical) then
                  rot := (rot+1) mod 4
                else
                  rot := (rot+3) mod 4;
                aLayer.SetAllCorners;
                aLayer.Corner[(rot + 2) mod 4] := False; // all corners except opposite to rotation
              end;
        else  raise Exception.Create('Wrong number of corners');
      end;
      if aFixRotation then
        aLayer.Rotation := rot;
    end;

    procedure FixObject;
    const
      OBJ_MIDDLE_X = [8,9,54..61,80,81,212,213,215];
      OBJ_MIDDLE_Y = [8,9,54..61,80,81,212,213,215,  1..5,10..12,17..19,21..24,63,126,210,211,249..253];
    begin
      //Horizontal flip: Vertex (not middle) objects must be moved right by 1
      if (aAxis = faHorizontal) and (X < fSelectionRect.Right)
      and (gTerrain.Land^[Y,X+1].Obj = OBJ_NONE) and not (gTerrain.Land^[Y,X].Obj in OBJ_MIDDLE_X) then
      begin
        gTerrain.Land^[Y,X+1].Obj := gTerrain.Land^[Y,X].Obj;
        gTerrain.Land^[Y,X].Obj := OBJ_NONE;
      end;

      //Vertical flip: Vertex (not middle) objects must be moved down by 1
      if (aAxis = faVertical) and (Y < fSelectionRect.Bottom)
      and (gTerrain.Land^[Y+1,X].Obj = OBJ_NONE) and not (gTerrain.Land^[Y,X].Obj in OBJ_MIDDLE_Y) then
      begin
        gTerrain.Land^[Y+1,X].Obj := gTerrain.Land^[Y,X].Obj;
        gTerrain.Land^[Y,X].Obj := OBJ_NONE;
      end;
    end;

  const
    CORNERS_REVERSED = [15,21,142,234,235,238];

  var
    L: Integer;
    ter: Word;
    rot: Byte;
  begin
    if ptTerrain in fPasteTypes then
    begin
      ter := gTerrain.Land^[Y,X].BaseLayer.Terrain;
      rot := gTerrain.Land^[Y,X].BaseLayer.Rotation mod 4; //Some KaM maps contain rotations > 3 which must be fixed by modding

      //Edges
      if gRes.Tileset.TileIsEdge(ter) then
      begin
        if (rot in [1,3]) xor (aAxis = faVertical) then
          gTerrain.Land^[Y,X].BaseLayer.Rotation := (rot + 2) mod 4;
      end else
      //Corners
      if gRes.Tileset.TileIsCorner(ter) then
      begin
        if (rot in [1,3]) xor (ter in CORNERS_REVERSED) xor (aAxis = faVertical) then
          gTerrain.Land^[Y,X].BaseLayer.Rotation := (rot+1) mod 4
        else
          gTerrain.Land^[Y,X].BaseLayer.Rotation := (rot+3) mod 4;
      end
      else
      begin
        case aAxis of
          faHorizontal: begin
                          if ter <> ResTileset_MirrorTilesH[ter] then
                          begin
                            gTerrain.Land^[Y,X].BaseLayer.Terrain := ResTileset_MirrorTilesH[ter];
                            gTerrain.Land^[Y,X].BaseLayer.Rotation := (8 - rot) mod 4; // Rotate left (in the opposite direction to normal rotation)
                          end
                          else
                          if ter <> ResTileset_MirrorTilesV[ter] then
                          begin
                            gTerrain.Land^[Y,X].BaseLayer.Terrain := ResTileset_MirrorTilesV[ter];
                            // do not rotate mirrored tile on odd rotation
                            if (rot mod 2) = 0 then
                              gTerrain.Land^[Y,X].BaseLayer.Rotation := (rot + 2) mod 4; // rotate 180 degrees
                          end;
                        end;
          faVertical:   begin
                          if ter <> ResTileset_MirrorTilesV[ter] then
                          begin
                            gTerrain.Land^[Y,X].BaseLayer.Terrain := ResTileset_MirrorTilesV[ter];
                            gTerrain.Land^[Y,X].BaseLayer.Rotation := (8 - rot) mod 4; // Rotate left (in the opposite direction to normal rotation)
                          end
                          else
                          if ter <> ResTileset_MirrorTilesH[ter] then
                          begin
                            gTerrain.Land^[Y,X].BaseLayer.Terrain := ResTileset_MirrorTilesH[ter];
                            // do not rotate mirrored tile on odd rotation
                            if (rot mod 2) = 0 then
                              gTerrain.Land^[Y,X].BaseLayer.Rotation := (rot + 2) mod 4; // rotate 180 degrees
                          end;
                        end;
        end;
      end;

      FixLayer(gTerrain.Land^[Y,X].BaseLayer, False);

      for L := 0 to gTerrain.Land^[Y,X].LayersCnt - 1 do
        FixLayer(gTerrain.Land^[Y,X].Layer[L], True);
    end;

    if ptObject in fPasteTypes then
      FixObject;
  end;

var
  I,K: Integer;
  SX, SY: Word;
begin
  SX := (fSelectionRect.Right - fSelectionRect.Left);
  SY := (fSelectionRect.Bottom - fSelectionRect.Top);

  case aAxis of
    faHorizontal:  for I := 1 to SY do
                      for K := 1 to SX div 2 do
                        SwapTiles(fSelectionRect.Left + K, fSelectionRect.Top + I,
                                  fSelectionRect.Right - K + 1, fSelectionRect.Top + I);
    faVertical:    for I := 1 to SY div 2 do
                      for K := 1 to SX do
                        SwapTiles(fSelectionRect.Left + K, fSelectionRect.Top + I,
                                  fSelectionRect.Left + K, fSelectionRect.Bottom - I + 1);
  end;

  //Must loop backwards for object fixing
  for I := SY downto 1 do
    for K := SX downto 1 do
      FixTerrain(fSelectionRect.Left + K, fSelectionRect.Top + I);

  gTerrain.UpdateRenderHeight(fSelectionRect);
  gTerrain.UpdateLighting(fSelectionRect);
  // Grow rect by 1, cause of possible Tree's on the edges, which could affect passability
  gTerrain.UpdatePassability(KMRectGrow(fSelectionRect, 1));
  gTerrain.UpdateFences(fSelectionRect);
end;


function TKMSelection.TileWithinPastePreview(aX, aY: Word): Boolean;
begin
  Result := (fSelectionMode = smPasting) and KMInRect(KMPoint(aX, aY), KMRectShinkTopLeft(fSelectionRect));
end;


procedure TKMSelection.IncludePasteType(aPasteType: TKMTerrainSelectionPasteType);
begin
  fPasteTypes := fPasteTypes + [aPasteType];
  if fSelectionMode = smPasting then
    SyncTempLand;
end;


procedure TKMSelection.ExcludePasteType(aPasteType: TKMTerrainSelectionPasteType);
begin
  fPasteTypes := fPasteTypes - [aPasteType];
  if fSelectionMode = smPasting then
    SyncTempLand;
end;


procedure TKMSelection.SetNiceCoal;
var
  I, X, Y, tileTypeTo, tileTypeFrom: Integer;
begin
  tileTypeTo := 152;
  tileTypeFrom := 152;

  for I := 0 to 4 do
  begin
    case I of
       0: tileTypeTo := 152;
       4: begin
           tileTypeTo := 263;
           tileTypeFrom := 155;
          end;
       else
          begin
            tileTypeTo := tileTypeTo + 1;
            tileTypeFrom := tileTypeTo - 1;
          end;
    end;

    if I <> 0 then
      for X := fSelectionRect.Left+1 to fSelectionRect.Right do
        for Y := fSelectionRect.Top+1 to fSelectionRect.Bottom do
          fLastTiles[X,Y] := gTerrain.Land^[Y, X].BaseLayer.Terrain;

    for X := fSelectionRect.Left+1 to fSelectionRect.Right do
      for Y := fSelectionRect.Top+1 to fSelectionRect.Bottom do
      begin
        if I = 0 then
        begin
          if   (gTerrain.Land^[Y, X].BaseLayer.Terrain = 152)
            or (gTerrain.Land^[Y, X].BaseLayer.Terrain = 153)
            or (gTerrain.Land^[Y, X].BaseLayer.Terrain = 154)
            or (gTerrain.Land^[Y, X].BaseLayer.Terrain = 155)
            or (gTerrain.Land^[Y, X].BaseLayer.Terrain = 263) then
          begin
            gTerrain.Land^[Y, X].BaseLayer.Terrain := tileTypeTo;
            gTerrain.Land^[Y, X].BaseLayer.Rotation := KamRandom(4{$IFDEF RNG_SPY}, 'TKMSelection.SetNiceCoal'{$ENDIF});
          end;
        end
        else
        begin
          if CheckTilesAround(X, Y, tileTypeFrom) then
            gTerrain.Land^[Y, X].BaseLayer.Terrain  := tileTypeTo;
        end;
      end;
  end;
end;


procedure TKMSelection.CopyBufferToTempLand(aUpdateMainLand: Boolean = False; aUpdateAll: Boolean = True);
var
  I, K: Integer;
  Sx, Sy, Lx, Ly: Integer;
  updateRect: TKMRect;
begin
  Sx := fSelectionRect.Right - fSelectionRect.Left;
  Sy := fSelectionRect.Bottom - fSelectionRect.Top;

  for I := 0 to Sy do
    for K := 0 to Sx do
    begin
      // calc gTerrain.Land coordinates
      Lx := fSelectionRect.Left + K + 1;
      Ly := fSelectionRect.Top + I + 1;

      if gTerrain.VerticeInMapCoords(Lx, Ly) then
      begin
        if InRange(I, 0, Sy - 1)
          and InRange(K, 0, Sx - 1)
          and gTerrain.TileInMapCoords(Lx, Ly) then
        begin
          if aUpdateMainLand then
            // Update Main Land
            BufferToTile(KMPoint(Lx, Ly),
                         gTerrain.MainLand^[Ly,Lx], gGame.MapEditor.MainLandMapEd^[Ly,Lx], fTerrainPainter.LandTerKind[Ly,Lx],
                         fSelectionBuffer[I,K])
          else
            // Update Temp Land
            BufferToTile(KMPoint(Lx, Ly), fLandTemp[Ly,Lx], fLandMapEdTemp[Ly,Lx], fLandTerKindTemp[Ly,Lx],
                         fSelectionBuffer[I,K]);
        end
        else
        if ptHeight in fPasteTypes then
        begin
          if aUpdateMainLand then
            gTerrain.MainLand^[Ly,Lx].Height := fSelectionBuffer[I,K].Height
          else
            fLandTemp[Ly,Lx].Height := fSelectionBuffer[I,K].Height;
        end;

        gTerrain.UpdateRenderHeight(Lx, Ly);
      end;
    end;

  if aUpdateAll then
  begin
    updateRect := KMRectGrow(fSelectionRect, 2); // 2 - just in case
    gTerrain.UpdateAll(updateRect);
  end;
end;


// This is used for scripting actions.
procedure TKMSelection.ChangeSelectionRectangle(aLeft, aTop, aRight, aBottom: Integer);
begin
  fSelectionRect.Left   := aLeft;
  fSelectionRect.Top    := aTop;
  fSelectionRect.Right  := aRight;
  fSelectionRect.Bottom := aBottom;
end;


procedure TKMSelection.SyncTempLand;
begin
  // Restore TempLand with 'original' gTerrain.Land first
  DuplicateLandToTemp;
  // Copy data from the buffer onto TempLand
  CopyBufferToTempLand;
end;


procedure TKMSelection.Paint(aLayer: TKMPaintLayer; const aClipRect: TKMRect);
var
  color: Cardinal;
begin
  if aLayer = plTerrain then
  begin
    color := 0;
    case fSelectionMode of
      smSelecting:  color := icCyan;
      smPasting:    color := icRed;  //$FF0000FF
    end;
    gRenderAux.SquareOnTerrain(fSelectionRect.Left, fSelectionRect.Top, fSelectionRect.Right, fSelectionRect.Bottom, color);
  end;
end;


end.

