unit KM_HandLogistics;
{$I KaM_Remake.inc}
interface
uses
  ComCtrls,
  {$IF Defined(FPC) or Defined(VER230)}
  {$ELSE}
    {$DEFINE USE_HASH}
  {$IFEND}

  {$IFDEF USE_HASH}
  Generics.Collections, Generics.Defaults, System.Hash,
  {$ENDIF}
  KM_Units, KM_Houses, KM_ResHouses,
  KM_ResWares, KM_CommonClasses, KM_Defaults, KM_Points;


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
    Item: TListItem;
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
    Item: TListItem;
  end;

  {$IFDEF USE_HASH}
  //Bids cache key
  TKMDeliveryBidKey = record
    FromUID: Integer; //House or Unit UID From where delivery path goes
    ToUID: Integer;   //same for To where delivery path goes
  end;

type
  //Custom key comparator. Probably TDictionary can handle it himself, but lets try our custom comparator
  TKMDeliveryBidKeyEqualityComparer = class(TEqualityComparer<TKMDeliveryBidKey>)
    function Equals(const Left, Right: TKMDeliveryBidKey): Boolean; override;
    function GetHashCode(const Value: TKMDeliveryBidKey): Integer; override;
  end;

  TKMDeliveryBidKeyComparer = class(TComparer<TKMDeliveryBidKey>)
    function Compare(const Left, Right: TKMDeliveryBidKey): Integer; override;
  end;
  {$ENDIF}

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
    fQueue: array of
    record
      Serf: TKMUnitSerf;
      IsFromUnit: Boolean; //Delivery was redispatched, so now we start delivery from current serf position
      OfferID, DemandID: Integer;
      JobStatus: TKMDeliveryJobStatus; //Empty slot, resource Taken, job Done
      Item: TListItem;
    end;

    {$IFDEF USE_HASH}
    // Cache of bid costs between offer object (house, serf) and demand object (house, unit - worker or warrior)
    fOfferToDemandCache: TDictionary<TKMDeliveryBidKey, Single>;
    // Cache of bid costs between serf and offer house
    fSerfToOfferCache: TDictionary<TKMDeliveryBidKey, Single>;
    {$ENDIF}

    fNodeList: TKMPointList; // Used to calc delivery bid

    function AllowFormLogisticsChange: Boolean;
    procedure UpdateOfferItem(aI: Integer);
    procedure UpdateDemandItem(aI: Integer);
    procedure UpdateQueueItem(aI: Integer);

    function GetSerfActualPos(aSerf: TKMUnit): TKMPoint;
    procedure CloseDelivery(aID: Integer);
    procedure CloseDemand(aID: Integer);
    procedure CloseOffer(aID: Integer);
    function ValidDelivery(iO, iD: Integer; aIgnoreOffer: Boolean = False): Boolean;
    function SerfCanDoDelivery(iO, iD: Integer; aSerf: TKMUnitSerf): Boolean;
    function PermitDelivery(iO, iD: Integer; aSerf: TKMUnitSerf): Boolean;
    function TryCalculateBid(iO, iD: Integer; var aBidValue: Single; aSerf: TKMUnitSerf = nil): Boolean;
    function TryCalculateBidBasic(iO, iD: Integer; var aBidBasicValue: Single; aSerf: TKMUnitSerf = nil;
                                  aAllowOffroad: Boolean = False): Boolean; overload;
    function TryCalculateBidBasic(aOfferUID: Integer; aOfferPos: TKMPoint; aOfferCnt: Cardinal; aOfferHouseType: TKMHouseType;
                                  aOwner: TKMHandID; iD: Integer; var aBidBasicValue: Single; aSerf: TKMUnitSerf = nil;
                                  aAllowOffroad: Boolean = False): Boolean; overload;
    function TryCalcSerfBidValue(aSerf: TKMUnitSerf; aOfferPos: TKMPoint; aToUID: Integer; var aSerfBidValue: Single): Boolean;
    function TryCalcRouteCost(aFromPos, aToPos: TKMPoint; aMainPass: TKMTerrainPassability; var aRoutCost: Single; aSecondPass: TKMTerrainPassability = tpUnused): Boolean;
    function GetUnitsCntOnPath(aNodeList: TKMPointList): Integer;
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

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad;

    procedure UpdateState(aTick: Cardinal);

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
  public
    constructor Create(aHandIndex: TKMHandID);
    destructor Destroy; override;

    procedure AddSerf(aSerf: TKMUnitSerf);
    property Queue: TKMDeliveries read fQueue;

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
  KM_Main, KM_Game, KM_Hand, KM_HandsCollection, KM_HouseBarracks,
  KM_Resource, KM_ResUnits,
  KM_Log, KM_Utils, KM_CommonUtils, KM_DevPerfLog, KM_DevPerfLogTypes;


const
  //Max distance to use pathfinding on calc delivery bids. No need to calc on very long distance
  BID_CALC_MAX_DIST_FOR_PATHF = 100;
  //Approx compensation to compare Bid cost calc with pathfinding and without it. Pathfinding is usually longer
  BID_CALC_PATHF_COMPENSATION = 0.9;
  CACHE_CLEAN_FREQ = 10; //in ticks. Clean cache every N ticks
  LENGTH_INC = 32; //Increment array lengths by this value
  NOT_REACHABLE_DEST_VALUE = MaxSingle;


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
var I: Integer;
begin
  SaveStream.PlaceMarker('SerfList');

  SaveStream.Write(fSerfCount);
  for I := 0 to fSerfCount - 1 do
  begin
    if fSerfs[I].Serf <> nil then
      SaveStream.Write(fSerfs[I].Serf.UID)
    else
      SaveStream.Write(Integer(0));
  end;

  fQueue.Save(SaveStream);
end;


procedure TKMHandLogistics.Load(LoadStream: TKMemoryStream);
var I: Integer;
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

  fSerfs[fSerfCount].Serf := TKMUnitSerf(aSerf.GetUnitPointer);
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
var I: Integer;
begin
  Result := 0;
  for I := 0 to fSerfCount - 1 do
    if fSerfs[I].Serf.IsIdle then
      Inc(Result);
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
  var I: Integer;
  begin
    Result := False;
    for I := 0 to fSerfCount - 1 do
      if fSerfs[I].Serf.IsIdle and fQueue.SerfCanDoDelivery(iO, iD, fSerfs[I].Serf) then
      begin
        Result := True;
        Exit;
      end;
  end;

