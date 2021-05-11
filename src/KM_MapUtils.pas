unit KM_MapUtils;
{$I KaM_Remake.inc}
interface
uses
  KM_MapTypes;

  function GuessMPPathRel(const aName, aExt: string; aCRC: Cardinal): string;
  function GuessMissionPathRel(const aMissionFileRelSP, aMissionName: string; aMapFullCRC: Cardinal; aIsMultiplayer: Boolean): string;

  function DetermineMapFolder(const aFolderName: UnicodeString; out aMapFolder: TKMapFolder): Boolean;
  function GetMapFolderType(aIsMultiplayer: Boolean): TKMapFolder;

implementation
uses
  SysUtils,
  KM_Defaults;

function GuessMPPathRel(const aName, aExt: string; aCRC: Cardinal): string;
var
  S: UnicodeString;
begin
  S := aName + '_' + IntToHex(aCRC, 8);
  Result := MAP_FOLDER[mfDL] + PathDelim + S + PathDelim + S + aExt;
  if not FileExists(ExeDir + Result) then
    Result := MAP_FOLDER[mfMP] + PathDelim + aName + PathDelim + aName + aExt;
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
//Returns true when succeeded
function DetermineMapFolder(const aFolderName: UnicodeString; out aMapFolder: TKMapFolder): Boolean;
var
  F: TKMapFolder;
begin
  for F := Low(TKMapFolder) to High(TKMapFolder) do
    if aFolderName = MAP_FOLDER[F] then
    begin
      aMapFolder := F;
      Result := True;
      Exit;
    end;
  Result := False;
end;


function GetMapFolderType(aIsMultiplayer: Boolean): TKMapFolder;
begin
  if aIsMultiplayer then
    Result := mfMP
  else
    Result := mfSP;
end;


end.

