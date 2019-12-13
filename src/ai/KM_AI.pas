unit KM_AI;
{$I KaM_Remake.inc}
interface
uses
  KM_CommonClasses, KM_CommonTypes, KM_CommonUtils, KM_Defaults,
  KM_Houses, KM_Units, KM_UnitWarrior,
  KM_AISetup, KM_AIMayor, KM_AIGoals, KM_AIGeneral,
  KM_CityManagement, KM_ArmyManagement;

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

    procedure CheckGoals;
    function GetHasWon: Boolean;
    function GetHasLost: Boolean;
    function GetIsNotWinnerNotLoser: Boolean;
  public
    constructor Create(aHandIndex: TKMHandID);
    destructor Destroy; override;

    property General: TKMGeneral read fGeneral;
    property Goals: TKMGoals read fGoals;
    property Mayor: TKMayor read fMayor;
    property Setup: TKMHandAISetup read fSetup;

    property CityManagement: TKMCityManagement read fCityManagement;
    property ArmyManagement: TKMArmyManagement read fArmyManagement;

    procedure ResetWonOrLost;
    procedure Defeat(aShowDefeatMessage: Boolean = True); //Defeat the player, this is not reversible
    procedure Victory; //Set this player as victorious, this is not reversible
    procedure AddDefaultGoals(aBuildings: Boolean);
    property WonOrLost: TWonOrLost read fWonOrLost;
    property HasWon: Boolean read GetHasWon;
    property HasLost: Boolean read GetHasLost;
    property IsNotWinnerNotLoser: Boolean read GetIsNotWinnerNotLoser;
    function GetWonOrLostString: UnicodeString; //Get string represantation of Hand WonOrLost
    procedure OwnerUpdate(aPlayer: TKMHandID);
    procedure HouseAttackNotification(aHouse: TKMHouse; aAttacker: TKMUnitWarrior);
    procedure UnitHPDecreaseNotification(aUnit: TKMUnit; aAttacker: TKMUnit; aNotifyScript: Boolean = True);
    procedure UnitAttackNotification(aUnit: TKMUnit; aAttacker: TKMUnit; aNotifyScript: Boolean = True);

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad();
    procedure UpdateState(aTick: Cardinal);
    procedure AfterMissionInit();

    function ObjToString: String;
  end;


implementation
uses
  SysUtils, TypInfo,
  KM_GameTypes, KM_GameApp, KM_Game, KM_Hand, KM_HandsCollection, KM_HandStats, KM_UnitGroup,
  KM_ResHouses, KM_ResSound, KM_ScriptingEvents, KM_Alerts, KM_Points,
  KM_AIFields;


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
  if fWonOrLost = wolNone then
  begin
    fWonOrLost := wolLost;

    //Let the game know
    gGame.PlayerDefeat(fOwner, aShowDefeatMessage);

    //Script may have additional event processors
    gScriptEvents.ProcPlayerDefeated(fOwner);
  end;
end;


//Set player to victorious (from scripting), this is not reversible.
//You probably need to make sure all other players are defeated or victorious too
//otherwise it will look odd.
procedure TKMHandAI.Victory;
begin
  if fWonOrLost = wolNone then
  begin
    fWonOrLost := wolWon;

    //Replays/spectators don't see victory screen
    if not (gGame.GameMode in [gmReplaySingle, gmReplayMulti])
    and (gGame.IsMultiPlayerOrSpec or (gMySpectator.HandID = fOwner)) then  //Let everyone know in MP mode
      gGame.PlayerVictory(fOwner);

    //Script may have additional event processors
    gScriptEvents.ProcPlayerVictory(fOwner);
  end;
end;


procedure TKMHandAI.AddDefaultGoals(aBuildings: Boolean);
var
  I: Integer;
  Enemies: array of TKMHandID;
begin
  SetLength(Enemies, 0);
  for I := 0 to gHands.Count - 1 do
    if gHands[I].Enabled and (gHands[fOwner].Alliances[I] = atEnemy) then
    begin
      SetLength(Enemies, Length(Enemies)+1);
      Enemies[High(Enemies)] := I;
    end;
  Goals.AddDefaultGoals(aBuildings, fOwner, Enemies);
end;


