unit KM_TerrainSelection;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, Clipbrd, KromUtils,
  {$IFDEF MSWindows} Windows, {$ENDIF}
  KM_CommonClasses, KM_Points, KM_Terrain, KM_TerrainPainter, KM_RenderPool, KM_ResTileset;


type
  TKMSelectionEdit = (seNone, seNewRect, seResizeX1, seResizeY1, seResizeX2, seResizeY2, seMove);
  TKMSelectionMode = (smSelecting, smPasting);
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
                  end;

  TKMSelection = class
  private
    fTerrainPainter: TKMTerrainPainter;
    fSelectionEdit: TKMSelectionEdit;
    fSelPrevX, fSelPrevY: Integer;

    fSelectionRectF: TKMRectF; //Cursor selection bounds (can have inverted bounds)
    fSelectionRect: TKMRect; //Tile-space selection, at least 1 tile
    fSelectionMode: TKMSelectionMode;
    fSelectionBuffer: array of array of TKMBufferData;
    procedure Selection_SyncCellRect;
  public
    constructor Create(aTerrainPainter: TKMTerrainPainter);
    procedure Selection_Resize;
    procedure Selection_Start;
    function Selection_DataInBuffer: Boolean;
    procedure Selection_Copy; //Copies the selected are into buffer
    procedure Selection_PasteBegin; //Pastes the area from buffer and lets move it with cursor
    procedure Selection_PasteApply; //Do the actual paste from buffer to terrain
    procedure Selection_PasteCancel;
    procedure Selection_Flip(aAxis: TKMFlipAxis);

    function TileWithinPastePreview(aX, aY: Word): Boolean;
    procedure Paint(aLayer: TKMPaintLayer; const aClipRect: TKMRect);
  end;


var
  CF_MAPDATA: Word; //Our own custom clipboard format


implementation
uses
  SysUtils,
  KM_Resource,
  KM_GameCursor, KM_RenderAux, KM_Defaults;


{ TKMSelection }
constructor TKMSelection.Create(aTerrainPainter: TKMTerrainPainter);
begin
  inherited Create;

  fTerrainPainter := aTerrainPainter;
end;


procedure TKMSelection.Selection_SyncCellRect;
begin
  //Convert RawRect values that can be inverted to tilespace Rect
  fSelectionRect.Left   := Trunc(Math.Min(fSelectionRectF.Left, fSelectionRectF.Right));
  fSelectionRect.Top    := Trunc(Math.Min(fSelectionRectF.Top, fSelectionRectF.Bottom));
  fSelectionRect.Right  := Ceil(Math.Max(fSelectionRectF.Left, fSelectionRectF.Right));
  fSelectionRect.Bottom := Ceil(Math.Max(fSelectionRectF.Top, fSelectionRectF.Bottom));
  //Selection must be at least one tile
  if fSelectionRect.Left = fSelectionRect.Right then Inc(fSelectionRect.Right);
  if fSelectionRect.Top = fSelectionRect.Bottom then Inc(fSelectionRect.Bottom);
end;


procedure TKMSelection.Selection_Resize;
var
  RectO: TKMRect;
  CursorFloat: TKMPointF;
  CursorCell: TKMPoint;
  MoveX, MoveY: Integer;
begin
  //Last row/col of the map is not visible or selectable
  CursorFloat.X := EnsureRange(gGameCursor.Float.X, 0.1, gTerrain.MapX-1 - 0.1);
  CursorFloat.Y := EnsureRange(gGameCursor.Float.Y, 0.1, gTerrain.MapY-1 - 0.1);
  CursorCell.X := EnsureRange(gGameCursor.Cell.X, 1, gTerrain.MapX-1);
  CursorCell.Y := EnsureRange(gGameCursor.Cell.Y, 1, gTerrain.MapY-1);

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
end;


procedure TKMSelection.Selection_Start;
const
  EDGE = 0.25;
var
  CursorFloat: TKMPointF;
  CursorCell: TKMPoint;
