unit KM_ScriptingStates;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, SysUtils, StrUtils,
  KM_CommonTypes, KM_Defaults, KM_Points, KM_HandsCollection, KM_Houses, KM_ScriptingIdCache, KM_Units, KM_MapTypes,
  KM_UnitGroup, KM_ResHouses, KM_HouseCollection, KM_HouseWoodcutters,
  KM_ResWares, KM_ScriptingEvents, KM_TerrainTypes, KM_ResTilesetTypes,
  KM_UnitGroupTypes, KM_ScriptingTypes,
  KM_ResTypes, KM_HandTypes, KM_AITypes;


type
  TKMScriptStates = class(TKMScriptEntity)
  private
    procedure _AIGroupsFormationGet(aHand: Integer; aGroupType: TKMGroupType; out aCount, aColumns: Integer; out aSucceed: Boolean);
    function _ClosestGroup(aHand, X, Y: Integer; aGroupType: TKMGroupType; out aSucceed: Boolean): Integer;
    function _ClosestGroupMultipleTypes(aHand, X, Y: Integer; aGroupTypes: TKMGroupTypeSet; out aSucceed: Boolean): Integer;
    function _ClosestHouse(aHand, X, Y: Integer; aHouseType: TKMHouseType; out aSucceed: Boolean): Integer;
    function _ClosestHouseMultipleTypes(aHand, X, Y: Integer; aHouseTypes: TKMHouseTypeSet; out aSucceed: Boolean): Integer;
    function _ClosestUnit(aHand, X, Y: Integer; aUnitType: TKMUnitType; out aSucceed: Boolean): Integer;
    function _ClosestUnitMultipleTypes(aHand, X, Y: Integer; aUnitTypes: TKMUnitTypeSet; out aSucceed: Boolean): Integer;
  public
    function AAIAttackHouseTypesGet(aHand: Byte): TKMHouseTypeSet;
    function AIArmyType(aHand: Byte): TKMArmyType;
    function AIAutoAttack(aHand: Byte): Boolean;
    function AIAutoAttackRange(aHand: Byte): Integer;
    function AIAutoBuild(aHand: Byte): Boolean;
    function AIAutoDefence(aHand: Byte): Boolean;
    function AIAutoRepair(aHand: Byte): Boolean;
    function AIDefendAllies(aHand: Byte): Boolean;
    procedure AIDefencePositionGet(aHand, aID: Byte; out aX, aY: Integer; out aGroupType: Byte; out aRadius: Integer; out aDefType: Byte);
    function AIDefencePositionGetByIndex(aHand, aIndex: Integer): TKMDefencePositionInfo;
    function AIEquipRate(aHand: Byte; aType: Byte): Integer;
    procedure AIGroupsFormationGet(aHand, aType: Byte; out aCount, aColumns: Integer);
    procedure AIGroupsFormationGetEx(aHand: Integer; aGroupType: TKMGroupType; out aCount, aColumns: Integer);
    function AIRecruitDelay(aHand: Byte): Integer;
    function AIRecruitLimit(aHand: Byte): Integer;
    function AIRepairMode(aHand: Integer): TKMAIRepairMode;
    function AISerfsPerHouse(aHand: Byte): Single;
    function AISoldiersLimit(aHand: Byte): Integer;
    function AIStartPosition(aHand: Byte): TKMPoint;
    function AIUnlimitedEquip(aHand: Byte): Boolean;
    function AIWorkerLimit(aHand: Byte): Integer;

    function CampaignMissionID: Integer;
    function CampaignMissionsCount: Integer;

    function ClosestGroup(aHand, X, Y, aGroupType: Integer): Integer;
    function ClosestGroupEx(aHand, X, Y: Integer; aGroupType: TKMGroupType): Integer;
    function ClosestGroupMultipleTypes(aHand, X, Y: Integer; aGroupTypes: TByteSet): Integer;
    function ClosestGroupMultipleTypesEx(aHand, X, Y: Integer; aGroupTypes: TKMGroupTypeSet): Integer;
    function ClosestHouse(aHand, X, Y, aHouseType: Integer): Integer;
    function ClosestHouseEx(aHand, X, Y: Integer; aHouseType: TKMHouseType): Integer;
    function ClosestHouseMultipleTypes(aHand, X, Y: Integer; aHouseTypes: TByteSet): Integer;
    function ClosestHouseMultipleTypesEx(aHand, X, Y: Integer; aHouseTypes: TKMHouseTypeSet): Integer;
    function ClosestUnit(aHand, X, Y, aUnitType: Integer): Integer;
    function ClosestUnitEx(aHand, X, Y: Integer; aUnitType: TKMUnitType): Integer;
    function ClosestUnitMultipleTypes(aHand, X, Y: Integer; aUnitTypes: TByteSet): Integer;
    function ClosestUnitMultipleTypesEx(aHand, X, Y: Integer; aUnitTypes: TKMUnitTypeSet): Integer;

    function ConnectedByRoad(X1, Y1, X2, Y2: Integer): Boolean;
    function ConnectedByWalking(X1, Y1, X2, Y2: Integer): Boolean;

    function FogRevealed(aHand: Byte; aX, aY: Integer): Boolean;

    function GameSpeed: Single;
    function GameSpeedChangeAllowed: Boolean;
    function GameTime: Cardinal;

    function GroupAllowAllyToSelect(aGroupID: Integer): Boolean;
    function GroupAssignedToDefencePosition(aGroupID, X, Y: Integer): Boolean;
    function GroupAt(aX, aY: Integer): Integer;
    function GroupColumnCount(aGroupID: Integer): Integer;
    function GroupDead(aGroupID: Integer): Boolean;
    function GroupIdle(aGroupID: Integer): Boolean;
    function GroupInFight(aGroupID: Integer; aCountCitizens: Boolean): Boolean;
    function GroupManualFormation(aGroupID: Integer): Boolean;
    function GroupMember(aGroupID, aMemberIndex: Integer): Integer;
    function GroupMemberCount(aGroupID: Integer): Integer;
    function GroupOrder(aGroupID: Integer): TKMGroupOrder;
    function GroupOwner(aGroupID: Integer): Integer;
    function GroupType(aGroupID: Integer): Integer;
    function GroupTypeEx(aGroupID: Integer): TKMGroupType;

    function HouseAllowAllyToSelect(aHouseID: Integer): Boolean;
    function HouseAt(aX, aY: Integer): Integer;
    function HouseBarracksRallyPointX(aBarracks: Integer): Integer;
    function HouseBarracksRallyPointY(aBarracks: Integer): Integer;
    function HouseBarracksRecruitsCount(aBarracks: Integer): Integer;
    function HouseBarracksRecruitBlock(aHouseID: Integer): Boolean;
    function HouseBuildingProgress(aHouseID: Integer): Integer;
    function HouseCanReachResources(aHouseID: Integer): Boolean;
    function HouseDamage(aHouseID: Integer): Integer;
    function HouseDeliveryBlocked(aHouseID: Integer): Boolean;
    function HouseDeliveryMode(aHouseID: Integer): TKMDeliveryMode;
    function HouseDestroyed(aHouseID: Integer): Boolean;
    function HouseFlagPoint(aHouseID: Integer): TKMPoint;
    function HouseGetAllUnitsIn(aHouseID: Integer): TIntegerArray;
    function HouseHasOccupant(aHouseID: Integer): Boolean;
    function HouseHasWorker(aHouseID: Integer): Boolean;
    function HouseIsComplete(aHouseID: Integer): Boolean;
    function HouseIsClosedForWorker(aHouseID: Integer): Boolean;
    function HouseOwner(aHouseID: Integer): Integer;
    function HousePosition(aHouseID: Integer): TKMPoint;
    function HousePositionX(aHouseID: Integer): Integer;
    function HousePositionY(aHouseID: Integer): Integer;
    function HouseRepair(aHouseID: Integer): Boolean;
    function HouseResourceAmount(aHouseID, aResource: Integer): Integer;
    function HouseSchoolQueue(aHouseID, QueueIndex: Integer): Integer;
    function HouseSiteIsDigged(aHouseID: Integer): Boolean;
    function HouseTownHallMaxGold(aHouseID: Integer): Integer;
    function HouseType(aHouseID: Integer): Integer;
    function HouseTypeEx(aHouseID: Integer): TKMHouseType;
    function HouseTypeMaxHealth(aHouseType: Integer): Integer;
    function HouseTypeMaxHealthEx(aHouseType: TKMHouseType): Integer;
    function HouseTypeName(aHouseType: Byte): AnsiString;
    function HouseTypeNameEx(aHouseType: TKMHouseType): AnsiString;
    function HouseTypeToOccupantType(aHouseType: Integer): Integer;
    function HouseTypeToWorkerType(aHouseType: TKMHouseType): TKMUnitType;
    function HouseUnlocked(aHand, aHouseType: Integer): Boolean;
    function HouseWareAmount(aHouseID: Integer; aWare: TKMWareType): Integer;
    function HouseWareBlocked(aHouseID, aWareType: Integer): Boolean;
    function HouseWareBlockedEx(aHouseID: Integer; aWareType: TKMWareType): Boolean;
    function HouseWareBlockedTakeOut(aHouseID: Integer; aWareType: TKMWareType): Boolean;
    function HouseWeaponsOrdered(aHouseID, aWareType: Integer): Integer;
    function HouseWeaponsOrderedEx(aHouseID: Integer; aWareType: TKMWareType): Integer;
    function HouseWoodcutterChopOnly(aHouseID: Integer): Boolean;
    function HouseWoodcutterMode(aHouseID: Integer): TKMWoodcutterMode;
    function HouseWorker(aHouseID: Integer): Integer;

    function IsFieldAt(aHand: ShortInt; X, Y: Integer): Boolean;
    function IsWinefieldAt(aHand: ShortInt; X, Y: Integer): Boolean;
    function IsRoadAt(aHand: ShortInt; X, Y: Integer): Boolean;

    function IsPlanAt(var aHand: Integer; var aFieldType: TKMFieldType; X, Y: Integer): Boolean;
    function IsFieldPlanAt(var aHand: Integer; X, Y: Integer): Boolean;
    function IsHousePlanAt(var aHand: Integer; var aHouseType: TKMHouseType; X, Y: Integer): Boolean;
    function IsRoadPlanAt(var aHand: Integer; X, Y: Integer): Boolean;
    function IsWinefieldPlanAt(var aHand: Integer; X, Y: Integer): Boolean;

    function IsMissionBuildType: Boolean;
    function IsMissionFightType: Boolean;
    function IsMissionCoopType: Boolean;
    function IsMissionSpecialType: Boolean;
    function IsMissionPlayableAsSP: Boolean;
    function IsMissionBlockColorSelection: Boolean;
    function IsMissionBlockTeamSelection: Boolean;
    function IsMissionBlockPeacetime: Boolean;
    function IsMissionBlockFullMapPreview: Boolean;

    function KaMRandom: Single;
    function KaMRandomI(aMax: Integer): Integer;
    function LocationCount: Integer;

    function MapTileHasOnlyTerrainKind(X, Y: Integer; TerKind: TKMTerrainKind): Boolean;
    function MapTileHasOnlyTerrainKinds(X, Y: Integer; TerKinds: array of TKMTerrainKind): Boolean;
    function MapTileHasTerrainKind(X, Y: Integer; TerKind: TKMTerrainKind): Boolean;
    function MapTileIsCoal(X, Y: Integer): Integer;
    function MapTileIsGold(X, Y: Integer): Integer;
    function MapTileIsIce(X, Y: Integer): Boolean;
    function MapTileIsInMapCoords(X, Y: Integer): Boolean;
    function MapTileIsIron(X, Y: Integer): Integer;
    function MapTileIsSand(X, Y: Integer): Boolean;
    function MapTileIsSnow(X, Y: Integer): Boolean;
    function MapTileIsSoil(X, Y: Integer): Boolean;
    function MapTileIsStone(X, Y: Integer): Integer;
    function MapTileIsWater(X, Y: Integer; FullTilesOnly: Boolean): Boolean;

    function MapTileType(X, Y: Integer): Integer;
    function MapTileRotation(X, Y: Integer): Integer;
    function MapTileHeight(X, Y: Integer): Integer;
    function MapTileObject(X, Y: Integer): Integer;
    function MapTileOverlay(X, Y: Integer): TKMTileOverlay;
    function MapTileOwner(X, Y: Integer): Integer;
    function MapTilePassability(X, Y: Integer; aPassability: Byte): Boolean;
    function MapTilePassabilityEx(X, Y: Integer; aPassability: TKMTerrainPassability): Boolean;
    function MapWidth: Integer;
    function MapHeight: Integer;

    function MissionAuthor: UnicodeString;

    function MissionDifficulty: TKMMissionDifficulty;
    function MissionDifficultyLevels: TKMMissionDifficultySet;

    function MissionVersion: UnicodeString;

    function MarketFromWare(aMarketID: Integer): Integer;
    function MarketFromWareEx(aMarketID: Integer): TKMWareType;
    function MarketLossFactor: Single;
    function MarketOrderAmount(aMarketID: Integer): Integer;
    function MarketToWare(aMarketID: Integer): Integer;
    function MarketToWareEx(aMarketID: Integer): TKMWareType;
    function MarketValue(aRes: Integer): Single;
    function MarketValueEx(aWareType: TKMWareType): Single;
    function PeaceTime: Cardinal;

    function PlayerAllianceCheck(aHand1, aHand2: Byte): Boolean;
    function PlayerColorFlag(aHand: Byte): AnsiString;
    function PlayerColorText(aHand: Byte): AnsiString;
    function PlayerDefeated(aHand: Byte): Boolean;
    function PlayerEnabled(aHand: Byte): Boolean;
    function PlayerHouseTypeCanBuild(aHand: Integer; aHouseType: TKMHouseType): Boolean;
    function PlayerHouseTypeLock(aHand: Integer; aHouseType: TKMHouseType): TKMHandHouseLock;
    function PlayerGetAllUnits(aHand: Byte): TIntegerArray;
    function PlayerGetAllHouses(aHand: Byte): TIntegerArray;
    function PlayerGetAllGroups(aHand: Byte): TIntegerArray;
    function PlayerIsAI(aHand: Byte): Boolean;
    function PlayerIsAdvancedAI(aHand: Byte): Boolean;
    function PlayerIsClassicAI(aHand: Byte): Boolean;
    function PlayerName(aHand: Byte): AnsiString;
    function PlayerUnitTypeCanTrain(aHand: Integer; aUnitType: TKMUnitType): Boolean;
    function PlayerVictorious(aHand: Byte): Boolean;
    function PlayerWareDistribution(aHand, aWareType, aHouseType: Byte): Byte;
    function PlayerWareDistributionEx(aHand: Integer; aWareType: TKMWareType; aHouseType: TKMHouseType): Integer;

    function StatAIDefencePositionsCount(aHand: Byte): Integer;
    function StatArmyCount(aHand: Byte): Integer;
    function StatArmyPower(aHand: Byte): Single;
    function StatCitizenCount(aHand: Byte): Integer;
    function StatHouseCount(aHand: Byte): Integer;
    function StatHouseMultipleTypesCount(aHand: Byte; aTypes: TByteSet): Integer;
    function StatHouseMultipleTypesCountEx(aHand: Integer; aTypes: TKMHouseTypeSet): Integer;
    function StatHouseTypeCount(aHand, aHouseType: Byte): Integer;
    function StatHouseTypeCountEx(aHand: Integer; aHouseType: TKMHouseType): Integer;
    function StatHouseTypePlansCount(aHand, aHouseType: Byte): Integer;
    function StatHouseTypePlansCountEx(aHand: Integer; aHouseType: TKMHouseType): Integer;
    function StatPlayerCount: Integer;
    function StatResourceProducedCount(aHand, aResType: Byte): Integer;
    function StatResourceProducedCountEx(aHand: Integer; aWareType: TKMWareType): Integer;
    function StatResourceProducedMultipleTypesCount(aHand: Byte; aTypes: TByteSet): Integer;
    function StatResourceProducedMultipleTypesCountEx(aHand: Integer; aTypes: TKMWareTypeSet): Integer;
    function StatUnitCount(aHand: Byte): Integer;
    function StatUnitKilledCount(aHand, aUnitType: Byte): Integer;
    function StatUnitKilledCountEx(aHand: Integer; aUnitType: TKMUnitType): Integer;
    function StatUnitKilledMultipleTypesCount(aHand: Byte; aTypes: TByteSet): Integer;
    function StatUnitKilledMultipleTypesCountEx(aHand: Integer; aTypes: TKMUnitTypeSet): Integer;
    function StatUnitLostCount(aHand, aUnitType: Byte): Integer;
    function StatUnitLostCountEx(aHand: Integer; aUnitType: TKMUnitType): Integer;
    function StatUnitLostMultipleTypesCount(aHand: Byte; aTypes: TByteSet): Integer;
    function StatUnitLostMultipleTypesCountEx(aHand: Byte; aTypes: TKMUnitTypeSet): Integer;
    function StatUnitMultipleTypesCount(aHand: Byte; aTypes: TByteSet): Integer;
    function StatUnitMultipleTypesCountEx(aHand: Integer; aTypes: TKMUnitTypeSet): Integer;
    function StatUnitTypeCount(aHand, aUnitType: Byte): Integer;
    function StatUnitTypeCountEx(aHand: Integer; aUnitType: TKMUnitType): Integer;

    function UnitAllowAllyToSelect(aUnitID: Integer): Boolean;
    function UnitAt(aX, aY: Integer): Integer;
    function UnitCarrying(aUnitID: Integer): Integer;
    function UnitCarryingEx(aUnitID: Integer): TKMWareType;
    function UnitDead(aUnitID: Integer): Boolean;
    function UnitDirection(aUnitID: Integer): Integer;
    function UnitDirectionEx(aUnitID: Integer): TKMDirection;
    function UnitDismissable(aUnitID: Integer): Boolean;
    function UnitFishCount(aUnitID: Integer): Integer;
    function UnitHome(aUnitID: Integer): Integer;
    function UnitHPCurrent(aUnitID: Integer): Integer;
    function UnitHPMax(aUnitID: Integer): Integer;
    function UnitHPInvulnerable(aUnitID: Integer): Boolean;
    function UnitHunger(aUnitID: Integer): Integer;
    function UnitIdle(aUnitID: Integer): Boolean;
    function UnitInHouse(aUnitID: Integer): Integer;
    function UnitLowHunger: Integer;
    function UnitMaxHunger: Integer;
    function UnitOwner(aUnitID: Integer): Integer;
    function UnitPosition(aUnitID: Integer): TKMPoint;
    function UnitPositionX(aUnitID: Integer): Integer;
    function UnitPositionY(aUnitID: Integer): Integer;
    function UnitsGroup(aUnitID: Integer): Integer;
    function UnitType(aUnitID: Integer): Integer;
    function UnitTypeEx(aUnitID: Integer): TKMUnitType;
    function UnitTypeName(aUnitType: Byte): AnsiString;
    function UnitTypeNameEx(aUnitType: TKMUnitType): AnsiString;

    function WareTypeName(aWareType: Byte): AnsiString;
    function WareTypeNameEx(aWareType: TKMWareType): AnsiString;
    function WarriorInFight(aUnitID: Integer; aCountCitizens: Boolean): Boolean;
  end;


