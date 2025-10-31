unit KM_GameInfo;
{$I KaM_Remake.inc}
interface
uses
  KM_CommonClasses, KM_Maps, KM_MapTypes, KM_Defaults,
  KM_HandTypes, KM_CommonTypes;


type
  TKMGameInfoParseErrorType = (gipetNone, gipetUnsupportedFormat, gipetUnsupportedVersion);

  TKMGameInfoParseError = record
    ErrorString: UnicodeString;
    ErrorType: TKMGameInfoParseErrorType;
  end;

  //Info that is relevant to any game, be it Save or a Mission
  TKMGameInfo = class
  private
    fMapTxtInfo: TKMMapTxtInfo;
    fParseError: TKMGameInfoParseError;
    procedure ResetParseError;
    function GetVersionUnicode: UnicodeString;
    function IsOnlyAILoc(aLoc: Integer): Boolean;
  public
    Title: UnicodeString; //Used for campaigns and to store in savegames
    Version: AnsiString; //Savegame version, yet unused in maps, they always have actual version
    MapFullCRC: Cardinal; //CRC of entire map, used for reporting which map was played to master server
    MapSimpleCRC: Cardinal; //CRC of .dat + .map files
    DATCRC: Cardinal; //CRC of defines .dat files (data\defines)
    TickCount: Cardinal; //Current tick count of the game (unused for maps)
    SaveTimestamp: TDateTime; //UTC time when the save was created (unused for maps)
    MissionMode: TKMissionMode; //Fighting or Build-a-City map
    MissionDifficulty: TKMMissionDifficulty;
    MapSizeX, MapSizeY: Integer;

    PlayerCount: Byte;
    Enabled: array [0..MAX_HANDS-1] of Boolean;
    CanBeHuman: array [0..MAX_HANDS-1] of Boolean;
    CanBeClassicAI: array [0..MAX_HANDS-1] of Boolean;
    CanBeAdvancedAI: array [0..MAX_HANDS-1] of Boolean;
    OwnerNickname: array [0..MAX_HANDS-1] of AnsiString; //Nickname of the player who plays this location
    HandTypes: array [0..MAX_HANDS-1] of TKMHandType;
    Color: array [0..MAX_HANDS-1] of Cardinal;
    Team: array [0..MAX_HANDS-1] of Integer;

    //To be used in Savegames
    constructor Create; overload;
    constructor Create(aMapTxtInfo: TKMMapTxtInfo); overload;
    destructor Destroy; override;

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

    property TxtInfo: TKMMapTxtInfo read fMapTxtInfo write fMapTxtInfo;
    property ParseError: TKMGameInfoParseError read fParseError;
    function IsValid(aCheckDATCRC: Boolean): Boolean;
    function AICount: Byte;
    function HumanCount: Byte;
    function HumanUsableLocs: TKMHandIDArray;
    function FixedLocsColors: TKMCardinalArray;
    function GetTimeText: UnicodeString;
    function GetTitleWithTime: UnicodeString;
    function GetSaveTimestamp: UnicodeString;
    function ColorUsed(aColor: Cardinal): Boolean;

    property VersionU: UnicodeString read GetVersionUnicode;
  end;


implementation
uses
  SysUtils,
  KM_Log, KM_Resource, KM_ResTexts, KM_CommonUtils;


{ TKMGameInfo }
constructor TKMGameInfo.Create;
begin
  Create(TKMMapTxtInfo.Create);
end;


constructor TKMGameInfo.Create(aMapTxtInfo: TKMMapTxtInfo);
begin
  inherited Create;

  fMapTxtInfo := aMapTxtInfo;
  ResetParseError;
end;


destructor TKMGameInfo.Destroy;
begin
  if fMapTxtInfo <> nil then
    fMapTxtInfo.Free;

  inherited;
end;


procedure TKMGameInfo.ResetParseError;
begin
  fParseError.ErrorString := '';
  fParseError.ErrorType := gipetNone;
end;


function TKMGameInfo.GetVersionUnicode: UnicodeString;
begin
  Result := UnicodeString(Version);
end;


procedure TKMGameInfo.Load(LoadStream: TKMemoryStream);

  procedure LoadGameInfoData;
  var
    I: Integer;
  begin
    LoadStream.Read(DATCRC); //Don't check it here (maps don't care), if required somebody else will check it
    LoadStream.Read(MapFullCRC);
    LoadStream.Read(MapSimpleCRC);

    LoadStream.ReadW(Title); //GameName
    LoadStream.Read(TickCount);
    LoadStream.Read(SaveTimestamp);
    LoadStream.Read(MissionMode, SizeOf(MissionMode));
    LoadStream.Read(MissionDifficulty, SizeOf(MissionDifficulty));
    LoadStream.Read(MapSizeX);
    LoadStream.Read(MapSizeY);

    LoadStream.Read(PlayerCount);
    for I := 0 to PlayerCount - 1 do
    begin
      LoadStream.Read(CanBeHuman[I]);
      LoadStream.Read(CanBeClassicAI[I]);
      LoadStream.Read(CanBeAdvancedAI[I]);
      LoadStream.Read(Enabled[I]);
      LoadStream.ReadA(OwnerNickname[I]);
      LoadStream.Read(HandTypes[I], SizeOf(HandTypes[I]));
      LoadStream.Read(Color[I]);
      LoadStream.Read(Team[I]);
    end;

    fMapTxtInfo.Load(LoadStream);
  end;

