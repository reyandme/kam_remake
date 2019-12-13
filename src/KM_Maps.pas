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
    function IsEmpty: Boolean;
    procedure Load(LoadStream: TKMemoryStream);
    procedure Save(SaveStream: TKMemoryStream);
  public
    Author, BigDesc, SmallDesc: UnicodeString;
    SmallDescLibx, BigDescLibx: Integer;
    IsCoop: Boolean; //Some multiplayer missions are defined as coop
    IsSpecial: Boolean; //Some missions are defined as special (e.g. tower defence, quest, etc.)
    IsPlayableAsSP: Boolean; //Is MP map playable as SP map ?

    DifficultyLevels: TKMMissionDifficultySet;

    BlockTeamSelection: Boolean;
    BlockPeacetime: Boolean;
    BlockFullMapPreview: Boolean;

    constructor Create;
    procedure SetBigDesc(const aBigDesc: UnicodeString);
    function GetBigDesc: UnicodeString;

    function IsSmallDescLibxSet: Boolean;
    function IsBigDescLibxSet: Boolean;

    procedure ResetInfo;

    procedure SaveTXTInfo(const aFilePath: String);
    procedure LoadTXTInfo(const aFilePath: String);
    function HasDifficultyLevels: Boolean;
  end;


  TKMMapTxtInfoArray = array of TKMMapTxtInfo;


  TKMapInfo = class
  private
    fPath: String;
    fFileName: UnicodeString; //without extension
    fCRC: Cardinal;
    fDatCRC: Cardinal; //Used to speed up scanning
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

    property TxtInfo: TKMMapTxtInfo read fTxtInfo;
    property BigDesc: UnicodeString read GetBigDesc write SetBigDesc;
    property InfoAmount: TKMMapInfoAmount read fInfoAmount;
    property Path: string read fPath;
    property MapFolder: TKMapFolder read fMapFolder;
    property FileName: UnicodeString read fFileName;
    function FullPath(const aExt: string): string;
    function HumanUsableLocs: TKMHandIDArray;
    function AIUsableLocs: TKMHandIDArray;
    function AdvancedAIUsableLocs: TKMHandIDArray;
    property CRC: Cardinal read fCRC;
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
    fIsStopped: Boolean;
    procedure ProcessMap(const aPath: UnicodeString; aFolder: TKMapFolder); override;
  public
    constructor Create(aMapFolders: TKMapFolderSet; aOnMapAdd: TKMapEvent; aOnMapAddDone, aOnTerminate: TNotifyEvent; aOnComplete: TNotifyEvent = nil);
    procedure Stop;
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
    CS: TCriticalSection;
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
    class function GuessMPPath(const aName, aExt: string; aCRC: Cardinal): string;
    class procedure GetAllMapPaths(const aExeDir: string; aList: TStringList);
    class function GetMapCRC(const aName: UnicodeString; aIsMultiplayer: Boolean): Cardinal;

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
  KM_GameApp, KM_FileIO,
  KM_MissionScript_Info, KM_Scripting,
  KM_Utils, KM_CommonUtils, KM_Log;


