{
Artificial intelligence
@author: Martin Toupal
@e-mail: poznamenany@gmail.com
}
unit KM_ArmyAttackNew;
{$I KaM_Remake.inc}
interface
uses
  Generics.Collections, Classes, KromUtils, Math, SysUtils,
  KM_Units, KM_UnitGroup,
  KM_CommonClasses, KM_Defaults, KM_Points,
  KM_Houses, KM_ResHouses, KM_NavMeshPathFinding,
  KM_ResTypes;

type
  TKMTargetType = (ttNone, ttPoint, ttHouse, ttGroup, ttUnit);
  TKMCombatPhase = (cpIdle, cpWalk, cpAttack, cpDead);
  TKMStuckInTraffic = record
    StuckInTraffic: Boolean;
    StuckCounter: Byte;
    PreviousPosition: TKMPoint;
  end;
  TKMCombatGroup = class;
  TKMCombatGroupArray = array of TKMCombatGroup;

  TKMCombatGroup = class
    fGroup: TKMUnitGroup;
    fTargetType: TKMTargetType;
    fCombatPhase: TKMCombatPhase;
    fOnPlace, fTargetChanged: Boolean;
    fTrafficDetection: TKMStuckInTraffic;
    fTargetGroup: TKMUnitGroup;
    fTargetUnit: TKMUnit;
    fTargetHouse: TKMHouse;
    fTargetPosition: TKMPointDir;
    fTargetAim: TKMPoint;
    fWalkTimeLimit, fAttackTimeLimit: Cardinal;

    function SquadInFight(): Boolean; inline;
    function GetGroupPosition(): TKMPoint; inline;
    function PlanPath(aTick: Cardinal; var aActualPosition, aTargetPosition: TKMPoint; aOrderAttack: Boolean = False; aOrderDestroy: Boolean = False): Boolean;

    procedure SetTargetGroup(aGroup: TKMUnitGroup);
    procedure SetTargetUnit(aUnit: TKMUnit);
    procedure ChangeTargetUnit(aUnit: TKMUnit);
    procedure SetTargetHouse(aHouse: TKMHouse);
    procedure SetTargetPosition(aLoc: TKMPointDir);

  public
    {$IFDEF DEBUG_NewAI}
    DEBUGPointPath: TKMPointArray;
    {$ENDIF}
    constructor Create(aGroup: TKMUnitGroup);
    constructor Load(LoadStream: TKMemoryStream);
    destructor Destroy; override;
    procedure Save(SaveStream: TKMemoryStream);
    procedure SyncLoad();

    property Group: TKMUnitGroup read fGroup;
    property TargetType: TKMTargetType read fTargetType;
    property CombatPhase: TKMCombatPhase read fCombatPhase;
    property OnPlace: Boolean read fOnPlace;
    property InFight: Boolean read SquadInFight;
    property Position: TKMPoint read GetGroupPosition;
    property StuckInTraffic: Boolean read fTrafficDetection.StuckInTraffic;
    property WalkTimeLimit: Cardinal read fWalkTimeLimit write fWalkTimeLimit;
    property AttackTimeLimit: Cardinal read fAttackTimeLimit write fAttackTimeLimit;
    property TargetGroup: TKMUnitGroup read fTargetGroup write SetTargetGroup;
    property TargetUnit: TKMUnit read fTargetUnit write SetTargetUnit;
    property TargetHouse: TKMHouse read fTargetHouse write SetTargetHouse;
    property TargetPosition: TKMPointDir read fTargetPosition write SetTargetPosition;
    property TargetAim: TKMPoint read fTargetAim;

    procedure UpdateState(aTick: Cardinal);
  end;

  TKMArmyAttackNew = class
  private
    fOwner: TKMHandID;
    fCombatGroups: TObjectList<TKMCombatGroup>;

    function GetCount(): Integer;
    function GetCombatGroupIdx(aGroup: TKMUnitGroup): Integer;
    function GetCombatGroup(aGroup: TKMUnitGroup): TKMCombatGroup;
  public
    constructor Create(aOwner: TKMHandID);
    destructor Destroy(); override;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad();

    property CG: TObjectList<TKMCombatGroup> read fCombatGroups;
    property Count: Integer read GetCount;
    property CombatGroup[aGroup: TKMUnitGroup]: TKMCombatGroup read GetCombatGroup;

    procedure AfterMissionInit();
    procedure UpdateState(aTick: Cardinal);
    procedure OwnerUpdate(aPlayer: TKMHandID);

    function IsGroupInAction(aGroup: TKMUnitGroup): Boolean;

    function AddGroup(const aGroup: TKMUnitGroup): TKMCombatGroup;
    procedure AddGroups(const aGroups: TKMUnitGroupArray);
    procedure ReleaseGroup(aGroup: TKMUnitGroup);
    procedure ReleaseGroups();
    procedure LinkGroup(aGroup: TKMUnitGroup);

    procedure LogStatus(var aBalanceText: UnicodeString);
    procedure Paint();
  end;

