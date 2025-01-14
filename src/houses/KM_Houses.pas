unit KM_Houses;
{$I KaM_Remake.inc}
interface
uses
  KM_ResHouses, KM_ResWares,
  KM_CommonClasses, KM_CommonTypes, KM_Defaults, KM_Points,
  KM_HandEntity,
  KM_GameTypes, KM_ResTypes;

// Houses are ruled by units, hence they don't know about  TKMUnits

// Everything related to houses is here
type
  //* Delivery mode
  TKMDeliveryMode = (dmClosed, dmDelivery, dmTakeOut);
const
  DELIVERY_MODE_SPRITE: array [TKMDeliveryMode] of Word = (38, 37, 664);

type
  TKMHouse = class;
  TKMHouseEvent = procedure(aHouse: TKMHouse) of object;
  TKMHouseFromEvent = procedure(aHouse: TKMHouse; aFrom: TKMHandID) of object;
  TKMHouseArray = array of TKMHouse;

  TKMHouseSketch = class;

  TKMHouseSketchType = (hstHousePlan, hstHouse);
  TKMHouseSketchTypeSet = set of TKMHouseSketchType;

  TAnonHouseSketchBoolFn = function(aSketch: TKMHouseSketch; aBoolParam: Boolean): Boolean;

  TKMHouseAction = class
  private
    fHouse: TKMHouse;
    fHouseState: TKMHouseState;
    fSubAction: TKMHouseActionSet;
    procedure SetHouseState(aHouseState: TKMHouseState);
  public
    constructor Create(aHouse: TKMHouse; aHouseState: TKMHouseState);
    procedure SubActionWork(aActionSet: TKMHouseActionType);
    procedure SubActionAdd(aActionSet: TKMHouseActionSet);
    procedure SubActionRem(aActionSet: TKMHouseActionSet);
    property State: TKMHouseState read fHouseState write SetHouseState;
    property SubAction: TKMHouseActionSet read fSubAction;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad;

    function ObjToString(const aSeparator: String = ' '): String;
  end;


  TKMHouseSketch = class(TKMHandEntityPointer<TKMHouse>)
  private
    fType: TKMHouseType; //House type
    fEntrance: TKMPoint;
    fPointBelowEntrance: TKMPoint;
    procedure UpdateEntrancePos;
  protected
    fPosition: TKMPoint; //House position on map, kinda virtual thing cos it doesn't match with entrance
    procedure SetPosition(const aPosition: TKMPoint); virtual;
    constructor Create; overload;
  public
    constructor Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID); overload;

    property HouseType: TKMHouseType read fType;

    property Position: TKMPoint read fPosition;
    property Entrance: TKMPoint read fEntrance;
    property PointBelowEntrance: TKMPoint read fPointBelowEntrance;

    function ObjToStringShort(const aSeparator: String = '|'): String; override;

    function IsEmpty: Boolean;
  end;

  // Editable Version of TKMHouseSketch
  // We do not want to allow edit TKMHouse fields, but need to do that for some sketches
  TKMHouseSketchEdit = class(TKMHouseSketch)
  private
    fEditable: Boolean;
  protected
    function GetInstance: TKMHouse; override;
    function GetIsSelectable: Boolean; override;
    function GetPositionForDisplayF: TKMPointF; override;
  public
    constructor Create;

    procedure Clear;
    procedure CopyTo(aHouseSketch: TKMHouseSketchEdit);

    procedure SetHouseUID(aUID: Integer);
    procedure SetHouseType(aHouseType: TKMHouseType);
    procedure SetPosition(const aPosition: TKMPoint); override;

    class var DummyHouseSketch: TKMHouseSketchEdit;
  end;


  TKMHouse = class(TKMHouseSketch)
  private
    fBuildSupplyWood: Byte; //How much Wood was delivered to house building site
    fBuildSupplyStone: Byte; //How much Stone was delivered to house building site
    fBuildReserve: Byte; //Take one build supply resource into reserve and "build from it"
    fBuildingProgress: Word; //That is how many efforts were put into building (Wooding+Stoning)
    fIsReadyToBeBuilt: Boolean;
    fDamage: Word; //Damaged inflicted to house

    fTick: Cardinal;
    fWorker: Pointer; // Worker, who is running this house
    fIsClosedForWorker: Boolean; // house is closed for worker. If worker is already occupied it, then leave house

    fBuildingRepair: Boolean; //If on and the building is damaged then labourers will come and repair it

    //Switch between delivery modes: delivery on/off/or make an offer from resources available
    fDeliveryMode: TKMDeliveryMode; // REAL delivery mode - using in game interactions and actual deliveries
    fNewDeliveryMode: TKMDeliveryMode; // Fake, NEW delivery mode, used just for UI. After few tick it will be set as REAL, if there will be no other clicks from player
    // Delivery mode set with small delay (couple of ticks), to avoid occasional clicks on delivery mode button
    fUpdateDeliveryModeOnTick: Cardinal; // Tick, on which we have to update real delivery mode with its NEW value

    fWareIn: array [1..4] of Byte; // Ware count in input


    // Count of the resources we have ordered for the input (used for ware distribution)
    //
    // We have to keep track of how many deliveries are going on now
    // But when demand is deleted it should be considered as well.
    // It could be deleted or not (if serf is entering demanded house)
    // F.e. when serf is walkin he can't close demand immidiately, he will close demand when he reach the next tile
    // Demand is marked as Deleted and fWareDemandsClosing is increased by 1
    // Then we will need to reduce fWareDeliveryCount and fWareDemandsClosing when demand will notify this house on its close
    // If serf is entering the house then we will not need to reduce fWareDeliveryCount, since ware is already delivered
    fWareDeliveryCount: array[1..4] of Word; // = fWareIn + Demands count (including closing demands)
    fWareDemandsClosing: array[1..4] of Word; // Number of closing demands at the moment

    fWareOut: array [1..4] of Byte; //Resource count in output
    fWareOrder: array [1..4] of Word; //If HousePlaceOrders=True then here are production orders
    fWareOutPool: array[0..19] of Byte;
    fLastOrderProduced: Byte;
//    fWareOrderDesired: array [1..4] of Single;

    fIsOnSnow: Boolean;
    fSnowStep: Single;

    fIsDestroyed: Boolean;
    fIsBeingDemolished: Boolean; //To prevent script calling HouseDestroy on same house within OnHouseDestroyed action.
                                 //Not saved because it is set and used within the same tick only.
    fTimeSinceUnoccupiedReminder: Integer;
    fDisableUnoccupiedMessage: Boolean;
    fResourceDepletedMsgIssued: Boolean;
    fOrderCompletedMsgIssued: Boolean;
    fNeedIssueOrderCompletedMsg: Boolean;
    fPlacedOverRoad: Boolean; //Is house entrance placed over road

    fOnShowGameMessage: TKMGameShowMessageEvent;

    procedure CheckOnSnow;

    function GetWareInArray: TKMByteArray;
    function GetWareOutArray: TKMByteArray;
    function GetWareOutPoolArray: TKMByteArray;

    procedure SetIsReadyToBeBuilt(aIsReadyToBeBuilt: Boolean);

    function GetWareDistribution(aID: Byte): Byte; //Will use GetRatio from mission settings to find distribution amount
    procedure SetIsClosedForWorker(aIsClosed: Boolean);
    procedure UpdateDeliveryMode;
    function GetHasWorker: Boolean;

    procedure ShowMsg(aTextID: Integer);
  protected
    fBuildState: TKMHouseBuildState; // = (hbsGlyph, hbsNoGlyph, hbsWood, hbsStone, hbsDone);
    FlagAnimStep: Cardinal; //Used for Flags and Burning animation
    //WorkAnimStep: Cardinal; //Used for Work and etc.. which is not in sync with Flags
    procedure Activate(aWasBuilt: Boolean); virtual;
    procedure AddDemandsOnActivate(aWasBuilt: Boolean); virtual;
    function GetWareOrder(aId: Byte): Integer; virtual;
    function GetWareIn(aI: Byte): Word; virtual;
    function GetWareOut(aI: Byte): Word; virtual;
    function GetWareInLocked(aI: Byte): Word; virtual;
    procedure SetWareInManageTakeOutDeliveryMode(aWare: TKMWareType; aCntChange: Integer);
    procedure SetWareIn(aI: Byte; aValue: Word); virtual;
    procedure SetWareOut(aI: Byte; aValue: Word); virtual;
    procedure SetBuildingRepair(aValue: Boolean);
    procedure SetWareOrder(aId: Byte; aValue: Integer); virtual;
    procedure SetNewDeliveryMode(aValue: TKMDeliveryMode); virtual;
    procedure CheckTakeOutDeliveryMode; virtual;
    function GetDeliveryModeForCheck(aImmidiate: Boolean): TKMDeliveryMode;

    procedure SetWareDeliveryCount(aIndex: Integer; aCount: Integer);
    function GetWareDeliveryCount(aIndex: Integer): Integer;

    procedure SetWareDemandsClosing(aIndex: Integer; aCount: Integer);
    function GetWareDemandsClosing(aIndex: Integer): Integer;

    property WareDeliveryCnt[aIndex: Integer]: Integer read GetWareDeliveryCount write SetWareDeliveryCount;
    property WareDemandsClosing[aIndex: Integer]: Integer read GetWareDemandsClosing write SetWareDemandsClosing;

    function GetInstance: TKMHouse; override;
    function GetPositionForDisplayF: TKMPointF; override;
    function GetPositionF: TKMPointF; inline;

    function GetIsSelectable: Boolean; override;

    function TryDecWareDelivery(aWare: TKMWareType; aDeleteCanceled: Boolean): Boolean; virtual;

    procedure MakeSound; virtual; //Swine/stables make extra sounds
  public
    CurrentAction: TKMHouseAction; //Current action, withing HouseTask or idle
    WorkAnimStep: Cardinal; //Used for Work and etc.. which is not in sync with Flags
    WorkAnimStepPrev: Cardinal; //Used for interpolated render, not saved
    DoorwayUse: Byte; //number of units using our door way. Used for sliding.
    OnDestroyed: TKMHouseFromEvent;

    constructor Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure SyncLoad; virtual;
    destructor Destroy; override;
    procedure Save(SaveStream: TKMemoryStream); override;

    property OnShowGameMessage: TKMGameShowMessageEvent read fOnShowGameMessage write fOnShowGameMessage;

    procedure Remove;
    procedure Demolish(aFrom: TKMHandID; IsSilent: Boolean = False); virtual;
    property BuildingProgress: Word read fBuildingProgress;

    procedure UpdatePosition(const aPos: TKMPoint); //Used only by map editor
    procedure OwnerUpdate(aOwner: TKMHandID; aMoveToNewOwner: Boolean = False);

    function GetClosestCell(const aPos: TKMPoint): TKMPoint;
    function GetDistance(const aPos: TKMPoint): Single;
    function InReach(const aPos: TKMPoint; aDistance: Single): Boolean;
    procedure GetListOfCellsAround(aCells: TKMPointDirList; aPassability: TKMTerrainPassability);
    procedure GetListOfCellsWithin(aCells: TKMPointList);
    procedure GetListOfGroundVisibleCells(aCells: TKMPointTagList);
    function GetRandomCellWithin: TKMPoint;
    function HitTest(X, Y: Integer): Boolean;
    property BuildingRepair: Boolean read fBuildingRepair write SetBuildingRepair;
    property PlacedOverRoad: Boolean read fPlacedOverRoad write fPlacedOverRoad;

    property PositionF: TKMPointF read GetPositionF;

    property DeliveryMode: TKMDeliveryMode read fDeliveryMode;
    property NewDeliveryMode: TKMDeliveryMode read fNewDeliveryMode write SetNewDeliveryMode;
    procedure SetNextDeliveryMode;
    procedure SetPrevDeliveryMode;
    procedure SetDeliveryModeInstantly(aValue: TKMDeliveryMode);
    function AllowDeliveryModeChange: Boolean;

    procedure IssueResourceDepletedMsg;
    function GetResourceDepletedMessageId: Word;

    property ResourceDepleted: Boolean read fResourceDepletedMsgIssued write fResourceDepletedMsgIssued;
    property OrderCompletedMsgIssued: Boolean read fOrderCompletedMsgIssued;

    function ShouldAbandonDeliveryTo(aWareType: TKMWareType): Boolean; virtual;
    function ShouldAbandonDeliveryFrom(aWareType: TKMWareType; aImmidiateCheck: Boolean = False): Boolean; virtual;
    function ShouldAbandonDeliveryFromTo(aToHouse: TKMHouse; aWareType: TKMWareType; aImmidiateCheck: Boolean): Boolean; virtual;

    property Worker: Pointer read fWorker;
    procedure SetWorker(aWorker: Pointer); //Explicitly use SetWorker, to make it clear its not only pointer assignment
    property HasWorker: Boolean read GetHasWorker; //There's a citizen who runs this house
    function CanHasWorker: Boolean;
    function IsWorkerHungry: Boolean;
    property IsClosedForWorker: Boolean read fIsClosedForWorker write SetIsClosedForWorker;
    property DisableUnoccupiedMessage: Boolean read fDisableUnoccupiedMessage write fDisableUnoccupiedMessage;

    function GetHealth: Word;
    function GetBuildWoodDelivered: Byte;
    function GetBuildStoneDelivered: Byte;
    function GetBuildResourceDelivered: Byte;
    function GetBuildResDeliveredPercent: Single;

    property WareInArray: TKMByteArray read GetWareInArray;
    property WareOutArray: TKMByteArray read GetWareOutArray;
    property WareOutPoolArray: TKMByteArray read GetWareOutPoolArray;

    property BuildingState: TKMHouseBuildState read fBuildState write fBuildState;
    property BuildSupplyWood: Byte read fBuildSupplyWood;
    property BuildSupplyStone: Byte read fBuildSupplyStone;
    procedure IncBuildingProgress;

    function MaxHealth: Word;
    procedure AddDamage(aAmount: Word; aAttacker: TObject; aIsEditor: Boolean = False);
    procedure AddRepair(aAmount: Word = 5);
    procedure UpdateDamage;

    function IsStone: Boolean;
    function IsComplete: Boolean; inline;
    function IsDamaged: Boolean;
    property IsDestroyed: Boolean read fIsDestroyed;
    property IsReadyToBeBuilt: Boolean read fIsReadyToBeBuilt;
    property GetDamage: Word read fDamage;

    procedure SetState(aState: TKMHouseState);
    function GetState: TKMHouseState;

    procedure HouseDemandWasClosed(aWare: TKMWareType; aDeleteCanceled: Boolean);

    function CheckWareIn(aWare: TKMWareType): Word; virtual;
    function CheckWareOut(aWare: TKMWareType): Word; virtual;
    function PickOrder: Byte;
    function CheckResToBuild: Boolean;
    function GetMaxInWare: Word;
    procedure WareAddToIn(aWare: TKMWareType; aCount: Integer = 1; aFromStaticScript: Boolean = False); virtual; //override for School and etc..
    procedure WareAddToOut(aWare: TKMWareType; const aCount: Integer = 1);
    procedure WareAddToEitherFromScript(aWare: TKMWareType; aCount: Integer);
    procedure WareAddToBuild(aWare: TKMWareType; aCount: Integer = 1);
    procedure WareTake(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False); virtual;
    procedure WareTakeFromIn(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False); virtual;
    procedure WareTakeFromOut(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False); virtual;
    function WareCanAddToIn(aWare: TKMWareType): Boolean; virtual;
    function WareCanAddToOut(aWare: TKMWareType): Boolean;
    function CanHaveWareType(aWare: TKMWareType): Boolean; virtual;
    function WareOutputAvailable(aWare: TKMWareType; const aCount: Word): Boolean; virtual;
    property WareOrder[aId: Byte]: Integer read GetWareOrder write SetWareOrder;
    property ResIn[aId: Byte]: Word read GetWareIn write SetWareIn;
    property ResOut[aId: Byte]: Word read GetWareOut write SetWareOut;
    property WareInLocked[aId: Byte]: Word read GetWareInLocked;

    procedure UpdateDemands; virtual;
    procedure PostLoadMission; virtual;

    function ObjToString(const aSeparator: String = '|'): String; override;

    procedure IncAnimStep;
    procedure UpdateState(aTick: Cardinal);
    procedure Paint; virtual;
  end;


  TKMHouseWFlagPoint = class(TKMHouse)
  private
    fFlagPoint: TKMPoint;
  protected
    procedure SetFlagPoint(aFlagPoint: TKMPoint); virtual;
    function GetMaxDistanceToPoint: Integer; virtual;
  public
    constructor Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure Save(SaveStream: TKMemoryStream); override;

    property FlagPoint: TKMPoint read fFlagPoint write SetFlagPoint;
    property MaxDistanceToPoint: Integer read GetMaxDistanceToPoint;
    function IsFlagPointSet: Boolean;
    procedure ValidateFlagPoint;
    function GetValidPoint(aPoint: TKMPoint): TKMPoint;

    function ObjToString(const aSeparator: String = '|'): String; override;
  end;


  TKMHouseTower = class(TKMHouse)
  public
    procedure Paint; override; //Render debug radius overlay
  end;


