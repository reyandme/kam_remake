unit KM_ScriptingActions;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, SysUtils, StrUtils, KM_AIAttacks, KM_ResTilesetTypes,
  KM_CommonTypes, KM_Defaults, KM_Points, KM_Houses, KM_ScriptingIdCache, KM_Units, KM_TerrainTypes,
  KM_ScriptSound, KM_MediaTypes, KM_ResTypes, KM_ResFonts, KM_HandTypes, KM_HouseWoodcutters,
  KM_UnitGroup, KM_ResHouses, KM_HouseCollection, KM_ResWares, KM_ScriptingEvents, KM_ScriptingTypes,
  KM_AITypes;


type
  TKMScriptActions = class(TKMScriptEntity)
  private
    fOnSetLogLinesMaxCnt: TIntegerEvent;
    procedure LogStr(const aText: String);

    function _AIDefencePositionAdd(aHand: Integer; aOrder: Integer; const aDefencePosition: TKMDefencePositionInfo): Integer;
    function _AIGroupsFormationSet(aHand: Integer; aGroupType: TKMGroupType; aCount, aColumns: Integer): Boolean;
  public
    property OnSetLogLinesMaxCnt: TIntegerEvent read fOnSetLogLinesMaxCnt write fOnSetLogLinesMaxCnt;

    procedure AIArmyType(aHand: Byte; aType: TKMArmyType);
    function AIAttackAdd(aHand: Integer; aRepeating: Boolean; aDelay: Cardinal; aTotalMen: Integer;
                         aMeleeGroupCount, aAntiHorseGroupCount, aRangedGroupCount, aMountedGroupCount: Integer; aRandomGroups: Boolean;
                         aTarget: TKMAIAttackTarget; aCustomPosition: TKMPoint): Integer;
    function AIAttackAddEx(aHand: Integer; var aAttackInfo: TKMAIAttackInfo): Integer;
    function AIAttackRemove(aHand, aAIAttackUID: Integer): Boolean;
    procedure AIAttackRemoveAll(aHand: Integer);
    procedure AIAutoAttack(aHand: Byte; aAutoAttack: Boolean);
    procedure AIAutoAttackRange(aHand: Byte; aRange: Integer);
    procedure AIAutoBuild(aHand: Byte; aAuto: Boolean);
    procedure AIAutoDefence(aHand: Byte; aAuto: Boolean);
    procedure AIAutoRepair(aHand: Byte; aAuto: Boolean);
    function AIDefencePositionAdd(aHand: Byte; X, Y: Integer; aDir, aGroupType: Byte; aRadius: Integer; aDefType: Byte): Integer;
    function AIDefencePositionAddEx(aHand, aOrder: Integer; var aDefencePosition: TKMDefencePositionInfo): Integer;
    procedure AIDefencePositionRemove(aHand: Byte; X, Y: Integer);
    procedure AIDefencePositionRemoveAll(aHand: Byte);
    procedure AIDefencePositionRemoveByUID(aHand, aUID: Integer);
    procedure AIDefendAllies(aHand: Byte; aDefend: Boolean);
    procedure AIEquipRate(aHand: Byte; aType: Byte; aRate: Integer);
    procedure AIGroupsFormationSet(aHand, aType: Byte; aCount, aColumns: Integer);
    procedure AIGroupsFormationSetEx(aHand: Integer; aGroupType: TKMGroupType; aCount, aColumns: Integer);
    procedure AIRecruitDelay(aHand: Byte; aDelay: Cardinal);
    procedure AIRecruitLimit(aHand, aLimit: Byte);
    procedure AIRepairMode(aHand: Integer; aRepairMode: TKMAIRepairMode);
    procedure AISerfsPerHouse(aHand: Byte; aSerfs: Single);
    procedure AISoldiersLimit(aHand: Byte; aLimit: Integer);
    procedure AIStartPosition(aHand: Byte; X, Y: Integer);
    procedure AIWorkerLimit(aHand, aLimit: Byte);

    procedure CinematicStart(aHand: Byte);
    procedure CinematicEnd(aHand: Byte);
    procedure CinematicPanTo(aHand: Byte; X, Y, Duration: Integer);

    function  GiveAnimal(aType, X,Y: Integer): Integer;
    function  GiveAnimalEx(aType: TKMUnitType; X,Y: Integer): Integer;
    function  GiveField(aHand, X, Y: Integer): Boolean;
    function  GiveFieldAged(aHand, X, Y: Integer; aStage: Byte; aRandomAge: Boolean): Boolean;
    function  GiveGroup(aHand, aType, X,Y, aDir, aCount, aColumns: Integer): Integer;
    function  GiveGroupEx(aHand: Integer; aType: TKMUnitType; X,Y: Integer; aDir: TKMDirection; aCount, aColumns: Integer): Integer;
    function  GiveHouse(aHand, aHouseType, X,Y: Integer): Integer;
    function  GiveHouseEx(aHand: Integer; aHouseType: TKMHouseType; X,Y: Integer): Integer;
    function  GiveHouseSite(aHand, aHouseType, X, Y: Integer; aAddMaterials: Boolean): Integer;
    function  GiveHouseSiteEx(aHand: Integer; aHouseType: TKMHouseType; X, Y, aWoodAmount, aStoneAmount: Integer): Integer;
    function  GiveUnit(aHand, aType, X,Y, aDir: Integer): Integer;
    function  GiveUnitEx(aHand: Integer; aType: TKMUnitType; X,Y: Integer; aDir: TKMDirection): Integer;
    function  GiveRoad(aHand, X, Y: Integer): Boolean;
    procedure GiveWares(aHand, aType, aCount: Integer);
    procedure GiveWaresEx(aHand: Integer; aType: TKMWareType; aCount: Integer);
    procedure GiveWeapons(aHand, aType, aCount: Integer);
    procedure GiveWeaponsEx(aHand: Integer; aType: TKMWareType; aCount: Integer);
    function  GiveWinefield(aHand, X, Y: Integer): Boolean;
    function  GiveWinefieldAged(aHand, X, Y: Integer; aStage: Byte; aRandomAge: Boolean): Boolean;

    procedure FogCoverAll(aHand: Byte);
    procedure FogCoverCircle(aHand, X, Y, aRadius: Integer);
    procedure FogRevealRect(aHand, X1, Y1, X2, Y2: Integer);
    procedure FogCoverRect(aHand, X1, Y1, X2, Y2: Integer);
    procedure FogRevealAll(aHand: Byte);
    procedure FogRevealCircle(aHand, X, Y, aRadius: Integer);

    procedure GameSpeed(aSpeed: Single);
    procedure GameSpeedChangeAllowed(aAllowed: Boolean);

    procedure GroupAllowAllyToSelect(aGroupID: Integer; aAllow: Boolean);
    procedure GroupBlockOrders(aGroupID: Integer; aBlock: Boolean);
    procedure GroupDisableHungryMessage(aGroupID: Integer; aDisable: Boolean);
    procedure GroupHungerSet(aGroupID, aHungerLevel: Integer);
    procedure GroupKillAll(aGroupID: Integer; aSilent: Boolean);
    procedure GroupOrderAttackHouse(aGroupID, aHouseID: Integer);
    procedure GroupOrderAttackUnit(aGroupID, aUnitID: Integer);
    procedure GroupOrderFood(aGroupID: Integer);
    procedure GroupOrderHalt(aGroupID: Integer);
    procedure GroupOrderLink(aGroupID, aDestGroupID: Integer);
    function  GroupOrderSplit(aGroupID: Integer): Integer;
    function  GroupOrderSplitUnit(aGroupID, aUnitID: Integer): Integer;
    procedure GroupOrderStorm(aGroupID: Integer);
    procedure GroupOrderWalk(aGroupID: Integer; X, Y, aDirection: Integer);
    procedure GroupOrderWalkEx(aGroupID: Integer; X, Y: Integer; aDirection: TKMDirection);
    procedure GroupSetFormation(aGroupID: Integer; aNumColumns: Byte);

    procedure HandHouseLock(aHand: Integer; aHouseType: TKMHouseType; aLock: TKMHandHouseLock);
    procedure HandTradeAllowed(aHand: Integer; aWareType: TKMWareType; aAllowed: Boolean);
    procedure HandUnitCanTrain(aHand: Integer; aUnitType: TKMUnitType; aCanTrain: Boolean);
    procedure HandWareDistribution(aHand: Integer; aWareType: TKMWareType; aHouseType: TKMHouseType; aAmount: Integer);

    procedure HouseAddBuildingMaterials(aHouseID: Integer);
    procedure HouseAddBuildingMaterialsEx(aHouseID, aWoodAmount, aStoneAmount: Integer);
    procedure HouseAddBuildingProgress(aHouseID: Integer);
    procedure HouseAddBuildingProgressEx(aHouseID, aBuildSteps: Integer);
    procedure HouseAddDamage(aHouseID: Integer; aDamage: Integer);
    procedure HouseAddRepair(aHouseID: Integer; aRepair: Integer);
    procedure HouseAddWaresTo(aHouseID: Integer; aType, aCount: Integer);
    procedure HouseAddWaresToEx(aHouseID: Integer; aType: TKMWareType; aCount: Integer);
    procedure HouseAllow(aHand, aHouseType: Integer; aAllowed: Boolean);
    procedure HouseAllowAllyToSelect(aHouseID: Integer; aAllow: Boolean);
    procedure HouseAllowAllyToSelectAll(aHand: ShortInt; aAllow: Boolean);
    function  HouseBarracksEquip(aHouseID: Integer; aUnitType: Integer; aCount: Integer): Integer;
    function  HouseBarracksEquipEx(aHouseID: Integer; aUnitType: TKMUnitType; aCount: Integer): Integer;
    procedure HouseBarracksGiveRecruit(aHouseID: Integer);
    procedure HouseBarracksGiveRecruits(aHouseID, aCount: Integer);
    procedure HouseBarracksRecruitBlock(aHouseID: Integer; aBlocked: Boolean);
    procedure HouseDestroy(aHouseID: Integer; aSilent: Boolean);
    procedure HouseDeliveryBlock(aHouseID: Integer; aDeliveryBlocked: Boolean);
    procedure HouseDeliveryMode(aHouseID: Integer; aDeliveryMode: TKMDeliveryMode);
    procedure HouseDisableUnoccupiedMessage(aHouseID: Integer; aDisabled: Boolean);
    procedure HouseRepairEnable(aHouseID: Integer; aRepairEnabled: Boolean);
    function  HouseSchoolQueueAdd(aHouseID: Integer; aUnitType: Integer; aCount: Integer): Integer;
    function  HouseSchoolQueueAddEx(aHouseID: Integer; aUnitType: TKMUnitType; aCount: Integer): Integer;
    procedure HouseSchoolQueueRemove(aHouseID, QueueIndex: Integer);
    procedure HouseTakeWaresFrom(aHouseID: Integer; aType, aCount: Integer);
    procedure HouseTakeWaresFromEx(aHouseID: Integer; aType: TKMWareType; aCount: Integer);
    function  HouseTownHallEquip(aHouseID: Integer; aUnitType: Integer; aCount: Integer): Integer;
    function  HouseTownHallEquipEx(aHouseID: Integer; aUnitType: TKMUnitType; aCount: Integer): Integer;
    procedure HouseTownHallMaxGold(aHouseID: Integer; aMaxGold: Integer);
    procedure HouseUnlock(aHand, aHouseType: Integer);
    procedure HouseWoodcutterChopOnly(aHouseID: Integer; aChopOnly: Boolean);
    procedure HouseWoodcutterMode(aHouseID: Integer; aWoodcutterMode: TKMWoodcutterMode);
    procedure HouseWareBlock(aHouseID, aWareType: Integer; aBlocked: Boolean);
    procedure HouseWareBlockEx(aHouseID: Integer; aWareType: TKMWareType; aBlocked: Boolean);
    procedure HouseWareBlockTakeOut(aHouseID: Integer; aWareType: TKMWareType; aBlocked: Boolean);
    procedure HouseWeaponsOrderSet(aHouseID, aWareType, aAmount: Integer);
    procedure HouseWeaponsOrderSetEx(aHouseID: Integer; aWareType: TKMWareType; aAmount: Integer);

    procedure Log(const aText: AnsiString);
    procedure LogLinesMaxCnt(aMaxLogLinesCnt: Integer);

    procedure MapBrush(X, Y: Integer; aSquare: Boolean; aSize: Integer; aTerKind: TKMTerrainKind; aRandomTiles, aOverrideCustomTiles: Boolean);
    procedure MapBrushElevation(X, Y: Integer; aSquare, aRaise: Boolean; aSize, aSlope, aSpeed: Integer);
    procedure MapBrushEqualize(X, Y: Integer; aSquare: Boolean; aSize, aSlope, aSpeed: Integer);
    procedure MapBrushFlatten(X, Y: Integer; aSquare: Boolean; aSize, aSlope, aSpeed: Integer);
    procedure MapBrushMagicWater(X, Y: Integer);
    procedure MapBrushWithMask(X, Y: Integer; aSquare: Boolean; aSize: Integer; aTerKind: TKMTerrainKind;
                               aRandomTiles, aOverrideCustomTiles: Boolean;
                               aBrushMask: TKMTileMaskKind; aBlendingLvl: Integer; aUseMagicBrush: Boolean);

    function MapTileSet(X, Y, aType, aRotation: Integer): Boolean;
    function MapTilesArraySet(aTiles: array of TKMTerrainTileBrief; aRevertOnFail, aShowDetailedErrors: Boolean): Boolean;
    function MapTilesArraySetS(aTilesS: TAnsiStringArray; aRevertOnFail, aShowDetailedErrors: Boolean): Boolean;
    function MapTileHeightSet(X, Y, Height: Integer): Boolean;
    function MapTileObjectSet(X, Y, Obj: Integer): Boolean;
    function MapTileOverlaySet(X, Y: Integer; aOverlay: TKMTileOverlay; aOverwrite: Boolean): Boolean;

    procedure MarketSetTrade(aMarketID, aFrom, aTo, aAmount: Integer);
    procedure MarketSetTradeEx(aMarketID: Integer; aFrom, aTo: TKMWareType; aAmount: Integer);

    procedure OverlayTextSet(aHand: Shortint; const aText: AnsiString);
    procedure OverlayTextSetFormatted(aHand: Shortint; const aText: AnsiString; aParams: array of const);
    procedure OverlayTextSetFont(aHand: Shortint; aFont: TKMFont);
    procedure OverlayTextSetWordWrap(aHand: Shortint; aWordWrap: Boolean);
    procedure OverlayTextAppend(aHand: Shortint; const aText: AnsiString);
    procedure OverlayTextAppendFormatted(aHand: Shortint; const aText: AnsiString; aParams: array of const);

    procedure Peacetime(aPeacetime: Cardinal);

    function PlanAddField(aHand, X, Y: Integer): Boolean;
    function PlanAddHouse(aHand, aHouseType, X, Y: Integer): Boolean;
    function PlanAddHouseEx(aHand: Integer; aHouseType: TKMHouseType; X, Y: Integer): Boolean;
    function PlanAddRoad(aHand, X, Y: Integer): Boolean;
    function PlanAddWinefield(aHand, X, Y: Integer): Boolean;
    function PlanConnectRoad(aHand, X1, Y1, X2, Y2: Integer; aCompleted: Boolean): Boolean;
    function PlanRemove(aHand, X, Y: Integer): Boolean;

    procedure PlayerAllianceChange(aHand1, aHand2: Byte; aCompliment, aAllied: Boolean);
    procedure PlayerAllianceNFogChange(aHand1, aHand2: Byte; aCompliment, aAllied, aSyncAllyFog: Boolean);
    procedure PlayerAddDefaultGoals(aHand: Byte; aBuildings: Boolean);
    procedure PlayerDefeat(aHand: Integer);
    procedure PlayerGoalsRemoveAll(aHand: Integer; aForAllPlayers: Boolean);
    procedure PlayerShareBeacons(aHand1, aHand2: Integer; aBothWays, aShare: Boolean);
    procedure PlayerShareFog(aHand1, aHand2: Integer; aShare: Boolean);
    procedure PlayerShareFogCompliment(aHand1, aHand2: Integer; aShare: Boolean);
    procedure PlayerWareDistribution(aHand, aWareType, aHouseType, aAmount: Byte);
    procedure PlayerWin(const aVictors: array of Integer; aTeamVictory: Boolean);

    function PlayWAV(aHand: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer;
    function PlayWAVFadeMusic(aHand: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer;
    function PlayWAVAtLocation(aHand: ShortInt; const aFileName: AnsiString; aVolume: Single; aRadius: Single; aX, aY: Integer): Integer;
    function PlayWAVLooped(aHand: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer;
    function PlayWAVAtLocationLooped(aHand: ShortInt; const aFileName: AnsiString; aVolume: Single; aRadius: Single; aX, aY: Integer): Integer;
    procedure StopLoopedWAV(aSoundIndex: Integer);

    function PlayOGG(aHand: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer;
    function PlayOGGFadeMusic(aHand: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer;
    function PlayOGGAtLocation(aHand: ShortInt; const aFileName: AnsiString; aVolume: Single; aRadius: Single; aX, aY: Integer): Integer;
    function PlayOGGLooped(aHand: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer;
    function PlayOGGAtLocationLooped(aHand: ShortInt; const aFileName: AnsiString; aVolume: Single; aRadius: Single; aX, aY: Integer): Integer;
    procedure StopLoopedOGG(aSoundIndex: Integer);

    function PlaySound(aHand: ShortInt; const aFileName: AnsiString; aAudioFormat: TKMAudioFormat; aVolume: Single;
                       aFadeMusic, aLooped: Boolean): Integer;
    function PlaySoundAtLocation(aHand: ShortInt; const aFileName: AnsiString; aAudioFormat: TKMAudioFormat; aVolume: Single;
                                 aFadeMusic, aLooped: Boolean; aRadius: Single; aX, aY: Integer): Integer;
    procedure StopSound(aSoundIndex: Integer);

    procedure RemoveRoad(X, Y: Integer);

    procedure SetTradeAllowed(aHand, aResType: Integer; aAllowed: Boolean);
    procedure ShowMsg(aHand: Shortint; const aText: AnsiString);
    procedure ShowMsgFormatted(aHand: Shortint; const aText: AnsiString; Params: array of const);
    procedure ShowMsgGoto(aHand: Shortint; aX, aY: Integer; const aText: AnsiString);
    procedure ShowMsgGotoFormatted(aHand: Shortint; aX, aY: Integer; const aText: AnsiString; Params: array of const);

    procedure UnitAllowAllyToSelect(aUnitID: Integer; aAllow: Boolean);
    procedure UnitBlock(aHand: Byte; aType: Integer; aBlock: Boolean);
    function  UnitDirectionSet(aUnitID, aDirection: Integer): Boolean;
    function  UnitDirectionSetEx(aUnitID: Integer; aDirection: TKMDirection): Boolean;
    procedure UnitDismiss(aUnitID: Integer);
    procedure UnitDismissableSet(aUnitID: Integer; aDismissable: Boolean);
    procedure UnitDismissCancel(aUnitID: Integer);
    procedure UnitHPChange(aUnitID, aHP: Integer);
    procedure UnitHPSetInvulnerable(aUnitID: Integer; aInvulnerable: Boolean);
    procedure UnitHungerSet(aUnitID, aHungerLevel: Integer);
    procedure UnitKill(aUnitID: Integer; aSilent: Boolean);
    function  UnitOrderWalk(aUnitID: Integer; X, Y: Integer): Boolean;
  end;


implementation
uses
  TypInfo,
  KM_AI, KM_AIDefensePos,
  KM_Game, KM_GameParams, KM_GameTypes, KM_FogOfWar,
  KM_HandsCollection, KM_HandLogistics, KM_HandConstructions,
  KM_HouseBarracks, KM_HouseSchool, KM_HouseStore, KM_HouseMarket, KM_HouseTownHall,
  KM_UnitWarrior,
  KM_UnitGroupTypes,
  KM_Resource, KM_ResUnits, KM_Hand, KM_ResMapElements,
  KM_PathFindingRoad,
  KM_Terrain,
  KM_CommonUtils, KM_CommonClasses;

const
  MIN_SOUND_AT_LOC_RADIUS = 28;

  //We need to check all input parameters as could be wildly off range due to
  //mistakes in scripts. In that case we have two options:
  // - skip silently and log
  // - report to player


function HouseTypeValid(aHouseType: Integer): Boolean; inline;
begin
  Result := (aHouseType in [Low(HOUSE_ID_TO_TYPE)..High(HOUSE_ID_TO_TYPE)])
            and (HOUSE_ID_TO_TYPE[aHouseType] <> htNone); //KaM index 26 is unused (htNone)
end;


{ TKMScriptActions }
//* Version: 5938
//* Puts the player in cinematic mode, blocking user input and allowing the screen to be panned
procedure TKMScriptActions.CinematicStart(aHand: Byte);
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled) then
    begin
      gHands[aHand].InCinematic := True;
      gGame.GamePlayInterface.CinematicUpdate;
    end
    else
      LogIntParamWarn('Actions.CinematicStart', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5938
//* Exits cinematic mode
procedure TKMScriptActions.CinematicEnd(aHand: Byte);
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled) then
    begin
      gHands[aHand].InCinematic := False;
      gGame.GamePlayInterface.CinematicUpdate;
    end
    else
      LogIntParamWarn('Actions.CinematicEnd', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5938
//* Pans the center of the player's screen to the given location over a set number of ticks.
//* If Duration = 0 then the screen moves instantly.
procedure TKMScriptActions.CinematicPanTo(aHand: Byte; X, Y, Duration: Integer);
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
      and gTerrain.TileInMapCoords(X, Y)
      and gHands[aHand].InCinematic then
    begin
      if aHand = gMySpectator.HandID then
        gGame.GamePlayInterface.Viewport.PanTo(KMPointF(X, Y), Duration);
    end
    else
      LogIntParamWarn('Actions.CinematicPanTo', [aHand, X, Y, Duration]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Proclaims player defeated
procedure TKMScriptActions.PlayerDefeat(aHand: Integer);
begin
  try
    //Verify all input parameters
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
      gHands[aHand].AI.Defeat
    else
      LogIntParamWarn('Actions.PlayerDefeat', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Remove all player goals
//* aHand: PlayerID
//* aForAllPlayers: also remove other player goals, related to this player
procedure TKMScriptActions.PlayerGoalsRemoveAll(aHand: Integer; aForAllPlayers: Boolean);
begin
  try
    //Verify all input parameters
    if InRange(aHand, 0, gHands.Count - 1) and gHands[aHand].Enabled then
    begin
      gHands[aHand].AI.Goals.Clear;
      if aForAllPlayers then
        gHands.UpdateGoalsForHand(aHand, False); //Goal disable works as good as delete goal
    end
    else
      LogIntParamWarn('Actions.PlayerGoalsRemoveAll', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Sets whether player A shares his beacons with player B.
//* Sharing can still only happen between allied players, but this command lets you disable allies from sharing.
//* aBothWays: share in both ways
procedure TKMScriptActions.PlayerShareBeacons(aHand1, aHand2: Integer; aBothWays, aShare: Boolean);
begin
  try
    if  InRange(aHand1, 0, gHands.Count - 1)
      and InRange(aHand2, 0, gHands.Count - 1)
      and (gHands[aHand1].Enabled)
      and (gHands[aHand2].Enabled) then
    begin
      gHands[aHand1].ShareBeacons[aHand2] := aShare;
      if aBothWays then
        gHands[aHand2].ShareBeacons[aHand1] := aShare;
    end
    else
      LogIntParamWarn('Actions.PlayerShareBeacons', [aHand1, aHand2, Byte(aBothWays), Byte(aShare)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5345
//* Sets whether player A shares his vision with player B (one way, for both ways use PlayerShareFogCompliment).
//* Sharing can still only happen between allied players, but this command lets you disable allies from sharing.
procedure TKMScriptActions.PlayerShareFog(aHand1, aHand2: Integer; aShare: Boolean);
begin
  try
    if  InRange(aHand1, 0, gHands.Count - 1)
      and InRange(aHand2, 0, gHands.Count - 1)
      and (gHands[aHand1].Enabled)
      and (gHands[aHand2].Enabled) then
      gHands[aHand1].ShareFOW[aHand2] := aShare
    else
      LogIntParamWarn('Actions.PlayerShareFog', [aHand1, aHand2, Byte(aShare)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Sets whether players A and B share their vision (both ways).
//* Sharing can still only happen between allied players, but this command lets you disable allies from sharing.
procedure TKMScriptActions.PlayerShareFogCompliment(aHand1, aHand2: Integer; aShare: Boolean);
begin
  try
    if  InRange(aHand1, 0, gHands.Count - 1)
      and InRange(aHand2, 0, gHands.Count - 1)
      and (gHands[aHand1].Enabled)
      and (gHands[aHand2].Enabled) then
    begin
      gHands[aHand1].ShareFOW[aHand2] := aShare;
      gHands[aHand2].ShareFOW[aHand1] := aShare
    end
    else
      LogIntParamWarn('Actions.PlayerShareFogCompliment', [aHand1, aHand2, Byte(aShare)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Set specified player(s) victorious, and all team members of those player(s) if the 2nd parameter TeamVictory is set to true.
//* All players who were not set to victorious are set to defeated.
//* aVictors: Array of player IDs
//Sets all player IDs in aVictors to victorious, and all their team members if aTeamVictory is true.
//All other players are set to defeated.
procedure TKMScriptActions.PlayerWin(const aVictors: array of Integer; aTeamVictory: Boolean);
var
  I, K: Integer;
begin
  try
    //Verify all input parameters
    for I := 0 to Length(aVictors) - 1 do
      if not InRange(aVictors[I], 0, gHands.Count - 1) then
      begin
        LogIntParamWarn('Actions.PlayerWin', [aVictors[I]]);
        Exit;
      end;

    for I := 0 to Length(aVictors) - 1 do
      if gHands[aVictors[I]].Enabled then
      begin
        gHands[aVictors[I]].AI.Victory;
        if aTeamVictory then
          for K := 0 to gHands.Count - 1 do
            if gHands[K].Enabled and (I <> K) and (gHands[aVictors[I]].Alliances[K] = atAlly) then
              gHands[K].AI.Victory;
      end;

    //All other players get defeated
    for I := 0 to gHands.Count - 1 do
      if gHands[I].Enabled and (gHands[I].AI.WonOrLost = wolNone) then
        gHands[I].AI.Defeat;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5345
//* Sets ware distribution for the specified resource, house and player.
//* aAmount: Distribution amount (0..5)
//* Note: distribution should be set after 1st tick of the game,
//* thus it will not make effect to use it in OnMissionStart event handler
procedure TKMScriptActions.PlayerWareDistribution(aHand, aWareType, aHouseType, aAmount: Byte);
begin
  try
    if (aWareType in [Low(WARE_ID_TO_TYPE) .. High(WARE_ID_TO_TYPE)])
      and (WARE_ID_TO_TYPE[aWareType] in [wtIron, wtCoal, wtTimber, wtCorn])
      and HouseTypeValid(aHouseType)
      and InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
      and InRange(aAmount, 0, 5) then
    begin
      gHands[aHand].Stats.WareDistribution[WARE_ID_TO_TYPE[aWareType], HOUSE_ID_TO_TYPE[aHouseType]] := aAmount;
      gHands[aHand].Houses.UpdateResRequest;
    end
    else
      LogIntParamWarn('Actions.PlayerWareDistribution', [aHand, aWareType, aHouseType, aAmount]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5097
//* Change whether player1 is allied to player2.
//* If Compliment is true, then it is set both ways (so also whether player2 is allied to player1)
//* aCompliment: Both ways
procedure TKMScriptActions.PlayerAllianceChange(aHand1, aHand2: Byte; aCompliment, aAllied: Boolean);
const
  ALLIED: array [Boolean] of TKMAllianceType = (atEnemy, atAlly);
begin
  try
    //Verify all input parameters
    if InRange(aHand1, 0, gHands.Count - 1)
      and InRange(aHand2, 0, gHands.Count - 1)
      and (aHand1 <> aHand2)
      and (gHands[aHand1].Enabled)
      and (gHands[aHand2].Enabled) then
    begin
      gHands[aHand1].Alliances[aHand2] := ALLIED[aAllied];
      if aAllied then
        gHands[aHand2].FogOfWar.SyncFOW(gHands[aHand1].FogOfWar);
      if aCompliment then
      begin
        gHands[aHand2].Alliances[aHand1] := ALLIED[aAllied];
        if aAllied then
          gHands[aHand1].FogOfWar.SyncFOW(gHands[aHand2].FogOfWar);
      end;
    end
    else
      LogIntParamWarn('Actions.PlayerAllianceChange', [aHand1, aHand2, Byte(aCompliment), Byte(aAllied)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Change whether player1 is allied to player2.
//* If Compliment is true, then it is set both ways (so also whether player2 is allied to player1)
//* aCompliment: Both ways
//* aSyncAllyFog: Synchronize allies fogs of war
procedure TKMScriptActions.PlayerAllianceNFogChange(aHand1, aHand2: Byte; aCompliment, aAllied, aSyncAllyFog: Boolean);
const
  ALLIED: array [Boolean] of TKMAllianceType = (atEnemy, atAlly);
begin
  try
    //Verify all input parameters
    if InRange(aHand1, 0, gHands.Count - 1)
      and InRange(aHand2, 0, gHands.Count - 1)
      and (aHand1 <> aHand2)
      and (gHands[aHand1].Enabled)
      and (gHands[aHand2].Enabled) then
    begin
      gHands[aHand1].Alliances[aHand2] := ALLIED[aAllied];
      if aAllied and aSyncAllyFog then
        gHands[aHand2].FogOfWar.SyncFOW(gHands[aHand1].FogOfWar);
      if aCompliment then
      begin
        gHands[aHand2].Alliances[aHand1] := ALLIED[aAllied];
        if aAllied and aSyncAllyFog then
          gHands[aHand1].FogOfWar.SyncFOW(gHands[aHand2].FogOfWar);
      end;
    end
    else
      LogIntParamWarn('Actions.PlayerAllianceNFogChange', [aHand1, aHand2, Byte(aCompliment), Byte(aAllied), Byte(aSyncAllyFog)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5165
//* Add default goals/lost goals for the specified player.
//* If the parameter buildings is true the goals will be important buildings.
//* Otherwise it will be troops.
procedure TKMScriptActions.PlayerAddDefaultGoals(aHand: Byte; aBuildings: Boolean);
begin
  try
    //Verify all input parameters
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled) then
    begin

      gHands[aHand].AI.AddDefaultGoals(aBuildings);
    end
    else
      LogIntParamWarn('Actions.PlayerAddDefaultGoals', [aHand, Byte(aBuildings)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5309
//* Plays WAV audio file.
//* If the player index is -1 the sound will be played to all players.
//* Mono and stereo WAV files are supported.
//* WAV file goes in mission folder named: Mission Name.filename.wav
//* aVolume: Audio level (0.0 to 1.0)
//* Result: SoundIndex of the sound
function TKMScriptActions.PlayWAV(aHand: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer;
begin
  Result := -1;
  try
    if InRange(aVolume, 0, 1) then
      Result := gScriptSounds.AddSound(aHand, aFileName, afWav, KMPOINT_ZERO, False, aVolume, 0, False, False)
    else
      LogIntParamWarn('Actions.PlayWAV: ' + UnicodeString(aFileName), []);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6220
//* Same as PlayWAV except music will fade then mute while the WAV is playing, then fade back in afterwards.
//* You should leave a small gap at the start of your WAV file to give the music time to fade
//* aVolume: Audio level (0.0 to 1.0)
//* Result: SoundIndex of the sound
function TKMScriptActions.PlayWAVFadeMusic(aHand: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer;
begin
  Result := -1;
  try
    if InRange(aVolume, 0, 1) then
      Result := gScriptSounds.AddSound(aHand, aFileName, afWav, KMPOINT_ZERO, False, aVolume, 0, True, False)
    else
      LogIntParamWarn('Actions.PlayWAVFadeMusic: ' + UnicodeString(aFileName), []);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5309
//* Plays WAV audio file at a location on the map.
//* If the player index is -1 the sound will be played to all players.
//* Radius specifies approximately the distance at which the sound can no longer be heard (normal game sounds use radius 32).
//* Only mono WAV files are supported.
//* WAV file goes in mission folder named: Mission Name.filename.wav.
//* Will not play if the location is not revealed to the player.
//* Higher volume range is allowed than PlayWAV as positional sounds are quieter
//* aVolume: Audio level (0.0 to 4.0)
//* aRadius: Radius (minimum 28)
//* Result: SoundIndex of the sound
function TKMScriptActions.PlayWAVAtLocation(aHand: ShortInt; const aFileName: AnsiString; aVolume: Single; aRadius: Single; aX, aY: Integer): Integer;
begin
  Result := -1;
  try
    if InRange(aVolume, 0, 4) and (aRadius >= MIN_SOUND_AT_LOC_RADIUS) and gTerrain.TileInMapCoords(aX,aY) then
      Result := gScriptSounds.AddSound(aHand, aFileName, afWav, KMPoint(aX,aY), True, aVolume, aRadius, False, False)
    else
      LogIntParamWarn('Actions.PlayWAVAtLocation: ' + UnicodeString(aFileName), [aX, aY]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6222
//* Plays looped audio file.
//* If the player index is -1 the sound will be played to all players.
//* Mono or stereo WAV files are supported.
//* WAV file goes in mission folder named: Mission Name.filename.wav.
//* The sound will continue to loop if the game is paused and will restart automatically when the game is loaded.
//* aVolume: Audio level (0.0 to 1.0)
//* Result: SoundIndex of the sound
function TKMScriptActions.PlayWAVLooped(aHand: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer;
begin
  try
    Result := -1;
    if InRange(aVolume, 0, 1) then
      Result := gScriptSounds.AddSound(aHand, aFileName, afWav, KMPOINT_ZERO, False, aVolume, 0, False, True)
    else
      LogIntParamWarn('Actions.PlayWAVLooped: ' + UnicodeString(aFileName), []);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6222
//* Plays looped WAV audio file at a location on the map.
//* If the player index is -1 the sound will be played to all players.
//* aRadius specifies approximately the distance at which the sound can no longer be heard (normal game sounds use aRadius 32).
//* Only mono WAV files are supported.
//* WAV file goes in mission folder named: Mission Name.filename.wav.
//* Will not play if the location is not revealed to the player (will start playing automatically when it is revealed).
//* Higher aVolume range is allowed than PlayWAV as positional sounds are quieter.
//* The sound will continue to loop if the game is paused and will restart automatically when the game is loaded.
//* aVolume: Audio level (0.0 to 4.0)
//* aRadius: aRadius (minimum 28)
//* Result: SoundIndex of the sound
function TKMScriptActions.PlayWAVAtLocationLooped(aHand: ShortInt; const aFileName: AnsiString; aVolume: Single; aRadius: Single; aX, aY: Integer): Integer;
begin
  try
    Result := -1;
    if InRange(aVolume, 0, 4) and (aRadius >= MIN_SOUND_AT_LOC_RADIUS) and gTerrain.TileInMapCoords(aX,aY) then
      Result := gScriptSounds.AddSound(aHand, aFileName, afWav, KMPoint(aX,aY), True, aVolume, aRadius, False, True)
    else
      LogIntParamWarn('Actions.PlayWAVAtLocationLooped: ' + UnicodeString(aFileName), [aX, aY]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6222
//* Stops playing a looped sound that was previously started with either Actions.PlayWAVLooped or Actions.PlayWAVAtLocationLooped.
//* aSoundIndex: value that was returned by either of those functions when the looped sound was started.
procedure TKMScriptActions.StopLoopedWAV(aSoundIndex: Integer);
begin
  try
    if aSoundIndex > 0 then
      gScriptSounds.RemoveLoopSoundByUID(aSoundIndex)
    else
      LogIntParamWarn('Actions.StopLoopedWAV', [aSoundIndex]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Plays OGG audio file.
//* If the player index is -1 the sound will be played to all players.
//* Mono and stereo OGG files are supported.
//* OGG file goes in mission folder named: Mission Name.filename.ogg
//* aVolume: Audio level (0.0 to 1.0)
//* Result: SoundIndex of the sound
function TKMScriptActions.PlayOGG(aHand: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer;
begin
  Result := -1;
  try
    if InRange(aVolume, 0, 1) then
      Result := gScriptSounds.AddSound(aHand, aFileName, afOgg, KMPOINT_ZERO, False, aVolume, 0, False, False)
    else
      LogIntParamWarn('Actions.PlayOGG: ' + UnicodeString(aFileName), []);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Same as PlayOGG except music will fade then mute while the OGG is playing, then fade back in afterwards.
//* You should leave a small gap at the start of your OGG file to give the music time to fade
//* aVolume: Audio level (0.0 to 1.0)
//* Result: SoundIndex of the sound
function TKMScriptActions.PlayOGGFadeMusic(aHand: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer;
begin
  Result := -1;
  try
    if InRange(aVolume, 0, 1) then
      Result := gScriptSounds.AddSound(aHand, aFileName, afOgg, KMPOINT_ZERO, False, aVolume, 0, True, False)
    else
      LogIntParamWarn('Actions.PlayOGGFadeMusic: ' + UnicodeString(aFileName), []);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Plays OGG audio file at a location on the map.
//* If the player index is -1 the sound will be played to all players.
//* Radius specifies approximately the distance at which the sound can no longer be heard (normal game sounds use radius 32).
//* Only mono OGG files are supported.
//* OGG file goes in mission folder named: Mission Name.filename.ogg.
//* Will not play if the location is not revealed to the player.
//* Higher volume range is allowed than PlayOGG as positional sounds are quieter
//* aVolume: Audio level (0.0 to 4.0)
//* aRadius: Radius (minimum 28)
//* Result: SoundIndex of the sound
function TKMScriptActions.PlayOGGAtLocation(aHand: ShortInt; const aFileName: AnsiString; aVolume: Single; aRadius: Single; aX, aY: Integer): Integer;
begin
  Result := -1;
  try
    if InRange(aVolume, 0, 4) and (aRadius >= MIN_SOUND_AT_LOC_RADIUS) and gTerrain.TileInMapCoords(aX,aY) then
      Result := gScriptSounds.AddSound(aHand, aFileName, afOgg, KMPoint(aX,aY), True, aVolume, aRadius, False, False)
    else
      LogIntParamWarn('Actions.PlayOGGAtLocation: ' + UnicodeString(aFileName), [aX, aY]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Plays looped OGG audio file.
//* If the player index is -1 the sound will be played to all players.
//* Mono or stereo OGG files are supported.
//* OGG file goes in mission folder named: Mission Name.filename.ogg.
//* The sound will continue to loop if the game is paused and will restart automatically when the game is loaded.
//* aVolume: Audio level (0.0 to 1.0)
//* Result: SoundIndex of the sound
function TKMScriptActions.PlayOGGLooped(aHand: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer;
begin
  try
    Result := -1;
    if InRange(aVolume, 0, 1) then
      Result := gScriptSounds.AddSound(aHand, aFileName, afOgg, KMPOINT_ZERO, False, aVolume, 0, False, True)
    else
      LogIntParamWarn('Actions.PlayOGGLooped: ' + UnicodeString(aFileName), []);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Plays looped audio file at a location on the map.
//* If the player index is -1 the sound will be played to all players.
//* aRadius specifies approximately the distance at which the sound can no longer be heard (normal game sounds use aRadius 32).
//* Only mono OGG files are supported.
//* OGG file goes in mission folder named: Mission Name.filename.ogg.
//* Will not play if the location is not revealed to the player (will start playing automatically when it is revealed).
//* Higher aVolume range is allowed than PlayOGG as positional sounds are quieter.
//* The sound will continue to loop if the game is paused and will restart automatically when the game is loaded.
//* aVolume: Audio level (0.0 to 4.0)
//* aRadius: aRadius (minimum 28)
//* Result: SoundIndex of the sound
function TKMScriptActions.PlayOGGAtLocationLooped(aHand: ShortInt; const aFileName: AnsiString; aVolume: Single; aRadius: Single; aX, aY: Integer): Integer;
begin
  try
    Result := -1;
    if InRange(aVolume, 0, 4) and (aRadius >= MIN_SOUND_AT_LOC_RADIUS) and gTerrain.TileInMapCoords(aX,aY) then
      Result := gScriptSounds.AddSound(aHand, aFileName, afOgg, KMPoint(aX,aY), True, aVolume, aRadius, False, True)
    else
      LogIntParamWarn('Actions.PlayOGGAtLocationLooped: ' + UnicodeString(aFileName), [aX, aY]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Stops playing a looped sound that was previously started with either Actions.PlayOGGLooped or Actions.PlayOGGAtLocationLooped.
//* aSoundIndex: value that was returned by either of those functions when the looped sound was started.
procedure TKMScriptActions.StopLoopedOGG(aSoundIndex: Integer);
begin
  try
    if aSoundIndex > 0 then
      gScriptSounds.RemoveLoopSoundByUID(aSoundIndex)
    else
      LogIntParamWarn('Actions.StopLoopedOGG', [aSoundIndex]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Plays audio file.
//* If the player index is -1 the sound will be played to all players.
//* Possible to specify Looped or FadeMusic parameter
//* Mono and stereo WAV and OGG files are supported.
//* To specify audio format use afWav or afOgg
//* WAV file goes in mission folder named: Mission Name.filename.wav.
//* OGG file goes in mission folder named: Mission Name.filename.ogg
//* If MusicFaded then sound will fade then mute while the file is playing, then fade back in afterwards.
//* If looped, the sound will continue to loop if the game is paused and will restart automatically when the game is loaded.
//* aAudioFormat: afWav or afOgg
//* aVolume: Audio level (0.0 to 1.0)
//* Result: SoundIndex of the sound
function TKMScriptActions.PlaySound(aHand: ShortInt; const aFileName: AnsiString; aAudioFormat: TKMAudioFormat; aVolume: Single; aFadeMusic, aLooped: Boolean): Integer;
begin
  try
    Result := -1;
    if InRange(aVolume, 0, 1) then
      Result := gScriptSounds.AddSound(aHand, aFileName, aAudioFormat, KMPOINT_ZERO, False, aVolume, 0, aFadeMusic, aLooped)
    else
      LogIntParamWarn('Actions.PlaySound: ' + UnicodeString(aFileName), []);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Plays audio file at a location on the map.
//* If the player index is -1 the sound will be played to all players.
//* Possible to specify Looped or FadeMusic parameter
//* aRadius specifies approximately the distance at which the sound can no longer be heard (normal game sounds use aRadius 32).
//* Only mono WAV or OGG files are supported.
//* To specify audio format use afWav or afOgg
//* WAV file goes in mission folder named: Mission Name.filename.wav.
//* OGG file goes in mission folder named: Mission Name.filename.ogg.
//* Will not play if the location is not revealed to the player (will start playing automatically when it is revealed).
//* Higher aVolume range is allowed than PlaySound as positional sounds are quieter.
//* If looped, the sound will continue to loop if the game is paused and will restart automatically when the game is loaded.
//* aAudioFormat: afWav or afOgg
//* aVolume: Audio level (0.0 to 4.0)
//* aRadius: aRadius (minimum 28)
//* Result: SoundIndex of the sound
function TKMScriptActions.PlaySoundAtLocation(aHand: ShortInt; const aFileName: AnsiString; aAudioFormat: TKMAudioFormat; aVolume: Single; aFadeMusic, aLooped: Boolean; aRadius: Single; aX, aY: Integer): Integer;
begin
  try
    Result := -1;
    if InRange(aVolume, 0, 4) and (aRadius >= MIN_SOUND_AT_LOC_RADIUS) and gTerrain.TileInMapCoords(aX,aY) then
      Result := gScriptSounds.AddSound(aHand, aFileName, aAudioFormat, KMPoint(aX,aY), True, aVolume, aRadius, aFadeMusic, aLooped)
    else
      LogIntParamWarn('Actions.PlaySoundAtLocation: ' + UnicodeString(aFileName), [aX, aY]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Stops playing any sound that was previously started by any of PlayWAV***, PlayOGG*** or PlaySound*** functions
//* aSoundIndex: value that was returned by either of those functions when the sound was started.
procedure TKMScriptActions.StopSound(aSoundIndex: Integer);
begin
  try
    if aSoundIndex > 0 then
      gScriptSounds.RemoveSoundByUID(aSoundIndex)
    else
      LogIntParamWarn('Actions.StopSound', [aSoundIndex]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5927
//* Removes road
procedure TKMScriptActions.RemoveRoad(X, Y: Integer);
var
  Pos: TKMPoint;
begin
  try
    Pos := KMPoint(X, Y);
    if gTerrain.TileInMapCoords(X, Y) then
    begin
      //Can't remove if tile is locked (house or roadwork)
      if (gTerrain.Land^[Y, X].TileOverlay = toRoad) and (gTerrain.Land^[Y, X].TileLock = tlNone) then
        gTerrain.RemRoad(Pos);
    end
    else
      LogIntParamWarn('Actions.RemoveRoad', [X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Give player group of warriors and return the group ID or -1 if the group was not able to be added
//* aColumns: Units per row
function TKMScriptActions.GiveGroup(aHand, aType, X,Y, aDir, aCount, aColumns: Integer): Integer;
var
  G: TKMUnitGroup;
begin
  try
    Result := UID_NONE;
    //Verify all input parameters
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
    and (aType in [UNIT_TYPE_TO_ID[WARRIOR_MIN]..UNIT_TYPE_TO_ID[WARRIOR_MAX]])
    and gTerrain.TileInMapCoords(X,Y)
    and (TKMDirection(aDir+1) in [dirN..dirNW])
    and (aCount > 0)
    and (aColumns > 0) then
    begin
      G := gHands[aHand].AddUnitGroup(UNIT_ID_TO_TYPE[aType],
                                          KMPoint(X,Y),
                                          TKMDirection(aDir+1),
                                          aColumns,
                                          aCount);
      if G = nil then Exit;
      Result := G.UID;
    end
    else
      LogIntParamWarn('Actions.GiveGroup', [aHand, aType, X, Y, aDir, aCount, aColumns]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Give player group of warriors and return the group ID or -1 if the group was not able to be added
//* aColumns: Units per row
function TKMScriptActions.GiveGroupEx(aHand: Integer; aType: TKMUnitType; X,Y: Integer; aDir: TKMDirection; aCount, aColumns: Integer): Integer;
var
  G: TKMUnitGroup;
begin
  try
    Result := UID_NONE;
    //Verify all input parameters
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
    and (aType in UNITS_WARRIORS)
    and gTerrain.TileInMapCoords(X,Y)
    and (aDir in [dirN..dirNW])
    and (aCount > 0)
    and (aColumns > 0) then
    begin
      G := gHands[aHand].AddUnitGroup(aType, KMPoint(X,Y), aDir, aColumns, aCount);
      if G = nil then Exit;
      Result := G.UID;
    end
    else
      LogParamWarn('Actions.GiveGroupEx', [aHand, GetEnumName(TypeInfo(TKMUnitType), Integer(aType)), X, Y,
                                           GetEnumName(TypeInfo(TKMDirection), Integer(aDir)), aCount, aColumns]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Give player a single citizen and returns the unit ID or -1 if the unit was not able to be added
function TKMScriptActions.GiveUnit(aHand, aType, X, Y, aDir: Integer): Integer;
var
  U: TKMUnit;
begin
  try
    Result := UID_NONE;

    //Verify all input parameters
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
    and (aType in [UNIT_TYPE_TO_ID[CITIZEN_MIN] .. UNIT_TYPE_TO_ID[CITIZEN_MAX]])
    and gTerrain.TileInMapCoords(X, Y)
    and (TKMDirection(aDir + 1) in [dirN .. dirNW]) then
    begin
      U := gHands[aHand].AddUnit(UNIT_ID_TO_TYPE[aType], KMPoint(X,Y));
      if U = nil then Exit;
      Result := U.UID;
      U.Direction := TKMDirection(aDir + 1);
    end
    else
      LogIntParamWarn('Actions.GiveUnit', [aHand, aType, X, Y, aDir]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Give player a single citizen and returns the unit ID or -1 if the unit was not able to be added
function TKMScriptActions.GiveUnitEx(aHand: Integer; aType: TKMUnitType; X,Y: Integer; aDir: TKMDirection): Integer;
var
  U: TKMUnit;
begin
  try
    Result := UID_NONE;

    //Verify all input parameters
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
    and (aType in UNITS_CITIZEN)
    and gTerrain.TileInMapCoords(X, Y)
    and (aDir in [dirN .. dirNW]) then
    begin
      U := gHands[aHand].AddUnit(aType, KMPoint(X,Y));
      if U = nil then Exit;
      Result := U.UID;
      U.Direction := aDir;
    end
    else
      LogParamWarn('Actions.GiveUnitEx', [aHand, GetEnumName(TypeInfo(TKMUnitType), Integer(aType)),
                                          X, Y, GetEnumName(TypeInfo(TKMDirection), Integer(aDir))]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5097
//* Give player a built house and returns the house ID or -1 if the house was not able to be added
function TKMScriptActions.GiveHouse(aHand, aHouseType, X,Y: Integer): Integer;
var
  H: TKMHouse;
begin
  try
    Result := UID_NONE;

    //Verify all input parameters
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
    and HouseTypeValid(aHouseType)
    and gTerrain.TileInMapCoords(X, Y) then
    begin
      if gTerrain.CanPlaceHouseFromScript(HOUSE_ID_TO_TYPE[aHouseType], KMPoint(X - gResHouses[HOUSE_ID_TO_TYPE[aHouseType]].EntranceOffsetX, Y)) then
      begin
        H := gHands[aHand].AddHouse(HOUSE_ID_TO_TYPE[aHouseType], X, Y, True);
        if H = nil then Exit;
        Result := H.UID;
      end;
    end
    else
      LogIntParamWarn('Actions.GiveHouse', [aHand, aHouseType, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Give player a built house and returns the house ID or -1 if the house was not able to be added
function TKMScriptActions.GiveHouseEx(aHand: Integer; aHouseType: TKMHouseType; X,Y: Integer): Integer;
var
  H: TKMHouse;
begin
  try
    Result := UID_NONE;

    //Verify all input parameters
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
      and (aHouseType in HOUSES_VALID)
      and gTerrain.TileInMapCoords(X, Y) then
    begin
      if gTerrain.CanPlaceHouseFromScript(aHouseType, KMPoint(X - gResHouses[aHouseType].EntranceOffsetX, Y)) then
      begin
        H := gHands[aHand].AddHouse(aHouseType, X, Y, True);
        if H = nil then Exit;
        Result := H.UID;
      end;
    end
    else
      LogParamWarn('Actions.GiveHouseEx', [aHand, GetEnumName(TypeInfo(TKMHouseType), Integer(aHouseType)), X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6288
//* Give player a digged house area and returns House ID or -1 if house site was not able to be added.
//* If AddMaterials = True, wood and stone will be added
function TKMScriptActions.GiveHouseSite(aHand, aHouseType, X, Y: Integer; aAddMaterials: Boolean): Integer;
var
  H: TKMHouse;
  I, K: Integer;
  HA: THouseArea;
  nonEntranceX: Integer;
begin
  try
    Result := -1;
    if InRange(aHand, 0, gHands.Count - 1)
    and (gHands[aHand].Enabled)
    and HouseTypeValid(aHouseType)
    and gTerrain.TileInMapCoords(X,Y) then
    begin
      nonEntranceX := X - gResHouses[HOUSE_ID_TO_TYPE[aHouseType]].EntranceOffsetX;
      if gTerrain.CanPlaceHouseFromScript(HOUSE_ID_TO_TYPE[aHouseType], KMPoint(nonEntranceX, Y)) then
      begin
        H := gHands[aHand].AddHouseWIP(HOUSE_ID_TO_TYPE[aHouseType], KMPoint(nonEntranceX, Y));
        if (H = nil) or (H.IsDestroyed) then
          Exit;

        Result := H.UID;
        HA := gResHouses[H.HouseType].BuildArea;
        for I := 1 to 4 do
        for K := 1 to 4 do
          if HA[I, K] <> 0 then
          begin
            gTerrain.RemoveObject(KMPoint(nonEntranceX + K - 3, Y + I - 4));
            gTerrain.FlattenTerrain(KMPoint(nonEntranceX + K - 3, Y + I - 4));
            gTerrain.SetTileLock(KMPoint(nonEntranceX + K - 3, Y + I - 4), tlDigged);
          end;

        gTerrain.SetRoad(H.Entrance, aHand);
        H.BuildingState := hbsWood;
        if aAddMaterials then
        begin
          H.ResAddToBuild(wtTimber, gResHouses[H.HouseType].WoodCost);
          H.ResAddToBuild(wtStone, gResHouses[H.HouseType].StoneCost);
        end
        else
        begin
          gHands[aHand].Deliveries.Queue.AddDemand(H, nil, wtTimber, gResHouses[H.HouseType].WoodCost, dtOnce, diHigh4);
          gHands[aHand].Deliveries.Queue.AddDemand(H, nil, wtStone, gResHouses[H.HouseType].StoneCost, dtOnce, diHigh4);
        end;
        gHands[aHand].Constructions.HouseList.AddHouse(H);
      end;
    end
    else
      LogIntParamWarn('Actions.GiveHouseSite', [aHand, aHouseType, X, Y, byte(aAddMaterials)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Give player a digged house area and returns House ID or -1 if house site was not able to be added.
//* aStoneAmount: number of resources to be added to the site
//* aWoodAmount: number of resources to be added to the site
function TKMScriptActions.GiveHouseSiteEx(aHand: Integer; aHouseType: TKMHouseType; X, Y, aWoodAmount, aStoneAmount: Integer): Integer;
var
  H: TKMHouse;
  I, K: Integer;
  HA: THouseArea;
  nonEntranceX: Integer;
begin
  try
    Result := -1;
    if InRange(aHand, 0, gHands.Count - 1)
      and (gHands[aHand].Enabled)
      and (aHouseType in HOUSES_VALID)
      and gTerrain.TileInMapCoords(X,Y) then
    begin
      nonEntranceX := X - gResHouses[aHouseType].EntranceOffsetX;
      if gTerrain.CanPlaceHouseFromScript(aHouseType, KMPoint(nonEntranceX, Y)) then
      begin
        H := gHands[aHand].AddHouseWIP(aHouseType, KMPoint(nonEntranceX, Y));
        if (H = nil) or (H.IsDestroyed) then
          Exit;

        Result := H.UID;
        HA := gResHouses[aHouseType].BuildArea;
        for I := 1 to 4 do
        for K := 1 to 4 do
          if HA[I, K] <> 0 then
          begin
            gTerrain.RemoveObject(KMPoint(nonEntranceX + K - 3, Y + I - 4));
            gTerrain.FlattenTerrain(KMPoint(nonEntranceX + K - 3, Y + I - 4));
            gTerrain.SetTileLock(KMPoint(nonEntranceX + K - 3, Y + I - 4), tlDigged);
          end;

        gTerrain.SetRoad(H.Entrance, aHand);
        H.BuildingState := hbsWood;

        // Add wood
        aWoodAmount := EnsureRange(aWoodAmount, 0, gResHouses[aHouseType].WoodCost);
        H.ResAddToBuild(wtTimber, aWoodAmount);
        gHands[aHand].Deliveries.Queue.AddDemand(H, nil, wtTimber, gResHouses[aHouseType].WoodCost - aWoodAmount, dtOnce, diHigh4);

        // Add stones
        aStoneAmount := EnsureRange(aStoneAmount, 0, gResHouses[aHouseType].StoneCost);
        H.ResAddToBuild(wtStone, aStoneAmount);
        gHands[aHand].Deliveries.Queue.AddDemand(H, nil, wtStone, gResHouses[aHouseType].StoneCost - aStoneAmount, dtOnce, diHigh4);

        gHands[aHand].Constructions.HouseList.AddHouse(H);
      end;
    end
    else
      LogParamWarn('Actions.GiveHouseSiteEx', [aHand, GetEnumName(TypeInfo(TKMHouseType), Integer(aHouseType)), X, Y, aWoodAmount, aStoneAmount]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Sets AI army type
//* aType: (atIronThenLeather, atLeather, atIron, atIronAndLeather)
procedure TKMScriptActions.AIArmyType(aHand: Byte; aType: TKMArmyType);
begin
  try
    if InRange(aHand, 0, gHands.Count - 1)
      and (gHands[aHand].Enabled)
      and (aType in [Low(TKMArmyType)..High(TKMArmyType)]) then
      gHands[aHand].AI.Setup.ArmyType := aType
    else
      LogIntParamWarn('Actions.AIArmyType', [aHand, Byte(aType)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Add AI attack 
//* aHand: handID
//* aRepeating: is attack repeating
//* aDelay: attack delay from the game start (in ticks)
//* aTotalMen: total soldiers to attack
//* aMeleeGroupCount, aAntiHorseGroupCount, aRangedGroupCount, aMountedGroupCount: soldiers groups count
//* aRandomGroups:  use random groups for attack
//* aTarget: attack target of TKMAIAttackTarget type
//* aCustomPosition: custom position of attack. Used if attCustomPosition was set up as attack target
//* Result: Attack UID, that could be used to remove this attack later on
function TKMScriptActions.AIAttackAdd(aHand: Integer; aRepeating: Boolean; aDelay: Cardinal; aTotalMen: Integer;
                                      aMeleeGroupCount, aAntiHorseGroupCount, aRangedGroupCount, aMountedGroupCount: Integer; aRandomGroups: Boolean;
                                      aTarget: TKMAIAttackTarget; aCustomPosition: TKMPoint): Integer;
var
  attackType: TKMAIAttackType;
begin
  Result := NO_SUCCESS_INT;
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled) then
    begin
      if aRepeating then
        attackType := aatRepeating
      else
        attackType := aatOnce;

      //Attack delay should be counted from the moment attack was added from script
      Result := gHands[aHand].AI.General.Attacks.AddAttack(attackType, aDelay, aTotalMen, aMeleeGroupCount, aAntiHorseGroupCount,
                                                             aRangedGroupCount, aMountedGroupCount, aRandomGroups, aTarget, 0, aCustomPosition);
    end else
      LogIntParamWarn('Actions.AIAttackAdd', [aHand, aDelay, aTotalMen, aMeleeGroupCount, aAntiHorseGroupCount, aRangedGroupCount, aMountedGroupCount]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Add AI attack for a specified hand (player)
//* Attack info is set via TKMAIAttackInfo record.
//* Result: Attack UID, that could be used to remove this attack later on
function TKMScriptActions.AIAttackAddEx(aHand: Integer; var aAttackInfo: TKMAIAttackInfo): Integer;
begin
  Result := NO_SUCCESS_INT;
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled) then
    begin
      Result := gHands[aHand].AI.General.Attacks.AddAttack( aAttackInfo.AttackType,
                                                            aAttackInfo.Delay,
                                                            aAttackInfo.TotalMen,
                                                            aAttackInfo.MeleeGroupCount,
                                                            aAttackInfo.AntiHorseGroupCount,
                                                            aAttackInfo.RangedGroupCount,
                                                            aAttackInfo.MountedGroupCount,
                                                            aAttackInfo.RandomGroups,
                                                            aAttackInfo.Target, 0,
                                                            aAttackInfo.CustomPosition);
      aAttackInfo.UID := Result;
    end else
      LogParamWarn('Actions.AIAttackAddEx', [aHand, aAttackInfo.ToStr]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Remove AI attack by attack UID
//* Result: true, if attack was succesfully removed, false, if attack was not found
function TKMScriptActions.AIAttackRemove(aHand, aAIAttackUID: Integer): Boolean;
begin
  Result := False;
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled) then
      Result := gHands[aHand].AI.General.Attacks.Remove(aAIAttackUID)
    else
      LogIntParamWarn('Actions.AIAttackRemove', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Remove all AI attacks
procedure TKMScriptActions.AIAttackRemoveAll(aHand: Integer);
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled) then
      gHands[aHand].AI.General.Attacks.Clear
    else
      LogIntParamWarn('Actions.AIAttackRemoveAll', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13000
//* Sets AI auto attack
procedure TKMScriptActions.AIAutoAttack(aHand: Byte; aAutoAttack: Boolean);
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled) then
      gHands[aHand].AI.Setup.AutoAttack := aAutoAttack
    else
      LogIntParamWarn('Actions.AIAutoAttack', [aHand, Byte(aAutoAttack)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6251
//* Sets AI auto attack range.
//* AI groups will automatically attack if you are closer than this many tiles.
//* aRange: Range (1 to 20)
procedure TKMScriptActions.AIAutoAttackRange(aHand: Byte; aRange: Integer);
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
      and InRange(aRange, 1, 20)
      and not gHands[aHand].AI.Setup.NewAI then // Do not allow AutoAttackRange if we are using newAI
      gHands[aHand].AI.Setup.AutoAttackRange := aRange
    else
      LogIntParamWarn('Actions.AIAutoAttackRange', [aHand, aRange]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5924
//* Sets whether the AI should build and manage his own village
procedure TKMScriptActions.AIAutoBuild(aHand: Byte; aAuto: Boolean);
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled) then
      gHands[aHand].AI.Setup.AutoBuild := aAuto
    else
      LogIntParamWarn('Actions.AIAutoBuild', [aHand, Byte(aAuto)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5924
//* Sets whether the AI should position his soldiers automatically
procedure TKMScriptActions.AIAutoDefence(aHand: Byte; aAuto: Boolean);
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled) then
      gHands[aHand].AI.Setup.AutoDefend := aAuto
    else
      LogIntParamWarn('Actions.AIAutoDefence', [aHand, Byte(aAuto)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5932
//* Sets whether the AI should automatically repair damaged buildings
procedure TKMScriptActions.AIAutoRepair(aHand: Byte; aAuto: Boolean);
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled) then
    begin
      if aAuto then
        gHands[aHand].AI.Setup.RepairMode := rmRepairAlways
      else
        gHands[aHand].AI.Setup.RepairMode := rmRepairNever;
    end
    else
      LogIntParamWarn('Actions.AIAutoRepair', [aHand, Byte(aAuto)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


function TKMScriptActions._AIDefencePositionAdd(aHand: Integer; aOrder: Integer; const aDefencePosition: TKMDefencePositionInfo): Integer;
var
  cnt: Integer;
begin
  Result := NO_SUCCESS_INT;

  if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
    and (aDefencePosition.Radius >= 0)
    and (aDefencePosition.PositionType in [dtFrontLine..dtBackLine])
    and (aDefencePosition.Dir in [dirN..dirNW])
    and (aDefencePosition.GroupType in GROUP_TYPES_VALID)
    and (gTerrain.TileInMapCoords(aDefencePosition.X, aDefencePosition.Y)) then
  begin
    cnt := gHands[aHand].AI.General.DefencePositions.Count;

    // Add position anyway, at least to the end of the list
    if not InRange(aOrder, 0, cnt) then
      aOrder := cnt;

    Result := gHands[aHand].AI.General.DefencePositions.Insert(aOrder, KMPointDir(aDefencePosition.X, aDefencePosition.Y, aDefencePosition.Dir),
                                                                 aDefencePosition.GroupType, aDefencePosition.Radius, aDefencePosition.PositionType);
  end;
end;


//* Version: 5932
//* Adds a defence position for the specified AI player
//* Returns added defence position UID or -1 if it could not be added
function TKMScriptActions.AIDefencePositionAdd(aHand: Byte; X, Y: Integer; aDir, aGroupType: Byte; aRadius: Integer; aDefType: Byte): Integer;
var
  defPos: TKMDefencePositionInfo;
begin
  Result := NO_SUCCESS_INT;
  try
    if InRange(aGroupType, 0, 3)
      and InRange(aDir, 0, Ord(High(TKMDirection)) - 1)
      and InRange(aDefType, 0, 1)
      and (TKMDirection(aDir + 1) in [dirN..dirNW])
      and (gTerrain.TileInMapCoords(X, Y)) then
    begin
      defPos.X := X;
      defPos.Y := Y;
      defPos.Dir := TKMDirection(aDir + 1);
      defPos.Radius := aRadius;
      defPos.GroupType := TKMGroupType(aGroupType + GROUP_TYPE_MIN_OFF);
      defPos.PositionType := TKMAIDefencePosType(aDefType);

      // Add defence position at the end of the list
      Result := _AIDefencePositionAdd(aHand, gHands[aHand].AI.General.DefencePositions.Count, defPos);
    end;

    if Result = NO_SUCCESS_INT then
      LogIntParamWarn('Actions.AIDefencePositionAdd', [aHand, X, Y, aDir, aGroupType, aRadius, aDefType]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Adds a defence position for the specified AI player
//* aHand: hand (player) ID
//* aOrder: order (or priority) of the defence position.
//* If aOrder is not in range of [0; Count], then position would be added to the end of the list
//* Returns added defence position UID or -1 if it could not be added
function TKMScriptActions.AIDefencePositionAddEx(aHand, aOrder: Integer; var aDefencePosition: TKMDefencePositionInfo): Integer;
begin
  try
    Result := _AIDefencePositionAdd(aHand, aOrder, aDefencePosition);
    aDefencePosition.UID := Result;
    if Result = NO_SUCCESS_INT then
      LogParamWarn('Actions.AIDefencePositionAddEx', [aHand, aOrder, 'DefPos: ' + aDefencePosition.ToStr]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6309
//* Removes defence position at X, Y
procedure TKMScriptActions.AIDefencePositionRemove(aHand: Byte; X, Y: Integer);
var
  I: Integer;
  DP: TAIDefencePosition;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1)
    and (gHands[aHand].Enabled)
    and gTerrain.TileInMapCoords(X, Y) then
      for I := gHands[aHand].AI.General.DefencePositions.Count - 1 downto 0 do
      begin
        DP := gHands[aHand].AI.General.DefencePositions.Positions[I];
        if DP <> nil then
          if (DP.Position.Loc.X = X)
          and (DP.Position.Loc.Y = Y) then
            gHands[aHand].AI.General.DefencePositions.Delete(I);
      end
  else
    LogIntParamWarn('Actions.AIDefencePositionRemove', [aHand, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6323
//* Removes all defence positions for specified AI player
procedure TKMScriptActions.AIDefencePositionRemoveAll(aHand: Byte);
var
  I: Integer;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1)
    and (gHands[aHand].Enabled) then
      for I := gHands[aHand].AI.General.DefencePositions.Count - 1 downto 0 do
        gHands[aHand].AI.General.DefencePositions.Delete(I)
    else
      LogIntParamWarn('Actions.AIDefencePositionRemoveAll', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Removes defence position by its UID
procedure TKMScriptActions.AIDefencePositionRemoveByUID(aHand, aUID: Integer);
var
  I: Integer;
  DP: TAIDefencePosition;
begin
  try
    if InRange(aHand, 0, gHands.Count - 1)
      and (gHands[aHand].Enabled) then
      for I := gHands[aHand].AI.General.DefencePositions.Count - 1 downto 0 do
      begin
        DP := gHands[aHand].AI.General.DefencePositions.Positions[I];
        if (DP <> nil) and (DP.UID = aUID) then
            gHands[aHand].AI.General.DefencePositions.Delete(I);
      end
  else
    LogIntParamWarn('Actions.AIDefencePositionRemoveByUID', [aHand, aUID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6251
//* Sets whether AI should defend units and houses of allies as if they were its own
procedure TKMScriptActions.AIDefendAllies(aHand: Byte; aDefend: Boolean);
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled) then
      gHands[aHand].AI.Setup.DefendAllies := aDefend
    else
      LogIntParamWarn('Actions.AIDefendAllies', [aHand, Byte(aDefend)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5778
//* Sets the warriors equip rate for AI.
//* aType: type: 0 - leather, 1 - iron
procedure TKMScriptActions.AIEquipRate(aHand: Byte; aType: Byte; aRate: Integer);
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled) then
      case aType of
        0:    gHands[aHand].AI.Setup.EquipRateLeather := aRate;
        1:    gHands[aHand].AI.Setup.EquipRateIron := aRate;
        else  LogIntParamWarn('Actions.AIEquipRate, unknown type', [aHand, aType, aRate]);
      end
    else
      LogIntParamWarn('Actions.AIEquipRate', [aHand, aType, aRate]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


function TKMScriptActions._AIGroupsFormationSet(aHand: Integer; aGroupType: TKMGroupType; aCount, aColumns: Integer): Boolean;
begin
  Result := False;
  if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
    and (aGroupType in GROUP_TYPES_VALID)
    and (aCount > 0) and (aColumns > 0) then
  begin
    gHands[aHand].AI.General.DefencePositions.TroopFormations[aGroupType].NumUnits := aCount;
    gHands[aHand].AI.General.DefencePositions.TroopFormations[aGroupType].UnitsPerRow := aColumns;
    Result := True;
  end;
end;


//* Version: 5778
//* Sets the formation the AI uses for defence positions. Works only for ClassicAI
procedure TKMScriptActions.AIGroupsFormationSet(aHand, aType: Byte; aCount, aColumns: Integer);
var
  gt: TKMGroupType;
begin
  try
    gt := gtNone;
    if InRange(aType, 0, 3) then
      gt := TKMGroupType(aType + GROUP_TYPE_MIN_OFF);

    if not _AIGroupsFormationSet(aHand, gt, aCount, aColumns) then
      LogIntParamWarn('Actions.AIGroupsFormationSet', [aHand, aType, aCount, aColumns]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Sets the formation the AI uses for defence positions. Works only for ClassicAI
//* aHand: hand (player) ID
procedure TKMScriptActions.AIGroupsFormationSetEx(aHand: Integer; aGroupType: TKMGroupType; aCount, aColumns: Integer);
begin
  try
    if not _AIGroupsFormationSet(aHand, aGroupType, aCount, aColumns) then
      LogParamWarn('Actions.AIGroupsFormationSetEx', [aHand, GetEnumName(TypeInfo(TKMGroupType), Integer(aGroupType)), aCount, aColumns]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5924
//* Sets the number of ticks before the specified AI will start training recruits
procedure TKMScriptActions.AIRecruitDelay(aHand: Byte; aDelay: Cardinal);
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled) then
      gHands[aHand].AI.Setup.RecruitDelay := aDelay
    else
      LogIntParamWarn('Actions.AIRecruitDelay', [aHand, aDelay]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5345
//* Sets the number of recruits the AI will keep in each barracks
procedure TKMScriptActions.AIRecruitLimit(aHand, aLimit: Byte);
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled) then
      gHands[aHand].AI.Setup.RecruitCount := aLimit
    else
      LogIntParamWarn('Actions.AIRecruitLimit', [aHand, aLimit]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Sets whether the AI should automatically repair damaged buildings
//* aRepairMode: One of the values (rmNone, rmRepairNever, rmRepairAlways, rmRepairManual)
//* rmNone - unused
//* rmRepairNever - disable repair for all houses
//* rmRepairAlways - enable repair for all houses
//* rmRepairManual - repair is set by script manually via Actions.HouseRepairEnable
procedure TKMScriptActions.AIRepairMode(aHand: Integer; aRepairMode: TKMAIRepairMode);
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
      and (aRepairMode <> rmNone) then
      gHands[aHand].AI.Setup.RepairMode := aRepairMode
    else
      LogParamWarn('Actions.AIRepairMode', [aHand, GetEnumName(TypeInfo(TKMAIRepairMode), Integer(aRepairMode))]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5924
//* Sets the number of serfs the AI will train per house.
//* Can be a decimal (0.25 for 1 serf per 4 houses)
procedure TKMScriptActions.AISerfsPerHouse(aHand: Byte; aSerfs: Single);
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled) then
      gHands[aHand].AI.Setup.SerfsPerHouse := aSerfs
    else
      LogIntParamWarn('Actions.AISerfsPerHouse', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5932
//* Sets the maximum number of soldiers the AI will train, or -1 for unlimited
procedure TKMScriptActions.AISoldiersLimit(aHand: Byte; aLimit: Integer);
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
    and (aLimit >= -1) then                       //-1 means unlimited; else MaxSoldiers = aLimit
      gHands[aHand].AI.Setup.MaxSoldiers := aLimit
    else
      LogIntParamWarn('Actions.AISoldiersLimit', [aHand, aLimit]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6251
//* Sets the AI start position which is used for targeting AI attacks
procedure TKMScriptActions.AIStartPosition(aHand: Byte; X, Y: Integer);
begin
  try
    if (InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled))
    and (gTerrain.TileInMapCoords(X, Y)) then
      gHands[aHand].AI.Setup.StartPosition := KMPoint(X, Y)
    else
      LogIntParamWarn('Actions.AIStartPosition', [aHand, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5924
//* Sets the maximum number of laborers the AI will train
procedure TKMScriptActions.AIWorkerLimit(aHand, aLimit: Byte);
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled) then
      gHands[aHand].AI.Setup.WorkerCount := aLimit
    else
      LogIntParamWarn('Actions.AIWorkerLimit', [aHand, aLimit]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Adds an animal to the game and returns the unit ID or -1 if the animal was not able to be added
function TKMScriptActions.GiveAnimal(aType, X, Y: Integer): Integer;
var
  U: TKMUnit;
begin
  try
    Result := UID_NONE;

    //Verify all input parameters
    if (aType in [UNIT_TYPE_TO_ID[ANIMAL_MIN] .. UNIT_TYPE_TO_ID[ANIMAL_MAX]])
    and gTerrain.TileInMapCoords(X, Y) then
    begin
      U := gHands.PlayerAnimals.AddUnit(UNIT_ID_TO_TYPE[aType], KMPoint(X,Y));
      if U <> nil then
        Result := U.UID;
    end
    else
      LogIntParamWarn('Actions.GiveAnimal', [aType, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Adds an animal to the game and returns the unit ID or -1 if the animal was not able to be added
function TKMScriptActions.GiveAnimalEx(aType: TKMUnitType; X,Y: Integer): Integer;
var
  U: TKMUnit;
begin
  try
    Result := UID_NONE;

    //Verify all input parameters
    if (aType in UNITS_ANIMALS)
    and gTerrain.TileInMapCoords(X, Y) then
    begin
      U := gHands.PlayerAnimals.AddUnit(aType, KMPoint(X,Y));
      if U <> nil then
        Result := U.UID;
    end
    else
      LogParamWarn('Actions.GiveAnimalEx', [GetEnumName(TypeInfo(TKMUnitType), Integer(aType)), X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6311
//* Adds finished field and returns true if field was successfully added
function TKMScriptActions.GiveField(aHand, X, Y: Integer): Boolean;
begin
  try
    Result := False;
    if InRange(aHand, 0, gHands.Count - 1)
      and (gHands[aHand].Enabled)
      and gTerrain.TileInMapCoords(X, Y) then
    begin
      if gHands[aHand].CanAddFieldPlan(KMPoint(X, Y), ftCorn) then
      begin
        Result := True;
        gTerrain.SetField(KMPoint(X, Y), aHand, ftCorn, 0, False, True);
      end
      else
        LogWarning('Actions.GiveField', Format('Cannot give field for player %d at [%d:%d]', [aHand,X,Y]));
    end else
      LogIntParamWarn('Actions.GiveField', [aHand, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Sets field age if tile is corn field, or adds finished field and sets its age if tile is empty, and returns true if this was successfully done
//* aStage: 0..6, sets the field growth stage. 0 = empty field; 6 = corn has been cut
//* aRandomAge: sets FieldAge to random, according to specified stage. Makes fields more realistic
function TKMScriptActions.GiveFieldAged(aHand, X, Y: Integer; aStage: Byte; aRandomAge: Boolean): Boolean;
begin
  try
    Result := False;
    if InRange(aHand, 0, gHands.Count - 1)
      and (gHands[aHand].Enabled)
      and (InRange(aStage, 0, CORN_STAGES_COUNT - 1))
      and gTerrain.TileInMapCoords(X, Y) then
    begin
      if gHands[aHand].CanAddFieldPlan(KMPoint(X, Y), ftCorn)
        or (gTerrain.TileIsCornField(KMPoint(X, Y))) then
      begin
        Result := True;
        gTerrain.SetField(KMPoint(X, Y), aHand, ftCorn, aStage, aRandomAge);
      end
      else
        LogWarning('Actions.GiveFieldAged', Format('Cannot give field for player %d at [%d:%d]', [aHand,X,Y]));
    end else
      LogIntParamWarn('Actions.GiveFieldAged', [aHand, X, Y, aStage, Byte(aRandomAge)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6311
//* Adds finished road and returns true if road was successfully added
function TKMScriptActions.GiveRoad(aHand, X, Y: Integer): Boolean;
begin
  try
    Result := False;
    if InRange(aHand, 0, gHands.Count - 1)
    and (gHands[aHand].Enabled)
    and gTerrain.TileInMapCoords(X, Y) then
      if gHands[aHand].CanAddFieldPlan(KMPoint(X, Y), ftRoad) then
      begin
        Result := True;
        gTerrain.SetRoad(KMPoint(X, Y), aHand);
        //Terrain under roads is flattened (fields are not)
        gTerrain.FlattenTerrain(KMPoint(X, Y));
        if gMapElements[gTerrain.Land^[Y,X].Obj].WineOrCorn then
          gTerrain.RemoveObject(KMPoint(X,Y)); //Remove corn/wine like normally built road does
      end
    else
      LogIntParamWarn('Actions.GiveRoad', [aHand, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Adds amount of wares to players 1st Store
//* Wares are added to first Store
procedure TKMScriptActions.GiveWares(aHand, aType, aCount: Integer);
var
  H: TKMHouse;
begin
  try
    //Verify all input parameters
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
      and InRange(aCount, 0, High(Word))
      and (aType in [Low(WARE_ID_TO_TYPE) .. High(WARE_ID_TO_TYPE)]) then
    begin
      H := gHands[aHand].FindHouse(htStore, 1);
      if H <> nil then
      begin
        H.ResAddToIn(WARE_ID_TO_TYPE[aType], aCount);
        gHands[aHand].Stats.WareProduced(WARE_ID_TO_TYPE[aType], aCount);
        gScriptEvents.ProcWareProduced(H, WARE_ID_TO_TYPE[aType], aCount);
      end;
    end
    else
      LogIntParamWarn('Actions.GiveWares', [aHand, aType, aCount]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Adds amount of wares to players 1st Store
//* Wares are added to first Store
procedure TKMScriptActions.GiveWaresEx(aHand: Integer; aType: TKMWareType; aCount: Integer);
var
  H: TKMHouse;
begin
  try
    //Verify all input parameters
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
      and InRange(aCount, 0, High(Word))
      and (aType in WARES_VALID) then
    begin
      H := gHands[aHand].FindHouse(htStore, 1);
      if H <> nil then
      begin
        H.ResAddToIn(aType, aCount);
        gHands[aHand].Stats.WareProduced(aType, aCount);
        gScriptEvents.ProcWareProduced(H, aType, aCount);
      end;
    end
    else
      LogParamWarn('Actions.GiveWaresEx', [aHand, GetEnumName(TypeInfo(TKMWareType), Integer(aType)), aCount]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5165
//* Adds amount of weapons to players 1st Barracks
//* Weapons are added to first Barracks
procedure TKMScriptActions.GiveWeapons(aHand, aType, aCount: Integer);
var
  H: TKMHouse;
begin
  try
    //Verify all input parameters
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
      and InRange(aCount, 0, High(Word))
      and (aType in [Low(WARE_ID_TO_TYPE) .. High(WARE_ID_TO_TYPE)])
      and (WARE_ID_TO_TYPE[aType] in [WARFARE_MIN .. WARFARE_MAX]) then
    begin
      H := gHands[aHand].FindHouse(htBarracks, 1);
      if H <> nil then
      begin
        H.ResAddToIn(WARE_ID_TO_TYPE[aType], aCount);
        gHands[aHand].Stats.WareProduced(WARE_ID_TO_TYPE[aType], aCount);
        gScriptEvents.ProcWareProduced(H, WARE_ID_TO_TYPE[aType], aCount);
      end;
    end
    else
      LogIntParamWarn('Actions.GiveWeapons', [aHand, aType, aCount]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Adds amount of weapons to players 1st Barracks
//* Weapons are added to first Barracks
procedure TKMScriptActions.GiveWeaponsEx(aHand: Integer; aType: TKMWareType; aCount: Integer);
var
  H: TKMHouse;
begin
  try
    //Verify all input parameters
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
      and InRange(aCount, 0, High(Word))
      and (aType in WARES_WARFARE) then
    begin
      H := gHands[aHand].FindHouse(htBarracks, 1);
      if H <> nil then
      begin
        H.ResAddToIn(aType, aCount);
        gHands[aHand].Stats.WareProduced(aType, aCount);
        gScriptEvents.ProcWareProduced(H, aType, aCount);
      end;
    end
    else
      LogParamWarn('Actions.GiveWeaponsEx', [aHand, GetEnumName(TypeInfo(TKMWareType), Integer(aType)), aCount]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6311
//* Adds finished winefield and returns true if winefield was successfully added
function TKMScriptActions.GiveWineField(aHand, X, Y: Integer): Boolean;
begin
  try
    Result := False;
    if InRange(aHand, 0, gHands.Count - 1)
      and (gHands[aHand].Enabled)
      and gTerrain.TileInMapCoords(X, Y) then
    begin
      if gHands[aHand].CanAddFieldPlan(KMPoint(X, Y), ftWine) then
      begin
        Result := True;
        gTerrain.SetField(KMPoint(X, Y), aHand, ftWine, 0, False, True);
      end
      else
        LogWarning('Actions.GiveWineField', Format('Cannot give winefield for player %d at [%d:%d]', [aHand,X,Y]));
    end else
      LogIntParamWarn('Actions.GiveWineField', [aHand, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Sets winefield age if tile is winefield, or adds finished winefield and sets its age if tile is empty, and returns true if this was successfully done
//* aStage: 0..3, sets the field growth stage. 0 = new fruits; 3 = grapes are ready to be harvested; according to WINE_STAGES_COUNT
//* aRandomAge: sets FieldAge to random, according to specified stage. Makes fields more realistic
function TKMScriptActions.GiveWineFieldAged(aHand, X, Y: Integer; aStage: Byte; aRandomAge: Boolean): Boolean;
begin
  try
    Result := False;
    if InRange(aHand, 0, gHands.Count - 1)
      and (gHands[aHand].Enabled)
      and (InRange(aStage, 0, WINE_STAGES_COUNT - 1))
      and gTerrain.TileInMapCoords(X, Y) then
    begin
      if gHands[aHand].CanAddFieldPlan(KMPoint(X, Y), ftWine)
        or (gTerrain.TileIsWineField(KMPoint(X, Y))) then
      begin
        Result := True;
        gTerrain.SetField(KMPoint(X, Y), aHand, ftWine, aStage, aRandomAge);
      end
      else
        LogWarning('Actions.GiveWineFieldAged', Format('Cannot give winefield for player %d at [%d:%d]', [aHand,X,Y]));
    end else
      LogIntParamWarn('Actions.GiveWineFieldAged', [aHand, X, Y, aStage, Byte(aRandomAge)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5097
//* Reveals a circle in fog of war for player
procedure TKMScriptActions.FogRevealCircle(aHand, X, Y, aRadius: Integer);
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
    and gTerrain.TileInMapCoords(X,Y)
    and InRange(aRadius, 0, 255) then
      gHands[aHand].FogOfWar.RevealCircle(KMPoint(X, Y), aRadius, FOG_OF_WAR_MAX)
    else
      LogIntParamWarn('Actions.FogRevealCircle', [aHand, X, Y, aRadius]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5097
//* Reveals a circle in fog of war for player
procedure TKMScriptActions.FogCoverCircle(aHand, X, Y, aRadius: Integer);
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
    and gTerrain.TileInMapCoords(X,Y)
    and InRange(aRadius, 0, 255) then
      gHands[aHand].FogOfWar.CoverCircle(KMPoint(X, Y), aRadius)
    else
      LogIntParamWarn('Actions.FogCoverCircle', [aHand, X, Y, aRadius]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5777
//* Reveals a rectangular area in fog of war for player
//* X1: Left coordinate
//* Y1: Top coordinate
//* X2: Right coordinate
//* Y2: Bottom coordinate
procedure TKMScriptActions.FogRevealRect(aHand, X1, Y1, X2, Y2: Integer);
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
    and gTerrain.TileInMapCoords(X1,Y1)
    and gTerrain.TileInMapCoords(X2,Y2) then
      gHands[aHand].FogOfWar.RevealRect(KMPoint(X1, Y1), KMPoint(X2, Y2), FOG_OF_WAR_MAX)
    else
      LogIntParamWarn('Actions.FogRevealRect', [aHand, X1, Y1, X2, Y2]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5777
//* Covers a rectangular area in fog of war for player
//* X1: Left coordinate
//* Y1: Top coordinate
//* X2: Right coordinate
//* Y2: Bottom coordinate
procedure TKMScriptActions.FogCoverRect(aHand, X1, Y1, X2, Y2: Integer);
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
    and gTerrain.TileInMapCoords(X1,Y1)
    and gTerrain.TileInMapCoords(X2,Y2) then
      gHands[aHand].FogOfWar.CoverRect(KMPoint(X1, Y1), KMPoint(X2, Y2))
    else
      LogIntParamWarn('Actions.FogCoverRect', [aHand, X1, Y1, X2, Y2]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5097
//* Reveals the entire map in fog of war for player
procedure TKMScriptActions.FogRevealAll(aHand: Byte);
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled) then
      gHands[aHand].FogOfWar.RevealEverything
    else
      LogIntParamWarn('Actions.FogRevealAll', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5097
//* Covers (un-reveals) the entire map in fog of war for player
procedure TKMScriptActions.FogCoverAll(aHand: Byte);
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled) then
      gHands[aHand].FogOfWar.CoverEverything
    else
      LogIntParamWarn('Actions.FogCoverAll', [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Displays a message to a player.
//* If the player index is -1 the message will be shown to all players.
//Input text is ANSI with libx codes to substitute
procedure TKMScriptActions.ShowMsg(aHand: Shortint; const aText: AnsiString);
begin
  try
    if (aHand = gMySpectator.HandID) or (aHand = HAND_NONE) then
      gGame.ShowMessageLocal(mkText, gGame.TextMission.ParseTextMarkup(UnicodeString(aText)), KMPOINT_ZERO);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5333
//* Displays a message to a player with formatted arguments (same as Format function).
//* If the player index is -1 the message will be shown to all players.
//* Params: Array of arguments
//Input text is ANSI with libx codes to substitute
procedure TKMScriptActions.ShowMsgFormatted(aHand: Shortint; const aText: AnsiString; Params: array of const);
begin
  try
    try
      if (aHand = gMySpectator.HandID) or (aHand = HAND_NONE) then
        gGame.ShowMessageLocal(mkText, gGame.TextMission.ParseTextMarkup(UnicodeString(aText), Params), KMPOINT_ZERO);
    except
      //Format may throw an exception
      on E: EConvertError do LogIntParamWarn('Actions.ShowMsgFormatted: '+E.Message, []);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5345
//* Displays a message to a player with a goto button that takes the player to the specified location.
//* If the player index is -1 the message will be shown to all players.
//Input text is ANSI with libx codes to substitute
procedure TKMScriptActions.ShowMsgGoto(aHand: Shortint; aX, aY: Integer; const aText: AnsiString);
begin
  try
    if gTerrain.TileInMapCoords(aX, aY) then
    begin
      if (aHand = gMySpectator.HandID) or (aHand = HAND_NONE) then
        gGame.ShowMessageLocal(mkText, gGame.TextMission.ParseTextMarkup(UnicodeString(aText)), KMPoint(aX,aY));
    end
    else
      LogIntParamWarn('Actions.ShowMsgGoto', [aHand, aX, aY]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5345
//* Displays a message to a player with formatted arguments (same as Format function)
//* and a goto button that takes the player to the specified location.
//* If the player index is -1 the message will be shown to all players.
//* Params: Array of arguments
//Input text is ANSI with libx codes to substitute
procedure TKMScriptActions.ShowMsgGotoFormatted(aHand: Shortint; aX, aY: Integer; const aText: AnsiString; Params: array of const);
begin
  try
    try
      if gTerrain.TileInMapCoords(aX, aY) then
      begin
        if (aHand = gMySpectator.HandID) or (aHand = HAND_NONE) then
          gGame.ShowMessageLocal(mkText, gGame.TextMission.ParseTextMarkup(UnicodeString(aText), Params), KMPoint(aX,aY));
      end
      else
        LogIntParamWarn('Actions.ShowMsgGotoFormatted', [aHand, aX, aY]);
    except
      //Format may throw an exception
      on E: EConvertError do LogIntParamWarn('Actions.ShowMsgGotoFormatted: '+E.Message, []);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Allows player to build the specified house even if they don't have the house built that normally unlocks it
//* (e.g. sawmill for farm).
//* Note: Does not override blocked houses, use HouseAllow for that.
procedure TKMScriptActions.HouseUnlock(aHand, aHouseType: Integer);
begin
  try
    //Verify all input parameters
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
    and HouseTypeValid(aHouseType) then
      gHands[aHand].Locks.HouseLock[HOUSE_ID_TO_TYPE[aHouseType]] := hlGranted
    else
      LogIntParamWarn('Actions.HouseUnlock', [aHand, aHouseType]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Sets whether the player is allowed to build the specified house.
//* Note: The house must still be unlocked normally (e.g. sawmill for farm), use HouseUnlock to override that.
procedure TKMScriptActions.HouseAllow(aHand, aHouseType: Integer; aAllowed: Boolean);
begin
  try
    //Verify all input parameters
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
      and HouseTypeValid(aHouseType) then
    begin
      case gHands[aHand].Locks.HouseLock[HOUSE_ID_TO_TYPE[aHouseType]] of
        hlDefault,
        hlGranted:  if not aAllowed then
                      gHands[aHand].Locks.HouseLock[HOUSE_ID_TO_TYPE[aHouseType]] := hlBlocked;
        hlBlocked:  if aAllowed then
                      gHands[aHand].Locks.HouseLock[HOUSE_ID_TO_TYPE[aHouseType]] := hlDefault;
      end;
    end
    else
      LogIntParamWarn('Actions.HouseAllow', [aHand, aHouseType, Byte(aAllowed)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 10940
//* Allows allies to view specified house
procedure TKMScriptActions.HouseAllowAllyToSelect(aHouseID: Integer; aAllow: Boolean);
var
  H: TKMHouse;
begin
  try
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil) and not H.IsDestroyed and H.IsComplete then
      begin
        H.AllowAllyToSelect := aAllow;
      end;
      //Silently ignore if house doesn't exist
    end
    else
      LogIntParamWarn('Actions.HouseAllowAllyToSelect', [aHouseID, Byte(aAllow)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 10940
//* Allows allies to view all houses of specified player, or for all players, if aHand is -1
//* This function applies only to already build houses.
//* New houses will be selectable for allies. To avoid it use OnHouseBuilt event
procedure TKMScriptActions.HouseAllowAllyToSelectAll(aHand: ShortInt; aAllow: Boolean);

  procedure SetAllowAllyToHand(aHandID: ShortInt);
  var
    I: Integer;
  begin
    if gHands[aHandID].Enabled then
      for I := 0 to gHands[aHandID].Houses.Count - 1 do
        gHands[aHandID].Houses[I].AllowAllyToSelect := aAllow
  end;

var
  I: Integer;
begin
  try
    if aHand = HAND_NONE then
      for I := 0 to gHands.Count - 1 do
        SetAllowAllyToHand(I)
    else
    if InRange(aHand, 0, gHands.Count - 1) then
      SetAllowAllyToHand(aHand)
    else
      LogIntParamWarn('Actions.HouseAllowAllyToSelectAll', [aHand, Byte(aAllow)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Sets whether the player is allowed to trade the specified resource.
procedure TKMScriptActions.SetTradeAllowed(aHand, aResType: Integer; aAllowed: Boolean);
begin
  try
    //Verify all input parameters
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
      and (aResType in [Low(WARE_ID_TO_TYPE)..High(WARE_ID_TO_TYPE)]) then
      gHands[aHand].Locks.AllowToTrade[WARE_ID_TO_TYPE[aResType]] := aAllowed
    else
      LogIntParamWarn('Actions.SetTradeAllowed', [aHand, aResType, Byte(aAllowed)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Sets hand (player) house lock aLock for a specified house type aHouseType
//* if htAny is passed for house type then aLock will be applied to all house types
procedure TKMScriptActions.HandHouseLock(aHand: Integer; aHouseType: TKMHouseType; aLock: TKMHandHouseLock);
var
  HT: TKMHouseType;
begin
  try
    //Verify all input parameters
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
      and ((aHouseType = htAny) or (aHouseType in HOUSES_VALID)) then
    begin
      if aHouseType = htAny then
      begin
        for HT in HOUSES_VALID do
          gHands[aHand].Locks.HouseLock[HT] := aLock;
      end
      else
        gHands[aHand].Locks.HouseLock[aHouseType] := aLock;
    end
    else
      LogParamWarn('Actions.HandHouseLock', [aHand, GetEnumName(TypeInfo(TKMHouseType), Integer(aHouseType))]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Sets whether the player is allowed to trade the specified resource.
//* if aHand = -1, then apply it to all hands (players)
procedure TKMScriptActions.HandTradeAllowed(aHand: Integer; aWareType: TKMWareType; aAllowed: Boolean);
var
  I: Integer;
begin
  try
    //Verify all input parameters
    if ((aHand = -1) or (InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)))
      and (aWareType in WARES_VALID) then
    begin
      if aHand = HAND_NONE then
      begin
        for I := 0 to gHands.Count - 1 do
          if gHands[I].Enabled then
            gHands[I].Locks.AllowToTrade[aWareType] := aAllowed;
      end
      else
        gHands[aHand].Locks.AllowToTrade[aWareType] := aAllowed;
    end
    else
      LogParamWarn('Actions.HandTradeAllowed', [aHand, GetEnumName(TypeInfo(TKMWareType), Integer(aWareType)), BoolToStr(aAllowed, True)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Sets whether the specified player can train/equip the specified unit type
//* if aHand = -1, then apply it to all hands (players)
procedure TKMScriptActions.HandUnitCanTrain(aHand: Integer; aUnitType: TKMUnitType; aCanTrain: Boolean);
var
  I: Integer;
begin
  try
    if ((aHand = -1) or (InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)))
      and (aUnitType in UNITS_VALID) then
    begin
      if aHand = HAND_NONE then
      begin
        for I := 0 to gHands.Count - 1 do
          if gHands[I].Enabled then
            gHands[I].Locks.SetUnitBlocked(not aCanTrain, aUnitType);
      end
      else
        gHands[aHand].Locks.SetUnitBlocked(not aCanTrain, aUnitType);
    end
    else
      LogParamWarn('Actions.HandUnitCanTrain', [aHand, GetEnumName(TypeInfo(TKMUnitType), Integer(aUnitType)), BoolToStr(aCanTrain, True)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Sets ware distribution for the specified resource, house and hand (player).
//* aAmount: Distribution amount (0..5)
//* Note: distribution should be set after 1st tick of the game,
//* thus it will not make effect to use it in OnMissionStart event handler
procedure TKMScriptActions.HandWareDistribution(aHand: Integer; aWareType: TKMWareType; aHouseType: TKMHouseType; aAmount: Integer);
begin
  try
    if (aWareType in WARES_VALID)
      and (aWareType in [wtIron, wtCoal, wtTimber, wtCorn])
      and (aHouseType in HOUSES_VALID)
      and InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
      and InRange(aAmount, 0, 5) then
    begin
      gHands[aHand].Stats.WareDistribution[aWareType, aHouseType] := aAmount;
      gHands[aHand].Houses.UpdateResRequest;
    end
    else
      LogParamWarn('Actions.HandWareDistribution', [aHand,
                                                    GetEnumName(TypeInfo(TKMWareType), Integer(aWareType)),
                                                    GetEnumName(TypeInfo(TKMHouseType), Integer(aHouseType)), aAmount]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6510
//* Add all building materials to the specified WIP house area
procedure TKMScriptActions.HouseAddBuildingMaterials(aHouseID: Integer);
var
  resNeeded: Integer;
  plannedToRemove: Word;
  H: TKMHouse;
begin
  try
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        if not H.IsComplete then
        begin
          resNeeded := gHands[H.Owner].Deliveries.Queue.TryRemoveDemand(H, wtTimber,
                         gResHouses[H.HouseType].WoodCost - H.GetBuildWoodDelivered, plannedToRemove);
          Inc(resNeeded, plannedToRemove);
          H.ResAddToBuild(wtTimber, resNeeded);

          resNeeded := gHands[H.Owner].Deliveries.Queue.TryRemoveDemand(H, wtStone,
                         gResHouses[H.HouseType].StoneCost - H.GetBuildStoneDelivered, plannedToRemove);
          Inc(resNeeded, plannedToRemove);
          H.ResAddToBuild(wtStone, resNeeded);
        end;
    end
    else
      LogIntParamWarn('Actions.HouseAddBuildingMaterials', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Add or remove building materials to the specified WIP house area
//* if aWoodAmount or aStoneAmount > 0 then add build wares to the site
//* if aWoodAmount or aStoneAmount < 0 then remove build wares from the site
procedure TKMScriptActions.HouseAddBuildingMaterialsEx(aHouseID, aWoodAmount, aStoneAmount: Integer);
var
  resNeeded: Integer;
  plannedToRemove: Word;
  H: TKMHouse;
begin
  try
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        if not H.IsComplete then
        begin
          aWoodAmount := EnsureRange(aWoodAmount, -H.BuildSupplyWood, gResHouses[H.HouseType].WoodCost - H.GetBuildWoodDelivered);

          if aWoodAmount > 0 then
          begin
            resNeeded := gHands[H.Owner].Deliveries.Queue.TryRemoveDemand(H, wtTimber, aWoodAmount, plannedToRemove);
            Inc(resNeeded, plannedToRemove);
            H.ResAddToBuild(wtTimber, resNeeded);
          end
          else
          begin
            H.ResAddToBuild(wtTimber, aWoodAmount);
            gHands[H.Owner].Deliveries.Queue.AddDemand(H, nil, wtTimber, -aWoodAmount, dtOnce, diHigh4);
          end;

          aStoneAmount := EnsureRange(aStoneAmount, -H.BuildSupplyStone, gResHouses[H.HouseType].StoneCost - H.GetBuildStoneDelivered);

          if aStoneAmount > 0 then
          begin
            resNeeded := gHands[H.Owner].Deliveries.Queue.TryRemoveDemand(H, wtStone, aStoneAmount, plannedToRemove);
            Inc(resNeeded, plannedToRemove);
            H.ResAddToBuild(wtStone, resNeeded);
          end
          else
          begin
            H.ResAddToBuild(wtStone, aStoneAmount);
            gHands[H.Owner].Deliveries.Queue.AddDemand(H, nil, wtStone, -aStoneAmount, dtOnce, diHigh4);
          end;

        end;
    end
    else
      LogIntParamWarn('Actions.HouseAddBuildingMaterialsEx', [aHouseID, aWoodAmount, aStoneAmount]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6297
//* Add 5 points of building progress to the specified WIP house area
procedure TKMScriptActions.HouseAddBuildingProgress(aHouseID: Integer);
var
  H: TKMHouse;
begin
  try
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        if not H.IsComplete
          and H.CheckResToBuild then
        begin
          H.IncBuildingProgress;
          if H.IsStone
          and (gTerrain.Land^[H.Position.Y, H.Position.X].TileLock <> tlHouse) then
            gTerrain.SetHouse(H.Position, H.HouseType, hsBuilt, H.Owner);
        end;
    end
    else
      LogIntParamWarn('Actions.HouseAddBuildingProgress', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Add 5 * aBuildSteps points of building progress to the specified WIP house area
procedure TKMScriptActions.HouseAddBuildingProgressEx(aHouseID, aBuildSteps: Integer);
var
  I: Integer;
  H: TKMHouse;
begin
  try
    if (aHouseID > 0) and (aBuildSteps > 0) then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
      begin
        for I := 0 to aBuildSteps - 1 do
        begin
          if H.IsComplete or not H.CheckResToBuild then Break;

          H.IncBuildingProgress;
        end;

        if H.IsStone and (gTerrain.Land^[H.Position.Y, H.Position.X].TileLock <> tlHouse) then
          gTerrain.SetHouse(H.Position, H.HouseType, hsBuilt, H.Owner);
      end;
    end
    else
      LogIntParamWarn('Actions.HouseAddBuildingProgressEx', [aHouseID, aBuildSteps]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Add damage to the specified house
procedure TKMScriptActions.HouseAddDamage(aHouseID: Integer; aDamage: Integer);
var
  H: TKMHouse;
begin
  try
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        H.AddDamage(aDamage, nil); //We don't know who did the damage
    end
    else
      LogIntParamWarn('Actions.HouseAddDamage', [aHouseID, aDamage]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5441
//* Reduces damage to the specified house
procedure TKMScriptActions.HouseAddRepair(aHouseID: Integer; aRepair: Integer);
var
  H: TKMHouse;
begin
  try
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil) and H.IsComplete then
        H.AddRepair(aRepair);
    end
    else
      LogIntParamWarn('Actions.HouseAddRepair', [aHouseID, aRepair]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5263
//* Destroys the specified house.
//* Silent means the house will not leave rubble or play destroy sound
procedure TKMScriptActions.HouseDestroy(aHouseID: Integer; aSilent: Boolean);
var
  H: TKMHouse;
begin
  try
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if H <> nil then
        H.Demolish(HAND_NONE, aSilent);
    end
    else
      LogIntParamWarn('Actions.HouseDestroy', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Add wares to the specified house
procedure TKMScriptActions.HouseAddWaresTo(aHouseID: Integer; aType, aCount: Integer);
var
  H: TKMHouse;
  res: TKMWareType;
begin
  try
    if (aHouseID > 0) and (aType in [Low(WARE_ID_TO_TYPE)..High(WARE_ID_TO_TYPE)]) then
    begin
      res := WARE_ID_TO_TYPE[aType];
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil) and not H.IsDestroyed and H.IsComplete then
        if H.CanHaveWareType(res) then
        begin
          if aCount > 0 then
          begin
            H.ResAddToEitherFromScript(res, aCount);
            gHands[H.Owner].Stats.WareProduced(res, aCount);
            gScriptEvents.ProcWareProduced(H, res, aCount);
          end;
        end
        else
          LogIntParamWarn('Actions.HouseAddWaresTo wrong ware type', [aHouseID, aType, aCount]);
      //Silently ignore if house doesn't exist
    end
    else
      LogIntParamWarn('Actions.HouseAddWaresTo', [aHouseID, aType, aCount]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Add wares to the specified house
procedure TKMScriptActions.HouseAddWaresToEx(aHouseID: Integer; aType: TKMWareType; aCount: Integer);
var
  H: TKMHouse;
begin
  try
    if (aHouseID > 0) and (aType in WARES_VALID) then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil) and not H.IsDestroyed and H.IsComplete then
        if H.CanHaveWareType(aType) then
        begin
          if aCount > 0 then
          begin
            H.ResAddToEitherFromScript(aType, aCount);
            gHands[H.Owner].Stats.WareProduced(aType, aCount);
            gScriptEvents.ProcWareProduced(H, aType, aCount);
          end;
        end
        else
          LogParamWarn('Actions.HouseAddWaresToEx wrong ware type', [aHouseID, GetEnumName(TypeInfo(TKMWareType), Integer(aType)), aCount]);
      //Silently ignore if house doesn't exist
    end
    else
      LogParamWarn('Actions.HouseAddWaresTo', [aHouseID, GetEnumName(TypeInfo(TKMWareType), Integer(aType)), aCount]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6015
//* Remove wares from the specified house.
//* If a serf was on the way to pick up the ware, the serf will abandon his task
procedure TKMScriptActions.HouseTakeWaresFrom(aHouseID: Integer; aType, aCount: Integer);
var
  H: TKMHouse;
  res: TKMWareType;
begin
  try
    if (aHouseID > 0) and (aType in [Low(WARE_ID_TO_TYPE)..High(WARE_ID_TO_TYPE)]) then
    begin
      res := WARE_ID_TO_TYPE[aType];
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil) and not H.IsDestroyed and H.IsComplete then
        //Store/barracks mix input/output (add to input, take from output) so we must process them together
        if H.CanHaveWareType(res) then
        begin
          if aCount > 0 then
            H.ResTake(res, aCount, True);
        end
        else
          LogIntParamWarn('Actions.HouseTakeWaresFrom wrong ware type', [aHouseID, aType, aCount]);
      //Silently ignore if house doesn't exist
    end
    else
      LogIntParamWarn('Actions.HouseTakeWaresFrom', [aHouseID, aType, aCount]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Remove wares from the specified house.
//* If a serf was on the way to pick up the ware, the serf will abandon his task
procedure TKMScriptActions.HouseTakeWaresFromEx(aHouseID: Integer; aType: TKMWareType; aCount: Integer);
var
  H: TKMHouse;
begin
  try
    if (aHouseID > 0) and (aType in WARES_VALID) then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil) and not H.IsDestroyed and H.IsComplete then
        //Store/barracks mix input/output (add to input, take from output) so we must process them together
        if H.CanHaveWareType(aType) then
        begin
          if aCount > 0 then
            H.ResTake(aType, aCount, True);
        end
        else
          LogParamWarn('Actions.HouseTakeWaresFromEx wrong ware type', [aHouseID, GetEnumName(TypeInfo(TKMWareType), Integer(aType)), aCount]);
      //Silently ignore if house doesn't exist
    end
    else
      LogParamWarn('Actions.HouseTakeWaresFromEx', [aHouseID, GetEnumName(TypeInfo(TKMWareType), Integer(aType)), aCount]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Equips the specified unit from the specified TownHall.
//* Returns the number of units successfully equipped.
function TKMScriptActions.HouseTownHallEquip(aHouseID: Integer; aUnitType: Integer; aCount: Integer): Integer;
var
  H: TKMHouse;
begin
  try
    Result := 0;
    if (aHouseID > 0)
      and (aUnitType in [UNIT_TYPE_TO_ID[WARRIOR_EQUIPABLE_TH_MIN]..UNIT_TYPE_TO_ID[WARRIOR_EQUIPABLE_TH_MAX]]) then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil) and (H is TKMHouseTownHall) and not H.IsDestroyed and H.IsComplete then
        Result := TKMHouseTownHall(H).Equip(UNIT_ID_TO_TYPE[aUnitType], aCount);
    end
    else
      LogIntParamWarn('Actions.HouseTownHallEquip', [aHouseID, aUnitType]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Equips the specified unit from the specified TownHall.
//* Returns the number of units successfully equipped.
function TKMScriptActions.HouseTownHallEquipEx(aHouseID: Integer; aUnitType: TKMUnitType; aCount: Integer): Integer;
var
  H: TKMHouse;
begin
  try
    Result := 0;
    if (aHouseID > 0)
      and (aUnitType in [WARRIOR_EQUIPABLE_TH_MIN..WARRIOR_EQUIPABLE_TH_MAX]) then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil) and (H is TKMHouseTownHall) and not H.IsDestroyed and H.IsComplete then
        Result := TKMHouseTownHall(H).Equip(aUnitType, aCount);
    end
    else
      LogParamWarn('Actions.HouseTownHallEquipEx', [aHouseID, GetEnumName(TypeInfo(TKMUnitType), Integer(aUnitType))]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Set TownHall Max Gold parameter (how many gold could be delivered in it)
procedure TKMScriptActions.HouseTownHallMaxGold(aHouseID: Integer; aMaxGold: Integer);
var
  H: TKMHouse;
begin
  try
    if (aHouseID > 0) and InRange(aMaxGold, 0, High(Word)) then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil) and (H is TKMHouseTownHall) and not H.IsDestroyed and H.IsComplete then
        TKMHouseTownHall(H).GoldMaxCnt := aMaxGold;
    end
    else
      LogIntParamWarn('Actions.HouseTownHallMaxGold', [aHouseID, aMaxGold]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Enables house repair for the specified house
procedure TKMScriptActions.HouseRepairEnable(aHouseID: Integer; aRepairEnabled: Boolean);
var
  H: TKMHouse;
begin
  try
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil) and not H.IsDestroyed and H.IsComplete then
        H.BuildingRepair := aRepairEnabled;
    end
    else
      LogIntParamWarn('Actions.HouseRepairEnable', [aHouseID, Byte(aRepairEnabled)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Sets delivery blocking for the specified house
procedure TKMScriptActions.HouseDeliveryBlock(aHouseID: Integer; aDeliveryBlocked: Boolean);
var
  H: TKMHouse;
begin
  try
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil)
        and not H.IsDestroyed //Allow to change delivery mode for not completed houses
        and gResHouses[H.HouseType].AcceptsWares then
      begin
        if aDeliveryBlocked then
          H.SetDeliveryModeInstantly(dmClosed)
        else
          H.SetDeliveryModeInstantly(dmDelivery);
      end;
    end
    else
      LogIntParamWarn('Actions.HouseDeliveryBlock', [aHouseID, Byte(aDeliveryBlocked)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Sets delivery mode for the specified house
procedure TKMScriptActions.HouseDeliveryMode(aHouseID: Integer; aDeliveryMode: TKMDeliveryMode);
var
  H: TKMHouse;
begin
  try
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil)
        and not H.IsDestroyed //Allow to change delivery mode for not completed houses
        and gResHouses[H.HouseType].AcceptsWares then
        H.SetDeliveryModeInstantly(aDeliveryMode);
    end
    else
      LogParamWarn('Actions.HouseDeliveryMode', [aHouseID, GetEnumName(TypeInfo(TKMDeliveryMode), Integer(aDeliveryMode))]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5345
//* Sets whether the specified house displays unoccupied messages to the player
procedure TKMScriptActions.HouseDisableUnoccupiedMessage(aHouseID: Integer; aDisabled: Boolean);
var
  H: TKMHouse;
begin
  try
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil) and not H.IsDestroyed then
        H.DisableUnoccupiedMessage := aDisabled;
    end
    else
      LogIntParamWarn('Actions.HouseDisableUnoccupiedMessage', [aHouseID, Byte(aDisabled)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5099
//* Sets whether a woodcutter's hut is on chop-only mode
procedure TKMScriptActions.HouseWoodcutterChopOnly(aHouseID: Integer; aChopOnly: Boolean);
const
  CHOP_ONLY: array [Boolean] of TKMWoodcutterMode = (wmChopAndPlant, wmChop);
var
  H: TKMHouse;
begin
  try
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil)
        and (H is TKMHouseWoodcutters)
        and not H.IsDestroyed
        and H.IsComplete then
        TKMHouseWoodcutters(H).WoodcutterMode := CHOP_ONLY[aChopOnly];
    end
    else
      LogIntParamWarn('Actions.HouseWoodcutterChopOnly', [aHouseID, Byte(aChopOnly)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Sets woodcutter's hut woodcutter mode as TKMWoodcutterMode = (wmChopAndPlant, wmChop, wmPlant)
procedure TKMScriptActions.HouseWoodcutterMode(aHouseID: Integer; aWoodcutterMode: TKMWoodcutterMode);
var
  H: TKMHouse;
begin
  try
    if (aHouseID > 0) then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil)
        and (H is TKMHouseWoodcutters)
        and not H.IsDestroyed
        and H.IsComplete then
        TKMHouseWoodcutters(H).WoodcutterMode := aWoodcutterMode;
    end
    else
      LogIntParamWarn('Actions.HouseWoodcutterMode', [aHouseID, Byte(aWoodcutterMode)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5099
//* Blocks a specific ware in a storehouse or barracks
procedure TKMScriptActions.HouseWareBlock(aHouseID, aWareType: Integer; aBlocked: Boolean);
var
  H: TKMHouse;
  res: TKMWareType;
begin
  try
    if (aHouseID > 0)
    and (aWareType in [Low(WARE_ID_TO_TYPE) .. High(WARE_ID_TO_TYPE)]) then
    begin
      res := WARE_ID_TO_TYPE[aWareType];
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil)
        and (H is TKMHouseStore)
        and not H.IsDestroyed then
        TKMHouseStore(H).NotAcceptFlag[res] := aBlocked;

      if (H <> nil)
        and (H is TKMHouseBarracks)
        and not H.IsDestroyed
        and (res in [WARFARE_MIN..WARFARE_MAX]) then
        TKMHouseBarracks(H).NotAcceptFlag[res] := aBlocked;
    end
    else
      LogIntParamWarn('Actions.HouseWareBlock', [aHouseID, aWareType, Byte(aBlocked)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Blocks a specific ware in a storehouse or barracks
procedure TKMScriptActions.HouseWareBlockEx(aHouseID: Integer; aWareType: TKMWareType; aBlocked: Boolean);
var
  H: TKMHouse;
begin
  try
    if (aHouseID > 0)
      and (aWareType in WARES_VALID) then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil)
        and (H is TKMHouseStore)
        and not H.IsDestroyed then
        TKMHouseStore(H).NotAcceptFlag[aWareType] := aBlocked;

      if (H <> nil)
        and (H is TKMHouseBarracks)
        and not H.IsDestroyed
        and (aWareType in WARES_WARFARE) then
        TKMHouseBarracks(H).NotAcceptFlag[aWareType] := aBlocked;
    end
    else
      LogParamWarn('Actions.HouseWareBlockEx', [aHouseID, GetEnumName(TypeInfo(TKMWareType), Integer(aWareType)), BoolToStr(aBlocked, True)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Blocks taking out of a specific ware from a storehouse or barracks
procedure TKMScriptActions.HouseWareBlockTakeOut(aHouseID: Integer; aWareType: TKMWareType; aBlocked: Boolean);
var
  H: TKMHouse;
begin
  try
    if (aHouseID > 0)
    and (aWareType in WARES_VALID) then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil)
        and (H is TKMHouseStore)
        and not H.IsDestroyed then
        TKMHouseStore(H).NotAllowTakeOutFlag[aWareType] := aBlocked;

      if (H <> nil)
        and (H is TKMHouseBarracks)
        and not H.IsDestroyed
        and (aWareType in WARES_WARFARE) then
        TKMHouseBarracks(H).NotAllowTakeOutFlag[aWareType] := aBlocked;
    end
    else
      LogParamWarn('Actions.HouseWareBlockTakeOut', [aHouseID, GetEnumName(TypeInfo(TKMWareType), Integer(aWareType)), BoolToStr(aBlocked, True)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5165
//* Sets the amount of the specified weapon ordered to be produced in the specified house
procedure TKMScriptActions.HouseWeaponsOrderSet(aHouseID, aWareType, aAmount: Integer);
var
  I: Integer;
  H: TKMHouse;
  res: TKMWareType;
begin
  try
    if (aHouseID > 0) and InRange(aAmount, 0, MAX_WARES_ORDER)
    and (aWareType in [Low(WARE_ID_TO_TYPE) .. High(WARE_ID_TO_TYPE)]) then
    begin
      res := WARE_ID_TO_TYPE[aWareType];
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil)
        and not H.IsDestroyed
        and H.IsComplete then
        for I := 1 to 4 do
          if gResHouses[H.HouseType].ResOutput[I] = res then
          begin
            H.ResOrder[I] := aAmount;
            Exit;
          end;
    end
    else
      LogIntParamWarn('Actions.HouseWeaponsOrderSet', [aHouseID, aWareType, aAmount]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Sets the amount of the specified weapon ordered to be produced in the specified house
procedure TKMScriptActions.HouseWeaponsOrderSetEx(aHouseID: Integer; aWareType: TKMWareType; aAmount: Integer);
var
  I: Integer;
  H: TKMHouse;
begin
  try
    if (aHouseID > 0) and InRange(aAmount, 0, MAX_WARES_ORDER)
    and (aWareType in WARES_VALID) then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil)
        and not H.IsDestroyed
        and H.IsComplete then
        for I := 1 to 4 do
          if gResHouses[H.HouseType].ResOutput[I] = aWareType then
          begin
            H.ResOrder[I] := aAmount;
            Exit;
          end;
    end
    else
      LogParamWarn('Actions.HouseWeaponsOrderSetEx', [aHouseID, GetEnumName(TypeInfo(TKMWareType), Integer(aWareType)), aAmount]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5174
//* Removes the unit from the specified slot of the school queue.
//* Slot 0 is the unit currently training, slots 1..5 are the queue.
procedure TKMScriptActions.HouseSchoolQueueRemove(aHouseID, QueueIndex: Integer);
var
  H: TKMHouse;
begin
  try
    if (aHouseID > 0) and InRange(QueueIndex, 0, 5) then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil)
        and (H is TKMHouseSchool)
        and not H.IsDestroyed
        and H.IsComplete then
        TKMHouseSchool(H).RemUnitFromQueue(QueueIndex);
    end
    else
      LogIntParamWarn('Actions.HouseSchoolQueueRemove', [aHouseID, QueueIndex]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5174
//* Adds the specified unit to the specified school's queue.
//* Returns the number of units successfully added to the queue.
function TKMScriptActions.HouseSchoolQueueAdd(aHouseID: Integer; aUnitType: Integer; aCount: Integer): Integer;
var
  H: TKMHouse;
begin
  try
    Result := 0;
    if (aHouseID > 0)
      and (aCount > 0)
      and (aUnitType in [UNIT_TYPE_TO_ID[CITIZEN_MIN]..UNIT_TYPE_TO_ID[CITIZEN_MAX]]) then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil)
        and (H is TKMHouseSchool)
        and not H.IsDestroyed
        and H.IsComplete then
        Result := TKMHouseSchool(H).AddUnitToQueue(UNIT_ID_TO_TYPE[aUnitType], aCount);
    end
    else
      LogIntParamWarn('Actions.HouseSchoolQueueAdd', [aHouseID, aUnitType]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Adds the specified unit to the specified school's queue.
//* Returns the number of units successfully added to the queue.
function TKMScriptActions.HouseSchoolQueueAddEx(aHouseID: Integer; aUnitType: TKMUnitType; aCount: Integer): Integer;
var
  H: TKMHouse;
begin
  try
    Result := 0;
    if (aHouseID > 0) and (aCount > 0) and (aUnitType in UNITS_CITIZEN) then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil)
        and (H is TKMHouseSchool)
        and not H.IsDestroyed
        and H.IsComplete then
        Result := TKMHouseSchool(H).AddUnitToQueue(aUnitType, aCount);
    end
    else
      LogParamWarn('Actions.HouseSchoolQueueAddEx', [aHouseID, GetEnumName(TypeInfo(TKMUnitType), Integer(aUnitType))]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5174
//* Equips the specified unit from the specified barracks.
//* Returns the number of units successfully equipped.
function TKMScriptActions.HouseBarracksEquip(aHouseID: Integer; aUnitType: Integer; aCount: Integer): Integer;
var
  H: TKMHouse;
begin
  try
    Result := 0;
    if (aHouseID > 0)
    and (aUnitType in [UNIT_TYPE_TO_ID[WARRIOR_EQUIPABLE_BARRACKS_MIN]..UNIT_TYPE_TO_ID[WARRIOR_EQUIPABLE_BARRACKS_MAX]]) then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil)
        and (H is TKMHouseBarracks)
        and not H.IsDestroyed
        and H.IsComplete then
        Result := TKMHouseBarracks(H).Equip(UNIT_ID_TO_TYPE[aUnitType], aCount);
    end
    else
      LogIntParamWarn('Actions.HouseBarracksEquip', [aHouseID, aUnitType]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 13900
//* Equips the specified unit from the specified barracks.
//* Returns the number of units successfully equipped.
function TKMScriptActions.HouseBarracksEquipEx(aHouseID: Integer; aUnitType: TKMUnitType; aCount: Integer): Integer;
var
  H: TKMHouse;
begin
  try
    Result := 0;
    if (aHouseID > 0)
    and (aUnitType in [WARRIOR_EQUIPABLE_BARRACKS_MIN..WARRIOR_EQUIPABLE_BARRACKS_MAX]) then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil)
        and (H is TKMHouseBarracks)
        and not H.IsDestroyed
        and H.IsComplete then
        Result := TKMHouseBarracks(H).Equip(aUnitType, aCount);
    end
    else
      LogParamWarn('Actions.HouseBarracksEquipEx', [aHouseID, GetEnumName(TypeInfo(TKMUnitType), Integer(aUnitType))]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6125
//* Adds a recruit inside the specified barracks
procedure TKMScriptActions.HouseBarracksGiveRecruit(aHouseID: Integer);
var
  H: TKMHouse;
begin
  try
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil)
        and (H is TKMHouseBarracks)
        and not H.IsDestroyed
        and H.IsComplete then
        TKMHouseBarracks(H).CreateRecruitInside(False);
    end
    else
      LogIntParamWarn('Actions.HouseBarracksGiveRecruit', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Adds aCount recruits inside the specified barracks
procedure TKMScriptActions.HouseBarracksGiveRecruits(aHouseID, aCount: Integer);
var
  I: Integer;
  H: TKMHouse;
begin
  try
    aCount := EnsureRange(aCount, 0, High(Word));
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil)
        and (H is TKMHouseBarracks)
        and not H.IsDestroyed
        and H.IsComplete then
        for I := 0 to aCount - 1 do
          TKMHouseBarracks(H).CreateRecruitInside(False);
    end
    else
      LogIntParamWarn('Actions.HouseBarracksGiveRecruits', [aHouseID, aCount]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Blocks or allows recruit to get into specified Barracks
procedure TKMScriptActions.HouseBarracksRecruitBlock(aHouseID: Integer; aBlocked: Boolean);
var
  H: TKMHouse;
begin
  try
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil)
        and (H is TKMHouseBarracks)
        and not H.IsDestroyed
        and H.IsComplete then
        TKMHouseBarracks(H).NotAcceptRecruitFlag := aBlocked;
    end
    else
      LogParamWarn('Actions.HouseBarracksRecruitBlock', [aHouseID, BoolToStr(aBlocked, True)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6067
//* Writes a line of text to the game log file. Useful for debugging.
//* Note that many calls to this procedure will have a noticeable performance impact,
//* as well as creating a large log file, so it is recommended you don't use it outside of debugging
procedure TKMScriptActions.Log(const aText: AnsiString);
begin
  try
    fOnScriptError(seLog, UnicodeString(aText));
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 12989
//* Set max number of error lines saved in the logs
procedure TKMScriptActions.LogLinesMaxCnt(aMaxLogLinesCnt: Integer);
begin
  try
    if Assigned(fOnSetLogLinesMaxCnt) then
      fOnSetLogLinesMaxCnt(aMaxLogLinesCnt);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//private utility function
procedure TKMScriptActions.LogStr(const aText: String);
begin
  Log(AnsiString(aText));
end;


//* Version: 11000
//* Apply brush from MapEd to the map
//* X: X coodinate
//* Y: Y coodinate
//* aSquare: is brush square or circle
//* aSize: brush size
//* aTerKind: terrain kind
//* aRandomTiles: use random tiles
//* aOverrideCustomTiles: override tiles, that were manually set from tiles table
procedure TKMScriptActions.MapBrush(X, Y: Integer; aSquare: Boolean; aSize: Integer; aTerKind: TKMTerrainKind; aRandomTiles, aOverrideCustomTiles: Boolean);
begin
  try
    if gTerrain.TileInMapCoords(X, Y) then
    begin
      gGame.TerrainPainter.SetBrushParams(X, Y, TKMMapEdShape(Byte(aSquare)), aSize, aTerKind, aRandomTiles, aOverrideCustomTiles);
      gGame.TerrainPainter.ApplyBrush;
    end
    else
    begin
      LogIntParamWarn('Actions.MapBrush', [X, Y, Byte(aSquare), aSize, Byte(aTerKind),
                                                Byte(aRandomTiles), Byte(aOverrideCustomTiles)]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Apply Elevation change brush from MapEd to the map
//* X: X coodinate
//* Y: Y coodinate
//* aSquare: is brush square or circle
//* aRaise: raise elevation or lower it
//* aSize: brush size
//* aSlope: elevation slope
//* aSpeed: elevation change speed
procedure TKMScriptActions.MapBrushElevation(X, Y: Integer; aSquare, aRaise: Boolean; aSize, aSlope, aSpeed: Integer);
begin
  try
    if gTerrain.TileInMapCoords(X, Y) then
    begin
      gGame.TerrainPainter.SetHeightParams(X, Y, TKMMapEdShape(Byte(aSquare)), aSize, False, aRaise, aSlope, aSpeed);
      gGame.TerrainPainter.ApplyHeight;
    end
    else
    begin
      LogIntParamWarn('Actions.MapBrushElevation', [X, Y, Byte(aSquare), aSize, aSlope, aSpeed]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Apply Equalize brush from MapEd to the map
//* X: X coodinate
//* Y: Y coodinate
//* aSquare: is brush square or circle
//* aSize: brush size
//* aSlope: elevation slope
//* aSpeed: elevation change speed
procedure TKMScriptActions.MapBrushEqualize(X, Y: Integer; aSquare: Boolean; aSize, aSlope, aSpeed: Integer);
begin
  try
    if gTerrain.TileInMapCoords(X, Y) then
    begin
      gGame.TerrainPainter.SetHeightParams(X, Y, TKMMapEdShape(Byte(aSquare)), aSize, True, True, aSlope, aSpeed);
      gGame.TerrainPainter.ApplyHeight;
    end
    else
    begin
      LogIntParamWarn('Actions.MapBrushEqualize', [X, Y, Byte(aSquare), aSize, aSlope, aSpeed]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Apply Flatten brush from MapEd to the map
//* X: X coodinate
//* Y: Y coodinate
//* aSquare: is brush square or circle
//* aSize: brush size
//* aSlope: elevation slope
//* aSpeed: elevation change speed
procedure TKMScriptActions.MapBrushFlatten(X, Y: Integer; aSquare: Boolean; aSize, aSlope, aSpeed: Integer);
begin
  try
    if gTerrain.TileInMapCoords(X, Y) then
    begin
      gGame.TerrainPainter.SetHeightParams(X, Y, TKMMapEdShape(Byte(aSquare)), aSize, True, False, aSlope, aSpeed);
      gGame.TerrainPainter.ApplyHeight;
    end
    else
    begin
      LogIntParamWarn('Actions.MapBrushFlatten', [X, Y, Byte(aSquare), aSize, aSlope, aSpeed]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Apply magic water brush from MapEd to the map
//* X: X coodinate
//* Y: Y coodinate
procedure TKMScriptActions.MapBrushMagicWater(X, Y: Integer);
begin
  try
    if gTerrain.TileInMapCoords(X, Y) then
    begin
      gGame.TerrainPainter.MagicWater(KMPoint(X, Y));
    end
    else
    begin
      LogIntParamWarn('Actions.MapBrushMagicWater', [X, Y]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Apply brush with mask specified from MapEd to the map
//* X: X coodinate
//* Y: Y coodinate
//* aSquare: is brush square or circle
//* aSize: brush size
//* aTerKind: terrain kind
//* aRandomTiles: use random tiles
//* aOverrideCustomTiles: override tiles, that were manually set from tiles table
//* aBrushMask: brush mask type
//* aBlendingLvl: blending level for masks. Allowed values are from 0 to 15
//* aUseMagicBrush: enable/disable magic brush to change/remove brush mask from the area
procedure TKMScriptActions.MapBrushWithMask(X, Y: Integer; aSquare: Boolean; aSize: Integer; aTerKind: TKMTerrainKind; aRandomTiles, aOverrideCustomTiles: Boolean; aBrushMask: TKMTileMaskKind; aBlendingLvl: Integer; aUseMagicBrush: Boolean);
begin
  try
    if gTerrain.TileInMapCoords(X, Y) then
    begin
      gGame.TerrainPainter.SetBrushParams(X, Y, TKMMapEdShape(Byte(aSquare)), aSize, aTerKind, aRandomTiles, aOverrideCustomTiles,
                                          aBrushMask, aBlendingLvl, aUseMagicBrush);
      gGame.TerrainPainter.ApplyBrush;
    end
    else
    begin
      LogIntParamWarn('Actions.MapBrushWithMask', [X, Y, Byte(aSquare), aSize, Byte(aTerKind), Byte(aRandomTiles),
                                                    Byte(aOverrideCustomTiles), Byte(aBrushMask), aBlendingLvl, Byte(aUseMagicBrush)]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6587
//* Sets the tile type and rotation at the specified XY coordinates.
//* Tile IDs can be seen by hovering over the tiles on the terrain tiles tab in the map editor.
//* Returns true if the change succeeded or false if it failed.
//* The change will fail if it would cause a unit to become stuck or a house/field to be damaged
//* aType: Tile type (0..255)
//* aRotation: Tile rotation (0..3)
function TKMScriptActions.MapTileSet(X, Y, aType, aRotation: Integer): Boolean;
begin
  try
    if gTerrain.TileInMapCoords(X, Y)
      and InRange(aType, 0, TILES_CNT - 1)
      and InRange(aRotation, 0, 3) then
      Result := gTerrain.ScriptTrySetTile(X, Y, aType, aRotation)
    else
    begin
      LogIntParamWarn('Actions.MapTileSet', [X, Y, aType, aRotation]);
      Result := False;
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Sets array of tiles info, with possible change of
//* 1. terrain (tile type) and/or rotation (same as for MapTileSet),
//* 2. tile height (same as for MapTileHeightSet)
//* 3. tile object (same as for MapTileObjectSet)
//* Works much faster, then applying all changes successively for every tile, because pathfinding compute is executed only once after all changes have been done
//* <pre>
//* TKMTerrainTileBrief = record
//*   X, Y: Word;     // Tile map coordinates
//*   Terrain: Word;  // Terrain tile type (0..596)
//*   Rotation: Byte; // Tile rotation (0..3)
//*   Height: Byte;   // Heigth (0..150)
//*   Obj: Word;      // Object (0..255)
//*   UpdateTerrain, UpdateRotation, UpdateHeight, UpdateObject: Boolean; // What part of tile should be updated?
//* end;
//* </pre>
//* UpdateXXX fields determines what should be changed on tile
//* F.e. if we want to change terrain type and height, then UpdateTerrain and UpdateHeight should be set to True
//* Note: aTiles elements should start from 0, as for dynamic array. So f.e. to change map tile 1,1 we should set aTiles[0][0].
//* Note: Errors are shown as map tiles (f.e. for error while applying aTiles[0][0] tile there will be a message with for map tile 1,1)
//*
//* aTiles: Check detailed info on this type in description
//* aRevertOnFail: do we need to revert all changes on any error while applying changes. If True, then no changes will be applied on error. If False - we will continue apply changes where possible
//* aShowDetailedErrors: show detailed errors after. Can slow down the execution, because of logging. If aRevertOnFail is set to True, then only first error will be shown
//* Result: True, if there was no errors on any tile. False if there was at least 1 error.
function TKMScriptActions.MapTilesArraySet(aTiles: array of TKMTerrainTileBrief; aRevertOnFail, aShowDetailedErrors: Boolean): Boolean;

  function GetTileErrorsStr(aErrorsIn: TKMTileChangeTypeSet): string;
  var
    tileChangeType: TKMTileChangeType;
  begin
    Result := '';
    for tileChangeType := Low(TKMTileChangeType) to High(TKMTileChangeType) do
      if tileChangeType in aErrorsIn then
      begin
        if Result <> '' then
          Result := Result + ', ';
        Result := Result + GetEnumName(TypeInfo(TKMTileChangeType), Integer(tileChangeType));
      end;
  end;

var
  I: Integer;
  errors: TKMTerrainTileChangeErrorArray;
begin
  try
    Result := True;
    SetLength(errors, 16);
    if not gTerrain.ScriptTrySetTilesArray(aTiles, aRevertOnFail, errors) then
    begin
      Result := False;

      // Log errors
      if Length(errors) > 0 then
      begin
        if not aShowDetailedErrors then
          Log(AnsiString(Format('Actions.MapTilesArraySet: there were %d errors while setting tiles' , [Length(errors)])))
        else
          Log('Actions.MapTilesArraySet list of tiles errors:');
      end;
      if aShowDetailedErrors then
        for I := Low(errors) to High(errors) do
          Log(AnsiString(Format('Tile: %d,%d errors while applying [%s]', [errors[I].X, errors[I].Y, GetTileErrorsStr(errors[I].ErrorsIn)])));
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Sets array of tiles info, like MapTilesArraySet, but parameters are
//* passed as an TAnsiStringArray instead of array of TKMTerrainTileBrief.
//* This function is useful if you need to create dynamic map from scratch.
//* Array must contain strings in following format: 'X,Y,Terrain,Rotation,Height,Obj'
//* f.e. '1,1,20,2,87,12'
//* In case of invalid structure detection / failed variable parsing you can find
//* detailed errors in LOG file.
//* If you need to skip terrain or rotation/height/obj use -1 as parameter
//* f.e.
//* Skipping rotation for tile [7,2]: '7,2,20,-1,87,12'
//* Skipping obj for tile [7,2]: '7,2,20,2,87,-1'
//* Skipping height for tile [7,2]: '7,2,20,2,-1,5' etc.
function TKMScriptActions.MapTilesArraySetS(aTilesS: TAnsiStringArray; aRevertOnFail, aShowDetailedErrors: Boolean): Boolean;

  function GetTileErrorsStr(aErrorsIn: TKMTileChangeTypeSet): string;
  var
    tileChangeType: TKMTileChangeType;
  begin
    Result := '';
    for tileChangeType := Low(TKMTileChangeType) to High(TKMTileChangeType) do
      if tileChangeType in aErrorsIn then
      begin
        if Result <> '' then
          Result := Result + ', ';
        Result := Result + GetEnumName(TypeInfo(TKMTileChangeType), Integer(tileChangeType));
      end;
  end;

var
  I: Integer;
  errors: TKMTerrainTileChangeErrorArray;
  tiles: array of TKMTerrainTileBrief;
  arrElem: TAnsiStringArray;
  parsedValue: Integer;
  parserError: Boolean;
begin
{$WARN SUSPICIOUS_TYPECAST OFF}
  try
    Result := True;
    SetLength(errors, 16);

    //***********PARSING ARRAY OF STRING TO ARRAY OF TKMTerrainTileBrief**********
    SetLength(tiles, Length(aTilesS));
    for I := Low(aTilesS) to High(aTilesS) do
    begin
      arrElem := StrSplitA(ReplaceStr(String(aTilesS[I]), ' ', ''), ',');
      parserError := false;

      //checking params count, if count is invalid we cannot proceed
      if (Length(arrElem) <> 6) then
        LogStr(Format('Actions.MapTilesArraySetS: Invalid number of parameters in string [%s]', [aTilesS[I]]))
      else
      begin
        //checking X, if X <= 0 we cannot proceed
        if ((TryStrToInt(string(PChar(arrElem[0])), parsedValue)) and (parsedValue > 0)) then
          tiles[I].X := parsedValue
        else
        begin
          LogStr(Format('Actions.MapTilesArraySetS: Parameter X = [%s] in line [%s] is not a valid integer.', [arrElem[0], aTilesS[I]]));
          parserError := true;
        end;
        //checking Y, if Y <= 0 we cannot proceed
        if ((TryStrToInt(string(PChar(arrElem[1])), parsedValue)) and (parsedValue > 0)) then
          tiles[I].Y := parsedValue
        else
        begin
          LogStr(Format('Actions.MapTilesArraySetS: Parameter Y = [%s] in line [%s] is not a valid integer.', [arrElem[1], aTilesS[I]]));
          parserError := true;
        end;

        //if X and Y are correctly defined we can proceed with terrain changes
        if (not parserError) then
        begin
          if (TryStrToInt(string(PChar(arrElem[2])), parsedValue)) then
          begin
            if (parsedValue >= 0) then
            begin
              //if value is not skipped we proceed with terrain
              tiles[I].Terrain := parsedValue;
              tiles[I].UpdateTerrain := True;
            end;
          end
          else
            LogStr(Format('Actions.MapTilesArraySetS: Parameter Terrain = [%s] in line [%s] is not a valid integer.', [arrElem[2], aTilesS[I]]));

          if (TryStrToInt(string(PChar(arrElem[3])), parsedValue)) then
          begin
            if (parsedValue >= 0) then
            begin
              //if value is not skipped we proceed with rotation
              tiles[I].Rotation := parsedValue;
              tiles[I].UpdateRotation := True;
            end;
          end
          else
            LogStr(Format('Actions.MapTilesArraySetS: Parameter Rotation = [%s] in line [%s] is not a valid integer.', [arrElem[3], aTilesS[I]]));

          if (TryStrToInt(string(PChar(arrElem[4])), parsedValue)) then
          begin
            if (parsedValue >= 0) then
            begin
              //if value is not skipped we proceed with height
              tiles[I].Height := parsedValue;
              tiles[I].UpdateHeight := True;
            end;
          end
          else
            LogStr(Format('Actions.MapTilesArraySetS: Parameter Height = [%s] in line [%s] is not a valid integer.', [arrElem[4], aTilesS[I]]));

          if (TryStrToInt(string(PChar(arrElem[5])), parsedValue)) then
          begin
            if (parsedValue >= 0) then
            begin
              //if value is not skipped we proceed with obj
              tiles[I].Obj := parsedValue;
              tiles[I].UpdateObject := True;
            end;
          end
          else
            LogStr(Format('Actions.MapTilesArraySetS: Parameter Obj = [%s] in line [%s] is not a valid integer.', [arrElem[5], aTilesS[I]]));
        end;
      end;
    end;
    //***********END OF PARSING**********

    if not gTerrain.ScriptTrySetTilesArray(tiles, aRevertOnFail, errors) then
    begin
      Result := False;

      // Log errors
      if Length(errors) > 0 then
      begin
        if not aShowDetailedErrors then
          Log(AnsiString(Format('Actions.MapTilesArraySetS: there were %d errors while setting tiles' , [Length(errors)])))
        else
          Log('Actions.MapTilesArraySetS list of tiles errors:');
      end;
      if aShowDetailedErrors then
        for I := Low(errors) to High(errors) do
          Log(AnsiString(Format('Tile: %d,%d errors while applying [%s]', [errors[I].X, errors[I].Y, GetTileErrorsStr(errors[I].ErrorsIn)])));
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
{$WARN SUSPICIOUS_TYPECAST ON}
end;


//* Version: 6587
//* Sets the height of the terrain at the top left corner (vertex) of the tile at the specified XY coordinates.
//* Returns true if the change succeeded or false if it failed.
//* The change will fail if it would cause a unit to become stuck or a house to be damaged
//* Height: Height (0..100)
function TKMScriptActions.MapTileHeightSet(X, Y, Height: Integer): Boolean;
begin
  try
    //Height is vertex based not tile based
    if gTerrain.VerticeInMapCoords(X, Y) and InRange(Height, 0, HEIGHT_MAX) then
      Result := gTerrain.ScriptTrySetTileHeight(X, Y, Height)
    else
    begin
      LogIntParamWarn('Actions.MapTileHeightSet', [X, Y, Height]);
      Result := False;
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6587
//* Sets the terrain object on the tile at the specified XY coordinates.
//* Object IDs can be seen in the map editor on the objects tab.
//* Object 61 is "block walking". To set no object, use object type 255.
//* Returns true if the change succeeded or false if it failed.
//* The change will fail if it would cause a unit to become stuck or a house/field to be damaged
//* Obj: Object type (0..255)
function TKMScriptActions.MapTileObjectSet(X, Y, Obj: Integer): Boolean;
begin
  try
    //Objects are vertex based not tile based
    if gTerrain.VerticeInMapCoords(X, Y) and InRange(Obj, 0, OBJECTS_CNT) then
      Result := gTerrain.ScriptTrySetTileObject(X, Y, Obj)
    else
    begin
      LogIntParamWarn('Actions.MapTileObjectSet', [X, Y, Obj]);
      Result := False;
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Sets the terrain overlay on the tile at the specified XY coordinates.
//* aOverwrite: False means safe way to change tile overlay, disallowing to set it on top of old fields/roads
//* aOverwrite: True allows to destroy roads and re-dig fields (like in game we can build road on top of field and when laborer dies there is a digged overlay left)
function TKMScriptActions.MapTileOverlaySet(X, Y: Integer; aOverlay: TKMTileOverlay; aOverwrite: Boolean): Boolean;
begin
  try
    Result := True;
    if gTerrain.TileInMapCoords(X, Y)
      and (aOverlay in [Low(TKMTileOverlay)..High(TKMTileOverlay)]) then
      gTerrain.SetOverlay(KMPoint(X, Y), aOverlay, aOverwrite)
    else
    begin
      LogIntParamWarn('Actions.MapTileOverlaySet', [X, Y, Byte(aOverlay), Byte(aOverwrite)]);
      Result := False;
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6216
//* Sets the trade in the specified market
procedure TKMScriptActions.MarketSetTrade(aMarketID, aFrom, aTo, aAmount: Integer);
var
  H: TKMHouse;
  resFrom, resTo: TKMWareType;
begin
  try
    if (aMarketID > 0)
    and (aFrom in [Low(WARE_ID_TO_TYPE)..High(WARE_ID_TO_TYPE)])
    and (aTo in [Low(WARE_ID_TO_TYPE)..High(WARE_ID_TO_TYPE)]) then
    begin
      H := fIDCache.GetHouse(aMarketID);
      resFrom := WARE_ID_TO_TYPE[aFrom];
      resTo := WARE_ID_TO_TYPE[aTo];
      if (H is TKMHouseMarket)
        and not H.IsDestroyed
        and H.IsComplete
        and TKMHouseMarket(H).AllowedToTrade(resFrom)
        and TKMHouseMarket(H).AllowedToTrade(resTo) then
      begin
        if (TKMHouseMarket(H).ResFrom <> resFrom) or (TKMHouseMarket(H).ResTo <> resTo) then
        begin
          TKMHouseMarket(H).ResOrder[0] := 0; //First we must cancel the current trade
          TKMHouseMarket(H).ResFrom := resFrom;
          TKMHouseMarket(H).ResTo := resTo;
        end;
        TKMHouseMarket(H).ResOrder[0] := aAmount; //Set the new trade
      end;
    end
    else
      LogIntParamWarn('Actions.MarketSetTrade', [aMarketID, aFrom, aTo, aAmount]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Sets the trade in the specified market
procedure TKMScriptActions.MarketSetTradeEx(aMarketID: Integer; aFrom, aTo: TKMWareType; aAmount: Integer);
var
  H: TKMHouse;
begin
  try
    if (aMarketID > 0)
      and (aFrom in WARES_VALID)
      and (aTo in WARES_VALID) then
    begin
      H := fIDCache.GetHouse(aMarketID);
      if (H is TKMHouseMarket)
        and not H.IsDestroyed
        and H.IsComplete
        and TKMHouseMarket(H).AllowedToTrade(aFrom)
        and TKMHouseMarket(H).AllowedToTrade(aTo) then
      begin
        if (TKMHouseMarket(H).ResFrom <> aFrom) or (TKMHouseMarket(H).ResTo <> aTo) then
        begin
          TKMHouseMarket(H).ResOrder[0] := 0; //First we must cancel the current trade
          TKMHouseMarket(H).ResFrom := aFrom;
          TKMHouseMarket(H).ResTo := aTo;
        end;
        TKMHouseMarket(H).ResOrder[0] := aAmount; //Set the new trade
      end;
    end
    else
      LogParamWarn('Actions.MarketSetTradeEx', [aMarketID,
                                                GetEnumName(TypeInfo(TKMWareType), Integer(aFrom)),
                                                GetEnumName(TypeInfo(TKMWareType), Integer(aTo)), aAmount]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5333
//* Sets text overlaid on top left of screen.
//* If the player index is -1 it will be set for all players.
procedure TKMScriptActions.OverlayTextSet(aHand: Shortint; const aText: AnsiString);
begin
  try
    //Text from script should be only ANSI Latin, but UI is Unicode, so we switch it
    if InRange(aHand, -1, gHands.Count - 1) then //-1 means all players
      gGame.OverlaySet(aHand, aText, [])
    else
      LogIntParamWarn('Actions.OverlayTextSet: '+UnicodeString(aText), [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5333
//* Sets text overlaid on top left of screen with formatted arguments (same as Format function).
//* If the player index is -1 it will be set for all players.
//* Params: Array of arguments
procedure TKMScriptActions.OverlayTextSetFormatted(aHand: Shortint; const aText: AnsiString; aParams: array of const);
begin
  try
    if InRange(aHand, -1, gHands.Count - 1) then //-1 means all players
    begin
      try
        gGame.OverlaySet(aHand, aText, aParams);
      except
        //Format may throw an exception
        on E: EConvertError do
          LogIntParamWarn('Actions.OverlayTextSetFormatted: EConvertError: ' + E.Message, []);
      end;
    end
    else
      LogIntParamWarn('Actions.OverlayTextSetFormatted: ' + UnicodeString(aText), [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Sets text overlay font
//* Possible values are: fntAntiqua, fntGame, fntGrey, fntMetal, fntMini, fntOutline, fntArial, fntMonospaced
//* If the player index is -1 it will be set for all players.
procedure TKMScriptActions.OverlayTextSetFont(aHand: Shortint; aFont: TKMFont);
begin
  try
    if InRange(aHand, -1, gHands.Count - 1) then //-1 means all players
    begin
      gGame.OverlaySetFont(aHand, aFont);
    end
    else
      LogParamWarn('Actions.OverlayTextSetFont', [aHand, GetEnumName(TypeInfo(TKMFont), Integer(aFont))]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Sets or unsets text overlay word wrap
//* If the player index is -1 it will be set for all players.
procedure TKMScriptActions.OverlayTextSetWordWrap(aHand: Shortint; aWordWrap: Boolean);
begin
  try
    if InRange(aHand, -1, gHands.Count - 1) then //-1 means all players
    begin
      gGame.OverlaySetWordWrap(aHand, aWordWrap);
    end
    else
      LogParamWarn('Actions.OverlayTextSetWordWrap', [aHand, aWordWrap]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5333
//* Appends to text overlaid on top left of screen.
//* If the player index is -1 it will be appended for all players.
procedure TKMScriptActions.OverlayTextAppend(aHand: Shortint; const aText: AnsiString);
begin
  try
    if InRange(aHand, -1, gHands.Count - 1) then //-1 means all players
      gGame.OverlayAppend(aHand, aText, [])
    else
      LogIntParamWarn('Actions.OverlayTextAppend: ' + UnicodeString(aText), [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5333
//* Appends to text overlaid on top left of screen with formatted arguments (same as Format function).
//* If the player index is -1 it will be appended for all players.
//* Params: Array of arguments
procedure TKMScriptActions.OverlayTextAppendFormatted(aHand: Shortint; const aText: AnsiString; aParams: array of const);
begin
  try
    if InRange(aHand, -1, gHands.Count - 1) then //-1 means all players
    begin
      try
        gGame.OverlayAppend(aHand, aText, aParams);
      except
        //Format may throw an exception
        on E: EConvertError do
          LogIntParamWarn('Actions.OverlayTextAppendFormatted: EConvertError: ' + E.Message, []);
      end;
    end
    else
      LogIntParamWarn('Actions.OverlayTextAppendFormatted: ' + UnicodeString(aText), [aHand]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Adds a road plan.
//* Returns true if the plan was successfully added or false if it failed (e.g. tile blocked)
function TKMScriptActions.PlanAddRoad(aHand, X, Y: Integer): Boolean;
begin
  try
    Result := False;
    //Verify all input parameters
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
    and gTerrain.TileInMapCoords(X,Y) then
    begin
      if gHands[aHand].CanAddFieldPlan(KMPoint(X, Y), ftRoad) then
      begin
        Result := True;
        gHands[aHand].Constructions.FieldworksList.AddField(KMPoint(X, Y), ftRoad);
      end;
    end
    else
      LogIntParamWarn('Actions.PlanAddRoad', [aHand, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Sets game peacetime. Peacetime will be set to the value of aPeacetime div 600
//* aPeacetime: game time in ticks
procedure TKMScriptActions.Peacetime(aPeacetime: Cardinal);
begin
  try
    gGame.Options.Peacetime := aPeacetime div 600; //PT in minutes
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Adds a corn field plan.
//* Returns true if the plan was successfully added or false if it failed (e.g. tile blocked)
function TKMScriptActions.PlanAddField(aHand, X, Y: Integer): Boolean;
begin
  try
    Result := False;
    //Verify all input parameters
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
    and gTerrain.TileInMapCoords(X,Y) then
    begin
      if gHands[aHand].CanAddFieldPlan(KMPoint(X, Y), ftCorn) then
      begin
        Result := True;
        gHands[aHand].Constructions.FieldworksList.AddField(KMPoint(X, Y), ftCorn);
      end;
    end
    else
      LogIntParamWarn('Actions.PlanAddField', [aHand, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Adds a wine field plan.
//* Returns true if the plan was successfully added or false if it failed (e.g. tile blocked)
function TKMScriptActions.PlanAddWinefield(aHand, X, Y: Integer): Boolean;
begin
  try
    Result := False;
    //Verify all input parameters
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
    and gTerrain.TileInMapCoords(X,Y) then
    begin
      if gHands[aHand].CanAddFieldPlan(KMPoint(X, Y), ftWine) then
      begin
        Result := True;
        gHands[aHand].Constructions.FieldworksList.AddField(KMPoint(X, Y), ftWine);
      end;
    end
    else
      LogIntParamWarn('Actions.PlanAddWinefield', [aHand, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6303
//* Connects road plans between two points like AI builder and returns True if road plan was successfully added.
//* If CompletedRoad = True, road will be added instead of plans
//* X1: Left coordinate
//* Y1: Top coordinate
//* X2: Right coordinate
//* Y2: Bottom coordinate
//* aCompleted: Completed road
function TKMScriptActions.PlanConnectRoad(aHand, X1, Y1, X2, Y2: Integer; aCompleted: Boolean): Boolean;
var
  I: Integer;
  points: TKMPointList;
  planExists: Boolean;
  path: TKMPathFindingRoad;
begin
  try
    Result := False;
    if InRange(aHand, 0, gHands.Count - 1)
    and (gHands[aHand].Enabled)
    and gTerrain.TileInMapCoords(X1, Y1)
    and gTerrain.TileInMapCoords(X2, Y2) then
    begin
      path := TKMPathFindingRoad.Create(aHand);
      points := TKMPointList.Create;
      try
        planExists := path.Route_ReturnToWalkable(KMPoint(X1, Y1), KMPoint(X2, Y2), 0, points);
        if not planExists then
          Exit;
        for I := 0 to points.Count - 1 do
          if gHands[aHand].CanAddFieldPlan(points[I], ftRoad) then
            if not aCompleted then
              gHands[aHand].Constructions.FieldworksList.AddField(points[I], ftRoad)
            else
            begin
              gTerrain.SetRoad(points[I], aHand);
              gTerrain.FlattenTerrain(points[I]);
              if gMapElements[gTerrain.Land^[points[I].Y,points[I].X].Obj].WineOrCorn then
                gTerrain.RemoveObject(points[I]); //Remove corn/wine like normally built road does
            end;
        Result := True;
      finally
        points.Free;
        path.Free;
      end;
    end
    else
      LogIntParamWarn('Actions.PlanConnectRoad', [aHand, X1, Y1, X2, Y2]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5345
//* Removes house, road or field plans from the specified tile for the specified player
//* Returns true if the plan was successfully removed or false if it failed (e.g. tile blocked)
function TKMScriptActions.PlanRemove(aHand, X, Y: Integer): Boolean;
var
  housePlan: TKMHousePlan;
begin
  try
    Result := False;
    //Verify all input parameters
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
    and gTerrain.TileInMapCoords(X,Y) then
    begin
      if gHands[aHand].Constructions.HousePlanList.TryGetPlan(KMPoint(X, Y), housePlan) then
      begin
        gHands[aHand].Constructions.HousePlanList.RemPlan(KMPoint(X, Y));
        gHands[aHand].Stats.HousePlanRemoved(housePlan.HouseType);
        Result := True;
      end;
      if gHands[aHand].Constructions.FieldworksList.HasField(KMPoint(X, Y)) <> ftNone then
      begin
        gHands[aHand].Constructions.FieldworksList.RemFieldPlan(KMPoint(X, Y));
        Result := True;
      end;
    end
    else
      LogIntParamWarn('Actions.PlanRemove', [aHand, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Adds a road plan.
//* Returns true if the plan was successfully added or false if it failed (e.g. tile blocked)
function TKMScriptActions.PlanAddHouse(aHand, aHouseType, X, Y: Integer): Boolean;
begin
  Result := False;
  try
    //Verify all input parameters
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
      and HouseTypeValid(aHouseType)
      and gTerrain.TileInMapCoords(X,Y) then
    begin
      if gHands[aHand].CanAddHousePlan(KMPoint(X, Y), HOUSE_ID_TO_TYPE[aHouseType]) then
      begin
        Result := True;
        gHands[aHand].AddHousePlan(HOUSE_ID_TO_TYPE[aHouseType], KMPoint(X, Y));
      end;
    end
    else
      LogIntParamWarn('Actions.PlanAddHouse', [aHand, aHouseType, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Adds a road plan.
//* Returns true if the plan was successfully added or false if it failed (e.g. tile blocked)
function TKMScriptActions.PlanAddHouseEx(aHand: Integer; aHouseType: TKMHouseType; X, Y: Integer): Boolean;
begin
  Result := False;
  try
    //Verify all input parameters
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
      and (aHouseType in HOUSES_VALID)
      and gTerrain.TileInMapCoords(X,Y) then
    begin
      if gHands[aHand].CanAddHousePlan(KMPoint(X, Y), aHouseType) then
      begin
        Result := True;
        gHands[aHand].AddHousePlan(aHouseType, KMPoint(X, Y));
      end;
    end
    else
      LogParamWarn('Actions.PlanAddHouseEx', [aHand, GetEnumName(TypeInfo(TKMHouseType), Integer(aHouseType)), X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 12600
//* Allows allies to select and view specified unit
//* For warriors: allow to select their group
procedure TKMScriptActions.UnitAllowAllyToSelect(aUnitID: Integer; aAllow: Boolean);
var
  U: TKMUnit;
begin
  try
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U <> nil then
      begin
        U.AllowAllyToSelect := aAllow;
      end;
      //Silently ignore if unit doesn't exist
    end
    else
      LogIntParamWarn('Actions.UnitAllowAllyToView', [aUnitID, Byte(aAllow)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5993
//* Sets whether the specified player can train/equip the specified unit type
procedure TKMScriptActions.UnitBlock(aHand: Byte; aType: Integer; aBlock: Boolean);
begin
  try
    if InRange(aHand, 0, gHands.Count - 1) and (gHands[aHand].Enabled)
    and (aType in [Low(UNIT_ID_TO_TYPE) .. High(UNIT_ID_TO_TYPE)]) then
      gHands[aHand].Locks.SetUnitBlocked(aBlock, UNIT_ID_TO_TYPE[aType])
    else
      LogIntParamWarn('Actions.UnitBlock', [aHand, aType, Byte(aBlock)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Heals/Wounds specified unit for aHP HP
procedure TKMScriptActions.UnitHPChange(aUnitID, aHP: Integer);
var
  U: TKMUnit;
begin
  try
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U <> nil then
        U.HitPointsChangeFromScript(aHP);
    end
    else
      LogIntParamWarn('Actions.UnitHPChange', [aUnitID, aHP]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Makes the unit invulnerable. Such unit can not be killed or die from hunger.
procedure TKMScriptActions.UnitHPSetInvulnerable(aUnitID: Integer; aInvulnerable: Boolean);
var
  U: TKMUnit;
begin
  try
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U <> nil then
        U.HitPointsInvulnerable := aInvulnerable;
    end
    else
      LogIntParamWarn('Actions.UnitHPSetInvulnerable', [aUnitID, Ord(aInvulnerable)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Sets the hunger level of the specified unit in ticks until death
//* aHungerLevel: Hunger level (ticks until death)
procedure TKMScriptActions.UnitHungerSet(aUnitID, aHungerLevel: Integer);
var
  U: TKMUnit;
begin
  try
    aHungerLevel := Round(aHungerLevel / CONDITION_PACE);
    if (aUnitID > 0) and InRange(aHungerLevel, 0, UNIT_MAX_CONDITION) then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U <> nil then
        U.Condition := aHungerLevel;
    end
    else
      LogIntParamWarn('Actions.UnitHungerSet', [aUnitID, aHungerLevel]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Makes the specified unit face a certain direction.
//* Note: Only works on idle units so as not to interfere with game logic and cause crashes.
//* Returns true on success or false on failure.
function TKMScriptActions.UnitDirectionSet(aUnitID, aDirection: Integer): Boolean;
var
  U: TKMUnit;
begin
  try
    Result := False;
    if (aUnitID > 0) and (TKMDirection(aDirection+1) in [dirN..dirNW]) then
    begin
      U := fIDCache.GetUnit(aUnitID);
      //Can only make idle units outside houses change direction so we don't mess up tasks and cause crashes
      if (U <> nil) and U.IsIdle and U.Visible then
      begin
        Result := True;
        U.Direction := TKMDirection(aDirection+1);
      end;
    end
    else
      LogIntParamWarn('Actions.UnitDirectionSet', [aUnitID, aDirection]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Makes the specified unit face a certain direction.
//* Note: Only works on idle units so as not to interfere with game logic and cause crashes.
//* Returns true on success or false on failure.
function TKMScriptActions.UnitDirectionSetEx(aUnitID: Integer; aDirection: TKMDirection): Boolean;
var
  U: TKMUnit;
begin
  Result := False;
  try
    if (aUnitID > 0) and (aDirection in [dirN..dirNW]) then
    begin
      U := fIDCache.GetUnit(aUnitID);
      //Can only make idle units outside houses change direction so we don't mess up tasks and cause crashes
      if (U <> nil) and U.IsIdle and U.Visible then
      begin
        Result := True;
        U.Direction := aDirection;
      end;
    end
    else
      LogParamWarn('Actions.UnitDirectionSetEx', [aUnitID, GetEnumName(TypeInfo(TKMDirection), Integer(aDirection))]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Dismiss the specified unit
procedure TKMScriptActions.UnitDismiss(aUnitID: Integer);
var
  U: TKMUnit;
begin
  try
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U <> nil then
        U.Dismiss;
    end
    else
      LogIntParamWarn('Actions.UnitDismiss', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Makes the specified unit 'dismiss' command available
procedure TKMScriptActions.UnitDismissableSet(aUnitID: Integer; aDismissable: Boolean);
var
  U: TKMUnit;
begin
  try
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U <> nil then
        U.Dismissable := aDismissable;
    end
    else
      LogIntParamWarn('Actions.UnitDismissableSet', [aUnitID, Byte(aDismissable)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Cancel dismiss task for the specified unit
procedure TKMScriptActions.UnitDismissCancel(aUnitID: Integer);
var
  U: TKMUnit;
begin
  try
    if aUnitID > 0 then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U <> nil then
        U.DismissCancel;
    end
    else
      LogIntParamWarn('Actions.UnitDismissCancel', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Order the specified unit to walk somewhere.
//* Note: Only works on idle units so as not to interfere with game logic and cause crashes.
//* Returns true on success or false on failure.
function TKMScriptActions.UnitOrderWalk(aUnitID: Integer; X, Y: Integer): Boolean;
var
  U: TKMUnit;
begin
  try
    Result := False;

    if (aUnitID > 0) and gTerrain.TileInMapCoords(X, Y) then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U = nil then Exit; //Unit could have long died, or never existed

      //Animals cant be ordered to walk, they use Steering instead
      if (U.UnitType in [ANIMAL_MIN..ANIMAL_MAX]) then
        LogIntParamWarn('Actions.UnitOrderWalk is not supported for animals', [aUnitID, X, Y])
      else
        //Can only make idle or units in houses walk so we don't mess up tasks and cause crashes
        if U.IsIdle and U.Visible then
        begin
          Result := True;
          U.SetActionWalkToSpot(KMPoint(X,Y), uaWalk);
        end;
    end
    else
      LogIntParamWarn('Actions.UnitOrderWalk', [aUnitID, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5099
//* Kills the specified unit.
//* Silent means the death animation (ghost) and sound won't play
procedure TKMScriptActions.UnitKill(aUnitID: Integer; aSilent: Boolean);
var
  U: TKMUnit;
begin
  try
    if (aUnitID > 0) then
    begin
      U := fIDCache.GetUnit(aUnitID);
      if U <> nil then
        //Force delay to let the unit choose when to die, because this could be called in the middle of an event
        U.Kill(HAND_NONE, not aSilent, True);
    end
    else
      LogIntParamWarn('Actions.UnitKill', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Changes game speed
procedure TKMScriptActions.GameSpeed(aSpeed: Single);
var
  speed: Single;
begin
  try
    if gGameParams.IsMultiplayer then
      speed := EnsureRange(aSpeed, GAME_SPEED_NORMAL, GAME_MP_SPEED_MAX)
    else
      speed := EnsureRange(aSpeed, GAME_SPEED_NORMAL, GAME_SP_SPEED_MAX);

    gGame.SetSpeedGIP(speed, True, True);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Allows or blocks game speed change
procedure TKMScriptActions.GameSpeedChangeAllowed(aAllowed: Boolean);
begin
  try
    gGame.SpeedChangeAllowed := aAllowed;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 12600
//* Allows allies to select and view specified group
procedure TKMScriptActions.GroupAllowAllyToSelect(aGroupID: Integer; aAllow: Boolean);
var
  G: TKMUnitGroup;
begin
  try
    if aGroupID > 0 then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if G <> nil then
      begin
        G.AllowAllyToSelect := aAllow;
      end;
      //Silently ignore if house doesn't exist
    end
    else
      LogIntParamWarn('Actions.GroupAllowAllyToSelect', [aGroupID, Byte(aAllow)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;

//* Version: 6277
//* Disables (Disable = True) or enables (Disable = False) control over specifed warriors group
procedure TKMScriptActions.GroupBlockOrders(aGroupID: Integer; aBlock: Boolean);
var
  G: TKMUnitGroup;
begin
  try
    if aGroupID > 0 then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if G <> nil then
        G.BlockOrders := aBlock;
    end
    else
      LogIntParamWarn('Actions.GroupBlockOrders', [aGroupID, Byte(aBlock)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5993
//* Sets whether the specified group will alert the player when they become hungry
//* (true to disable hunger messages, false to enable them)
procedure TKMScriptActions.GroupDisableHungryMessage(aGroupID: Integer; aDisable: Boolean);
var
  G: TKMUnitGroup;
begin
  try
    if aGroupID > 0 then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if G <> nil then
        G.DisableHungerMessage := aDisable;
    end
    else
      LogIntParamWarn('Actions.GroupDisableHungryMessage', [aGroupID, Byte(aDisable)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5993
//* Set hunger level for all group members
//* aHungerLevel: Hunger level (ticks until death)
procedure TKMScriptActions.GroupHungerSet(aGroupID, aHungerLevel: Integer);
var
  I: Integer;
  G: TKMUnitGroup;
begin
  try
    aHungerLevel := Round(aHungerLevel / CONDITION_PACE);
    if (aGroupID > 0) and InRange(aHungerLevel, 0, UNIT_MAX_CONDITION) then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if G <> nil then
        for I := 0 to G.Count - 1 do
          if (G.Members[I] <> nil) and (not G.Members[I].IsDeadOrDying) then
            G.Members[I].Condition := aHungerLevel;
    end
    else
      LogIntParamWarn('Actions.GroupHungerSet', [aGroupID, aHungerLevel]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5993
//* Kills all members of the specified group
procedure TKMScriptActions.GroupKillAll(aGroupID: Integer; aSilent: Boolean);
var
  G: TKMUnitGroup;
  I: Integer;
begin
  try
    if (aGroupID > 0) then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if G <> nil then
        for I := G.Count - 1 downto 0 do
          G.Members[I].Kill(HAND_NONE, not aSilent, True);
    end
    else
      LogIntParamWarn('Actions.GroupKillAll', [aGroupID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Order the specified group to attack the specified house
procedure TKMScriptActions.GroupOrderAttackHouse(aGroupID, aHouseID: Integer);
var
  G: TKMUnitGroup;
  H: TKMHouse;
begin
  try
    if (aGroupID > 0) and (aHouseID > 0) then
    begin
      G := fIDCache.GetGroup(aGroupID);
      H := fIDCache.GetHouse(aHouseID);
      if (G <> nil)
        and (H <> nil)
        and not H.IsDestroyed then
        G.OrderAttackHouse(H, True);
    end
    else
      LogIntParamWarn('Actions.GroupOrderAttackHouse', [aGroupID, aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Order the specified group to attack the specified unit
procedure TKMScriptActions.GroupOrderAttackUnit(aGroupID, aUnitID: Integer);
var
  G: TKMUnitGroup;
  U: TKMUnit;
begin
  try
    if (aGroupID > 0) and (aUnitID > 0) then
    begin
      G := fIDCache.GetGroup(aGroupID);
      U := fIDCache.GetUnit(aUnitID);

      //Player can not attack animals
      if (G <> nil) and (U <> nil) and (U.Owner <> HAND_ANIMAL) then
        G.OrderAttackUnit(U, True);
    end
    else
      LogIntParamWarn('Actions.GroupOrderAttackUnit', [aGroupID, aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Order the specified group to request food
procedure TKMScriptActions.GroupOrderFood(aGroupID: Integer);
var
  G: TKMUnitGroup;
begin
  try
    if (aGroupID > 0) then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if (G <> nil) then
        G.OrderFood(True);
    end
    else
      LogIntParamWarn('Actions.GroupOrderFood', [aGroupID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Order the specified group to halt
procedure TKMScriptActions.GroupOrderHalt(aGroupID: Integer);
var
  G: TKMUnitGroup;
begin
  try
    if (aGroupID > 0) then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if (G <> nil) then
        G.OrderHalt(True);
    end
    else
      LogIntParamWarn('Actions.GroupOrderHalt', [aGroupID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Order the first specified group to link to the second specified group
procedure TKMScriptActions.GroupOrderLink(aGroupID, aDestGroupID: Integer);
var
  G, G2: TKMUnitGroup;
begin
  try
    if (aGroupID > 0) and (aDestGroupID > 0) then
    begin
      G := fIDCache.GetGroup(aGroupID);
      G2 := fIDCache.GetGroup(aDestGroupID);
      if (G <> nil) and (G2 <> nil) and (G.Owner = G2.Owner) then  //Check group owners to prevent "DNA Modifications" ;D
        G.OrderLinkTo(G2, True);
    end
    else
      LogIntParamWarn('Actions.GroupOrderLink', [aGroupID, aDestGroupID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Order the specified group to split in half.
//* Return the newly create group ID or -1 if splitting failed (e.g. only 1 member)
function TKMScriptActions.GroupOrderSplit(aGroupID: Integer): Integer;
var
  G, G2: TKMUnitGroup;
begin
  try
    Result := UID_NONE;
    if (aGroupID > 0) then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if (G <> nil) then
      begin
        G2 := G.OrderSplit;
        if G2 <> nil then
          Result := G2.UID;
      end;
    end
    else
      LogIntParamWarn('Actions.GroupOrderSplit', [aGroupID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6338
//* Splits specified unit from the group.
//* Returns the newly create group ID or -1 if splitting failed (e.g. only 1 member)
function TKMScriptActions.GroupOrderSplitUnit(aGroupID, aUnitID: Integer): Integer;
var
  G, G2: TKMUnitGroup;
  U: TKMUnit;
begin
  try
    Result := UID_NONE;
    if (aGroupID > 0)
    and (aUnitID > 0) then
    begin
      G := fIDCache.GetGroup(aGroupID);
      U := fIDCache.GetUnit(aUnitID);
      if (G <> nil)
      and (U <> nil)
      and (U is TKMUnitWarrior)
      and (G.HasMember(TKMUnitWarrior(U))) then
      begin
        G2 := G.OrderSplitUnit(TKMUnitWarrior(U), True);
        if G2 <> nil then
          Result := G2.UID;
      end;
    end
    else
      LogIntParamWarn('Actions.GroupOrderSplitSelected', [aGroupID, aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Order the specified group to storm attack
procedure TKMScriptActions.GroupOrderStorm(aGroupID: Integer);
var
  G: TKMUnitGroup;
begin
  try
    if (aGroupID > 0) then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if (G <> nil) and (G.GroupType = gtMelee) then
        G.OrderStorm(True);
    end
    else
      LogIntParamWarn('Actions.GroupOrderStorm', [aGroupID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Order the specified group to walk somewhere
procedure TKMScriptActions.GroupOrderWalk(aGroupID: Integer; X, Y, aDirection: Integer);
var
  G: TKMUnitGroup;
begin
  try
    if (aGroupID > 0)
      and gTerrain.TileInMapCoords(X, Y)
      and (TKMDirection(aDirection + 1) in [dirN..dirNW]) then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if (G <> nil) and G.CanWalkTo(KMPoint(X,Y), 0) then
        G.OrderWalk(KMPoint(X,Y), True, wtokScript, TKMDirection(aDirection+1));
    end
    else
      LogIntParamWarn('Actions.GroupOrderWalk', [aGroupID, X, Y, aDirection]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 14000
//* Order the specified group to walk somewhere
procedure TKMScriptActions.GroupOrderWalkEx(aGroupID: Integer; X, Y: Integer; aDirection: TKMDirection);
var
  G: TKMUnitGroup;
begin
  try
    if (aGroupID > 0)
      and gTerrain.TileInMapCoords(X, Y)
      and (aDirection in [dirN..dirNW]) then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if (G <> nil) and G.CanWalkTo(KMPoint(X,Y), 0) then
        G.OrderWalk(KMPoint(X,Y), True, wtokScript, aDirection);
    end
    else
      LogParamWarn('Actions.GroupOrderWalkEx', [aGroupID, X, Y, GetEnumName(TypeInfo(TKMDirection), Integer(aDirection))]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Sets the number of columns (units per row) for the specified group
procedure TKMScriptActions.GroupSetFormation(aGroupID: Integer; aNumColumns: Byte);
var
  G: TKMUnitGroup;
begin
  try
    if (aGroupID > 0) then
    begin
      G := fIDCache.GetGroup(aGroupID);
      if G <> nil then
        G.UnitsPerRow := aNumColumns;
    end
    else
      LogIntParamWarn('Actions.GroupSetFormation', [aGroupID, aNumColumns]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


end.
