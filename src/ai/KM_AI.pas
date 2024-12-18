unit KM_AI;
{$I KaM_Remake.inc}
interface
uses
  KM_CommonClasses, KM_CommonTypes, KM_Defaults,
  KM_Houses, KM_Units, KM_UnitWarrior, KM_Points,
  KM_AISetup, KM_AIMayor, KM_AIGoals, KM_AIGeneral,
  KM_CityManagement, KM_ArmyManagement, KM_GameTypes;

type
  //Things that player does automatically
  //Player AI exists both for AI and Human players, but for AI it does significantly more
  TKMHandAI = class
  private
    fOwner: TKMHandID;

    fGeneral: TKMGeneral;
    fGoals: TKMGoals;
    fMayor: TKMayor;
    fSetup: TKMHandAISetup;

    fCityManagement: TKMCityManagement;
    fArmyManagement: TKMArmyManagement;

    fWonOrLost: TWonOrLost; //Has this player won/lost? If so, do not check goals

    fCanBeAITypes: TKMAITypeSet;

    procedure CheckGoals(aAllowResetGoals: Boolean = False);
    function GetHasWon: Boolean;
    function GetHasLost: Boolean;
    function GetIsNotWinnerNotLoser: Boolean;
    function GetGoals: TKMGoals;
    function GetSetup: TKMHandAISetup;
  public
    constructor Create(aHandIndex: TKMHandID);
    destructor Destroy; override;

    property General: TKMGeneral read fGeneral;
    property Goals: TKMGoals read GetGoals;
    property Mayor: TKMayor read fMayor;
    property Setup: TKMHandAISetup read GetSetup;

    property CityManagement: TKMCityManagement read fCityManagement;
    property ArmyManagement: TKMArmyManagement read fArmyManagement;

    property CanBeAITypes: TKMAITypeSet read fCanBeAITypes write fCanBeAITypes;

    procedure ResetWonOrLost;
    procedure Defeat(aShowDefeatMessage: Boolean = True); //Defeat the player, this is not reversible
    procedure Victory; //Set this player as victorious, this is not reversible
    procedure AddDefaultGoals(aBuildings: Boolean);
    property WonOrLost: TWonOrLost read fWonOrLost;
    property HasWon: Boolean read GetHasWon;
    property HasLost: Boolean read GetHasLost;
    procedure RecheckGoals;
    property IsNotWinnerNotLoser: Boolean read GetIsNotWinnerNotLoser;
    function GetWonOrLostString: UnicodeString; //Get string represantation of Hand WonOrLost
    procedure OwnerUpdate(aPlayer: TKMHandID);
    procedure HouseAttackNotification(aHouse: TKMHouse; aAttacker: TKMUnitWarrior);
    procedure UnitHPDecreaseNotification(aUnit: TKMUnit; aAttacker: TKMUnit; aNotifyScript: Boolean = True);
    procedure UnitAttackNotification(aUnit: TKMUnit; aAttacker: TKMUnit; aNotifyScript: Boolean = True);

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad();
    procedure UpdateState(aTick: Cardinal; aCheckGoals: Boolean);
    procedure AfterMissionInit(aCanBeAITypes: TKMAITypeSet);
    procedure PlaceFirstStorehouse(aLoc: TKMPoint); //RMG

    function ObjToString: String;
  end;


implementation
uses
  SysUtils, TypInfo, Math,
  KM_GameApp, KM_Game, KM_Hand, KM_HandsCollection, KM_HandStats, KM_UnitGroup,
  KM_ResSound, KM_ScriptingEvents, KM_Alerts,
  KM_AIFields, KM_Terrain, KM_ResMapElements, KM_DevPerfLog, KM_DevPerfLogTypes,
  KM_HandTypes,
  KM_MapTypes,
  KM_ResTypes;


{ TKMHandAI }
constructor TKMHandAI.Create(aHandIndex: TKMHandID);
begin
  inherited Create;

  fOwner := aHandIndex;
  fSetup := TKMHandAISetup.Create;
  fMayor := TKMayor.Create(fOwner, fSetup);
  fGeneral := TKMGeneral.Create(fOwner, fSetup);
  fGoals := TKMGoals.Create;
  fWonOrLost := wolNone;

  fCityManagement := TKMCityManagement.Create(fOwner, fSetup);
  fArmyManagement := TKMArmyManagement.Create(fOwner, fSetup);
