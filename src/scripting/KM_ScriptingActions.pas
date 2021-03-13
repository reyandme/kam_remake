unit KM_ScriptingActions;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, SysUtils, StrUtils, KM_AIAttacks, KM_ResTileset,
  KM_CommonTypes, KM_Defaults, KM_Points, KM_Houses, KM_ScriptingIdCache, KM_Units, KM_Terrain, KM_Sound,
  KM_UnitGroup, KM_ResHouses, KM_HouseCollection, KM_ResWares, KM_ScriptingEvents, KM_ScriptingTypes;


type
  TKMScriptActions = class(TKMScriptEntity)
  private
    procedure LogStr(const aText: String);
  public
    procedure AIArmyType(aPlayer: Byte; aType: TKMArmyType);
    function AIAttackAdd(aPlayer: Byte; aRepeating: Boolean; aDelay: Cardinal; aTotalMen: Integer;
                         aMelleCount, aAntiHorseCount, aRangedCount, aMountedCount: Word; aRandomGroups: Boolean;
                         aTarget: TKMAIAttackTarget; aCustomPosition: TKMPoint): Integer;
    function AIAttackRemove(aPlayer: Byte; aAIAttackId: Word): Boolean;
    procedure AIAttackRemoveAll(aPlayer: Byte);
    procedure AIAutoAttackRange(aPlayer: Byte; aRange: Word);
    procedure AIAutoBuild(aPlayer: Byte; aAuto: Boolean);
    procedure AIAutoDefence(aPlayer: Byte; aAuto: Boolean);
    procedure AIAutoRepair(aPlayer: Byte; aAuto: Boolean);
    procedure AIDefencePositionAdd(aPlayer: Byte; X, Y: Integer; aDir, aGroupType: Byte; aRadius: Word; aDefType: Byte);
    procedure AIDefencePositionRemove(aPlayer: Byte; X, Y: Integer);
    procedure AIDefencePositionRemoveAll(aPlayer: Byte);
    procedure AIDefendAllies(aPlayer: Byte; aDefend: Boolean);
    procedure AIEquipRate(aPlayer: Byte; aType: Byte; aRate: Word);
    procedure AIGroupsFormationSet(aPlayer, aType: Byte; aCount, aColumns: Word);
    procedure AIRecruitDelay(aPlayer: Byte; aDelay: Cardinal);
    procedure AIRecruitLimit(aPlayer, aLimit: Byte);
    procedure AISerfsPerHouse(aPlayer: Byte; aSerfs: Single);
    procedure AISoldiersLimit(aPlayer: Byte; aLimit: Integer);
    procedure AIStartPosition(aPlayer: Byte; X, Y: Word);
    procedure AIWorkerLimit(aPlayer, aLimit: Byte);

    procedure CinematicStart(aPlayer: Byte);
    procedure CinematicEnd(aPlayer: Byte);
    procedure CinematicPanTo(aPlayer: Byte; X, Y, Duration: Word);

    function  GiveAnimal(aType, X,Y: Word): Integer;
    function  GiveField(aPlayer, X, Y: Word): Boolean;
    function  GiveFieldAged(aPlayer, X, Y: Word; aStage: Byte; aRandomAge: Boolean): Boolean;
    function  GiveGroup(aPlayer, aType, X,Y, aDir, aCount, aColumns: Word): Integer;
    function  GiveHouse(aPlayer, aHouseType, X,Y: Integer): Integer;
    function  GiveHouseSite(aPlayer, aHouseType, X, Y: Integer; aAddMaterials: Boolean): Integer;
    function  GiveUnit(aPlayer, aType, X,Y, aDir: Word): Integer;
    function  GiveRoad(aPlayer, X, Y: Word): Boolean;
    procedure GiveWares(aPlayer, aType, aCount: Word);
    procedure GiveWeapons(aPlayer, aType, aCount: Word);
    function  GiveWinefield(aPlayer, X, Y: Word): Boolean;
    function  GiveWinefieldAged(aPlayer, X, Y: Word; aStage: Byte; aRandomAge: Boolean): Boolean;

    procedure FogCoverAll(aPlayer: Byte);
    procedure FogCoverCircle(aPlayer, X, Y, aRadius: Word);
    procedure FogRevealRect(aPlayer, X1, Y1, X2, Y2: Word);
    procedure FogCoverRect(aPlayer, X1, Y1, X2, Y2: Word);
    procedure FogRevealAll(aPlayer: Byte);
    procedure FogRevealCircle(aPlayer, X, Y, aRadius: Word);

    procedure GameSpeed(aSpeed: Single);
    procedure GameSpeedChangeAllowed(aAllowed: Boolean);

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
    procedure GroupOrderWalk(aGroupID: Integer; X, Y, aDirection: Word);
    procedure GroupSetFormation(aGroupID: Integer; aNumColumns: Byte);

    procedure HouseAddBuildingMaterials(aHouseID: Integer);
    procedure HouseAddBuildingProgress(aHouseID: Integer);
    procedure HouseAddDamage(aHouseID: Integer; aDamage: Word);
    procedure HouseAddRepair(aHouseID: Integer; aRepair: Word);
    procedure HouseAddWaresTo(aHouseID: Integer; aType, aCount: Word);
    procedure HouseAllow(aPlayer, aHouseType: Word; aAllowed: Boolean);
    procedure HouseAllowAllyToView(aHouseID: Integer; aAllow: Boolean);
    procedure HouseAllowAllyToViewAll(aPlayer: Byte; aAllow: Boolean);
    function  HouseBarracksEquip(aHouseID: Integer; aUnitType: Integer; aCount: Integer): Integer;
    procedure HouseBarracksGiveRecruit(aHouseID: Integer);
    procedure HouseDestroy(aHouseID: Integer; aSilent: Boolean);
    procedure HouseDeliveryBlock(aHouseID: Integer; aDeliveryBlocked: Boolean);
    procedure HouseDeliveryMode(aHouseID: Integer; aDeliveryMode: Byte);
    procedure HouseDisableUnoccupiedMessage(aHouseID: Integer; aDisabled: Boolean);
    procedure HouseRepairEnable(aHouseID: Integer; aRepairEnabled: Boolean);
    function  HouseSchoolQueueAdd(aHouseID: Integer; aUnitType: Integer; aCount: Integer): Integer;
    procedure HouseSchoolQueueRemove(aHouseID, QueueIndex: Integer);
    procedure HouseTakeWaresFrom(aHouseID: Integer; aType, aCount: Word);
    function  HouseTownHallEquip(aHouseID: Integer; aUnitType: Integer; aCount: Integer): Integer;
    procedure HouseTownHallMaxGold(aHouseID: Integer; aMaxGold: Integer);
    procedure HouseUnlock(aPlayer, aHouseType: Word);
    procedure HouseWoodcutterChopOnly(aHouseID: Integer; aChopOnly: Boolean);
    procedure HouseWoodcutterMode(aHouseID: Integer; aWoodcutterMode: Byte);
    procedure HouseWareBlock(aHouseID, aWareType: Integer; aBlocked: Boolean);
    procedure HouseWeaponsOrderSet(aHouseID, aWareType, aAmount: Integer);

    procedure Log(const aText: AnsiString);

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

    procedure OverlayTextSet(aPlayer: Shortint; const aText: AnsiString);
    procedure OverlayTextSetFormatted(aPlayer: Shortint; const aText: AnsiString; Params: array of const);
    procedure OverlayTextAppend(aPlayer: Shortint; const aText: AnsiString);
    procedure OverlayTextAppendFormatted(aPlayer: Shortint; const aText: AnsiString; Params: array of const);

    procedure Peacetime(aPeacetime: Cardinal);

    function PlanAddField(aPlayer, X, Y: Word): Boolean;
    function PlanAddHouse(aPlayer, aHouseType, X, Y: Word): Boolean;
    function PlanAddRoad(aPlayer, X, Y: Word): Boolean;
    function PlanAddWinefield(aPlayer, X, Y: Word): Boolean;
    function PlanConnectRoad(aPlayer, X1, Y1, X2, Y2: Integer; aCompleted: Boolean): Boolean;
    function PlanRemove(aPlayer, X, Y: Word): Boolean;

    procedure PlayerAllianceChange(aPlayer1, aPlayer2: Byte; aCompliment, aAllied: Boolean);
    procedure PlayerAllianceNFogChange(aPlayer1, aPlayer2: Byte; aCompliment, aAllied, aSyncAllyFog: Boolean);
    procedure PlayerAddDefaultGoals(aPlayer: Byte; aBuildings: Boolean);
    procedure PlayerDefeat(aPlayer: Word);
    procedure PlayerGoalsRemoveAll(aPlayer: Word; aForAllPlayers: Boolean);
    procedure PlayerShareBeacons(aPlayer1, aPlayer2: Word; aBothWays, aShare: Boolean);
    procedure PlayerShareFog(aPlayer1, aPlayer2: Word; aShare: Boolean);
    procedure PlayerShareFogCompliment(aPlayer1, aPlayer2: Word; aShare: Boolean);
    procedure PlayerWareDistribution(aPlayer, aWareType, aHouseType, aAmount: Byte);
    procedure PlayerWin(const aVictors: array of Integer; aTeamVictory: Boolean);

    function PlayWAV(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer;
    function PlayWAVFadeMusic(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer;
    function PlayWAVAtLocation(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single; aRadius: Single; aX, aY: Word): Integer;
    function PlayWAVLooped(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer;
    function PlayWAVAtLocationLooped(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single; aRadius: Single; aX, aY: Word): Integer;
    procedure StopLoopedWAV(aSoundIndex: Integer);

    function PlayOGG(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer;
    function PlayOGGFadeMusic(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer;
    function PlayOGGAtLocation(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single; aRadius: Single; aX, aY: Word): Integer;
    function PlayOGGLooped(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer;
    function PlayOGGAtLocationLooped(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single; aRadius: Single; aX, aY: Word): Integer;
    procedure StopLoopedOGG(aSoundIndex: Integer);

    function PlaySound(aPlayer: ShortInt; const aFileName: AnsiString; aAudioFormat: TKMAudioFormat; aVolume: Single;
                       aFadeMusic, aLooped: Boolean): Integer;
    function PlaySoundAtLocation(aPlayer: ShortInt; const aFileName: AnsiString; aAudioFormat: TKMAudioFormat; aVolume: Single;
                                 aFadeMusic, aLooped: Boolean; aRadius: Single; aX, aY: Word): Integer;
    procedure StopSound(aSoundIndex: Integer);

    procedure RemoveRoad(X, Y: Word);

    procedure SetTradeAllowed(aPlayer, aResType: Word; aAllowed: Boolean);
    procedure ShowMsg(aPlayer: Shortint; const aText: AnsiString);
    procedure ShowMsgFormatted(aPlayer: Shortint; const aText: AnsiString; Params: array of const);
    procedure ShowMsgGoto(aPlayer: Shortint; aX, aY: Word; const aText: AnsiString);
    procedure ShowMsgGotoFormatted(aPlayer: Shortint; aX, aY: Word; const aText: AnsiString; Params: array of const);

    procedure UnitBlock(aPlayer: Byte; aType: Word; aBlock: Boolean);
    function  UnitDirectionSet(aUnitID, aDirection: Integer): Boolean;
    procedure UnitDismiss(aUnitID: Integer);
    procedure UnitDismissableSet(aUnitID: Integer; aDismissable: Boolean);
    procedure UnitDismissCancel(aUnitID: Integer);
    procedure UnitHPChange(aUnitID, aHP: Integer);
    procedure UnitHPSetInvulnerable(aUnitID: Integer; aInvulnerable: Boolean);
    procedure UnitHungerSet(aUnitID, aHungerLevel: Integer);
    procedure UnitKill(aUnitID: Integer; aSilent: Boolean);
    function  UnitOrderWalk(aUnitID: Integer; X, Y: Word): Boolean;
  end;


implementation
uses
  TypInfo, KM_AI, KM_Game, KM_GameParams, KM_FogOfWar, KM_HandsCollection, KM_HandLogistics,
  KM_HouseBarracks, KM_HouseSchool, KM_ResUnits, KM_CommonUtils, KM_HouseMarket,
  KM_Resource, KM_Hand, KM_AIDefensePos, KM_CommonClasses,
  KM_PathFindingRoad, KM_ResMapElements, KM_HandConstructions,
  KM_HouseWoodcutters, KM_HouseTownHall,
  KM_UnitGroupTypes,
  KM_ResTypes;

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
procedure TKMScriptActions.CinematicStart(aPlayer: Byte);
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
    begin
      gHands[aPlayer].InCinematic := True;
      gGame.GamePlayInterface.CinematicUpdate;
    end
    else
      LogParamWarning('Actions.CinematicStart', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5938
//* Exits cinematic mode
procedure TKMScriptActions.CinematicEnd(aPlayer: Byte);
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
    begin
      gHands[aPlayer].InCinematic := False;
      gGame.GamePlayInterface.CinematicUpdate;
    end
    else
      LogParamWarning('Actions.CinematicEnd', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5938
//* Pans the center of the player's screen to the given location over a set number of ticks.
//* If Duration = 0 then the screen moves instantly.
procedure TKMScriptActions.CinematicPanTo(aPlayer: Byte; X, Y, Duration: Word);
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and gTerrain.TileInMapCoords(X, Y)
    and gHands[aPlayer].InCinematic then
    begin
      if aPlayer = gMySpectator.HandID then
        gGame.GamePlayInterface.Viewport.PanTo(KMPointF(X, Y), Duration);
    end
    else
      LogParamWarning('Actions.CinematicPanTo', [aPlayer, X, Y, Duration]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Proclaims player defeated
procedure TKMScriptActions.PlayerDefeat(aPlayer: Word);
begin
  try
    //Verify all input parameters
    if InRange(aPlayer, 0, gHands.Count - 1) and gHands[aPlayer].Enabled then
      gHands[aPlayer].AI.Defeat
    else
      LogParamWarning('Actions.PlayerDefeat', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Remove all player goals
//* aPlayer: PlayerID
//* aForAllPlayers: also remove other player goals, related to this player
procedure TKMScriptActions.PlayerGoalsRemoveAll(aPlayer: Word; aForAllPlayers: Boolean);
begin
  try
    //Verify all input parameters
    if InRange(aPlayer, 0, gHands.Count - 1) and gHands[aPlayer].Enabled then
    begin
      gHands[aPlayer].AI.Goals.Clear;
      if aForAllPlayers then
        gHands.UpdateGoalsForHand(aPlayer, False); //Goal disable works as good as delete goal
    end
    else
      LogParamWarning('Actions.PlayerGoalsRemoveAll', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Sets whether player A shares his beacons with player B.
//* Sharing can still only happen between allied players, but this command lets you disable allies from sharing.
//* aBothWays: share in both ways
procedure TKMScriptActions.PlayerShareBeacons(aPlayer1, aPlayer2: Word; aBothWays, aShare: Boolean);
begin
  try
    if  InRange(aPlayer1, 0, gHands.Count - 1)
    and InRange(aPlayer2, 0, gHands.Count - 1)
    and (gHands[aPlayer1].Enabled)
    and (gHands[aPlayer2].Enabled) then
    begin
      gHands[aPlayer1].ShareBeacons[aPlayer2] := aShare;
      if aBothWays then
        gHands[aPlayer2].ShareBeacons[aPlayer1] := aShare;
    end
    else
      LogParamWarning('Actions.PlayerShareBeacons', [aPlayer1, aPlayer2, Byte(aBothWays), Byte(aShare)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5345
//* Sets whether player A shares his vision with player B (one way, for both ways use PlayerShareFogCompliment).
//* Sharing can still only happen between allied players, but this command lets you disable allies from sharing.
procedure TKMScriptActions.PlayerShareFog(aPlayer1, aPlayer2: Word; aShare: Boolean);
begin
  try
    if  InRange(aPlayer1, 0, gHands.Count - 1)
    and InRange(aPlayer2, 0, gHands.Count - 1)
    and (gHands[aPlayer1].Enabled)
    and (gHands[aPlayer2].Enabled) then
      gHands[aPlayer1].ShareFOW[aPlayer2] := aShare
    else
      LogParamWarning('Actions.PlayerShareFog', [aPlayer1, aPlayer2, Byte(aShare)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Sets whether players A and B share their vision (both ways).
//* Sharing can still only happen between allied players, but this command lets you disable allies from sharing.
procedure TKMScriptActions.PlayerShareFogCompliment(aPlayer1, aPlayer2: Word; aShare: Boolean);
begin
  try
    if  InRange(aPlayer1, 0, gHands.Count - 1)
    and InRange(aPlayer2, 0, gHands.Count - 1)
    and (gHands[aPlayer1].Enabled)
    and (gHands[aPlayer2].Enabled) then
    begin
      gHands[aPlayer1].ShareFOW[aPlayer2] := aShare;
      gHands[aPlayer2].ShareFOW[aPlayer1] := aShare
    end
    else
      LogParamWarning('Actions.PlayerShareFogCompliment', [aPlayer1, aPlayer2, Byte(aShare)]);
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
      LogParamWarning('Actions.PlayerWin', [aVictors[I]]);
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
procedure TKMScriptActions.PlayerWareDistribution(aPlayer, aWareType, aHouseType, aAmount: Byte);
begin
  try
    if (aWareType in [Low(WARE_ID_TO_TYPE) .. High(WARE_ID_TO_TYPE)])
    and (WARE_ID_TO_TYPE[aWareType] in [wtSteel, wtCoal, wtWood, wtCorn])
    and HouseTypeValid(aHouseType)
    and InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and InRange(aAmount, 0, 5) then
    begin
      gHands[aPlayer].Stats.WareDistribution[WARE_ID_TO_TYPE[aWareType], HOUSE_ID_TO_TYPE[aHouseType]] := aAmount;
      gHands[aPlayer].Houses.UpdateResRequest;
    end
    else
      LogParamWarning('Actions.PlayerWareDistribution', [aPlayer, aWareType, aHouseType, aAmount]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5097
//* Change whether player1 is allied to player2.
//* If Compliment is true, then it is set both ways (so also whether player2 is allied to player1)
//* aCompliment: Both ways
procedure TKMScriptActions.PlayerAllianceChange(aPlayer1, aPlayer2: Byte; aCompliment, aAllied: Boolean);
const
  ALLIED: array [Boolean] of TKMAllianceType = (atEnemy, atAlly);
begin
  try
    //Verify all input parameters
    if InRange(aPlayer1, 0, gHands.Count - 1)
      and InRange(aPlayer2, 0, gHands.Count - 1)
      and (aPlayer1 <> aPlayer2)
      and (gHands[aPlayer1].Enabled)
      and (gHands[aPlayer2].Enabled) then
    begin
      gHands[aPlayer1].Alliances[aPlayer2] := ALLIED[aAllied];
      if aAllied then
        gHands[aPlayer2].FogOfWar.SyncFOW(gHands[aPlayer1].FogOfWar);
      if aCompliment then
      begin
        gHands[aPlayer2].Alliances[aPlayer1] := ALLIED[aAllied];
        if aAllied then
          gHands[aPlayer1].FogOfWar.SyncFOW(gHands[aPlayer2].FogOfWar);
      end;
    end
    else
      LogParamWarning('Actions.PlayerAllianceChange', [aPlayer1, aPlayer2, Byte(aCompliment), Byte(aAllied)]);
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
procedure TKMScriptActions.PlayerAllianceNFogChange(aPlayer1, aPlayer2: Byte; aCompliment, aAllied, aSyncAllyFog: Boolean);
const
  ALLIED: array [Boolean] of TKMAllianceType = (atEnemy, atAlly);
begin
  try
    //Verify all input parameters
    if InRange(aPlayer1, 0, gHands.Count - 1)
      and InRange(aPlayer2, 0, gHands.Count - 1)
      and (aPlayer1 <> aPlayer2)
      and (gHands[aPlayer1].Enabled)
      and (gHands[aPlayer2].Enabled) then
    begin
      gHands[aPlayer1].Alliances[aPlayer2] := ALLIED[aAllied];
      if aAllied and aSyncAllyFog then
        gHands[aPlayer2].FogOfWar.SyncFOW(gHands[aPlayer1].FogOfWar);
      if aCompliment then
      begin
        gHands[aPlayer2].Alliances[aPlayer1] := ALLIED[aAllied];
        if aAllied and aSyncAllyFog then
          gHands[aPlayer1].FogOfWar.SyncFOW(gHands[aPlayer2].FogOfWar);
      end;
    end
    else
      LogParamWarning('Actions.PlayerAllianceNFogChange', [aPlayer1, aPlayer2, Byte(aCompliment), Byte(aAllied), Byte(aSyncAllyFog)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5165
//* Add default goals/lost goals for the specified player.
//* If the parameter buildings is true the goals will be important buildings.
//* Otherwise it will be troops.
procedure TKMScriptActions.PlayerAddDefaultGoals(aPlayer: Byte; aBuildings: Boolean);
begin
  try
    //Verify all input parameters
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
    begin

      gHands[aPlayer].AI.AddDefaultGoals(aBuildings);
    end
    else
      LogParamWarning('Actions.PlayerAddDefaultGoals', [aPlayer, Byte(aBuildings)]);
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
function TKMScriptActions.PlayWAV(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer;
begin
  Result := -1;
  try
    if InRange(aVolume, 0, 1) then
      Result := gScriptSounds.AddSound(aPlayer, aFileName, afWav, KMPOINT_ZERO, False, aVolume, 0, False, False)
    else
      LogParamWarning('Actions.PlayWAV: ' + UnicodeString(aFileName), []);
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
function TKMScriptActions.PlayWAVFadeMusic(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer;
begin
  Result := -1;
  try
    if InRange(aVolume, 0, 1) then
      Result := gScriptSounds.AddSound(aPlayer, aFileName, afWav, KMPOINT_ZERO, False, aVolume, 0, True, False)
    else
      LogParamWarning('Actions.PlayWAVFadeMusic: ' + UnicodeString(aFileName), []);
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
function TKMScriptActions.PlayWAVAtLocation(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single; aRadius: Single; aX, aY: Word): Integer;
begin
  Result := -1;
  try
    if InRange(aVolume, 0, 4) and (aRadius >= MIN_SOUND_AT_LOC_RADIUS) and gTerrain.TileInMapCoords(aX,aY) then
      Result := gScriptSounds.AddSound(aPlayer, aFileName, afWav, KMPoint(aX,aY), True, aVolume, aRadius, False, False)
    else
      LogParamWarning('Actions.PlayWAVAtLocation: ' + UnicodeString(aFileName), [aX, aY]);
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
function TKMScriptActions.PlayWAVLooped(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer;
begin
  try
    Result := -1;
    if InRange(aVolume, 0, 1) then
      Result := gScriptSounds.AddSound(aPlayer, aFileName, afWav, KMPOINT_ZERO, False, aVolume, 0, False, True)
    else
      LogParamWarning('Actions.PlayWAVLooped: ' + UnicodeString(aFileName), []);
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
function TKMScriptActions.PlayWAVAtLocationLooped(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single; aRadius: Single; aX, aY: Word): Integer;
begin
  try
    Result := -1;
    if InRange(aVolume, 0, 4) and (aRadius >= MIN_SOUND_AT_LOC_RADIUS) and gTerrain.TileInMapCoords(aX,aY) then
      Result := gScriptSounds.AddSound(aPlayer, aFileName, afWav, KMPoint(aX,aY), True, aVolume, aRadius, False, True)
    else
      LogParamWarning('Actions.PlayWAVAtLocationLooped: ' + UnicodeString(aFileName), [aX, aY]);
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
      LogParamWarning('Actions.StopLoopedWAV', [aSoundIndex]);
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
function TKMScriptActions.PlayOGG(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer;
begin
  Result := -1;
  try
    if InRange(aVolume, 0, 1) then
      Result := gScriptSounds.AddSound(aPlayer, aFileName, afOgg, KMPOINT_ZERO, False, aVolume, 0, False, False)
    else
      LogParamWarning('Actions.PlayOGG: ' + UnicodeString(aFileName), []);
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
function TKMScriptActions.PlayOGGFadeMusic(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer;
begin
  Result := -1;
  try
    if InRange(aVolume, 0, 1) then
      Result := gScriptSounds.AddSound(aPlayer, aFileName, afOgg, KMPOINT_ZERO, False, aVolume, 0, True, False)
    else
      LogParamWarning('Actions.PlayOGGFadeMusic: ' + UnicodeString(aFileName), []);
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
function TKMScriptActions.PlayOGGAtLocation(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single; aRadius: Single; aX, aY: Word): Integer;
begin
  Result := -1;
  try
    if InRange(aVolume, 0, 4) and (aRadius >= MIN_SOUND_AT_LOC_RADIUS) and gTerrain.TileInMapCoords(aX,aY) then
      Result := gScriptSounds.AddSound(aPlayer, aFileName, afOgg, KMPoint(aX,aY), True, aVolume, aRadius, False, False)
    else
      LogParamWarning('Actions.PlayOGGAtLocation: ' + UnicodeString(aFileName), [aX, aY]);
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
function TKMScriptActions.PlayOGGLooped(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single): Integer;
begin
  try
    Result := -1;
    if InRange(aVolume, 0, 1) then
      Result := gScriptSounds.AddSound(aPlayer, aFileName, afOgg, KMPOINT_ZERO, False, aVolume, 0, False, True)
    else
      LogParamWarning('Actions.PlayOGGLooped: ' + UnicodeString(aFileName), []);
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
function TKMScriptActions.PlayOGGAtLocationLooped(aPlayer: ShortInt; const aFileName: AnsiString; aVolume: Single; aRadius: Single; aX, aY: Word): Integer;
begin
  try
    Result := -1;
    if InRange(aVolume, 0, 4) and (aRadius >= MIN_SOUND_AT_LOC_RADIUS) and gTerrain.TileInMapCoords(aX,aY) then
      Result := gScriptSounds.AddSound(aPlayer, aFileName, afOgg, KMPoint(aX,aY), True, aVolume, aRadius, False, True)
    else
      LogParamWarning('Actions.PlayOGGAtLocationLooped: ' + UnicodeString(aFileName), [aX, aY]);
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
      LogParamWarning('Actions.StopLoopedOGG', [aSoundIndex]);
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
function TKMScriptActions.PlaySound(aPlayer: ShortInt; const aFileName: AnsiString; aAudioFormat: TKMAudioFormat; aVolume: Single; aFadeMusic, aLooped: Boolean): Integer;
begin
  try
    Result := -1;
    if InRange(aVolume, 0, 1) then
      Result := gScriptSounds.AddSound(aPlayer, aFileName, aAudioFormat, KMPOINT_ZERO, False, aVolume, 0, aFadeMusic, aLooped)
    else
      LogParamWarning('Actions.PlaySound: ' + UnicodeString(aFileName), []);
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
function TKMScriptActions.PlaySoundAtLocation(aPlayer: ShortInt; const aFileName: AnsiString; aAudioFormat: TKMAudioFormat; aVolume: Single; aFadeMusic, aLooped: Boolean; aRadius: Single; aX, aY: Word): Integer;
begin
  try
    Result := -1;
    if InRange(aVolume, 0, 4) and (aRadius >= MIN_SOUND_AT_LOC_RADIUS) and gTerrain.TileInMapCoords(aX,aY) then
      Result := gScriptSounds.AddSound(aPlayer, aFileName, aAudioFormat, KMPoint(aX,aY), True, aVolume, aRadius, aFadeMusic, aLooped)
    else
      LogParamWarning('Actions.PlaySoundAtLocation: ' + UnicodeString(aFileName), [aX, aY]);
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
      LogParamWarning('Actions.StopSound', [aSoundIndex]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5927
//* Removes road
procedure TKMScriptActions.RemoveRoad(X, Y: Word);
var
  Pos: TKMPoint;
begin
  try
    Pos := KMPoint(X, Y);
    if gTerrain.TileInMapCoords(X, Y) then
    begin
      //Can't remove if tile is locked (house or roadwork)
      if (gTerrain.Land[Y, X].TileOverlay = toRoad) and (gTerrain.Land[Y, X].TileLock = tlNone) then
        gTerrain.RemRoad(Pos);
    end
    else
      LogParamWarning('Actions.RemoveRoad', [X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Give player group of warriors and return the group ID or -1 if the group was not able to be added
//* aColumns: Units per row
function TKMScriptActions.GiveGroup(aPlayer, aType, X,Y, aDir, aCount, aColumns: Word): Integer;
var
  G: TKMUnitGroup;
begin
  try
    Result := UID_NONE;
    //Verify all input parameters
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and (aType in [UNIT_TYPE_TO_ID[WARRIOR_MIN]..UNIT_TYPE_TO_ID[WARRIOR_MAX]])
    and gTerrain.TileInMapCoords(X,Y)
    and (TKMDirection(aDir+1) in [dirN..dirNW])
    and (aCount > 0)
    and (aColumns > 0) then
    begin
      G := gHands[aPlayer].AddUnitGroup(UNIT_ID_TO_TYPE[aType],
                                          KMPoint(X,Y),
                                          TKMDirection(aDir+1),
                                          aColumns,
                                          aCount);
      if G = nil then Exit;
      Result := G.UID;
    end
    else
      LogParamWarning('Actions.GiveGroup', [aPlayer, aType, X, Y, aDir, aCount, aColumns]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Give player a single citizen and returns the unit ID or -1 if the unit was not able to be added
function TKMScriptActions.GiveUnit(aPlayer, aType, X, Y, aDir: Word): Integer;
var
  U: TKMUnit;
begin
  try
    Result := UID_NONE;

    //Verify all input parameters
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and (aType in [UNIT_TYPE_TO_ID[CITIZEN_MIN] .. UNIT_TYPE_TO_ID[CITIZEN_MAX]])
    and gTerrain.TileInMapCoords(X, Y)
    and (TKMDirection(aDir + 1) in [dirN .. dirNW]) then
    begin
      U := gHands[aPlayer].AddUnit(UNIT_ID_TO_TYPE[aType], KMPoint(X,Y));
      if U = nil then Exit;
      Result := U.UID;
      U.Direction := TKMDirection(aDir + 1);
      //Make sure the unit is not locked so the script can use commands like UnitOrderWalk.
      //By default newly created units are given SetActionLockedStay
      U.SetActionStay(10, uaWalk);
    end
    else
      LogParamWarning('Actions.GiveUnit', [aPlayer, aType, X, Y, aDir]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5097
//* Give player a built house and returns the house ID or -1 if the house was not able to be added
function TKMScriptActions.GiveHouse(aPlayer, aHouseType, X,Y: Integer): Integer;
var
  H: TKMHouse;
begin
  try
    Result := UID_NONE;

    //Verify all input parameters
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and HouseTypeValid(aHouseType)
    and gTerrain.TileInMapCoords(X, Y) then
    begin
      if gTerrain.CanPlaceHouseFromScript(HOUSE_ID_TO_TYPE[aHouseType], KMPoint(X - gRes.Houses[HOUSE_ID_TO_TYPE[aHouseType]].EntranceOffsetX, Y)) then
      begin
        H := gHands[aPlayer].AddHouse(HOUSE_ID_TO_TYPE[aHouseType], X, Y, True);
        if H = nil then Exit;
        Result := H.UID;
      end;
    end
    else
      LogParamWarning('Actions.GiveHouse', [aPlayer, aHouseType, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6288
//* Give player a digged house area and returns House ID or -1 if house site was not able to be added.
//* If AddMaterials = True, wood and stone will be added
function TKMScriptActions.GiveHouseSite(aPlayer, aHouseType, X, Y: Integer; aAddMaterials: Boolean): Integer;
var
  H: TKMHouse;
  I, K: Integer;
  HA: THouseArea;
  NonEntranceX: Integer;
begin
  try
    Result := -1;
    if InRange(aPlayer, 0, gHands.Count - 1)
    and (gHands[aPlayer].Enabled)
    and HouseTypeValid(aHouseType)
    and gTerrain.TileInMapCoords(X,Y) then
    begin
      NonEntranceX := X - gRes.Houses[HOUSE_ID_TO_TYPE[aHouseType]].EntranceOffsetX;
      if gTerrain.CanPlaceHouseFromScript(HOUSE_ID_TO_TYPE[aHouseType], KMPoint(NonEntranceX, Y)) then
      begin
        H := gHands[aPlayer].AddHouseWIP(HOUSE_ID_TO_TYPE[aHouseType], KMPoint(NonEntranceX, Y));
        if (H = nil) or (H.IsDestroyed) then
          Exit;

        Result := H.UID;
        HA := gRes.Houses[H.HouseType].BuildArea;
        for I := 1 to 4 do
        for K := 1 to 4 do
          if HA[I, K] <> 0 then
          begin
            gTerrain.RemoveObject(KMPoint(NonEntranceX + K - 3, Y + I - 4));
            gTerrain.FlattenTerrain(KMPoint(NonEntranceX + K - 3, Y + I - 4));
            gTerrain.SetTileLock(KMPoint(NonEntranceX + K - 3, Y + I - 4), tlDigged);
          end;

        gTerrain.SetRoad(H.Entrance, aPlayer);
        H.BuildingState := hbsWood;
        if aAddMaterials then
        begin
          for I := 0 to gRes.Houses[H.HouseType].WoodCost - 1 do
            H.ResAddToBuild(wtWood);
          for K := 0 to gRes.Houses[H.HouseType].StoneCost - 1 do
            H.ResAddToBuild(wtStone);
        end
        else
        begin
          gHands[aPlayer].Deliveries.Queue.AddDemand(H, nil, wtWood, gRes.Houses[H.HouseType].WoodCost, dtOnce, diHigh4);
          gHands[aPlayer].Deliveries.Queue.AddDemand(H, nil, wtStone, gRes.Houses[H.HouseType].StoneCost, dtOnce, diHigh4);
        end;
        gHands[aPlayer].Constructions.HouseList.AddHouse(H);
      end;
    end
    else
      LogParamWarning('Actions.GiveHouseSite', [aPlayer, aHouseType, X, Y, byte(aAddMaterials)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Sets AI army type
//* aType = (atIronThenLeather, atLeather, atIron, atIronAndLeather)
procedure TKMScriptActions.AIArmyType(aPlayer: Byte; aType: TKMArmyType);
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1)
    and (gHands[aPlayer].Enabled)
    and (aType in [Low(TKMArmyType)..High(TKMArmyType)]) then
      gHands[aPlayer].AI.Setup.ArmyType := aType
    else
      LogParamWarning('Actions.AIArmyType', [aPlayer, Byte(aType)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Add AI attack 
//** <b>aPlayer</b> - playerID
//** <b>aRepeating</b> - is attack repeating
//** <b>aDelay</b> - attack delay
//** <b>aTotalMen</b> - total soldiers to attack
//** <b>aMelleCount</b>, <b>aAntiHorseCount</b>, <b>aRangedCount</b>, <b>aMountedCount</b> - soldiers groups count
//** <b>aRandomGroups</b> - use random groups for attack
//** <b>aTarget</b> - attack target of TKMAIAttackTarget type. Possible values:
//** <pre>TKMAIAttackTarget = (
//**  attClosestUnit, //Closest enemy unit
//**  attClosestBuildingFromArmy,
//**    //Closest building from the group lauching the attack
//**  attClosestBuildingFromStartPos,
//**    //Closest building from the AI's start position
//**  attCustomPosition
//**    //Custom point defined with aCustomPosition
//** );</pre>
//** <b>aCustomPosition</b> - TKMPoint for custom position of attack. Used if attCustomPosition was set up as attack target
//** <b>Result</b>: Attack Id, that could be used to remove this attack later on
function TKMScriptActions.AIAttackAdd(aPlayer: Byte; aRepeating: Boolean; aDelay: Cardinal; aTotalMen: Integer; aMelleCount, aAntiHorseCount, aRangedCount, aMountedCount: Word; aRandomGroups: Boolean; aTarget: TKMAIAttackTarget; aCustomPosition: TKMPoint): Integer;
var
  AttackType: TKMAIAttackType;
  Delay: Cardinal;
begin
  Result := -1;
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
    begin
      if aRepeating then
        AttackType := aatRepeating
      else
        AttackType := aatOnce;

      //Attack delay should be counted from the moment attack was added from script
      Delay := aDelay + gGameParams.Tick;
      Result := gHands[aPlayer].AI.General.Attacks.AddAttack(AttackType, Delay, aTotalMen, aMelleCount, aAntiHorseCount, aRangedCount, aMountedCount, aRandomGroups, aTarget, 0, aCustomPosition);
    end else
      LogParamWarning('Actions.AIAttackAdd', [aPlayer, aDelay, aTotalMen, aMelleCount, aAntiHorseCount, aRangedCount, aMountedCount]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Remove AI attack by attack ID
//* Result: true, if attack was succesfully removed, false, if attack was not found
function TKMScriptActions.AIAttackRemove(aPlayer: Byte; aAIAttackId: Word): Boolean;
begin
  Result := False;
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      Result := gHands[aPlayer].AI.General.Attacks.RemoveAttack(aAIAttackId)
    else
      LogParamWarning('Actions.AIAttackRemove', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Remove all AI attacks
procedure TKMScriptActions.AIAttackRemoveAll(aPlayer: Byte);
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      gHands[aPlayer].AI.General.Attacks.Clear
    else
      LogParamWarning('Actions.AIAttackRemoveAll', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6251
//* Sets AI auto attack range.
//* AI groups will automatically attack if you are closer than this many tiles.
//* aRange: Range (1 to 20)
procedure TKMScriptActions.AIAutoAttackRange(aPlayer: Byte; aRange: Word);
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
      and InRange(aRange, 1, 20)
      and not gHands[aPlayer].AI.Setup.NewAI then // Do not allow AutoAttackRange if we are using newAI
      gHands[aPlayer].AI.Setup.AutoAttackRange := aRange
    else
      LogParamWarning('Actions.AIAutoAttackRange', [aPlayer, aRange]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5924
//* Sets whether the AI should build and manage his own village
procedure TKMScriptActions.AIAutoBuild(aPlayer: Byte; aAuto: Boolean);
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      gHands[aPlayer].AI.Setup.AutoBuild := aAuto
    else
      LogParamWarning('Actions.AIAutoBuild', [aPlayer, Byte(aAuto)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5924
//* Sets whether the AI should position his soldiers automatically
procedure TKMScriptActions.AIAutoDefence(aPlayer: Byte; aAuto: Boolean);
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      gHands[aPlayer].AI.Setup.AutoDefend := aAuto
    else
      LogParamWarning('Actions.AIAutoDefence', [aPlayer, Byte(aAuto)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5932
//* Sets whether the AI should automatically repair damaged buildings
procedure TKMScriptActions.AIAutoRepair(aPlayer: Byte; aAuto: Boolean);
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
       gHands[aPlayer].AI.Setup.AutoRepair := aAuto
     else
       LogParamWarning('Actions.AIAutoRepair', [aPlayer, Byte(aAuto)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5932
//* Adds a defence position for the specified AI player
procedure TKMScriptActions.AIDefencePositionAdd(aPlayer: Byte; X, Y: Integer; aDir, aGroupType: Byte; aRadius: Word; aDefType: Byte);
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and (TAIDefencePosType(aDefType) in [adtFrontLine..adtBackLine])
    and (TKMGroupType(aGroupType) in [gtMelee..gtMounted])
    and (TKMDirection(aDir+1) in [dirN..dirNW])
    and (gTerrain.TileInMapCoords(X, Y)) then
      gHands[aPlayer].AI.General.DefencePositions.Add(KMPointDir(X, Y, TKMDirection(aDir + 1)), TKMGroupType(aGroupType), aRadius, TAIDefencePosType(aDefType))
  else
    LogParamWarning('Actions.AIDefencePositionAdd', [aPlayer, X, Y, aDir, aGroupType, aRadius, aDefType]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6309
//* Removes defence position at X, Y
procedure TKMScriptActions.AIDefencePositionRemove(aPlayer: Byte; X, Y: Integer);
var
  I: Integer;
  DP: TAIDefencePosition;
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1)
    and (gHands[aPlayer].Enabled)
    and gTerrain.TileInMapCoords(X, Y) then
      for I := gHands[aPlayer].AI.General.DefencePositions.Count - 1 downto 0 do
      begin
        DP := gHands[aPlayer].AI.General.DefencePositions.Positions[I];
        if DP <> nil then
          if (DP.Position.Loc.X = X)
          and (DP.Position.Loc.Y = Y) then
            gHands[aPlayer].AI.General.DefencePositions.Delete(I);
      end
  else
    LogParamWarning('Actions.AIDefencePositionRemove', [aPlayer, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6323
//* Removes all defence positions for specified AI player
procedure TKMScriptActions.AIDefencePositionRemoveAll(aPlayer: Byte);
var
  I: Integer;
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1)
    and (gHands[aPlayer].Enabled) then
      for I := gHands[aPlayer].AI.General.DefencePositions.Count - 1 downto 0 do
        gHands[aPlayer].AI.General.DefencePositions.Delete(I)
    else
      LogParamWarning('Actions.AIDefencePositionRemoveAll', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6251
//* Sets whether AI should defend units and houses of allies as if they were its own
procedure TKMScriptActions.AIDefendAllies(aPlayer: Byte; aDefend: Boolean);
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      gHands[aPlayer].AI.Setup.DefendAllies := aDefend
    else
      LogParamWarning('Actions.AIDefendAllies', [aPlayer, Byte(aDefend)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5778
//* Sets the warriors equip rate for AI.
//* aType: type: 0 - leather, 1 - iron
procedure TKMScriptActions.AIEquipRate(aPlayer: Byte; aType: Byte; aRate: Word);
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      case aType of
        0:    gHands[aPlayer].AI.Setup.EquipRateLeather := aRate;
        1:    gHands[aPlayer].AI.Setup.EquipRateIron := aRate;
        else  LogParamWarning('Actions.AIEquipRate, unknown type', [aPlayer, aType, aRate]);
      end
    else
      LogParamWarning('Actions.AIEquipRate', [aPlayer, aType, aRate]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5778
//* Sets the formation the AI uses for defence positions
procedure TKMScriptActions.AIGroupsFormationSet(aPlayer, aType: Byte; aCount, aColumns: Word);
var
  gt: TKMGroupType;
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and InRange(aType, 0, 3)
    and (aCount > 0) and (aColumns > 0) then
    begin
      gt := TKMGroupType(aType);
      gHands[aPlayer].AI.General.DefencePositions.TroopFormations[gt].NumUnits := aCount;
      gHands[aPlayer].AI.General.DefencePositions.TroopFormations[gt].UnitsPerRow := aColumns;
    end
    else
      LogParamWarning('Actions.AIGroupsFormationSet', [aPlayer, aType, aCount, aColumns]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5924
//* Sets the number of ticks before the specified AI will start training recruits
procedure TKMScriptActions.AIRecruitDelay(aPlayer: Byte; aDelay: Cardinal);
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      gHands[aPlayer].AI.Setup.RecruitDelay := aDelay
    else
      LogParamWarning('Actions.AIRecruitDelay', [aPlayer, aDelay]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5345
//* Sets the number of recruits the AI will keep in each barracks
procedure TKMScriptActions.AIRecruitLimit(aPlayer, aLimit: Byte);
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      gHands[aPlayer].AI.Setup.RecruitCount := aLimit
    else
      LogParamWarning('Actions.AIRecruitLimit', [aPlayer, aLimit]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5924
//* Sets the number of serfs the AI will train per house.
//* Can be a decimal (0.25 for 1 serf per 4 houses)
procedure TKMScriptActions.AISerfsPerHouse(aPlayer: Byte; aSerfs: Single);
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      gHands[aPlayer].AI.Setup.SerfsPerHouse := aSerfs
    else
      LogParamWarning('Actions.AISerfsPerHouse', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5932
//* Sets the maximum number of soldiers the AI will train, or -1 for unlimited
procedure TKMScriptActions.AISoldiersLimit(aPlayer: Byte; aLimit: Integer);
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and (aLimit >= -1) then                       //-1 means unlimited; else MaxSoldiers = aLimit
      gHands[aPlayer].AI.Setup.MaxSoldiers := aLimit
    else
      LogParamWarning('Actions.AISoldiersLimit', [aPlayer, aLimit]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6251
//* Sets the AI start position which is used for targeting AI attacks
procedure TKMScriptActions.AIStartPosition(aPlayer: Byte; X, Y: Word);
begin
  try
    if (InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled))
    and (gTerrain.TileInMapCoords(X, Y)) then
      gHands[aPlayer].AI.Setup.StartPosition := KMPoint(X, Y)
    else
      LogParamWarning('Actions.AIStartPosition', [aPlayer, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5924
//* Sets the maximum number of laborers the AI will train
procedure TKMScriptActions.AIWorkerLimit(aPlayer, aLimit: Byte);
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      gHands[aPlayer].AI.Setup.WorkerCount := aLimit
    else
      LogParamWarning('Actions.AIWorkerLimit', [aPlayer, aLimit]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Adds an animal to the game and returns the unit ID or -1 if the animal was not able to be added
function TKMScriptActions.GiveAnimal(aType, X, Y: Word): Integer;
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
      LogParamWarning('Actions.GiveAnimal', [aType, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6311
//* Adds finished field and returns true if field was successfully added
function TKMScriptActions.GiveField(aPlayer, X, Y: Word): Boolean;
begin
  try
    Result := False;
    if InRange(aPlayer, 0, gHands.Count - 1)
      and (gHands[aPlayer].Enabled)
      and gTerrain.TileInMapCoords(X, Y) then
    begin
      if gHands[aPlayer].CanAddFieldPlan(KMPoint(X, Y), ftCorn) then
      begin
        Result := True;
        gTerrain.SetField(KMPoint(X, Y), aPlayer, ftCorn, 0, False, True);
      end
      else
        LogWarning('Actions.GiveField', Format('Cannot give field for player %d at [%d:%d]', [aPlayer,X,Y]));
    end else
      LogParamWarning('Actions.GiveField', [aPlayer, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Sets field age if tile is corn field, or adds finished field and sets its age if tile is empty, and returns true if this was successfully done
//* aStage: 0..6, sets the field growth stage. 0 = empty field; 6 = corn has been cut
//* aRandomAge sets FieldAge to random, according to specified stage. Makes fields more realistic
function TKMScriptActions.GiveFieldAged(aPlayer, X, Y: Word; aStage: Byte; aRandomAge: Boolean): Boolean;
begin
  try
    Result := False;
    if InRange(aPlayer, 0, gHands.Count - 1)
      and (gHands[aPlayer].Enabled)
      and (InRange(aStage, 0, CORN_STAGES_COUNT - 1))
      and gTerrain.TileInMapCoords(X, Y) then
    begin
      if gHands[aPlayer].CanAddFieldPlan(KMPoint(X, Y), ftCorn)
        or (gTerrain.TileIsCornField(KMPoint(X, Y))) then
      begin
        Result := True;
        gTerrain.SetField(KMPoint(X, Y), aPlayer, ftCorn, aStage, aRandomAge);
      end
      else
        LogWarning('Actions.GiveFieldAged', Format('Cannot give field for player %d at [%d:%d]', [aPlayer,X,Y]));
    end else
      LogParamWarning('Actions.GiveFieldAged', [aPlayer, X, Y, aStage, Byte(aRandomAge)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6311
//* Adds finished road and returns true if road was successfully added
function TKMScriptActions.GiveRoad(aPlayer, X, Y: Word): Boolean;
begin
  try
    Result := False;
    if InRange(aPlayer, 0, gHands.Count - 1)
    and (gHands[aPlayer].Enabled)
    and gTerrain.TileInMapCoords(X, Y) then
      if gHands[aPlayer].CanAddFieldPlan(KMPoint(X, Y), ftRoad) then
      begin
        Result := True;
        gTerrain.SetRoad(KMPoint(X, Y), aPlayer);
        //Terrain under roads is flattened (fields are not)
        gTerrain.FlattenTerrain(KMPoint(X, Y));
        if gMapElements[gTerrain.Land[Y,X].Obj].WineOrCorn then
          gTerrain.RemoveObject(KMPoint(X,Y)); //Remove corn/wine like normally built road does
      end
    else
      LogParamWarning('Actions.GiveRoad', [aPlayer, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Adds amount of wares to players 1st Store
//Wares are added to first Store
procedure TKMScriptActions.GiveWares(aPlayer, aType, aCount: Word);
var
  H: TKMHouse;
begin
  try
    //Verify all input parameters
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and InRange(aCount, 0, High(Word))
    and (aType in [Low(WARE_ID_TO_TYPE) .. High(WARE_ID_TO_TYPE)]) then
    begin
      H := gHands[aPlayer].FindHouse(htStore, 1);
      if H <> nil then
      begin
        H.ResAddToIn(WARE_ID_TO_TYPE[aType], aCount);
        gHands[aPlayer].Stats.WareProduced(WARE_ID_TO_TYPE[aType], aCount);
        gScriptEvents.ProcWareProduced(H, WARE_ID_TO_TYPE[aType], aCount);
      end;
    end
    else
      LogParamWarning('Actions.GiveWares', [aPlayer, aType, aCount]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;

//* Version: 5165
//* Adds amount of weapons to players 1st Barracks
//Weapons are added to first Barracks
procedure TKMScriptActions.GiveWeapons(aPlayer, aType, aCount: Word);
var
  H: TKMHouse;
begin
  try
    //Verify all input parameters
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and InRange(aCount, 0, High(Word))
    and (aType in [Low(WARE_ID_TO_TYPE) .. High(WARE_ID_TO_TYPE)])
    and (WARE_ID_TO_TYPE[aType] in [WARFARE_MIN .. WARFARE_MAX]) then
    begin
      H := gHands[aPlayer].FindHouse(htBarracks, 1);
      if H <> nil then
      begin
        H.ResAddToIn(WARE_ID_TO_TYPE[aType], aCount);
        gHands[aPlayer].Stats.WareProduced(WARE_ID_TO_TYPE[aType], aCount);
        gScriptEvents.ProcWareProduced(H, WARE_ID_TO_TYPE[aType], aCount);
      end;
    end
    else
      LogParamWarning('Actions.GiveWeapons', [aPlayer, aType, aCount]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version 6311
//* Adds finished winefield and returns true if winefield was successfully added
function TKMScriptActions.GiveWineField(aPlayer, X, Y: Word): Boolean;
begin
  try
    Result := False;
    if InRange(aPlayer, 0, gHands.Count - 1)
      and (gHands[aPlayer].Enabled)
      and gTerrain.TileInMapCoords(X, Y) then
    begin
      if gHands[aPlayer].CanAddFieldPlan(KMPoint(X, Y), ftWine) then
      begin
        Result := True;
        gTerrain.SetField(KMPoint(X, Y), aPlayer, ftWine, 0, False, True);
      end
      else
        LogWarning('Actions.GiveWineField', Format('Cannot give winefield for player %d at [%d:%d]', [aPlayer,X,Y]));
    end else
      LogParamWarning('Actions.GiveWineField', [aPlayer, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version 7000+
//* Sets winefield age if tile is winefield, or adds finished winefield and sets its age if tile is empty, and returns true if this was successfully done
//* aStage = 0..3, sets the field growth stage. 0 = new fruits; 3 = grapes are ready to be harvested; according to WINE_STAGES_COUNT
//* aRandomAge sets FieldAge to random, according to specified stage. Makes fields more realistic
function TKMScriptActions.GiveWineFieldAged(aPlayer, X, Y: Word; aStage: Byte; aRandomAge: Boolean): Boolean;
begin
  try
    Result := False;
    if InRange(aPlayer, 0, gHands.Count - 1)
      and (gHands[aPlayer].Enabled)
      and (InRange(aStage, 0, WINE_STAGES_COUNT - 1))
      and gTerrain.TileInMapCoords(X, Y) then
    begin
      if gHands[aPlayer].CanAddFieldPlan(KMPoint(X, Y), ftWine)
        or (gTerrain.TileIsWineField(KMPoint(X, Y))) then
      begin
        Result := True;
        gTerrain.SetField(KMPoint(X, Y), aPlayer, ftWine, aStage, aRandomAge);
      end
      else
        LogWarning('Actions.GiveWineFieldAged', Format('Cannot give winefield for player %d at [%d:%d]', [aPlayer,X,Y]));
    end else
      LogParamWarning('Actions.GiveWineFieldAged', [aPlayer, X, Y, aStage, Byte(aRandomAge)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5097
//* Reveals a circle in fog of war for player
procedure TKMScriptActions.FogRevealCircle(aPlayer, X, Y, aRadius: Word);
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and gTerrain.TileInMapCoords(X,Y)
    and InRange(aRadius, 0, 255) then
      gHands[aPlayer].FogOfWar.RevealCircle(KMPoint(X, Y), aRadius, FOG_OF_WAR_MAX)
    else
      LogParamWarning('Actions.FogRevealCircle', [aPlayer, X, Y, aRadius]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5097
//* Reveals a circle in fog of war for player
procedure TKMScriptActions.FogCoverCircle(aPlayer, X, Y, aRadius: Word);
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and gTerrain.TileInMapCoords(X,Y)
    and InRange(aRadius, 0, 255) then
      gHands[aPlayer].FogOfWar.CoverCircle(KMPoint(X, Y), aRadius)
    else
      LogParamWarning('Actions.FogCoverCircle', [aPlayer, X, Y, aRadius]);
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
procedure TKMScriptActions.FogRevealRect(aPlayer, X1, Y1, X2, Y2: Word);
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and gTerrain.TileInMapCoords(X1,Y1)
    and gTerrain.TileInMapCoords(X2,Y2) then
      gHands[aPlayer].FogOfWar.RevealRect(KMPoint(X1, Y1), KMPoint(X2, Y2), FOG_OF_WAR_MAX)
    else
      LogParamWarning('Actions.FogRevealRect', [aPlayer, X1, Y1, X2, Y2]);
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
procedure TKMScriptActions.FogCoverRect(aPlayer, X1, Y1, X2, Y2: Word);
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and gTerrain.TileInMapCoords(X1,Y1)
    and gTerrain.TileInMapCoords(X2,Y2) then
      gHands[aPlayer].FogOfWar.CoverRect(KMPoint(X1, Y1), KMPoint(X2, Y2))
    else
      LogParamWarning('Actions.FogCoverRect', [aPlayer, X1, Y1, X2, Y2]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5097
//* Reveals the entire map in fog of war for player
procedure TKMScriptActions.FogRevealAll(aPlayer: Byte);
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      gHands[aPlayer].FogOfWar.RevealEverything
    else
      LogParamWarning('Actions.FogRevealAll', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5097
//* Covers (un-reveals) the entire map in fog of war for player
procedure TKMScriptActions.FogCoverAll(aPlayer: Byte);
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      gHands[aPlayer].FogOfWar.CoverEverything
    else
      LogParamWarning('Actions.FogCoverAll', [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Displays a message to a player.
//* If the player index is -1 the message will be shown to all players.
//Input text is ANSI with libx codes to substitute
procedure TKMScriptActions.ShowMsg(aPlayer: Shortint; const aText: AnsiString);
begin
  try
    if (aPlayer = gMySpectator.HandID) or (aPlayer = PLAYER_NONE) then
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
procedure TKMScriptActions.ShowMsgFormatted(aPlayer: Shortint; const aText: AnsiString; Params: array of const);
begin
  try
    try
      if (aPlayer = gMySpectator.HandID) or (aPlayer = PLAYER_NONE) then
        gGame.ShowMessageLocal(mkText, gGame.TextMission.ParseTextMarkup(UnicodeString(aText), Params), KMPOINT_ZERO);
    except
      //Format may throw an exception
      on E: EConvertError do LogParamWarning('Actions.ShowMsgFormatted: '+E.Message, []);
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
procedure TKMScriptActions.ShowMsgGoto(aPlayer: Shortint; aX, aY: Word; const aText: AnsiString);
begin
  try
    if gTerrain.TileInMapCoords(aX, aY) then
    begin
      if (aPlayer = gMySpectator.HandID) or (aPlayer = PLAYER_NONE) then
        gGame.ShowMessageLocal(mkText, gGame.TextMission.ParseTextMarkup(UnicodeString(aText)), KMPoint(aX,aY));
    end
    else
      LogParamWarning('Actions.ShowMsgGoto', [aPlayer, aX, aY]);
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
procedure TKMScriptActions.ShowMsgGotoFormatted(aPlayer: Shortint; aX, aY: Word; const aText: AnsiString; Params: array of const);
begin
  try
    try
      if gTerrain.TileInMapCoords(aX, aY) then
      begin
        if (aPlayer = gMySpectator.HandID) or (aPlayer = PLAYER_NONE) then
          gGame.ShowMessageLocal(mkText, gGame.TextMission.ParseTextMarkup(UnicodeString(aText), Params), KMPoint(aX,aY));
      end
      else
        LogParamWarning('Actions.ShowMsgGotoFormatted', [aPlayer, aX, aY]);
    except
      //Format may throw an exception
      on E: EConvertError do LogParamWarning('Actions.ShowMsgGotoFormatted: '+E.Message, []);
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
procedure TKMScriptActions.HouseUnlock(aPlayer, aHouseType: Word);
begin
  try
    //Verify all input parameters
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and HouseTypeValid(aHouseType) then
      gHands[aPlayer].Locks.HouseGranted[HOUSE_ID_TO_TYPE[aHouseType]] := True
    else
      LogParamWarning('Actions.HouseUnlock', [aPlayer, aHouseType]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Sets whether the player is allowed to build the specified house.
//* Note: The house must still be unlocked normally (e.g. sawmill for farm), use HouseUnlock to override that.
procedure TKMScriptActions.HouseAllow(aPlayer, aHouseType: Word; aAllowed: Boolean);
begin
  try
    //Verify all input parameters
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and HouseTypeValid(aHouseType) then
      gHands[aPlayer].Locks.HouseBlocked[HOUSE_ID_TO_TYPE[aHouseType]] := not aAllowed
    else
      LogParamWarning('Actions.HouseAllow', [aPlayer, aHouseType, Byte(aAllowed)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 10940
//* Allows allies to view specified house
procedure TKMScriptActions.HouseAllowAllyToView(aHouseID: Integer; aAllow: Boolean);
var
  H: TKMHouse;
begin
  try
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil) and not H.IsDestroyed and H.IsComplete then
      begin
        H.AllowAllyToView := aAllow;
      end;
      //Silently ignore if house doesn't exist
    end
    else
      LogParamWarning('Actions.HouseAllowAllyView', [aHouseID, Byte(aAllow)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 10940
//* Allows allies to view all houses of specified player
procedure TKMScriptActions.HouseAllowAllyToViewAll(aPlayer: Byte; aAllow: Boolean);
var
  I: Integer;
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled) then
      for I := 0 to gHands[aPlayer].Houses.Count - 1 do
        gHands[aPlayer].Houses[I].AllowAllyToView := aAllow
    else
      LogParamWarning('Actions.HouseAllowAllyToViewAll', [aPlayer, Byte(aAllow)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Sets whether the player is allowed to trade the specified resource.
procedure TKMScriptActions.SetTradeAllowed(aPlayer, aResType: Word; aAllowed: Boolean);
begin
  try
    //Verify all input parameters
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and (aResType in [Low(WARE_ID_TO_TYPE)..High(WARE_ID_TO_TYPE)]) then
      gHands[aPlayer].Locks.AllowToTrade[WARE_ID_TO_TYPE[aResType]] := aAllowed
    else
      LogParamWarning('Actions.SetTradeAllowed', [aPlayer, aResType, Byte(aAllowed)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6510
//* Add building materials to the specified WIP house area
procedure TKMScriptActions.HouseAddBuildingMaterials(aHouseID: Integer);
var
  I, StoneNeeded, WoodNeeded: Integer;
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
          StoneNeeded := gHands[H.Owner].Deliveries.Queue.TryRemoveDemand(H, wtStone,
                            gRes.Houses[H.HouseType].StoneCost - H.GetBuildStoneDelivered, plannedToRemove);
          Inc(StoneNeeded, plannedToRemove);
          WoodNeeded := gHands[H.Owner].Deliveries.Queue.TryRemoveDemand(H, wtWood,
                            gRes.Houses[H.HouseType].WoodCost - H.GetBuildWoodDelivered, plannedToRemove);
          Inc(WoodNeeded, plannedToRemove);
          for I := 0 to WoodNeeded - 1 do
            H.ResAddToBuild(wtWood);
          for I := 0 to StoneNeeded - 1 do
            H.ResAddToBuild(wtStone);
        end;
    end
    else
      LogParamWarning('Actions.HouseAddBuildingMaterials', [aHouseID]);
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
        if (not H.IsComplete)
        and (H.CheckResToBuild) then
        begin
          H.IncBuildingProgress;
          if H.IsStone
          and (gTerrain.Land[H.Position.Y, H.Position.X].TileLock <> tlHouse) then
            gTerrain.SetHouse(H.Position, H.HouseType, hsBuilt, H.Owner);
        end;
    end
    else
      LogParamWarning('Actions.HouseAddBuildingProgress', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Add damage to the specified house
procedure TKMScriptActions.HouseAddDamage(aHouseID: Integer; aDamage: Word);
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
      LogParamWarning('Actions.HouseAddDamage', [aHouseID, aDamage]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5441
//* Reduces damage to the specified house
procedure TKMScriptActions.HouseAddRepair(aHouseID: Integer; aRepair: Word);
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
      LogParamWarning('Actions.HouseAddRepair', [aHouseID, aRepair]);
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
        H.DemolishHouse(PLAYER_NONE, aSilent);
    end
    else
      LogParamWarning('Actions.HouseDestroy', [aHouseID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Add wares to the specified house
procedure TKMScriptActions.HouseAddWaresTo(aHouseID: Integer; aType, aCount: Word);
var
  H: TKMHouse;
  Res: TKMWareType;
begin
  try
    if (aHouseID > 0) and (aType in [Low(WARE_ID_TO_TYPE)..High(WARE_ID_TO_TYPE)]) then
    begin
      Res := WARE_ID_TO_TYPE[aType];
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil) and not H.IsDestroyed and H.IsComplete then
        if H.ResCanAddToIn(Res) or H.ResCanAddToOut(Res) then
        begin
          if aCount > 0 then
          begin
            H.ResAddToEitherFromScript(Res, aCount);
            gHands[H.Owner].Stats.WareProduced(Res, aCount);
            gScriptEvents.ProcWareProduced(H, Res, aCount);
          end;
        end
        else
          LogParamWarning('Actions.HouseAddWaresTo wrong ware type', [aHouseID, aType, aCount]);
      //Silently ignore if house doesn't exist
    end
    else
      LogParamWarning('Actions.HouseAddWaresTo', [aHouseID, aType, aCount]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 6015
//* Remove wares from the specified house.
//* If a serf was on the way to pick up the ware, the serf will abandon his task
procedure TKMScriptActions.HouseTakeWaresFrom(aHouseID: Integer; aType, aCount: Word);
var
  H: TKMHouse;
  Res: TKMWareType;
begin
  try
    if (aHouseID > 0) and (aType in [Low(WARE_ID_TO_TYPE)..High(WARE_ID_TO_TYPE)]) then
    begin
      Res := WARE_ID_TO_TYPE[aType];
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil) and not H.IsDestroyed and H.IsComplete then
        //Store/barracks mix input/output (add to input, take from output) so we must process them together
        if H.ResCanAddToIn(Res) or H.ResCanAddToOut(Res) then
        begin
          if aCount > 0 then
          begin
            //Range checking is done within ResTakeFromIn and ResTakeFromOut when aFromScript=True
            //Only one will succeed, we don't care which one it is
            H.ResTakeFromIn(Res, aCount, True);
            H.ResTakeFromOut(Res, aCount, True);
          end;
        end
        else
          LogParamWarning('Actions.HouseTakeWaresFrom wrong ware type', [aHouseID, aType, aCount]);
      //Silently ignore if house doesn't exist
    end
    else
      LogParamWarning('Actions.HouseTakeWaresFrom', [aHouseID, aType, aCount]);
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
      and ((aUnitType = UNIT_TYPE_TO_ID[utMilitia])
        or (aUnitType in [UNIT_TYPE_TO_ID[WARRIOR_EQUIPABLE_TH_MIN]..UNIT_TYPE_TO_ID[WARRIOR_EQUIPABLE_TH_MAX]])) then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil) and (H is TKMHouseTownHall) and not H.IsDestroyed and H.IsComplete then
        Result := TKMHouseTownHall(H).Equip(UNIT_ID_TO_TYPE[aUnitType], aCount);
    end
    else
      LogParamWarning('Actions.HouseTownHallEquip', [aHouseID, aUnitType]);
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
      LogParamWarning('Actions.HouseTownHallMaxGold', [aHouseID, aMaxGold]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Enables house repair for the specified house
procedure TKMScriptActions.HouseRepairEnable(aHouseID: Integer; aRepairEnabled: Boolean);
var H: TKMHouse;
begin
  try
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil) and not H.IsDestroyed and H.IsComplete then
        H.BuildingRepair := aRepairEnabled;
    end
    else
      LogParamWarning('Actions.HouseRepairEnable', [aHouseID, Byte(aRepairEnabled)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Sets delivery blocking for the specified house
procedure TKMScriptActions.HouseDeliveryBlock(aHouseID: Integer; aDeliveryBlocked: Boolean);
var H: TKMHouse;
begin
  try
    if aHouseID > 0 then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil)
        and not H.IsDestroyed //Allow to change delivery mode for not completed houses
        and gRes.Houses[H.HouseType].AcceptsWares then
      begin
        if aDeliveryBlocked then
          H.SetDeliveryModeInstantly(dmClosed)
        else
          H.SetDeliveryModeInstantly(dmDelivery);
      end;
    end
    else
      LogParamWarning('Actions.HouseDeliveryBlock', [aHouseID, Byte(aDeliveryBlocked)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Sets delivery mode for the specified house
//* Possible values for aDeliveryMode parameter:
//* 0 - Delivery closed
//* 1 - Delivery allowed
//* 2 - Take resource out
procedure TKMScriptActions.HouseDeliveryMode(aHouseID: Integer; aDeliveryMode: Byte);
var H: TKMHouse;
begin
  try
    if (aHouseID > 0) and (aDeliveryMode <= Byte(High(TKMDeliveryMode))) then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil)
        and not H.IsDestroyed //Allow to change delivery mode for not completed houses
        and gRes.Houses[H.HouseType].AcceptsWares then
        H.SetDeliveryModeInstantly(TKMDeliveryMode(aDeliveryMode));
    end
    else
      LogParamWarning('Actions.HouseDeliveryState', [aHouseID, aDeliveryMode]);
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
      LogParamWarning('Actions.HouseDisableUnoccupiedMessage', [aHouseID, Byte(aDisabled)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5099
//* Sets whether a woodcutter's hut is on chop-only mode
procedure TKMScriptActions.HouseWoodcutterChopOnly(aHouseID: Integer; aChopOnly: Boolean);
const
  CHOP_ONLY: array [Boolean] of TKMWoodcutterMode = (wcmChopAndPlant, wcmChop);
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
      LogParamWarning('Actions.HouseWoodcutterChopOnly', [aHouseID, Byte(aChopOnly)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Sets woodcutter's hut woodcutter mode
//* Possible values for aWoodcutterMode parameter are:
//* 0 - Chop And Plant
//* 1 - Chop only
//* 2 - Plant only
procedure TKMScriptActions.HouseWoodcutterMode(aHouseID: Integer; aWoodcutterMode: Byte);
var
  H: TKMHouse;
begin
  try
    if (aHouseID > 0) and (aWoodcutterMode <= Byte(High(TKMWoodcutterMode))) then
    begin
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil)
        and (H is TKMHouseWoodcutters)
        and not H.IsDestroyed
        and H.IsComplete then
        TKMHouseWoodcutters(H).WoodcutterMode := TKMWoodcutterMode(aWoodcutterMode);
    end
    else
      LogParamWarning('Actions.HouseWoodcutterMode', [aHouseID, Byte(aWoodcutterMode)]);
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
  Res: TKMWareType;
begin
  try
    if (aHouseID > 0)
    and (aWareType in [Low(WARE_ID_TO_TYPE) .. High(WARE_ID_TO_TYPE)]) then
    begin
      Res := WARE_ID_TO_TYPE[aWareType];
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil)
        and (H is TKMHouseStore)
        and not H.IsDestroyed then
        TKMHouseStore(H).NotAcceptFlag[Res] := aBlocked;

      if (H <> nil)
        and (H is TKMHouseBarracks)
        and not H.IsDestroyed
        and (Res in [WARFARE_MIN..WARFARE_MAX]) then
        TKMHouseBarracks(H).NotAcceptFlag[Res] := aBlocked;
    end
    else
      LogParamWarning('Actions.HouseWareBlock', [aHouseID, aWareType, Byte(aBlocked)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5165
//* Sets the amount of the specified weapon ordered to be produced in the specified house
procedure TKMScriptActions.HouseWeaponsOrderSet(aHouseID, aWareType, aAmount: Integer);
var
  H: TKMHouse;
  Res: TKMWareType;
  I: Integer;
begin
  try
    if (aHouseID > 0) and InRange(aAmount, 0, MAX_WARES_ORDER)
    and (aWareType in [Low(WARE_ID_TO_TYPE) .. High(WARE_ID_TO_TYPE)]) then
    begin
      Res := WARE_ID_TO_TYPE[aWareType];
      H := fIDCache.GetHouse(aHouseID);
      if (H <> nil)
        and not H.IsDestroyed
        and H.IsComplete then
        for I := 1 to 4 do
          if gRes.Houses[H.HouseType].ResOutput[I] = Res then
          begin
            H.ResOrder[I] := aAmount;
            Exit;
          end;
    end
    else
      LogParamWarning('Actions.HouseWeaponsOrderSet', [aHouseID, aWareType, aAmount]);
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
      LogParamWarning('Actions.HouseSchoolQueueRemove', [aHouseID, QueueIndex]);
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
      LogParamWarning('Actions.HouseSchoolQueueAdd', [aHouseID, aUnitType]);
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
      LogParamWarning('Actions.HouseBarracksEquip', [aHouseID, aUnitType]);
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
      LogParamWarning('Actions.HouseBarracksGiveRecruit', [aHouseID]);
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


//private utility function
procedure TKMScriptActions.LogStr(const aText: String);
begin
  Log(AnsiString(aText));
end;


//* Version: 11000
//* Apply brush from MapEd to the map
//* X,Y: coodinates
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
      LogParamWarning('Actions.MapBrush', [X, Y, Byte(aSquare), aSize, Byte(aTerKind),
                                                Byte(aRandomTiles), Byte(aOverrideCustomTiles)]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Apply Elevation change brush from MapEd to the map
//* X,Y: coodinates
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
      LogParamWarning('Actions.MapBrushElevation', [X, Y, Byte(aSquare), aSize, aSlope, aSpeed]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Apply Equalize brush from MapEd to the map
//* X,Y: coodinates
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
      LogParamWarning('Actions.MapBrushEqualize', [X, Y, Byte(aSquare), aSize, aSlope, aSpeed]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Apply Flatten brush from MapEd to the map
//* X,Y: coodinates
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
      LogParamWarning('Actions.MapBrushFlatten', [X, Y, Byte(aSquare), aSize, aSlope, aSpeed]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Apply magic water brush from MapEd to the map
//* X,Y: coodinates
procedure TKMScriptActions.MapBrushMagicWater(X, Y: Integer);
begin
  try
    if gTerrain.TileInMapCoords(X, Y) then
    begin
      gGame.TerrainPainter.MagicWater(KMPoint(X, Y));
    end
    else
    begin
      LogParamWarning('Actions.MapBrushMagicWater', [X, Y]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Apply brush with mask specified from MapEd to the map
//* X,Y: coodinates
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
      LogParamWarning('Actions.MapBrushWithMask', [X, Y, Byte(aSquare), aSize, Byte(aTerKind), Byte(aRandomTiles),
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
      LogParamWarning('Actions.MapTileSet', [X, Y, aType, aRotation]);
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
//* <pre>TKMTerrainTileBrief = record
//*   X, Y: Byte;     // Tile map coordinates
//*   Terrain: Byte;  // Terrain tile type (0..255)
//*   Rotation: Byte; // Tile rotation (0..3)
//*   Height: Byte;   // Heigth (0..100)
//*   Obj: Byte;      // Object (0..255)
//*   ChangeSet: TKMTileChangeTypeSet; // Set of changes.
//* end;
//* TKMTileChangeTypeSet = set of TKMTileChangeType
//* TKMTileChangeType =
//*   (tctTerrain, tctRotation, tctHeight, tctObject)</pre>
//* ChangeSet determines what should be changed on tile
//* F.e. if we want to change terrain type and height, then ChangeSet should contain tctTerrain and tctHeight
//* Note: aTiles elements should start from 0, as for dynamic array. So f.e. to change map tile 1,1 we should set aTiles[0][0].
//* Note: Errors are shown as map tiles (f.e. for error while applying aTiles[0][0] tile there will be a message with for map tile 1,1)
//*
//* aTiles: Check detailed info on this type in description
//* aRevertOnFail: do we need to revert all changes on any error while applying changes. If True, then no changes will be applied on error. If False - we will continue apply changes where possible
//* aShowDetailedErrors: show detailed errors after. Can slow down the execution, because of logging. If aRevertOnFail is set to True, then only first error will be shown
//* Returns true, if there was no errors on any tile. False if there was at least 1 error.
function TKMScriptActions.MapTilesArraySet(aTiles: array of TKMTerrainTileBrief; aRevertOnFail, aShowDetailedErrors: Boolean): Boolean;
  function GetTileErrorsStr(aErrorsIn: TKMTileChangeTypeSet): string;
  var TileChangeType: TKMTileChangeType;
  begin
    Result := '';
    for TileChangeType := Low(TKMTileChangeType) to High(TKMTileChangeType) do
      if TileChangeType in aErrorsIn then
      begin
        if Result <> '' then
          Result := Result + ', ';
        Result := Result + GetEnumName(TypeInfo(TKMTileChangeType), Integer(TileChangeType));
      end;
  end;

var I: Integer;
    Errors: TKMTerrainTileChangeErrorArray;
begin
  try
    Result := True;
    SetLength(Errors, 16);
    if not gTerrain.ScriptTrySetTilesArray(aTiles, aRevertOnFail, Errors) then
    begin
      Result := False;

      // Log errors
      if Length(Errors) > 0 then
      begin
        if not aShowDetailedErrors then
          Log(AnsiString(Format('Actions.MapTilesArraySet: there were %d errors while setting tiles' , [Length(Errors)])))
        else
          Log('Actions.MapTilesArraySet list of tiles errors:');
      end;
      if aShowDetailedErrors then
        for I := Low(Errors) to High(Errors) do
          Log(AnsiString(Format('Tile: %d,%d errors while applying [%s]', [Errors[I].X, Errors[I].Y, GetTileErrorsStr(Errors[I].ErrorsIn)])));
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
  var TileChangeType: TKMTileChangeType;
  begin
    Result := '';
    for TileChangeType := Low(TKMTileChangeType) to High(TKMTileChangeType) do
      if TileChangeType in aErrorsIn then
      begin
        if Result <> '' then
          Result := Result + ', ';
        Result := Result + GetEnumName(TypeInfo(TKMTileChangeType), Integer(TileChangeType));
      end;
  end;

var I: Integer;
    Errors: TKMTerrainTileChangeErrorArray;
    aTiles: array of TKMTerrainTileBrief;
    aArrElem: TAnsiStringArray;
    aParsedValue: Integer;
    aParserError: Boolean;
begin
{$WARN SUSPICIOUS_TYPECAST OFF}
  try
    Result := True;
    SetLength(Errors, 16);

    //***********PARSING ARRAY OF STRING TO ARRAY OF TKMTerrainTileBrief**********
    SetLength(aTiles, Length(aTilesS));
    for I := Low(aTilesS) to High(aTilesS) do
    begin
      aArrElem := StrSplitA(ReplaceStr(String(aTilesS[I]), ' ', ''), ',');
      aParserError := false;

      //checking params count, if count is invalid we cannot proceed
      if (Length(aArrElem) <> 6) then
        LogStr(Format('Actions.MapTilesArraySetS: Invalid number of parameters in string [%s]', [aTilesS[I]]))
      else
      begin
        //checking X, if X <= 0 we cannot proceed
        if ((TryStrToInt(string(PChar(aArrElem[0])), aParsedValue)) and (aParsedValue > 0)) then
          aTiles[I].X := aParsedValue
        else
        begin
          LogStr(Format('Actions.MapTilesArraySetS: Parameter X = [%s] in line [%s] is not a valid integer.', [aArrElem[0], aTilesS[I]]));
          aParserError := true;
        end;
        //checking Y, if Y <= 0 we cannot proceed
        if ((TryStrToInt(string(PChar(aArrElem[1])), aParsedValue)) and (aParsedValue > 0)) then
          aTiles[I].Y := aParsedValue
        else
        begin
          LogStr(Format('Actions.MapTilesArraySetS: Parameter Y = [%s] in line [%s] is not a valid integer.', [aArrElem[1], aTilesS[I]]));
          aParserError := true;
        end;

        //if X and Y are correctly defined we can proceed with terrain changes
        if (not aParserError) then
        begin
          if (TryStrToInt(string(PChar(aArrElem[2])), aParsedValue)) then
          begin
            if (aParsedValue >= 0) then
            begin
              //if value is not skipped we proceed with terrain
              aTiles[I].Terrain := aParsedValue;
              aTiles[I].UpdateTerrain := True;
            end;
          end
          else
            LogStr(Format('Actions.MapTilesArraySetS: Parameter Terrain = [%s] in line [%s] is not a valid integer.', [aArrElem[2], aTilesS[I]]));

          if (TryStrToInt(string(PChar(aArrElem[3])), aParsedValue)) then
          begin
            if (aParsedValue >= 0) then
            begin
              //if value is not skipped we proceed with rotation
              aTiles[I].Rotation := aParsedValue;
              aTiles[I].UpdateRotation := True;
            end;
          end
          else
            LogStr(Format('Actions.MapTilesArraySetS: Parameter Rotation = [%s] in line [%s] is not a valid integer.', [aArrElem[3], aTilesS[I]]));

          if (TryStrToInt(string(PChar(aArrElem[4])), aParsedValue)) then
          begin
            if (aParsedValue >= 0) then
            begin
              //if value is not skipped we proceed with height
              aTiles[I].Height := aParsedValue;
              aTiles[I].UpdateHeight := True;
            end;
          end
          else
            LogStr(Format('Actions.MapTilesArraySetS: Parameter Height = [%s] in line [%s] is not a valid integer.', [aArrElem[4], aTilesS[I]]));

          if (TryStrToInt(string(PChar(aArrElem[5])), aParsedValue)) then
          begin
            if (aParsedValue >= 0) then
            begin
              //if value is not skipped we proceed with obj
              aTiles[I].Obj := aParsedValue;
              aTiles[I].UpdateObject := True;
            end;
          end
          else
            LogStr(Format('Actions.MapTilesArraySetS: Parameter Obj = [%s] in line [%s] is not a valid integer.', [aArrElem[5], aTilesS[I]]));
        end;
      end;
    end;
    //***********END OF PARSING**********

    if not gTerrain.ScriptTrySetTilesArray(aTiles, aRevertOnFail, Errors) then
    begin
      Result := False;

      // Log errors
      if Length(Errors) > 0 then
      begin
        if not aShowDetailedErrors then
          Log(AnsiString(Format('Actions.MapTilesArraySetS: there were %d errors while setting tiles' , [Length(Errors)])))
        else
          Log('Actions.MapTilesArraySetS list of tiles errors:');
      end;
      if aShowDetailedErrors then
        for I := Low(Errors) to High(Errors) do
          Log(AnsiString(Format('Tile: %d,%d errors while applying [%s]', [Errors[I].X, Errors[I].Y, GetTileErrorsStr(Errors[I].ErrorsIn)])));
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
    if gTerrain.VerticeInMapCoords(X, Y) and InRange(Height, 0, 100) then
      Result := gTerrain.ScriptTrySetTileHeight(X, Y, Height)
    else
    begin
      LogParamWarning('Actions.MapTileHeightSet', [X, Y, Height]);
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
      LogParamWarning('Actions.MapTileObjectSet', [X, Y, Obj]);
      Result := False;
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Sets the terrain overlay on the tile at the specified XY coordinates.
//* aOverwrite = False means safe way to change tile overlay, disallowing to set it on top of old fields/roads
//* aOverwrite = True allows to destroy roads and re-dig fields (like in game we can build road on top of field and when laborer dies there is a digged overlay left)
function TKMScriptActions.MapTileOverlaySet(X, Y: Integer; aOverlay: TKMTileOverlay; aOverwrite: Boolean): Boolean;
begin
  try
    Result := True;
    if gTerrain.TileInMapCoords(X, Y)
      and (aOverlay in [Low(TKMTileOverlay)..High(TKMTileOverlay)]) then
      gTerrain.SetOverlay(KMPoint(X, Y), aOverlay, aOverwrite)
    else
    begin
      LogParamWarning('Actions.MapTileOverlaySet', [X, Y, Byte(aOverlay), Byte(aOverwrite)]);
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
  ResFrom, ResTo: TKMWareType;
begin
  try
    if (aMarketID > 0)
    and (aFrom in [Low(WARE_ID_TO_TYPE)..High(WARE_ID_TO_TYPE)])
    and (aTo in [Low(WARE_ID_TO_TYPE)..High(WARE_ID_TO_TYPE)]) then
    begin
      H := fIDCache.GetHouse(aMarketID);
      ResFrom := WARE_ID_TO_TYPE[aFrom];
      ResTo := WARE_ID_TO_TYPE[aTo];
      if (H is TKMHouseMarket)
        and not H.IsDestroyed
        and H.IsComplete
        and TKMHouseMarket(H).AllowedToTrade(ResFrom)
        and TKMHouseMarket(H).AllowedToTrade(ResTo) then
      begin
        if (TKMHouseMarket(H).ResFrom <> ResFrom) or (TKMHouseMarket(H).ResTo <> ResTo) then
        begin
          TKMHouseMarket(H).ResOrder[0] := 0; //First we must cancel the current trade
          TKMHouseMarket(H).ResFrom := ResFrom;
          TKMHouseMarket(H).ResTo := ResTo;
        end;
        TKMHouseMarket(H).ResOrder[0] := aAmount; //Set the new trade
      end;
    end
    else
      LogParamWarning('Actions.MarketSetTrade', [aMarketID, aFrom, aTo, aAmount]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5333
//* Sets text overlaid on top left of screen.
//* If the player index is -1 it will be set for all players.
procedure TKMScriptActions.OverlayTextSet(aPlayer: Shortint; const aText: AnsiString);
begin
  try
    //Text from script should be only ANSI Latin, but UI is Unicode, so we switch it
    if InRange(aPlayer, -1, gHands.Count - 1) then //-1 means all players
      gGame.OverlaySet(gGame.TextMission.ParseTextMarkup(UnicodeString(aText)), aPlayer)
    else
      LogParamWarning('Actions.OverlayTextSet: '+UnicodeString(aText), [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5333
//* Sets text overlaid on top left of screen with formatted arguments (same as Format function).
//* If the player index is -1 it will be set for all players.
//* Params: Array of arguments
procedure TKMScriptActions.OverlayTextSetFormatted(aPlayer: Shortint; const aText: AnsiString; Params: array of const);
begin
  try
    if InRange(aPlayer, -1, gHands.Count - 1) then //-1 means all players
    begin
      try
        //Text from script should be only ANSI Latin, but UI is Unicode, so we switch it
        gGame.OverlaySet(gGame.TextMission.ParseTextMarkup(UnicodeString(aText), Params), aPlayer);
      except
        //Format may throw an exception
        on E: EConvertError do LogParamWarning('Actions.OverlayTextSetFormatted: EConvertError: '+E.Message, []);
      end;
    end
    else
      LogParamWarning('Actions.OverlayTextSetFormatted: '+UnicodeString(aText), [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5333
//* Appends to text overlaid on top left of screen.
//* If the player index is -1 it will be appended for all players.
procedure TKMScriptActions.OverlayTextAppend(aPlayer: Shortint; const aText: AnsiString);
begin
  try
    //Text from script should be only ANSI Latin, but UI is Unicode, so we switch it
    if InRange(aPlayer, -1, gHands.Count - 1) then //-1 means all players
      gGame.OverlayAppend(gGame.TextMission.ParseTextMarkup(UnicodeString(aText)), aPlayer)
    else
      LogParamWarning('Actions.OverlayTextAppend: '+UnicodeString(aText), [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5333
//* Appends to text overlaid on top left of screen with formatted arguments (same as Format function).
//* If the player index is -1 it will be appended for all players.
//* Params: Array of arguments
procedure TKMScriptActions.OverlayTextAppendFormatted(aPlayer: Shortint; const aText: AnsiString; Params: array of const);
begin
  try
    if InRange(aPlayer, -1, gHands.Count - 1) then //-1 means all players
    begin
      try
        //Text from script should be only ANSI Latin, but UI is Unicode, so we switch it
        gGame.OverlayAppend(gGame.TextMission.ParseTextMarkup(UnicodeString(aText), Params), aPlayer);
      except
        //Format may throw an exception
        on E: EConvertError do LogParamWarning('Actions.OverlayTextAppendFormatted: EConvertError: '+E.Message, []);
      end;
    end
    else
      LogParamWarning('Actions.OverlayTextAppendFormatted: '+UnicodeString(aText), [aPlayer]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Adds a road plan.
//* Returns true if the plan was successfully added or false if it failed (e.g. tile blocked)
function TKMScriptActions.PlanAddRoad(aPlayer, X, Y: Word): Boolean;
begin
  try
    Result := False;
    //Verify all input parameters
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and gTerrain.TileInMapCoords(X,Y) then
    begin
      if gHands[aPlayer].CanAddFieldPlan(KMPoint(X, Y), ftRoad) then
      begin
        Result := True;
        gHands[aPlayer].Constructions.FieldworksList.AddField(KMPoint(X, Y), ftRoad);
      end;
    end
    else
      LogParamWarning('Actions.PlanAddRoad', [aPlayer, X, Y]);
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
function TKMScriptActions.PlanAddField(aPlayer, X, Y: Word): Boolean;
begin
  try
    Result := False;
    //Verify all input parameters
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and gTerrain.TileInMapCoords(X,Y) then
    begin
      if gHands[aPlayer].CanAddFieldPlan(KMPoint(X, Y), ftCorn) then
      begin
        Result := True;
        gHands[aPlayer].Constructions.FieldworksList.AddField(KMPoint(X, Y), ftCorn);
      end;
    end
    else
      LogParamWarning('Actions.PlanAddField', [aPlayer, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Adds a wine field plan.
//* Returns true if the plan was successfully added or false if it failed (e.g. tile blocked)
function TKMScriptActions.PlanAddWinefield(aPlayer, X, Y: Word): Boolean;
begin
  try
    Result := False;
    //Verify all input parameters
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and gTerrain.TileInMapCoords(X,Y) then
    begin
      if gHands[aPlayer].CanAddFieldPlan(KMPoint(X, Y), ftWine) then
      begin
        Result := True;
        gHands[aPlayer].Constructions.FieldworksList.AddField(KMPoint(X, Y), ftWine);
      end;
    end
    else
      LogParamWarning('Actions.PlanAddWinefield', [aPlayer, X, Y]);
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
function TKMScriptActions.PlanConnectRoad(aPlayer, X1, Y1, X2, Y2: Integer; aCompleted: Boolean): Boolean;
var
  Points: TKMPointList;
  PlanExists: Boolean;
  I: Integer;
  Path: TPathFindingRoad;
begin
  try
    Result := False;
    if InRange(aPlayer, 0, gHands.Count - 1)
    and (gHands[aPlayer].Enabled)
    and gTerrain.TileInMapCoords(X1, Y1)
    and gTerrain.TileInMapCoords(X2, Y2) then
    begin
      Path := TPathFindingRoad.Create(aPlayer);
      Points := TKMPointList.Create;
      try
        PlanExists := Path.Route_ReturnToWalkable(KMPoint(X1, Y1), KMPoint(X2, Y2), 0, Points);
        if not PlanExists then
          Exit;
        for I := 0 to Points.Count - 1 do
          if gHands[aPlayer].CanAddFieldPlan(Points[I], ftRoad) then
            if not aCompleted then
              gHands[aPlayer].Constructions.FieldworksList.AddField(Points[I], ftRoad)
            else
            begin
              gTerrain.SetRoad(Points[I], aPlayer);
              gTerrain.FlattenTerrain(Points[I]);
              if gMapElements[gTerrain.Land[Points[I].Y,Points[I].X].Obj].WineOrCorn then
                gTerrain.RemoveObject(Points[I]); //Remove corn/wine like normally built road does
            end;
        Result := True;
      finally
        Points.Free;
        Path.Free;
      end;
    end
    else
      LogParamWarning('Actions.PlanConnectRoad', [aPlayer, X1, Y1, X2, Y2]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5345
//* Removes house, road or field plans from the specified tile for the specified player
//* Returns true if the plan was successfully removed or false if it failed (e.g. tile blocked)
function TKMScriptActions.PlanRemove(aPlayer, X, Y: Word): Boolean;
var
  HPlan: TKMHousePlan;
begin
  try
    Result := False;
    //Verify all input parameters
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and gTerrain.TileInMapCoords(X,Y) then
    begin
      if gHands[aPlayer].Constructions.HousePlanList.TryGetPlan(KMPoint(X, Y), HPlan) then
      begin
        gHands[aPlayer].Constructions.HousePlanList.RemPlan(KMPoint(X, Y));
        gHands[aPlayer].Stats.HousePlanRemoved(HPlan.HouseType);
        Result := True;
      end;
      if gHands[aPlayer].Constructions.FieldworksList.HasField(KMPoint(X, Y)) <> ftNone then
      begin
        gHands[aPlayer].Constructions.FieldworksList.RemFieldPlan(KMPoint(X, Y));
        Result := True;
      end;
    end
    else
      LogParamWarning('Actions.PlanRemove', [aPlayer, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Adds a road plan.
//* Returns true if the plan was successfully added or false if it failed (e.g. tile blocked)
function TKMScriptActions.PlanAddHouse(aPlayer, aHouseType, X, Y: Word): Boolean;
begin
  try
    Result := False;
    //Verify all input parameters
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and HouseTypeValid(aHouseType)
    and gTerrain.TileInMapCoords(X,Y) then
    begin
      if gHands[aPlayer].CanAddHousePlan(KMPoint(X, Y), HOUSE_ID_TO_TYPE[aHouseType]) then
      begin
        Result := True;
        gHands[aPlayer].AddHousePlan(HOUSE_ID_TO_TYPE[aHouseType], KMPoint(X, Y));
      end;
    end
    else
      LogParamWarning('Actions.PlanAddHouse', [aPlayer, aHouseType, X, Y]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5993
//* Sets whether the specified player can train/equip the specified unit type
procedure TKMScriptActions.UnitBlock(aPlayer: Byte; aType: Word; aBlock: Boolean);
begin
  try
    if InRange(aPlayer, 0, gHands.Count - 1) and (gHands[aPlayer].Enabled)
    and (aType in [Low(UNIT_ID_TO_TYPE) .. High(UNIT_ID_TO_TYPE)]) then
      gHands[aPlayer].Locks.SetUnitBlocked(aBlock, UNIT_ID_TO_TYPE[aType])
    else
      LogParamWarning('Actions.UnitBlock', [aPlayer, aType, Byte(aBlock)]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 7000+
//* Heals/Wounds specified unit for aHP HP
procedure TKMScriptActions.UnitHPChange(aUnitID: Integer; aHP: Integer);
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
      LogParamWarning('Actions.UnitHPChange', [aUnitID, aHP]);
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
      LogParamWarning('Actions.UnitHPSetInvulnerable', [aUnitID, Ord(aInvulnerable)]);
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
      LogParamWarning('Actions.UnitHungerSet', [aUnitID, aHungerLevel]);
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
      LogParamWarning('Actions.UnitDirectionSet', [aUnitID, aDirection]);
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
      LogParamWarning('Actions.UnitDismiss', [aUnitID]);
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
      LogParamWarning('Actions.UnitDismissableSet', [aUnitID, Byte(aDismissable)]);
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
      LogParamWarning('Actions.UnitDismissCancel', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Order the specified unit to walk somewhere.
//* Note: Only works on idle units so as not to interfere with game logic and cause crashes.
//* Returns true on success or false on failure.
function TKMScriptActions.UnitOrderWalk(aUnitID: Integer; X, Y: Word): Boolean;
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
        LogParamWarning('Actions.UnitOrderWalk is not supported for animals', [aUnitID, X, Y])
      else
        //Can only make idle or units in houses walk so we don't mess up tasks and cause crashes
        if U.IsIdle and U.Visible then
        begin
          Result := True;
          U.SetActionWalkToSpot(KMPoint(X,Y), uaWalk);
        end;
    end
    else
      LogParamWarning('Actions.UnitOrderWalk', [aUnitID, X, Y]);
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
        U.Kill(PLAYER_NONE, not aSilent, True);
    end
    else
      LogParamWarning('Actions.UnitKill', [aUnitID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 11000
//* Changes game speed
procedure TKMScriptActions.GameSpeed(aSpeed: Single);
var
  Speed: Single;
begin
  try
    if gGameParams.IsMultiplayer then
      Speed := EnsureRange(aSpeed, GAME_SPEED_NORMAL, GAME_MP_SPEED_MAX)
    else
      Speed := EnsureRange(aSpeed, GAME_SPEED_NORMAL, GAME_SP_SPEED_MAX);

    gGame.SetSpeedGIP(Speed, True);
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
      LogParamWarning('Actions.GroupBlockOrders', [aGroupID, Byte(aBlock)]);
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
      LogParamWarning('Actions.GroupDisableHungryMessage', [aGroupID, Byte(aDisable)]);
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
  G: TKMUnitGroup;
  I: Integer;
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
      LogParamWarning('Actions.GroupHungerSet', [aGroupID, aHungerLevel]);
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
          G.Members[I].Kill(PLAYER_NONE, not aSilent, True);
    end
    else
      LogParamWarning('Actions.GroupKillAll', [aGroupID]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


//* Version: 5057
//* Order the specified group to walk somewhere
procedure TKMScriptActions.GroupOrderWalk(aGroupID: Integer; X, Y, aDirection: Word);
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
      LogParamWarning('Actions.GroupOrderWalk', [aGroupID, X, Y, aDirection]);
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
      LogParamWarning('Actions.GroupOrderAttackHouse', [aGroupID, aHouseID]);
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
      if (G <> nil) and (U <> nil) and (U.Owner <> PLAYER_ANIMAL) then
        G.OrderAttackUnit(U, True);
    end
    else
      LogParamWarning('Actions.GroupOrderAttackUnit', [aGroupID, aUnitID]);
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
      LogParamWarning('Actions.GroupOrderFood', [aGroupID]);
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
      LogParamWarning('Actions.GroupOrderStorm', [aGroupID]);
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
      LogParamWarning('Actions.GroupOrderHalt', [aGroupID]);
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
      LogParamWarning('Actions.GroupOrderLink', [aGroupID, aDestGroupID]);
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
      LogParamWarning('Actions.GroupOrderSplit', [aGroupID]);
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
      and (G.HasMember(U)) then
      begin
        G2 := G.OrderSplitUnit(U, True);
        if G2 <> nil then
          Result := G2.UID;
      end;
    end
    else
      LogParamWarning('Actions.GroupOrderSplitSelected', [aGroupID, aUnitID]);
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
      LogParamWarning('Actions.GroupSetFormation', [aGroupID, aNumColumns]);
  except
    gScriptEvents.ExceptionOutsideScript := True; //Don't blame script for this exception
    raise;
  end;
end;


end.
