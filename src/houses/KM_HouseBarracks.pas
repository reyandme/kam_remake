unit KM_HouseBarracks;
{$I KaM_Remake.inc}
interface
uses
  Classes,
  KM_Houses,
  KM_ResWares,
  KM_CommonClasses, KM_Defaults,
  KM_ResTypes;


type
  // Barracks have 11 wares and Recruits
  TKMHouseBarracks = class(TKMHouseWFlagPoint)
  private
    fRecruitsList: TList;
    fResourceCount: array [WARFARE_MIN..WARFARE_MAX] of Word;
    procedure SetWareCnt(aWareType: TKMWareType; aValue: Word);
  protected
    function GetFlagPointTexId: Word; override;
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
    procedure ResAddToIn(aWare: TKMWareType; aCount: Integer = 1; aFromScript: Boolean = False); override;
    procedure ResTakeFromOut(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False); override;
    function CheckResIn(aWare: TKMWareType): Word; override;
    function ResCanAddToIn(aRes: TKMWareType): Boolean; override;

    function ShouldAbandonDeliveryTo(aWareType: TKMWareType): Boolean; override;
    function ShouldAbandonDeliveryFrom(aWareType: TKMWareType; aImmidiateCheck: Boolean = False): Boolean; override;
    function ShouldAbandonDeliveryFromTo(aToHouse: TKMHouse; aWareType: TKMWareType; aImmidiateCheck: Boolean): Boolean; override;

    function GetTotalWaresCnt: Integer;
    function ResOutputAvailable(aRes: TKMWareType; const aCount: Word): Boolean; override;
    function CanEquip(aUnitType: TKMUnitType): Boolean;
    function RecruitsCount: Integer;
    procedure RecruitsAdd(aUnit: Pointer);
    procedure RecruitsRemove(aUnit: Pointer);
    procedure ToggleNotAcceptFlag(aRes: TKMWareType);
    procedure ToggleNotAllowTakeOutFlag(aRes: TKMWareType);
    procedure ToggleAcceptRecruits;
    function EquipWarrior(aUnitType: TKMUnitType): Pointer;
    function Equip(aUnitType: TKMUnitType; aCount: Integer): Integer;
    procedure CreateRecruitInside(aIsMapEd: Boolean);
  end;


implementation
uses
  Math, Types,
  KM_Hand,
  KM_HandsCollection,
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
begin
  inherited;

  for I := 0 to RecruitsCount - 1 do
    fRecruitsList.Items[I] := gHands.GetUnitByUID(Cardinal(fRecruitsList.Items[I]));
end;


destructor TKMHouseBarracks.Destroy;
begin
  fRecruitsList.Free;

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
  fRecruitsList.Clear;

  for W := WARFARE_MIN to WARFARE_MAX do
    gHands[Owner].Stats.WareConsumed(W, fResourceCount[W]);

  inherited;
end;


procedure TKMHouseBarracks.RecruitsAdd(aUnit: Pointer);
begin
  fRecruitsList.Add(aUnit);
end;


function TKMHouseBarracks.RecruitsCount: Integer;
begin
  Result := fRecruitsList.Count;
end;


procedure TKMHouseBarracks.RecruitsRemove(aUnit: Pointer);
begin
  fRecruitsList.Remove(aUnit);
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


procedure TKMHouseBarracks.ResAddToIn(aWare: TKMWareType; aCount: Integer = 1; aFromScript: Boolean = False);
var
  oldCnt: Integer;
begin
  Assert(aWare in [WARFARE_MIN..WARFARE_MAX], 'Invalid resource added to barracks');

  oldCnt := fResourceCount[aWare];
  SetWareCnt(aWare, EnsureRange(fResourceCount[aWare] + aCount, 0, High(Word)));
  gHands[Owner].Deliveries.Queue.AddOffer(Self, aWare, fResourceCount[aWare] - oldCnt);
end;


function TKMHouseBarracks.ResCanAddToIn(aRes: TKMWareType): Boolean;
begin
  Result := (aRes in [WARFARE_MIN..WARFARE_MAX]);
end;


function TKMHouseBarracks.CheckResIn(aWare: TKMWareType): Word;
begin
  if aWare in [WARFARE_MIN..WARFARE_MAX] then
    Result := fResourceCount[aWare]
  else
    Result := 0; //Including Wood/stone in building stage
end;


procedure TKMHouseBarracks.ResTakeFromOut(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False);
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


function TKMHouseBarracks.ResOutputAvailable(aRes: TKMWareType; const aCount: Word): Boolean;
begin
  Assert(aRes in [WARFARE_MIN .. WARFARE_MAX]);
  Result := (fResourceCount[aRes] >= aCount);
end;


function TKMHouseBarracks.GetTotalWaresCnt: Integer;
var
  W: TKMWareType;
begin
  Result := 0;
  for W := WARFARE_MIN to WARFARE_MAX do
    Inc(Result, fResourceCount[W]);
end;


procedure TKMHouseBarracks.ToggleNotAcceptFlag(aRes: TKMWareType);
begin
  Assert(aRes in [WARFARE_MIN .. WARFARE_MAX]);

  NotAcceptFlag[aRes] := not NotAcceptFlag[aRes];
end;


procedure TKMHouseBarracks.ToggleNotAllowTakeOutFlag(aRes: TKMWareType);
begin
  Assert(aRes in [WARFARE_MIN .. WARFARE_MAX]);

  NotAllowTakeOutFlag[aRes] := not NotAllowTakeOutFlag[aRes];
end;


function TKMHouseBarracks.GetFlagPointTexId: Word;
begin
  Result := 249;
end;


function TKMHouseBarracks.ShouldAbandonDeliveryTo(aWareType: TKMWareType): Boolean;
begin
  Result := inherited
            or not (aWareType in [WARFARE_MIN .. WARFARE_MAX])
            or NotAcceptFlag[aWareType];
end;


function TKMHouseBarracks.ShouldAbandonDeliveryFrom(aWareType: TKMWareType; aImmidiateCheck: Boolean = False): Boolean;
begin
  Result := inherited or not (aWareType in [WARFARE_MIN .. WARFARE_MAX]);
end;


function TKMHouseBarracks.ShouldAbandonDeliveryFromTo(aToHouse: TKMHouse; aWareType: TKMWareType; aImmidiateCheck: Boolean): Boolean;
begin
  Result := inherited
              or (aToHouse = nil)
              //Do not allow delivery from Barracks to other houses except Market/Store/other Barracks
              or not (aToHouse.HouseType in [htMarket, htStore, htBarracks])
              or ((aToHouse.HouseType <> htMarket) //allow delivery to Market with any mode
                //For other houses allow only when dmTakeOut and no flag NotAllowTakeOutFlag
                and ((GetDeliveryModeForCheck(aImmidiateCheck) <> dmTakeOut)
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
begin
  Result := nil;

  //Make sure we have enough resources to equip a unit
  if not CanEquip(aUnitType) then Exit;

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
  TKMUnitRecruit(fRecruitsList.Items[0]).KillInHouse;
  fRecruitsList.Delete(0); //Delete first recruit in the list

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
