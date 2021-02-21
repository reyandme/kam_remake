unit KM_UnitGroup;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, SysUtils, Types,
  KM_Defaults, KM_CommonClasses, KM_CommonTypes, KM_Points, KM_Houses, KM_Units,
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
    fMembers: TList;
    fOffenders: TList;
    fSelected: TKMUnitWarrior; //Unit selected by player in GUI. Should not be saved or affect game logic for MP consistency.
    fUnitsPerRow: Word;
    fTimeSinceHungryReminder: Integer;
    fGroupType: TKMGroupType;
    fDisableHungerMessage: Boolean;
    fBlockOrders: Boolean;
    fManualFormation: Boolean;
    fMembersPushbackCommandsCnt: Word; //Number of 'push back' commands ordered to group members when executing goWalkTo

    fOrder: TKMGroupOrder; //Remember last order incase we need to repeat it (e.g. to joined members)
    fOrderLoc: TKMPointDir; //Dir is the direction to face after order
    fOrderWalkKind: TKMOrderWalkKind;

    //Avoid accessing these directly
    fOrderTargetUnit: TKMUnit; //Unit we are ordered to attack. This property should never be accessed, use public OrderTarget instead.
    fOrderTargetGroup: TKMUnitGroup; //Unit we are ordered to attack. This property should never be accessed, use public OrderTarget instead.
    fOrderTargetHouse: TKMHouse; //House we are ordered to attack. This property should never be accessed, use public OrderHouseTarget instead.

    //don't saved:
    fMapEdCount: Word;

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

    function GetFlagPositionF: TKMPointF;
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
    procedure SetSelected(aValue: TKMUnitWarrior);
    function GetSelected: TKMUnitWarrior;
  protected
    function GetPosition: TKMPoint; override;
    function GetInstance: TKMUnitGroup; override;
    function GetPositionF: TKMPointF; override;
    procedure SetPositionF(const aPositionF: TKMPointF); override;
    procedure SetOwner(const aOwner: TKMHandID); override;
  public
    //Each group can have initial order
    //SendGroup - walk to some location
    //AttackPosition - attack something at position (or walk there if its empty)
    MapEdOrder: TKMMapEdOrder;
    OnGroupDied: TKMUnitGroupEvent;

    constructor Create(aID: Cardinal; aCreator: TKMUnitWarrior); overload;
    constructor Create(aID: Cardinal; aOwner: TKMHandID; aUnitType: TKMUnitType; PosX, PosY: Word; aDir: TKMDirection;
                       aUnitPerRow, aCount: Word); overload;
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure SyncLoad;
    procedure Save(SaveStream: TKMemoryStream); override;
    destructor Destroy; override;

    procedure AddMember(aWarrior: TKMUnitWarrior; aIndex: Integer = -1; aOnlyWarrior: Boolean = True);
    function  MemberByUID(aUID: Integer): TKMUnitWarrior;
    function  HitTest(X,Y: Integer): Boolean;
    procedure SelectFlagBearer;
    function  HasMember(aWarrior: TKMUnit): Boolean;
    procedure ResetAnimStep;
    function InFight(aCountCitizens: Boolean = False): Boolean; //Fighting and can't take any orders from player
    function InFightAllMembers(aCountCitizens: Boolean = False): Boolean; //Fighting and can't take any orders from player
    function InFightAgaistGroups(var aGroupArray: TKMUnitGroupArray): Boolean; //Fighting agaist specific groups
    function IsAttackingHouse: Boolean; //Attacking house
    function IsAttackingUnit: Boolean;
    function IsIdleToAI(aOrderWalkKindSet: TKMOrderWalkKindSet = []): Boolean;
    function IsPositioned(const aLoc: TKMPoint; Dir: TKMDirection): Boolean;
    function IsAllyTo(aUnit: TKMUnit): Boolean; overload;
    function IsAllyTo(aUnitGroup: TKMUnitGroup): Boolean; overload;
    function IsAllyTo(aHouse: TKMHouse): Boolean; overload;
    function CanTakeOrders: Boolean;
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
    procedure SetGroupPosition(const aValue: TKMPoint);
    property Direction: TKMDirection read GetDirection write SetDirection;
    property UnitsPerRow: Word read fUnitsPerRow write SetUnitsPerRow;
    property SelectedUnit: TKMUnitWarrior read GetSelected write SetSelected;
    property Condition: Integer read GetCondition write SetCondition;
    property Order: TKMGroupOrder read fOrder;
    property DisableHungerMessage: Boolean read fDisableHungerMessage write fDisableHungerMessage;
    property BlockOrders: Boolean read fBlockOrders write fBlockOrders;
    property ManualFormation: Boolean read fManualFormation write fManualFormation;
    property FlagPositionF: TKMPointF read GetFlagPositionF;
    property FlagColor: Cardinal read GetFlagColor;
    function IsFlagRenderBeforeUnit: Boolean;

    property OrderLoc: TKMPointDir read fOrderLoc;
    property OrderTargetUnit: TKMUnit read GetOrderTargetUnit write SetOrderTargetUnit;
    property OrderTargetGroup: TKMUnitGroup read GetOrderTargetGroup;
    property OrderTargetHouse: TKMHouse read GetOrderTargetHouse write SetOrderTargetHouse;

    procedure OwnerUpdate(aOwner: TKMHandID; aMoveToNewOwner: Boolean = False);

    function IsSelectable: Boolean; override;

    procedure OrderAttackHouse(aHouse: TKMHouse; aClearOffenders: Boolean; aForced: Boolean = True);
    procedure OrderAttackUnit(aUnit: TKMUnit; aClearOffenders: Boolean; aForced: Boolean = True);
    procedure OrderFood(aClearOffenders: Boolean; aHungryOnly: Boolean = False);
    procedure OrderFormation(aTurnAmount: TKMTurnDirection; aColumnsChange: ShortInt; aClearOffenders: Boolean);
    procedure OrderHalt(aClearOffenders: Boolean; aForced: Boolean = True);
    procedure OrderLinkTo(aTargetGroup: TKMUnitGroup; aClearOffenders: Boolean);
    procedure OrderNone;
    function OrderSplit(aNewLeaderUnitType: TKMUnitType; aNewCnt: Integer; aMixed: Boolean): TKMUnitGroup; overload;
    function OrderSplit(aSplitSingle: Boolean = False): TKMUnitGroup; overload;
    function OrderSplitUnit(aUnit: TKMUnit; aClearOffenders: Boolean): TKMUnitGroup;
    procedure OrderSplitLinkTo(aGroup: TKMUnitGroup; aCount: Word; aClearOffenders: Boolean);
    procedure OrderStorm(aClearOffenders: Boolean);
    procedure OrderWalk(const aLoc: TKMPoint; aClearOffenders: Boolean; aOrderWalkKind: TKMOrderWalkKind;
                        aDir: TKMDirection = dirNA; aForced: Boolean = True);

    procedure OrderRepeat(aForced: Boolean = True);
    procedure CopyOrderFrom(aGroup: TKMUnitGroup; aUpdateOrderLoc: Boolean; aForced: Boolean = True);

    procedure KillGroup;

    function ObjToStringShort(const aSeparator: String = '|'): String; override;
    function ObjToString(const aSeparator: String = '|'): String; override;

    procedure UpdateState;
    procedure PaintHighlighted(aHandColor, aFlagColor: Cardinal; aDoImmediateRender: Boolean = False; aDoHighlight: Boolean = False; aHighlightColor: Cardinal = 0);
    procedure Paint;

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
    procedure GetGroupsInRect(const aRect: TKMRect; List: TList);
    function GetClosestGroup(const aPoint: TKMPoint; aTypes: TKMGroupTypeSet = [Low(TKMGroupType)..High(TKMGroupType)]): TKMUnitGroup;
    function GetGroupsInRadius(aPoint: TKMPoint; aSqrRadius: Single; aTypes: TKMGroupTypeSet = [Low(TKMGroupType)..High(TKMGroupType)]): TKMUnitGroupArray;
    function GetGroupsMemberInRadius(aPoint: TKMPoint; aSqrRadius: Single; var aUGA: TKMUnitGroupArray; aTypes: TKMGroupTypeSet = [Low(TKMGroupType)..High(TKMGroupType)]): TKMUnitArray;


    procedure Clear;

    function WarriorTrained(aUnit: TKMUnitWarrior): TKMUnitGroup;

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad;
    procedure UpdateState;
    procedure Paint(const aRect: TKMRect);
  end;


