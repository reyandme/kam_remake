unit KM_Houses;
{$I KaM_Remake.inc}
interface
uses
  KM_ResHouses, KM_ResWares,
  KM_CommonClasses, KM_CommonTypes, KM_Defaults, KM_Points,
  KM_HandEntity,
  KM_ResTypes;

//Houses are ruled by units, hence they don't know about  TKMUnits

//Everything related to houses is here
type
  TKMDeliveryMode = (dmClosed = 0, dmDelivery = 1, dmTakeOut = 2);

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
  end;


  TKMHouseSketch = class(TKMHandEntityPointer<TKMHouse>)
  private
    fType: TKMHouseType; //House type
    function GetEntrance: TKMPoint;
    function GetPointBelowEntrance: TKMPoint;
  protected
    fPosition: TKMPoint; //House position on map, kinda virtual thing cos it doesn't match with entrance
    function GetPosition: TKMPoint; override;
    constructor Create; overload;
  public
    constructor Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID); overload;

    property HouseType: TKMHouseType read fType;

    property Entrance: TKMPoint read GetEntrance;
    property PointBelowEntrance: TKMPoint read GetPointBelowEntrance;

    function ObjToStringShort(const aSeparator: String = '|'): String; override;

    function IsEmpty: Boolean;
  end;

  //Editable Version of TKMHouseSketch
  //We do not want to allow edit TKMHouse fields, but need to do that for some sketches
  TKMHouseSketchEdit = class(TKMHouseSketch)
  private
    fEditable: Boolean;
  protected
    function GetInstance: TKMHouse; override;
    function GetPositionF: TKMPointF; override;
    procedure SetPositionF(const aPositionF: TKMPointF); override;
  public
    constructor Create;

    procedure Clear;
    procedure CopyTo(var aHouseSketch: TKMHouseSketchEdit);

    procedure SetHouseUID(aUID: Integer);
    procedure SetHouseType(aHouseType: TKMHouseType);
    procedure SetPosition(aPosition: TKMPoint);

    class var DummyHouseSketch: TKMHouseSketchEdit;
  end;


  TKMHouse = class(TKMHouseSketch)
  private
    fBuildSupplyWood: Byte; //How much Wood was delivered to house building site
    fBuildSupplyStone: Byte; //How much Stone was delivered to house building site
    fBuildReserve: Byte; //Take one build supply resource into reserve and "build from it"
    fBuildingProgress: Word; //That is how many efforts were put into building (Wooding+Stoning)
    fDamage: Word; //Damaged inflicted to house

    fTick: Cardinal;
    fHasOwner: Boolean; //which is some TKMUnit
    fBuildingRepair: Boolean; //If on and the building is damaged then labourers will come and repair it

    //Switch between delivery modes: delivery on/off/or make an offer from resources available
    fDeliveryMode: TKMDeliveryMode; // REAL delivery mode - using in game interactions and actual deliveries
    fNewDeliveryMode: TKMDeliveryMode; // Fake, NEW delivery mode, used just for UI. After few tick it will be set as REAL, if there will be no other clicks from player
    // Delivery mode set with small delay (couple of ticks), to avoid occasional clicks on delivery mode button
    fUpdateDeliveryModeOnTick: Cardinal; // Tick, on which we have to update real delivery mode with its NEW value

    fIsClosedForWorker: Boolean; // house is closed for worker. If worker is already occupied it, then leave house

    fResourceIn: array [1..4] of Byte; //Resource count in input
    //Count of the resources we have ordered for the input (used for ware distribution)
    fResourceDeliveryCount: array[1..4] of Word; // = fResourceIn + Demands count
    fResourceOut: array [1..4] of Byte; //Resource count in output
    fResourceOrder: array [1..4] of Word; //If HousePlaceOrders=true then here are production orders
    fResourceOutPool: array[0..19] of Byte;
    fLastOrderProduced: Byte;
//    fResOrderDesired: array [1..4] of Single;

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
    fAllowAllyToView: Boolean;
    fPlacedOverRoad: Boolean; //Is house entrance placed over road

    procedure CheckOnSnow;

    function GetResourceInArray: TKMByteArray;
    function GetResourceOutArray: TKMByteArray;
    function GetResourceOutPoolArray: TKMByteArray;

    procedure MakeSound; virtual; //Swine/stables make extra sounds
    function GetResDistribution(aID: Byte): Byte; //Will use GetRatio from mission settings to find distribution amount
    procedure SetIsClosedForWorker(aIsClosed: Boolean);
    procedure UpdateDeliveryMode;
  protected
    fBuildState: TKMHouseBuildState; // = (hbsGlyph, hbsNoGlyph, hbsWood, hbsStone, hbsDone);
    FlagAnimStep: Cardinal; //Used for Flags and Burning animation
    //WorkAnimStep: Cardinal; //Used for Work and etc.. which is not in sync with Flags
    procedure Activate(aWasBuilt: Boolean); virtual;
    procedure AddDemandsOnActivate(aWasBuilt: Boolean); virtual;
    function GetResOrder(aId: Byte): Integer; virtual;
    function GetResIn(aI: Byte): Word; virtual;
    function GetResOut(aI: Byte): Word; virtual;
    function GetResInLocked(aI: Byte): Word; virtual;
    procedure SetResIn(aI: Byte; aValue: Word); virtual;
    procedure SetResOut(aI: Byte; aValue: Word); virtual;
    procedure SetBuildingRepair(aValue: Boolean);
    procedure SetResOrder(aId: Byte; aValue: Integer); virtual;
    procedure SetNewDeliveryMode(aValue: TKMDeliveryMode); virtual;
    procedure CheckTakeOutDeliveryMode; virtual;
    function GetDeliveryModeForCheck(aImmidiate: Boolean): TKMDeliveryMode;

    procedure SetResourceDeliveryCount(aIndex: Integer; aCount: Word);
    function GetResourceDeliveryCount(aIndex: Integer): Word;

    property ResDeliveryCnt[aIndex: Integer]: Word read GetResourceDeliveryCount write SetResourceDeliveryCount;

    function GetInstance: TKMHouse; override;
    function GetPositionF: TKMPointF; override;
    procedure SetPositionF(const aPositionF: TKMPointF); override;
  public
    CurrentAction: TKMHouseAction; //Current action, withing HouseTask or idle
    WorkAnimStep: Cardinal; //Used for Work and etc.. which is not in sync with Flags
    DoorwayUse: Byte; //number of units using our door way. Used for sliding.
    OnDestroyed: TKMHouseFromEvent;

    constructor Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure SyncLoad; virtual;
    destructor Destroy; override;
    procedure Save(SaveStream: TKMemoryStream); override;

    procedure RemoveHouse;
    procedure DemolishHouse(aFrom: TKMHandID; IsSilent: Boolean = False); virtual;
    property BuildingProgress: Word read fBuildingProgress;

    procedure SetPosition(const aPos: TKMPoint); //Used only by map editor
    procedure OwnerUpdate(aOwner: TKMHandID; aMoveToNewOwner: Boolean = False);

    function GetClosestCell(const aPos: TKMPoint): TKMPoint;
    function GetDistance(const aPos: TKMPoint): Single;
    function InReach(const aPos: TKMPoint; aDistance: Single): Boolean;
    procedure GetListOfCellsAround(Cells: TKMPointDirList; aPassability: TKMTerrainPassability);
    procedure GetListOfCellsWithin(Cells: TKMPointList);
    procedure GetListOfGroundVisibleCells(aCells: TKMPointTagList);
    function GetRandomCellWithin: TKMPoint;
    function HitTest(X, Y: Integer): Boolean;
    property BuildingRepair: Boolean read fBuildingRepair write SetBuildingRepair;
    property PlacedOverRoad: Boolean read fPlacedOverRoad write fPlacedOverRoad;

    property DeliveryMode: TKMDeliveryMode read fDeliveryMode;
    property NewDeliveryMode: TKMDeliveryMode read fNewDeliveryMode write SetNewDeliveryMode;
    procedure SetNextDeliveryMode;
    procedure SetPrevDeliveryMode;
    procedure SetDeliveryModeInstantly(aValue: TKMDeliveryMode);
    function AllowDeliveryModeChange: Boolean;

    procedure IssueResourceDepletedMsg;
    function GetResourceDepletedMessageId: Word;

    property AllowAllyToView: Boolean read fAllowAllyToView write fAllowAllyToView;

    property ResourceDepleted: Boolean read fResourceDepletedMsgIssued write fResourceDepletedMsgIssued;
    property OrderCompletedMsgIssued: Boolean read fOrderCompletedMsgIssued;

    function ShouldAbandonDeliveryTo(aWareType: TKMWareType): Boolean; virtual;
    function ShouldAbandonDeliveryFrom(aWareType: TKMWareType; aImmidiateCheck: Boolean = False): Boolean; virtual;
    function ShouldAbandonDeliveryFromTo(aToHouse: TKMHouse; aWareType: TKMWareType; aImmidiateCheck: Boolean): Boolean; virtual;

    property IsClosedForWorker: Boolean read fIsClosedForWorker write SetIsClosedForWorker;
    property HasOwner: Boolean read fHasOwner write fHasOwner; //There's a citizen who runs this house
    property DisableUnoccupiedMessage: Boolean read fDisableUnoccupiedMessage write fDisableUnoccupiedMessage;
    function GetHealth: Word;
    function GetBuildWoodDelivered: Byte;
    function GetBuildStoneDelivered: Byte;
    function GetBuildResourceDelivered: Byte;
    function GetBuildResDeliveredPercent: Single;

    function IsSelectable: Boolean; override;

    property ResourceInArray: TKMByteArray read GetResourceInArray;
    property ResourceOutArray: TKMByteArray read GetResourceOutArray;
    property ResourceOutPoolArray: TKMByteArray read GetResourceOutPoolArray;

    property BuildingState: TKMHouseBuildState read fBuildState write fBuildState;
    procedure IncBuildingProgress;
    function MaxHealth: Word;
    procedure AddDamage(aAmount: Word; aAttacker: TObject; aIsEditor: Boolean = False);
    procedure AddRepair(aAmount: Word = 5);
    procedure UpdateDamage;

    function IsStone: Boolean;
    function IsComplete: Boolean;
    function IsDamaged: Boolean;
    property IsDestroyed: Boolean read fIsDestroyed;
    property GetDamage: Word read fDamage;

    procedure SetState(aState: TKMHouseState);
    function GetState: TKMHouseState;

    procedure DecResourceDelivery(aWare: TKMWareType); virtual;

    function CheckResIn(aWare: TKMWareType): Word; virtual;
    function CheckResOut(aWare: TKMWareType): Word; virtual;
    function PickOrder: Byte;
    function CheckResToBuild: Boolean;
    function GetMaxInRes: Word;
    procedure ResAddToIn(aWare: TKMWareType; aCount: Integer = 1; aFromScript: Boolean = False); virtual; //override for School and etc..
    procedure ResAddToOut(aWare: TKMWareType; const aCount: Integer = 1);
    procedure ResAddToEitherFromScript(aWare: TKMWareType; aCount: Integer);
    procedure ResAddToBuild(aWare: TKMWareType);
    procedure ResTakeFromIn(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False); virtual;
    procedure ResTakeFromOut(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False); virtual;
    function ResCanAddToIn(aWare: TKMWareType): Boolean; virtual;
    function ResCanAddToOut(aWare: TKMWareType): Boolean;
    function ResOutputAvailable(aWare: TKMWareType; const aCount: Word): Boolean; virtual;
    property ResOrder[aId: Byte]: Integer read GetResOrder write SetResOrder;
    property ResIn[aId: Byte]: Word read GetResIn write SetResIn;
    property ResOut[aId: Byte]: Word read GetResOut write SetResOut;
    property ResInLocked[aId: Byte]: Word read GetResInLocked;

    procedure PostLoadMission; virtual;

    function ObjToString(const aSeparator: String = '|'): String; override;

    procedure IncAnimStep;
    procedure UpdateResRequest;
    procedure UpdateState(aTick: Cardinal);
    procedure Paint; virtual;
  end;


  TKMHouseWFlagPoint = class(TKMHouse)
  private
    fFlagPoint: TKMPoint;
  protected
    procedure SetFlagPoint(aFlagPoint: TKMPoint); virtual;
    function GetFlagPointTexId: Word; virtual; abstract;
    function GetMaxDistanceToPoint: Integer; virtual;
  public
    constructor Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure Save(SaveStream: TKMemoryStream); override;

    property FlagPoint: TKMPoint read fFlagPoint write SetFlagPoint;
    property FlagPointTexId: Word read GetFlagPointTexId;
    property MaxDistanceToPoint: Integer read GetMaxDistanceToPoint;
    function IsFlagPointSet: Boolean;
    procedure ValidateFlagPoint;
    function GetValidPoint(aPoint: TKMPoint): TKMPoint;
  end;

  // SwineStable has unique property - it needs to accumulate some resource before production begins, also special animation
  TKMHouseSwineStable = class(TKMHouse)
  private
    BeastAge: array[1..5]of byte; //Each beasts "age". Once Best reaches age 3+1 it's ready
  public
    constructor Load(LoadStream: TKMemoryStream); override;
    function FeedBeasts: Byte;
    procedure TakeBeast(aID: Byte);
    procedure MakeSound; override;
    procedure Save(SaveStream: TKMemoryStream); override;
    procedure Paint; override;
  end;


  // Storehouse keeps all the resources and flags for them
  TKMHouseStore = class(TKMHouse)
  private
    fWaresCount: array [WARE_MIN .. WARE_MAX] of Word;
    procedure SetWareCnt(aWareType: TKMWareType; aValue: Word);
  protected
    procedure Activate(aWasBuilt: Boolean); override;
  public
    NotAcceptFlag: array [WARE_MIN .. WARE_MAX] of Boolean;
    NotAllowTakeOutFlag: array [WARE_MIN .. WARE_MAX] of Boolean;
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure DemolishHouse(aFrom: TKMHandID; IsSilent: Boolean = False); override;
    function ShouldAbandonDeliveryTo(aWareType: TKMWareType): Boolean; override;
    function ShouldAbandonDeliveryFromTo(aToHouse: TKMHouse; aWareType: TKMWareType; aImmidiateCheck: Boolean): Boolean; override;
    procedure ToggleNotAcceptFlag(aWare: TKMWareType);
    procedure ToggleNotAcceptTakeOutFlag(aWare: TKMWareType);
    procedure ResAddToIn(aWare: TKMWareType; aCount: Integer = 1; aFromScript: Boolean = False); override;
    function CheckResIn(aWare: TKMWareType): Word; override;
    procedure ResTakeFromOut(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False); override;
    function ResCanAddToIn(aWare: TKMWareType): Boolean; override;
    function ResOutputAvailable(aWare: TKMWareType; const aCount: Word): Boolean; override;
    procedure Save(SaveStream: TKMemoryStream); override;
  end;


  TKMHouseTower = class(TKMHouse)
  public
    procedure Paint; override; //Render debug radius overlay
  end;


  TKMHouseArmorWorkshop = class(TKMHouse)
  private
    fAcceptWood: Boolean;
    fAcceptLeather: Boolean;
  public
    property AcceptWood: Boolean read fAcceptWood write fAcceptWood;
    property AcceptLeather: Boolean read fAcceptLeather write fAcceptLeather;
    constructor Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure Save(SaveStream: TKMemoryStream); override;
    procedure ToggleResDelivery(aWareType: TKMWareType);
    function AcceptWareForDelivery(aWareType: TKMWareType): Boolean;
    function ShouldAbandonDeliveryTo(aWareType: TKMWareType): Boolean; override;
  end;


