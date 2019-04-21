unit KM_HouseBarracks;
{$I KaM_Remake.inc}
interface
uses
  Classes,
  KM_Houses,
  KM_ResWares, KM_ResHouses,
  KM_CommonClasses, KM_Defaults, KM_Points;


type
  //Barracks have 11 resources and Recruits
  TKMHouseBarracks = class(TKMHouseWFlagPoint)
  private
    fRecruitsList: TList;
    fResourceCount: array [WARFARE_MIN..WARFARE_MAX] of Word;
  protected
    function GetFlagPointTexId: Word; override;
  public
    MapEdRecruitCount: Word; //Only used by MapEd
    NotAcceptFlag: array [WARFARE_MIN .. WARFARE_MAX] of Boolean;
    NotAcceptRecruitFlag: Boolean;
    constructor Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure Save(SaveStream: TKMemoryStream); override;
    procedure SyncLoad; override;
    destructor Destroy; override;

    procedure Activate(aWasBuilt: Boolean); override;
    procedure DemolishHouse(aFrom: TKMHandID; IsSilent: Boolean = False); override;
    procedure ResAddToIn(aWare: TKMWareType; aCount: Integer = 1; aFromScript: Boolean = False); override;
    procedure ResTakeFromOut(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False); override;
    function CheckResIn(aWare: TKMWareType): Word; override;
    function ResCanAddToIn(aRes: TKMWareType): Boolean; override;

    function ShouldAbandonDelivery(aWareType: TKMWareType): Boolean; override;

    function ResOutputAvailable(aRes: TKMWareType; const aCount: Word): Boolean; override;
    function CanEquip(aUnitType: TKMUnitType): Boolean;
    function RecruitsCount: Integer;
    procedure RecruitsAdd(aUnit: Pointer);
    procedure RecruitsRemove(aUnit: Pointer);
    procedure ToggleAcceptFlag(aRes: TKMWareType);
    procedure ToggleAcceptRecruits;
    function Equip(aUnitType: TKMUnitType; aCount: Integer): Integer;
    procedure CreateRecruitInside(aIsMapEd: Boolean);
  end;


implementation
uses
  Math, Types,
  KM_Hand, KM_HandsCollection, KM_Terrain,
  KM_Units, KM_UnitWarrior,
  KM_ResUnits;


{ TKMHouseBarracks }
constructor TKMHouseBarracks.Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
begin
  inherited;

  fRecruitsList := TList.Create;
end;


constructor TKMHouseBarracks.Load(LoadStream: TKMemoryStream);
var
  I, NewCount: Integer;
  U: TKMUnit;
begin
  inherited;

  LoadStream.Read(fResourceCount, SizeOf(fResourceCount));
  fRecruitsList := TList.Create;
  LoadStream.Read(NewCount);
  for I := 0 to NewCount - 1 do
  begin
    LoadStream.Read(U, 4); //subst on syncload
    fRecruitsList.Add(U);
  end;
  LoadStream.Read(NotAcceptFlag, SizeOf(NotAcceptFlag));
  LoadStream.Read(NotAcceptRecruitFlag);
end;


procedure TKMHouseBarracks.SyncLoad;
var I: Integer;
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
  FirstBarracks: TKMHouseBarracks;
  WT: TKMWareType;
begin
  inherited;
  //A new Barracks should inherit the accept properies of the first Barracks of that player,
  //which stops a sudden flow of unwanted wares to it as soon as it is created.
  FirstBarracks := TKMHouseBarracks(gHands[fOwner].FindHouse(htBarracks, 1));
  if (FirstBarracks <> nil) and not FirstBarracks.IsDestroyed then
  begin
    for WT := WARFARE_MIN to WARFARE_MAX do
      NotAcceptFlag[WT] := FirstBarracks.NotAcceptFlag[WT];
    NotAcceptRecruitFlag := FirstBarracks.NotAcceptRecruitFlag;
  end;
end;


procedure TKMHouseBarracks.DemolishHouse(aFrom: TKMHandID; IsSilent: Boolean = False);
var
  R: TKMWareType;
begin
  //Recruits are no longer under our control so we forget about them (UpdateVisibility will sort it out)
  //Otherwise it can cause crashes while saving under the right conditions when a recruit is then killed.
  fRecruitsList.Clear;

  for R := WARFARE_MIN to WARFARE_MAX do
    gHands[fOwner].Stats.WareConsumed(R, fResourceCount[R]);

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


procedure TKMHouseBarracks.ResAddToIn(aWare: TKMWareType; aCount: Integer = 1; aFromScript: Boolean = False);
var
  OldCnt: Integer;