implementation
uses
  TypInfo,
  KM_Game, KM_GameParams, KM_Hand, KM_HandsCollection, KM_Terrain, KM_CommonUtils, KM_ResTexts, KM_RenderPool,
  KM_Hungarian, KM_UnitActionWalkTo, KM_ResUnits, KM_ScriptingEvents,
  KM_UnitActionStormAttack, KM_CommonClassesExt, KM_RenderAux,
  KM_GameTypes, KM_Log, KM_DevPerfLog, KM_DevPerfLogTypes,
  KM_HandTypes;


const
  HUNGER_CHECK_FREQ = 10; //Check warrior hunger every 1 second


{ TKMUnitGroup }
//Create a Group from a single warrior (short version)
constructor TKMUnitGroup.Create(aID: Cardinal; aCreator: TKMUnitWarrior);
begin
  inherited Create(etGroup, aID, aCreator.Owner);

  fGroupType := UNIT_TO_GROUP_TYPE[aCreator.UnitType];
  fMembers := TList.Create;
  fOffenders := TList.Create;

  //So when they click Halt for the first time it knows where to place them
  fOrderLoc := KMPointDir(aCreator.Position.X, aCreator.Position.Y, aCreator.Direction);

  AddMember(aCreator);
  UnitsPerRow := 1;
  fMembersPushbackCommandsCnt := 0;
end;


//Create a Group from script (creates all the warriors as well)
constructor TKMUnitGroup.Create(aID: Cardinal; aOwner: TKMHandID; aUnitType: TKMUnitType; PosX, PosY: Word;
                                aDir: TKMDirection; aUnitPerRow, aCount: Word);
var
  Warrior: TKMUnitWarrior;
  I: Integer;
  DoesFit: Boolean;
  UnitLoc: TKMPoint;
  NewCondition: Word;
  DesiredArea: Byte;
begin
  inherited Create(etGroup, aID, aOwner);

  fGroupType := UNIT_TO_GROUP_TYPE[aUnitType];
  fMembers := TList.Create;
  fOffenders := TList.Create;

  //So when they click Halt for the first time it knows where to place them
  fOrderLoc := KMPointDir(PosX, PosY, aDir);

  //Whole group should have the same condition
  NewCondition := Round(UNIT_MAX_CONDITION * (UNIT_CONDITION_BASE + KaMRandomS2(UNIT_CONDITION_RANDOM, 'TKMUnitGroup.Create')));

  if gGameParams.IsMapEditor then
  begin
    //In MapEd we create only flagholder, other members are virtual
    Warrior := TKMUnitWarrior(gHands[aOwner].AddUnit(aUnitType, KMPoint(PosX, PosY), False, 0, False, False));
    if Warrior <> nil then
    begin
      Warrior.Direction := aDir;
      Warrior.AnimStep  := UNIT_STILL_FRAMES[aDir];
      AddMember(Warrior);
      Warrior.Condition := GetDefaultCondition;
      fMapEdCount := aCount;
    end;
  end
  else
  begin
    //We want all of the Group memmbers to be placed in one area
    DesiredArea := gTerrain.GetWalkConnectID(KMPoint(PosX, PosY));
    for I := 0 to aCount - 1 do
    begin
      UnitLoc := GetPositionInGroup2(PosX, PosY, aDir, I, aUnitPerRow, gTerrain.MapX, gTerrain.MapY, DoesFit);
      if not DoesFit then Continue;

      Warrior := TKMUnitWarrior(gHands[aOwner].AddUnit(aUnitType, UnitLoc, True, DesiredArea));
      if Warrior = nil then Continue;

      Warrior.Direction := aDir;
      Warrior.AnimStep  := UNIT_STILL_FRAMES[aDir];
      AddMember(Warrior, -1, False);
      Warrior.Condition := NewCondition;
    end;
  end;

  //We could not set it earlier cos it's limited by Count
  UnitsPerRow := aUnitPerRow;
  fMembersPushbackCommandsCnt := 0;
end;


//Load the Group from savegame
constructor TKMUnitGroup.Load(LoadStream: TKMemoryStream);
var
  I, NewCount: Integer;
  W: TKMUnitWarrior;
begin
  inherited;

  LoadStream.CheckMarker('UnitGroup');
  fMembers := TList.Create;
  fOffenders := TList.Create;

  LoadStream.Read(fGroupType, SizeOf(fGroupType));
  LoadStream.Read(NewCount);
  for I := 0 to NewCount - 1 do
  begin
    LoadStream.Read(W, 4); //subst on syncload
    fMembers.Add(W);
  end;

  LoadStream.Read(NewCount);
  for I := 0 to NewCount - 1 do
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
  LoadStream.Read(fBlockOrders);
  LoadStream.Read(fManualFormation);
  LoadStream.Read(fMembersPushbackCommandsCnt);
end;


procedure TKMUnitGroup.SyncLoad;
var I: Integer;
begin
  inherited;

  //Assign event handlers after load
  for I := 0 to Count - 1 do
  begin
    fMembers[I] := TKMUnitWarrior(gHands.GetUnitByUID(Cardinal(fMembers[I])));
    Members[I].OnWarriorDied := Member_Died;
    Members[I].OnPickedFight := Member_PickedFight;
  end;

  for I := 0 to fOffenders.Count - 1 do
    fOffenders[I] := TKMUnitWarrior(gHands.GetUnitByUID(Cardinal(TKMUnitWarrior(fOffenders[I]))));

  fOrderTargetGroup := gHands.GetGroupByUID(Cardinal(fOrderTargetGroup));
  fOrderTargetHouse := gHands.GetHouseByUID(Cardinal(fOrderTargetHouse));
  fOrderTargetUnit  := gHands.GetUnitByUID(Cardinal(fOrderTargetUnit));
end;


destructor TKMUnitGroup.Destroy;
begin
  //We don't release unit pointers from fMembers, because the group is only destroyed when fMembers.Count = 0
  //or when the game is canceled (then it doesn't matter)
  fMembers.Free;

  //We need to release offenders pointers
  ClearOffenders;
  fOffenders.Free;

  ClearOrderTarget; //Free pointers

  inherited;
end;


function TKMUnitGroup.FightMaxRange: Single;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Count - 1 do
  if Members[I].GetFightMaxRange > Result then
    Result := Members[I].GetFightMaxRange;
end;


procedure TKMUnitGroup.Save(SaveStream: TKMemoryStream);
var I: Integer;
begin
  inherited;

  SaveStream.PlaceMarker('UnitGroup');
  SaveStream.Write(fGroupType, SizeOf(fGroupType));
  SaveStream.Write(fMembers.Count);
  for I := 0 to fMembers.Count - 1 do
    SaveStream.Write(Members[I].UID);
  SaveStream.Write(fOffenders.Count);
  for I := 0 to fOffenders.Count - 1 do
    SaveStream.Write(TKMUnitWarrior(fOffenders[I]).UID);
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
  SaveStream.Write(fBlockOrders);
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
    Result := Min(Result, Members[I].Condition);
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
  Result := fMembers.Items[aIndex];
end;


function TKMUnitGroup.GetAliveMember: TKMUnitWarrior;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    Result := Members[I];
    if not Result.IsDeadOrDying then
      Exit;
  end;
  Result := nil;
end;


function TKMUnitGroup.GetFlagBearer: TKMUnitWarrior;
begin
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
                  and (gTerrain.GetWalkConnectID(Result.Loc) = gTerrain.GetWalkConnectID(Members[aIndex].Position));
end;


function TKMUnitGroup.GetNearestMember(aUnit: TKMUnitWarrior): Integer;
var
  I: Integer;
  Dist, Best: Single;
begin
  Result := -1;
  Best := MaxSingle;
  for I := 0 to Count - 1 do
  if (Members[I] <> aUnit) and not Members[I].IsDeadOrDying then
  begin
    Dist := KMLengthSqr(aUnit.Position, Members[I].Position);
    if Dist < Best then
    begin
      Best := Dist;
      Result := I;
    end;
  end;
end;


function TKMUnitGroup.GetNearestMember(const aLoc: TKMPoint): TKMUnitWarrior;
var
  I: Integer;
  Dist, Best: Single;
begin
  Result := nil;
  Best := MaxSingle;
  for I := 0 to Count - 1 do
  if not Members[I].IsDeadOrDying then
  begin
    Dist := KMLengthSqr(aLoc, Members[I].Position);
    if Dist < Best then
    begin
      Best := Dist;
      Result := Members[I];
    end;
  end;
end;


//Get current groups location (we use flagholder)
function TKMUnitGroup.GetPosition: TKMPoint;
begin
  if not IsDead then
    Result := Members[0].Position
  else
    Result := KMPOINT_ZERO;
end;