implementation
uses
  // Do not add KM_Game dependancy! Entities should be isolated as much as possible
  TypInfo, SysUtils, Math, KromUtils,
  KM_Entity,
  KM_GameParams, KM_Terrain, KM_RenderPool, KM_RenderAux, KM_Sound,
  KM_Hand, KM_HandsCollection, KM_HandLogistics, KM_HandTypes,
  KM_Units, KM_UnitWarrior, KM_HouseWoodcutters,
  KM_Resource, KM_ResSound, KM_ResTexts, KM_ResUnits, KM_ResMapElements,
  KM_Log, KM_ScriptingEvents, KM_CommonUtils, KM_MapEdTypes,
  KM_RenderDebug,
  KM_TerrainTypes,
  KM_CommonExceptions,
  KM_ResTileset;

const
  // Delay, in ticks, from user click on DeliveryMode btn, to tick, when mode will be really set.
  // Made to prevent serf's taking/losing deliveries only because player clicks throught modes.
  // No hurry, let's wait a bit for player to be sure, what mode he needs
  UPDATE_DELIVERY_MODE_DELAY = 10;


{ TKMHouseSketch }
constructor TKMHouseSketch.Create;
begin
  inherited Create(etHouse, 0, -1); //Just do nothing; (For house loading)
end;


constructor TKMHouseSketch.Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID);
begin
  Assert((PosX <> 0) and (PosY <> 0)); // Can create only on map

  inherited Create(etHouse, aUID, aOwner);

  fType     := aHouseType;
  fPosition := KMPoint (PosX, PosY);
  UpdateEntrancePos;
end;


{Return Entrance of the house, which is different than house position sometimes}
procedure TKMHouseSketch.UpdateEntrancePos;
begin
  if IsEmpty then Exit;
  
  fEntrance.X := fPosition.X + gRes.Houses[fType].EntranceOffsetX;
  fEntrance.Y := fPosition.Y;
  Assert((fEntrance.X > 0) and (fEntrance.Y > 0));

  fPointBelowEntrance := KMPointBelow(fEntrance);
end;


procedure TKMHouseSketch.SetPosition(const aPosition: TKMPoint);
begin
  fPosition.X := aPosition.X;
  fPosition.Y := aPosition.Y;

  UpdateEntrancePos;
end;


function TKMHouseSketch.IsEmpty: Boolean;
begin
  Result :=    (UID = -1)
            or (HouseType = htNone)
            or (Position.X = -1)
            or (Position.Y = -1);
end;


function TKMHouseSketch.ObjToStringShort(const aSeparator: String = '|'): String;
begin
  if Self = nil then Exit('nil');

  Result := inherited ObjToStringShort(aSeparator) +
            Format('%sType = %s%sEntr = %s',
                  [aSeparator,
                   GetEnumName(TypeInfo(TKMHouseType), Integer(fType)), aSeparator,
                   TypeToString(Entrance)]);
end;


{ TKMHouseSketchEdit}
constructor TKMHouseSketchEdit.Create;
begin
  inherited Create(-1, htNone, -1, -1, -1);

  fEditable := True;
end;


procedure TKMHouseSketchEdit.Clear;
begin
  SetUID(-1);
  SetHouseType(htNone);
  SetPosition(KMPoint(0,0));
end;


procedure TKMHouseSketchEdit.CopyTo(aHouseSketch: TKMHouseSketchEdit);
begin
  aHouseSketch.Owner := Owner;
  aHouseSketch.SetUID(UID);
  aHouseSketch.SetHouseType(HouseType);
  aHouseSketch.SetPosition(Position);
end;


procedure TKMHouseSketchEdit.SetHouseUID(aUID: Integer);
begin
  if fEditable then
    SetUID(aUID);
end;


procedure TKMHouseSketchEdit.SetHouseType(aHouseType: TKMHouseType);
begin
  if fEditable then
    fType := aHouseType;
end;


procedure TKMHouseSketchEdit.SetPosition(const aPosition: TKMPoint);
begin
  if not fEditable then Exit;

  inherited;
end;


function TKMHouseSketchEdit.GetInstance: TKMHouse;
begin
  //Not used. Make compiler happy
  raise Exception.Create('Can''t get instance of TKMHouseSketchEdit');
end;


function TKMHouseSketchEdit.GetIsSelectable: Boolean;
begin
  Result := False;
end;


function TKMHouseSketchEdit.GetPositionForDisplayF: TKMPointF;
begin
  Assert(False, 'Should not get positionF of TKMHouseSketchEdit');
  //Not used. Make compiler happy
  Result := Entrance.ToFloat;
end;


{ TKMHouse }
constructor TKMHouse.Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
var
  I: Integer;
begin
  inherited Create(aUID, aHouseType, PosX, PosY, aOwner);

  fBuildState := aBuildState;
  fIsReadyToBeBuilt := False;

  fBuildSupplyWood  := 0;
  fBuildSupplyStone := 0;
  fBuildReserve     := 0;
  fBuildingProgress := 0;
  fDamage           := 0; //Undamaged yet

  fPlacedOverRoad   := gTerrain.TileHasRoad(Entrance);

  fWorker           := nil;
  //Initially repair is [off]. But for AI it's controlled by a command in DAT script
  fBuildingRepair   := False; //Don't set it yet because we don't always know who are AIs yet (in multiplayer) It is set in first UpdateState
  DoorwayUse        := 0;
  fNewDeliveryMode  := dmDelivery;
  fDeliveryMode     := dmDelivery;
  fUpdateDeliveryModeOnTick := 0;

  for I := 1 to 4 do
  begin
    fWareIn[I] := 0;
    fWareDeliveryCount[I] := 0;
    fWareDemandsClosing[I] := 0;
    fWareOut[I] := 0;
    fWareOrder[I] := 0;
  end;

  for I := 0 to 19 do
    fWareOutPool[I] := 0;

  fIsDestroyed := False;
//  fPointerCount := 0;
  fTimeSinceUnoccupiedReminder := TIME_BETWEEN_MESSAGES;

  fResourceDepletedMsgIssued := False;
  fNeedIssueOrderCompletedMsg := False;
  fOrderCompletedMsgIssued := False;

  // By default allow to show all houses to allies for locs, where human could play
  // Do not show AI-only frienly loc houses (they could have thousands of wares)
  AllowAllyToSelect :=  gHands[Owner].IsHuman or gHands[Owner].CanBeHuman;

  if aBuildState = hbsDone then //House was placed on map already Built e.g. in mission maker
  begin
    Activate(False);
    fBuildingProgress := gRes.Houses[fType].MaxHealth;
    gTerrain.SetHouse(fPosition, fType, hsBuilt, Owner, (gGameParams <> nil) and not gGameParams.IsMapEditor); //Sets passability and flattens terrain if we're not in the map editor
  end
  else
    gTerrain.SetHouse(fPosition, fType, hsFence, Owner); //Terrain remains neutral yet

  //Built houses accumulate snow slowly, pre-placed houses are already covered
  CheckOnSnow;
  fSnowStep := Byte(aBuildState = hbsDone);
end;


constructor TKMHouse.Load(LoadStream: TKMemoryStream);
var
  I: Integer;
  hasAct: Boolean;
begin
  inherited;

  LoadStream.CheckMarker('House');
  LoadStream.Read(fType, SizeOf(fType));
  LoadStream.Read(fPosition);
  UpdateEntrancePos;
  LoadStream.Read(fBuildState, SizeOf(fBuildState));
  LoadStream.Read(fIsReadyToBeBuilt);
  LoadStream.Read(fBuildSupplyWood);
  LoadStream.Read(fBuildSupplyStone);
  LoadStream.Read(fBuildReserve);
  LoadStream.Read(fBuildingProgress, SizeOf(fBuildingProgress));
  LoadStream.Read(fDamage, SizeOf(fDamage));
  LoadStream.Read(fWorker, 4); //subst on syncload
  LoadStream.Read(fBuildingRepair);
  LoadStream.Read(Byte(fDeliveryMode));
  LoadStream.Read(Byte(fNewDeliveryMode));
  LoadStream.Read(fUpdateDeliveryModeOnTick);
  LoadStream.Read(fIsClosedForWorker);
  for I:=1 to 4 do LoadStream.Read(fWareIn[I]);
  for I:=1 to 4 do LoadStream.Read(fWareDeliveryCount[I]);
  for I:=1 to 4 do LoadStream.Read(fWareDemandsClosing[I]);
  for I:=1 to 4 do LoadStream.Read(fWareOut[I]);
  for I:=1 to 4 do LoadStream.Read(fWareOrder[I], SizeOf(fWareOrder[I]));
