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
  KM_UnitGroup, KM_AISetup,
  KM_HandStats, KM_ArmyDefence, KM_AIAttacks, KM_ArmyAttack, KM_ArmyAttackNew,
  KM_NavMeshInfluences;

type
  // Agent interface (for Supervisor)
  TKMAttackRequest = record
    Active, FoodShortage: Boolean;
    BestAllianceCmp,WorstAllianceCmp: Single;
    BestEnemy, WorstEnemy: TKMHandID; // or index of Enemies array
    BestPoint, WorstPoint: TKMPoint;
    Enemies: TKMHandIDArray;
  end;

  TKMArmyManagement = class
  private
    fOwner: TKMHandID;
    fSetup: TKMHandAISetup;
    fLastEquippedTimeIron, fLastEquippedTimeLeather: Cardinal;
    fAttackRequest: TKMAttackRequest;

    fAttack: TKMArmyAttack;
    fAttackNew: TKMArmyAttackNew;
    fDefence: TKMArmyDefence;

    fBalanceText: UnicodeString;

    procedure RecruitSoldiers();
    procedure CheckGroupsState();
    procedure CheckAttack();
    procedure SetAttackRequest(aAttackRequest: TKMAttackRequest);

    function CombineBalanceStrings(): UnicodeString;
  public
    constructor Create(aPlayer: TKMHandID; aSetup: TKMHandAISetup);
    destructor Destroy; override;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad();

    property Attack: TKMArmyAttack read fAttack write fAttack;
    property AttackNew: TKMArmyAttackNew read fAttackNew;
    property Defence: TKMArmyDefence read fDefence write fDefence;
    property AttackRequest: TKMAttackRequest read fAttackRequest write SetAttackRequest;
    property BalanceText: UnicodeString read CombineBalanceStrings;

    procedure AfterMissionInit();
    procedure UpdateState(aTick: Cardinal);
    procedure OwnerUpdate(aPlayer: TKMHandID);
    procedure WarriorEquipped(aGroup: TKMUnitGroup);

    procedure Paint();
  end;


implementation
uses
  KM_Game, KM_Hand, KM_HandsCollection, KM_Terrain, KM_AIFields,
  KM_HouseBarracks, KM_Supervisor,
  KM_ResHouses, KM_CommonUtils,
  KM_AIParameters, KM_DevPerfLog, KM_DevPerfLogTypes;


{ TKMArmyManagement }
constructor TKMArmyManagement.Create(aPlayer: TKMHandID; aSetup: TKMHandAISetup);
begin
  inherited Create;

  fOwner := aPlayer;
  fSetup := aSetup;

  fAttack := TKMArmyAttack.Create(aPlayer);
  fAttackNew := TKMArmyAttackNew.Create(aPlayer);
  fDefence := TKMArmyDefence.Create(aPlayer, fAttack);
end;


destructor TKMArmyManagement.Destroy();
begin
  fAttack.Free;
  fAttackNew.Free;
  fDefence.Free;

  inherited;
end;


procedure TKMArmyManagement.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.PlaceMarker('ArmyManagement');
  SaveStream.Write(fOwner);
  SaveStream.Write(fLastEquippedTimeIron);
  SaveStream.Write(fLastEquippedTimeLeather);

  with fAttackRequest do
  begin
    SaveStream.Write(Active);
    SaveStream.Write(FoodShortage);
    SaveStream.Write(BestAllianceCmp);
    SaveStream.Write(WorstAllianceCmp);
    SaveStream.Write(BestEnemy);
    SaveStream.Write(BestPoint);
    SaveStream.Write(WorstEnemy);
    SaveStream.Write(WorstPoint);
    SaveStream.Write( Integer(Length(Enemies)) );
    if (Length(Enemies) > 0) then
      SaveStream.Write(Enemies[0], SizeOf(Enemies[0])*Length(Enemies));
  end;

  fAttack.Save(SaveStream);
  fAttackNew.Save(SaveStream);
  fDefence.Save(SaveStream);
end;


procedure TKMArmyManagement.Load(LoadStream: TKMemoryStream);
var
  Count: Integer;
