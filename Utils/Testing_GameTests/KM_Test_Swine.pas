unit KM_Test_Swine;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMTest_Swine = class(TKMTest)
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


procedure TKMTest_Swine.SetUp;
begin
  inherited;

  gGameApp.NewEmptyMap(32, 32);

  var H := gHands[0].AddHouse(htSwine, 16, 16, False);

  // We supply 20 corn so it's guaranteed to feed the beasts enough times to produce at least 1 pig
  H.WareAddToIn(wtCorn, 20);

  gHands[0].AddUnit(utAnimalBreeder, KMPoint(16, 17));
end;


function TKMTest_Swine.DoTick(aTick: Cardinal): Boolean;
begin
  // Keep running until at least 1 pig is produced
  Result := gHands[0].Stats.GetWaresProduced(wtPig) = 0;
end;


procedure TKMTest_Swine.Execute(aRun: Integer);
begin
  SetKaMSeed(aRun+1);
  SimulateGame;

  // Check if it produced a pig
  AssertTrue(gHands[0].Stats.GetWaresProduced(wtPig) >= 1, 'Swine farm should have processed enough corn to grow and produce a pig');

  gGameApp.StopGame(grSilent);
end;


class function TKMTest_Swine.TestTags: TKMTestTagSet;
begin
  Result := [tcSwine, tcAnimalBreeder, tcEconomy];
end;


class function TKMTest_Swine.TestDescription: string;
begin
  Result := 'Tests the swine farm''s ability to feed pigs multiple times using corn until a pig is produced.';
end;


initialization
  RegisterTest(TKMTest_Swine);
end.
