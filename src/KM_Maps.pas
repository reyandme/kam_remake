unit KM_Maps;
{$I KaM_Remake.inc}
interface
uses
  Classes, SyncObjs,
  KM_MapTypes,
  KM_CommonTypes, KM_CommonClasses, KM_Defaults, KM_Pics, KM_ResTexts;


type
  TKMapsSortMethod = (
    smByFavouriteAsc, smByFavouriteDesc,
    smByNameAsc, smByNameDesc,
    smBySizeAsc, smBySizeDesc,
    smByPlayersAsc, smByPlayersDesc,
    smByHumanPlayersAsc, smByHumanPlayersDesc,
    smByHumanPlayersMPAsc, smByHumanPlayersMPDesc,
    smByMissionModeAsc, smByMissionModeDesc);

  TKMapInfo = class;
  TKMapEvent = procedure (aMap: TKMapInfo) of object;
  TKMMapInfoAmount = (iaBase, iaExtra);

  TKMMapGoalInfo = packed record
    Cond: TKMGoalCondition;
    Play: TKMHandID;
    Stat: TKMGoalStatus;
  end;

  TKMMapTxtInfo = class
  private
    fBlockColorSelection: Boolean;
    function IsEmpty: Boolean;
    function GetBlockColorSelection: Boolean;
  public
    Author, Version, BigDesc, SmallDesc: UnicodeString;
    SmallDescLibx, BigDescLibx: Integer;
    IsCoop: Boolean; //Some multiplayer missions are defined as coop
    IsSpecial: Boolean; //Some missions are defined as special (e.g. tower defence, quest, etc.)
    IsRMG: Boolean; //Missions that were generated via Random Map Generator
    IsPlayableAsSP: Boolean; //Is MP map playable as SP map ?

    DifficultyLevels: TKMMissionDifficultySet;

    BlockTeamSelection: Boolean;
    BlockPeacetime: Boolean;
    BlockFullMapPreview: Boolean;

    constructor Create;

    procedure Load(LoadStream: TKMemoryStream);
    procedure Save(SaveStream: TKMemoryStream);

    procedure SetBigDesc(const aBigDesc: UnicodeString);
    function GetBigDesc: UnicodeString;

    function IsSmallDescLibxSet: Boolean;
    function IsBigDescLibxSet: Boolean;

    procedure ResetInfo;

    procedure SaveTXTInfo(const aFilePath: String);
    procedure LoadTXTInfo(const aFilePath: String);
    function HasDifficultyLevels: Boolean;

    property BlockColorSelection: Boolean read GetBlockColorSelection write fBlockColorSelection;
  end;


  TKMMapTxtInfoArray = array of TKMMapTxtInfo;


  TKMapInfo = class
  private
    fPath: String;
    fFileName: UnicodeString; //without extension
    fCRC: Cardinal;
    fDatCRC: Cardinal; //Used to speed up scanning
    fMapAndDatCRC: Cardinal; //Used to determine map by its .map + .dat files, ignoring other map data (.txt and .script)
    fVersion: AnsiString; //Savegame version, yet unused in maps, they always have actual version
    fInfoAmount: TKMMapInfoAmount;
    fMapFolder: TKMapFolder;
    fTxtInfo: TKMMapTxtInfo;
    fSize: TKMMapSize;
    fSizeText: String;
    fCustomScriptParams: TKMCustomScriptParamDataArray;
    procedure ResetInfo;
    procedure LoadFromStreamObj(aStreamObj: TObject; const aPath: UnicodeString);
    procedure LoadFromFile(const aPath: UnicodeString);
    procedure SaveToStreamObj(aStreamObj: TObject; const aPath: UnicodeString);
    procedure SaveToFile(const aPath: UnicodeString);
    function GetSize: TKMMapSize;
    function GetSizeText: String;
    function DetermineReadmeFilePath: String;
    function GetFavouriteMapPic: TKMPic;
    function GetCanBeHumanCount: Byte;
    function GetCanBeOnlyHumanCount: Byte;
    function GetCanBeAICount: Byte;
    function GetCanBeOnlyAICount: Byte;
    function GetCanBeHumanAndAICount: Byte;
    function GetBigDesc: UnicodeString;
    procedure SetBigDesc(const aBigDesc: UnicodeString);
    function GetTxtInfo: TKMMapTxtInfo;
  public
    MapSizeX, MapSizeY: Integer;
    MissionMode: TKMissionMode;
    LocCount: Byte;
    CanBeHuman: array [0..MAX_HANDS-1] of Boolean;
    CanBeAI: array [0..MAX_HANDS-1] of Boolean;
    CanBeAdvancedAI: array [0..MAX_HANDS-1] of Boolean;
    DefaultHuman: TKMHandID;
    GoalsVictoryCount, GoalsSurviveCount: array [0..MAX_HANDS-1] of Byte;
    GoalsVictory: array [0..MAX_HANDS-1] of array of TKMMapGoalInfo;
    GoalsSurvive: array [0..MAX_HANDS-1] of array of TKMMapGoalInfo;
    Alliances: array [0..MAX_HANDS-1, 0..MAX_HANDS-1] of TKMAllianceType;
    FlagColors: array [0..MAX_HANDS-1] of Cardinal;
    IsFavourite: Boolean;

    constructor Create(const aFolder: string; aStrictParsing: Boolean; aMapFolder: TKMapFolder); overload;
    destructor Destroy; override;

    procedure AddGoal(aType: TKMGoalType; aPlayer: TKMHandID; aCondition: TKMGoalCondition; aStatus: TKMGoalStatus; aPlayerIndex: TKMHandID);
    procedure LoadExtra;

    property TxtInfo: TKMMapTxtInfo read GetTxtInfo;
    property BigDesc: UnicodeString read GetBigDesc write SetBigDesc;
    property InfoAmount: TKMMapInfoAmount read fInfoAmount;
    property Path: string read fPath;
    property MapFolder: TKMapFolder read fMapFolder;
    property FileName: UnicodeString read fFileName;
    function FullPath(const aExt: string): string;
    function HumanUsableLocs: TKMHandIDArray;
    function AIUsableLocs: TKMHandIDArray;
    function AdvancedAIUsableLocs: TKMHandIDArray;
    function FixedLocsColors: TKMCardinalArray;
    function AIOnlyLocsColors: TKMCardinalArray;
    function IsOnlyAILoc(aLoc: Integer): Boolean;
    property CRC: Cardinal read fCRC;
    property MapAndDatCRC : Cardinal read fMapAndDatCRC;
    function LocationName(aIndex: TKMHandID): string;
    property Size: TKMMapSize read GetSize;
    property SizeText: string read GetSizeText;
    function IsValid: Boolean;
    function HumanPlayerCount: Byte;
    function HumanPlayerCountMP: Byte;
    function AIOnlyLocCount: Byte;
    function FileNameWithoutHash: UnicodeString;
    function HasReadme: Boolean;
    function ViewReadme: Boolean;
    function GetLobbyColor: Cardinal;
    function IsFilenameEndMatchHash: Boolean;
    function IsPlayableForSP: Boolean;
    function IsSinglePlayer: Boolean;
    function IsMultiPlayer: Boolean;
    function IsDownloaded: Boolean;
    function IsNormalMission: Boolean;
    function IsTacticMission: Boolean;
    property FavouriteMapPic: TKMPic read GetFavouriteMapPic;
    property CanBeHumanCount: Byte read GetCanBeHumanCount;
    property CanBeOnlyHumanCount: Byte read GetCanBeOnlyHumanCount;
    property CanBeAICount: Byte read GetCanBeAICount;
    property CanBeOnlyAICount: Byte read GetCanBeOnlyAICount;
    property CanBeHumanAndAICount: Byte read GetCanBeHumanAndAICount;
    function HasDifferentAITypes: Boolean;
  end;


  TTCustomMapsScanner = class(TThread)
  private
    fMapFolders: TKMapFolderSet;
    fOnComplete: TNotifyEvent;
    procedure ProcessMap(const aPath: UnicodeString; aFolder: TKMapFolder); virtual; abstract;
  public
    constructor Create(aMapFolders: TKMapFolderSet; aOnComplete: TNotifyEvent = nil);
    procedure Execute; override;
  end;

  TTMapsScanner = class(TTCustomMapsScanner)
  private
    fOnMapAdd: TKMapEvent;
    fOnMapAddDone: TNotifyEvent;
    procedure ProcessMap(const aPath: UnicodeString; aFolder: TKMapFolder); override;
  public
    constructor Create(aMapFolders: TKMapFolderSet; aOnMapAdd: TKMapEvent; aOnMapAddDone, aOnTerminate: TNotifyEvent; aOnComplete: TNotifyEvent = nil);
  end;

  TTMapsCacheUpdater = class(TTCustomMapsScanner)
  private
    fIsStopped: Boolean;
    procedure ProcessMap(const aPath: UnicodeString; aFolder: TKMapFolder); override;
  public
    procedure Stop;
    constructor Create(aMapFolders: TKMapFolderSet);
  end;


  TKMapsCollection = class
  private
    fCount: Integer;
    fMaps: array of TKMapInfo;
    fMapFolders: TKMapFolderSet;
    fSortMethod: TKMapsSortMethod;
    fDoSortWithFavourites: Boolean;
    fCriticalSection: TCriticalSection;
    fScanner: TTMapsScanner;
    fScanning: Boolean; //Flag if scan is in progress
    fUpdateNeeded: Boolean;
    fOnRefresh: TNotifyEvent;
    fOnTerminate: TNotifyEvent;
    fOnComplete: TNotifyEvent;
    procedure Clear;
    procedure MapAdd(aMap: TKMapInfo);
    procedure MapAddDone(Sender: TObject);
    procedure ScanTerminate(Sender: TObject);
    procedure ScanComplete(Sender: TObject);
    procedure DoSort;
    function GetMap(aIndex: Integer): TKMapInfo;
  public
    constructor Create(aMapFolders: TKMapFolderSet; aSortMethod: TKMapsSortMethod = smByNameDesc; aDoSortWithFavourites: Boolean = False); overload;
    constructor Create(aMapFolder: TKMapFolder; aSortMethod: TKMapsSortMethod = smByNameDesc; aDoSortWithFavourites: Boolean = False); overload;
    destructor Destroy; override;

    property Count: Integer read fCount;
    property Maps[aIndex: Integer]: TKMapInfo read GetMap; default;
    procedure Lock;
    procedure Unlock;

    class function FullPath(const aDirName, aFileName, aExt: string; aMapFolder: TKMapFolder): string; overload;
    class function FullPath(const aName, aExt: string; aMultiplayer: Boolean): string; overload;
    class function FullPath(const aName, aExt: string; aMapFolder: TKMapFolder): string; overload;
    class function FullPath(const aName, aExt: string; aMapFolder: TKMapFolder; aCRC: Cardinal): string; overload;
