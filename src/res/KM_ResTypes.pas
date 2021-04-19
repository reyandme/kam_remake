unit KM_ResTypes;
interface

type
  TKMChopableAge = (caAge1, caAge2, caAge3, caAgeFull, caAgeFall, caAgeStump);

  TKMChopableAgeSet = set of TKMChopableAge;

  TKMWareType = (
    wtNone,
    wtTrunk,   wtStone,   wtWood,        wtIronOre,   wtGoldOre,
    wtCoal,    wtSteel,   wtGold,        wtWine,      wtCorn,
    wtBread,   wtFlour,   wtLeather,     wtSausages,  wtPig,
    wtSkin,    wtShield,  wtMetalShield, wtArmor,     wtMetalArmor,
    wtAxe,     wtSword,   wtPike,        wtHallebard, wtBow,
    wtArbalet, wtHorse,   wtFish,

    // Special ware types
    wtAll,     wtWarfare, wtFood
  );


  TKMHouseType = (htNone, htAny,
    htArmorSmithy,     htArmorWorkshop,   htBakery,        htBarracks,      htButchers,
    htCoalMine,        htFarm,            htFisherHut,     htGoldMine,      htInn,
    htIronMine,        htIronSmithy,      htMarketplace,   htMetallurgists, htMill,
    htQuary,           htSawmill,         htSchool,        htSiegeWorkshop, htStables,
    htStore,           htSwine,           htTannery,       htTownHall,      htWatchTower,
    htWeaponSmithy,    htWeaponWorkshop,  htWineyard,      htWoodcutters    );

  THouseTypeSet = set of TKMHouseType;
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


  TKMKeyFuncArea = (faCommon,
                 faGame,
                   faUnit,
                   faHouse,
                 faSpecReplay,
                 faMapEdit);

  TKMKeyFuncAreaSet = set of TKMKeyFuncArea;

implementation

end.