var
  I, K, iD, iO, FoundO, FoundD: Integer;
  Bid, BestBid: Single;
  BestImportance: TKMDemandImportance;
  AvailableDeliveries, AvailableSerfs: Integer;
  Serf: TKMUnitSerf;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psDelivery, aTick);
  {$ENDIF}
  try
    fQueue.UpdateState(aTick);
    RemoveExtraSerfs;

    AvailableDeliveries := fQueue.GetAvailableDeliveriesCount;
    AvailableSerfs := GetIdleSerfCount;
    if AvailableSerfs * AvailableDeliveries = 0 then Exit;

    if AvailableDeliveries > AvailableSerfs then
    begin
      for I := 0 to fSerfCount - 1 do
        if fSerfs[I].Serf.IsIdle then
          fQueue.AskForDelivery(fSerfs[I].Serf);
    end
    else
    //I is not used anywhere, but we must loop through once for each delivery available so each one is taken
    for I := 1 to AvailableDeliveries do
    begin
      //First we decide on the best delivery to be done based on current Offers and Demands
      //We need to choose the best delivery out of all of them, otherwise we could get
      //a further away storehouse when there are multiple possibilities.
      //Note: All deliveries will be taken, because we have enough serfs to fill them all.
      //The important concept here is to always get the shortest delivery when a delivery can be taken to multiple places.
      BestBid := MaxSingle;
      BestImportance := Low(TKMDemandImportance);
      FoundO := -1;
      FoundD := -1;
      for iD := 1 to fQueue.fDemandCount do
        if (fQueue.fDemand[iD].Ware <> wtNone)
          and (fQueue.fDemand[iD].Importance >= BestImportance) then //Skip any less important than the best we found
          for iO := 1 to fQueue.fOfferCount do
            if (fQueue.fOffer[iO].Ware <> wtNone)
              and fQueue.ValidDelivery(iO,iD)
              and AnySerfCanDoDelivery(iO,iD) //Only choose this delivery if at least one of the serfs can do it
              and fQueue.TryCalculateBid(iO,iD,Bid)
              and ((Bid < BestBid) or (fQueue.fDemand[iD].Importance > BestImportance)) then
            begin
              BestBid := Bid;
              BestImportance := fQueue.fDemand[iD].Importance;
              FoundO := iO;
              FoundD := iD;
            end;

      //FoundO and FoundD give us the best delivery to do at this moment. Now find the best serf for the job.
      if (FoundO <> -1) and (FoundD <> -1) then
      begin
        Serf := nil;
        BestBid := MaxSingle;
        for K := 0 to fSerfCount - 1 do
          if fSerfs[K].Serf.IsIdle then
            if fQueue.SerfCanDoDelivery(FoundO,FoundD,fSerfs[K].Serf) then
            begin
              Bid := KMLength(fSerfs[K].Serf.CurrPosition, fQueue.fOffer[FoundO].Loc_House.Entrance);
              if (Bid < BestBid) then
              begin
                BestBid := Bid;
                Serf := fSerfs[K].Serf;
              end;
            end;
        if Serf <> nil then
          fQueue.AssignDelivery(FoundO, FoundD, Serf);
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
{$IFDEF USE_HASH}
var
  CacheKeyComparer: TKMDeliveryBidKeyEqualityComparer;
{$ENDIF}
begin
  fOwner := aHandIndex;
  {$IFDEF USE_HASH}
  if CACHE_DELIVERY_BIDS then
  begin
    CacheKeyComparer := TKMDeliveryBidKeyEqualityComparer.Create;
    fOfferToDemandCache := TDictionary<TKMDeliveryBidKey, Single>.Create(CacheKeyComparer);
    fSerfToOfferCache := TDictionary<TKMDeliveryBidKey, Single>.Create(CacheKeyComparer);
  end;

  {$ENDIF}
  if DELIVERY_BID_CALC_USE_PATHFINDING then
    fNodeList := TKMPointList.Create;

  if AllowFormLogisticsChange then
  begin
    FormLogistics.DeliveriesList.Items.Clear;
    FormLogistics.OffersList.Items.Clear;
    FormLogistics.DemandsList.Items.Clear;
  end;
end;


destructor TKMDeliveries.Destroy;
begin
  {$IFDEF USE_HASH}
  if CACHE_DELIVERY_BIDS then
  begin
    FreeAndNil(fSerfToOfferCache);
    FreeAndNil(fOfferToDemandCache);
  end;
  {$ENDIF}
  if DELIVERY_BID_CALC_USE_PATHFINDING then
    FreeAndNil(fNodeList);

  inherited;
end;


function TKMDeliveries.AllowFormLogisticsChange: Boolean;
begin
  Result := gMain.IsDebugChangeAllowed and Assigned(FormLogistics);
end;


procedure TKMDeliveries.UpdateOfferItem(aI: Integer);
begin
  if aI >= fOfferCount then Exit;

  with fOffer[aI] do
    if AllowFormLogisticsChange
      and (gGame <> nil) and not gGame.ReadyToStop
      and (Ware <> wtNone) then
    begin
      if Item = nil then
        Item := FormLogistics.OffersList.Items.Add;

      if Item = nil then Exit;

      Item.Caption := IntToStr(Item.Index);
      Item.SubItems.Clear;

      Item.SubItems.Add(IntToStr(fOwner));
      Item.SubItems.Add(IntToStr(aI));
      Item.SubItems.Add(gRes.Wares[Ware].Title);

      if Loc_House <> nil then
      begin
        Item.SubItems.Add(gRes.Houses[Loc_House.HouseType].HouseName);
        Item.SubItems.Add(IntToStr(Loc_House.UID));
      end
      else
      begin
        Item.SubItems.Add('nil');
        Item.SubItems.Add('-');
      end;

      Item.SubItems.Add(IntToStr(Count));
      Item.SubItems.Add(IntToStr(BeingPerformed));
      Item.SubItems.Add(BoolToStr(IsDeleted, True));
    end;
end;


procedure TKMDeliveries.UpdateDemandItem(aI: Integer);
begin
  if aI >= fDemandCount then Exit;

  with fDemand[aI] do
    if AllowFormLogisticsChange
      and (gGame <> nil) and not gGame.ReadyToStop
      and (Ware <> wtNone) then
    begin
      if Item = nil then
        Item := FormLogistics.DemandsList.Items.Add;

      if Item = nil then Exit;

      Item.Caption := IntToStr(Item.Index);
      Item.SubItems.Clear;

      Item.SubItems.Add(IntToStr(fOwner));
      Item.SubItems.Add(IntToStr(aI));
      Item.SubItems.Add(gRes.Wares[Ware].Title);

      if Loc_House <> nil then
      begin
        Item.SubItems.Add('H: ' + gRes.Houses[Loc_House.HouseType].HouseName);
        Item.SubItems.Add(IntToStr(Loc_House.UID));
      end
      else if Loc_Unit <> nil then
      begin
        Item.SubItems.Add('U: ' + gRes.Units[Loc_Unit.UnitType].GUIName);
        Item.SubItems.Add(IntToStr(Loc_Unit.UID));
      end
      else
      begin
        Item.SubItems.Add('nil');
        Item.SubItems.Add('-');
      end;

      Item.SubItems.Add(GetEnumName(TypeInfo(TKMDemandType), Integer(DemandType)));
      Item.SubItems.Add(GetEnumName(TypeInfo(TKMDemandImportance), Integer(Importance)));
      Item.SubItems.Add(IntToStr(BeingPerformed));
      Item.SubItems.Add(BoolToStr(IsDeleted, True));
    end;
end;


procedure TKMDeliveries.UpdateQueueItem(aI: Integer);
begin
  if aI >= fQueueCount then Exit;

  if AllowFormLogisticsChange then
    with fQueue[aI] do
    begin
      if Item = nil then
        Item := FormLogistics.DeliveriesList.Items.Add;

      Item.Caption := IntToStr(Item.Index);
      Item.SubItems.Clear;

      Item.SubItems.Add(IntToStr(fOwner));
      Item.SubItems.Add(IntToStr(aI));
      Item.SubItems.Add(gRes.Wares[fDemand[DemandID].Ware].Title); //Use demand ware, as offer could be nil after redispatching

      if fOffer[OfferID].Loc_House = nil then
      begin
        Item.SubItems.Add('nil');
        Item.SubItems.Add('-');
      end
      else
      begin
        Item.SubItems.Add(gRes.Houses[fOffer[OfferID].Loc_House.HouseType].HouseName);
        Item.SubItems.Add(IntToStr(fOffer[OfferID].Loc_House.UID));
      end;

      if fDemand[DemandID].Loc_House <> nil then
      begin
        Item.SubItems.Add('H: ' + gRes.Houses[fDemand[DemandID].Loc_House.HouseType].HouseName);
        Item.SubItems.Add(IntToStr(fDemand[DemandID].Loc_House.UID));
      end
      else
      if fDemand[DemandID].Loc_Unit <> nil then
      begin
        Item.SubItems.Add('U: ' + gRes.Units[fDemand[DemandID].Loc_Unit.UnitType].GUIName);
        Item.SubItems.Add(IntToStr(fDemand[DemandID].Loc_Unit.UID));
      end
      else
      begin
        Item.SubItems.Add('nil');
        Item.SubItems.Add('-');
      end;

      if Serf = nil then
        Item.SubItems.Add('nil')
      else
        Item.SubItems.Add(IntToStr(Serf.UID));
    end;
end;


//Adds new Offer to the list. List is stored without sorting
//(it matters only for Demand to keep everything in waiting its order in line),
//so we just find an empty place and write there.
procedure TKMDeliveries.AddOffer(aHouse: TKMHouse; aWare: TKMWareType; aCount: Integer);
var
  I, K: Integer;
