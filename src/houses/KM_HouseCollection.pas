unit KM_HouseCollection;
{$I KaM_Remake.inc}
interface
uses
  Classes, Generics.Collections,
  KM_Houses,
  KM_ResHouses,
  KM_CommonClasses, KM_Defaults, KM_Points,
  KM_ResTypes;

type
  TKMHousesCollection = class
  private
    fHouses: TKMList; //Private to hide methods we don't want to expose

    procedure DoAddHouse(aHouse: TKMHouse);
    function AddToCollection(aHouseType: TKMHouseType; aPosX, aPosY: Integer; aOwner: TKMHandID; aHBS: TKMHouseBuildState):TKMHouse;
    function GetHouse(aIndex: Integer): TKMHouse; inline;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    function AddHouse(aHouseType: TKMHouseType; aPosX, aPosY: Integer; aOwner: TKMHandID; aRelativeEntrance: Boolean):TKMHouse;
    function AddHouseWIP(aHouseType: TKMHouseType; aPosX, aPosY: Integer; aOwner: TKMHandID): TKMHouse;
    procedure AddHouseToList(aHouse: TKMHouse);
    property Count: Integer read GetCount;
    procedure OwnerUpdate(aOwner: TKMHandID);
    property Houses[aIndex: Integer]: TKMHouse read GetHouse; default;
    function HitTest(X, Y: Integer): TKMHouse;
    function GetHouseByUID(aUID: Integer): TKMHouse;
    procedure GetHousesInRect(const aRect: TKMRect; aList: TList<TKMHouse>);
    function FindEmptyHouse(aUnitType: TKMUnitType; const aLoc: TKMPoint): TKMHouse;
    function FindHouse(aType: TKMHouseType; X, Y: Word; const aIndex: Byte = 1; aOnlyCompleted: Boolean = True): TKMHouse; overload;
    function FindHouse(const aTypes: TKMHouseTypeSet; X, Y: Word; const aIndex: Byte = 1; aOnlyCompleted: Boolean = True): TKMHouse; overload;
    function FindHousesInRadius(aLoc: TKMPoint; aSqrRadius: Single; aTypes: TKMHouseTypeSet; aOnlyCompleted: Boolean = True): TKMHouseArray;
    function GetTotalPointers: Cardinal;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad;
    procedure IncAnimStep;
    procedure UpdateResRequest; //Change resource requested counts for all houses
    procedure DeleteHouseFromList(aHouse: TKMHouse);
    procedure RemoveAllHouses;
    procedure RemoveHousesOutOfBounds(const aInsetRect: TKMRect);

    procedure UpdateState(aTick: Cardinal);
    procedure Paint(const aRect: TKMRect);
  end;


implementation
uses
  SysUtils, Types, Math,
  KM_Game, KM_GameParams, KM_Terrain,
  KM_HouseInn, KM_HouseMarket, KM_HouseBarracks, KM_HouseSchool, KM_HouseStore, KM_HouseArmorWorkshop, KM_HouseSwineStable,
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


procedure TKMHousesCollection.Clear;
begin
  fHouses.Clear;
end;


// Center point of adding to the collection
procedure TKMHousesCollection.DoAddHouse(aHouse: TKMHouse);
begin
  fHouses.Add(aHouse);
  aHouse.OnShowGameMessage := gGame.ShowMessage; // set show message handler. We don't want to KM_House to be dependant unit of KM_Game
end;


function TKMHousesCollection.AddToCollection(aHouseType: TKMHouseType; aPosX, aPosY: Integer; aOwner: TKMHandID; aHBS: TKMHouseBuildState): TKMHouse;
var
  uid: Cardinal;
begin
  uid := gGame.GetNewUID;

  case aHouseType of
    htSwine,
    htStables:       Result := TKMHouseSwineStable.Create(uid, aHouseType,aPosX,aPosY, aOwner, aHBS);
    htInn:           Result := TKMHouseInn.Create(uid, aHouseType,aPosX,aPosY, aOwner, aHBS);
    htMarket:   Result := TKMHouseMarket.Create(uid, aHouseType,aPosX,aPosY, aOwner, aHBS);
    htSchool:        Result := TKMHouseSchool.Create(uid, aHouseType,aPosX,aPosY, aOwner, aHBS);
    htBarracks:      Result := TKMHouseBarracks.Create(uid, aHouseType,aPosX,aPosY, aOwner, aHBS);
    htTownHall:      Result := TKMHouseTownHall.Create(uid, aHouseType,aPosX,aPosY, aOwner, aHBS);
    htStore:         Result := TKMHouseStore.Create(uid, aHouseType,aPosX,aPosY, aOwner, aHBS);
    htWatchTower:    Result := TKMHouseTower.Create(uid, aHouseType,aPosX,aPosY, aOwner, aHBS);
    htWoodcutters:   Result := TKMHouseWoodcutters.Create(uid, aHouseType,aPosX,aPosY, aOwner, aHBS);
    htArmorWorkshop: Result := TKMHouseArmorWorkshop.Create(uid, aHouseType,aPosX,aPosY, aOwner, aHBS);
    else             Result := TKMHouse.Create(uid, aHouseType,aPosX,aPosY, aOwner, aHBS);
  end;

  if Result <> nil then
    DoAddHouse(Result);
