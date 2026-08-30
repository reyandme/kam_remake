unit KM_Test_MP_RosterWithoutUs;
{$I KaM_Remake.inc}
interface
uses
  KM_Test, KM_Test_MP;


type
  // Regression test for issue #315 (EAccessViolation in TKMGamePlayInterface.AlliesOnPlayerSetup).
  //
  // The host drops our slot from its room and broadcasts the player list, exactly as it does when a
  // client is lost while the host is in lobby state. We are still a member of the server's room, so
  // the packet reaches us while our game is very much alive. HandleMessagePlayersList then recomputes
  // fMySlotIndex from our nickname, finds nothing, and leaves it at -1. MyRoomSlot returns nil for an
  // out of range index, and AlliesOnPlayerSetup dereferences it.
  //
  // Red until that is fixed. The assertion is the absence of a crash, so it would also catch a "fix"
  // that simply drops the packet: PumpUntil below insists the player list really did arrive
  TKMTest_MP_RosterWithoutUs = class(TKMTestMultiplayer)
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
  KM_GameApp, KM_Networking, KM_TestMPSession;

const
  INJECT_AT_TICK = 20;


{ TKMTest_MP_RosterWithoutUs }
procedure TKMTest_MP_RosterWithoutUs.SetUp;
begin
  inherited;

  fDuration := 40;

  StartSession;
end;


procedure TKMTest_MP_RosterWithoutUs.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  if aTick <> INJECT_AT_TICK then Exit;

  var listCountBefore := Session.SUTPlayersListCount;

  Session.HostDropsSUTFromRoster;
  Session.HostBroadcastRoster;

  Session.PumpUntil(function: Boolean
                    begin
                      Result := Session.SUTPlayersListCount > listCountBefore;
                    end, 5000, 'the player list to reach the system under test');

  // Stop here on purpose. Once MySlotIndex is -1 the game input process would index its schedule
  // with it every tick, and those follow up failures would bury the one we came to look for
  aKeepGoing := False;

  AssertEquals(-1, gNetworking.MySlotIndex, 'Our nickname should be gone from the room');
  AssertTrue(gGameApp.Game <> nil, 'Handling the player list should not have torn the game down');
  AssertTrue(CaughtException = '',
             'Handling a player list without our own nickname crashed with ' + CaughtException);
end;


class function TKMTest_MP_RosterWithoutUs.TestTags: TKMTestTagSet;
begin
  Result := [tcMultiplayer, tcNetworking];
end;


class function TKMTest_MP_RosterWithoutUs.TestDescription: string;
begin
  Result := 'A player list that no longer contains us should not crash the allies panel (issue 315).';
end;


initialization
  RegisterTest(TKMTest_MP_RosterWithoutUs);
end.