const
  // Houses in TARGET_HOUSES will be selected as a primary target (so the company will come to this point but it will not attack it because of this list)
  TARGET_HOUSES: TKMHouseTypeSet = [htBarracks, htStore, htSchool, htTownhall];
  // Houses in SCAN_HOUSES will be destroyed when they are in radius (it should also contain TARGET_HOUSES)
  SCAN_HOUSES: TKMHouseTypeSet = [htWatchTower, htBarracks, htStore, htSchool, htTownhall];
  // All houses for final stage of attack algorithm
  ALL_HOUSES: TKMHouseTypeSet = HOUSES_VALID;

{$IFDEF DEBUG_NewAI}
var
  gTimePathfinding, gTimeAiming: Int64;
{$ENDIF}

implementation
uses
  Types, TypInfo,
  KM_Game, KM_GameParams, KM_HandsCollection, KM_Terrain, KM_AIFields,
  KM_NavMesh, KM_RenderAux,
  {$IFDEF DEBUG_NewAI}
    KM_CommonUtils,
  {$ENDIF}
  KM_UnitWarrior, KM_AIParameters, KM_UnitActionFight, KM_UnitActionWalkTo,
  KM_UnitGroupTypes;


{ TKMCombatGroup }
constructor TKMCombatGroup.Create(aGroup: TKMUnitGroup);
begin
  inherited Create;
  fTargetType := ttPoint;
  fCombatPhase := cpIdle;
  fOnPlace := False;
  fTargetChanged := True;
  fTrafficDetection.StuckInTraffic := False;
  fTrafficDetection.PreviousPosition := aGroup.Position;
  fTrafficDetection.StuckCounter := 0;
  fTargetPosition := KMPointDir(KMPOINT_ZERO, dirNA);
  fTargetAim := KMPOINT_ZERO;
  fWalkTimeLimit := 0;
  fAttackTimeLimit := 0;
  fGroup := aGroup.GetPointer();
  fTargetGroup := nil;
  fTargetUnit := nil;
  fTargetHouse := nil;
end;


destructor TKMCombatGroup.Destroy();
begin
  gHands.CleanUpGroupPointer(fGroup);
  gHands.CleanUpGroupPointer(fTargetGroup);
  gHands.CleanUpUnitPointer(fTargetUnit);
  gHands.CleanUpHousePointer(fTargetHouse);
  inherited;
end;


constructor TKMCombatGroup.Load(LoadStream: TKMemoryStream);
begin
  inherited Create;
  LoadStream.CheckMarker('CombatGroup');
  LoadStream.Read(fTargetType, SizeOf(fTargetType));
  LoadStream.Read(fCombatPhase, SizeOf(fCombatPhase));
  LoadStream.Read(fOnPlace);
  LoadStream.Read(fTargetChanged);
  LoadStream.Read(fTargetPosition);
  LoadStream.Read(fTargetAim, SizeOf(fTargetAim));
  LoadStream.Read(fWalkTimeLimit, SizeOf(fWalkTimeLimit));
  LoadStream.Read(fAttackTimeLimit, SizeOf(fAttackTimeLimit));
  LoadStream.Read(fTrafficDetection, SizeOf(TKMStuckInTraffic));
  //Subst on syncload
  LoadStream.Read(fGroup, 4);
  LoadStream.Read(fTargetGroup, 4);
  LoadStream.Read(fTargetUnit, 4);
  LoadStream.Read(fTargetHouse, 4);
end;


procedure TKMCombatGroup.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.PlaceMarker('CombatGroup');
  SaveStream.Write(fTargetType, SizeOf(fTargetType));
  SaveStream.Write(fCombatPhase, SizeOf(fCombatPhase));
  SaveStream.Write(fOnPlace);
  SaveStream.Write(fTargetChanged);
  SaveStream.Write(fTargetPosition);
  SaveStream.Write(fTargetAim, SizeOf(fTargetAim));
  SaveStream.Write(fWalkTimeLimit, SizeOf(fWalkTimeLimit));
  SaveStream.Write(fAttackTimeLimit, SizeOf(fAttackTimeLimit));
  SaveStream.Write(fTrafficDetection, SizeOf(TKMStuckInTraffic));
  SaveStream.Write(fGroup.UID);
  SaveStream.Write(fTargetGroup.UID);
  SaveStream.Write(fTargetUnit.UID);
  SaveStream.Write(fTargetHouse.UID);
end;


procedure TKMCombatGroup.SyncLoad();
begin
  fGroup := gHands.GetGroupByUID( Cardinal(fGroup) );
  fTargetHouse := gHands.GetHouseByUID( Cardinal(fTargetHouse) );
  fTargetGroup := gHands.GetGroupByUID( Cardinal(fTargetGroup) );
  fTargetUnit := gHands.GetUnitByUID( Cardinal(fTargetUnit) );
end;


