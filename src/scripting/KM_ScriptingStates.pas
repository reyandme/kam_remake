unit KM_ScriptingStates;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, SysUtils, StrUtils, uPSRuntime,
  KM_CommonTypes, KM_Defaults, KM_Points, KM_HandsCollection, KM_Houses, KM_ScriptingIdCache, KM_Units, KM_MapTypes,
  KM_UnitGroup, KM_ResHouses, KM_HouseCollection, KM_ResWares, KM_ScriptingEvents;


type
  TKMScriptStates = class(TKMScriptEntity)
  public
    function AIAutoAttackRange(aPlayer: Byte): Integer;
    function AIAutoBuild(aPlayer: Byte): Boolean;
    function AIAutoDefence(aPlayer: Byte): Boolean;
    function AIAutoRepair(aPlayer: Byte): Boolean;
    function AIDefendAllies(aPlayer: Byte): Boolean;
    function AIEquipRate(aPlayer: Byte; aType: Byte): Integer;
    procedure AIGroupsFormationGet(aPlayer, aType: Byte; out aCount, aColumns: Integer);
    function AIRecruitDelay(aPlayer: Byte): Integer;
    function AIRecruitLimit(aPlayer: Byte): Integer;
    function AISerfsPerHouse(aPlayer: Byte): Single;
    function AISoldiersLimit(aPlayer: Byte): Integer;
    function AIStartPosition(aPlayer: Byte): TKMPoint;
    function AIWorkerLimit(aPlayer: Byte): Integer;

    function ClosestGroup(aPlayer, X, Y, aGroupType: Integer): Integer;
    function ClosestGroupMultipleTypes(aPlayer, X, Y: Integer; aGroupTypes: TByteSet): Integer;
    function ClosestHouse(aPlayer, X, Y, aHouseType: Integer): Integer;
    function ClosestHouseMultipleTypes(aPlayer, X, Y: Integer; aHouseTypes: TByteSet): Integer;
    function ClosestUnit(aPlayer, X, Y, aUnitType: Integer): Integer;
    function ClosestUnitMultipleTypes(aPlayer, X, Y: Integer; aUnitTypes: TByteSet): Integer;

    function ConnectedByRoad(X1, Y1, X2, Y2: Integer): Boolean;
    function ConnectedByWalking(X1, Y1, X2, Y2: Integer): Boolean;

    function FogRevealed(aPlayer: Byte; aX, aY: Word): Boolean;

    function GameTime: Cardinal;

    function GroupAssignedToDefencePosition(aGroupID, X, Y: Integer): Boolean;
    function GroupAt(aX, aY: Word): Integer;
    function GroupColumnCount(aGroupID: Integer): Integer;
    function GroupDead(aGroupID: Integer): Boolean;
    function GroupIdle(aGroupID: Integer): Boolean;
    function GroupMember(aGroupID, aMemberIndex: Integer): Integer;
    function GroupMemberCount(aGroupID: Integer): Integer;
    function GroupOrder(aGroupID: Integer): TKMGroupOrder;
    function GroupOwner(aGroupID: Integer): Integer;
    function GroupType(aGroupID: Integer): Integer;

    function HouseAt(aX, aY: Word): Integer;
    function HouseBarracksRallyPointX(aBarracks: Integer): Integer;
    function HouseBarracksRallyPointY(aBarracks: Integer): Integer;
    function HouseBuildingProgress(aHouseID: Integer): Word;
    function HouseCanReachResources(aHouseID: Integer): Boolean;
    function HouseDamage(aHouseID: Integer): Integer;
    function HouseDeliveryBlocked(aHouseID: Integer): Boolean;
    function HouseDeliveryMode(aHouseID: Integer): Integer;
    function HouseDestroyed(aHouseID: Integer): Boolean;
    function HouseHasOccupant(aHouseID: Integer): Boolean;
    function HouseFlagPoint(aHouseID: Integer): TKMPoint;
    function HouseIsComplete(aHouseID: Integer): Boolean;
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
    function HouseTypeMaxHealth(aHouseType: Integer): Word;
    function HouseTypeName(aHouseType: Byte): AnsiString;
    function HouseTypeToOccupantType(aHouseType: Integer): Integer;
    function HouseUnlocked(aPlayer, aHouseType: Word): Boolean;
    function HouseWareBlocked(aHouseID, aWareType: Integer): Boolean;
    function HouseWeaponsOrdered(aHouseID, aWareType: Integer): Integer;
    function HouseWoodcutterChopOnly(aHouseID: Integer): Boolean;
    function HouseWoodcutterMode(aHouseID: Integer): Integer;

    function IsFieldAt(aPlayer: ShortInt; X, Y: Word): Boolean;
    function IsWinefieldAt(aPlayer: ShortInt; X, Y: Word): Boolean;
    function IsRoadAt(aPlayer: ShortInt; X, Y: Word): Boolean;

    function IsPlanAt(var aPlayer: Integer; var aFieldType: TKMFieldType; X, Y: Word): Boolean;
    function IsFieldPlanAt(var aPlayer: Integer; X, Y: Word): Boolean;
    function IsHousePlanAt(var aPlayer: Integer; var aHouseType: TKMHouseType; X, Y: Word): Boolean;
    function IsRoadPlanAt(var aPlayer: Integer; X, Y: Word): Boolean;
    function IsWinefieldPlanAt(var aPlayer: Integer; X, Y: Word): Boolean;

    function IsMissionBuildType: Boolean;
    function IsMissionFightType: Boolean;
    function IsMissionCoopType: Boolean;
    function IsMissionSpecialType: Boolean;
    function IsMissionPlayableAsSP: Boolean;
    function IsMissionBlockTeamSelection: Boolean;
    function IsMissionBlockPeacetime: Boolean;
    function IsMissionBlockFullMapPreview: Boolean;

    function KaMRandom: Single;
    function KaMRandomI(aMax: Integer): Integer;
    function LocationCount: Integer;

    function MapTileType(X, Y: Integer): Integer;
    function MapTileRotation(X, Y: Integer): Integer;
    function MapTileHeight(X, Y: Integer): Integer;
    function MapTileObject(X, Y: Integer): Integer;
    function MapTilePassability(X, Y: Integer; aPassability: Byte): Boolean;
    function MapWidth: Integer;
    function MapHeight: Integer;

    function MissionAuthor: UnicodeString;
    function MissionBigDesc: UnicodeString;
    function MissionBigDescLibx: Integer;
    function MissionSmallDesc: UnicodeString;
    function MissionSmallDescLibx: Integer;

    function MissionDifficulty: TKMMissionDifficulty;
    function MissionDifficultyLevels: TKMMissionDifficultySet;

    function MarketFromWare(aMarketID: Integer): Integer;
    function MarketLossFactor: Single;
    function MarketOrderAmount(aMarketID: Integer): Integer;
    function MarketToWare(aMarketID: Integer): Integer;
    function MarketValue(aRes: Integer): Single;
    function PeaceTime: Cardinal;

    function PlayerAllianceCheck(aPlayer1, aPlayer2: Byte): Boolean;
    function PlayerColorText(aPlayer: Byte): AnsiString;
    function PlayerDefeated(aPlayer: Byte): Boolean;
    function PlayerEnabled(aPlayer: Byte): Boolean;
    function PlayerGetAllUnits(aPlayer: Byte): TIntegerArray;
    function PlayerGetAllHouses(aPlayer: Byte): TIntegerArray;
    function PlayerGetAllGroups(aPlayer: Byte): TIntegerArray;
    function PlayerIsAI(aPlayer: Byte): Boolean;
    function PlayerName(aPlayer: Byte): AnsiString;
    function PlayerVictorious(aPlayer: Byte): Boolean;
    function PlayerWareDistribution(aPlayer, aWareType, aHouseType: Byte): Byte;

    function StatAIDefencePositionsCount(aPlayer: Byte): Integer;
    function StatArmyCount(aPlayer: Byte): Integer;
    function StatCitizenCount(aPlayer: Byte): Integer;
    function StatHouseMultipleTypesCount(aPlayer: Byte; aTypes: TByteSet): Integer;
    function StatHouseTypeCount(aPlayer, aHouseType: Byte): Integer;
    function StatHouseTypePlansCount(aPlayer, aHouseType: Byte): Integer;
    function StatPlayerCount: Integer;
    function StatResourceProducedCount(aPlayer, aResType: Byte): Integer;
    function StatResourceProducedMultipleTypesCount(aPlayer: Byte; aTypes: TByteSet): Integer;
    function StatUnitCount(aPlayer: Byte): Integer;
    function StatUnitKilledCount(aPlayer, aUnitType: Byte): Integer;
    function StatUnitKilledMultipleTypesCount(aPlayer: Byte; aTypes: TByteSet): Integer;
    function StatUnitLostCount(aPlayer, aUnitType: Byte): Integer;
    function StatUnitLostMultipleTypesCount(aPlayer: Byte; aTypes: TByteSet): Integer;
    function StatUnitMultipleTypesCount(aPlayer: Byte; aTypes: TByteSet): Integer;
    function StatUnitTypeCount(aPlayer, aUnitType: Byte): Integer;

    function UnitAt(aX, aY: Word): Integer;
    function UnitCarrying(aUnitID: Integer): Integer;
    function UnitDead(aUnitID: Integer): Boolean;
    function UnitDirection(aUnitID: Integer): Integer;
    function UnitDismissable(aUnitID: Integer): Boolean;
    function UnitHome(aUnitID: Integer): Integer;
    function UnitHPCurrent(aUnitID: Integer): Integer;
    function UnitHPMax(aUnitID: Integer): Integer;
    function UnitHPInvulnerable(aUnitID: Integer): Boolean;
    function UnitHunger(aUnitID: Integer): Integer;
    function UnitIdle(aUnitID: Integer): Boolean;
    function UnitLowHunger: Integer;
    function UnitMaxHunger: Integer;
    function UnitOwner(aUnitID: Integer): Integer;
    function UnitPosition(aUnitID: Integer): TKMPoint;
    function UnitPositionX(aUnitID: Integer): Integer;
    function UnitPositionY(aUnitID: Integer): Integer;
    function UnitsGroup(aUnitID: Integer): Integer;
    function UnitType(aUnitID: Integer): Integer;
    function UnitTypeName(aUnitType: Byte): AnsiString;
    function WareTypeName(aWareType: Byte): AnsiString;
  end;


