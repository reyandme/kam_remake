unit KM_Test_Swine;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMRunnerSwine_Process = class(TKMTest)
  protected
    function DoTick(aTick: Cardinal): Boolean; override;
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
  public
    class function TestTags: TKMTestTagSet; override;
    class function TestDescription: string; override;
  end;

implementation
uses
  Windows, SysUtils, Classes, Math,
  Generics.Collections, Generics.Defaults,
  KM_CommonClasses, KM_Defaults, KM_Points, KM_CommonUtils,
  KM_GameApp, KM_Log, KM_HandsCollection, KM_HouseCollection, KM_Resource,
  KM_Terrain, KM_Units, KM_Campaigns, KM_Houses,
  KM_GameParams,
  KM_Exceptions,
  KM_CampaignTypes,
  KM_HandSpectator, KM_ResHouses, KM_Hand, KM_HandTypes, KM_UnitsCollection, KM_UnitGroup,
  KM_GameSettings,
  KM_CommonTypes, KM_MapTypes, KM_FileIO, KM_Game, KM_GameInputProcess, KM_GameTypes, KM_InterfaceGame,
  KM_UnitGroupTypes,
  KM_ResTypes, KM_CampaignClasses;

procedure TKMRunnerSwine_Process.SetUp;
var
  H: TKMHouse;
begin
  inherited;
  fResults.ValueCount := 1;
  gGameApp.NewEmptyMap(32, 32);

  // Add the Swine Farm
  H := gHands[0].AddHouse(htSwine, 16, 16, False);

  // A swine farm requires multiple corn deliveries to grow a pig (random beast array needs 4 feeds)
  // We supply 20 corn so it's guaranteed to feed the beasts enough times to produce at least 1 pig
  H.ResIn[1] := 20;

  // Add the animal breeder
  gHands[0].AddUnit(utAnimalBreeder, KMPoint(16, 17));
end;

function TKMRunnerSwine_Process.DoTick(aTick: Cardinal): Boolean;
begin
  // Keep running until at least 1 pig is produced
  Result := gHands[0].Stats.GetWaresProduced(wtPig) = 0;
end;

procedure TKMRunnerSwine_Process.Execute(aRun: Integer);
begin
  SetKaMSeed(aRun+1);
  SimulateGame;

  // Check if it produced a pig
  fResults.Value[aRun, 0] := gHands[0].Stats.GetWaresProduced(wtPig);

  AssertTrue(fResults.Value[aRun, 0] >= 1, 'Swine farm should have processed enough corn to grow and produce a pig');

  gGameApp.StopGame(grSilent);
end;

class function TKMRunnerSwine_Process.TestTags: TKMTestTagSet;
begin
  Result := [tcSwine, tcAnimalBreeder, tcEconomy];
end;

class function TKMRunnerSwine_Process.TestDescription: string;
begin
  Result := 'Tests the swine farm''s ability to feed pigs multiple times using corn until a pig is produced.';
end;

initialization
  RegisterTest(TKMRunnerSwine_Process);
end.
