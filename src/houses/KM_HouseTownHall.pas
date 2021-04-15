unit KM_HouseTownHall;
{$I KaM_Remake.inc}
interface
uses
  KM_Houses,

  KM_CommonClasses, KM_Defaults,
  KM_ResTypes;

const
  TH_MAX_GOLDMAX_VALUE = 999; //Max value for TownHall MaxGold parameter


type
  TKMHouseTownHall = class(TKMHouseWFlagPoint)
  private
    fGoldCnt: Word;
    fGoldMaxCnt: Word;
    function GetTHUnitOrderIndex(aUnitType: TKMUnitType): Integer;
    procedure SetGoldCnt(aValue: Word); overload;
    procedure SetGoldCnt(aValue: Word; aLimitMaxGoldCnt: Boolean); overload;
    procedure UpdateDemands;

    procedure SetGoldMaxCnt(aValue: Word);

    function GetGoldDeliveryCnt: Word;
    procedure SetGoldDeliveryCnt(aCount: Word);

    property GoldDeliveryCnt: Word read GetGoldDeliveryCnt write SetGoldDeliveryCnt;
  protected
    function GetFlagPointTexId: Word; override;
    procedure AddDemandsOnActivate(aWasBuilt: Boolean); override;
    function GetResIn(aI: Byte): Word; override;
    procedure SetResIn(aI: Byte; aValue: Word); override;
  public
    constructor Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure Save(SaveStream: TKMemoryStream); override;


    procedure DecResourceDelivery(aWare: TKMWareType); override;

    property GoldCnt: Word read fGoldCnt write SetGoldCnt;
    property GoldMaxCnt: Word read fGoldMaxCnt write SetGoldMaxCnt;

    function ShouldAbandonDeliveryTo(aWareType: TKMWareType): Boolean; override;

    function Equip(aUnitType: TKMUnitType; aCount: Integer): Integer;
    function CanEquip(aUnitType: TKMUnitType): Boolean;

    procedure PostLoadMission; override;

    procedure ResAddToIn(aWare: TKMWareType; aCount: Integer = 1; aFromScript: Boolean = False); override;
    procedure ResTakeFromIn(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False); override;
    procedure ResTakeFromOut(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False); override;
    function CheckResIn(aWare: TKMWareType): Word; override;
    function ResCanAddToIn(aRes: TKMWareType): Boolean; override;
  end;


implementation
uses
  Math,
  KM_Hand, KM_HandsCollection, KM_HandLogistics,
  KM_UnitWarrior, KM_ResUnits, KM_ScriptingEvents,
  KM_InterfaceGame;

{TKMHouseTownHall}
constructor TKMHouseTownHall.Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
var
  I, M: Integer;
begin
  inherited;
  
  M := MAX_WARES_IN_HOUSE;
  //Get max troop cost and set GoldMaxCnt to it
  for I := Low(TH_TROOP_COST) to High(TH_TROOP_COST) do
    if TH_TROOP_COST[I] > M then 
      M := TH_TROOP_COST[I];
  fGoldCnt := 0;
  fGoldMaxCnt := M;
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


procedure TKMHouseTownHall.SetGoldCnt(aValue: Word);
begin
  SetGoldCnt(aValue, True);
end;


procedure TKMHouseTownHall.SetGoldCnt(aValue: Word; aLimitMaxGoldCnt: Boolean);
var
  oldValue: Integer;
begin
  oldValue := fGoldCnt;

  fGoldCnt := EnsureRange(aValue, 0, IfThen(aLimitMaxGoldCnt, fGoldMaxCnt, High(Word)));

  SetResInManageTakeOutDeliveryMode(wtGold, fGoldCnt - oldValue);

  if oldValue <> fGoldCnt then
    gScriptEvents.ProcHouseWareCountChanged(Self, wtGold, fGoldCnt, fGoldCnt - oldValue);
end;


procedure TKMHouseTownHall.DecResourceDelivery(aWare: TKMWareType);
begin
  GoldDeliveryCnt := GoldDeliveryCnt - 1;
end;


procedure TKMHouseTownHall.SetGoldMaxCnt(aValue: Word);
begin
  fGoldMaxCnt := EnsureRange(aValue, 0, TH_MAX_GOLDMAX_VALUE);
  UpdateDemands;
end;