begin
  if gGame.IsMapEditor then
    Exit;
  if aCount = 0 then
    Exit;

  //Add Count of resource to old offer
  for I := 1 to fOfferCount do
    if (fOffer[I].Loc_House = aHouse)
    and (fOffer[I].Ware = aWare) then
    begin
      if fOffer[I].IsDeleted then
      begin
        //Revive old offer because some serfs are still walking to perform it
        Assert(fOffer[I].BeingPerformed > 0);
        fOffer[I].Count :=  aCount;
        fOffer[I].IsDeleted := False;

        UpdateOfferItem(I);
        Exit; //Count added, thats all
      end
      else
      begin
        Inc(fOffer[I].Count, aCount);

        UpdateOfferItem(I);

        Exit; //Count added, thats all
      end;
    end;

  //Find empty place or allocate new one
  I := 1;
  while (I <= fOfferCount) and (fOffer[I].Ware <> wtNone) do
    Inc(I);
  if I > fOfferCount then
  begin
    Inc(fOfferCount, LENGTH_INC);
    SetLength(fOffer, fOfferCount + 1);
    for K := I to fOfferCount do
      FillChar(fOffer[K], SizeOf(fOffer[K]), #0); //Initialise the new queue space
  end;

  //Add offer
  with fOffer[I] do
  begin
    if aHouse <> nil then
      Loc_House := aHouse.GetHousePointer;
    Ware := aWare;
    Count := aCount;
    Assert((BeingPerformed = 0) and not IsDeleted); //Make sure this item has been closed properly, if not there is a flaw

    UpdateOfferItem(I);
  end;
end;


//Remove Offer from the list. E.G on house demolish
//List is stored without sorting so we have to parse it to find that entry..
procedure TKMDeliveries.RemAllOffers(aHouse: TKMHouse);
var
  I: Integer;
begin
  if gGame.IsMapEditor then
    Exit;

  //We need to parse whole list, never knowing how many offers the house had
  for I := 1 to fOfferCount do
  if fOffer[I].Loc_House = aHouse then
    if fOffer[I].BeingPerformed > 0 then
    begin
      //Keep it until all associated deliveries are abandoned
      fOffer[I].IsDeleted := True; //Don't reset it until serfs performing this offer are done with it
      fOffer[I].Count := 0; //Make the count 0 so no one else tries to take this offer
      UpdateOfferItem(I);
    end
    else
      CloseOffer(I);
end;


procedure TKMDeliveries.RemOffer(aHouse: TKMHouse; aWare: TKMWareType; aCount: Cardinal);
var
  I: Integer;
begin
  if gGame.IsMapEditor then
    Exit;
  if aCount = 0 then
    Exit;
  
  //Add Count of resource to old offer
  for I := 1 to fOfferCount do
    if (fOffer[I].Loc_House = aHouse)
      and (fOffer[I].Ware = aWare)
      and not fOffer[I].IsDeleted then
    begin
      Assert(fOffer[I].Count >= aCount, 'Removing too many offers');
      Dec(fOffer[I].Count, aCount);
      if fOffer[I].Count = 0 then
      begin
        if fOffer[i].BeingPerformed > 0 then
          fOffer[i].IsDeleted := True
        else
          CloseOffer(i);
      end;
      UpdateOfferItem(I);
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
  if gGame.IsMapEditor then
    Exit;

  Assert(aHouse <> nil);
  for I := 1 to fDemandCount do
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
  if fQueue[aIQ].DemandID <> 0 then
    Result := not fDemand[fQueue[aIQ].DemandId].IsDeleted //Delivery could be cancelled because of Demand marked as Deleted
  else
    Result := False; //Not allowed delivery if demandId is underfined (= 0)
end;


//Remove Demand from the list
// List is stored without sorting so we parse it to find all entries..
procedure TKMDeliveries.RemDemand(aUnit: TKMUnit);
var
  I: Integer;
begin
  if gGame.IsMapEditor then
    Exit;
  Assert(aUnit <> nil);
  for I := 1 to fDemandCount do
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
  for I := 1 to fQueueCount do
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

  if gGame.IsMapEditor then
    Exit;

  if aCount = 0 then Exit;
  Assert(aHouse <> nil);
  for I := fDemandCount downto 1 do
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
    //If we didn't find enought not performed demands, mark found performing demands as deleted to be removed soon
    for I := 0 to Min(aPlannedToRemove, aCount - Result) - 1 do
    begin
      fDemand[PlannedIDs[I]].IsDeleted := True;
      fDemand[PlannedIDs[I]].NotifyLocHouseOnClose := aRemoveBeingPerformed;
    end;
end;


function TKMDeliveries.GetDemandsCnt(aHouse: TKMHouse; aResource: TKMWareType; aType: TKMDemandType; aImp: TKMDemandImportance): Integer;
var
  I: Integer;
  Demand: TKMDeliveryDemand;
begin
  Result := 0;

  if (aHouse = nil) or (aResource = wtNone)  then Exit;

  for I := 1 to fDemandCount do
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
  if gGame.IsMapEditor then
    Exit;
  Assert(aResource <> wtNone, 'Demanding rtNone');
  if aCount <= 0 then Exit;


  for K := 1 to aCount do
  begin
    I := 1;
    while (I <= fDemandCount) and (fDemand[I].Ware <> wtNone) do
      Inc(I);
    if I > fDemandCount then
    begin
      Inc(fDemandCount, LENGTH_INC);
      SetLength(fDemand, fDemandCount + 1);
      for J := I to fDemandCount do
        FillChar(fDemand[J], SizeOf(fDemand[J]), #0); //Initialise the new queue space
    end;

    with fDemand[I] do
    begin
      if aHouse <> nil then
        Loc_House := aHouse.GetHousePointer;

      if aUnit <> nil then
        Loc_Unit := aUnit.GetUnitPointer;

      DemandType := aType; //Once or Always
      Ware := aResource;
      Importance := aImp;
      Assert((not IsDeleted) and (BeingPerformed = 0)); //Make sure this item has been closed properly, if not there is a flaw

      //Gold to Schools
      if (Ware = wtGold)
        and (Loc_House <> nil) and (Loc_House.HouseType = htSchool) then
        Importance := diHigh1;

      //Food to Inn
      if (Ware in [wtBread, wtSausages, wtWine, wtFish])
        and (Loc_House <> nil) and (Loc_House.HouseType = htInn) then
        Importance := diHigh3;

      UpdateDemandItem(I);
    end;
  end;
end;


//IgnoreOffer means we don't check whether offer was already taken or deleted (used after offer was already claimed)
function TKMDeliveries.ValidDelivery(iO,iD: Integer; aIgnoreOffer: Boolean = False): Boolean;
var
  I: Integer;
  B: TKMHouseBarracks;
begin
  //If Offer Resource matches Demand
  Result := (fDemand[iD].Ware = fOffer[iO].Ware) or
            (fDemand[iD].Ware = wtAll) or
            ((fDemand[iD].Ware = wtWarfare) and (fOffer[iO].Ware in [WARFARE_MIN..WARFARE_MAX])) or
            ((fDemand[iD].Ware = wtFood) and (fOffer[iO].Ware in [wtBread, wtSausages, wtWine, wtFish]));

  //If Demand and Offer aren't reserved already
  Result := Result and (((fDemand[iD].DemandType = dtAlways) or (fDemand[iD].BeingPerformed = 0))
                   and (aIgnoreOffer or (fOffer[iO].BeingPerformed < fOffer[iO].Count)));

  //If Demand and Offer aren't deleted
  Result := Result and not fDemand[iD].IsDeleted and (aIgnoreOffer or not fOffer[iO].IsDeleted);

  //If Offer should not be abandoned
  Result := Result and not fOffer[iO].Loc_House.ShouldAbandonDeliveryFrom(fOffer[iO].Ware)
                   //Check store to store evacuation
                   and not fOffer[iO].Loc_House.ShouldAbandonDeliveryFromTo(fDemand[iD].Loc_House, fOffer[iO].Ware, False);


  //If Demand house should abandon delivery
  Result := Result and ((fDemand[iD].Loc_House = nil)
                         or not fDemand[iD].Loc_House.IsComplete
                         or not fDemand[iD].Loc_House.ShouldAbandonDeliveryTo(fOffer[iO].Ware));

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

  Result := Result and (
            ( //House-House delivery should be performed only if there's a connecting road
            (fDemand[iD].Loc_House <> nil) and
            (gTerrain.Route_CanBeMade(fOffer[iO].Loc_House.PointBelowEntrance, fDemand[iD].Loc_House.PointBelowEntrance, tpWalkRoad, 0))
            )
            or
            ( //House-Unit delivery can be performed without connecting road
            (fDemand[iD].Loc_Unit <> nil) and
            (gTerrain.Route_CanBeMade(fOffer[iO].Loc_House.PointBelowEntrance, fDemand[iD].Loc_Unit.CurrPosition, tpWalk, 1))
            ));
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
  Result := aSerf.CurrPosition;

  //If the serf is inside the house (invisible) test from point below
  if not aSerf.Visible then
    Result := KMPointBelow(Result);
end;


//Get the total number of possible deliveries with current Offers and Demands
function TKMDeliveries.GetAvailableDeliveriesCount: Integer;
var
  iD,iO: Integer;
  OffersTaken: Cardinal;
  DemandTaken: array of Boolean; //Each demand can only be taken once in our measurements
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psDelivery, gGame.GameTick);
  {$ENDIF}
  try
    SetLength(DemandTaken,fDemandCount+1);
    FillChar(DemandTaken[0], SizeOf(Boolean)*(fDemandCount+1), #0);

    Result := 0;
    for iO := 1 to fOfferCount do
      if (fOffer[iO].Ware <> wtNone) then
      begin
        OffersTaken := 0;
        for iD := 1 to fDemandCount do
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
function TKMDeliveries.TryCalcSerfBidValue(aSerf: TKMUnitSerf; aOfferPos: TKMPoint; aToUID: Integer; var aSerfBidValue: Single): Boolean;
  {$IFDEF USE_HASH}
var
  BidKey: TKMDeliveryBidKey;
  CachedBid: Single;
  {$ENDIF}
begin
  aSerfBidValue := 0;
  Result := True;
  if aSerf = nil then Exit;

  {$IFDEF USE_HASH}
  if CACHE_DELIVERY_BIDS then
  begin
    BidKey.FromUID := aSerf.UID;
    BidKey.ToUID := aToUID;

    if fSerfToOfferCache.TryGetValue(BidKey, CachedBid) then
    begin
      aSerfBidValue := aSerfBidValue + CachedBid;
      Result := (aSerfBidValue <> NOT_REACHABLE_DEST_VALUE);
      Exit;
    end;
  end;
  {$ENDIF}

  //Also prefer deliveries near to the serf
  if aSerf <> nil then
    //Serf gets to first house with tpWalkRoad, if not possible, then with tpWalk
    Result := TryCalcRouteCost(GetSerfActualPos(aSerf), aOfferPos, tpWalkRoad, aSerfBidValue, tpWalk);

  {$IFDEF USE_HASH}
  if CACHE_DELIVERY_BIDS then
    fSerfToOfferCache.Add(BidKey, aSerfBidValue);
  {$ENDIF}
end;


function TKMDeliveries.GetUnitsCntOnPath(aNodeList: TKMPointList): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to aNodeList.Count - 1 do
    Inc(Result, Byte(gTerrain.Land[aNodeList[I].Y,aNodeList[I].X].IsUnit <> nil));
end;


//Try to Calc route cost
//If destination is not reachable, then return False
function TKMDeliveries.TryCalcRouteCost(aFromPos, aToPos: TKMPoint; aMainPass: TKMTerrainPassability; var aRoutCost: Single;
                                        aSecondPass: TKMTerrainPassability = tpUnused): Boolean;
var
  Distance: Single;
  PassToUse: TKMTerrainPassability;
begin
  PassToUse := aMainPass;
  Result := True;
  if not gTerrain.Route_CanBeMade(aFromPos, aToPos, PassToUse, 0) then
  begin
    PassToUse := aSecondPass;
    Result := gTerrain.Route_CanBeMade(aFromPos, aToPos, PassToUse, 0);
  end;

  Distance := KMLength(aFromPos, aToPos);
  if DELIVERY_BID_CALC_USE_PATHFINDING and (Distance < BID_CALC_MAX_DIST_FOR_PATHF) then
  begin
    fNodeList.Clear;

    //Try to make the route to get delivery cost
    if Result
      and gGame.Pathfinding.Route_Make(aFromPos, aToPos, [PassToUse], 1, nil, fNodeList) then
      aRoutCost := KMPathLength(fNodeList) * BID_CALC_PATHF_COMPENSATION //to equalize routes with Pathfinding and without
                + GetUnitsCntOnPath(fNodeList) // units on path are also considered
    else
      Result := False;
  end
  else
    //Basic Bid is length of route
    if Result then
      aRoutCost := KMLengthDiag(aFromPos, aToPos); //Use KMLengthDiag, as it closer to what distance serf will actually cove

  if not Result then
    aRoutCost := NOT_REACHABLE_DEST_VALUE; //Not reachable destination
end;


function TKMDeliveries.TryCalculateBidBasic(iO, iD: Integer; var aBidBasicValue: Single; aSerf: TKMUnitSerf = nil;
                                            aAllowOffroad: Boolean = False): Boolean;
begin
  Result := TryCalculateBidBasic(fOffer[iO].Loc_House.UID, fOffer[iO].Loc_House.PointBelowEntrance, fOffer[iO].Count,
                                 fOffer[iO].Loc_House.HouseType, fOffer[iO].Loc_House.Owner, iD, aBidBasicValue, aSerf,
                                 aAllowOffroad);
end;


//Calc bid cost between offer object (house, serf) and demand object (house, unit - worker or warrior)
function TKMDeliveries.TryCalculateBidBasic(aOfferUID: Integer; aOfferPos: TKMPoint; aOfferCnt: Cardinal; aOfferHouseType: TKMHouseType;
                                            aOwner: TKMHandID; iD: Integer; var aBidBasicValue: Single;
                                            aSerf: TKMUnitSerf = nil; aAllowOffroad: Boolean = False): Boolean;

  {$IFDEF USE_HASH}
  procedure TryAddToCache(aBidKey: TKMDeliveryBidKey; aBidBasicV: Single);
  begin
    if CACHE_DELIVERY_BIDS then
      fOfferToDemandCache.Add(aBidKey, aBidBasicV);
  end;
  {$ENDIF}

var
  SerfBidValue: Single;
  SecondPass: TKMTerrainPassability;
  {$IFDEF USE_HASH}
  BidKey: TKMDeliveryBidKey;
  OfferToDemandCache: Single;
  {$ENDIF}
begin
  aBidBasicValue := NOT_REACHABLE_DEST_VALUE;
  Result := TryCalcSerfBidValue(aSerf, aOfferPos, aOfferUID, SerfBidValue);
  if not Result then
    Exit;

  {$IFDEF USE_HASH}
  if CACHE_DELIVERY_BIDS then
  begin
    BidKey.FromUID := aOfferUID;
    BidKey.ToUID := 0;
    if (fDemand[iD].Loc_House <> nil) then
      BidKey.ToUID := fDemand[iD].Loc_House.UID
    else if (fDemand[iD].Loc_Unit <> nil) then //Sometimes Loc_House and Loc_Unit could be nil for some reason (its a bug actually). Just add nil check here for now
      BidKey.ToUID := fDemand[iD].Loc_Unit.UID;

    if (BidKey.ToUID <> 0) and fOfferToDemandCache.TryGetValue(BidKey, OfferToDemandCache) then
    begin
      Result := (OfferToDemandCache <> NOT_REACHABLE_DEST_VALUE);
      if not Result then
        aBidBasicValue := NOT_REACHABLE_DEST_VALUE
      else
        aBidBasicValue := SerfBidValue + OfferToDemandCache;
      Exit;
    end;
  end;
  {$ENDIF}

  //For weapons production in cases with little resources available, they should be distributed
  //evenly between places rather than caring about route length.
  //This means weapon and armour smiths should get same amount of iron, even if one is closer to the smelter.
  if (fDemand[iD].Loc_House <> nil) and fDemand[iD].Loc_House.IsComplete
    and gRes.Houses[fDemand[iD].Loc_House.HouseType].DoesOrders
    and (aOfferCnt <= 3) //Little resources to share around
    and (fDemand[iD].Loc_House.CheckResIn(fDemand[iD].Ware) <= 2) then //Few resources already delivered
    aBidBasicValue := 7
    //Resource ratios are also considered
    + KaMRandom(65 - 13*gHands[aOwner].Stats.WareDistribution[fDemand[iD].Ware, fDemand[iD].Loc_House.HouseType],
                'TKMDeliveries.TryCalculateBidBasic')
  else
  begin
    //For all other cases - use distance approach. Direct length (rough) or pathfinding (exact)
    if fDemand[iD].Loc_House <> nil then
    begin
      SecondPass := tpUnused;
      if aAllowOffroad then
        SecondPass := tpWalk;
      //Calc cost between offer and demand houses
      Result := TryCalcRouteCost(aOfferPos, fDemand[iD].Loc_House.PointBelowEntrance, tpWalkRoad, aBidBasicValue, SecondPass);
      aBidBasicValue := aBidBasicValue
        //Resource ratios are also considered
        + KaMRandom(16 - 3*gHands[aOwner].Stats.WareDistribution[fDemand[iD].Ware, fDemand[iD].Loc_House.HouseType],
                    'TKMDeliveries.TryCalculateBidBasic 2');
    end
    else
      //Calc bid cost between offer house and demand Unit (digged worker or hungry warrior)
      Result := TryCalcRouteCost(aOfferPos, fDemand[iD].Loc_Unit.CurrPosition, tpWalk, aBidBasicValue);

    if not Result then
    begin
      aBidBasicValue := NOT_REACHABLE_DEST_VALUE;
      {$IFDEF USE_HASH}
      TryAddToCache(BidKey, aBidBasicValue);
      {$ENDIF}
      Exit; //Add to cache NOT_REACHABLE_DEST_VALUE value
    end;
  end;

  //Deliver wood first to equal distance construction sites
  if (fDemand[iD].Loc_House <> nil)
    and not fDemand[iD].Loc_House.IsComplete then
  begin
    //Give priority to almost built houses
    aBidBasicValue := aBidBasicValue - 4*fDemand[iD].Loc_House.GetBuildResDeliveredPercent;
    //Only add a small amount so houses at different distances will be prioritized separately
    if (fDemand[iD].Ware = wtStone) then
      aBidBasicValue := aBidBasicValue + 0.1;
  end
  else
    //For all other deliveries, add some random element so in the case of identical
    //bids the same resource will not always be chosen (e.g. weapons storehouse->barracks
    //should take random weapon types not sequentially)
    aBidBasicValue := aBidBasicValue + KaMRandom(10, 'TKMDeliveries.TryCalculateBidBasic 3');

  if (fDemand[iD].Ware = wtAll)        // Always prefer deliveries House>House instead of House>Store
    or ((aOfferHouseType = htStore)    // Prefer taking wares from House rather than Store...
    and (fDemand[iD].Ware <> wtWarfare)) then //...except weapons Store>Barracks, that is also prefered
    aBidBasicValue := aBidBasicValue + 1000;

  {$IFDEF USE_HASH}
  TryAddToCache(BidKey, aBidBasicValue);
  {$ENDIF}

  aBidBasicValue := aBidBasicValue + SerfBidValue;
end;


function TKMDeliveries.TryCalculateBid(iO, iD: Integer; var aBidValue: Single; aSerf: TKMUnitSerf = nil): Boolean;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psDelivery, gGame.GameTick);
  {$ENDIF}
  try
    Result := TryCalculateBidBasic(iO, iD, aBidValue, aSerf);

    if not Result then
      Exit;

    //Modifications for bidding system
    if (fDemand[iD].Loc_House <> nil) //Prefer delivering to houses with fewer supply
      and (fDemand[iD].Ware <> wtAll)
      and (fDemand[iD].Ware <> wtWarfare) //Except Barracks and Store, where supply doesn't matter or matter less
      and (fDemand[iD].Loc_House.HouseType <> htTownHall) then //Except TownHall as well, where supply doesn't matter or matter less
      aBidValue := aBidValue + 20 * fDemand[iD].Loc_House.CheckResIn(fDemand[iD].Ware);

    if (fDemand[iD].Loc_House <> nil)
      and (fDemand[iD].Loc_House.HouseType = htTownHall) then
    begin
      //Delivering gold to TH - if there are already more then 500 gold, then make this delivery very low priority
      if (fDemand[iD].Loc_House.CheckResIn(fOffer[iO].Ware) > 500) then
        aBidValue := aBidValue + 5000
      else
        aBidValue := aBidValue + 2; //Add small value, so it will not have so big advantage above other houses
    end;

    //Delivering weapons from store to barracks, make it lowest priority when there are >50 of that weapon in the barracks.
    //In some missions the storehouse has vast amounts of weapons, and we don't want the serfs to spend the whole game moving these.
    //In KaM, if the barracks has >200 weapons the serfs will stop delivering from the storehouse. I think our solution is better.
    if (fDemand[iD].Loc_House <> nil)
      and (fDemand[iD].Loc_House.HouseType = htBarracks)
      and (fOffer[iO].Loc_House.HouseType = htStore)
      and (fDemand[iD].Loc_House.CheckResIn(fOffer[iO].Ware) > 50) then
      aBidValue := aBidValue + 10000;

    //When delivering food to warriors, add a random amount to bid to ensure that a variety of food is taken. Also prefer food which is more abundant.
    if (fDemand[iD].Loc_Unit <> nil) and (fDemand[iD].Ware = wtFood) then
    begin
      //The more resource there is, the smaller Random can be. >100 we no longer care, it's just random 5.
      if fOffer[iO].Count = 0 then
        aBidValue := aBidValue + KaMRandom(5 + 150, 'TKMDeliveries.TryCalculateBidBasic 4')
      else
        aBidValue := aBidValue + KaMRandom(5 + (100 div fOffer[iO].Count), 'TKMDeliveries.TryCalculateBidBasic 5');
    end;
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psDelivery);
    {$ENDIF}
  end;