//  for I:=1 to 4 do LoadStream.Read(fWareOrderDesired[I], SizeOf(fWareOrderDesired[I]));

  if gRes.Houses[fType].IsWorkshop then
    LoadStream.Read(fWareOutPool, 20); //todo: Should be SizeOf()

  LoadStream.Read(fLastOrderProduced);
  LoadStream.Read(FlagAnimStep);
  LoadStream.Read(WorkAnimStep);
  LoadStream.Read(fIsOnSnow);
  LoadStream.Read(fSnowStep);
  LoadStream.Read(fIsDestroyed);
  LoadStream.Read(fTimeSinceUnoccupiedReminder);
  LoadStream.Read(fDisableUnoccupiedMessage);
  LoadStream.Read(fNeedIssueOrderCompletedMsg);
  LoadStream.Read(fOrderCompletedMsgIssued);
  LoadStream.Read(hasAct);
  if hasAct then
  begin
    CurrentAction := TKMHouseAction.Create(nil, hstEmpty); //Create action object
    CurrentAction.Load(LoadStream); //Load actual data into object
  end;
  LoadStream.Read(fResourceDepletedMsgIssued);
  LoadStream.Read(DoorwayUse);
  LoadStream.Read(fPlacedOverRoad);
end;


procedure TKMHouse.SyncLoad;
begin
  fWorker := TKMUnit(gHands.GetUnitByUID(Integer(fWorker)));
  CurrentAction.SyncLoad;
end;


destructor TKMHouse.Destroy;
begin
  FreeAndNil(CurrentAction);
  gHands.CleanUpUnitPointer(TKMUnit(fWorker));

  inherited;
end;


procedure TKMHouse.AddDemandsOnActivate(aWasBuilt: Boolean);
var
  I, demandsCnt: Integer;
  W: TKMWareType;
begin
  for I := 1 to 4 do
  begin
    W := gRes.Houses[fType].WareInput[I];
    with gHands[Owner].Deliveries.Queue do
    case W of
      wtNone:    ;
      wtWarfare: AddDemand(Self, nil, W, 1, dtAlways, diNorm);
      wtAll:     AddDemand(Self, nil, W, 1, dtAlways, diNorm);
      else        begin
                    demandsCnt := GetWareDistribution(I);
                    AddDemand(Self, nil, W, demandsCnt, dtOnce, diNorm); //Every new house needs 5 resource units
                    WareDeliveryCnt[I] := WareDeliveryCnt[I] + demandsCnt; //Keep track of how many resources we have on order (for distribution of wares)
                  end;
    end;
  end;
end;


procedure TKMHouse.Activate(aWasBuilt: Boolean);

  function ObjectShouldBeCleared(X,Y: Integer): Boolean;
  begin
    Result := not gTerrain.ObjectIsChopableTree(KMPoint(X,Y), [caAge1,caAge2,caAge3,caAgeFull,caAgeFall])
              and not gTerrain.ObjectIsCorn(X,Y)
              and not gTerrain.ObjectIsWine(X,Y);
  end;

var
  I, K: Integer;
  P1, P2: TKMPoint;
  HA: TKMHouseArea;
begin
  // Only activated houses count
  gHands[Owner].Locks.HouseCreated(fType);
  gHands[Owner].Stats.HouseCreated(fType, aWasBuilt);

//  if not gGameApp.DynamicFOWEnabled then
//  begin
    HA := gRes.Houses[fType].BuildArea;
    //Reveal house from all points it covers
    for I := 1 to 4 do
      for K := 1 to 4 do
        if HA[I,K] <> 0 then
          gHands.RevealForTeam(Owner, KMPoint(fPosition.X + K - 4, fPosition.Y + I - 4), gRes.Houses[fType].Sight, FOG_OF_WAR_MAX);
//  end;

  CurrentAction := TKMHouseAction.Create(Self, hstEmpty);
  CurrentAction.SubActionAdd([haFlagpole, haFlag1..haFlag3]);

  UpdateDamage; //House might have been damaged during construction, so show flames when it is built
  AddDemandsOnActivate(aWasBuilt);

  //Fix for diagonal blocking objects near house entrance
  if aWasBuilt then
  begin
    P1 := KMPoint(Entrance.X - 1, Entrance.Y + 1) ; //Point to the left from PointBelowEntrance
    P2 := KMPoint(P1.X + 2, P1.Y);        //Point to the right from PointBelowEntrance

    if not gTerrain.CanWalkDiagonally(Entrance, P1.X, P1.Y)
      and ObjectShouldBeCleared(P1.X + 1, P1.Y) then // Do not clear choppable trees
      gTerrain.RemoveObject(KMPoint(P1.X + 1, P1.Y)); //Clear object at PointBelowEntrance

    if not gTerrain.CanWalkDiagonally(Entrance, P2.X, P2.Y)
      and ObjectShouldBeCleared(P2.X, P2.Y) then
      gTerrain.RemoveObject(P2);
  end;
end;


procedure TKMHouse.Remove;
begin
  Assert(gGameParams.IsMapEditor, 'Operation allowed only in the MapEd');

  Demolish(Owner, True);
  gHands[Owner].Houses.DeleteHouseFromList(Self);
end;


//IsSilent parameter is used by Editor and scripts
procedure TKMHouse.Demolish(aFrom: TKMHandID; IsSilent: Boolean = False);
var
  I: Integer;
  W: TKMWareType;
begin
  if IsDestroyed or fIsBeingDemolished then Exit;

  fIsBeingDemolished := True; //Make sure script doesn't try to demolish this house again during event
  OnDestroyed(Self, aFrom); //We must do this before setting fIsDestroyed for scripting
  fIsBeingDemolished := False; //No longer required

  //If anyone still has a pointer to the house he should check for IsDestroyed flag
  fIsDestroyed := True;

  //Play sound
  if (fBuildState > hbsNoGlyph) and not IsSilent
  and (gMySpectator <> nil) //gMySpectator is nil during loading
  and (gMySpectator.FogOfWar.CheckTileRevelation(fPosition.X, fPosition.Y) >= 255) then
    gSoundPlayer.Play(sfxHouseDestroy, fPosition);

  //NOTE: We don't run Stats.WareConsumed on fBuildSupplyWood/Stone as the
  //delivery task already did that upon delivery (they are irreversibly consumed at that point)

  for I := 1 to 4 do
  begin
    W := gRes.Houses[fType].WareInput[I];
    if W in [WARE_MIN..WARE_MAX] then
      gHands[Owner].Stats.WareConsumed(W, ResIn[I]);
    W := gRes.Houses[fType].WareOutput[I];
    if W in [WARE_MIN..WARE_MAX] then
      gHands[Owner].Stats.WareConsumed(W, fWareOut[I]);
  end;

  gTerrain.SetHouse(fPosition, fType, hsNone, HAND_NONE);

  //Leave rubble
  if not IsSilent then
    gTerrain.AddHouseRemainder(fPosition, fType, fBuildState);

  BuildingRepair := False; //Otherwise labourers will take task to repair when the house is destroyed
  if (BuildingState in [hbsNoGlyph, hbsWood]) or IsSilent then
  begin
    if gTerrain.TileHasRoad(Entrance) and not fPlacedOverRoad then
    begin
      gTerrain.RemRoad(Entrance);
      if not IsSilent then
        gTerrain.Land^[Entrance.Y, Entrance.X].TileOverlay := toDig3; //Remove road and leave dug earth behind
    end;
  end;

  FreeAndNil(CurrentAction);

  //Leave disposing of units inside the house to themselves

  //Notify the script that the house is now completely gone
  gScriptEvents.EventHouseAfterDestroyed(HouseType, Owner, Entrance.X, Entrance.Y);
end;


//Used by MapEditor
//Set house to new position
procedure TKMHouse.UpdatePosition(const aPos: TKMPoint);
var
  wasOnSnow, isRallyPointSet: Boolean;
begin
  Assert(gGameParams.IsMapEditor);

  //We have to remove the house THEN check to see if we can place it again so we can put it on the old position
  gTerrain.SetHouse(fPosition, fType, hsNone, HAND_NONE);

  if gMySpectator.Hand.CanAddHousePlan(aPos, HouseType) then
  begin
    isRallyPointSet := False;
    //Save if flag point was set for previous position
    if (Self is TKMHouseWFlagPoint) then
      isRallyPointSet := TKMHouseWFlagPoint(Self).IsFlagPointSet;

    gTerrain.RemRoad(Entrance);

    SetPosition(KMPoint(aPos.X - gRes.Houses[fType].EntranceOffsetX, aPos.Y));

    //Update rally/cutting point position for houses with flag point after change fPosition
    if (Self is TKMHouseWFlagPoint) then
    begin
      if not isRallyPointSet then
        TKMHouseWFlagPoint(Self).FlagPoint := PointBelowEntrance
      else
        TKMHouseWFlagPoint(Self).ValidateFlagPoint;
    end;
  end;

  gTerrain.SetHouse(fPosition, fType, hsBuilt, Owner); // Update terrain tiles for house

  //Do not remove all snow if house is moved from snow to snow
  wasOnSnow := fIsOnSnow;
  CheckOnSnow;
  if not wasOnSnow or not fIsOnSnow then
    fSnowStep := 0;
end;


//Check and proceed if we Set or UnSet dmTakeOut delivery mode
procedure TKMHouse.CheckTakeOutDeliveryMode;
var
  I: Integer;
  resCnt: Word;
  W: TKMWareType;
begin
  // House had dmTakeOut delivery mode
  // Remove offers from this house then
  if fDeliveryMode = dmTakeOut then
    for I := 1 to 4 do
    begin
      W := gRes.Houses[fType].WareInput[I];
      resCnt := ResIn[I] - WareInLocked[I];
      if (W <> wtNone) and (resCnt > 0) then
        gHands[Owner].Deliveries.Queue.RemOffer(Self, W, resCnt);
    end;

  // House will get dmTakeOut delivery mode
  // Add offers to this house then
  if fNewDeliveryMode = dmTakeOut then
  begin
    for I := 1 to 4 do
    begin
      W := gRes.Houses[fType].WareInput[I];
      resCnt := ResIn[I] - WareInLocked[I];

      if not (W in [wtNone, wtAll, wtWarfare]) and (resCnt > 0) then
        gHands[Owner].Deliveries.Queue.AddOffer(Self, W, resCnt);
    end;
  end;
end;


// Use aCount: Integer, instead of Word, since we don't want to get Range check error exception
procedure TKMHouse.SetWareDeliveryCount(aIndex: Integer; aCount: Integer);
begin
  fWareDeliveryCount[aIndex] := EnsureRange(aCount, 0, High(Word));
end;


// Use Result Integer, instead of Word, since we don't want to get Range check error exception in the setter
function TKMHouse.GetWareDeliveryCount(aIndex: Integer): Integer;
begin
  Result := fWareDeliveryCount[aIndex];
end;


// Use aCount: Integer, instead of Word, since we don't want to get Range check error exception
procedure TKMHouse.SetWareDemandsClosing(aIndex: Integer; aCount: Integer);
begin
  fWareDemandsClosing[aIndex] := EnsureRange(aCount, 0, High(Word));
end;


// Use Result Integer, instead of Word, since we don't want to get Range check error exception in the setter
function TKMHouse.GetWareDemandsClosing(aIndex: Integer): Integer;
begin
  Result := fWareDemandsClosing[aIndex];
end;


//Get delivery mode, used for some checks in 'ShouldAbandonDeliveryXX'
//aImmidiate - do we want to have immidiate check (then will get "fake" NewDeliveryMode) or no (real DeliveryMode will be returned)
function TKMHouse.GetDeliveryModeForCheck(aImmidiate: Boolean): TKMDeliveryMode;
begin
  if aImmidiate then
    Result := NewDeliveryMode
  else
    Result := DeliveryMode;
end;


procedure TKMHouse.UpdateDeliveryMode;
var
  oldDeliveryMode: TKMDeliveryMode;
begin
  if fNewDeliveryMode = fDeliveryMode then
    Exit;

  CheckTakeOutDeliveryMode;

  fUpdateDeliveryModeOnTick := 0;
  oldDeliveryMode := fDeliveryMode;
  fDeliveryMode := fNewDeliveryMode;
  gScriptEvents.ProcHouseDeliveryModeChanged(Self, oldDeliveryMode, fDeliveryMode);
  gLog.LogDelivery('DeliveryMode updated to ' + IntToStr(Ord(fDeliveryMode)));
end;


