unit KM_BuildList;
{$I KaM_Remake.inc}
interface
uses
  KM_Units, KM_Houses,
  KM_ResHouses,
  KM_Defaults, KM_CommonClasses, KM_Points;


type
  TKMJobStatus = (
    jsEmpty,   // Empty - empty spot for a new job
    jsOpen,    // Open - job is free to take by anyone
    jsTaken    // Taken - job is taken by some worker
  );
  
  //List of houses ready to build
  TKMHouseList = class
  private
    fHousesCount: Integer;
    fHouses: array of record
      House: TKMHouse;
      Assigned: Integer; //How many workers are on this house
    end;
    procedure RemoveExtraHouses;
  public
    destructor Destroy; override;

    procedure AddHouse(aHouse: TKMHouse); //New house to build
    procedure RemWorker(aIndex: Integer);
    procedure GiveTask(aIndex: Integer; aWorker: TKMUnitWorker);
    function BestBid(aWorker: TKMUnitWorker; out aBid: Single): Integer;
    function GetAvailableJobsCount: Integer;

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad;

    procedure UpdateState;
  end;


  TKMHousePlan = record
    UID: Integer;
    HouseType: TKMHouseType;
    Loc: TKMPoint;
    JobStatus: TKMJobStatus;
    Worker: TKMUnit; //So we can tell Worker if plan is cancelled
    function IsEmpty: Boolean;
  end;
  TKMHousePlanArray = array of TKMHousePlan;


  //List of house plans and workers assigned to them
  TKMHousePlanList = class
  private
    fPlansCount: Integer;
    fPlans: TKMHousePlanArray;
  public
    //Player orders
    procedure AddPlan(aHouseType: TKMHouseType; const aLoc: TKMPoint);
    function HasPlan(const aLoc: TKMPoint): Boolean; overload;
    function HasPlan(const aLoc: TKMPoint; out aHouseType: TKMHouseType): Boolean; overload;
    procedure RemPlan(const aLoc: TKMPoint);
    function TryGetPlan(const aLoc: TKMPoint; out aHousePlan: TKMHousePlan): Boolean;
    function FindHousePlan(const aLoc: TKMPoint; aSkip: TKMPoint; out aOut: TKMPoint): Boolean;

    // AI Informations
    property Count: Integer read fPlansCount;
    property Plans: TKMHousePlanArray read fPlans;
    function ExistPlan(const aLoc: TKMPoint; aHT: TKMHouseType): Boolean;
    function GetPlansStoneDemands(): Integer;
    function GetPlansWoodDemands(): Integer;

    //Game events
    function BestBid(aWorker: TKMUnitWorker; out aBid: Single): Integer; //Calculate best bid for a given worker
    function GetAvailableJobsCount: Integer;
    procedure GiveTask(aIndex: Integer; aWorker: TKMUnitWorker); //Assign worker to a field
    procedure ReOpenPlan(aIndex: Integer); //Worker has died while walking to the Field, allow other worker to take the task
    procedure ClosePlan(aIndex: Integer); //Worker has finished the task

    procedure GetOutlines(aList: TKMPointDirList; const aRect: TKMRect);
    procedure GetTablets(aList: TKMPointTagList; const aRect: TKMRect);

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad;
  end;


  TKMFieldPlan = record
    Loc: TKMPoint;
    FieldType: TKMFieldType;
    JobStatus: TKMJobStatus;
    Worker: TKMUnit;
  end;
  TKMFieldPlanArray = array of TKMFieldPlan;


  TKMFieldworksList = class
  private
    fFieldsCount: Integer;
    fFields: TKMFieldPlanArray;
    //List of fields which are shown visually but not verified by the server
    fFakeFields: array of record
      Loc: TKMPoint;
      FieldType: TKMFieldType;
      Active: Boolean;
    end;
    //List of fields which are being deleted, so fields can disappear as soon as the player deleted them
    fFakeDeletedFields: array of record
      Loc: TKMPoint;
      Active: Boolean;
    end;
  public
    //Player orders
    procedure AddFakeField(const aLoc: TKMPoint; aFieldType: TKMFieldType);
    procedure AddFakeDeletedField(const aLoc: TKMPoint);
    procedure AddField(const aLoc: TKMPoint; aFieldType: TKMFieldType);
    function HasField(const aLoc: TKMPoint): TKMFieldType;
    function HasFakeField(const aLoc: TKMPoint): TKMFieldType;
    procedure RemFieldPlan(const aLoc: TKMPoint);
    procedure RemFakeField(const aLoc: TKMPoint);
    procedure RemFakeDeletedField(const aLoc: TKMPoint);

    // AI Informations
    property Count: Integer read fFieldsCount;
    property Fields: TKMFieldPlanArray read fFields;

    //Game events
    function BestBid(aWorker: TKMUnitWorker; out aBid: Single): Integer; //Calculate best bid for a given worker
    function GetAvailableJobsCount:Integer;
    procedure GiveTask(aIndex: Integer; aWorker: TKMUnitWorker); //Assign worker to a field
    procedure ReOpenField(aIndex: Integer); //Worker has died while walking to the Field, allow other worker to take the task
    procedure CloseField(aIndex: Integer); //Worker has finished the task

    procedure GetFields(aList: TKMPointTagList; const aRect: TKMRect; aIncludeFake:Boolean);
    function FieldCount(aFieldType: TKMFieldType): Integer;

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad;
  end;


  // Use simple approach since repairs are quite rare events
  // Houses are only added to the list. List checks itself when House should be removed from it
  TKMRepairList = class
  private
    fHousesCount: Integer;
    fHouses: array of record
      House: TKMHouse; //Pointer to house
      Assigned: Byte; //How many workers are assigned to it
    end;

    function HouseAlreadyInList(aHouse: TKMHouse): Boolean;
    procedure RemoveExtraHouses;
  public
    destructor Destroy; override;

    procedure AddHouse(aHouse: TKMHouse);
    function BestBid(aWorker: TKMUnitWorker; out aBid: Single): Integer; //Calculate best bid for a given worker
    function GetAvailableJobsCount:Integer;
    procedure GiveTask(aIndex: Integer; aWorker: TKMUnitWorker);
    procedure RemWorker(aIndex: Integer);

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad;
    procedure UpdateState;
  end;


  // Matchmaking service of workers to building sites, fields, repairs, etc
  TKMBuildList = class
  private
    fFieldworksList: TKMFieldworksList;
    fHouseList: TKMHouseList;
    fHousePlanList: TKMHousePlanList;
    fRepairList: TKMRepairList;

    fWorkersCount: Integer;
    fWorkers: array of record
      Worker: TKMUnitWorker; //Pointer to Worker
    end;
    procedure RemWorker(aIndex: Integer);
    procedure RemoveExtraWorkers;
    function GetIdleWorkerCount: Integer;
    function GetBestWorker(const aPoint: TKMPoint): TKMUnitWorker;

    procedure AssignFieldworks;
    procedure AssignHousePlans;
    procedure AssignHouses;
    procedure AssignRepairs;
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddWorker(aWorker: TKMUnitWorker);

    property FieldworksList: TKMFieldworksList read fFieldworksList;
    property HouseList: TKMHouseList read fHouseList;
    property HousePlanList: TKMHousePlanList read fHousePlanList;
    property RepairList: TKMRepairList read fRepairList;

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad;
    procedure UpdateState;
  end;