end;


procedure TKMDeliveries.CheckForBetterDemand(aDeliveryID: Integer; out aToHouse: TKMHouse; out aToUnit: TKMUnit; aSerf: TKMUnitSerf);
var
  iD, iO, BestD, OldD: Integer;
  Bid, BestBid: Single;
  BestImportance: TKMDemandImportance;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psDelivery, gGame.GameTick);
  {$ENDIF}
  try
    iO := fQueue[aDeliveryID].OfferID;
    OldD := fQueue[aDeliveryID].DemandID;

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
    if fDemand[OldD].Loc_Unit <> nil then
    begin
      aToHouse := fDemand[OldD].Loc_House;
      aToUnit := fDemand[OldD].Loc_Unit;
      Exit;
    end;

    //By default we keep the old demand, so that's our starting bid
    BestD := OldD;
    if not fDemand[OldD].IsDeleted then
    begin
      TryCalculateBid(iO, OldD, BestBid, aSerf);
      BestImportance := fDemand[OldD].Importance;
    end
    else
    begin
      //Our old demand is no longer valid (e.g. house destroyed), so give it minimum weight
      //If no other demands are found we can still return this invalid one, TaskDelivery handles that
      BestBid := MaxSingle;
      BestImportance := Low(TKMDemandImportance);
    end;

    for iD := 1 to fDemandCount do
      if (fDemand[iD].Ware <> wtNone)
      and (OldD <> Id)
      and (fDemand[iD].Importance >= BestImportance) //Skip any less important than the best we found
      and ValidDelivery(iO, iD, True)
      and TryCalculateBid(iO, iD, Bid, aSerf)
      and ((Bid < BestBid) or (fDemand[iD].Importance > BestImportance)) then
      begin
        BestD := iD;
        BestBid := Bid;
        BestImportance := fDemand[iD].Importance;
      end;

    //Did we switch jobs?
    if BestD <> OldD then
    begin
      //Remove old demand
      Dec(fDemand[OldD].BeingPerformed);
      if (fDemand[OldD].BeingPerformed = 0) and fDemand[OldD].IsDeleted then
        CloseDemand(OldD);

      UpdateDemandItem(OldD);

      //Take new demand
      fQueue[aDeliveryID].DemandID := BestD;
      Inc(fDemand[BestD].BeingPerformed); //Places a virtual "Reserved" sign on Demand

      UpdateDemandItem(BestD);
    end;
    //Return chosen unit and house
    aToHouse := fDemand[BestD].Loc_House;
    aToUnit := fDemand[BestD].Loc_Unit;
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
              ((fDemand[iD].Ware = wtFood) and (aResource in [wtBread, wtSausages, wtWine, wtFish]));

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
    iD, OldDemandId: Integer;
    Bid, BestBid: Single;
    BestImportance: TKMDemandImportance;
    DeliverToUnit: Boolean;
  begin
    Result := -1;
    aForceDelivery := False;
    OldDemandId := fQueue[aDeliveryId].DemandID;
    BestImportance := Low(TKMDemandImportance);
    BestBid := MaxSingle;
    DeliverToUnit := fDemand[OldDemandId].Loc_Unit <> nil;
    //Mark that delivery as IsFromUnit (Serf), since we are looking for other destination while in delivery process
    fQueue[aDeliveryId].IsFromUnit := True;
    //Try to find house or unit demand first (not storage)
    for iD := 1 to fDemandCount do
      if (fDemand[iD].Ware <> wtNone)
        and (iD <> OldDemandId)
        and not fDemand[iD].IsDeleted
        and (fDemand[iD].Importance >= BestImportance)
        and ValidBestDemand(iD, OldDemandId)
        and TryCalculateBidBasic(aSerf.UID, aSerf.CurrPosition, 1, htNone, aSerf.Owner, iD, Bid, nil,
                                 DeliverToUnit or fQueue[aDeliveryId].IsFromUnit)
        and ((Bid < BestBid) or (fDemand[iD].Importance > BestImportance)) then //Calc bid to find the best demand
      begin
        Result := iD;
        BestBid := Bid;
        BestImportance := fDemand[iD].Importance;
      end;

    // If nothing was found, then try to deliver to open for delivery Storage
    if Result = -1 then
      for iD := 1 to fDemandCount do
        if (fDemand[iD].Ware = wtAll)
          and (iD <> OldDemandId)
          and not fDemand[iD].IsDeleted
          and (fDemand[iD].Loc_House.DeliveryMode = dmDelivery)
          and (fDemand[iD].Loc_House is TKMHouseStore)
          and not TKMHouseStore(fDemand[iD].Loc_House).NotAcceptFlag[aResource]
          and TryCalculateBidBasic(aSerf.UID, aSerf.CurrPosition, 1, htNone, aSerf.Owner, iD, Bid, nil,
                                   DeliverToUnit or fQueue[aDeliveryId].IsFromUnit) //Choose the closest storage
          and (Bid < BestBid) then
        begin
          Result := iD;
          BestBid := Bid;
        end;

    // If no open storage for delivery found, then try to find any storage or any barracks
    if Result = -1 then
      for iD := 1 to fDemandCount do
        if (fDemand[iD].Ware = wtAll)
          and not fDemand[iD].IsDeleted
          and not fDemand[iD].Loc_House.IsDestroyed //choose between all storages, including current delivery. But not destroyed
          and TryCalculateBidBasic(aSerf.UID, aSerf.CurrPosition, 1, htNone, aSerf.Owner, iD, Bid, nil,
                                   DeliverToUnit or fQueue[aDeliveryId].IsFromUnit) //Choose the closest storage
          and (Bid < BestBid) then
        begin
          Result := iD;
          BestBid := Bid;
          aForceDelivery := True;
        end;
  end;
