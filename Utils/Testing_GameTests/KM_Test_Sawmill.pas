unit KM_Test_Sawmill;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMTest_Sawmill = class(TKMTest)
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


procedure TKMTest_Sawmill.SetUp;
begin
  inherited;

  gGameApp.NewGameEmptyMap(32, 32);

  var H := gHands[0].AddHouse(htSawmill, 16, 16, False);
  H.WareAddToIn(wtTrunk);

  gHands[0].AddUnit(utCarpenter, KMPoint(16, 17));
end;


procedure TKMTest_Sawmill.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  if gHands[0].Stats.GetWaresProduced(wtTimber) >= 2 then
    aKeepGoing := False;

  if TimeIsOut then
    AssertFail('Sawmill should have processed trunk into 2 timber');
end;


class function TKMTest_Sawmill.TestTags: TKMTestTagSet;
begin
  Result := [tcSawmill, tcEconomy];
end;


class function TKMTest_Sawmill.TestDescription: string;
begin
  Result := 'Tests the sawmill (carpenter''s) ability to process one trunk from the internal stock into two boards.';
end;


initialization
  RegisterTest(TKMTest_Sawmill);
end.