//Set NewDelivery mode. Its going to become a real delivery mode few ticks later
procedure TKMHouse.SetNewDeliveryMode(aValue: TKMDeliveryMode);
begin
  fNewDeliveryMode := aValue;

  fUpdateDeliveryModeOnTick := fTick + UPDATE_DELIVERY_MODE_DELAY;
  gLog.LogDelivery('NewDeliveryMode set to ' + IntToStr(Ord(fNewDeliveryMode)));
end;


procedure TKMHouse.SetNextDeliveryMode;
begin
  SetNewDeliveryMode(TKMDeliveryMode((Ord(fNewDeliveryMode) + 3 - 1) mod 3)); // We use opposite order for legacy support
end;


procedure TKMHouse.SetPrevDeliveryMode;
begin
  SetNewDeliveryMode(TKMDeliveryMode((Ord(fNewDeliveryMode) + 1) mod 3)); // We use opposite order for legacy support
end;


// Set delivery mdoe immidiately
procedure TKMHouse.SetDeliveryModeInstantly(aValue: TKMDeliveryMode);
begin
  fNewDeliveryMode := aValue;
  UpdateDeliveryMode;
end;


function TKMHouse.AllowDeliveryModeChange: Boolean;
begin
  Result := gRes.Houses[fType].AcceptsWares;
end;


procedure TKMHouse.IssueResourceDepletedMsg;
var
  msgID: Word;
begin
  msgID := GetResourceDepletedMessageId;
  Assert(msgID <> 0, gRes.Houses[HouseType].HouseName + ' resource can''t be depleted');

  ShowMsg(msgID);
  ResourceDepleted := True;
end;


function TKMHouse.GetIsSelectable: Boolean;
begin
  Result := not IsDestroyed;
end;


function TKMHouse.GetResourceDepletedMessageId: Word;
begin
  Result := 0;
  case HouseType of
    htQuarry:       Result := TX_MSG_STONE_DEPLETED;
    htCoalMine:     Result := TX_MSG_COAL_DEPLETED;
    htIronMine:     Result := TX_MSG_IRON_DEPLETED;
    htGoldMine:     Result := TX_MSG_GOLD_DEPLETED;
    htWoodcutters:  if TKMHouseWoodcutters(Self).WoodcutterMode = wmPlant then
                      Result := TX_MSG_WOODCUTTER_PLANT_DEPLETED
                    else
                      Result := TX_MSG_WOODCUTTER_DEPLETED;
    htFishermans:   if not gTerrain.CanFindFishingWater(PointBelowEntrance, gRes.Units[utFisher].MiningRange) then
                      Result := TX_MSG_FISHERMAN_TOO_FAR
                    else
                      Result := TX_MSG_FISHERMAN_CANNOT_CATCH;
  end;
end;


//Check if we should abandon delivery to this house
function TKMHouse.ShouldAbandonDeliveryTo(aWareType: TKMWareType): Boolean;
begin
  Result := DeliveryMode <> dmDelivery;
end;


procedure TKMHouse.ShowMsg(aTextID: Integer);
begin
  if Assigned(fOnShowGameMessage) then
    fOnShowGameMessage(mkHouse, aTextID, Entrance, UID, Owner);
end;


//Check if we should abandon delivery from this house
function TKMHouse.ShouldAbandonDeliveryFrom(aWareType: TKMWareType; aImmidiateCheck: Boolean = False): Boolean;
begin
  Result := not WareOutputAvailable(aWareType, 1);
end;


//Check if we should abandon delivery from this house to aToHouse (used in Store only for now)
function TKMHouse.ShouldAbandonDeliveryFromTo(aToHouse: TKMHouse; aWareType: TKMWareType; aImmidiateCheck: Boolean): Boolean;
begin
  Result := False;
end;


{Returns the closest cell of the house to aPos}
function TKMHouse.GetClosestCell(const aPos: TKMPoint): TKMPoint;
var
  list: TKMPointList;
begin
  Result := KMPOINT_ZERO;
  list := TKMPointList.Create;
  try
    GetListOfCellsWithin(list);
    if not list.GetClosest(aPos, Result) then
      raise Exception.Create('Could not find closest house cell');
  finally
    list.Free;
  end;
end;


// Return distance from aPos to the closest house tile
function TKMHouse.GetDistance(const aPos: TKMPoint): Single;
var
  I, K: Integer;
  loc: TKMPoint;
  HA: TKMHouseArea;
begin
  Result := MaxSingle;
  loc := fPosition;
  HA := gRes.Houses[fType].BuildArea;

  for I := max(loc.Y - 3, 1) to loc.Y do
  for K := max(loc.X - 2, 1) to min(loc.X + 1, gTerrain.MapX) do
  if HA[I - loc.Y + 4, K - loc.X + 3] <> 0 then
    Result := Min(Result, KMLength(aPos, KMPoint(K, I)));
end;


//Check if house is within reach of given Distance (optimized version for PathFinding)
//Check precise distance when we are close enough
function TKMHouse.InReach(const aPos: TKMPoint; aDistance: Single): Boolean;
begin
  //+6 is the worst case with the barracks, distance from fPosition to top left tile of house could be > 5
  if KMLengthDiag(aPos, fPosition) >= aDistance + 6 then
    Result := False //We are sure they are not close enough to the house
  else
    //We need to perform a precise check
    Result := GetDistance(aPos) <= aDistance;
end;


procedure TKMHouse.GetListOfCellsAround(aCells: TKMPointDirList; aPassability: TKMTerrainPassability);
var
  I, K: Integer;
  loc: TKMPoint;
  HA: TKMHouseArea;

  procedure AddLoc(X,Y: Word; Dir: TKMDirection);
  begin
    //Check that the passabilty is correct, as the house may be placed against blocked terrain
    if gTerrain.CheckPassability(KMPoint(X,Y), aPassability) then
      aCells.Add(KMPointDir(X, Y, Dir));
  end;

begin
  aCells.Clear;
  loc := fPosition;
  HA := gRes.Houses[fType].BuildArea;

  for I := 1 to 4 do for K := 1 to 4 do
  if HA[I,K] <> 0 then
  begin
    if (I = 1) or (HA[I-1,K] = 0) then
      AddLoc(loc.X + K - 3, loc.Y + I - 4 - 1, dirS); //Above
    if (I = 4) or (HA[I+1,K] = 0) then
      AddLoc(loc.X + K - 3, loc.Y + I - 4 + 1, dirN); //Below
    if (K = 4) or (HA[I,K+1] = 0) then
      AddLoc(loc.X + K - 3 + 1, loc.Y + I - 4, dirW); //FromRight
    if (K = 1) or (HA[I,K-1] = 0) then
      AddLoc(loc.X + K - 3 - 1, loc.Y + I - 4, dirE); //FromLeft
  end;
end;


procedure TKMHouse.GetListOfCellsWithin(aCells: TKMPointList);
var
  I, K: Integer;
  loc: TKMPoint;
  houseArea: TKMHouseArea;
begin
  aCells.Clear;
  loc := fPosition;
  houseArea := gRes.Houses[fType].BuildArea;

  for I := Max(loc.Y - 3, 1) to loc.Y do
    for K := Max(loc.X - 2, 1) to Min(loc.X + 1, gTerrain.MapX) do
      if houseArea[I - loc.Y + 4, K - loc.X + 3] <> 0 then
        aCells.Add(KMPoint(K, I));
end;


procedure TKMHouse.GetListOfGroundVisibleCells(aCells: TKMPointTagList);
var
  I, K, ground: Integer;
  loc: TKMPoint;
  groundVisibleArea: TKMHouseArea;
begin
  aCells.Clear;
  loc := fPosition;
  groundVisibleArea := gRes.Houses[fType].GroundVisibleArea;

  for I := Max(loc.Y - 3, 1) to loc.Y do
    for K := Max(loc.X - 2, 1) to Min(loc.X + 1, gTerrain.MapX) do
    begin
      ground := groundVisibleArea[I - loc.Y + 4, K - loc.X + 3];
      if ground <> 0 then
        aCells.Add(KMPoint(K, I), ground);
    end;
end;


function TKMHouse.GetRandomCellWithin: TKMPoint;
var
  cells: TKMPointList;
  success: Boolean;
begin
  cells := TKMPointList.Create;
  GetListOfCellsWithin(cells);
  success := cells.GetRandom(Result);
  Assert(success);
  cells.Free;
end;


function TKMHouse.HitTest(X, Y: Integer): Boolean;
begin
  Result := (X-fPosition.X+3 in [1..4]) and
            (Y-fPosition.Y+4 in [1..4]) and
            (gRes.Houses[fType].BuildArea[Y-fPosition.Y+4, X-fPosition.X+3] <> 0);
end;


function TKMHouse.GetHasWorker: Boolean;
begin
  Result := fWorker <> nil;
end;


function TKMHouse.GetHealth:word;
begin
  Result := max(fBuildingProgress - fDamage, 0);
end;


function TKMHouse.GetInstance: TKMHouse;
begin
  Result := Self;
end;


function TKMHouse.GetPositionForDisplayF: TKMPointF;
begin
  Result := Entrance.ToFloat;
end;


function TKMHouse.GetPositionF: TKMPointF;
begin
  Result := Entrance.ToFloat;
end;


function TKMHouse.GetBuildWoodDelivered: Byte;
begin
  case fBuildState of
    hbsStone,
    hbsDone: Result := gRes.Houses[fType].WoodCost;
    hbsWood: Result := fBuildSupplyWood+Ceil(fBuildingProgress/50);
    else      Result := 0;
  end;
end;


function TKMHouse.GetBuildStoneDelivered: Byte;
begin
  case fBuildState of
    hbsDone:  Result := gRes.Houses[fType].StoneCost;
    hbsWood:  Result := fBuildSupplyStone;
    hbsStone: Result := fBuildSupplyStone+Ceil(fBuildingProgress/50)-gRes.Houses[fType].WoodCost;
    else       Result := 0;
  end;
end;


function TKMHouse.GetBuildResourceDelivered: Byte;
begin
  Result := GetBuildWoodDelivered + GetBuildStoneDelivered;
end;


function TKMHouse.GetBuildResDeliveredPercent: Single;
begin
  Result := GetBuildResourceDelivered / (gRes.Houses[fType].WoodCost + gRes.Houses[fType].StoneCost);
end;


// Increase building progress of house. When it reaches some point Stoning replaces Wooding
// and then it's done and house should be finalized
// Keep track on stone/wood reserve here as well
procedure TKMHouse.IncBuildingProgress;
begin
  if IsComplete then Exit;

  SetIsReadyToBeBuilt(True);

  if (fBuildState = hbsWood) and (fBuildReserve = 0) then
  begin
    Dec(fBuildSupplyWood);
    Inc(fBuildReserve, 50);
  end;
  if (fBuildState = hbsStone) and (fBuildReserve = 0) then
  begin
    Dec(fBuildSupplyStone);
    Inc(fBuildReserve, 50);
  end;

  Inc(fBuildingProgress, 5); //is how many effort was put into building nevermind applied damage
  Dec(fBuildReserve, 5); //This is reserve we build from

  if (fBuildState = hbsWood)
    and (fBuildingProgress = gRes.Houses[fType].WoodCost*50) then
    fBuildState := hbsStone;

  if (fBuildState = hbsStone)
    and (fBuildingProgress - gRes.Houses[fType].WoodCost*50 = gRes.Houses[fType].StoneCost*50) then
  begin
    fBuildState := hbsDone;
    gHands[Owner].Stats.HouseEnded(fType);
    SetIsReadyToBeBuilt(False);
    Activate(True);
    //House was damaged while under construction, so set the repair mode now it is complete
    if (fDamage > 0) and BuildingRepair then
      gHands[Owner].Constructions.RepairList.AddHouse(Self);

    gScriptEvents.ProcHouseBuilt(Self); //At the end since it could destroy this house
  end;
end;


function TKMHouse.MaxHealth: Word;
begin
  if fBuildState = hbsNoGlyph then
    Result := 0
  else
    Result := gRes.Houses[fType].MaxHealth;
end;


procedure TKMHouse.OwnerUpdate(aOwner: TKMHandID; aMoveToNewOwner: Boolean = False);
begin
  if aMoveToNewOwner and (Owner <> aOwner) then
  begin
    Assert(gGameParams.Mode = gmMapEd); // Allow to move existing House directly only in MapEd
    gHands[Owner].Houses.DeleteHouseFromList(Self);
    gHands[aOwner].Houses.AddHouseToList(Self);
  end;
  Owner := aOwner;
end;


//Add damage to the house, positive number
procedure TKMHouse.AddDamage(aAmount: Word; aAttacker: TObject; aIsEditor: Boolean = False);
var
  attackerHand: TKMHandID;
