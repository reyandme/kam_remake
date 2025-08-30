unit KM_CampaignUtils;
{$I KaM_Remake.inc}
interface

type
  TKMCampaignUtils = class
  public
    class function GetMissionFile(const aPath, aShortName: UnicodeString; aIndex: Byte; const aExt: UnicodeString = '.dat'): String;
    class function GetMissionName(const aShortName: UnicodeString; aIndex: Byte): String;
  end;


implementation
uses
  SysUtils;


class function TKMCampaignUtils.GetMissionFile(const aPath, aShortName: UnicodeString; aIndex: Byte; const aExt: UnicodeString = '.dat'): String;
begin
  var missionName := GetMissionName(aShortName, aIndex);
  Result := aPath + missionName + PathDelim + missionName + aExt;
end;


class function TKMCampaignUtils.GetMissionName(const aShortName: UnicodeString; aIndex: Byte): String;
begin
  Result := aShortName + Format('%.2d', [aIndex + 1]);
end;


end.
