unit KM_UnitTaskBuild;
{$I KaM_Remake.inc}
interface
uses
  SysUtils,
  KM_CommonClasses, KM_Defaults, KM_Points,
  KM_Houses, KM_Terrain, KM_Units, KM_ResHouses;


//Do the building
type
  TKMTaskBuild = class(TKMUnitTask)
  public
    procedure CancelThePlan; virtual; abstract;
    function CouldBeCancelled: Boolean; override;
  end;

  TKMTaskBuildRoad = class(TKMTaskBuild)
  private
    fLoc: TKMPoint;
    fIsDigged: Boolean;
    BuildID: Integer;
    DemandSet: Boolean;
    TileLockSet: Boolean;
  public
    constructor Create(aWorker: TKMUnitWorker; const aLoc: TKMPoint; aID: Integer);
    constructor Load(LoadStream: TKMemoryStream); override;
    destructor Destroy; override;
    function WalkShouldAbandon: Boolean; override;
    procedure CancelThePlan; override;
    function Execute: TKMTaskResult; override;
    procedure Save(SaveStream: TKMemoryStream); override;
  end;

  TKMTaskBuildWine = class(TKMTaskBuild)
  private
    fLoc: TKMPoint;
    fIsDigged: Boolean;
    BuildID: Integer;
    DemandSet: Boolean;
    TileLockSet: Boolean;
  public
    constructor Create(aWorker: TKMUnitWorker; const aLoc: TKMPoint; aID: Integer);
    constructor Load(LoadStream: TKMemoryStream); override;
    destructor Destroy; override;
    function WalkShouldAbandon: Boolean; override;
    procedure CancelThePlan; override;
    function Execute: TKMTaskResult; override;
    procedure Save(SaveStream: TKMemoryStream); override;
  end;

  TKMTaskBuildField = class(TKMTaskBuild)
  private
    fLoc: TKMPoint;
    BuildID: Integer;
    TileLockSet: Boolean;
  public
    constructor Create(aWorker: TKMUnitWorker; const aLoc: TKMPoint; aID: Integer);
    constructor Load(LoadStream: TKMemoryStream); override;
    destructor Destroy; override;
    function WalkShouldAbandon: Boolean; override;
    procedure CancelThePlan; override;
    function Execute: TKMTaskResult; override;
    procedure Save(SaveStream: TKMemoryStream); override;
  end;

  TKMTaskBuildHouseArea = class(TKMTaskBuild)
  private
    fHouse: TKMHouse;
    fHouseType: TKMHouseType;
    fHouseLoc: TKMPoint;
    BuildID: Integer;
    HouseNeedsWorker: Boolean;
    HouseReadyToBuild: Boolean;
    CellsToDig: array [0..15] of TKMPoint; //max house square is 4*4
    LastToDig: ShortInt;
    function GetHouseEntranceLoc: TKMPoint;
  public
    constructor Create(aWorker: TKMUnitWorker; aHouseType: TKMHouseType; const aLoc: TKMPoint; aID: Integer);
    constructor Load(LoadStream: TKMemoryStream); override;
    property DigState: ShortInt read LastToDig;
    procedure SyncLoad; override;
    destructor Destroy; override;
    function WalkShouldAbandon: Boolean; override;
    procedure CancelThePlan; override;
    function Digging: Boolean;
    function Execute: TKMTaskResult; override;
    procedure Save(SaveStream: TKMemoryStream); override;
  end;

  TKMTaskBuildHouse = class(TKMUnitTask)
  private
    fHouse: TKMHouse;
    BuildID: Integer;
    BuildFrom: TKMPointDir; //Current WIP location
    Cells: TKMPointDirList; //List of surrounding cells and directions
  public
    constructor Create(aWorker: TKMUnitWorker; aHouse: TKMHouse; aID: Integer);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure SyncLoad; override;
    destructor Destroy; override;
    function WalkShouldAbandon: Boolean; override;
    function CouldBeCancelled: Boolean; override;
    function Execute: TKMTaskResult; override;
    procedure Save(SaveStream:TKMemoryStream); override;
  end;

  TKMTaskBuildHouseRepair = class(TKMUnitTask)
  private
    fHouse: TKMHouse;
    fRepairID: Integer; //Remember the house we repair to report if we died and let others take our place
    BuildFrom: TKMPointDir; //Current WIP location
    Cells: TKMPointDirList; //List of surrounding cells and directions
  public
    constructor Create(aWorker: TKMUnitWorker; aHouse: TKMHouse; aRepairID: Integer);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure SyncLoad; override;
    destructor Destroy; override;
    function WalkShouldAbandon: Boolean; override;
    function CouldBeCancelled: Boolean; override;
    function Execute: TKMTaskResult; override;
    procedure Save(SaveStream: TKMemoryStream); override;
  end;


