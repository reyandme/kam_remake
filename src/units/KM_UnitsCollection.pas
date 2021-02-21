unit KM_UnitsCollection;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, Types,
  KM_CommonClasses, KM_Defaults, KM_Points,
  KM_Terrain, KM_Units;

//Memo on directives:
//Dynamic - declared and used (overriden) occasionally
//Virtual - declared and used (overriden) always
//Abstract - declared but must be overriden in child classes

type
  TKMUnitsCollection = class
  private
    fUnits: TKMList;
    function GetUnit(aIndex: Integer): TKMUnit; inline;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function AddUnit(aOwner: TKMHandID; aUnitType: TKMUnitType; const aLoc: TKMPoint; aAutoPlace: Boolean = True;
                     aRequiredWalkConnect: Byte = 0; aAddInHouse: Boolean = False): TKMUnit;
    procedure AddUnitToList(aUnit: TKMUnit);
    property Count: Integer read GetCount;
    property Units[aIndex: Integer]: TKMUnit read GetUnit; default; //Use instead of Items[.]
    procedure RemoveUnit(aUnit: TKMUnit);
    procedure RemoveAllUnits;
    procedure RemoveUnitsOutOfBounds(const aInsetRect: TKMRect);
    procedure DeleteUnitFromList(aUnit: TKMUnit);
    procedure OwnerUpdate(aOwner: TKMHandID);
    function HitTest(X, Y: Integer; const UT: TKMUnitType = utAny): TKMUnit;
    function GetUnitByUID(aUID: Integer): TKMUnit;
    function GetClosestUnit(const aPoint: TKMPoint; aTypes: TKMUnitTypeSet = [Low(TKMUnitType)..High(TKMUnitType)]): TKMUnit;
    procedure GetUnitsInRect(const aRect: TKMRect; List: TList);
    function GetTotalPointers: Integer;
    procedure Clear;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad;
    procedure UpdateState(aTick: Cardinal);
    procedure UpdateVisualState;
    procedure Paint(const aRect: TKMRect; aTickLag: Single);
  end;


implementation
uses
  SysUtils,
  KM_Game, KM_GameParams, KM_HandsCollection, KM_Log, KM_Resource, KM_ResUnits, KM_UnitWarrior,
  KM_UnitActionWalkTo,
  KM_DevPerfLog, KM_DevPerfLogTypes,
  KM_CommonExceptions;


{ TKMUnitsCollection }
constructor TKMUnitsCollection.Create;
begin
  inherited Create;

  fUnits := TKMList.Create;
end;


destructor TKMUnitsCollection.Destroy;
begin
  //No need to free units individually since they are Freed by TKMList.Clear command in destructor
  fUnits.Free;

  inherited;
end;


procedure TKMUnitsCollection.Clear;
begin
  fUnits.Clear;
end;


function TKMUnitsCollection.GetCount: Integer;
begin
  Result := fUnits.Count;
end;


function TKMUnitsCollection.GetUnit(aIndex: Integer): TKMUnit;
begin
  Result := fUnits[aIndex];
end;


//AutoPlace means we should try to find a spot for this unit instead of just placing it where we were told to
function TKMUnitsCollection.AddUnit(aOwner: TKMHandID; aUnitType: TKMUnitType; const aLoc: TKMPoint; aAutoPlace: Boolean = True;
                                    aRequiredWalkConnect: Byte = 0; aAddInHouse: Boolean = False): TKMUnit;
var
  ID: Cardinal;
  PlaceTo: TKMPoint;
  U: TKMUnit;
