{
Artificial intelligence
@author: Martin Toupal
@e-mail: poznamenany@gmail.com
}
unit KM_ArmyManagement;
{$I KaM_Remake.inc}
interface
uses
  Classes, KromUtils, Math, SysUtils,
  KM_CommonClasses, KM_Defaults, KM_Points,
  KM_Houses, KM_Units,
  KM_UnitGroup, KM_AISetup, KM_ResTypes,
  KM_HandStats, KM_ArmyDefence, KM_AIAttacks, KM_ArmyAttackNew;

const
  ARMY_VECTOR_SCAN_HOUSES_DEF: TKMHouseTypeSet = [htBarracks, htStore, htSchool, htTownhall]; // htWatchTower

type
  // Agent interface (for Supervisor)
  TKMAttackRequest = record
    Active, FoodShortage, FFA: Boolean;
    BestAllianceCmp,WorstAllianceCmp: Single;
    BestEnemy: TKMHandID; // or index of Enemies array
    Enemies: TKMHandIDArray;
  end;

  TKMArmyManagement = class
  private
    fOwner: TKMHandID;
    fSetup: TKMHandAISetup;
    fFoodProblems: Boolean;
    fLastEquippedTimeIron, fLastEquippedTimeLeather: Cardinal;
    fAttackRequest: TKMAttackRequest;
    fArmyVectorFieldScanHouses: TKMHouseTypeSet;

    fAttackNew: TKMArmyAttackNew;
    fDefence: TKMArmyDefence;

    fBalanceText: UnicodeString;

    procedure RecruitSoldiers;
    procedure CheckGroupsState;
    procedure CheckAttack;
    procedure SetAttackRequest(aAttackRequest: TKMAttackRequest);

    function CombineBalanceStrings: UnicodeString;
  public
    constructor Create(aPlayer: TKMHandID; aSetup: TKMHandAISetup);
    destructor Destroy; override;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad;

    property AttackNew: TKMArmyAttackNew read fAttackNew;
    property Defence: TKMArmyDefence read fDefence write fDefence;
    property AttackRequest: TKMAttackRequest read fAttackRequest write SetAttackRequest;
    property BalanceText: UnicodeString read CombineBalanceStrings;

    property ArmyVectorFieldScanHouses: TKMHouseTypeSet read fArmyVectorFieldScanHouses write fArmyVectorFieldScanHouses;

    procedure AfterMissionInit;
    procedure UpdateState(aTick: Cardinal);
    procedure OwnerUpdate(aPlayer: TKMHandID);
    procedure WarriorEquipped(aGroup: TKMUnitGroup);

    procedure Paint;
  end;


implementation
uses
  KM_Game, KM_GameParams,
  KM_Hand, KM_HandsCollection, KM_HandTypes, KM_HandEntity,
  KM_Terrain,
  KM_HouseBarracks,
  KM_CommonUtils,
  KM_DevPerfLog, KM_DevPerfLogTypes,
  KM_AITypes, KM_AIFields,
  KM_MapTypes;


{ TKMArmyManagement }
constructor TKMArmyManagement.Create(aPlayer: TKMHandID; aSetup: TKMHandAISetup);
begin
  inherited Create;

  fOwner := aPlayer;
  fSetup := aSetup;
  fFoodProblems := False;
  fLastEquippedTimeIron := 0;
  fLastEquippedTimeLeather := 0;
  fArmyVectorFieldScanHouses := ARMY_VECTOR_SCAN_HOUSES_DEF;
  fAttackRequest.Active := False;

  fAttackNew := TKMArmyAttackNew.Create(aPlayer);
  fDefence := TKMArmyDefence.Create(aPlayer);
end;


destructor TKMArmyManagement.Destroy;
begin
  fAttackNew.Free;
  fDefence.Free;

  inherited;
end;