//    class function GuessMPPath(const aName, aExt: string; aCRC: Cardinal): string;
    class procedure GetAllMapPaths(const aExeDir: string; aList: TStringList);
    class function GetMapCRC(const aMapPath: string): Cardinal;

    procedure Refresh(aOnRefresh: TNotifyEvent;  aOnTerminate: TNotifyEvent = nil;aOnComplete: TNotifyEvent = nil);
    procedure TerminateScan;
    procedure Sort(aSortMethod: TKMapsSortMethod; aOnSortComplete: TNotifyEvent);
    property SortMethod: TKMapsSortMethod read fSortMethod; //Read-only because we should not change it while Refreshing

    function Contains(const aNewName: UnicodeString): Boolean;
    procedure RenameMap(aIndex: Integer; const aName: UnicodeString);
    procedure DeleteMap(aIndex: Integer);
    procedure MoveMap(aIndex: Integer; const aName: UnicodeString; aMapFolder: TKMapFolder);

    procedure UpdateState;
  end;

  function GetMapFolderType(aIsMultiplayer: Boolean): TKMapFolder;
  function DetermineMapFolder(const aFolderName: UnicodeString; out aMapFolder: TKMapFolder): Boolean;


implementation
uses
  SysUtils, StrUtils, TypInfo, Math,
  KromShellUtils, KromUtils,
  KM_GameApp, KM_GameSettings, KM_FileIO,
  KM_MissionScript_Info, KM_Scripting,
  KM_CommonUtils, KM_Log;

const
  MAP_TXT_INFO_MARKER = 'MapTxtInfo';


{ TKMapInfo }
constructor TKMapInfo.Create(const aFolder: string; aStrictParsing: Boolean; aMapFolder: TKMapFolder);

  function GetLIBXCRC(const aSearchFile: UnicodeString): Cardinal;
  var SearchRec: TSearchRec;
  begin
    Result := 0;
    FindFirst(aSearchFile, faAnyFile - faDirectory, SearchRec);
    try
      repeat
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
          Result := Result xor Adler32CRC(ExtractFilePath(aSearchFile) + SearchRec.Name);
      until (FindNext(SearchRec) <> 0);
    finally
      FindClose(SearchRec);
    end;
  end;

var
  I: Integer;
  datFile, mapFile, scriptFile, txtFile, libxFiles: string;
  datCRC, mapCRC, othersCRC: Cardinal;
  missionParser: TKMMissionParserInfo;
  scriptPreProcessor: TKMScriptingPreProcessor;
  scriptFiles: TKMScriptFilesCollection;
  CSP: TKMCustomScriptParam;
