unit KM_UnitTaskBuild;
{$I KaM_Remake.inc}
interface
uses
  SysUtils,
  KM_CommonClasses, KM_Defaults, KM_Points,
  KM_Houses, KM_Terrain, KM_Units, KM_ResHouses,
  KM_ResTypes;


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
    fBuildID: Integer;
    fDemandSet: Boolean;
    fTileLockSet: Boolean;
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
    fBuildID: Integer;
    fDemandSet: Boolean;
    fTileLockSet: Boolean;
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
    fBuildID: Integer;
    fTileLockSet: Boolean;
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
    fBuildID: Integer;
    fHouseNeedsWorker: Boolean;
    fHouseReadyToBuild: Boolean;
    fCellsToDig: array [0..15] of TKMPoint; //max house square is 4*4
    fLastToDig: ShortInt;
    function GetHouseEntranceLoc: TKMPoint;
  public
    constructor Create(aWorker: TKMUnitWorker; aHouseType: TKMHouseType; const aLoc: TKMPoint; aID: Integer);
    constructor Load(LoadStream: TKMemoryStream); override;
    property DigState: ShortInt read fLastToDig;
    procedure SyncLoad; override;
    destructor Destroy; override;
    property House: TKMHouse read fHouse;
    function WalkShouldAbandon: Boolean; override;
    procedure CancelThePlan; override;
    function Digging: Boolean;
    function Execute: TKMTaskResult; override;
    procedure Save(SaveStream: TKMemoryStream); override;
  end;

  TKMTaskBuildHouse = class(TKMUnitTask)
  private
    fHouse: TKMHouse;
    fBuildID: Integer;
    fBuildFrom: TKMPointDir; //Current WIP location
    fCells: TKMPointDirList; //List of surrounding cells and directions
  public
    constructor Create(aWorker: TKMUnitWorker; aHouse: TKMHouse; aID: Integer);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure SyncLoad; override;
    destructor Destroy; override;
    property House: TKMHouse read fHouse;
    function WalkShouldAbandon: Boolean; override;
    function CouldBeCancelled: Boolean; override;
    function Execute: TKMTaskResult; override;
    procedure Save(SaveStream: TKMemoryStream); override;
  end;

  TKMTaskBuildHouseRepair = class(TKMUnitTask)
  private
    fHouse: TKMHouse;
    fRepairID: Integer; //Remember the house we repair to report if we died and let others take our place
    fBuildFrom: TKMPointDir; //Current WIP location
    fCells: TKMPointDirList; //List of surrounding cells and directions
  public
    constructor Create(aWorker: TKMUnitWorker; aHouse: TKMHouse; aRepairID: Integer);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure SyncLoad; override;
    destructor Destroy; override;
    property House: TKMHouse read fHouse;
    function WalkShouldAbandon: Boolean; override;
    function CouldBeCancelled: Boolean; override;
    function Execute: TKMTaskResult; override;
    procedure Save(SaveStream: TKMemoryStream); override;
  end;


implementation
uses
  KM_HandLogistics, KM_HandsCollection, KM_Resource, KM_ResMapElements,
  KM_Game, KM_Hand, KM_ScriptingEvents;


{ TKMTaskBuild }
function TKMTaskBuild.CouldBeCancelled: Boolean;
begin
  Result := (fPhase - 1) //phase was increased at the end of execution
                   <= 0; //Allow cancel task only at walking phases
end;


{ TKMTaskBuildRoad }
constructor TKMTaskBuildRoad.Create(aWorker: TKMUnitWorker; const aLoc: TKMPoint; aID: Integer);
begin
  inherited Create(aWorker);

  fType := uttBuildRoad;
  fLoc      := aLoc;
  fBuildID   := aID;
  fDemandSet := False;
  fTileLockSet := False;
end;


constructor TKMTaskBuildRoad.Load(LoadStream: TKMemoryStream);
begin
  inherited;

  LoadStream.CheckMarker('TaskBuildRoad');
  LoadStream.Read(fLoc);
  LoadStream.Read(fBuildID);
  LoadStream.Read(fDemandSet);
  LoadStream.Read(fTileLockSet);
end;


