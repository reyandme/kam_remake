unit KM_TestMPParticipant;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, Math,
  KM_CommonClasses, KM_CommonTypes, KM_Defaults, KM_Points,
  KM_MapTypes, KM_NetTypes, KM_Networking;


const
  // How far ahead of the game tick we keep the command packs topped up.
  // Mirrors MAX_DELAY in KM_GameInputProcess_Multi, which is the most the real client ever plans ahead
  LEAD_TICKS_DEFAULT = 32;


type
  // A real network client that plays a real part in a real session, but has no game simulation of
  // its own. Only one TKMGame can exist per process (gGame, gHands, gTerrain are globals), so every
  // client except the system under test has to be one of these.
  //
  // It joins, takes a location, gets ready, acknowledges the start, and then feeds the session an
  // empty command pack every tick. That last part is not optional: the real client cannot advance
  // a tick until TKMGameInputProcess_Multi.CommandsReceived has heard from every human slot
  // in the room, so a silent participant stalls the game forever.
  TKMTestMPParticipant = class
  private
    fNet: TKMNetworking;
    fNickname: AnsiString;
    fDesiredLoc: Integer;

    fJoined: Boolean;
    fMapReady: Boolean;
    fReadySent: Boolean;
    fPlaying: Boolean;
    fError: UnicodeString;

    fLeadTicks: Integer;
    fStallTicks: Integer;
    fNextTickToSend: Cardinal;

    // Networking calls these without an "if Assigned" guard, so they must all be provided
    procedure NetJoinSucc;
    procedure NetJoinAssignedHost;
    procedure NetJoinFail(const aText: UnicodeString);
    procedure NetJoinPassword;
    procedure NetDisconnect(const aText: UnicodeString);
    procedure NetStartMap(const aData: UnicodeString; aMapKind: TKMMapKind; aCRC: Cardinal;
                          Spectating: Boolean; aMissionDifficulty: TKMMissionDifficulty);
    procedure NetStartSave(const aData: UnicodeString; Spectating: Boolean);
    procedure NetPlay;
    procedure NetMPGameInfoChanged;

    procedure SendEmptyCommands(aTick: Cardinal);
  public
    constructor Create(const aNickname: AnsiString; aDesiredLoc: Integer);
    destructor Destroy; override;

    property Net: TKMNetworking read fNet;
    property Nickname: AnsiString read fNickname;
    property Joined: Boolean read fJoined;
    property MapReady: Boolean read fMapReady;
    property Playing: Boolean read fPlaying;
    property Error: UnicodeString read fError;
    function IsHost: Boolean;

    procedure Join(const aAddress: string; aPort: Word);
    function TryTakeLocAndReady: Boolean;
    procedure Pump;

    // Scriptable behaviour
    procedure SetLeadTicks(aTicks: Integer);
    procedure StallFor(aTicks: Integer);
  end;


implementation
uses
  KM_GameParams;


{ TKMTestMPParticipant }
constructor TKMTestMPParticipant.Create(const aNickname: AnsiString; aDesiredLoc: Integer);
begin
  inherited Create;

  fNickname := aNickname;
  fDesiredLoc := aDesiredLoc;
  fLeadTicks := LEAD_TICKS_DEFAULT;

  // Deliberately no master server address and no UDP announce - a test must not talk to the outside
  fNet := TKMNetworking.Create('', 1 {kick timeout, sec}, 1000 {ping interval}, 0 {announce interval},
                               0 {UDP scan port}, 0 {packets accumulating delay},
                               False {dynamic FOW}, False {maps filter}, '',
                               KMRange(0, 300), KMRange(0.0, 10.0), KMRange(0.0, 10.0));

  // Every one of these is called by TKMNetworking without an "if Assigned" check
  fNet.OnJoinSucc := NetJoinSucc;
  // The first client into the room is made host by the server, and that path reports through
  // OnJoinAssignedHost instead of OnJoinSucc - mkAllowToJoin only ever comes from an existing host
  fNet.OnJoinAssignedHost := NetJoinAssignedHost;
  fNet.OnJoinFail := NetJoinFail;
  fNet.OnJoinPassword := NetJoinPassword;
  fNet.OnDisconnect := NetDisconnect;
  fNet.OnStartMap := NetStartMap;
  fNet.OnStartSave := NetStartSave;
  fNet.OnMPGameInfoChanged := NetMPGameInfoChanged;
  fNet.OnPlay := NetPlay;

  // Left deliberately nil:
  //   OnTextMessage - PostLocalMessage would then reach gSoundPlayer, which is not nil safe
  //   OnCommands    - incoming commands are of no use to a client with no simulation
end;


destructor TKMTestMPParticipant.Destroy;
begin
  // Note: TKMNetworking.Destroy clears gNetworking only when it still points at itself,
  // so freeing a participant no longer blanks the pointer the real game depends on
  FreeAndNil(fNet);

  inherited;
