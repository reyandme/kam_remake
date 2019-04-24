unit KM_NetPlayersList;
{$I KaM_Remake.inc}
interface
uses
  Classes, KromUtils, StrUtils, Math, SysUtils,
  KM_CommonClasses, KM_CommonTypes, KM_Defaults, KM_Hand, KM_ResLocales, KM_NetworkTypes;

const
  PING_COUNT = 20; //Number of pings to store and take the maximum over for latency calculation (pings are measured once per second)

type
  //Multiplayer info that is filled in Lobby before TKMPlayers are created (thats why it has many mirror fields)
  TKMNetPlayerInfo = class
  private
    fNikname: AnsiString;
    fLangCode: AnsiString;
    fIndexOnServer: TKMNetHandleIndex;
    fFlagColorID: Integer;    //Flag color, 0 means random
    fPings: array[0 .. PING_COUNT-1] of Word; //Ring buffer
    fPingPos: Byte;
    procedure SetLangCode(const aCode: AnsiString);
    function GetNiknameColored: AnsiString;
    function GetNikname: AnsiString;
    function GetNiknameColoredU: UnicodeString;
    function GetNiknameU: UnicodeString;
    function GetHandIndex: Integer;
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
    FPS: Cardinal;
    VotedYes: Boolean;
    procedure AddPing(aPing: Word);
    procedure ResetPingRecord;
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
    property Nikname: AnsiString read GetNikname; //Human player nikname (ANSI-Latin)
    property NiknameColored: AnsiString read GetNiknameColored;
    property NiknameU: UnicodeString read GetNiknameU;
    property NiknameColoredU: UnicodeString read GetNiknameColoredU;
    property LangCode: AnsiString read fLangCode write SetLangCode;
    property IndexOnServer: TKMNetHandleIndex read fIndexOnServer;
    property SetIndexOnServer: TKMNetHandleIndex write fIndexOnServer;
    function FlagColor(aDefault: Cardinal = $FF000000): Cardinal;
    property FlagColorID: Integer read fFlagColorID write fFlagColorID;
    property HandIndex: Integer read GetHandIndex;

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
  end;


  //Handles everything related to players list,
  //but knows nothing about networking nor game setup. Only players.
  TKMNetPlayersList = class
  private
    fCount: Integer;
    fNetPlayers: array [1..MAX_LOBBY_SLOTS] of TKMNetPlayerInfo;
    function GetPlayer(aIndex: Integer): TKMNetPlayerInfo;
    procedure ValidateColors;
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

    procedure AddPlayer(const aNik: AnsiString; aIndexOnServer: TKMNetHandleIndex; const aLang: AnsiString);
    procedure AddAIPlayer(aAdvancedAI: Boolean; aSlot: Integer = -1);
    procedure AddClosedPlayer(aSlot: Integer = -1);
    procedure DisconnectPlayer(aIndexOnServer: TKMNetHandleIndex);
    procedure DisconnectAllClients(const aOwnNikname: AnsiString);
    procedure DropPlayer(aIndexOnServer: TKMNetHandleIndex);
    procedure RemPlayer(aIndex: Integer);
    procedure RemServerPlayer(aIndexOnServer: TKMNetHandleIndex);
    property Player[aIndex: Integer]: TKMNetPlayerInfo read GetPlayer; default;

    //Getters
    function ServerToLocal(aIndexOnServer: TKMNetHandleIndex): Integer;
    function NiknameToLocal(const aNikname: AnsiString): Integer;
    function StartingLocToLocal(aLoc: Integer): Integer;
    function PlayerIndexToLocal(aIndex: TKMHandID): Integer;

    function CheckCanJoin(const aNik: AnsiString; aIndexOnServer: TKMNetHandleIndex): Integer;
    function CheckCanReconnect(aLocalIndex: Integer): Integer;
    function LocAvailable(aIndex: Integer): Boolean;
    function ColorAvailable(aIndex: Integer): Boolean;
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

    procedure ResetLocAndReady;
    procedure ResetReady;
    procedure ResetReadyToPlay;
    procedure ResetReadyToReturnToLobby;
    procedure ResetVote;
    procedure SetAIReady;
    procedure RemAllAIs;
    procedure RemDisconnectedPlayers;
    function ValidateSetup(const aHumanUsableLocs, aAIUsableLocs, aAdvancedAIUsableLocs: TKMHandIDArray; out ErrorMsg: UnicodeString): Boolean;

    //Import/Export
    procedure SaveToStream(aStream: TKMemoryStream); //Gets all relevant information as text string
    procedure LoadFromStream(aStream: TKMemoryStream); //Sets all relevant information
    function GetSlotNames: UnicodeString; //Gets just names as a text string seperated by |
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


