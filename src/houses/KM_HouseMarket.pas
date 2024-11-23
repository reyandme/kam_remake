unit KM_HouseMarket;
{$I KaM_Remake.inc}
interface
uses
  KM_Houses,
  KM_CommonClasses, KM_Defaults,
  KM_ResTypes;

type
  //Marketplace
  TKMHouseMarket = class(TKMHouse)
  private
    fResFrom, fResTo: TKMWareType;
    fMarketWareIn: array [WARE_MIN..WARE_MAX] of Word;
    fMarketWareOut: array [WARE_MIN..WARE_MAX] of Word;
    // For some reason fMarketDeliveryCount is not the same as house / townhall delivery count
    // In the market we don't count actual wares on the market in the delivery count, but for other houses we do
    fMarketDeliveryCount: array [WARE_MIN..WARE_MAX] of Word;
    // Number of demands that were reqeusted to close. We don't klnow if they will succeed in closing or not
    // Closing could be cancelled, if serf is already entering the house of the demand
    fMarketDemandsClosing: array [WARE_MIN..WARE_MAX] of Word;
    fTradeAmount: Word;
    procedure AttemptExchange;
    procedure SetWareFrom(aWare: TKMWareType);
    procedure SetWareTo(aWare: TKMWareType);

    procedure SetWareInCnt(aWareType: TKMWareType; aValue: Word);
    procedure SetWareOutCnt(aWareType: TKMWareType; aValue: Word);

    function GetWareToTrade(aWare: TKMWareType): Word;
    procedure SetWareToTrade(aWare: TKMWareType; aCnt: Word);
    property WareToTrade[aWare: TKMWareType]: Word read GetWareToTrade write SetWareToTrade;

    function GetWareRequired: Integer;

    procedure MoveWareIn2Out(aWare: TKMWareType; aCnt: Integer);
    function MoveWareOut2In(aWare: TKMWareType; aCnt: Integer): Integer;
  protected
    function GetWareOrder(aId: Byte): Integer; override;
    procedure SetWareOrder(aId: Byte; aValue: Integer); override;
    procedure CheckTakeOutDeliveryMode; override;

    function TryDecWareDelivery(aWare: TKMWareType; aDeleteCanceled: Boolean): Boolean; override;
  public
    constructor Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
    constructor Load(LoadStream: TKMemoryStream); override;

    procedure Demolish(aFrom: TKMHandID; IsSilent: Boolean = False); override;
    property ResFrom: TKMWareType read fResFrom write SetWareFrom;
    property ResTo: TKMWareType read fResTo write SetWareTo;
    function RatioFrom: Byte;
    function RatioTo: Byte;

    function ShouldAbandonDeliveryFrom(aWareType: TKMWareType; aImmidiateCheck: Boolean = False): Boolean; override;
    function ShouldAbandonDeliveryTo(aWareType: TKMWareType): Boolean; override;

    function AllowedToTrade(aWare: TKMWareType): Boolean;
    function TradeInProgress: Boolean;
    function GetResTotal(aWare: TKMWareType): Word; overload;
    function CheckWareIn(aWare: TKMWareType): Word; override;
    function CheckWareOut(aWare: TKMWareType): Word; override;
    procedure WareAddToIn(aWare: TKMWareType; aCount: Integer = 1; aFromScript: Boolean = False); override;
    procedure WareTakeFromOut(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False); override;
    function WareCanAddToIn(aWare: TKMWareType): Boolean; override;
    function WareOutputAvailable(aWare: TKMWareType; const aCount: Word): Boolean; override;

    procedure UpdateDemands; override;

    procedure Save(SaveStream: TKMemoryStream); override;
    procedure Paint; override;

    function ObjToString(const aSeparator: String = '|'): String; override;
  end;


implementation
uses
  Math, SysUtils, TypInfo,
  KM_Entity,
  KM_RenderPool,
  KM_HandsCollection, KM_HandLogistics, KM_HandTypes, KM_HandEntity,
  KM_Resource, KM_ResSound, KM_ResWares,
  KM_ScriptingEvents, KM_Sound,
  KM_CommonUtils;

const
  //Maximum number of Demands we can place at once (stops the delivery queue from becoming clogged with 1500 items)
  MAX_RES_ORDERED = 10;


{ TKMHouseMarket }
constructor TKMHouseMarket.Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
begin
  inherited;

  fResFrom := wtNone;
  fResTo := wtNone;
end;


