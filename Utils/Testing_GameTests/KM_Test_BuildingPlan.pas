unit KM_Test_BuildingPlan;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMTest_BuildingPlan = class(TKMTest)
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
  KM_Defaults, KM_Points, KM_CommonUtils,
  KM_GameApp, KM_HandsCollection, KM_Terrain,
  KM_ResMapElements, KM_ResTypes;


procedure TKMTest_BuildingPlan.SetUp;
begin
  inherited;

  gGameApp.NewEmptyMap(32, 32);

  gHands[0].AddHousePlan(htSchool, KMPoint(16, 20));

  gHands[0].AddUnit(utBuilder, KMPoint(16, 21));

  // Initialize passability so builder can evaluate CanWalkTo
  gHands[0].AfterMissionInit(False);
  gTerrain.UpdatePassability;
end;


function TKMTest_BuildingPlan.DoTick(aTick: Cardinal): Boolean;
var
  I: Integer;
begin
  // Continue simulation (True) until the house plan is fully dug out
  Result := True;
  for I := 0 to gHands[0].Houses.Count - 1 do
  begin
    var H := gHands[0].Houses[I];
    if (H.HouseType = htSchool) and (H.BuildingState >= hbsWood) then
      Result := False; // Dug out
  end;
end;


procedure TKMTest_BuildingPlan.Execute(aRun: Integer);
var
  I: Integer;
begin
  SetKaMSeed(aRun+1);
  SimulateGame;

  fResults.Value[aRun] := 0;

  // If the house reached hbsWood state, the builder has finished clearing the site
  for I := 0 to gHands[0].Houses.Count - 1 do
  begin
    var H := gHands[0].Houses[I];
    if (H.HouseType = htSchool) and (H.BuildingState >= hbsWood) then
      fResults.Value[aRun] := 1;
  end;

  AssertTrue(fResults.Value[aRun] = 1, 'Builder should have dug out the house plan');

  gGameApp.StopGame(grSilent);
end;


class function TKMTest_BuildingPlan.TestTags: TKMTestTagSet;
begin
  Result := [tcBuilder, tcSchool];
end;


class function TKMTest_BuildingPlan.TestDescription: string;
begin
  Result := 'Tests a builder''s ability to dig out a house plan.';
end;


initialization
  RegisterTest(TKMTest_BuildingPlan);
end.
