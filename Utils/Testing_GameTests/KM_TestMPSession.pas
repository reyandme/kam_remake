unit KM_TestMPSession;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, Generics.Collections,
  KM_CommonTypes, KM_Defaults, KM_MapTypes, KM_NetTypes, KM_NetServer, KM_Networking,
  KM_TestMPParticipant;


const
  // Deliberately not the stock 56789, so a test never collides with a real server on this machine
  TEST_SERVER_PORT = 56999;
  TEST_MAP_NAME = 'test_mp_2p';


type
  TKMTestCondition = reference to function: Boolean;

  ETestSessionFailed = class(Exception);

  // Drives a genuine multiplayer session inside the test process: a real TKMNetServer on the
  // loopback interface, a real lobby, a real mkStart / mkPlay handshake.
  //
  // The server is owned here rather than started through TKMNetworking.Host, because Host hides it
  // in a private field and the tests need to call MeasurePings at a chosen moment. It is the same
  // TKMNetServer either way - only the owner differs - so the session stays a real one while the
  // kick becomes deterministic instead of depending on the wall clock.
  TKMTestMPSession = class
  private
    fServer: TKMNetServer;
    fParticipants: TObjectList<TKMTestMPParticipant>;
    fHost: TKMTestMPParticipant;
    fSUTNickname: AnsiString;
    fSUTLoc: Integer;
    fSUTJoined: Boolean;
    fSUTError: UnicodeString;
    fSUTGameSeen: Boolean;
    fOnSUTGameCreated: TKMEvent;

    // The SUT's own TKMNetworking is created by TKMGameApp.NetworkInit, which binds only
    // OnStartMap / OnStartSave / OnMPGameInfoChanged / OnAnnounceReturnToLobby / OnDoReturnToLobby.
    // The lobby side events are normally supplied by the menu pages, which a headless test has not
    // got, and they are called without an "if Assigned" guard
    procedure SUTJoinSucc;
    procedure SUTJoinAssignedHost;
    procedure SUTJoinFail(const aText: UnicodeString);
    procedure SUTJoinPassword;
    procedure SUTDisconnect(const aText: UnicodeString);

    function SUTNet: TKMNetworking;
    procedure ClaimGlobalForSUT;
  public
    constructor Create;
    destructor Destroy; override;

    // Fired from Pump the moment the system under test's game object appears. The allies panel is
    // reachable from packet handling from that instant, and packets do arrive while the game is
    // still starting up, so anything that needs to watch it has to be hooked up here rather than
    // after StartGame returns
    property OnSUTGameCreated: TKMEvent read fOnSUTGameCreated write fOnSUTGameCreated;
    property Server: TKMNetServer read fServer;
    property Host: TKMTestMPParticipant read fHost;
    property Participants: TObjectList<TKMTestMPParticipant> read fParticipants;

    procedure StartServer;
    function AddHost(const aNickname: AnsiString; aLoc: Integer): TKMTestMPParticipant;
    function AddParticipant(const aNickname: AnsiString; aLoc: Integer): TKMTestMPParticipant;
    procedure AddSUT(const aNickname: AnsiString; aLoc: Integer);

    procedure Pump;
    procedure PumpUntil(const aCondition: TKMTestCondition; aTimeoutMs: Cardinal; const aWhat: string);

    procedure SelectMap(const aMapName: UnicodeString);
    procedure EveryoneReady;
    procedure StartGame;

    procedure KickSUT;

    // Roster manipulations performed by the host on its own room, then broadcast by the ordinary
    // production code path. Nothing is reached into on the system under test's side - it just
    // receives, over the real network, a player list the shipping code is able to build by itself
    procedure HostDropsSUTFromRoster;
    procedure HostClearsStartLocations;
    procedure HostBroadcastRoster;
    function SUTPlayersListCount: Cardinal;
  end;


implementation
uses
  Forms, KromUtils,
  KM_CommonUtils, KM_GameApp;