procedure TKMHouseMarket.Demolish(aFrom: TKMHandID; IsSilent: Boolean = False);
var
  WT: TKMWareType;
begin
  //Count resources as lost
  for WT := WARE_MIN to WARE_MAX do
    gHands[Owner].Stats.WareConsumed(WT, fMarketWareIn[WT] + fMarketWareOut[WT]);

  inherited;
end;


function TKMHouseMarket.GetResTotal(aWare: TKMWareType): Word;
begin
  Result := fMarketWareIn[aWare] + fMarketWareOut[aWare];
end;


function TKMHouseMarket.CheckWareIn(aWare: TKMWareType): Word;
begin
  Result := fMarketWareIn[aWare];
end;


function TKMHouseMarket.CheckWareOut(aWare: TKMWareType): Word;
begin
  Result := fMarketWareOut[aWare];
end;


function TKMHouseMarket.GetWareOrder(aID: Byte): Integer;
begin
  Result := fTradeAmount;
end;


function TKMHouseMarket.RatioFrom: Byte;
var
  costFrom, costTo: Single;
begin
  if (fResFrom <> wtNone) and (fResTo <> wtNone) then
  begin
    //When trading target ware is priced higher
    costFrom := gRes.Wares[fResFrom].MarketPrice;
    costTo := gRes.Wares[fResTo].MarketPrice * MARKET_TRADEOFF_FACTOR;
    Result := Round(costTo / Min(costFrom, costTo));
  end else
    Result := 1;
end;


function TKMHouseMarket.RatioTo: Byte;
var
  costFrom, costTo: Single;
begin
  if (fResFrom <> wtNone) and (fResTo <> wtNone) then
  begin
    //When trading target ware is priced higher
    costFrom := gRes.Wares[fResFrom].MarketPrice;
    costTo := gRes.Wares[fResTo].MarketPrice * MARKET_TRADEOFF_FACTOR;
    Result := Round(costFrom / Min(costFrom, costTo));
  end else
    Result := 1;
end;


function TKMHouseMarket.GetWareRequired: Integer;
begin
  // How many wares needed
  Result := fTradeAmount * RatioFrom          // According to trade ratio
            - WareToTrade[fResFrom]           // Except what we have already
            - fMarketDeliveryCount[fResFrom]  // Except already delivering
            + Max(0, fMarketDemandsClosing[fResFrom] - 1); // But except closing demands (-1 for the possible cancelled one, because of the entering serf)
end;


procedure TKMHouseMarket.WareAddToIn(aWare: TKMWareType; aCount: Integer = 1; aFromScript: Boolean = False);
var
  ordersAllowed, ordersToDo: Integer;
begin
  //If user cancelled the exchange (or began new one with different resources already)
  //then incoming resourced should be added to Offer list immediately
  //We don't want Marketplace to act like a Store
  if not aFromScript then
    Dec(fMarketDeliveryCount[aWare], aCount); //We must keep track of the number ordered, which is less now because this has arrived

  if (aWare = fResFrom) and TradeInProgress then
  begin
    SetWareInCnt(aWare, fMarketWareIn[aWare] + aCount); //Place the new resource in the IN list

    // As we only order 10 resources at one time, we might need to order another now to fill the gap made by the one delivered
    //
    // How many can we order
    // Consider number of deliveries
    // Except the deliveries, which are closing
    // But except 1 closing delivery which possibly could not be cancelled,
    // since serf is entering the house
    // There is only serf entering the house at any moment, so 1 is enough for this last exception
    ordersAllowed := MAX_RES_ORDERED
                     - fMarketDeliveryCount[fResFrom]               // Consider number of deliveries
                     + Max(0, fMarketDemandsClosing[fResFrom] - 1); // Except the deliveries, which are closing - possibly not closed one
                                                                    // But except 1 closing delivery which possibly could not be cancelled, since

    Assert(ordersAllowed >= 0); //We must never have ordered more than we are allowed

    ordersToDo := Min3(aCount, GetWareRequired, ordersAllowed);

    if ordersToDo > 0 then
    begin
      Inc(fMarketDeliveryCount[aWare], ordersToDo);
      gHands[Owner].Deliveries.Queue.AddDemand(Self, nil, fResFrom, ordersToDo, dtOnce, diNorm);
    end;
    AttemptExchange;
  end
  else
  begin
    SetWareOutCnt(aWare, fMarketWareOut[aWare] + aCount); //Place the new resource in the OUT list
    gHands[Owner].Deliveries.Queue.AddOffer(Self, aWare, aCount);
  end;
