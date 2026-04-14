unit KM_Test_Sawmill_DeliveryOut;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMTest_SawmillDeliveryOut = class(TKMTest)
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


procedure TKMTest_SawmillDeliveryOut.SetUp;
var
  I, J: Integer;
begin
  inherited;
  fResults.ValueCount := 1;
  gGameApp.NewEmptyMap(32, 32);

  for I := 9 to 21 do
    gHands[0].AddRoad(KMPoint(I, 17));

  gHands[0].AddHouse(htStore, 10, 16, False);

  var H := gHands[0].AddHouse(htSawmill, 20, 16, False);
  H.WareAddToOut(wtTimber, 2);

  gHands[0].AddUnit(utSerf, KMPoint(20, 17));
  gHands[0].AddUnit(utCarpenter, KMPoint(19, 17));
end;


function TKMTest_SawmillDeliveryOut.DoTick(aTick: Cardinal): Boolean;
begin
  Result := True;
  var Store := gHands[0].FindHouse(htStore);
  if Store <> nil then
  begin
    if Store.CheckWareIn(wtTimber) = 2 then
      Result := False;
  end;
end;


procedure TKMTest_SawmillDeliveryOut.Execute(aRun: Integer);
begin
  SetKaMSeed(aRun+1);
  SimulateGame;

  fResults.Value[aRun, 0] := 0;
  var Store := gHands[0].FindHouse(htStore);
  if Store <> nil then
  begin
    fResults.Value[aRun, 0] := Store.CheckWareIn(wtTimber);
  end;

  AssertTrue(fResults.Value[aRun, 0] = 2, 'Serf should have delivered 2 timbers to storehouse');

  gGameApp.StopGame(grSilent);
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
