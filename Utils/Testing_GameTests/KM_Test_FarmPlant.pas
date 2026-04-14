unit KM_Test_FarmPlant;
{$I KaM_Remake.inc}
interface
uses
  Unit_Runner;

type
  TKMRunnerFarm_Plant = class(TKMRunnerCommon)
  protected
    function OnTickCondition(aTick: Cardinal): Boolean; override;
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
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
  KM_ResMapElements,
  KM_GameParams,
  KM_Exceptions,
  KM_CampaignTypes,
  KM_HandSpectator, KM_ResHouses, KM_Hand, KM_HandTypes, KM_UnitsCollection, KM_UnitGroup,
  KM_GameSettings,
  KM_CommonTypes, KM_MapTypes, KM_FileIO, KM_Game, KM_GameInputProcess, KM_GameTypes, KM_InterfaceGame,
  KM_UnitGroupTypes,
  KM_ResTypes, KM_CampaignClasses;

procedure TKMRunnerFarm_Plant.SetUp;
begin
  inherited;
  fResults.ValueCount := 1;
  gGameApp.NewEmptyMap(32, 32);

  gHands[0].AddHouse(htFarm, 16, 20, False);

  gHands[0].AddField(KMPoint(16, 22), ftCorn, 0, False, True);
  
  gHands[0].AddUnit(utFarmer, KMPoint(16, 21));
end;

function TKMRunnerFarm_Plant.OnTickCondition(aTick: Cardinal): Boolean;
begin
  Result := not ObjectIsCorn(gTerrain.Land[22, 16].Obj); // ObjectIsCorn expects ID
end;

procedure TKMRunnerFarm_Plant.Execute(aRun: Integer);
begin
  SetKaMSeed(aRun+1);
  SimulateGame;

  fResults.Value[aRun, 0] := 0;
  if ObjectIsCorn(gTerrain.Land[22, 16].Obj) then
    fResults.Value[aRun, 0] := 1;

  AssertTrue(fResults.Value[aRun, 0] = 1, 'Farmer should have planted corn');

  gGameApp.StopGame(grSilent);
end;

class function TKMRunnerFarm_Plant.TestCategories: TKMTestCategorySet;
begin
  Result := [tcFarm, tcPlantTree];
end;

class function TKMRunnerFarm_Plant.TestDescription: string;
begin
  Result := 'Tests a farmer''s ability to sow a clean field with wheat.';
end;

initialization
  RegisterRunner(TKMRunnerFarm_Plant);
end.
