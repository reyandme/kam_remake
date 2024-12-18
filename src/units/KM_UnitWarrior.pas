unit KM_UnitWarrior;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, KromUtils, Math,
  KM_CommonClasses, KM_Defaults, KM_Points,
  KM_Houses, KM_Terrain, KM_Units, KM_CommonGameTypes;


type
  TKMUnitWarrior = class;
  TKMWarriorEvent = procedure(aWarrior: TKMUnitWarrior) of object;
  TKMWarrior2Event = procedure(aWarrior: TKMUnitWarrior; aUnit: TKMUnit) of object;

  // What player has ordered us to do
  TKMWarriorOrder = (
    woNone, //No orders
    woWalk, //Walk somewhere
    woWalkOut, //Walk out of Barracks
    woAttackUnit, //Attack someone
    woAttackHouse, //Attack house
    woStorm //Do Storm attack
  );

  TKMUnitWarrior = class(TKMUnit)
  private
    fGroup: Pointer; // Warrior's group (pointer will be converted to TKMUnitGroup in TKMHandsCollection.GetGroupByMember
    fNextOrder: TKMWarriorOrder; //New order we should perform as soon as we can change tasks
    fNextOrderForced: Boolean; //Next order considered not forced if it comes as "repeated order" after Split/Link orders/Die member/Link after training
    fOrder: TKMWarriorOrder; //Order we are performing
    fOrderLoc: TKMPoint; //Dir is the direction to face after order
    fOrderTargetUnit: TKMUnit; //Unit we are ordered to attack. This property should never be accessed, use GetOrderTarget instead.
    fAttackingUnit: TKMUnit; //Unit we are attacking or following to attack (f.e. group offenders). This property should never be accessed, use GetAttackingUnit instead.
    fOrderTargetHouse: TKMHouse; //House we are ordered to attack. This property should never be accessed, use GetOrderHouseTarget instead.
    fUseExactTarget: Boolean; //Do we try to reach exact position or is it e.g. unwalkable
    fLastShootTime: Cardinal; //Used to prevent archer rate of fire exploit

    fRequestedFood: Boolean;
    fStormDelay: Word;

    procedure FightEnemy(aEnemy: TKMUnit);

    procedure ClearOrderTarget(aClearAttackingUnit: Boolean = True);
    procedure ClearAttackingUnit;
    procedure SetOrderTarget(aUnit: TKMUnit);
    procedure DoSetAttackingUnit(aUnit: TKMUnit);
    function GetAttackingUnit: TKMUnit;
    function GetOrderTargetUnit: TKMUnit;
    function GetOrderHouseTarget: TKMHouse;
    procedure SetOrderHouseTarget(aHouse: TKMHouse);
    procedure UpdateOrderTargets;

    procedure TakeNextOrder;
    function CanInterruptAction(aForced: Boolean = True): Boolean;

    function GetFiringDelay: Byte;
    function GetAimingDelay: Byte;
    function GetRangeMin: Single;
    function GetRangeMax: Single;
    function GetProjectileType: TKMProjectileType;
    function GetAimSoundDelay: Byte;
  protected
    function GetAllowAllyToSelect: Boolean; override;
    procedure SetAllowAllyToSelect(aAllow: Boolean); override;
  public
    OnWarriorDied: TKMWarriorEvent; //Separate event from OnUnitDied to report to Group
    OnPickedFight: TKMWarrior2Event;
    OnWarriorWalkOut: TKMWarriorEvent;
    // Todo: do we actually need it? Should not Group.OrderLoc.Dir be used for the same purpose ?
    FaceDir: TKMDirection; //Direction we should face after walking. Only check for enemies in this direction.

    constructor Create(aID: Cardinal; aUnitType: TKMUnitType; const aLoc: TKMPointDir; aOwner: TKMHandID; aInHouse: TKMHouse);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure SyncLoad; override;
    procedure CloseUnit(aRemoveTileUsage: Boolean = True); override;
    destructor Destroy; override;

    function GetPointer: TKMUnitWarrior; reintroduce;

    property Group: pointer read fGroup; // Property for GetGroupByMember function
    // This procedure should not be called by anyone except UnitGroups class(it is out of property)
    procedure SetGroup(aGroup: Pointer); //Explicitly use SetWorker, to make it clear its not only pointer assignment

    function GetWarriorActivityText(aIsAttackingUnit: Boolean): UnicodeString;
    procedure Kill(aFrom: TKMHandID; aShowAnimation, aForceDelay: Boolean); override;
    procedure Dismiss; override;
    procedure DismissCancel; override;

    //Commands from TKMUnitGroup
    procedure OrderFood;
    procedure OrderNone;
    procedure OrderStorm(aDelay: Word; aForced: Boolean = True);
    procedure OrderWalk(const aLoc: TKMPoint; aUseExactTarget: Boolean = True; aForced: Boolean = True);
    procedure OrderAttackHouse(aTargetHouse: TKMHouse; aForced: Boolean = True);
    procedure OrderFight(aTargetUnit: TKMUnit);

    //Ranged units properties
    property AimingDelay: Byte read GetAimingDelay;
    property FiringDelay: Byte read GetFiringDelay;
    property RangeMin: Single read GetRangeMin;
    property RangeMax: Single read GetRangeMax;
    property ProjectileType: TKMProjectileType read GetProjectileType;
    property AimSoundDelay: Byte read GetAimSoundDelay;

    procedure SetActionFight(aAction: TKMUnitActionType; aOpponent: TKMUnit);

    function GetFightMinRange: Single;
    function GetFightMaxRange(aTileBased: Boolean = False): Single;
    function WithinFightRange(const aValue: TKMPoint): Boolean;
    function OrderDone: Boolean;
    property RequestedFood: Boolean read fRequestedFood write fRequestedFood; //Cleared by Serf delivering food
    property LastShootTime: Cardinal read fLastShootTime;
    function IsRanged: Boolean;
    function InFight(aCountCitizens: Boolean = False): Boolean;
    function InFightAgaist(var aUnit: TKMUnit; aCountCitizens: Boolean = False): Boolean;
    function InAGroup: Boolean;
    function NeedsToReload(aFightAnimLength: Byte): Boolean;
    procedure SetLastShootTime;
    function FindLinkUnit(const aLoc: TKMPoint): TKMUnitWarrior;
    function CheckForEnemy: Boolean;
    function FindEnemy: TKMUnit;
    function PathfindingShouldAvoid: Boolean; override;

    function IsAttackingUnit(aUnit: TKMUnit): Boolean;

    procedure SetAttackingUnit(aUnit: TKMUnit);

    procedure WalkedOut;

    procedure SetActionGoIn(aAction: TKMUnitActionType; aGoDir: TKMGoInDirection; aHouse: TKMHouse); override;

    function ObjToStringShort(const aSeparator: String = '|'): String; override;
    function ObjToString(const aSeparator: String = '|'): String; override;

    procedure Save(SaveStream: TKMemoryStream); override;
    function UpdateState: Boolean; override;
    procedure Paint(aTickLag: Single); override;
  end;


