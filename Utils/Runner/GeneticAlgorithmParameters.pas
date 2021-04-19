unit GeneticAlgorithmParameters;

interface
uses
  Classes, SysUtils, Math,
  GeneticAlgorithm,
  KM_Log, KM_AIParameters;

type
  TAIParSet = set of TAIPar;
  TGAParameterization = class
  private
    fLogPar: TKMLog;
    fClass: String;
    function Incr(var Idx: Word): Word;
    procedure LogParameters();
    // Get count of parameters
    function GetParCntFromSet(const aSet: TAIParSet): Word;
    function GetParCnt_TestParRun(): Word;
    function GetParCnt_HandLogistics(): Word;
    // Set global parameters
    procedure SetParameters(const aSet: TAIParSet; const aIdv: TGAIndividual; aLogIt: Boolean = False);
    procedure SetPar_HandLogistics(const aIdv: TGAIndividual; aLogIt: Boolean = False; K: Word = 0);
  public
    constructor Create();
    destructor Destroy(); override;

    property SetLogPar: TKMLog write fLogPar;
    property CurrentClass: String read fClass write fClass;

    function GetParCnt(aNewClass: String = ''): Word;
    procedure SetPar(const aIdv: TGAIndividual; aLogIt: Boolean = False);
  end;

implementation
uses
  Types, TypInfo;


const

SetArmyAttack:
  TAIParSet = [
    ARMY_MaxGgroupsInCompany..ARMY_PATHFINDING_AvoidTraffic,
    ATTACK_COMPANY_AttackRadius..ATTACK_COMPANY_TimePerATile_Slow,
    ATTACK_SQUAD_ChangeTarget_Delay..ATTACK_SQUAD_TargetReached_Unit
  ];
SetArmyAttackNew:
  TAIParSet = [
    ARMY_PATHFINDING_AvoidEdges..ARMY_PATHFINDING_AvoidTraffic,
    ATTACK_NMAP_BackwardFlood_MaxAllyInfluence..ATTACK_NMAP_TArmyBackwardFF_EnemyInfluence,
    ATTACK_SUPERVISOR_EvalTarget_DistanceGroup..ATTACK_SUPERVISOR_UpdateAttacks_AttackThreshold
  ];
SetCityAllIn:
  TAIParSet = [
    BUILDER_BuildHouse_FieldMaxWork..ROADS_noBuildArea
  ];
SetCityBuilder:
  TAIParSet = [
    BUILDER_BuildHouse_FieldMaxWork..BUILDER_Shortage_Wood
  ];
SetCityPlanner:
  TAIParSet = [
    PLANNER_FindPlaceForHouse_CityCenter..PLANNER_FindPlaceForQuary_SnapCrit,
    PLANNER_ObstaclesInHousePlan_Road..PLANNER_SnapCrit_RoadInEntrance
  ];
SetFarm:
  TAIParSet = [
    PLANNER_FARM_FieldCrit_FlatArea..PLANNER_FARM_PlanFields_ExistField
  ];
SetForest:
  TAIParSet = [
    EYE_GetForests_MaxAB..EYE_GetForests_SPRndOwnLimMin,
    PLANNER_FOREST_FindForestAround_MaxDist..PLANNER_FOREST_PlaceWoodcutter_DistFromForest
  ];
SetManager:
  TAIParSet = [
    MANAGEMENT_CheckUnitCount_SerfGoldCoef..MANAGEMENT_GoldShortage,
    PREDICTOR_SecondSchool_MinRequiredUnits..PREDICTOR_WareNeedPerAWorker_Wood
  ];
SetQuarry:
  TAIParSet = [
    PLANNER_FindPlaceForQuary_DistCity..PLANNER_FindPlaceForQuary_SnapCrit
  ];
SetRoadPlanner:
  TAIParSet = [
    SHORTCUTS_BasePrice..SHORTCUTS_noBuildArea,
    ROADS_noBuildArea..ROADS_noBuildArea
  ];




{ TGAParameterization }
constructor TGAParameterization.Create();
begin
  inherited;

  fLogPar := nil;
  fClass := '';
