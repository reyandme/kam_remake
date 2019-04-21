unit KM_MapTypes;
{$I KaM_Remake.inc}
interface
uses
  KM_ResTexts;

type
  TKMMissionDifficulty = (mdNone, mdEasy, mdNormal, mdHard);
  TKMMissionDifficultySet = set of TKMMissionDifficulty;

const
  DIFFICULTY_LEVELS_TX: array[mdEasy..mdHard] of Integer =
    (TX_MISSION_DIFFICULTY_EASY, TX_MISSION_DIFFICULTY_NORMAL, TX_MISSION_DIFFICULTY_HARD);


implementation


end.