procedure TKMCombatGroup.SetTargetGroup(aGroup: TKMUnitGroup);
begin
  // Check old target
  if (aGroup = fTargetGroup) then
    Exit;
  // Clear pointer
  gHands.CleanUpGroupPointer(fTargetGroup);
  // Update target
  if (aGroup = nil) OR aGroup.IsDead then
    SetTargetUnit(nil)
  else
  begin
    fTargetGroup := aGroup.GetPointer;
    ChangeTargetUnit( aGroup.GetAliveMember() );
  end;
end;


procedure TKMCombatGroup.SetTargetUnit(aUnit: TKMUnit);
begin
  // Check old target
  if (fTargetUnit = aUnit) then
    Exit;
  // Remove group pointer
  gHands.CleanUpGroupPointer(fTargetGroup);
  // Archers will reaim (+ reset animation) only in case that new target is in specific distance from existing target
  if (aUnit <> nil) AND not aUnit.IsDeadOrDying then
    ChangeTargetUnit(aUnit)
  else
    gHands.CleanUpUnitPointer(fTargetUnit);
end;


procedure TKMCombatGroup.ChangeTargetUnit(aUnit: TKMUnit);
begin
  fTargetChanged := (fTargetUnit = nil) OR not fTargetUnit.IsDeadOrDying
    OR ((aUnit is TKMUnitWarrior) AND (fTargetUnit is TKMUnitWarrior) AND (TKMUnitWarrior(fTargetUnit).Group <> TKMUnitWarrior(aUnit).Group));
  gHands.CleanUpUnitPointer(fTargetUnit);
  fTargetUnit := aUnit.GetPointer;
end;


procedure TKMCombatGroup.SetTargetHouse(aHouse: TKMHouse);
begin
  // House have lower priority so if there is request for attacking house, then target group and unit must be nil
  if (aHouse <> nil) AND not aHouse.IsDestroyed then
    SetTargetGroup(nil); // Includes also nil of target unit
  // Check old target
  if (fTargetHouse = aHouse) then
    Exit;
  // Clean pointer
  gHands.CleanUpHousePointer(fTargetHouse);
  // Update target
  fTargetChanged := True;
  if (aHouse <> nil) then
    fTargetHouse := aHouse.GetPointer;
end;


procedure TKMCombatGroup.SetTargetPosition(aLoc: TKMPointDir);
begin
  SetTargetGroup(nil);
  SetTargetHouse(nil);
  fTargetPosition := aLoc;
  fWalkTimeLimit := gGameParams.Tick + KMDistanceAbs(fTargetPosition.Loc, Position) * 5;
end;


function TKMCombatGroup.SquadInFight(): Boolean;
begin
  Result := not fGroup.CanTakeOrders;
end;


function TKMCombatGroup.GetGroupPosition(): TKMPoint;
begin
  Result := fGroup.Position;
end;


// Update state of squad (group orders)
procedure TKMCombatGroup.UpdateState(aTick: Cardinal);

  function GetTargetUnitPosition(): TKMPoint;
  var
    K: Integer;
    Dist, BestDist: Single;
    BestTgt: TKMUnit;
    G: TKMUnitGroup;
  begin
    Result := fTargetUnit.Position;
    // Get closest warrior in enemy group if the squad is ranged
    if (fGroup.GroupType = gtRanged) AND (fTargetUnit is TKMUnitWarrior) then
    begin
      BestTgt := nil;
      G := TKMUnitWarrior(fTargetUnit).Group;
      //Group will be nil if we target a warrior still walking out of barracks
      if G <> nil then
      begin
        BestDist := 1E10;
        for K := 0 to G.Count - 1 do
          if not G.Members[K].IsDeadOrDying then
          begin
            Dist := KMDistanceSqr(fGroup.Position,G.Members[K].Position);
            if (Dist < BestDist) then
            begin
              BestTgt := G.Members[K];
              BestDist := Dist;
            end;
          end;
        if (BestTgt <> nil) then
        begin
          gHands.CleanUpUnitPointer(fTargetUnit);
          fTargetUnit := BestTgt.GetPointer;
        end;
      end;
    end;
  end;

  procedure MoveRangedInFormation();
  var
    K, CntFighting, CntWalking, CntCanFight: Integer;
    NodeList: TKMPointList;
    {$IFDEF DEBUG_NewAI}
      Timer: Int64;
    {$ENDIF}
  begin
    {$IFDEF DEBUG_NewAI}
      Timer := TimeGetUsec();
    {$ENDIF}
    // Target comes from behind
    K := Abs(Byte(KMGetDirection(Position,TargetAim)) - Byte(Group.OrderLoc.Dir));
    if (K > 1) AND (K < 7) then
    begin
      Group.OrderAttackUnit(fTargetUnit, True);
      Exit;
    end;
    //if Group.GetAliveMember.WithinFightRange(fTargetAim) then
    // Check amount of shooting members
    CntFighting := 0;
    CntWalking := 0;
    CntCanFight := 0;
    for K := 0 to Group.Count - 1 do
    begin
      CntFighting := CntFighting + Byte(Group.Members[K].Action is TKMUnitActionFight);
      CntWalking := CntWalking + Byte(Group.Members[K].Action is TKMUnitActionWalkTo);
      CntCanFight := CntCanFight + Byte(Group.Members[K].WithinFightRange(fTargetAim));
    end;
    if (CntFighting = 0) AND (CntCanFight > 0) then
    begin
      Group.OrderAttackUnit(fTargetUnit, True);
      Exit;
    end;
    if (CntFighting > Group.Count * 0.7) OR (CntCanFight > Group.Count * 0.5) OR (CntWalking + CntFighting > Group.Count * 0.7) then
      Exit;
    NodeList := TKMPointList.Create;
    try
      if gGame.Pathfinding.Route_Make(Group.GetAliveMember.Position, TargetUnit.PositionNext, [tpWalk], Group.GetAliveMember.GetFightMaxRange, nil, NodeList) then
      begin
        fTargetPosition := KMPointDir(NodeList[NodeList.Count-1],KMGetDirection(NodeList[NodeList.Count-1], TargetUnit.PositionNext));
        if KMSamePoint(fTargetPosition.Loc, Position) then
          fTargetPosition.Loc := KMGetPointInDir(fTargetPosition.Loc, fTargetPosition.Dir, 1);
        Group.OrderWalk(fTargetPosition.Loc, True, wtokAISquad, fTargetPosition.Dir);
      end;
    finally
      NodeList.Free;
    end;
  {$IFDEF DEBUG_NewAI}
    gTimeAiming := gTimeAiming + TimeGetUsec() - Timer;
  {$ENDIF}
  end;

