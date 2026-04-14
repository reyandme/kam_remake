unit KM_Test_Sawmill_DeliveryOut;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMRunnerSawmill_DeliveryOut = class(TKMTest)
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
  KM_Terrain, KM_Units, KM_Campaigns, KM_Houses, KM_HouseStore,
  KM_GameParams,
  KM_Exceptions,
  KM_CampaignTypes,
  KM_HandSpectator, KM_ResHouses, KM_Hand, KM_HandTypes, KM_UnitsCollection, KM_UnitGroup,
  KM_GameSettings,
  KM_CommonTypes, KM_MapTypes, KM_FileIO, KM_Game, KM_GameInputProcess, KM_GameTypes, KM_InterfaceGame,
  KM_UnitGroupTypes,
  KM_ResTypes, KM_CampaignClasses;

procedure TKMRunnerSawmill_DeliveryOut.SetUp;
var
  H: TKMHouse;
  I, J: Integer;
begin
  inherited;
  fResults.ValueCount := 1;
  gGameApp.NewEmptyMap(32, 32);

  for I := 9 to 21 do
      gHands[0].AddRoadToList(KMPoint(I, 17));
  gHands[0].AfterMissionInit(False);

  gHands[0].AddHouse(htStore, 10, 16, False);

  H := gHands[0].AddHouse(htSawmill, 20, 16, False);
  // Give sawmill completed product (wtWood is index 1 for outputs of Sawmill)
  H.ResIn[1] := 2;

  gHands[0].AddUnit(utSerf, KMPoint(20, 17));
  gHands[0].AddUnit(utCarpenter, KMPoint(19, 17));
end;

function TKMRunnerSawmill_DeliveryOut.DoTick(aTick: Cardinal): Boolean;
var
  Store: TKMHouseStore;
begin
  Result := True;
  Store := TKMHouseStore(gHands[0].FindHouse(htStore));
  if Store <> nil then
  begin
    if Store.CheckWareIn(wtTimber) = 2 then
      Result := False;
  end;
end;

procedure TKMRunnerSawmill_DeliveryOut.Execute(aRun: Integer);
var
  Store: TKMHouseStore;
begin
  SetKaMSeed(aRun+1);
  SimulateGame;

  fResults.Value[aRun, 0] := 0;
  Store := TKMHouseStore(gHands[0].FindHouse(htStore));
  if Store <> nil then
  begin
    fResults.Value[aRun, 0] := Store.CheckWareIn(wtTimber);
  end;

  AssertTrue(fResults.Value[aRun, 0] = 2, 'Serf should have delivered 2 timbers to storehouse');

  gGameApp.StopGame(grSilent);
end;

class function TKMRunnerSawmill_DeliveryOut.TestTags: TKMTestTagSet;
begin
  Result := [tcSawmill, tcEconomy, tcDeliveryOut];
end;

class function TKMRunnerSawmill_DeliveryOut.TestDescription: string;
begin
  Result := 'Tests the servant''s ability to carry finished boards from the sawmill warehouse to the main storage area.';
end;

initialization
  RegisterTest(TKMRunnerSawmill_DeliveryOut);
end.
