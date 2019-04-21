unit KM_AIArmyEvaluation;
{$I KaM_Remake.inc}
interface
uses
  KM_Defaults, KM_CommonClasses,
  KM_Units, KM_UnitGroup;

type
  TKMGroupEval = record
    HitPoints, Attack, AttackHorse, Defence, DefenceProjectiles: Single;
  end;
  TKMFoodState = record
    Full, Middle, Low: Cardinal;
  end;
  TKMArmyEval = record
    FoodState: TKMFoodState;
    Groups: array[TKMGroupType] of TKMGroupEval;
  end;
  TKMGameEval = array[0 .. MAX_HANDS - 1] of TKMArmyEval;

  TKMGroupStrengthArray = array[TKMGroupType] of Single;

  //This class evaluate self army relatively enemy armies
  TKMArmyEvaluation = class
  private
    fEvals: TKMGameEval; //Results of evaluation

    function CalculateStrength(aEval: TKMArmyEval): TKMGroupStrengthArray;
    function GetUnitEvaluation(aUT: TKMUnitType; aConsiderHitChance: Boolean = False): TKMGroupEval;
    function GetEvaluation(aPlayer: TKMHandID): TKMArmyEval;
    function GetAllianceStrength(aPlayer: TKMHandID; aAlliance: TKMAllianceType): TKMArmyEval;
    procedure EvaluatePower(aPlayer: TKMHandID; aConsiderHitChance: Boolean = False);
  public
    constructor Create();
    destructor Destroy; override;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

    property UnitEvaluation[aUT: TKMUnitType; aConsiderHitChance: Boolean]: TKMGroupEval read GetUnitEvaluation;
    property Evaluation[aPlayer: TKMHandID]: TKMArmyEval read GetEvaluation;
    property AllianceEvaluation[aPlayer: TKMHandID; aAlliance: TKMAllianceType]: TKMArmyEval read GetAllianceStrength;

    function CompareStrength(aPlayer, aOponent: TKMHandID): Single;
    function CompareAllianceStrength(aPlayer, aOponent: TKMHandID): Single;
    procedure AfterMissionInit();
    procedure UpdateState(aTick: Cardinal);
  end;

const
  HIT_CHANCE_MODIFIER = 0.5;

implementation
uses
  Math,
  KM_Hand, KM_HandsCollection, KM_HandStats,
  KM_Resource, KM_ResUnits;


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
  SaveStream.WriteA('ArmyEvaluation');
  SaveStream.Write(fEvals, SizeOf(fEvals));
end;


procedure TKMArmyEvaluation.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.ReadAssert('ArmyEvaluation');
  LoadStream.Read(fEvals, SizeOf(fEvals));
end;


function TKMArmyEvaluation.GetUnitEvaluation(aUT: TKMUnitType; aConsiderHitChance: Boolean = False): TKMGroupEval;
var
  US: TKMUnitSpec;
begin
  // Fill array with reference values
  US := gRes.Units[aUT];
  with Result do
  begin
    Hitpoints :=          US.Hitpoints;
    Attack :=             US.Attack;
    AttackHorse :=        US.AttackHorse;
    Defence :=            US.Defence;
    DefenceProjectiles := US.GetDefenceVsProjectiles(False);
    if aConsiderHitChance AND (UnitGroups[aUT] = gtRanged) then
      Attack := Attack * HIT_CHANCE_MODIFIER;
  end;
end;


function TKMArmyEvaluation.GetEvaluation(aPlayer: TKMHandID): TKMArmyEval;
begin
  Move(fEvals[aPlayer], Result, SizeOf(fEvals[aPlayer]));
end;


function TKMArmyEvaluation.CalculateStrength(aEval: TKMArmyEval): TKMGroupStrengthArray;
  var
    GT: TKMGroupType;
  begin
    for GT := Low(TKMGroupType) to High(TKMGroupType) do
      with aEval.Groups[GT] do
        Result[GT] := Attack * Hitpoints * Defence;
        //Result[GT] := Attack * Max(1, AttackHorse) * Hitpoints * Defence;
  end;