var
  walkedDistance: Integer;
  ActPos: TKMPoint;
begin
  fOnPlace := False;
  // Check group status and possibility to give order
  if (fGroup = nil) OR fGroup.IsDead then
    fCombatPhase := cpDead;
  if (fCombatPhase = cpDead) OR InFight then
    Exit;

  // Check targets
  if (fTargetGroup <> nil) AND fTargetGroup.IsDead then
    SetTargetGroup(nil);
  if (fTargetUnit <> nil) AND fTargetUnit.IsDeadOrDying then
  begin
    if (fTargetGroup <> nil) then
    begin
      ChangeTargetUnit( fTargetGroup.GetAliveMember() );
      fTargetAim := GetTargetUnitPosition();
      // New target is out of range -> wait for supervisor to update target group to the closest
      if KMDistanceSqr(fTargetAim,Position) > Sqr(Group.GetAliveMember.GetFightMaxRange) then
      begin
        fTargetType := ttGroup;
        fCombatPhase := cpAttack;
        Exit;
      end;
    end
    else
      SetTargetUnit(nil);
  end;
  if (fTargetHouse <> nil) AND (fTargetHouse.IsDestroyed) then
    SetTargetHouse(nil);

  // Orders
  ActPos := Position;
  if (fTargetUnit <> nil) OR (fTargetGroup <> nil) then
  begin
      fTargetAim := GetTargetUnitPosition();
      if PlanPath(aTick, ActPos, fTargetAim, True, False) then  // Check if squad is in the place
        Group.OrderWalk(fTargetAim, True, wtokAISquad, TargetPosition.Dir)
      else if (fGroup.GroupType = gtRanged) then
        MoveRangedInFormation()
      else if
        fTargetChanged // Target has been changed
        OR (KMDistanceSqr(fTargetAim,ActPos) > 12*12)
        OR (fGroup.Order in [goNone, goAttackHouse, goWalkTo]) // Force Group to change its task
        OR (fAttackTimeLimit < aTick) // Make sure that unit is not stuck
      then
      begin
        fAttackTimeLimit := aTick + Round(AI_Par[ATTACK_SQUAD_ChangeTarget_Delay]);
        fTargetChanged := False;
        Group.OrderAttackUnit(fTargetUnit, True);
      end;
      fOnPlace := True;
  end
  else if (fTargetHouse <> nil) then
  begin
    fTargetAim := fTargetHouse.Position;
    if PlanPath(aTick, ActPos, fTargetAim, False, True) then
      Group.OrderWalk(fTargetAim, True, wtokAISquad, TargetPosition.Dir)
    else if (fGroup.GroupType <> gtRanged) OR fTargetChanged OR (fAttackTimeLimit < aTick) then
    begin
      fAttackTimeLimit := aTick + Round(AI_Par[ATTACK_SQUAD_ChangeTarget_Delay]);
      fTargetChanged := False;
      Group.OrderAttackHouse(fTargetHouse, True);
    end;
    fOnPlace := True;
  end
  else if not KMSamePoint(TargetPosition.Loc, KMPOINT_ZERO) then
  begin
    fTargetAim := TargetPosition.Loc;
    if PlanPath(aTick, ActPos, fTargetAim, False, False) then
      Group.OrderWalk(fTargetAim, True, wtokAISquad, TargetPosition.Dir)
    else if not KMSamePoint(Group.Position, TargetPosition.Loc) then // Dont repeat order and let archers fire
      Group.OrderWalk(TargetPosition.Loc, True, wtokAISquad, TargetPosition.Dir);
  end
  else
    Group.OrderNone();

  fTargetType := ttNone;
  fCombatPhase := cpAttack;
  if      (fTargetHouse <> nil) then fTargetType := ttHouse
  else if (fTargetGroup <> nil) then fTargetType := ttGroup
  else if (fTargetUnit  <> nil) then fTargetType := ttUnit
  else if not KMSamePoint(fTargetPosition.Loc, KMPOINT_ZERO) then
  begin
    fTargetType := ttPoint;
    fCombatPhase := cpWalk;
  end
  else
    fCombatPhase := cpIdle;

  // Check traffic
  walkedDistance := KMDistanceAbs(fTrafficDetection.PreviousPosition, fGroup.Position);
  fTrafficDetection.StuckCounter := min(round(AI_Par[ATTACK_SQUAD_TrafficDetection_Limit]), max(0, Word(fCombatPhase = cpWalk) * fTrafficDetection.StuckCounter + Word(walkedDistance <= 1) * 2 - 1));
  fTrafficDetection.StuckInTraffic := fTrafficDetection.StuckCounter > AI_Par[ATTACK_SQUAD_TrafficDetection_Threshold];
  fTrafficDetection.PreviousPosition := fGroup.Position;
