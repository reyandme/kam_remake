unit ParallelRun;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, Unit_Runner, Runner_Game, ComInterface, GeneticAlgorithm, Unit1;


type
  TKMParallelRun = class
  private
    fForm: TForm2;

    fSimSetup: TSimSetup;
    fGASetup: TGASetup;
    fCommunication: TKMComInterface;
    procedure Log(aLog: String);
  public
    constructor Create(aForm: TForm2);
    destructor Destroy(); override;

    procedure InitSimulation();
    procedure RunSimulation();
    procedure LogResults();
  end;

implementation

const
  LOG_ACTIVE = False;


constructor TKMParallelRun.Create(aForm: TForm2);
begin
  fForm := aForm;
  fGASetup.Population := nil;
  fSimSetup.RunningClass := '';
  fSimSetup.SimNumber := 0;
  fSimSetup.SimTimeInMin := 0;
  fCommunication := TKMComInterface.Create();
  Log('TKMParallelRun was created');
end;


destructor TKMParallelRun.Destroy();
begin
  fCommunication.Free;
end;


procedure TKMParallelRun.Log(aLog: String);
begin
  if LOG_ACTIVE then
    fForm.Memo1.Lines.Append(aLog);
end;


procedure TKMParallelRun.InitSimulation();
begin
  Log('Initialization');
  fCommunication.SetupSimulation(fSimSetup, fGASetup);
end;


procedure TKMParallelRun.RunSimulation();
var
  Check: Boolean;
  I: Integer;
  RunnerClass: TKMRunnerClass;
  Runner: TKMRunnerCommon;
  GARunner: TKMRunnerGA_Common;
  Output: TKMRunResults;
begin
  Check := False;
  for I := 0 to Length(RunnerList) - 1 do
    if (CompareText(RunnerList[I].ClassName, fSimSetup.RunningClass) = 0) then
    begin
      Check := True;
      Log('Name was found');
      break;
    end;
  if not Check then
  begin
    Log('Name was NOT found : ' + RunnerList[3].ClassName + ' vs ' + fSimSetup.RunningClass);
    Exit;
  end;


  RunnerClass := RunnerList[I]; // ID of running test - planner / builder / predictor etc.
  Runner := RunnerClass.Create(nil); // No render in parallel run
  try
    Log('Start simulation');
    Runner.Duration := fSimSetup.SimTimeInMin; // Minutes of simulation
    if (Runner.ClassType.InheritsFrom(TKMRunnerGA_Common)) then
    begin
      GARunner := TKMRunnerGA_Common(Runner);
      GARunner.IOData := fGASetup;
      GARunner.SimSetup := fSimSetup;
      Output := Runner.Run(1); // Only 1 run
      fGASetup := GARunner.IOData;
    end
    else
      Output := Runner.Run(1); // Only 1 run

  finally
    Runner.Free;
  end;

  Log('End simulation');
end;


procedure TKMParallelRun.LogResults();
begin
  Log('Log Results');
  fCommunication.LogSimulationResults(fSimSetup, fGASetup);
end;

end.