destructor TKMTaskBuildRoad.Destroy;
begin
  if (fUnit <> nil) and fDemandSet then
    gHands[fUnit.Owner].Deliveries.Queue.RemDemand(fUnit);

  if fTileLockSet then
    gTerrain.UnlockTile(fLoc);

  //Yet unstarted
  if (fUnit <> nil) then
  begin
    if fBuildID <> -1 then
    begin
      if gTerrain.CanAddField(fLoc.X, fLoc.Y, ftRoad) then
        //Allow other workers to take this task
        gHands[fUnit.Owner].Constructions.FieldworksList.ReOpenField(fBuildID)
      else
        //This plan is not valid anymore
        gHands[fUnit.Owner].Constructions.FieldworksList.CloseField(fBuildID);
    end
    else
      //Autobuild AI should rebuild roads when worker dies (otherwise house is never built)
      if (gGame <> nil) and not gGame.IsExiting and gHands[fUnit.Owner].AI.Setup.AutoBuild and (fPhase < 9)
      and gHands[fUnit.Owner].CanAddFieldPlan(fLoc, ftRoad) then
        gHands[fUnit.Owner].Constructions.FieldworksList.AddField(fLoc, ftRoad);
  end;

  inherited;
end;


function TKMTaskBuildRoad.WalkShouldAbandon: Boolean;
begin
  //Walk should abandon if other player has built something there before we arrived
  Result := (fBuildID <> -1) and not gTerrain.CanAddField(fLoc.X, fLoc.Y, ftRoad);
end;


procedure TKMTaskBuildRoad.CancelThePlan;
begin
  gHands[fUnit.Owner].Constructions.FieldworksList.CloseField(fBuildID); //Close the job now because it can no longer be cancelled
  fBuildID := -1;
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
         fTileLockSet := True;

         CancelThePlan;

         gHands[Owner].Deliveries.Queue.AddDemand(nil, fUnit, wtStone, 1, dtOnce, diHigh4);
         fDemandSet := true;

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
         fDemandSet := false;
         Thought := thNone;
       end;
    6: begin
         gTerrain.IncDigState(fLoc);
         SetActionLockedStay(11,uaWork2,false);
       end;
    7: begin
         gTerrain.IncDigState(fLoc);
         gTerrain.FlattenTerrain(fLoc); //Flatten the terrain slightly on and around the road
         if gMapElements[gTerrain.Land^[fLoc.Y,fLoc.X].Obj].WineOrCorn then
           gTerrain.RemoveObject(fLoc); //Remove corn/wine/grass as they won't fit with road
         SetActionLockedStay(11,uaWork2,false);
       end;
    8: begin
         gTerrain.SetRoad(fLoc, Owner);
         gTerrain.RemoveObjectsKilledByRoad(fLoc);
         SetActionStay(5, uaWalk);
         gTerrain.UnlockTile(fLoc);
         fTileLockSet := False;
       end;
    else Result := trTaskDone;
  end;
  if fPhase<>4 then inc(fPhase); //Phase=4 is when worker waits for rtStone
end;


procedure TKMTaskBuildRoad.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  SaveStream.PlaceMarker('TaskBuildRoad');
  SaveStream.Write(fLoc);
  SaveStream.Write(fBuildID);
  SaveStream.Write(fDemandSet);
  SaveStream.Write(fTileLockSet);
end;


{ TTaskBuildWine }
constructor TKMTaskBuildWine.Create(aWorker: TKMUnitWorker; const aLoc: TKMPoint; aID: Integer);
begin
  inherited Create(aWorker);
  fType := uttBuildWine;
  fLoc      := aLoc;
  fBuildID   := aID;
  fDemandSet := False;
  fTileLockSet := False;
end;


constructor TKMTaskBuildWine.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.PlaceMarker('TaskBuildWine');
  LoadStream.Read(fLoc);
  LoadStream.Read(fBuildID);
  LoadStream.Read(fDemandSet);
  LoadStream.Read(fTileLockSet);
end;


