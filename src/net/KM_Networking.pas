unit KM_Networking;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF Unix} LCLIntf, {$ENDIF}
  Classes, SysUtils, TypInfo, Generics.Collections,
  KromUtils,
  KM_Console,
  KM_CommonClasses, KM_CommonTypes, KM_NetworkClasses, KM_NetworkTypes, KM_Defaults, KM_Points,
  KM_Saves, KM_GameOptions, KM_ResLocales, KM_NetFileTransfer, KM_Maps, KM_MapTypes, KM_NetPlayersList,
  KM_DedicatedServer, KM_NetClient, KM_ServerQuery,
  {$IFDEF USESECUREAUTH}
    // If you don't have this file - disable USESECUREAUTH in KaM_Remake.inc
    KM_NetAuthSecure
  {$ELSE}
    KM_NetAuthUnsecure
  {$ENDIF}
  ;

type
  TKMMapStartEvent = procedure (const aData: UnicodeString; aMapKind: TKMMapKind; aCRC: Cardinal; Spectating: Boolean;
                                aMissionDifficulty: TKMMissionDifficulty) of object;

  // Should handle message exchange and routing, interacting with UI
  TKMNetworking = class
  private
    fPacketsReceived: array[TKMessageKind] of Cardinal;
    fPacketsSent: array[TKMessageKind] of Cardinal;
    fPacketsStatsStartTime: Cardinal;

    fNetServer: TKMDedicatedServer;
    fNetClient: TKMNetClient;
    fServerQuery: TKMServerQuery;
    fNetPlayerKind: TKMNetPlayerKind; // Our role (Host or Joiner)
    fNetGameState: TKMNetGameState;
    fServerAddress: string; // Used for reconnecting
    fServerPort: Word; // Used for reconnecting
    fRoomToJoin: Integer; // The room we should join once we hear from the server
    fLastProcessedTick: Cardinal;
    fReconnectRequested: Cardinal; // TickCount at which a reconnection was requested
    fMyNickname: AnsiString;
    fWelcomeMessage: UnicodeString;
    fServerName: AnsiString; // Name of the server we are currently in (shown in the lobby)
    fPassword: AnsiString;
    fDescription: UnicodeString;
    fEnteringPassword: Boolean;
    fMyIndexOnServer: TKMNetHandleIndex;
    fMyIndex: Integer; // In NetPlayers list
    fHostIndex: Integer; //In NetPlayers list
    fIgnorePings: Integer; // During loading ping measurements will be high, so discard them. (when networking is threaded this might be unnecessary)
    fJoinTimeout, fLastVoteTime: Cardinal;
    fReturnedToLobby: Boolean; //Did we get to the lobby by return to lobby feature?
    fNetPlayers: TKMNetPlayersList;
    fMutedPlayersList: TList<Integer>; // List of ServerIndexes of muted players.
    fMyPlayerCurrentFPS: Cardinal;

    fMapInfo: TKMMapInfo; // Everything related to selected map
    fSaveInfo: TKMSaveInfo;
    fSelectGameKind: TKMNetGameKind;
    fNetGameOptions: TKMGameOptions;
    fNetGameFilter: TKMPGameFilter;

    fFileReceiver: TKMFileReceiver;
    fFileSenderManager: TKMFileSenderManager;
    fMissingFileType: TKMNetGameKind;
    fMissingFileName: UnicodeString;
    fMissingFileCRC: Cardinal;

    fVoteReturnToLobbySucceeded: Boolean;

    procedure DecodePingInfo(aStream: TKMemoryStream);
    procedure ForcedDisconnect(Sender: TObject);
    procedure StartGame;
    procedure TryPlayGame;
    procedure PlayGame;
    procedure SetGameState(aState: TKMNetGameState; aOnMPInfoChanged: Boolean = True);
    procedure SendMapOrSave(Recipient: TKMNetHandleIndex = NET_ADDRESS_OTHERS);
    procedure DoReconnection;
    function IsPlayerHandStillInGame(aPlayerIndex: Integer): Boolean;
    procedure ReassignHost(aSenderIndex: TKMNetHandleIndex; M: TKMemoryStream);
    procedure PlayerJoined(aServerIndex: TKMNetHandleIndex; const aPlayerName: AnsiString);
    procedure PlayerDisconnected(aSenderIndex: TKMNetHandleIndex; aLastSentCommandsTick: Integer);
    procedure PlayersListReceived(aM: TKMemoryStream);
    procedure ReturnToLobbyVoteSucceeded;
    procedure ResetReturnToLobbyVote;
    procedure TransferOnCompleted(aClientIndex: TKMNetHandleIndex);
    procedure TransferOnPacket(aClientIndex: TKMNetHandleIndex; aStream: TKMemoryStream; out SendBufferEmpty: Boolean);
    function GetMyNetPlayer: TKMNetPlayerInfo;
    procedure SetDownloadlInProgress(aSenderIndex: TKMNetHandleIndex; aValue: Boolean);
    procedure FileRequestReceived(aSenderIndex: TKMNetHandleIndex; aM: TKMemoryStream);

    procedure ConnectSucceed(Sender:TObject);
    procedure ConnectFailed(const aText: string);
    function GetNetAddressPrintDescr(aNetworkAddress: Integer): String;
    procedure LogPacket(aIsSending: Boolean; aKind: TKMessageKind; aNetworkAddress: TKMNetHandleIndex);
    procedure PostLogMessageToChat(const aLogMessage: UnicodeString);
    procedure PacketRecieve(aNetClient: TKMNetClient; aSenderIndex: TKMNetHandleIndex; aData: Pointer; aLength: Cardinal); //Process all commands
    procedure PacketSend(aRecipient: TKMNetHandleIndex; aKind: TKMessageKind); overload;
    procedure PacketSend(aRecipient: TKMNetHandleIndex; aKind: TKMessageKind; aStream: TKMemoryStream); overload;
    procedure PacketSend(aRecipient: TKMNetHandleIndex; aKind: TKMessageKind; aParam: Integer); overload;
    procedure PacketSend(aRecipient: TKMNetHandleIndex; aKind: TKMessageKind; aParam: Cardinal); overload;
//    procedure PacketSend(aRecipient: TKMNetHandleIndex; aKind: TKMessageKind; const aParams: array of Integer);
    procedure PacketSendInd(aRecipient: TKMNetHandleIndex; aKind: TKMessageKind; aIndexOnServer: TKMNetHandleIndex);
    procedure PacketSendA(aRecipient: TKMNetHandleIndex; aKind: TKMessageKind; const aText: AnsiString);
    procedure PacketSendW(aRecipient: TKMNetHandleIndex; aKind: TKMessageKind; const aText: UnicodeString);
    procedure SetDescription(const Value: UnicodeString);

    function GetPacketsReceived(aKind: TKMessageKind): Cardinal;
    function GetPacketsSent(aKind: TKMessageKind): Cardinal;

    procedure WriteInfoToJoinRoom(aM: TKMemoryStream);
    function GetMapInfo: TKMMapInfo;
  public
    OnJoinSucc: TEvent;               // We were allowed to join
    OnJoinFail: TUnicodeStringEvent;  // We were refused to join
    OnJoinPassword: TEvent;           // Lobby requires password
    OnHostFail: TUnicodeStringEvent;  // Server failed to start (already running a server?)
    OnJoinAssignedHost: TEvent;       // We were assigned hosting rights upon connection
    OnReassignedHost: TEvent;         // We were reassigned hosting rights when the host quit
    OnReassignedJoiner: TEvent;       // We were reassigned to a joiner from host
    OnFileTransferProgress: TTransferProgressEvent;             // File transfer progress to this player
    OnPlayerFileTransferProgress: TTransferProgressPlayerEvent; // File transfer progress to other player

    OnPlayersSetup: TEvent;               // Player list updated
    OnUpdateMinimap: TEvent;              // Update minimap
    OnGameOptions: TEvent;                // Game options updated
    OnMapName: TUnicodeStringEvent;       // Map name updated
    OnMapMissing: TUnicodeStringBoolEvent;// Map missing
    OnStartMap: TKMMapStartEvent;           // Start the game
    OnStartSave: TGameStartEvent;         // Load the game
    OnDoReturnToLobby: TEvent;
    OnAnnounceReturnToLobby: TEvent;      // Sends GIC command to create synchronised save file
    OnPlay: TEvent;                       // Start the gameplay
    OnReadyToPlay: TEvent;                // Update the list of players ready to play
    OnPingInfo: TEvent;                   // Ping info updated
    OnMPGameInfoChanged: TEvent;
    OnSetPassword: TAnsiStringEvent;
    OnAbortAllTransfers: TEvent;

    OnDisconnect: TUnicodeStringEvent;    // Lost connection or was kicked
    OnJoinerDropped: TIntegerEvent;       // Other player disconnected
    OnCommands: TStreamIntEvent;          // Recieved GIP commands
    OnResyncFromTick: TResyncEvent;

    OnTextMessage: TUnicodeStringEvent;   // Text message recieved

    constructor Create(const aMasterServerAddress: string; aKickTimeout, aPingInterval, aAnnounceInterval, aServerUDPScanPort: Word;
                       const aPacketsAccDelay: Integer;
                       aDynamicFOW, aMapsFilterEnabled: Boolean; const aMapsCRCListStr: UnicodeString; const aPeacetimeRng: TKMRangeInt;
                       const aSpeedRng: TKMRangeSingle; const aSpeedRngAfterPT: TKMRangeSingle);
    destructor Destroy; override;

    property MyIndex: Integer read fMyIndex;
    property MyIndexOnServer: TKMNetHandleIndex read fMyIndexOnServer;
    property HostIndex: Integer read fHostIndex;
    property NetGameState: TKMNetGameState read fNetGameState;
    property NetGameFilter: TKMPGameFilter read fNetGameFilter;
    function MyIPString: string;
    property ServerName: AnsiString read fServerName;
    property ServerAddress: string read fServerAddress;
    property ServerPort: Word read fServerPort;
    property ServerRoom: Integer read fRoomToJoin;
    function IsHost: Boolean;
    function IsReconnecting: Boolean;
    function CalculateGameCRC: Cardinal;

    function IsMuted(aNetPlayerIndex: Integer): Boolean;
    procedure ToggleMuted(aNetPlayerIndex: Integer);

    function IsSave: Boolean;
    function IsMap: Boolean;

    //Lobby
    property ServerQuery: TKMServerQuery read fServerQuery;
    procedure Host(const aServerName: AnsiString; aPort: Word; const aNickname: AnsiString; aAnnounceServer, aAnnounceUDP: Boolean);
    procedure Join(const aServerAddress: string; aPort: Word; const aNickname: AnsiString; aRoom: Integer; aIsReconnection: Boolean = False);
    procedure AnnounceDisconnect(aLastSentCmdsTick: Cardinal = LAST_SENT_COMMANDS_TICK_NONE);
    procedure Disconnect;
    procedure DropPlayers(aPlayers: TKMByteArray);
    function  Connected: Boolean;
    procedure MatchPlayersToSave(aPlayerID: Integer = -1);
    procedure AbortAllTransfers;
    procedure SelectNoMap(const aErrorMessage: UnicodeString);
    procedure SelectMap(const aName: UnicodeString; aMapKind: TKMMapKind; aSendPlayerSetup: Boolean = False);
    procedure SelectSave(const aName: UnicodeString);
    procedure SelectLoc(aIndex: Integer; aPlayerIndex: Integer);
    procedure SelectTeam(aIndex: Integer; aPlayerIndex: Integer);
    procedure SelectColor(aColor: Cardinal; aPlayerIndex: Integer);
    procedure KickPlayer(aPlayerIndex: Integer);
    procedure BanPlayer(aPlayerIndex: Integer);
    procedure SetToHost(aPlayerIndex: Integer);
    procedure ResetBans;
    procedure SendPassword(const aPassword: AnsiString);
    procedure SetPassword(const aPassword: AnsiString);
    property Password: AnsiString read fPassword;
    property Description: UnicodeString read fDescription write SetDescription;
    function ReadyToStart: Boolean;
    function CanStart: TKMGameStartMode;
    function CanTakeLocation(aPlayer, aLoc: Integer; AllowSwapping: Boolean): Boolean;
    procedure StartClick; //All required arguments are in our class
    procedure SendPlayerListAndRefreshPlayersSetup(aPlayerIndex: TKMNetHandleIndex = NET_ADDRESS_OTHERS);
    procedure UpdateGameOptions(aPeacetime: Word; aSpeedPT, aSpeedAfterPT: Single; aDifficulty: TKMMissionDifficulty);
    procedure SendGameOptions;
    procedure RequestFileTransfer;
    procedure VoteReturnToLobby;
    procedure AnnounceReadyToReturnToLobby;
    procedure WakeUpNotReady;
    procedure AskToSendCrashreport(aOtherPlayerIndex: Integer; aErrorStr: UnicodeString);

    //Common
    procedure ConsoleCommand(const aText: UnicodeString);
    procedure PostMessage(aTextID: Integer; aSound: TKMChatSound; const aText1: UnicodeString = ''; const aText2: UnicodeString = '';
                          aRecipient: TKMNetHandleIndex = NET_ADDRESS_ALL; aTextID2: Integer = -1);
    procedure PostChat(const aText: UnicodeString; aMode: TKMChatMode; aRecipientServerIndex: TKMNetHandleIndex = NET_ADDRESS_OTHERS); overload;
    procedure PostLocalMessage(const aText: UnicodeString; aSound: TKMChatSound = csNone);
    procedure AnnounceGameInfo(aGameTime: TDateTime; aMap: UnicodeString);

    //Gameplay
    property MapInfo: TKMMapInfo read GetMapInfo;
    property SaveInfo: TKMSaveInfo read fSaveInfo;
    property NetGameOptions: TKMGameOptions read fNetGameOptions;
    property SelectGameKind: TKMNetGameKind read fSelectGameKind;
    property NetPlayers: TKMNetPlayersList read fNetPlayers;
    property MyNetPlayer: TKMNetPlayerInfo read GetMyNetPlayer;
    property LastProcessedTick: Cardinal write fLastProcessedTick;
    property MissingFileType: TKMNetGameKind read fMissingFileType;
    property MissingFileName: UnicodeString read fMissingFileName;
    procedure GameCreated;
    procedure SendCommands(aStream: TKMemoryStream; aPlayerIndex: ShortInt = -1);
    procedure AttemptReconnection;
    procedure ReturnToLobby;

    property PacketsReceived[aKind: TKMessageKind]: Cardinal read GetPacketsReceived;
    property PacketsSent[aKind: TKMessageKind]: Cardinal read GetPacketsSent;
    property PacketsStatsStartTime: Cardinal read fPacketsStatsStartTime;
    procedure ResetPacketsStats;

    procedure UpdateState(aGlobalTickCount: cardinal);
    procedure UpdateStateIdle;
    procedure FPSMeasurement(aFPS: Cardinal);

    function GetNetPlayerByHandIndex(aHandIndex: Integer): TKMNetPlayerInfo;
    function GetNetPlayerIndex(aHandIndex: Integer): Integer;
  end;


