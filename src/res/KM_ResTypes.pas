unit KM_ResTypes;
{$I KaM_Remake.inc}
interface
uses
  KM_ResTilesetTypes;

type
  TKMChopableAge = (caAge1, caAge2, caAge3, caAgeFull, caAgeFall, caAgeStump);
  TKMChopableAgeSet = set of TKMChopableAge;

  //* Ware type
  TKMWareType = (
    wtNone,
    wtTrunk,    wtStone,         wtTimber,     wtIronOre,      wtGoldOre,
    wtCoal,     wtIron,          wtGold,       wtWine,         wtCorn,
    wtBread,    wtFlour,         wtLeather,    wtSausage,      wtPig,
    wtSkin,     wtWoodenShield,  wtIronShield, wtLeatherArmor, wtIronArmor,
    wtAxe,      wtSword,         wtLance,      wtPike,         wtBow,
    wtCrossbow, wtHorse,         wtFish,

    // Special ware types
    wtAll, wtWarfare, wtFood
  );

  //* Ware type set
  TKMWareTypeSet = set of TKMWareType;

const
  WARE_MIN = wtTrunk;
  WARE_MAX = wtFish;
  WARFARE_MIN = wtWoodenShield;
  WEAPON_MIN = wtWoodenShield;
  WEAPON_MAX = wtCrossbow;
  WARFARE_MAX = wtHorse;

  WARES_VALID = [WARE_MIN..WARE_MAX];
  WARES_WARFARE = [WARFARE_MIN..WARFARE_MAX];
  WARES_FOOD = [wtWine, wtBread, wtSausage, wtFish];

  WARE_CNT = Integer(WARE_MAX) - Integer(WARE_MIN) + 1;
  WARFARE_CNT = Integer(WARFARE_MAX) - Integer(WEAPON_MIN) + 1;

  WARFARE_IRON = [wtIronShield, wtIronArmor, wtSword, wtPike, wtCrossbow];