destructor TKMTaskBuildWine.Destroy;
begin
  //Yet unstarted
  if fBuildID <> -1 then
    if gTerrain.CanAddField(fLoc.X, fLoc.Y, ftWine) then
      //Allow other workers to take this task
      gHands[fUnit.Owner].Constructions.FieldworksList.ReOpenField(fBuildID)
    else
      //This plan is not valid anymore
      gHands[fUnit.Owner].Constructions.FieldworksList.CloseField(fBuildID);

  if fDemandSet then
    gHands[fUnit.Owner].Deliveries.Queue.RemDemand(fUnit);

  if fTileLockSet then
    gTerrain.UnlockTile(fLoc);
  inherited;
end;


function TKMTaskBuildWine.WalkShouldAbandon: Boolean;
begin
  //Walk should abandon if other player has built something there before we arrived
  Result := (fBuildID <> -1) and not gTerrain.CanAddField(fLoc.X, fLoc.Y, ftWine);
end;


procedure TKMTaskBuildWine.CancelThePlan;
begin
  gHands[fUnit.Owner].Constructions.FieldworksList.CloseField(fBuildID); //Close the job now because it can no longer be cancelled
  fBuildID := -1;
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
        fTileLockSet := True;

        CancelThePlan;

        gTerrain.ResetDigState(fLoc); //Remove any dig over that might have been there (e.g. destroyed house)

        gHands[Owner].Deliveries.Queue.AddDemand(nil,fUnit,wtTimber, 1, dtOnce, diHigh4);
        fDemandSet := true;

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
        fDemandSet := false;
        SetActionLockedStay(11*8, uaWork2, False);
        Thought := thNone;
      end;
   7: begin
        gTerrain.SetField(fLoc, Owner, ftWine);
        SetActionStay(5, uaWalk);
        gTerrain.UnlockTile(fLoc);
        fTileLockSet := False;
      end;
   else Result := trTaskDone;
  end;
  if fPhase<>5 then inc(fPhase); //Phase=5 is when worker waits for rtWood
end;


procedure TKMTaskBuildWine.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  SaveStream.PlaceMarker('TaskBuildWine');
  SaveStream.Write(fLoc);
  SaveStream.Write(fBuildID);
  SaveStream.Write(fDemandSet);
  SaveStream.Write(fTileLockSet);
end;


{ TTaskBuildField }
constructor TKMTaskBuildField.Create(aWorker: TKMUnitWorker; const aLoc: TKMPoint; aID: Integer);
begin
  inherited Create(aWorker);

  fType := uttBuildField;
  fLoc      := aLoc;
  fBuildID   := aID;
  fTileLockSet := False;
end;


constructor TKMTaskBuildField.Load(LoadStream: TKMemoryStream);
begin
  inherited;

  LoadStream.CheckMarker('TaskBuildField');
  LoadStream.Read(fLoc);
  LoadStream.Read(fBuildID);
  LoadStream.Read(fTileLockSet);
end;


destructor TKMTaskBuildField.Destroy;
begin
  //Yet unstarted
  if fBuildID <> -1 then
    if gTerrain.CanAddField(fLoc.X, fLoc.Y, ftCorn) then
      //Allow other workers to take this task
      gHands[fUnit.Owner].Constructions.FieldworksList.ReOpenField(fBuildID)
    else
      //This plan is not valid anymore
      gHands[fUnit.Owner].Constructions.FieldworksList.CloseField(fBuildID);

  if fTileLockSet then gTerrain.UnlockTile(fLoc);
  inherited;
end;


function TKMTaskBuildField.WalkShouldAbandon: Boolean;
begin
  //Walk should abandon if other player has built something there before we arrived
  Result := (fBuildID <> -1) and not gTerrain.CanAddField(fLoc.X, fLoc.Y, ftCorn);
end;


procedure TKMTaskBuildField.CancelThePlan;
begin
  gHands[fUnit.Owner].Constructions.FieldworksList.CloseField(fBuildID); //Close the job now because it can no longer be cancelled
  fBuildID := -1;
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
        fTileLockSet := True;
        CancelThePlan;
        SetActionLockedStay(0,uaWalk);
       end;
    2: begin
        SetActionLockedStay(11,uaWork1,false);
        inc(fPhase2);
        if fPhase2 = 2 then gTerrain.ResetDigState(fLoc); //Remove any dig over that might have been there (e.g. destroyed house)
        if (fPhase2 = 6) and gMapElements[gTerrain.Land^[fLoc.Y,fLoc.X].Obj].WineOrCorn then
          gTerrain.RemoveObject(fLoc); //Remove grass/corn/wine as they take up most of the tile
        if fPhase2 in [6,8] then gTerrain.IncDigState(fLoc);
       end;
    3: begin
        Thought := thNone; //Keep thinking build until it's done
        gTerrain.SetField(fLoc, Owner, ftCorn);
        SetActionStay(5,uaWalk);
        gTerrain.UnlockTile(fLoc);
        fTileLockSet := False;
       end;
    else Result := trTaskDone;
  end;
  if fPhase2 in [0,10] then inc(fPhase);
