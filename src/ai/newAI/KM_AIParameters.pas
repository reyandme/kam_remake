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

// Global constants for AI
//const

  
// Global variables for AI
// They are stored in this file so Runner and Parallel runner can access it
var


{ KM_ArmyAttack }
//{ 2019-12-14
  GA_ATTACK_SQUAD_ChangeTarget_DistTolerance         : Single =     1.9587301016;
  GA_ATTACK_SQUAD_ChangeTarget_Delay                 : Word =  415;
  GA_ATTACK_SQUAD_TargetReached_Position             : Word =    6;
  GA_ATTACK_SQUAD_TargetReached_Unit                 : Word =   10;
  GA_ATTACK_SQUAD_TargetReached_House                : Word =    8;
  GA_ATTACK_SQUAD_TargetReached_RangedSquad          : Word =   15;
  GA_ATTACK_SQUAD_MinWalkingDistance                 : Word =    6;

  GA_ATTACK_COMPANY_AttackRadius                     : Word =   11;
  GA_ATTACK_COMPANY_ProtectRangedRadius              : Word =    9;
  GA_ATTACK_COMPANY_AttackRangedGain                 : Single =     1.8996825218;
  GA_ATTACK_COMPANY_ProtectRangedGain                : Single =     5.0222282410;
  GA_ATTACK_COMPANY_ProtectRangedAllInDist           : Word =    8;
  GA_ATTACK_COMPANY_DecreaseThreat_Prio1             : Single =     0.8563764095;
  GA_ATTACK_COMPANY_DecreaseThreat_Prio2             : Single =     0.4269955456;
  GA_ATTACK_COMPANY_DecreaseThreat_Prio3             : Single =     0.6608481407;
  GA_ATTACK_COMPANY_DecreaseThreat_Prio4             : Single =     0.4229704440;
  GA_ATTACK_COMPANY_TimePerATile_Slow                : Word =    5;
  GA_ATTACK_COMPANY_TimePerATile_Fast                : Word =   11;
//}