implementation
uses
  TypInfo, Generics.Collections,
  KM_Entity,
  KM_ResTexts, KM_HandsCollection, KM_RenderPool, KM_UnitTaskAttackHouse,
  KM_Hand, KM_HandLogistics, KM_HandTypes, KM_HandEntity,
  KM_UnitActionFight, KM_UnitActionGoInOut, KM_UnitActionWalkTo, KM_UnitActionStay,
  KM_UnitActionStormAttack, KM_Resource, KM_ResUnits, KM_UnitGroup,
  KM_GameParams, KM_CommonUtils, KM_RenderDebug, KM_UnitVisual,
  KM_CommonExceptions,
  KM_ResTypes;


{ TKMUnitWarrior }
constructor TKMUnitWarrior.Create(aID: Cardinal; aUnitType: TKMUnitType; const aLoc: TKMPointDir; aOwner: TKMHandID; aInHouse: TKMHouse);
begin
  inherited;

  fGroup             := nil;
  fOrderTargetUnit   := nil;
  fOrderTargetHouse  := nil;
  fRequestedFood     := False;
  fNextOrder         := woNone;
  fOrder             := woNone;
  fOrderLoc          := aLoc.Loc;
end;


constructor TKMUnitWarrior.Load(LoadStream: TKMemoryStream);
begin
  inherited;

  LoadStream.Read(fGroup, 4); //subst on syncload
  LoadStream.Read(fNextOrder, SizeOf(fNextOrder));
  LoadStream.Read(fNextOrderForced);
  LoadStream.Read(fOrder, SizeOf(fOrder));
  LoadStream.Read(fOrderLoc);
  LoadStream.Read(fOrderTargetHouse, 4); //subst on syncload
  LoadStream.Read(fOrderTargetUnit, 4); //subst on syncload
  LoadStream.Read(fAttackingUnit, 4); //subst on syncload
  LoadStream.Read(fRequestedFood);
  LoadStream.Read(fStormDelay);
  LoadStream.Read(fUseExactTarget);
  LoadStream.Read(FaceDir);
  LoadStream.Read(fLastShootTime);
end;


procedure TKMUnitWarrior.SyncLoad;
begin
  inherited;

  fGroup := TKMUnitGroup(gHands.GetGroupByUID(Integer(fGroup)));
  fOrderTargetUnit := TKMUnitWarrior(gHands.GetUnitByUID(Integer(fOrderTargetUnit)));
  fAttackingUnit := TKMUnitWarrior(gHands.GetUnitByUID(Integer(fAttackingUnit)));
  fOrderTargetHouse := gHands.GetHouseByUID(Integer(fOrderTargetHouse));

  if Action is TKMUnitActionGoInOut then
    TKMUnitActionGoInOut(Action).OnWalkedOut := WalkedOut;
end;


procedure TKMUnitWarrior.Save(SaveStream: TKMemoryStream);
begin
  inherited;

  SaveStream.Write( TKMUnitGroup(fGroup).UID); //Store ID
  SaveStream.Write(fNextOrder, SizeOf(fNextOrder));
  SaveStream.Write(fNextOrderForced);
  SaveStream.Write(fOrder, SizeOf(fOrder));
  SaveStream.Write(fOrderLoc);
  SaveStream.Write(fOrderTargetHouse.UID); //Store ID
  SaveStream.Write(fOrderTargetUnit.UID); //Store ID
  SaveStream.Write(fAttackingUnit.UID); //Store ID
  SaveStream.Write(fRequestedFood);
  SaveStream.Write(fStormDelay);
  SaveStream.Write(fUseExactTarget);
  SaveStream.Write(FaceDir);
  SaveStream.Write(fLastShootTime);
end;


procedure TKMUnitWarrior.CloseUnit;
begin
  //This ensures that pointer usage tracking is reset
  ClearOrderTarget;

  fNextOrder := woNone;

  inherited;
end;


destructor TKMUnitWarrior.Destroy;
begin
  //This ensures that pointer usage tracking is reset
  ClearOrderTarget;
  gHands.CleanUpGroupPointer( TKMUnitGroup(fGroup) );

  inherited;
end;