procedure TKMUnitGroup.SetGroupPosition(const aValue: TKMPoint);
begin
  Assert(gGameParams.IsMapEditor);

  Members[0].SetUnitPosition(aValue);
  fOrderLoc.Loc := Members[0].Position; //Don't assume we can move to aValue
end;


procedure TKMUnitGroup.SetSelected(aValue: TKMUnitWarrior);
begin
  Assert(HasMember(aValue), 'Cant''t select unit that is not a groups member');
  fSelected := aValue;
end;


function TKMUnitGroup.GetSelected: TKMUnitWarrior;
begin
  if Self = nil then Exit(nil);

  if (fSelected = nil) and (Count > 0) then
    fSelected := FlagBearer;
  Result := fSelected;
end;


procedure TKMUnitGroup.SetGroupOrder(aOrder: TKMGroupOrder);
begin
  fOrder := aOrder;
  fMembersPushbackCommandsCnt := 0;
end;


procedure TKMUnitGroup.SetCondition(aValue: Integer);
var I: Integer;
begin
  for I := 0 to Count - 1 do
    Members[I].Condition := aValue;
end;


procedure TKMUnitGroup.SetDirection(Value: TKMDirection);
begin
  Assert(gGameParams.IsMapEditor);
  fOrderLoc.Dir := Value;
  Members[0].Direction := Value;
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
end;


function TKMUnitGroup.HasMember(aWarrior: TKMUnit): Boolean;
begin
  Result := fMembers.IndexOf(aWarrior) <> -1;
end;


//Used by the MapEd after changing direction (so warriors are frozen on the right frame)
procedure TKMUnitGroup.ResetAnimStep;
begin
  Assert(gGameParams.IsMapEditor);
  Members[0].AnimStep := UNIT_STILL_FRAMES[Members[0].Direction];
end;


//If the player is allowed to issue orders to group
function TKMUnitGroup.CanTakeOrders: Boolean;
begin
  Result := (IsRanged or not InFight) and (not fBlockOrders);
end;


function TKMUnitGroup.CanWalkTo(const aTo: TKMPoint; aDistance: Single): Boolean;
begin
  Result := (Count > 0) and Members[0].CanWalkTo(aTo, aDistance);
end;


//Group is dead, but still exists cos of pointers to it
function TKMUnitGroup.IsDead: Boolean;
begin
  Result := (Count = 0);
end;


function TKMUnitGroup.IsRanged: Boolean;
begin
  Result := (fGroupType = gtRanged);
end;


function TKMUnitGroup.IsSelectable: Boolean;
begin
  if Self = nil then Exit(False);

  Result := not IsDead;
end;


procedure TKMUnitGroup.KillGroup;
var I: Integer;
begin
  for I := fMembers.Count - 1 downto 0 do
    TKMUnit(fMembers[I]).Kill(PLAYER_NONE, True, False);
end;


//Select nearest member for group. Or set it to nil it no other members were found
procedure TKMUnitGroup.SelectNearestMember;
var
  NewSel: Integer;
begin
  //Transfer selection to nearest member
  NewSel := GetNearestMember(fSelected);
  fSelected := nil;
  if NewSel <> -1 then
    fSelected := Members[NewSel];
end;


//Member reports that he has died (or been killed)
procedure TKMUnitGroup.Member_Died(aMember: TKMUnitWarrior);
var
  I: Integer;
  NewSel: Integer;
begin
  if aMember = nil then
    Exit;

  if aMember.HitPointsInvulnerable then
    Exit;

  I := fMembers.IndexOf(aMember);
  Assert(I <> -1, 'No such member');

  if (aMember = fSelected) then
    SelectNearestMember;

  fMembers.Delete(I);

  //Move nearest member to placeholders place
  if I = 0 then
  begin
    NewSel := GetNearestMember(aMember);
    if NewSel <> -1 then
      fMembers.Exchange(NewSel, 0);
  end;

  gHands.CleanUpUnitPointer(TKMUnit(aMember));

  SetUnitsPerRow(fUnitsPerRow);

  //If Group has died report to owner
  if IsDead and Assigned(OnGroupDied) then
    OnGroupDied(Self);

  //Only repeat the order if we are not in a fight (since bowmen can still take orders when fighting)
  if not IsDead and CanTakeOrders and not InFight then
    OrderRepeat(False);
end;


//Member got in a fight
//Remember who we are fighting with, to guide idle units to
//This only works for melee offenders(?)
procedure TKMUnitGroup.Member_PickedFight(aMember: TKMUnitWarrior; aEnemy: TKMUnit);
begin
  if (aEnemy is TKMUnitWarrior) then
    fOffenders.Add(aEnemy.GetPointer);
end;


//If we picked up a fight, while doing any other order - manage it here
procedure TKMUnitGroup.CheckForFight;
var
  I,K: Integer;
  U: TKMUnit;
  FightWasOrdered: Boolean;
begin
  //Verify we still have foes
  for I := fOffenders.Count - 1 downto 0 do
    if TKMUnitWarrior(fOffenders[I]).IsDeadOrDying
      or IsAllyTo(TKMUnitWarrior(fOffenders[I])) then //Offender could become an ally from script
    begin
      U := fOffenders[I]; //Need to pass var
      gHands.CleanUpUnitPointer(U);
      fOffenders.Delete(I);
      if fOffenders.Count = 0 then
        OrderRepeat;
    end;

  //Fight is over
  if fOffenders.Count = 0 then Exit;

  if IsRanged then
  begin
    FightWasOrdered := False;
    for I := 0 to Count - 1 do
      if not Members[I].InFight then
        //If there are several enemies within range, shooting any of the offenders is first priority
        //If there are no offenders in range then CheckForEnemy will pick a new target
        //Archers stay still and attack enemies only within their range without walking to/from them
        for K := 0 to fOffenders.Count - 1 do
          if Members[I].WithinFightRange(TKMUnitWarrior(fOffenders[K]).Position) then
          begin
            Members[I].OrderFight(TKMUnitWarrior(fOffenders[K]));
            FightWasOrdered := True;
          end;

    //If nobody in the group is in a fight and all offenders are out of range then clear offenders
    //(archers should forget about out of range offenders since they won't walk to them like melee)
    if not FightWasOrdered and not InFight then
    begin
      ClearOffenders;
      OrderRepeat;
    end;
  end
  else
  begin
    //Idle members should help their comrades
    for I := 0 to Count - 1 do
    if not Members[I].InFight then
      Members[I].OrderWalk(TKMUnitWarrior(fOffenders[KaMRandom(fOffenders.Count, 'TKMUnitGroup.CheckForFight')]).NextPosition, False);
  end;
end;


//Check if order has been executed and if necessary attempt to repeat it
procedure TKMUnitGroup.CheckOrderDone;
var
  I: Integer;
  OrderExecuted: Boolean;
  P: TKMPointExact;
  U: TKMUnitWarrior;
  pushbackLimit: Word;
  pushbackLimitReached: Boolean;
