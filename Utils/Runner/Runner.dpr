program Runner;
{$I KaM_Remake.inc}
uses
  Forms,
  {$IFDEF FPC}
  Interfaces,
  {$ENDIF }
  Unit1 in 'Unit1.pas' {Form2},
  Unit_Runner in 'Unit_Runner.pas',
  Runner_Game in 'Runner_Game.pas',
  ComInterface in 'ComInterface.pas',
  ParallelRun in 'ParallelRun.pas',
  GeneticAlgorithm in 'GeneticAlgorithm.pas',
  GeneticAlgorithmParameters in 'GeneticAlgorithmParameters.pas';

{$R *.res}

procedure DebugLogString();
var
  K: Integer;
  Params: String;
  debugFile: TextFile;
begin
  Params := '';
  AssignFile(debugFile, 'DEBUG_inputParameters.txt');
  try
    rewrite(debugFile);
    for K := 0 to ParamCount do
      writeln(debugFile, ParamStr(K));
    CloseFile(debugFile);
  except
    //on E: EInOutError do
    //  writeln('File handling error occurred. Details: ', E.ClassName, '/', E.Message);
  end;
end;

var
  ParRun: TKMParallelRun;
begin
  Application.Initialize;
  Application.CreateForm(TForm2, Form2);
  if (ParamCount > 0) then
  begin
    //DebugLogString();
    ParRun := TKMParallelRun.Create(Form2);
    try
      PARALLEL_RUN := True;
      ParRun.InitSimulation();
      ParRun.RunSimulation();
      ParRun.LogResults();
    finally
      ParRun.Free();
    end;
    Application.Terminate;
  end;
  
  Application.Run;
end.