begin
  inherited Create;

  fTxtInfo := TKMMapTxtInfo.Create;
  fPath := ExeDir + MAP_FOLDER[aMapFolder] + PathDelim + aFolder + PathDelim;
  fFileName := aFolder;
  fMapFolder := aMapFolder;

  for CSP := Low(TKMCustomScriptParam) to High(TKMCustomScriptParam) do
  begin
    fCustomScriptParams[CSP].Added := False;
    fCustomScriptParams[CSP].Data := '';
  end;

  datFile := fPath + fFileName + '.dat';
  mapFile := fPath + fFileName + '.map';
  scriptFile := fPath + fFileName + EXT_FILE_SCRIPT_DOT; //Needed for CRC
  txtFile := fPath + fFileName + '.txt'; //Needed for CRC
  libxFiles := fPath + fFileName + '.*.libx'; //Needed for CRC

  fSizeText := ''; //Lazy initialization

  if not FileExists(datFile) then Exit;

  //Try loading info from cache, since map scanning is rather slow
  LoadFromFile(fPath + fFileName + '.mi'); //Data will be empty if failed

  //We will scan map once again if anything has changed
  //In SP mode (non-strict) we check DAT CRC and version, that is enough
  //In MP mode (strict) we also need exact CRCs to match maps between players

  datCRC := Adler32CRC(datFile);
  //.map file CRC is the slowest, so only calculate it if necessary
  othersCRC := 0; //Supresses incorrect warning by Delphi
  mapCRC := 0;
  if aStrictParsing then
  begin
    mapCRC := Adler32CRC(mapFile);
    othersCRC := mapCRC xor Adler32CRC(txtFile) xor GetLIBXCRC(libxFiles);
    fMapAndDatCRC := datCRC xor mapCRC;

    //Add main script CRC and all included scripts CRC
    if FileExists(scriptFile) then
    begin
      othersCRC := othersCRC xor Adler32CRC(scriptFile);
      scriptPreProcessor := TKMScriptingPreProcessor.Create;
      try
        if scriptPreProcessor.PreProcessFile(scriptFile) then
        begin
          //Copy custom script params
          for CSP := Low(TKMCustomScriptParam) to High(TKMCustomScriptParam) do
            fCustomScriptParams[CSP] := scriptPreProcessor.CustomScriptParams[CSP];

          scriptFiles := scriptPreProcessor.ScriptFilesInfo;
          for I := 0 to scriptFiles.IncludedCount - 1 do
            othersCRC := othersCRC xor Adler32CRC(scriptFiles[I].FullFilePath);
        end;
      finally
        scriptPreProcessor.Free;
      end;
    end;
  end;

  //Does the map need to be fully rescanned? (.mi cache is outdated?)
  if (fVersion <> GAME_REVISION) or
     (fDatCRC <> datCRC) or //In non-strict mode only DAT CRC matters (SP)
     (aStrictParsing and (fCRC <> datCRC xor othersCRC)) //In strict mode we check all CRCs (MP)
  then
  begin
    //Calculate OthersCRC if it wasn't calculated before
    if not aStrictParsing then
    begin
      mapCRC := Adler32CRC(mapFile);
      othersCRC := mapCRC xor Adler32CRC(scriptFile) xor Adler32CRC(txtFile);
    end;

    fCRC := datCRC xor othersCRC;
    fDatCRC := datCRC;
    fMapAndDatCRC := datCRC xor mapCRC;
    fVersion := GAME_REVISION;

    //First reset everything because e.g. CanBeHuman is assumed false by default and set true when we encounter SET_USER_PLAYER
    ResetInfo;

    missionParser := TKMMissionParserInfo.Create;
    try
      //Fill Self properties with MissionParser
      missionParser.LoadMission(datFile, Self, pmBase);
    finally
      missionParser.Free;
    end;

    //Load additional text info
    fTxtInfo.LoadTXTInfo(fPath + fFileName + '.txt');

    if gGameSettings = nil // In case we are closing app and settings object is already destroyed
      then Exit;

    IsFavourite := gGameSettings.FavouriteMaps.Contains(fMapAndDatCRC);

    SaveToFile(fPath + fFileName + '.mi'); //Save new cache file
  end;

  fInfoAmount := iaBase;
end;


destructor TKMapInfo.Destroy;
begin
  FreeAndNil(fTxtInfo);

  inherited;
end;


procedure TKMapInfo.AddGoal(aType: TKMGoalType; aPlayer: TKMHandID; aCondition: TKMGoalCondition; aStatus: TKMGoalStatus; aPlayerIndex: TKMHandID);
var
  G: TKMMapGoalInfo;
begin
  G.Cond := aCondition;
  G.Play := aPlayerIndex;
  G.Stat := aStatus;

  case aType of
    gltVictory:  begin
                    SetLength(GoalsVictory[aPlayer], GoalsVictoryCount[aPlayer] + 1);
                    GoalsVictory[aPlayer, GoalsVictoryCount[aPlayer]] := G;
                    Inc(GoalsVictoryCount[aPlayer]);
                  end;
    gltSurvive:  begin
                    SetLength(GoalsSurvive[aPlayer], GoalsSurviveCount[aPlayer] + 1);
                    GoalsSurvive[aPlayer, GoalsSurviveCount[aPlayer]] := G;
                    Inc(GoalsSurviveCount[aPlayer]);
                  end;
    else          ;
  end;
end;


function TKMapInfo.FullPath(const aExt: string): string;
begin
  Result := fPath + fFileName + aExt;
end;


function TKMapInfo.HumanUsableLocs: TKMHandIDArray;
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


function TKMapInfo.AIUsableLocs: TKMHandIDArray;
var
  I: Integer;
begin
  SetLength(Result, 0);
  for I := 0 to MAX_HANDS - 1 do
    if CanBeAI[I] then
    begin
      SetLength(Result, Length(Result)+1);
      Result[Length(Result)-1] := I;
    end;
end;


function TKMapInfo.AdvancedAIUsableLocs: TKMHandIDArray;
var
  I: Integer;
begin
  SetLength(Result, 0);
  for I := 0 to MAX_HANDS - 1 do
    if CanBeAdvancedAI[I] then
    begin
      SetLength(Result, Length(Result)+1);
      Result[Length(Result)-1] := I;
    end;
end;


function TKMapInfo.IsOnlyAILoc(aLoc: Integer): Boolean;
begin
  Assert(aLoc < MAX_HANDS);
  Result := not CanBeHuman[aLoc] and (CanBeAI[aLoc] or CanBeAdvancedAI[aLoc]);
end;


// Color is fixed for loc if map has BlockColorSelection attribute
// or if its only AI loc, no available for player
function TKMapInfo.FixedLocsColors: TKMCardinalArray;
var
  I: Integer;
begin
  SetLength(Result, MAX_HANDS);

  for I := 0 to MAX_HANDS - 1 do
    if TxtInfo.BlockColorSelection or IsOnlyAILoc(I) then
      Result[I] := FlagColors[I]
    else
      Result[I] := 0;
end;


// Colors that are used by only AI locs
function TKMapInfo.AIOnlyLocsColors: TKMCardinalArray;
var
  I, K: Integer;
begin
  SetLength(Result, 0);
  if Self = nil then Exit;

  SetLength(Result, LocCount);
  K := 0;
  for I := 0 to LocCount - 1 do
  begin
    if not CanBeHuman[I]
      and (CanBeAI[I] or CanBeAdvancedAI[I]) then
    begin
      Result[K] := FlagColors[I];
      Inc(K);
    end;
  end;

  SetLength(Result, K);
end;


function TKMapInfo.LocationName(aIndex: TKMHandID): string;
begin
  Result := Format(gResTexts[TX_LOBBY_LOCATION_X], [aIndex + 1]);
end;


function TKMapInfo.GetSize: TKMMapSize;
begin
  if fSize = msNone then
    fSize := MapSizeIndex(MapSizeX, MapSizeY);
  Result := fSize;
end;


function TKMapInfo.GetSizeText: string;
begin
  if fSizeText = '' then
    fSizeText := MapSizeText(MapSizeX, MapSizeY);
  Result := fSizeText;
end;


function TKMapInfo.GetTxtInfo: TKMMapTxtInfo;
begin
  if Self = nil then Exit(nil);

  Result := fTxtInfo;
end;


//Load additional information for map that is not in main SP list
procedure TKMapInfo.LoadExtra;
var
  datFile: string;
  missionParser: TKMMissionParserInfo;
begin
  //Do not append Extra info twice
  if fInfoAmount = iaExtra then Exit;

  //First reset everything because e.g. CanBeHuman is assumed false by default and set true when we encounter SET_USER_PLAYER
  ResetInfo;

  datFile := fPath + fFileName + '.dat';

  missionParser := TKMMissionParserInfo.Create;
  try
    //Fill Self properties with MissionParser
    missionParser.LoadMission(datFile, Self, pmExtra);
  finally
    missionParser.Free;
  end;

  if IsTacticMission then
    fTxtInfo.BlockPeacetime := True;

  fTxtInfo.LoadTXTInfo(fPath + fFileName + '.txt');

  fInfoAmount := iaExtra;
