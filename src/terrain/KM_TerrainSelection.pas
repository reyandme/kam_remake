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
                    TerKind: TKMTerrainKind; //Used for brushes
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

  BufferStream := TKMemoryStream.Create;
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
        fSelectionBuffer[By,Bx].BaseLayer.Corners  := gTerrain.Land[I+1, K+1].BaseLayer.Corners;
        fSelectionBuffer[By,Bx].LayersCnt := gTerrain.Land[I+1, K+1].LayersCnt;
        fSelectionBuffer[By,Bx].Height    := gTerrain.Land[I+1, K+1].Height;
        fSelectionBuffer[By,Bx].Obj       := gTerrain.Land[I+1, K+1].Obj;
        fSelectionBuffer[By,Bx].TerKind   := fTerrainPainter.LandTerKind[I+1, K+1].TerKind;
        for L := 0 to 2 do
        begin
          fSelectionBuffer[By,Bx].Layer[L].Terrain  := gTerrain.Land[I+1, K+1].Layer[L].Terrain;
          fSelectionBuffer[By,Bx].Layer[L].Rotation := gTerrain.Land[I+1, K+1].Layer[L].Rotation;
          fSelectionBuffer[By,Bx].Layer[L].Corners  := gTerrain.Land[I+1, K+1].Layer[L].Corners;
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
  BufferStream := TKMemoryStream.Create;
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
        gTerrain.Land[I+1, K+1].BaseLayer.Corners  := fSelectionBuffer[By,Bx].BaseLayer.Corners;
        gTerrain.Land[I+1, K+1].LayersCnt   := fSelectionBuffer[By,Bx].LayersCnt;
        gTerrain.Land[I+1, K+1].Height      := fSelectionBuffer[By,Bx].Height;
        gTerrain.Land[I+1, K+1].Obj         := fSelectionBuffer[By,Bx].Obj;
        fTerrainPainter.LandTerKind[I+1, K+1].TerKind := fSelectionBuffer[By,Bx].TerKind;
        for L := 0 to 2 do
        begin
          gTerrain.Land[I+1, K+1].Layer[L].Terrain  := fSelectionBuffer[By,Bx].Layer[L].Terrain;
          gTerrain.Land[I+1, K+1].Layer[L].Rotation := fSelectionBuffer[By,Bx].Layer[L].Rotation;
          gTerrain.Land[I+1, K+1].Layer[L].Corners  := fSelectionBuffer[By,Bx].Layer[L].Corners;
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
  var
    TmpCorners: set of Byte;
  begin
    SwapInt(Layer1.Terrain, Layer2.Terrain);
    SwapInt(Layer1.Rotation, Layer2.Rotation);
    TmpCorners := Layer1.Corners;
    Layer1.Corners := Layer2.Corners;
    Layer2.Corners := TmpCorners;
  end;

  procedure SwapTiles(X1, Y1, X2, Y2: Word);
  var
    L: Integer;
    Tmp: TKMTerrainKind;
  begin
    SwapLayers(gTerrain.Land[Y1,X1].BaseLayer, gTerrain.Land[Y2,X2].BaseLayer);

    for L := 0 to 2 do
      SwapLayers(gTerrain.Land[Y1,X1].Layer[L], gTerrain.Land[Y2,X2].Layer[L]);

    SwapInt(gTerrain.Land[Y1,X1].Obj, gTerrain.Land[Y2,X2].Obj);
    SwapInt(gTerrain.Land[Y1,X1].LayersCnt, gTerrain.Land[Y2,X2].LayersCnt);

    //Heights are vertex based not tile based, so it gets flipped slightly differently
    case aAxis of
      faHorizontal: SwapInt(gTerrain.Land[Y1,X1].Height, gTerrain.Land[Y2  ,X2+1].Height);
      faVertical:   SwapInt(gTerrain.Land[Y1,X1].Height, gTerrain.Land[Y2+1,X2  ].Height);
    end;
    Tmp := fTerrainPainter.LandTerKind[Y1, X1].TerKind;
    fTerrainPainter.LandTerKind[Y1, X1].TerKind := fTerrainPainter.LandTerKind[Y2, X2].TerKind;
    fTerrainPainter.LandTerKind[Y2, X2].TerKind := Tmp;
  end;

  procedure FixTerrain(X, Y: Integer);
    procedure FixLayer(var aLayer: TKMTerrainLayer; aFixRotation: Boolean);
    var
      I, J: Integer;
      Rot: Byte;
      Corners: array[0..3] of Integer;
    begin
      J := 0;

      for I in aLayer.Corners do
      begin
        Corners[J] := I;
        Inc(J);
      end;

      //Lets try to get initial Rot from Corners information, if possible
      case J of
        0,4:  Exit;  //nothing to fix here
        1:    begin
                // For 1 corner - corner is equal to rotation
                Rot := Corners[0];
                if (Rot in [0,2]) xor (aAxis = faVertical) then
                  Rot := (Rot+1) mod 4
                else
                  Rot := (Rot+3) mod 4;
                aLayer.Corners := [Rot];
              end;
        2:    begin
                if Abs(Corners[0] - Corners[1]) = 2 then  //Opposite corners
                begin
                  if aFixRotation then
                    Rot := aLayer.Rotation // for opposite corners its not possible to get rotation from corners, as 1 rot equal to 3 rot etc.
                  else
                    Rot := Corners[0];
                  // Fixed Rot is same as for 1 corner
                  if (Rot in [0,2]) xor (aAxis = faVertical) then
                    Rot := (Rot+1) mod 4
                  else
                    Rot := (Rot+3) mod 4;
                  aLayer.Corners := [(Corners[0] + 1) mod 4, (Corners[1] + 1) mod 4]; //no difference for +1 or +3, as they are same on (mod 4)
                end else begin
                  if (Corners[0] = 0) and (Corners[1] = 3) then // left vertical straight  = initial Rot = 3
                    Rot := 3
                  else
                    Rot := Corners[0];
                  // Fixed Rot calculation
                  if (Rot in [1,3]) xor (aAxis = faVertical) then
                  begin
                    Rot := (Rot+2) mod 4;
                    aLayer.Corners := [(Corners[0] + 2) mod 4, (Corners[1] + 2) mod 4];
                  end;
                end;
              end;
        3:    begin
                // Initial Rot - just go through all 4 possibilities
                if (Corners[0] = 0) and (Corners[2] = 3) then
                  Rot := IfThen(Corners[1] = 1, 0, 3)
                else
                  Rot := Round((Corners[0] + Corners[2]) / 2);
                // Fixed Rot calculation same as for corner
                if (Rot in [0,2]) xor (aAxis = faVertical) then
                  Rot := (Rot+1) mod 4
                else
                  Rot := (Rot+3) mod 4;
                aLayer.Corners := [0,1,2,3];
                Exclude(aLayer.Corners, (Rot + 2) mod 4); // all corners except opposite to rotation
              end;
        else  raise Exception.Create('Wrong number of corners');
      end;
      if aFixRotation then
        aLayer.Rotation := Rot;
    end;

  const
    CORNERS = [10,15,18,21..23,25,38,49,51..54,56,58,65,66,68..69,71,72,74,78,80,81,83,84,86..87,89,90,92,93,95,96,98,99,101,102,104,105,107..108,110..111,113,114,116,118,119,120,122,123,126..127,138,142,143,165,176..193,196,202,203,205,213,220,234..241,243,247];
    CORNERS_REVERSED = [15,21,142,234,235,238];
    EDGES = [4,12,19,39,50,57,64,67,70,73,76,79,82,85,88,91,94,97,100,103,106,109,112,115,117,121,124..125,139,141,166..175,194,198..200,204,206..212,216..219,223,224..233,242,244];
    OBJ_MIDDLE_X = [8,9,54..61,80,81,212,213,215];
    OBJ_MIDDLE_Y = [8,9,54..61,80,81,212,213,215,  1..5,10..12,17..19,21..24,63,126,210,211,249..253];
  var
    L: Integer;
    Ter: Word;
    Rot: Byte;
  begin
    Ter := gTerrain.Land[Y,X].BaseLayer.Terrain;
    Rot := gTerrain.Land[Y,X].BaseLayer.Rotation mod 4; //Some KaM maps contain rotations > 3 which must be fixed by modding

    //Edges
    if (Ter in EDGES) and ((Rot in [1,3]) xor (aAxis = faVertical)) then
      gTerrain.Land[Y,X].BaseLayer.Rotation := (Rot+2) mod 4;

    //Corners
    if Ter in CORNERS then
    begin
      if (Rot in [1,3]) xor (Ter in CORNERS_REVERSED) xor (aAxis = faVertical) then
        gTerrain.Land[Y,X].BaseLayer.Rotation := (Rot+1) mod 4
      else
        gTerrain.Land[Y,X].BaseLayer.Rotation := (Rot+3) mod 4;
    end;

    FixLayer(gTerrain.Land[Y,X].BaseLayer, False);

    for L := 0 to gTerrain.Land[Y,X].LayersCnt - 1 do
      FixLayer(gTerrain.Land[Y,X].Layer[L], True);

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
    Result.BaseLayer := aBufferData.BaseLayer;
    Result.LayersCnt := aBufferData.LayersCnt;
    Result.Height    := aBufferData.Height;
    Result.Obj       := aBufferData.Obj;
    Result.IsCustom  := aBufferData.IsCustom;
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
                      gRenderAux.SquareOnTerrain(fSelectionRect.Left, fSelectionRect.Top, fSelectionRect.Right, fSelectionRect.Bottom, $FFFFFF00);
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
  CF_MAPDATA := RegisterClipboardFormat(PWideChar('KaM Remake ' + GAME_REVISION + ' Map Data'));
  {$ENDIF}
end;


end.


