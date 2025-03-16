unit KM_NetworkTypes;
{$I KaM_Remake.inc}
interface
uses
  Math, KM_Points, KM_Lists, KM_CommonClasses;


type
  TKMNetPlayerKind = (lpkHost, lpkJoiner);
  TKMNetGameState = (lgsNone, lgsConnecting, lgsQuery, lgsLobby, lgsLoading, lgsGame, lgsReconnecting);
  TKMNetGameKind = (ngkNone, ngkMap, ngkSave);
  TKMChatSound = (csNone, csJoin, csLeave, csSystem, csGameStart, csSaveGame, csChat, csChatWhisper, csChatTeam);

const
  NET_ADDRESS_EMPTY = 0;    //Yet undefined
  NET_ADDRESS_OTHERS = -1;  //Recipient
  NET_ADDRESS_ALL = -2;     //Recipient
  NET_ADDRESS_HOST = -3;    //Sender/Recipient
  NET_ADDRESS_SERVER = -4;  //Sender/Recipient

  //Size of chunks that a file is sent in (must be smaller than MAX_PACKET_SIZE)
  //Making it less than Ethernet MTU (~1500) helps to avoids inefficient IP fragmentation
  FILE_CHUNK_SIZE = 1024; //max value less then MTU
  MAX_CUMULATIVE_PACKET_SIZE = 1460; //max value less then MTU
  MAX_PACKET_SIZE = 20480; //20kb. Maximum length of a KM packet
  MAX_CHUNKS_BEFORE_ACK = 80; //Number of chunks of a file that can be in flight
  DEFAULT_PACKET_ACC_DELAY = 20;

