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
    fGoldMaxCnt: Integer;
    function GetTHUnitOrderIndex(aUnitType: TKMUnitType): Integer;
    procedure SetGoldCnt(aValue: Integer); overload;

    procedure SetGoldMaxCnt(aValue: Integer);
    function GetGoldCount : Integer;
  protected
    procedure AddDemandsOnActivate(aWasBuilt: Boolean); override;

    function GetWareDistribution(aID: Byte): Word; override; //Will use GetRatio from mission settings to find distribution amount
  public
    constructor Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure Save(SaveStream: TKMemoryStream); override;

    property GoldCnt: Integer read GetGoldCount write SetGoldCnt;
    property GoldMaxCnt: Integer read fGoldMaxCnt write SetGoldMaxCnt;

    function ShouldAbandonDeliveryTo(aWareType: TKMWareType): Boolean; override;

    function Equip(aUnitType: TKMUnitType; aCount: Integer): Integer;
    function CanEquip(aUnitType: TKMUnitType): Boolean;

    procedure PostLoadMission; override;
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
  //fGoldCnt := 0;
  fGoldMaxCnt := M;

  inherited;
end;


constructor TKMHouseTownHall.Load(LoadStream: TKMemoryStream);
begin
  inherited;

  LoadStream.CheckMarker('HouseTownHall');
  //LoadStream.Read(fGoldCnt);
  LoadStream.Read(fGoldMaxCnt);
end;


procedure TKMHouseTownHall.Save(SaveStream: TKMemoryStream);
begin
  inherited;

  SaveStream.PlaceMarker('HouseTownHall');
  //SaveStream.Write(fGoldCnt);
  SaveStream.Write(fGoldMaxCnt);
end;

function TKMHouseTownHall.GetWareDistribution(aID: Byte): Word;
begin
  Result := IfThen(aID = 1, fGoldMaxCnt, 0);
end;


procedure TKMHouseTownHall.SetGoldCnt(aValue: Integer);
var C : Integer;
begin
  C := aValue - CheckWareIn(wtGold);
  WareAddToIn(wtGold, C, true);
end;


procedure TKMHouseTownHall.SetGoldMaxCnt(aValue: Integer);
begin
  fGoldMaxCnt := EnsureRange(aValue, 0, TH_MAX_GOLDMAX_VALUE);
  UpdateDemands;
end;

function TKMHouseTownHall.GetGoldCount: Integer;
begin
  Result := CheckWareIn(wtGold);
end;


function TKMHouseTownHall.CanEquip(aUnitType: TKMUnitType): Boolean;
var
  thUnitIndex: Integer;
begin
  Result := not gHands[Owner].Locks.GetUnitBlocked(aUnitType, True);

  thUnitIndex := GetTHUnitOrderIndex(aUnitType);

  if thUnitIndex <> -1 then
    Result := Result and (GoldCnt >= TH_TROOP_COST[thUnitIndex]);  //Can't equip if we don't have a required resource
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
    //GoldDeliveryCnt := GoldDeliveryCnt - TH_TROOP_COST[thUnitIndex]; //Compensation for GoldDeliveryCnt
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


function TKMHouseTownHall.ShouldAbandonDeliveryTo(aWareType: TKMWareType): Boolean;
begin
  Result := inherited or (aWareType <> wtGold);
  if not Result then
    Result := GoldCnt + gHands[Owner].Deliveries.Queue.GetDeliveriesToHouseCnt(Self, wtGold) > GoldMaxCnt;
end;


end.

