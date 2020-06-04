{
Artificial intelligence
@author: Martin Toupal
@e-mail: poznamenany@gmail.com
}
unit KM_AIParameters;
{$I KaM_Remake.inc}

interface
uses
  SysUtils;

{$IFDEF PARALLEL_RUNNER}
  procedure LoadGAParameters(LoadStream: TKMemoryStream);
  procedure SaveGAParameters(SaveStream: TKMemoryStream);
{$ENDIF}


// AI parameters in enumerations
type

  TAIPar = (
     ARMY_MaxGgroupsInCompany
    ,ARMY_PATHFINDING_AvoidEdges
    ,ARMY_PATHFINDING_AvoidSpecEnemy
    ,ARMY_PATHFINDING_AvoidTraffic

    ,ATTACK_ArmyVectorField_EvalClusters_InPlace
    ,ATTACK_ArmyVectorField_EvalClusters_AtAdvantage
    ,ATTACK_ArmyVectorField_EvalClusters_Ambushed
    ,ATTACK_ArmyVectorField_DivideForces_DefendCityAdv

    ,ATTACK_COMPANY_AttackRadius
    ,ATTACK_COMPANY_AttackRangedGain
    ,ATTACK_COMPANY_DecreaseThreat_Prio1
    ,ATTACK_COMPANY_DecreaseThreat_Prio2
    ,ATTACK_COMPANY_DecreaseThreat_Prio3
    ,ATTACK_COMPANY_DecreaseThreat_Prio4
    ,ATTACK_COMPANY_GroupTypePenalization
    ,ATTACK_COMPANY_MinCombatSpacing
    ,ATTACK_COMPANY_MinWalkSpacing
    ,ATTACK_COMPANY_MinimumMovement
    ,ATTACK_COMPANY_Positioning_InitPolyCnt
    ,ATTACK_COMPANY_ProtectRangedAllInDist
    ,ATTACK_COMPANY_ProtectRangedGain
    ,ATTACK_COMPANY_ProtectRangedRadius
    ,ATTACK_COMPANY_TimePerATile_Fast
    ,ATTACK_COMPANY_TimePerATile_Slow

    ,ATTACK_NMAP_BackwardFlood_MaxAllyInfluence
    ,ATTACK_NMAP_BackwardFlood_MaxEnemyInfluence
    ,ATTACK_NMAP_EvaluateLine_MinDist
    ,ATTACK_NMAP_EvaluateLine_QueueCnt
    ,ATTACK_NMAP_PrefillDistances_Groups
    ,ATTACK_NMAP_PrefillDistances_Houses
    ,ATTACK_NMAP_TArmyBackwardFF_EnemyInfluence

    ,ATTACK_SQUAD_ChangeTarget_Delay
    ,ATTACK_SQUAD_ChangeTarget_DistTolerance
    ,ATTACK_SQUAD_MinWalkingDistance
    ,ATTACK_SQUAD_TargetReached_House
    ,ATTACK_SQUAD_TargetReached_Position
    ,ATTACK_SQUAD_TargetReached_RangedSquad
    ,ATTACK_SQUAD_TargetReached_Unit

    ,ATTACK_SUPERVISOR_EvalTarget_DistanceGroup
    ,ATTACK_SUPERVISOR_EvalTarget_OpportunityDistGain
    ,ATTACK_SUPERVISOR_EvalTarget_OpportunityGain
    ,ATTACK_SUPERVISOR_EvalTarget_ThreatGainAntiHorse
    ,ATTACK_SUPERVISOR_EvalTarget_ThreatGainDist
    ,ATTACK_SUPERVISOR_EvalTarget_ThreatGainMelee
    ,ATTACK_SUPERVISOR_EvalTarget_ThreatGainMounted
    ,ATTACK_SUPERVISOR_EvalTarget_ThreatGainRangDist
    ,ATTACK_SUPERVISOR_EvalTarget_ThreatGainRanged
    ,ATTACK_SUPERVISOR_UpdateAttacks_AttackThreshold

    ,BUILDER_BuildHouse_FieldMaxWork
    ,BUILDER_BuildHouse_RTPMaxWork
    ,BUILDER_BuildHouse_RoadMaxWork
    ,BUILDER_ChHTB_AllWorkerCoef
    ,BUILDER_ChHTB_FractionCoef
    ,BUILDER_ChHTB_FreeWorkerCoef
    ,BUILDER_ChHTB_TrunkBalance
    ,BUILDER_ChHTB_TrunkFactor
    ,BUILDER_CreateShortcuts_MaxWork
    ,BUILDER_Shortage_Gold
    ,BUILDER_Shortage_Stone
    ,BUILDER_Shortage_StoneReserve
    ,BUILDER_Shortage_Trunk
    ,BUILDER_Shortage_Wood

    ,EYE_GetForests_MaxAB
    ,EYE_GetForests_MinRndSoil
    ,EYE_GetForests_MinTrees
    ,EYE_GetForests_Radius
    ,EYE_GetForests_SPRndOwnLimMax
    ,EYE_GetForests_SPRndOwnLimMin

    ,MANAGEMENT_CheckUnitCount_SerfGoldCoef
    ,MANAGEMENT_CheckUnitCount_SerfLimit1
    ,MANAGEMENT_CheckUnitCount_SerfLimit2
    ,MANAGEMENT_CheckUnitCount_SerfLimit3
    ,MANAGEMENT_CheckUnitCount_WorkerGoldCoef
    ,MANAGEMENT_GoldShortage

    ,PLANNER_FARM_FieldCrit_FlatArea
    ,PLANNER_FARM_FieldCrit_PolyRoute
    ,PLANNER_FARM_FieldCrit_Soil
    ,PLANNER_FARM_FindPlaceForHouse_CityCenter
    ,PLANNER_FARM_FindPlaceForHouse_FlatArea
    ,PLANNER_FARM_FindPlaceForHouse_HouseDist
    ,PLANNER_FARM_FindPlaceForHouse_Route
    ,PLANNER_FARM_PlanFields_CanBuild
    ,PLANNER_FARM_PlanFields_Dist
    ,PLANNER_FARM_PlanFields_ExistField

    ,PLANNER_FindPlaceForHouse_CityCenter
    ,PLANNER_FindPlaceForHouse_FlatArea
    ,PLANNER_FindPlaceForHouse_HouseDist
    ,PLANNER_FindPlaceForHouse_Route
    ,PLANNER_FindPlaceForHouse_SeedDist
    ,PLANNER_FindPlaceForHouse_SnapCrit
    ,PLANNER_FindPlaceForQuary_DistCity
    ,PLANNER_FindPlaceForQuary_DistStone
    ,PLANNER_FindPlaceForQuary_DistTimer
    ,PLANNER_FindPlaceForQuary_Obstacle
    ,PLANNER_FindPlaceForQuary_SnapCrit

    ,PLANNER_FOREST_FindForestAround_MaxDist
    ,PLANNER_FOREST_FindPlaceForWoodcutter_ABRange
    ,PLANNER_FOREST_FindPlaceForWoodcutter_DistCrit
    ,PLANNER_FOREST_FindPlaceForWoodcutter_DistTimer
    ,PLANNER_FOREST_FindPlaceForWoodcutter_ExistForest
    ,PLANNER_FOREST_FindPlaceForWoodcutter_FlatArea
    ,PLANNER_FOREST_FindPlaceForWoodcutter_FreeTiles
    ,PLANNER_FOREST_FindPlaceForWoodcutter_Radius
    ,PLANNER_FOREST_FindPlaceForWoodcutter_Routes
    ,PLANNER_FOREST_FindPlaceForWoodcutter_Soil
    ,PLANNER_FOREST_FindPlaceForWoodcutter_TreeCnt
    ,PLANNER_FOREST_FindPlaceForWoodcutter_TreeCntTimer
    ,PLANNER_FOREST_PlaceWoodcutter_DistFromForest

    ,PLANNER_ObstaclesInHousePlan_Road
    ,PLANNER_ObstaclesInHousePlan_Tree
    ,PLANNER_SnapCrit_Field
    ,PLANNER_SnapCrit_HouseOrRoad
    ,PLANNER_SnapCrit_NoBuild
    ,PLANNER_SnapCrit_ObstacleInEntrance
    ,PLANNER_SnapCrit_Road
    ,PLANNER_SnapCrit_RoadInEntrance

    ,PREDICTOR_SecondSchool_MinRequiredUnits
    ,PREDICTOR_WareNeedPerAWorker_Stone
    ,PREDICTOR_WareNeedPerAWorker_StoneOffset
    ,PREDICTOR_WareNeedPerAWorker_Wood

    ,SHORTCUTS_BasePrice
    ,SHORTCUTS_Coal
    ,SHORTCUTS_Field
    ,SHORTCUTS_Forest
    ,SHORTCUTS_OtherCase
    ,SHORTCUTS_Road
    ,SHORTCUTS_TurnPenalization
    ,SHORTCUTS_noBuildArea
    ,ROADS_BasePrice
    ,ROADS_Coal
    ,ROADS_Field
    ,ROADS_Forest
    ,ROADS_OtherCase
    ,ROADS_Road
    ,ROADS_TurnPenalization
    ,ROADS_noBuildArea
  );