end;


destructor TKMHandAI.Destroy;
begin
  fGoals.Free;
  fGeneral.Free;
  fMayor.Free;
  fSetup.Free;

  fCityManagement.Free;
  fArmyManagement.Free;

  inherited;
end;


procedure TKMHandAI.ResetWonOrLost;
begin
  fWonOrLost := wolNone;
end;


//Defeat Player (from scripting?), this is not reversible.
//Defeated player remains in place, but does no actions
procedure TKMHandAI.Defeat(aShowDefeatMessage: Boolean = True);
begin
  if fWonOrLost <> wolNone then Exit;

  fWonOrLost := wolLost;

  //Let the game know
  gGame.PlayerDefeat(fOwner, aShowDefeatMessage);

  //Script may have additional event processors
  gScriptEvents.ProcPlayerDefeated(fOwner);
end;


//Set player to victorious (from scripting), this is not reversible.
//You probably need to make sure all other players are defeated or victorious too
//otherwise it will look odd.
procedure TKMHandAI.Victory;
begin
  if fWonOrLost <> wolNone then Exit;

  fWonOrLost := wolWon;

  //Replays/spectators don't see victory screen
  if not gGame.Params.IsReplay
    and (gGame.Params.IsMultiPlayerOrSpec or (gMySpectator.HandID = fOwner)) then  //Let everyone know in MP mode
    gGame.PlayerVictory(fOwner);

  //Script may have additional event processors
  gScriptEvents.ProcPlayerVictory(fOwner);
end;


procedure TKMHandAI.AddDefaultGoals(aBuildings: Boolean);
var
  I: Integer;
  enemies: array of TKMHandID;
begin
  SetLength(enemies, 0);
  for I := 0 to gHands.Count - 1 do
    if gHands[I].Enabled and (gHands[fOwner].Alliances[I] = atEnemy) then
    begin
      SetLength(enemies, Length(enemies)+1);
      enemies[High(enemies)] := I;
    end;
  Goals.AddDefaultGoals(aBuildings, fOwner, enemies);
end;


procedure TKMHandAI.RecheckGoals;
begin
  CheckGoals(True);
end;


procedure TKMHandAI.CheckGoals(aAllowResetGoals: Boolean = False);

  function GoalConditionSatisfied(const aGoal: TKMGoal): Boolean;
  var
    stats: TKMHandStats;
  begin
    Assert((aGoal.GoalCondition = gcTime) or (aGoal.HandIndex <> HAND_NONE), 'Only gcTime can have nil Player');

    if aGoal.Disabled then
      Exit(True);

    if aGoal.HandIndex <> HAND_NONE then
      stats := gHands[aGoal.HandIndex].Stats
    else
      stats := nil;

    case aGoal.GoalCondition of
      gcBuildTutorial:     Result := True; //Deprecated
      //gcTime is disabled as we process messages in Event system now. Return True so players
      //do not have to wait for all messages to show before they are allowed to win (same in TPR)
      gcTime:              Result := True; //Deprecated
      gcBuildings:         Result := (stats.GetHouseQty(GOAL_BUILDINGS_HOUSES) > 0);
      gcTroops:            Result := (stats.GetArmyCount > 0);
      gcMilitaryAssets:    Result := (stats.GetArmyCount > 0) or
                                      (stats.GetHouseQty([htBarracks, htCoalMine, htWeaponWorkshop, htArmorWorkshop, htStables,
                                                         htIronMine, htIronSmithy ,htWeaponSmithy, htArmorSmithy, htTownHall,
                                                         htSiegeWorkshop]) > 0);
      gcSerfsAndSchools:   Result := (stats.GetHouseQty([htSchool]) > 0) or (stats.GetUnitQty(utSerf) > 0);
      gcEconomyBuildings:  Result := (stats.GetHouseQty([htStore, htSchool, htInn]) > 0);
      else                  raise Exception.Create('Unknown goal');
    end;
    if aGoal.GoalStatus = gsFalse then
      Result := not Result; //Reverse condition
  end;

var
  I: Integer;
  hasVictoryGoal: Boolean;
  victorySatisfied, survivalSatisfied: Boolean;