function TKMUnitWarrior.GetPointer: TKMUnitWarrior;
begin
  Result := TKMUnitWarrior(inherited GetPointer);
end;


procedure TKMUnitWarrior.SetGroup(aGroup: Pointer);
begin
  gHands.CleanUpGroupPointer( TKMUnitGroup(fGroup) );
  fGroup := TKMUnitGroup(aGroup).GetPointer();
end;


procedure TKMUnitWarrior.Dismiss;
begin
  raise Exception.Create('Warrior unit can not be dismissed');
end;


procedure TKMUnitWarrior.DismissCancel;
begin
  raise Exception.Create('Warrior unit can not be dismissed and can not cancel dismiss then');
end;


procedure TKMUnitWarrior.Kill(aFrom: TKMHandID; aShowAnimation, aForceDelay: Boolean);
var
  alreadyDeadOrDying: Boolean;
begin
  alreadyDeadOrDying := IsDeadOrDying; //Inherited will kill the unit
  inherited;

  //After inherited so script events can still check which group the warrior is from
  if not alreadyDeadOrDying then
  begin
    ClearOrderTarget; //This ensures that pointer usage tracking is reset

    //Report to Group that we have died
    if Assigned(OnWarriorDied) then
      OnWarriorDied(Self);
  end;
end;


//Order some food for troops
procedure TKMUnitWarrior.OrderFood;
begin
  if (fCondition < (UNIT_MAX_CONDITION * TROOPS_FEED_MAX)) and not fRequestedFood then
  begin
    gHands[Owner].Deliveries.Queue.AddDemand(nil, Self, wtFood, 1, dtOnce, diHigh2);
    fRequestedFood := True;
  end;
end;


procedure TKMUnitWarrior.OrderNone;
begin
  ClearOrderTarget;

  fNextOrder := woNone;
  fUseExactTarget := False;
end;


procedure TKMUnitWarrior.OrderStorm(aDelay: Word; aForced: Boolean = True);
begin
  //Can't order another storm attack until the current one stops
  if Action is TKMUnitActionStormAttack then Exit;

  ClearOrderTarget;

  fNextOrder := woStorm;
  fNextOrderForced := aForced;
  fStormDelay := aDelay;
end;


procedure TKMUnitWarrior.ClearOrderTarget(aClearAttackingUnit: Boolean = True);
begin
  //Set fOrderTargets to nil, removing pointer if it's still valid
  gHands.CleanUpUnitPointer(fOrderTargetUnit);
  gHands.CleanUpHousePointer(fOrderTargetHouse);
  if aClearAttackingUnit then
    ClearAttackingUnit;
end;


procedure TKMUnitWarrior.ClearAttackingUnit;
begin
  gHands.CleanUpUnitPointer(fAttackingUnit);
end;


procedure TKMUnitWarrior.SetOrderTarget(aUnit: TKMUnit);
begin
  //Remove previous value
  ClearOrderTarget(False); // Don't clear attacking unit
  if aUnit <> nil then
    fOrderTargetUnit := aUnit.GetPointer; //Else it will be nil from ClearOrderTarget
end;


procedure TKMUnitWarrior.DoSetAttackingUnit(aUnit: TKMUnit);
begin
  //Remove previous value
  ClearAttackingUnit;
  if aUnit <> nil then
    fAttackingUnit := aUnit.GetPointer; //Else it will be nil from ClearAttackingUnit
end;


function TKMUnitWarrior.GetAttackingUnit: TKMUnit;
begin
  //If the target unit has died then return nil
  //Don't clear fAttackingUnit here, since we could get called from UI
  //depending on player actions (getters should be side effect free)
  if (fAttackingUnit <> nil) and fAttackingUnit.IsDead then
    Result := nil
  else
    Result := fAttackingUnit;
end;


function TKMUnitWarrior.GetOrderTargetUnit: TKMUnit;
begin
  //If the target unit has died then return nil
  //Don't clear fOrderTargetUnit here, since we could get called from UI
  //depending on player actions (getters should be side effect free)
  if (fOrderTargetUnit <> nil) and fOrderTargetUnit.IsDead then
    Result := nil
  else
    Result := fOrderTargetUnit;
end;


procedure TKMUnitWarrior.SetOrderHouseTarget(aHouse: TKMHouse);
begin
  //Remove previous value
  ClearOrderTarget;
  if aHouse <> nil then
    fOrderTargetHouse := aHouse.GetPointer; //Else it will be nil from ClearOrderTarget
end;


function TKMUnitWarrior.GetOrderHouseTarget:TKMHouse;
begin
  //If the target house has been destroyed then return nil
  //Don't clear fOrderTargetHouse here, since we could get called from UI
  //depending on player actions (getters should be side effect free)
  if (fOrderTargetHouse <> nil) and (fOrderTargetHouse.IsDestroyed) then
    Result := nil
  else
    Result := fOrderTargetHouse;
end;


//Clear target unit/house if they are dead/destroyed
procedure TKMUnitWarrior.UpdateOrderTargets;
begin
  if (fOrderTargetUnit <> nil) and fOrderTargetUnit.IsDead then
    gHands.CleanUpUnitPointer(fOrderTargetUnit);

  if (fOrderTargetHouse <> nil) and fOrderTargetHouse.IsDestroyed then
    gHands.CleanUpHousePointer(fOrderTargetHouse);
end;