end;


function TKMCombatGroup.PlanPath(aTick: Cardinal; var aActualPosition, aTargetPosition: TKMPoint; aOrderAttack: Boolean = False; aOrderDestroy: Boolean = False): Boolean;
var
  PathFound: Boolean;
  InitPolygon, ClosestPolygon, Distance: Word;
  I: Integer;
  SQRDist: Single;
  PointPath: TKMPointArray;
  {$IFDEF DEBUG_NewAI}
    Timer: Int64;
  {$ENDIF}
begin
  {$IFDEF DEBUG_NewAI}
    Timer := TimeGetUsec();
  {$ENDIF}
  Result := False;
  fOnPlace := False;
  SQRDist := KMDistanceSqr(aActualPosition, aTargetPosition);
  // Time limit
  if (not (aOrderAttack OR aOrderDestroy) AND (fWalkTimeLimit < aTick)) // Time limit is set to 0 in case that unit attack something
    // Target position is reached
    OR (SQRDist < sqr(AI_Par[ATTACK_SQUAD_TargetReached_Position]))
    // Target unit is close
    OR (aOrderAttack AND (SQRDist < sqr(AI_Par[ATTACK_SQUAD_TargetReached_Unit])))
    // Target house is close
    OR (aOrderDestroy AND (SQRDist < sqr(AI_Par[ATTACK_SQUAD_TargetReached_House])))
    // Archers should start fire as soon as possible
    OR ((aOrderAttack OR aOrderDestroy) AND (fGroup.GroupType = gtRanged) AND (SQRDist < sqr(AI_Par[ATTACK_SQUAD_TargetReached_RangedSquad]))) then
  begin
    fOnPlace := True;
    Exit;
  end;
  // Plan path with respect to enemy presence
  if aOrderAttack then
    PathFound := gAIFields.NavMesh.Pathfinding.AvoidEnemyRoute(Group.Owner, Group.GroupType, aActualPosition, aTargetPosition, Distance, PointPath)
  else if aOrderDestroy then
    PathFound := gAIFields.NavMesh.Pathfinding.ShortestRoute(aActualPosition, aTargetPosition, Distance, PointPath)
  else
    PathFound := gAIFields.NavMesh.Pathfinding.AvoidTrafficRoute(Group.Owner, aActualPosition, aTargetPosition, Distance, PointPath);

  if PathFound then
  begin
    if Distance < 5 then
    begin
      fOnPlace := True;
      Exit;
    end
    else
    begin
      InitPolygon := gAIFields.NavMesh.KMPoint2Polygon[aActualPosition];
      I := Length(PointPath)-1;
      repeat
        aTargetPosition := PointPath[Max(0, I)];
        ClosestPolygon := gAIFields.NavMesh.KMPoint2Polygon[aTargetPosition];
        I := I - 1;
      until (I < 0) or (
          (InitPolygon <> ClosestPolygon)
          and (tpWalk in gTerrain.Land^[aTargetPosition.Y, aTargetPosition.X].Passability)
          and (KMDistanceSqr(aActualPosition, aTargetPosition) > sqr(AI_Par[ATTACK_SQUAD_MinWalkingDistance]))
        );

      {$IFDEF DEBUG_NewAI}
      DEBUGPointPath := PointPath;
      {$ENDIF}
    end;
  end;
  Result := True;
  {$IFDEF DEBUG_NewAI}
    gTimePathfinding := gTimePathfinding + TimeGetUsec() - Timer;
  {$ENDIF}
