unit KM_Units;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, SysUtils, KromUtils, Types,
  KM_CommonClasses, KM_CommonTypes, KM_Defaults, KM_Points, KM_CommonUtils,
  KM_Terrain, KM_ResHouses, KM_ResWares, KM_Houses, KM_HouseSchool, KM_HouseBarracks, KM_HouseInn;

//Memo on directives:
//Dynamic - declared and used (overriden) occasionally
//Virtual - declared and used (overriden) always
//Abstract - declared but must be overriden in child classes

type
  TKMUnit = class;
  TKMUnitWorker = class;
  TKMUnitEvent = procedure(aUnit: TKMUnit) of object;
  TKMUnitFromEvent = procedure(aUnit: TKMUnit; aFrom: TKMHandID) of object;

  TKMActionResult = (arActContinues, arActDone, arActAborted); //

  TKMUnitArray = array of TKMUnit;

  TKMUnitAction = class
  protected
    fType: TKMUnitActionType;
    fUnit: TKMUnit;
    fOnActionDone: TAnonBooleanFn;
  public
    Locked: Boolean; //Means that unit can't take part in interaction, must stay on its tile
    StepDone: Boolean; //True when single action element is done (unit walked to new tile, single attack loop done)
    constructor Create(aUnit: TKMUnit; aActionType: TKMUnitActionType; aLocked: Boolean);
    constructor Load(LoadStream: TKMemoryStream); virtual;
    procedure SyncLoad; virtual;

    property OnActionDone: TAnonBooleanFn read fOnActionDone write fOnActionDone;
    function CanBeInterrupted(aForced: Boolean = True): Boolean; virtual;
    function ActName: TKMUnitActionName; virtual; abstract;
    property ActionType: TKMUnitActionType read fType;
    function GetExplanation: UnicodeString; virtual; abstract;
    function Execute: TKMActionResult; virtual; abstract;
    procedure Save(SaveStream: TKMemoryStream); virtual;
    procedure Paint; virtual;
  end;

  TKMTaskResult = (trTaskContinues, trTaskDone); //There's no difference between Done and Aborted

  TKMUnitTask = class
  protected
    fType: TKMUnitTaskType;
    fUnit: TKMUnit; //Unit who's performing the Task
    fPhase: Byte;
    fPhase2: Byte;
    procedure InitDefaultAction; virtual;
  public
    constructor Create(aUnit: TKMUnit);
    constructor Load(LoadStream: TKMemoryStream); virtual;
    procedure SyncLoad; virtual;
    destructor Destroy; override;

    property Phase: Byte read fPhase write fPhase;
    property TaskType: TKMUnitTaskType read fType;
    function WalkShouldAbandon: Boolean; dynamic;

    function CouldBeCancelled: Boolean; virtual;

    function ObjToString(aSeparator: String = ', '): String; virtual;

    function Execute: TKMTaskResult; virtual; abstract;
    procedure Save(SaveStream: TKMemoryStream); virtual;
  end;


  TKMUnit = class
  protected //Accessible for child classes
    fUID: Integer; //unique unit ID, used for save/load to sync to
    fType: TKMUnitType;
    fTask: TKMUnitTask;
    fAction: TKMUnitAction;
    fThought: TKMUnitThought;
    fHitPoints: Byte;
    fHitPointCounter: Cardinal; //Counter for hit point restoration, separate cos it resets on first hit
    fCondition: Integer; //Unit condition, when it reaches zero unit should die (rarely can be negative due to WalkExchange)
    fStartWDefaultCondition: Boolean; //For MapEditor only. Shows if this unit conditions will be set to default at the start of the game
    fTicker: Cardinal; //ticks of life for the unit (allows to spread updates)
    fOwner: TKMHandID;
    fHome: TKMHouse;
    fPositionF: TKMPointF;
    fVisible: Boolean;
    fIsDead: Boolean;
    fKillASAP: Boolean;
    fDismissASAP: Boolean;
    fKillASAPShowAnimation: Boolean;
    fPointerCount: Word;
    fInHouse: TKMHouse; //House we are currently in
    fCurrPosition: TKMPoint; //Where we are now
    fPrevPosition: TKMPoint; //Where we were
    fNextPosition: TKMPoint; //Where we will be. Next tile in route or same tile if stay on place
    fDirection: TKMDirection; //

    //No saved fields, used only in players UI
    fDismissInProgress: Boolean; //Mark unit as waiting for Dismiss GIC cmd, to show proper UI

    function GetDesiredPassability: TKMTerrainPassability;
    function GetHitPointsMax: Byte;
    procedure SetDirection(aValue: TKMDirection);
    procedure SetAction(aAction: TKMUnitAction; aStep: Integer = 0);
    procedure SetNextPosition(const aLoc: TKMPoint);
    procedure SetCurrPosition(const aLoc: TKMPoint);
    procedure SetCondition(aValue: Integer);
    function CanAccessHome: Boolean;
    procedure SetHome(aHome: TKMHouse);
    procedure SetOwner(aOwner: TKMHandID);

    procedure SetThought(aThought: TKMUnitThought);
    procedure SetInHouse(aInHouse: TKMHouse);
    procedure UpdateThoughts;
    function UpdateVisibility: Boolean;
    procedure UpdateHitPoints;
    procedure DoKill(aShowAnimation: Boolean);
    procedure DoDismiss;
  public
    AnimStep: Integer;
    IsExchanging: Boolean; //Current walk is an exchange, used for sliding
    OnUnitDied: TKMUnitFromEvent;
    OnUnitTrained: TKMUnitEvent;

    HitPointsInvulnerable: Boolean;
    Dismissable: Boolean; //Is it allowed to dismiss this unit ?

    constructor Create(aID: Cardinal; aUnitType: TKMUnitType; const aLoc: TKMPoint; aOwner: TKMHandID);
    constructor Load(LoadStream: TKMemoryStream); dynamic;
    procedure SyncLoad; virtual;
    destructor Destroy; override;

    function GetUnitPointer: TKMUnit; //Returns self and adds one to the pointer counter
    procedure ReleaseUnitPointer;  //Decreases the pointer counter
    property GetPointerCount: Word read fPointerCount;

    //Creates TTaskDie which then will Close the unit from further access
    procedure Kill(aFrom: TKMHandID; aShowAnimation, aForceDelay: Boolean); virtual;

    //Creates TTaskDismiss
    procedure Dismiss; virtual;
    procedure DismissCancel; virtual;
    //Could be used only in UI
    procedure DismissStarted;
    property DismissInProgress: Boolean read fDismissInProgress;

    procedure CloseUnit(aRemoveTileUsage: Boolean = True); dynamic;

    property UID: Integer read fUID;
    property CurrPosition: TKMPoint read fCurrPosition;
    property PositionF: TKMPointF read fPositionF write fPositionF;
    property PrevPosition: TKMPoint read fPrevPosition;
    property NextPosition: TKMPoint read fNextPosition write SetNextPosition;
    procedure SetPosition(aPos: TKMPoint);

    property Direction: TKMDirection read fDirection write SetDirection;
    property CurrentHitPoints: Byte read fHitPoints;

    function HitTest(X,Y: Integer; const UT: TKMUnitType = utAny): Boolean;

    procedure SetActionAbandonWalk(const aLocB: TKMPoint; aActionType: TKMUnitActionType = uaWalk);
    procedure SetActionGoIn(aAction: TKMUnitActionType; aGoDir: TKMGoInDirection; aHouse: TKMHouse); virtual;
    procedure SetActionStay(aTimeToStay: Integer; aAction: TKMUnitActionType; aStayStill: Boolean = True; aStillFrame: Byte = 0; aStep: Integer = 0);
    procedure SetActionStorm(aRow: Integer);
    procedure SetActionSteer;
    procedure SetActionLockedStay(aTimeToStay: Integer; aAction: TKMUnitActionType; aStayStill: Boolean=true; aStillFrame: Byte = 0; aStep: Integer=0);

    procedure SetActionWalk(const aLocB: TKMPoint; aActionType: TKMUnitActionType; aDistance:single; aTargetUnit: TKMUnit; aTargetHouse: TKMHouse);
    procedure SetActionWalkToHouse(aHouse: TKMHouse; aDistance: Single; aActionType: TKMUnitActionType = uaWalk);
    procedure SetActionWalkFromHouse(aHouse: TKMHouse; aDistance: Single; aActionType: TKMUnitActionType = uaWalk);
    procedure SetActionWalkToUnit(aUnit: TKMUnit; aDistance:single; aActionType: TKMUnitActionType = uaWalk);
    procedure SetActionWalkFromUnit(aUnit: TKMUnit; aDistance: Single; aActionType: TKMUnitActionType = uaWalk);
    procedure SetActionWalkToSpot(const aLocB: TKMPoint; aActionType: TKMUnitActionType = uaWalk; aDistance: Single = 0);
    procedure SetActionWalkToRoad(aActionType: TKMUnitActionType = uaWalk; aDistance: Single = 0;
                                         aTargetPassability: TKMTerrainPassability = tpWalkRoad; aTargetWalkConnectSet: TKMByteSet = []);
    procedure SetActionWalkPushed(const aLocB: TKMPoint; aActionType: TKMUnitActionType = uaWalk);

    procedure Feed(Amount: Single);
    function IsHungry: Boolean;
    procedure AbandonWalk;
    property  DesiredPassability: TKMTerrainPassability read GetDesiredPassability;
    property  Owner: TKMHandID read fOwner write SetOwner;

    property  Home: TKMHouse read fHome write SetHome;
    property  Action: TKMUnitAction read fAction;
    property  Task: TKMUnitTask read fTask;
    property  UnitType: TKMUnitType read fType;
    function  GetActionText: UnicodeString;
    property  Condition: Integer read fCondition write SetCondition;
    property  StartWDefaultCondition: Boolean read fStartWDefaultCondition write fStartWDefaultCondition;

    procedure OwnerUpdate(aOwner: TKMHandID; aMoveToNewOwner: Boolean = False);
    procedure HitPointsChangeFromScript(aAmount: Integer);
    procedure HitPointsDecrease(aAmount: Byte; aAttacker: TKMUnit);
    property  HitPointsMax: Byte read GetHitPointsMax;
    procedure CancelTask(aFreeTaskObject: Boolean = True);
    property  Visible: Boolean read fVisible write fVisible;
    property  InHouse: TKMHouse read fInHouse write SetInHouse;
    property  IsDead: Boolean read fIsDead;
    function  IsDeadOrDying: Boolean;
    function  IsDismissing: Boolean;
    function  IsDismissAvailable: Boolean;
    function  IsDismissCancelAvailable: Boolean;

    property  Thought: TKMUnitThought read fThought write SetThought;
    function  GetMovementVector: TKMPointF;
    function  IsIdle: Boolean;
    procedure TrainInHouse(aSchool: TKMHouseSchool);

    function CanStepTo(X,Y: Integer; aPass: TKMTerrainPassability): Boolean;
    function CanWalkTo(const aTo: TKMPoint; aDistance: Single): Boolean; overload;
    function CanWalkTo(const aTo: TKMPoint; aPass: TKMTerrainPassability; aDistance: Single): Boolean; overload;
    function CanWalkTo(const aFrom, aTo: TKMPoint; aDistance: Single): Boolean; overload;
    function CanWalkTo(const aFrom, aTo: TKMPoint; aPass: TKMTerrainPassability; aDistance: Single): Boolean; overload;
    function CanWalkTo(const aFrom: TKMPoint; aHouse: TKMHouse; aPass: TKMTerrainPassability; aDistance: Single): Boolean; overload;
    function CanWalkDiagonaly(const aFrom, aTo: TKMPoint): Boolean;
    procedure VertexRem(const aLoc: TKMPoint);
    function  VertexUsageCompatible(const aFrom, aTo: TKMPoint): Boolean;
    procedure VertexAdd(const aFrom, aTo: TKMPoint);
    procedure Walk(const aFrom, aTo: TKMPoint);
    function GetActivityText: UnicodeString; virtual;
    function GetSlide(aCheck: TKMCheckAxis): Single;
    function PathfindingShouldAvoid: Boolean; virtual;

    function ObjToString(aSeparator: String = '|'): String; virtual;
    function ObjToStringShort(aSeparator: String = '|'): String; virtual;

    procedure Save(SaveStream: TKMemoryStream); virtual;
    function UpdateState: Boolean; virtual;
    procedure Paint; virtual;

    class function GetDefaultCondition: Integer;
  end;

  //Common class for all civil units
  TKMCivilUnit = class(TKMUnit)
  public
    function GoEat(aInn: TKMHouseInn; aUnitAlreadyInsideInn: Boolean = False): Boolean;
    function CheckCondition: Boolean;
    procedure KillInHouse;
  end;

  //This is common class for all units, who can be an owner for house (recruits and all citizen workers)
  TKMSettledUnit = class(TKMCivilUnit)
  private
    procedure CleanHousePointer(aFreeAndNilTask: Boolean = False);
  protected
    function InitiateActivity: TKMUnitTask; virtual; abstract;
    function FindHome: Boolean;
    procedure ProceedHouseClosedForWorker;
  public
    function UpdateState: Boolean; override;
  end;

  //This is a common class for all units, who can work in house
  TKMUnitCitizen = class(TKMSettledUnit)
  private
    procedure IssueResourceDepletedMessage;
  protected
    function InitiateActivity: TKMUnitTask; override;
  public
    function CanWorkAt(aLoc: TKMPoint; aGatheringScript: TKMGatheringScript): Boolean;
    function GetActivityText: UnicodeString; override;
    procedure Paint; override;
  end;


  TKMUnitRecruit = class(TKMSettledUnit)
  protected
    function InitiateActivity: TKMUnitTask; override;
  public
    procedure Paint; override;
  end;

  //Serf - transports all wares between houses
  TKMUnitSerf = class(TKMCivilUnit)
  private
    fCarry: TKMWareType;
  public
    constructor Create(aID: Cardinal; aUnitType: TKMUnitType; const aLoc: TKMPoint; aOwner: TKMHandID);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure Save(SaveStream: TKMemoryStream); override;

    procedure Deliver(aFrom: TKMHouse; toHouse: TKMHouse; Res: TKMWareType; aID: integer); overload;
    procedure Deliver(aFrom: TKMHouse; toUnit: TKMUnit; Res: TKMWareType; aID: integer); overload;
    function TryDeliverFrom(aFrom: TKMHouse): Boolean;
    procedure DelegateDelivery(aToSerf: TKMUnitSerf);

    property Carry: TKMWareType read fCarry;
    procedure CarryGive(Res: TKMWareType);
    procedure CarryTake;

    function ObjToString(aSeparator: String = '|'): String; override;

    function UpdateState: Boolean; override;
    procedure Paint; override;
  end;

  //Worker class - builds everything in game
  TKMUnitWorker = class(TKMCivilUnit)
  public
    procedure BuildHouse(aHouse: TKMHouse; aIndex: Integer);
    procedure BuildHouseRepair(aHouse: TKMHouse; aIndex: Integer);
    procedure BuildField(aField: TKMFieldType; aLoc: TKMPoint; aIndex: Integer);
    procedure BuildHouseArea(aHouseType: TKMHouseType; aLoc: TKMPoint; aIndex: Integer);
    function PickRandomSpot(aList: TKMPointDirList; out Loc: TKMPointDir): Boolean;

    function UpdateState: Boolean; override;
    procedure Paint; override;
  end;


  //Animals
  TKMUnitAnimal = class(TKMUnit)
  private
    fFishCount: Byte; //1-5
  public
    constructor Create(aID: Cardinal; aUnitType: TKMUnitType; const aLoc: TKMPoint; aOwner: TKMHandID); overload;
    constructor Load(LoadStream: TKMemoryStream); override;
    property FishCount: byte read fFishCount;
    function ReduceFish: Boolean;
    procedure Save(SaveStream: TKMemoryStream); override;
    function UpdateState: Boolean; override;
    procedure Paint; override;
  end;