implementation
uses
  Math,
  KM_Game, KM_HandsCollection, KM_Resource;


const
  LENGTH_INC = 32; // Increment array lengths by this value
  BID_MODIF = 5; // Modificator for every next assigned worker

  //Limit number of workers building each house, so they all fit in around
  MAX_WORKERS: array [TKMHouseType] of Byte = (
    0,0, //htNone, htAny
    8, {htArmorSmithy}  8,{htArmorWorkshop}  8, {htBakery}      12,{htBarracks}      8, {htButchers}
    6, {htCoalMine}     8,{htFarm}           7, {htFisherHut}   3, {htGoldMine}      10,{htInn}
    4, {htIronMine}     8,{htIronSmithy}     10,{htMarketplace} 8, {htMetallurgists} 8, {htMill}
    6, {htQuary}        8,{htSawmill}        10,{htSchool}      8, {htSiegeWorkshop} 10,{htStables}
    10,{htStore}        8,{htSwine}          8, {htTannery}     10,{htTownHall}      6, {htWatchTower}
    8, {htWeaponSmithy} 8,{htWeaponWorkshop} 8, {htWineyard}    6  {htWoodcutters}
  );


{ TKMHousePlan }
function TKMHousePlan.IsEmpty: Boolean;
begin
  Result := JobStatus = jsEmpty;
end;


{TKMHouseList}
destructor TKMHouseList.Destroy;
var
  I: Integer;
begin
  for I := 0 to fHousesCount - 1 do
  if fHouses[I].House <> nil then
    gHands.CleanUpHousePointer(fHouses[I].House);

  inherited;
end;


//Add new job to the list
procedure TKMHouseList.AddHouse(aHouse: TKMHouse);
var I: Integer;
begin
  I := 0;
  while (I < fHousesCount) and (fHouses[I].House <> nil) do
    Inc(I);

  if I >= fHousesCount then
    Inc(fHousesCount);

  if I >= Length(fHouses) then
    SetLength(fHouses, Length(fHouses) + LENGTH_INC);

  fHouses[I].House := aHouse.GetHousePointer;
  fHouses[I].Assigned := 0;
end;


function TKMHouseList.BestBid(aWorker: TKMUnitWorker; out aBid: Single): Integer;
var
  I: Integer;
  NewBid: Single;
begin
  //We can weight the repairs by distance, severity, etc..
  //For now, each worker will go for the house closest to him

  Result := -1;
  aBid := MaxSingle;
  for I := fHousesCount - 1 downto 0 do
  if (fHouses[i].House <> nil) and fHouses[i].House.CheckResToBuild
  and (fHouses[I].Assigned < MAX_WORKERS[fHouses[i].House.HouseType])
  and aWorker.CanWalkTo(fHouses[i].House.PointBelowEntrance, 0)
  then
  begin
    NewBid := KMLengthDiag(aWorker.CurrPosition, fHouses[I].House.Position);
    NewBid := NewBid + fHouses[I].Assigned * BID_MODIF;

    if NewBid < aBid then
    begin
      aBid := NewBid;
      Result := I;
    end;
  end;
end;


function TKMHouseList.GetAvailableJobsCount:Integer;
var I: Integer;
begin
  Result := 0;
  for I := 0 to fHousesCount - 1 do
    if (fHouses[i].House <> nil) and fHouses[i].House.CheckResToBuild then
      inc(Result);
end;


procedure TKMHouseList.GiveTask(aIndex: Integer; aWorker: TKMUnitWorker);
begin
  aWorker.BuildHouse(fHouses[aIndex].House, aIndex);
  Inc(fHouses[aIndex].Assigned);
end;


//Whenever worker dies we need to remove him from assigned to the house
procedure TKMHouseList.RemWorker(aIndex: Integer);
begin
  Dec(fHouses[aIndex].Assigned);
  //If the house is complete or destroyed it will be removed in next UpdateState
end;


//We can remove house only when there are no workers left to it (e.g. stuck on their way)
procedure TKMHouseList.RemoveExtraHouses;
var I: Integer;
begin
  for I := 0 to fHousesCount - 1 do
  if (fHouses[i].House <> nil) and (fHouses[I].House.IsDestroyed or fHouses[I].House.IsComplete) and (fHouses[I].Assigned = 0) then
      gHands.CleanUpHousePointer(fHouses[I].House);
end;


procedure TKMHouseList.UpdateState;
begin
  RemoveExtraHouses;
end;


procedure TKMHouseList.Save(SaveStream: TKMemoryStream);
var I: Integer;
begin
  SaveStream.PlaceMarker('HouseList');

  SaveStream.Write(fHousesCount);
  for I := 0 to fHousesCount - 1 do
  begin
    if fHouses[I].House <> nil then
      SaveStream.Write(fHouses[I].House.UID)
    else
      SaveStream.Write(Integer(0));
    SaveStream.Write(fHouses[I].Assigned);
  end;
end;


