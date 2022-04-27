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
    IsActive: Boolean;
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
  TKMDeliveryDemand = record
    IsActive: Boolean;
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
    OfferID: Integer;
    OfferWare: TKMWareType;
    DemandID: Integer;
    DemandWare: TKMWareType;
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
    Ware: TKMWareType;
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
    OfferWare: TKMWareType;
    DemandWare: TKMWareType;
    OfferID: Integer;
    DemandID: Integer;

    Importance: TKMDemandImportance;

    SerfToOffer: TKMDeliveryRouteCalcCost;
    OfferToDemand: TKMDeliveryRouteCalcCost;
    Addition: Single;

    constructor Create(aSerf: TKMUnitSerf); overload;
    constructor Create(aImportance: TKMDemandImportance; aSerf: TKMUnitSerf; oWT, dWT: TKMWareType; iO, iD: Integer; iQ: Integer = DELIVERY_NO_ID); overload;

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
    fOfferCount: array[WARE_MIN..WARE_MAX] of Integer;
    fOffer: array[WARE_MIN..WARE_MAX] of array of TKMDeliveryOffer;
    fDemandCount: array[WARE_MIN..WARE_MAX_ALL] of Integer;
    fDemand: array[WARE_MIN..WARE_MAX_ALL] of array of TKMDeliveryDemand;
    fQueueCount: Integer;
    fQueue: array of TKMDeliveryQueueItem;

    fRouteEvaluator: TKMDeliveryRouteEvaluator;

    fBestBidCandidates: TObjectBinaryHeap<TKMDeliveryBid>;
    fBestBids: TObjectBinaryHeap<TKMDeliveryBid>;

    function AllowFormLogisticsChange: Boolean;
    {$IFDEF USE_VIRTUAL_TREEVIEW}
    procedure SetVSTData(aVST: TVirtualStringTree; Node: PVirtualNode; aHandID, aID: Integer; aWare: TKMWareType);
    {$ENDIF}
    procedure Form_UpdateOfferNode(aWare: TKMWareType; aI: Integer);
    procedure Form_UpdateDemandNode(aWare: TKMWareType; aI: Integer);
    procedure Form_UpdateQueueNode(aI: Integer);

    function CompareBids(A, B: TKMDeliveryBid): Boolean;

    function GetSerfActualPos(aSerf: TKMUnit): TKMPoint;
    procedure CloseDelivery(aID: Integer);
    procedure CloseDemand(aWare: TKMWareType; aID: Integer);
    procedure CloseOffer(aWare: TKMWareType; aID: Integer);
    function ValidWareTypePair(oWT, dWT: TKMWareType): Boolean;
    function ValidDelivery(oWT, dWT: TKMWareType; iO, iD: Integer; aIgnoreOffer: Boolean = False): Boolean;
    function SerfCanDoDelivery(oWT: TKMWareType; iO: Integer; aSerf: TKMUnitSerf): Boolean;
    function PermitDelivery(oWT, dWT: TKMWareType; iO, iD: Integer; aSerf: TKMUnitSerf): Boolean;
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
    function GetDemandCount(aWare: TKMWareType): Integer;
    function GetDemand(aWare: TKMWareType; aDemandID: Integer): TKMDeliveryDemand;
    function GetOfferCount(aWare: TKMWareType): Integer;
    function GetOffer(aWare: TKMWareType; aOfferID: Integer): TKMDeliveryOffer;
    function GetDelivery(aQueueID: Integer): TKMDeliveryQueueItem;
    function GetWareType(aQueueID: Integer): TKMWareType;
  public
    constructor Create(aHandIndex: TKMHandID);
    destructor Destroy; override;
    procedure AddOffer(aHouse: TKMHouse; aWare: TKMWareType; aCount: Integer);
    procedure RemAllOffers(aHouse: TKMHouse);
    procedure RemOffer(aHouse: TKMHouse; aWare: TKMWareType; aCount: Cardinal);

    function GetDemandsCnt(aHouse: TKMHouse; aWare: TKMWareType; aType: TKMDemandType; aImp: TKMDemandImportance): Integer;
    procedure AddDemand(aHouse: TKMHouse; aUnit: TKMUnit; aWare: TKMWareType; aCount: Integer; aType: TKMDemandType; aImp: TKMDemandImportance);
    function TryRemoveDemand(aHouse: TKMHouse; aWare: TKMWareType; aCount: Word; aRemoveBeingPerformed: Boolean = True): Word; overload;
    function TryRemoveDemand(aHouse: TKMHouse; aWare: TKMWareType; aCount: Word; out aPlannedToRemove: Word;
                             aRemoveBeingPerformed: Boolean = True): Word; overload;
    procedure RemDemand(aHouse: TKMHouse); overload;
    procedure RemDemand(aUnit: TKMUnit); overload;

    function IsDeliveryAlowed(aIQ: Integer): Boolean;

    function GetDeliveriesToHouseCnt(aHouse: TKMHouse; aWare: TKMWareType): Integer;

    function GetAvailableDeliveriesCount: Integer;
    procedure ReAssignDelivery(iQ: Integer; aSerf: TKMUnitSerf);
    procedure AssignDelivery(oWT, dWT: TKMWareType; iO, iD: Integer; aSerf: TKMUnitSerf);
    function AskForDelivery(aSerf: TKMUnitSerf; aHouse: TKMHouse = nil): Boolean;
    procedure CheckForBetterDemand(aDeliveryID: Integer; out aToHouse: TKMHouse; out aToUnit: TKMUnit; aSerf: TKMUnitSerf);
    procedure DeliveryFindBestDemand(aSerf: TKMUnitSerf; aDeliveryId: Integer; aWare: TKMWareType; out aToHouse: TKMHouse; out aToUnit: TKMUnit; out aForceDelivery: Boolean);
    procedure TakenOffer(iQ: Integer);
    procedure GaveDemand(iQ: Integer);
    procedure AbandonDelivery(iQ: Integer); //Occurs when unit is killed or something alike happens

    property Delivery[aQueueID: Integer]: TKMDeliveryQueueItem read GetDelivery;
    property DeliveryCount: Integer read fQueueCount;
    property DeliveryWare[aQueueID: Integer]: TKMWareType read GetWareType;

    property Demand[aWare: TKMWareType; aDemandID: Integer]: TKMDeliveryDemand read GetDemand;
    property DemandCount[aWare: TKMWareType]: Integer read GetDemandCount;

    property Offer[aWare: TKMWareType; aOfferID: Integer]: TKMDeliveryOffer read GetOffer;
    property OfferCount[aWare: TKMWareType]: Integer read GetOfferCount;

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
    fSerfs: array of TKMUnitSerf;

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
  KM_UnitWarrior,
  KM_Resource, KM_ResUnits,
  KM_Log, KM_Utils, KM_CommonUtils, KM_DevPerfLog, KM_DevPerfLogTypes;


const
  //Max distance to use pathfinding on calc delivery bids. No need to calc on very long distance
  BID_CALC_MAX_DIST_FOR_PATHF = 40;
  //Approx compensation to compare Bid cost calc with pathfinding and without it. Pathfinding is usually longer
  BID_CALC_PATHF_COMPENSATION = 0.9;
  LENGTH_INC = 32; //Increment array lengths by this value
  NOT_REACHABLE_DEST_VALUE = MaxSingle;
  CACHE_CLEAN_FREQ = 100; //In update counts
  OFFER_DEMAND_CACHED_BID_TTL = 50; //In ticks. DeliveryUpdate is not made every tick
  SERF_OFFER_CACHED_BID_TTL = 30;   //In ticks. DeliveryUpdate is not made every tick

  BIDS_TO_COMPARE = 5; // Maximum number of bids to compare among candidates (how many routes to calc)


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
    SaveStream.Write(fSerfs[I].UID);

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
    LoadStream.Read(fSerfs[I], 4);

  fQueue.Load(LoadStream);
end;


procedure TKMHandLogistics.SyncLoad;
var
  I: Integer;
  U: TKMUnit;
begin
  for I := 0 to fSerfCount - 1 do
  begin
    U := gHands.GetUnitByUID(Cardinal(fSerfs[I]));
    Assert(U is TKMUnitSerf, 'Non-serf in delivery list');
    fSerfs[I] := TKMUnitSerf(U);
  end;
  fQueue.SyncLoad;
end;


//Add the Serf to the List
procedure TKMHandLogistics.AddSerf(aSerf: TKMUnitSerf);
begin
  if fSerfCount >= Length(fSerfs) then
    SetLength(fSerfs, fSerfCount + LENGTH_INC);

  fSerfs[fSerfCount] := TKMUnitSerf(aSerf.GetPointer);
  Inc(fSerfCount);
end;


//Remove died Serf from the List
procedure TKMHandLogistics.RemSerf(aIndex: Integer);
begin
  gHands.CleanUpUnitPointer(TKMUnit(fSerfs[aIndex]));

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
    if fSerfs[I].IsIdle then
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
    if fSerfs[I].IsDeadOrDying then
      RemSerf(I);