implementation
uses
  TypInfo,
  KM_Game, KM_GameApp, KM_RenderPool, KM_RenderAux, KM_ResTexts, KM_ScriptingEvents,
  KM_HandsCollection, KM_FogOfWar, KM_UnitWarrior, KM_Resource, KM_ResUnits,
  KM_Hand, KM_HouseWoodcutters,

  KM_UnitActionAbandonWalk,
  KM_UnitActionFight,
  KM_UnitActionGoInOut,
  KM_UnitActionStay,
  KM_UnitActionSteer,
  KM_UnitActionStormAttack,
  KM_UnitActionWalkTo,

  KM_UnitTaskAttackHouse,
  KM_UnitTaskBuild,
  KM_UnitTaskDelivery,
  KM_UnitTaskDie,
  KM_UnitTaskGoEat,
  KM_UnitTaskGoHome,
  KM_UnitTaskDismiss,
  KM_UnitTaskGoOutShowHungry,
  KM_UnitTaskMining,
  KM_UnitTaskSelfTrain,
  KM_UnitTaskThrowRock,
  KM_GameTypes,
  KM_Log;


{ TKMCivilUnit }
function TKMCivilUnit.CheckCondition: Boolean;
var
  H: TKMHouseInn;
begin
  Result := False;
  if IsHungry then
  begin
    H := gHands[fOwner].FindInn(fCurrPosition, Self, InHouse <> nil);
    Result := GoEat(H);
  end;
end;


procedure TKMCivilUnit.KillInHouse;
begin
  Assert(fInHouse <> nil, 'Unit could be silently killed only inside some House');
  //Dispose of current action/task BEFORE we close the unit (action might need to check fPosition if recruit was about to walk out to eat)
  //Normally this isn't required because TTaskDie takes care of it all, but recruits in barracks don't use TaskDie.
  SetAction(nil);
  FreeAndNil(fTask);

  CloseUnit(False); //Don't remove tile usage, we are inside the barracks
end;


function TKMCivilUnit.GoEat(aInn: TKMHouseInn; aUnitAlreadyInsideInn: Boolean = False): Boolean;
begin
  Result := False;
  if aInn <> nil then
  begin
    FreeAndNil(fTask);
    fTask := TKMTaskGoEat.Create(aInn, Self);
    if aUnitAlreadyInsideInn then
      fTask.Phase := 3; //We are inside Inn already
    Result := True;
  end;
end;


{ TKMSettledUnit }
//Find home for settled unit
function TKMSettledUnit.FindHome: Boolean;
var H: TKMHouse;
begin
  Result:=false;
  H := gHands[fOwner].Houses.FindEmptyHouse(fType, fCurrPosition);
  if H <> nil then
  begin
    fHome  := H.GetHousePointer;
    Result := true;
  end;
end;


procedure TKMSettledUnit.CleanHousePointer(aFreeAndNilTask: Boolean = False);
begin
  if aFreeAndNilTask then
    FreeAndNil(fTask);
  fHome.HasOwner := False;
  gHands.CleanUpHousePointer(fHome);
end;


// Manage house is closed for worker process
procedure TKMSettledUnit.ProceedHouseClosedForWorker;
var
  wGoingInsideHouse: Boolean;
  wThrowingRock: Boolean;
  wGoingForEating: Boolean;
  wWentOutShowHungry: Boolean;
  wWantToGoOutShowHungry: Boolean;
  wWalkingOutside: Boolean;
  wWorkingOutsideHouse: Boolean;
  wHasNoTask: Boolean;
  wIsInsideHouse: Boolean;
begin
  if (fHome <> nil)
    and not fHome.IsDestroyed
    and (fHome.IsClosedForWorker or ((fHome.HouseType = htBarracks) and (TKMHouseBarracks(fHome).NotAcceptRecruitFlag)))
    and not (fTask is TKMTaskDie)
    and not (fTask is TKMTaskDismiss) then
    begin
      wGoingInsideHouse := (fAction is TKMUnitActionGoInOut) and ((TKMUnitActionGoInOut(fAction)).Direction = gdGoInside);
      // let recruits finish throwing animation
      wThrowingRock := (fTask is TKMTaskThrowRock) and (fHome.GetState in [hstWork]);
      // do not cancel eating task
      wGoingForEating := (fTask is TKMTaskGoEat);
      // Assume worker is inside the house if not Visible.
      wIsInsideHouse := not Visible;
      // cancel GoOutShowHungry task if we outside of the house
      wWentOutShowHungry := (fTask is TKMTaskGoOutShowHungry) and not wIsInsideHouse;
      // cancel GoOutShowHungry task and go out of the house, if we inside of it
      wWantToGoOutShowHungry := (fTask is TKMTaskGoOutShowHungry) and wIsInsideHouse;
      // We are on the way to somewhere. AbandonWalk 'n cancel task.
      wWalkingOutside := (fAction is TKMUnitActionWalkTo) and not TKMUnitActionWalkTo(fAction).DoingExchange;
      // Working outside
      wWorkingOutsideHouse := (fTask is TKMTaskMining) and not wIsInsideHouse;
      // Somehow no task
      wHasNoTask := (fTask = nil);
      if (not wThrowingRock) then       // Let recruit finish rock throwing
        if (wGoingForEating) then
        begin
          CleanHousePointer;            // Clean house pointer, do not cancel eating task
        end else begin
          if (wWalkingOutside) then begin
            AbandonWalk;                // Stop walking
            CleanHousePointer(True);    // Clean house pointer and free task
          end else
          if not wGoingInsideHouse and  // Let worker get into the house
            ((wWentOutShowHungry or wWorkingOutsideHouse) // When already outside the house
            // Not sure we need this
            or (wHasNoTask and not wIsInsideHouse)) then  // Or has no task outside the house.
          begin
            CleanHousePointer(True);    // Clean house pointer and free task
          end else
          if (wIsInsideHouse or wWantToGoOutShowHungry)
            and not (fHome.HouseType = htBarracks) then // Recruits should not go out of Barracks
          begin
            SetActionGoIn(uaWalk, gdGoOutside, fHome); //Walk outside the house
            // If working inside - first we need to set house state to Idle, then to Empty
            fHome.SetState(hstIdle);
            fHome.SetState(hstEmpty);
            CleanHousePointer(True)     // Clean house pointer and free task
          end;
        end;
    end;
end;


function TKMSettledUnit.UpdateState: Boolean;
begin
  Result := True;
  if fAction = nil then
    raise ELocError.Create(gRes.Units[UnitType].GUIName + ' has no action at start of TKMSettledUnit.UpdateState', fCurrPosition);

  //Reset unit activity if home was destroyed, except when unit is dying or eating (finish eating/dying first)
  if (fHome <> nil)
    and fHome.IsDestroyed
    and not(fTask is TKMTaskDie)
    and not(fTask is TKMTaskGoEat) then
  begin
    if (fAction is TKMUnitActionWalkTo)
      and not TKMUnitActionWalkTo(Action).DoingExchange then
      AbandonWalk;
    FreeAndNil(fTask);
    gHands.CleanUpHousePointer(fHome);
  end;

  ProceedHouseClosedForWorker;

  if inherited UpdateState then Exit;
  if IsDead then Exit; //Caused by SelfTrain.Abandoned

  fThought := thNone;

  if IsHungry
    and not CheckCondition
    and (fHome <> nil)
    and not fVisible then
  begin
    if fTask <> nil then
      FreeAndNil(fTask);
    fTask := TKMTaskGoOutShowHungry.Create(Self);
  end;

  if fTask = nil then //If Unit still got nothing to do, nevermind hunger
    if fHome = nil then
      if FindHome then
        fTask := TKMTaskGoHome.Create(Self) //Home found - go there
      else begin
        fThought := thQuest; //Always show quest when idle, unlike serfs who randomly show it
        SetActionStay(20, uaWalk) //There's no home, but there will hopefully be one soon so don't sleep too long
      end
    else
      if fVisible then //Unit is not at home, but it has one
      begin
        if CanAccessHome then
          fTask := TKMTaskGoHome.Create(Self)
        else
          SetActionStay(60, uaWalk) //Home can't be reached
      end else begin

        if not (fHome.HouseType in HOUSE_WORKSHOP)
          or (fHome.CheckResOut(wtAll) < MAX_WARES_OUT_WORKSHOP) then //Do not do anything if we have too many ready resources
          fTask := InitiateActivity; //Unit is at home, so go get a job

        if fTask = nil then //We didn't find any job to do - rest at home
          SetActionStay(Max(gRes.Houses[fHome.HouseType].WorkerRest,1)*10, uaWalk); //By default it's 0, don't scan that often
      end;

  if fAction = nil then
    raise ELocError.Create(gRes.Units[UnitType].GUIName + ' has no action at end of TKMSettledUnit.UpdateState',fCurrPosition);

  Result := False;
end;


{ TKMUnitCitizen }
procedure TKMUnitCitizen.Paint;
var
  Act: TKMUnitActionType;
  XPaintPos, YPaintPos: Single;
  ID: Integer;