const
  //Map folder name by folder type. Containing single maps, for SP/MP/DL mode
  MAP_FOLDER: array [TKMapFolder] of string = (MAPS_FOLDER_NAME, MAPS_MP_FOLDER_NAME, MAPS_DL_FOLDER_NAME);

  CUSTOM_MAP_PARAM_DESCR_TX: array[TKMCustomScriptParam] of Integer = (TX_MAP_CUSTOM_PARAM_TH_TROOP_COST, TX_MAP_CUSTOM_PARAM_MARKET_PRICE);


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
  DatFile, MapFile, ScriptFile, TxtFile, LIBXFiles: string;
  DatCRC, OthersCRC: Cardinal;
  fMissionParser: TKMMissionParserInfo;
  ScriptPreProcessor: TKMScriptingPreProcessor;
  ScriptFiles: TKMScriptFilesCollection;
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

  DatFile := fPath + fFileName + '.dat';
  MapFile := fPath + fFileName + '.map';
  ScriptFile := fPath + fFileName + EXT_FILE_SCRIPT_DOT; //Needed for CRC
  TxtFile := fPath + fFileName + '.txt'; //Needed for CRC
  LIBXFiles := fPath + fFileName + '.*.libx'; //Needed for CRC

  fSizeText := ''; //Lazy initialization

  if not FileExists(DatFile) then Exit;

  //Try loading info from cache, since map scanning is rather slow
  LoadFromFile(fPath + fFileName + '.mi'); //Data will be empty if failed

  //We will scan map once again if anything has changed
  //In SP mode (non-strict) we check DAT CRC and version, that is enough
  //In MP mode (strict) we also need exact CRCs to match maps between players

  DatCRC := Adler32CRC(DatFile);
  //.map file CRC is the slowest, so only calculate it if necessary
  OthersCRC := 0; //Supresses incorrect warning by Delphi
  if aStrictParsing then
  begin
    OthersCRC := Adler32CRC(MapFile) xor Adler32CRC(TxtFile) xor GetLIBXCRC(LIBXFiles);

    //Add main script CRC and all included scripts CRC
    if FileExists(ScriptFile) then
    begin
      OthersCRC := OthersCRC xor Adler32CRC(ScriptFile);
      ScriptPreProcessor := TKMScriptingPreProcessor.Create;
      try
        if ScriptPreProcessor.PreProcessFile(ScriptFile) then
        begin
          //Copy custom script params
          for CSP := Low(TKMCustomScriptParam) to High(TKMCustomScriptParam) do
            fCustomScriptParams[CSP] := ScriptPreProcessor.CustomScriptParams[CSP];

          ScriptFiles := ScriptPreProcessor.ScriptFilesInfo;
          for I := 0 to ScriptFiles.IncludedCount - 1 do
            OthersCRC := OthersCRC xor Adler32CRC(ScriptFiles[I].FullFilePath);
        end;
      finally
        ScriptPreProcessor.Free;
      end;
    end;
  end;

  //Does the map need to be fully rescanned? (.mi cache is outdated?)
  if (fVersion <> GAME_REVISION) or
     (fDatCRC <> DatCRC) or //In non-strict mode only DAT CRC matters (SP)
     (aStrictParsing and (fCRC <> DatCRC xor OthersCRC)) //In strict mode we check all CRCs (MP)
  then
  begin
    //Calculate OthersCRC if it wasn't calculated before
    if not aStrictParsing then
      OthersCRC := Adler32CRC(MapFile) xor Adler32CRC(ScriptFile) xor Adler32CRC(TxtFile);

    fCRC := DatCRC xor OthersCRC;
    fDatCRC := DatCRC;
    fVersion := GAME_REVISION;

    //First reset everything because e.g. CanBeHuman is assumed false by default and set true when we encounter SET_USER_PLAYER
    ResetInfo;

    fMissionParser := TKMMissionParserInfo.Create;
    try
      //Fill Self properties with MissionParser
      fMissionParser.LoadMission(DatFile, Self, pmBase);
    finally
      fMissionParser.Free;
    end;

    //Load additional text info
    fTxtInfo.LoadTXTInfo(fPath + fFileName + '.txt');

    if gGameApp.GameSettings = nil // In case we are closing app and settings object is already destroyed
      then Exit;

    IsFavourite := gGameApp.GameSettings.FavouriteMaps.Contains(fCRC);

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
var G: TKMMapGoalInfo;
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


//Load additional information for map that is not in main SP list
procedure TKMapInfo.LoadExtra;
var
  DatFile: string;
  fMissionParser: TKMMissionParserInfo;
