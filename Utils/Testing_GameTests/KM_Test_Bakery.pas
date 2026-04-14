unit KM_Test_Bakery;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMTest_Bakery = class(TKMTest)
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


procedure TKMTest_Bakery.SetUp;
begin
  inherited;

  gGameApp.NewEmptyMap(32, 32);

  var bakery := gHands[0].AddHouse(htBakery, 16, 16, False);
  bakery.WareAddToIn(wtFlour);

  gHands[0].AddUnit(utBaker, KMPoint(16, 17));
end;


function TKMTest_Bakery.DoTick(aTick: Cardinal): Boolean;
begin
  // Keep running until bread is produced
  Result := gHands[0].Stats.GetWaresProduced(wtBread) = 0;
end;


procedure TKMTest_Bakery.Execute(aRun: Integer);
begin
  SetKaMSeed(aRun+1);
  SimulateGame;

  // Check if it produced something
  AssertTrue(gHands[0].Stats.GetWaresProduced(wtBread) >= 1, 'Bakery should have processed flour and water into bread');

  gGameApp.StopGame(grSilent);
end;


class function TKMTest_Bakery.TestTags: TKMTestTagSet;
begin
  Result := [tcBakery, tcBaker, tcEconomy];
end;


class function TKMTest_Bakery.TestDescription: string;
begin
  Result := 'Tests the bakery''s ability to process flour and water from the internal stock into bread.';
end;


initialization
  RegisterTest(TKMTest_Bakery);
end.