begin
  inherited;
  if not fVisible then exit;
  if fAction = nil then exit;
  Act := fAction.fType;

  XPaintPos := fPositionF.X + UNIT_OFF_X + GetSlide(axX);
  YPaintPos := fPositionF.Y + UNIT_OFF_Y + GetSlide(axY);

  ID := fUID * Byte(not (fAction.fType in [uaDie, uaEat]));

  case fAction.fType of
    uaWalk:
      begin
        gRenderPool.AddUnit(fType, ID, uaWalk, Direction, AnimStep, XPaintPos, YPaintPos, gHands[fOwner].GameFlagColor, true);
        if gRes.Units[fType].SupportsAction(uaWalkArm) then
          gRenderPool.AddUnit(fType, ID, uaWalkArm, Direction, AnimStep, XPaintPos, YPaintPos, gHands[fOwner].GameFlagColor, false);
      end;
    uaWork..uaEat:
        gRenderPool.AddUnit(fType, ID, Act, Direction, AnimStep, XPaintPos, YPaintPos, gHands[fOwner].GameFlagColor, true);
    uaWalkArm .. uaWalkBooty2:
      begin
        gRenderPool.AddUnit(fType, ID, uaWalk, Direction, AnimStep, XPaintPos, YPaintPos, gHands[fOwner].GameFlagColor, true);
        gRenderPool.AddUnit(fType, ID, Act, Direction, AnimStep, XPaintPos, YPaintPos, gHands[fOwner].GameFlagColor, false);
      end;
  end;

  if fThought <> thNone then
    gRenderPool.AddUnitThought(fType, Act, Direction, fThought, XPaintPos, YPaintPos);
end;


function TKMUnitCitizen.CanWorkAt(aLoc: TKMPoint; aGatheringScript: TKMGatheringScript): Boolean;
var
  I: Integer;
begin
  case aGatheringScript of
    gsWoodCutterPlant: begin
                          //Woodcutters should not plant trees on our own or our ally's house plans
                          //(it's very annoying if they do)
                          Result := True;
                          for I := 0 to gHands.Count - 1 do
                            if gHands[fOwner].Alliances[I] = atAlly then
                              Result := Result and not gHands[I].BuildList.HousePlanList.HasPlan(aLoc);
                        end;
    else Result := True;
  end;
end;


function TKMUnitCitizen.GetActivityText: UnicodeString;
begin
  Result := Inherited GetActivityText; //Default
  if fTask is TKMTaskMining then
    Result := TKMTaskMining(fTask).GetActivityText;
end;


procedure TKMUnitCitizen.IssueResourceDepletedMessage;
var
  Msg: Word;
begin
  case fHome.HouseType of
    htQuary:       Msg := TX_MSG_STONE_DEPLETED;
    htCoalMine:    Msg := TX_MSG_COAL_DEPLETED;
    htIronMine:    Msg := TX_MSG_IRON_DEPLETED;
    htGoldMine:    Msg := TX_MSG_GOLD_DEPLETED;
    htWoodcutters: if TKMHouseWoodcutters(fHome).WoodcutterMode = wcmPlant then
                      Msg := TX_MSG_WOODCUTTER_PLANT_DEPLETED
                    else
                      Msg := TX_MSG_WOODCUTTER_DEPLETED;
    htFisherHut:   if not gTerrain.CanFindFishingWater(fHome.PointBelowEntrance, gRes.Units[fType].MiningRange) then
                      Msg := TX_MSG_FISHERMAN_TOO_FAR
                    else
                      Msg := TX_MSG_FISHERMAN_CANNOT_CATCH;
    else            Msg := 0;
  end;

  Assert(Msg <> 0, gRes.Houses[fHome.HouseType].HouseName + ' resource cant possibly deplet');

  gGame.ShowMessage(mkHouse, Msg, fHome.Entrance, fOwner);
  fHome.ResourceDepletedMsgIssued := True;
end;


function TKMUnitCitizen.InitiateActivity: TKMUnitTask;
var
  Res: Integer;
  TM: TKMTaskMining;
begin
  Result := nil;

  if not KMSamePoint(fCurrPosition, fHome.Entrance) then
    raise ELocError.Create('Mining from wrong spot', fCurrPosition);

  Res := 1;
  //Check if House has production orders
  //Ask the house what order we should make
  if gRes.Houses[fHome.HouseType].DoesOrders then
  begin
    Res := fHome.PickOrder;
    if Res = 0 then Exit;
  end;

  // Don't bother creating a task if there's no room for resulting ware
  // Saves us time on Fishers/Stonecutters/Woodcutters when they calculate routes to nearby deposits
  // Other houses where workers walk out can choose between cut/plant
  if (fHome.HouseType in [htFisherHut, htQuary, htWineyard])
  and (fHome.CheckResOut(gRes.Houses[fHome.HouseType].ResOutput[Res]) >= MAX_WARES_IN_HOUSE) then
    Exit;

  TM := TKMTaskMining.Create(Self, gRes.Houses[fHome.HouseType].ResOutput[Res]);

  if TM.WorkPlan.ResourceDepleted and not fHome.ResourceDepletedMsgIssued then
    IssueResourceDepletedMessage;

  if TM.WorkPlan.IsIssued
    and ((TM.WorkPlan.Resource1 = wtNone) or (fHome.CheckResIn(TM.WorkPlan.Resource1) >= TM.WorkPlan.Count1))
    and ((TM.WorkPlan.Resource2 = wtNone) or (fHome.CheckResIn(TM.WorkPlan.Resource2) >= TM.WorkPlan.Count2))
    and (fHome.CheckResOut(TM.WorkPlan.Product1) < MAX_WARES_IN_HOUSE)
    and (fHome.CheckResOut(TM.WorkPlan.Product2) < MAX_WARES_IN_HOUSE) then
  begin
    //if fResource.HouseDat[fHome.HouseType].DoesOrders then
      //Take order to production
      //fHome.ResOrder[Res] := fHome.ResOrder[Res] - 1;
    Result := TM;
  end
  else
  begin
    TM.Free;
    Result := nil;
  end;
end;


{ TKMUnitRecruit }
procedure TKMUnitRecruit.Paint;
var
  Act: TKMUnitActionType;
  XPaintPos, YPaintPos: Single;
  ID: Integer;
begin
  inherited;
  if not fVisible then exit;
  if fAction = nil then exit;
  Act := fAction.fType;

  XPaintPos := fPositionF.X + UNIT_OFF_X + GetSlide(axX);
  YPaintPos := fPositionF.Y + UNIT_OFF_Y + GetSlide(axY);

  ID := fUID * Byte(not (fAction.fType in [uaDie, uaEat]));

  case fAction.fType of
    uaWalk:
      begin
        gRenderPool.AddUnit(fType, ID, uaWalk, Direction, AnimStep, XPaintPos, YPaintPos, gHands[fOwner].GameFlagColor, true);
        if gRes.Units[fType].SupportsAction(uaWalkArm) then
          gRenderPool.AddUnit(fType, ID, uaWalkArm, Direction, AnimStep, XPaintPos, YPaintPos, gHands[fOwner].GameFlagColor, false);
      end;
    uaWork..uaEat:
        gRenderPool.AddUnit(fType, ID, Act, Direction, AnimStep, XPaintPos, YPaintPos, gHands[fOwner].GameFlagColor, true);
    uaWalkArm .. uaWalkBooty2:
      begin
        gRenderPool.AddUnit(fType, ID, uaWalk, Direction, AnimStep, XPaintPos, YPaintPos, gHands[fOwner].GameFlagColor, true);
        gRenderPool.AddUnit(fType, ID, Act, Direction, AnimStep, XPaintPos, YPaintPos, gHands[fOwner].GameFlagColor, false);
      end;
  end;

  if fThought <> thNone then
    gRenderPool.AddUnitThought(fType, Act, Direction, fThought, XPaintPos, YPaintPos);
end;


function TKMUnitRecruit.InitiateActivity: TKMUnitTask;
var
  Enemy: TKMUnit;
begin
  Result := nil;

  //See if we are in a tower and have something to throw
  if not (fHome is TKMHouseTower) or (fHome.CheckResIn(wtStone) <= 0) then
    Exit;

  Enemy := gTerrain.UnitsHitTestWithinRad(fCurrPosition, RANGE_WATCHTOWER_MIN, RANGE_WATCHTOWER_MAX, fOwner, atEnemy, dirNA, not RANDOM_TARGETS);

  //Note: In actual game there might be two Towers nearby,
  //both throwing a stone into the same enemy. We should not
  //negate that fact, thats real-life situation.

  if Enemy <> nil then
    Result := TKMTaskThrowRock.Create(Self, Enemy);
end;


{ TKMSerf }
constructor TKMUnitSerf.Create(aID: Cardinal; aUnitType: TKMUnitType; const aLoc: TKMPoint; aOwner: TKMHandID);
begin
  inherited;
  fCarry := wtNone;
end;


procedure TKMUnitSerf.Deliver(aFrom, toHouse: TKMHouse; Res: TKMWareType; aID: integer);
begin
  fThought := thNone; //Clear ? thought
  fTask := TKMTaskDeliver.Create(Self, aFrom, toHouse, Res, aID);
end;


procedure TKMUnitSerf.Deliver(aFrom: TKMHouse; toUnit: TKMUnit; Res: TKMWareType; aID: integer);
begin
  fThought := thNone; //Clear ? thought
  fTask := TKMTaskDeliver.Create(Self, aFrom, toUnit, Res, aID);
end;


function TKMUnitSerf.TryDeliverFrom(aFrom: TKMHouse): Boolean;
var
  T: TKMUnitTask;
begin
  Result := False;
  //Save current task
  T := fTask;
  //Try to get a new one
  if gHands[Owner].Deliveries.Queue.AskForDelivery(Self, aFrom) then
  begin
    Result := True;
    FreeAndNil(T); //Destroy old task, we created a new one
  end;

  //If we got ourselves a new task then skip to resource-taking part, as we are already in this house
  if Result and (aFrom <> nil) then
    fTask.Phase := 2; //Skip  of the new task
end;


//Delegate delivery to other serf
procedure TKMUnitSerf.DelegateDelivery(aToSerf: TKMUnitSerf);
begin
  Assert(Task is TKMTaskDeliver, 'UnitTask is not TKMTaskDeliver');

  TKMTaskDeliver(Task).DelegateToOtherSerf(aToSerf); //Update task to be used with new serf
  aToSerf.fTask := Task; //Set delivery task to new serf

  //AbandonWalk if needed and cleanup task pointer, but do not free task object, as it was delegated to other serf already
  CancelTask(False);
end;


constructor TKMUnitSerf.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.Read(fCarry, SizeOf(fCarry));
end;


procedure TKMUnitSerf.Paint;
var
  Act: TKMUnitActionType;
  XPaintPos, YPaintPos: Single;
  ID: Integer;
begin
  inherited;
  if not fVisible then exit;
  if fAction = nil then exit;
  Act := fAction.fType;

  XPaintPos := fPositionF.X + UNIT_OFF_X + GetSlide(axX);
  YPaintPos := fPositionF.Y + UNIT_OFF_Y + GetSlide(axY);

  ID := fUID * Byte(not (fAction.fType in [uaDie, uaEat]));

  gRenderPool.AddUnit(UnitType, ID, Act, Direction, AnimStep, XPaintPos, YPaintPos, gHands[fOwner].GameFlagColor, true);

  if fTask is TKMTaskDie then Exit; //Do not show unnecessary arms

  if Carry <> wtNone then
    gRenderPool.AddUnitCarry(Carry, ID, Direction, AnimStep, XPaintPos, YPaintPos)
  else
    gRenderPool.AddUnit(UnitType, ID, uaWalkArm, Direction, AnimStep, XPaintPos, YPaintPos, gHands[fOwner].GameFlagColor, false);

  if fThought <> thNone then
    gRenderPool.AddUnitThought(fType, Act, Direction, fThought, XPaintPos, YPaintPos);
end;


procedure TKMUnitSerf.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fCarry, SizeOf(fCarry));
end;


function TKMUnitSerf.ObjToString(aSeparator: String = '|'): String;
begin
  Result := inherited ObjToString(aSeparator)
          + Format('%sCarry = %s', [aSeparator, GetEnumName(TypeInfo(TKMWareType), Integer(fCarry))]);
end;


function TKMUnitSerf.UpdateState: Boolean;
var
  OldThought: TKMUnitThought;
  WasIdle: Boolean;
