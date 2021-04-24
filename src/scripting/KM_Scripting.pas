unit KM_Scripting;
{$I KaM_Remake.inc}
{$WARN IMPLICIT_STRING_CAST OFF}
interface
uses
  Classes, SysUtils,
  uPSCompiler, uPSRuntime, uPSUtils, uPSDisassembly, uPSDebugger, uPSPreProcessor,
  KM_CommonClasses, KM_CommonTypes, KM_Defaults, KM_FileIO,
  KM_ScriptingActions, KM_ScriptingEvents, KM_ScriptingIdCache, KM_ScriptingStates, KM_ScriptingTypes, KM_ScriptingUtils,
  ScriptValidatorResult;

  //Dynamic scripts allow mapmakers to control the mission flow

  //Three classes exposed to scripting States, Actions and Utils

  //All functions can be split into these three categories:
  // - Event, when something has happened (e.g. House was built)
  // - State, describing the state of something (e.g. Houses.Count >= 1)
  // - Action, when we need to perform something (e.g. show a message)

  //How to add new a method exposed to the scripting? Three steps:
  //1. Add method to published section here below
  //2. Add method declaration to Compiler (TKMScripting.ScriptOnUses)
  //3. Add method name to Runtime (TKMScripting.LinkRuntime)

type


  // Scripts can be included one into another with PreProcessor directives {$I filename.script} or {$INCLUDE filename.script}
  // This structure collects included files info
  TKMScriptFilesCollection = class
  private
    fMainFileInfo: TKMScriptFileInfo;
    fMainFilePath: UnicodeString;
    fHasDefDirectives: Boolean;
    fIncludedCnt: Integer;
    fIncluded: array of TKMScriptFileInfo;

    function GetIncluded(aIndex: Integer): TKMScriptFileInfo;

  public
    constructor Create;

    property Included[I: Integer]: TKMScriptFileInfo read GetIncluded; default;
    property IncludedCount: Integer read fIncludedCnt;
    procedure AddIncludeInfo(const aIncludeInfo: TKMScriptFileInfo);
//    function FindCodeLine(const aLine: AnsiString; out aFileNamesArr: TKMStringArray; out aRowsArr: TIntegerArray): Integer;
  end;


  TKMScriptErrorHandler = class
  private
    fErrorString: TKMScriptErrorMessage; //Info about found mistakes (Unicode, can be localized later on)
    fWarningsString: TKMScriptErrorMessage;
    fHintsString: TKMScriptErrorMessage;

    fHasErrorOccured: Boolean; //Has runtime error occurred? (only display first error)
    fScriptLogFile: UnicodeString;
    fOnScriptError: TUnicodeStringEvent;
    procedure SetScriptLogFile(const aScriptLogFile: UnicodeString);
    function AppendErrorPrefix(const aPrefix: UnicodeString; var aError: TKMScriptErrorMessage): TKMScriptErrorMessage;
  public
    constructor Create(aOnScriptError: TUnicodeStringEvent);

    property ScriptLogFile: UnicodeString read fScriptLogFile write SetScriptLogFile;
    property ErrorString: TKMScriptErrorMessage read fErrorString;
    property WarningsString: TKMScriptErrorMessage read fWarningsString;

    procedure HandleScriptError(aType: TKMScriptErrorType; const aError: TKMScriptErrorMessage);
    procedure HandleScriptErrorString(aType: TKMScriptErrorType; const aErrorString: UnicodeString;
                                      const aDetailedErrorString: UnicodeString = '');
    function HasErrors: Boolean;
    function HasWarnings: Boolean;
    function HasHints: Boolean;
    procedure AppendError(aError: TKMScriptErrorMessage);
    procedure AppendWarning(const aWarning: TKMScriptErrorMessage);
    procedure AppendHint(const aHint: TKMScriptErrorMessage);
    procedure AppendErrorStr(const aErrorString: String; const aDetailedErrorString: String = '');
    procedure AppendWarningStr(const aWarningString: String; const aDetailedWarningString: String = '');
    procedure HandleErrors;
    procedure Clear;
  end;


  TKMScriptingPreProcessor = class
  private
    fDestroyErrorHandler: Boolean;
    fScriptFilesInfo: TKMScriptFilesCollection;
    fErrorHandler: TKMScriptErrorHandler;
    fValidationIssues: TScriptValidatorResult;

    fCustomScriptParams: TKMCustomScriptParamDataArray;
    fPSPreProcessor: TPSPreProcessor;

    function IsCampaignMissionScript: Boolean;

    function GetCustomScriptParamData(aParam: TKMCustomScriptParam): TKMCustomScriptParamData;

    procedure AfterPreProcess;
    procedure BeforePreProcess(const aMainFileName: UnicodeString; const aMainFileText: AnsiString);

    function ScriptOnNeedFile(Sender: TPSPreProcessor; const aCallingFileName: AnsiString; var aFileName, aOutput: AnsiString): Boolean;
    procedure ScriptOnProcessDirective(Sender: TPSPreProcessor; Parser: TPSPascalPreProcessorParser; const Active: Boolean;
                                        const DirectiveName, DirectiveParam: tbtString; var aContinue: Boolean);
  public
    constructor Create; overload;
    constructor Create(aOnScriptError: TUnicodeStringEvent); overload;
    constructor Create(aOnScriptError: TUnicodeStringEvent; aErrorHandler: TKMScriptErrorHandler); overload;
    destructor Destroy; override;

    property CustomScriptParams[aParam: TKMCustomScriptParam]: TKMCustomScriptParamData read GetCustomScriptParamData;
    property ScriptFilesInfo: TKMScriptFilesCollection read fScriptFilesInfo;
    property ValidationIssues: TScriptValidatorResult read fValidationIssues write fValidationIssues;

    function ScriptMightChangeAfterPreProcessing: Boolean;
    function PreProcessFile(const aFileName: UnicodeString): Boolean; overload;
    function PreProcessFile(const aFileName: UnicodeString; var aScriptCode: AnsiString): Boolean; overload;
  end;


  TKMScripting = class
  private
    fScriptCode: AnsiString;
    fCampaignDataTypeCode: AnsiString;
    fByteCode: AnsiString;
    fDebugByteCode: AnsiString;
    fExec: TPSExec;

    fValidationIssues: TScriptValidatorResult;
    fErrorHandler: TKMScriptErrorHandler;
    fPreProcessor: TKMScriptingPreProcessor;

    fStates: TKMScriptStates;
    fActions: TKMScriptActions;
    fIDCache: TKMScriptingIdCache;
    fUtils: TKMScriptUtils;

    procedure AddError(aMsg: TPSPascalCompilerMessage);
    procedure CompileScript;
    procedure LinkRuntime;

    procedure SaveVar(SaveStream: TKMemoryStream; Src: Pointer; aType: TPSTypeRec);
    procedure LoadVar(LoadStream: TKMemoryStream; Src: Pointer; aType: TPSTypeRec);

    function GetScriptFilesInfo: TKMScriptFilesCollection;
//    function GetCodeLine(aRowNum: Cardinal): AnsiString;
//    function FindCodeLine(aRowNumber: Integer; out aFileNamesArr: TKMStringArray; out aRowsArr: TIntegerArray): Integer;
    procedure RecreateValidationIssues;
    constructor Create(aOnScriptError: TUnicodeStringEvent); // Scripting has to be created via special TKMScriptingCreator
  public
    destructor Destroy; override;

    property ErrorHandler: TKMScriptErrorHandler read fErrorHandler;

    function ScriptOnUses(Sender: TPSPascalCompiler; const Name: AnsiString): Boolean;
    procedure ScriptOnUseVariable(Sender: TPSPascalCompiler; VarType: TPSVariableType; VarNo: Longint; ProcNo, Position: Cardinal; const PropData: tbtString);
    function ScriptOnExportCheck(Sender: TPSPascalCompiler; Proc: TPSInternalProcedure; const ProcDecl: AnsiString): Boolean;

    //property ScriptCode: AnsiString read fScriptCode;
    property ScriptFilesInfo: TKMScriptFilesCollection read GetScriptFilesInfo;
    property PreProcessor: TKMScriptingPreProcessor read fPreProcessor;

    function GetErrorMessage(aErrorMsg: TPSPascalCompilerMessage): TKMScriptErrorMessage; overload;
    function GetErrorMessage(const aErrorType, aShortErrorDescription, aModule: String; aRow, aCol, aPos: Integer): TKMScriptErrorMessage; overload;

    property ValidationIssues: TScriptValidatorResult read fValidationIssues;
    procedure LoadFromFile(const aFileName, aCampaignDataTypeFile: UnicodeString; aCampaignData: TKMemoryStream);
    procedure ExportDataToText;

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad;

    procedure SaveCampaignData(SaveStream: TKMemoryStream);
    procedure LoadCampaignData(LoadStream: TKMemoryStream);

    procedure UpdateState;
  end;


  //Scripting creator
  TKMScriptingCreator = class
  public
    class function CreateScripting(aOnScriptError: TUnicodeStringEvent): TKMScripting;
  end;


const
  MAX_LOG_SIZE = 1024 * 1024; //1 MB
  CAMPAIGN_DATA_TYPE = 'TCampaignData'; //Type of the global variable
  CAMPAIGN_DATA_VAR = 'CampaignData'; //Name of the global variable
  VALID_GLOBAL_VAR_TYPES: set of TPSBaseType = [
    btU8,  //Byte, Boolean, Enums
    btS8,  //ShortInt
    btU16, //Word
    btS16, //SmallInt
    btU32, //Cardinal / LongInt
    btS32, //Integer
    btSingle, //Single
    btString, //Means AnsiString in PascalScript.
    btUnicodeString, //string and UnicodeString
    btStaticArray, btArray, //Static and Dynamic Arrays
    btRecord, btSet];


implementation
uses
  TypInfo, Math, KromUtils, KM_GameParams, KM_Resource, KM_ResUnits, KM_Log, KM_CommonUtils, KM_ResWares,
  KM_ScriptingConsoleCommands,
  KM_ResTypes, KM_CampaignTypes;

const
  SCRIPT_LOG_EXT = '.log.txt';

var
  gScripting: TKMScripting;


{Regular procedures and functions to wrap TKMScripting procedures and functions}
function ScriptOnUsesFunc(Sender: TPSPascalCompiler; const Name: AnsiString): Boolean;
begin
  Result := False;
  if gScripting <> nil then
    Result := gScripting.ScriptOnUses(Sender, Name);
end;


procedure ScriptOnUseVariableProc(Sender: TPSPascalCompiler; VarType: TPSVariableType; VarNo: Integer; ProcNo, Position: Cardinal; const PropData: tbtString);
begin
  if gScripting <> nil  then
    gScripting.ScriptOnUseVariable(Sender, VarType, VarNo, ProcNo, Position, PropData);
end;


function ScriptOnExportCheckFunc(Sender: TPSPascalCompiler; Proc: TPSInternalProcedure; const ProcDecl: AnsiString): Boolean;
begin
  Result := False;
  if gScripting <> nil then
    Result := gScripting.ScriptOnExportCheck(Sender, Proc, ProcDecl);
end;


{ TKMScriptingCreator }
//We need to save pointer to scripting object (in gScripting), as it is used by ScriptOnUsesFunc/ScriptOnUseVariableProc/ScriptOnExportCheckFunc
//These functions are regular methods and need TKMScripting object in global scope
class function TKMScriptingCreator.CreateScripting(aOnScriptError: TUnicodeStringEvent): TKMScripting;
begin
  if gScripting <> nil then // Should never happen in 1 application, as only 1 TKMScripting object is needed usually
    FreeAndNil(gScripting);

  gScripting := TKMScripting.Create(aOnScriptError);
  Result := gScripting;
end;


{ TKMScripting }
constructor TKMScripting.Create(aOnScriptError: TUnicodeStringEvent);
begin
  inherited Create;

  // Create an instance of the script executer
  if DEBUG_SCRIPTING_EXEC then
    fExec := TPSDebugExec.Create //Use slow debug executor (about 3 times slower! never use on release version)
  else
    fExec := TPSExec.Create;

  fIDCache := TKMScriptingIdCache.Create;

  // Global object to get events
  fErrorHandler := TKMScriptErrorHandler.Create(aOnScriptError);
  fPreProcessor := TKMScriptingPreProcessor.Create(aOnScriptError, fErrorHandler); //Use same error handler for PreProcessor and Scripting

  gScriptEvents := TKMScriptEvents.Create(fExec, fPreProcessor.fPSPreProcessor, fIDCache);
  fStates := TKMScriptStates.Create(fIDCache);
  fActions := TKMScriptActions.Create(fIDCache);
  fUtils := TKMScriptUtils.Create(fIDCache);

  gScriptEvents.OnScriptError := fErrorHandler.HandleScriptErrorString;
  fStates.OnScriptError := fErrorHandler.HandleScriptErrorString;
  fActions.OnScriptError := fErrorHandler.HandleScriptErrorString;
  fUtils.OnScriptError := fErrorHandler.HandleScriptErrorString;
end;


destructor TKMScripting.Destroy;
begin
  FreeAndNil(gScriptEvents);
  FreeAndNil(fStates);
  FreeAndNil(fActions);
  FreeAndNil(fIDCache);
  FreeAndNil(fExec);
  FreeAndNil(fUtils);
  FreeAndNil(fErrorHandler);
  FreeAndNil(fValidationIssues);
  FreeAndNil(fPreProcessor);
  gScripting := nil;
  inherited;
end;


procedure TKMScripting.RecreateValidationIssues;
begin
  if fValidationIssues <> nil then
    FreeAndNil(fValidationIssues);

  fValidationIssues := TScriptValidatorResult.Create;
  fPreProcessor.ValidationIssues := fValidationIssues;
end;


procedure TKMScripting.LoadFromFile(const aFileName, aCampaignDataTypeFile: UnicodeString; aCampaignData: TKMemoryStream);
begin
  RecreateValidationIssues;

  if not fPreProcessor.PreProcessFile(aFileName, fScriptCode) then
    Exit; // Continue only if PreProcess was successful;

  //Parse console commands procedures
  if gScriptEvents.HasConsoleCommands then
    try
      gScriptEvents.ParseConsoleCommandsProcedures(fScriptCode);
    except
      on E: EConsoleCommandParseError do
      begin
        fErrorHandler.AppendErrorStr(E.Message);
        fValidationIssues.AddError(E.Row, E.Col, E.Token, E.Message);
      end;
    end;

  if (aCampaignDataTypeFile <> '') and FileExists(aCampaignDataTypeFile) then
    fCampaignDataTypeCode := ReadTextA(aCampaignDataTypeFile)
  else
    fCampaignDataTypeCode := '';

  CompileScript;

  fErrorHandler.HandleErrors;

  if aCampaignData <> nil then
    LoadCampaignData(aCampaignData);
end;


//The OnUses callback function is called for each "uses" in the script.
//It's always called with the parameter 'SYSTEM' at the top of the script.
//For example: uses ii1, ii2;
//This will call this function 3 times. First with 'SYSTEM' then 'II1' and then 'II2'
function TKMScripting.ScriptOnUses(Sender: TPSPascalCompiler; const Name: AnsiString): Boolean;
  //Register classes and methods to the script engine.
  //After that they can be used from within the script.
  procedure RegisterMethodCheck(aClass: TPSCompileTimeClass; const aDecl: String);
  begin
    // We are fine with Assert, cos it will trigger for devs during development
    if not aClass.RegisterMethod(AnsiString(aDecl)) then
      Assert(False, Format('Error registering "%s"', [aDecl]));
  end;

var
  campaignDataType: TPSType;
  c: TPSCompileTimeClass;