end;


{ TKMArmyAttackNew }
constructor TKMArmyAttackNew.Create(aOwner: TKMHandID);
begin
  inherited Create;
  fCombatGroups := TObjectList<TKMCombatGroup>.Create();
  fOwner := aOwner;
  {$IFDEF DEBUG_NewAI}
    gTimePathfinding := 0;
    gTimeAiming := 0;
  {$ENDIF}
end;


destructor TKMArmyAttackNew.Destroy;
begin
  fCombatGroups.Free; // Calls also Clear()
  inherited;
end;


procedure TKMArmyAttackNew.Save(SaveStream: TKMemoryStream);
var
  K: Integer;
begin
  SaveStream.PlaceMarker('ArmyAttack');
  SaveStream.Write(fOwner);
  SaveStream.Write( Integer(Count) );

  for K := 0 to Count - 1 do
    fCombatGroups[K].Save(SaveStream);
end;


procedure TKMArmyAttackNew.Load(LoadStream: TKMemoryStream);
var
  K, NewCount: Integer;
begin
  LoadStream.CheckMarker('ArmyAttack');
  LoadStream.Read(fOwner);
  LoadStream.Read(NewCount);

  for K := 0 to NewCount - 1 do
    fCombatGroups.Add( TKMCombatGroup.Load(LoadStream) );
end;


procedure TKMArmyAttackNew.SyncLoad();
var
  K: Integer;
begin
  for K := 0 to Count - 1 do
    fCombatGroups[K].SyncLoad();
end;


procedure TKMArmyAttackNew.AfterMissionInit();
begin

end;


procedure TKMArmyAttackNew.UpdateState(aTick: Cardinal);
var
  K: Integer;
begin
  // Update target point
  {
  for K := fCombatGroups.Count - 1 downto 0 do
    for L := 0 to Length( gAIFields.Supervisor.fArmyPos.fAllyGroups) - 1 do
      if ( gAIFields.Supervisor.fArmyPos.fAllyGroups[L] = fCombatGroups[K].Group) then
      begin
        if (Length(gAIFields.Supervisor.fArmyPos.TargetPositions) > L) then
        begin
          fCombatGroups[K].TargetPosition := KMPointDir(gAIFields.Supervisor.fArmyPos.TargetPositions[L],dirNE);
          fCombatGroups[K].WalkTimeLimit := aTick + ;
        end;
        break;
      end;
      }

  // Check state
  //for K := fCombatGroups.Count - 1 downto 0 do
  //begin
  //  CG := fCombatGroups.Items[K];
  //  //CG.UpdateState(aTick);
  //end;

  // Update state
  for K := fCombatGroups.Count - 1 downto 0 do
  begin
    fCombatGroups[K].UpdateState(aTick);
    if (fCombatGroups[K].CombatPhase = cpDead) then
      fCombatGroups.Delete(K);
  end;
end;


procedure TKMArmyAttackNew.OwnerUpdate(aPlayer: TKMHandID);
begin
  fOwner := aPlayer;
end;


function TKMArmyAttackNew.GetCount(): Integer;
begin
  Result := fCombatGroups.Count;
end;


function TKMArmyAttackNew.GetCombatGroupIdx(aGroup: TKMUnitGroup): Integer;
var
  K: Integer;
begin
  Result := -1;
  for K := 0 to Count - 1 do
    if (fCombatGroups[K].Group = aGroup) then
      Exit(K);
end;


function TKMArmyAttackNew.GetCombatGroup(aGroup: TKMUnitGroup): TKMCombatGroup;
var
  K: Integer;
begin
  Result := nil;
  K := GetCombatGroupIdx(aGroup);
  if (K <> -1) then
    Result := fCombatGroups[K];
end;


function TKMArmyAttackNew.IsGroupInAction(aGroup: TKMUnitGroup): Boolean;
begin
  Result := GetCombatGroup(aGroup) <> nil;
end;


function TKMArmyAttackNew.AddGroup(const aGroup: TKMUnitGroup): TKMCombatGroup;
var
  Idx: Integer;
begin
  Result := nil;
  if (aGroup <> nil) AND not aGroup.IsDead then
  begin
    Result := GetCombatGroup(aGroup);
    if (Result = nil) then
    begin
      Idx := fCombatGroups.Add( TKMCombatGroup.Create(aGroup) );
      Result := fCombatGroups[Idx];
    end;
  end;
end;


procedure TKMArmyAttackNew.AddGroups(const aGroups: TKMUnitGroupArray);
var
  K: Integer;
begin
  for K := 0 to Length(aGroups) - 1 do
    AddGroup(aGroups[K]);
end;


procedure TKMArmyAttackNew.ReleaseGroup(aGroup: TKMUnitGroup);
var
  K: Integer;
begin
  K := GetCombatGroupIdx(aGroup);
  if (K <> -1) then
    fCombatGroups.Delete(K);
end;