begin
  Result := True; //Required for override compatibility
  WasIdle := IsIdle;
  if fAction = nil then raise ELocError.Create(gRes.Units[UnitType].GUIName+' has no action at start of TKMUnitSerf.UpdateState',fCurrPosition);
  if inherited UpdateState then
    Exit;

  OldThought := fThought;
  fThought := thNone;

  CheckCondition;

  //Only show quest thought if we have been idle since the last update (not HadTask)
  //and not thinking anything else (e.g. death)
  if fTask = nil then
  begin
    if WasIdle and (OldThought = thNone) and (KaMRandom(2, 'TKMUnitSerf.UpdateState') = 0) then
      fThought := thQuest;
    SetActionStay(60,uaWalk); //Stay idle
  end;

  if fAction = nil then
    raise ELocError.Create(gRes.Units[UnitType].GUIName+' has no action at end of TKMUnitSerf.UpdateState', fCurrPosition);
end;


procedure TKMUnitSerf.CarryGive(Res:TKMWareType);
begin
  Assert(fCarry = wtNone, 'Giving Serf another Carry');
  fCarry := Res;
end;


procedure TKMUnitSerf.CarryTake;
begin
  Assert(Carry <> wtNone, 'Taking wrong ware from Serf');
  fCarry := wtNone;
end;


{ TKMWorker }
procedure TKMUnitWorker.BuildHouse(aHouse: TKMHouse; aIndex: Integer);
begin
  fTask := TKMTaskBuildHouse.Create(Self, aHouse, aIndex);
end;


procedure TKMUnitWorker.BuildField(aField: TKMFieldType; aLoc: TKMPoint; aIndex: Integer);
begin
  case aField of
    ftRoad: fTask := TKMTaskBuildRoad.Create(Self, aLoc, aIndex);
    ftCorn: fTask := TKMTaskBuildField.Create(Self, aLoc, aIndex);
    ftWine: fTask := TKMTaskBuildWine.Create(Self, aLoc, aIndex);
  else
    raise Exception.Create('Unexpected TKMFieldType');
  end;
end;


procedure TKMUnitWorker.BuildHouseArea(aHouseType: TKMHouseType; aLoc: TKMPoint; aIndex: Integer);
begin
  fTask := TKMTaskBuildHouseArea.Create(Self, aHouseType, aLoc, aIndex);
end;


procedure TKMUnitWorker.BuildHouseRepair(aHouse: TKMHouse; aIndex: Integer);
begin
  fTask := TKMTaskBuildHouseRepair.Create(Self, aHouse, aIndex);
end;


//Given a list check the locations in it and pick those that can be walked to
//excluding current location. We assume that caller already made the list
//with only walkable valid tiles
function TKMUnitWorker.PickRandomSpot(aList: TKMPointDirList; out Loc: TKMPointDir): Boolean;
var
  I, MyCount: Integer;
  Spots: array of Word;
begin
  SetLength(Spots, aList.Count);

  //Scan the list and pick suitable locations
  MyCount := 0;
  for I := 0 to aList.Count - 1 do
  if not KMSamePoint(aList[I].Loc, CurrPosition)
  and CanWalkTo(aList[I].Loc, 0) then
  begin
    Spots[MyCount] := I;
    Inc(MyCount);
  end;

  Result := (MyCount > 0);
  if Result then
    Loc := aList[Spots[KaMRandom(MyCount, 'TKMUnitWorker.PickRandomSpot')]];
end;


procedure TKMUnitWorker.Paint;
var
  XPaintPos, YPaintPos: Single;
  ID: Integer;
begin
  inherited;
  if not fVisible then exit;
  if fAction = nil then exit;

  XPaintPos := fPositionF.X + UNIT_OFF_X + GetSlide(axX);
  YPaintPos := fPositionF.Y + UNIT_OFF_Y + GetSlide(axY);

  ID := fUID * Byte(not (fAction.fType in [uaDie, uaEat]));

  gRenderPool.AddUnit(UnitType, ID, fAction.fType, Direction, AnimStep, XPaintPos, YPaintPos, gHands[fOwner].GameFlagColor, true);

  if fThought <> thNone then
    gRenderPool.AddUnitThought(fType, fAction.ActionType, Direction, fThought, XPaintPos, YPaintPos);
end;


function TKMUnitWorker.UpdateState: Boolean;
begin
  Result := True; //Required for override compatibility
  if fAction = nil then
    raise ELocError.Create(gRes.Units[UnitType].GUIName + ' has no action at start of TKMUnitWorker.UpdateState', fCurrPosition);
  if inherited UpdateState then Exit;

  CheckCondition;

  if (fThought = thBuild) and (fTask = nil) then
    fThought := thNone; //Remove build thought if we are no longer doing anything

  //If we are still stuck on a house for some reason, get off it ASAP
  Assert(gTerrain.Land[fCurrPosition.Y, fCurrPosition.X].TileLock <> tlHouse);

  if (fTask = nil) and (fAction = nil) then SetActionStay(20, uaWalk);

  if fAction=nil then raise ELocError.Create(gRes.Units[UnitType].GUIName+' has no action at end of TKMUnitWorker.UpdateState',fCurrPosition);
end;


{ TKMUnitAnimal }
constructor TKMUnitAnimal.Create(aID: Cardinal; aUnitType: TKMUnitType; const aLoc: TKMPoint; aOwner: TKMHandID);
begin
  inherited;

  //Always start with 5 fish in the group
  if aUnitType = utFish then
    fFishCount := 5;
end;


constructor TKMUnitAnimal.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.Read(fFishCount);
end;


function TKMUnitAnimal.ReduceFish: Boolean;
begin
  Result := fType = utFish;
  if not Result then Exit;

  if fFishCount > 1 then
    Dec(fFishCount)
  else
    Kill(PLAYER_NONE, True, False);
end;


procedure TKMUnitAnimal.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fFishCount);
end;


function TKMUnitAnimal.UpdateState: Boolean;
begin
  Result := True; //Required for override compatibility

  SetCurrPosition(KMPointRound(fPositionF));

  if fAction = nil then
    raise ELocError.Create(gRes.Units[UnitType].GUIName + ' has no action at start of TKMUnitAnimal.UpdateState', fCurrPosition);

  if fKillASAP then
  begin
    DoKill(fKillASAPShowAnimation);
    fKillASAP := False;
    Exit;
  end;

  case fAction.Execute of
    arActContinues: exit;
    arActDone:      FreeAndNil(fAction);
    arActAborted:   FreeAndNil(fAction);
  end;
  SetCurrPosition(KMPointRound(fPositionF));


  Assert((fTask = nil) or (fTask is TKMTaskDie));
  if fTask is TKMTaskDie then
  case fTask.Execute of
    trTaskContinues:  exit;
    trTaskDone:       raise Exception.Create('Unexpected fUnitTask.Execute value = trTaskDone'); //TTaskDie never returns trTaskDone yet
  end;

  //First make sure the animal isn't stuck (check passibility of our position)
  if (not gTerrain.CheckPassability(fCurrPosition, DesiredPassability))
  or gTerrain.CheckAnimalIsStuck(fCurrPosition, DesiredPassability) then
  begin
    Kill(PLAYER_NONE, True, False); //Animal is stuck so it dies
    Exit;
  end;

  SetActionSteer;

  if fAction = nil then
    raise ELocError.Create(gRes.Units[UnitType].GUIName + ' has no action at end of TKMUnitAnimal.UpdateState', fCurrPosition);
end;


//For fish the action is the number of fish in the group
procedure TKMUnitAnimal.Paint;
var
  Act: TKMUnitActionType;
  XPaintPos, YPaintPos: single;
begin
  inherited;
  if fAction = nil then exit;
  if fType = utFish then
    Act := FishCountAct[fFishCount]
  else
    Act := fAction.fType;

  XPaintPos := fPositionF.X + UNIT_OFF_X + GetSlide(axX);
  YPaintPos := fPositionF.Y + UNIT_OFF_Y + GetSlide(axY);

  //Make fish/watersnakes more visible in the MapEd
  if (gGame.GameMode = gmMapEd) and (fType in [utFish, utWatersnake, utSeastar]) then
    gRenderAux.Circle(fPositionF.X - 0.5,
                      gTerrain.FlatToHeight(fPositionF.X - 0.5, fPositionF.Y - 0.5),
                      0.5, $30FF8000, $60FF8000);

  //Animals share the same WalkTo logic as other units and they exchange places if necessary
  //Animals can be picked only in MapEd
  gRenderPool.AddUnit(fType, fUID * Byte(gGame.IsMapEditor), Act, Direction, AnimStep, XPaintPos, YPaintPos, $FFFFFFFF, True);
end;


{ TKMUnit }
constructor TKMUnit.Create(aID: Cardinal; aUnitType: TKMUnitType; const aLoc: TKMPoint; aOwner: TKMHandID);
begin
  inherited Create;

  fUID          := aID;
  fTicker       := fUID; //Units update states will be spread more evenly that way
  fPointerCount := 0;
  fIsDead       := false;
  fKillASAP     := false;
  fThought      := thNone;
  fHome         := nil;
  fInHouse      := nil;
  fPositionF     := KMPointF(aLoc);
  fCurrPosition := aLoc;
  fPrevPosition := aLoc; //Init values
  fNextPosition := aLoc; //Init values
  fOwner        := aOwner;
  fType     := aUnitType;
  fDirection    := dirS;
  fVisible      := True;
  IsExchanging  := False;
  AnimStep      := UnitStillFrames[fDirection]; //Use still frame at begining, so units don't all change frame on first tick
  Dismissable   := True;

  //Units start with a random amount of condition ranging from 0.5 to 0.7 (KaM uses 0.6 for all units)
  //By adding the random amount they won't all go eat at the same time and cause crowding, blockages, food shortages and other problems.
  if (gGame <> nil) and (gGame.GameMode <> gmMapEd) then
    fCondition    := Round(UNIT_MAX_CONDITION * (UNIT_CONDITION_BASE + KaMRandomS(UNIT_CONDITION_RANDOM, 'TKMUnit.Create')))
  else begin
    fCondition    := GetDefaultCondition;
    fStartWDefaultCondition := True;
  end;

  fHitPoints      := HitPointsMax;
  fHitPointCounter := 1;
  HitPointsInvulnerable := False;

  SetActionLockedStay(10, uaWalk); //Must be locked for this initial pause so animals don't get pushed
  gTerrain.UnitAdd(NextPosition,Self);

  //The area around the unit should be visible at the start of the mission
  if InRange(fOwner, 0, MAX_HANDS - 1) then //Not animals
    gHands.RevealForTeam(fOwner, fCurrPosition, gRes.Units[fType].Sight, FOG_OF_WAR_MAX);
end;


destructor TKMUnit.Destroy;
begin
  if not IsDead then gTerrain.UnitRem(NextPosition); //Happens only when removing player from map on GameStart (network)
  FreeAndNil(fAction);
  FreeAndNil(fTask);
  SetInHouse(nil); //Free pointer
  inherited;
end;


constructor TKMUnit.Load(LoadStream: TKMemoryStream);
var
  HasTask, HasAct: Boolean;
  TaskName: TKMUnitTaskType;
  ActName: TKMUnitActionName;