end;


procedure TKMapInfo.ResetInfo;
var
  I, K: Integer;
begin
  MissionMode := mmNormal;
  DefaultHuman := 0;
  fTxtInfo.ResetInfo;
  for I:=0 to MAX_HANDS-1 do
  begin
    FlagColors[I] := DefaultTeamColors[I];
    CanBeHuman[I] := False;
    CanBeAI[I] := False;
    CanBeAdvancedAI[I] := False;
    GoalsVictoryCount[I] := 0;
    SetLength(GoalsVictory[I], 0);
    GoalsSurviveCount[I] := 0;
    SetLength(GoalsSurvive[I], 0);
    for K:=0 to MAX_HANDS-1 do
      if I = K then
        Alliances[I,K] := atAlly
      else
        Alliances[I,K] := atEnemy;
  end;
end;


procedure TKMapInfo.LoadFromStreamObj(aStreamObj: TObject; const aPath: UnicodeString);
var
  S: TKMemoryStream;
begin
  Assert(aStreamObj is TKMemoryStreamBinary, 'Wrong stream object class');

  S := TKMemoryStreamBinary(aStreamObj);

  S.LoadFromFile(aPath);

  //Internal properties
  S.Read(fCRC);
  S.Read(fDatCRC);
  S.Read(fMapAndDatCRC);
  S.ReadA(fVersion);

  //Exposed properties
  S.Read(MapSizeX);
  S.Read(MapSizeY);
  S.Read(MissionMode, SizeOf(TKMissionMode));
  S.Read(LocCount);
  S.Read(CanBeHuman, SizeOf(CanBeHuman));

  fTxtInfo.Load(S);

  IsFavourite := gGameSettings.FavouriteMaps.Contains(fMapAndDatCRC);
end;


procedure TKMapInfo.LoadFromFile(const aPath: UnicodeString);
var
  S: TKMemoryStream;
  errorStr: UnicodeString;
begin
  if not FileExists(aPath) then Exit;

  S := TKMemoryStreamBinary.Create;
  try
    //Try to load map cache up to 3 times (in case its updating by other thread
    //its much easier and working well, then synchronize threads
    if not TryExecuteMethod(TObject(S), aPath, 'LoadFromStreamObj', errorStr, LoadFromStreamObj) then
      gLog.AddTime(errorStr);
  finally
    //Other properties are not saved, they are fast to reload
    S.Free;
  end;
end;


procedure TKMapInfo.SaveToStreamObj(aStreamObj: TObject; const aPath: UnicodeString);
var
  S: TKMemoryStream;
begin
  Assert(aStreamObj is TKMemoryStreamBinary, 'Wrong stream object class');

  S := TKMemoryStreamBinary(aStreamObj);

  S.SaveToFile(aPath);
end;


procedure TKMapInfo.SaveToFile(const aPath: UnicodeString);
var
  S: TKMemoryStream;
  errorStr: UnicodeString;
begin
  S := TKMemoryStreamBinary.Create;
  try
    //Internal properties
    S.Write(fCRC);
    S.Write(fDatCRC);
    S.Write(fMapAndDatCRC);
    S.WriteA(fVersion);

    //Exposed properties
    S.Write(MapSizeX);
    S.Write(MapSizeY);
    S.Write(MissionMode, SizeOf(TKMissionMode));
    S.Write(LocCount);
    S.Write(CanBeHuman, SizeOf(CanBeHuman));

    fTxtInfo.Save(S);

    //Try to save map cache up to 3 times (in case its updating by other thread
    //its much easier and working well, then synchronize threads
    if not TryExecuteMethod(TObject(S), aPath, 'SaveToStreamObj', errorStr, SaveToStreamObj) then
      gLog.AddTime(errorStr);
  finally
    //Other properties from text file are not saved, they are fast to reload
    S.Free;
  end;
end;


function TKMapInfo.IsValid: Boolean;
begin
  Result := (LocCount > 0) and
            FileExists(fPath + fFileName + '.dat') and
            FileExists(fPath + fFileName + '.map');
end;


function TKMapInfo.HumanPlayerCount: Byte;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to MAX_HANDS - 1 do
    if CanBeHuman[I] then
      Inc(Result);
end;


function TKMapInfo.HumanPlayerCountMP: Byte;
begin
  Result := HumanPlayerCount;
  //Enforce MP limit
  if Result > MAX_LOBBY_PLAYERS then
    Result := MAX_LOBBY_PLAYERS;
end;


function TKMapInfo.AIOnlyLocCount: Byte;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to MAX_HANDS - 1 do
    if (CanBeAI[I] or CanBeAdvancedAI[I]) and not CanBeHuman[I] then
      Inc(Result);
end;


//Returns True if map filename ends with this map actual CRC hash.
//Used to check if downloaded map was changed
function TKMapInfo.IsFilenameEndMatchHash: Boolean;
begin
  Result := (Length(fFileName) > 9)
    and (fFileName[Length(FileName)-8] = '_')
    and (IntToHex(fCRC, 8) = RightStr(fFileName, 8));
end;


function TKMapInfo.IsPlayableForSP: Boolean;
begin
  Result := IsSinglePlayer or TxtInfo.IsPlayableAsSP;
end;


function TKMapInfo.IsSinglePlayer: Boolean;
begin
  Result := fMapFolder = mfSP;
end;


function TKMapInfo.IsMultiPlayer: Boolean;
begin
  Result := fMapFolder = mfMP;
end;


function TKMapInfo.IsDownloaded: Boolean;
begin
  Result := fMapFolder = mfDL;
end;


function TKMapInfo.IsNormalMission: Boolean;
begin
  Result := MissionMode = mmNormal;
end;


function TKMapInfo.IsTacticMission: Boolean;
begin
  Result := MissionMode = mmTactic;
end;


function TKMapInfo.FileNameWithoutHash: UnicodeString;
begin
  if (fMapFolder = mfDL) and IsFilenameEndMatchHash then
    Result := LeftStr(FileName, Length(FileName)-9)
  else
    Result := FileName;
end;


function TKMapInfo.DetermineReadmeFilePath: String;
var
  path: String;
begin
  Assert(gGameApp <> nil, 'gGameApp = nil!');
  Assert(gGameSettings <> nil, 'gGameSettings = nil!');

  Result := '';
  path := fPath + fFileName + '.' + String(gGameSettings.Locale) + '.pdf'; // Try to file with our locale first
  if FileExists(path) then
    Result := path
  else
  begin
    path := fPath + fFileName + '.' + String(DEFAULT_LOCALE) + '.pdf'; // then with default locale
    if FileExists(path) then
      Result := path
    else
    begin
      path := fPath + fFileName + '.pdf'; // and finally without any locale
      if FileExists(path) then
        Result := path;
    end;
  end;
end;


function TKMapInfo.GetFavouriteMapPic: TKMPic;
begin
  Result := MakePic(rxGuiMain, IfThen(IsFavourite, 77, 85), True);
end;


function TKMapInfo.GetCanBeHumanCount: Byte;
var
  I: Integer;
begin
  Result := 0;
  for I := Low(CanBeHuman) to High(CanBeHuman) do
    if CanBeHuman[I] then
      Inc(Result);
end;


function TKMapInfo.GetCanBeOnlyHumanCount: Byte;
var
  I: Integer;
begin
  Result := 0;
  for I := Low(CanBeHuman) to High(CanBeHuman) do
    if CanBeHuman[I] and not CanBeAI[I] and not CanBeAdvancedAI[I] then
      Inc(Result);
end;