procedure TKMHouseList.Load(LoadStream: TKMemoryStream);
var I: Integer;
begin
  LoadStream.CheckMarker('HouseList');

  LoadStream.Read(fHousesCount);
  SetLength(fHouses, fHousesCount);
  for I := 0 to fHousesCount - 1 do
  begin
    LoadStream.Read(fHouses[I].House, 4);
    LoadStream.Read(fHouses[I].Assigned);
  end;
end;


procedure TKMHouseList.SyncLoad;
var I: Integer;
begin
  for I := 0 to fHousesCount - 1 do
    fHouses[i].House := gHands.GetHouseByUID(cardinal(fHouses[I].House));
end;


{ TKMFieldworksList }
function TKMFieldworksList.BestBid(aWorker: TKMUnitWorker; out aBid: Single): Integer;
var
  I: Integer;
  NewBid: Single;
begin
  Result := -1;
  aBid := MaxSingle;

  for I := 0 to fFieldsCount - 1 do
  if (fFields[I].JobStatus = jsOpen)
  and aWorker.CanWalkTo(fFields[I].Loc, 0) then
  begin
    NewBid := KMLengthDiag(aWorker.CurrPosition, fFields[I].Loc);
    if NewBid < aBid then
    begin
      Result := I;
      aBid := NewBid;
    end;
  end;
end;


function TKMFieldworksList.GetAvailableJobsCount:Integer;
var I: Integer;
begin
  Result := 0;
  for I := 0 to fFieldsCount - 1 do
    if fFields[I].JobStatus = jsOpen then
      inc(Result);
end;


procedure TKMFieldworksList.CloseField(aIndex: Integer);
begin
  //Any fake fields should now be removed
  RemFakeField(fFields[aIndex].Loc);
  RemFakeDeletedField(fFields[aIndex].Loc);

  fFields[aIndex].Loc := KMPOINT_ZERO;
  fFields[aIndex].FieldType := ftNone;
  fFields[aIndex].JobStatus := jsEmpty;
  gHands.CleanUpUnitPointer(fFields[aIndex].Worker); //Will nil the worker as well
end;


//Returns the list of fields inside aRect.
//aIncludeFake means the list of fields will be as the user should see it, with additional fake fields
//and some of the real fields removed if the user has deleted them but the command has not yet been processed.
procedure TKMFieldworksList.GetFields(aList: TKMPointTagList; const aRect: TKMRect; aIncludeFake: Boolean);
var I: Integer;
begin
  for I := 0 to fFieldsCount - 1 do
  if (fFields[I].FieldType <> ftNone) and KMInRect(fFields[I].Loc, aRect) then
    aList.Add(fFields[I].Loc, Byte(fFields[I].FieldType));

  if aIncludeFake then
  begin
    for I := 0 to Length(fFakeFields) - 1 do
      //It is possible to have a fake fieldplans at the position of a real fieldplan temporarily when
      //clicking on one tile repeatly due to network delay. Don't add duplicate points to the list.
      if fFakeFields[I].Active and not aList.Contains(fFakeFields[I].Loc) then
        aList.Add(fFakeFields[I].Loc, Byte(fFakeFields[I].FieldType));
    //Fields that have been deleted should not be painted
    for I := 0 to Length(fFakeDeletedFields) - 1 do
      if fFakeDeletedFields[I].Active then
        aList.Remove(fFakeDeletedFields[I].Loc);
  end;
end;


function TKMFieldworksList.FieldCount(aFieldType: TKMFieldType): Integer;
var I: Integer;
begin
  Result := 0;
  for I := 0 to fFieldsCount - 1 do
    if (fFields[I].FieldType = aFieldType) then
      Inc(Result);
end;


procedure TKMFieldworksList.GiveTask(aIndex: Integer; aWorker: TKMUnitWorker);
begin
  aWorker.BuildField(fFields[aIndex].FieldType, fFields[aIndex].Loc, aIndex);
  fFields[aIndex].JobStatus := jsTaken;
  fFields[aIndex].Worker := aWorker.GetUnitPointer;
end;


//Fake plan that will be visible until real one is verified by Server
procedure TKMFieldworksList.AddFakeField(const aLoc: TKMPoint; aFieldType: TKMFieldType);
var I: Integer;
begin
  I := 0;
  while (I < Length(fFakeFields)) and (fFakeFields[I].Active) do
    Inc(I);

  if I >= Length(fFakeFields) then
    SetLength(fFakeFields, Length(fFakeFields) + LENGTH_INC);

  fFakeFields[I].Loc := aLoc;
  fFakeFields[I].FieldType := aFieldType;
  fFakeFields[I].Active := True;
end;


//Indicator that the real plan on this tile has been deleted, so hide it from the user
procedure TKMFieldworksList.AddFakeDeletedField(const aLoc: TKMPoint);
var I: Integer;
begin
  I := 0;
  while (I < Length(fFakeDeletedFields)) and (fFakeDeletedFields[I].Active) do
    Inc(I);

  if I >= Length(fFakeDeletedFields) then
    SetLength(fFakeDeletedFields, Length(fFakeDeletedFields) + LENGTH_INC);

  fFakeDeletedFields[I].Loc := aLoc;
  fFakeDeletedFields[I].Active := True;
end;


//Keep list items in place, since Workers use indexes to address them
procedure TKMFieldworksList.AddField(const aLoc: TKMPoint; aFieldType: TKMFieldType);
var
  I: Integer;
begin
  //Remove any fake fields here, as the real one is being placed. FakeDeleted fields should stay,
  //since the user might already have deleted this field we are adding so it should not reappear.
  RemFakeField(aLoc);

  I := 0;
  while (I < fFieldsCount) and (fFields[I].JobStatus <> jsEmpty) do
    Inc(I);

  if I >= fFieldsCount then
    Inc(fFieldsCount);

  if I >= Length(fFields) then
    SetLength(fFields, Length(fFields) + LENGTH_INC);

  fFields[I].Loc := aLoc;
  fFields[I].FieldType := aFieldType;
  fFields[I].JobStatus := jsOpen;
  fFields[I].Worker := nil;
end;


