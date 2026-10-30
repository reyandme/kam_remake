unit KM_FPCCompat;
{$I KaM_Remake.inc}
interface
uses
  Classes;


type
  {$IF FPC_FULLVERSION >= 30301}
  TProc = reference to procedure;
  TProc<T> = reference to procedure(aValue: T);
  TProc<T1, T2> = reference to procedure(aValue1: T1; aValue2: T2);
  {$ELSE}
  TProc = procedure;
  {$ENDIF}

  TKMFile = class
  public
    class function ReadAllText(const aPath: string): string; static;
  end;
  TFile = TKMFile;


implementation


class function TKMFile.ReadAllText(const aPath: string): string;
var
  stream: TStringStream;
begin
  stream := TStringStream.Create('');
  try
    stream.LoadFromFile(aPath);
    Result := stream.DataString;
  finally
    stream.Free;
  end;
end;


end.