implementation
uses
  KM_HandLogistics, KM_HandsCollection, KM_Resource, KM_ResMapElements,
  KM_ResWares, KM_Game, KM_Hand, KM_ScriptingEvents;


{ TKMTaskBuild }
function TKMTaskBuild.CouldBeCancelled: Boolean;
begin
  Result := (fPhase - 1) //phase was increased at the end of execution
                   <= 0; //Allow cancel task only at walking phases
end;


{ TKMTaskBuildRoad }
constructor TKMTaskBuildRoad.Create(aWorker:TKMUnitWorker; const aLoc:TKMPoint; aID:integer);
begin
  inherited Create(aWorker);
  fType := uttBuildRoad;
  fLoc      := aLoc;
  BuildID   := aID;
  DemandSet := False;
  TileLockSet := False;
end;


constructor TKMTaskBuildRoad.Load(LoadStream:TKMemoryStream);
begin
  inherited;
  LoadStream.Read(fLoc);
  LoadStream.Read(BuildID);
  LoadStream.Read(DemandSet);
  LoadStream.Read(TileLockSet);
end;


destructor TKMTaskBuildRoad.Destroy;
begin
  if (fUnit <> nil) and DemandSet then
    gHands[fUnit.Owner].Deliveries.Queue.RemDemand(fUnit);

  if TileLockSet then
    gTerrain.UnlockTile(fLoc);

  //Yet unstarted
  if (fUnit <> nil) then
  begin
    if BuildID <> -1 then
    begin
      if gTerrain.CanAddField(fLoc.X, fLoc.Y, ftRoad) then
        //Allow other workers to take this task
        gHands[fUnit.Owner].BuildList.FieldworksList.ReOpenField(BuildID)
      else
        //This plan is not valid anymore
        gHands[fUnit.Owner].BuildList.FieldworksList.CloseField(BuildID);
    end
    else
      //Autobuild AI should rebuild roads when worker dies (otherwise house is never built)
      if (gGame <> nil) and not gGame.IsExiting and gHands[fUnit.Owner].AI.Setup.AutoBuild and (fPhase < 9)
      and gHands[fUnit.Owner].CanAddFieldPlan(fLoc, ftRoad) then
        gHands[fUnit.Owner].BuildList.FieldworksList.AddField(fLoc, ftRoad);
  end;

  inherited;
end;


function TKMTaskBuildRoad.WalkShouldAbandon: Boolean;
begin
  //Walk should abandon if other player has built something there before we arrived
  Result := (BuildID <> -1) and not gTerrain.CanAddField(fLoc.X, fLoc.Y, ftRoad);
end;


procedure TKMTaskBuildRoad.CancelThePlan;
begin
  gHands[fUnit.Owner].BuildList.FieldworksList.CloseField(BuildID); //Close the job now because it can no longer be cancelled
  BuildID := -1;
end;