implementation
uses
  TypInfo, SysUtils, Math, KromUtils,
  KM_Game, KM_GameParams, KM_Terrain, KM_RenderPool, KM_RenderAux, KM_Sound,
  KM_Hand, KM_HandsCollection, KM_HandLogistics,
  KM_UnitWarrior, KM_HouseWoodcutters,
  KM_Resource, KM_ResSound, KM_ResTexts, KM_ResUnits, KM_ResMapElements,
  KM_Log, KM_ScriptingEvents, KM_CommonUtils, KM_MapEditorHistory,
  KM_GameTypes, KM_RenderDebug,
  KM_HandTypes,
  KM_CommonExceptions,
  KM_ResTileset;

const
  //Delay, In ticks, from user click on DeliveryMode btn, to tick, when mode will be really set.
  //Made to prevent serf's taking/losing deliveries only because player clicks throught modes.
  //No hurry, let's wait a bit for player to be sure, what mode he needs
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

  fPosition   := KMPoint (PosX, PosY);
  fType       := aHouseType;
end;


{Return Entrance of the house, which is different than house position sometimes}
function TKMHouseSketch.GetEntrance: TKMPoint;
begin
  Result.X := Position.X + gRes.Houses[fType].EntranceOffsetX;
  Result.Y := Position.Y;
  Assert((Result.X > 0) and (Result.Y > 0));
end;


function TKMHouseSketch.GetPointBelowEntrance: TKMPoint;
begin
  Result := KMPointBelow(Entrance);
end;


