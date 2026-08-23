unit KM_Test_Vineyard;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMTest_Vineyard = class(TKMTest)
  protected
    procedure DoTick(aTick: Cardinal; var aKeepGoing: Boolean); override;
    procedure SetUp; override;
    procedure CheckResult; override;
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
  gGameApp.NewGameEmptyMap(32, 32);

  gHands[0].AddHouse(htVineyard, 16, 20, False);

  // Field plan at (16, 22) -> Stage 3 is ready to harvest for grapes
  // ftWine uses WINE_STAGES_COUNT = 4 (0..3)
  gHands[0].AddField(KMPoint(16, 22), ftWine, 3, False, True);

  gHands[0].AddUnit(utFarmer, KMPoint(16, 21));
end;


procedure TKMTest_Vineyard.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  var H := gHands[0].Houses[0];
  if H.ResOut[1] > 0 then
    aKeepGoing := False;
end;

procedure TKMTest_Vineyard.CheckResult;
begin
  var H := gHands[0].Houses[0];
  var gotGrapes := H.ResOut[1];

  AssertTrue(gotGrapes > 0, 'Farmer should have harvested grapes and delivered them to the vineyard');
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