var
  gNetworking: TKMNetworking;


implementation
uses
  Math, StrUtils,
  KM_NetworkConsts, KM_Sound, KM_Log, KM_CommonUtils, KM_HandsCollection, KM_Hand,
  KM_System, KM_GameApp, KM_GameSettings,
  KM_Resource, KM_ResSound, KM_ResTexts, KM_NetworkUtils;


{ TKMNetworking }
constructor TKMNetworking.Create(const aMasterServerAddress: string; aKickTimeout, aPingInterval, aAnnounceInterval, aServerUDPScanPort: Word;
                                 const aPacketsAccDelay: Integer;
                                 aDynamicFOW, aMapsFilterEnabled: Boolean; const aMapsCRCListStr: UnicodeString; const aPeacetimeRng: TKMRangeInt;
                                 const aSpeedRng: TKMRangeSingle; const aSpeedRngAfterPT: TKMRangeSingle);
var
  gameFilter: TKMPGameFilter;
begin
  inherited Create;

  SetGameState(lgsNone);

  fNetServer := TKMDedicatedServer.Create(1, aKickTimeout, aPingInterval, aAnnounceInterval, aServerUDPScanPort,
                                          aMasterServerAddress, '', '', aPacketsAccDelay, False);
  gameFilter := TKMPGameFilter.Create(aDynamicFOW, aMapsFilterEnabled, aMapsCRCListStr, aPeacetimeRng, aSpeedRng, aSpeedRngAfterPT);
  fNetServer.Server.GameFilter := gameFilter;

  fNetGameFilter := TKMPGameFilter.Create;

  fNetClient := TKMNetClient.Create;
  // Handle all 'background (unhandled)' exceptions, so we will be able to intercept them with madExcept
  fNetClient.SetHandleBackgrounException;
  fNetPlayers := TKMNetPlayersList.Create;
  fServerQuery := TKMServerQuery.Create(aMasterServerAddress, aServerUDPScanPort);
  fNetGameOptions := TKMGameOptions.Create;
  fFileSenderManager := TKMFileSenderManager.Create;
  fMutedPlayersList := TList<Integer>.Create;
  fFileSenderManager.OnTransferCompleted := TransferOnCompleted;
  fFileSenderManager.OnTransferPacket := TransferOnPacket;
  gLog.AddOnLogEventSub(PostLogMessageToChat);
  fVoteReturnToLobbySucceeded := False;

  gNetworking := Self;
end;


destructor TKMNetworking.Destroy;
begin
  gLog.RemoveOnLogEventSub(PostLogMessageToChat);
  fNetPlayers.Free;
  fNetServer.Free;
  fNetClient.Free;
  fServerQuery.Free;
  fFileSenderManager.Free;
  fMutedPlayersList.Free;
  FreeAndNil(fMapInfo);
  FreeAndNil(fSaveInfo);
  FreeAndNil(fNetGameOptions);
  FreeAndNil(fNetGameFilter);

  gNetworking := nil;

  inherited;
end;


function TKMNetworking.MyIPString: string;
begin
  Result := fNetClient.MyIPString;
end;


function TKMNetworking.IsHost: Boolean;
begin
  if Self = nil then Exit(False);
  
  Result := (fNetPlayerKind = lpkHost);
end;


function TKMNetworking.IsReconnecting:boolean;
begin
  Result := (fNetGameState = lgsReconnecting) or (fReconnectRequested <> 0);
end;


//Startup a local server and connect to it as ordinary client
procedure TKMNetworking.Host(const aServerName: AnsiString; aPort: Word; const aNickname: AnsiString;
                             aAnnounceServer, aAnnounceUDP: Boolean);
begin
  fWelcomeMessage := '';
  fPassword := '';
  fDescription := '';
  fIgnorePings := 0; //Accept pings
  fNetServer.Stop;

  fNetServer.OnMessage := gLog.AddTime; //Log server messages in case there is a problem, but hide from user
  try
    fNetServer.Start(aServerName, aPort, aAnnounceServer, aAnnounceUDP);
  except
    on E: Exception do
    begin
      // Server failed to start
      OnHostFail(E.Message);
      Exit;
    end;
  end;

  Join('127.0.0.1', aPort, aNickname, 0); //Server will assign hosting rights to us as we are the first joiner
end;


procedure TKMNetworking.Join(const aServerAddress: string; aPort: Word; const aNickname: AnsiString; aRoom: Integer; aIsReconnection: Boolean = False);
begin
  Assert(not fNetClient.Connected, 'Cannot connect: We are already connected');

  fWelcomeMessage := '';
  fPassword := '';
  fDescription := '';
  fIgnorePings := 0; //Accept pings
  fJoinTimeout := TimeGet;
  fMyIndex := -1; //Host will send us PlayerList and we will get our index from there
  fHostIndex := -1;
  fMyIndexOnServer := -1; //Assigned by Server
  fRoomToJoin := aRoom;
  if aIsReconnection then
    SetGameState(lgsReconnecting) //Special state so we know we are reconnecting
  else
    SetGameState(lgsConnecting); //We are still connecting to the server

  fServerAddress := aServerAddress;
  fServerPort := aPort;
  fMyNickname := aNickname;
  fNetPlayerKind := lpkJoiner;
  fServerName := ''; //Server will tell us once we are joined

  fNetClient.OnRecieveData := PacketRecieve;
  fNetClient.OnConnectSucceed := ConnectSucceed;
  fNetClient.OnConnectFailed := ConnectFailed;
  fNetClient.OnForcedDisconnect := ForcedDisconnect;
  //fNetClient.OnStatusMessage := OnTextMessage; //For debugging only
  fNetClient.ConnectTo(fServerAddress, fServerPort);
end;


//Connection was successful, but we still need mkIndexOnServer to be able to do anything
procedure TKMNetworking.ConnectSucceed(Sender:TObject);
begin
  //This is currently unused, the player does not need to see this message
  //PostLocalMessage('Connection successful');
end;


procedure TKMNetworking.ConnectFailed(const aText: string);
begin
  fNetClient.Disconnect;
  OnJoinFail(aText);
end;


//Send message that we have deliberately disconnected
procedure TKMNetworking.AnnounceDisconnect(aLastSentCmdsTick: Cardinal = LAST_SENT_COMMANDS_TICK_NONE);
begin
//  gLog.AddTime(Format('AnnounceDisconnect. LastSentCmdsTick = %d', [aLastSentCmdsTick]));
  // Tell everyone when we quit
  PacketSend(NET_ADDRESS_OTHERS, mkDisconnect, aLastSentCmdsTick); //Send our last sent commands tick
end;


procedure TKMNetworking.Disconnect;
begin
  fIgnorePings := 0;
  fReconnectRequested := 0; //Cancel any reconnection that was requested
  fEnteringPassword := False;
  fReturnedToLobby := False;
  SetGameState(lgsNone);
  OnJoinSucc := nil;
  OnJoinFail := nil;
  OnJoinAssignedHost := nil;
  OnHostFail := nil;
  OnTextMessage := nil;
  OnPlayersSetup := nil;
  OnUpdateMinimap := nil;
  OnMapName := nil;
  OnMapMissing := nil;
  OnCommands := nil;
  OnResyncFromTick := nil;
  OnDisconnect := nil;
  OnPingInfo := nil;
  OnReassignedHost := nil;
  OnReassignedJoiner := nil;
  fWelcomeMessage := '';

  fNetPlayers.Clear;
  fMutedPlayersList.Clear;
  fNetGameOptions.Reset;
  fNetClient.Disconnect;
  fNetServer.Stop;

  FreeAndNil(fMapInfo);
  FreeAndNil(fSaveInfo);
  FreeAndNil(fFileReceiver);
  AbortAllTransfers;

  fSelectGameKind := ngkNone;
end;


procedure TKMNetworking.DropPlayers(aPlayers: TKMByteArray);
var
  I: Integer;
  serverIndex: TKMNetHandleIndex;
begin
  Assert(IsHost, 'Only the host is allowed to drop players');
  for I := Low(aPlayers) to High(aPlayers) do
  begin
    if NetPlayers[aPlayers[I]].Dropped then
    begin
      //Reset NetPlayer LastSentCommandsTick, so we are not going to wait its last commands anymore... Let's hope for the best...
      NetPlayers[aPlayers[I]].LastSentCommandsTick := LAST_SENT_COMMANDS_TICK_NONE;
    end
    else
    begin
      serverIndex := NetPlayers[aPlayers[I]].IndexOnServer;
      //Make sure this player is properly disconnected from the server
      PacketSendInd(NET_ADDRESS_SERVER, mkKickPlayer, serverIndex);
      NetPlayers.DropPlayer(serverIndex);
    end;
    PostMessage(TX_NET_DROPPED, csLeave, NetPlayers[aPlayers[I]].NicknameColoredU);
  end;
  SendPlayerListAndRefreshPlayersSetup;

  //Player being dropped may cause vote to end
  if (fNetGameState in [lgsLoading, lgsGame]) and (fNetPlayers.FurtherVotesNeededForMajority <= 0) then
    ReturnToLobbyVoteSucceeded;
end;


procedure TKMNetworking.ForcedDisconnect(Sender: TObject);
begin
  OnDisconnect(gResTexts[TX_NET_SERVER_STOPPED]);
end;


function TKMNetworking.Connected: Boolean;
begin
  Result := fNetClient.Connected;
end;


procedure TKMNetworking.DecodePingInfo(aStream: TKMemoryStream);
var
  I: Integer;
  pingCount: Integer;
  playerHandle: TKMNetHandleIndex;
  pingValue, fpsValue: Word;
  localHandle: Integer;
begin
  if fIgnorePings > 0 then
  begin
    Dec(fIgnorePings);
    Exit;
  end;
  if fIgnorePings <> 0 then exit; //-1 means ignore all pings

  aStream.Read(pingCount);
  for I:=1 to pingCount do
  begin
    aStream.Read(playerHandle);
    localHandle := fNetPlayers.ServerToLocal(playerHandle);
    aStream.Read(pingValue);
    aStream.Read(fpsValue);
    //This player might not be in the lobby yet, could still be asking to join. If so we do not care about their ping.
    if localHandle <> -1 then
    begin
      fNetPlayers[localHandle].AddPing(pingValue);
      if localHandle <> fMyIndex then // our own FPS was set immidiately after measurement, without delay.
        fNetPlayers[localHandle].FPS := fpsValue;
    end;
  end;
end;


procedure TKMNetworking.SendMapOrSave(Recipient: TKMNetHandleIndex = NET_ADDRESS_OTHERS);
var
  M: TKMemoryStream;
begin
  M := TKMemoryStreamBinary.Create;
  case fSelectGameKind of
    ngkSave: begin
                M.WriteW(fSaveInfo.FileName);
                M.Write(fSaveInfo.CRC);
                PacketSend(Recipient, mkSaveSelect, M);
              end;
    ngkMap:  begin
                M.WriteW(fMapInfo.FileNameWithoutHash);
                M.Write(fMapInfo.CRC);
                PacketSend(Recipient, mkMapSelect, M);
              end;
    else      PacketSend(Recipient, mkResetMap);
  end;
  M.Free;
end;


procedure TKMNetworking.MatchPlayersToSave(aPlayerID: Integer = -1);
var
  I, K: Integer;
begin
  Assert(IsHost, 'Only host can match players');
  Assert(fSelectGameKind = ngkSave, 'Not a save');

  if aPlayerID = -1 then
  begin
    //If we are matching all then reset them all first so we don't get clashes
    for I := 1 to fNetPlayers.Count do
      if not fNetPlayers[I].IsSpectator then
        fNetPlayers[I].StartLocation := LOC_RANDOM;

    for I := 1 to MAX_LOBBY_PLAYERS - fSaveInfo.GameInfo.HumanCount - fNetPlayers.GetClosedCount
                                    - Max(fNetPlayers.GetSpectatorCount - MAX_LOBBY_SPECTATORS, 0) do
      //First 2 spectators don't count towards MAX_LOBBY_PLAYERS (separate section), but additional ones do
      if fNetPlayers.Count - Min(fNetPlayers.GetSpectatorCount, MAX_LOBBY_SPECTATORS) < MAX_LOBBY_PLAYERS then
        fNetPlayers.AddClosedPlayer; //Close unused slots
  end;

  //Match players based on their nicknames
  for I := 1 to fNetPlayers.Count do
    for K := 1 to fSaveInfo.GameInfo.PlayerCount do
      if fSaveInfo.GameInfo.Enabled[K-1]
      and ((I = aPlayerID) or (aPlayerID = -1)) //-1 means update all players
      and fNetPlayers.LocAvailable(K)
      and fNetPlayers[I].IsHuman
      and not fNetPlayers[I].IsSpectator
      and (fNetPlayers[I].Nickname = fSaveInfo.GameInfo.OwnerNickname[K-1]) then
      begin
        fNetPlayers[I].StartLocation := K;
        Break;
      end;
end;


procedure TKMNetworking.AbortAllTransfers;
begin
  fFileSenderManager.AbortAllTransfers; //Any ongoing transfer is cancelled
  if Assigned(OnAbortAllTransfers) then
    OnAbortAllTransfers;
end;


//Clear selection from any map/save
procedure TKMNetworking.SelectNoMap(const aErrorMessage: UnicodeString);
begin
  Assert(IsHost, 'Only host can reset map');

  fSelectGameKind := ngkNone;

  FreeAndNil(fMapInfo);
  FreeAndNil(fSaveInfo);

  AbortAllTransfers;

  PacketSend(NET_ADDRESS_OTHERS, mkResetMap);
  fNetPlayers.ResetLocAndReady; //Reset start locations
  MyNetPlayer.ReadyToStart := True;
  MyNetPlayer.HasMapOrSave := True;

  if Assigned(OnMapName) then
    OnMapName(aErrorMessage);

  SendPlayerListAndRefreshPlayersSetup;
end;


//Tell other players which map we will be using
//Players will reset their starting locations and "Ready" status on their own
procedure TKMNetworking.SelectMap(const aName: UnicodeString; aMapKind: TKMMapKind; aSendPlayerSetup: Boolean = False);
begin
  Assert(IsHost, 'Only host can select maps');
  FreeAndNil(fMapInfo);
  FreeAndNil(fSaveInfo);

  //Strict scanning to force CRC recalculation
  fMapInfo := TKMMapInfo.Create(aName, True, aMapKind);

  if not fMapInfo.IsValid then
  begin
    SelectNoMap(gResTexts[TX_NET_ERR_MAP_INVALID]);
    PostLocalMessage(gResTexts[TX_NET_ERR_MAP_INVALID_MSG], csSystem);
    Exit;
  end;

  if (aMapKind = mkDL) and not fMapInfo.IsFilenameEndMatchHash then
  begin
    SelectNoMap(gResTexts[TX_NET_ERR_DL_MAP_FILE_CHANGED]);
    PostLocalMessage(gResTexts[TX_NET_ERR_DL_MAP_FILE_CHANGED_MSG], csSystem);
    Exit;
  end;

  fMapInfo.LoadExtra; //Lobby requires extra map info such as CanBeHuman

  fNetPlayers.ResetLocAndReady; //Reset start locations

  fSelectGameKind := ngkMap;
  MyNetPlayer.ReadyToStart := True;
  MyNetPlayer.HasMapOrSave := True;
  AbortAllTransfers; //Any ongoing transfer is cancelled

  SendMapOrSave;

  if Assigned(OnMapName) then
    OnMapName(fMapInfo.Name);

  //Don't send player setup by default. Cause it will be sent from lobby just afterwards
  if aSendPlayerSetup then
    SendPlayerListAndRefreshPlayersSetup;