end;


destructor TGAParameterization.Destroy();
begin
  fLogPar := nil;
  fClass := '';

  inherited;
end;



// Small helping function
function TGAParameterization.Incr(var Idx: Word): Word;
begin
  Result := Idx;
  Inc(Idx);
end;


function TGAParameterization.GetParCntFromSet(const aSet: TAIParSet): Word;
var
  Idx: TAIPar;
begin
  Result := 0;
  for Idx in aSet do
    Inc(Result);
end;


procedure TGAParameterization.SetParameters(const aSet: TAIParSet; const aIdv: TGAIndividual; aLogIt: Boolean = False);
{$IFDEF DEBUG_NewAI}
var
  K: Integer;
  Idx: TAIPar;
{$ENDIF}
begin
{$IFDEF DEBUG_NewAI}
  K := 0;
  for Idx in aSet do
  begin
    AI_Par[Idx] := AI_Par_Offset[Idx] + AI_Par_Gain[Idx] * aIdv.Gene[K];
    Inc(K);
  end;
  if aLogIt then
    LogParameters();
{$ENDIF}
end;


procedure TGAParameterization.LogParameters();
var
  Idx: TAIPar;
  enumName: String;
begin
  if (fLogPar = nil) then
    Exit;
  fLogPar.AddTime('  AI_Par: array[TAIPar] of Single = (');
  for Idx := Low(AI_Par) to High(AI_Par) do
  begin
    enumName := GetEnumName(TypeInfo(TAIPar), Integer(Idx));
    fLogPar.AddTime(Format('%13.7f, // %s',[AI_Par[Idx], enumName ]));
    //fLogPar.AddTime(Format('%13.7f%s, // %s',[AI_Par[Idx], StringOfChar(' ', Max(1,50 - Length(enumName))), enumName ]));
  end;
  fLogPar.AddTime('  );');
end;


function TGAParameterization.GetParCnt(aNewClass: String = ''): Word;
begin
  if not (CompareStr(aNewClass, '') = 0) then
    fClass := aNewClass;
  if      (CompareStr(fClass, 'TKMRunnerGA_CityAllIn'    ) = 0) then Result := GetParCntFromSet(SetCityAllIn)
  else if (CompareStr(fClass, 'TKMRunnerGA_CityBuilder'  ) = 0) then Result := GetParCntFromSet(SetCityBuilder)
  else if (CompareStr(fClass, 'TKMRunnerGA_CityPlanner'  ) = 0) then Result := GetParCntFromSet(SetCityPlanner)
  else if (CompareStr(fClass, 'TKMRunnerGA_Farm'         ) = 0) then Result := GetParCntFromSet(SetFarm)
  else if (CompareStr(fClass, 'TKMRunnerGA_Forest'       ) = 0) then Result := GetParCntFromSet(SetForest)
  else if (CompareStr(fClass, 'TKMRunnerGA_HandLogistics') = 0) then Result := GetParCnt_HandLogistics
  else if (CompareStr(fClass, 'TKMRunnerGA_Manager'      ) = 0) then Result := GetParCntFromSet(SetManager)
  else if (CompareStr(fClass, 'TKMRunnerGA_Quarry'       ) = 0) then Result := GetParCntFromSet(SetQuarry)
  else if (CompareStr(fClass, 'TKMRunnerGA_RoadPlanner'  ) = 0) then Result := GetParCntFromSet(SetRoadPlanner)
  else if (CompareStr(fClass, 'TKMRunnerGA_TestParRun'   ) = 0) then Result := GetParCnt_TestParRun
  else if (CompareStr(fClass, 'TKMRunnerGA_ArmyAttack'   ) = 0) then Result := GetParCntFromSet(SetArmyAttack)
  else if (CompareStr(fClass, 'TKMRunnerGA_ArmyAttackNew') = 0) then Result := GetParCntFromSet(SetArmyAttackNew)
  else Result := 0;
end;

