unit KM_GameInputProcess;
{$I KaM_Remake.inc}
interface
uses
  Generics.Collections,
  KM_Units, KM_UnitGroup,
  KM_Houses, KM_HouseWoodcutters, KM_Hand,
  KM_ScriptingConsoleCommands,
  KM_CommonClasses, KM_CommonTypes, KM_Defaults, KM_Points, KM_WorkerThread,
  KM_HandTypes,
  KM_UnitGroupTypes,
  KM_GameTypes,
  KM_ResTypes;

{ A. This unit takes and adjoins players input from TGame and TGamePlayInterfaces clicks and keys
  Then passes it on to game events.
  E.g. there are 2 ways player can place an order to selected Warrior:
  1. Click on map
  2. Click on minimap

  B. And most important, it accumulates and feeds player input to the game.
  Thus making possible to:
   - record gameplay
   - playback replays
   - send input through LAN to make multiplayer games

  This is a polymorphic unit which is only used as the parent of TGameInputProcess_Single for single
  player or TGameInputProcess_Multi for multiplayer
  It contains a few common methods such as replays as well as abstract methods for the child classes to handle.
  Most importantly it converts all Cmd____ methods called by TGamePlayInterfaces into one procedure
  ProcessCommandFromPlayer. Single and Multi then use this according to their needs.
  Replays are stored and managed here, hidden from the child classes by private. They add new replay
  commands with StoreCommand, and in gipReplaying state commands are executed on Tick
  }

const
  MAX_PARAMS = 4; //There are maximum of 4 integers passed along with a command


type
  TKMGIPReplayState = (gipRecording, gipReplaying);

  TKMGameInputCommandType = (
    gicNone,
    //I.      Army commands, only warriors (TKMUnitWarrior, OrderInfo)
    gicArmyFeed,
    gicArmySplit,
    gicArmySplitSingle,
    gicArmyLink,
    gicArmyAttackUnit,
    gicArmyAttackHouse,
    gicArmyHalt,
    gicArmyFormation,    //Formation commands
    gicArmyWalk,         //Walking
    gicArmyStorm,        //StormAttack

    //II. Unit commands
    gicUnitDismiss,
    gicUnitDismissCancel,

    //III.     Building/road plans (what to build and where)
    gicBuildToggleFieldPlan,
    gicBuildRemoveFieldPlan, //Removal of a plan
    gicBuildRemoveHouse,     //Removal of house
    gicBuildRemoveHousePlan, //Removal of house plan
    gicBuildHousePlan,       //Build HouseType

    //IV.    House repair/delivery/orders (TKMHouse, Toggle(repair, delivery, orders))
    gicHouseRepairToggle,
    gicHouseDeliveryModeNext,
    gicHouseDeliveryModePrev,
    gicHouseClosedForWorkerTgl,         //Toggle house state for worker - vacate or occupy
    gicHouseOrderProduct,               //Place an order to manufacture warfare
    gicHouseMarketFrom,                 //Select wares to trade in marketplace
    gicHouseMarketTo,                   //Select wares to trade in marketplace
    gicHouseWoodcutterMode,             //Switch the woodcutter mode
    gicHouseArmorWSDeliveryToggle,      //Toggle resourse delivery to armor workshop
    gicHouseStoreNotAcceptFlag,         //Control wares delivery to store
    gicHouseStoreNotAcceptAllFlag,      //Control all wares delivery to store
    gicHStoreNotAllowTakeOutFlag,       //Control wares delivery from store
    gicHStoreNotAllowTakeOutAllFlag,    //Control all wares delivery from store
    gicHouseSchoolTrain,                //Place an order to train citizen
    gicHouseSchoolTrainChOrder,         //Change school training order
    gicHouseSchoolTrainChLastUOrder,    //Change school training order for last unit in queue
    gicHouseBarracksAcceptFlag,         //Control wares delivery to barracks
    gicHouseBarracksAcceptAllFlag,      //Control all wares delivery to barracks
    gicHBarracksNotAllowTakeOutFlag,    //Control wares delivery from barracks
    gicHBarracksNotAllowTakeOutAllFlag, //Control all wares delivery from barracks
    gicHBarracksAcceptRecruitsTgl,      //Toggle are recruits allowed to enter barracks or not
    gicHouseBarracksEquip,              //Place an order to train warrior in the Barracks
    gicHouseBarracksRally,              //Set the rally point for the Barracks
    gicHouseTownHallEquip,              //Place an order to train warrior in the TownHall
    gicHouseTownHallRally,              //Set the rally point for the TownHall
    gicHouseTownHallMaxGold,            //Set TownHall MaxGold value
    gicHouseRemoveTrain,                //Remove unit being trained from School
    gicHouseWoodcuttersCutting,         //Set the cutting point for the Woodcutters

    //V.     Delivery ratios changes (and other game-global settings)
    gicWareDistributionChange,   //Change of distribution for 1 ware
    gicWareDistributions,        //Update distributions for all wares at ones

    //VI.      Game changes
    gicGameAlertBeacon,          //Signal alert (beacon)
    gicGamePause,
    gicGameSpeed,
    gicGameAutoSave,
    gicGameAutoSaveAfterPT,
    gicGameSaveReturnLobby,
    gicGameLoadSave,
    gicGameTeamChange,
    gicGameHotkeySet,        //Hotkeys are synced for MP saves (UI keeps local copy to avoid GIP delays)
    gicGameMessageLogRead,   //Player marks a message in their log as read
    gicGameMessageListRead,  //Player opens message list
    gicGamePlayerChange,     //Players can be changed to AI when loading a save and player name could be changed
    gicGamePlayerDefeat,     //Player can be defeated after intentional quit from the game
    gicGamePlayerAllianceSet,//Set player alliance to other player
    gicGamePlayerAddDefGoals,//Set player default goals

    //VII.
    gicScriptConsoleCommand, //Script console command invokation
    gicScriptSoundRemoveRq,  //Request to remove script sound

    //VIII.     Temporary and debug commands
    gicTempAddScout,
    gicTempRevealMap, //Revealing the map can have an impact on the game. Events happen based on tiles being revealed
    gicTempVictory,
    gicTempDefeat,
    gicTempDoNothing  //Used for "aggressive" replays that store a command every tick

    { Optional input }
    //VI.     Viewport settings for replay (location, zoom)
    //VII.    Message queue handling in gameplay interface
    //IX.     Text messages for multiplayer (moved to Networking)
    );

  TKMGameInputCommandPackType = (
    gicpt_NoParams,
    gicpt_Int1,
    gicpt_Int2,
    gicpt_Int3,
    gicpt_Int1Word3,
    gicpt_Int1SmInt3,
    gicpt_AnsiStr1,
    gicpt_Ansi1Int2,
    gicpt_Ansi1Int3,
    // gicpt_Ansi1Int4, // does not work atm, since we limited pack size to 12 bytes atm (GIC_PACKED_DATA_SIZE)
    gicpt_Float,
    gicpt_UniStr1,
    gicpt_Ansi1Uni4,
    gicpt_Date);

const
  BLOCKED_BY_PEACETIME: set of TKMGameInputCommandType = [gicArmySplit, gicArmySplitSingle,
    gicArmyLink, gicArmyAttackUnit, gicArmyAttackHouse, gicArmyHalt,
    gicArmyFormation,  gicArmyWalk, gicArmyStorm, gicHouseBarracksEquip, gicHouseTownHallEquip];

  ALLOWED_AFTER_DEFEAT: set of TKMGameInputCommandType =
    [gicGameAlertBeacon, gicGameSpeed, gicGameAutoSave, gicGameAutoSaveAfterPT, gicGameSaveReturnLobby, gicGameLoadSave,
     gicGameMessageLogRead, gicGameMessageListRead, gicScriptSoundRemoveRq, gicTempDoNothing];

  ALLOWED_IN_CINEMATIC: set of TKMGameInputCommandType =
    [gicGameAlertBeacon, gicGameSpeed, gicGameAutoSave, gicGameAutoSaveAfterPT, gicGameSaveReturnLobby, gicGameMessageLogRead,
     gicGameMessageListRead, gicGamePlayerAllianceSet, gicGamePlayerAddDefGoals, gicScriptSoundRemoveRq, gicTempDoNothing];

  ALLOWED_BY_SPECTATORS: set of TKMGameInputCommandType =
    [gicGameAlertBeacon, gicGameSpeed, gicGameAutoSave, gicGameAutoSaveAfterPT, gicGameSaveReturnLobby, gicGameLoadSave,
     gicGamePlayerChange, gicGamePlayerDefeat, gicTempDoNothing];

  //Those commands should not have random check, because they they are not strictly happen, depends of player config and actions
  //We want to make it possible to reproduce AI city build knowing only seed + map config
  //Autosave and other commands random checks could break it, since every command have its own random check (and KaMRandom call)
  SKIP_RANDOM_CHECKS_FOR: set of TKMGameInputCommandType =
    [gicGameAlertBeacon, gicGameSpeed, gicGameAutoSave, gicGameAutoSaveAfterPT, gicGameSaveReturnLobby, gicGameLoadSave];

  ARMY_ORDER_COMMANDS: set of TKMGameInputCommandType = [
    gicArmyFeed,
    gicArmySplit,
    gicArmySplitSingle,
    gicArmyLink,
    gicArmyAttackUnit,
    gicArmyAttackHouse,
    gicArmyHalt,
    gicArmyFormation,
    gicArmyWalk,
    gicArmyStorm];

  HOUSE_ORDER_COMMANDS: set of TKMGameInputCommandType = [
    gicHouseRepairToggle,
    gicHouseDeliveryModeNext,
    gicHouseDeliveryModePrev,
    gicHouseClosedForWorkerTgl,
    gicHouseOrderProduct,
    gicHouseMarketFrom,
    gicHouseMarketTo,
    gicHouseWoodcutterMode,
    gicHouseStoreNotAcceptFlag,
    gicHouseStoreNotAcceptAllFlag,
    gicHStoreNotAllowTakeOutFlag,
    gicHStoreNotAllowTakeOutAllFlag,
    gicHouseSchoolTrain,
    gicHouseSchoolTrainChOrder,
    gicHouseSchoolTrainChLastUOrder,
    gicHouseBarracksAcceptFlag,
    gicHouseBarracksAcceptAllFlag,
    gicHBarracksNotAllowTakeOutFlag,
    gicHBarracksNotAllowTakeOutAllFlag,
    gicHBarracksAcceptRecruitsTgl,
    gicHouseBarracksEquip,
    gicHouseBarracksRally,
    gicHouseTownHallEquip,
    gicHouseTownHallRally,
    gicHouseTownHallMaxGold,
    gicHouseRemoveTrain,
    gicHouseWoodcuttersCutting];


  COMMAND_PACK_TYPES: array[TKMGameInputCommandType] of TKMGameInputCommandPackType = (
    gicpt_NoParams, // gicNone
    //I.      Army commands, only warriors (TKMUnitWarrior, OrderInfo)
    gicpt_Int1,     // gicArmyFeed
    gicpt_Int1,     // gicArmySplit
    gicpt_Int1,     // gicArmySplitSingle
    gicpt_Int2,     // gicArmyLink
    gicpt_Int2,     // gicArmyAttackUnit
    gicpt_Int2,     // gicArmyAttackHouse
    gicpt_Int1,     // gicArmyHalt
    gicpt_Int3,     // gicArmyFormation
    gicpt_Int1SmInt3,// gicArmyWalk
    gicpt_Int1,     // gicArmyStorm
    //II.      Unit commands
    gicpt_Int1,     // gicUnitDismiss
    gicpt_Int1,     // gicUnitDismissCancel
    //III.     Building/road plans (what to build and where)
    gicpt_Int3,     // gicBuildAddFieldPlan
    gicpt_Int2,     // gicBuildRemoveFieldPlan
    gicpt_Int2,     // gicBuildRemoveHouse
    gicpt_Int2,     // gicBuildRemoveHousePlan
    gicpt_Int3,     // gicBuildHousePlan
    //IV.    House repair/delivery/orders (TKMHouse, Toggle(repair, delivery, orders))
    gicpt_Int1,     // gicHouseRepairToggle
    gicpt_Int1,     // gicHouseDeliveryModeNext
    gicpt_Int1,     // gicHouseDeliveryModePrev
    gicpt_Int1,     // gicHouseClosedForWorkerTgl
    gicpt_Int3,     // gicHouseOrderProduct
    gicpt_Int2,     // gicHouseMarketFrom
    gicpt_Int2,     // gicHouseMarketTo
    gicpt_Int2,     // gicHouseWoodcutterMode
    gicpt_Int2,     // gicHouseArmorWSDeliveryToggle
    gicpt_Int2,     // gicHouseStoreNotAcceptFlag
    gicpt_Int2,     // gicHouseStoreNotAcceptAllFlag
    gicpt_Int2,     // gicHStoreNotAllowTakeOutFlag
    gicpt_Int2,     // gicHStoreNotAllowTakeOutAllFlag
    gicpt_Int3,     // gicHouseSchoolTrain
    gicpt_Int3,     // gicHouseSchoolTrainChOrder
    gicpt_Int2,     // gicHouseSchoolTrainChLastUOrder
    gicpt_Int2,     // gicHouseBarracksAcceptFlag
    gicpt_Int2,     // gicHouseBarracksAcceptAllFlag
    gicpt_Int2,     // gicHBarracksNotAllowTakeOutFlag
    gicpt_Int2,     // gicHBarracksNotAllowTakeOutAllFlag
    gicpt_Int1,     // gicHBarracksAcceptRecruitsTgl
    gicpt_Int3,     // gicHouseBarracksEquip
    gicpt_Int3,     // gicHouseBarracksRally
    gicpt_Int3,     // gicHouseTownHallEquip
    gicpt_Int3,     // gicHouseTownHallRally
    gicpt_Int2,     // gicHouseTownHallMaxGold
    gicpt_Int2,     // gicHouseRemoveTrain
    gicpt_Int3,     // gicHouseWoodcuttersCutting
    //V.     Delivery ratios changes (and other game-global settings)
    gicpt_Int3,     // gicWareDistributionChange
    gicpt_AnsiStr1, // gicWareDistributions
    //VI.      Game changes
    gicpt_Int1SmInt3,// gicGameAlertBeacon
    gicpt_NoParams, // gicGamePause
    gicpt_Float,    // gicGameSpeed
    gicpt_Date,     // gicGameAutoSave
    gicpt_Date,     // gicGameAutoSaveAfterPT
    gicpt_Date,     // gicGameSaveReturnLobby
    gicpt_Int1,     // gicGameLoadSave
    gicpt_Int2,     // gicGameTeamChange
    gicpt_Int2,     // gicGameHotkeySet
    gicpt_Int1,     // gicGameMessageLogRead
    gicpt_Int1,     // gicGameMessageListRead
    gicpt_Ansi1Int3,// gicGamePlayerChange
    gicpt_Int1,     // gicGamePlayerDefeat
    gicpt_Int3,     // gicGamePlayerAllianceSet
    gicpt_Int2,     // gicGameSetDefaultGoals
    //VII.     Scripting commands
    gicpt_Ansi1Uni4,// gicScriptConsoleCommand
    gicpt_Int1,     // gicScriptSoundRemoveRq
    //VIII.    Temporary and debug commands
    gicpt_Int2,     // gicTempAddScout
    gicpt_NoParams, // gicTempRevealMap
    gicpt_NoParams, // gicTempVictory
    gicpt_NoParams, // gicTempDefeat
    gicpt_NoParams  // gicTempDoNothing
  );

