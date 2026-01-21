unit KM_UnitGroup;
{$I KaM_Remake.inc}
interface
uses
  Generics.Collections,
  KM_Defaults, KM_CommonClasses, KM_Points, KM_Houses, KM_Units,
  KM_UnitWarrior,
  KM_UnitGroupTypes,
  KM_HandEntity;

type
  TKMUnitGroup = class;
  TKMUnitGroupArray = array of TKMUnitGroup;
  TKMUnitGroupEvent = procedure(aGroup: TKMUnitGroup) of object;

  //Group of warriors
  TKMUnitGroup = class(TKMHandEntityPointer<TKMUnitGroup>)
  private
    fTicker: Cardinal;
    fTargetFollowTicker: Cardinal;
    fMembers: TList<TKMUnitWarrior>;
    fOffenders: TList<TKMUnitWarrior>; // enemy troops, which melee units are going to help with and which will be attacked first by ranged units
    fProtectedRanged: TList<Integer>; // enemy ranged unit ids, that should not be forgotten and removed from fOffenders .
    fUnitsPerRow: Word;
    fTimeSinceHungryReminder: Integer;
    fGroupType: TKMGroupType;
    fDisableHungerMessage: Boolean;
    fBlockPlayerOrders: Boolean; // Block orders from the script
    fManualFormation: Boolean;
    fMembersPushbackCommandsCnt: Word;

    fOrder: TKMGroupOrder; //Remember last order incase we need to repeat it (e.g. to joined members)
    fOrderLoc: TKMPointDir; //Dir is the direction to face after order
    fOrderWalkKind: TKMOrderWalkKind;

    //Avoid accessing these directly
    fOrderTargetUnit: TKMUnit; //Unit we are ordered to attack. This property should never be accessed, use public OrderTarget instead.
    fOrderTargetGroup: TKMUnitGroup; //Unit we are ordered to attack. This property should never be accessed, use public OrderTarget instead.
    fOrderTargetHouse: TKMHouse; //House we are ordered to attack. This property should never be accessed, use public OrderHouseTarget instead.

    //don't saved:
    fMapEdCount: Word;
    fSelectedInUI: TKMUnitWarrior; // Unit selected by the player in GUI. Should not be saved or affect game logic for MP consistency.

    function GetCount: Integer;
    function GetMember(aIndex: Integer): TKMUnitWarrior;
    function GetFlagBearer: TKMUnitWarrior;
    function GetNearestMember(aUnit: TKMUnitWarrior): Integer; overload;
    function GetNearestMember(const aLoc: TKMPoint): TKMUnitWarrior; overload;


    function GetMemberLoc(aIndex: Integer): TKMPoint; overload;
    function GetMemberLocExact(aIndex: Integer): TKMPointExact; overload;
    function GetMemberLocExact(aIndex: Integer; out aExact: Boolean): TKMPoint; overload;


    procedure SetMapEdCount(aCount: Word);
    procedure SetUnitsPerRow(aCount: Word);
    procedure SetDirection(Value: TKMDirection);
    procedure SetCondition(aValue: Integer);
    procedure ClearOrderTarget;
    procedure ClearOffenders;
    procedure HungarianReorderMembers;

    function GetFlagColor: Cardinal;

    procedure SetGroupOrder(aOrder: TKMGroupOrder);
    function GetPushbackLimit: Word; inline;

    function GetOrderTargetUnit: TKMUnit;
    function GetOrderTargetGroup: TKMUnitGroup;
    function GetOrderTargetHouse: TKMHouse;
    procedure SetOrderTargetUnit(aUnit: TKMUnit);
    procedure SetOrderTargetHouse(aHouse: TKMHouse);
    procedure UpdateOrderTargets;

    procedure CheckForFight;
    procedure CheckOrderDone;
    procedure UpdateHungerMessage;

    procedure SelectNearestMember;
    procedure Member_Died(aMember: TKMUnitWarrior);
    procedure Member_PickedFight(aMember: TKMUnitWarrior; aEnemy: TKMUnit);

    function GetCondition: Integer;
    function GetDirection: TKMDirection;
    procedure SetSelectedInUI(aUnit: TKMUnitWarrior);
    function GetSelectedInUI: TKMUnitWarrior;
    procedure UpdateProtectedRanged;
    procedure OffendersPrune;

  protected
    function GetPosition: TKMPoint; inline;
    function GetInstance: TKMUnitGroup; override;
    function GetPositionForDisplayF: TKMPointF; override;
    function GetPositionF: TKMPointF; inline;
    procedure SetOwner(const aOwner: TKMHandID); override;
    function GetIsSelectable: Boolean; override;
  public
    //Each group can have initial order
    //SendGroup - walk to some location
    //AttackPosition - attack something at position (or walk there if its empty)
    MapEdOrder: TKMMapEdOrder;
    OnGroupDied: TKMUnitGroupEvent;

    constructor Create(aUID: Integer; aCreator: TKMUnitWarrior); overload;
    constructor Create(aUID: Integer; aOwner: TKMHandID; aUnitType: TKMUnitType; PosX, PosY: Word; aDir: TKMDirection;
                       aUnitPerRow, aCount: Word); overload;
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure SyncLoad;
    procedure Save(SaveStream: TKMemoryStream); override;
    destructor Destroy; override;

    procedure AddMember(aWarrior: TKMUnitWarrior; aIndex: Integer = -1; aOnlyWarrior: Boolean = True);
    function  MemberByUID(aUID: Integer): TKMUnitWarrior;
    function  HitTest(X,Y: Integer): Boolean;
    procedure SelectFlagBearer;
    function  HasMember(aWarrior: TKMUnitWarrior): Boolean;
    procedure ResetAnimStep;
    function InFight(aCountCitizens: Boolean = False): Boolean; //Fighting and can't take any orders from player
    function InFightAllMembers(aCountCitizens: Boolean = False): Boolean; //Fighting and can't take any orders from player
    function InFightAgaistGroups(var aGroupArray: TKMUnitGroupArray): Boolean; //Fighting agaist specific groups
    function IsAttackingHouse: Boolean; //Attacking house
    function IsAttackingUnit: Boolean;
    function IsIdleToAI(aOrderWalkKindSet: TKMOrderWalkKindSet = []): Boolean;

    property Position: TKMPoint read GetPosition;
    property PositionF: TKMPointF read GetPositionF;

    function IsPositioned(const aLoc: TKMPoint; Dir: TKMDirection): Boolean;
    function IsAllyTo(aEntity: TKMHandEntity): Boolean;
    function CanTakePlayerOrders: Boolean;
    function CanTakeOrdersByScript: Boolean;
    function CanWalkTo(const aTo: TKMPoint; aDistance: Single): Boolean;
    function FightMaxRange: Single;
    function IsRanged: Boolean;
    function IsDead: Boolean;
    function UnitType: TKMUnitType;
    function HasUnitType(aUnitType: TKMUnitType): Boolean;
    function GetOrderText: UnicodeString;
    property GroupType: TKMGroupType read fGroupType;
    property Count: Integer read GetCount;
    property MapEdCount: Word read fMapEdCount write SetMapEdCount;
    property Members[aIndex: Integer]: TKMUnitWarrior read GetMember;
    function GetAliveMember: TKMUnitWarrior;
    property FlagBearer: TKMUnitWarrior read GetFlagBearer;
    function SetGroupPosition(const aValue: TKMPoint): Boolean;
    property Direction: TKMDirection read GetDirection write SetDirection;
    property UnitsPerRow: Word read fUnitsPerRow write SetUnitsPerRow;
    property SelectedUnit: TKMUnitWarrior read GetSelectedInUI write SetSelectedInUI;
    property Condition: Integer read GetCondition write SetCondition;
    property Order: TKMGroupOrder read fOrder;
    property DisableHungerMessage: Boolean read fDisableHungerMessage write fDisableHungerMessage;
    property BlockPlayerOrders: Boolean read fBlockPlayerOrders write fBlockPlayerOrders;
    property ManualFormation: Boolean read fManualFormation write fManualFormation;
    property FlagColor: Cardinal read GetFlagColor;
    class function IsFlagRenderBeforeUnit(aDir: TKMDirection): Boolean; static;

    property OrderLoc: TKMPointDir read fOrderLoc;
    property OrderTargetUnit: TKMUnit read GetOrderTargetUnit write SetOrderTargetUnit;
    property OrderTargetGroup: TKMUnitGroup read GetOrderTargetGroup;
    property OrderTargetHouse: TKMHouse read GetOrderTargetHouse write SetOrderTargetHouse;

    procedure OwnerUpdate(aOwner: TKMHandID; aMoveToNewOwner: Boolean = False);

    procedure OrderAttackHouse(aHouse: TKMHouse; aClearOffenders: Boolean; aForced: Boolean = True);
    procedure OrderAttackUnit(aUnit: TKMUnit; aClearOffenders: Boolean; aForced: Boolean = True);
    procedure OrderFood(aClearOffenders: Boolean; aHungryOnly: Boolean = False);
    procedure OrderFormation(aTurnAmount, aColumnsChange: ShortInt; aClearOffenders: Boolean);
    procedure OrderHalt(aClearOffenders: Boolean; aForced: Boolean = True);
    procedure OrderLinkTo(aTargetGroup: TKMUnitGroup; aClearOffenders: Boolean);
    procedure OrderNone;
    function OrderSplit(aNewLeaderUnitType: TKMUnitType; aNewCnt: Integer; aMixed: Boolean): TKMUnitGroup; overload;
    function OrderSplit(aSplitSingle: Boolean = False): TKMUnitGroup; overload;
    function OrderSplitUnit(aUnit: TKMUnitWarrior; aClearOffenders: Boolean): TKMUnitGroup;
    procedure OrderSplitLinkTo(aGroup: TKMUnitGroup; aCount: Word; aClearOffenders: Boolean);
    procedure OrderStorm(aClearOffenders: Boolean);
    procedure OrderWalk(const aLoc: TKMPoint; aClearOffenders: Boolean; aOrderWalkKind: TKMOrderWalkKind;
                        aDir: TKMDirection = dirNA; aForced: Boolean = True);

    procedure OrderRepeat(aForced: Boolean = True);
    procedure CopyOrderFrom(aGroup: TKMUnitGroup; aUpdateOrderLoc: Boolean; aForced: Boolean = True);

    procedure CloseGroup;
    procedure KillGroup;

    function ObjToStringShort(const aSeparator: string = '|'): string; override;
    function ObjToString(const aSeparator: string = '|'): string; override;

    procedure UpdateState;
    procedure PaintHighlighted(aTickLag: Single; aHandColor, aFlagColor: Cardinal; aDoImmediateRender: Boolean = False; aDoHighlight: Boolean = False; aHighlightColor: Cardinal = 0);
    procedure Paint(aTickLag: Single);

    class function GetDefaultCondition: Integer;
  end;


  //Collection of Groups
  TKMUnitGroups = class
  private
    fGroups: TKMList;

    function GetCount: Integer;
    function GetGroup(aIndex: Integer): TKMUnitGroup;
  public
    constructor Create;
    destructor Destroy; override;

    function AddGroup(aWarrior: TKMUnitWarrior): TKMUnitGroup; overload;
    function AddGroup(aOwner: TKMHandID; aUnitType: TKMUnitType; PosX, PosY: Word; aDir: TKMDirection;
                      aUnitPerRow, aCount: Word): TKMUnitGroup; overload;
    procedure AddGroupToList(aGroup: TKMUnitGroup);
    procedure DeleteGroupFromList(aGroup: TKMUnitGroup);
    procedure RemGroup(aGroup: TKMUnitGroup);
    procedure RemAllGroups;

    property Count: Integer read GetCount;
    property Groups[aIndex: Integer]: TKMUnitGroup read GetGroup; default;
    function GetGroupByUID(aUID: Integer): TKMUnitGroup;
    function GetGroupByMember(aUnit: TKMUnitWarrior): TKMUnitGroup;
    function HitTest(X,Y: Integer): TKMUnitGroup;
    procedure GetGroupsInRect(const aRect: TKMRect; List: TList<TKMUnitGroup>);
    function GetClosestGroup(const aPoint: TKMPoint; aTypes: TKMGroupTypeSet = GROUP_TYPES_VALID): TKMUnitGroup;
    function GetGroupsInRadius(aPoint: TKMPoint; aSqrRadius: Single; aTypes: TKMGroupTypeSet = GROUP_TYPES_VALID): TKMUnitGroupArray;
    function GetGroupsMemberInRadius(aPoint: TKMPoint; aSqrRadius: Single; var aUGA: TKMUnitGroupArray; aTypes: TKMGroupTypeSet = GROUP_TYPES_VALID): TKMUnitArray;

    procedure Clear;

    function WarriorTrained(aUnit: TKMUnitWarrior): TKMUnitGroup;

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad;
    procedure UpdateState;
    procedure Paint(const aRect: TKMRect; aTickLag: Single);
  end;