var
  BestDemandId, OldDemandId: Integer; // Keep Int to assign to Delivery down below
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psDelivery, gGame.GameTick);
  {$ENDIF}
  try
    OldDemandId := fQueue[aDeliveryId].DemandID;
    BestDemandId := FindBestDemandId();

    // Did we find anything?
    if BestDemandId = -1 then
    begin
      // Remove old demand
      Dec(fDemand[OldDemandId].BeingPerformed);
      if (fDemand[OldDemandId].BeingPerformed = 0) and fDemand[OldDemandId].IsDeleted then
        CloseDemand(OldDemandId);

      UpdateDemandItem(OldDemandId);

      // Delivery should be cancelled now
      CloseDelivery(aDeliveryId);
      aToHouse := nil;
      aToUnit := nil;
    end
    else
    begin
      // Did we switch jobs?
      if BestDemandId <> OldDemandId then
      begin
        // Remove old demand
        Dec(fDemand[OldDemandId].BeingPerformed);
        if (fDemand[OldDemandId].BeingPerformed = 0) and fDemand[OldDemandId].IsDeleted then
          CloseDemand(OldDemandId);

        UpdateDemandItem(OldDemandId);

        // Take new demand
        fQueue[aDeliveryId].DemandId := BestDemandId;
        Inc(fDemand[BestDemandId].BeingPerformed); //Places a virtual "Reserved" sign on Demand
        fQueue[aDeliveryId].IsFromUnit := True; //Now this delivery will always start from serfs hands

        UpdateDemandItem(BestDemandId);
        UpdateQueueItem(aDeliveryId);
      end;

      // Return chosen unit and house
      aToHouse := fDemand[BestDemandId].Loc_House;
      aToUnit := fDemand[BestDemandId].Loc_Unit;
    end;
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psDelivery);
    {$ENDIF}
  end;