function TKMHouseSketch.GetPosition: TKMPoint;
begin
  Result := fPosition;
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
  Result := Format('UID = %d%sType = %s%sEntrance = %s',
                  [UID, aSeparator,
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


procedure TKMHouseSketchEdit.CopyTo(var aHouseSketch: TKMHouseSketchEdit);
begin
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


procedure TKMHouseSketchEdit.SetPosition(aPosition: TKMPoint);
begin
  if fEditable then
    fPosition := aPosition;
end;


function TKMHouseSketchEdit.GetInstance: TKMHouse;
begin
  //Not used. Make compiler happy
  raise Exception.Create('Can''t get instance of TKMHouseSketchEdit');
end;


function TKMHouseSketchEdit.GetPositionF: TKMPointF;
begin
  //Not used. Make compiler happy
  raise Exception.Create('Can''t get positionF of TKMHouseSketchEdit');
end;


procedure TKMHouseSketchEdit.SetPositionF(const aPositionF: TKMPointF);
begin
  //Not used. Make compiler happy
  raise Exception.Create('Can''t set positionF of TKMHouseSketchEdit');
end;


{ TKMHouse }
constructor TKMHouse.Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
var
  I: Byte;
begin
  inherited Create(aUID, aHouseType, PosX, PosY, aOwner);

  fBuildState := aBuildState;

  fBuildSupplyWood  := 0;
  fBuildSupplyStone := 0;
  fBuildReserve     := 0;
  fBuildingProgress := 0;
  fDamage           := 0; //Undamaged yet

  fPlacedOverRoad   := gTerrain.TileHasRoad(Entrance);

  fHasOwner         := False;
  //Initially repair is [off]. But for AI it's controlled by a command in DAT script
  fBuildingRepair   := False; //Don't set it yet because we don't always know who are AIs yet (in multiplayer) It is set in first UpdateState
  DoorwayUse        := 0;
  fNewDeliveryMode  := dmDelivery;
  fDeliveryMode     := dmDelivery;
  fUpdateDeliveryModeOnTick := 0;

  for I := 1 to 4 do
  begin
    fResourceIn[I] := 0;
    fResourceDeliveryCount[I] := 0;
    fResourceOut[I] := 0;
    fResourceOrder[I] := 0;
  end;

  for I := 0 to 19 do
    fResourceOutPool[I] := 0;

  fIsDestroyed := False;
//  fPointerCount := 0;
  fTimeSinceUnoccupiedReminder := TIME_BETWEEN_MESSAGES;

  fResourceDepletedMsgIssued := False;
  fNeedIssueOrderCompletedMsg := False;
  fOrderCompletedMsgIssued := False;

  //ByDefault allow to show all human player houses to allies, or AI's not in Campaign
  fAllowAllyToView := gHands[Owner].IsHuman or not gGameParams.IsCampaign;

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
  HasAct: Boolean;
begin
  inherited;

  LoadStream.CheckMarker('House');
  LoadStream.Read(fType, SizeOf(fType));
  LoadStream.Read(fPosition);
  LoadStream.Read(fBuildState, SizeOf(fBuildState));
  LoadStream.Read(fBuildSupplyWood);
  LoadStream.Read(fBuildSupplyStone);
  LoadStream.Read(fBuildReserve);
  LoadStream.Read(fBuildingProgress, SizeOf(fBuildingProgress));
  LoadStream.Read(fDamage, SizeOf(fDamage));
  LoadStream.Read(fHasOwner);
  LoadStream.Read(fBuildingRepair);
  LoadStream.Read(Byte(fDeliveryMode));
  LoadStream.Read(Byte(fNewDeliveryMode));
  LoadStream.Read(fUpdateDeliveryModeOnTick);
  LoadStream.Read(fIsClosedForWorker);
  for I:=1 to 4 do LoadStream.Read(fResourceIn[I]);
  for I:=1 to 4 do LoadStream.Read(fResourceDeliveryCount[I]);
  for I:=1 to 4 do LoadStream.Read(fResourceOut[I]);
  for I:=1 to 4 do LoadStream.Read(fResourceOrder[I], SizeOf(fResourceOrder[I]));
//  for I:=1 to 4 do LoadStream.Read(fResOrderDesired[I], SizeOf(fResOrderDesired[I]));

  if fType in HOUSE_WORKSHOP then
    LoadStream.Read(fResourceOutPool, 20);

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
  LoadStream.Read(HasAct);
  if HasAct then
  begin
    CurrentAction := TKMHouseAction.Create(nil, hstEmpty); //Create action object
    CurrentAction.Load(LoadStream); //Load actual data into object
  end;
  LoadStream.Read(fResourceDepletedMsgIssued);
  LoadStream.Read(DoorwayUse);
  LoadStream.Read(fAllowAllyToView);
  LoadStream.Read(fPlacedOverRoad);
end;


procedure TKMHouse.SyncLoad;
begin
  CurrentAction.SyncLoad;
end;


destructor TKMHouse.Destroy;
begin
  FreeAndNil(CurrentAction);

  inherited;
end;


procedure TKMHouse.AddDemandsOnActivate(aWasBuilt: Boolean);
var
  I, DemandsCnt: Integer;
  Res: TKMWareType;
begin
  for I := 1 to 4 do
  begin
    Res := gRes.Houses[fType].ResInput[I];
    with gHands[Owner].Deliveries.Queue do
    case Res of
      wtNone:    ;
      wtWarfare: AddDemand(Self, nil, Res, 1, dtAlways, diNorm);
      wtAll:     AddDemand(Self, nil, Res, 1, dtAlways, diNorm);
      else        begin
                    DemandsCnt := GetResDistribution(I);
                    AddDemand(Self, nil, Res, DemandsCnt, dtOnce, diNorm); //Every new house needs 5 resource units
                    ResDeliveryCnt[I] := ResDeliveryCnt[I] + DemandsCnt; //Keep track of how many resources we have on order (for distribution of wares)
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
  HA: THouseArea;
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

    if not gTerrain.CanWalkDiagonaly(Entrance, P1.X, P1.Y)
      and ObjectShouldBeCleared(P1.X + 1, P1.Y) then // Do not clear choppable trees
      gTerrain.RemoveObject(KMPoint(P1.X + 1, P1.Y)); //Clear object at PointBelowEntrance

    if not gTerrain.CanWalkDiagonaly(Entrance, P2.X, P2.Y)
      and ObjectShouldBeCleared(P2.X, P2.Y) then
      gTerrain.RemoveObject(P2);
  end;
end;


procedure TKMHouse.RemoveHouse;
begin
  Assert(gGameParams.IsMapEditor, 'Operation allowed only in the MapEd');

  DemolishHouse(Owner, True);
  gHands[Owner].Houses.DeleteHouseFromList(Self);
end;


//IsSilent parameter is used by Editor and scripts
procedure TKMHouse.DemolishHouse(aFrom: TKMHandID; IsSilent: Boolean = False);
var
  I: Integer;
  R: TKMWareType;
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
    R := gRes.Houses[fType].ResInput[I];
    if R in [WARE_MIN..WARE_MAX] then
      gHands[Owner].Stats.WareConsumed(R, ResIn[I]);
    R := gRes.Houses[fType].ResOutput[I];
    if R in [WARE_MIN..WARE_MAX] then
      gHands[Owner].Stats.WareConsumed(R, fResourceOut[I]);
  end;

  gTerrain.SetHouse(fPosition, fType, hsNone, PLAYER_NONE);

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
        gTerrain.Land[Entrance.Y, Entrance.X].TileOverlay := toDig3; //Remove road and leave dug earth behind
    end;
  end;

  FreeAndNil(CurrentAction);

  //Leave disposing of units inside the house to themselves

  //Notify the script that the house is now completely gone
  gScriptEvents.ProcHouseAfterDestroyed(HouseType, Owner, Entrance.X, Entrance.Y);
end;


//Used by MapEditor
//Set house to new position
procedure TKMHouse.SetPosition(const aPos: TKMPoint);
var
  WasOnSnow, IsRallyPointSet, newPos: Boolean;
begin
  Assert(gGameParams.Mode = gmMapEd);

  newPos := fPosition <> aPos;

  //We have to remove the house THEN check to see if we can place it again so we can put it on the old position
  gTerrain.SetHouse(fPosition, fType, hsNone, PLAYER_NONE);

  if gMySpectator.Hand.CanAddHousePlan(aPos, HouseType) then
  begin
    IsRallyPointSet := False;
    //Save if flag point was set for previous position
    if (Self is TKMHouseWFlagPoint) then
      IsRallyPointSet := TKMHouseWFlagPoint(Self).IsFlagPointSet;

    gTerrain.RemRoad(GetEntrance);
    fPosition.X := aPos.X - gRes.Houses[fType].EntranceOffsetX;
    fPosition.Y := aPos.Y;

    //Update rally/cutting point position for houses with flag point after change fPosition
    if (Self is TKMHouseWFlagPoint) then
    begin
      if not IsRallyPointSet then
        TKMHouseWFlagPoint(Self).FlagPoint := PointBelowEntrance
      else
        TKMHouseWFlagPoint(Self).ValidateFlagPoint;
    end;
  end;

  gTerrain.SetHouse(fPosition, fType, hsBuilt, Owner); // Update terrain tiles for house

  //Do not remove all snow if house is moved from snow to snow
  WasOnSnow := fIsOnSnow;
  CheckOnSnow;
  if not WasOnSnow or not fIsOnSnow then
    fSnowStep := 0;

  if newPos then
    gGame.MapEditor.History.MakeCheckpoint(caHouses, Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_MOVE_SMTH],
                                                            [gRes.Houses[HouseType].HouseName, aPos.ToString]));
end;


//Check and proceed if we Set or UnSet dmTakeOut delivery mode
procedure TKMHouse.CheckTakeOutDeliveryMode;
var
  I: Integer;
  ResCnt: Word;
  Res: TKMWareType;
begin
  if fDeliveryMode = dmTakeOut then
    for I := 1 to 4 do
    begin
      Res := gRes.Houses[fType].ResInput[I];
      ResCnt := ResIn[I] - ResInLocked[I];
      if (Res <> wtNone) and (ResCnt > 0) then
        gHands[Owner].Deliveries.Queue.RemOffer(Self, Res, ResCnt);
    end;

  if fNewDeliveryMode = dmTakeOut then
  begin
    for I := 1 to 4 do
    begin
      Res := gRes.Houses[fType].ResInput[I];
      ResCnt := ResIn[I] - ResInLocked[I];

      if not (Res in [wtNone, wtAll, wtWarfare]) and (ResCnt > 0) then
        gHands[Owner].Deliveries.Queue.AddOffer(Self, Res, ResCnt);
    end;
  end;
end;


procedure TKMHouse.SetResourceDeliveryCount(aIndex: Integer; aCount: Word);
begin
  fResourceDeliveryCount[aIndex] := EnsureRange(aCount, 0, High(Word));
end;


function TKMHouse.GetResourceDeliveryCount(aIndex: Integer): Word;
begin
  Result := fResourceDeliveryCount[aIndex];
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
begin
  if fNewDeliveryMode = fDeliveryMode then
    Exit;

  CheckTakeOutDeliveryMode;

  fUpdateDeliveryModeOnTick := 0;
  fDeliveryMode := fNewDeliveryMode;
  gLog.LogDelivery('DeliveryMode updated to ' + IntToStr(Byte(fDeliveryMode)));
end;


//Set NewDelivery mode. Its going to become a real delivery mode few ticks later
procedure TKMHouse.SetNewDeliveryMode(aValue: TKMDeliveryMode);
begin
  fNewDeliveryMode := aValue;

  fUpdateDeliveryModeOnTick := fTick + UPDATE_DELIVERY_MODE_DELAY;
  gLog.LogDelivery('NewDeliveryMode set to ' + IntToStr(Byte(fNewDeliveryMode)));
end;


procedure TKMHouse.SetNextDeliveryMode;
begin
  SetNewDeliveryMode(TKMDeliveryMode((Byte(fNewDeliveryMode) + 3 - 1) mod 3)); //We use opposite order for legacy support
end;


procedure TKMHouse.SetPrevDeliveryMode;
begin
  SetNewDeliveryMode(TKMDeliveryMode((Byte(fNewDeliveryMode) + 1) mod 3)); //We use opposite order for legacy support
end;


//Set delivery mdoe immidiately
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
  MsgID: Word;
begin
  MsgID := GetResourceDepletedMessageId;
  Assert(MsgID <> 0, gRes.Houses[HouseType].HouseName + ' resource can''t be depleted');

  gGame.ShowMessage(mkHouse, MsgID, Entrance, Owner);
  ResourceDepleted := True;
end;


function TKMHouse.IsSelectable: Boolean;
begin
  if Self = nil then Exit(False);

  Result := not IsDestroyed;
end;


function TKMHouse.GetResourceDepletedMessageId: Word;
begin
  Result := 0;
  case HouseType of
    htQuary:       Result := TX_MSG_STONE_DEPLETED;
    htCoalMine:    Result := TX_MSG_COAL_DEPLETED;
    htIronMine:    Result := TX_MSG_IRON_DEPLETED;
    htGoldMine:    Result := TX_MSG_GOLD_DEPLETED;
    htWoodcutters: if TKMHouseWoodcutters(Self).WoodcutterMode = wcmPlant then
                      Result := TX_MSG_WOODCUTTER_PLANT_DEPLETED
                    else
                      Result := TX_MSG_WOODCUTTER_DEPLETED;
    htFisherHut:   if not gTerrain.CanFindFishingWater(PointBelowEntrance, gRes.Units[utFisher].MiningRange) then
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