end;


//Tell other players which save we will be using
//Players will reset their starting locations and "Ready" status on their own
procedure TKMNetworking.SelectSave(const aName: UnicodeString);
var
  error: UnicodeString;
begin
  Assert(IsHost, 'Only host can select saves');

  FreeAndNil(fMapInfo);
  FreeAndNil(fSaveInfo);

  fSaveInfo := TKMSaveInfo.Create(aName, True);

  if not fSaveInfo.IsValid then
  begin
    error := WrapColor(fSaveInfo.SaveError.ErrorString, clSaveLoadError); //Make a copy since fSaveInfo is freed in SelectNoMap
    SelectNoMap(error); //State the error, e.g. wrong version
    Exit;
  end;

  fNetPlayers.ResetLocAndReady; //Reset start locations

  NetGameOptions.Peacetime := fSaveInfo.GameOptions.Peacetime;
  NetGameOptions.SpeedPT := fSaveInfo.GameOptions.SpeedPT;
  NetGameOptions.SpeedAfterPT := fSaveInfo.GameOptions.SpeedAfterPT;
  SendGameOptions;
  if Assigned(OnGameOptions) then OnGameOptions;

  fSelectGameKind := ngkSave;

  fMyIndex := fNetPlayers.NicknameToLocal(fMyNickname); // host's index can change when players are removed
  fHostIndex := fMyIndex;
  // Set ReadyToStart and HasMapOrSave with updated fMyIndex
  MyNetPlayer.ReadyToStart := True;
  MyNetPlayer.HasMapOrSave := True;

  //Randomise locations within team is disabled for saves
  NetPlayers.RandomizeTeamLocations := False;
  AbortAllTransfers; //Any ongoing transfer is cancelled

  SendMapOrSave;
  MatchPlayersToSave; //Don't match players if it's not a valid save

  if Assigned(OnMapName) then
    OnMapName(fSaveInfo.FileName);

  SendPlayerListAndRefreshPlayersSetup;
end;


//Tell other players which start position we would like to use
//Each players choice should be unique
procedure TKMNetworking.SelectLoc(aIndex: Integer; aPlayerIndex: Integer);
var
  netPlayerIndex: Integer;
begin
  //Check if position can be taken before doing anything
  if not CanTakeLocation(aPlayerIndex, aIndex, IsHost and fNetPlayers.HostDoesSetup) then
  begin
    if Assigned(OnPlayersSetup) then OnPlayersSetup;
    Exit;
  end;

  //If someone else has this index, switch them (only when HostDoesSetup)
  if IsHost and fNetPlayers.HostDoesSetup and (aIndex <> LOC_RANDOM) and (aIndex <> LOC_SPECTATE) then
  begin
    netPlayerIndex := fNetPlayers.StartingLocToLocal(aIndex);
    if netPlayerIndex <> -1 then
    begin
      fNetPlayers[netPlayerIndex].StartLocation := fNetPlayers[aPlayerIndex].StartLocation;

      //Spectators can't have team
      if fNetPlayers[netPlayerIndex].StartLocation = LOC_SPECTATE then
        fNetPlayers[netPlayerIndex].Team := 0;

      //If host pushes player to a different loc, the player should be set to not ready (they must agree to change)
      if (netPlayerIndex <> fMyIndex) and not fNetPlayers[netPlayerIndex].IsComputer then
        fNetPlayers[netPlayerIndex].ReadyToStart := False;
    end;
  end;

  case fNetPlayerKind of
    lpkHost:   begin
                  //Host makes rules, Joiner will get confirmation from Host
                  fNetPlayers[aPlayerIndex].StartLocation := aIndex; //Use aPlayerIndex not fMyIndex because it could be an AI

                  //If host pushes player to a different loc, the player should be set to not ready (they must agree to change)
                  if (aPlayerIndex <> fMyIndex) and not fNetPlayers[aPlayerIndex].IsComputer then
                    fNetPlayers[aPlayerIndex].ReadyToStart := False;

                  if aIndex = LOC_SPECTATE then
                    fNetPlayers[aPlayerIndex].Team := 0; //Spectators can't have team

                  // Update minimap
                  if (aPlayerIndex = fMyIndex) and Assigned(OnUpdateMinimap) then
                    OnUpdateMinimap;

                  SendPlayerListAndRefreshPlayersSetup;
                end;
    lpkJoiner: PacketSend(NET_ADDRESS_HOST, mkStartingLocQuery, aIndex);
  end;
end;


//Tell other players which team we are on. Player selections need not be unique
procedure TKMNetworking.SelectTeam(aIndex:integer; aPlayerIndex:integer);
begin
  fNetPlayers[aPlayerIndex].Team := aIndex; //Use aPlayerIndex not fMyIndex because it could be an AI

  case fNetPlayerKind of
    lpkHost:   begin
                  //If host pushes player to a different team, the player should be set to not ready (they must agree to change)
                  if (aPlayerIndex <> fMyIndex) and not fNetPlayers[aPlayerIndex].IsComputer then
                    fNetPlayers[aPlayerIndex].ReadyToStart := False;

                  SendPlayerListAndRefreshPlayersSetup;
                end;
    lpkJoiner: PacketSend(NET_ADDRESS_HOST, mkSetTeam, aIndex);
  end;
end;


//Tell other players which color we will be using
//For now players colors are not unique, many players may have one color
procedure TKMNetworking.SelectColor(aColor: Cardinal; aPlayerIndex: Integer);
begin
  if not fNetPlayers.ColorAvailable(aColor) then Exit;
  if (fSelectGameKind = ngkSave)
    and SaveInfo.IsValid
    and SaveInfo.GameInfo.ColorUsed(aColor) then Exit;

  //Host makes rules, Joiner will get confirmation from Host
  fNetPlayers[aPlayerIndex].FlagColor := aColor; //Use aPlayerIndex not fMyIndex because it could be an AI

  case fNetPlayerKind of
    lpkHost:   SendPlayerListAndRefreshPlayersSetup;
    lpkJoiner: begin
                  PacketSend(NET_ADDRESS_HOST, mkFlagColorQuery, aColor);
                  if Assigned(OnPlayersSetup) then OnPlayersSetup;
                end;
  end;
end;


procedure TKMNetworking.KickPlayer(aPlayerIndex: Integer);
begin
  Assert(IsHost, 'Only host is allowed to kick players out');
  //No need to play a sound, server will do that when it announces that player disconnected
  PostMessage(TX_NET_KICKED, csNone, fNetPlayers[aPlayerIndex].NicknameColoredU);
  PacketSendInd(NET_ADDRESS_SERVER, mkKickPlayer, fNetPlayers[aPlayerIndex].IndexOnServer);
end;


procedure TKMNetworking.BanPlayer(aPlayerIndex: Integer);
begin
  Assert(IsHost, 'Only host is allowed to ban players');
  //No need to play a sound, server will do that when it announces that player disconnected
  PostMessage(TX_NET_BANNED, csNone, fNetPlayers[aPlayerIndex].NicknameColoredU);
  PacketSendInd(NET_ADDRESS_SERVER, mkBanPlayer, fNetPlayers[aPlayerIndex].IndexOnServer);
end;


procedure TKMNetworking.SetToHost(aPlayerIndex: Integer);
begin
  Assert(IsHost, 'Only host is allowed to promote players');
  //Don't allow host reassigning if the server is running within this client (if host quits server stops)
  if fNetServer.IsListening then
    PostLocalMessage(gResTexts[TX_NET_PROMOTE_LOCAL_SERVER], csSystem)
  else
    PacketSendInd(NET_ADDRESS_SERVER, mkGiveHost, fNetPlayers[aPlayerIndex].IndexOnServer);
end;


procedure TKMNetworking.ResetBans;
begin
  PacketSend(NET_ADDRESS_SERVER, mkResetBans);
  PostMessage(TX_NET_BANS_RESET, csSystem);
end;


procedure TKMNetworking.WriteInfoToJoinRoom(aM: TKMemoryStream);
begin
  aM.Write(fRoomToJoin);
  aM.Write(TKMGameRevision(GAME_REVISION_NUM));
end;


procedure TKMNetworking.SendPassword(const aPassword: AnsiString);
var
  M: TKMemoryStream;
begin
  M := TKMemoryStreamBinary.Create;

  WriteInfoToJoinRoom(M);

  M.WriteA(aPassword);
  PacketSend(NET_ADDRESS_SERVER, mkPassword, M);
  M.Free;

  fEnteringPassword := False;
  fJoinTimeout := TimeGet; //Wait another X seconds for host to reply before timing out
end;


procedure TKMNetworking.SetPassword(const aPassword: AnsiString);
begin
  Assert(IsHost, 'Only host can set password');
  fPassword := aPassword;
  OnMPGameInfoChanged; //Send the password state to the server so it is shown in server list
  PacketSendA(NET_ADDRESS_SERVER, mkSetPassword, fPassword); //Send to server

  PacketSendA(NET_ADDRESS_OTHERS, mkSetPassword, fPassword); //Send to other players as well, just to let them know we have password here

  if Assigned(OnSetPassword) then
    OnSetPassword(fPassword);
end;


//Joiner indicates that he is ready to start
function TKMNetworking.ReadyToStart: Boolean;
begin
  if (fSelectGameKind = ngkSave) and (MyNetPlayer.StartLocation = 0) then
  begin
    PostLocalMessage(gResTexts[TX_LOBBY_ERROR_SELECT_PLAYER], csSystem);
    Result := False;
    Exit;
  end;

  if ((fSelectGameKind = ngkMap) and fMapInfo.IsValid) or
     ((fSelectGameKind = ngkSave) and fSaveInfo.IsValid) or
     MyNetPlayer.IsSpectator then //Spectators can be ready without map selected
  begin
    //Toggle it
    PacketSend(NET_ADDRESS_HOST, mkReadyToStart);
    Result := not MyNetPlayer.ReadyToStart;
  end
  else
  begin
    PostLocalMessage(gResTexts[TX_LOBBY_ERROR_NO_MAP], csSystem);
    Result := False;
  end;
end;


function TKMNetworking.CanStart: TKMGameStartMode;

  function BoolToGameStartMode(aAllowed: Boolean): TKMGameStartMode;
  begin
    if not aAllowed then
    begin
      //Check if we can't start unsupported save
      if (fSelectGameKind = ngkSave)
        and fSaveInfo.IsValid
        and not fSaveInfo.IsValidStrictly then
        Result := gsmNoStartWithWarn
      else
        Result := gsmNoStart;
    end
    else
    begin
      if (fSelectGameKind = ngkSave)
        and not fSaveInfo.IsValidStrictly then //Save detected as non-strict valid already at that point
        Result := gsmStartWithWarn
      else
        Result := gsmStart;
    end;
  end;

var
  I: Integer;
  startAllowed: Boolean;
begin
  case fSelectGameKind of
    ngkMap:   startAllowed := fNetPlayers.AllReady and fMapInfo.IsValid;
    ngkSave:  begin
                startAllowed := fNetPlayers.AllReady and fSaveInfo.IsValid;
                for I := 1 to fNetPlayers.Count do //In saves everyone must chose a location
                  startAllowed := startAllowed and ((fNetPlayers[i].StartLocation <> LOC_RANDOM) or fNetPlayers[i].IsClosed);
              end;
    else      startAllowed := False;
  end;
  //At least one player must NOT be a spectator or closed
  for I := 1 to fNetPlayers.Count do
    if not fNetPlayers[i].IsSpectator and not fNetPlayers[i].IsClosed then
      Exit(BoolToGameStartMode(startAllowed)); //Exit with result from above

  //If we reached here then all players are spectators so only saves can be started,
  //unless this map has AI-only locations (spectators can watch the AIs)
  if (fSelectGameKind = ngkMap) and (fMapInfo.AIOnlyLocCount = 0) then
    startAllowed := False;

  Result := BoolToGameStartMode(startAllowed);
end;


//Tell other players we want to start
procedure TKMNetworking.StartClick;
var
  humanUsableLocs, aiUsableLocs, advancedAIUsableLocs: TKMHandIDArray;
  errorMessage: UnicodeString;
  M: TKMemoryStream;
  checkMapInfo: TKMMapInfo;
  fixedLocsColors: TKMCardinalArray;
begin
  Assert(IsHost, 'Only host can start the game');
  Assert(IsGameStartAllowed(CanStart), 'Can''t start the game now');
  Assert(fNetGameState = lgsLobby, 'Can only start from lobby');

  SetLength(fixedLocsColors, 0);

  //Define random parameters (start locations and flag colors)
  //This will also remove odd players from the List, they will lose Host in few seconds
  case fSelectGameKind of
    ngkMap:  begin
                humanUsableLocs := fMapInfo.HumanUsableLocs;
                aiUsableLocs := fMapInfo.AIUsableLocs;
                advancedAIUsableLocs := fMapInfo.AdvancedAIUsableLocs;
                fixedLocsColors := fMapInfo.FixedLocsColors;
                //Check that map's hash hasn't changed
                checkMapInfo := TKMMapInfo.Create(fMapInfo.Name, True, fMapInfo.Kind);
                try
                  if checkMapInfo.CRC <> fMapInfo.CRC then
                  begin
                    PostLocalMessage(Format(gResTexts[TX_LOBBY_CANNOT_START], [gResTexts[TX_NET_ERR_MAP_FILE_CHANGED]]), csSystem);
                    Exit;
                  end;
                finally
                  checkMapInfo.Free;
                end;
              end;
    ngkSave: begin
                humanUsableLocs := fSaveInfo.GameInfo.HumanUsableLocs;
                //AIs may replace humans
                aiUsableLocs := fSaveInfo.GameInfo.HumanUsableLocs;
                advancedAIUsableLocs := fSaveInfo.GameInfo.HumanUsableLocs;
                fixedLocsColors := fSaveInfo.GameInfo.FixedLocsColors;
              end;
    else      begin
                SetLength(humanUsableLocs, 0);
                SetLength(aiUsableLocs, 0);
              end;
  end;
  if not fNetPlayers.ValidateSetup(humanUsableLocs, aiUsableLocs, advancedAIUsableLocs, fixedLocsColors, errorMessage) then
  begin
    PostLocalMessage(Format(gResTexts[TX_LOBBY_CANNOT_START], [errorMessage]), csSystem);
    Exit;
  end;

  fNetPlayers.ResetReadyToPlay; //Nobody is ready to play

  //ValidateSetup removes closed players if successful, so our index changes
  fMyIndex := fNetPlayers.NicknameToLocal(fMyNickname);
  fHostIndex := fMyIndex;

  //Init random seed for all the players
  fNetGameOptions.RandomSeed := RandomRange(1, 2147483646);

  //Let everyone start with final version of fNetPlayers and fNetGameOptions
  SendGameOptions;

  M := TKMemoryStreamBinary.Create;
  M.Write(fHostIndex);
  fNetPlayers.SaveToStream(M);
  PacketSend(NET_ADDRESS_OTHERS, mkStart, M);
  M.Free;

  StartGame;
