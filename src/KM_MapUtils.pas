unit KM_MapUtils;
{$I KaM_Remake.inc}
interface

  function GuessMPPath(const aName, aExt: string; aCRC: Cardinal): string;

implementation
uses
  SysUtils,
  KM_Defaults, KM_MapTypes;

function GuessMPPath(const aName, aExt: string; aCRC: Cardinal): string;
var
  S: UnicodeString;
begin
  S := aName + '_' + IntToHex(aCRC, 8);
  Result := MAP_FOLDER[mfDL] + PathDelim + S + PathDelim + S + aExt;
  if not FileExists(ExeDir + Result) then
    Result := MAP_FOLDER[mfMP] + PathDelim + aName + PathDelim + aName + aExt;
end;


end.