// Global constants for AI
//const

// Global variables for AI
{$IFDEF DEBUG_NewAI}
var
{$ELSE}
const
{$ENDIF}

AI_Par: array[TAIPar] of Single = (
         7.0000000, // ARMY_MaxGgroupsInCompany
         3.0505981, // ARMY_PATHFINDING_AvoidEdges
         1.0583768, // ARMY_PATHFINDING_AvoidSpecEnemy
         0.1000000, // ARMY_PATHFINDING_AvoidTraffic
         0.7500000, // ATTACK_ArmyVectorField_EvalClusters_InPlace
         1.5000000, // ATTACK_ArmyVectorField_EvalClusters_AtAdvantage
         0.2000000, // ATTACK_ArmyVectorField_EvalClusters_Ambushed
         0.5000000, // ATTACK_ArmyVectorField_DivideForces_DefendCityAdv
        14.0000000, // ATTACK_COMPANY_AttackRadius
         3.8477340, // ATTACK_COMPANY_AttackRangedGain
         0.6768462, // ATTACK_COMPANY_DecreaseThreat_Prio1
         0.6052376, // ATTACK_COMPANY_DecreaseThreat_Prio2
         0.9684158, // ATTACK_COMPANY_DecreaseThreat_Prio3
         0.4872158, // ATTACK_COMPANY_DecreaseThreat_Prio4
       157.0000000, // ATTACK_COMPANY_GroupTypePenalization
         3.0000000, // ATTACK_COMPANY_MinCombatSpacing
         3.0000000, // ATTACK_COMPANY_MinWalkSpacing
         5.0000000, // ATTACK_COMPANY_MinimumMovement
         1.0000000, // ATTACK_COMPANY_Positioning_InitPolyCnt
         4.0000000, // ATTACK_COMPANY_ProtectRangedAllInDist
         1.5641868, // ATTACK_COMPANY_ProtectRangedGain
         9.0000000, // ATTACK_COMPANY_ProtectRangedRadius
         3.0000000, // ATTACK_COMPANY_TimePerATile_Fast
         3.0000000, // ATTACK_COMPANY_TimePerATile_Slow
        15.0000000, // ATTACK_NMAP_BackwardFlood_MaxAllyInfluence
        30.0000000, // ATTACK_NMAP_BackwardFlood_MaxEnemyInfluence
         0.4369974, // ATTACK_NMAP_EvaluateLine_MinDist
         0.1092338, // ATTACK_NMAP_EvaluateLine_QueueCnt
        29.0000000, // ATTACK_NMAP_PrefillDistances_Groups
         5.0000000, // ATTACK_NMAP_PrefillDistances_Houses
         4.0000000, // ATTACK_NMAP_TArmyBackwardFF_EnemyInfluence
       697.0000000, // ATTACK_SQUAD_ChangeTarget_Delay
         6.1796260, // ATTACK_SQUAD_ChangeTarget_DistTolerance
         4.0000000, // ATTACK_SQUAD_MinWalkingDistance
         8.0000000, // ATTACK_SQUAD_TargetReached_House
         2.0000000, // ATTACK_SQUAD_TargetReached_Position
        14.0000000, // ATTACK_SQUAD_TargetReached_RangedSquad
        12.0000000, // ATTACK_SQUAD_TargetReached_Unit
        20.0000000, // ATTACK_SUPERVISOR_EvalTarget_DistanceGroup
         0.1000000, // ATTACK_SUPERVISOR_EvalTarget_OpportunityDistGain
         1.0000000, // ATTACK_SUPERVISOR_EvalTarget_OpportunityGain
         1.0000000, // ATTACK_SUPERVISOR_EvalTarget_ThreatGainAntiHorse
         1.0000000, // ATTACK_SUPERVISOR_EvalTarget_ThreatGainDist
         1.0000000, // ATTACK_SUPERVISOR_EvalTarget_ThreatGainMelee
         1.0000000, // ATTACK_SUPERVISOR_EvalTarget_ThreatGainMounted
         1.0000000, // ATTACK_SUPERVISOR_EvalTarget_ThreatGainRangDist
         1.0000000, // ATTACK_SUPERVISOR_EvalTarget_ThreatGainRanged
         0.7455105, // ATTACK_SUPERVISOR_UpdateAttacks_AttackThreshold
         1.6684477, // BUILDER_BuildHouse_FieldMaxWork
        11.6014986, // BUILDER_BuildHouse_RTPMaxWork
        21.6772480, // BUILDER_BuildHouse_RoadMaxWork
         8.1070709, // BUILDER_ChHTB_AllWorkerCoef
        21.3621922, // BUILDER_ChHTB_FractionCoef
        17.1468201, // BUILDER_ChHTB_FreeWorkerCoef
         0.2159205, // BUILDER_ChHTB_TrunkBalance
        11.5937538, // BUILDER_ChHTB_TrunkFactor
        10.0000000, // BUILDER_CreateShortcuts_MaxWork
        29.1807594, // BUILDER_Shortage_Gold
        11.7483110, // BUILDER_Shortage_Stone
        14.0460310, // BUILDER_Shortage_StoneReserve
         1.8335937, // BUILDER_Shortage_Trunk
        19.8352127, // BUILDER_Shortage_Wood
        26.4097462, // EYE_GetForests_MaxAB
        45.2892570, // EYE_GetForests_MinRndSoil
         2.9898586, // EYE_GetForests_MinTrees
         6.1196084, // EYE_GetForests_Radius
       165.0055695, // EYE_GetForests_SPRndOwnLimMax
        98.0682449, // EYE_GetForests_SPRndOwnLimMin
         0.3049391, // MANAGEMENT_CheckUnitCount_SerfGoldCoef
        22.1768589, // MANAGEMENT_CheckUnitCount_SerfLimit1
        34.9827499, // MANAGEMENT_CheckUnitCount_SerfLimit2
        51.9892654, // MANAGEMENT_CheckUnitCount_SerfLimit3
         2.2670105, // MANAGEMENT_CheckUnitCount_WorkerGoldCoef
         6.1128011, // MANAGEMENT_GoldShortage
        10.8081493, // PLANNER_FARM_FieldCrit_FlatArea
         1.6080004, // PLANNER_FARM_FieldCrit_PolyRoute
         1.9612305, // PLANNER_FARM_FieldCrit_Soil
         4.7511997, // PLANNER_FARM_FindPlaceForHouse_CityCenter
         8.6881905, // PLANNER_FARM_FindPlaceForHouse_FlatArea
        11.3342533, // PLANNER_FARM_FindPlaceForHouse_HouseDist
         1.7072186, // PLANNER_FARM_FindPlaceForHouse_Route
        20.8064556, // PLANNER_FARM_PlanFields_CanBuild
        40.4509315, // PLANNER_FARM_PlanFields_Dist
        50.7865372, // PLANNER_FARM_PlanFields_ExistField
        40.0904541, // PLANNER_FindPlaceForHouse_CityCenter
         2.7339566, // PLANNER_FindPlaceForHouse_FlatArea
        43.2200470, // PLANNER_FindPlaceForHouse_HouseDist
         2.4208529, // PLANNER_FindPlaceForHouse_Route
        25.1297512, // PLANNER_FindPlaceForHouse_SeedDist
         0.8601482, // PLANNER_FindPlaceForHouse_SnapCrit
        31.5224438, // PLANNER_FindPlaceForQuary_DistCity
        12.8906088, // PLANNER_FindPlaceForQuary_DistStone
      1080.8776855, // PLANNER_FindPlaceForQuary_DistTimer
        85.5322800, // PLANNER_FindPlaceForQuary_Obstacle
        56.4987259, // PLANNER_FindPlaceForQuary_SnapCrit
         8.3981934, // PLANNER_FOREST_FindForestAround_MaxDist
        43.0639000, // PLANNER_FOREST_FindPlaceForWoodcutter_ABRange
        18.3647213, // PLANNER_FOREST_FindPlaceForWoodcutter_DistCrit
      6053.0366211, // PLANNER_FOREST_FindPlaceForWoodcutter_DistTimer
       359.9281311, // PLANNER_FOREST_FindPlaceForWoodcutter_ExistForest
         5.8913641, // PLANNER_FOREST_FindPlaceForWoodcutter_FlatArea
         4.6900163, // PLANNER_FOREST_FindPlaceForWoodcutter_FreeTiles
         3.5208817, // PLANNER_FOREST_FindPlaceForWoodcutter_Radius
        -0.6038398, // PLANNER_FOREST_FindPlaceForWoodcutter_Routes
         0.1276233, // PLANNER_FOREST_FindPlaceForWoodcutter_Soil
         7.2485070, // PLANNER_FOREST_FindPlaceForWoodcutter_TreeCnt
     21258.1250000, // PLANNER_FOREST_FindPlaceForWoodcutter_TreeCntTimer
         0.2943508, // PLANNER_FOREST_PlaceWoodcutter_DistFromForest
       293.8428345, // PLANNER_ObstaclesInHousePlan_Road
       599.5475464, // PLANNER_ObstaclesInHousePlan_Tree
        27.8181629, // PLANNER_SnapCrit_Field
         1.1461508, // PLANNER_SnapCrit_HouseOrRoad
        -9.2810154, // PLANNER_SnapCrit_NoBuild
       201.9597015, // PLANNER_SnapCrit_ObstacleInEntrance
        61.5381699, // PLANNER_SnapCrit_Road
        22.1572151, // PLANNER_SnapCrit_RoadInEntrance
        44.3221283, // PREDICTOR_SecondSchool_MinRequiredUnits
         0.6563203, // PREDICTOR_WareNeedPerAWorker_Stone
         6.7707891, // PREDICTOR_WareNeedPerAWorker_StoneOffset
         0.3007088, // PREDICTOR_WareNeedPerAWorker_Wood
       105.4901276, // SHORTCUTS_BasePrice
        36.0100517, // SHORTCUTS_Coal
        28.4500065, // SHORTCUTS_Field
        46.3248215, // SHORTCUTS_Forest
        23.4434166, // SHORTCUTS_OtherCase
        39.0297012, // SHORTCUTS_Road
        70.4304733, // SHORTCUTS_TurnPenalization
        34.4703903, // SHORTCUTS_noBuildArea
        32.6338196, // ROADS_BasePrice
        20.8406906, // ROADS_Coal
        41.7385406, // ROADS_Field
        49.8783913, // ROADS_Forest
        33.5808334, // ROADS_OtherCase
        26.4302139, // ROADS_Road
        27.7078152, // ROADS_TurnPenalization
        39.9684258  // ROADS_noBuildArea
);


