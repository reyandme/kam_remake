unit KM_Test_MP_RosterZeroLoc;
{$I KaM_Remake.inc}
interface
uses
  KM_Test, KM_Test_MP;


type
  // Regression test for issue #316 (ERangeError in TKMGamePlayInterface.UpdateRoomMapping).
  //
  // The host puts every non spectator start location back to LOC_RANDOM, which is what
  // ResetLocAndReady does whenever a map or save is picked in the lobby, and broadcasts the list.
  // A client that is still in the game accepts it - mkPlayersList is allowed in lgsGame, unlike
  // mkResetMap - and UpdateRoomMapping then writes handIdToRoomId[HandIndex] with HandIndex = -1,
  // because IsSpectator only excludes LOC_SPECTATE (-1), not location zero.
  //
  // Unlike issue #315 our own slot survives here, so the crash lands further in, in
  // UpdateRoomMapping rather than on the MyRoomSlot dereference above it.
  //
  // Detecting it needs range checking on, which Testing_GameTests.dproj enables for Win32 Debug
  TKMTest_MP_RosterZeroLoc = class(TKMTestMultiplayer)
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

{$IFOPT R-}
  {$MESSAGE WARN 'Range checks are off, this test cannot detect issue #316'}
{$ENDIF}


{ TKMTest_MP_RosterZeroLoc }
procedure TKMTest_MP_RosterZeroLoc.SetUp;
begin
  inherited;

  fDuration := 40;

  StartSession;
end;


procedure TKMTest_MP_RosterZeroLoc.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  if aTick <> INJECT_AT_TICK then Exit;

{$IFOPT R-}
  AssertFail('Range checks are disabled, so this test cannot detect issue #316');
{$ENDIF}

  var listCountBefore := Session.SUTPlayersListCount;

  Session.HostClearsStartLocations;
  Session.HostBroadcastRoster;

  Session.PumpUntil(function: Boolean
                    begin
                      Result := Session.SUTPlayersListCount > listCountBefore;
                    end, 5000, 'the player list to reach the system under test');

  // Every slot now claims location zero, so letting the game carry on would only pile up
  // consequences of the state we just injected
  aKeepGoing := False;

  // Our own slot is still there, which is what separates this from issue #315
  AssertTrue(gNetworking.MySlotIndex > 0,
             Format('We should still be in the room, but MySlotIndex is %d', [gNetworking.MySlotIndex]));
  AssertEquals(0, gNetworking.MyRoomSlot.StartLocation,
               'The injected player list should have left us without a start location');
  AssertTrue(gGameApp.Game <> nil, 'Handling the player list should not have torn the game down');
  AssertTrue(CaughtException = '',
             'Handling a player list with unset start locations crashed with ' + CaughtException);
end;


class function TKMTest_MP_RosterZeroLoc.TestTags: TKMTestTagSet;
begin
  Result := [tcMultiplayer, tcNetworking];
end;


class function TKMTest_MP_RosterZeroLoc.TestDescription: string;
begin
  Result := 'A player list with unset start locations should not crash the allies panel (issue 316).';
end;


initialization
  RegisterTest(TKMTest_MP_RosterZeroLoc);
end.