type
  // Client-Server-Client exchange packets. Each packet is a certain type
  //
  // Attention!!!
  // Add any new message kinds to the end of the next enum !!!
  //
  // Real situation example:
  // ************************************************************************************************************************
  // That issue was caused by adding new network command type of mkAskToSendCrashreport, which was added in r14423.
  // Command type is used not only in the game code, but in server code as well.
  // Most commands are just ignored by the server, but some commands are not,
  // f.e. server knows about the password so he should be able to receive that command type.
  // But mkAskToSendCrashreport was not added to the end of the list, but before mkPassword command.
  // Thus in r13651 mkPassword got an ID of 23 (let's say), but on r14423 its already 24, because of the new mkAskToSendCrashreport.
  // So when r14432 game client send mkPassword as a host he sends command ID of 24, but old server got 24 and its not mkPassword for him,
  // but some other command, which he did not except to receive and just ignores it. Thus password is not set on the server side.
  // When server and game client both have same version - their commands IDs are equal and everything is fine.
  // ************************************************************************************************************************
  //
  // Alternative solution could be to send message kind as a text, to avoid such errors in the future
  // Or even better solution is to use fixed IDs for enum values
  //
  TKMessageKind = (
    mkAskToJoin,       //Client asks Host if he can join
    mkAllowToJoin,     //Host allows Client to join
    mkRefuseToJoin,    //Host can refuse when e.g. Nickname is already taken

    mkAskForAuth,      //Joiner sends challenge to host, and askes host to send its challenge
    mkIndexOnServer,   //Server tells Client his index
    mkClientLost,      //Server tells clients that someone has disconnected
    mkReassignHost,    //Server tells clients who is the new host after the host disconnects

    mkGameVersion,     //Server tells a new client which NET_PROTOCOL_REVISON we are using (was GAME_VERSION before, but it is unnecessarily strict)
    mkWelcomeMessage,  //Server sends a welcome message to the client
    mkServerName,      //Server sends the server name to the client
    mkJoinRoom,        //Client requests to be placed in a room
    mkConnectedToRoom, //Server tells a client they have been successfully added to a room
    mkSetGameInfo,     //Host tells the server the player list, map, etc to be reported to queries
    mkKickPlayer,      //Host askes the server to kick someone
    mkBanPlayer,       //Host askes the server to ban someone from this room
    mkGiveHost,        //Host askes the server to reassign host
    mkResetBans,       //Host askes the server to reset the ban list for this room
    mkKicked,          //Server tells a client they were kicked just before disconnecting then
    mkLangCode,        //Client tells host his language code
    mkAuthChallenge,   //Host sends solution and own challenge back to joiner

    mkGetServerInfo,   //Client askes for server for the server details (for querying)
    mkServerInfo,      //Server sends client the server info on request

    mkDisconnect,      //Joiner tells Host that he is leaving the lobby/game deliberately
                        //Host tells Joiners that he is quitting
                        //A. Server runs on the same machine and stops right after
                        //B. Server runs on different machine and assigns Host role to some Client

    mkPing,            //Server pings Clients
    mkPong,            //Clients reply to Server with pong
    mkPingInfo,        //Server sends list of ping times to Clients
    mkFPS,             //Client tells other clients his FPS

    mkPlayersList,     //Host keeps the players list and sends it to everyone on change
    mkGameOptions,     //Host keeps the game options and sends it to everyone on change

    mkStartingLocQuery,//Joiner asks Host if he can take that starting location
    mkSetTeam,         //Joiner tells Host which team he is on
    mkFlagColorQuery,  //Joiner asks Host if he can take specific color

    mkResetMap,        //Reset the map selection to blank
    mkMapSelect,       //Host selects the map to play
    mkSaveSelect,      //Host selects the save to play
    mkReadyToStart,    //Joiner tells he's ready to play the game
    mkHasMapOrSave,    //Joiner tells host he has the map/save file
    mkStart,           //Host says to start the game
    mkReadyToReturnToLobby, //Joiner/host tells others they are ready to return to lobby

    mkReadyToPlay,     //Joiner tells Host he has loaded the map and clock can start
    mkPlay,            //Host tells everyone that the game may begin
    mkAskToReconnect,  //Dropped player askes permission from the host to reconnect
    mkRefuseReconnect, //Host tells the dropped player he is not allowed to reconnect
    mkResyncFromTick,  //Dropped player requests other players to send missed commands from specified tick
    mkReconnectionAccepted, //Host tells dropped player they are accepted back into the game
    mkClientReconnected, //Host tells other players the index of a reconnected client

    mkCommands,        //Clients exchange commands for next ticks
    mkTextTranslated,  //Clients exchange translated text (system messages)
    mkTextChat,        //Clients exchange chat messages

    mkReqPassword,     //Server requests joiner to send password
    mkPassword,        //Joiner sends password to server
    mkSetPassword,     //Host sets password on server

    mkFileRequest,     //Joiner requests host to send file
    mkFileSendStarted, //Host notify all about he start sending file
    mkFileChunk,       //Host sends chunk of file to joiner
    mkFileAck,         //Joiner tells host he received a chunk
    mkFileEnd,         //Host informs joiner that the whole file has been sent
    mkFileProgress,    //Joiner informs other players about his map/save downloading progress

    mkVote,            //Joiner tells host his vote
    mkAskToSendCrashreport // Ask other player to send crashreport, because we got desync error with him
  );
  // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // ^^^ Add new network command types to the end of the list. Check explanation above ^^^
  // ************************************************************************************************************************

  TKMPacketFormat = (
    pfNoData,   // Packet contains no data
    pfBinary,   // Packet contains binary data (Stream)
    pfNumber,   // Packet contains an integer
    pfStringA,  // Packet contains ANSI string
    pfStringW   // Packet contains Unicode string
  );

