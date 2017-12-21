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
    function GetTHUnitOrderIndex(aUnitType: TUnitType): Integer;
    procedure SetGoldCnt(aValue: Word);
    procedure SetGoldMaxCnt(aValue: Word); overload;
  protected
    function GetFlagPointTexId: Word; override;
    procedure AddDemandsOnActivate; override;
    function GetResIn(aI: Byte): Word; override;
    procedure SetResIn(aI: Byte; aValue: Word); override;
  public
    constructor Create(aUID: Integer; aHouseType: THouseType; PosX, PosY: Integer; aOwner: TKMHandIndex; aBuildState: THouseBuildState);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure Save(SaveStream: TKMemoryStream); override;

    procedure SetGoldMaxCnt(aValue: Word; aFromScript: Boolean); overload;

    property GoldCnt: Word read fGoldCnt write SetGoldCnt;
    property GoldMaxCnt: Word read fGoldMaxCnt write SetGoldMaxCnt;

    procedure DemolishHouse(aFrom: TKMHandIndex; IsSilent: Boolean = False); override;

    function Equip(aUnitType: TUnitType; aCount: Integer): Integer;
    function CanEquip(aUnitType: TUnitType): Boolean;

    procedure PostLoadMission; override;

    procedure ResAddToIn(aWare: TWareType; aCount: Integer = 1; aFromScript: Boolean = False); override;
    procedure ResTakeFromIn(aWare: TWareType; aCount: Word = 1; aFromScript: Boolean = False); override;
    procedure ResTakeFromOut(aWare: TWareType; aCount: Word = 1; aFromScript: Boolean = False); override;
    function CheckResIn(aWare: TWareType): Word; override;
    function ResCanAddToIn(aRes: TWareType): Boolean; override;
  end;


implementation
uses
  Math,
  KM_Hand, KM_HandsCollection, KM_HandLogistics, KM_Terrain,
  KM_Units_Warrior, KM_ResUnits,
  KM_InterfaceGame;


{TKMHouseTownHall}
constructor TKMHouseTownHall.Create(aUID: Integer; aHouseType: THouseType; PosX, PosY: Integer; aOwner: TKMHandIndex; aBuildState: THouseBuildState);
begin
  inherited;

  fGoldCnt := 0;
  fGoldMaxCnt := MAX_WARES_IN_HOUSE;
//  fGoldDeliveryCount := 0;
end;


constructor TKMHouseTownHall.Load(LoadStream: TKMemoryStream);
begin
  inherited;

  LoadStream.Read(fGoldCnt);
  LoadStream.Read(fGoldMaxCnt);
//  LoadStream.Read(fGoldDeliveryCount);
end;


procedure TKMHouseTownHall.Save(SaveStream: TKMemoryStream);
begin
  inherited;

  SaveStream.Write(fGoldCnt);
  SaveStream.Write(fGoldMaxCnt);
//  SaveStream.Write(fGoldDeliveryCount);
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
      gHands[fOwner].Deliveries.Queue.TryRemoveDemand(Self, wt_Gold, OldGoldMax - fGoldMaxCnt)
    else if OldGoldMax < fGoldMaxCnt then
    begin
      //if fGoldCnt < fGoldMaxCnt then
      gHands[fOwner].Deliveries.Queue.AddDemand(Self, nil, wt_Gold, fGoldMaxCnt - Max(OldGoldMax, fGoldCnt), dtOnce, diNorm);
    end;
  end;

////    TryRemoveDemand
//    for I := OldGoldMaxCnt to fGoldMaxCnt - 1 do
//      gHands[fOwner].Deliveries.Queue.RemOffer(Self, wt_Gold, aCount);

end;


procedure TKMHouseTownHall.SetGoldMaxCnt(aValue: Word);
begin
  SetGoldMaxCnt(aValue, False);
end;


function TKMHouseTownHall.GetFlagPointTexId: Word;
begin
  Result := 249;
end;


function TKMHouseTownHall.CanEquip(aUnitType: TUnitType): Boolean;
var
  THUnitIndex: Integer;
begin
  Result := not gHands[fOwner].Locks.GetUnitBlocked(aUnitType, True);

  THUnitIndex := GetTHUnitOrderIndex(aUnitType);

  if THUnitIndex <> -1 then
    Result := Result and (fGoldCnt >= TH_TroopCost[THUnitIndex]);  //Can't equip if we don't have a required resource
end;