begin
  if IsDestroyed then
    Exit;

  //(NoGlyph houses MaxHealth = 0, they get destroyed instantly)
  fDamage := Math.min(fDamage + aAmount, MaxHealth);
  if IsComplete then
  begin
    if BuildingRepair then
      gHands[Owner].Constructions.RepairList.AddHouse(Self);

    //Update fire if the house is complete
    UpdateDamage;
  end;

  if gGameParams.Mode <> gmMapEd then
  begin
    //Let AI and script know when the damage is already applied, so they see actual state
    gHands[Owner].AI.HouseAttackNotification(Self, TKMUnitWarrior(aAttacker));
    if fIsDestroyed then Exit; //Script event might destroy this house

    if aAttacker <> nil then
      attackerHand := TKMUnitWarrior(aAttacker).Owner
    else
      attackerHand := HAND_NONE;

    //Properly release house assets
    //Do not remove house in Editor just yet, mapmaker might increase the hp again
    if (GetHealth = 0) and not aIsEditor then
      Demolish(attackerHand);
  end;
end;


//Add repair to the house
procedure TKMHouse.AddRepair(aAmount: Word = 5);
var
  oldDmg: Integer;
begin
  oldDmg := fDamage;
  fDamage := EnsureRange(fDamage - aAmount, 0, High(Word));
  UpdateDamage;

  if gGameParams.Mode <> gmMapEd then
    gScriptEvents.ProcHouseRepaired(Self, oldDmg - fDamage, fDamage);
end;


//Update house damage animation
procedure TKMHouse.UpdateDamage;
var
  dmgLevel: Word;
begin
  dmgLevel := MaxHealth div 8; //There are 8 fire places for each house, so the increment for each fire level is Max_Health / 8
  CurrentAction.SubActionRem([haFire1, haFire2, haFire3, haFire4, haFire5, haFire6, haFire7, haFire8]);
  if fDamage > 0 * dmgLevel then CurrentAction.SubActionAdd([haFire1]);
  if fDamage > 1 * dmgLevel then CurrentAction.SubActionAdd([haFire2]);
  if fDamage > 2 * dmgLevel then CurrentAction.SubActionAdd([haFire3]);
  if fDamage > 3 * dmgLevel then CurrentAction.SubActionAdd([haFire4]);
  if fDamage > 4 * dmgLevel then CurrentAction.SubActionAdd([haFire5]);
  if fDamage > 5 * dmgLevel then CurrentAction.SubActionAdd([haFire6]);
  if fDamage > 6 * dmgLevel then CurrentAction.SubActionAdd([haFire7]);
  if fDamage > 7 * dmgLevel then CurrentAction.SubActionAdd([haFire8]);
  //House gets destroyed in UpdateState loop
end;


procedure TKMHouse.SetBuildingRepair(aValue: Boolean);
begin
  fBuildingRepair := aValue;

  if fBuildingRepair then
  begin
    if IsComplete and IsDamaged and not IsDestroyed then
      gHands[Owner].Constructions.RepairList.AddHouse(Self);
  end
  else
    //Worker checks on house and will cancel the walk if Repair is turned off
    //RepairList removes the house automatically too
end;


procedure TKMHouse.SetIsClosedForWorker(aIsClosed: Boolean);
begin
  if fIsClosedForWorker = aIsClosed then Exit; // Nothing to do. Do not count house closed for worker in stats again and again

  fIsClosedForWorker := aIsClosed;

  if not gGameParams.IsMapEditor then
    gHands[Owner].Stats.HouseClosed(aIsClosed, fType);
end;


// Set if house is ready to build
// possible values during house lifecycle:
// False -> True (rdy to be built) -> False (building complete or house was destroyed)
procedure TKMHouse.SetIsReadyToBeBuilt(aIsReadyToBeBuilt: Boolean);
begin
  if fIsReadyToBeBuilt = aIsReadyToBeBuilt then Exit; // Nothing to update

  fIsReadyToBeBuilt := aIsReadyToBeBuilt;

  if fIsReadyToBeBuilt then
    // Construction started
    gHands[Owner].Stats.HouseRdyToBeBuilt(fType)
  else
    // Construction completed
    gHands[Owner].Stats.HouseBuildEnded(fType);
end;


function TKMHouse.CanHasWorker: Boolean;
begin
  if Self = nil then Exit(False);
  
  Result := gRes.Houses[fType].CanHasWorker;
end;


function TKMHouse.IsStone: Boolean;
begin
  Result := fBuildState = hbsStone;
end;


{Check if house is completely built, nevermind the damage}
function TKMHouse.IsComplete: Boolean;
begin
  Result := fBuildState = hbsDone;
end;


{Check if house is damaged}
function TKMHouse.IsDamaged: Boolean;
begin
  Result := fDamage <> 0;
end;


procedure TKMHouse.SetState(aState: TKMHouseState);
begin
  CurrentAction.State := aState;
end;


procedure TKMHouse.SetWorker(aWorker: Pointer);
begin
  if Self = nil then Exit;

  gHands.CleanUpUnitPointer( TKMUnit(fWorker) );

  if aWorker <> nil then
    fWorker := TKMUnit(aWorker).GetPointer();
end;

function TKMHouse.IsWorkerHungry: Boolean;
begin
  Result := TKMUnit(fWorker).IsHungry;
end;

function TKMHouse.GetState: TKMHouseState;
begin
  Result := CurrentAction.State;
end;


function TKMHouse.GetWareInArray: TKMByteArray;
var
  I, iOffset: Integer;
begin
  SetLength(Result, Length(fWareIn));
  iOffset := Low(fWareIn) - Low(Result);
  for I := Low(Result) to High(Result) do
    Result[I] := fWareIn[I + iOffset];
end;


function TKMHouse.GetWareOutArray: TKMByteArray;
var
  I, iOffset: Integer;
begin
  SetLength(Result, Length(fWareOut));
  iOffset := Low(fWareOut) - Low(Result);
  for I := Low(Result) to High(Result) do
    Result[I] := fWareOut[I + iOffset];
end;


function TKMHouse.GetWareOutPoolArray: TKMByteArray;
var
  I: Integer;
begin
  SetLength(Result, Length(fWareOutPool));
  for I := Low(Result) to High(Result) do
    Result[I] := fWareOutPool[I];
end;


// Check if house is placed mostly on snow
procedure TKMHouse.CheckOnSnow;
var
  I: Integer;
  snowTiles, noSnowTiles: Integer;
  cells: TKMPointTagList;
begin
  cells := TKMPointTagList.Create;

  GetListOfGroundVisibleCells(cells);

  snowTiles := 0;
  noSnowTiles := 0;
  for I := 0 to cells.Count - 1 do
    if gTerrain.TileIsSnow(cells[I].X, cells[I].Y) then
      Inc(snowTiles, cells.Tag[I])
    else
      Inc(noSnowTiles, cells.Tag[I]);

  fIsOnSnow := snowTiles > noSnowTiles;

  cells.Free;
end;


// How much resources house has in Input
function TKMHouse.CheckWareIn(aWare: TKMWareType): Word;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to 4 do
    if (aWare = gRes.Houses[fType].WareInput[I]) or (aWare = wtAll) then
      Inc(Result, ResIn[I]);
end;


// How much resources house has in Output
function TKMHouse.CheckWareOut(aWare: TKMWareType): Word;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to 4 do
    if (aWare = gRes.Houses[fType].WareOutput[I]) or (aWare = wtAll) then
      Inc(Result, fWareOut[I]);
end;


// Check amount of placed order for given ID
function TKMHouse.GetWareOrder(aID: Byte): Integer;
begin
  Result := fWareOrder[aID];
end;


//Input value is integer because we might get a -100 order from outside and need to fit it to range
//properly
procedure TKMHouse.SetWareOrder(aID: Byte; aValue: Integer);
//var
//  I: Integer;
//  TotalDesired: Integer;
begin
  fWareOrder[aID] := EnsureRange(aValue, 0, MAX_WARES_ORDER);

  //Calculate desired production ratio (so that we are not affected by fWareOrder which decreases till 0)
//  TotalDesired := fWareOrder[1] + fWareOrder[2] + fWareOrder[3] + fWareOrder[4];
//  for I := 1 to 4 do
//    fWareOrderDesired[I] := fWareOrder[I] / TotalDesired;

  fNeedIssueOrderCompletedMsg := False;
  fOrderCompletedMsgIssued := False;
end;


//Select order we will be making
//Order picking in sequential, so that if orders for 1st = 6 and for 2nd = 2
//then the production will go like so: 12121111
function TKMHouse.PickOrder: Byte;
var
  I, resI: Integer;
  ware: TKMWareType;
//  BestBid: Single;
//  TotalLeft: Integer;
//  LeftRatio: array [1..4] of Single;
begin
  Result := 0;

  if WARFARE_ORDER_SEQUENTIAL then
    for I := 0 to 3 do
    begin
      resI := ((fLastOrderProduced + I) mod 4) + 1; //1..4
      ware := gRes.Houses[fType].WareOutput[resI];
      if (WareOrder[resI] > 0) //Player has ordered some of this
      and (CheckWareOut(ware) < MAX_WARES_IN_HOUSE) //Output of this is not full
      //Check we have wares to produce this weapon. If both are the same type check > 1 not > 0
      and ((WARFARE_COSTS[ware,1] <> WARFARE_COSTS[ware,2]) or (CheckWareIn(WARFARE_COSTS[ware,1]) > 1))
      and ((WARFARE_COSTS[ware,1] = wtNone) or (CheckWareIn(WARFARE_COSTS[ware,1]) > 0))
      and ((WARFARE_COSTS[ware,2] = wtNone) or (CheckWareIn(WARFARE_COSTS[ware,2]) > 0)) then
      begin
        Result := resI;
        fLastOrderProduced := resI;
        Break;
      end;
    end;

//  if WARFARE_ORDER_PROPORTIONAL then
//  begin
//    //See the ratio between items that were made (since last order amount change)
//    TotalLeft := fWareOrder[1] + fWareOrder[2] + fWareOrder[3] + fWareOrder[4];
//    for I := 1 to 4 do
//      LeftRatio[I] := fWareOrder[I] / TotalLeft;
//
//    //Left   Desired
//    //0.5    0.6
//    //0.3    0.3
//    //0.2    0.1
//
//    //Find order that which production ratio is the smallest
//    BestBid := -MaxSingle;
//    for I := 1 to 4 do
//    if (WareOrder[I] > 0) then //Player has ordered some of this
//    begin
//      Ware := gRes.Houses[fType].WareOutput[I];
//
//      if (CheckWareOut(Ware) < MAX_WARES_IN_HOUSE) //Output of this is not full
//      //Check we have enough wares to produce this weapon. If both are the same type check > 1 not > 0
//      and ((WarfareCosts[Ware,1] <> WarfareCosts[Ware,2]) or (CheckWareIn(WarfareCosts[Ware,1]) > 1))
//      and ((WarfareCosts[Ware,1] = wtNone) or (CheckWareIn(WarfareCosts[Ware,1]) > 0))
//      and ((WarfareCosts[Ware,2] = wtNone) or (CheckWareIn(WarfareCosts[Ware,2]) > 0))
//      and (LeftRatio[I] - fWareOrderDesired[I] > BestBid) then
//      begin
//        Result := I;
//        BestBid := LeftRatio[Result] - fWareOrderDesired[Result];
//      end;
//    end;
//  end;

  if Result <> 0 then
  begin
    Dec(fWareOrder[Result]);
    fNeedIssueOrderCompletedMsg := True;
    fOrderCompletedMsgIssued := False;
  end
  else
    //Check all orders are actually finished (input resources might be empty)
    if  (WareOrder[1] = 0) and (WareOrder[2] = 0)
    and (WareOrder[3] = 0) and (WareOrder[4] = 0) then
      if fNeedIssueOrderCompletedMsg then
      begin
        fNeedIssueOrderCompletedMsg := False;
        fOrderCompletedMsgIssued := True;
        ShowMsg(TX_MSG_ORDER_COMPLETED);
      end;
end;


// Check if house has enough resource supply to be built depending on it's state
function TKMHouse.CheckResToBuild: Boolean;
begin
  case fBuildState of
    hbsWood:   Result := (fBuildSupplyWood > 0) or (fBuildReserve > 0);
    hbsStone:  Result := (fBuildSupplyStone > 0) or (fBuildReserve > 0);
  else
    Result := False;
  end;
end;


function TKMHouse.GetMaxInWare: Word;
begin
  //todo: This belongs to gRes.Houses[]
  if fType in [htStore, htBarracks, htMarket] then
    Result := High(Word)
  else
    Result := MAX_WARES_IN_HOUSE; //All other houses can only stock 5 for now
end;