const
  GIC_PACKED_DATA_SIZE = 12; //Bytes in the stored GIC command

type
  TKMGameInputCommand = record
    CommandType: TKMGameInputCommandType;
    HandIndex: TKMHandID; //Player for which the command is to be issued. (Needed for multiplayer and other reasons)
    IntParams: array[0..GIC_PACKED_DATA_SIZE div 4] of Integer;
    WordParams: array[0..GIC_PACKED_DATA_SIZE div 2] of Word;
    SmallIntParams: array[0..GIC_PACKED_DATA_SIZE div 2] of SmallInt;
    FloatParam: Single;
    AnsiStrParam: AnsiString;
    UnicodeStrParams: TKMScriptCommandParamsArray;
    DateTimeParam: TDateTime;
    procedure Clear;
  end;

  function IsSelectedObjectCommand(aGIC: TKMGameInputCommandType): Boolean;
  //As TGameInputCommand is no longer fixed size (due to the string) we cannot simply read/write it as a block
  procedure SaveCommandToMemoryStream(const aCommand: TKMGameInputCommand; aMemoryStream: TKMemoryStream); inline;
  procedure LoadCommandFromMemoryStream(out aCommand: TKMGameInputCommand; aMemoryStream: TKMemoryStream); inline;


type
  TKMGicDataPacked = packed record
    function AsAnsiString(aStartByte: Integer): AnsiString;
    function AsUnicodeString(aStartByte: Integer): UnicodeString;
    case Integer of
      0: (Integers:   array [0..(GIC_PACKED_DATA_SIZE div 4)-1] of Integer);
      1: (Words:      array [0..(GIC_PACKED_DATA_SIZE div 2)-1] of Word);
      2: (SmallInts:  array [0..(GIC_PACKED_DATA_SIZE div 2)-1] of SmallInt);
      3: (Bytes:      array [0.. GIC_PACKED_DATA_SIZE-1] of Byte);
      4: (AnsiChars:  array [0.. GIC_PACKED_DATA_SIZE-1] of AnsiChar);
      5: (WideChars:  array [0..(GIC_PACKED_DATA_SIZE div 2)-1] of WideChar);
      6: (Singles:    array [0..(GIC_PACKED_DATA_SIZE div 4)-1] of Single);
      7: (DateT: TDateTime);
  end;

  // Packed GIC commmand - contains Data field with any data type in it
  TKMGameInputCommandPacked = packed record
    CmdType: TKMGameInputCommandType;
    HandID: TKMHandID;
    Data: TKMGicDataPacked;
    procedure ClearData;
    function DataToString: string;
  end;

  TKMStoredGicPackedList = TList<TKMGameInputCommandPacked>;

  TKMStoredGIPCommand = packed record
    Tick: Cardinal;
    Rand: Cardinal; //acts as CRC check
    Command: TKMGameInputCommandPacked;
  end;

  TKMGic2StoredConverter = class
  private
    fAnsiStrBuf: AnsiString;
    fUnicodeStrBuf: UnicodeString;
    fReadyToParseNewCommand: Boolean;
    fWaitForNextCommand: Boolean;
    fStrParamsParsed: Integer;
    procedure Reset;
    procedure CommandParseCompleted;
  public
    constructor Create;
    function ParseNextStoredPackedCommand(const aStoredCmd: TKMGameInputCommandPacked; var aGicCommand: TKMGameInputCommand): Boolean; //aGicCommand should be marked as `var` since we use it as a buffer
    procedure GicToStoredCommands(const aGicCommand: TKMGameInputCommand; aStoredCommands: TKMStoredGicPackedList);
  end;


  TKMGameInputProcess = class
  private
    fCount: Integer;
    fReplayState: TKMGIPReplayState;
    fPlannedCommands: TList<TKMGameInputCommand>; //Commands that were made before game was started (f.e. gicPlayerTypeChange, gicGameSpeed), we plan them for the next tick
  protected
    fStoredCommands: TKMStoredGicPackedList;

    fGic2StoredConverter: TKMGic2StoredConverter;
    fCursor: Integer; //Used only in gipReplaying
    fQueue: array of TKMStoredGIPCommand;
    fOnReplayDesync: TIntegerEvent;

    function MakeEmptyCommand(aGIC: TKMGameInputCommandType): TKMGameInputCommand; inline;
    function MakeCommand(aGIC: TKMGameInputCommandType): TKMGameInputCommand; overload;
    function MakeCommand(aGIC: TKMGameInputCommandType; const aParam1: Integer): TKMGameInputCommand; overload;
    function MakeCommand(aGIC: TKMGameInputCommandType; const aParam1, aParam2: Integer): TKMGameInputCommand; overload;
    function MakeCommand(aGIC: TKMGameInputCommandType; const aParam1, aParam2, aParam3: Integer): TKMGameInputCommand; overload;
    function MakeCommandW(aGIC: TKMGameInputCommandType; const aParam1: Integer; const aParam2, aParam3, aParam4: Word): TKMGameInputCommand;
    function MakeCommandSmI(aGIC: TKMGameInputCommandType; const aParam1: Integer; const aParam2, aParam3, aParam4: SmallInt): TKMGameInputCommand; overload;
    function MakeCommand(aGIC: TKMGameInputCommandType; const aAnsiTxtParam: AnsiString; const aParam1, aParam2: Integer): TKMGameInputCommand; overload;
    function MakeCommand(aGIC: TKMGameInputCommandType; const aAnsiTxtParam: AnsiString; const aParam1, aParam2, aParam3: Integer): TKMGameInputCommand; overload;
    function MakeCommandNoHand(aGIC: TKMGameInputCommandType; const aParam1: Single): TKMGameInputCommand;
    function MakeCommand(aGIC: TKMGameInputCommandType; const aTextParam: AnsiString): TKMGameInputCommand; overload;
    function MakeCommand(aGIC: TKMGameInputCommandType; const aTextParam: UnicodeString): TKMGameInputCommand; overload;
    function MakeCommand(aGIC: TKMGameInputCommandType; const aAnsiTxtParam: AnsiString; const aUniTxtArray: TKMScriptCommandParamsArray): TKMGameInputCommand; overload;
    function MakeCommand(aGIC: TKMGameInputCommandType; aDateTimeParam: TDateTime): TKMGameInputCommand; overload;
    procedure TakeCommand(const aCommand: TKMGameInputCommand);
    procedure DoTakeCommand(const aCommand: TKMGameInputCommand); virtual;
    procedure ExecCommand(const aCommand: TKMGameInputCommand);
    procedure StoreCommand(const aCommand: TKMGameInputCommand);
    procedure ExecGameAlertBeaconCmd(const aCommand: TKMGameInputCommand);

    function DoSkipLogCommand(const aCommandType: TKMGameInputCommandType): Boolean;
    function QueueToString: String;

    function IsLastTickValueCorrect(aLastTickValue: Cardinal): Boolean;
    procedure SaveExtra(SaveStream: TKMemoryStream); virtual;
    procedure LoadExtra(LoadStream: TKMemoryStream); virtual;

    function GetNetPlayerName(aHandIndex: TKMHandID): String; virtual;
    function GICHeaderToString(aCommandType: TKMGameInputCommandType; aHandIndex: Integer): string;
    function IsPlayerMuted(aHandIndex: Integer): Boolean; virtual;
  public
    constructor Create(aReplayState: TKMGIPReplayState);
    destructor Destroy; override;

    procedure CmdArmy(aCommandType: TKMGameInputCommandType; aGroup: TKMUnitGroup); overload;
    procedure CmdArmy(aCommandType: TKMGameInputCommandType; aGroup: TKMUnitGroup; aUnit: TKMUnit); overload;
    procedure CmdArmy(aCommandType: TKMGameInputCommandType; aGroup1, aGroup2: TKMUnitGroup); overload;
    procedure CmdArmy(aCommandType: TKMGameInputCommandType; aGroup: TKMUnitGroup; aHouse: TKMHouse); overload;
    procedure CmdArmy(aCommandType: TKMGameInputCommandType; aGroup: TKMUnitGroup; aTurnAmount, aLineAmount: ShortInt); overload;
    procedure CmdArmy(aCommandType: TKMGameInputCommandType; aGroup: TKMUnitGroup; const aLoc: TKMPoint; aDirection: TKMDirection); overload;

    procedure CmdUnit(aCommandType: TKMGameInputCommandType; aUnit: TKMUnit);

    procedure CmdBuild(aCommandType: TKMGameInputCommandType; const aLoc: TKMPoint); overload;
    procedure CmdBuild(aCommandType: TKMGameInputCommandType; const aLoc: TKMPoint; aFieldType: TKMFieldType); overload;
    procedure CmdBuild(aCommandType: TKMGameInputCommandType; const aLoc: TKMPoint; aHouseType: TKMHouseType); overload;

    procedure CmdHouse(aCommandType: TKMGameInputCommandType; aHouse: TKMHouse); overload;
    procedure CmdHouse(aCommandType: TKMGameInputCommandType; aHouse: TKMHouse; aItem, aAmountChange: Integer); overload;
    procedure CmdHouse(aCommandType: TKMGameInputCommandType; aHouse: TKMHouse; aWareType: TKMWareType); overload;
    procedure CmdHouse(aCommandType: TKMGameInputCommandType; aHouse: TKMHouse; aWoodcutterMode: TKMWoodcutterMode); overload;
    procedure CmdHouse(aCommandType: TKMGameInputCommandType; aHouse: TKMHouse; aUnitType: TKMUnitType; aCount: Integer); overload;
    procedure CmdHouse(aCommandType: TKMGameInputCommandType; aHouse: TKMHouse; aValue: Integer); overload;
    procedure CmdHouse(aCommandType: TKMGameInputCommandType; aHouse: TKMHouse; const aLoc: TKMPoint); overload;

    procedure CmdWareDistribution(aCommandType: TKMGameInputCommandType; aWare: TKMWareType; aHouseType: TKMHouseType; aValue:integer); overload;
    procedure CmdWareDistribution(aCommandType: TKMGameInputCommandType; const aTextParam: AnsiString); overload;

    procedure CmdConsoleCommand(aCommandType: TKMGameInputCommandType; const aAnsiTxtParam: AnsiString;
                                const aUniTxtArray: TKMScriptCommandParamsArray);

    procedure CmdGame(aCommandType: TKMGameInputCommandType; aDateTime: TDateTime); overload;
    procedure CmdGame(aCommandType: TKMGameInputCommandType; aParam1, aParam2: Integer); overload;
    procedure CmdGame(aCommandType: TKMGameInputCommandType; aValue: Integer); overload;
    procedure CmdGame(aCommandType: TKMGameInputCommandType; aValue: Single); overload;

    procedure CmdGameBeacon(const aLocF: TKMPointF; aOwner: TKMHandID; aColor: Cardinal);

    procedure CmdPlayerAllianceSet(aForPlayer, aToPlayer: TKMHandID; aAllianceType: TKMAllianceType);
    procedure CmdPlayerAddDefaultGoals(aPlayer: TKMHandID; aBuilding: Boolean);
    procedure CmdPlayerChanged(aPlayer: TKMHandID; aPlayerNickname: AnsiString; aType: TKMHandType; aAIType: TKMAIType);

    procedure CmdScriptSoundRemoveRequest(aScriptSoundUID: Integer);

    procedure CmdTemp(aCommandType: TKMGameInputCommandType; const aLoc: TKMPoint); overload;
    procedure CmdTemp(aCommandType: TKMGameInputCommandType); overload;

    procedure ReplayTimer(aTick: Cardinal); virtual;
    procedure RunningTimer(aTick: Cardinal); virtual;
    procedure TakePlannedCommands;
    procedure UpdateState(aTick: Cardinal); virtual;

    //Replay methods
    procedure SaveToStream(SaveStream: TKMemoryStream);
    procedure SaveToFileAsText(const aFileName: UnicodeString);
    procedure SaveToFile(const aFileName: UnicodeString);
    procedure SaveToFileAsync(const aFileName: UnicodeString; aWorkerThread: TKMWorkerThread);
    procedure LoadFromStream(LoadStream: TKMemoryStream);
    procedure LoadFromFile(const aFileName: UnicodeString);
    property Count: Integer read fCount;
    property ReplayState: TKMGIPReplayState read fReplayState;
    function GetLastTick: Cardinal;
    function ReplayEnded: Boolean;
    procedure MoveCursorTo(aTick: Integer);

    property OnReplayDesync: TIntegerEvent read fOnReplayDesync write fOnReplayDesync;

    function GIPCommandToString(const aGIC: TKMGameInputCommand): UnicodeString;
    function StoredGIPCommandToString(const aCommand: TKMStoredGIPCommand): String;

    procedure Paint;
  end;