begin
  Assert(aWare in [WARFARE_MIN..WARFARE_MAX], 'Invalid resource added to barracks');

  OldCnt := fResourceCount[aWare];
  fResourceCount[aWare] := EnsureRange(fResourceCount[aWare] + aCount, 0, High(Word));
  gHands[fOwner].Deliveries.Queue.AddOffer(Self, aWare, fResourceCount[aWare] - OldCnt);
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
      gHands[fOwner].Stats.WareConsumed(aWare, aCount);
      gHands[fOwner].Deliveries.Queue.RemOffer(Self, aWare, aCount);
    end;
  end;
  Assert(aCount <= fResourceCount[aWare]);
  Dec(fResourceCount[aWare], aCount);
end;


function TKMHouseBarracks.ResOutputAvailable(aRes: TKMWareType; const aCount: Word): Boolean;
begin
  Assert(aRes in [WARFARE_MIN .. WARFARE_MAX]);
  Result := (fResourceCount[aRes] >= aCount);
end;


procedure TKMHouseBarracks.ToggleAcceptFlag(aRes: TKMWareType);
begin
  Assert(aRes in [WARFARE_MIN .. WARFARE_MAX]);

  NotAcceptFlag[aRes] := not NotAcceptFlag[aRes];
end;


function TKMHouseBarracks.GetFlagPointTexId: Word;
begin
  Result := 249;
end;


function TKMHouseBarracks.ShouldAbandonDelivery(aWareType: TKMWareType): Boolean;
begin
  Result := inherited or not (aWareType in [WARFARE_MIN .. WARFARE_MAX]) or NotAcceptFlag[aWareType];
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
  Result := Result and not gHands[fOwner].Locks.GetUnitBlocked(aUnitType);

  for I := 1 to 4 do
  if TROOP_COST[aUnitType, I] <> wtNone then //Can't equip if we don't have a required resource
    Result := Result and (fResourceCount[TROOP_COST[aUnitType, I]] > 0);
end;


//Equip a new soldier and make him walk out of the house
//Return the number of units successfully equipped
function TKMHouseBarracks.Equip(aUnitType: TKMUnitType; aCount: Integer): Integer;
var
  I, K: Integer;
  Soldier: TKMUnitWarrior;
begin
  Result := 0;
  Assert(aUnitType in [WARRIOR_EQUIPABLE_MIN..WARRIOR_EQUIPABLE_MAX]);

  for K := 0 to aCount - 1 do
  begin
    //Make sure we have enough resources to equip a unit
    if not CanEquip(aUnitType) then Exit;

    //Take resources
    for I := 1 to 4 do
    if TROOP_COST[aUnitType, I] <> wtNone then
    begin
      Dec(fResourceCount[TROOP_COST[aUnitType, I]]);
      gHands[fOwner].Stats.WareConsumed(TROOP_COST[aUnitType, I]);
      gHands[fOwner].Deliveries.Queue.RemOffer(Self, TROOP_COST[aUnitType, I], 1);
    end;

    //Special way to kill the Recruit because it is in a house
    TKMUnitRecruit(fRecruitsList.Items[0]).KillInHouse;
    fRecruitsList.Delete(0); //Delete first recruit in the list

    //Make new unit
    Soldier := TKMUnitWarrior(gHands[fOwner].TrainUnit(aUnitType, Entrance));
    Soldier.InHouse := Self; //Put him in the barracks, so if it is destroyed while he is inside he is placed somewhere
    Soldier.Visible := False; //Make him invisible as he is inside the barracks
    Soldier.Condition := Round(TROOPS_TRAINED_CONDITION * UNIT_MAX_CONDITION); //All soldiers start with 3/4, so groups get hungry at the same time
    //Soldier.OrderLoc := KMPointBelow(Entrance); //Position in front of the barracks facing north
    Soldier.SetActionGoIn(uaWalk, gdGoOutside, Self);
    if Assigned(Soldier.OnUnitTrained) then
      Soldier.OnUnitTrained(Soldier);
    Inc(Result);
  end;
end;


procedure TKMHouseBarracks.CreateRecruitInside(aIsMapEd: Boolean);
var U: TKMUnit;
begin
  if aIsMapEd then
    Inc(MapEdRecruitCount)
  else
  begin
    U := gHands[fOwner].TrainUnit(utRecruit, Entrance);
    U.Visible := False;
    U.InHouse := Self;
    U.Home := Self; //When walking out Home is used to remove recruit from barracks
    RecruitsAdd(U);
    gHands[fOwner].Stats.UnitCreated(utRecruit, False);
  end;
end;


procedure TKMHouseBarracks.Save(SaveStream: TKMemoryStream);
var
  I: Integer;
begin
  inherited;

  SaveStream.Write(fResourceCount, SizeOf(fResourceCount));
  SaveStream.Write(RecruitsCount);
  for I := 0 to RecruitsCount - 1 do
    SaveStream.Write(TKMUnit(fRecruitsList.Items[I]).UID); //Store ID
  SaveStream.Write(NotAcceptFlag, SizeOf(NotAcceptFlag));
  SaveStream.Write(NotAcceptRecruitFlag);
end;


end.