implementation
uses
  Classes, Math, SysUtils, Types, TypInfo,
  KM_CommonTypes, KM_Entity,
  KM_Game, KM_GameParams, KM_GameUIDTracker,
  KM_Hand, KM_HandsCollection,
  KM_Terrain, KM_CommonUtils,
  KM_ResTexts, KM_RenderPool,
  KM_Hungarian, KM_UnitActionWalkTo, KM_ResUnits, KM_ScriptingEvents,
  KM_UnitActionStormAttack, KM_CommonClassesExt, KM_RenderAux,
  KM_GameTypes, KM_Log, KM_DevPerfLog, KM_DevPerfLogTypes,
  KM_HandTypes, KM_UnitVisual;


const
  HUNGER_CHECK_FREQ = 10; //Check warrior hunger every 1 second


{ TKMUnitGroup }
// Create a Group from a single warrior (short version)
constructor TKMUnitGroup.Create(aUID: Integer; aCreator: TKMUnitWarrior);
begin
  inherited Create(etGroup, aUID, aCreator.Owner);

  fGroupType := UNIT_TO_GROUP_TYPE[aCreator.UnitType];
  Assert(fGroupType in GROUP_TYPES_VALID, 'Can''t assign group type ' + GetEnumName(TypeInfo(TKMGroupType), Integer(fGroupType)));
  fMembers := TList<TKMUnitWarrior>.Create;
  fOffenders := TList<TKMUnitWarrior>.Create;
  fProtectedRanged := TList<Integer>.Create;

  //So when they click Halt for the first time it knows where to place them
  fOrderLoc := KMPointDir(aCreator.Position.X, aCreator.Position.Y, aCreator.Direction);

  AddMember(aCreator);
  UnitsPerRow := 1;
  fMembersPushbackCommandsCnt := 0;
end;


// Create a Group from script (creates all the warriors as well)
constructor TKMUnitGroup.Create(aUID: Integer; aOwner: TKMHandID; aUnitType: TKMUnitType; PosX, PosY: Word;
                                aDir: TKMDirection; aUnitPerRow, aCount: Word);
var
  I: Integer;
  warrior: TKMUnitWarrior;
  doesFit: Boolean;
  unitLoc: TKMPoint;
  newCondition: Word;
  desiredArea: Byte;
begin
  inherited Create(etGroup, aUID, aOwner);

  fGroupType := UNIT_TO_GROUP_TYPE[aUnitType];
  Assert(fGroupType in GROUP_TYPES_VALID, 'Can''t assign group type ' + GetEnumName(TypeInfo(TKMGroupType), Integer(fGroupType)));
  fMembers := TList<TKMUnitWarrior>.Create;
  fOffenders := TList<TKMUnitWarrior>.Create;
  fProtectedRanged := TList<Integer>.Create;

  //So when they click Halt for the first time it knows where to place them
  fOrderLoc := KMPointDir(PosX, PosY, aDir);

  //Whole group should have the same condition
  newCondition := Round(UNIT_MAX_CONDITION * (UNIT_CONDITION_BASE + KaMRandomS2(UNIT_CONDITION_RANDOM{$IFDEF DBG_RNG_SPY}, 'TKMUnitGroup.Create'{$ENDIF})));

  if gGameParams.IsMapEditor then
  begin
    //In MapEd we create only flagholder, other members are virtual
    warrior := TKMUnitWarrior(gHands[aOwner].AddUnit(aUnitType, KMPointDir(PosX, PosY, aDir), False));
    if warrior <> nil then
    begin
      warrior.AnimStep  := UNIT_STILL_FRAMES[aDir];
      AddMember(warrior);
      warrior.Condition := GetDefaultCondition;
      fMapEdCount := aCount;
    end;
  end
  else
  begin
    //We want all of the Group memmbers to be placed in one area
    desiredArea := gTerrain.GetWalkConnectID(KMPoint(PosX, PosY));
    for I := 0 to aCount - 1 do
    begin
      unitLoc := GetPositionInGroup2(PosX, PosY, aDir, I, aUnitPerRow, gTerrain.MapX, gTerrain.MapY, doesFit);
      if not doesFit then Continue;

      warrior := TKMUnitWarrior(gHands[aOwner].AddUnit(aUnitType, KMPointDir(unitLoc, aDir), True, desiredArea));
      if warrior = nil then Continue;

      warrior.AnimStep  := UNIT_STILL_FRAMES[aDir];
      AddMember(warrior, -1, False);
      warrior.Condition := newCondition;
    end;
  end;

  //We could not set it earlier cos it's limited by Count
  UnitsPerRow := aUnitPerRow;
  fMembersPushbackCommandsCnt := 0;
end;


//Load the Group from savegame
constructor TKMUnitGroup.Load(LoadStream: TKMemoryStream);
var
  I, newCount: Integer;
  W: TKMUnitWarrior;
  id: Integer;
begin
  inherited;

  LoadStream.CheckMarker('UnitGroup');
  fMembers := TList<TKMUnitWarrior>.Create;
  fOffenders := TList<TKMUnitWarrior>.Create;
  fProtectedRanged := TList<Integer>.Create;

  LoadStream.Read(fGroupType, SizeOf(fGroupType));
  LoadStream.Read(newCount);
  for I := 0 to newCount - 1 do
  begin
    LoadStream.Read(W, 4); //subst on syncload
    fMembers.Add(W);
  end;

  LoadStream.Read(newCount);
  for I := 0 to newCount - 1 do
  begin
    LoadStream.Read(W, 4); //subst on syncload
    fOffenders.Add(W);
  end;

  LoadStream.Read(fOrder, SizeOf(fOrder));
  LoadStream.Read(fOrderLoc);
  LoadStream.Read(fOrderWalkKind, SizeOf(fOrderWalkKind));
  LoadStream.Read(fOrderTargetGroup, 4); //subst on syncload
  LoadStream.Read(fOrderTargetHouse, 4); //subst on syncload
  LoadStream.Read(fOrderTargetUnit, 4); //subst on syncload
  LoadStream.Read(fTicker);
  LoadStream.Read(fTargetFollowTicker);
  LoadStream.Read(fTimeSinceHungryReminder);
  LoadStream.Read(fUnitsPerRow);
  LoadStream.Read(fDisableHungerMessage);
  LoadStream.Read(fBlockPlayerOrders);
  LoadStream.Read(fManualFormation);
  LoadStream.Read(fMembersPushbackCommandsCnt);
end;


procedure TKMUnitGroup.SyncLoad;
var
  I: Integer;
begin
  inherited;

  //Assign event handlers after load
  for I := 0 to Count - 1 do
  begin
    fMembers[I] := TKMUnitWarrior(gHands.GetUnitByUID(Integer(fMembers[I])));
    fMembers[I].OnWarriorDied := Member_Died;
    fMembers[I].OnPickedFight := Member_PickedFight;
  end;

  for I := 0 to fOffenders.Count - 1 do
    fOffenders[I] := TKMUnitWarrior(gHands.GetUnitByUID(Integer(fOffenders[I])));

  fOrderTargetGroup := gHands.GetGroupByUID(Integer(fOrderTargetGroup));
  fOrderTargetHouse := gHands.GetHouseByUID(Integer(fOrderTargetHouse));
  fOrderTargetUnit  := gHands.GetUnitByUID(Integer(fOrderTargetUnit));
end;


destructor TKMUnitGroup.Destroy;
begin
  //We don't release unit pointers from fMembers, because the group is only destroyed when fMembers.Count = 0
  //or when the game is canceled (then it doesn't matter)
  fMembers.Free;

  //We need to release offenders pointers
  ClearOffenders;
  fOffenders.Free;

  fProtectedRanged.Free;

  ClearOrderTarget; //Free pointers

  inherited;
end;


function TKMUnitGroup.FightMaxRange: Single;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Count - 1 do
    if fMembers[I].GetFightMaxRange > Result then
      Result := fMembers[I].GetFightMaxRange;
end;


procedure TKMUnitGroup.Save(SaveStream: TKMemoryStream);
var
  I: Integer;
begin
  inherited;

  SaveStream.PlaceMarker('UnitGroup');
  SaveStream.Write(fGroupType, SizeOf(fGroupType));
  SaveStream.Write(fMembers.Count);
  for I := 0 to fMembers.Count - 1 do
    SaveStream.Write(fMembers[I].UID);
  SaveStream.Write(fOffenders.Count);
  for I := 0 to fOffenders.Count - 1 do
    SaveStream.Write(fOffenders[I].UID);
  SaveStream.Write(fOrder, SizeOf(fOrder));
  SaveStream.Write(fOrderLoc);
  SaveStream.Write(fOrderWalkKind, SizeOf(fOrderWalkKind));
  SaveStream.Write(fOrderTargetGroup.UID);
  SaveStream.Write(fOrderTargetHouse.UID);
  SaveStream.Write(fOrderTargetUnit.UID);
  SaveStream.Write(fTicker);
  SaveStream.Write(fTargetFollowTicker);
  SaveStream.Write(fTimeSinceHungryReminder);
  SaveStream.Write(fUnitsPerRow);
  SaveStream.Write(fDisableHungerMessage);
  SaveStream.Write(fBlockPlayerOrders);
  SaveStream.Write(fManualFormation);
  SaveStream.Write(fMembersPushbackCommandsCnt);
end;


//Group condition is the Min from all members (so that AI feeds the Group when needed)
function TKMUnitGroup.GetCondition: Integer;
var
  I: Integer;
begin
  Result := UNIT_MAX_CONDITION; //Assign const incase Count=0
  for I := 0 to Count - 1 do
    Result := Min(Result, fMembers[I].Condition);
end;


function TKMUnitGroup.GetCount: Integer;
begin
  Result := fMembers.Count;
end;


function TKMUnitGroup.GetDirection: TKMDirection;
begin
  Result := fOrderLoc.Dir;
end;


function TKMUnitGroup.GetMember(aIndex: Integer): TKMUnitWarrior;
begin
  Result := fMembers[aIndex];
end;


function TKMUnitGroup.GetAliveMember: TKMUnitWarrior;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    Result := fMembers[I];
    if not Result.IsDeadOrDying then
      Exit;
  end;
  Result := nil;
end;


function TKMUnitGroup.GetFlagBearer: TKMUnitWarrior;
begin
  if Self = nil then Exit(nil);
  
  Result := fMembers.Items[0];
end;


function TKMUnitGroup.GetMemberLoc(aIndex: Integer): TKMPoint;
var
  exact: Boolean;
begin
  Result := GetMemberLocExact(aIndex, exact);
end;


function TKMUnitGroup.GetMemberLocExact(aIndex: Integer; out aExact: Boolean): TKMPoint;
begin
  //Allow off map positions so GetClosestTile works properly
  Result := GetPositionInGroup2(fOrderLoc.Loc.X, fOrderLoc.Loc.Y,
                                fOrderLoc.Dir, aIndex, fUnitsPerRow,
                                gTerrain.MapX, gTerrain.MapY,
                                aExact);
end;


//Get member order location within formation
function TKMUnitGroup.GetMemberLocExact(aIndex: Integer): TKMPointExact;
begin
  //Allow off map positions so GetClosestTile works properly
  Result.Loc := GetMemberLocExact(aIndex, Result.Exact);

  //Fits on map and is on passable terrain and have same walkConnect as member current position
  Result.Exact :=     Result.Exact
                  and gTerrain.CheckPassability(Result.Loc, tpWalk)
                  and (gTerrain.GetWalkConnectID(Result.Loc) = gTerrain.GetWalkConnectID(fMembers[aIndex].Position));