//Check if we should abandon delivery from this house
function TKMHouse.ShouldAbandonDeliveryFrom(aWareType: TKMWareType; aImmidiateCheck: Boolean = False): Boolean;
begin
  Result := not ResOutputAvailable(aWareType, 1);
end;


//Check if we should abandon delivery from this house to aToHouse (used in Store only for now)
function TKMHouse.ShouldAbandonDeliveryFromTo(aToHouse: TKMHouse; aWareType: TKMWareType; aImmidiateCheck: Boolean): Boolean;
begin
  Result := False;
end;


{Returns the closest cell of the house to aPos}
function TKMHouse.GetClosestCell(const aPos: TKMPoint): TKMPoint;
var
  C: TKMPointList;
begin
  Result := KMPOINT_ZERO;
  C := TKMPointList.Create;
  try
    GetListOfCellsWithin(C);
    if not C.GetClosest(aPos, Result) then
      raise Exception.Create('Could not find closest house cell');
  finally
    C.Free;
  end;
end;


{Return distance from aPos to the closest house tile}
function TKMHouse.GetDistance(const aPos: TKMPoint): Single;
var
  I, K: Integer;
  Loc: TKMPoint;
  HA: THouseArea;
begin
  Result := MaxSingle;
  Loc := fPosition;
  HA := gRes.Houses[fType].BuildArea;

  for I := max(Loc.Y - 3, 1) to Loc.Y do
  for K := max(Loc.X - 2, 1) to min(Loc.X + 1, gTerrain.MapX) do
  if HA[I - Loc.Y + 4, K - Loc.X + 3] <> 0 then
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


procedure TKMHouse.GetListOfCellsAround(Cells: TKMPointDirList; aPassability: TKMTerrainPassability);
var
  I,K: Integer;
  Loc: TKMPoint;
  HA: THouseArea;

  procedure AddLoc(X,Y: Word; Dir: TKMDirection);
  begin
    //Check that the passabilty is correct, as the house may be placed against blocked terrain
    if gTerrain.CheckPassability(KMPoint(X,Y), aPassability) then
      Cells.Add(KMPointDir(X, Y, Dir));
  end;

begin
  Cells.Clear;
  Loc := fPosition;
  HA := gRes.Houses[fType].BuildArea;

  for I := 1 to 4 do for K := 1 to 4 do
  if HA[I,K] <> 0 then
  begin
    if (I = 1) or (HA[I-1,K] = 0) then
      AddLoc(Loc.X + K - 3, Loc.Y + I - 4 - 1, dirS); //Above
    if (I = 4) or (HA[I+1,K] = 0) then
      AddLoc(Loc.X + K - 3, Loc.Y + I - 4 + 1, dirN); //Below
    if (K = 4) or (HA[I,K+1] = 0) then
      AddLoc(Loc.X + K - 3 + 1, Loc.Y + I - 4, dirW); //FromRight
    if (K = 1) or (HA[I,K-1] = 0) then
      AddLoc(Loc.X + K - 3 - 1, Loc.Y + I - 4, dirE); //FromLeft
  end;
end;


procedure TKMHouse.GetListOfCellsWithin(Cells: TKMPointList);
var
  i,k: Integer;
  Loc: TKMPoint;
  HouseArea: THouseArea;
begin
  Cells.Clear;
  Loc := fPosition;
  HouseArea := gRes.Houses[fType].BuildArea;

  for i := max(Loc.Y - 3, 1) to Loc.Y do
    for K := max(Loc.X - 2, 1) to min(Loc.X + 1, gTerrain.MapX) do
      if HouseArea[i - Loc.Y + 4, K - Loc.X + 3] <> 0 then
        Cells.Add(KMPoint(K, i));
end;


procedure TKMHouse.GetListOfGroundVisibleCells(aCells: TKMPointTagList);
var
  i,k,ground: Integer;
  Loc: TKMPoint;
  GroundVisibleArea: THouseArea;
begin
  aCells.Clear;
  Loc := fPosition;
  GroundVisibleArea := gRes.Houses[fType].GroundVisibleArea;

  for i := max(Loc.Y - 3, 1) to Loc.Y do
    for K := max(Loc.X - 2, 1) to min(Loc.X + 1, gTerrain.MapX) do
    begin
      ground := GroundVisibleArea[i - Loc.Y + 4, K - Loc.X + 3];
      if ground <> 0 then
        aCells.Add(KMPoint(K, i), ground);
    end;
end;


function TKMHouse.GetRandomCellWithin: TKMPoint;
var
  Cells: TKMPointList;
  Success: Boolean;
begin
  Cells := TKMPointList.Create;
  GetListOfCellsWithin(Cells);
  Success := Cells.GetRandom(Result);
  Assert(Success);
  Cells.Free;
end;


function TKMHouse.HitTest(X, Y: Integer): Boolean;
begin
  Result := (X-fPosition.X+3 in [1..4]) and
            (Y-fPosition.Y+4 in [1..4]) and
            (gRes.Houses[fType].BuildArea[Y-fPosition.Y+4, X-fPosition.X+3] <> 0);
end;


function TKMHouse.GetHealth:word;
begin
  Result := max(fBuildingProgress - fDamage, 0);
end;


function TKMHouse.GetInstance: TKMHouse;
begin
  Result := Self;
end;


procedure TKMHouse.SetPositionF(const aPositionF: TKMPointF);
begin
  raise Exception.Create('Can''t set PositionF for House');
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


