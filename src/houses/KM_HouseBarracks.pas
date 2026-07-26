unit KM_HouseBarracks;
{$I KaM_Remake.inc}
interface
uses
  Classes,
  KM_Houses,
  KM_CommonClasses, KM_Defaults,
  KM_ResTypes;


type
  // Barracks have 11 wares and Recruits
  TKMHouseBarracks = class(TKMHouseWFlagPoint)
  private
    fRecruitsList: TList;
    fResourceCount: array [WARFARE_MIN..WARFARE_MAX] of Word;
    procedure SetWareCnt(aWareType: TKMWareType; aValue: Word);
    procedure RecruitsClear;
    function TakeFirstRecruit: Pointer;
  public
    MapEdRecruitCount: Word; //Only used by MapEd
    NotAcceptFlag: array [WARFARE_MIN .. WARFARE_MAX] of Boolean;
    NotAllowTakeOutFlag: array [WARFARE_MIN .. WARFARE_MAX] of Boolean;
    NotAcceptRecruitFlag: Boolean;
    constructor Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure Save(SaveStream: TKMemoryStream); override;
    procedure SyncLoad; override;
    destructor Destroy; override;

    procedure Activate(aWasBuilt: Boolean); override;
    procedure Demolish(aFrom: TKMHandID; IsSilent: Boolean = False); override;

    procedure WareAddToIn(aWare: TKMWareType; aCount: Integer = 1; aFromScript: Boolean = False); override;
    procedure WareTakeFromOut(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False); override;
    function CheckWareIn(aWare: TKMWareType): Word; override;
    function WareCanAddToIn(aWare: TKMWareType): Boolean; override;

    function ShouldAbandonDeliveryTo(aWareType: TKMWareType): Boolean; override;
    function ShouldAbandonDeliveryFrom(aWareType: TKMWareType; aImmediateCheck: Boolean = False): Boolean; override;
    function ShouldAbandonDeliveryFromTo(aToHouse: TKMHouse; aWareType: TKMWareType; aImmediateCheck: Boolean): Boolean; override;

    function GetTotalWaresCnt: Integer;
    function WareOutputAvailable(aWare: TKMWareType; const aCount: Word): Boolean; override;
    function CanEquip(aUnitType: TKMUnitType): Boolean;
    function RecruitsCount: Integer;
    procedure RecruitsAdd(aUnit: Pointer);
    procedure RecruitsRemove(aUnit: Pointer);
    procedure ToggleNotAcceptFlag(aWare: TKMWareType);
    procedure ToggleNotAcceptAllFlag(aWare: TKMWareType);
    procedure ToggleNotAllowTakeOutFlag(aWare: TKMWareType);
    procedure ToggleNotAllowTakeOutAllFlag(aWare: TKMWareType);
    procedure ToggleAcceptRecruits;
    function EquipWarrior(aUnitType: TKMUnitType): Pointer;
    function Equip(aUnitType: TKMUnitType; aCount: Integer): Integer;
    procedure CreateRecruitInside(aIsMapEd: Boolean);
  end;


implementation
uses
  Math, Types, SysUtils,
  KM_Entity,
  KM_Log,
  KM_Hand,
  KM_HandsCollection,
  KM_HandTypes,
  KM_HandEntity,
  KM_Units,
  KM_UnitWarrior,
  KM_ScriptingEvents,
  KM_ResUnits;


{ TKMHouseBarracks }
constructor TKMHouseBarracks.Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
begin
  inherited;

  fRecruitsList := TList.Create;
end;


constructor TKMHouseBarracks.Load(LoadStream: TKMemoryStream);
var
  I, newCount: Integer;
  U: TKMUnit;
begin
  inherited;

  LoadStream.CheckMarker('HouseBarracks');
  LoadStream.Read(fResourceCount, SizeOf(fResourceCount));
  fRecruitsList := TList.Create;
  LoadStream.Read(newCount);
  for I := 0 to newCount - 1 do
  begin
    LoadStream.Read(U, 4); //subst on syncload
    fRecruitsList.Add(U);
  end;
  LoadStream.Read(NotAcceptFlag, SizeOf(NotAcceptFlag));
  LoadStream.Read(NotAllowTakeOutFlag, SizeOf(NotAllowTakeOutFlag));
  LoadStream.Read(NotAcceptRecruitFlag);
end;


procedure TKMHouseBarracks.SyncLoad;
var
  I: Integer;
  U: TKMUnit;