type
  //* House type
  TKMHouseType = (
    htNone, htAny,
    htArmorSmithy,     htArmorWorkshop,   htBakery,        htBarracks,      htButchers,
    htCoalMine,        htFarm,            htFishermans,    htGoldMine,      htInn,
    htIronMine,        htIronSmithy,      htMarket,        htMetallurgists, htMill,
    htQuarry,          htSawmill,         htSchool,        htSiegeWorkshop, htStables,
    htStore,           htSwine,           htTannery,       htTownHall,      htWatchTower,
    htWeaponSmithy,    htWeaponWorkshop,  htVineyard,      htWoodcutters
  );

  //* House type set
  TKMHouseTypeSet = set of TKMHouseType;
  TKMHouseTypeArray = array of TKMHouseType;


  TKMKeyFunction = (
    kfNone,

    // faCommon
    kfScrollLeft,   // Scroll Left
    kfScrollRight,  // Scroll Right
    kfScrollUp,     // Scroll Up
    kfScrollDown,   // Scroll Down

    kfMapDragScroll, // Map drag scroll

    kfZoomIn,     // Zoom In
    kfZoomOut,    // Zoom Out
    kfZoomReset,  // Reset Zoom

    kfCloseMenu,  // Close opened menu

    kfMusicPrevTrack,   // Music previous track
    kfMusicNextTrack,   // Music next track
    kfMusicDisable,     // Music disable
    kfMusicShuffle,     // Music shuffle
    kfMusicVolumeUp,    // Music volume up
    kfMusicVolumeDown,  // Music volume down
    kfMusicMute,        // Music mute

    kfSoundVolumeUp,    // Sound volume up
    kfSoundVolumeDown,  // Sound volume down
    kfSoundMute,        // Sound mute

    kfMuteAll,          // Mute music and sound

    kfDebugWindow,    // Debug window
    kfDebugRevealmap, // Debug Menu Reveal Map
    kfDebugVictory,   // Debug Menu Victory
    kfDebugDefeat,    // Debug Menu Defeat
    kfDebugAddscout,  // Debug Menu Add Scout

    // faGame
    kfMenuBuild,  // Build Menu
    kfMenuRatio,  // Ratio Menu
    kfMenuStats,  // Stats Menu
    kfMenuMenu,   // Main Menu

    kfSpeedup1, // Speed up 1
    kfSpeedup2, // Speed up 2
    kfSpeedup3, // Speed up 3
    kfSpeedup4, // Speed up 4

    kfBeacon,     // Beacon
    kfPause,      // Pause
    kfShowTeams,  // Show teams in MP

    kfCenterAlert,  // Center to alert
    kfDeleteMsg,    // Delete message
    kfChat,         // Show the chat

    kfNextEntitySameType,  // Select next building/unit with same type
    kfPlayerColorMode,     // Switch player color mode

    kfPlanRoad,   // Plan road
    kfPlanField,  // Plan field
    kfPlanWine,   // Plan wine
    kfErasePlan,  // Erase plan

    kfSelect1,  // Select 1
    kfSelect2,  // Select 2
    kfSelect3,  // Select 3
    kfSelect4,  // Select 4
    kfSelect5,  // Select 5
    kfSelect6,  // Select 6
    kfSelect7,  // Select 7
    kfSelect8,  // Select 8
    kfSelect9,  // Select 9
    kfSelect10, // Select 10
    kfSelect11, // Select 11
    kfSelect12, // Select 12
    kfSelect13, // Select 13
    kfSelect14, // Select 14
    kfSelect15, // Select 15
    kfSelect16, // Select 16
    kfSelect17, // Select 17
    kfSelect18, // Select 18
    kfSelect19, // Select 19
    kfSelect20, // Select 20

    // faUnit
    kfArmyHalt,       // Halt Command
    kfArmySplit,      // Split up Command
    kfArmyLink,       // Linkup Command
    kfArmyFood,       // Food Command
    kfArmyStorm,      // Storm Command
    kfArmyAddLine,    // Formation Increase Line Command
    kfArmyDelLine,    // Formation Shrink Line Command
    kfArmyRotateCw,   // Turn Right Command
    kfArmyRotateCcw,  // Turn Left Command

    // faHouse
    kfTrainGotoPrev,  // Goto previuos unit
    kfTrainEquipUnit, // Train or Equip unit
    kfTrainGotoNext,  // Goto next unit

    // faSpecReplay
    kfSpecpanelSelectDropbox, // Select dropbox on spectator panel
    kfReplayPlayNextTick,     // Play next tick in replay
    kfSpectatePlayer1,  // Spectate player 1
    kfSpectatePlayer2,  // Spectate player 2
    kfSpectatePlayer3,  // Spectate player 3
    kfSpectatePlayer4,  // Spectate player 4
    kfSpectatePlayer5,  // Spectate player 5
    kfSpectatePlayer6,  // Spectate player 6
    kfSpectatePlayer7,  // Spectate player 7
    kfSpectatePlayer8,  // Spectate player 8
    kfSpectatePlayer9,  // Spectate player 9
    kfSpectatePlayer10, // Spectate player 10
    kfSpectatePlayer11, // Spectate player 11
    kfSpectatePlayer12, // Spectate player 12

    // faMapEdit
    kfMapedExtra,     // Maped Extra's menu
    kfMapedTerrain,   // Maped Terrain Editing
    kfMapedVillage,   // Maped Village Planning
    kfMapedVisual,    // Maped Visual Scripts
    kfMapedGlobal,    // Maped Global Scripting
    kfMapedMainMenu,  // Maped Main Menu
    kfMapedSubMenu1,  // Maped Sub-menu 1
    kfMapedSubMenu2,  // Maped Sub-menu 2
    kfMapedSubMenu3,  // Maped Sub-menu 3
    kfMapedSubMenu4,  // Maped Sub-menu 4
    kfMapedSubMenu5,  // Maped Sub-menu 5
    kfMapedSubMenu6,  // Maped Sub-menu 6
    kfMapedSubMenuAction1,  // Maped Sub-menu Action 1
    kfMapedSubMenuAction2,  // Maped Sub-menu Action 2
    kfMapedSubMenuAction3,  // Maped Sub-menu Action 3
    kfMapedSubMenuAction4,  // Maped Sub-menu Action 4
    kfMapedSubMenuAction5,  // Maped Sub-menu Action 5
    kfMapedSubMenuAction6,  // Maped Sub-menu Action 6
    kfMapedSubMenuAction7,  // Maped Sub-menu Action 6
    kfMapedObjPalette,      // Maped Objects palette
    kfMapedTilesPalette,    // Maped Tiles palette
    kfMapedUnivErasor,      // Maped Universal erasor
    kfMapedPaintBucket,     // Maped Paint bucket
    kfMapedHistory          // Maped History
  );

  TKMKeyFunctionSet = set of TKMKeyFunction;

  TKMKeyFuncArea = (faCommon,
                      faGame,
                        faUnit,
                        faHouse,
                      faSpecReplay,
                      faMapEdit);

  TKMKeyFuncAreaSet = set of TKMKeyFuncArea;