begin
  inherited Create;
  LoadStream.Read(fType, SizeOf(fType));
  LoadStream.Read(HasTask);
  if HasTask then
  begin
    LoadStream.Read(TaskName, SizeOf(TaskName));
    case TaskName of
      uttUnknown:         raise Exception.Create('TaskName can''t be handled');
      uttSelfTrain:       fTask := TKMTaskSelfTrain.Load(LoadStream);
      uttDeliver:         fTask := TKMTaskDeliver.Load(LoadStream);
      uttBuildRoad:       fTask := TKMTaskBuildRoad.Load(LoadStream);
      uttBuildWine:       fTask := TKMTaskBuildWine.Load(LoadStream);
      uttBuildField:      fTask := TKMTaskBuildField.Load(LoadStream);
      uttBuildHouseArea:  fTask := TKMTaskBuildHouseArea.Load(LoadStream);
      uttBuildHouse:      fTask := TKMTaskBuildHouse.Load(LoadStream);
      uttBuildHouseRepair:fTask := TKMTaskBuildHouseRepair.Load(LoadStream);
      uttGoHome:          fTask := TKMTaskGoHome.Load(LoadStream);
      uttDismiss:         fTask := TKMTaskDismiss.Load(LoadStream);
      uttAttackHouse:     fTask := TKMTaskAttackHouse.Load(LoadStream);
      uttThrowRock:       fTask := TKMTaskThrowRock.Load(LoadStream);
      uttGoEat:           fTask := TKMTaskGoEat.Load(LoadStream);
      uttMining:          fTask := TKMTaskMining.Load(LoadStream);
      uttDie:             fTask := TKMTaskDie.Load(LoadStream);
      uttGoOutShowHungry: fTask := TKMTaskGoOutShowHungry.Load(LoadStream);
    else
      raise Exception.Create('TaskName can''t be handled');
    end;
  end
  else
    fTask := nil;

  LoadStream.Read(HasAct);
  if HasAct then
  begin
    LoadStream.Read(ActName, SizeOf(ActName));
    case ActName of
      uanStay:        fAction := TKMUnitActionStay.Load(LoadStream);
      uanWalkTo:      fAction := TKMUnitActionWalkTo.Load(LoadStream);
      uanAbandonWalk: fAction := TKMUnitActionAbandonWalk.Load(LoadStream);
      uanGoInOut:     fAction := TKMUnitActionGoInOut.Load(LoadStream);
      uanFight:       fAction := TKMUnitActionFight.Load(LoadStream);
      uanStormAttack: fAction := TKMUnitActionStormAttack.Load(LoadStream);
      uanSteer:       fAction := TKMUnitActionSteer.Load(LoadStream);
    else
      raise Exception.Create('ActName can''t be handled');
    end;
  end
  else
    fAction := nil;

  LoadStream.Read(fThought, SizeOf(fThought));
  LoadStream.Read(fCondition);
  LoadStream.Read(fStartWDefaultCondition);
  LoadStream.Read(fTicker);
  LoadStream.Read(fHitPoints);
  LoadStream.Read(fHitPointCounter);
  LoadStream.Read(HitPointsInvulnerable);
  LoadStream.Read(fInHouse, 4);
  LoadStream.Read(fOwner, SizeOf(fOwner));
  LoadStream.Read(fHome, 4); //Substitute it with reference on SyncLoad
  LoadStream.Read(fPositionF);
  LoadStream.Read(fVisible);
  LoadStream.Read(fIsDead);
  LoadStream.Read(fKillASAP);
  LoadStream.Read(fKillASAPShowAnimation);
  LoadStream.Read(IsExchanging);
  LoadStream.Read(fPointerCount);
  LoadStream.Read(fUID);
  LoadStream.Read(AnimStep);
  LoadStream.Read(fDirection);
  LoadStream.Read(fCurrPosition);
  LoadStream.Read(fPrevPosition);
  LoadStream.Read(fNextPosition);
  LoadStream.Read(fDismissASAP);
  LoadStream.Read(Dismissable);
end;


procedure TKMUnit.SyncLoad;
begin
  if fTask <> nil then
    fTask.SyncLoad;

  if fAction <> nil then
    fAction.SyncLoad;

  fHome := gHands.GetHouseByUID(cardinal(fHome));
  fInHouse := gHands.GetHouseByUID(cardinal(fInHouse));
end;


procedure TKMUnit.TrainInHouse(aSchool: TKMHouseSchool);
begin
  fTask := TKMTaskSelfTrain.Create(Self, aSchool);
end;


// Returns self and adds on to the pointer counter
function TKMUnit.GetUnitPointer: TKMUnit;
begin
  Assert(gGame.AllowGetPointer, 'GetUnitPointer is not allowed outside of game tick update procedure, it could cause game desync');

  Inc(fPointerCount);
  Result := Self;
end;


{Decreases the pointer counter}
//Should be used only by gHands for clarity sake
procedure TKMUnit.ReleaseUnitPointer;
begin
  Assert(gGame.AllowGetPointer, 'GetUnitPointer is not allowed outside of game tick update procedure, it could cause game desync');

  if fPointerCount < 1 then
    raise ELocError.Create('Unit remove pointer', PrevPosition);
  Dec(fPointerCount);
end;


// Erase everything related to unit status to exclude it from being accessed by anything but the old pointers
procedure TKMUnit.CloseUnit(aRemoveTileUsage: Boolean = True);
begin
  if fHome <> nil then
  begin
    fHome.HasOwner := False;
    gHands.CleanUpHousePointer(fHome);
  end;

  if aRemoveTileUsage then
    gTerrain.UnitRem(fNextPosition); //Must happen before we nil NextPosition

  fIsDead       := True;
  fThought      := thNone;
  fPositionF     := KMPOINTF_ZERO;
  fCurrPosition := KMPOINT_ZERO;
  fPrevPosition := fCurrPosition;
  fNextPosition := fCurrPosition;
  fOwner        := PLAYER_NONE;
  //Do not reset the unit type when they die as we still need to know during Load
  //fUnitType     := utNone;
  fDirection    := dirNA;
  fVisible      := False;
  fCondition    := 0;
  AnimStep      := 0;
  FreeAndNil(fAction);
  FreeAndNil(fTask);

  Assert(gMySpectator.Selected <> Self,
    'Removed units should be flushed from UI earlier in TaskDie or never appear there when training cancelled or alike');
end;


procedure TKMUnit.DismissStarted;
begin
  fDismissInProgress := True;
end;


procedure TKMUnit.Dismiss;
begin
  if not Dismissable or IsDeadOrDying then
    Exit;

  fDismissInProgress := False;

  if (fAction is TKMUnitActionWalkTo) and TKMUnitActionWalkTo(fAction).DoingExchange then
  begin
    fDismissASAP := True; //Unit will be dismissed ASAP, when unit is ready for it
    Exit;
  end;

  DoDismiss;
end;


procedure TKMUnit.DismissCancel;
begin
  fDismissInProgress := False; //remove fDismissInProgress mark, which is used only in UI

  if not IsDismissing then Exit;

  fThought := thNone; //Reset thought
  fDismissASAP := False;

  if (fAction is TKMUnitActionWalkTo)
    and not TKMUnitActionWalkTo(fAction).DoingExchange then
  begin
    AbandonWalk;
  end else
  if fAction.CanBeInterrupted then
  begin
    SetActionLockedStay(0, uaWalk);
    if fTask = nil then
      SetActionStay(5, uaWalk);
  end;

  if fTask <> nil then
    FreeAndNil(fTask);
end;


procedure TKMUnit.DoDismiss;

  procedure TryCreateDismissTask;
  begin
    FreeAndNil(fTask);
    fTask := TKMTaskDismiss.Create(Self); //Will create empty locked stay action
    if TKMTaskDismiss(fTask).ShouldBeCancelled then
      FreeAndNil(fTask);
  end;

begin
  //We can update existing Walk action with minimum changes
  if (fAction is TKMUnitActionWalkTo)
    and not TKMUnitActionWalkTo(fAction).DoingExchange then
  begin
    AbandonWalk;
    TryCreateDismissTask;
  end else
  if fAction.CanBeInterrupted then
  begin
    SetActionLockedStay(0, uaWalk);
    TryCreateDismissTask;
    if fTask = nil then
      SetActionStay(5, uaWalk);
  end else
    fDismissASAP := True; // Delay Dismiss for 1 more tick, until action interrupt could be possible
end;


{Call this procedure to properly kill a unit. ForceDelay means we always use KillASAP}
//killing a unit is done in 3 steps
// Kill - release all unit-specific tasks
// TTaskDie - perform dying animation
// CloseUnit - erase all unit data and hide it from further access
procedure TKMUnit.Kill(aFrom: TKMHandID; aShowAnimation, aForceDelay: Boolean);
begin
  //Don't kill unit if it's already dying
  if IsDeadOrDying then
    Exit;

  // Don't allow to kill invulnerable units (by any means)
  if HitPointsInvulnerable then
    Exit;

  //From this moment onwards the unit is guaranteed to die (no way to avoid it even with KillASAP), so
  //signal to our owner that we have died (doesn't have to be assigned since f.e. animals don't use it)
  //This must be called before actually killing the unit because gScriptEvets needs to access it
  //and script is not allowed to touch dead/dying/KillASAP units
  if Assigned(OnUnitDied) then
    OnUnitDied(Self, aFrom);

  // Wait till units exchange (1 tick) and then do the killing
  if aForceDelay
    or ((fAction is TKMUnitActionWalkTo) and TKMUnitActionWalkTo(fAction).DoingExchange) then
  begin
    fKillASAP := True; //Unit will be killed ASAP, when unit is ready for it
    fKillASAPShowAnimation := aShowAnimation;
    Exit;
  end;

  // If we didn't exit above, we are safe to do the kill now (no delay from KillASAP required)
  DoKill(aShowAnimation);
end;


procedure TKMUnit.DoKill(aShowAnimation: Boolean);
begin
  fThought := thNone; //Reset thought
  SetAction(nil); //Dispose of current action (TTaskDie will set it to LockedStay)
  FreeAndNil(fTask); //Should be overriden to dispose of Task-specific items
  fTask := TKMTaskDie.Create(Self, aShowAnimation);
end;


procedure TKMUnit.SetOwner(aOwner: TKMHandID);
begin
  fOwner := aOwner;
end;


procedure TKMUnit.OwnerUpdate(aOwner: TKMHandID; aMoveToNewOwner: Boolean = False);
begin
  if aMoveToNewOwner and (fOwner <> aOwner) then
  begin
    Assert(gGame.GameMode = gmMapEd); // Allow to move existing Unit directly only in MapEd
    gHands[fOwner].Units.DeleteUnitFromList(Self);
    gHands[aOwner].Units.AddUnitToList(Self);
  end;
  fOwner := aOwner;
end;


procedure TKMUnit.SetPosition(aPos: TKMPoint);
begin
  //This is only used by the map editor, set all positions to aPos
  Assert(gGame.GameMode = gmMapEd);
  if not gTerrain.CanPlaceUnit(aPos, UnitType) then Exit;

  gTerrain.UnitRem(fCurrPosition);
  fCurrPosition := aPos;
  fNextPosition := aPos;
  fPrevPosition := aPos;
  fPositionF := KMPointF(aPos);
  gTerrain.UnitAdd(fCurrPosition, Self);
end;


function TKMUnit.CanAccessHome: Boolean;
begin
  Result := (fHome = nil) or CanWalkTo(fHome.PointBelowEntrance, tpWalk, 0);
end;


function TKMUnit.GetActionText: UnicodeString;
begin
  Result := fAction.GetExplanation;
end;


procedure TKMUnit.HitPointsDecrease(aAmount: Byte; aAttacker: TKMUnit);
begin
  Assert(aAmount > 0, '0 damage should be handled outside so not to reset HPCounter');

  //When we are first hit reset the counter
  if fHitPoints = HitPointsMax then
    fHitPointCounter := 1;

  fHitPoints := Max(fHitPoints - aAmount, 0);

  gHands[Owner].AI.UnitHPDecreaseNotification(Self, aAttacker);

  //Make sure to kill only once
  if (fHitPoints = 0) and not IsDeadOrDying then
    if aAttacker <> nil then
      Kill(aAttacker.Owner, True, False)
    else
      Kill(PLAYER_NONE, True, False)
end;


procedure TKMUnit.HitPointsChangeFromScript(aAmount: Integer);
begin
  fHitPoints := EnsureRange(fHitPoints + aAmount, 0, GetHitPointsMax);
  if (fHitPoints = 0)
  and (not IsDeadOrDying) then
    Kill(PLAYER_NONE, True, False);
end;


function TKMUnit.GetHitPointsMax: Byte;
begin
  Result := gRes.Units[fType].HitPoints;
end;


procedure TKMUnit.CancelTask(aFreeTaskObject: Boolean = True);
begin
  if (fTask <> nil)
    and (fAction is TKMUnitActionWalkTo)
    and not TKMUnitActionWalkTo(Action).DoingExchange then
    AbandonWalk;
  if aFreeTaskObject then
    FreeAndNil(fTask)
  else
    fTask := nil;
end;


procedure TKMUnit.SetThought(aThought: TKMUnitThought);
begin
  fThought := aThought;
end;


procedure TKMUnit.SetInHouse(aInHouse: TKMHouse);
begin
  gHands.CleanUpHousePointer(fInHouse);
  if aInHouse <> nil then
    fInHouse := aInHouse.GetHousePointer;
end;


function TKMUnit.HitTest(X,Y: Integer; const UT:TKMUnitType = utAny): Boolean;
begin
  Result := (X = fCurrPosition.X) and //Comparing X,Y to CurrentPosition separately, cos they can be negative numbers
            (Y = fCurrPosition.Y) and
            ((fType = UT) or (UT = utAny));
end;


