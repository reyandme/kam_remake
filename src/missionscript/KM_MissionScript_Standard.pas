unit KM_MissionScript_Standard;
{$I KaM_Remake.inc}
interface
uses
  KM_MissionScript, KM_UnitGroup, KM_Units, KM_Houses,
  KM_AIAttacks, KM_Points, KM_Defaults;


type
  TKMAttackPosition = record
    Group: TKMUnitGroup;
    Target: TKMPoint;
  end;

  TKMMissionParserStandard = class(TKMMissionParserCommon)
  private
    fParsingMode: TKMMissionParsingMode; //Data gets sent to Game differently depending on Game/Editor mode
    fPlayerEnabled: TKMHandEnabledArray;
    fLastHouse: TKMHouse;
    fLastUnit: TKMUnit;
    fLastTroop: TKMUnitGroup;
    fAIAttack: TKMAIAttack;
    fAttackPositions: array of TKMAttackPosition;
    fAttackPositionsCount: Integer;
    fDefaultLocation: ShortInt;
    procedure ProcessAttackPositions;
  protected
    function ProcessCommand(CommandType: TKMCommandType; P: array of Integer; const TextParam: AnsiString = ''): Boolean; override;
  public
    constructor Create(aMode: TKMMissionParsingMode); overload;
    constructor Create(aMode: TKMMissionParsingMode; aPlayersEnabled: TKMHandEnabledArray); overload;
    function LoadMission(const aFileName: string): Boolean; overload; override;
    procedure PostLoadMission;

    property DefaultLocation: ShortInt read fDefaultLocation;
    procedure SaveDATFile(const aFileName: string; aLeftInset: SmallInt = 0; aTopInset: SmallInt = 0; aDoXorEncoding: Boolean = False);
  end;


implementation
uses
  Classes, SysUtils, Math, KromUtils,
  KM_Hand, KM_Game, KM_HandsCollection,
  KM_UnitsCollection, KM_UnitWarrior,
  KM_HouseCollection, KM_HouseBarracks, KM_HouseTownHall, KM_HouseWoodcutters,
  KM_AI, KM_AIDefensePos,
  KM_Resource, KM_ResHouses, KM_ResUnits, KM_ResWares,
  KM_CommonClasses, KM_CommonTypes, KM_Terrain;


type
  TKMCommandParamType = (cptUnknown=0, cptRecruits, cptConstructors, cptWorkerFactor, cptRecruitCount, cptTownDefence,
                         cptMaxSoldier, cptEquipRate, cptEquipRateIron, cptEquipRateLeather, cptAutoAttackRange, cptAttackFactor, cptTroopParam);

  TAIAttackParamType = (cptType, cptTotalAmount, cptCounter, cptRange, cptTroopAmount, cptTarget, cptPosition, cptTakeAll);

const
  PARAMVALUES: array [TKMCommandParamType] of AnsiString = (
    '', 'RECRUTS', 'CONSTRUCTORS', 'WORKER_FACTOR', 'RECRUT_COUNT', 'TOWN_DEFENSE',
    'MAX_SOLDIER', 'EQUIP_RATE', 'EQUIP_RATE_IRON', 'EQUIP_RATE_LEATHER', 'AUTO_ATTACK_RANGE', 'ATTACK_FACTOR', 'TROUP_PARAM');

  AI_ATTACK_PARAMS: array [TAIAttackParamType] of AnsiString = (
    'TYPE', 'TOTAL_AMOUNT', 'COUNTER', 'RANGE', 'TROUP_AMOUNT', 'TARGET', 'POSITION', 'TAKEALL');


{ TMissionParserStandard }
//Mode affect how certain parameters are loaded a bit differently
constructor TKMMissionParserStandard.Create(aMode: TKMMissionParsingMode);
var I: Integer;
begin
  inherited Create;
  fParsingMode := aMode;
  fDefaultLocation := 0;

  for I := 0 to High(fPlayerEnabled) do
    fPlayerEnabled[I] := True;
end;


constructor TKMMissionParserStandard.Create(aMode: TKMMissionParsingMode; aPlayersEnabled: TKMHandEnabledArray);
begin
  inherited Create;
  fParsingMode := aMode;
  fDefaultLocation := 0;

  //Tells us which player should be enabled and which ignored/skipped
  fPlayerEnabled := aPlayersEnabled;
end;


function TKMMissionParserStandard.LoadMission(const aFileName: string): Boolean;
var
  FileText: AnsiString;
begin
  inherited LoadMission(aFileName);

  Assert((gTerrain <> nil) and (gHands <> nil));

  Result := False;

  //Load the terrain since we know where it is beforehand
  if FileExists(ChangeFileExt(fMissionFileName, '.map')) then
  begin
    gTerrain.LoadFromFile(ChangeFileExt(fMissionFileName, '.map'), fParsingMode = mpmEditor);
    if fParsingMode = mpmEditor then
      gGame.MapEditor.TerrainPainter.LoadFromFile(ChangeFileExt(fMissionFileName, '.map'));
  end
  else
  begin
    //Else abort loading and fail
    AddError('Map file couldn''t be found', True);
    Exit;
  end;

  //Read the mission file into FileText
  FileText := ReadMissionFile(aFileName);
  if FileText = '' then
    Exit;

  if not TokenizeScript(FileText, 6, []) then
    Exit;

  //If we have reach here without exiting then loading was successful if no errors were reported
  Result := (fFatalErrors = '');
end;


procedure TKMMissionParserStandard.PostLoadMission;
begin
  //Post-processing of ctAttack_Position commands which must be done after mission has been loaded
  ProcessAttackPositions;
  gHands.PostLoadMission;
end;


//Determine what we are attacking: House, Unit or just walking to some place
procedure TKMMissionParserStandard.ProcessAttackPositions;
var
  I: Integer;
  H: TKMHouse;
  U: TKMUnit;
begin
  Assert((fParsingMode <> mpmEditor) or (fAttackPositionsCount = 0), 'AttackPositions should be handled by MapEd');

  for I := 0 to fAttackPositionsCount - 1 do
    with fAttackPositions[I] do
    begin
      H := gHands.HousesHitTest(Target.X, Target.Y); //Attack house
      if (H <> nil) and (not H.IsDestroyed) and (gHands.CheckAlliance(Group.Owner, H.Owner) = atEnemy) then
        Group.OrderAttackHouse(H, True)
      else
      begin
        U := gTerrain.UnitsHitTest(Target.X, Target.Y); //Chase/attack unit
        if (U <> nil) and (not U.IsDeadOrDying) and (gHands.CheckAlliance(Group.Owner, U.Owner) = atEnemy) then
          Group.OrderAttackUnit(U, True)
        else
          Group.OrderWalk(Target, True, wtokMissionScript); //Just move to position
      end;
    end;
end;


function TKMMissionParserStandard.ProcessCommand(CommandType: TKMCommandType; P: array of Integer; const TextParam: AnsiString = ''): Boolean;

  function PointInMap(X, Y: Integer): Boolean;
  begin
    Result := InRange(X, 1, gTerrain.MapX)
          and InRange(Y, 1, gTerrain.MapY);
  end;

var
  I: Integer;
  Qty, HandI: Integer;
  H: TKMHouse;
  HT: TKMHouseType;
  UT: TKMUnitType;
  iPlayerAI: TKMHandAI;