begin
  OrderExecuted := False;

  //1. Check the Order
  //2. Attempt to finish the order
  case fOrder of
    goNone:         OrderExecuted := False;
    goWalkTo:       begin
                      OrderExecuted := True;
                      pushbackLimit := GetPushbackLimit; //Save it to avoid recalc for every unit
                      for I := 0 to Count - 1 do
                      begin
                        pushbackLimitReached := fMembersPushbackCommandsCnt > pushbackLimit;
                        OrderExecuted := OrderExecuted and Members[I].IsIdle and (Members[I].OrderDone or pushbackLimitReached);

                        if Members[I].OrderDone then
                        begin
                          //If the unit is idle make them face the right direction
                          if Members[I].IsIdle
                          and (fOrderLoc.Dir <> dirNA) and (Members[I].Direction <> fOrderLoc.Dir) then
                          begin
                            Members[I].Direction := fOrderLoc.Dir;
                            Members[I].SetActionStay(50, uaWalk); //Make sure the animation still frame is updated
                          end;
                        end
                        else
                          //Guide Idle and pushed units back to their places
                          if not pushbackLimitReached
                            and (Members[I].IsIdle
                                 or ((Members[I].Action is TKMUnitActionWalkTo) and TKMUnitActionWalkTo(Members[I].Action).WasPushed)) then
                          begin
                            P := GetMemberLocExact(I);
                            Members[I].OrderWalk(P.Loc, P.Exact);
                            fMembersPushbackCommandsCnt := Min(fMembersPushbackCommandsCnt + 1, High(Word));
                          end;
                      end;
                    end;
    goAttackHouse:  begin
                      //It is TaskAttackHouse responsibility to execute it
                      OrderExecuted := (OrderTargetHouse = nil) or IsAllyTo(OrderTargetHouse); //Target could become ally from script
                    end;
    goAttackUnit:   begin
                      if IsRanged then
                      begin
                        //Ranged units must kill target unit only
                        //Then they will attack anything within their reach by themselves
                        OrderExecuted := (OrderTargetUnit = nil) or IsAllyTo(OrderTargetUnit); //Target could become ally from script

                        if not OrderExecuted then
                          //If our leader is out of range (enemy has walked away) we need to walk closer
                          if (KMLength(fOrderLoc.Loc, OrderTargetUnit.Position) > Members[0].GetFightMaxRange) then
                            OrderAttackUnit(OrderTargetUnit, False)
                          else
                            //Our leader is in range so each member should get into position
                            for I := 0 to Count - 1 do
                            if Members[I].IsIdle then
                            begin
                              P := GetMemberLocExact(I);
                              if KMSamePoint(Members[I].Position, P.Loc)
                              or (KMLength(Members[I].Position, OrderTargetUnit.Position) <= Members[I].GetFightMaxRange) then
                              begin
                                //We are at the right spot, so face towards enemy
                                Members[I].Direction := KMGetDirection(Members[I].Position, OrderTargetUnit.Position);
                                Members[I].FaceDir := Members[I].Direction;
                                if not Members[I].CheckForEnemy then
                                  //If we are too close to shoot, make sure the animation still frame is still updated
                                  Members[I].SetActionStay(10, uaWalk);
                              end
                              else
                              begin
                                //Too far away. Walk to the enemy in our formation
                                Members[I].OrderWalk(P.Loc, P.Exact);
                                Members[I].FaceDir := fOrderLoc.Dir;
                              end;
                            end;
                      end
                      else
                      begin
                        //Melee units must kill target unit and its Group
                        OrderExecuted :=
                              //Target could become ally from script
                              ((OrderTargetUnit = nil)  or IsAllyTo(OrderTargetUnit))
                          and ((OrderTargetGroup = nil) or IsAllyTo(OrderTargetGroup));

                        if (OrderTargetUnit <> nil) and not IsAllyTo(OrderTargetUnit) then //Target could become ally from script
                        begin
                          //See if target is escaping
                          if not KMSamePoint(OrderTargetUnit.NextPosition, fOrderLoc.Loc) then
                          begin
                            Inc(fTargetFollowTicker);
                            //It's wasteful to run pathfinding to correct route every step of the way, so if the target unit
                            //is within 4 tiles, update every step. Within 8, every 2 steps, 12, every 3 steps, etc.
                            if fTargetFollowTicker mod Max((Round(KMLengthDiag(GetPosition, OrderTargetUnit.Position)) div 4), 1) = 0 then
                              OrderAttackUnit(OrderTargetUnit, False);
                          end;

                          for I := 0 to Count - 1 do
                            if Members[I].IsIdle then
                            begin
                              P := GetMemberLocExact(I);
                              Members[I].OrderWalk(P.Loc, P.Exact);
                            end;
                        end;


                        //If Enemy was killed, but target Group still exists
                        //Group could become an ally from script
                        if (OrderTargetUnit = nil) and ((OrderTargetGroup <> nil) and not IsAllyTo(OrderTargetGroup)) then
                        begin
                          //Old enemy has died, change target to his comrades
                          U := OrderTargetGroup.GetNearestMember(Members[0].Position);
                          if U <> nil then // U could be nil in some rare cases (probably some rare bug with unit kills from scripts), just ignore that situation for now
                            OrderAttackUnit(U, False)
                          else
                            OrderExecuted := True; //Could rarely happen, as described above
                        end;
                      end;
                    end;
    goStorm:        OrderExecuted := False;
  end;

  if OrderExecuted then
  begin
    for I := 0 to Count - 1 do
    if (fOrderLoc.Dir <> dirNA) and Members[I].IsIdle then //Don't change direction whilst f.e. walking
      Members[I].Direction := fOrderLoc.Dir;
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
    if Members[I].InFight(aCountCitizens) then
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
    if not Members[I].InFight(aCountCitizens) then
      Exit(False);
end;


function TKMUnitGroup.InFightAgaistGroups(var aGroupArray: TKMUnitGroupArray): Boolean;
var
  Check: Boolean;
  I,K,Cnt: Integer;
  U: TKMUnit;
  G: TKMUnitGroup;
begin
  Cnt := 0;
  for I := 0 to Count - 1 do
  begin
    U := nil;
    if not Members[I].IsDeadOrDying
      AND Members[I].InFightAgaist(U, False)
      AND (U <> nil)
      AND not U.IsDeadOrDying then
    begin
      G := gHands[ U.Owner ].UnitGroups.GetGroupByMember( TKMUnitWarrior(U) );
      if (G <> nil) then // Group can be nil if soldiers go out of Barracks
      begin
        Check := True;
        for K := 0 to Cnt - 1 do
          if (aGroupArray[K] = G) then
          begin
            Check := False;
            break;
          end;
        if Check then
        begin
          if (Length(aGroupArray) >= Cnt) then
            SetLength(aGroupArray, Cnt + 12);
          aGroupArray[Cnt] := G;
          Cnt := Cnt + 1;
        end;
      end;
    end;
  end;
  SetLength(aGroupArray,Cnt);

  Result := (Length(aGroupArray) > 0);
end;


function TKMUnitGroup.IsAttackingHouse: Boolean;
var
  I: Integer;
begin
  Result := False;

  for I := 0 to Count - 1 do
  if (Members[I].Task <> nil)
  and (Members[I].Task.TaskType = uttAttackHouse) then
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
    U := Members[I];
    Result := U.IsIdle and KMSamePoint(U.Position, P.Loc) and (U.Direction = Dir);
    if not Result then Exit;
  end;
end;


function TKMUnitGroup.IsAllyTo(aUnit: TKMUnit): Boolean;
begin
  Result := gHands[Owner].Alliances[aUnit.Owner] = atAlly;
end;


function TKMUnitGroup.IsAllyTo(aUnitGroup: TKMUnitGroup): Boolean;
begin
  Result := gHands[Owner].Alliances[aUnitGroup.Owner] = atAlly;
end;


function TKMUnitGroup.IsAllyTo(aHouse: TKMHouse): Boolean;
begin
  Result := gHands[Owner].Alliances[aHouse.Owner] = atAlly;
end;


function TKMUnitGroup.MemberByUID(aUID: Integer): TKMUnitWarrior;
var
  I: Integer;
begin
  Result := nil;

  for I := 0 to Count - 1 do
  if (Members[I].UID = aUID) and not Members[I].IsDead then
    Exit(Members[I]);
end;


