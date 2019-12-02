unit KM_HouseCollection;
{$I KaM_Remake.inc}
interface
uses
  Classes,
  KM_Houses,
  KM_ResHouses,
  KM_CommonClasses, KM_Defaults, KM_Points;

type
  TKMHousesCollection = class
  private
    fHouses: TKMList; //Private to hide methods we don't want to expose
    function AddToCollection(aHouseType: TKMHouseType; PosX,PosY: Integer; aOwner: TKMHandID; aHBS: TKMHouseBuildState):TKMHouse;
    function GetHouse(aIndex: Integer): TKMHouse; inline;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function AddHouse(aHouseType: TKMHouseType; PosX,PosY: Integer; aOwner: TKMHandID; RelativeEntrance: Boolean):TKMHouse;
    function AddHouseWIP(aHouseType: TKMHouseType; PosX,PosY: Integer; aOwner: TKMHandID): TKMHouse;
    procedure AddHouseToList(aHouse: TKMHouse);
    property Count: Integer read GetCount;
    procedure OwnerUpdate(aOwner: TKMHandID);
    property Houses[aIndex: Integer]: TKMHouse read GetHouse; default;
    function HitTest(X, Y: Integer): TKMHouse;
    function GetHouseByUID(aUID: Integer): TKMHouse;
    procedure GetHousesInRect(const aRect: TKMRect; List: TList);
    function FindEmptyHouse(aUnitType: TKMUnitType; const Loc: TKMPoint): TKMHouse;
    function FindHouse(aType: TKMHouseType; X,Y: Word; const aIndex: Byte = 1; aOnlyCompleted: Boolean = True): TKMHouse; overload;
    function FindHouse(const aTypes: THouseTypeSet; X,Y: Word; const aIndex: Byte = 1; aOnlyCompleted: Boolean = True): TKMHouse; overload;
    function FindHousesInRadius(aLoc: TKMPoint; aSqrRadius: Single; aTypes: THouseTypeSet; aOnlyCompleted: Boolean = True): TKMHouseArray;
    function GetTotalPointers: Cardinal;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad;
    procedure IncAnimStep;
    procedure UpdateResRequest; //Change resource requested counts for all houses
    procedure DeleteHouseFromList(aHouse: TKMHouse);
    procedure RemoveAllHouses;

    procedure UpdateState(aTick: Cardinal);
    procedure Paint(const aRect: TKMRect);
  end;


implementation
uses
  SysUtils, Types, Math,
  KM_Game, KM_Terrain,
  KM_HouseInn, KM_HouseMarket, KM_HouseBarracks, KM_HouseSchool, 
  KM_HouseTownHall, KM_HouseWoodcutters,
  KM_Resource,
  KM_GameTypes;


{ TKMHousesCollection }
constructor TKMHousesCollection.Create;
begin
  inherited;
  fHouses := TKMList.Create;
end;


destructor TKMHousesCollection.Destroy;
begin
  fHouses.Free;
  inherited;
end;


function TKMHousesCollection.AddToCollection(aHouseType: TKMHouseType; PosX,PosY: Integer; aOwner: TKMHandID; aHBS: TKMHouseBuildState): TKMHouse;
var ID: Cardinal;
begin
  ID := gGame.GetNewUID;

  case aHouseType of
    htSwine,
    htStables:       Result := TKMHouseSwineStable.Create(ID, aHouseType,PosX,PosY, aOwner, aHBS);
    htInn:           Result := TKMHouseInn.Create(ID, aHouseType,PosX,PosY, aOwner, aHBS);
    htMarketplace:   Result := TKMHouseMarket.Create(ID, aHouseType,PosX,PosY, aOwner, aHBS);
    htSchool:        Result := TKMHouseSchool.Create(ID, aHouseType,PosX,PosY, aOwner, aHBS);
    htBarracks:      Result := TKMHouseBarracks.Create(ID, aHouseType,PosX,PosY, aOwner, aHBS);
    htTownHall:      Result := TKMHouseTownHall.Create(ID, aHouseType,PosX,PosY, aOwner, aHBS);
    htStore:         Result := TKMHouseStore.Create(ID, aHouseType,PosX,PosY, aOwner, aHBS);
    htWatchTower:    Result := TKMHouseTower.Create(ID, aHouseType,PosX,PosY, aOwner, aHBS);
    htWoodcutters:   Result := TKMHouseWoodcutters.Create(ID, aHouseType,PosX,PosY, aOwner, aHBS);
    htArmorWorkshop: Result := TKMHouseArmorWorkshop.Create(ID, aHouseType,PosX,PosY, aOwner, aHBS);
    else              Result := TKMHouse.Create(ID, aHouseType,PosX,PosY, aOwner, aHBS);
  end;

  if Result <> nil then
    fHouses.Add(Result);