{ TKMTestMPSession }
constructor TKMTestMPSession.Create;
begin
  inherited;

  fParticipants := TObjectList<TKMTestMPParticipant>.Create(True);
end;


destructor TKMTestMPSession.Destroy;
begin
  // Participants go first: while any of them is alive the game could still be handed packets.
  // Freeing them is safe for gNetworking now that TKMNetworking.Destroy only clears the global
  // when it still points at itself
  FreeAndNil(fParticipants);
  fHost := nil;

  if fServer <> nil then
  begin
    fServer.StopListening;
    fServer.ClearClients;
    FreeAndNil(fServer);
  end;

  inherited;
end;


procedure TKMTestMPSession.StartServer;
begin
  // aPacketsAccDelay = 0 kills the internal TTimer (the constructor assigns it unchecked), so this
  // test owns every queue flush through UpdateState. Never touch PacketsAccumulatingDelay or
  // UpdateSettings afterwards - their setter clamps to a 5 ms minimum and the timer would come back.
  // An empty HTML status file name keeps SaveHTMLStatus from writing anything.
  //
  // The kick timeout stays at the production value on purpose. Anything short and the server culls
  // the system under test while it is busy building the game - the main thread is not pumping
  // messages then, so it answers no pings - and the session dies before the test has even begun.
  // Tests that want a kick ask for one explicitly through KickSUT
  fServer := TKMNetServer.Create(1 {rooms}, 20 {kick timeout, sec}, '' {no HTML status}, '' {no welcome},
                                 0 {packets accumulating delay});
  fServer.OnStatusMessage := nil;
  fServer.StartListening(TEST_SERVER_PORT, 'KaM Test Server');
end;


function TKMTestMPSession.AddHost(const aNickname: AnsiString; aLoc: Integer): TKMTestMPParticipant;
begin
  // The server hands hosting rights to whoever is first into the room, so this must be called first.
  // The system under test has to end up a joiner: HandleMessagePlayersList, where both crashes
  // live, only runs for lpkJoiner
  Result := AddParticipant(aNickname, aLoc);
  fHost := Result;
end;


function TKMTestMPSession.AddParticipant(const aNickname: AnsiString; aLoc: Integer): TKMTestMPParticipant;
var
  p: TKMTestMPParticipant;
begin
  p := TKMTestMPParticipant.Create(aNickname, aLoc);
  fParticipants.Add(p);

  // TKMNetworking.Create assigns gNetworking to itself, last writer wins.
  // The running game reads that global everywhere, so it must point back at the SUT
  ClaimGlobalForSUT;

  p.Join('127.0.0.1', TEST_SERVER_PORT);
  PumpUntil(function: Boolean begin Result := p.Joined or (p.Error <> '') end, 5000,
            'participant ' + string(aNickname) + ' to join');

  if p.Error <> '' then
    raise ETestSessionFailed.Create(string(aNickname) + ': ' + p.Error);

  Result := p;
end;


procedure TKMTestMPSession.AddSUT(const aNickname: AnsiString; aLoc: Integer);
begin
  fSUTNickname := aNickname;
  fSUTLoc := aLoc;
  fSUTJoined := False;
  fSUTError := '';

  gGameApp.NetworkInit;
  ClaimGlobalForSUT;

  SUTNet.ResetPacketsStats;

  SUTNet.OnJoinSucc := SUTJoinSucc;
  SUTNet.OnJoinAssignedHost := SUTJoinAssignedHost;
  SUTNet.OnJoinFail := SUTJoinFail;
  SUTNet.OnJoinPassword := SUTJoinPassword;
  SUTNet.OnDisconnect := SUTDisconnect; //MultiplayerRig replaces this with GameMPDisconnect on start

  SUTNet.Join('127.0.0.1', TEST_SERVER_PORT, aNickname, 0);
  PumpUntil(function: Boolean begin Result := fSUTJoined or (fSUTError <> '') end, 5000,
            'system under test to join');

  if fSUTError <> '' then
    raise ETestSessionFailed.Create('SUT: ' + fSUTError);