end;


function TKMHousesCollection.GetCount: Integer;
begin
  Result := fHouses.Count;
end;


function TKMHousesCollection.GetHouse(aIndex: Integer): TKMHouse;
begin
  Result := fHouses[aIndex];
end;


function TKMHousesCollection.AddHouse(aHouseType: TKMHouseType; aPosX, aPosY: Integer; aOwner: TKMHandID; aRelativeEntrance: Boolean):TKMHouse;
begin
  if aRelativeEntrance then
    Result := AddToCollection(aHouseType, aPosX - gResHouses[aHouseType].EntranceOffsetX, aPosY, aOwner, hbsDone)
  else
    Result := AddToCollection(aHouseType, aPosX, aPosY, aOwner, hbsDone);
end;


{Add a plan for house}
function TKMHousesCollection.AddHouseWIP(aHouseType: TKMHouseType; aPosX, aPosY: Integer; aOwner: TKMHandID): TKMHouse;
begin
  Result := AddToCollection(aHouseType, aPosX, aPosY, aOwner, hbsNoGlyph);
end;


procedure TKMHousesCollection.AddHouseToList(aHouse: TKMHouse);
begin
  Assert(gGameParams.IsMapEditor); // Allow to add existing House directly only in MapEd
  if (aHouse <> nil) then
    DoAddHouse(aHouse);
end;


//Delete pointer to House in List
procedure TKMHousesCollection.DeleteHouseFromList(aHouse: TKMHouse);
begin
  Assert(gGameParams.IsMapEditor); // Allow to delete existing House directly only in MapEd

  if (aHouse <> nil) then
    fHouses.Extract(aHouse);
end;


procedure TKMHousesCollection.RemoveHousesOutOfBounds(const aInsetRect: TKMRect);
var
  I: Integer;
  newMapRect: TKMRect;
begin
  Assert(gGameParams.IsMapEditor);
  if Count <= 0 then Exit;

  newMapRect := KMRectGrow(gTerrain.MapRect, aInsetRect);

  for I := 0 to Count - 1 do
    if not KMInRect(Houses[I].Position, newMapRect)
      or not gTerrain.CheckHouseBounds(Houses[I].HouseType, Houses[I].Position, aInsetRect) then
      Houses[I].Demolish(Houses[I].Owner, True);
end;


procedure TKMHousesCollection.RemoveAllHouses;
var
  I: Integer;
begin
  if Count <= 0 then Exit;

  for I := 0 to Count - 1 do
    Houses[I].Demolish(Houses[I].Owner, True);

  fHouses.Clear;
end;


procedure TKMHousesCollection.OwnerUpdate(aOwner: TKMHandID);
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Houses[I].OwnerUpdate(aOwner);
end;


function TKMHousesCollection.HitTest(X, Y: Integer): TKMHouse;
var
  I: Integer;
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
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Count - 1 do
    if aUID = Houses[I].UID then
    begin
      Result := Houses[I];
      Exit;
    end;
end;


procedure TKMHousesCollection.GetHousesInRect(const aRect: TKMRect; aList: TList<TKMHouse>);
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if KMInRect(Houses[I].Entrance, aRect) and not Houses[I].IsDestroyed then
      aList.Add(Houses[I]);
end;


//Should find closest house to Loc
function TKMHousesCollection.FindEmptyHouse(aUnitType: TKMUnitType; const aLoc: TKMPoint): TKMHouse;
var
  I: Integer;
  dist, bestBid: Single;
begin
  Result := nil;
  bestBid := MaxSingle;

  for I := 0 to Count - 1 do
    if (gResHouses[Houses[I].HouseType].WorkerType = aUnitType) and // If Unit can work in here
       not Houses[I].HasWorker and                                  // if there's yet no owner
       not Houses[I].IsDestroyed and                                // if house is not destroyed
       Houses[I].IsComplete and                                     // if house is built
       not Houses[I].IsClosedForWorker then                         // if house is not closed for worker
    begin
      //Recruits should not go to a barracks with ware delivery switched off or with not accept flag for recruits
      if (Houses[I].HouseType = htBarracks)
        and ((Houses[I].DeliveryMode <> dmDelivery) or (TKMHouseBarracks(Houses[I]).NotAcceptRecruitFlag)) then Continue;
      if not gTerrain.Route_CanBeMade(aLoc, Houses[I].PointBelowEntrance, tpWalk, 0) then Continue;

      dist := KMLengthSqr(aLoc, Houses[I].Position);

      //Always prefer Towers to Barracks by making Barracks Bid much less attractive
      //In case of multiple barracks, prefer the closer one (players should make multiple schools or use WareDelivery to control it)
      if Houses[I].HouseType = htBarracks then
        dist := dist * 1000;

      if dist < bestBid then
      begin
        bestBid := dist;
        Result := Houses[I];
      end;
    end;
