unit KM_HandLogistics;
{$I KaM_Remake.inc}
interface
uses
  {$IF Defined(FPC) or Defined(VER230)}
  {$ELSE}
    {$DEFINE USE_HASH}
  {$IFEND}

  {$IFDEF USE_VIRTUAL_TREEVIEW}VirtualTrees, {$ENDIF}

  {$IFDEF USE_HASH}
  Generics.Collections, Generics.Defaults, System.Hash,
  {$ENDIF}
  KM_Units, KM_Houses, KM_ResHouses,
  KM_HandEntity, KM_HandTypes,
  KM_ResWares, KM_CommonClasses, KM_Defaults, KM_Points,
  BinaryHeapGen,
  KM_ResTypes;


type
  TKMDemandType = (
    dtOnce,   // One-time demand like usual
    dtAlways  // Constant (store, barracks)
  );

  // Sorted from lowest to highest importance
  TKMDemandImportance = (
    diNorm,  //Everything (lowest importance)
    diHigh4, //Materials to workers
    diHigh3, //Food to Inn
    diHigh2, //Food to soldiers
    diHigh1  //Gold to School (highest importance)
  );

  TKMDeliveryJobStatus = (
    jsEmpty, // Empty - empty spot for a new job
    jsTaken  // Taken - job is taken by some worker
  );

  PKMDeliveryOffer = ^TKMDeliveryOffer;
  TKMDeliveryOffer = record
    Ware: TKMWareType;
    Count: Cardinal; //How many items are offered
    Loc_House: TKMHouse;
    BeingPerformed: Cardinal; //How many items are being delivered atm from total Count offered
    //Keep offer until serfs that do it abandons it
    IsDeleted: Boolean;
    {$IFDEF USE_VIRTUAL_TREEVIEW}
    Node: PVirtualNode;
    {$ENDIF}
    procedure Cleanup;
    procedure Reset;
  end;

  PKMDeliveryDemand = ^TKMDeliveryDemand;
  TKMDeliveryDemand =  record
    Ware: TKMWareType;
    DemandType: TKMDemandType; //Once for everything, Always for Store and Barracks
    Importance: TKMDemandImportance; //How important demand is, e.g. Workers and building sites should be diHigh
    Loc_House: TKMHouse;
    Loc_Unit: TKMUnit;
    BeingPerformed: Cardinal; //Can be performed multiple times for dtAlways
    IsDeleted: Boolean; //So we don't get pointer issues
    NotifyLocHouseOnClose: Boolean; //Should we notify Loc_House when demand is closed (house could need to do some his actions on that)
    {$IFDEF USE_VIRTUAL_TREEVIEW}
    Node: PVirtualNode;
    {$ENDIF}
    procedure Cleanup;
    procedure Reset;
    function GetDemandEntity: TKMHandEntity;
  end;

  PKMDeliveryQueueItem = ^TKMDeliveryQueueItem;
  TKMDeliveryQueueItem = record
    Serf: TKMUnitSerf;
    IsFromUnit: Boolean; //Delivery was redispatched, so now we start delivery from current serf position
    OfferID, DemandID: Integer;
    JobStatus: TKMDeliveryJobStatus; //Empty slot, resource Taken, job Done
    {$IFDEF USE_VIRTUAL_TREEVIEW}
    Node: PVirtualNode;
    {$ENDIF}
    procedure Reset;
    procedure Cleanup;
  end;

  PKMLogisticsIDs = ^TKMLogisticsIDs;
  TKMLogisticsIDs = record
    HandID: Integer;
    ID: Integer;
  end;

  TKMDeliveryRouteStep = (drsSerfToOffer, drsOfferToDemand);

  {$IFDEF USE_HASH}
  //Bids cache key
  TKMDeliveryRouteBidKey = record
    FromP: TKMPoint; //House or Unit UID From where delivery path goes
    ToP: TKMPoint;   //same for To where delivery path goes
    Pass: TKMTerrainPassability;   //same for To where delivery path goes
    function GetHashCode: Integer;
  end;

  //Custom key comparator. Probably TDictionary can handle it himself, but lets try our custom comparator
  TKMDeliveryRouteBidKeyEqualityComparer = class(TEqualityComparer<TKMDeliveryRouteBidKey>)
    function Equals(const Left, Right: TKMDeliveryRouteBidKey): Boolean; override;
    function GetHashCode(const Value: TKMDeliveryRouteBidKey): Integer; override;
  end;

  //Comparer just to make some order by keys
  TKMDeliveryRouteBidKeyComparer = class(TComparer<TKMDeliveryRouteBidKey>)
    function Compare(const Left, Right: TKMDeliveryRouteBidKey): Integer; override;
  end;

  TKMDeliveryRouteBid = record
    Value: Single;
    RouteStep: TKMDeliveryRouteStep;
    CreatedAt: Integer; //Cached bid time to live, we have to update it from time to time
    function GetTTL: Integer;
    function IsExpired(aTick: Integer): Boolean;
  end;

  TKMDeliveryRouteCache = class(TDictionary<TKMDeliveryRouteBidKey, TKMDeliveryRouteBid>)
  public
    function TryGetValue(const aKey: TKMDeliveryRouteBidKey; var aBid: TKMDeliveryRouteBid): Boolean; reintroduce;
    procedure Add(const FromP: TKMPoint; ToP: TKMPoint; const aValue: Single; const aKind: TKMDeliveryRouteStep); reintroduce; overload;
    procedure Add(const aKey: TKMDeliveryRouteBidKey; const aValue: Single; const aRouteStep: TKMDeliveryRouteStep); reintroduce; overload;
//    procedure Add(const aKey: TKMDeliveryBidKey; const aBid: TKMDeliveryBid); reintroduce; overload;
  end;

  TKMDeliveryCalcKind = (dckFast, dckAccurate);

  TKMDeliveryRouteCalcCost = record
    Value: Single;
    Pass: TKMTerrainPassability;
  end;

  TKMDeliveryBid = class
  public
    Serf: TKMUnitSerf;
    QueueID: Integer;
    OfferID: Integer;
    DemandID: Integer;

    Importance: TKMDemandImportance;

    SerfToOffer: TKMDeliveryRouteCalcCost;
    OfferToDemand: TKMDeliveryRouteCalcCost;
    Addition: Single;

    constructor Create(aSerf: TKMUnitSerf); overload;
    constructor Create(aImportance: TKMDemandImportance; aSerf: TKMUnitSerf; iO, iD: Integer; iQ: Integer = DELIVERY_NO_ID); overload;

    function Cost: Single;
    procedure ResetValues;
    function IsValid: Boolean;

    procedure IncAddition(aValue: Single);
  end;

  TKMDeliveryBidCalcEventType = (bceBid, bceBidBasic, bceSerfBid);

  {$ENDIF}

  TKMDeliveryRouteEvaluator = class
  private
    {$IFDEF USE_HASH}
    fUpdatesCnt: Integer; //Keep number of updates
    // Cache of bid costs between 2 points
    fBidsRoutesCache: TKMDeliveryRouteCache; //cache

    fRemoveKeysList: TList<TKMDeliveryRouteBidKey>; //list of items to remove from cache. Create / Destroy it only once
    fNodeList: TKMPointList; // Used to calc delivery bid
    {$ENDIF}

    function DoTryEvaluate(aFromPos, aToPos: TKMPoint; aPass: TKMTerrainPassability; out aRoutCost: Single): Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    function EvaluateFast(const aFromPos, aToPos: TKMPoint): Single;

    function TryEvaluateAccurate(const aFromPos, aToPos: TKMPoint; aPass: TKMTerrainPassability; out aRouteCost: Single;
                                 aRouteStep: TKMDeliveryRouteStep): Boolean;
    procedure CleanCache;

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

    procedure UpdateState;
  end;


type
  //We need to combine 2 approaches for wares > serfs and wares < serfs
  //Houses signal when they have new wares/needs
  //Serfs signal when they are free to perform actions
  //List should be able to override Idling Serfs action
  //List should not override serfs deliveries even if the other serf can do it quicker,
  //because it will look bad to player, if first serfs stops for no reason
  //List does the comparison between houses and serfs and picks best pairs
  //(logic can be quite complicated and try to predict serfs/wares ETA)
  //Comparison function could be executed more rare or frequent depending on signals from houses/serfs
  //e.g. with no houses signals it can sleep till first on. At any case - not more frequent than 1/tick
  //TKMDeliveryList = class; //Serfs, Houses/Warriors/Workers

  TKMDeliveries = class
  private
    fOwner: TKMHandID;
    fOfferCount: Integer;
    fOffer: array of TKMDeliveryOffer;
    fDemandCount: Integer;
    fDemand: array of TKMDeliveryDemand;
    fQueueCount: Integer;
    fQueue: array of TKMDeliveryQueueItem;

    fRouteEvaluator: TKMDeliveryRouteEvaluator;

    fBestBidCandidates: TObjectBinaryHeap<TKMDeliveryBid>;
    fBestBids: TObjectBinaryHeap<TKMDeliveryBid>;

    function AllowFormLogisticsChange: Boolean;
    {$IFDEF USE_VIRTUAL_TREEVIEW}
    procedure SetVSTData(aVST: TVirtualStringTree; Node: PVirtualNode; aHandID, aID: Integer);
    {$ENDIF}
    procedure Form_UpdateOfferNode(aI: Integer);
    procedure Form_UpdateDemandNode(aI: Integer);
    procedure Form_UpdateQueueNode(aI: Integer);

    function CompareBids(A, B: TKMDeliveryBid): Boolean;

    function GetSerfActualPos(aSerf: TKMUnit): TKMPoint;
    procedure CloseDelivery(aID: Integer);
    procedure CloseDemand(aID: Integer);
    procedure CloseOffer(aID: Integer);
    function ValidDelivery(iO, iD: Integer; aIgnoreOffer: Boolean = False): Boolean;
    function SerfCanDoDelivery(iO, iD: Integer; aSerf: TKMUnitSerf): Boolean;
    function PermitDelivery(iO, iD: Integer; aSerf: TKMUnitSerf): Boolean;
    function TryCalculateBid(aCalcKind: TKMDeliveryCalcKind; var aBidCost: TKMDeliveryBid; aSerf: TKMUnitSerf = nil): Boolean; overload;
    function TryCalculateBidBasic(aCalcKind: TKMDeliveryCalcKind; var aBidBasicCost: TKMDeliveryBid; aSerf: TKMUnitSerf = nil;
                                  aAllowOffroad: Boolean = False): Boolean; overload;
    function TryCalculateBidBasic(aCalcKind: TKMDeliveryCalcKind; aOfferPos: TKMPoint; aOfferCnt: Cardinal; aOfferHouseType: TKMHouseType;
                                  aOwner: TKMHandID; var aBidBasicCost: TKMDeliveryBid; aSerf: TKMUnitSerf = nil;
                                  aAllowOffroad: Boolean = False): Boolean; overload;
    function TryCalcSerfBidValue(aCalcKind: TKMDeliveryCalcKind; aSerf: TKMUnitSerf; const aOfferPos: TKMPoint; var aBidBasicCost: TKMDeliveryBid): Boolean;
    function TryCalcRouteCost(aCalcKind: TKMDeliveryCalcKind; aFromPos, aToPos: TKMPoint; aRouteStep: TKMDeliveryRouteStep; var aRoutCost: TKMDeliveryRouteCalcCost;
                              aSecondPass: TKMTerrainPassability = tpNone): Boolean;