procedure TKMArmyManagement.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.PlaceMarker('ArmyManagement');
  SaveStream.Write(fOwner);
  SaveStream.Write(fFoodProblems);
  SaveStream.Write(fLastEquippedTimeIron);
  SaveStream.Write(fLastEquippedTimeLeather);
  SaveStream.Write(fArmyVectorFieldScanHouses, SizeOf(fArmyVectorFieldScanHouses));

  with fAttackRequest do
  begin
    SaveStream.Write(Active);
    SaveStream.Write(FoodShortage);
    SaveStream.Write(FFA);
    SaveStream.Write(BestAllianceCmp);
    SaveStream.Write(WorstAllianceCmp);
    SaveStream.Write(BestEnemy);
    SaveStream.Write( Integer(Length(Enemies)) );
    if (Length(Enemies) > 0) then
      SaveStream.Write(Enemies[0], SizeOf(Enemies[0])*Length(Enemies));
  end;

  fAttackNew.Save(SaveStream);
  fDefence.Save(SaveStream);
end;


procedure TKMArmyManagement.Load(LoadStream: TKMemoryStream);
var
  Count: Integer;
begin
  LoadStream.CheckMarker('ArmyManagement');
  LoadStream.Read(fOwner);
  LoadStream.Read(fFoodProblems);
  LoadStream.Read(fLastEquippedTimeIron);
  LoadStream.Read(fLastEquippedTimeLeather);
  LoadStream.Read(fArmyVectorFieldScanHouses, SizeOf(fArmyVectorFieldScanHouses));

  with fAttackRequest do
  begin
    LoadStream.Read(Active);
    LoadStream.Read(FoodShortage);
    LoadStream.Read(FFA);
    LoadStream.Read(BestAllianceCmp);
    LoadStream.Read(WorstAllianceCmp);
    LoadStream.Read(BestEnemy);
    LoadStream.Read(Count);
    SetLength(Enemies,Count);
    if (Length(Enemies) > 0) then
      LoadStream.Read(Enemies[0], SizeOf(Enemies[0])*Length(Enemies));
  end;

  fAttackNew.Load(LoadStream);
  fDefence.Load(LoadStream);
end;


procedure TKMArmyManagement.SyncLoad;
begin
  fAttackNew.SyncLoad;
  fDefence.SyncLoad;
end;


procedure TKMArmyManagement.AfterMissionInit;
begin
  fAttackNew.AfterMissionInit;
  fDefence.AfterMissionInit;
end;


procedure TKMArmyManagement.OwnerUpdate(aPlayer: TKMHandID);
begin
  fOwner := aPlayer;
  fAttackNew.OwnerUpdate(aPlayer);
  fDefence.OwnerUpdate(aPlayer);
end;


procedure TKMArmyManagement.WarriorEquipped(aGroup: TKMUnitGroup);
begin
  //if (gAIFields.Supervisor.CombatStatus[fOwner,fOwner] = csDefending) AND (fDefence.GroupsCount = 0) AND (fAttackNew.Count > 0) then
  if (fDefence.GroupsCount = 0) AND (fAttackNew.Count > 0) AND not fFoodProblems then
    fAttackNew.LinkGroup(aGroup);
  if (aGroup.Count > 0) then
    fDefence.FindPlaceForGroup(aGroup);
end;


procedure TKMArmyManagement.RecruitSoldiers;
  function CanEquipIron: Boolean;
  begin
    Result := not (fSetup.ArmyType = atLeather)
              and (fSetup.UnlimitedEquip or gGame.CheckTime(fLastEquippedTimeIron + fSetup.EquipRateIron));
  end;
  function CanEquipLeather: Boolean;
  begin
    Result := not (fSetup.ArmyType = atIron)
              and (fSetup.UnlimitedEquip or gGame.CheckTime(fLastEquippedTimeLeather + fSetup.EquipRateLeather));
  end;
var
  H: TKMHouse;
  GT: TKMGroupType;
  K,L: Integer;
  UT: TKMUnitType;
  pEquippedTime: ^Cardinal;
  GroupReq: TKMGroupTypeArray;
  Barracks: array of TKMHouseBarracks;
