unit KM_Test_MP_SessionSmoke;
{$I KaM_Remake.inc}
interface
uses
  KM_Test, KM_Test_MP;


type
  // Proves the multiplayer test harness itself works: a real server, a real lobby, a real start,
  // and a game that actually ticks with two human clients in the room.
  // Every other multiplayer test builds on this, so when they all fail at once, check this one first
  TKMTest_MP_SessionSmoke = class(TKMTestMultiplayer)
  protected
    procedure SetUp; override;
    procedure DoTick(aTick: Cardinal; var aKeepGoing: Boolean); override;
  public
    class function TestTags: TKMTestTagSet; override;
    class function TestDescription: string; override;
  end;


implementation
uses
  SysUtils,
  KM_GameApp, KM_NetTypes, KM_Networking;


{ TKMTest_MP_SessionSmoke }
procedure TKMTest_MP_SessionSmoke.SetUp;
begin
  inherited;

  fDuration := 100;

  StartSession;
end;


procedure TKMTest_MP_SessionSmoke.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  if CaughtException <> '' then
    AssertFail('Nothing should have crashed while handling packets, but got ' + CaughtException);

  if Session.Host.Error <> '' then
    AssertFail('Host participant reported: ' + Session.Host.Error);

  if not TimeIsOut then Exit;

  AssertTrue(gGameApp.Game <> nil, 'The game should still be running');
  AssertTrue(gNetworking.NetGameState = lgsGame, 'Networking should still be in the running game state');
  AssertTrue(Session.Host.Playing, 'Host participant should have reached the running game');

  // The first tick is always lost: at tick 0 nobody has sent anything yet, so CommandsReceived(1)
  // is false and UpdateState only then fills the schedule. Everything after that must flow
  AssertTrue(gGameApp.Game.Params.Tick >= Cardinal(fDuration - 2),
             Format('Game should have ticked through, stopped at %d of %d',
                    [gGameApp.Game.Params.Tick, fDuration]));
end;


class function TKMTest_MP_SessionSmoke.TestTags: TKMTestTagSet;
begin
  Result := [tcMultiplayer, tcNetworking];
end;


class function TKMTest_MP_SessionSmoke.TestDescription: string;
begin
  Result := 'A real multiplayer session with two clients should start and keep ticking.';
end;


initialization
  RegisterTest(TKMTest_MP_SessionSmoke);
end.