begin
  if aAutoPlace then
  begin
    PlaceTo := KMPOINT_ZERO; // Will have 0:0 if no place found
    if aRequiredWalkConnect = 0 then
      aRequiredWalkConnect := gTerrain.GetWalkConnectID(aLoc);
    gHands.FindPlaceForUnit(aLoc.X, aLoc.Y, aUnitType, PlaceTo, aRequiredWalkConnect);
  end
  else
    PlaceTo := aLoc;

  //Check if Pos is within map coords first, as other checks rely on this
  if not gTerrain.TileInMapCoords(PlaceTo.X, PlaceTo.Y) then
  begin
    gLog.AddTime('Unable to add unit to ' + KM_Points.TypeToString(PlaceTo));
    Result := nil;
    Exit;
  end;

  if not aAddInHouse and gTerrain.HasUnit(PlaceTo) then
  begin
    U := TKMUnit(gTerrain.Land[PlaceTo.Y,PlaceTo.X].IsUnit);
    raise ELocError.Create(Format('No space for %s at %s, tile is already occupied by %s, ID = %d',
                                  [gRes.Units[aUnitType].GUIName, aLoc.ToString, gRes.Units[U.UnitType].GUIName, U.UID]),
                           PlaceTo);
  end;

  ID := gGame.GetNewUID;
  case aUnitType of
    utSerf:                        Result := TKMUnitSerf.Create(ID, aUnitType, PlaceTo, aOwner, aAddInHouse);
    utWorker:                      Result := TKMUnitWorker.Create(ID, aUnitType, PlaceTo, aOwner, aAddInHouse);
    utWoodCutter..utFisher,
    {utWorker,}
    utStoneCutter..utMetallurgist: Result := TKMUnitCitizen.Create(ID, aUnitType, PlaceTo, aOwner, aAddInHouse);
    utRecruit:                     Result := TKMUnitRecruit.Create(ID, aUnitType, PlaceTo, aOwner, aAddInHouse);
    WARRIOR_MIN..WARRIOR_MAX:      Result := TKMUnitWarrior.Create(ID, aUnitType, PlaceTo, aOwner, aAddInHouse);
    ANIMAL_MIN..ANIMAL_MAX:        Result := TKMUnitAnimal.Create(ID, aUnitType, PlaceTo, aOwner); //Do not specify aAddInHouse, we want to call TKMUnitAnimal constructor
    else                           raise ELocError.Create('Add ' + gRes.Units[aUnitType].GUIName, PlaceTo);
  end;

  if Result <> nil then
    fUnits.Add(Result);
end;

procedure TKMUnitsCollection.AddUnitToList(aUnit: TKMUnit);
begin
  Assert(gGameParams.IsMapEditor); // Allow to add existing Unit directly only in MapEd
  if aUnit <> nil then
    fUnits.Add(aUnit);
end;


procedure TKMUnitsCollection.RemoveUnit(aUnit: TKMUnit);
begin
  aUnit.CloseUnit; //Should free up the unit properly (freeing terrain usage and memory)
  fUnits.Remove(aUnit); //Will free the unit
end;


procedure TKMUnitsCollection.RemoveUnitsOutOfBounds(const aInsetRect: TKMRect);
var
  I: Integer;
  newMapRect: TKMRect;
begin
  Assert(gGameParams.IsMapEditor);
  if Count <= 0 then Exit;

  newMapRect := KMRectGrow(gTerrain.MapRect, aInsetRect);

  for I := 0 to Count - 1 do
    if not KMInRect(Units[I].Position, newMapRect) then
      Units[I].CloseUnit;
end;


procedure TKMUnitsCollection.RemoveAllUnits;
var
  I: Integer;
begin
  Assert(gGameParams.IsMapEditor);
  if Count <= 0 then Exit;

  for I := 0 to Count - 1 do
    Units[I].CloseUnit;
  fUnits.Clear;
end;


procedure TKMUnitsCollection.DeleteUnitFromList(aUnit: TKMUnit);
begin
  Assert(gGameParams.IsMapEditor); // Allow to delete existing Unit directly only in MapEd
  if (aUnit <> nil) then
    fUnits.Extract(aUnit);  // use Extract instead of Delete, cause Delete nils inner objects somehow
end;


procedure TKMUnitsCollection.OwnerUpdate(aOwner: TKMHandID);
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Units[I].Owner := aOwner;
end;


function TKMUnitsCollection.HitTest(X, Y: Integer; const UT: TKMUnitType = utAny): TKMUnit;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Count - 1 do
    if Units[I].HitTest(X,Y,UT) and not Units[I].IsDead then
    begin
      Result := Units[I];
      Exit;
    end;
end;


function TKMUnitsCollection.GetUnitByUID(aUID: Integer): TKMUnit;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Count - 1 do
    if aUID = Units[I].UID then
    begin
      Result := Units[I];
      exit;
    end;
end;


procedure TKMUnitsCollection.GetUnitsInRect(const aRect: TKMRect; List: TList);
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if KMInRect(Units[I].PositionF, aRect) and not Units[I].IsDeadOrDying then
      List.Add(Units[I]);
end;


function TKMUnitsCollection.GetClosestUnit(const aPoint: TKMPoint; aTypes: TKMUnitTypeSet = [Low(TKMUnitType)..High(TKMUnitType)]): TKMUnit;
var
  I: Integer;
  BestDist, Dist: Single;
begin
  Result := nil;
  BestDist := MaxSingle; //Any distance will be closer than that
  for I := 0 to Count - 1 do
    if not Units[I].IsDeadOrDying and Units[I].Visible and (Units[I].UnitType in aTypes) then
    begin
      Dist := KMLengthSqr(Units[I].Position, aPoint);
      if Dist < BestDist then
      begin
        BestDist := Dist;
        Result := Units[I];
      end;
    end;
