unit KM_Utils;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF FPC} FileUtil, {$ENDIF}
  {$IFDEF WDC} IOUtils, {$ENDIF}
	SysUtils, StrUtils, Classes,
//  Controls,
  KM_TerrainTypes,
  KM_Defaults, KM_CommonTypes, KM_CommonClasses, KM_Points,
  KM_ResTypes;

  function KMPathLength(aNodeList: TKMPointList): Single;

  function GetHintWHotkey(const aText: String; aKeyFunc: TKMKeyFunction): String; overload;
  function GetHintWHotkey(aTextId: Integer; const aHotkeyStr: String): String; overload;
  function GetHintWHotkey(aTextId: Integer; aKeyFunc: TKMKeyFunction): String; overload;

  function RoundToTilePixel(aVal: Single): Single; inline; overload;
  function RoundToTilePixel(aVal: TKMPointF): TKMPointF; inline; overload;

  procedure LoadMapHeader(aStream: TKMemoryStream; var aMapX: Integer; var aMapY: Integer); overload;
  procedure LoadMapHeader(aStream: TKMemoryStream; var aMapX: Integer; var aMapY: Integer; var aGameRev: Integer); overload;
  procedure LoadMapHeader(aStream: TKMemoryStream; var aMapX: Integer; var aMapY: Integer; var aGameRev: Integer; var aMapDataSize: Cardinal); overload;

  function GetTerrainTileBasic(aTile: TKMTerrainTile): TKMTerrainTileBasic;

  procedure IterateOverArea(const aStartCell: TKMPoint; aSize: Integer; aIsSquare: Boolean; aOnCell: TPointEventSimple; aAroundArea: Boolean = False);

  function GetLocalizedFilePath(aPath: string; aLocale, aFallbackLocale, aExt: AnsiString): string;

  function CompareTextLogical(A, B: UnicodeString): Integer;


implementation
uses
  Math, KM_ResTexts, KM_ResKeys;


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


//@Rey: Should we change "var" to "out" here and above? It would be more semantically correct in these cases
procedure LoadMapHeader(aStream: TKMemoryStream; var aMapX: Integer; var aMapY: Integer; var aGameRev: Integer; var aMapDataSize: Cardinal);
var
  GameRevision: UnicodeString;
  GameRev: Integer;
begin
  aStream.Read(aMapX); // Get map header to determine old (r6720 and earlier) or newer format

  aGameRev := 0;
  if aMapX = 0 then // Means we have not a standart KaM format map, but our own KaM_Remake format
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
      BorderArea[K] := TKMPoint.New(X, Y);
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
  end else
  begin
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
    AroundArea := TStringList.Create; //todo -cPractical: Replace with TKMPointList
    try
      AroundArea.Sort; //todo -cPractical: Sorting empty list, why? Or do we want added values to be sorted?
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


function GetHintWHotkey(const aText: String; aKeyFunc: TKMKeyFunction): String;
var
  hotKeyStr: String;
begin
  Result := aText;
  hotKeyStr := gResKeys.GetKeyNameById(aKeyFunc);
  if hotKeyStr <> '' then
    Result := Result + Format(' (''%s'')', [hotKeyStr]);
end;


function GetHintWHotkey(aTextId: Integer; const aHotkeyStr: String): String;
var
  hotKeyStr: string;
begin
  Result := gResTexts[aTextId];
  hotKeyStr := Trim(aHotkeyStr);
  if hotKeyStr <> '' then
    Result := Result + Format(' (''%s'')', [hotKeyStr]);
end;


function GetHintWHotkey(aTextId: Integer; aKeyFunc: TKMKeyFunction): String;
begin
  Result := GetHintWHotkey(aTextId, gResKeys.GetKeyNameById(aKeyFunc));
end;


// Try to find path to file with local suffixes, f.e. TSK01.waterfall.eng.wav
function GetLocalizedFilePath(aPath: string; aLocale, aFallbackLocale, aExt: AnsiString): string;
begin
  Result := aPath + '.' + String(aLocale) + String(aExt); // Try to file with our locale first
  if FileExists(Result) then
    Exit
  else
  begin
    Result := aPath + '.' + String(aFallbackLocale) + String(aExt); // then with fallback locale
    if FileExists(Result) then
      Exit
    else
    begin
      Result := aPath + '.' + String(DEFAULT_LOCALE) + String(aExt); // then with default locale (eng)
      if FileExists(Result) then
        Exit
      else
      begin
        Result := aPath + String(aExt); // and finally without any locale
        if FileExists(Result) then
          Exit
        else
          Exit('');
      end;
    end;
  end;
end;


{$IFDEF MSWindows}
// Logical comparison of the string, as Windows do
// taken from https://stackoverflow.com/questions/10108789/is-there-a-compare-function-for-file-name-sorting
function StrCmpLogicalW(psz1, psz2: PWideChar): Integer; stdcall; external 'shlwapi.dll';
{$ENDIF}


function CompareTextLogical(A, B: UnicodeString): Integer;
begin
  {$IFDEF MSWindows}
  Result := StrCmpLogicalW(PWideChar(A), PWideChar(B));
  {$ELSE}
  Result := CompareText(A, B);
  {$ENDIF}
end;


end.