end;


procedure TKMHandLogistics.UpdateState(aTick: Cardinal);

  function AnySerfCanDoDelivery(oWT: TKMWareType; iO: Integer): Boolean;
  var
    I: Integer;
  begin
    Result := False;
    for I := 0 to fSerfCount - 1 do
      if fSerfs[I].IsIdle and fQueue.SerfCanDoDelivery(oWT, iO, fSerfs[I]) then
        Exit(True);
  end;

var
  I, K, iD, iO: Integer;
  dWT, oWT: TKMWareType;
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

    availableSerfs := GetIdleSerfCount;
    if availableSerfs = 0 then Exit;

    availableDeliveries := fQueue.GetAvailableDeliveriesCount;
    if availableDeliveries = 0 then Exit;

    if availableDeliveries > availableSerfs then
    begin
      for I := 0 to fSerfCount - 1 do
        if fSerfs[I].IsIdle then
          fQueue.AskForDelivery(fSerfs[I]);
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
      fQueue.fBestBidCandidates.EnlargeTo(1024);

      for dWT := Low(fQueue.fDemandCount) to High(fQueue.fDemandCount) do
        for oWT := WARE_MIN to WARE_MAX do
          if fQueue.ValidWareTypePair(oWT, dWT) then
            for iD := 0 to fQueue.fDemandCount[dWT] - 1 do
              if fQueue.fDemand[dWT, iD].IsActive
                and (fQueue.fDemand[dWT, iD].Importance >= bestImportance) then //Skip any less important than the best we found
                for iO := 0 to fQueue.fOfferCount[oWT] - 1 do
                  if fQueue.fOffer[oWT, iO].IsActive
                    and fQueue.ValidDelivery(oWT, dWT, iO, iD)
                    and AnySerfCanDoDelivery(oWT, iO) then //Only choose this delivery if at least one of the serfs can do it
                  begin
                    bid := TKMDeliveryBid.Create(fQueue.fDemand[dWT,iD].Importance, nil, oWT, dWT, iO, iD);
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
        offerPos := fQueue.fOffer[bid.OfferWare, bid.OfferID].Loc_House.PointBelowEntrance;
        fQueue.fBestBidCandidates.Clear;
        fQueue.fBestBidCandidates.EnlargeTo(fSerfCount);
        serfBid := nil;
        for K := 0 to fSerfCount - 1 do
          if fSerfs[K].IsIdle then
            if fQueue.SerfCanDoDelivery(bid.OfferWare, bid.OfferID, fSerfs[K]) then
            begin
              serfBid := TKMDeliveryBid.Create(fSerfs[K]);

              if fQueue.TryCalcSerfBidValue(dckFast, fSerfs[K], offerPos, serfBid) then
                fQueue.fBestBidCandidates.Push(serfBid);
            end;

        serfBid := fQueue.ChooseBestSerfBid(offerPos);

        if serfBid <> nil then
        begin
          fQueue.AssignDelivery(bid.OfferWare, bid.DemandWare, bid.OfferID, bid.DemandID, serfBid.Serf);
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
procedure TKMDeliveries.SetVSTData(aVST: TVirtualStringTree; Node: PVirtualNode; aHandID, aID: Integer; aWare: TKMWareType);
var
  data: PKMLogisticsIDs;
begin
  data := aVST.GetNodeData(Node);
  data.HandID := aHandID;
  data.ID := aID;
  data.Ware := aWare;
end;
{$ENDIF}


// Update FormLogistics offer item
procedure TKMDeliveries.Form_UpdateOfferNode(aWare: TKMWareType; aI: Integer);
begin
  {$IFDEF USE_VIRTUAL_TREEVIEW}
  if (gGame = nil) or gGame.ReadyToStop then Exit;
  if not AllowFormLogisticsChange then Exit;
  if aWare = wtNone then Exit;
  if aI >= fOfferCount[aWare] then Exit;


  with fOffer[aWare, aI] do
    if IsActive then
    begin
      if Node = nil then
        Node := FormLogistics.VSTOffers.AddChild(nil); //Add to root

      SetVSTData(FormLogistics.VSTOffers, Node, fOwner, aI, aWare);

      FormLogistics.FilterNode(FormLogistics.VSTOffers, Node);
    end;
  {$ENDIF}
end;


// Update FormLogistics demand item
procedure TKMDeliveries.Form_UpdateDemandNode(aWare: TKMWareType; aI: Integer);
begin
  {$IFDEF USE_VIRTUAL_TREEVIEW}
  if (gGame = nil) or gGame.ReadyToStop then Exit;
  if not AllowFormLogisticsChange then Exit;
  if aWare = wtNone then Exit;
  if aI >= fDemandCount[aWare] then Exit;

  with fDemand[aWare, aI] do
    if IsActive then
    begin
      if Node = nil then
        Node := FormLogistics.VSTDemands.AddChild(nil); //Add to root

      SetVSTData(FormLogistics.VSTDemands, Node, fOwner, aI, aWare);

      FormLogistics.FilterNode(FormLogistics.VSTDemands, Node);
    end;
  {$ENDIF}
end;


// Update FormLogistics queue item
procedure TKMDeliveries.Form_UpdateQueueNode(aI: Integer);
begin
  {$IFDEF USE_VIRTUAL_TREEVIEW}
  if (gGame = nil) or gGame.ReadyToStop then Exit;
  if not AllowFormLogisticsChange then Exit;
  if aI >= fQueueCount then Exit;

  with fQueue[aI] do
  begin
    if (DemandID = DELIVERY_NO_ID) or (DemandWare = wtNone) then Exit;
    if (OfferID = DELIVERY_NO_ID) or (OfferWare = wtNone) then Exit;

    if not fDemand[DemandWare, DemandID].IsActive
      or not fOffer[OfferWare, OfferID].IsActive then Exit;

    if Node = nil then
      Node := FormLogistics.VSTDeliveries.AddChild(nil); //Add to root

    SetVSTData(FormLogistics.VSTDeliveries, Node, fOwner, aI, wtNone);

    FormLogistics.FilterNode(FormLogistics.VSTDeliveries, Node);
  end;
  {$ENDIF}
end;


// Update FormLogistics items (all of them)
procedure TKMDeliveries.Form_UpdateAllNodes;
{$IFDEF USE_VIRTUAL_TREEVIEW}
var
  I: Integer;
  WT: TKMWareType;
{$ENDIF}
begin
  if Self = nil then Exit;

  {$IFDEF USE_VIRTUAL_TREEVIEW}
  for I := 0 to fQueueCount - 1 do
    Form_UpdateQueueNode(I);

  for WT := Low(fOfferCount) to High(fOfferCount) do
    for I := 0 to fOfferCount[WT] - 1 do
      Form_UpdateOfferNode(WT, I);

  for WT := Low(fDemandCount) to High(fDemandCount) do
    for I := 0 to fDemandCount[WT] - 1 do
      Form_UpdateDemandNode(WT, I);

  // Update form only once, after all Nodes were created
  FormLogistics.VSTUpdate;
  {$ENDIF}
end;


