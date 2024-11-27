unit KM_NetworkUtils;
{$I KaM_Remake.inc}
interface

type
  TKMNetworkUtils = class

  public
    class function GetEscapedNewLineServerName(str: string): string; static;
  end;


implementation
uses
  StrUtils, SysUtils;

class function TKMNetworkUtils.GetEscapedNewLineServerName(str: string): string;
begin
  Result := StringReplace(str, '|', ' ', [rfReplaceAll]);
end;


end.