procedure TKMHandAI.CheckGoals;

  function GoalConditionSatisfied(const aGoal: TKMGoal): Boolean;
  var
    Stat: TKMHandStats;
  begin
    Assert((aGoal.GoalCondition = gcTime) or (aGoal.HandIndex <> PLAYER_NONE), 'Only gcTime can have nil Player');

    if aGoal.Disabled then
    begin
      Result := True;
      Exit;
    end;

    if aGoal.HandIndex <> PLAYER_NONE then
      Stat := gHands[aGoal.HandIndex].Stats
    else
      Stat := nil;

    case aGoal.GoalCondition of
      gcBuildTutorial:     Result := True; //Deprecated
      //gcTime is disabled as we process messages in Event system now. Return true so players
      //do not have to wait for all messages to show before they are allowed to win (same in TPR)
      gcTime:              Result := True; //Deprecated
      gcBuildings:         Result := (Stat.GetHouseQty([htStore, htSchool, htBarracks, htTownHall]) > 0);
      gcTroops:            Result := (Stat.GetArmyCount > 0);
      gcMilitaryAssets:    Result := (Stat.GetArmyCount > 0) or
                                      (Stat.GetHouseQty([htBarracks, htCoalMine, htWeaponWorkshop, htArmorWorkshop, htStables,
                                                         htIronMine, htIronSmithy ,htWeaponSmithy, htArmorSmithy, htTownHall,
                                                         htSiegeWorkshop]) > 0);
      gcSerfsAndSchools:   Result := (Stat.GetHouseQty([htSchool]) > 0) or (Stat.GetUnitQty(utSerf) > 0);
      gcEconomyBuildings:  Result := (Stat.GetHouseQty([htStore, htSchool, htInn]) > 0);
      else                  raise Exception.Create('Unknown goal');
    end;
    if aGoal.GoalStatus = gsFalse then
      Result := not Result; //Reverse condition
  end;

var
  I: Integer;
  HasVictoryGoal: Boolean;
  VictorySatisfied, SurvivalSatisfied: Boolean;
begin
  //If player has elected to play on past victory or defeat
  //then do not check for any further goals
  if fWonOrLost <> wolNone then Exit;

  //Assume they will win/survive, then prove it with goals
  HasVictoryGoal := False;
  VictorySatisfied := True;
  SurvivalSatisfied := True;

  with gHands[fOwner] do
  for I := 0 to Goals.Count - 1 do
  case Goals[I].GoalType of
    gltVictory:  begin
                    //In a sandbox or script-ruled mission there may be no victory conditions in Goals
                    //so we make sure player wins by Goals only if he has such goals
                    HasVictoryGoal := True;
                    VictorySatisfied := VictorySatisfied and GoalConditionSatisfied(Goals[I]);
                  end;
    gltSurvive:  SurvivalSatisfied := SurvivalSatisfied and GoalConditionSatisfied(Goals[I]);
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
  if not SurvivalSatisfied then
    Defeat
  else
    if HasVictoryGoal and VictorySatisfied then
      Victory;
end;


function TKMHandAI.GetHasWon: Boolean;
begin
  Result := fWonOrLost = wolWon;
end;


function TKMHandAI.GetHasLost: Boolean;
begin
  Result := fWonOrLost = wolLost;
end;


function TKMHandAI.GetIsNotWinnerNotLoser: Boolean;
begin
  Result := fWonOrLost = wolNone;
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
        //No fight alerts in replays/spectating, and only show alerts for ourselves
        if not (gGame.GameMode in [gmMultiSpectate, gmReplaySingle, gmReplayMulti])
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
            fArmyManagement.CheckNewThreat(aHouse, aAttacker);
          end
          else
          begin
            fGeneral.RetaliateAgainstThreat(aAttacker);
            //Our allies might like to help us too
            for I := 0 to gHands.Count-1 do
              if gHands[I].Enabled and (gHands[I].HandType = hndComputer)
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
  if not (WonOrLost <> wolNone) then
  begin
    if fSetup.NewAI AND (gHands[fOwner].HandType <> hndHuman) then // Make sure that it is not player
    begin
      fArmyManagement.CheckNewThreat(aUnit, aAttacker);
    end;
  end;
  if aNotifyScript then
    gScriptEvents.ProcUnitWounded(aUnit, aAttacker); //At the end since it could kill the unit
