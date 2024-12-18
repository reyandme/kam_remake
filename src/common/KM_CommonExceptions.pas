unit KM_CommonExceptions;
{$I KaM_Remake.inc}
interface
uses
  SysUtils, KM_Points;

type
  //Custom Exception that includes a TKMPoint
  ELocError = class(Exception)
    Loc: TKMPoint;
    constructor Create(const aMsg: UnicodeString; const aLoc: TKMPoint);
  end;

  // Error while game initialization
  // madExcept ignores it, since we just want to show simple message instead
  EGameInitError = class(Exception);

implementation


{ ELocError }
constructor ELocError.Create(const aMsg: UnicodeString; const aLoc: TKMPoint);
begin
  inherited Create(aMsg);
  Loc := aLoc;
end;


end.