//At which range we can fight
function TKMUnitWarrior.GetFightMaxRange(aTileBased: Boolean = False): Single;
begin
  case fType of
    utBowman,
    utCrossbowman,
    utRogue:   Result := RangeMax / (Byte(REDUCE_SHOOTING_RANGE) + 1);
    //During storm attack we look for enemies 1.42 tiles away so we engage enemies easier and don't accidentially walk past them diagonally
    else            if aTileBased and not (Action is TKMUnitActionStormAttack) then
                      Result := 1 //Enemy must maximum be 1 tile away
                    else
                      Result := 1.42; //slightly bigger than sqrt(2) for diagonal fights
  end;
end;


//At which range we can fight
function TKMUnitWarrior.GetFightMinRange: Single;
begin
  case fType of
    utBowman,
    utCrossbowman,
    utRogue:   Result := RangeMin;
    else            Result := 0.5;
  end;
end;


function TKMUnitWarrior.WithinFightRange(const aValue: TKMPoint): Boolean;
begin
  Result := InRange(KMLength(PositionNext, aValue), GetFightMinRange, GetFightMaxRange);
end;


//Is unit a part of the group
//(units are independent when leaving barracks, till they find a group to link to)
function TKMUnitWarrior.InAGroup: Boolean;
begin
  //Event is assigned when unit is added to a group, so we can use it as a marker
  Result := Assigned(OnWarriorDied);
end;


//Used to prevent rate of fire exploit
function TKMUnitWarrior.NeedsToReload(aFightAnimLength: Byte): Boolean;
begin
  Result := (fLastShootTime <> 0) and ((gGameParams.Tick - fLastShootTime) < aFightAnimLength);
end;


//Used to prevent rate of fire exploit
procedure TKMUnitWarrior.SetLastShootTime;
begin
  fLastShootTime := gGameParams.Tick;
end;


//We are actively fighting with an enemy
function TKMUnitWarrior.InFight(aCountCitizens: Boolean = False): Boolean;
begin
  Result := (Action is TKMUnitActionFight)
            and (aCountCitizens or (TKMUnitActionFight(Action).GetOpponent is TKMUnitWarrior))
            and not TKMUnitActionFight(Action).GetOpponent.IsDeadOrDying;
end;


function TKMUnitWarrior.InFightAgaist(var aUnit: TKMUnit; aCountCitizens: Boolean = False): Boolean;
begin
  Result := InFight(aCountCitizens);
  aUnit := nil;
  if Result then
    aUnit := TKMUnitActionFight(Action).GetOpponent;
end;


// Return True if we are attacking or following specified unit
function TKMUnitWarrior.IsAttackingUnit(aUnit: TKMUnit): Boolean;
begin
  if (Self = nil) or (aUnit = nil) then Exit(False);
  
  Result := ((fOrder = woAttackUnit) and (aUnit = GetOrderTargetUnit)) or (aUnit = GetAttackingUnit);
end;


procedure TKMUnitWarrior.SetAttackingUnit(aUnit: TKMUnit);
begin
  DoSetAttackingUnit(aUnit);
end;


function TKMUnitWarrior.IsRanged: Boolean;
begin
  Result := gRes.Units[fType].FightType = ftRanged;
end;


function TKMUnitWarrior.FindLinkUnit(const aLoc: TKMPoint): TKMUnitWarrior;
var
  I: Integer;
  foundUnits: TList<TKMUnit>;
  U: TKMUnit;
  best, L: Single;
begin
  Result := nil;
  best := MaxSingle;

  foundUnits := TList<TKMUnit>.Create;
  gHands[Owner].Units.GetUnitsInRect(KMRect(aLoc.X - LINK_RADIUS,
                                            aLoc.Y - LINK_RADIUS,
                                            aLoc.X + LINK_RADIUS,
                                            aLoc.Y + LINK_RADIUS),
                                     foundUnits);

  for I := 0 to foundUnits.Count - 1 do
  begin
    U := foundUnits[I];
    if (U is TKMUnitWarrior)
    and (U <> Self)
    and (UNIT_TO_GROUP_TYPE[U.UnitType] = UNIT_TO_GROUP_TYPE[fType]) // They must be the same group type
    and TKMUnitWarrior(U).InAGroup then // Check if warrior belongs to some Group
    begin
      L := KMLength(aLoc, U.Position);
      if (L < best) then
      begin
        best := L;
        Result := TKMUnitWarrior(U);
      end;
    end;
  end;

  foundUnits.Free;
end;


//Only the group knows the difference between Walking and Attacking unit, so we need aIsAttackingUnit parameter
function TKMUnitWarrior.GetWarriorActivityText(aIsAttackingUnit: Boolean): UnicodeString;
begin
  //We can't rely on fOrder because it does not get reset, so look at actions/tasks
  if fAction is TKMUnitActionFight then
    if IsRanged then
      Result := gResTexts[TX_UNIT_TASK_FIRING]
    else
      Result := gResTexts[TX_UNIT_TASK_FIGHTING]
  else
  if fAction is TKMUnitActionStormAttack then
    Result := gResTexts[TX_UNIT_TASK_STORM_ATTACK]
  else
  if fTask is TKMTaskAttackHouse then
    Result := gResTexts[TX_UNIT_TASK_ATTACKING_HOUSE]
  else
  if fAction is TKMUnitActionGoInOut then
    Result := gResTexts[TX_UNIT_TASK_MOVING]
  else
  if fAction is TKMUnitActionWalkTo then
    if aIsAttackingUnit then
      Result := gResTexts[TX_UNIT_TASK_ATTACKING]
    else
      Result := gResTexts[TX_UNIT_TASK_MOVING]
  else
    Result := gResTexts[TX_UNIT_TASK_IDLE];
end;