//    function GetUnitsCntOnPath(aNodeList: TKMPointList): Integer;

    function DoChooseBestBid(aCalcEventType: TKMDeliveryBidCalcEventType;aBestImportance: TKMDemandImportance; aSerf: TKMUnitSerf;
                             const aOfferPos: TKMPoint; aAllowOffroad: Boolean = False): TKMDeliveryBid;
    function ChooseBestBid(aBestImportance: TKMDemandImportance; aSerf: TKMUnitSerf = nil): TKMDeliveryBid;
    function ChooseBestBidBasic(aBestImportance: TKMDemandImportance; aAllowOffroad: Boolean): TKMDeliveryBid;
    function ChooseBestSerfBid(const aOfferPos: TKMPoint): TKMDeliveryBid;
    function GetDemand(aDemandID: Integer): TKMDeliveryDemand;
    function GetOffer(aOfferID: Integer): TKMDeliveryOffer;
    function GetDelivery(aQueueID: Integer): TKMDeliveryQueueItem;
    function GetWareType(aQueueID: Integer): TKMWareType;
  public
    constructor Create(aHandIndex: TKMHandID);
    destructor Destroy; override;
    procedure AddOffer(aHouse: TKMHouse; aWare: TKMWareType; aCount: Integer);
    procedure RemAllOffers(aHouse: TKMHouse);
    procedure RemOffer(aHouse: TKMHouse; aWare: TKMWareType; aCount: Cardinal);

    function GetDemandsCnt(aHouse: TKMHouse; aResource: TKMWareType; aType: TKMDemandType; aImp: TKMDemandImportance): Integer;
    procedure AddDemand(aHouse: TKMHouse; aUnit: TKMUnit; aResource: TKMWareType; aCount: Integer; aType: TKMDemandType; aImp: TKMDemandImportance);
    function TryRemoveDemand(aHouse: TKMHouse; aResource: TKMWareType; aCount: Word; aRemoveBeingPerformed: Boolean = True): Word; overload;
    function TryRemoveDemand(aHouse: TKMHouse; aResource: TKMWareType; aCount: Word; out aPlannedToRemove: Word;
                             aRemoveBeingPerformed: Boolean = True): Word; overload;
    procedure RemDemand(aHouse: TKMHouse); overload;
    procedure RemDemand(aUnit: TKMUnit); overload;

    function IsDeliveryAlowed(aIQ: Integer): Boolean;

    function GetDeliveriesToHouseCnt(aHouse: TKMHouse; aWareType: TKMWareType): Integer;

    function GetAvailableDeliveriesCount: Integer;
    procedure ReAssignDelivery(iQ: Integer; aSerf: TKMUnitSerf);
    procedure AssignDelivery(iO, iD: Integer; aSerf: TKMUnitSerf);
    function AskForDelivery(aSerf: TKMUnitSerf; aHouse: TKMHouse = nil): Boolean;
    procedure CheckForBetterDemand(aDeliveryID: Integer; out aToHouse: TKMHouse; out aToUnit: TKMUnit; aSerf: TKMUnitSerf);
    procedure DeliveryFindBestDemand(aSerf: TKMUnitSerf; aDeliveryId: Integer; aResource: TKMWareType; out aToHouse: TKMHouse; out aToUnit: TKMUnit; out aForceDelivery: Boolean);
    procedure TakenOffer(aID: Integer);
    procedure GaveDemand(aID: Integer);
    procedure AbandonDelivery(aID: Integer); //Occurs when unit is killed or something alike happens

    property Delivery[aQueueID: Integer]: TKMDeliveryQueueItem read GetDelivery;
    property DeliveryCount: Integer read fQueueCount;
    property DeliveryWare[aQueueID: Integer]: TKMWareType read GetWareType;

    property Demand[aDemandID: Integer]: TKMDeliveryDemand read GetDemand;
    property DemandCount: Integer read fDemandCount;

    property Offer[aOfferID: Integer]: TKMDeliveryOffer read GetOffer;
    property OfferCount: Integer read fOfferCount;

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad;

    procedure UpdateState;

    procedure Form_UpdateAllNodes;
    procedure Form_NilAllNodes;

    procedure ExportToFile(const aFileName: UnicodeString);
  end;

  TKMHandLogistics = class
  private
    fQueue: TKMDeliveries;

    fSerfCount: Integer;
    fSerfs: array of record //Not sure what else props we planned to add here
      Serf: TKMUnitSerf;
    end;

    procedure RemSerf(aIndex: Integer);
    procedure RemoveExtraSerfs;
    function GetIdleSerfCount: Integer;
    function GetQueue: TKMDeliveries;
  public
    constructor Create(aHandIndex: TKMHandID);
    destructor Destroy; override;

    procedure AddSerf(aSerf: TKMUnitSerf);
    property Queue: TKMDeliveries read GetQueue;

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad;
    procedure UpdateState(aTick: Cardinal);
  end;


implementation
uses
  Classes, SysUtils, Math, TypInfo,
  KM_Terrain,
  KM_FormLogistics, KM_UnitTaskDelivery,
  KM_Main, KM_Game, KM_GameParams, KM_Hand, KM_HandsCollection, KM_HouseBarracks, KM_HouseStore,
  KM_Resource, KM_ResUnits,
  KM_Log, KM_Utils, KM_CommonUtils, KM_DevPerfLog, KM_DevPerfLogTypes;


const
  //Max distance to use pathfinding on calc delivery bids. No need to calc on very long distance
  BID_CALC_MAX_DIST_FOR_PATHF = 100;
  //Approx compensation to compare Bid cost calc with pathfinding and without it. Pathfinding is usually longer
  BID_CALC_PATHF_COMPENSATION = 0.9;
  LENGTH_INC = 32; //Increment array lengths by this value
  NOT_REACHABLE_DEST_VALUE = MaxSingle;
  CACHE_CLEAN_FREQ = 100; //In update counts
  OFFER_DEMAND_CACHED_BID_TTL = 50; //In ticks. DeliveryUpdate is not made every tick
  SERF_OFFER_CACHED_BID_TTL = 30;   //In ticks. DeliveryUpdate is not made every tick

  BIDS_TO_COMPARE = 10; // Maximum number of bids to compare among candidates (how many routes to calc)


{ TKMHandLogistics }
constructor TKMHandLogistics.Create(aHandIndex: TKMHandID);
begin
  fQueue := TKMDeliveries.Create(aHandIndex);
end;


destructor TKMHandLogistics.Destroy;
begin
  FreeAndNil(fQueue);
  inherited;
end;


procedure TKMHandLogistics.Save(SaveStream: TKMemoryStream);
var
  I: Integer;
begin
  SaveStream.PlaceMarker('SerfList');

  SaveStream.Write(fSerfCount);
  for I := 0 to fSerfCount - 1 do
    SaveStream.Write(fSerfs[I].Serf.UID);

  fQueue.Save(SaveStream);
end;


procedure TKMHandLogistics.Load(LoadStream: TKMemoryStream);
var
  I: Integer;
begin
  LoadStream.CheckMarker('SerfList');

  LoadStream.Read(fSerfCount);
  SetLength(fSerfs, fSerfCount);
  for I := 0 to fSerfCount - 1 do
    LoadStream.Read(fSerfs[I].Serf, 4);

  fQueue.Load(LoadStream);
end;


procedure TKMHandLogistics.SyncLoad;
var
  I: Integer;
  U: TKMUnit;
begin
  for I := 0 to fSerfCount - 1 do
  begin
    U := gHands.GetUnitByUID(Cardinal(fSerfs[I].Serf));
    Assert(U is TKMUnitSerf, 'Non-serf in delivery list');
    fSerfs[I].Serf := TKMUnitSerf(U);
  end;
  fQueue.SyncLoad;
end;


//Add the Serf to the List
procedure TKMHandLogistics.AddSerf(aSerf: TKMUnitSerf);
begin
  if fSerfCount >= Length(fSerfs) then
    SetLength(fSerfs, fSerfCount + LENGTH_INC);

  fSerfs[fSerfCount].Serf := TKMUnitSerf(aSerf.GetPointer);
  Inc(fSerfCount);
end;


//Remove died Serf from the List
procedure TKMHandLogistics.RemSerf(aIndex: Integer);
begin
  gHands.CleanUpUnitPointer(TKMUnit(fSerfs[aIndex].Serf));

  //Serf order is not important, so we just move last one into freed spot
  if aIndex <> fSerfCount - 1 then
    fSerfs[aIndex] := fSerfs[fSerfCount - 1];

  Dec(fSerfCount);
end;


function TKMHandLogistics.GetIdleSerfCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to fSerfCount - 1 do
    if fSerfs[I].Serf.IsIdle then
      Inc(Result);
end;


function TKMHandLogistics.GetQueue: TKMDeliveries;
begin
  if Self = nil then Exit(nil);

  Result := fQueue;
end;


//Remove dead serfs
procedure TKMHandLogistics.RemoveExtraSerfs;
var
  I: Integer;
begin
  for I := fSerfCount - 1 downto 0 do
    if fSerfs[I].Serf.IsDeadOrDying then
      RemSerf(I);
end;


procedure TKMHandLogistics.UpdateState(aTick: Cardinal);

  function AnySerfCanDoDelivery(iO,iD: Integer): Boolean;
  var
    I: Integer;
  begin
    Result := False;
    for I := 0 to fSerfCount - 1 do
      if fSerfs[I].Serf.IsIdle and fQueue.SerfCanDoDelivery(iO, iD, fSerfs[I].Serf) then
        Exit(True);
  end;

var
  I, K, iD, iO: Integer;
  offerPos: TKMPoint;
  bid, serfBid: TKMDeliveryBid;
  bestImportance: TKMDemandImportance;
  availableDeliveries, availableSerfs: Integer;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psDelivery);
  {$ENDIF}
  try
    fQueue.UpdateState;
    RemoveExtraSerfs;

    availableDeliveries := fQueue.GetAvailableDeliveriesCount;
    availableSerfs := GetIdleSerfCount;
    if availableSerfs * availableDeliveries = 0 then Exit;

    if availableDeliveries > availableSerfs then
    begin
      for I := 0 to fSerfCount - 1 do
        if fSerfs[I].Serf.IsIdle then
          fQueue.AskForDelivery(fSerfs[I].Serf);
    end
    else
    //I is not used anywhere, but we must loop through once for each delivery available so each one is taken
    for I := 0 to availableDeliveries - 1 do
    begin
      //First we decide on the best delivery to be done based on current Offers and Demands
      //We need to choose the best delivery out of all of them, otherwise we could get
      //a further away storehouse when there are multiple possibilities.
      //Note: All deliveries will be taken, because we have enough serfs to fill them all.
      //The important concept here is to always get the shortest delivery when a delivery can be taken to multiple places.
      bestImportance := Low(TKMDemandImportance);

      fQueue.fBestBidCandidates.Clear;
      fQueue.fBestBidCandidates.EnlargeTo(fQueue.fDemandCount * fQueue.fOfferCount);

      for iD := 0 to fQueue.fDemandCount - 1 do
        if (fQueue.fDemand[iD].Ware <> wtNone)
          and (fQueue.fDemand[iD].Importance >= bestImportance) then //Skip any less important than the best we found
          for iO := 0 to fQueue.fOfferCount - 1 do
            if (fQueue.fOffer[iO].Ware <> wtNone)
              and fQueue.ValidDelivery(iO,iD)
              and AnySerfCanDoDelivery(iO,iD) then //Only choose this delivery if at least one of the serfs can do it
            begin
              bid := TKMDeliveryBid.Create(fQueue.fDemand[iD].Importance, nil, iO, iD);
              if fQueue.TryCalculateBid(dckFast, bid) then
              begin
                fQueue.fBestBidCandidates.Push(bid);
                bestImportance := bid.Importance;
              end
              else
                bid.Free;
            end;

      bid := fQueue.ChooseBestBid(bestImportance);

      //Found bid give us the best delivery to do at this moment. Now find the best serf for the job.
      if bid <> nil then
      begin
        offerPos := fQueue.fOffer[bid.OfferID].Loc_House.PointBelowEntrance;
        fQueue.fBestBidCandidates.Clear;
        fQueue.fBestBidCandidates.EnlargeTo(fSerfCount);
        serfBid := nil;
        for K := 0 to fSerfCount - 1 do
          if fSerfs[K].Serf.IsIdle then
            if fQueue.SerfCanDoDelivery(bid.OfferID, bid.DemandID, fSerfs[K].Serf) then
            begin
              serfBid := TKMDeliveryBid.Create(fSerfs[K].Serf);

              if fQueue.TryCalcSerfBidValue(dckFast, fSerfs[K].Serf, offerPos, serfBid) then
                fQueue.fBestBidCandidates.Push(serfBid);
            end;

        serfBid := fQueue.ChooseBestSerfBid(offerPos);

        if serfBid <> nil then
        begin
          fQueue.AssignDelivery(bid.OfferID, bid.DemandID, serfBid.Serf);
          serfBid.Free;
        end;
        bid.Free;
      end;
    end;
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psDelivery);
    {$ENDIF}
  end;
end;


{ TKMDeliveries }
constructor TKMDeliveries.Create(aHandIndex: TKMHandID);
const
  INIT_BIDS_HEAP_SIZE = 100;
begin
  fOwner := aHandIndex;

  fRouteEvaluator := TKMDeliveryRouteEvaluator.Create;
  fBestBidCandidates := TObjectBinaryHeap<TKMDeliveryBid>.Create(INIT_BIDS_HEAP_SIZE, CompareBids);
  fBestBids := TObjectBinaryHeap<TKMDeliveryBid>.Create(BIDS_TO_COMPARE, CompareBids);

  if AllowFormLogisticsChange then
    FormLogistics.Clear;
end;


destructor TKMDeliveries.Destroy;
begin
  fBestBids.Free;
  fBestBidCandidates.Free;
  fRouteEvaluator.Free;

  inherited;
end;


function TKMDeliveries.AllowFormLogisticsChange: Boolean;
begin
  Result := gMain.IsDebugChangeAllowed and Assigned(FormLogistics) and FormLogistics.IsEnabled;
end;


{$IFDEF USE_VIRTUAL_TREEVIEW}
procedure TKMDeliveries.SetVSTData(aVST: TVirtualStringTree; Node: PVirtualNode; aHandID, aID: Integer);
var
  data: PKMLogisticsIDs;
begin
  data := aVST.GetNodeData(Node);
  data.HandID := aHandID;
  data.ID := aID;
end;
{$ENDIF}


// Update FormLogistics offer item
procedure TKMDeliveries.Form_UpdateOfferNode(aI: Integer);
begin
  {$IFDEF USE_VIRTUAL_TREEVIEW}
  if aI >= fOfferCount then Exit;

  with fOffer[aI] do
    if AllowFormLogisticsChange
      and (gGame <> nil) and not gGame.ReadyToStop
      and (Ware <> wtNone) then
    begin
      if Node = nil then
        Node := FormLogistics.VSTOffers.AddChild(nil); //Add to root

      SetVSTData(FormLogistics.VSTOffers, Node, fOwner, aI);

      FormLogistics.FilterNode(FormLogistics.VSTOffers, Node);
    end;
  {$ENDIF}
end;


// Update FormLogistics demand item
procedure TKMDeliveries.Form_UpdateDemandNode(aI: Integer);
begin
  {$IFDEF USE_VIRTUAL_TREEVIEW}
  if aI >= fDemandCount then Exit;

  with fDemand[aI] do
    if AllowFormLogisticsChange
      and (gGame <> nil) and not gGame.ReadyToStop
      and (Ware <> wtNone) then
    begin
      if Node = nil then
        Node := FormLogistics.VSTDemands.AddChild(nil); //Add to root

      SetVSTData(FormLogistics.VSTDemands, Node, fOwner, aI);

      FormLogistics.FilterNode(FormLogistics.VSTDemands, Node);
    end;
  {$ENDIF}