begin
  //If player has elected to play on past victory or defeat
  //then do not check for any further goals
  if not aAllowResetGoals and (fWonOrLost <> wolNone) then Exit;

  //Assume they will win/survive, then prove it with goals
  hasVictoryGoal := False;
  victorySatisfied := True;
  survivalSatisfied := True;

  with gHands[fOwner] do
  for I := 0 to Goals.Count - 1 do
  case Goals[I].GoalType of
    gltVictory:  begin
                    //In a sandbox or script-ruled mission there may be no victory conditions in Goals
                    //so we make sure player wins by Goals only if he has such goals
                    hasVictoryGoal := True;
                    victorySatisfied := victorySatisfied and
                                       (gHands[Goals[I].HandIndex].AI.HasLost //if player is Lost then no need to check other Goal conditions
                                        or GoalConditionSatisfied(Goals[I]));
                  end;
    gltSurvive:  survivalSatisfied := survivalSatisfied and GoalConditionSatisfied(Goals[I]);
  end;
      //Messages in goals have been replaced by SCRIPT files, so this code is disabled now,
      //but kept in case we need it for something later. (conversion process?)

      //Display message if set and not already shown and not a blank text
      {if (Goals[I].MessageToShow <> 0)
      and not Goals[I].MessageHasShown
      and (fTextLibrary[Goals[I].MessageToShow] <> '') then
      begin
        if MyPlayer = fPlayers[fHandIndex] then
          fGameG.ShowMessage(mkText, fTextLibrary[Goals[I].MessageToShow], KMPOINT_ZERO);
        Goals.SetMessageHasShown(I);
      end;}

  //You can't win and lose at the same time. In KaM defeats override victories, except
  //when there are no goals defined, in which case you win for some weird reason...
  //But given that having no goals is pretty pointless we'll make defeat override so you can't
  //win battle missions by waiting for your troops to simultainiously starve to death.

  //Now we know if player has been defeated or won
  if not survivalSatisfied then
    Defeat
  else
  if hasVictoryGoal and victorySatisfied then
    Victory
  else
  if aAllowResetGoals then
    ResetWonOrLost;
end;


function TKMHandAI.GetHasWon: Boolean;
begin
  if Self = nil then Exit(False);

  Result := fWonOrLost = wolWon;
end;


function TKMHandAI.GetGoals: TKMGoals;
begin
  if Self = nil then Exit(nil);

  Result := fGoals;
end;


function TKMHandAI.GetHasLost: Boolean;
begin
  if Self = nil then Exit(False);

  Result := fWonOrLost = wolLost;
end;


function TKMHandAI.GetIsNotWinnerNotLoser: Boolean;
begin
  if Self = nil then Exit(False);

  Result := fWonOrLost = wolNone;
end;


function TKMHandAI.GetSetup: TKMHandAISetup;
begin
  if Self = nil then Exit(nil);

  Result := fSetup;
end;


function TKMHandAI.GetWonOrLostString: UnicodeString;
begin
  Result := '';
  case fWonOrLost of
    wolNone: Result := 'Undefined';
    wolWon:  Result := 'Won';
    wolLost: Result := 'Lost';
  end;
end;


procedure TKMHandAI.OwnerUpdate(aPlayer: TKMHandID);
begin
  fOwner := aPlayer;
  fMayor.OwnerUpdate(fOwner);
  fGeneral.OwnerUpdate(fOwner);

  fCityManagement.OwnerUpdate(fOwner);
  fArmyManagement.OwnerUpdate(fOwner);
end;


// aHouse is our house that was attacked
procedure TKMHandAI.HouseAttackNotification(aHouse: TKMHouse; aAttacker: TKMUnitWarrior);
var
  I: Integer;