begin
  LoadStream.CheckMarker('ArmyManagement');
  LoadStream.Read(fOwner);
  LoadStream.Read(fLastEquippedTimeIron);
  LoadStream.Read(fLastEquippedTimeLeather);

  with fAttackRequest do
  begin
    LoadStream.Read(Active);
    LoadStream.Read(FoodShortage);
    LoadStream.Read(BestAllianceCmp);
    LoadStream.Read(WorstAllianceCmp);
    LoadStream.Read(BestEnemy);
    LoadStream.Read(BestPoint);
    LoadStream.Read(WorstEnemy);
    LoadStream.Read(WorstPoint);
    LoadStream.Read(Count);
    SetLength(Enemies,Count);
    if (Length(Enemies) > 0) then
      LoadStream.Read(Enemies[0], SizeOf(Enemies[0])*Length(Enemies));
  end;

  fAttack.Load(LoadStream);
  fAttackNew.Load(LoadStream);
  fDefence.Load(LoadStream);
end;


procedure TKMArmyManagement.SyncLoad();
begin
  fAttack.SyncLoad();
  fAttackNew.SyncLoad();
  fDefence.SyncLoad();
end;


procedure TKMArmyManagement.AfterMissionInit();
begin
  fAttack.AfterMissionInit();
  fAttackNew.AfterMissionInit();
  fDefence.AfterMissionInit();
end;


procedure TKMArmyManagement.OwnerUpdate(aPlayer: TKMHandID);
begin
  fOwner := aPlayer;
  fAttack.OwnerUpdate(aPlayer);
  fAttackNew.OwnerUpdate(aPlayer);
  fDefence.OwnerUpdate(aPlayer);
end;


procedure TKMArmyManagement.WarriorEquipped(aGroup: TKMUnitGroup);
begin
  //if (gAIFields.Supervisor.CombatStatus[fOwner,fOwner] = csDefending) AND (fDefence.GroupsCount = 0) AND (fAttackNew.Count > 0) then
  if (fDefence.GroupsCount = 0) AND (fAttackNew.Count > 0) then
    fAttackNew.LinkGroup(aGroup);
  if (aGroup.Count > 0) then
    fDefence.FindPlaceForGroup(aGroup);
end;


