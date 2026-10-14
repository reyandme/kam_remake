unit KM_Test_Replay_WithoutAI;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;


type
  // Plays a game in which nobody is or may become an AI, saves it and watches the replay from that save
  TKMTest_ReplayWithoutAI = class(TKMTest)
  protected
    procedure SetUp; override;
    procedure DoTick(aTick: Cardinal; var aKeepGoing: Boolean); override;
  public
    class function TestTags: TKMTestTagSet; override;
    class function TestDescription: string; override;
  end;


implementation
uses
  KM_Defaults,
  KM_GameApp, KM_HandsCollection, KM_HandTypes, KM_Saves;

const
  SAVE_NAME = 'game_test_replay_without_ai';


{ TKMTest_ReplayWithoutAI }
procedure TKMTest_ReplayWithoutAI.SetUp;
begin
  inherited;

  fDuration := 40;

  gGameApp.NewGameEmptyMap(32, 32);

  for var I := 0 to gHands.Count - 1 do
    gHands[I].HandType := hndHuman;
end;


procedure TKMTest_ReplayWithoutAI.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  if aTick = 5 then
    gGameApp.Game.SaveAndWait(SAVE_NAME);

  if aTick = 10 then
  begin
    gGameApp.NewGameSaveAndReplay(TKMSavesCollection.FullPath(SAVE_NAME, EXT_SAVE_MAIN, False),
                                  TKMSavesCollection.FullPath(SAVE_NAME, EXT_SAVE_REPLAY, False));
    AssertTrue(gGameApp.Game.Params.IsReplay, 'Setup: the save should open as a replay');
  end;

  if TimeIsOut then
    AssertTrue(gGameApp.Game.Params.Tick >= 30, 'Replay should play on to the end of the test');
end;


class function TKMTest_ReplayWithoutAI.TestTags: TKMTestTagSet;
begin
  Result := [tcSaveLoad, tcAI];
end;


class function TKMTest_ReplayWithoutAI.TestDescription: string;
begin
  Result := 'A replay of a game in which nobody can be AI should play on.';
end;


initialization
  RegisterTest(TKMTest_ReplayWithoutAI);
end.