function TKMHouseTownHall.GetFlagPointTexId: Word;
begin
  Result := 249;
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
    ResTakeFromIn(wtGold, TH_TROOP_COST[thUnitIndex]); //Do the goldtaking

    gHands[Owner].Stats.WareConsumed(wtGold, TH_TROOP_COST[thUnitIndex]);
      
    //Make new unit
    soldier := TKMUnitWarrior(gHands[Owner].TrainUnit(aUnitType, Entrance));
    soldier.InHouse := Self; //Put him in the barracks, so if it is destroyed while he is inside he is placed somewhere
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
  UpdateDemands;
end;


procedure TKMHouseTownHall.AddDemandsOnActivate(aWasBuilt: Boolean);
begin
  if aWasBuilt then
    UpdateDemands;
end;


function TKMHouseTownHall.GetResIn(aI: Byte): Word;
begin
  Result := 0;
  if aI = 1 then //Resources are 1 based
    Result := fGoldCnt;
end;


procedure TKMHouseTownHall.SetResIn(aI: Byte; aValue: Word);
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


procedure TKMHouseTownHall.ResAddToIn(aWare: TKMWareType; aCount: Integer = 1; aFromScript: Boolean = False);
var
  ordersRemoved : Integer;
begin
  Assert(aWare = wtGold, 'Invalid resource added to TownHall');

  // Allow to enlarge GoldMaxCnt from script (either from .dat or from .script)
  if aFromScript and (fGoldMaxCnt < fGoldCnt + aCount) then
    SetGoldMaxCnt(fGoldCnt + aCount);

  SetGoldCnt(fGoldCnt + aCount, False);

  if aFromScript then
  begin
    GoldDeliveryCnt := GoldDeliveryCnt + aCount;
    ordersRemoved := gHands[Owner].Deliveries.Queue.TryRemoveDemand(Self, aWare, aCount);
    GoldDeliveryCnt := GoldDeliveryCnt - ordersRemoved;
  end;

  UpdateDemands;
end;


function TKMHouseTownHall.GetGoldDeliveryCnt: Word;
begin
  Result := ResDeliveryCnt[1];
end;


procedure TKMHouseTownHall.SetGoldDeliveryCnt(aCount: Word);
begin
  ResDeliveryCnt[1] := aCount;
end;


procedure TKMHouseTownHall.UpdateDemands;
const
  MAX_GOLD_DEMANDS = 20; //Limit max number of demands by townhall to not to overfill demands list
var
  goldToOrder, ordersRemoved: Integer;
begin
  goldToOrder := Min(MAX_GOLD_DEMANDS - (GoldDeliveryCnt - fGoldCnt), fGoldMaxCnt - GoldDeliveryCnt);
  if goldToOrder > 0 then
  begin
    gHands[Owner].Deliveries.Queue.AddDemand(Self, nil, wtGold, goldToOrder, dtOnce, diNorm);
    GoldDeliveryCnt := GoldDeliveryCnt + goldToOrder;
  end
  else
  if goldToOrder < 0 then
  begin
    ordersRemoved := gHands[Owner].Deliveries.Queue.TryRemoveDemand(Self, wtGold, -goldToOrder);
    GoldDeliveryCnt := GoldDeliveryCnt - ordersRemoved;
  end;
end;


procedure TKMHouseTownHall.ResTakeFromIn(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False);
begin
  Assert(aWare = wtGold, 'Invalid resource taken from TownHall');
  aCount := EnsureRange(aCount, 0, fGoldCnt);
  if aFromScript then
    gHands[Owner].Stats.WareConsumed(aWare, aCount);

  SetGoldCnt(fGoldCnt - aCount, False);
  UpdateDemands;
end;


procedure TKMHouseTownHall.ResTakeFromOut(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False);
begin
  Assert(aWare = wtGold, 'Invalid resource taken from TownHall');
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


function TKMHouseTownHall.CheckResIn(aWare: TKMWareType): Word;
begin
  Result := 0; //Including Wood/stone in building stage
  if aWare = wtGold then
    Result := fGoldCnt;
end;


function TKMHouseTownHall.ResCanAddToIn(aRes: TKMWareType): Boolean;
begin
  Result := (aRes = wtGold) and (fGoldCnt < fGoldMaxCnt);
end;


end.