end;


function TKMUnitGroup.GetNearestMember(aUnit: TKMUnitWarrior): Integer;
var
  I: Integer;
  dist, best: Single;
begin
  Result := -1;
  best := MaxSingle;
  for I := 0 to Count - 1 do
  if (fMembers[I] <> aUnit) and not fMembers[I].IsDeadOrDying then
  begin
    dist := KMLengthSqr(aUnit.Position, fMembers[I].Position);
    if dist < best then
    begin
      best := dist;
      Result := I;
    end;
  end;
end;


function TKMUnitGroup.GetNearestMember(const aLoc: TKMPoint): TKMUnitWarrior;
var
  I: Integer;
  dist, best: Single;
begin
  Result := nil;
  best := MaxSingle;
  for I := 0 to Count - 1 do
  if not fMembers[I].IsDeadOrDying then
  begin
    dist := KMLengthSqr(aLoc, fMembers[I].Position);
    if dist < best then
    begin
      best := dist;
      Result := fMembers[I];
    end;
  end;
end;


//Get current groups location (we use flagholder)
function TKMUnitGroup.GetPosition: TKMPoint;
begin
  if not IsDead then
    Result := fMembers[0].Position
  else
    Result := KMPOINT_ZERO;
end;


function TKMUnitGroup.SetGroupPosition(const aValue: TKMPoint): Boolean;
begin
  Assert(gGameParams.IsMapEditor);

  Result := fMembers[0].SetUnitPosition(aValue);
  fOrderLoc.Loc := fMembers[0].Position; //Don't assume we can move to aValue
end;


procedure TKMUnitGroup.SetSelectedInUI(aUnit: TKMUnitWarrior);
begin
  Assert(HasMember(aUnit), 'Cant''t select unit that is not a groups member');
  fSelectedInUI := aUnit;
end;


function TKMUnitGroup.GetSelectedInUI: TKMUnitWarrior;
begin
  if Self = nil then Exit(nil);

  if (fSelectedInUI = nil) and (Count > 0) then
    fSelectedInUI := FlagBearer;
  Result := fSelectedInUI;
end;


procedure TKMUnitGroup.SetGroupOrder(aOrder: TKMGroupOrder);
begin
  fOrder := aOrder;
  fMembersPushbackCommandsCnt := 0;
end;


procedure TKMUnitGroup.SetCondition(aValue: Integer);
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    fMembers[I].Condition := aValue;
end;


procedure TKMUnitGroup.SetDirection(Value: TKMDirection);
begin
  Assert(gGameParams.IsMapEditor);
  fOrderLoc.Dir := Value;
  fMembers[0].Direction := Value;
end;


procedure TKMUnitGroup.SetMapEdCount(aCount: Word);
begin
  fMapEdCount := aCount;

  // Ensure that fUnitsPerRow is valid (less than or equal to fMapEdCount)
  SetUnitsPerRow(fUnitsPerRow);
end;


procedure TKMUnitGroup.SetUnitsPerRow(aCount: Word);
begin
  if gGameParams.IsMapEditor then
    fUnitsPerRow := EnsureRange(aCount, 1, fMapEdCount)
  else
    fUnitsPerRow := EnsureRange(aCount, 1, Count);
end;


//Locally stored limit, save it just to avoid its calculation every time
function TKMUnitGroup.GetPushbackLimit: Word;
const
  //Const values were received from tests
  ORDERWALK_PUSHBACK_PER_MEMBER_MAX_CNT = 2.5;
  COUNT_POWER_COEF = 1.07;
begin
  //Progressive formula, since for very large groups (>100 members) we neen to allow more pushbacks,
  //otherwise it will be hard to group to get to its position on a crowed areas
  Result := Round(Math.Power(Count, COUNT_POWER_COEF) * ORDERWALK_PUSHBACK_PER_MEMBER_MAX_CNT);
end;


procedure TKMUnitGroup.AddMember(aWarrior: TKMUnitWarrior; aIndex: Integer = -1; aOnlyWarrior: Boolean = True);
begin
  Assert(fMembers.IndexOf(aWarrior) = -1, 'We already have this Warrior in group');
  if aIndex <> -1 then
    fMembers.Insert(aIndex, aWarrior.GetPointer)
  else
    fMembers.Add(aWarrior.GetPointer);

  //Member reports to Group if something happens to him, so that Group can apply its logic
  aWarrior.OnPickedFight := Member_PickedFight;
  aWarrior.OnWarriorDied := Member_Died;
  aWarrior.SetGroup(Self);
  // Face warrior as at our orderLoc
  aWarrior.FaceDir := fOrderLoc.Dir;
end;


function TKMUnitGroup.HasMember(aWarrior: TKMUnitWarrior): Boolean;
begin
  Result := fMembers.IndexOf(aWarrior) <> -1;
end;


//Used by the MapEd after changing direction (so warriors are frozen on the right frame)
procedure TKMUnitGroup.ResetAnimStep;
begin
  Assert(gGameParams.IsMapEditor);
  fMembers[0].AnimStep := UNIT_STILL_FRAMES[fMembers[0].Direction];
end;


//If the player is allowed to issue orders to group
function TKMUnitGroup.CanTakePlayerOrders: Boolean;
begin
  Result := (IsRanged or not InFight) and not fBlockPlayerOrders;
end;


//If the script is allowed to issue orders to group
function TKMUnitGroup.CanTakeOrdersByScript: Boolean;
begin
  Result := (IsRanged or not InFight);
end;


function TKMUnitGroup.CanWalkTo(const aTo: TKMPoint; aDistance: Single): Boolean;
begin
  Result := (Count > 0) and fMembers[0].CanWalkTo(aTo, aDistance);
end;


// Group is dead, but still exists cos of pointers to it
function TKMUnitGroup.IsDead: Boolean;
begin
  Result := (Count = 0);
end;


function TKMUnitGroup.IsRanged: Boolean;
begin
  Result := (fGroupType = gtRanged);
end;


function TKMUnitGroup.GetIsSelectable: Boolean;
begin
  Result := not IsDead;
end;


procedure TKMUnitGroup.CloseGroup;
var
  I: Integer;
  member: TKMUnit;
begin
  for I := fMembers.Count - 1 downto 0 do
  begin
    // Member is already 'closed'
    member := fMembers[I];
    gHands.CleanUpUnitPointer(member);
  end;

  fMembers.Clear;
end;


procedure TKMUnitGroup.KillGroup;
var
  I: Integer;
begin
  for I := fMembers.Count - 1 downto 0 do
    fMembers[I].Kill(HAND_NONE, True, False);
end;


// Select nearest member for group. Or set it to nil it no other members were found
procedure TKMUnitGroup.SelectNearestMember;
var
  newSel: Integer;
begin
  // Transfer selection to nearest member
  newSel := GetNearestMember(fSelectedInUI);
  fSelectedInUI := nil;
  if newSel <> -1 then
    fSelectedInUI := fMembers[newSel];
end;


//Member reports that he has died (or been killed)
procedure TKMUnitGroup.Member_Died(aMember: TKMUnitWarrior);
var
  I: Integer;
  newSel: Integer;
begin
  if aMember = nil then
    Exit;

  if aMember.HitPointsInvulnerable then
    Exit;

  I := fMembers.IndexOf(aMember);
  Assert(I <> -1, 'No such member');

  if (aMember = fSelectedInUI) then
    SelectNearestMember;

  fMembers.Delete(I);

  //Move nearest member to placeholders place
  if I = 0 then
  begin
    newSel := GetNearestMember(aMember);
    if newSel <> -1 then
      fMembers.Exchange(newSel, 0);
  end;

  gHands.CleanUpUnitPointer(TKMUnit(aMember));

  SetUnitsPerRow(fUnitsPerRow);

  //If Group has died report to owner
  if IsDead and Assigned(OnGroupDied) then
    OnGroupDied(Self);

  //Only repeat the order if we are not in a fight (since bowmen can still take orders when fighting)
  if not IsDead and CanTakePlayerOrders and not InFight then
    OrderRepeat(False);
end;


//Member got in a fight
//Remember who we are fighting with, to guide idle units to
//This only works for melee offenders(?)
procedure TKMUnitGroup.Member_PickedFight(aMember: TKMUnitWarrior; aEnemy: TKMUnit);
begin
  // Add offender only if its a werrior and we did not have it in the list yet
  // there is no much harm in duplicate offenders,
  // but in some cases it could mean, that this offender will be attacked more frequently
  // because of KaMRandom(Length(fOffenders)) code
  if (aEnemy is TKMUnitWarrior)
    and not fOffenders.Contains(TKMUnitWarrior(aEnemy)) then
    fOffenders.Add(TKMUnitWarrior(aEnemy).GetPointer);
end;


procedure TKMUnitGroup.UpdateProtectedRanged;
var
  I: Integer;
  U: TKMUnit;
begin
  for I := 0 to Count - 1 do
    if fMembers[I].InFight then
    begin
      U := fMembers[i].GetAttackingUnit();
      if TKMUnitWarrior(U).IsRanged then
        fProtectedRanged.Add(U.UID);
    end;
end;

procedure TKMUnitGroup.OffendersPrune;

  function ForgetOffender(aOffender: TKMUnitWarrior; aForgetRangedOffenders: Boolean): Boolean;
  begin
    Result := False;

    // Already dying
    if aOffender.IsDeadOrDying then Exit(True);

    // Offender could become an ally from script
    if IsAllyTo(aOffender) then Exit(True);

    // Remove ranged offenders if we are in fight with melee units for melee units groups
    if aForgetRangedOffenders and aOffender.IsRanged and not fProtectedRanged.Contains(aOffender.UID) then Exit(True);
  end;
var
  I: Integer;
  U: TKMUnit;
  forgetRangedOffenders: Boolean;
begin
  // If we are Melee and we are fighting with Melee we should forget about the Ranged offenders we have
  forgetRangedOffenders := False;
  if not IsRanged then
    for I := 0 to fOffenders.Count - 1 do
      if not fOffenders[I].IsRanged then
      begin
        forgetRangedOffenders := True;
        UpdateProtectedRanged();
        Break;
      end;

  for I := fOffenders.Count - 1 downto 0 do
  if ForgetOffender(fOffenders[I], forgetRangedOffenders) then
  begin
    U := fOffenders[I]; // Need to pass var
    gHands.CleanUpUnitPointer(U);
    fOffenders.Delete(I);

    if fOffenders.Count = 0 then
      OrderRepeat;
  end;

  fProtectedRanged.Clear();
end;


// If we picked up a fight, while doing any other order - manage it here
procedure TKMUnitGroup.CheckForFight;
var
  I, K: Integer;
  fightWasOrdered: Boolean;
  offender: TKMUnitWarrior;
begin
  // Check on our offenders and remove ones we dont care about anymore
  OffendersPrune;

  //Fight is over
  if fOffenders.Count = 0 then Exit;

  if IsRanged then
  begin
    fightWasOrdered := False;
    for I := 0 to Count - 1 do
      if not fMembers[I].InFight then
        //If there are several enemies within range, shooting any of the offenders is first priority
        //If there are no offenders in range then CheckForEnemy will pick a new target
        //Archers stay still and attack enemies only within their range without walking to/from them
        for K := 0 to fOffenders.Count - 1 do
          if fMembers[I].WithinFightRange(fOffenders[K].Position) then
          begin
            fMembers[I].OrderFight(fOffenders[K]);
            fightWasOrdered := True;
          end;

    //If nobody in the group is in a fight and all offenders are out of range then clear offenders
    //(archers should forget about out of range offenders since they won't walk to them like melee)
    if not fightWasOrdered and not InFight then
    begin
      ClearOffenders;
      OrderRepeat;
    end;
  end
  else
  begin
    //Idle members should help their comrades
    for I := 0 to Count - 1 do
      if not fMembers[I].InFight then
      begin
        offender := nil;

        // Check if this member already attacking some of the offenders. He could be not in fight, but just walking towards enemy
        for K := 0 to fOffenders.Count - 1 do
          if fMembers[I].IsAttackingUnit(fOffenders[K]) then
          begin
            offender := fOffenders[K];
            Break;
          end;

        if offender = nil then
          offender := fOffenders[KaMRandom(fOffenders.Count{$IFDEF DBG_RNG_SPY}, 'TKMUnitGroup.CheckForFight'{$ENDIF})];

        fMembers[I].OrderWalk(offender.PositionNext, False);
        // Set warrior attacking some offender, to avoid switching to another offender
        fMembers[I].SetAttackingUnit(offender);
      end;
  end;