function TKMTaskBuildRoad.Execute: TKMTaskResult;
begin
  Result := trTaskContinues;

  if WalkShouldAbandon then
  begin
    Result := trTaskDone;
    Exit;
  end;

  with fUnit do
  case fPhase of
    0: begin
         SetActionWalkToSpot(fLoc);
         Thought := thBuild;
       end;
    1: begin
         Thought := thNone;
         gTerrain.SetTileLock(fLoc, tlRoadWork);
         TileLockSet := True;

         CancelThePlan;

         gHands[Owner].Deliveries.Queue.AddDemand(nil, fUnit, wtStone, 1, dtOnce, diHigh4);
         DemandSet := true;

         SetActionLockedStay(11,uaWork1,false);
       end;
    2: begin
         gTerrain.ResetDigState(fLoc); //Remove any dig over that might have been there (e.g. destroyed house) after first dig
         gTerrain.IncDigState(fLoc);
         SetActionLockedStay(11,uaWork1,false);
       end;
    3: begin
         gTerrain.IncDigState(fLoc);
         SetActionLockedStay(11,uaWork1,false);
       end;
    //Warning! This step value is harcoded in KM_UnitTaskDelivery
    4: begin //This step is repeated until Serf brings us some stone
         SetActionLockedStay(30,uaWork1);
         Thought := thStone;
         if not fIsDigged then
         begin
           gScriptEvents.ProcPlanRoadDigged(Owner, fLoc.X, fLoc.Y);
           fIsDigged := true;
         end;
       end;
    5: begin
         SetActionLockedStay(11,uaWork2,false);
         DemandSet := false;
         Thought := thNone;
       end;
    6: begin
         gTerrain.IncDigState(fLoc);
         SetActionLockedStay(11,uaWork2,false);
       end;
    7: begin
         gTerrain.IncDigState(fLoc);
         gTerrain.FlattenTerrain(fLoc); //Flatten the terrain slightly on and around the road
         if gMapElements[gTerrain.Land[fLoc.Y,fLoc.X].Obj].WineOrCorn then
           gTerrain.RemoveObject(fLoc); //Remove corn/wine/grass as they won't fit with road
         SetActionLockedStay(11,uaWork2,false);
       end;
    8: begin
         gTerrain.SetRoad(fLoc, Owner);
         gTerrain.RemoveObjectsKilledByRoad(fLoc);
         SetActionStay(5, uaWalk);
         gTerrain.UnlockTile(fLoc);
         TileLockSet := False;
       end;
    else Result := trTaskDone;
  end;
  if fPhase<>4 then inc(fPhase); //Phase=4 is when worker waits for rtStone
end;


procedure TKMTaskBuildRoad.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fLoc);
  SaveStream.Write(BuildID);
  SaveStream.Write(DemandSet);
  SaveStream.Write(TileLockSet);
end;


{ TTaskBuildWine }
constructor TKMTaskBuildWine.Create(aWorker: TKMUnitWorker; const aLoc: TKMPoint; aID: Integer);
begin
  inherited Create(aWorker);
  fType := uttBuildWine;
  fLoc      := aLoc;
  BuildID   := aID;
  DemandSet := False;
  TileLockSet := False;
end;


constructor TKMTaskBuildWine.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.Read(fLoc);
  LoadStream.Read(BuildID);
  LoadStream.Read(DemandSet);
  LoadStream.Read(TileLockSet);
end;


destructor TKMTaskBuildWine.Destroy;
begin
  //Yet unstarted
  if BuildID <> -1 then
    if gTerrain.CanAddField(fLoc.X, fLoc.Y, ftWine) then
      //Allow other workers to take this task
      gHands[fUnit.Owner].BuildList.FieldworksList.ReOpenField(BuildID)
    else
      //This plan is not valid anymore
      gHands[fUnit.Owner].BuildList.FieldworksList.CloseField(BuildID);

  if DemandSet then
    gHands[fUnit.Owner].Deliveries.Queue.RemDemand(fUnit);

  if TileLockSet then
    gTerrain.UnlockTile(fLoc);
  inherited;
end;


function TKMTaskBuildWine.WalkShouldAbandon: Boolean;
begin
  //Walk should abandon if other player has built something there before we arrived
  Result := (BuildID <> -1) and not gTerrain.CanAddField(fLoc.X, fLoc.Y, ftWine);
end;


procedure TKMTaskBuildWine.CancelThePlan;
begin
  gHands[fUnit.Owner].BuildList.FieldworksList.CloseField(BuildID); //Close the job now because it can no longer be cancelled
  BuildID := -1;
end;