begin
  inherited;

  //Pointer counters are saved along with the units, hence no GetPointer here
  for I := RecruitsCount - 1 downto 0 do
  begin
    U := gHands.GetUnitByUID(Integer(fRecruitsList.Items[I]));
    if U = nil then
      //Should never happen, but a nil in the list means a crash in EquipWarrior later on
      fRecruitsList.Delete(I)
    else
      fRecruitsList.Items[I] := U;
  end;
end;


destructor TKMHouseBarracks.Destroy;
begin
  FreeAndNil(fRecruitsList);

  inherited;
end;


procedure TKMHouseBarracks.Activate(aWasBuilt: Boolean);
var
  firstBarracks: TKMHouseBarracks;
  WT: TKMWareType;
begin
  inherited;
  //A new Barracks should inherit the accept properies of the first Barracks of that player,
  //which stops a sudden flow of unwanted wares to it as soon as it is created.
  firstBarracks := TKMHouseBarracks(gHands[Owner].FindHouse(htBarracks, 1));
  if (firstBarracks <> nil) and not firstBarracks.IsDestroyed then
  begin
    for WT := WARFARE_MIN to WARFARE_MAX do
    begin
      NotAcceptFlag[WT] := firstBarracks.NotAcceptFlag[WT];
      NotAllowTakeOutFlag[WT] := firstBarracks.NotAllowTakeOutFlag[WT];
    end;
    NotAcceptRecruitFlag := firstBarracks.NotAcceptRecruitFlag;
  end;
end;


procedure TKMHouseBarracks.Demolish(aFrom: TKMHandID; IsSilent: Boolean = False);
var
  W: TKMWareType;
begin
  //Recruits are no longer under our control so we forget about them (UpdateVisibility will sort it out)
  //Otherwise it can cause crashes while saving under the right conditions when a recruit is then killed.
  RecruitsClear;

  for W := WARFARE_MIN to WARFARE_MAX do
    gHands[Owner].Stats.WareConsumed(W, fResourceCount[W]);

  inherited;
end;


procedure TKMHouseBarracks.RecruitsAdd(aUnit: Pointer);
begin
  // Take a counted reference, otherwise the recruit could be freed while he is still in our list
  // (units are freed as soon as their PointerCount is 0) and we would keep a dangling pointer
  fRecruitsList.Add(TKMUnit(aUnit).GetPointer);
end;


function TKMHouseBarracks.RecruitsCount: Integer;
begin
  Result := fRecruitsList.Count;
end;


procedure TKMHouseBarracks.RecruitsRemove(aUnit: Pointer);
var
  U: TKMUnit;
  I: Integer;
begin
  I := fRecruitsList.IndexOf(aUnit);
  if I = -1 then Exit; // Not ours, or he was unregistered already

  U := TKMUnit(fRecruitsList[I]);
  fRecruitsList.Delete(I);
  gHands.CleanUpUnitPointer(U);
end;


// Forget all the recruits, releasing the references we were holding
procedure TKMHouseBarracks.RecruitsClear;
var
  U: TKMUnit;
begin
  for var I := fRecruitsList.Count - 1 downto 0 do
  begin
    U := TKMUnit(fRecruitsList[I]);
    gHands.CleanUpUnitPointer(U);
  end;

  fRecruitsList.Clear;
end;


// Unregister the first recruit who is actually sitting inside this very house and return him.
// The list should never contain anything else, but a stale entry means a crash in KillInHouse,
// hence such entries are dropped here rather than handed out
function TKMHouseBarracks.TakeFirstRecruit: Pointer;
var
  U: TKMUnit;
begin
  Result := nil;

  while (Result = nil) and (fRecruitsList.Count > 0) do
  begin
    U := TKMUnit(fRecruitsList[0]);
    fRecruitsList.Delete(0);

    if (U <> nil) and not U.IsDead and (U is TKMUnitRecruit) and (U.InHouse = Self) then
      Result := U
    else
      gLog.AddTime(Format('TKMHouseBarracks UID %d: dropped an invalid recruit entry', [UID]));

    gHands.CleanUpUnitPointer(U); // Release the reference our list was holding
  end;
end;


procedure TKMHouseBarracks.SetWareCnt(aWareType: TKMWareType; aValue: Word);
var
  cntChange: Integer;
begin
  Assert(aWareType in [WARE_MIN..WARE_MAX]);

  cntChange := aValue - fResourceCount[aWareType];

  fResourceCount[aWareType] := aValue;

  if cntChange <> 0 then
    gScriptEvents.ProcHouseWareCountChanged(Self, aWareType, aValue, cntChange);
end;


procedure TKMHouseBarracks.WareAddToIn(aWare: TKMWareType; aCount: Integer = 1; aFromScript: Boolean = False);
var
  oldCnt: Integer;