end;


// aUnit is our unit that was attacked
procedure TKMHandAI.UnitAttackNotification(aUnit: TKMUnit; aAttacker: TKMUnit; aNotifyScript: Boolean = True);
const
  NotifyKind: array [Boolean] of TAttackNotification = (anCitizens, anTroops);
var
  Group: TKMUnitGroup;
  I: Integer;
begin
  case gHands[fOwner].HandType of
    hndHuman:
      //No fight alerts in replays, and only show alerts for ourselves
      if not (gGame.GameMode in [gmMultiSpectate, gmReplaySingle, gmReplayMulti])
      and (fOwner = gMySpectator.HandID) then
        gGame.GamePlayInterface.Alerts.AddFight(aUnit.PositionF, fOwner, NotifyKind[aUnit is TKMUnitWarrior],
                                                gGameApp.GlobalTickCount + ALERT_DURATION[atFight]);
    hndComputer:
      begin
        if not (WonOrLost <> wolNone) then
        begin
          if fSetup.NewAI then
          begin
            // Calls too often
            //fArmyManagement.CheckNewThreat(aUnit, aAttacker);
          end
          else
          begin
            //If we are attacked, then we should counter attack the attacker (except if he is a recruit in tower)
            if aAttacker is TKMUnitWarrior then
            begin
              fGeneral.RetaliateAgainstThreat(aAttacker); //Nearby soldiers should come to assist

              //Our allies might like to help us too
              for I := 0 to gHands.Count-1 do
                if gHands[I].Enabled and (gHands[I].HandType = hndComputer)
                and (gHands.CheckAlliance(I, fOwner) = atAlly) and gHands[I].AI.Setup.DefendAllies then
                  gHands[I].AI.General.RetaliateAgainstThreat(aAttacker);

              //If we are a warrior we can also attack that unit ourselves
              if aUnit is TKMUnitWarrior then
              begin
                Group := gHands[fOwner].UnitGroups.GetGroupByMember(TKMUnitWarrior(aUnit));
                //It's ok for the group to be nil, the warrior could still be walking out of the barracks
                if (Group <> nil) and not Group.IsDead then
                  //If we are already in the process of attacking something, don't change our minds,
                  //otherwise you can make a unit walk backwards and forwards forever between two groups of archers
                  if not Group.InFight then
                    //Make sure the group could possibly reach the offenders
                    if Group.CanWalkTo(aAttacker.CurrPosition, Group.FightMaxRange) then
                      Group.OrderAttackUnit(aAttacker, True);
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

  fSetup.Save(SaveStream);
  fGeneral.Save(SaveStream);
  fMayor.Save(SaveStream);
  fGoals.Save(SaveStream);

  fCityManagement.Save(SaveStream);
  fArmyManagement.Save(SaveStream);
end;


procedure TKMHandAI.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.CheckMarker('HandAI');
  LoadStream.Read(fOwner);
  LoadStream.Read(fWonOrLost, SizeOf(fWonOrLost));

  fSetup.Load(LoadStream);
  fGeneral.Load(LoadStream);
  fMayor.Load(LoadStream);
  fGoals.Load(LoadStream);

  fCityManagement.Load(LoadStream);
  fArmyManagement.Load(LoadStream);
end;


procedure TKMHandAI.SyncLoad();
begin
  fGeneral.SyncLoad();
  fArmyManagement.SyncLoad();
  fCityManagement.SyncLoad();
end;


procedure TKMHandAI.AfterMissionInit();
begin
  fMayor.AfterMissionInit();

  gAIFields.Eye.OwnerUpdate(fOwner);
  fCityManagement.AfterMissionInit();
  fArmyManagement.AfterMissionInit();
end;


procedure TKMHandAI.UpdateState(aTick: Cardinal);
begin
  if (WonOrLost <> wolNone) then
    Exit;
  //Check goals for all players to maintain multiplayer consistency
  //AI victory/defeat is used in scripts (e.g. OnPlayerDefeated in battle tutorial)
  if (aTick + Byte(fOwner)) mod MAX_HANDS = 0 then
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
end;


function TKMHandAI.ObjToString: String;
begin
  Result := 'WOL = ' + GetEnumName(TypeInfo(TWonOrLost), Integer(fWonOrLost));
end;


end.