procedure TKMDeliveries.Form_NilAllNodes;
{$IFDEF USE_VIRTUAL_TREEVIEW}
var
  I: Integer;
  WT: TKMWareType;
{$ENDIF}
begin
  if Self = nil then Exit;

  {$IFDEF USE_VIRTUAL_TREEVIEW}
  for I := 0 to fQueueCount - 1 do
     fQueue[I].Node := nil;

  for WT := Low(fOfferCount) to High(fOfferCount) do
    for I := 0 to fOfferCount[WT] - 1 do
      fOffer[WT,I].Node := nil;

  for WT := Low(fDemandCount) to High(fDemandCount) do
    for I := 0 to fDemandCount[WT] - 1 do
      fDemand[WT,I].Node := nil;
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
  for I := 0 to fOfferCount[aWare] - 1 do
    if (fOffer[aWare,I].Loc_House = aHouse) then
    begin
      if fOffer[aWare,I].IsDeleted then
      begin
        //Revive old offer because some serfs are still walking to perform it
        Assert(fOffer[aWare,I].BeingPerformed > 0);
        fOffer[aWare,I].Count :=  aCount;
        fOffer[aWare,I].IsDeleted := False;

        Form_UpdateOfferNode(aWare,I);
        Exit; //Count added, thats all
      end
      else
      begin
        Inc(fOffer[aWare,I].Count, aCount);

        Form_UpdateOfferNode(aWare,I);

        Exit; //Count added, thats all
      end;
    end;

  //Find empty place or allocate new one
  I := 0;
  while (I < fOfferCount[aWare]) and fOffer[aWare,I].IsActive do
    Inc(I);
  if I >= fOfferCount[aWare] then
  begin
    Inc(fOfferCount[aWare], LENGTH_INC);
    SetLength(fOffer[aWare], fOfferCount[aWare]);
    for K := I to fOfferCount[aWare] - 1 do
      //We could do fOffer[aWare,K].Reset here, but FillChar is a bit faster
      FillChar(fOffer[aWare,K], SizeOf(fOffer[aWare,K]), #0);
  end;

  //Add offer
  with fOffer[aWare,I] do
  begin
    IsActive := True;
    if aHouse <> nil then
      Loc_House := aHouse.GetPointer;
    Count := aCount;
    Assert((BeingPerformed = 0) and not IsDeleted); //Make sure this item has been closed properly, if not there is a flaw

    Form_UpdateOfferNode(aWare,I);
  end;
end;


//Remove Offer from the list. E.G on house demolish
//List is stored without sorting so we have to parse it to find that entry..
procedure TKMDeliveries.RemAllOffers(aHouse: TKMHouse);
var
  I: Integer;
  WT: TKMWareType;
begin
  if gGameParams.IsMapEditor then
    Exit;

  for WT := WARE_MIN to WARE_MAX do
  begin
    //Todo: we can use only ResIn / ResOut ware types, depends of the delivery mode
    if not aHouse.CanHaveWareType(WT) then Continue;

    //We need to parse whole list, never knowing how many offers the house had
    for I := 0 to fOfferCount[WT] - 1 do
      if fOffer[WT,I].Loc_House = aHouse then
      begin
        if fOffer[WT,I].BeingPerformed > 0 then
        begin
          //Keep it until all associated deliveries are abandoned
          fOffer[WT,I].IsDeleted := True; //Don't reset it until serfs performing this offer are done with it
          fOffer[WT,I].Count := 0; //Make the count 0 so no one else tries to take this offer
          Form_UpdateOfferNode(WT,I);
        end
        else
          CloseOffer(WT,I);
      end;
  end;
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
  for I := 0 to fOfferCount[aWare] - 1 do
    if (fOffer[aWare,I].Loc_House = aHouse)
      and not fOffer[aWare,I].IsDeleted then
    begin
      Assert(fOffer[aWare,I].Count >= aCount, 'Removing too many offers');
      Dec(fOffer[aWare,I].Count, aCount);
      if fOffer[aWare,I].Count = 0 then
      begin
        if fOffer[aWare,I].BeingPerformed > 0 then
          fOffer[aWare,I].IsDeleted := True
        else
          CloseOffer(aWare,I);
      end;
      Form_UpdateOfferNode(aWare,I);
      Exit; //Count decreased, that's all
    end;

  raise Exception.Create('Failed to remove offer');
end;


//Remove Demand from the list
// List is stored without sorting so we parse it to find all entries..
procedure TKMDeliveries.RemDemand(aHouse: TKMHouse);
var
  I: Integer;
  WT: TKMWareType;
begin
  if gGameParams.IsMapEditor then
    Exit;

  Assert(aHouse <> nil);

  for WT := WARE_MIN to WARE_MAX do
  begin
    //Todo: we can use only ResIn / ResOut ware types, depends of the delivery mode
    if not aHouse.CanHaveWareType(WT) then Continue;

    for I := 0 to fDemandCount[WT] - 1 do
      if fDemand[WT,I].Loc_House = aHouse then
      begin
        if fDemand[WT,I].BeingPerformed > 0 then
          //Can't free it yet, some serf is using it
          fDemand[WT,I].IsDeleted := True
        else
          CloseDemand(WT,I); //Clear up demand
        //Keep on scanning cos House can have multiple demands entries
      end;
  end;
end;


//Check if delivery is allowed to continue
function TKMDeliveries.IsDeliveryAlowed(aIQ: Integer): Boolean;
begin
  if (fQueue[aIQ].DemandID <> DELIVERY_NO_ID) and (fQueue[aIQ].DemandWare <> wtNone) then
    Result := not fDemand[fQueue[aIQ].DemandWare, fQueue[aIQ].DemandId].IsDeleted //Delivery could be cancelled because of Demand marked as Deleted
  else
    Result := False; //Not allowed delivery if demandId is underfined (= DELIVERY_NO_ID)
end;


//Remove Demand from the list
// List is stored without sorting so we parse it to find all entries..
procedure TKMDeliveries.RemDemand(aUnit: TKMUnit);
const
  WARES_TO_BUILDER = [wtStone, wtTimber];
var
  I: Integer;
  WT: TKMWareType;
  wares: TKMWareTypeSet;
begin
  if gGameParams.IsMapEditor then
    Exit;

  Assert(aUnit <> nil);

  wares := [];

  if aUnit is TKMUnitWarrior then
    wares := [wtFood]
  else
  if aUnit is TKMUnitWorker then
    wares := WARES_TO_BUILDER;


  for WT in wares do
    for I := 0 to fDemandCount[WT] - 1 do
      if fDemand[WT,I].Loc_Unit = aUnit then
      begin
        if fDemand[WT,I].BeingPerformed > 0 then
          //Can't free it yet, some serf is using it
          fDemand[WT,I].IsDeleted := True
        else
          CloseDemand(WT,I); //Clear up demand
        //Keep on scanning cos Unit can have multiple demands entries (foreseeing Walls building)
      end;
end;


function TKMDeliveries.GetDeliveriesToHouseCnt(aHouse: TKMHouse; aWare: TKMWareType): Integer;
var
  I, iD: Integer;
begin
  Result := 0;
  for I := 0 to fQueueCount - 1 do
  begin
    if (fQueue[I].DemandWare = aWare)
      and (fQueue[I].JobStatus = jsTaken) then
    begin
      iD := fQueue[I].DemandId;
      if (fDemand[aWare,iD].Loc_House = aHouse)
        and not fDemand[aWare,iD].IsDeleted
        and (fDemand[aWare,iD].BeingPerformed > 0) then
        Inc(Result);
    end;
  end;
end;


function TKMDeliveries.TryRemoveDemand(aHouse: TKMHouse; aWare: TKMWareType; aCount: Word; aRemoveBeingPerformed: Boolean = True): Word;
var
  plannedToRemove: Word;
begin
  Result := TryRemoveDemand(aHouse, aWare, aCount, plannedToRemove);
end;


//Attempt to remove aCount demands from this house and report the number
//if there are some being performed, then mark them as deleted, so they will be cancelled as soon as possible
function TKMDeliveries.TryRemoveDemand(aHouse: TKMHouse; aWare: TKMWareType; aCount: Word; out aPlannedToRemove: Word;
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

  for I := fDemandCount[aWare] - 1 downto 0 do
    if (fDemand[aWare,I].Loc_House = aHouse)
//      and (fDemand[I].Ware = aWare)
      and not fDemand[aWare,I].IsDeleted then
    begin
      if fDemand[aWare,I].BeingPerformed = 0 then
      begin
        CloseDemand(aWare,I); //Clear up demand
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
      fDemand[aWare, PlannedIDs[I]].IsDeleted := True;
      fDemand[aWare, PlannedIDs[I]].NotifyLocHouseOnClose := aRemoveBeingPerformed;
    end;
end;


function TKMDeliveries.GetDelivery(aQueueID: Integer): TKMDeliveryQueueItem;
begin
  Result := fQueue[aQueueID];
end;


function TKMDeliveries.GetDemand(aWare: TKMWareType; aDemandID: Integer): TKMDeliveryDemand;
begin
  Result := fDemand[aWare, aDemandID];
end;


function TKMDeliveries.GetDemandCount(aWare: TKMWareType): Integer;
begin
  Result := fDemandCount[aWare];
end;


function TKMDeliveries.GetOffer(aWare: TKMWareType; aOfferID: Integer): TKMDeliveryOffer;
begin
  Result := fOffer[aWare, aOfferID];
end;


function TKMDeliveries.GetOfferCount(aWare: TKMWareType): Integer;
begin
  Result := fOfferCount[aWare];
end;


function TKMDeliveries.GetDemandsCnt(aHouse: TKMHouse; aWare: TKMWareType; aType: TKMDemandType; aImp: TKMDemandImportance): Integer;
var
  I: Integer;
  demand: TKMDeliveryDemand;
begin
  Result := 0;

  if (aHouse = nil) or (aWare = wtNone) then Exit;

  for I := 0 to fDemandCount[aWare] - 1 do
  begin
    demand := fDemand[aWare,I];
    if {(aWare = demand.Ware)
      and }(aHouse = demand.Loc_House)
      and (aType = demand.DemandType)
      and (aImp = demand.Importance) then
      Inc(Result);
  end;
end;


//Adds new Demand to the list. List is stored sorted, but the sorting is done upon Deliver completion,
//so we just find an empty place (which is last one) and write there.
procedure TKMDeliveries.AddDemand(aHouse: TKMHouse; aUnit: TKMUnit; aWare: TKMWareType; aCount: Integer; aType: TKMDemandType; aImp: TKMDemandImportance);
var
  I,K,J: Integer;
begin
  if gGameParams.IsMapEditor then
    Exit;
  Assert(aWare <> wtNone, 'Demanding wtNone');
  if aCount <= 0 then Exit;

  for K := 0 to aCount - 1 do
  begin
    I := 0;
    while (I < fDemandCount[aWare]) and fDemand[aWare, I].IsActive do
      Inc(I);
    if I >= fDemandCount[aWare] then
    begin
      Inc(fDemandCount[aWare], LENGTH_INC);
      SetLength(fDemand[aWare], fDemandCount[aWare]);
      for J := I to fDemandCount[aWare] - 1 do
        //We could do fDemand[aWare,J].Reset here, but FillChar is a bit faster
        FillChar(fDemand[aWare,J], SizeOf(fDemand[aWare,J]), #0);
    end;

    with fDemand[aWare,I] do
    begin
      if aHouse <> nil then
        Loc_House := aHouse.GetPointer;

      if aUnit <> nil then
        Loc_Unit := aUnit.GetPointer;

      IsActive := True;
      DemandType := aType; //Once or Always
      Importance := aImp;
      Assert((not IsDeleted) and (BeingPerformed = 0)); //Make sure this item has been closed properly, if not there is a flaw

      //Gold to Schools
      if (aWare = wtGold)
        and (Loc_House <> nil) and (Loc_House.HouseType = htSchool) then
        Importance := diHigh1;

      //Food to Inn
      if (aWare in [wtBread, wtSausage, wtWine, wtFish])
        and (Loc_House <> nil) and (Loc_House.HouseType = htInn) then
        Importance := diHigh3;

      Form_UpdateDemandNode(aWare,I);
    end;
  end;
end;


function TKMDeliveries.ValidWareTypePair(oWT, dWT: TKMWareType): Boolean;
begin
  Result := (dWT = oWT)
            or (dWT = wtAll)
            or ((dWT = wtWarfare) and (oWT in WARES_WARFARE))
            or ((dWT = wtFood) and (oWT in WARES_FOOD));
end;


//IgnoreOffer means we don't check whether offer was already taken or deleted (used after offer was already claimed)
function TKMDeliveries.ValidDelivery(oWT, dWT: TKMWareType; iO, iD: Integer; aIgnoreOffer: Boolean = False): Boolean;
var
  I: Integer;
  B: TKMHouseBarracks;
  offer: PKMDeliveryOffer;
  demand: PKMDeliveryDemand;
begin
  offer := @fOffer[oWT,iO];
  demand := @fDemand[dWT,iD];

  // Conditions are called in the frequency of a negative Result: most negative first

  //If Demand and Offer aren't reserved already
  Result := (aIgnoreOffer or (offer.BeingPerformed < offer.Count))
             and ((demand.DemandType = dtAlways) or (demand.BeingPerformed = 0));

  Result := Result and (
            ( //House-House delivery should be performed only if there's a connecting road
            (demand.Loc_House <> nil) and
            (gTerrain.Route_CanBeMade(offer.Loc_House.PointBelowEntrance, demand.Loc_House.PointBelowEntrance, tpWalkRoad, 0))
            )
            or
            ( //House-Unit delivery can be performed without connecting road
            (demand.Loc_Unit <> nil) and
            (gTerrain.Route_CanBeMade(offer.Loc_House.PointBelowEntrance, demand.Loc_Unit.Position, tpWalk, 1))
            ));

  //If Demand house should abandon delivery
  Result := Result and ((demand.Loc_House = nil)
                         or not demand.Loc_House.IsComplete
                         or not demand.Loc_House.ShouldAbandonDeliveryTo(oWT));

  //If Offer should not be abandoned
  Result := Result and not offer.Loc_House.ShouldAbandonDeliveryFrom(oWT)
                   //Check store to store evacuation
                   and not offer.Loc_House.ShouldAbandonDeliveryFromTo(demand.Loc_House, oWT, False);

  //Warfare has a preference to be delivered to Barracks
  if Result
    and (oWT in WARES_WARFARE)
    and (demand.Loc_House <> nil) then
  begin
    //Permit delivery of warfares to Store only if player has no Barracks or they all have blocked ware
    if demand.Loc_House.HouseType = htStore then
    begin
      //Scan through players Barracks, if none accepts - allow deliver to Store
      I := 1;
      repeat
        B := TKMHouseBarracks(gHands[demand.Loc_House.Owner].FindHouse(htBarracks, I));
        //If the barracks will take the ware, don't allow the store to take it (disallow current delivery)
        if (B <> nil) and (B.DeliveryMode = dmDelivery) and not B.NotAcceptFlag[oWT] then
        begin
          Result := False;
          Break;
        end;
        Inc(I);
      until (B = nil);
    end;
  end;

  //If Demand and Offer aren't deleted
  Result := Result and not demand.IsDeleted and (aIgnoreOffer or not offer.IsDeleted);

  //Do not allow delivery from 1 house to same house (f.e. store)
  Result := Result and ((demand.Loc_House = nil)
                       or (demand.Loc_House.UID <> offer.Loc_House.UID));

  //If Demand and Offer are different HouseTypes, means forbid Store<->Store deliveries
  //except the case where 2nd store is being built and requires building materials
  //or when we use TakeOut delivery (evacuation) mode for Offer Store
  Result := Result and ((demand.Loc_House = nil)
                        or not ((offer.Loc_House.HouseType = htStore) and (demand.Loc_House.HouseType = htStore))
                        or not demand.Loc_House.IsComplete
                        or ((offer.Loc_House.DeliveryMode = dmTakeOut) and not TKMHouseStore(offer.Loc_House).NotAllowTakeOutFlag[oWT]));

  //Allow transfers between Barracks only when offer barracks have DeliveryMode = dmTakeOut
  Result := Result and ((demand.Loc_House = nil)
                        or (demand.Loc_House.HouseType <> htBarracks)
                        or (offer.Loc_House.HouseType <> htBarracks)
                        or (offer.Loc_House.DeliveryMode = dmTakeOut));

  //Permit Barracks -> Store deliveries only if barracks delivery mode is TakeOut
  Result := Result and ((demand.Loc_House = nil)
                        or (demand.Loc_House.HouseType <> htStore)
                        or (offer.Loc_House.HouseType <> htBarracks)
                        or (offer.Loc_House.DeliveryMode = dmTakeOut));
end;


// Delivery is only permitted if the serf can access the From house.
function TKMDeliveries.SerfCanDoDelivery(oWT: TKMWareType; iO: Integer; aSerf: TKMUnitSerf): Boolean;
var
  LocA, LocB: TKMPoint;
begin
  LocA := GetSerfActualPos(aSerf);
  LocB := fOffer[oWT,iO].Loc_House.PointBelowEntrance;

  Result := aSerf.CanWalkTo(LocA, LocB, tpWalk, 0);
end;


function TKMDeliveries.PermitDelivery(oWT, dWT: TKMWareType; iO,iD: Integer; aSerf: TKMUnitSerf): Boolean;
begin
  Result := ValidDelivery(oWT, dWT, iO, iD) and SerfCanDoDelivery(oWT, iO, aSerf);
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

  Result := fQueue[aQueueID].OfferWare;

  if Result in WARES_VALID then Exit;

  Result := fQueue[aQueueID].DemandWare;
end;


//Get the total number of possible deliveries with current Offers and Demands
function TKMDeliveries.GetAvailableDeliveriesCount: Integer;
var
  iD,iO: Integer;
  offersTaken: Cardinal;
  demandTaken: array[WARE_MIN..WARE_MAX_ALL] of array of Boolean; //Each demand can only be taken once in our measurements
  dWT, oWT: TKMWareType;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psDelivery);
  {$ENDIF}
  try
    for dWT := Low(demandTaken) to High(demandTaken) do
    begin
      SetLength(demandTaken[dWT], fDemandCount[dWT]);
      if fDemandCount[dWT] > 0 then
        FillChar(demandTaken[dWT][0], SizeOf(Boolean)*fDemandCount[dWT], #0);
    end;

    Result := 0;

    for dWT := Low(fDemandCount) to High(fDemandCount) do
      for oWT := WARE_MIN to WARE_MAX do
        if ValidWareTypePair(oWT, dWT) then
          for iO := 0 to fOfferCount[oWT] - 1 do
            if fOffer[oWT,iO].IsActive then
            begin
              offersTaken := 0;
              for iD := 0 to fDemandCount[dWT] - 1 do
                if fDemand[dWT,iD].IsActive and not demandTaken[dWT,iD] and ValidDelivery(oWT,dWT,iO,iD) then
                begin
                  if fDemand[dWT,iD].DemandType = dtOnce then
                  begin
                    demandTaken[dWT,iD] := True;
                    Inc(Result);
                    Inc(offersTaken);
                    if fOffer[oWT,iO].Count - offersTaken = 0 then
                      Break; //Finished with this offer
                  end
                  else
                  begin
                    //This demand will take all the offers, so increase result by that many
                    Inc(Result, fOffer[oWT,iO].Count - offersTaken);
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
  oWT: TKMWareType;
begin
  iO := aBidBasicCost.OfferID;
  oWT := aBidBasicCost.OfferWare;
  Result := TryCalculateBidBasic(aCalcKind, fOffer[oWT,iO].Loc_House.PointBelowEntrance, fOffer[oWT,iO].Count,
                                 fOffer[oWT,iO].Loc_House.HouseType, fOffer[oWT,iO].Loc_House.Owner, aBidBasicCost, aSerf,
                                 aAllowOffroad);
end;


//Calc bid cost between offer object (house, serf) and demand object (house, unit - worker or warrior)
function TKMDeliveries.TryCalculateBidBasic(aCalcKind: TKMDeliveryCalcKind; aOfferPos: TKMPoint; aOfferCnt: Cardinal; aOfferHouseType: TKMHouseType;
                                            aOwner: TKMHandID; var aBidBasicCost: TKMDeliveryBid; aSerf: TKMUnitSerf = nil;
                                            aAllowOffroad: Boolean = False): Boolean;
var
  iD: Integer;
  dWT: TKMWareType;
  secondPass: TKMTerrainPassability;
begin
  Assert((aCalcKind = dckFast) or aBidBasicCost.IsValid); // For dckAccurate we assume cost was already calculated before and it was confirmed it's not unwalkable

  iD := aBidBasicCost.DemandID;
  dWT := aBidBasicCost.DemandWare;

  Result := TryCalcSerfBidValue(aCalcKind, aSerf, aOfferPos, aBidBasicCost);
  if not Result then
    Exit;

  //For weapons production in cases with little resources available, they should be distributed
  //evenly between places rather than caring about route length.
  //This means weapon and armour smiths should get same amount of iron, even if one is closer to the smelter.
  if (fDemand[dWT,iD].Loc_House <> nil) and fDemand[dWT,iD].Loc_House.IsComplete
    and gResHouses[fDemand[dWT,iD].Loc_House.HouseType].DoesOrders
    and (aOfferCnt <= 3) //Little resources to share around
    and (fDemand[dWT,iD].Loc_House.CheckResIn(dWT) <= 2) then //Few resources already delivered
  begin
    if aCalcKind = dckAccurate then
      Exit;

    aBidBasicCost.OfferToDemand.Value := 7
      //Resource ratios are also considered
      + KaMRandom(65 - 13*gHands[aOwner].Stats.WareDistribution[dWT, fDemand[dWT,iD].Loc_House.HouseType],
                  'TKMDeliveries.TryCalculateBidBasic');
  end
  else
  begin
    //For all other cases - use distance approach. Direct length (rough) or pathfinding (exact)
    if fDemand[dWT,iD].Loc_House <> nil then
    begin
      secondPass := tpNone;
      if aAllowOffroad then
        secondPass := tpWalk;
      //Calc cost between offer and demand houses
      aBidBasicCost.OfferToDemand.Pass := tpWalkRoad;
      Result := TryCalcRouteCost(aCalcKind, aOfferPos, fDemand[dWT,iD].Loc_House.PointBelowEntrance, drsOfferToDemand, aBidBasicCost.OfferToDemand, secondPass);

      if aCalcKind = dckAccurate then
        Exit;

      //Resource ratios are also considered
      aBidBasicCost.IncAddition(KaMRandom(16 - 3*gHands[aOwner].Stats.WareDistribution[dWT, fDemand[dWT,iD].Loc_House.HouseType],
                                          'TKMDeliveries.TryCalculateBidBasic 2'));
    end
    else
    begin
      aBidBasicCost.OfferToDemand.Pass := tpWalk;
      //Calc bid cost between offer house and demand Unit (digged worker or hungry warrior)
      Result := TryCalcRouteCost(aCalcKind, aOfferPos, fDemand[dWT,iD].Loc_Unit.Position, drsOfferToDemand, aBidBasicCost.OfferToDemand);
    end;

    // There is no route, Exit immidiately
    if not Result then
      Exit;
  end;

  if aCalcKind = dckAccurate then
    Exit;

  //Deliver wood first to equal distance construction sites
  if (fDemand[dWT,iD].Loc_House <> nil)
    and not fDemand[dWT,iD].Loc_House.IsComplete then
  begin
    //Give priority to almost built houses
    aBidBasicCost.Addition := aBidBasicCost.Addition - 4*fDemand[dWT,iD].Loc_House.GetBuildResDeliveredPercent;
    //Only add a small amount so houses at different distances will be prioritized separately
    if dWT = wtStone then
      aBidBasicCost.IncAddition(0.1);
  end
  else
    //For all other deliveries, add some random element so in the case of identical
    //bids the same resource will not always be chosen (e.g. weapons storehouse->barracks
    //should take random weapon types not sequentially)
    aBidBasicCost.IncAddition(KaMRandom(10, 'TKMDeliveries.TryCalculateBidBasic 3'));

  if (dWT = wtAll)        // Always prefer deliveries House>House instead of House>Store
    or ((aOfferHouseType = htStore)    // Prefer taking wares from House rather than Store...
        and (dWT <> wtWarfare)) then //...except weapons Store>Barracks, that is also prefered
    aBidBasicCost.IncAddition(1000);
end;


function TKMDeliveries.TryCalculateBid(aCalcKind: TKMDeliveryCalcKind; var aBidCost: TKMDeliveryBid; aSerf: TKMUnitSerf = nil): Boolean;
var
  iO, iD: Integer;
  oWT, dWT: TKMWareType;
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
    oWT := aBidCost.OfferWare;
    dWT := aBidCost.DemandWare;

    //Modifications for bidding system
    if (fDemand[dWT,iD].Loc_House <> nil) //Prefer delivering to houses with fewer supply
      and (dWT <> wtAll)
      and (dWT <> wtWarfare) //Except Barracks and Store, where supply doesn't matter or matter less
      and (fDemand[dWT,iD].Loc_House.HouseType <> htTownHall) then //Except TownHall as well, where supply doesn't matter or matter less
      aBidCost.IncAddition(20 * fDemand[dWT,iD].Loc_House.CheckResIn(dWT));

    if (fDemand[dWT,iD].Loc_House <> nil)
      and (fDemand[dWT,iD].Loc_House.HouseType = htTownHall) then
    begin
      //Delivering gold to TH - if there are already more then 500 gold, then make this delivery very low priority
      if (fDemand[dWT,iD].Loc_House.CheckResIn(oWT) > 500) then
        aBidCost.IncAddition(5000)
      else
        aBidCost.IncAddition(2); //Add small value, so it will not have so big advantage above other houses
    end;

    //Delivering weapons from store to barracks, make it lowest priority when there are >50 of that weapon in the barracks.
    //In some missions the storehouse has vast amounts of weapons, and we don't want the serfs to spend the whole game moving these.
    //In KaM, if the barracks has >200 weapons the serfs will stop delivering from the storehouse. I think our solution is better.
    if (fDemand[dWT,iD].Loc_House <> nil)
      and (fDemand[dWT,iD].Loc_House.HouseType = htBarracks)
      and (fOffer[oWT,iO].Loc_House.HouseType = htStore)
      and (fDemand[dWT,iD].Loc_House.CheckResIn(oWT) > 50) then
      aBidCost.IncAddition(10000);

    //When delivering food to warriors, add a random amount to bid to ensure that a variety of food is taken. Also prefer food which is more abundant.
    if (fDemand[dWT,iD].Loc_Unit <> nil) and (dWT = wtFood) then
    begin
      //The more resource there is, the smaller Random can be. >100 we no longer care, it's just random 5.
      if fOffer[oWT,iO].Count = 0 then
        aBidCost.IncAddition(KaMRandom(5 + 150, 'TKMDeliveries.TryCalculateBidBasic 4'))
      else
        aBidCost.IncAddition(KaMRandom(5 + (100 div fOffer[oWT,iO].Count), 'TKMDeliveries.TryCalculateBidBasic 5'));
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
  oldDWT, dWT, bestDWT, oWT: TKMWareType;
  bestImportance: TKMDemandImportance;
  bid: TKMDeliveryBid;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psDelivery);
  {$ENDIF}
  try
    iO := fQueue[aDeliveryID].OfferID;
    oWT := fQueue[aDeliveryID].OfferWare;
    oldD := fQueue[aDeliveryID].DemandID;
    oldDWT := fQueue[aDeliveryID].DemandWare;

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
    if fDemand[oldDWT,oldD].Loc_Unit <> nil then
    begin
      aToHouse := fDemand[oldDWT,oldD].Loc_House;
      aToUnit := fDemand[oldDWT,oldD].Loc_Unit;
      Exit;
    end;

    //By default we keep the old demand, so that's our starting bid
    fBestBidCandidates.Clear;
    fBestBidCandidates.EnlargeTo(fDemandCount[oldDWT]);

    if not fDemand[oldDWT,oldD].IsDeleted then
    begin
      bestImportance := fDemand[oldDWT,oldD].Importance;
      bid := TKMDeliveryBid.Create(bestImportance, aSerf, oWT, oldDWT, iO, oldD);
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

    for dWT := Low(fDemandCount) to High(fDemandCount) do
      if ValidWareTypePair(oWT, dWT) then
        for iD := 0 to fDemandCount[dWT] - 1 do
          if fDemand[dWT,iD].IsActive
          and not ((oldD = iD) and (oldDWT = dWT))
          and (fDemand[dWT,iD].Importance >= bestImportance) //Skip any less important than the best we found
          and ValidDelivery(oWT, dWT, iO, iD, True) then
          begin
            bid := TKMDeliveryBid.Create(fDemand[dWT,iD].Importance, aSerf, oWT, dWT, iO, iD);
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
      bestDWT := bid.DemandWare;
      bid.Free;
    end
    else
    begin
      bestD := oldD;
      bestDWT := oldDWT;
    end;

    //Did we switch jobs?
    if not ((bestD = oldD) and (bestDWT = oldDWT)) then
    begin
      //Remove old demand
      Dec(fDemand[oldDWT,oldD].BeingPerformed);
      if (fDemand[oldDWT,oldD].BeingPerformed = 0) and fDemand[oldDWT,oldD].IsDeleted then
        CloseDemand(oldDWT,oldD);

      Form_UpdateDemandNode(oldDWT,oldD);

      //Take new demand
      fQueue[aDeliveryID].DemandID := bestD;
      fQueue[aDeliveryID].DemandWare := bestDWT;
      Inc(fDemand[bestDWT, bestD].BeingPerformed); //Places a virtual "Reserved" sign on Demand

      Form_UpdateDemandNode(bestDWT,bestD);
    end;

    //Return chosen unit and house
    aToHouse := fDemand[bestDWT, bestD].Loc_House;
    aToUnit := fDemand[bestDWT, bestD].Loc_Unit;
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psDelivery);
    {$ENDIF}
  end;
end;

// Find best Demand for the given delivery. Could return same or nothing
procedure TKMDeliveries.DeliveryFindBestDemand(aSerf: TKMUnitSerf; aDeliveryId: Integer; aWare: TKMWareType;
                                               out aToHouse: TKMHouse; out aToUnit: TKMUnit; out aForceDelivery: Boolean);

  function ValidBestDemand(dWT, oldDWT: TKMWareType; iD, iOldID: Integer): Boolean;
  var
    I: Integer;
    H: TKMHouse;
    demand, oldDemand: PKMDeliveryDemand;
  begin
    demand := @fDemand[dWT, iD];
    oldDemand := @fDemand[oldDWT,iOldID];

    //Check if unit is alive
    Result := ((demand.Loc_Unit = nil)
               or (not demand.Loc_Unit.IsDeadOrDying and (demand.Loc_Unit <> oldDemand^.Loc_Unit)));

    //If Demand house should abandon delivery
    Result := Result and ((demand.Loc_House = nil)
                          or not demand.Loc_House.IsComplete
                          or (not demand.Loc_House.ShouldAbandonDeliveryTo(aWare)
                             and (demand.Loc_House <> oldDemand^.Loc_House)));

    //If Demand aren't reserved already
    Result := Result and ((demand.DemandType = dtAlways) or (demand.BeingPerformed = 0));

    //For constructing houses check if they are connected with road to some other houses,
    //which can produce demanded ware (stone or wood)
    if Result
      and (demand.Loc_House <> nil)
      and not demand.Loc_House.IsComplete
      and not demand.Loc_House.IsDestroyed then
      for I := 0 to gHands[demand.Loc_House.Owner].Houses.Count - 1 do
      begin
        H := gHands[demand.Loc_House.Owner].Houses[I];
        if H.IsComplete
          and not H.IsDestroyed
          and H.CanHaveWareType(dWT) then
          Result := Result and gTerrain.Route_CanBeMade(H.PointBelowEntrance, demand.Loc_House.PointBelowEntrance, tpWalkRoad, 0);
      end;
  end;

  procedure FindBestDemandId(out aBestDWT: TKMWareType; out aBestDemandID: Integer);
  var
    iD, oldDemandId: Integer;
    dWT, oldDWT: TKMWareType;
    bid: TKMDeliveryBid;
    bestImportance: TKMDemandImportance;
    allowOffroad: Boolean;
  begin
    aBestDemandID := DELIVERY_NO_ID;
    aBestDWT := wtNone;

    aForceDelivery := False;
    oldDemandId := fQueue[aDeliveryId].DemandID;
    oldDWT := fQueue[aDeliveryId].DemandWare;
    bestImportance := Low(TKMDemandImportance);

    //Mark that delivery as IsFromUnit (Serf), since we are looking for other destination while in delivery process
    fQueue[aDeliveryId].IsFromUnit := True;

    allowOffroad := True; //(fDemand[oldDemandId].Loc_Unit <> nil) or fQueue[aDeliveryId].IsFromUnit;

    fBestBidCandidates.Clear;
//    fBestBidCandidates.EnlargeTo(128);      // Do we need it ?

    //Try to find house or unit demand first (not storage)
    for dWT := Low(fDemandCount) to High(fDemandCount) do
      if ValidWareTypePair(aWare, dWT) then
        for iD := 0 to fDemandCount[dWT] - 1 do
          if fDemand[dWT,iD].IsActive
            and not ((iD = oldDemandId) and (dWT = oldDWT))
            and not fDemand[dWT,iD].IsDeleted
            and (fDemand[dWT,iD].Importance >= bestImportance)
            and ValidBestDemand(dWT, oldDWT, iD, oldDemandId) then
          begin
            bid := TKMDeliveryBid.Create(fDemand[dWT,iD].Importance, aSerf, wtNone, dWT, 0, iD);
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
      for iD := 0 to fDemandCount[wtAll] - 1 do
        if not ((iD = oldDemandId) and (oldDWT = wtAll))
          and not fDemand[wtAll,iD].IsDeleted
          and (fDemand[wtAll,iD].Loc_House <> nil)
          and (fDemand[wtAll,iD].Loc_House is TKMHouseStore)
          and (fDemand[wtAll,iD].Loc_House.DeliveryMode = dmDelivery)
          and not fDemand[wtAll,iD].Loc_House.IsDestroyed
          and not TKMHouseStore(fDemand[wtAll,iD].Loc_House).NotAcceptFlag[aWare] then
        begin
          bid := TKMDeliveryBid.Create(fDemand[wtAll,iD].Importance, aSerf, wtNone, wtAll, 0, iD);
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
      for iD := 0 to fDemandCount[wtAll] - 1 do
        if not fDemand[wtAll,iD].IsDeleted
          and (fDemand[wtAll,iD].Loc_House <> nil)
          and not fDemand[wtAll,iD].Loc_House.IsDestroyed then //choose between all storages, including current delivery. But not destroyed
        begin
          bid := TKMDeliveryBid.Create(fDemand[wtAll,iD].Importance, aSerf, wtNone, wtAll, 0, iD);
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
      aBestDemandID := bid.DemandID;
      aBestDWT := bid.DemandWare;
      bid.Free;
    end;
  end;
var
  bestDemandId, oldDemandId: Integer; // Keep Int to assign to Delivery down below
  bestDWT, oldDWT: TKMWareType;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psDelivery);
  {$ENDIF}
  try
    oldDemandId := fQueue[aDeliveryId].DemandID;
    oldDWT := fQueue[aDeliveryId].DemandWare;
    FindBestDemandId(bestDWT, bestDemandId);

    // Did we find anything?
    if (bestDemandId = DELIVERY_NO_ID) or (bestDWT = wtNone) then
    begin
      // Remove old demand
      Dec(fDemand[oldDWT,oldDemandId].BeingPerformed);
      if (fDemand[oldDWT,oldDemandId].BeingPerformed = 0) and fDemand[oldDWT,oldDemandId].IsDeleted then
        CloseDemand(oldDWT,oldDemandId);

      Form_UpdateDemandNode(oldDWT,oldDemandId);

      // Delivery should be cancelled now
      CloseDelivery(aDeliveryId);
      aToHouse := nil;
      aToUnit := nil;
    end
    else
    begin
      // Did we switch jobs?
      if not ((bestDemandId = oldDemandId) and (bestDWT = oldDWT)) then
      begin
        // Remove old demand
        Dec(fDemand[oldDWT,oldDemandId].BeingPerformed);
        if (fDemand[oldDWT,oldDemandId].BeingPerformed = 0) and fDemand[oldDWT,oldDemandId].IsDeleted then
          CloseDemand(oldDWT,oldDemandId);

        Form_UpdateDemandNode(oldDWT,oldDemandId);

        // Take new demand
        fQueue[aDeliveryId].DemandId := bestDemandId;
        fQueue[aDeliveryId].DemandWare := bestDWT;
        Inc(fDemand[bestDWT,bestDemandId].BeingPerformed); //Places a virtual "Reserved" sign on Demand
        fQueue[aDeliveryId].IsFromUnit := True; //Now this delivery will always start from serfs hands

        Form_UpdateDemandNode(bestDWT,bestDemandId);
        Form_UpdateQueueNode(aDeliveryId);
      end;

      // Return chosen unit and house
      aToHouse := fDemand[bestDWT,bestDemandId].Loc_House;
      aToUnit := fDemand[bestDWT,bestDemandId].Loc_Unit;
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
  dWT, oWT: TKMWareType;
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
    fBestBidCandidates.EnlargeTo(128); // Do we need this?

    for dWT := Low(fDemandCount) to High(fDemandCount) do
      for oWT := WARE_MIN to WARE_MAX do
        if ValidWareTypePair(oWT, dWT) then
          for iD := 0 to fDemandCount[dWT] - 1 do
            if fDemand[dWT,iD].IsActive
              and (fDemand[dWT,iD].Importance >= bestImportance) then //Skip any less important than the best we found
              for iO := 0 to fOfferCount[oWT] - 1 do
                if ((aHouse = nil) or (fOffer[oWT,iO].Loc_House = aHouse))  //Make sure from house is the one requested
                  and fOffer[oWT,iO].IsActive
                  and PermitDelivery(oWT, dWT, iO, iD, aSerf) then
                begin
                  bid := TKMDeliveryBid.Create(fDemand[dWT,iD].Importance, aSerf, oWT, dWT, iO, iD);
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
      AssignDelivery(bid.OfferWare, bid.DemandWare, bid.OfferID, bid.DemandID, aSerf);
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
            and (fQueue[iQ].OfferWare <> wtNone)
            and (fQueue[iQ].DemandWare <> wtNone)
            and (fOffer[fQueue[iQ].OfferWare, fQueue[iQ].OfferID].Loc_House = aHouse)
            and (fDemand[fQueue[iQ].DemandWare, fQueue[iQ].DemandID].Importance >= bestImportance)
            and (TKMTaskDeliver(fQueue[iQ].Serf.Task).DeliverStage = dsToFromHouse) then // Serf can walk in this house
          begin
            bid := TKMDeliveryBid.Create(fDemand[fQueue[iQ].DemandWare, fQueue[iQ].DemandID].Importance, aSerf,
                                         fQueue[iQ].OfferWare, fQueue[iQ].DemandWare,
                                         fQueue[iQ].OfferID, fQueue[iQ].DemandID, iQ);
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


