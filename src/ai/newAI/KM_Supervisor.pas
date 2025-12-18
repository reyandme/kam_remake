{
Artificial intelligence
@author: Martin Toupal
@e-mail: poznamenany@gmail.com
}
unit KM_Supervisor;
{$I KaM_Remake.inc}
interface
uses
  Classes, KM_CommonClasses, KM_CommonTypes, KM_Defaults,
  KM_Points, KM_UnitGroup, KM_Units, KM_UnitWarrior, KM_Terrain,
  KM_NavMeshDefences, KM_NavMeshInfluences, KM_ArmyManagement, KM_AIArmyEvaluation,
  KM_ArmyAttackNew, KM_NavMeshArmyVectorField,
  KM_Houses, KM_Sort;

type
  TKMCompFunc = function (const aElem1, aElem2): Integer;
  TKMDefEval = record
    Val: Word;
    Owner: TKMHandID;
    DefPos: PDefencePosition;
  end;
  TKMDefEvalArr = array of TKMDefEval;
  TKMMineEval = record
    Val: Word;
    pPoint: ^TKMPoint;
  end;
  TKMMineEvalArr = array of TKMMineEval;

  TKMHandByteArr = array[0..MAX_HANDS-1] of Byte;

  TKMCombatStatusPLArray = array[0..MAX_HANDS-1,0..MAX_HANDS-1] of TKMCombatStatus;

  TThreatArray = array of record
    DistRanged, Distance, Risk, WeightedCount: Single;
  end;
  {$IFDEF DEBUG_Supervisor}
    TCombatStatusDebug = record
      TargetGroups: array[0..MAX_HANDS-1] of TKMUnitGroupArray;
      TargetHouses: array[0..MAX_HANDS-1] of TKMHouseArray;
    end;
    TArmyAttackDebug = record
      Groups: TKMUnitGroupArray;
      Threat: TThreatArray;
    end;
  {$ENDIF}


// Supervisor <-> agent relation ... cooperating AI players are just an illusion, agents does not see each other
  TKMSupervisor = class
  private
    fFFA: Boolean;
    fPL2Alli: TKMHandByteArr;
    fAlli2PL: TKMHandID2Array;
    fCombatStatus: TKMCombatStatusPLArray;
    fArmyVector: TKMArmyVectorField;
    {$IFDEF DEBUG_Supervisor}
      fCombatStatusDebug: TCombatStatusDebug;
      fArmyAttackDebug: TArmyAttackDebug;
    {$ENDIF}

    procedure UpdateFFA();
    function IsNewAI(aID: TKMHandID): Boolean;
    function NewAIInTeam(aTeam: Byte; aAttack, aDefence: Boolean): Boolean;
    function IsTeamAlive(aTeam: Byte): Boolean;
    function HasAssets(aPL: TKMHandID; aIncludeArmy: Boolean = True): Boolean;

    function GetInitPoints(var aPlayers: TKMHandIDArray): TKMPointArray;
    function UpdateCombatStatus(aTeam: Byte; var aCityUnderAttack: Boolean): TKMCombatStatus;
    procedure AttackCluster(aAttack: Boolean; aCCTIdx: Word; var A: pTKMGroupCounterWeightArray; const E: TKMUnitGroupArray; const H: TKMHouseArray);
    procedure UpdateAttacks(aTeam: Byte; aTick: Cardinal);
    procedure AttackDecision(aTeam: Byte);

    procedure UpdateDefPos(aTeam: Byte);
    procedure DivideResources();
    //procedure EvaluateArmies();
  public
    constructor Create();
    destructor Destroy(); override;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

    property PL2Alli: TKMHandByteArr read fPL2Alli;
    property Alli2PL: TKMHandID2Array read fAlli2PL;
    property CombatStatus: TKMCombatStatusPLArray read fCombatStatus;
    property FFA: boolean read fFFA;

    function FindClosestEnemies(var aPlayers: TKMHandIDArray; var aEnemyStats: TKMEnemyStatisticsArray): Boolean;

    procedure AfterMissionInit();
    procedure UpdateState(aTick: Cardinal);
    procedure UpdateAlliances();

    function LogStatus(): UnicodeString;
    procedure Paint(aRect: TKMRect);
  end;


implementation
uses
  SysUtils, Math,
  KM_Game, KM_GameParams,
  KM_HandsCollection, KM_Hand, KM_HandEntity, KM_HandTypes,
  {$IFDEF DEBUG_Supervisor}
    KM_RenderAux,
  {$ENDIF}
  KM_AIFields, KM_CommonUtils, KM_AIParameters,
  KM_ResTypes;

type
  TByteArray = array [Word] of byte;
  PByteArray = ^TByteArray;

{ Procedural functions }
function CompareDef(const aElem1, aElem2): Integer;
var
  val1 : TKMDefEval absolute aElem1;
  val2 : TKMDefEval absolute aElem2;
begin
  if      (val1.Val = val2.Val) then Result :=  0
  else if (val1.Val < val2.Val) then Result := -1
  else                               Result := +1;
end;

function CompareMines(const aElem1, aElem2): Integer;
var
  val1 : TKMMineEval absolute aElem1;
  val2 : TKMMineEval absolute aElem2;
begin
  if      (val1.Val = val2.Val) then Result :=  0
  else if (val1.Val < val2.Val) then Result := -1
  else                               Result := +1;
end;

function CompareInt(const aElem1, aElem2): Integer;
var
  val1 : Integer absolute aElem1;
  val2 : Integer absolute aElem2;
begin
  if      (val1 = val2) then Result :=  0
  else if (val1 < val2) then Result := -1
  else                       Result := +1;
end;