function TKMNetPlayerInfo.FlagColor(aDefault: Cardinal = $FF000000): Cardinal;
begin
  if fFlagColorID <> 0 then
    Result := MP_TEAM_COLORS[fFlagColorID]
  else
    Result := aDefault; //Black by default
end;


procedure TKMNetPlayerInfo.SetLangCode(const aCode: AnsiString);
begin
  if gResLocales.IndexByCode(aCode) <> -1 then
    fLangCode := aCode;
end;


function TKMNetPlayerInfo.GetInstantPing: Word;
begin
  Result := fPings[fPingPos];
end;


function TKMNetPlayerInfo.GetMaxPing: Word;
var I: Integer; Worst: Word;
begin
  Result := 0;
  Worst := 0;
  //We should ignore the worst ping so we don't delay game input due to one ping spike
  for I := 0 to PING_COUNT - 1 do
  begin
    if fPings[I] > Worst then
    begin
      Result := Math.max(Result, Worst);
      Worst := fPings[I]
    end
    else
      Result := Math.max(Result, fPings[I]);
  end;
end;


function TKMNetPlayerInfo.IsHuman: Boolean;
begin
  Result := PlayerNetType = nptHuman;
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
    nptHuman:     Result := NiknameU;
    nptComputerClassic:  //In lobby AI players don't have numbers yet (they are added on mission start)
                  Result := gResTexts[TX_AI_PLAYER_CLASSIC];
    nptComputerAdvanced:  //In lobby AI players don't have numbers yet (they are added on mission start)
                  Result := gResTexts[TX_AI_PLAYER_ADVANCED];
    nptClosed:    Result := gResTexts[TX_LOBBY_SLOT_CLOSED];
    else          Result := NO_TEXT;
  end;
end;


function TKMNetPlayerInfo.GetNikname: AnsiString;
begin
  if IsHuman or (gHands = nil) or (HandIndex = -1) then
    Result := fNikname
  else
    Result := AnsiString(gHands[HandIndex].OwnerName);
end;


function TKMNetPlayerInfo.GetNiknameColored: AnsiString;
begin
  if FlagColorID <> 0 then
    Result := WrapColorA(Nikname, FlagColorToTextColor(FlagColor))
  else
    Result := Nikname;
end;


function TKMNetPlayerInfo.GetNiknameU: UnicodeString;
begin
  Result := UnicodeString(GetNikname);
end;


function TKMNetPlayerInfo.GetNiknameColoredU: UnicodeString;
begin
  Result := UnicodeString(GetNiknameColored);
end;


function TKMNetPlayerInfo.GetHandIndex: Integer;
begin
  Result := -1;
  if StartLocation > 0 then
    Result := StartLocation - 1;
end;


procedure TKMNetPlayerInfo.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.ReadA(fNikname);
  LoadStream.ReadA(fLangCode);
  LoadStream.Read(SmallInt(fIndexOnServer));
  LoadStream.Read(PlayerNetType, SizeOf(PlayerNetType));
  LoadStream.Read(fFlagColorID);
  LoadStream.Read(StartLocation);
  LoadStream.Read(Team);
  LoadStream.Read(ReadyToStart);
  LoadStream.Read(ReadyToPlay);
  LoadStream.Read(ReadyToReturnToLobby);
  LoadStream.Read(HasMapOrSave);
  LoadStream.Read(Connected);
  LoadStream.Read(Dropped);
  LoadStream.Read(VotedYes);