end;

//Should issue a job based on requesters location and job importance
//Serf may ask for a job from within a house after completing previous delivery
function TKMDeliveries.AskForDelivery(aSerf: TKMUnitSerf; aHouse: TKMHouse = nil): Boolean;
var
  iQ, iD, iO, BestD, BestO, BestQ: Integer;
  Bid, BestBid: Single;
  BestImportance: TKMDemandImportance;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psDelivery, gGame.GameTick);
  {$ENDIF}
  try
    //Find Offer matching Demand
    //TravelRoute Asker>Offer>Demand should be shortest
    BestBid := MaxSingle;
    BestO := -1;
    BestD := -1;
    BestImportance := Low(TKMDemandImportance);
    Result := False;

    for iD := 1 to fDemandCount do
      if (fDemand[iD].Ware <> wtNone)
        and (fDemand[iD].Importance >= BestImportance) then //Skip any less important than the best we found
        for iO := 1 to fOfferCount do
          if ((aHouse = nil) or (fOffer[iO].Loc_House = aHouse))  //Make sure from house is the one requested
            and (fOffer[iO].Ware <> wtNone)
            and PermitDelivery(iO, iD, aSerf)
            and TryCalculateBid(iO, iD, Bid, aSerf)
            and ((Bid < BestBid) or (fDemand[iD].Importance > BestImportance)) then
          begin
            BestO := iO;
            BestD := iD;
            BestBid := Bid;
            BestImportance := fDemand[iD].Importance;
          end;

    if (BestO <> -1) and (BestD <> -1) then
    begin
      AssignDelivery(BestO, BestD, aSerf);
      Result := True;
    end else
      //Try to find ongoing delivery task from specified house and took it from serf, which is on the way to that house
      if aHouse <> nil then
      begin
        BestBid := MaxSingle;
        BestQ := -1;
        BestImportance := Low(TKMDemandImportance);
        for iQ := 1 to fQueueCount do
          if (fQueue[iQ].JobStatus = jsTaken)
            and (fOffer[fQueue[iQ].OfferID].Loc_House = aHouse)
            and (fQueue[iQ].Serf <> nil)                                                //Should be always true
            and (fQueue[iQ].Serf.Task is TKMTaskDeliver)                            //Should be always true
            and (TKMTaskDeliver(fQueue[iQ].Serf.Task).DeliverStage = dsToFromHouse) //Should be always true
            and TryCalculateBid(fQueue[iQ].OfferID, fQueue[iQ].DemandID, Bid, aSerf)
            and ((Bid < BestBid) or (fDemand[fQueue[iQ].DemandID].Importance > BestImportance)) then
          begin
            BestQ := iQ;
            BestBid := Bid;
            BestImportance := fDemand[fQueue[iQ].DemandID].Importance;
          end;
        if (BestQ <> -1) then
        begin
          ReAssignDelivery(BestQ, aSerf);
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
  Assert(iQ <= fQueueCount, 'iQ < fQueueCount');
  Assert(fQueue[iQ].JobStatus = jsTaken);

  if gLog.CanLogDelivery() then
    gLog.LogDelivery(Format('Hand [%d] - Reassign delivery ID %d from serf ID: %d to serf ID: %d', [fOwner, iQ, fQueue[iQ].Serf.UID, aSerf.UID]));

  fQueue[iQ].Serf.DelegateDelivery(aSerf);

  gHands.CleanUpUnitPointer(TKMUnit(fQueue[iQ].Serf));
  fQueue[iQ].Serf := TKMUnitSerf(aSerf.GetUnitPointer);
  UpdateQueueItem(iQ);