end;


function TKMUnitsCollection.GetTotalPointers: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Count - 1 do
    Inc(Result, Units[I].PointerCount);
end;


procedure TKMUnitsCollection.Save(SaveStream: TKMemoryStream);
var
  I: Integer;
begin
  SaveStream.PlaceMarker('Units');
  SaveStream.Write(Count);
  for I := 0 to Count - 1 do
  begin
    //We save unit type to know which unit class to load
    SaveStream.Write(Units[I].UnitType, SizeOf(Units[I].UnitType));
    Units[I].Save(SaveStream);
  end;
end;


procedure TKMUnitsCollection.Load(LoadStream: TKMemoryStream);
var
  I, NewCount: Integer;
  UnitType: TKMUnitType;
  U: TKMUnit;
begin
  LoadStream.CheckMarker('Units');
  LoadStream.Read(NewCount);
  for I := 0 to NewCount - 1 do
  begin
    LoadStream.Read(UnitType, SizeOf(UnitType));
    case UnitType of
      utSerf:                   U := TKMUnitSerf.Load(LoadStream);
      utWorker:                 U := TKMUnitWorker.Load(LoadStream);
      utWoodCutter..utFisher,
      {utWorker,}
      utStoneCutter..utMetallurgist:
                                U := TKMUnitCitizen.Load(LoadStream);
      utRecruit:                U := TKMUnitRecruit.Load(LoadStream);
      WARRIOR_MIN..WARRIOR_MAX: U := TKMUnitWarrior.Load(LoadStream);
      ANIMAL_MIN..ANIMAL_MAX:   U := TKMUnitAnimal.Load(LoadStream);
      else                      U := nil;
    end;

    if U <> nil then
      fUnits.Add(U)
    else
      gLog.AddAssert('Unknown unit type in Savegame');
  end;
end;


procedure TKMUnitsCollection.SyncLoad;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Units[I].SyncLoad;
end;


procedure TKMUnitsCollection.UpdateVisualState;
var
  I: Integer;
begin
  Assert(gGameParams.IsMapEditor);

  for I := Count - 1 downto 0 do
    if not Units[I].IsDead then
      Units[I].UpdateVisualState;
end;


procedure TKMUnitsCollection.UpdateState(aTick: Cardinal);
var
  I: Integer;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psUnits);
  {$ENDIF}
  try
    for I := Count - 1 downto 0 do
      if not Units[I].IsDead then
      begin
        Units[I].UpdateState;
        Units[I].UpdateVisualState;
      end
      else
        if FREE_POINTERS and (Units[I].PointerCount = 0) then
          fUnits.Delete(I);
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psUnits);
    {$ENDIF}
  end;
    //   --     POINTER FREEING SYSTEM - DESCRIPTION     --   //
    //  This system was implemented because unit and house objects cannot be freed until all pointers
    //  to them (in tasks, delivery queue, etc.) have been freed, otherwise we have pointer integrity
    //  issues.

    //   --     ROUGH OUTLINE     --   //
    // - Units and houses have fPointerCount, which is the number of pointers to them. (e.g. tasks,
    //   deliveries) This is kept up to date by the thing that is using the pointer. On create it uses
    //   GetPointer to get the pointer and increase the pointer count and on destroy it decreases
    //   it with ReleasePointer.
    // - When a unit dies, the object is not destroyed. Instead a flag (boolean) is set to say that we
    //   want to destroy but can't because there still might be pointers to the unit. From then on
    //   every update state it checks to see if the pointer count is 0 yet. If it is then the unit is
    //   destroyed.
    // - For each place that contains a pointer, it should check everytime the pointer is used to see
    //   if it has been destroy. If it has then we free the pointer and reduce the count.
    //   (and do any other action nececary due to the unit/house dying)
end;


procedure TKMUnitsCollection.Paint(const aRect: TKMRect; aTickLag: Single);
const
  Margin = 2;
var
  I: Integer;
  growRect: TKMRect;
begin
  //Add additional margin to compensate for units height
  growRect := KMRectGrow(aRect, Margin);

  for I := 0 to Count - 1 do
  if (Units[I] <> nil)
    and not Units[I].IsDead
    and ((SHOW_UNIT_ROUTES
          and (Units[I].Action is TKMUnitActionWalkTo)
          and TKMUnitActionWalkTo(Units[I].Action).NeedToPaint(growRect))
        or KMInRect(Units[I].PositionF, growRect)) then
    Units[I].Paint(aTickLag);
end;


end.
