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
  KM_Test_Bakery in 'KM_Test_Bakery.pas',
  KM_Test_BuildingPlan in 'KM_Test_BuildingPlan.pas',
  KM_Test_FarmHarvest in 'KM_Test_FarmHarvest.pas',
  KM_Test_FarmPlant in 'KM_Test_FarmPlant.pas',
  KM_Test_Fight95 in 'KM_Test_Fight95.pas',
  KM_Test_Hungarian in 'KM_Test_Hungarian.pas',
  KM_Test_Mill in 'KM_Test_Mill.pas',
  KM_Test_Sawmill in 'KM_Test_Sawmill.pas',
  KM_Test_Sawmill_DeliveryIn in 'KM_Test_Sawmill_DeliveryIn.pas',
  KM_Test_Sawmill_DeliveryOut in 'KM_Test_Sawmill_DeliveryOut.pas',
  KM_Test_Stone in 'KM_Test_Stone.pas',
  KM_Test_Woodcutter_Chop in 'KM_Test_Woodcutter_Chop.pas',
  KM_Test_Woodcutter_Plant in 'KM_Test_Woodcutter_Plant.pas',
  KM_Test_Vineyard in 'KM_Test_Vineyard.pas',
  KM_Test_Swine in 'KM_Test_Swine.pas';

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
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