//Removes the fake marker showing the user he has placed a field here
procedure TKMFieldworksList.RemFakeField(const aLoc: TKMPoint);
var I: Integer;
begin
  for I := 0 to Length(fFakeFields) - 1 do
    if fFakeFields[I].Active and KMSamePoint(fFakeFields[I].Loc, aLoc) then
      fFakeFields[I].Active := False;
end;


//Removes the fake deleted field which is used to hide a real field until the command can be processed
procedure TKMFieldworksList.RemFakeDeletedField(const aLoc: TKMPoint);
var I: Integer;
begin
  for I := 0 to Length(fFakeDeletedFields) - 1 do
    if fFakeDeletedFields[I].Active and KMSamePoint(fFakeDeletedFields[I].Loc, aLoc) then
      fFakeDeletedFields[I].Active := False;
end;


procedure TKMFieldworksList.RemFieldPlan(const aLoc: TKMPoint);
var I: Integer;
begin
  RemFakeDeletedField(aLoc);
  for I := 0 to fFieldsCount - 1 do
  if KMSamePoint(fFields[I].Loc, aLoc) then
  begin
    if fFields[I].Worker <> nil then
      fFields[I].Worker.CancelTask;
    CloseField(I);
    Exit;
  end;
end;


//Will return the field as the game should see it, ignoring all fakes.
function TKMFieldworksList.HasField(const aLoc: TKMPoint): TKMFieldType;
var
  I: Integer;
begin
  Result := ftNone;

  for I := 0 to fFieldsCount - 1 do
  if KMSamePoint(fFields[I].Loc, aLoc) then
  begin
    Result := fFields[I].FieldType;
    Exit;
  end;
end;


//Will return the field as the user should see it.
//Fake fields are shown when the command has not yet been processed, and
//real fields which the user deleted are hidden with the FakeDeletedFields array
function TKMFieldworksList.HasFakeField(const aLoc: TKMPoint): TKMFieldType;
var
  I, K: Integer;
  Found: Boolean;
begin
  Result := ftNone;

  //First check fake fields
  for I := 0 to Length(fFakeFields) - 1 do
  if fFakeFields[I].Active and KMSamePoint(fFakeFields[I].Loc, aLoc) then
  begin
    Result := fFakeFields[I].FieldType;
    Exit;
  end;

  //Now check for real fields that are not deleted
  for I := 0 to fFieldsCount - 1 do
  if KMSamePoint(fFields[I].Loc, aLoc) then
  begin
    Found := False;
    for K := 0 to Length(fFakeDeletedFields) - 1 do
      if fFakeDeletedFields[K].Active and KMSamePoint(fFakeDeletedFields[K].Loc, aLoc) then
      begin
        Found := True; //This field is being deleted, so don't count it
        Break;
      end;
    if not Found then
    begin
      Result := fFields[I].FieldType;
      Exit;
    end;
  end;
end;


//When a worker dies while walking to the task aIndex, we should allow other workers to take this task
procedure TKMFieldworksList.ReOpenField(aIndex: Integer);
begin
  fFields[aIndex].JobStatus := jsOpen;
  gHands.CleanUpUnitPointer(fFields[aIndex].Worker); //Will nil the worker as well
end;


procedure TKMFieldworksList.Save(SaveStream: TKMemoryStream);
var
  I: Integer;
begin
  //Note: Fakes should not be saved, they are just temporary and saves must be consistent acorss all networked computers
  SaveStream.PlaceMarker('FieldworksList');

  SaveStream.Write(fFieldsCount);
  for I := 0 to fFieldsCount - 1 do
  begin
    SaveStream.Write(fFields[I].Loc);
    SaveStream.Write(fFields[I].FieldType, SizeOf(fFields[I].FieldType));
    SaveStream.Write(fFields[I].JobStatus, SizeOf(fFields[I].JobStatus));
    if fFields[I].Worker <> nil then
      SaveStream.Write(fFields[I].Worker.UID)
    else
      SaveStream.Write(Integer(0));
  end;
end;


procedure TKMFieldworksList.Load(LoadStream: TKMemoryStream);
var
  I: Integer;
begin
  LoadStream.CheckMarker('FieldworksList');

  LoadStream.Read(fFieldsCount);
  SetLength(fFields, fFieldsCount);
  for I := 0 to fFieldsCount - 1 do
  begin
    LoadStream.Read(fFields[I].Loc);
    LoadStream.Read(fFields[I].FieldType, SizeOf(fFields[I].FieldType));
    LoadStream.Read(fFields[I].JobStatus, SizeOf(fFields[I].JobStatus));
    LoadStream.Read(fFields[I].Worker, 4);
  end;
end;


procedure TKMFieldworksList.SyncLoad;
var
  I: Integer;
begin
  for I := 0 to fFieldsCount - 1 do
    fFields[I].Worker := gHands.GetUnitByUID(Cardinal(fFields[I].Worker));
end;


{ TKMHousePlanList }
procedure TKMHousePlanList.AddPlan(aHouseType: TKMHouseType; const aLoc: TKMPoint);
var
  I: Integer;
begin
  I := 0;
  while (I < fPlansCount) and (fPlans[I].JobStatus <> jsEmpty) do
    Inc(I);

  if I >= fPlansCount then
    Inc(fPlansCount);

  if I >= Length(fPlans) then
    SetLength(fPlans, Length(fPlans) + LENGTH_INC);

  fPlans[I].UID := gGame.GetNewUID;
  fPlans[I].HouseType := aHouseType;
  fPlans[I].Loc := aLoc;
  fPlans[I].JobStatus := jsOpen;
  fPlans[I].Worker := nil;
end;


function TKMHousePlanList.BestBid(aWorker: TKMUnitWorker; out aBid: Single): Integer;
var
  I: Integer;
  NewBid: Single;
begin
  Result := -1;
  aBid := MaxSingle;

  for I := 0 to fPlansCount - 1 do
    if (fPlans[I].JobStatus = jsOpen)
    and aWorker.CanWalkTo(fPlans[I].Loc, 0)
    then
    begin
      NewBid := KMLengthDiag(aWorker.CurrPosition, fPlans[I].Loc);
      if NewBid < aBid then
      begin
        Result := I;
        aBid := NewBid;
      end;
    end;
end;