begin
  //Last row/col of the map is not visible or selectable
  CursorFloat.X := EnsureRange(gGameCursor.Float.X, 0.1, gTerrain.MapX-1 - 0.1);
  CursorFloat.Y := EnsureRange(gGameCursor.Float.Y, 0.1, gTerrain.MapY-1 - 0.1);
  CursorCell.X := EnsureRange(gGameCursor.Cell.X, 1, gTerrain.MapX-1);
  CursorCell.Y := EnsureRange(gGameCursor.Cell.Y, 1, gTerrain.MapY-1);

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


function TKMSelection.Selection_DataInBuffer: Boolean;
begin
  Result := Clipboard.HasFormat(CF_MAPDATA);
end;


//Copy terrain section into buffer
procedure TKMSelection.Selection_Copy;
var
  I, K, L: Integer;
  Sx, Sy: Word;
  Bx, By: Word;
  {$IFDEF WDC}
    hMem: THandle;
    BufPtr: Pointer;
  {$ENDIF}
  BufferStream: TKMemoryStream;
begin
  Sx := fSelectionRect.Right - fSelectionRect.Left;
  Sy := fSelectionRect.Bottom - fSelectionRect.Top;
  SetLength(fSelectionBuffer, Sy, Sx);

  BufferStream := TKMemoryStreamBinary.Create;
  BufferStream.Write(Sx);
  BufferStream.Write(Sy);

  for I := fSelectionRect.Top to fSelectionRect.Bottom - 1 do
    for K := fSelectionRect.Left to fSelectionRect.Right - 1 do
      if gTerrain.TileInMapCoords(K+1, I+1, 0) then
      begin
        Bx := K - fSelectionRect.Left;
        By := I - fSelectionRect.Top;
        fSelectionBuffer[By,Bx].BaseLayer.Terrain  := gTerrain.Land[I+1, K+1].BaseLayer.Terrain;
        fSelectionBuffer[By,Bx].BaseLayer.Rotation := gTerrain.Land[I+1, K+1].BaseLayer.Rotation;
        fSelectionBuffer[By,Bx].BaseLayer.CopyCorners(gTerrain.Land[I+1, K+1].BaseLayer);
        fSelectionBuffer[By,Bx].LayersCnt   := gTerrain.Land[I+1, K+1].LayersCnt;
        fSelectionBuffer[By,Bx].Height      := gTerrain.Land[I+1, K+1].Height;
        fSelectionBuffer[By,Bx].Obj         := gTerrain.Land[I+1, K+1].Obj;
        fSelectionBuffer[By,Bx].IsCustom    := gTerrain.Land[I+1, K+1].IsCustom;
        fSelectionBuffer[By,Bx].BlendingLvl := gTerrain.Land[I+1, K+1].BlendingLvl;
        fSelectionBuffer[By,Bx].TerKind     := fTerrainPainter.LandTerKind[I+1, K+1].TerKind;
        fSelectionBuffer[By,Bx].TileOverlay := gTerrain.Land[I+1, K+1].TileOverlay;
        for L := 0 to 2 do
        begin
          fSelectionBuffer[By,Bx].Layer[L].Terrain  := gTerrain.Land[I+1, K+1].Layer[L].Terrain;
          fSelectionBuffer[By,Bx].Layer[L].Rotation := gTerrain.Land[I+1, K+1].Layer[L].Rotation;
          fSelectionBuffer[By,Bx].Layer[L].CopyCorners(gTerrain.Land[I+1, K+1].Layer[L]);
        end;

        BufferStream.Write(fSelectionBuffer[By,Bx], SizeOf(fSelectionBuffer[By,Bx]));
  end;

  if Sx*Sy <> 0 then
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


procedure TKMSelection.Selection_PasteBegin;
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
  for I:=0 to Sy-1 do
    for K:=0 to Sx-1 do
      BufferStream.Read(fSelectionBuffer[I,K], SizeOf(fSelectionBuffer[I,K]));
  BufferStream.Free;

  //Mapmaker could have changed selection rect, sync it with Buffer size
  fSelectionRect.Right := fSelectionRect.Left + Length(fSelectionBuffer[0]);
  fSelectionRect.Bottom := fSelectionRect.Top + Length(fSelectionBuffer);

  fSelectionMode := smPasting;