end;


// Update FormLogistics queue item
procedure TKMDeliveries.Form_UpdateQueueNode(aI: Integer);
begin
  {$IFDEF USE_VIRTUAL_TREEVIEW}
  if aI >= fQueueCount then Exit;

  if AllowFormLogisticsChange then
    with fQueue[aI] do
    begin
      if DemandID = DELIVERY_NO_ID then Exit;

      if fDemand[DemandID].Ware = wtNone then Exit; // Check via DemandID, since OfferID could be 0 for redispatched deliveries

      if Node = nil then
        Node := FormLogistics.VSTDeliveries.AddChild(nil); //Add to root

      SetVSTData(FormLogistics.VSTDeliveries, Node, fOwner, aI);

      FormLogistics.FilterNode(FormLogistics.VSTDeliveries, Node);
    end;
  {$ENDIF}
end;


// Update FormLogistics items (all of them)
procedure TKMDeliveries.Form_UpdateAllNodes;
{$IFDEF USE_VIRTUAL_TREEVIEW}
var
  I: Integer;
{$ENDIF}
begin
  if Self = nil then Exit;

  {$IFDEF USE_VIRTUAL_TREEVIEW}
  for I := 0 to fQueueCount - 1 do
    Form_UpdateQueueNode(I);

  for I := 0 to fOfferCount - 1 do
    Form_UpdateOfferNode(I);

  for I := 0 to fDemandCount - 1 do
    Form_UpdateDemandNode(I);

  // Update form only once, after all Nodes were created
  FormLogistics.VSTUpdate;
  {$ENDIF}
end;


procedure TKMDeliveries.Form_NilAllNodes;
{$IFDEF USE_VIRTUAL_TREEVIEW}
var
  I: Integer;
{$ENDIF}
begin
  if Self = nil then Exit;

  {$IFDEF USE_VIRTUAL_TREEVIEW}
  for I := 0 to fQueueCount - 1 do
     fQueue[I].Node := nil;

  for I := 0 to fOfferCount - 1 do
    fOffer[I].Node := nil;

  for I := 0 to fDemandCount - 1 do
    fDemand[I].Node := nil;
  {$ENDIF}
end;


//Adds new Offer to the list. List is stored without sorting
//(it matters only for Demand to keep everything in waiting its order in line),
//so we just find an empty place and write there.
procedure TKMDeliveries.AddOffer(aHouse: TKMHouse; aWare: TKMWareType; aCount: Integer);
var
  I, K: Integer;