implementation
uses
  Classes, SysUtils, StrUtils, TypInfo, Math,
  KM_Entity,
  KM_GameApp, KM_Game, KM_GameParams, KM_GameSettings,
  KM_HandsCollection, KM_HandEntity,
  KM_HouseMarket, KM_HouseBarracks, KM_HouseSchool, KM_HouseTownHall, KM_HouseStore, KM_HouseArmorWorkshop,
  KM_ScriptingEvents, KM_Alerts, KM_CommonUtils, KM_RenderUI,
  KM_ResFonts, KM_Resource,
  KM_Log,
  KM_WorkerThreadUtils;

const 
  NO_LAST_TICK_VALUE = 0;
  HAND_ID_AS_WORD_ADJ = 128;

var
  GIC_COMMAND_TYPE_MAX_LENGTH: Byte;


function IsSelectedObjectCommand(aGIC: TKMGameInputCommandType): Boolean;
begin
  Result := (aGIC in ARMY_ORDER_COMMANDS) or (aGIC in HOUSE_ORDER_COMMANDS);
end;


procedure SaveCommandToMemoryStream(const aCommand: TKMGameInputCommand; aMemoryStream: TKMemoryStream); inline;
begin
  with aCommand do
  begin
    aMemoryStream.Write(CommandType, SizeOf(CommandType));
    case COMMAND_PACK_TYPES[CommandType] of
      gicpt_NoParams: ;
      gicpt_Int1:       aMemoryStream.Write(IntParams[0]);
      gicpt_Int2:       begin
                          aMemoryStream.Write(IntParams[0]);
                          aMemoryStream.Write(IntParams[1]);
                        end;
      gicpt_Int3:       begin
                          aMemoryStream.Write(IntParams[0]);
                          aMemoryStream.Write(IntParams[1]);
                          aMemoryStream.Write(IntParams[2]);
                        end;
      gicpt_Int1Word3:  begin
                          aMemoryStream.Write(IntParams[0]);
                          aMemoryStream.Write(WordParams[0]);
                          aMemoryStream.Write(WordParams[1]);
                          aMemoryStream.Write(WordParams[2]);
                        end;
      gicpt_Int1SmInt3: begin
                          aMemoryStream.Write(IntParams[0]);
                          aMemoryStream.Write(SmallIntParams[0]);
                          aMemoryStream.Write(SmallIntParams[1]);
                          aMemoryStream.Write(SmallIntParams[2]);
                        end;
      gicpt_AnsiStr1:   aMemoryStream.WriteA(AnsiStrParam);
      gicpt_Ansi1Int2:  begin
                          aMemoryStream.Write(IntParams[0]);
                          aMemoryStream.Write(IntParams[1]);
                          aMemoryStream.WriteA(AnsiStrParam);
                        end;
      gicpt_Ansi1Int3:  begin
                          aMemoryStream.Write(IntParams[0]);
                          aMemoryStream.Write(IntParams[1]);
                          aMemoryStream.Write(IntParams[2]);
                          aMemoryStream.WriteA(AnsiStrParam);
                        end;
      gicpt_Float:      aMemoryStream.Write(FloatParam);
      gicpt_UniStr1:    aMemoryStream.WriteW(UnicodeStrParams[0]);
      gicpt_Ansi1Uni4:  begin
                          aMemoryStream.WriteA(AnsiStrParam);
                          aMemoryStream.WriteW(UnicodeStrParams[0]);
                          aMemoryStream.WriteW(UnicodeStrParams[1]);
                          aMemoryStream.WriteW(UnicodeStrParams[2]);
                          aMemoryStream.WriteW(UnicodeStrParams[3]);
                        end;
      gicpt_Date:       aMemoryStream.Write(DateTimeParam);
    end;
    aMemoryStream.Write(HandIndex);
  end;
end;


procedure LoadCommandFromMemoryStream(out aCommand: TKMGameInputCommand; aMemoryStream: TKMemoryStream); inline;
begin
  with aCommand do
  begin
    aMemoryStream.Read(CommandType, SizeOf(CommandType));
    case COMMAND_PACK_TYPES[CommandType] of
      gicpt_NoParams: ;
      gicpt_Int1:       aMemoryStream.Read(IntParams[0]);
      gicpt_Int2:       begin
                          aMemoryStream.Read(IntParams[0]);
                          aMemoryStream.Read(IntParams[1]);
                        end;
      gicpt_Int3:       begin
                          aMemoryStream.Read(IntParams[0]);
                          aMemoryStream.Read(IntParams[1]);
                          aMemoryStream.Read(IntParams[2]);
                        end;
      gicpt_Int1Word3:  begin
                          aMemoryStream.Read(IntParams[0]);
                          aMemoryStream.Read(WordParams[0]);
                          aMemoryStream.Read(WordParams[1]);
                          aMemoryStream.Read(WordParams[2]);
                        end;
      gicpt_Int1SmInt3: begin
                          aMemoryStream.Read(IntParams[0]);
                          aMemoryStream.Read(SmallIntParams[0]);
                          aMemoryStream.Read(SmallIntParams[1]);
                          aMemoryStream.Read(SmallIntParams[2]);
                        end;
      gicpt_AnsiStr1:   aMemoryStream.ReadA(AnsiStrParam);
      gicpt_Ansi1Int2:  begin
                          aMemoryStream.Read(IntParams[0]);
                          aMemoryStream.Read(IntParams[1]);
                          aMemoryStream.ReadA(AnsiStrParam);
                        end;
      gicpt_Ansi1Int3:  begin
                          aMemoryStream.Read(IntParams[0]);
                          aMemoryStream.Read(IntParams[1]);
                          aMemoryStream.Read(IntParams[2]);
                          aMemoryStream.ReadA(AnsiStrParam);
                        end;
      gicpt_Float:      aMemoryStream.Read(FloatParam);
      gicpt_UniStr1:    aMemoryStream.ReadW(UnicodeStrParams[0]);
      gicpt_Ansi1Uni4:  begin
                          aMemoryStream.ReadA(AnsiStrParam);
                          aMemoryStream.ReadW(UnicodeStrParams[0]);
                          aMemoryStream.ReadW(UnicodeStrParams[1]);
                          aMemoryStream.ReadW(UnicodeStrParams[2]);
                          aMemoryStream.ReadW(UnicodeStrParams[3]);
                        end;
      gicpt_Date:       aMemoryStream.Read(DateTimeParam);
    end;
    aMemoryStream.Read(HandIndex);
  end;
end;


function TKMGameInputProcess.GetNetPlayerName(aHandIndex: TKMHandID): String;
begin
  Result := '';
end;


function TKMGameInputProcess.GICHeaderToString(aCommandType: TKMGameInputCommandType; aHandIndex: Integer): string;
begin
  Result := Format('%-' + IntToStr(GIC_COMMAND_TYPE_MAX_LENGTH) + 's hand: %2d' + GetNetPlayerName(aHandIndex) + ', params: ',
                  [GetEnumName(TypeInfo(TKMGameInputCommandType), Integer(aCommandType)), aHandIndex]);
end;


function TKMGameInputProcess.GIPCommandToString(const aGIC: TKMGameInputCommand): UnicodeString;
begin
  with aGIC do
  begin
    Result := GICHeaderToString(CommandType, HandIndex);
    case COMMAND_PACK_TYPES[CommandType] of
      gicpt_NoParams:   Result := Result + ' []';
      gicpt_Int1:       Result := Result + Format('[%10d]', [IntParams[0]]);
      gicpt_Int2:       Result := Result + Format('[%10d,%10d]', [IntParams[0], IntParams[1]]);
      gicpt_Int3:       Result := Result + Format('[%10d,%10d,%10d]', [IntParams[0], IntParams[1], IntParams[2]]);
      gicpt_Int1Word3:  Result := Result + Format('[%10d,%10d,%10d,%10d]', [IntParams[0], WordParams[0], WordParams[1], WordParams[2]]);
      gicpt_Int1SmInt3: Result := Result + Format('[%10d,%10d,%10d,%10d]', [IntParams[0], SmallIntParams[0], SmallIntParams[1], SmallIntParams[2]]);
      gicpt_AnsiStr1:   Result := Result + Format('[%s]', [AnsiStrParam]);
      gicpt_Ansi1Int2:  Result := Result + Format('[%s,%10d,%10d]', [AnsiStrParam, IntParams[0], IntParams[1]]);
      gicpt_Ansi1Int3:  Result := Result + Format('[%s,%10d,%10d,%10d]', [AnsiStrParam, IntParams[0], IntParams[1], IntParams[2]]);
      gicpt_UniStr1:    Result := Result + Format('[%s]', [UnicodeStrParams[0]]);
      gicpt_Float:      Result := Result + Format('[%f]', [FloatParam]);
      gicpt_Ansi1Uni4:  Result := Result + Format('[%s,%s,%s,%s,%s]', [AnsiStrParam, UnicodeStrParams[0], UnicodeStrParams[0],UnicodeStrParams[1],UnicodeStrParams[2]]);
      gicpt_Date:       Result := Result + Format('[%s]', [FormatDateTime('dd.mm.yy hh:nn:ss.zzz', DateTimeParam)]);
    end;
  end;
end;


{ TGameInputProcess }
constructor TKMGameInputProcess.Create(aReplayState: TKMGIPReplayState);
begin
  inherited Create;

  SetLength(fQueue, 128);
  fCount := 0;
  fCursor := 1;
  fReplayState := aReplayState;

  fPlannedCommands := TList<TKMGameInputCommand>.Create;
  fGic2StoredConverter := TKMGic2StoredConverter.Create;
  fStoredCommands := TKMStoredGicPackedList.Create;
end;


destructor TKMGameInputProcess.Destroy;
begin
  fStoredCommands.Free;
  fGic2StoredConverter.Free;
  fPlannedCommands.Free;

  inherited;
end;


function TKMGameInputProcess.MakeEmptyCommand(aGIC: TKMGameInputCommandType): TKMGameInputCommand;
begin
  Result.CommandType := aGIC;
  Result.HandIndex := gMySpectator.HandID;
end;


procedure TKMGameInputProcess.MoveCursorTo(aTick: Integer);
begin
  // fCursor cant be 0, while tick could if we load the very first replay savepoint
  fCursor := Max(1, aTick);
end;


function TKMGameInputProcess.MakeCommand(aGIC: TKMGameInputCommandType): TKMGameInputCommand;
begin
  Assert(COMMAND_PACK_TYPES[aGIC] = gicpt_NoParams,
         Format('Wrong packing type for command %s: Expected: gicpt_NoParams Actual: [%s]',
                [GetEnumName(TypeInfo(TKMGameInputCommandType), Integer(aGIC)),
                 GetEnumName(TypeInfo(TKMGameInputCommandPackType), Integer(COMMAND_PACK_TYPES[aGIC]))]));
  Result := MakeEmptyCommand(aGIC);