end;


function TKMHouseMarket.WareCanAddToIn(aWare: TKMWareType): Boolean;
begin
  Result := (aWare in [WARE_MIN..WARE_MAX]);
end;


function TKMHouseMarket.WareOutputAvailable(aWare: TKMWareType; const aCount: Word): Boolean;
begin
  Assert(aWare in [WARE_MIN..WARE_MAX]);
  Result := (fMarketWareOut[aWare] >= aCount);
end;


procedure TKMHouseMarket.AttemptExchange;
var
  tradeCount: Integer;
begin
  Assert((fResFrom <> wtNone) and (fResTo <> wtNone) and (fResFrom <> fResTo));

  //Script might have blocked these resources from trading, if so reset trade order
  if TradeInProgress
  and (not AllowedToTrade(fResFrom) or not AllowedToTrade(fResTo)) then
  begin
    SetWareOrder(0, 0);
    Exit;
  end;

  if TradeInProgress and (WareToTrade[fResFrom] >= RatioFrom) then
  begin
    //How much can we trade
    tradeCount := Min((WareToTrade[fResFrom] div RatioFrom), fTradeAmount);

    WareToTrade[fResFrom] := WareToTrade[fResFrom] - tradeCount * RatioFrom;
    gHands[Owner].Stats.WareConsumed(fResFrom, tradeCount * RatioFrom);
    Dec(fTradeAmount, tradeCount);
    SetWareOutCnt(fResTo, fMarketWareOut[fResTo] + tradeCount * RatioTo);
    gHands[Owner].Stats.WareProduced(fResTo, tradeCount * RatioTo);
    gHands[Owner].Deliveries.Queue.AddOffer(Self, fResTo, tradeCount * RatioTo);

    gScriptEvents.EventMarketTrade(Self, fResFrom, fResTo);
    gScriptEvents.ProcWareProduced(Self, fResTo, tradeCount * RatioTo);
    gSoundPlayer.Play(sfxnTrade, fPosition);
  end;
end;


procedure TKMHouseMarket.WareTakeFromOut(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False);
begin
  if aFromScript then
  begin
    aCount := Min(aCount, fMarketWareOut[aWare]);
    if aCount > 0 then
    begin
      gHands[Owner].Stats.WareConsumed(aWare, aCount);
      gHands[Owner].Deliveries.Queue.RemOffer(Self, aWare, aCount);
    end;
  end;

  if aCount <= fMarketWareOut[aWare] then
    SetWareOutCnt(aWare, fMarketWareOut[aWare] - aCount)
  else if (DeliveryMode = dmTakeOut) and (aCount <= fMarketWareIn[aWare]) then
    SetWareInCnt(aWare, fMarketWareIn[aWare] - aCount)
  else
    raise Exception.Create(Format('No ware: [%s] count = %d to take from market UID = %d',
                                  [GetEnumName(TypeInfo(TKMWareType), Integer(aWare)), aCount, UID]));

end;


//Check if we allowed to deliver from Market
//
//Probably this method will be never invoked,
//since when we cancel trade all resources from IN are moved into OUT
//so it looks likewe have no chance to find anything to get in the IN wares, only when trade is going on
function TKMHouseMarket.ShouldAbandonDeliveryFrom(aWareType: TKMWareType; aImmidiateCheck: Boolean = False): Boolean;
begin
  Result := inherited and not ((GetDeliveryModeForCheck(aImmidiateCheck) = dmTakeOut)
                                and (fMarketWareIn[aWareType] >= 1));
end;


function TKMHouseMarket.ShouldAbandonDeliveryTo(aWareType: TKMWareType): Boolean;
begin
  Result := inherited or (fTradeAmount = 0) or (fResFrom <> aWareType); //Stop delivery to market when player set trade amount to 0
end;


function TKMHouseMarket.AllowedToTrade(aWare: TKMWareType): Boolean;
begin
  Result := gHands[Owner].Locks.AllowToTrade[aWare];
end;


procedure TKMHouseMarket.SetWareFrom(aWare: TKMWareType);
begin
  if TradeInProgress or not AllowedToTrade(aWare) then
    Exit;

  fResFrom := aWare;
  if fResTo = fResFrom then
    fResTo := wtNone;
end;


procedure TKMHouseMarket.SetWareTo(aWare: TKMWareType);
begin
  if TradeInProgress or not AllowedToTrade(aWare) then
    Exit;

  fResTo := aWare;
  if fResFrom = fResTo then
    fResFrom := wtNone;
