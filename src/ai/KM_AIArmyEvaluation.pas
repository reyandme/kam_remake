unit KM_AIArmyEvaluation;
{$I KaM_Remake.inc}
interface
uses
  KM_Defaults, KM_CommonClasses,
  KM_Units, KM_UnitGroup;

type
  TKMGroupEval = record
    Count: Integer;
    HitPoints, Attack, AttackHorse, Defence, DefenceProjectiles: Single;
  end;
  TKMFoodState = record
    Full, Middle, Low: Integer;
  end;
  TKMArmyEval = record
    FoodState: TKMFoodState;
    Groups: array[GROUP_TYPE_MIN..GROUP_TYPE_MAX] of TKMGroupEval;
  end;
  TKMGameEval = array[0 .. MAX_HANDS - 1] of TKMArmyEval;

  TKMGroupStrengthArray = array[GROUP_TYPE_MIN..GROUP_TYPE_MAX] of Single;

  //This class evaluate self army relatively enemy armies
  TKMArmyEvaluation = class
  private
    fEvals: TKMGameEval; //Results of evaluation

    function CompareStrength(A, E: TKMArmyEval): Single;
    function GetAllianceStrength(const aAlliance: TKMHandIDArray): TKMArmyEval;
    procedure EvaluatePower(aPlayer: TKMHandID; aConsiderHitChance: Boolean = False);
  public
    constructor Create();
    destructor Destroy; override;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

    function UnitEvaluation(aUT: TKMUnitType; aConsiderHitChance: Boolean = False): TKMGroupEval;
    function GroupEvaluation(aGroup: TKMUnitGroup; aConsiderHitChance: Boolean): TKMGroupEval;
    function PlayerEvaluation(aPlayer: TKMHandID): TKMArmyEval;
    function AllianceEvaluation(aPlayer: TKMHandID; aAlliance: TKMAllianceType): TKMArmyEval;

    function CompareAllianceStrength(const aAlly, aEnemy: TKMHandIDArray): Single;
    function CheckFoodProblems(const aAlly: TKMHandIDArray): Boolean;
    procedure AfterMissionInit();
    procedure UpdateState(aTick: Cardinal);
  end;


const
  HIT_CHANCE_MODIFIER = 0.5;


implementation
uses
  Classes, Math,
  KM_Hand, KM_HandsCollection, KM_HandStats,
  KM_UnitsCollection,
  KM_Resource, KM_ResUnits, KM_ResTypes;


