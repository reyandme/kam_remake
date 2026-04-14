unit Runner_TestVineyard_Harvest;
{$I KaM_Remake.inc}
interface
uses
  Unit_Runner;

type
  TKMRunnerVineyard_Harvest = class(TKMRunnerCommon)
  protected
    function OnTickCondition(aTick: Cardinal): Boolean; override;
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
  public
    class function TestCategories: TKMTestCategorySet; override;
    class function TestDescription: UnicodeString; override;
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

procedure TKMRunnerVineyard_Harvest.SetUp;
begin
  inherited;
  fResults.ValueCount := 1;
  gGameApp.NewEmptyMap(32, 32);

  gHands[0].AddHouse(htVineyard, 16, 20, False);

  // Field plan at (16, 22) -> Stage 3 is ready to harvest for grapes
  // ftWine uses WINE_STAGES_COUNT = 4 (0..3)
  gHands[0].AddField(KMPoint(16, 22), ftWine, 3, False, True);
  
  // Add the farmer unit
  gHands[0].AddUnit(utFarmer, KMPoint(16, 21));
end;

function TKMRunnerVineyard_Harvest.OnTickCondition(aTick: Cardinal): Boolean;
var
  H: TKMHouse;
begin
  Result := True;
  H := gHands[0].FindHouse(htVineyard);
  if H <> nil then
  begin
    if H.ResOut[1] > 0 then
      Result := False;
  end;
end;

procedure TKMRunnerVineyard_Harvest.Execute(aRun: Integer);
var
  H: TKMHouse;
begin
  SetKaMSeed(aRun+1);
  SimulateGame;

  fResults.Value[aRun, 0] := 0;
  H := gHands[0].FindHouse(htVineyard);
  if H <> nil then
  begin
    fResults.Value[aRun, 0] := H.ResOut[1];
  end;

  AssertTrue(fResults.Value[aRun, 0] > 0, 'Farmer should have harvested grapes and delivered them to the vineyard');

  gGameApp.StopGame(grSilent);
end;

class function TKMRunnerVineyard_Harvest.TestCategories: TKMTestCategorySet;
begin
  Result := [tcVineyard, tcEconomy];
end;

class function TKMRunnerVineyard_Harvest.TestDescription: UnicodeString;
begin
  Result := 'Tests a farmer''s ability to collect ripe grapes and carry them back to the vineyard.';
end;

initialization
  RegisterRunner(TKMRunnerVineyard_Harvest);
end.
