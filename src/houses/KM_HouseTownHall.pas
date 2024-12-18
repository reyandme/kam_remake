unit KM_HouseTownHall;
{$I KaM_Remake.inc}
interface
uses
  KM_CommonClasses, KM_Defaults,
  KM_Houses,
  KM_ResTypes;

const
  TH_MAX_GOLDMAX_VALUE = High(Word); //Max value for TownHall MaxGold parameter


type
  TKMHouseTownHall = class(TKMHouseWFlagPoint)
  private
    fGoldCnt: Integer;
    fGoldMaxCnt: Integer;
    function GetTHUnitOrderIndex(aUnitType: TKMUnitType): Integer;
    procedure SetGoldCnt(aValue: Integer); overload;
    procedure SetGoldCnt(aValue: Integer; aLimitMaxGoldCnt: Boolean); overload;

    procedure SetGoldMaxCnt(aValue: Integer);

    function GetGoldDeliveryCnt: Word;
    procedure SetGoldDeliveryCnt(aCount: Word);

    function GetGoldDemandsClosing: Word;
    procedure SetGoldDemandsClosing(aCount: Word);

    property GoldDeliveryCnt: Word read GetGoldDeliveryCnt write SetGoldDeliveryCnt;
    property GoldDemandsClosing: Word read GetGoldDemandsClosing write SetGoldDemandsClosing;
  protected
    procedure AddDemandsOnActivate(aWasBuilt: Boolean); override;
    function GetWareIn(aI: Byte): Word; override;
    procedure SetWareIn(aI: Byte; aValue: Word); override;

    function TryDecWareDelivery(aWare: TKMWareType; aDeleteCanceled: Boolean): Boolean; override;
  public
    constructor Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure Save(SaveStream: TKMemoryStream); override;

    property GoldCnt: Integer read fGoldCnt write SetGoldCnt;
    property GoldMaxCnt: Integer read fGoldMaxCnt write SetGoldMaxCnt;

    function ShouldAbandonDeliveryTo(aWareType: TKMWareType): Boolean; override;

    function Equip(aUnitType: TKMUnitType; aCount: Integer): Integer;
    function CanEquip(aUnitType: TKMUnitType): Boolean;

    procedure PostLoadMission; override;
    procedure UpdateDemands; override;

    procedure WareTake(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False); override;
    procedure WareAddToIn(aWare: TKMWareType; aCount: Integer = 1; aFromScript: Boolean = False); override;
    procedure WareTakeFromIn(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False); override;
    procedure WareTakeFromOut(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False); override;
    function CheckWareIn(aWare: TKMWareType): Word; override;
    function WareCanAddToIn(aWare: TKMWareType): Boolean; override;
    function CanHaveWareType(aWare: TKMWareType): Boolean; override;
  end;


implementation
uses
  Math,
  KM_Hand, KM_HandsCollection, KM_HandLogistics, KM_HandTypes, KM_HandEntity,
  KM_UnitWarrior, KM_ResUnits, KM_ScriptingEvents,
  KM_InterfaceGame;


{ TKMHouseTownHall }
constructor TKMHouseTownHall.Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
var
  I, M: Integer;
begin
  M := MAX_WARES_IN_HOUSE;
  //Get max troop cost and set GoldMaxCnt to it
  for I := Low(TH_TROOP_COST) to High(TH_TROOP_COST) do
    if TH_TROOP_COST[I] > M then
      M := TH_TROOP_COST[I];
  fGoldCnt := 0;
  fGoldMaxCnt := M;

  inherited;
end;


constructor TKMHouseTownHall.Load(LoadStream: TKMemoryStream);
begin
  inherited;

  LoadStream.CheckMarker('HouseTownHall');
  LoadStream.Read(fGoldCnt);
  LoadStream.Read(fGoldMaxCnt);
end;


procedure TKMHouseTownHall.Save(SaveStream: TKMemoryStream);
begin
  inherited;

  SaveStream.PlaceMarker('HouseTownHall');
  SaveStream.Write(fGoldCnt);
  SaveStream.Write(fGoldMaxCnt);
end;


procedure TKMHouseTownHall.SetGoldCnt(aValue: Integer);
begin
  SetGoldCnt(aValue, True);
end;


procedure TKMHouseTownHall.SetGoldCnt(aValue: Integer; aLimitMaxGoldCnt: Boolean);
var
  oldValue: Integer;
begin
  oldValue := fGoldCnt;

  fGoldCnt := EnsureRange(aValue, 0, IfThen(aLimitMaxGoldCnt, fGoldMaxCnt, High(Word)));

  SetWareInManageTakeOutDeliveryMode(wtGold, fGoldCnt - oldValue);

  if oldValue <> fGoldCnt then
    gScriptEvents.ProcHouseWareCountChanged(Self, wtGold, fGoldCnt, fGoldCnt - oldValue);