procedure TKMHouse.HouseDemandWasClosed(aWare: TKMWareType; aDeleteCanceled: Boolean);
begin
  if Self = nil then Exit;

  if TryDecWareDelivery(aWare, aDeleteCanceled) then
    // Update demands, since our DeliveryCount was changed
    // Maybe we need more wares to order
    UpdateDemands;
end;


function TKMHouse.TryDecWareDelivery(aWare: TKMWareType; aDeleteCanceled: Boolean): Boolean;
var
  I: Integer;
begin
  Result := False;
  if Self = nil then Exit;

  for I := 1 to 4 do
    if aWare = gRes.Houses[fType].WareInput[I] then
    begin
      // Do not decrease DeliveryCount, if demand delete was cancelled (demand closing was not possible, f.e. when serf enters the house)
      // thus serf brought ware to the house and we should not decrease delivery count in that case here
      // (but it will be decreased anyway in the WareAddToIn for market)
      if not aDeleteCanceled then
        WareDeliveryCnt[I] := WareDeliveryCnt[I] - 1;

      WareDemandsClosing[I] := WareDemandsClosing[I] - 1;
      Exit(True);
    end;
end;


//Maybe it's better to rule out In/Out? No, it is required to separate what can be taken out of the house and what not.
//But.. if we add "Evacuate" button to all house the separation becomes artificial..
procedure TKMHouse.WareAddToIn(aWare: TKMWareType; aCount: Integer = 1; aFromStaticScript: Boolean = False);
var
  I, ordersRemoved: Integer;
begin
  Assert(aWare <> wtNone);

  for I := 1 to 4 do
    if aWare = gRes.Houses[fType].WareInput[I] then
    begin
      //Don't allow the static script to overfill houses
      if aFromStaticScript then
        aCount := EnsureRange(aCount, 0, GetMaxInWare - fWareIn[I]);
      //WareDeliveryCnt stay same, because corresponding demand will be closed
      ResIn[I] := ResIn[I] + aCount;
      if aFromStaticScript then
      begin
        WareDeliveryCnt[I] := WareDeliveryCnt[I] + aCount;
        ordersRemoved := gHands[Owner].Deliveries.Queue.TryRemoveDemand(Self, aWare, aCount);
        WareDeliveryCnt[I] := WareDeliveryCnt[I] - ordersRemoved;
      end;
    end;
end;


procedure TKMHouse.WareAddToOut(aWare: TKMWareType; const aCount:integer=1);
var
  I, p, count: Integer;
begin
  if aWare = wtNone then
    exit;

  for I := 1 to 4 do
    if aWare = gRes.Houses[fType].WareOutput[I] then
    begin
      ResOut[I] := ResOut[I] + aCount;

      if gRes.Houses[fType].IsWorkshop and (aCount > 0) then
      begin
        count := aCount;
        for p := 0 to 19 do
          if fWareOutPool[p] = 0 then
          begin
            fWareOutPool[p] := I;
            Dec(count);
            if count = 0 then
              Break;
          end;
      end;

      gHands[Owner].Deliveries.Queue.AddOffer(Self, aWare, aCount);
    end;
end;


procedure TKMHouse.WareAddToEitherFromScript(aWare: TKMWareType; aCount: Integer);
var
  I: Integer;
begin
  for I := 1 to 4 do
  begin
    //No range checking required as WareAddToIn does that
    //If WareCanAddToIn, add it immediately and exit (e.g. store)
    if WareCanAddToIn(aWare) or (aWare = gRes.Houses[fType].WareInput[I]) then
    begin
      WareAddToIn(aWare, aCount, True);
      Exit;
    end;
    //Don't allow output to be overfilled from script. This is not checked
    //in WareAddToOut because e.g. stonemason is allowed to overfill it slightly)
    if (aWare = gRes.Houses[fType].WareOutput[I]) and (fWareOut[I] < 5) then
    begin
      aCount := Min(aCount, 5 - fWareOut[I]);
      WareAddToOut(aWare, aCount);
      Exit;
    end;
  end;
end;


// Add resources to building process
// aCount - number of materials to add or remove if negative value is specified
procedure TKMHouse.WareAddToBuild(aWare: TKMWareType; aCount: Integer = 1);
begin
  // If there are some wares or build progress update rdy to be built flag of the house
  if (fBuildingProgress > 0) or (fBuildSupplyWood > 0) or (fBuildSupplyStone > 0) then
    SetIsReadyToBeBuilt(True);

  case aWare of
    wtTimber:  fBuildSupplyWood := EnsureRange(fBuildSupplyWood + aCount, 0, gRes.Houses[fType].WoodCost);
    wtStone:   fBuildSupplyStone := EnsureRange(fBuildSupplyStone + aCount, 0, gRes.Houses[fType].StoneCost);
  else
    raise ELocError.Create('WIP house is not supposed to receive ' + gRes.Wares[aWare].Title + ', right?', fPosition);
  end;
end;


function TKMHouse.WareCanAddToIn(aWare: TKMWareType): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 1 to 4 do
    if aWare = gRes.Houses[fType].WareInput[I] then
      Result := True;
end;


function TKMHouse.WareCanAddToOut(aWare: TKMWareType): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 1 to 4 do
    if aWare = gRes.Houses[fType].WareOutput[I] then
      Result := True;
end;


function TKMHouse.CanHaveWareType(aWare: TKMWareType): Boolean;
begin
  Result := WareCanAddToIn(aWare) or WareCanAddToOut(aWare);
end;


function TKMHouse.GetWareIn(aI: Byte): Word;
begin
  Result := fWareIn[aI];
end;


function TKMHouse.GetWareOut(aI: Byte): Word;
begin
  Result := fWareOut[aI];
end;


function TKMHouse.GetWareInLocked(aI: Byte): Word;
begin
  Result := 0; //By default we do not lock any In res
end;


procedure TKMHouse.SetWareInManageTakeOutDeliveryMode(aWare: TKMWareType; aCntChange: Integer);
begin
  //In case we brought smth to house with TakeOut delivery mode,
  //then we need to add it to offer
  //Usually it can happens when we changed delivery mode while serf was going inside house
  //and his delivery was not cancelled, but resource was not in the house yet
  //then it was not offered to other houses
  if fDeliveryMode = dmTakeOut then
  begin
    if not (aWare in [wtNone, wtAll, wtWarfare]) and (aCntChange > 0) then
      gHands[Owner].Deliveries.Queue.AddOffer(Self, aWare, aCntChange);
  end;
end;


procedure TKMHouse.SetWareIn(aI: Byte; aValue: Word);
var
  cntChange: Integer;
  W: TKMWareType;
begin
  W := gRes.Houses[fType].WareInput[aI];
  cntChange := aValue - fWareIn[aI];

  SetWareInManageTakeOutDeliveryMode(W, cntChange);

  fWareIn[aI] := aValue;

  if not (W in [wtNone, wtAll, wtWarfare]) and (cntChange <> 0) then
    gScriptEvents.ProcHouseWareCountChanged(Self, W, aValue, cntChange);
end;


procedure TKMHouse.SetWareOut(aI: Byte; aValue: Word);
var
  cntChange: Integer;
  W: TKMWareType;
begin
  W := gRes.Houses[fType].WareOutput[aI];
  cntChange := aValue - fWareOut[aI];

  fWareOut[aI] := aValue;

  if not (W in [wtNone, wtAll, wtWarfare]) and (cntChange <> 0) then
    gScriptEvents.ProcHouseWareCountChanged(Self, W, aValue, cntChange);
end;


function TKMHouse.WareOutputAvailable(aWare: TKMWareType; const aCount: Word): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 1 to 4 do
    if aWare = gRes.Houses[fType].WareOutput[I] then
      Result := fWareOut[I] >= aCount;

  if not Result and (fNewDeliveryMode = dmTakeOut) then
    for I := 1 to 4 do
      if aWare = gRes.Houses[fType].WareInput[I] then
        Result := ResIn[I] - WareInLocked[I] >= aCount;
end;


procedure TKMHouse.WareTake(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False);
begin
  //Range checking is done within WareTakeFromIn and WareTakeFromOut when aFromScript=True
  //Only one will succeed, we don't care which one it is
  WareTakeFromIn(aWare, aCount, aFromScript);
  WareTakeFromOut(aWare, aCount, aFromScript);
end;


// Take resource from Input and order more of that kind if DistributionRatios allow
procedure TKMHouse.WareTakeFromIn(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False);
var
  I, K: Integer;
begin
  Assert(aWare <> wtNone);

  for I := 1 to 4 do
  if aWare = gRes.Houses[fType].WareInput[I] then
  begin
    if aFromScript then
    begin
      //Script might try to take too many
      aCount := EnsureRange(aCount, 0, ResIn[I]);
      gHands[Owner].Stats.WareConsumed(aWare, aCount);
    end;

    //Keep track of how many are ordered
    WareDeliveryCnt[I] := EnsureRange(WareDeliveryCnt[I] - aCount, 0, High(Word));

    Assert(ResIn[I] >= aCount, 'fResourceIn[i] < 0');
    ResIn[I] := ResIn[I] - aCount;
    //Only request a new resource if it is allowed by the distribution of wares for our parent player
    for K := 1 to aCount do
      if WareDeliveryCnt[I] < GetWareDistribution(I) then
      begin
        gHands[Owner].Deliveries.Queue.AddDemand(Self, nil, aWare, 1, dtOnce, diNorm);
        WareDeliveryCnt[I] := WareDeliveryCnt[I] + 1;
      end;
    Exit;
  end;
end;


procedure TKMHouse.WareTakeFromOut(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False);
var
  I, K, p, count: integer;
begin
  Assert(aWare <> wtNone);
  Assert(not(fType in [htStore,htBarracks,htTownHall]));
  for I := 1 to 4 do
  if aWare = gRes.Houses[fType].WareOutput[I] then
  begin
    if aFromScript then
    begin
      aCount := Min(aCount, fWareOut[I]);
      if aCount > 0 then
      begin
        gHands[Owner].Stats.WareConsumed(aWare, aCount);
        gHands[Owner].Deliveries.Queue.RemOffer(Self, aWare, aCount);
      end;
    end;
    Assert(aCount <= fWareOut[I]);

    if gRes.Houses[fType].IsWorkshop and (aCount > 0) then
    begin
      count := aCount;
      for p := 0 to 19 do
        if fWareOutPool[p] = I then
          begin
            fWareOutPool[p] := 0;
            Dec(count);
            if count = 0 then
              Break;
          end;
    end;

    ResOut[I] := ResOut[I] - aCount;
    Exit;
  end;

  // Next part is for take-out mode only
  if fDeliveryMode <> dmTakeOut then Exit;

  // Try to take ware from 'in' queue, if we are in take-out delivery mode
  for I := 1 to 4 do
  if aWare = gRes.Houses[fType].WareInput[I] then
  begin
    if aFromScript then
    begin
      //Script might try to take too many
      aCount := Min(aCount, ResIn[I]);
      if aCount > 0 then
        gHands[Owner].Deliveries.Queue.RemOffer(Self, aWare, aCount);
    end;

    //Keep track of how many are ordered
    WareDeliveryCnt[I] := WareDeliveryCnt[I] - aCount;

    Assert(ResIn[I] >= aCount, 'fResourceIn[i] < 0');
    ResIn[I] := ResIn[I] - aCount;
    //Only request a new resource if it is allowed by the distribution of wares for our parent player
    for K := 1 to aCount do
      if WareDeliveryCnt[I] < GetWareDistribution(I) then
      begin
        gHands[Owner].Deliveries.Queue.AddDemand(Self, nil, aWare, 1, dtOnce, diNorm);
        WareDeliveryCnt[I] := WareDeliveryCnt[I] + 1;
      end;
    Exit;
  end;
end;


function TKMHouse.GetWareDistribution(aID: Byte): Byte;
begin
  Result := gHands[Owner].Stats.WareDistribution[gRes.Houses[fType].WareInput[aID],fType];
end;


procedure TKMHouse.MakeSound;
var
  work: TKMHouseActionType;
  step: Byte;