function TKMapInfo.GetCanBeAICount: Byte;
var
  I: Integer;
begin
  Result := 0;
  for I := Low(CanBeAI) to High(CanBeAI) do
    if CanBeAI[I] or CanBeAdvancedAI[I] then
      Inc(Result);
end;


function TKMapInfo.GetCanBeOnlyAICount: Byte;
var
  I: Integer;
begin
  Result := 0;
  for I := Low(CanBeHuman) to High(CanBeHuman) do
    if (CanBeAI[I] or CanBeAdvancedAI[I]) and not CanBeHuman[I] then
      Inc(Result);
end;


function TKMapInfo.GetCanBeHumanAndAICount: Byte;
var
  I: Integer;
begin
  Result := 0;
  for I := Low(CanBeHuman) to High(CanBeHuman) do
    if (CanBeAI[I] or CanBeAdvancedAI[I]) and CanBeHuman[I] then
      Inc(Result);
end;


function TKMapInfo.HasDifferentAITypes: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := Low(CanBeHuman) to High(CanBeHuman) do
    if CanBeAI[I] and CanBeAdvancedAI[I] then
      Result := True;
end;


function TKMapInfo.GetBigDesc: UnicodeString;
var
  CSP: TKMCustomScriptParam;
begin
  Result := '';
  for CSP := Low(TKMCustomScriptParam) to High(TKMCustomScriptParam) do
    if fCustomScriptParams[CSP].Added then
      Result := Result + WrapColor(gResTexts[CUSTOM_MAP_PARAM_DESCR_TX[CSP]] + ':', icRed) + '|'
                       + WrapColor('[' + fCustomScriptParams[CSP].Data + ']', icOrange) + '||';

  Result := Result + TxtInfo.BigDesc;

  // Add 1 new line for author & version section
  if (TxtInfo.Author <> '') or (TxtInfo.Version <> '') and (Result <> '') then
    Result := Result + '|';

  if (TxtInfo.Author <> '') then
    Result := Result + Format('|[$00B0FF]%s:[] %s', [gResTexts[TX_MAPED_MISSION_AUTHOR], TxtInfo.Author]);

  if TxtInfo.Version <> '' then
    Result := Result + Format('|[$7070FF]%s:[] %s', [gResTexts[TX_MAPED_MISSION_VERSION], TxtInfo.Version]);
end;


procedure TKMapInfo.SetBigDesc(const aBigDesc: UnicodeString);
begin
  TxtInfo.BigDesc := aBigDesc;
end;


function TKMapInfo.HasReadme: Boolean;
begin
  Result := DetermineReadmeFilePath <> '';
end;


function TKMapInfo.ViewReadme: Boolean;
begin
  Result := OpenPDF(DetermineReadmeFilePath);
end;


function TKMapInfo.GetLobbyColor: Cardinal;
begin
  if fMapFolder = mfDL then
    Result := $FFC9BBBB
  else
    Result := $FF9CF6FF;
end;


{ TKMMapTxtInfo }
constructor TKMMapTxtInfo.Create;
begin
  ResetInfo;
end;


procedure TKMMapTxtInfo.SaveTXTInfo(const aFilePath: String);
var
  St: String;
  ft: TextFile;
  MD: TKMMissionDifficulty;

  procedure WriteLine(const aLineHeader: String; const aLineValue: String = '');
  begin
    Writeln(ft, aLineHeader);
    if aLineValue <> '' then
      Writeln(ft, aLineValue);
    Writeln(ft);
  end;

begin
  if IsEmpty then
  begin
    if FileExists(aFilePath) then
      DeleteFile(aFilePath);
    Exit;
  end;

  ForceDirectories(ExtractFilePath(aFilePath));

  AssignFile(ft, aFilePath);
  Rewrite(ft);

  if Author <> '' then
    WriteLine('Author', Author);

  if Version <> '' then
    WriteLine('Version', Version);

  if SmallDescLibx <> -1 then
    WriteLine('SmallDescLIBX', IntToStr(SmallDescLibx))
  else if SmallDesc <> '' then
    WriteLine('SmallDesc', SmallDesc);

  if BigDescLibx <> -1 then
    WriteLine('BigDescLIBX', IntToStr(BigDescLibx))
  else if BigDesc <> '' then
    WriteLine('BigDesc', BigDesc);

  if IsCoop then
    WriteLine('SetCoop');

  if IsSpecial then
    WriteLine('SetSpecial');

  if IsRMG then
    WriteLine('RMG');

  if IsPlayableAsSP then
    WriteLine('PlayableAsSP');

  if BlockPeacetime then
    WriteLine('BlockPeacetime');

  if BlockTeamSelection then
    WriteLine('BlockTeamSelection');

  if BlockColorSelection then
    WriteLine('BlockColorSelection');

  if BlockFullMapPreview then
    WriteLine('BlockFullMapPreview');

  if HasDifficultyLevels then
  begin
    St := '';
    for MD := MISSION_DIFFICULTY_MIN to MISSION_DIFFICULTY_MAX do
      if MD in DifficultyLevels then
      begin
        if St <> '' then
          St := St + ',';
        St := St + GetEnumName(TypeInfo(TKMMissionDifficulty), Integer(MD));
      end;
    WriteLine('DifficultyLevels', St);
  end;

  CloseFile(ft);
end;

procedure TKMMapTxtInfo.LoadTXTInfo(const aFilePath: String);

  function LoadDescriptionFromLIBX(aIndex: Integer): UnicodeString;
  var
    missionTexts: TKMTextLibrarySingle;
  begin
    Result := '';
    if aIndex = -1 then Exit;
    missionTexts := TKMTextLibrarySingle.Create;
    missionTexts.LoadLocale(ChangeFileExt(aFilePath, '.%s.libx'));
    Result := missionTexts.Texts[aIndex];
    missionTexts.Free;
  end;

var
  I: Integer;
  St, S: String;
  ft: TextFile;
  stList: TStringList;
  MD: TKMMissionDifficulty;
begin
  //Load additional text info
  if FileExists(aFilePath) then
  begin
    AssignFile(ft, aFilePath);
    FileMode := fmOpenRead;
    Reset(ft);
    repeat
      ReadLn(ft, St);
      if SameText(St, 'Author') then
        Readln(ft, Author);
      if SameText(St, 'Version') then
        Readln(ft, Version);
      if SameText(St, 'BigDesc') then
        Readln(ft, BigDesc);

      if SameText(St, 'BigDescLIBX') then
      begin
        Readln(ft, S);
        BigDescLibx := StrToIntDef(S, -1);
        BigDesc := LoadDescriptionFromLIBX(BigDescLibx);
      end;

      if SameText(St, 'SmallDesc') then
        ReadLn(ft, SmallDesc);

      if SameText(St, 'SmallDescLIBX') then
      begin
        Readln(ft, S);
        SmallDescLibx := StrToIntDef(S, -1);
        SmallDesc := LoadDescriptionFromLIBX(SmallDescLibx);
      end;

      if SameText(St, 'SetCoop')   then
      begin
        IsCoop := True;
        BlockTeamSelection := True;
        BlockPeacetime := True;
        BlockFullMapPreview := True;
      end;

      if SameText(St, 'SetSpecial') then
        IsSpecial := True;
      if SameText(St, 'RMG') then
        IsRMG := True;
      if SameText(St, 'PlayableAsSP') then
        IsPlayableAsSP := True;
      if SameText(St, 'BlockTeamSelection') then
        BlockTeamSelection := True;
      if SameText(St, 'BlockColorSelection') then
        BlockColorSelection := True;
      if SameText(St, 'BlockPeacetime') then
        BlockPeacetime := True;
      if SameText(St, 'BlockFullMapPreview') then
        BlockFullMapPreview := True;

      if SameText(St, 'DifficultyLevels') then
      begin
        Readln(ft, S);
        stList := TStringList.Create;
        StringSplit(S, ',', stList);
        for I := 0 to stList.Count - 1 do
          for MD := MISSION_DIFFICULTY_MIN to MISSION_DIFFICULTY_MAX do
            if SameText(stList[I], GetEnumName(TypeInfo(TKMMissionDifficulty), Integer(MD))) then
              Include(DifficultyLevels, MD);
        stList.Free;
      end;
    until(eof(ft));
    CloseFile(ft);
  end;