begin
  case gHands[fOwner].HandType of
    hndHuman:
      begin
        // Our allies might like to help us too
        for I := 0 to gHands.Count-1 do
          if gHands[I].Enabled and gHands[I].IsComputer
          and (gHands.CheckAlliance(I, fOwner) = atAlly) and gHands[I].AI.Setup.DefendAllies then
            gHands[I].AI.General.RetaliateAgainstThreat(aAttacker);

        // No fight alerts in replays/spectating, and only show alerts for ourselves
        if not gGame.Params.IsReplayOrSpectate
          and (fOwner = gMySpectator.HandID)
          and (aAttacker <> nil) then //Don't show alerts for annonymous attacks (e.g. script)
          gGame.GamePlayInterface.Alerts.AddFight(KMPointF(aHouse.Position), fOwner, anTown,
                                                  gGameApp.GlobalTickCount + ALERT_DURATION[atFight]);
      end;
    hndComputer:
      begin
        if not (WonOrLost <> wolNone) then
        begin
          if fSetup.NewAI then
          begin
            // Do nothing (too CPU demanding)
          end
          else
          begin
            fGeneral.RetaliateAgainstThreat(aAttacker);
            // Our allies might like to help us too
            for I := 0 to gHands.Count-1 do
              if gHands[I].Enabled and gHands[I].IsComputer
              and (gHands.CheckAlliance(I, fOwner) = atAlly) and gHands[I].AI.Setup.DefendAllies then
                gHands[I].AI.General.RetaliateAgainstThreat(aAttacker);
          end;
        end;
      end;
  end;

  gScriptEvents.ProcHouseDamaged(aHouse, aAttacker); //At the end since it could destroy the house
end;