end;


function TKMGameInputProcess.MakeCommand(aGIC: TKMGameInputCommandType; const aParam1: Integer): TKMGameInputCommand;
begin
  Assert(COMMAND_PACK_TYPES[aGIC] = gicpt_Int1,
         Format('Wrong packing type for command %s: Expected: gicpt_Int1 Actual: [%s]',
                [GetEnumName(TypeInfo(TKMGameInputCommandType), Integer(aGIC)),
                 GetEnumName(TypeInfo(TKMGameInputCommandPackType), Integer(COMMAND_PACK_TYPES[aGIC]))]));
  Result := MakeEmptyCommand(aGIC);
  Result.IntParams[0] := aParam1;
end;


function TKMGameInputProcess.MakeCommand(aGIC: TKMGameInputCommandType; const aParam1, aParam2: Integer): TKMGameInputCommand;
begin
  Assert(COMMAND_PACK_TYPES[aGIC] = gicpt_Int2,
         Format('Wrong packing type for command %s: Expected: gicpt_Int2 Actual: [%s]',
                [GetEnumName(TypeInfo(TKMGameInputCommandType), Integer(aGIC)),
                 GetEnumName(TypeInfo(TKMGameInputCommandPackType), Integer(COMMAND_PACK_TYPES[aGIC]))]));
  Result := MakeEmptyCommand(aGIC);
  Result.IntParams[0] := aParam1;
  Result.IntParams[1] := aParam2;
end;


function TKMGameInputProcess.MakeCommand(aGIC: TKMGameInputCommandType; const aParam1, aParam2, aParam3: Integer): TKMGameInputCommand;
begin
  Assert(COMMAND_PACK_TYPES[aGIC] = gicpt_Int3,
         Format('Wrong packing type for command %s: Expected: gicpt_Int3 Actual: [%s]',
                [GetEnumName(TypeInfo(TKMGameInputCommandType), Integer(aGIC)),
                 GetEnumName(TypeInfo(TKMGameInputCommandPackType), Integer(COMMAND_PACK_TYPES[aGIC]))]));
  Result := MakeEmptyCommand(aGIC);
  Result.IntParams[0] := aParam1;
  Result.IntParams[1] := aParam2;
  Result.IntParams[2] := aParam3;
end;


function TKMGameInputProcess.MakeCommandW(aGIC: TKMGameInputCommandType; const aParam1: Integer; const aParam2, aParam3, aParam4: Word): TKMGameInputCommand;
begin
  Assert(COMMAND_PACK_TYPES[aGIC] = gicpt_Int1Word3,
         Format('Wrong packing type for command %s: Expected: gicpt_Int1Word3 Actual: [%s]',
                [GetEnumName(TypeInfo(TKMGameInputCommandType), Integer(aGIC)),
                 GetEnumName(TypeInfo(TKMGameInputCommandPackType), Integer(COMMAND_PACK_TYPES[aGIC]))]));
  Result := MakeEmptyCommand(aGIC);
  Result.IntParams[0] := aParam1;
  Result.WordParams[0] := aParam2;
  Result.WordParams[1] := aParam3;
  Result.WordParams[2] := aParam4;
end;


function TKMGameInputProcess.MakeCommandSmI(aGIC: TKMGameInputCommandType; const aParam1: Integer; const aParam2, aParam3, aParam4: SmallInt): TKMGameInputCommand;
begin
  Assert(COMMAND_PACK_TYPES[aGIC] = gicpt_Int1SmInt3,
         Format('Wrong packing type for command %s: Expected: gicpt_Int1SmInt3 Actual: [%s]',
                [GetEnumName(TypeInfo(TKMGameInputCommandType), Integer(aGIC)),
                 GetEnumName(TypeInfo(TKMGameInputCommandPackType), Integer(COMMAND_PACK_TYPES[aGIC]))]));
  Result := MakeEmptyCommand(aGIC);
  Result.IntParams[0] := aParam1;
  Result.SmallIntParams[0] := aParam2;
  Result.SmallIntParams[1] := aParam3;
  Result.SmallIntParams[2] := aParam4;
end;


function TKMGameInputProcess.MakeCommand(aGIC: TKMGameInputCommandType; const aAnsiTxtParam: AnsiString; const aParam1, aParam2: Integer): TKMGameInputCommand;
begin
  Assert(COMMAND_PACK_TYPES[aGIC] = gicpt_Ansi1Int2,
         Format('Wrong packing type for command %s: Expected: gicpt_Ansi1Int2 Actual: [%s]',
                [GetEnumName(TypeInfo(TKMGameInputCommandType), Integer(aGIC)),
                 GetEnumName(TypeInfo(TKMGameInputCommandPackType), Integer(COMMAND_PACK_TYPES[aGIC]))]));
  Result := MakeEmptyCommand(aGIC);
  Result.AnsiStrParam := aAnsiTxtParam;
  Result.IntParams[0] := aParam1;
  Result.IntParams[1] := aParam2;
end;


function TKMGameInputProcess.MakeCommand(aGIC: TKMGameInputCommandType; const aAnsiTxtParam: AnsiString; const aParam1, aParam2, aParam3: Integer): TKMGameInputCommand;
begin
  Assert(COMMAND_PACK_TYPES[aGIC] = gicpt_Ansi1Int3,
         Format('Wrong packing type for command %s: Expected: gicpt_Ansi1Int2 Actual: [%s]',
                [GetEnumName(TypeInfo(TKMGameInputCommandType), Integer(aGIC)),
                 GetEnumName(TypeInfo(TKMGameInputCommandPackType), Integer(COMMAND_PACK_TYPES[aGIC]))]));
  Result := MakeEmptyCommand(aGIC);
  Result.AnsiStrParam := aAnsiTxtParam;
  Result.IntParams[0] := aParam1;
  Result.IntParams[1] := aParam2;
  Result.IntParams[2] := aParam3;
end;


function TKMGameInputProcess.MakeCommandNoHand(aGIC: TKMGameInputCommandType; const aParam1: Single): TKMGameInputCommand;
begin
  Assert(COMMAND_PACK_TYPES[aGIC] = gicpt_Float,
         Format('Wrong packing type for command %s: Expected: gicpt_Float Actual: [%s]',
                [GetEnumName(TypeInfo(TKMGameInputCommandType), Integer(aGIC)),
                 GetEnumName(TypeInfo(TKMGameInputCommandPackType), Integer(COMMAND_PACK_TYPES[aGIC]))]));
  Result.HandIndex := -1;
  Result.CommandType := aGIC;
  Result.FloatParam := aParam1;
end;


function TKMGameInputProcess.MakeCommand(aGIC: TKMGameInputCommandType; const aTextParam: AnsiString): TKMGameInputCommand;
begin
  Assert(COMMAND_PACK_TYPES[aGIC] = gicpt_AnsiStr1,
         Format('Wrong packing type for command %s: Expected: gicpt_AnsiStr1 Actual: [%s]',
                [GetEnumName(TypeInfo(TKMGameInputCommandType), Integer(aGIC)),
                 GetEnumName(TypeInfo(TKMGameInputCommandPackType), Integer(COMMAND_PACK_TYPES[aGIC]))]));
  Result := MakeEmptyCommand(aGIC);

  Result.AnsiStrParam := aTextParam;
end;


function TKMGameInputProcess.MakeCommand(aGIC: TKMGameInputCommandType; const aTextParam: UnicodeString): TKMGameInputCommand;
begin
  Assert(COMMAND_PACK_TYPES[aGIC] = gicpt_UniStr1,
         Format('Wrong packing type for command %s: Expected: gicpt_UniStr1 Actual: [%s]',
                [GetEnumName(TypeInfo(TKMGameInputCommandType), Integer(aGIC)),
                 GetEnumName(TypeInfo(TKMGameInputCommandPackType), Integer(COMMAND_PACK_TYPES[aGIC]))]));
  Result := MakeEmptyCommand(aGIC);

  Result.UnicodeStrParams[0] := aTextParam;
end;


function TKMGameInputProcess.MakeCommand(aGIC: TKMGameInputCommandType; const aAnsiTxtParam: AnsiString;
                                         const aUniTxtArray: TKMScriptCommandParamsArray): TKMGameInputCommand;
var
  I: Integer;
begin
  Assert(COMMAND_PACK_TYPES[aGIC] = gicpt_Ansi1Uni4,
         Format('Wrong packing type for command %s: Expected: gicpt_Ansi1Uni4 Actual: [%s]',
                [GetEnumName(TypeInfo(TKMGameInputCommandType), Integer(aGIC)),
                 GetEnumName(TypeInfo(TKMGameInputCommandPackType), Integer(COMMAND_PACK_TYPES[aGIC]))]));
  Result := MakeEmptyCommand(aGIC);

  Result.AnsiStrParam := aAnsiTxtParam;

  for I := 0 to Length(aUniTxtArray) - 1 do
    Result.UnicodeStrParams[I] := aUniTxtArray[I];
end;


function TKMGameInputProcess.MakeCommand(aGIC: TKMGameInputCommandType; aDateTimeParam: TDateTime): TKMGameInputCommand;
begin
  Assert(COMMAND_PACK_TYPES[aGIC] = gicpt_Date,
         Format('Wrong packing type for command %s: Expected: gicpt_Date Actual: [%s]',
                [GetEnumName(TypeInfo(TKMGameInputCommandType), Integer(aGIC)),
                 GetEnumName(TypeInfo(TKMGameInputCommandPackType), Integer(COMMAND_PACK_TYPES[aGIC]))]));
  Result := MakeEmptyCommand(aGIC);

  Result.DateTimeParam := aDateTimeParam;
end;


function TKMGameInputProcess.DoSkipLogCommand(const aCommandType: TKMGameInputCommandType): Boolean;
begin
  Result := SKIP_LOG_TEMP_COMMANDS and (aCommandType in [gicTempAddScout, gicTempRevealMap, gicTempVictory, gicTempDefeat, gicTempDoNothing]);
end;


procedure TKMGameInputProcess.DoTakeCommand(const aCommand: TKMGameInputCommand);
begin
  //Do nothing
end;


procedure TKMGameInputProcess.TakeCommand(const aCommand: TKMGameInputCommand);
begin
  if gGame.IsStarted
    and (gGameParams.Tick > 0) then //We could get some commands even before 1st game update (on tick 0)
    DoTakeCommand(aCommand)
  else
    fPlannedCommands.Add(aCommand);
end;


procedure TKMGameInputProcess.ExecCommand(const aCommand: TKMGameInputCommand);
var
  P: TKMHand;
  isSilent: Boolean;
  srcUnit: TKMUnit;
  srcGroup, TgtGroup: TKMUnitGroup;
  tgtUnit: TKMUnit;
  srcHouse, tgtHouse: TKMHouse;