function TKMArmyEvaluation.CompareStrength(aPlayer, aOponent: TKMHandID): Single;
var
  Sum, Diff: Single;
  GT: TKMGroupType;
  PlayerArmy, EnemyArmy: TKMGroupStrengthArray;
begin
  PlayerArmy := CalculateStrength( Evaluation[aPlayer] );
  EnemyArmy := CalculateStrength( Evaluation[aOponent] );
  Sum := 0;
  Diff := 0;
  for GT := Low(TKMGroupType) to High(TKMGroupType) do
  begin
    Sum := Sum + PlayerArmy[GT] + EnemyArmy[GT];
    Diff := Diff + PlayerArmy[GT] - EnemyArmy[GT];
  end;
  Result := Diff / Max(1,Sum); // => number in <-1,1> ... positive = we have advantage and vice versa
end;


function TKMArmyEvaluation.GetAllianceStrength(aPlayer: TKMHandID; aAlliance: TKMAllianceType): TKMArmyEval;
var
  PL: Integer;
  GT: TKMGroupType;
begin
  FillChar(Result, SizeOf(Result), #0);
  for PL := 0 to gHands.Count - 1 do
    if gHands[PL].Enabled AND (gHands[aPlayer].Alliances[PL] = aAlliance) then
    begin
      for GT := Low(TKMGroupType) to High(TKMGroupType) do
        with Result.Groups[GT] do
        begin
          Hitpoints          := Hitpoints          + fEvals[PL].Groups[GT].Hitpoints;
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
function TKMArmyEvaluation.CompareAllianceStrength(aPlayer, aOponent: TKMHandID): Single;
var
  Sum, Diff: Single;
  GT: TKMGroupType;
  AllyEval, EnemyEval: TKMArmyEval;
  AllyArmy, EnemyArmy: TKMGroupStrengthArray;
begin
  AllyEval := GetAllianceStrength(aPlayer, atAlly);
  EnemyEval := GetAllianceStrength(aOponent, atAlly);
  AllyArmy := CalculateStrength(AllyEval);
  EnemyArmy := CalculateStrength(EnemyEval);
  Sum := 0;
  Diff := 0;
  for GT := Low(TKMGroupType) to High(TKMGroupType) do
  begin
    Sum := Sum + AllyArmy[GT] + EnemyArmy[GT];
    Diff := Diff + AllyArmy[GT] - EnemyArmy[GT];
  end;
  Result := Diff / Max(1,Sum); // => number in <-1,1> ... positive = we have advantage and vice versa
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
    K,L: Integer;
    LowCnt, FullCnt, ArmyCnt: Cardinal;
    U: TKMUnit;
    G: TKMUnitGroup;
  begin
    LowCnt := 0;
    FullCnt := 0;
    ArmyCnt := 0;
    for K := 0 to gHands[aPlayer].UnitGroups.Count - 1 do
    begin
      G := gHands[aPlayer].UnitGroups[K];
      if not ((G = nil) OR (G.IsDead)) then
        for L := 0 to G.Count - 1 do
        begin
          U := G.Members[L];
          if not ((U = nil) OR (U.IsDeadOrDying)) then
          begin
            Inc(LowCnt,Byte(U.Condition < LOW_LIMIT));
            Inc(FullCnt,Byte(U.Condition > FULL_LIMIT));
            Inc(ArmyCnt);
          end;
        end;
    end;
    fEvals[aPlayer].FoodState.Low := LowCnt;
    fEvals[aPlayer].FoodState.Middle := ArmyCnt - LowCnt - FullCnt;
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
    GT := UnitGroups[UT];
    with fEvals[aPlayer].Groups[GT] do
    begin
      Hitpoints := Hitpoints + Qty * US.HitPoints;
      Attack := Attack + Qty * US.Attack;
      AttackHorse := AttackHorse + Qty * US.AttackHorse;
      Defence := Defence + Qty * US.Defence;
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
  PL: TKMHandID;
begin
  PL := aTick mod PERF_SUM;
  if (PL < gHands.Count) AND gHands[PL].Enabled then
    EvaluatePower(PL, True);
end;


end.