end;


procedure TKMHouseMarket.SetWareInCnt(aWareType: TKMWareType; aValue: Word);
var
  cntChange: Integer;
begin
  Assert(aWareType in [WARE_MIN..WARE_MAX]);

  cntChange := aValue - fMarketWareIn[aWareType];

  fMarketWareIn[aWareType] := aValue;

  if cntChange <> 0 then
    gScriptEvents.ProcHouseWareCountChanged(Self, aWareType, WareToTrade[aWareType], cntChange);
end;


procedure TKMHouseMarket.SetWareOutCnt(aWareType: TKMWareType; aValue: Word);
var
  cntChange: Integer;
begin
  Assert(aWareType in [WARE_MIN..WARE_MAX]);

  cntChange := aValue - fMarketWareOut[aWareType];

  fMarketWareOut[aWareType] := aValue;

  if cntChange <> 0 then
    gScriptEvents.ProcHouseWareCountChanged(Self, aWareType, WareToTrade[aWareType], cntChange);
end;


function TKMHouseMarket.GetWareToTrade(aWare: TKMWareType): Word;
begin
  Result := fMarketWareIn[aWare] + fMarketWareOut[aWare];
end;


procedure TKMHouseMarket.SetWareToTrade(aWare: TKMWareType; aCnt: Word);
var
  curCnt, decFromIn, decFromOut: Word;
begin
  curCnt := GetWareToTrade(aWare);
  if aCnt > curCnt then
    SetWareInCnt(aWare, fMarketWareIn[aWare] + aCnt - curCnt)
  else
  if aCnt < curCnt then
  begin
    decFromIn := Min(fMarketWareIn[aWare], curCnt - aCnt);
    Dec(fMarketWareIn[aWare], decFromIn); //Dont call SetRes func, cause we don't need double script event calls
    decFromOut := curCnt - aCnt - decFromIn;
    Dec(fMarketWareOut[aWare], decFromOut); //Dont call SetRes func, cause we don't need double script event calls

    gScriptEvents.ProcHouseWareCountChanged(Self, aWare, WareToTrade[aWare], - decFromIn - decFromOut);
    gHands[Owner].Deliveries.Queue.RemOffer(Self, aWare, decFromOut);
  end;
end;


procedure TKMHouseMarket.MoveWareIn2Out(aWare: TKMWareType; aCnt: Integer);
begin
  aCnt := Min(aCnt, fMarketWareIn[aWare]);

  if aCnt <= 0 then Exit; // aCnt could be negative

  //No need to call SetRes functins here, since its just moving resource from In to Out
  Inc(fMarketWareOut[aWare], aCnt);

  // No need to add offer if market is already in TakeOut delivery mode
  if DeliveryMode <> dmTakeOut  then
    gHands[Owner].Deliveries.Queue.AddOffer(Self, aWare, aCnt); //Add res as offer, since they are in 'out' queue

  Dec(fMarketWareIn[aWare], aCnt);
end;


function TKMHouseMarket.MoveWareOut2In(aWare: TKMWareType; aCnt: Integer): Integer;
begin
  Result := Min(aCnt, fMarketWareOut[aWare]);

  if Result <= 0 then Exit; // aCnt could be negative

  //No need to call SetRes functins here, since its just moving resource from Out to In
  Dec(fMarketWareOut[aWare], Result);

  // Do not remove offer, if market is in TakeOut delivery mode
  // We still allow to take the ware out
  if DeliveryMode <> dmTakeOut  then
    gHands[Owner].Deliveries.Queue.RemOffer(Self, aWare, Result); //Remove offer, we moved wares to In
  Inc(fMarketWareIn[aWare], Result);
end;


function TKMHouseMarket.TradeInProgress: Boolean;
begin
  Result := fTradeAmount > 0;
end;


function TKMHouseMarket.TryDecWareDelivery(aWare: TKMWareType; aDeleteCanceled: Boolean): Boolean;
begin
  Assert(fMarketDemandsClosing[aWare] > 0);

  // Do not decrease DeliveryCount, if demand delete was cancelled (demand closing was not possible, f.e. when serf enters the house)
  // thus serf brought ware to the house and we should not decrease delivery count in that case here
  // (but it will be decreased anyway in the WareAddToIn for market)
  if not aDeleteCanceled then
    fMarketDeliveryCount[aWare] := Max(0, fMarketDeliveryCount[aWare] - 1);

  fMarketDemandsClosing[aWare] := Max(0, fMarketDemandsClosing[aWare] - 1);

  Result := True;
