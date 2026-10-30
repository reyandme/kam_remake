program KaM_Remake;
{$I ../KaM_Remake.inc}
uses
  cthreads, Interfaces, Forms, SysUtils,
  KM_FPCCompat in '../src/common/KM_FPCCompat.pas',
  KM_LCLCompat in '../src/forms/KM_LCLCompat.pas',
  KM_StreamWriter in '../src/utils/io/KM_StreamWriter.pas',
  KM_MacPaths in 'KM_MacPaths.pas',
  KM_Main, KM_Defaults;


type
  TKMMacExceptionReporter = class
    procedure Handle(aSender: TObject; aException: Exception);
  end;

var
  gExceptionReporter: TKMMacExceptionReporter;


procedure TKMMacExceptionReporter.Handle(aSender: TObject; aException: Exception);
begin
  WriteLn(StdErr, aException.ClassName, ': ', aException.Message);
  DumpExceptionBackTrace(StdErr);
  Application.ShowException(aException);
end;


begin
  Application.Initialize;
  Application.Title := 'KaM Remake';
  gExceptionReporter := TKMMacExceptionReporter.Create;
  Application.OnException := gExceptionReporter.Handle;
  try
    try
      ExeDir := MacGameDataDir;
      gMain := TKMMain.Create;
      try
        gMain.Start;
        Application.Run;
      finally
        FreeAndNil(gMain);
      end;
    except
      on E: Exception do
      begin
        WriteLn(StdErr, E.ClassName, ': ', E.Message);
        DumpExceptionBackTrace(StdErr);
        ExitCode := 1;
      end;
    end;
  finally
    Application.OnException := nil;
    FreeAndNil(gExceptionReporter);
  end;
end.