end;


procedure TKMSelection.Selection_PasteApply;
var
  I, K, L: Integer;
  Bx, By: Word;
begin
  for I := fSelectionRect.Top to fSelectionRect.Bottom - 1 do
    for K := fSelectionRect.Left to fSelectionRect.Right - 1 do
      if gTerrain.TileInMapCoords(K+1, I+1, 0) then
      begin
        Bx := K - fSelectionRect.Left;
        By := I - fSelectionRect.Top;
        gTerrain.Land[I+1, K+1].BaseLayer.Terrain  := fSelectionBuffer[By,Bx].BaseLayer.Terrain;
        gTerrain.Land[I+1, K+1].BaseLayer.Rotation := fSelectionBuffer[By,Bx].BaseLayer.Rotation;
        gTerrain.Land[I+1, K+1].BaseLayer.CopyCorners(fSelectionBuffer[By,Bx].BaseLayer);
        gTerrain.Land[I+1, K+1].LayersCnt   := fSelectionBuffer[By,Bx].LayersCnt;
        gTerrain.Land[I+1, K+1].Height     := fSelectionBuffer[By,Bx].Height;
        gTerrain.Land[I+1, K+1].Obj         := fSelectionBuffer[By,Bx].Obj;
        gTerrain.Land[I+1, K+1].IsCustom    := fSelectionBuffer[By,Bx].IsCustom;
        gTerrain.Land[I+1, K+1].BlendingLvl := fSelectionBuffer[By,Bx].BlendingLvl;
        fTerrainPainter.LandTerKind[I+1, K+1].TerKind := fSelectionBuffer[By,Bx].TerKind;
        gterrain.Land[I+1, K+1].TileOverlay := fSelectionBuffer[By,Bx].TileOverlay;
        for L := 0 to 2 do
        begin
          gTerrain.Land[I+1, K+1].Layer[L].Terrain  := fSelectionBuffer[By,Bx].Layer[L].Terrain;
          gTerrain.Land[I+1, K+1].Layer[L].Rotation := fSelectionBuffer[By,Bx].Layer[L].Rotation;
          gTerrain.Land[I+1, K+1].Layer[L].CopyCorners(fSelectionBuffer[By,Bx].Layer[L]);
        end;
      end;

  gTerrain.UpdateLighting(fSelectionRect);
  gTerrain.UpdatePassability(fSelectionRect);

  fSelectionMode := smSelecting;
end;


procedure TKMSelection.Selection_PasteCancel;
begin
  fSelectionMode := smSelecting;
end;