end;


function TKMHousesCollection.FindHouse(aType: TKMHouseType; X, Y: Word; const aIndex: Byte = 1; aOnlyCompleted: Boolean = True): TKMHouse;
var
  HT: TKMHouseTypeSet;
begin
  if aType = htAny then
    HT := [Low(TKMHouseType)..High(TKMHouseType)]
  else
    HT := [aType];
  Result := FindHouse(HT, X, Y, aIndex, aOnlyCompleted);
end;


//Find closest house to given position
//or
//Find house by index (1st, 2nd)
function TKMHousesCollection.FindHouse(const aTypes: TKMHouseTypeSet; X, Y: Word; const aIndex: Byte = 1; aOnlyCompleted: Boolean = True): TKMHouse;
var
  I, ID: Integer;
  usePosition: Boolean;
  bestMatch, dist: Single;
begin
  Result := nil;
  ID := 0;
  bestMatch := MaxSingle; //Any distance will be closer than that
  usePosition := X*Y <> 0; //Calculate this once to save computing lots of multiplications
  Assert((not usePosition) or (aIndex = 1), 'Can''t find house basing both on Position and Index');

  for I := 0 to Count - 1 do
  if (Houses[I].HouseType in aTypes)
  and (Houses[I].IsComplete or not aOnlyCompleted)
  and not Houses[I].IsDestroyed then
  begin
    Inc(ID);
    if usePosition then
    begin
      dist := KMLengthSqr(Houses[I].Position,KMPoint(X,Y));
      if bestMatch = -1 then bestMatch := dist; //Initialize for first use
      if dist < bestMatch then
      begin
        bestMatch := dist;
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


function TKMHousesCollection.FindHousesInRadius(aLoc: TKMPoint; aSqrRadius: Single; aTypes: TKMHouseTypeSet; aOnlyCompleted: Boolean = True): TKMHouseArray;
var
  I, idx: Integer;
begin
  SetLength(Result, 12);
  idx := 0;
  for I := 0 to Count - 1 do
    if (Houses[I].HouseType in aTypes)
      AND (not aOnlyCompleted OR Houses[I].IsComplete)
      AND not Houses[I].IsDestroyed then
    begin
      if (KMLengthSqr(Houses[I].Position, aLoc) <= aSqrRadius) then
      begin
        if (idx >= Length(Result)) then
          SetLength(Result, idx + 12);
        Result[idx] := Houses[I];
        idx := idx + 1;
      end;
    end;
  SetLength(Result,idx);
end;


procedure TKMHousesCollection.Save(SaveStream: TKMemoryStream);
var
  I: Integer;
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
  I, newCount: Integer;
  HT: TKMHouseType;
  H: TKMHouse;
begin
  LoadStream.CheckMarker('Houses');

  LoadStream.Read(newCount);
  for I := 0 to newCount - 1 do
  begin
    LoadStream.Read(HT, SizeOf(HT));
    case HT of
      htSwine,
      htStables:       H := TKMHouseSwineStable.Load(LoadStream);
      htInn:           H := TKMHouseInn.Load(LoadStream);
      htMarket:   H := TKMHouseMarket.Load(LoadStream);
      htSchool:        H := TKMHouseSchool.Load(LoadStream);
      htBarracks:      H := TKMHouseBarracks.Load(LoadStream);
      htStore:         H := TKMHouseStore.Load(LoadStream);
      htWatchTower:    H := TKMHouseTower.Load(LoadStream);
      htWoodcutters:   H := TKMHouseWoodcutters.Load(LoadStream);
      htArmorWorkshop: H := TKMHouseArmorWorkshop.Load(LoadStream);
      htTownHall:      H := TKMHouseTownHall.Load(LoadStream);
      else             H := TKMHouse.Load(LoadStream);
    end;

    if H <> nil then
      DoAddHouse(H);
  end;
end;


procedure TKMHousesCollection.SyncLoad;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Houses[I].SyncLoad;
end;


//Update resource requested counts for all houses
procedure TKMHousesCollection.UpdateResRequest;
var
  I: Integer;
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
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Houses[I].IncAnimStep;
end;


function TKMHousesCollection.GetTotalPointers: Cardinal;
var
  I: Integer;
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
