unit KM_MapTypes;
{$I KaM_Remake.inc}
interface
uses
  KM_Defaults, KM_CommonTypes, KM_ResTypes;

type
  TKMMapKind = (mkUnknown, mkSP, mkMP, mkDL);
  TKMMapKindSet = set of TKMMapKind;

  // Sketch of the goal and message displaying system used in KaM (from scripting point of view anyway)
  // This is very similar to that used in KaM and is quite flexable/expandable.
  // (we can add more parameters/conditions as well as existing KaM ones, possibly using a new script command)
  // Some things are probably named unclearly, please give me suggestions or change them. Goals are the one part
  // of scripting that seems to confuse everyone at first, mainly because of the TGoalStatus. In 99% of cases gsTrue and gtDefeat
  // go together, because the if the defeat conditions is NOT true you lose, not the other way around. I guess it should be called a
  // "survival" conditions rather than defeat.
  // I put some examples below to give you an idea of how it works. Remember this is basically a copy of the goal scripting system in KaM,
  // not something I designed. It can change, this is just easiest to implement from script compatability point of view.
  TKMGoalType = (
    gltNone = 0,  // Means: It is not required for victory or defeat (e.g. simply display a message)
    gltVictory,   // Means: "The following condition must be true for you to win"
    gltSurvive    // Means: "The following condition must be true or else you lose"
  );

  // Conditions are the same numbers as in KaM script
  TKMGoalCondition = (
    gcUnknown0,        // Not used/unknown
    gcBuildTutorial,   // Must build a tannery (and other buildings from tutorial?) for it to be true. In KaM tutorial messages will be dispalyed if this is a goal
    gcTime,            // A certain time must pass
    gcBuildings,       // Storehouse, school, barracks, TownHall
    gcTroops,          // All troops
    gcUnknown5,        // Not used/unknown
    gcMilitaryAssets,  // All Troops, Coal mine, Weapons Workshop, Tannery, Armory workshop, Stables, Iron mine, Iron smithy, Weapons smithy, Armory smithy, Barracks, Town hall and Vehicles Workshop
    gcSerfsAndSchools, // Serfs (possibly all citizens?) and schoolhouses
    gcEconomyBuildings // School, Inn and Storehouse
    //We can come up with our own
  );

  TKMGoalStatus = (gsTrue = 0, gsFalse = 1); // Weird that it's inverted, but KaM uses it that way

  TKMissionMode = (mmBuilding, mmFighting);

  //* Mission difficulty
  TKMMissionDifficulty = (mdNone, mdEasy3, mdEasy2, mdEasy1, mdNormal, mdHard1, mdHard2, mdHard3);
  //* Set of mission difficulties
  TKMMissionDifficultySet = set of TKMMissionDifficulty;

const
  {$I KM_TextIDs.inc}

  GOAL_BUILDINGS_HOUSES: array[0..3] of TKMHouseType = (htStore, htSchool, htBarracks, htTownHall);

  //We discontinue support of other goals in favor of PascalScript scripts
  GOALS_SUPPORTED: set of TKMGoalCondition =
    [gcBuildings, gcTroops, gcMilitaryAssets, gcSerfsAndSchools, gcEconomyBuildings];

  // Used for error's logging
  GOAL_CONDITION_STR: array [TKMGoalCondition] of string = (
    'Unknown 0',
    'Build Tannery',
    'Time',
    'Store School Barracks Townhall',
    'Troops',
    'Unknown 5',
    'Military assets',
    'Serfs&Schools',
    'School Inn Store'
  );


  MISSION_DIFFICULTY_MIN = mdEasy3;
  MISSION_DIFFICULTY_MAX = mdHard3;

  DIFFICULTY_LEVELS_TX: array[MISSION_DIFFICULTY_MIN..MISSION_DIFFICULTY_MAX] of Integer = (
    TX_MISSION_DIFFICULTY_EASY3,
    TX_MISSION_DIFFICULTY_EASY2,
    TX_MISSION_DIFFICULTY_EASY1,
    TX_MISSION_DIFFICULTY_NORMAL,
    TX_MISSION_DIFFICULTY_HARD1,
    TX_MISSION_DIFFICULTY_HARD2,
    TX_MISSION_DIFFICULTY_HARD3
  );

  DIFFICULTY_LEVELS_COLOR: array[TKMMissionDifficulty] of Cardinal = (
    icLightGray2,
    icLightGreen,
    icGreen,
    icGreenYellow,
    icYellow,
    icOrange,
    icDarkOrange,
    icRed
  );

  //Map folder name by folder type. Containing single maps, for SP/MP/DL mode
  MAP_FOLDER_NAME: array [TKMMapKind] of string = ('', MAPS_FOLDER_NAME, MAPS_MP_FOLDER_NAME, MAPS_DL_FOLDER_NAME);

  CUSTOM_MAP_PARAM_DESCR_TX: array[TKMCustomScriptParam] of Integer = (TX_MAP_CUSTOM_PARAM_TH_TROOP_COST, TX_MAP_CUSTOM_PARAM_MARKET_PRICE);


implementation


end.
