unit KM_Test_MP;
{$I KaM_Remake.inc}
interface
uses
  Forms, SysUtils, //Forms for TExceptionEvent, see HandleAppException
  KM_CommonTypes, //TKMEvent
  KM_Test, KM_TestMPSession, KM_TestMPParticipant;


type
  // Base class for tests that need a genuine multiplayer session: a real server on the loopback
  // interface, a real lobby, a real mkStart / mkPlay handshake, and N clients.
  //
  // Only one of those clients - the system under test - owns an actual TKMGame, because gGame,
  // gHands and gTerrain are process globals. The others are TKMTestMPParticipant, which speak the
  // real protocol but simulate nothing
  TKMTestMultiplayer = class(TKMTest)
  protected
    fSession: TKMTestMPSession;
    fCaughtException: string;
    fPrevOnException: TExceptionEvent;
    fInnerPlayersSetup: TKMEvent;
    fInnerPingInfo: TKMEvent;

    procedure HandleAppException(Sender: TObject; E: Exception);
    procedure GuardAlliesEvents;
    procedure GuardedPlayersSetup;
    procedure GuardedPingInfo;
    procedure RecordException(E: Exception);
    procedure EnsureTestMapInstalled;
    // Brings the session all the way up to a running game, with the system under test as a joiner
    procedure StartSession(const aSUTNickname: AnsiString = 'Tester');
    procedure BeforeTick(aTick: Cardinal); override;
    procedure TearDown; override;
  public
    property Session: TKMTestMPSession read fSession;
    // Crashes inside packet handling do not reach our call stack, see HandleAppException
    property CaughtException: string read fCaughtException;
  end;


implementation
uses
  IOUtils,
  KM_Defaults, KM_Networking;


{ TKMTestMultiplayer }
// An exception raised while a packet is being handled never reaches our call stack. TKMNetworking's
// constructor calls SetHandleBackgrounException, which puts Overbyte into fehAppHandleException
// mode, so anything thrown inside the socket callback is routed to the Application exception
// handler instead. Capturing it here is both the only way to observe the crash and what stops a
// modal error dialog from hanging a batch run
procedure TKMTestMultiplayer.HandleAppException(Sender: TObject; E: Exception);
begin
  RecordException(E);
end;


procedure TKMTestMultiplayer.RecordException(E: Exception);
begin
  if fCaughtException = '' then
    fCaughtException := E.ClassName + ': ' + E.Message;
end;


// The allies panel is updated straight from the packet handler, so a crash there unwinds into
// Overbyte and is finally swallowed by madExcept, which writes a bugreport and kills the process -
// the run then ends with no result line at all.
//
// Wrapping the two events lets the test observe the crash where it happens. Nothing about the
// subject changes: the real AlliesOnPlayerSetup still runs, on a real packet, through the real path.
// MultiplayerRig assigns these during game creation, so this has to happen after the game starts
procedure TKMTestMultiplayer.GuardAlliesEvents;
begin
  fInnerPlayersSetup := gNetworking.OnPlayersSetup;
  fInnerPingInfo := gNetworking.OnPingInfo;

  gNetworking.OnPlayersSetup := GuardedPlayersSetup;
  gNetworking.OnPingInfo := GuardedPingInfo;
end;


procedure TKMTestMultiplayer.GuardedPlayersSetup;
begin
  try
    if Assigned(fInnerPlayersSetup) then
      fInnerPlayersSetup;
  except
    on E: Exception do
      RecordException(E);
  end;
end;


procedure TKMTestMultiplayer.GuardedPingInfo;
begin
  try
    if Assigned(fInnerPingInfo) then
      fInnerPingInfo;
  except
    on E: Exception do
      RecordException(E);
  end;
end;


// MapsMP is gitignored, so the fixture lives in the test project (in a sub folder - a .map placed
// directly in Utils/Testing_GameTests would be swallowed by the /Utils/*/*.map rule meant for
// Delphi linker maps) and is copied into place here. Idempotent
procedure TKMTestMultiplayer.EnsureTestMapInstalled;
var
  srcDir, dstDir, name: string;
  files: TArray<string>;
  I: Integer;
begin
  srcDir := ExeDir + 'Utils' + PathDelim + 'Testing_GameTests' + PathDelim + 'fixtures'
            + PathDelim + TEST_MAP_NAME + PathDelim;
  dstDir := ExeDir + MAPS_MP_FOLDER_NAME + PathDelim + TEST_MAP_NAME + PathDelim;

  if not DirectoryExists(srcDir) then
    raise Exception.Create('Test map fixture is missing at ' + srcDir);

  ForceDirectories(dstDir);

  files := TDirectory.GetFiles(srcDir);
  for I := 0 to High(files) do
  begin
    name := ExtractFileName(files[I]);
    if not FileExists(dstDir + name) then
      TFile.Copy(files[I], dstDir + name);
  end;
end;


procedure TKMTestMultiplayer.StartSession(const aSUTNickname: AnsiString = 'Tester');
begin
  EnsureTestMapInstalled;

  fCaughtException := '';
  fPrevOnException := Application.OnException;
  Application.OnException := HandleAppException;

  // Ticks must be driven by our loop rather than the wall clock. Already False in a Debug build
  // (CALC_EXPECTED_TICK = not DEBUG_CFG), but a Release build of the test project would flip it
  CALC_EXPECTED_TICK := False;

  fSession := TKMTestMPSession.Create;
  fSession.OnSUTGameCreated := GuardAlliesEvents;
  fSession.StartServer;

  // Order matters twice over: the server grants hosting rights to whoever enters the room first,
  // and the system under test has to be a joiner, because HandleMessagePlayersList - where both
  // #315 and #316 crash - only runs for lpkJoiner
  fSession.AddHost('Host', 2);
  fSession.AddSUT(aSUTNickname, 1);

  fSession.SelectMap(TEST_MAP_NAME);
  fSession.EveryoneReady;
  fSession.StartGame;
end;


procedure TKMTestMultiplayer.BeforeTick(aTick: Cardinal);
begin
  if fSession <> nil then
    fSession.Pump;
end;


procedure TKMTestMultiplayer.TearDown;
begin
  // TearDown runs while an exception may already be in flight - the whole point of most of these
  // tests is that one is. A second exception raised here would replace it and hide the real failure
  try
    inherited;
  except
    // swallowed on purpose
  end;

  try
    FreeAndNil(fSession);
  except
    // swallowed on purpose
  end;

  Application.OnException := fPrevOnException;
end;


end.
