unit GeneticAlgorithmParameters;
interface
uses
  Classes, SysUtils, Math, StrUtils,
  GeneticAlgorithm,
  KM_Log, KM_AIParameters;

type
  TAIParSet = set of TAIPar;
  TGAParameterization = class
  private
    fLogPar: TKMLog;
    fClass: String;
    function Incr(var Idx: Word): Word;
    procedure LogParameters(const aIdv: TGAIndividual);
    // Get count of parameters
    function GetParCntFromSet(const aSet: TAIParSet): Word;
    function GetParCnt_TestParRun(): Word;
    function GetParCnt_HandLogistics(): Word;
    function GetSetPar(): TAIParSet;
    // Set global parameters
    procedure SetParameters(const aSet: TAIParSet; const aIdv: TGAIndividual; aLogIt: Boolean = False);
    procedure SetPar_HandLogistics(const aIdv: TGAIndividual; aLogIt: Boolean = False; aK: Word = 0);
  public
    constructor Create;
    destructor Destroy; override;

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
      //ARMY_MaxGgroupsInCompany..ARMY_PATHFINDING_AvoidTraffic,
      //ATTACK_COMPANY_AttackRadius..ATTACK_COMPANY_TimePerATile_Slow,
      ATTACK_SQUAD_START..ATTACK_SQUAD_END
    ];
  SetArmyAttackNew:
    TAIParSet = [
      ATTACK_ArmyVectorField_START..ATTACK_ArmyVectorField_END,
      ATTACK_SQUAD_START..ATTACK_SQUAD_END,
      ATTACK_SUPERVISOR_START..ATTACK_SUPERVISOR_END,
      NAVMESH_PATHFINDING_START..NAVMESH_PATHFINDING_END
    ];
  SetCityAllIn:
    TAIParSet = [
      BUILDER_START..ROADS_END
    ];
  SetCityBuilder:
    TAIParSet = [
      BUILDER_START..BUILDER_END
    ];
  SetCityPlanner:
    TAIParSet = [
      PLANNER_FindPlaceForHouse_START..PLANNER_FindPlaceForHouse_END,
      PLANNER_Snap_START..PLANNER_Snap_END
    ];
  SetFarm:
    TAIParSet = [
      PLANNER_FARM_START..PLANNER_FARM_END
    ];
  SetForest:
    TAIParSet = [
      EYE_GetForests_START..EYE_GetForests_END,
      PLANNER_FOREST_START..PLANNER_FOREST_END
    ];
  SetManager:
    TAIParSet = [
      MANAGEMENT_START..MANAGEMENT_END,
      PREDICTOR_START..PREDICTOR_END
    ];
  SetQuarry:
    TAIParSet = [
      PLANNER_FindPlaceForQuary_START..PLANNER_FindPlaceForQuary_END
    ];
  SetRoadPlanner:
    TAIParSet = [
      SHORTCUTS_START..SHORTCUTS_END,
      ROADS_START..ROADS_END
    ];


{ TGAParameterization }
constructor TGAParameterization.Create;
begin
  inherited;

  fLogPar := nil;
  fClass := '';
end;


destructor TGAParameterization.Destroy;
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
    LogParameters(aIdv);
{$ENDIF}
end;


procedure TGAParameterization.LogParameters(const aIdv: TGAIndividual);
var
  K: Integer;
  Idx: TAIPar;
  params: TAIParSet;
  enumName, comma: String;
begin
  if (fLogPar = nil) then
    Exit;
  // Log all parameters
  fLogPar.AddTime('  AI_Par: array[TAIPar] of Single = (');
  for Idx := Low(AI_Par) to High(AI_Par) do
  begin
    comma := ',';
    if Idx = High(AI_Par) then
      comma := ' ';
    enumName := GetEnumName(TypeInfo(TAIPar), Integer(Idx));
    fLogPar.AddTime(Format('%13.7f%s // %s', [AI_Par[Idx], comma, enumName], TFormatSettings.Invariant));
    if ContainsText(enumName, '_END') then
      fLogPar.AddTime(' ');
    //fLogPar.AddTime('%13.7f%s, // %s', [AI_Par[Idx], StringOfChar(' ', Max(1,50 - Length(enumName))), enumName]);
  end;
  fLogPar.AddTime('  );');
  // Log only tested parameters
  K := 0;
  params := GetSetPar();
  for Idx in params do
  begin
    enumName := GetEnumName(TypeInfo(TAIPar), Integer(Idx));
    if not ContainsText(enumName, '_END') AND not ContainsText(enumName, '_START') then
      fLogPar.AddTime(Format('%3d. %1.3f: %7.3f, // %s', [K, aIdv.Gene[K], AI_Par[Idx], enumName], TFormatSettings.Invariant));
    Inc(K);
  end;

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
  else if (CompareStr(fClass, 'TKMRunnerGA_ArmyAttackNew') = 0) then SetParameters(SetArmyAttackNew, aIdv, aLogIt);
end;


function TGAParameterization.GetSetPar(): TAIParSet;
begin
  if      (CompareStr(fClass, 'TKMRunnerGA_CityAllIn'    ) = 0) then Result := SetCityAllIn
  else if (CompareStr(fClass, 'TKMRunnerGA_CityBuilder'  ) = 0) then Result := SetCityBuilder
  else if (CompareStr(fClass, 'TKMRunnerGA_CityPlanner'  ) = 0) then Result := SetCityPlanner
  else if (CompareStr(fClass, 'TKMRunnerGA_Farm'         ) = 0) then Result := SetFarm
  else if (CompareStr(fClass, 'TKMRunnerGA_Forest'       ) = 0) then Result := SetForest
  else if (CompareStr(fClass, 'TKMRunnerGA_HandLogistics') = 0) then Result := []
  else if (CompareStr(fClass, 'TKMRunnerGA_Manager'      ) = 0) then Result := SetManager
  else if (CompareStr(fClass, 'TKMRunnerGA_Quarry'       ) = 0) then Result := SetQuarry
  else if (CompareStr(fClass, 'TKMRunnerGA_RoadPlanner'  ) = 0) then Result := SetRoadPlanner
  else if (CompareStr(fClass, 'TKMRunnerGA_ArmyAttack'   ) = 0) then Result := SetArmyAttack
  else if (CompareStr(fClass, 'TKMRunnerGA_ArmyAttackNew') = 0) then Result := SetArmyAttackNew;
end;


function TGAParameterization.GetParCnt_TestParRun(): Word;
begin
  Result := 10;
end;


function TGAParameterization.GetParCnt_HandLogistics(): Word;
begin
  Result := 0;
end;


procedure TGAParameterization.SetPar_HandLogistics(const aIdv: TGAIndividual; aLogIt: Boolean = False; aK: Word = 0);
//var
//  I: Integer;
begin
  //I := 0;

  //GA_TCBB_BasicInit   := Max(1, Round(aIdv.Gene[Incr(aK)] * 20));
  //GA_TCBB_BasicRnd    := Max(1, Round(aIdv.Gene[Incr(aK)] * 60)+40);
  //GA_TCBB_NormRnd     := Max(1, Round(aIdv.Gene[Incr(aK)] * 32));
  //GA_TCBB_Rnd         := Max(1, Round(aIdv.Gene[Incr(aK)] * 50));
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