begin
  //NOTE: gMySpectator.PlayerIndex should not be used for important stuff here, use P instead (commands must be executed the same for all players)
  isSilent := (aCommand.HandIndex <> gMySpectator.HandID);
  P := gHands[aCommand.HandIndex];
  srcUnit := nil;
  srcGroup := nil;
  TgtGroup := nil;
  srcHouse := nil;
  tgtHouse := nil;
  tgtUnit := nil;

  with aCommand do
  begin
    //It is possible that units/houses have died by now
    if CommandType in [gicArmyFeed, gicArmySplit, gicArmySplitSingle, gicArmyLink,
                       gicArmyAttackUnit, gicArmyAttackHouse, gicArmyHalt,
                       gicArmyFormation, gicArmyWalk, gicArmyStorm]
    then
    begin
      srcGroup := gHands.GetGroupByUID(IntParams[0]);
      if (srcGroup = nil) or srcGroup.IsDead //Group has died before command could be executed
      or (srcGroup.Owner <> aCommand.HandIndex) then //Potential exploit
        Exit;
    end;
    if CommandType in [gicArmyLink] then
    begin
      TgtGroup := gHands.GetGroupByUID(IntParams[1]);
      if (TgtGroup = nil) or TgtGroup.IsDead //Unit has died before command could be executed
      or (TgtGroup.Owner <> aCommand.HandIndex) then //Potential exploit
        Exit;
    end;
    if CommandType in [gicArmyAttackUnit] then
    begin
      tgtUnit := gHands.GetUnitByUID(IntParams[1]);
      if (tgtUnit = nil) or tgtUnit.IsDeadOrDying then //Unit has died before command could be executed
        Exit;
    end;
    if CommandType in [gicHouseRepairToggle, gicHouseDeliveryModeNext, gicHouseDeliveryModePrev, gicHouseWoodcuttersCutting, gicHouseTownHallMaxGold,
      gicHouseOrderProduct, gicHouseMarketFrom, gicHouseMarketTo, gicHouseBarracksRally, gicHouseTownHallRally,
      gicHouseStoreNotAcceptFlag, gicHouseStoreNotAcceptAllFlag, gicHStoreNotAllowTakeOutFlag, gicHStoreNotAllowTakeOutAllFlag,
      gicHouseBarracksAcceptFlag, gicHouseBarracksAcceptAllFlag, gicHBarracksNotAllowTakeOutFlag, gicHBarracksNotAllowTakeOutAllFlag,
      gicHouseBarracksEquip, gicHouseTownHallEquip, gicHouseClosedForWorkerTgl,
      gicHouseSchoolTrain, gicHouseSchoolTrainChOrder, gicHouseSchoolTrainChLastUOrder, gicHouseRemoveTrain,
      gicHouseWoodcutterMode, gicHBarracksAcceptRecruitsTgl, gicHouseArmorWSDeliveryToggle] then
    begin
      srcHouse := gHands.GetHouseByUID(IntParams[0]);
      if (srcHouse = nil) or srcHouse.IsDestroyed //House has been destroyed before command could be executed
      or (srcHouse.Owner <> aCommand.HandIndex) then //Potential exploit
        Exit;
    end;
    if CommandType in [gicArmyAttackHouse] then
    begin
      tgtHouse := gHands.GetHouseByUID(IntParams[1]);
      if (tgtHouse = nil) or tgtHouse.IsDestroyed then Exit; //House has been destroyed before command could be executed
    end;

    if CommandType in [gicUnitDismiss, gicUnitDismissCancel] then
    begin
      srcUnit := gHands.GetUnitByUID(IntParams[0]);
      if (srcUnit = nil) or srcUnit.IsDeadOrDying //Unit has died before command could be executed
        or (srcUnit.Owner <> aCommand.HandIndex) then //Potential exploit
        Exit;
    end;

    //Some commands are blocked by peacetime (this is a fall back in case players try to cheat)
    if gGame.IsPeaceTime and (CommandType in BLOCKED_BY_PEACETIME) then
       Exit;

    //No commands allowed after a player has lost (this is a fall back in case players try to cheat)
    if not (aCommand.CommandType in ALLOWED_AFTER_DEFEAT) and P.AI.HasLost then
      Exit;

    //Most commands blocked during cinematic (this is a fall back in case players try to cheat)
    if not (aCommand.CommandType in ALLOWED_IN_CINEMATIC) and (P.InCinematic) then
      Exit;

    if gLog.CanLogCommands() and not DoSkipLogCommand(aCommand.CommandType) then
      gLog.LogCommands(Format('Tick: %6d Exec command: %s', [gGameParams.Tick, GIPCommandToString(aCommand)]));

    case CommandType of
      gicArmyFeed:         srcGroup.OrderFood(True);
      gicArmySplit:        srcGroup.OrderSplit;
      gicArmySplitSingle:  srcGroup.OrderSplit(True);
      gicArmyStorm:        srcGroup.OrderStorm(True);
      gicArmyLink:         srcGroup.OrderLinkTo(TgtGroup, True);
      gicArmyAttackUnit:   srcGroup.OrderAttackUnit(tgtUnit, True);
      gicArmyAttackHouse:  srcGroup.OrderAttackHouse(tgtHouse, True);
      gicArmyHalt:         srcGroup.OrderHalt(True);
      gicArmyFormation:    srcGroup.OrderFormation(IntParams[1],IntParams[2], True);
      gicArmyWalk:         srcGroup.OrderWalk(KMPoint(SmallIntParams[0], SmallIntParams[1]), True, wtokPlayerOrder, TKMDirection(SmallIntParams[2]));

      gicUnitDismiss:        srcUnit.Dismiss;
      gicUnitDismissCancel:  srcUnit.DismissCancel;

      gicBuildToggleFieldPlan:   P.ToggleFieldPlan(KMPoint(IntParams[0],IntParams[1]), TKMFieldType(IntParams[2]), not gGameParams.IsMultiPlayerOrSpec); //Make sound in singleplayer mode only
      gicBuildRemoveFieldPlan:   P.RemFieldPlan(KMPoint(IntParams[0],IntParams[1]), not gGameParams.IsMultiPlayerOrSpec); //Make sound in singleplayer mode only
      gicBuildRemoveHouse:       P.RemHouse(KMPoint(IntParams[0],IntParams[1]), isSilent);
      gicBuildRemoveHousePlan:   P.RemHousePlan(KMPoint(IntParams[0],IntParams[1]));
      gicBuildHousePlan:         if P.CanAddHousePlan(KMPoint(IntParams[1],IntParams[2]), TKMHouseType(IntParams[0])) then
                                    P.AddHousePlan(TKMHouseType(IntParams[0]), KMPoint(IntParams[1],IntParams[2]));

      gicHouseRepairToggle:      srcHouse.BuildingRepair := not srcHouse.BuildingRepair;
      gicHouseDeliveryModeNext:   //Delivery mode has to be delayed, to avoid occasional delivery mode button clicks
                                  srcHouse.SetNextDeliveryMode;
      gicHouseDeliveryModePrev:   //Delivery mode has to be delayed, to avoid occasional delivery mode button clicks
                                  srcHouse.SetPrevDeliveryMode;
      gicHouseClosedForWorkerTgl: srcHouse.IsClosedForWorker := not srcHouse.IsClosedForWorker;
      gicHouseOrderProduct:      srcHouse.WareOrder[IntParams[1]] := srcHouse.WareOrder[IntParams[1]] + IntParams[2];
      gicHouseMarketFrom:        TKMHouseMarket(srcHouse).ResFrom := TKMWareType(IntParams[1]);
      gicHouseMarketTo:          TKMHouseMarket(srcHouse).ResTo := TKMWareType(IntParams[1]);
      gicHouseStoreNotAcceptFlag:   TKMHouseStore(srcHouse).ToggleNotAcceptFlag(TKMWareType(IntParams[1]));
      gicHouseStoreNotAcceptAllFlag:
                                 TKMHouseStore(srcHouse).ToggleNotAcceptAllFlag(TKMWareType(IntParams[1]));
      gicHStoreNotAllowTakeOutFlag:
                                 TKMHouseStore(srcHouse).ToggleNotAcceptTakeOutFlag(TKMWareType(IntParams[1]));
      gicHStoreNotAllowTakeOutAllFlag:
                                 TKMHouseStore(srcHouse).ToggleNotAcceptTakeOutAllFlag(TKMWareType(IntParams[1]));
      gicHouseWoodcutterMode:    TKMHouseWoodcutters(srcHouse).WoodcutterMode := TKMWoodcutterMode(IntParams[1]);
      gicHouseBarracksAcceptFlag:
                                  TKMHouseBarracks(srcHouse).ToggleNotAcceptFlag(TKMWareType(IntParams[1]));
      gicHouseBarracksAcceptAllFlag:
                                  TKMHouseBarracks(srcHouse).ToggleNotAcceptAllFlag(TKMWareType(IntParams[1]));
      gicHBarracksNotAllowTakeOutFlag:
                                  TKMHouseBarracks(srcHouse).ToggleNotAllowTakeOutFlag(TKMWareType(IntParams[1]));
      gicHBarracksNotAllowTakeOutAllFlag:
                                  TKMHouseBarracks(srcHouse).ToggleNotAllowTakeOutAllFlag(TKMWareType(IntParams[1]));
      gicHBarracksAcceptRecruitsTgl:
                                  TKMHouseBarracks(srcHouse).ToggleAcceptRecruits;
      gicHouseBarracksEquip:     TKMHouseBarracks(srcHouse).Equip(TKMUnitType(IntParams[1]), IntParams[2]);
      gicHouseBarracksRally:     TKMHouseBarracks(srcHouse).FlagPoint := KMPoint(IntParams[1], IntParams[2]);
      gicHouseTownHallEquip:     TKMHouseTownHall(srcHouse).Equip(TKMUnitType(IntParams[1]), IntParams[2]);
      gicHouseTownHallRally:     TKMHouseTownHall(srcHouse).FlagPoint := KMPoint(IntParams[1], IntParams[2]);
      gicHouseTownHallMaxGold:   TKMHouseTownHall(srcHouse).GoldMaxCnt := EnsureRange(IntParams[1], 0, High(Word));
      gicHouseSchoolTrain:       TKMHouseSchool(srcHouse).AddUnitToQueue(TKMUnitType(IntParams[1]), IntParams[2]);
      gicHouseSchoolTrainChOrder:TKMHouseSchool(srcHouse).ChangeUnitTrainOrder(IntParams[1], IntParams[2]);
      gicHouseSchoolTrainChLastUOrder: TKMHouseSchool(srcHouse).ChangeUnitTrainOrder(IntParams[1]);
      gicHouseRemoveTrain:       TKMHouseSchool(srcHouse).RemUnitFromQueue(IntParams[1]);
      gicHouseWoodcuttersCutting: TKMHouseWoodcutters(srcHouse).FlagPoint := KMPoint(IntParams[1], IntParams[2]);
      gicHouseArmorWSDeliveryToggle:   TKMHouseArmorWorkshop(srcHouse).ToggleResDelivery(TKMWareType(IntParams[1]));

      gicWareDistributionChange:  begin
                                    P.Stats.WareDistribution[TKMWareType(IntParams[0]), TKMHouseType(IntParams[1])] := IntParams[2];
                                    P.Houses.UpdateDemands;
                                  end;
      gicWareDistributions:       begin
                                    P.Stats.WareDistribution.LoadFromStr(UnicodeString(AnsiStrParam));
                                    P.Houses.UpdateDemands;
                                  end;

      gicTempAddScout:            if DEBUG_CHEATS and (MULTIPLAYER_CHEATS or not gGameParams.IsMultiPlayerOrSpec) then
                                    //Place a warrior
                                    P.AddUnit(utScout, KMPoint(IntParams[0], IntParams[1]), True, 0, True);
      gicTempRevealMap:           if DEBUG_CHEATS and (MULTIPLAYER_CHEATS or not gGameParams.IsMultiPlayerOrSpec) then
                                    P.FogOfWar.RevealEverything;
      gicTempVictory:             if DEBUG_CHEATS and (MULTIPLAYER_CHEATS or not gGameParams.IsMultiPlayerOrSpec) then
                                    P.AI.Victory;
      gicTempDefeat:              if DEBUG_CHEATS and (MULTIPLAYER_CHEATS or not gGameParams.IsMultiPlayerOrSpec) then
                                    P.AI.Defeat;
      gicTempDoNothing:           ;

      gicGamePause:               ;//if fReplayState = gipRecording then fGame.fGamePlayInterface.SetPause(boolean(Params[0]));
      gicGameSpeed:               gGame.SetSpeedGIP(FloatParam, fReplayState = gipRecording);
      gicGameAutoSave:            if (fReplayState = gipRecording) and gGameSettings.Autosave then
                                    gGame.AutoSave(DateTimeParam); //Timestamp is synchronised
      gicGameAutoSaveAfterPT:     if (fReplayState = gipRecording) and gGameSettings.Autosave then
                                    gGame.AutoSaveAfterPT(DateTimeParam); //Timestamp is synchronised
      gicGameSaveReturnLobby:     if fReplayState = gipRecording then
                                  begin
                                    gGameApp.PrepareReturnToLobby(DateTimeParam); //Timestamp is synchronised
                                    Exit;
                                  end;
      gicGameLoadSave:            ; //Just a marker to know when game was loaded
      gicGameTeamChange:          begin
                                    //Currently unused, disabled to prevent potential exploitation
                                    {fGame.Networking.Room[Params[0]].Team := Params[1];
                                    fGame.UpdateMultiplayerTeams;
                                    fPlayers.SyncFogOfWar;
                                    if fGame.Networking.IsHost then
                                      fGame.Networking.SendPlayerListAndRefreshPlayersSetup;}
                                  end;
      gicGameAlertBeacon:         ExecGameAlertBeaconCmd(aCommand);
      gicGameHotkeySet:           P.SelectionHotkeys[IntParams[0]] := IntParams[1];
      gicGameMessageLogRead:      P.MessageLog[IntParams[0]].IsReadGIP := True;
      gicGameMessageListRead:     P.MessageLog.ReadAtCountGIP := IntParams[0];
      gicGamePlayerChange:        begin
                                    Assert(not gGameParams.IsMapEditor);
                                    gHands[IntParams[0]].OwnerNickname := AnsiStrParam;
                                    gHands.UpdateHandState(IntParams[0], TKMHandType(IntParams[1]), TKMAIType(IntParams[2]));
                                    gGame.GamePlayInterface.UpdateUI; //Update players drop list
                                  end;
      gicGamePlayerDefeat:        begin
                                    gHands.UpdateGoalsForHand(IntParams[0], False);
                                    gHands[IntParams[0]].AI.Defeat(False);
                                  end;
      gicGamePlayerAllianceSet:   gHands[IntParams[0]].Alliances[IntParams[1]] := TKMAllianceType(IntParams[2]);
      gicGamePlayerAddDefGoals:   gHands[IntParams[0]].AI.AddDefaultGoals(IntToBool(IntParams[1]));
      gicScriptConsoleCommand:    gScriptEvents.CallConsoleCommand(HandIndex, AnsiStrParam, UnicodeStrParams);
      gicScriptSoundRemoveRq:     gGame.AddScriptSoundRemoveRequest(IntParams[0], HandIndex);
    else
      raise Exception.Create('Unexpected gic command');
    end;
  end;