end;


procedure TKMDeliveries.AssignDelivery(iO,iD: Integer; aSerf: TKMUnitSerf);
var
  I: Integer;
begin
  //Find a place where Delivery will be written to after Offer-Demand pair is found
  I := 1;
  while (I <= fQueueCount) and (fQueue[I].JobStatus <> jsEmpty) do
    Inc(I);

  if I > fQueueCount then
  begin
    Inc(fQueueCount, LENGTH_INC);
    SetLength(fQueue, fQueueCount + 1);
  end;

  fQueue[I].DemandID := iD;
  fQueue[I].OfferID := iO;
  fQueue[I].JobStatus := jsTaken;
  fQueue[I].Serf := TKMUnitSerf(aSerf.GetUnitPointer);
  fQueue[I].Item := nil;

  UpdateQueueItem(I);

  Inc(fOffer[iO].BeingPerformed); //Places a virtual "Reserved" sign on Offer
  Inc(fDemand[iD].BeingPerformed); //Places a virtual "Reserved" sign on Demand
  UpdateOfferItem(iO);
  UpdateDemandItem(iD);

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
  fQueue[aID].OfferID := 0; //We don't need it any more

  Dec(fOffer[iO].BeingPerformed); //Remove reservation
  Dec(fOffer[iO].Count); //Remove resource from Offer list

  if fOffer[iO].Count = 0 then
    if fOffer[iO].BeingPerformed > 0 then
      fOffer[iO].IsDeleted := True
    else
      CloseOffer(iO);

  UpdateQueueItem(aID);
  UpdateOfferItem(iO);
end;


//Resource has been delivered to Demand
procedure TKMDeliveries.GaveDemand(aID: Integer);
var
  iD: Integer;
begin
  gLog.LogDelivery('Gave demand from delivery ID ' + IntToStr(aID));
  iD := fQueue[aID].DemandID;
  fQueue[aID].DemandID := 0; //We don't need it any more

  Dec(fDemand[iD].BeingPerformed); //Remove reservation

  fDemand[iD].NotifyLocHouseOnClose := False; //No need to notify Loc_House since we already delivered item

  if (fDemand[iD].DemandType = dtOnce)
    or (fDemand[iD].IsDeleted and (fDemand[iD].BeingPerformed = 0)) then
    CloseDemand(iD); //Remove resource from Demand list
  UpdateDemandItem(iD);
end;


//AbandonDelivery
procedure TKMDeliveries.AbandonDelivery(aID: Integer);
begin
  gLog.LogDelivery('Abandoned delivery ID ' + IntToStr(aID));
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psDelivery, gGame.GameTick);
  {$ENDIF}
  try
    //Remove reservations without removing items from lists
    if fQueue[aID].OfferID <> 0 then
    begin
      Dec(fOffer[fQueue[aID].OfferID].BeingPerformed);
      //Now see if we need to delete the Offer as we are the last remaining pointer
      if fOffer[fQueue[aID].OfferID].IsDeleted and (fOffer[fQueue[aID].OfferID].BeingPerformed = 0) then
        CloseOffer(fQueue[aID].OfferID);

      UpdateOfferItem(fQueue[aID].OfferID);
    end;

    if fQueue[aID].DemandID <> 0 then
    begin
      Dec(fDemand[fQueue[aID].DemandID].BeingPerformed);
      if fDemand[fQueue[aID].DemandID].IsDeleted and (fDemand[fQueue[aID].DemandID].BeingPerformed = 0) then
        CloseDemand(fQueue[aID].DemandID);

      UpdateDemandItem(fQueue[aID].DemandID);
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

  fQueue[aID].OfferID := 0;
  fQueue[aID].DemandID := 0;
  fQueue[aID].JobStatus := jsEmpty; //Open slot
  gHands.CleanUpUnitPointer(TKMUnit(fQueue[aID].Serf));

  if Assigned(fQueue[aID].Item) then
    fQueue[aID].Item.Delete;

  fQueue[aID].Item := nil; //Set to nil, as sometimes Item is not nil even after Delete
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

  if Assigned(fDemand[aID].Item) then
    fDemand[aID].Item.Delete;

  fDemand[aID].Item := nil; //Set to nil, as sometimes Item is not nil even after Delete
end;


procedure TKMDeliveries.CloseOffer(aID: Integer);
begin
  Assert(fOffer[aID].BeingPerformed = 0);
  fOffer[aID].IsDeleted := false;
  fOffer[aID].Ware := wtNone;
  fOffer[aID].Count := 0;
  gHands.CleanUpHousePointer(fOffer[aID].Loc_House);

  if Assigned(fOffer[aID].Item) then
    fOffer[aID].Item.Delete;

  fOffer[aID].Item := nil; //Set to nil, as sometimes Item is not nil even after Delete
end;


procedure TKMDeliveries.Save(SaveStream: TKMemoryStream);
var
  I: Integer;
  {$IFDEF USE_HASH}
  CacheKeyArray : TArray<TKMDeliveryBidKey>;
  Key: TKMDeliveryBidKey;
  Comparer: TKMDeliveryBidKeyComparer;
  {$ENDIF}
begin
  SaveStream.PlaceMarker('Deliveries');
  SaveStream.Write(fOwner);
  SaveStream.Write(fOfferCount);

  SaveStream.PlaceMarker('Offers');
  for I := 1 to fOfferCount do
  begin
    SaveStream.Write(fOffer[I].Ware, SizeOf(fOffer[I].Ware));
    SaveStream.Write(fOffer[I].Count);
    if fOffer[I].Loc_House <> nil then
      SaveStream.Write(fOffer[I].Loc_House.UID)
    else
      SaveStream.Write(Integer(0));
    SaveStream.Write(fOffer[I].BeingPerformed);
    SaveStream.Write(fOffer[I].IsDeleted);
  end;

  SaveStream.PlaceMarker('Demands');
  SaveStream.Write(fDemandCount);
  for I := 1 to fDemandCount do
  with fDemand[I] do
  begin
    SaveStream.Write(Ware, SizeOf(Ware));
    SaveStream.Write(DemandType, SizeOf(DemandType));
    SaveStream.Write(Importance, SizeOf(Importance));
    if Loc_House <> nil then SaveStream.Write(Loc_House.UID) else SaveStream.Write(Integer(0));
    if Loc_Unit  <> nil then SaveStream.Write(Loc_Unit.UID ) else SaveStream.Write(Integer(0));
    SaveStream.Write(BeingPerformed);
    SaveStream.Write(IsDeleted);
    SaveStream.Write(NotifyLocHouseOnClose);
  end;

  SaveStream.PlaceMarker('Queue');
  SaveStream.Write(fQueueCount);
  for I := 1 to fQueueCount do
  begin
    SaveStream.Write(fQueue[I].IsFromUnit);
    SaveStream.Write(fQueue[I].OfferID);
    SaveStream.Write(fQueue[I].DemandID);
    SaveStream.Write(fQueue[I].JobStatus, SizeOf(fQueue[I].JobStatus));
    if fQueue[I].Serf  <> nil then SaveStream.Write(fQueue[I].Serf.UID ) else SaveStream.Write(Integer(0));
  end;

  {$IFDEF USE_HASH}
  if CACHE_DELIVERY_BIDS then
  begin
    SaveStream.PlaceMarker('OfferToDemandCache');
    SaveStream.Write(fOfferToDemandCache.Count);

    Comparer := nil; //RESET to nil. Obligatory!

    if (fOfferToDemandCache.Count > 0) or (fSerfToOfferCache.Count > 0) then
      Comparer := TKMDeliveryBidKeyComparer.Create;

    if fOfferToDemandCache.Count > 0 then
    begin
      CacheKeyArray := fOfferToDemandCache.Keys.ToArray;
      TArray.Sort<TKMDeliveryBidKey>(CacheKeyArray, Comparer);

      for Key in CacheKeyArray do
      begin
        SaveStream.Write(Key.FromUID);
        SaveStream.Write(Key.ToUID);
        SaveStream.Write(fOfferToDemandCache.Items[Key]);
      end;
    end;

    SaveStream.PlaceMarker('SerfToOfferCache');
    SaveStream.Write(fSerfToOfferCache.Count);

    if fSerfToOfferCache.Count > 0 then
    begin
      CacheKeyArray := fSerfToOfferCache.Keys.ToArray;
      TArray.Sort<TKMDeliveryBidKey>(CacheKeyArray, Comparer);

      for Key in CacheKeyArray do
      begin
        SaveStream.Write(Key.FromUID);
        SaveStream.Write(Key.ToUID);
        SaveStream.Write(fSerfToOfferCache.Items[Key]);
      end;
    end;

    if Comparer <> nil then
      Comparer.Free;
  end;
  {$ENDIF}