begin
  //Do not append Extra info twice
  if fInfoAmount = iaExtra then Exit;

  //First reset everything because e.g. CanBeHuman is assumed false by default and set true when we encounter SET_USER_PLAYER
  ResetInfo;

  DatFile := fPath + fFileName + '.dat';

  fMissionParser := TKMMissionParserInfo.Create;
  try
    //Fill Self properties with MissionParser
    fMissionParser.LoadMission(DatFile, Self, pmExtra);
  finally
    fMissionParser.Free;
  end;

  if MissionMode = mmTactic then
    fTxtInfo.BlockPeacetime := True;

  fTxtInfo.LoadTXTInfo(fPath + fFileName + '.txt');

  fInfoAmount := iaExtra;
end;


procedure TKMapInfo.ResetInfo;
var I, K: Integer;
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
  S: TKMemoryStreamBinary;
begin
  Assert(aStreamObj is TKMemoryStreamBinary, 'Wrong stream object class');

  S := TKMemoryStreamBinary(aStreamObj);

  S.LoadFromFile(aPath);

  //Internal properties
  S.Read(fCRC);
  S.Read(fDatCRC);
  S.ReadA(fVersion);

  //Exposed properties
  S.Read(MapSizeX);
  S.Read(MapSizeY);
  S.Read(MissionMode, SizeOf(TKMissionMode));
  S.Read(LocCount);
  S.Read(CanBeHuman, SizeOf(CanBeHuman));

  fTxtInfo.Load(S);

  IsFavourite := gGameApp.GameSettings.FavouriteMaps.Contains(fCRC);
end;


procedure TKMapInfo.LoadFromFile(const aPath: UnicodeString);
var
  S: TKMemoryStreamBinary;
  ErrorStr: UnicodeString;
begin
  if not FileExists(aPath) then Exit;

  S := TKMemoryStreamBinary.Create;
  try
    //Try to load map cache up to 3 times (in case its updating by other thread
    //its much easier and working well, then synchronize threads
    if not TryExecuteMethod(TObject(S), aPath, 'LoadFromStreamObj', ErrorStr, LoadFromStreamObj) then
      gLog.AddTime(ErrorStr);
  finally
    //Other properties are not saved, they are fast to reload
    S.Free;
  end;
end;


procedure TKMapInfo.SaveToStreamObj(aStreamObj: TObject; const aPath: UnicodeString);
var
  S: TKMemoryStreamBinary;
begin
  Assert(aStreamObj is TKMemoryStreamBinary, 'Wrong stream object class');

  S := TKMemoryStreamBinary(aStreamObj);

  S.SaveToFile(aPath);
end;


procedure TKMapInfo.SaveToFile(const aPath: UnicodeString);
var
  S: TKMemoryStreamBinary;
  ErrorStr: UnicodeString;
begin
  S := TKMemoryStreamBinary.Create;
  try
    //Internal properties
    S.Write(fCRC);
    S.Write(fDatCRC);
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
    if not TryExecuteMethod(TObject(S), aPath, 'SaveToStreamObj', ErrorStr, SaveToStreamObj) then
      gLog.AddTime(ErrorStr);
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
var I: Integer;
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
var I: Integer;
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
var Path: String;
    Locale: AnsiString;
begin
  Result := '';
  Locale := gGameApp.GameSettings.Locale;
  Path := fPath + fFileName + '.' + String(Locale) + '.pdf'; // Try to file with our locale first
  if FileExists(Path) then
    Result := Path
  else
  begin
    Path := fPath + fFileName + '.' + String(DEFAULT_LOCALE) + '.pdf'; // then with default locale
    if FileExists(Path) then
      Result := Path
    else
    begin
      Path := fPath + fFileName + '.pdf'; // and finally without any locale
      if FileExists(Path) then
        Result := Path;
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

  if IsPlayableAsSP then
    WriteLine('PlayableAsSP');

  if BlockPeacetime then
    WriteLine('BlockPeacetime');

  if BlockTeamSelection then
    WriteLine('BlockTeamSelection');

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
    MissionTexts: TKMTextLibrarySingle;
  begin
    Result := '';
    if aIndex = -1 then Exit;
    MissionTexts := TKMTextLibrarySingle.Create;
    MissionTexts.LoadLocale(ChangeFileExt(aFilePath, '.%s.libx'));
    Result := MissionTexts.Texts[aIndex];
    MissionTexts.Free;
  end;

