unit KM_Test_Stone;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMTest_Stone = class(TKMTest)
  protected
    procedure DoTick(aTick: Cardinal; var aKeepGoing: Boolean); override;
    procedure SetUp; override;
    procedure TearDown; override;
  public
    class function TestTags: TKMTestTagSet; override;
    class function TestDescription: string; override;
  end;

implementation
uses
  KM_Defaults, KM_Points, KM_CommonUtils,
  KM_GameApp, KM_HandsCollection, KM_Terrain,
  KM_ResMapElements, KM_ResTypes;


{ TKMTest_Stone }
procedure TKMTest_Stone.SetUp;
begin
  inherited;

  DYNAMIC_TERRAIN := False;

  gGameApp.NewGameEmptyMap(32, 32);

  // Set a stone deposit for mining
  // 132 is a base tile ID for Stone (tkStone)
  gTerrain.ScriptTrySetTile(16, 15, 132, 0);

  // Set the quarry house
  gHands[0].AddHouse(htQuarry, 16, 20, False);
  
  // Add the stonemason unit just outside the house
  gHands[0].AddUnit(utStonemason, KMPoint(16, 21));
end;


procedure TKMTest_Stone.TearDown;
begin
  inherited;
  DYNAMIC_TERRAIN := True;
end;


procedure TKMTest_Stone.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  if gHands[0].Stats.GetWaresProduced(wtStone) > 0 then
    aKeepGoing := False;

  if TimeIsOut then
    AssertFail('Stonemason should have mined some stone');
end;


class function TKMTest_Stone.TestTags: TKMTestTagSet;
begin
  Result := [tcQuarry, tcStonemason];
end;


class function TKMTest_Stone.TestDescription: string;
begin
  Result := 'Tests a stonemason''s ability to find stone, mine it, and deliver it to the quarry.';
end;


initialization
  RegisterTest(TKMTest_Stone);
end.