begin
  // Peace time; Max soldiers limit reached; cannot equip; no Barracks
  if gGame.IsPeaceTime
  or ((fSetup.MaxSoldiers <> -1) and (gHands[fOwner].Stats.GetArmyCount >= fSetup.MaxSoldiers))
  or (not CanEquipIron and not CanEquipLeather)
  or (gHands[fOwner].Stats.GetHouseQty(htBarracks) = 0)
  or (fDefence.Count = 0) then
    Exit;

  // Take required warriors from CityManagement (-> implemented consideration of required units + save time)
  FillChar(GroupReq, SizeOf(GroupReq), #0); //Clear up
  for GT := GROUP_TYPE_MIN to GROUP_TYPE_MAX do
    for K := Low(AI_TROOP_TRAIN_ORDER[GT]) to High(AI_TROOP_TRAIN_ORDER[GT]) do
      if (AI_TROOP_TRAIN_ORDER[GT,K] <> utNone) then
        Inc(GroupReq[GT], gHands[fOwner].AI.CityManagement.WarriorsDemands[ AI_TROOP_TRAIN_ORDER[GT,K] ] + 1); // Always recruit something

  // Find barracks
  SetLength(Barracks, gHands[fOwner].Stats.GetHouseQty(htBarracks));
  for K := 0 to Length(Barracks) - 1 do
    Barracks[K] := nil; // Just to be sure
  L := 0;
  for K := 0 to gHands[fOwner].Houses.Count - 1 do
  begin
    H := gHands[fOwner].Houses[K];
    if (H <> nil) AND not H.IsDestroyed AND (H.HouseType = htBarracks) AND H.IsComplete then
    begin
      Barracks[L] := TKMHouseBarracks(H);
      Inc(L);
    end;
  end;

  // Train troops where possible in each barracks
  for K := Low(Barracks) to High(Barracks) do
    if (Barracks[K] <> nil) then
    begin
      // Chose a random group type that we are going to attempt to train (so we don't always train certain group types first)
      L := 0;
      repeat
        GT := TKMGroupType(GROUP_TYPE_MIN_OFF + KaMRandom(4{$IFDEF DBG_RNG_SPY}, 'TKMArmyManagement.RecruitSoldiers'{$ENDIF})); //Pick random from overall count
        Inc(L);
      until (GroupReq[GT] > 0) or (L > 9); // Limit number of attempts to guarantee it doesn't loop forever

      if (GroupReq[GT] = 0) then
        Continue; // Don't train

      for L := Low(AI_TROOP_TRAIN_ORDER[GT]) to High(AI_TROOP_TRAIN_ORDER[GT]) do
      begin
        UT := AI_TROOP_TRAIN_ORDER[GT, L];
        if (UT <> utNone) then
        begin
          if CanEquipIron and (UT in WARRIORS_IRON) then
            pEquippedTime := @fLastEquippedTimeIron
          else
          if CanEquipLeather and not (UT in WARRIORS_IRON) then
            pEquippedTime := @fLastEquippedTimeLeather
          else
            Continue;

          while Barracks[K].CanEquip(UT)
          and (GroupReq[GT] > 0)
          and ((fSetup.MaxSoldiers = -1) or (gHands[fOwner].Stats.GetArmyCount < fSetup.MaxSoldiers)) do
          begin
            Barracks[K].Equip(UT, 1);
            Dec(GroupReq[GT]);
            pEquippedTime^ := gGameParams.Tick; // Only reset it when we actually trained something (in IronThenLeather mode we don't count them separately)
          end;
        end;
      end;
    end;
end;


//Check army food level and positioning
procedure TKMArmyManagement.CheckGroupsState;
var
  K: Integer;
  Group: TKMUnitGroup;
begin
  // Update food level
  fFoodProblems := gAIFields.Eye.ArmyEvaluation.CheckFoodProblems([fOwner]);

  // Feed army and find unused groups
  for K := 0 to gHands[fOwner].UnitGroups.Count - 1 do
  begin
    Group := gHands[fOwner].UnitGroups[K];

    if (Group <> nil) AND not Group.IsDead AND not Group.InFight then
    begin
      // Check hunger and order food
      if (Group.Condition < UNIT_MIN_CONDITION) AND not fFoodProblems then
        // Cheat for autobuild AI: Only feed hungry group members (food consumption lower and more predictable)
        Group.OrderFood(True, fSetup.AutoBuild);

      // Do not process attack or defence during peacetime
      if gGame.IsPeaceTime then
        Continue;

      // Group is in combat classes
      if fAttackNew.IsGroupInAction(Group) then
        Continue;

      // Group is in defence position
      if (fDefence.FindPositionOf(Group) <> nil) then
        Continue;

    if (fDefence.GroupsCount = 0) AND (fAttackNew.Count > 0) then
      fAttackNew.LinkGroup(Group);

      if (Group.Count > 0) then
        fDefence.FindPlaceForGroup(Group);
    end;
  end;
end;


procedure TKMArmyManagement.CheckAttack;
type
  TKMAvailableGroups = record
    Count: Word;
    GroupsAvailable: TKMGroupTypeArray;
    MenAvailable: TKMGroupTypeArray;
    GroupArr: TKMUnitGroupArray;
  end;
  // Find all available groups
  function GetGroups(aMobilizationCoef: Single): TKMAvailableGroups;
  const
    MIN_TROOPS_IN_GROUP = 4;
  var
    K: Integer;
    Group: TKMUnitGroup;
    AG: TKMAvailableGroups;
    DP: TKMDefencePosition;
  begin
    AG.Count := 0;
    SetLength(AG.GroupArr, gHands[fOwner].UnitGroups.Count);
    for K := 0 to gHands[fOwner].UnitGroups.Count - 1 do
    begin
      Group := gHands[fOwner].UnitGroups[K];
      if (Group = nil)
        OR Group.IsDead
        //OR not Group.IsIdleToAI([wtokFlagPoint, wtokHaltOrder])
        OR ((aMobilizationCoef < 1) AND (Group.Count < MIN_TROOPS_IN_GROUP)) then
        Continue;
      // Add grop pointer to array (but dont increase count now so it will be ignored)
      AG.GroupArr[AG.Count] := Group;
      // Check if group can be in array
      if (aMobilizationCoef = 1) then
      begin
        // Take all groups out of attack class
        if not fAttackNew.IsGroupInAction(Group) then
          Inc(AG.Count,1); // Confirm that the group should be in array GroupArr
      end
      else
      begin
        // Take group in defence position if it is required by mobilization
        DP := fDefence.FindPositionOf(Group, KaMRandom({$IFDEF DBG_RNG_SPY}'TKMArmyManagement.RecruitSoldiers'{$ENDIF}) < aMobilizationCoef ); // True = First line will not be considered
        if (DP <> nil) then
          Inc(AG.Count,1); // Confirm that the group should be in array GroupArr
      end;
    end;
    FillChar(AG.GroupsAvailable, SizeOf(AG.GroupsAvailable), #0);
    FillChar(AG.MenAvailable, SizeOf(AG.MenAvailable), #0);
    for K := 0 to AG.Count - 1 do
    begin
      Group := AG.GroupArr[K];
      Inc(AG.GroupsAvailable[ Group.GroupType ]);
      Inc(AG.MenAvailable[ Group.GroupType ],Group.Count);
    end;
    Result := AG;
  end;
  // Filter groups
  procedure FilterGroups(aTotalMen: Integer; aGroupAmounts: TKMGroupTypeArray; var aAG: TKMAvailableGroups);
  var
    GCnt, MenCnt, StartIdx, ActIdx: Integer;
    G: TKMUnitGroup;
    GT: TKMGroupType;
  begin
    if (aTotalMen = 0) then
      Exit;
    // Select the right number of groups
    StartIdx := 0;
    MenCnt := 0;
    for GT := GROUP_TYPE_MIN to GROUP_TYPE_MAX do
    begin
      GCnt := aGroupAmounts[GT];
      ActIdx := StartIdx;
      while (GCnt > 0) AND (ActIdx < aAG.Count) do
      begin
        if (aAG.GroupArr[ActIdx].GroupType = GT) then
        begin
          G := aAG.GroupArr[StartIdx];
          aAG.GroupArr[StartIdx] := aAG.GroupArr[ActIdx];
          aAG.GroupArr[ActIdx] := G;
          Inc(MenCnt, aAG.GroupArr[ActIdx].Count);
          Inc(StartIdx);
          Dec(GCnt);
        end;
        Inc(ActIdx);
      end;
    end;
    // Add another groups if we dont have enough men
    while (MenCnt < aTotalMen) AND (ActIdx < aAG.Count) do
    begin
      Inc(MenCnt, aAG.GroupArr[ActIdx].Count);
      Inc(ActIdx);
    end;
    aAG.Count := ActIdx;
    SetLength(aAG.GroupArr, ActIdx);
  end;

  function FindScriptedTarget(aGroup: TKMUnitGroup; aTarget: TKMAIAttackTarget; aCustomPos: TKMPoint; var aTargetP: TKMPoint ): Boolean;
  var
    TargetHouse: TKMHouse;
    TargetUnit: TKMUnit;
  begin
    aTargetP := KMPOINT_ZERO;
    TargetHouse := nil;
    TargetUnit := nil;
    //Find target
    case aTarget of
      attClosestUnit:                  TargetUnit := gHands.GetClosestUnit(aGroup.Position, fOwner, atEnemy);
      attClosestBuildingFromArmy:      TargetHouse := gHands.GetClosestHouse(aGroup.Position, fOwner, atEnemy, TARGET_HOUSES, False);
      attClosestBuildingFromStartPos:  TargetHouse := gHands.GetClosestHouse(fSetup.StartPosition, fOwner, atEnemy, TARGET_HOUSES, False);
      attCustomPosition:
      begin
        TargetHouse := gHands.HousesHitTest(aCustomPos.X, aCustomPos.Y);
        if (TargetHouse <> nil) AND (gHands.CheckAlliance(fOwner, TargetHouse.Owner) = atAlly) then
          TargetHouse := nil;
        TargetUnit := gTerrain.UnitsHitTest(aCustomPos.X, aCustomPos.Y);
        if (TargetUnit <> nil) AND ((gHands.CheckAlliance(fOwner, TargetUnit.Owner) = atAlly) OR TargetUnit.IsDeadOrDying) then
          TargetUnit := nil;
      end;
    end;
    //Choose best option
    if (TargetHouse <> nil) then
      aTargetP := TargetHouse.Position
    else if (TargetUnit <> nil) then
      aTargetP := TargetUnit.Position
    else if (aTarget = attCustomPosition) then
      aTargetP := aCustomPos;
    Result := not KMSamePoint(aTargetP, KMPOINT_ZERO);
  end;

  // Order attack by releasing Defensive groups and creating Combat groups
  procedure OrderAttack(aTargetPoint: TKMPoint; var aAG: TKMAvailableGroups);
  var
    K: Integer;
  begin
    for K := 0 to aAG.Count - 1 do
      fDefence.ReleaseGroup(aAG.GroupArr[K]);

    fAttackNew.AddGroups(aAG.GroupArr);
    //fAttackNew.AddGroups( fDefence.ReleaseAllGroups );
  end;
const
  MIN_DEF_RATIO = 1.2;
  ATT_ADVANTAGE = 0.2;
  MIN_BEST_ALLI_CMP = 0.8;
  MIN_WORST_ALLI_CMP = 0.5;
  MIN_GROUPS_IN_ATTACK = 4;
var
  K: Integer;
  DefRatio, MobilizationCoef: Single;
  TargetPoint: TKMPoint;
  AG: TKMAvailableGroups;
begin
  if fAttackRequest.Active then
  begin
    fAttackRequest.Active := False;
    // Check defences and comparison of strength
    DefRatio := fDefence.DefenceStatus;
    with fAttackRequest do
    begin
      // Exit if AI has NOT enough soldiers for defences in the FFA mode
      if FFA AND not FoodShortage AND (DefRatio < MIN_DEF_RATIO) AND (gGameParams.MissionMode <> mmFighting) then
        Exit;
      // 1v1 or special game mode
      if not FFA OR gGameParams.IsTactic then
        MobilizationCoef := 1
      // Else compute if it is necessary to mobilize the first defence line (or fraction)
      else
      begin
        // Relative def ratio
        DefRatio := Max( 0, (DefRatio - 1) / Max(1, DefRatio) ); // = <0,1); 0 = army is in the first line of def. pos.; 1 = army is in second lines
        // Mobilization of the first line  //  * (WorstAllianceCmp)
        MobilizationCoef := Min(1, (1+ATT_ADVANTAGE) / (1+BestAllianceCmp) ) * (1 - DefRatio);
      end;
    end;
    // Get array of pointers to available groups
    AG := GetGroups(MobilizationCoef);
    // If we dont have enough groups then exit (if we should take all check if there are already some combat groups)
    if (MobilizationCoef < 1) AND (AG.Count < MIN_GROUPS_IN_ATTACK) then
      Exit;
    // Order attack
    OrderAttack(TargetPoint, AG);
  end
  else if not fSetup.AutoAttack then
    with gHands[fOwner].AI.General do
    begin
      AG := GetGroups(1);
      for K := 0 to Attacks.Count - 1 do
        if Attacks.CanOccur(K, AG.MenAvailable, AG.GroupsAvailable, gGameParams.Tick) then //Check conditions are right
        begin
          FilterGroups(Attacks[K].TotalMen, Attacks[K].GroupAmounts, AG);
          if FindScriptedTarget(AG.GroupArr[0], Attacks[K].Target, Attacks[K].CustomPosition, TargetPoint) then
          begin
            OrderAttack(TargetPoint,AG);
            Attacks.HasOccured(K);
            break; // Just 1 attack in 1 tick
          end;
        end;
    end;
end;


procedure TKMArmyManagement.SetAttackRequest(aAttackRequest: TKMAttackRequest);
begin
  fAttackRequest.Active := aAttackRequest.Active;
  fAttackRequest.FFA := aAttackRequest.FFA;
  fAttackRequest.FoodShortage := aAttackRequest.FoodShortage;
  fAttackRequest.BestAllianceCmp := aAttackRequest.BestAllianceCmp;
  fAttackRequest.WorstAllianceCmp := aAttackRequest.WorstAllianceCmp;
  fAttackRequest.BestEnemy := aAttackRequest.BestEnemy;
  SetLength(fAttackRequest.Enemies, Length(aAttackRequest.Enemies) );
  Move(aAttackRequest.Enemies[0], fAttackRequest.Enemies[0], SizeOf(fAttackRequest.Enemies[0])*Length(fAttackRequest.Enemies));
end;


procedure TKMArmyManagement.UpdateState(aTick: Cardinal);
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psAIArmyAdv);
  {$ENDIF}
  try
    if (aTick mod MAX_HANDS = fOwner) then
    begin
      if not gGame.IsPeaceTime then
      begin
        CheckAttack;
        RecruitSoldiers;
      end;
      CheckGroupsState;
      fAttackNew.UpdateState(aTick);
      fDefence.UpdateState(aTick);
    end;
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psAIArmyAdv);
    {$ENDIF}
  end;
end;


function TKMArmyManagement.CombineBalanceStrings: UnicodeString;
begin
  Result := fBalanceText;
  fAttackNew.LogStatus(Result);
  fDefence.LogStatus(Result);
end;


procedure TKMArmyManagement.Paint;
begin
  fAttackNew.Paint;
  fDefence.Paint;
end;


end.