function TKMHousePlanList.GetAvailableJobsCount:Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to fPlansCount - 1 do
    if fPlans[I].JobStatus = jsOpen then
      inc(Result);
end;


procedure TKMHousePlanList.ClosePlan(aIndex: Integer);
begin
  fPlans[aIndex].HouseType := htNone;
  fPlans[aIndex].Loc       := KMPOINT_ZERO;
  fPlans[aIndex].JobStatus := jsEmpty;
  gHands.CleanUpUnitPointer(fPlans[aIndex].Worker);
end;


//Find plan nearest to aLoc but skip said location
function TKMHousePlanList.FindHousePlan(const aLoc: TKMPoint; aSkip: TKMPoint; out aOut: TKMPoint): Boolean;
var
  I: Integer;
  Entrance: TKMPoint;
  Dist, Best: Single;
  HD: TKMResHouses;
begin
  Result := False;
  Best := MaxSingle;
  HD := gRes.Houses;

  for I := 0 to fPlansCount - 1 do
  if (fPlans[I].HouseType <> htNone)
  and ((fPlans[I].Loc.X + HD[fPlans[I].HouseType].EntranceOffsetX <> aSkip.X) or (fPlans[I].Loc.Y <> aSkip.Y)) then
  begin
    Entrance := KMPoint(fPlans[I].Loc.X + HD[fPlans[I].HouseType].EntranceOffsetX, fPlans[I].Loc.Y + 1);
    Dist := KMLengthDiag(Entrance, aLoc);
    if Dist < Best then
    begin
      Best := Dist;
      aOut := Entrance;
      Result := True;
    end;
  end;
end;


// Check if this plan exist - aLoc is given by house entrance (offset of plans is moved back to entrance)
function TKMHousePlanList.ExistPlan(const aLoc: TKMPoint; aHT: TKMHouseType): Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := 0 to fPlansCount - 1 do
    if (fPlans[I].HouseType = aHT)
      AND KMSamePoint(  aLoc, KMPointAdd( fPlans[I].Loc, KMPoint(gRes.Houses[aHT].EntranceOffsetX,0) )  ) then
	    Exit;
  Result := False;
end;


procedure TKMHousePlanList.GiveTask(aIndex: Integer; aWorker: TKMUnitWorker);
begin
  aWorker.BuildHouseArea(fPlans[aIndex].HouseType, fPlans[aIndex].Loc, aIndex);
  fPlans[aIndex].JobStatus := jsTaken;
  fPlans[aIndex].Worker := aWorker.GetUnitPointer;
end;


function TKMHousePlanList.HasPlan(const aLoc: TKMPoint; out aHouseType: TKMHouseType): Boolean;
var
  I: Integer;
begin
  Result := False;
  aHouseType := htNone;

  for I := 0 to fPlansCount - 1 do
  if (fPlans[I].HouseType <> htNone)
  and ((aLoc.X - fPlans[I].Loc.X + 3 in [1..4]) and
       (aLoc.Y - fPlans[I].Loc.Y + 4 in [1..4]) and
       (gRes.Houses[fPlans[I].HouseType].BuildArea[aLoc.Y - fPlans[I].Loc.Y + 4, aLoc.X - fPlans[I].Loc.X + 3] <> 0))
  then
  begin
    aHouseType := fPlans[I].HouseType;
    Result := True;
    Exit;
  end;
end;


function TKMHousePlanList.HasPlan(const aLoc: TKMPoint): Boolean;
var
  HT: TKMHouseType;
begin
  Result := HasPlan(aLoc, HT);
end;


procedure TKMHousePlanList.RemPlan(const aLoc: TKMPoint);
var
  I: Integer;
begin
  for I := 0 to fPlansCount - 1 do
  if (fPlans[I].HouseType <> htNone)
  and ((aLoc.X - fPlans[I].Loc.X + 3 in [1..4]) and
       (aLoc.Y - fPlans[I].Loc.Y + 4 in [1..4]) and
       (gRes.Houses[fPlans[I].HouseType].BuildArea[aLoc.Y - fPlans[I].Loc.Y + 4, aLoc.X - fPlans[I].Loc.X + 3] <> 0))
  then
  begin
    if fPlans[I].Worker <> nil then
      fPlans[I].Worker.CancelTask;
    ClosePlan(I);
    Exit;
  end;
end;


function TKMHousePlanList.TryGetPlan(const aLoc: TKMPoint; out aHousePlan: TKMHousePlan): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to fPlansCount - 1 do
  if (fPlans[I].HouseType <> htNone)
  and ((aLoc.X - fPlans[I].Loc.X + 3 in [1..4]) and
       (aLoc.Y - fPlans[I].Loc.Y + 4 in [1..4]) and
       (gRes.Houses[fPlans[I].HouseType].BuildArea[aLoc.Y - fPlans[I].Loc.Y + 4, aLoc.X - fPlans[I].Loc.X + 3] <> 0))
  then
  begin
    aHousePlan := fPlans[I];
    Result := True;
    Exit;
  end;
end;


//When a worker dies while walking to the task aIndex, we should allow other workers to take this task
procedure TKMHousePlanList.ReOpenPlan(aIndex: Integer);
begin
  gHands.CleanUpUnitPointer(fPlans[aIndex].Worker);
  fPlans[aIndex].JobStatus := jsOpen;
end;


procedure TKMHousePlanList.GetOutlines(aList: TKMPointDirList; const aRect: TKMRect);
var
  I,J,K: Integer;
  Rect: TKMRect;
  HA: THouseArea;