//As long as we only ever set PrevPos to NextPos and do so everytime before NextPos changes,
//there can be no problems (as were occurring in GetSlide)
//This procedure ensures that these values always get updated correctly so we don't get a problem
//where GetLength(PrevPosition,NextPosition) > sqrt(2)
procedure TKMUnit.SetNextPosition(const aLoc: TKMPoint);
begin
  fPrevPosition := NextPosition;
  fNextPosition := aLoc;
end;


procedure TKMUnit.SetCurrPosition(const aLoc: TKMPoint);
begin
  if {not gGameApp.DynamicFOWEnabled
    and }(fOwner <> PLAYER_ANIMAL)
    and (fCurrPosition <> aLoc) then  //Update FOW only for new loc
    gHands.RevealForTeam(fOwner, aLoc, gRes.Units[fType].Sight, FOG_OF_WAR_MAX);

  fCurrPosition := aLoc;
end;


//Only ClearUnit can set fDirection to NA, no other circumstances it is allowed
procedure TKMUnit.SetDirection(aValue: TKMDirection);
begin
  Assert(aValue <> dirNA);
  fDirection := aValue;

  //if fCurrentAction is TUnitActionStay then
  //  AnimStep := UnitStillFrames[fDirection];
end;


//Assign the following Action to unit and set AnimStep
procedure TKMUnit.SetAction(aAction: TKMUnitAction; aStep: Integer = 0);
begin
  AnimStep := aStep;
  if aAction = nil then
  begin
    FreeAndNil(fAction);
    Exit;
  end;
  if not gRes.Units[fType].SupportsAction(aAction.ActionType) then
  begin
    FreeAndNil(aAction);
    raise Exception.Create('Unit ' + gRes.Units[UnitType].GUIName + ' was asked to do unsupported action');
  end;
  if fAction <> aAction then
  begin
    fAction.Free;
    fAction := aAction;
  end;
end;


procedure TKMUnit.SetActionGoIn(aAction: TKMUnitActionType; aGoDir: TKMGoInDirection; aHouse: TKMHouse);
begin
  SetAction(TKMUnitActionGoInOut.Create(Self, aAction, aGoDir, aHouse));
end;


procedure TKMUnit.SetActionStay(aTimeToStay: Integer; aAction: TKMUnitActionType; aStayStill: Boolean = True; aStillFrame: Byte = 0; aStep: Integer = 0);
begin
  //When standing still in walk, use default frame
  if (aAction = uaWalk) and aStayStill then
  begin
    aStillFrame := UnitStillFrames[Direction];
    aStep := UnitStillFrames[Direction];
  end;
  SetAction(TKMUnitActionStay.Create(Self, aTimeToStay, aAction, aStayStill, aStillFrame, False), aStep);
end;


procedure TKMUnit.SetActionStorm(aRow: Integer);
begin
  SetAction(TKMUnitActionStormAttack.Create(Self, uaWalk, aRow), 0); //Action is uaWalk for that is the inital one
end;


procedure TKMUnit.SetActionSteer;
begin
  SetAction(TKMUnitActionSteer.Create(Self, uaWalk, True), 0);
end;


//Same as above but we will ignore get-out-of-the-way (push) requests from interaction system
procedure TKMUnit.SetActionLockedStay(aTimeToStay: Integer; aAction: TKMUnitActionType; aStayStill: Boolean = True;
                                      aStillFrame: Byte = 0; aStep: Integer = 0);
begin
  //When standing still in walk, use default frame
  if (aAction = uaWalk) and aStayStill then
  begin
    aStillFrame := UnitStillFrames[Direction];
    aStep := UnitStillFrames[Direction];
  end;
  SetAction(TKMUnitActionStay.Create(Self, aTimeToStay, aAction, aStayStill, aStillFrame, True), aStep);
end;


//WalkTo action with exact options (retranslated from WalkTo if Obstcale met)
procedure TKMUnit.SetActionWalk(const aLocB: TKMPoint; aActionType: TKMUnitActionType; aDistance: Single; aTargetUnit: TKMUnit; aTargetHouse: TKMHouse);
begin
  if (Action is TKMUnitActionWalkTo) and not TKMUnitActionWalkTo(Action).CanAbandonExternal then
    raise Exception.Create('');
  SetAction(TKMUnitActionWalkTo.Create(Self, aLocB, aActionType, aDistance, false, aTargetUnit, aTargetHouse));
end;


//Approach house
procedure TKMUnit.SetActionWalkToHouse(aHouse: TKMHouse; aDistance: Single; aActionType: TKMUnitActionType = uaWalk);
begin
  if (Action is TKMUnitActionWalkTo) and not TKMUnitActionWalkTo(Action).CanAbandonExternal then
    raise Exception.Create('');

  SetAction(TKMUnitActionWalkTo.Create( Self,               //Who's walking
                                      //Target position is the closest cell to our current position (only used for estimating in path finding)
                                      aHouse.GetClosestCell(Self.CurrPosition),
                                      aActionType,        //
                                      aDistance,          //Proximity
                                      false,              //If we were pushed
                                      nil,                //Unit
                                      aHouse              //House
                                      ));
end;


procedure TKMUnit.SetActionWalkFromHouse(aHouse: TKMHouse; aDistance: Single; aActionType: TKMUnitActionType = uaWalk);
begin
  if (Action is TKMUnitActionWalkTo) and not TKMUnitActionWalkTo(Action).CanAbandonExternal then
    raise Exception.Create('');

  //todo: Make unit walk away from House
  SetActionStay(20, aActionType);
end;


//Approach unit
procedure TKMUnit.SetActionWalkToUnit(aUnit: TKMUnit; aDistance: Single; aActionType: TKMUnitActionType = uaWalk);
begin
  if (Action is TKMUnitActionWalkTo) and not TKMUnitActionWalkTo(Action).CanAbandonExternal then
   raise Exception.Create('');

  Assert(aDistance >= 1, 'Should not walk to units place');
  SetAction(TKMUnitActionWalkTo.Create( Self,               //Who's walking
                                      aUnit.fCurrPosition,//Target position
                                      aActionType,        //
                                      aDistance,          //Proximity
                                      False,              //If we were pushed
                                      aUnit,              //Unit
                                      nil                 //House
                                      ));
end;


procedure TKMUnit.SetCondition(aValue: Integer);
begin
  fCondition := EnsureRange(aValue, 0, UNIT_MAX_CONDITION);
end;


procedure TKMUnit.SetActionWalkFromUnit(aUnit: TKMUnit; aDistance: Single; aActionType: TKMUnitActionType = uaWalk);
begin
  if (Action is TKMUnitActionWalkTo) and not TKMUnitActionWalkTo(Action).CanAbandonExternal then
    raise Exception.Create('');

  //todo: Make unit walk away from Unit
  SetActionStay(20, aActionType);
end;


//Walk to spot or its neighbourhood
procedure TKMUnit.SetActionWalkToSpot(const aLocB: TKMPoint; aActionType: TKMUnitActionType = uaWalk; aDistance: Single = 0);
begin
  if (Action is TKMUnitActionWalkTo) and not TKMUnitActionWalkTo(Action).CanAbandonExternal then
    raise Exception.Create('Interrupting unabandonable Walk action');

  SetAction(TKMUnitActionWalkTo.Create(Self, aLocB, aActionType, aDistance, False, nil, nil));
end;


procedure TKMUnit.SetActionWalkToRoad(aActionType: TKMUnitActionType = uaWalk; aDistance: Single = 0;
                                             aTargetPassability: TKMTerrainPassability = tpWalkRoad; aTargetWalkConnectSet: TKMByteSet = []);
begin
  if (Action is TKMUnitActionWalkTo) and not TKMUnitActionWalkTo(Action).CanAbandonExternal then
    raise Exception.Create('Interrupting unabandonable Walk action');

  SetAction(TKMUnitActionWalkTo.Create(Self, KMPOINT_INVALID_TILE, aActionType, aDistance, False, nil, nil,
                                       aTargetPassability, aTargetWalkConnectSet));
end;


//We were pushed (walk to spot with wider Passability)
procedure TKMUnit.SetActionWalkPushed(const aLocB: TKMPoint; aActionType: TKMUnitActionType = uaWalk);
begin
  //1. Only idle units can be pushed, for they are low priority to busy units
  //2. If unit can't get away it will re-push itself once again
  Assert(((Action is TKMUnitActionStay) and (not Action.Locked)) or
         ((Action is TKMUnitActionWalkTo) and TKMUnitActionWalkTo(Action).CanAbandonExternal));

  SetAction(TKMUnitActionWalkTo.Create(Self, aLocB, aActionType, 0, True, nil, nil));
  //Once pushed, unit will try to walk away, if he bumps into more units he will
  //
end;


procedure TKMUnit.SetActionAbandonWalk(const aLocB: TKMPoint; aActionType: TKMUnitActionType = uaWalk);
var
  TempVertexOccupied: TKMPoint;
begin
  if Action is TKMUnitActionWalkTo then
  begin
    TempVertexOccupied := TKMUnitActionWalkTo(Action).fVertexOccupied;
    TKMUnitActionWalkTo(Action).fVertexOccupied := KMPOINT_ZERO; //So it doesn't try to DecVertex on destroy (now it's AbandonWalk's responsibility)
  end
  else
    TempVertexOccupied := KMPOINT_ZERO;

  SetAction(TKMUnitActionAbandonWalk.Create(Self, aLocB, TempVertexOccupied, aActionType), AnimStep); //Use the current animation step, to ensure smooth transition
end;


procedure TKMUnit.AbandonWalk;
begin
  if Action is TKMUnitActionWalkTo then
    SetActionAbandonWalk(NextPosition, uaWalk)
  else
    SetActionLockedStay(0, uaWalk); //Error
end;


//Used by barracks when creating a recruit inside
procedure TKMUnit.SetHome(aHome: TKMHouse);
begin
  gHands.CleanUpHousePointer(fHome);
  fHome := aHome.GetHousePointer;
end;


//Specific unit desired passability may depend on several factors
function TKMUnit.GetDesiredPassability: TKMTerrainPassability;
begin
  Result := gRes.Units[fType].DesiredPassability;

  //Delivery to unit
  if (fType = utSerf)
  and (fTask is TKMTaskDeliver)
  and (TKMTaskDeliver(fTask).DeliverKind = dkToUnit)
  then
    Result := tpWalk;

  //Preparing house area
  if (fType = utWorker) and (fTask is TKMTaskBuildHouseArea)
  and TKMTaskBuildHouseArea(fTask).Digging
  then
    Result := tpWorker; //Special mode that allows us to walk on building sites

  //Miners at work need to go off roads
  if (fType in [utWoodcutter, utFarmer, utFisher, utStoneCutter])
  and (fTask is TKMTaskMining)
  then
    Result := tpWalk;
end;


procedure TKMUnit.Feed(Amount: Single);
begin
  fCondition := Math.min(fCondition + Round(Amount), UNIT_MAX_CONDITION);
end;


function TKMUnit.IsHungry: Boolean;
begin
  Result := fCondition < UNIT_MIN_CONDITION;
end;


//It's better not to start doing anything with dying units
function TKMUnit.IsDeadOrDying: Boolean;
begin
  Result := fIsDead or fKillASAP or (fTask is TKMTaskDie);
end;


function TKMUnit.IsDismissing: Boolean;
begin
  Result := fDismissASAP or (fTask is TKMTaskDismiss);
end;


function TKMUnit.IsDismissAvailable: Boolean;
begin
  Result := (fTask = nil) or fTask.CouldBeCancelled;
end;


function TKMUnit.IsDismissCancelAvailable: Boolean;
begin
  Result := fDismissASAP
            or ((fTask is TKMTaskDismiss)
              and TKMTaskDismiss(fTask).CouldBeCancelled);
end;


function TKMUnit.CanWalkDiagonaly(const aFrom, aTo: TKMPoint): Boolean;
begin
  Result := gTerrain.CanWalkDiagonaly(aFrom, aTo.X, aTo.Y);
end;


function TKMUnit.CanWalkTo(const aTo: TKMPoint; aDistance: Single): Boolean;
begin
  Result := gTerrain.Route_CanBeMade(CurrPosition, aTo, DesiredPassability, aDistance);
end;


function TKMUnit.CanWalkTo(const aTo: TKMPoint; aPass: TKMTerrainPassability; aDistance: Single): Boolean;
begin
  Result := gTerrain.Route_CanBeMade(CurrPosition, aTo, aPass, aDistance);
end;


function TKMUnit.CanWalkTo(const aFrom, aTo: TKMPoint; aDistance: Single): Boolean;
begin
  Result := gTerrain.Route_CanBeMade(aFrom, aTo, DesiredPassability, aDistance);
