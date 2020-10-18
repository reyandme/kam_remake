unit KM_MapTypes;
{$I KaM_Remake.inc}
interface
uses
  KM_Defaults, KM_CommonTypes;

type
  TKMMissionDifficulty = (mdNone, mdEasy3, mdEasy2, mdEasy1, mdNormal, mdHard1, mdHard2, mdHard3);
  TKMMissionDifficultySet = set of TKMMissionDifficulty;

const
  {$I KM_TextIDs.inc}

  MISSION_DIFFICULTY_MIN = mdEasy3;
  MISSION_DIFFICULTY_MAX = mdHard3;

  DIFFICULTY_LEVELS_TX: array[MISSION_DIFFICULTY_MIN..MISSION_DIFFICULTY_MAX] of Integer =
    (TX_MISSION_DIFFICULTY_EASY3,
     TX_MISSION_DIFFICULTY_EASY2,
     TX_MISSION_DIFFICULTY_EASY1,
     TX_MISSION_DIFFICULTY_NORMAL,
     TX_MISSION_DIFFICULTY_HARD1,
     TX_MISSION_DIFFICULTY_HARD2,
     TX_MISSION_DIFFICULTY_HARD3);

  DIFFICULTY_LEVELS_COLOR: array[TKMMissionDifficulty] of Cardinal =
    (icLightGray2,
     icLightGreen,
     icGreen,
     icGreenYellow,
     icYellow,
     icOrange,
     icDarkOrange,
     icRed);

  //Map folder name by folder type. Containing single maps, for SP/MP/DL mode
  MAP_FOLDER: array [TKMapFolder] of string = (MAPS_FOLDER_NAME, MAPS_MP_FOLDER_NAME, CAMPAIGNS_FOLDER_NAME, MAPS_DL_FOLDER_NAME);

  CUSTOM_MAP_PARAM_DESCR_TX: array[TKMCustomScriptParam] of Integer = (TX_MAP_CUSTOM_PARAM_TH_TROOP_COST, TX_MAP_CUSTOM_PARAM_MARKET_PRICE);


implementation


end.