procedure TKMDeliveries.AssignDelivery(oWT, dWT: TKMWareType; iO, iD: Integer; aSerf: TKMUnitSerf);
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
  fQueue[I].DemandWare := dWT;
  fQueue[I].OfferID := iO;
  fQueue[I].OfferWare := oWT;
  fQueue[I].JobStatus := jsTaken;
  fQueue[I].Serf := TKMUnitSerf(aSerf.GetPointer);

  {$IFDEF USE_VIRTUAL_TREEVIEW}
  fQueue[I].Node := nil;
  {$ENDIF}

  Form_UpdateQueueNode(I);

  Inc(fOffer[oWT,iO].BeingPerformed); //Places a virtual "Reserved" sign on Offer
  Inc(fDemand[dWT,iD].BeingPerformed); //Places a virtual "Reserved" sign on Demand
  Form_UpdateOfferNode(oWT,iO);
  Form_UpdateDemandNode(dWT,iD);

  if gLog.CanLogDelivery then
    gLog.LogDelivery('Creating delivery ID ' + IntToStr(I));

  //Now we have best job and can perform it
  if fDemand[dWT,iD].Loc_House <> nil then
    aSerf.Deliver(fOffer[oWT,iO].Loc_House, fDemand[dWT,iD].Loc_House, oWT, I)
  else
    aSerf.Deliver(fOffer[oWT,iO].Loc_House, fDemand[dWT,iD].Loc_Unit, oWT, I)