end;


procedure TKMNetPlayerInfo.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.WriteA(fNikname);
  SaveStream.WriteA(fLangCode);
  SaveStream.Write(fIndexOnServer);
  SaveStream.Write(PlayerNetType, SizeOf(PlayerNetType));
  SaveStream.Write(fFlagColorID);
  SaveStream.Write(StartLocation);
  SaveStream.Write(Team);
  SaveStream.Write(ReadyToStart);
  SaveStream.Write(ReadyToPlay);
  SaveStream.Write(ReadyToReturnToLobby);
  SaveStream.Write(HasMapOrSave);
  SaveStream.Write(Connected);
  SaveStream.Write(Dropped);
  SaveStream.Write(VotedYes);
end;


{ TKMNetPlayersList }
constructor TKMNetPlayersList.Create;
var
  I: Integer;
begin
  inherited;
  SpectatorSlotsOpen := MAX_LOBBY_SPECTATORS;

  for I := 1 to MAX_LOBBY_SLOTS do
    fNetPlayers[I] := TKMNetPlayerInfo.Create;
end;


destructor TKMNetPlayersList.Destroy;
var I: Integer;
begin
  for I := 1 to MAX_LOBBY_SLOTS do
    fNetPlayers[I].Free;

  inherited;
end;


procedure TKMNetPlayersList.Clear;
begin
  HostDoesSetup := False;
  RandomizeTeamLocations := False;
  SpectatorsAllowed := False;
  SpectatorSlotsOpen := MAX_LOBBY_SPECTATORS;
  ResetVote;
  fCount := 0;
end;


function TKMNetPlayersList.GetPlayer(aIndex: Integer): TKMNetPlayerInfo;
begin
  Result := fNetPlayers[aIndex];
end;


procedure TKMNetPlayersList.ValidateColors;
var
  I,K,ColorCount: Integer;
  UsedColor: array [0..MP_COLOR_COUNT] of Boolean; //0 means Random
  AvailableColor: array [1..MP_COLOR_COUNT] of Byte;