procedure TKMArmyManagement.RecruitSoldiers();
  function CanEquipIron: Boolean;
  begin
    Result := not (fSetup.ArmyType = atLeather)
              AND (fSetup.UnlimitedEquip or gGame.CheckTime(fLastEquippedTimeIron + fSetup.EquipRateIron));
  end;
  function CanEquipLeather: Boolean;
  begin
    Result := not (fSetup.ArmyType = atIron)
              AND (fSetup.UnlimitedEquip or gGame.CheckTime(fLastEquippedTimeLeather + fSetup.EquipRateLeather));
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
    OR ((fSetup.MaxSoldiers <> -1) AND (gHands[fOwner].Stats.GetArmyCount >= fSetup.MaxSoldiers))
    OR (not CanEquipIron AND not CanEquipLeather)
    OR (gHands[fOwner].Stats.GetHouseQty(htBarracks) = 0)
    OR (fDefence.Count = 0) then
    Exit;

  // Take required warriors from CityManagement (-> implemented consideration of required units + save time)
  FillChar(GroupReq, SizeOf(GroupReq), #0); //Clear up
  for GT := Low(TKMGroupType) to High(TKMGroupType) do
    for K := Low(AITroopTrainOrder[GT]) to High(AITroopTrainOrder[GT]) do
      if (AITroopTrainOrder[GT,K] <> utNone) then
        Inc(GroupReq[GT], gHands[fOwner].AI.CityManagement.WarriorsDemands[ AITroopTrainOrder[GT,K] ] + 1); // Always recruit something

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
        GT := TKMGroupType(KaMRandom(4, 'TKMArmyManagement.RecruitSoldiers')); //Pick random from overall count
        Inc(L);
      until (GroupReq[GT] > 0) OR (L > 9); // Limit number of attempts to guarantee it doesn't loop forever

      if (GroupReq[GT] = 0) then
        continue; // Don't train

      for L := Low(AITroopTrainOrder[GT]) to High(AITroopTrainOrder[GT]) do
      begin
        UT := AITroopTrainOrder[GT, L];
        if (UT <> utNone) then
        begin
          if CanEquipIron AND (UT in WARRIORS_IRON) then
            pEquippedTime := @fLastEquippedTimeIron
          else if CanEquipLeather AND not (UT in WARRIORS_IRON) then
            pEquippedTime := @fLastEquippedTimeLeather
          else
            continue;
          while Barracks[K].CanEquip(UT)
            AND (GroupReq[GT] > 0)
            AND (  ( fSetup.MaxSoldiers = -1 ) OR ( gHands[fOwner].Stats.GetArmyCount < fSetup.MaxSoldiers )  ) do
          begin
            Barracks[K].Equip(UT, 1);
            Dec(GroupReq[GT]);
            pEquippedTime^ := gGame.GameTick; // Only reset it when we actually trained something (in IronThenLeather mode we don't count them separately)
          end;
        end;
      end;
    end;
end;


//Check army food level and positioning
procedure TKMArmyManagement.CheckGroupsState();
var
  K: Integer;
  Group: TKMUnitGroup;
begin
  // Feed army and find unused groups
  for K := 0 to gHands[fOwner].UnitGroups.Count - 1 do
  begin
    Group := gHands[fOwner].UnitGroups[K];

    if (Group <> nil) AND not Group.IsDead AND not Group.InFight then
    begin
      // Check hunger and order food
      if (Group.Condition < UNIT_MIN_CONDITION) then
        // Cheat for autobuild AI: Only feed hungry group members (food consumption lower and more predictable)
        Group.OrderFood(True, fSetup.AutoBuild);

      // Do not process attack or defence during peacetime
      if gGame.IsPeaceTime then
        Continue;

      // Group is in combat classes
      if fAttack.IsGroupInAction(Group) OR fAttackNew.IsGroupInAction(Group) then
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


procedure TKMArmyManagement.CheckAttack();
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
        OR not Group.IsIdleToAI([wtokFlagPoint, wtokHaltOrder])
        OR ((aMobilizationCoef < 1) AND (Group.Count < MIN_TROOPS_IN_GROUP)) then
        Continue;
      // Add grop pointer to array (but dont increase count now so it will be ignored)
      AG.GroupArr[AG.Count] := Group;
      // Check if group can be in array
      if (aMobilizationCoef = 1) then
      begin
        // Take all groups out of attack class
        if not fAttack.IsGroupInAction(Group) OR fAttack.IsGroupInAction(Group) OR fAttackNew.IsGroupInAction(Group) then
          Inc(AG.Count,1); // Confirm that the group should be in array GroupArr
      end
      else
      begin
        // Take group in defence position if it is required by mobilization
        DP := fDefence.FindPositionOf(Group, KaMRandom('TKMArmyManagement.RecruitSoldiers') < aMobilizationCoef ); // True = First line will not be considered
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
    // Select the right number of groups
    StartIdx := 0;
    MenCnt := 0;
    for GT := Low(TKMGroupType) to High(TKMGroupType) do
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
    // Add another groups if we dont have enought men
    while (MenCnt < aTotalMen) AND (ActIdx < aAG.Count) do
    begin
      Inc(MenCnt, aAG.GroupArr[ActIdx].Count);
      Inc(ActIdx);
    end;
    aAG.Count := ActIdx;
    SetLength(aAG.GroupArr, ActIdx);
  end;
  // Find best target -> to secure that AI will be as universal as possible find only point in map and company will destroy everything around automatically
  //function FindBestTarget(var aBestTargetPlayer, aTargetPlayer: TKMHandIndex; var aTargetPoint: TKMPoint; aForceToAttack: Boolean = False): Boolean;
  function FindBestTarget(var aBestTargetPlayer: TKMHandID; var aTargetPoint: TKMPoint; aForceToAttack: Boolean): Boolean;
  const
    ALLIANCE_TARGET_COEF = 0.1;
    BEST_ALLIANCE_TARGET_COEF = 0.2;
    DISTANCE_TILE_PENALIZATION = 1/50;
    DISTANCE_COEF = DISTANCE_TILE_PENALIZATION * 0.1; // Every 50 tiles from closest enemy increase comparison by 0.1
    MIN_COMPARSION = -0.2; // advantage for defender (but we are attacking as a team and team have advantage)
  var
    I, K, MinDist: Integer;
    Comparison, BestComparison: Single;
    OwnerArr: TKMHandIDArray;
    EnemyStats: TKMEnemyStatisticsArray;
  begin
    Result := False;
    aTargetPoint := KMPOINT_ZERO;

    // Try to find enemies from owners position
    SetLength(OwnerArr,1);
    OwnerArr[0] := fOwner;
    if not gAIFields.Supervisor.FindClosestEnemies(OwnerArr, EnemyStats) then
      Exit;

    // Calculate strength of alliance, find best comparison - value in interval <-1,1>, positive value = advantage, negative = disadvantage
    BestComparison := -1;
    if (Length(EnemyStats) > 0) then
    begin
      // Find closest enemy
      MinDist := High(Integer);
      for I := 0 to Length(EnemyStats) - 1 do
        MinDist := Min(MinDist, EnemyStats[I].Distance);

      for I := 0 to Length(EnemyStats) - 1 do
      begin
        // Compute comparison
        Comparison := + gAIFields.Eye.ArmyEvaluation.CompareStrength(fOwner, EnemyStats[I].Player) // <-1,1>
                      + Byte(EnemyStats[I].Player = aBestTargetPlayer) * BEST_ALLIANCE_TARGET_COEF // (+0.1)
                      - abs(EnemyStats[I].Distance - MinDist) * DISTANCE_COEF; // -0.1 per 50 tiles
        // Consider teammates of best target which is selected by Supervisor
        for K := 0 to Length(fAttackRequest.Enemies) - 1 do
          if (fAttackRequest.Enemies[K] = EnemyStats[I].Player) then
            Comparison := Comparison + ALLIANCE_TARGET_COEF; // (+0.1)
        // Find the best
        if (Comparison > BestComparison) then
        begin
          BestComparison := Comparison;
          //aTargetOwner := EnemyStats[I].Player;
          aTargetPoint := EnemyStats[I].ClosestPoint;
        end;
      end;
    end;

    Result := (Length(EnemyStats) > 0) AND (aForceToAttack OR (BestComparison > MIN_COMPARSION));
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
      attClosestBuildingFromArmy:      TargetHouse := gHands.GetClosestHouse(aGroup.Position, fOwner, atEnemy, TARGET_HOUSES, false);
      attClosestBuildingFromStartPos:  TargetHouse := gHands.GetClosestHouse(fSetup.StartPosition, fOwner, atEnemy, TARGET_HOUSES, false);
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
      aTargetP := TargetUnit.CurrPosition
    else if (aTarget = attCustomPosition) then
      aTargetP := TargetHouse.Position;
    Result := not KMSamePoint(aTargetP, KMPOINT_ZERO);
  end;

  // Order multiple companies with equally distributed group types
  procedure OrderAttack(aTargetPoint: TKMPoint; var aAG: TKMAvailableGroups);
  var
    I, K, CompaniesCnt, GTMaxCnt, GCnt, HighAG: Integer;
    GT: TKMGroupType;
    GTArr: array[TKMGroupType] of Integer;
    Groups: TKMUnitGroupArray;
  begin
    // Get count of available group types
    FillChar(GTArr, SizeOf(GTArr), #0);

    for K := 0 to aAG.Count - 1 do
    begin
      fDefence.ReleaseGroup(aAG.GroupArr[K]);
      Inc(  GTArr[ aAG.GroupArr[K].GroupType ]  );
    end;

    if not SP_OLD_ATTACK_AI then
      fAttackNew.AddGroups(aAG.GroupArr)
    else
    begin
      CompaniesCnt := Max(1, Ceil(aAG.Count / Max(1,GA_ARMY_MaxGgroupsInCompany)));
      HighAG := aAG.Count - 1;
      for I := 0 to CompaniesCnt - 1 do
      begin
        GCnt := 0;
        for GT := Low(TKMGroupType) to High(TKMGroupType) do
        begin
          GTMaxCnt := Max(0, Round(GTArr[GT] / (CompaniesCnt - I)));
          GTArr[GT] := GTArr[GT] - GTMaxCnt;
          for K := HighAG downto 0 do
            if (GTMaxCnt <= 0) then
              break
            else if (aAG.GroupArr[K].GroupType = GT) then
            begin
              if (Length(Groups) <= GCnt) then
                SetLength(Groups, GCnt + GA_ARMY_MaxGgroupsInCompany);
              Groups[GCnt] := aAG.GroupArr[K];
              GCnt := GCnt + 1;
              aAG.GroupArr[K] := aAG.GroupArr[HighAG];
              HighAG := HighAG - 1;
              GTMaxCnt := GTMaxCnt - 1;
            end;
        end;
        SetLength(Groups, GCnt);
        fAttack.CreateCompany(aTargetPoint, Groups);
      end;
    end;
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
    DefRatio := fDefence.DefenceStatus();
    with fAttackRequest do
    begin
      // Exit if AI has NOT enought soldiers in defence AND there is NOT food or there are multiple oponents
      if (DefRatio < MIN_DEF_RATIO) AND (FoodShortage OR (BestEnemy <> WorstEnemy)) AND (gGame.MissionMode <> mmTactic) then
        Exit;
      // 1v1 or special game mode
      if (BestEnemy = WorstEnemy) OR (gGame.MissionMode = mmTactic) then
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
    // If we dont have enought groups then exit (if we should take all check if there are already some combat groups)
    if ((MobilizationCoef < 1) OR (fAttack.Count > 2)) AND (AG.Count < MIN_GROUPS_IN_ATTACK) then
      Exit;
    // Find best target of owner and order attack
    if FindBestTarget(fAttackRequest.BestEnemy, TargetPoint, MobilizationCoef = 1) then
      OrderAttack(TargetPoint, AG);
  end
  else if not fSetup.AutoAttack then
    with gHands[fOwner].AI.General do
    begin
      AG := GetGroups(1);
      for K := 0 to Attacks.Count - 1 do
        if Attacks.CanOccur(K, AG.MenAvailable, AG.GroupsAvailable, gGame.GameTick) then //Check conditions are right
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
  fAttackRequest.BestAllianceCmp := aAttackRequest.BestAllianceCmp;
  fAttackRequest.WorstAllianceCmp := aAttackRequest.WorstAllianceCmp;
  fAttackRequest.BestEnemy := aAttackRequest.BestEnemy;
  fAttackRequest.BestPoint := aAttackRequest.BestPoint;
  fAttackRequest.WorstEnemy := aAttackRequest.WorstEnemy;
  fAttackRequest.WorstPoint := aAttackRequest.WorstPoint;
  SetLength(fAttackRequest.Enemies, Length(aAttackRequest.Enemies) );
  Move(aAttackRequest.Enemies[0], fAttackRequest.Enemies[0], SizeOf(fAttackRequest.Enemies[0])*Length(fAttackRequest.Enemies));
end;



procedure TKMArmyManagement.UpdateState(aTick: Cardinal);
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psAIArmyAdv, aTick);
  {$ENDIF}
  try
    if (aTick mod MAX_HANDS = fOwner) then
    begin
      if not gGame.IsPeaceTime then
      begin
        CheckAttack();
        RecruitSoldiers();
      end;
      CheckGroupsState();
      if SP_OLD_ATTACK_AI then
        fAttack.UpdateState(aTick)
      else
        fAttackNew.UpdateState(aTick);
      fDefence.UpdateState(aTick);
    end;
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psAIArmyAdv);
    {$ENDIF}
  end;
end;


function TKMArmyManagement.CombineBalanceStrings(): UnicodeString;
begin
  Result := fBalanceText;
  fAttack.LogStatus(Result);
  fAttackNew.LogStatus(Result);
  fDefence.LogStatus(Result);
end;


procedure TKMArmyManagement.Paint();
begin
  fAttackNew.Paint();
end;


end.