end;


//Resource has been taken from Offer
procedure TKMDeliveries.TakenOffer(iQ: Integer);
var
  iO: Integer;
  oWT: TKMWareType;
begin
  if gLog.CanLogDelivery then
    gLog.LogDelivery('Taken offer from delivery ID ' + IntToStr(iQ));

  iO := fQueue[iQ].OfferID;
  oWT := fQueue[iQ].OfferWare;

  fQueue[iQ].OfferID := DELIVERY_NO_ID; //We don't need it any more
  fQueue[iQ].OfferWare := wtNone;

  Dec(fOffer[oWT,iO].BeingPerformed); //Remove reservation
  Dec(fOffer[oWT,iO].Count); //Remove resource from Offer list

  if fOffer[oWT,iO].Count = 0 then
    if fOffer[oWT,iO].BeingPerformed > 0 then
      fOffer[oWT,iO].IsDeleted := True
    else
      CloseOffer(oWT,iO);

  Form_UpdateQueueNode(iQ);
  Form_UpdateOfferNode(oWT,iO);
end;


//Resource has been delivered to Demand
procedure TKMDeliveries.GaveDemand(iQ: Integer);
var
  iD: Integer;
  dWT: TKMWareType;
begin
  if gLog.CanLogDelivery then
    gLog.LogDelivery('Gave demand from delivery ID ' + IntToStr(iQ));

  iD := fQueue[iQ].DemandID;
  dWT := fQueue[iQ].DemandWare;

  fQueue[iQ].DemandID := DELIVERY_NO_ID; //We don't need it any more
  fQueue[iQ].DemandWare := wtNone;

  Dec(fDemand[dWT,iD].BeingPerformed); //Remove reservation

  fDemand[dWT,iD].NotifyLocHouseOnClose := False; //No need to notify Loc_House since we already delivered item

  if (fDemand[dWT,iD].DemandType = dtOnce)
    or (fDemand[dWT,iD].IsDeleted and (fDemand[dWT,iD].BeingPerformed = 0)) then
    CloseDemand(dWT,iD); //Remove resource from Demand list

  Form_UpdateDemandNode(dWT,iD);