implementation
uses
  KM_AI, KM_Terrain, KM_Game, KM_FogOfWar, KM_UnitWarrior,
  KM_HouseBarracks, KM_HouseSchool, KM_ResUnits, KM_Log, KM_CommonUtils, KM_HouseMarket,
  KM_Resource, KM_UnitTaskSelfTrain, KM_Sound, KM_Hand, KM_AIDefensePos, KM_CommonClasses,
  KM_UnitsCollection, KM_PathFindingRoad, KM_HouseWoodcutters, KM_HouseTownHall,
  KM_ArmyDefence;


  //We need to check all input parameters as could be wildly off range due to
  //mistakes in scripts. In that case we have two options:
  // - skip silently and log
  // - report to player


function HouseTypeValid(aHouseType: Integer): Boolean; inline;
begin
  Result := (aHouseType in [Low(HouseIndexToType)..High(HouseIndexToType)])
            and (HouseIndexToType[aHouseType] <> htNone); //KaM index 26 is unused (htNone)
end;


{ TKMScriptStates }

//* Version: 7000+
//* Gets AI auto attack range.
//* Returns -1 if used with wrong parameters
function TKMScriptStates.AIAutoAttackRange(aPlayer: Byte): Integer;
begin
  Result := -1;
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      Result := gHands[aPlayer].AI.Setup.AutoAttackRange
    else
      LogParamWarning('States.AIAutoAttackRange', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Gets whether the AI should build and manage his own village
//* Returns False if used with wrong parameters
function TKMScriptStates.AIAutoBuild(aPlayer: Byte): Boolean;
begin
  Result := False;
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      Result := gHands[aPlayer].AI.Setup.AutoBuild
    else
      LogParamWarning('States.AIAutoBuild', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Gets whether the AI should position his soldiers automatically
//* Returns False if used with wrong parameters
function TKMScriptStates.AIAutoDefence(aPlayer: Byte): Boolean;
begin
  Result := False;
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      Result := gHands[aPlayer].AI.Setup.AutoDefend
    else
      LogParamWarning('States.AIAutoDefence', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Gets whether the AI should automatically repair damaged buildings
//* Returns False if used with wrong parameters
function TKMScriptStates.AIAutoRepair(aPlayer: Byte): Boolean;
begin
  Result := False;
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      Result := gHands[aPlayer].AI.Setup.AutoRepair
    else
      LogParamWarning('States.AIAutoRepair', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Gets whether AI should defend units and houses of allies as if they were its own
//* Returns False if used with wrong parameters
function TKMScriptStates.AIDefendAllies(aPlayer: Byte): Boolean;
begin
  Result := False;
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      Result := gHands[aPlayer].AI.Setup.DefendAllies
    else
      LogParamWarning('States.AIDefendAllies', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Gets the warriors equip rate for AI.
//* aType: type: 0 - leather, 1 - iron
//* Returns -1 if used with wrong parameters
function TKMScriptStates.AIEquipRate(aPlayer: Byte; aType: Byte): Integer;
begin
  Result := -1;
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
    begin
      case aType of
        0:    Result := gHands[aPlayer].AI.Setup.EquipRateLeather;
        1:    Result := gHands[aPlayer].AI.Setup.EquipRateIron;
        else  LogParamWarning('States.AIEquipRate, unknown type', [aPlayer, aType]);
      end;
    end else
      LogParamWarning('States.AIEquipRate', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Gets the formation the AI uses for defence positions for specified player and group type
//* GroupType: 0 = Melee, 1 = AntiHorse, 2 = Ranged, 3 = Mounted
//* group count and columns are returned in aCount and aColumns variables
procedure TKMScriptStates.AIGroupsFormationGet(aPlayer, aType: Byte; out aCount, aColumns: Integer);
var
  gt: TKMGroupType;
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
      and InRange(aType, 0, 3) then
    begin
      gt := TKMGroupType(aType);
      if gHands[aPlayer].AI.Setup.NewAI then
      begin
        aCount := gHands[aPlayer].AI.ArmyManagement.Defence.TroopFormations[gt].NumUnits;
        aColumns := gHands[aPlayer].AI.ArmyManagement.Defence.TroopFormations[gt].UnitsPerRow;
      end
      else
      begin;
        aCount := gHands[aPlayer].AI.General.DefencePositions.TroopFormations[gt].NumUnits;
        aColumns := gHands[aPlayer].AI.General.DefencePositions.TroopFormations[gt].UnitsPerRow;
      end
    end
    else
      LogParamWarning('Actions.AIGroupsFormationGet', [aPlayer, aType]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Gets the number of ticks before the specified AI will start training recruits
//* Returns -1 if used with wrong parameters
function TKMScriptStates.AIRecruitDelay(aPlayer: Byte): Integer;
begin
  Result := -1;
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      Result := gHands[aPlayer].AI.Setup.RecruitDelay
    else
      LogParamWarning('States.AIRecruitDelay', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Gets the number of recruits the AI will keep in each barracks
//* Returns -1 if used with wrong parameters
function TKMScriptStates.AIRecruitLimit(aPlayer: Byte): Integer;
begin
  Result := -1;
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      Result := gHands[aPlayer].AI.Setup.RecruitCount
    else
      LogParamWarning('States.AIRecruitLimit', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Gets the number of serfs the AI will train per house.
//* Can be a decimal (0.25 for 1 serf per 4 houses)
//* Returns -1 if used with wrong parameters
function TKMScriptStates.AISerfsPerHouse(aPlayer: Byte): Single;
begin
  Result := -1;
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      Result := gHands[aPlayer].AI.Setup.SerfsPerHouse
    else
      LogParamWarning('States.AISerfsPerHouse', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Gets the maximum number of soldiers the AI will train, or -1 for unlimited
//* Returns -2 if used with wrong parameters
function TKMScriptStates.AISoldiersLimit(aPlayer: Byte): Integer;
begin
  Result := -2; // use -2 here, as -1 is used for unlimited
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      Result := gHands[aPlayer].AI.Setup.MaxSoldiers
    else
      LogParamWarning('States.AISoldiersLimit', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Gets the AI start position which is used for targeting AI attacks
//* Returns (-1;-1) if used with wrong parameters
function TKMScriptStates.AIStartPosition(aPlayer: Byte): TKMPoint;
begin
  Result := KMPOINT_INVALID_TILE;
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      Result := gHands[aPlayer].AI.Setup.StartPosition
    else
      LogParamWarning('States.AIStartPosition', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Gets the maximum number of laborers the AI will train
//* Returns -1 if used with wrong parameters
function TKMScriptStates.AIWorkerLimit(aPlayer: Byte): Integer;
begin
  Result := -1;
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      Result := gHands[aPlayer].AI.Setup.WorkerCount
    else
      LogParamWarning('States.AIWorkerLimit', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6216
//* Returns the group of the specified player and group type that is closest to the specified coordinates,
//* or -1 if no such group was found.
//* If the group type is -1 any group type will be accepted
//* Result: Group ID
function TKMScriptStates.ClosestGroup(aPlayer, X, Y, aGroupType: Integer): Integer;
var
  GTS: TKMGroupTypeSet;
  G: TKMUnitGroup;
begin
  try
    Result := -1;
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and gTerrain.TileInMapCoords(X, Y)
    and ((aGroupType = -1) or (aGroupType in [Byte(Low(TKMGroupType))..Byte(High(TKMGroupType))])) then
    begin
      if aGroupType = -1 then
        GTS := [Low(TKMGroupType)..High(TKMGroupType)]
      else
        GTS := [TKMGroupType(aGroupType)];

      G := gHands[aPlayer].UnitGroups.GetClosestGroup(KMPoint(X,Y), GTS);
      if (G <> nil) and not G.IsDead then
      begin
        Result := G.UID;
        fIDCache.CacheGroup(G, G.UID);
      end;
    end
    else
      LogParamWarning('States.ClosestGroup', [aPlayer, X, Y, aGroupType]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6216
//* Returns the group of the specified player and group types that is closest to the specified coordinates,
//* or -1 if no such group was found.
//* The group types is a "set of Byte", for example [1,3]
//* aGroupTypes: Set of group types
//* Result: Group ID
function TKMScriptStates.ClosestGroupMultipleTypes(aPlayer, X, Y: Integer; aGroupTypes: TByteSet): Integer;
var
  B: Byte;
  GTS: TKMGroupTypeSet;
  G: TKMUnitGroup;
begin
  try
    Result := -1;
    GTS := [];
    for B in [Byte(Low(TKMGroupType))..Byte(High(TKMGroupType))] do
      if B in aGroupTypes then
        GTS := GTS + [TKMGroupType(B)];

    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and gTerrain.TileInMapCoords(X, Y) then
    begin
      G := gHands[aPlayer].UnitGroups.GetClosestGroup(KMPoint(X,Y), GTS);
      if G <> nil then
      begin
        Result := G.UID;
        fIDCache.CacheGroup(G, G.UID);
      end;
    end
    else
      LogParamWarning('States.ClosestGroupMultipleTypes', [aPlayer, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6216
//* Returns the house of the specified player and house type that is closest to the specified coordinates,
//* or -1 if no such house was found.
//* If the house type is -1 any house type will be accepted
//* Result: House ID
function TKMScriptStates.ClosestHouse(aPlayer, X, Y, aHouseType: Integer): Integer;
var
  HTS: THouseTypeSet;
  H: TKMHouse;
begin
  try
    Result := -1;
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and gTerrain.TileInMapCoords(X, Y)
    and ((aHouseType = -1) or HouseTypeValid(aHouseType)) then
    begin
      if aHouseType = -1 then
        HTS := [Low(TKMHouseType)..High(TKMHouseType)]
      else
        HTS := [HouseIndexToType[aHouseType]];

      H := gHands[aPlayer].Houses.FindHouse(HTS, X, Y);
      if H <> nil then
      begin
        Result := H.UID;
        fIDCache.CacheHouse(H, H.UID);
      end;
    end
    else
      LogParamWarning('States.ClosestHouse', [aPlayer, X, Y, aHouseType]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6216
//* Returns the house of the specified player and house types that is closest to the specified coordinates,
//* or -1 if no such house was found.
//* The house types is a "set of Byte", for example [11,13,21]
//* aHouseTypes: Set of house types
//* Result: House ID
function TKMScriptStates.ClosestHouseMultipleTypes(aPlayer, X, Y: Integer; aHouseTypes: TByteSet): Integer;
var
  B: Byte;
  HTS: THouseTypeSet;
  H: TKMHouse;
begin
  try
    Result := -1;
    HTS := [];
    for B := Low(HouseIndexToType) to High(HouseIndexToType) do
      if (B in aHouseTypes) and (HouseIndexToType[B] <> htNone) then
        HTS := HTS + [HouseIndexToType[B]];

    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and gTerrain.TileInMapCoords(X, Y) then
    begin
      H := gHands[aPlayer].Houses.FindHouse(HTS, X, Y);
      if H <> nil then
      begin
        Result := H.UID;
        fIDCache.CacheHouse(H, H.UID);
      end;
    end
    else
      LogParamWarning('States.ClosestHouseMultipleTypes', [aPlayer, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6216
//* Returns the unit of the specified player and unit type that is closest to the specified coordinates,
//* or -1 if no such unit was found.
//* If the unit type is -1 any unit type will be accepted
//* Result: Unit ID
function TKMScriptStates.ClosestUnit(aPlayer, X, Y, aUnitType: Integer): Integer;
var
  UTS: TKMUnitTypeSet;
  U: TKMUnit;
begin
  try
    Result := -1;
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and gTerrain.TileInMapCoords(X, Y)
    and ((aUnitType = -1) or (aUnitType in [Low(UnitIndexToType)..High(UnitIndexToType)]))  then
    begin
      if aUnitType = -1 then
        UTS := [Low(TKMUnitType)..High(TKMUnitType)]
      else
        UTS := [UnitIndexToType[aUnitType]];

      U := gHands[aPlayer].Units.GetClosestUnit(KMPoint(X,Y), UTS);
      if U <> nil then
      begin
        Result := U.UID;
        fIDCache.CacheUnit(U, U.UID);
      end;
    end
    else
      LogParamWarning('States.ClosestUnit', [aPlayer, X, Y, aUnitType]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6216
//* Returns the unit of the specified player and unit types that is closest to the specified coordinates,
//* or -1 if no such unit was found.
//* The unit types is a "set of Byte", for example [0,9]
//* aUnitTypes: Set of unit types
//* Result: Unit ID
function TKMScriptStates.ClosestUnitMultipleTypes(aPlayer, X, Y: Integer; aUnitTypes: TByteSet): Integer;
var
  B: Byte;
  UTS: TKMUnitTypeSet;
  U: TKMUnit;
begin
  try
    Result := -1;
    UTS := [];
    for B in [Low(UnitIndexToType)..High(UnitIndexToType)] do
      if B in aUnitTypes then
        UTS := UTS + [UnitIndexToType[B]];

    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and gTerrain.TileInMapCoords(X, Y) then
    begin
      U := gHands[aPlayer].Units.GetClosestUnit(KMPoint(X,Y), UTS);
      if U <> nil then
      begin
        Result := U.UID;
        fIDCache.CacheUnit(U, U.UID);
      end;
    end
    else
      LogParamWarning('States.ClosestUnit', [aPlayer, X, Y]);
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
      LogParamWarning('States.ConnectedByRoad', [X1, Y1, X2, Y2]);
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
      LogParamWarning('States.ConnectedByWalking', [X1, Y1, X2, Y2]);
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
function TKMScriptStates.StatAIDefencePositionsCount(aPlayer: Byte): Integer;
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1)
    and (gHands[aPlayer].Enabled) then
    begin
      if gHands[aPlayer].AI.Setup.NewAI then
        Result := gHands[aPlayer].AI.General.DefencePositions.Count
      else
        Result := gHands[aPlayer].AI.General.DefencePositions.Count;
    end
    else
    begin
      Result := 0;
      LogParamWarning('States.StatAIDefencePositionsCount', [aPlayer]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* How many military units player has
//* Result: Army count
function TKMScriptStates.StatArmyCount(aPlayer: Byte): Integer;
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      Result := gHands[aPlayer].Stats.GetArmyCount
    else
    begin
      Result := 0;
      LogParamWarning('States.StatArmyCount', [aPlayer]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* How many citizen player has
//* Result: Citizen count
function TKMScriptStates.StatCitizenCount(aPlayer: Byte): Integer;
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      Result := gHands[aPlayer].Stats.GetCitizensCount
    else
    begin
      Result := 0;
      LogParamWarning('States.StatCitizenCount', [aPlayer]);
    end;
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
    Result := gGame.GameTick;
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
    Result := 600 * gGame.GameOptions.Peacetime;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Check how player 1 feels towards player 2 (order matters).
//* Returns true for ally, false for enemy
//* Result: Allied
function TKMScriptStates.PlayerAllianceCheck(aPlayer1, aPlayer2: Byte): Boolean;
begin
  try
    if  InRange(aPlayer1, 0, gHands.Count - 1)
    and InRange(aPlayer2, 0, gHands.Count - 1)
    and (gHands[aPlayer1].Enabled)
    and (gHands[aPlayer2].Enabled) then
      Result := gHands[aPlayer1].Alliances[aPlayer2] = atAlly
    else
    begin
      Result := False;
      LogParamWarning('States.PlayerAllianceCheck', [aPlayer1, aPlayer2]);
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
function TKMScriptStates.StatHouseMultipleTypesCount(aPlayer: Byte; aTypes: TByteSet): Integer;
var
  B: Byte;
begin
  try
    Result := 0;
    if InRange(aPlayer, 0, gHands.Count - 1)
    and (gHands[aPlayer].Enabled) then
    begin
      for B := Low(HouseIndexToType) to High(HouseIndexToType) do
        if (B in aTypes) and (HouseIndexToType[B] <> htNone) then
          inc(Result, gHands[aPlayer].Stats.GetHouseQty(HouseIndexToType[B]));
    end
    else
      LogParamWarning('States.StatHouseMultipleTypesCount', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the total number of the specified house type for the specified player.
//* Result: Number of houses
function TKMScriptStates.StatHouseTypeCount(aPlayer, aHouseType: Byte): Integer;
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and HouseTypeValid(aHouseType) then
      Result := gHands[aPlayer].Stats.GetHouseQty(HouseIndexToType[aHouseType])
    else
    begin
      Result := 0;
      LogParamWarning('States.StatHouseTypeCount', [aPlayer, aHouseType]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6313
//* Specified house type plans count
//* Result: Number of plans
function TKMScriptStates.StatHouseTypePlansCount(aPlayer, aHouseType: Byte): Integer;
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1)
    and (gHands[aPlayer].Enabled)
    and HouseTypeValid(aHouseType) then
      Result := gHands[aPlayer].Stats.GetHousePlans(HouseIndexToType[aHouseType])
    else
    begin
      Result := 0;
      LogParamWarning('States.StatHouseTypePlansCount', [aPlayer, aHouseType]);
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
function TKMScriptStates.PlayerDefeated(aPlayer: Byte): Boolean;
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      Result := gHands[aPlayer].AI.HasLost
    else
    begin
      Result := False;
      LogParamWarning('States.PlayerDefeated', [aPlayer]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 4545
//* See if player is victorious
//* Result: Victorious
function TKMScriptStates.PlayerVictorious(aPlayer: Byte): Boolean;
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      Result := (gHands[aPlayer].AI.HasWon)
    else
    begin
      Result := False;
      LogParamWarning('States.PlayerVictorious', [aPlayer]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5345
//* Returns the ware distribution for the specified resource, house and player
//* Result: Ware distribution [0..5]
function TKMScriptStates.PlayerWareDistribution(aPlayer, aWareType, aHouseType: Byte): Byte;
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and(aWareType in [Low(WareIndexToType) .. High(WareIndexToType)])
    and HouseTypeValid(aHouseType) then
      Result := gHands[aPlayer].Stats.WareDistribution[WareIndexToType[aWareType], HouseIndexToType[aHouseType]]
    else
    begin
      Result := 0;
      LogParamWarning('States.PlayerWareDistribution', [aPlayer, aWareType, aHouseType]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5165
//* Returns an array with IDs for all the units of the specified player
//* Result: Array of unit IDs
function TKMScriptStates.PlayerGetAllUnits(aPlayer: Byte): TIntegerArray;
var
  I, UnitCount: Integer;
  U: TKMUnit;
begin
  try
    SetLength(Result, 0);

    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
    begin
      UnitCount := 0;

      //Allocate max required space
      SetLength(Result, gHands[aPlayer].Units.Count);
      for I := 0 to gHands[aPlayer].Units.Count - 1 do
      begin
        U := gHands[aPlayer].Units[I];
        //Skip units in training, they can't be disturbed until they are finished training
        if U.IsDeadOrDying or (U.Task is TKMTaskSelfTrain) then Continue;
        Result[UnitCount] := U.UID;
        Inc(UnitCount);
      end;

      //Trim to length
      SetLength(Result, UnitCount);
    end
    else
    begin
      LogParamWarning('States.PlayerGetAllUnits', [aPlayer]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5209
//* Returns an array with IDs for all the houses of the specified player
//* Result: Array of house IDs
function TKMScriptStates.PlayerGetAllHouses(aPlayer: Byte): TIntegerArray;
var
  I, HouseCount: Integer;
  H: TKMHouse;
begin
  try
    SetLength(Result, 0);

    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
    begin
      HouseCount := 0;

      //Allocate max required space
      SetLength(Result, gHands[aPlayer].Houses.Count);
      for I := 0 to gHands[aPlayer].Houses.Count - 1 do
      begin
        H := gHands[aPlayer].Houses[I];
        if H.IsDestroyed then Continue;
        Result[HouseCount] := H.UID;
        Inc(HouseCount);
      end;

      //Trim to length
      SetLength(Result, HouseCount);
    end
    else
    begin
      LogParamWarning('States.PlayerGetAllHouses', [aPlayer]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5209
//* Returns an array with IDs for all the groups of the specified player
//* Result: Array of group IDs
function TKMScriptStates.PlayerGetAllGroups(aPlayer: Byte): TIntegerArray;
var
  I, GroupCount: Integer;
  G: TKMUnitGroup;
begin
  try
    SetLength(Result, 0);

    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
    begin
      GroupCount := 0;

      //Allocate max required space
      SetLength(Result, gHands[aPlayer].UnitGroups.Count);
      for I := 0 to gHands[aPlayer].UnitGroups.Count - 1 do
      begin
        G := gHands[aPlayer].UnitGroups[I];
        if G.IsDead then Continue;
        Result[GroupCount] := G.UID;
        Inc(GroupCount);
      end;

      //Trim to length
      SetLength(Result, GroupCount);
    end
    else
    begin
      LogParamWarning('States.PlayerGetAllGroups', [aPlayer]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5927
//* Wherever player is controlled by AI
//* Result: Player is AI
function TKMScriptStates.PlayerIsAI(aPlayer: Byte): Boolean;
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      Result := gHands[aPlayer].HandType = hndComputer
    else
    begin
      Result := False;
      LogParamWarning('States.PlayerIsAI', [aPlayer]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 4289
//* Returns the number of units of the specified player
//* Result: Number of units
function TKMScriptStates.StatUnitCount(aPlayer: Byte): Integer;
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      Result := gHands[aPlayer].Stats.GetUnitQty(utAny)
    else
    begin
      Result := 0;
      LogParamWarning('States.StatUnitCount', [aPlayer]);
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
function TKMScriptStates.StatUnitMultipleTypesCount(aPlayer: Byte; aTypes: TByteSet): Integer;
var
  B: Byte;
begin
  try
    Result := 0;
    if InRange(aPlayer, 0, gHands.Count - 1)
    and (gHands[aPlayer].Enabled) then
    begin
      for B := Low(UnitIndexToType) to High(UnitIndexToType) do
        if B in aTypes then
          inc(Result, gHands[aPlayer].Stats.GetUnitQty(UnitIndexToType[B]));
    end
    else
      LogParamWarning('States.StatUnitMultipleTypesCount', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns number of specified unit type for specified player
//* Result: Number of units
function TKMScriptStates.StatUnitTypeCount(aPlayer, aUnitType: Byte): Integer;
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and (aUnitType in [Low(UnitIndexToType)..High(UnitIndexToType)])
    then
      Result := gHands[aPlayer].Stats.GetUnitQty(UnitIndexToType[aUnitType])
    else
    begin
      Result := 0;
      LogParamWarning('States.StatUnitTypeCount', [aPlayer, aUnitType]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the number of the specified unit killed by the specified player
//* Result: Number of killed units
function TKMScriptStates.StatUnitKilledCount(aPlayer, aUnitType: Byte): Integer;
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and (aUnitType in [Low(UnitIndexToType)..High(UnitIndexToType)])
    then
      Result := gHands[aPlayer].Stats.GetUnitKilledQty(UnitIndexToType[aUnitType])
    else
    begin
      Result := 0;
      LogParamWarning('States.StatUnitKilledCount', [aPlayer, aUnitType]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6331
//* Returns the number of the specified unit types killed by the specified player.
//* Result: Set of unit types eg. [0, 5, 13]
function TKMScriptStates.StatUnitKilledMultipleTypesCount(aPlayer: Byte; aTypes: TByteSet): Integer;
var
  B: Byte;
begin
  try
    Result := 0;
    if InRange(aPlayer, 0, gHands.Count - 1)
    and (gHands[aPlayer].Enabled) then
    begin
      for B := Low(UnitIndexToType) to High(UnitIndexToType) do
        if B in aTypes then
          inc(Result, gHands[aPlayer].Stats.GetUnitKilledQty(UnitIndexToType[B]));
    end
    else
      LogParamWarning('States.StatUnitKilledMultipleTypesCount', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the number of the specified unit lost by the specified player
//* Result: Number of lost units
function TKMScriptStates.StatUnitLostCount(aPlayer, aUnitType: Byte): Integer;
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and (aUnitType in [Low(UnitIndexToType)..High(UnitIndexToType)])
    then
      Result := gHands[aPlayer].Stats.GetUnitLostQty(UnitIndexToType[aUnitType])
    else
    begin
      Result := 0;
      LogParamWarning('States.StatUnitLostCount', [aPlayer, aUnitType]);
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
function TKMScriptStates.StatUnitLostMultipleTypesCount(aPlayer: Byte; aTypes: TByteSet): Integer;
var
  B: Byte;
begin
  try
    Result := 0;
    if InRange(aPlayer, 0, gHands.Count - 1)
    and (gHands[aPlayer].Enabled) then
    begin
      for B := Low(UnitIndexToType) to High(UnitIndexToType) do
        if B in aTypes then
          inc(Result, gHands[aPlayer].Stats.GetUnitLostQty(UnitIndexToType[B]));
    end
    else
      LogParamWarning('States.StatUnitLostMultipleTypesCount', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the number of the specified resource produced by the specified player
//* Result: Number of produced resources
function TKMScriptStates.StatResourceProducedCount(aPlayer, aResType: Byte): Integer;
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and (aResType in [Low(WareIndexToType)..High(WareIndexToType)])
    then
      Result := gHands[aPlayer].Stats.GetWaresProduced(WareIndexToType[aResType])
    else
    begin
      Result := 0;
      LogParamWarning('States.StatResourceProducedCount', [aPlayer, aResType]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6331
//* Returns the number of the specified resource types produced by the specified player.
//* aTypes: Set of ware types eg. [8, 10, 13, 27] for food
//* Result: Number of produced resources
function TKMScriptStates.StatResourceProducedMultipleTypesCount(aPlayer: Byte; aTypes: TByteSet): Integer;
var
  B: Byte;
begin
  try
    Result := 0;
    if InRange(aPlayer, 0, gHands.Count - 1)
    and (gHands[aPlayer].Enabled) then
    begin
      for B := Low(WareIndexToType) to High(WareIndexToType) do
        if B in aTypes then
          inc(Result, gHands[aPlayer].Stats.GetWaresProduced(WareIndexToType[B]));
    end
    else
      LogParamWarning('States.StatResourceProducedMultipleTypesCount', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 4758
//* Get players color as text in hex format
//* Result: Player color
function TKMScriptStates.PlayerColorText(aPlayer: Byte): AnsiString;
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
    begin
      //Use FlagColorToTextColor to desaturate and lighten the text so all player colours are
      //readable on a variety of backgrounds
      Result := AnsiString(Format('%.6x', [FlagColorToTextColor(gHands[aPlayer].FlagColor) and $FFFFFF]))
    end
    else
    begin
      Result := '';
      LogParamWarning('States.PlayerColorText', [aPlayer]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Will be false if nobody selected that location in multiplayer
//* Result: Enabled
function TKMScriptStates.PlayerEnabled(aPlayer: Byte): Boolean;
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) then
      Result := gHands[aPlayer].Enabled
    else
    begin
      Result := False;
      LogParamWarning('States.PlayerEnabled', [aPlayer]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Get name of player as a string (for multiplayer)
//* Result: Player name
function TKMScriptStates.PlayerName(aPlayer: Byte): AnsiString;
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      Result := AnsiString(gHands[aPlayer].OwnerName)
    else
    begin
      Result := '';
      LogParamWarning('States.PlayerName', [aPlayer]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the ID of the house at the specified location or -1 if no house exists there
//* Result: House ID
function TKMScriptStates.HouseAt(aX, aY: Word): Integer;
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
      LogParamWarning('States.HouseAt', [aX, aY]);
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
          LogParamWarning('States.HouseBarracksRallyPointX: Specified house is not Barracks', [aBarracks]);
      end;
    end
    else
      LogParamWarning('States.HouseBarracksRallyPointX', [aBarracks]);
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
          LogParamWarning('States.HouseBarracksRallyPointY: Specified house is not Barracks', [aBarracks]);
      end;
    end
    else
      LogParamWarning('States.HouseBarracksRallyPointY', [aBarracks]);
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
          LogParamWarning('States.HouseFlagPoint: Specified house does not have Flag point', [aHouseId]);
      end;
    end
    else
      LogParamWarning('States.HouseFlagPoint', [aHouseId]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6285
//* Returns building progress of the specified house
//* Result: Building progress
function TKMScriptStates.HouseBuildingProgress(aHouseID: Integer): Word;
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
      LogParamWarning('States.HouseBuildingProgress', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5993
//* Returns true if the specified house can reach the resources that it mines (coal, stone, fish, etc.)
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
        Result := not H.ResourceDepletedMsgIssued;
    end
    else
      LogParamWarning('States.HouseCanReachResources', [aHouseID]);
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
      LogParamWarning('States.HouseDamage', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns true if the specified house has delivery disabled
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
      LogParamWarning('States.HouseDeliveryBlocked', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns delivery mode ID, where
//* ID = 0 delivery blocked
//* ID = 1 delivery allowed
//* ID = 2 take ware out allowed
//* if no house was found then ID = 1 is returned
//* Result: Blocked
function TKMScriptStates.HouseDeliveryMode(aHouseID: Integer): Integer;
var
  H: TKMHouse;
begin
  try
    Result := Integer(dmDelivery);
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        Result := Integer(H.DeliveryMode);
    end
    else
      LogParamWarning('States.HouseDeliveryMode', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns true if the house is destroyed
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
      LogParamWarning('States.HouseDestroyed', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns true if the specified house currently has an occupant
//* Result: Has occupant
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
        Result := H.HasOwner;
    end
    else
      LogParamWarning('States.HouseHasOccupant', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5345
//* Returns true if the specified house is fully built
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
      LogParamWarning('States.HouseIsComplete', [aHouseID]);
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
      LogParamWarning('States.HousePosition', [aHouseID]);
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
      LogParamWarning('States.HousePositionX', [aHouseID]);
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
      LogParamWarning('States.HousePositionY', [aHouseID]);
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
    Result := PLAYER_NONE;
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        Result := H.Owner;
    end
    else
      LogParamWarning('States.HouseOwner', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns true if the specified house has repair enabled
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
      LogParamWarning('States.HouseRepair', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the amount of the specified resource in the specified house
//* Result: Number of resources
function TKMScriptStates.HouseResourceAmount(aHouseID, aResource: Integer): Integer;
var
  H: TKMHouse;
  Res: TKMWareType;
begin
  try
    Result := -1; //-1 if house id is invalid
    if (aHouseID > 0) and (aResource in [Low(WareIndexToType)..High(WareIndexToType)]) then
    begin
      Res := WareIndexToType[aResource];
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        Result := H.CheckResIn(Res) + H.CheckResOut(Res); //Count both in and out
    end
    else
      LogParamWarning('States.HouseResourceAmount', [aHouseID, aResource]);
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
        Result := UnitTypeToIndex[TKMHouseSchool(H).Queue[QueueIndex]];
    end
    else
      LogParamWarning('States.HouseSchoolQueue', [aHouseID, QueueIndex]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6510
//* Returns true if specified WIP house area is digged
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
      LogParamWarning('States.HouseSiteIsDigged', [aHouseID]);
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
      LogParamWarning('States.HouseTownHallMaxGold', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the type of the specified house
//* Result: House type
//Get the house type
function TKMScriptStates.HouseType(aHouseID: Integer): Integer;
var
  H: TKMHouse;
begin
  try
    Result := -1;
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        Result := HouseTypeToIndex[H.HouseType] - 1;
    end
    else
      LogParamWarning('States.HouseType', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6284
//* Returns max health of the specified house type
//* Result: Max health
function TKMScriptStates.HouseTypeMaxHealth(aHouseType: Integer): Word;
begin
  try
    Result := 0;
    if HouseTypeValid(aHouseType) then
      Result := gRes.Houses[HouseIndexToType[aHouseType]].MaxHealth
    else
      LogParamWarning('States.HouseTypeMaxHealth', [aHouseType]);
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
      Result := '<%' + AnsiString(IntToStr(gRes.Houses[HouseIndexToType[aHouseType]].HouseNameTextID)) + '>'
    else
    begin
      Result := '';
      LogParamWarning('States.HouseTypeName', [aHouseType]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5345
//* Returns the type of unit that should occupy the specified type of house, or -1 if no unit should occupy it.
//* Result: Unit type
function TKMScriptStates.HouseTypeToOccupantType(aHouseType: Integer): Integer;
begin
  try
    Result := -1;
    if HouseTypeValid(aHouseType) then
    begin
      Result := UnitTypeToIndex[gRes.Houses[HouseIndexToType[aHouseType]].OwnerType];
    end
    else
      LogParamWarning('States.HouseTypeToOccupantType', [aHouseType]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6220
//* Returns true if the specified player can build the specified house type (unlocked and allowed).
//* Result: House unlocked
function TKMScriptStates.HouseUnlocked(aPlayer, aHouseType: Word): Boolean;
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and HouseTypeValid(aHouseType) then
      Result := gHands[aPlayer].Locks.HouseCanBuild(HouseIndexToType[aHouseType])
    else
    begin
      Result := False;
      LogParamWarning('States.HouseUnlocked', [aPlayer, aHouseType]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5099
//* Returns true if the specified ware in the specified storehouse or barracks is blocked
//* Result: Ware blocked
function TKMScriptStates.HouseWareBlocked(aHouseID, aWareType: Integer): Boolean;
var
  H: TKMHouse;
  Res: TKMWareType;
begin
  try
    Result := False;
    if (aHouseID > 0) and (aWareType in [Low(WareIndexToType)..High(WareIndexToType)]) then
    begin
      Res := WareIndexToType[aWareType];
      H := fIDCache.GetHouse(aHouseID);
      if (H is TKMHouseStore) then
        Result := TKMHouseStore(H).NotAcceptFlag[Res];
      if (H is TKMHouseBarracks) and (Res in [WARFARE_MIN..WARFARE_MAX]) then
        Result := TKMHouseBarracks(H).NotAcceptFlag[Res];
    end
    else
      LogParamWarning('States.HouseWareBlocked', [aHouseID, aWareType]);
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
  H: TKMHouse;
  Res: TKMWareType;
  I: Integer;
begin
  try
    Result := 0;
    if (aHouseID > 0) and (aWareType in [Low(WareIndexToType)..High(WareIndexToType)]) then
    begin
      Res := WareIndexToType[aWareType];
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil) then
        for I := 1 to 4 do
          if gRes.Houses[H.HouseType].ResOutput[I] = Res then
          begin
            Result := H.ResOrder[I];
            Exit;
          end;
    end
    else
      LogParamWarning('States.HouseWeaponsOrdered', [aHouseID, aWareType]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5099
//* Returns true if the specified woodcutter's hut is on chop-only mode
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
        Result := TKMHouseWoodcutters(H).WoodcutterMode = wcmChop;
    end
    else
      LogParamWarning('States.HouseWoodcutterChopOnly', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns woodcutter mode value for the specified woodcutter's hut
//* Possible values for woodcutter mode are:
//* 0 - Chop And Plant
//* 1 - Chop only
//* 2 - Plant only
//* Result: woodcutter mode as Integer value
function TKMScriptStates.HouseWoodcutterMode(aHouseID: Integer): Integer;
var
  H: TKMHouse;
begin
  try
    Result := Integer(wcmChopAndPlant);
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H is TKMHouseWoodcutters then
        Result := Integer(TKMHouseWoodcutters(H).WoodcutterMode);
    end
    else
      LogParamWarning('States.HouseWoodcutterMode', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5345
//* Returns true if the specified player has a corn field at the specified location.
//* If player index is -1 it will return true if any player has a corn field at the specified tile
//* Result: Is field
function TKMScriptStates.IsFieldAt(aPlayer: ShortInt; X, Y: Word): Boolean;
begin
  try
    Result := False;
    //-1 stands for any player
    if InRange(aPlayer, -1, gHands.Count - 1) and gTerrain.TileInMapCoords(X, Y) then
      Result := gTerrain.TileIsCornField(KMPoint(X,Y))
                and ((aPlayer = -1) or (gTerrain.Land[Y, X].TileOwner = aPlayer))
    else
      LogParamWarning('States.IsFieldAt', [aPlayer, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5345
//* Returns true if the specified player has a road at the specified location.
//* If player index is -1 it will return true if any player has a road at the specified tile
//* Result: Is road
function TKMScriptStates.IsRoadAt(aPlayer: ShortInt; X, Y: Word): Boolean;
begin
  try
    Result := False;
    //-1 stands for any player
    if InRange(aPlayer, -1, gHands.Count - 1) and gTerrain.TileInMapCoords(X, Y) then
      Result := (gTerrain.Land[Y,X].TileOverlay = toRoad)
                and ((aPlayer = -1) or (gTerrain.Land[Y, X].TileOwner = aPlayer))
    else
      LogParamWarning('States.IsRoadAt', [aPlayer, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5345
//* Returns true if the specified player has a winefield at the specified location.
//* If player index is -1 it will return true if any player has a winefield at the specified tile
//* Result: Is winefield
function TKMScriptStates.IsWinefieldAt(aPlayer: ShortInt; X, Y: Word): Boolean;
begin
  try
    Result := False;
    //-1 stands for any player
    if InRange(aPlayer, -1, gHands.Count - 1) and gTerrain.TileInMapCoords(X, Y) then
      Result := gTerrain.TileIsWineField(KMPoint(X,Y))
                and ((aPlayer = -1) or (gTerrain.Land[Y, X].TileOwner = aPlayer))
    else
      LogParamWarning('States.IsWinefieldAt', [aPlayer, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns true if the specified player has a field plan of the specified type at the specified location.
//* If aPlayer index is -1 it will return true if any player has plan of the specified type at the specified location.
//* If aFieldType is ftNone it will return if the specified player has a field plan of the any type (ftCorn, ftRoad, ftWine) at the specified location.
//* If aPlayer index is -1 and aFieldType is ftNone it will return if any player has a field plan of the any type (ftCorn, ftRoad, ftWine) at the specified location.
//* If Plan found then aPlayer will contain its player id and aFieldType its type
//* Result: Is plan found
function TKMScriptStates.IsPlanAt(var aPlayer: Integer; var aFieldType: TKMFieldType; X, Y: Word): Boolean;

  function FindPlan(aHandId, aX, aY: Word; var aFieldType: TKMFieldType): Boolean; inline;
  var
    FT: TKMFieldType;
  begin
    FT := gHands[aHandId].BuildList.FieldworksList.HasField(KMPoint(aX, aY));
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
  HandFilter, FieldTypeFilter: Boolean;
begin
  try
    Result := False;
    //Verify all input parameters
    if gTerrain.TileInMapCoords(X,Y) then
    begin
      HandFilter := InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled);
      FieldTypeFilter := aFieldType in [ftCorn, ftRoad, ftWine];

      if HandFilter and FieldTypeFilter then
        Result := FindPlan(aPlayer, X, Y, aFieldType)
      else
      if HandFilter then
      begin
        aFieldType := ftNone;
        Result := FindPlan(aPlayer, X, Y, aFieldType);
      end else
      begin
        if not FieldTypeFilter then
          aFieldType := ftNone;

        for I := 0 to gHands.Count - 1 do
          if gHands[I].Enabled then
          begin
            Result := FindPlan(I, X, Y, aFieldType);
            if Result then
            begin
              aPlayer := I;
              Exit;
            end;
          end;
      end
    end
    else
      LogParamWarning('States.IsPlanAt', [aPlayer, Byte(aFieldType), X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns true if the specified player has a field plan (ftCorn) at the specified location.
//* If aPlayer index is -1 it will return true if any player has field plan at the specified location.
//* If Corn (Field) Plan found then aPlayer will contain its player id
//* Result: Is field plan found
function TKMScriptStates.IsFieldPlanAt(var aPlayer: Integer; X, Y: Word): Boolean;

  function FindPlan(aHandId, aX, aY: Word): Boolean; inline;
  begin
    Result := gHands[aHandId].BuildList.FieldworksList.HasField(KMPoint(aX, aY)) = ftCorn;
  end;

var
  I: Integer;
begin
  try
    Result := False;
    //Verify all input parameters
    if gTerrain.TileInMapCoords(X,Y) then
    begin
      if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
        Result := FindPlan(aPlayer, X, Y)
      else
        for I := 0 to gHands.Count - 1 do
          if gHands[I].Enabled then
          begin
            Result := FindPlan(I, X, Y);
            if Result then
            begin
              aPlayer := I;
              Exit;
            end;
          end;
    end
    else
      LogParamWarning('States.IsFieldPlanAt', [aPlayer, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns true if the specified player has a house plan of the specified type at the specified location.
//* If aPlayer index is -1 it will return true if any player has house plan of the specified type at the specified location.
//* If aHouseType is htNone it will return if the specified player has a house plan of the any type at the specified location.
//* If aPlayer index is -1 and aHouseType is htNone it will return if any player has a house plan of the any type at the specified location.
//* If house plan found then after execution aPlayer will contain its player id and aHouseType its type
//* Result: Is house plan found
function TKMScriptStates.IsHousePlanAt(var aPlayer: Integer; var aHouseType: TKMHouseType; X, Y: Word): Boolean;

  function FindPlan(aHandId, aX, aY: Word; var aHouseType: TKMHouseType): Boolean; inline;
  var
    HT: TKMHouseType;
  begin
    Result := gHands[aHandId].BuildList.HousePlanList.HasPlan(KMPoint(aX, aY), HT);
    if Result then
    begin
      if aHouseType = htNone then
        aHouseType := HT
      else
        Result := aHouseType = HT;
    end;
  end;

var
  I: Integer;
  HandFilter, HTypeFilter: Boolean;
begin
  try
    Result := False;
    //Verify all input parameters
    if gTerrain.TileInMapCoords(X,Y) then
    begin
      HandFilter := InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled);
      HTypeFilter := aHouseType in [HOUSE_MIN..HOUSE_MAX];

      if HandFilter and HTypeFilter then
        Result := FindPlan(aPlayer, X, Y, aHouseType)
      else
      if HandFilter then
      begin
        aHouseType := htNone;
        Result := FindPlan(aPlayer, X, Y, aHouseType);
      end else
      begin
        if not HTypeFilter then
          aHouseType := htNone;

        for I := 0 to gHands.Count - 1 do
          if gHands[I].Enabled then
          begin
            Result := FindPlan(I, X, Y, aHouseType);
            if Result then
            begin
              aPlayer := I;
              Exit;
            end;
          end;
      end;
    end
    else
      LogParamWarning('States.IsHousePlanAt', [X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns true if the specified player has a field plan (ftRoad) at the specified location.
//* If aPlayer index is -1 it will return true if any player has road plan at the specified location.
//* If Road plan found then aPlayer will contain its player id
//* Result: Is road plan found
function TKMScriptStates.IsRoadPlanAt(var aPlayer: Integer; X, Y: Word): Boolean;

  function FindPlan(aHandId, aX, aY: Word): Boolean; inline;
  begin
    Result := gHands[aHandId].BuildList.FieldworksList.HasField(KMPoint(aX, aY)) = ftRoad;
  end;

var
  I: Integer;
begin
  try
    Result := False;
    //Verify all input parameters
    if gTerrain.TileInMapCoords(X,Y) then
    begin
      if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
        Result := FindPlan(aPlayer, X, Y)
      else
        for I := 0 to gHands.Count - 1 do
          if gHands[I].Enabled then
          begin
            Result := FindPlan(I, X, Y);
            if Result then
            begin
              aPlayer := I;
              Exit;
            end;
          end;
    end
    else
      LogParamWarning('States.IsRoadPlanAt', [X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;



//* Version: 7000+
//* Returns true if the specified player has a field plan (ftWine) at the specified location.
//* If aPlayer index is -1 it will return true if any player has winefield plan at the specified location.
//* If Winefield Plan found then aPlayer will contain its player id
//* Result: Is winefield plan found
function TKMScriptStates.IsWinefieldPlanAt(var aPlayer: Integer; X, Y: Word): Boolean;

  function FindPlan(aHandId, aX, aY: Word): Boolean; inline;
  begin
    Result := gHands[aHandId].BuildList.FieldworksList.HasField(KMPoint(aX, aY)) = ftWine;
  end;

var
  I: Integer;
begin
  try
    Result := False;
    //Verify all input parameters
    if gTerrain.TileInMapCoords(X,Y) then
    begin
      if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
        Result := FindPlan(aPlayer, X, Y)
      else
        for I := 0 to gHands.Count - 1 do
          if gHands[I].Enabled then
          begin
            Result := FindPlan(I, X, Y);
            if Result then
            begin
              aPlayer := I;
              Exit;
            end;
          end;
    end
    else
      LogParamWarning('States.IsWinefieldPlanAt', [X, Y]);
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
    Result := gGame.MissionMode = mmNormal;
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
    Result := gGame.MissionMode = mmTactic;
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
    Result := KM_CommonUtils.KaMRandom('TKMScriptStates.KaMRandom');
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6216
//* Returns a random integer such that: 0 <= Number
//* Result: Number 0 to aMax
function TKMScriptStates.KaMRandomI(aMax:Integer): Integer;
begin
  try
    //No parameters to check, any integer is fine (even negative)
    Result := KM_CommonUtils.KaMRandom(aMax, 'TKMScriptStates.KaMRandomI');
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
//* Returns mission big description
function TKMScriptStates.MissionBigDesc: UnicodeString;
begin
  try
    Result := gGame.MapTxtInfo.BigDesc;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns mission big description Libx ID
function TKMScriptStates.MissionBigDescLibx: Integer;
begin
  try
    Result := gGame.MapTxtInfo.BigDescLibx;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns mission small description
function TKMScriptStates.MissionSmallDesc: UnicodeString;
begin
  try
    Result := gGame.MapTxtInfo.SmallDesc;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns mission small description Libx ID
function TKMScriptStates.MissionSmallDescLibx: Integer;
begin
  try
    Result := gGame.MapTxtInfo.SmallDescLibx;
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
    Result := gGame.MissionDifficulty;
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


//* Version: 6587
//* Returns the tile type ID of the tile at the specified XY coordinates.
//* Tile IDs can be seen by hovering over the tiles on the terrain tiles tab in the map editor.
//* Result: Tile type (0..255)
function TKMScriptStates.MapTileType(X, Y: Integer): Integer;
begin
  try
    if gTerrain.TileInMapCoords(X, Y) then
      Result := gTerrain.Land[Y, X].BaseLayer.Terrain
    else
    begin
      Result := -1;
      LogParamWarning('States.MapTileType', [X, Y]);
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
      Result := gTerrain.Land[Y, X].BaseLayer.Rotation mod 4
    else
    begin
      Result := -1;
      LogParamWarning('States.MapTileRotation', [X, Y]);
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
    Result := gTerrain.MapX
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
    Result := gTerrain.MapY
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
      Result := gTerrain.Land[Y, X].Height
    else
    begin
      Result := -1;
      LogParamWarning('States.MapTileHeight', [X, Y]);
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
      Result := gTerrain.Land[Y, X].Obj
    else
    begin
      Result := -1;
      LogParamWarning('States.MapTileObject', [X, Y]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Returns true if specified tile has requested passability.
//* aPassability: passability index as listed in KM_Defaults (starts from 0)
//* Result: true or false
function TKMScriptStates.MapTilePassability(X, Y: Integer; aPassability: Byte): Boolean;
begin
  try
    if (gTerrain.TileInMapCoords(X, Y))
    and (TKMTerrainPassability(aPassability) in [Low(TKMTerrainPassability)..High(TKMTerrainPassability)]) then
      Result := TKMTerrainPassability(aPassability) in gTerrain.Land[Y, X].Passability
    else
    begin
      Result := False;
      LogParamWarning('States.MapTilePassability', [X, Y, aPassability]);
    end;
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
  ResFrom: TKMWareType;
begin
  try
    Result := -1;
    if aMarketID > 0 then
    begin
      H := fIDCache.GetHouse(aMarketID);
      if (H is TKMHouseMarket)
      and (not H.IsDestroyed)
      and (TKMHouseMarket(H).ResFrom <> TKMHouseMarket(H).ResTo)
      and (TKMHouseMarket(H).ResFrom in [WARE_MIN .. WARE_MAX])
      and (TKMHouseMarket(H).ResTo in [WARE_MIN .. WARE_MAX]) then
      begin
        ResFrom := TKMHouseMarket(H).ResFrom;
        Result := WareTypeToIndex[ResFrom];
      end;
    end
    else
      LogParamWarning('States.MarketFromWare', [aMarketID]);
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
      and (TKMHouseMarket(H).ResFrom in [WARE_MIN .. WARE_MAX])
      and (TKMHouseMarket(H).ResTo in [WARE_MIN .. WARE_MAX]) then
        Result := TKMHouseMarket(H).ResOrder[0];
    end
    else
      LogParamWarning('States.MarketOrderAmount', [aMarketID]);
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
  ResTo: TKMWareType;
begin
  try
    Result := -1;
    if aMarketID > 0 then
    begin
      H := fIDCache.GetHouse(aMarketID);
      if (H is TKMHouseMarket)
      and (not H.IsDestroyed)
      and (TKMHouseMarket(H).ResFrom <> TKMHouseMarket(H).ResTo)
      and (TKMHouseMarket(H).ResFrom in [WARE_MIN .. WARE_MAX])
      and (TKMHouseMarket(H).ResTo in [WARE_MIN .. WARE_MAX]) then
      begin
        ResTo := TKMHouseMarket(H).ResTo;
        Result := WareTypeToIndex[ResTo];
      end;
    end
    else
      LogParamWarning('States.MarketToWare', [aMarketID]);
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
  Res: TKMWareType;
begin
  try
    Result := -1; //-1 if ware is invalid
    if aRes in [Low(WareIndexToType)..High(WareIndexToType)] then
    begin
      Res := WareIndexToType[aRes];
      Result := gRes.Wares[Res].MarketPrice;
    end
    else
      LogParamWarning('States.MarketValue', [aRes]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5097
//* Check if a tile is revealed in fog of war for a player
//* Result: Revealed
function TKMScriptStates.FogRevealed(aPlayer: Byte; aX, aY: Word): Boolean;
begin
  try
    Result := False;
    if gTerrain.TileInMapCoords(aX,aY)
    and InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      Result := gHands[aPlayer].FogOfWar.CheckTileRevelation(aX, aY) > 0
    else
      LogParamWarning('States.FogRevealed', [aPlayer, aX, aY]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the ID of the unit on the specified tile or -1 if no unit exists there
//* Result: Unit ID
function TKMScriptStates.UnitAt(aX, aY: Word): Integer;
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
      LogParamWarning('States.UnitAt', [aX, aY]);
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
        Result := U.CurrPosition;
    end
    else
      LogParamWarning('States.UnitPosition', [aUnitID]);
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
        Result := U.CurrPosition.X;
    end
    else
      LogParamWarning('States.UnitPositionX', [aUnitID]);
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
        Result := U.CurrPosition.Y;
    end
    else
      LogParamWarning('States.UnitPositionY', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns true if the unit is dead
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
      LogParamWarning('States.UnitDead', [aUnitID]);
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
    Result := PLAYER_NONE;
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U <> nil then
        Result := U.Owner;
    end
    else
      LogParamWarning('States.UnitOwner', [aUnitID]);
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
      LogParamWarning('States.UnitDirection', [aUnitID]);
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
      LogParamWarning('States.UnitDismissable', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the type of the specified unit
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
        Result := UnitTypeToIndex[U.UnitType];
    end
    else
      LogParamWarning('States.UnitType', [aUnitID]);
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
    if (aUnitType in [Low(UnitIndexToType) .. High(UnitIndexToType)]) then
      Result := '<%' + AnsiString(IntToStr(gRes.Units[UnitIndexToType[aUnitType]].GUITextID)) + '>'
    else
    begin
      Result := '';
      LogParamWarning('States.UnitTypeName', [aUnitType]);
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
    if (aWareType in [Low(WareIndexToType) .. High(WareIndexToType)]) then
      Result := '<%' + AnsiString(IntToStr(gRes.Wares[WareIndexToType[aWareType]].TextID)) + '>'
    else
    begin
      Result := '';
      LogParamWarning('States.WareTypeName', [aWareType]);
    end;
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
      LogParamWarning('States.UnitHPCurrent', [aUnitID]);
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
      LogParamWarning('States.UnitHPMax', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* See if unit is invulnerable
//* Result: true or false
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
      LogParamWarning('States.UnitHPInvulnerable', [aUnitID]);
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
      LogParamWarning('States.UnitHunger', [aUnitID]);
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
        Result := WareTypeToIndex[TKMUnitSerf(U).Carry];
    end
    else
      LogParamWarning('States.UnitCarrying', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5997
//* Returns the ID of the house which is the home of the specified unit or -1 if the unit does not have a home
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
      LogParamWarning('States.UnitHome', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6523
//* Returns true if specified unit is idle (has no orders/action)
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
      LogParamWarning('States.UnitIdle', [aUnitID]);
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


//* Version: 7000+
//* Returns true if target Group is assigned to the Defence Position at coordinates X, Y
//* Result: Group assigned to Defence position
function TKMScriptStates.GroupAssignedToDefencePosition(aGroupID, X, Y: Integer): Boolean;
var
  G: TKMUnitGroup;
  DefPos: TAIDefencePosition;
  DefPosNewAI: TKMDefencePosition;
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
          DefPosNewAI := gHands[G.Owner].AI.ArmyManagement.Defence.FindPositionOf(G);
          if DefPosNewAI <> nil then
            Result := (DefPosNewAI.Position.Loc.X = X) and (DefPosNewAI.Position.Loc.Y = Y);
        end
        else
        begin
          DefPos := gHands[G.Owner].AI.General.DefencePositions.FindPositionOf(G);
          if DefPos <> nil then
              Result := (DefPos.Position.Loc.X = X) and (DefPos.Position.Loc.Y = Y)
        end;
      end;
    end
    else
      LogParamWarning('States.GroupAssignedToDefencePosition', [aGroupID, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns the ID of the group of the unit on the specified tile or -1 if no group exists there
//* Result: Group ID
function TKMScriptStates.GroupAt(aX, aY: Word): Integer;
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
      LogParamWarning('States.UnitsGroup', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Returns true if the group is dead (all members dead or joined other groups)
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
      LogParamWarning('States.GroupDead', [aGroupID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6523
//* Returns true if specified group is idle (has no orders/action)
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
      LogParamWarning('States.GroupIdle', [aGroupID]);
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
    Result := PLAYER_NONE;
    if aGroupID > 0 then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if G <> nil then
        Result := G.Owner;
    end
    else
      LogParamWarning('States.GroupOwner', [aGroupID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5932
//* Returns the type of the specified group or -1 if Group ID invalid
//* Result: Group type
function TKMScriptStates.GroupType(aGroupID: Integer): Integer;
var
  G: TKMUnitGroup;
begin
  try
    Result := -1;
    if aGroupID > 0 then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if G <> nil then
        Result := Byte(G.GroupType);
    end
    else
      LogParamWarning('States.GroupType', [aGroupID]);
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
      LogParamWarning('States.GroupMemberCount', [aGroupID]);
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
      LogParamWarning('States.GroupOrder', [aGroupID]);
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
      LogParamWarning('States.GroupColumnCount', [aGroupID]);
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
          LogParamWarning('States.GroupMember', [aGroupID, aMemberIndex]);
      end;
    end
    else
      LogParamWarning('States.GroupMember', [aGroupID, aMemberIndex]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


end.