begin
  if SKIP_SOUND then Exit;

  if CurrentAction = nil then exit; //no action means no sound ;)

  if haWork1 in CurrentAction.SubAction then work := haWork1 else
  if haWork2 in CurrentAction.SubAction then work := haWork2 else
  if haWork3 in CurrentAction.SubAction then work := haWork3 else
  if haWork4 in CurrentAction.SubAction then work := haWork4 else
  if haWork5 in CurrentAction.SubAction then work := haWork5 else
    Exit; //No work is going on

  step := gRes.Houses[fType].Anim[work].Count;
  if step = 0 then Exit;

  step := WorkAnimStep mod step;

  //Do not play sounds if house is invisible to gMySpectator
  //This check is slower so we do it after other Exit checks
  if gMySpectator.FogOfWar.CheckTileRevelation(fPosition.X, fPosition.Y) < 255 then exit;

  case fType of //Various buildings and HouseActions producing sounds
    htSchool:        if (work = haWork5)and(step = 28) then gSoundPlayer.Play(sfxSchoolDing, fPosition); //Ding as the clock strikes 12
    htMill:          if (work = haWork2)and(step = 0) then gSoundPlayer.Play(sfxMill, fPosition);
    htCoalMine:      if (work = haWork1)and(step = 5) then gSoundPlayer.Play(sfxcoalDown, fPosition)
                      else if (work = haWork1)and(step = 24) then gSoundPlayer.Play(sfxCoalMineThud, fPosition,True,0.8)
                      else if (work = haWork2)and(step = 7) then gSoundPlayer.Play(sfxmine, fPosition)
                      else if (work = haWork5)and(step = 1) then gSoundPlayer.Play(sfxcoalDown, fPosition);
    htIronMine:      if (work = haWork2)and(step = 7) then gSoundPlayer.Play(sfxmine, fPosition);
    htGoldMine:      if (work = haWork2)and(step = 5) then gSoundPlayer.Play(sfxmine, fPosition);
    htSawmill:       if (work = haWork2)and(step = 1) then gSoundPlayer.Play(sfxsaw, fPosition);
    htVineyard:      if (work = haWork2)and(step in [1,7,13,19]) then gSoundPlayer.Play(sfxwineStep, fPosition)
                      else if (work = haWork5)and(step = 14) then gSoundPlayer.Play(sfxwineDrain, fPosition,True,1.5)
                      else if (work = haWork1)and(step = 10) then gSoundPlayer.Play(sfxwineDrain, fPosition,True,1.5);
    htBakery:        if (work = haWork3)and(step in [6,25]) then gSoundPlayer.Play(sfxBakerSlap, fPosition);
    htQuarry:         if (work = haWork2)and(step in [4,13]) then gSoundPlayer.Play(sfxQuarryClink, fPosition)
                      else if (work = haWork5)and(step in [4,13,22]) then gSoundPlayer.Play(sfxQuarryClink, fPosition);
    htWeaponSmithy:  if (work = haWork1)and(step in [17,22]) then gSoundPlayer.Play(sfxBlacksmithFire, fPosition)
                      else if (work = haWork2)and(step in [10,25]) then gSoundPlayer.Play(sfxBlacksmithBang, fPosition)
                      else if (work = haWork3)and(step in [10,25]) then gSoundPlayer.Play(sfxBlacksmithBang, fPosition)
                      else if (work = haWork4)and(step in [8,22]) then gSoundPlayer.Play(sfxBlacksmithFire, fPosition)
                      else if (work = haWork5)and(step = 12) then gSoundPlayer.Play(sfxBlacksmithBang, fPosition);
    htArmorSmithy:   if (work = haWork2)and(step in [13,28]) then gSoundPlayer.Play(sfxBlacksmithBang, fPosition)
                      else if (work = haWork3)and(step in [13,28]) then gSoundPlayer.Play(sfxBlacksmithBang, fPosition)
                      else if (work = haWork4)and(step in [8,22]) then gSoundPlayer.Play(sfxBlacksmithFire, fPosition)
                      else if (work = haWork5)and(step in [8,22]) then gSoundPlayer.Play(sfxBlacksmithFire, fPosition);
    htMetallurgists: if (work = haWork3)and(step = 6) then gSoundPlayer.Play(sfxmetallurgists, fPosition)
                      else if (work = haWork4)and(step in [16,20]) then gSoundPlayer.Play(sfxwineDrain, fPosition);
    htIronSmithy:    if (work = haWork2)and(step in [1,16]) then gSoundPlayer.Play(sfxmetallurgists, fPosition)
                      else if (work = haWork3)and(step = 1) then gSoundPlayer.Play(sfxmetallurgists, fPosition)
                      else if (work = haWork3)and(step = 13) then gSoundPlayer.Play(sfxwineDrain, fPosition);
    htWeaponWorkshop:if (work = haWork2)and(step in [1,10,19]) then gSoundPlayer.Play(sfxsaw, fPosition)
                      else if (work = haWork3)and(step in [10,21]) then gSoundPlayer.Play(sfxCarpenterHammer, fPosition)
                      else if (work = haWork4)and(step in [2,13]) then gSoundPlayer.Play(sfxCarpenterHammer, fPosition);
    htArmorWorkshop: if (work = haWork2)and(step in [3,13,23]) then gSoundPlayer.Play(sfxsaw, fPosition)
                      else if (work = haWork3)and(step in [17,28]) then gSoundPlayer.Play(sfxCarpenterHammer, fPosition)
                      else if (work = haWork4)and(step in [10,20]) then gSoundPlayer.Play(sfxCarpenterHammer, fPosition);
    htTannery:       if (work = haWork2)and(step = 5) then gSoundPlayer.Play(sfxLeather, fPosition,True,0.8);
    htButchers:      if (work = haWork2)and(step in [8,16,24]) then gSoundPlayer.Play(sfxButcherCut, fPosition)
                      else if (work = haWork3)and(step in [9,21]) then gSoundPlayer.Play(sfxSausageString, fPosition);
    htSwine:         if ((work = haWork2)and(step in [10,20]))or((work = haWork3)and(step = 1)) then gSoundPlayer.Play(sfxButcherCut, fPosition);
    //htWatchTower:  Sound handled by projectile itself
  end;
end;


procedure TKMHouse.Save(SaveStream: TKMemoryStream);
var
  I: Integer;
  hasAct: Boolean;
begin
  inherited;

  SaveStream.PlaceMarker('House');
  SaveStream.Write(fType, SizeOf(fType));
  SaveStream.Write(fPosition);
  SaveStream.Write(fBuildState, SizeOf(fBuildState));
  SaveStream.Write(fIsReadyToBeBuilt);
  SaveStream.Write(fBuildSupplyWood);
  SaveStream.Write(fBuildSupplyStone);
  SaveStream.Write(fBuildReserve);
  SaveStream.Write(fBuildingProgress, SizeOf(fBuildingProgress));
  SaveStream.Write(fDamage, SizeOf(fDamage));
  SaveStream.Write(TKMUnit(fWorker).UID); // Store UID
  SaveStream.Write(fBuildingRepair);
  SaveStream.Write(Byte(fDeliveryMode));
  SaveStream.Write(Byte(fNewDeliveryMode));
  SaveStream.Write(fUpdateDeliveryModeOnTick);
  SaveStream.Write(fIsClosedForWorker);
  for I := 1 to 4 do SaveStream.Write(fWareIn[I]);
  for I := 1 to 4 do SaveStream.Write(fWareDeliveryCount[I]);
  for I := 1 to 4 do SaveStream.Write(fWareDemandsClosing[I]);
  for I := 1 to 4 do SaveStream.Write(fWareOut[I]);
  for I := 1 to 4 do SaveStream.Write(fWareOrder[I], SizeOf(fWareOrder[I]));
//  for I:=1 to 4 do SaveStream.Write(fWareOrderDesired[I], SizeOf(fWareOrderDesired[I]));

  if gRes.Houses[fType].IsWorkshop then
    SaveStream.Write(fWareOutPool, 20); //todo: Should be SizeOf()

  SaveStream.Write(fLastOrderProduced);
  SaveStream.Write(FlagAnimStep);
  SaveStream.Write(WorkAnimStep);
  SaveStream.Write(fIsOnSnow);
  SaveStream.Write(fSnowStep);
  SaveStream.Write(fIsDestroyed);
  SaveStream.Write(fTimeSinceUnoccupiedReminder);
  SaveStream.Write(fDisableUnoccupiedMessage);
  SaveStream.Write(fNeedIssueOrderCompletedMsg);
  SaveStream.Write(fOrderCompletedMsgIssued);
  hasAct := CurrentAction <> nil;
  SaveStream.Write(hasAct);
  if hasAct then CurrentAction.Save(SaveStream);
  SaveStream.Write(fResourceDepletedMsgIssued);
  SaveStream.Write(DoorwayUse);
  SaveStream.Write(fPlacedOverRoad);
end;


procedure TKMHouse.PostLoadMission;
begin
  //Do nothing, override where needed
end;


procedure TKMHouse.IncAnimStep;
const
  //How much ticks it takes for a house to become completely covered in snow
  SNOW_TIME = 300;
var
  I, K: Integer;
  wasOnSnow: Boolean;
  HA: TKMHouseArea;
begin
  Inc(FlagAnimStep);
  WorkAnimStepPrev := WorkAnimStep;
  Inc(WorkAnimStep);

  if (FlagAnimStep mod 10 = 0) and gGameParams.IsMapEditor then
  begin
    wasOnSnow := fIsOnSnow;
    CheckOnSnow;
    if not wasOnSnow or not fIsOnSnow then
      fSnowStep := 0;
  end;

  if fIsOnSnow and (fSnowStep < 1) then
    fSnowStep := Min(fSnowStep + (1 + Byte(gGameParams.IsMapEditor) * 10) / SNOW_TIME, 1);

  //FlagAnimStep is a sort of counter to reveal terrain once a sec
  if gGameParams.DynamicFOW and (FlagAnimStep mod FOW_PACE = 0) then
  begin
    HA := gRes.Houses[fType].BuildArea;
    //Reveal house from all points it covers
    for I := 1 to 4 do
      for K := 1 to 4 do
        if HA[I,K] <> 0 then
          gHands.RevealForTeam(Owner, KMPoint(fPosition.X + K - 4, fPosition.Y + I - 4), gRes.Houses[fType].Sight, FOG_OF_WAR_INC);
  end;
end;


//Request more wares (if distribution of wares has changed)
//todo: Situation: I have timber set to 5 for the weapons workshop, and no timber in my village.
//      I change timber to 0 for the weapons workshop. My woodcutter starts again and 5 timber is still
//      taken to the weapons workshop because the request doesn't get canceled.
//      Maybe it's possible to cancel the current requests if no serf has taken them yet?
procedure TKMHouse.UpdateDemands;
var
  I: Integer;
  demandsRemoved, plannedToRemove, demandsToChange: Integer;
  resDistribution: Byte;
begin
  for I := 1 to 4 do
  begin
    if (fType = htTownHall) or (gRes.Houses[fType].WareInput[I] in [wtAll, wtWarfare, wtNone]) then Continue;

    resDistribution := GetWareDistribution(I);

    demandsToChange := resDistribution - (WareDeliveryCnt[I] - WareDemandsClosing[I]);

    //Not enough resources ordered, add new demand
    if demandsToChange > 0 then
    begin
      gHands[Owner].Deliveries.Queue.AddDemand(Self, nil, gRes.Houses[fType].WareInput[I], demandsToChange, dtOnce, diNorm);

      WareDeliveryCnt[I] := WareDeliveryCnt[I] + demandsToChange;
    end;

    //Too many resources ordered, attempt to remove demand if nobody has taken it yet
    if demandsToChange < 0 then
    begin
      demandsRemoved := gHands[Owner].Deliveries.Queue.TryRemoveDemand(Self, gRes.Houses[fType].WareInput[I], -demandsToChange, plannedToRemove);

      WareDeliveryCnt[I] := WareDeliveryCnt[I] - demandsRemoved; //Only reduce it by the number that were actually removed
      WareDemandsClosing[I] := WareDemandsClosing[I] + plannedToRemove;
    end;
  end;
end;


function TKMHouse.ObjToString(const aSeparator: String = '|'): String;
var
  I: Integer;
  actStr, resOutPoolStr, workerStr: String;