procedure TKMArmyAttackNew.ReleaseGroups();
begin
  fCombatGroups.Clear();
end;


procedure TKMArmyAttackNew.LinkGroup(aGroup: TKMUnitGroup);
var
  K: Integer;
begin
  for K := 0 to Count - 1 do
    if (aGroup.GroupType = fCombatGroups[K].Group.GroupType) AND (fCombatGroups[K].Group.Count < 9) then
    begin
      if (fCombatGroups[K].Group.Count - 9 <= aGroup.Count) then
        aGroup.OrderLinkTo(fCombatGroups[K].Group, True)
      else
        aGroup.OrderSplitLinkTo(fCombatGroups[K].Group, fCombatGroups[K].Group.Count - 9, True);
      fCombatGroups[K].Group.UnitsPerRow := Max(3,fCombatGroups[K].Group.UnitsPerRow);
    end;
end;


procedure TKMArmyAttackNew.LogStatus(var aBalanceText: UnicodeString);
var
  K: Integer;
  Order, GroupOrder: UnicodeString;
  CG: TKMCombatGroup;
begin
  {$IFDEF DEBUG_NewAI}
    aBalanceText := Format('%s||Time pathfinding: %d|Time aiming:%d',[aBalanceText,gTimePathfinding,gTimeAiming]);
  {$ENDIF}
  if (gMySpectator.Selected is TKMUnitGroup) then
    for K := 0 to fCombatGroups.Count - 1 do
      if (gMySpectator.Selected = fCombatGroups[K].Group) then
      begin
        CG := fCombatGroups[K];

        Order := 'CGTargets:|';
        if (CG.TargetGroup <> nil) AND not CG.TargetGroup.IsDead then
          Order := Format('%s   Group [%d;%d] %s|',[Order, CG.TargetGroup.Position.X,CG.TargetGroup.Position.Y, GetEnumName(TypeInfo(TKMGroupType), Integer(CG.TargetGroup.GroupType))]);
        if (CG.TargetUnit <> nil) AND not CG.TargetUnit.IsDeadOrDying then
          Order := Format('%s   Unit [%d;%d] %s|',[Order, CG.TargetUnit.Position.X,CG.TargetUnit.Position.Y, GetEnumName(TypeInfo(TKMUnitType), Integer(CG.TargetUnit.UnitType))]);
        if (CG.TargetHouse <> nil) AND not CG.TargetHouse.IsDestroyed then
          Order := Format('%s   House [%d;%d] %s|',[Order, CG.TargetHouse.Entrance.X, CG.TargetHouse.Entrance.Y, GetEnumName(TypeInfo(TKMHouseType), Integer(CG.TargetHouse.HouseType))]);

        GroupOrder := Format('GroupOrder: %s',[GetEnumName(TypeInfo(TKMGroupOrder), Integer(CG.Group.Order))]);
        if (CG.Group.Order = goWalkTo) then
          GroupOrder := Format('%s [%d;%d]|', [GroupOrder, CG.Group.OrderLoc.Loc.X, CG.Group.OrderLoc.Loc.Y])
        else if (CG.Group.Order in [goAttackHouse,goNone]) AND (CG.Group.OrderTargetHouse <> nil) then
          GroupOrder := Format('%s %d [%d;%d]|', [GroupOrder, Integer(CG.Group.OrderTargetHouse), CG.Group.OrderTargetHouse.Position.X, CG.Group.OrderTargetHouse.Position.Y])
        else if (CG.Group.Order in [goAttackUnit,goNone]) AND (CG.Group.OrderTargetUnit <> nil) then
          GroupOrder := Format('%s %d [%d;%d]|', [GroupOrder, Integer(CG.Group.OrderTargetUnit), CG.Group.OrderTargetUnit.Position.X, CG.Group.OrderTargetUnit.Position.Y])
        else if (CG.Group.Order = goNone) then
          GroupOrder := Format('%s [%d;%d]|', [GroupOrder, CG.Group.OrderLoc.Loc.X, CG.Group.OrderLoc.Loc.Y]);

        aBalanceText := Format('%s|CG_ID: %d|Group_ID: %d|CombatPhase: %s|TargetType: %s|OnPlace: %d|InFight: %d|%sWalkTimeLimit: %d|AttackTimeLimit: %d|GroupPosition: [%d;%d]|TargetAim: [%d;%d]|DistanceFromAim: Sqr(%f) Abs(%d)|%s', [
                          aBalanceText,
                          Integer(CG),
                          Integer(CG.Group),
                          GetEnumName(TypeInfo(TKMCombatPhase), Integer(CG.CombatPhase)),
                          GetEnumName(TypeInfo(TKMTargetType), Integer(CG.TargetType)),
                          Byte(CG.OnPlace),
                          Byte(CG.InFight),
                          Order,
                          Max(0, Integer(CG.WalkTimeLimit)   - Integer(gGameParams.Tick)),
                          Max(0, Integer(CG.AttackTimeLimit) - Integer(gGameParams.Tick)),
                          CG.Position.X, CG.Position.Y,
                          CG.TargetAim.X, CG.TargetAim.Y,
                          KMDistanceSqr(CG.TargetAim,CG.Position), KMDistanceAbs(CG.TargetAim,CG.Position),
                          GroupOrder
                        ]);
      end;