end;


function TKMHousesCollection.GetCount: Integer;
begin
  Result := fHouses.Count;
end;


function TKMHousesCollection.GetHouse(aIndex: Integer): TKMHouse;
begin
  Result := fHouses[aIndex];
end;


function TKMHousesCollection.AddHouse(aHouseType: TKMHouseType; PosX,PosY: Integer; aOwner: TKMHandID; RelativeEntrance: Boolean):TKMHouse;
begin
  if RelativeEntrance then
    Result := AddToCollection(aHouseType, PosX - gRes.Houses[aHouseType].EntranceOffsetX, PosY, aOwner, hbsDone)
  else
    Result := AddToCollection(aHouseType, PosX, PosY, aOwner, hbsDone);
end;


{Add a plan for house}
function TKMHousesCollection.AddHouseWIP(aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID): TKMHouse;
begin
  Result := AddToCollection(aHouseType, PosX, PosY, aOwner, hbsNoGlyph);
end;


procedure TKMHousesCollection.AddHouseToList(aHouse: TKMHouse);
begin
  Assert(gGame.GameMode = gmMapEd); // Allow to add existing House directly only in MapEd
  if (aHouse <> nil) then
    fHouses.Add(aHouse);
end;


//Delete pointer to House in List
procedure TKMHousesCollection.DeleteHouseFromList(aHouse: TKMHouse);
begin
  Assert(gGame.GameMode = gmMapEd); // Allow to delete existing House directly only in MapEd
  if (aHouse <> nil) then
    fHouses.Extract(aHouse);
end;


procedure TKMHousesCollection.RemoveAllHouses;
var I: Integer;
begin
  Assert(gGame.GameMode = gmMapEd);
  if Count <= 0 then Exit;

  for I := 0 to Count - 1 do
    Houses[I].DemolishHouse(Houses[I].Owner, True);

  fHouses.Clear;
end;


procedure TKMHousesCollection.OwnerUpdate(aOwner: TKMHandID);
var I: Integer;
begin
  for I := 0 to Count - 1 do
    Houses[I].OwnerUpdate(aOwner);
end;


function TKMHousesCollection.HitTest(X, Y: Integer): TKMHouse;
var I: Integer;
begin
  Result:= nil;
  for I := 0 to Count - 1 do
    if Houses[I].HitTest(X, Y) and (not Houses[I].IsDestroyed) then
    begin
      Result := Houses[I];
      Break;
    end;
end;


function TKMHousesCollection.GetHouseByUID(aUID: Integer): TKMHouse;
var I: Integer;
begin
  Result := nil;
  for I := 0 to Count - 1 do
    if aUID = Houses[I].UID then
    begin
      Result := Houses[I];
      Exit;
    end;
end;


procedure TKMHousesCollection.GetHousesInRect(const aRect: TKMRect; List: TList);
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if KMInRect(Houses[I].Entrance, aRect) and not Houses[I].IsDestroyed then
      List.Add(Houses[I]);
end;