{$IFDEF DEBUG_NewAI}
const
  AI_Par_Offset: array[TAIPar] of Single = (
        5.00, // ARMY_MaxGgroupsInCompany
       80.00, // ARMY_PATHFINDING_AvoidEdges
        0.00, // ARMY_PATHFINDING_AvoidSpecEnemy
        0.00, // ARMY_PATHFINDING_AvoidTraffic
        0.00, // ATTACK_ArmyVectorField_EvalClusters_InPlace
        0.00, // ATTACK_ArmyVectorField_EvalClusters_AtAdvantage
        0.00, // ATTACK_ArmyVectorField_EvalClusters_Ambushed
        0.00, // ATTACK_ArmyVectorField_DivideForces_DefendCityAdv
        9.00, // ATTACK_COMPANY_AttackRadius
        0.00, // ATTACK_COMPANY_AttackRangedGain
        0.00, // ATTACK_COMPANY_DecreaseThreat_Prio1
        0.00, // ATTACK_COMPANY_DecreaseThreat_Prio2
        0.00, // ATTACK_COMPANY_DecreaseThreat_Prio3
        0.00, // ATTACK_COMPANY_DecreaseThreat_Prio4
      100.00, // ATTACK_COMPANY_GroupTypePenalization
        2.00, // ATTACK_COMPANY_MinCombatSpacing
        2.00, // ATTACK_COMPANY_MinWalkSpacing
        3.00, // ATTACK_COMPANY_MinimumMovement
        1.00, // ATTACK_COMPANY_Positioning_InitPolyCnt
        2.00, // ATTACK_COMPANY_ProtectRangedAllInDist
        2.00, // ATTACK_COMPANY_ProtectRangedGain
        6.00, // ATTACK_COMPANY_ProtectRangedRadius
        2.00, // ATTACK_COMPANY_TimePerATile_Fast
        2.00, // ATTACK_COMPANY_TimePerATile_Slow
        0.00, // ATTACK_NMAP_BackwardFlood_MaxAllyInfluence
        0.00, // ATTACK_NMAP_BackwardFlood_MaxEnemyInfluence
        0.00, // ATTACK_NMAP_EvaluateLine_MinDist
        0.00, // ATTACK_NMAP_EvaluateLine_QueueCnt
        0.00, // ATTACK_NMAP_PrefillDistances_Groups
        0.00, // ATTACK_NMAP_PrefillDistances_Houses
        0.00, // ATTACK_NMAP_TArmyBackwardFF_EnemyInfluence
      400.00, // ATTACK_SQUAD_ChangeTarget_Delay
        4.00, // ATTACK_SQUAD_ChangeTarget_DistTolerance
       10.00, // ATTACK_SQUAD_MinWalkingDistance
        0.00, // ATTACK_SQUAD_TargetReached_House
        1.00, // ATTACK_SQUAD_TargetReached_Position
       12.00, // ATTACK_SQUAD_TargetReached_RangedSquad
        8.00, // ATTACK_SQUAD_TargetReached_Unit
        0.00, // ATTACK_SUPERVISOR_EvalTarget_DistanceGroup
        0.00, // ATTACK_SUPERVISOR_EvalTarget_OpportunityDistGain
        0.00, // ATTACK_SUPERVISOR_EvalTarget_OpportunityGain
        0.00, // ATTACK_SUPERVISOR_EvalTarget_ThreatGainAntiHorse
        0.00, // ATTACK_SUPERVISOR_EvalTarget_ThreatGainDist
        0.00, // ATTACK_SUPERVISOR_EvalTarget_ThreatGainMelee
        0.00, // ATTACK_SUPERVISOR_EvalTarget_ThreatGainMounted
        0.00, // ATTACK_SUPERVISOR_EvalTarget_ThreatGainRangDist
        0.00, // ATTACK_SUPERVISOR_EvalTarget_ThreatGainRanged
        0.00, // ATTACK_SUPERVISOR_UpdateAttacks_AttackThreshold
        1.00, // BUILDER_BuildHouse_FieldMaxWork
        1.00, // BUILDER_BuildHouse_RTPMaxWork
        5.00, // BUILDER_BuildHouse_RoadMaxWork
        8.00, // BUILDER_ChHTB_AllWorkerCoef
        5.00, // BUILDER_ChHTB_FractionCoef
        8.00, // BUILDER_ChHTB_FreeWorkerCoef
        0.00, // BUILDER_ChHTB_TrunkBalance
        8.00, // BUILDER_ChHTB_TrunkFactor
        1.00, // BUILDER_CreateShortcuts_MaxWork
        0.00, // BUILDER_Shortage_Gold
       10.00, // BUILDER_Shortage_Stone
       10.00, // BUILDER_Shortage_StoneReserve
        1.00, // BUILDER_Shortage_Trunk
        3.00, // BUILDER_Shortage_Wood
        1.00, // EYE_GetForests_MaxAB
       40.00, // EYE_GetForests_MinRndSoil
        1.00, // EYE_GetForests_MinTrees
        5.00, // EYE_GetForests_Radius
      100.00, // EYE_GetForests_SPRndOwnLimMax
        0.00, // EYE_GetForests_SPRndOwnLimMin
        0.10, // MANAGEMENT_CheckUnitCount_SerfGoldCoef
        5.00, // MANAGEMENT_CheckUnitCount_SerfLimit1
       20.00, // MANAGEMENT_CheckUnitCount_SerfLimit2
       40.00, // MANAGEMENT_CheckUnitCount_SerfLimit3
        0.10, // MANAGEMENT_CheckUnitCount_WorkerGoldCoef
        1.00, // MANAGEMENT_GoldShortage
        0.00, // PLANNER_FARM_FieldCrit_FlatArea
        0.00, // PLANNER_FARM_FieldCrit_PolyRoute
        0.00, // PLANNER_FARM_FieldCrit_Soil
        0.00, // PLANNER_FARM_FindPlaceForHouse_CityCenter
        0.00, // PLANNER_FARM_FindPlaceForHouse_FlatArea
        5.00, // PLANNER_FARM_FindPlaceForHouse_HouseDist
       -2.00, // PLANNER_FARM_FindPlaceForHouse_Route
        0.00, // PLANNER_FARM_PlanFields_CanBuild
        0.00, // PLANNER_FARM_PlanFields_Dist
       30.00, // PLANNER_FARM_PlanFields_ExistField
        0.00, // PLANNER_FindPlaceForHouse_CityCenter
        0.00, // PLANNER_FindPlaceForHouse_FlatArea
       25.00, // PLANNER_FindPlaceForHouse_HouseDist
        0.00, // PLANNER_FindPlaceForHouse_Route
        0.00, // PLANNER_FindPlaceForHouse_SeedDist
        0.00, // PLANNER_FindPlaceForHouse_SnapCrit
        0.00, // PLANNER_FindPlaceForQuary_DistCity
        0.00, // PLANNER_FindPlaceForQuary_DistStone
        0.00, // PLANNER_FindPlaceForQuary_DistTimer
       40.00, // PLANNER_FindPlaceForQuary_Obstacle
       10.00, // PLANNER_FindPlaceForQuary_SnapCrit
        5.00, // PLANNER_FOREST_FindForestAround_MaxDist
        0.00, // PLANNER_FOREST_FindPlaceForWoodcutter_ABRange
        8.00, // PLANNER_FOREST_FindPlaceForWoodcutter_DistCrit
        0.00, // PLANNER_FOREST_FindPlaceForWoodcutter_DistTimer
        0.00, // PLANNER_FOREST_FindPlaceForWoodcutter_ExistForest
        0.00, // PLANNER_FOREST_FindPlaceForWoodcutter_FlatArea
        0.00, // PLANNER_FOREST_FindPlaceForWoodcutter_FreeTiles
        3.00, // PLANNER_FOREST_FindPlaceForWoodcutter_Radius
       -1.00, // PLANNER_FOREST_FindPlaceForWoodcutter_Routes
        0.00, // PLANNER_FOREST_FindPlaceForWoodcutter_Soil
        0.00, // PLANNER_FOREST_FindPlaceForWoodcutter_TreeCnt
    12000.00, // PLANNER_FOREST_FindPlaceForWoodcutter_TreeCntTimer
        0.00, // PLANNER_FOREST_PlaceWoodcutter_DistFromForest
      200.00, // PLANNER_ObstaclesInHousePlan_Road
      500.00, // PLANNER_ObstaclesInHousePlan_Tree
      -20.00, // PLANNER_SnapCrit_Field
      -30.00, // PLANNER_SnapCrit_HouseOrRoad
      -30.00, // PLANNER_SnapCrit_NoBuild
        0.00, // PLANNER_SnapCrit_ObstacleInEntrance
       25.00, // PLANNER_SnapCrit_Road
        0.00, // PLANNER_SnapCrit_RoadInEntrance
       20.00, // PREDICTOR_SecondSchool_MinRequiredUnits
        0.50, // PREDICTOR_WareNeedPerAWorker_Stone
        5.00, // PREDICTOR_WareNeedPerAWorker_StoneOffset
        0.01, // PREDICTOR_WareNeedPerAWorker_Wood
       70.00, // SHORTCUTS_BasePrice
       20.00, // SHORTCUTS_Coal
        0.00, // SHORTCUTS_Field
       10.00, // SHORTCUTS_Forest
        0.00, // SHORTCUTS_OtherCase
        0.00, // SHORTCUTS_Road
       35.00, // SHORTCUTS_TurnPenalization
       20.00, // SHORTCUTS_noBuildArea
       25.00, // ROADS_BasePrice
        0.00, // ROADS_Coal
       20.00, // ROADS_Field
       30.00, // ROADS_Forest
        0.00, // ROADS_OtherCase
        0.00, // ROADS_Road
        0.00, // ROADS_TurnPenalization
       15.00  // ROADS_noBuildArea
  );


  AI_Par_Gain: array[TAIPar] of Single = (
       15.00, // ARMY_MaxGgroupsInCompany
       80.00, // ARMY_PATHFINDING_AvoidEdges
       10.00, // ARMY_PATHFINDING_AvoidSpecEnemy
        3.00, // ARMY_PATHFINDING_AvoidTraffic
        1.00, // ATTACK_ArmyVectorField_EvalClusters_InPlace
        3.00, // ATTACK_ArmyVectorField_EvalClusters_AtAdvantage
        1.00, // ATTACK_ArmyVectorField_EvalClusters_Ambushed
        1.00, // ATTACK_ArmyVectorField_DivideForces_DefendCityAdv
       11.00, // ATTACK_COMPANY_AttackRadius
       10.00, // ATTACK_COMPANY_AttackRangedGain
        1.00, // ATTACK_COMPANY_DecreaseThreat_Prio1
        1.00, // ATTACK_COMPANY_DecreaseThreat_Prio2
        1.00, // ATTACK_COMPANY_DecreaseThreat_Prio3
        1.00, // ATTACK_COMPANY_DecreaseThreat_Prio4
      100.00, // ATTACK_COMPANY_GroupTypePenalization
        3.00, // ATTACK_COMPANY_MinCombatSpacing
        3.00, // ATTACK_COMPANY_MinWalkSpacing
       15.00, // ATTACK_COMPANY_MinimumMovement
        3.00, // ATTACK_COMPANY_Positioning_InitPolyCnt
        5.00, // ATTACK_COMPANY_ProtectRangedAllInDist
        5.00, // ATTACK_COMPANY_ProtectRangedGain
        8.00, // ATTACK_COMPANY_ProtectRangedRadius
        3.00, // ATTACK_COMPANY_TimePerATile_Fast
        3.00, // ATTACK_COMPANY_TimePerATile_Slow
       50.00, // ATTACK_NMAP_BackwardFlood_MaxAllyInfluence
       50.00, // ATTACK_NMAP_BackwardFlood_MaxEnemyInfluence
        1.00, // ATTACK_NMAP_EvaluateLine_MinDist
        2.00, // ATTACK_NMAP_EvaluateLine_QueueCnt
       50.00, // ATTACK_NMAP_PrefillDistances_Groups
       50.00, // ATTACK_NMAP_PrefillDistances_Houses
       10.00, // ATTACK_NMAP_TArmyBackwardFF_EnemyInfluence
      500.00, // ATTACK_SQUAD_ChangeTarget_Delay
        6.00, // ATTACK_SQUAD_ChangeTarget_DistTolerance
       20.00, // ATTACK_SQUAD_MinWalkingDistance
        8.00, // ATTACK_SQUAD_TargetReached_House
        4.00, // ATTACK_SQUAD_TargetReached_Position
        5.00, // ATTACK_SQUAD_TargetReached_RangedSquad
        8.00, // ATTACK_SQUAD_TargetReached_Unit
       10.00, // ATTACK_SUPERVISOR_EvalTarget_DistanceGroup
       10.00, // ATTACK_SUPERVISOR_EvalTarget_OpportunityDistGain
       10.00, // ATTACK_SUPERVISOR_EvalTarget_OpportunityGain
        5.00, // ATTACK_SUPERVISOR_EvalTarget_ThreatGainAntiHorse
      500.00, // ATTACK_SUPERVISOR_EvalTarget_ThreatGainDist
        5.00, // ATTACK_SUPERVISOR_EvalTarget_ThreatGainMelee
        5.00, // ATTACK_SUPERVISOR_EvalTarget_ThreatGainMounted
        5.00, // ATTACK_SUPERVISOR_EvalTarget_ThreatGainRangDist
        5.00, // ATTACK_SUPERVISOR_EvalTarget_ThreatGainRanged
        1.00, // ATTACK_SUPERVISOR_UpdateAttacks_AttackThreshold
        1.00, // BUILDER_BuildHouse_FieldMaxWork
       15.00, // BUILDER_BuildHouse_RTPMaxWork
       20.00, // BUILDER_BuildHouse_RoadMaxWork
       10.00, // BUILDER_ChHTB_AllWorkerCoef
       40.00, // BUILDER_ChHTB_FractionCoef
       20.00, // BUILDER_ChHTB_FreeWorkerCoef
        3.00, // BUILDER_ChHTB_TrunkBalance
       12.00, // BUILDER_ChHTB_TrunkFactor
        9.00, // BUILDER_CreateShortcuts_MaxWork
       35.00, // BUILDER_Shortage_Gold
       15.00, // BUILDER_Shortage_Stone
       40.00, // BUILDER_Shortage_StoneReserve
        3.00, // BUILDER_Shortage_Trunk
       20.00, // BUILDER_Shortage_Wood
      200.00, // EYE_GetForests_MaxAB
       22.00, // EYE_GetForests_MinRndSoil
        4.00, // EYE_GetForests_MinTrees
        4.00, // EYE_GetForests_Radius
      155.00, // EYE_GetForests_SPRndOwnLimMax
      155.00, // EYE_GetForests_SPRndOwnLimMin
        3.00, // MANAGEMENT_CheckUnitCount_SerfGoldCoef
       20.00, // MANAGEMENT_CheckUnitCount_SerfLimit1
       20.00, // MANAGEMENT_CheckUnitCount_SerfLimit2
       30.00, // MANAGEMENT_CheckUnitCount_SerfLimit3
        3.00, // MANAGEMENT_CheckUnitCount_WorkerGoldCoef
       15.00, // MANAGEMENT_GoldShortage
       15.00, // PLANNER_FARM_FieldCrit_FlatArea
        5.00, // PLANNER_FARM_FieldCrit_PolyRoute
        3.00, // PLANNER_FARM_FieldCrit_Soil
       10.00, // PLANNER_FARM_FindPlaceForHouse_CityCenter
       15.00, // PLANNER_FARM_FindPlaceForHouse_FlatArea
       15.00, // PLANNER_FARM_FindPlaceForHouse_HouseDist
        4.00, // PLANNER_FARM_FindPlaceForHouse_Route
       75.00, // PLANNER_FARM_PlanFields_CanBuild
       75.00, // PLANNER_FARM_PlanFields_Dist
       75.00, // PLANNER_FARM_PlanFields_ExistField
       80.00, // PLANNER_FindPlaceForHouse_CityCenter
        6.00, // PLANNER_FindPlaceForHouse_FlatArea
       20.00, // PLANNER_FindPlaceForHouse_HouseDist
        4.00, // PLANNER_FindPlaceForHouse_Route
       50.00, // PLANNER_FindPlaceForHouse_SeedDist
        3.00, // PLANNER_FindPlaceForHouse_SnapCrit
       50.00, // PLANNER_FindPlaceForQuary_DistCity
       50.00, // PLANNER_FindPlaceForQuary_DistStone
    15000.00, // PLANNER_FindPlaceForQuary_DistTimer
       50.00, // PLANNER_FindPlaceForQuary_Obstacle
       50.00, // PLANNER_FindPlaceForQuary_SnapCrit
        5.00, // PLANNER_FOREST_FindForestAround_MaxDist
      150.00, // PLANNER_FOREST_FindPlaceForWoodcutter_ABRange
       20.00, // PLANNER_FOREST_FindPlaceForWoodcutter_DistCrit
    10000.00, // PLANNER_FOREST_FindPlaceForWoodcutter_DistTimer
      500.00, // PLANNER_FOREST_FindPlaceForWoodcutter_ExistForest
        6.00, // PLANNER_FOREST_FindPlaceForWoodcutter_FlatArea
        6.00, // PLANNER_FOREST_FindPlaceForWoodcutter_FreeTiles
        4.00, // PLANNER_FOREST_FindPlaceForWoodcutter_Radius
        2.00, // PLANNER_FOREST_FindPlaceForWoodcutter_Routes
        3.00, // PLANNER_FOREST_FindPlaceForWoodcutter_Soil
       21.00, // PLANNER_FOREST_FindPlaceForWoodcutter_TreeCnt
    12000.00, // PLANNER_FOREST_FindPlaceForWoodcutter_TreeCntTimer
        2.00, // PLANNER_FOREST_PlaceWoodcutter_DistFromForest
      500.00, // PLANNER_ObstaclesInHousePlan_Road
     1000.00, // PLANNER_ObstaclesInHousePlan_Tree
       50.00, // PLANNER_SnapCrit_Field
       50.00, // PLANNER_SnapCrit_HouseOrRoad
       50.00, // PLANNER_SnapCrit_NoBuild
     1000.00, // PLANNER_SnapCrit_ObstacleInEntrance
       50.00, // PLANNER_SnapCrit_Road
      300.00, // PLANNER_SnapCrit_RoadInEntrance
       30.00, // PREDICTOR_SecondSchool_MinRequiredUnits
        0.30, // PREDICTOR_WareNeedPerAWorker_Stone
       10.00, // PREDICTOR_WareNeedPerAWorker_StoneOffset
        0.30, // PREDICTOR_WareNeedPerAWorker_Wood
       40.00, // SHORTCUTS_BasePrice
       50.00, // SHORTCUTS_Coal
       50.00, // SHORTCUTS_Field
       40.00, // SHORTCUTS_Forest
       50.00, // SHORTCUTS_OtherCase
       50.00, // SHORTCUTS_Road
       50.00, // SHORTCUTS_TurnPenalization
       50.00, // SHORTCUTS_noBuildArea
       30.00, // ROADS_BasePrice
       50.00, // ROADS_Coal
       40.00, // ROADS_Field
       50.00, // ROADS_Forest
       50.00, // ROADS_OtherCase
       50.00, // ROADS_Road
       50.00, // ROADS_TurnPenalization
       35.00  // ROADS_noBuildArea
  );
{$ENDIF}

implementation

{$IFDEF PARALLEL_RUNNER}
procedure LoadGAParameters(LoadStream: TKMemoryStream);
begin
  LoadStream.CheckMarker('LoadGAParameters');
  LoadStream.Read(AI_Par,SizeOf(AI_Par));
end;

procedure SaveGAParameters(SaveStream: TKMemoryStream);
begin
  SaveStream.PlaceMarker('LoadGAParameters');
  SaveStream.Write(AI_Par,SizeOf(AI_Par));
end;
{$ENDIF}

end.