function TKMUnitGroup.HitTest(X,Y: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;

  for I := 0 to Count - 1 do
  if Members[I].HitTest(X, Y) and not Members[I].IsDead then
    Exit(True);
end;


procedure TKMUnitGroup.SelectFlagBearer;
begin
  fSelected := fMembers[0];
end;


procedure TKMUnitGroup.SetOwner(const aOwner: TKMHandID);
var
  I: Integer;
begin
  inherited SetOwner(aOwner);

  for I := 0 to fMembers.Count - 1 do
    TKMUnitWarrior(fMembers[I]).Owner := aOwner;
end;


procedure TKMUnitGroup.OwnerUpdate(aOwner: TKMHandID; aMoveToNewOwner: Boolean = False);
var I: Integer;
begin
  if aMoveToNewOwner and (Owner <> aOwner) then
  begin
    Assert(gGameParams.Mode = gmMapEd); // Allow to move existing Unit directly only in MapEd
    gHands[Owner].UnitGroups.DeleteGroupFromList(Self);
    gHands[aOwner].UnitGroups.AddGroupToList(Self);
  end;
  Owner := aOwner;
  for I := 0 to fMembers.Count - 1 do
    TKMUnitWarrior(fMembers[I]).OwnerUpdate(aOwner, aMoveToNewOwner);
end;


//All units are assigned TTaskAttackHouse which does everything for us (move to position, hit house, abandon, etc.)
procedure TKMUnitGroup.OrderAttackHouse(aHouse: TKMHouse; aClearOffenders: Boolean; aForced: Boolean = True);
var
  I: Integer;
begin
  Assert(aHouse <> nil);

  //Can attack only enemy houses
  if gHands[Owner].Alliances[aHouse.Owner] <> atEnemy then Exit;

  if aClearOffenders and CanTakeOrders then ClearOffenders;

  SetGroupOrder(goAttackHouse);
  fOrderLoc := KMPointDir(0, 0, dirNA);
  OrderTargetHouse := aHouse;

  for I := 0 to Count - 1 do
    Members[I].OrderAttackHouse(aHouse, aForced);

  //Script may have additional event processors
  gScriptEvents.ProcGroupOrderAttackHouse(Self, aHouse);
end;


procedure TKMUnitGroup.OrderAttackUnit(aUnit: TKMUnit; aClearOffenders: Boolean; aForced: Boolean = True);
var
  I: Integer;
  NodeList: TKMPointList;
  P: TKMPointExact;
begin
  Assert(aUnit <> nil);

  //If unit is already dying ignore the order
  if aUnit.IsDeadOrDying then Exit;

  //Can attack only enemy units
  if gHands[Owner].Alliances[aUnit.Owner] <> atEnemy then Exit;

  if aClearOffenders and CanTakeOrders then
    ClearOffenders;

  if IsRanged then
  begin
    //Ranged units should walk in formation to within range of the enemy
    SetGroupOrder(goAttackUnit);
    OrderTargetUnit := aUnit;

    //First choose fOrderLoc, which is where the leader will stand to shoot
    if (KMLength(Members[0].Position, OrderTargetUnit.Position) > Members[0].GetFightMaxRange) then
    begin
      NodeList := TKMPointList.Create;
      try
        if gGame.Pathfinding.Route_Make(Members[0].Position, OrderTargetUnit.NextPosition, [tpWalk], Members[0].GetFightMaxRange, nil, NodeList) then
        begin
          fOrderLoc.Loc := NodeList[NodeList.Count-1];
          fOrderLoc.Dir := KMGetDirection(NodeList[NodeList.Count-1], OrderTargetUnit.NextPosition);
          HungarianReorderMembers; //We are about to get them to walk to fOrderLoc
        end
        else
        begin
          OrderTargetUnit := nil; //Target cannot be reached, so abort completely
          SetGroupOrder(goNone);
          FreeAndNil(NodeList);
          Exit;
        end;
      finally
        FreeAndNil(NodeList);
      end;
    end
    else
    begin
      fOrderLoc.Loc := Members[0].Position; //Leader is already within range
      fOrderLoc.Dir := KMGetDirection(Members[0].Position, OrderTargetUnit.NextPosition);
    end;

    //Next assign positions for each member (including leader)
    for I := 0 to Count - 1 do
    begin
      //Check target in range, and if not - chase it / back up from it
      P := GetMemberLocExact(I);
      if not KMSamePoint(Members[I].Position, P.Loc)
        and((KMLength(Members[I].NextPosition, OrderTargetUnit.Position) > Members[I].GetFightMaxRange)
        or (KMLength(Members[I].NextPosition, OrderTargetUnit.Position) < Members[I].GetFightMinRange)) then
      begin
        //Too far/close. Walk to the enemy in formation
        Members[I].OrderWalk(P.Loc, P.Exact, aForced);
        Members[I].FaceDir := fOrderLoc.Dir;
      end
      else
        if not Members[I].IsIdle then
        begin
          Members[I].OrderWalk(Members[I].NextPosition, True, aForced); //We are at the right spot already, just need to abandon what we are doing
          Members[I].FaceDir := fOrderLoc.Dir;
        end
        else
        begin
          //We are within range, so face towards the enemy
          //Don't fight this specific enemy, giving archers exact targets is too abusable in MP. Choose random target in that direction.
          Members[I].Direction := KMGetDirection(Members[I].Position, aUnit.Position);
          Members[I].FaceDir := Members[I].Direction;
          if not Members[I].CheckForEnemy then
            //If we are too close to shoot, make sure the animation still frame is still updated
            Members[I].SetActionStay(10, uaWalk);
        end;
    end;
  end
  else
  begin
    //Walk in formation towards enemy,
    //Members will take care of attack when we approach
    OrderWalk(aUnit.NextPosition, False, wtokNone, dirNA, aForced);

    //Revert Order to proper one (we disguise Walk)
    SetGroupOrder(goAttackUnit);
    fOrderLoc := KMPointDir(aUnit.NextPosition, dirNA); //Remember where unit stand
    OrderTargetUnit := aUnit;
  end;

  //Script may have additional event processors
  gScriptEvents.ProcGroupOrderAttackUnit(Self, aUnit);
end;


//Order some food for troops
procedure TKMUnitGroup.OrderFood(aClearOffenders: Boolean; aHungryOnly: Boolean = False);
var I: Integer;
begin
  if aClearOffenders and CanTakeOrders then ClearOffenders;

  for I := 0 to Count - 1 do
    if not aHungryOnly or (Members[I].Condition <= UNIT_MIN_CONDITION) then
      Members[I].OrderFood;
end;


procedure TKMUnitGroup.OrderFormation(aTurnAmount: TKMTurnDirection; aColumnsChange: ShortInt; aClearOffenders: Boolean);
begin
  if IsDead then Exit;
  if aClearOffenders and CanTakeOrders then ClearOffenders;

  //If it is yet unset - use first members direction
  if fOrderLoc.Dir = dirNA then
    fOrderLoc.Dir := Members[0].Direction;

  case aTurnAmount of
    tdCW:   fOrderLoc.Dir := KMNextDirection(fOrderLoc.Dir);
    tdCCW:  fOrderLoc.Dir := KMPrevDirection(fOrderLoc.Dir);
  end;

  SetUnitsPerRow(Max(fUnitsPerRow + aColumnsChange, 0));

  ManualFormation := True;

  OrderRepeat;
end;


//Forcefull termination of any activity
procedure TKMUnitGroup.OrderHalt(aClearOffenders: Boolean; aForced: Boolean = True);
begin
  if aClearOffenders and CanTakeOrders then
    ClearOffenders;

  //Halt is not a true order, it is just OrderWalk
  //hose target depends on previous activity
  case fOrder of
    goNone:         if not KMSamePoint(fOrderLoc.Loc, KMPOINT_ZERO) then
                      OrderWalk(fOrderLoc.Loc, False, wtokHaltOrder, dirNA, aForced)
                    else
                      OrderWalk(Members[0].NextPosition, False, wtokHaltOrder, dirNA, aForced);
    goWalkTo:       OrderWalk(Members[0].NextPosition, False, wtokHaltOrder, dirNA, aForced);
    goAttackHouse:  OrderWalk(Members[0].NextPosition, False, wtokHaltOrder, dirNA, aForced);
    goAttackUnit:   OrderWalk(Members[0].NextPosition, False, wtokHaltOrder, dirNA, aForced);
    goStorm:        OrderWalk(Members[0].NextPosition, False, wtokHaltOrder, dirNA, aForced);
  end;
end;


procedure TKMUnitGroup.OrderLinkTo(aTargetGroup: TKMUnitGroup; aClearOffenders: Boolean);
var
  U: TKMUnit;
begin
  if aClearOffenders and CanTakeOrders then ClearOffenders;

  //Any could have died since the time order was issued due to Net delay
  if IsDead or aTargetGroup.IsDead then Exit;

  //Only link to same group type
  if aTargetGroup.GroupType <> GroupType then Exit;

  //Can't link to self for obvious reasons
  if aTargetGroup = Self then Exit;

  //Move our members and self to the new group
  while (fMembers.Count <> 0) do
  begin
    U := Members[0];
    aTargetGroup.AddMember(Members[0], -1, False);
    gHands.CleanUpUnitPointer(U);
    fMembers.Delete(0);
  end;

  //In MP commands execution may be delayed, check if we still selected
  if gMySpectator.Selected = Self then
  begin
    gMySpectator.Selected := aTargetGroup;
    //What if fSelected died by now
    if not fSelected.IsDeadOrDying then
    begin
      if not aTargetGroup.HasMember(fSelected) then
        gLog.AddNoTimeNoFlush(
          Format('Make sure we joined selected unit. Group UID: %d; TargetGroup UID: %d Selected member UID: %d',
                 [UID, aTargetGroup.UID, fSelected.UID]));
      aTargetGroup.fSelected := fSelected;
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
    Members[I].OrderNone;
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
  I, NL, UPerRow: Integer;
  NewLeader: TKMUnitWarrior;
  U: TKMUnit;
  NewGroup: TKMUnitGroup;
  MemberUTypes: TKMListUnique<TKMUnitType>;
  PlainSplit, ChangeNewGroupOrderLoc: Boolean;
begin
  Result := nil;
  if IsDead then Exit;
  if Count < 2 then Exit;
  if not InRange(aNewCnt, 1, Count - 1) then Exit;
  if not (aNewLeaderUnitType in [WARRIOR_MIN..WARRIOR_MAX]) then Exit;

  //If leader is storming don't allow splitting the group (makes it too easy to withdraw)
  if Members[0].Action is TKMUnitActionStormAttack then Exit;

  if CanTakeOrders then
    ClearOffenders;

  MemberUTypes := TKMListUnique<TKMUnitType>.Create;
  try
    for I := 0 to Count - 1 do
      MemberUTypes.Add(Members[I].UnitType);

    PlainSplit := not MemberUTypes.Contains(aNewLeaderUnitType) // no specified leader type
                  or (MemberUTypes.Count = 1); // there is only 1 unit type in the group

    // Find new leader
    NewLeader := nil;

    if PlainSplit then
    begin
      NL := EnsureRange(Count - aNewCnt + (Min(fUnitsPerRow, aNewCnt) div 2), 0, Count - 1);
      NewLeader := Members[NL];
    end
    else
    if MemberUTypes.Contains(aNewLeaderUnitType) then
    begin
      for I := 0 to Count - 1 do
        if aNewLeaderUnitType = Members[I].UnitType then
          NewLeader := Members[I];
    end
    else //We did't find leader unit type
      Exit;
  finally
    MemberUTypes.Free;
  end;

  UPerRow := fUnitsPerRow; //Save formation for later
  //Remove from the group
  NewLeader.ReleasePointer;
  fMembers.Remove(NewLeader);

  NewGroup := gHands[Owner].UnitGroups.AddGroup(NewLeader);
  NewGroup.OnGroupDied := OnGroupDied;

  for I := Count - 1 downto 0 do
    if (aNewCnt > NewGroup.Count)
      and (PlainSplit or aMixed or (Members[I].UnitType = NewLeader.UnitType)) then
    begin
      U := Members[I];
      gHands.CleanUpUnitPointer(U);
      NewGroup.AddMember(Members[I], 1, False); // Join new group (insert next to commander)
      fMembers.Delete(I); // Leave this group
    end;

  //Keep the selected unit Selected
  if not SelectedUnit.IsDeadOrDying and NewGroup.HasMember(SelectedUnit) then
  begin
    NewGroup.fSelected := fSelected;
    SelectNearestMember; // For current group set fSelected to nearest member to its old selected
  end;

  //Make sure units per row is still valid for both groups
  UnitsPerRow := UPerRow;
  NewGroup.UnitsPerRow := UPerRow;

  //If we are hungry then don't repeat message each time we split, give new commander our counter
  NewGroup.fTimeSinceHungryReminder := fTimeSinceHungryReminder;

  ChangeNewGroupOrderLoc := True; //Update Order loc by default
  //For walk order our new leader was going to some loc, and we want this loc to be our new fOrderLoc for new group
  if (fOrder = goWalkTo)
    and (NewLeader.Action is TKMUnitActionWalkTo) then
  begin
    NewGroup.fOrderLoc := KMPointDir(TKMUnitActionWalkTo(NewLeader.Action).WalkTo, fOrderLoc.Dir);
    ChangeNewGroupOrderLoc := False; //Do not update order loc since we set it already
  end;

  //Tell both groups to reposition
  OrderRepeat(False);
  NewGroup.CopyOrderFrom(Self, ChangeNewGroupOrderLoc, False);

  Result := NewGroup; //Return the new group in case somebody is interested in it

  //Script may have additional event processors
  gScriptEvents.ProcGroupOrderSplit(Self, NewGroup);
end;


//Split group in half
//or split different unit types apart
function TKMUnitGroup.OrderSplit(aSplitSingle: Boolean = False): TKMUnitGroup;
var
  I: Integer;
  NewLeader: TKMUnitWarrior;
  MultipleTypes: Boolean;
  aNewLeaderUnitType: TKMUnitType; aOldCnt, aNewCnt: Integer; aMixed: Boolean;
begin
  Result := nil;
  if IsDead then Exit;
  if Count < 2 then Exit;
  //If leader is storming don't allow splitting the group (makes it too easy to withdraw)
  if Members[0].Action is TKMUnitActionStormAttack then Exit;

  //If there are different unit types in the group, split should just split them first
  MultipleTypes := False;


  //First find default split parameters - NewLeader type and new group members count

  //Choose the new leader
  if aSplitSingle then
    NewLeader := Members[Count - 1]
  else
  begin
    NewLeader := Members[(Count div 2) + (Min(fUnitsPerRow, Count div 2) div 2)];

    for I := 1 to Count - 1 do
      if Members[I].UnitType <> Members[0].UnitType then
      begin
        MultipleTypes := True;
        //New commander is first unit of different type, for simplicity
        NewLeader := Members[I];
        Break;
      end;
  end;

  aNewLeaderUnitType := NewLeader.UnitType;
  aNewCnt := 1;
  aOldCnt := Count - 1;
  // Determine new group members count
  if not aSplitSingle then
    //Split by UnitTypes or by Count (make NewGroup half or smaller half)
    for I := Count - 1 downto 0 do
    begin
      if Members[I] = NewLeader then Continue;

      if (MultipleTypes and (Members[I].UnitType = NewLeader.UnitType))
         or (not MultipleTypes and (aOldCnt > aNewCnt + 1)) then
      begin
        Inc(aNewCnt);
        Dec(aOldCnt);
      end;
    end;

  aMixed := False; // We don't use mixed group by default
  // Ask script if it ant to change some split parameters
  gScriptEvents.ProcGroupBeforeOrderSplit(Self, aNewLeaderUnitType, aNewCnt, aMixed);
  // Apply split with parameters, which came from Script
  Result := OrderSplit(aNewLeaderUnitType, aNewCnt, aMixed);

  // Select single splitted unit
  if aSplitSingle
    and (aNewCnt = 1) and (aNewLeaderUnitType = NewLeader.UnitType) //SplitSingle command was not changed by script
    and (gGame.ControlledHandIndex = Result.Owner) //Only select unit for player that issued order (group owner)
    and (gGame.ControlledHandIndex <> -1)
    and (gMySpectator.Selected = Self) then //Selection is still on that group (in MP game there could be a delay, when player could select other target already)
    gMySpectator.Selected := Result;
end;


//Split ONE certain unit from the group
function TKMUnitGroup.OrderSplitUnit(aUnit: TKMUnit; aClearOffenders: Boolean): TKMUnitGroup;
var
  NewGroup: TKMUnitGroup;
  NewLeader: TKMUnitWarrior;
begin
  Result := nil;
  if not HasMember(aUnit) then Exit;
  if IsDead then Exit;
  if Count < 2 then Exit;
  if aClearOffenders
  and CanTakeOrders then
    ClearOffenders;

  //Delete from group
  NewLeader := TKMUnitWarrior(aUnit);
  fMembers.Remove(NewLeader);
  NewLeader.ReleasePointer;

  //Give new group
  NewGroup := gHands[Owner].UnitGroups.AddGroup(NewLeader);
  NewGroup.OnGroupDied := OnGroupDied;
  NewGroup.fSelected := NewLeader;
  NewGroup.fTimeSinceHungryReminder := fTimeSinceHungryReminder;
  NewGroup.fOrderLoc := KMPointDir(NewLeader.Position, fOrderLoc.Dir);

  //Set units per row
  UnitsPerRow := fUnitsPerRow;
  NewGroup.UnitsPerRow := 1;

  //Save unit selection
  if NewGroup.HasMember(fSelected) then
  begin
    gMySpectator.Selected := NewGroup;
    NewGroup.fSelected := fSelected;
  end;

  //Halt both groups
  OrderHalt(False);
  NewGroup.OrderHalt(False);

  //Return NewGroup as result
  Result := NewGroup;

  //Script may have additional event processors
  gScriptEvents.ProcGroupOrderSplit(Self, NewGroup);
end;


//Splits X number of men from the group and adds them to the new commander
procedure TKMUnitGroup.OrderSplitLinkTo(aGroup: TKMUnitGroup; aCount: Word; aClearOffenders: Boolean);
var
  I: Integer;
  U: TKMUnit;
begin
  //Make sure to leave someone in the group
  Assert(aCount < Count);
  if aClearOffenders and CanTakeOrders then ClearOffenders;

  //Take units from the end, to keep flagholder
  for I := fMembers.Count - 1 downto fMembers.Count - aCount do
  begin
    U := Members[I];
    gHands.CleanUpUnitPointer(U);
    aGroup.AddMember(Members[I], -1, False);
    fMembers.Delete(I);
  end;

  //Make sure units per row is still valid
  SetUnitsPerRow(UnitsPerRow);

  //Tell both groups to reposition
  OrderHalt(False);
  aGroup.OrderHalt(False);
end;


procedure TKMUnitGroup.OrderStorm(aClearOffenders: Boolean);
var I: Integer;
begin
  //Don't allow ordering a second storm attack while there is still one active (possible due to network lag)
  if not CanTakeOrders then Exit;
  if aClearOffenders and CanTakeOrders then ClearOffenders;

  SetGroupOrder(goStorm);
  fOrderLoc := KMPointDir(0, 0, dirNA);
  ClearOrderTarget;

  //Each next row delayed by few ticks to avoid crowding
  for I := 0 to Count - 1 do
    Members[I].OrderStorm(I div fUnitsPerRow);
end;


procedure TKMUnitGroup.OrderWalk(const aLoc: TKMPoint; aClearOffenders: Boolean; aOrderWalkKind: TKMOrderWalkKind;
                                 aDir: TKMDirection = dirNA; aForced: Boolean = True);
var
  I: Integer;
  NewDir: TKMDirection;
  P: TKMPointExact;
begin
  if IsDead then Exit;

  fOrderWalkKind := aOrderWalkKind;

  if aClearOffenders and CanTakeOrders then
    ClearOffenders;

  if aDir = dirNA then
    if fOrderLoc.Dir = dirNA then
      NewDir := Members[0].Direction
    else
      NewDir := fOrderLoc.Dir
  else
    NewDir := aDir;

  fOrderLoc := KMPointDir(aLoc, NewDir);
  ClearOrderTarget;

  if IsPositioned(aLoc, NewDir) then
    Exit; //No need to actually walk, all members are at the correct location and direction

  SetGroupOrder(goWalkTo);
  HungarianReorderMembers;

  for I := 0 to Count - 1 do
  begin
    P := GetMemberLocExact(I);
    Members[I].OrderWalk(P.Loc, P.Exact, aForced);
    Members[I].FaceDir := NewDir;
  end;

  //Script may have additional event processors
  gScriptEvents.ProcGroupOrderMove(Self, aLoc.X, aLoc.Y);
end;


function TKMUnitGroup.UnitType: TKMUnitType;
begin
  Result := Members[0].UnitType;
end;


function TKMUnitGroup.HasUnitType(aUnitType: TKMUnitType): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to fMembers.Count - 1 do
    if not Members[I].IsDeadOrDying
      and (Members[I].UnitType = aUnitType) then
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
  SomeoneHungry: Boolean;
begin
  if IsDead then Exit;

  SomeoneHungry := False;
  for I := 0 to Count - 1 do
    if (Members[I] <> nil) 
    and not Members[I].IsDeadOrDying then
    begin
      SomeoneHungry := SomeoneHungry
                       or ((Members[I].Condition < UNIT_MIN_CONDITION)
                       and not Members[I].RequestedFood);
      if SomeoneHungry then Break;
    end;

  if SomeoneHungry then
  begin
    Dec(fTimeSinceHungryReminder, HUNGER_CHECK_FREQ);
    if fTimeSinceHungryReminder < 1 then
    begin
      gScriptEvents.ProcGroupHungry(Self);
      if not fDisableHungerMessage then
        gGame.ShowMessage(mkUnit, TX_MSG_TROOP_HUNGRY, Position, Owner);
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


function TKMUnitGroup.IsFlagRenderBeforeUnit: Boolean;
begin
  Result := FlagBearer.Direction in [dirSE, dirS, dirSW, dirW];
end;


function TKMUnitGroup.GetFlagPositionF: TKMPointF;
begin
  Result.X := FlagBearer.PositionF.X + UNIT_OFF_X + FlagBearer.GetSlide(axX);
  Result.Y := FlagBearer.PositionF.Y + UNIT_OFF_Y + FlagBearer.GetSlide(axY);
  //Flag needs to be rendered above or below unit depending on direction (see AddUnitFlag)
  if IsFlagRenderBeforeUnit then
    Result.Y := Result.Y - FLAG_X_OFFSET
  else
    Result.Y := Result.Y + FLAG_X_OFFSET;
end;


function TKMUnitGroup.GetInstance: TKMUnitGroup;
begin
  Result := Self;
end;


procedure TKMUnitGroup.SetPositionF(const aPositionF: TKMPointF);
begin
  raise Exception.Create('Can''t set PositionF for UnitGroup');
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
  Agents, Tasks: TKMPointList;
  I: Integer;
  NewOrder: TKMCardinalArray;
  NewMembers: TList;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psHungarian);
  {$ENDIF}
  try
    if not HUNGARIAN_GROUP_ORDER then Exit;
    if fMembers.Count <= 1 then Exit; //If it's just the leader we can't rearrange
    Agents := TKMPointList.Create;
    Tasks := TKMPointList.Create;

    //todo: Process each unit type seperately in mixed groups so their order is maintained

    //Skip leader, he can't be reordered because he holds the flag
    //(tossing flag around is quite complicated and looks unnatural in KaM)
    for I := 1 to fMembers.Count - 1 do
    begin
      Agents.Add(Members[I].Position);
      Tasks.Add(GetMemberLoc(I));
    end;

    //huIndividual as we'd prefer 20 members to take 1 step than 1 member to take 10 steps (minimize individual work rather than total work)
    NewOrder := HungarianMatchPoints(Tasks, Agents, huIndividual);
    NewMembers := TList.Create;
    NewMembers.Add(Members[0]);

    for I := 1 to fMembers.Count - 1 do
      NewMembers.Add(fMembers[NewOrder[I - 1] + 1]);

    fMembers.Free;
    fMembers := NewMembers;

    Agents.Free;
    Tasks.Free;
  finally
    {$IFDEF PERFLOG}
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
var G: TKMUnitGroup;
begin
  //Remove previous value
  ClearOrderTarget;
  if (aUnit <> nil) and not (aUnit.IsDeadOrDying) then
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


