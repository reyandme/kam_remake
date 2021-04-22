unit KM_Utils;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows}
  Windows,
  {$ENDIF}
  {$IFDEF Unix}
  unix, baseunix, UnixUtil,
  {$ENDIF}
  {$IFDEF FPC} FileUtil, {$ENDIF}
  {$IFDEF WDC} IOUtils, {$ENDIF}
	SysUtils, StrUtils, Classes, Controls,
  KM_TerrainTypes,
  KM_Defaults, KM_CommonTypes, KM_CommonClasses, KM_Points,
  KM_ResTypes;

  function KMPathLength(aNodeList: TKMPointList): Single;

  function GetHintWHotKey(const aText: String; aKeyFunc: TKMKeyFunction): String; overload;
  function GetHintWHotKey(aTextId: Integer; const aHotkeyStr: String): String; overload;
  function GetHintWHotKey(aTextId: Integer; aKeyFunc: TKMKeyFunction): String; overload;

	function GetShiftState(aButton: TMouseButton): TShiftState;
  function GetMultiplicator(aButton: TMouseButton): Word; overload;
  function GetMultiplicator(aShift: TShiftState): Word; overload;

  function RoundToTilePixel(aVal: Single): Single; inline; overload;
  function RoundToTilePixel(aVal: TKMPointF): TKMPointF; inline; overload;

  procedure LoadMapHeader(aStream: TKMemoryStream; var aMapX: Integer; var aMapY: Integer); overload;
  procedure LoadMapHeader(aStream: TKMemoryStream; var aMapX: Integer; var aMapY: Integer; var aGameRev: Integer); overload;
  procedure LoadMapHeader(aStream: TKMemoryStream; var aMapX: Integer; var aMapY: Integer; var aGameRev: Integer; var aMapDataSize: Cardinal); overload;

  function GetGameObjectOwnerIndex(aObject: TObject): TKMHandID;

  function GetTerrainTileBasic(aTile: TKMTerrainTile): TKMTerrainTileBasic;

  procedure IterateOverArea(const aStartCell: TKMPoint; aSize: Integer; aIsSquare: Boolean; aOnCell: TPointEventSimple; aAroundArea: Boolean = False);

  function IsUnderWine: Boolean;


implementation
uses
  Math, KM_ResTexts, KM_ResKeys, KM_Houses, KM_Units, KM_UnitGroup;


function RoundToTilePixel(aVal: Single): Single; inline;
begin
  Result := Round(aVal * CELL_SIZE_PX) / CELL_SIZE_PX;
end;


function RoundToTilePixel(aVal: TKMPointF): TKMPointF; inline;
begin
  Result.X := RoundToTilePixel(aVal.X);
  Result.Y := RoundToTilePixel(aVal.Y);
end;


function KMPathLength(aNodeList: TKMPointList): Single;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to aNodeList.Count - 1 do
    Result := Result + KMLengthDiag(aNodeList[I-1], aNodeList[I]);
end;


procedure LoadMapHeader(aStream: TKMemoryStream; var aMapX: Integer; var aMapY: Integer);
var
  GameRev: Integer;
begin
  LoadMapHeader(aStream, aMapX, aMapY, GameRev);
end;


procedure LoadMapHeader(aStream: TKMemoryStream; var aMapX: Integer; var aMapY: Integer; var aGameRev: Integer);
var
  MapDataSize: Cardinal;
begin
  LoadMapHeader(aStream, aMapX, aMapY, aGameRev, MapDataSize);
end;


procedure LoadMapHeader(aStream: TKMemoryStream; var aMapX: Integer; var aMapY: Integer; var aGameRev: Integer; var aMapDataSize: Cardinal);
var
  GameRevision: UnicodeString;
  GameRev: Integer;
