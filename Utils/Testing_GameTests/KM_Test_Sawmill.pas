unit KM_Test_Sawmill;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMTest_Sawmill = class(TKMTest)
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


procedure TKMTest_Sawmill.SetUp;
begin
  inherited;
  fResults.ValueCount := 1;
  gGameApp.NewEmptyMap(32, 32);

  var H := gHands[0].AddHouse(htSawmill, 16, 16, False);
  H.WareAddToIn(wtTrunk);

  gHands[0].AddUnit(utCarpenter, KMPoint(16, 17));
end;


function TKMTest_Sawmill.DoTick(aTick: Cardinal): Boolean;
begin
  // Keep running until wood is produced
  Result := gHands[0].Stats.GetWaresProduced(wtTimber) = 0;
end;


procedure TKMTest_Sawmill.Execute(aRun: Integer);
begin
  SetKaMSeed(aRun+1);
  SimulateGame;

  // Check if it produced something
  fResults.Value[aRun, 0] := gHands[0].Stats.GetWaresProduced(wtTimber);

  AssertTrue(fResults.Value[aRun, 0] >= 2, 'Sawmill should have processed trunk into 2 timber');

  gGameApp.StopGame(grSilent);
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