procedure TKMUnitWarrior.SetActionGoIn(aAction: TKMUnitActionType; aGoDir: TKMGoInDirection; aHouse: TKMHouse);
begin
  Assert(aGoDir = gdGoOutside, 'Walking inside is not implemented yet');
  Assert((aHouse.HouseType = htBarracks) or (aHouse.HouseType = htTownHall), 'Only Barracks and TownHall so far');
  inherited;

  TKMUnitActionGoInOut(Action).OnWalkedOut := WalkedOut;
end;


procedure TKMUnitWarrior.OrderWalk(const aLoc: TKMPoint; aUseExactTarget: Boolean = True; aForced: Boolean = True);
begin
  ClearOrderTarget;

  fNextOrder := woWalk;
  fNextOrderForced := aForced;
  fOrderLoc := aLoc;
  fUseExactTarget := aUseExactTarget;
end;


function TKMUnitWarrior.OrderDone: Boolean;
begin
  Result := False;
  if fNextOrder <> woNone then Exit; //We haven't had time to take the order yet, so return False

  //Did we performed the Order?
  case fOrder of
    woNone:         Result := True;
    woWalk:         begin
                      if not fUseExactTarget or KMSamePoint(Position, fOrderLoc) then
                        Result := True
                      else
                      begin
                        Result := False;
                        {//Maybe unit from different group took our place
                        U := fTerrain.UnitsHitTest(fOrderLoc.Loc.X, fOrderLoc.Loc.Y);
                        if U <> nil then}
                      end;
                    end;
    woWalkOut:      Result := IsIdle;
    woAttackUnit:   Result := (GetOrderTargetUnit = nil);
    woAttackHouse:  Result := (GetOrderHouseTarget = nil);
    woStorm:        Result := IsIdle;
  end;
end;


//All units are assigned TTaskAttackHouse which does everything for us (move to position, hit house, abandon, etc.) }
procedure TKMUnitWarrior.OrderAttackHouse(aTargetHouse: TKMHouse; aForced: Boolean = True);
begin
  fNextOrder := woAttackHouse;
  fNextOrderForced := aForced;
  SetOrderHouseTarget(aTargetHouse);
end;


procedure TKMUnitWarrior.OrderFight(aTargetUnit: TKMUnit);
begin
  fNextOrder := woAttackUnit;
  SetOrderTarget(aTargetUnit);
end;


function TKMUnitWarrior.PathfindingShouldAvoid: Boolean;
begin
  Result := Inherited PathfindingShouldAvoid;
  Result := Result and (fNextOrder = woNone); //If we have been given an order we're about to move somewhere 
end;


function TKMUnitWarrior.CheckForEnemy: Boolean;
var
  newEnemy: TKMUnit;
begin
  Result := False; //Didn't find anyone to fight

  //Ranged units should not check for enemy while walking or when facing the wrong way
  if IsRanged and ((not IsIdle) or ((FaceDir <> Direction) and (FaceDir <> dirNA))) then Exit;

  newEnemy := FindEnemy;
  if newEnemy <> nil then
  begin
    OnPickedFight(Self, newEnemy);
    //If the target is close enough attack it now, otherwise OnPickedFight will handle it through Group.OffendersList
    //Remember that AI's AutoAttackRange feature means a melee warrior can pick a fight with someone out of range
    if WithinFightRange(newEnemy.Position) then
      FightEnemy(newEnemy);
    Result := True; //Found someone
  end;
end;


function TKMUnitWarrior.FindEnemy: TKMUnit;
var
  testDir: TKMDirection;
  range: Single;
begin
  Result := nil; //No one to fight
  if not CanInterruptAction then exit;

  if IsRanged then
  begin
    //We are busy with an action (e.g. in a fight)
    if (Action <> nil) and Action.Locked then Exit;

    //We are shooting at house
    if (fTask <> nil) and (fTask is TKMTaskAttackHouse) then Exit;

    //Archers should only look for opponents when they are idle or when they are finishing another fight (function is called by TUnitActionFight)
    if (Action is TKMUnitActionWalkTo)
    and ((GetOrderTargetUnit = nil) or GetOrderTargetUnit.IsDeadOrDying or not WithinFightRange(GetOrderTargetUnit.Position))
    then
      Exit;
  end;

  if IsRanged then
    testDir := Direction //Use direction for ranged attacks, if it was not already specified
  else
    testDir := dirNA;

  range := GetFightMaxRange(True);
  //AI has an "auto attack range" for melee like in TSK/TPR so you can't sneak past them (when idle)
  if not IsRanged and IsIdle and gHands[Owner].IsComputer then
    range := Max(range, gHands[Owner].AI.Setup.AutoAttackRange);

  //This function should not be run too often, as it will take some time to execute (e.g. with lots of warriors in the range area to check)
  Result := gTerrain.UnitsHitTestWithinRad(Position, GetFightMinRange, range, Owner, atEnemy, testDir, not RANDOM_TARGETS);

  //Only stop attacking a house if it's a warrior
  if (fTask <> nil) and (fTask is TKMTaskAttackHouse) and (Action is TKMUnitActionStay) and not (Result is TKMUnitWarrior) then
    Result := nil;
end;


procedure TKMUnitWarrior.SetActionFight(aAction: TKMUnitActionType; aOpponent: TKMUnit);
var
  cycle, step: Byte;
begin
  //Archers should start in the reloading if they shot recently phase to avoid rate of fire exploit
  step := 0; //Default
  cycle := Max(gRes.Units[UnitType].UnitAnim[aAction, Direction].Count, 1);
  if (TKMUnitWarrior(Self).IsRanged) and TKMUnitWarrior(Self).NeedsToReload(cycle) then
    //Skip the unit's animation forward to 1 step AFTER firing
    step := (FiringDelay + (gGameParams.Tick - TKMUnitWarrior(Self).LastShootTime)) mod cycle;

  if (Action is TKMUnitActionWalkTo) and not TKMUnitActionWalkTo(Action).CanAbandonExternal then
    raise ELocError.Create('Unit fight overrides walk', fPositionRound);
  SetAction(TKMUnitActionFight.Create(Self, aAction, aOpponent), step);