end;


procedure TKMNetworking.SendPlayerListAndRefreshPlayersSetup(aPlayerIndex: TKMNetHandleIndex = NET_ADDRESS_OTHERS);
var
  I: Integer;
  M: TKMemoryStream;
  aiOnlyColors: TKMCardinalArray;
begin
  Assert(IsHost, 'Only host can send player list');

  //In saves we should load team and color from the SaveInfo
  if (fNetGameState = lgsLobby) and (fSelectGameKind = ngkSave) then
    for I := 1 to NetPlayers.Count do
      if (NetPlayers[I].StartLocation <> LOC_RANDOM) and (NetPlayers[I].StartLocation <> LOC_SPECTATE) then
      begin
        NetPlayers[I].FlagColor := fSaveInfo.GameInfo.Color[NetPlayers[I].HandIndex];
        NetPlayers[I].Team := fSaveInfo.GameInfo.Team[NetPlayers[I].HandIndex];
      end
      else
      begin
        NetPlayers[I].Team := 0;
        //Spectators may still change their color, but may not use one from the save
        if NetPlayers[I].IsColorSet
          and SaveInfo.GameInfo.ColorUsed(NetPlayers[I].FlagColor) then
          NetPlayers[I].FlagColor := 0;
      end;

  // Map change could casue, that some colors are not valid anymore
  // Reset those colors then
  if (fNetGameState = lgsLobby) and (fSelectGameKind = ngkMap) then
  begin
    aiOnlyColors := MapInfo.AIOnlyLocsColors; // save it locally to avoid multiple calculations
    for I := 1 to NetPlayers.Count do
    begin
      if NetPlayers[I].IsColorSet
        and IsColorCloseToColors(NetPlayers[I].FlagColor, aiOnlyColors, MIN_PLAYER_COLOR_DIST) then
        NetPlayers[I].ResetColor;
    end;
  end;

  fMyIndex := fNetPlayers.NicknameToLocal(fMyNickname); //The host's index can change when players are removed
  fHostIndex := fMyIndex;

  OnMPGameInfoChanged; //Tell the server about the changes

  M := TKMemoryStreamBinary.Create;
  M.Write(fHostIndex);
  fNetPlayers.SaveToStream(M);
  PacketSend(aPlayerIndex, mkPlayersList, M);
  M.Free;

  if Assigned(OnPlayersSetup) then OnPlayersSetup;
end;


procedure TKMNetworking.UpdateGameOptions(aPeacetime: Word; aSpeedPT, aSpeedAfterPT: Single; aDifficulty: TKMMissionDifficulty);
begin
  fNetGameOptions.Peacetime := aPeacetime;
  fNetGameOptions.SpeedPT := aSpeedPT;
  fNetGameOptions.SpeedAfterPT := aSpeedAfterPT;
  fNetGameOptions.MissionDifficulty := aDifficulty;

  fNetPlayers.ResetReady;
  MyNetPlayer.ReadyToStart := True;

  SendGameOptions;
  SendPlayerListAndRefreshPlayersSetup;
end;


procedure TKMNetworking.SendGameOptions;
var
  M: TKMemoryStream;
begin
  Assert(IsHost, 'Only host can send game options');

  M := TKMemoryStreamBinary.Create;
  fNetGameOptions.Save(M);
  PacketSend(NET_ADDRESS_OTHERS, mkGameOptions, M);
  M.Free;
end;


procedure TKMNetworking.RequestFileTransfer;
begin
  if fFileReceiver = nil then
    case fMissingFileType of
      ngkMap:  begin
                  fFileReceiver := TKMFileReceiver.Create(kttMap, fMissingFileName, fMissingFileCRC);
                  PacketSendW(NET_ADDRESS_HOST, mkFileRequest, fMissingFileName);
                end;
      ngkSave: begin
                  fFileReceiver := TKMFileReceiver.Create(kttSave, fMissingFileName);
                  PacketSendW(NET_ADDRESS_HOST, mkFileRequest, fMissingFileName);
                end;
    end;
end;


procedure TKMNetworking.VoteReturnToLobby;
begin
  //Even if we are the host we still send our vote through the network, that's simpler
  PacketSend(NET_ADDRESS_HOST, mkVote);
end;


procedure TKMNetworking.ConsoleCommand(const aText: UnicodeString);
{var
  s,PlayerID: Integer;
  ConsoleCmd: UnicodeString;}
begin
  {PostLocalMessage('[$808080]' + aText + '[]');
  s := PosEx(' ', aText);
  if s = 0 then s := Length(aText) + 1;

  ConsoleCmd := LowerCase(LeftStr(aText, s-1));

  if ConsoleCmd = '/kick' then
  begin
    if not IsHost then
    begin
      PostLocalMessage('Only the host can kick players', False);
      Exit;
    end;
    if (Length(aText) >= s+1) and TryStrToInt(aText[s+1], PlayerID)
    and InRange(PlayerID, 1, fNetPlayers.Count) then
    begin
      if fNetPlayers[PlayerID].IsHuman
      and (PlayerID <> MyIndex) then
        KickPlayer(PlayerID)
      else
        PostLocalMessage('You cannot kick yourself or AI players', False);
    end
    else
      PostLocalMessage('Invalid syntax. Type /help for more info', False);
  end
  else
  if ConsoleCmd = '/help' then
    PostLocalMessage('The following console commands are available:|' +
                     '    /kick <Player ID> - Kicks a player from the lobby|' +
                   //'    /ban <Player ID> - Kicks and bans a player from the lobby|'+
                   //'    /newhost <Player ID> - Changes the host player|'+
                     '    /help - Displays this page|' +
                     'Player IDs:|' +
                     fNetPlayers.GetPlayersWithIDs, False)
  else
  begin
    PostLocalMessage('Unknown console command "' + aText + '". Type /help for more info', False);
  end;}
end;


//We route the message through Server to ensure everyone sees messages in the same order
//with exact same timestamps (possibly added by Server?)
procedure TKMNetworking.PostChat(const aText: UnicodeString; aMode: TKMChatMode; aRecipientServerIndex: TKMNetHandleIndex = NET_ADDRESS_OTHERS);
var
  I: Integer;
  M: TKMemoryStream;
begin
  //Sending chat during reconnections at best causes messages to be lost and at worst causes crashes due to intermediate connecting states
  if IsReconnecting then
    Exit; //Fallback in case UI check fails

  M := TKMemoryStreamBinary.Create;
  M.Write(aMode, SizeOf(aMode));
  M.Write(aRecipientServerIndex);
  M.WriteW(aText);

  case aMode of
    cmTeam:
      if MyNetPlayer.Team = 0 then
        PacketSend(fMyIndexOnServer, mkTextChat, M) //Send to self only if we have no team
      else
        for I := 1 to NetPlayers.Count do
          if (NetPlayers[I].Team = MyNetPlayer.Team) and NetPlayers[I].IsHuman and (NetPlayers[I].IndexOnServer <> -1) then
            PacketSend(NetPlayers[I].IndexOnServer, mkTextChat, M); //Send to each player on team (includes self)

    cmSpectators:
      for I := 1 to NetPlayers.Count do
        if NetPlayers[I].IsSpectator and NetPlayers[I].IsHuman and (NetPlayers[I].IndexOnServer <> -1) then
          PacketSend(NetPlayers[I].IndexOnServer, mkTextChat, M); //Send to each spectator (includes self)

    cmWhisper:
      begin
        PacketSend(aRecipientServerIndex, mkTextChat, M); //Send to specific player
        PacketSend(fMyIndexOnServer, mkTextChat, M); //Send to self as well so the player sees it
      end;

    cmAll:
      PacketSend(NET_ADDRESS_ALL, mkTextChat, M); //Send to all;
  end;
  M.Free;
end;


procedure TKMNetworking.PostMessage(aTextID: Integer; aSound: TKMChatSound; const aText1: UnicodeString = '';
                                    const aText2: UnicodeString = ''; aRecipient: TKMNetHandleIndex = NET_ADDRESS_ALL; aTextID2: Integer = -1);
var
  M: TKMemoryStream;
begin
  M := TKMemoryStreamBinary.Create;
  M.Write(aTextID);
  M.Write(aSound, SizeOf(aSound));
  M.WriteW(aText1);
  M.WriteW(aText2);
  M.Write(aTextID2);
  PacketSend(aRecipient, mkTextTranslated, M);
  M.Free;
end;


procedure TKMNetworking.PostLocalMessage(const aText: UnicodeString; aSound: TKMChatSound = csNone);
const
  CHAT_SOUND: array [TKMChatSound] of TSoundFXNew = (
    sfxnMPChatSystem, // csNone
    sfxnMPChatSystem, // csJoin
    sfxnMPChatSystem, // csLeave
    sfxnMPChatSystem, // csSystem
    sfxnMPChatSystem, // csGameStart
    sfxnMPChatSystem, // csSaveGame
    sfxnMPChatMessage,// csChat
    sfxnMPChatTeam,   // csChatTeam
    sfxnMPChatTeam    // csChatWhisper
  );
begin
  if Assigned(OnTextMessage) then
  begin
    if (gSystem <> nil) and (gGameApp <> nil) and (gGameSettings <> nil) then
      if gGameSettings.FlashOnMessage then
        gSystem.FlashingStart;

    OnTextMessage(aText);

    if aSound <> csNone then
      gSoundPlayer.Play(CHAT_SOUND[aSound]);
  end;
end;


//Send our commands to either to all players, or to specified one
procedure TKMNetworking.SendCommands(aStream: TKMemoryStream; aPlayerIndex: ShortInt = -1);
begin
  if aPlayerIndex = -1 then
    PacketSend(NET_ADDRESS_OTHERS, mkCommands, aStream)
  else
    PacketSend(fNetPlayers[aPlayerIndex].IndexOnServer, mkCommands, aStream);
end;


procedure TKMNetworking.AttemptReconnection;
begin
  if fReconnectRequested = 0 then
    fReconnectRequested := TimeGet; //Do it soon
end;


procedure TKMNetworking.DoReconnection;
var
  tempMyIndex: Integer;
begin
  gLog.LogNetConnection(Format('DoReconnection: %s',[fMyNickname]));
  fReconnectRequested := 0;
  PostLocalMessage(gResTexts[TX_NET_RECONNECTING], csSystem);
  //Stop the previous connection without calling Self.Disconnect as that frees everything
  fNetClient.Disconnect;
  tempMyIndex := fMyIndex;
  Join(fServerAddress,fServerPort,fMyNickname,fRoomToJoin, True); //Join the same server/room as before in reconnecting mode
  fMyIndex := tempMyIndex; //Join overwrites it, but we must remember it
end;


procedure TKMNetworking.PlayerJoined(aServerIndex: TKMNetHandleIndex; const aPlayerName: AnsiString);
begin
  fNetPlayers.AddPlayer(aPlayerName, aServerIndex, '');
  PacketSend(aServerIndex, mkAllowToJoin);
  PacketSendA(aServerIndex, mkSetPassword, fPassword); //Send joiner password, just to tell him
  SendMapOrSave(aServerIndex); //Send the map first so it doesn't override starting locs

  if fSelectGameKind = ngkSave then
    MatchPlayersToSave(fNetPlayers.ServerToLocal(aServerIndex)); //Match only this player
  SendPlayerListAndRefreshPlayersSetup;
  SendGameOptions;
  PostMessage(TX_NET_HAS_JOINED, csJoin, UnicodeString(aPlayerName));
end;


// Check if player (not spectator) is not defeated and not win
function TKMNetworking.IsPlayerHandStillInGame(aPlayerIndex: Integer): Boolean;
begin
  Result := (fNetGameState = lgsGame) and (fNetPlayers[aPlayerIndex].HandIndex <> -1)
            and (gHands[fNetPlayers[aPlayerIndex].HandIndex].AI.IsNotWinnerNotLoser) // This means player is not defeated and not win
            and not fNetPlayers[aPlayerIndex].IsSpectator
end;


// Handle mkReassignHost message
procedure TKMNetworking.ReassignHost(aSenderIndex: TKMNetHandleIndex; M: TKMemoryStream);
var
  newHostIndex, oldHostIndex: TKMNetHandleIndex;
  passwordA: AnsiString;
  descriptionW: UnicodeString;
begin
  M.Read(newHostIndex);
  if fFileReceiver <> nil then
  begin
    FreeAndNil(fFileReceiver); //Transfer is aborted if host disconnects/changes
    //Reset, otherwise it will freeze in "downloading" state
    if Assigned(OnMapMissing) then OnMapMissing('', False); //Set empty str as error msg for now
  end;
  if IsHost then
  begin
    //We are no longer the host
    AbortAllTransfers;
    fNetPlayerKind := lpkJoiner;
    if Assigned(OnReassignedJoiner) then OnReassignedJoiner; //Lobby/game might need to know
    if Assigned(OnPlayersSetup) then OnPlayersSetup;
  end;
  if newHostIndex = fMyIndexOnServer then
  begin
    //We are now the host
    fNetPlayerKind := lpkHost;
    fMyIndex := fNetPlayers.NicknameToLocal(fMyNickname);

    oldHostIndex := fHostIndex;

    if Assigned(OnReassignedHost) then
      OnReassignedHost; //Lobby/game might need to know that we are now hosting

    case fNetGameState of
      lgsLobby:   begin
                     if InRange(fHostIndex, 1, fNetPlayers.Count) then
                       fNetPlayers[fHostIndex].ReadyToStart := False; //Old host is not ready anymore
                     MyNetPlayer.ReadyToStart := True; //The host is always ready
                     fNetPlayers.SetAIReady; //Set all AI players to ready
                     SendGameOptions; //Only needs to be sent when in the lobby. Our version becomes standard.
                   end;
      lgsLoading: begin
                     if Assigned(OnReadyToPlay) then OnReadyToPlay;
                     TryPlayGame;
                   end;
    end;

    fHostIndex := MyIndex; //Set it down here as it is used above

    //Server tells us the password and description in this packet,
    //so they aren't reset when the host is changed
    M.ReadA(passwordA);
    M.ReadW(descriptionW);
    fPassword := passwordA;
    fDescription := descriptionW;

    OnMPGameInfoChanged;
    if (fSelectGameKind = ngkNone)
      or ((fSelectGameKind = ngkMap)  and not MapInfo.IsValid)
      or ((fSelectGameKind = ngkSave) and not SaveInfo.IsValid) then
      SelectNoMap(''); //In case the previous host had the map and we don't
    SendPlayerListAndRefreshPlayersSetup;

    //If host was dropped already, that mean we have to defeat him, because he intentionally quits the game
    //(dropped was set on his mkDisconnect message)
    if fNetPlayers[oldHostIndex].Dropped
      and IsPlayerHandStillInGame(oldHostIndex)
      and (fNetPlayers[oldHostIndex].HandIndex <> -1)
      and Assigned(OnJoinerDropped) then
      OnJoinerDropped(fNetPlayers[oldHostIndex].HandIndex);

    PostMessage(TX_NET_HOSTING_RIGHTS, csSystem, fNetPlayers[fMyIndex].NicknameColoredU);
    gLog.LogNetConnection('Hosting rights reassigned to us ('+UnicodeString(fMyNickname)+')');
  end;