begin
  //Expand the Rect by 2 to include plans near Rect borders
  Rect := KMRectGrow(aRect, 2);

  //Test all plans. We use Loc-2 to test plans centers
  for I := 0 to fPlansCount - 1 do
    if (fPlans[I].HouseType <> htNone)
    and InRange(fPlans[I].Loc.X - 2, Rect.Left, Rect.Right)
    and InRange(fPlans[I].Loc.Y - 2, Rect.Top, Rect.Bottom) then
    begin
      HA := gRes.Houses[fPlans[I].HouseType].BuildArea;

      for J := 1 to 4 do for K := 1 to 4 do
      if HA[J,K] <> 0 then
      begin
        if (J = 1) or (HA[J-1, K] = 0) then
          aList.Add(KMPointDir(fPlans[I].Loc.X + K - 3, fPlans[I].Loc.Y + J - 4, dirN));

        if (K = 1) or (HA[J, K-1] = 0) then
          aList.Add(KMPointDir(fPlans[I].Loc.X + K - 3, fPlans[I].Loc.Y + J - 4, dirE));

        if (J = 4) or (HA[J+1, K] = 0) then
          aList.Add(KMPointDir(fPlans[I].Loc.X + K - 3, fPlans[I].Loc.Y + J - 4, dirS));

        if (K = 4) or (HA[J, K+1] = 0) then
          aList.Add(KMPointDir(fPlans[I].Loc.X + K - 3, fPlans[I].Loc.Y + J - 4, dirW));
      end;
    end;
end;


procedure TKMHousePlanList.GetTablets(aList: TKMPointTagList; const aRect: TKMRect);
var
  I: Integer;
  Rect: TKMRect;
begin
  //Expand the Rect by 2 to include tablets near Rect borders
  Rect := KMRectGrow(aRect, 2);

  for I := 0 to fPlansCount - 1 do
  if (fPlans[I].HouseType <> htNone)
  and InRange(fPlans[I].Loc.X - 2, Rect.Left, Rect.Right)
  and InRange(fPlans[I].Loc.Y - 2, Rect.Top, Rect.Bottom) then
    aList.Add(KMPoint(fPlans[I].Loc.X + gRes.Houses[fPlans[I].HouseType].EntranceOffsetX, fPlans[I].Loc.Y), Byte(fPlans[I].HouseType));
end;


procedure TKMHousePlanList.Save(SaveStream: TKMemoryStream);
var
  I: Integer;
begin
  SaveStream.PlaceMarker('HousePlanList');

  SaveStream.Write(fPlansCount);
  for I := 0 to fPlansCount - 1 do
  with fPlans[I] do
  begin
    SaveStream.Write(HouseType, SizeOf(HouseType));
    SaveStream.Write(Loc);
    SaveStream.Write(JobStatus, SizeOf(JobStatus));
    if Worker <> nil then
      SaveStream.Write(Worker.UID)
    else
      SaveStream.Write(Integer(0));
  end;
end;


procedure TKMHousePlanList.Load(LoadStream: TKMemoryStream);
var I: Integer;
begin
  LoadStream.CheckMarker('HousePlanList');

  LoadStream.Read(fPlansCount);
  SetLength(fPlans, fPlansCount);
  for I := 0 to fPlansCount - 1 do
  with fPlans[I] do
  begin
    LoadStream.Read(HouseType, SizeOf(HouseType));
    LoadStream.Read(Loc);
    LoadStream.Read(JobStatus, SizeOf(JobStatus));
    LoadStream.Read(Worker, 4);
  end;
end;


procedure TKMHousePlanList.SyncLoad;
var
  I: Integer;
begin
  for I := 0 to fPlansCount - 1 do
    fPlans[I].Worker := gHands.GetUnitByUID(Cardinal(fPlans[I].Worker));
end;


{ TKMRepairList }
destructor TKMRepairList.Destroy;
var
  I: Integer;
begin
  for I := 0 to fHousesCount - 1 do
  if fHouses[I].House <> nil then
    gHands.CleanUpHousePointer(fHouses[I].House);

  inherited;
end;


function TKMRepairList.HouseAlreadyInList(aHouse: TKMHouse): Boolean;
var I: Integer;
begin
  Result := False;

  for I := 0 to fHousesCount - 1 do
    if fHouses[I].House = aHouse then
    begin
      Result := True;
      Exit;
    end;
end;


//Include the House into the List
procedure TKMRepairList.AddHouse(aHouse: TKMHouse);
var I: Integer;
begin
  if HouseAlreadyInList(aHouse) then Exit;

  I := 0;
  while (I < fHousesCount) and (fHouses[I].House <> nil) do
    Inc(I);

  if I >= fHousesCount then
    Inc(fHousesCount);

  if I >= Length(fHouses) then
    SetLength(fHouses, Length(fHouses) + LENGTH_INC);

  fHouses[I].House := aHouse.GetHousePointer;
  fHouses[I].Assigned := 0;
end;


function TKMRepairList.BestBid(aWorker: TKMUnitWorker; out aBid: Single): Integer;
var
  I: Integer;
  NewBid: Single;
begin
  //We can weight the repairs by distance, severity, etc..
  //For now, each worker will go for the house closest to him

  Result := -1;
  aBid := MaxSingle;
  for I := 0 to fHousesCount - 1 do
  if (fHouses[I].House <> nil)
  and (fHouses[I].Assigned < MAX_WORKERS[fHouses[i].House.HouseType]) then
  begin
    NewBid := KMLengthDiag(aWorker.CurrPosition, fHouses[I].House.Position);
    NewBid := NewBid + fHouses[I].Assigned * BID_MODIF;

    if NewBid < aBid then
    begin
      aBid := NewBid;
      Result := I;
    end;
  end;
end;


function TKMRepairList.GetAvailableJobsCount:Integer;
var I: Integer;
begin
  Result := 0;
  for I := 0 to fHousesCount - 1 do
    if fHouses[i].House <> nil then
      inc(Result);
end;


procedure TKMRepairList.GiveTask(aIndex: Integer; aWorker: TKMUnitWorker);
begin
  aWorker.BuildHouseRepair(fHouses[aIndex].House, aIndex);
  Inc(fHouses[aIndex].Assigned);
end;


procedure TKMRepairList.RemWorker(aIndex: Integer);
begin
  Dec(fHouses[aIndex].Assigned);
end;


//Remove houses that should not be repaired any more
procedure TKMRepairList.RemoveExtraHouses;
var
  I: Integer;
begin
  for I := 0 to fHousesCount - 1 do
    if (fHouses[I].House <> nil)
    and (not fHouses[I].House.IsDamaged
         or not fHouses[I].House.BuildingRepair
         or fHouses[I].House.IsDestroyed)
    and (fHouses[I].Assigned = 0) then
      gHands.CleanUpHousePointer(fHouses[I].House);
end;