procedure TKMSelection.Selection_Flip(aAxis: TKMFlipAxis);

  procedure SwapLayers(var Layer1, Layer2: TKMTerrainLayer);
  begin
    SwapInt(Layer1.Terrain, Layer2.Terrain);
    SwapInt(Layer1.Rotation, Layer2.Rotation);
    Layer1.SwapCorners(Layer2);
  end;

  procedure SwapTiles(X1, Y1, X2, Y2: Word);
  var
    L: Integer;
    tmp: TKMTerrainKind;
  begin
    SwapLayers(gTerrain.Land[Y1,X1].BaseLayer, gTerrain.Land[Y2,X2].BaseLayer);

    for L := 0 to 2 do
      SwapLayers(gTerrain.Land[Y1,X1].Layer[L], gTerrain.Land[Y2,X2].Layer[L]);

    SwapInt(gTerrain.Land[Y1,X1].Obj, gTerrain.Land[Y2,X2].Obj);
    SwapInt(gTerrain.Land[Y1,X1].LayersCnt, gTerrain.Land[Y2,X2].LayersCnt);
    SwapInt(gTerrain.Land[Y1,X1].BlendingLvl, gTerrain.Land[Y2,X2].BlendingLvl);
    SwapBool(gTerrain.Land[Y1,X1].IsCustom, gTerrain.Land[Y2,X2].IsCustom);

    //Heights are vertex based not tile based, so it gets flipped slightly differently
    case aAxis of
      faHorizontal: SwapInt(gTerrain.Land[Y1,X1].Height, gTerrain.Land[Y2  ,X2+1].Height);
      faVertical:   SwapInt(gTerrain.Land[Y1,X1].Height, gTerrain.Land[Y2+1,X2  ].Height);
    end;
    tmp := fTerrainPainter.LandTerKind[Y1, X1].TerKind;
    fTerrainPainter.LandTerKind[Y1, X1].TerKind := fTerrainPainter.LandTerKind[Y2, X2].TerKind;
    fTerrainPainter.LandTerKind[Y2, X2].TerKind := tmp;
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

      //Lets try to get initial Rot from Corners information, if possible
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
      and (gTerrain.Land[Y,X+1].Obj = OBJ_NONE) and not (gTerrain.Land[Y,X].Obj in OBJ_MIDDLE_X) then
      begin
        gTerrain.Land[Y,X+1].Obj := gTerrain.Land[Y,X].Obj;
        gTerrain.Land[Y,X].Obj := OBJ_NONE;
      end;

      //Vertical flip: Vertex (not middle) objects must be moved down by 1
      if (aAxis = faVertical) and (Y < fSelectionRect.Bottom)
      and (gTerrain.Land[Y+1,X].Obj = OBJ_NONE) and not (gTerrain.Land[Y,X].Obj in OBJ_MIDDLE_Y) then
      begin
        gTerrain.Land[Y+1,X].Obj := gTerrain.Land[Y,X].Obj;
        gTerrain.Land[Y,X].Obj := OBJ_NONE;
      end;
    end;

  const
    CORNERS_REVERSED = [15,21,142,234,235,238];

  var
    L: Integer;
    ter: Word;
    rot: Byte;
  begin
    ter := gTerrain.Land[Y,X].BaseLayer.Terrain;
    rot := gTerrain.Land[Y,X].BaseLayer.Rotation mod 4; //Some KaM maps contain rotations > 3 which must be fixed by modding

    //Edges
    if gRes.Tileset.TileIsEdge(ter) then
    begin
      if (rot in [1,3]) xor (aAxis = faVertical) then
        gTerrain.Land[Y,X].BaseLayer.Rotation := (rot + 2) mod 4
    end else
    //Corners
    if gRes.Tileset.TileIsCorner(ter) then
    begin
      if (rot in [1,3]) xor (ter in CORNERS_REVERSED) xor (aAxis = faVertical) then
        gTerrain.Land[Y,X].BaseLayer.Rotation := (rot+1) mod 4
      else
        gTerrain.Land[Y,X].BaseLayer.Rotation := (rot+3) mod 4;
    end
    else
    begin
      case aAxis of
        faHorizontal: begin
                        if ter <> ResTileset_MirrorTilesH[ter] then
                        begin
                          gTerrain.Land[Y,X].BaseLayer.Terrain := ResTileset_MirrorTilesH[ter];
                          gTerrain.Land[Y,X].BaseLayer.Rotation := (8 - rot) mod 4; // Rotate left (in the opposite direction to normal rotation)
                        end
                        else
                        if ter <> ResTileset_MirrorTilesV[ter] then
                        begin
                          gTerrain.Land[Y,X].BaseLayer.Terrain := ResTileset_MirrorTilesV[ter];
                          // do not rotate mirrored tile on odd rotation
                          if (rot mod 2) = 0 then
                            gTerrain.Land[Y,X].BaseLayer.Rotation := (rot + 2) mod 4; // rotate 180 degrees
                        end;
                      end;
        faVertical:   begin
                        if ter <> ResTileset_MirrorTilesV[ter] then
                        begin
                          gTerrain.Land[Y,X].BaseLayer.Terrain := ResTileset_MirrorTilesV[ter];
                          gTerrain.Land[Y,X].BaseLayer.Rotation := (8 - rot) mod 4; // Rotate left (in the opposite direction to normal rotation)
                        end
                        else
                        if ter <> ResTileset_MirrorTilesH[ter] then
                        begin
                          gTerrain.Land[Y,X].BaseLayer.Terrain := ResTileset_MirrorTilesH[ter];
                          // do not rotate mirrored tile on odd rotation
                          if (rot mod 2) = 0 then
                            gTerrain.Land[Y,X].BaseLayer.Rotation := (rot + 2) mod 4; // rotate 180 degrees
                        end;
                      end;
      end;
    end;

    FixLayer(gTerrain.Land[Y,X].BaseLayer, False);

    for L := 0 to gTerrain.Land[Y,X].LayersCnt - 1 do
      FixLayer(gTerrain.Land[Y,X].Layer[L], True);

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

  gTerrain.UpdateLighting(fSelectionRect);
  gTerrain.UpdatePassability(fSelectionRect);