end;


//AbandonDelivery
procedure TKMDeliveries.AbandonDelivery(iQ: Integer);
var
  iO, iD: Integer;
  oWT, dWT: TKMWareType;
begin
  if gLog.CanLogDelivery then
    gLog.LogDelivery('Abandoned delivery ID ' + IntToStr(iQ));

  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psDelivery);
  {$ENDIF}
  try
    iO := fQueue[iQ].OfferID;
    oWT := fQueue[iQ].OfferWare;

    //Remove reservations without removing items from lists
    if (iO <> DELIVERY_NO_ID) and (oWT <> wtNone) then
    begin
      Dec(fOffer[oWT,iO].BeingPerformed);
      //Now see if we need to delete the Offer as we are the last remaining pointer
      if fOffer[oWT,iO].IsDeleted and (fOffer[oWT,iO].BeingPerformed = 0) then
        CloseOffer(oWT,iO);

      Form_UpdateOfferNode(oWT,iO);
    end;

    iD := fQueue[iQ].DemandID;
    dWT := fQueue[iQ].DemandWare;

    if (iD <> DELIVERY_NO_ID) and (dWT <> wtNone) then
    begin
      Dec(fDemand[dWT,iD].BeingPerformed);
      if fDemand[dWT,iD].IsDeleted and (fDemand[dWT,iD].BeingPerformed = 0) then
        CloseDemand(dWT,iD);

      Form_UpdateDemandNode(dWT,iD);
    end;

    CloseDelivery(iQ);
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psDelivery);
    {$ENDIF}
  end;
