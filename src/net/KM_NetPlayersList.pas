unit KM_NetPlayersList;
{$I KaM_Remake.inc}
interface
uses
  Classes, KromUtils, StrUtils, Math, SysUtils,
  KM_CommonClasses, KM_CommonTypes, KM_Defaults, KM_Hand, KM_ResLocales, KM_NetworkTypes,
  KM_HandTypes;

const
  PING_COUNT = 20; //Number of pings to store and take the maximum over for latency calculation (pings are measured once per second)

type
  //Multiplayer info that is filled in Lobby before TKMPlayers are created (thats why it has many mirror fields)
  //@Rey: This class can actually be renamed to TKMLobbySlot
  TKMNetPlayerInfo = class
  private
    fNickname: AnsiString;
    fLangCode: AnsiString;
    fIndexOnServer: TKMNetHandleIndex;
    fFlagColor: Cardinal; //Flag color
    fPings: array[0 .. PING_COUNT-1] of Word; //Ring buffer
    fPingPos: Byte;
    procedure SetLangCode(const aCode: AnsiString);
    function GetNicknameColored: AnsiString;
    function GetNickname: AnsiString;
    function GetNicknameColoredU: UnicodeString;
    function GetNicknameU: UnicodeString;
    function GetHandIndex: Integer;
    function GetFlagColor: Cardinal;
    procedure SetFlagColor(const Value: Cardinal);
  public
    PlayerNetType: TKMNetPlayerType; //Human, Computer, Closed
    StartLocation: Integer;  //Start location, 0 means random, -1 means spectate
    Team: Integer;
    ReadyToStart: Boolean;
    ReadyToPlay: Boolean;
    ReadyToReturnToLobby: Boolean;
    HasMapOrSave: Boolean;
    Connected: Boolean;      //Player is still connected
    Dropped: Boolean;        //Host elected to continue play without this player
    LastSentCommandsTick: Integer; {Last tick when this player sent GIP commands to others}  //todo: move it somewhere...?)
    DownloadInProgress: Boolean; //Player is in map/save download progress
    FPS: Cardinal;
    VotedYes: Boolean;
    procedure AddPing(aPing: Word);
    procedure ResetPingRecord;
    function NeedWaitForLastCommands(aTick: Integer): Boolean;
    function NoNeedToWait(aTick: Integer): Boolean;
    function GetInstantPing: Word;
    function GetMaxPing: Word;
    function IsHuman: Boolean;
    function IsComputer: Boolean;
    function IsClassicComputer: Boolean;
    function IsAdvancedComputer: Boolean;
    function IsClosed: Boolean;
    function IsSpectator: Boolean;
    function GetPlayerType: TKMHandType;
    function SlotName: UnicodeString; //Player name if it's human or computer or closed
    property Nickname: AnsiString read GetNickname; //Human player nickname (ANSI-Latin)
    property NicknameColored: AnsiString read GetNicknameColored;
    property NicknameU: UnicodeString read GetNicknameU;
    property NicknameColoredU: UnicodeString read GetNicknameColoredU;
    property LangCode: AnsiString read fLangCode write SetLangCode;
    property IndexOnServer: TKMNetHandleIndex read fIndexOnServer;
    property SetIndexOnServer: TKMNetHandleIndex write fIndexOnServer;
    function FlagColorDef(aDefaultColor: Cardinal = icWhite): Cardinal;
    property FlagColor: Cardinal read GetFlagColor write SetFlagColor;
    function IsColorSet: Boolean;
    procedure ResetColor;
    property HandIndex: Integer read GetHandIndex;

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
  end;


  //Handles everything related to players list,
  //but knows nothing about networking nor game setup. Only players.
  //@Rey: This class can actually be renamed to TKMLobbySlots
  TKMNetPlayersList = class
  private
    fCount: Integer;
    fNetPlayers: array [1..MAX_LOBBY_SLOTS] of TKMNetPlayerInfo;
    function GetPlayer(aIndex: Integer): TKMNetPlayerInfo;
    procedure ValidateColors(var aFixedLocsColors: TKMCardinalArray);
    procedure RemAllClosedPlayers;
  public
    HostDoesSetup: Boolean; //Gives host absolute control over locations/teams (not colors)
    RandomizeTeamLocations: Boolean; //When the game starts locations are shuffled within each team
    SpectatorsAllowed: Boolean;
    SpectatorSlotsOpen: ShortInt;
    VoteActive: Boolean;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    property Count: Integer read fCount;

    procedure AddPlayer(const aNick: AnsiString; aIndexOnServer: TKMNetHandleIndex; const aLang: AnsiString; aAsSpectator: Boolean = False);
    procedure AddAIPlayer(aAdvancedAI: Boolean; aSlot: Integer = -1);
    procedure AddClosedPlayer(aSlot: Integer = -1);
    procedure DisconnectPlayer(aIndexOnServer: TKMNetHandleIndex);
    procedure DisconnectAllClients(const aOwnNickname: AnsiString);
    procedure DropPlayer(aIndexOnServer: TKMNetHandleIndex; aLastSentCommandsTick: Integer = LAST_SENT_COMMANDS_TICK_NONE);
    procedure RemPlayer(aIndex: Integer);
    procedure RemServerPlayer(aIndexOnServer: TKMNetHandleIndex);
    property Player[aIndex: Integer]: TKMNetPlayerInfo read GetPlayer; default;

    //Getters
    function ServerToLocal(aIndexOnServer: TKMNetHandleIndex): Integer;
    function NicknameToLocal(const aNickname: AnsiString): Integer;
    function StartingLocToLocal(aLoc: Integer): Integer;
    function PlayerIndexToLocal(aIndex: TKMHandID): Integer;

    function CheckCanJoin(const aNick: AnsiString; aIndexOnServer: TKMNetHandleIndex): Integer;
    function CheckCanReconnect(aLocalIndex: Integer): Integer;
    function LocAvailable(aIndex: Integer): Boolean;
    function ColorAvailable(aColor: Cardinal): Boolean;
    function AllReady: Boolean;
    function AllReadyToPlay: Boolean;
    function AllReadyToReturnToLobby: Boolean;
    function GetMaxHighestRoundTripLatency: Word;
    function GetNotReadyToPlayPlayers: TKMByteArray;
    function GetAICount(aAIPlayerTypes: TKMNetPlayerTypeSet = [AI_PLAYER_TYPE_MIN..AI_PLAYER_TYPE_MAX]): Integer;
    function GetPlayerCount(aPlayerTypes: TKMNetPlayerTypeSet = [Low(TKMNetPlayerType)..High(TKMNetPlayerType)]): Integer;
    function GetClosedCount: Integer;
    function GetSpectatorCount: Integer;
    function GetConnectedCount: Integer;
    function GetConnectedPlayersCount: Integer;
    function GetNotDroppedCount: Integer;
    function FurtherVotesNeededForMajority: Integer;
    function HasOnlySpectators: Boolean;
    procedure SetDownloadAborted;

    procedure ResetLocAndReady;
    procedure ResetReady;
    procedure ResetReadyToPlay;
    procedure ResetReadyToReturnToLobby;
    procedure ResetVote;
    procedure SetAIReady;
    procedure RemAllAIs;
    procedure RemDisconnectedPlayers;
    function ValidateSetup(var aHumanUsableLocs, aAIUsableLocs, aAdvancedAIUsableLocs: TKMHandIDArray;
                           var aFixedLocsColors: TKMCardinalArray; out ErrorMsg: UnicodeString): Boolean;

    //Import/Export
    procedure SaveToStream(aStream: TKMemoryStream); //Gets all relevant information as text string
    procedure LoadFromStream(aStream: TKMemoryStream); //Sets all relevant information
    function GetPlayersWithIDs: UnicodeString;
  end;


