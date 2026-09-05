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

  KM_Test in 'KM_Test.pas',
  KM_Test_Archers_GoFar in 'KM_Test_Archers_GoFar.pas',
  KM_Test_Bakery in 'KM_Test_Bakery.pas',
  KM_Test_BuildingPlan in 'KM_Test_BuildingPlan.pas',
  KM_Test_FarmHarvest in 'KM_Test_FarmHarvest.pas',
  KM_Test_FarmPlant in 'KM_Test_FarmPlant.pas',
  KM_Test_Fight95 in 'KM_Test_Fight95.pas',
  KM_Test_Hungarian_LongWalk in 'KM_Test_Hungarian_LongWalk.pas',
  KM_Test_Hungarian_SwapPerf in 'KM_Test_Hungarian_SwapPerf.pas',
  KM_Test_Melee_HelperStandsIdle in 'KM_Test_Melee_HelperStandsIdle.pas',
  KM_Test_Mill in 'KM_Test_Mill.pas',
  KM_Test_Recruit_EatsAndReturns in 'KM_Test_Recruit_EatsAndReturns.pas',
  KM_Test_Recruit_EquipWhileEating in 'KM_Test_Recruit_EquipWhileEating.pas',
  KM_Test_Recruit_KilledInside in 'KM_Test_Recruit_KilledInside.pas',
  KM_Test_Recruit_StarvedInside in 'KM_Test_Recruit_StarvedInside.pas',
  KM_Test_SaveLoad_RoundTrip in 'KM_Test_SaveLoad_RoundTrip.pas',
  KM_Test_Sawmill in 'KM_Test_Sawmill.pas',
  KM_Test_Sawmill_DeliveryIn in 'KM_Test_Sawmill_DeliveryIn.pas',
  KM_Test_Sawmill_DeliveryOut in 'KM_Test_Sawmill_DeliveryOut.pas',
  KM_Test_Stone in 'KM_Test_Stone.pas',
  KM_Test_TerrainGetClosestTile in 'KM_Test_TerrainGetClosestTile.pas',
  KM_Test_Walk_UnwalkableTarget in 'KM_Test_Walk_UnwalkableTarget.pas',
  KM_Test_Woodcutter_Chop in 'KM_Test_Woodcutter_Chop.pas',
  KM_Test_Woodcutter_Plant in 'KM_Test_Woodcutter_Plant.pas',
  KM_Test_Vineyard in 'KM_Test_Vineyard.pas',
  KM_Test_Swine in 'KM_Test_Swine.pas',
  KM_Test_EngagedMeleeChasingPassing_Warrior in 'KM_Test_EngagedMeleeChasingPassing_Warrior.pas',
  KM_Test_EngagedMeleeChasingPassing_Citizen in 'KM_Test_EngagedMeleeChasingPassing_Citizen.pas';

{$R *.res}

{$IFDEF WDC}
  // Enable usage of 3Gb or 4Gb of RAM for Win32 Delphi application
  // https://docwiki.embarcadero.com/RADStudio/Alexandria/en/Increasing_the_Memory_Address_Space
  {$SetPEFlags IMAGE_FILE_LARGE_ADDRESS_AWARE}
{$ENDIF}

var
  Form2: TForm2;

begin
  Application.Initialize;
  Application.ShowMainForm := False; // Form is shown by RunFromCmdLine / Application.Run itself
  Application.CreateForm(TForm2, Form2);

  // Batch mode for the command line, see TForm2.RunFromCmdLine
  if not Form2.RunFromCmdLine then
  begin
    Application.ShowMainForm := True;
    Application.Run;
  end;
end.