end;


// Handle mkPLayerList message
procedure TKMNetworking.PlayersListReceived(aM: TKMemoryStream);
var
  oldLoc: Integer;
  isPlayerInitBefore: Boolean;
begin
  if fNetPlayerKind = lpkJoiner then
  begin
    oldLoc := -1234; // some randor value, make compiler happy
    isPlayerInitBefore := MyIndex > 0;
    if isPlayerInitBefore then
      oldLoc := MyNetPlayer.StartLocation;

    aM.Read(fHostIndex);
    fNetPlayers.LoadFromStream(aM); //Our index could have changed on players add/removal
    fMyIndex := fNetPlayers.NicknameToLocal(fMyNickname);

    if Assigned(OnPlayersSetup) then OnPlayersSetup;

    if Assigned(OnUpdateMinimap)
    and ((isPlayerInitBefore
      and (oldLoc <> MyNetPlayer.StartLocation))
      or not isPlayerInitBefore) then
      OnUpdateMinimap;
  end;
end;


// Handle mkDisconnect message
procedure TKMNetworking.PlayerDisconnected(aSenderIndex: TKMNetHandleIndex; aLastSentCommandsTick: Integer);

  //Post local message about player disconnection
  procedure PostPlayerDisconnectedMsg(aPlayerIndex: Integer);
  var QuitMsgId: Integer;
  begin
    if IsPlayerHandStillInGame(aPlayerIndex) then
      QuitMsgId := IfThen(fHostIndex = aPlayerIndex, TX_MULTIPLAYER_HOST_DISCONNECTED_DEFEATED, TX_NET_HAS_QUIT_AND_DEFEATED)
    else
      QuitMsgId := IfThen(fHostIndex = aPlayerIndex, TX_MULTIPLAYER_HOST_DISCONNECTED, TX_NET_HAS_QUIT);
    PostLocalMessage(Format(gResTexts[QuitMsgId], [fNetPlayers[aPlayerIndex].NicknameColoredU]), csLeave);
  end;

var
  playerIndex: Integer;
begin
  playerIndex := fNetPlayers.ServerToLocal(aSenderIndex);
  gLog.AddTime(Format('PlayerDisconnected [netPlayer %d [%s] HandID %d]. LastSentCommandsTick = %d',
                      [playerIndex,
                       fNetPlayers[playerIndex].Nickname,
                       fNetPlayers[playerIndex].HandIndex,
                       aLastSentCommandsTick]));
  case fNetPlayerKind of
    lpkHost:   begin
                  fFileSenderManager.ClientDisconnected(aSenderIndex);
                  if playerIndex = -1 then Exit; //Has already disconnected

                  PostPlayerDisconnectedMsg(playerIndex);

                  if fNetGameState in [lgsGame] then
                  begin
                    if IsPlayerHandStillInGame(playerIndex) and Assigned(OnJoinerDropped) then
                      OnJoinerDropped(fNetPlayers[playerIndex].HandIndex);
                  end;

                  if fNetGameState in [lgsLoading, lgsGame] then
                    fNetPlayers.DropPlayer(aSenderIndex, aLastSentCommandsTick)
                  else
                    fNetPlayers.RemServerPlayer(aSenderIndex);
                  SendPlayerListAndRefreshPlayersSetup;
                  //Player leaving may cause vote to end
                  if (fNetGameState in [lgsLoading, lgsGame])
                  and (fNetPlayers.FurtherVotesNeededForMajority <= 0) then
                    ReturnToLobbyVoteSucceeded;
                end;
    lpkJoiner: begin
                  if playerIndex = -1 then exit; //Has already disconnected

                  PostPlayerDisconnectedMsg(playerIndex);

                  if fHostIndex = playerIndex then
                  begin
                    //Host has quit so drop them from the game
                    if fNetGameState in [lgsLoading, lgsGame] then
                      fNetPlayers.DropPlayer(aSenderIndex, aLastSentCommandsTick)
                    else
                      fNetPlayers.RemServerPlayer(aSenderIndex);
                  end;
                end;
  end;
end;


function TKMNetworking.CalculateGameCRC: Cardinal;
begin
  //CRC checks are done on the data we already loaded, not the files on HDD which can change.
  Result := gRes.GetDATCRC;

  //For debugging/testing it's useful to skip EXE check sometimes (but data files should always be checked)
  if not SKIP_EXE_CRC then
    Result := Result xor Adler32CRC(ParamStr(0));
end;


function TKMNetworking.CanTakeLocation(aPlayer, aLoc: Integer; AllowSwapping: Boolean): Boolean;
begin
  Result := True;
  if (aLoc <> LOC_SPECTATE) and (aLoc <> LOC_RANDOM) then
    case fSelectGameKind of
      ngkMap:  Result := (fMapInfo <> nil) and fMapInfo.IsValid and (aLoc <= fMapInfo.LocCount);
      ngkSave: Result := (fSaveInfo <> nil) and fSaveInfo.IsValid and (aLoc <= fSaveInfo.GameInfo.PlayerCount);
      ngkNone: Result := False;
    end;

  //If we are currently a spectator wanting to be a non-spectator, make sure there is a slot for us
  if fNetPlayers[aPlayer].IsSpectator and (aLoc <> LOC_SPECTATE) then
    Result := Result and (NetPlayers.Count-NetPlayers.GetSpectatorCount < MAX_LOBBY_PLAYERS);

  //Can't be a spectator if they are disabled
  if (aLoc = LOC_SPECTATE) and not fNetPlayers.SpectatorsAllowed then
    Result := False;

  //If we are trying to be a spectator and aren't one already, make sure there is an open spectator slot
  if (aLoc = LOC_SPECTATE) and not fNetPlayers[aPlayer].IsSpectator then
    Result := Result and ((NetPlayers.SpectatorSlotsOpen = MAX_LOBBY_SPECTATORS) //Means infinite spectators allowed
                          or (NetPlayers.SpectatorSlotsOpen-NetPlayers.GetSpectatorCount > 0));

  //Check with NetPlayers that the location isn't taken already, unless it's our current location
  //Host may be allowed to swap when HostDoesSetup is set, meaning it doesn't matter if loc is taken
  if (aLoc <> fNetPlayers[aPlayer].StartLocation) and not AllowSwapping then
    Result := Result and fNetPlayers.LocAvailable(aLoc);
end;


procedure TKMNetworking.GameCreated;
begin
  case fNetPlayerKind of
    lpkHost:   begin
                  MyNetPlayer.ReadyToPlay := True;
                  PacketSend(NET_ADDRESS_OTHERS, mkReadyToPlay);
                  SendPlayerListAndRefreshPlayersSetup; //Initialise the in-game player setup
                  //Check this here because it is possible to start a multiplayer game without other humans, just AI (at least for debugging)
                  TryPlayGame;
                end;
    lpkJoiner: begin
                  MyNetPlayer.ReadyToPlay := True;
                  PacketSend(NET_ADDRESS_OTHERS, mkReadyToPlay);
                end;
  end;
end;


//Get printable name of network address
function TKMNetworking.GetNetAddressPrintDescr(aNetworkAddress: Integer): String;

  function GetNetPlayerDescr: String;
  var NetPlayerIndex: Integer;
  begin
    NetPlayerIndex := fNetPlayers.ServerToLocal(aNetworkAddress);
    if NetPlayerIndex = -1 then
      Result := 'unknown'
    else
      Result := Format('%d | %s', [NetPlayerIndex, fNetPlayers[NetPlayerIndex].Nickname]);
  end;

begin
  case aNetworkAddress of
    NET_ADDRESS_EMPTY   : Result := 'EMPTY';
    NET_ADDRESS_OTHERS  : Result := 'OTHERS';
    NET_ADDRESS_ALL     : Result := 'ALL';
    NET_ADDRESS_HOST    : Result := 'HOST';
    NET_ADDRESS_SERVER  : Result := 'SERVER';
    else                  Result := Format('Client %d [NetPlayer %s]', [aNetworkAddress, GetNetPlayerDescr]);
  end;
end;


procedure TKMNetworking.LogPacket(aIsSending: Boolean; aKind: TKMessageKind; aNetworkAddress: TKMNetHandleIndex);
const
  LOGGED_PACKET_KINDS: set of TKMessageKind = [mkReadyToPlay,
                                               mkPlay,
                                               mkReconnectionAccepted,
                                               mkResyncFromTick,
                                               mkClientReconnected,
                                               mkRefuseReconnect,
                                               mkAskToReconnect,
                                               mkAskToSendCrashreport,
                                               mkStart,
                                               mkGiveHost,
                                               mkKicked,
                                               mkDisconnect,
                                               mkVote,
                                               mkReadyToReturnToLobby];
var
  logMessage: String;
begin
  if aIsSending then
    Inc(fPacketsSent[aKind])
  else
    Inc(fPacketsReceived[aKind]);

  if aIsSending then
    logMessage := 'Packet send:     %-23s to   %s'  // 23 is the length of mk_ command with the longest name
  else
    logMessage := 'Packet received: %-23s from %s';

  logMessage := Format(logMessage, [GetEnumName(TypeInfo(TKMessageKind), Integer(aKind)),
                                    GetNetAddressPrintDescr(aNetworkAddress)]);

  if aKind in LOGGED_PACKET_KINDS then
    gLog.AddTime(logMessage)
  else
    case aKind of
      mkPing, mkPong,
      mkPingInfo, mkFPS:  gLog.LogNetPacketPingFps(logMessage);
      mkCommands       :  gLog.LogNetPacketCommand(logMessage);
      else                gLog.LogNetPacketOther(logMessage);
    end;
end;


procedure TKMNetworking.PostLogMessageToChat(const aLogMessage: UnicodeString);
begin
  if Self = nil then Exit;

  if SHOW_LOG_IN_CHAT then
    PostLocalMessage(DeleteDoubleSpaces(aLogMessage), csNone);
end;


procedure TKMNetworking.PacketRecieve(aNetClient: TKMNetClient; aSenderIndex: TKMNetHandleIndex; aData: Pointer; aLength: Cardinal);
var
  I, locID, teamID, playerIndex: Integer;
  M, M2: TKMemoryStream;
  kind: TKMessageKind;
  err: UnicodeString;
  tmpInteger, tmpInteger2: Integer;
  tmpHandleIndex: TKMNetHandleIndex;
  tmpCardinal, tmpCardinal2: Cardinal;
  tmpStringA: AnsiString;
  tmpStringW, replyStringW: UnicodeString;
  tmpChatMode: TKMChatMode;
  chatSound: TKMChatSound;
