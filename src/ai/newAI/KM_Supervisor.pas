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
  KM_NavMeshDefences, KM_NavMeshInfluences, KM_NavMeshArmyPositioning, KM_ArmyManagement, KM_AIArmyEvaluation,
  KM_ArmyAttackNew,
  KM_Houses, KM_ResHouses, KM_Sort;

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
  TKMHandID2Arr = array of TKMHandIDArray;

  TKMCombatStatus = (csNeutral = 0, csDefending, csAttackingCity, csAttackingEverything);
  TKMCombatStatusArray = array[0..MAX_HANDS-1,0..MAX_HANDS-1] of TKMCombatStatus;

// Supervisor <-> agent relation ... cooperating AI players are just an illusion, agents does not see each other
  TKMSupervisor = class
  private
    fFFA: Boolean;
    fPL2Alli: TKMHandByteArr;
    fAlli2PL: TKMHandID2Arr;
    fCombatStatus: TKMCombatStatusArray;
    fArmyPos: TArmyForwardFF;

    procedure UpdateFFA();
    function UpdateCombatStatus(aTeam: Byte; var E: TKMUnitGroupArray; var H: TKMHouseArray): TKMCombatStatus;
    procedure UpdateDefPos(aTeam: Byte);
    procedure UpdateAttack(aTeam: Byte);
    procedure DivideResources();
    function GetInitPoints(var aPlayers: TKMHandIDArray): TKMPointArray;
    function IsNewAI(aID: TKMHandID): Boolean;
    function NewAIInTeam(aTeam: Byte; aAttack, aDefence: Boolean): Boolean;
    //procedure EvaluateArmies();

    procedure UpdateAttacks(aTeam: Byte; aTick: Cardinal);
    function EvalTarget(aAttack: Boolean; var A, E: TKMUnitGroupArray; var H: TKMHouseArray): TKMUnitGroupArray;
  public
    constructor Create();
    destructor Destroy(); override;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

    property PL2Alli: TKMHandByteArr read fPL2Alli;
    property Alli2PL: TKMHandID2Arr read fAlli2PL;
    property CombatStatus: TKMCombatStatusArray read fCombatStatus;
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
  KM_Game, KM_HandsCollection, KM_Hand,
  KM_AIFields, KM_CommonUtils, KM_AIParameters;

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
begin
  fArmyPos := TArmyForwardFF.Create(True);
  FillChar(fCombatStatus,SizeOf(fCombatStatus),#0);
end;

destructor TKMSupervisor.Destroy();
begin
  fArmyPos.Free;
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
    AND (  (gGame.MissionMode = mmTactic) OR (aTick > (gGame.GameOptions.Peacetime+3) * 10 * 60)  ) then // In normal mode wait 3 minutes after peace
    begin
      UpdateFFA();
      UpdateAttack(Modulo - ATTACKS);
    end;
    Modulo := (aTick mod MAX_HANDS);
    if (Modulo < Length(fAlli2PL)) then
      UpdateAttacks(Modulo,aTick);
  end;
end;



function TKMSupervisor.UpdateCombatStatus(aTeam: Byte; var E: TKMUnitGroupArray; var H: TKMHouseArray): TKMCombatStatus;
  procedure AddEnemy(aG: TKMUnitGroup; var aCnt: Integer; var aEnemyIsClose: Boolean);
  var
    K: Integer;
  begin
    aEnemyIsClose := True;
    for K := 0 to aCnt - 1 do
      if (E[K] = aG) then
        Exit;
    E[aCnt] := aG;
    Inc(aCnt);
  end;
  procedure AddHouse(aH: TKMHouse; var aCnt: Integer; var aHouseIsClose: Boolean);
  var
    K: Integer;
  begin
    aHouseIsClose := True;
    for K := 0 to aCnt - 1 do
      if (H[K] = aH) then // Should not happen for houses
        Exit;
    H[aCnt] := aH;
    Inc(aCnt);
  end;
const
  SQR_DANGEROUS_DISTANCE = 15*15;
  SQR_OFFENSIVE_DISTANCE = 30*30;
  INFLUENCE_THRESHOLD = 1;
  ARMY_IN_HOSTILE_CITY = 200;
  TARGET_HOUSE_IN_INFLUENCE = 150;
var
  InCombat, HouseIsClose, EnemyIsClose: Boolean;
  PL: TKMHandID;
  CS: TKMCombatStatus;
  Idx, K, L, CntH, CntE: Integer;
  SelectedDistance: Single;
  P: TKMPoint;
  G: TKMUnitGroup;
  House: TKMHouse;
  Owner: TKMHandID;
begin
  Result := csNeutral;
  // Check if team have newAI
  if not NewAIInTeam(aTeam, False, False) OR (SP_OLD_ATTACK_AI = True) then
    Exit;
  CntH := 0;
  CntE := 0;
  for Idx := 0 to Length(fAlli2PL[aTeam]) - 1 do
  begin
    Owner := fAlli2PL[aTeam,Idx];
    CS := csNeutral;
    InCombat := gHands[Owner].AI.ArmyManagement.AttackNew.Count > 0;
    for PL := 0 to gHands.Count - 1 do
    begin
      if (gHands[Owner].Alliances[PL] = atEnemy) then
      begin
        // Check if units are closer to enemy city and if so, then change status to attacker
        if (fCombatStatus[Owner,PL] in [csNeutral, csDefending]) then
        begin
          for K := 0 to gHands[Owner].UnitGroups.Count - 1 do
          begin
            G := gHands[Owner].UnitGroups.Groups[K];
            if (G <> nil) AND not G.IsDead AND (gAIFields.Influences.OwnPoint[ PL, G.Position ] > ARMY_IN_HOSTILE_CITY) then
            begin
              fCombatStatus[Owner,PL] := csAttackingCity;
              break;
            end;
          end;
        end;

        // All combat groups are dead
        if not InCombat AND not gHands[Owner].AI.ArmyManagement.AttackRequest.Active then
          fCombatStatus[Owner,PL] := csNeutral;

        // Find all hostile houses (only if player attacking someone)
        HouseIsClose := False;
        if (fCombatStatus[Owner,PL] in [csAttackingCity, csAttackingEverything]) then
        begin
          if (CntH + gHands[PL].Houses.Count >= Length(H)) then
            SetLength(H, Length(H) + gHands[PL].Houses.Count);
          for K := 0 to gHands[PL].Houses.Count - 1 do
          begin
            House := gHands[PL].Houses[K];
            if (House <> nil) AND not House.IsDestroyed AND (
              ((House.HouseType in TARGET_HOUSES) AND House.IsComplete)
              OR
              (gAIFields.Influences.OwnPoint[ Owner, House.Position ] > TARGET_HOUSE_IN_INFLUENCE)
            ) then
              AddHouse(House,CntH,HouseIsClose);
          end;
        end;

        // Find all hostile groups
        EnemyIsClose := False;
        // Select scan distance (it is based on combat status so AIs in the FFA do not get mad)
        SelectedDistance := SQR_DANGEROUS_DISTANCE;
        if (fCombatStatus[Owner,PL] = csAttackingCity) then
          SelectedDistance := SQR_OFFENSIVE_DISTANCE
        else if (fCombatStatus[Owner,PL] = csAttackingEverything) then
          SelectedDistance := 1E10;
        if (CntE + gHands[PL].UnitGroups.Count >= Length(E)) then
          SetLength(E, Length(E) + gHands[PL].UnitGroups.Count);
        for K := 0 to gHands[PL].UnitGroups.Count - 1 do
        begin
          G := gHands[PL].UnitGroups.Groups[K];
          if (G <> nil) AND not G.IsDead then
          begin
            P := G.Position;
            if (gAIFields.Influences.OwnPoint[ Owner, P ] > INFLUENCE_THRESHOLD) then
              AddEnemy(G, CntE, EnemyIsClose)
            else
              for L := 0 to gHands[Owner].UnitGroups.Count - 1 do
                if (KMDistanceSqr(gHands[Owner].UnitGroups.Groups[L].Position,P) < SelectedDistance) then
                begin
                  AddEnemy(G, CntE, EnemyIsClose);
                  break;
                end;
          end;
        end;
        fCombatStatus[Owner,PL] := TKMCombatStatus(  Byte(HouseIsClose OR EnemyIsClose) * Max( Byte(fCombatStatus[Owner,PL]), Byte(csDefending) )  );
        CS := TKMCombatStatus(  Max( Byte(CS), Byte(fCombatStatus[Owner,PL]) )  );
        Result := TKMCombatStatus(  Max( Byte(fCombatStatus[Owner,PL]), Byte(Result) )  );
      end;
      fCombatStatus[Owner,Owner] := CS; // Overall combat status of player
    end;
  end;
  SetLength(H,CntH);
  SetLength(E,CntE);
end;





function TKMSupervisor.EvalTarget(aAttack: Boolean; var A, E: TKMUnitGroupArray; var H: TKMHouseArray): TKMUnitGroupArray;

  function GetIdx(aLen, aA, aE: Integer): Integer; inline;
  begin
    Result := aLen * aA + aE;
  end;

const
  NO_THREAT = -1E6;
  sqr_INTEREST_DISTANCE_House = 20*20;
  sqr_MAX_DISTANCE_FROM_HOUSE = 10*10;
  MAX_ATTACKERS_PER_HOUSE = 12;
  WarriorPrice: array [utMilitia..utHorseman] of Single = (
    1.5,2.0,2.5,2.0,2.5, // utMilitia,utAxeFighter,utSwordsman,utBowman,utArbaletman,
    2.0,2.5,2.0,2.5,     // utPikeman,utHallebardman,utHorseScout,utCavalry
    2.5,1.5,1.5,2.5,1.5  // utBarbarian,utPeasant,utSlingshot,utMetalBarbarian,utHorseman
  );
  ThreatGain: array [TKMGroupType] of Single = (
  // gtMelee, gtAntiHorse, gtRanged, gtMounted
         0.5,         1.0,      3.0,       3.0
  );
  OportunityArr: array [TKMGroupType,TKMGroupType] of Single = (
  // gtMelee, gtAntiHorse, gtRanged, gtMounted
    (    1.0,         2.0,      3.0,       0.5), // gtMelee
    (    0.5,         1.0,      2.0,       4.0), // gtAntiHorse
    (    1.0,         2.0,      3.0,       0.5), // gtRanged
    (    1.0,         0.2,      5.0,       1.0)  // gtMounted
  );

var
  IdxA,IdxE, CntA, CntE, Overflow, Overflow2, BestIdxE, BestIdxA: Integer;
  SqrDistFromRanged, SqrDist, BestSqrDistFromRanged, BestSqrDist, BestThreat, Opportunity, BestOpportunity: Single;
  G: TKMUnitGroup;
  CG: TKMCombatGroup;
  U: TKMUnit;
  UW: TKMUnitWarrior;
  TargetH: TKMHouse;
  Dist: array of Single;
  Threat: array of record
    DistRanged, Distance, Risk, WeightedCount: Single;
  end;
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
      TargetH := A[IdxA].OrderTargetHouse;
      if (TargetH <> nil) AND (A[IdxA].GroupType <> gtRanged) AND (KMDistanceSqr(A[IdxA].Position,TargetH.Entrance) < sqr_MAX_DISTANCE_FROM_HOUSE) then
        for IdxE := 0 to Length(H) - 1 do
          if (H[IdxE] = TargetH) then
          begin
            Inc(AttackingHouseCnt[IdxE],A[IdxA].Count);
            Dec(CntA);
            A[IdxA] := A[CntA];
            break;
          end;
    end;
  end;

  if aAttack AND (Length(E) > 0) then
  begin

    // Set orders for ranged groups (the closest enemy, top prio)
    for IdxA := CntA - 1 downto 0 do
      if (A[IdxA].GroupType = gtRanged) then
      begin
        U := gTerrain.UnitsHitTestWithinRad(A[IdxA].Position, 0.5, A[IdxA].GetAliveMember.GetFightMaxRange(True), A[IdxA].Owner, atEnemy, dirNA, True);
        if (U is TKMUnitWarrior) then
        begin
          CG := gHands[ A[IdxA].Owner ].AI.ArmyManagement.AttackNew.CombatGroup[ A[IdxA] ];
          CG.TargetGroup := TKMUnitWarrior(U).Group;
          Dec(CntA);
          A[IdxA] := A[CntA];
        end;
      end;


    // Compute distances
    SetLength(Dist, Length(A)*Length(E));
    for IdxA := 0 to CntA - 1 do
    for IdxE := 0 to CntE - 1 do
      Dist[ GetIdx(CntE,IdxA,IdxE) ] := KMDistanceSqr(A[IdxA].Position,E[IdxE].Position);

    // Compute threat
    SetLength(Threat, Length(E));
    for IdxE := 0 to CntE - 1 do
    begin
      Threat[IdxE].Distance := 1E6;
      Threat[IdxE].DistRanged := 1E6;
      for IdxA := Low(A) to High(A) do
        if (A[IdxA].GroupType = gtRanged) AND (Dist[ GetIdx(CntE,IdxA,IdxE) ] < Threat[IdxE].DistRanged) then
          Threat[IdxE].DistRanged := Dist[ GetIdx(CntE,IdxA,IdxE) ]
        else if (Dist[ GetIdx(CntE,IdxA,IdxE) ] < Threat[IdxE].Distance) then
          Threat[IdxE].Distance := Dist[ GetIdx(CntE,IdxA,IdxE) ];
      UW := E[IdxE].GetAliveMember;
      Threat[IdxE].WeightedCount := E[IdxE].Count * WarriorPrice[UW.UnitType];
      case E[IdxE].GroupType of // + City influence - Group in combat
        gtMelee:     Threat[IdxE].Risk := Threat[IdxE].WeightedCount * GA_ATTACK_SUPERVISOR_EvalTarget_ThreatGainMelee;
        gtAntiHorse: Threat[IdxE].Risk := Threat[IdxE].WeightedCount * GA_ATTACK_SUPERVISOR_EvalTarget_ThreatGainAntiHorse;
        gtRanged:    Threat[IdxE].Risk := Threat[IdxE].WeightedCount * GA_ATTACK_SUPERVISOR_EvalTarget_ThreatGainRanged;
        gtMounted:   Threat[IdxE].Risk := Threat[IdxE].WeightedCount * GA_ATTACK_SUPERVISOR_EvalTarget_ThreatGainMounted;
      end;
      Threat[IdxE].Risk := Threat[IdxE].Risk + Threat[IdxE].DistRanged * GA_ATTACK_SUPERVISOR_EvalTarget_ThreatGainRangDist + Threat[IdxE].Distance * GA_ATTACK_SUPERVISOR_EvalTarget_ThreatGainDist;
    end;

    // Set targets
    // Archers - higher distance
    for IdxA := 0 to CntA - 1 do
      if (A[IdxA].GroupType = gtRanged) then
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
          CG := gHands[ A[IdxA].Owner ].AI.ArmyManagement.AttackNew.CombatGroup[ A[IdxA] ];
          CG.TargetGroup := E[BestIdxE];
          // Remove group from selection
          A[IdxA] := nil;
        end;
      end;
    // Melee
    Overflow := 0;
    while (Overflow < Length(E)) do
    begin
      Inc(Overflow);
      BestThreat := NO_THREAT;
      for IdxE := Low(Threat) to High(Threat) do
        if (Threat[IdxE].Risk > BestThreat) then
        begin
          BestIdxE := IdxE;
          BestThreat := Threat[IdxE].Risk;
        end;
      if (BestThreat <= NO_THREAT) then
        break;

      with Threat[BestIdxE] do
      begin
        Overflow2 := 0;
        while (WeightedCount > 0) AND (Min(DistRanged, Distance) < sqr(GA_ATTACK_SUPERVISOR_EvalTarget_DistanceGroup)) AND (Overflow2 < 1000) do
        begin
          Inc(Overflow2);
          BestOpportunity := NO_THREAT;
          for IdxA := 0 to CntA - 1 do
            if (A[IdxA] <> nil) then
            begin
              Opportunity := OportunityArr[ A[IdxA].GroupType, E[BestIdxE].GroupType ] * GA_ATTACK_SUPERVISOR_EvalTarget_OportunityGain - Dist[ GetIdx(CntE,IdxA,BestIdxE) ] * GA_ATTACK_SUPERVISOR_EvalTarget_OportunityDistGain;
              if (BestOpportunity < Opportunity) then
              begin
                BestIdxA := IdxA;
                BestOpportunity := Opportunity;
              end;
            end;
          if (BestOpportunity <> NO_THREAT) then
          begin
            // SetOrders
            UW := A[BestIdxA].GetAliveMember;
            // Decrease risk
            WeightedCount := WeightedCount - A[BestIdxA].Count * WarriorPrice[UW.UnitType];
            // Set order
            CG := gHands[ A[BestIdxA].Owner ].AI.ArmyManagement.AttackNew.CombatGroup[ A[BestIdxA] ];
            CG.TargetGroup := E[BestIdxE];
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

  for IdxE := 0 to Length(H) - 1 do
  begin
    Overflow := 0;
    while (AttackingHouseCnt[IdxE] < MAX_ATTACKERS_PER_HOUSE) AND (Overflow < 5) do
    begin
      Inc(Overflow);
      BestOpportunity := abs(NO_THREAT);
      for IdxA := 0 to CntA - 1 do
        if (A[IdxA] <> nil) AND (A[IdxA].GroupType <> gtRanged) then
        begin
          Opportunity := KMDistanceSqr(H[IdxE].Entrance, A[IdxA].Position);
          if (BestOpportunity > Opportunity) AND (Opportunity < sqr_INTEREST_DISTANCE_House) then
          begin
            BestIdxA := IdxA;
            BestOpportunity := Opportunity;
          end;
        end;
      // Set order
      if (BestOpportunity <> abs(NO_THREAT)) then
      begin
        Inc(AttackingHouseCnt[IdxE],A[BestIdxA].Count);
        CG := gHands[ A[BestIdxA].Owner ].AI.ArmyManagement.AttackNew.CombatGroup[ A[BestIdxA] ];
        CG.TargetHouse := H[IdxE];
        A[BestIdxA] := nil;
      end;
    end;
  end;

  Result := A;
end;


procedure TKMSupervisor.UpdateAttacks(aTeam: Byte; aTick: Cardinal);
var
  Ally, Enemy: TKMAllianceInfo; // fAllyGroups, fEnemyGroups
  TL: TKMWordArray; // TargetLines
  TP: TKMPointDirArray; // TargetPositions
  BL: TKMBattleLines; // BattleLines
  CG: array of TKMCombatGroup;

  procedure OrderMove(AG: TKMUnitGroupArray);
  var
    K,L: Integer;
  begin
    for K := Low(AG) to High(AG) do
      if (AG[K] <> nil) then
        for L := Low(CG) to High(CG) do
          if (CG[L] <> nil) AND (AG[K] = CG[L].Group) then
          begin
            CG[L].TargetPosition := TP[L];
            break;
          end;
  end;

  procedure EvaluateEnemy(aAttack: Boolean; var aBattleLine: TKMBattleLine);
  var
    Check: Boolean;
    K, L, Cnt: Integer;
    EG, AG: TKMUnitGroupArray;
    EH: TKMHouseArray;
  begin
    Cnt := 0;
    SetLength(EG, aBattleLine.GroupsCount);
    for K := 0 to aBattleLine.GroupsCount - 1 do
    begin
      EG[Cnt] := Enemy.Groups[ aBattleLine.Groups[K] ];
      Check := True;
      for L := 0 to Cnt - 1 do
        Check := Check AND (EG[L] <> EG[Cnt]);
      Cnt := Cnt + Byte(Check);
    end;
    SetLength(EG, Cnt);

    Cnt := 0;
    SetLength(AG, Ally.GroupsCount);
    for K := Low(CG) to High(CG) do
      if (CG[K] <> nil) then
      begin
        AG[Cnt] := CG[K].Group;
        Check := True;
        for L := 0 to Cnt - 1 do
          Check := Check AND (AG[L] <> AG[Cnt]);
        Cnt := Cnt + Byte(Check);
      end;
    SetLength(AG, Cnt);

    Cnt := 0;
    SetLength(EH, aBattleLine.HousesCount);
    for K := 0 to aBattleLine.HousesCount - 1 do
    begin
      EH[Cnt] := Enemy.Houses[ aBattleLine.Houses[K] ];
      Check := True;
      for L := 0 to Cnt - 1 do
        Check := Check AND (EH[L] <> EH[Cnt]);
      Cnt := Cnt + Byte(Check);
    end;
    SetLength(EH, Cnt);

    AG := EvalTarget(aAttack, AG, EG, EH);
    OrderMove(AG);
  end;

var
  PlayerInCombat, LineInCombat, TeamInCombat: Boolean;
  K, L, Cnt, Ready: Integer;
  CS: TKMCombatStatus;
  EnemyGroups: TKMUnitGroupArray;
  EnemyHouses: TKMHouseArray;
begin
  // Check if team have newAI
  if not NewAIInTeam(aTeam, False, False) OR (SP_OLD_ATTACK_AI = True) then
    Exit;
  // Check if there are hostile units around
  CS := UpdateCombatStatus(aTeam, EnemyGroups, EnemyHouses);
  // Check if hostile units are around specific player (if not release combat groups)
  for K := 0 to Length(fAlli2PL[aTeam]) - 1 do
    if IsNewAI(fAlli2PL[aTeam,K]) then
    begin
      PlayerInCombat := False;
      for L := 0 to Length(fCombatStatus[ fAlli2PL[aTeam,K] ]) - 1 do
        PlayerInCombat := PlayerInCombat OR (fCombatStatus[ fAlli2PL[aTeam,K], L ] <> csNeutral);
      if not PlayerInCombat then
        gHands[ fAlli2PL[aTeam,K] ].AI.ArmyManagement.AttackNew.ReleaseGroups();
    end;
  if (CS = csNeutral) OR ((CS = csDefending) AND (Length(EnemyGroups) <= 0)) then
    Exit;
  // Add everything to defence if AI is defending
  for K := 0 to Length(fAlli2PL[aTeam]) - 1 do
    if IsNewAI(fAlli2PL[aTeam,K]) then
      for L := Low(fCombatStatus) to High(fCombatStatus) do
        if (fCombatStatus[ fAlli2PL[aTeam,K], L ] = csDefending) then
        begin
          with gHands[ fAlli2PL[aTeam,K] ].AI.ArmyManagement do
            AttackNew.AddGroups( Defence.ReleaseAllGroups() );
          break;
        end;
  // Check if team have combat groups
  TeamInCombat := False;
  for K := 0 to Length(fAlli2PL[aTeam]) - 1 do
    TeamInCombat := TeamInCombat OR (gHands[ fAlli2PL[aTeam,K] ].AI.ArmyManagement.AttackNew.Count > 0);
  if not TeamInCombat then
    Exit;
  // Try to find battle line
  if not fArmyPos.FindArmyPosition(fAlli2PL[aTeam], EnemyGroups, EnemyHouses)then
    Exit;

  //{
  // Get army info
  Ally := fArmyPos.Ally;
  //Enemy := fArmyPos.Enemy;
  Enemy := fArmyPos.TargetEnemy;
  TL := fArmyPos.TargetLines;
  TP := fArmyPos.TargetPositions;
  BL := fArmyPos.BattleLines;
  SetLength(CG, Ally.GroupsCount);
  // Check all combat lines
  for K := 0 to BL.Count - 1 do
  begin
    LineInCombat := False;
    Ready := 0;
    Cnt := 0;
    // Check if groups in one combat line are ready for attack
    for L := Low(TL) to High(TL) do
    begin
      CG[L] := nil;
      if (TL[L] = K) then
      begin
        CG[L] := gHands[ Ally.Groups[L].Owner ].AI.ArmyManagement.AttackNew.CombatGroup[ Ally.Groups[L] ];
        if (CG[L] <> nil) then
        begin
          Inc(Cnt);
          Inc(Ready, Byte(CG[L].OnPlace OR fArmyPos.InCombatLine[L] OR (fArmyPos.fInflInfo[ Ally.GroupsPoly[L] ].EnemyInfluence > 0)) );
          LineInCombat := LineInCombat OR (CG[L].CombatPhase = cpAttack);
        end;
      end;
    end;
    // Launch attack or move groups
    EvaluateEnemy((Ready > Cnt * GA_ATTACK_SUPERVISOR_UpdateAttacks_AttackThreshold) OR LineInCombat, BL.Lines[K]);
  end;
  //}
end;


procedure TKMSupervisor.UpdateAlliances();
var
  PL1,PL2: TKMHandID;
  AlliCnt, PLCnt: Byte;
begin
  FillChar(fPL2Alli, SizeOf(fPL2Alli), #255); // TKMHandIndex = SmallInt => Byte(255) = -1 = PLAYER_NONE
  SetLength(fAlli2PL, gHands.Count, gHands.Count);
  AlliCnt := 0;
  for PL1 := 0 to gHands.Count - 1 do
    if gHands[PL1].Enabled AND (fPL2Alli[PL1] = 255) then
    begin
      PLCnt := 0;
      for PL2 := 0 to gHands.Count - 1 do
        if gHands[PL2].Enabled AND ((PL1 = PL2) OR (gHands[PL1].Alliances[PL2] = atAlly)) then
        begin
          fPL2Alli[PL2] := AlliCnt;
          fAlli2PL[AlliCnt,PLCnt] := PL2;
          Inc(PLCnt);
        end;
      SetLength(fAlli2PL[AlliCnt], PLCnt);
      Inc(AlliCnt);
    end;
  SetLength(fAlli2PL, AlliCnt);
  UpdateFFA();
end;


procedure TKMSupervisor.UpdateFFA();
var
  Team,PL,Cnt: Integer;
begin
  Cnt := 0;
  for Team := Low(fAlli2PL) to High(fAlli2PL) do
    for PL := Low(fAlli2PL[Team]) to High(fAlli2PL[Team]) do
      if gHands[ fAlli2PL[Team,PL] ].Enabled AND not gHands[ fAlli2PL[Team,PL] ].AI.HasLost then
      begin
        Inc(Cnt);
        break;
      end;
  fFFA := Cnt > 2;
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
      Sort(DefEval[0], Low(DefEval), Cnt-1, sizeof(DefEval[0]), CompareDef);
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
          if (HandType = hndComputer) AND AI.Setup.NewAI AND AI.Setup.AutoDefend then
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
        Troops := Byte(HandType = hndComputer) * (Stats.GetUnitQty(utRecruit) + Stats.GetArmyCount); // Consider also recruits so after peace time the AI already have prepared defences
        DefPosReq[IdxPL] := Round(Troops / 8) + RESERVE_DEF_POS; // Each group have 9 troops so we need max (Troops / 9) positions + reserves
      end;
    SetLength(TeamDefPos,0);
    gAIFields.NavMesh.Defences.FindTeamDefences(fAlli2PL[aTeam], DefPosReq, TeamDefPos);
    DivideDefences(fAlli2PL[aTeam], DefPosReq, TeamDefPos);
  end;
end;


function TKMSupervisor.GetInitPoints(var aPlayers: TKMHandIDArray): TKMPointArray;
var
  IdxPL: Integer;
  Player: TKMHandID;
  Group: TKMUnitGroup;
  CenterPoints: TKMPointArray;
begin
  SetLength(Result,0);
  // Find center points of cities / armies (where we should start scan - init point / center screen is useless for this)
  for IdxPL := 0 to Length(aPlayers) - 1 do
  begin
    Player := aPlayers[IdxPL];
    gAIFields.Eye.OwnerUpdate(Player);
    CenterPoints := gAIFields.Eye.GetCityCenterPoints(True);
    if (Length(CenterPoints) = 0) then // Important houses were not found -> try find soldier
    begin
      if (gHands[Player].UnitGroups.Count = 0) then
        continue;
      Group := gHands[Player].UnitGroups.Groups[ KaMRandom(gHands[Player].UnitGroups.Count, 'TKMSupervisor.GetInitPoints') ];
      if (Group <> nil) AND not Group.IsDead AND not KMSamePoint(KMPOINT_ZERO,Group.Position) then
      begin
        SetLength(CenterPoints, 1);
        CenterPoints[0] := Group.Position;
      end
      else
        continue;
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
            AND ( gAIFields.Influences.InfluenceSearch.FindClosestEnemies(aPlayers[0], InitPoints, aEnemyStats, True)
               OR gAIFields.Influences.InfluenceSearch.FindClosestEnemies(aPlayers[0], InitPoints, aEnemyStats, False) );
end;


// Find best target -> to secure that AI will be as universal as possible find only point in map and company will destroy everything around automatically
procedure TKMSupervisor.UpdateAttack(aTeam: Byte);

  procedure GetBestComparison(aPlayer: TKMHandID; var aBestCmpIdx, aWorstCmpIdx: TKMHandID; var aBestCmp, aWorstCmp: Single; var aEnemyStats: TKMEnemyStatisticsArray);
  const
    // Decrease chance to attack enemy in distance
    DISTANCE_COEF_1v1 = 0.4;
    DISTANCE_COEF_FFA = 2;
  var
    I, MinDist, MaxDist: Integer;
    Comparison, invDistInterval, DistCoef: Single;
  begin
    aBestCmp := -1;
    aWorstCmp := 1;
    aBestCmpIdx := 0;
    aWorstCmpIdx := 0;
    if (Length(aEnemyStats) > 0) then
    begin
      // Find closest enemy
      MinDist := High(Integer);
      MaxDist := 0;
      for I := 0 to Length(aEnemyStats) - 1 do
      begin
          MinDist := Min(MinDist, aEnemyStats[I].Distance);
          MaxDist := Max(MaxDist, aEnemyStats[I].Distance);
      end;
      invDistInterval := 1 / Max(1,MaxDist - MinDist);
      DistCoef := ifthen(fFFA, DISTANCE_COEF_FFA, DISTANCE_COEF_1v1);

      for I := 0 to Length(aEnemyStats) - 1 do
      begin
        Comparison := + gAIFields.Eye.ArmyEvaluation.CompareAllianceStrength(aPlayer, aEnemyStats[I].Player)
                      - (aEnemyStats[I].Distance - MinDist) * invDistInterval * DistCoef;
        if (Comparison > aBestCmp) then
        begin
          aBestCmp := Comparison;
          aBestCmpIdx := I;
        end;
        if (Comparison <= aWorstCmp) then
        begin
          aWorstCmp := Comparison;
          aWorstCmpIdx := I;
        end;
      end;
    end;
  end;
const
  MIN_DEF_RATIO = 1.2;
  FOOD_THRESHOLD = 0.55;
  MIN_ADVANTAGE = 0.15; // 15% advantage for attacker
var
  IdxPL, EnemyTeamIdx: Integer;
  DefRatio, BestCmp, WorstCmp, FoodLevel: Single;
  BestCmpIdx, WorstCmpIdx: TKMHandID;
  ArmyState: TKMArmyEval;
  EnemyStats: TKMEnemyStatisticsArray;
  AR: TKMAttackRequest;
begin
  if not NewAIInTeam(aTeam, True, False) OR (Length(fAlli2PL) < 2) then // I sometimes use my loc as a spectator (alliance with everyone) so make sure that search for enemy will use AI loc
    Exit;
  // Check if alliance can attack (have available soldiers) in the FFA mode (if there are just 2 teams attack if we have advantage)
  if fFFA AND not (gGame.MissionMode = mmTactic) then
  begin
    DefRatio := 0;
    for IdxPL := 0 to Length( fAlli2PL[aTeam] ) - 1 do
      with gHands[ fAlli2PL[aTeam, IdxPL] ] do
        if (HandType = hndComputer) AND AI.Setup.NewAI AND AI.Setup.AutoAttack then
        begin
          DefRatio := Max(DefRatio, AI.ArmyManagement.Defence.DefenceStatus);
          KMSwapInt(fAlli2PL[aTeam, 0], fAlli2PL[aTeam, IdxPL]); // Make sure that player in first index is new AI
        end;
    // AI does not have enought soldiers
    if (DefRatio < MIN_DEF_RATIO) then
      Exit;
  end;
  // Try find enemies by influence area
  if FindClosestEnemies(fAlli2PL[aTeam], EnemyStats) then
  begin
    // Calculate strength of alliance, find best comparison - value in interval <-1,1>, positive value = advantage, negative = disadvantage
    GetBestComparison(fAlli2PL[aTeam, 0], BestCmpIdx, WorstCmpIdx, BestCmp, WorstCmp, EnemyStats);
    ArmyState := gAIFields.Eye.ArmyEvaluation.AllianceEvaluation[ fAlli2PL[aTeam,0], atAlly ];
    with ArmyState.FoodState do
      FoodLevel := (Full + Middle) / Max(1, (Full + Middle + Low));
    if (BestCmpIdx <> -1) AND ((BestCmp > MIN_ADVANTAGE) OR (FoodLevel < FOOD_THRESHOLD) OR (gGame.MissionMode = mmTactic)) then
    begin
      EnemyTeamIdx := fPL2Alli[ EnemyStats[BestCmpIdx].Player ];
      for IdxPL := 0 to Length( fAlli2PL[aTeam] ) - 1 do
        if gHands[ fAlli2PL[aTeam,IdxPL] ].AI.Setup.AutoAttack then
        begin
          fCombatStatus[fAlli2PL[aTeam,IdxPL],EnemyStats[BestCmpIdx].Player] := csAttackingCity;
          if (gGame.MissionMode = mmTactic) then
            fCombatStatus[fAlli2PL[aTeam,IdxPL],EnemyStats[BestCmpIdx].Player] := csAttackingEverything;
          with AR do
          begin
            Active := True;
            FoodShortage := FoodLevel < FOOD_THRESHOLD;
            BestAllianceCmp := BestCmp;
            WorstAllianceCmp := WorstCmp;
            BestEnemy := EnemyStats[BestCmpIdx].Player;
            BestPoint := EnemyStats[BestCmpIdx].ClosestPoint;
            WorstEnemy := EnemyStats[WorstCmpIdx].Player;
            WorstPoint := EnemyStats[WorstCmpIdx].ClosestPoint;
            SetLength(Enemies, Length(fAlli2PL[EnemyTeamIdx]) );
            Move(fAlli2PL[EnemyTeamIdx,0], Enemies[0], SizeOf(Enemies[0])*Length(Enemies));
          end;
          gHands[ fAlli2PL[aTeam,IdxPL] ].AI.ArmyManagement.AttackRequest := AR;
        end;
    end;
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
    for K := Length(aMines) - 1 downto 0 do
    begin
      // Evaluate point if there can be mine (in dependence on influence)
      PL := gAIFields.Influences.GetBestOwner(aMines[K].X,aMines[K].Y);
      for IdxPL := 0 to Length(aPlayers) - 1 do
        if (PL = aPlayers[IdxPL]) then
        begin
          PLCnt := 0;
          for IdxPL2 := 0 to Length(aPlayers) - 1 do // Mark players which can place mine here (by influence)
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
      Sort(Mines[0], Low(Mines), Cnt-1, sizeof(Mines[0]), CompareMines);
      // Distribute mines by evaluation and possible mine cnt per a player
      for K := 0 to Cnt - 1 do // Lower index = less players can own this mine
      begin
        IdxPL2 := 0;
        BestPrice := High(Word);
        for IdxPL := 0 to Length(aPlayers) - 1 do
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
          for IdxPL2 := 0 to Length(aPlayers) - 1 do
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
      if (HandType = hndComputer)
        AND AI.Setup.NewAI
        AND (not aAttack OR AI.Setup.AutoAttack)
        AND (not aDefence OR AI.Setup.AutoDefend) then
      begin
        Result := True;
        Exit;
      end;
end;



function TKMSupervisor.LogStatus(): UnicodeString;
const
  COLOR_WHITE = '[$FFFFFF]';
var
  Team, K: Integer;
  PL,PL2, Cnt: TKMHandID;
  CombatStatusText: UnicodeString;
begin
  Result := '';
  if not OVERLAY_AI_SUPERVISOR then
    Exit;
  // Head
  Cnt := 0;
  for PL := 0 to gHands.Count-1 do
    Cnt := Cnt + Byte(gHands[PL].Enabled);
  Result := Format('Supervisor (FFA = %d; Teams = %d); Players = %d',[Byte(fFFA), Length(fAlli2PL), Cnt]);
  // Diplomacy + combat status
  for Team := Low(fAlli2PL) to High(fAlli2PL) do
  begin
    Result := Format('%s|  Team %d',[Result,Team]);
    for K := Low(fAlli2PL[Team]) to High(fAlli2PL[Team]) do
    begin
      PL := Alli2PL[Team,K];
      Result := Format('%s|    [$%s] Player %s %d (Enabled %d; Defeated: %d)',[Result,IntToHex(gHands[PL].FlagColor AND $FFFFFF,6),COLOR_WHITE,PL,Byte(gHands[PL].Enabled),Byte(gHands[PL].AI.HasLost)]);
      for PL2 := Low(fCombatStatus[PL]) to High(fCombatStatus[PL]) do
        if (PL <> PL2) then
        begin
          case fCombatStatus[PL,PL2] of
            csNeutral: continue;
            csDefending:            CombatStatusText := 'defending';
            csAttackingCity:        CombatStatusText := 'attacking city';
            csAttackingEverything:  CombatStatusText := 'attacking everything';
          end;
          Result := Format('%s [$%s] %s %s %d,',[Result,IntToHex(gHands[PL2].FlagColor AND $FFFFFF,6),CombatStatusText,COLOR_WHITE,PL2]);
        end;
    end;
  end;
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
  COLOR_WHITE = $FFFFFF;
  COLOR_BLACK = $000000;
  COLOR_GREEN = $00FF00;
  COLOR_RED = $0000FF;
  COLOR_YELLOW = $00FFFF;
  COLOR_BLUE = $FF0000;

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
      continue;
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
      //gRenderAux.Quad(P.X, P.Y, $FF000000 OR COLOR_RED);
      //gRenderAux.LineOnTerrain(Company.PointPath[K+1], Company.PointPath[K], $60000000 OR COLOR_YELLOW);
      //gRenderAux.Line(P.X-0.5, P.Y-1, P.X-0.5, P.Y-1-A[Alli,GIdx].Attack/100, $FF000000 OR COLOR_BLACK);
      // Strenght
      gRenderAux.Triangle(P.X-1.5, P.Y, P.X-1.25, P.Y-A[Alli,GIdx].Own.Attack           /200, P.X-1.0, P.Y, $55000000 OR COLOR_RED);
      gRenderAux.Triangle(P.X-1.5, P.Y, P.X-1.25, P.Y-A[Alli,GIdx].Own.AttackHorse      /200, P.X-1.0, P.Y, $AA000000 OR COLOR_RED);
      gRenderAux.Triangle(P.X-1.0, P.Y, P.X-0.75, P.Y-A[Alli,GIdx].Own.Defence           /10, P.X-0.5, P.Y, $AA000000 OR COLOR_BLUE);
      gRenderAux.Triangle(P.X-1.0, P.Y, P.X-0.75, P.Y-A[Alli,GIdx].Own.DefenceProjectiles/10, P.X-0.5, P.Y, $55000000 OR COLOR_BLUE);
      gRenderAux.Triangle(P.X-0.5, P.Y, P.X-0.25, P.Y-A[Alli,GIdx].Own.HitPoints         /10, P.X-0.0, P.Y, $AA000000 OR COLOR_GREEN);
      // Influence
      gRenderAux.Triangle(P.X+0.0, P.Y, P.X+0.25, P.Y-A[Alli,GIdx].Nearby.Attack           /200, P.X+0.5, P.Y, $22000000 OR COLOR_RED);
      gRenderAux.Triangle(P.X+0.0, P.Y, P.X+0.25, P.Y-A[Alli,GIdx].Nearby.AttackHorse      /200, P.X+0.5, P.Y, $55000000 OR COLOR_RED);
      gRenderAux.Triangle(P.X+0.5, P.Y, P.X+0.75, P.Y-A[Alli,GIdx].Nearby.Defence           /10, P.X+1.0, P.Y, $55000000 OR COLOR_BLUE);
      gRenderAux.Triangle(P.X+0.5, P.Y, P.X+0.75, P.Y-A[Alli,GIdx].Nearby.DefenceProjectiles/10, P.X+1.0, P.Y, $22000000 OR COLOR_BLUE);
      gRenderAux.Triangle(P.X+1.0, P.Y, P.X+1.25, P.Y-A[Alli,GIdx].Nearby.HitPoints         /10, P.X+1.5, P.Y, $55000000 OR COLOR_GREEN);
    end;
end;
//}


procedure TKMSupervisor.Paint(aRect: TKMRect);
const
  COLOR_WHITE = $FFFFFF;
  COLOR_BLACK = $000000;
  COLOR_GREEN = $00FF00;
  COLOR_RED = $0000FF;
  COLOR_YELLOW = $00FFFF;
  COLOR_BLUE = $FF0000;
begin
  //EvaluateArmies();
  fArmyPos.Paint();
end;

end.