var
  I: Integer;
  St, S: String;
  ft: TextFile;
  StList: TStringList;
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
        BlockPeacetime := True;
        BlockTeamSelection := True;
        BlockFullMapPreview := True;
      end;

      if SameText(St, 'SetSpecial') then
        IsSpecial := True;
      if SameText(St, 'PlayableAsSP') then
        IsPlayableAsSP := True;
      if SameText(St, 'BlockPeacetime') then
        BlockPeacetime := True;
      if SameText(St, 'BlockTeamSelection') then
        BlockTeamSelection := True;
      if SameText(St, 'BlockFullMapPreview') then
        BlockFullMapPreview := True;

      if SameText(St, 'DifficultyLevels') then
      begin
        Readln(ft, S);
        StList := TStringList.Create;
        StringSplit(S, ',', StList);
        for I := 0 to StList.Count - 1 do
          for MD := MISSION_DIFFICULTY_MIN to MISSION_DIFFICULTY_MAX do
            if SameText(StList[I], GetEnumName(TypeInfo(TKMMissionDifficulty), Integer(MD))) then
              Include(DifficultyLevels, MD);
        StList.Free;
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
  Result := not (IsCoop or IsSpecial or IsPlayableAsSP
            or BlockTeamSelection or BlockPeacetime or BlockFullMapPreview
            or (Author <> '')
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
  IsPlayableAsSP := False;
  BlockTeamSelection := False;
  BlockPeacetime := False;
  BlockFullMapPreview := False;
  DifficultyLevels := [];
  Author := '';
  SmallDesc := '';
  SmallDescLibx := -1;
  BigDesc := '';
  BigDescLibx := -1;
end;


procedure TKMMapTxtInfo.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.Read(IsCoop);
  LoadStream.Read(IsSpecial);
  LoadStream.Read(IsPlayableAsSP);

  LoadStream.Read(BlockTeamSelection);
  LoadStream.Read(BlockPeacetime);
  LoadStream.Read(BlockFullMapPreview);

  LoadStream.ReadW(SmallDesc);
  LoadStream.Read(SmallDescLibx);
//  aStream.ReadW(fBigDesc);
end;


procedure TKMMapTxtInfo.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.Write(IsCoop);
  SaveStream.Write(IsSpecial);
  SaveStream.Write(IsPlayableAsSP);

  SaveStream.Write(BlockTeamSelection);
  SaveStream.Write(BlockPeacetime);
  SaveStream.Write(BlockFullMapPreview);

  SaveStream.WriteW(SmallDesc);
  SaveStream.Write(SmallDescLibx);
//  aStream.WriteW(fBigDesc);
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
  CS := TCriticalSection.Create;
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

  CS.Free;
  inherited;
end;


function TKMapsCollection.GetMap(aIndex: Integer): TKMapInfo;
begin
  //No point locking/unlocking here since we return a TObject that could be modified/freed
  //by another thread before the caller uses it.
  Assert(InRange(aIndex, 0, fCount - 1));
  Result := fMaps[aIndex];
end;


class function TKMapsCollection.GuessMPPath(const aName, aExt: string; aCRC: Cardinal): string;
var S: UnicodeString;
begin
  S := aName + '_' + IntToHex(aCRC, 8);
  Result := MAP_FOLDER[mfDL] + PathDelim + S + PathDelim + S + aExt;
  if not FileExists(ExeDir + Result) then
    Result := MAP_FOLDER[mfMP] + PathDelim + aName + PathDelim + aName + aExt;
end;


procedure TKMapsCollection.Lock;
begin
  CS.Enter;
end;


procedure TKMapsCollection.Unlock;
begin
  CS.Leave;
end;


procedure TKMapsCollection.Clear;
var
  I: Integer;
begin
  Assert(not fScanning, 'Guarding from access to inconsistent data');
  for I := 0 to fCount - 1 do
    FreeAndNil(fMaps[I]);
  fCount := 0;
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
  Dest: UnicodeString;
begin
  Assert(InRange(aIndex, 0, fCount - 1));
  if Trim(aName) = '' then Exit;

  Lock;
  try
    Dest := ExeDir + MAP_FOLDER[aMapFolder] + PathDelim + aName + PathDelim;
    Assert(fMaps[aIndex].Path <> Dest);

    KMMoveFolder(fMaps[aIndex].Path, Dest);

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
var TempMaps: array of TKMapInfo;

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
      smByMissionModeAsc:            Result := A.MissionMode < B.MissionMode;
      smByMissionModeDesc:           Result := A.MissionMode > B.MissionMode;
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
  var Middle, I, J, Ind1, Ind2: integer;
  begin
    if aRight <= aLeft then
      exit;

    Middle := (aLeft+aRight) div 2;
    MergeSort(aLeft, Middle);
    Inc(Middle);
    MergeSort(Middle, aRight);
    Ind1 := aLeft;
    Ind2 := Middle;
    for I := aLeft to aRight do
    begin
      if (Ind1 < Middle) and ((Ind2 > aRight) or not Compare(fMaps[Ind1], fMaps[Ind2])) then
      begin
        TempMaps[I] := fMaps[Ind1];
        Inc(Ind1);
      end
      else
      begin
        TempMaps[I] := fMaps[Ind2];
        Inc(Ind2);
      end;
    end;
    for J := aLeft to aRight do
      fMaps[J] := TempMaps[J];
  end;
begin
  SetLength(TempMaps, Length(fMaps));
  MergeSort(Low(fMaps), High(fMaps));
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
    fScanner.Stop;
//We use Stop instead now, since WaitFor sometimes freeze (deadlock?)
//Thread will be not terminated, but its not a big problem actually
//Need to Free object here actually, but we still could get deadlock on it...
//    fScanner.WaitFor;
//    fScanner.Free;
//    fScanner := nil;
  end;
  fScanning := False;
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
  if not fScanning then
    Exit;

  Lock;
  try
    fScanning := False;
//    Stop;
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
var S: UnicodeString;
begin
  S := aName;
  if aMapFolder = mfDL then
    S := S + '_' + IntToHex(Integer(aCRC), 8);
  Result := FullPath(S, aExt, aMapFolder);
end;


class function TKMapsCollection.GetMapCRC(const aName: UnicodeString; aIsMultiplayer: Boolean): Cardinal;
var
  MapPath: UnicodeString;
begin
  Result := 0;
  MapPath := FullPath(aName, '.dat', aIsMultiplayer);
  if FileExists(MapPath) then
    Result := Adler32CRC(MapPath);
end;


class procedure TKMapsCollection.GetAllMapPaths(const aExeDir: string; aList: TStringList);
var
  I: Integer;
  SearchRec: TSearchRec;
  PathToMaps: TStringList;
begin
  aList.Clear;

  PathToMaps := TStringList.Create;
  try
    PathToMaps.Add(aExeDir + MAPS_FOLDER_NAME + PathDelim);
    PathToMaps.Add(aExeDir + MAPS_MP_FOLDER_NAME + PathDelim);
    PathToMaps.Add(aExeDir + TUTORIALS_FOLDER_NAME + PathDelim);

    //Include all campaigns maps
    FindFirst(aExeDir + CAMPAIGNS_FOLDER_NAME + PathDelim + '*', faDirectory, SearchRec);
    try
      repeat
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
          PathToMaps.Add(aExeDir + CAMPAIGNS_FOLDER_NAME + PathDelim + SearchRec.Name + PathDelim);
      until (FindNext(SearchRec) <> 0);
    finally
      FindClose(SearchRec);
    end;

    for I := 0 to PathToMaps.Count - 1 do
    if DirectoryExists(PathToMaps[I]) then
    begin
      FindFirst(PathToMaps[I] + '*', faDirectory, SearchRec);
      try
        repeat
          if (SearchRec.Name <> '.') and (SearchRec.Name <> '..')
          and FileExists(PathToMaps[I] + SearchRec.Name + PathDelim + SearchRec.Name + '.dat')
          and FileExists(PathToMaps[I] + SearchRec.Name + PathDelim + SearchRec.Name + '.map') then
            aList.Add(PathToMaps[I] + SearchRec.Name + PathDelim + SearchRec.Name + '.dat');
        until (FindNext(SearchRec) <> 0);
      finally
        FindClose(SearchRec);
      end;
    end;
  finally
    PathToMaps.Free;
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
  SearchRec: TSearchRec;
  PathToMaps: string;
  MF: TKMapFolder;
begin
  try
    for MF in fMapFolders do
    begin
      PathToMaps := ExeDir + MAP_FOLDER[MF] + PathDelim;

      if not DirectoryExists(PathToMaps) then Exit;

      FindFirst(PathToMaps + '*', faDirectory, SearchRec);
      try
        repeat
          if (SearchRec.Name <> '.') and (SearchRec.Name <> '..')
            and FileExists(TKMapsCollection.FullPath(SearchRec.Name, '.dat', MF))
            and FileExists(TKMapsCollection.FullPath(SearchRec.Name, '.map', MF)) then
          begin
            ProcessMap(SearchRec.Name, MF);
          end;
        until (FindNext(SearchRec) <> 0) or Terminated;
      finally
        FindClose(SearchRec);
      end;
    end;
  finally
    if not Terminated and Assigned(fOnComplete) then
      fOnComplete(Self);
  end;
end;


{ TTMapsScanner }
//aOnMapAdd - signal that there's new map that should be added
//aOnMapAddDone - signal that map has been added
//aOnTerminate - scan was terminated (but could be not complete yet)
//aOnComplete - scan is complete
constructor TTMapsScanner.Create(aMapFolders: TKMapFolderSet; aOnMapAdd: TKMapEvent; aOnMapAddDone, aOnTerminate: TNotifyEvent;
                                 aOnComplete: TNotifyEvent = nil);
begin
  inherited Create(aMapFolders, aOnComplete);

  Assert(Assigned(aOnMapAdd));

  fOnMapAdd := aOnMapAdd;
  fOnMapAddDone := aOnMapAddDone;
  OnTerminate := aOnTerminate;
  FreeOnTerminate := False;
end;


procedure TTMapsScanner.ProcessMap(const aPath: UnicodeString; aFolder: TKMapFolder);
var
  Map: TKMapInfo;
begin
  if fIsStopped then
    Exit;

  Map := TKMapInfo.Create(aPath, False, aFolder);

  if SLOW_MAP_SCAN then
    Sleep(50);

  fOnMapAdd(Map);
  fOnMapAddDone(Self);
end;


procedure TTMapsScanner.Stop;
begin
//  inherited;

  if Self <> nil then
    fIsStopped := True;

//  OnTerminate := nil;
end;


{ TTMapsCacheUpdater }
constructor TTMapsCacheUpdater.Create(aMapFolders: TKMapFolderSet);
begin
  inherited Create(aMapFolders);
  FreeOnTerminate := True;
end;


procedure TTMapsCacheUpdater.ProcessMap(const aPath: UnicodeString; aFolder: TKMapFolder);
var
  Map: TKMapInfo;
begin
  //Simply creating the TKMapInfo updates the .mi cache file
  if not fIsStopped then
  begin
    Map := TKMapInfo.Create(aPath, False, aFolder);
    Map.Free;
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
var F: TKMapFolder;
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