const
  KEY_FUNC_LOW = Succ(kfNone); // 1st key function

  KEY_FUNCS_ALL = [KEY_FUNC_LOW..High(TKMKeyFunction)];

type
  // Cursors
  TKMCursor = (
    kmcDefault, kmcInfo, kmcAttack, kmcJoinYes, kmcJoinNo, kmcEdit, kmcDragUp,
    kmcDir0, kmcDir1, kmcDir2, kmcDir3, kmcDir4, kmcDir5, kmcDir6, kmcDir7, kmcDirNA,
    kmcScroll0, kmcScroll1, kmcScroll2, kmcScroll3, kmcScroll4, kmcScroll5, kmcScroll6, kmcScroll7,
    kmcBeacon, kmcDrag,
    kmcInvisible, // for some reason kmcInvisible should be at its current position in enum. Otherwise 1px dot will appear while TroopSelection is on
    kmcPaintBucket,
    kmcAnimatedDirSelector
  );

const
  // Indexes of cursor images in GUI.RX
  CURSOR_SPRITE_INDEX: array [TKMCursor] of Word = (
    1, 452, 457, 460, 450, 453, 449,
    511,  512, 513, 514, 515, 516, 517, 518, 519,
    4, 7, 3, 9, 5, 8, 2, 6,
    456, 451, 999, 661, 0);

type
  TRXUsage = (ruMenu, ruGame, ruCustom); //Where sprites are used

  TSpriteAtlasType = (saBase, saMask);

  TRXInfo = record
    FileName: string; //Used for logging and filenames
    TeamColors: Boolean; //sprites should be generated with color masks
    Usage: TRXUsage; //Menu and Game sprites are loaded separately
    LoadingTextID: Word;
  end;

  TKMGenTerrainInfo = record
    TerKind: TKMTerrainKind;
    Mask: TKMMaskFullType;
  end;

// ResSprites Types
type
  TRXType = (
    rxTrees,
    rxHouses,
    rxUnits,
    rxGui,
    rxGuiMain,
    rxCustom, //Used for loading stuff like campaign maps (there is no main RXX file)
    rxTiles //Tiles
    );

const
  //Colors to paint beneath player color areas (flags)
  //The blacker/whighter - the more contrast player color will be
  FLAG_COLOR_DARK = $FF101010;   //Dark-grey (Black)
  FLAG_COLOR_LITE = $FFFFFFFF;   //White

type
  TRXData = record
    Count: Integer;
    Flag: array of Byte; //Sprite is valid
    Size: array of record X,Y: Word; end;
    Pivot: array of record X,Y: SmallInt; end;
    SizeNoShadow: array of record left,top,right,bottom: SmallInt; end; //Image object (without shadow) rect in the image sizes
    Data: array of array of Byte; //Used for RXX utils (Packer / Editor)
    RGBA: array of array of Cardinal; //Expanded image
    Mask: array of array of Byte; //Mask for team colors
    HasMask: array of Boolean; //Flag if Mask for team colors is used
  end;
  PRXData = ^TRXData;

  TKMSoftenShadowType = (sstNone, sstOnlyShadow, sstBoth);

const
  {$I KM_TextIDs.inc}

var
  RXInfo: array [TRXType] of TRXInfo = (
    (FileName: 'Trees';      TeamColors: False; Usage: ruGame;   LoadingTextID: TX_MENU_LOADING_TREES;),
    (FileName: 'Houses';     TeamColors: True;  Usage: ruGame;   LoadingTextID: TX_MENU_LOADING_HOUSES;),
    (FileName: 'Units';      TeamColors: True;  Usage: ruGame;   LoadingTextID: TX_MENU_LOADING_UNITS;),
    (FileName: 'GUI';        TeamColors: True;  Usage: ruMenu;   LoadingTextID: 0;),
    (FileName: 'GUIMain';    TeamColors: False; Usage: ruMenu;   LoadingTextID: 0;),
    (FileName: 'Custom';     TeamColors: False; Usage: ruCustom; LoadingTextID: 0;),
    (FileName: 'Tileset';    TeamColors: False; Usage: ruMenu;   LoadingTextID: TX_MENU_LOADING_TILESET;));

  function GetKeyFunctionStr(aKeyFun: TKMKeyFunction): string;


implementation
uses
  TypInfo;


function GetKeyFunctionStr(aKeyFun: TKMKeyFunction): string;
begin
//  Result := TRttiEnumerationType.GetName(aKeyFun);
  Result := GetEnumName(TypeInfo(TKMKeyFunction), Integer(aKeyFun));
end;


end.