//Should find closest house to Loc
function TKMHousesCollection.FindEmptyHouse(aUnitType: TKMUnitType; const Loc: TKMPoint): TKMHouse;
var
  I: Integer;
  Dist, BestBid: Single;
begin
  Result := nil;
  BestBid := MaxSingle;

  for I := 0 to Count - 1 do
    if (gRes.Houses[Houses[I].HouseType].OwnerType = aUnitType) and // If Unit can work in here
       not Houses[I].HasOwner and                                   // if there's yet no owner
       not Houses[I].IsDestroyed and                                // if house is not destroyed
       Houses[I].IsComplete and                                     // if house is built
       not Houses[I].IsClosedForWorker then                         // if house is not closed for worker
    begin
      //Recruits should not go to a barracks with ware delivery switched off or with not accept flag for recruits
      if (Houses[I].HouseType = htBarracks)
        and ((Houses[I].DeliveryMode <> dmDelivery) or (TKMHouseBarracks(Houses[I]).NotAcceptRecruitFlag)) then Continue;
      if not gTerrain.Route_CanBeMade(Loc, Houses[I].PointBelowEntrance, tpWalk, 0) then Continue;

      Dist := KMLengthSqr(Loc, Houses[I].Position);

      //Always prefer Towers to Barracks by making Barracks Bid much less attractive
      //In case of multiple barracks, prefer the closer one (players should make multiple schools or use WareDelivery to control it)
      if Houses[I].HouseType = htBarracks then
        Dist := Dist * 1000;

      if Dist < BestBid then
      begin
        BestBid := Dist;
        Result := Houses[I];
      end;

    end;

  if (Result <> nil) and (Result.HouseType <> htBarracks) then
    Result.HasOwner := True; //Become owner except Barracks;
end;


function TKMHousesCollection.FindHouse(aType: TKMHouseType; X, Y: word; const aIndex: Byte = 1; aOnlyCompleted: Boolean = True): TKMHouse;
var HT: THouseTypeSet;
begin
  if aType = htAny then HT := [Low(TKMHouseType)..High(TKMHouseType)]
  else                   HT := [aType];
  Result := FindHouse(HT, X, Y, aIndex, aOnlyCompleted);
end;


//Find closest house to given position
//or
//Find house by index (1st, 2nd)
function TKMHousesCollection.FindHouse(const aTypes: THouseTypeSet; X, Y: word; const aIndex: Byte = 1; aOnlyCompleted: Boolean = True): TKMHouse;
var
  I,ID: Integer;
  UsePosition: Boolean;
  BestMatch,Dist: Single;
begin
  Result := nil;
  ID := 0;
  BestMatch := MaxSingle; //Any distance will be closer than that
  UsePosition := X*Y <> 0; //Calculate this once to save computing lots of multiplications
  Assert((not UsePosition) or (aIndex = 1), 'Can''t find house basing both on Position and Index');

  for I := 0 to Count - 1 do
  if (Houses[I].HouseType in aTypes)
  and (Houses[I].IsComplete or not aOnlyCompleted)
  and not Houses[I].IsDestroyed then
  begin
    Inc(ID);
    if UsePosition then
    begin
      Dist := KMLengthSqr(Houses[I].Position,KMPoint(X,Y));
      if BestMatch = -1 then BestMatch := Dist; //Initialize for first use
      if Dist < BestMatch then
      begin
        BestMatch := Dist;
        Result := Houses[I];
      end;
    end
    else
      //Take the N-th result
      if aIndex = ID then
      begin
        Result := Houses[I];
        Exit;
      end;
  end;
end;


function TKMHousesCollection.FindHousesInRadius(aLoc: TKMPoint; aSqrRadius: Single; aTypes: THouseTypeSet; aOnlyCompleted: Boolean = True): TKMHouseArray;
var
  I,Idx: Integer;