begin
  Assert(aWare in [WARFARE_MIN..WARFARE_MAX], 'Invalid ware added to barracks');

  oldCnt := fResourceCount[aWare];
  SetWareCnt(aWare, EnsureRange(fResourceCount[aWare] + aCount, 0, High(Word)));
  gHands[Owner].Deliveries.Queue.AddOffer(Self, aWare, fResourceCount[aWare] - oldCnt);
end;


function TKMHouseBarracks.WareCanAddToIn(aWare: TKMWareType): Boolean;
begin
  Result := (aWare in [WARFARE_MIN..WARFARE_MAX]);
end;


function TKMHouseBarracks.CheckWareIn(aWare: TKMWareType): Word;
begin
  if aWare in [WARFARE_MIN..WARFARE_MAX] then
    Result := fResourceCount[aWare]
  else
    Result := 0; //Including Wood/stone in building stage
end;


procedure TKMHouseBarracks.WareTakeFromOut(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False);
begin
  if aFromScript then
  begin
    aCount := Min(aCount, fResourceCount[aWare]);
    if aCount > 0 then
    begin
      gHands[Owner].Stats.WareConsumed(aWare, aCount);
      gHands[Owner].Deliveries.Queue.RemOffer(Self, aWare, aCount);
    end;
  end;
  Assert(aCount <= fResourceCount[aWare]);
  SetWareCnt(aWare, fResourceCount[aWare] - aCount);
end;


function TKMHouseBarracks.WareOutputAvailable(aWare: TKMWareType; const aCount: Word): Boolean;
begin
  Assert(aWare in [WARFARE_MIN .. WARFARE_MAX]);
  Result := (fResourceCount[aWare] >= aCount);
end;


function TKMHouseBarracks.GetTotalWaresCnt: Integer;
var
  W: TKMWareType;
begin
  Result := 0;
  for W := WARFARE_MIN to WARFARE_MAX do
    Inc(Result, fResourceCount[W]);
end;


procedure TKMHouseBarracks.ToggleNotAcceptFlag(aWare: TKMWareType);
begin
  Assert(aWare in [WARFARE_MIN .. WARFARE_MAX]);

  NotAcceptFlag[aWare] := not NotAcceptFlag[aWare];
end;


procedure TKMHouseBarracks.ToggleNotAcceptAllFlag(aWare: TKMWareType);
var
  ware: TKMWareType;
  accepted: Boolean;

begin
  Assert(aWare in [WARFARE_MIN .. WARFARE_MAX]);

  accepted := not NotAcceptFlag[aWare];

  for ware := Low(fResourceCount) to High(fResourceCount) do
    NotAcceptFlag[ware] := accepted;
end;


procedure TKMHouseBarracks.ToggleNotAllowTakeOutFlag(aWare: TKMWareType);
begin
  Assert(aWare in [WARFARE_MIN .. WARFARE_MAX]);

  NotAllowTakeOutFlag[aWare] := not NotAllowTakeOutFlag[aWare];
end;


procedure TKMHouseBarracks.ToggleNotAllowTakeOutAllFlag(aWare: TKMWareType);
var
  ware: TKMWareType;
  accepted: Boolean;

begin
  Assert(aWare in [WARFARE_MIN .. WARFARE_MAX]);

  accepted := not NotAllowTakeOutFlag[aWare];

  for ware := Low(fResourceCount) to High(fResourceCount) do
    NotAllowTakeOutFlag[ware] := accepted;
end;


function TKMHouseBarracks.ShouldAbandonDeliveryTo(aWareType: TKMWareType): Boolean;
begin
  Result := inherited
            or not (aWareType in [WARFARE_MIN .. WARFARE_MAX])
            or NotAcceptFlag[aWareType];
end;


function TKMHouseBarracks.ShouldAbandonDeliveryFrom(aWareType: TKMWareType; aImmediateCheck: Boolean = False): Boolean;
begin
  Result := inherited or not (aWareType in [WARFARE_MIN .. WARFARE_MAX]);
end;


function TKMHouseBarracks.ShouldAbandonDeliveryFromTo(aToHouse: TKMHouse; aWareType: TKMWareType; aImmediateCheck: Boolean): Boolean;
begin
  Result := inherited
              or (aToHouse = nil)
              //Do not allow delivery from Barracks to other houses except Market/Store/other Barracks
              or not (aToHouse.HouseType in [htMarket, htStore, htBarracks])
              or ((aToHouse.HouseType <> htMarket) //allow delivery to Market with any mode
                //For other houses allow only when dmTakeOut and no flag NotAllowTakeOutFlag
                and ((GetDeliveryModeForCheck(aImmediateCheck) <> dmTakeOut)
                      or NotAllowTakeOutFlag[aWareType])); //Use NewDelivery here, since