end;


function TKMHouseTownHall.TryDecWareDelivery(aWare: TKMWareType; aDeleteCanceled: Boolean): Boolean;
begin
  Assert(GoldDemandsClosing > 0);

  // If there was no delivery (it was cancelled)
  if not aDeleteCanceled then
    GoldDeliveryCnt := GoldDeliveryCnt - 1; // No delivery => reduce DeliveryCnt
  GoldDemandsClosing := GoldDemandsClosing - 1;

  Result := True;
end;


procedure TKMHouseTownHall.SetGoldMaxCnt(aValue: Integer);
begin
  fGoldMaxCnt := EnsureRange(aValue, 0, TH_MAX_GOLDMAX_VALUE);
  UpdateDemands;
end;


function TKMHouseTownHall.CanEquip(aUnitType: TKMUnitType): Boolean;
var
  thUnitIndex: Integer;
begin
  Result := not gHands[Owner].Locks.GetUnitBlocked(aUnitType, True);

  thUnitIndex := GetTHUnitOrderIndex(aUnitType);

  if thUnitIndex <> -1 then
    Result := Result and (fGoldCnt >= TH_TROOP_COST[thUnitIndex]);  //Can't equip if we don't have a required resource
end;


//Equip a new soldier and make him walk out of the house
//Return the number of units successfully equipped
function TKMHouseTownHall.Equip(aUnitType: TKMUnitType; aCount: Integer): Integer;
var
  I, K, thUnitIndex: Integer;
  soldier: TKMUnitWarrior;
  foundTPR: Boolean;
begin
  Result := 0;
  foundTPR := False;
  for I := Low(TownHall_Order) to High(TownHall_Order) do
    if TownHall_Order[I] = aUnitType then
    begin
      foundTPR := True;
      Break;
    end;
  Assert(foundTPR);

  thUnitIndex := GetTHUnitOrderIndex(aUnitType);
  if thUnitIndex = -1 then Exit;
  
  for K := 0 to aCount - 1 do
  begin
    //Make sure we have enough resources to equip a unit
    if not CanEquip(aUnitType) then Exit;

    //Take resources
    GoldDeliveryCnt := GoldDeliveryCnt - TH_TROOP_COST[thUnitIndex]; //Compensation for GoldDeliveryCnt
    WareTakeFromIn(wtGold, TH_TROOP_COST[thUnitIndex]); //Do the goldtaking

    gHands[Owner].Stats.WareConsumed(wtGold, TH_TROOP_COST[thUnitIndex]);
      
    //Make new unit
    soldier := TKMUnitWarrior(gHands[Owner].TrainUnit(aUnitType, Self));
    soldier.Visible := False; //Make him invisible as he is inside the barracks
    soldier.Condition := Round(TROOPS_TRAINED_CONDITION * UNIT_MAX_CONDITION); //All soldiers start with 3/4, so groups get hungry at the same time
    soldier.SetActionGoIn(uaWalk, gdGoOutside, Self);
    if Assigned(soldier.OnUnitTrained) then
      soldier.OnUnitTrained(soldier);
    Inc(Result);
  end;
end;


function TKMHouseTownhall.GetTHUnitOrderIndex(aUnitType: TKMUnitType): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := Low(TownHall_Order) to High(TownHall_Order) do
  begin
    if TownHall_Order[I] = aUnitType then
    begin
      Result := I;
      Break;
    end;
  end;
end;


procedure TKMHouseTownHall.PostLoadMission;
begin
  // House could be destroyed on the game start if placed with 0 health in the MapEd
  if not IsDestroyed then
    UpdateDemands;
end;


procedure TKMHouseTownHall.AddDemandsOnActivate(aWasBuilt: Boolean);
begin
  UpdateDemands;
end;


function TKMHouseTownHall.GetWareIn(aI: Byte): Word;
begin
  Result := 0;
  if aI = 1 then // Wares are 1 based
    Result := fGoldCnt;
end;


procedure TKMHouseTownHall.SetWareIn(aI: Byte; aValue: Word);
begin
  if aI = 1 then
    GoldCnt := aValue;
end;


function TKMHouseTownHall.ShouldAbandonDeliveryTo(aWareType: TKMWareType): Boolean;
begin
  Result := inherited or (aWareType <> wtGold);
  if not Result then
    Result := GoldCnt + gHands[Owner].Deliveries.Queue.GetDeliveriesToHouseCnt(Self, wtGold) > GoldMaxCnt;
end;


procedure TKMHouseTownHall.WareAddToIn(aWare: TKMWareType; aCount: Integer = 1; aFromScript: Boolean = False);
var
  ordersRemoved, plannedToRemove: Integer;