end;


procedure TKMMapTxtInfo.SetBigDesc(const aBigDesc: UnicodeString);
begin
  BigDesc := aBigDesc;
end;


function TKMMapTxtInfo.GetBigDesc: UnicodeString;
begin
  Result := BigDesc;
end;


function TKMMapTxtInfo.GetBlockColorSelection: Boolean;
begin
  if Self = nil then Exit(False);

  Result := fBlockColorSelection;
end;


function TKMMapTxtInfo.IsSmallDescLibxSet: Boolean;
begin
  Result := SmallDescLibx <> -1;
end;


function TKMMapTxtInfo.IsBigDescLibxSet: Boolean;
begin
  Result := BigDescLibx <> -1;
end;


function TKMMapTxtInfo.IsEmpty: Boolean;
begin
  Result := not (IsCoop or IsSpecial or IsPlayableAsSP or IsRMG
            or BlockTeamSelection or BlockColorSelection or BlockPeacetime or BlockFullMapPreview
            or (Author <> '') or (Version <> '')
            or (SmallDesc <> '') or IsSmallDescLibxSet
            or (BigDesc <> '') or IsBigDescLibxSet
            or HasDifficultyLevels);
end;


function TKMMapTxtInfo.HasDifficultyLevels: Boolean;
var
  MD: TKMMissionDifficulty;
begin
  Result := (DifficultyLevels <> []);
  //We consider there is no difficulty levels, if only one is presented
  for MD := MISSION_DIFFICULTY_MIN to MISSION_DIFFICULTY_MAX do
    Result := Result and (DifficultyLevels <> [MD]);
end;


procedure TKMMapTxtInfo.ResetInfo;
begin
  IsCoop := False;
  IsSpecial := False;
  IsRMG := False;
  IsPlayableAsSP := False;
  BlockTeamSelection := False;
  BlockColorSelection := False;
  BlockPeacetime := False;
  BlockFullMapPreview := False;
  DifficultyLevels := [];
  Author := '';
  Version := '';
  SmallDesc := '';
  SmallDescLibx := -1;
  BigDesc := '';
  BigDescLibx := -1;
end;


procedure TKMMapTxtInfo.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.CheckMarker(MAP_TXT_INFO_MARKER);

  LoadStream.ReadW(Author);
  LoadStream.ReadW(Version);
  LoadStream.Read(IsCoop);
  LoadStream.Read(IsSpecial);
  LoadStream.Read(IsRMG);
  LoadStream.Read(IsPlayableAsSP);

  LoadStream.Read(BlockTeamSelection);
  LoadStream.Read(fBlockColorSelection);
  LoadStream.Read(BlockPeacetime);
  LoadStream.Read(BlockFullMapPreview);

  LoadStream.ReadW(SmallDesc);
  LoadStream.Read(SmallDescLibx);

  LoadStream.ReadW(BigDesc);
  LoadStream.Read(BigDescLibx);
end;


procedure TKMMapTxtInfo.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.PlaceMarker(MAP_TXT_INFO_MARKER);

  SaveStream.WriteW(Author);
  SaveStream.WriteW(Version);
  SaveStream.Write(IsCoop);
  SaveStream.Write(IsSpecial);
  SaveStream.Write(IsRMG);
  SaveStream.Write(IsPlayableAsSP);

  SaveStream.Write(BlockTeamSelection);
  SaveStream.Write(fBlockColorSelection);
  SaveStream.Write(BlockPeacetime);
  SaveStream.Write(BlockFullMapPreview);

  SaveStream.WriteW(SmallDesc);
  SaveStream.Write(SmallDescLibx);

  SaveStream.WriteW(BigDesc);
  SaveStream.Write(BigDescLibx);
end;


{ TKMapsCollection }
constructor TKMapsCollection.Create(aMapFolders: TKMapFolderSet; aSortMethod: TKMapsSortMethod = smByNameDesc; aDoSortWithFavourites: Boolean = False);
begin
  inherited Create;

  fMapFolders := aMapFolders;
  fSortMethod := aSortMethod;
  fDoSortWithFavourites := aDoSortWithFavourites;

  //CS is used to guard sections of code to allow only one thread at once to access them
  //We mostly don't need it, as UI should access Maps only when map events are signaled
  //it mostly acts as a safenet
  fCriticalSection := TCriticalSection.Create;
end;


function TKMapsCollection.Contains(const aNewName: UnicodeString): Boolean;
var
  I: Integer;
begin
  Result := False;

  for I := 0 to fCount - 1 do
    if LowerCase(fMaps[I].FileName) = LowerCase(aNewName) then
    begin
      Result := True;
      Exit;
    end;
end;


constructor TKMapsCollection.Create(aMapFolder: TKMapFolder; aSortMethod: TKMapsSortMethod = smByNameDesc; aDoSortWithFavourites: Boolean = False);
begin
  Create([aMapFolder], aSortMethod, aDoSortWithFavourites);
end;


destructor TKMapsCollection.Destroy;
begin
  //Terminate and release the Scanner if we have one working or finished
  TerminateScan;

  //Release TKMapInfo objects
  Clear;

  fCriticalSection.Free;
  inherited;
end;


function TKMapsCollection.GetMap(aIndex: Integer): TKMapInfo;
begin
  //No point locking/unlocking here since we return a TObject that could be modified/freed
  //by another thread before the caller uses it.
  Assert(InRange(aIndex, 0, fCount - 1));
  Result := fMaps[aIndex];
end;


//class function TKMapsCollection.GuessMPPath(const aName, aExt: string; aCRC: Cardinal): string;
//var
//  S: UnicodeString;
//begin
//  S := aName + '_' + IntToHex(aCRC, 8);
//  Result := MAP_FOLDER[mfDL] + PathDelim + S + PathDelim + S + aExt;
//  if not FileExists(ExeDir + Result) then
//    Result := MAP_FOLDER[mfMP] + PathDelim + aName + PathDelim + aName + aExt;
//end;


procedure TKMapsCollection.Lock;
begin
  fCriticalSection.Enter;
end;


procedure TKMapsCollection.Unlock;
begin
  fCriticalSection.Leave;
end;


procedure TKMapsCollection.Clear;
var
  I: Integer;
begin
  Assert(not fScanning, 'Guarding from access to inconsistent data');
  for I := 0 to fCount - 1 do
    FreeAndNil(fMaps[I]);
  fCount := 0;
  SetLength(fMaps, 0); //We could use Low and High. Need to reset array to 0 length
end;


procedure TKMapsCollection.UpdateState;
begin
  if fUpdateNeeded then
  begin
    if Assigned(fOnRefresh) then
      fOnRefresh(Self);

    fUpdateNeeded := False;
  end;
end;


procedure TKMapsCollection.DeleteMap(aIndex: Integer);
var
  I: Integer;