procedure TGAParameterization.SetPar(const aIdv: TGAIndividual; aLogIt: Boolean = False);
begin
  if      (CompareStr(fClass, 'TKMRunnerGA_CityAllIn'    ) = 0) then SetParameters(SetCityAllIn, aIdv, aLogIt)
  else if (CompareStr(fClass, 'TKMRunnerGA_CityBuilder'  ) = 0) then SetParameters(SetCityBuilder, aIdv, aLogIt)
  else if (CompareStr(fClass, 'TKMRunnerGA_CityPlanner'  ) = 0) then SetParameters(SetCityPlanner, aIdv, aLogIt)
  else if (CompareStr(fClass, 'TKMRunnerGA_Farm'         ) = 0) then SetParameters(SetFarm, aIdv, aLogIt)
  else if (CompareStr(fClass, 'TKMRunnerGA_Forest'       ) = 0) then SetParameters(SetForest, aIdv, aLogIt)
  else if (CompareStr(fClass, 'TKMRunnerGA_HandLogistics') = 0) then SetPar_HandLogistics(aIdv, aLogIt)
  else if (CompareStr(fClass, 'TKMRunnerGA_Manager'      ) = 0) then SetParameters(SetManager, aIdv, aLogIt)
  else if (CompareStr(fClass, 'TKMRunnerGA_Quarry'       ) = 0) then SetParameters(SetQuarry, aIdv, aLogIt)
  else if (CompareStr(fClass, 'TKMRunnerGA_RoadPlanner'  ) = 0) then SetParameters(SetRoadPlanner, aIdv, aLogIt)
  else if (CompareStr(fClass, 'TKMRunnerGA_ArmyAttack'   ) = 0) then SetParameters(SetArmyAttack, aIdv, aLogIt)
  else if (CompareStr(fClass, 'TKMRunnerGA_ArmyAttackNew') = 0) then SetParameters(SetArmyAttackNew, aIdv, aLogIt)
  else begin end;
end;


function TGAParameterization.GetParCnt_TestParRun(): Word;
begin
  Result := 10;
end;


function TGAParameterization.GetParCnt_HandLogistics(): Word;
begin
  Result := 0;
end;


procedure TGAParameterization.SetPar_HandLogistics(const aIdv: TGAIndividual; aLogIt: Boolean = False; K: Word = 0);
//var
//  I: Integer;
begin
  //I := 0;

  //GA_TCBB_BasicInit   := Max(1, Round(aIdv.Gene[Incr(K)] * 20));
  //GA_TCBB_BasicRnd    := Max(1, Round(aIdv.Gene[Incr(K)] * 60)+40);
  //GA_TCBB_NormRnd     := Max(1, Round(aIdv.Gene[Incr(K)] * 32));
  //GA_TCBB_Rnd         := Max(1, Round(aIdv.Gene[Incr(K)] * 50));
  //GA_TCBB_BasicPwr    := Max(1, Round(GA_TCBB_BasicRnd / 5)); // GA has discovered that this is best strategy
  //GA_TCBB_NormPwr     := Max(1, Round(GA_TCBB_NormRnd / 5));
  //
  //if aLogIt then
  //begin
  //  fLogPar.AddTime('GA_TCBB_BasicInit   : Integer = ' + IntToStr( GA_TCBB_BasicInit ) + ';');
  //  fLogPar.AddTime('GA_TCBB_BasicRnd    : Integer = ' + IntToStr( GA_TCBB_BasicRnd  ) + ';');
  //  fLogPar.AddTime('GA_TCBB_BasicPwr    : Integer = ' + IntToStr( GA_TCBB_BasicPwr  ) + ';');
  //  fLogPar.AddTime('GA_TCBB_NormRnd     : Integer = ' + IntToStr( GA_TCBB_NormRnd   ) + ';');
  //  fLogPar.AddTime('GA_TCBB_NormPwr     : Integer = ' + IntToStr( GA_TCBB_NormPwr   ) + ';');
  //  fLogPar.AddTime('GA_TCBB_Rnd         : Integer = ' + IntToStr( GA_TCBB_Rnd       ) + ';');
  //end;
end;


end.