end;


function TKMGameInputProcess.IsPlayerMuted(aHandIndex: Integer): Boolean;
begin
  Result := False;
end;


procedure TKMGameInputProcess.ExecGameAlertBeaconCmd(const aCommand: TKMGameInputCommand);
var
  handId: Integer;

  function DoAddPlayerBeacon: Boolean;
  begin
    Result := (gHands.CheckAlliance(handId, gMySpectator.HandID) = atAlly)
      and (gHands[handId].ShareBeacons[gMySpectator.HandID])
      and not IsPlayerMuted(handId); // Do not show beacons sent by muted players
  end;

var
  doAddBeacon: Boolean;
begin
  handId := aCommand.SmallIntParams[2];
  // Beacon script event must always be run by all players for consistency
  gScriptEvents.ProcBeacon(handId, 1 + (aCommand.SmallIntParams[0] div 10),
                                   1 + (aCommand.SmallIntParams[1] div 10));

  doAddBeacon := False;

  case gGameParams.Mode of
    gmSingle,
    gmCampaign,
    gmMulti:          doAddBeacon := (handId <> HAND_NONE) and DoAddPlayerBeacon;
    gmMultiSpectate:  doAddBeacon := (handId = HAND_NONE) // Show spectators beacons while spectating
                                    or (gGameSettings.SpecShowBeacons and DoAddPlayerBeacon);
    gmReplaySingle,
    gmReplayMulti:    doAddBeacon := (handId <> HAND_NONE)  // Do not show spectators beacons in replay
                                    and gGameSettings.ReplayShowBeacons and DoAddPlayerBeacon;
  end;

  if doAddBeacon then
    gGame.GamePlayInterface.Alerts.AddBeacon(KMPointF(aCommand.SmallIntParams[0]/10,
                                                      aCommand.SmallIntParams[1]/10),
                                                      handId,
                                                      (aCommand.IntParams[0] or $FF000000),
                                                      gGameApp.GlobalTickCount + ALERT_DURATION[atBeacon]);
end;


procedure TKMGameInputProcess.CmdArmy(aCommandType: TKMGameInputCommandType; aGroup: TKMUnitGroup);
begin
  Assert(aCommandType in [gicArmyFeed, gicArmySplit, gicArmySplitSingle, gicArmyStorm, gicArmyHalt]);
  TakeCommand(MakeCommand(aCommandType, aGroup.UID));
end;


procedure TKMGameInputProcess.CmdArmy(aCommandType: TKMGameInputCommandType; aGroup: TKMUnitGroup; aUnit: TKMUnit);
begin
  Assert(aCommandType in [gicArmyAttackUnit]);
  TakeCommand(MakeCommand(aCommandType, aGroup.UID, aUnit.UID));
end;


procedure TKMGameInputProcess.CmdArmy(aCommandType: TKMGameInputCommandType; aGroup1, aGroup2: TKMUnitGroup);
begin
  Assert(aCommandType in [gicArmyLink]);
  TakeCommand(MakeCommand(aCommandType, aGroup1.UID, aGroup2.UID));
end;


procedure TKMGameInputProcess.CmdArmy(aCommandType: TKMGameInputCommandType; aGroup: TKMUnitGroup; aHouse: TKMHouse);
begin
  Assert(aCommandType = gicArmyAttackHouse);
  TakeCommand(MakeCommand(aCommandType, aGroup.UID, aHouse.UID));
end;


procedure TKMGameInputProcess.CmdArmy(aCommandType: TKMGameInputCommandType; aGroup: TKMUnitGroup; aTurnAmount, aLineAmount: ShortInt);
begin
  Assert(aCommandType = gicArmyFormation);
  TakeCommand(MakeCommand(aCommandType, aGroup.UID, aTurnAmount, aLineAmount));
end;


procedure TKMGameInputProcess.CmdArmy(aCommandType: TKMGameInputCommandType; aGroup: TKMUnitGroup; const aLoc: TKMPoint; aDirection: TKMDirection);
begin
  Assert(aCommandType = gicArmyWalk);
  TakeCommand(MakeCommandSmI(aCommandType, aGroup.UID, aLoc.X, aLoc.Y, SmallInt(aDirection)));
end;


procedure TKMGameInputProcess.CmdUnit(aCommandType: TKMGameInputCommandType; aUnit: TKMUnit);
begin
  Assert(aCommandType in [gicUnitDismiss, gicUnitDismissCancel]);
  TakeCommand(MakeCommand(aCommandType, aUnit.UID));
end;


procedure TKMGameInputProcess.CmdBuild(aCommandType: TKMGameInputCommandType; const aLoc: TKMPoint);
begin
  Assert(aCommandType in [gicBuildRemoveFieldPlan, gicBuildRemoveHouse, gicBuildRemoveHousePlan]);

  if gGameParams.IsReplayOrSpectate then Exit;

  //Remove fake markup that will be visible only to gMySpectator until Server verifies it.
  //Must go before TakeCommand as it could execute command immediately (in singleplayer)
  //and the fake markup must be added first otherwise our logic in FieldsList fails
  if gGameParams.IsMultiplayerGame and (aCommandType = gicBuildRemoveFieldPlan) then
    gMySpectator.Hand.RemFakeFieldPlan(aLoc);

  TakeCommand(MakeCommand(aCommandType, aLoc.X, aLoc.Y));
end;


procedure TKMGameInputProcess.CmdBuild(aCommandType: TKMGameInputCommandType; const aLoc: TKMPoint; aFieldType: TKMFieldType);
begin
  Assert(aCommandType in [gicBuildToggleFieldPlan]);

  if gGameParams.IsReplayOrSpectate then Exit;

  //Add fake markup that will be visible only to gMySpectator until Server verifies it.
  //Must go before TakeCommand as it could execute command immediately (in singleplayer)
  //and the fake markup must be added first otherwise our logic in FieldsList fails
  if gGameParams.IsMultiplayerGame then
    gMySpectator.Hand.ToggleFakeFieldPlan(aLoc, aFieldType);

  TakeCommand(MakeCommand(aCommandType, aLoc.X, aLoc.Y, Byte(aFieldType)));
end;


procedure TKMGameInputProcess.CmdBuild(aCommandType: TKMGameInputCommandType; const aLoc: TKMPoint; aHouseType: TKMHouseType);
begin
  Assert(aCommandType = gicBuildHousePlan);

  if gGameParams.IsReplayOrSpectate then Exit;

  TakeCommand(MakeCommand(aCommandType, Byte(aHouseType), aLoc.X, aLoc.Y));
end;


procedure TKMGameInputProcess.CmdHouse(aCommandType: TKMGameInputCommandType; aHouse: TKMHouse);
begin
  Assert(aCommandType in [gicHouseRepairToggle, gicHouseClosedForWorkerTgl, gicHBarracksAcceptRecruitsTgl, gicHouseDeliveryModeNext, gicHouseDeliveryModePrev]);
  TakeCommand(MakeCommand(aCommandType, aHouse.UID));
end;


procedure TKMGameInputProcess.CmdHouse(aCommandType: TKMGameInputCommandType; aHouse: TKMHouse; aItem, aAmountChange: Integer);
begin
  Assert(aCommandType in [gicHouseOrderProduct, gicHouseSchoolTrainChOrder]);
  TakeCommand(MakeCommand(aCommandType, aHouse.UID, aItem, aAmountChange));
end;


procedure TKMGameInputProcess.CmdHouse(aCommandType: TKMGameInputCommandType; aHouse: TKMHouse; aWareType: TKMWareType);
begin
  Assert(aCommandType in [gicHouseStoreNotAcceptFlag, gicHStoreNotAllowTakeOutFlag,
                          gicHouseStoreNotAcceptAllFlag, gicHStoreNotAllowTakeOutAllFlag,
                          gicHouseBarracksAcceptFlag, gicHBarracksNotAllowTakeOutFlag,
                          gicHouseBarracksAcceptAllFlag, gicHBarracksNotAllowTakeOutAllFlag,
                          gicHouseMarketFrom, gicHouseMarketTo, gicHouseArmorWSDeliveryToggle]);
  TakeCommand(MakeCommand(aCommandType, aHouse.UID, Byte(aWareType)));
end;


procedure TKMGameInputProcess.CmdHouse(aCommandType: TKMGameInputCommandType; aHouse: TKMHouse; aWoodcutterMode: TKMWoodcutterMode);
begin
  Assert(aCommandType = gicHouseWoodcutterMode);
  TakeCommand(MakeCommand(aCommandType, aHouse.UID, Byte(aWoodcutterMode)));
end;


procedure TKMGameInputProcess.CmdHouse(aCommandType: TKMGameInputCommandType; aHouse: TKMHouse; aUnitType: TKMUnitType; aCount: Integer);
begin
  Assert(aCommandType in [gicHouseSchoolTrain, gicHouseBarracksEquip, gicHouseTownHallEquip]);
  TakeCommand(MakeCommand(aCommandType, aHouse.UID, Byte(aUnitType), aCount));
end;


procedure TKMGameInputProcess.CmdHouse(aCommandType: TKMGameInputCommandType; aHouse: TKMHouse; aValue: Integer);
begin
  Assert(aCommandType in [gicHouseRemoveTrain, gicHouseSchoolTrainChLastUOrder, gicHouseTownHallMaxGold]);
  Assert((aHouse is TKMHouseSchool) or (aHouse is TKMHouseTownHall));
  TakeCommand(MakeCommand(aCommandType, aHouse.UID, aValue));
end;


procedure TKMGameInputProcess.CmdHouse(aCommandType: TKMGameInputCommandType; aHouse: TKMHouse; const aLoc: TKMPoint);
begin
  Assert((aCommandType = gicHouseBarracksRally) or (aCommandType = gicHouseTownHallRally) or (aCommandType = gicHouseWoodcuttersCutting));
  Assert((aHouse is TKMHouseBarracks) or (aHouse is TKMHouseTownHall) or (aHouse is TKMHouseWoodcutters));
  TakeCommand(MakeCommand(aCommandType, aHouse.UID, aLoc.X, aLoc.Y));
end;


procedure TKMGameInputProcess.CmdWareDistribution(aCommandType: TKMGameInputCommandType; aWare: TKMWareType; aHouseType: TKMHouseType; aValue:integer);
begin
  Assert(aCommandType = gicWareDistributionChange);
  TakeCommand(MakeCommand(aCommandType, Byte(aWare), Byte(aHouseType), aValue));
end;


procedure TKMGameInputProcess.CmdWareDistribution(aCommandType: TKMGameInputCommandType; const aTextParam: AnsiString);
begin
  Assert(aCommandType = gicWareDistributions);
  TakeCommand(MakeCommand(aCommandType, aTextParam));
end;


procedure TKMGameInputProcess.CmdConsoleCommand(aCommandType: TKMGameInputCommandType; const aAnsiTxtParam: AnsiString;
                                                const aUniTxtArray: TKMScriptCommandParamsArray);
begin
  Assert(aCommandType = gicScriptConsoleCommand);
  TakeCommand(MakeCommand(aCommandType, aAnsiTxtParam, aUniTxtArray));
end;


procedure TKMGameInputProcess.CmdGame(aCommandType: TKMGameInputCommandType; aDateTime: TDateTime);
begin
  Assert(aCommandType in [gicGameAutoSave, gicGameAutoSaveAfterPT, gicGameSaveReturnLobby]);
  TakeCommand(MakeCommand(aCommandType, aDateTime));
end;


procedure TKMGameInputProcess.CmdGame(aCommandType: TKMGameInputCommandType; aParam1, aParam2: Integer);
begin
  Assert(aCommandType in [gicGameTeamChange, gicGameHotkeySet]);
  TakeCommand(MakeCommand(aCommandType, aParam1, aParam2));
end;


procedure TKMGameInputProcess.CmdGame(aCommandType: TKMGameInputCommandType; aValue: Integer);
begin
  Assert(aCommandType in [gicGameMessageLogRead, gicGameMessageListRead, gicGamePlayerDefeat, gicGameLoadSave]);
  TakeCommand(MakeCommand(aCommandType, aValue));
end;


procedure TKMGameInputProcess.CmdGameBeacon(const aLocF: TKMPointF; aOwner: TKMHandID; aColor: Cardinal);
begin
  TakeCommand(MakeCommandSmI(gicGameAlertBeacon, Integer(aColor and $FFFFFF), Round(aLocF.X * 10), Round(aLocF.Y * 10), aOwner));
end;


procedure TKMGameInputProcess.CmdGame(aCommandType: TKMGameInputCommandType; aValue: Single);
begin
  Assert(aCommandType = gicGameSpeed);
  TakeCommand(MakeCommandNoHand(aCommandType, aValue));