end;


procedure TKMDeliveries.Load(LoadStream: TKMemoryStream);
var
  I: Integer;
  {$IFDEF USE_HASH}
  Count: Integer;
  Key: TKMDeliveryBidKey;
  Value: Single;
  {$ENDIF}
begin
  LoadStream.CheckMarker('Deliveries');
  LoadStream.Read(fOwner);
  LoadStream.Read(fOfferCount);
  SetLength(fOffer, fOfferCount+1);

  LoadStream.CheckMarker('Offers');
  for I := 1 to fOfferCount do
  begin
    LoadStream.Read(fOffer[I].Ware, SizeOf(fOffer[I].Ware));
    LoadStream.Read(fOffer[I].Count);
    LoadStream.Read(fOffer[I].Loc_House, 4);
    LoadStream.Read(fOffer[I].BeingPerformed);
    LoadStream.Read(fOffer[I].IsDeleted);
  end;

  LoadStream.CheckMarker('Demands');
  LoadStream.Read(fDemandCount);
  SetLength(fDemand, fDemandCount+1);
  for I := 1 to fDemandCount do
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
  SetLength(fQueue, fQueueCount+1);
  for I := 1 to fQueueCount do
  begin
    LoadStream.Read(fQueue[I].IsFromUnit);
    LoadStream.Read(fQueue[I].OfferID);
    LoadStream.Read(fQueue[I].DemandID);
    LoadStream.Read(fQueue[I].JobStatus, SizeOf(fQueue[I].JobStatus));
    LoadStream.Read(fQueue[I].Serf, 4);
  end;

  {$IFDEF USE_HASH}
  if CACHE_DELIVERY_BIDS then
  begin
    LoadStream.CheckMarker('OfferToDemandCache');
    fOfferToDemandCache.Clear;
    LoadStream.Read(Count);
    for I := 0 to Count - 1 do
    begin
      LoadStream.Read(Key.FromUID);
      LoadStream.Read(Key.ToUID);
      LoadStream.Read(Value);
      fOfferToDemandCache.Add(Key, Value);
    end;

    LoadStream.CheckMarker('SerfToOfferCache');
    fSerfToOfferCache.Clear;
    LoadStream.Read(Count);
    for I := 0 to Count - 1 do
    begin
      LoadStream.Read(Key.FromUID);
      LoadStream.Read(Key.ToUID);
      LoadStream.Read(Value);
      fSerfToOfferCache.Add(Key, Value);
    end;
  end;
  {$ENDIF}
end;


procedure TKMDeliveries.SyncLoad;
var
  I: Integer;
begin
  for I := 1 to fOfferCount do
  begin
    fOffer[I].Loc_House := gHands.GetHouseByUID(Cardinal(fOffer[I].Loc_House));
    UpdateOfferItem(I);
  end;

  for I := 1 to fDemandCount do
    with fDemand[I] do
    begin
      Loc_House := gHands.GetHouseByUID(Cardinal(Loc_House));
      Loc_Unit := gHands.GetUnitByUID(Cardinal(Loc_Unit));
      UpdateDemandItem(I);
    end;

  for I := 1 to fQueueCount do
  begin
    fQueue[I].Serf := TKMUnitSerf(gHands.GetUnitByUID(Cardinal(fQueue[I].Serf)));
    UpdateQueueItem(I);
  end;
end;


procedure TKMDeliveries.UpdateState(aTick: Cardinal);
begin
  {$IFDEF USE_HASH}
  //Clear cache every 10 ticks, spread cache clearing a by handIndex, to make route's calc's spread too
  if CACHE_DELIVERY_BIDS and (((aTick + fOwner) mod CACHE_CLEAN_FREQ) = 0) then
  begin
    fOfferToDemandCache.Clear;
    fSerfToOfferCache.Clear;
  end;
  {$ENDIF}
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
  for I := 1 to fDemandCount do
  if fDemand[I].Ware <> wtNone then
  begin
    tmpS := #9;
    if fDemand[I].Loc_House <> nil then tmpS := tmpS + gRes.Houses[fDemand[I].Loc_House.HouseType].HouseName + #9 + #9;
    if fDemand[I].Loc_Unit  <> nil then tmpS := tmpS + gRes.Units[fDemand[I].Loc_Unit.UnitType].GUIName + #9 + #9;
    tmpS := tmpS + gRes.Wares[fDemand[I].Ware].Title;
    if fDemand[I].Importance <> diNorm then
      tmpS := tmpS + '^';

    SL.Append(tmpS);
  end;

  SL.Append('Offer:');
  SL.Append('---------------------------------');
  for I := 1 to fOfferCount do
  if fOffer[I].Ware <> wtNone then
  begin
    tmpS := #9;
    if fOffer[I].Loc_House <> nil then tmpS := tmpS + gRes.Houses[fOffer[I].Loc_House.HouseType].HouseName + #9 + #9;
    tmpS := tmpS + gRes.Wares[fOffer[I].Ware].Title + #9;
    tmpS := tmpS + IntToStr(fOffer[I].Count);

    SL.Append(tmpS);
  end;

  SL.Append('Running deliveries:');
  SL.Append('---------------------------------');
  for I := 1 to fQueueCount do
  if fQueue[I].OfferID <> 0 then
  begin
    tmpS := 'id ' + IntToStr(I) + '.' + #9;
    tmpS := tmpS + gRes.Wares[fOffer[fQueue[I].OfferID].Ware].Title + #9;

    if fOffer[fQueue[I].OfferID].Loc_House = nil then
      tmpS := tmpS + 'Destroyed' + ' >>> '
    else
      tmpS := tmpS + gRes.Houses[fOffer[fQueue[I].OfferID].Loc_House.HouseType].HouseName + ' >>> ';

    if fDemand[fQueue[I].DemandID].Loc_House = nil then
      tmpS := tmpS + 'Destroyed'
    else
      tmpS := tmpS + gRes.Houses[fDemand[fQueue[I].DemandID].Loc_House.HouseType].HouseName;

    SL.Append(tmpS);
  end;

  SL.SaveToFile(aFileName);
  SL.Free;
end;


{$IFDEF USE_HASH}
{ TKMDeliveryBidKeyComparer }
function TKMDeliveryBidKeyEqualityComparer.Equals(const Left, Right: TKMDeliveryBidKey): Boolean;
begin
  Result := (Left.FromUID = Right.FromUID) and (Left.ToUID = Right.ToUID);
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


function TKMDeliveryBidKeyEqualityComparer.GetHashCode(const Value: TKMDeliveryBidKey): Integer;
begin
  Result := CombinedHash([THashBobJenkins.GetHashValue(Value.FromUID, SizeOf(Integer), 0),
                          THashBobJenkins.GetHashValue(Value.ToUID, SizeOf(Integer), 0)]);
end;


function TKMDeliveryBidKeyComparer.Compare(const Left, Right: TKMDeliveryBidKey): Integer;
begin
  if Left.FromUID = Right.FromUID then
    Result := Left.ToUID - Right.ToUID
  else
    Result := Left.FromUID - Right.FromUID;
end;


{$ENDIF}


end.