//Equip a new soldier and make him walk out of the house
//Return the number of units successfully equipped
function TKMHouseTownHall.Equip(aUnitType: TUnitType; aCount: Integer): Integer;
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
    for I := 0 to TH_TroopCost[THUnitIndex] - 1 do
    begin  
      ResTakeFromIn(wt_Gold); //Do the goldtaking
      gHands[fOwner].Stats.WareConsumed(wt_Gold);
    end;
      
    //Make new unit
    Soldier := TKMUnitWarrior(gHands[fOwner].TrainUnit(aUnitType, Entrance));
    Soldier.SetInHouse(Self); //Put him in the barracks, so if it is destroyed while he is inside he is placed somewhere
    Soldier.Visible := False; //Make him invisible as he is inside the barracks
    Soldier.Condition := Round(TROOPS_TRAINED_CONDITION * UNIT_MAX_CONDITION); //All soldiers start with 3/4, so groups get hungry at the same time
    Soldier.SetActionGoIn(ua_Walk, gd_GoOutside, Self);
    if Assigned(Soldier.OnUnitTrained) then
      Soldier.OnUnitTrained(Soldier);
    Inc(Result);
  end;
end;


function TKMHouseTownhall.GetTHUnitOrderIndex(aUnitType: TUnitType): Integer;
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
var
  DemandsCnt: Integer;
begin
  DemandsCnt := fGoldMaxCnt - fGoldCnt;
  gHands[fOwner].Deliveries.Queue.AddDemand(Self, nil, wt_Gold, DemandsCnt, dtOnce, diNorm); //Every new house needs 5 resource units
end;


procedure TKMHouseTownHall.AddDemandsOnActivate;
//var
//  DemandsCnt: Integer;
begin
  //We have to add demands in PostLoadMission procedure, as GoldMaxCnt and GoldCnt are not loaded yet

//  DemandsCnt := fGoldMaxCnt - fGoldCnt;
//  gHands[fOwner].Deliveries.Queue.AddDemand(Self, nil, wt_Gold, DemandsCnt, dtOnce, diNorm); //Every new house needs 5 resource units
//  Inc(fGoldDeliveryCount, DemandsCnt);
end;


procedure TKMHouseTownHall.DemolishHouse(aFrom: TKMHandIndex; IsSilent: Boolean = False);
begin
  gHands[fOwner].Stats.WareConsumed(wt_Gold, fGoldCnt);

  inherited;
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


procedure TKMHouseTownHall.ResAddToIn(aWare: TWareType; aCount: Integer = 1; aFromScript: Boolean = False);
//var
//  OldCnt, AddedGoldCnt, OrdersRemoved: Integer;
begin
  Assert(aWare = wt_Gold, 'Invalid resource added to TownHall');

//  OldCnt := fGoldCnt;

  // Allow to enlarge GoldMaxCnt from script (either from .dat or from .script)
  if aFromScript and (fGoldMaxCnt < fGoldCnt + aCount) then
    SetGoldMaxCnt(fGoldCnt + aCount, True);

  fGoldCnt := EnsureRange(fGoldCnt + aCount, 0, High(Word));
//  AddedGoldCnt := fGoldCnt - OldCnt;
  if aFromScript then
  begin
//    Inc(fGoldDeliveryCount, AddedGoldCnt);
    {OrdersRemoved := }gHands[fOwner].Deliveries.Queue.TryRemoveDemand(Self, aWare, aCount);
//    Dec(fGoldDeliveryCount, OrdersRemoved);
  end;
//  gHands[fOwner].Deliveries.Queue.AddOffer(Self, aWare, fGoldCnt - OldCnt);
end;


procedure TKMHouseTownHall.ResTakeFromIn(aWare: TWareType; aCount: Word = 1; aFromScript: Boolean = False);
begin
  aCount := Min(aCount, fGoldCnt);
  if aFromScript then
    gHands[Owner].Stats.WareConsumed(aWare, aCount);

//  fGoldDeliveryCount := Max(fGoldDeliveryCount - aCount, 0);

  Dec(fGoldCnt, aCount);
  //Only request a new resource if it is allowed by the distribution of wares for our parent player
  gHands[fOwner].Deliveries.Queue.AddDemand(Self, nil, aWare, aCount, dtOnce, diNorm);
//  Inc(fGoldDeliveryCount, aCount);
end;


procedure TKMHouseTownHall.ResTakeFromOut(aWare: TWareType; aCount: Word = 1; aFromScript: Boolean = False);
begin
  Assert(aWare = wt_Gold, 'Invalid resource added to TownHall');
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
end;


function TKMHouseTownHall.CheckResIn(aWare: TWareType): Word;
begin
  Result := 0; //Including Wood/stone in building stage
  if aWare = wt_Gold then
    Result := fGoldCnt;
end;


function TKMHouseTownHall.ResCanAddToIn(aRes: TWareType): Boolean;
begin
  Result := (aRes = wt_Gold) and (fGoldCnt < fGoldMaxCnt);
end;


end.