var
  ansiStr: AnsiString;
begin
  ResetParseError;
  LoadStream.ReadA(ansiStr);
  if ansiStr <> 'KaM_GameInfo' then
  begin
    fParseError.ErrorString := Format(gResTexts[TX_SAVE_UNSUPPORTED_FORMAT], [Copy(ansiStr, 1, 8)]);
    fParseError.ErrorType := gipetUnsupportedFormat;
    Exit;
  end;

  LoadStream.ReadA(Version);
  if Version <> GAME_REVISION then
  begin
    fParseError.ErrorString := Format(gResTexts[TX_SAVE_UNSUPPORTED_VERSION], [Version]);
    fParseError.ErrorType := gipetUnsupportedVersion;
//    Exit; //need to try load game data anyway, in case we will try to load unsupported version save
  end;

  if fParseError.ErrorType = gipetUnsupportedVersion then
  begin
    try
      LoadGameInfoData;
    except
      on E: Exception do
        gLog.AddTime('Error while loading game info from save of unsupported version "%s"', [Version]); //silently log error
    end;
  end
  else
    LoadGameInfoData; //Load without catching exception
end;


procedure TKMGameInfo.Save(SaveStream: TKMemoryStream);
var
  I: Integer;
begin
  SaveStream.WriteA('KaM_GameInfo');
  SaveStream.WriteA(GAME_REVISION); //Save current revision
  SaveStream.Write(gRes.GetDATCRC);
  SaveStream.Write(MapFullCRC);
  SaveStream.Write(MapSimpleCRC);

  SaveStream.WriteW(Title); //GameName
  SaveStream.Write(TickCount);

  // Game times differ for game and replay
  // Set default value there in that case
  if GAME_SAVE_STRIP_FOR_CRC then
    SaveStream.Write(DATE_TIME_ZERO)
  else
    SaveStream.Write(SaveTimestamp);

  SaveStream.Write(MissionMode, SizeOf(MissionMode));
  SaveStream.Write(MissionDifficulty, SizeOf(MissionDifficulty));
  SaveStream.Write(MapSizeX);
  SaveStream.Write(MapSizeY);

  SaveStream.Write(PlayerCount);
  for I := 0 to PlayerCount - 1 do
  begin
    SaveStream.Write(CanBeHuman[I]);
    SaveStream.Write(CanBeClassicAI[I]);
    SaveStream.Write(CanBeAdvancedAI[I]);
    SaveStream.Write(Enabled[I]);
    SaveStream.WriteA(OwnerNickname[I]);
    SaveStream.Write(HandTypes[I], SizeOf(HandTypes[I]));
    SaveStream.Write(Color[I]);
    SaveStream.Write(Team[I]);
  end;

  fMapTxtInfo.Save(SaveStream);
end;


function TKMGameInfo.IsValid(aCheckDATCRC: Boolean): Boolean;
begin
  Result := (PlayerCount > 0) and (not aCheckDATCRC or (DATCRC = gRes.GetDATCRC));
end;


//How many AI players are in this game,
//so that Lobby could automatically create this much AIs when the save is selected
function TKMGameInfo.AICount: Byte;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to PlayerCount - 1 do
    if HandTypes[I] = hndComputer then
      Inc(Result);
end;


function TKMGameInfo.HumanCount: Byte;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to PlayerCount - 1 do
    if Enabled[I] and (HandTypes[I] = hndHuman) then
      Inc(Result);
end;


function TKMGameInfo.HumanUsableLocs: TKMHandIDArray;
var
  I: Integer;
begin
  SetLength(Result, 0);
  for I := 0 to MAX_HANDS - 1 do
    if CanBeHuman[I] then
    begin
      SetLength(Result, Length(Result)+1);
      Result[Length(Result)-1] := I;
    end;
end;


function TKMGameInfo.IsOnlyAILoc(aLoc: Integer): Boolean;
begin
  Assert(aLoc < MAX_HANDS);
  Result := not CanBeHuman[aLoc] and (CanBeClassicAI[aLoc] or CanBeAdvancedAI[aLoc]);
end;


// Color is fixed for loc if map has BlockColorSelection attribute
// or if its only AI loc, no available for player
// *** We don't need to check if loc is only for AI for now, it works fine without it
function TKMGameInfo.FixedLocsColors: TKMCardinalArray;
var
  I: Integer;
begin
  SetLength(Result, 0);
  if Self = nil then Exit;

  SetLength(Result, PlayerCount);
  for I := 0 to PlayerCount - 1 do
    if TxtInfo.BlockColorSelection or IsOnlyAILoc(I) then
      Result[I] := Color[I]
    else
      Result[I] := 0;
end;


function TKMGameInfo.GetTimeText: UnicodeString;
begin
  Result := TickToTimeStr(TickCount);
end;


function TKMGameInfo.GetTitleWithTime: UnicodeString;
begin
  if IsValid(True) then
    Result := Title + ' ' + TickToTimeStr(TickCount)
  else
    Result := Title;
end;


function TKMGameInfo.GetSaveTimestamp: UnicodeString;
begin
  Result := FormatDateTime('ddddd t', UTCToLocal(SaveTimestamp));
end;


function TKMGameInfo.ColorUsed(aColor: Cardinal): Boolean;
var
  I: Integer;
begin
  for I := 0 to MAX_HANDS - 1 do
    if Enabled[I] and (Color[I] = aColor) then
    begin
      Result := True;
      Exit;
    end;
  Result := False;
end;


end.