procedure TKMHandAI.UnitHPDecreaseNotification(aUnit: TKMUnit; aAttacker: TKMUnit; aNotifyScript: Boolean = True);
begin
  {
  if not (WonOrLost <> wolNone) then
  begin
    if fSetup.NewAI AND (gHands[fOwner].HandType <> hndHuman) then // Make sure that it is not player
    begin
      // Do nothing (too CPU demanding)
    end;
  end;
  //}
  if aNotifyScript then
    gScriptEvents.ProcUnitWounded(aUnit, aAttacker); //At the end since it could kill the unit
end;


// aUnit is our unit that was attacked
procedure TKMHandAI.UnitAttackNotification(aUnit: TKMUnit; aAttacker: TKMUnit; aNotifyScript: Boolean = True);
const
  NOTIFY_KIND: array [Boolean] of TAttackNotification = (anCitizens, anTroops);
var
  I: Integer;
  group: TKMUnitGroup;
begin
  case gHands[fOwner].HandType of
    hndHuman:
      begin
        // If we are attacked, then our allies might like to help us too
        if aAttacker is TKMUnitWarrior then
        begin
          // Our allies might like to help us too
          for I := 0 to gHands.Count-1 do
            if gHands[I].Enabled and gHands[I].IsComputer
            and (gHands.CheckAlliance(I, fOwner) = atAlly) and gHands[I].AI.Setup.DefendAllies then
              gHands[I].AI.General.RetaliateAgainstThreat(aAttacker);
        end;

        // No fight alerts in replays, and only show alerts for ourselves
        if not gGame.Params.IsReplayOrSpectate
          and (fOwner = gMySpectator.HandID) then
          gGame.GamePlayInterface.Alerts.AddFight(aUnit.PositionF, fOwner, NOTIFY_KIND[aUnit is TKMUnitWarrior],
                                                  gGameApp.GlobalTickCount + ALERT_DURATION[atFight]);
      end;
    hndComputer:
      begin
        if not (WonOrLost <> wolNone) then
        begin
          if fSetup.NewAI then
          begin
            // Do nothing (too CPU demanding)
          end
          else
          begin
            //If we are attacked, then we should counter attack the attacker (except if he is a recruit in tower)
            if aAttacker is TKMUnitWarrior then
            begin
              fGeneral.RetaliateAgainstThreat(aAttacker); //Nearby soldiers should come to assist

              //Our allies might like to help us too
              for I := 0 to gHands.Count-1 do
                if gHands[I].Enabled and gHands[I].IsComputer
                and (gHands.CheckAlliance(I, fOwner) = atAlly) and gHands[I].AI.Setup.DefendAllies then
                  gHands[I].AI.General.RetaliateAgainstThreat(aAttacker);

              //If we are a warrior we can also attack that unit ourselves
              if aUnit is TKMUnitWarrior then
              begin
                group := gHands[fOwner].UnitGroups.GetGroupByMember(TKMUnitWarrior(aUnit));
                //It's ok for the group to be nil, the warrior could still be walking out of the barracks
                if (group <> nil) and not group.IsDead then
                  //If we are already in the process of attacking something, don't change our minds,
                  //otherwise you can make a unit walk backwards and forwards forever between two groups of archers
                  if not group.InFight then
                    //Make sure the group could possibly reach the offenders
                    if group.CanWalkTo(aAttacker.Position, group.FightMaxRange) then
                      group.OrderAttackUnit(aAttacker, True);
              end;
            end;
          end;
        end;
      end;
  end;

  if aNotifyScript then
    gScriptEvents.ProcUnitAttacked(aUnit, aAttacker); //At the end since it could kill the unit
end;


procedure TKMHandAI.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.PlaceMarker('HandAI');
  SaveStream.Write(fOwner);
  SaveStream.Write(fWonOrLost, SizeOf(fWonOrLost));
  SaveStream.Write(fCanBeAITypes, SizeOf(fCanBeAITypes));

  fSetup.Save(SaveStream);
  fGoals.Save(SaveStream);

  if aitClassic in fCanBeAITypes then
  begin
    fGeneral.Save(SaveStream);
    fMayor.Save(SaveStream);
  end;

  if aitAdvanced in fCanBeAITypes then
  begin
    fCityManagement.Save(SaveStream);
    fArmyManagement.Save(SaveStream);
  end;
end;


procedure TKMHandAI.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.CheckMarker('HandAI');
  LoadStream.Read(fOwner);
  LoadStream.Read(fWonOrLost, SizeOf(fWonOrLost));
  LoadStream.Read(fCanBeAITypes, SizeOf(fCanBeAITypes));

  fSetup.Load(LoadStream);
  fGoals.Load(LoadStream);

  if aitClassic in fCanBeAITypes then
  begin
    fGeneral.Load(LoadStream);
    fMayor.Load(LoadStream);
  end;

  if aitAdvanced in fCanBeAITypes then
  begin
    fCityManagement.Load(LoadStream);
    fArmyManagement.Load(LoadStream);
  end;
end;


procedure TKMHandAI.SyncLoad();
begin
  if aitClassic in fCanBeAITypes then
    fGeneral.SyncLoad();

  if aitAdvanced in fCanBeAITypes then
  begin
    fArmyManagement.SyncLoad();
    fCityManagement.SyncLoad();
  end;
end;


procedure TKMHandAI.AfterMissionInit(aCanBeAITypes: TKMAITypeSet);
begin
  fCanBeAITypes := aCanBeAITypes;

  // Do AI initialization only if there could be any AI of a certain type
  // We should do it at the game start, in case player will be swapped to AI player
  // Also we have to do it only at the game start for Advanced AI, because it considers teams and divide mines according to the teams
  if aitClassic in fCanBeAITypes then
    fMayor.AfterMissionInit();

  if aitAdvanced in fCanBeAITypes then
  begin
    gAIFields.Eye.OwnerUpdate(fOwner);
    fCityManagement.AfterMissionInit();
    fArmyManagement.AfterMissionInit();
  end;
end;


procedure TKMHandAI.UpdateState(aTick: Cardinal; aCheckGoals: Boolean);
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psAI);
  {$ENDIF}
  try
    if (WonOrLost <> wolNone) then
      Exit;

    //Check goals for all players to maintain multiplayer consistency
    //AI victory/defeat is used in scripts (e.g. OnPlayerDefeated in battle tutorial)
    if aCheckGoals and (((aTick + Byte(fOwner)) mod MAX_HANDS) = 0) then
      CheckGoals; //This procedure manages victory and loss

    case gHands[fOwner].HandType of
      hndHuman:     begin
                      //Humans dont need AI management
                    end;
      hndComputer:  begin
                      if fSetup.NewAI then
                      begin
                        gAIFields.Eye.OwnerUpdate(fOwner);
                        fArmyManagement.UpdateState(aTick);
                        fCityManagement.UpdateState(aTick);
                      end
                      else
                      begin
                        fMayor.UpdateState(aTick);
                        fGeneral.UpdateState(aTick);
                      end;
                    end;
    end;
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psAI);
    {$ENDIF}
  end;
end;


function TKMHandAI.ObjToString: String;
begin
  Result := 'WOL = ' + GetEnumName(TypeInfo(TWonOrLost), Integer(fWonOrLost));
end;