procedure TKMRepairList.UpdateState;
begin
  RemoveExtraHouses;
end;


procedure TKMRepairList.Save(SaveStream: TKMemoryStream);
var
  I: Integer;
begin
  SaveStream.PlaceMarker('RepairList');

  SaveStream.Write(fHousesCount);
  for I := 0 to fHousesCount - 1 do
  begin
    if fHouses[I].House <> nil then
      SaveStream.Write(fHouses[I].House.UID)
    else
      SaveStream.Write(Integer(0));
    SaveStream.Write(fHouses[I].Assigned);
  end;
end;


procedure TKMRepairList.Load(LoadStream: TKMemoryStream);
var I: Integer;
begin
  LoadStream.CheckMarker('RepairList');

  LoadStream.Read(fHousesCount);
  SetLength(fHouses, fHousesCount);
  for I := 0 to fHousesCount - 1 do
  begin
    LoadStream.Read(fHouses[I].House, 4);
    LoadStream.Read(fHouses[I].Assigned);
  end;
end;


procedure TKMRepairList.SyncLoad;
var I: Integer;
begin
  for I := 0 to fHousesCount - 1 do
    fHouses[I].House := gHands.GetHouseByUID(Cardinal(fHouses[I].House));
end;


{ TKMWorkersList }
constructor TKMBuildList.Create;
begin
  inherited;
  fFieldworksList := TKMFieldworksList.Create;
  fHouseList := TKMHouseList.Create;
  fHousePlanList := TKMHousePlanList.Create;
  fRepairList := TKMRepairList.Create;
end;


destructor TKMBuildList.Destroy;
var
  I: Integer;
begin
  fFieldworksList.Free;
  fHouseList.Free;
  fHousePlanList.Free;
  fRepairList.Free;

  for I := fWorkersCount - 1 downto 0 do
    gHands.CleanUpUnitPointer(TKMUnit(fWorkers[I].Worker));

  inherited;
end;


//Add the Worker to the List
procedure TKMBuildList.AddWorker(aWorker: TKMUnitWorker);
begin
  if fWorkersCount >= Length(fWorkers) then
    SetLength(fWorkers, fWorkersCount + LENGTH_INC);

  fWorkers[fWorkersCount].Worker := TKMUnitWorker(aWorker.GetUnitPointer);
  Inc(fWorkersCount);
end;

//Remove died Worker from the List
procedure TKMBuildList.RemWorker(aIndex: Integer);
begin
  gHands.CleanUpUnitPointer(TKMUnit(fWorkers[aIndex].Worker));

  if aIndex <> fWorkersCount - 1 then
    Move(fWorkers[aIndex+1], fWorkers[aIndex], SizeOf(fWorkers[aIndex]) * (fWorkersCount - 1 - aIndex));

  Dec(fWorkersCount);
end;


//Remove dead workers
procedure TKMBuildList.RemoveExtraWorkers;
var
  I: Integer;
begin
  for I := fWorkersCount - 1 downto 0 do
    if fWorkers[I].Worker.IsDeadOrDying then
      RemWorker(I);
end;


procedure TKMBuildList.Save(SaveStream: TKMemoryStream);
var
  I: Integer;
begin
  SaveStream.PlaceMarker('WorkerList');

  SaveStream.Write(fWorkersCount);
  for I := 0 to fWorkersCount - 1 do
  begin
    if fWorkers[I].Worker <> nil then
      SaveStream.Write(fWorkers[I].Worker.UID)
    else
      SaveStream.Write(Integer(0));
  end;

  fFieldworksList.Save(SaveStream);
  fHouseList.Save(SaveStream);
  fHousePlanList.Save(SaveStream);
  fRepairList.Save(SaveStream);
end;


procedure TKMBuildList.Load(LoadStream: TKMemoryStream);
var I: Integer;
begin
  LoadStream.CheckMarker('WorkerList');

  LoadStream.Read(fWorkersCount);
  SetLength(fWorkers, fWorkersCount);
  for I := 0 to fWorkersCount - 1 do
    LoadStream.Read(fWorkers[I].Worker, 4);

  fFieldworksList.Load(LoadStream);
  fHouseList.Load(LoadStream);
  fHousePlanList.Load(LoadStream);
  fRepairList.Load(LoadStream);
end;


procedure TKMBuildList.SyncLoad;
var I: Integer; U: TKMUnit;
begin
  for I := 0 to fWorkersCount - 1 do
  begin
    U := gHands.GetUnitByUID(Cardinal(fWorkers[I].Worker));
    Assert(U is TKMUnitWorker, 'Non-worker in build list');
    fWorkers[I].Worker := TKMUnitWorker(U);
  end;

  fFieldworksList.SyncLoad;
  fHouseList.SyncLoad;
  fHousePlanList.SyncLoad;
  fRepairList.SyncLoad;
end;


function TKMBuildList.GetIdleWorkerCount: Integer;
var I: Integer;
begin
  Result := 0;
  for I := 0 to fWorkersCount - 1 do
    if fWorkers[I].Worker.IsIdle then
      inc(Result);
end;


function TKMBuildList.GetBestWorker(const aPoint: TKMPoint): TKMUnitWorker;
var
  I: Integer;
  NewBid, BestBid: Single;
begin
  Result := nil;
  BestBid := MaxSingle;
  for I := 0 to fWorkersCount - 1 do
    if fWorkers[I].Worker.IsIdle and fWorkers[I].Worker.CanWalkTo(aPoint, 0) then
    begin
      NewBid := KMLengthDiag(fWorkers[I].Worker.CurrPosition, aPoint);
      if NewBid < BestBid then
      begin
        Result := fWorkers[I].Worker;
        BestBid := NewBid;
      end;
    end;
end;


procedure TKMBuildList.AssignFieldworks;
var
  I, AvailableWorkers, AvailableJobs, JobID: Integer;
  MyBid: Single;
  BestWorker:TKMUnitWorker;
