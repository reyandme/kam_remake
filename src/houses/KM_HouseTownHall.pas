unit KM_HouseTownHall;
{$I KaM_Remake.inc}
interface
uses
  KM_Houses,
  KM_ResHouses, KM_ResWares,
  KM_CommonClasses, KM_Defaults, KM_Points;

const
  TH_MAX_GOLDMAX_VALUE = 999; //Max value for TownHall MaxGold parameter


type
  TKMHouseTownHall = class(TKMHouseWFlagPoint)
  private
    fGoldCnt: Word;
    fGoldMaxCnt: Word;
    function GetTHUnitOrderIndex(aUnitType: TKMUnitType): Integer;
    procedure SetGoldCnt(aValue: Word);
    procedure SetGoldMaxCnt(aValue: Word); overload;
    procedure AddInitialDemands;
  protected
    function GetFlagPointTexId: Word; override;
    procedure AddDemandsOnActivate(aWasBuilt: Boolean); override;
    function GetResIn(aI: Byte): Word; override;
    procedure SetResIn(aI: Byte; aValue: Word); override;
  public
    constructor Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure Save(SaveStream: TKMemoryStream); override;

    procedure SetGoldMaxCnt(aValue: Word; aFromScript: Boolean); overload;

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
  KM_Hand, KM_HandsCollection, KM_HandLogistics, KM_Terrain,
  KM_UnitWarrior, KM_ResUnits,
  KM_InterfaceGame;


{TKMHouseTownHall}
constructor TKMHouseTownHall.Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
begin
  inherited;

  fGoldCnt := 0;
  fGoldMaxCnt := MAX_WARES_IN_HOUSE;
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
  fGoldCnt := EnsureRange(aValue, 0, fGoldMaxCnt);
end;


procedure TKMHouseTownHall.SetGoldMaxCnt(aValue: Word; aFromScript: Boolean);
var
  OldGoldMax: Word;
begin
  OldGoldMax := fGoldMaxCnt;
  fGoldMaxCnt := EnsureRange(aValue, 0, TH_MAX_GOLDMAX_VALUE);
  if not aFromScript then
  begin
    if OldGoldMax > fGoldMaxCnt then
      gHands[fOwner].Deliveries.Queue.TryRemoveDemand(Self, wtGold, OldGoldMax - fGoldMaxCnt)
    else if OldGoldMax < fGoldMaxCnt then
    begin
      //if fGoldCnt < fGoldMaxCnt then
      gHands[fOwner].Deliveries.Queue.AddDemand(Self, nil, wtGold, fGoldMaxCnt - Max(OldGoldMax, fGoldCnt), dtOnce, diNorm);
    end;
  end;
end;


procedure TKMHouseTownHall.SetGoldMaxCnt(aValue: Word);
begin
  SetGoldMaxCnt(aValue, False);
end;


function TKMHouseTownHall.GetFlagPointTexId: Word;
begin
  Result := 249;
end;


function TKMHouseTownHall.CanEquip(aUnitType: TKMUnitType): Boolean;
var
  THUnitIndex: Integer;
begin
  Result := not gHands[fOwner].Locks.GetUnitBlocked(aUnitType, True);

  THUnitIndex := GetTHUnitOrderIndex(aUnitType);

  if THUnitIndex <> -1 then
    Result := Result and (fGoldCnt >= TH_TROOP_COST[THUnitIndex]);  //Can't equip if we don't have a required resource
end;


//Equip a new soldier and make him walk out of the house
//Return the number of units successfully equipped
function TKMHouseTownHall.Equip(aUnitType: TKMUnitType; aCount: Integer): Integer;
var
  I, K, THUnitIndex: Integer;
  Soldier: TKMUnitWarrior;
  FoundTPR: Boolean;
begin
  Result := 0;
  FoundTPR := False;
  for I := Low(TownHall_Order) to High(TownHall_Order) do
    if TownHall_Order[I] = aUnitType then
    begin
      FoundTPR := True;
      Break;
    end;
  Assert(FoundTPR);

  THUnitIndex := GetTHUnitOrderIndex(aUnitType);
  if THUnitIndex = -1 then Exit;
  
  
  for K := 0 to aCount - 1 do
  begin
    //Make sure we have enough resources to equip a unit
    if not CanEquip(aUnitType) then Exit;

    //Take resources
    for I := 0 to TH_TROOP_COST[THUnitIndex] - 1 do
    begin  
      ResTakeFromIn(wtGold); //Do the goldtaking
      gHands[fOwner].Stats.WareConsumed(wtGold);
    end;
      
    //Make new unit
    Soldier := TKMUnitWarrior(gHands[fOwner].TrainUnit(aUnitType, Entrance));
    Soldier.InHouse := Self; //Put him in the barracks, so if it is destroyed while he is inside he is placed somewhere
    Soldier.Visible := False; //Make him invisible as he is inside the barracks
    Soldier.Condition := Round(TROOPS_TRAINED_CONDITION * UNIT_MAX_CONDITION); //All soldiers start with 3/4, so groups get hungry at the same time
    Soldier.SetActionGoIn(uaWalk, gdGoOutside, Self);
    if Assigned(Soldier.OnUnitTrained) then
      Soldier.OnUnitTrained(Soldier);
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


procedure TKMHouseTownHall.AddInitialDemands;
begin
  gHands[fOwner].Deliveries.Queue.AddDemand(Self, nil, wtGold, fGoldMaxCnt - fGoldCnt, dtOnce, diNorm);
end;


procedure TKMHouseTownHall.PostLoadMission;
begin
  AddInitialDemands;
end;


procedure TKMHouseTownHall.AddDemandsOnActivate(aWasBuilt: Boolean);
begin
  if aWasBuilt then
    AddInitialDemands;
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
begin
  Assert(aWare = wtGold, 'Invalid resource added to TownHall');

  // Allow to enlarge GoldMaxCnt from script (either from .dat or from .script)
  if aFromScript and (fGoldMaxCnt < fGoldCnt + aCount) then
    SetGoldMaxCnt(fGoldCnt + aCount, True);

  fGoldCnt := EnsureRange(fGoldCnt + aCount, 0, High(Word));
  if aFromScript then
    gHands[fOwner].Deliveries.Queue.TryRemoveDemand(Self, aWare, aCount);
end;


procedure TKMHouseTownHall.ResTakeFromIn(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False);
begin
  aCount := Min(aCount, fGoldCnt);
  if aFromScript then
    gHands[Owner].Stats.WareConsumed(aWare, aCount);

  Dec(fGoldCnt, aCount);
  //Only request a new resource if it is allowed by the distribution of wares for our parent player
  gHands[fOwner].Deliveries.Queue.AddDemand(Self, nil, aWare, aCount, dtOnce, diNorm);
end;


procedure TKMHouseTownHall.ResTakeFromOut(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False);
begin
  Assert(aWare = wtGold, 'Invalid resource added to TownHall');
  if aFromScript then
  begin
    aCount := Min(aCount, fGoldCnt);
    if aCount > 0 then
    begin
      gHands[fOwner].Stats.WareConsumed(aWare, aCount);
      gHands[fOwner].Deliveries.Queue.RemOffer(Self, aWare, aCount);
    end;
  end;
  Assert(aCount <= fGoldCnt);
  Dec(fGoldCnt, aCount);
  if gHands[fOwner].Deliveries.Queue.GetDemandsCnt(Self, aWare, dtOnce, diNorm) < fGoldMaxCnt then
    gHands[fOwner].Deliveries.Queue.AddDemand(Self, nil, aWare, aCount, dtOnce, diNorm);
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