end;


procedure TKMUnitWarrior.FightEnemy(aEnemy: TKMUnit);
begin
  Assert(aEnemy <> nil, 'Fight no one?');

  //Free the task or set it up to be resumed afterwards
  if Task <> nil then
  begin
    if (Task is TKMTaskAttackHouse) and not (aEnemy is TKMUnitWarrior) then
      TKMTaskAttackHouse(Task).Phase := 0 //Reset task so it will resume after the fight
    else
      FreeAndNil(fTask); //e.g. TaskAttackHouse
  end;

  DoSetAttackingUnit(aEnemy);

  SetActionFight(uaWork, aEnemy);
  if aEnemy is TKMUnitWarrior then
    TKMUnitWarrior(aEnemy).CheckForEnemy; //Let opponent know he is attacked ASAP
end;


{ See if we can abandon other actions in favor of more important things }
function TKMUnitWarrior.CanInterruptAction(aForced: Boolean = True): Boolean;
begin
  if (Action is TKMUnitActionStay)
    and (Task is TKMTaskAttackHouse) then
    Result := True //We can abandon attack house if the action is stay
  else
    Result := Action.CanBeInterrupted(aForced);
end;


function TKMUnitWarrior.GetFiringDelay: Byte;
const
  SLINGSHOT_FIRING_DELAY = 15; //on which frame slinger fires his rock
  FIRING_DELAY = 0; //on which frame archer fires his arrow/bolt
begin
  Result := 0;
  if IsRanged then
    case UnitType of
      utBowman,
      utCrossbowman: Result := FIRING_DELAY;
      utRogue:  Result := SLINGSHOT_FIRING_DELAY;
      else raise Exception.Create('Unknown shooter');
    end;
end;


function TKMUnitWarrior.GetAimingDelay: Byte;
const
  BOWMEN_AIMING_DELAY_MIN      = 6; //minimum time for bowmen to aim
  BOWMEN_AIMING_DELAY_ADD      = 6; //random component
  SLINGSHOT_AIMING_DELAY_MIN   = 0; //minimum time for slingshot to aim
  SLINGSHOT_AIMING_DELAY_ADD   = 4; //random component
  CROSSBOWMEN_AIMING_DELAY_MIN = 8; //minimum time for crossbowmen to aim
  CROSSBOWMEN_AIMING_DELAY_ADD = 8; //random component
begin
  Result := 0;
  if IsRanged then
    case UnitType of
      utBowman:       Result := BOWMEN_AIMING_DELAY_MIN + KaMRandom(BOWMEN_AIMING_DELAY_ADD{$IFDEF RNG_SPY}, 'TKMUnitWarrior.GetAimingDelay'{$ENDIF});
      utCrossbowman:  Result := CROSSBOWMEN_AIMING_DELAY_MIN + KaMRandom(CROSSBOWMEN_AIMING_DELAY_ADD{$IFDEF RNG_SPY}, 'TKMUnitWarrior.GetAimingDelay 2'{$ENDIF});
      utRogue:        Result := SLINGSHOT_AIMING_DELAY_MIN + KaMRandom(SLINGSHOT_AIMING_DELAY_ADD{$IFDEF RNG_SPY}, 'TKMUnitWarrior.GetAimingDelay 3'{$ENDIF});
      else raise Exception.Create('Unknown shooter');
    end;
end;


function TKMUnitWarrior.GetAimSoundDelay: Byte;
const
  SLINGSHOT_AIMING_SOUND_DELAY = 2;
begin
  Result := 0;
  if UnitType = utRogue then
    Result := SLINGSHOT_AIMING_SOUND_DELAY;
end;


function TKMUnitWarrior.GetAllowAllyToSelect: Boolean;
begin
  // Warriors considered to be allowed to select by allies at the same time as his group is
  Result := (fGroup <> nil) and TKMUnitGroup(fGroup).AllowAllyToSelect;
end;


procedure TKMUnitWarrior.SetAllowAllyToSelect(aAllow: Boolean);
begin
  if fGroup = nil then Exit;

  // Warriors considered to be allowed to select by allies at the same time as his group is
  TKMUnitGroup(fGroup).AllowAllyToSelect := aAllow;
end;


function TKMUnitWarrior.GetRangeMin: Single;
const
  RANGE_ARBALETMAN_MIN  = 4; //KaM: We will shoot a unit standing 4 tiles away, but not one standing 3 tiles away
  RANGE_BOWMAN_MIN      = 4;
  RANGE_SLINGSHOT_MIN   = 4;
begin
  Result := 0;
  if IsRanged then
    case UnitType of
      utBowman:     Result := RANGE_BOWMAN_MIN;
      utCrossbowman: Result := RANGE_ARBALETMAN_MIN;
      utRogue:  Result := RANGE_SLINGSHOT_MIN;
      else raise Exception.Create('Unknown shooter');
    end;
end;


function TKMUnitWarrior.GetRangeMax: Single;
const
  RANGE_ARBALETMAN_MAX  = 10.99; //KaM: Unit standing 10 tiles from us will be shot, 11 tiles not
  RANGE_BOWMAN_MAX      = 10.99;
  RANGE_SLINGSHOT_MAX   = 10.99;