end;


procedure TKMHouseMarket.UpdateDemands;
var
  resRequired, ordersAllowed, ordersRemoved, orderToDo, movedOut2In, plannedToRemove: Integer;
begin
  if (fResFrom = wtNone) or (fResTo = wtNone) or (fResFrom = fResTo) then Exit;

  //@Lewin: If player has cancelled the exchange and then started it again resources will not be
  //removed from offers list and perhaps serf will carry them off the marketplace
  //@Krom: Yes. It would be better if the deliveries were abandoned and the resources were use in
  //the new trade. For example I might be trading stone to bread, then cancel and change from stone to wine.
  //I would expect any stone already at the marketplace to stay since the new trade requires it,
  //it looks bad that serfs remove the stone then take it back. To be converted to todo item.

  //How much do we need to ask to add to delivery system = Needed - (Ordered + Arrived)
  resRequired := GetWareRequired;

  if fTradeAmount <> 0 then
  begin
    movedOut2In := MoveWareOut2In(fResFrom, resRequired);
    if movedOut2In > 0 then
    begin
      //Remove demands, we took some of the wares from OUT queue
      ordersRemoved := gHands[Owner].Deliveries.Queue.TryRemoveDemand(Self, fResFrom, movedOut2In, plannedToRemove);
      Dec(fMarketDeliveryCount[fResFrom], ordersRemoved);
      Inc(fMarketDemandsClosing[fResFrom], plannedToRemove);
    end;
  end;

  // How many can we order
  // Consider number of deliveries
  // Except the deliveries, which are closing
  // But except 1 closing delivery which possibly could not be cancelled,
  // since serf is entering the house
  // There is only serf entering the house at any moment, so 1 is enough for this last exception
  ordersAllowed :=  MAX_RES_ORDERED
                    - fMarketDeliveryCount[fResFrom]                // Consider number of deliveries
                    + Max(fMarketDemandsClosing[fResFrom] - 1, 0);  // Except the deliveries, which are closing - possibly not closed one
                                                                    // But except 1 closing delivery which possibly could not be cancelled, since

  Assert(ordersAllowed >= 0); //We must never have ordered more than we are allowed

  //Update required resource, after we moved some from Out to In queue
  resRequired := GetWareRequired;

  //Order as many as we can within our limit
  if (resRequired > 0) and (ordersAllowed > 0) then
  begin
    orderToDo := Min(resRequired, ordersAllowed);
    Inc(fMarketDeliveryCount[fResFrom], orderToDo);
    gHands[Owner].Deliveries.Queue.AddDemand(Self, nil, fResFrom, orderToDo, dtOnce, diNorm)
  end
  else
  //There are too many resources ordered, so remove as many as we can from the delivery list (some will be being performed)
  if (resRequired < 0) then
  begin
    ordersRemoved := gHands[Owner].Deliveries.Queue.TryRemoveDemand(Self, fResFrom, -resRequired, plannedToRemove);
    Dec(fMarketDeliveryCount[fResFrom], ordersRemoved);
    Inc(fMarketDemandsClosing[fResFrom], plannedToRemove);
  end;
end;


//Player has changed the amount of order
procedure TKMHouseMarket.SetWareOrder(aId: Byte; aValue: Integer);
begin
  if (fResFrom = wtNone) or (fResTo = wtNone) or (fResFrom = fResTo) then Exit;

  fTradeAmount := EnsureRange(aValue, 0, MAX_WARES_ORDER);

  //Try to make an exchange from existing resources
  AttemptExchange;

  //If player cancelled exchange then move all remainders of From resource to Offers list
  if fTradeAmount = 0 then
    MoveWareIn2Out(fResFrom, fMarketWareIn[fResFrom]);

  UpdateDemands;
end;


//Check and proceed if we Set or UnSet dmTakeOut delivery mode
procedure TKMHouseMarket.CheckTakeOutDeliveryMode;
var
  WT: TKMWareType;
begin
  if DeliveryMode = dmTakeOut then
    for WT := WARE_MIN to WARE_MAX do
    begin
      if fMarketWareIn[WT] > 0 then
        gHands[Owner].Deliveries.Queue.RemOffer(Self, WT, fMarketWareIn[WT]);
    end;

  if NewDeliveryMode = dmTakeOut then
  begin
    for WT := WARE_MIN to WARE_MAX do
    begin
      if fMarketWareIn[WT] > 0 then
        gHands[Owner].Deliveries.Queue.AddOffer(Self, WT, fMarketWareIn[WT]);
    end;
  end;