begin
  //All wrong colors will be reset to random
  for I := 1 to fCount do
    if not Math.InRange(fNetPlayers[I].FlagColorID, 0, MP_COLOR_COUNT) then
      fNetPlayers[I].FlagColorID := 0;

  FillChar(UsedColor, SizeOf(UsedColor), #0);

  //Remember all used colors and drop duplicates
  for I := 1 to fCount do
    if UsedColor[fNetPlayers[I].FlagColorID] then
      fNetPlayers[I].FlagColorID := 0
    else
      UsedColor[fNetPlayers[I].FlagColorID] := true;

  //Collect available colors
  ColorCount := 0;
  for I := 1 to MP_COLOR_COUNT do
  if not UsedColor[I] then
  begin
    Inc(ColorCount);
    AvailableColor[ColorCount] := I;
  end;

  //Randomize (don't use KaMRandom - we want varied results and PlayerList is synced to clients before start)
  for I := 1 to ColorCount do
    SwapInt(AvailableColor[I], AvailableColor[Random(ColorCount)+1]);

  //Allocate available colors
  K := 0;
  for I := 1 to fCount do
    if fNetPlayers[I].FlagColorID = 0 then
    begin
      Inc(K);
      if K <= ColorCount then
        fNetPlayers[I].FlagColorID := AvailableColor[K];
    end;

  //Check for odd players
  for I := 1 to fCount do
    Assert(fNetPlayers[I].FlagColorID <> 0, 'Everyone should have a color now!');
end;


procedure TKMNetPlayersList.RemAllClosedPlayers;
var
  I: Integer;
begin
  for I := fCount downto 1 do
    if Player[I].IsClosed then
      RemPlayer(I);
end;


procedure TKMNetPlayersList.AddPlayer(const aNik: AnsiString; aIndexOnServer: TKMNetHandleIndex; const aLang: AnsiString);
begin
  Assert(fCount <= MAX_LOBBY_SLOTS, 'Can''t add player');
  Inc(fCount);
  fNetPlayers[fCount].fNikname := aNik;
  fNetPlayers[fCount].fLangCode := aLang;
  fNetPlayers[fCount].fIndexOnServer := aIndexOnServer;
  fNetPlayers[fCount].PlayerNetType := nptHuman;
  fNetPlayers[fCount].Team := 0;
  fNetPlayers[fCount].FlagColorID := 0;
  fNetPlayers[fCount].ReadyToStart := false;
  fNetPlayers[fCount].HasMapOrSave := false;
  fNetPlayers[fCount].ReadyToPlay := false;
  fNetPlayers[fCount].ReadyToReturnToLobby := false;
  fNetPlayers[fCount].Connected := true;
  fNetPlayers[fCount].Dropped := false;
  fNetPlayers[fCount].ResetPingRecord;
  //Check if this player must go in a spectator slot
  if fCount - GetSpectatorCount > MAX_LOBBY_PLAYERS then
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
  fNetPlayers[aSlot].fNikname := '';
  fNetPlayers[aSlot].fLangCode := '';
  fNetPlayers[aSlot].fIndexOnServer := -1;
  if aAdvancedAI then
    fNetPlayers[aSlot].PlayerNetType := nptComputerAdvanced
  else
    fNetPlayers[aSlot].PlayerNetType := nptComputerClassic;
  fNetPlayers[aSlot].Team := 0;
  fNetPlayers[aSlot].FlagColorID := 0;
  fNetPlayers[aSlot].StartLocation := 0;
  fNetPlayers[aSlot].ReadyToStart := True;
  fNetPlayers[aSlot].HasMapOrSave := True;
  fNetPlayers[aSlot].ReadyToPlay := True;
  fNetPlayers[aSlot].Connected := True;
  fNetPlayers[aSlot].Dropped := False;
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
  fNetPlayers[aSlot].fNikname := '';
  fNetPlayers[aSlot].fLangCode := '';
  fNetPlayers[aSlot].fIndexOnServer := -1;
  fNetPlayers[aSlot].PlayerNetType := nptClosed;
  fNetPlayers[aSlot].Team := 0;
  fNetPlayers[aSlot].FlagColorID := 0;
  fNetPlayers[aSlot].StartLocation := 0;
  fNetPlayers[aSlot].ReadyToStart := True;
  fNetPlayers[aSlot].HasMapOrSave := True;
  fNetPlayers[aSlot].ReadyToPlay := True;
  fNetPlayers[aSlot].Connected := True;
  fNetPlayers[aSlot].Dropped := False;
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
procedure TKMNetPlayersList.DisconnectAllClients(const aOwnNikname: AnsiString);
var
  I: Integer;
begin
  for I := 1 to fCount do
    if (fNetPlayers[I].IsHuman) and (fNetPlayers[I].Nikname <> aOwnNikname) then
      fNetPlayers[I].Connected := False;
end;


//Set player to no longer be on the server, but do not remove their assets from the game
procedure TKMNetPlayersList.DropPlayer(aIndexOnServer: TKMNetHandleIndex);
var
  ID: Integer;
begin
  ID := ServerToLocal(aIndexOnServer);
  Assert(ID <> -1, 'Cannot drop player');
  fNetPlayers[ID].Connected := false;
  fNetPlayers[ID].Dropped := true;
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
    begin
      Result := I;
      Exit;
    end;
end;


//Networking needs to convert Nikname to local index in players list
function TKMNetPlayersList.NiknameToLocal(const aNikname: AnsiString): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 1 to fCount do
    if fNetPlayers[I].fNikname = aNikname then
      Result := I;
end;


//Convert known starting location to local index in players list
function TKMNetPlayersList.StartingLocToLocal(aLoc: Integer): Integer;
var I: Integer;
begin
  Result := -1;
  for I := 1 to fCount do
    if fNetPlayers[I].StartLocation = aLoc then
      Result := I;
end;


function TKMNetPlayersList.PlayerIndexToLocal(aIndex: TKMHandID): Integer;
var I: Integer;
begin
  Result := -1;
  for I := 1 to Count do
    if (aIndex = fNetPlayers[I].HandIndex) then
      Result := I;
end;


//See if player can join our game
function TKMNetPlayersList.CheckCanJoin(const aNik: AnsiString; aIndexOnServer: TKMNetHandleIndex): Integer;
begin
  if fCount >= MAX_LOBBY_SLOTS then
    Result := TX_NET_ROOM_FULL
  else
  if ServerToLocal(aIndexOnServer) <> -1 then
    Result := TX_NET_SAME_NAME
  else
  if NiknameToLocal(aNik) <> -1 then
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


function TKMNetPlayersList.ColorAvailable(aIndex: Integer): Boolean;
var
  I: Integer;
begin
  Result := True;
  if aIndex = 0 then Exit;

  for I := 1 to fCount do
    Result := Result and (aIndex <> fNetPlayers[I].FlagColorID);
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
  I: Integer; Highest, Highest2, PlayerPing: Word;
begin
  Highest := 0;
  Highest2 := 0;
  for I := 1 to fCount do
    if fNetPlayers[I].Connected and fNetPlayers[I].IsHuman then
    begin
      PlayerPing := fNetPlayers[I].GetMaxPing;
      if PlayerPing > Highest then
        Highest := PlayerPing
      else
        if PlayerPing > Highest2 then
          Highest2 := PlayerPing;
    end;
  Result := min(Highest + Highest2, High(Word));
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
  I, VotedYes, Total: Integer;
  OnlySpecsLeft: Boolean;
begin
  Total := 0;
  VotedYes := 0;
  OnlySpecsLeft := HasOnlySpectators; //Store value locally
  for I := 1 to fCount do
    if (fNetPlayers[I].PlayerNetType = nptHuman)
    and (OnlySpecsLeft or (fNetPlayers[I].StartLocation <> LOC_SPECTATE))
    and not fNetPlayers[I].Dropped then
    begin
      Inc(Total);
      if fNetPlayers[I].VotedYes then
        Inc(VotedYes);
    end;
  Result := (Total div 2) + 1 - VotedYes;
end;


//All human players who are not dropped are spectators
function TKMNetPlayersList.HasOnlySpectators: Boolean;
var I: Integer;
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


procedure TKMNetPlayersList.ResetLocAndReady;
var I: Integer;
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
var I: Integer;
begin
  for I := 1 to fCount do
    //AI/closed players are always ready, spectator ready status is not reset by options change
    if (fNetPlayers[I].PlayerNetType = nptHuman) and (fNetPlayers[I].StartLocation <> LOC_SPECTATE) then
      fNetPlayers[I].ReadyToStart := False;
end;


procedure TKMNetPlayersList.ResetReadyToPlay;
var I: Integer;
begin
  for I := 1 to fCount do
    fNetPlayers[I].ReadyToPlay := False;
end;


procedure TKMNetPlayersList.ResetReadyToReturnToLobby;
var I: Integer;
begin
  for I := 1 to fCount do
    fNetPlayers[I].ReadyToReturnToLobby := False;
end;


procedure TKMNetPlayersList.ResetVote;
var I: Integer;
begin
  VoteActive := False;
  for I := 1 to fCount do
    fNetPlayers[I].VotedYes := False;
end;


procedure TKMNetPlayersList.SetAIReady;
var I: Integer;
begin
  for I := 1 to fCount do
    if fNetPlayers[I].PlayerNetType in [nptComputerClassic, nptComputerAdvanced, nptClosed] then
    begin
      fNetPlayers[I].ReadyToStart := True;
      fNetPlayers[I].ReadyToPlay := True;
    end;
end;


procedure TKMNetPlayersList.RemAllAIs;
var I: Integer;
begin
  for I := fCount downto 1 do
    if Player[I].IsComputer then
      RemPlayer(I);
end;


procedure TKMNetPlayersList.RemDisconnectedPlayers;
var I: Integer;
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
  PTypesStr: String;
begin
  PTypesStr := '';
  for PT in aLoc.AllowedPlayerTypes do
  begin
    if PTypesStr <> '' then
      PTypesStr := PTypesStr + ',';
    PTypesStr := PTypesStr + GetEnumName(TypeInfo(TPlayerType), Integer(PT));
  end;
  Result := Format('Loc%d [%s]', [aLoc.ID, PTypesStr]);
end;


function TLocFiller.PlayerToStr(aPlayer: TPlayer): String;
begin
  Result := Format('Player%d [%s]', [aPlayer.ID, GetEnumName(TypeInfo(TPlayerType), Integer(aPlayer.PlayerType))]);
end;


function TLocFiller.FillerToString: UnicodeString;
var
  I: Integer;
  PlayerStr: String;
begin
  if not fFilled then
    Result := 'Loc filler is not filled!'
  else begin
    Result := 'Loc filler: ';
    for I := 0 to High(Locs) do
    begin
      if Locs[I].PlayerID = -1 then
        PlayerStr := '-'
      else
        PlayerStr := PlayerToStr(Players[Locs[I].PlayerI]);
      Result := Format('%s[%s: %s]; ', [Result, LocToStr(Locs[I]), PlayerStr]);
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
  FillOrders: TFFillOrdersArr;
  PlayersC: TPlayersArr;
  LocsC: TLocsArr;
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

  //Simple solution - try all possible ways to fill, and if we find solution, then its good enought.
  //First Fill order - Abc means first we put A ball to all A only baskets, then A+B basket, then A+C and then A+B+C
  //Second fill order - Bac, which goes after first - same, but for the B ball, so we fill all remaining baskets:
  // first B ball goes to B-only baskets, then B+A then B+C then B+A+C
  //And the last - goes C ball, whereever they can fit

  //Altogether there are 24 different fill orders
  FillOrders := GenerateFillOrders;

  for I := 0 to Length(FillOrders) - 1 do
  begin
    PlayersC := Copy(Players, 0, MaxInt);
    LocsC := Copy(Locs, 0, MaxInt);

    for J := 0 to High(PlayersC) do
      PlayersC[J].LocID := -1;

    for J := 0 to High(LocsC) do
      LocsC[J].PlayerID := -1;

    //First ABC
    Fill(FillOrders[I].FO1, PlayersC, LocsC);
    //Second BAC
    Fill(FillOrders[I].FO2, PlayersC, LocsC);
    for J := 0 to High(PlayersC) do
      if (PlayersC[J].PlayerType = FillOrders[I].PT3) then
      begin
        //Last C
        TryTakeLoc(J, [], PlayersC, LocsC, True);
        Break;
      end;

    if IsFilled(PlayersC, LocsC) then
    begin
      Players := Copy(PlayersC, 0, MaxInt);
      Locs := Copy(LocsC, 0, MaxInt);
      Result := True;
      fFilled := True;
      Exit;
    end;
  end;
end;


function TLocFiller.GetLocsToSwap(aPlayerType: TPlayerType): TIntegerArray;
var
  Cnt: Integer;

  procedure AddLoc(aI: Integer);
  begin
    if not ArrayContains(aI, Result) then
    begin
      Result[Cnt] := aI;
      Inc(Cnt);
    end;
  end;

var
  I, J: Integer;
begin
  SetLength(Result, 0);

  if not fFilled then
    Exit;

  Cnt := 0;

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

  SetLength(Result, Cnt);
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
function TKMNetPlayersList.ValidateSetup(const aHumanUsableLocs, aAIUsableLocs, aAdvancedAIUsableLocs: TKMHandIDArray;
                                         out ErrorMsg: UnicodeString): Boolean;
  function IsHumanLoc(aLoc: Byte): Boolean;
  var I: Integer;
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
  var I: Integer;
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
  var I: Integer;
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
  UsedLoc: array[1..MAX_HANDS] of Boolean;
  TeamLocs: array of Integer;
  LocFiller: TLocFiller;
  Player: TPlayer;
  PT: TPlayerType;
  Loc: TLoc;
  LocsArr: TIntegerArray;
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
    UsedLoc[I] := False;


  LocFiller := TLocFiller.Create;
  try
    //Remember all used locations and drop duplicates (fallback since UI should block that anyway)
    for I := 1 to fCount do
      if (fNetPlayers[I].StartLocation <> LOC_RANDOM) and (fNetPlayers[I].StartLocation <> LOC_SPECTATE) then
      begin
        if UsedLoc[fNetPlayers[I].StartLocation] then
          fNetPlayers[I].StartLocation := LOC_RANDOM
        else
          UsedLoc[fNetPlayers[I].StartLocation] := True;
      end
      else
      if (fNetPlayers[I].StartLocation = LOC_RANDOM) and not fNetPlayers[I].IsClosed then
      begin
        Player.ID := I;
        Player.LocID := -1;
        Player.PlayerType := ConvertPlayerType(fNetPlayers[I].PlayerNetType);
        LocFiller.AddPlayer(Player);
      end;

    //Collect available locations in a list
    for I := 1 to MAX_HANDS do
      if not UsedLoc[I] then
      begin
        Loc.ID := I;
        Loc.PlayerID := -1;
        Loc.AllowedPlayerTypes := [];

        if IsHumanLoc(I) then
          Include(Loc.AllowedPlayerTypes, ptHuman);
        if IsAILoc(I) then
          Include(Loc.AllowedPlayerTypes, ptAI);
        if IsAdvAILoc(I) then
          Include(Loc.AllowedPlayerTypes, ptAdvAI);

        //Allow to fill locs if there is human
        if (Loc.AllowedPlayerTypes <> [])
          and ((ptHuman in Loc.AllowedPlayerTypes) or (Loc.AllowedPlayerTypes = [ptAI,ptAdvAI])) then
          LocFiller.AddLoc(Loc);
      end;

    //Try to fill locs with available players
    if not LocFiller.TryFillLocs then
    begin
      ErrorMsg := gResTexts[TX_LOBBY_UNABLE_RANDOM_LOCS];
      Result := False;
      Exit;
    end;

    RemAllClosedPlayers; //Closed players are just a marker in the lobby, delete them when the game starts

    gLog.AddTime('Randomizing locs...');
    if gLog.IsDegubLogEnabled then
      gLog.LogDebug(LocFiller.FillerToString);

    //Randomize all available lists (don't use KaMRandom - we want varied results and PlayerList is synced to clients before start)
    for PT := Low(TPlayerType) to High(TPlayerType) do
    begin
      LocsArr := LocFiller.GetLocsToSwap(PT);
      for I := 0 to High(LocsArr) do
        LocFiller.SwapLocsPlayers(LocsArr[I], LocsArr[Random(Length(LocsArr))]);
    end;

    //Fill all locs
    for I := 0 to High(LocFiller.Players) do
      fNetPlayers[LocFiller.Players[I].ID].StartLocation := LocFiller.Players[I].LocID;

    if gLog.IsDegubLogEnabled then
      gLog.LogDebug('Randomized locs: ' + LocFiller.FillerToString);
  finally
    LocFiller.Free;
  end;

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

  ValidateColors;
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


function TKMNetPlayersList.GetSlotNames: UnicodeString;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to fCount do
  begin
    Result := Result + fNetPlayers[I].SlotName;
    if I < fCount then
      Result := Result + '|';
  end;
end;


function TKMNetPlayersList.GetPlayersWithIDs: UnicodeString;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to fCount do
  begin
    Result := Result + '   ' + IntToStr(I) + ': ' + fNetPlayers[I].NiknameU;
    if I < fCount then
      Result := Result + '|';
  end;
end;


end.