// RMG
procedure TKMHandAI.PlaceFirstStorehouse(aLoc: TKMPoint);

  // Get closest resource to location
  function GetClosestResource(var aRes: TKMPoint; aList: TKMPointList): Boolean;
  const
    SQR_MAX_DISTANCE = 20*20;
  var
    K: Integer;
    distance, bestDistance: Single;
  begin
    aRes := KMPOINT_ZERO; // Set default point to zero so there is not integer overflow during evaluation if resource does not exist
    bestDistance := 1e10;
    for K := 0 to aList.Count - 1 do
    begin
      distance := KMDistanceSqr(aLoc, aList[K]);
      if (distance < bestDistance) then
      begin
        bestDistance := distance;
        aRes := aList[K];
      end;
    end;
    Result := bestDistance < SQR_MAX_DISTANCE;
  end;

  // Place road and return True if it is possible
  function AddRoad(aPoint: TKMPoint): Boolean;
  begin
    Result := gHands[fOwner].CanAddFieldPlan(KMPoint(aPoint.X, aPoint.Y), ftRoad);
    if Result then
    begin
      gTerrain.SetRoad(aPoint, fOwner);
      //Terrain under roads is flattened (fields are not)
      gTerrain.FlattenTerrain(aPoint);
      if gMapElements[gTerrain.Land^[aPoint.Y,aPoint.X].Obj].WineOrCorn then
        gTerrain.RemoveObject(aPoint);
    end;
  end;

  // Find place for store
  procedure FindPlaceForStore(bStone, bGold, bIron: Boolean; aInitP, Stone, Gold, Iron: TKMPoint);
  const
    RAD = 15;
  var
    X, Y: Integer;
    price, bestPrice: Single;
    loc, bestLoc: TKMPoint;
  begin
    bestPrice := 1e10;
    for X := Max(1,aInitP.X-RAD) to Min(gTerrain.MapX-1,aInitP.X+RAD) do
    for Y := Max(1,aInitP.Y-RAD) to Min(gTerrain.MapY-1,aInitP.Y+RAD) do
      if gHands[fOwner].CanAddFieldPlan(KMPoint(X,Y+1), ftRoad) AND gHands[fOwner].CanAddHousePlanAI(X,Y,htStore,False) then
      begin
        //gTerrain.ScriptTrySetTileObject(X, Y, 0); // Debug (visualization)
        loc := KMPoint(X,Y);
        price :=
          + 6 * Byte(bStone) * KMDistanceSqr(loc, Stone)
          + 50 * (Byte(gTerrain.TileIsCoal(X, Y) > 1) + Byte(gTerrain.TileIsCoal(X, Y-1) > 1) + Byte(gTerrain.TileIsCoal(X, Y-2) > 1))
          + 2 * Byte(bGold) * KMDistanceSqr(loc, Gold)
          + 1 * Byte(bIron) * KMDistanceSqr(loc, Iron)
          - 20 * ( Byte(gHands[fOwner].CanAddFieldPlan(KMPoint(X,Y+2), ftRoad)) + Byte(gHands[fOwner].CanAddFieldPlan(KMPoint(X+1,Y+1), ftRoad)) + Byte(gHands[fOwner].CanAddFieldPlan(KMPoint(X-1,Y+1), ftRoad)) );

        if (price < bestPrice) then
        begin
          bestPrice := price;
          bestLoc := loc;
        end;
      end;
    // Place storehouse
    if (bestPrice < 1E10) then
      gHands[fOwner].AddFirstStorehouse(bestLoc);
  end;

const
  MAX_DIST_FROM_STONES = 10;
var
  bGold, bIron, bStone: Boolean;
  gold, iron, stone, initPoint: TKMPoint;
begin
  // Find the closest resource
  bGold := GetClosestResource(gold, gAIFields.Eye.GoldLocs);
  bIron := GetClosestResource(iron, gAIFields.Eye.IronLocs);
  bStone := GetClosestResource(stone, gAIFields.Eye.StoneMiningTiles);
  // Apply logic
  if bStone then
  begin
    if bGold then
      initPoint := KMPoint( Round((stone.X*4+gold.X*2+aLoc.X)/7), Round((stone.Y*4+gold.Y*2+aLoc.Y)/7) )
    else if bIron then
      initPoint := KMPoint( Round((stone.X*4+iron.X+aLoc.X)/6), Round((stone.Y*4+iron.Y+aLoc.Y)/6) )
    else
      initPoint := stone;
  end
  else
  begin
    if bGold then
      initPoint := gold
    else if bIron then
      initPoint := iron
    else
      Exit;
  end;
  // Find place for store
  FindPlaceForStore(bStone, bGold, bIron, initPoint, stone, gold, iron);
end;


end.