{ TKMArmyEvaluation }
constructor TKMArmyEvaluation.Create();
begin
  inherited Create;
  FillChar(fEvals, SizeOf(fEvals), #0);
end;


destructor TKMArmyEvaluation.Destroy;
begin
  inherited;
end;


procedure TKMArmyEvaluation.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.PlaceMarker('ArmyEvaluation');
  SaveStream.Write(fEvals, SizeOf(fEvals));
end;


procedure TKMArmyEvaluation.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.CheckMarker('ArmyEvaluation');
  LoadStream.Read(fEvals, SizeOf(fEvals));
end;


function TKMArmyEvaluation.UnitEvaluation(aUT: TKMUnitType; aConsiderHitChance: Boolean = False): TKMGroupEval;
var
  unitSpec: TKMUnitSpec;
begin
  // Fill array with reference values
  unitSpec := gRes.Units[aUT];
  Result.Count              := 1;
  Result.HitPoints          := unitSpec.HitPoints;
  Result.Attack             := unitSpec.Attack;
  Result.AttackHorse        := unitSpec.AttackHorse;
  Result.Defence            := unitSpec.Defence;
  Result.DefenceProjectiles := unitSpec.GetDefenceVsProjectiles(False);
  if aConsiderHitChance and (UNIT_TO_GROUP_TYPE[aUT] = gtRanged) then
    Result.Attack := Result.Attack * HIT_CHANCE_MODIFIER;
end;


function TKMArmyEvaluation.GroupEvaluation(aGroup: TKMUnitGroup; aConsiderHitChance: Boolean): TKMGroupEval;
var
  K: Integer;
  GE: TKMGroupEval;
begin
  FillChar(Result, SizeOf(Result), #0);
  Result.Count := aGroup.Count;
  for K := 0 to aGroup.Count-1 do
  begin
    GE := UnitEvaluation(TKMUnit(aGroup.Members[K]).UnitType, aConsiderHitChance);
    with Result do
    begin
      HitPoints          := HitPoints          + GE.HitPoints;
      Attack             := Attack             + GE.Attack;
      AttackHorse        := AttackHorse        + GE.AttackHorse;
      Defence            := Defence            + GE.Defence;
      DefenceProjectiles := DefenceProjectiles + GE.DefenceProjectiles;
    end;
  end;
end;


function TKMArmyEvaluation.PlayerEvaluation(aPlayer: TKMHandID): TKMArmyEval;
begin
  Move(fEvals[aPlayer], Result, SizeOf(fEvals[aPlayer]));
end;


function TKMArmyEvaluation.AllianceEvaluation(aPlayer: TKMHandID; aAlliance: TKMAllianceType): TKMArmyEval;
var
  Cnt: Integer;
  PL: TKMHandID;
  Alliance: TKMHandIDArray;
begin
  Cnt := 0;
  SetLength(Alliance, gHands.Count);
  for PL := 0 to gHands.Count - 1 do
  begin
    Alliance[Cnt] := PL;
    Inc(Cnt, Byte( gHands[PL].Enabled AND (gHands[aPlayer].Alliances[PL] = aAlliance) ));
  end;
  SetLength(Alliance,Cnt);
  Result := GetAllianceStrength(Alliance);
end;


function TKMArmyEvaluation.CompareStrength(A, E: TKMArmyEval): Single;
  // Sum power of all types of groups
  procedure SumPower(var aEval: TKMGroupEval; var Army: TKMArmyEval);
  var
    GT: TKMGroupType;
  begin
    FillChar(aEval, SizeOf(aEval), #0);
    for GT := GROUP_TYPE_MIN to GROUP_TYPE_MAX do
    begin
      aEval.Count              := aEval.Count              + Army.Groups[GT].Count             ;
      aEval.HitPoints          := aEval.HitPoints          + Army.Groups[GT].HitPoints         ;
      aEval.Attack             := aEval.Attack             + Army.Groups[GT].Attack            ;
      aEval.AttackHorse        := aEval.AttackHorse        + Army.Groups[GT].AttackHorse       ;
      aEval.Defence            := aEval.Defence            + Army.Groups[GT].Defence           ;
      aEval.DefenceProjectiles := aEval.DefenceProjectiles + Army.Groups[GT].DefenceProjectiles;
    end;
  end;
var
  AEval, EEval: TKMGroupEval;
begin
  // Sum power of groups in alliance
  SumPower(AEval,A);
  SumPower(EEval,E);
  // Get weighted power with consideration of hostile groups
  AEval.AttackHorse := AEval.AttackHorse * E.Groups[gtMounted].Count / Max(1, EEval.Count);
  EEval.AttackHorse := EEval.AttackHorse * A.Groups[gtMounted].Count / Max(1, AEval.Count);
  AEval.DefenceProjectiles := AEval.DefenceProjectiles * E.Groups[gtRanged].Count / Max(1, EEval.Count);
  EEval.DefenceProjectiles := EEval.DefenceProjectiles * A.Groups[gtRanged].Count / Max(1, AEval.Count);
  // Get balance of power
  Result := (
    + 1 - Min(2,(EEval.Attack + EEval.AttackHorse        ) / Max(1,(AEval.Attack + AEval.AttackHorse        )))
    + 1 - Min(2,(EEval.HitPoints                         ) / Max(1,(AEval.HitPoints                         )))
    + 1 - Min(2,(EEval.Defence + EEval.DefenceProjectiles) / Max(1,(AEval.Defence + AEval.DefenceProjectiles)))
  ) / 3;
end;


function TKMArmyEvaluation.GetAllianceStrength(const aAlliance: TKMHandIDArray): TKMArmyEval;
var
  PL: Integer;
  GT: TKMGroupType;
begin
  FillChar(Result, SizeOf(Result), #0);
  for PL in aAlliance do
  begin
    for GT := GROUP_TYPE_MIN to GROUP_TYPE_MAX do
      with Result.Groups[GT] do
      begin
        Count              := Count              + fEvals[PL].Groups[GT].Count;
        HitPoints          := HitPoints          + fEvals[PL].Groups[GT].HitPoints;
        Attack             := Attack             + fEvals[PL].Groups[GT].Attack;
        AttackHorse        := AttackHorse        + fEvals[PL].Groups[GT].AttackHorse;
        Defence            := Defence            + fEvals[PL].Groups[GT].Defence;
        DefenceProjectiles := DefenceProjectiles + fEvals[PL].Groups[GT].DefenceProjectiles;
      end;
    with Result.FoodState do
    begin
      Inc(Full,fEvals[PL].FoodState.Full);
      Inc(Middle,fEvals[PL].FoodState.Middle);
      Inc(Low,fEvals[PL].FoodState.Low);
    end;
  end;
end;


// Approximate way how to compute strength of 2 alliances
function TKMArmyEvaluation.CompareAllianceStrength(const aAlly, aEnemy: TKMHandIDArray): Single;
var
  AllyEval, EnemyEval: TKMArmyEval;
begin
  AllyEval := GetAllianceStrength(aAlly);
  EnemyEval := GetAllianceStrength(aEnemy);
  Result := CompareStrength(AllyEval, EnemyEval); // => number in <-1,1> ... positive = we have advantage and vice versa
end;


function TKMArmyEvaluation.CheckFoodProblems(const aAlly: TKMHandIDArray): Boolean;
const
  FOOD_THRESHOLD = 0.75;
var
  Full, Middle, Low, Food: Integer;
  PL: TKMHandID;
begin
  Result := False;
  Full := 0;
  Middle := 0;
  Low := 0;
  for PL in aAlly do
  begin
    Food := 0;
    Inc(Food  ,gHands[PL].Stats.GetWareBalance(wtBread));
    Inc(Food  ,gHands[PL].Stats.GetWareBalance(wtWine));
    Inc(Food  ,gHands[PL].Stats.GetWareBalance(wtSausage));
    Inc(Food  ,gHands[PL].Stats.GetWareBalance(wtFish));
    Inc(Full  ,fEvals[PL].FoodState.Full);
    Inc(Middle,fEvals[PL].FoodState.Middle);
    Inc(Low   ,max(0, fEvals[PL].FoodState.Low - Food));
  end;
  if ((Full + Middle + Low) > 0) then
    Result := ((Full + Middle) / Max(1, (Full + Middle + Low))) < FOOD_THRESHOLD;
end;


// Actualize power of specific player
//
// Equation of combat:
//
//   Close combat
//                    Attack (+ AttackHorse) (+ DirModifier)   -> DirModifier is not considered in ArmyEvaluation
//     Probability = ---------------------------------------
//                                 Defence
//
//   Ranged units
//     HitProbability = 1 - Distance;  Distance in <0,1>       -> Hit probability is considered as a decreasing of attack by HIT_CHANCE_MODIFIER
//                         Attack
//     Probability = --------------------
//                    DefenceProjectiles
//
// Probability > random number => decrease hitpoint; 0 hitpoints = unit is dead
procedure TKMArmyEvaluation.EvaluatePower(aPlayer: TKMHandID; aConsiderHitChance: Boolean = False);
  procedure EvaluateFoodLevel();
  const
    FULL_LIMIT = Round(UNIT_MAX_CONDITION * 0.75);
    LOW_LIMIT = Round(UNIT_MAX_CONDITION * 0.3);
  var
    K, Condition, LowCnt, FullCnt: Integer;
  begin
    LowCnt := 0;
    FullCnt := 0;
    for K := 0 to gHands[aPlayer].Units.Count - 1 do
    begin
      Condition := gHands[aPlayer].Units[K].Condition;
      Inc(LowCnt, Byte(Condition < LOW_LIMIT));
      Inc(FullCnt,Byte(Condition > FULL_LIMIT));
    end;
    fEvals[aPlayer].FoodState.Low := LowCnt;
    fEvals[aPlayer].FoodState.Middle := gHands[aPlayer].Units.Count - LowCnt - FullCnt;
    fEvals[aPlayer].FoodState.Full := FullCnt;
  end;
var
  Stats: TKMHandStats;
  Qty: Integer;
  US: TKMUnitSpec;
  UT: TKMUnitType;
  GT: TKMGroupType;
begin
  Stats := gHands[aPlayer].Stats;

  // Clear array
  FillChar(fEvals[aPlayer], SizeOf(fEvals[aPlayer]), #0);

  // Fill array with reference values
  for UT := WARRIOR_MIN to WARRIOR_MAX do
  begin
    Qty := Stats.GetUnitQty(UT);
    US := gRes.Units[UT];
    GT := UNIT_TO_GROUP_TYPE[UT];
    with fEvals[aPlayer].Groups[GT] do
    begin
      Count       := Count       + Qty;
      HitPoints   := HitPoints   + Qty * US.HitPoints;
      Attack      := Attack      + Qty * US.Attack;
      AttackHorse := AttackHorse + Qty * US.AttackHorse;
      Defence     := Defence     + Qty * US.Defence;
      DefenceProjectiles := DefenceProjectiles + Qty * US.GetDefenceVsProjectiles(False); // True = IsBolt -> calculation without bolts
    end;
  end;
  if aConsiderHitChance then
    with fEvals[aPlayer].Groups[gtRanged] do
      Attack := Attack * HIT_CHANCE_MODIFIER;

  // Check if army is hungry
  EvaluateFoodLevel();
end;


procedure TKMArmyEvaluation.AfterMissionInit();
var
  PL: TKMHandID;
begin
  for PL := 0 to gHands.Count - 1 do
    if gHands[PL].Enabled then
      EvaluatePower(PL, True);
end;


procedure TKMArmyEvaluation.UpdateState(aTick: Cardinal);
const
  PERF_SUM = MAX_HANDS * 10;
var
  PL: Integer;
begin
  PL := aTick mod PERF_SUM;
  if (PL < gHands.Count) AND gHands[PL].Enabled then
    EvaluatePower(PL, True);
end;


end.