end;


//Check if order has been executed and if necessary attempt to repeat it
procedure TKMUnitGroup.CheckOrderDone;
var
  I: Integer;
  orderExecuted: Boolean;
  P: TKMPointExact;
  U: TKMUnitWarrior;
  pushbackLimit: Word;
  pushbackLimitReached: Boolean;
begin
  orderExecuted := False;

  //1. Check the Order
  //2. Attempt to finish the order
  case fOrder of
    goNone:         orderExecuted := False;
    goWalkTo:       begin
                      orderExecuted := True;
                      pushbackLimit := GetPushbackLimit; //Save it to avoid recalc for every unit
                      for I := 0 to Count - 1 do
                      begin
                        pushbackLimitReached := fMembersPushbackCommandsCnt > pushbackLimit;
                        orderExecuted := orderExecuted and fMembers[I].IsIdle and (fMembers[I].OrderDone or pushbackLimitReached);

                        if fMembers[I].OrderDone then
                        begin
                          //If the unit is idle make them face the right direction
                          if fMembers[I].IsIdle
                          and (fOrderLoc.Dir <> dirNA) and (fMembers[I].Direction <> fOrderLoc.Dir) then
                          begin
                            fMembers[I].Direction := fOrderLoc.Dir;
                            fMembers[I].SetActionStay(50, uaWalk); //Make sure the animation still frame is updated
                          end;
                        end
                        else
                          //Guide Idle and pushed units back to their places
                          if not pushbackLimitReached
                            and (fMembers[I].IsIdle
                                 or ((fMembers[I].Action is TKMUnitActionWalkTo) and TKMUnitActionWalkTo(fMembers[I].Action).WasPushed)) then
                          begin
                            P := GetMemberLocExact(I);
                            fMembers[I].OrderWalk(P.Loc, P.Exact);
                            fMembersPushbackCommandsCnt := Min(fMembersPushbackCommandsCnt + 1, High(Word));
                          end;
                      end;
                    end;
    goAttackHouse:  begin
                      //It is TaskAttackHouse responsibility to execute it
                      orderExecuted := (OrderTargetHouse = nil) or IsAllyTo(OrderTargetHouse); //Target could become ally from script
                    end;
    goAttackUnit:   begin
                      if IsRanged then
                      begin
                        //Ranged units must kill target unit only
                        //Then they will attack anything within their reach by themselves
                        orderExecuted := (OrderTargetUnit = nil) or IsAllyTo(OrderTargetUnit); //Target could become ally from script

                        if not orderExecuted then
                          //If our leader is out of range (enemy has walked away) we need to walk closer
                          if (KMLength(fOrderLoc.Loc, OrderTargetUnit.Position) > fMembers[0].GetFightMaxRange) then
                            OrderAttackUnit(OrderTargetUnit, False)
                          else
                            //Our leader is in range so each member should get into position
                            for I := 0 to Count - 1 do
                            if fMembers[I].IsIdle then
                            begin
                              P := GetMemberLocExact(I);
                              if KMSamePoint(fMembers[I].Position, P.Loc)
                              or (KMLength(fMembers[I].Position, OrderTargetUnit.Position) <= fMembers[I].GetFightMaxRange) then
                              begin
                                //We are at the right spot, so face towards enemy
                                fMembers[I].Direction := KMGetDirection(fMembers[I].PositionNext, OrderTargetUnit.PositionNext);
                                fMembers[I].FaceDir := fMembers[I].Direction;
                                if not fMembers[I].CheckForEnemy then
                                  //If we are too close to shoot, make sure the animation still frame is still updated
                                  fMembers[I].SetActionStay(10, uaWalk);
                              end
                              else
                              begin
                                //Too far away. Walk to the enemy in our formation
                                fMembers[I].OrderWalk(P.Loc, P.Exact);
                                fMembers[I].FaceDir := fOrderLoc.Dir;
                              end;
                            end;
                      end
                      else
                      begin
                        //Melee units must kill target unit and its Group
                        orderExecuted :=
                              //Target could become ally from script
                              ((OrderTargetUnit = nil)  or IsAllyTo(OrderTargetUnit))
                          and ((OrderTargetGroup = nil) or IsAllyTo(OrderTargetGroup));

                        if (OrderTargetUnit <> nil) and not IsAllyTo(OrderTargetUnit) then //Target could become ally from script
                        begin
                          //See if target is escaping
                          if not KMSamePoint(OrderTargetUnit.PositionNext, fOrderLoc.Loc) then
                          begin
                            Inc(fTargetFollowTicker);
                            //It's wasteful to run pathfinding to correct route every step of the way, so if the target unit
                            //is within 4 tiles, update every step. Within 8, every 2 steps, 12, every 3 steps, etc.
                            if fTargetFollowTicker mod Max((Round(KMLengthDiag(GetPosition, OrderTargetUnit.Position)) div 4), 1) = 0 then
                              OrderAttackUnit(OrderTargetUnit, False);
                          end;

                          for I := 0 to Count - 1 do
                            if fMembers[I].IsIdle then
                            begin
                              P := GetMemberLocExact(I);
                              fMembers[I].OrderWalk(P.Loc, P.Exact);
                            end;
                        end;

                        //If Enemy was killed, but target Group still exists
                        //Group could become an ally from script
                        if (OrderTargetUnit = nil) and ((OrderTargetGroup <> nil) and not IsAllyTo(OrderTargetGroup)) then
                        begin
                          //Old enemy has died, change target to his comrades
                          U := OrderTargetGroup.GetNearestMember(fMembers[0].Position);
                          if U <> nil then // U could be nil in some rare cases (probably some rare bug with unit kills from scripts), just ignore that situation for now
                            OrderAttackUnit(U, False)
                          else
                            orderExecuted := True; //Could rarely happen, as described above
                        end;
                      end;
                    end;
    goStorm:        orderExecuted := False;
  end;

  if orderExecuted then
  begin
    for I := 0 to Count - 1 do
    if (fOrderLoc.Dir <> dirNA) and fMembers[I].IsIdle then //Don't change direction whilst f.e. walking
      fMembers[I].Direction := fOrderLoc.Dir;
    OrderNone;
  end;
end;


//Check if at least 1 group member is fighting
//Fighting with citizens does not count by default
function TKMUnitGroup.InFight(aCountCitizens: Boolean = False): Boolean;
var
  I: Integer;
begin
  Result := False;

  for I := 0 to Count - 1 do
    if fMembers[I].InFight(aCountCitizens) then
      Exit(True);
end;


//Check if all group members are fighting
//Fighting with citizens does not count by default
function TKMUnitGroup.InFightAllMembers(aCountCitizens: Boolean = False): Boolean;
var
  I: Integer;
begin
  Result := True;

  for I := 0 to Count - 1 do
    if not fMembers[I].InFight(aCountCitizens) then
      Exit(False);
end;


function TKMUnitGroup.InFightAgaistGroups(var aGroupArray: TKMUnitGroupArray): Boolean;
var
  I, K, cnt: Integer;
  U: TKMUnit;
  G: TKMUnitGroup;
  check: Boolean;
begin
  cnt := 0;
  for I := 0 to Count - 1 do
  begin
    U := nil;
    if not fMembers[I].IsDeadOrDying
      and fMembers[I].InFightAgaist(U, False)
      and (U <> nil)
      and not U.IsDeadOrDying then
    begin
      G := gHands[U.Owner].UnitGroups.GetGroupByMember( TKMUnitWarrior(U) );
      if (G <> nil) then // Group can be nil if soldiers go out of Barracks
      begin
        check := True;
        for K := 0 to cnt - 1 do
          if (aGroupArray[K] = G) then
          begin
            check := False;
            Break;
          end;
        if check then
        begin
          if (Length(aGroupArray) >= cnt) then
            SetLength(aGroupArray, cnt + 12);
          aGroupArray[cnt] := G;
          cnt := cnt + 1;
        end;
      end;
    end;
  end;
  SetLength(aGroupArray,cnt);

  Result := (Length(aGroupArray) > 0);
end;


function TKMUnitGroup.IsAttackingHouse: Boolean;
var
  I: Integer;
begin
  Result := False;

  for I := 0 to Count - 1 do
  if (fMembers[I].Task <> nil)
  and (fMembers[I].Task.TaskType = uttAttackHouse) then
    Exit(True);
end;


function TKMUnitGroup.IsAttackingUnit: Boolean;
begin
  Result := (fOrder = goAttackUnit) and (OrderTargetUnit <> nil);
end;


function TKMUnitGroup.IsIdleToAI(aOrderWalkKindSet: TKMOrderWalkKindSet = []): Boolean;
begin
  //First check that the previous order has completed
  if fOrder = goWalkTo then
    Result := (fOrderWalkKind in aOrderWalkKindSet) or (KMLengthDiag(Position, fOrderLoc.Loc) < 2)
  else
    Result := (fOrder = goNone);

  //Even fighting citizens should also stop the AI repositioning the group
  Result := Result and not InFight(True);
  //Also wait until we have dealt with all offenders
  Result := Result and (fOffenders.Count = 0);
end;


function TKMUnitGroup.IsPositioned(const aLoc:TKMPoint; Dir: TKMDirection): Boolean;
var
  I: Integer;
  P: TKMPointExact;
  U: TKMUnitWarrior;
begin
  Result := True;
  for I := 0 to Count - 1 do
  begin
    P.Loc := GetPositionInGroup2(aLoc.X, aLoc.Y, Dir, I, fUnitsPerRow,
                                 gTerrain.MapX, gTerrain.MapY,
                                 P.Exact);
    U := fMembers[I];
    Result := U.IsIdle and KMSamePoint(U.Position, P.Loc) and (U.Direction = Dir);
    if not Result then Exit;
  end;
end;


function TKMUnitGroup.IsAllyTo(aEntity: TKMHandEntity): Boolean;
begin
  Result := gHands[Owner].Alliances[aEntity.Owner] = atAlly;
end;


function TKMUnitGroup.MemberByUID(aUID: Integer): TKMUnitWarrior;
var
  I: Integer;
begin
  Result := nil;

  for I := 0 to Count - 1 do
  if (fMembers[I].UID = aUID) and not fMembers[I].IsDead then
    Exit(fMembers[I]);
end;