begin
  AvailableWorkers := GetIdleWorkerCount;
  AvailableJobs := fFieldworksList.GetAvailableJobsCount;
  if AvailableWorkers*AvailableJobs = 0 then Exit;

  if AvailableJobs > AvailableWorkers then
  begin
    for I := 0 to fWorkersCount - 1 do
      if fWorkers[I].Worker.IsIdle then
      begin
        JobID := fFieldworksList.BestBid(fWorkers[I].Worker, MyBid);
        if JobID <> -1 then fFieldworksList.GiveTask(JobID, fWorkers[I].Worker);
      end;
  end
  else
    for I := 0 to fFieldworksList.fFieldsCount - 1 do
      if fFieldworksList.fFields[I].JobStatus = jsOpen then
      begin
        BestWorker := GetBestWorker(fFieldworksList.fFields[I].Loc);
        if BestWorker <> nil then fFieldworksList.GiveTask(I, BestWorker);
      end;
end;


procedure TKMBuildList.AssignHousePlans;
var
  I, AvailableWorkers, AvailableJobs, JobID: Integer;
  MyBid: Single;
  BestWorker:TKMUnitWorker;
begin
  AvailableWorkers := GetIdleWorkerCount;
  AvailableJobs := fHousePlanList.GetAvailableJobsCount;
  if AvailableWorkers*AvailableJobs = 0 then Exit;

  if AvailableJobs > AvailableWorkers then
  begin
    for I := 0 to fWorkersCount - 1 do
      if fWorkers[I].Worker.IsIdle then
      begin
        JobID := fHousePlanList.BestBid(fWorkers[I].Worker, MyBid);
        if JobID <> -1 then fHousePlanList.GiveTask(JobID, fWorkers[I].Worker);
      end;
  end
  else
    for I := 0 to fHousePlanList.fPlansCount - 1 do
      if fHousePlanList.fPlans[I].JobStatus = jsOpen then
      begin
        BestWorker := GetBestWorker(fHousePlanList.fPlans[I].Loc);
        if BestWorker <> nil then fHousePlanList.GiveTask(I, BestWorker);
      end;
end;


procedure TKMBuildList.AssignHouses;
var
  I, AvailableWorkers, AvailableJobs, JobID: Integer;
  MyBid: Single;
  BestWorker: TKMUnitWorker;
begin
  AvailableWorkers := GetIdleWorkerCount;
  AvailableJobs := fHouseList.GetAvailableJobsCount;
  if AvailableWorkers*AvailableJobs = 0 then Exit;

  if AvailableJobs > AvailableWorkers then
  begin
    for I := 0 to fWorkersCount - 1 do
      if fWorkers[I].Worker.IsIdle then
      begin
        JobID := fHouseList.BestBid(fWorkers[I].Worker, MyBid);
        if JobID <> -1 then fHouseList.GiveTask(JobID, fWorkers[I].Worker);
      end;
  end
  else
    for I := 0 to fHouseList.fHousesCount - 1 do
      if (fHouseList.fHouses[i].House <> nil) and fHouseList.fHouses[i].House.CheckResToBuild
      and(fHouseList.fHouses[I].Assigned < MAX_WORKERS[fHouseList.fHouses[i].House.HouseType]) then
      begin
        BestWorker := GetBestWorker(fHouseList.fHouses[I].House.PointBelowEntrance);
        if BestWorker <> nil then fHouseList.GiveTask(I, BestWorker);
      end;
end;


procedure TKMBuildList.AssignRepairs;
var
  I, AvailableWorkers, AvailableJobs, JobID: Integer;
  MyBid: Single;
  BestWorker: TKMUnitWorker;
begin
  AvailableWorkers := GetIdleWorkerCount;
  AvailableJobs := fRepairList.GetAvailableJobsCount;
  if AvailableWorkers*AvailableJobs = 0 then Exit;

  if AvailableJobs > AvailableWorkers then
  begin
    for I := 0 to fWorkersCount - 1 do
      if fWorkers[I].Worker.IsIdle then
      begin
        JobID := fRepairList.BestBid(fWorkers[I].Worker, MyBid);
        if JobID <> -1 then fRepairList.GiveTask(JobID, fWorkers[I].Worker);
      end;
  end
  else
    for I := 0 to fRepairList.fHousesCount - 1 do
      if (fRepairList.fHouses[i].House <> nil)
      and(fRepairList.fHouses[I].Assigned < MAX_WORKERS[fRepairList.fHouses[i].House.HouseType]) then
      begin
        BestWorker := GetBestWorker(fRepairList.fHouses[I].House.PointBelowEntrance);
        if BestWorker <> nil then fRepairList.GiveTask(I, BestWorker);
      end;
end;


procedure TKMBuildList.UpdateState;
begin
  HouseList.UpdateState;
  fRepairList.UpdateState;

  RemoveExtraWorkers;

  //In 99% of cases we have either of these situations:
  //  1. Lots of jobs, only few workers to do them.
  //  2. Lots of workers, only a few jobs for them to do.
  //In case 1. the best solution is to parse workers list and find the best job for him
  //In case 2. the best solution is to parse jobs list and find the best worker for the job
  //This approach should give jobs more sensibly than just parsing workers or parsing jobs list each time.
  //A hungarian solution would be better as a long term goal (match list of workers/jobs optimally) but
  //keep in mind that it will only be more efficient when BOTH IdleWorkerCount and JobCount are > 1,
  //which is very rare (only when ordering a large number of jobs within 2 seconds)

  //In KaM the order is:
  //1. House plans
  //2. Fieldworks
  //3. Houses
  //4. Repairs
  //However we decided to make repairs the highest priority since the player has absolute control over it
  //(they can switch repair off at any time) and only a limited number of workers can be assigned to each
  //repair job (same as for building houses)
  AssignRepairs;
  AssignHousePlans;
  AssignFieldworks;
  AssignHouses;
end;


function TKMHousePlanList.GetPlansStoneDemands(): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to fPlansCount - 1 do
    if (fPlans[I].HouseType <> htNone) then // fPlansCount may not be updated
      Result := Result + gRes.Houses[ fPlans[I].HouseType ].StoneCost;
end;


function TKMHousePlanList.GetPlansWoodDemands(): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to fPlansCount - 1 do
    if (fPlans[I].HouseType <> htNone) then // fPlansCount may not be updated
      Result := Result + gRes.Houses[ fPlans[I].HouseType ].WoodCost;
end;

end.