end;


function TKMSelection.TileWithinPastePreview(aX, aY: Word): Boolean;
begin
  Result := (fSelectionMode = smPasting) and KMInRect(KMPoint(aX, aY), KMRectShinkTopLeft(fSelectionRect));
end;


procedure TKMSelection.Paint(aLayer: TKMPaintLayer; const aClipRect: TKMRect);

  function GetTileBasic(const aBufferData: TKMBufferData): TKMTerrainTileBasic;
  var
    L: Integer;
  begin
    Result.BaseLayer    := aBufferData.BaseLayer;
    Result.LayersCnt    := aBufferData.LayersCnt;
    Result.Height       := aBufferData.Height;
    Result.Obj          := aBufferData.Obj;
    Result.IsCustom     := aBufferData.IsCustom;
    Result.BlendingLvl  := aBufferData.BlendingLvl;
    Result.TileOverlay  := aBufferData.TileOverlay;
    for L := 0 to 2 do
      Result.Layer[L] := aBufferData.Layer[L];
  end;

var
  Sx, Sy: Word;
  I, K: Integer;
begin
  Sx := fSelectionRect.Right - fSelectionRect.Left;
  Sy := fSelectionRect.Bottom - fSelectionRect.Top;

  if aLayer = plTerrain then
    case fSelectionMode of
      smSelecting:  begin
                      //fRenderAux.SquareOnTerrain(RawRect.Left, RawRect.Top, RawRect.Right, RawRect.Bottom, $40FFFF00);
                      gRenderAux.SquareOnTerrain(fSelectionRect.Left, fSelectionRect.Top, fSelectionRect.Right, fSelectionRect.Bottom, icCyan);
                    end;
      smPasting:    begin
                      for I := 0 to Sy - 1 do
                        for K := 0 to Sx - 1 do
                           //Check TileInMapCoords first since KMInRect can't handle negative coordinates
                          if gTerrain.TileInMapCoords(fSelectionRect.Left+K+1, fSelectionRect.Top+I+1)
                            and KMInRect(KMPoint(fSelectionRect.Left+K+1, fSelectionRect.Top+I+1), aClipRect) then
                            gRenderPool.RenderTerrain.RenderTile(fSelectionRect.Left+K+1, fSelectionRect.Top+I+1, GetTileBasic(fSelectionBuffer[I,K]));

                      gRenderAux.SquareOnTerrain(fSelectionRect.Left, fSelectionRect.Top, fSelectionRect.Right, fSelectionRect.Bottom, $FF0000FF);
                    end;
    end;

  if aLayer = plObjects then
    if fSelectionMode = smPasting then
    begin
      for I := 0 to Sy - 1 do
        for K := 0 to Sx - 1 do
          //Check TileInMapCoords first since KMInRect can't handle negative coordinates
          if (fSelectionBuffer[I,K].Obj <> OBJ_NONE) and gTerrain.TileInMapCoords(fSelectionRect.Left+K+1, fSelectionRect.Top+I+1)
            and KMInRect(KMPoint(fSelectionRect.Left+K+1, fSelectionRect.Top+I+1), aClipRect) then
            gRenderPool.RenderMapElement(fSelectionBuffer[I,K].Obj, 0, fSelectionRect.Left+K+1, fSelectionRect.Top+I+1, True);
    end;
end;


initialization
begin
  {$IFDEF WDC}
  CF_MAPDATA := RegisterClipboardFormat(PWideChar('KaM Remake ' + string(GAME_REVISION) + ' Map Data'));
  {$ENDIF}
end;


end.