begin
  if gGameParams.IsMapEditor then
    Exit;
  if aCount = 0 then
    Exit;

  //Add Count of resource to old offer
  for I := 0 to fOfferCount - 1 do
    if (fOffer[I].Loc_House = aHouse)
    and (fOffer[I].Ware = aWare) then
    begin
      if fOffer[I].IsDeleted then
      begin
        //Revive old offer because some serfs are still walking to perform it
        Assert(fOffer[I].BeingPerformed > 0);
        fOffer[I].Count :=  aCount;
        fOffer[I].IsDeleted := False;

        Form_UpdateOfferNode(I);
        Exit; //Count added, thats all
      end
      else
      begin
        Inc(fOffer[I].Count, aCount);

        Form_UpdateOfferNode(I);

        Exit; //Count added, thats all
      end;
    end;

  //Find empty place or allocate new one
  I := 0;
  while (I < fOfferCount) and (fOffer[I].Ware <> wtNone) do
    Inc(I);
  if I >= fOfferCount then
  begin
    Inc(fOfferCount, LENGTH_INC);
    SetLength(fOffer, fOfferCount);
    for K := I to fOfferCount - 1 do
      //We could do fOffer[K].Reset here, but FillChar is a bit faster
      FillChar(fOffer[K], SizeOf(fOffer[K]), #0);
  end;

  //Add offer
  with fOffer[I] do
  begin
    if aHouse <> nil then
      Loc_House := aHouse.GetPointer;
    Ware := aWare;
    Count := aCount;
    Assert((BeingPerformed = 0) and not IsDeleted); //Make sure this item has been closed properly, if not there is a flaw

    Form_UpdateOfferNode(I);
  end;
end;


//Remove Offer from the list. E.G on house demolish
//List is stored without sorting so we have to parse it to find that entry..
procedure TKMDeliveries.RemAllOffers(aHouse: TKMHouse);
var
  I: Integer;
begin
  if gGameParams.IsMapEditor then
    Exit;

  //We need to parse whole list, never knowing how many offers the house had
  for I := 0 to fOfferCount - 1 do
  if fOffer[I].Loc_House = aHouse then
    if fOffer[I].BeingPerformed > 0 then
    begin
      //Keep it until all associated deliveries are abandoned
      fOffer[I].IsDeleted := True; //Don't reset it until serfs performing this offer are done with it
      fOffer[I].Count := 0; //Make the count 0 so no one else tries to take this offer
      Form_UpdateOfferNode(I);
    end
    else
      CloseOffer(I);
end;


procedure TKMDeliveries.RemOffer(aHouse: TKMHouse; aWare: TKMWareType; aCount: Cardinal);
var
  I: Integer;
begin
  if gGameParams.IsMapEditor then
    Exit;
  if aCount = 0 then
    Exit;

  //Add Count of resource to old offer
  for I := 0 to fOfferCount - 1 do
    if (fOffer[I].Loc_House = aHouse)
      and (fOffer[I].Ware = aWare)
      and not fOffer[I].IsDeleted then
    begin
      Assert(fOffer[I].Count >= aCount, 'Removing too many offers');
      Dec(fOffer[I].Count, aCount);
      if fOffer[I].Count = 0 then
      begin
        if fOffer[I].BeingPerformed > 0 then
          fOffer[I].IsDeleted := True
        else
          CloseOffer(I);
      end;
      Form_UpdateOfferNode(I);
      Exit; //Count decreased, that's all
    end;
  raise Exception.Create('Failed to remove offer');
end;


//Remove Demand from the list
// List is stored without sorting so we parse it to find all entries..
procedure TKMDeliveries.RemDemand(aHouse: TKMHouse);
var
  I: Integer;
begin
  if gGameParams.IsMapEditor then
    Exit;

  Assert(aHouse <> nil);
  for I := 0 to fDemandCount - 1 do
    if fDemand[I].Loc_House = aHouse then
    begin
      if fDemand[I].BeingPerformed > 0 then
        //Can't free it yet, some serf is using it
        fDemand[I].IsDeleted := True
      else
        CloseDemand(I); //Clear up demand
      //Keep on scanning cos House can have multiple demands entries
    end;
end;


//Check if delivery is allowed to continue
function TKMDeliveries.IsDeliveryAlowed(aIQ: Integer): Boolean;
begin
  if fQueue[aIQ].DemandID <> DELIVERY_NO_ID then
    Result := not fDemand[fQueue[aIQ].DemandId].IsDeleted //Delivery could be cancelled because of Demand marked as Deleted
  else
    Result := False; //Not allowed delivery if demandId is underfined (= DELIVERY_NO_ID)
end;


//Remove Demand from the list
// List is stored without sorting so we parse it to find all entries..
procedure TKMDeliveries.RemDemand(aUnit: TKMUnit);
var
  I: Integer;
begin
  if gGameParams.IsMapEditor then
    Exit;
  Assert(aUnit <> nil);
  for I := 0 to fDemandCount - 1 do
  if fDemand[I].Loc_Unit = aUnit then
  begin
    if fDemand[I].BeingPerformed > 0 then
      //Can't free it yet, some serf is using it
      fDemand[I].IsDeleted := True
    else
      CloseDemand(I); //Clear up demand
    //Keep on scanning cos Unit can have multiple demands entries (foreseeing Walls building)
  end;
end;


function TKMDeliveries.GetDeliveriesToHouseCnt(aHouse: TKMHouse; aWareType: TKMWareType): Integer;
var
  I, iD: Integer;
begin
  Result := 0;
  for I := 0 to fQueueCount - 1 do
  begin
    if fQueue[I].JobStatus = jsTaken then
    begin
      iD := fQueue[I].DemandId;
      if (fDemand[iD].Loc_House = aHouse)
        and (fDemand[iD].Ware = aWareType)
        and not fDemand[iD].IsDeleted
        and (fDemand[iD].BeingPerformed > 0) then
        Inc(Result);
    end;
  end;
end;


function TKMDeliveries.TryRemoveDemand(aHouse: TKMHouse; aResource: TKMWareType; aCount: Word; aRemoveBeingPerformed: Boolean = True): Word;
var
  plannedToRemove: Word;
begin
  Result := TryRemoveDemand(aHouse, aResource, aCount, plannedToRemove);
end;


//Attempt to remove aCount demands from this house and report the number
//if there are some being performed, then mark them as deleted, so they will be cancelled as soon as possible
function TKMDeliveries.TryRemoveDemand(aHouse: TKMHouse; aResource: TKMWareType; aCount: Word; out aPlannedToRemove: Word;
                                       aRemoveBeingPerformed: Boolean = True): Word;
var
  I: Integer;
  PlannedIDs: array of Integer;
begin
  Result := 0;
  aPlannedToRemove := 0;

  if gGameParams.IsMapEditor then
    Exit;

  if aCount = 0 then Exit;
  Assert(aHouse <> nil);
  for I := fDemandCount - 1 downto 0 do
    if (fDemand[I].Loc_House = aHouse)
      and (fDemand[I].Ware = aResource)
      and not fDemand[I].IsDeleted then
    begin
      if fDemand[I].BeingPerformed = 0 then
      begin
        CloseDemand(I); //Clear up demand
        Inc(Result);
      end
      else
      begin
        //Collect all performing demands first (but limit it with `NEEDED - FOUND`)
        if aRemoveBeingPerformed and (aPlannedToRemove < aCount - Result) then
        begin
          if Length(PlannedIDs) = 0 then
            SetLength(PlannedIDs, aCount); //Set length of PlannedIDs only once

          PlannedIDs[aPlannedToRemove] := I;
          Inc(aPlannedToRemove);
        end;
      end;
      if Result = aCount then
        Break; //We have removed enough demands
    end;

  if aRemoveBeingPerformed then
    //If we didn't find enough not performed demands, mark found performing demands as deleted to be removed soon
    for I := 0 to Min(aPlannedToRemove, aCount - Result) - 1 do
    begin
      fDemand[PlannedIDs[I]].IsDeleted := True;
      fDemand[PlannedIDs[I]].NotifyLocHouseOnClose := aRemoveBeingPerformed;
    end;
end;


function TKMDeliveries.GetDelivery(aQueueID: Integer): TKMDeliveryQueueItem;
begin
  Result := fQueue[aQueueID];
end;


function TKMDeliveries.GetDemand(aDemandID: Integer): TKMDeliveryDemand;
begin
  Result := fDemand[aDemandID];
end;


function TKMDeliveries.GetOffer(aOfferID: Integer): TKMDeliveryOffer;
begin
  Result := fOffer[aOfferID];
end;


function TKMDeliveries.GetDemandsCnt(aHouse: TKMHouse; aResource: TKMWareType; aType: TKMDemandType; aImp: TKMDemandImportance): Integer;
var
  I: Integer;
  Demand: TKMDeliveryDemand;
begin
  Result := 0;

  if (aHouse = nil) or (aResource = wtNone)  then Exit;

  for I := 0 to fDemandCount - 1 do
  begin
    Demand := fDemand[I];
    if (aResource = Demand.Ware)
      and (aHouse = Demand.Loc_House)
      and (aType = Demand.DemandType)
      and (aImp = Demand.Importance) then
      Inc(Result);
  end;
end;


//Adds new Demand to the list. List is stored sorted, but the sorting is done upon Deliver completion,
//so we just find an empty place (which is last one) and write there.
procedure TKMDeliveries.AddDemand(aHouse: TKMHouse; aUnit: TKMUnit; aResource: TKMWareType; aCount: Integer; aType: TKMDemandType; aImp: TKMDemandImportance);
var
  I,K,J: Integer;
begin
  if gGameParams.IsMapEditor then
    Exit;
  Assert(aResource <> wtNone, 'Demanding rtNone');
  if aCount <= 0 then Exit;

  for K := 0 to aCount - 1 do
  begin
    I := 0;
    while (I < fDemandCount) and (fDemand[I].Ware <> wtNone) do
      Inc(I);
    if I >= fDemandCount then
    begin
      Inc(fDemandCount, LENGTH_INC);
      SetLength(fDemand, fDemandCount);
      for J := I to fDemandCount - 1 do
        //We could do fDemand[J].Reset here, but FillChar is a bit faster
        FillChar(fDemand[J], SizeOf(fDemand[J]), #0);
    end;

    with fDemand[I] do
    begin
      if aHouse <> nil then
        Loc_House := aHouse.GetPointer;

      if aUnit <> nil then
        Loc_Unit := aUnit.GetPointer;

      DemandType := aType; //Once or Always
      Ware := aResource;
      Importance := aImp;
      Assert((not IsDeleted) and (BeingPerformed = 0)); //Make sure this item has been closed properly, if not there is a flaw

      //Gold to Schools
      if (Ware = wtGold)
        and (Loc_House <> nil) and (Loc_House.HouseType = htSchool) then
        Importance := diHigh1;

      //Food to Inn
      if (Ware in [wtBread, wtSausage, wtWine, wtFish])
        and (Loc_House <> nil) and (Loc_House.HouseType = htInn) then
        Importance := diHigh3;

      Form_UpdateDemandNode(I);
    end;
  end;
end;


//IgnoreOffer means we don't check whether offer was already taken or deleted (used after offer was already claimed)
function TKMDeliveries.ValidDelivery(iO, iD: Integer; aIgnoreOffer: Boolean = False): Boolean;
var
  I: Integer;
  B: TKMHouseBarracks;
begin
  // Conditions are called in the frequency of a negative Result: most negative first

  // 95% of the calls returns False after next condition
  //If Offer Resource matches Demand
  Result := (fDemand[iD].Ware = fOffer[iO].Ware) or
            (fDemand[iD].Ware = wtAll) or
            ((fDemand[iD].Ware = wtWarfare) and (fOffer[iO].Ware in [WARFARE_MIN..WARFARE_MAX])) or
            ((fDemand[iD].Ware = wtFood) and (fOffer[iO].Ware in [wtBread, wtSausage, wtWine, wtFish]));

  //If Demand and Offer aren't reserved already
  Result := Result and (aIgnoreOffer or (fOffer[iO].BeingPerformed < fOffer[iO].Count))
                   and ((fDemand[iD].DemandType = dtAlways) or (fDemand[iD].BeingPerformed = 0));

  Result := Result and (
            ( //House-House delivery should be performed only if there's a connecting road
            (fDemand[iD].Loc_House <> nil) and
            (gTerrain.Route_CanBeMade(fOffer[iO].Loc_House.PointBelowEntrance, fDemand[iD].Loc_House.PointBelowEntrance, tpWalkRoad, 0))
            )
            or
            ( //House-Unit delivery can be performed without connecting road
            (fDemand[iD].Loc_Unit <> nil) and
            (gTerrain.Route_CanBeMade(fOffer[iO].Loc_House.PointBelowEntrance, fDemand[iD].Loc_Unit.Position, tpWalk, 1))
            ));

  //If Demand house should abandon delivery
  Result := Result and ((fDemand[iD].Loc_House = nil)
                         or not fDemand[iD].Loc_House.IsComplete
                         or not fDemand[iD].Loc_House.ShouldAbandonDeliveryTo(fOffer[iO].Ware));

  //If Offer should not be abandoned
  Result := Result and not fOffer[iO].Loc_House.ShouldAbandonDeliveryFrom(fOffer[iO].Ware)
                   //Check store to store evacuation
                   and not fOffer[iO].Loc_House.ShouldAbandonDeliveryFromTo(fDemand[iD].Loc_House, fOffer[iO].Ware, False);

  //Warfare has a preference to be delivered to Barracks
  if Result
    and (fOffer[iO].Ware in [WARFARE_MIN..WARFARE_MAX])
    and (fDemand[iD].Loc_House <> nil) then
  begin
    //Permit delivery of warfares to Store only if player has no Barracks or they all have blocked ware
    if fDemand[iD].Loc_House.HouseType = htStore then
    begin
      //Scan through players Barracks, if none accepts - allow deliver to Store
      I := 1;
      repeat
        B := TKMHouseBarracks(gHands[fDemand[iD].Loc_House.Owner].FindHouse(htBarracks, I));
        //If the barracks will take the ware, don't allow the store to take it (disallow current delivery)
        if (B <> nil) and (B.DeliveryMode = dmDelivery) and not B.NotAcceptFlag[fOffer[iO].Ware] then
        begin
          Result := False;
          Break;
        end;
        Inc(I);
      until (B = nil);
    end;
  end;

  //If Demand and Offer aren't deleted
  Result := Result and not fDemand[iD].IsDeleted and (aIgnoreOffer or not fOffer[iO].IsDeleted);

  //Do not allow delivery from 1 house to same house (f.e. store)
  Result := Result and ((fDemand[iD].Loc_House = nil)
                       or (fDemand[iD].Loc_House.UID <> fOffer[iO].Loc_House.UID));

  //If Demand and Offer are different HouseTypes, means forbid Store<->Store deliveries
  //except the case where 2nd store is being built and requires building materials
  //or when we use TakeOut delivery (evacuation) mode for Offer Store
  Result := Result and ((fDemand[iD].Loc_House = nil)
                        or not ((fOffer[iO].Loc_House.HouseType = htStore) and (fDemand[iD].Loc_House.HouseType = htStore))
                        or not fDemand[iD].Loc_House.IsComplete
                        or ((fOffer[iO].Loc_House.DeliveryMode = dmTakeOut) and not TKMHouseStore(fOffer[iO].Loc_House).NotAllowTakeOutFlag[fOffer[iO].Ware]));

  //Allow transfers between Barracks only when offer barracks have DeliveryMode = dmTakeOut
  Result := Result and ((fDemand[iD].Loc_House = nil)
                        or (fDemand[iD].Loc_House.HouseType <> htBarracks)
                        or (fOffer[iO].Loc_House.HouseType <> htBarracks)
                        or (fOffer[iO].Loc_House.DeliveryMode = dmTakeOut));

  //Permit Barracks -> Store deliveries only if barracks delivery mode is TakeOut
  Result := Result and ((fDemand[iD].Loc_House = nil)
                        or (fDemand[iD].Loc_House.HouseType <> htStore)
                        or (fOffer[iO].Loc_House.HouseType <> htBarracks)
                        or (fOffer[iO].Loc_House.DeliveryMode = dmTakeOut));
end;


// Delivery is only permitted if the serf can access the From house.
function TKMDeliveries.SerfCanDoDelivery(iO,iD: Integer; aSerf: TKMUnitSerf): Boolean;
var
  LocA, LocB: TKMPoint;
begin
  LocA := GetSerfActualPos(aSerf);
  LocB := fOffer[iO].Loc_House.PointBelowEntrance;

  Result := aSerf.CanWalkTo(LocA, LocB, tpWalk, 0);
end;


function TKMDeliveries.PermitDelivery(iO,iD: Integer; aSerf: TKMUnitSerf): Boolean;
begin
  Result := ValidDelivery(iO, iD) and SerfCanDoDelivery(iO, iD, aSerf);
end;


function TKMDeliveries.GetSerfActualPos(aSerf: TKMUnit): TKMPoint;
begin
  Result := aSerf.Position;

  //If the serf is inside the house (invisible) test from point below
  if not aSerf.Visible then
    Result := KMPointBelow(Result);
end;


function TKMDeliveries.GetWareType(aQueueID: Integer): TKMWareType;
begin
  Result := fQueue[aQueueID].Serf.Carry;

  if Result in WARES_VALID then Exit;

  Result := fOffer[fQueue[aQueueID].OfferID].Ware;

  if Result in WARES_VALID then Exit;

  Result := fDemand[fQueue[aQueueID].DemandID].Ware;
end;


//Get the total number of possible deliveries with current Offers and Demands
function TKMDeliveries.GetAvailableDeliveriesCount: Integer;
var
  iD,iO: Integer;
  OffersTaken: Cardinal;
  DemandTaken: array of Boolean; //Each demand can only be taken once in our measurements
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psDelivery);
  {$ENDIF}
  try
    SetLength(DemandTaken, fDemandCount);
    if fDemandCount > 0 then
      FillChar(DemandTaken[0], SizeOf(Boolean)*fDemandCount, #0);

    Result := 0;
    for iO := 0 to fOfferCount - 1 do
      if (fOffer[iO].Ware <> wtNone) then
      begin
        OffersTaken := 0;
        for iD := 0 to fDemandCount - 1 do
          if (fDemand[iD].Ware <> wtNone) and not DemandTaken[iD] and ValidDelivery(iO,iD) then
          begin
            if fDemand[iD].DemandType = dtOnce then
            begin
              DemandTaken[iD] := True;
              Inc(Result);
              Inc(OffersTaken);
              if fOffer[iO].Count - OffersTaken = 0 then
                Break; //Finished with this offer
            end
            else
            begin
              //This demand will take all the offers, so increase result by that many
              Inc(Result, fOffer[iO].Count - OffersTaken);
              Break; //This offer is finished (because this demand took it all)
            end;
          end;
      end;
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psDelivery);
    {$ENDIF}
  end;
end;


//Try to Calc bid cost between serf and offer house
//Return False and aSerfBidValue = NOT_REACHABLE_DEST_VALUE, if house is not reachable by serf
function TKMDeliveries.TryCalcSerfBidValue(aCalcKind: TKMDeliveryCalcKind; aSerf: TKMUnitSerf; const aOfferPos: TKMPoint;
                                           var aBidBasicCost: TKMDeliveryBid): Boolean;
begin
  aBidBasicCost.SerfToOffer.Value := 0;
  Result := True;
  if aSerf = nil then Exit;

  // Set pass only for 1st fast calculation
  if aCalcKind = dckFast then
    aBidBasicCost.SerfToOffer.Pass := tpWalkRoad;

  //Also prefer deliveries near to the serf
  //Serf gets to first house with tpWalkRoad, if not possible, then with tpWalk
  Result := TryCalcRouteCost(aCalcKind, GetSerfActualPos(aSerf), aOfferPos, drsSerfToOffer, aBidBasicCost.SerfToOffer, tpWalk);
end;


//function TKMDeliveries.GetUnitsCntOnPath(aNodeList: TKMPointList): Integer;
//var
//  I: Integer;
//begin
//  Result := 0;
//  for I := 1 to aNodeList.Count - 1 do
//    Inc(Result, Byte(gTerrain.Land^[aNodeList[I].Y,aNodeList[I].X].IsUnit <> nil));
//end;


//Try to Calc route cost
//If destination is not reachable, then return False
function TKMDeliveries.TryCalcRouteCost(aCalcKind: TKMDeliveryCalcKind; aFromPos, aToPos: TKMPoint; aRouteStep: TKMDeliveryRouteStep;
                                        var aRoutCost: TKMDeliveryRouteCalcCost; aSecondPass: TKMTerrainPassability = tpNone): Boolean;

  function RouteCanBeMade(const LocA, LocB: TKMPoint; aPass: TKMTerrainPassability): Boolean; inline;
  begin
    if aPass = tpNone then
      Exit(False);

    Result := gTerrain.Route_CanBeMade(LocA, LocB, aPass, 0);
  end;

var
  passToUse: TKMTerrainPassability;
  canMakeRoute: Boolean;
  cost: Single;
begin
  passToUse := aRoutCost.Pass;

  case aCalcKind of
    dckFast:      begin
                    canMakeRoute := RouteCanBeMade(aFromPos, aToPos, passToUse);

                    if not canMakeRoute then
                    begin
                      passToUse := aSecondPass;
                      canMakeRoute := RouteCanBeMade(aFromPos, aToPos, passToUse);
                    end;

                    if not canMakeRoute then
                    begin
                      aRoutCost.Value := NOT_REACHABLE_DEST_VALUE;
                      Exit(False);
                    end;

                    Result := True;
                    aRoutCost.Value := fRouteEvaluator.EvaluateFast(aFromPos, aToPos);
                  end;
    dckAccurate:  begin
                    //
                    Result := fRouteEvaluator.TryEvaluateAccurate(aFromPos, aToPos, passToUse, cost, aRouteStep);
                    aRoutCost.Value := cost;
                  end;
    else
      raise Exception.Create('Wrong delivery bid route calc kind!');
  end;

  aRoutCost.Pass := passToUse;
end;


function TKMDeliveries.TryCalculateBidBasic(aCalcKind: TKMDeliveryCalcKind; var aBidBasicCost: TKMDeliveryBid;
                                            aSerf: TKMUnitSerf = nil; aAllowOffroad: Boolean = False): Boolean;
var
  iO: Integer;
begin
  iO := aBidBasicCost.OfferID;
  Result := TryCalculateBidBasic(aCalcKind, fOffer[iO].Loc_House.PointBelowEntrance, fOffer[iO].Count,
                                 fOffer[iO].Loc_House.HouseType, fOffer[iO].Loc_House.Owner, aBidBasicCost, aSerf,
                                 aAllowOffroad);
end;


//Calc bid cost between offer object (house, serf) and demand object (house, unit - worker or warrior)
function TKMDeliveries.TryCalculateBidBasic(aCalcKind: TKMDeliveryCalcKind; aOfferPos: TKMPoint; aOfferCnt: Cardinal; aOfferHouseType: TKMHouseType;
                                            aOwner: TKMHandID; var aBidBasicCost: TKMDeliveryBid; aSerf: TKMUnitSerf = nil;
                                            aAllowOffroad: Boolean = False): Boolean;
var
  iD: Integer;
  secondPass: TKMTerrainPassability;
begin
  Assert((aCalcKind = dckFast) or aBidBasicCost.IsValid); // For dckAccurate we assume cost was already calculated before and it was confirmed it's not unwalkable

  iD := aBidBasicCost.DemandID;

  Result := TryCalcSerfBidValue(aCalcKind, aSerf, aOfferPos, aBidBasicCost);
  if not Result then
    Exit;

  //For weapons production in cases with little resources available, they should be distributed
  //evenly between places rather than caring about route length.
  //This means weapon and armour smiths should get same amount of iron, even if one is closer to the smelter.
  if (fDemand[iD].Loc_House <> nil) and fDemand[iD].Loc_House.IsComplete
    and gResHouses[fDemand[iD].Loc_House.HouseType].DoesOrders
    and (aOfferCnt <= 3) //Little resources to share around
    and (fDemand[iD].Loc_House.CheckResIn(fDemand[iD].Ware) <= 2) then //Few resources already delivered
  begin
    if aCalcKind = dckAccurate then
      Exit;

    aBidBasicCost.OfferToDemand.Value := 7
      //Resource ratios are also considered
      + KaMRandom(65 - 13*gHands[aOwner].Stats.WareDistribution[fDemand[iD].Ware, fDemand[iD].Loc_House.HouseType],
                  'TKMDeliveries.TryCalculateBidBasic');
  end
  else
  begin
    //For all other cases - use distance approach. Direct length (rough) or pathfinding (exact)
    if fDemand[iD].Loc_House <> nil then
    begin
      secondPass := tpNone;
      if aAllowOffroad then
        secondPass := tpWalk;
      //Calc cost between offer and demand houses
      aBidBasicCost.OfferToDemand.Pass := tpWalkRoad;
      Result := TryCalcRouteCost(aCalcKind, aOfferPos, fDemand[iD].Loc_House.PointBelowEntrance, drsOfferToDemand, aBidBasicCost.OfferToDemand, secondPass);

      if aCalcKind = dckAccurate then
        Exit;

      //Resource ratios are also considered
      aBidBasicCost.IncAddition(KaMRandom(16 - 3*gHands[aOwner].Stats.WareDistribution[fDemand[iD].Ware, fDemand[iD].Loc_House.HouseType],
                                          'TKMDeliveries.TryCalculateBidBasic 2'));
    end
    else
    begin
      aBidBasicCost.OfferToDemand.Pass := tpWalk;
      //Calc bid cost between offer house and demand Unit (digged worker or hungry warrior)
      Result := TryCalcRouteCost(aCalcKind, aOfferPos, fDemand[iD].Loc_Unit.Position, drsOfferToDemand, aBidBasicCost.OfferToDemand);
    end;

    // There is no route, Exit immidiately
    if not Result then
      Exit;
  end;

  if aCalcKind = dckAccurate then
    Exit;

  //Deliver wood first to equal distance construction sites
  if (fDemand[iD].Loc_House <> nil)
    and not fDemand[iD].Loc_House.IsComplete then
  begin
    //Give priority to almost built houses
    aBidBasicCost.Addition := aBidBasicCost.Addition - 4*fDemand[iD].Loc_House.GetBuildResDeliveredPercent;
    //Only add a small amount so houses at different distances will be prioritized separately
    if (fDemand[iD].Ware = wtStone) then
      aBidBasicCost.IncAddition(0.1);
  end
  else
    //For all other deliveries, add some random element so in the case of identical
    //bids the same resource will not always be chosen (e.g. weapons storehouse->barracks
    //should take random weapon types not sequentially)
    aBidBasicCost.IncAddition(KaMRandom(10, 'TKMDeliveries.TryCalculateBidBasic 3'));

  if (fDemand[iD].Ware = wtAll)        // Always prefer deliveries House>House instead of House>Store
    or ((aOfferHouseType = htStore)    // Prefer taking wares from House rather than Store...
    and (fDemand[iD].Ware <> wtWarfare)) then //...except weapons Store>Barracks, that is also prefered
    aBidBasicCost.IncAddition(1000);
end;


function TKMDeliveries.TryCalculateBid(aCalcKind: TKMDeliveryCalcKind; var aBidCost: TKMDeliveryBid; aSerf: TKMUnitSerf = nil): Boolean;
var
  iO, iD: Integer;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psDelivery);
  {$ENDIF}
  try
    Result := TryCalculateBidBasic(aCalcKind, aBidCost, aSerf);

    if not Result or (aCalcKind = dckAccurate) then
      Exit;

    iO := aBidCost.OfferID;
    iD := aBidCost.DemandID;

    //Modifications for bidding system
    if (fDemand[iD].Loc_House <> nil) //Prefer delivering to houses with fewer supply
      and (fDemand[iD].Ware <> wtAll)
      and (fDemand[iD].Ware <> wtWarfare) //Except Barracks and Store, where supply doesn't matter or matter less
      and (fDemand[iD].Loc_House.HouseType <> htTownHall) then //Except TownHall as well, where supply doesn't matter or matter less
      aBidCost.IncAddition(20 * fDemand[iD].Loc_House.CheckResIn(fDemand[iD].Ware));

    if (fDemand[iD].Loc_House <> nil)
      and (fDemand[iD].Loc_House.HouseType = htTownHall) then
    begin
      //Delivering gold to TH - if there are already more then 500 gold, then make this delivery very low priority
      if (fDemand[iD].Loc_House.CheckResIn(fOffer[iO].Ware) > 500) then
        aBidCost.IncAddition(5000)
      else
        aBidCost.IncAddition(2); //Add small value, so it will not have so big advantage above other houses
    end;

    //Delivering weapons from store to barracks, make it lowest priority when there are >50 of that weapon in the barracks.
    //In some missions the storehouse has vast amounts of weapons, and we don't want the serfs to spend the whole game moving these.
    //In KaM, if the barracks has >200 weapons the serfs will stop delivering from the storehouse. I think our solution is better.
    if (fDemand[iD].Loc_House <> nil)
      and (fDemand[iD].Loc_House.HouseType = htBarracks)
      and (fOffer[iO].Loc_House.HouseType = htStore)
      and (fDemand[iD].Loc_House.CheckResIn(fOffer[iO].Ware) > 50) then
      aBidCost.IncAddition(10000);

    //When delivering food to warriors, add a random amount to bid to ensure that a variety of food is taken. Also prefer food which is more abundant.
    if (fDemand[iD].Loc_Unit <> nil) and (fDemand[iD].Ware = wtFood) then
    begin
      //The more resource there is, the smaller Random can be. >100 we no longer care, it's just random 5.
      if fOffer[iO].Count = 0 then
        aBidCost.IncAddition(KaMRandom(5 + 150, 'TKMDeliveries.TryCalculateBidBasic 4'))
      else
        aBidCost.IncAddition(KaMRandom(5 + (100 div fOffer[iO].Count), 'TKMDeliveries.TryCalculateBidBasic 5'));
    end;
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psDelivery);
    {$ENDIF}
  end;