implementation
uses
  TypInfo,
  KM_Entity,
  KM_AI, KM_ArmyDefence, KM_AIDefensePos,
  KM_Game, KM_GameApp, KM_GameParams,
  KM_UnitsCollection, KM_UnitWarrior, KM_UnitTaskSelfTrain,
  KM_HouseBarracks, KM_HouseSchool, KM_HouseMarket, KM_HouseStore, KM_HouseTownHall,
  KM_Resource, KM_ResUnits,
  KM_Hand, KM_HandEntity,
  KM_Terrain,
  KM_CommonUtils;


  //We need to check all input parameters as could be wildly off range due to
  //mistakes in scripts. In that case we have two options:
  // - skip silently and log
  // - report to player


function HouseTypeValid(aHouseType: Integer): Boolean; inline;
begin
  Result := (aHouseType in [Low(HOUSE_ID_TO_TYPE)..High(HOUSE_ID_TO_TYPE)])
            and (HOUSE_ID_TO_TYPE[aHouseType] <> htNone); //KaM index 26 is unused (htNone)
end;


{ TKMScriptStates }


//* Version: 14600
//* Gets set of house types, houses of which Advanced AI should attack
//* aHand: HandID
//* Returns empty set if wrong handId was passed
function TKMScriptStates.AAIAttackHouseTypesGet(aHand: Byte): TKMHouseTypeSet;
begin
  try
    Result := [];
    if InRange(aHand, 0, gHands.Count - 1)
      and gHands[aHand].Enabled
      and gHands[aHand].AI.Setup.NewAI then
      Result := gHands[aHand].AI.ArmyManagement.ArmyVectorFieldScanHouses
    else
      LogIntParamWarn('States.AAIAttackHouseTypesGet', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Gets AI army type
function TKMScriptStates.AIArmyType(aHand: Byte): TKMArmyType;
begin
  try
    Result := atIronThenLeather; //Make compiler happy
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := gHands[aHand].AI.Setup.ArmyType
    else
      LogIntParamWarn('States.AIArmyType', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;



//* Version: 13000
//* Gets AI AutoAttack (True or False)
function TKMScriptStates.AIAutoAttack(aHand: Byte): Boolean;
begin
  Result := False;
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := gHands[aHand].AI.Setup.AutoAttack
    else
      LogIntParamWarn('States.AIAutoAttack', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Gets AI auto attack range.
//* Returns -1 if used with wrong parameters
function TKMScriptStates.AIAutoAttackRange(aHand: Byte): Integer;
begin
  Result := -1;
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := gHands[aHand].AI.Setup.AutoAttackRange
    else
      LogIntParamWarn('States.AIAutoAttackRange', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Gets whether the AI should build and manage his own village
//* Returns False if used with wrong parameters
function TKMScriptStates.AIAutoBuild(aHand: Byte): Boolean;
begin
  Result := False;
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := gHands[aHand].AI.Setup.AutoBuild
    else
      LogIntParamWarn('States.AIAutoBuild', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Gets whether the AI should position his soldiers automatically
//* Returns False if used with wrong parameters
function TKMScriptStates.AIAutoDefence(aHand: Byte): Boolean;
begin
  Result := False;
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := gHands[aHand].AI.Setup.AutoDefend
    else
      LogIntParamWarn('States.AIAutoDefence', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Gets whether the AI should automatically repair damaged buildings
//* Returns False if used with wrong parameters
function TKMScriptStates.AIAutoRepair(aHand: Byte): Boolean;
begin
  Result := False;
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := gHands[aHand].AI.Setup.IsRepairAlways
    else
      LogIntParamWarn('States.AIAutoRepair', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Gets whether AI should defend units and houses of allies as if they were its own
//* Returns False if used with wrong parameters
function TKMScriptStates.AIDefendAllies(aHand: Byte): Boolean;
begin
  Result := False;
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := gHands[aHand].AI.Setup.DefendAllies
    else
      LogIntParamWarn('States.AIDefendAllies', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 12000+
//* Gets the parameters of AI defence position
//* Parameters are returned in aX, aY, aGroupType, aRadius, aDefType variables
//* Group types: 0 = Melee; 1	= Anti-horse; 2	= Ranged; 3	= Mounted
//* Defence type: 0 = Defenders; 1 = Attackers
procedure TKMScriptStates.AIDefencePositionGet(aHand, aID: Byte; out aX, aY: Integer; out aGroupType: Byte; out aRadius: Integer; out aDefType: Byte);
var
  DP: TAIDefencePosition;
begin
  //todo -cPractical: Should return all zeroes in case of bad arguments
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled
    and InRange(aID, 0, gHands[aHand].AI.General.DefencePositions.Count - 1) then
    begin
      DP := gHands[aHand].AI.General.DefencePositions[aID];
      if DP <> nil then
      begin
        aX := DP.Position.Loc.X;
        aY := DP.Position.Loc.Y;
        aGroupType := Ord(DP.GroupType) - GROUP_TYPE_MIN_OFF;
        aRadius := DP.Radius;
        aDefType := Ord(DP.DefenceType);
      end;
    end
    else
      LogIntParamWarn('States.AIDefencePositionGet', [aHand, aID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Gets the parameters of AI defence position
//* aIndex: index in the list of all defence positions for the specified player
//* Returns defence position parameters
function TKMScriptStates.AIDefencePositionGetByIndex(aHand, aIndex: Integer): TKMDefencePositionInfo;
var
  DP: TAIDefencePosition;
begin
  //todo -cPractical: Should return default(TKMDefencePositionInfo) in case of bad arguments
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled
    and InRange(aIndex, 0, gHands[aHand].AI.General.DefencePositions.Count - 1) then
    begin
      DP := gHands[aHand].AI.General.DefencePositions[aIndex];
      if DP <> nil then
      begin
        Result.UID := DP.UID;
        Result.X := DP.Position.Loc.X;
        Result.Y := DP.Position.Loc.Y;
        if DP.CurrentGroup = nil then
          Result.GroupID := -1
        else
          Result.GroupID := DP.CurrentGroup.UID;
        Result.Radius := DP.Radius;
        Result.Dir := DP.Position.Dir;
        Result.GroupType := DP.GroupType;
        Result.PositionType := DP.DefenceType;
      end;
    end
    else
      LogIntParamWarn('States.AIDefencePositionGetByIndex', [aHand, aIndex]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Gets the warriors equip rate for AI.
//* aType: type: 0 - leather, 1 - iron
//* Returns -1 if used with wrong parameters
function TKMScriptStates.AIEquipRate(aHand: Byte; aType: Byte): Integer;
begin
  Result := -1;
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
    begin
      case aType of
        0:    Result := gHands[aHand].AI.Setup.EquipRateLeather;
        1:    Result := gHands[aHand].AI.Setup.EquipRateIron;
        else  LogIntParamWarn('States.AIEquipRate, unknown type', [aHand, aType]);
      end;
    end else
      LogIntParamWarn('States.AIEquipRate', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


procedure TKMScriptStates._AIGroupsFormationGet(aHand: Integer; aGroupType: TKMGroupType; out aCount, aColumns: Integer; out aSucceed: Boolean);
begin
  aSucceed := False;
  if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled
    and (aGroupType in GROUP_TYPES_VALID) then
  begin
    if gHands[aHand].AI.Setup.NewAI then
    begin
      aCount := gHands[aHand].AI.ArmyManagement.Defence.TroopFormations[aGroupType].NumUnits;
      aColumns := gHands[aHand].AI.ArmyManagement.Defence.TroopFormations[aGroupType].UnitsPerRow;
    end
    else
    begin
      aCount := gHands[aHand].AI.General.DefencePositions.TroopFormations[aGroupType].NumUnits;
      aColumns := gHands[aHand].AI.General.DefencePositions.TroopFormations[aGroupType].UnitsPerRow;
    end;
    aSucceed := True;
  end;
end;


//* Version: 7000+
//* Gets the formation the AI uses for defence positions for specified player and group type
//* GroupType: 0 = Melee, 1 = AntiHorse, 2 = Ranged, 3 = Mounted
//* group count and columns are returned in aCount and aColumns variables
procedure TKMScriptStates.AIGroupsFormationGet(aHand, aType: Byte; out aCount, aColumns: Integer);
var
  gt: TKMGroupType;
  succeed: Boolean;
begin
  //todo -cPractical: LogIntParamWarn is good, but the func should return all zeroes in case of bad arguments anyway
  try
    gt := gtNone;

    if InRange(aType, 0, 3) then
      gt := TKMGroupType(aType + GROUP_TYPE_MIN_OFF);

    _AIGroupsFormationGet(aHand, gt, aCount, aColumns, succeed);
    if not succeed then
      LogIntParamWarn('States.AIGroupsFormationGet', [aHand, aType]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Gets the formation the AI uses for defence positions for specified player and group type
//* group count and columns are returned in aCount and aColumns variables
procedure TKMScriptStates.AIGroupsFormationGetEx(aHand: Integer; aGroupType: TKMGroupType; out aCount, aColumns: Integer);
var
  succeed: Boolean;
begin
  //todo -cPractical: LogParamWarn is good, but the func should return all zeroes in case of bad arguments anyway
  try
    _AIGroupsFormationGet(aHand, aGroupType, aCount, aColumns, succeed);
    if not succeed then
      LogParamWarn('States.AIGroupsFormationGetEx', [aHand, GetEnumName(TypeInfo(TKMGroupType), Integer(aGroupType))]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Gets the number of ticks before the specified AI will start training recruits
//* Returns -1 if used with wrong parameters
function TKMScriptStates.AIRecruitDelay(aHand: Byte): Integer;
begin
  Result := -1;
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := gHands[aHand].AI.Setup.RecruitDelay
    else
      LogIntParamWarn('States.AIRecruitDelay', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Gets the number of recruits the AI will keep in each barracks
//* Returns -1 if used with wrong parameters
function TKMScriptStates.AIRecruitLimit(aHand: Byte): Integer;
begin
  Result := -1;
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := gHands[aHand].AI.Setup.RecruitCount
    else
      LogIntParamWarn('States.AIRecruitLimit', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Gets whether the AI should automatically repair damaged buildings
//* Returns rmNone if used with wrong parameters
//* rmNever if disable repair for all houses
//* rmAlways if enable repair for all houses
//* rmManual if repair is set by script manually via Actions.HouseRepairEnable
function TKMScriptStates.AIRepairMode(aHand: Integer): TKMAIRepairMode;
begin
  Result := rmNone;
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := gHands[aHand].AI.Setup.RepairMode
    else
      LogIntParamWarn('States.AIRepairMode', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Gets the number of serfs the AI will train per house.
//* Can be a decimal (0.25 for 1 serf per 4 houses)
//* Returns -1 if used with wrong parameters
function TKMScriptStates.AISerfsPerHouse(aHand: Byte): Single;
begin
  Result := -1;
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := gHands[aHand].AI.Setup.SerfsPerHouse
    else
      LogIntParamWarn('States.AISerfsPerHouse', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Gets the maximum number of soldiers the AI will train, or -1 for unlimited
//* Returns -2 if used with wrong parameters
function TKMScriptStates.AISoldiersLimit(aHand: Byte): Integer;
begin
  Result := -2; // use -2 here, as -1 is used for unlimited
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := gHands[aHand].AI.Setup.MaxSoldiers
    else
      LogIntParamWarn('States.AISoldiersLimit', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Gets the AI start position which is used for targeting AI attacks
//* Returns (-1;-1) if used with wrong parameters
function TKMScriptStates.AIStartPosition(aHand: Byte): TKMPoint;
begin
  Result := KMPOINT_INVALID_TILE;
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := gHands[aHand].AI.Setup.StartPosition
    else
      LogIntParamWarn('States.AIStartPosition', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14800
//* Gets AI unlimited equip parameter or False if aHand parameter is not valid
function TKMScriptStates.AIUnlimitedEquip(aHand: Byte): Boolean;
begin
  Result := False;
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := gHands[aHand].AI.Setup.UnlimitedEquip
    else
      LogIntParamWarn('States.AIUnlimitedEquip', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Gets the maximum number of laborers the AI will train
//* Returns -1 if used with wrong parameters
function TKMScriptStates.AIWorkerLimit(aHand: Byte): Integer;
begin
  Result := -1;
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := gHands[aHand].AI.Setup.WorkerCount
    else
      LogIntParamWarn('States.AIWorkerLimit', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 12600
//* Returns current campaing mission number or -1 if this is not a campaign mission
//* First mission got ID = 1
function TKMScriptStates.CampaignMissionID: Integer;
begin
  Result := -1;
  try
    if not gGame.Params.IsCampaign then
    begin
      LogWarning('States.CampaignMissionID', 'Current mission is not part of a campaign');
      Exit;
    end;

    Result := gGame.CampaignMap + 1; // CampaignMap starts from 0
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 12600
//* Returns current campaign missions count or -1 if this is not a campaign mission
function TKMScriptStates.CampaignMissionsCount: Integer;
begin
  Result := -1;
  try
    if not gGame.Params.IsCampaign or (gGameApp.Campaigns.ActiveCampaign = nil) then
    begin
      LogWarning('States.CampaignMissionsCount', 'Current mission is not part of a campaign');
      Exit;
    end;

    Result := gGameApp.Campaigns.ActiveCampaign.Spec.MissionsCount;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


function TKMScriptStates._ClosestGroup(aHand, X, Y: Integer; aGroupType: TKMGroupType; out aSucceed: Boolean): Integer;
var
  G: TKMUnitGroup;
  GTS: TKMGroupTypeSet;
begin
  Result := -1;
  aSucceed := False;
  if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled
    and gTerrain.TileInMapCoords(X, Y)
    and ((aGroupType = gtAny) or (aGroupType in GROUP_TYPES_VALID)) then
  begin
    if aGroupType = gtAny then
      GTS := GROUP_TYPES_VALID
    else
      GTS := [aGroupType];

    G := gHands[aHand].UnitGroups.GetClosestGroup(KMPoint(X,Y), GTS);
    if (G <> nil) and not G.IsDead then
    begin
      Result := G.UID;
      fIDCache.CacheGroup(G, G.UID);
    end;
    aSucceed := True;
  end;

end;


//* Version: 6216
//* Returns the group of the specified player and group type that is closest to the specified coordinates,
//* or -1 if no such group was found.
//* If the group type is -1 any group type will be accepted
//* Result: Group ID
function TKMScriptStates.ClosestGroup(aHand, X, Y, aGroupType: Integer): Integer;
var
  gt: TKMGroupType;
  succeed: Boolean;
begin
  try
    gt := gtNone;

    if aGroupType = -1 then
      gt := gtAny
    else
    if InRange(aGroupType, 0, 3) then
      gt := TKMGroupType(aGroupType + GROUP_TYPE_MIN_OFF);

    Result := _ClosestGroup(aHand, X, Y, gt, succeed);
    if not succeed then
      LogIntParamWarn('States.ClosestGroup', [aHand, X, Y, aGroupType]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns the group of the specified player and group type that is closest to the specified coordinates,
//* or -1 if no such group was found.
//* Result: Group ID
function TKMScriptStates.ClosestGroupEx(aHand, X, Y: Integer; aGroupType: TKMGroupType): Integer;
var
  succeed: Boolean;
begin
  try
    Result := _ClosestGroup(aHand, X, Y, aGroupType, succeed);
    if not succeed then
      LogParamWarn('States.ClosestGroupEx', [aHand, X, Y, GetEnumName(TypeInfo(TKMGroupType), Integer(aGroupType))]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


function TKMScriptStates._ClosestGroupMultipleTypes(aHand, X, Y: Integer; aGroupTypes: TKMGroupTypeSet; out aSucceed: Boolean): Integer;
var
  G: TKMUnitGroup;
begin
  Result := -1;
  aSucceed := False;
  if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled
    and gTerrain.TileInMapCoords(X, Y) then
  begin
    aGroupTypes := aGroupTypes * GROUP_TYPES_VALID;
    G := gHands[aHand].UnitGroups.GetClosestGroup(KMPoint(X,Y), aGroupTypes);
    if G <> nil then
    begin
      Result := G.UID;
      fIDCache.CacheGroup(G, G.UID);
    end;
    aSucceed := True;
  end;
end;


//* Version: 6216
//* Returns the group of the specified player and group types that is closest to the specified coordinates,
//* or -1 if no such group was found.
//* The group types is a "set of Byte", for example [1,3]
//* aGroupTypes: Set of group types
//* Result: Group ID
function TKMScriptStates.ClosestGroupMultipleTypes(aHand, X, Y: Integer; aGroupTypes: TByteSet): Integer;
var
  B: Byte;
  GTS: TKMGroupTypeSet;
  succeed: Boolean;
  strSet: string;
begin
  try
    GTS := [];
    for B in [Byte(GROUP_TYPE_MIN)..Byte(GROUP_TYPE_MAX)] do
      if B - GROUP_TYPE_MIN_OFF in aGroupTypes then
        GTS := GTS + [TKMGroupType(B)];

    Result := _ClosestGroupMultipleTypes(aHand, X, Y, GTS, succeed);

    if not succeed then
    begin
      // Collect group types to string
      strSet := '';
      for B in aGroupTypes do
        strSet := strSet + IfThen(strSet <> '', ', ') + IntToStr(B);
      strSet := '[' + strSet + ']';

      LogParamWarn('States.ClosestGroupMultipleTypes', [aHand, X, Y, strSet]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns the group of the specified player and group types that is closest to the specified coordinates,
//* or -1 if no such group was found.
//* The group types is a "set of Byte", for example [1,3]
//* aGroupTypes: Set of group types
//* Result: Group ID
function TKMScriptStates.ClosestGroupMultipleTypesEx(aHand, X, Y: Integer; aGroupTypes: TKMGroupTypeSet): Integer;
var
  succeed: Boolean;
  strSet: string;
  GT: TKMGroupType;
begin
  try
    Result := _ClosestGroupMultipleTypes(aHand, X, Y, aGroupTypes, succeed);

    if not succeed then
    begin
      // Collect group types to string
      strSet := '';
      for GT in aGroupTypes do
        strSet := strSet + IfThen(strSet <> '', ', ') + GetEnumName(TypeInfo(TKMGroupType), Integer(GT));
      strSet := '[' + strSet + ']';

      LogParamWarn('States.ClosestGroupMultipleTypesEx', [aHand, X, Y, strSet]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


function TKMScriptStates._ClosestHouse(aHand, X, Y: Integer; aHouseType: TKMHouseType; out aSucceed: Boolean): Integer;
var
  H: TKMHouse;
  HTS: TKMHouseTypeSet;
begin
  Result := -1;
  aSucceed := False;
  if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled
    and gTerrain.TileInMapCoords(X, Y)
    and (aHouseType <> htNone) then
  begin
    if aHouseType = htAny then
      HTS := HOUSES_VALID
    else
      HTS := [aHouseType];

    H := gHands[aHand].Houses.FindHouse(HTS, X, Y);
    if H <> nil then
    begin
      Result := H.UID;
      fIDCache.CacheHouse(H, H.UID);
    end;
    aSucceed := True;
  end;
end;


//* Version: 6216
//* Returns the house of the specified player and house type that is closest to the specified coordinates,
//* or -1 if no such house was found.
//* If the house type is -1 any house type will be accepted
//* Result: House ID
function TKMScriptStates.ClosestHouse(aHand, X, Y, aHouseType: Integer): Integer;
var
  HT: TKMHouseType;
  succeed: Boolean;
begin
  try
    HT := htNone;

    if aHouseType = -1 then
      HT := htAny
    else
    if HouseTypeValid(aHouseType) then
      HT := HOUSE_ID_TO_TYPE[aHouseType];

    Result := _ClosestHouse(aHand, X, Y, HT, succeed);
    if not succeed then
      LogIntParamWarn('States.ClosestHouse', [aHand, X, Y, aHouseType]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns the house of the specified player and house type that is closest to the specified coordinates,
//* or -1 if no such house was found.
//* If the house type is htAny any house type will be accepted
//* Result: House ID
function TKMScriptStates.ClosestHouseEx(aHand, X, Y: Integer; aHouseType: TKMHouseType): Integer;
var
  succeed: Boolean;
begin
  try
    Result := _ClosestHouse(aHand, X, Y, aHouseType, succeed);
    if not succeed then
      LogParamWarn('States.ClosestHouseEx', [aHand, X, Y, GetEnumName(TypeInfo(TKMHouseType), Integer(aHouseType))]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


function TKMScriptStates._ClosestHouseMultipleTypes(aHand, X, Y: Integer; aHouseTypes: TKMHouseTypeSet; out aSucceed: Boolean): Integer;
var
  H: TKMHouse;
begin
  Result := -1;
  aSucceed := False;
  if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled
    and gTerrain.TileInMapCoords(X, Y) then
  begin
    aHouseTypes := aHouseTypes * HOUSES_VALID;
    H := gHands[aHand].Houses.FindHouse(aHouseTypes, X, Y);
    if H <> nil then
    begin
      Result := H.UID;
      fIDCache.CacheHouse(H, H.UID);
    end;
    aSucceed := True;
  end;
end;


//* Version: 6216
//* Returns the house of the specified player and house types that is closest to the specified coordinates,
//* or -1 if no such house was found.
//* The house types is a "set of Byte", for example [11,13,21]
//* aHouseTypes: Set of house types
//* Result: House ID
function TKMScriptStates.ClosestHouseMultipleTypes(aHand, X, Y: Integer; aHouseTypes: TByteSet): Integer;
var
  B: Byte;
  HTS: TKMHouseTypeSet;
  strSet: string;
  succeed: Boolean;
begin
  try
    HTS := [];
    for B := Low(HOUSE_ID_TO_TYPE) to High(HOUSE_ID_TO_TYPE) do
      if (B in aHouseTypes) and (HOUSE_ID_TO_TYPE[B] <> htNone) then
        HTS := HTS + [HOUSE_ID_TO_TYPE[B]];

    Result := _ClosestHouseMultipleTypes(aHand, X, Y, HTS, succeed);
    if not succeed then
    begin
      // Collect house types to string
      strSet := '';
      for B in aHouseTypes do
        strSet := strSet + IfThen(strSet <> '', ', ') + IntToStr(B);
      strSet := '[' + strSet + ']';

      LogParamWarn('States.ClosestHouseMultipleTypes', [aHand, X, Y, strSet]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns the house of the specified player and house types that is closest to the specified coordinates,
//* or -1 if no such house was found.
//* The house types is a "set of TKMHouseType", for example [htQuary, htSchool, htStore]
//* aHouseTypes: Set of house types
//* Result: House ID
function TKMScriptStates.ClosestHouseMultipleTypesEx(aHand, X, Y: Integer; aHouseTypes: TKMHouseTypeSet): Integer;
var
  succeed: Boolean;
  HT: TKMHouseType;
  strSet: string;
begin
  try
    Result := _ClosestHouseMultipleTypes(aHand, X, Y, aHouseTypes, succeed);
    if not succeed then
    begin
      // Collect house types to string
      strSet := '';
      for HT in aHouseTypes do
        strSet := strSet + IfThen(strSet <> '', ', ') + GetEnumName(TypeInfo(TKMHouseType), Integer(HT));
      strSet := '[' + strSet + ']';

      LogParamWarn('States.ClosestHouseMultipleTypesEx', [aHand, X, Y, strSet]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


function TKMScriptStates._ClosestUnit(aHand, X, Y: Integer; aUnitType: TKMUnitType; out aSucceed: Boolean): Integer;
var
  U: TKMUnit;
  UTS: TKMUnitTypeSet;
begin
  Result := -1;
  aSucceed := False;
  if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled
    and gTerrain.TileInMapCoords(X, Y)
    and ((aUnitType = utAny) or (aUnitType in [UNIT_MIN..UNIT_MAX]))  then
  begin
    if aUnitType = utAny then
      UTS := [UNIT_MIN..UNIT_MAX]
    else
      UTS := [aUnitType];

    U := gHands[aHand].Units.GetClosestUnit(KMPoint(X,Y), UTS);
    if U <> nil then
    begin
      Result := U.UID;
      fIDCache.CacheUnit(U, U.UID);
    end;
    aSucceed := True;
  end;
end;


//* Version: 6216
//* Returns the unit of the specified player and unit type that is closest to the specified coordinates,
//* or -1 if no such unit was found.
//* If the unit type is -1 any unit type will be accepted
//* Result: Unit ID
function TKMScriptStates.ClosestUnit(aHand, X, Y, aUnitType: Integer): Integer;
var
  UT: TKMUnitType;
  succeed: Boolean;
begin
  try
    UT := utNone;

    if (aUnitType = -1) then
      UT := utAny
    else
    if (aUnitType in [Low(UNIT_ID_TO_TYPE)..High(UNIT_ID_TO_TYPE)]) then
      UT := UNIT_ID_TO_TYPE[aUnitType];

    Result := _ClosestUnit(aHand, X, Y, UT, succeed);
    if not succeed then
      LogIntParamWarn('States.ClosestUnit', [aHand, X, Y, aUnitType]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns the unit of the specified player and unit type that is closest to the specified coordinates,
//* or -1 if no such unit was found.
//* If the unit type is utAny any unit type will be accepted
//* Result: Unit ID
function TKMScriptStates.ClosestUnitEx(aHand, X, Y: Integer; aUnitType: TKMUnitType): Integer;
var
  succeed: Boolean;
begin
  try
    Result := _ClosestUnit(aHand, X, Y, aUnitType, succeed);
    if not succeed then
      LogParamWarn('States.ClosestUnitEx', [aHand, X, Y, GetEnumName(TypeInfo(TKMUnitType), Integer(aUnitType))]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


function TKMScriptStates._ClosestUnitMultipleTypes(aHand, X, Y: Integer; aUnitTypes: TKMUnitTypeSet; out aSucceed: Boolean): Integer;
var
  U: TKMUnit;
begin
  Result := -1;
  aSucceed := False;
  if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled
    and gTerrain.TileInMapCoords(X, Y) then
  begin
    aUnitTypes := aUnitTypes * [UNIT_MIN..UNIT_MAX];
    U := gHands[aHand].Units.GetClosestUnit(KMPoint(X,Y), aUnitTypes);
    if U <> nil then
    begin
      Result := U.UID;
      fIDCache.CacheUnit(U, U.UID);
    end;
    aSucceed := True;
  end;
end;



//* Version: 6216
//* Returns the unit of the specified player and unit types that is closest to the specified coordinates,
//* or -1 if no such unit was found.
//* The unit types is a "set of Byte", for example [0,9]
//* aUnitTypes: Set of unit types
//* Result: Unit ID
function TKMScriptStates.ClosestUnitMultipleTypes(aHand, X, Y: Integer; aUnitTypes: TByteSet): Integer;
var
  B: Byte;
  UTS: TKMUnitTypeSet;
  succeed: Boolean;
  strSet: string;
begin
  try
    UTS := [];
    for B in [Low(UNIT_ID_TO_TYPE)..High(UNIT_ID_TO_TYPE)] do
      if B in aUnitTypes then
        UTS := UTS + [UNIT_ID_TO_TYPE[B]];

    Result := _ClosestUnitMultipleTypes(aHand, X, Y, UTS, succeed);
    if not succeed then
    begin
      // Collect unit types to string
      strSet := '';
      for B in aUnitTypes do
        strSet := strSet + IfThen(strSet <> '', ', ') + IntToStr(B);
      strSet := '[' + strSet + ']';

      LogParamWarn('States.ClosestUnitMultipleTypes', [aHand, X, Y, strSet]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns the unit of the specified player and unit types that is closest to the specified coordinates,
//* or -1 if no such unit was found.
//* The unit types is a "set of TKMUnitType", for example [utSerf, utMilitia]
//* aUnitTypes: Set of unit types
//* Result: Unit ID
function TKMScriptStates.ClosestUnitMultipleTypesEx(aHand, X, Y: Integer; aUnitTypes: TKMUnitTypeSet): Integer;
var
  succeed: Boolean;
  strSet: string;
  UT: TKMUnitType;
begin
  try
    Result := _ClosestUnitMultipleTypes(aHand, X, Y, aUnitTypes, succeed);
    if not succeed then
    begin
      // Collect unit types to string
      strSet := '';
      for UT in aUnitTypes do
        strSet := strSet + IfThen(strSet <> '', ', ') + GetEnumName(TypeInfo(TKMUnitType), Integer(UT));
      strSet := '[' + strSet + ']';

      LogParamWarn('States.ClosestUnitMultipleTypesEx', [aHand, X, Y, strSet]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6602
//* Check if two tiles are connected by walkable road
//* X1: left coordinate
//* Y1: top coordinate
//* X2: right coordinate
//* Y2: bottom coordinate
//* Result: Connected
function TKMScriptStates.ConnectedByRoad(X1, Y1, X2, Y2: Integer): Boolean;
begin
  try
    if gTerrain.TileInMapCoords(X1,Y1) and gTerrain.TileInMapCoords(X2,Y2) then
      Result := (gTerrain.GetRoadConnectID(KMPoint(X1, Y1)) <> 0) and
                (gTerrain.GetRoadConnectID(KMPoint(X1, Y1)) = gTerrain.GetRoadConnectID(KMPoint(X2, Y2)))
    else
    begin
      Result := False;
      LogIntParamWarn('States.ConnectedByRoad', [X1, Y1, X2, Y2]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6602
//* Check if two tiles are connected by a walkable route
//* X1: Left coordinate
//* Y1: Top coordinate
//* X2: Right coordinate
//* Y2: Bottom coordinate
//* Result: Connected
function TKMScriptStates.ConnectedByWalking(X1, Y1, X2, Y2: Integer): Boolean;
begin
  try
    if gTerrain.TileInMapCoords(X1,Y1) and gTerrain.TileInMapCoords(X2,Y2) then
      Result := (gTerrain.GetWalkConnectID(KMPoint(X1, Y1)) <> 0) and
                (gTerrain.GetWalkConnectID(KMPoint(X1, Y1)) = gTerrain.GetWalkConnectID(KMPoint(X2, Y2)))
    else
    begin
      Result := False;
      LogIntParamWarn('States.ConnectedByWalking', [X1, Y1, X2, Y2]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6323
//* How many defence positions AI player has.
//* Useful for scripts like "if not enough positions and too much groups then add a new position"
//* Result: Defence position count
function TKMScriptStates.StatAIDefencePositionsCount(aHand: Byte): Integer;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1)
    and gHands[aHand].Enabled then
    begin
      if gHands[aHand].AI.Setup.NewAI then
        Result := gHands[aHand].AI.General.DefencePositions.Count
      else
        Result := gHands[aHand].AI.General.DefencePositions.Count;
    end
    else
    begin
      Result := 0;
      LogIntParamWarn('States.StatAIDefencePositionsCount', [aHand]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* How many military units player has
//* Result: Army count
function TKMScriptStates.StatArmyCount(aHand: Byte): Integer;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := gHands[aHand].Stats.GetArmyCount
    else
    begin
      Result := 0;
      LogIntParamWarn('States.StatArmyCount', [aHand]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13660
//* The power factor of a player's army
//* Result: Army power
function TKMScriptStates.StatArmyPower(aHand: Byte): Single;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := gHands[aHand].Stats.GetArmyPower
    else
    begin
      Result := 0.0;
      LogIntParamWarn('States.StatArmyPower', [aHand]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* How many citizen player has
//* Result: Citizen count
function TKMScriptStates.StatCitizenCount(aHand: Byte): Integer;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := gHands[aHand].Stats.GetCitizensCount
    else
    begin
      Result := 0;
      LogIntParamWarn('States.StatCitizenCount', [aHand]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Get the game speed
//* Result: Game speed
function TKMScriptStates.GameSpeed: Single;
begin
  try
    Result := gGame.SpeedGIP; //Return recorded as GIP speed, not actual!
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Return True if game speed change is allowed
//* Result: Is game speed change allowed
function TKMScriptStates.GameSpeedChangeAllowed: Boolean;
begin
  try
    Result := gGame.SpeedChangeAllowed;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Get the number of game ticks since mission start
//* Result: Ticks (~10 per second)
function TKMScriptStates.GameTime: Cardinal;
begin
  try
    Result := gGameParams.Tick;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Length of peacetime in ticks (multiplayer)
//* Result: Ticks (~10 per second)
function TKMScriptStates.PeaceTime: Cardinal;
begin
  try
    Result := 600 * gGame.Options.Peacetime;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Check how player 1 feels towards player 2 (order matters).
//* Returns True for ally, False for enemy
//* Result: Allied
function TKMScriptStates.PlayerAllianceCheck(aHand1, aHand2: Byte): Boolean;
begin
  try
    if  InRange(aHand1, 0, gHands.Count - 1)
      and InRange(aHand2, 0, gHands.Count - 1)
      and gHands[aHand1].Enabled
      and gHands[aHand2].Enabled then
      Result := gHands[aHand1].Alliances[aHand2] = atAlly
    else
    begin
      Result := False;
      LogIntParamWarn('States.PlayerAllianceCheck', [aHand1, aHand2]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;

//* Version: 10940
//* Returns the number of houses of the specified player
//* Result: Number of houses
function TKMScriptStates.StatHouseCount(aHand: Byte): Integer;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := gHands[aHand].Stats.GetHouseQty(htAny)
    else
    begin
      Result := 0;
      LogIntParamWarn('States.StatHouseCount', [aHand]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6328
//* Returns number of specified house types for specified player.
//* aTypes: House types eg. [11, 13, 21]
//* Result: Total number of houses
function TKMScriptStates.StatHouseMultipleTypesCount(aHand: Byte; aTypes: TByteSet): Integer;
var
  htID: Byte;
begin
  try
    Result := 0;
    if InRange(aHand, 0, gHands.Count - 1)
    and gHands[aHand].Enabled then
    begin
      for htID := Low(HOUSE_ID_TO_TYPE) to High(HOUSE_ID_TO_TYPE) do
        if (htID in aTypes) and (HOUSE_ID_TO_TYPE[htID] <> htNone) then
          Inc(Result, gHands[aHand].Stats.GetHouseQty(HOUSE_ID_TO_TYPE[htID]));
    end
    else
      LogIntParamWarn('States.StatHouseMultipleTypesCount', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns number of specified house types for specified player.
//* aTypes: House types eg. [htQuary, htSchool, htStore]
//* Result: Total number of houses
function TKMScriptStates.StatHouseMultipleTypesCountEx(aHand: Integer; aTypes: TKMHouseTypeSet): Integer;
var
  HT: TKMHouseType;
  strSet: string;
begin
  try
    Result := 0;
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
    begin
      aTypes := aTypes * HOUSES_VALID;
      for HT in aTypes do
        Inc(Result, gHands[aHand].Stats.GetHouseQty(HT));
    end
    else
    begin
      strSet := '';
      for HT in aTypes do
        strSet := strSet + IfThen(strSet <> '', ', ') + GetEnumName(TypeInfo(TKMHouseType), Integer(HT));
      strSet := '[' + strSet + ']';

      LogParamWarn('States.StatHouseMultipleTypesCountEx', [aHand, strSet]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the total number of the specified house type for the specified player.
//* Result: Number of houses
function TKMScriptStates.StatHouseTypeCount(aHand, aHouseType: Byte): Integer;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled
      and HouseTypeValid(aHouseType) then
      Result := gHands[aHand].Stats.GetHouseQty(HOUSE_ID_TO_TYPE[aHouseType])
    else
    begin
      Result := 0;
      LogIntParamWarn('States.StatHouseTypeCount', [aHand, aHouseType]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns the total number of the specified house type for the specified player.
//* Result: Number of houses
function TKMScriptStates.StatHouseTypeCountEx(aHand: Integer; aHouseType: TKMHouseType): Integer;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled
    and (aHouseType in HOUSES_VALID) then
      Result := gHands[aHand].Stats.GetHouseQty(aHouseType)
    else
    begin
      Result := 0;
      LogParamWarn('States.StatHouseTypeCountEx', [aHand, GetEnumName(TypeInfo(TKMHouseType), Integer(aHouseType))]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6313
//* Specified house type plans count
//* Result: Number of plans
function TKMScriptStates.StatHouseTypePlansCount(aHand, aHouseType: Byte): Integer;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1)
      and gHands[aHand].Enabled
      and HouseTypeValid(aHouseType) then
      Result := gHands[aHand].Stats.GetHousePlans(HOUSE_ID_TO_TYPE[aHouseType])
    else
    begin
      Result := 0;
      LogIntParamWarn('States.StatHouseTypePlansCount', [aHand, aHouseType]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Specified house type plans count
//* Result: Number of plans
function TKMScriptStates.StatHouseTypePlansCountEx(aHand: Integer; aHouseType: TKMHouseType): Integer;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1)
      and gHands[aHand].Enabled
      and (aHouseType in HOUSES_VALID) then
      Result := gHands[aHand].Stats.GetHousePlans(aHouseType)
    else
    begin
      Result := 0;
      LogParamWarn('States.StatHouseTypePlansCountEx', [aHand, GetEnumName(TypeInfo(TKMHouseType), Integer(aHouseType))]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* How many active players there are.
//* Result: Number of players
function TKMScriptStates.StatPlayerCount: Integer;
var
  I: Integer;
begin
  try
    Result := 0;
    for I := 0 to gHands.Count - 1 do
      if gHands[I].Enabled then
        Inc(Result);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* See if player was defeated
//* Result: Defeated
function TKMScriptStates.PlayerDefeated(aHand: Byte): Boolean;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := gHands[aHand].AI.HasLost
    else
    begin
      Result := False;
      LogIntParamWarn('States.PlayerDefeated', [aHand]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 4545
//* See if player is victorious
//* Result: Victorious
function TKMScriptStates.PlayerVictorious(aHand: Byte): Boolean;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := (gHands[aHand].AI.HasWon)
    else
    begin
      Result := False;
      LogIntParamWarn('States.PlayerVictorious', [aHand]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5345
//* Returns the ware distribution for the specified resource, house and player
//* Result: Ware distribution [0..5]
function TKMScriptStates.PlayerWareDistribution(aHand, aWareType, aHouseType: Byte): Byte;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled
      and(aWareType in [Low(WARE_ID_TO_TYPE) .. High(WARE_ID_TO_TYPE)])
      and HouseTypeValid(aHouseType) then
      Result := gHands[aHand].Stats.WareDistribution[WARE_ID_TO_TYPE[aWareType], HOUSE_ID_TO_TYPE[aHouseType]]
    else
    begin
      Result := 0;
      LogIntParamWarn('States.PlayerWareDistribution', [aHand, aWareType, aHouseType]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14600
//* Returns the ware distribution for the specified resource, house and player
//* Result: Ware distribution [0..5]
function TKMScriptStates.PlayerWareDistributionEx(aHand: Integer; aWareType: TKMWareType; aHouseType: TKMHouseType): Integer;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled
      and (aWareType in WARES_VALID)
      and (aHouseType in HOUSES_VALID) then
      Result := gHands[aHand].Stats.WareDistribution[aWareType, aHouseType]
    else
    begin
      Result := 0;
      LogParamWarn('States.PlayerWareDistributionEx', [aHand, GetEnumName(TypeInfo(TKMWareType), Integer(aWareType)),
                                                              GetEnumName(TypeInfo(TKMHouseType), Integer(aHouseType))]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5165
//* Returns an array with IDs for all the units of the specified player
//* Result: Array of unit IDs
function TKMScriptStates.PlayerGetAllUnits(aHand: Byte): TIntegerArray;
var
  I, unitCount: Integer;
  U: TKMUnit;
begin
  try
    SetLength(Result, 0);

    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
    begin
      unitCount := 0;

      //Allocate max required space
      SetLength(Result, gHands[aHand].Units.Count);
      for I := 0 to gHands[aHand].Units.Count - 1 do
      begin
        U := gHands[aHand].Units[I];
        //Skip units in training, they can't be disturbed until they are finished training
        if U.IsDeadOrDying or (U.Task is TKMTaskSelfTrain) then Continue;
        Result[unitCount] := U.UID;
        Inc(unitCount);
      end;

      //Trim to length
      SetLength(Result, unitCount);
    end
    else
    begin
      LogIntParamWarn('States.PlayerGetAllUnits', [aHand]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5209
//* Returns an array with IDs for all the houses of the specified player
//* Result: Array of house IDs
function TKMScriptStates.PlayerGetAllHouses(aHand: Byte): TIntegerArray;
var
  I, houseCount: Integer;
  H: TKMHouse;
begin
  try
    SetLength(Result, 0);

    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
    begin
      houseCount := 0;

      //Allocate max required space
      SetLength(Result, gHands[aHand].Houses.Count);
      for I := 0 to gHands[aHand].Houses.Count - 1 do
      begin
        H := gHands[aHand].Houses[I];
        if H.IsDestroyed then Continue;
        Result[houseCount] := H.UID;
        Inc(houseCount);
      end;

      //Trim to length
      SetLength(Result, houseCount);
    end
    else
    begin
      LogIntParamWarn('States.PlayerGetAllHouses', [aHand]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5209
//* Returns an array with IDs for all the groups of the specified player
//* Result: Array of group IDs
function TKMScriptStates.PlayerGetAllGroups(aHand: Byte): TIntegerArray;
var
  I, groupCount: Integer;
  G: TKMUnitGroup;
begin
  try
    SetLength(Result, 0);

    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
    begin
      groupCount := 0;

      //Allocate max required space
      SetLength(Result, gHands[aHand].UnitGroups.Count);
      for I := 0 to gHands[aHand].UnitGroups.Count - 1 do
      begin
        G := gHands[aHand].UnitGroups[I];
        if G.IsDead then Continue;
        Result[groupCount] := G.UID;
        Inc(groupCount);
      end;

      //Trim to length
      SetLength(Result, groupCount);
    end
    else
    begin
      LogIntParamWarn('States.PlayerGetAllGroups', [aHand]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5927
//* Wherever player is controlled by AI
//* Result: Player is AI
function TKMScriptStates.PlayerIsAI(aHand: Byte): Boolean;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := gHands[aHand].IsComputer
    else
    begin
      Result := False;
      LogIntParamWarn('States.PlayerIsAI', [aHand]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14600
//* Wherever player is controlled by Advanced AI
//* Result: Player is Advanced AI
function TKMScriptStates.PlayerIsAdvancedAI(aHand: Byte): Boolean;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := gHands[aHand].IsAdvancedAI
    else
    begin
      Result := False;
      LogParamWarn('States.PlayerIsAdvancedAI', [aHand]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Verson: 14600
//* Wherever player is controlled by Classic AI
//* Result: Player is Classic AI
function TKMScriptStates.PlayerIsClassicAI(aHand: Byte): Boolean;
begin
    try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := gHands[aHand].IsClassicAI
    else
    begin
      Result := False;
      LogParamWarn('States.PlayerIsClassicAI', [aHand]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 4289
//* Returns the number of units of the specified player
//* Result: Number of units
function TKMScriptStates.StatUnitCount(aHand: Byte): Integer;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := gHands[aHand].Stats.GetUnitQty(utAny)
    else
    begin
      Result := 0;
      LogIntParamWarn('States.StatUnitCount', [aHand]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6328
//* Returns number of specified unit types for specified player.
//* aTypes: Set of unit types eg. [0, 5, 13]
//* Result: Total number of  units
function TKMScriptStates.StatUnitMultipleTypesCount(aHand: Byte; aTypes: TByteSet): Integer;
var
  utID: Byte;
begin
  try
    Result := 0;
    if InRange(aHand, 0, gHands.Count - 1)
    and gHands[aHand].Enabled then
    begin
      for utID := Low(UNIT_ID_TO_TYPE) to High(UNIT_ID_TO_TYPE) do
        if utID in aTypes then
          Inc(Result, gHands[aHand].Stats.GetUnitQty(UNIT_ID_TO_TYPE[utID]));
    end
    else
      LogIntParamWarn('States.StatUnitMultipleTypesCount', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns number of specified unit types for specified player.
//* aTypes: Set of unit types eg. [utSerf, utMilitia]
//* Result: Total number of  units
function TKMScriptStates.StatUnitMultipleTypesCountEx(aHand: Integer; aTypes: TKMUnitTypeSet): Integer;
var
  UT: TKMUnitType;
  strSet: string;
begin
  try
    Result := 0;
    if InRange(aHand, 0, gHands.Count - 1)
      and gHands[aHand].Enabled then
    begin
      aTypes := aTypes * UNITS_HUMAN; // Only humans could be counted (we have stats only for them)
      for UT in aTypes do
        Inc(Result, gHands[aHand].Stats.GetUnitQty(UT));
    end
    else
    begin
      // Collect unit types to string
      strSet := '';
      for UT in aTypes do
        strSet := strSet + IfThen(strSet <> '', ', ') + GetEnumName(TypeInfo(TKMUnitType), Integer(UT));
      strSet := '[' + strSet + ']';

      LogParamWarn('States.StatUnitMultipleTypesCountEx', [aHand, strSet]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns number of specified unit type for specified player
//* Result: Number of units
function TKMScriptStates.StatUnitTypeCount(aHand, aUnitType: Byte): Integer;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled
      and (aUnitType in [Low(UNIT_ID_TO_TYPE)..High(UNIT_ID_TO_TYPE)]) then
      Result := gHands[aHand].Stats.GetUnitQty(UNIT_ID_TO_TYPE[aUnitType])
    else
    begin
      Result := 0;
      LogIntParamWarn('States.StatUnitTypeCount', [aHand, aUnitType]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns number of specified unit type for specified player
//* if passed utAny as unit type, then returns number of all units for the specified player
//* Result: Number of units
function TKMScriptStates.StatUnitTypeCountEx(aHand: Integer; aUnitType: TKMUnitType): Integer;
begin
  Result := 0;
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled
      and ((aUnitType = utAny) or (aUnitType in UNITS_HUMAN)) then
      Result := gHands[aHand].Stats.GetUnitQty(aUnitType)
    else
      LogParamWarn('States.StatUnitTypeCountEx', [aHand, GetEnumName(TypeInfo(TKMUnitType), Integer(aUnitType))]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the number of the specified unit killed by the specified player
//* Result: Number of killed units
function TKMScriptStates.StatUnitKilledCount(aHand, aUnitType: Byte): Integer;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled
      and (aUnitType in [Low(UNIT_ID_TO_TYPE)..High(UNIT_ID_TO_TYPE)]) then
      Result := gHands[aHand].Stats.GetUnitKilledQty(UNIT_ID_TO_TYPE[aUnitType])
    else
    begin
      Result := 0;
      LogIntParamWarn('States.StatUnitKilledCount', [aHand, aUnitType]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns the number of the specified unit killed by the specified player
//* if utAny is passed, then return all killed units by the specified player
//* Result: Number of killed units
function TKMScriptStates.StatUnitKilledCountEx(aHand: Integer; aUnitType: TKMUnitType): Integer;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled
      and ((aUnitType = utAny) or (aUnitType in [HUMANS_MIN..HUMANS_MAX])) then
    begin
      Result := gHands[aHand].Stats.GetUnitKilledQty(aUnitType);
    end
    else
    begin
      Result := 0;
      LogParamWarn('States.StatUnitKilledCountEx', [aHand, GetEnumName(TypeInfo(TKMUnitType), Integer(aUnitType))]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6331
//* Returns the number of the specified unit types killed by the specified player.
//* Result: Set of unit types eg. [0, 5, 13]
function TKMScriptStates.StatUnitKilledMultipleTypesCount(aHand: Byte; aTypes: TByteSet): Integer;
var
  utID: Byte;
begin
  try
    Result := 0;
    if InRange(aHand, 0, gHands.Count - 1)
    and gHands[aHand].Enabled then
    begin
      for utID := Low(UNIT_ID_TO_TYPE) to High(UNIT_ID_TO_TYPE) do
        if utID in aTypes then
          Inc(Result, gHands[aHand].Stats.GetUnitKilledQty(UNIT_ID_TO_TYPE[utID]));
    end
    else
      LogIntParamWarn('States.StatUnitKilledMultipleTypesCount', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns the number of the specified unit types killed by the specified player.
//* Result: Set of unit types eg. [utMilitia, utAxeFighter, utSwordsman]
function TKMScriptStates.StatUnitKilledMultipleTypesCountEx(aHand: Integer; aTypes: TKMUnitTypeSet): Integer;
var
  UT: TKMUnitType;
  strSet: string;
begin
  try
    Result := 0;
    if InRange(aHand, 0, gHands.Count - 1)
      and gHands[aHand].Enabled then
    begin
      aTypes := aTypes * UNITS_HUMAN; // Only humans could be killed
      for UT in aTypes do
        Inc(Result, gHands[aHand].Stats.GetUnitKilledQty(UT));
    end
    else
    begin
      // Collect unit types to string
      strSet := '';
      for UT in aTypes do
        strSet := strSet + IfThen(strSet <> '', ', ') + GetEnumName(TypeInfo(TKMUnitType), Integer(UT));
      strSet := '[' + strSet + ']';

      LogParamWarn('States.StatUnitKilledMultipleTypesCountEx', [aHand, strSet]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the number of the specified unit lost by the specified player
//* Result: Number of lost units
function TKMScriptStates.StatUnitLostCount(aHand, aUnitType: Byte): Integer;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled
      and (aUnitType in [Low(UNIT_ID_TO_TYPE)..High(UNIT_ID_TO_TYPE)]) then
      Result := gHands[aHand].Stats.GetUnitLostQty(UNIT_ID_TO_TYPE[aUnitType])
    else
    begin
      Result := 0;
      LogIntParamWarn('States.StatUnitLostCount', [aHand, aUnitType]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns the number of the specified unit lost by the specified player
//* if utAny is passed, then return number of all lost units by the specified player
//* Result: Number of lost units
function TKMScriptStates.StatUnitLostCountEx(aHand: Integer; aUnitType: TKMUnitType): Integer;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled
      and ((aUnitType = utAny) or (aUnitType in [HUMANS_MIN..HUMANS_MAX])) then
    begin
      Result := gHands[aHand].Stats.GetUnitLostQty(aUnitType);
    end
    else
    begin
      Result := 0;
      LogParamWarn('States.StatUnitLostCountEx', [aHand, GetEnumName(TypeInfo(TKMUnitType), Integer(aUnitType))]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6331
//* Returns the number of the specified unit types lost by the specified player.
//* aTypes: Set of unit types eg. [0, 5, 13]
//* Result: Number of lost units
function TKMScriptStates.StatUnitLostMultipleTypesCount(aHand: Byte; aTypes: TByteSet): Integer;
var
  utID: Byte;
begin
  try
    Result := 0;
    if InRange(aHand, 0, gHands.Count - 1)
    and gHands[aHand].Enabled then
    begin
      for utID := Low(UNIT_ID_TO_TYPE) to High(UNIT_ID_TO_TYPE) do
        if utID in aTypes then
          Inc(Result, gHands[aHand].Stats.GetUnitLostQty(UNIT_ID_TO_TYPE[utID]));
    end
    else
      LogIntParamWarn('States.StatUnitLostMultipleTypesCount', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns the number of the specified unit types lost by the specified player.
//* aTypes: Set of unit types eg. [utMilitia, utAxeFighter, utSwordsman]
//* Result: Number of lost units
function TKMScriptStates.StatUnitLostMultipleTypesCountEx(aHand: Byte; aTypes: TKMUnitTypeSet): Integer;
var
  UT: TKMUnitType;
  strSet: string;
begin
  try
    Result := 0;
    if InRange(aHand, 0, gHands.Count - 1)
      and gHands[aHand].Enabled then
    begin
      aTypes := aTypes * UNITS_HUMAN; // Only humans could be lost
      for UT in aTypes do
        Inc(Result, gHands[aHand].Stats.GetUnitLostQty(UT));
    end
    else
    begin
      // Collect unit types to string
      strSet := '';
      for UT in aTypes do
        strSet := strSet + IfThen(strSet <> '', ', ') + GetEnumName(TypeInfo(TKMUnitType), Integer(UT));
      strSet := '[' + strSet + ']';

      LogParamWarn('States.StatUnitLostMultipleTypesCountEx', [aHand, strSet]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the number of the specified resource produced by the specified player
//* Result: Number of produced resources
function TKMScriptStates.StatResourceProducedCount(aHand, aResType: Byte): Integer;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled
      and (aResType in [Low(WARE_ID_TO_TYPE)..High(WARE_ID_TO_TYPE)]) then
      Result := gHands[aHand].Stats.GetWaresProduced(WARE_ID_TO_TYPE[aResType])
    else
    begin
      Result := 0;
      LogIntParamWarn('States.StatResourceProducedCount', [aHand, aResType]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns the number of the specified resource produced by the specified player
//* if wtFood is passed, then all produced food will be returned
//* if wtWarfare is passed, then all produced warfare will be returned, including horses
//* if wtAll is passed, then all produced wares will be returned
//* Result: Number of produced resources
function TKMScriptStates.StatResourceProducedCountEx(aHand: Integer; aWareType: TKMWareType): Integer;
var
  WT: TKMWareType;
  WTS: TKMWareTypeSet;
begin
  Result := 0;
  try
    if InRange(aHand, 0, gHands.Count - 1)
      and gHands[aHand].Enabled
      and (aWareType <> wtNone) then
    begin
      case aWareType of
        wtNone:     WTS := [];
        wtWarfare:  WTS := WARES_WARFARE;
        wtFood:     WTS := WARES_FOOD;
        wtAll:      WTS := WARES_VALID;
        else        WTS := [aWareType];
      end;

      for WT in WTS do
        Result := Result + gHands[aHand].Stats.GetWaresProduced(WT);
    end
    else
      LogParamWarn('States.StatResourceProducedCountEx', [aHand, GetEnumName(TypeInfo(TKMWareType), Integer(aWareType))]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6331
//* Returns the number of the specified resource types produced by the specified player.
//* aTypes: Set of ware types eg. [8, 10, 13, 27] for food
//* Result: Number of produced resources
function TKMScriptStates.StatResourceProducedMultipleTypesCount(aHand: Byte; aTypes: TByteSet): Integer;
var
  wtID: Byte;
begin
  try
    Result := 0;
    if InRange(aHand, 0, gHands.Count - 1)
    and gHands[aHand].Enabled then
    begin
      for wtID := Low(WARE_ID_TO_TYPE) to High(WARE_ID_TO_TYPE) do
        if wtID in aTypes then
          Inc(Result, gHands[aHand].Stats.GetWaresProduced(WARE_ID_TO_TYPE[wtID]));
    end
    else
      LogIntParamWarn('States.StatResourceProducedMultipleTypesCount', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns the number of the specified resource types produced by the specified player.
//* aTypes: Set of ware types eg. [wtCoal, wtSteel, wtGold]
//* Result: Number of produced resources
function TKMScriptStates.StatResourceProducedMultipleTypesCountEx(aHand: Integer; aTypes: TKMWareTypeSet): Integer;
var
  WT: TKMWareType;
  strSet: string;
begin
  try
    Result := 0;
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
    begin
      aTypes := aTypes * WARES_VALID;
      for WT in aTypes do
        Inc(Result, gHands[aHand].Stats.GetWaresProduced(WT));
    end
    else
    begin
      strSet := '';
      for WT in aTypes do
        strSet := strSet + IfThen(strSet <> '', ', ') + GetEnumName(TypeInfo(TKMWareType), Integer(WT));
      strSet := '[' + strSet + ']';

      LogParamWarn('States.StatResourceProducedMultipleTypesCountEx', [aHand, strSet]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 10940
//* Get players color in hex format
//* Result: Player color
function TKMScriptStates.PlayerColorFlag(aHand: Byte): AnsiString;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := AnsiString(Format('%.6x', [gHands[aHand].FlagColor and $FFFFFF]))
    else
    begin
      Result := '';
      LogIntParamWarn('States.PlayerColorFlag', [aHand]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 4758
//* Get players color as text in hex format
//* Result: Player color as text
function TKMScriptStates.PlayerColorText(aHand: Byte): AnsiString;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
    begin
      //Use FlagColorToTextColor to desaturate and lighten the text so all player colours are
      //readable on a variety of backgrounds
      Result := AnsiString(Format('%.6x', [FlagColorToTextColor(gHands[aHand].FlagColor) and $FFFFFF]))
    end
    else
    begin
      Result := '';
      LogIntParamWarn('States.PlayerColorText', [aHand]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Will be False if nobody selected that location in multiplayer
//* Result: Enabled
function TKMScriptStates.PlayerEnabled(aHand: Byte): Boolean;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) then
      Result := gHands[aHand].Enabled
    else
    begin
      Result := False;
      LogIntParamWarn('States.PlayerEnabled', [aHand]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14600
//* Returns True if the specified player can build the specified house type
//* Result: House can be build
function TKMScriptStates.PlayerHouseTypeCanBuild(aHand: Integer; aHouseType: TKMHouseType): Boolean;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled
    and (aHouseType in HOUSES_VALID) then
      Result := gHands[aHand].Locks.HouseCanBuild(aHouseType)
    else
    begin
      Result := False;
      LogIntParamWarn('States.PlayerHouseTypeCanBuild', [aHand, Ord(aHouseType)]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14600
//* Returns player house type lock as enum value of TKMHandHouseLock = (hlDefault, hlBlocked, hlGranted)
//* Result: Player house type lock
function TKMScriptStates.PlayerHouseTypeLock(aHand: Integer; aHouseType: TKMHouseType): TKMHandHouseLock;
begin
  Result := hlNone;
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled
    and (aHouseType in HOUSES_VALID) then
      Result := gHands[aHand].Locks.HouseLock[aHouseType]
    else
      LogIntParamWarn('States.PlayerHouseTypeLock', [aHand, Ord(aHouseType)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Get name of player as a string (for multiplayer)
//* Result: Player name
function TKMScriptStates.PlayerName(aHand: Byte): AnsiString;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      // Don't use localized names, since AI will be return differently for script,
      // and we could get desync or save difference
      Result := AnsiString(gHands[aHand].OwnerName(True, False))
    else
    begin
      Result := '';
      LogIntParamWarn('States.PlayerName', [aHand]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14600
//* Returns True if the specified player can train / equip the specified unit type
//* Result: Unit could be trained / equipped
function TKMScriptStates.PlayerUnitTypeCanTrain(aHand: Integer; aUnitType: TKMUnitType): Boolean;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1)
      and gHands[aHand].Enabled
      and (aUnitType in UNITS_HUMAN) then
      Result := not gHands[aHand].Locks.GetUnitBlocked(aUnitType)
    else
    begin
      Result := False;
      LogParamWarn('States.PlayerUnitTypeCanTrain', [aHand, GetEnumName(TypeInfo(TKMUnitType), Integer(aUnitType))]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 10940
//* Return if specified house is allowed to be selected and viewed by his allies
function TKMScriptStates.HouseAllowAllyToSelect(aHouseID: Integer): Boolean;
var
  H: TKMHouse;
begin
  try
    Result := False;
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil) and not H.IsDestroyed and (H.IsComplete) then
        Result := H.AllowAllyToSelect;
    end
    else
      LogIntParamWarn('States.HouseAllowAllyToSelect', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the ID of the house at the specified location or -1 if no house exists there
//* Result: House ID
function TKMScriptStates.HouseAt(aX, aY: Integer): Integer;
var
  H: TKMHouse;
begin
  try
    Result := UID_NONE;
    if gTerrain.TileInMapCoords(aX,aY) then
    begin
      H := gHands.HousesHitTest(aX, aY);
      if (H <> nil) and not H.IsDestroyed then
      begin
        Result := H.UID;
        fIDCache.CacheHouse(H, H.UID); //Improves cache efficiency since H will probably be accessed soon
      end;
    end
    else
      LogIntParamWarn('States.HouseAt', [aX, aY]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6516
//* Returns X coordinate of Rally Point of specified barracks or 0 if BarracksID is invalid
//* Result: X coordinate
function TKMScriptStates.HouseBarracksRallyPointX(aBarracks: Integer): Integer;
var
  H: TKMHouse;
begin
  try
    Result := 0;
    if aBarracks > 0 then
    begin
      H := fIDCache.GetHouse(aBarracks);
      if (H <> nil) and not H.IsDestroyed  and (H.IsComplete) then
      begin
        if (H is TKMHouseBarracks) then
          Result := TKMHouseBarracks(H).FlagPoint.X
        else
          LogIntParamWarn('States.HouseBarracksRallyPointX: Specified house is not Barracks', [aBarracks]);
      end;
    end
    else
      LogIntParamWarn('States.HouseBarracksRallyPointX', [aBarracks]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6516
//* Returns Y coordinate of Rally Point of specified barracks or 0 if BarracksID is invalid
//* Result: Y coordinate
function TKMScriptStates.HouseBarracksRallyPointY(aBarracks: Integer): Integer;
var
  H: TKMHouse;
begin
  try
    Result := 0;
    if aBarracks > 0 then
    begin
      H := fIDCache.GetHouse(aBarracks);
      if (H <> nil) and not H.IsDestroyed and (H.IsComplete) then
      begin
        if (H is TKMHouseBarracks) then
          Result := TKMHouseBarracks(H).FlagPoint.Y
        else
          LogIntParamWarn('States.HouseBarracksRallyPointY: Specified house is not Barracks', [aBarracks]);
      end;
    end
    else
      LogIntParamWarn('States.HouseBarracksRallyPointY', [aBarracks]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 12600
//* Return number of recruits in the specified barracks or 0 if BarracksID is invalid
function TKMScriptStates.HouseBarracksRecruitsCount(aBarracks: Integer): Integer;
var
  H: TKMHouse;
begin
  try
    Result := 0;
    if aBarracks > 0 then
    begin
      H := fIDCache.GetHouse(aBarracks);
      if (H <> nil) and not H.IsDestroyed and (H.IsComplete) then
      begin
        if (H is TKMHouseBarracks) then
          Result := TKMHouseBarracks(H).RecruitsCount
        else
          LogIntParamWarn('States.HouseBarracksRecruitsCount: Specified house is not Barracks', [aBarracks]);
      end;
    end
    else
      LogIntParamWarn('States.HouseBarracksRecruitsCount', [aBarracks]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Returns if recruits are blocked in the specified Barracks
function TKMScriptStates.HouseBarracksRecruitBlock(aHouseID: Integer): Boolean;
var
  H: TKMHouse;
begin
  Result := False;
  try
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil)
        and (H is TKMHouseBarracks)
        and not H.IsDestroyed
        and H.IsComplete then
        Result := TKMHouseBarracks(H).NotAcceptRecruitFlag;
    end
    else
      LogParamWarn('States.HouseBarracksRecruitBlock', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns House Flag Point of specified house or KMPoint(0,0) if aHouseId is invalid
//* Result: Flag Point
function TKMScriptStates.HouseFlagPoint(aHouseID: Integer): TKMPoint;
var
  H: TKMHouse;
begin
  try
    Result := KMPOINT_ZERO;
    if aHouseId > 0 then
    begin
      H := fIDCache.GetHouse(aHouseId);
      if (H <> nil) and not H.IsDestroyed and (H.IsComplete) then
      begin
        if (H is TKMHouseWFlagPoint) then
          Result := TKMHouseWFlagPoint(H).FlagPoint
        else
          LogIntParamWarn('States.HouseFlagPoint: Specified house does not have Flag point', [aHouseId]);
      end;
    end
    else
      LogIntParamWarn('States.HouseFlagPoint', [aHouseId]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 12982
//* Returns an array with IDs for all the units in the specified house
//* Result: Array of unit IDs
function TKMScriptStates.HouseGetAllUnitsIn(aHouseID: Integer): TIntegerArray;
var
  I, unitCount: Integer;
  U: TKMUnit;
  H: TKMHouse;
begin
  try
    SetLength(Result, 0);

    if aHouseId > 0 then
    begin
      unitCount := 0;

      H := fIDCache.GetHouse(aHouseId);
      if (H <> nil) and not H.IsDestroyed and (H.IsComplete) then
      begin
        //Allocate max required space
        SetLength(Result, gHands[H.Owner].Units.Count);

        for I := 0 to gHands[H.Owner].Units.Count - 1 do
        begin
          U := gHands[H.Owner].Units[I];
          //Skip units in training, they can't be disturbed until they are finished training
          //We want to get only units in a specified house
          if U.IsDeadOrDying
            or (U.Task is TKMTaskSelfTrain)
            or (U.InHouse <> H) then Continue;

          Result[unitCount] := U.UID;
          Inc(unitCount);
        end;

        //Trim to length
        SetLength(Result, unitCount);
      end;
    end
    else
    begin
      LogIntParamWarn('States.HouseGetAllUnitsIn', [aHouseId]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6285
//* Returns building progress of the specified house
//* Result: Building progress
function TKMScriptStates.HouseBuildingProgress(aHouseID: Integer): Integer;
var
  H: TKMHouse;
begin
  try
    Result := 0;
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil) then
        Result := H.BuildingProgress;
    end
    else
      LogIntParamWarn('States.HouseBuildingProgress', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5993
//* Returns True if the specified house can reach the resources that it mines (coal, stone, fish, etc.)
//* Result: Reachable
function TKMScriptStates.HouseCanReachResources(aHouseID: Integer): Boolean;
var
  H: TKMHouse;
begin
  try
    Result := False;
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        Result := not H.ResourceDepleted;
    end
    else
      LogIntParamWarn('States.HouseCanReachResources', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the damage of the specified house or -1 if House ID invalid
//* Result: House damage
function TKMScriptStates.HouseDamage(aHouseID: Integer): Integer;
var
  H: TKMHouse;
begin
  try
    Result := -1; //-1 if house id is invalid
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        Result := H.GetDamage;
    end
    else
      LogIntParamWarn('States.HouseDamage', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns True if the specified house has delivery disabled
//* Result: Blocked
function TKMScriptStates.HouseDeliveryBlocked(aHouseID: Integer): Boolean;
var
  H: TKMHouse;
begin
  try
    Result := True;
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        Result := (H.DeliveryMode <> dmDelivery);
    end
    else
      LogIntParamWarn('States.HouseDeliveryBlocked', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns house delivery mode,
//* if no house was found then ID = 1 is returned
//* Result: Delivery mode
function TKMScriptStates.HouseDeliveryMode(aHouseID: Integer): TKMDeliveryMode;
var
  H: TKMHouse;
begin
  try
    Result := dmDelivery;
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        Result := H.DeliveryMode;
    end
    else
      LogIntParamWarn('States.HouseDeliveryMode', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns True if the house is destroyed
//* Result: Destroyed
function TKMScriptStates.HouseDestroyed(aHouseID: Integer): Boolean;
var
  H: TKMHouse;
begin
  try
    Result := True;
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        Result := H.IsDestroyed;
    end
    else
      LogIntParamWarn('States.HouseDestroyed', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Status: Deprecated
//* Replacement: HouseHasWorker
//* Returns True if the specified house currently has a worker
//* Result: Has worker
function TKMScriptStates.HouseHasOccupant(aHouseID: Integer): Boolean;
var
  H: TKMHouse;
begin
  try
    Result := False;
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        Result := H.HasWorker;
    end
    else
      LogIntParamWarn('States.HouseHasOccupant', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13050
//* Returns True if the specified house currently has a worker
//* Result: Has worker
function TKMScriptStates.HouseHasWorker(aHouseID: Integer): Boolean;
var
  H: TKMHouse;
begin
  try
    Result := False;
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        Result := H.HasWorker;
    end
    else
      LogIntParamWarn('States.HouseHasWorker', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5345
//* Returns True if the specified house is fully built
//* Result:
function TKMScriptStates.HouseIsComplete(aHouseID: Integer): Boolean;
var
  H: TKMHouse;
begin
  try
    Result := False;
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        Result := H.IsComplete;
    end
    else
      LogIntParamWarn('States.HouseIsComplete', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 15000
//* Returns True if the specified house is closed for worker
//* Result:
function TKMScriptStates.HouseIsClosedForWorker(aHouseID: Integer): Boolean;
var
  H: TKMHouse;
begin
  try
    Result := False;
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        Result := H.IsClosedForWorker;
    end
    else
      LogIntParamWarn('States.HouseIsClosedForWorker', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns the Entrance Point of the specified house or (-1;-1) point if House ID invalid
//* Result: TKMPoint
function TKMScriptStates.HousePosition(aHouseID: Integer): TKMPoint;
var
  H: TKMHouse;
begin
  try
    Result := KMPOINT_INVALID_TILE;
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        Result := H.Entrance;
    end
    else
      LogIntParamWarn('States.HousePosition', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the X coordinate of the specified house or -1 if House ID invalid
//* Result: X coordinate
function TKMScriptStates.HousePositionX(aHouseID: Integer): Integer;
var
  H: TKMHouse;
begin
  try
    Result := UID_NONE;
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        Result := H.Entrance.X;
    end
    else
      LogIntParamWarn('States.HousePositionX', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the Y coordinate of the specified house or -1 if House ID invalid
//* Result: Y coordinate
function TKMScriptStates.HousePositionY(aHouseID: Integer): Integer;
var
  H: TKMHouse;
begin
  try
    Result := UID_NONE;
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        Result := H.Entrance.Y;
    end
    else
      LogIntParamWarn('States.HousePositionY', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the owner of the specified house or -1 if House ID invalid
//* Result: Player ID
function TKMScriptStates.HouseOwner(aHouseID: Integer): Integer;
var
  H: TKMHouse;
begin
  try
    Result := HAND_NONE;
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        Result := H.Owner;
    end
    else
      LogIntParamWarn('States.HouseOwner', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns True if the specified house has repair enabled
//* Result: Repair enabled
function TKMScriptStates.HouseRepair(aHouseID: Integer): Boolean;
var
  H: TKMHouse;
begin
  try
    Result := False;
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        Result := H.BuildingRepair;
    end
    else
      LogIntParamWarn('States.HouseRepair', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the amount of the specified resource in the specified house
//* Result: Number of resources or -1 if aHouseID is invalid
function TKMScriptStates.HouseResourceAmount(aHouseID, aResource: Integer): Integer;
var
  H: TKMHouse;
  W: TKMWareType;
begin
  try
    Result := -1; //-1 if house id is invalid
    if (aHouseID > 0) and (aResource in [Low(WARE_ID_TO_TYPE)..High(WARE_ID_TO_TYPE)]) then
    begin
      W := WARE_ID_TO_TYPE[aResource];
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        Result := H.CheckWareIn(W) + H.CheckWareOut(W); //Count both in and out
    end
    else
      LogIntParamWarn('States.HouseResourceAmount', [aHouseID, aResource]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14800
//* Returns the amount of the specified ware in the specified house
//* Result: Number of wares or -1 if aHouseID is invalid
function TKMScriptStates.HouseWareAmount(aHouseID: Integer; aWare: TKMWareType): Integer;
var
  H: TKMHouse;
begin
  try
    Result := -1; //-1 if house id is invalid
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        Result := H.CheckWareIn(aWare) + H.CheckWareOut(aWare); //Count both in and out
    end
    else
      LogParamWarn('States.HouseWareAmount', [aHouseID, GetEnumName(TypeInfo(TKMWareType), Integer(aWare))]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5165
//* Returns the unit type in the specified slot of the school queue.
//* Slot 0 is the unit currently training, slots 1..5 are the queue.
//* QueueIndex: Queue index (0..5)
//* Result: Unit type
//Get the unit type in Schools queue
function TKMScriptStates.HouseSchoolQueue(aHouseID, QueueIndex: Integer): Integer;
var
  H: TKMHouse;
begin
  try
    Result := -1;
    if (aHouseID > 0) and InRange(QueueIndex, 0, 5) then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil) and (H is TKMHouseSchool) then
        Result := UNIT_TYPE_TO_ID[TKMHouseSchool(H).Queue[QueueIndex]];
    end
    else
      LogIntParamWarn('States.HouseSchoolQueue', [aHouseID, QueueIndex]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6510
//* Returns True if specified WIP house area is digged
//* Result: Digged
function TKMScriptStates.HouseSiteIsDigged(aHouseID: Integer): Boolean;
var
  H: TKMHouse;
begin
  try
    Result := False;
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        Result := H.BuildingState <> hbsNoGlyph;
    end
    else
      LogIntParamWarn('States.HouseSiteIsDigged', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns Max amount of gold which is possible to deliver into the TownHall
//* Result: Max gold for specified TownHall
//* or -1 if TownHall house was not found
function TKMScriptStates.HouseTownHallMaxGold(aHouseID: Integer): Integer;
var
  H: TKMHouse;
begin
  try
    Result := -1;
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H is TKMHouseTownHall then
        Result := TKMHouseTownHall(H).GoldMaxCnt;
    end
    else
      LogIntParamWarn('States.HouseTownHallMaxGold', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the type of the specified house
//* Result: House type
function TKMScriptStates.HouseType(aHouseID: Integer): Integer;
var
  H: TKMHouse;
begin
  Result := -1;
  try
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        Result := HOUSE_TYPE_TO_ID[H.HouseType] - 1;
    end
    else
      LogIntParamWarn('States.HouseType', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns the type of the specified house
//* Result: House type
function TKMScriptStates.HouseTypeEx(aHouseID: Integer): TKMHouseType;
var
  H: TKMHouse;
begin
  Result := htNone;
  try
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        Result := H.HouseType;
    end
    else
      LogIntParamWarn('States.HouseTypeEx', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6284
//* Returns max health of the specified house type
//* Result: Max health
function TKMScriptStates.HouseTypeMaxHealth(aHouseType: Integer): Integer;
begin
  try
    Result := 0;
    if HouseTypeValid(aHouseType) then
      Result := gRes.Houses[HOUSE_ID_TO_TYPE[aHouseType]].MaxHealth
    else
      LogIntParamWarn('States.HouseTypeMaxHealth', [aHouseType]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns max health of the specified house type
//* Result: Max health
function TKMScriptStates.HouseTypeMaxHealthEx(aHouseType: TKMHouseType): Integer;
begin
  try
    Result := 0;
    if aHouseType in HOUSES_VALID then
      Result := gRes.Houses[aHouseType].MaxHealth
    else
      LogParamWarn('States.HouseTypeMaxHealthEx', [GetEnumName(TypeInfo(TKMHouseType), Integer(aHouseType))]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6001
//* Returns the the translated name of the specified house type.
//* Note: To ensure multiplayer consistency the name is returned as a number encoded within a markup which is
//* decoded on output, not the actual translated text.
//* Therefore string operations like LowerCase will not work.
//* Result: House type name
function TKMScriptStates.HouseTypeName(aHouseType: Byte): AnsiString;
begin
  try
    if HouseTypeValid(aHouseType) then
      Result := '<%' + AnsiString(IntToStr(gRes.Houses[HOUSE_ID_TO_TYPE[aHouseType]].HouseNameTextID)) + '>'
    else
    begin
      Result := '';
      LogIntParamWarn('States.HouseTypeName', [aHouseType]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns the the translated name of the specified house type.
//* Note: To ensure multiplayer consistency the name is returned as a number encoded within a markup which is
//* decoded on output, not the actual translated text.
//* Therefore string operations like LowerCase will not work.
//* Result: House type name
function TKMScriptStates.HouseTypeNameEx(aHouseType: TKMHouseType): AnsiString;
begin
  try
    if aHouseType in HOUSES_VALID then
      Result := '<%' + AnsiString(IntToStr(gRes.Houses[aHouseType].HouseNameTextID)) + '>'
    else
    begin
      Result := '';
      LogParamWarn('States.HouseTypeNameEx', [GetEnumName(TypeInfo(TKMHouseType), Integer(aHouseType))]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5345
//* Status: Deprecated
//* Replacement: HouseTypeToWorkerType
//* Returns the type of unit that should work in the specified type of house, or -1 if no unit should work in it.
//* Result: Unit type
function TKMScriptStates.HouseTypeToOccupantType(aHouseType: Integer): Integer;
begin
  try
    Result := -1;
    if HouseTypeValid(aHouseType) then
    begin
      Result := UNIT_TYPE_TO_ID[gRes.Houses[HOUSE_ID_TO_TYPE[aHouseType]].WorkerType];
    end
    else
      LogIntParamWarn('States.HouseTypeToOccupantType', [aHouseType]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns the type of unit that should work in the specified type of house, or utNone if no unit should work in it.
//* Result: Unit type
function TKMScriptStates.HouseTypeToWorkerType(aHouseType: TKMHouseType): TKMUnitType;
begin
  Result := utNone;
  try
    if aHouseType in HOUSES_VALID then
      Result := gRes.Houses[aHouseType].WorkerType
    else
      LogParamWarn('States.HouseTypeToWorkerType', [GetEnumName(TypeInfo(TKMHouseType), Integer(aHouseType))]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6220
//* Returns True if the specified player can build the specified house type (unlocked and allowed).
//* Result: House unlocked
function TKMScriptStates.HouseUnlocked(aHand, aHouseType: Integer): Boolean;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled
      and HouseTypeValid(aHouseType) then
      Result := gHands[aHand].Locks.HouseCanBuild(HOUSE_ID_TO_TYPE[aHouseType])
    else
    begin
      Result := False;
      LogIntParamWarn('States.HouseUnlocked', [aHand, aHouseType]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5099
//* Returns True if the specified ware in the specified storehouse or barracks is blocked
//* Result: Ware blocked
function TKMScriptStates.HouseWareBlocked(aHouseID, aWareType: Integer): Boolean;
var
  H: TKMHouse;
  W: TKMWareType;
begin
  try
    Result := False;
    if (aHouseID > 0) and (aWareType in [Low(WARE_ID_TO_TYPE)..High(WARE_ID_TO_TYPE)]) then
    begin
      W := WARE_ID_TO_TYPE[aWareType];
      H := fIDCache.GetHouse(aHouseID);
      if (H is TKMHouseStore) then
        Result := TKMHouseStore(H).NotAcceptFlag[W];
      if (H is TKMHouseBarracks) and (W in [WARFARE_MIN..WARFARE_MAX]) then
        Result := TKMHouseBarracks(H).NotAcceptFlag[W];
    end
    else
      LogIntParamWarn('States.HouseWareBlocked', [aHouseID, aWareType]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns True if the specified ware in the specified storehouse or barracks is blocked
//* Result: Ware blocked
function TKMScriptStates.HouseWareBlockedEx(aHouseID: Integer; aWareType: TKMWareType): Boolean;
var
  H: TKMHouse;
begin
  try
    Result := False;
    if (aHouseID > 0) and (aWareType in WARES_VALID) then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H is TKMHouseStore) then
        Result := TKMHouseStore(H).NotAcceptFlag[aWareType];
      if (H is TKMHouseBarracks) and (aWareType in WARES_WARFARE) then
        Result := TKMHouseBarracks(H).NotAcceptFlag[aWareType];
    end
    else
      LogParamWarn('States.HouseWareBlockedEx', [aHouseID, GetEnumName(TypeInfo(TKMWareType), Integer(aWareType))]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns True if the specified ware in the specified storehouse or barracks is blocked for taking out (yellow triangle)
//* Result: Ware blocked for taking out
function TKMScriptStates.HouseWareBlockedTakeOut(aHouseID: Integer; aWareType: TKMWareType): Boolean;
var
  H: TKMHouse;
begin
  try
    Result := False;
    if (aHouseID > 0) and (aWareType in WARES_VALID) then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H is TKMHouseStore) then
        Result := TKMHouseStore(H).NotAllowTakeOutFlag[aWareType];
      if (H is TKMHouseBarracks) and (aWareType in WARES_WARFARE) then
        Result := TKMHouseBarracks(H).NotAllowTakeOutFlag[aWareType];
    end
    else
      LogParamWarn('States.HouseWareBlockedTakeOut', [aHouseID, GetEnumName(TypeInfo(TKMWareType), Integer(aWareType))]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5165
//* Returns the number of the specified weapon ordered to be produced in the specified house
//* Result: Number of ordered weapons
function TKMScriptStates.HouseWeaponsOrdered(aHouseID, aWareType: Integer): Integer;
var
  I: Integer;
  H: TKMHouse;
  W: TKMWareType;
begin
  try
    Result := 0;
    if (aHouseID > 0) and (aWareType in [Low(WARE_ID_TO_TYPE)..High(WARE_ID_TO_TYPE)]) then
    begin
      W := WARE_ID_TO_TYPE[aWareType];
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil) then
        for I := 1 to 4 do
          if gRes.Houses[H.HouseType].WareOutput[I] = W then
            Exit(H.WareOrder[I]);
    end
    else
      LogIntParamWarn('States.HouseWeaponsOrdered', [aHouseID, aWareType]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns the number of the specified weapon ordered to be produced in the specified house
//* Result: Number of ordered weapons
function TKMScriptStates.HouseWeaponsOrderedEx(aHouseID: Integer; aWareType: TKMWareType): Integer;
var
  I: Integer;
  H: TKMHouse;
begin
  try
    Result := 0;
    if (aHouseID > 0) and (aWareType in WARES_VALID) then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil) then
        for I := 1 to 4 do
          if gRes.Houses[H.HouseType].WareOutput[I] = aWareType then
            Exit(H.WareOrder[I]);
    end
    else
      LogParamWarn('States.HouseWeaponsOrderedEx', [aHouseID, GetEnumName(TypeInfo(TKMWareType), Integer(aWareType))]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5099
//* Returns True if the specified woodcutter's hut is on chop-only mode
//* Result: Chop-only
function TKMScriptStates.HouseWoodcutterChopOnly(aHouseID: Integer): Boolean;
var
  H: TKMHouse;
begin
  try
    Result := False;
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H is TKMHouseWoodcutters then
        Result := TKMHouseWoodcutters(H).WoodcutterMode = wmChop;
    end
    else
      LogIntParamWarn('States.HouseWoodcutterChopOnly', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns woodcutter mode value for the specified woodcutter's hut
//* Result: woodcutter mode as TKMWoodcutterMode = (wmChopAndPlant, wmChop, wmPlant)
function TKMScriptStates.HouseWoodcutterMode(aHouseID: Integer): TKMWoodcutterMode;
var
  H: TKMHouse;
begin
  try
    Result := wmChopAndPlant;
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H is TKMHouseWoodcutters then
        Result := TKMHouseWoodcutters(H).WoodcutterMode;
    end
    else
      LogIntParamWarn('States.HouseWoodcutterMode', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13050
//* Returns ID of a citizen, who works in specified house or -1 if there is no worker or aHouseID is incorrect
function TKMScriptStates.HouseWorker(aHouseID: Integer): Integer;
var
  H: TKMHouse;
begin
  try
    Result := -1;
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H.HasWorker then
        Result := TKMUnit(H.Worker).UID;
    end
    else
      LogIntParamWarn('States.HouseWorker', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5345
//* Returns True if the specified player has a corn field at the specified location.
//* If player index is -1 it will return True if any player has a corn field at the specified tile
//* Result: Is field
function TKMScriptStates.IsFieldAt(aHand: ShortInt; X, Y: Integer): Boolean;
begin
  try
    Result := False;
    //-1 stands for any player
    if InRange(aHand, -1, gHands.Count - 1) and gTerrain.TileInMapCoords(X, Y) then
      Result := gTerrain.TileIsCornField(KMPoint(X,Y))
                and ((aHand = -1) or (gTerrain.Land^[Y, X].TileOwner = aHand))
    else
      LogIntParamWarn('States.IsFieldAt', [aHand, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5345
//* Returns True if the specified player has a road at the specified location.
//* If player index is -1 it will return True if any player has a road at the specified tile
//* Result: Is road
function TKMScriptStates.IsRoadAt(aHand: ShortInt; X, Y: Integer): Boolean;
begin
  try
    Result := False;
    //-1 stands for any player
    if InRange(aHand, -1, gHands.Count - 1) and gTerrain.TileInMapCoords(X, Y) then
      Result := (gTerrain.Land^[Y,X].TileOverlay = toRoad)
                and ((aHand = -1) or (gTerrain.Land^[Y, X].TileOwner = aHand))
    else
      LogIntParamWarn('States.IsRoadAt', [aHand, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5345
//* Returns True if the specified player has a winefield at the specified location.
//* If player index is -1 it will return True if any player has a winefield at the specified tile
//* Result: Is winefield
function TKMScriptStates.IsWinefieldAt(aHand: ShortInt; X, Y: Integer): Boolean;
begin
  try
    Result := False;
    //-1 stands for any player
    if InRange(aHand, -1, gHands.Count - 1) and gTerrain.TileInMapCoords(X, Y) then
      Result := gTerrain.TileIsWineField(KMPoint(X,Y))
                and ((aHand = -1) or (gTerrain.Land^[Y, X].TileOwner = aHand))
    else
      LogIntParamWarn('States.IsWinefieldAt', [aHand, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns True if the specified player has a field plan of the specified type at the specified location.
//* If aHand index is -1 it will return True if any player has plan of the specified type at the specified location.
//* If aFieldType is ftNone it will return if the specified player has a field plan of the any type (ftCorn, ftRoad, ftWine) at the specified location.
//* If aHand index is -1 and aFieldType is ftNone it will return if any player has a field plan of the any type (ftCorn, ftRoad, ftWine) at the specified location.
//* If Plan found then aHand will contain its player id and aFieldType its type
//* Result: Is plan found
function TKMScriptStates.IsPlanAt(var aHand: Integer; var aFieldType: TKMFieldType; X, Y: Integer): Boolean;

  function FindPlan(aHandId, aX, aY: Integer; var aFieldType: TKMFieldType): Boolean;
  var
    FT: TKMFieldType;
  begin
    FT := gHands[aHandId].Constructions.FieldworksList.HasField(KMPoint(aX, aY));
    if aFieldType = ftNone then
    begin
      Result := FT in [ftCorn, ftRoad, ftWine];
      if Result then
        aFieldType := FT;
    end else
      Result := FT = aFieldType;
  end;

var
  I: Integer;
  handFilter, fieldTypeFilter: Boolean;
begin
  try
    Result := False;
    //Verify all input parameters
    if gTerrain.TileInMapCoords(X,Y) then
    begin
      handFilter := InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled;
      fieldTypeFilter := aFieldType in [ftCorn, ftRoad, ftWine];

      if handFilter and fieldTypeFilter then
        Result := FindPlan(aHand, X, Y, aFieldType)
      else
      if handFilter then
      begin
        aFieldType := ftNone;
        Result := FindPlan(aHand, X, Y, aFieldType);
      end else
      begin
        if not fieldTypeFilter then
          aFieldType := ftNone;

        for I := 0 to gHands.Count - 1 do
          if gHands[I].Enabled then
          begin
            Result := FindPlan(I, X, Y, aFieldType);
            if Result then
            begin
              aHand := I;
              Exit;
            end;
          end;
      end
    end
    else
      LogParamWarn('States.IsPlanAt', [aHand, GetEnumName(TypeInfo(TKMFieldType), Integer(aFieldType)), X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns True if the specified player has a field plan (ftCorn) at the specified location.
//* If aHand index is -1 it will return True if any player has field plan at the specified location.
//* If Corn (Field) Plan found then aHand will contain its player id
//* Result: Is field plan found
function TKMScriptStates.IsFieldPlanAt(var aHand: Integer; X, Y: Integer): Boolean;

  function FindPlan(aHandId, aX, aY: Integer): Boolean; inline;
  begin
    Result := gHands[aHandId].Constructions.FieldworksList.HasField(KMPoint(aX, aY)) = ftCorn;
  end;

var
  I: Integer;
begin
  try
    Result := False;
    //Verify all input parameters
    if gTerrain.TileInMapCoords(X,Y) then
    begin
      if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
        Result := FindPlan(aHand, X, Y)
      else
        for I := 0 to gHands.Count - 1 do
          if gHands[I].Enabled then
          begin
            Result := FindPlan(I, X, Y);
            if Result then
            begin
              aHand := I;
              Exit;
            end;
          end;
    end
    else
      LogIntParamWarn('States.IsFieldPlanAt', [aHand, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns True if the specified player has a house plan of the specified type at the specified location.
//* If aHand index is -1 it will return True if any player has house plan of the specified type at the specified location.
//* If aHouseType is htAny it will return if the specified player has a house plan of the any type at the specified location.
//* If aHand index is -1 and aHouseType is htNone it will return if any player has a house plan of the any type at the specified location.
//* If house plan found then after execution aHand will contain its player id and aHouseType its type
//* Result: Is house plan found
function TKMScriptStates.IsHousePlanAt(var aHand: Integer; var aHouseType: TKMHouseType; X, Y: Integer): Boolean;

  function FindPlan(aHandId, aX, aY: Integer; var aHouseType: TKMHouseType): Boolean; inline;
  var
    HT: TKMHouseType;
  begin
    Result := gHands[aHandId].Constructions.HousePlanList.HasPlan(KMPoint(aX, aY), HT);
    if Result then
    begin
      if aHouseType = htAny then
        aHouseType := HT
      else
        Result := aHouseType = HT;
    end;
  end;

var
  I: Integer;
  handFilter, houseTypeFilter: Boolean;
begin
  try
    Result := False;
    //Verify all input parameters
    if gTerrain.TileInMapCoords(X,Y) then
    begin
      handFilter := InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled;
      houseTypeFilter := aHouseType in HOUSES_VALID;

      if handFilter and houseTypeFilter then
        Result := FindPlan(aHand, X, Y, aHouseType)
      else
      if handFilter then
      begin
        aHouseType := htAny;
        Result := FindPlan(aHand, X, Y, aHouseType);
      end else
      begin
        if not houseTypeFilter then
          aHouseType := htAny;

        for I := 0 to gHands.Count - 1 do
          if gHands[I].Enabled then
          begin
            Result := FindPlan(I, X, Y, aHouseType);
            if Result then
            begin
              aHand := I;
              Exit;
            end;
          end;
      end;
    end
    else
      LogParamWarn('States.IsHousePlanAt', [aHand, GetEnumName(TypeInfo(TKMHouseType), Integer(aHouseType)), X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns True if the specified player has a field plan (ftRoad) at the specified location.
//* If aHand index is -1 it will return True if any player has road plan at the specified location.
//* If Road plan found then aHand will contain its player id
//* Result: Is road plan found
function TKMScriptStates.IsRoadPlanAt(var aHand: Integer; X, Y: Integer): Boolean;

  function FindPlan(aHandId, aX, aY: Integer): Boolean; inline;
  begin
    Result := gHands[aHandId].Constructions.FieldworksList.HasField(KMPoint(aX, aY)) = ftRoad;
  end;

var
  I: Integer;
begin
  try
    Result := False;
    //Verify all input parameters
    if gTerrain.TileInMapCoords(X,Y) then
    begin
      if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
        Result := FindPlan(aHand, X, Y)
      else
        for I := 0 to gHands.Count - 1 do
          if gHands[I].Enabled then
          begin
            Result := FindPlan(I, X, Y);
            if Result then
            begin
              aHand := I;
              Exit;
            end;
          end;
    end
    else
      LogIntParamWarn('States.IsRoadPlanAt', [aHand, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns True if the specified player has a field plan (ftWine) at the specified location.
//* If aHand index is -1 it will return True if any player has winefield plan at the specified location.
//* If Winefield Plan found then aHand will contain its player id
//* Result: Is winefield plan found
function TKMScriptStates.IsWinefieldPlanAt(var aHand: Integer; X, Y: Integer): Boolean;

  function FindPlan(aHandId, aX, aY: Integer): Boolean; inline;
  begin
    Result := gHands[aHandId].Constructions.FieldworksList.HasField(KMPoint(aX, aY)) = ftWine;
  end;

var
  I: Integer;
begin
  try
    Result := False;
    //Verify all input parameters
    if gTerrain.TileInMapCoords(X,Y) then
    begin
      if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
        Result := FindPlan(aHand, X, Y)
      else
        for I := 0 to gHands.Count - 1 do
          if gHands[I].Enabled then
          begin
            Result := FindPlan(I, X, Y);
            if Result then
            begin
              aHand := I;
              Exit;
            end;
          end;
    end
    else
      LogIntParamWarn('States.IsWinefieldPlanAt', [aHand, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns if mission is build type
function TKMScriptStates.IsMissionBuildType: Boolean;
begin
  try
    Result := gGameParams.IsNormalMission;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns if mission is fight type
function TKMScriptStates.IsMissionFightType: Boolean;
begin
  try
    Result := gGameParams.IsTactic;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns if mission is cooperative type
function TKMScriptStates.IsMissionCoopType: Boolean;
begin
  try
    Result := gGame.MapTxtInfo.IsCoop;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns if mission is special type
function TKMScriptStates.IsMissionSpecialType: Boolean;
begin
  try
    Result := gGame.MapTxtInfo.IsSpecial;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns if mission is playable as Singleplayer map
function TKMScriptStates.IsMissionPlayableAsSP: Boolean;
begin
  try
    Result := gGame.MapTxtInfo.IsPlayableAsSP;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11230
//* Returns if color selection is locked for current mission
function TKMScriptStates.IsMissionBlockColorSelection: Boolean;
begin
  try
    Result := gGame.MapTxtInfo.BlockColorSelection;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns if team selection is locked for current mission
function TKMScriptStates.IsMissionBlockTeamSelection: Boolean;
begin
  try
    Result := gGame.MapTxtInfo.BlockTeamSelection;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns if peacetime is locked for current mission
function TKMScriptStates.IsMissionBlockPeacetime: Boolean;
begin
  try
    Result := gGame.MapTxtInfo.BlockPeacetime;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns if full map preview is blocked for current mission
function TKMScriptStates.IsMissionBlockFullMapPreview: Boolean;
begin
  try
    Result := gGame.MapTxtInfo.BlockFullMapPreview;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6216
//* Returns a random single (float) such that: 0 <= Number < 1.0
//* Result: Decimal number 0.0 to 1.0
function TKMScriptStates.KaMRandom: Single;
begin
  try
    Result := KM_CommonUtils.KaMRandom({$IFDEF RNG_SPY}'TKMScriptStates.KaMRandom'{$ENDIF});
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6216
//* Returns a random integer Number, such that: 0 <= Number < aMax
//* Result: Number 0 to aMax
function TKMScriptStates.KaMRandomI(aMax: Integer): Integer;
begin
  try
    //No parameters to check, any integer is fine (even negative)
    Result := KM_CommonUtils.KaMRandom(aMax{$IFDEF RNG_SPY}, 'TKMScriptStates.KaMRandomI'{$ENDIF});
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6611
//* Returns the number of player locations available on the map (including AIs),
//* regardless of whether the location was taken in multiplayer (use PlayerEnabled to check if a location is being used)
//* Result: Number of locations
function TKMScriptStates.LocationCount: Integer;
begin
  try
    Result := gHands.Count;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns mission author
function TKMScriptStates.MissionAuthor: UnicodeString;
begin
  try
    Result := gGame.MapTxtInfo.Author;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns mission difficulty for current game
function TKMScriptStates.MissionDifficulty: TKMMissionDifficulty;
begin
  try
    Result := gGameParams.MissionDifficulty;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns allowed mission difficulty levels
function TKMScriptStates.MissionDifficultyLevels: TKMMissionDifficultySet;
begin
  try
    Result := gGame.MapTxtInfo.DifficultyLevels;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11300
//* Returns mission version
function TKMScriptStates.MissionVersion: UnicodeString;
begin
  try
    Result := gGame.MapTxtInfo.Version;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6587
//* Returns the tile type ID of the tile at the specified XY coordinates.
//* Tile IDs can be seen by hovering over the tiles on the terrain tiles tab in the map editor.
//* Result: Tile type (0..597)
function TKMScriptStates.MapTileType(X, Y: Integer): Integer;
begin
  try
    if gTerrain.TileInMapCoords(X, Y) then
      Result := gTerrain.Land^[Y, X].BaseLayer.Terrain
    else
    begin
      Result := -1;
      LogIntParamWarn('States.MapTileType', [X, Y]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6587
//* Returns the rotation of the tile at the specified XY coordinates.
//* Result: Rotation (0..3)
function TKMScriptStates.MapTileRotation(X, Y: Integer): Integer;
begin
  try
    if gTerrain.TileInMapCoords(X, Y) then
      //In KaM map format values can be >= 4. Convert again just in case it was missed by gTerrain
      Result := gTerrain.Land^[Y, X].BaseLayer.Rotation mod 4
    else
    begin
      Result := -1;
      LogIntParamWarn('States.MapTileRotation', [X, Y]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6613
//* Returns the width of the map
//* Result: Width
function TKMScriptStates.MapWidth: Integer;
begin
  try
    Result := gTerrain.MapX;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6613
//* Returns the height of the map
//* Result: Height
function TKMScriptStates.MapHeight: Integer;
begin
  try
    Result := gTerrain.MapY;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6587
//* Returns the height of the terrain at the top left corner (vertex) of the tile at the specified XY coordinates.
//* Result: Height (0..100)
function TKMScriptStates.MapTileHeight(X, Y: Integer): Integer;
begin
  try
    if gTerrain.TileInMapCoords(X, Y) then
      Result := gTerrain.Land^[Y, X].Height
    else
    begin
      Result := -1;
      LogIntParamWarn('States.MapTileHeight', [X, Y]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6587
//* Returns the terrain object ID on the tile at the specified XY coordinates.
//* Object IDs can be seen in the map editor on the objects tab.
//* Object 61 is "block walking".
//* If there is no object on the tile, the result will be 255.
//* Result: Object type (0..255)
function TKMScriptStates.MapTileObject(X, Y: Integer): Integer;
begin
  try
    if gTerrain.TileInMapCoords(X, Y) then
      Result := gTerrain.Land^[Y, X].Obj
    else
    begin
      Result := -1;
      LogIntParamWarn('States.MapTileObject', [X, Y]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000+
//* Returns the terrain overlay on the tile at the specified XY coordinates.
//* Result: tile overlay
function TKMScriptStates.MapTileOverlay(X, Y: Integer): TKMTileOverlay;
begin
  try
    if gTerrain.TileInMapCoords(X, Y) then
      Result := gTerrain.Land^[Y, X].TileOverlay
    else
    begin
      Result := toNone;
      LogIntParamWarn('States.MapTileOverlay', [X, Y]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000+
//* Returns the tile owner at the specified XY coordinates.
//* Result: tile owner ID
function TKMScriptStates.MapTileOwner(X, Y: Integer): Integer;
begin
  try
    if gTerrain.TileInMapCoords(X, Y) then
      Result := gTerrain.Land^[Y, X].TileOwner
    else
    begin
      Result := -1;
      LogIntParamWarn('States.MapTileOwner', [X, Y]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns True if specified tile has requested passability.
//* aPassability: passability index as listed in KM_Defaults (starts from 0)
//* Result: True or False
function TKMScriptStates.MapTilePassability(X, Y: Integer; aPassability: Byte): Boolean;
begin
  try
    if (gTerrain.TileInMapCoords(X, Y))
    and (TKMTerrainPassability(aPassability) in [Low(TKMTerrainPassability)..High(TKMTerrainPassability)]) then
      Result := TKMTerrainPassability(aPassability) in gTerrain.Land^[Y, X].Passability
    else
    begin
      Result := False;
      LogIntParamWarn('States.MapTilePassability', [X, Y, aPassability]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns True if specified tile has requested passability.
//* aPassability: TKMTerrainPassability
//* Result: True or False
function TKMScriptStates.MapTilePassabilityEx(X, Y: Integer; aPassability: TKMTerrainPassability): Boolean;
begin
  try
    if (gTerrain.TileInMapCoords(X, Y)) then
      Result := aPassability in gTerrain.Land^[Y, X].Passability
    else
    begin
      Result := False;
      LogParamWarn('States.MapTilePassabilityEx', [X, Y, GetEnumName(TypeInfo(TKMTerrainPassability), Integer(aPassability))]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Check if tile at XY coordinates has only requested terrain kind. F.e. water, but no transition with shallow or stone.
//* Result: Tile has only requested terrain kind
function TKMScriptStates.MapTileHasOnlyTerrainKind(X, Y: Integer; TerKind: TKMTerrainKind): Boolean;
begin
  try
    if gTerrain.TileInMapCoords(X, Y) then
      Result := gTerrain.TileHasOnlyTerrainKind(X, Y, TerKind)
    else
    begin
      Result := False;
      LogIntParamWarn('States.MapTileHasOnlyTerrainKind', [X, Y]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Check if tile at XY coordinates has only requested terrain kinds. F.e. water and stone, but no dirt
//* Result: Tile has only requested terrain kinds
function TKMScriptStates.MapTileHasOnlyTerrainKinds(X, Y: Integer; TerKinds: array of TKMTerrainKind): Boolean;
begin
  try
    if gTerrain.TileInMapCoords(X, Y) then
      Result := gTerrain.TileHasOnlyTerrainKinds(X, Y, TerKinds)
    else
    begin
      Result := False;
      LogIntParamWarn('States.MapTileHasOnlyTerrainKinds', [X, Y]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Check if tile at XY coordinates has a part of requested terrain kind. F.e. water tile has corner transition with dirt
//* Result: Tile has requested terrain kind part
function TKMScriptStates.MapTileHasTerrainKind(X, Y: Integer; TerKind: TKMTerrainKind): Boolean;
begin
  try
    if gTerrain.TileInMapCoords(X, Y)
      and (TerKind in [Low(TKMTerrainKind)..High(TKMTerrainKind)]) then
      Result := gTerrain.TileHasTerrainKindPart(X, Y, TerKind)
    else
    begin
      Result := False;
      LogIntParamWarn('States.MapTileHasTerrainKind', [X, Y]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Check coal deposit size at the specified XY coordinates.
//* Result: Coal deposit size at X, Y
function TKMScriptStates.MapTileIsCoal(X, Y: Integer): Integer;
begin
  try
    if gTerrain.TileInMapCoords(X, Y) then
      Result := gTerrain.TileIsCoal(X, Y)
    else
    begin
      Result := 0;
      LogIntParamWarn('States.MapTileIsCoal', [X, Y]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Check gold deposit size at the specified XY coordinates.
//* Result: Gold deposit size at X, Y
function TKMScriptStates.MapTileIsGold(X, Y: Integer): Integer;
begin
  try
    if gTerrain.TileInMapCoords(X, Y) then
      Result := gTerrain.TileIsGold(X, Y)
    else
    begin
      Result := 0;
      LogIntParamWarn('States.MapTileIsGold', [X, Y]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Check if tile at the specified XY coordinates has ice
//* Result: Tile has ice
function TKMScriptStates.MapTileIsIce(X, Y: Integer): Boolean;
begin
  try
    if gTerrain.TileInMapCoords(X, Y) then
      Result := gTerrain.TileIsIce(X, Y)
    else
    begin
      Result := False;
      LogIntParamWarn('States.MapTileIsIce', [X, Y]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11750
//* Check if tile at the specified XY coordinates is within map borders (map has specified XY coordinates).
//* F.e. coordinates (150, 200) are invalid for 128x128 map and not within map borders
//* Result: tile is in map coordinates
function TKMScriptStates.MapTileIsInMapCoords(X, Y: Integer): Boolean;
begin
  try
    Result := gTerrain.TileInMapCoords(X, Y);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Check iron deposit size at the specified XY coordinates.
//* Result: Iron deposit size at X, Y
function TKMScriptStates.MapTileIsIron(X, Y: Integer): Integer;
begin
  try
    if gTerrain.TileInMapCoords(X, Y) then
      Result := gTerrain.TileIsIron(X, Y)
    else
    begin
      Result := 0;
      LogIntParamWarn('States.MapTileIsIron', [X, Y]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Check if tile at the specified XY coordinates has sand
//* Result: Tile has sand
function TKMScriptStates.MapTileIsSand(X, Y: Integer): Boolean;
begin
  try
    if gTerrain.TileInMapCoords(X, Y) then
      Result := gTerrain.TileIsSand(KMPoint(X, Y))
    else
    begin
      Result := False;
      LogIntParamWarn('States.MapTileIsSand', [X, Y]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Check if tile at the specified XY coordinates has snow
//* Result: Tile has snow
function TKMScriptStates.MapTileIsSnow(X, Y: Integer): Boolean;
begin
  try
    if gTerrain.TileInMapCoords(X, Y) then
      Result := gTerrain.TileIsSnow(X, Y)
    else
    begin
      Result := False;
      LogIntParamWarn('States.MapTileIsSnow', [X, Y]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Check if tile at the specified XY coordinates has fertile soil (grass, dirt etc terrain good for fields, trees)
//* Result: Tile has soil
function TKMScriptStates.MapTileIsSoil(X, Y: Integer): Boolean;
begin
  try
    if gTerrain.TileInMapCoords(X, Y) then
      Result := gTerrain.TileIsSoil(X, Y)
    else
    begin
      Result := False;
      LogIntParamWarn('States.MapTileIsSoil', [X, Y]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Check stone deposit size at the specified XY coordinates.
//* Result: Stone deposit size at X, Y
function TKMScriptStates.MapTileIsStone(X, Y: Integer): Integer;
begin
  try
    if gTerrain.TileInMapCoords(X, Y) then
      Result := gTerrain.TileIsStone(X, Y) * 3
    else
    begin
      Result := 0;
      LogIntParamWarn('States.MapTileIsStone', [X, Y]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Check if tile at the specified XY coordinates has water.
//* FullTilesOnly: True means we check only water tiles not containing transition with grass/sand/stone etc tiles. False checks any water containing tiles including transitions.
//* Result: Tile has water
function TKMScriptStates.MapTileIsWater(X, Y: Integer; FullTilesOnly: Boolean): Boolean;
begin
  Result := False;
  try
    if gTerrain.TileInMapCoords(X, Y) then
    begin
      if FullTilesOnly then
        Result := gTerrain.TileIsWater(X, Y)
      else
      if not FullTilesOnly then
        Result := gTerrain.TileHasWater(X, Y);
    end
  else
    LogIntParamWarn('States.MapTileIsWater', [X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6287
//* Returns type of FromWare in specified market, or -1 if no ware is selected
//* Result: Ware type
function TKMScriptStates.MarketFromWare(aMarketID: Integer): Integer;
var
  H: TKMHouse;
  resFrom: TKMWareType;
begin
  try
    Result := -1;
    if aMarketID > 0 then
    begin
      H := fIDCache.GetHouse(aMarketID);
      if (H is TKMHouseMarket)
      and (not H.IsDestroyed)
      and (TKMHouseMarket(H).ResFrom <> TKMHouseMarket(H).ResTo)
      and (TKMHouseMarket(H).ResFrom in WARES_VALID)
      and (TKMHouseMarket(H).ResTo in WARES_VALID) then
      begin
        resFrom := TKMHouseMarket(H).ResFrom;
        Result := WARE_TY_TO_ID[resFrom];
      end;
    end
    else
      LogIntParamWarn('States.MarketFromWare', [aMarketID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns type of FromWare in specified market, or wtNone if no ware is selected
//* Result: Ware type
function TKMScriptStates.MarketFromWareEx(aMarketID: Integer): TKMWareType;
var
  H: TKMHouse;
begin
  try
    Result := wtNone;
    if aMarketID > 0 then
    begin
      H := fIDCache.GetHouse(aMarketID);
      if (H is TKMHouseMarket)
        and (not H.IsDestroyed)
        and (TKMHouseMarket(H).ResFrom <> TKMHouseMarket(H).ResTo)
        and (TKMHouseMarket(H).ResFrom in WARES_VALID)
        and (TKMHouseMarket(H).ResTo in WARES_VALID) then
        Result := TKMHouseMarket(H).ResFrom;
    end
    else
      LogIntParamWarn('States.MarketFromWareEx', [aMarketID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6217
//* Returns the factor of resources lost during market trading,
//* used to calculate the TradeRatio (see explanation in MarketValue).
//* This value is constant within one KaM Remake release, but may change in future KaM Remake releases
//* Result: Loss factor
function TKMScriptStates.MarketLossFactor: Single;
begin
  try
    Result := MARKET_TRADEOFF_FACTOR;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6287
//* Returns trade order amount in specified market
//* Result: Order amount
function TKMScriptStates.MarketOrderAmount(aMarketID: Integer): Integer;
var
  H: TKMHouse;
begin
  try
    Result := 0;
    if aMarketID > 0 then
    begin
      H := fIDCache.GetHouse(aMarketID);
      if (H is TKMHouseMarket)
      and (not H.IsDestroyed)
      and (TKMHouseMarket(H).ResFrom <> TKMHouseMarket(H).ResTo)
      and (TKMHouseMarket(H).ResFrom in WARES_VALID)
      and (TKMHouseMarket(H).ResTo in WARES_VALID) then
        Result := TKMHouseMarket(H).WareOrder[0];
    end
    else
      LogIntParamWarn('States.MarketOrderAmount', [aMarketID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6287
//* Returns type of ToWare in specified market, or -1 if no ware is selected
//* Result: Ware type
function TKMScriptStates.MarketToWare(aMarketID: Integer): Integer;
var
  H: TKMHouse;
  resTo: TKMWareType;
begin
  try
    Result := -1;
    if aMarketID > 0 then
    begin
      H := fIDCache.GetHouse(aMarketID);
      if (H is TKMHouseMarket)
      and (not H.IsDestroyed)
      and (TKMHouseMarket(H).ResFrom <> TKMHouseMarket(H).ResTo)
      and (TKMHouseMarket(H).ResFrom in WARES_VALID)
      and (TKMHouseMarket(H).ResTo in WARES_VALID) then
      begin
        resTo := TKMHouseMarket(H).ResTo;
        Result := WARE_TY_TO_ID[resTo];
      end;
    end
    else
      LogIntParamWarn('States.MarketToWare', [aMarketID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns type of ToWare in specified market, or wtNone if no ware is selected
//* Result: Ware type
function TKMScriptStates.MarketToWareEx(aMarketID: Integer): TKMWareType;
var
  H: TKMHouse;
begin
  try
    Result := wtNone;
    if aMarketID > 0 then
    begin
      H := fIDCache.GetHouse(aMarketID);
      if (H is TKMHouseMarket)
      and (not H.IsDestroyed)
      and (TKMHouseMarket(H).ResFrom <> TKMHouseMarket(H).ResTo)
      and (TKMHouseMarket(H).ResFrom in WARES_VALID)
      and (TKMHouseMarket(H).ResTo in WARES_VALID) then
        Result := TKMHouseMarket(H).ResTo;
    end
    else
      LogIntParamWarn('States.MarketToWareEx', [aMarketID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6216
//* Returns the relative market value of the specified resource type,
//* which is a rough indication of the cost to produce that resource.
//* These values are constant within one KaM Remake release, but may change in future KaM Remake releases.
//* The TradeRatio is calculated as: MarketLossFactor * MarketValue(To) / (MarketValue(From).
//* If the TradeRatio is >= 1, then the number of From resources required to receive 1 To resource is: Round(TradeRatio).
//* If the trade ratio is < 1 then the number of To resources received for trading 1 From resource is: Round(1 / TradeRatio)
//* Result: Value
function TKMScriptStates.MarketValue(aRes: Integer): Single;
var
  W: TKMWareType;
begin
  try
    Result := -1; //-1 if ware is invalid
    if aRes in [Low(WARE_ID_TO_TYPE)..High(WARE_ID_TO_TYPE)] then
    begin
      W := WARE_ID_TO_TYPE[aRes];
      Result := gRes.Wares[W].MarketPrice;
    end
    else
      LogIntParamWarn('States.MarketValue', [aRes]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns the relative market value of the specified resource type,
//* which is a rough indication of the cost to produce that resource.
//* These values are constant within one KaM Remake release, but may change in future KaM Remake releases.
//* The TradeRatio is calculated as: MarketLossFactor * MarketValue(To) / (MarketValue(From).
//* If the TradeRatio is >= 1, then the number of From resources required to receive 1 To resource is: Round(TradeRatio).
//* If the trade ratio is < 1 then the number of To resources received for trading 1 From resource is: Round(1 / TradeRatio)
//* Result: Value
function TKMScriptStates.MarketValueEx(aWareType: TKMWareType): Single;
begin
  try
    Result := -1; //-1 if ware is invalid
    if aWareType in WARES_VALID then
      Result := gRes.Wares[aWareType].MarketPrice
    else
      LogParamWarn('States.MarketValueEx', [GetEnumName(TypeInfo(TKMWareType), Integer(aWareType))]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5097
//* Check if a tile is revealed in fog of war for a player
//* Result: Revealed
function TKMScriptStates.FogRevealed(aHand: Byte; aX, aY: Integer): Boolean;
begin
  try
    Result := False;
    if gTerrain.TileInMapCoords(aX,aY)
      and InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      Result := gHands[aHand].FogOfWar.CheckTileRevelation(aX, aY) > 0
    else
      LogIntParamWarn('States.FogRevealed', [aHand, aX, aY]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 12600
//* Return if specified unit is allowed to be selected and viewed by his allies
//* For warriors returns if allies can select their group
function TKMScriptStates.UnitAllowAllyToSelect(aUnitID: Integer): Boolean;
var
  U: TKMUnit;
begin
  try
    Result := False;
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U <> nil then
        Result := U.AllowAllyToSelect;
    end
    else
      LogIntParamWarn('States.UnitAllowAllyToSelect', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the ID of the unit on the specified tile or -1 if no unit exists there
//* Result: Unit ID
function TKMScriptStates.UnitAt(aX, aY: Integer): Integer;
var
  U: TKMUnit;
begin
  try
    Result := UID_NONE;
    if gTerrain.TileInMapCoords(aX,aY) then
    begin
      U := gTerrain.UnitsHitTest(aX, aY);
      if (U <> nil) and not U.IsDeadOrDying then
      begin
        Result := U.UID;
        fIDCache.CacheUnit(U, U.UID); //Improves cache efficiency since U will probably be accessed soon
      end;
    end
    else
      LogIntParamWarn('States.UnitAt', [aX, aY]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns the TKMPoint with coordinates of the specified unit or (-1;-1) point if Unit ID invalid
//* Result: TKMPoint
function TKMScriptStates.UnitPosition(aUnitID: Integer): TKMPoint;
var
  U: TKMUnit;
begin
  try
    Result := KMPOINT_INVALID_TILE; //-1 if unit id is invalid
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U <> nil then
        Result := U.Position;
    end
    else
      LogIntParamWarn('States.UnitPosition', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the X coordinate of the specified unit or -1 if Unit ID invalid
//* Result: X coordinate
function TKMScriptStates.UnitPositionX(aUnitID: Integer): Integer;
var
  U: TKMUnit;
begin
  try
    Result := -1; //-1 if unit id is invalid
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U <> nil then
        Result := U.Position.X;
    end
    else
      LogIntParamWarn('States.UnitPositionX', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the Y coordinate of the specified unit or -1 if Unit ID invalid
//* Result: Y coordinate
function TKMScriptStates.UnitPositionY(aUnitID: Integer): Integer;
var
  U: TKMUnit;
begin
  try
    Result := -1; //-1 if unit id is invalid
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U <> nil then
        Result := U.Position.Y;
    end
    else
      LogIntParamWarn('States.UnitPositionY', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns True if the unit is dead
//* Result: Dead
function TKMScriptStates.UnitDead(aUnitID: Integer): Boolean;
var
  U: TKMUnit;
begin
  try
    Result := True;
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U <> nil then
        Result := U.IsDeadOrDying;
    end
    else
      LogIntParamWarn('States.UnitDead', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the owner of the specified unit or -1 if Unit ID invalid
//* Result: Player ID
function TKMScriptStates.UnitOwner(aUnitID: Integer): Integer;
var
  U: TKMUnit;
begin
  try
    Result := HAND_NONE;
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U <> nil then
        Result := U.Owner;
    end
    else
      LogIntParamWarn('States.UnitOwner', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5165
//* Returns the direction the specified unit is facing
//* Result: Direction (0..7)
function TKMScriptStates.UnitDirection(aUnitID: Integer): Integer;
var
  U: TKMUnit;
begin
  try
    Result := -1;//-1 if unit id is invalid
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U <> nil then
        Result := Byte(U.Direction) - 1;
    end
    else
      LogIntParamWarn('States.UnitDirection', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns the direction the specified unit is facing
//* Result: Direction (dirNA, dirN, dirNE, dirE, dirSE, dirS, dirSW, dirW, dirNW)
function TKMScriptStates.UnitDirectionEx(aUnitID: Integer): TKMDirection;
var
  U: TKMUnit;
begin
  try
    Result := dirNA; //if unit id is invalid
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U <> nil then
        Result := U.Direction;
    end
    else
      LogIntParamWarn('States.UnitDirectionEx', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns the 'Dismissable' status of specified unit
//* Result: is unit dismissable
function TKMScriptStates.UnitDismissable(aUnitID: Integer): Boolean;
var
  U: TKMUnit;
begin
  try
    Result := False;
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U <> nil then
        Result := U.Dismissable;
    end
    else
      LogIntParamWarn('States.UnitDismissable', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 15000
//* Returns number of available fish to catch on the specified fish unit
function TKMScriptStates.UnitFishCount(aUnitID: Integer): Integer;
var
  U: TKMUnit;
begin
  try
    Result := 0;
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if (U <> nil ) and (U is TKMUnitFish) then
        Result := TKMUnitFish(U).FishCount;
    end
    else
      LogIntParamWarn('States.UnitFishCount', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the type of the specified unit or -1 if unit id is invalid
//* Result: Unit type
function TKMScriptStates.UnitType(aUnitID: Integer): Integer;
var
  U: TKMUnit;
begin
  try
    Result := -1; //-1 if unit id is invalid
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U <> nil then
        Result := UNIT_TYPE_TO_ID[U.UnitType];
    end
    else
      LogIntParamWarn('States.UnitType', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns the type of the specified unit or utNone if unit id is invalid
//* Result: Unit type
function TKMScriptStates.UnitTypeEx(aUnitID: Integer): TKMUnitType;
var
  U: TKMUnit;
begin
  try
    Result := utNone; //-1 if unit id is invalid
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U <> nil then
        Result := U.UnitType;
    end
    else
      LogIntParamWarn('States.UnitTypeEx', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6001
//* Returns the the translated name of the specified unit type.
//* Note: To ensure multiplayer consistency the name is returned as a number encoded within a markup
//* which is decoded on output, not the actual translated text.
//* Therefore string operations like LowerCase will not work.
//* Result: Unit type name
function TKMScriptStates.UnitTypeName(aUnitType: Byte): AnsiString;
begin
  try
    if (aUnitType in [Low(UNIT_ID_TO_TYPE) .. High(UNIT_ID_TO_TYPE)]) then
      Result := '<%' + AnsiString(IntToStr(gRes.Units[UNIT_ID_TO_TYPE[aUnitType]].GUITextID)) + '>'
    else
    begin
      Result := '';
      LogIntParamWarn('States.UnitTypeName', [aUnitType]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns the the translated name of the specified unit type.
//* Note: To ensure multiplayer consistency the name is returned as a number encoded within a markup
//* which is decoded on output, not the actual translated text.
//* Therefore string operations like LowerCase will not work.
//* Result: Unit type name
function TKMScriptStates.UnitTypeNameEx(aUnitType: TKMUnitType): AnsiString;
begin
  try
    if (aUnitType in UNITS_VALID) then
      Result := '<%' + AnsiString(IntToStr(gRes.Units[aUnitType].GUITextID)) + '>'
    else
    begin
      Result := '';
      LogParamWarn('States.UnitTypeNameEx', [GetEnumName(TypeInfo(TKMUnitType), Integer(aUnitType))]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6001
//* Returns the the translated name of the specified ware type.
//* Note: To ensure multiplayer consistency the name is returned as a number encoded within a markup
//* which is decoded on output, not the actual translated text.
//* Therefore string operations like LowerCase will not work.
//* Result: Ware type name
function TKMScriptStates.WareTypeName(aWareType: Byte): AnsiString;
begin
  try
    if (aWareType in [Low(WARE_ID_TO_TYPE) .. High(WARE_ID_TO_TYPE)]) then
      Result := '<%' + AnsiString(IntToStr(gRes.Wares[WARE_ID_TO_TYPE[aWareType]].TextID)) + '>'
    else
    begin
      Result := '';
      LogIntParamWarn('States.WareTypeName', [aWareType]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns the the translated name of the specified ware type.
//* Note: To ensure multiplayer consistency the name is returned as a number encoded within a markup
//* which is decoded on output, not the actual translated text.
//* Therefore string operations like LowerCase will not work.
//* Result: Ware type name
function TKMScriptStates.WareTypeNameEx(aWareType: TKMWareType): AnsiString;
begin
  try
    if (aWareType in WARES_VALID) then
      Result := '<%' + AnsiString(IntToStr(gRes.Wares[aWareType].TextID)) + '>'
    else
    begin
      Result := '';
      LogParamWarn('States.WareTypeNameEx', [GetEnumName(TypeInfo(TKMWareType), Integer(aWareType))]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns True if specified warrior is in fight
//* aCountCitizens: including fights with citizens
//* Result: InFight
function TKMScriptStates.WarriorInFight(aUnitID: Integer; aCountCitizens: Boolean): Boolean;
var
  U: TKMUnit;
begin
  try
    Result := False;
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if (U <> nil) and (U is TKMUnitWarrior) then
        Result := TKMUnitWarrior(U).InFight(aCountCitizens);
    end
    else
      LogIntParamWarn('States.WarriorInFight', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns current hitpoints for specified unit or -1 if Unit ID invalid
//* Result: HitPoints
function TKMScriptStates.UnitHPCurrent(aUnitID: Integer): Integer;
var
  U: TKMUnit;
begin
  try
    Result := -1; //-1 if unit id is invalid
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U <> nil then
        Result := U.CurrentHitPoints;
    end
    else
      LogIntParamWarn('States.UnitHPCurrent', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns max hitpoints for specified unit or -1 if Unit ID invalid
//* Result: HitPoints
function TKMScriptStates.UnitHPMax(aUnitID: Integer): Integer;
var
  U: TKMUnit;
begin
  try
    Result := -1; //-1 if unit id is invalid
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U <> nil then
        Result := gRes.Units[U.UnitType].HitPoints;
    end
    else
      LogIntParamWarn('States.UnitHPMax', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* See if unit is invulnerable
//* Result: True or False
function TKMScriptStates.UnitHPInvulnerable(aUnitID: Integer): Boolean;
var
  U: TKMUnit;
begin
  try
    Result := False;
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U <> nil then
        Result := U.HitPointsInvulnerable;
    end
    else
      LogIntParamWarn('States.UnitHPInvulnerable', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the hunger level of the specified unit as number of ticks until death or -1 if Unit ID invalid
//* Result: Hunger level
function TKMScriptStates.UnitHunger(aUnitID: Integer): Integer;
var
  U: TKMUnit;
begin
  try
    Result := -1; //-1 if unit id is invalid
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U <> nil then
        Result := Max(U.Condition, 0)*CONDITION_PACE;
    end
    else
      LogIntParamWarn('States.UnitHunger', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the ware a serf is carrying, or -1 if the unit is not a serf or is not carrying anything
//* Result: Ware type
function TKMScriptStates.UnitCarrying(aUnitID: Integer): Integer;
var
  U: TKMUnit;
begin
  try
    Result := -1; //-1 if unit id is invalid
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if (U <> nil) and (U is TKMUnitSerf) and (TKMUnitSerf(U).Carry in [WARE_MIN..WARE_MAX]) then
        Result := WARE_TY_TO_ID[TKMUnitSerf(U).Carry];
    end
    else
      LogIntParamWarn('States.UnitCarrying', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns the ware a serf is carrying, or wtNone if the unit is not a serf or is not carrying anything
//* Result: Ware type
function TKMScriptStates.UnitCarryingEx(aUnitID: Integer): TKMWareType;
var
  U: TKMUnit;
begin
  try
    Result := wtNone; //-1 if unit id is invalid
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if (U <> nil) and (U is TKMUnitSerf) and (TKMUnitSerf(U).Carry in WARES_VALID) then
        Result := TKMUnitSerf(U).Carry;
    end
    else
      LogIntParamWarn('States.UnitCarryingEx', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5997
//* Returns the ID of the house which is the home of the specified unit (house where he works) or -1 if the unit does not have a home
//* Result: House ID
function TKMScriptStates.UnitHome(aUnitID: Integer): Integer;
var
  U: TKMUnit;
  H: TKMHouse;
begin
  try
    Result := -1;
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if (U <> nil) then
      begin
        H := U.Home;
        if (H <> nil) and not H.IsDestroyed then
        begin
          Result := H.UID;
          fIDCache.CacheHouse(H, H.UID); //Improves cache efficiency since H will probably be accessed soon
        end;
      end;
    end
    else
      LogIntParamWarn('States.UnitHome', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6523
//* Returns True if specified unit is idle (has no orders/action)
//* Result: Idle
function TKMScriptStates.UnitIdle(aUnitID: Integer): Boolean;
var
  U: TKMUnit;
begin
  try
    Result := False;
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if (U <> nil) then
        Result := U.IsIdle;
    end
    else
      LogIntParamWarn('States.UnitIdle', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 12982
//* Returns HouseID where specified Unit is now, at this particular moment, or -1 if Unit not found or Unit is not in any house
//* Result: HouseId, where unit is placed
function TKMScriptStates.UnitInHouse(aUnitID: Integer): Integer;
var
  U: TKMUnit;
begin
  try
    Result := -1;
    if (aUnitID > 0) then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U.InHouse <> nil then
        Result := U.InHouse.UID;
    end
    else
      LogIntParamWarn('States.UnitInHouse', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Gives the maximum hunger level a unit can have in ticks until death
//* Result: Hunger in ticks
function TKMScriptStates.UnitMaxHunger: Integer;
begin
  try
    Result := UNIT_MAX_CONDITION*CONDITION_PACE;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Gives the hunger level when a unit will try to eat in ticks until death
//* Result: Hunger in ticks
function TKMScriptStates.UnitLowHunger: Integer;
begin
  try
    Result := UNIT_MIN_CONDITION*CONDITION_PACE;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 12600
//* Return if specified group is allowed to be selected and viewed by his allies
function TKMScriptStates.GroupAllowAllyToSelect(aGroupID: Integer): Boolean;
var
  G: TKMUnitGroup;
begin
  try
    Result := False;
    if aGroupID > 0 then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if G <> nil then
        Result := G.AllowAllyToSelect;
    end
    else
      LogIntParamWarn('States.GroupAllowAllyToSelect', [aGroupID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns True if target Group is assigned to the Defence Position at coordinates X, Y
//* if X = -1, or Y = -1, then those coordinates does not used to filter defence position
//* Result: Group assigned to Defence position
function TKMScriptStates.GroupAssignedToDefencePosition(aGroupID, X, Y: Integer): Boolean;
var
  G: TKMUnitGroup;
  DP: TAIDefencePosition;
  DPNewAI: TKMDefencePosition;
begin
  try
    Result := False;
    if aGroupID > 0 then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if G <> nil then
      begin
        if gHands[G.Owner].AI.Setup.NewAI then
        begin
          DPNewAI := gHands[G.Owner].AI.ArmyManagement.Defence.FindPositionOf(G);
          if DPNewAI <> nil then
            Result := ((DPNewAI.Position.Loc.X = X) or (X = -1)) and ((DPNewAI.Position.Loc.Y = Y) or (Y = -1));
        end
        else
        begin
          DP := gHands[G.Owner].AI.General.DefencePositions.FindPositionOf(G);
          if DP <> nil then
            Result := ((DP.Position.Loc.X = X) or (X = -1)) and ((DP.Position.Loc.Y = Y) or (Y = -1));
        end;
      end;
    end
    else
      LogIntParamWarn('States.GroupAssignedToDefencePosition', [aGroupID, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the ID of the group of the unit on the specified tile or -1 if no group exists there
//* Result: Group ID
function TKMScriptStates.GroupAt(aX, aY: Integer): Integer;
var
  G: TKMUnitGroup;
begin
  try
    G := gHands.GroupsHitTest(aX, aY);
    if (G <> nil) and not G.IsDead then
    begin
      Result := G.UID;
      fIDCache.CacheGroup(G, G.UID); //Improves cache efficiency since G will probably be accessed soon
    end
    else
      Result := UID_NONE;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the group that the specified unit (warrior) belongs to or -1 if it does not belong to a group
//* Result: Group ID
function TKMScriptStates.UnitsGroup(aUnitID: Integer): Integer;
var
  U: TKMUnit;
  G: TKMUnitGroup;
begin
  try
    Result := UID_NONE;
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if (U <> nil) and (U is TKMUnitWarrior) then
      begin
        G := gHands[U.Owner].UnitGroups.GetGroupByMember(TKMUnitWarrior(U));
        if G <> nil then
        begin
          Result := G.UID;
          fIDCache.CacheGroup(G, G.UID); //Improves cache efficiency since G will probably be accessed soon
        end;
      end;
    end
    else
      LogIntParamWarn('States.UnitsGroup', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns True if the group is dead (all members dead or joined other groups)
//* Result: Dead
function TKMScriptStates.GroupDead(aGroupID: Integer): Boolean;
var
  G: TKMUnitGroup;
begin
  try
    Result := True;
    if aGroupID > 0 then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if G <> nil then
        Result := G.IsDead;
    end
    else
      LogIntParamWarn('States.GroupDead', [aGroupID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6523
//* Returns True if specified group is idle (has no orders/action)
//* Result: Idle
function TKMScriptStates.GroupIdle(aGroupID: Integer): Boolean;
var
  G: TKMUnitGroup;
begin
  try
    Result := False;
    if aGroupID > 0 then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if G <> nil then
        Result := G.Order = goNone;
    end
    else
      LogIntParamWarn('States.GroupIdle', [aGroupID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns True if specified group is in fight
//* aCountCitizens: including fights with citizens
//* Result: InFight
function TKMScriptStates.GroupInFight(aGroupID: Integer; aCountCitizens: Boolean): Boolean;
var
  G: TKMUnitGroup;
begin
  try
    Result := False;
    if aGroupID > 0 then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if G <> nil then
        Result := G.InFight(aCountCitizens);
    end
    else
      LogIntParamWarn('States.GroupInFight', [aGroupID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the owner of the specified group or -1 if Group ID invalid
//* Result: Player ID
function TKMScriptStates.GroupOwner(aGroupID: Integer): Integer;
var
  G: TKMUnitGroup;
begin
  try
    Result := HAND_NONE;
    if aGroupID > 0 then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if G <> nil then
        Result := G.Owner;
    end
    else
      LogIntParamWarn('States.GroupOwner', [aGroupID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5932
//* Returns the type of the specified group or -1 if Group ID invalid
//* Result: Group type, values are 0 - melee, 1 - antiHorse, 2 - ranged, 3 - mounted
function TKMScriptStates.GroupType(aGroupID: Integer): Integer;
var
  G: TKMUnitGroup;
begin
  Result := -1;
  try
    if aGroupID > 0 then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if G <> nil then
        Result := Byte(G.GroupType) - GROUP_TYPE_MIN_OFF;
    end
    else
      LogIntParamWarn('States.GroupType', [aGroupID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Returns the type of the specified group or gtNone if Group ID invalid
//* Result: Group type
function TKMScriptStates.GroupTypeEx(aGroupID: Integer): TKMGroupType;
var
  G: TKMUnitGroup;
begin
  Result := gtNone;
  try
    if aGroupID > 0 then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if G <> nil then
        Result := G.GroupType;
    end
    else
      LogIntParamWarn('States.GroupTypeEx', [aGroupID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11200
//* Returns the manual formation parameter of the specified group (False for new group, True if player changed formation manually at least once)
//* Result: manual formation
function TKMScriptStates.GroupManualFormation(aGroupID: Integer): Boolean;
var
  G: TKMUnitGroup;
begin
  try
    Result := False;
    if aGroupID > 0 then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if G <> nil then
        Result := G.ManualFormation;
    end
    else
      LogIntParamWarn('States.GroupManualFormation', [aGroupID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the total number of members of the specified group
//* Result: Member count
function TKMScriptStates.GroupMemberCount(aGroupID: Integer): Integer;
var
  G: TKMUnitGroup;
begin
  try
    Result := 0;
    if aGroupID > 0 then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if G <> nil then
        Result := G.Count;
    end
    else
      LogIntParamWarn('States.GroupMemberCount', [aGroupID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns current order of the specified group
//* Result: TKMGroupOrder
function TKMScriptStates.GroupOrder(aGroupID: Integer): TKMGroupOrder;
var
  G: TKMUnitGroup;
begin
  try
    Result := goNone;
    if aGroupID > 0 then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if G <> nil then
        Result := G.Order;
    end
    else
      LogIntParamWarn('States.GroupOrder', [aGroupID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5272
//* Returns the number of columns (units per row) of the specified group
//* Result: Column count
function TKMScriptStates.GroupColumnCount(aGroupID: Integer): Integer;
var
  G: TKMUnitGroup;
begin
  try
    Result := 0;
    if aGroupID > 0 then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if G <> nil then
        Result := G.UnitsPerRow;
    end
    else
      LogIntParamWarn('States.GroupColumnCount', [aGroupID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the unit ID of the specified group member.
//* Member 0 will be the flag holder, 1...GroupMemberCount-1 will be the other members
//* (0 <= MemberIndex <= GroupMemberCount-1)
//* Result: Unit ID
function TKMScriptStates.GroupMember(aGroupID, aMemberIndex: Integer): Integer;
var
  G: TKMUnitGroup;
begin
  try
    Result := UID_NONE;
    if aGroupID > 0 then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if G <> nil then
      begin
        if InRange(aMemberIndex, 0, G.Count-1) then
        begin
          Result := G.Members[aMemberIndex].UID;
          //Improves cache efficiency since unit will probably be accessed soon
          fIDCache.CacheUnit(G.Members[aMemberIndex], Result);
        end
        else
          LogIntParamWarn('States.GroupMember', [aGroupID, aMemberIndex]);
      end;
    end
    else
      LogIntParamWarn('States.GroupMember', [aGroupID, aMemberIndex]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


end.
