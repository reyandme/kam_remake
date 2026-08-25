unit KM_Test_Sawmill_DeliveryOut;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMTest_SawmillDeliveryOut = class(TKMTest)
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
  KM_GameApp, KM_HandsCollection, KM_Terrain,
  KM_ResMapElements, KM_ResTypes;


procedure TKMTest_SawmillDeliveryOut.SetUp;
begin
  inherited;

  gGameApp.NewGameEmptyMap(32, 32);

  for var I := 9 to 21 do
    gHands[0].AddRoad(KMPoint(I, 17));

  gHands[0].AddHouse(htStore, 10, 16, False);
  gHands[0].AddHouse(htSawmill, 20, 16, False).WareAddToOut(wtTimber, 2);
  gHands[0].AddUnit(utSerf, KMPoint(20, 17));
  gHands[0].AddUnit(utCarpenter, KMPoint(19, 17));
end;


procedure TKMTest_SawmillDeliveryOut.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  if gHands[0].Houses[0].CheckWareIn(wtTimber) = 2 then
    aKeepGoing := False;

  if TimeIsOut then
    AssertFail('Serf should have delivered 2 timbers to storehouse');
end;


class function TKMTest_SawmillDeliveryOut.TestTags: TKMTestTagSet;
begin
  Result := [tcSawmill, tcEconomy, tcDeliveryOut];
end;


class function TKMTest_SawmillDeliveryOut.TestDescription: string;
begin
  Result := 'Tests the servant''s ability to carry finished boards from the sawmill warehouse to the main storage area.';
end;


initialization
  RegisterTest(TKMTest_SawmillDeliveryOut);
end.