function TKMTaskBuildWine.Execute: TKMTaskResult;
begin
  Result := trTaskContinues;

  if WalkShouldAbandon then
  begin
    Result := trTaskDone;
    Exit;
  end;

  with fUnit do
  case fPhase of
   0: begin
        SetActionWalkToSpot(fLoc);
        Thought := thBuild;
      end;
   1: begin
        Thought := thNone;
        gTerrain.SetTileLock(fLoc, tlFieldWork);
        TileLockSet := True;

        CancelThePlan;

        gTerrain.ResetDigState(fLoc); //Remove any dig over that might have been there (e.g. destroyed house)

        gHands[Owner].Deliveries.Queue.AddDemand(nil,fUnit,wtWood, 1, dtOnce, diHigh4);
        DemandSet := true;

        SetActionLockedStay(12*4,uaWork1,false);
      end;
   2: begin
        gTerrain.IncDigState(fLoc);
        SetActionLockedStay(24,uaWork1,false);
      end;
   3: begin
        gTerrain.IncDigState(fLoc);
        SetActionLockedStay(24,uaWork1,false);
      end;
   4: begin
        gTerrain.ResetDigState(fLoc);
        gTerrain.SetInitWine(fLoc, Owner); //Replace the terrain, but don't seed grapes yet
        SetActionLockedStay(30, uaWork1);
        Thought := thWood;
        if not fIsDigged then
        begin
          gScriptEvents.ProcPlanWinefieldDigged(Owner, fLoc.X, fLoc.Y);
          fIsDigged := true;
        end;
      end;
   //Warning! This step value is harcoded in KM_UnitTaskDelivery
   5: begin //This step is repeated until Serf brings us some wood
        SetActionLockedStay(30, uaWork1);
        Thought := thWood;
      end;
   6: begin
        DemandSet := false;
        SetActionLockedStay(11*8, uaWork2, False);
        Thought := thNone;
      end;
   7: begin
        gTerrain.SetField(fLoc, Owner, ftWine);
        SetActionStay(5, uaWalk);
        gTerrain.UnlockTile(fLoc);
        TileLockSet := False;
      end;
   else Result := trTaskDone;
  end;
  if fPhase<>5 then inc(fPhase); //Phase=5 is when worker waits for rtWood
end;


procedure TKMTaskBuildWine.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fLoc);
  SaveStream.Write(BuildID);
  SaveStream.Write(DemandSet);
  SaveStream.Write(TileLockSet);
end;


{ TTaskBuildField }
constructor TKMTaskBuildField.Create(aWorker:TKMUnitWorker; const aLoc:TKMPoint; aID: Integer);
begin
  inherited Create(aWorker);
  fType := uttBuildField;
  fLoc      := aLoc;
  BuildID   := aID;
  TileLockSet := False;
end;


constructor TKMTaskBuildField.Load(LoadStream:TKMemoryStream);
begin
  inherited;
  LoadStream.Read(fLoc);
  LoadStream.Read(BuildID);
  LoadStream.Read(TileLockSet);
end;


destructor TKMTaskBuildField.Destroy;
begin
  //Yet unstarted
  if BuildID <> -1 then
    if gTerrain.CanAddField(fLoc.X, fLoc.Y, ftCorn) then
      //Allow other workers to take this task
      gHands[fUnit.Owner].BuildList.FieldworksList.ReOpenField(BuildID)
    else
      //This plan is not valid anymore
      gHands[fUnit.Owner].BuildList.FieldworksList.CloseField(BuildID);

  if TileLockSet then gTerrain.UnlockTile(fLoc);
  inherited;
end;


function TKMTaskBuildField.WalkShouldAbandon: Boolean;
begin
  //Walk should abandon if other player has built something there before we arrived
  Result := (BuildID <> -1) and not gTerrain.CanAddField(fLoc.X, fLoc.Y, ftCorn);
end;


procedure TKMTaskBuildField.CancelThePlan;
begin
  gHands[fUnit.Owner].BuildList.FieldworksList.CloseField(BuildID); //Close the job now because it can no longer be cancelled
  BuildID := -1;
end;


function TKMTaskBuildField.Execute: TKMTaskResult;
begin
  Result := trTaskContinues;

  if WalkShouldAbandon then
  begin
    Result := trTaskDone;
    Exit;
  end;

  with fUnit do
  case fPhase of
    0: begin
         SetActionWalkToSpot(fLoc);
         Thought := thBuild;
       end;
    1: begin
        gTerrain.SetTileLock(fLoc, tlFieldWork);
        TileLockSet := True;
        CancelThePlan;
        SetActionLockedStay(0,uaWalk);
       end;
    2: begin
        SetActionLockedStay(11,uaWork1,false);
        inc(fPhase2);
        if fPhase2 = 2 then gTerrain.ResetDigState(fLoc); //Remove any dig over that might have been there (e.g. destroyed house)
        if (fPhase2 = 6) and gMapElements[gTerrain.Land[fLoc.Y,fLoc.X].Obj].WineOrCorn then
          gTerrain.RemoveObject(fLoc); //Remove grass/corn/wine as they take up most of the tile
        if fPhase2 in [6,8] then gTerrain.IncDigState(fLoc);
       end;
    3: begin
        Thought := thNone; //Keep thinking build until it's done
        gTerrain.SetField(fLoc, Owner, ftCorn);
        SetActionStay(5,uaWalk);
        gTerrain.UnlockTile(fLoc);
        TileLockSet := False;
       end;
    else Result := trTaskDone;
  end;
  if fPhase2 in [0,10] then inc(fPhase);