{Increase building progress of house. When it reaches some point Stoning replaces Wooding
 and then it's done and house should be finalized}
 {Keep track on stone/wood reserve here as well}
procedure TKMHouse.IncBuildingProgress;
begin
  if IsComplete then Exit;

  if (fBuildState = hbsWood) and (fBuildReserve = 0) then
  begin
    dec(fBuildSupplyWood);
    inc(fBuildReserve, 50);
  end;
  if (fBuildState = hbsStone) and (fBuildReserve = 0) then
  begin
    Dec(fBuildSupplyStone);
    Inc(fBuildReserve, 50);
  end;

  Inc(fBuildingProgress, 5); //is how many effort was put into building nevermind applied damage
  Dec(fBuildReserve, 5); //This is reserve we build from

  if (fBuildState=hbsWood)
    and (fBuildingProgress = gRes.Houses[fType].WoodCost*50) then
    fBuildState := hbsStone;

  if (fBuildState = hbsStone)
    and (fBuildingProgress - gRes.Houses[fType].WoodCost*50 = gRes.Houses[fType].StoneCost*50) then
  begin
    fBuildState := hbsDone;
    gHands[Owner].Stats.HouseEnded(fType);
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
      attackerHand := PLAYER_NONE;

    //Properly release house assets
    //Do not remove house in Editor just yet, mapmaker might increase the hp again
    if (GetHealth = 0) and not aIsEditor then
      DemolishHouse(attackerHand);
  end;
end;


//Add repair to the house
procedure TKMHouse.AddRepair(aAmount: Word = 5);
begin
  fDamage := EnsureRange(fDamage - aAmount, 0, High(Word));
  UpdateDamage;
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


function TKMHouse.GetState: TKMHouseState;
begin
  Result := CurrentAction.State;
end;


function TKMHouse.GetResourceInArray: TKMByteArray;
var
  I, iOffset: Integer;
begin
  SetLength(Result, Length(fResourceIn));
  iOffset := Low(fResourceIn) - Low(Result);
  for I := Low(Result) to High(Result) do
    Result[I] := fResourceIn[I + iOffset];
end;


function TKMHouse.GetResourceOutArray: TKMByteArray;
var
  I, iOffset: Integer;
begin
  SetLength(Result, Length(fResourceOut));
  iOffset := Low(fResourceOut) - Low(Result);
  for I := Low(Result) to High(Result) do
    Result[I] := fResourceOut[I + iOffset];
end;


function TKMHouse.GetResourceOutPoolArray: TKMByteArray;
var
  I: Integer;
begin
  SetLength(Result, Length(fResourceOutPool));
  for I := Low(Result) to High(Result) do
    Result[I] := fResourceOutPool[I];
end;


// Check if house is placed mostly on snow
procedure TKMHouse.CheckOnSnow;
var
  I: Integer;
  SnowTiles, NoSnowTiles: Integer;
  Cells: TKMPointTagList;
begin
  Cells := TKMPointTagList.Create;

  GetListOfGroundVisibleCells(Cells);

  SnowTiles := 0;
  NoSnowTiles := 0;
  for I := 0 to Cells.Count - 1 do
    if gTerrain.TileIsSnow(Cells[I].X, Cells[I].Y) then
      Inc(SnowTiles, Cells.Tag[I])
    else
      Inc(NoSnowTiles, Cells.Tag[I]);

  fIsOnSnow := SnowTiles > NoSnowTiles;

  Cells.Free;
end;


{How much resources house has in Input}
function TKMHouse.CheckResIn(aWare: TKMWareType): Word;
var I: Integer;
begin
  Result := 0;
  for I := 1 to 4 do
    if (aWare = gRes.Houses[fType].ResInput[I]) or (aWare = wtAll) then
      Inc(Result, ResIn[I]);
end;


{How much resources house has in Output}
function TKMHouse.CheckResOut(aWare: TKMWareType): Word;
var I: Integer;
begin
  Result := 0;
  for I := 1 to 4 do
    if (aWare = gRes.Houses[fType].ResOutput[I]) or (aWare = wtAll) then
      Inc(Result, fResourceOut[I]);
end;


{Check amount of placed order for given ID}
function TKMHouse.GetResOrder(aID: Byte): Integer;
begin
  Result := fResourceOrder[aID];
end;


//Input value is integer because we might get a -100 order from outside and need to fit it to range
//properly
procedure TKMHouse.SetResOrder(aID: Byte; aValue: Integer);
//var
//  I: Integer;
//  TotalDesired: Integer;
begin
  fResourceOrder[aID] := EnsureRange(aValue, 0, MAX_WARES_ORDER);

  //Calculate desired production ratio (so that we are not affected by fResourceOrder which decreases till 0)
//  TotalDesired := fResourceOrder[1] + fResourceOrder[2] + fResourceOrder[3] + fResourceOrder[4];
//  for I := 1 to 4 do
//    fResOrderDesired[I] := fResourceOrder[I] / TotalDesired;

  fNeedIssueOrderCompletedMsg := False;
  fOrderCompletedMsgIssued := False;
end;


//Select order we will be making
//Order picking in sequential, so that if orders for 1st = 6 and for 2nd = 2
//then the production will go like so: 12121111
function TKMHouse.PickOrder: Byte;
var
  I, Res: Byte;
  Ware: TKMWareType;
//  BestBid: Single;
//  TotalLeft: Integer;
//  LeftRatio: array [1..4] of Single;
begin
  Result := 0;

  if WARFARE_ORDER_SEQUENTIAL then
    for I := 0 to 3 do
    begin
      Res := ((fLastOrderProduced + I) mod 4) + 1; //1..4
      Ware := gRes.Houses[fType].ResOutput[Res];
      if (ResOrder[Res] > 0) //Player has ordered some of this
      and (CheckResOut(Ware) < MAX_WARES_IN_HOUSE) //Output of this is not full
      //Check we have wares to produce this weapon. If both are the same type check > 1 not > 0
      and ((WARFARE_COSTS[Ware,1] <> WARFARE_COSTS[Ware,2]) or (CheckResIn(WARFARE_COSTS[Ware,1]) > 1))
      and ((WARFARE_COSTS[Ware,1] = wtNone) or (CheckResIn(WARFARE_COSTS[Ware,1]) > 0))
      and ((WARFARE_COSTS[Ware,2] = wtNone) or (CheckResIn(WARFARE_COSTS[Ware,2]) > 0)) then
      begin
        Result := Res;
        fLastOrderProduced := Res;
        Break;
      end;
    end;

//  if WARFARE_ORDER_PROPORTIONAL then
//  begin
//    //See the ratio between items that were made (since last order amount change)
//    TotalLeft := fResourceOrder[1] + fResourceOrder[2] + fResourceOrder[3] + fResourceOrder[4];
//    for I := 1 to 4 do
//      LeftRatio[I] := fResourceOrder[I] / TotalLeft;
//
//    //Left   Desired
//    //0.5    0.6
//    //0.3    0.3
//    //0.2    0.1
//
//    //Find order that which production ratio is the smallest
//    BestBid := -MaxSingle;
//    for I := 1 to 4 do
//    if (ResOrder[I] > 0) then //Player has ordered some of this
//    begin
//      Ware := gRes.Houses[fType].ResOutput[I];
//
//      if (CheckResOut(Ware) < MAX_WARES_IN_HOUSE) //Output of this is not full
//      //Check we have enough wares to produce this weapon. If both are the same type check > 1 not > 0
//      and ((WarfareCosts[Ware,1] <> WarfareCosts[Ware,2]) or (CheckResIn(WarfareCosts[Ware,1]) > 1))
//      and ((WarfareCosts[Ware,1] = wtNone) or (CheckResIn(WarfareCosts[Ware,1]) > 0))
//      and ((WarfareCosts[Ware,2] = wtNone) or (CheckResIn(WarfareCosts[Ware,2]) > 0))
//      and (LeftRatio[I] - fResOrderDesired[I] > BestBid) then
//      begin
//        Result := I;
//        BestBid := LeftRatio[Result] - fResOrderDesired[Result];
//      end;
//    end;
//  end;

  if Result <> 0 then
  begin
    Dec(fResourceOrder[Result]);
    fNeedIssueOrderCompletedMsg := True;
    fOrderCompletedMsgIssued := False;
  end
  else
    //Check all orders are actually finished (input resources might be empty)
    if  (ResOrder[1] = 0) and (ResOrder[2] = 0)
    and (ResOrder[3] = 0) and (ResOrder[4] = 0) then
      if fNeedIssueOrderCompletedMsg then
      begin
        fNeedIssueOrderCompletedMsg := False;
        fOrderCompletedMsgIssued := True;
        gGame.ShowMessage(mkHouse, TX_MSG_ORDER_COMPLETED, Entrance, Owner);
      end;
end;


// Check if house has enough resource supply to be built depending on it's state
function TKMHouse.CheckResToBuild:boolean;
begin
  case fBuildState of
    hbsWood:   Result := (fBuildSupplyWood > 0) or (fBuildReserve > 0);
    hbsStone:  Result := (fBuildSupplyStone > 0) or (fBuildReserve > 0);
    else        Result := False;
  end;
end;


function TKMHouse.GetMaxInRes: Word;
begin
  if fType in [htStore, htBarracks, htMarketplace] then
    Result := High(Word)
  else
    Result := MAX_WARES_IN_HOUSE; //All other houses can only stock 5 for now
end;


procedure TKMHouse.DecResourceDelivery(aWare: TKMWareType);
var
  I: Integer;
begin
  for I := 1 to 4 do
    if aWare = gRes.Houses[fType].ResInput[I] then
    begin
      ResDeliveryCnt[I] := ResDeliveryCnt[I] - 1;
      Exit;
    end;
end;


//Maybe it's better to rule out In/Out? No, it is required to separate what can be taken out of the house and what not.
//But.. if we add "Evacuate" button to all house the separation becomes artificial..
procedure TKMHouse.ResAddToIn(aWare: TKMWareType; aCount: Integer = 1; aFromScript: Boolean = False);
var
  I,OrdersRemoved: Integer;
begin
  Assert(aWare <> wtNone);

  for I := 1 to 4 do
    if aWare = gRes.Houses[fType].ResInput[I] then
    begin
      //Don't allow the script to overfill houses
      if aFromScript then
        aCount := EnsureRange(aCount, 0, GetMaxInRes - fResourceIn[I]);
      //ResDeliveryCnt stay same, because corresponding demand will be closed
      ResIn[I] := ResIn[I] + aCount;
      if aFromScript then
      begin
        ResDeliveryCnt[I] := ResDeliveryCnt[I] + aCount;
        OrdersRemoved := gHands[Owner].Deliveries.Queue.TryRemoveDemand(Self, aWare, aCount);
        ResDeliveryCnt[I] := ResDeliveryCnt[I] - OrdersRemoved;
      end;
    end;
end;


procedure TKMHouse.ResAddToOut(aWare: TKMWareType; const aCount:integer=1);
var
  I, p, count: Integer;
begin
  if aWare = wtNone then
    exit;

  for I := 1 to 4 do
    if aWare = gRes.Houses[fType].ResOutput[I] then
    begin
      ResOut[I] := ResOut[I] + aCount;

      if (fType in HOUSE_WORKSHOP) and (aCount > 0) then
      begin
        count := aCount;
        for p := 0 to 19 do
          if fResourceOutPool[p] = 0 then
          begin
            fResourceOutPool[p] := I;
            Dec(count);
            if count = 0 then
              Break;
          end;
      end;

      gHands[Owner].Deliveries.Queue.AddOffer(Self, aWare, aCount);
    end;
end;


procedure TKMHouse.ResAddToEitherFromScript(aWare: TKMWareType; aCount: Integer);
var I: Integer;
begin
  for I := 1 to 4 do
  begin
    //No range checking required as ResAddToIn does that
    //If ResCanAddToIn, add it immediately and exit (e.g. store)
    if ResCanAddToIn(aWare) or (aWare = gRes.Houses[fType].ResInput[I]) then
    begin
      ResAddToIn(aWare, aCount, True);
      Exit;
    end;
    //Don't allow output to be overfilled from script. This is not checked
    //in ResAddToOut because e.g. stonemason is allowed to overfill it slightly)
    if (aWare = gRes.Houses[fType].ResOutput[I]) and (fResourceOut[I] < 5) then
    begin
      aCount := Min(aCount, 5 - fResourceOut[I]);
      ResAddToOut(aWare, aCount);
      Exit;
    end;
  end;
end;


// Add resources to building process
procedure TKMHouse.ResAddToBuild(aWare: TKMWareType);
begin
  case aWare of
    wtWood:  Inc(fBuildSupplyWood);
    wtStone: Inc(fBuildSupplyStone);
    else      raise ELocError.Create('WIP house is not supposed to recieve ' + gRes.Wares[aWare].Title + ', right?', fPosition);
  end;
end;


function TKMHouse.ResCanAddToIn(aWare: TKMWareType): Boolean;
var I: Integer;
begin
  Result := False;
  for I := 1 to 4 do
    if aWare = gRes.Houses[fType].ResInput[I] then
      Result := True;
end;


function TKMHouse.ResCanAddToOut(aWare: TKMWareType): Boolean;
var I: Integer;
begin
  Result := False;
  for I := 1 to 4 do
    if aWare = gRes.Houses[fType].ResOutput[I] then
      Result := True;
end;


function TKMHouse.GetResIn(aI: Byte): Word;
begin
  Result := fResourceIn[aI];
end;


function TKMHouse.GetResOut(aI: Byte): Word;
begin
  Result := fResourceOut[aI];
end;


function TKMHouse.GetResInLocked(aI: Byte): Word;
begin
  Result := 0; //By default we do not lock any In res
end;


procedure TKMHouse.SetResIn(aI: Byte; aValue: Word);
var
  CntChange: Integer;
  Res: TKMWareType;
begin
  Res := gRes.Houses[fType].ResInput[aI];
  CntChange := aValue - fResourceIn[aI];
  //In case we brought smth to house with TakeOut delivery mode,
  //then we need to add it to offer
  //Usually it can happens when we changed delivery mode while serf was going inside house
  //and his delivery was not cancelled, but resource was not in the house yet
  //then it was not offered to other houses
  if fDeliveryMode = dmTakeOut then
  begin
    if not (Res in [wtNone, wtAll, wtWarfare]) and (CntChange > 0) then
      gHands[Owner].Deliveries.Queue.AddOffer(Self, Res, CntChange);
  end;

  fResourceIn[aI] := aValue;

  if not (Res in [wtNone, wtAll, wtWarfare]) and (CntChange <> 0) then
    gScriptEvents.ProcHouseWareCountChanged(Self, Res, aValue, CntChange);
end;


procedure TKMHouse.SetResOut(aI: Byte; aValue: Word);
var
  CntChange: Integer;
  Res: TKMWareType;
begin
  Res := gRes.Houses[fType].ResOutput[aI];
  CntChange := aValue - fResourceOut[aI];

  fResourceOut[aI] := aValue;

  if not (Res in [wtNone, wtAll, wtWarfare]) and (CntChange <> 0) then
    gScriptEvents.ProcHouseWareCountChanged(Self, Res, aValue, CntChange);
end;


function TKMHouse.ResOutputAvailable(aWare: TKMWareType; const aCount: Word): Boolean;
var I: Integer;
begin
  Result := False;
  for I := 1 to 4 do
    if aWare = gRes.Houses[fType].ResOutput[I] then
      Result := fResourceOut[I] >= aCount;

  if not Result and (fNewDeliveryMode = dmTakeOut) then
    for I := 1 to 4 do
      if aWare = gRes.Houses[fType].ResInput[I] then
        Result := ResIn[I] - ResInLocked[I] >= aCount;
end;


// Take resource from Input and order more of that kind if DistributionRatios allow
procedure TKMHouse.ResTakeFromIn(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False);
var I,K: Integer;
begin
  Assert(aWare <> wtNone);

  for I := 1 to 4 do
  if aWare = gRes.Houses[fType].ResInput[I] then
  begin
    if aFromScript then
    begin
      //Script might try to take too many
      aCount := EnsureRange(aCount, 0, ResIn[I]);
      gHands[Owner].Stats.WareConsumed(aWare, aCount);
    end;

    //Keep track of how many are ordered
    ResDeliveryCnt[I] := EnsureRange(ResDeliveryCnt[I] - aCount, 0, High(Word));

    Assert(ResIn[I] >= aCount, 'fResourceIn[i] < 0');
    ResIn[I] := ResIn[I] - aCount;
    //Only request a new resource if it is allowed by the distribution of wares for our parent player
    for K := 1 to aCount do
      if ResDeliveryCnt[I] < GetResDistribution(I) then
      begin
        gHands[Owner].Deliveries.Queue.AddDemand(Self, nil, aWare, 1, dtOnce, diNorm);
        ResDeliveryCnt[I] := ResDeliveryCnt[I] + 1;
      end;
    Exit;
  end;
end;


procedure TKMHouse.ResTakeFromOut(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False);
var
  I, K, p, count: integer;
begin
  Assert(aWare <> wtNone);
  Assert(not(fType in [htStore,htBarracks,htTownHall]));
  for I := 1 to 4 do
  if aWare = gRes.Houses[fType].ResOutput[I] then
  begin
    if aFromScript then
    begin
      aCount := Min(aCount, fResourceOut[I]);
      if aCount > 0 then
      begin
        gHands[Owner].Stats.WareConsumed(aWare, aCount);
        gHands[Owner].Deliveries.Queue.RemOffer(Self, aWare, aCount);
      end;
    end;
    Assert(aCount <= fResourceOut[I]);

    if (fType in HOUSE_WORKSHOP) and (aCount > 0) then
    begin
      count := aCount;
      for p := 0 to 19 do
        if fResourceOutPool[p] = I then
          begin
            fResourceOutPool[p] := 0;
            Dec(count);
            if count = 0 then
              Break;
          end;
    end;

    ResOut[I] := ResOut[I] - aCount;
    Exit;
  end;

  for I := 1 to 4 do
  if aWare = gRes.Houses[fType].ResInput[I] then
  begin
    if aFromScript then
    begin
      aCount := Min(aCount, ResIn[I]);
      if aCount > 0 then
        gHands[Owner].Deliveries.Queue.RemOffer(Self, aWare, aCount);
    end;

    //Keep track of how many are ordered
    ResDeliveryCnt[I] := ResDeliveryCnt[I] - aCount;

    Assert(ResIn[I] >= aCount, 'fResourceIn[i] < 0');
    ResIn[I] := ResIn[I] - aCount;
    //Only request a new resource if it is allowed by the distribution of wares for our parent player
    for K := 1 to aCount do
      if ResDeliveryCnt[I] < GetResDistribution(I) then
      begin
        gHands[Owner].Deliveries.Queue.AddDemand(Self, nil, aWare, 1, dtOnce, diNorm);
        ResDeliveryCnt[I] := ResDeliveryCnt[I] + 1;
      end;
    Exit;
  end;
end;


function TKMHouse.GetResDistribution(aID: Byte): Byte;
begin
  Result := gHands[Owner].Stats.WareDistribution[gRes.Houses[fType].ResInput[aID],fType];
end;


procedure TKMHouse.MakeSound;
var
  Work: TKMHouseActionType;
  Step: Byte;
begin
  if SKIP_SOUND then Exit;

  if CurrentAction = nil then exit; //no action means no sound ;)

  if haWork1 in CurrentAction.SubAction then Work := haWork1 else
  if haWork2 in CurrentAction.SubAction then Work := haWork2 else
  if haWork3 in CurrentAction.SubAction then Work := haWork3 else
  if haWork4 in CurrentAction.SubAction then Work := haWork4 else
  if haWork5 in CurrentAction.SubAction then Work := haWork5 else
    Exit; //No work is going on

  Step := gRes.Houses[fType].Anim[Work].Count;
  if Step = 0 then Exit;

  Step := WorkAnimStep mod Step;

  //Do not play sounds if house is invisible to gMySpectator
  //This check is slower so we do it after other Exit checks
  if gMySpectator.FogOfWar.CheckTileRevelation(fPosition.X, fPosition.Y) < 255 then exit;

  case fType of //Various buildings and HouseActions producing sounds
    htSchool:        if (Work = haWork5)and(Step = 28) then gSoundPlayer.Play(sfxSchoolDing, fPosition); //Ding as the clock strikes 12
    htMill:          if (Work = haWork2)and(Step = 0) then gSoundPlayer.Play(sfxMill, fPosition);
    htCoalMine:      if (Work = haWork1)and(Step = 5) then gSoundPlayer.Play(sfxcoalDown, fPosition)
                      else if (Work = haWork1)and(Step = 24) then gSoundPlayer.Play(sfxCoalMineThud, fPosition,true,0.8)
                      else if (Work = haWork2)and(Step = 7) then gSoundPlayer.Play(sfxmine, fPosition)
                      else if (Work = haWork5)and(Step = 1) then gSoundPlayer.Play(sfxcoalDown, fPosition);
    htIronMine:      if (Work = haWork2)and(Step = 7) then gSoundPlayer.Play(sfxmine, fPosition);
    htGoldMine:      if (Work = haWork2)and(Step = 5) then gSoundPlayer.Play(sfxmine, fPosition);
    htSawmill:       if (Work = haWork2)and(Step = 1) then gSoundPlayer.Play(sfxsaw, fPosition);
    htWineyard:      if (Work = haWork2)and(Step in [1,7,13,19]) then gSoundPlayer.Play(sfxwineStep, fPosition)
                      else if (Work = haWork5)and(Step = 14) then gSoundPlayer.Play(sfxwineDrain, fPosition,true,1.5)
                      else if (Work = haWork1)and(Step = 10) then gSoundPlayer.Play(sfxwineDrain, fPosition,true,1.5);
    htBakery:        if (Work = haWork3)and(Step in [6,25]) then gSoundPlayer.Play(sfxBakerSlap, fPosition);
    htQuary:         if (Work = haWork2)and(Step in [4,13]) then gSoundPlayer.Play(sfxQuarryClink, fPosition)
                      else if (Work = haWork5)and(Step in [4,13,22]) then gSoundPlayer.Play(sfxQuarryClink, fPosition);
    htWeaponSmithy:  if (Work = haWork1)and(Step in [17,22]) then gSoundPlayer.Play(sfxBlacksmithFire, fPosition)
                      else if (Work = haWork2)and(Step in [10,25]) then gSoundPlayer.Play(sfxBlacksmithBang, fPosition)
                      else if (Work = haWork3)and(Step in [10,25]) then gSoundPlayer.Play(sfxBlacksmithBang, fPosition)
                      else if (Work = haWork4)and(Step in [8,22]) then gSoundPlayer.Play(sfxBlacksmithFire, fPosition)
                      else if (Work = haWork5)and(Step = 12) then gSoundPlayer.Play(sfxBlacksmithBang, fPosition);
    htArmorSmithy:   if (Work = haWork2)and(Step in [13,28]) then gSoundPlayer.Play(sfxBlacksmithBang, fPosition)
                      else if (Work = haWork3)and(Step in [13,28]) then gSoundPlayer.Play(sfxBlacksmithBang, fPosition)
                      else if (Work = haWork4)and(Step in [8,22]) then gSoundPlayer.Play(sfxBlacksmithFire, fPosition)
                      else if (Work = haWork5)and(Step in [8,22]) then gSoundPlayer.Play(sfxBlacksmithFire, fPosition);
    htMetallurgists: if (Work = haWork3)and(Step = 6) then gSoundPlayer.Play(sfxmetallurgists, fPosition)
                      else if (Work = haWork4)and(Step in [16,20]) then gSoundPlayer.Play(sfxwineDrain, fPosition);
    htIronSmithy:    if (Work = haWork2)and(Step in [1,16]) then gSoundPlayer.Play(sfxmetallurgists, fPosition)
                      else if (Work = haWork3)and(Step = 1) then gSoundPlayer.Play(sfxmetallurgists, fPosition)
                      else if (Work = haWork3)and(Step = 13) then gSoundPlayer.Play(sfxwineDrain, fPosition);
    htWeaponWorkshop:if (Work = haWork2)and(Step in [1,10,19]) then gSoundPlayer.Play(sfxsaw, fPosition)
                      else if (Work = haWork3)and(Step in [10,21]) then gSoundPlayer.Play(sfxCarpenterHammer, fPosition)
                      else if (Work = haWork4)and(Step in [2,13]) then gSoundPlayer.Play(sfxCarpenterHammer, fPosition);
    htArmorWorkshop: if (Work = haWork2)and(Step in [3,13,23]) then gSoundPlayer.Play(sfxsaw, fPosition)
                      else if (Work = haWork3)and(Step in [17,28]) then gSoundPlayer.Play(sfxCarpenterHammer, fPosition)
                      else if (Work = haWork4)and(Step in [10,20]) then gSoundPlayer.Play(sfxCarpenterHammer, fPosition);
    htTannery:       if (Work = haWork2)and(Step = 5) then gSoundPlayer.Play(sfxLeather, fPosition,true,0.8);
    htButchers:      if (Work = haWork2)and(Step in [8,16,24]) then gSoundPlayer.Play(sfxButcherCut, fPosition)
                      else if (Work = haWork3)and(Step in [9,21]) then gSoundPlayer.Play(sfxSausageString, fPosition);
    htSwine:         if ((Work = haWork2)and(Step in [10,20]))or((Work = haWork3)and(Step = 1)) then gSoundPlayer.Play(sfxButcherCut, fPosition);
    //htWatchTower:  Sound handled by projectile itself
  end;
end;


procedure TKMHouse.Save(SaveStream: TKMemoryStream);
var
  I: Integer;
  HasAct: Boolean;
begin
  inherited;

  SaveStream.PlaceMarker('House');
  SaveStream.Write(fType, SizeOf(fType));
  SaveStream.Write(fPosition);
  SaveStream.Write(fBuildState, SizeOf(fBuildState));
  SaveStream.Write(fBuildSupplyWood);
  SaveStream.Write(fBuildSupplyStone);
  SaveStream.Write(fBuildReserve);
  SaveStream.Write(fBuildingProgress, SizeOf(fBuildingProgress));
  SaveStream.Write(fDamage, SizeOf(fDamage));
  SaveStream.Write(fHasOwner);
  SaveStream.Write(fBuildingRepair);
  SaveStream.Write(Byte(fDeliveryMode));
  SaveStream.Write(Byte(fNewDeliveryMode));
  SaveStream.Write(fUpdateDeliveryModeOnTick);
  SaveStream.Write(fIsClosedForWorker);
  for I:=1 to 4 do SaveStream.Write(fResourceIn[I]);
  for I:=1 to 4 do SaveStream.Write(fResourceDeliveryCount[I]);
  for I:=1 to 4 do SaveStream.Write(fResourceOut[I]);
  for I:=1 to 4 do SaveStream.Write(fResourceOrder[I], SizeOf(fResourceOrder[I]));
//  for I:=1 to 4 do SaveStream.Write(fResOrderDesired[I], SizeOf(fResOrderDesired[I]));

  if fType in HOUSE_WORKSHOP then
    SaveStream.Write(fResourceOutPool, 20);

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
  HasAct := CurrentAction <> nil;
  SaveStream.Write(HasAct);
  if HasAct then CurrentAction.Save(SaveStream);
  SaveStream.Write(fResourceDepletedMsgIssued);
  SaveStream.Write(DoorwayUse);
  SaveStream.Write(fAllowAllyToView);
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
  WasOnSnow: Boolean;
  HA: THouseArea;
begin
  Inc(FlagAnimStep);
  Inc(WorkAnimStep);

  if (FlagAnimStep mod 10 = 0) and gGameParams.IsMapEditor then
  begin
    WasOnSnow := fIsOnSnow;
    CheckOnSnow;
    if not WasOnSnow or not fIsOnSnow then
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


//Request more resources (if distribution of wares has changed)
//todo: Situation: I have timber set to 5 for the weapons workshop, and no timber in my village.
//      I change timber to 0 for the weapons workshop. My woodcutter starts again and 5 timber is still
//      taken to the weapons workshop because the request doesn't get canceled.
//      Maybe it's possible to cancel the current requests if no serf has taken them yet?
procedure TKMHouse.UpdateResRequest;
var
  I: Byte;
  Count, Excess: ShortInt;
  ResDistribution: Byte;
begin
  for I := 1 to 4 do
    if not (fType = htTownHall) and not (gRes.Houses[fType].ResInput[I] in [wtAll, wtWarfare, wtNone]) then
    begin
      ResDistribution := GetResDistribution(I);
      //Not enough resources ordered, add new demand
      if ResDeliveryCnt[I] < ResDistribution then
      begin
        Count := ResDistribution - ResDeliveryCnt[I];
        gHands[Owner].Deliveries.Queue.AddDemand(
          Self, nil, gRes.Houses[fType].ResInput[I], Count, dtOnce, diNorm);

        ResDeliveryCnt[I] := ResDeliveryCnt[I] + Count;
      end;

      //Too many resources ordered, attempt to remove demand if nobody has taken it yet
      if ResDeliveryCnt[I] > ResDistribution then
      begin
        Excess := ResDeliveryCnt[I] - ResDistribution;
        Count := gHands[Owner].Deliveries.Queue.TryRemoveDemand(Self, gRes.Houses[fType].ResInput[I], Excess);

        ResDeliveryCnt[I] := ResDeliveryCnt[I] - Count; //Only reduce it by the number that were actually removed
      end;

    end;
end;


function TKMHouse.ObjToString(const aSeparator: String = '|'): String;
var
  I: Integer;
  ActStr,ResOutPoolStr: String;
begin
  ActStr := 'nil';
  if CurrentAction <> nil then
    ActStr := CurrentAction.ClassName;

  ResOutPoolStr := '';
  for I := Low(fResourceOutPool) to High(fResourceOutPool) do
  begin
    if ResOutPoolStr <> '' then
      ResOutPoolStr := ResOutPoolStr + ',';
    if I = 10 then
      ResOutPoolStr := ResOutPoolStr + aSeparator;
    ResOutPoolStr := ResOutPoolStr + IntToStr(fResourceOutPool[I]);
  end;


  Result := '|' + ObjToStringShort(aSeparator) +
            Format('%sHasOwner = %s%sOwner = %d%sAction = %s%sRepair = %s%sIsClosedForWorker = %s%sDeliveryMode = %s%s' +
                   'NewDeliveryMode = %s%sDamage = %d%s' +
                   'BuildState = %s%sBuildSupplyWood = %d%sBuildSupplyStone = %d%sBuildingProgress = %d%sDoorwayUse = %d%s' +
                   'ResIn = %d,%d,%d,%d%sResDeliveryCnt = %d,%d,%d,%d%sResOut = %d,%d,%d,%d%sResOrder = %d,%d,%d,%d%sResOutPool = %s',
                   [aSeparator,
                    BoolToStr(fHasOwner, True), aSeparator,
                    Owner, aSeparator,
                    ActStr, aSeparator,
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
                    fResourceIn[1], fResourceIn[2], fResourceIn[3], fResourceIn[4], aSeparator,
                    fResourceDeliveryCount[1], fResourceDeliveryCount[2], fResourceDeliveryCount[3], fResourceDeliveryCount[4], aSeparator,
                    fResourceOut[1], fResourceOut[2], fResourceOut[3], fResourceOut[4], aSeparator,
                    fResourceOrder[1], fResourceOrder[2], fResourceOrder[3], fResourceOrder[4], aSeparator,
                    ResOutPoolStr]);
end;


procedure TKMHouse.UpdateState(aTick: Cardinal);
const
  HOUSE_PLAN_SIGHT = 2;
var
  I, K: Integer;
  HouseUnoccupiedMsgId: Integer;
  HA: THouseArea;
begin
  if not IsComplete then
  begin
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

  //Show unoccupied message if needed and house belongs to human player and can have owner at all
  //and is not closed for worker and not a barracks
  if not fDisableUnoccupiedMessage and not fHasOwner and not fIsClosedForWorker
  and (gRes.Houses[fType].OwnerType <> utNone) and (fType <> htBarracks) then
  begin
    Dec(fTimeSinceUnoccupiedReminder);
    if fTimeSinceUnoccupiedReminder = 0 then
    begin
      HouseUnoccupiedMsgId := gRes.Houses[fType].UnoccupiedMsgId;
      if HouseUnoccupiedMsgId <> -1 then // HouseNotOccupMsgId should never be -1
        gGame.ShowMessage(mkHouse, HouseUnoccupiedMsgId, Entrance, Owner)
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
                    gRenderPool.AddHouseSupply(fType, fPosition, fResourceIn, fResourceOut, fResourceOutPool);
                    if CurrentAction <> nil then
                      gRenderPool.AddHouseWork(fType, fPosition, CurrentAction.SubAction, WorkAnimStep, gHands[Owner].GameFlagColor);
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


{TKMHouseSwineStable}
constructor TKMHouseSwineStable.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.CheckMarker('HouseSwineStable');
  LoadStream.Read(BeastAge, SizeOf(BeastAge));
end;


//Return ID of beast that has grown up
function TKMHouseSwineStable.FeedBeasts: Byte;
var
  I: Integer;
begin
  Result := 0;
  Inc(BeastAge[KaMRandom(5, 'TKMHouseSwineStable.FeedBeasts') + 1]); //Let's hope it never overflows MAX
  for I := 1 to Length(BeastAge) do
    if BeastAge[I] > 3 then
      Result := I;
end;


procedure TKMHouseSwineStable.TakeBeast(aID: Byte);
begin
  if (aID<>0) and (BeastAge[aID]>3) then
    BeastAge[aID] := 0;
end;


//Make beast noises - each beast makes a noise (if it exists) with two second pauses between each one
procedure TKMHouseSwineStable.MakeSound;
var
  I: Integer;
begin
  inherited;
  if gMySpectator.FogOfWar.CheckTileRevelation(fPosition.X, fPosition.Y) < 255 then Exit;

  for I := 0 to 4 do
  if BeastAge[I+1] > 0 then
  if (FlagAnimStep + 20*I) mod 100 = 0 then
  begin
    if fType = htStables then
      gSoundPlayer.Play(TSoundFX(byte(sfxHorse1) + Random(4)), fPosition); //sfxHorse1..sfxHorse4
    if fType = htSwine   then
      gSoundPlayer.Play(TSoundFX(byte(sfxPig1)   + Random(4)), fPosition); //sfxPig1..sfxPig4
  end;
end;


procedure TKMHouseSwineStable.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  SaveStream.PlaceMarker('HouseSwineStable');
  SaveStream.Write(BeastAge, SizeOf(BeastAge));
end;


procedure TKMHouseSwineStable.Paint;
var I: Integer;
begin
  inherited;
  //We render beasts on top of the HouseWork (which is mostly flames in this case), because otherwise
  //Swinefarm looks okay, but Stables are totaly wrong - flames are right on horses backs!
  if fBuildState = hbsDone then
    for I := 1 to 5 do
      if BeastAge[I] > 0 then
        gRenderPool.AddHouseStableBeasts(fType, fPosition, I, Min(BeastAge[I],3), WorkAnimStep);

  //But Animal Breeders should be on top of beasts
  if CurrentAction <> nil then
    gRenderPool.AddHouseWork(fType, fPosition,
                            CurrentAction.SubAction * [haWork1, haWork2, haWork3, haWork4, haWork5],
                            WorkAnimStep, gHands[Owner].GameFlagColor);
end;


{ TKMHouseStore }
procedure TKMHouseStore.Activate(aWasBuilt:boolean);
var
  FirstStore: TKMHouseStore;
  RT: TKMWareType;
begin
  inherited;
  //A new storehouse should inherrit the accept properies of the first storehouse of that player,
  //which stops a sudden flow of unwanted resources to it as soon as it is create.
  FirstStore := TKMHouseStore(gHands[Owner].FindHouse(htStore, 1));
  if (FirstStore <> nil) and not FirstStore.IsDestroyed then
    for RT := WARE_MIN to WARE_MAX do
    begin
      NotAcceptFlag[RT] := FirstStore.NotAcceptFlag[RT];
      NotAllowTakeOutFlag[RT] := FirstStore.NotAllowTakeOutFlag[RT];
    end;
end;


procedure TKMHouseStore.SetWareCnt(aWareType: TKMWareType; aValue: Word);
var
  CntChange: Integer;
begin
  Assert(aWareType in [WARE_MIN..WARE_MAX]);

  CntChange := aValue - fWaresCount[aWareType];

  fWaresCount[aWareType] := aValue;

  if CntChange <> 0 then
    gScriptEvents.ProcHouseWareCountChanged(Self, aWareType, aValue, CntChange);
end;


constructor TKMHouseStore.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.CheckMarker('HouseStore');
  LoadStream.Read(fWaresCount, SizeOf(fWaresCount));
  LoadStream.Read(NotAcceptFlag, SizeOf(NotAcceptFlag));
  LoadStream.Read(NotAllowTakeOutFlag, SizeOf(NotAllowTakeOutFlag));
end;


procedure TKMHouseStore.ResAddToIn(aWare: TKMWareType; aCount: Integer = 1; aFromScript: Boolean = False);
var R: TKMWareType;
begin
  case aWare of
    wtAll:     for R := Low(fWaresCount) to High(fWaresCount) do begin
                  SetWareCnt(R, EnsureRange(fWaresCount[R] + aCount, 0, High(Word)));
                  gHands[Owner].Deliveries.Queue.AddOffer(Self, R, aCount);
                end;
    WARE_MIN..
    WARE_MAX:   begin
                  SetWareCnt(aWare, EnsureRange(fWaresCount[aWare] + aCount, 0, High(Word)));
                  gHands[Owner].Deliveries.Queue.AddOffer(Self,aWare,aCount);
                end;
    else        raise ELocError.Create('Cant''t add ' + gRes.Wares[aWare].Title, Position);
  end;
end;


function TKMHouseStore.ResCanAddToIn(aWare: TKMWareType): Boolean;
begin
  Result := (aWare in [WARE_MIN..WARE_MAX]);
end;


function TKMHouseStore.ResOutputAvailable(aWare: TKMWareType; const aCount: Word): Boolean;
begin
  Assert(aWare in [WARE_MIN..WARE_MAX]);
  Result := (fWaresCount[aWare] >= aCount);
end;


function TKMHouseStore.CheckResIn(aWare: TKMWareType): Word;
begin
  if aWare in [WARE_MIN..WARE_MAX] then
    Result := fWaresCount[aWare]
  else
    raise Exception.Create('Unexpected aWareType');
end;


procedure TKMHouseStore.DemolishHouse(aFrom: TKMHandID; IsSilent: Boolean = False);
var
  R: TKMWareType;
begin
  for R := WARE_MIN to WARE_MAX do
    gHands[Owner].Stats.WareConsumed(R, fWaresCount[R]);

  inherited;
end;


procedure TKMHouseStore.ResTakeFromOut(aWare: TKMWareType; aCount: Word=1; aFromScript: Boolean = False);
begin
  if aFromScript then
  begin
    aCount := Min(aCount, fWaresCount[aWare]);
    if aCount > 0 then
    begin
      gHands[Owner].Stats.WareConsumed(aWare, aCount);
      gHands[Owner].Deliveries.Queue.RemOffer(Self, aWare, aCount);
    end;
  end;
  Assert(aCount <= fWaresCount[aWare]);

  SetWareCnt(aWare, fWaresCount[aWare] - aCount);
end;


procedure TKMHouseStore.ToggleNotAcceptFlag(aWare: TKMWareType);
const
  //Using shortints instead of bools makes it look much neater in code-view
  CHEAT_SP_PATTERN: array [WARE_MIN..WARE_MAX] of Byte = (
    0,0,1,0,0,
    0,1,0,1,0,
    1,0,0,0,1,
    1,0,0,0,1,
    1,1,1,1,1,
    0,0,0);
var
  ware: TKMWareType;
  cheatPattern: Boolean;
begin
  // Dunno why thats happening sometimes..
  Assert(aWare in [WARE_MIN .. WARE_MAX]);

  // We need to skip cheats in MP replays too, not just MP games, so don't use fGame.IsMultiplayer
  if CHEATS_SP_ENABLED and (MULTIPLAYER_CHEATS or not (gGameParams.Mode in [gmMulti, gmMultiSpectate, gmReplayMulti])) then
  begin
    // Check the cheat pattern
    cheatPattern := True;
    for ware := Low(fWaresCount) to High(fWaresCount) do
      cheatPattern := cheatPattern and (NotAcceptFlag[ware] = Boolean(CHEAT_SP_PATTERN[ware]));

    if cheatPattern then
      case aWare of
        wtArbalet: begin
                      ResAddToIn(wtAll, 10);
                      gHands[Owner].Stats.WareProduced(wtAll, 10);
                      Exit;
                    end;
        wtHorse:   if not gGameParams.IsMultiPlayerOrSpec then
                    begin
                      // Game results cheats should not be used in MP even in debug
                      // MP does Win/Defeat differently (without Hold)
                      gGame.RequestHold(grWin);
                      Exit;
                    end;
        wtFish:    if not gGameParams.IsMultiPlayerOrSpec then
                    begin
                      // Game results cheats should not be used in MP even in debug
                      // MP does Win/Defeat differently (without Hold)
                      gGame.RequestHold(grDefeat);
                      Exit;
                    end;
      end;
  end;

  NotAcceptFlag[aWare] := not NotAcceptFlag[aWare];
end;


procedure TKMHouseStore.ToggleNotAcceptTakeOutFlag(aWare: TKMWareType);
begin
  NotAllowTakeOutFlag[aWare] := not NotAllowTakeOutFlag[aWare];
end;


procedure TKMHouseStore.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  SaveStream.PlaceMarker('HouseStore');
  SaveStream.Write(fWaresCount, SizeOf(fWaresCount));
  SaveStream.Write(NotAcceptFlag, SizeOf(NotAcceptFlag));
  SaveStream.Write(NotAllowTakeOutFlag, SizeOf(NotAllowTakeOutFlag));
end;


function TKMHouseStore.ShouldAbandonDeliveryTo(aWareType: TKMWareType): Boolean;
begin
  Result := inherited or NotAcceptFlag[aWareType];
end;


//Check if we should abandon TakeOut delivery (evacuate) from this house to aToHouse
function TKMHouseStore.ShouldAbandonDeliveryFromTo(aToHouse: TKMHouse; aWareType: TKMWareType; aImmidiateCheck: Boolean): Boolean;
begin
  Result := inherited or ((aToHouse <> nil)
                           and (aToHouse is TKMHouseStore)
                           and aToHouse.IsComplete
                           and ((GetDeliveryModeForCheck(aImmidiateCheck) <> dmTakeOut)
                                //Cancel delivery depends if we want to made immidiate check or not
                                //When Player sees "serf enters Store" then f.e. Player wants immidiately cancel this serf delivery
                                //In that case Delivery state will be set too late, and cancellation will be not applied
                                or NotAllowTakeOutFlag[aWareType]));
end;


{ TKMHouseArmorWorkshop }
constructor TKMHouseArmorWorkshop.Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
begin
  inherited;
  fAcceptWood := True;
  fAcceptLeather := True;
end;


constructor TKMHouseArmorWorkshop.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.CheckMarker('HouseArmorWorkshop');
  LoadStream.Read(fAcceptWood);
  LoadStream.Read(fAcceptLeather);
end;


procedure TKMHouseArmorWorkshop.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  SaveStream.PlaceMarker('HouseArmorWorkshop');
  SaveStream.Write(fAcceptWood);
  SaveStream.Write(fAcceptLeather);
end;


procedure TKMHouseArmorWorkshop.ToggleResDelivery(aWareType: TKMWareType);
begin
  case aWareType of
    wtWood: fAcceptWood := not fAcceptWood;
    wtLeather: fAcceptLeather := not fAcceptLeather;
  end;
end;


function TKMHouseArmorWorkshop.AcceptWareForDelivery(aWareType: TKMWareType): Boolean;
begin
  Result := False;
  case aWareType of
    wtWood: Result := fAcceptWood;
    wtLeather: Result := fAcceptLeather;
  end;
end;


function TKMHouseArmorWorkshop.ShouldAbandonDeliveryTo(aWareType: TKMWareType): Boolean;
begin
  Result := inherited or not AcceptWareForDelivery(aWareType);
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
  if fHouse.fType <> htMill then fHouse.WorkAnimStep := 0; //Exception for mill so that the windmill doesn't jump frames
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
begin
  fFlagPoint := GetValidPoint(aFlagPoint);
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
      P := KMPoint(P.X + 2*KaMRandom(2, 'TKMHouseWFlagPoint.GetValidPoint') - 1, P.Y) // Offset = +1 or -1
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