begin
  Assert(aLength >= 1, 'Unexpectedly short message'); //Kind, Message
  if not Connected then Exit;

  M := TKMemoryStreamBinary.Create;
  try
    M.WriteBuffer(aData^, aLength);
    M.Position := 0;
    M.Read(kind, SizeOf(TKMessageKind)); //Depending on kind message contains either Text or a Number

    //Make sure we are allowed to receive this packet at this point
    if not (kind in NET_ALLOWED_PACKETS_SET[fNetGameState]) then
    begin
      //When querying or reconnecting to a host we may receive data such as commands, player setup, etc. These should be ignored.
      if not (fNetGameState in [lgsQuery, lgsReconnecting]) then
      begin
        err := 'Received a packet not intended for this state (' +
          GetEnumName(TypeInfo(TKMNetGameState), Integer(fNetGameState)) + '): ' +
          GetEnumName(TypeInfo(TKMessageKind), Integer(kind));
        //These warnings sometimes happen when returning to lobby, log them but don't show user
        gLog.AddTime(err);
        //PostLocalMessage('Error: ' + err, csSystem);
      end;
      Exit;
    end;

    LogPacket(False, kind, aSenderIndex);

    case kind of
      mkGameVersion:
              begin
                M.ReadA(tmpStringA);
                if tmpStringA <> NET_PROTOCOL_REVISON then
                begin
                  Assert(not IsHost);
                  OnJoinFail(Format(gResTexts[TX_MP_MENU_WRONG_VERSION], [NET_PROTOCOL_REVISON, tmpStringA]));
                  fNetClient.Disconnect;
                  Exit;
                end;
              end;

      mkWelcomeMessage:
              begin
                M.ReadW(tmpStringW);
                fWelcomeMessage := tmpStringW;
              end;

      mkServerName:
              begin
                M.ReadA(tmpStringA);
                fServerName := TKMNetworkUtils.GetEscapedNewLineServerNameA(tmpStringA);
              end;

      mkIndexOnServer:
              begin
                M.Read(tmpHandleIndex);
                fMyIndexOnServer := tmpHandleIndex;
                //PostLocalMessage('Index on Server - ' + inttostr(fMyIndexOnServer));
                //Now join the room we planned to
                M2 := TKMemoryStreamBinary.Create;
                WriteInfoToJoinRoom(M2);

                PacketSend(NET_ADDRESS_SERVER, mkJoinRoom, M2);
                M2.Free;
              end;

      mkConnectedToRoom:
              begin
                M.Read(tmpHandleIndex); //Host's index
                fNetGameFilter.Load(M);
                //See if the server assigned hosting rights to us
                if tmpHandleIndex = fMyIndexOnServer then
                begin
                  fNetPlayerKind := lpkHost;

                  // Enter the lobby if we had hosting rights assigned to us
                  if Assigned(OnJoinAssignedHost) then
                    OnJoinAssignedHost;

                  PostLocalMessage(gResTexts[TX_LOBBY_HOST_RIGHTS], csNone);
                end;

                //We are now clear to proceed with our business
                if fNetGameState = lgsReconnecting then
                begin
                  if IsHost then
                  begin
                    gLog.LogNetConnection('Hosting reconnection');
                    //The other players must have been disconnected too, so we will be the host now
                    SetGameState(lgsGame); //We are now in control of the game, so we are no longer reconnecting
                    //At this point we now know that every other client was dropped, but we probably missed the disconnect messages
                    fNetPlayers.DisconnectAllClients(fMyNickname); //Mark all human players as disconnected, except for self
                    //Set our new index on server
                    fNetPlayers[fNetPlayers.NicknameToLocal(fMyNickname)].SetIndexOnServer := fMyIndexOnServer;
                  end
                  else
                  begin
                    PacketSendA(NET_ADDRESS_HOST, mkAskToReconnect, fMyNickname);
                    fJoinTimeout := TimeGet; //Wait another X seconds for host to reply before timing out
                    gLog.LogNetConnection('Asking to reconnect');
                  end;
                end
                else
                  case fNetPlayerKind of
                    lpkHost:
                        begin
                          fNetPlayers.AddPlayer(fMyNickname, fMyIndexOnServer, gResLocales.UserLocale, LOBBY_HOST_AS_SPECTATOR);
                          fMyIndex := fNetPlayers.NicknameToLocal(fMyNickname);
                          fHostIndex := fMyIndex;
                          MyNetPlayer.ReadyToStart := True;
                          MyNetPlayer.HasMapOrSave := True;
                          if Assigned(OnPlayersSetup) then OnPlayersSetup;
                          SetGameState(lgsLobby);
                          gSoundPlayer.Play(sfxnMPChatSystem); //Sound for joining the lobby
                          if fWelcomeMessage <> '' then PostLocalMessage(fWelcomeMessage, csNone);
                        end;
                    lpkJoiner:
                    begin
                        SetGameState(lgsQuery);
                        fJoinTimeout := TimeGet; //Wait another X seconds for host to reply before timing out
                        M2 := TKMemoryStreamBinary.Create;
                        TKMNetSecurity.GenerateChallenge(M2, tmpHandleIndex);
                        PacketSend(NET_ADDRESS_HOST, mkAskForAuth, M2);
                        M2.Free;
                    end;
                  end;
              end;

      mkAskToReconnect:
              begin
                M.ReadA(tmpStringA);
                playerIndex := fNetPlayers.NicknameToLocal(tmpStringA);
                tmpInteger := fNetPlayers.CheckCanReconnect(playerIndex);
                if tmpInteger = -1 then
                begin
                  gLog.LogNetConnection(UnicodeString(tmpStringA) + ' successfully reconnected');
                  fNetPlayers[playerIndex].SetIndexOnServer := aSenderIndex; //They will have a new index
                  fNetPlayers[playerIndex].Connected := True; //This player is now back online
                  SendPlayerListAndRefreshPlayersSetup;
                  PacketSend(aSenderIndex, mkReconnectionAccepted); //Tell this client they are back in the game
                  PacketSendInd(NET_ADDRESS_OTHERS, mkClientReconnected, aSenderIndex); //Tell everyone to ask him to resync
                  PacketSend(aSenderIndex, mkResyncFromTick, Integer(fLastProcessedTick)); //Ask him to resync us
                  PostMessage(TX_NET_HAS_RECONNECTED, csJoin, fNetPlayers[playerIndex].NicknameColoredU);
                end
                else
                begin
                  gLog.LogNetConnection(UnicodeString(tmpStringA) + ' asked to reconnect: ' + IntToStr(tmpInteger));
                  PacketSend(aSenderIndex, mkRefuseReconnect, tmpInteger);
                end;
              end;

      mkRefuseReconnect:
              begin
                M.Read(tmpInteger);
                //If the result is < 1 is means silently ignore and keep retrying
                if tmpInteger > 0 then
                  PostLocalMessage(Format(gResTexts[TX_NET_RECONNECTION_FAILED], [gResTexts[tmpInteger]]), csSystem);
                if Assigned(OnJoinFail) then
                  OnJoinFail('');
              end;

      mkAskToJoin:
              if IsHost then
              begin
                if not TKMNetSecurity.ValidateSolution(M, aSenderIndex) then
                  tmpInteger := TX_NET_YOUR_DATA_FILES
                else
                begin
                  M.ReadA(tmpStringA);
                  tmpInteger := fNetPlayers.CheckCanJoin(tmpStringA, aSenderIndex);
                  if (tmpInteger = -1) and (fNetGameState <> lgsLobby) then
                    tmpInteger := TX_NET_GAME_IN_PROGRESS;
                end;
                if tmpInteger = -1 then
                begin
                  //Password was checked by server already
                  PlayerJoined(aSenderIndex, tmpStringA);
                end
                else
                begin
                  PacketSend(aSenderIndex, mkRefuseToJoin, tmpInteger);
                  //Force them to reconnect and ask for a new challenge
                  PacketSendInd(NET_ADDRESS_SERVER, mkKickPlayer, aSenderIndex);
                end;
              end;

      mkFileRequest: FileRequestReceived(aSenderIndex, M);
              

      mkFileChunk:
              if not IsHost and (fFileReceiver <> nil) then
              begin
                if SLOW_MAP_SAVE_LOAD then
                  Sleep(50);
                  
                fFileReceiver.DataReceived(M);
                PacketSend(aSenderIndex, mkFileAck);
                M2 := TKMemoryStreamBinary.Create;
                M2.Write(fFileReceiver.TotalSize);
                M2.Write(fFileReceiver.ReceivedSize);
                PacketSend(NET_ADDRESS_OTHERS, mkFileProgress, M2);
                M2.Free;
                if Assigned(OnFileTransferProgress) then
                  OnFileTransferProgress(fFileReceiver.TotalSize, fFileReceiver.ReceivedSize);
              end;

      mkFileAck:
              if IsHost then
                fFileSenderManager.AckReceived(aSenderIndex);

      mkFileEnd:
              if not IsHost and (fFileReceiver <> nil) then
              begin
                fFileReceiver.ProcessTransfer;
                FreeAndNil(fFileReceiver);
                SetDownloadlInProgress(aSenderIndex, False);
              end;

      mkFileProgress:
              if Assigned(OnPlayerFileTransferProgress) then
              begin
                M.Read(tmpCardinal);
                M.Read(tmpCardinal2);
                playerIndex := fNetPlayers.ServerToLocal(aSenderIndex);
                if (playerIndex <> -1) and fNetPlayers[playerIndex].DownloadInProgress then
                  OnPlayerFileTransferProgress(playerIndex, tmpCardinal, tmpCardinal2);
              end;

      mkFileSendStarted:
              if not IsHost then //Host will mark NetPlayers before file send
              begin
                M.Read(tmpCardinal);
                SetDownloadlInProgress(tmpCardinal, True);
              end;

      mkLangCode:
              begin
                M.ReadA(tmpStringA);
                playerIndex := fNetPlayers.ServerToLocal(aSenderIndex);
                if playerIndex <> -1 then
                  fNetPlayers[playerIndex].LangCode := tmpStringA;
                SendPlayerListAndRefreshPlayersSetup;
              end;

      mkAllowToJoin:
              if fNetPlayerKind = lpkJoiner then
              begin
                OnJoinSucc; // Enter lobby
                SetGameState(lgsLobby);
                //No need to play a sound here, host will send "<player> has joined" message
                if fWelcomeMessage <> '' then PostLocalMessage(fWelcomeMessage, csNone);
                PacketSendA(NET_ADDRESS_HOST, mkLangCode, gResLocales.UserLocale);
              end;

      mkRefuseToJoin:
              if fNetPlayerKind = lpkJoiner then
              begin
                M.Read(tmpInteger);
                fNetClient.Disconnect;
                OnJoinFail(gResTexts[tmpInteger]);
              end;

      mkReqPassword:
              begin
                fEnteringPassword := True; //Disables timing out
                OnJoinPassword;
              end;

      mkAskForAuth:
              if IsHost then
              begin
                //We should refuse the joiner immediately if we are not in the lobby
                if fNetGameState <> lgsLobby then
                  PacketSend(aSenderIndex, mkRefuseToJoin, TX_NET_GAME_IN_PROGRESS)
                else
                begin
                  //Solve joiner's challenge
                  M2 := TKMemoryStreamBinary(TKMNetSecurity.SolveChallenge(M, aSenderIndex));
                  //Send our own challenge
                  TKMNetSecurity.GenerateChallenge(M2, aSenderIndex);
                  PacketSend(aSenderIndex, mkAuthChallenge, M2);
                  M2.Free;
                end;
              end;

      mkAuthChallenge:
              begin
                //Validate solution the host sent back to us
                if TKMNetSecurity.ValidateSolution(M, aSenderIndex) then
                begin
                  //Solve host's challenge and ask to join
                  M2 := TKMemoryStreamBinary(TKMNetSecurity.SolveChallenge(M, aSenderIndex));
                  M2.WriteA(fMyNickname);
                  PacketSend(NET_ADDRESS_HOST, mkAskToJoin, M2);
                  M2.Free;
                end
                else
                  OnJoinFail(gResTexts[TX_NET_YOUR_DATA_FILES]);
              end;

      mkKicked:
              begin
                M.Read(tmpInteger);
                OnDisconnect(gResTexts[tmpInteger]);
              end;

      mkClientLost:
              begin
                M.Read(tmpHandleIndex);
                if IsHost then
                begin
                  fFileSenderManager.ClientDisconnected(tmpHandleIndex);
                  playerIndex := fNetPlayers.ServerToLocal(tmpHandleIndex);
                  if playerIndex = -1 then exit; //Has already disconnected or not from our room
                  if not fNetPlayers[playerIndex].Dropped then
                  begin
                    PostMessage(TX_NET_LOST_CONNECTION, csLeave, fNetPlayers[playerIndex].NicknameColoredU);
                    gLog.LogNetConnection(fNetPlayers[playerIndex].NicknameU + ' lost connection');
                  end;
                  if fNetGameState = lgsGame then
                    fNetPlayers.DisconnectPlayer(tmpHandleIndex)
                  else
                    if fNetGameState = lgsLoading then
                    begin
                      fNetPlayers.DropPlayer(tmpHandleIndex);
                      TryPlayGame;
                    end
                    else
                      fNetPlayers.RemServerPlayer(tmpHandleIndex);
                  SendPlayerListAndRefreshPlayersSetup;
                end
                else
                  if fNetPlayers.ServerToLocal(tmpHandleIndex) <> -1 then
                  begin
                    if fNetGameState = lgsGame then
                      fNetPlayers.DisconnectPlayer(tmpHandleIndex)
                    else
                      if fNetGameState = lgsLoading then
                        fNetPlayers.DropPlayer(tmpHandleIndex)
                      else
                        fNetPlayers.RemServerPlayer(tmpHandleIndex); //Remove the player anyway as it might be the host that was lost
                  end;
              end;

      mkDisconnect:   begin
                        M.Read(tmpInteger);
                        PlayerDisconnected(aSenderIndex, tmpInteger);
                      end;

      mkReassignHost: ReassignHost(aSenderIndex, M);

      mkPing:  PacketSend(aSenderIndex, mkPong);//, Integer(fMyPlayerCurrentFPS)); //Server will intercept this message

      mkPingInfo:
              begin
                DecodePingInfo(M);
                if Assigned(OnPingInfo) then OnPingInfo;
              end;