const
  NetPacketType: array [TKMessageKind] of TKMPacketFormat = (
    pfBinary,   //mkAskToJoin
    pfNoData,   //mkAllowToJoin
    pfNumber,   //mkRefuseToJoin
    pfBinary,   //mkAskForAuth
    pfNumber,   //mkIndexOnServer
    pfNumber,   //mkClientLost
    pfBinary,   //mkReassignHost
    pfStringA,  //mkGameVersion
    pfStringW,  //mkWelcomeMessage
    pfStringA,  //mkServerName
    pfBinary,   //mkJoinRoom
    pfNumber,   //mkConnectedToRoom
    pfBinary,   //mkSetGameInfo
    pfNumber,   //mkKickPlayer
    pfNumber,   //mkBanPlayer
    pfNumber,   //mkGiveHost
    pfNoData,   //mkResetBans
    pfNumber,   //mkKicked
    pfStringA,  //mkLangCode
    pfBinary,   //mkAuthChallenge
    pfNoData,   //mkGetServerInfo
    pfBinary,   //mkServerInfo
    pfNumber,   //mkDisconnect
    pfNoData,   //mkPing
    pfNoData,   //mkPong
    pfBinary,   //mkPingInfo
    pfNumber,   //mkFPS
    pfBinary,   //mkPlayersList
    pfBinary,   //mkGameOptions
    pfNumber,   //mkStartingLocQuery
    pfNumber,   //mkSetTeam
    pfNumber,   //mkFlagColorQuery
    pfNoData,   //mkResetMap
    pfBinary,   //mkMapSelect
    pfBinary,   //mkSaveSelect
    pfNoData,   //mkReadyToStart
    pfNoData,   //mkHasMapOrSave
    pfBinary,   //mkStart
    pfNoData,   //mkReadyToReturnToLobby
    pfNoData,   //mkReadyToPlay
    pfNoData,   //mkPlay
    pfStringA,  //mkAskToReconnect
    pfNumber,   //mkRefuseReconnect
    pfNumber,   //mkResyncFromTick
    pfNoData,   //mkReconnectionAccepted
    pfNumber,   //mkClientReconnected
    pfBinary,   //mkCommands
    pfBinary,   //mkTextTranslated
    pfBinary,   //mkTextChat
    pfNoData,   //mkReqPassword
    pfBinary,   //mkPassword
    pfStringA,  //mkSetPassword
    pfStringW,  //mkFileRequest
    pfNumber,   //mkFileSendStarted
    pfBinary,   //mkFileChunk
    pfNoData,   //mkFileAck
    pfNoData,   //mkFileEnd
    pfBinary,   //mkFileProgress
    pfNoData,   //mkVote
    pfStringW   //mkAskToSendCrashreport
  );


type
  TKMNetHandleIndex = SmallInt;
  PKMNetHandleIndex = ^TKMNetHandleIndex;
  TMPGameState = (mgsNone, mgsLobby, mgsLoading, mgsGame);
  TKMServerType = (mstClient, mstDedicated, mstLocal);
  TKMNetPlayerType = (nptHuman, nptClosed, nptComputerClassic, nptComputerAdvanced);
  TKMNetPlayerTypeSet = set of TKMNetPlayerType;


  TKMPGameFilter = class
  private
    fDynamicFOW: Boolean;
    fMapsFilterEnabled: Boolean;
    fMapsCRCList: TKMMapsCRCList;
    fPeacetimeRng: TKMRangeInt;
    fSpeedRng: TKMRangeSingle;
    fSpeedAfterPTRng: TKMRangeSingle;
    procedure Reset;
  public
    constructor Create; overload;
    constructor Create(aDynamicFOW, aMapsFilterEnabled: Boolean; const aMapsCRCListStr: UnicodeString; const aPeacetimeRng: TKMRangeInt;
                       const aSpeedRng: TKMRangeSingle; const aSpeedRngAfterPT: TKMRangeSingle); overload;
    destructor Destroy; override;

    function FilterMap(aCRC: Cardinal): Boolean;

    property DynamicFOW: Boolean read fDynamicFOW;
    property MapsFilterEnabled: Boolean read fMapsFilterEnabled;
    property MapsCRCList: TKMMapsCRCList read fMapsCRCList;
    property PeacetimeRng: TKMRangeInt read fPeacetimeRng;
    property SpeedRng: TKMRangeSingle read fSpeedRng;
    property SpeedAfterPTRng: TKMRangeSingle read fSpeedAfterPTRng;

    procedure Save(aStream: TKMemoryStream);
    procedure Load(aStream: TKMemoryStream);
  end;

