unit KM_NetAuthUnsecure;
{$I KaM_Remake.inc}
interface
uses
  Classes, KM_CommonClasses;

type
  TKMNetSecurity = class
  public
    class procedure GenerateChallenge(M: TKMemoryStreamBinary; aSender: Integer);
    class function SolveChallenge(M: TKMemoryStreamBinary; aSender: Integer): TKMemoryStreamBinary;
    class function ValidateSolution(M: TKMemoryStreamBinary; aSender: Integer): Boolean;
  end;

implementation


{ TKMNetSecurity }
class procedure TKMNetSecurity.GenerateChallenge(M: TKMemoryStreamBinary; aSender: Integer);
begin
  //Leave M unchanged
end;


class function TKMNetSecurity.SolveChallenge(M: TKMemoryStreamBinary; aSender: Integer): TKMemoryStreamBinary;
begin
  Result := TKMemoryStreamBinary.Create;
  //Result.Write(Integer(GAME_BETA_REVISION));
end;


class function TKMNetSecurity.ValidateSolution(M: TKMemoryStreamBinary; aSender: Integer): Boolean;
//var
//  BetaVersion: Integer;
begin
//  M.Read(BetaVersion);
//  Result := BetaVersion = GAME_BETA_REVISION;
  Result := True;
end;

end.
