unit KM_MapTypes;
{$I KaM_Remake.inc}
interface
uses
  KM_ResTexts, KM_Defaults;

type
  TKMMissionDifficulty = (mdNone, mdEasy3, mdEasy2, mdEasy1, mdNormal, mdHard1, mdHard2, mdHard3);
  TKMMissionDifficultySet = set of TKMMissionDifficulty;

const
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


implementation


end.