begin
  if Name = 'SYSTEM' then
  begin
    if fCampaignDataTypeCode <> '' then
      try
        campaignDataType := Sender.AddTypeS(CAMPAIGN_DATA_TYPE, fCampaignDataTypeCode);
        Sender.AddUsedVariable(CAMPAIGN_DATA_VAR, campaignDataType);
      except
        on E: Exception do
        begin
          fErrorHandler.AppendErrorStr('Error in declaration of global campaign data type|');
          fValidationIssues.AddError(0, 0, '', 'Error in declaration of global campaign data type');
        end;
      end;

    // Common
    Sender.AddTypeS('TIntegerArray', 'array of Integer'); //Needed for PlayerGetAllUnits
    Sender.AddTypeS('TAnsiStringArray', 'array of AnsiString'); //Needed for some array Utils
    Sender.AddTypeS('TByteSet', 'set of Byte'); //Needed for Closest*MultipleTypes
    Sender.AddTypeS('TKMPoint', 'record X,Y:Integer; end;'); //Could be very useful

    Sender.AddTypeS('TKMFieldType', '(ftNone,ftRoad,ftCorn,ftWine)'); //No need to add InitWine for scripts
    Sender.AddTypeS('TKMHouseType', '(htNone, htAny, '
      + 'htArmorSmithy,     htArmorWorkshop,   htBakery,        htBarracks,      htButchers,'
      + 'htCoalMine,        htFarm,            htFisherHut,     htGoldMine,      htInn,'
      + 'htIronMine,        htIronSmithy,      htMarketplace,   htMetallurgists, htMill,'
      + 'htQuary,           htSawmill,         htSchool,        htSiegeWorkshop, htStables,'
      + 'htStore,           htSwine,           htTannery,       htTownHall,      htWatchTower,'
      + 'htWeaponSmithy,    htWeaponWorkshop,  htWineyard,      htWoodcutters    )');

    Sender.AddTypeS('TKMGroupOrder', '(goNone, goWalkTo, goAttackHouse, goAttackUnit, goStorm)');

    Sender.AddTypeS('TKMAudioFormat', '(afWav, afOgg)'); //Needed for PlaySound

    // Types needed for MapTilesArraySet function
    Sender.AddTypeS('TKMTerrainTileBrief', 'record X,Y:Byte;Terrain:Word;Rotation:Byte;Height:Byte;Obj:Word;UpdateTerrain,UpdateRotation,UpdateHeight,UpdateObject:Boolean;end');

    Sender.AddTypeS('TKMAIAttackTarget', '(attClosestUnit,attClosestBuildingFromArmy,attClosestBuildingFromStartPos,attCustomPosition)');

    Sender.AddTypeS('TKMArmyType', '(atIronThenLeather,atLeather,atIron,atIronAndLeather)');

    Sender.AddTypeS('TKMMissionDifficulty', '(mdNone,mdEasy3,mdEasy2,mdEasy1,mdNormal,mdHard1,mdHard2,mdHard3)');
    Sender.AddTypeS('TKMMissionDifficultySet', 'set of TKMMissionDifficulty');

    Sender.AddTypeS('TKMTileOverlay', '(toNone, toDig1, toDig2, toDig3, toDig4, toRoad)');

    Sender.AddTypeS('TKMTerrainKind', '('
      + 'tkCustom,       tkGrass,        tkMoss,         tkPaleGrass, tkCoastSand,'
      + 'tkGrassSand1,   tkGrassSand2,   tkGrassSand3,   tkSand,      tkGrassDirt,'
      + 'tkDirt,         tkCobbleStone,  tkGrassyWater,  tkSwamp,     tkIce,'
      + 'tkSnowOnGrass,  tkSnowOnDirt,   tkSnow,         tkDeepSnow,  tkStone,'
      + 'tkGoldMount,    tkIronMount,    tkAbyss,        tkGravel,    tkCoal,'
      + 'tkGold,         tkIron,         tkWater,        tkFastWater, tkLava)');

    Sender.AddTypeS('TKMTileMaskKind', '(mkNone, mkSoft1, mkSoft2, mkSoft3, mkStraight, mkGradient)');

    Sender.AddTypeS('TKMUnitType', '(utNone, utAny,'
      + 'utSerf,          utWoodcutter,    utMiner,         utAnimalBreeder,'
      + 'utFarmer,        utLamberjack,    utBaker,         utButcher,'
      + 'utFisher,        utWorker,        utStoneCutter,   utSmith,'
      + 'utMetallurgist,  utRecruit,'
      + 'utMilitia,      utAxeFighter,   utSwordsman,     utBowman,'
      + 'utArbaletman,   utPikeman,      utHallebardman,  utHorseScout,'
      + 'utCavalry,      utBarbarian,'
      + 'utPeasant,      utSlingshot,    utMetalBarbarian,utHorseman,'
      //utCatapult,   utBallista,
      + 'utWolf,         utFish,         utWatersnake,   utSeastar,'
      + 'utCrab,         utWaterflower,  utWaterleaf,    utDuck)');

    Sender.AddTypeS('TReplaceFlags', '(rfReplaceAll, rfIgnoreCase)'); //Needed for string util Utils.StringReplace

    // Register classes and methods to the script engine.
    // After that they can be used from within the script.
    c := Sender.AddClassN(nil, AnsiString(fStates.ClassName));
    RegisterMethodCheck(c, 'function AIArmyType(aPlayer: Byte): TKMArmyType');
    RegisterMethodCheck(c, 'function AIAutoAttackRange(aPlayer: Byte): Integer');
    RegisterMethodCheck(c, 'function AIAutoBuild(aPlayer: Byte): Boolean');
    RegisterMethodCheck(c, 'function AIAutoDefence(aPlayer: Byte): Boolean');
    RegisterMethodCheck(c, 'function AIAutoRepair(aPlayer: Byte): Boolean');
    RegisterMethodCheck(c, 'procedure AIDefencePositionGet(aPlayer, aID: Byte; out aX, aY: Integer; out aGroupType: Byte; out aRadius: Word; out aDefType: Byte)');
    RegisterMethodCheck(c, 'function AIDefendAllies(aPlayer: Byte): Boolean');
    RegisterMethodCheck(c, 'function AIEquipRate(aPlayer: Byte; aType: Byte): Integer');
    RegisterMethodCheck(c, 'procedure AIGroupsFormationGet(aPlayer, aType: Byte; out aCount, aColumns: Integer)');
    RegisterMethodCheck(c, 'function AIRecruitDelay(aPlayer: Byte): Integer');
    RegisterMethodCheck(c, 'function AIRecruitLimit(aPlayer: Byte): Integer');
    RegisterMethodCheck(c, 'function AISerfsPerHouse(aPlayer: Byte): Single');
    RegisterMethodCheck(c, 'function AISoldiersLimit(aPlayer: Byte): Integer');
    RegisterMethodCheck(c, 'function AIStartPosition(aPlayer: Byte): TKMPoint');
    RegisterMethodCheck(c, 'function AIWorkerLimit(aPlayer: Byte): Integer');

    RegisterMethodCheck(c, 'function CampaignMissionID: Integer');
    RegisterMethodCheck(c, 'function CampaignMissionsCount: Integer');
    RegisterMethodCheck(c, 'function CampaignUnlockedMissionID: Integer');

    RegisterMethodCheck(c, 'function ClosestGroup(aPlayer, X, Y, aGroupType: Integer): Integer');
    RegisterMethodCheck(c, 'function ClosestGroupMultipleTypes(aPlayer, X, Y: Integer; aGroupTypes: TByteSet): Integer');
    RegisterMethodCheck(c, 'function ClosestHouse(aPlayer, X, Y, aHouseType: Integer): Integer');
    RegisterMethodCheck(c, 'function ClosestHouseMultipleTypes(aPlayer, X, Y: Integer; aHouseTypes: TByteSet): Integer');
    RegisterMethodCheck(c, 'function ClosestUnit(aPlayer, X, Y, aUnitType: Integer): Integer');
    RegisterMethodCheck(c, 'function ClosestUnitMultipleTypes(aPlayer, X, Y: Integer; aUnitTypes: TByteSet): Integer');

    RegisterMethodCheck(c, 'function ConnectedByRoad(X1, Y1, X2, Y2: Integer): Boolean');
    RegisterMethodCheck(c, 'function ConnectedByWalking(X1, Y1, X2, Y2: Integer): Boolean');

    RegisterMethodCheck(c, 'function FogRevealed(aPlayer: Byte; aX, aY: Word): Boolean');

    RegisterMethodCheck(c, 'function GameSpeed: Single');
    RegisterMethodCheck(c, 'function GameSpeedChangeAllowed: Boolean');
    RegisterMethodCheck(c, 'function GameTime: Cardinal');

    RegisterMethodCheck(c, 'function GroupAllowAllyToSelect(aGroupID: Integer): Boolean');
    RegisterMethodCheck(c, 'function GroupAssignedToDefencePosition(aGroupID, X, Y: Integer): Boolean');
    RegisterMethodCheck(c, 'function GroupAt(aX, aY: Word): Integer');
    RegisterMethodCheck(c, 'function GroupColumnCount(aGroupID: Integer): Integer');
    RegisterMethodCheck(c, 'function GroupDead(aGroupID: Integer): Boolean');
    RegisterMethodCheck(c, 'function GroupIdle(aGroupID: Integer): Boolean');
    RegisterMethodCheck(c, 'function GroupInFight(aGroupID: Integer; aCountCitizens: Boolean): Boolean');
    RegisterMethodCheck(c, 'function GroupManualFormation(aGroupID: Integer): Boolean');
    RegisterMethodCheck(c, 'function GroupMember(aGroupID, aMemberIndex: Integer): Integer');
    RegisterMethodCheck(c, 'function GroupMemberCount(aGroupID: Integer): Integer');
    RegisterMethodCheck(c, 'function GroupOrder(aGroupID: Integer): TKMGroupOrder');
    RegisterMethodCheck(c, 'function GroupOwner(aGroupID: Integer): Integer');
    RegisterMethodCheck(c, 'function GroupType(aGroupID: Integer): Integer');

    RegisterMethodCheck(c, 'function HouseAt(aX, aY: Word): Integer');
    RegisterMethodCheck(c, 'function HouseAllowAllyToSelect(aHouseID: Integer): Boolean');
    RegisterMethodCheck(c, 'function HouseBarracksRallyPointX(aBarracks: Integer): Integer');
    RegisterMethodCheck(c, 'function HouseBarracksRallyPointY(aBarracks: Integer): Integer');
    RegisterMethodCheck(c, 'function HouseBarracksRecruitsCount(aBarracks: Integer): Integer');
    RegisterMethodCheck(c, 'function HouseBuildingProgress(aHouseID: Integer): Word');
    RegisterMethodCheck(c, 'function HouseCanReachResources(aHouseID: Integer): Boolean)');
    RegisterMethodCheck(c, 'function HouseDamage(aHouseID: Integer): Integer');
    RegisterMethodCheck(c, 'function HouseDeliveryBlocked(aHouseID: Integer): Boolean');
    RegisterMethodCheck(c, 'function HouseDeliveryMode(aHouseID: Integer): Integer');
    RegisterMethodCheck(c, 'function HouseDestroyed(aHouseID: Integer): Boolean');
    RegisterMethodCheck(c, 'function HouseHasOccupant(aHouseID: Integer): Boolean');
    RegisterMethodCheck(c, 'function HouseFlagPoint(aHouseID: Integer): TKMPoint');
    RegisterMethodCheck(c, 'function HouseIsComplete(aHouseID: Integer): Boolean');
    RegisterMethodCheck(c, 'function HouseOwner(aHouseID: Integer): Integer');
    RegisterMethodCheck(c, 'function HousePosition(aHouseID: Integer): TKMPoint');
    RegisterMethodCheck(c, 'function HousePositionX(aHouseID: Integer): Integer');
    RegisterMethodCheck(c, 'function HousePositionY(aHouseID: Integer): Integer');
    RegisterMethodCheck(c, 'function HouseRepair(aHouseID: Integer): Boolean');
    RegisterMethodCheck(c, 'function HouseResourceAmount(aHouseID, aResource: Integer): Integer');
    RegisterMethodCheck(c, 'function HouseSchoolQueue(aHouseID, QueueIndex: Integer): Integer');
    RegisterMethodCheck(c, 'function HouseSiteIsDigged(aHouseID: Integer): Boolean');
    RegisterMethodCheck(c, 'function HouseTownHallMaxGold(aHouseID: Integer): Integer');
    RegisterMethodCheck(c, 'function HouseType(aHouseID: Integer): Integer');
    RegisterMethodCheck(c, 'function HouseTypeMaxHealth(aHouseType: Integer): Word');
    RegisterMethodCheck(c, 'function HouseTypeName(aHouseType: Byte): AnsiString');
    RegisterMethodCheck(c, 'function HouseTypeToOccupantType(aHouseID: Integer): Integer');
    RegisterMethodCheck(c, 'function HouseUnlocked(aPlayer, aHouseType: Word): Boolean');
    RegisterMethodCheck(c, 'function HouseWoodcutterChopOnly(aHouseID: Integer): Boolean');
    RegisterMethodCheck(c, 'function HouseWoodcutterMode(aHouseID: Integer): Integer');
    RegisterMethodCheck(c, 'function HouseWareBlocked(aHouseID, aWareType: Integer): Boolean');
    RegisterMethodCheck(c, 'function HouseWareBlockedTakeOut(aHouseID, aWareType: Integer): Boolean');
    RegisterMethodCheck(c, 'function HouseWeaponsOrdered(aHouseID, aWareType: Integer): Integer');

    RegisterMethodCheck(c, 'function IsFieldAt(aPlayer: ShortInt; X, Y: Word): Boolean');
    RegisterMethodCheck(c, 'function IsRoadAt(aPlayer: ShortInt; X, Y: Word): Boolean');
    RegisterMethodCheck(c, 'function IsWinefieldAt(aPlayer: ShortInt; X, Y: Word): Boolean');

    RegisterMethodCheck(c, 'function IsPlanAt(var aPlayer: Integer; var aFieldType: TKMFieldType; X, Y: Word): Boolean');
    RegisterMethodCheck(c, 'function IsFieldPlanAt(var aPlayer: Integer; X, Y: Word): Boolean');
    RegisterMethodCheck(c, 'function IsHousePlanAt(var aPlayer: Integer; var aHouseType: TKMHouseType; X, Y: Word): Boolean');
    RegisterMethodCheck(c, 'function IsRoadPlanAt(var aPlayer: Integer; X, Y: Word): Boolean');
    RegisterMethodCheck(c, 'function IsWinefieldPlanAt(var aPlayer: Integer; X, Y: Word): Boolean');

    RegisterMethodCheck(c, 'function IsMissionBuildType: Boolean');
    RegisterMethodCheck(c, 'function IsMissionFightType: Boolean');
    RegisterMethodCheck(c, 'function IsMissionCoopType: Boolean');
    RegisterMethodCheck(c, 'function IsMissionSpecialType: Boolean');
    RegisterMethodCheck(c, 'function IsMissionPlayableAsSP: Boolean');
    RegisterMethodCheck(c, 'function IsMissionBlockColorSelection: Boolean');
    RegisterMethodCheck(c, 'function IsMissionBlockTeamSelection: Boolean');
    RegisterMethodCheck(c, 'function IsMissionBlockPeacetime: Boolean');
    RegisterMethodCheck(c, 'function IsMissionBlockFullMapPreview: Boolean');

    RegisterMethodCheck(c, 'function KaMRandom: Single');
    RegisterMethodCheck(c, 'function KaMRandomI(aMax:Integer): Integer');

    RegisterMethodCheck(c, 'function LocationCount: Integer');

    RegisterMethodCheck(c, 'function MapHeight: Integer');
    RegisterMethodCheck(c, 'function MapTileHasOnlyTerrainKind(X, Y: Integer; TerKind: TKMTerrainKind): Boolean');
    RegisterMethodCheck(c, 'function MapTileHasOnlyTerrainKinds(X, Y: Integer; TerKinds: array of TKMTerrainKind): Boolean');
    RegisterMethodCheck(c, 'function MapTileHasTerrainKind(X, Y: Integer; TerKind: TKMTerrainKind): Boolean');
    RegisterMethodCheck(c, 'function MapTileHeight(X, Y: Integer): Integer');
    RegisterMethodCheck(c, 'function MapTileIsCoal(X, Y: Integer): Word');
    RegisterMethodCheck(c, 'function MapTileIsGold(X, Y: Integer): Word');
    RegisterMethodCheck(c, 'function MapTileIsIce(X, Y: Integer): Boolean');
    RegisterMethodCheck(c, 'function MapTileIsInMapCoords(X, Y: Integer): Boolean');
    RegisterMethodCheck(c, 'function MapTileIsIron(X, Y: Integer): Word');
    RegisterMethodCheck(c, 'function MapTileIsSand(X, Y: Integer): Boolean');
    RegisterMethodCheck(c, 'function MapTileIsSnow(X, Y: Integer): Boolean');
    RegisterMethodCheck(c, 'function MapTileIsSoil(X, Y: Integer): Boolean');
    RegisterMethodCheck(c, 'function MapTileIsStone(X, Y: Integer): Word');
    RegisterMethodCheck(c, 'function MapTileIsWater(X, Y: Integer; FullTilesOnly: Boolean): Boolean');
    RegisterMethodCheck(c, 'function MapTileObject(X, Y: Integer): Integer');
    RegisterMethodCheck(c, 'function MapTileOverlay(X, Y: Integer): TKMTileOverlay');
    RegisterMethodCheck(c, 'function MapTileOwner(X, Y: Integer): Integer');
    RegisterMethodCheck(c, 'function MapTilePassability(X, Y: Integer; aPassability: Byte): Boolean');
    RegisterMethodCheck(c, 'function MapTileRotation(X, Y: Integer): Integer');
    RegisterMethodCheck(c, 'function MapTileType(X, Y: Integer): Integer');
    RegisterMethodCheck(c, 'function MapWidth: Integer');

    RegisterMethodCheck(c, 'function MissionAuthor: UnicodeString');
    RegisterMethodCheck(c, 'function MissionBigDesc: UnicodeString');
    RegisterMethodCheck(c, 'function MissionBigDescLibx: Integer');
    RegisterMethodCheck(c, 'function MissionSmallDesc: UnicodeString');
    RegisterMethodCheck(c, 'function MissionSmallDescLibx: Integer');

    RegisterMethodCheck(c, 'function MissionDifficulty: TKMMissionDifficulty');
    RegisterMethodCheck(c, 'function MissionDifficultyLevels: TKMMissionDifficultySet');

    RegisterMethodCheck(c, 'function MissionVersion: UnicodeString');

    RegisterMethodCheck(c, 'function MarketFromWare(aMarketID: Integer): Integer');
    RegisterMethodCheck(c, 'function MarketLossFactor: Single');
    RegisterMethodCheck(c, 'function MarketOrderAmount(aMarketID: Integer): Integer');
    RegisterMethodCheck(c, 'function MarketToWare(aMarketID: Integer): Integer');
    RegisterMethodCheck(c, 'function MarketValue(aRes: Integer): Single');

    RegisterMethodCheck(c, 'function PeaceTime: Cardinal');

    RegisterMethodCheck(c, 'function PlayerAllianceCheck(aPlayer1, aPlayer2: Byte): Boolean');
    RegisterMethodCheck(c, 'function PlayerColorFlag(aPlayer: Byte): AnsiString');
    RegisterMethodCheck(c, 'function PlayerColorText(aPlayer: Byte): AnsiString');
    RegisterMethodCheck(c, 'function PlayerDefeated(aPlayer: Byte): Boolean');
    RegisterMethodCheck(c, 'function PlayerEnabled(aPlayer: Byte): Boolean');
    RegisterMethodCheck(c, 'function PlayerGetAllGroups(aPlayer: Byte): TIntegerArray');
    RegisterMethodCheck(c, 'function PlayerGetAllHouses(aPlayer: Byte): TIntegerArray');
    RegisterMethodCheck(c, 'function PlayerGetAllUnits(aPlayer: Byte): TIntegerArray');
    RegisterMethodCheck(c, 'function PlayerIsAI(aPlayer: Byte): Boolean');
    RegisterMethodCheck(c, 'function PlayerName(aPlayer: Byte): AnsiString');
    RegisterMethodCheck(c, 'function PlayerVictorious(aPlayer: Byte): Boolean');
    RegisterMethodCheck(c, 'function PlayerWareDistribution(aPlayer, aWareType, aHouseType: Byte): Byte');

    RegisterMethodCheck(c, 'function StatAIDefencePositionsCount(aPlayer: Byte): Integer');
    RegisterMethodCheck(c, 'function StatArmyCount(aPlayer: Byte): Integer');
    RegisterMethodCheck(c, 'function StatCitizenCount(aPlayer: Byte): Integer');
    RegisterMethodCheck(c, 'function StatHouseCount(aPlayer: Byte): Integer');
    RegisterMethodCheck(c, 'function StatHouseMultipleTypesCount(aPlayer: Byte; aTypes: TByteSet): Integer');
    RegisterMethodCheck(c, 'function StatHouseTypeCount(aPlayer, aHouseType: Byte): Integer');
    RegisterMethodCheck(c, 'function StatHouseTypePlansCount(aPlayer, aHouseType: Byte): Integer');
    RegisterMethodCheck(c, 'function StatPlayerCount: Integer');
    RegisterMethodCheck(c, 'function StatResourceProducedCount(aPlayer, aResType: Byte): Integer');
    RegisterMethodCheck(c, 'function StatResourceProducedMultipleTypesCount(aPlayer: Byte; aTypes: TByteSet): Integer');
    RegisterMethodCheck(c, 'function StatUnitCount(aPlayer: Byte): Integer');
    RegisterMethodCheck(c, 'function StatUnitKilledCount(aPlayer, aUnitType: Byte): Integer');
    RegisterMethodCheck(c, 'function StatUnitKilledMultipleTypesCount(aPlayer: Byte; aTypes: TByteSet): Integer');
    RegisterMethodCheck(c, 'function StatUnitLostCount(aPlayer, aUnitType: Byte): Integer');
    RegisterMethodCheck(c, 'function StatUnitLostMultipleTypesCount(aPlayer: Byte; aTypes: TByteSet): Integer');
    RegisterMethodCheck(c, 'function StatUnitMultipleTypesCount(aPlayer: Byte; aTypes: TByteSet): Integer');
    RegisterMethodCheck(c, 'function StatUnitTypeCount(aPlayer, aUnitType: Byte): Integer');

    RegisterMethodCheck(c, 'function UnitAllowAllyToSelect(aUnitID: Integer): Boolean');
    RegisterMethodCheck(c, 'function UnitAt(aX, aY: Word): Integer');
    RegisterMethodCheck(c, 'function UnitCarrying(aUnitID: Integer): Integer');
    RegisterMethodCheck(c, 'function UnitDead(aUnitID: Integer): Boolean');
    RegisterMethodCheck(c, 'function UnitDirection(aUnitID: Integer): Integer');
    RegisterMethodCheck(c, 'function UnitDismissable(aUnitID: Integer): Boolean');
    RegisterMethodCheck(c, 'function UnitHome(aUnitID: Integer): Integer');
    RegisterMethodCheck(c, 'function UnitHPCurrent(aUnitID: Integer): Integer');
    RegisterMethodCheck(c, 'function UnitHPMax(aUnitID: Integer): Integer');
    RegisterMethodCheck(c, 'function UnitHPInvulnerable(aUnitID: Integer): Boolean');
    RegisterMethodCheck(c, 'function UnitHunger(aUnitID: Integer): Integer');
    RegisterMethodCheck(c, 'function UnitIdle(aUnitID: Integer): Boolean');
    RegisterMethodCheck(c, 'function UnitLowHunger: Integer');
    RegisterMethodCheck(c, 'function UnitMaxHunger: Integer');
    RegisterMethodCheck(c, 'function UnitOwner(aUnitID: Integer): Integer');
    RegisterMethodCheck(c, 'function UnitPosition(aHouseID: Integer): TKMPoint');
    RegisterMethodCheck(c, 'function UnitPositionX(aHouseID: Integer): Integer');
    RegisterMethodCheck(c, 'function UnitPositionY(aHouseID: Integer): Integer');
    RegisterMethodCheck(c, 'function UnitsGroup(aUnitID: Integer): Integer');
    RegisterMethodCheck(c, 'function UnitType(aUnitID: Integer): Integer');
    RegisterMethodCheck(c, 'function UnitTypeName(aUnitType: Byte): AnsiString');
    RegisterMethodCheck(c, 'function UnitUnlocked(aPlayer: Word; aUnitType: Integer): Boolean');

    RegisterMethodCheck(c, 'function WareTypeName(aWareType: Byte): AnsiString');
    RegisterMethodCheck(c, 'function WarriorInFight(aUnitID: Integer; aCountCitizens: Boolean): Boolean');

    c := Sender.AddClassN(nil, AnsiString(fActions.ClassName));
    RegisterMethodCheck(c, 'procedure AIArmyType(aPlayer: Byte; aType: TKMArmyType)');
    RegisterMethodCheck(c, 'function AIAttackAdd(aPlayer: Byte; aRepeating: Boolean; aDelay: Cardinal; aTotalMen: Integer;' +
                           'aMelleCount, aAntiHorseCount, aRangedCount, aMountedCount: Word; ' +
                           'aRandomGroups: Boolean; aTarget: TKMAIAttackTarget; aCustomPosition: TKMPoint): Integer');
    RegisterMethodCheck(c, 'function AIAttackRemove(aPlayer: Byte; aAIAttackId: Word): Boolean');
    RegisterMethodCheck(c, 'procedure AIAttackRemoveAll(aPlayer: Byte)');
    RegisterMethodCheck(c, 'procedure AIAutoAttackRange(aPlayer: Byte; aRange: Word)');
    RegisterMethodCheck(c, 'procedure AIAutoBuild(aPlayer: Byte; aAuto: Boolean)');
    RegisterMethodCheck(c, 'procedure AIAutoDefence(aPlayer: Byte; aAuto: Boolean)');
    RegisterMethodCheck(c, 'procedure AIAutoRepair(aPlayer: Byte; aAuto: Boolean)');
    RegisterMethodCheck(c, 'procedure AIDefencePositionAdd(aPlayer: Byte; X, Y: Integer; aDir, aGroupType: Byte; aRadius: Word; aDefType: Byte)');
    RegisterMethodCheck(c, 'procedure AIDefencePositionRemove(aPlayer: Byte; X, Y: Integer)');
    RegisterMethodCheck(c, 'procedure AIDefencePositionRemoveAll(aPlayer: Byte)');
    RegisterMethodCheck(c, 'procedure AIDefendAllies(aPlayer: Byte; aDefend: Boolean)');
    RegisterMethodCheck(c, 'procedure AIEquipRate(aPlayer: Byte; aType: Byte; aRate: Word)');
    RegisterMethodCheck(c, 'procedure AIGroupsFormationSet(aPlayer, aType: Byte; aCount, aColumns: Word)');
    RegisterMethodCheck(c, 'procedure AIRecruitDelay(aPlayer, aDelay: Cardinal)');
    RegisterMethodCheck(c, 'procedure AIRecruitLimit(aPlayer, aLimit: Byte)');
    RegisterMethodCheck(c, 'procedure AISerfsPerHouse(aPlayer: Byte; aSerfs: Single)');
    RegisterMethodCheck(c, 'procedure AISoldiersLimit(aPlayer: Byte; aLimit: Integer)');
    RegisterMethodCheck(c, 'procedure AIStartPosition(aPlayer: Byte; X, Y: Word)');
    RegisterMethodCheck(c, 'procedure AIWorkerLimit(aPlayer, aLimit: Byte)');

    RegisterMethodCheck(c, 'procedure CinematicEnd(aPlayer: Byte)');
    RegisterMethodCheck(c, 'procedure CinematicPanTo(aPlayer: Byte; X, Y, Duration: Word)');
    RegisterMethodCheck(c, 'procedure CinematicStart(aPlayer: Byte)');

    RegisterMethodCheck(c, 'procedure FogCoverAll(aPlayer: Byte)');
    RegisterMethodCheck(c, 'procedure FogCoverCircle(aPlayer, X, Y, aRadius: Word)');
    RegisterMethodCheck(c, 'procedure FogCoverRect(aPlayer, X1, Y1, X2, Y2: Word)');
    RegisterMethodCheck(c, 'procedure FogRevealAll(aPlayer: Byte)');
    RegisterMethodCheck(c, 'procedure FogRevealCircle(aPlayer, X, Y, aRadius: Word)');
    RegisterMethodCheck(c, 'procedure FogRevealRect(aPlayer, X1, Y1, X2, Y2: Word)');

    RegisterMethodCheck(c, 'procedure GameSpeed(aSpeed: Single)');
    RegisterMethodCheck(c, 'procedure GameSpeedChangeAllowed(aAllowed: Boolean)');

    RegisterMethodCheck(c, 'function  GiveAnimal(aType, X,Y: Word): Integer');
    RegisterMethodCheck(c, 'function  GiveField(aPlayer, X, Y: Word): Boolean');
    RegisterMethodCheck(c, 'function  GiveFieldAged(aPlayer, X, Y: Word; aStage: Byte; aRandomAge: Boolean): Boolean');
    RegisterMethodCheck(c, 'function  GiveGroup(aPlayer, aType, X, Y, aDir, aCount, aColumns: Word): Integer');
    RegisterMethodCheck(c, 'function  GiveHouse(aPlayer, aHouseType, X,Y: Integer): Integer');
    RegisterMethodCheck(c, 'function  GiveHouseSite(aPlayer, aHouseType, X, Y: Integer; aAddMaterials: Boolean): Integer');
    RegisterMethodCheck(c, 'function  GiveRoad(aPlayer, X, Y: Word): Boolean');
    RegisterMethodCheck(c, 'function  GiveUnit(aPlayer, aType, X,Y, aDir: Word): Integer');
    RegisterMethodCheck(c, 'procedure GiveWares(aPlayer, aType, aCount: Word)');
    RegisterMethodCheck(c, 'procedure GiveWeapons(aPlayer, aType, aCount: Word)');
    RegisterMethodCheck(c, 'function  GiveWineField(aPlayer, X, Y: Word): Boolean');
    RegisterMethodCheck(c, 'function  GiveWineFieldAged(aPlayer, X, Y: Word; aStage: Byte; aRandomAge: Boolean): Boolean');

    RegisterMethodCheck(c, 'procedure GroupAllowAllyToSelect(aGroupID: Integer; aAllow: Boolean)');
    RegisterMethodCheck(c, 'procedure GroupBlockOrders(aGroupID: Integer; aBlock: Boolean)');
    RegisterMethodCheck(c, 'procedure GroupDisableHungryMessage(aGroupID: Integer; aDisable: Boolean)');
    RegisterMethodCheck(c, 'procedure GroupHungerSet(aGroupID, aHungerLevel: Integer)');
    RegisterMethodCheck(c, 'procedure GroupKillAll(aGroupID: Integer; aSilent: Boolean)');
    RegisterMethodCheck(c, 'procedure GroupOrderAttackHouse(aGroupID, aHouseID: Integer)');
    RegisterMethodCheck(c, 'procedure GroupOrderAttackUnit(aGroupID, aUnitID: Integer)');
    RegisterMethodCheck(c, 'procedure GroupOrderFood(aGroupID: Integer)');
    RegisterMethodCheck(c, 'procedure GroupOrderHalt(aGroupID: Integer)');
    RegisterMethodCheck(c, 'procedure GroupOrderLink(aGroupID, aDestGroupID: Integer)');
    RegisterMethodCheck(c, 'function  GroupOrderSplit(aGroupID: Integer): Integer');
    RegisterMethodCheck(c, 'function  GroupOrderSplitUnit(aGroupID, aUnitID: Integer): Integer');
    RegisterMethodCheck(c, 'procedure GroupOrderStorm(aGroupID: Integer)');
    RegisterMethodCheck(c, 'procedure GroupOrderWalk(aGroupID: Integer; X, Y, aDirection: Word)');
    RegisterMethodCheck(c, 'procedure GroupSetFormation(aGroupID: Integer; aNumColumns: Byte)');

    RegisterMethodCheck(c, 'procedure HouseAddBuildingMaterials(aHouseID: Integer)');
    RegisterMethodCheck(c, 'procedure HouseAddBuildingProgress(aHouseID: Integer)');
    RegisterMethodCheck(c, 'procedure HouseAddDamage(aHouseID: Integer; aDamage: Word)');
    RegisterMethodCheck(c, 'procedure HouseAddRepair(aHouseID: Integer; aRepair: Word)');
    RegisterMethodCheck(c, 'procedure HouseAddWaresTo(aHouseID: Integer; aType, aCount: Word)');
    RegisterMethodCheck(c, 'procedure HouseAllow(aPlayer, aHouseType: Word; aAllowed: Boolean)');
    RegisterMethodCheck(c, 'procedure HouseAllowAllyToSelect(aHouseID: Integer; aAllow: Boolean)');
    RegisterMethodCheck(c, 'procedure HouseAllowAllyToSelectAll(aPlayer: Byte; aAllow: Boolean)');
    RegisterMethodCheck(c, 'function  HouseBarracksEquip(aHouseID: Integer; aUnitType: Integer; aCount: Integer): Integer');
    RegisterMethodCheck(c, 'procedure HouseBarracksGiveRecruit(aHouseID: Integer)');
    RegisterMethodCheck(c, 'procedure HouseDeliveryBlock(aHouseID: Integer; aDeliveryBlocked: Boolean)');
    RegisterMethodCheck(c, 'procedure HouseDestroy(aHouseID: Integer; aSilent: Boolean)');
    RegisterMethodCheck(c, 'procedure HouseDisableUnoccupiedMessage(aHouseID: Integer; aDisabled: Boolean)');
    RegisterMethodCheck(c, 'procedure HouseRepairEnable(aHouseID: Integer; aRepairEnabled: Boolean)');
    RegisterMethodCheck(c, 'function  HouseSchoolQueueAdd(aHouseID: Integer; aUnitType: Integer; aCount: Integer): Integer');
    RegisterMethodCheck(c, 'procedure HouseSchoolQueueRemove(aHouseID, QueueIndex: Integer)');
    RegisterMethodCheck(c, 'procedure HouseTakeWaresFrom(aHouseID: Integer; aType, aCount: Word)');
    RegisterMethodCheck(c, 'function  HouseTownHallEquip(aHouseID: Integer; aUnitType: Integer; aCount: Integer): Integer');
    RegisterMethodCheck(c, 'procedure HouseTownHallMaxGold(aHouseID: Integer; aMaxGold: Integer)');
    RegisterMethodCheck(c, 'procedure HouseUnlock(aPlayer, aHouseType: Word)');
    RegisterMethodCheck(c, 'procedure HouseWoodcutterChopOnly(aHouseID: Integer; aChopOnly: Boolean)');
    RegisterMethodCheck(c, 'procedure HouseWoodcutterMode(aHouseID: Integer; aWoodcutterMode: Byte)');
    RegisterMethodCheck(c, 'procedure HouseWareBlock(aHouseID, aWareType: Integer; aBlocked: Boolean)');
    RegisterMethodCheck(c, 'procedure HouseWareBlockTakeOut(aHouseID, aWareType: Integer; aBlocked: Boolean)');
    RegisterMethodCheck(c, 'procedure HouseWeaponsOrderSet(aHouseID, aWareType, aAmount: Integer)');

    RegisterMethodCheck(c, 'procedure Log(const aText: AnsiString)');

    RegisterMethodCheck(c, 'procedure MarketSetTrade(aMarketID, aFrom, aTo, aAmount: Integer)');

    RegisterMethodCheck(c, 'function MapTileHeightSet(X, Y, Height: Integer): Boolean');
    RegisterMethodCheck(c, 'function MapTileObjectSet(X, Y, Obj: Integer): Boolean');
    RegisterMethodCheck(c, 'function MapTileOverlaySet(X, Y: Integer; aOverlay: TKMTileOverlay; aOverwrite: Boolean): Boolean');
    RegisterMethodCheck(c, 'function MapTileSet(X, Y, aType, aRotation: Integer): Boolean');
    RegisterMethodCheck(c, 'function MapTilesArraySet(aTiles: array of TKMTerrainTileBrief; aRevertOnFail, aShowDetailedErrors: Boolean): Boolean');
    RegisterMethodCheck(c, 'function MapTilesArraySetS(aTiles: TAnsiStringArray; aRevertOnFail, aShowDetailedErrors: Boolean): Boolean');

    RegisterMethodCheck(c, 'procedure MapBrush(X, Y: Integer; aSquare: Boolean; aSize: Integer; aTerKind: TKMTerrainKind; aRandomTiles, aOverrideCustomTiles: Boolean)');
    RegisterMethodCheck(c, 'procedure MapBrushElevation(X, Y: Integer; aSquare, aRaise: Boolean; aSize, aSlope, aSpeed: Integer)');
    RegisterMethodCheck(c, 'procedure MapBrushEqualize(X, Y: Integer; aSquare: Boolean; aSize, aSlope, aSpeed: Integer)');
    RegisterMethodCheck(c, 'procedure MapBrushFlatten(X, Y: Integer; aSquare: Boolean; aSize, aSlope, aSpeed: Integer)');
    RegisterMethodCheck(c, 'procedure MapBrushMagicWater(X, Y: Integer)');
    RegisterMethodCheck(c, 'procedure MapBrushWithMask(X, Y: Integer; aSquare: Boolean; aSize: Integer; aTerKind: TKMTerrainKind;'
                                      + 'aRandomTiles, aOverrideCustomTiles: Boolean;'
                                      + 'aBrushMask: TKMTileMaskKind; aBlendingLvl: Integer; aUseMagicBrush: Boolean)');

    RegisterMethodCheck(c, 'procedure OverlayTextAppend(aPlayer: Shortint; const aText: AnsiString)');
    RegisterMethodCheck(c, 'procedure OverlayTextAppendFormatted(aPlayer: Shortint; const aText: AnsiString; Params: array of const)');
    RegisterMethodCheck(c, 'procedure OverlayTextSet(aPlayer: Shortint; const aText: AnsiString)');
    RegisterMethodCheck(c, 'procedure OverlayTextSetFormatted(aPlayer: Shortint; const aText: AnsiString; Params: array of const)');

    RegisterMethodCheck(c, 'procedure Peacetime(aPeacetime: Cardinal)');

    RegisterMethodCheck(c, 'function  PlanAddField(aPlayer, X, Y: Word): Boolean');
    RegisterMethodCheck(c, 'function  PlanAddHouse(aPlayer, aHouseType, X, Y: Word): Boolean');
    RegisterMethodCheck(c, 'function  PlanAddRoad(aPlayer, X, Y: Word): Boolean');
    RegisterMethodCheck(c, 'function  PlanAddWinefield(aPlayer, X, Y: Word): Boolean');
    RegisterMethodCheck(c, 'function  PlanConnectRoad(aPlayer, X1, Y1, X2, Y2: Integer; aCompleted: Boolean): Boolean');
    RegisterMethodCheck(c, 'function  PlanRemove(aPlayer, X, Y: Word): Boolean');

    RegisterMethodCheck(c, 'procedure PlayerAddDefaultGoals(aPlayer: Byte; aBuildings: Boolean)');
    RegisterMethodCheck(c, 'procedure PlayerAllianceChange(aPlayer1, aPlayer2: Byte; aCompliment, aAllied: Boolean)');
    RegisterMethodCheck(c, 'procedure PlayerAllianceNFogChange(aPlayer1, aPlayer2: Byte; aCompliment, aAllied, aSyncAllyFog: Boolean)');
    RegisterMethodCheck(c, 'procedure PlayerDefeat(aPlayer: Word)');
    RegisterMethodCheck(c, 'procedure PlayerGoalsRemoveAll(aPlayer: Word; aForAllPlayers: Boolean)');
    RegisterMethodCheck(c, 'procedure PlayerShareBeacons(aPlayer1, aPlayer2: Word; aCompliment, aShare: Boolean)');
    RegisterMethodCheck(c, 'procedure PlayerShareFog(aPlayer1, aPlayer2: Word; aShare: Boolean)');
    RegisterMethodCheck(c, 'procedure PlayerShareFogCompliment(aPlayer1, aPlayer2: Word; aShare: Boolean)');
    RegisterMethodCheck(c, 'procedure PlayerWareDistribution(aPlayer, aWareType, aHouseType, aAmount: Byte)');
    RegisterMethodCheck(c, 'procedure PlayerWin(const aVictors: array of Integer; aTeamVictory: Boolean)');

    RegisterMethodCheck(c, 'function PlayWAV(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer');
    RegisterMethodCheck(c, 'function PlayWAVAtLocation(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single; aRadius: Single; aX, aY: Word): Integer');
    RegisterMethodCheck(c, 'function PlayWAVAtLocationLooped(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single; aRadius: Single; aX, aY: Word): Integer');
    RegisterMethodCheck(c, 'function PlayWAVFadeMusic(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer');
    RegisterMethodCheck(c, 'function PlayWAVLooped(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer');
    RegisterMethodCheck(c, 'procedure StopLoopedWAV(aLoopIndex: Integer)');

    RegisterMethodCheck(c, 'function PlayOGG(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer');
    RegisterMethodCheck(c, 'function PlayOGGAtLocation(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single; aRadius: Single; aX, aY: Word): Integer');
    RegisterMethodCheck(c, 'function PlayOGGAtLocationLooped(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single; aRadius: Single; aX, aY: Word): Integer');
    RegisterMethodCheck(c, 'function PlayOGGFadeMusic(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer');
    RegisterMethodCheck(c, 'function PlayOGGLooped(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer');
    RegisterMethodCheck(c, 'procedure StopLoopedOGG(aLoopIndex: Integer)');
    RegisterMethodCheck(c, 'function PlaySound(aPlayer: ShortInt; const aFileName: AnsiString; aAudioFormat: TKMAudioFormat; ' +
                            'aVolume: Single; aFadeMusic, aLooped: Boolean): Integer');
    RegisterMethodCheck(c, 'function PlaySoundAtLocation(aPlayer: ShortInt; const aFileName: AnsiString; aAudioFormat: TKMAudioFormat; ' +
                            'aVolume: Single; aFadeMusic, aLooped: Boolean; aRadius: Single; aX, aY: Word): Integer');
    RegisterMethodCheck(c, 'procedure StopSound(aSoundIndex: Integer)');

    RegisterMethodCheck(c, 'procedure RemoveRoad(X, Y: Word)');

    RegisterMethodCheck(c, 'procedure SetTradeAllowed(aPlayer, aResType: Word; aAllowed: Boolean)');

    RegisterMethodCheck(c, 'procedure ShowMsg(aPlayer: ShortInt; const aText: AnsiString)');
    RegisterMethodCheck(c, 'procedure ShowMsgFormatted(aPlayer: Shortint; const aText: AnsiString; Params: array of const)');
    RegisterMethodCheck(c, 'procedure ShowMsgGoto(aPlayer: Shortint; aX, aY: Word; const aText: AnsiString)');
    RegisterMethodCheck(c, 'procedure ShowMsgGotoFormatted(aPlayer: Shortint; aX, aY: Word; const aText: AnsiString; Params: array of const)');

    RegisterMethodCheck(c, 'procedure UnitAllowAllyToSelect(aUnitID: Integer; aAllow: Boolean)');
    RegisterMethodCheck(c, 'procedure UnitBlock(aPlayer: Byte; aType: Word; aBlock: Boolean)');
    RegisterMethodCheck(c, 'function  UnitDirectionSet(aUnitID, aDirection: Integer): Boolean');
    RegisterMethodCheck(c, 'procedure UnitDismiss(aUnitID: Integer)');
    RegisterMethodCheck(c, 'procedure UnitDismissableSet(aUnitID: Integer; aDismissable: Boolean)');
    RegisterMethodCheck(c, 'procedure UnitDismissCancel(aUnitID: Integer)');
    RegisterMethodCheck(c, 'procedure UnitHPChange(aUnitID, aHP: Integer)');
    RegisterMethodCheck(c, 'procedure UnitHPSetInvulnerable(aUnitID: Integer; aInvulnerable: Boolean)');
    RegisterMethodCheck(c, 'procedure UnitHungerSet(aUnitID, aHungerLevel: Integer)');
    RegisterMethodCheck(c, 'procedure UnitKill(aUnitID: Integer; aSilent: Boolean)');
    RegisterMethodCheck(c, 'function  UnitOrderWalk(aUnitID: Integer; X, Y: Word): Boolean');

    c := Sender.AddClassN(nil, AnsiString(fUtils.ClassName));
    RegisterMethodCheck(c, 'function AbsI(aValue: Integer): Integer');
    RegisterMethodCheck(c, 'function AbsS(aValue: Single): Single');

    RegisterMethodCheck(c, 'function ArrayElementCount(const aElement: AnsiString; aArray: array of AnsiString): Integer');
    RegisterMethodCheck(c, 'function ArrayElementCountB(aElement: Boolean; aArray: array of Boolean): Integer');
    RegisterMethodCheck(c, 'function ArrayElementCountI(aElement: Integer; aArray: array of Integer): Integer');
    RegisterMethodCheck(c, 'function ArrayElementCountS(aElement: Single; aArray: array of Single): Integer');

    RegisterMethodCheck(c, 'function ArrayHasElement(const aElement: AnsiString; aArray: array of AnsiString): Boolean');
    RegisterMethodCheck(c, 'function ArrayHasElementB(aElement: Boolean; aArray: array of Boolean): Boolean');
    RegisterMethodCheck(c, 'function ArrayHasElementI(aElement: Integer; aArray: array of Integer): Boolean');
    RegisterMethodCheck(c, 'function ArrayHasElementS(aElement: Single; aArray: array of Single): Boolean');

    RegisterMethodCheck(c, 'function ArrayRemoveIndexI(aIndex: Integer; aArray: TIntegerArray): TIntegerArray');
    RegisterMethodCheck(c, 'function ArrayRemoveIndexS(aIndex: Integer; aArray: TAnsiStringArray): TAnsiStringArray');

    RegisterMethodCheck(c, 'function BoolToStr(aBool: Boolean): AnsiString');

    RegisterMethodCheck(c, 'function ColorBrightness(const aHexColor: string): Single');

    RegisterMethodCheck(c, 'function CompareString(const Str1, Str2: String): Integer');
    RegisterMethodCheck(c, 'function CompareText(const Str1, Str2: String): Integer');
    RegisterMethodCheck(c, 'function CopyString(Str: String; Index, Count: Integer): String');

    RegisterMethodCheck(c, 'procedure DeleteString(var Str: String; Index, Count: Integer)');

    RegisterMethodCheck(c, 'function EnsureRangeS(aValue, aMin, aMax: Single): Single');
    RegisterMethodCheck(c, 'function EnsureRangeI(aValue, aMin, aMax: Integer): Integer');

    RegisterMethodCheck(c, 'function Format(aFormatting: string; aData: array of const): string');
    RegisterMethodCheck(c, 'function FormatFloat(const aFormat: string; aValue: Single): string');

    RegisterMethodCheck(c, 'function IfThen(aBool: Boolean; const aTrue, aFalse: AnsiString): AnsiString');
    RegisterMethodCheck(c, 'function IfThenI(aBool: Boolean; aTrue, aFalse: Integer): Integer');
    RegisterMethodCheck(c, 'function IfThenS(aBool: Boolean; aTrue, aFalse: Single): Single');

    RegisterMethodCheck(c, 'function InAreaI(aX, aY, aXMin, aYMin, aXMax, aYMax: Integer): Boolean');
    RegisterMethodCheck(c, 'function InAreaS(aX, aY, aXMin, aYMin, aXMax, aYMax: Single): Boolean');

    RegisterMethodCheck(c, 'function InRangeI(aValue, aMin, aMax: Integer): Boolean');
    RegisterMethodCheck(c, 'function InRangeS(aValue, aMin, aMax: Single): Boolean');

    RegisterMethodCheck(c, 'procedure InsertString(Source: String; var Target: String; Index: Integer)');

    RegisterMethodCheck(c, 'function KMPoint(X,Y: Integer): TKMPoint');

    RegisterMethodCheck(c, 'function LowerCase(const Str: String): String');

    RegisterMethodCheck(c, 'function MaxI(A, B: Integer): Integer');
    RegisterMethodCheck(c, 'function MaxS(A, B: Single): Single');

    RegisterMethodCheck(c, 'function MaxInArrayI(aArray: array of Integer): Integer');
    RegisterMethodCheck(c, 'function MaxInArrayS(aArray: array of Single): Single');

    RegisterMethodCheck(c, 'function MinI(A, B: Integer): Integer');
    RegisterMethodCheck(c, 'function MinS(A, B: Single): Single');

    RegisterMethodCheck(c, 'function MinInArrayI(aArray: array of Integer): Integer');
    RegisterMethodCheck(c, 'function MinInArrayS(aArray: array of Single): Single');

    RegisterMethodCheck(c, 'procedure MoveString(const Source: String; var Destination: String; Count: Integer)');

    RegisterMethodCheck(c, 'function Pos(SubStr, Str: String): Integer');

    RegisterMethodCheck(c, 'function Power(Base, Exponent: Extended): Extended');

    RegisterMethodCheck(c, 'function RandomRangeI(aFrom, aTo: Integer): Integer');

    RegisterMethodCheck(c, 'function RGBDecToBGRHex(aR, aG, aB: Byte): AnsiString');
    RegisterMethodCheck(c, 'function RGBToBGRHex(const aHexColor: string): AnsiString');

    RegisterMethodCheck(c, 'function CeilTo(aValue: Single; aBase: Integer): Integer');
    RegisterMethodCheck(c, 'function FloorTo(aValue: Single; aBase: Integer): Integer');
    RegisterMethodCheck(c, 'function RoundTo(aValue: Single; aBase: Integer): Integer');
    RegisterMethodCheck(c, 'function TruncTo(aValue: Single; aBase: Integer): Integer');

    RegisterMethodCheck(c, 'function Sqr(A: Extended): Extended');

    RegisterMethodCheck(c, 'function StringReplace(const Str, OldPattern, NewPattern: string; Flags: TReplaceFlags): String');

    RegisterMethodCheck(c, 'function SumI(aArray: array of Integer): Integer');
    RegisterMethodCheck(c, 'function SumS(aArray: array of Single): Single');

    RegisterMethodCheck(c, 'function TimeToString(aTicks: Integer): AnsiString');
    RegisterMethodCheck(c, 'function TimeToTick(aHours, aMinutes, aSeconds: Integer): Cardinal');

    RegisterMethodCheck(c, 'function Trim(const Str: String): String');
    RegisterMethodCheck(c, 'function TrimLeft(const Str: String): String');
    RegisterMethodCheck(c, 'function TrimRight(const Str: String): String');

    RegisterMethodCheck(c, 'function UpperCase(const Str: String): String');

        // Register objects
    AddImportedClassVariable(Sender, 'States', AnsiString(fStates.ClassName));
    AddImportedClassVariable(Sender, 'Actions', AnsiString(fActions.ClassName));
    AddImportedClassVariable(Sender, 'Utils', AnsiString(fUtils.ClassName));
    AddImportedClassVariable(Sender, 'S', AnsiString(fStates.ClassName));
    AddImportedClassVariable(Sender, 'A', AnsiString(fActions.ClassName));
    AddImportedClassVariable(Sender, 'U', AnsiString(fUtils.ClassName));

    Result := True;
  end
  else
    Result := False;