end;


//Job successfully done and we ommit it
procedure TKMDeliveries.CloseDelivery(aID: Integer);
begin
  if gLog.CanLogDelivery then
    gLog.LogDelivery('Closed delivery ID ' + IntToStr(aID));

  fQueue[aID].OfferWare := wtNone;
  fQueue[aID].DemandWare := wtNone;
  fQueue[aID].OfferID := DELIVERY_NO_ID;
  fQueue[aID].DemandID := DELIVERY_NO_ID;
  fQueue[aID].JobStatus := jsEmpty; //Open slot
  gHands.CleanUpUnitPointer(TKMUnit(fQueue[aID].Serf));

  fQueue[aID].Cleanup;
end;


procedure TKMDeliveries.CloseDemand(aWare: TKMWareType; aID: Integer);
begin
  Assert(fDemand[aWare,aID].BeingPerformed = 0);

  if fDemand[aWare,aID].NotifyLocHouseOnClose and (fDemand[aWare,aID].Loc_House <> nil) then
    fDemand[aWare,aID].Loc_House.DecResourceDelivery(aWare);

  fDemand[aWare,aID].NotifyLocHouseOnClose := False;
  fDemand[aWare,aID].IsActive := False;
  fDemand[aWare,aID].DemandType := dtOnce;
  fDemand[aWare,aID].Importance := Low(TKMDemandImportance);
  gHands.CleanUpHousePointer(fDemand[aWare,aID].Loc_House);
  gHands.CleanUpUnitPointer(fDemand[aWare,aID].Loc_Unit);
  fDemand[aWare,aID].IsDeleted := False;

  fDemand[aWare,aID].Cleanup;
end;