function TKMUnitGroup.ObjToStringShort(const aSeparator: String = '|'): String;
begin
  Result := Format('UID = %d%sType = %s%sMembersCount = %d',
                   [UID, aSeparator,
                    GetEnumName(TypeInfo(TKMGroupType), Integer(fGroupType)), aSeparator,
                    Count]);
end;


function TKMUnitGroup.ObjToString(const aSeparator: String = '|'): String;
var
  TargetUnitStr, TargetHouseStr, TargetGroupStr: String;
begin
  TargetUnitStr := 'nil';
  TargetHouseStr := 'nil';
  TargetGroupStr := 'nil';

  if fOrderTargetUnit <> nil then
    TargetUnitStr := fOrderTargetUnit.ObjToStringShort(', ');

  if fOrderTargetGroup <> nil then
    TargetGroupStr := fOrderTargetGroup.ObjToStringShort(', ');

  if fOrderTargetHouse <> nil then
    TargetHouseStr := fOrderTargetHouse.ObjToStringShort(', ');

  Result := ObjToStringShort +
            Format('%sOwner = %d%sUnitsPerRow = %d%sGroupOrder = %s%sOrderLoc = %s%s' +
                   'OrderTargetUnit = [%s]%sOrderTargetGroup = [%s]%sOrderTargetHouse = [%s]%sPushbackCommandsCnt = [%d]',
                   [aSeparator,
                    Owner, aSeparator,
                    fUnitsPerRow, aSeparator,
                    GetEnumName(TypeInfo(TKMGroupOrder), Integer(fOrder)), aSeparator,
                    TypeToString(fOrderLoc), aSeparator,
                    TargetUnitStr, aSeparator,
                    TargetGroupStr, aSeparator,
                    TargetHouseStr, aSeparator,
                    fMembersPushbackCommandsCnt]);