begin
  Assert(aWare = wtGold, 'Invalid ware added to TownHall');

  // Allow to enlarge GoldMaxCnt from script (either from .dat or from .script)
  if aFromScript and (fGoldMaxCnt < fGoldCnt + aCount) then
    SetGoldMaxCnt(fGoldCnt + aCount);

  SetGoldCnt(fGoldCnt + aCount, False);

  if aFromScript then
  begin
    GoldDeliveryCnt := GoldDeliveryCnt + aCount;
    ordersRemoved := gHands[Owner].Deliveries.Queue.TryRemoveDemand(Self, aWare, aCount, plannedToRemove);
    GoldDeliveryCnt := GoldDeliveryCnt - ordersRemoved;
    GoldDemandsClosing := GoldDemandsClosing + plannedToRemove;
  end;

  UpdateDemands;
end;


function TKMHouseTownHall.GetGoldDeliveryCnt: Word;
begin
  Result := WareDeliveryCnt[1];
end;


procedure TKMHouseTownHall.SetGoldDeliveryCnt(aCount: Word);
begin
  WareDeliveryCnt[1] := aCount;
end;


function TKMHouseTownHall.GetGoldDemandsClosing: Word;
begin
  Result := WareDemandsClosing[1];
end;


procedure TKMHouseTownHall.SetGoldDemandsClosing(aCount: Word);
begin
  WareDemandsClosing[1] := aCount;
end;


procedure TKMHouseTownHall.UpdateDemands;
const
  MAX_GOLD_DEMANDS = 30; //Limit max number of demands by townhall to not to overfill demands list
var
  goldToOrder, ordersRemoved, plannedToRemove, deliveringGold: Integer;
begin
  deliveringGold := GoldDeliveryCnt - GoldDemandsClosing; // We might consider here, same as in Market: GoldDeliveryCnt - Max(0, GoldDemandsClosing - 1);
  goldToOrder := Min(MAX_GOLD_DEMANDS - (deliveringGold - fGoldCnt), fGoldMaxCnt - deliveringGold);
  if goldToOrder > 0 then
  begin
    gHands[Owner].Deliveries.Queue.AddDemand(Self, nil, wtGold, goldToOrder, dtOnce, diNorm);
    GoldDeliveryCnt := GoldDeliveryCnt + goldToOrder;
  end
  else
  if goldToOrder < 0 then
  begin
    ordersRemoved := gHands[Owner].Deliveries.Queue.TryRemoveDemand(Self, wtGold, -goldToOrder, plannedToRemove);
    GoldDeliveryCnt := GoldDeliveryCnt - ordersRemoved;
    GoldDemandsClosing := GoldDemandsClosing + plannedToRemove;
  end;
end;


procedure TKMHouseTownHall.WareTake(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False);
begin
  if DeliveryMode = dmTakeOut then
    WareTakeFromOut(aWare, aCount, aFromScript)
  else
    WareTakeFromIn(aWare, aCount, aFromScript);
end;


procedure TKMHouseTownHall.WareTakeFromIn(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False);
begin
  Assert(aWare = wtGold, 'Invalid ware taken from TownHall');

  aCount := EnsureRange(aCount, 0, fGoldCnt);
  if aFromScript then
  begin
    aCount := EnsureRange(aCount, 0, fGoldCnt);
    gHands[Owner].Stats.WareConsumed(aWare, aCount);
  end;

  //Keep track of how many are ordered
  GoldDeliveryCnt := EnsureRange(GoldDeliveryCnt - aCount, 0, High(Word));

  SetGoldCnt(fGoldCnt - aCount, False);
  UpdateDemands;
end;


procedure TKMHouseTownHall.WareTakeFromOut(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False);
begin
  Assert(aWare = wtGold, 'Invalid ware taken from TownHall');

  if aFromScript then
  begin
    aCount := EnsureRange(aCount, 0, fGoldCnt);
    if aCount > 0 then
    begin
      gHands[Owner].Stats.WareConsumed(aWare, aCount);
      gHands[Owner].Deliveries.Queue.RemOffer(Self, aWare, aCount);
    end;
  end;
  Assert(aCount <= fGoldCnt);
  SetGoldCnt(fGoldCnt - aCount, False);

  //Keep track of how many are ordered
  GoldDeliveryCnt := GoldDeliveryCnt - aCount;

  UpdateDemands;
end;


function TKMHouseTownHall.CheckWareIn(aWare: TKMWareType): Word;
begin
  Result := 0; //Including Wood/stone in building stage
  if aWare = wtGold then
    Result := fGoldCnt;
end;


function TKMHouseTownHall.WareCanAddToIn(aWare: TKMWareType): Boolean;
begin
  Result := (aWare = wtGold) and (fGoldCnt < fGoldMaxCnt);
end;


function TKMHouseTownHall.CanHaveWareType(aWare: TKMWareType): Boolean;
begin
  Result := (aWare = wtGold);
end;


end.