implementation
uses
  TypInfo,
  KM_Log, KM_ResTexts, KM_CommonUtils, KM_HandsCollection;


{ TKMNetPlayerInfo }
procedure TKMNetPlayerInfo.AddPing(aPing: Word);
begin
  fPingPos := (fPingPos + 1) mod PING_COUNT;
  fPings[fPingPos] := aPing;
end;


procedure TKMNetPlayerInfo.ResetPingRecord;
begin
  fPingPos := 0;
  FillChar(fPings, SizeOf(fPings), #0);
end;


function TKMNetPlayerInfo.GetFlagColor: Cardinal;
begin
  if Self = nil then Exit(0);

  Result := fFlagColor;
end;


function TKMNetPlayerInfo.FlagColorDef(aDefaultColor: Cardinal = icWhite): Cardinal;
begin
  if IsColorSet then
    Result := GetFlagColor
  else
    Result := aDefaultColor;
end;


procedure TKMNetPlayerInfo.SetFlagColor(const Value: Cardinal);
begin
  if Self = nil then Exit;

  fFlagColor := Value;
end;


procedure TKMNetPlayerInfo.SetLangCode(const aCode: AnsiString);
begin
  if gResLocales.IndexByCode(aCode) <> -1 then
    fLangCode := aCode;
end;


//Check if other players need to wait this player, because of his last commands before disconnection
function TKMNetPlayerInfo.NeedWaitForLastCommands(aTick: Integer): Boolean;
begin
  Result := (LastSentCommandsTick <> LAST_SENT_COMMANDS_TICK_NONE) and (LastSentCommandsTick >= aTick);
end;


//Do other player need to wait us at game tick aTick?
function TKMNetPlayerInfo.NoNeedToWait(aTick: Integer): Boolean;
begin
  Result := not IsHuman or (Dropped and not NeedWaitForLastCommands(aTick));
end;


function TKMNetPlayerInfo.GetInstantPing: Word;
begin
  Result := fPings[fPingPos];
end;


function TKMNetPlayerInfo.GetMaxPing: Word;
var
  I: Integer;
  worst: Word;
begin
  Result := 0;
  worst := 0;
  //We should ignore the worst ping so we don't delay game input due to one ping spike
  for I := 0 to PING_COUNT - 1 do
  begin
    if fPings[I] > worst then
    begin
      Result := Math.max(Result, worst);
      worst := fPings[I]
    end
    else
      Result := Math.max(Result, fPings[I]);
  end;
end;


function TKMNetPlayerInfo.IsHuman: Boolean;
begin
  Result := PlayerNetType = nptHuman;
end;


function TKMNetPlayerInfo.IsColorSet: Boolean;
begin
  Result := fFlagColor <> 0; // We suggest color is not set if its 0 (also means its transparent, not black)
end;


procedure TKMNetPlayerInfo.ResetColor;
begin
  fFlagColor := 0;
end;


function TKMNetPlayerInfo.IsComputer: Boolean;
begin
  Result := PlayerNetType in [nptComputerClassic, nptComputerAdvanced];
end;


function TKMNetPlayerInfo.IsClassicComputer: Boolean;
begin
  Result := PlayerNetType = nptComputerClassic;
end;


function TKMNetPlayerInfo.IsAdvancedComputer: Boolean;
begin
  Result := PlayerNetType = nptComputerAdvanced;
end;


function TKMNetPlayerInfo.IsClosed: Boolean;
begin
  Result := PlayerNetType = nptClosed;
end;


function TKMNetPlayerInfo.IsSpectator: Boolean;
begin
  Result := StartLocation = LOC_SPECTATE;
end;


function TKMNetPlayerInfo.GetPlayerType: TKMHandType;
const
  PlayerTypes: array [TKMNetPlayerType] of TKMHandType = (hndHuman, hndComputer, hndComputer, hndComputer);
begin
  Result := PlayerTypes[PlayerNetType];
end;


function TKMNetPlayerInfo.SlotName: UnicodeString;
begin
  case PlayerNetType of
    nptHuman:     Result := NicknameU;
    nptComputerClassic:  //In lobby AI players don't have numbers yet (they are added on mission start)
                  Result := gResTexts[TX_AI_PLAYER_CLASSIC];
    nptComputerAdvanced:  //In lobby AI players don't have numbers yet (they are added on mission start)
                  Result := gResTexts[TX_AI_PLAYER_ADVANCED];
    nptClosed:    Result := gResTexts[TX_LOBBY_SLOT_CLOSED];
    else          Result := NO_TEXT;
  end;
end;


function TKMNetPlayerInfo.GetNickname: AnsiString;
begin
  if Self = nil then Exit('');

  if IsHuman or (gHands = nil) or (HandIndex = -1) then
    Result := fNickname
  else
    Result := AnsiString(gHands[HandIndex].OwnerName(True, False));
end;


function TKMNetPlayerInfo.GetNicknameColored: AnsiString;
begin
  if IsColorSet then
    Result := WrapColorA(Nickname, FlagColorToTextColor(FlagColor))
  else
    Result := Nickname;
end;


function TKMNetPlayerInfo.GetNicknameU: UnicodeString;
begin
  Result := UnicodeString(GetNickname);
end;


function TKMNetPlayerInfo.GetNicknameColoredU: UnicodeString;
begin
  Result := UnicodeString(GetNicknameColored);
end;


function TKMNetPlayerInfo.GetHandIndex: Integer;
begin
  if Self = nil then Exit(-1);
  
  Result := -1;
  if StartLocation > 0 then
    Result := StartLocation - 1;
end;


procedure TKMNetPlayerInfo.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.ReadA(fNickname);
  LoadStream.ReadA(fLangCode);
  LoadStream.Read(SmallInt(fIndexOnServer));
  LoadStream.Read(PlayerNetType, SizeOf(PlayerNetType));
  LoadStream.Read(fFlagColor);
  LoadStream.Read(StartLocation);
  LoadStream.Read(Team);
  LoadStream.Read(ReadyToStart);
  LoadStream.Read(ReadyToPlay);
  LoadStream.Read(ReadyToReturnToLobby);
  LoadStream.Read(HasMapOrSave);
  LoadStream.Read(Connected);
  LoadStream.Read(Dropped);
  LoadStream.Read(LastSentCommandsTick);
  LoadStream.Read(DownloadInProgress);
  LoadStream.Read(VotedYes);
end;


procedure TKMNetPlayerInfo.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.WriteA(fNickname);
  SaveStream.WriteA(fLangCode);
  SaveStream.Write(fIndexOnServer);
  SaveStream.Write(PlayerNetType, SizeOf(PlayerNetType));
  SaveStream.Write(fFlagColor);
  SaveStream.Write(StartLocation);
  SaveStream.Write(Team);
  SaveStream.Write(ReadyToStart);
  SaveStream.Write(ReadyToPlay);
  SaveStream.Write(ReadyToReturnToLobby);
  SaveStream.Write(HasMapOrSave);
  SaveStream.Write(Connected);
  SaveStream.Write(Dropped);
  SaveStream.Write(LastSentCommandsTick);
  SaveStream.Write(DownloadInProgress);
  SaveStream.Write(VotedYes);
end;


{ TKMNetPlayersList }
constructor TKMNetPlayersList.Create;
var
  I: Integer;
begin
  inherited;

  for I := 1 to MAX_LOBBY_SLOTS do
    fNetPlayers[I] := TKMNetPlayerInfo.Create;

  Clear;
end;


destructor TKMNetPlayersList.Destroy;
var
  I: Integer;
begin
  for I := 1 to MAX_LOBBY_SLOTS do
    fNetPlayers[I].Free;

  inherited;
end;


procedure TKMNetPlayersList.Clear;
begin
  HostDoesSetup := False;
  RandomizeTeamLocations := False;
  SpectatorsAllowed := LOBBY_SET_SPECS_DEFAULT;
  SpectatorSlotsOpen := MAX_LOBBY_SPECTATORS;
  ResetVote;
  fCount := 0;
end;


function TKMNetPlayersList.GetPlayer(aIndex: Integer): TKMNetPlayerInfo;
begin
  if (Self = nil) or not InRange(aIndex, 1, MAX_LOBBY_SLOTS) then Exit(nil);

  Result := fNetPlayers[aIndex];
end;


procedure TKMNetPlayersList.ValidateColors(var aFixedLocsColors: TKMCardinalArray);

var
  colorCount: Integer;
  usedColor: array [0..MP_COLOR_COUNT] of Boolean; //0 means Random
  availableColor: array [1..MP_COLOR_COUNT] of Byte;

  procedure CollectAvailColors(aColorDist: Single);
  var
    I: Integer;
  begin
    //Collect available colors
    colorCount := 0;
    FillChar(availableColor, SizeOf(availableColor), #0);
    for I := 1 to MP_COLOR_COUNT do
      if not usedColor[I] and not IsColorCloseToColors(MP_PLAYER_COLORS[I], aFixedLocsColors, aColorDist) then
      begin
        Inc(colorCount);
        availableColor[colorCount] := I;
      end;
  end;

  function IsFixedPlayerColor(aLocIndex: Integer): Boolean;
  var
    fixedColorsSet: Boolean;
  begin
    fixedColorsSet := Length(aFixedLocsColors) > 0;
    Result := not fNetPlayers[aLocIndex].IsSpectator // we should always count on specs color
              and fixedColorsSet
              and (aFixedLocsColors[fNetPlayers[aLocIndex].HandIndex] <> 0);
  end;

var
  I, K, colorID, colorsNeeded: Integer;
  colorDist: Single;
begin

  // Set known fixed colors
  // Fixed are AI only locs colors
  // and every loc color, if BlockPlayerColor parametr is set
  for I := 1 to fCount do
    if IsFixedPlayerColor(I) then
      fNetPlayers[I].FlagColor := aFixedLocsColors[fNetPlayers[I].HandIndex];

  //All wrong colors will be reset to random
  for I := 1 to fCount do
    if (fNetPlayers[I].FlagColor shr 24) <> $FF then
      fNetPlayers[I].ResetColor;

  FillChar(usedColor, SizeOf(usedColor), #0);

  colorsNeeded := 0;
  //Remember all used colors and drop duplicates
  for I := 1 to fCount do
  begin
    if not fNetPlayers[I].IsColorSet then
      Inc(colorsNeeded);

    // Ignore fixed colors for non-specs
    if IsFixedPlayerColor(I) then
      Continue;

    colorID := FindMPColor(fNetPlayers[I].FlagColor);

    if usedColor[colorID] then
    begin
      fNetPlayers[I].ResetColor;
    end else begin
      usedColor[colorID] := True;
    end;
  end;

  // Try to find different colors by reduced color distance
  colorDist := MIN_PLAYER_COLOR_DIST;
  repeat
    CollectAvailColors(colorDist);
    colorDist := colorDist * 0.7; // color distance is reduced to find more colors, if needed
  until (colorCount >= colorsNeeded) or (colorDist < 0.001); // Try to get at least 1 color or stop when its way to low on distance

  //Randomize (don't use KaMRandom - we want varied results and PlayerList is synced to clients before start)
  for I := 1 to colorCount do
    SwapInt(availableColor[I], availableColor[Random(colorCount)+1]);

  //Allocate available colors
  K := 0;
  for I := 1 to fCount do
  begin
    // Ignore fixed colors for non-specs
    if IsFixedPlayerColor(I) then
      Continue;

    if not fNetPlayers[I].IsColorSet then
    begin
      Inc(K);
      if K <= colorCount then
        fNetPlayers[I].FlagColor := MP_PLAYER_COLORS[availableColor[K]]
      else
        fNetPlayers[I].FlagColor := GetRandomColor; // That should not be happening/ But just in case - set random color then
    end;
  end;

  //Check for odd players
  for I := 1 to fCount do
    Assert(fNetPlayers[I].IsColorSet, 'Everyone should have a color now!');
end;


procedure TKMNetPlayersList.RemAllClosedPlayers;
var
  I: Integer;
begin
  for I := fCount downto 1 do
    if Player[I].IsClosed then
      RemPlayer(I);
end;


procedure TKMNetPlayersList.AddPlayer(const aNick: AnsiString; aIndexOnServer: TKMNetHandleIndex; const aLang: AnsiString; aAsSpectator: Boolean = False);
begin
  Assert(fCount <= MAX_LOBBY_SLOTS, 'Can''t add player');
  Inc(fCount);
  fNetPlayers[fCount].fNickname := aNick;
  fNetPlayers[fCount].fLangCode := aLang;
  fNetPlayers[fCount].fIndexOnServer := aIndexOnServer;
  fNetPlayers[fCount].PlayerNetType := nptHuman;
  fNetPlayers[fCount].Team := 0;
  fNetPlayers[fCount].FlagColor := 0; // Transparent color
  fNetPlayers[fCount].ReadyToStart := False;
  fNetPlayers[fCount].HasMapOrSave := False;
  fNetPlayers[fCount].ReadyToPlay := False;
  fNetPlayers[fCount].ReadyToReturnToLobby := False;
  fNetPlayers[fCount].Connected := True;
  fNetPlayers[fCount].Dropped := False;
  fNetPlayers[fCount].LastSentCommandsTick := LAST_SENT_COMMANDS_TICK_NONE;
  fNetPlayers[fCount].DownloadInProgress := False;
  fNetPlayers[fCount].ResetPingRecord;
  //Check if this player must go in a spectator slot
  if aAsSpectator or (fCount - GetSpectatorCount > MAX_LOBBY_PLAYERS) then
    fNetPlayers[fCount].StartLocation := LOC_SPECTATE
  else
    fNetPlayers[fCount].StartLocation := LOC_RANDOM;
end;


procedure TKMNetPlayersList.AddAIPlayer(aAdvancedAI: Boolean; aSlot: Integer = -1);
begin
  if aSlot = -1 then
  begin
    Assert(fCount <= MAX_LOBBY_SLOTS, 'Can''t add AI player');
    Inc(fCount);
    aSlot := fCount;
  end;
  fNetPlayers[aSlot].fNickname := '';
  fNetPlayers[aSlot].fLangCode := '';
  fNetPlayers[aSlot].fIndexOnServer := -1;
  if aAdvancedAI then
    fNetPlayers[aSlot].PlayerNetType := nptComputerAdvanced
  else
    fNetPlayers[aSlot].PlayerNetType := nptComputerClassic;
  fNetPlayers[aSlot].Team := 0;
  fNetPlayers[aSlot].FlagColor := 0;
  fNetPlayers[aSlot].StartLocation := 0;
  fNetPlayers[aSlot].ReadyToStart := True;
  fNetPlayers[aSlot].HasMapOrSave := True;
  fNetPlayers[aSlot].ReadyToPlay := True;
  fNetPlayers[aSlot].Connected := True;
  fNetPlayers[aSlot].Dropped := False;
  fNetPlayers[aSlot].LastSentCommandsTick := LAST_SENT_COMMANDS_TICK_NONE;
  fNetPlayers[aSlot].DownloadInProgress := False;
  fNetPlayers[aSlot].ResetPingRecord;
end;


procedure TKMNetPlayersList.AddClosedPlayer(aSlot: Integer = -1);
begin
  if aSlot = -1 then
  begin
    Assert(fCount < MAX_LOBBY_SLOTS, 'Can''t add closed player');
    Inc(fCount);
    aSlot := fCount;
  end;
  fNetPlayers[aSlot].fNickname := '';
  fNetPlayers[aSlot].fLangCode := '';
  fNetPlayers[aSlot].fIndexOnServer := -1;
  fNetPlayers[aSlot].PlayerNetType := nptClosed;
  fNetPlayers[aSlot].Team := 0;
  fNetPlayers[aSlot].FlagColor := 0;
  fNetPlayers[aSlot].StartLocation := 0;
  fNetPlayers[aSlot].ReadyToStart := True;
  fNetPlayers[aSlot].HasMapOrSave := True;
  fNetPlayers[aSlot].ReadyToPlay := True;
  fNetPlayers[aSlot].Connected := True;
  fNetPlayers[aSlot].Dropped := False;
  fNetPlayers[aSlot].LastSentCommandsTick := LAST_SENT_COMMANDS_TICK_NONE;
  fNetPlayers[aSlot].DownloadInProgress := False;
  fNetPlayers[aSlot].ResetPingRecord;
end;


//Set player to no longer be connected, but do not remove them from the game
procedure TKMNetPlayersList.DisconnectPlayer(aIndexOnServer: TKMNetHandleIndex);
var
  ID: Integer;
begin
  ID := ServerToLocal(aIndexOnServer);
  Assert(ID <> -1, 'Cannot disconnect player');
  fNetPlayers[ID].Connected := False;
end;

//Mark all human players as disconnected (used when reconnecting if all clients were lost)
procedure TKMNetPlayersList.DisconnectAllClients(const aOwnNickname: AnsiString);
var
  I: Integer;
begin
  for I := 1 to fCount do
    if (fNetPlayers[I].IsHuman) and (fNetPlayers[I].Nickname <> aOwnNickname) then
      fNetPlayers[I].Connected := False;
end;


//Set player to no longer be on the server, but do not remove their assets from the game
procedure TKMNetPlayersList.DropPlayer(aIndexOnServer: TKMNetHandleIndex; aLastSentCommandsTick: Integer = LAST_SENT_COMMANDS_TICK_NONE);
var
  ID: Integer;
begin
  ID := ServerToLocal(aIndexOnServer);
  Assert(ID <> -1, 'Cannot drop player');
  fNetPlayers[ID].Connected := False;
  fNetPlayers[ID].Dropped := True;
  fNetPlayers[ID].LastSentCommandsTick := aLastSentCommandsTick;
end;


procedure TKMNetPlayersList.RemPlayer(aIndex: Integer);
var
  I: Integer;
begin
  fNetPlayers[aIndex].Free;
  for I := aIndex to fCount - 1 do
    fNetPlayers[I] := fNetPlayers[I + 1]; // Shift only pointers

  fNetPlayers[fCount] := TKMNetPlayerInfo.Create; // Empty players are created but not used
  Dec(fCount);
end;


procedure TKMNetPlayersList.RemServerPlayer(aIndexOnServer: TKMNetHandleIndex);
var
  ID: Integer;
begin
  ID := ServerToLocal(aIndexOnServer);
  Assert(ID <> -1, 'Cannot remove non-existing player');
  RemPlayer(ID);
end;


function TKMNetPlayersList.ServerToLocal(aIndexOnServer: TKMNetHandleIndex): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 1 to fCount do
    if fNetPlayers[I].fIndexOnServer = aIndexOnServer then
      Exit(I);
end;


//Networking needs to convert Nickname to local index in players list
function TKMNetPlayersList.NicknameToLocal(const aNickname: AnsiString): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 1 to fCount do
    if fNetPlayers[I].fNickname = aNickname then
      Exit(I);
end;


//Convert known starting location to local index in players list
function TKMNetPlayersList.StartingLocToLocal(aLoc: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 1 to fCount do
    if fNetPlayers[I].StartLocation = aLoc then
      Exit(I);
end;


function TKMNetPlayersList.PlayerIndexToLocal(aIndex: TKMHandID): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 1 to Count do
    if (aIndex = fNetPlayers[I].HandIndex) then
      Exit(I);
end;


//See if player can join our game
function TKMNetPlayersList.CheckCanJoin(const aNick: AnsiString; aIndexOnServer: TKMNetHandleIndex): Integer;
begin
  if fCount >= MAX_LOBBY_SLOTS then
    Result := TX_NET_ROOM_FULL
  else
  if ServerToLocal(aIndexOnServer) <> -1 then
    Result := TX_NET_SAME_NAME
  else
  if NicknameToLocal(aNick) <> -1 then
    Result := TX_NET_SAME_NAME
  else
  //If this player must take a spectator spot, check that one is open
  if (fCount-GetSpectatorCount >= MAX_LOBBY_PLAYERS)
  and ((SpectatorSlotsOpen-GetSpectatorCount <= 0) or not SpectatorsAllowed) then
    Result := TX_NET_ROOM_FULL
  else
    Result := -1;
end;


//See if player can join our game
function TKMNetPlayersList.CheckCanReconnect(aLocalIndex: Integer): Integer;
begin
  if aLocalIndex = -1 then
    Result := -2 //Silent failure, client should try again
  else
  if Player[aLocalIndex].Connected then
    Result := -2 //Silent failure, client should try again
  else
  if Player[aLocalIndex].Dropped then
    Result := TX_NET_RECONNECTION_DROPPED
  else
    Result := -1; //Success
end;


function TKMNetPlayersList.LocAvailable(aIndex: Integer): Boolean;
var
  I: Integer;
begin
  Result := True;
  if (aIndex = LOC_RANDOM) or (aIndex = LOC_SPECTATE) then Exit;

  for I := 1 to fCount do
    Result := Result and (aIndex <> fNetPlayers[I].StartLocation);
end;


function TKMNetPlayersList.ColorAvailable(aColor: Cardinal): Boolean;
var
  I: Integer;
begin
  Result := True;
  if (aColor shr 24) <> $FF then Exit; // Color with transparency

  for I := 1 to fCount do
    Result := Result and (aColor <> fNetPlayers[I].FlagColor);
end;


function TKMNetPlayersList.AllReady: Boolean;
var
  I: Integer;
begin
  Result := true;
  for I := 1 to fCount do
    if fNetPlayers[I].Connected and fNetPlayers[I].IsHuman then
      Result := Result and fNetPlayers[I].ReadyToStart and fNetPlayers[I].HasMapOrSave;
end;


function TKMNetPlayersList.AllReadyToPlay: Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := 1 to fCount do
    if fNetPlayers[I].Connected and fNetPlayers[I].IsHuman then
      Result := Result and fNetPlayers[I].ReadyToPlay;
end;


function TKMNetPlayersList.AllReadyToReturnToLobby: Boolean;
var
  I: Integer;
begin
  Result := True;
  for I:=1 to fCount do
    if fNetPlayers[I].Connected and fNetPlayers[I].IsHuman then
      Result := Result and fNetPlayers[I].ReadyToReturnToLobby;
end;


function TKMNetPlayersList.GetMaxHighestRoundTripLatency: Word;
var
  I: Integer;
  highest, highest2, playerPing: Word;
begin
  highest := 0;
  highest2 := 0;
  for I := 1 to fCount do
    if fNetPlayers[I].Connected and fNetPlayers[I].IsHuman then
    begin
      playerPing := fNetPlayers[I].GetMaxPing;
      if playerPing > highest then
        highest := playerPing
      else
        if playerPing > highest2 then
          highest2 := playerPing;
    end;
  Result := min(highest + highest2, High(Word));
end;


function TKMNetPlayersList.GetNotReadyToPlayPlayers: TKMByteArray;
var
  I, K: Integer;
begin
  SetLength(Result, MAX_LOBBY_SLOTS);

  K := 0;
  for I := 1 to fCount do
    if (not fNetPlayers[I].ReadyToPlay) and fNetPlayers[I].IsHuman and fNetPlayers[I].Connected then
    begin
      Result[K] := I;
      Inc(K)
    end;

  SetLength(Result, K);
end;


function TKMNetPlayersList.GetAICount(aAIPlayerTypes: TKMNetPlayerTypeSet = [AI_PLAYER_TYPE_MIN..AI_PLAYER_TYPE_MAX]): Integer;
begin
  Result := GetPlayerCount(aAIPlayerTypes * [AI_PLAYER_TYPE_MIN..AI_PLAYER_TYPE_MAX]);
end;


function TKMNetPlayersList.GetPlayerCount(aPlayerTypes: TKMNetPlayerTypeSet = [Low(TKMNetPlayerType)..High(TKMNetPlayerType)]): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to fCount do
    if fNetPlayers[I].PlayerNetType in aPlayerTypes then
      Inc(Result);
end;


function TKMNetPlayersList.GetClosedCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to fCount do
    if fNetPlayers[I].PlayerNetType = nptClosed then
      Inc(Result);
end;


function TKMNetPlayersList.GetSpectatorCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to fCount do
    if fNetPlayers[I].IsSpectator then
      Inc(Result);
end;


function TKMNetPlayersList.GetConnectedCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to fCount do
    if fNetPlayers[I].IsHuman and fNetPlayers[I].Connected then
      Inc(Result);
end;


function TKMNetPlayersList.GetConnectedPlayersCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to fCount do
    if fNetPlayers[I].IsHuman
      and fNetPlayers[I].Connected
      and not fNetPlayers[I].IsSpectator then
      Inc(Result);
end;


//Number of not Dropped players
//Player could be disconnected already, but not dropped yet.
function TKMNetPlayersList.GetNotDroppedCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to fCount do
    if fNetPlayers[I].IsHuman and not fNetPlayers[I].Dropped then
      Inc(Result);
end;


function TKMNetPlayersList.FurtherVotesNeededForMajority: Integer;
var
  I, votedYes, total: Integer;
  onlySpecsLeft: Boolean;
begin
  total := 0;
  votedYes := 0;
  onlySpecsLeft := HasOnlySpectators; //Store value locally
  for I := 1 to fCount do
    if (fNetPlayers[I].PlayerNetType = nptHuman)
    and (onlySpecsLeft or (fNetPlayers[I].StartLocation <> LOC_SPECTATE))
    and not fNetPlayers[I].Dropped then
    begin
      Inc(total);
      if fNetPlayers[I].VotedYes then
        Inc(votedYes);
    end;
  Result := (total div 2) + 1 - votedYes;
end;


//All human players who are not dropped are spectators
function TKMNetPlayersList.HasOnlySpectators: Boolean;
var
  I: Integer;
begin
  for I := 1 to fCount do
    if (fNetPlayers[I].PlayerNetType = nptHuman) and (fNetPlayers[I].StartLocation <> LOC_SPECTATE)
    and not fNetPlayers[I].Dropped then
    begin
      Result := False;
      Exit;
    end;
  Result := True;
end;


procedure TKMNetPlayersList.SetDownloadAborted;
var
  I: Integer;
begin
  for I := 1 to fCount do
    fNetPlayers[I].DownloadInPRogress := False;
end;


procedure TKMNetPlayersList.ResetLocAndReady;
var
  I: Integer;
begin
  for I := 1 to fCount do
  begin
    if fNetPlayers[I].PlayerNetType = nptHuman then
      fNetPlayers[I].HasMapOrSave := False;

    if fNetPlayers[I].StartLocation <> LOC_SPECTATE then
      fNetPlayers[I].StartLocation := LOC_RANDOM;

    //AI/closed players are always ready, spectator ready status is not reset by map change
    if (fNetPlayers[I].PlayerNetType = nptHuman) and (fNetPlayers[I].StartLocation <> LOC_SPECTATE) then
      fNetPlayers[I].ReadyToStart := false;
  end;
end;


procedure TKMNetPlayersList.ResetReady;
var
  I: Integer;
begin
  for I := 1 to fCount do
    //AI/closed players are always ready, spectator ready status is not reset by options change
    if (fNetPlayers[I].PlayerNetType = nptHuman) and (fNetPlayers[I].StartLocation <> LOC_SPECTATE) then
      fNetPlayers[I].ReadyToStart := False;
end;


procedure TKMNetPlayersList.ResetReadyToPlay;
var
  I: Integer;
begin
  for I := 1 to fCount do
    fNetPlayers[I].ReadyToPlay := False;
end;


procedure TKMNetPlayersList.ResetReadyToReturnToLobby;
var
  I: Integer;
begin
  for I := 1 to fCount do
    fNetPlayers[I].ReadyToReturnToLobby := False;
end;


procedure TKMNetPlayersList.ResetVote;
var
  I: Integer;
begin
  VoteActive := False;
  for I := 1 to fCount do
    fNetPlayers[I].VotedYes := False;
end;


procedure TKMNetPlayersList.SetAIReady;
var
  I: Integer;
begin
  for I := 1 to fCount do
    if fNetPlayers[I].PlayerNetType in [nptComputerClassic, nptComputerAdvanced, nptClosed] then
    begin
      fNetPlayers[I].ReadyToStart := True;
      fNetPlayers[I].ReadyToPlay := True;
    end;
end;


procedure TKMNetPlayersList.RemAllAIs;
var
  I: Integer;
begin
  for I := fCount downto 1 do
    if Player[I].IsComputer then
      RemPlayer(I);
end;


procedure TKMNetPlayersList.RemDisconnectedPlayers;
var
  I: Integer;
begin
  for I := fCount downto 1 do
    if not Player[I].Connected then
      RemPlayer(I);
end;


type

  //Loc filler types
  TPlayerType = (ptHuman, ptAI, ptAdvAI);
  TPlayerTypeOrder = array[0..2] of TPlayerType;
  TPlayerTypeSet = set of TPlayerType;

  TFillOrder = record
    PT1, PT2, PT3: TPlayerType;
  end;

  TFullFillOrder = record
    FO1, FO2: TFillOrder;
    PT3: TPlayerType;
  end;

  TFFillOrdersArr = array of TFullFillOrder;

  TPlayer = record
    ID: Integer;
    PlayerType: TPlayerType;
    LocI: Integer;
    LocID: Integer;
  end;

  TPlayersArr = array of TPlayer;

  TLoc = record
    ID: Integer;
    AllowedPlayerTypes: TPlayerTypeSet;
    PlayerI: Integer;
    PlayerID: Integer;
  end;

  TLocsArr = array of TLoc;

  TLocFiller = class
  private
    fFilled: Boolean;
  public
    Players: TPlayersArr;
    Locs: TLocsArr;
    procedure AddLoc(const aLoc: TLoc);
    procedure AddPlayer(const aPlayer: TPlayer);
    function TryFillLocs: Boolean;
    function GenerateFillOrders: TFFillOrdersArr;
    function FOToStr(aFO: TFillOrder): String;
    function FFOToStr(aFO: TFullFillOrder): String;
    function LocToStr(aLoc: TLoc): String;
    function PlayerToStr(aPlayer: TPlayer): String;
    function GetLocsToSwap(aPlayerType: TPlayerType): TIntegerArray;
    function FillerToString: UnicodeString;
    procedure SwapLocsPlayers(aLocI1, aLocI2: Integer);
  end;

  function ConvertPlayerType(aNetPlayerType: TKMNetPlayerType): TPlayerType;
  begin
    case aNetPlayerType of
      nptHuman,
      nptClosed:            Result := ptHuman; //We do not care about Closed, as we dont use it here
      nptComputerClassic:   Result := ptAI;
      nptComputerAdvanced:  Result := ptAdvAI;
      else                  Result := ptHuman; //Should never happen
    end;
  end;

const
  ALL_TYPES_SET: TPlayerTypeSet = [ptHuman..ptAdvAI];


procedure TLocFiller.AddLoc(const aLoc: TLoc);
begin
  SetLength(Locs, Length(Locs) + 1);
  Locs[Length(Locs) - 1] := aLoc;
end;


procedure TLocFiller.AddPlayer(const aPlayer: TPlayer);
begin
  SetLength(Players, Length(Players) + 1);
  Players[Length(Players) - 1] := aPlayer;
end;


function TLocFiller.FOToStr(aFO: TFillOrder): String;
begin
  Result := GetEnumName(TypeInfo(TPlayerType), Integer(aFO.PT1));
  Result := Result + ' ' + GetEnumName(TypeInfo(TPlayerType), Integer(aFO.PT2));
  Result := Result + ' ' + GetEnumName(TypeInfo(TPlayerType), Integer(aFO.PT3));
end;


function TLocFiller.FFOToStr(aFO: TFullFillOrder): String;
begin
  Result := FOToStr(aFO.FO1) + '; ' + FOToStr(aFO.FO2) + '; ' + GetEnumName(TypeInfo(TPlayerType), Integer(aFO.PT3));
end;


function TLocFiller.LocToStr(aLoc: TLoc): String;
var
  PT: TPlayerType;
  pTypesStr: String;
begin
  pTypesStr := '';
  for PT in aLoc.AllowedPlayerTypes do
  begin
    if pTypesStr <> '' then
      pTypesStr := pTypesStr + ',';
    pTypesStr := pTypesStr + GetEnumName(TypeInfo(TPlayerType), Integer(PT));
  end;
  Result := Format('Loc%d [%s]', [aLoc.ID, pTypesStr]);
end;


function TLocFiller.PlayerToStr(aPlayer: TPlayer): String;
begin
  Result := Format('Player%d [%s]', [aPlayer.ID, GetEnumName(TypeInfo(TPlayerType), Integer(aPlayer.PlayerType))]);
end;


function TLocFiller.FillerToString: UnicodeString;
var
  I: Integer;
  playerStr: String;
begin
  if not fFilled then
    Result := 'Loc filler is not filled!'
  else begin
    Result := 'Loc filler: ';
    for I := 0 to High(Locs) do
    begin
      if Locs[I].PlayerID = -1 then
        playerStr := '-'
      else
        playerStr := PlayerToStr(Players[Locs[I].PlayerI]);
      Result := Format('%s[%s: %s]; ', [Result, LocToStr(Locs[I]), playerStr]);
    end;
  end;
end;


//Generates this:
//FO1.PT1 PT2  PT3      FO1.PT1 PT2  PT3      PT3
//ptHuman ptAI ptAdvAI; ptAI ptHuman ptAdvAI; ptAdvAI
//ptHuman ptAI ptAdvAI; ptAI ptAdvAI ptHuman; ptAdvAI
//ptHuman ptAI ptAdvAI; ptAdvAI ptHuman ptAI; ptAI
//ptHuman ptAI ptAdvAI; ptAdvAI ptAI ptHuman; ptAI
//ptHuman ptAdvAI ptAI; ptAI ptHuman ptAdvAI; ptAdvAI
//ptHuman ptAdvAI ptAI; ptAI ptAdvAI ptHuman; ptAdvAI
//ptHuman ptAdvAI ptAI; ptAdvAI ptHuman ptAI; ptAI
//ptHuman ptAdvAI ptAI; ptAdvAI ptAI ptHuman; ptAI
//ptAI ptHuman ptAdvAI; ptHuman ptAI ptAdvAI; ptAdvAI
//ptAI ptHuman ptAdvAI; ptHuman ptAdvAI ptAI; ptAdvAI
//ptAI ptHuman ptAdvAI; ptAdvAI ptHuman ptAI; ptHuman
//ptAI ptHuman ptAdvAI; ptAdvAI ptAI ptHuman; ptHuman
//ptAI ptAdvAI ptHuman; ptHuman ptAI ptAdvAI; ptAdvAI
//ptAI ptAdvAI ptHuman; ptHuman ptAdvAI ptAI; ptAdvAI
//ptAI ptAdvAI ptHuman; ptAdvAI ptHuman ptAI; ptHuman
//ptAI ptAdvAI ptHuman; ptAdvAI ptAI ptHuman; ptHuman
//ptAdvAI ptHuman ptAI; ptHuman ptAI ptAdvAI; ptAI
//ptAdvAI ptHuman ptAI; ptHuman ptAdvAI ptAI; ptAI
//ptAdvAI ptHuman ptAI; ptAI ptHuman ptAdvAI; ptHuman
//ptAdvAI ptHuman ptAI; ptAI ptAdvAI ptHuman; ptHuman
//ptAdvAI ptAI ptHuman; ptHuman ptAI ptAdvAI; ptAI
//ptAdvAI ptAI ptHuman; ptHuman ptAdvAI ptAI; ptAI
//ptAdvAI ptAI ptHuman; ptAI ptHuman ptAdvAI; ptHuman
//ptAdvAI ptAI ptHuman; ptAI ptAdvAI ptHuman; ptHuman
function TLocFiller.GenerateFillOrders: TFFillOrdersArr;
var
  RI, I: Integer;
  PJ,PK,PM,PN,PL,PO: TPlayerType;
  Filled1Copy, Filled1,
  Filled2Copy, Filled2,
  Filled3Copy, Filled3: TPlayerTypeSet;
begin
  SetLength(Result, 6*4);
  RI := 0;

  Filled1Copy := ALL_TYPES_SET;
  for I := 0 to 2 do
  begin
    Result[RI].FO1.PT1 := TPlayerType(I);
    Filled1 := ALL_TYPES_SET - [TPlayerType(I)];
    for PJ in Filled1 do
    begin
      Filled1Copy := Filled1;
      Result[RI].FO1.PT2 := PJ;
      Exclude(Filled1Copy, PJ);
      for PK in Filled1Copy do
      begin
        Result[RI].FO1.PT3 := PK;
        Filled2 := ALL_TYPES_SET - [TPlayerType(I)];
        for PM in Filled2 do
        begin
          Filled2Copy := Filled2;
          Result[RI].FO2.PT1 := PM;
          Exclude(Filled2Copy, PM);
          for PN in Filled2Copy do
            Result[RI].PT3 := PN;
          Filled3 := ALL_TYPES_SET - [PM];
          for PL in Filled3 do
          begin
            Filled3Copy := Filled3;
            Result[RI].FO2.PT2 := PL;
            Exclude(Filled3Copy, PL);
            for PO in Filled3Copy do
            begin
              Result[RI].FO2.PT3 := PO;
              Inc(RI);
              if RI < Length(Result) then
                Result[RI] := Result[RI - 1];
            end;
          end;
        end;
      end;
    end;
  end;
end;


function TLocFiller.TryFillLocs: Boolean;

  procedure TakeLoc(aPlayerI, aLocJ: Integer; var aPlayers: TPlayersArr; var aLocs: TLocsArr);
  begin
    aLocs[aLocJ].PlayerI := aPlayerI;
    aLocs[aLocJ].PlayerID := aPlayers[aPlayerI].ID;
    aPlayers[aPlayerI].LocID := aLocs[aLocJ].ID;
    aPlayers[aPlayerI].LocI := aLocJ;
  end;

  function TryTakeLoc(aPlayerI: Integer; aAllowedPlayerTypes: TPlayerTypeSet; var aPlayers: TPlayersArr;
                       var aLocs: TLocsArr; aTakeFirst: Boolean = False): Boolean;
  var
    J: Integer;
  begin
    Result := False;
    for J := 0 to High(aLocs) do
    begin
      if (aLocs[J].PlayerID = -1)
        and (aPlayers[aPlayerI].LocID = -1)
        and (aTakeFirst or (aLocs[J].AllowedPlayerTypes = aAllowedPlayerTypes))
        and (aPlayers[aPlayerI].PlayerType in aLocs[J].AllowedPlayerTypes) then
      begin
        TakeLoc(aPlayerI,J,aPlayers,aLocs);
        Result := True;
        Exit;
      end;
    end;
  end;

  procedure Fill(aFO: TFillOrder; var aPlayers: TPlayersArr; var aLocs: TLocsArr);
  var
    I: Integer;
  begin
    //ABC fill order
    for I := 0 to High(aPlayers) do
      if (aPlayers[I].PlayerType = aFO.PT1) then
      begin
        if not (TryTakeLoc(I, [aFO.PT1], aPlayers, aLocs)             //First A-only
          or TryTakeLoc(I, [aFO.PT1, aFO.PT2], aPlayers, aLocs)       //then A+B
          or TryTakeLoc(I, [aFO.PT1, aFO.PT3], aPlayers, aLocs)) then //then A+C
          TryTakeLoc(I, [aFO.PT1, aFO.PT2, aFO.PT3], aPlayers, aLocs);//then A+B+C
      end;
  end;

  function IsFilled(aPlayers: TPlayersArr; aLocs: TLocsArr): Boolean;
  var
    I: Integer;
  begin
    Result := True;
    for I := 0 to High(aPlayers) do
      Result := Result and (aPlayers[I].LocID <> -1);
  end;

var
  I,J: Integer;
  fillOrders: TFFillOrdersArr;
  playersC: TPlayersArr;
  locsC: TLocsArr;
begin
  //No players means there is nothing to randomize
  if Length(Players) = 0 then
  begin
    fFilled := True;
    Exit(True);
  end;

  Result := False;
  fFilled := False;
  if (Length(Players) > Length(Locs)) or (Length(Locs) = 0) then
    Exit;

  //Generate all possible fill orders
  //Task:
  //we have number of balls (players) with different colors (player type)
  //also we have number of baskets(locs), colored if 1,2 or 3 ball colors (allowed player types)
  //every ball can go to 1 basket with allowed color
  //How to fill them?

  //Simple solution - try all possible ways to fill, and if we find solution, then its good enough.
  //First Fill order - Abc means first we put A ball to all A only baskets, then A+B basket, then A+C and then A+B+C
  //Second fill order - Bac, which goes after first - same, but for the B ball, so we fill all remaining baskets:
  // first B ball goes to B-only baskets, then B+A then B+C then B+A+C
  //And the last - goes C ball, whereever they can fit

  //Altogether there are 24 different fill orders
  fillOrders := GenerateFillOrders;

  for I := 0 to Length(fillOrders) - 1 do
  begin
    playersC := Copy(Players, 0, MaxInt);
    locsC := Copy(Locs, 0, MaxInt);

    for J := 0 to High(playersC) do
      playersC[J].LocID := -1;

    for J := 0 to High(locsC) do
      locsC[J].PlayerID := -1;

    //First ABC
    Fill(fillOrders[I].FO1, playersC, locsC);
    //Second BAC
    Fill(fillOrders[I].FO2, playersC, locsC);
    for J := 0 to High(playersC) do
      if (playersC[J].PlayerType = fillOrders[I].PT3) then
      begin
        //Last C
        TryTakeLoc(J, [], playersC, locsC, True);
        Break;
      end;

    if IsFilled(playersC, locsC) then
    begin
      Players := Copy(playersC, 0, MaxInt);
      Locs := Copy(locsC, 0, MaxInt);
      Result := True;
      fFilled := True;
      Exit;
    end;
  end;
end;


function TLocFiller.GetLocsToSwap(aPlayerType: TPlayerType): TIntegerArray;
var
  cnt: Integer;

  procedure AddLoc(aI: Integer);
  begin
    if not ArrayContains(aI, Result) then
    begin
      Result[cnt] := aI;
      Inc(cnt);
    end;
  end;

var
  I, J: Integer;
begin
  SetLength(Result, 0);

  if not fFilled then
    Exit;

  cnt := 0;

  SetLength(Result, Length(Locs));
  for I := Low(Result) to High(Result) do
    Result[I] := -100; //Init with some impossible value for loc number (but 0 loc exists)

  //Get locs to swap randomly
  for I := 0 to High(Locs) do
    if ((Locs[I].PlayerID <> -1) and (Players[Locs[I].PlayerI].PlayerType = aPlayerType)) // Taken locs with same type
      or ((Locs[I].PlayerID = -1) and (aPlayerType in Locs[I].AllowedPlayerTypes)) then   // Empty locs which is allowed to take
      AddLoc(I);
  //Find all locs, where both player types could be. Add them both then
  for I := 0 to High(Locs) do
    for J := I + 1 to High(Locs) do
      if (Locs[I].PlayerID <> -1)
        and (Locs[J].PlayerID <> -1)
        and (Players[Locs[I].PlayerI].PlayerType = aPlayerType)
        and (Players[Locs[I].PlayerI].PlayerType in Locs[I].AllowedPlayerTypes)
        and (Players[Locs[J].PlayerI].PlayerType in Locs[I].AllowedPlayerTypes)
        and (Players[Locs[I].PlayerI].PlayerType in Locs[J].AllowedPlayerTypes)
        and (Players[Locs[J].PlayerI].PlayerType in Locs[J].AllowedPlayerTypes) then
      begin
        AddLoc(I);
        AddLoc(J);
      end;

  SetLength(Result, cnt);
end;


procedure TLocFiller.SwapLocsPlayers(aLocI1, aLocI2: Integer);
begin
  if Locs[aLocI1].PlayerID <> -1 then
    Players[Locs[aLocI1].PlayerI].LocID := Locs[aLocI2].ID;

  if Locs[aLocI2].PlayerID <> -1 then
    Players[Locs[aLocI2].PlayerI].LocID := Locs[aLocI1].ID;

  SwapInt(Locs[aLocI1].PlayerI, Locs[aLocI2].PlayerI);
  SwapInt(Locs[aLocI1].PlayerID, Locs[aLocI2].PlayerID);
end;


//Convert undefined/random start locations to fixed and assign random colors
//Remove odd players
function TKMNetPlayersList.ValidateSetup(var aHumanUsableLocs, aAIUsableLocs, aAdvancedAIUsableLocs: TKMHandIDArray;
                                         var aFixedLocsColors: TKMCardinalArray; out ErrorMsg: UnicodeString): Boolean;
  function IsHumanLoc(aLoc: Byte): Boolean;
  var
    I: Integer;
  begin
    Result := False;
    for I := 0 to Length(aHumanUsableLocs)-1 do
      if aLoc = aHumanUsableLocs[I]+1 then
      begin
        Result := True;
        Exit;
      end;
  end;

  function IsAILoc(aLoc: Byte): Boolean;
  var
    I: Integer;
  begin
    Result := False;
    for I := 0 to Length(aAIUsableLocs)-1 do
      if aLoc = aAIUsableLocs[I]+1 then
      begin
        Result := True;
        Exit;
      end;
  end;

  function IsAdvAILoc(aLoc: Byte): Boolean;
  var
    I: Integer;
  begin
    Result := False;
    for I := 0 to Length(aAdvancedAIUsableLocs)-1 do
      if aLoc = aAdvancedAIUsableLocs[I]+1 then
      begin
        Result := True;
        Exit;
      end;
  end;

var
  I, K, J: Integer;
  usedLoc: array[1..MAX_HANDS] of Boolean;
  TeamLocs: array of Integer;
  locFiller: TLocFiller;
  player: TPlayer;
  PT: TPlayerType;
  loc: TLoc;
  locsArr: TIntegerArray;
begin
  if not AllReady then
  begin
    ErrorMsg := gResTexts[TX_LOBBY_EVERYONE_NOT_READY];
    Result := False;
    Exit;
  end;

  for I := 1 to fCount do
    if fNetPlayers[I].IsSpectator then
      Assert((fNetPlayers[I].PlayerNetType = nptHuman), 'Only humans can spectate');

  //All wrong start locations will be reset to random (fallback since UI should block that anyway)
  for I := 1 to fCount do
    if (fNetPlayers[I].StartLocation <> LOC_RANDOM) and (fNetPlayers[I].StartLocation <> LOC_SPECTATE) then
      if (fNetPlayers[I].IsHuman and not IsHumanLoc(fNetPlayers[I].StartLocation))
        or (fNetPlayers[I].IsClassicComputer and not IsAILoc(fNetPlayers[I].StartLocation))
        or (fNetPlayers[I].IsAdvancedComputer and not IsAdvAILoc(fNetPlayers[I].StartLocation)) then
        fNetPlayers[I].StartLocation := LOC_RANDOM;

  for I := 1 to MAX_HANDS do
    usedLoc[I] := False;


  locFiller := TLocFiller.Create;
  try
    //Remember all used locations and drop duplicates (fallback since UI should block that anyway)
    for I := 1 to fCount do
      if (fNetPlayers[I].StartLocation <> LOC_RANDOM) and (fNetPlayers[I].StartLocation <> LOC_SPECTATE) then
      begin
        if usedLoc[fNetPlayers[I].StartLocation] then
          fNetPlayers[I].StartLocation := LOC_RANDOM
        else
          usedLoc[fNetPlayers[I].StartLocation] := True;
      end
      else
      if (fNetPlayers[I].StartLocation = LOC_RANDOM) and not fNetPlayers[I].IsClosed then
      begin
        player.ID := I;
        player.LocID := -1;
        player.PlayerType := ConvertPlayerType(fNetPlayers[I].PlayerNetType);
        locFiller.AddPlayer(player);
      end;

    //Collect available locations in a list
    for I := 1 to MAX_HANDS do
      if not usedLoc[I] then
      begin
        loc.ID := I;
        loc.PlayerID := -1;
        loc.AllowedPlayerTypes := [];

        if IsHumanLoc(I) then
          Include(loc.AllowedPlayerTypes, ptHuman);
        if IsAILoc(I) then
          Include(loc.AllowedPlayerTypes, ptAI);
        if IsAdvAILoc(I) then
          Include(loc.AllowedPlayerTypes, ptAdvAI);

        //Allow to fill locs if there is human
        if (loc.AllowedPlayerTypes <> [])
          and ((ptHuman in loc.AllowedPlayerTypes) or (loc.AllowedPlayerTypes = [ptAI,ptAdvAI])) then
          locFiller.AddLoc(loc);
      end;

    //Try to fill locs with available players
    if not locFiller.TryFillLocs then
    begin
      ErrorMsg := gResTexts[TX_LOBBY_UNABLE_RANDOM_LOCS];
      Result := False;
      Exit;
    end;

    gLog.AddTime('Randomizing locs...');
    if gLog.IsDegubLogEnabled then
      gLog.LogDebug(locFiller.FillerToString);

    //Randomize all available lists (don't use KaMRandom - we want varied results and PlayerList is synced to clients before start)
    for PT := Low(TPlayerType) to High(TPlayerType) do
    begin
      locsArr := locFiller.GetLocsToSwap(PT);
      for I := 0 to High(locsArr) do
        locFiller.SwapLocsPlayers(locsArr[I], locsArr[Random(Length(locsArr))]);
    end;

    //Fill all locs
    for I := 0 to High(locFiller.Players) do
      fNetPlayers[locFiller.Players[I].ID].StartLocation := locFiller.Players[I].LocID;

    if gLog.IsDegubLogEnabled then
      gLog.LogDebug('Randomized locs: ' + locFiller.FillerToString);
  finally
    locFiller.Free;
  end;

  RemAllClosedPlayers; //Closed players are just a marker in the lobby, delete them when the game starts

  //Check for odd players
  for I := 1 to fCount do
    Assert(fNetPlayers[I].StartLocation <> LOC_RANDOM, 'Everyone should have a starting location!');

  //Shuffle locations within each team if requested
  if RandomizeTeamLocations then
    for I := 1 to MAX_TEAMS do //Each team
    begin
      SetLength(TeamLocs, 0); //Reset
      for K := 1 to fCount do
        if (fNetPlayers[K].Team = I) and not fNetPlayers[K].IsSpectator then
        begin
          SetLength(TeamLocs, Length(TeamLocs)+1);
          TeamLocs[Length(TeamLocs)-1] := fNetPlayers[K].StartLocation;
        end;
      //Shuffle the locations
      for K := 0 to Length(TeamLocs)-1 do
        SwapInt(TeamLocs[K], TeamLocs[Random(Length(TeamLocs))]);
      //Assign each location back to a player
      J := 0;
      for K := 1 to fCount do
        if (fNetPlayers[K].Team = I) and not fNetPlayers[K].IsSpectator then
        begin
          fNetPlayers[K].StartLocation := TeamLocs[J];
          Inc(J);
        end;
    end;

  ValidateColors(aFixedLocsColors);
  Result := True;
end;


//Save whole amount of data as string to be sent across network to other players
//I estimate it ~50 Bytes per player at max
//later it will be Byte array?
procedure TKMNetPlayersList.SaveToStream(aStream: TKMemoryStream);
var
  I: Integer;
begin
  aStream.Write(HostDoesSetup);
  aStream.Write(RandomizeTeamLocations);
  aStream.Write(SpectatorsAllowed);
  aStream.Write(SpectatorSlotsOpen);
  aStream.Write(VoteActive);
  aStream.Write(fCount);
  for I := 1 to fCount do
    fNetPlayers[I].Save(aStream);
end;


procedure TKMNetPlayersList.LoadFromStream(aStream: TKMemoryStream);
var
  I: Integer;
begin
  aStream.Read(HostDoesSetup);
  aStream.Read(RandomizeTeamLocations);
  aStream.Read(SpectatorsAllowed);
  aStream.Read(SpectatorSlotsOpen);
  aStream.Read(VoteActive);
  aStream.Read(fCount);
  for I := 1 to fCount do
    fNetPlayers[I].Load(aStream);
end;


function TKMNetPlayersList.GetPlayersWithIDs: UnicodeString;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to fCount do
  begin
    Result := Result + '   ' + IntToStr(I) + ': ' + fNetPlayers[I].NicknameU;
    if I < fCount then
      Result := Result + '|';
  end;
end;


end.

