unit KM_Test_Stone;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMTest_Stone = class(TKMTest)
  protected
    function DoTick(aTick: Cardinal): Boolean; override;
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
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

  gGameApp.NewEmptyMap(32, 32);

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


function TKMTest_Stone.DoTick(aTick: Cardinal): Boolean;
begin
  // Continue simulation (True) until stone is produced
  Result := gHands[0].Stats.GetWaresProduced(wtStone) = 0;
end;


procedure TKMTest_Stone.Execute(aRun: Integer);
begin
  SetKaMSeed(aRun+1);
  
  // Run the simulation loop
  SimulateGame;

  // The stonemason should have found the stone, mined it, and delivered it.
  AssertTrue(gHands[0].Stats.GetWaresProduced(wtStone) > 0, 'Stonemason should have mined some stone');

  gGameApp.StopGame(grSilent);
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