end;


procedure TKMHouseBarracks.ToggleAcceptRecruits;
begin
  NotAcceptRecruitFlag := not NotAcceptRecruitFlag;
end;


function TKMHouseBarracks.CanEquip(aUnitType: TKMUnitType): Boolean;
var
  I: Integer;
begin
  Result := RecruitsCount > 0; //Can't equip anything without recruits
  Result := Result and not gHands[Owner].Locks.GetUnitBlocked(aUnitType);

  for I := 1 to 4 do
  if TROOP_COST[aUnitType, I] <> wtNone then //Can't equip if we don't have a required resource
    Result := Result and (fResourceCount[TROOP_COST[aUnitType, I]] > 0);
end;


function TKMHouseBarracks.EquipWarrior(aUnitType: TKMUnitType): Pointer;
var
  I: Integer;
  troopWareType: TKMWareType;
  soldier: TKMUnitWarrior;
  recruit: TKMUnitRecruit;
begin
  Result := nil;

  //Make sure we have enough resources to equip a unit
  if not CanEquip(aUnitType) then Exit;

  //Take the recruit before anything else: if the list turns out to have no valid recruit
  //(should never happen) we must not consume the wares
  recruit := TKMUnitRecruit(TakeFirstRecruit);
  if recruit = nil then Exit;

  //Take resources
  for I := 1 to 4 do
  if TROOP_COST[aUnitType, I] <> wtNone then
  begin
    troopWareType := TROOP_COST[aUnitType, I];
    SetWareCnt(troopWareType, fResourceCount[troopWareType] - 1);

    gHands[Owner].Stats.WareConsumed(TROOP_COST[aUnitType, I]);
    gHands[Owner].Deliveries.Queue.RemOffer(Self, TROOP_COST[aUnitType, I], 1);
  end;

  //Special way to kill the Recruit because it is in a house
  recruit.KillInHouse;

  //Make new unit
  soldier := TKMUnitWarrior(gHands[Owner].TrainUnit(aUnitType, Self));
  soldier.Visible := False; //Make him invisible as he is inside the barracks
  soldier.Condition := Round(TROOPS_TRAINED_CONDITION * UNIT_MAX_CONDITION); //All soldiers start with 3/4, so groups get hungry at the same time
  //Soldier.OrderLoc := KMPointBelow(Entrance); //Position in front of the barracks facing north
  soldier.SetActionGoIn(uaWalk, gdGoOutside, Self);
  if Assigned(soldier.OnUnitTrained) then
    soldier.OnUnitTrained(soldier);

  Result := soldier;
end;


// Equip a new soldier and make him walk out of the house
// Return the number of units successfully equipped
function TKMHouseBarracks.Equip(aUnitType: TKMUnitType; aCount: Integer): Integer;
var
  I: Integer;
  soldier: TKMUnitWarrior;
begin
  Result := 0;
  Assert(aUnitType in [WARRIOR_EQUIPABLE_BARRACKS_MIN..WARRIOR_EQUIPABLE_BARRACKS_MAX]);

  for I := 0 to aCount - 1 do
  begin
    soldier := TKMUnitWarrior(EquipWarrior(aUnitType));
    if soldier = nil then
      Exit;
      
    Inc(Result);
  end;
end;


procedure TKMHouseBarracks.CreateRecruitInside(aIsMapEd: Boolean);
var
  U: TKMUnit;
begin
  if aIsMapEd then
    Inc(MapEdRecruitCount)
  else
  begin
    U := gHands[Owner].TrainUnit(utRecruit, Self);
    U.Visible := False;
    U.Home := Self; //When walking out Home is used to remove recruit from barracks
    RecruitsAdd(U);
    gHands[Owner].Stats.UnitCreated(utRecruit, False);
  end;
end;


procedure TKMHouseBarracks.Save(SaveStream: TKMemoryStream);
var
  I: Integer;
begin
  inherited;

  SaveStream.PlaceMarker('HouseBarracks');
  SaveStream.Write(fResourceCount, SizeOf(fResourceCount));
  SaveStream.Write(RecruitsCount);
  for I := 0 to RecruitsCount - 1 do
    SaveStream.Write(TKMUnit(fRecruitsList.Items[I]).UID); //Store ID
  SaveStream.Write(NotAcceptFlag, SizeOf(NotAcceptFlag));
  SaveStream.Write(NotAllowTakeOutFlag, SizeOf(NotAllowTakeOutFlag));
  SaveStream.Write(NotAcceptRecruitFlag);
end;


end.