end;


procedure TKMUnitGroup.UpdateState;
var
  NeedCheckOrderDone: Boolean;
begin
  Inc(fTicker);
  if IsDead then Exit;

  UpdateOrderTargets;

  if fTicker mod HUNGER_CHECK_FREQ = 0 then
    UpdateHungerMessage;

  if fTicker mod 5 = 0 then
    CheckForFight;

  NeedCheckOrderDone := (fTicker mod 7 = 0);
  if NeedCheckOrderDone then
  begin
    if IsRanged then
      //Ranged units could be partially in fight
      //That could cause wrong unit direction, check it in further CheckOrderDone
      NeedCheckOrderDone := not InFightAllMembers
    else
      NeedCheckOrderDone := not InFight;
  end;

  if NeedCheckOrderDone then
    CheckOrderDone;
end;


procedure TKMUnitGroup.Paint;
begin
  PaintHighlighted(gHands[FlagBearer.Owner].GameFlagColor, FlagColor);
end;


procedure TKMUnitGroup.PaintHighlighted(aHandColor, aFlagColor: Cardinal; aDoImmediateRender: Boolean = False; aDoHighlight: Boolean = False; aHighlightColor: Cardinal = 0);
var
  UnitPos: TKMPointF;
  FlagStep: Cardinal;
  I: Integer;
  NewPos: TKMPoint;
  DoesFit: Boolean;