begin
  aStream.Read(aMapX); //Get map header to determine old (r6720 and earlier) or newer format

  aGameRev := 0;
  if aMapX = 0 then //Means we have not standart KaM format map, but our own KaM_Remake format
  begin
    aStream.ReadW(GameRevision);
    if TryStrToInt(Copy(GameRevision, 2, Length(GameRevision) - 1), GameRev) then
      aGameRev := GameRev
    else
      raise Exception.Create('Unexpected game revision in map header');

    aStream.Read(aMapDataSize);
    aStream.Read(aMapX);
  end;

  aStream.Read(aMapY);
  if not InRange(aMapX, 1, MAX_MAP_SIZE) or not InRange(aMapY, 1, MAX_MAP_SIZE) then
    raise Exception.Create(Format('Can''t open the map cos it has wrong dimensions: [%d:%d]', [aMapX, aMapY]));
end;


// Iterate over area. Using different rounding (Circle/Square).
// aOnCell - invoke that procedure on every iteration
// aAroundArea - do we also iterate over surrounding tiles?
procedure IterateOverArea(const aStartCell: TKMPoint; aSize: Integer; aIsSquare: Boolean; aOnCell: TPointEventSimple; aAroundArea: Boolean = False);
type
  TKMRoundingMode = (rOdd, rEven);

  //Is point I;J inside iterating area
  function IsInside(I,J,Rad: Integer; aRounding: TKMRoundingMode): Boolean;
  begin
    case aRounding of
      rOdd:   Result := aIsSquare or (Sqr(I)    + Sqr(J)    < Sqr(Rad+0.5));
      rEven:  Result := aIsSquare or (Sqr(I+0.5)+Sqr(J+0.5) < Sqr(Rad));
      else    Result := False;
    end;
  end;

  //Is Cell inside iterating area
  function IsCellInside(aCell: TKMPoint; Rad: Integer; aRounding: TKMRoundingMode): Boolean;
  var
    I,J: Integer;
  begin
    I := aCell.X - aStartCell.X;
    J := aCell.Y - aStartCell.Y;
    Result := InRange(I, -Rad, Rad-1) and InRange(J, -Rad, Rad-1) and IsInside(I, J, Rad, aRounding);
  end;

var
  BorderArea: TKMPointArray;
  K: Integer;

  procedure ProceedCell(X,Y: Integer; aIsBorderCell: Boolean);
  begin
    aOnCell(X, Y);
    if aIsBorderCell and (Length(BorderArea) > K) then
    begin
      //Collect BorderArea cells
      BorderArea[K] := KMPoint(X,Y);
      Inc(K);
    end;
  end;

var
  AroundArea: TStringList;
  I,J,MaxIJ,Rad,Size: Integer;
  PointsAround: TKMPointArray;
  P: TKMPoint;
  RoundingMode: TKMRoundingMode;
  FirstInRow, IsBorderCell: Boolean;
begin
  K := 0;
  Size := aSize;
  if aAroundArea and (Size <> 0) then
  begin
    if aIsSquare then
      Inc(Size, 2)
    else
      SetLength(BorderArea, Max(1, 4*(Size - 1)));
  end;

  if Size = 0 then
  begin
    // size smaller than one cell
    aOnCell(aStartCell.X, aStartCell.Y);
    if aAroundArea then
    begin
      aOnCell(aStartCell.X-1, aStartCell.Y-1);
      aOnCell(aStartCell.X-1, aStartCell.Y);
      aOnCell(aStartCell.X,   aStartCell.Y-1);
    end;
    Exit;
  end;

  Rad := Size div 2;
  // There are two brush types here, even and odd size
  if Size mod 2 = 1 then
  begin
    RoundingMode := rOdd;
    MaxIJ := Rad;
  end else begin
    RoundingMode := rEven;
    MaxIJ := Rad - 1;
  end;

  for I := -Rad to MaxIJ do
  begin
    FirstInRow := True;
    for J := -Rad to MaxIJ do
      // Rounding corners in a nice way
      if IsInside(I,J,Rad,RoundingMode) then
      begin
        //Check if this tile is in 'border area'
        IsBorderCell := FirstInRow or (I = -Rad) or (I = MaxIJ) or (J = -Rad) or (J = MaxIJ) // check if its first or at edges
                          or not IsInside(I,J+1,Rad,RoundingMode);  // or if its last (next tile in row is not in area anymore)
        ProceedCell(aStartCell.X+J, aStartCell.Y+I, IsBorderCell);
        FirstInRow := False;
      end;
  end;

  if aAroundArea and not aIsSquare then
  begin
    AroundArea := TStringList.Create;
    try
      AroundArea.Sort;
      AroundArea.Duplicates := dupIgnore;

      for I := 0 to K - 1 do
      begin
        //Get around cells for border cells
        PointsAround := KMPointsAround(BorderArea[I]);
        for J := 0 to High(PointsAround) do
          // If border cell is outside of iterating area addthem to Around Area
          if not IsCellInside(PointsAround[J], Rad, RoundingMode) then
            AroundArea.Add(TypeToString(PointsAround[J]));
      end;

      // Iterate through around area.
      // We assume, that iterating order is not important, so we do not care,
      // that first were iterated Central cells, then around area
      for I := 0 to AroundArea.Count - 1 do
      begin
        P := StringToType(AroundArea[I]);
        aOnCell(P.X, P.Y);
      end;
    finally
      AroundArea.Free;
    end;
  end;