const
  AI_PLAYER_TYPE_MIN = nptComputerClassic;
  AI_PLAYER_TYPE_MAX = nptComputerAdvanced;
  //Used in the dedicated server display as it does not care about translations (translated ones are in KM_TextLibrary)
  GameStateText: array [TMPGameState] of UnicodeString = ('None', 'Lobby', 'Loading', 'Game');
  NetPlayerTypeName: array [TKMNetPlayerType] of UnicodeString = ('Human', 'Closed', 'Classic AI Player', 'Advanced AI Player');
  ServerTypePic: array [TKMServerType] of Word = (74, 75, 79);

  function GetNetAddressStr(aNetworkAddress: Integer): String;
  function GetAIPlayerIcon(aNetPlayerType: TKMNetPlayerType): Word;

implementation
uses
  SysUtils;


{ TKMPGameFilter }
constructor TKMPGameFilter.Create;
begin
  inherited;

  fMapsCRCList := TKMMapsCRCList.Create;
  Reset;
end;


constructor TKMPGameFilter.Create(aDynamicFOW, aMapsFilterEnabled: Boolean; const aMapsCRCListStr: UnicodeString; const aPeacetimeRng: TKMRangeInt;
                                  const aSpeedRng: TKMRangeSingle; const aSpeedRngAfterPT: TKMRangeSingle);
begin
  inherited Create;

  fDynamicFOW := aDynamicFOW;
  fMapsFilterEnabled := aMapsFilterEnabled;

  fMapsCRCList := TKMMapsCRCList.Create;
  fMapsCRCList.LoadFromString(aMapsCRCListStr);

  fPeacetimeRng := aPeacetimeRng;
  fSpeedRng := aSpeedRng;
  fSpeedAfterPTRng := aSpeedRngAfterPT;
end;


destructor TKMPGameFilter.Destroy;
begin
  FreeAndNil(fMapsCRCList);

  inherited;
end;


procedure TKMPGameFilter.Save(aStream: TKMemoryStream);
begin
  aStream.Write(fDynamicFOW);
  aStream.Write(fMapsFilterEnabled);
  aStream.WriteA(AnsiString(fMapsCRCList.PackToString));
  aStream.Write(fPeacetimeRng);
  aStream.Write(fSpeedRng);
  aStream.Write(fSpeedAfterPTRng);
end;


procedure TKMPGameFilter.Load(aStream: TKMemoryStream);
var
  strA: AnsiString;
begin
  aStream.Read(fDynamicFOW);
  aStream.Read(fMapsFilterEnabled);
  aStream.ReadA(strA);
  fMapsCRCList.LoadFromString(UnicodeString(strA));
  aStream.Read(fPeacetimeRng);
  aStream.Read(fSpeedRng);
  aStream.Read(fSpeedAfterPTRng);
end;


procedure TKMPGameFilter.Reset;
begin
  fMapsCRCList.Clear;
  fDynamicFOW := False;
  fMapsFilterEnabled := False;
  fPeacetimeRng.Min := 0;
  fPeacetimeRng.Max := MaxInt;
  fSpeedRng.Min := 0;
  fSpeedRng.Max := MaxSingle;
  fSpeedAfterPTRng.Min := 0;
  fSpeedAfterPTRng.Max := MaxSingle;
end;


function TKMPGameFilter.FilterMap(aCRC: Cardinal): Boolean;
begin
  Result := not fMapsFilterEnabled or fMapsCRCList.Contains(aCRC);
end;


function GetNetAddressStr(aNetworkAddress: Integer): String;
begin
  case aNetworkAddress of
    NET_ADDRESS_EMPTY   : Result := 'EMPTY';
    NET_ADDRESS_OTHERS  : Result := 'OTHERS';
    NET_ADDRESS_ALL     : Result := 'ALL';
    NET_ADDRESS_HOST    : Result := 'HOST';
    NET_ADDRESS_SERVER  : Result := 'SERVER';
    else                  Result := IntToStr(aNetworkAddress);
  end;
end;


function GetAIPlayerIcon(aNetPlayerType: TKMNetPlayerType): Word;
begin
  case aNetPlayerType of
    nptComputerClassic:   Result := 62; //PC Icon
    nptComputerAdvanced:  Result := 74; //Large PC Icon
    else                  Result := 0;  //None
  end;
end;


end.