{ TKMSupervisor }
constructor TKMSupervisor.Create();
{$IFDEF DEBUG_Supervisor}
  var
    PL: Integer;
{$ENDIF}
begin
  fArmyVector := TKMArmyVectorField.Create(True);
  FillChar(fCombatStatus,SizeOf(fCombatStatus),#0);
  {$IFDEF DEBUG_Supervisor}
    SetLength(fArmyAttackDebug.Threat,0);
    for PL := 0 to MAX_HANDS - 1 do
    begin
      SetLength(fCombatStatusDebug.TargetGroups[PL],0);
      SetLength(fCombatStatusDebug.TargetHouses[PL],0);
    end;
  {$ENDIF}
end;

destructor TKMSupervisor.Destroy();
begin
  fArmyVector.Free;
  inherited;
end;


procedure TKMSupervisor.Save(SaveStream: TKMemoryStream);
var
  K: Integer;
begin
  SaveStream.PlaceMarker('Supervisor');
  SaveStream.Write(fFFA);
  SaveStream.Write(fPL2Alli, SizeOf(fPL2Alli));
  SaveStream.Write( Integer(Length(fAlli2PL)) );
  for K := Low(fAlli2PL) to High(fAlli2PL) do
  begin
    SaveStream.Write( Integer(Length(fAlli2PL[K])) );
    SaveStream.Write(fAlli2PL[K,0], SizeOf(fAlli2PL[K,0])*Length(fAlli2PL[K]));
  end;
  SaveStream.Write(fCombatStatus, SizeOf(fCombatStatus));
end;

procedure TKMSupervisor.Load(LoadStream: TKMemoryStream);
var
  K,L: Integer;
begin
  LoadStream.CheckMarker('Supervisor');
  LoadStream.Read(fFFA);
  LoadStream.Read(fPL2Alli, SizeOf(fPL2Alli));
  LoadStream.Read(L);
  SetLength(fAlli2PL, L);
  for K := Low(fAlli2PL) to High(fAlli2PL) do
  begin
    LoadStream.Read(L);
    SetLength(fAlli2PL[K],L);
    LoadStream.Read(fAlli2PL[K,0], SizeOf(fAlli2PL[K,0])*Length(fAlli2PL[K]));
  end;
  LoadStream.Read(fCombatStatus, SizeOf(fCombatStatus));
end;


procedure TKMSupervisor.AfterMissionInit();
begin
  UpdateAlliances();
  DivideResources();
end;


procedure TKMSupervisor.UpdateState(aTick: Cardinal);
const
  DEFSUPPORT_DIVISION = 10 * MAX_HANDS * 2; // 24 sec
  DEF_OR_ATT_DIVISION = 10 * MAX_HANDS * 10; // 2 min
  DEFENCES = 500;
  ATTACKS = 10;
var
  Modulo: Word;
begin
  // Attack / defence can be updated slower
  Modulo := aTick mod DEF_OR_ATT_DIVISION;
  if (Modulo >= DEFENCES) AND (Modulo - DEFENCES < Length(fAlli2PL)) then
    UpdateDefPos(Modulo - DEFENCES);
  if not gGame.IsPeaceTime then
  begin
    if (Modulo >= ATTACKS) AND (Modulo - ATTACKS < Length(fAlli2PL))
    AND (  gGameParams.IsTactic OR (aTick > (gGame.Options.Peacetime+3) * 10 * 60)  ) then // In normal mode wait 3 minutes after peace
    begin
      UpdateFFA();
      AttackDecision(Modulo - ATTACKS);
    end;
    Modulo := (aTick mod MAX_HANDS);
    if (Modulo < Length(fAlli2PL)) then
      UpdateAttacks(Modulo,aTick);
  end;
end;


procedure TKMSupervisor.UpdateAlliances();
var
  Check: Boolean;
  AlliCnt, PLCnt: Byte;
  Idx: Integer;
  PL1,PL2,PL3: TKMHandID;
begin
  if gGameParams.IsMapEditor then Exit; //No need to work in the mapEd

  FillChar(fPL2Alli, SizeOf(fPL2Alli), #255); // TKMHandIndex = SmallInt => Byte(255) = -1 = HAND_NONE
  SetLength(fAlli2PL, gHands.Count, gHands.Count);
  AlliCnt := 0;
  for PL1 := 0 to gHands.Count - 1 do
    if gHands[PL1].Enabled AND (fPL2Alli[PL1] = 255) then
    begin
      PLCnt := 0;
      for PL2 := 0 to gHands.Count - 1 do
        if gHands[PL2].Enabled AND (fPL2Alli[PL2] = 255) AND ((PL1 = PL2) OR (gHands[PL1].Alliances[PL2] = atAlly)) then
        begin
          Check := True;
          for Idx := 0 to PLCnt - 1 do
          begin
            PL3 := fAlli2PL[AlliCnt,Idx];
            Check := Check AND ((gHands[PL3].Alliances[PL2] = atAlly) AND (gHands[PL2].Alliances[PL3] = atAlly));
          end;
          if not Check then
            Continue;
          fPL2Alli[PL2] := AlliCnt;
          fAlli2PL[AlliCnt,PLCnt] := PL2;
          Inc(PLCnt);
        end;
      SetLength(fAlli2PL[AlliCnt], PLCnt);
      Inc(AlliCnt);
    end;
  SetLength(fAlli2PL, AlliCnt);
  UpdateFFA();
  gAIFields.Influences.UpdateAlliances(fAlli2PL);
end;


procedure TKMSupervisor.UpdateFFA();
var
  Team,PL,Cnt: Integer;
begin
  Cnt := 0;
  for Team := Low(fAlli2PL) to High(fAlli2PL) do
    for PL := Low(fAlli2PL[Team]) to High(fAlli2PL[Team]) do
      if HasAssets(fAlli2PL[Team,PL]) then
      begin
        Inc(Cnt);
        break;
      end;
  fFFA := Cnt > 2;
end;


function TKMSupervisor.IsNewAI(aID: TKMHandID): Boolean;
begin
  Result := gHands[aID].AI.Setup.NewAI;
end;


function TKMSupervisor.NewAIInTeam(aTeam: Byte; aAttack, aDefence: Boolean): Boolean;
var
  IdxPL: Integer;
begin
  Result := False;
  for IdxPL := 0 to Length( fAlli2PL[aTeam] ) - 1 do
    with gHands[ fAlli2PL[aTeam, IdxPL] ] do
      if IsComputer
        AND AI.Setup.NewAI
        AND (not aAttack OR AI.Setup.AutoAttack)
        AND (not aDefence OR AI.Setup.AutoDefend) then
        Exit(True);
end;


function TKMSupervisor.IsTeamAlive(aTeam: Byte): Boolean;
var
  PL: Integer;
begin
  Result := False;
  for PL in fAlli2PL[aTeam] do
    if HasAssets(PL,True) then
      Exit(True);
end;


function TKMSupervisor.HasAssets(aPL: TKMHandID; aIncludeArmy: Boolean = True): Boolean;
const
  HOUSE_TYPES: array of TKMHouseType = [htBarracks, htStore, htSchool, htTownhall];
begin
  with gHands[aPL] do
    Result := Enabled AND ((Stats.GetHouseQty(HOUSE_TYPES) > 0) OR (aIncludeArmy AND (Stats.GetArmyCount() > 0)));
end;


function TKMSupervisor.UpdateCombatStatus(aTeam: Byte; var aCityUnderAttack: Boolean): TKMCombatStatus;
  procedure UpdateCS(aOwner,aEnemy: TKMHandID; aStatus: TKMCombatStatus);
  begin
    if (Byte(fCombatStatus[aOwner,aEnemy]) < Byte(aStatus)) then
      fCombatStatus[aOwner,aEnemy] := aStatus;
  end;

const
  SQR_DANGEROUS_DISTANCE = 15*15;
  SQR_OFFENSIVE_DISTANCE = 30*30;
  INFLUENCE_THRESHOLD = 150;
  ARMY_IN_HOSTILE_CITY = 200;
  TARGET_HOUSE_IN_INFLUENCE = 150;
var
  CS: TKMCombatStatus;
  K, L, M, CSNum: Integer;
  P: TKMPoint;
  G: TKMUnitGroup;
  pCluster: pTKMCombatCluster;
  Owner, PL: TKMHandID;
begin
  Result := csNeutral;
  aCityUnderAttack := False;
  // Check if team have newAI
  if not NewAIInTeam(aTeam, False, False) then
    Exit;

  // Set default state = csNeutral (except attack combat status)
  for Owner in fAlli2PL[aTeam] do
    for PL := 0 to gHands.Count - 1 do
        if (gHands[Owner].Alliances[PL] <> atEnemy)
          OR (fCombatStatus[Owner,PL] in [csDefending, csCounterattack])
          OR (not HasAssets(PL))
          OR ((gHands[Owner].AI.ArmyManagement.AttackNew.Count = 0) AND not gHands[Owner].AI.ArmyManagement.AttackRequest.Active) then
          fCombatStatus[Owner,PL] := csNeutral;

  // Scan distances in the NavMesh
  if not fArmyVector.DetectEnemyPresence(fAlli2PL[aTeam]) then
    Exit(csNeutral);

  // Get closest distance between ally and enemy groups
  for K := 0 to fArmyVector.Ally.GroupsCount - 1 do
  begin
    L := fArmyVector.Ally.GroupsPoly[K];
    if (fArmyVector.QueueArray[L].Visited > 0) then
    begin
      pCluster := @fArmyVector.Clusters.Clusters[  fArmyVector.Clusters.Clusters[ fArmyVector.ClusterMapping[L] ].ReferenceID  ];
      for M := Low(fArmyVector.CCT) to High(fArmyVector.CCT) do
        if (fArmyVector.CCT[M].Cluster = pCluster) then
        begin
          fArmyVector.CCT[M].BestDist := Min(fArmyVector.CCT[M].BestDist, fArmyVector.QueueArray[L].Distance);
          for Owner in fArmyVector.CCT[M].Owners do
            UpdateCS(fArmyVector.Ally.Groups[K].Owner, Owner, csDefending);
        end;
    end;
  end;

  // Evaluate cluster
  for K := Low(fArmyVector.CCT) to High(fArmyVector.CCT) do
  begin
    pCluster := fArmyVector.CCT[K].Cluster;

    // Check if cluster is in the city
    for M := 0 to pCluster.GroupsCount - 1 do
    begin
      G := fArmyVector.Enemy.Groups[ pCluster.Groups[M] ];
      Inc(fArmyVector.CCT[K].CounterWeight.WeightedCount[G.GroupType],G.Count);
      P := G.Position;
      for Owner in fAlli2PL[aTeam] do
        if (gAIFields.Influences.OwnPoint[Owner, P] > INFLUENCE_THRESHOLD) then
        begin
          fArmyVector.CCT[K].AttackingCity := True;
          aCityUnderAttack := True;
          Result := csDefending;
          UpdateCS(Owner,G.Owner,csDefending);
        end;
    end;

    // Get combat status - if CS = csAttackCity then increase threat
    CSNum := Byte(csNeutral);
    for M := 0 to Length(fArmyVector.CCT[K].Owners) - 1 do
      for Owner in fAlli2PL[aTeam] do
        CSNum := Max(CSNum, Byte(fCombatStatus[ Owner, fArmyVector.CCT[K].Owners[M] ]) );

    // Estimate threat
    with fArmyVector.CCT[K] do
    begin
      Threat := (CounterWeight.WeightedCount[gtMelee] + CounterWeight.WeightedCount[gtMounted] + CounterWeight.WeightedCount[gtRanged] + CounterWeight.WeightedCount[gtAntiHorse]);
      ThreatNearby := Byte((BestDist < 1E4) OR AttackingCity) * Threat
                + Byte( (CSNum >= Byte(csAttackingCity)) AND (pCluster.HousesCount > 0) );
    end;
  end;


  // Update combat status of the alliance in relation to allied units
  for Owner in fAlli2PL[aTeam] do
  begin
    CS := csNeutral;
    for PL := 0 to gHands.Count - 1 do
      if (gHands[Owner].Alliances[PL] = atEnemy) then
      begin
        // Check if units are closer to enemy city and if so, then change status to counterattack
        if (fCombatStatus[Owner,PL] in [csNeutral, csDefending]) AND HasAssets(PL,False) then
          for K := 0 to gHands[Owner].UnitGroups.Count - 1 do
          begin
            G := gHands[Owner].UnitGroups.Groups[K];
            if (G <> nil) AND not G.IsDead AND (gAIFields.Influences.OwnPoint[ PL, G.Position ] > ARMY_IN_HOSTILE_CITY) then
            begin
              fCombatStatus[Owner,PL] := csCounterattack;
              break;
            end;
          end;
        // Update combat status
        CS := TKMCombatStatus(  Max( Byte(CS), Byte(fCombatStatus[Owner,PL]) )  );
      end;
    Result := TKMCombatStatus(  Max( Byte(CS), Byte(Result) )  );
    fCombatStatus[Owner,Owner] := CS; // Overall combat status of player
  end;
end;


procedure TKMSupervisor.AttackCluster(aAttack: Boolean; aCCTIdx: Word; var A: pTKMGroupCounterWeightArray; const E: TKMUnitGroupArray; const H: TKMHouseArray);

  function GetIdx(aLen, aA, aE: Integer): Integer; inline;
  begin
    Result := aLen * aA + aE;
  end;

const
  NO_THREAT = -1E6;
  sqr_INTEREST_DISTANCE_House = 20*20;
  sqr_MAX_DISTANCE_FROM_HOUSE = 10*10;
  MAX_ATTACKERS_PER_HOUSE = 12;
  WarriorPrice: array [utMilitia..utVagabond] of Single = (
    1.0,2.0,3.0,2.0,3.0, // utMilitia,utAxeFighter,utSwordsman,utBowman,utArbaletman,
    2.0,3.0,2.0,3.0,     // utPikeman,utHallebardman,utHorseScout,utCavalry
    3.5,1.0,1.0,3.5,1.0  // utBarbarian,utPeasant,utSlingshot,utMetalBarbarian,utHorseman
  );
  OpportunityArr: array [GROUP_TYPE_MIN..GROUP_TYPE_MAX, GROUP_TYPE_MIN..GROUP_TYPE_MAX] of Single = (
  // gtMelee, gtAntiHorse, gtRanged, gtMounted
    (    1.0,         1.5,      3.0,       0.5), // gtMelee
    (    0.5,         1.0,      2.0,       4.0), // gtAntiHorse
    (    1.0,         1.5,      2.0,       0.5), // gtRanged
    (    1.0,         0.5,      5.0,       1.0)  // gtMounted
  );

var
  IdxA,IdxE, CntA, CntE, Overflow, Overflow2, BestIdxE, BestIdxA: Integer;
  BestThreat, Opportunity, BestOpportunity: Single;
  U: TKMUnit;
  UW: TKMUnitWarrior;
  pGCWA: pTKMGroupCounterWeight;
  TargetH: TKMHouse;
  Dist: array of Single;
  Threat: TThreatArray;
  AttackingHouseCnt: array of Word;
begin
  // Init variables for compiler
  BestIdxA := 0;
  BestIdxE := 0;
  CntA := Length(A);
  CntE := Length(E);

  // Remove groups that already attack house (destroy it at all cost)
  SetLength(AttackingHouseCnt, Length(H));
  if (Length(AttackingHouseCnt) > 0) then
  begin
    FillChar(AttackingHouseCnt[0], Length(AttackingHouseCnt) * SizeOf(AttackingHouseCnt[0]), #0);
    for IdxA := CntA - 1 downto 0 do
    begin
      TargetH := A[IdxA].Group.OrderTargetHouse;
      if (TargetH <> nil) AND (A[IdxA].Group.GroupType <> gtRanged) AND (KMDistanceSqr(A[IdxA].Group.Position,TargetH.Entrance) < sqr_MAX_DISTANCE_FROM_HOUSE) then
      begin
        // Consider units if house is in the combat line
        for IdxE := 0 to Length(H) - 1 do
          if (H[IdxE] = TargetH) then
          begin
            Inc(AttackingHouseCnt[IdxE],A[IdxA].Group.Count);
            break;
          end;
        Dec(CntA);
        // Swap groups so groups < CntA waits for orders but threat is computed from all
        pGCWA := A[IdxA];
        A[IdxA] := A[CntA];
        A[CntA] := pGCWA;
      end;
    end;
  end;

  if aAttack AND (Length(E) > 0) then
  begin

    // Set orders for ranged groups in range (the closest enemy, top prio)
    for IdxA := CntA - 1 downto 0 do
      if (A[IdxA].Group.GroupType = gtRanged) then
      begin
        U := gTerrain.UnitsHitTestWithinRad(A[IdxA].Group.Position, 0.5, A[IdxA].Group.GetAliveMember.GetFightMaxRange(True), A[IdxA].Group.Owner, atEnemy, dirNA, False);
        if (U is TKMUnitWarrior) then
        begin
          A[IdxA].CG.TargetGroup := TKMUnitWarrior(U).Group;
          Dec(CntA);
          // Swap groups so groups < CntA waits for orders but threat is computed from all
          pGCWA := A[IdxA];
          A[IdxA] := A[CntA];
          A[CntA] := pGCWA;
        end;
      end;

    // Compute distances (it is used for threat so compute it for all groups)
    SetLength(Dist, Length(A)*Length(E));
    for IdxA := 0 to Length(A) - 1 do
    for IdxE := 0 to Length(E) - 1 do
      Dist[ GetIdx(CntE,IdxA,IdxE) ] := KMDistanceSqr(A[IdxA].Group.Position,E[IdxE].Position);

    // Compute threat
    SetLength(Threat, Length(E));
    for IdxE := 0 to CntE - 1 do
    begin
      // Estimate threat
      Threat[IdxE].Distance := 1E6;
      Threat[IdxE].DistRanged := 1E6;
      for IdxA := 0 to Length(A) - 1 do // Over all groups
        if (A[IdxA].Group.GroupType = gtRanged) AND (Dist[ GetIdx(CntE,IdxA,IdxE) ] < Threat[IdxE].DistRanged) then
          Threat[IdxE].DistRanged := Dist[ GetIdx(CntE,IdxA,IdxE) ]
        else if (Dist[ GetIdx(CntE,IdxA,IdxE) ] < Threat[IdxE].Distance) then
          Threat[IdxE].Distance := Dist[ GetIdx(CntE,IdxA,IdxE) ];
      // Estimate group price (use just 1 warrior type * count)
      UW := E[IdxE].GetAliveMember;
      Threat[IdxE].WeightedCount := E[IdxE].Count * WarriorPrice[UW.UnitType];
      case E[IdxE].GroupType of // + City influence - Group in combat
        gtMelee:     Threat[IdxE].Risk := Threat[IdxE].WeightedCount * AI_Par[ATTACK_SUPERVISOR_EvalTarget_ThreatGainMelee];
        gtAntiHorse: Threat[IdxE].Risk := Threat[IdxE].WeightedCount * AI_Par[ATTACK_SUPERVISOR_EvalTarget_ThreatGainAntiHorse];
        gtRanged:    Threat[IdxE].Risk := Threat[IdxE].WeightedCount * AI_Par[ATTACK_SUPERVISOR_EvalTarget_ThreatGainRanged];
        gtMounted:   Threat[IdxE].Risk := Threat[IdxE].WeightedCount * AI_Par[ATTACK_SUPERVISOR_EvalTarget_ThreatGainMounted];
        else         Threat[IdxE].Risk := NO_THREAT;
      end;
      // Consider distance
      Threat[IdxE].Risk :=
        + Threat[IdxE].Risk
        - Threat[IdxE].DistRanged * AI_Par[ATTACK_SUPERVISOR_EvalTarget_ThreatGainRangDist] * Byte(Threat[IdxE].DistRanged <> 1E6)
        - Threat[IdxE].Distance   * AI_Par[ATTACK_SUPERVISOR_EvalTarget_ThreatGainDist]     * Byte(Threat[IdxE].Distance   <> 1E6);
    end;

    {$IFDEF DEBUG_Supervisor}
      SetLength(fArmyAttackDebug.Groups, Length(Threat));
      SetLength(fArmyAttackDebug.Threat, Length(Threat));
      if (Length(Threat) > 0) then
      begin
        Move(E[0],      fArmyAttackDebug.Groups[0], Length(E) * SizeOf(E[0]));
        Move(Threat[0], fArmyAttackDebug.Threat[0], Length(Threat) * SizeOf(Threat[0]));
      end;
    {$ENDIF}

    // Set targets

    // Archers (out of range) - shoot the nearest enemy
    for IdxA := 0 to CntA - 1 do
      if (A[IdxA].Group.GroupType = gtRanged) then
      begin
        BestOpportunity := abs(NO_THREAT);
        for IdxE := Low(Threat) to High(Threat) do
          if (Dist[ GetIdx(CntE,IdxA,IdxE) ] < BestOpportunity) then
          begin
            BestIdxE := IdxE;
            BestOpportunity := Dist[ GetIdx(CntE,IdxA,IdxE) ];
          end;
        // Set order
        if (BestOpportunity <> abs(NO_THREAT)) then
        begin
          A[IdxA].CG.TargetGroup := E[BestIdxE];
          // Remove group from selection
          A[IdxA] := nil;
        end;
      end;

    // Melee - attack the most dangerous enemy
    Overflow := 0;
    while (Overflow < Length(E)) do
    begin
      Inc(Overflow);
      // Find the most dangerous enemy (closest and strongest group)
      BestThreat := NO_THREAT;
      for IdxE := Low(Threat) to High(Threat) do
        if (Threat[IdxE].Risk > BestThreat) then
        begin
          BestIdxE := IdxE;
          BestThreat := Threat[IdxE].Risk;
        end;
      if (BestThreat <= NO_THREAT) then
        break;
      // Find something that can beat it (distance, strength and group type)
      with Threat[BestIdxE] do
      begin
        Overflow2 := 0;
        while (WeightedCount > 0) AND (Min(DistRanged, Distance) < sqr(AI_Par[ATTACK_SUPERVISOR_EvalTarget_DistanceGroup])) AND (Overflow2 < 100) do
        begin
          Inc(Overflow2);
          BestOpportunity := NO_THREAT;
          for IdxA := 0 to CntA - 1 do
            if (A[IdxA] <> nil) then // Skip already used group
            begin
              Opportunity := + OpportunityArr[ A[IdxA].Group.GroupType, E[BestIdxE].GroupType ] * AI_Par[ATTACK_SUPERVISOR_EvalTarget_OpportunityGain]
                             - Dist[ GetIdx(CntE,IdxA,BestIdxE) ]                               * AI_Par[ATTACK_SUPERVISOR_EvalTarget_OpportunityDistGain];
              if (BestOpportunity < Opportunity) then
              begin
                BestIdxA := IdxA;
                BestOpportunity := Opportunity;
              end;
            end;
          if (BestOpportunity <> NO_THREAT) then
          begin
            // SetOrders
            UW := A[BestIdxA].Group.GetAliveMember;
            // Decrease risk
            WeightedCount := WeightedCount - A[BestIdxA].Group.Count * WarriorPrice[UW.UnitType] * AI_Par[ATTACK_SUPERVISOR_EvalTarget_DecreaseRisk];
            // Set order
            A[BestIdxA].CG.TargetGroup := E[BestIdxE];
            // Remove group from selection
            A[BestIdxA] := nil;
          end
          else
            break;
        end;
        Risk := NO_THREAT;
      end;
    end;
  end;

  // Attack houses
  for IdxE := 0 to Length(H) - 1 do
  begin
    Overflow := 0;
    while (AttackingHouseCnt[IdxE] < MAX_ATTACKERS_PER_HOUSE) AND (Overflow < 5) do
    begin
      Inc(Overflow);
      BestOpportunity := abs(NO_THREAT);
      for IdxA := 0 to CntA - 1 do
        if (A[IdxA] <> nil) AND (A[IdxA].Group.GroupType <> gtRanged) then
        begin
          Opportunity := KMDistanceSqr(H[IdxE].Entrance, A[IdxA].Group.Position);
          if (BestOpportunity > Opportunity) AND (Opportunity < sqr_INTEREST_DISTANCE_House) then
          begin
            BestIdxA := IdxA;
            BestOpportunity := Opportunity;
          end;
        end;
      // Set order
      if (BestOpportunity <> abs(NO_THREAT)) then
      begin
        Inc(AttackingHouseCnt[IdxE],A[BestIdxA].Group.Count);
        A[BestIdxA].CG.TargetHouse := H[IdxE];
        A[BestIdxA] := nil;
      end;
    end;
  end;
  // Remove groups with orders from A (the rest is going to get command to walk)
  for IdxA := cntA to Length(A) - 1 do
    A[IdxA] := nil;
end;


procedure TKMSupervisor.UpdateAttacks(aTeam: Byte; aTick: Cardinal);

  procedure EvaluateEnemy(aAttack: Boolean; aIdx: Word);
  var
    K, Cnt: Integer;
    EG: TKMUnitGroupArray;
    pGCWA: pTKMGroupCounterWeightArray;
    H: TKMHouseArray;
  begin
    // Copy allied groups (they will be edited)
    SetLength(pGCWA, fArmyVector.CCT[aIdx].CounterWeight.CGCount);
    Cnt := 0;
    for K := 0 to fArmyVector.CCT[aIdx].CounterWeight.GroupsCount - 1 do
    begin
      pGCWA[Cnt] := @fArmyVector.CCT[aIdx].CounterWeight.Groups[K];
      Inc(Cnt,Byte(pGCWA[Cnt].CG <> nil));
      if (Cnt = fArmyVector.CCT[aIdx].CounterWeight.CGCount) then
        break;
    end;
    // Set orders to attack
    with fArmyVector.CCT[aIdx].Cluster^ do
    begin
      SetLength(EG, GroupsCount);
      for K := 0 to GroupsCount - 1 do
        EG[K] := fArmyVector.Enemy.Groups[ Groups[K] ];
      SetLength(H, HousesCount);
      Cnt := 0;
      // Barracks first
      for K := 0 to HousesCount - 1 do
        if (fArmyVector.Enemy.Houses[ Houses[K] ].HouseType = htBarracks) then
        begin
          H[Cnt] := fArmyVector.Enemy.Houses[ Houses[K] ];
          Inc(Cnt);
        end;
      for K := 0 to HousesCount - 1 do
        if (fArmyVector.Enemy.Houses[ Houses[K] ].HouseType <> htBarracks) then
        begin
          H[Cnt] := fArmyVector.Enemy.Houses[ Houses[K] ];
          Inc(Cnt);
        end;
      AttackCluster(aAttack, aIdx, pGCWA, EG, H);
    end;
    // Set orders to move
    for K := Low(pGCWA) to High(pGCWA) do
      if (pGCWA[K] <> nil) AND (pGCWA[K].CG <> nil) then
        pGCWA[K].CG.TargetPosition := pGCWA[K].TargetPosition
  end;

var
  PlayerInCombat, CityUnderAttack: Boolean;
  K, L: Integer;
  PL: TKMHandID;
  CS: TKMCombatStatus;
  CSA: TKMCombatStatusArray;
begin
  // Check if team have newAI
  if not NewAIInTeam(aTeam, False, False) then
    Exit;
  // Check if there are hostile units around
  CityUnderAttack := False;
  CS := UpdateCombatStatus(aTeam,CityUnderAttack);
  // Check if hostile units are around specific player (if not release combat groups)
  if not CityUnderAttack then
    for K := 0 to Length(fAlli2PL[aTeam]) - 1 do
      if IsNewAI(fAlli2PL[aTeam,K]) then
      begin
        PlayerInCombat := False;
        for L := 0 to Length(fCombatStatus[ fAlli2PL[aTeam,K] ]) - 1 do
          PlayerInCombat := PlayerInCombat OR (fCombatStatus[ fAlli2PL[aTeam,K], L ] <> csNeutral);
        if not PlayerInCombat then
          gHands[ fAlli2PL[aTeam,K] ].AI.ArmyManagement.AttackNew.ReleaseGroups();
      end;
  if (CS = csNeutral) then
    Exit;
  // Check if team have groups
  if not (fArmyVector.Ally.GroupsCount > 0) OR (fArmyVector.Clusters.Count = 0) then
    Exit;

  // Add everything to defence if AI is defending
  for K := Low(fArmyVector.CCT) to High(fArmyVector.CCT) do
    if (fArmyVector.CCT[K].AttackingCity) then
    begin
      for PL in fAlli2PL[aTeam] do
        if IsNewAI(PL) then
          with gHands[PL].AI.ArmyManagement do
            AttackNew.AddGroups( Defence.ReleaseAllGroups() );
      break;
    end;

  // Divide forces and find positions
  for PL in fAlli2PL[aTeam] do
    CSA[PL] := fCombatStatus[PL,PL];
  fArmyVector.DivideForces(CS, CSA);
  fArmyVector.FindPositions();

  // Set orders
  for K := 0 to Length(fArmyVector.CCT) - 1 do
    with fArmyVector.CCT[K].CounterWeight do
      if (CGCount > 0) then
        EvaluateEnemy(InPlace OR AtAdvantage OR Ambushed, K);
end;


function TKMSupervisor.GetInitPoints(var aPlayers: TKMHandIDArray): TKMPointArray;
var
  IdxPL: Integer;
  Player: TKMHandID;
  Group: TKMUnitGroup;
  CenterPoints: TKMPointArray;
begin
  SetLength(Result, 0);

  // Find center points of cities / armies (where we should start scan - init point / center screen is useless for this)
  for IdxPL := 0 to High(aPlayers) do
  begin
    Player := aPlayers[IdxPL];
    gAIFields.Eye.OwnerUpdate(Player);
    CenterPoints := gAIFields.Eye.GetCityCenterPoints(True);
    if (Length(CenterPoints) = 0) then // Important houses were not found -> try find soldier
    begin
      if (gHands[Player].UnitGroups.Count = 0) then
        Continue;
      Group := gHands[Player].UnitGroups.Groups[ KaMRandom(gHands[Player].UnitGroups.Count{$IFDEF RNG_SPY}, 'TKMSupervisor.GetInitPoints'{$ENDIF}) ];
      if (Group <> nil) AND not Group.IsDead AND not KMSamePoint(KMPOINT_ZERO,Group.Position) then
      begin
        SetLength(CenterPoints, 1);
        CenterPoints[0] := Group.Position;
      end
      else
        Continue;
    end;
    SetLength(Result, Length(Result) + Length(CenterPoints));
    Move(CenterPoints[0], Result[ Length(Result) - Length(CenterPoints) ], SizeOf(CenterPoints[0]) * Length(CenterPoints));
  end;
end;


function TKMSupervisor.FindClosestEnemies(var aPlayers: TKMHandIDArray; var aEnemyStats: TKMEnemyStatisticsArray): Boolean;
var
  InitPoints: TKMPointArray;
begin
  // Get init points
  InitPoints := GetInitPoints(aPlayers);
  // Try find enemies by influence area
  Result := (Length(InitPoints) <> 0)
            AND (
              gAIFields.Influences.InfluenceSearch.FindClosestEnemies(aPlayers[0], InitPoints, aEnemyStats, True)
              //OR gAIFields.Influences.InfluenceSearch.FindClosestEnemies(aPlayers[0], InitPoints, aEnemyStats, False)
            );
end;


// Find best target -> to secure that AI will be as universal as possible find only point in map and company will destroy everything around automatically
procedure TKMSupervisor.AttackDecision(aTeam: Byte);

  function FindTargetAssets(aTeamIdx: Byte; var aTargetSoldiers: Boolean; var aPolygons: TKMWordArray): Integer;
  const
    SCANNED_HOUSES = [htStore, htSchool, htBarracks, htTownhall];
  var
    K: Integer;
    PL: TKMHandID;
    H: TKMHouse;
    G: TKMUnitGroup;
  begin
    aTargetSoldiers := False;
    Result := 0;
    FillChar(aPolygons[0], SizeOf(aPolygons[0])*Length(aPolygons), #0);
    for PL in fAlli2PL[aTeamIdx] do
    begin
      for K := 0 to gHands[PL].Houses.Count - 1 do
      begin
        H := gHands[PL].Houses[K];
        if (H <> nil) AND not H.IsDestroyed AND H.IsComplete AND (H.HouseType in SCANNED_HOUSES) then
        begin
          aPolygons[PL] := gAIFields.NavMesh.KMPoint2Polygon[ H.PointBelowEntrance ];
          Inc(Result);
          break;
        end;
      end;
    end;
    if (Result = 0) then
    begin
      aTargetSoldiers := True;
      for PL in fAlli2PL[aTeamIdx] do
        for K := 0 to gHands[PL].UnitGroups.Count - 1 do
        begin
          G := gHands[PL].UnitGroups.Groups[K];
          if (G <> nil) AND not G.IsDead AND not KMSamePoint(KMPOINT_ZERO,G.Position) then
          begin
            aPolygons[PL] := gAIFields.NavMesh.KMPoint2Polygon[ G.Position ];
            Inc(Result);
            break;
          end;
        end;
    end;
  end;

  function CompareAlliances(out aBestCmpTeam, aWorstCmpTeam: Byte; out aBestCmp, aAvrgCmp, aWorstCmp: Single; out aBestTarget: TKMHandID): Boolean;
  const
    // Decrease chance to attack enemy in distance
    DISTANCE_COEF_1v1 = 0.4;
    DISTANCE_COEF_FFA = 2;
  var
    ATargetSoldiers, ETargetSoldiers: Boolean;
    Distance, MinDist, MaxDist: Word;
    K, L, ACnt, ECnt, TeamIdx: Integer;
    Comparison, DistCoef: Single;
    TargetPL: TKMHandIDArray;
    AllyPoly,EnemyPoly,RoutePoly,DistArr: TKMWordArray;
  begin
    Result := False;
    ATargetSoldiers := False;
    ETargetSoldiers := False;
    SetLength(AllyPoly,MAX_HANDS);
    SetLength(EnemyPoly,MAX_HANDS);
    ACnt := FindTargetAssets(aTeam, ATargetSoldiers, AllyPoly);
    aBestCmp := -1;
    aAvrgCmp := 0;
    aWorstCmp := 1;
    aBestCmpTeam := 0;
    aWorstCmpTeam := 0;

    // Compute walking distance between alliances
    Distance := 0;
    MinDist := High(Word);
    MaxDist := 0;
    SetLength(DistArr, Length(fAlli2PL));
    SetLength(TargetPL, Length(fAlli2PL));
    for TeamIdx := Low(fAlli2PL) to High(fAlli2PL) do
    begin
      DistArr[TeamIdx] := High(Word);
      if (TeamIdx <> aTeam) AND IsTeamAlive(TeamIdx) then
      begin
        ECnt := FindTargetAssets(TeamIdx, ATargetSoldiers, EnemyPoly);
        if (ECnt <= 0) then
          Continue;
        for K := Low(AllyPoly) to High(AllyPoly) do
          if (AllyPoly[K] > 0) then
            for L := Low(EnemyPoly) to High(EnemyPoly) do
              if (EnemyPoly[L] > 0) AND gAIFields.NavMesh.Pathfinding.ShortestPolygonRoute(AllyPoly[K], EnemyPoly[L], Distance, RoutePoly) then
              begin
                if (DistArr[TeamIdx] > Distance) then
                begin
                  DistArr[TeamIdx] := Distance;
                  TargetPL[TeamIdx] := L;
                end;
              end;
        if (DistArr[TeamIdx] = High(Word)) then
          Continue;
        Result := True;
        MinDist := Min(MinDist, DistArr[TeamIdx]);
        MaxDist := Max(MaxDist, DistArr[TeamIdx]);
      end;
    end;

    // Compute comparison
    DistCoef := IfThen(FFA, DISTANCE_COEF_FFA, DISTANCE_COEF_1v1);
    for TeamIdx := Low(fAlli2PL) to High(fAlli2PL) do
      if (DistArr[TeamIdx] <> High(Word)) then
      begin
        Comparison := + gAIFields.Eye.ArmyEvaluation.CompareAllianceStrength(fAlli2PL[aTeam], fAlli2PL[TeamIdx])
                      - (DistArr[TeamIdx] - MinDist) / Max(1,(MaxDist - MinDist));
        aAvrgCmp := aAvrgCmp + Comparison;
        if (Comparison >= aBestCmp) then
        begin
          aBestCmp := Comparison;
          aBestCmpTeam := TeamIdx;
          aBestTarget := TargetPL[TeamIdx];
        end;
        if (Comparison <= aWorstCmp) then
        begin
          aWorstCmp := Comparison;
          aWorstCmpTeam := TeamIdx;
        end;
      end;
    aAvrgCmp := aAvrgCmp / Max(1,Length(fAlli2PL)-1);
  end;

const
  MIN_DEF_RATIO = 1.2;
  MIN_ADVANTAGE = 0.15; // 15% advantage for attacker
var
  FoodProblems: Boolean;
  BestCmpTeam, WorstCmpTeam: Byte;
  IdxPL: Integer;
  DefRatio, BestCmp, AvrgCmp, WorstCmp: Single;
  PL, PL2, BestTarget: TKMHandID;
  AR: TKMAttackRequest;
begin
  if not NewAIInTeam(aTeam, True, False) OR not IsTeamAlive(aTeam) OR (Length(fAlli2PL) < 2) then // I sometimes use my loc as a spectator (alliance with everyone) so make sure that search for enemy will use AI loc
    Exit;
  // Check if alliance can attack (have available soldiers) in the FFA mode (if there are just 2 teams attack if we have advantage)
  if FFA AND not gGameParams.IsTactic then
  begin
    DefRatio := 0;
    for IdxPL := 0 to Length( fAlli2PL[aTeam] ) - 1 do
      with gHands[ fAlli2PL[aTeam, IdxPL] ] do
        if IsComputer AND AI.Setup.NewAI AND AI.Setup.AutoAttack then
        begin
          DefRatio := Max(DefRatio, AI.ArmyManagement.Defence.DefenceStatus);
          KMSwapInt(fAlli2PL[aTeam, 0], fAlli2PL[aTeam, IdxPL]); // Make sure that player in first index is new AI
        end;
    // AI does not have enough soldiers
    if (DefRatio < MIN_DEF_RATIO) then
      Exit;
  end;
  // Try to find enemies, find best comparison - value in interval <-1,1>, positive value = advantage, negative = disadvantage
  if CompareAlliances(BestCmpTeam, WorstCmpTeam, BestCmp, AvrgCmp, WorstCmp, BestTarget) then
  begin
    // Consider food
    FoodProblems := gAIFields.Eye.ArmyEvaluation.CheckFoodProblems(fAlli2PL[aTeam]);
    // Make decision
    if (BestCmp > MIN_ADVANTAGE) OR (FoodProblems AND (fCombatStatus[fAlli2PL[aTeam,0],fAlli2PL[aTeam,0]] = csNeutral)) OR gGameParams.IsTactic then
    begin
      with AR do
      begin
        Active := True;
        FFA := fFFA;
        FoodShortage := FoodProblems;
        BestAllianceCmp := BestCmp;
        WorstAllianceCmp := WorstCmp;
        BestEnemy := BestTarget;
        SetLength(Enemies, Length(fAlli2PL[BestCmpTeam]) );
        Move(fAlli2PL[BestCmpTeam,0], Enemies[0], SizeOf(Enemies[0])*Length(Enemies));
      end;
      for PL in fAlli2PL[aTeam] do
        if gHands[PL].AI.Setup.AutoAttack then
        begin
          gHands[PL].AI.ArmyManagement.AttackRequest := AR;
          if gGameParams.IsTactic then
            fCombatStatus[PL,BestTarget] := csAttackingEverything
          else
            fCombatStatus[PL,BestTarget] := csAttackingCity;
        end;
    end;
    // Stop attack if food problem was solved
    if (BestCmp < MIN_ADVANTAGE) AND not FoodProblems AND not gGameParams.IsTactic then
    begin
      for PL in fAlli2PL[aTeam] do
        if gHands[PL].AI.Setup.AutoAttack then
          for PL2 := 0 to MAX_HANDS - 1 do
            if (fCombatStatus[PL,PL2] = csAttackingCity) OR (fCombatStatus[PL,PL2] = csAttackingEverything) then
              fCombatStatus[PL,PL2] := csNeutral;
    end;
  end;
end;


procedure TKMSupervisor.UpdateDefPos(aTeam: Byte);
type
  TKMDistDefPos = array[0..MAX_HANDS-1] of record
    Count: Word;
    DefPos: array of PDefencePosition;
  end;

  procedure DivideDefences(var aOwners: TKMHandIDArray; var aDefPosReq: TKMWordArray; var aTeamDefPos: TKMTeamDefPos);
  const
    DISTANCE_PRICE = 1;
    FRONT_LINE_PRICE = 40;
  var
    Line: Byte;
    I, K, PolyIdx, IdxPL, Cnt: Integer;
    Point: TKMPoint;
    DistributedPos: TKMDistDefPos;
    DefEval: TKMDefEvalArr;
    CenterPoints, Points: TKMPointArray;
  begin
    // Find center points
    SetLength(CenterPoints, Length(aOwners));
    for IdxPL := 0 to Length(aOwners) - 1 do
    begin
      gAIFields.Eye.OwnerUpdate( aOwners[IdxPL] );
      Points := gAIFields.Eye.GetCityCenterPoints(False);
      CenterPoints[IdxPL] := Points[0];
    end;
    // Set Length
    Cnt := 0;
    for I := 0 to Length(aTeamDefPos) - 1 do
      Inc(Cnt, Length(aTeamDefPos[I].DefPosArr)*Length(aTeamDefPos[I].Owners));
    SetLength(DefEval,Cnt);
    // Evaluate defences (price of each defence depends on potential owner)
    Cnt := 0;
    for I := 0 to Length(aTeamDefPos) - 1 do
      with aTeamDefPos[I] do
        for K := 0 to Length(DefPosArr) - 1 do
        begin
          PolyIdx := DefPosArr[K].Polygon;
          Line := DefPosArr[K].Line;
          Point := DefPosArr[K].DirPoint.Loc;
          DefPosArr[K].Weight := 0; // Mark defence as available
          for IdxPL := 0 to Length(Owners) - 1 do
          begin
            DefEval[Cnt].Owner := Owners[IdxPL];
            DefEval[Cnt].Val := + 64000 // Base price
                                + gAIFields.Influences.OwnPoly[Owners[IdxPL], PolyIdx] // Max + 255
                                - KMDistanceAbs(CenterPoints[IdxPL], Point) * DISTANCE_PRICE
                                - Line * FRONT_LINE_PRICE;
            DefEval[Cnt].DefPos := @DefPosArr[K];
            Inc(Cnt);
          end;
        end;
    if (Length(DefEval) > 0) then
    begin
      // Sort by evaluation
      SortCustom(DefEval[0], Low(DefEval), Cnt-1, SizeOf(DefEval[0]), CompareDef);
      // Prepare output array
      for I := 0 to Length(aOwners) - 1 do
        with DistributedPos[ aOwners[I] ] do
        begin
          Count := 0;
          SetLength(DefPos, aDefPosReq[I]);
        end;
      // Split defences between players
      for I := Length(DefEval) - 1 downto 0 do
        if (DefEval[I].DefPos^.Weight = 0) then
          with DistributedPos[ DefEval[I].Owner ] do
            if (Count < Length(DefPos)) then
            begin
              DefEval[I].DefPos^.Weight := Max(0, DefEval[I].Val - gAIFields.Influences.GetBestAllianceOwnership(DefEval[I].Owner, DefEval[I].DefPos.Polygon, atAlly) * 50); // Copy price for defense but try to keep soldier out of ally city
              DefPos[ Count ] := DefEval[I].DefPos;
              Inc(Count);
            end;
      // Send defences to owner
      for I := 0 to Length(aOwners) - 1 do
        with gHands[ aOwners[I] ] do
          if IsComputer AND AI.Setup.NewAI AND AI.Setup.AutoDefend then
            AI.ArmyManagement.Defence.UpdateDefences(DistributedPos[ aOwners[I] ].Count, DistributedPos[ aOwners[I] ].DefPos);
    end;
  end;

const
  RESERVE_DEF_POS = 5;
var
  IdxPL,Troops: Integer;
  DefPosReq: TKMWordArray;
  TeamDefPos: TKMTeamDefPos;
begin
  if NewAIInTeam(aTeam, False, True) AND (Length(fAlli2PL) > 1) then
  begin
    SetLength(DefPosReq, Length( fAlli2PL[aTeam] ) );
    for IdxPL := 0 to Length(DefPosReq) - 1 do
      with gHands[ fAlli2PL[aTeam, IdxPL] ] do
      begin
        Troops := Byte(IsComputer) * (Stats.GetUnitQty(utRecruit) + Stats.GetArmyCount); // Consider also recruits so after peace time the AI already have prepared defences
        DefPosReq[IdxPL] := Round(Troops / 8) + RESERVE_DEF_POS; // Each group have 9 troops so we need max (Troops / 9) positions + reserves
      end;
    SetLength(TeamDefPos,0);
    gAIFields.NavMesh.Defences.FindTeamDefences(fAlli2PL[aTeam], DefPosReq, TeamDefPos);
    DivideDefences(fAlli2PL[aTeam], DefPosReq, TeamDefPos);
  end;
end;


procedure TKMSupervisor.DivideResources();
  function FindAndDivideMines(var aPlayers: TKMHandIDArray; var aMines: TKMPointArray): TKMWordArray;
  const
    MAX_INFLUENCE = 256;
  var
    K, IdxPL, IdxPL2, Cnt, PLCnt, BestPrice: Integer;
    PL: TKMHandID;
    PLMines,PLPossibleMines: TKMWordArray;
    Mines: TKMMineEvalArr;
  begin
    SetLength(Result, 0);
    // Init
    SetLength(PLMines, Length(aPlayers));
    SetLength(PLPossibleMines, Length(aPlayers));
    FillChar(PLMines[0], SizeOf(PLMines[0]) * Length(PLMines), #0);
    FillChar(PLPossibleMines[0], SizeOf(PLPossibleMines[0]) * Length(PLPossibleMines), #0);
    // Get only mines in influence of alliance
    Cnt := 0;
    SetLength(Mines, Length(aMines));
    for K := High(aMines) downto 0 do
    begin
      // Evaluate point if there can be mine (in dependence on influence)
      PL := gAIFields.Influences.GetBestOwner(aMines[K].X,aMines[K].Y);
      for IdxPL := 0 to High(aPlayers) do
        if (PL = aPlayers[IdxPL]) then
        begin
          PLCnt := 0;
          for IdxPL2 := 0 to High(aPlayers) do // Mark players which can place mine here (by influence)
            if (gAIFields.Influences.OwnPoint[aPlayers[IdxPL2], aMines[K]] > 0) then
            begin
              Inc(PLPossibleMines[IdxPL2]);
              Inc(PLCnt);
            end;
          Mines[Cnt].Val := PLCnt * MAX_INFLUENCE + gAIFields.Influences.OwnPoint[PL, aMines[K]];
          Mines[Cnt].pPoint := @aMines[K];
          Inc(Cnt);
        end;
    end;
    if (Cnt > 0) then
    begin
      // Sort mines by evaluation
      SortCustom(Mines[0], Low(Mines), Cnt-1, SizeOf(Mines[0]), CompareMines);
      // Distribute mines by evaluation and possible mine cnt per a player
      for K := 0 to Cnt - 1 do // Lower index = less players can own this mine
      begin
        IdxPL2 := 0;
        BestPrice := High(Word);
        for IdxPL := 0 to High(aPlayers) do
          if (gAIFields.Influences.OwnPoint[aPlayers[IdxPL], Mines[K].pPoint^] > 0)
            AND (PLPossibleMines[IdxPL] + PLMines[IdxPL] < BestPrice) then
          begin
            BestPrice := PLPossibleMines[IdxPL] + PLMines[IdxPL];
            IdxPL2 := IdxPL;
          end;
        if (BestPrice <> High(Word)) then
        begin
          Inc(PLMines[IdxPL2]);
          // Decrease possible mine cnt
          for IdxPL2 := 0 to High(aPlayers) do
            if (gAIFields.Influences.OwnPoint[aPlayers[IdxPL2], Mines[K].pPoint^] > 0) then
              Dec(PLPossibleMines[IdxPL2]);
        end;
      end;
    end;
    Result := PLMines;
  end;
var
  Alli, IdxPL: Integer;
  MineCnt: TKMWordArray;
  GoldMines, IronMines: TKMPointArray;
begin
  IronMines := gAIFields.Eye.FindSeparateMineLocs(True, htIronMine);
  GoldMines := gAIFields.Eye.FindSeparateMineLocs(True, htGoldMine);
  for Alli := 0 to Length(fAlli2PL) - 1 do
  begin
    MineCnt := FindAndDivideMines(fAlli2PL[Alli], IronMines);
    if (Length(MineCnt) > 0) then
      for IdxPL := 0 to Length(fAlli2PL[Alli]) - 1 do
        gHands[ fAlli2PL[Alli,IdxPL] ].AI.CityManagement.Predictor.IronMineCnt := MineCnt[IdxPL];
    MineCnt := FindAndDivideMines(fAlli2PL[Alli], GoldMines);
    if (Length(MineCnt) > 0) then
      for IdxPL := 0 to Length(fAlli2PL[Alli]) - 1 do
        gHands[ fAlli2PL[Alli,IdxPL] ].AI.CityManagement.Predictor.MaxGoldMineCnt := MineCnt[IdxPL];
  end;
end;


function TKMSupervisor.LogStatus(): UnicodeString;
const
  STR_COLOR_WHITE = '[$FFFFFF]';
  STR_COLOR_RED = '[$0000FF]';
var
  Team, SelectedTeam, K: Integer;
  Color: Cardinal;
  Power: Single;
  PL,PL2, Cnt: TKMHandID;
  CombatStatusText: UnicodeString;
begin
  Result := '';
  if not OVERLAY_AI_SUPERVISOR then
    Exit;
  SelectedTeam := -1;
  if (gMySpectator.HandID <> HAND_NONE) then
    SelectedTeam := fPL2Alli[ gMySpectator.HandID ];
  // Head
  Cnt := 0;
  for PL := 0 to gHands.Count-1 do
    Cnt := Cnt + Byte(gHands[PL].Enabled);
  Result := Format('Supervisor (%sFFA = %d%s; Teams = %d; Players = %d)',[STR_COLOR_RED, Byte(fFFA), STR_COLOR_WHITE, Length(fAlli2PL), Cnt]);

  // Diplomacy + combat status
  for Team := Low(fAlli2PL) to High(fAlli2PL) do
  begin
    Result := Format('%s|  Team %d: ',[Result,Team]);
    for K := Low(fAlli2PL[Team]) to High(fAlli2PL[Team]) do
    begin
      PL := Alli2PL[Team,K];
      if not gHands[ Alli2PL[Team,K] ].AI.Setup.NewAI then
        Result := Format('%s[$%s] PL %s %d (%d;%d), ',[Result,IntToHex(gHands[PL].FlagColor AND $FFFFFF,6),STR_COLOR_WHITE,PL,Byte(gHands[PL].Enabled),Byte(not HasAssets(PL))]);
    end;
    if (SelectedTeam = Team) then
    begin
      Result := Format('%s SELECTED TEAM',[Result]);
      if gAIFields.Eye.ArmyEvaluation.CheckFoodProblems(fAlli2PL[Team]) then
        Result := Format('%s %sFOOD PROBLEMS%s',[Result, STR_COLOR_RED, STR_COLOR_WHITE]);
    end
    else if (SelectedTeam <> -1) then
    begin
      Power := gAIFields.Eye.ArmyEvaluation.CompareAllianceStrength(fAlli2PL[SelectedTeam], fAlli2PL[Team]);
      if      (Power < -0.5) then Color := tcRed
      else if (Power < -0.1) then Color := tcFuchsia
      else if (Power < +0.1) then Color := tcWhite
      else if (Power < +0.5) then Color := tcTeal
      else                        Color := tcGreen;
      Result := Format('%s [$%s]Power = %.2f%s',[Result, IntToHex(Color,6), Power, STR_COLOR_WHITE]);
    end;
    for K := Low(fAlli2PL[Team]) to High(fAlli2PL[Team]) do
      if gHands[ Alli2PL[Team,K] ].AI.Setup.NewAI then
      begin
        PL := Alli2PL[Team,K];
        Result := Format('%s|    [$%s] NewAI %s %d (E %d; D: %d)',[Result,IntToHex(gHands[PL].FlagColor AND $FFFFFF,6),STR_COLOR_WHITE,PL,Byte(gHands[PL].Enabled),Byte(not HasAssets(PL))]);
        for PL2 := Low(fCombatStatus[PL]) to High(fCombatStatus[PL]) do
          if (PL <> PL2) then
          begin
            case fCombatStatus[PL,PL2] of
              csNeutral:              Continue;
              csDefending:            CombatStatusText := 'def';
              csCounterattack:        CombatStatusText := 'count att';
              csAttackingCity:        CombatStatusText := 'att city';
              csAttackingEverything:  CombatStatusText := 'att all';
            end;
            Result := Format('%s [$%s] %s %s %d,',[Result,IntToHex(gHands[PL2].FlagColor AND $FFFFFF,6),CombatStatusText,STR_COLOR_WHITE,PL2]);
          end;
      end;
  end;
  Result := Format('%s|%s',[Result, fArmyVector.LogStatus()]);
  {$IFDEF DEBUG_Supervisor}
    if (gMySpectator.Selected is TKMUnitGroup) then
      for K := 0 to Length(fArmyAttackDebug.Groups) - 1 do
        if (TKMUnitGroup(gMySpectator.Selected) = fArmyAttackDebug.Groups[K]) then
          with fArmyAttackDebug.Threat[K] do
          begin
            Result := Format('%s||Selected unit:|  Distance ranged = %f;|  Distance = %f;|  Risk = %f;|  Weighted count = %f;',[Result, DistRanged, Distance, Risk, WeightedCount]);
            Break;
          end;
  {$ENDIF}
end;


procedure TKMSupervisor.Paint(aRect: TKMRect);
{$IFDEF DEBUG_Supervisor}
  var
    Owner: TKMHandID;
    InRange: Boolean;
    K, L, M, PL: Integer;
    MaxThreat,MinThreat: Single;
    G: TKMUnitGroup;
    CG: TKMCombatGroup;
{$ENDIF}
begin
  //EvaluateArmies();

  {$IFDEF DEBUG_ArmyVectorField}
    fArmyVector.Paint();
  {$ENDIF}

  if not OVERLAY_AI_SUPERVISOR then
    Exit;

  {$IFDEF DEBUG_Supervisor}
    Owner := gMySpectator.HandID;
    if (Owner = HAND_NONE) then
      Exit;

    MaxThreat := -1E10;
    MinThreat := +1E10;
    for K := 0 to Length(fArmyAttackDebug.Threat) - 1 do
    begin
      MaxThreat := Max(MaxThreat,fArmyAttackDebug.Threat[K].Risk);
      MinThreat := Min(MinThreat,fArmyAttackDebug.Threat[K].Risk);
    end;
    with fCombatStatusDebug do
      if (MaxThreat <> 0) then
        for K := Low(TargetGroups[Owner]) to High(TargetGroups[Owner]) do
          for PL := 0 to gHands.Count - 1 do
            if (gHands[Owner].Alliances[PL] = atEnemy) then
              for L := 0 to gHands[PL].UnitGroups.Count - 1 do
                if (TargetGroups[Owner,K] = gHands[PL].UnitGroups.Groups[L]) then
                begin
                  InRange := False;
                  for M := 0 to Length(fArmyAttackDebug.Groups) - 1 do
                    if (TargetGroups[Owner,K] = fArmyAttackDebug.Groups[M]) then
                    begin
                      G := TargetGroups[Owner,K];
                      gRenderAux.CircleOnTerrain(G.Position.X, G.Position.Y, 0.5, (Round(255 - (fArmyAttackDebug.Threat[M].Risk-MinThreat)/(MaxThreat-MinThreat)*220) shl 24) OR tcRed, $11FFFFFF);
                      InRange := True;
                      break;
                    end;
                  if not InRange then
                    with fCombatStatusDebug.TargetGroups[Owner,K].Position do
                      gRenderAux.CircleOnTerrain(X, Y, 1, $10FFFFFF, $FFFFFFFF);
                end;

    if (gMySpectator.Selected is TKMUnitGroup) then
    begin
      G := TKMUnitGroup(gMySpectator.Selected);
      for PL := 0 to gHands.Count - 1 do
        if (gHands[G.Owner].Alliances[PL] = atEnemy) AND gHands[PL].AI.Setup.NewAI then
          for K := 0 to gHands[PL].AI.ArmyManagement.AttackNew.Count - 1 do
          begin
            CG := gHands[PL].AI.ArmyManagement.AttackNew.CG[K];
            if (G = CG.TargetGroup) then
              gRenderAux.Line(CG.Position.X, CG.Position.Y, G.Position.X, G.Position.Y, $FF000000 OR tcRed);
          end;
    end;
  {$ENDIF}
end;


{
procedure TKMSupervisor.EvaluateArmies();
type
  TKMPGroupEvalSup = ^TKMGroupEvalSup;
  TKMGroupEvalSup = record
    Aggressive: Single;
    Own, Nearby: TKMGroupEval;
    Group, HostileGroup: TKMUnitGroup;
    pHostileGroup: TKMPGroupEvalSup;
  end;
const
  LIM_INFLUENCE = 1/255;
  LIM_CLOSEST = 15;
  LIM_AGGRESSIVE = 0.5;
  DIST_TOLERANCE = 8;
var
  X,Y: Integer;
  Alli, Enemy, IdxPL, GIdx, GIdx2, GCnt, K, Closest, Distance: Integer;
  Dist: Single;
  P: TKMPoint;
  PL: TKMHandID;
  GE: TKMGroupEval;
  A: array of array of TKMGroupEvalSup;
  Time: Cardinal;
begin
  Time := TimeGet();
  // Compute strength of groups
  SetLength(A,Length(fAlli2PL));
  for Alli := Low(fAlli2PL) to High(fAlli2PL) do
  begin
    GCnt := 0;
    for IdxPL := Low(fAlli2PL[Alli]) to High(fAlli2PL[Alli]) do
      GCnt := GCnt + gHands[ fAlli2PL[Alli,IdxPL] ].UnitGroups.Count;
    if (GCnt <= 0) then
      Continue;
    SetLength(A[Alli], GCnt);
    FillChar(A[Alli,0], SizeOf(TKMGroupEval)*GCnt, #0);
    GIdx := 0;
    for IdxPL := Low(fAlli2PL[Alli]) to High(fAlli2PL[Alli]) do
    begin
      PL := fAlli2PL[Alli,IdxPL];
      for K := 0 to gHands[PL].UnitGroups.Count - 1 do
      begin
        A[Alli,GIdx].Group := gHands[PL].UnitGroups[K];
        A[Alli,GIdx].Own := gAIFields.Eye.ArmyEvaluation.GroupEvaluation(A[Alli,GIdx].Group,True);
        Inc(GIdx);
      end;
    end;
  end;
  for Alli := Low(A) to High(A) do
  begin
    // Spread influence of each group to surrounding groups
    for GIdx := Low(A[Alli]) to High(A[Alli]) do
    begin
      for GIdx2 := Low(A[Alli]) to High(A[Alli]) do
        if (GIdx2 <> GIdx) then
        begin
          Dist := 1 / Max(KMDistanceAbs(A[Alli,GIdx].Group.Position,A[Alli,GIdx2].Group.Position) - DIST_TOLERANCE,1);
          if (Dist > 0.1) then
            with A[Alli,GIdx].Nearby do
            begin
              Attack             := Attack             + A[Alli,GIdx2].own.Attack             * Dist;
              AttackHorse        := AttackHorse        + A[Alli,GIdx2].own.AttackHorse        * Dist;
              Defence            := Defence            + A[Alli,GIdx2].own.Defence            * Dist;
              DefenceProjectiles := DefenceProjectiles + A[Alli,GIdx2].own.DefenceProjectiles * Dist;
              HitPoints          := HitPoints          + A[Alli,GIdx2].own.HitPoints          * Dist;
            end;
        end;
      // Compute Aggressivity of all groups = group is close to hostile unit or house
      P := A[Alli,GIdx].Group.Position;
      A[Alli,GIdx].Aggressive := gAIFields.Influences.GetBestAllianceOwnership(A[Alli,GIdx].Group.Owner,P.X,P.Y,atEnemy) * LIM_INFLUENCE;
      Closest := High(Integer);
      for Enemy := Low(A) to High(A) do
        if (Alli <> Enemy) then
          for GIdx2 := Low(A[Enemy]) to High(A[Enemy]) do
          begin
            Distance := KMDistanceAbs(P,A[Enemy,GIdx2].Group.Position);
            if (Distance < Closest) then
            begin
              Closest := Distance;
              A[Alli,GIdx].pHostileGroup := @A[Enemy,GIdx2];
            end;
          end;
      if (Closest < LIM_CLOSEST) then
        A[Alli,GIdx].Aggressive := A[Alli,GIdx].Aggressive + 1 / Max(1,Closest - LIM_CLOSEST);
    end;
  end;

  // Detect problematic groups
  for Alli := Low(A) to High(A) do
  begin
    for Enemy := Low(A) to High(A) do
      if (Enemy <> Alli) then
        for GIdx := Low(A[Enemy]) to High(A[Enemy]) do
          if (A[Enemy,GIdx].Aggressive > LIM_AGGRESSIVE) then
          begin

          end;
    break; // DEBUG
  end;

  Time := TimeGet() - Time;

  for Alli := Low(A) to High(A) do
    for GIdx := Low(A[Alli]) to High(A[Alli]) do
    begin
      P := A[Alli,GIdx].Group.Position;
      //gRenderAux.Quad(P.X, P.Y, $FF000000 OR tcRed);
      //gRenderAux.LineOnTerrain(Company.PointPath[K+1], Company.PointPath[K], $60000000 OR tcYellow);
      //gRenderAux.Line(P.X-0.5, P.Y-1, P.X-0.5, P.Y-1-A[Alli,GIdx].Attack/100, $FF000000 OR tcBlack);
      // Strenght
      gRenderAux.Triangle(P.X-1.5, P.Y, P.X-1.25, P.Y-A[Alli,GIdx].Own.Attack           /200, P.X-1.0, P.Y, $55000000 OR tcRed);
      gRenderAux.Triangle(P.X-1.5, P.Y, P.X-1.25, P.Y-A[Alli,GIdx].Own.AttackHorse      /200, P.X-1.0, P.Y, $AA000000 OR tcRed);
      gRenderAux.Triangle(P.X-1.0, P.Y, P.X-0.75, P.Y-A[Alli,GIdx].Own.Defence           /10, P.X-0.5, P.Y, $AA000000 OR tcBlue);
      gRenderAux.Triangle(P.X-1.0, P.Y, P.X-0.75, P.Y-A[Alli,GIdx].Own.DefenceProjectiles/10, P.X-0.5, P.Y, $55000000 OR tcBlue);
      gRenderAux.Triangle(P.X-0.5, P.Y, P.X-0.25, P.Y-A[Alli,GIdx].Own.HitPoints         /10, P.X-0.0, P.Y, $AA000000 OR tcGreen);
      // Influence
      gRenderAux.Triangle(P.X+0.0, P.Y, P.X+0.25, P.Y-A[Alli,GIdx].Nearby.Attack           /200, P.X+0.5, P.Y, $22000000 OR tcRed);
      gRenderAux.Triangle(P.X+0.0, P.Y, P.X+0.25, P.Y-A[Alli,GIdx].Nearby.AttackHorse      /200, P.X+0.5, P.Y, $55000000 OR tcRed);
      gRenderAux.Triangle(P.X+0.5, P.Y, P.X+0.75, P.Y-A[Alli,GIdx].Nearby.Defence           /10, P.X+1.0, P.Y, $55000000 OR tcBlue);
      gRenderAux.Triangle(P.X+0.5, P.Y, P.X+0.75, P.Y-A[Alli,GIdx].Nearby.DefenceProjectiles/10, P.X+1.0, P.Y, $22000000 OR tcBlue);
      gRenderAux.Triangle(P.X+1.0, P.Y, P.X+1.25, P.Y-A[Alli,GIdx].Nearby.HitPoints         /10, P.X+1.5, P.Y, $55000000 OR tcGreen);
    end;
end;
//}

end.
