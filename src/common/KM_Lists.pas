unit KM_Lists;
{$I KaM_Remake.inc}
interface
uses
  Classes,
  SysUtils,
  KM_CommonTypes;

type
  TKMMapsCRCList = class
  private
    fEnabled: Boolean;
    fMapsList: TStringList;
    fOnMapsUpdate: TUnicodeStringEvent;

    procedure MapsUpdated;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromString(const aString: UnicodeString);
    function PackToString: UnicodeString;

    property OnMapsUpdate: TUnicodeStringEvent read fOnMapsUpdate write fOnMapsUpdate;
    property Count: Integer read GetCount;
    property Enabled: Boolean read fEnabled write fEnabled;

    procedure Clear;
    procedure RemoveMissing(aMapsCRCArray: TKMCardinalArray);
    function Contains(aMapCRC: Cardinal): Boolean;
    procedure Add(aMapCRC: Cardinal);
    procedure Remove(aMapCRC: Cardinal);
    procedure Replace(aOldCRC, aNewCRC: Cardinal);
  end;

implementation

const
  MAPS_CRC_DELIMITER = ':';

{ TKMMapsCRCList }
constructor TKMMapsCRCList.Create;
begin
  inherited Create;

  fEnabled := True;
  fMapsList := TStringList.Create;
  fMapsList.Delimiter       := MAPS_CRC_DELIMITER;
  fMapsList.StrictDelimiter := True; // Requires D2006 or newer.
end;


destructor TKMMapsCRCList.Destroy;
begin
  FreeAndNil(fMapsList);
  inherited;
end;


function TKMMapsCRCList.GetCount: Integer;
begin
  if not fEnabled then Exit(0);

  Result := fMapsList.Count;
end;


procedure TKMMapsCRCList.MapsUpdated;
begin
  if Assigned(fOnMapsUpdate) then
    fOnMapsUpdate(PackToString);
end;


procedure TKMMapsCRCList.LoadFromString(const aString: UnicodeString);
var
  I: Integer;
  mapCRC : Int64;
  stringList: TStringList;
begin
  if not fEnabled then Exit;

  fMapsList.Clear;
  stringList := TStringList.Create;
  stringList.Delimiter := MAPS_CRC_DELIMITER;
  stringList.DelimitedText   := Trim(aString);

  for I := 0 to stringList.Count - 1 do
  begin
    if TryStrToInt64(Trim(stringList[I]), mapCRC)
      and (mapCRC > 0)
      and not Contains(Cardinal(mapCRC)) then
      fMapsList.Add(Trim(stringList[I]));
  end;

  stringList.Free;
end;


function TKMMapsCRCList.PackToString: UnicodeString;
begin
  if not fEnabled then Exit('');

  Result := fMapsList.DelimitedText;
end;


procedure TKMMapsCRCList.Clear;
begin
  if not fEnabled then Exit;

  fMapsList.Clear;
end;


//Remove missing Favourites Maps from list, check if are of them are presented in the given maps CRC array.
procedure TKMMapsCRCList.RemoveMissing(aMapsCRCArray: TKMCardinalArray);

  function ArrayContains(aValue: Cardinal): Boolean;
  var
    I: Integer;
  begin
    Result := False;
    for I := Low(aMapsCRCArray) to High(aMapsCRCArray) do
      if aMapsCRCArray[I] = aValue then
      begin
        Result := True;
        Break;
      end;
  end;

var
  I: Integer;
begin
  if not fEnabled then Exit;

  I := fMapsList.Count - 1;
  //We must check, that all values from favorites are presented in maps CRC array. If not - then remove it from favourites
  while (fMapsList.Count > 0) and (I >= 0) do
  begin
    if not ArrayContains(StrToInt64(fMapsList[I])) then
    begin
      fMapsList.Delete(I);
      MapsUpdated;
    end;

    Dec(I);
  end;
end;


function TKMMapsCRCList.Contains(aMapCRC: Cardinal): Boolean;
begin
  if (Self = nil) or not fEnabled then Exit(False);

  Result := fMapsList.IndexOf(IntToStr(aMapCRC)) <> -1;
end;


procedure TKMMapsCRCList.Add(aMapCRC: Cardinal);
begin
  if not fEnabled then Exit;

  if not Contains(aMapCRC) then
  begin
    fMapsList.Add(IntToStr(aMapCRC));
    MapsUpdated;
  end;
end;


procedure TKMMapsCRCList.Remove(aMapCRC: Cardinal);
var
  I: Integer;
begin
  if not fEnabled then Exit;

  I := fMapsList.IndexOf(IntToStr(aMapCRC));
  if I <> -1 then
    fMapsList.Delete(I);

  MapsUpdated;
end;


procedure TKMMapsCRCList.Replace(aOldCRC, aNewCRC: Cardinal);
begin
  if not fEnabled then Exit;

  if Contains(aOldCRC) then
  begin
    Remove(aOldCRC);
    Add(aNewCRC);
  end;
end;

end.