end;


procedure TKMTaskBuildField.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fLoc);
  SaveStream.Write(BuildID);
  SaveStream.Write(TileLockSet);
end;


{ TTaskBuildHouseArea }
constructor TKMTaskBuildHouseArea.Create(aWorker: TKMUnitWorker; aHouseType: TKMHouseType; const aLoc: TKMPoint; aID: Integer);
var
  I,K: Integer;
  HA: THouseArea;
begin
  inherited Create(aWorker);
  fType  := uttBuildHouseArea;
  fHouseType := aHouseType;
  fHouseLoc  := aLoc;
  BuildID    := aID;
  HouseNeedsWorker  := False; //House needs this worker to complete
  HouseReadyToBuild := False; //House is ready to be built

  HA := gRes.Houses[fHouseType].BuildArea;

  //Fill Cells left->right, top->bottom. Worker will start flattening from the end (reversed)
  LastToDig := -1;
  for I := 1 to 4 do for K := 1 to 4 do
  if HA[I,K] <> 0 then
  begin
    Inc(LastToDig);
    CellsToDig[LastToDig] := KMPoint(fHouseLoc.X + K - 3, fHouseLoc.Y + I - 4);
  end;
end;


constructor TKMTaskBuildHouseArea.Load(LoadStream:TKMemoryStream);
begin
  inherited;

  LoadStream.Read(fHouse, 4);
  LoadStream.Read(fHouseType, SizeOf(fHouseType));
  LoadStream.Read(fHouseLoc);
  LoadStream.Read(BuildID);
  LoadStream.Read(HouseNeedsWorker);
  LoadStream.Read(HouseReadyToBuild);
  LoadStream.Read(LastToDig);
  LoadStream.Read(CellsToDig, SizeOf(CellsToDig));
end;


procedure TKMTaskBuildHouseArea.SyncLoad;
begin
  inherited;
  fHouse := gHands.GetHouseByUID(cardinal(fHouse));
end;


{ We need to revert all changes made }
destructor TKMTaskBuildHouseArea.Destroy;
begin
  //Don't demolish the house when the game is exiting (causes wrong stats and errors in script)
  if (gGame = nil) or gGame.IsExiting then
	  Exit;

  //Yet unstarted
  if (BuildID <> -1) then
    if gTerrain.CanPlaceHouse(GetHouseEntranceLoc,fHouseType) then
      //Allow other workers to take this task
      gHands[fUnit.Owner].BuildList.HousePlanList.ReOpenPlan(BuildID)
    else
    begin
      //This plan is not valid anymore
      gHands[fUnit.Owner].BuildList.HousePlanList.ClosePlan(BuildID);
      gHands[fUnit.Owner].Stats.HousePlanRemoved(fHouseType);
    end;

  //Destroy the house if worker was killed (e.g. by archer or hunger)
  //as we don't have mechanics to resume the building process yet
  if HouseNeedsWorker and (fHouse <> nil) and not fHouse.IsDestroyed then
    fHouse.DemolishHouse(fUnit.Owner);

  //Complete the task in the end (Worker could have died while trying to exit building area)
  if HouseReadyToBuild and not HouseNeedsWorker and (fHouse <> nil) and not fHouse.IsDestroyed then
  begin
    fHouse.BuildingState := hbsWood;
    gHands[fUnit.Owner].BuildList.HouseList.AddHouse(fHouse); //Add the house to JobList, so then all workers could take it
    gHands[fUnit.Owner].Deliveries.Queue.AddDemand(fHouse, nil, wtWood, gRes.Houses[fHouse.HouseType].WoodCost, dtOnce, diHigh4);
    gHands[fUnit.Owner].Deliveries.Queue.AddDemand(fHouse, nil, wtStone, gRes.Houses[fHouse.HouseType].StoneCost, dtOnce, diHigh4);
  end;

  gHands.CleanUpHousePointer(fHouse);
  inherited;
end;