end;


procedure TKMGameInputProcess.CmdPlayerAllianceSet(aForPlayer, aToPlayer: TKMHandID; aAllianceType: TKMAllianceType);
begin
  TakeCommand(MakeCommand(gicGamePlayerAllianceSet, aForPlayer, aToPlayer, Byte(aAllianceType)));
end;


procedure TKMGameInputProcess.CmdPlayerAddDefaultGoals(aPlayer: TKMHandID; aBuilding: Boolean);
begin
  TakeCommand(MakeCommand(gicGamePlayerAddDefGoals, aPlayer, Byte(aBuilding)));
end;


procedure TKMGameInputProcess.CmdPlayerChanged(aPlayer: TKMHandID; aPlayerNickname: AnsiString; aType: TKMHandType; aAIType: TKMAIType);
begin
  Assert(ReplayState = gipRecording);
  TakeCommand(MakeCommand(gicGamePlayerChange, aPlayerNickname, aPlayer, Byte(aType), Byte(aAIType)));
end;


procedure TKMGameInputProcess.CmdScriptSoundRemoveRequest(aScriptSoundUID: Integer);
begin
  TakeCommand(MakeCommand(gicScriptSoundRemoveRq, aScriptSoundUID));
end;


procedure TKMGameInputProcess.CmdTemp(aCommandType: TKMGameInputCommandType; const aLoc: TKMPoint);
begin
  Assert(aCommandType = gicTempAddScout);
  TakeCommand(MakeCommand(aCommandType, aLoc.X, aLoc.Y));
end;


procedure TKMGameInputProcess.CmdTemp(aCommandType: TKMGameInputCommandType);
begin
  Assert(aCommandType in [gicTempRevealMap, gicTempVictory, gicTempDefeat, gicTempDoNothing]);
  TakeCommand(MakeCommand(aCommandType));
end;


procedure TKMGameInputProcess.SaveToStream(SaveStream: TKMemoryStream);
var
  I, K: Integer;
begin
  SaveStream.WriteA(GAME_REVISION);
  SaveStream.Write(fCount);

  SaveExtra(SaveStream);

  if SaveStream is TKMemoryStreamText then
    for I := 1 to fCount do
    begin
      if SaveStream is TKMemoryStreamText then
        SaveStream.PlaceMarker(GetEnumName(TypeInfo(TKMGameInputCommandType), Integer(fQueue[I].Command.CmdType)));

      SaveStream.Write(fQueue[I].Tick);
      SaveStream.Write(fQueue[I].Rand);
      SaveStream.Write(fQueue[I].Command.CmdType, SizeOf(fQueue[I].Command.CmdType));
      SaveStream.Write(fQueue[I].Command.HandID, SizeOf(fQueue[I].Command.HandID));
      for K := 0 to GIC_PACKED_DATA_SIZE - 1 do
        SaveStream.Write(fQueue[I].Command.Data.Bytes[K]);
    end
  else
    SaveStream.Write(fQueue[0], SizeOf(fQueue[0])*(fCount + 1));
end;


procedure TKMGameInputProcess.SaveToFileAsText(const aFileName: UnicodeString);
var
  S: TKMemoryStreamText;
begin
  S := TKMemoryStreamText.Create;
  try
    SaveToStream(S);
    S.SaveToFile(aFileName);
  finally
    S.Free;
  end;
end;


procedure TKMGameInputProcess.SaveToFile(const aFileName: UnicodeString);
var
  S: TKMemoryStream;
begin
  S := TKMemoryStreamBinary.Create;
  try
    SaveToStream(S);
    S.SaveToFileCompressed(aFileName, 'GIPCompressed');
  finally
    S.Free;
  end;
end;


procedure TKMGameInputProcess.SaveToFileAsync(const aFileName: UnicodeString; aWorkerThread: TKMWorkerThread);
var
  S: TKMemoryStream;
begin
  S := TKMemoryStreamBinary.Create;
  SaveToStream(S);
  AsyncSaveToFileCompressedAndFree(S, aFileName, 'GIPCompressed', aWorkerThread);
end;


procedure TKMGameInputProcess.LoadFromStream(LoadStream: TKMemoryStream);
var
  fileVersion: AnsiString;
begin
  LoadStream.ReadA(fileVersion);
  //We could allow to load unsupported version files
  Assert(ALLOW_LOAD_UNSUP_VERSION_SAVE or (fileVersion = GAME_REVISION),
         'Old or unexpected replay file. ' + UnicodeString(GAME_REVISION) + ' is required.');

  LoadStream.Read(fCount);
  SetLength(fQueue, fCount + 1);

  LoadExtra(LoadStream);

  LoadStream.Read(fQueue[0], SizeOf(fQueue[0])*(fCount + 1));
end;


procedure TKMGameInputProcess.LoadFromFile(const aFileName: UnicodeString);
var
  S: TKMemoryStream;
begin
  if not FileExists(aFileName) then Exit;

  S := TKMemoryStreamBinary.Create;
  try
    S.LoadFromFileCompressed(aFileName, 'GIPCompressed');
    LoadFromStream(S);
  finally
    S.Free;
  end;
end;


{ Return last recorded tick }
function TKMGameInputProcess.GetLastTick: Cardinal;
begin
  Result := fQueue[fCount].Tick;
end;


{ See if replay has ended (no more commands in queue) }
function TKMGameInputProcess.ReplayEnded: Boolean;
begin
  Result := (ReplayState = gipReplaying) and (fCursor > fCount);
end;


//Store commands for the replay
//While in replay there are no commands to process, but for debug we might allow ChangePlayer
procedure TKMGameInputProcess.StoreCommand(const aCommand: TKMGameInputCommand);

  procedure EnlargeQueue;
  begin
    Inc(fCount);
    if Length(fQueue) <= fCount then SetLength(fQueue, fCount + 128);
  end;

var
  I: Integer;
begin
  if ReplayState = gipReplaying then
    Exit;

  Assert(ReplayState = gipRecording);

  fGic2StoredConverter.GicToStoredCommands(aCommand, fStoredCommands);

  for I := 0 to fStoredCommands.Count - 1 do
  begin
    EnlargeQueue;
    fQueue[fCount].Command := fStoredCommands[I];
    fQueue[fCount].Tick := gGameParams.Tick;
    fQueue[fCount].Rand := 0;
  end;

  // Random check is made only for the last stored command
  //----------------------------------------------------------
  //Skip random check generation. We do not want KaMRandom to be called here
  if SKIP_RNG_CHECKS_FOR_SOME_GIC and (aCommand.CommandType in SKIP_RANDOM_CHECKS_FOR) then
    fQueue[fCount].Rand := 0
  else
    //This will be our check to ensure everything is consistent
    fQueue[fCount].Rand := Cardinal(KaMRandom(MaxInt{$IFDEF RNG_SPY}, 'TKMGameInputProcess.StoreCommand'{$ENDIF}));
end;


procedure TKMGameInputProcess.ReplayTimer(aTick: Cardinal);
begin
end;


procedure TKMGameInputProcess.RunningTimer(aTick: Cardinal);
begin
end;


procedure TKMGameInputProcess.TakePlannedCommands;
var
  I: Integer;
begin
  if Self = nil then Exit;
  if fPlannedCommands.Count = 0 then Exit;

  // Take all planned commands
  for I := 0 to fPlannedCommands.Count - 1 do
    DoTakeCommand(fPlannedCommands[I]);

  // And clear
  fPlannedCommands.Clear;
end;


procedure TKMGameInputProcess.UpdateState(aTick: Cardinal);
begin
  //Only used in GIP_Multi
end;


function TKMGameInputProcess.IsLastTickValueCorrect(aLastTickValue: Cardinal): Boolean;
begin
  Result := aLastTickValue <> NO_LAST_TICK_VALUE;
end;


procedure TKMGameInputProcess.SaveExtra(SaveStream: TKMemoryStream);
begin
  SaveStream.Write(Cardinal(NO_LAST_TICK_VALUE));
end;


procedure TKMGameInputProcess.LoadExtra(LoadStream: TKMemoryStream);
var
  Tmp: Cardinal;
begin
  LoadStream.Read(Tmp); //Just read some bytes from the stream
  //Only used in GIP_Single
end;


function TKMGameInputProcess.QueueToString: String;
const
  MAX_ITEMS_CNT = 100;
var
  I, K, maxIndex: Integer;
begin
  if Self = nil then Exit('');

  if fReplayState = gipRecording then
    maxIndex := fCount
  else
    maxIndex := Min(fCount, fCursor);

  Result := '';
  K := 0;
  for I := maxIndex downto 1 do
  begin
    if not DoSkipLogCommand(fQueue[I].Command.CmdType) then
    begin
      Inc(K);
      Result := Result + StoredGIPCommandToString(fQueue[I]) + '|';
    end;
    if K > MAX_ITEMS_CNT then
      Break;
  end;
end;


procedure TKMGameInputProcess.Paint;
const
  GIP_FONT = fntMonospaced;
var
  W: Integer;
  str: string;
  textSize: TKMPoint;
begin
  if Self = nil then Exit;
  if not SHOW_GIP then Exit;

  str := QueueToString;

  if str = '' then Exit;

  textSize := gRes.Fonts[GIP_FONT].GetTextSize(str, False, False, FONT_TAB_WIDTH);

  W := gGame.ActiveInterface.MyControls.MasterPanel.Width;

  TKMRenderUI.WriteBevel(W - textSize.X - 10, 0, textSize.X + 10, textSize.Y + 10);
  TKMRenderUI.WriteText(W - textSize.X - 5, 0, 0, str, GIP_FONT, taLeft, icWhite, False, False, False, FONT_TAB_WIDTH);
end;


function TKMGameInputProcess.StoredGIPCommandToString(const aCommand: TKMStoredGIPCommand): String;
var
  I: Integer;
  str: string;
begin
  str := GICHeaderToString(aCommand.Command.CmdType, aCommand.Command.HandId);

  if SHOW_GIP_AS_BYTES then
  begin
    for I := 0 to GIC_PACKED_DATA_SIZE - 1 do
      str := Format('%s%4d', [str, aCommand.Command.Data.Bytes[I]]);
  end
  else
    str := Format('%s%s', [str, aCommand.Command.DataToString]);

  Result := Format('Tick %6d Rand %10d Cmd: %s', [aCommand.Tick, aCommand.Rand, str]);
end;


function GetGICCommandTypeMaxLength: Byte;
begin
  Result := 0;
  for var I := Low(TKMGameInputCommandType) to High(TKMGameInputCommandType) do
    Result := Max(Result, Length(GetEnumName(TypeInfo(TKMGameInputCommandType), Ord(I))));
end;


