unit KM_GameInfo;
{$I KaM_Remake.inc}
interface
uses
  KM_Hand, KM_CommonClasses, KM_MapTypes, KM_Defaults;


type
  TKMGameInfoParseErrorType = (gipetNone, gipetUnsupportedFormat, gipetUnsupportedVersion);

  TKMGameInfoParseError = record
    ErrorString: UnicodeString;
    ErrorType: TKMGameInfoParseErrorType;
  end;

  //Info that is relevant to any game, be it Save or a Mission
  TKMGameInfo = class
  private
    fParseError: TKMGameInfoParseError;
    procedure ResetParseError;
    function GetVersionUnicode: UnicodeString;
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
    OwnerNikname: array [0..MAX_HANDS-1] of AnsiString; //Nikname of the player who plays this location
    HandTypes: array [0..MAX_HANDS-1] of TKMHandType;
    Color: array [0..MAX_HANDS-1] of Cardinal;
    Team: array [0..MAX_HANDS-1] of Integer;

    //To be used in Savegames
    constructor Create;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

    property ParseError: TKMGameInfoParseError read fParseError;
    function IsValid(aCheckDATCRC: Boolean): Boolean;
    function AICount: Byte;
    function HumanCount: Byte;
    function HumanUsableLocs: TKMHandIDArray;
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
  inherited;
  ResetParseError;
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
      LoadStream.Read(Enabled[I]);
      LoadStream.ReadA(OwnerNikname[I]);
      LoadStream.Read(HandTypes[I], SizeOf(HandTypes[I]));
      LoadStream.Read(Color[I]);
      LoadStream.Read(Team[I]);
    end;
  end;

var
  s: AnsiString;
begin
  ResetParseError;
  LoadStream.ReadA(s);
  if s <> 'KaM_GameInfo' then
  begin
    fParseError.ErrorString := Format(gResTexts[TX_SAVE_UNSUPPORTED_FORMAT], [Copy(s, 1, 8)]);
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
        gLog.AddTime(Format('Error while loading game info from save of unsupported version %s', [Version])); //silently log error
    end;
  end
  else
    LoadGameInfoData; //Load without catching exception

end;


procedure TKMGameInfo.Save(SaveStream: TKMemoryStream);
var I: Integer;
begin
  SaveStream.WriteA('KaM_GameInfo');
  SaveStream.WriteA(GAME_REVISION); //Save current revision
  SaveStream.Write(gRes.GetDATCRC);
  SaveStream.Write(MapFullCRC);
  SaveStream.Write(MapSimpleCRC);

  SaveStream.WriteW(Title); //GameName
  SaveStream.Write(TickCount);
  SaveStream.Write(SaveTimestamp);
  SaveStream.Write(MissionMode, SizeOf(MissionMode));
  SaveStream.Write(MissionDifficulty, SizeOf(MissionDifficulty));
  SaveStream.Write(MapSizeX);
  SaveStream.Write(MapSizeY);

  SaveStream.Write(PlayerCount);
  for I := 0 to PlayerCount - 1 do
  begin
    SaveStream.Write(CanBeHuman[I]);
    SaveStream.Write(Enabled[I]);
    SaveStream.WriteA(OwnerNikname[I]);
    SaveStream.Write(HandTypes[I], SizeOf(HandTypes[I]));
    SaveStream.Write(Color[I]);
    SaveStream.Write(Team[I]);
  end;
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