end;


function TKMTestMPSession.SUTNet: TKMNetworking;
begin
  Result := gGameApp.Networking;
end;


procedure TKMTestMPSession.ClaimGlobalForSUT;
begin
  if gGameApp.Networking <> nil then
    gNetworking := gGameApp.Networking;
end;


procedure TKMTestMPSession.SUTJoinSucc;
begin
  fSUTJoined := True;
end;


// Reaching this means the system under test was first into the room and got hosting rights, which
// breaks the premise: HandleMessagePlayersList, where #315 and #316 crash, only runs for lpkJoiner
procedure TKMTestMPSession.SUTJoinAssignedHost;
begin
  fSUTError := 'System under test was made host, but it has to be a joiner';
end;


procedure TKMTestMPSession.SUTJoinFail(const aText: UnicodeString);
begin
  fSUTError := 'Join failed: ' + aText;
end;


procedure TKMTestMPSession.SUTJoinPassword;
begin
  fSUTError := 'Room unexpectedly asked for a password';
end;


procedure TKMTestMPSession.SUTDisconnect(const aText: UnicodeString);
begin
  fSUTError := 'Disconnected: ' + aText;
end;


// Overbyte delivers socket data through a hidden message window and TKMNetClient.UpdateStateIdle is
// a no-op under Delphi, so without ProcessMessages nothing moves at all
procedure TKMTestMPSession.Pump;
var
  I: Integer;
begin
  Application.ProcessMessages;

  if fServer <> nil then
    fServer.UpdateState(nil);

  for I := 0 to fParticipants.Count - 1 do
    fParticipants[I].Pump;

  if gGameApp.Networking <> nil then
    gGameApp.Networking.UpdateStateIdle;

  if not fSUTGameSeen and (gGameApp.Game <> nil) then
  begin
    fSUTGameSeen := True;
    if Assigned(fOnSUTGameCreated) then
      fOnSUTGameCreated;
  end;
end;


// Every wait goes through here. Socket teardown is asynchronous - Kick closes the socket and the
// resulting mkClientLost only leaves on a later pump - so a bare "while not condition" would hang
// forever the moment a scenario misbehaves
procedure TKMTestMPSession.PumpUntil(const aCondition: TKMTestCondition; aTimeoutMs: Cardinal; const aWhat: string);
var
  started: Cardinal;
begin
  started := TimeGet;
  while not aCondition do
  begin
    if TimeSince(started) > aTimeoutMs then
      raise ETestSessionFailed.CreateFmt('Timed out after %d ms waiting for %s', [aTimeoutMs, aWhat]);

    Pump;
    Sleep(1);
  end;
end;


procedure TKMTestMPSession.SelectMap(const aMapName: UnicodeString);
begin
  if fHost = nil then
    raise ETestSessionFailed.Create('No host in the session');

  fHost.Net.SelectMap(aMapName, mkMP);

  if fHost.Net.SelectGameKind <> ngkMap then
    raise ETestSessionFailed.CreateFmt('Host could not select map "%s" - is it in MapsMP?', [aMapName]);

  // Joiners load the map themselves on mkMapSelect and answer mkHasMapOrSave. All clients share one
  // filesystem here, so no file transfer should ever start
  PumpUntil(function: Boolean
            var
              I: Integer;
            begin
              Result := SUTNet.SelectGameKind = ngkMap;
              for I := 0 to fParticipants.Count - 1 do
                if fParticipants[I] <> fHost then
                  Result := Result and (fParticipants[I].Net.SelectGameKind = ngkMap);
            end, 10000, 'everyone to accept the map');
end;


procedure TKMTestMPSession.EveryoneReady;
var
  I: Integer;