begin
  Result := False; //Set it right from the start. There are several Exit points below

  case CommandType of
    ctSetMap:          begin
                          //Check for KaM format map path (disused, as Remake maps are always next to DAT script)
                          {MapFileName := RemoveQuotes(String(TextParam));
                          if FileExists(ExeDir + MapFileName) then
                          begin
                            fTerrain.LoadFromFile(ExeDir+MapFileName, fParsingMode = mpmEditor)
                            if fParsingMode = mpmEditor then
                              fTerrainPainter.LoadFromFile(ExeDir+MapFileName);
                          end}
                        end;

    ctSetMaxPlayer:    begin
                          gHands.AddPlayers(P[0]);
                          //Set players to enabled/disabled
                          for I := 0 to gHands.Count - 1 do
                          begin
                            gHands[i].Enabled := fPlayerEnabled[i];
                            if fParsingMode = mpmEditor then
                            begin
                              gGame.MapEditor.PlayerHuman[I] := False;
                              gGame.MapEditor.PlayerClassicAI[I] := False;
                              gGame.MapEditor.PlayerAdvancedAI[I] := False;
                            end;
                          end;
                        end;

    ctSetTactic:       begin
                          //Default is mmNormal
                          gGame.MissionMode := mmTactic;
                        end;

    ctSetCurrPlayer:   if InRange(P[0], 0, MAX_HANDS - 1) then
                        begin
                          if fPlayerEnabled[P[0]] then
                            fLastHand := P[0]
                          else
                            fLastHand := PLAYER_NONE; //Lets us skip this player
                          fLastHouse := nil;
                          fLastTroop := nil;
                          fLastUnit := nil;
                        end;

    ctHumanPlayer:     begin
                          //We use this command in a sense "Default human player"
                          //MP and SP set human players themselves
                          //Remains usefull for map preview and MapEd
                          //Also saved in Hand to check for advanced AI setup
                          fDefaultLocation := P[0];
                          if gHands <> nil then
                          begin
                            if fParsingMode = mpmEditor then
                            begin
                              gGame.MapEditor.DefaultHuman := P[0];
                              gGame.MapEditor.PlayerHuman[P[0]] := True;
                            end else
                              gHands[P[0]].CanBeHuman := True;
                          end;
                        end;

    ctUserPlayer:      //New command added by KMR - mark player as allowed to be human
                        //MP and SP set human players themselves
                        //Remains usefull for map preview and MapEd
                        //Also saved in Hand to check for advanced AI setup
                        if (gHands <> nil) then
                        begin
                          HandI := IfThen(InRange(P[0], 0, gHands.Count - 1), P[0], fLastHand);

                          if HandI <> -1 then
                          begin
                            if (fParsingMode = mpmEditor) then
                              gGame.MapEditor.PlayerHuman[HandI] := True
                            else
                              gHands[HandI].CanBeHuman := True;
                          end;
                        end;

    ctAIPlayer:        if (gHands <> nil) then
                        begin
                          HandI := IfThen(InRange(P[0], 0, gHands.Count - 1), P[0], fLastHand);

                          if (HandI <> -1) then
                          begin
                            if (fParsingMode = mpmEditor) then
                              gGame.MapEditor.PlayerClassicAI[HandI] := True
                            else
                              gHands[HandI].AddAIType(aitClassic);
                          end;
                        end;

    ctAdvancedAIPlayer:
                        if (gHands <> nil) then
                        begin
                          HandI := IfThen(InRange(P[0], 0, gHands.Count - 1), P[0], fLastHand);

                          if (HandI <> -1) then
                          begin
                            if (fParsingMode = mpmEditor) then
                              gGame.MapEditor.PlayerAdvancedAI[HandI] := True
                            else
                              gHands[HandI].AddAIType(aitAdvanced);
                          end;
                        end;

    ctCenterScreen:    if (fLastHand <> PLAYER_NONE)
                          and PointInMap(P[0]+1, P[1]+1) then
                          gHands[fLastHand].CenterScreen := KMPoint(P[0]+1, P[1]+1);

    ctClearUp:         if fLastHand <> PLAYER_NONE then
                        begin
                          if fParsingMode = mpmEditor then
                          begin
                            if P[0] = 255 then
                              gGame.MapEditor.RevealAll[fLastHand] := True
                            else if PointInMap(P[0]+1, P[1]+1) then
                              gGame.MapEditor.Revealers[fLastHand].Add(KMPoint(P[0]+1,P[1]+1), P[2]);
                          end else begin
                            if P[0] = 255 then
                              gHands[fLastHand].FogOfWar.RevealEverything
                            else if PointInMap(P[0]+1, P[1]+1) then
                              gHands[fLastHand].FogOfWar.RevealCircle(KMPoint(P[0]+1,P[1]+1), P[2], 255);
                          end;
                        end;

    ctSetHouse:        if fLastHand <> PLAYER_NONE then
                          if PointInMap(P[1]+1, P[2]+1) and InRange(P[0], Low(HouseIndexToType), High(HouseIndexToType)) then
                            if gTerrain.CanPlaceHouseFromScript(HouseIndexToType[P[0]], KMPoint(P[1]+1, P[2]+1)) then
                              fLastHouse := gHands[fLastHand].AddHouse(
                                HouseIndexToType[P[0]], P[1]+1, P[2]+1, false)
                            else
                              AddError('ct_SetHouse failed, can not place house at ' + TypeToString(KMPoint(P[1]+1, P[2]+1)));

    ctSetHouseDamage:  if fLastHand <> PLAYER_NONE then //Skip false-positives for skipped players
                          if fLastHouse <> nil then
                          begin
                            if not fLastHouse.IsDestroyed then //Could be destroyed already by damage
                              fLastHouse.AddDamage(Min(P[0], High(Word)), nil, fParsingMode = mpmEditor)
                          end
                          else
                            AddError('ct_SetHouseDamage without prior declaration of House');

    ctSetHouseDeliveryMode:
                        if fLastHand <> PLAYER_NONE then //Skip false-positives for skipped players
                          if fLastHouse <> nil then
                          begin
                            if InRange(P[0], Byte(Low(TKMDeliveryMode)), Byte(High(TKMDeliveryMode))) then //Check allowed range for delivery mode value
                            begin
                              if fLastHouse.AllowDeliveryModeChange then
                                fLastHouse.SetDeliveryModeInstantly(TKMDeliveryMode(P[0]))
                              else
                                AddError(Format('ct_SetHouseDeliveryMode: not allowed to change delivery mode for %s ', [gRes.Houses[fLastHouse.HouseType].HouseName]));
                            end else
                              AddError(Format('ct_SetHouseDeliveryMode: wrong value for delivery mode: [%d] ', [P[0]]));
                          end
                          else
                            AddError('ct_SetHouseDeliveryMode without prior declaration of House');

    ctSetHouseRepairMode:
                        if fLastHand <> PLAYER_NONE then //Skip false-positives for skipped players
                          if fLastHouse <> nil then
                            fLastHouse.BuildingRepair := True
                          else
                            AddError('ct_SetHouseRepairMode without prior declaration of House');

    ctSetHouseClosedForWorker:
                        if fLastHand <> PLAYER_NONE then //Skip false-positives for skipped players
                          if fLastHouse <> nil then
                            fLastHouse.IsClosedForWorker := True
                          else
                            AddError('ct_SetHouseClosedForWorker without prior declaration of House');

    ctSetUnit:         if PointInMap(P[1]+1, P[2]+1) then
                        begin
                          //Animals should be added regardless of current player
                          if UnitOldIndexToType[P[0]] in [ANIMAL_MIN..ANIMAL_MAX] then
                            gHands.PlayerAnimals.AddUnit(UnitOldIndexToType[P[0]], KMPoint(P[1]+1, P[2]+1))
                          else
                          if (fLastHand <> PLAYER_NONE) and (UnitOldIndexToType[P[0]] in [HUMANS_MIN..HUMANS_MAX]) then
                            fLastUnit := gHands[fLastHand].AddUnit(UnitOldIndexToType[P[0]], KMPoint(P[1]+1, P[2]+1));
                        end;

    ctSetUnitByStock:  if fLastHand <> PLAYER_NONE then
                          if UnitOldIndexToType[P[0]] in [HUMANS_MIN..HUMANS_MAX] then
                          begin
                            H := gHands[fLastHand].FindHouse(htStore, 1);
                            if (H <> nil) and PointInMap(H.Entrance.X, H.Entrance.Y+1) then
                              gHands[fLastHand].AddUnit(UnitOldIndexToType[P[0]], KMPoint(H.Entrance.X, H.Entrance.Y+1));
                          end;

    ctUnitAddToLast:   if fLastHand <> PLAYER_NONE then
                          if fLastHouse <> nil then
                          begin
                            if (fLastHouse is TKMHouseBarracks) and (P[0] = UnitTypeToOldIndex[utRecruit]) then
                            begin
                              if not fLastHouse.IsDestroyed then //Could be destroyed already by damage
                                TKMHouseBarracks(fLastHouse).CreateRecruitInside(fParsingMode = mpmEditor);
                            end
                            else
                              AddError('ct_UnitAddToLast only supports barracks and recruits so far');
                          end
                          else
                            AddError('ct_UnitAddToLast without prior declaration of House');

    ctSetUnitFood:      if fLastHand <> PLAYER_NONE then
                        begin
                          if fLastUnit <> nil then
                          begin
                            fLastUnit.StartWDefaultCondition := False;
                            if P[0] <> -1 then
                              fLastUnit.Condition := P[0];
                          end else
                            AddError('ct_SetUnitFood without prior declaration of Unit');
                        end;

    ctSetRoad:         if (fLastHand <> PLAYER_NONE) and PointInMap(P[0]+1, P[1]+1) then
                          gHands[fLastHand].AddRoadToList(KMPoint(P[0]+1,P[1]+1));

    ctSetField:        if (fLastHand <> PLAYER_NONE) and PointInMap(P[0]+1, P[1]+1) then
                          gHands[fLastHand].AddField(KMPoint(P[0]+1,P[1]+1),ftCorn,0,True);

    ctSetFieldStaged:  if (fLastHand <> PLAYER_NONE) and PointInMap(P[0]+1, P[1]+1) then
                          gHands[fLastHand].AddField(KMPoint(P[0]+1,P[1]+1),ftCorn,P[2]);

    ctSetWinefield:    if (fLastHand <> PLAYER_NONE) and PointInMap(P[0]+1, P[1]+1) then
                          gHands[fLastHand].AddField(KMPoint(P[0]+1,P[1]+1),ftWine,0,True);

    ctSetWinefieldStaged:  if (fLastHand <> PLAYER_NONE) and PointInMap(P[0]+1, P[1]+1) then
                              gHands[fLastHand].AddField(KMPoint(P[0]+1,P[1]+1),ftWine,P[2]);

    ctSetStock:        if (fLastHand <> PLAYER_NONE) and PointInMap(P[0]+1, P[1]+1) then
                        begin //This command basically means: Put a SH here with road bellow it
                          fLastHouse := gHands[fLastHand].AddHouse(htStore, P[0]+1,P[1]+1, False);
                          gHands[fLastHand].AddRoadToList(KMPoint(P[0]+1,P[1]+2));
                          gHands[fLastHand].AddRoadToList(KMPoint(P[0],P[1]+2));
                          gHands[fLastHand].AddRoadToList(KMPoint(P[0]-1,P[1]+2));
                        end;

    ctAddWare:         if fLastHand <> PLAYER_NONE then
                        begin
                          Qty := EnsureRange(P[1], -1, High(Word)); //Sometimes user can define it to be 999999
                          if Qty = -1 then Qty := High(Word); //-1 means maximum resources
                          H := gHands[fLastHand].FindHouse(htStore,1);
                          if (H <> nil) and H.ResCanAddToIn(WareIndexToType[P[0]]) then
                          begin
                            H.ResAddToIn(WareIndexToType[P[0]], Qty, True);
                            gHands[fLastHand].Stats.WareInitial(WareIndexToType[P[0]], Qty);
                          end;
                        end;

    ctAddWareToAll:    begin
                          Qty := EnsureRange(P[1], -1, High(Word)); //Sometimes user can define it to be 999999
                          if Qty = -1 then Qty := High(Word); //-1 means maximum resources
                          for I := 0 to gHands.Count - 1 do
                          begin
                            H := gHands[i].FindHouse(htStore, 1);
                            if (H <> nil) and H.ResCanAddToIn(WareIndexToType[P[0]]) then
                            begin
                              H.ResAddToIn(WareIndexToType[P[0]], Qty, True);
                              gHands[i].Stats.WareInitial(WareIndexToType[P[0]], Qty);
                            end;
                          end;
                        end;

    ctAddWareToSecond: if fLastHand <> PLAYER_NONE then
                        begin
                          Qty := EnsureRange(P[1], -1, High(Word)); //Sometimes user can define it to be 999999
                          if Qty = -1 then Qty := High(Word); //-1 means maximum resources

                          H := TKMHouseStore(gHands[fLastHand].FindHouse(htStore, 2));
                          if (H <> nil) and H.ResCanAddToIn(WareIndexToType[P[0]]) then
                          begin
                            H.ResAddToIn(WareIndexToType[P[0]], Qty, True);
                            gHands[fLastHand].Stats.WareInitial(WareIndexToType[P[0]], Qty);
                          end;
                        end;

    //Depreciated by ctAddWareToLast, but we keep it for backwards compatibility in loading
    ctAddWareTo:       if fLastHand <> PLAYER_NONE then
                        begin //HouseType, House Order, Ware Type, Count
                          Qty := EnsureRange(P[3], -1, High(Word)); //Sometimes user can define it to be 999999
                          if Qty = -1 then Qty := High(Word); //-1 means maximum resources

                          H := gHands[fLastHand].FindHouse(HouseIndexToType[P[0]], P[1]);
                          if (H <> nil) and (H.ResCanAddToIn(WareIndexToType[P[2]]) or H.ResCanAddToOut(WareIndexToType[P[2]])) then
                          begin
                            H.ResAddToEitherFromScript(WareIndexToType[P[2]], Qty);
                            gHands[fLastHand].Stats.WareInitial(WareIndexToType[P[2]], Qty);
                          end;
                        end;

    ctAddWareToLast:   if fLastHand <> PLAYER_NONE then
                        begin //Ware Type, Count
                          Qty := EnsureRange(P[1], -1, High(Word)); //Sometimes user can define it to be 999999
                          if Qty = -1 then Qty := High(Word); //-1 means maximum resources

                          if (fLastHouse <> nil) and (fLastHouse.ResCanAddToIn(WareIndexToType[P[0]]) or fLastHouse.ResCanAddToOut(WareIndexToType[P[0]])) then
                          begin
                            if not fLastHouse.IsDestroyed then //Could be destroyed already by damage
                            begin
                              fLastHouse.ResAddToEitherFromScript(WareIndexToType[P[0]], Qty);
                              gHands[fLastHand].Stats.WareInitial(WareIndexToType[P[0]], Qty);
                            end;
                          end
                          else
                            AddError('ct_AddWareToLast without prior declaration of House');
                        end;

    ctAddWeapon:       if fLastHand <> PLAYER_NONE then
                        begin
                          Qty := EnsureRange(P[1], -1, High(Word)); //Sometimes user can define it to be 999999
                          if Qty = -1 then Qty := High(Word); //-1 means maximum weapons
                          H := gHands[fLastHand].FindHouse(htBarracks, 1);
                          if (H <> nil) and H.ResCanAddToIn(WareIndexToType[P[0]]) then
                          begin
                            H.ResAddToIn(WareIndexToType[P[0]], Qty, True);
                            gHands[fLastHand].Stats.WareInitial(WareIndexToType[P[0]], Qty);
                          end;
                        end;

    ctBlockTrade:      if fLastHand <> PLAYER_NONE then
                        begin
                          if WareIndexToType[P[0]] in [WARE_MIN..WARE_MAX] then
                            gHands[fLastHand].Locks.AllowToTrade[WareIndexToType[P[0]]] := False;
                        end;

    ctBlockUnit:       if fLastHand <> PLAYER_NONE then
                        begin
                          UT := UnitIndexToType[P[0]];

                          if UT in [HUMANS_MIN..HUMANS_MAX] then
                          begin
                            //Militia is a special case, because it could be trained in 2 diff houses
                            if (UT = utMilitia) and (P[1] = 1) then // if P[1] = 1, then its TownHall
                              gHands[fLastHand].Locks.SetUnitBlocked(True, UT, True)
                            else
                              gHands[fLastHand].Locks.SetUnitBlocked(True, UT);
                          end;
                        end;

    ctBlockHouse:      if fLastHand <> PLAYER_NONE then
                        begin
                          if InRange(P[0], Low(HouseIndexToType), High(HouseIndexToType)) then
                            gHands[fLastHand].Locks.HouseBlocked[HouseIndexToType[P[0]]] := True;
                        end;

    ctReleaseHouse:    if fLastHand <> PLAYER_NONE then
                        begin
                          if InRange(P[0], Low(HouseIndexToType), High(HouseIndexToType)) then
                            gHands[fLastHand].Locks.HouseGranted[HouseIndexToType[P[0]]] := True;
                        end;

    ctReleaseAllHouses:if fLastHand <> PLAYER_NONE then
                          for HT := HOUSE_MIN to HOUSE_MAX do
                            gHands[fLastHand].Locks.HouseGranted[HT] := True;

    ctSetGroup:        if (fLastHand <> PLAYER_NONE) and PointInMap(P[1]+1, P[2]+1) then
                          if InRange(P[0], Low(UnitIndexToType), High(UnitIndexToType)) and (UnitIndexToType[P[0]] <> utNone) then
                          try
                            fLastTroop := gHands[fLastHand].AddUnitGroup(
                              UnitIndexToType[P[0]],
                              KMPoint(P[1]+1, P[2]+1),
                              TKMDirection(P[3]+1),
                              P[4],
                              P[5]
                              );
                          except
                            //Group could not be placed because there's already another flagholder there
                            //flagholders need to be placed on exact spots, no autoplacing is used
                            on E: ELocError do
                              AddError(ELocError(E).Message);
                          end;

    ctSendGroup:       if (fLastHand <> PLAYER_NONE) and PointInMap(P[0]+1, P[1]+1) then
                        begin
                          if fLastTroop <> nil then
                            if fParsingMode = mpmEditor then
                            begin
                              fLastTroop.MapEdOrder.Order := ioSendGroup;
                              fLastTroop.MapEdOrder.Pos := KMPointDir(P[0]+1, P[1]+1, TKMDirection(P[2]+1));
                            end
                            else
                              fLastTroop.OrderWalk(KMPoint(P[0]+1, P[1]+1), True, wtokMissionScript, TKMDirection(P[2]+1))
                          else
                            AddError('ct_SendGroup without prior declaration of Troop');
                        end;

    ctSetGroupFood:    if fLastHand <> PLAYER_NONE then
                        begin
                          if fLastTroop <> nil then
                          begin
                            fLastTroop.FlagBearer.StartWDefaultCondition := False;
                            if P[0] <> -1 then
                              fLastTroop.Condition := P[0]
                            else
                              fLastTroop.Condition := UNIT_MAX_CONDITION; //support old maps !SET_GROUP_FOOD without parameters
                          end else
                            AddError('ct_SetGroupFood without prior declaration of Troop');
                        end;

    ctAICharacter:     if fLastHand <> PLAYER_NONE then
                        begin
                          if gHands[fLastHand].HandType <> hndComputer then Exit;
                          iPlayerAI := gHands[fLastHand].AI; //Setup the AI's character
                          if TextParam = PARAMVALUES[cptRecruits]     then iPlayerAI.Setup.RecruitCount  := P[1];
                          if TextParam = PARAMVALUES[cptConstructors] then iPlayerAI.Setup.WorkerCount   := P[1];
                          if TextParam = PARAMVALUES[cptWorkerFactor] then iPlayerAI.Setup.SerfsPerHouse := (10/Max(P[1],1));
                          if TextParam = PARAMVALUES[cptRecruitCount] then iPlayerAI.Setup.RecruitDelay  := P[1];
                          if TextParam = PARAMVALUES[cptTownDefence]  then iPlayerAI.Setup.TownDefence   := P[1];
                          if TextParam = PARAMVALUES[cptAutoAttackRange] then iPlayerAI.Setup.AutoAttackRange := P[1];
                          if TextParam = PARAMVALUES[cptMaxSoldier]   then iPlayerAI.Setup.MaxSoldiers   := P[1];
                          if TextParam = PARAMVALUES[cptEquipRate]    then //Now depreciated, kept for backwards compatibility
                          begin
                            iPlayerAI.Setup.EquipRateLeather := P[1];
                            iPlayerAI.Setup.EquipRateIron    := P[1]; //Both the same for now, could be separate commands later
                          end;
                          if TextParam = PARAMVALUES[cptEquipRateLeather] then iPlayerAI.Setup.EquipRateLeather := P[1];
                          if TextParam = PARAMVALUES[cptEquipRateIron]    then iPlayerAI.Setup.EquipRateIron    := P[1];
                          if TextParam = PARAMVALUES[cptAttackFactor]     then iPlayerAI.Setup.Aggressiveness   := P[1];
                          if TextParam = PARAMVALUES[cptTroopParam]   then
                          begin
                            iPlayerAI.General.DefencePositions.TroopFormations[TKMGroupType(P[1])].NumUnits := P[2];
                            iPlayerAI.General.DefencePositions.TroopFormations[TKMGroupType(P[1])].UnitsPerRow  := P[3];
                          end;
                        end;

    ctAINoBuild:       if fLastHand <> PLAYER_NONE then
                          gHands[fLastHand].AI.Setup.AutoBuild := False;

    ctAIAutoRepair:    if fLastHand <> PLAYER_NONE then
                          gHands[fLastHand].AI.Setup.AutoRepair := True;

    ctAIAutoAttack:    if fLastHand <> PLAYER_NONE then
                          gHands[fLastHand].AI.Setup.AutoAttack := True;

    ctAIAutoDefend:    if fLastHand <> PLAYER_NONE then
                          gHands[fLastHand].AI.Setup.AutoDefend := True;

    ctAIDefendAllies:  if fLastHand <> PLAYER_NONE then
                          gHands[fLastHand].AI.Setup.DefendAllies := True;

    ctAIUnlimitedEquip:if fLastHand <> PLAYER_NONE then
                          gHands[fLastHand].AI.Setup.UnlimitedEquip := True;

    ctAIArmyType:      if (fLastHand <> PLAYER_NONE) and (P[0] >= Byte(Low(TKMArmyType))) and (P[0] <= Byte(High(TKMArmyType))) then
                          gHands[fLastHand].AI.Setup.ArmyType := TKMArmyType(P[0]);

    ctAIStartPosition: if (fLastHand <> PLAYER_NONE) and PointInMap(P[0]+1, P[1]+1) then
                          gHands[fLastHand].AI.Setup.StartPosition := KMPoint(P[0]+1,P[1]+1);

    ctSetAlliance:     if (fLastHand <> PLAYER_NONE) and fPlayerEnabled[P[0]] and (P[0] <> fLastHand) then
                          if P[1] = 1 then
                            gHands[fLastHand].Alliances[P[0]] := atAlly
                          else
                            gHands[fLastHand].Alliances[P[0]] := atEnemy;

    ctAttackPosition:  if (fLastHand <> PLAYER_NONE) and PointInMap(P[0]+1, P[1]+1) then
                          //If target is building: Attack building
                          //If target is unit: Chase/attack unit
                          //If target is nothing: move to position
                          //However, because the unit/house target may not have been created yet, this must be processed after everything else
                          if fLastTroop <> nil then
                            if fParsingMode = mpmEditor then
                            begin
                              fLastTroop.MapEdOrder.Order := ioAttackPosition;
                              fLastTroop.MapEdOrder.Pos := KMPointDir(P[0]+1, P[1]+1, dirNA);
                            end
                            else
                            begin
                              Inc(fAttackPositionsCount);
                              SetLength(fAttackPositions, fAttackPositionsCount+1);
                              fAttackPositions[fAttackPositionsCount-1].Group := fLastTroop;
                              fAttackPositions[fAttackPositionsCount-1].Target := KMPoint(P[0]+1,P[1]+1);
                            end
                          else
                            AddError('ct_AttackPosition without prior declaration of Troop');

    ctAddGoal:         //ADD_GOAL, condition, status, message_id, player_id,
                        if fLastHand <> PLAYER_NONE then
                        begin
                          if not InRange(P[0], 0, Byte(High(TKMGoalCondition))) then
                            AddError('Add_Goal with unknown condition index ' + IntToStr(P[0]))
                          else
                            if not (TKMGoalCondition(P[0]) in GoalsSupported) then
                              AddError('Goal type ' + GoalConditionStr[TKMGoalCondition(P[0])] + ' is deprecated')
                            else
                              if (P[2] <> 0) then
                                AddError('Goals messages are deprecated. Use .script instead')
                              else
                                if InRange(P[3], 0, gHands.Count - 1) and fPlayerEnabled[P[3]] then
                                  gHands[fLastHand].AI.Goals.AddGoal(gltVictory, TKMGoalCondition(P[0]), TKMGoalStatus(P[1]), 0, P[2], P[3]);
                        end;

    ctAddLostGoal:     if fLastHand <> PLAYER_NONE then
                        begin
                          if not InRange(P[0], 0, Byte(High(TKMGoalCondition))) then
                            AddError('Add_LostGoal with unknown condition index ' + IntToStr(P[0]))
                          else
                          if InRange(P[3], 0, gHands.Count - 1)
                          and fPlayerEnabled[P[3]] then
                          begin
                            if not (TKMGoalCondition(P[0]) in GoalsSupported) then
                              AddError('LostGoal type ' + GoalConditionStr[TKMGoalCondition(P[0])] + ' is deprecated');
                            if (P[2] <> 0) then
                              AddError('LostGoals messages are deprecated. Use .script instead');
                            gHands[fLastHand].AI.Goals.AddGoal(gltSurvive, TKMGoalCondition(P[0]), TKMGoalStatus(P[1]), 0, P[2], P[3]);
                          end;
                        end;

    ctAIDefence:       if (fLastHand <> PLAYER_NONE) and PointInMap(P[0]+1, P[1]+1) then
                          if InRange(P[3], Integer(Low(TKMGroupType)), Integer(High(TKMGroupType))) then //TPR 3 tries to set TKMGroupType 240 due to a missing space
                            gHands[fLastHand].AI.General.DefencePositions.Add(KMPointDir(P[0]+1, P[1]+1, TKMDirection(P[2]+1)),TKMGroupType(P[3]),P[4],TAIDefencePosType(P[5]));

    ctSetMapColor:     if fLastHand <> PLAYER_NONE then
                          //For now simply use the minimap color for all color, it is too hard to load all 8 shades from ctSetNewRemap
                          gHands[fLastHand].FlagColor := gRes.Palettes.DefaultPalette.Color32(P[0]);

    ctSetRGBColor:     if fLastHand <> PLAYER_NONE then
                          gHands[fLastHand].FlagColor := P[0] or $FF000000;

    ctAIAttack:        if fLastHand <> PLAYER_NONE then
                        begin
                          //Set up the attack command
                          if TextParam = AI_ATTACK_PARAMS[cptType] then
                            if InRange(P[1], Low(RemakeAttackType), High(RemakeAttackType)) then
                              fAIAttack.AttackType := RemakeAttackType[P[1]]
                            else
                              AddError('Unknown parameter ' + IntToStr(P[1]) + ' at ctAIAttack');
                          if TextParam = AI_ATTACK_PARAMS[cptTotalAmount] then
                            fAIAttack.TotalMen := P[1];
                          if TextParam = AI_ATTACK_PARAMS[cptCounter] then
                            fAIAttack.Delay := P[1];
                          if TextParam = AI_ATTACK_PARAMS[cptRange] then
                            fAIAttack.Range := P[1];
                          if TextParam = AI_ATTACK_PARAMS[cptTroopAmount] then
                            fAIAttack.GroupAmounts[TKMGroupType(P[1])] := P[2];
                          if TextParam = AI_ATTACK_PARAMS[cptTarget] then
                            fAIAttack.Target := TKMAIAttackTarget(P[1]);
                          if TextParam = AI_ATTACK_PARAMS[cptPosition] then
                            fAIAttack.CustomPosition := KMPoint(P[1]+1,P[2]+1);
                          if TextParam = AI_ATTACK_PARAMS[cptTakeAll] then
                            fAIAttack.TakeAll := True;
                        end;

    ctCopyAIAttack:    if fLastHand <> PLAYER_NONE then
                        begin
                          //Save the attack to the AI assets
                          gHands[fLastHand].AI.General.Attacks.AddAttack(fAIAttack);

                          //For KaM compatability we do NOT reset values before next Attack processing
                          //by default. In KaM values must be carried over since many missions rely on
                          //this. When we save AI attacks we use ctClearAIAttack to clear it manually
                          //FillChar(fAIAttack, SizeOf(fAIAttack), #0);
                        end;

    ctClearAIAttack:   if fLastHand <> PLAYER_NONE then
                          FillChar(fAIAttack, SizeOf(fAIAttack), #0);

    ctSetRallyPoint:   if (fLastHand <> PLAYER_NONE) and PointInMap(P[0]+1, P[1]+1) then
                        begin
                          if (fLastHouse <> nil) then
                          begin
                            if not fLastHouse.IsDestroyed  //Could be destroyed already by damage
                              and (fLastHouse is TKMHouseWFlagPoint) then
                              TKMHouseWFlagPoint(fLastHouse).FlagPoint := KMPoint(P[0]+1, P[1]+1);
                          end
                          else
                            AddError('ct_SetRallyPoint without prior declaration of House');
                        end;

    ctEnablePlayer:    ;//Serves no real purpose, all players have this command anyway

    ctSetNewRemap:     ;//Disused. Minimap color is used for all colors now. However it might be better to use these values in the long run as sometimes the minimap colors do not match well
  end;
  Result := True; //Must have worked if we haven't exited by now
end;


//Write out a KaM format mission file to aFileName
procedure TKMMissionParserStandard.SaveDATFile(const aFileName: string;  aLeftInset: SmallInt = 0; aTopInset: SmallInt = 0; aDoXorEncoding: Boolean = False);
const
  COMMANDLAYERS = 4;
var
  I: longint; //longint because it is used for encoding entire output, which will limit the file size
  K,J,iX,iY,CommandLayerCount: Integer;
  StoreCount, BarracksCount: Integer;
  Res: TKMWareType;
  G: TKMGroupType;
  U: TKMUnit;
  H: TKMHouse;
  Group: TKMUnitGroup;
  HT: TKMHouseType;
  ReleaseAllHouses: Boolean;
  SaveString: AnsiString;
  SaveStream: TFileStream;
  UT: TKMUnitType;

  procedure AddData(const aText: AnsiString);
  begin
    if CommandLayerCount = -1 then //No layering
      SaveString := SaveString + aText + EolA //Add to the string normally
    else
    begin
      case (CommandLayerCount mod COMMANDLAYERS) of
        0:   SaveString := SaveString + EolA + aText //Put a line break every 4 commands
        else SaveString := SaveString + ' ' + aText; //Just put spaces so commands "layer"
      end;
      Inc(CommandLayerCount);
    end
  end;

  procedure AddCommand(aCommand: TKMCommandType; aComParam: TKMCommandParamType; aParams: array of Integer); overload;
  var
    OutData: AnsiString;
    I: Integer;
  begin
    OutData := '!' + COMMANDVALUES[aCommand];

    if aComParam <> cptUnknown then
      OutData := OutData + ' ' + PARAMVALUES[aComParam];

    for I:=Low(aParams) to High(aParams) do
      OutData := OutData + ' ' + AnsiString(IntToStr(aParams[I]));

    AddData(OutData);
  end;

  procedure AddCommand(aCommand: TKMCommandType; aComParam: TAIAttackParamType; aParams: array of Integer); overload;
  var
    OutData: AnsiString;
    I: Integer;
  begin
    OutData := '!' + COMMANDVALUES[aCommand] + ' ' + AI_ATTACK_PARAMS[aComParam];

    for I:=Low(aParams) to High(aParams) do
      OutData := OutData + ' ' + AnsiString(IntToStr(aParams[I]));

    AddData(OutData);
  end;

  procedure AddCommand(aCommand: TKMCommandType; aParams: array of Integer); overload;
  begin
    AddCommand(aCommand, cptUnknown, aParams);
  end;

begin
  //Put data into stream
  SaveString := '';
  CommandLayerCount := -1; //Some commands (road/fields) are layered so the file is easier to read (not so many lines)

  //Main header, use same filename for MAP
  //We will probably discontinue KAM format,
  //if mapmaker wants to use MapEd for KaM he needs to update/change other things too
  //however without this line old KMR versions just refuse to load, so we keep it
  AddData('!' + COMMANDVALUES[ctSetMap] + ' "data\mission\smaps\' +
    AnsiString(ChangeFileExt(ExtractFileName(aFileName), '.map')) + '"');

  if gGame.MissionMode = mmTactic then AddCommand(ctSetTactic, []);
  AddCommand(ctSetMaxPlayer, [gHands.Count]);
  //When removing players DefaultHuman can be left outside the valid range
  if InRange(gGame.MapEditor.DefaultHuman, 0, gHands.Count - 1) then
    AddCommand(ctHumanPlayer, [gGame.MapEditor.DefaultHuman]);
  AddData(''); //NL

  //Player loop
  for I := 0 to gHands.Count - 1 do
  begin
    //Player header, using same order of commands as KaM
    AddCommand(ctSetCurrPlayer, [I]);
    AddCommand(ctEnablePlayer, [I]);

//    Assert(gGame.MapEditor.PlayerHuman[I]
//        or (not gGame.MapEditor.PlayerClassicAI[I] and not gGame.MapEditor.PlayerAdvancedAI[I]),
//          'There can''t be ');
    Assert(gGame.MapEditor.PlayerHuman[I]
        or gGame.MapEditor.PlayerClassicAI[I]
        or gGame.MapEditor.PlayerAdvancedAI[I], 'At least one player type should be available for hand ' + IntToStr(I));

    if gGame.MapEditor.PlayerHuman[I] then AddCommand(ctUserPlayer, []);
    if gGame.MapEditor.PlayerClassicAI[I] then AddCommand(ctAIPlayer, []);
    if gGame.MapEditor.PlayerAdvancedAI[I] then AddCommand(ctAdvancedAIPlayer, []);

    //Write RGB command second so it will be used if color is not from KaM palette
    AddCommand(ctSetRGBColor, [gHands[I].FlagColor and $00FFFFFF]);

    if not KMSamePoint(gHands[I].CenterScreen, KMPOINT_ZERO) then
      AddCommand(ctCenterScreen, [gHands[I].CenterScreen.X - 1 + aLeftInset, gHands[I].CenterScreen.Y - 1 + aTopInset]);

    with gGame.MapEditor.Revealers[I] do
    for K := 0 to Count - 1 do
      AddCommand(ctClearUp, [Items[K].X - 1 + aLeftInset, Items[K].Y - 1 + aTopInset, Tag[K]]);

    if gGame.MapEditor.RevealAll[I] then
      AddCommand(ctClearUp, [255]);

    AddData(''); //NL

    //Human specific, e.g. goals, center screen (though all players can have it, only human can use it)
    for K := 0 to gHands[I].AI.Goals.Count - 1 do
      with gHands[I].AI.Goals[K] do
      begin
        if (GoalType = gltVictory) or (GoalType = gltNone) then //For now treat none same as normal goal, we can add new command for it later
          if GoalCondition = gcTime then
            AddCommand(ctAddGoal, [byte(GoalCondition),byte(GoalStatus),MessageToShow,GoalTime])
          else
            AddCommand(ctAddGoal, [byte(GoalCondition),byte(GoalStatus),MessageToShow, HandIndex]);

        if GoalType = gltSurvive then
          if GoalCondition = gcTime then
            AddCommand(ctAddLostGoal, [byte(GoalCondition),byte(GoalStatus),MessageToShow,GoalTime])
          else
            AddCommand(ctAddLostGoal, [byte(GoalCondition),byte(GoalStatus),MessageToShow, HandIndex]);
      end;
    AddData(''); //NL

    //Computer specific, e.g. AI commands. Always save these commands even if the player
    //is not AI so no data is lost from MapEd (human players will ignore AI script anyway)
    AddCommand(ctAIStartPosition, [gHands[I].AI.Setup.StartPosition.X-1,gHands[I].AI.Setup.StartPosition.Y-1]);
    if not gHands[I].AI.Setup.AutoBuild then AddCommand(ctAINoBuild, []);
    if gHands[I].AI.Setup.AutoRepair then    AddCommand(ctAIAutoRepair, []);
    if gHands[I].AI.Setup.AutoAttack then    AddCommand(ctAIAutoAttack, []);
    if gHands[I].AI.Setup.AutoDefend then    AddCommand(ctAIAutoDefend, []);
    if gHands[I].AI.Setup.DefendAllies then  AddCommand(ctAIDefendAllies, []);
    if gHands[I].AI.Setup.UnlimitedEquip then AddCommand(ctAIUnlimitedEquip, []);
    AddCommand(ctAIArmyType, [Byte(gHands[I].AI.Setup.ArmyType)]);
    AddCommand(ctAICharacter,cptRecruits, [gHands[I].AI.Setup.RecruitCount]);
    AddCommand(ctAICharacter,cptWorkerFactor, [Round(10 / gHands[I].AI.Setup.SerfsPerHouse)]);
    AddCommand(ctAICharacter,cptConstructors, [gHands[I].AI.Setup.WorkerCount]);
    AddCommand(ctAICharacter,cptTownDefence, [gHands[I].AI.Setup.TownDefence]);
    AddCommand(ctAICharacter,cptAutoAttackRange, [gHands[I].AI.Setup.AutoAttackRange]);
    //Only store if a limit is in place (high is the default)
    if gHands[I].AI.Setup.MaxSoldiers <> -1 then
      AddCommand(ctAICharacter,cptMaxSoldier, [gHands[I].AI.Setup.MaxSoldiers]);
    AddCommand(ctAICharacter,cptEquipRateLeather, [gHands[I].AI.Setup.EquipRateLeather]);
    AddCommand(ctAICharacter,cptEquipRateIron,    [gHands[I].AI.Setup.EquipRateIron]);
    AddCommand(ctAICharacter,cptAttackFactor, [gHands[I].AI.Setup.Aggressiveness]);
    AddCommand(ctAICharacter,cptRecruitCount, [gHands[I].AI.Setup.RecruitDelay]);
    for G:=Low(TKMGroupType) to High(TKMGroupType) do
      if gHands[I].AI.General.DefencePositions.TroopFormations[G].NumUnits <> 0 then //Must be valid and used
        AddCommand(ctAICharacter, cptTroopParam, [KaMGroupType[G], gHands[I].AI.General.DefencePositions.TroopFormations[G].NumUnits, gHands[I].AI.General.DefencePositions.TroopFormations[G].UnitsPerRow]);
    AddData(''); //NL
    for K:=0 to gHands[I].AI.General.DefencePositions.Count - 1 do
      with gHands[I].AI.General.DefencePositions[K] do
        AddCommand(ctAIDefence, [Position.Loc.X - 1 + aLeftInset,
                                  Position.Loc.Y - 1 + aTopInset,
                                  Byte(Position.Dir) - 1,
                                  KaMGroupType[GroupType],
                                  Radius,
                                  Byte(DefenceType)]);
    AddData(''); //NL
    AddData(''); //NL
    for K := 0 to gHands[I].AI.General.Attacks.Count - 1 do
      with gHands[I].AI.General.Attacks[K] do
      begin
        AddCommand(ctAIAttack, cptType, [KaMAttackType[AttackType]]);
        AddCommand(ctAIAttack, cptTotalAmount, [TotalMen]);
        if TakeAll then
          AddCommand(ctAIAttack, cptTakeAll, [])
        else
          for G:=Low(TKMGroupType) to High(TKMGroupType) do
            AddCommand(ctAIAttack, cptTroopAmount, [KaMGroupType[G], GroupAmounts[G]]);

        if (Delay > 0) or (AttackType = aatOnce) then //Type once must always have counter because it uses the delay
          AddCommand(ctAIAttack,cptCounter, [Delay]);

        AddCommand(ctAIAttack,cptTarget, [Byte(Target)]);
        if Target = attCustomPosition then
          AddCommand(ctAIAttack,cptPosition, [CustomPosition.X-1 + aLeftInset,CustomPosition.Y-1 + aTopInset]);

        if Range > 0 then
          AddCommand(ctAIAttack,cptRange, [Range]);

        AddCommand(ctCopyAIAttack, [K]); //Store attack with ID number
        AddCommand(ctClearAIAttack, []); //Clear values so they don't carry over to next attack
        AddData(''); //NL
      end;
    AddData(''); //NL

    //General, e.g. units, roads, houses, etc.
    //Alliances
    for K:=0 to gHands.Count-1 do
      if K<>I then
        AddCommand(ctSetAlliance, [K, Byte(gHands[I].Alliances[K])]); //0=enemy, 1=ally
    AddData(''); //NL

    //Release/block houses
    ReleaseAllHouses := True;
    for HT := HOUSE_MIN to HOUSE_MAX do
    begin
      if gHands[I].Locks.HouseBlocked[HT] then
      begin
        AddCommand(ctBlockHouse, [HouseTypeToIndex[HT]-1]);
        ReleaseAllHouses := false;
      end
      else
        if gHands[I].Locks.HouseGranted[HT] then
          AddCommand(ctReleaseHouse, [HouseTypeToIndex[HT]-1])
        else
          ReleaseAllHouses := false;
    end;
    if ReleaseAllHouses then
      AddCommand(ctReleaseAllHouses, []);

    //Block units
    for UT := HUMANS_MIN to HUMANS_MAX do
    begin
      if (UT = utMilitia) and gHands[I].Locks.GetUnitBlocked(UT, True) then
        AddCommand(ctBlockUnit, [UnitTypeToIndex[UT], 1]); // 1 - special case for militia in TownHall

      if gHands[I].Locks.GetUnitBlocked(UT) then
        AddCommand(ctBlockUnit, [UnitTypeToIndex[UT], 0]); // means default
    end;

    //Block trades
    for Res := WARE_MIN to WARE_MAX do
      if not gHands[I].Locks.AllowToTrade[Res] then
        AddCommand(ctBlockTrade, [WareTypeToIndex[Res]]);

    //Houses
    StoreCount := 0;
    BarracksCount := 0;
    for K := 0 to gHands[I].Houses.Count - 1 do
    begin
      H := gHands[I].Houses[K];
      if not H.IsDestroyed then
      begin
        AddCommand(ctSetHouse, [HouseTypeToIndex[H.HouseType]-1, H.Position.X-1 + aLeftInset, H.Position.Y-1 + aTopInset]);
        if H.IsDamaged then
          AddCommand(ctSetHouseDamage, [H.GetDamage]);

        if H.BuildingRepair then // Repair mode is turned off by default
          AddCommand(ctSetHouseRepairMode, []);

        if H.IsClosedForWorker then
          AddCommand(ctSetHouseClosedForWorker, []);

        if H is TKMHouseBarracks then
        begin
          for J := 1 to TKMHouseBarracks(H).MapEdRecruitCount do
            AddCommand(ctUnitAddToLast, [UnitTypeToOldIndex[utRecruit]]);
        end;

        if (H is TKMHouseWFlagPoint)
          and TKMHouseWFlagPoint(H).IsFlagPointSet then
          AddCommand(ctSetRallyPoint, [TKMHouseWFlagPoint(H).FlagPoint.X-1 + aLeftInset, TKMHouseWFlagPoint(H).FlagPoint.Y-1 + aTopInset]);

        //Process any wares in this house
        //First two Stores use special KaM commands
        if (H.HouseType = htStore) and (StoreCount < 2) then
        begin
          Inc(StoreCount);
          for Res := WARE_MIN to WARE_MAX do
            if H.CheckResIn(Res) > 0 then
              case StoreCount of
                1:  AddCommand(ctAddWare, [WareTypeToIndex[Res], H.CheckResIn(Res)]);
                2:  AddCommand(ctAddWareToSecond, [WareTypeToIndex[Res], H.CheckResIn(Res)]);
              end;
        end
        else
        //First Barracks uses special KaM command
        if (H.HouseType = htBarracks) and (BarracksCount = 0) then
        begin
          Inc(BarracksCount);
          for Res := WARFARE_MIN to WARFARE_MAX do
            if H.CheckResIn(Res) > 0 then
              AddCommand(ctAddWeapon, [WareTypeToIndex[Res], H.CheckResIn(Res)]); //Ware, Count
        end
        else
          for Res := WARE_MIN to WARE_MAX do
          begin
            if H.CheckResIn(Res) > 0 then
              AddCommand(ctAddWareToLast, [WareTypeToIndex[Res], H.CheckResIn(Res)]);
            if H.CheckResOut(Res) > 0 then
              AddCommand(ctAddWareToLast, [WareTypeToIndex[Res], H.CheckResOut(Res)]);
          end;

        //Set Delivery mode after Wares, so in case there are some wares and delivery mode TakeOut, then we will need to add proper Offers
        if H.DeliveryMode <> dmDelivery then //Default delivery mode is dmDelivery
          AddCommand(ctSetHouseDeliveryMode, [Byte(H.DeliveryMode)]);
      end;
    end;
    AddData(''); //NL

    //Roads and fields. We must check EVERY terrain tile
    CommandLayerCount := 0; //Enable command layering
    for iY := 1 to gTerrain.MapY do
      for iX := 1 to gTerrain.MapX do
        if gTerrain.Land[iY,iX].TileOwner = gHands[I].ID then
        begin
          if gTerrain.Land[iY,iX].TileOverlay = toRoad then
          begin
            H := gHands.HousesHitTest(iX, iY);
            //Don't place road under the entrance of houses (it will be placed there if the house is destroyed on mission start)
            if (H = nil) or not KMSamePoint(H.Entrance, KMPoint(iX, iY)) then
              AddCommand(ctSetRoad, [iX-1 + aLeftInset,iY-1 + aTopInset]);
          end;
          if gTerrain.TileIsCornField(KMPoint(iX,iY)) then
            AddCommand(ctSetFieldStaged, [iX-1 + aLeftInset, iY-1 + aTopInset, gTerrain.GetCornStage(KMPoint(iX, iY))]);
          if gTerrain.TileIsWineField(KMPoint(iX,iY)) then
            AddCommand(ctSetWinefieldStaged, [iX-1 + aLeftInset, iY-1 + aTopInset, gTerrain.GetWineStage(KMPoint(iX, iY))]);
        end;
    CommandLayerCount := -1; //Disable command layering
    AddData(''); //Extra NL because command layering doesn't put one
    AddData(''); //NL

    //Units
    for K := 0 to gHands[I].Units.Count - 1 do
    begin
      U := gHands[I].Units[K];
      if not (U is TKMUnitWarrior) then //Groups get saved separately
      begin
        AddCommand(ctSetUnit, [UnitTypeToOldIndex[U.UnitType], U.CurrPosition.X-1 + aLeftInset, U.CurrPosition.Y-1 + aTopInset]);
        if not U.StartWDefaultCondition then
          AddCommand(ctSetUnitFood, [U.Condition]);
      end;
    end;

    //Unit groups
    for K := 0 to gHands[I].UnitGroups.Count - 1 do
    begin
      Group := gHands[I].UnitGroups[K];
      AddCommand(ctSetGroup, [UnitTypeToIndex[Group.UnitType], Group.Position.X-1 + aLeftInset, Group.Position.Y-1 + aTopInset, Byte(Group.Direction)-1, Group.UnitsPerRow, Group.MapEdCount]);
      if not Group.FlagBearer.StartWDefaultCondition then
        AddCommand(ctSetGroupFood, [Group.FlagBearer.Condition]);

      case Group.MapEdOrder.Order of
        ioNoOrder: ;
        ioSendGroup:
          AddCommand(ctSendGroup, [Group.MapEdOrder.Pos.Loc.X-1 + aLeftInset, Group.MapEdOrder.Pos.Loc.Y-1 + aTopInset, Byte(Group.MapEdOrder.Pos.Dir)-1]);
        ioAttackPosition:
          AddCommand(ctAttackPosition, [Group.MapEdOrder.Pos.Loc.X-1 + aLeftInset, Group.MapEdOrder.Pos.Loc.Y-1 + aTopInset]);
        else
          raise Exception.Create('Unexpected group order in MapEd');
      end;
    end;

    AddData(''); //NL
    AddData(''); //NL
  end; //Player loop

  //Main footer

  //Animals, wares to all, etc. go here
  AddData('//Animals');
  for I := 0 to gHands.PlayerAnimals.Units.Count - 1 do
  begin
    U := gHands.PlayerAnimals.Units[I];
    AddCommand(ctSetUnit, [UnitTypeToOldIndex[U.UnitType], U.CurrPosition.X-1 + aLeftInset, U.CurrPosition.Y-1 + aTopInset]);
  end;
  AddData(''); //NL

  //Similar footer to one in Lewin's Editor, useful so ppl know what mission was made with.
  AddData('//This mission was made with KaM Remake Map Editor version ' + GAME_VERSION + ' at ' + AnsiString(DateTimeToStr(Now)));


  if aDoXorEncoding then
  begin
    //Write uncoded file for debug
    SaveStream := TFileStream.Create(aFileName+'.txt', fmCreate);
    SaveStream.WriteBuffer(SaveString[1], Length(SaveString));
    SaveStream.Free;

    //Encode file
    for I := 1 to Length(SaveString) do
      SaveString[I] := AnsiChar(Byte(SaveString[I]) xor 239);
  end;

  SaveStream := TFileStream.Create(aFileName, fmCreate);
  SaveStream.WriteBuffer(SaveString[1], Length(SaveString));
  SaveStream.Free;
end;


end.