begin
  SetLength(Result, 12);
  Idx := 0;
  for I := 0 to Count - 1 do
    if (Houses[I].HouseType in aTypes)
      AND (not aOnlyCompleted OR Houses[I].IsComplete)
      AND not Houses[I].IsDestroyed then
    begin
      if (KMLengthSqr(Houses[I].Position, aLoc) <= aSqrRadius) then
      begin
        if (Idx >= Length(Result)) then
          SetLength(Result, Idx + 12);
        Result[Idx] := Houses[I];
        Idx := Idx + 1;
      end;
    end;
  SetLength(Result,Idx);
end;


procedure TKMHousesCollection.Save(SaveStream: TKMemoryStream);
var I: Integer;
begin
  SaveStream.PlaceMarker('Houses');

  SaveStream.Write(Count);
  for I := 0 to Count - 1 do
  begin
    //We save house type to know which house class to load
    SaveStream.Write(Houses[I].HouseType, SizeOf(Houses[I].HouseType));
    Houses[I].Save(SaveStream);
  end;
end;


procedure TKMHousesCollection.Load(LoadStream: TKMemoryStream);
var
  I, NewCount: Integer;
  HouseType: TKMHouseType;
  T: TKMHouse;
begin
  LoadStream.CheckMarker('Houses');

  LoadStream.Read(NewCount);
  for I := 0 to NewCount - 1 do
  begin
    LoadStream.Read(HouseType, SizeOf(HouseType));
    case HouseType of
      htSwine,
      htStables:       T := TKMHouseSwineStable.Load(LoadStream);
      htInn:           T := TKMHouseInn.Load(LoadStream);
      htMarketplace:   T := TKMHouseMarket.Load(LoadStream);
      htSchool:        T := TKMHouseSchool.Load(LoadStream);
      htBarracks:      T := TKMHouseBarracks.Load(LoadStream);
      htStore:         T := TKMHouseStore.Load(LoadStream);
      htWatchTower:    T := TKMHouseTower.Load(LoadStream);
      htWoodcutters:   T := TKMHouseWoodcutters.Load(LoadStream);
      htArmorWorkshop: T := TKMHouseArmorWorkshop.Load(LoadStream);
      htTownHall:      T := TKMHouseTownHall.Load(LoadStream);
      else              T := TKMHouse.Load(LoadStream);
    end;

    if T <> nil then
      fHouses.Add(T);
  end;
end;


procedure TKMHousesCollection.SyncLoad;
var I: Integer;
begin
  for I := 0 to Count - 1 do
    Houses[I].SyncLoad;
end;


//Update resource requested counts for all houses
procedure TKMHousesCollection.UpdateResRequest;
var I: Integer;
begin
  for I := 0 to Count - 1 do
  if Houses[I].IsComplete and not Houses[I].IsDestroyed then
    Houses[I].UpdateResRequest;
end;


procedure TKMHousesCollection.UpdateState(aTick: Cardinal);
var
  I: Integer;
begin
  for I := Count - 1 downto 0  do
    if not Houses[I].IsDestroyed then
      Houses[I].UpdateState(aTick)
    else
      if FREE_POINTERS and (Houses[I].PointerCount = 0) then
        fHouses.Delete(I); //Because no one needs this anymore it must DIE!!!!! :D
end;


procedure TKMHousesCollection.IncAnimStep;
var I: Integer;
begin
  for I := 0 to Count - 1 do
    Houses[I].IncAnimStep;
end;


function TKMHousesCollection.GetTotalPointers: Cardinal;
var I: Integer;
begin
  Result := 0;
  for I := 0 to Count - 1 do
    Result := Result + Houses[I].PointerCount;
end;


procedure TKMHousesCollection.Paint(const aRect: TKMRect);
const
  Margin = 3;
var
  I: Integer;
  growRect: TKMRect;
begin
  //Compensate for big houses near borders or standing on hills
  growRect := KMRectGrow(aRect, Margin);

  for I := 0 to Count - 1 do
  if not Houses[I].IsDestroyed and KMInRect(Houses[I].Position, growRect) then
    Houses[I].Paint;
end;


end.