end;


procedure TKMDeliveries.CheckForBetterDemand(aDeliveryID: Integer; out aToHouse: TKMHouse; out aToUnit: TKMUnit; aSerf: TKMUnitSerf);
var
  iD, iO, bestD, oldD: Integer;
  bestImportance: TKMDemandImportance;
  bid: TKMDeliveryBid;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psDelivery);
  {$ENDIF}
  try
    iO := fQueue[aDeliveryID].OfferID;
    oldD := fQueue[aDeliveryID].DemandID;

    //Special rule to prevent an annoying situation: If we were delivering to a unit
    //do not look for a better demand. Deliveries to units are closely watched/controlled
    //by the player. For example if player orders food for group A, then after serfs start
    //walking to storehouse orders food for closer group B. Player expects A to be fed first
    //even though B is closer.
    //Another example: School is nearly finished digging at start of game. Serf is getting
    //stone for a labourer making a road. School digging finishes and the stone goes to the
    //school (which is closer). Now the road labourer is waiting even though the player saw
    //the serf fetching the stone for him before the school digging was finished.
    //This "CheckForBetterDemand" feature is mostly intended to optimise house->house
    //deliveries within village and reduce delay in serf decision making.
    if fDemand[oldD].Loc_Unit <> nil then
    begin
      aToHouse := fDemand[oldD].Loc_House;
      aToUnit := fDemand[oldD].Loc_Unit;
      Exit;
    end;

    //By default we keep the old demand, so that's our starting bid
    fBestBidCandidates.Clear;
    fBestBidCandidates.EnlargeTo(fDemandCount);

    if not fDemand[oldD].IsDeleted then
    begin
      bestImportance := fDemand[oldD].Importance;
      bid := TKMDeliveryBid.Create(bestImportance, aSerf, iO, oldD);
      if TryCalculateBid(dckFast, bid, aSerf) then
        fBestBidCandidates.Push(bid)
      else
        bid.Free;
    end
    else
    begin
      //Our old demand is no longer valid (e.g. house destroyed), so give it minimum weight
      //If no other demands are found we can still return this invalid one, TaskDelivery handles that
      bestImportance := Low(TKMDemandImportance);
    end;

    for iD := 0 to fDemandCount - 1 do
      if (fDemand[iD].Ware <> wtNone)
      and (oldD <> Id)
      and (fDemand[iD].Importance >= bestImportance) //Skip any less important than the best we found
      and ValidDelivery(iO, iD, True) then
      begin
        bid := TKMDeliveryBid.Create(fDemand[iD].Importance, aSerf, iO, iD);
        if TryCalculateBid(dckFast, bid) then
        begin
          fBestBidCandidates.Push(bid);
          bestImportance := bid.Importance;
        end
        else
          bid.Free;
      end;

    bid := ChooseBestBid(bestImportance, aSerf);

    if bid <> nil then
    begin
      bestD := bid.DemandID;
      bid.Free;
    end
    else
      bestD := oldD;

    //Did we switch jobs?
    if bestD <> oldD then
    begin
      //Remove old demand
      Dec(fDemand[oldD].BeingPerformed);
      if (fDemand[oldD].BeingPerformed = 0) and fDemand[oldD].IsDeleted then
        CloseDemand(oldD);

      Form_UpdateDemandNode(oldD);

      //Take new demand
      fQueue[aDeliveryID].DemandID := bestD;
      Inc(fDemand[bestD].BeingPerformed); //Places a virtual "Reserved" sign on Demand

      Form_UpdateDemandNode(bestD);
    end;

    //Return chosen unit and house
    aToHouse := fDemand[bestD].Loc_House;
    aToUnit := fDemand[bestD].Loc_Unit;
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psDelivery);
    {$ENDIF}
  end;
end;

// Find best Demand for the given delivery. Could return same or nothing
procedure TKMDeliveries.DeliveryFindBestDemand(aSerf: TKMUnitSerf; aDeliveryId: Integer; aResource: TKMWareType;
                                               out aToHouse: TKMHouse; out aToUnit: TKMUnit; out aForceDelivery: Boolean);

  function ValidBestDemand(iD, iOldID: Integer): Boolean;
  var
    I: Integer;
    H: TKMHouse;
  begin
    Result := (fDemand[iD].Ware = aResource) or
              ((fDemand[iD].Ware = wtWarfare) and (aResource in [WARFARE_MIN..WARFARE_MAX])) or
              ((fDemand[iD].Ware = wtFood) and (aResource in [wtBread, wtSausage, wtWine, wtFish]));

    //Check if unit is alive
    Result := Result and ((fDemand[iD].Loc_Unit = nil)
                          or (not fDemand[iD].Loc_Unit.IsDeadOrDying and (fDemand[iD].Loc_Unit <> fDemand[iOldID].Loc_Unit)));

    //If Demand house should abandon delivery
    Result := Result and ((fDemand[iD].Loc_House = nil)
                          or not fDemand[iD].Loc_House.IsComplete
                          or (not fDemand[iD].Loc_House.ShouldAbandonDeliveryTo(aResource)
                             and (fDemand[iD].Loc_House <> fDemand[iOldID].Loc_House)));

    //If Demand aren't reserved already
    Result := Result and ((fDemand[iD].DemandType = dtAlways) or (fDemand[iD].BeingPerformed = 0));

    //For constructing houses check if they are connected with road to some other houses,
    //which can produce demanded ware (stone or wood)
    if Result
      and (fDemand[iD].Loc_House <> nil)
      and not fDemand[iD].Loc_House.IsComplete
      and not fDemand[iD].Loc_House.IsDestroyed then
      for I := 0 to gHands[fDemand[iD].Loc_House.Owner].Houses.Count - 1 do
      begin
        H := gHands[fDemand[iD].Loc_House.Owner].Houses[I];
        if H.IsComplete
          and not H.IsDestroyed
          and (H.ResCanAddToOut(fDemand[iD].Ware) //Check both - output and input ware, because we could use in theory takeout delivery...
            or H.ResCanAddToIn(fDemand[iD].Ware)) then
          Result := Result and gTerrain.Route_CanBeMade(H.PointBelowEntrance, fDemand[iD].Loc_House.PointBelowEntrance, tpWalkRoad, 0);
      end;
  end;

  function FindBestDemandId(): Integer;
  var
    iD, oldDemandId: Integer;
    bid: TKMDeliveryBid;
    bestImportance: TKMDemandImportance;
    allowOffroad: Boolean;
  begin
    Result := DELIVERY_NO_ID;
    aForceDelivery := False;
    oldDemandId := fQueue[aDeliveryId].DemandID;
    bestImportance := Low(TKMDemandImportance);

    //Mark that delivery as IsFromUnit (Serf), since we are looking for other destination while in delivery process
    fQueue[aDeliveryId].IsFromUnit := True;

    allowOffroad := True; //(fDemand[oldDemandId].Loc_Unit <> nil) or fQueue[aDeliveryId].IsFromUnit;

    fBestBidCandidates.Clear;
    fBestBidCandidates.EnlargeTo(fDemandCount);

    //Try to find house or unit demand first (not storage)
    for iD := 0 to fDemandCount - 1 do
      if (fDemand[iD].Ware <> wtNone)
        and (iD <> oldDemandId)
        and not fDemand[iD].IsDeleted
        and (fDemand[iD].Importance >= bestImportance)
        and ValidBestDemand(iD, oldDemandId) then
      begin
        bid := TKMDeliveryBid.Create(fDemand[iD].Importance, aSerf, 0, iD);
        if TryCalculateBidBasic(dckFast, aSerf.Position, 1, htNone, aSerf.Owner, bid, nil, allowOffroad) then
        begin
          fBestBidCandidates.Push(bid);
          bestImportance := bid.Importance;
        end
        else
          bid.Free;
      end;

    bid := ChooseBestBidBasic(bestImportance, allowOffroad);

    // If nothing was found, then try to deliver to open for delivery Storage
    if bid = nil then
    begin
      fBestBidCandidates.Clear;
      for iD := 0 to fDemandCount - 1 do
        if (fDemand[iD].Ware = wtAll)
          and (iD <> oldDemandId)
          and not fDemand[iD].IsDeleted
          and (fDemand[iD].Loc_House.DeliveryMode = dmDelivery)
          and (fDemand[iD].Loc_House is TKMHouseStore)
          and not TKMHouseStore(fDemand[iD].Loc_House).NotAcceptFlag[aResource] then
        begin
          bid := TKMDeliveryBid.Create(fDemand[iD].Importance, aSerf, 0, iD);
          if TryCalculateBidBasic(dckFast, aSerf.Position, 1, htNone, aSerf.Owner, bid, nil, allowOffroad) then
          begin
            fBestBidCandidates.Push(bid);
            bestImportance := bid.Importance;
          end
          else
            bid.Free;
        end;

        bid := ChooseBestBidBasic(bestImportance, allowOffroad);
    end;

    // If no open storage for delivery found, then try to find any storage or any barracks
    if bid = nil then
    begin
      fBestBidCandidates.Clear;
      for iD := 0 to fDemandCount - 1 do
        if (fDemand[iD].Ware = wtAll)
          and not fDemand[iD].IsDeleted
          and not fDemand[iD].Loc_House.IsDestroyed then //choose between all storages, including current delivery. But not destroyed
        begin
          bid := TKMDeliveryBid.Create(fDemand[iD].Importance, aSerf, 0, iD);
          if TryCalculateBidBasic(dckFast, aSerf.Position, 1, htNone, aSerf.Owner, bid, nil, allowOffroad) then
          begin
            fBestBidCandidates.Push(bid);
            bestImportance := bid.Importance;
            aForceDelivery := True;
          end
          else
            bid.Free;
        end;

        bid := ChooseBestBidBasic(bestImportance, allowOffroad);
    end;

    if bid <> nil then
    begin
      Result := bid.DemandID;
      bid.Free;
    end;
  end;