begin
  Result := 0;
  if IsRanged then
    case UnitType of
      utBowman:     Result := RANGE_BOWMAN_MAX;
      utCrossbowman: Result := RANGE_ARBALETMAN_MAX;
      utRogue:  Result := RANGE_SLINGSHOT_MAX;
      else raise Exception.Create('Unknown shooter');
    end;
end;


function TKMUnitWarrior.GetProjectileType: TKMProjectileType;
begin
  Assert(IsRanged, 'Can''t get projectile type for not ranged warriors');
  case UnitType of
    utBowman:     Result := ptArrow;
    utCrossbowman: Result := ptBolt;
    utRogue:  Result := ptSlingRock;
    else raise Exception.Create('Unknown shooter');
  end;
end;


//Override current action if there's an Order in queue paying attention
//to unit WalkTo current position (let the unit arrive on next tile first!)
//As well let the unit finish it's curent Attack action before taking a new order
//This should make units response a bit delayed.
procedure TKMUnitWarrior.TakeNextOrder;
var
  loc: TKMPoint;
begin
  //Make sure attack orders are still valid
  if ((fNextOrder = woAttackUnit) and (GetOrderTargetUnit = nil))
    or ((fNextOrder = woAttackHouse) and (GetOrderHouseTarget = nil)) then
    fNextOrder := woNone;

  case fNextOrder of
    woNone: ;
    woWalk:         begin
                      //We can update existing Walk action with minimum changes
                      if (Action is TKMUnitActionWalkTo)
                        and not TKMUnitActionWalkTo(Action).DoingExchange then
                      begin
                        FreeAndNil(fTask); //e.g. TaskAttackHouse

                        loc := gTerrain.GetClosestTile(fOrderLoc, Position, GetDesiredPassability, fUseExactTarget);

                        TKMUnitActionWalkTo(Action).ChangeWalkTo(loc, 0);
                        fNextOrder := woNone;
                        fOrder := woWalk;
                      end
                      else
                      //Other actions are harder to interrupt
                      if CanInterruptAction(fNextOrderForced) then
                      begin
                        FreeAndNil(fTask);

                        loc := gTerrain.GetClosestTile(fOrderLoc, Position, GetDesiredPassability, fUseExactTarget);

                        //Ranged units instead of attack get walk order to change direction, so they should move in case there was an attack order.
                        //For others there is no need to walk if we reached destination already.
                        if IsRanged or (loc <> fPositionRound) then
                          SetActionWalkToSpot(loc, uaWalk);

                        fNextOrder := woNone;
                        fOrder := woWalk;
                      end;
                    end;
    woWalkOut:      ;
    woAttackUnit:   begin
                      if CanInterruptAction(fNextOrderForced) then
                      begin
                        FreeAndNil(fTask); //e.g. TaskAttackHouse
                        fNextOrder := woNone;
                        fOrder := woAttackUnit;
                        fOrderLoc := GetOrderTargetUnit.Position;
                        FightEnemy(GetOrderTargetUnit);
                      end;
                    end;
    woAttackHouse:  begin
                      //No need to update order  if we are going to attack same house
                      if (fOrder <> woAttackHouse)
                          or (Task = nil)
                          or not (Task is TKMTaskAttackHouse)
                          or (TKMTaskAttackHouse(Task).House <> GetOrderHouseTarget) then
                      begin
                        //Abandon walk so we can take attack house
                        if (Action is TKMUnitActionWalkTo)
                          and not TKMUnitActionWalkTo(Action).DoingExchange
                          and not TKMUnitActionWalkTo(Action).WasPushed then
                          AbandonWalk;

                        //Take attack house order
                        if CanInterruptAction(fNextOrderForced) then
                        begin
                          FreeAndNil(fTask); //e.g. TaskAttackHouse
                          fTask := TKMTaskAttackHouse.Create(Self, GetOrderHouseTarget);
                          fOrder := woAttackHouse;
                          fOrderLoc := Position; //Once the house is destroyed we will position where we are standing
                          fNextOrder := woNone;
                        end;
                      end;
                    end;
    woStorm:        begin
                      //Abandon walk so we can take attack house or storm attack order
                      if (Action is TKMUnitActionWalkTo)
                        and not TKMUnitActionWalkTo(Action).DoingExchange then
                        AbandonWalk;

                      //Storm
                      if CanInterruptAction(fNextOrderForced) then
                      begin
                        FreeAndNil(fTask); //e.g. TaskAttackHouse
                        SetActionStorm(fStormDelay);
                        fNextOrder := woNone;
                        fOrder := woStorm;
                      end;
                    end;
  end;
end;


//Warrior has walked out of the Barracks
procedure TKMUnitWarrior.WalkedOut;
begin
  //Report for duty (Groups will link us or create a new group)
  if Assigned(OnWarriorWalkOut) then
    OnWarriorWalkOut(Self);
end;


{procedure TKMUnitWarrior.ChaseTargetUnit;
begin
  if InFight or (GetOrderTarget = nil) or not CanInterruptAction then Exit;

  //--We don't take advantage of ChangeWalkTo yet for the sake of simplicity?
  if IsRanged then
  begin
    //Check target in range, and if not - chase it / back up from it
    if (KMLength(GetPosition, GetOrderTarget.GetPosition) > GetFightMaxRange) then
    begin
      //Too far away
      if (Action is TUnitActionWalkTo)
      and not TUnitActionWalkTo(Action).DoingExchange then
        TUnitActionWalkTo(Action).ChangeWalkTo(GetOrderTarget, GetFightMaxRange)
      else
      if CanInterruptAction then
        SetActionWalkToUnit(GetOrderTarget, GetFightMaxRange, uaWalk);
    end
    else
    if (KMLength(GetPosition, GetOrderTarget.GetPosition) < GetFightMinRange) then
    begin
      //todo: Archer is too close, back up
    end
    else
      //WithinRange
      FightEnemy(GetOrderTarget);
  end
  else
  //IsMelee
  begin
    if (Action is TUnitActionWalkTo)
    and not TUnitActionWalkTo(Action).DoingExchange then
      TUnitActionWalkTo(Action).ChangeWalkTo(GetOrderTarget, 1)
    else
    if CanInterruptAction then
      SetActionWalkToUnit(GetOrderTarget, 1, uaWalk);
  end;

  fOrder := woAttackUnit;
  fOrderLoc := GetOrderTarget.GetPosition;
end;}