{ 2019-12-13
  GA_ATTACK_SQUAD_ChangeTarget_DistTolerance         : Single = 6; // 1-12 ~6 Archers change target if the enemy is too close
  GA_ATTACK_SQUAD_ChangeTarget_Delay                 : Word = 200; // [ticks] Archers cannot change target too often otherwise they don't shoot
  GA_ATTACK_SQUAD_TargetReached_Position             : Word =   4; // Tolerance between reached point and actual position it is useful in traffic problems
  GA_ATTACK_SQUAD_TargetReached_Unit                 : Word =   4; // Target unit should have lower tolerance because of group type pathfinding (cav will avoid spears etc)
  GA_ATTACK_SQUAD_TargetReached_House                : Word =   8; // Houses should have larger tolerance because NavMesh does not work in cities properly
  GA_ATTACK_SQUAD_TargetReached_RangedSquad          : Word =  15; // This should be more than maximal range of ranged groups (11*11)
  GA_ATTACK_SQUAD_MinWalkingDistance                 : Word =   4; // Avoid group to be stucked in cities (higher = less stuck)


  GA_ATTACK_COMPANY_AttackRadius                     : Word =  20; // Attack radius of company
  GA_ATTACK_COMPANY_ProtectRangedRadius              : Word =  10; // Radius around ranged units where requires close combat protection
  GA_ATTACK_COMPANY_AttackRangedGain                 : Single = 5;
  GA_ATTACK_COMPANY_ProtectRangedGain                : Single = 1; // Gain of threat level if enemy is close to ranged group
  GA_ATTACK_COMPANY_ProtectRangedAllInDist           : Word =   7; // If is enemy too cloose aim him but dont decrease threat level
  GA_ATTACK_COMPANY_DecreaseThreat_Prio1             : Single = 1;
  GA_ATTACK_COMPANY_DecreaseThreat_Prio2             : Single = 0.7;
  GA_ATTACK_COMPANY_DecreaseThreat_Prio3             : Single = 0.5;
  GA_ATTACK_COMPANY_DecreaseThreat_Prio4             : Single = 0.2;
  GA_ATTACK_COMPANY_TimePerATile_Slow                : Word =   7; // Max ticks per a tile (slow mode)
  GA_ATTACK_COMPANY_TimePerATile_Fast                : Word =   4; // Max ticks per a tile (fast mode)
//}



{ KM_ArmyDefence }


{ KM_ArmyManagement }


{ KM_CityBuilder }
  GA_BUILDER_BuildHouse_FieldMaxWork                 : Single =  1;
  GA_BUILDER_BuildHouse_RTPMaxWork                   : Single =  5;
  GA_BUILDER_BuildHouse_RoadMaxWork                  : Single = 16;
  GA_BUILDER_CreateShortcuts_MaxWork                 : Single = 10;
  GA_BUILDER_ChHTB_FractionCoef                      : Single =  9.352;
  GA_BUILDER_ChHTB_TrunkFactor                       : Single = 16.045;
  GA_BUILDER_ChHTB_TrunkBalance                      : Single =  2.511;
  GA_BUILDER_ChHTB_AllWorkerCoef                     : Single =  7.154;
  GA_BUILDER_ChHTB_FreeWorkerCoef                    : Single =  4.251;
  GA_BUILDER_Shortage_StoneReserve                   : Single = 29.0000000000;
  GA_BUILDER_Shortage_Stone                          : Single = 14.0000000000;
  GA_BUILDER_Shortage_Gold                           : Single = 27.638;
  GA_BUILDER_Shortage_Trunk                          : Single =  3.360;
  GA_BUILDER_Shortage_Wood                           : Single = 12.890;


{ KM_CityManagement }
//{ 2019-11-30
  GA_MANAGEMENT_GoldShortage                         : Word =    8;
  GA_MANAGEMENT_CheckUnitCount_SerfLimit1            : Word =    9;
  GA_MANAGEMENT_CheckUnitCount_SerfLimit2            : Word =   35;
  GA_MANAGEMENT_CheckUnitCount_SerfLimit3            : Word =   50;
  GA_MANAGEMENT_CheckUnitCount_WorkerGoldCoef        : Single =  2.9055855274;
  GA_MANAGEMENT_CheckUnitCount_SerfGoldCoef          : Single =  1.5343497992;
//}


{ KM_CityPlanner }
  GA_PLANNER_FindPlaceForHouse_AllyInfluence         : Single =  1; // 0..255
  GA_PLANNER_FindPlaceForHouse_EnemyInfluence        : Single = 10; // 0..255
  GA_PLANNER_FindForestAndWoodcutter_AllyInfluence   : Single =  3; // 0..255
  GA_PLANNER_FindForestAndWoodcutter_EnemyInfluence  : Single = 10; // 0..255

//{ 2019-11-25
  GA_PLANNER_ObstaclesInHousePlan_Tree               : Single =   717.8121337891;
  GA_PLANNER_ObstaclesInHousePlan_Road               : Single =   678.5110473633;
  GA_PLANNER_FieldCrit_PolyRoute                     : Single =     2.9083948135;
  GA_PLANNER_FieldCrit_FlatArea                      : Single =     7.9779438972;
  GA_PLANNER_FieldCrit_Soil                          : Single =     0.7377260327;
  GA_PLANNER_SnapCrit_SnapToHouse                    : Single =    10.4464416504;
  GA_PLANNER_SnapCrit_SnapToFields                   : Single =    11.6313076019;
  GA_PLANNER_SnapCrit_SnapToRoads                    : Single =    16.6169967651;
  GA_PLANNER_SnapCrit_ObstacleInEntrance             : Single =   275.7873535156;
  GA_PLANNER_SnapCrit_RoadInEntrance                 : Single =   295.2063903809;
  GA_PLANNER_FindPlaceForHouse_SnapCrit              : Single =     2.5595338345;
  GA_PLANNER_FindPlaceForHouse_HouseDist             : Single =    10.2654743195;
  GA_PLANNER_FindPlaceForHouse_SeedDist              : Single =    45.7494544983;
  GA_PLANNER_FindPlaceForHouse_CityCenter            : Single =    37.5235137939;
  GA_PLANNER_FindPlaceForHouse_Route                 : Single =     2.2165458202;
  GA_PLANNER_FindPlaceForHouse_FlatArea              : Single =     0.7113031149;
  GA_PLANNER_FindPlaceForHouse_RouteFarm             : Single =    -1.3569523096;
  GA_PLANNER_FindPlaceForHouse_FlatAreaFarm          : Single =    -2.1046175957;
  GA_PLANNER_FindPlaceForHouse_HouseDistFarm         : Single =     3.9945483208;
  GA_PLANNER_FindPlaceForHouse_CityCenterFarm        : Single =    30.7348155975;
  GA_PLANNER_PlaceWoodcutter_DistFromForest          : Single =     5.6932945251;
//}

{ 2019-11-24
  GA_PLANNER_ObstaclesInHousePlan_Tree               : Single =   881.6007080078;
  GA_PLANNER_ObstaclesInHousePlan_Road               : Single =   500.0000000000;
  GA_PLANNER_FieldCrit_PolyRoute                     : Single =     2.5273594856;
  GA_PLANNER_FieldCrit_FlatArea                      : Single =    10.3394212723;
  GA_PLANNER_FieldCrit_Soil                          : Single =     0.0000000000;
  GA_PLANNER_SnapCrit_SnapToHouse                    : Single =    10.6793680191;
  GA_PLANNER_SnapCrit_SnapToFields                   : Single =    22.3944587708;
  GA_PLANNER_SnapCrit_SnapToRoads                    : Single =    14.6788730621;
  GA_PLANNER_SnapCrit_ObstacleInEntrance             : Single =   326.7499694824;
  GA_PLANNER_SnapCrit_RoadInEntrance                 : Single =   380.5420837402;
  GA_PLANNER_FindPlaceForHouse_SnapCrit              : Single =     2.0000000000;
  GA_PLANNER_FindPlaceForHouse_HouseDist             : Single =    12.8775806427;
  GA_PLANNER_FindPlaceForHouse_SeedDist              : Single =    45.3871498108;
  GA_PLANNER_FindPlaceForHouse_CityCenter            : Single =    25.4636230469;
  GA_PLANNER_FindPlaceForHouse_Route                 : Single =     1.5853630304;
  GA_PLANNER_FindPlaceForHouse_FlatArea              : Single =     0.0000000000;
  GA_PLANNER_FindPlaceForHouse_RouteFarm             : Single =    -1.1291456223;
  GA_PLANNER_FindPlaceForHouse_FlatAreaFarm          : Single =    -4.0141062737;
  GA_PLANNER_FindPlaceForHouse_HouseDistFarm         : Single =     4.9828200340;
  GA_PLANNER_FindPlaceForHouse_CityCenterFarm        : Single =    24.7738304138;
  GA_PLANNER_PlaceWoodcutter_DistFromForest          : Single =     4.9499578476;
//}

{ 2019-11-23
  GA_PLANNER_ObstaclesInHousePlan_Tree               : Single = 788.3220911;
  GA_PLANNER_ObstaclesInHousePlan_Road               : Single = 219.6835876;
  GA_PLANNER_FieldCrit_PolyRoute                     : Single =   2.883937657;
  GA_PLANNER_FieldCrit_FlatArea                      : Single =   1.613979578;
  GA_PLANNER_FieldCrit_Soil                          : Single =   2.607529342;
  GA_PLANNER_SnapCrit_SnapToHouse                    : Single =   0;
  GA_PLANNER_SnapCrit_SnapToFields                   : Single =   0.288372883;
  GA_PLANNER_SnapCrit_SnapToRoads                    : Single =   7.870791852;
  GA_PLANNER_SnapCrit_ObstacleInEntrance             : Single =  19.17334318;
  GA_PLANNER_SnapCrit_RoadInEntrance                 : Single =  19.17334318;
  GA_PLANNER_FindPlaceForHouse_SnapCrit              : Single =   1.07497108;
  GA_PLANNER_FindPlaceForHouse_HouseDist             : Single =  18.67234826;
  GA_PLANNER_FindPlaceForHouse_SeedDist              : Single =  42.05959439;
  GA_PLANNER_FindPlaceForHouse_CityCenter            : Single =  43.24023426;
  GA_PLANNER_FindPlaceForHouse_Route                 : Single =   3.326784611;
  GA_PLANNER_FindPlaceForHouse_FlatArea              : Single =   1.945348799;
  GA_PLANNER_FindPlaceForHouse_RouteFarm             : Single =  -1.3515504;
  GA_PLANNER_FindPlaceForHouse_FlatAreaFarm          : Single =  -5;
  GA_PLANNER_FindPlaceForHouse_HouseDistFarm         : Single =   4.647785425;
  GA_PLANNER_FindPlaceForHouse_CityCenterFarm        : Single =  23.23892713;
  GA_PLANNER_PlaceWoodcutter_DistFromForest	         : Single =   0.899758935;
//}

  GA_PLANNER_PlanFields_CanBuild                     : Word = 33;
  GA_PLANNER_PlanFields_Dist                         : Word =  3;
  GA_PLANNER_PlanFields_ExistField                   : Word = 33;

  GA_PLANNER_FindPlaceForQuary_Obstacle              : Single =    35.4110183716;
  GA_PLANNER_FindPlaceForQuary_DistCity              : Single =    10.5008840561;
  GA_PLANNER_FindPlaceForQuary_DistTimer             : Single =     0.0000000000;
  GA_PLANNER_FindPlaceForQuary_DistStone             : Single =    32.1478843689;
  GA_PLANNER_FindPlaceForQuary_SnapCrit              : Single =     5.6924824715;

  GA_PLANNER_FindPlaceForWoodcutter_TreeCnt          : Single =    32.1456005573273;
  GA_PLANNER_FindPlaceForWoodcutter_TreeCntTimer     : Single = 13805.7332038879;
  GA_PLANNER_FindPlaceForWoodcutter_ExistForest      : Single =   406.349253058433;
  GA_PLANNER_FindPlaceForWoodcutter_Routes           : Single =     0.816604614257812;
  GA_PLANNER_FindPlaceForWoodcutter_FlatArea         : Single =     3.37718081474304;
  GA_PLANNER_FindPlaceForWoodcutter_Soil             : Single =     2.91867184638977;
  GA_PLANNER_FindPlaceForWoodcutter_DistCrit         : Single =     0.94243973493576;
  GA_PLANNER_FindPlaceForWoodcutter_DistTimer        : Single = 11655.6522846222;
  GA_PLANNER_FindPlaceForWoodcutter_FreeTiles        : Single =     3.34831988811493; // c
  GA_PLANNER_FindPlaceForWoodcutter_ABRange          : Single =   138.00858259201; // c
  GA_PLANNER_FindPlaceForWoodcutter_Radius           : Single =     4.72347187995911;
  GA_PLANNER_FindForestAround_MaxDist                : Single =     7.36316233873368; // c

// Note: it is interesting to see different GA strategy for pathfinding
// of first road to new house and pathfinding of shortcuts
//{ 2019-11-24
  GA_PATHFINDING_BasePrice                           : Word =   53;
  GA_PATHFINDING_TurnPenalization                    : Word =   31;
  GA_PATHFINDING_Road                                : Word =   41;
  GA_PATHFINDING_noBuildArea                         : Word =   22;
  GA_PATHFINDING_Field                               : Word =   18;
  GA_PATHFINDING_Coal                                : Word =   27;
  GA_PATHFINDING_Forest                              : Word =   61;
  GA_PATHFINDING_OtherCase                           : Word =   40;

  GA_SHORTCUTS_BasePrice                             : Word =   77;
  GA_SHORTCUTS_TurnPenalization                      : Word =   49;
  GA_SHORTCUTS_Road                                  : Word =   29;
  GA_SHORTCUTS_noBuildArea                           : Word =   25;
  GA_SHORTCUTS_Field                                 : Word =   48;
  GA_SHORTCUTS_Coal                                  : Word =   46;
  GA_SHORTCUTS_Forest                                : Word =   45;
  GA_SHORTCUTS_OtherCase                             : Word =   41;
//}
{ 2019-11-23
  GA_PATHFINDING_BasePrice                           : Word =   68;
  GA_PATHFINDING_TurnPenalization                    : Word =   20;
  GA_PATHFINDING_Road                                : Word =   29;
  GA_PATHFINDING_noBuildArea                         : Word =   10;
  GA_PATHFINDING_Field                               : Word =   48;
  GA_PATHFINDING_Coal                                : Word =   10;
  GA_PATHFINDING_Forest                              : Word =   65;
  GA_PATHFINDING_OtherCase                           : Word =   50;

  GA_SHORTCUTS_BasePrice                             : Word =   75;
  GA_SHORTCUTS_TurnPenalization                      : Word =   20;
  GA_SHORTCUTS_Road                                  : Word =   45;
  GA_SHORTCUTS_noBuildArea                           : Word =   17;
  GA_SHORTCUTS_Field                                 : Word =   32;
  GA_SHORTCUTS_Coal                                  : Word =   13;
  GA_SHORTCUTS_Forest                                : Word =   13;
  GA_SHORTCUTS_OtherCase                             : Word =   26;
//}


{ KM_CityPredictor }
//{ 2019-11-20
  GA_PREDICTOR_WareNeedPerAWorker_Stone              : Single = 0.7038065791;
  GA_PREDICTOR_WareNeedPerAWorker_Wood               : Single = 0.2908146679;
//}


{ KM_Eye }
//{
  GA_EYE_GetForests_MaxAB          : Single = 155.750323295593; // <0.201> Ignore trees in existing forest <0.255-AVOID_BUILDING_FOREST_MINIMUM)
  GA_EYE_GetForests_Radius         : Single =   8.670244455338; // Forest radius
  GA_EYE_GetForests_MinTrees       : Single =   3.150522664189; // Min trees in forest
  GA_EYE_GetForests_SPRndOwnLimMin : Single =  99.770336151123; // Minimum influence of potential forest
  GA_EYE_GetForests_SPRndOwnLimMax : Single = 201.641844511032; // Maximum influence of potential forest
  GA_EYE_GetForests_MinRndSoil     : Single =  81.396015167236; // 0-82
//}


{  KM_NavMeshPathFinding }
//{ 2019-12-14
  GA_PATHFINDING_AvoidTraffic                        : Single =     2.4100508690;
  GA_PATHFINDING_AvoidSpecEnemy                      : Single =     0.9644539356;
//}

{ 2019-12-13
  GA_PATHFINDING_AvoidTraffic      : Single =  1.5; // 1 tile is max 10 points, max value of ArmyTraffic is 20, this coefficient must increase the price
  GA_PATHFINDING_AvoidSpecEnemy    : Single =  1;
//}


{ KM_Supervisor }


implementation

end.