begin
   Lock;
   try
     Assert(InRange(aIndex, 0, fCount - 1));
     KMDeleteFolder(fMaps[aIndex].Path);
     fMaps[aIndex].Free;
     for I  := aIndex to fCount - 2 do
       fMaps[I] := fMaps[I + 1];
     Dec(fCount);
     SetLength(fMaps, fCount);
   finally
     Unlock;
   end;
end;


procedure TKMapsCollection.RenameMap(aIndex: Integer; const aName: UnicodeString);
begin
  MoveMap(aIndex, aName, fMaps[aIndex].fMapFolder);
end;


procedure TKMapsCollection.MoveMap(aIndex: Integer; const aName: UnicodeString; aMapFolder: TKMapFolder);
var
  I: Integer;
  dest: UnicodeString;
begin
  Assert(InRange(aIndex, 0, fCount - 1));
  if Trim(aName) = '' then Exit;

  Lock;
  try
    dest := ExeDir + MAP_FOLDER[aMapFolder] + PathDelim + aName + PathDelim;
    Assert(fMaps[aIndex].Path <> dest);

    KMMoveFolder(fMaps[aIndex].Path, dest);

    //Remove the map from our list
    fMaps[aIndex].Free;
    for I  := aIndex to fCount - 2 do
      fMaps[I] := fMaps[I + 1];
    Dec(fCount);
    SetLength(fMaps, fCount);
  finally
    Unlock;
  end;
end;


//For private access, where CS is managed by the caller
procedure TKMapsCollection.DoSort;
var
  tempMaps: array of TKMapInfo;

  //Return True if items should be exchanged
  function Compare(A, B: TKMapInfo): Boolean;
  begin
    Result := False; //By default everything remains in place
    case fSortMethod of
      smByFavouriteAsc:       Result := A.IsFavourite and not B.IsFavourite;
      smByFavouriteDesc:      Result := not A.IsFavourite and B.IsFavourite;
      smByNameAsc:            Result := CompareText(A.FileName, B.FileName) < 0;
      smByNameDesc:           Result := CompareText(A.FileName, B.FileName) > 0;
      smBySizeAsc:            Result := MapSizeIndex(A.MapSizeX, A.MapSizeY) < MapSizeIndex(B.MapSizeX, B.MapSizeY);
      smBySizeDesc:           Result := MapSizeIndex(A.MapSizeX, A.MapSizeY) > MapSizeIndex(B.MapSizeX, B.MapSizeY);
      smByPlayersAsc:         Result := A.LocCount < B.LocCount;
      smByPlayersDesc:        Result := A.LocCount > B.LocCount;
      smByHumanPlayersAsc:    Result := A.HumanPlayerCount < B.HumanPlayerCount;
      smByHumanPlayersDesc:   Result := A.HumanPlayerCount > B.HumanPlayerCount;
      smByHumanPlayersMPAsc:  Result := A.HumanPlayerCountMP < B.HumanPlayerCountMP;
      smByHumanPlayersMPDesc: Result := A.HumanPlayerCountMP > B.HumanPlayerCountMP;
      smByMissionModeAsc:     Result := A.MissionMode < B.MissionMode;
      smByMissionModeDesc:    Result := A.MissionMode > B.MissionMode;
    end;
    if fDoSortWithFavourites and not (fSortMethod in [smByFavouriteAsc, smByFavouriteDesc]) then
    begin
      if A.IsFavourite and not B.IsFavourite then
        Result := False
      else if not A.IsFavourite and B.IsFavourite then
        Result := True
    end;

  end;

  procedure MergeSort(aLeft, aRight: Integer);
  var
    middle, I, J, ind1, ind2: integer;
  begin
    if aRight <= aLeft then
      exit;

    middle := (aLeft+aRight) div 2;
    MergeSort(aLeft, middle);
    Inc(middle);
    MergeSort(middle, aRight);
    ind1 := aLeft;
    ind2 := middle;
    for I := aLeft to aRight do
    begin
      if (ind1 < middle) and ((ind2 > aRight) or not Compare(fMaps[ind1], fMaps[ind2])) then
      begin
        tempMaps[I] := fMaps[ind1];
        Inc(ind1);
      end
      else
      begin
        tempMaps[I] := fMaps[ind2];
        Inc(ind2);
      end;
    end;
    for J := aLeft to aRight do
      fMaps[J] := tempMaps[J];
  end;
begin
  SetLength(tempMaps, fCount);
  MergeSort(0, fCount - 1);
end;


//For public access
//Apply new Sort within Critical Section, as we could be in the Refresh phase
//note that we need to preserve fScanning flag
procedure TKMapsCollection.Sort(aSortMethod: TKMapsSortMethod; aOnSortComplete: TNotifyEvent);
begin
  Lock;
  try
    if fScanning then
    begin
      fScanning := False;
      fSortMethod := aSortMethod;
      DoSort;
      if Assigned(aOnSortComplete) then
        aOnSortComplete(Self);
      fScanning := True;
    end
    else
    begin
      fSortMethod := aSortMethod;
      DoSort;
      if Assigned(aOnSortComplete) then
        aOnSortComplete(Self);
    end;
  finally
    Unlock;
  end;
end;


procedure TKMapsCollection.TerminateScan;
begin
  if (fScanner <> nil) then
  begin
    fScanner.Terminate;
    fScanner.WaitFor;
    fScanner.Free;
    fScanner := nil;
    fScanning := False;
  end;
  fUpdateNeeded := False; //If the scan was terminated we should not run fOnRefresh next UpdateState
end;


//Start the refresh of maplist
procedure TKMapsCollection.Refresh(aOnRefresh: TNotifyEvent; aOnTerminate: TNotifyEvent = nil; aOnComplete: TNotifyEvent = nil);
begin
  //Terminate previous Scanner if two scans were launched consequentialy
  TerminateScan;
  Clear;

  fOnRefresh := aOnRefresh;
  fOnComplete := aOnComplete;
  fOnTerminate := aOnTerminate;

  //Scan will launch upon create automatically
  fScanning := True;
  fScanner := TTMapsScanner.Create(fMapFolders, MapAdd, MapAddDone, ScanTerminate, ScanComplete);
end;


procedure TKMapsCollection.MapAdd(aMap: TKMapInfo);
begin
  Lock;
  try
    SetLength(fMaps, fCount + 1);
    fMaps[fCount] := aMap;
    Inc(fCount);

    //Set the scanning to false so we could Sort
    fScanning := False;

    //Keep the maps sorted
    //We signal from Locked section, so everything caused by event can safely access our Maps
    DoSort;

    fScanning := True;
  finally
    Unlock;
  end;
end;


procedure TKMapsCollection.MapAddDone(Sender: TObject);
begin
  fUpdateNeeded := True; //Next time the GUI thread calls UpdateState we will run fOnRefresh
end;


//All maps have been scanned
//No need to resort since that was done in last MapAdd event
procedure TKMapsCollection.ScanComplete(Sender: TObject);
begin
  Lock;
  try
    fScanning := False;
    if Assigned(fOnComplete) then
      fOnComplete(Self);
  finally
    Unlock;
  end;
end;


//Scan was terminated
//No need to resort since that was done in last MapAdd event
procedure TKMapsCollection.ScanTerminate(Sender: TObject);
begin
  Lock;
  try
    fScanning := False;
    if Assigned(fOnTerminate) then
      fOnTerminate(Self);
  finally
    Unlock;
  end;
end;


class function TKMapsCollection.FullPath(const aName, aExt: string; aMultiplayer: Boolean): string;
begin
  Result := FullPath(aName, aExt, GetMapFolderType(aMultiplayer));