begin
  if IsDead then Exit;

  if not FlagBearer.Visible then Exit;
  if FlagBearer.IsDeadOrDying then Exit;

  //In MapEd units fTicker always the same, use Terrain instead
  FlagStep := IfThen(gGameParams.Mode = gmMapEd, gTerrain.AnimStep, fTicker);

  //Paint virtual members in MapEd mode
  for I := 1 to fMapEdCount - 1 do
  begin
    NewPos := GetPositionInGroup2(fOrderLoc.Loc.X, fOrderLoc.Loc.Y, fOrderLoc.Dir, I, fUnitsPerRow, gTerrain.MapX, gTerrain.MapY, DoesFit);
    if not DoesFit then Continue; //Don't render units that are off the map in the map editor
    UnitPos.X := NewPos.X + UNIT_OFF_X; //MapEd units don't have sliding
    UnitPos.Y := NewPos.Y + UNIT_OFF_Y;
    gRenderPool.AddUnit(FlagBearer.UnitType, 0, uaWalk, fOrderLoc.Dir, UNIT_STILL_FRAMES[fOrderLoc.Dir], UnitPos.X, UnitPos.Y, aHandColor, True, aDoImmediateRender, aDoHighlight, aHighlightColor);
  end;

  // We need to render Flag after MapEd virtual members
  gRenderPool.AddUnitFlag(FlagBearer.UnitType, FlagBearer.Action.ActionType,
    FlagBearer.Direction, FlagStep, FlagPositionF.X, FlagPositionF.Y, aFlagColor, aDoImmediateRender);

  if SHOW_GROUP_MEMBERS_POS and not gGameParams.IsMapEditor then
    for I := 0 to Count - 1 do
      gRenderAux.Text(Members[I].PositionF.X + 0.2, Members[I].PositionF.Y + 0.2, IntToStr(I), icCyan);
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
  fGroups.Free;

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
  Result := TKMUnitGroup.Create(gGame.GetNewUID, aWarrior);
  fGroups.Add(Result)
end;


function TKMUnitGroups.AddGroup(aOwner: TKMHandID; aUnitType: TKMUnitType; PosX, PosY: Word; aDir: TKMDirection;
                                aUnitPerRow, aCount: Word): TKMUnitGroup;
begin
  Result := nil;
  Assert(aUnitType in [WARRIOR_MIN..WARRIOR_MAX]);

  Result := TKMUnitGroup.Create(gGame.GetNewUID, aOwner, aUnitType, PosX, PosY, aDir, aUnitPerRow, aCount);

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
  LinkUnit: TKMUnitWarrior;
begin
  Result := nil; //Makes compiler happy

  case gHands[aUnit.Owner].HandType of
    hndHuman:    begin
                   LinkUnit := aUnit.FindLinkUnit(aUnit.Position);
                   if LinkUnit <> nil then
                   begin
                     //Link to other group
                     Result := gHands[aUnit.Owner].UnitGroups.GetGroupByMember(LinkUnit);
                     Result.AddMember(aUnit);
                     //Form a square (rather than a long snake like in TSK/TPR)
                     //but don't change formation if player decided to set it manually
                     if not Result.ManualFormation then
                       Result.UnitsPerRow := Ceil(Sqrt(Result.Count));
                     Result.OrderRepeat(False);
                   end
                   else
                   begin
                     //Create a new group with this one warrior
                     Result := TKMUnitGroup.Create(gGame.GetNewUID, aUnit);
                     fGroups.Add(Result);
                   end;
                 end;
    hndComputer: begin
                   Result := TKMUnitGroup.Create(gGame.GetNewUID, aUnit);
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


procedure TKMUnitGroups.GetGroupsInRect(const aRect: TKMRect; List: TList);
var
  I, K: Integer;
begin
  for I := 0 to Count - 1 do
    for K := 0 to Groups[I].Count - 1 do
      if KMInRect(Groups[I].Members[K].PositionF, aRect) and not Groups[I].Members[K].IsDeadOrDying then
      begin
        List.Add(Groups[I]);
        Break;
      end;
end;


function TKMUnitGroups.GetClosestGroup(const aPoint: TKMPoint; aTypes: TKMGroupTypeSet = [Low(TKMGroupType)..High(TKMGroupType)]): TKMUnitGroup;
var
  I: Integer;
  BestDist, Dist: Single;
begin
  Result := nil;
  BestDist := MaxSingle; //Any distance will be closer than that
  for I := 0 to Count - 1 do
    if not Groups[I].IsDead AND (Groups[I].GroupType in aTypes) then
    begin
      Dist := KMLengthSqr(Groups[I].GetPosition, aPoint);
      if Dist < BestDist then
      begin
        BestDist := Dist;
        Result := Groups[I];
      end;
    end;
end;


function TKMUnitGroups.GetGroupsInRadius(aPoint: TKMPoint; aSqrRadius: Single; aTypes: TKMGroupTypeSet = [Low(TKMGroupType)..High(TKMGroupType)]): TKMUnitGroupArray;
var
  I,K,Idx: Integer;
  UW: TKMUnitWarrior;
begin
  Idx := 0;
  for I := 0 to Count - 1 do
    if not Groups[I].IsDead AND (Groups[I].GroupType in aTypes) then
    begin
      K := 0;
      while (K < Groups[I].Count) do // Large groups may be in radius too so check every fifth member
        if Groups[I].Members[K].IsDeadOrDying then // Member must be alive
          K := K + 1
        else
        begin
          UW := Groups[I].Members[K];
          if (KMLengthSqr(UW.Position, aPoint) <= aSqrRadius) then
          begin
            if (Idx >= Length(Result)) then
              SetLength(Result, Idx + 12);
            Result[Idx] := Groups[I];
            Idx := Idx + 1;
            break;
          end;
          K := K + 5;
        end;
    end;
  SetLength(Result,Idx);
end;


function TKMUnitGroups.GetGroupsMemberInRadius(aPoint: TKMPoint; aSqrRadius: Single; var aUGA: TKMUnitGroupArray; aTypes: TKMGroupTypeSet = [Low(TKMGroupType)..High(TKMGroupType)]): TKMUnitArray;
var
  I,K,Idx: Integer;
  Dist, MinDist: Single;
  U, BestU: TKMUnit;
begin
  Idx := 0;
  BestU := nil;
  for I := 0 to Count - 1 do
    if not Groups[I].IsDead AND (Groups[I].GroupType in aTypes) then
    begin
      K := 0;
      MinDist := MaxSingle; //Any distance will be closer than that
      while (K < Groups[I].Count) do
        if Groups[I].Members[K].IsDeadOrDying then // Member must be alive
          K := K + 1
        else
        begin
          U := Groups[I].Members[K];
          Dist := KMLengthSqr(U.Position, aPoint);
          if (Dist <= MinDist) then
          begin
            MinDist := Dist;
            BestU := U;
          end;
          K := K + 5; // Large groups may be in radius too so check every fifth member
        end;
      if (MinDist <= aSqrRadius) then
      begin
        if (Idx >= Length(Result)) then
        begin
          SetLength(Result, Idx + 12);
          SetLength(aUGA, Idx + 12);
        end;
        Result[Idx] := BestU;
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
begin
  Assert(gGameParams.Mode = gmMapEd);
  fGroups.Clear;
end;


procedure TKMUnitGroups.Save(SaveStream: TKMemoryStream);
var I: Integer;
begin
  SaveStream.PlaceMarker('UnitGroups');
  SaveStream.Write(Count);
  for I := 0 to Count - 1 do
    Groups[I].Save(SaveStream);
end;


procedure TKMUnitGroups.Load(LoadStream: TKMemoryStream);
var
  I, NewCount: Integer;
begin
  LoadStream.CheckMarker('UnitGroups');
  LoadStream.Read(NewCount);
  for I := 0 to NewCount - 1 do
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


procedure TKMUnitGroups.Paint(const aRect: TKMRect);
const
  MARGIN = 2;
var
  I: Integer;
  growRect: TKMRect;
begin
  // Add additional margin to compensate for units height
  growRect := KMRectGrow(aRect, MARGIN);

  for I := 0 to Count - 1 do
  if not Groups[I].IsDead and KMInRect(Groups[I].Members[0].PositionF, growRect) then
    Groups[I].Paint;
end;


end.