{ TKMGameInputCommandPacked }
procedure TKMGameInputCommandPacked.ClearData;
begin
  FillChar(Data, GIC_PACKED_DATA_SIZE, #0);
end;


function TKMGameInputCommandPacked.DataToString: string;
begin
  {$WARN IMPLICIT_STRING_CAST OFF} // We don't care about Ansistring casting here
  case COMMAND_PACK_TYPES[CmdType] of
    gicpt_NoParams:   Result := Result + ' []';
    gicpt_Int1:       Result := Result + Format('[%10d]', [Data.Integers[0]]);
    gicpt_Int2:       Result := Result + Format('[%10d,%10d]', [Data.Integers[0], Data.Integers[1]]);
    gicpt_Int3:       Result := Result + Format('[%10d,%10d,%10d]', [Data.Integers[0], Data.Integers[1], Data.Integers[2]]);
    gicpt_Int1Word3:  Result := Result + Format('[%10d,%10d,%10d,%10d]', [Data.Integers[0], Data.Words[2], Data.Words[3], Data.Words[4]]);
    gicpt_Int1SmInt3: Result := Result + Format('[%10d,%10d,%10d,%10d]', [Data.Integers[0], Data.SmallInts[2], Data.SmallInts[3], Data.SmallInts[4]]);
    gicpt_AnsiStr1:   Result := Result + Format('[%s]', [ReplaceStr(Data.AsAnsiString(0), #0, '#')]);
    gicpt_Ansi1Int2:  Result := Result + Format('[%s]', [ReplaceStr(Data.AsAnsiString(0), #0, '#')]);
    gicpt_Ansi1Int3:  Result := Result + Format('[%s]', [ReplaceStr(Data.AsAnsiString(0), #0, '#')]);
    gicpt_UniStr1:    Result := Result + Format('[%s]', [ReplaceStr(Data.AsUnicodeString(0), #0, '#')]);
    gicpt_Float:      Result := Result + Format('[%f]', [Data.Singles[0]]);
    gicpt_Ansi1Uni4:  Result := Result + Format('[%s]', [ReplaceStr(Data.AsAnsiString(0), #0, '#')]);
    gicpt_Date:       Result := Result + Format('[%s]', [FormatDateTime('dd.mm.yy hh:nn:ss.zzz', Data.DateT)]);
  end;
  {$WARN IMPLICIT_STRING_CAST ON}
end;


{ TKMGicDataPacked }
function TKMGicDataPacked.AsAnsiString(aStartByte: Integer): AnsiString;
begin
  if aStartByte >= GIC_PACKED_DATA_SIZE then Exit('');

  SetString(Result, PAnsiChar(@Bytes[aStartByte]), GIC_PACKED_DATA_SIZE - aStartByte);
end;


function TKMGicDataPacked.AsUnicodeString(aStartByte: Integer): UnicodeString;
begin
  if aStartByte >= GIC_PACKED_DATA_SIZE then Exit('');

  SetString(Result, PWideChar(@Bytes[aStartByte*2]), (GIC_PACKED_DATA_SIZE - aStartByte) div 2);
end;


{ TKMGicAndStoredConverter }
constructor TKMGic2StoredConverter.Create;
begin
  inherited;

  Reset;
end;


procedure TKMGic2StoredConverter.Reset;
begin
  fAnsiStrBuf := '';
  fUnicodeStrBuf := '';
  fStrParamsParsed := 0;
  fWaitForNextCommand := False;
  fReadyToParseNewCommand := True;
end;


procedure TKMGic2StoredConverter.CommandParseCompleted;
begin
  Reset;
end;


// Parse Next stored GIC command. GIC command could be saved in the number of stored commands, because of variant length of Ansi/Unicode string parameters
function TKMGic2StoredConverter.ParseNextStoredPackedCommand(const aStoredCmd: TKMGameInputCommandPacked; var aGicCommand: TKMGameInputCommand): Boolean;

  function TryFindAnsiBufEnd(var aString: AnsiString): Boolean;
  var
    endStr: Integer;
  begin
    Result := True;
    {$WARN IMPLICIT_STRING_CAST OFF} // We don't care about Ansistring casting here. Pos(#0, fAnsiStrBuf) works just fine
    endStr := Pos(#0, fAnsiStrBuf);
    {$WARN IMPLICIT_STRING_CAST ON}
    if endStr > 0 then
    begin
      aString := Copy(fAnsiStrBuf, 1, endStr - 1);
      Result := False;
    end;
  end;

  function TryFindUnicodeBufEnd(var aString: UnicodeString): Boolean;
  var
    endStr: Integer;
  begin
    Result := True;
    endStr := Pos(#0, fUnicodeStrBuf);
    if endStr > 0 then
    begin
      aString := Copy(fUnicodeStrBuf, 1, endStr - 1);
      Result := False;
    end;
  end;

  function ReadParamsAndAnsiStr(var aAnsiString: AnsiString; aParamsCnt: Integer): Boolean;
  var
    I: Integer;
  begin
    with aGicCommand do
      with aStoredCmd do
      begin
        if fWaitForNextCommand then
        begin
          fAnsiStrBuf := fAnsiStrBuf + Data.AsAnsiString(0);

          fWaitForNextCommand := TryFindAnsiBufEnd(aAnsiString);
        end
        else
        begin
          fAnsiStrBuf := '';
          for I := 0 to aParamsCnt - 1 do
            IntParams[I] := Data.Integers[I];

          fAnsiStrBuf := Data.AsAnsiString(aParamsCnt*SizeOf(IntParams[0]));

          fWaitForNextCommand := TryFindAnsiBufEnd(aAnsiString);
        end;
      end;

    Result := not fWaitForNextCommand;
    if Result then
      Inc(fStrParamsParsed);
  end;

  function ReadParamsAndUnicodeStr(var aUnicodeStr: UnicodeString; aParamsCnt: Integer): Boolean;
  var
    I: Integer;
  begin
    with aGicCommand do
      with aStoredCmd do
      begin
        if fWaitForNextCommand then
        begin
          fUnicodeStrBuf := fUnicodeStrBuf + Data.AsUnicodeString(0);

          fWaitForNextCommand := TryFindUnicodeBufEnd(aUnicodeStr);
        end
        else
        begin
          fUnicodeStrBuf := '';
          for I := 0 to aParamsCnt - 1 do
            IntParams[I] := Data.Integers[I];

          fUnicodeStrBuf := Data.AsUnicodeString(aParamsCnt*SizeOf(IntParams[0]));

          fWaitForNextCommand := TryFindUnicodeBufEnd(aUnicodeStr);
        end;
      end;

    Result := not fWaitForNextCommand;
    if Result then
      Inc(fStrParamsParsed);
  end;

var
  I: Integer;
begin
  Result := True;

  // Clear gicCommand only if we ready to parse next command
  if fReadyToParseNewCommand then
  begin
    aGicCommand.Clear;
    fReadyToParseNewCommand := False;
  end;

  with aGicCommand do
    with aStoredCmd do
    begin
      CommandType := CmdType;
      HandIndex := HandID;

      case COMMAND_PACK_TYPES[CmdType] of
        gicpt_NoParams:   ;
        gicpt_Int1:       IntParams[0] := Data.Integers[0];
        gicpt_Int2:       for I := 0 to 1 do
                            IntParams[I] := Data.Integers[I];
        gicpt_Int3:       for I := 0 to 2 do
                            IntParams[I] := Data.Integers[I];
        gicpt_Int1Word3:  begin
                            IntParams[0] := Data.Integers[0];
                            for I := 0 to 2 do
                              WordParams[I] := Data.Words[I+2];
                          end;
        gicpt_Int1SmInt3: begin
                            IntParams[0] := Data.Integers[0];
                            for I := 0 to 2 do
                              SmallIntParams[I] := Data.SmallInts[I+2];
                          end;
        gicpt_AnsiStr1:   Result := ReadParamsAndAnsiStr(aGicCommand.AnsiStrParam, 0);
        gicpt_Ansi1Int2:  Result := ReadParamsAndAnsiStr(aGicCommand.AnsiStrParam, 2);
        gicpt_Ansi1Int3:  Result := ReadParamsAndAnsiStr(aGicCommand.AnsiStrParam, 3);
        gicpt_Float:      FloatParam := Data.Singles[0];
        gicpt_UniStr1:    Result := ReadParamsAndUnicodeStr(aGicCommand.UnicodeStrParams[0], 0);
        gicpt_Ansi1Uni4:  begin
                            // Check how many params we parsed and what is the enxt param to parse
                            case fStrParamsParsed of
                              0:    ReadParamsAndAnsiStr(aGicCommand.AnsiStrParam, 0);
                              1..4: ReadParamsAndUnicodeStr(aGicCommand.UnicodeStrParams[fStrParamsParsed - 1], 0);
                            end;
                            Result := ( fStrParamsParsed = 5 ); // We parsed all 5 parameters
                          end;
        gicpt_Date:       DateTimeParam := Data.DateT;
      else
        raise Exception.Create('Unknown gic command type');
      end;
    end;

  if Result then
    CommandParseCompleted;
end;


// Convert GIC command into 1 or several stored commands
procedure TKMGic2StoredConverter.GicToStoredCommands(const aGicCommand: TKMGameInputCommand; aStoredCommands: TKMStoredGicPackedList);

  procedure AddStoredGic(aStoredGic: TKMGameInputCommandPacked; const aGic: TKMGameInputCommand);
  begin
    aStoredGic.CmdType := aGic.CommandType;
    aStoredGic.HandID := aGic.HandIndex;
    aStoredCommands.Add(aStoredGic);
  end;

  procedure AddAnsiString(const aAnsiStr: AnsiString; var aStoredGic: TKMGameInputCommandPacked; aStrIndex, aCmdByteIndex: Integer);
  var
    ansiStr: AnsiString;
  begin
    ansiStr := aAnsiStr + #0;
    repeat
      if aCmdByteIndex = GIC_PACKED_DATA_SIZE then
      begin
        AddStoredGic(aStoredGic, aGicCommand);
        aStoredGic.ClearData;
        aCmdByteIndex := 0;
      end;

      aStoredGic.Data.AnsiChars[aCmdByteIndex] := ansiStr[aStrIndex + 1];

      Inc(aStrIndex);
      Inc(aCmdByteIndex);
    until ansiStr[aStrIndex] = #0;

    AddStoredGic(aStoredGic, aGicCommand);
  end;

  procedure AddUnicodeString(const aUnicodeStr: UnicodeString; var aStoredGic: TKMGameInputCommandPacked; aStrIndex, aCmdByteIndex: Integer);
  var
    unicodeStr: UnicodeString;
  begin
    unicodeStr := aUnicodeStr + #0;
    repeat
      if aCmdByteIndex = (GIC_PACKED_DATA_SIZE div 2) then
      begin
        AddStoredGic(aStoredGic, aGicCommand);
        aStoredGic.ClearData;
        aCmdByteIndex := 0;
      end;

      aStoredGic.Data.WideChars[aCmdByteIndex] := unicodeStr[aStrIndex + 1];

      Inc(aStrIndex);
      Inc(aCmdByteIndex);
    until unicodeStr[aStrIndex] = #0;

    AddStoredGic(aStoredGic, aGicCommand);
  end;

  procedure AddStoredWithParams(aParamsCnt: Integer; var aStoredGic: TKMGameInputCommandPacked);
  var
    I: Integer;
  begin
    with aGicCommand do
      for I := 0 to aParamsCnt - 1 do
        aStoredGic.Data.Integers[I] := IntParams[I];

    AddStoredGic(aStoredGic, aGicCommand);
  end;

  procedure AddStoredWithParamsAndAnsi(aParamsCnt: Integer; const aAnsiStr: AnsiString; var aStoredGic: TKMGameInputCommandPacked);
  var
    I: Integer;
  begin
    aStoredGic.ClearData;
    with aGicCommand do
      for I := 0 to aParamsCnt - 1 do
        aStoredGic.Data.Integers[I] := IntParams[I];

    AddAnsiString(aAnsiStr, aStoredGic, 0, aParamsCnt*SizeOf(aGicCommand.IntParams[0]));
  end;

var
  I: Integer;
  storedGic: TKMGameInputCommandPacked;
begin
  aStoredCommands.Clear;
  storedGic.ClearData;
  with aGicCommand do
  begin
    case COMMAND_PACK_TYPES[CommandType] of
      gicpt_NoParams:   AddStoredGic(storedGic, aGicCommand);
      gicpt_Int1:       AddStoredWithParams(1, storedGic);
      gicpt_Int2:       AddStoredWithParams(2, storedGic);
      gicpt_Int3:       AddStoredWithParams(3, storedGic);
      gicpt_Int1Word3:  begin
                          storedGic.Data.Integers[0] := IntParams[0];
                          for I := 0 to 2 do
                            storedGic.Data.Words[I+2] := WordParams[I];

                          AddStoredGic(storedGic, aGicCommand);
                        end;
      gicpt_Int1SmInt3: begin
                          storedGic.Data.Integers[0] := IntParams[0];
                          for I := 0 to 2 do
                            storedGic.Data.SmallInts[I+2] := SmallIntParams[I];

                          AddStoredGic(storedGic, aGicCommand);
                        end;
      gicpt_AnsiStr1:   AddAnsiString(aGicCommand.AnsiStrParam, storedGic, 0, 0);
      gicpt_Ansi1Int2:  AddStoredWithParamsAndAnsi(2, aGicCommand.AnsiStrParam, storedGic);
      gicpt_Ansi1Int3:  AddStoredWithParamsAndAnsi(3, aGicCommand.AnsiStrParam, storedGic);
      gicpt_Float:      begin
                          storedGic.Data.Singles[0] := FloatParam;
                          AddStoredGic(storedGic, aGicCommand);
                        end;
      gicpt_UniStr1:    AddUnicodeString(aGicCommand.UnicodeStrParams[0], storedGic, 0, 0);
      gicpt_Ansi1Uni4:  begin
                          AddAnsiString(aGicCommand.AnsiStrParam, storedGic, 0, 0);
                          for I := 0 to 3 do
                          begin
                            storedGic.ClearData; //Clear data before next param to be parsed
                            AddUnicodeString(aGicCommand.UnicodeStrParams[I], storedGic, 0, 0);
                          end;
                        end;
      gicpt_Date:       begin
                          storedGic.Data.DateT := aGicCommand.DateTimeParam;
                          AddStoredGic(storedGic, aGicCommand);
                        end;
    else
      raise Exception.Create('Unknown gic command type');
    end;
  end;
end;


{ TKMGameInputCommand }
procedure TKMGameInputCommand.Clear;
var
  I: Integer;
begin
  CommandType := gicNone;
  HandIndex := 0;
  FillChar(IntParams, SizeOf(IntParams), #0);
  FillChar(WordParams, SizeOf(WordParams), #0);
  FillChar(SmallIntParams, SizeOf(SmallIntParams), #0);
  FillChar(FloatParam, SizeOf(FloatParam), #0);
  AnsiStrParam := '';
  for I := 0 to High(UnicodeStrParams) do
    UnicodeStrParams[I] := '';

  FillChar(DateTimeParam, SizeOf(DateTimeParam), #0);
end;


initialization
begin
  GIC_COMMAND_TYPE_MAX_LENGTH := GetGICCommandTypeMaxLength;
end;


end.