function TKMTaskBuildHouseArea.WalkShouldAbandon: Boolean;
begin
  //Walk should abandon if other player has built something there before we arrived
  Result := (BuildID <> -1) and not gTerrain.CanPlaceHouse(GetHouseEntranceLoc, fHouseType);
end;


function TKMTaskBuildHouseArea.GetHouseEntranceLoc: TKMPoint;
begin
  Result.X := fHouseLoc.X + gRes.Houses[fHouseType].EntranceOffsetX;
  Result.Y := fHouseLoc.Y;
end;


//Tell if we are in Digging phase where we can walk on tlDigged tiles
//(incl. phase when we walk out)
function TKMTaskBuildHouseArea.Digging: Boolean;
begin
  Result := fPhase >= 2;
end;


procedure TKMTaskBuildHouseArea.CancelThePlan;
begin
  //House plan could be canceled during initial walk or while walking within the house area so
  //ignore it if it's already been canceled (occurs when trying to walk within range of an enemy tower during flattening)
  if BuildID = -1 then Exit;
  gHands[fUnit.Owner].BuildList.HousePlanList.ClosePlan(BuildID);
  gHands[fUnit.Owner].Stats.HousePlanRemoved(fHouseType);
  BuildID := -1;
end;


//Prepare building site - flatten terrain
function TKMTaskBuildHouseArea.Execute: TKMTaskResult;
var OutOfWay: TKMPoint;
begin
  Result := trTaskContinues;

  if WalkShouldAbandon then
  begin
    Result := trTaskDone;
    Exit;
  end;

  if (fHouse <> nil) and fHouse.IsDestroyed then
  begin
    Result := trTaskDone;
    fUnit.Thought := thNone;
    Exit;
  end;

  with fUnit do
  case fPhase of
    0:  begin
          SetActionWalkToSpot(GetHouseEntranceLoc);
          Thought := thBuild;
        end;
    1:  begin
          CancelThePlan;
          Assert(fHouse = nil);

          fHouse := gHands[Owner].AddHouseWIP(fHouseType, fHouseLoc);
          Assert(fHouse <> nil, 'Failed to add wip house');
          fHouse := fHouse.GetHousePointer; //We need to register a pointer to the house

          HouseNeedsWorker := True; //The house placed on the map, if something happens with Worker the house will be removed
          SetActionLockedStay(2, uaWalk);
          Thought := thNone;
        end;
    2:  //The house can become too steep after we flatten one part of it
        if CanWalkTo(CellsToDig[LastToDig], 0) then
          SetActionWalkToSpot(CellsToDig[LastToDig])
        else
        begin
          Result := trTaskDone;
          fUnit.Thought := thNone;
          Exit;
        end;
    3:  begin
          SetActionLockedStay(11,uaWork1,false); //Don't flatten terrain here as we haven't started digging yet
        end;
    4:  begin
          SetActionLockedStay(11,uaWork1,false);
          gTerrain.FlattenTerrain(CellsToDig[LastToDig]);
        end;
    5:  begin
          SetActionLockedStay(11,uaWork1,false);
          gTerrain.FlattenTerrain(CellsToDig[LastToDig]);
        end;
    6:  begin
          SetActionLockedStay(11,uaWork1,false);
          gTerrain.FlattenTerrain(CellsToDig[LastToDig]);
          gTerrain.FlattenTerrain(CellsToDig[LastToDig]); //Flatten the terrain twice now to ensure it really is flat
          gTerrain.SetTileLock(CellsToDig[LastToDig], tlDigged); //Block passability on tile
          if KMSamePoint(fHouse.Entrance, CellsToDig[LastToDig]) then
            gTerrain.SetRoad(fHouse.Entrance, Owner);
          gTerrain.RemoveObject(CellsToDig[LastToDig]); //All objects are removed
          Dec(LastToDig);
        end;
    7:  begin
          //Walk away from building site, before we get trapped when house becomes stoned
          OutOfWay := gTerrain.GetOutOfTheWay(fUnit, KMPOINT_ZERO, tpWalk);
          //GetOutOfTheWay can return the input position (GetPosition in this case) if no others are possible
          if KMSamePoint(OutOfWay, KMPOINT_ZERO) or KMSamePoint(OutOfWay, CurrPosition) then
            OutOfWay := fHouse.PointBelowEntrance; //Don't get stuck in corners
          SetActionWalkToSpot(OutOfWay);
          HouseNeedsWorker := False; //House construction no longer needs the worker to continue
          HouseReadyToBuild := True; //If worker gets killed while walking house will be finished without him
          gScriptEvents.ProcHousePlanDigged(fHouse.UID);
        end;
    else
        Result := trTaskDone;
  end;

  Inc(fPhase);

  if (fPhase = 7) and (LastToDig >= 0) then
    fPhase := 2; //Repeat with next cell