end;


procedure TKMTaskBuildField.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  SaveStream.PlaceMarker('TaskBuildField');
  SaveStream.Write(fLoc);
  SaveStream.Write(fBuildID);
  SaveStream.Write(fTileLockSet);
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
  fBuildID    := aID;
  fHouseNeedsWorker  := False; //House needs this worker to complete
  fHouseReadyToBuild := False; //House is ready to be built

  HA := gResHouses[fHouseType].BuildArea;

  //Fill Cells left->right, top->bottom. Worker will start flattening from the end (reversed)
  fLastToDig := -1;
  for I := 1 to 4 do for K := 1 to 4 do
  if HA[I,K] <> 0 then
  begin
    Inc(fLastToDig);
    fCellsToDig[fLastToDig] := KMPoint(fHouseLoc.X + K - 3, fHouseLoc.Y + I - 4);
  end;
end;


constructor TKMTaskBuildHouseArea.Load(LoadStream: TKMemoryStream);
begin
  inherited;

  LoadStream.CheckMarker('TaskBuildHouseArea');
  LoadStream.Read(fHouse, 4);
  LoadStream.Read(fHouseType, SizeOf(fHouseType));
  LoadStream.Read(fHouseLoc);
  LoadStream.Read(fBuildID);
  LoadStream.Read(fHouseNeedsWorker);
  LoadStream.Read(fHouseReadyToBuild);
  LoadStream.Read(fLastToDig);
  LoadStream.Read(fCellsToDig, SizeOf(fCellsToDig));
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
  if (fBuildID <> -1) then
    if gTerrain.CanPlaceHouse(GetHouseEntranceLoc,fHouseType) then
      //Allow other workers to take this task
      gHands[fUnit.Owner].Constructions.HousePlanList.ReOpenPlan(fBuildID)
    else
    begin
      //This plan is not valid anymore
      gHands[fUnit.Owner].Constructions.HousePlanList.ClosePlan(fBuildID);
      gHands[fUnit.Owner].Stats.HousePlanRemoved(fHouseType);
    end;

  //Destroy the house if worker was killed (e.g. by archer or hunger)
  //as we don't have mechanics to resume the building process yet
  if fHouseNeedsWorker and (fHouse <> nil) and not fHouse.IsDestroyed then
    //Use handID of unit killer, since he indirecty caused house demolishing
    fHouse.Demolish(fUnit.KilledBy);

  //Complete the task in the end (Worker could have died while trying to exit building area)
  if fHouseReadyToBuild and not fHouseNeedsWorker and (fHouse <> nil) and not fHouse.IsDestroyed then
  begin
    fHouse.BuildingState := hbsWood;
    gHands[fUnit.Owner].Constructions.HouseList.AddHouse(fHouse); //Add the house to JobList, so then all workers could take it
    gHands[fUnit.Owner].Deliveries.Queue.AddDemand(fHouse, nil, wtTimber, gResHouses[fHouse.HouseType].WoodCost, dtOnce, diHigh4);
    gHands[fUnit.Owner].Deliveries.Queue.AddDemand(fHouse, nil, wtStone, gResHouses[fHouse.HouseType].StoneCost, dtOnce, diHigh4);
  end;

  gHands.CleanUpHousePointer(fHouse);
  inherited;
end;


function TKMTaskBuildHouseArea.WalkShouldAbandon: Boolean;
begin
  //Walk should abandon if other player has built something there before we arrived
  Result := (fBuildID <> -1) and not gTerrain.CanPlaceHouse(GetHouseEntranceLoc, fHouseType);
end;