end;


function TKMTestMPParticipant.IsHost: Boolean;
begin
  Result := (fNet <> nil) and fNet.IsHost;
end;


procedure TKMTestMPParticipant.Join(const aAddress: string; aPort: Word);
begin
  fNet.Join(aAddress, aPort, fNickname, 0);
end;


procedure TKMTestMPParticipant.NetJoinSucc;
begin
  fJoined := True;
end;


procedure TKMTestMPParticipant.NetJoinAssignedHost;
begin
  fJoined := True;
end;


procedure TKMTestMPParticipant.NetJoinFail(const aText: UnicodeString);
begin
  fError := 'Join failed: ' + aText;
end;


procedure TKMTestMPParticipant.NetJoinPassword;
begin
  fError := 'Room unexpectedly asked for a password';
end;


procedure TKMTestMPParticipant.NetDisconnect(const aText: UnicodeString);
begin
  fError := 'Disconnected: ' + aText;
  fPlaying := False;
end;


// The real client would build a TKMGame here. We must not - there can only be one per process -
// but we still have to report readiness, otherwise the host's TryPlayGame never sees
// AllReadyToPlay, never sends mkPlay, and the whole session hangs in lgsLoading
procedure TKMTestMPParticipant.NetStartMap(const aData: UnicodeString; aMapKind: TKMMapKind; aCRC: Cardinal;
                                           Spectating: Boolean; aMissionDifficulty: TKMMissionDifficulty);
begin
  fNet.GameCreated;
end;


procedure TKMTestMPParticipant.NetStartSave(const aData: UnicodeString; Spectating: Boolean);
begin
  fNet.GameCreated;
end;


procedure TKMTestMPParticipant.NetPlay;
begin
  fPlaying := True;
  fNextTickToSend := 1;
end;


procedure TKMTestMPParticipant.NetMPGameInfoChanged;
begin
  // Only reachable if this participant is promoted to host mid-session
end;


// Takes the requested location and announces readiness. The map has to have arrived first:
// ReadyToStart refuses while SelectGameKind is still ngkNone
function TKMTestMPParticipant.TryTakeLocAndReady: Boolean;
begin
  Result := False;
  if fReadySent then Exit(True);
  if fNet.MySlotIndex <= 0 then Exit;
  if fNet.SelectGameKind = ngkNone then Exit;

  if fNet.MyRoomSlot.StartLocation <> fDesiredLoc then
    fNet.SelectHand(fNet.MySlotIndex, fDesiredLoc);

  if fNet.MyRoomSlot.StartLocation <> fDesiredLoc then Exit; //Host has not granted it yet

  fReadySent := fNet.ReadyToStart;
  Result := fReadySent;
end;


// Wire format matches TKMGameInputProcess_Multi.SendCommands: the data type, the target tick and
// then TKMCommandsPack.Save, which for an empty pack is just its Word count of zero.
// SendCommands prepends mkCommands itself
procedure TKMTestMPParticipant.SendEmptyCommands(aTick: Cardinal);
var
  M: TKMemoryStream;
begin
  M := TKMemoryStreamBinary.Create;
  try
    M.Write(Byte(0));   //TKMDataType.kdpCommands
    M.Write(aTick);
    M.Write(Word(0));   //TKMCommandsPack.fCount
    fNet.SendCommands(M);
  finally
    M.Free;
  end;
end;


procedure TKMTestMPParticipant.Pump;
var
  tick, lastWanted: Cardinal;
begin
  if fNet = nil then Exit;

  fNet.UpdateStateIdle;

  if not fPlaying or not fNet.Connected then Exit;
  if fNet.NetGameState <> lgsGame then Exit;

  if fStallTicks > 0 then
  begin
    Dec(fStallTicks);
    Exit;
  end;

  // We share the process with the system under test, so we can read its tick directly
  // instead of free running and risking either falling behind or lapping the ring buffer
  if gGameParams = nil then Exit;

  tick := gGameParams.Tick;
  lastWanted := tick + Cardinal(fLeadTicks);

  if fNextTickToSend <= tick then
    fNextTickToSend := tick + 1; //We fell behind, anything older is discarded by the receiver anyway

  while fNextTickToSend <= lastWanted do
  begin
    SendEmptyCommands(fNextTickToSend);
    Inc(fNextTickToSend);
  end;
end;


procedure TKMTestMPParticipant.SetLeadTicks(aTicks: Integer);
begin
  // Below MIN_DELAY the real client would be waiting on us every tick, above MAX_SCHEDULE
  // we would lap the ring buffer and overwrite packs it has not consumed yet
  fLeadTicks := EnsureRange(aTicks, 2, 90);
end;


procedure TKMTestMPParticipant.StallFor(aTicks: Integer);
begin
  fStallTicks := Max(0, aTicks);
end;


end.