procedure TKMDeliveries.CloseOffer(aWare: TKMWareType; aID: Integer);
begin
  Assert(fOffer[aWare,aID].BeingPerformed = 0);
  fOffer[aWare,aID].IsDeleted := false;
  fOffer[aWare,aID].IsActive := False;
  fOffer[aWare,aID].Count := 0;
  gHands.CleanUpHousePointer(fOffer[aWare,aID].Loc_House);

  fOffer[aWare,aID].Cleanup;
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
  WT: TKMWareType;
begin
  SaveStream.PlaceMarker('Deliveries');
  SaveStream.Write(fOwner);

  SaveStream.PlaceMarker('Offers');
  for WT := Low(fOfferCount) to High(fOfferCount) do
  begin
    SaveStream.Write(fOfferCount[WT]);
    for I := 0 to fOfferCount[WT] - 1 do
      with fOffer[WT,I] do
      begin
        SaveStream.Write(IsActive);
        SaveStream.Write(Count);
        SaveStream.Write(Loc_House.UID);
        SaveStream.Write(BeingPerformed);
        SaveStream.Write(IsDeleted);
      end;
  end;


  SaveStream.PlaceMarker('Demands');
  for WT := Low(fDemandCount) to High(fDemandCount) do
  begin
    SaveStream.Write(fDemandCount[WT]);
    for I := 0 to fDemandCount[WT] - 1 do
      with fDemand[WT,I] do
      begin
        SaveStream.Write(IsActive);
        SaveStream.Write(DemandType, SizeOf(DemandType));
        SaveStream.Write(Importance, SizeOf(Importance));

        SaveStream.Write(Loc_House.UID);
        SaveStream.Write(Loc_Unit.UID );

        SaveStream.Write(BeingPerformed);
        SaveStream.Write(IsDeleted);
        SaveStream.Write(NotifyLocHouseOnClose);
      end;
  end;

  SaveStream.PlaceMarker('Queue');

  SaveStream.Write(fQueueCount);
  for I := 0 to fQueueCount - 1 do
    with fQueue[I] do
    begin
      SaveStream.Write(IsFromUnit);
      SaveStream.Write(OfferWare, SizeOf(OfferWare));
      SaveStream.Write(DemandWare, SizeOf(DemandWare));
      SaveStream.Write(OfferID);
      SaveStream.Write(DemandID);
      SaveStream.Write(JobStatus, SizeOf(JobStatus));
      SaveStream.Write(Serf.UID );
    end;

  fRouteEvaluator.Save(SaveStream);
end;


procedure TKMDeliveries.Load(LoadStream: TKMemoryStream);
var
  I: Integer;
  WT: TKMWareType;
begin
  LoadStream.CheckMarker('Deliveries');
  LoadStream.Read(fOwner);

  LoadStream.CheckMarker('Offers');
  for WT := Low(fOfferCount) to High(fOfferCount) do
  begin
    LoadStream.Read(fOfferCount[WT]);
    SetLength(fOffer[WT], fOfferCount[WT]);

    for I := 0 to fOfferCount[WT] - 1 do
      with fOffer[WT,I] do
      begin
        LoadStream.Read(IsActive);
        LoadStream.Read(Count);
        LoadStream.Read(Loc_House, 4);
        LoadStream.Read(BeingPerformed);
        LoadStream.Read(IsDeleted);
      end;
  end;

  LoadStream.CheckMarker('Demands');
  for WT := Low(fDemandCount) to High(fDemandCount) do
  begin
    LoadStream.Read(fDemandCount[WT]);
    SetLength(fDemand[WT], fDemandCount[WT]);
    for I := 0 to fDemandCount[WT] - 1 do
      with fDemand[WT,I] do
      begin
        LoadStream.Read(IsActive);
        LoadStream.Read(DemandType, SizeOf(DemandType));
        LoadStream.Read(Importance, SizeOf(Importance));
        LoadStream.Read(Loc_House, 4);
        LoadStream.Read(Loc_Unit, 4);
        LoadStream.Read(BeingPerformed);
        LoadStream.Read(IsDeleted);
        LoadStream.Read(NotifyLocHouseOnClose);
      end;
  end;

  LoadStream.CheckMarker('Queue');
  LoadStream.Read(fQueueCount);
  SetLength(fQueue, fQueueCount);
  for I := 0 to fQueueCount - 1 do
    with fQueue[I] do
    begin
      LoadStream.Read(IsFromUnit);
      LoadStream.Read(OfferWare, SizeOf(OfferWare));
      LoadStream.Read(DemandWare, SizeOf(DemandWare));
      LoadStream.Read(OfferID);
      LoadStream.Read(DemandID);
      LoadStream.Read(JobStatus, SizeOf(JobStatus));
      LoadStream.Read(Serf, 4);
    end;

  fRouteEvaluator.Load(LoadStream);
end;


procedure TKMDeliveries.SyncLoad;
var
  I: Integer;
  WT: TKMWareType;
begin
  for WT := Low(fOfferCount) to High(fOfferCount) do
    for I := 0 to fOfferCount[WT] - 1 do
      with fOffer[WT,I] do
      begin
        Loc_House := gHands.GetHouseByUID(Cardinal(Loc_House));
        Form_UpdateOfferNode(WT,I);
      end;

  for WT := Low(fDemandCount) to High(fDemandCount) do
    for I := 0 to fDemandCount[WT] - 1 do
      with fDemand[WT,I] do
      begin
        Loc_House := gHands.GetHouseByUID(Cardinal(Loc_House));
        Loc_Unit := gHands.GetUnitByUID(Cardinal(Loc_Unit));
        Form_UpdateDemandNode(WT,I);
      end;

  for I := 0 to fQueueCount - 1 do
    with fQueue[I] do
    begin
      Serf := TKMUnitSerf(gHands.GetUnitByUID(Cardinal(Serf)));
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
  WT: TKMWareType;
  SL: TStringList;
  tmpS: UnicodeString;
begin
  SL := TStringList.Create;

  SL.Append('Demand:');
  SL.Append('---------------------------------');
  for WT := Low(fDemandCount) to High(fDemandCount) do
    for I := 0 to fDemandCount[WT] - 1 do
      if fDemand[WT,I].IsActive then
      begin
        tmpS := #9;
        if fDemand[WT,I].Loc_House <> nil then tmpS := tmpS + gResHouses[fDemand[WT,I].Loc_House.HouseType].HouseName + #9 + #9;
        if fDemand[WT,I].Loc_Unit  <> nil then tmpS := tmpS + gRes.Units[fDemand[WT,I].Loc_Unit.UnitType].GUIName + #9 + #9;
        tmpS := tmpS + gResWares[WT].Title;
        if fDemand[WT,I].Importance <> diNorm then
          tmpS := tmpS + '^';

        SL.Append(tmpS);
      end;

  SL.Append('Offer:');
  SL.Append('---------------------------------');
  for WT := Low(fOfferCount) to High(fOfferCount) do
    for I := 0 to fOfferCount[WT] - 1 do
      if fOffer[WT,I].IsActive then
      begin
        tmpS := #9;
        if fOffer[WT,I].Loc_House <> nil then tmpS := tmpS + gResHouses[fOffer[WT,I].Loc_House.HouseType].HouseName + #9 + #9;
        tmpS := tmpS + gResWares[WT].Title + #9;
        tmpS := tmpS + IntToStr(fOffer[WT,I].Count);

        SL.Append(tmpS);
      end;

  SL.Append('Running deliveries:');
  SL.Append('---------------------------------');
  for I := 0 to fQueueCount - 1 do
  if fQueue[I].OfferID <> DELIVERY_NO_ID then
  begin
    tmpS := 'id ' + IntToStr(I) + '.' + #9;
    tmpS := tmpS + gResWares[fQueue[I].OfferWare].Title + #9;

    if fOffer[fQueue[I].OfferWare, fQueue[I].OfferID].Loc_House = nil then
      tmpS := tmpS + 'Destroyed' + ' >>> '
    else
      tmpS := tmpS + gResHouses[fOffer[fQueue[I].OfferWare, fQueue[I].OfferID].Loc_House.HouseType].HouseName + ' >>> ';

    if fDemand[fQueue[I].DemandWare, fQueue[I].DemandID].Loc_House = nil then
      tmpS := tmpS + 'Destroyed'
    else
      tmpS := tmpS + gResHouses[fDemand[fQueue[I].DemandWare, fQueue[I].DemandID].Loc_House.HouseType].HouseName;

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
  Create(Low(TKMDemandImportance), aSerf, wtNone, wtNone, DELIVERY_NO_ID, DELIVERY_NO_ID);
end;


constructor TKMDeliveryBid.Create(aImportance: TKMDemandImportance; aSerf: TKMUnitSerf; oWT, dWT: TKMWareType; iO, iD: Integer; iQ: Integer = DELIVERY_NO_ID);
begin
  inherited Create;

  Importance := aImportance;
  QueueID := iQ;
  OfferWare := oWT;
  DemandWare := dWT;
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
  IsActive := False;
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
  IsActive := False;
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