function TKMTaskBuildHouseArea.GetHouseEntranceLoc: TKMPoint;
begin
  Result.X := fHouseLoc.X + gResHouses[fHouseType].EntranceOffsetX;
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
  if fBuildID = -1 then Exit;
  gHands[fUnit.Owner].Constructions.HousePlanList.ClosePlan(fBuildID);
  gHands[fUnit.Owner].Stats.HousePlanRemoved(fHouseType);
  fBuildID := -1;
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
          fHouse := fHouse.GetPointer; //We need to register a pointer to the house

          fHouseNeedsWorker := True; //The house placed on the map, if something happens with Worker the house will be removed
          SetActionLockedStay(2, uaWalk);
          Thought := thNone;
        end;
    2:  //The house can become too steep after we flatten one part of it
        if CanWalkTo(fCellsToDig[fLastToDig], 0) then
          SetActionWalkToSpot(fCellsToDig[fLastToDig])
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
          gTerrain.FlattenTerrain(fCellsToDig[fLastToDig]);
        end;
    5:  begin
          SetActionLockedStay(11,uaWork1,false);
          gTerrain.FlattenTerrain(fCellsToDig[fLastToDig]);
        end;
    6:  begin
          SetActionLockedStay(11,uaWork1,false);
          gTerrain.FlattenTerrain(fCellsToDig[fLastToDig]);
          gTerrain.FlattenTerrain(fCellsToDig[fLastToDig]); //Flatten the terrain twice now to ensure it really is flat
          gTerrain.SetTileLock(fCellsToDig[fLastToDig], tlDigged); //Block passability on tile
          if KMSamePoint(fHouse.Entrance, fCellsToDig[fLastToDig]) then
            gTerrain.SetRoad(fHouse.Entrance, Owner);
          gTerrain.RemoveObject(fCellsToDig[fLastToDig]); //All objects are removed
          Dec(fLastToDig);
        end;
    7:  begin
          //Walk away from building site, before we get trapped when house becomes stoned
          OutOfWay := gTerrain.GetOutOfTheWay(fUnit, KMPOINT_ZERO, tpWalk);
          //GetOutOfTheWay can return the input position (GetPosition in this case) if no others are possible
          if KMSamePoint(OutOfWay, KMPOINT_ZERO) or KMSamePoint(OutOfWay, Position) then
            OutOfWay := fHouse.PointBelowEntrance; //Don't get stuck in corners
          SetActionWalkToSpot(OutOfWay);
          fHouseNeedsWorker := False; //House construction no longer needs the worker to continue
          fHouseReadyToBuild := True; //If worker gets killed while walking house will be finished without him
          gScriptEvents.ProcHousePlanDigged(fHouse);
        end;
    else
        Result := trTaskDone;
  end;

  Inc(fPhase);

  if (fPhase = 7) and (fLastToDig >= 0) then
    fPhase := 2; //Repeat with next cell
end;


procedure TKMTaskBuildHouseArea.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  SaveStream.PlaceMarker('TaskBuildHouseArea');
  SaveStream.Write(fHouse.UID); //Store ID, then substitute it with reference on SyncLoad
  SaveStream.Write(fHouseType, SizeOf(fHouseType));
  SaveStream.Write(fHouseLoc);
  SaveStream.Write(fBuildID);
  SaveStream.Write(fHouseNeedsWorker);
  SaveStream.Write(fHouseReadyToBuild);
  SaveStream.Write(fLastToDig);
  SaveStream.Write(fCellsToDig, SizeOf(fCellsToDig));
end;


{ TTaskBuildHouse }
constructor TKMTaskBuildHouse.Create(aWorker: TKMUnitWorker; aHouse: TKMHouse; aID: Integer);
begin
  inherited Create(aWorker);
  fType := uttBuildHouse;
  fHouse    := aHouse.GetPointer;
  fBuildID   := aID;

  fCells := TKMPointDirList.Create;
  fHouse.GetListOfCellsAround(fCells, aWorker.DesiredPassability);
end;


constructor TKMTaskBuildHouse.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.CheckMarker('TaskBuildHouse');
  LoadStream.Read(fHouse, 4);
  LoadStream.Read(fBuildID);
  LoadStream.Read(fBuildFrom);
  fCells := TKMPointDirList.Create;
  fCells.LoadFromStream(LoadStream);
end;