end;


class function TKMapsCollection.FullPath(const aName, aExt: string; aMapFolder: TKMapFolder): string;
begin
  Result := ExeDir + MAP_FOLDER[aMapFolder] + PathDelim + aName + PathDelim + aName + aExt;
end;


class function TKMapsCollection.FullPath(const aDirName, aFileName, aExt: string; aMapFolder: TKMapFolder): string;
begin
  Result := ExeDir + MAP_FOLDER[aMapFolder] + PathDelim + aDirName + PathDelim + aFileName + aExt;
end;


class function TKMapsCollection.FullPath(const aName, aExt: string; aMapFolder: TKMapFolder; aCRC: Cardinal): string;
var
  S: UnicodeString;
begin
  S := aName;
  if aMapFolder = mfDL then
    S := S + '_' + IntToHex(Integer(aCRC), 8);
  Result := FullPath(S, aExt, aMapFolder);
end;


class function TKMapsCollection.GetMapCRC(const aMapPath: string): Cardinal;
begin
  Result := 0;
  if FileExists(aMapPath) then
    Result := Adler32CRC(aMapPath);
end;


class procedure TKMapsCollection.GetAllMapPaths(const aExeDir: string; aList: TStringList);
var
  I: Integer;
  searchRec: TSearchRec;
  pathToMaps: TStringList;
begin
  aList.Clear;

  pathToMaps := TStringList.Create;
  try
    pathToMaps.Add(aExeDir + MAPS_FOLDER_NAME + PathDelim);
    pathToMaps.Add(aExeDir + MAPS_MP_FOLDER_NAME + PathDelim);
    pathToMaps.Add(aExeDir + TUTORIALS_FOLDER_NAME + PathDelim);

    //Include all campaigns maps
    FindFirst(aExeDir + CAMPAIGNS_FOLDER_NAME + PathDelim + '*', faDirectory, searchRec);
    try
      repeat
        if (searchRec.Name <> '.') and (searchRec.Name <> '..') then
          pathToMaps.Add(aExeDir + CAMPAIGNS_FOLDER_NAME + PathDelim + searchRec.Name + PathDelim);
      until (FindNext(searchRec) <> 0);
    finally
      FindClose(searchRec);
    end;

    for I := 0 to pathToMaps.Count - 1 do
    if DirectoryExists(pathToMaps[I]) then
    begin
      FindFirst(pathToMaps[I] + '*', faDirectory, searchRec);
      try
        repeat
          if (searchRec.Name <> '.') and (searchRec.Name <> '..')
          and FileExists(pathToMaps[I] + searchRec.Name + PathDelim + searchRec.Name + '.dat')
          and FileExists(pathToMaps[I] + searchRec.Name + PathDelim + searchRec.Name + '.map') then
            aList.Add(pathToMaps[I] + searchRec.Name + PathDelim + searchRec.Name + '.dat');
        until (FindNext(searchRec) <> 0);
      finally
        FindClose(searchRec);
      end;
    end;
  finally
    pathToMaps.Free;
  end;
end;


{ TTCustomMapsScanner }
constructor TTCustomMapsScanner.Create(aMapFolders: TKMapFolderSet; aOnComplete: TNotifyEvent = nil);
begin
  //Thread isn't started until all constructors have run to completion
  //so Create(False) may be put in front as well
  inherited Create(False);

  fMapFolders := aMapFolders;
  fOnComplete := aOnComplete;
  FreeOnTerminate := False;
end;


procedure TTCustomMapsScanner.Execute;
var
  searchRec: TSearchRec;
  pathToMaps: string;
  MF: TKMapFolder;
begin
  gLog.MultithreadLogging := True; // We could log smth while create map cache or scan maps
  try
    try
      for MF in fMapFolders do
      begin
        pathToMaps := ExeDir + MAP_FOLDER[MF] + PathDelim;

        if not DirectoryExists(pathToMaps) then Exit;

        FindFirst(pathToMaps + '*', faDirectory, searchRec);
        try
          repeat
            if (searchRec.Name <> '.') and (searchRec.Name <> '..')
              and FileExists(TKMapsCollection.FullPath(searchRec.Name, '.dat', MF))
              and FileExists(TKMapsCollection.FullPath(searchRec.Name, '.map', MF)) then
            begin
              try
                ProcessMap(searchRec.Name, MF);
              except
                on E: Exception do
                  gLog.AddTime('Error loading map ''' + searchRec.Name + ''''); //Just silently log an exception
              end;
            end;
          until (FindNext(searchRec) <> 0) or Terminated;
        finally
          FindClose(searchRec);
        end;
      end;
    finally
      if not Terminated and Assigned(fOnComplete) then
        fOnComplete(Self);
    end;
  finally
    gLog.MultithreadLogging := False;
  end;
end;


{ TTMapsScanner }
//aOnMapAdd - signal that there's new map that should be added
//aOnMapAddDone - signal that map has been added
//aOnTerminate - scan was terminated (but could be not complete yet)
//aOnComplete - scan is complete
constructor TTMapsScanner.Create(aMapFolders: TKMapFolderSet; aOnMapAdd: TKMapEvent; aOnMapAddDone, aOnTerminate: TNotifyEvent; aOnComplete: TNotifyEvent = nil);
begin
  inherited Create(aMapFolders, aOnComplete);

  Assert(Assigned(aOnMapAdd));

  {$IFDEF DEBUG}
  TThread.NameThreadForDebugging('MapsScanner', ThreadID);
  {$ENDIF}

  fOnMapAdd := aOnMapAdd;
  fOnMapAddDone := aOnMapAddDone;
  OnTerminate := aOnTerminate;
  FreeOnTerminate := False;
end;


procedure TTMapsScanner.ProcessMap(const aPath: UnicodeString; aFolder: TKMapFolder);
var
  map: TKMapInfo;
begin
  map := TKMapInfo.Create(aPath, False, aFolder);

  if SLOW_MAP_SCAN then
    Sleep(50);

  fOnMapAdd(map);
  fOnMapAddDone(Self);
end;


{ TTMapsCacheUpdater }
constructor TTMapsCacheUpdater.Create(aMapFolders: TKMapFolderSet);
begin
  inherited Create(aMapFolders);

  {$IFDEF DEBUG}
  TThread.NameThreadForDebugging('MapsCacheUpdater', ThreadID);
  {$ENDIF}

  FreeOnTerminate := True;
end;


procedure TTMapsCacheUpdater.ProcessMap(const aPath: UnicodeString; aFolder: TKMapFolder);
var
  map: TKMapInfo;
begin
  //Simply creating the TKMapInfo updates the .mi cache file
  if not fIsStopped then
  begin
    map := TKMapInfo.Create(aPath, False, aFolder);
    map.Free;
  end;
end;


procedure TTMapsCacheUpdater.Stop;
begin
  if Self <> nil then
    fIsStopped := True;
end;


{Utility methods}
//Try to determine TMapFolder for specified aFolderName
//Returns true when succeeded
function DetermineMapFolder(const aFolderName: UnicodeString; out aMapFolder: TKMapFolder): Boolean;
var
  F: TKMapFolder;
begin
  for F := Low(TKMapFolder) to High(TKMapFolder) do
    if aFolderName = MAP_FOLDER[F] then
    begin
      aMapFolder := F;
      Result := True;
      Exit;
    end;
  Result := False;
end;


function GetMapFolderType(aIsMultiplayer: Boolean): TKMapFolder;
begin
  if aIsMultiplayer then
    Result := mfMP
  else
    Result := mfSP;
end;


end.