end;


procedure TKMArmyAttackNew.Paint;
var
  Op1, Op2: Byte;
  K: Integer;
  Col1, Col2: Cardinal;
  Position: TKMPoint;
  CG: TKMCombatGroup;
  {$IFDEF DEBUG_NewAI}
    L: Integer;
  {$ENDIF}
begin
  for K := 0 to fCombatGroups.Count - 1 do
  begin
    CG := fCombatGroups[K];
    if CG.fTrafficDetection.StuckInTraffic then
      gRenderAux.Quad(CG.Position.X, CG.Position.Y, $FF000000 OR tcRed);
  end;


  {$IFDEF DEBUG_NavMeshPathfinding}
  if (fOwner = gMySpectator.HandID) then
    gAIFields.NavMesh.Pathfinding.Paint();
  {$ENDIF}
  //if (fOwner <> 1) then
  //  Exit;

  for K := 0 to fCombatGroups.Count - 1 do
  begin
    CG := fCombatGroups[K];

    // Opacity
    Op1 := $20;
    Op2 := $30;
    if (gMySpectator.Selected is TKMUnitGroup) AND (gMySpectator.Selected = CG.Group) then
    begin
      //Col1 := gMySpectator.Hand.FlagColor;
      Op1 := $AA;
      Op2 := $FF;
      case CG.Group.Order of
        goWalkTo:      Position := CG.Group.OrderLoc.Loc;
        goAttackHouse:
        begin
          if (CG.Group.OrderTargetHouse <> nil) then
            Position := CG.Group.OrderTargetHouse.Position;
        end;
        goAttackUnit:
        begin
          if (CG.Group.OrderTargetUnit <> nil) then
            Position := CG.Group.OrderTargetUnit.Position;
        end;
        goNone:
        begin
          if (CG.Group.OrderTargetHouse <> nil) then
            Position := CG.Group.OrderTargetHouse.Position
          else if (CG.Group.OrderTargetUnit <> nil) then
            Position := CG.Group.OrderTargetUnit.Position
          else
            Position := CG.Group.OrderLoc.Loc;
        end;
        else begin end; // goStorm, goNone
      end;
      if not KMSamePoint(Position,KMPOINT_ZERO) then
        gRenderAux.CircleOnTerrain(Position.X, Position.Y, 1.5, (Op1 shl 24) OR tcBlue, (Op2 shl 24) OR tcBlue);
      gRenderAux.Quad(CG.TargetAim.X, CG.TargetAim.Y, $FF000000 OR tcWhite);
      {$IFDEF DEBUG_NewAI}
      if not KMSamePoint(CG.TargetAim, KMPOINT_ZERO) AND (Length(CG.DEBUGPointPath) > 0) then
        with CG.DEBUGPointPath[Low(CG.DEBUGPointPath)] do
          gRenderAux.Quad(X, Y, $FF000000 OR tcCyan);
      {$ENDIF}
    end;

    // Combat group circle
    Col1 := tcWhite;
    case CG.CombatPhase of
      cpIdle:   Col1 := tcWhite;
      cpWalk:   Col1 := tcGreen;
      cpAttack: Col1 := tcRed;
      cpDead:   Col1 := tcBlack;
    end;
    Col2 := tcWhite;
    case CG.TargetType of
      ttNone:  Col2 := tcWhite;
      ttGroup: Col2 := tcRed;
      ttUnit:  Col2 := tcYellow;
      ttHouse: Col2 := tcYellow;
      ttPoint: Col2 := tcGreen;
    end;
    gRenderAux.CircleOnTerrain(CG.Position.X, CG.Position.Y, 1, (Op1 shl 24) OR Col1, (Op2 shl 24) OR Col2);

    // Select target
    Col1 := tcWhite;
    if      (CG.CombatPhase = cpWalk)   then Col1 := tcGreen
    else if (CG.CombatPhase = cpAttack) then Col1 := tcRed;
    {$IFDEF DEBUG_NewAI}
    if not KMSamePoint(CG.TargetAim, KMPOINT_ZERO) then
      for L := 1 to Length(CG.DEBUGPointPath) - 1 do
        gRenderAux.LineOnTerrain(CG.DEBUGPointPath[L-1], CG.DEBUGPointPath[L], (Op2 shl 24) OR Col1);
    {$ELSE}
    if not KMSamePoint(CG.TargetAim, KMPOINT_ZERO) then
      gRenderAux.LineOnTerrain(CG.Position, CG.TargetAim, (Op2 shl 24) OR Col1);
    {$ENDIF}
  end;
  //gRenderAux.Quad(Loc.X, Loc.Y, Color);
end;

end.