end;


procedure TKMTaskBuildHouseArea.Save(SaveStream:TKMemoryStream);
begin
  inherited;

  if fHouse <> nil then
    SaveStream.Write(fHouse.UID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Integer(0));
  SaveStream.Write(fHouseType, SizeOf(fHouseType));
  SaveStream.Write(fHouseLoc);
  SaveStream.Write(BuildID);
  SaveStream.Write(HouseNeedsWorker);
  SaveStream.Write(HouseReadyToBuild);
  SaveStream.Write(LastToDig);
  SaveStream.Write(CellsToDig, SizeOf(CellsToDig));
end;


{ TTaskBuildHouse }
constructor TKMTaskBuildHouse.Create(aWorker: TKMUnitWorker; aHouse: TKMHouse; aID: Integer);
begin
  inherited Create(aWorker);
  fType := uttBuildHouse;
  fHouse    := aHouse.GetHousePointer;
  BuildID   := aID;

  Cells := TKMPointDirList.Create;
  fHouse.GetListOfCellsAround(Cells, aWorker.DesiredPassability);
end;


constructor TKMTaskBuildHouse.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.Read(fHouse, 4);
  LoadStream.Read(BuildID);
  LoadStream.Read(BuildFrom);
  Cells := TKMPointDirList.Create;
  Cells.LoadFromStream(LoadStream);
end;


procedure TKMTaskBuildHouse.SyncLoad;
begin
  inherited;
  fHouse := gHands.GetHouseByUID(Cardinal(fHouse));
end;


destructor TKMTaskBuildHouse.Destroy;
begin
  //We are no longer connected to the House (it's either done or we died)
  gHands[fUnit.Owner].BuildList.HouseList.RemWorker(BuildID);
  gHands.CleanUpHousePointer(fHouse);
  FreeAndNil(Cells);
  inherited;
end;


{ If we are walking to the house but the house is destroyed/canceled we should abandon immediately
  If house has not enough resource to be built, consider building task is done and look for a new
  task that has enough resouces. Once this house has building resources delivered it will be
  available from build queue again
  If house is already built by other workers}
function TKMTaskBuildHouse.WalkShouldAbandon: Boolean;
begin
  Result := fHouse.IsDestroyed or (not fHouse.CheckResToBuild) or fHouse.IsComplete;
end;


function TKMTaskBuildHouse.CouldBeCancelled: Boolean;
begin
  Result := (fPhase - 1) //phase was increased at the end of execution
                   <= 0; //Allow cancel task only at walking phases
end;


{Build the house}
function TKMTaskBuildHouse.Execute: TKMTaskResult;
begin
  Result := trTaskContinues;

  if WalkShouldAbandon then
  begin
    fUnit.Thought := thNone;
    Result := trTaskDone;
    Exit;
  end;

  with TKMUnitWorker(fUnit) do
  case fPhase of
    0:  if PickRandomSpot(Cells, BuildFrom) then
        begin
          Thought := thBuild;
          SetActionWalkToSpot(BuildFrom.Loc);
        end
        else
          Result := trTaskDone;
    //WARNING!!! THIS PHASE VALUE IS USED IN TKMTaskDelivery to construction !!!
    1:  begin
          //Face the building
          Direction := BuildFrom.Dir;
          SetActionLockedStay(0, uaWalk);
        end;
    2:  begin
          //Start animation
          SetActionLockedStay(5, uaWork, False);
          Direction := BuildFrom.Dir;
          //Remove house plan when we start the stone phase (it is still required for wood)
          //But don't do it every time we hit if it's already done!
          if fHouse.IsStone and (gTerrain.Land[fHouse.Position.Y, fHouse.Position.X].TileLock <> tlHouse) then
            gTerrain.SetHouse(fHouse.Position, fHouse.HouseType, hsBuilt, Owner);
        end;
    3:  begin
          //Update house on hummer hit
          fHouse.IncBuildingProgress;
          SetActionLockedStay(6, uaWork, False, 0, 5); //Do building and end animation
          Inc(fPhase2);
        end;
    4:  begin
          SetActionStay(1, uaWalk);
          Thought := thNone;
        end;
    else Result := trTaskDone;
  end;
  Inc(fPhase);

  {Worker does 5 hits from any spot around the house and then goes to new spot,
   but if the house is done worker should stop activity immediately}
  if (fPhase = 4) and (not fHouse.IsComplete) then //If animation cycle is done
    if fPhase2 mod 5 = 0 then //if worker did [5] hits from same spot
      fPhase := 0 //Then goto new spot
    else
      fPhase := 2; //else do more hits