function TKMUnitWarrior.ObjToStringShort(const aSeparator: String = '|'): String;
begin
  if Self = nil then Exit('nil');

  Result := inherited ObjToStringShort(aSeparator) +
            Format('%sWOrder = %s%sNextOrder = %s%sNextOrderForced = %s%sOrderLoc = %s%s' +
                   'HasOTargetU = [%s]%sHasOTargetH = [%s]',
                   [aSeparator,
                    GetEnumName(TypeInfo(TKMWarriorOrder), Integer(fOrder)), aSeparator,
                    GetEnumName(TypeInfo(TKMWarriorOrder), Integer(fNextOrder)), aSeparator,
                    BoolToStr(fNextOrderForced, True), aSeparator,
                    TypeToString(fOrderLoc), aSeparator,
                    BoolToStr(fOrderTargetUnit <> nil, True), aSeparator,
                    BoolToStr(fOrderTargetHouse <> nil, True)]);
end;


function TKMUnitWarrior.ObjToString(const aSeparator: String = '|'): String;
var
  unitStr, attackUStr, houseStr, groupStr: String;
begin
  if Self = nil then Exit('nil');

  groupStr := 'nil';
  unitStr := 'nil';
  houseStr := 'nil';
  attackUStr := 'nil';

  if fGroup <> nil then
    groupStr := TKMUnitGroup(fGroup).ObjToString('|  ');

  if fOrderTargetUnit <> nil then
    unitStr := fOrderTargetUnit.ObjToStringShort('; ');

  if fAttackingUnit <> nil then
    attackUStr := fAttackingUnit.ObjToStringShort('; ');

  if fOrderTargetHouse <> nil then
    houseStr := fOrderTargetHouse.ObjToStringShort('; ');

  Result := inherited ObjToString(aSeparator) +
            Format('%sFaceDir = %s%sOrderTargetU = [%s]%sAttackingU = [%s]%sOrderTargetH = [%s]%sGroup = %s%s',
                   [aSeparator,
                    GetEnumName(TypeInfo(TKMDirection), Integer(FaceDir)), aSeparator,
                    unitStr, aSeparator,
                    attackUStr, aSeparator,
                    houseStr, aSeparator,
                    groupStr, aSeparator]);
end;


function TKMUnitWarrior.UpdateState: Boolean;
begin
  if fAction = nil then
    raise ELocError.Create(gRes.Units[UnitType].GUIName+' has no action at start of TKMUnitWarrior.UpdateState', fPositionRound);

  if IsDeadOrDying then
  begin
    Result := True; //Required for override compatibility
    inherited UpdateState;
    Exit;
  end;

  UpdateOrderTargets;

  if fCondition < UNIT_MIN_CONDITION then
    fThought := thEat; //thDeath checked in parent UpdateState

  //Part 1 - Take orders into execution if there are any
  //Part 2 - UpdateState
  //Part 3 -

  if fNextOrder <> woNone then
    TakeNextOrder;

  if (fTicker mod 6 = 0) and not InFight then
    CheckForEnemy; //Split into separate procedure so it can be called from other places

  Result := True; //Required for override compatibility
  if inherited UpdateState then Exit;

  //Make sure we didn't get an action above
  if Action <> nil then
    Exit;

  SetActionStay(50, uaWalk);
end;


procedure TKMUnitWarrior.Paint(aTickLag: Single);
var
  V: TKMUnitVisualState;
  act: TKMUnitActionType;
  unitPos: TKMPointF;
  fillColor, lineColor: Cardinal;
begin
  inherited;
  if not fVisible then Exit;
  V := fVisual.GetLerp(aTickLag);

  act := V.Action;
  unitPos.X := V.PositionF.X + UNIT_OFF_X + V.SlideX;
  unitPos.Y := V.PositionF.Y + UNIT_OFF_Y + V.SlideY;

  gRenderPool.AddUnit(fType, UID, act, V.Dir, V.AnimStep, V.AnimFraction, unitPos.X, unitPos.Y, gHands[Owner].GameFlagColor, True);

  if fThought <> thNone then
    gRenderPool.AddUnitThought(fType, act, V.Dir, fThought, unitPos.X, unitPos.Y);

  if SHOW_ATTACK_RADIUS or (mlUnitsAttackRadius in gGameParams.VisibleLayers) then
    if IsRanged then
    begin
      fillColor := $40FFFFFF;
      lineCOlor := icWhite;
      if (gMySpectator.Selected = Self)
        or ((gMySpectator.Selected is TKMUnitGroup)
          and (TKMUnitGroup(gMySpectator.Selected).FlagBearer = Self)) then
      begin
        fillColor := icRed and fillColor;
        lineColor := icCyan;
      end;

      gRenderPool.RenderDebug.RenderTiledArea(Position, GetFightMinRange, GetFightMaxRange, GetLength, fillColor, lineColor);
    end;
end;


end.