end;


function TKMUnit.CanWalkTo(const aFrom, aTo: TKMPoint; aPass: TKMTerrainPassability; aDistance: Single): Boolean;
begin
  Result := gTerrain.Route_CanBeMade(aFrom, aTo, aPass, aDistance);
end;


//Check if a route can be made to any tile around this house
function TKMUnit.CanWalkTo(const aFrom: TKMPoint; aHouse: TKMHouse; aPass: TKMTerrainPassability; aDistance: Single): Boolean;
var
  I: Integer;
  Cells: TKMPointList;
begin
  Result := False;
  Cells := TKMPointList.Create;
  try
    aHouse.GetListOfCellsWithin(Cells);
    for I := 0 to Cells.Count - 1 do
      Result := Result or gTerrain.Route_CanBeMade(aFrom, Cells[I], aPass, aDistance);
  finally
    Cells.Free;
  end;
end;


function TKMUnit.CanStepTo(X,Y: Integer; aPass: TKMTerrainPassability): Boolean;
begin
  Result := gTerrain.TileInMapCoords(X,Y)
        and (gTerrain.Land[Y,X].IsUnit = nil)
        and (gTerrain.CheckPassability(KMPoint(X,Y), aPass))
        and (not KMStepIsDiag(CurrPosition, KMPoint(X,Y)) //Only check vertex usage if the step is diagonal
             or (not gTerrain.HasVertexUnit(KMGetDiagVertex(CurrPosition, KMPoint(X,Y)))))
        and (gTerrain.CanWalkDiagonaly(CurrPosition, X, Y));
end;


procedure TKMUnit.UpdateThoughts;
begin
  if (fThought <> thDeath) and (fCondition <= UNIT_MIN_CONDITION div 3) then
    fThought := thDeath;

  if (fThought in [thDeath, thEat]) and (fCondition > UNIT_MIN_CONDITION) then
    fThought := thNone;

  if (fTask is TKMTaskDismiss) then
    fThought := thDismiss;

  if (fTask is TKMTaskDie) then //Clear thought if we are in the process of dying
    fThought := thNone;
end;


//Return true if the unit has to be killed due to lack of space
function TKMUnit.UpdateVisibility: Boolean;
var
  NewCurrPosition: TKMPoint;
begin
  Result := False;
  if fInHouse = nil then Exit; //There's nothing to update, we are always visible

  if fInHouse.IsDestroyed then //Someone has destroyed the house we were in
  begin
    fVisible := True;
    //If we are walking into/out of the house then don't set our position, ActionGoInOut will sort it out
    if (not (Action is TKMUnitActionGoInOut))
    or (not TKMUnitActionGoInOut(Action).GetHasStarted)
    or (TKMUnitActionGoInOut(Action).GetWaitingForPush) then
    begin
      //Position in a spiral nearest to entrance of house, updating IsUnit.
      if not gHands.FindPlaceForUnit(fInHouse.Entrance.X, fInHouse.Entrance.Y, UnitType, NewCurrPosition, gTerrain.GetWalkConnectID(fInHouse.Entrance)) then
      begin
        //There is no space for this unit so it must be destroyed
        //todo: re-route to KillUnit and let it sort out that unit is invisible and cant be placed
        if (gHands <> nil) and (fOwner <> PLAYER_NONE) and not IsDeadOrDying then
        begin
          gHands[fOwner].Stats.UnitLost(fType);
          gScriptEvents.ProcUnitDied(Self, PLAYER_NONE);
        end;
        //These must be freed before running CloseUnit because task destructors sometimes need access to unit properties
        SetAction(nil);
        FreeAndNil(fTask);
        CloseUnit(False); //Close the unit without removing tile usage (because this unit was in a house it has none)
        Result := true;
        exit;
      end;
      SetCurrPosition(NewCurrPosition); //will update FOW

      //Make sure these are reset properly
      Assert(not gTerrain.HasUnit(fCurrPosition));
      IsExchanging := false;
      fPositionF := KMPointF(fCurrPosition);
      fPrevPosition := fCurrPosition;
      fNextPosition := fCurrPosition;
      gTerrain.UnitAdd(fCurrPosition, Self); //Unit was not occupying tile while inside the house, hence just add do not remove

      //OnWarriorWalkOut usually happens in TUnitActionGoInOut, otherwise the warrior doesn't get assigned a group
      //Do this after setting terrain usage since OnWarriorWalkOut calls script events
      if (Self is TKMUnitWarrior) and Assigned(TKMUnitWarrior(Self).OnWarriorWalkOut) then
        TKMUnitWarrior(Self).OnWarriorWalkOut(TKMUnitWarrior(Self));

      if Action is TKMUnitActionGoInOut then
        SetActionLockedStay(0, uaWalk); //Abandon the walk out in this case

      if (Task is TKMTaskGoEat) and (TKMTaskGoEat(Task).Eating) then
      begin
        FreeAndNil(fTask); //Stop the eating animation and makes the unit appear
        SetActionStay(0, uaWalk); //Free the current action and give the unit a temporary one
      end;
      //If we were idle abandon our action so we look for a new house immediately (rather than after 20 seconds for the fisherman)
      if (Task = nil) and (Action is TKMUnitActionStay) and not TKMUnitActionStay(Action).Locked then
        SetActionStay(0, uaWalk); //Free the current action and give the unit a temporary one
    end;
    SetInHouse(nil); //Can't be in a destroyed house
  end;
end;


procedure TKMUnit.VertexAdd(const aFrom, aTo: TKMPoint);
begin
  gTerrain.UnitVertexAdd(aFrom, aTo);
end;

procedure TKMUnit.VertexRem(const aLoc: TKMPoint);
begin
  gTerrain.UnitVertexRem(aLoc); //Unoccupy vertex
end;


function TKMUnit.VertexUsageCompatible(const aFrom, aTo: TKMPoint): Boolean;
begin
  Result := gTerrain.VertexUsageCompatible(aFrom, aTo);
end;


procedure TKMUnit.Walk(const aFrom, aTo: TKMPoint);
begin
  gTerrain.UnitWalk(aFrom, aTo, Self)
end;


function TKMUnit.GetActivityText: UnicodeString;
const
  TASK_TEXT: array[TKMUnitTaskType] of Integer = (
      -1,-1,                   //uttUnknown, uttSelfTrain
      TX_UNIT_TASK_DELVERING,  //uttDeliver
      TX_UNIT_TASK_ROAD,       //uttBuildRoad
      TX_UNIT_TASK_WINEFIELD,  //uttBuildWine
      TX_UNIT_TASK_FIELD,      //uttBuildField
      TX_UNIT_TASK_HOUSE_SITE, //uttBuildHouseArea
      TX_UNIT_TASK_HOUSE,      //uttBuildHouse
      TX_UNIT_TASK_REPAIRING,  //uttBuildHouseRepair
      TX_UNIT_TASK_HOME,       //uttGoHome
      TX_UNIT_TASK_DISMISS,    //uttDismiss
      TX_UNIT_TASK_INN,        //uttGoEat
      -1,                      //uttMining (overridden by Citizen)
      -1,                      //uttDie (never visible)
      TX_UNIT_TASK_INN,        //uttGoOutShowHungry
      -1,                      //uttAttackHouse (overridden by Warrior)
      -1                       //uttThrowRock (never visible)
    );
begin
  if (fTask <> nil) and (TASK_TEXT[fTask.TaskType] <> -1) then
    Result := gResTexts[TASK_TEXT[fTask.TaskType]]
  else
    Result := gResTexts[TX_UNIT_TASK_IDLE];
end;


procedure TKMUnit.UpdateHitPoints;
begin
  //Use fHitPointCounter as a counter to restore hit points every X ticks (Humbelum says even when in fights)
  if HITPOINT_RESTORE_PACE = 0 then Exit; //0 pace means don't restore

  if (fHitPointCounter mod HITPOINT_RESTORE_PACE = 0) and (fHitPoints < HitPointsMax) then
    Inc(fHitPoints);

  Inc(fHitPointCounter); //Increasing each tick by 1 would require 13,6 years to overflow Cardinal
end;


function TKMUnit.GetSlide(aCheck: TKMCheckAxis): Single;
//Pixel positions (waypoints) for sliding around other units. Uses a lookup to save on-the-fly calculations.
//Follows a sort of a bell curve (normal distribution) shape for realistic acceleration/deceleration.
//I tweaked it by hand to look similar to KaM.
//1st row for straight, 2nd for diagonal sliding
const
  SlideLookup: array[1..2, 0..Round(CELL_SIZE_PX * 1.42)] of byte = ( //1.42 instead of 1.41 because we want to round up just in case (it was causing a crash because Round(40*sqrt(2)) = 57 but Round(40*1.41) = 56)
    (0,0,0,0,0,0,1,1,2,2,3,3,4,5,6,7,7,8,8,9,9,9,9,8,8,7,7,6,5,4,3,3,2,2,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,3,3,4,4,4,5,5,5,6,6,6,7,7,7,7,6,6,6,5,5,5,4,4,4,3,3,2,2,2,1,1,1,1,0,0,0,0,0,0,0,0,0));
var
  DY,DX, PixelPos, LookupDiagonal: shortint;
begin
  Result := 0;

  //When going into a house, units "slide" towards the door when it is not on center
  if Action is TKMUnitActionGoInOut then
    Result := Result+TKMUnitActionGoInOut(Action).GetDoorwaySlide(aCheck);

  if (not IsExchanging) or not (Action.ActName in [uanWalkTo, uanGoInOut]) then exit;

  //Uses Y because a walk in the Y means a slide in the X
  DX := sign(NextPosition.X - fPositionF.X);
  DY := sign(NextPosition.Y - fPositionF.Y);
  if (aCheck = axX) and (DY = 0) then exit; //Unit is not shifted
  if (aCheck = axY) and (DX = 0) then exit;

  LookupDiagonal := abs(DX) + abs(DY); //which gives us swith: 1-straight, 2-diagonal.

  if aCheck = axX then
  begin
    PixelPos := Round(abs(fPositionF.Y-PrevPosition.Y)*CELL_SIZE_PX*sqrt(LookupDiagonal)); //Diagonal movement *sqrt(2)
    Result := Result+(DY*SlideLookup[LookupDiagonal,PixelPos])/CELL_SIZE_PX;
  end;
  if aCheck = axY then
  begin
    PixelPos := Round(abs(fPositionF.X-PrevPosition.X)*CELL_SIZE_PX*sqrt(LookupDiagonal)); //Diagonal movement *sqrt(2)
    Result := Result-(DX*SlideLookup[LookupDiagonal,PixelPos])/CELL_SIZE_PX;
  end;
end;


function TKMUnit.PathfindingShouldAvoid: Boolean;
begin
  Result := not (fAction is TKMUnitActionWalkTo); //If we're walking, pathfinding should not route around us
end;


function TKMUnit.GetMovementVector: TKMPointF;
var
  MovementSpeed: Single;
begin
  if (Action is TKMUnitActionWalkTo) and TKMUnitActionWalkTo(Action).DoesWalking then
    MovementSpeed := gRes.Units[fType].Speed
  else
  if (Action is TKMUnitActionStormAttack) then
    MovementSpeed := TKMUnitActionStormAttack(Action).GetSpeed
  else
    MovementSpeed := 0;

  Result.X := KMGetVertex(fDirection).X * MovementSpeed;
  Result.Y := KMGetVertex(fDirection).Y * MovementSpeed;
end;


function TKMUnit.IsIdle: Boolean;
begin
  Result := (fTask = nil) and ((fAction is TKMUnitActionStay) and not TKMUnitActionStay(fAction).Locked);
end;


function TKMUnit.ObjToStringShort(aSeparator: String = '|'): String;
var
  ActStr, TaskStr: String;
begin
  ActStr := 'nil';
  TaskStr := 'nil';
  if fAction <> nil then
    ActStr := fAction.ClassName;
  if fTask <> nil then
    TaskStr := fTask.ObjToString;

  Result := Format('UID = %d%sType = %s%sAction = %s%sTask = [%s]%sCurrPosition = %s',
                   [fUID, aSeparator,
                    GetEnumName(TypeInfo(TKMUnitType), Integer(fType)), aSeparator,
                    ActStr, aSeparator,
                    TaskStr, aSeparator,
                    TypeToString(fCurrPosition)]);
end;


function TKMUnit.ObjToString(aSeparator: String = '|'): String;
var
  HomeStr: String;