end;


procedure TKMScripting.ScriptOnUseVariable(Sender: TPSPascalCompiler; VarType: TPSVariableType; VarNo: Integer; ProcNo, Position: Cardinal; const PropData: tbtString);
begin
  //There's no variable type info here
  //GetVarCount is not including this current variable yet either
end;


{ The OnExportCheck callback function is called for each function in the script
  (Also for the main proc, with '!MAIN' as a Proc^.Name). ProcDecl contains the
  result type and parameter types of a function using this format:
  ProcDecl: ResultType + ' ' + Parameter1 + ' ' + Parameter2 + ' '+Parameter3 + .....
  Parameter: ParameterType+TypeName
  ParameterType is @ for a normal parameter and ! for a var parameter.
  A result type of 0 means no result}
function TKMScripting.ScriptOnExportCheck(Sender: TPSPascalCompiler; Proc: TPSInternalProcedure; const ProcDecl: AnsiString): Boolean;
const
  PROCS: array [0..33] of record
    Names: AnsiString;
    ParamCount: Byte;
    Typ: array [0..4] of Byte;
    Dir: array [0..3] of TPSParameterMode;
  end =
  (
  (Names: 'OnFieldBuilt';           ParamCount: 3; Typ: (0, btS32, btS32, btS32, 0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),
  (Names: 'OnGroupHungry';          ParamCount: 1; Typ: (0, btS32, 0,     0,     0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),

  (Names: 'OnGroupOrderAttackHouse';ParamCount: 2; Typ: (0, btS32, btS32, 0,     0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),
  (Names: 'OnGroupOrderAttackUnit'; ParamCount: 2; Typ: (0, btS32, btS32, 0,     0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),
  (Names: 'OnGroupOrderLink';       ParamCount: 2; Typ: (0, btS32, btS32, 0,     0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),
  (Names: 'OnGroupOrderSplit';      ParamCount: 2; Typ: (0, btS32, btS32, 0,     0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),

  (Names: 'OnHouseAfterDestroyed';  ParamCount: 4; Typ: (0, btS32, btS32, btS32, btS32); Dir: (pmIn, pmIn, pmIn, pmIn)),
  (Names: 'OnHouseBuilt';           ParamCount: 1; Typ: (0, btS32, 0,     0,     0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),
  (Names: 'OnHouseDamaged';         ParamCount: 2; Typ: (0, btS32, btS32, 0,     0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),
  (Names: 'OnHouseDestroyed';       ParamCount: 2; Typ: (0, btS32, btS32, 0,     0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),
  (Names: 'OnHouseWareCountChanged';ParamCount: 4; Typ: (0, btS32, btS32, btS32, btS32); Dir: (pmIn, pmIn, pmIn, pmIn)),
  (Names: 'OnHousePlanPlaced';      ParamCount: 4; Typ: (0, btS32, btS32, btS32, btS32); Dir: (pmIn, pmIn, pmIn, pmIn)),
  (Names: 'OnHousePlanRemoved';     ParamCount: 4; Typ: (0, btS32, btS32, btS32, btS32); Dir: (pmIn, pmIn, pmIn, pmIn)),

  (Names: 'OnMarketTrade';          ParamCount: 3; Typ: (0, btS32, btS32, btS32, 0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),

  (Names: 'OnMissionStart';         ParamCount: 0; Typ: (0, 0,     0,     0,     0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),

  (Names: 'OnPlanFieldPlaced';      ParamCount: 3; Typ: (0, btS32, btS32, btS32, 0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),
  (Names: 'OnPlanFieldRemoved';     ParamCount: 3; Typ: (0, btS32, btS32, btS32, 0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),
  (Names: 'OnPlanRoadPlaced';       ParamCount: 3; Typ: (0, btS32, btS32, btS32, 0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),
  (Names: 'OnPlanRoadRemoved';      ParamCount: 3; Typ: (0, btS32, btS32, btS32, 0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),
  (Names: 'OnPlanWinefieldPlaced';  ParamCount: 3; Typ: (0, btS32, btS32, btS32, 0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),
  (Names: 'OnPlanWinefieldRemoved'; ParamCount: 3; Typ: (0, btS32, btS32, btS32, 0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),

  (Names: 'OnPlayerDefeated';       ParamCount: 1; Typ: (0, btS32, 0,     0,     0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),
  (Names: 'OnPlayerVictory';        ParamCount: 1; Typ: (0, btS32, 0,     0,     0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),

  (Names: 'OnRoadBuilt';            ParamCount: 3; Typ: (0, btS32, btS32, btS32, 0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),

  (Names: 'OnTick';                 ParamCount: 0; Typ: (0, 0,     0,     0,     0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),

  (Names: 'OnUnitAfterDied';        ParamCount: 4; Typ: (0, btS32, btS32, btS32, btS32); Dir: (pmIn, pmIn, pmIn, pmIn)),
  (Names: 'OnUnitAttacked';         ParamCount: 2; Typ: (0, btS32, btS32, 0,     0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),
  (Names: 'OnUnitDied';             ParamCount: 2; Typ: (0, btS32, btS32, 0,     0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),
  (Names: 'OnUnitTrained';          ParamCount: 1; Typ: (0, btS32, 0,     0,     0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),
  (Names: 'OnUnitWounded';          ParamCount: 2; Typ: (0, btS32, btS32, 0,     0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),

  (Names: 'OnWarriorEquipped';      ParamCount: 2; Typ: (0, btS32, btS32, 0,     0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),
  (Names: 'OnWarriorWalked';        ParamCount: 3; Typ: (0, btS32, btS32, btS32, 0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),
  (Names: 'OnWareProduced';         ParamCount: 3; Typ: (0, btS32, btS32, btS32, 0    ); Dir: (pmIn, pmIn, pmIn, pmIn)),
  (Names: 'OnWinefieldBuilt';       ParamCount: 3; Typ: (0, btS32, btS32, btS32, 0    ); Dir: (pmIn, pmIn, pmIn, pmIn))
  );
var
  I: Integer;
begin
  Result := True;
  for I := Low(PROCS) to High(PROCS) do
    if (Proc.Name = PROCS[I].Names) then
      if not ExportCheck(Sender, Proc, Slice(PROCS[I].Typ, PROCS[I].ParamCount+1), Slice(PROCS[I].Dir, PROCS[I].ParamCount)) then
      begin
        //Something is wrong, show an error
        //todo: Sender.MakeError reports the wrong line number so the user has no idea what the error is
        Sender.MakeError(PROCS[I].Names, ecTypeMismatch, '');
        Result := False;
        Exit;
      end;
end;


procedure TKMScripting.AddError(aMsg: TPSPascalCompilerMessage);
begin
  fErrorHandler.AppendError(GetErrorMessage(aMsg));
  fValidationIssues.AddError(aMsg.Row, aMsg.Col, aMsg.Param, aMsg.ShortMessageToString);
end;


procedure TKMScripting.CompileScript;
var
  I: Integer;
  compiler: TPSPascalCompiler;
  compileSuccess: Boolean;
  msg: TPSPascalCompilerMessage;
begin
  compiler := TPSPascalCompiler.Create; // create an instance of the compiler
  try
    compiler.OnUses := ScriptOnUsesFunc; // assign the OnUses event
    compiler.OnUseVariable := ScriptOnUseVariableProc;
    compiler.OnExportCheck := ScriptOnExportCheckFunc; // Assign the onExportCheck event

    compiler.AllowNoEnd := True; //Scripts only use event handlers now, main section is unused
    compiler.BooleanShortCircuit := True; //Like unchecking "Complete booolean evaluation" in Delphi compiler options

    compileSuccess := compiler.Compile(fScriptCode); // Compile the Pascal script into bytecode

    fPreProcessor.fPSPreProcessor.AdjustMessages(compiler);

    for I := 0 to compiler.MsgCount - 1 do
    begin
      msg := compiler.Msg[I];

      if msg.ErrorType = 'Hint' then
      begin
        fErrorHandler.AppendHint(GetErrorMessage(msg));
        fValidationIssues.AddHint(msg.Row, msg.Col, msg.Param, msg.ShortMessageToString);
      end
      else if msg.ErrorType = 'Warning' then
      begin
        fErrorHandler.AppendWarning(GetErrorMessage(msg));
        fValidationIssues.AddWarning(msg.Row, msg.Col, msg.Param, msg.ShortMessageToString);
      end else
        AddError(msg);
    end;

    if not compileSuccess then
      Exit;

    compiler.GetOutput(fByteCode);            // Save the output of the compiler in the string Data.
    compiler.GetDebugOutput(fDebugByteCode);  // Save the debug output of the compiler
  finally
    compiler.Free;
  end;

  LinkRuntime;
end;


//Link the ByteCode with used functions and load it into Executioner
procedure TKMScripting.LinkRuntime;

  function ValidateVarType(aType: TPSTypeRec): UnicodeString;
  var
    I: Integer;
  begin
    //Check against our set of allowed types
    if not (aType.BaseType in VALID_GLOBAL_VAR_TYPES) then
    begin
      Result := Format('Unsupported global variable type %d (%s)|', [aType.BaseType, UnicodeString(aType.ExportName)]);
      Exit;
    end;

    //Check elements of arrays/records are valid too
    case aType.BaseType of
      btArray,
      btStaticArray:
        Result := ValidateVarType(TPSTypeRec_Array(aType).ArrayType);
      btRecord:
        begin
          Result := '';
          for I := 0 to TPSTypeRec_Record(aType).FieldTypes.Count - 1 do
            Result := Result + ValidateVarType(TPSTypeRec_Record(aType).FieldTypes[I]);
        end;
    end;
  end;

var
  classImp: TPSRuntimeClassImporter;
  I: Integer;
  V: PIFVariant;
  errStr: string;
begin
  //Create an instance of the runtime class importer
  classImp := TPSRuntimeClassImporter.Create;
  try
    //Register classes and their exposed methods to Runtime
    //(uppercase is not needed, FastUpperCase does this well. See uPSRuntime.pas, line 11387)
    with classImp.Add(TKMScriptStates) do
    begin
      RegisterMethod(@TKMScriptStates.AIArmyType,                               'AIArmyType');
      RegisterMethod(@TKMScriptStates.AIAutoAttackRange,                        'AIAutoAttackRange');
      RegisterMethod(@TKMScriptStates.AIAutoBuild,                              'AIAutoBuild');
      RegisterMethod(@TKMScriptStates.AIAutoDefence,                            'AIAutoDefence');
      RegisterMethod(@TKMScriptStates.AIAutoRepair,                             'AIAutoRepair');
      RegisterMethod(@TKMScriptStates.AIDefencePositionGet,                     'AIDefencePositionGet');
      RegisterMethod(@TKMScriptStates.AIDefendAllies,                           'AIDefendAllies');
      RegisterMethod(@TKMScriptStates.AIEquipRate,                              'AIEquipRate');
      RegisterMethod(@TKMScriptStates.AIGroupsFormationGet,                     'AIGroupsFormationGet');
      RegisterMethod(@TKMScriptStates.AIRecruitDelay,                           'AIRecruitDelay');
      RegisterMethod(@TKMScriptStates.AIRecruitLimit,                           'AIRecruitLimit');
      RegisterMethod(@TKMScriptStates.AISerfsPerHouse,                          'AISerfsPerHouse');
      RegisterMethod(@TKMScriptStates.AISoldiersLimit,                          'AISoldiersLimit');
      RegisterMethod(@TKMScriptStates.AIStartPosition,                          'AIStartPosition');
      RegisterMethod(@TKMScriptStates.AIWorkerLimit,                            'AIWorkerLimit');

      RegisterMethod(@TKMScriptStates.CampaignMissionID,                        'CampaignMissionID');
      RegisterMethod(@TKMScriptStates.CampaignMissionsCount,                    'CampaignMissionsCount');
      RegisterMethod(@TKMScriptStates.CampaignUnlockedMissionID,                'CampaignUnlockedMissionID');

      RegisterMethod(@TKMScriptStates.ClosestGroup,                             'ClosestGroup');
      RegisterMethod(@TKMScriptStates.ClosestGroupMultipleTypes,                'ClosestGroupMultipleTypes');
      RegisterMethod(@TKMScriptStates.ClosestHouse,                             'ClosestHouse');
      RegisterMethod(@TKMScriptStates.ClosestHouseMultipleTypes,                'ClosestHouseMultipleTypes');
      RegisterMethod(@TKMScriptStates.ClosestUnit,                              'ClosestUnit');
      RegisterMethod(@TKMScriptStates.ClosestUnitMultipleTypes,                 'ClosestUnitMultipleTypes');

      RegisterMethod(@TKMScriptStates.ConnectedByRoad,                          'ConnectedByRoad');
      RegisterMethod(@TKMScriptStates.ConnectedByWalking,                       'ConnectedByWalking');

      RegisterMethod(@TKMScriptStates.FogRevealed,                              'FogRevealed');

      RegisterMethod(@TKMScriptStates.GameSpeed,                                'GameSpeed');
      RegisterMethod(@TKMScriptStates.GameSpeedChangeAllowed,                   'GameSpeedChangeAllowed');
      RegisterMethod(@TKMScriptStates.GameTime,                                 'GameTime');

      RegisterMethod(@TKMScriptStates.GroupAllowAllyToSelect,                   'GroupAllowAllyToSelect');
      RegisterMethod(@TKMScriptStates.GroupAssignedToDefencePosition,           'GroupAssignedToDefencePosition');
      RegisterMethod(@TKMScriptStates.GroupAt,                                  'GroupAt');
      RegisterMethod(@TKMScriptStates.GroupColumnCount,                         'GroupColumnCount');
      RegisterMethod(@TKMScriptStates.GroupDead,                                'GroupDead');
      RegisterMethod(@TKMScriptStates.GroupIdle,                                'GroupIdle');
      RegisterMethod(@TKMScriptStates.GroupInFight,                             'GroupInFight');
      RegisterMethod(@TKMScriptStates.GroupManualFormation,                     'GroupManualFormation');
      RegisterMethod(@TKMScriptStates.GroupMember,                              'GroupMember');
      RegisterMethod(@TKMScriptStates.GroupMemberCount,                         'GroupMemberCount');
      RegisterMethod(@TKMScriptStates.GroupOrder,                               'GroupOrder');
      RegisterMethod(@TKMScriptStates.GroupOwner,                               'GroupOwner');
      RegisterMethod(@TKMScriptStates.GroupType,                                'GroupType');

      RegisterMethod(@TKMScriptStates.HouseAllowAllyToSelect,                   'HouseAllowAllyToSelect');
      RegisterMethod(@TKMScriptStates.HouseAt,                                  'HouseAt');
      RegisterMethod(@TKMScriptStates.HouseBarracksRallyPointX,                 'HouseBarracksRallyPointX');
      RegisterMethod(@TKMScriptStates.HouseBarracksRallyPointY,                 'HouseBarracksRallyPointY');
      RegisterMethod(@TKMScriptStates.HouseBarracksRecruitsCount,               'HouseBarracksRecruitsCount');
      RegisterMethod(@TKMScriptStates.HouseBuildingProgress,                    'HouseBuildingProgress');
      RegisterMethod(@TKMScriptStates.HouseCanReachResources,                   'HouseCanReachResources');
      RegisterMethod(@TKMScriptStates.HouseDamage,                              'HouseDamage');
      RegisterMethod(@TKMScriptStates.HouseDeliveryBlocked,                     'HouseDeliveryBlocked');
      RegisterMethod(@TKMScriptStates.HouseDeliveryMode,                        'HouseDeliveryMode');
      RegisterMethod(@TKMScriptStates.HouseDestroyed,                           'HouseDestroyed');
      RegisterMethod(@TKMScriptStates.HouseHasOccupant,                         'HouseHasOccupant');
      RegisterMethod(@TKMScriptStates.HouseFlagPoint,                           'HouseFlagPoint');
      RegisterMethod(@TKMScriptStates.HouseIsComplete,                          'HouseIsComplete');
      RegisterMethod(@TKMScriptStates.HouseOwner,                               'HouseOwner');
      RegisterMethod(@TKMScriptStates.HousePosition,                            'HousePosition');
      RegisterMethod(@TKMScriptStates.HousePositionX,                           'HousePositionX');
      RegisterMethod(@TKMScriptStates.HousePositionY,                           'HousePositionY');
      RegisterMethod(@TKMScriptStates.HouseRepair,                              'HouseRepair');
      RegisterMethod(@TKMScriptStates.HouseResourceAmount,                      'HouseResourceAmount');
      RegisterMethod(@TKMScriptStates.HouseSchoolQueue,                         'HouseSchoolQueue');
      RegisterMethod(@TKMScriptStates.HouseSiteIsDigged,                        'HouseSiteIsDigged');
      RegisterMethod(@TKMScriptStates.HouseTownHallMaxGold,                     'HouseTownHallMaxGold');
      RegisterMethod(@TKMScriptStates.HouseType,                                'HouseType');
      RegisterMethod(@TKMScriptStates.HouseTypeMaxHealth,                       'HouseTypeMaxHealth');
      RegisterMethod(@TKMScriptStates.HouseTypeName,                            'HouseTypeName');
      RegisterMethod(@TKMScriptStates.HouseTypeToOccupantType,                  'HouseTypeToOccupantType');
      RegisterMethod(@TKMScriptStates.HouseUnlocked,                            'HouseUnlocked');
      RegisterMethod(@TKMScriptStates.HouseWoodcutterChopOnly,                  'HouseWoodcutterChopOnly');
      RegisterMethod(@TKMScriptStates.HouseWoodcutterMode,                      'HouseWoodcutterMode');
      RegisterMethod(@TKMScriptStates.HouseWareBlocked,                         'HouseWareBlocked');
      RegisterMethod(@TKMScriptStates.HouseWareBlockedTakeOut,                  'HouseWareBlockedTakeOut');
      RegisterMethod(@TKMScriptStates.HouseWeaponsOrdered,                      'HouseWeaponsOrdered');

      RegisterMethod(@TKMScriptStates.IsFieldAt,                                'IsFieldAt');
      RegisterMethod(@TKMScriptStates.IsRoadAt,                                 'IsRoadAt');
      RegisterMethod(@TKMScriptStates.IsWinefieldAt,                            'IsWinefieldAt');

      RegisterMethod(@TKMScriptStates.IsPlanAt,                                 'IsPlanAt');
      RegisterMethod(@TKMScriptStates.IsFieldPlanAt,                            'IsFieldPlanAt');
      RegisterMethod(@TKMScriptStates.IsHousePlanAt,                            'IsHousePlanAt');
      RegisterMethod(@TKMScriptStates.IsRoadPlanAt,                             'IsRoadPlanAt');
      RegisterMethod(@TKMScriptStates.IsWinefieldPlanAt,                        'IsWinefieldPlanAt');

      RegisterMethod(@TKMScriptStates.IsMissionBuildType,                       'IsMissionBuildType');
      RegisterMethod(@TKMScriptStates.IsMissionFightType,                       'IsMissionFightType');
      RegisterMethod(@TKMScriptStates.IsMissionCoopType,                        'IsMissionCoopType');
      RegisterMethod(@TKMScriptStates.IsMissionSpecialType,                     'IsMissionSpecialType');
      RegisterMethod(@TKMScriptStates.IsMissionPlayableAsSP,                    'IsMissionPlayableAsSP');
      RegisterMethod(@TKMScriptStates.IsMissionBlockColorSelection,             'IsMissionBlockColorSelection');
      RegisterMethod(@TKMScriptStates.IsMissionBlockTeamSelection,              'IsMissionBlockTeamSelection');
      RegisterMethod(@TKMScriptStates.IsMissionBlockPeacetime,                  'IsMissionBlockPeacetime');
      RegisterMethod(@TKMScriptStates.IsMissionBlockFullMapPreview,             'IsMissionBlockFullMapPreview');

      RegisterMethod(@TKMScriptStates.KaMRandom,                                'KaMRandom');
      RegisterMethod(@TKMScriptStates.KaMRandomI,                               'KaMRandomI');

      RegisterMethod(@TKMScriptStates.LocationCount,                            'LocationCount');

      RegisterMethod(@TKMScriptStates.MapHeight,                                'MapHeight');
      RegisterMethod(@TKMScriptStates.MapTileHasOnlyTerrainKind,                'MapTileHasOnlyTerrainKind');
      RegisterMethod(@TKMScriptStates.MapTileHasOnlyTerrainKinds,               'MapTileHasOnlyTerrainKinds');
      RegisterMethod(@TKMScriptStates.MapTileHasTerrainKind,                    'MapTileHasTerrainKind');
      RegisterMethod(@TKMScriptStates.MapTileHeight,                            'MapTileHeight');
      RegisterMethod(@TKMScriptStates.MapTileIsCoal,                            'MapTileIsCoal');
      RegisterMethod(@TKMScriptStates.MapTileIsGold,                            'MapTileIsGold');
      RegisterMethod(@TKMScriptStates.MapTileIsIce,                             'MapTileIsIce');
      RegisterMethod(@TKMScriptStates.MapTileIsInMapCoords,                     'MapTileIsInMapCoords');
      RegisterMethod(@TKMScriptStates.MapTileIsIron,                            'MapTileIsIron');
      RegisterMethod(@TKMScriptStates.MapTileIsSand,                            'MapTileIsSand');
      RegisterMethod(@TKMScriptStates.MapTileIsSnow,                            'MapTileIsSnow');
      RegisterMethod(@TKMScriptStates.MapTileIsSoil,                            'MapTileIsSoil');
      RegisterMethod(@TKMScriptStates.MapTileIsStone,                           'MapTileIsStone');
      RegisterMethod(@TKMScriptStates.MapTileIsWater,                           'MapTileIsWater');
      RegisterMethod(@TKMScriptStates.MapTileObject,                            'MapTileObject');
      RegisterMethod(@TKMScriptStates.MapTileOverlay,                           'MapTileOverlay');
      RegisterMethod(@TKMScriptStates.MapTileOwner,                             'MapTileOwner');
      RegisterMethod(@TKMScriptStates.MapTilePassability,                       'MapTilePassability');
      RegisterMethod(@TKMScriptStates.MapTileRotation,                          'MapTileRotation');
      RegisterMethod(@TKMScriptStates.MapTileType,                              'MapTileType');
      RegisterMethod(@TKMScriptStates.MapWidth,                                 'MapWidth');

      RegisterMethod(@TKMScriptStates.MissionAuthor,                            'MissionAuthor');
      RegisterMethod(@TKMScriptStates.MissionBigDesc,                           'MissionBigDesc');
      RegisterMethod(@TKMScriptStates.MissionBigDescLibx,                       'MissionBigDescLibx');
      RegisterMethod(@TKMScriptStates.MissionSmallDesc,                         'MissionSmallDesc');
      RegisterMethod(@TKMScriptStates.MissionSmallDescLibx,                     'MissionSmallDescLibx');

      RegisterMethod(@TKMScriptStates.MissionDifficulty,                        'MissionDifficulty');
      RegisterMethod(@TKMScriptStates.MissionDifficultyLevels,                  'MissionDifficultyLevels');

      RegisterMethod(@TKMScriptStates.MissionVersion,                           'MissionVErsion');

      RegisterMethod(@TKMScriptStates.MarketFromWare,                           'MarketFromWare');
      RegisterMethod(@TKMScriptStates.MarketLossFactor,                         'MarketLossFactor');
      RegisterMethod(@TKMScriptStates.MarketOrderAmount,                        'MarketOrderAmount');
      RegisterMethod(@TKMScriptStates.MarketToWare,                             'MarketToWare');
      RegisterMethod(@TKMScriptStates.MarketValue,                              'MarketValue');

      RegisterMethod(@TKMScriptStates.PeaceTime,                                'PeaceTime');

      RegisterMethod(@TKMScriptStates.PlayerAllianceCheck,                      'PlayerAllianceCheck');
      RegisterMethod(@TKMScriptStates.PlayerColorFlag,                          'PlayerColorFlag');
      RegisterMethod(@TKMScriptStates.PlayerColorText,                          'PlayerColorText');
      RegisterMethod(@TKMScriptStates.PlayerDefeated,                           'PlayerDefeated');
      RegisterMethod(@TKMScriptStates.PlayerEnabled,                            'PlayerEnabled');
      RegisterMethod(@TKMScriptStates.PlayerGetAllGroups,                       'PlayerGetAllGroups');
      RegisterMethod(@TKMScriptStates.PlayerGetAllHouses,                       'PlayerGetAllHouses');
      RegisterMethod(@TKMScriptStates.PlayerGetAllUnits,                        'PlayerGetAllUnits');
      RegisterMethod(@TKMScriptStates.PlayerIsAI,                               'PlayerIsAI');
      RegisterMethod(@TKMScriptStates.PlayerName,                               'PlayerName');
      RegisterMethod(@TKMScriptStates.PlayerVictorious,                         'PlayerVictorious');
      RegisterMethod(@TKMScriptStates.PlayerWareDistribution,                   'PlayerWareDistribution');

      RegisterMethod(@TKMScriptStates.StatAIDefencePositionsCount,              'StatAIDefencePositionsCount');
      RegisterMethod(@TKMScriptStates.StatArmyCount,                            'StatArmyCount');
      RegisterMethod(@TKMScriptStates.StatCitizenCount,                         'StatCitizenCount');
      RegisterMethod(@TKMScriptStates.StatHouseCount,                           'StatHouseCount');
      RegisterMethod(@TKMScriptStates.StatHouseMultipleTypesCount,              'StatHouseMultipleTypesCount');
      RegisterMethod(@TKMScriptStates.StatHouseTypeCount,                       'StatHouseTypeCount');
      RegisterMethod(@TKMScriptStates.StatHouseTypePlansCount,                  'StatHouseTypePlansCount');
      RegisterMethod(@TKMScriptStates.StatPlayerCount,                          'StatPlayerCount');
      RegisterMethod(@TKMScriptStates.StatResourceProducedCount,                'StatResourceProducedCount');
      RegisterMethod(@TKMScriptStates.StatResourceProducedMultipleTypesCount,   'StatResourceProducedMultipleTypesCount');
      RegisterMethod(@TKMScriptStates.StatUnitCount,                            'StatUnitCount');
      RegisterMethod(@TKMScriptStates.StatUnitKilledCount,                      'StatUnitKilledCount');
      RegisterMethod(@TKMScriptStates.StatUnitKilledMultipleTypesCount,         'StatUnitKilledMultipleTypesCount');
      RegisterMethod(@TKMScriptStates.StatUnitLostCount,                        'StatUnitLostCount');
      RegisterMethod(@TKMScriptStates.StatUnitLostMultipleTypesCount,           'StatUnitLostMultipleTypesCount');
      RegisterMethod(@TKMScriptStates.StatUnitMultipleTypesCount,               'StatUnitMultipleTypesCount');
      RegisterMethod(@TKMScriptStates.StatUnitTypeCount,                        'StatUnitTypeCount');

      RegisterMethod(@TKMScriptStates.UnitAllowAllyToSelect,                    'UnitAllowAllyToSelect');
      RegisterMethod(@TKMScriptStates.UnitAt,                                   'UnitAt');
      RegisterMethod(@TKMScriptStates.UnitCarrying,                             'UnitCarrying');
      RegisterMethod(@TKMScriptStates.UnitDead,                                 'UnitDead');
      RegisterMethod(@TKMScriptStates.UnitDirection,                            'UnitDirection');
      RegisterMethod(@TKMScriptStates.UnitDismissable,                          'UnitDismissable');
      RegisterMethod(@TKMScriptStates.UnitHome,                                 'UnitHome');
      RegisterMethod(@TKMScriptStates.UnitHPCurrent,                            'UnitHPCurrent');
      RegisterMethod(@TKMScriptStates.UnitHPMax,                                'UnitHPMax');
      RegisterMethod(@TKMScriptStates.UnitHPInvulnerable,                       'UnitHPInvulnerable');
      RegisterMethod(@TKMScriptStates.UnitHunger,                               'UnitHunger');
      RegisterMethod(@TKMScriptStates.UnitIdle,                                 'UnitIdle');
      RegisterMethod(@TKMScriptStates.UnitLowHunger,                            'UnitLowHunger');
      RegisterMethod(@TKMScriptStates.UnitMaxHunger,                            'UnitMaxHunger');
      RegisterMethod(@TKMScriptStates.UnitOwner,                                'UnitOwner');
      RegisterMethod(@TKMScriptStates.UnitPosition,                             'UnitPosition');
      RegisterMethod(@TKMScriptStates.UnitPositionX,                            'UnitPositionX');
      RegisterMethod(@TKMScriptStates.UnitPositionY,                            'UnitPositionY');
      RegisterMethod(@TKMScriptStates.UnitsGroup,                               'UnitsGroup');
      RegisterMethod(@TKMScriptStates.UnitType,                                 'UnitType');
      RegisterMethod(@TKMScriptStates.UnitTypeName,                             'UnitTypeName');
      RegisterMethod(@TKMScriptStates.UnitUnlocked,                             'UnitUnlocked');

      RegisterMethod(@TKMScriptStates.WareTypeName,                             'WareTypeName');
      RegisterMethod(@TKMScriptStates.WarriorInFight,                           'WarriorInFight');
    end;

    with classImp.Add(TKMScriptActions) do
    begin
      RegisterMethod(@TKMScriptActions.AIArmyType,                              'AIArmyType');
      RegisterMethod(@TKMScriptActions.AIAttackAdd,                             'AIAttackAdd');
      RegisterMethod(@TKMScriptActions.AIAttackRemove,                          'AIAttackRemove');
      RegisterMethod(@TKMScriptActions.AIAttackRemoveAll,                       'AIAttackRemoveAll');
      RegisterMethod(@TKMScriptActions.AIAutoAttackRange,                       'AIAutoAttackRange');
      RegisterMethod(@TKMScriptActions.AIAutoBuild,                             'AIAutoBuild');
      RegisterMethod(@TKMScriptActions.AIAutoDefence,                           'AIAutoDefence');
      RegisterMethod(@TKMScriptActions.AIAutoRepair,                            'AIAutoRepair');
      RegisterMethod(@TKMScriptActions.AIDefencePositionAdd,                    'AIDefencePositionAdd');
      RegisterMethod(@TKMScriptActions.AIDefencePositionRemove,                 'AIDefencePositionRemove');
      RegisterMethod(@TKMScriptActions.AIDefencePositionRemoveAll,              'AIDefencePositionRemoveAll');
      RegisterMethod(@TKMScriptActions.AIDefendAllies,                          'AIDefendAllies');
      RegisterMethod(@TKMScriptActions.AIEquipRate,                             'AIEquipRate');
      RegisterMethod(@TKMScriptActions.AIGroupsFormationSet,                    'AIGroupsFormationSet');
      RegisterMethod(@TKMScriptActions.AIRecruitDelay,                          'AIRecruitDelay');
      RegisterMethod(@TKMScriptActions.AIRecruitLimit,                          'AIRecruitLimit');
      RegisterMethod(@TKMScriptActions.AISerfsPerHouse,                         'AISerfsPerHouse');
      RegisterMethod(@TKMScriptActions.AISoldiersLimit,                         'AISoldiersLimit');
      RegisterMethod(@TKMScriptActions.AIStartPosition,                         'AIStartPosition');
      RegisterMethod(@TKMScriptActions.AIWorkerLimit,                           'AIWorkerLimit');

      RegisterMethod(@TKMScriptActions.CinematicEnd,                            'CinematicEnd');
      RegisterMethod(@TKMScriptActions.CinematicPanTo,                          'CinematicPanTo');
      RegisterMethod(@TKMScriptActions.CinematicStart,                          'CinematicStart');

      RegisterMethod(@TKMScriptActions.FogCoverAll,                             'FogCoverAll');
      RegisterMethod(@TKMScriptActions.FogCoverCircle,                          'FogCoverCircle');
      RegisterMethod(@TKMScriptActions.FogCoverRect,                            'FogCoverRect');
      RegisterMethod(@TKMScriptActions.FogRevealAll,                            'FogRevealAll');
      RegisterMethod(@TKMScriptActions.FogRevealCircle,                         'FogRevealCircle');
      RegisterMethod(@TKMScriptActions.FogRevealRect,                           'FogRevealRect');

      RegisterMethod(@TKMScriptActions.GameSpeed,                               'GameSpeed');
      RegisterMethod(@TKMScriptActions.GameSpeedChangeAllowed,                  'GameSpeedChangeAllowed');

      RegisterMethod(@TKMScriptActions.GiveAnimal,                              'GiveAnimal');
      RegisterMethod(@TKMScriptActions.GiveField,                               'GiveField');
      RegisterMethod(@TKMScriptActions.GiveFieldAged,                           'GiveFieldAged');
      RegisterMethod(@TKMScriptActions.GiveGroup,                               'GiveGroup');
      RegisterMethod(@TKMScriptActions.GiveUnit,                                'GiveUnit');
      RegisterMethod(@TKMScriptActions.GiveHouse,                               'GiveHouse');
      RegisterMethod(@TKMScriptActions.GiveHouseSite,                           'GiveHouseSite');
      RegisterMethod(@TKMScriptActions.GiveRoad,                                'GiveRoad');
      RegisterMethod(@TKMScriptActions.GiveWares,                               'GiveWares');
      RegisterMethod(@TKMScriptActions.GiveWeapons,                             'GiveWeapons');
      RegisterMethod(@TKMScriptActions.GiveWineField,                           'GiveWineField');
      RegisterMethod(@TKMScriptActions.GiveWineFieldAged,                       'GiveWineFieldAged');

      RegisterMethod(@TKMScriptActions.GroupAllowAllyToSelect,                  'GroupAllowAllyToSelect');
      RegisterMethod(@TKMScriptActions.GroupBlockOrders,                        'GroupBlockOrders');
      RegisterMethod(@TKMScriptActions.GroupDisableHungryMessage,               'GroupDisableHungryMessage');
      RegisterMethod(@TKMScriptActions.GroupHungerSet,                          'GroupHungerSet');
      RegisterMethod(@TKMScriptActions.GroupKillAll,                            'GroupKillAll');
      RegisterMethod(@TKMScriptActions.GroupOrderAttackHouse,                   'GroupOrderAttackHouse');
      RegisterMethod(@TKMScriptActions.GroupOrderAttackUnit,                    'GroupOrderAttackUnit');
      RegisterMethod(@TKMScriptActions.GroupOrderFood,                          'GroupOrderFood');
      RegisterMethod(@TKMScriptActions.GroupOrderHalt,                          'GroupOrderHalt');
      RegisterMethod(@TKMScriptActions.GroupOrderLink,                          'GroupOrderLink');
      RegisterMethod(@TKMScriptActions.GroupOrderSplit,                         'GroupOrderSplit');
      RegisterMethod(@TKMScriptActions.GroupOrderSplitUnit,                     'GroupOrderSplitUnit');
      RegisterMethod(@TKMScriptActions.GroupOrderStorm,                         'GroupOrderStorm');
      RegisterMethod(@TKMScriptActions.GroupOrderWalk,                          'GroupOrderWalk');
      RegisterMethod(@TKMScriptActions.GroupSetFormation,                       'GroupSetFormation');

      RegisterMethod(@TKMScriptActions.HouseAddBuildingMaterials,               'HouseAddBuildingMaterials');
      RegisterMethod(@TKMScriptActions.HouseAddBuildingProgress,                'HouseAddBuildingProgress');
      RegisterMethod(@TKMScriptActions.HouseAddDamage,                          'HouseAddDamage');
      RegisterMethod(@TKMScriptActions.HouseAddRepair,                          'HouseAddRepair');
      RegisterMethod(@TKMScriptActions.HouseAddWaresTo,                         'HouseAddWaresTo');
      RegisterMethod(@TKMScriptActions.HouseAllow,                              'HouseAllow');
      RegisterMethod(@TKMScriptActions.HouseAllowAllyToSelect,                  'HouseAllowAllyToSelect');
      RegisterMethod(@TKMScriptActions.HouseAllowAllyToSelectAll,               'HouseAllowAllyToSelectAll');
      RegisterMethod(@TKMScriptActions.HouseBarracksEquip,                      'HouseBarracksEquip');
      RegisterMethod(@TKMScriptActions.HouseBarracksGiveRecruit,                'HouseBarracksGiveRecruit');
      RegisterMethod(@TKMScriptActions.HouseDeliveryBlock,                      'HouseDeliveryBlock');
      RegisterMethod(@TKMScriptActions.HouseDisableUnoccupiedMessage,           'HouseDisableUnoccupiedMessage');
      RegisterMethod(@TKMScriptActions.HouseDestroy,                            'HouseDestroy');
      RegisterMethod(@TKMScriptActions.HouseRepairEnable,                       'HouseRepairEnable');
      RegisterMethod(@TKMScriptActions.HouseSchoolQueueAdd,                     'HouseSchoolQueueAdd');
      RegisterMethod(@TKMScriptActions.HouseSchoolQueueRemove,                  'HouseSchoolQueueRemove');
      RegisterMethod(@TKMScriptActions.HouseTakeWaresFrom,                      'HouseTakeWaresFrom');
      RegisterMethod(@TKMScriptActions.HouseTownHallEquip,                      'HouseTownHallEquip');
      RegisterMethod(@TKMScriptActions.HouseTownHallMaxGold,                    'HouseTownHallMaxGold');
      RegisterMethod(@TKMScriptActions.HouseUnlock,                             'HouseUnlock');
      RegisterMethod(@TKMScriptActions.HouseWoodcutterChopOnly,                 'HouseWoodcutterChopOnly');
      RegisterMethod(@TKMScriptActions.HouseWoodcutterMode,                     'HouseWoodcutterMode');
      RegisterMethod(@TKMScriptActions.HouseWareBlock,                          'HouseWareBlock');
      RegisterMethod(@TKMScriptActions.HouseWareBlockTakeOut,                   'HouseWareBlockTakeOut');
      RegisterMethod(@TKMScriptActions.HouseWeaponsOrderSet,                    'HouseWeaponsOrderSet');

      RegisterMethod(@TKMScriptActions.Log,                                     'Log');

      RegisterMethod(@TKMScriptActions.MapBrush,                                'MapBrush');
      RegisterMethod(@TKMScriptActions.MapBrushElevation,                       'MapBrushElevation');
      RegisterMethod(@TKMScriptActions.MapBrushEqualize,                        'MapBrushEqualize');
      RegisterMethod(@TKMScriptActions.MapBrushFlatten,                         'MapBrushFlatten');
      RegisterMethod(@TKMScriptActions.MapBrushMagicWater,                      'MapBrushMagicWater');
      RegisterMethod(@TKMScriptActions.MapBrushWithMask,                        'MapBrushWithMask');

      RegisterMethod(@TKMScriptActions.MapTileSet,                              'MapTileSet');
      RegisterMethod(@TKMScriptActions.MapTilesArraySet,                        'MapTilesArraySet');
      RegisterMethod(@TKMScriptActions.MapTilesArraySetS,                       'MapTilesArraySetS');
      RegisterMethod(@TKMScriptActions.MapTileHeightSet,                        'MapTileHeightSet');
      RegisterMethod(@TKMScriptActions.MapTileObjectSet,                        'MapTileObjectSet');
      RegisterMethod(@TKMScriptActions.MapTileOverlaySet,                       'MapTileOverlaySet');

      RegisterMethod(@TKMScriptActions.MarketSetTrade,                          'MarketSetTrade');

      RegisterMethod(@TKMScriptActions.OverlayTextAppend,                       'OverlayTextAppend');
      RegisterMethod(@TKMScriptActions.OverlayTextAppendFormatted,              'OverlayTextAppendFormatted');
      RegisterMethod(@TKMScriptActions.OverlayTextSet,                          'OverlayTextSet');
      RegisterMethod(@TKMScriptActions.OverlayTextSetFormatted,                 'OverlayTextSetFormatted');

      RegisterMethod(@TKMScriptActions.Peacetime,                               'Peacetime');

      RegisterMethod(@TKMScriptActions.PlanAddField,                            'PlanAddField');
      RegisterMethod(@TKMScriptActions.PlanAddHouse,                            'PlanAddHouse');
      RegisterMethod(@TKMScriptActions.PlanAddRoad,                             'PlanAddRoad');
      RegisterMethod(@TKMScriptActions.PlanAddWinefield,                        'PlanAddWinefield');
      RegisterMethod(@TKMScriptActions.PlanConnectRoad,                         'PlanConnectRoad');
      RegisterMethod(@TKMScriptActions.PlanRemove,                              'PlanRemove');

      RegisterMethod(@TKMScriptActions.PlayerAllianceChange,                    'PlayerAllianceChange');
      RegisterMethod(@TKMScriptActions.PlayerAllianceNFogChange,                'PlayerAllianceNFogChange');
      RegisterMethod(@TKMScriptActions.PlayerAddDefaultGoals,                   'PlayerAddDefaultGoals');
      RegisterMethod(@TKMScriptActions.PlayerDefeat,                            'PlayerDefeat');
      RegisterMethod(@TKMScriptActions.PlayerGoalsRemoveAll,                    'PlayerGoalsRemoveAll');
      RegisterMethod(@TKMScriptActions.PlayerShareBeacons,                      'PlayerShareBeacons');
      RegisterMethod(@TKMScriptActions.PlayerShareFog,                          'PlayerShareFog');
      RegisterMethod(@TKMScriptActions.PlayerShareFogCompliment,                'PlayerShareFogCompliment');
      RegisterMethod(@TKMScriptActions.PlayerWareDistribution,                  'PlayerWareDistribution');
      RegisterMethod(@TKMScriptActions.PlayerWin,                               'PlayerWin');

      RegisterMethod(@TKMScriptActions.PlayWAV,                                 'PlayWAV');
      RegisterMethod(@TKMScriptActions.PlayWAVAtLocation,                       'PlayWAVAtLocation');
      RegisterMethod(@TKMScriptActions.PlayWAVAtLocationLooped,                 'PlayWAVAtLocationLooped');
      RegisterMethod(@TKMScriptActions.PlayWAVFadeMusic,                        'PlayWAVFadeMusic');
      RegisterMethod(@TKMScriptActions.PlayWAVLooped,                           'PlayWAVLooped');
      RegisterMethod(@TKMScriptActions.StopLoopedWAV,                           'StopLoopedWAV');

      RegisterMethod(@TKMScriptActions.PlayOGG,                                 'PlayOGG');
      RegisterMethod(@TKMScriptActions.PlayOGGAtLocation,                       'PlayOGGAtLocation');
      RegisterMethod(@TKMScriptActions.PlayOGGAtLocationLooped,                 'PlayOGGAtLocationLooped');
      RegisterMethod(@TKMScriptActions.PlayOGGFadeMusic,                        'PlayOGGFadeMusic');
      RegisterMethod(@TKMScriptActions.PlayOGGLooped,                           'PlayOGGLooped');
      RegisterMethod(@TKMScriptActions.StopLoopedOGG,                           'StopLoopedOGG');

      RegisterMethod(@TKMScriptActions.PlaySound,                               'PlaySound');
      RegisterMethod(@TKMScriptActions.PlaySoundAtLocation,                     'PlaySoundAtLocation');
      RegisterMethod(@TKMScriptActions.StopSound,                               'StopSound');

      RegisterMethod(@TKMScriptActions.RemoveRoad,                              'RemoveRoad');

      RegisterMethod(@TKMScriptActions.SetTradeAllowed,                         'SetTradeAllowed');

      RegisterMethod(@TKMScriptActions.ShowMsg,                                 'ShowMsg');
      RegisterMethod(@TKMScriptActions.ShowMsgFormatted,                        'ShowMsgFormatted');
      RegisterMethod(@TKMScriptActions.ShowMsgGoto,                             'ShowMsgGoto');
      RegisterMethod(@TKMScriptActions.ShowMsgGotoFormatted,                    'ShowMsgGotoFormatted');

      RegisterMethod(@TKMScriptActions.UnitAllowAllyToSelect,                   'UnitAllowAllyToSelect');
      RegisterMethod(@TKMScriptActions.UnitBlock,                               'UnitBlock');
      RegisterMethod(@TKMScriptActions.UnitDirectionSet,                        'UnitDirectionSet');
      RegisterMethod(@TKMScriptActions.UnitDismiss,                             'UnitDismiss');
      RegisterMethod(@TKMScriptActions.UnitDismissableSet,                      'UnitDismissableSet');
      RegisterMethod(@TKMScriptActions.UnitDismissCancel,                       'UnitDismissCancel');
      RegisterMethod(@TKMScriptActions.UnitHPChange,                            'UnitHPChange');
      RegisterMethod(@TKMScriptActions.UnitHPSetInvulnerable,                   'UnitHPSetInvulnerable');
      RegisterMethod(@TKMScriptActions.UnitHungerSet,                           'UnitHungerSet');
      RegisterMethod(@TKMScriptActions.UnitKill,                                'UnitKill');
      RegisterMethod(@TKMScriptActions.UnitOrderWalk,                           'UnitOrderWalk');
    end;

    with classImp.Add(TKMScriptUtils) do
    begin
      RegisterMethod(@TKMScriptUtils.AbsI,                                      'AbsI');
      RegisterMethod(@TKMScriptUtils.AbsS,                                      'AbsS');

      RegisterMethod(@TKMScriptUtils.ArrayElementCount,                         'ArrayElementCount');
      RegisterMethod(@TKMScriptUtils.ArrayElementCountB,                        'ArrayElementCountB');
      RegisterMethod(@TKMScriptUtils.ArrayElementCountI,                        'ArrayElementCountI');
      RegisterMethod(@TKMScriptUtils.ArrayElementCountS,                        'ArrayElementCountS');

      RegisterMethod(@TKMScriptUtils.ArrayHasElement,                           'ArrayHasElement');
      RegisterMethod(@TKMScriptUtils.ArrayHasElementB,                          'ArrayHasElementB');
      RegisterMethod(@TKMScriptUtils.ArrayHasElementI,                          'ArrayHasElementI');
      RegisterMethod(@TKMScriptUtils.ArrayHasElementS,                          'ArrayHasElementS');

      RegisterMethod(@TKMScriptUtils.ArrayRemoveIndexI,                         'ArrayRemoveIndexI');
      RegisterMethod(@TKMScriptUtils.ArrayRemoveIndexS,                         'ArrayRemoveIndexS');

      RegisterMethod(@TKMScriptUtils.BoolToStr,                                 'BoolToStr');

      RegisterMethod(@TKMScriptUtils.ColorBrightness,                           'ColorBrightness');

      RegisterMethod(@TKMScriptUtils.CompareString,                             'CompareString');
      RegisterMethod(@TKMScriptUtils.CompareText,                               'CompareText');
      RegisterMethod(@TKMScriptUtils.CopyString,                                'CopyString');

      RegisterMethod(@TKMScriptUtils.DeleteString,                              'DeleteString');

      RegisterMethod(@TKMScriptUtils.EnsureRangeI,                              'EnsureRangeI');
      RegisterMethod(@TKMScriptUtils.EnsureRangeS,                              'EnsureRangeS');

      RegisterMethod(@TKMScriptUtils.Format,                                    'Format');
      RegisterMethod(@TKMScriptUtils.FormatFloat,                               'FormatFloat');

      RegisterMethod(@TKMScriptUtils.IfThen,                                    'IfThen');
      RegisterMethod(@TKMScriptUtils.IfThenI,                                   'IfThenI');
      RegisterMethod(@TKMScriptUtils.IfThenS,                                   'IfThenS');

      RegisterMethod(@TKMScriptUtils.InAreaI,                                   'InAreaI');
      RegisterMethod(@TKMScriptUtils.InAreaS,                                   'InAreaS');

      RegisterMethod(@TKMScriptUtils.InRangeI,                                  'InRangeI');
      RegisterMethod(@TKMScriptUtils.InRangeS,                                  'InRangeS');

      RegisterMethod(@TKMScriptUtils.InsertString,                              'InsertString');

      RegisterMethod(@TKMScriptUtils.KMPoint,                                   'KMPoint');

      RegisterMethod(@TKMScriptUtils.LowerCase,                                 'LowerCase');

      RegisterMethod(@TKMScriptUtils.MaxI,                                      'MaxI');
      RegisterMethod(@TKMScriptUtils.MaxS,                                      'MaxS');

      RegisterMethod(@TKMScriptUtils.MaxInArrayI,                               'MaxInArrayI');
      RegisterMethod(@TKMScriptUtils.MaxInArrayS,                               'MaxInArrayS');

      RegisterMethod(@TKMScriptUtils.MinI,                                      'MinI');
      RegisterMethod(@TKMScriptUtils.MinS,                                      'MinS');

      RegisterMethod(@TKMScriptUtils.MinInArrayI,                               'MinInArrayI');
      RegisterMethod(@TKMScriptUtils.MinInArrayS,                               'MinInArrayS');

      RegisterMethod(@TKMScriptUtils.MoveString,                                'MoveString');

      RegisterMethod(@TKMScriptUtils.Pos,                                       'Pos');

      RegisterMethod(@TKMScriptUtils.Power,                                     'Power');

      RegisterMethod(@TKMScriptUtils.RandomRangeI,                              'RandomRangeI');

      RegisterMethod(@TKMScriptUtils.RGBDecToBGRHex,                            'RGBDecToBGRHex');
      RegisterMethod(@TKMScriptUtils.RGBToBGRHex,                               'RGBToBGRHex');


      RegisterMethod(@TKMScriptUtils.CeilTo,                                    'CeilTo');
      RegisterMethod(@TKMScriptUtils.FloorTo,                                   'FloorTo');
      RegisterMethod(@TKMScriptUtils.RoundTo,                                   'RoundTo');
      RegisterMethod(@TKMScriptUtils.TruncTo,                                   'TruncTo');

      RegisterMethod(@TKMScriptUtils.SumI,                                      'SumI');
      RegisterMethod(@TKMScriptUtils.SumS,                                      'SumS');

      RegisterMethod(@TKMScriptUtils.Sqr,                                       'Sqr');

      RegisterMethod(@TKMScriptUtils.StringReplace,                             'StringReplace');

      RegisterMethod(@TKMScriptUtils.TimeToString,                              'TimeToString');
      RegisterMethod(@TKMScriptUtils.TimeToTick,                                'TimeToTick');

      RegisterMethod(@TKMScriptUtils.Trim,                                      'Trim');
      RegisterMethod(@TKMScriptUtils.TrimLeft,                                  'TrimLeft');
      RegisterMethod(@TKMScriptUtils.TrimRight,                                 'TrimRight');

      RegisterMethod(@TKMScriptUtils.UpperCase,                                 'UpperCase');

    end;

    //Append classes info to Exec
    RegisterClassLibraryRuntime(fExec, classImp);

    if not fExec.LoadData(fByteCode) then // Load the data from the Data string.
    begin
      { For some reason the script could not be loaded. This is usually the case when a
        library that has been used at compile time isn't registered at runtime. }
      fErrorHandler.AppendErrorStr('Unknown error in loading bytecode to Exec|');
      fValidationIssues.AddError(0, 0, '', 'Unknown error in loading bytecode to Exec');
      Exit;
    end;

    if (fExec is TPSDebugExec) and TPSDebugExec(fExec).DebugEnabled then
      TPSDebugExec(fExec).LoadDebugData(fDebugByteCode);

    //Check global variables in script to be only of supported type
    for I := 0 to fExec.GetVarCount - 1 do
    begin
      V := fExec.GetVarNo(I);
      //Promote to Unicode just to make compiler happy
      if SameText(UnicodeString(V.FType.ExportName), 'TKMScriptStates')
      or SameText(UnicodeString(V.FType.ExportName), 'TKMScriptActions')
      or SameText(UnicodeString(V.FType.ExportName), 'TKMScriptUtils') then
        Continue;

      errStr := ValidateVarType(V.FType);
      fErrorHandler.AppendErrorStr(errStr);
      if errStr <> '' then
        fValidationIssues.AddError(0, 0, '', ValidateVarType(V.FType));
      if fErrorHandler.HasErrors then
      begin
        //Don't allow the script to run
        fExec.Clear;
        Exit;
      end;
    end;

    //Link script objects with objects
    SetVariantToClass(fExec.GetVarNo(fExec.GetVar('STATES')), fStates);
    SetVariantToClass(fExec.GetVarNo(fExec.GetVar('ACTIONS')), fActions);
    SetVariantToClass(fExec.GetVarNo(fExec.GetVar('UTILS')), fUtils);
    SetVariantToClass(fExec.GetVarNo(fExec.GetVar('S')), fStates);
    SetVariantToClass(fExec.GetVarNo(fExec.GetVar('A')), fActions);
    SetVariantToClass(fExec.GetVarNo(fExec.GetVar('U')), fUtils);
  finally
    classImp.Free;
  end;

  //Link events into the script
  gScriptEvents.LinkEventsAndCommands;
end;


procedure TKMScripting.ExportDataToText;
var
  s: string;
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    IFPS3DataToText(fByteCode, s);
    SL.Text := s;
    ForceDirectories(ExeDir  + 'Export' + PathDelim);
    SL.SaveToFile(ExeDir + 'Export' + PathDelim + 'script_DataText.txt');
  finally
    SL.Free;
  end;
end;


procedure TKMScripting.LoadVar(LoadStream: TKMemoryStream; Src: Pointer; aType: TPSTypeRec);
var
  I: Integer;
  elemCount: Integer;
  offset: Cardinal;
begin
  //See uPSRuntime line 1630 for algo idea
  case aType.BaseType of
    btU8:            LoadStream.Read(tbtu8(Src^)); //Byte, Boolean
    btS8:            LoadStream.Read(tbts8(Src^)); //ShortInt
    btU16:           LoadStream.Read(tbtu16(Src^)); //Word
    btS16:           LoadStream.Read(tbts16(Src^)); //SmallInt
    btU32:           LoadStream.Read(tbtu32(Src^)); //Cardinal / LongInt
    btS32:           LoadStream.Read(tbts32(Src^)); //Integer
    btSingle:        LoadStream.Read(tbtsingle(Src^));
    btString:        LoadStream.ReadA(tbtString(Src^));
    btUnicodeString: LoadStream.ReadW(tbtUnicodeString(Src^));
    btStaticArray:begin
                    LoadStream.Read(elemCount);
                    Assert(elemCount = TPSTypeRec_StaticArray(aType).Size, 'Script array element count mismatches saved count');
                    for I := 0 to elemCount - 1 do
                    begin
                      offset := TPSTypeRec_Array(aType).ArrayType.RealSize * I;
                      LoadVar(LoadStream, Pointer(IPointer(Src) + offset), TPSTypeRec_Array(aType).ArrayType);
                    end;
                  end;
    btArray:      begin
                    LoadStream.Read(elemCount);
                    PSDynArraySetLength(Pointer(Src^), aType, elemCount);
                    for I := 0 to elemCount - 1 do
                    begin
                      offset := TPSTypeRec_Array(aType).ArrayType.RealSize * I;
                      LoadVar(LoadStream, Pointer(IPointer(Src^) + offset), TPSTypeRec_Array(aType).ArrayType);
                    end;
                  end;
    btRecord:     begin
                    LoadStream.Read(elemCount);
                    Assert(elemCount = TPSTypeRec_Record(aType).FieldTypes.Count, 'Script record element count mismatches saved count');
                    for I := 0 to elemCount - 1 do
                    begin
                      offset := Cardinal(TPSTypeRec_Record(aType).RealFieldOffsets[I]);
                      LoadVar(LoadStream, Pointer(IPointer(Src) + offset), TPSTypeRec_Record(aType).FieldTypes[I]);
                    end;
                  end;
    btSet:        begin
                    LoadStream.Read(elemCount);
                    Assert(elemCount = TPSTypeRec_Set(aType).RealSize, 'Script set element count mismatches saved count');
                    LoadStream.Read(Src^, elemCount);
                  end;
    //Already checked and reported as an error in LinkRuntime, no need to crash it here
    //else Assert(False);
  end;
end;


procedure TKMScripting.Load(LoadStream: TKMemoryStream);
var
  I: Integer;
  V: PIFVariant;
begin
  RecreateValidationIssues;

  LoadStream.CheckMarker('Script');
  LoadStream.ReadHugeString(fScriptCode);
  LoadStream.ReadA(fCampaignDataTypeCode);
  gScriptEvents.Load(LoadStream);
  fIDCache.Load(LoadStream);

  if fScriptCode <> '' then
    CompileScript;

  LoadStream.CheckMarker('ScriptVars');
  //Read script variables
  LoadStream.Read(I);
  Assert(I = fExec.GetVarCount, 'Script variable count mismatches saved variables count');
  for I := 0 to fExec.GetVarCount - 1 do
  begin
    V := fExec.GetVarNo(I);
    LoadVar(LoadStream, @PPSVariantData(V).Data, V.FType);
  end;

  //The log path can't be stored in the save since it might be in MapsMP or MapsDL on different clients
  fErrorHandler.ScriptLogFile := ExeDir + ChangeFileExt(gGameParams.MissionFile, SCRIPT_LOG_EXT);
end;


procedure TKMScripting.SyncLoad;
begin
  fIDCache.SyncLoad;
end;


function TKMScripting.GetScriptFilesInfo: TKMScriptFilesCollection;
begin
  Result := fPreProcessor.fScriptFilesInfo;
end;


procedure TKMScripting.LoadCampaignData(LoadStream: TKMemoryStream);
var
  I: Integer;
  V: PIFVariant;
  S: AnsiString;
begin
  //Campaign data format might change. If so, do not load it
  LoadStream.ReadA(S);
  if S <> fCampaignDataTypeCode then
    Exit;

  for I := 0 to fExec.GetVarCount - 1 do
  begin
    V := fExec.GetVarNo(I);
    if V.FType.ExportName = FastUppercase(CAMPAIGN_DATA_TYPE) then
    begin
      LoadVar(LoadStream, @PPSVariantData(V).Data, V.FType);
      Exit;
    end;
  end;
end;


procedure TKMScripting.SaveVar(SaveStream: TKMemoryStream; Src: Pointer; aType: TPSTypeRec);
var
  I: Integer;
  elemCount: Integer;
  offset: Cardinal;
begin
  //See uPSRuntime line 1630 for algo idea
  case aType.BaseType of
    btU8:            SaveStream.Write(tbtu8(Src^)); //Byte, Boolean
    btS8:            SaveStream.Write(tbts8(Src^)); //ShortInt
    btU16:           SaveStream.Write(tbtu16(Src^)); //Word
    btS16:           SaveStream.Write(tbts16(Src^)); //SmallInt
    btU32:           SaveStream.Write(tbtu32(Src^)); //Cardinal / LongInt
    btS32:           SaveStream.Write(tbts32(Src^)); //Integer
    btSingle:        SaveStream.Write(tbtsingle(Src^));
    btString:        SaveStream.WriteA(tbtString(Src^));
    btUnicodeString: SaveStream.WriteW(tbtUnicodeString(Src^));
    btStaticArray:begin
                    elemCount := TPSTypeRec_StaticArray(aType).Size;
                    SaveStream.Write(elemCount);
                    for I := 0 to elemCount - 1 do
                    begin
                      offset := TPSTypeRec_Array(aType).ArrayType.RealSize * I;
                      SaveVar(SaveStream, Pointer(IPointer(Src) + offset), TPSTypeRec_Array(aType).ArrayType);
                    end;
                  end;
    btArray:      begin
                    elemCount := PSDynArrayGetLength(Pointer(Src^), aType);
                    SaveStream.Write(elemCount);
                    for I := 0 to elemCount - 1 do
                    begin
                      offset := TPSTypeRec_Array(aType).ArrayType.RealSize * I;
                      SaveVar(SaveStream, Pointer(IPointer(Src^) + offset), TPSTypeRec_Array(aType).ArrayType);
                    end;
                  end;
    btRecord:     begin
                    elemCount := TPSTypeRec_Record(aType).FieldTypes.Count;
                    SaveStream.Write(elemCount);
                    for I := 0 to elemCount - 1 do
                    begin
                      offset := Cardinal(TPSTypeRec_Record(aType).RealFieldOffsets[I]);
                      SaveVar(SaveStream, Pointer(IPointer(Src) + offset), TPSTypeRec_Record(aType).FieldTypes[I]);
                    end;
                  end;
    btSet:        begin
                    elemCount := TPSTypeRec_Set(aType).RealSize;
                    SaveStream.Write(elemCount);
                    SaveStream.Write(Src^, elemCount);
                  end;
    //Already checked and reported as an error in LinkRuntime, no need to crash it here
    //else Assert(False);
  end;
end;


procedure TKMScripting.Save(SaveStream: TKMemoryStream);
var
  I: Integer;
  V: PIFVariant;
begin
  SaveStream.PlaceMarker('Script');

  //Write script code
  SaveStream.WriteHugeString(fScriptCode);
  SaveStream.WriteA(fCampaignDataTypeCode);
  gScriptEvents.Save(SaveStream);
  fIDCache.Save(SaveStream);

  SaveStream.PlaceMarker('ScriptVars');
  //Write script global variables
  SaveStream.Write(fExec.GetVarCount);
  for I := 0 to fExec.GetVarCount - 1 do
  begin
    V := fExec.GetVarNo(I);
    SaveVar(SaveStream, @PPSVariantData(V).Data, V.FType);
  end;
end;


procedure TKMScripting.SaveCampaignData(SaveStream: TKMemoryStream);
var
  I: Integer;
  V: PIFVariant;
begin
  SaveStream.WriteA(fCampaignDataTypeCode);
  for I := 0 to fExec.GetVarCount - 1 do
  begin
    V := fExec.GetVarNo(I);
    if V.FType.ExportName = FastUppercase(CAMPAIGN_DATA_TYPE) then
    begin
      SaveVar(SaveStream, @PPSVariantData(V).Data, V.FType);
      Exit;
    end;
  end;
end;


procedure TKMScripting.UpdateState;
begin
  gScriptEvents.ProcTick;
  fIDCache.UpdateState;
end;


//function TKMScripting.GetCodeLine(aRowNum: Cardinal): AnsiString;
//var
//  strings: TStringList;
//begin
//  strings := TStringList.Create;
//  strings.Text := fScriptCode;
//  Result := AnsiString(strings[aRowNum - 1]);
//  strings.Free;
//end;


//function TKMScripting.FindCodeLine(aRowNumber: Integer; out aFileNamesArr: TKMStringArray; out aRowsArr: TIntegerArray): Integer;
//begin
//  Result := fPreProcessor.fScriptFilesInfo.FindCodeLine(GetCodeLine(aRowNumber), aFileNamesArr, aRowsArr);
//end;


function TKMScripting.GetErrorMessage(aErrorMsg: TPSPascalCompilerMessage): TKMScriptErrorMessage;
begin
  Result := GetErrorMessage(aErrorMsg.ErrorType, EolW + '[' + aErrorMsg.ErrorType + '] ' + aErrorMsg.ShortMessageToString + EolW,
                            aErrorMsg.ModuleName, aErrorMsg.Row, aErrorMsg.Col, aErrorMsg.Pos);
end;


function TKMScripting.GetErrorMessage(const aErrorType, aShortErrorDescription, aModule: String; aRow, aCol, aPos: Integer): TKMScriptErrorMessage;
var
  errorMsg: UnicodeString;
begin
  errorMsg := Format(aShortErrorDescription + 'in ''%s'' at [%d:%d]' + EolW, [aModule, aRow, aCol]);

  // Show game message only for errors. Do not show it for hints or warnings.
  if aErrorType = 'Error' then
    Result.GameMessage := errorMsg
  else
    Result.GameMessage := '';

   Result.LogMessage := errorMsg;
end;


{TKMScriptErrorHandler}
constructor TKMScriptErrorHandler.Create(aOnScriptError: TUnicodeStringEvent);
begin
  inherited Create;

  fOnScriptError := aOnScriptError;
  Clear;
end;


procedure TKMScriptErrorHandler.AppendError(aError: TKMScriptErrorMessage);
begin
  fErrorString.GameMessage := fErrorString.GameMessage + aError.GameMessage;
  fErrorString.LogMessage := fErrorString.LogMessage + aError.LogMessage;
end;


procedure TKMScriptErrorHandler.AppendHint(const aHint: TKMScriptErrorMessage);
begin
  fHintsString.GameMessage := fHintsString.GameMessage + aHint.GameMessage;
  fHintsString.LogMessage := fHintsString.LogMessage + aHint.LogMessage;
end;


procedure TKMScriptErrorHandler.AppendWarning(const aWarning: TKMScriptErrorMessage);
begin
  fWarningsString.GameMessage := fWarningsString.GameMessage + aWarning.GameMessage;
  fWarningsString.LogMessage := fWarningsString.LogMessage + aWarning.LogMessage;
end;


procedure TKMScriptErrorHandler.AppendErrorStr(const aErrorString: String; const aDetailedErrorString: String = '');
begin
  fErrorString.GameMessage := fErrorString.GameMessage + aErrorString;
  fErrorString.LogMessage := fErrorString.LogMessage + aDetailedErrorString;
end;


procedure TKMScriptErrorHandler.AppendWarningStr(const aWarningString: String; const aDetailedWarningString: String = '');
begin
  fWarningsString.GameMessage := fWarningsString.GameMessage + aWarningString;
  fWarningsString.LogMessage := fWarningsString.LogMessage + aDetailedWarningString;
end;


function TKMScriptErrorHandler.AppendErrorPrefix(const aPrefix: UnicodeString; var aError: TKMScriptErrorMessage): TKMScriptErrorMessage;
begin
  // Append prefix only for non-empty messages
  if aError.GameMessage <> '' then
    aError.GameMessage := aPrefix + aError.GameMessage;

  if aError.LogMessage <> '' then
    aError.LogMessage := aPrefix + aError.LogMessage;
  Result := aError;
end;


function TKMScriptErrorHandler.HasErrors: Boolean;
begin
  Result := fErrorString.GameMessage <> '';
end;


function TKMScriptErrorHandler.HasWarnings: Boolean;
begin
  Result := fWarningsString.GameMessage <> '';
end;


function TKMScriptErrorHandler.HasHints: Boolean;
begin
  Result := fHintsString.GameMessage <> '';
end;


procedure TKMScriptErrorHandler.HandleErrors;
begin
  HandleScriptError(seCompileError, AppendErrorPrefix('Script compile errors:' + EolW, fErrorString));
  HandleScriptError(seCompileWarning, AppendErrorPrefix('Script compile warnings:' + EolW, fWarningsString));
  HandleScriptError(seCompileHint, AppendErrorPrefix('Script compile hints:' + EolW, fHintsString));
end;


procedure TKMScriptErrorHandler.Clear;
begin
  fErrorString.GameMessage := '';
  fErrorString.LogMessage := '';
  fWarningsString.GameMessage := '';
  fWarningsString.LogMessage := '';
  fHintsString.GameMessage := '';
  fHintsString.LogMessage := '';
end;


procedure TKMScriptErrorHandler.SetScriptLogFile(const aScriptLogFile: UnicodeString);
begin
  fScriptLogFile := aScriptLogFile;
  if not DirectoryExists(ExtractFilePath(fScriptLogFile)) then
    fScriptLogFile := '';
end;


procedure TKMScriptErrorHandler.HandleScriptError(aType: TKMScriptErrorType; const aError: TKMScriptErrorMessage);
begin
  HandleScriptErrorString(aType, aError.GameMessage, aError.LogMessage);
end;


procedure TKMScriptErrorHandler.HandleScriptErrorString(aType: TKMScriptErrorType; const aErrorString: UnicodeString;
                                                        const aDetailedErrorString: UnicodeString = '');
var
  fl: TextFile;
  logErrorMsg, errorStr: UnicodeString;
begin
  if BLOCK_FILE_WRITE then Exit;

  if aDetailedErrorString <> '' then
    logErrorMsg := aDetailedErrorString
  else
    logErrorMsg := aErrorString;

  if logErrorMsg = '' then //No errors occur
    Exit;

  gLog.AddTime('Script: ' + logErrorMsg); //Always log the error to global game log

  //Log to map specific log file
  if fScriptLogFile <> '' then
  begin
    AssignFile(fl, fScriptLogFile);
    if not FileExists(fScriptLogFile) then
      Rewrite(fl)
    else
      if GetFileSize(fScriptLogFile) > MAX_LOG_SIZE then
      begin
        //Reset the log if it gets too long so poorly written scripts don't waste disk space
        Rewrite(fl);
        WriteLn(fl, Format('%23s   %s', [FormatDateTime('yyyy/mm/dd hh:nn:ss.zzz', Now),
                'Log file exceeded ' + IntToStr(MAX_LOG_SIZE) + ' bytes and was reset']));
      end
      else
        Append(fl);
    WriteLn(fl, Format('%23s   %s', [FormatDateTime('yyyy/mm/dd hh:nn:ss.zzz', Now), logErrorMsg]));
    CloseFile(fl);
  end;

  errorStr := StringReplace(aErrorString, EolW, '|', [rfReplaceAll]);

  //Display compile errors in-game
  if (aType in [seCompileError, sePreprocessorError]) and Assigned(fOnScriptError) then
    fOnScriptError(errorStr);

  //Serious runtime errors should be shown to the player
  if aType in [seException] then
  begin
    //Only show the first message in-game to avoid spamming the player
    if not fHasErrorOccured and Assigned(fOnScriptError) then
      fOnScriptError('Error(s) have occured in the mission script. ' +
                     'Please check the log file for further details. First error:|' + errorStr);
    fHasErrorOccured := True;
  end;
end;


{TKMScriptingPreProcessor}
constructor TKMScriptingPreProcessor.Create;
var
  onScriptError: TUnicodeStringEvent;
begin
  onScriptError := nil;
  Create(onScriptError);
end;


constructor TKMScriptingPreProcessor.Create(aOnScriptError: TUnicodeStringEvent);
begin
  Create(aOnScriptError, TKMScriptErrorHandler.Create(aOnScriptError));
  fDestroyErrorHandler := True;
end;


constructor TKMScriptingPreProcessor.Create(aOnScriptError: TUnicodeStringEvent; aErrorHandler: TKMScriptErrorHandler);
begin
  inherited Create;

  fPSPreProcessor := TPSPreProcessor.Create;
  fPSPreProcessor.OnNeedFile := ScriptOnNeedFile;
  fPSPreProcessor.OnProcessDirective := ScriptOnProcessDirective;

  fScriptFilesInfo := TKMScriptFilesCollection.Create;

  fErrorHandler := aErrorHandler;
  fDestroyErrorHandler := False;
end;


destructor TKMScriptingPreProcessor.Destroy;
begin
  FreeAndNil(fScriptFilesInfo);
  //Error Handler could be destroyed already
  if fDestroyErrorHandler then
    FreeAndNil(fErrorHandler);

  FreeAndNil(fPSPreProcessor);
  inherited;
end;


procedure TKMScriptingPreProcessor.BeforePreProcess(const aMainFileName: UnicodeString; const aMainFileText: AnsiString);
var
  CSP: TKMCustomScriptParam;
begin
  fScriptFilesInfo.fMainFilePath := ExtractFilePath(aMainFileName);
  fScriptFilesInfo.fMainFileInfo.FullFilePath := aMainFileName;
  fScriptFilesInfo.fMainFileInfo.FileName := ExtractFileName(aMainFileName);
  fScriptFilesInfo.fMainFileInfo.FileText := aMainFileText;

  //Reset custom script parameters
  for CSP := Low(TKMCustomScriptParam) to High(TKMCustomScriptParam) do
  begin
    fCustomScriptParams[CSP].Added := False;
    fCustomScriptParams[CSP].Data := '';
  end;
end;


function TKMScriptingPreProcessor.GetCustomScriptParamData(aParam: TKMCustomScriptParam): TKMCustomScriptParamData;
begin
  Result := fCustomScriptParams[aParam];
end;


procedure TKMScriptingPreProcessor.AfterPreProcess;
begin
  SetLength(fScriptFilesInfo.fIncluded, fScriptFilesInfo.fIncludedCnt);
end;


function TKMScriptingPreProcessor.ScriptMightChangeAfterPreProcessing: Boolean;
begin
  Result := (fScriptFilesInfo.fIncludedCnt <> 0) or fScriptFilesInfo.fHasDefDirectives;
end;


// Check if main script file is a campaign mission
function TKMScriptingPreProcessor.IsCampaignMissionScript: Boolean;
begin
  if gGameParams <> nil then
    Exit(gGameParams.IsCampaign)
  else
    // We could run pre processor from script validator, f.e., so we will have no gGameParams initialized

    // fScriptFilesInfo.fMainFilePath could have absolute or relative path
    // ScriptValidator ExeDir could lead to some different folder
    Result :=  (Pos(ExeDir + CAMPAIGNS_FOLDER_NAME, fScriptFilesInfo.fMainFilePath) = 1)
            or (Pos(CAMPAIGNS_FOLDER_NAME, fScriptFilesInfo.fMainFilePath) = 1)
            // Use PathDelims for script validator, to avoid abusing maps with names like 'Better_then_any_Campaigns_map' which contains 'Campaigns' string
            or (Pos(PathDelim + CAMPAIGNS_FOLDER_NAME + PathDelim, fScriptFilesInfo.fMainFilePath) > 0);
end;


function TKMScriptingPreProcessor.PreProcessFile(const aFileName: UnicodeString): Boolean;
var
  scriptCode: AnsiString;
begin
  Result := PreProcessFile(aFileName, scriptCode);
end;


function TKMScriptingPreProcessor.PreProcessFile(const aFileName: UnicodeString; var aScriptCode: AnsiString): Boolean;
var
  mainScriptCode: AnsiString;
begin
  Result := False;
  fErrorHandler.ScriptLogFile := ChangeFileExt(aFileName, SCRIPT_LOG_EXT);

  if not FileExists(aFileName) then
  begin
    gLog.AddNoTime(aFileName + ' was not found. It is okay for mission to have no dynamic scripts.');
    Exit;
  end;

  mainScriptCode := ReadTextA(aFileName);

  fPSPreProcessor.MainFileName := AnsiString(aFileName);
  fPSPreProcessor.MainFile := mainScriptCode;
  BeforePreProcess(aFileName, mainScriptCode);
  try
    fPSPreProcessor.PreProcess(fPSPreProcessor.MainFileName, aScriptCode);
    AfterPreProcess;
    Result := True; // If PreProcess has been done succesfully
  except
    on E: Exception do
    begin
      fErrorHandler.HandleScriptErrorString(sePreprocessorError, 'Script preprocessing errors:' + EolW + E.Message);
      if fValidationIssues <> nil then
        fValidationIssues.AddError(0, 0, '', 'Script preprocessing errors:' + EolW + E.Message);
    end;
  end;
end;


procedure TKMScriptingPreProcessor.ScriptOnProcessDirective(Sender: TPSPreProcessor; Parser: TPSPascalPreProcessorParser; const Active: Boolean;
                                                            const DirectiveName, DirectiveParam: tbtString; var aContinue: Boolean);
const
  CUSTOM_EVENT_DIRECTIVE = 'EVENT';
  CUSTOM_CONSOLE_COMMAND_DIRECTIVE = 'COMMAND';
  CUSTOM_CONSOLE_COMMAND_DIRECTIVE_SHORT = 'CMD';
  CUSTOM_TH_TROOP_COST_DIRECTIVE = 'CUSTOM_TH_TROOP_COST';
  CUSTOM_MARKET_GOLD_PRICE_DIRECTIVE = 'CUSTOM_MARKET_GOLD_PRICE_X';

  function AllowGameUpdate: Boolean;
  begin
    Result := ((gGameParams <> nil) and not gGameParams.IsMapEditor)
              or ((gGameParams = nil) and (gScripting <> nil));
  end;

  procedure LoadCustomEventDirectives;
  var
    errorStr: UnicodeString;
    eventType: Integer;
    directiveParamSL: TStringList;
  begin
    //Load custom event handlers
    if UpperCase(DirectiveName) = UpperCase(CUSTOM_EVENT_DIRECTIVE) then
    begin
      aContinue := False; //Custom directive should not be proccesed any further by pascal script preprocessor, as it will cause an error

      //Do not do anything for while in MapEd
      //But we have to allow to preprocess file, as preprocessed file used for CRC calc in MapEd aswell
      //gGame could be nil here, but that does not change final CRC, so we can Exit
      if not AllowGameUpdate then Exit;

      try
        directiveParamSL := TStringList.Create;
        try
          StringSplit(DirectiveParam, ':', directiveParamSL);
          eventType := GetEnumValue(TypeInfo(TKMScriptEventType), Trim(directiveParamSL[0]));

          if eventType = -1 then
          begin
            fErrorHandler.AppendErrorStr(Format('Unknown directive ''%s'' at [%d:%d]' + sLineBreak,
                                                [Trim(directiveParamSL[0]), Parser.Row, Parser.Col]));
            if fValidationIssues <> nil then
              fValidationIssues.AddError(Parser.Row, Parser.Col, Trim(directiveParamSL[0]), 'Unknown directive');
          end else
            gScriptEvents.AddEventHandlerName(TKMScriptEventType(eventType), AnsiString(Trim(directiveParamSL[1])));
        finally
          directiveParamSL.Free;
        end;
      except
        on E: Exception do
          begin
            errorStr := Format('Error loading directive ''%s'' at [%d:%d]', [Parser.Token, Parser.Row, Parser.Col]);
            fErrorHandler.AppendErrorStr(errorStr, errorStr + ' Exception: ' + E.Message
              {$IFDEF WDC} + sLineBreak + E.StackTrace {$ENDIF});
            if fValidationIssues <> nil then
              fValidationIssues.AddError(Parser.Row, Parser.Col, Parser.Token, 'Error loading directive');
          end;
      end;
    end;
  end;

  procedure LoadCustomConsoleCommands;
  var
    cmdName, procName: AnsiString;
    errorStr: UnicodeString;
    SL: TStringList;
  begin
    //Load custom event handlers
    if (UpperCase(DirectiveName) = UpperCase(CUSTOM_CONSOLE_COMMAND_DIRECTIVE))
      or (UpperCase(DirectiveName) = UpperCase(CUSTOM_CONSOLE_COMMAND_DIRECTIVE_SHORT)) then
    begin
      aContinue := False; //Custom directive should not be proccesed any further by pascal script preprocessor, as it will cause an error

      //Do not do anything for while in MapEd
      //But we have to allow to preprocess file, as preprocessed file used for CRC calc in MapEd aswell
      //gGame could be nil here, but that does not change final CRC, so we can Exit
      if not AllowGameUpdate then Exit;

      try
        SL := TStringList.Create;
        try
          StringSplit(DirectiveParam, ':', SL);
          cmdName := AnsiString(Trim(SL[0]));
          procName := AnsiString(Trim(SL[1]));

          gScriptEvents.AddConsoleCommand(cmdName, procName);
        finally
          FreeAndNil(SL);
        end;
      except
        on E: Exception do
          begin
            errorStr := Format('Error loading command ''%s'' at [%d:%d]', [Parser.Token, Parser.Row, Parser.Col]);
            fErrorHandler.AppendErrorStr(errorStr, errorStr + ' Exception: ' + E.Message
              {$IFDEF WDC} + sLineBreak + E.StackTrace {$ENDIF});
            if fValidationIssues <> nil then
              fValidationIssues.AddError(Parser.Row, Parser.Col, Parser.Token, 'Error loading command');
          end;
      end;
    end;
  end;

  procedure LoadCustomTHTroopCost;
  var
    I, troopCost: Integer;
    errorStr: UnicodeString;
    directiveParamSL: TStringList;
    hasError: Boolean;
    thTroopCost: array[Low(TH_TROOP_COST)..High(TH_TROOP_COST)] of Integer;
  begin
    if UpperCase(DirectiveName) = UpperCase(CUSTOM_TH_TROOP_COST_DIRECTIVE) then
    begin
      aContinue := False; //Custom directive should not be proccesed any further by pascal script preprocessor, as it will cause an error

      try
        directiveParamSL := TStringList.Create;
        try
          StringSplit(DirectiveParam, ',', directiveParamSL);

          hasError := False;
          if directiveParamSL.Count <> Length(thTroopCost) then
          begin
            hasError := True;
            fErrorHandler.AppendErrorStr(Format('Directive ''%s'' has wrong number of parameters: expected %d, actual: %d. At [%d:%d]' + sLineBreak,
                                                [CUSTOM_TH_TROOP_COST_DIRECTIVE, Length(thTroopCost), directiveParamSL.Count,
                                                 Parser.Row, Parser.Col]));
            if fValidationIssues <> nil then
              fValidationIssues.AddError(Parser.Row, Parser.Col, CUSTOM_TH_TROOP_COST_DIRECTIVE,
                                         Format('Wrong number of parameters: expected %d, actual: %d',
                                                [Length(thTroopCost), directiveParamSL.Count]));
          end;

          for I := Low(thTroopCost) to High(thTroopCost) do
            if TryStrToInt(directiveParamSL[I], troopCost) then
              thTroopCost[I] := EnsureRange(troopCost, 1, 255)
            else begin
              hasError := True;
              fErrorHandler.AppendErrorStr(Format('Directive ''%s'' wrong parameter: [%s] is not a number. At [%d:%d]' + sLineBreak,
                                                  [CUSTOM_TH_TROOP_COST_DIRECTIVE, directiveParamSL[I], Parser.Row, Parser.Col]));
              if fValidationIssues <> nil then
                fValidationIssues.AddError(Parser.Row, Parser.Col, CUSTOM_TH_TROOP_COST_DIRECTIVE,
                                           Format('Wrong directive parameter: [%s] is not a number', [directiveParamSL[I]]));
            end;

          if not hasError then
          begin
            fCustomScriptParams[cspTHTroopCosts].Added := True;
            fCustomScriptParams[cspTHTroopCosts].Data := DirectiveParam;
          end else
            Exit;

          //Do not do anything for while in MapEd
          //But we have to allow to preprocess file, as preprocessed file used for CRC calc in MapEd aswell
          //gGame could be nil here, but that does not change final CRC, so we can Exit
          if not AllowGameUpdate then Exit;

          //Update actual troop cost
          for I := Low(TH_TROOP_COST) to High(TH_TROOP_COST) do
            TH_TROOP_COST[I] := thTroopCost[I];

        finally
          directiveParamSL.Free;
        end;
      except
        on E: Exception do
          begin
            errorStr := Format('Error loading directive ''%s'' at [%d:%d]', [Parser.Token, Parser.Row, Parser.Col]);
            fErrorHandler.AppendErrorStr(errorStr, errorStr + ' Exception: ' + E.Message
              {$IFDEF WDC} + sLineBreak + E.StackTrace {$ENDIF});
            if fValidationIssues <> nil then
              fValidationIssues.AddError(Parser.Row, Parser.Col, Parser.Token, 'Error loading directive');
          end;
      end;
    end;
  end;

  procedure LoadCustomMarketGoldPrice;
  var
    errorStr: UnicodeString;
    directiveParamSL: TStringList;
    hasError: Boolean;
    goldOrePriceX, goldPriceX: Single;
  begin
    if UpperCase(DirectiveName) = UpperCase(CUSTOM_MARKET_GOLD_PRICE_DIRECTIVE) then
    begin
      aContinue := False; //Custom directive should not be proccesed any further by pascal script preprocessor, as it will cause an error

      try
        directiveParamSL := TStringList.Create;
        try
          StringSplit(DirectiveParam, ',', directiveParamSL);

          if directiveParamSL.Count <> 2 then
          begin
            fErrorHandler.AppendErrorStr(Format('Directive ''%s'' has wrong number of parameters: expected 2, actual: %d. At [%d:%d]' + sLineBreak,
                                                [CUSTOM_MARKET_GOLD_PRICE_DIRECTIVE, directiveParamSL.Count, Parser.Row, Parser.Col]));
            if fValidationIssues <> nil then
              fValidationIssues.AddError(Parser.Row, Parser.Col, CUSTOM_MARKET_GOLD_PRICE_DIRECTIVE,
                                         'Wrong number of parameters: expected 2, actual: ' + IntToStr(directiveParamSL.Count));
          end;

          hasError := False;
            if TryStrToFloat(StringReplace(directiveParamSL[0], '.', ',', [rfReplaceAll]), goldOrePriceX)
              and TryStrToFloat(StringReplace(directiveParamSL[1], '.', ',', [rfReplaceAll]), goldPriceX) then
            begin
              goldOrePriceX := EnsureRange(goldOrePriceX, 0.1, 10);
              goldPriceX := EnsureRange(goldPriceX, 0.1, 10);
            end else begin
              hasError := True;
              fErrorHandler.AppendErrorStr(Format('Directive ''%s'' has not a number parameter: [%s]. At [%d:%d]' + sLineBreak,
                                                  [CUSTOM_MARKET_GOLD_PRICE_DIRECTIVE, DirectiveParam, Parser.Row, Parser.Col]));
              if fValidationIssues <> nil then
                fValidationIssues.AddError(Parser.Row, Parser.Col, CUSTOM_MARKET_GOLD_PRICE_DIRECTIVE,
                                           'Wrong directive parameters type, Integer required');
            end;

          if not hasError then
          begin
            fCustomScriptParams[cspMarketGoldPrice].Added := True;
            fCustomScriptParams[cspMarketGoldPrice].Data :=
              Format('%s: x%s %s: x%s', [gRes.Wares[wtGoldOre].Title, FormatFloat('#0.#', goldOrePriceX),
                                         gRes.Wares[wtGold].Title,    FormatFloat('#0.#', goldPriceX)]);
          end else
            Exit;

          //Do not do anything for while in MapEd
          //But we have to allow to preprocess file, as preprocessed file used for CRC calc in MapEd aswell
          //gGame could be nil here, but that does not change final CRC, so we can Exit
          if not AllowGameUpdate then Exit;

          //Update actual troop cost
          gRes.Wares[wtGoldOre].MarketPriceMultiplier := goldOrePriceX;
          gRes.Wares[wtGold].MarketPriceMultiplier := goldPriceX;

        finally
          directiveParamSL.Free;
        end;
      except
        on E: Exception do
          begin
            errorStr := Format('Error loading directive ''%s'' at [%d:%d]', [Parser.Token, Parser.Row, Parser.Col]);
            fErrorHandler.AppendErrorStr(errorStr, errorStr + ' Exception: ' + E.Message
              {$IFDEF WDC} + sLineBreak + E.StackTrace {$ENDIF});
            if fValidationIssues <> nil then
              fValidationIssues.AddError(Parser.Row, Parser.Col, Parser.Token, 'Error loading directive');
          end;
      end;
    end;
  end;

begin
  // Most of the scripts do not have directives.
  // save in fHasDefDirectives, when script do have IFDEF or IFNDEF directive, which might change script code after pre-processing
  if not fScriptFilesInfo.fHasDefDirectives
    and Active
    and ((DirectiveName = 'IFDEF')
      or (DirectiveName = 'IFNDEF')
      or (DirectiveName = 'ELSE')
      or (DirectiveName = 'DEFINE')
      or (DirectiveName = 'UNDEF')) then
    fScriptFilesInfo.fHasDefDirectives := True;

  LoadCustomEventDirectives;
  LoadCustomConsoleCommands;
  LoadCustomTHTroopCost;
  LoadCustomMarketGoldPrice;
end;


function TKMScriptingPreProcessor.ScriptOnNeedFile(Sender: TPSPreProcessor; const aCallingFileName: AnsiString; var aFileName, aOutput: AnsiString): Boolean;
var
  path, fileName, fileExt, errorStr: string;
  inclFile: AnsiString;
  includedScriptFileInfo: TKMScriptFileInfo;
  isCmpScript: Boolean;
begin
  Result := False;

  // Always should check main script folder first, instead of using aCallingFileName, since it could be invoked from included script
  // We want to always allow to overwrite included file from main script folder                           \
  //
  // So f.e. main.script includes A.script in the Campaign's Scripts folder
  // A.script includes B.script, which is also in the Campaign's Scripts folder
  // But if main script folder contains other B.script, then it should be used instead of Scripts/B.script
  path := fScriptFilesInfo.fMainFilePath;

  inclFile := AnsiString(Trim(aFileName));

  fileName := path + inclFile;

  isCmpScript := IsCampaignMissionScript;

  fileExt := ExtractFileExt(fileName);
  // Check included file extension
  if fileExt <> EXT_FILE_SCRIPT_DOT then
  begin
    errorStr := Format('Error including ''%s'' from ''%s'':|wrong extension: ''%s''',
                       [inclFile, ExtractFileName(aCallingFileName), fileExt]);
    fErrorHandler.AppendErrorStr(errorStr, errorStr);
    raise Exception.Create(errorStr); // We should raise Exception here, to stop Including process by PascalScript
  end;

  // Do not allow to include campaigndata.script, since we can include scripts from the root folder now
  if inclFile = CAMPAIGN_DATA_FILENAME + EXT_FILE_SCRIPT_DOT then
  begin
    errorStr := Format('Error including ''%s'' from ''%s'':|filename ''%s'' is reserved for campaign data',
                       [inclFile, ExtractFileName(aCallingFileName), CAMPAIGN_DATA_FILENAME + EXT_FILE_SCRIPT_DOT]);
    fErrorHandler.AppendErrorStr(errorStr, errorStr);
    raise Exception.Create(errorStr); // We should raise Exception here, to stop Including process by PascalScript
  end;

  // Check if file has some path in it
  if ExtractFilePath(fileName) <> fScriptFilesInfo.fMainFilePath then
  begin
    if isCmpScript then
      errorStr := Format('Error including ''%s'' from ''%s'':|included script files should be in the same folder as main script file ' +
                         'or in the campaign folder: ''%s''',
                         [fileName, ExtractFileName(aCallingFileName), CAMPAIGN_SCRIPTS_FOLDER_NAME])
    else
      errorStr := Format('Error including ''%s'' from ''%s'':|included script files should be in the same folder as main script file',
                         [fileName, ExtractFileName(aCallingFileName)]);
    fErrorHandler.AppendErrorStr(errorStr, errorStr);
    raise Exception.Create(errorStr); // We should raise Exception here, to stop Including process by PascalScript
  end;

  aFileName := AnsiString(fileName);

  // If file not found in the main script folder and main script is from campaign mission (checked via folder path),
  // then we should try to find this script in the 'Scripts' folder inside campaign main folder
  if isCmpScript and not FileExists(aFileName) then
  begin
    fileName := AnsiString(path) + '..' + PathDelim + CAMPAIGN_SCRIPTS_FOLDER_NAME + PathDelim + inclFile;

    // If not found, then set aFileName to an initial name
    if FileExists(fileName) then
      aFileName := AnsiString(fileName);
  end;

  if FileExists(aFileName) then
  begin
    aOutput := ReadTextA(aFileName);

    includedScriptFileInfo.FullFilePath := aFileName;
    includedScriptFileInfo.FileName := ExtractFileName(aFileName);
    includedScriptFileInfo.FileText := aOutput;

    fScriptFilesInfo.AddIncludeInfo(includedScriptFileInfo);

    Result := True;
  end;
end;


{TKMScriptFilesCollection}
constructor TKMScriptFilesCollection.Create;
begin
  fIncludedCnt := 0;
  fHasDefDirectives := False;
  SetLength(fIncluded, 8);
end;


procedure TKMScriptFilesCollection.AddIncludeInfo(const aIncludeInfo: TKMScriptFileInfo);
begin
  if Length(fIncluded) >= fIncludedCnt then
    SetLength(fIncluded, fIncludedCnt + 8);

  fIncluded[fIncludedCnt] := aIncludeInfo;
  Inc(fIncludedCnt);
end;


function TKMScriptFilesCollection.GetIncluded(aIndex: Integer): TKMScriptFileInfo;
begin
  Result := fIncluded[aIndex];
end;


//
////Try to find line of code in all script files
////Returns number of occurences
//function TKMScriptFilesCollection.FindCodeLine(const aLine: AnsiString; out aFileNamesArr: TKMStringArray;
//                                               out aRowsArr: TIntegerArray): Integer;
//
//  procedure AddFoundLineInfo(var aFoundCnt: Integer; const aFileNameFound: String; aRowFound: Integer);
//  begin
//    if (aFoundCnt >= Length(aFileNamesArr))
//      or (aFoundCnt >= Length(aRowsArr)) then
//    begin
//      SetLength(aFileNamesArr, aFoundCnt + 8);
//      SetLength(aRowsArr, aFoundCnt + 8);
//    end;
//
//    aFileNamesArr[aFoundCnt] := aFileNameFound;
//    aRowsArr[aFoundCnt] := aRowFound;
//
//    Inc(aFoundCnt);
//  end;
//
//  procedure FindLine(var aFoundCnt: Integer; const aScriptFileInfo: TKMScriptFileInfo; var aStrings: TStringList);
//  var
//    I: Integer;
//  begin
//    aStrings.Clear;
//    aStrings.Text := aScriptFileInfo.FileText;
//
//    //Find all occurences of aLine in FileText
//    for I := 0 to aStrings.Count - 1 do
//      if aStrings[I] = aLine then
//        AddFoundLineInfo(aFoundCnt, aScriptFileInfo.FileName, I + 1);
//  end;
//
//var
//  strings: TStringList;
//  I, aFoundCnt: Integer; // Same name as a parameter?
//begin
//  strings := TStringList.Create; // Create TStringList only once for all files
//
//  aFoundCnt := 0;
//  //Find in main script file first
//  FindLine(aFoundCnt, fMainFileInfo, strings);
//
//  for I := 0 to fIncludedCnt - 1 do
//    //then find in included script files
//    FindLine(aFoundCnt, fIncluded[I], strings);
//
//  Result := aFoundCnt;
//  strings.Free;
//end;


end.