end;


procedure TKMTaskBuildHouse.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  if fHouse <> nil then
    SaveStream.Write(fHouse.UID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Integer(0));
  SaveStream.Write(BuildID);
  SaveStream.Write(BuildFrom);
  Cells.SaveToStream(SaveStream);
end;


{ TTaskBuildHouseRepair }
constructor TKMTaskBuildHouseRepair.Create(aWorker: TKMUnitWorker; aHouse: TKMHouse; aRepairID: Integer);
begin
  inherited Create(aWorker);
  fType := uttBuildHouseRepair;
  fHouse    := aHouse.GetHousePointer;
  fRepairID := aRepairID;

  Cells := TKMPointDirList.Create;
  fHouse.GetListOfCellsAround(Cells, aWorker.DesiredPassability);
end;


constructor TKMTaskBuildHouseRepair.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.Read(fHouse, 4);
  LoadStream.Read(fRepairID);
  LoadStream.Read(BuildFrom);
  Cells := TKMPointDirList.Create;
  Cells.LoadFromStream(LoadStream);
end;


procedure TKMTaskBuildHouseRepair.SyncLoad;
begin
  inherited;
  fHouse := gHands.GetHouseByUID(Cardinal(fHouse));
end;


destructor TKMTaskBuildHouseRepair.Destroy;
begin
  gHands[fUnit.Owner].BuildList.RepairList.RemWorker(fRepairID);
  gHands.CleanUpHousePointer(fHouse);
  FreeAndNil(Cells);
  inherited;
end;


function TKMTaskBuildHouseRepair.WalkShouldAbandon: Boolean;
begin
  Result := fHouse.IsDestroyed
            or not fHouse.IsDamaged
            or not fHouse.BuildingRepair;
end;


function TKMTaskBuildHouseRepair.CouldBeCancelled: Boolean;
begin
  Result := (fPhase - 1) //phase was increased at the end of execution
                   <= 0; //Allow cancel task only at walking phases
end;


{Repair the house}
function TKMTaskBuildHouseRepair.Execute: TKMTaskResult;
begin
  Result := trTaskContinues;

  if WalkShouldAbandon then
  begin
    Result := trTaskDone;
    Exit;
  end;

  with TKMUnitWorker(fUnit) do
    case fPhase of
      0:  if PickRandomSpot(Cells, BuildFrom) then
          begin
            Thought := thBuild;
            SetActionWalkToSpot(BuildFrom.Loc);
          end
          else
            Result := trTaskDone;
      1:  begin
            Direction := BuildFrom.Dir;
            SetActionLockedStay(0, uaWalk);
          end;
      2:  begin
            SetActionLockedStay(5, uaWork, false, 0, 0); //Start animation
            Direction := BuildFrom.Dir;
          end;
      3:  begin
            fHouse.AddRepair;
            SetActionLockedStay(6, uaWork,false, 0, 5); //Do building and end animation
            inc(fPhase2);
          end;
      4:  begin
            Thought := thNone;
            SetActionStay(1, uaWalk);
          end;
      else
          Result := trTaskDone;
    end;
  inc(fPhase);

  if fPhase = 4 then //If animation cycle is done
    if fPhase2 mod 5 = 0 then //if worker did [5] hits from same spot
      fPhase := 0 //Then goto new spot
    else
      fPhase := 2; //else do more hits
end;


procedure TKMTaskBuildHouseRepair.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  if fHouse <> nil then
    SaveStream.Write(fHouse.UID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Integer(0));
  SaveStream.Write(fRepairID);
  SaveStream.Write(BuildFrom);
  Cells.SaveToStream(SaveStream);
end;


end.
