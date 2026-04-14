unit KM_Test_Stone;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMRunnerStone = class(TKMTest)
  protected
    function OnTickCondition(aTick: Cardinal): Boolean; override;
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
    procedure TearDown; override;
  public
    class function TestCategories: TKMTestCategorySet; override;
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

{ TKMRunnerStone }
procedure TKMRunnerStone.SetUp;
begin
  inherited;
  fResults.ValueCount := 1;

  DYNAMIC_TERRAIN := False;

  gGameApp.NewEmptyMap(32, 32);

  // Set a stone deposit for mining
  // 132 is a base tile ID for Stone (tkStone)
  gTerrain.ScriptTrySetTile(16, 15, 132, 0);

  // Set the quarry house
  gHands[0].AddHouse(htQuarry, 16, 20, False);
  
  // Add the stonemason unit just outside the house
  gHands[0].AddUnit(utStonemason, KMPoint(16, 21));
end;


procedure TKMRunnerStone.TearDown;
begin
  inherited;
  DYNAMIC_TERRAIN := True;
end;

function TKMRunnerStone.OnTickCondition(aTick: Cardinal): Boolean;
begin
  // Continue simulation (True) until stone is produced
  Result := gHands[0].Stats.GetWaresProduced(wtStone) = 0;
end;

procedure TKMRunnerStone.Execute(aRun: Integer);
begin
  SetKaMSeed(aRun+1);
  
  // Run the simulation loop
  SimulateGame;

  // The stonemason should have found the stone, mined it, and delivered it.
  fResults.Value[aRun, 0] := gHands[0].Stats.GetWaresProduced(wtStone);

  AssertTrue(fResults.Value[aRun, 0] > 0, 'Stonemason should have mined some stone');

  gGameApp.StopGame(grSilent);
end;

class function TKMRunnerStone.TestCategories: TKMTestCategorySet;
begin
  Result := [tcQuarry, tcStonemason];
end;

class function TKMRunnerStone.TestDescription: string;
begin
  Result := 'Tests a stonemason''s ability to find stone, mine it, and deliver it to the quarry.';
end;

initialization
  RegisterRunner(TKMRunnerStone);
end.