begin
  if Self = nil then Exit('nil');

  workerStr := 'nil';
  if fWorker <> nil then
    workerStr := TKMUnit(fWorker).ObjToStringShort(' ');

  actStr := 'nil';
  if CurrentAction <> nil then
    actStr := CurrentAction.ObjToString();

  resOutPoolStr := '';
  for I := Low(fWareOutPool) to High(fWareOutPool) do
  begin
    if resOutPoolStr <> '' then
      resOutPoolStr := resOutPoolStr + ',';
    if I = 10 then
      resOutPoolStr := resOutPoolStr + aSeparator;
    resOutPoolStr := resOutPoolStr + IntToStr(fWareOutPool[I]);
  end;


  Result := inherited ObjToString(aSeparator) +
            Format('%sWorker = %s%sAction = %s%sRepair = %s%sIsClosedForWorker = %s%sDeliveryMode = %s%s' +
                   'NewDeliveryMode = %s%sDamage = %d%s' +
                   'BuildState = %s%sBuildSupplyWood = %d%sBuildSupplyStone = %d%sBuildingProgress = %d%sDoorwayUse = %d%s' +
                   'ResIn = %d,%d,%d,%d%sResDeliveryCnt = %d,%d,%d,%d%sResDemandsClosing = %d,%d,%d,%d%sResOut = %d,%d,%d,%d%s' +
                   'WareOrder = %d,%d,%d,%d%sResOutPool = %s',
                   [aSeparator,
                    workerStr, aSeparator,
                    actStr, aSeparator,
                    BoolToStr(fBuildingRepair, True), aSeparator,
                    BoolToStr(fIsClosedForWorker, True), aSeparator,
                    GetEnumName(TypeInfo(TKMDeliveryMode), Integer(fDeliveryMode)), aSeparator,
                    GetEnumName(TypeInfo(TKMDeliveryMode), Integer(fNewDeliveryMode)), aSeparator,
                    fDamage, aSeparator,
                    GetEnumName(TypeInfo(TKMHouseBuildState), Integer(fBuildState)), aSeparator,
                    fBuildSupplyWood, aSeparator,
                    fBuildSupplyStone, aSeparator,
                    fBuildingProgress, aSeparator,
                    DoorwayUse, aSeparator,
                    fWareIn[1], fWareIn[2], fWareIn[3], fWareIn[4], aSeparator,
                    fWareDeliveryCount[1], fWareDeliveryCount[2], fWareDeliveryCount[3], fWareDeliveryCount[4], aSeparator,
                    fWareDemandsClosing[1], fWareDemandsClosing[2], fWareDemandsClosing[3], fWareDemandsClosing[4], aSeparator,
                    fWareOut[1], fWareOut[2], fWareOut[3], fWareOut[4], aSeparator,
                    fWareOrder[1], fWareOrder[2], fWareOrder[3], fWareOrder[4], aSeparator,
                    resOutPoolStr]);
end;


procedure TKMHouse.UpdateState(aTick: Cardinal);
const
  HOUSE_PLAN_SIGHT = 2;
  UPDATE_RDY_TO_BE_BUILT_FREQ = 20; // every 2 sec
var
  I, K: Integer;
  houseUnoccupiedMsgId: Integer;
  HA: TKMHouseArea;
begin
  if not IsComplete then
  begin
    // Update RdyToBeBuilt flag on the house
    // no need to do it often, since its used only for specs (through hand stats)
    if (aTick mod UPDATE_RDY_TO_BE_BUILT_FREQ = 0)
      and not fIsReadyToBeBuilt
      and gHands[Owner].Deliveries.Queue.HasDeliveryTo(Self) then
      SetIsReadyToBeBuilt(True);

    if gGameParams.DynamicFOW and ((aTick + Owner) mod FOW_PACE = 0) then
    begin
      HA := gRes.Houses[fType].BuildArea;
      //Reveal house from all points it covers
      for I := 1 to 4 do
        for K := 1 to 4 do
          if HA[I,K] <> 0 then
            gHands.RevealForTeam(Owner, KMPoint(fPosition.X + K - 4, fPosition.Y + I - 4), HOUSE_PLAN_SIGHT, FOG_OF_WAR_INC);
    end;
    Exit; //Don't update unbuilt houses
  end;

  fTick := aTick;

  //Update delivery mode, if time has come
  if (fUpdateDeliveryModeOnTick = fTick) then
    UpdateDeliveryMode;

  //Show unoccupied message if needed and house belongs to human player and can have worker at all
  //and is not closed for worker and not a barracks
  if not fDisableUnoccupiedMessage and not HasWorker and not fIsClosedForWorker
  and gRes.Houses[fType].CanHasWorker and (fType <> htBarracks) then
  begin
    Dec(fTimeSinceUnoccupiedReminder);
    if fTimeSinceUnoccupiedReminder = 0 then
    begin
      houseUnoccupiedMsgId := gRes.Houses[fType].UnoccupiedMsgId;
      if houseUnoccupiedMsgId <> -1 then // HouseNotOccupMsgId should never be -1
        ShowMsg(houseUnoccupiedMsgId)
      else
        gLog.AddTime('Warning: HouseUnoccupiedMsgId for house type ord=' + IntToStr(Ord(fType)) + ' could not be determined.');
      fTimeSinceUnoccupiedReminder := TIME_BETWEEN_MESSAGES; //Don't show one again until it is time
    end;
  end
  else
    fTimeSinceUnoccupiedReminder := TIME_BETWEEN_MESSAGES;

  if not fIsDestroyed then MakeSound; //Make some sound/noise along the work

  IncAnimStep;
end;


procedure TKMHouse.Paint;
var
  H: TKMHouseSpec;
  progress: Single;
begin
  H := gRes.Houses[fType];
  case fBuildState of
    hbsNoGlyph:; //Nothing
    hbsWood:   begin
                  progress := fBuildingProgress / 50 / H.WoodCost;
                  gRenderPool.AddHouse(fType, fPosition, progress, 0, 0);
                  gRenderPool.AddHouseBuildSupply(fType, fPosition, fBuildSupplyWood, fBuildSupplyStone);
                end;
    hbsStone:  begin
                  progress := (fBuildingProgress / 50 - H.WoodCost) / H.StoneCost;
                  gRenderPool.AddHouse(fType, fPosition, 1, progress, 0);
                  gRenderPool.AddHouseBuildSupply(fType, fPosition, fBuildSupplyWood, fBuildSupplyStone);
                end;
    else        begin
                  //Incase we need to render house at desired step in debug mode
                  if HOUSE_BUILDING_STEP = 0 then
                  begin
                    if fIsOnSnow then
                      gRenderPool.AddHouse(fType, fPosition, 1, 1, fSnowStep)
                    else
                      gRenderPool.AddHouse(fType, fPosition, 1, 1, 0);
                    gRenderPool.AddHouseSupply(fType, fPosition, fWareIn, fWareOut, fWareOutPool);
                    if CurrentAction <> nil then
                      gRenderPool.AddHouseWork(fType, fPosition, CurrentAction.SubAction, WorkAnimStep, WorkAnimStepPrev, gHands[Owner].GameFlagColor);
                  end
                  else
                    gRenderPool.AddHouse(fType, fPosition,
                      Min(HOUSE_BUILDING_STEP * 3, 1),
                      EnsureRange(HOUSE_BUILDING_STEP * 3 - 1, 0, 1),
                      Max(HOUSE_BUILDING_STEP * 3 - 2, 0));
                end;
  end;

  if SHOW_POINTER_DOTS then
    gRenderAux.UnitPointers(fPosition.X + 0.5, fPosition.Y + 1, PointerCount);
end;


{ THouseAction }
constructor TKMHouseAction.Create(aHouse: TKMHouse; aHouseState: TKMHouseState);
begin
  inherited Create;
  fHouse := aHouse;
  SetHouseState(aHouseState);
end;


procedure TKMHouseAction.SetHouseState(aHouseState: TKMHouseState);
begin
  fHouseState := aHouseState;
  case fHouseState of
    hstIdle:   begin
                  SubActionRem([haWork1..haSmoke]); //remove all work attributes
                  SubActionAdd([haIdle]);
                end;
    hstWork:   SubActionRem([haIdle]);
    hstEmpty:  SubActionRem([haIdle]);
  end;
end;


procedure TKMHouseAction.SubActionWork(aActionSet: TKMHouseActionType);
begin
  SubActionRem([haWork1..haWork5]); //Remove all work
  fSubAction := fSubAction + [aActionSet];
  fHouse.WorkAnimStep := 0;
  fHouse.WorkAnimStepPrev := 0;
end;


procedure TKMHouseAction.SubActionAdd(aActionSet: TKMHouseActionSet);
begin
  fSubAction := fSubAction + aActionSet;
end;


procedure TKMHouseAction.SubActionRem(aActionSet: TKMHouseActionSet);
begin
  fSubAction := fSubAction - aActionSet;
end;


procedure TKMHouseAction.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.Write(fHouse.UID);
  SaveStream.Write(fHouseState, SizeOf(fHouseState));
  SaveStream.Write(fSubAction, SizeOf(fSubAction));
end;


procedure TKMHouseAction.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.Read(fHouse, 4);
  LoadStream.Read(fHouseState, SizeOf(fHouseState));
  LoadStream.Read(fSubAction, SizeOf(fSubAction));
end;


procedure TKMHouseAction.SyncLoad;
begin
  if Self = nil then Exit;

  fHouse := gHands.GetHouseByUID(Integer(fHouse));
end;


function TKMHouseAction.ObjToString(const aSeparator: String = ' '): String;
var
  AT: TKMHouseActionType;
  subActStr: string;
begin
  subActStr := '';
  for AT in fSubAction do
  begin
    if subActStr <> '' then
      subActStr := subActStr + ' ';

    subActStr := subActStr + GetEnumName(TypeInfo(TKMHouseActionType), Integer(AT));
  end;

  Result := Format('%sState = %s%sSubAction = [%s]',
                   [aSeparator,
                    GetEnumName(TypeInfo(TKMHouseState), Integer(fHouseState)), aSeparator,
                    subActStr]);
end;


{ TKMHouseTower }
procedure TKMHouseTower.Paint;
var
  fillColor, lineColor: Cardinal;
begin
  inherited;

  if SHOW_ATTACK_RADIUS or (mlTowersAttackRadius in gGameParams.VisibleLayers) then
  begin
    fillColor := $40FFFFFF;
    lineColor := icWhite;
    if gMySpectator.Selected = Self then
    begin
      fillColor := icRed and fillColor;
      lineColor := icCyan;
    end;

    gRenderPool.RenderDebug.RenderTiledArea(Position, RANGE_WATCHTOWER_MIN, RANGE_WATCHTOWER_MAX, GetLength, fillColor, lineColor);
  end;
end;


{ TKMHouseWPoint }
constructor TKMHouseWFlagPoint.Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
begin
  inherited;

  fFlagPoint := PointBelowEntrance;
end;


constructor TKMHouseWFlagPoint.Load(LoadStream: TKMemoryStream);
begin
  inherited;

  LoadStream.CheckMarker('HouseWFlagPoint');
  LoadStream.Read(fFlagPoint);
end;


procedure TKMHouseWFlagPoint.Save(SaveStream: TKMemoryStream);
begin
  inherited;

  SaveStream.PlaceMarker('HouseWFlagPoint');
  SaveStream.Write(fFlagPoint);
end;


function TKMHouseWFlagPoint.IsFlagPointSet: Boolean;
begin
  Result := not KMSamePoint(fFlagPoint, PointBelowEntrance);
end;


procedure TKMHouseWFlagPoint.SetFlagPoint(aFlagPoint: TKMPoint);
var
  oldFlagPoint: TKMPoint;
begin
  oldFlagPoint := fFlagPoint;
  fFlagPoint := GetValidPoint(aFlagPoint);

  if not KMSamePoint(oldFlagPoint, fFlagPoint) then
  begin
    gScriptEvents.ProcHouseFlagPointChanged(Self, oldFlagPoint.X, oldFlagPoint.Y, fFlagPoint.X, fFlagPoint.Y);
  end;
end;


procedure TKMHouseWFlagPoint.ValidateFlagPoint;
begin
  //this will automatically update rally point to valid value
  fFlagPoint := GetValidPoint(fFlagPoint);
end;


function TKMHouseWFlagPoint.GetMaxDistanceToPoint: Integer;
begin
  Result := -1; //Unlimited by default
end;


function TKMHouseWFlagPoint.GetValidPoint(aPoint: TKMPoint): TKMPoint;
var
  L, R: Boolean;
  P: TKMPoint;
begin
  P := PointBelowEntrance;
  if not gTerrain.CheckPassability(P, tpWalk) then
  begin
    L := gTerrain.CheckPassability(KMPointLeft(P), tpWalk);
    R := gTerrain.CheckPassability(KMPointRight(P), tpWalk);
    //Choose random between Left and Right
    if L and R then
      P := KMPoint(P.X + 2*KaMRandom(2{$IFDEF RNG_SPY}, 'TKMHouseWFlagPoint.GetValidPoint'{$ENDIF}) - 1, P.Y) // Offset = +1 or -1
    else
    if L then
      P := KMPointLeft(P)
    else
    if R then
      P := KMPointRight(P)
    else
    begin
      Result := KMPOINT_ZERO;
      Exit;
    end;
  end;

  Result := gTerrain.GetPassablePointWithinSegment(P, aPoint, tpWalk, MaxDistanceToPoint);
end;


function TKMHouseWFlagPoint.ObjToString(const aSeparator: String = '|'): String;
begin
  Result := inherited ObjToString(aSeparator) +
            Format('%sFlagPoint = %s', [aSeparator, fFlagPoint.ToString]);
end;


initialization
begin
  TKMHouseSketchEdit.DummyHouseSketch := TKMHouseSketchEdit.Create;
  TKMHouseSketchEdit.DummyHouseSketch.fEditable := False;
end;

finalization
begin
  FreeAndNil(TKMHouseSketchEdit.DummyHouseSketch);
end;


end.