var
  bestDemandId, oldDemandId: Integer; // Keep Int to assign to Delivery down below
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psDelivery);
  {$ENDIF}
  try
    oldDemandId := fQueue[aDeliveryId].DemandID;
    bestDemandId := FindBestDemandId();

    // Did we find anything?
    if bestDemandId = DELIVERY_NO_ID then
    begin
      // Remove old demand
      Dec(fDemand[oldDemandId].BeingPerformed);
      if (fDemand[oldDemandId].BeingPerformed = 0) and fDemand[oldDemandId].IsDeleted then
        CloseDemand(oldDemandId);

      Form_UpdateDemandNode(oldDemandId);

      // Delivery should be cancelled now
      CloseDelivery(aDeliveryId);
      aToHouse := nil;
      aToUnit := nil;
    end
    else
    begin
      // Did we switch jobs?
      if bestDemandId <> oldDemandId then
      begin
        // Remove old demand
        Dec(fDemand[oldDemandId].BeingPerformed);
        if (fDemand[oldDemandId].BeingPerformed = 0) and fDemand[oldDemandId].IsDeleted then
          CloseDemand(oldDemandId);

        Form_UpdateDemandNode(oldDemandId);

        // Take new demand
        fQueue[aDeliveryId].DemandId := bestDemandId;
        Inc(fDemand[bestDemandId].BeingPerformed); //Places a virtual "Reserved" sign on Demand
        fQueue[aDeliveryId].IsFromUnit := True; //Now this delivery will always start from serfs hands

        Form_UpdateDemandNode(bestDemandId);
        Form_UpdateQueueNode(aDeliveryId);
      end;

      // Return chosen unit and house
      aToHouse := fDemand[bestDemandId].Loc_House;
      aToUnit := fDemand[bestDemandId].Loc_Unit;
    end;
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psDelivery);
    {$ENDIF}
  end;
end;


// Find best bid from the candidates list
// Build exact route instead (dckAccurate)
function TKMDeliveries.DoChooseBestBid(aCalcEventType: TKMDeliveryBidCalcEventType; aBestImportance: TKMDemandImportance; aSerf: TKMUnitSerf;
                                       const aOfferPos: TKMPoint; aAllowOffroad: Boolean = False): TKMDeliveryBid;
var
  K, bidsToCompare: Integer;
begin
  bidsToCompare := Min(BIDS_TO_COMPARE, fBestBidCandidates.Count);

  if bidsToCompare = 1 then
    Exit(fBestBidCandidates.Pop);

  fBestBids.Clear;
  for K := 0 to bidsToCompare - 1 do
  begin
    Result := fBestBidCandidates.Pop;
    // There could be bids with lower importance
    if Result.Importance < aBestImportance then
    begin
      Result.Free;
      Continue;
    end;

    case aCalcEventType of
      bceBid:       if TryCalculateBid(dckAccurate, Result, aSerf) then
                      fBestBids.Push(Result)
                    else
                      Result.Free;
      bceBidBasic:  if TryCalculateBidBasic(dckAccurate, Result.Serf.Position, 1, htNone, Result.Serf.Owner, Result, nil, aAllowOffroad) then
                      fBestBids.Push(Result)
                    else
                      Result.Free;
      bceSerfBid:   if TryCalcSerfBidValue(dckAccurate, Result.Serf, aOfferPos, Result) then
                      fBestBids.Push(Result)
                    else
                      Result.Free;
      else
        raise Exception.Create('Unknown CalcEventType');
    end;
  end;

  Result := fBestBids.Pop;
end;


function TKMDeliveries.ChooseBestBid(aBestImportance: TKMDemandImportance; aSerf: TKMUnitSerf = nil): TKMDeliveryBid;
begin
  Result := DoChooseBestBid(bceBid, aBestImportance, aSerf, KMPOINT_ZERO);
end;


function TKMDeliveries.ChooseBestBidBasic(aBestImportance: TKMDemandImportance; aAllowOffroad: Boolean): TKMDeliveryBid;
begin
  Result := DoChooseBestBid(bceBidBasic, aBestImportance, nil, KMPOINT_ZERO, aAllowOffroad);
end;


function TKMDeliveries.ChooseBestSerfBid(const aOfferPos: TKMPoint): TKMDeliveryBid;
begin
  Result := DoChooseBestBid(bceSerfBid, Low(TKMDemandImportance), nil, aOfferPos, False);
end;


//Should issue a job based on requesters location and job importance
//Serf may ask for a job from within a house after completing previous delivery
function TKMDeliveries.AskForDelivery(aSerf: TKMUnitSerf; aHouse: TKMHouse = nil): Boolean;
var
  iQ, iD, iO: Integer;
  bid: TKMDeliveryBid;
  bestImportance: TKMDemandImportance;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psDelivery);
  {$ENDIF}
  try
    //Find Offer matching Demand
    //TravelRoute Asker>Offer>Demand should be shortest
    bestImportance := Low(TKMDemandImportance);
    Result := False;

    fBestBidCandidates.Clear;
    fBestBidCandidates.EnlargeTo(fDemandCount * fOfferCount);

    for iD := 0 to fDemandCount - 1 do
      if (fDemand[iD].Ware <> wtNone)
        and (fDemand[iD].Importance >= bestImportance) then //Skip any less important than the best we found
        for iO := 0 to fOfferCount - 1 do
          if ((aHouse = nil) or (fOffer[iO].Loc_House = aHouse))  //Make sure from house is the one requested
            and (fOffer[iO].Ware <> wtNone)
            and PermitDelivery(iO, iD, aSerf) then
          begin
            bid := TKMDeliveryBid.Create(fDemand[iD].Importance, aSerf, iO, iD);
            if TryCalculateBid(dckFast, bid, aSerf) then
            begin
              fBestBidCandidates.Push(bid);
              bestImportance := bid.Importance;
            end
            else
              bid.Free;
          end;

    bid := ChooseBestBid(bestImportance, aSerf);

    if bid <> nil then
    begin
      AssignDelivery(bid.OfferID, bid.DemandID, aSerf);
      bid.Free;
      Result := True;
    end else
      //Try to find ongoing delivery task from specified house and took it from serf, which is on the way to that house
      if aHouse <> nil then
      begin
        bestImportance := Low(TKMDemandImportance);
        fBestBidCandidates.Clear;

        for iQ := 0 to fQueueCount - 1 do
          if (fQueue[iQ].JobStatus = jsTaken)
            and (fQueue[iQ].OfferID <> DELIVERY_NO_ID)
            and (fQueue[iQ].DemandID <> DELIVERY_NO_ID)
            and (fOffer[fQueue[iQ].OfferID].Loc_House = aHouse)
            and (fDemand[fQueue[iQ].DemandID].Importance >= bestImportance)
            and (TKMTaskDeliver(fQueue[iQ].Serf.Task).DeliverStage = dsToFromHouse) then // Serf can walk in this house
          begin
            bid := TKMDeliveryBid.Create(fDemand[fQueue[iQ].DemandID].Importance, aSerf, fQueue[iQ].OfferID, fQueue[iQ].DemandID, iQ);
            if TryCalculateBid(dckFast, bid, aSerf) then
            begin
              fBestBidCandidates.Push(bid);
              bestImportance := bid.Importance;
            end
            else
              bid.Free;
          end;

        bid := ChooseBestBid(bestImportance, aSerf);

        if bid <> nil then
        begin
          ReAssignDelivery(bid.QueueID, aSerf);
          bid.Free;
          Result := True;
        end;
      end;
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psDelivery);
    {$ENDIF}
  end;
end;


procedure TKMDeliveries.ReAssignDelivery(iQ: Integer; aSerf: TKMUnitSerf);
begin
  Assert(iQ < fQueueCount, 'iQ >= fQueueCount!');
  Assert(fQueue[iQ].JobStatus = jsTaken);

  if gLog.CanLogDelivery() then
    gLog.LogDelivery(Format('Hand [%d] - Reassign delivery ID %d from serf ID: %d to serf ID: %d', [fOwner, iQ, fQueue[iQ].Serf.UID, aSerf.UID]));

  fQueue[iQ].Serf.DelegateDelivery(aSerf);

  gHands.CleanUpUnitPointer(TKMUnit(fQueue[iQ].Serf));
  fQueue[iQ].Serf := TKMUnitSerf(aSerf.GetPointer);
  Form_UpdateQueueNode(iQ);
end;


procedure TKMDeliveries.AssignDelivery(iO,iD: Integer; aSerf: TKMUnitSerf);
var
  I, K: Integer;
begin
  //Find a place where Delivery will be written to after Offer-Demand pair is found
  I := 0;
  while (I < fQueueCount) and (fQueue[I].JobStatus <> jsEmpty) do
    Inc(I);

  if I >= fQueueCount then
  begin
    Inc(fQueueCount, LENGTH_INC);
    SetLength(fQueue, fQueueCount);
    for K := I to fQueueCount - 1 do
      fQueue[K].Reset;
  end;

  fQueue[I].DemandID := iD;
  fQueue[I].OfferID := iO;
  fQueue[I].JobStatus := jsTaken;
  fQueue[I].Serf := TKMUnitSerf(aSerf.GetPointer);

  {$IFDEF USE_VIRTUAL_TREEVIEW}
  fQueue[I].Node := nil;
  {$ENDIF}

  Form_UpdateQueueNode(I);

  Inc(fOffer[iO].BeingPerformed); //Places a virtual "Reserved" sign on Offer
  Inc(fDemand[iD].BeingPerformed); //Places a virtual "Reserved" sign on Demand
  Form_UpdateOfferNode(iO);
  Form_UpdateDemandNode(iD);

  gLog.LogDelivery('Creating delivery ID ' + IntToStr(I));

  //Now we have best job and can perform it
  if fDemand[iD].Loc_House <> nil then
    aSerf.Deliver(fOffer[iO].Loc_House, fDemand[iD].Loc_House, fOffer[iO].Ware, I)
  else
    aSerf.Deliver(fOffer[iO].Loc_House, fDemand[iD].Loc_Unit, fOffer[iO].Ware, I)
end;


//Resource has been taken from Offer
procedure TKMDeliveries.TakenOffer(aID: Integer);
var
  iO: Integer;
begin
  gLog.LogDelivery('Taken offer from delivery ID ' + IntToStr(aID));

  iO := fQueue[aID].OfferID;
  fQueue[aID].OfferID := DELIVERY_NO_ID; //We don't need it any more

  Dec(fOffer[iO].BeingPerformed); //Remove reservation
  Dec(fOffer[iO].Count); //Remove resource from Offer list

  if fOffer[iO].Count = 0 then
    if fOffer[iO].BeingPerformed > 0 then
      fOffer[iO].IsDeleted := True
    else
      CloseOffer(iO);

  Form_UpdateQueueNode(aID);
  Form_UpdateOfferNode(iO);
end;


//Resource has been delivered to Demand
procedure TKMDeliveries.GaveDemand(aID: Integer);
var
  iD: Integer;
begin
  gLog.LogDelivery('Gave demand from delivery ID ' + IntToStr(aID));
  iD := fQueue[aID].DemandID;
  fQueue[aID].DemandID := DELIVERY_NO_ID; //We don't need it any more

  Dec(fDemand[iD].BeingPerformed); //Remove reservation

  fDemand[iD].NotifyLocHouseOnClose := False; //No need to notify Loc_House since we already delivered item

  if (fDemand[iD].DemandType = dtOnce)
    or (fDemand[iD].IsDeleted and (fDemand[iD].BeingPerformed = 0)) then
    CloseDemand(iD); //Remove resource from Demand list
  Form_UpdateDemandNode(iD);
end;