end;


constructor TKMHouseMarket.Load(LoadStream: TKMemoryStream);
begin
  inherited;

  LoadStream.CheckMarker('HouseMarket');
  LoadStream.Read(fTradeAmount);
  LoadStream.Read(fResFrom, SizeOf(fResFrom));
  LoadStream.Read(fResTo, SizeOf(fResTo));
  LoadStream.Read(fMarketWareIn, SizeOf(fMarketWareIn));
  LoadStream.Read(fMarketWareOut, SizeOf(fMarketWareOut));
  LoadStream.Read(fMarketDeliveryCount, SizeOf(fMarketDeliveryCount));
  LoadStream.Read(fMarketDemandsClosing, SizeOf(fMarketDemandsClosing));
end;


procedure TKMHouseMarket.Save(SaveStream: TKMemoryStream);
begin
  inherited;

  SaveStream.PlaceMarker('HouseMarket');
  SaveStream.Write(fTradeAmount);
  SaveStream.Write(fResFrom, SizeOf(fResFrom));
  SaveStream.Write(fResTo, SizeOf(fResTo));
  SaveStream.Write(fMarketWareIn, SizeOf(fMarketWareIn));
  SaveStream.Write(fMarketWareOut, SizeOf(fMarketWareOut));
  SaveStream.Write(fMarketDeliveryCount, SizeOf(fMarketDeliveryCount));
  SaveStream.Write(fMarketDemandsClosing, SizeOf(fMarketDemandsClosing));
end;


//Render special market wares display
procedure TKMHouseMarket.Paint;
var
  WT: TKMWareType;
  bestCount: Word;
  bestWare: TKMWareType;
begin
  inherited;

  if fBuildState < hbsDone then Exit;

  //Market can display only one ware at a time (lookup ware that has most count)
  bestCount := 0;
  bestWare := wtNone;
  for WT := WARE_MIN to WARE_MAX do
  if fMarketWareIn[WT] + fMarketWareOut[WT] > bestCount then
  begin
    bestCount := fMarketWareIn[WT] + fMarketWareOut[WT];
    bestWare := WT;
  end;

  if bestCount > 0 then
    //FlagAnimStep is required for horses animation
    gRenderPool.AddHouseMarketSupply(fPosition, bestWare, bestCount, FlagAnimStep);
end;


function TKMHouseMarket.ObjToString(const aSeparator: String = '|'): String;
var
  resInStr, resOutStr, deliveryCntStr, demandsCloseStr, strIn, strOut, strDel, strDemClose: string;
  WT: TKMWareType;
  len: Integer;
begin
  if Self = nil then Exit('nil');

  resInStr := '';
  resOutStr := '';
  deliveryCntStr := '';
  demandsCloseStr := '';

  for WT := WARE_MIN to WARE_MAX do
  begin
    strIn  := IntToStr(fMarketWareIn[WT]);
    strOut := IntToStr(fMarketWareOut[WT]);
    strDel := IntToStr(fMarketDeliveryCount[WT]);
    strDemClose := IntToStr(fMarketDemandsClosing[WT]);
    len := Max3I(Length(strIn), Length(strOut), Length(strDel));
    resInStr        := resInStr        + ' ' + StringOfChar(' ', len - Length(strIn))       + strIn;
    resOutStr       := resOutStr       + ' ' + StringOfChar(' ', len - Length(strOut))      + strOut;
    deliveryCntStr  := deliveryCntStr  + ' ' + StringOfChar(' ', len - Length(strDel))      + strDel;
    demandsCloseStr := demandsCloseStr + ' ' + StringOfChar(' ', len - Length(strDemClose)) + strDemClose;
  end;

  Result := inherited +
            Format('%sMarketResFrom = %s%sMarketResTo = %s%sTradeAmount = %d%sMarketResIn       = %s%sMarketResOut      = %s' +
                   '%sMarketDeliveryCnt = %s%sMarketDemandClose = %s',
                   [aSeparator,
                    GetEnumName(TypeInfo(TKMWareType), Integer(fResFrom)), aSeparator,
                    GetEnumName(TypeInfo(TKMWareType), Integer(fResTo)), aSeparator,
                    fTradeAmount, aSeparator,
                    resInStr, aSeparator,
                    resOutStr, aSeparator,
                    deliveryCntStr, aSeparator,
                    demandsCloseStr]);
end;


end.
