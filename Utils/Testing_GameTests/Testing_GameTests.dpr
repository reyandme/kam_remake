program Testing_GameTests;
{$I KaM_Remake.inc}
uses
  {$IFDEF USE_MAD_EXCEPT}
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListModules,
  {$ENDIF}
  //FastMM4,
  Forms,
  {$IFDEF FPC}
  Interfaces,
  {$ENDIF }
  {$IFDEF WDC}
    WinApi.Windows, // To allow to set {$SetPEFlags IMAGE_FILE_LARGE_ADDRESS_AWARE} for 3Gb or 4Gb RAM usage for Win32 Delphi app
  {$ENDIF}
  Unit1 in 'Unit1.pas' {Form2},
  Unit_Runner in 'Unit_Runner.pas',
  Runner_TestStone in 'Runner_TestStone.pas',
  Runner_TestSawmill_Process in 'Runner_TestSawmill_Process.pas',
  Runner_TestSawmill_DeliveryIn in 'Runner_TestSawmill_DeliveryIn.pas',
  Runner_TestSawmill_DeliveryOut in 'Runner_TestSawmill_DeliveryOut.pas',
  Runner_TestWoodcutter_Chop in 'Runner_TestWoodcutter_Chop.pas',
  Runner_TestWoodcutter_Plant in 'Runner_TestWoodcutter_Plant.pas',
  Runner_TestFarm_Plant in 'Runner_TestFarm_Plant.pas',
  Runner_TestFarm_Harvest in 'Runner_TestFarm_Harvest.pas',
  Runner_TestVineyard_Harvest in 'Runner_TestVineyard_Harvest.pas',
  Runner_TestBuilding_Plan in 'Runner_TestBuilding_Plan.pas',
  Runner_TestMill_Process in 'Runner_TestMill_Process.pas',
  Runner_TestBakery_Process in 'Runner_TestBakery_Process.pas',
  Runner_TestSwine_Process in 'Runner_TestSwine_Process.pas',
  Runner_TestHungarian in 'Runner_TestHungarian.pas',
  Runner_TestFight95 in 'Runner_TestFight95.pas';

{$R *.res}

{$IFDEF WDC}
  // Enable usage of 3Gb or 4Gb of RAM for Win32 Delphi application
  // https://docwiki.embarcadero.com/RADStudio/Alexandria/en/Increasing_the_Memory_Address_Space
  {$SetPEFlags IMAGE_FILE_LARGE_ADDRESS_AWARE}
{$ENDIF}

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

{$IFDEF PARALLEL_Testing_GameTests}
var
  ParRun: TKMParallelRun;
{$ENDIF}
begin
  Application.Initialize;
  Application.CreateForm(TForm2, Form2);
  {$IFDEF PARALLEL_Testing_GameTests}
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
  {$ENDIF}
  Application.Run;
end.