//      mkFPS:
//              begin
//                M.Read(tmpInteger);
//                PlayerIndex := fNetPlayers.ServerToLocal(aSenderIndex);
//                if PlayerIndex = -1 then Exit;
//                fNetPlayers[PlayerIndex].FPS := Cardinal(tmpInteger);
//                if Assigned(OnPingInfo) then OnPingInfo;
//              end;

      mkPlayersList: PlayersListReceived(M);

      mkGameOptions:
              if fNetPlayerKind = lpkJoiner then
              begin
                fNetGameOptions.Load(M);
                if Assigned(OnGameOptions) then OnGameOptions;
              end;

      mkResetMap:
              begin
                FreeAndNil(fFileReceiver); //Any ongoing transfer is cancelled
                fSelectGameKind := ngkNone;
                FreeAndNil(fMapInfo);
                FreeAndNil(fSaveInfo);
                if Assigned(OnMapName) then OnMapName('');
              end;

      mkMapSelect:
              if fNetPlayerKind = lpkJoiner then
              begin
                FreeAndNil(fFileReceiver); //Any ongoing transfer is cancelled
                M.ReadW(tmpStringW); //Map name
                M.Read(tmpCardinal); //CRC
                //Try to load map from MP or DL folder
                FreeAndNil(fMapInfo);
                fMapInfo := TKMMapInfo.Create(tmpStringW, True, mkMP);
                if not fMapInfo.IsValid or (fMapInfo.CRC <> tmpCardinal) then
                begin
                  //Append CRC to map name
                  tmpStringW := tmpStringW + '_' + IntToHex(Integer(tmpCardinal), 8);
                  fMapInfo := TKMMapInfo.Create(tmpStringW, True, mkDL);
                  if not fMapInfo.IsValid or (fMapInfo.CRC <> tmpCardinal) then
                    FreeAndNil(fMapInfo);
                end;

                if fMapInfo <> nil then
                begin
                  fSelectGameKind := ngkMap;
                  fMapInfo.LoadExtra; //Lobby requires extra map info such as CanBeHuman
                  if Assigned(OnMapName) then OnMapName(fMapInfo.Name);
                  PacketSend(NET_ADDRESS_HOST, mkHasMapOrSave);
                end
                else
                begin
                  fMissingFileType := ngkMap;
                  fMissingFileName := tmpStringW;
                  fMissingFileCRC := tmpCardinal;
                  fSelectGameKind := ngkNone;
                  if Assigned(OnMapName) then OnMapName(tmpStringW);
                  if Assigned(OnMapMissing) then OnMapMissing(tmpStringW, False);
                end;
                if Assigned(OnPlayersSetup) then OnPlayersSetup;
              end;

      mkSaveSelect:
              if fNetPlayerKind = lpkJoiner then
              begin
                FreeAndNil(fFileReceiver); //Any ongoing transfer is cancelled
                M.ReadW(tmpStringW); //Save name
                M.Read(tmpCardinal); //CRC

                //See if we already have the save file the host selected
                FreeAndNil(fSaveInfo);
                fSaveInfo := TKMSaveInfo.Create(tmpStringW, True);

                gLog.AddTime(Format('mk_SaveSelect: fSaveInfo.CRC = %d, tmpCRC = %d', [fSaveInfo.CRC, tmpCardinal]));
                if not fSaveInfo.IsValid or (fSaveInfo.CRC <> tmpCardinal) then
                begin
                  if fReturnedToLobby and (tmpStringW = RETURN_TO_LOBBY_SAVE) then
                  begin
                    //Host paused file doesn't match ours, host may be cheating!
                    PostLocalMessage(gResTexts[TX_PAUSED_FILE_MISMATCH], csSystem);
                    gLog.AddTime(Format('Save error: %s. Check params: fSaveInfo.IsValid = %s; (fSaveInfo.CRC <> tmpCRC) = ;' +
                                        ' Save FileExists %s: %s; fSaveError = %s; fInfo.IsValid(True) = %s',
                                        [gResTexts[TX_PAUSED_FILE_MISMATCH], BoolToStr(fSaveInfo.IsValid),
                                         BoolToStr(fSaveInfo.CRC <> tmpCardinal), fSaveInfo.Path + fSaveInfo.FileName + EXT_SAVE_MAIN_DOT,
                                         BoolToStr(FileExists(fSaveInfo.Path + fSaveInfo.FileName + EXT_SAVE_MAIN_DOT)),
                                         fSaveInfo.SaveError.ErrorString, fSaveInfo.GameInfo.IsValid(True)]));
                    fSelectGameKind := ngkNone;
                    FreeAndNil(fSaveInfo);
                    if Assigned(OnMapName) then OnMapName('');
                    Exit;
                  end;
                  //See if the host selected the same save we already downloaded
                  FreeAndNil(fSaveInfo);
                  fSaveInfo := TKMSaveInfo.Create(DOWNLOADED_LOBBY_SAVE, True);
                end;

                if fSaveInfo.IsValid and (fSaveInfo.CRC = tmpCardinal) then
                begin
                  fSelectGameKind := ngkSave;
                  if Assigned(OnMapName) then OnMapName(tmpStringW);
                  if Assigned(OnPlayersSetup) then OnPlayersSetup;
                  PacketSend(NET_ADDRESS_HOST, mkHasMapOrSave);
                end
                else
                begin
                  FreeAndNil(fSaveInfo);
                  fSelectGameKind := ngkNone;
                  //Save file does not exist, so downloaded it
                  fMissingFileType := ngkSave;
                  fMissingFileName := tmpStringW;
                  if Assigned(OnMapMissing) then OnMapMissing(tmpStringW, False);
                end;
              end;

      mkStartingLocQuery:
              if IsHost and not fNetPlayers.HostDoesSetup then
              begin
                M.Read(tmpInteger);
                locID := tmpInteger;
                playerIndex := fNetPlayers.ServerToLocal(aSenderIndex);
                if CanTakeLocation(playerIndex, locID, False) then
                begin //Update Players setup
                  fNetPlayers[playerIndex].StartLocation := locID;
                  //Spectators can't have team
                  if locID = LOC_SPECTATE then
                    fNetPlayers[playerIndex].Team := 0;
                  SendPlayerListAndRefreshPlayersSetup;
                end
                else //Quietly refuse
                  SendPlayerListAndRefreshPlayersSetup(aSenderIndex);
              end;

      mkSetTeam:
              if IsHost and not fNetPlayers.HostDoesSetup then
              begin
                M.Read(tmpInteger);
                teamID := tmpInteger;
                //Update Players setup
                fNetPlayers[fNetPlayers.ServerToLocal(aSenderIndex)].Team := teamID;
                SendPlayerListAndRefreshPlayersSetup;
              end;

      mkFlagColorQuery:
              if IsHost then
              begin
                M.Read(tmpCardinal);
                //The player list could have changed since the joiner sent this request (over slow connection)
                if fNetPlayers.ColorAvailable(tmpCardinal)
                and ((fSelectGameKind <> ngkSave) or not SaveInfo.IsValid or not SaveInfo.GameInfo.ColorUsed(tmpCardinal)) then
                begin
                  fNetPlayers[fNetPlayers.ServerToLocal(aSenderIndex)].FlagColor := tmpCardinal;
                  SendPlayerListAndRefreshPlayersSetup;
                end
                else //Quietly refuse
                  SendPlayerListAndRefreshPlayersSetup(aSenderIndex);
              end;

      mkReadyToStart:
              if IsHost then
              begin
                playerIndex := fNetPlayers.ServerToLocal(aSenderIndex);
                fNetPlayers[playerIndex].ReadyToStart := not fNetPlayers[playerIndex].ReadyToStart;
                SendPlayerListAndRefreshPlayersSetup;
              end;

      mkHasMapOrSave:
              if IsHost then
              begin
                playerIndex := fNetPlayers.ServerToLocal(aSenderIndex);
                fNetPlayers[playerIndex].HasMapOrSave := True;
                SendPlayerListAndRefreshPlayersSetup;
              end;

      mkStart:
              if fNetPlayerKind = lpkJoiner then
              begin
                M.Read(fHostIndex);
                fNetPlayers.LoadFromStream(M);
                fMyIndex := fNetPlayers.NicknameToLocal(fMyNickname);
                StartGame;
              end;

      mkSetPassword:
              if not IsHost then //Save password for joiner's only, as it's used to show Lock image
              begin
                M.ReadA(tmpStringA); //Password
                fPassword := tmpStringA;
                if Assigned(OnSetPassword) then
                  OnSetPassword(fPassword);
              end;

      mkReadyToReturnToLobby:
              begin
                fNetPlayers[fNetPlayers.ServerToLocal(aSenderIndex)].ReadyToReturnToLobby := True;
                if fNetPlayers.AllReadyToReturnToLobby then
                begin
                  ResetReturnToLobbyVote;   //So it's reset for next time
                  OnDoReturnToLobby;
                end;
              end;

      mkReadyToPlay:
              begin
                fNetPlayers[fNetPlayers.ServerToLocal(aSenderIndex)].ReadyToPlay := True;
                if Assigned(OnReadyToPlay) then OnReadyToPlay;
                if IsHost then TryPlayGame;
              end;

      mkPlay:
              if fNetPlayerKind = lpkJoiner then PlayGame;

      mkCommands:
              begin
                playerIndex := fNetPlayers.ServerToLocal(aSenderIndex);
                if (playerIndex<>-1) and not fNetPlayers[playerIndex].Dropped then
                  if Assigned(OnCommands) then OnCommands(M, playerIndex);
              end;
      mkAskToSendCrashreport:
              begin
                // We were asked to send crashreport. Raise new Exception then
                M.ReadW(tmpStringW);
                gLog.AddTime('Received mkAskToSendCrashreport with player error msg: ' + tmpStringW);
                raise Exception.Create(Format(gResTexts[TX_ERROR_ASK_TO_SEND_RNGCHECK_REPORT], [#13#10#13#10, tmpStringW]));
              end;

      mkResyncFromTick:
              begin
                M.Read(tmpInteger);
                gLog.LogNetConnection('Asked to resync from tick ' + IntToStr(tmpInteger));
                playerIndex := fNetPlayers.ServerToLocal(aSenderIndex);
                if Assigned(OnResyncFromTick) and (playerIndex<>-1) then
                begin
                  gLog.LogNetConnection('Resyncing player ' + fNetPlayers[playerIndex].NicknameU);
                  OnResyncFromTick(playerIndex, Cardinal(tmpInteger));
                end;
              end;

      mkReconnectionAccepted:
              begin
                //The host has accepted us back into the game!
                gLog.LogNetConnection('Reconnection Accepted');
                SetGameState(lgsGame); //Game is now running once again
                fReconnectRequested := 0; //Cancel any retry in progress
                //Request all other clients to resync us
                PacketSend(NET_ADDRESS_OTHERS, mkResyncFromTick, Integer(fLastProcessedTick));
              end;

      mkClientReconnected:
              begin
                M.Read(tmpHandleIndex);
                //The host has accepted a disconnected client back into the game. Request this client to resync us
                if tmpHandleIndex = fMyIndexOnServer then exit;
                gLog.LogNetConnection('Requesting resync for reconnected client');
                PacketSend(tmpHandleIndex, mkResyncFromTick, Integer(fLastProcessedTick));
              end;

      mkVote:
              begin
                playerIndex := fNetPlayers.ServerToLocal(aSenderIndex);

                if not fVoteReturnToLobbySucceeded  // Do not allow late mkVote after we received enough votes (if it comes while still in game and receiveing mk_readyToReturnToLobby)
                  and not fNetPlayers[playerIndex].VotedYes //No need to vote more than once
                  and (fNetPlayers.HasOnlySpectators or not fNetPlayers[playerIndex].IsSpectator) //spectators don't get to vote unless there's only spectators left
                  then
                begin
                  fLastVoteTime := TimeGet;
                  fNetPlayers[playerIndex].VotedYes := True;
                  fNetPlayers.VoteActive := True;
                  if fNetPlayers.FurtherVotesNeededForMajority <= 0 then
                  begin
                    PostMessage(TX_NET_VOTE_PASSED, csSystem, fNetPlayers[playerIndex].NicknameColoredU);
                    ReturnToLobbyVoteSucceeded;
                  end
                  else
                  begin
                    PostMessage(TX_NET_VOTED, csSystem, fNetPlayers[playerIndex].NicknameColoredU, IntToStr(fNetPlayers.FurtherVotesNeededForMajority));
                    SendPlayerListAndRefreshPlayersSetup;
                  end;
                end;
              end;

      mkTextTranslated:
              begin
                M.Read(tmpInteger);
                M.Read(chatSound, SizeOf(chatSound));
                M.ReadW(tmpStringW);
                M.ReadW(replyStringW);
                M.Read(tmpInteger2);
                if tmpInteger2 = -1 then
                  PostLocalMessage(Format(gResTexts[tmpInteger], [tmpStringW, replyStringW]), chatSound)
                else
                  PostLocalMessage(Format(gResTexts[tmpInteger], [gResTexts[tmpInteger2]]), chatSound)
              end;

      mkTextChat:
              begin
                M.Read(tmpChatMode, SizeOf(tmpChatMode));
                M.Read(tmpHandleIndex);
                M.ReadW(tmpStringW);

                case tmpChatMode of
                  cmTeam:
                    begin
                      tmpStringW := ' [$66FF66]('+gResTexts[TX_CHAT_TEAM]+')[]: ' + tmpStringW;
                      chatSound := csChatTeam;
                    end;

                  cmSpectators:
                    begin
                      tmpStringW := ' [$66FF66]('+gResTexts[TX_CHAT_SPECTATORS]+')[]: ' + tmpStringW;
                      chatSound := csChatTeam;
                    end;

                  cmWhisper:
                    begin
                      chatSound := csChatWhisper;
                      I := NetPlayers.ServerToLocal(tmpHandleIndex);
                      if I <> -1 then
                        //we want to show colored nickname, so prepare nickname string
                        tmpStringA := '[]' + NetPlayers[I].NicknameColored + '[$00B9FF]'
                      else
                        tmpStringA := '';
                      tmpStringW := ' [$00B9FF](' + Format(gResTexts[TX_CHAT_WHISPER_TO], [UnicodeString(tmpStringA)]) + ')[]: ' + tmpStringW;
                    end;

                  cmAll:
                    begin
                      tmpStringW := ' ('+gResTexts[TX_CHAT_ALL]+'): ' + tmpStringW;
                      chatSound := csChat;
                    end;
                end;

                playerIndex := fNetPlayers.ServerToLocal(aSenderIndex);
                if (playerIndex <> -1) then
                begin
                  if not IsMuted(playerIndex) then
                  begin
                    if NetPlayers[playerIndex].IsColorSet then
                      tmpStringW := WrapColor(NetPlayers[playerIndex].NicknameU, FlagColorToTextColor(NetPlayers[playerIndex].FlagColor)) + tmpStringW
                    else
                      tmpStringW := NetPlayers[playerIndex].NicknameU + tmpStringW;
                    PostLocalMessage(tmpStringW, chatSound);
                  end
                  else
                  if tmpChatMode = cmWhisper then
                    // Notify sender, when he is muted
                    PostMessage(TX_NET_MUTED, csSystem, MyNetPlayer.NicknameColoredU, '', aSenderIndex);
                end;
              end;
    end;

  finally
    M.Free;
  end;
end;


//MessageKind.Data(depends on Kind)
procedure TKMNetworking.PacketSend(aRecipient: TKMNetHandleIndex; aKind: TKMessageKind);
var
  M: TKMemoryStream;
begin
  Assert(NetPacketType[aKind] = pfNoData);

  LogPacket(True, aKind, aRecipient);

  M := TKMemoryStreamBinary.Create;
  M.Write(aKind, SizeOf(TKMessageKind));

  fNetClient.SendData(fMyIndexOnServer, aRecipient, M.Memory, M.Size);
  M.Free;
end;


procedure TKMNetworking.PacketSend(aRecipient: TKMNetHandleIndex; aKind: TKMessageKind; aStream: TKMemoryStream);
var
  M: TKMemoryStream;
begin
  Assert(NetPacketType[aKind] = pfBinary);

  LogPacket(True, aKind, aRecipient);

  M := TKMemoryStreamBinary.Create;
  M.Write(aKind, SizeOf(TKMessageKind));

  aStream.Position := 0;
  M.CopyFrom(aStream, aStream.Size);

  fNetClient.SendData(fMyIndexOnServer, aRecipient, M.Memory, M.Size);
  M.Free;
end;


procedure TKMNetworking.PacketSend(aRecipient: TKMNetHandleIndex; aKind: TKMessageKind; aParam: Cardinal);
var
  M: TKMemoryStream;
begin
  Assert(NetPacketType[aKind] = pfNumber);

  LogPacket(True, aKind, aRecipient);

  M := TKMemoryStreamBinary.Create;
  M.Write(aKind, SizeOf(TKMessageKind));

  M.Write(aParam);

  fNetClient.SendData(fMyIndexOnServer, aRecipient, M.Memory, M.Size);
  M.Free;
end;


procedure TKMNetworking.PacketSend(aRecipient: TKMNetHandleIndex; aKind: TKMessageKind; aParam: Integer);
var
  M: TKMemoryStream;
begin
  Assert(NetPacketType[aKind] = pfNumber);

  LogPacket(True, aKind, aRecipient);

  M := TKMemoryStreamBinary.Create;
  M.Write(aKind, SizeOf(TKMessageKind));

  M.Write(aParam);

  fNetClient.SendData(fMyIndexOnServer, aRecipient, M.Memory, M.Size);
  M.Free;
end;


//procedure TKMNetworking.PacketSend(aRecipient: TKMNetHandleIndex; aKind: TKMessageKind; const aParams: array of Integer);
//var
//  I: Integer;
//  M: TKMemoryStream;
//begin
//  Assert(NetPacketType[aKind] = pfBinary); //Several numbers are considered as binary
//
//  LogPacket(True, aKind, aRecipient);
//
//  M := TKMemoryStreamBinary.Create;
//  M.Write(aKind, SizeOf(TKMessageKind));
//
//  for I := 0 to Length(aParams) - 1 do
//    M.Write(aParams[I]);
//
//  fNetClient.SendData(fMyIndexOnServer, aRecipient, M.Memory, M.Size);
//  M.Free;
//end;


procedure TKMNetworking.PacketSendInd(aRecipient: TKMNetHandleIndex; aKind: TKMessageKind; aIndexOnServer: TKMNetHandleIndex);
var
  M: TKMemoryStream;
begin
  Assert(NetPacketType[aKind] = pfNumber);

  LogPacket(True, aKind, aRecipient);

  M := TKMemoryStreamBinary.Create;
  M.Write(aKind, SizeOf(TKMessageKind));

  M.Write(aIndexOnServer);

  fNetClient.SendData(fMyIndexOnServer, aRecipient, M.Memory, M.Size);
  M.Free;
end;


procedure TKMNetworking.PacketSendA(aRecipient: TKMNetHandleIndex; aKind: TKMessageKind; const aText: AnsiString);
var
  M: TKMemoryStream;
begin
  Assert(NetPacketType[aKind] = pfStringA);

  LogPacket(True, aKind, aRecipient);

  M := TKMemoryStreamBinary.Create;
  M.Write(aKind, SizeOf(TKMessageKind));

  M.WriteA(aText);

  fNetClient.SendData(fMyIndexOnServer, aRecipient, M.Memory, M.Size);
  M.Free;
end;


procedure TKMNetworking.PacketSendW(aRecipient: TKMNetHandleIndex; aKind: TKMessageKind; const aText: UnicodeString);
var
  M: TKMemoryStream;
begin
  Assert(NetPacketType[aKind] = pfStringW);

  LogPacket(True, aKind, aRecipient);

  M := TKMemoryStreamBinary.Create;
  M.Write(aKind, SizeOf(TKMessageKind));

  M.WriteW(aText);

  fNetClient.SendData(fMyIndexOnServer, aRecipient, M.Memory, M.Size);
  M.Free;
end;


procedure TKMNetworking.StartGame;
begin
  PostLocalMessage(gResTexts[TX_LOBBY_GAME_STARTED], csGameStart);
  SetGameState(lgsLoading); //Loading has begun (no further players allowed to join)
  fIgnorePings := -1; //Ignore all pings until we have finished loading

  case fSelectGameKind of
    ngkMap:  OnStartMap(fMapInfo.FileNameWithoutHash, fMapInfo.Kind, fMapInfo.CRC, MyNetPlayer.IsSpectator,
                         fNetGameOptions.MissionDifficulty);
    ngkSave: OnStartSave(fSaveInfo.FileName, MyNetPlayer.IsSpectator);
  else
    raise Exception.Create('Unexpected fSelectGameKind');
  end;
end;


procedure TKMNetworking.TryPlayGame;
begin
  if fNetPlayers.AllReadyToPlay then
  begin
    PacketSend(NET_ADDRESS_OTHERS, mkPlay);
    PlayGame;
  end;
end;


procedure TKMNetworking.PlayGame;
begin
  fIgnorePings := 5; //Ignore the next few pings as they will have been measured during loading
  SetGameState(lgsGame); //The game has begun (no further players allowed to join)
  if Assigned(OnPlay) then OnPlay;
end;


procedure TKMNetworking.SetDescription(const Value: UnicodeString);
begin
  Assert(IsHost, 'Only host can set description');
  fDescription := Value;
  OnMPGameInfoChanged; //Send the description to the server so it is shown in room info
end;


// Return if specified NetPlayer is muted locally
function TKMNetworking.IsMuted(aNetPlayerIndex: Integer): Boolean;
begin
  Result := (aNetPlayerIndex <> -1) and (fMutedPlayersList.IndexOf(fNetPlayers[aNetPlayerIndex].IndexOnServer) <> -1);
end;


function TKMNetworking.IsSave: Boolean;
begin
  Result := SelectGameKind = ngkSave;
end;


function TKMNetworking.IsMap: Boolean;
begin
  Result := SelectGameKind = ngkMap;
end;


// Toggle mute status of specified NetPlayer
procedure TKMNetworking.ToggleMuted(aNetPlayerIndex: Integer);
var
  listIndex: Integer;
begin
  if gLog.IsDegubLogEnabled then
    gLog.LogDebug(Format('TKMNetworking.ToggleMuted: IndexOnServer for NetPlayer %d [%s] = %d',
                         [aNetPlayerIndex, fNetPlayers[aNetPlayerIndex].Nickname, fNetPlayers[aNetPlayerIndex].IndexOnServer]));
  listIndex := fMutedPlayersList.IndexOf(fNetPlayers[aNetPlayerIndex].IndexOnServer);
  if listIndex <> -1 then
    fMutedPlayersList.Delete(listIndex)
  else
    fMutedPlayersList.Add(fNetPlayers[aNetPlayerIndex].IndexOnServer);
end;


procedure TKMNetworking.SetGameState(aState: TKMNetGameState; aOnMPInfoChanged: Boolean = True);
begin
  gLog.AddTime(Format('SetGameState from %s to %s', [GetEnumName(TypeInfo(TKMNetGameState), Integer(fNetGameState)),
                                                     GetEnumName(TypeInfo(TKMNetGameState), Integer(aState))]));
  fNetGameState := aState;
  if aOnMPInfoChanged and (fNetGameState in [lgsLobby,lgsLoading,lgsGame]) and IsHost and (fMyIndexOnServer <> -1) then
    OnMPGameInfoChanged;
end;


//Tell the server what we know about the game
procedure TKMNetworking.AnnounceGameInfo(aGameTime: TDateTime; aMap: UnicodeString);
var
  I: Integer;
  M: TKMemoryStream;
  MPGameInfo: TKMPGameInfo;
begin
  //Only one player per game should send the info - Host
  if not IsHost then Exit;

  MPGameInfo := TKMPGameInfo.Create;
  try
    if (fNetGameState in [lgsLobby, lgsLoading]) then
    begin
      case fSelectGameKind of
        ngkSave: aMap := fSaveInfo.GameInfo.Title;
        ngkMap:  aMap := fMapInfo.Name;
        else     aMap := '';
      end;
      aGameTime := -1;
    end;
    MPGameInfo.Description := fDescription;
    MPGameInfo.Map := aMap;
    MPGameInfo.GameTime := aGameTime;
    MPGameInfo.GameState := NET_MP_GAME_STATE[fNetGameState];
    MPGameInfo.PasswordLocked := (fPassword <> '');
    MPGameInfo.PlayerCount := NetPlayers.Count;

    MPGameInfo.GameOptions.Peacetime := fNetGameOptions.Peacetime;
    MPGameInfo.GameOptions.SpeedPT := fNetGameOptions.SpeedPT;
    MPGameInfo.GameOptions.SpeedAfterPT := fNetGameOptions.SpeedAfterPT;
    MPGameInfo.GameOptions.RandomSeed := fNetGameOptions.RandomSeed; //not needed, but we send it anyway
    MPGameInfo.GameOptions.MissionDifficulty := fNetGameOptions.MissionDifficulty;

    for I := 1 to NetPlayers.Count do
    begin
      MPGameInfo.Players[I].Name        := NetPlayers[I].Nickname;
      MPGameInfo.Players[I].Color       := NetPlayers[I].FlagColorDef;
      MPGameInfo.Players[I].Connected   := NetPlayers[I].Connected;
      MPGameInfo.Players[I].LangCode    := NetPlayers[I].LangCode;
      MPGameInfo.Players[I].Team        := NetPlayers[I].Team;
      MPGameInfo.Players[I].IsSpectator := NetPlayers[I].IsSpectator;
      MPGameInfo.Players[I].IsHost      := HostIndex = I;
      MPGameInfo.Players[I].PlayerType  := NetPlayers[I].PlayerNetType;
      if (gHands = nil) //Game is not loaded yet...
        or MPGameInfo.Players[I].IsSpectator
        or (NetPlayers[I].HandIndex = -1) then
        MPGameInfo.Players[I].WonOrLost := wolNone
      else
        MPGameInfo.Players[I].WonOrLost := gHands[NetPlayers[I].HandIndex].AI.WonOrLost;
    end;

    M := TKMemoryStreamBinary.Create;
    MPGameInfo.SaveToStream(M);
    PacketSend(NET_ADDRESS_SERVER, mkSetGameInfo, M);
    M.Free;
  finally
    MPGameInfo.Free;
  end;
end;


procedure TKMNetworking.TransferOnCompleted(aClientIndex: TKMNetHandleIndex);
begin
  PacketSend(aClientIndex, mkFileEnd);
  SendMapOrSave(aClientIndex);
  SendPlayerListAndRefreshPlayersSetup(aClientIndex);
end;


procedure TKMNetworking.TransferOnPacket(aClientIndex: TKMNetHandleIndex; aStream: TKMemoryStream; out SendBufferEmpty: Boolean);
begin
  PacketSend(aClientIndex, mkFileChunk, aStream);
  SendBufferEmpty := fNetClient.SendBufferEmpty;
end;


procedure TKMNetworking.UpdateState(aGlobalTickCount: cardinal);
begin
  // Reconnection delay
  if (fReconnectRequested <> 0) and (TimeSince(fReconnectRequested) > RECONNECT_PAUSE) then DoReconnection;

  // Joining timeout
  if fNetGameState in [lgsConnecting,lgsReconnecting,lgsQuery] then
    if (TimeSince(fJoinTimeout) > JOIN_TIMEOUT) and not fEnteringPassword
    and (fReconnectRequested = 0) then
      if Assigned(OnJoinFail) then
        OnJoinFail(gResTexts[TX_NET_QUERY_TIMED_OUT]);

  // Vote expiring
  if (fNetGameState in [lgsLoading, lgsGame]) and IsHost
  and fNetPlayers.VoteActive and (TimeSince(fLastVoteTime) > VOTE_TIMEOUT) then
  begin
    PostMessage(TX_NET_VOTE_FAILED, csSystem);
    fNetPlayers.ResetVote;
    SendPlayerListAndRefreshPlayersSetup;
  end;
end;


procedure TKMNetworking.UpdateStateIdle;
begin
  fNetServer.UpdateState; //Server measures pings etc.
  //LNet requires network update calls unless it is being used as visual components
  fNetClient.UpdateStateIdle;
  fServerQuery.UpdateStateIdle;
  fFileSenderManager.UpdateStateIdle(fNetClient.SendBufferEmpty);
end;


procedure TKMNetworking.FPSMeasurement(aFPS: Cardinal);
begin
  if Self = nil then Exit;

  fMyPlayerCurrentFPS := aFPS;
  if fNetGameState = lgsGame then
  begin
    PacketSend(NET_ADDRESS_SERVER, mkFPS, aFPS);
    MyNetPlayer.FPS := aFPS;
  end;
end;


procedure TKMNetworking.AnnounceReadyToReturnToLobby;
begin
  //Send it to ourselves too, that's simplest
  PacketSend(NET_ADDRESS_ALL, mkReadyToReturnToLobby);
end;


procedure TKMNetworking.WakeUpNotReady;
var
  I, K: Integer;
begin
  K := 0;
  for I := 1 to fNetPlayers.Count do
  begin
    if fNetPlayers[I].Connected and not fNetPlayers[I].ReadyToStart then
    begin
      PostMessage(TX_LOBBY_ALERT_NOT_READY, csSystem, '', '', fNetPlayers[I].IndexOnServer, TX_LOBBY_READY);
      Inc(K);
    end;
  end;
  PostLocalMessage(Format(gResTexts[TX_LOBBY_ALERT_GET_READY_SENT], [IntToStr(K)]), csSystem);
end;


// Ask other player to send report. We need reports from both players, who got desync error, to compare the saves and fix the desync
procedure TKMNetworking.AskToSendCrashreport(aOtherPlayerIndex: Integer; aErrorStr: UnicodeString);
begin
  PacketSendW(fNetPlayers[aOtherPlayerIndex].IndexOnServer, mkAskToSendCrashreport, aErrorStr);
end;


function TKMNetworking.GetMapInfo: TKMMapInfo;
begin
  if Self = nil then Exit(nil);

  Result := fMapInfo;
end;


function TKMNetworking.GetMyNetPlayer: TKMNetPlayerInfo;
begin
  Result := fNetPlayers[fMyIndex];
end;


procedure TKMNetworking.SetDownloadlInProgress(aSenderIndex: TKMNetHandleIndex; aValue: Boolean);
var
  playerIndex: Integer;
begin
  playerIndex := fNetPlayers.ServerToLocal(aSenderIndex);
  if playerIndex <> -1 then
    fNetPlayers[playerIndex].DownloadInProgress := aValue;
end;


procedure TKMNetworking.FileRequestReceived(aSenderIndex: TKMNetHandleIndex; aM: TKMemoryStream);

  procedure AbortSend;
  begin
    PacketSend(aSenderIndex, mkFileEnd); //Abort
    SetDownloadlInProgress(aSenderIndex, False);
  end;
  
var
  tmpStringW: UnicodeString;
begin
  if IsHost then
  begin
    //Validate request and set up file sender
    aM.ReadW(tmpStringW);
    case fSelectGameKind of
      ngkMap: if ((tmpStringW = MapInfo.Name) or (tmpStringW = MapInfo.Name + '_' + IntToHex(MapInfo.CRC, 8))) then
              begin
                PacketSend(NET_ADDRESS_OTHERS, mkFileSendStarted, aSenderIndex);
                SetDownloadlInProgress(aSenderIndex, True);
                if not fFileSenderManager.StartNewSend(kttMap, MapInfo.Name, MapInfo.Kind, aSenderIndex) then
                  AbortSend;
              end 
              else
                AbortSend;
                            

      ngkSave:if tmpStringW = SaveInfo.FileName then
              begin
                PacketSend(NET_ADDRESS_OTHERS, mkFileSendStarted, aSenderIndex);
                SetDownloadlInProgress(aSenderIndex, True);
                if not fFileSenderManager.StartNewSend(kttSave, SaveInfo.FileName, mkDL, aSenderIndex) then
                  AbortSend;
              end
              else
                AbortSend;
    end;
  end;
end;


procedure TKMNetworking.ReturnToLobbyVoteSucceeded;
begin
  // Don't run NetPlayers.ResetVote here, wait until we actually return to the lobby so the vote can't start again
  NetPlayers.ResetReadyToReturnToLobby;
  fVoteReturnToLobbySucceeded := True;
  SendPlayerListAndRefreshPlayersSetup;
  OnAnnounceReturnToLobby; // Sends GIC command to create synchronised save file
end;


procedure TKMNetworking.ResetReturnToLobbyVote;
begin
  fVoteReturnToLobbySucceeded := False;
  fNetPlayers.ResetReadyToReturnToLobby;
end;


procedure TKMNetworking.ReturnToLobby;
begin
  //Clear events that were used by Game
  OnCommands := nil;
  OnResyncFromTick := nil;
  OnPlay := nil;
  OnReadyToPlay := nil;
  OnPlayersSetup := nil;

  SetGameState(lgsLobby, False);
  fReturnedToLobby := True; //Expect pause.sav to match host
  if IsHost then
  begin
    NetPlayers.RemAllAIs; //AIs are included automatically when you start the save
    NetPlayers.RemDisconnectedPlayers; //Disconnected players must not be shown in lobby
    NetPlayers.ResetVote; //Only reset the vote now that the game has exited
    //Don't refresh player setup here since events aren't attached to lobby yet
  end;
end;


//Get NetPlayer by hand index. If no NetPlayer found for specified aHandIndex, then nil returned
function TKMNetworking.GetNetPlayerByHandIndex(aHandIndex: Integer): TKMNetPlayerInfo;
var
  index: Integer;
begin
  Result := nil;
  if Self = nil then Exit;

  index := GetNetPlayerIndex(aHandIndex);
  if index <> -1 then
    Result := fNetPlayers[index];
end;


//Get NetPlayer index by hand index. If no NetPlayer found for specified aHandIndex, then -1 returned
function TKMNetworking.GetNetPlayerIndex(aHandIndex: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;
  if Self = nil then Exit;

  for I := 1 to MAX_LOBBY_SLOTS do
    if aHandIndex = fNetPlayers[I].HandIndex then
      Exit(I);
end;


function TKMNetworking.GetPacketsReceived(aKind: TKMessageKind): Cardinal;
begin
  Result := fPacketsReceived[aKind];
end;


function TKMNetworking.GetPacketsSent(aKind: TKMessageKind): Cardinal;
begin
  Result := fPacketsSent[aKind];
end;


procedure TKMNetworking.ResetPacketsStats;
var
  mKind: TKMessageKind;
begin
  for mKind := Low(TKMessageKind) to High(TKMessageKind) do
  begin
    fPacketsReceived[mKind] := 0;
    fPacketsSent[mKind] := 0;
  end;
  fPacketsStatsStartTime := TimeGet;
end;


end.