function TKMUnitGroup.HitTest(X,Y: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;

  for I := 0 to Count - 1 do
  if fMembers[I].HitTest(X, Y) and not fMembers[I].IsDead then
    Exit(True);
end;


procedure TKMUnitGroup.SelectFlagBearer;
begin
  fSelectedInUI := fMembers[0];
end;


procedure TKMUnitGroup.SetOwner(const aOwner: TKMHandID);
var
  I: Integer;
begin
  inherited SetOwner(aOwner);

  for I := 0 to fMembers.Count - 1 do
    fMembers[I].Owner := aOwner;
end;


procedure TKMUnitGroup.OwnerUpdate(aOwner: TKMHandID; aMoveToNewOwner: Boolean = False);
var
  I: Integer;
begin
  if aMoveToNewOwner and (Owner <> aOwner) then
  begin
    Assert(gGameParams.Mode = gmMapEd); // Allow to move existing Unit directly only in MapEd
    gHands[Owner].UnitGroups.DeleteGroupFromList(Self);
    gHands[aOwner].UnitGroups.AddGroupToList(Self);
  end;

  // Update members owner first so we will move units to new hand units first
  for I := 0 to fMembers.Count - 1 do
    fMembers[I].OwnerUpdate(aOwner, aMoveToNewOwner);

  // Update group owner after members owner
  Owner := aOwner;
end;


//All units are assigned TTaskAttackHouse which does everything for us (move to position, hit house, abandon, etc.)
procedure TKMUnitGroup.OrderAttackHouse(aHouse: TKMHouse; aClearOffenders: Boolean; aForced: Boolean = True);
var
  I: Integer;
begin
  Assert(aHouse <> nil);

  //Can attack only enemy houses
  if gHands[Owner].Alliances[aHouse.Owner] <> atEnemy then Exit;

  if aClearOffenders and CanTakePlayerOrders then
    ClearOffenders;

  SetGroupOrder(goAttackHouse);
  fOrderLoc := KMPointDir(0, 0, dirNA);
  OrderTargetHouse := aHouse;

  for I := 0 to Count - 1 do
    fMembers[I].OrderAttackHouse(aHouse, aForced);

  //Script may have additional event processors
  gScriptEvents.ProcGroupOrderAttackHouse(Self, aHouse);
end;


procedure TKMUnitGroup.OrderAttackUnit(aUnit: TKMUnit; aClearOffenders: Boolean; aForced: Boolean = True);
var
  I: Integer;
  nodeList: TKMPointList;
  P: TKMPointExact;
begin
  Assert(aUnit <> nil);

  //If unit is already dying ignore the order
  if aUnit.IsDeadOrDying then Exit;

  //Can attack only enemy units
  if gHands[Owner].Alliances[aUnit.Owner] <> atEnemy then Exit;

  if aClearOffenders and CanTakePlayerOrders then
    ClearOffenders;

  if IsRanged then
  begin
    //Ranged units should walk in formation to within range of the enemy
    SetGroupOrder(goAttackUnit);
    OrderTargetUnit := aUnit;

    //First choose fOrderLoc, which is where the leader will stand to shoot
    if (KMLength(fMembers[0].Position, OrderTargetUnit.Position) > fMembers[0].GetFightMaxRange) then
    begin
      nodeList := TKMPointList.Create;
      try
        if gGame.Pathfinding.Route_Make(fMembers[0].Position, OrderTargetUnit.PositionNext, [tpWalk], fMembers[0].GetFightMaxRange, nil, nodeList) then
        begin
          fOrderLoc.Loc := nodeList[nodeList.Count-1];
          fOrderLoc.Dir := KMGetDirection(nodeList[nodeList.Count-1], OrderTargetUnit.PositionNext);
          HungarianReorderMembers; //We are about to get them to walk to fOrderLoc
        end
        else
        begin
          OrderTargetUnit := nil; //Target cannot be reached, so abort completely
          SetGroupOrder(goNone);
          FreeAndNil(nodeList);
          Exit;
        end;
      finally
        FreeAndNil(nodeList);
      end;
    end
    else
    begin
      fOrderLoc.Loc := fMembers[0].Position; //Leader is already within range
      fOrderLoc.Dir := KMGetDirection(fMembers[0].Position, OrderTargetUnit.PositionNext);
    end;

    //Next assign positions for each member (including leader)
    for I := 0 to Count - 1 do
    begin
      //Check target in range, and if not - chase it / back up from it
      P := GetMemberLocExact(I);
      if not KMSamePoint(fMembers[I].Position, P.Loc)
        and((KMLength(fMembers[I].PositionNext, OrderTargetUnit.Position) > fMembers[I].GetFightMaxRange)
        or (KMLength(fMembers[I].PositionNext, OrderTargetUnit.Position) < fMembers[I].GetFightMinRange)) then
      begin
        //Too far/close. Walk to the enemy in formation
        fMembers[I].OrderWalk(P.Loc, P.Exact, aForced);
        fMembers[I].FaceDir := fOrderLoc.Dir;
      end
      else
        if not fMembers[I].IsIdle then
        begin

          // We are at the right spot already. Restart what we are doing (with stub Walk order) only if the direction has changed
          // (important for archers who got order to attack different enemy).
          // However also make stub walk order in case we are not fighting
          // This is to prevent attack restart (bow twitching f.e.) on every new attack enemy command
          if (fMembers[I].FaceDir <> fOrderLoc.Dir) or not fMembers[I].InFight(True) then
          begin
            fMembers[I].OrderWalk(fMembers[I].PositionNext, True, aForced); //We are at the right spot already, just need to abandon what we are doing
            fMembers[I].FaceDir := fOrderLoc.Dir;
          end;
        end
        else
        begin
          //We are within range, so face towards the enemy
          //Don't fight this specific enemy, giving archers exact targets is too abusable in MP. Choose random target in that direction.
          fMembers[I].Direction := KMGetDirection(fMembers[I].PositionNext, aUnit.PositionNext);
          fMembers[I].FaceDir := fMembers[I].Direction;
          if not fMembers[I].CheckForEnemy then
            //If we are too close to shoot, make sure the animation still frame is still updated
            fMembers[I].SetActionStay(10, uaWalk);
        end;
    end;
  end
  else
  begin
    //Walk in formation towards enemy,
    //Members will take care of attack when we approach
    OrderWalk(aUnit.PositionNext, False, wtokNone, dirNA, aForced);

    // Set members to as 'attacking enemy unit', since we are going to attack it
    for I := 0 to Count - 1 do
      Members[I].SetAttackingUnit(aUnit);

    //Revert Order to proper one (we disguise Walk)
    SetGroupOrder(goAttackUnit);
    fOrderLoc := KMPointDir(aUnit.PositionNext, dirNA); //Remember where unit stand
    OrderTargetUnit := aUnit;
  end;

  //Script may have additional event processors
  gScriptEvents.ProcGroupOrderAttackUnit(Self, aUnit);
end;


//Order some food for troops
procedure TKMUnitGroup.OrderFood(aClearOffenders: Boolean; aHungryOnly: Boolean = False);
var
  I: Integer;
begin
  if aClearOffenders and CanTakePlayerOrders then
    ClearOffenders;

  for I := 0 to Count - 1 do
    if not aHungryOnly or (fMembers[I].Condition <= UNIT_MIN_CONDITION) then
      fMembers[I].OrderFood;
end;


procedure TKMUnitGroup.OrderFormation(aTurnAmount, aColumnsChange: ShortInt; aClearOffenders: Boolean);
begin
  if IsDead then Exit;
  if aClearOffenders and CanTakePlayerOrders then
    ClearOffenders;

  //If it is yet unset - use first members direction
  if fOrderLoc.Dir = dirNA then
    fOrderLoc.Dir := fMembers[0].Direction;

  if aTurnAmount <> 0 then
    fOrderLoc.Dir := KMAddDirection(fOrderLoc.Dir, aTurnAmount);

  SetUnitsPerRow(Max(fUnitsPerRow + aColumnsChange, 0));

  ManualFormation := True;

  OrderRepeat;
end;


//Forcefull termination of any activity
procedure TKMUnitGroup.OrderHalt(aClearOffenders: Boolean; aForced: Boolean = True);
begin
  if aClearOffenders and CanTakePlayerOrders then
    ClearOffenders;

  //Halt is not a True order, it is just OrderWalk
  //hose target depends on previous activity
  case fOrder of
    goNone:         if not KMSamePoint(fOrderLoc.Loc, KMPOINT_ZERO) then
                      OrderWalk(fOrderLoc.Loc, False, wtokHaltOrder, dirNA, aForced)
                    else
                      OrderWalk(fMembers[0].PositionNext, False, wtokHaltOrder, dirNA, aForced);
    goWalkTo:       OrderWalk(fMembers[0].PositionNext, False, wtokHaltOrder, dirNA, aForced);
    goAttackHouse:  OrderWalk(fMembers[0].PositionNext, False, wtokHaltOrder, dirNA, aForced);
    goAttackUnit:   OrderWalk(fMembers[0].PositionNext, False, wtokHaltOrder, dirNA, aForced);
    goStorm:        OrderWalk(fMembers[0].PositionNext, False, wtokHaltOrder, dirNA, aForced);
  end;
end;


procedure TKMUnitGroup.OrderLinkTo(aTargetGroup: TKMUnitGroup; aClearOffenders: Boolean);
var
  U: TKMUnit;
begin
  if aClearOffenders and CanTakePlayerOrders then
    ClearOffenders;

  //Any could have died since the time order was issued due to Net delay
  if IsDead or aTargetGroup.IsDead then Exit;

  //Only link to same group type
  if aTargetGroup.GroupType <> GroupType then Exit;

  //Can't link to self for obvious reasons
  if aTargetGroup = Self then Exit;

  //Move our members and self to the new group
  while (fMembers.Count <> 0) do
  begin
    U := fMembers[0];
    aTargetGroup.AddMember(fMembers[0], -1, False);
    gHands.CleanUpUnitPointer(U);
    fMembers.Delete(0);
  end;

  //In MP commands execution may be delayed, check if we still selected
  if gMySpectator.Selected = Self then
  begin
    gMySpectator.Selected := aTargetGroup;
    // What if fSelectedInUI died by now
    if not fSelectedInUI.IsDeadOrDying then
    begin
      if not aTargetGroup.HasMember(fSelectedInUI) then
        gLog.AddNoTime(
          Format('Make sure we joined selected unit. Group UID: %d; TargetGroup UID: %d Selected member UID: %d',
                 [UID, aTargetGroup.UID, fSelectedInUI.UID]));
      aTargetGroup.fSelectedInUI := fSelectedInUI;
    end;
  end;

  //Repeat targets group order to newly linked members
  aTargetGroup.OrderRepeat(False);

  //Script may have additional event processors
  gScriptEvents.ProcGroupOrderLink(Self, aTargetGroup);
end;


procedure TKMUnitGroup.OrderNone;
var
  I: Integer;
begin
  SetGroupOrder(goNone);
  //fOrderLoc remains old
  ClearOrderTarget;

  for I := 0 to Count - 1 do
    fMembers[I].OrderNone;
end;


//Copy order from specified aGroup
procedure TKMUnitGroup.CopyOrderFrom(aGroup: TKMUnitGroup; aUpdateOrderLoc: Boolean; aForced: Boolean = True);
begin
  SetGroupOrder(aGroup.fOrder);

  if aUpdateOrderLoc then
  begin
    //Get leader current position as order loc if there is no order
    if (fOrder = goNone) then
      fOrderLoc := KMPointDir(FlagBearer.Position, aGroup.fOrderLoc.Dir)
    else
      fOrderLoc := aGroup.fOrderLoc;  //otherwise - copy from target group
  end;

  fOrderWalkKind := wtokNone;
  if fOrder = goWalkTo then
    fOrderWalkKind := aGroup.fOrderWalkKind;

  case fOrder of
    goNone:         OrderHalt(False, aForced);
    goWalkTo:       OrderWalk(fOrderLoc.Loc, False, fOrderWalkKind, dirNA, aForced);
    goAttackHouse:  if aGroup.OrderTargetHouse <> nil then
                      OrderAttackHouse(aGroup.OrderTargetHouse, False, aForced);
    goAttackUnit:   if aGroup.OrderTargetUnit <> nil then
                      OrderAttackUnit(aGroup.OrderTargetUnit, False, aForced);
    goStorm:        ;
  end;
end;


//Repeat last order e.g. if new members have joined
procedure TKMUnitGroup.OrderRepeat(aForced: Boolean = True);
begin
  case fOrder of
    goNone:         OrderHalt(False, aForced);
    goWalkTo:       OrderWalk(fOrderLoc.Loc, False, fOrderWalkKind, dirNA, aForced);
    goAttackHouse:  if OrderTargetHouse <> nil then
                      OrderAttackHouse(OrderTargetHouse, False, aForced);
    goAttackUnit:   if OrderTargetUnit <> nil then
                      OrderAttackUnit(OrderTargetUnit, False, aForced);
    goStorm:        ;
  end;
end;


function TKMUnitGroup.OrderSplit(aNewLeaderUnitType: TKMUnitType; aNewCnt: Integer; aMixed: Boolean): TKMUnitGroup;
var
  I, NL, uPerRow: Integer;
  newLeader: TKMUnitWarrior;
  U: TKMUnit;
  newGroup: TKMUnitGroup;
  memberUTypes: TKMListUnique<TKMUnitType>;
  plainSplit, changeNewGroupOrderLoc: Boolean;
begin
  Result := nil;
  if IsDead then Exit;
  if Count < 2 then Exit;
  if not InRange(aNewCnt, 1, Count - 1) then Exit;
  if not (aNewLeaderUnitType in [WARRIOR_MIN..WARRIOR_MAX]) then Exit;

  //If leader is storming don't allow splitting the group (makes it too easy to withdraw)
  if fMembers[0].Action is TKMUnitActionStormAttack then Exit;

  if CanTakePlayerOrders then
    ClearOffenders;

  memberUTypes := TKMListUnique<TKMUnitType>.Create;
  try
    for I := 0 to Count - 1 do
      memberUTypes.Add(fMembers[I].UnitType);

    plainSplit := not memberUTypes.Contains(aNewLeaderUnitType) // no specified leader type
                  or (memberUTypes.Count = 1); // there is only 1 unit type in the group

    // Find new leader
    newLeader := nil;

    if plainSplit then
    begin
      NL := EnsureRange(Count - aNewCnt + (Min(fUnitsPerRow, aNewCnt) div 2), 0, Count - 1);
      newLeader := fMembers[NL];
    end
    else
    if memberUTypes.Contains(aNewLeaderUnitType) then
    begin
      for I := 0 to Count - 1 do
        if aNewLeaderUnitType = fMembers[I].UnitType then
          newLeader := fMembers[I];
    end
    else //We did't find leader unit type
      Exit;
  finally
    memberUTypes.Free;
  end;

  uPerRow := fUnitsPerRow; //Save formation for later
  //Remove from the group
  newLeader.ReleasePointer;
  fMembers.Remove(newLeader);

  newGroup := gHands[Owner].UnitGroups.AddGroup(newLeader);
  newGroup.OnGroupDied := OnGroupDied;

  for I := Count - 1 downto 0 do
    if (aNewCnt > newGroup.Count)
      and (plainSplit or aMixed or (fMembers[I].UnitType = newLeader.UnitType)) then
    begin
      U := fMembers[I];
      gHands.CleanUpUnitPointer(U);
      newGroup.AddMember(fMembers[I], 1, False); // Join new group (insert next to commander)
      fMembers.Delete(I); // Leave this group
    end;

  //Keep the selected unit Selected
  if not SelectedUnit.IsDeadOrDying and newGroup.HasMember(SelectedUnit) then
  begin
    newGroup.fSelectedInUI := fSelectedInUI;
    SelectNearestMember; // For current group set fSelectedInUI to nearest member to its old selected
  end;

  //Make sure units per row is still valid for both groups
  UnitsPerRow := uPerRow;
  newGroup.UnitsPerRow := uPerRow;

  //If we are hungry then don't repeat message each time we split, give new commander our counter
  newGroup.fTimeSinceHungryReminder := fTimeSinceHungryReminder;

  changeNewGroupOrderLoc := True; //Update Order loc by default
  //For walk order our new leader was going to some loc, and we want this loc to be our new fOrderLoc for new group
  if (fOrder = goWalkTo)
    and (newLeader.Action is TKMUnitActionWalkTo) then
  begin
    newGroup.fOrderLoc := KMPointDir(TKMUnitActionWalkTo(newLeader.Action).WalkTo, fOrderLoc.Dir);
    changeNewGroupOrderLoc := False; //Do not update order loc since we set it already
  end;

  //Tell both groups to reposition
  OrderRepeat(False);
  newGroup.CopyOrderFrom(Self, changeNewGroupOrderLoc, False);

  Result := newGroup; //Return the new group in case somebody is interested in it

  //Script may have additional event processors
  gScriptEvents.ProcGroupOrderSplit(Self, newGroup);
end;


//Split group in half
//or split different unit types apart
function TKMUnitGroup.OrderSplit(aSplitSingle: Boolean = False): TKMUnitGroup;
var
  I: Integer;
  newLeader: TKMUnitWarrior;
  multipleTypes: Boolean;
  newLeaderUnitType: TKMUnitType;
  oldCnt, newCnt: Integer;
  mixed: Boolean;
begin
  Result := nil;
  if IsDead then Exit;
  if Count < 2 then Exit;
  //If leader is storming don't allow splitting the group (makes it too easy to withdraw)
  if fMembers[0].Action is TKMUnitActionStormAttack then Exit;

  //If there are different unit types in the group, split should just split them first
  multipleTypes := False;


  //First find default split parameters - NewLeader type and new group members count

  //Choose the new leader
  if aSplitSingle then
    newLeader := fMembers[Count - 1]
  else
  begin
    newLeader := fMembers[(Count div 2) + (Min(fUnitsPerRow, Count div 2) div 2)];

    for I := 1 to Count - 1 do
      if fMembers[I].UnitType <> fMembers[0].UnitType then
      begin
        multipleTypes := True;
        //New commander is first unit of different type, for simplicity
        newLeader := fMembers[I];
        Break;
      end;
  end;

  newLeaderUnitType := newLeader.UnitType;
  newCnt := 1;
  oldCnt := Count - 1;
  // Determine new group members count
  if not aSplitSingle then
    //Split by UnitTypes or by Count (make NewGroup half or smaller half)
    for I := Count - 1 downto 0 do
    begin
      if fMembers[I] = newLeader then Continue;

      if (multipleTypes and (fMembers[I].UnitType = newLeader.UnitType))
         or (not multipleTypes and (oldCnt > newCnt + 1)) then
      begin
        Inc(newCnt);
        Dec(oldCnt);
      end;
    end;

  mixed := False; // We don't use mixed group by default
  // Ask script if it ant to change some split parameters
  gScriptEvents.ProcGroupBeforeOrderSplit(Self, newLeaderUnitType, newCnt, mixed);
  // Apply split with parameters, which came from Script
  Result := OrderSplit(newLeaderUnitType, newCnt, mixed);

  // Select single splitted unit
  if aSplitSingle
    and (newCnt = 1) and (newLeaderUnitType = newLeader.UnitType) //SplitSingle command was not changed by script
    and (gGame.ControlledHandIndex = Result.Owner) //Only select unit for player that issued order (group owner)
    and (gGame.ControlledHandIndex <> -1)
    and (gMySpectator.Selected = Self) then //Selection is still on that group (in MP game there could be a delay, when player could select other target already)
    gMySpectator.Selected := Result;
end;


//Split ONE certain unit from the group
function TKMUnitGroup.OrderSplitUnit(aUnit: TKMUnitWarrior; aClearOffenders: Boolean): TKMUnitGroup;
var
  newGroup: TKMUnitGroup;
  newLeader: TKMUnitWarrior;
begin
  Result := nil;
  if IsDead then Exit;
  if Count < 2 then Exit;

  // We could have received several repeating commands due to Network lag and this unit is already out of this group
  if not HasMember(aUnit) then Exit;

  if aClearOffenders and CanTakePlayerOrders then
    ClearOffenders;

  //Delete from group
  newLeader := aUnit;
  fMembers.Remove(newLeader);
  newLeader.ReleasePointer;

  //Give new group
  newGroup := gHands[Owner].UnitGroups.AddGroup(newLeader);
  newGroup.OnGroupDied := OnGroupDied;
  newGroup.fSelectedInUI := newLeader;
  newGroup.fTimeSinceHungryReminder := fTimeSinceHungryReminder;
  newGroup.fOrderLoc := KMPointDir(newLeader.Position, fOrderLoc.Dir);

  //Set units per row
  UnitsPerRow := fUnitsPerRow;
  newGroup.UnitsPerRow := 1;

  //Save unit selection
  if newGroup.HasMember(fSelectedInUI) then
  begin
    newGroup.fSelectedInUI := fSelectedInUI;

    if (gGame.ControlledHandIndex = newGroup.Owner) //Only select unit for player that issued order (group owner)
      and (gGame.ControlledHandIndex <> -1)
      and (gMySpectator.Selected = Self) then //Selection is still on that group (in MP game there could be a delay, when player could select other target already)
      gMySpectator.Selected := newGroup;
  end;

  //Halt both groups
  OrderHalt(False);
  newGroup.OrderHalt(False);

  //Return NewGroup as result
  Result := newGroup;

  //Script may have additional event processors
  gScriptEvents.ProcGroupOrderSplit(Self, newGroup);
end;


//Splits X number of men from the group and adds them to the new commander
procedure TKMUnitGroup.OrderSplitLinkTo(aGroup: TKMUnitGroup; aCount: Word; aClearOffenders: Boolean);
var
  I: Integer;
  U: TKMUnit;
begin
  //Make sure to leave someone in the group
  Assert(aCount < Count);
  if aClearOffenders and CanTakePlayerOrders then
    ClearOffenders;

  //Take units from the end, to keep flagholder
  for I := fMembers.Count - 1 downto fMembers.Count - aCount do
  begin
    U := fMembers[I];
    gHands.CleanUpUnitPointer(U);
    aGroup.AddMember(fMembers[I], -1, False);
    fMembers.Delete(I);
  end;

  //Make sure units per row is still valid
  SetUnitsPerRow(UnitsPerRow);

  //Tell both groups to reposition
  OrderHalt(False);
  aGroup.OrderHalt(False);
end;


procedure TKMUnitGroup.OrderStorm(aClearOffenders: Boolean);
var
  I: Integer;
begin
  //Don't allow ordering a second storm attack while there is still one active (possible due to network lag)
  if not CanTakePlayerOrders then Exit;
  if aClearOffenders and CanTakePlayerOrders then
    ClearOffenders;

  SetGroupOrder(goStorm);
  fOrderLoc := KMPointDir(0, 0, dirNA);
  ClearOrderTarget;

  //Each next row delayed by few ticks to avoid crowding
  for I := 0 to Count - 1 do
    fMembers[I].OrderStorm(I div fUnitsPerRow);
end;


procedure TKMUnitGroup.OrderWalk(const aLoc: TKMPoint; aClearOffenders: Boolean; aOrderWalkKind: TKMOrderWalkKind;
                                 aDir: TKMDirection = dirNA; aForced: Boolean = True);
var
  I: Integer;
  newDir: TKMDirection;
  P: TKMPointExact;
begin
  if IsDead then Exit;

  fOrderWalkKind := aOrderWalkKind;

  if aClearOffenders and CanTakePlayerOrders then
    ClearOffenders;

  if aDir = dirNA then
    if fOrderLoc.Dir = dirNA then
      newDir := fMembers[0].Direction
    else
      newDir := fOrderLoc.Dir
  else
    newDir := aDir;

  fOrderLoc := KMPointDir(aLoc, newDir);
  ClearOrderTarget;

  if IsPositioned(aLoc, newDir) then
    Exit; //No need to actually walk, all members are at the correct location and direction

  SetGroupOrder(goWalkTo);
  HungarianReorderMembers;

  for I := 0 to Count - 1 do
  begin
    P := GetMemberLocExact(I);
    fMembers[I].OrderWalk(P.Loc, P.Exact, aForced);
    fMembers[I].FaceDir := newDir;
  end;

  //Script may have additional event processors
  gScriptEvents.ProcGroupOrderMove(Self, aLoc.X, aLoc.Y, newDir);
end;


function TKMUnitGroup.UnitType: TKMUnitType;
begin
  Result := fMembers[0].UnitType;
end;


function TKMUnitGroup.HasUnitType(aUnitType: TKMUnitType): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to fMembers.Count - 1 do
    if not fMembers[I].IsDeadOrDying
      and (fMembers[I].UnitType = aUnitType) then
      Exit(True);

end;


function TKMUnitGroup.GetOrderText: UnicodeString;
begin
  case fOrder of
    goNone:         Result := 'Idle';
    goWalkTo:       Result := 'Walk';
    goAttackHouse:  Result := 'Attack house';
    goAttackUnit:   Result := 'Attack unit';
    goStorm:        Result := 'Storm';
  end;
  Result := Result + '(' + IntToStr(fOffenders.Count) + ')';
end;


//Tell the player to feed us if we are hungry
procedure TKMUnitGroup.UpdateHungerMessage;
var
  I: Integer;
  someoneHungry: Boolean;
begin
  if IsDead then Exit;

  someoneHungry := False;
  for I := 0 to Count - 1 do
    if (fMembers[I] <> nil)
    and not fMembers[I].IsDeadOrDying then
    begin
      someoneHungry := someoneHungry
                       or ((fMembers[I].Condition < UNIT_MIN_CONDITION)
                       and not fMembers[I].RequestedFood);
      if someoneHungry then Break;
    end;

  if someoneHungry then
  begin
    Dec(fTimeSinceHungryReminder, HUNGER_CHECK_FREQ);
    if fTimeSinceHungryReminder < 1 then
    begin
      gScriptEvents.ProcGroupHungry(Self);
      if not fDisableHungerMessage then
        gGame.ShowMessage(mkGroup, TX_MSG_TROOP_HUNGRY, Position, UID, Owner);
      fTimeSinceHungryReminder := TIME_BETWEEN_MESSAGES; //Don't show one again until it is time
    end;
  end
  else
    fTimeSinceHungryReminder := 0;
end;


procedure TKMUnitGroup.ClearOrderTarget;
begin
  //Set fOrderTargets to nil, removing pointer if it's still valid
  gHands.CleanUpUnitPointer(fOrderTargetUnit);
  gHands.CleanUpGroupPointer(fOrderTargetGroup);
  gHands.CleanUpHousePointer(fOrderTargetHouse);
end;


procedure TKMUnitGroup.ClearOffenders;
var
  I: Integer;
  U: TKMUnit;
begin
  for I := fOffenders.Count - 1 downto 0 do
  begin
    U := fOffenders[I]; //Need to pass variable
    gHands.CleanUpUnitPointer(U);
  end;
  fOffenders.Clear;
end;


class function TKMUnitGroup.IsFlagRenderBeforeUnit(aDir: TKMDirection): Boolean;
begin
  Result := aDir in [dirSE, dirS, dirSW, dirW];
end;


function TKMUnitGroup.GetInstance: TKMUnitGroup;
begin
  Result := Self;
end;


function TKMUnitGroup.GetPositionForDisplayF: TKMPointF;
begin
  if (Self = nil) or IsDead then Exit(KMPOINTF_INVALID_TILE);

  Result := FlagBearer.PositionF;
end;


function TKMUnitGroup.GetPositionF: TKMPointF;
begin
  Result := FlagBearer.PositionF;
end;


function TKMUnitGroup.GetFlagColor: Cardinal;
begin
  //Highlight selected group
  Result := gHands[FlagBearer.Owner].GameFlagColor;
  if gMySpectator.Selected = Self then
    //If base color is brighter than $FFFF40 then use black highlight
    if (Result and $FF) + (Result shr 8 and $FF) + (Result shr 16 and $FF) > $240 then
      Result := $FF404040
    else
      Result := $FFFFFFFF;
end;


procedure TKMUnitGroup.HungarianReorderMembers;
var
  I: Integer;
  agents, tasks: TKMPointList;
  newOrder: TKMCardinalArray;
  newMembers: TList<TKMUnitWarrior>;
begin
  {$IFDEF DBG_PERFLOG}
  gPerfLogs.SectionEnter(psHungarian);
  {$ENDIF}
  try
    if not FEAT_HUNGARIAN_GROUP_ORDER then Exit;
    if fMembers.Count <= 1 then Exit; //If it's just the leader we can't rearrange
    agents := TKMPointList.Create;
    tasks := TKMPointList.Create;

    //todo -cComplicated: Process each unit type separately in mixed groups so their order is maintained

    //Skip leader, he can't be reordered because he holds the flag
    //(tossing flag around is quite complicated and looks unnatural in KaM)
    for I := 1 to fMembers.Count - 1 do
    begin
      agents.Add(fMembers[I].Position);
      tasks.Add(GetMemberLoc(I));
    end;

    //huIndividual as we'd prefer 20 members to take 1 step than 1 member to take 10 steps (minimize individual work rather than total work)
    newOrder := HungarianMatchPoints(tasks, agents, huIndividual);
    newMembers := TList<TKMUnitWarrior>.Create;
    newMembers.Add(fMembers[0]);

    for I := 1 to fMembers.Count - 1 do
      newMembers.Add(fMembers[newOrder[I - 1] + 1]);

    fMembers.Free;
    fMembers := newMembers;

    agents.Free;
    tasks.Free;
  finally
    {$IFDEF DBG_PERFLOG}
    gPerfLogs.SectionLeave(psHungarian);
    {$ENDIF}
  end;
end;


function TKMUnitGroup.GetOrderTargetUnit: TKMUnit;
begin
  //If the target unit has died then return nil
  //Don't clear fOrderTargetUnit here, since we could get called from UI
  //depending on player actions (getters should be side effect free)
  if (fOrderTargetUnit <> nil) and fOrderTargetUnit.IsDeadOrDying then
    Result := nil
  else
    Result := fOrderTargetUnit;
end;


function TKMUnitGroup.GetOrderTargetGroup: TKMUnitGroup;
begin
  //If the target group has died then return nil
  //Don't clear fOrderTargetGroup here, since we could get called from UI
  //depending on player actions (getters should be side effect free)
  if (fOrderTargetGroup <> nil) and fOrderTargetGroup.IsDead then
    Result := nil
  else
    Result := fOrderTargetGroup;
end;


function TKMUnitGroup.GetOrderTargetHouse: TKMHouse;
begin
  //If the target house has been destroyed then return nil
  //Don't clear fOrderTargetHouse here, since we could get called from UI
  //depending on player actions (getters should be side effect free)
  if (fOrderTargetHouse <> nil) and fOrderTargetHouse.IsDestroyed then
    Result := nil
  else
    Result := fOrderTargetHouse;
end;


procedure TKMUnitGroup.SetOrderTargetUnit(aUnit: TKMUnit);
var
  G: TKMUnitGroup;
begin
  //Remove previous value
  ClearOrderTarget;
  if (aUnit <> nil) and not aUnit.IsDeadOrDying then
  begin
    fOrderTargetUnit := aUnit.GetPointer; //Else it will be nil from ClearOrderTarget
    if (aUnit is TKMUnitWarrior) and not IsRanged then
    begin
      G := gHands[aUnit.Owner].UnitGroups.GetGroupByMember(TKMUnitWarrior(aUnit));
      //Target warrior won't have a group while he's walking out of the barracks
      if G <> nil then
        fOrderTargetGroup := G.GetPointer;
    end;
  end;
end;


procedure TKMUnitGroup.SetOrderTargetHouse(aHouse: TKMHouse);
begin
  //Remove previous value
  ClearOrderTarget;
  if (aHouse <> nil) and not aHouse.IsDestroyed then
    fOrderTargetHouse := aHouse.GetPointer; //Else it will be nil from ClearOrderTarget
end;


//Clear target if it is dead
procedure TKMUnitGroup.UpdateOrderTargets;
begin
  // Check target unit and stop attacking him in case
  // if unit is dead or if he is hidden from us (inside some house)
  // we do not want soldiers walking around the house where unit hides from them
  // stop attacking him and find new target
  // if new target will not be found the ngroup continue its way to unit/house location, but its quite rare situation, an does not matter much
  if (fOrderTargetUnit <> nil) and (fOrderTargetUnit.IsDeadOrDying or not fOrderTargetUnit.Visible) then
    gHands.CleanUpUnitPointer(fOrderTargetUnit);

  if (fOrderTargetHouse <> nil) and fOrderTargetHouse.IsDestroyed then
    gHands.CleanUpHousePointer(fOrderTargetHouse);

  if (fOrderTargetGroup <> nil) and fOrderTargetGroup.IsDead then
    gHands.CleanUpGroupPointer(fOrderTargetGroup);
end;


function TKMUnitGroup.ObjToStringShort(const aSeparator: string = '|'): string;
begin
  if Self = nil then Exit('nil');

  Result := inherited ObjToStringShort(aSeparator) +
            Format('%sType = %s%sMembersCnt = %d%sOffendersCnt = %d',
                   [aSeparator,
                    GetEnumName(TypeInfo(TKMGroupType), Integer(fGroupType)), aSeparator,
                    fMembers.Count, aSeparator,
                    fOffenders.Count]);
end;


function TKMUnitGroup.ObjToString(const aSeparator: string = '|'): string;
var
  I: Integer;
  targetUnitStr, targetHouseStr, targetGroupStr, offendersStr: string;
begin
  if Self = nil then Exit('nil');

  targetUnitStr := 'nil';
  targetHouseStr := 'nil';
  targetGroupStr := 'nil';
  offendersStr := '';

  if fOrderTargetUnit <> nil then
    targetUnitStr := fOrderTargetUnit.ObjToStringShort(', ');

  if fOrderTargetGroup <> nil then
    targetGroupStr := fOrderTargetGroup.ObjToStringShort(', ');

  if fOrderTargetHouse <> nil then
    targetHouseStr := fOrderTargetHouse.ObjToStringShort(', ');

  for I := 0 to fOffenders.Count - 1 do
    offendersStr := offendersStr + aSeparator + '  ' + fOffenders[I].ObjToStringShort(', ');


  Result := inherited ObjToString(aSeparator) +
            Format('%sUnitsPerRow = %d%sCanTakeOrders = %s%sInFight = %s%sGOrder = %s%sOrderLoc = %s%s' +
                   'OTargetU = [%s]%sOTargetG = [%s]%sOTargetH = [%s]%sPushbackCmdCnt = %d%s' +
                   'Offenders = [%s]',
                   [aSeparator,
                    fUnitsPerRow, aSeparator,
                    BoolToStr(CanTakePlayerOrders, True), aSeparator,
                    BoolToStr(InFight, True), aSeparator,
                    GetEnumName(TypeInfo(TKMGroupOrder), Integer(fOrder)), aSeparator,
                    TypeToString(fOrderLoc), aSeparator,
                    targetUnitStr, aSeparator,
                    targetGroupStr, aSeparator,
                    targetHouseStr, aSeparator,
                    fMembersPushbackCommandsCnt, aSeparator,
                    offendersStr]);
end;


procedure TKMUnitGroup.UpdateState;
var
  needCheckOrderDone: Boolean;
begin
  Inc(fTicker);
  if IsDead then Exit;

  UpdateOrderTargets;

  if fTicker mod HUNGER_CHECK_FREQ = 0 then
    UpdateHungerMessage;

  if fTicker mod 5 = 0 then
    CheckForFight;

  needCheckOrderDone := (fTicker mod 7 = 0);
  if needCheckOrderDone then
  begin
    if IsRanged then
      //Ranged units could be partially in fight
      //That could cause wrong unit direction, check it in further CheckOrderDone
      needCheckOrderDone := not InFightAllMembers
    else
      needCheckOrderDone := not InFight;
  end;

  if needCheckOrderDone then
    CheckOrderDone;
end;


procedure TKMUnitGroup.Paint(aTickLag: Single);
begin
  PaintHighlighted(aTickLag, gHands[FlagBearer.Owner].GameFlagColor, FlagColor);
end;


procedure TKMUnitGroup.PaintHighlighted(aTickLag: Single; aHandColor, aFlagColor: Cardinal; aDoImmediateRender: Boolean = False;
                                        aDoHighlight: Boolean = False; aHighlightColor: Cardinal = 0);

  function GetFlagPositionF(const aUVS: TKMUnitVisualState): TKMPointF;
  begin
    Result.X := aUVS.PositionF.X + UNIT_OFF_X + aUVS.SlideX;
    Result.Y := aUVS.PositionF.Y + UNIT_OFF_Y + aUVS.SlideY;
    //Flag needs to be rendered above or below unit depending on direction (see AddUnitFlag)
    if IsFlagRenderBeforeUnit(aUVS.Dir) then
      Result.Y := Result.Y - FLAG_X_OFFSET
    else
      Result.Y := Result.Y + FLAG_X_OFFSET;
  end;

var
  V: TKMUnitVisualState;
  unitPos, flagPos: TKMPointF;
  I: Integer;
  flagStep: Cardinal;
  newPos: TKMPoint;
  doesFit: Boolean;
begin
  if IsDead then Exit;

  if not FlagBearer.Visible then Exit;
  if FlagBearer.IsDeadOrDying then Exit;

  //In MapEd units fTicker always the same, use Terrain instead
  flagStep := IfThen(gGameParams.IsMapEditor, gTerrain.AnimStep, fTicker);

  //Paint virtual members in MapEd mode
  for I := 1 to fMapEdCount - 1 do
  begin
    newPos := GetPositionInGroup2(fOrderLoc.Loc.X, fOrderLoc.Loc.Y, fOrderLoc.Dir, I, fUnitsPerRow, gTerrain.MapX, gTerrain.MapY, doesFit);
    if not doesFit then Continue; //Don't render units that are off the map in the map editor
    unitPos.X := newPos.X + UNIT_OFF_X; //MapEd units don't have sliding
    unitPos.Y := newPos.Y + UNIT_OFF_Y;
    gRenderPool.AddUnit(FlagBearer.UnitType, 0, uaWalk, fOrderLoc.Dir, UNIT_STILL_FRAMES[fOrderLoc.Dir], 0.0, unitPos.X, unitPos.Y, aHandColor, True, aDoImmediateRender, aDoHighlight, aHighlightColor);
  end;

  V := FlagBearer.Visual.GetLerp(aTickLag);
  // We need to render Flag after MapEd virtual members
  flagPos := GetFlagPositionF(V);
  gRenderPool.AddUnitFlag(FlagBearer.UnitType, V.Action,
    V.Dir, flagStep, flagPos.X, flagPos.Y, aFlagColor, aDoImmediateRender);

  if SHOW_GROUP_MEMBERS_POS and not gGameParams.IsMapEditor then
    for I := 0 to Count - 1 do
      gRenderAux.Text(fMembers[I].PositionF.X + 0.2, fMembers[I].PositionF.Y + 0.2, IntToStr(I), icCyan);
end;


class function TKMUnitGroup.GetDefaultCondition: Integer;
begin
  Result := UNIT_MAX_CONDITION div 2; //Half-fed
end;


{ TKMUnitGroups }
constructor TKMUnitGroups.Create;
begin
  inherited Create;

  fGroups := TKMList.Create;
end;


destructor TKMUnitGroups.Destroy;
begin
  FreeAndNil(fGroups);

  inherited;
end;


procedure TKMUnitGroups.Clear;
begin
  fGroups.Clear;
end;


function TKMUnitGroups.GetCount: Integer;
begin
  Result := fGroups.Count;
end;


function TKMUnitGroups.GetGroup(aIndex: Integer): TKMUnitGroup;
begin
  Result := fGroups[aIndex];
end;


function TKMUnitGroups.AddGroup(aWarrior: TKMUnitWarrior): TKMUnitGroup;
begin
  Result := TKMUnitGroup.Create(gUIDTracker.GetNewUID, aWarrior);
  fGroups.Add(Result);
end;


function TKMUnitGroups.AddGroup(aOwner: TKMHandID; aUnitType: TKMUnitType; PosX, PosY: Word; aDir: TKMDirection;
                                aUnitPerRow, aCount: Word): TKMUnitGroup;
begin
  Result := nil;
  Assert(aUnitType in [WARRIOR_MIN..WARRIOR_MAX]);

  Result := TKMUnitGroup.Create(gUIDTracker.GetNewUID, aOwner, aUnitType, PosX, PosY, aDir, aUnitPerRow, aCount);

  //If group failed to create (e.g. due to being placed on unwalkable position)
  //then its memberCount = 0
  if not Result.IsDead then
    fGroups.Add(Result)
  else
    FreeAndNil(Result);
end;


procedure TKMUnitGroups.AddGroupToList(aGroup: TKMUnitGroup);
begin
  Assert(gGameParams.Mode = gmMapEd); // Allow to add existing Group directly only in MapEd
  if aGroup <> nil then
    fGroups.Add(aGroup);
end;


procedure TKMUnitGroups.DeleteGroupFromList(aGroup: TKMUnitGroup);
begin
  Assert(gGameParams.Mode = gmMapEd); // Allow to delete existing Group directly only in MapEd
  if (aGroup <> nil) then
    fGroups.Extract(aGroup);  // use Extract instead of Delete, cause Delete nils inner objects somehow
end;


function TKMUnitGroups.GetGroupByUID(aUID: Integer): TKMUnitGroup;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Count - 1 do
    if aUID = Groups[I].UID then
    begin
      Result := Groups[I];
      Break;
    end;
end;


function TKMUnitGroups.GetGroupByMember(aUnit: TKMUnitWarrior): TKMUnitGroup;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Count - 1 do
    if Groups[I].HasMember(aUnit) then
      Exit(fGroups[I]);
end;


//Warrior has been trained and we need to see where to place him
//Return group he was assigned to
function TKMUnitGroups.WarriorTrained(aUnit: TKMUnitWarrior): TKMUnitGroup;
var
  linkUnit: TKMUnitWarrior;
begin
  Result := nil; // Makes compiler happy

  case gHands[aUnit.Owner].HandType of
    hndHuman:    begin
                   linkUnit := aUnit.FindLinkUnit(aUnit.Position);
                   if linkUnit <> nil then
                   begin
                     // Link to other group
                     Result := gHands[aUnit.Owner].UnitGroups.GetGroupByMember(linkUnit);
                     Result.AddMember(aUnit);
                     // Form a square (rather than a long snake like in TSK/TPR)
                     // but don't change formation if player decided to set it manually
                     if not Result.ManualFormation then
                       Result.UnitsPerRow := Ceil(Sqrt(Result.Count));
                     Result.OrderRepeat(False);
                   end
                   else
                   begin
                     // Create a new group with this one warrior
                     Result := TKMUnitGroup.Create(gUIDTracker.GetNewUID, aUnit);
                     fGroups.Add(Result);
                   end;
                 end;
    hndComputer: begin
                   Result := TKMUnitGroup.Create(gUIDTracker.GetNewUID, aUnit);
                   fGroups.Add(Result);
                 end;
  end;
end;


function TKMUnitGroups.HitTest(X,Y: Integer): TKMUnitGroup;
var
  I: Integer;
  U: TKMUnit;
begin
  Result := nil;
  U := gTerrain.UnitsHitTest(X,Y);
  if (U <> nil) and (U is TKMUnitWarrior) then
  for I := 0 to Count - 1 do
    if Groups[I].HitTest(X,Y) then
      Exit(Groups[I]);
end;


procedure TKMUnitGroups.GetGroupsInRect(const aRect: TKMRect; List: TList<TKMUnitGroup>);
var
  I, K: Integer;
begin
  for I := 0 to Count - 1 do
    for K := 0 to Groups[I].Count - 1 do
      if KMInRect(Groups[I].fMembers[K].PositionF, aRect) and not Groups[I].fMembers[K].IsDeadOrDying then
      begin
        List.Add(Groups[I]);
        Break;
      end;
end;


function TKMUnitGroups.GetClosestGroup(const aPoint: TKMPoint; aTypes: TKMGroupTypeSet = GROUP_TYPES_VALID): TKMUnitGroup;
var
  I: Integer;
  bestDist, dist: Single;
begin
  Result := nil;
  bestDist := MaxSingle; //Any distance will be closer than that
  for I := 0 to Count - 1 do
    if not Groups[I].IsDead and (Groups[I].GroupType in aTypes) then
    begin
      dist := KMLengthSqr(Groups[I].GetPosition, aPoint);
      if dist < bestDist then
      begin
        bestDist := dist;
        Result := Groups[I];
      end;
    end;
end;


function TKMUnitGroups.GetGroupsInRadius(aPoint: TKMPoint; aSqrRadius: Single; aTypes: TKMGroupTypeSet = GROUP_TYPES_VALID): TKMUnitGroupArray;
var
  I, K, Idx: Integer;
  UW: TKMUnitWarrior;
begin
  Idx := 0;
  for I := 0 to Count - 1 do
    if not Groups[I].IsDead and (Groups[I].GroupType in aTypes) then
    begin
      K := 0;
      while (K < Groups[I].Count) do // Large groups may be in radius too so check every fifth member
        if Groups[I].fMembers[K].IsDeadOrDying then // Member must be alive
          K := K + 1
        else
        begin
          UW := Groups[I].fMembers[K];
          if (KMLengthSqr(UW.Position, aPoint) <= aSqrRadius) then
          begin
            if (Idx >= Length(Result)) then
              SetLength(Result, Idx + 12);
            Result[Idx] := Groups[I];
            Idx := Idx + 1;
            Break;
          end;
          K := K + 5;
        end;
    end;
  SetLength(Result,Idx);
end;


function TKMUnitGroups.GetGroupsMemberInRadius(aPoint: TKMPoint; aSqrRadius: Single; var aUGA: TKMUnitGroupArray; aTypes: TKMGroupTypeSet = GROUP_TYPES_VALID): TKMUnitArray;
var
  I, K, Idx: Integer;
  dist, minDist: Single;
  U, bestU: TKMUnit;
begin
  Idx := 0;
  bestU := nil;
  for I := 0 to Count - 1 do
    if not Groups[I].IsDead and (Groups[I].GroupType in aTypes) then
    begin
      K := 0;
      minDist := MaxSingle; //Any distance will be closer than that
      while (K < Groups[I].Count) do
        if Groups[I].fMembers[K].IsDeadOrDying then // Member must be alive
          K := K + 1
        else
        begin
          U := Groups[I].fMembers[K];
          dist := KMLengthSqr(U.Position, aPoint);
          if (dist <= minDist) then
          begin
            minDist := dist;
            bestU := U;
          end;
          K := K + 5; // Large groups may be in radius too so check every fifth member
        end;
      if (minDist <= aSqrRadius) then
      begin
        if (Idx >= Length(Result)) then
        begin
          SetLength(Result, Idx + 12);
          SetLength(aUGA, Idx + 12);
        end;
        Result[Idx] := bestU;
        aUGA[Idx] := Groups[I]; // Save also group (it is faster than search group via HandsCollection)
        Idx := Idx + 1;
      end;
    end;
  SetLength(Result,Idx);
end;


procedure TKMUnitGroups.RemGroup(aGroup: TKMUnitGroup);
begin
  fGroups.Remove(aGroup);
end;


procedure TKMUnitGroups.RemAllGroups;
var
  I: Integer;
begin
  if not gGameParams.IsMapEditor then
    for I := 0 to Count - 1 do
      Groups[I].CloseGroup;

  fGroups.Clear;
end;


procedure TKMUnitGroups.Save(SaveStream: TKMemoryStream);
var
  I: Integer;
begin
  SaveStream.PlaceMarker('UnitGroups');
  SaveStream.Write(Count);
  for I := 0 to Count - 1 do
    Groups[I].Save(SaveStream);
end;


procedure TKMUnitGroups.Load(LoadStream: TKMemoryStream);
var
  I, newCount: Integer;
begin
  LoadStream.CheckMarker('UnitGroups');
  LoadStream.Read(newCount);
  for I := 0 to newCount - 1 do
    fGroups.Add(TKMUnitGroup.Load(LoadStream));
end;


procedure TKMUnitGroups.SyncLoad;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Groups[I].SyncLoad;
end;


procedure TKMUnitGroups.UpdateState;
var
  I: Integer;
begin
  //We delete dead groups only next tick after they died
  //so that gMySpectator.Selected could register their death and reset
  //(this could be outdated with Spectators appearence)
  for I := Count - 1 downto 0 do
  if FREE_POINTERS
  and Groups[I].IsDead
  and (Groups[I].PointerCount = 0) then
    fGroups.Delete(I);

  for I := 0 to Count - 1 do
  if not Groups[I].IsDead then
    Groups[I].UpdateState;
end;


procedure TKMUnitGroups.Paint(const aRect: TKMRect; aTickLag: Single);
const
  MARGIN = 2;
var
  I: Integer;
  growRect: TKMRect;
begin
  // Add additional margin to compensate for units height
  growRect := KMRectGrow(aRect, MARGIN);

  for I := 0 to Count - 1 do
  if not Groups[I].IsDead and KMInRect(Groups[I].fMembers[0].PositionF, growRect) then
    Groups[I].Paint(aTickLag);
end;


end.
