unit KM_Test_Vineyard;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMTest_Vineyard = class(TKMTest)
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


procedure TKMTest_Vineyard.SetUp;
begin
  inherited;
  gGameApp.NewEmptyMap(32, 32);

  gHands[0].AddHouse(htVineyard, 16, 20, False);

  // Field plan at (16, 22) -> Stage 3 is ready to harvest for grapes
  // ftWine uses WINE_STAGES_COUNT = 4 (0..3)
  gHands[0].AddField(KMPoint(16, 22), ftWine, 3, False, True);

  gHands[0].AddUnit(utFarmer, KMPoint(16, 21));
end;


function TKMTest_Vineyard.DoTick(aTick: Cardinal): Boolean;
begin
  Result := True;
  var H := gHands[0].FindHouse(htVineyard);
  if H <> nil then
  begin
    if H.ResOut[1] > 0 then
      Result := False;
  end;
end;

procedure TKMTest_Vineyard.Execute(aRun: Integer);
begin
  SetKaMSeed(aRun+1);
  SimulateGame;

  var gotGrapes := 0;
  var H := gHands[0].FindHouse(htVineyard);
  if H <> nil then
    gotGrapes := H.ResOut[1];

  AssertTrue(gotGrapes > 0, 'Farmer should have harvested grapes and delivered them to the vineyard');

  gGameApp.StopGame(grSilent);
end;


class function TKMTest_Vineyard.TestTags: TKMTestTagSet;
begin
  Result := [tcVineyard, tcEconomy];
end;


class function TKMTest_Vineyard.TestDescription: string;
begin
  Result := 'Tests a farmer''s ability to collect ripe grapes and carry them back to the vineyard.';
end;


initialization
  RegisterTest(TKMTest_Vineyard);
end.
