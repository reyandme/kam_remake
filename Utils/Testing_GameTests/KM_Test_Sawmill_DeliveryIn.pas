unit KM_Test_Sawmill_DeliveryIn;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMRunnerSawmill_DeliveryIn = class(TKMTest)
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
  KM_Terrain, KM_Units, KM_Campaigns, KM_Houses, KM_HouseStore,
  KM_GameParams,
  KM_Exceptions,
  KM_CampaignTypes,
  KM_HandSpectator, KM_ResHouses, KM_Hand, KM_HandTypes, KM_UnitsCollection, KM_UnitGroup,
  KM_GameSettings,
  KM_CommonTypes, KM_MapTypes, KM_FileIO, KM_Game, KM_GameInputProcess, KM_GameTypes, KM_InterfaceGame,
  KM_UnitGroupTypes,
  KM_ResTypes, KM_CampaignClasses;

{ TKMRunnerSawmill_DeliveryIn }
procedure TKMRunnerSawmill_DeliveryIn.SetUp;
var
  Store: TKMHouseStore;
  I, J: Integer;
begin
  inherited;
  fResults.ValueCount := 1;
  gGameApp.NewEmptyMap(32, 32);

  for I := 9 to 21 do
      gHands[0].AddRoadToList(KMPoint(I, 17));
  gHands[0].AfterMissionInit(False);

  Store := TKMHouseStore(gHands[0].AddHouse(htStore, 10, 16, False));
  Store.WareAddToIn(wtTrunk, 1, True); // FromScript = True

  gHands[0].AddHouse(htSawmill, 20, 16, False);
  
  // Serf to deliver the trunk
  gHands[0].AddUnit(utSerf, KMPoint(10, 17));
end;

function TKMRunnerSawmill_DeliveryIn.OnTickCondition(aTick: Cardinal): Boolean;
var
  H: TKMHouse;
begin
  Result := True;
  H := gHands[0].FindHouse(htSawmill);
  if H <> nil then
  begin
    if H.ResIn[1] > 0 then
      Result := False;
  end;
end;

procedure TKMRunnerSawmill_DeliveryIn.Execute(aRun: Integer);
var
  H: TKMHouse;
begin
  SetKaMSeed(aRun+1);
  SimulateGame;

  fResults.Value[aRun, 0] := 0;
  H := gHands[0].FindHouse(htSawmill);
  if H <> nil then
  begin
    fResults.Value[aRun, 0] := H.ResIn[1];
  end;

  AssertTrue(fResults.Value[aRun, 0] > 0, 'Serf should have delivered trunk to sawmill');

  gGameApp.StopGame(grSilent);
end;

class function TKMRunnerSawmill_DeliveryIn.TestCategories: TKMTestCategorySet;
begin
  Result := [tcSawmill, tcEconomy, tcDeliveryIn];
end;

class function TKMRunnerSawmill_DeliveryIn.TestDescription: string;
begin
  Result := 'Tests a servant''s ability to carry a log from the warehouse to the sawmill.';
end;

initialization
  RegisterRunner(TKMRunnerSawmill_DeliveryIn);
end.
