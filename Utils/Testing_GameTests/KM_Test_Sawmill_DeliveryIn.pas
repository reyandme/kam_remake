unit KM_Test_Sawmill_DeliveryIn;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMTest_SawmillDeliveryIn = class(TKMTest)
  protected
    procedure DoTick(aTick: Cardinal; var aKeepGoing: Boolean); override;
    procedure SetUp; override;
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
begin
  inherited;

  gGameApp.NewGameEmptyMap(32, 32);

  for var I := 9 to 21 do
    gHands[0].AddRoad(KMPoint(I, 17));

  TKMHouseStore(gHands[0].AddHouse(htStore, 10, 16, False)).WareAddToIn(wtTrunk, 1, True);

  gHands[0].AddHouse(htSawmill, 20, 16, False);

  // Serf to deliver the trunk
  gHands[0].AddUnit(utSerf, KMPoint(10, 17));
end;


procedure TKMTest_SawmillDeliveryIn.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  var trunksInSawmill := gHands[0].Houses[1].ResIn[1];
  if trunksInSawmill > 0 then
    aKeepGoing := False;

  if TimeIsOut then
    AssertFail('Serf should have delivered trunk to sawmill');
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