//AbandonDelivery
procedure TKMDeliveries.AbandonDelivery(aID: Integer);
begin
  gLog.LogDelivery('Abandoned delivery ID ' + IntToStr(aID));
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psDelivery);
  {$ENDIF}
  try
    //Remove reservations without removing items from lists
    if fQueue[aID].OfferID <> DELIVERY_NO_ID then
    begin
      Dec(fOffer[fQueue[aID].OfferID].BeingPerformed);
      //Now see if we need to delete the Offer as we are the last remaining pointer
      if fOffer[fQueue[aID].OfferID].IsDeleted and (fOffer[fQueue[aID].OfferID].BeingPerformed = 0) then
        CloseOffer(fQueue[aID].OfferID);

      Form_UpdateOfferNode(fQueue[aID].OfferID);
    end;

    if fQueue[aID].DemandID <> DELIVERY_NO_ID then
    begin
      Dec(fDemand[fQueue[aID].DemandID].BeingPerformed);
      if fDemand[fQueue[aID].DemandID].IsDeleted and (fDemand[fQueue[aID].DemandID].BeingPerformed = 0) then
        CloseDemand(fQueue[aID].DemandID);

      Form_UpdateDemandNode(fQueue[aID].DemandID);
    end;

    CloseDelivery(aID);
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psDelivery);
    {$ENDIF}
  end;
end;


//Job successfully done and we ommit it
procedure TKMDeliveries.CloseDelivery(aID: Integer);
begin
  gLog.LogDelivery('Closed delivery ID ' + IntToStr(aID));

  fQueue[aID].OfferID := DELIVERY_NO_ID;
  fQueue[aID].DemandID := DELIVERY_NO_ID;
  fQueue[aID].JobStatus := jsEmpty; //Open slot
  gHands.CleanUpUnitPointer(TKMUnit(fQueue[aID].Serf));

  fQueue[aID].Cleanup;
end;


procedure TKMDeliveries.CloseDemand(aID: Integer);
begin
  Assert(fDemand[aID].BeingPerformed = 0);

  if fDemand[aID].NotifyLocHouseOnClose and (fDemand[aID].Loc_House <> nil) then
    fDemand[aID].Loc_House.DecResourceDelivery(fDemand[aID].Ware);

  fDemand[aID].NotifyLocHouseOnClose := False;
  fDemand[aID].Ware := wtNone;
  fDemand[aID].DemandType := dtOnce;
  fDemand[aID].Importance := Low(TKMDemandImportance);
  gHands.CleanUpHousePointer(fDemand[aID].Loc_House);
  gHands.CleanUpUnitPointer(fDemand[aID].Loc_Unit);
  fDemand[aID].IsDeleted := False;

  fDemand[aID].Cleanup;
end;


procedure TKMDeliveries.CloseOffer(aID: Integer);
begin
  Assert(fOffer[aID].BeingPerformed = 0);
  fOffer[aID].IsDeleted := false;
  fOffer[aID].Ware := wtNone;
  fOffer[aID].Count := 0;
  gHands.CleanUpHousePointer(fOffer[aID].Loc_House);

  fOffer[aID].Cleanup;
end;


function TKMDeliveries.CompareBids(A, B: TKMDeliveryBid): Boolean;
begin
  if (A = nil) then
    Exit(False);

  if (B = nil) then
    Exit(True);

  if A.Importance <> B.Importance then
    Exit(A.Importance > B.Importance);

  Result := A.Cost < B.Cost;
end;


procedure TKMDeliveries.Save(SaveStream: TKMemoryStream);
var
  I: Integer;
begin
  SaveStream.PlaceMarker('Deliveries');
  SaveStream.Write(fOwner);

  SaveStream.PlaceMarker('Offers');
  SaveStream.Write(fOfferCount);

  for I := 0 to fOfferCount - 1 do
  begin
    SaveStream.Write(fOffer[I].Ware, SizeOf(fOffer[I].Ware));
    SaveStream.Write(fOffer[I].Count);
    SaveStream.Write(fOffer[I].Loc_House.UID);
    SaveStream.Write(fOffer[I].BeingPerformed);
    SaveStream.Write(fOffer[I].IsDeleted);
  end;

  SaveStream.PlaceMarker('Demands');
  SaveStream.Write(fDemandCount);
  for I := 0 to fDemandCount - 1 do
  with fDemand[I] do
  begin
    SaveStream.Write(Ware, SizeOf(Ware));
    SaveStream.Write(DemandType, SizeOf(DemandType));
    SaveStream.Write(Importance, SizeOf(Importance));

    SaveStream.Write(Loc_House.UID);
    SaveStream.Write(Loc_Unit.UID );

    SaveStream.Write(BeingPerformed);
    SaveStream.Write(IsDeleted);
    SaveStream.Write(NotifyLocHouseOnClose);
  end;

  SaveStream.PlaceMarker('Queue');
  SaveStream.Write(fQueueCount);
  for I := 0 to fQueueCount - 1 do
  begin
    SaveStream.Write(fQueue[I].IsFromUnit);
    SaveStream.Write(fQueue[I].OfferID);
    SaveStream.Write(fQueue[I].DemandID);
    SaveStream.Write(fQueue[I].JobStatus, SizeOf(fQueue[I].JobStatus));
    SaveStream.Write(fQueue[I].Serf.UID );
  end;

  fRouteEvaluator.Save(SaveStream);
end;


procedure TKMDeliveries.Load(LoadStream: TKMemoryStream);
var
  I: Integer;
begin
  LoadStream.CheckMarker('Deliveries');
  LoadStream.Read(fOwner);

  LoadStream.CheckMarker('Offers');
  LoadStream.Read(fOfferCount);
  SetLength(fOffer, fOfferCount);

  for I := 0 to fOfferCount - 1 do
  begin
    LoadStream.Read(fOffer[I].Ware, SizeOf(fOffer[I].Ware));
    LoadStream.Read(fOffer[I].Count);
    LoadStream.Read(fOffer[I].Loc_House, 4);
    LoadStream.Read(fOffer[I].BeingPerformed);
    LoadStream.Read(fOffer[I].IsDeleted);
  end;

  LoadStream.CheckMarker('Demands');
  LoadStream.Read(fDemandCount);
  SetLength(fDemand, fDemandCount);
  for I := 0 to fDemandCount - 1 do
  with fDemand[I] do
  begin
    LoadStream.Read(Ware, SizeOf(Ware));
    LoadStream.Read(DemandType, SizeOf(DemandType));
    LoadStream.Read(Importance, SizeOf(Importance));
    LoadStream.Read(Loc_House, 4);
    LoadStream.Read(Loc_Unit, 4);
    LoadStream.Read(BeingPerformed);
    LoadStream.Read(IsDeleted);
    LoadStream.Read(NotifyLocHouseOnClose);
  end;

  LoadStream.CheckMarker('Queue');
  LoadStream.Read(fQueueCount);
  SetLength(fQueue, fQueueCount);
  for I := 0 to fQueueCount - 1 do
  begin
    LoadStream.Read(fQueue[I].IsFromUnit);
    LoadStream.Read(fQueue[I].OfferID);
    LoadStream.Read(fQueue[I].DemandID);
    LoadStream.Read(fQueue[I].JobStatus, SizeOf(fQueue[I].JobStatus));
    LoadStream.Read(fQueue[I].Serf, 4);
  end;

  fRouteEvaluator.Load(LoadStream);
end;


procedure TKMDeliveries.SyncLoad;
var
  I: Integer;
begin
  for I := 0 to fOfferCount - 1 do
  begin
    fOffer[I].Loc_House := gHands.GetHouseByUID(Cardinal(fOffer[I].Loc_House));
    Form_UpdateOfferNode(I);
  end;

  for I := 0 to fDemandCount - 1 do
    with fDemand[I] do
    begin
      Loc_House := gHands.GetHouseByUID(Cardinal(Loc_House));
      Loc_Unit := gHands.GetUnitByUID(Cardinal(Loc_Unit));
      Form_UpdateDemandNode(I);
    end;

  for I := 0 to fQueueCount - 1 do
  begin
    fQueue[I].Serf := TKMUnitSerf(gHands.GetUnitByUID(Cardinal(fQueue[I].Serf)));
    Form_UpdateQueueNode(I);
  end;
end;


procedure TKMDeliveries.UpdateState;
begin
  fRouteEvaluator.UpdateState;

  // Update form logistics
  if AllowFormLogisticsChange then
    FormLogistics.VSTUpdate;
end;


procedure TKMDeliveries.ExportToFile(const aFileName: UnicodeString);
var
  I: Integer;
  SL: TStringList;
  tmpS: UnicodeString;
begin
  SL := TStringList.Create;

  SL.Append('Demand:');
  SL.Append('---------------------------------');
  for I := 0 to fDemandCount - 1 do
  if fDemand[I].Ware <> wtNone then
  begin
    tmpS := #9;
    if fDemand[I].Loc_House <> nil then tmpS := tmpS + gResHouses[fDemand[I].Loc_House.HouseType].HouseName + #9 + #9;
    if fDemand[I].Loc_Unit  <> nil then tmpS := tmpS + gRes.Units[fDemand[I].Loc_Unit.UnitType].GUIName + #9 + #9;
    tmpS := tmpS + gResWares[fDemand[I].Ware].Title;
    if fDemand[I].Importance <> diNorm then
      tmpS := tmpS + '^';

    SL.Append(tmpS);
  end;

  SL.Append('Offer:');
  SL.Append('---------------------------------');
  for I := 0 to fOfferCount - 1 do
  if fOffer[I].Ware <> wtNone then
  begin
    tmpS := #9;
    if fOffer[I].Loc_House <> nil then tmpS := tmpS + gResHouses[fOffer[I].Loc_House.HouseType].HouseName + #9 + #9;
    tmpS := tmpS + gResWares[fOffer[I].Ware].Title + #9;
    tmpS := tmpS + IntToStr(fOffer[I].Count);

    SL.Append(tmpS);
  end;

  SL.Append('Running deliveries:');
  SL.Append('---------------------------------');
  for I := 0 to fQueueCount - 1 do
  if fQueue[I].OfferID <> DELIVERY_NO_ID then
  begin
    tmpS := 'id ' + IntToStr(I) + '.' + #9;
    tmpS := tmpS + gResWares[fOffer[fQueue[I].OfferID].Ware].Title + #9;

    if fOffer[fQueue[I].OfferID].Loc_House = nil then
      tmpS := tmpS + 'Destroyed' + ' >>> '
    else
      tmpS := tmpS + gResHouses[fOffer[fQueue[I].OfferID].Loc_House.HouseType].HouseName + ' >>> ';

    if fDemand[fQueue[I].DemandID].Loc_House = nil then
      tmpS := tmpS + 'Destroyed'
    else
      tmpS := tmpS + gResHouses[fDemand[fQueue[I].DemandID].Loc_House.HouseType].HouseName;

    SL.Append(tmpS);
  end;

  SL.SaveToFile(aFileName);
  SL.Free;
end;


{$IFDEF USE_HASH}
{ TKMDeliveryBidKeyComparer }

function TKMDeliveryRouteBidKeyEqualityComparer.Equals(const Left, Right: TKMDeliveryRouteBidKey): Boolean;
begin
  // path keys are equal if they have same ends
  Result := ((Left.FromP = Right.FromP) and (Left.ToP = Right.ToP))
         or ((Left.FromP = Right.ToP)   and (Left.ToP = Right.FromP));
end;


//example taken from https://stackoverflow.com/questions/18068977/use-objects-as-keys-in-tobjectdictionary
{$IFOPT Q+}
  {$DEFINE OverflowChecksEnabled}
  {$Q-}
{$ENDIF}
function CombinedHash(const Values: array of Integer): Integer;
var
  Value: Integer;
begin
  Result := 17;
  for Value in Values do begin
    Result := Result*37 + Value;
  end;
end;
{$IFDEF OverflowChecksEnabled}
  {$Q+}
{$ENDIF}


// Hash function should be match to equals function, so
// if A equals B, then Hash(A) = Hash(B)
// For our task we need that From / To end could be swapped, since we don't care where is the starting point of the path
function TKMDeliveryRouteBidKeyEqualityComparer.GetHashCode(const Value: TKMDeliveryRouteBidKey): Integer;
begin
  Result := Value.GetHashCode;
end;


//Compare keys to make some order to make save consistent. We don't care about the order, it just should be consistent
function TKMDeliveryRouteBidKeyComparer.Compare(const Left, Right: TKMDeliveryRouteBidKey): Integer;
begin
  if Left.Pass = Right.Pass then
  begin
    if Left.FromP = Right.FromP then
      Result := Left.ToP.Compare(Right.ToP)
    else
      Result := Left.FromP.Compare(Right.FromP);
  end
  else
    Result := Byte(Left.Pass) - Byte(Right.Pass);
end;


{ TKMDeliveryCache }
procedure TKMDeliveryRouteCache.Add(const aKey: TKMDeliveryRouteBidKey; const aValue: Single; const aRouteStep: TKMDeliveryRouteStep); //; const aTimeToLive: Word);
var
  bid: TKMDeliveryRouteBid;
begin
  if not CACHE_DELIVERY_BIDS then Exit;

  bid.Value := aValue;
  bid.RouteStep := aRouteStep;
  bid.CreatedAt := gGameParams.Tick;
  inherited Add(aKey, bid);
end;


procedure TKMDeliveryRouteCache.Add(const FromP: TKMPoint; ToP: TKMPoint; const aValue: Single; const aKind: TKMDeliveryRouteStep);//; const aTimeToLive: Word);
var
  key: TKMDeliveryRouteBidKey;
  bid: TKMDeliveryRouteBid;
begin
  if not CACHE_DELIVERY_BIDS then Exit;

  key.FromP := FromP;
  key.ToP := ToP;
  bid.Value := aValue;
  bid.RouteStep := aKind;
  bid.CreatedAt := gGameParams.Tick;
  inherited Add(key, bid);
end;


