unit KM_MapUtils;
{$I KaM_Remake.inc}
interface
uses
  KM_Defaults, KM_MapTypes;

  function GuessMPPathRel(const aName, aExt: string; aCRC: Cardinal): string;
  function GuessMissionPathRel(const aMissionFileRelSP, aMissionName: string; aMapFullCRC: Cardinal; aIsMultiplayer: Boolean): string;

  function DetermineMapKind(const aFolderName: UnicodeString; out aMapKind: TKMMapKind): Boolean;
  function GetMapKind(aIsMultiplayer: Boolean): TKMMapKind;
  function IsCampaignMissionPathRel(const aMissionFileRel: string): Boolean;

implementation
uses
  SysUtils;


function GuessMPPathRel(const aName, aExt: string; aCRC: Cardinal): string;
var
  S: UnicodeString;
begin
  S := aName + '_' + IntToHex(aCRC, 8);
  Result := MAP_FOLDER_NAME[mkDL] + PathDelim + S + PathDelim + S + aExt;
  if not FileExists(ExeDir + Result) then
    Result := MAP_FOLDER_NAME[mkMP] + PathDelim + aName + PathDelim + aName + aExt;
end;


function GuessMissionPathRel(const aMissionFileRelSP, aMissionName: string; aMapFullCRC: Cardinal; aIsMultiplayer: Boolean): string;
begin
  if aIsMultiplayer then
    //In MP we can't store it since it will be MapsMP or MapsDL on different clients
    Result := GuessMPPathRel(aMissionName, '.dat', aMapFullCRC)
  else
    Result := aMissionFileRelSP; //In SP we store it
end;


//Try to determine TMapFolder for specified aFolderName
//Returns True when succeeded
function DetermineMapKind(const aFolderName: UnicodeString; out aMapKind: TKMMapKind): Boolean;
var
  MK: TKMMapKind;
begin
  Result := False;
  // no need to test mkUnknown
  for MK := Succ(Low(TKMMapKind)) to High(TKMMapKind) do
    if aFolderName = MAP_FOLDER_NAME[MK] then
    begin
      aMapKind := MK;
      Exit(True);
    end;
end;


function GetMapKind(aIsMultiplayer: Boolean): TKMMapKind;
begin
  if aIsMultiplayer then
    Result := mkMP
  else
    Result := mkSP;
end;


function IsCampaignMissionPathRel(const aMissionFileRel: string): Boolean;
begin
  Result := (aMissionFileRel <> '') and (Pos(MAP_FOLDER_NAME[mkCM] + PathDelim, aMissionFileRel) = 1);
end;


end.

