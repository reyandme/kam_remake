unit KM_Test_Mill;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMTest_Mill = class(TKMTest)
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


procedure TKMTest_Mill.SetUp;
begin
  inherited;
  fResults.ValueCount := 1;
  gGameApp.NewEmptyMap(32, 32);

  var H := gHands[0].AddHouse(htMill, 16, 16, False);
  H.WareAddToIn(wtCorn);

  gHands[0].AddUnit(utBaker, KMPoint(16, 17));
end;


function TKMTest_Mill.DoTick(aTick: Cardinal): Boolean;
begin
  // Keep running until flour is produced
  Result := gHands[0].Stats.GetWaresProduced(wtFlour) = 0;
end;


procedure TKMTest_Mill.Execute(aRun: Integer);
begin
  SetKaMSeed(aRun+1);
  SimulateGame;

  // Check if it produced something
  fResults.Value[aRun, 0] := gHands[0].Stats.GetWaresProduced(wtFlour);

  AssertTrue(fResults.Value[aRun, 0] >= 1, 'Mill should have processed corn into flour');

  gGameApp.StopGame(grSilent);
end;


class function TKMTest_Mill.TestTags: TKMTestTagSet;
begin
  Result := [tcMill, tcEconomy];
end;


class function TKMTest_Mill.TestDescription: string;
begin
  Result := 'Tests the mill''s ability to process one corn from the internal stock into flour.';
end;


initialization
  RegisterTest(TKMTest_Mill);
end.