//procedure TKMDeliveryCache.Add(const aKey: TKMDeliveryBidKey; const aBid: TKMDeliveryBid);
//begin
//  if not CACHE_DELIVERY_BIDS then Exit;
//
//  inherited Add(aKey, aBid);
//end;


function TKMDeliveryRouteCache.TryGetValue(const aKey: TKMDeliveryRouteBidKey; var aBid: TKMDeliveryRouteBid): Boolean;
begin
  Result := False;
  if inherited TryGetValue(aKey, aBid) then
  begin
    if aBid.IsExpired(gGameParams.Tick) then //Don't return expired records
      Remove(aKey) //Remove expired record
    else
      Exit(True); // We found value
  end;
end;

{$ENDIF}

{ TKMDeliveryBidKey }
function TKMDeliveryRouteBidKey.GetHashCode: Integer;
var
  total: Int64;
begin
  //HashCode should be the same if we swap From and To
  Int64Rec(total).Words[0] := (FromP.X + ToP.X);    // values range is 0..MAX_MAP_SIZE*2 (0..512)
  Int64Rec(total).Words[1] := Abs(FromP.X - ToP.X); // (0..256)
  Int64Rec(total).Words[2] := FromP.Y + ToP.Y;      // (0..512)
  Int64Rec(total).Words[3] := (Byte(Pass) shl 8)          // (0..13 actually)
                              or Abs(FromP.Y - ToP.Y); // (0..256)
  //GetHashValue(Integer/Cardinal) is even faster, but we can't fit our 34 bits there
  Result := THashBobJenkins.GetHashValue(total, SizeOf(Int64), 0);
end;


{ TKMDeliveryBid }
function TKMDeliveryRouteBid.GetTTL: Integer;
begin
  Result := 0;
  case RouteStep of
    drsSerfToOffer:   Result := SERF_OFFER_CACHED_BID_TTL;
    drsOfferToDemand: Result := OFFER_DEMAND_CACHED_BID_TTL;
  end;
end;


function TKMDeliveryRouteBid.IsExpired(aTick: Integer): Boolean;
begin
  Result := aTick - CreatedAt > GetTTL;
end;


{ TKMDeliveryRouteEvaluator }
constructor TKMDeliveryRouteEvaluator.Create;
begin
  inherited;

  fUpdatesCnt := 0;

  {$IFDEF USE_HASH}
  if CACHE_DELIVERY_BIDS then
  begin
    fBidsRoutesCache := TKMDeliveryRouteCache.Create(TKMDeliveryRouteBidKeyEqualityComparer.Create);
    fRemoveKeysList := TList<TKMDeliveryRouteBidKey>.Create;
  end;

  if DELIVERY_BID_CALC_USE_PATHFINDING then
    fNodeList := TKMPointList.Create;
  {$ENDIF}
end;


destructor TKMDeliveryRouteEvaluator.Destroy;
begin
  {$IFDEF USE_HASH}
  if CACHE_DELIVERY_BIDS then
  begin
    fBidsRoutesCache.Free;
    fRemoveKeysList.Free;
  end;

  if DELIVERY_BID_CALC_USE_PATHFINDING then
    fNodeList.Free;
  {$ENDIF}

  inherited;
end;


function TKMDeliveryRouteEvaluator.DoTryEvaluate(aFromPos, aToPos: TKMPoint; aPass: TKMTerrainPassability; out aRoutCost: Single): Boolean;
var
  distance: Single;
begin
  distance := EvaluateFast(aFromPos, aToPos);
  Result := True;

  if DELIVERY_BID_CALC_USE_PATHFINDING and (distance < BID_CALC_MAX_DIST_FOR_PATHF) then
  begin
    fNodeList.Clear;

    //Try to make the route to get delivery cost
    if gGame.Pathfinding.Route_Make(aFromPos, aToPos, [aPass], 1, nil, fNodeList) then
      aRoutCost := KMPathLength(fNodeList) * BID_CALC_PATHF_COMPENSATION //to equalize routes with Pathfinding and without
//                + GetUnitsCntOnPath(fNodeList) // units on path are also considered
    else
      Result := False;
  end
  else
    //Basic Bid is length of route
    aRoutCost := distance;

  if not Result then
    aRoutCost := NOT_REACHABLE_DEST_VALUE; //Not reachable destination
end;


function TKMDeliveryRouteEvaluator.EvaluateFast(const aFromPos, aToPos: TKMPoint): Single;
begin
  Result := KMLengthDiag(aFromPos, aToPos); //Use KMLengthDiag, as it closer to what distance serf will actually cover
end;


function TKMDeliveryRouteEvaluator.TryEvaluateAccurate(const aFromPos, aToPos: TKMPoint; aPass: TKMTerrainPassability;
                                                       out aRouteCost: Single; aRouteStep: TKMDeliveryRouteStep): Boolean;
var
  bidKey: TKMDeliveryRouteBidKey;
  bid: TKMDeliveryRouteBid;
begin
  {$IFDEF USE_HASH}
  if CACHE_DELIVERY_BIDS then
  begin
    bidKey.FromP := aFromPos;
    bidKey.ToP := aToPos;
    bidKey.Pass := aPass;

    if fBidsRoutesCache.TryGetValue(bidKey, bid) then
    begin
      Result := (bid.Value <> NOT_REACHABLE_DEST_VALUE);
      aRouteCost := bid.Value;
      Exit; // Cost found in the cache, Exit
    end;
  end;
  {$ENDIF}

  // Calc value if it was not found in the cache
  Result := DoTryEvaluate(aFromPos, aToPos, aPass, aRouteCost);

  {$IFDEF USE_HASH}
  if CACHE_DELIVERY_BIDS then
    //Add calculated cost to the cache, even if there was no route. TTL for cache records is quite low, couple seconds
    fBidsRoutesCache.Add(bidKey, aRouteCost, aRouteStep);
  {$ENDIF}
end;


procedure TKMDeliveryRouteEvaluator.CleanCache;
{$IFDEF USE_HASH}
var
  I: Integer;
  bidPair: TPair<TKMDeliveryRouteBidKey, TKMDeliveryRouteBid>;
  bid: TKMDeliveryRouteBid;
{$ENDIF}
begin
{$IFDEF USE_HASH}
  fRemoveKeysList.Clear;

  // Decrease TimeToLive for every cache record
  for bidPair in fBidsRoutesCache do
  begin
    bid := bidPair.Value;

    if bid.IsExpired(gGameParams.Tick) then
      fRemoveKeysList.Add(bidPair.Key); // its not safe to remove dictionary value in the loop, will cause desyncs
  end;

  // Remove old records after full dictionary scan
  for I := 0 to fRemoveKeysList.Count - 1 do
    fBidsRoutesCache.Remove(fRemoveKeysList[I]);
{$ENDIF}
end;


procedure TKMDeliveryRouteEvaluator.UpdateState;
begin
  {$IFDEF USE_HASH}
  Inc(fUpdatesCnt);
  if CACHE_DELIVERY_BIDS and ((fUpdatesCnt mod CACHE_CLEAN_FREQ) = 0) then
    CleanCache;
  {$ENDIF}
end;


procedure TKMDeliveryRouteEvaluator.Save(SaveStream: TKMemoryStream);
{$IFDEF USE_HASH}
var
  cacheKeyArray : TArray<TKMDeliveryRouteBidKey>;
  key: TKMDeliveryRouteBidKey;
  comparer: TKMDeliveryRouteBidKeyComparer;
  bid: TKMDeliveryRouteBid;
{$ENDIF}
begin
  if not CACHE_DELIVERY_BIDS then Exit;

  {$IFDEF USE_HASH}
  CleanCache; // Don't save expired cache records
  SaveStream.PlaceMarker('DeliveryRouteEvaluator');
  SaveStream.Write(fUpdatesCnt);
  SaveStream.Write(fBidsRoutesCache.Count);

  if fBidsRoutesCache.Count > 0 then
  begin
    comparer := TKMDeliveryRouteBidKeyComparer.Create;
    try
      cacheKeyArray := fBidsRoutesCache.Keys.ToArray;
      TArray.Sort<TKMDeliveryRouteBidKey>(cacheKeyArray, comparer);

      for key in cacheKeyArray do
      begin
        bid := fBidsRoutesCache[key];

        SaveStream.Write(key.FromP);
        SaveStream.Write(key.ToP);
        SaveStream.Write(key.Pass, SizeOf(key.Pass));

        SaveStream.Write(bid.Value);
        SaveStream.Write(bid.RouteStep, SizeOf(bid.RouteStep));
        SaveStream.Write(bid.CreatedAt);
      end;
    finally
      comparer.Free;
    end;
  end;
  {$ENDIF}
end;


procedure TKMDeliveryRouteEvaluator.Load(LoadStream: TKMemoryStream);
{$IFDEF USE_HASH}
var
  I: Integer;
  count: Integer;
  key: TKMDeliveryRouteBidKey;
  bid: TKMDeliveryRouteBid;
{$ENDIF}
begin
  if not CACHE_DELIVERY_BIDS then Exit;

  {$IFDEF USE_HASH}
  LoadStream.CheckMarker('DeliveryRouteEvaluator');
  LoadStream.Read(fUpdatesCnt);
  fBidsRoutesCache.Clear;
  LoadStream.Read(count);

  for I := 0 to count - 1 do
  begin
    LoadStream.Read(key.FromP);
    LoadStream.Read(key.ToP);
    LoadStream.Read(key.Pass, SizeOf(key.Pass));

    LoadStream.Read(bid.Value);
    LoadStream.Read(bid.RouteStep, SizeOf(bid.RouteStep));
    LoadStream.Read(bid.CreatedAt);

    fBidsRoutesCache.Add(key, bid);
  end;
  {$ENDIF}
end;


{ TKMDeliveryBid }
constructor TKMDeliveryBid.Create(aSerf: TKMUnitSerf);
begin
  Create(Low(TKMDemandImportance), aSerf, 0, 0);
end;


constructor TKMDeliveryBid.Create(aImportance: TKMDemandImportance; aSerf: TKMUnitSerf; iO, iD: Integer; iQ: Integer = DELIVERY_NO_ID);
begin
  inherited Create;

  Importance := aImportance;
  QueueID := iQ;
  OfferID := iO;
  DemandID := iD;
  Serf := aSerf;

  ResetValues;
end;


function TKMDeliveryBid.Cost: Single;
begin
  if not IsValid then
    Exit(NOT_REACHABLE_DEST_VALUE);

  Result := Byte(SerfToOffer.Pass <> tpNone) * SerfToOffer.Value
          + Byte(OfferToDemand.Pass <> tpNone) * OfferToDemand.Value
          + Addition;
end;


procedure TKMDeliveryBid.IncAddition(aValue: Single);
begin
  Addition := Addition + aValue;
end;


function TKMDeliveryBid.IsValid: Boolean;
begin
  Result := ((SerfToOffer.Pass = tpNone) or (SerfToOffer.Value <> NOT_REACHABLE_DEST_VALUE))
        and ((OfferToDemand.Pass = tpNone) or (OfferToDemand.Value <> NOT_REACHABLE_DEST_VALUE));
end;


procedure TKMDeliveryBid.ResetValues;
begin
  SerfToOffer.Value := NOT_REACHABLE_DEST_VALUE;
  SerfToOffer.Pass := tpNone;
  OfferToDemand.Value := NOT_REACHABLE_DEST_VALUE;
  OfferToDemand.Pass := tpNone;
  Addition := 0;
end;


{ TKMDeliveryQueueItem }
procedure TKMDeliveryQueueItem.Cleanup;
begin
  {$IFDEF USE_VIRTUAL_TREEVIEW}
  if Assigned(Node) then
  begin
    if not FormLogistics.VSTDeliveries.IsEmpty then
      FormLogistics.VSTDeliveries.DeleteNode(Node);
  end;

  Node := nil;
  {$ENDIF}
end;


procedure TKMDeliveryQueueItem.Reset;
begin
  Serf := nil;
  IsFromUnit := False;
  OfferID := DELIVERY_NO_ID;
  DemandID := DELIVERY_NO_ID;
  JobStatus := jsEmpty;
  Node := nil;
end;


{ TKMDeliveryOffer }
procedure TKMDeliveryOffer.Cleanup;
begin
  {$IFDEF USE_VIRTUAL_TREEVIEW}
  if Assigned(Node) then
  begin
    if not FormLogistics.VSTOffers.IsEmpty then
      FormLogistics.VSTOffers.DeleteNode(Node);
  end;

  Node := nil;
  {$ENDIF}
end;


procedure TKMDeliveryOffer.Reset;
begin
  Ware := wtNone;
  Count := 0;
  Loc_House := nil;
  BeingPerformed := 0;
  IsDeleted := False;
  Node := nil;
end;


{ TKMDeliveryDemand }
procedure TKMDeliveryDemand.Cleanup;
begin
  {$IFDEF USE_VIRTUAL_TREEVIEW}
  if Assigned(Node) then
  begin
    if not FormLogistics.VSTDemands.IsEmpty then
      FormLogistics.VSTDemands.DeleteNode(Node);
  end;

  Node := nil;
  {$ENDIF}
end;


procedure TKMDeliveryDemand.Reset;
begin
  Ware := wtNone;
  DemandType := dtOnce;
  Importance := diNorm;
  Loc_House := nil;
  Loc_Unit := nil;
  BeingPerformed := 0;
  IsDeleted := False;
  NotifyLocHouseOnClose := False;
  Node := nil;
end;


function TKMDeliveryDemand.GetDemandEntity: TKMHandEntity;
begin
  Result := nil;
  if Loc_House <> nil then
    Result := Loc_House
  else
  if Loc_Unit <> nil then
    Result := Loc_Unit;
end;


end.