end;


function GetTerrainTileBasic(aTile: TKMTerrainTile): TKMTerrainTileBasic;
var
  L: Integer;
begin
  Result.BaseLayer    := aTile.BaseLayer;
  Result.LayersCnt    := aTile.LayersCnt;
  Result.Height       := aTile.Height;
  Result.Obj          := aTile.Obj;
  Result.IsCustom     := aTile.IsCustom;
  Result.BlendingLvl  := aTile.BlendingLvl;
  Result.TileOverlay  := aTile.TileOverlay;

  for L := 0 to 2 do
    Result.Layer[L] := aTile.Layer[L];
end;


function GetGameObjectOwnerIndex(aObject: TObject): TKMHandID;
begin
  Result := -1;
  if aObject is TKMHouse then
  begin
    Result := TKMHouse(aObject).Owner;
    Exit;
  end;
  if aObject is TKMUnit then
  begin
    Result := TKMUnit(aObject).Owner;
    Exit;
  end;
  if aObject is TKMUnitGroup then
  begin
    Result := TKMUnitGroup(aObject).Owner;
    Exit;
  end;
end;


function GetShiftState(aButton: TMouseButton): TShiftState;
begin
  Result := [];
  case aButton of
    mbLeft:   Include(Result, ssLeft);
    mbRight:  Include(Result, ssRight);
  end;

  if GetKeyState(VK_SHIFT) < 0 then
    Include(Result, ssShift);
end;


function GetMultiplicator(aButton: TMouseButton): Word;
begin
  Result := GetMultiplicator(GetShiftState(aButton));
end;


function GetMultiplicator(aShift: TShiftState): Word;
begin
  Exclude(aShift, ssCtrl); //Ignore Ctrl
  Result := Byte(aShift = [ssLeft])
          + Byte(aShift = [ssRight]) * 10
          + Byte(aShift = [ssShift,ssLeft]) * 100
          + Byte(aShift = [ssShift,ssRight]) * 1000;
end;


function GetHintWHotKey(const aText: String; aKeyFunc: TKMKeyFunction): String;
var
  hotKeyStr: String;
begin
  Result := aText;
  hotKeyStr := gResKeys.GetKeyNameById(aKeyFunc);
  if hotKeyStr <> '' then
    Result := Result + Format(' (''%s'')', [hotKeyStr]);
end;


function GetHintWHotKey(aTextId: Integer; const aHotkeyStr: String): String;
var
  hotKeyStr: string;
begin
  Result := gResTexts[aTextId];
  hotKeyStr := Trim(aHotkeyStr);
  if hotKeyStr <> '' then
    Result := Result + Format(' (''%s'')', [hotKeyStr]);
end;


function GetHintWHotKey(aTextId: Integer; aKeyFunc: TKMKeyFunction): String;
begin
  Result := GetHintWHotKey(aTextId, gResKeys.GetKeyNameById(aKeyFunc));
end;


function IsUnderWine: Boolean;
var
  H: Cardinal;
begin
  Result := False;
  H := LoadLibrary('ntdll.dll');
  if H > HINSTANCE_ERROR then
  begin
    Result := Assigned(GetProcAddress(H, 'wine_get_version'));
    FreeLibrary(H);
  end;
end;


end.