begin
  // Locations are requested from the host, so this needs pumping between attempts
  PumpUntil(function: Boolean
            var
              K: Integer;
            begin
              Result := True;
              for K := 0 to fParticipants.Count - 1 do
                if fParticipants[K] <> fHost then
                  Result := fParticipants[K].TryTakeLocAndReady and Result;
            end, 10000, 'participants to take their locations');

  // MyRoomSlot is nil until the host's player list has given us a slot index, and StartLocation is
  // a plain field with no nil guard on it
  PumpUntil(function: Boolean begin Result := SUTNet.MySlotIndex > 0 end, 10000,
            'the system under test to get a room slot');

  if SUTNet.MyRoomSlot.StartLocation <> fSUTLoc then
    SUTNet.SelectHand(SUTNet.MySlotIndex, fSUTLoc);

  PumpUntil(function: Boolean begin Result := SUTNet.MyRoomSlot.StartLocation = fSUTLoc end, 10000,
            'the system under test to get its location');

  SUTNet.ReadyToStart;

  PumpUntil(function: Boolean begin Result := fHost.Net.Room.AllReady end, 10000, 'everyone to be ready');

  for I := 0 to fParticipants.Count - 1 do
    if fParticipants[I].Error <> '' then
      raise ETestSessionFailed.Create(string(fParticipants[I].Nickname) + ': ' + fParticipants[I].Error);
end;


procedure TKMTestMPSession.StartGame;
var
  startMode: TKMGameStartMode;
begin
  startMode := fHost.Net.CanStart;
  if not (startMode in [gsmStart, gsmStartWithWarn]) then
    raise ETestSessionFailed.CreateFmt('Host refuses to start the game (CanStart = %d)', [Ord(startMode)]);

  fHost.Net.StartClick;

  // The host only sends mkPlay once every slot has answered mkReadyToPlay. Participants answer from
  // their OnStartMap stub; the SUT answers from MultiplayerRig once its real game is built
  PumpUntil(function: Boolean begin Result := SUTNet.NetGameState = lgsGame end, 30000,
            'the game to start on the system under test');

  PumpUntil(function: Boolean
            var
              I: Integer;
            begin
              Result := True;
              for I := 0 to fParticipants.Count - 1 do
                Result := Result and fParticipants[I].Playing;
            end, 30000, 'all participants to reach the running game');
end;


// A real, in protocol way to knock the SUT off the session. mkKickPlayer only closes the socket -
// unlike mkBanPlayer it does not add the address to the room ban list - so the client is free to
// come back, which is exactly the window issues #315 and #316 live in
procedure TKMTestMPSession.KickSUT;
begin
  fHost.Net.KickPlayer(fHost.Net.Room.NicknameToLocal(fSUTNickname));
end;


// What the host really does to a player it no longer considers part of the room - RemServerPlayer
// takes this same path. The slot is deleted and the ones after it shift down
procedure TKMTestMPSession.HostDropsSUTFromRoster;
var
  slotIndex: Integer;
begin
  slotIndex := fHost.Net.Room.NicknameToLocal(fSUTNickname);
  if slotIndex = -1 then
    raise ETestSessionFailed.Create('Host has no slot for the system under test to drop');

  fHost.Net.Room.RemPlayer(slotIndex);
end;


// The state ResetLocAndReady leaves behind when the host picks a map or save in the lobby:
// every non spectator start location goes back to LOC_RANDOM, which is zero
procedure TKMTestMPSession.HostClearsStartLocations;
var
  I: Integer;
begin
  for I := 1 to fHost.Net.Room.Count do
    if not fHost.Net.Room[I].IsSpectator then
      fHost.Net.Room[I].StartLocation := LOC_RANDOM;
end;


procedure TKMTestMPSession.HostBroadcastRoster;
begin
  fHost.Net.SendPlayerListAndRefreshPlayersSetup;
end;


// LogPacket bumps this counter before dispatching, so it proves the packet really arrived
// even though mkPlayersList is not one of the kinds written to the log
function TKMTestMPSession.SUTPlayersListCount: Cardinal;
begin
  Result := SUTNet.PacketsReceived[mkPlayersList];
end;


end.
