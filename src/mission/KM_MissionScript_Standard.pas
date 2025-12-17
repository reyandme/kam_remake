unit KM_MissionScript_Standard;
{$I KaM_Remake.inc}
interface
uses
  Generics.Collections,
  KM_MissionScript, KM_UnitGroup, KM_Units, KM_Houses,
  KM_AIAttacks, KM_Points, KM_Defaults, KM_UnitGroupTypes;


type
  TKMMissionScriptGroupOrder = record
    Group: TKMUnitGroup;
    Kind: TKMGroupInitialOrder;
    Target: TKMPoint;
    Dir: TKMDirection;
  end;

  TKMMissionParserStandard = class(TKMMissionParserCommon)
  private
    fParsingMode: TKMMissionParsingMode; //Data gets sent to Game differently depending on Game/Editor mode
    fPlayerEnabled: TKMHandEnabledArray;
    fLastHouse: TKMHouse;
    fLastUnit: TKMUnit;
    fLastTroop: TKMUnitGroup;
    fAIAttack: TKMAIAttack;
    fGroupOrders: TList<TKMMissionScriptGroupOrder>;
    fDefaultLocation: ShortInt;
    procedure HandleGroupOrders;
    procedure Init(aMode: TKMMissionParsingMode);
  protected
    procedure ProcessCommand(CommandType: TKMCommandType; P: array of Integer; const TextParam: AnsiString = ''); override;
  public
    constructor Create(aMode: TKMMissionParsingMode); overload;
    constructor Create(aMode: TKMMissionParsingMode; var aPlayersEnabled: TKMHandEnabledArray); overload;
    destructor Destroy; override;

    procedure LoadMission(const aFileName: string); override;
    procedure PostLoadMission;

    property DefaultLocation: ShortInt read fDefaultLocation;
    procedure SaveDATFile(const aFileName: string; aLeftInset: SmallInt = 0; aTopInset: SmallInt = 0; aDoXorEncoding: Boolean = False);
  end;


implementation
uses
  Classes, SysUtils, Math, KromUtils,
  KM_Hand, KM_HandEntity,
  KM_Game, KM_GameParams, KM_GameTypes, KM_HandsCollection,
  KM_UnitsCollection, KM_UnitWarrior,
  KM_HouseCollection, KM_HouseBarracks, KM_HouseStore,
  KM_AI,
  KM_Resource, KM_ResHouses, KM_ResUnits, KM_ResWares,
  KM_CommonClasses, KM_CommonTypes, KM_Terrain,
  KM_HandTypes,
  KM_CommonExceptions,
  KM_ResTypes,
  KM_TerrainTypes,
  KM_MapTypes,
  KM_AITypes;


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


{ TKMMissionParserStandard }
// Mode affect how certain parameters are loaded a bit differently
constructor TKMMissionParserStandard.Create(aMode: TKMMissionParsingMode);
var
  I: Integer;
begin
  inherited Create;

  Init(aMode);

  for I := 0 to High(fPlayerEnabled) do
    fPlayerEnabled[I] := True;
end;


constructor TKMMissionParserStandard.Create(aMode: TKMMissionParsingMode; var aPlayersEnabled: TKMHandEnabledArray);
begin
  inherited Create;

  Init(aMode);

  //Tells us which player should be enabled and which ignored/skipped
  fPlayerEnabled := aPlayersEnabled;
end;


procedure TKMMissionParserStandard.Init(aMode: TKMMissionParsingMode);
begin
  fGroupOrders := TList<TKMMissionScriptGroupOrder>.Create;
  fParsingMode := aMode;
  fDefaultLocation := 0;
end;


destructor TKMMissionParserStandard.Destroy;
begin
  fGroupOrders.Free;

  inherited;
end;


procedure TKMMissionParserStandard.LoadMission(const aFileName: string);
var
  fileText: AnsiString;
begin
  inherited LoadMission(aFileName);

  Assert((gTerrain <> nil) and (gHands <> nil));

  //Load the terrain since we know where it is beforehand
  if not FileExists(ChangeFileExt(fMissionFileName, '.map')) then
    raise Exception.Create('Map file couldn''t be found');

  gTerrain.LoadFromFile(ChangeFileExt(fMissionFileName, '.map'), fParsingMode = mpmEditor);
  gGame.TerrainPainter.LoadFromFile(ChangeFileExt(fMissionFileName, '.map'));

  //Read the mission file into FileText
  fileText := ReadMissionFile(aFileName);
  if fileText = '' then
    raise Exception.Create('Script is empty');

  TokenizeScript(fileText, 6, []);
end;


procedure TKMMissionParserStandard.PostLoadMission;
begin
  //Post-processing of ctAttack_Position commands which must be done after mission has been loaded
  HandleGroupOrders;
  gHands.PostLoadMission;
end;


//Determine what we are attacking: House, Unit or just walking to some place
procedure TKMMissionParserStandard.HandleGroupOrders;
var
  I: Integer;
  H: TKMHouse;
  U: TKMUnit;
begin
  Assert((fParsingMode <> mpmEditor) or (fGroupOrders.Count = 0), 'AttackPositions should be handled by MapEd');

  for I := 0 to fGroupOrders.Count - 1 do
    with fGroupOrders[I] do
    begin
      case Kind of
        gioNoOrder:         ;
        gioSendGroup:       Group.OrderWalk(Target, True, wtokMissionScript, Dir);
        gioAttackPosition:  begin
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
    end;
end;


procedure TKMMissionParserStandard.ProcessCommand(CommandType: TKMCommandType; P: array of Integer; const TextParam: AnsiString = '');

  function PointInMap(X, Y: Integer): Boolean;
  begin
    Result := InRange(X, 1, gTerrain.MapX)
          and InRange(Y, 1, gTerrain.MapY);
  end;

