unit KM_Test_SaveLoad_RoundTrip;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;


type
  // Saves a game and loads it straight back. This is a smoke test for the round trip itself -
  // it checks that the save completes and that loading it takes effect, not that every byte of
  // the world came back (a savegame is megabytes; asserting on a handful of them proves little)
  TKMTest_SaveLoadRoundTrip = class(TKMTest)
  protected
    procedure SetUp; override;
    procedure DoTick(aTick: Cardinal; var aKeepGoing: Boolean); override;
    procedure CheckResult; override;
  public
    class function TestTags: TKMTestTagSet; override;
    class function TestDescription: string; override;
  end;


implementation
uses
  KM_GameApp;

const
  SAVE_NAME = 'game_test_save_load';


{ TKMTest_SaveLoadRoundTrip }
procedure TKMTest_SaveLoadRoundTrip.SetUp;
begin
  inherited;

  fDuration := 40;

  gGameApp.NewGameEmptyMap(32, 32);
end;


procedure TKMTest_SaveLoadRoundTrip.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  if aTick = 30 then
    gGameApp.Game.SaveAndWait(SAVE_NAME);

  // Load it back only after playing on for a while, so that the load has to visibly rewind the game
  if aTick = 40 then
    gGameApp.NewGameSingleSave(SAVE_NAME);
end;


procedure TKMTest_SaveLoadRoundTrip.CheckResult;
begin
  // The game had played on to tick 40, so being back at 30 means the save really was loaded
  AssertEquals(30, gGameApp.Game.Params.Tick, 'Loaded game should carry on from the tick it was saved at');
end;


class function TKMTest_SaveLoadRoundTrip.TestTags: TKMTestTagSet;
begin
  Result := [tcSaveLoad];
end;


class function TKMTest_SaveLoadRoundTrip.TestDescription: string;
begin
  Result := 'A game started on an empty map should save and load again.';
end;


initialization
  RegisterTest(TKMTest_SaveLoadRoundTrip);
end.
