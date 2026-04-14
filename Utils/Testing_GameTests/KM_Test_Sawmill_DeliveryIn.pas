unit KM_Test_Sawmill_DeliveryIn;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMTest_SawmillDeliveryIn = class(TKMTest)
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
  KM_GameApp, KM_HandsCollection, KM_Terrain, KM_HouseStore,
  KM_ResMapElements, KM_ResTypes;


{ TKMTest_SawmillDeliveryIn }
procedure TKMTest_SawmillDeliveryIn.SetUp;
var
  I, J: Integer;
begin
  inherited;

  gGameApp.NewEmptyMap(32, 32);

  for I := 9 to 21 do
    gHands[0].AddRoad(KMPoint(I, 17));

  var Store := TKMHouseStore(gHands[0].AddHouse(htStore, 10, 16, False));
  Store.WareAddToIn(wtTrunk, 1, True); // FromScript = True

  gHands[0].AddHouse(htSawmill, 20, 16, False);

  // Serf to deliver the trunk
  gHands[0].AddUnit(utSerf, KMPoint(10, 17));
end;

function TKMTest_SawmillDeliveryIn.DoTick(aTick: Cardinal): Boolean;
begin
  Result := True;
  var H := gHands[0].FindHouse(htSawmill);
  if H <> nil then
  begin
    if H.ResIn[1] > 0 then
      Result := False;
  end;
end;


procedure TKMTest_SawmillDeliveryIn.Execute(aRun: Integer);
begin
  SetKaMSeed(aRun+1);
  SimulateGame;

  var trunkInSawmill := 0;
  var H := gHands[0].FindHouse(htSawmill);
  if H <> nil then
    trunkInSawmill := H.ResIn[1];

  AssertTrue(trunkInSawmill > 0, 'Serf should have delivered trunk to sawmill');

  gGameApp.StopGame(grSilent);
end;


class function TKMTest_SawmillDeliveryIn.TestTags: TKMTestTagSet;
begin
  Result := [tcSawmill, tcEconomy, tcDeliveryIn];
end;


class function TKMTest_SawmillDeliveryIn.TestDescription: string;
begin
  Result := 'Tests a servant''s ability to carry a log from the warehouse to the sawmill.';
end;


initialization
  RegisterTest(TKMTest_SawmillDeliveryIn);
end.