begin
  HomeStr := 'nil';

  if fHome <> nil then
    HomeStr := Format('[UID = %d, Type = %s]', [fHome.UID, GetEnumName(TypeInfo(TKMHouseType), Integer(fHome.HouseType))]);

  Result := ObjToStringShort(aSeparator) +
            Format('%sPositionF = %s%sPrevPosition = %s%sNextPosition = %s%s' +
                   'Thought = %s%sHitPoints = %d%sHitPointCounter = %d%sCondition = %d%s' +
                   'Owner = %d%sHome = %s%sVisible = %s%sIsDead = %s',
                   [aSeparator,
                    TypeToString(fPositionF), aSeparator,
                    TypeToString(fPrevPosition), aSeparator,
                    TypeToString(fNextPosition), aSeparator,
                    GetEnumName(TypeInfo(TKMUnitThought), Integer(fThought)), aSeparator,
                    fHitPoints, aSeparator,
                    fHitPointCounter, aSeparator,
                    fCondition, aSeparator,
                    fOwner, aSeparator,
                    HomeStr, aSeparator,
                    BoolToStr(fVisible, True), aSeparator,
                    BoolToStr(fIsDead, True)]);
end;


procedure TKMUnit.Save(SaveStream: TKMemoryStream);
var
  HasTask, HasAct: Boolean;
  ActName: TKMUnitActionName;
begin
  SaveStream.Write(fType, SizeOf(fType));

  HasTask := fTask <> nil; //Thats our switch to know if unit should write down his task.
  SaveStream.Write(HasTask);
  if HasTask then
  begin
    //We save TaskName to know which Task class to load
    SaveStream.Write(fTask.TaskType, SizeOf(fTask.TaskType));
    fTask.Save(SaveStream);
  end;

  HasAct := fAction <> nil;
  SaveStream.Write(HasAct);
  if HasAct then
  begin
    ActName := fAction.ActName; //Can not pass function result to Write
    //We save ActName to know which Task class to load
    SaveStream.Write(ActName, SizeOf(ActName));
    fAction.Save(SaveStream);
  end;

  SaveStream.Write(fThought, SizeOf(fThought));
  SaveStream.Write(fCondition);
  SaveStream.Write(fStartWDefaultCondition);
  SaveStream.Write(fTicker);
  SaveStream.Write(fHitPoints);
  SaveStream.Write(fHitPointCounter);
  SaveStream.Write(HitPointsInvulnerable);

  if fInHouse <> nil then
    SaveStream.Write(fInHouse.UID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Integer(0));

  SaveStream.Write(fOwner, SizeOf(fOwner));

  if fHome <> nil then
    SaveStream.Write(fHome.UID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Integer(0));

  SaveStream.Write(fPositionF);
  SaveStream.Write(fVisible);
  SaveStream.Write(fIsDead);
  SaveStream.Write(fKillASAP);
  SaveStream.Write(fKillASAPShowAnimation);
  SaveStream.Write(IsExchanging);
  SaveStream.Write(fPointerCount);

  SaveStream.Write(fUID);
  SaveStream.Write(AnimStep);
  SaveStream.Write(fDirection);
  SaveStream.Write(fCurrPosition);
  SaveStream.Write(fPrevPosition);
  SaveStream.Write(fNextPosition);
  SaveStream.Write(fDismissASAP);
  SaveStream.Write(Dismissable);
end;


{Here are common Unit.UpdateState routines}
function TKMUnit.UpdateState: Boolean;
begin
  //There are layers of unit activity (bottom to top):
  // - Action (Atom creating layer (walk 1frame, etc..))
  // - Task (Action creating layer)
  // - specific UpdateState (Task creating layer)

  Result := True;

  if fAction = nil then
    raise ELocError.Create(gRes.Units[UnitType].GUIName + ' has no action at start of TKMUnit.UpdateState', fCurrPosition);

  if not ((fAction is TKMUnitActionWalkTo) and TKMUnitActionWalkTo(fAction).DoingExchange) then
  begin
    //UpdateState can happen right after unit gets killed (Exchange still in progress)
    if fKillASAP then
    begin
      DoKill(fKillASAPShowAnimation);
      fKillASAP := False;
      Assert(IsDeadOrDying, 'Unit should be dead or dying'); //Just in case KillUnit failed
    end;

    //UpdateState can happen right after unit gets dismissed (Exchange still in progress)
    if fDismissASAP then
    begin
      fDismissASAP := False; //Could be set back to True in DoDismiss
      DoDismiss;
    end;
  end;

  //Reset unit dismiss, when target school is destroyed
  if not fDismissASAP and (fTask is TKMTaskDismiss)
    and ((TKMTaskDismiss(fTask).School = nil)
      or TKMTaskDismiss(fTask).School.IsDestroyed) then
    DoDismiss;

  Inc(fTicker);

  //Update hunger
  if (fTicker mod CONDITION_PACE = 0)
    and (fCondition > 0)
    and not ((fTask is TKMTaskGoEat) and TKMTaskGoEat(fTask).Eating) then
    //Make unit hungry as long as they are not currently eating in the inn
    Dec(fCondition);

  //Unit killing could be postponed by few ticks, hence fCondition could be <0
  if fCondition <= 0 then
    Kill(PLAYER_NONE, True, False);

  //We only need to update fog of war regularly if we're using dynamic fog of war, otherwise only update it when the unit moves
  if gGameApp.DynamicFOWEnabled and (fTicker mod FOW_PACE = 0) then
    gHands.RevealForTeam(fOwner, fCurrPosition, gRes.Units[fType].Sight, FOG_OF_WAR_INC);

  UpdateThoughts;
  UpdateHitPoints;
  if UpdateVisibility then Exit; //incase units home was destroyed. Returns true if the unit was killed due to lack of space

  //Shortcut to kill unit in place if it's on an unwalkable tile. We use fNextPosition rather than fCurrPosition
  //because once we have taken a step from a tile we no longer care about it. (fNextPosition matches up with IsUnit in terrain)
  if fAction is TKMUnitActionWalkTo then
    if DesiredPassability = tpWalkRoad then
    begin
      if not gTerrain.CheckPassability(fNextPosition, tpWalk) then
        Self.Kill(PLAYER_NONE, False, True);
        //Grayter 18.01.2018
        //Despite checking passability of current tile, some units can walk on
        //unwalkable tile especially when there are many soldiers on the map (> 4000)
        //I don't know why it happens really, so we decided to kill this unit instead
        //of rising error. This problem does not occur in 99.9% gameplays and is fired
        //randomly so it is practically impossible to debug.
        //raise ELocError.Create( gRes.Units[UnitType].GUIName+' on unwalkable tile at '+KM_Points.TypeToString(fNextPosition)+' pass CanWalk', fNextPosition);
    end else
    if not gTerrain.CheckPassability(fNextPosition, DesiredPassability) then
      Self.Kill(PLAYER_NONE, False, True);
      //Explanation above
      //raise ELocError.Create(gRes.Units[UnitType].GUIName+' on unwalkable tile at '+KM_Points.TypeToString(fNextPosition)+' "'+PassabilityGuiText[DesiredPassability] + '"', fNextPosition);

  //
  //Performing Tasks and Actions now
  //------------------------------------------------------------------------------------------------
  if fAction = nil then
    raise ELocError.Create(gRes.Units[UnitType].GUIName+' has no action in TKMUnit.UpdateState',fCurrPosition);

  SetCurrPosition(KMPointRound(fPositionF)); //will update FOW

  case fAction.Execute of
    arActContinues: begin
                      SetCurrPosition(KMPointRound(fPositionF));
                      Exit;
                    end; //will update FOW
    arActAborted:   begin
                      FreeAndNil(fAction);
                      FreeAndNil(fTask);
                    end;
    arActDone:      begin
                      if Assigned(fAction.OnActionDone) then
                      begin
                        //Free action depends of fOnActionDone
                        //If we created new action, then no need to free it
                        //If we created new task then we must free it
                        if not fAction.fOnActionDone() then
                          FreeAndNil(fAction);
                      end else
                        FreeAndNil(fAction);
                    end;
  end;
  SetCurrPosition(KMPointRound(fPositionF)); //will update FOW

  if fTask <> nil then
  case fTask.Execute of
    trTaskContinues:  Exit;
      trTaskDone:       FreeAndNil(fTask);
    end;

  //If we get to this point then it means that common part is done and now
  //we can perform unit-specific activities (ask for job, etc..)
  Result := False;
end;


procedure TKMUnit.Paint;
begin
  //Here should be catched any cases where unit has no current action - this is a flaw in TTasks somewhere
  //Unit always meant to have some Action performed.
  //However, do not assert it here because then the player cannot close the message (paint happens repeatedly)
  //We check it at the start and end of UpdateState, that is the only place.
  if fAction <> nil then
    fAction.Paint;

  if SHOW_POINTER_DOTS then
    gRenderAux.UnitPointers(fPositionF.X + 0.5 + GetSlide(axX), fPositionF.Y + 1   + GetSlide(axY), fPointerCount);
end;


class function TKMUnit.GetDefaultCondition: Integer;
begin
  Result := Round(UNIT_MAX_CONDITION * UNIT_CONDITION_BASE);
end;


{ TUnitTask }
constructor TKMUnitTask.Create(aUnit: TKMUnit);
begin
  inherited Create;

  fType := uttUnknown;
  Assert(aUnit <> nil);
  fUnit := aUnit.GetUnitPointer;
  fPhase  := 0;
  fPhase2 := 0;

  InitDefaultAction;
end;


constructor TKMUnitTask.Load(LoadStream: TKMemoryStream);
begin
  inherited Create;

  LoadStream.Read(fType, SizeOf(fType));
  LoadStream.Read(fUnit, 4);//Substitute it with reference on SyncLoad
  LoadStream.Read(fPhase);
  LoadStream.Read(fPhase2);
end;


procedure TKMUnitTask.SyncLoad;
begin
  fUnit := gHands.GetUnitByUID(cardinal(fUnit));
end;


destructor TKMUnitTask.Destroy;
begin
  fUnit.Thought := thNone; //Stop any thoughts
  gHands.CleanUpUnitPointer(fUnit);
  fPhase        := High(Byte) - 1; //-1 so that if it is increased on the next run it won't overrun before exiting
  fPhase2       := High(Byte) - 1;
  inherited;
end;


procedure TKMUnitTask.InitDefaultAction;
begin
  fUnit.SetActionLockedStay(0, uaWalk);
end;


function TKMUnitTask.WalkShouldAbandon: Boolean;
begin
  Result := False; //Only used in some child classes
end;


function TKMUnitTask.CouldBeCancelled: Boolean;
begin
  Result := False; //Only used in some child classes
end;


function TKMUnitTask.ObjToString(aSeparator: String = ', '): String;
begin
  Result := Format('Type %s%sPhase = %d%sPhase2 = %d',
                   [GetEnumName(TypeInfo(TKMUnitTaskType), Integer(fType)), aSeparator,
                    fPhase, aSeparator,
                    fPhase2]);
end;


procedure TKMUnitTask.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.Write(fType, SizeOf(fType)); //Save task type before anything else for it will be used on loading to create specific task type
  if fUnit <> nil then
    SaveStream.Write(fUnit.UID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Integer(0));
  SaveStream.Write(fPhase);
  SaveStream.Write(fPhase2);
end;


{ TUnitAction }
constructor TKMUnitAction.Create(aUnit: TKMUnit; aActionType: TKMUnitActionType; aLocked: Boolean);
begin
  inherited Create;

  //Unit who will be performing the action
  //Does not require pointer tracking because action should always be destroyed before the unit that owns it
  fUnit       := aUnit;
  fType := aActionType;
  Locked      := aLocked;
  StepDone    := False;
end;


constructor TKMUnitAction.Load(LoadStream: TKMemoryStream);
begin
  inherited Create;
  LoadStream.Read(fType, SizeOf(fType));
  LoadStream.Read(fUnit, 4);
  LoadStream.Read(Locked);
  LoadStream.Read(StepDone);
end;


procedure TKMUnitAction.SyncLoad;
begin
  fUnit := gHands.GetUnitByUID(cardinal(fUnit));
end;


procedure TKMUnitAction.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.Write(fType, SizeOf(fType));
  if fUnit <> nil then
    SaveStream.Write(fUnit.UID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Integer(0));
  SaveStream.Write(Locked);
  SaveStream.Write(StepDone);
end;


procedure TKMUnitAction.Paint;
begin
  //Used for debug, paint action properties here
end;


function TKMUnitAction.CanBeInterrupted(aForced: Boolean = True): Boolean;
begin
  Result := True;
end;


end.