var
  I: Integer;
  qty, HandI: Integer;
  U: TKMUnit;
  H: TKMHouse;
  HT: TKMHouseType;
  UT: TKMUnitType;
  iPlayerAI: TKMHandAI;
  chooseLoc: TKMChooseLoc;
  groupOrder: TKMMissionScriptGroupOrder;
begin
  case CommandType of
    ctSetMap:           begin
                          //Check for KaM format map path (disused, as Remake maps are always next to DAT script)
                          {MapFileName := RemoveQuotes(String(TextParam));
                          if FileExists(ExeDir + MapFileName) then
                          begin
                            fTerrain.LoadFromFile(ExeDir+MapFileName, fParsingMode = mpmEditor)
                            if fParsingMode = mpmEditor then
                              fTerrainPainter.LoadFromFile(ExeDir+MapFileName);
                          end}
                        end;

    ctSetMaxPlayer:     begin
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

    ctSetTactic:        begin
                          //Default is mmNormal
                          gGameParams.MissionMode := mmFighting;
                        end;

    ctSetCurrPlayer:    if InRange(P[0], 0, MAX_HANDS - 1) then
                        begin
                          if fPlayerEnabled[P[0]] then
                            fLastHand := P[0]
                          else
                            fLastHand := HAND_NONE; //Lets us skip this player
                          fLastHouse := nil;
                          fLastTroop := nil;
                          fLastUnit := nil;
                        end;

    ctHumanPlayer:      begin
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

    ctAIPlayer:         if (gHands <> nil) then
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

    ctCenterScreen:     if (fLastHand <> HAND_NONE)
                          and PointInMap(P[0]+1, P[1]+1) then
                          gHands[fLastHand].CenterScreen := KMPoint(P[0]+1, P[1]+1);

    ctChooseLoc:        if (fLastHand <> HAND_NONE) then
                        begin
                          chooseLoc := gHands[fLastHand].ChooseLocation;
                          chooseLoc.Allowed := Boolean(P[0]);
                          gHands[fLastHand].ChooseLocation := chooseLoc;
                        end;

    ctChooseLocAddWare: if (fLastHand <> HAND_NONE) then
                        begin
                          qty := EnsureRange(P[1], -1, High(Word)); //Sometimes user can define it to be 999999
                          if qty = -1 then qty := High(Word); //-1 means maximum resources
                          chooseLoc := gHands[fLastHand].ChooseLocation;
                          chooseLoc.Resources[ WARE_ID_TO_TYPE[P[0]] ] := qty;
                          gHands[fLastHand].ChooseLocation := chooseLoc;
                        end;

    ctChooseLocAddUnit: if (fLastHand <> HAND_NONE) then
                        begin
                          qty := EnsureRange(P[1], -1, High(Byte)); //Sometimes user can define it to be 999999
                          if qty = -1 then qty := High(Byte); //-1 means maximum resources
                          chooseLoc := gHands[fLastHand].ChooseLocation;
                          chooseLoc.Units[ UNIT_ID_TO_TYPE[P[0]] ] := qty;
                          gHands[fLastHand].ChooseLocation := chooseLoc;
                        end;

    ctClearUp:          if fLastHand <> HAND_NONE then
                        begin
                          if fParsingMode = mpmEditor then
                          begin
                            if P[0] = 255 then
                              gGame.MapEditor.RevealAll[fLastHand] := True
                            else if PointInMap(P[0]+1, P[1]+1) then
                              gGame.MapEditor.Revealers[fLastHand].Add(KMPoint(P[0]+1,P[1]+1), P[2]);
                          end else begin
                            if P[0] = 255 then
                            begin
                              gHands[fLastHand].FogOfWar.RevealEverything;
                              gHands[fLastHand].FogOfWar.InitialRevealAll := True;
                            end
                            else
                            if PointInMap(P[0]+1, P[1]+1) then
                            begin
                              gHands[fLastHand].FogOfWar.RevealCircle(KMPoint(P[0]+1,P[1]+1), P[2], 255);
                              gHands[fLastHand].FogOfWar.InitialRevealers.Add(KMPoint(P[0]+1,P[1]+1), P[2]);
                            end;
                          end;
                        end;

    ctSetHouse:         if fLastHand <> HAND_NONE then
                          if PointInMap(P[1]+1, P[2]+1) and InRange(P[0], Low(HOUSE_ID_TO_TYPE), High(HOUSE_ID_TO_TYPE)) then
                            if gTerrain.CanPlaceHouseFromScript(HOUSE_ID_TO_TYPE[P[0]], KMPoint(P[1]+1, P[2]+1)) then
                              fLastHouse := gHands[fLastHand].AddHouse(
                                HOUSE_ID_TO_TYPE[P[0]], P[1]+1, P[2]+1, False)
                            else
                              AddError('ct_SetHouse failed, can not place house at ' + TypeToString(KMPoint(P[1]+1, P[2]+1)));

    ctSetHouseDamage:   if fLastHand <> HAND_NONE then //Skip False-positives for skipped players
                          if fLastHouse <> nil then
                          begin
                            if not fLastHouse.IsDestroyed then //Could be destroyed already by damage
                              fLastHouse.AddDamage(Min(P[0], High(Word)), nil, fParsingMode = mpmEditor)
                          end
                          else
                            AddError('ct_SetHouseDamage without prior declaration of House');

    ctSetHouseDeliveryMode:
                        if fLastHand <> HAND_NONE then //Skip False-positives for skipped players
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
                        if fLastHand <> HAND_NONE then //Skip False-positives for skipped players
                          if fLastHouse <> nil then
                            fLastHouse.BuildingRepair := True
                          else
                            AddError('ct_SetHouseRepairMode without prior declaration of House');

    ctSetHouseClosedForWorker:
                        if fLastHand <> HAND_NONE then //Skip False-positives for skipped players
                          // House could be already destroyed if he had full HP damage (thus 0 hp) in the static script
                          if (fLastHouse <> nil) and not fLastHouse.IsDestroyed then
                            fLastHouse.IsClosedForWorker := True
                          else
                            AddError('ct_SetHouseClosedForWorker without prior declaration of House');

    ctSetUnit:          if PointInMap(P[1]+1, P[2]+1) then
                        begin
                          UT := UNIT_OLD_ID_TO_TYPE[P[0]];
                          //Animals should be added regardless of current player
                          if UT in [ANIMAL_MIN..ANIMAL_MAX] then
                          begin
                            U := gHands.PlayerAnimals.AddUnit(UT, KMPoint(P[1]+1, P[2]+1));
                            if (U is TKMUnitFish) and InRange(P[3], 1, UNIT_FISH_CONUT_MAX) then
                              TKMUnitFish(U).FishCount := P[3];
                          end
                          else
                          if (fLastHand <> HAND_NONE) and (UT in [HUMANS_MIN..HUMANS_MAX]) then
                            fLastUnit := gHands[fLastHand].AddUnit(UT, KMPoint(P[1]+1, P[2]+1));
                        end;

    ctSetUnitByStock:   if fLastHand <> HAND_NONE then
                          if UNIT_OLD_ID_TO_TYPE[P[0]] in [HUMANS_MIN..HUMANS_MAX] then
                          begin
                            H := gHands[fLastHand].FindHouse(htStore, 1);
                            if (H <> nil) and PointInMap(H.Entrance.X, H.Entrance.Y+1) then
                              gHands[fLastHand].AddUnit(UNIT_OLD_ID_TO_TYPE[P[0]], KMPoint(H.Entrance.X, H.Entrance.Y+1));
                          end;

    ctUnitAddToLast:    if fLastHand <> HAND_NONE then
                          if fLastHouse <> nil then
                          begin
                            if (fLastHouse is TKMHouseBarracks) and (P[0] = UNIT_TYPE_TO_OLD_ID[utRecruit]) then
                            begin
                              if not fLastHouse.IsDestroyed then //Could be destroyed already by damage
                                TKMHouseBarracks(fLastHouse).CreateRecruitInside(fParsingMode = mpmEditor);
                            end
                            else
                              AddError('ct_UnitAddToLast only supports barracks and recruits so far');
                          end
                          else
                            AddError('ct_UnitAddToLast without prior declaration of House');

    ctSetUnitFood:      if fLastHand <> HAND_NONE then
                        begin
                          if fLastUnit <> nil then
                          begin
                            fLastUnit.StartWDefaultCondition := False;
                            if P[0] <> -1 then
                              fLastUnit.Condition := P[0];
                          end else
                            AddError('ct_SetUnitFood without prior declaration of Unit');
                        end;

    ctSetRoad:          if (fLastHand <> HAND_NONE) and PointInMap(P[0]+1, P[1]+1) then
                          gHands[fLastHand].AddRoadToList(KMPoint(P[0]+1,P[1]+1));

    ctSetField:         if (fLastHand <> HAND_NONE) and PointInMap(P[0]+1, P[1]+1) then
                          gHands[fLastHand].AddField(KMPoint(P[0]+1,P[1]+1),ftCorn,0,True,False);

    ctSetFieldStaged:   if (fLastHand <> HAND_NONE) and PointInMap(P[0]+1, P[1]+1) then
                          gHands[fLastHand].AddField(KMPoint(P[0]+1,P[1]+1),ftCorn,P[2],False,False);

    ctSetWinefield:     if (fLastHand <> HAND_NONE) and PointInMap(P[0]+1, P[1]+1) then
                          gHands[fLastHand].AddField(KMPoint(P[0]+1,P[1]+1),ftWine,0,True,False);

    ctSetWinefieldStaged:  if (fLastHand <> HAND_NONE) and PointInMap(P[0]+1, P[1]+1) then
                              gHands[fLastHand].AddField(KMPoint(P[0]+1,P[1]+1),ftWine,P[2],False,False);

    ctSetStock:         if (fLastHand <> HAND_NONE) and PointInMap(P[0]+1, P[1]+1) then
                        begin //This command basically means: Put a SH here with road bellow it
                          fLastHouse := gHands[fLastHand].AddHouse(htStore, P[0]+1,P[1]+1, False);
                          gHands[fLastHand].AddRoadToList(KMPoint(P[0]+1,P[1]+2));
                          gHands[fLastHand].AddRoadToList(KMPoint(P[0],P[1]+2));
                          gHands[fLastHand].AddRoadToList(KMPoint(P[0]-1,P[1]+2));
                        end;
    // @Deprecated, used AddWareToLast instead
    ctAddWare:          if fLastHand <> HAND_NONE then
                        begin
                          qty := EnsureRange(P[1], -1, High(Word)); //Sometimes user can define it to be 999999
                          if qty = -1 then qty := High(Word); //-1 means maximum resources
                          H := gHands[fLastHand].FindHouse(htStore,1);
                          if (H <> nil) and H.WareCanAddToIn(WARE_ID_TO_TYPE[P[0]]) then
                          begin
                            H.WareAddToIn(WARE_ID_TO_TYPE[P[0]], qty, True);
                            gHands[fLastHand].Stats.WareInitial(WARE_ID_TO_TYPE[P[0]], qty);
                          end;
                        end;
    // @Deprecated, used AddWareToLast instead
    ctAddWareToAll:    begin
                          qty := EnsureRange(P[1], -1, High(Word)); //Sometimes user can define it to be 999999
                          if qty = -1 then qty := High(Word); //-1 means maximum resources
                          for I := 0 to gHands.Count - 1 do
                          begin
                            H := gHands[i].FindHouse(htStore, 1);
                            if (H <> nil) and H.WareCanAddToIn(WARE_ID_TO_TYPE[P[0]]) then
                            begin
                              H.WareAddToIn(WARE_ID_TO_TYPE[P[0]], qty, True);
                              gHands[i].Stats.WareInitial(WARE_ID_TO_TYPE[P[0]], qty);
                            end;
                          end;
                        end;
    // @Deprecated, used AddWareToLast instead
    ctAddWareToSecond:  if fLastHand <> HAND_NONE then
                        begin
                          qty := EnsureRange(P[1], -1, High(Word)); //Sometimes user can define it to be 999999
                          if qty = -1 then qty := High(Word); //-1 means maximum resources

                          H := TKMHouseStore(gHands[fLastHand].FindHouse(htStore, 2));
                          if (H <> nil) and H.WareCanAddToIn(WARE_ID_TO_TYPE[P[0]]) then
                          begin
                            H.WareAddToIn(WARE_ID_TO_TYPE[P[0]], qty, True);
                            gHands[fLastHand].Stats.WareInitial(WARE_ID_TO_TYPE[P[0]], qty);
                          end;
                        end;

    //Depreciated by ctAddWareToLast, but we keep it for backwards compatibility in loading
    ctAddWareTo:        if fLastHand <> HAND_NONE then
                        begin //HouseType, House Order, Ware Type, Count
                          qty := EnsureRange(P[3], -1, High(Word)); //Sometimes user can define it to be 999999
                          if qty = -1 then qty := High(Word); //-1 means maximum resources

                          H := gHands[fLastHand].FindHouse(HOUSE_ID_TO_TYPE[P[0]], P[1]);
                          if (H <> nil) and (H.WareCanAddToIn(WARE_ID_TO_TYPE[P[2]]) or H.WareCanAddToOut(WARE_ID_TO_TYPE[P[2]])) then
                          begin
                            H.WareAddToEitherFromScript(WARE_ID_TO_TYPE[P[2]], qty);
                            gHands[fLastHand].Stats.WareInitial(WARE_ID_TO_TYPE[P[2]], qty);
                          end;
                        end;

    ctAddWareToLast:    if fLastHand <> HAND_NONE then
                        begin //Ware Type, Count
                          qty := EnsureRange(P[1], -1, High(Word)); //Sometimes user can define it to be 999999
                          if qty = -1 then qty := High(Word); //-1 means maximum resources

                          if (fLastHouse <> nil) and (fLastHouse.WareCanAddToIn(WARE_ID_TO_TYPE[P[0]]) or fLastHouse.WareCanAddToOut(WARE_ID_TO_TYPE[P[0]])) then
                          begin
                            if not fLastHouse.IsDestroyed then //Could be destroyed already by damage
                            begin
                              fLastHouse.WareAddToEitherFromScript(WARE_ID_TO_TYPE[P[0]], qty);
                              gHands[fLastHand].Stats.WareInitial(WARE_ID_TO_TYPE[P[0]], qty);
                            end;
                          end
                          else
                            AddError('ct_AddWareToLast without prior declaration of House');
                        end;
    // @Deprecated, used AddWareToLast instead
    ctAddWeapon:        if fLastHand <> HAND_NONE then
                        begin
                          qty := EnsureRange(P[1], -1, High(Word)); //Sometimes user can define it to be 999999
                          if qty = -1 then qty := High(Word); //-1 means maximum weapons
                          H := gHands[fLastHand].FindHouse(htBarracks, 1);
                          if (H <> nil) and H.WareCanAddToIn(WARE_ID_TO_TYPE[P[0]]) then
                          begin
                            H.WareAddToIn(WARE_ID_TO_TYPE[P[0]], qty, True);
                            gHands[fLastHand].Stats.WareInitial(WARE_ID_TO_TYPE[P[0]], qty);
                          end;
                        end;

    ctBlockTrade:       if fLastHand <> HAND_NONE then
                        begin
                          if WARE_ID_TO_TYPE[P[0]] in [WARE_MIN..WARE_MAX] then
                            gHands[fLastHand].Locks.AllowToTrade[WARE_ID_TO_TYPE[P[0]]] := False;
                        end;

    ctBlockUnit:        if fLastHand <> HAND_NONE then
                        begin
                          UT := UNIT_ID_TO_TYPE[P[0]];

                          if UT in [HUMANS_MIN..HUMANS_MAX] then
                          begin
                            //Militia is a special case, because it could be trained in 2 diff houses
                            if (UT = utMilitia) and (P[1] = 1) then // if P[1] = 1, then its TownHall
                              gHands[fLastHand].Locks.SetUnitBlocked(True, UT, True)
                            else
                              gHands[fLastHand].Locks.SetUnitBlocked(True, UT);
                          end;
                        end;

    ctBlockHouse:       if fLastHand <> HAND_NONE then
                        begin
                          if InRange(P[0], Low(HOUSE_ID_TO_TYPE), High(HOUSE_ID_TO_TYPE)) then
                            gHands[fLastHand].Locks.HouseLock[HOUSE_ID_TO_TYPE[P[0]]] := hlBlocked;
                        end;

    ctReleaseHouse:     if fLastHand <> HAND_NONE then
                        begin
                          if InRange(P[0], Low(HOUSE_ID_TO_TYPE), High(HOUSE_ID_TO_TYPE)) then
                            gHands[fLastHand].Locks.HouseLock[HOUSE_ID_TO_TYPE[P[0]]] := hlGranted;
                        end;

    ctReleaseAllHouses: if fLastHand <> HAND_NONE then
                          for HT := HOUSE_MIN to HOUSE_MAX do
                            gHands[fLastHand].Locks.HouseLock[HT] := hlGranted;

    ctSetGroup:         if (fLastHand <> HAND_NONE) and PointInMap(P[1]+1, P[2]+1) then
                          if InRange(P[0], Low(UNIT_ID_TO_TYPE), High(UNIT_ID_TO_TYPE)) and (UNIT_ID_TO_TYPE[P[0]] <> utNone) then
                          try
                            fLastTroop := gHands[fLastHand].AddUnitGroup(
                              UNIT_ID_TO_TYPE[P[0]],
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

    ctSendGroup:        if (fLastHand <> HAND_NONE) and PointInMap(P[0]+1, P[1]+1) then
                        begin
                          if fLastTroop <> nil then
                            if fParsingMode = mpmEditor then
                            begin
                              fLastTroop.MapEdOrder.Order := gioSendGroup;
                              fLastTroop.MapEdOrder.Pos := KMPointDir(P[0]+1, P[1]+1, TKMDirection(P[2]+1));
                            end
                            else
                            begin
                              groupOrder.Group := fLastTroop;
                              groupOrder.Kind := gioSendGroup;
                              groupOrder.Target := KMPoint(P[0]+1,P[1]+1);
                              groupOrder.Dir := TKMDirection(P[2]+1);
                              fGroupOrders.Add(groupOrder);
                            end
                          else
                            AddError('ct_SendGroup without prior declaration of Troop');
                        end;

    ctSetGroupFood:     if fLastHand <> HAND_NONE then
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

    ctAICharacter:      if fLastHand <> HAND_NONE then
                        begin
                          if gHands[fLastHand].HandType <> hndComputer then
                            //@Rey we exited here, leading to FatalError.
                            Assert(False, 'ctAICharacter gHands[fLastHand].HandType <> hndComputer');

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
                            iPlayerAI.General.DefencePositions.TroopFormations[TKMGroupType(GROUP_TYPE_MIN_OFF + P[1])].NumUnits := P[2];
                            iPlayerAI.General.DefencePositions.TroopFormations[TKMGroupType(GROUP_TYPE_MIN_OFF + P[1])].UnitsPerRow  := P[3];
                          end;
                        end;

    ctAINoBuild:        if fLastHand <> HAND_NONE then
                          gHands[fLastHand].AI.Setup.AutoBuild := False;

    ctAIAutoRepair:     if fLastHand <> HAND_NONE then
                          gHands[fLastHand].AI.Setup.RepairMode := rmRepairAlways;

    ctAIAutoAttack:     if fLastHand <> HAND_NONE then
                          gHands[fLastHand].AI.Setup.AutoAttack := True;

    ctAIAutoDefend:     if fLastHand <> HAND_NONE then
                          gHands[fLastHand].AI.Setup.AutoDefend := True;

    ctAIDefendAllies:   if fLastHand <> HAND_NONE then
                          gHands[fLastHand].AI.Setup.DefendAllies := True;

    ctAIUnlimitedEquip: if fLastHand <> HAND_NONE then
                          gHands[fLastHand].AI.Setup.UnlimitedEquip := True;

    ctAIArmyType:       if (fLastHand <> HAND_NONE) and (P[0] >= Byte(Low(TKMArmyType))) and (P[0] <= Byte(High(TKMArmyType))) then
                          gHands[fLastHand].AI.Setup.ArmyType := TKMArmyType(P[0]);

    ctAIStartPosition:  if (fLastHand <> HAND_NONE) and PointInMap(P[0]+1, P[1]+1) then
                          gHands[fLastHand].AI.Setup.StartPosition := KMPoint(P[0]+1,P[1]+1);

    ctSetAlliance:      if (fLastHand <> HAND_NONE) and fPlayerEnabled[P[0]] and (P[0] <> fLastHand) then
                          if P[1] = 1 then
                            gHands[fLastHand].Alliances[P[0]] := atAlly
                          else
                            gHands[fLastHand].Alliances[P[0]] := atEnemy;

    ctAttackPosition:   if (fLastHand <> HAND_NONE) and PointInMap(P[0]+1, P[1]+1) then
                          //If target is building: Attack building
                          //If target is unit: Chase/attack unit
                          //If target is nothing: move to position
                          //However, because the unit/house target may not have been created yet, this must be processed after everything else
                          if fLastTroop <> nil then
                            if fParsingMode = mpmEditor then
                            begin
                              fLastTroop.MapEdOrder.Order := gioAttackPosition;
                              fLastTroop.MapEdOrder.Pos := KMPointDir(P[0]+1, P[1]+1, dirNA);
                            end
                            else
                            begin
                              groupOrder.Group := fLastTroop;
                              groupOrder.Kind := gioAttackPosition;
                              groupOrder.Target := KMPoint(P[0]+1,P[1]+1);
                              groupOrder.Dir := dirNA;
                              fGroupOrders.Add(groupOrder);
                            end
                          else
                            AddError('ct_AttackPosition without prior declaration of Troop');

    ctAddGoal:          //ADD_GOAL, condition, status, message_id, player_id,
                        if fLastHand <> HAND_NONE then
                        begin
                          if not InRange(P[0], 0, Byte(High(TKMGoalCondition))) then
                            AddError('Add_Goal with unknown condition index ' + IntToStr(P[0]))
                          else
                            if not (TKMGoalCondition(P[0]) in GOALS_SUPPORTED) then
                              AddError('Goal type ' + GOAL_CONDITION_STR[TKMGoalCondition(P[0])] + ' is deprecated')
                            else
                              if (P[2] <> 0) then
                                AddError('Goals messages are deprecated. Use .script instead')
                              else
                                if InRange(P[3], 0, gHands.Count - 1) and fPlayerEnabled[P[3]] then
                                  gHands[fLastHand].AI.Goals.AddGoal(gltVictory, TKMGoalCondition(P[0]), P[3]); //Ignore not used parameters
                        end;

    ctAddLostGoal:      if fLastHand <> HAND_NONE then
                        begin
                          if not InRange(P[0], 0, Byte(High(TKMGoalCondition))) then
                            AddError('Add_LostGoal with unknown condition index ' + IntToStr(P[0]))
                          else
                          if InRange(P[3], 0, gHands.Count - 1)
                          and fPlayerEnabled[P[3]] then
                          begin
                            if not (TKMGoalCondition(P[0]) in GOALS_SUPPORTED) then
                              AddError('LostGoal type ' + GOAL_CONDITION_STR[TKMGoalCondition(P[0])] + ' is deprecated');
                            if (P[2] <> 0) then
                              AddError('LostGoals messages are deprecated. Use .script instead');
                            gHands[fLastHand].AI.Goals.AddGoal(gltSurvive, TKMGoalCondition(P[0]), P[3]); //Ignore not used parameters
                          end;
                        end;

    ctAIDefence:        if (fLastHand <> HAND_NONE) and PointInMap(P[0]+1, P[1]+1) then
                          if InRange(P[3], Integer(GROUP_TYPE_MIN) - GROUP_TYPE_MIN_OFF, Integer(GROUP_TYPE_MAX) - GROUP_TYPE_MIN_OFF) then //TPR 3 tries to set TKMGroupType 240 due to a missing space
                            gHands[fLastHand].AI.General.DefencePositions.Add(KMPointDir(P[0]+1, P[1]+1, TKMDirection(P[2]+1)),TKMGroupType(GROUP_TYPE_MIN_OFF + P[3]),P[4],TKMAIDefencePosType(P[5]));

    ctSetMapColor:      if fLastHand <> HAND_NONE then
                          //For now simply use the minimap color for all color, it is too hard to load all 8 shades from ctSetNewRemap
                          gHands[fLastHand].FlagColor := gRes.Palettes.DefaultPalette.Color32(P[0]);

    ctSetRGBColor:      if fLastHand <> HAND_NONE then
                          gHands[fLastHand].FlagColor := P[0] or $FF000000;

    ctAIAttack:         if fLastHand <> HAND_NONE then
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
                            fAIAttack.GroupAmounts[TKMGroupType(GROUP_TYPE_MIN_OFF + P[1])] := P[2];
                          if TextParam = AI_ATTACK_PARAMS[cptTarget] then
                            fAIAttack.Target := TKMAIAttackTarget(P[1]);
                          if TextParam = AI_ATTACK_PARAMS[cptPosition] then
                            fAIAttack.CustomPosition := KMPoint(P[1]+1,P[2]+1);
                          if TextParam = AI_ATTACK_PARAMS[cptTakeAll] then
                            fAIAttack.RandomGroups := True;
                        end;

    ctCopyAIAttack:     if fLastHand <> HAND_NONE then
                        begin
                          //Save the attack to the AI assets
                          gHands[fLastHand].AI.General.Attacks.AddAttack(fAIAttack);

                          //For KaM compatability we do NOT reset values before next Attack processing
                          //by default. In KaM values must be carried over since many missions rely on
                          //this. When we save AI attacks we use ctClearAIAttack to clear it manually
                          //FillChar(fAIAttack, SizeOf(fAIAttack), #0);
                        end;

    ctClearAIAttack:    if fLastHand <> HAND_NONE then
                          FillChar(fAIAttack, SizeOf(fAIAttack), #0);

    ctSetRallyPoint:    if (fLastHand <> HAND_NONE) and PointInMap(P[0]+1, P[1]+1) then
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

    ctEnablePlayer:     ;//Serves no real purpose, all players have this command anyway

    ctSetNewRemap:      ;//Disused. Minimap color is used for all colors now. However it might be better to use these values in the long run as sometimes the minimap colors do not match well
  end;
end;


//Write out a KaM format mission file to aFileName
procedure TKMMissionParserStandard.SaveDATFile(const aFileName: string;  aLeftInset: SmallInt = 0; aTopInset: SmallInt = 0; aDoXorEncoding: Boolean = False);
const
  COMMANDLAYERS = 4;
var
  I: longint; //longint because it is used for encoding entire output, which will limit the file size
  K, J, iX, iY, commandLayerCount: Integer;
  storeCount, barracksCount: Integer;
  WT: TKMWareType;
  G: TKMGroupType;
  U: TKMUnit;
  UT: TKMUnitType;
  H: TKMHouse;
  group: TKMUnitGroup;
  HT: TKMHouseType;
  releaseAllHouses: Boolean;
  saveString: AnsiString;
  saveStream: TFileStream;
  params: TIntegerArray;

  procedure AddData(const aText: AnsiString);
  begin
    if commandLayerCount = -1 then //No layering
      saveString := saveString + aText + EolA //Add to the string normally
    else
    begin
      case (commandLayerCount mod COMMANDLAYERS) of
        0:   saveString := saveString + EolA + aText //Put a line break every 4 commands
        else saveString := saveString + ' ' + aText; //Just put spaces so commands "layer"
      end;
      Inc(commandLayerCount);
    end
  end;

  procedure AddCommand(aCommand: TKMCommandType; aComParam: TKMCommandParamType; aParams: TIntegerArray); overload;
  var
    I: Integer;
    outData: AnsiString;
  begin
    outData := '!' + COMMANDVALUES[aCommand];

    if aComParam <> cptUnknown then
      outData := outData + ' ' + PARAMVALUES[aComParam];

    for I:=Low(aParams) to High(aParams) do
      outData := outData + ' ' + AnsiString(IntToStr(aParams[I]));

    AddData(outData);
  end;

  procedure AddCommand(aCommand: TKMCommandType; aComParam: TAIAttackParamType; aParams: TIntegerArray); overload;
  var
    I: Integer;
    outData: AnsiString;
  begin
    outData := '!' + COMMANDVALUES[aCommand] + ' ' + AI_ATTACK_PARAMS[aComParam];

    for I:=Low(aParams) to High(aParams) do
      outData := outData + ' ' + AnsiString(IntToStr(aParams[I]));

    AddData(outData);
  end;

  procedure AddCommand(aCommand: TKMCommandType; aParams: TIntegerArray); overload;
  begin
    AddCommand(aCommand, cptUnknown, aParams);
  end;

begin
  //Put data into stream
  saveString := '';
  commandLayerCount := -1; //Some commands (road/fields) are layered so the file is easier to read (not so many lines)

  //Main header, use same filename for MAP
  //We will probably discontinue KAM format,
  //if mapmaker wants to use MapEd for KaM he needs to update/change other things too
  //however without this line old KMR versions just refuse to load, so we keep it
  AddData('!' + COMMANDVALUES[ctSetMap] + ' "data\mission\smaps\' +
    AnsiString(ChangeFileExt(ExtractFileName(aFileName), '.map')) + '"');

  if gGameParams.IsTactic then AddCommand(ctSetTactic, []);
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

    // Save center screen
    if not KMSamePoint(gHands[I].CenterScreen, KMPOINT_ZERO) then
      AddCommand(ctCenterScreen, [gHands[I].CenterScreen.X - 1 + aLeftInset, gHands[I].CenterScreen.Y - 1 + aTopInset]);

    // Choose loc configuration
    with gHands[I].ChooseLocation do
      if Allowed then
      begin
        // Allow loc configuration
        AddCommand(ctChooseLoc, [1]);
        // Add resources
        for WT := Low(Resources) to High(Resources) do
          if (Resources[WT] > 0) then
            AddCommand(ctChooseLocAddWare, [WARE_TY_TO_ID[WT], Resources[WT]]);
        // Add units
        for UT := Low(Units) to High(Units) do
          if (Units[UT] > 0) then
            AddCommand(ctChooseLocAddUnit, [UNIT_TYPE_TO_ID[UT], Units[UT]]);
      end;

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
    if gHands[I].AI.Setup.IsRepairAlways then AddCommand(ctAIAutoRepair, []);
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
    for G := GROUP_TYPE_MIN to GROUP_TYPE_MAX do
      if gHands[I].AI.General.DefencePositions.TroopFormations[G].NumUnits <> 0 then //Must be valid and used
        AddCommand(ctAICharacter, cptTroopParam, [GROUP_TYPES[G],
                                                  gHands[I].AI.General.DefencePositions.TroopFormations[G].NumUnits,
                                                  gHands[I].AI.General.DefencePositions.TroopFormations[G].UnitsPerRow]);
    AddData(''); //NL
    for K := 0 to gHands[I].AI.General.DefencePositions.Count - 1 do
      with gHands[I].AI.General.DefencePositions[K] do
        AddCommand(ctAIDefence, [Position.Loc.X - 1 + aLeftInset,
                                  Position.Loc.Y - 1 + aTopInset,
                                  Byte(Position.Dir) - 1,
                                  GROUP_TYPES[GroupType],
                                  Radius,
                                  Byte(DefenceType)]);
    AddData(''); //NL
    AddData(''); //NL
    for K := 0 to gHands[I].AI.General.Attacks.Count - 1 do
      with gHands[I].AI.General.Attacks[K] do
      begin
        AddCommand(ctAIAttack, cptType, [KaMAttackType[AttackType]]);
        AddCommand(ctAIAttack, cptTotalAmount, [TotalMen]);
        if RandomGroups then
          AddCommand(ctAIAttack, cptTakeAll, [])
        else
          for G := GROUP_TYPE_MIN to GROUP_TYPE_MAX do
            AddCommand(ctAIAttack, cptTroopAmount, [GROUP_TYPES[G], GroupAmounts[G]]);

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
    releaseAllHouses := True;
    for HT := HOUSE_MIN to HOUSE_MAX do
    begin
      if gHands[I].Locks.HouseBlocked[HT] then
      begin
        AddCommand(ctBlockHouse, [HOUSE_TYPE_TO_ID[HT]-1]);
        releaseAllHouses := False;
      end
      else
        if gHands[I].Locks.HouseGranted[HT] then
          AddCommand(ctReleaseHouse, [HOUSE_TYPE_TO_ID[HT]-1])
        else
          releaseAllHouses := False;
    end;
    if releaseAllHouses then
      AddCommand(ctReleaseAllHouses, []);

    //Block units
    for UT := HUMANS_MIN to HUMANS_MAX do
    begin
      if (UT = utMilitia) and gHands[I].Locks.GetUnitBlocked(UT, True) then
        AddCommand(ctBlockUnit, [UNIT_TYPE_TO_ID[UT], 1]); // 1 - special case for militia in TownHall

      if gHands[I].Locks.GetUnitBlocked(UT) then
        AddCommand(ctBlockUnit, [UNIT_TYPE_TO_ID[UT], 0]); // means default
    end;

    //Block trades
    for WT := WARE_MIN to WARE_MAX do
      if not gHands[I].Locks.AllowToTrade[WT] then
        AddCommand(ctBlockTrade, [WARE_TY_TO_ID[WT]]);

    //Houses
    storeCount := 0;
    barracksCount := 0;
    for K := 0 to gHands[I].Houses.Count - 1 do
    begin
      H := gHands[I].Houses[K];
      if not H.IsDestroyed then
      begin
        AddCommand(ctSetHouse, [HOUSE_TYPE_TO_ID[H.HouseType]-1, H.Position.X-1 + aLeftInset, H.Position.Y-1 + aTopInset]);
        if H.IsDamaged then
          AddCommand(ctSetHouseDamage, [H.GetDamage]);

        if H.BuildingRepair then // Repair mode is turned off by default
          AddCommand(ctSetHouseRepairMode, []);

        if H.IsClosedForWorker then
          AddCommand(ctSetHouseClosedForWorker, []);

        if H is TKMHouseBarracks then
        begin
          for J := 1 to TKMHouseBarracks(H).MapEdRecruitCount do
            AddCommand(ctUnitAddToLast, [UNIT_TYPE_TO_OLD_ID[utRecruit]]);
        end;

        if (H is TKMHouseWFlagPoint)
          and TKMHouseWFlagPoint(H).IsFlagPointSet then
          AddCommand(ctSetRallyPoint, [TKMHouseWFlagPoint(H).FlagPoint.X-1 + aLeftInset, TKMHouseWFlagPoint(H).FlagPoint.Y-1 + aTopInset]);

        //Process any wares in this house
        for WT := WARE_MIN to WARE_MAX do
        begin
          if H.CheckWareIn(WT) > 0 then
            AddCommand(ctAddWareToLast, [WARE_TY_TO_ID[WT], H.CheckWareIn(WT)]);
          if H.CheckWareOut(WT) > 0 then
            AddCommand(ctAddWareToLast, [WARE_TY_TO_ID[WT], H.CheckWareOut(WT)]);
        end;

        //Set Delivery mode after Wares, so in case there are some wares and delivery mode TakeOut, then we will need to add proper Offers
        if H.DeliveryMode <> dmDelivery then //Default delivery mode is dmDelivery
          AddCommand(ctSetHouseDeliveryMode, [Ord(H.DeliveryMode)]);
      end;
    end;
    AddData(''); //NL

    //Roads and fields. We must check EVERY terrain tile
    commandLayerCount := 0; //Enable command layering
    for iY := 1 to gTerrain.MapY do
      for iX := 1 to gTerrain.MapX do
        if gTerrain.Land^[iY,iX].TileOwner = gHands[I].ID then
        begin
          if gTerrain.Land^[iY,iX].TileOverlay = toRoad then
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
    commandLayerCount := -1; //Disable command layering
    AddData(''); //Extra NL because command layering doesn't put one
    AddData(''); //NL

    //Units
    for K := 0 to gHands[I].Units.Count - 1 do
    begin
      U := gHands[I].Units[K];
      if not (U is TKMUnitWarrior) then //Groups get saved separately
      begin
        AddCommand(ctSetUnit, [UNIT_TYPE_TO_OLD_ID[U.UnitType], U.Position.X-1 + aLeftInset, U.Position.Y-1 + aTopInset]);
        if not U.StartWDefaultCondition then
          AddCommand(ctSetUnitFood, [U.Condition]);
      end;
    end;

    //Unit groups
    for K := 0 to gHands[I].UnitGroups.Count - 1 do
    begin
      group := gHands[I].UnitGroups[K];
      AddCommand(ctSetGroup, [UNIT_TYPE_TO_ID[group.UnitType], group.Position.X-1 + aLeftInset, group.Position.Y-1 + aTopInset, Byte(group.Direction)-1, group.UnitsPerRow, group.MapEdCount]);
      if not group.FlagBearer.StartWDefaultCondition then
        AddCommand(ctSetGroupFood, [group.FlagBearer.Condition]);

      case group.MapEdOrder.Order of
        gioNoOrder: ;
        gioSendGroup:
          AddCommand(ctSendGroup, [group.MapEdOrder.Pos.Loc.X-1 + aLeftInset, group.MapEdOrder.Pos.Loc.Y-1 + aTopInset, Byte(group.MapEdOrder.Pos.Dir)-1]);
        gioAttackPosition:
          AddCommand(ctAttackPosition, [group.MapEdOrder.Pos.Loc.X-1 + aLeftInset, group.MapEdOrder.Pos.Loc.Y-1 + aTopInset]);
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
    SetLength(params, 3);
    params[0] := UNIT_TYPE_TO_OLD_ID[U.UnitType];
    params[1] := U.Position.X - 1 + aLeftInset;
    params[2] := U.Position.Y - 1 + aTopInset;

    // Also save fish count to dat
    if U is TKMUnitFish then
    begin
      SetLength(params, 4);
      params[3] := TKMUnitFish(U).FishCount;
    end;

    AddCommand(ctSetUnit, params);
  end;
  AddData(''); //NL

  //Similar footer to one in Lewin's Editor, useful so ppl know what mission was made with.
  AddData('//This mission was made with KaM Remake Map Editor version ' + GAME_VERSION + ' at ' + AnsiString(DateTimeToStr(Now)));


  if aDoXorEncoding then
  begin
    //Write uncoded file for debug
    saveStream := TFileStream.Create(aFileName+'.txt', fmCreate);
    saveStream.WriteBuffer(saveString[1], Length(saveString));
    saveStream.Free;

    //Encode file
    for I := 1 to Length(saveString) do
      saveString[I] := AnsiChar(Byte(saveString[I]) xor 239);
  end;

  saveStream := TFileStream.Create(aFileName, fmCreate);
  saveStream.WriteBuffer(saveString[1], Length(saveString));
  saveStream.Free;
end;


end.