procedure TKMTaskBuildHouse.SyncLoad;
begin
  inherited;
  fHouse := gHands.GetHouseByUID(Cardinal(fHouse));
end;


destructor TKMTaskBuildHouse.Destroy;
begin
  //We are no longer connected to the House (it's either done or we died)
  gHands[fUnit.Owner].Constructions.HouseList.RemWorker(fBuildID);
  gHands.CleanUpHousePointer(fHouse);
  FreeAndNil(fCells);
  inherited;
end;


// If we are walking to the house but the house is destroyed/canceled we should abandon immediately
// If house has not enough resource to be built, consider building task is done and look for a new
// task that has enough resouces. Once this house has building resources delivered it will be
// available from build queue again
// If house is already built by other workers
function TKMTaskBuildHouse.WalkShouldAbandon: Boolean;
begin
  Result := fHouse.IsDestroyed or not fHouse.CheckResToBuild or fHouse.IsComplete;
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
    0:  if PickRandomSpot(fCells, fBuildFrom) then
        begin
          Thought := thBuild;
          SetActionWalkToSpot(fBuildFrom.Loc);
        end
        else
          Result := trTaskDone;
    //WARNING!!! THIS PHASE VALUE IS USED IN TKMTaskDelivery to construction !!!
    1:  begin
          //Face the building
          Direction := fBuildFrom.Dir;
          SetActionLockedStay(0, uaWalk);
        end;
    2:  begin
          //Start animation
          SetActionLockedStay(5, uaWork, False);
          Direction := fBuildFrom.Dir;
          //Remove house plan when we start the stone phase (it is still required for wood)
          //But don't do it every time we hit if it's already done!
          if fHouse.IsStone and (gTerrain.Land^[fHouse.Position.Y, fHouse.Position.X].TileLock <> tlHouse) then
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
  SaveStream.PlaceMarker('TaskBuildHouse');
  SaveStream.Write(fHouse.UID); //Store ID, then substitute it with reference on SyncLoad
  SaveStream.Write(fBuildID);
  SaveStream.Write(fBuildFrom);
  fCells.SaveToStream(SaveStream);
end;


{ TTaskBuildHouseRepair }
constructor TKMTaskBuildHouseRepair.Create(aWorker: TKMUnitWorker; aHouse: TKMHouse; aRepairID: Integer);
begin
  inherited Create(aWorker);
  fType := uttBuildHouseRepair;
  fHouse    := aHouse.GetPointer;
  fRepairID := aRepairID;

  fCells := TKMPointDirList.Create;
  fHouse.GetListOfCellsAround(fCells, aWorker.DesiredPassability);
end;


constructor TKMTaskBuildHouseRepair.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.CheckMarker('TaskBuildHouseRepair');
  LoadStream.Read(fHouse, 4);
  LoadStream.Read(fRepairID);
  LoadStream.Read(fBuildFrom);
  fCells := TKMPointDirList.Create;
  fCells.LoadFromStream(LoadStream);
end;


procedure TKMTaskBuildHouseRepair.SyncLoad;
begin
  inherited;
  fHouse := gHands.GetHouseByUID(Cardinal(fHouse));
end;


destructor TKMTaskBuildHouseRepair.Destroy;
begin
  gHands[fUnit.Owner].Constructions.RepairList.RemWorker(fRepairID);
  gHands.CleanUpHousePointer(fHouse);
  FreeAndNil(fCells);
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
      0:  if PickRandomSpot(fCells, fBuildFrom) then
          begin
            Thought := thBuild;
            SetActionWalkToSpot(fBuildFrom.Loc);
          end
          else
            Result := trTaskDone;
      1:  begin
            Direction := fBuildFrom.Dir;
            SetActionLockedStay(0, uaWalk);
          end;
      2:  begin
            SetActionLockedStay(5, uaWork, false, 0, 0); //Start animation
            Direction := fBuildFrom.Dir;
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
  SaveStream.PlaceMarker('TaskBuildHouseRepair');
  SaveStream.Write(fHouse.UID); //Store ID, then substitute it with reference on SyncLoad
  SaveStream.Write(fRepairID);
  SaveStream.Write(fBuildFrom);
  fCells.SaveToStream(SaveStream);
end;


end.
