unit KM_NetworkUtils;
{$I KaM_Remake.inc}
interface

type
  TKMNetworkUtils = class

  public
    class function GetEscapedNewLineServerName(str: String): String; static;
    class function GetEscapedNewLineServerNameA(str: AnsiString): AnsiString; static;
  end;


implementation
uses
  StrUtils, SysUtils;


class function TKMNetworkUtils.GetEscapedNewLineServerName(str: String): String;
begin
  Result := StringReplace(str, '|', ' ', [rfReplaceAll]);
end;


// Add AnsiString version of the same procedure, to avoid type casting compilation hint
class function TKMNetworkUtils.GetEscapedNewLineServerNameA(str: AnsiString): AnsiString;
begin
  Result := AnsiString(GetEscapedNewLineServerName(String(str)));
end;


end.
