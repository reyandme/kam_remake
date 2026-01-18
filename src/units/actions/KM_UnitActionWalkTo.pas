unit KM_UnitActionWalkTo;
{$I KaM_Remake.inc}
interface
uses
  Classes,
  KM_Defaults, KM_CommonClasses, KM_CommonTypes, KM_Points,
  KM_Houses, KM_Units;

type
  TKMInteractionStatus = (
    kisNone,       //We have not yet encountered an interaction (we are just walking)
    kisPushing,    //We are pushing an idle unit out of the way
    kisPushed,     //We were pushed (idle then asked to move)
    kisTrying,     //We are or have been stuck (difference between this and kisNone is only for debug)
    kisWaiting     //We have been stuck for a while so allow other units to swap with us
  );

  TKMDestinationCheck = (dcNoChanges, dcRouteChanged, dcNoRoute);
  TKMObstacleCheck = (ocNoObstacle, ocReRouteMade, ocNoRoute);

  TKMUnitActionWalkTo = class(TKMUnitAction)
  private
    fWalkFrom: TKMPoint; //Walking from this spot, used only in Create
    fWalkTo: TKMPoint; //Where are we going to
    fNewWalkTo: TKMPoint; //If we recieve a new TargetLoc it will be stored here
    fDistance: Single; //How close we need to get to our target
    fTargetUnit: TKMUnit; //Folow this unit
    fTargetHouse: TKMHouse; //Go to this House
    fPass: TKMTerrainPassability; //Desired passability set once on Create
    fDoesWalking, fWaitingOnStep: Boolean;
    fDestBlocked: Boolean; //Our route is blocked by busy units, so we must wait for them to clear. Give way to all other units (who might be carrying stone for the worker blocking us)
    fDoExchange: Boolean; //Command to make exchange maneuver with other unit, should use MakeExchange when vertex use needs to be set
    fInteractionCount, fLastSideStepNodePos: Integer;
    fInteractionStatus: TKMInteractionStatus;
    fAvoidLockedAsMovementCost: Boolean; //Avoid locked as 'movement cost' if True and means 'as unwalkable' if False
    function AssembleTheRoute: Boolean;
    function CanWalkToTarget(const aFrom: TKMPoint; aPass: TKMTerrainPassability): Boolean;
    function CheckForNewDestination: TKMDestinationCheck;
    function CheckTargetHasDied: Boolean;
    function CheckForObstacle(aDir: TKMDirection): TKMObstacleCheck;
    function CheckWalkComplete: Boolean;
    function CheckInteractionFreq(aIntCount, aTimeout, aFreq: Integer): Boolean;
    function DoUnitInteraction: Boolean;
      //Sub functions split out of DoUnitInteraction (these are the solutions)
      function IntCheckIfPushing(aOpponent: TKMUnit): Boolean;
      function IntSolutionPush(aOpponent: TKMUnit; aHighestInteractionCount: Integer): Boolean;
      function IntSolutionExchange(aOpponent: TKMUnit; aHighestInteractionCount: Integer): Boolean;
      function IntCheckIfPushed(aHighestInteractionCount: Integer): Boolean;
      function IntSolutionDodge(aOpponent: TKMUnit; aHighestInteractionCount: Integer): Boolean;
      function IntSolutionAvoid(aOpponent: TKMUnit): Boolean;
      function IntSolutionSideStep(const aPosition: TKMPoint; aHighestInteractionCount: Integer): Boolean;

    procedure ChangeStepTo(const aPos: TKMPoint);
    procedure PerformExchange(const aForcedExchangePos: TKMPoint);
    procedure SmoothDiagSideStep;
    procedure IncVertex;
    procedure DecVertex;
    procedure SetInitValues;
    function CanAbandonInternal: Boolean;
    function GetNextNextPosition(out NextNextPos: TKMPoint): Boolean;
    function GetEffectivePassability: TKMTerrainPassability; //Returns passability that unit is allowed to walk on
    procedure ExplanationLogCreate;
    procedure ExplanationLogAdd;
    function CheckAllTilesAroundHouseLocked: Boolean;
  private //Debug items
    fNodePos: Integer;
    fNodeList: TKMPointList;
    fExplanation: UnicodeString; //Debug only, explanation what unit is doing
    fExplanationLog: TStringList;
  public
    fVertexOccupied: TKMPoint; //Public because it needs to be used by AbandonWalk
    constructor Create(aUnit: TKMUnit; const aLocB: TKMPoint; aActionType: TKMUnitActionType; aDistance: Single; aSetPushed:
                       Boolean; aTargetUnit: TKMUnit; aTargetHouse: TKMHouse; aTargetPassability: TKMTerrainPassability = tpNone;
                       aTargetWalkConnectSet: TKMByteSet = []; aUseExactTarget: Boolean = True;
                       aAvoidLockedByMovementCost: Boolean = True; aSilent: Boolean = False);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure  SyncLoad; override;
    destructor Destroy; override;

    function ActName: TKMUnitActionName; override;
    function CanBeInterrupted(aForced: Boolean = True): Boolean; override;
    function CanAbandonExternal: Boolean;
    property DoesWalking: Boolean read fDoesWalking;
    property DoingExchange: Boolean read fDoExchange; //Critical piece, must not be abandoned
    function GetExplanation: UnicodeString; override;
    function WasPushed: Boolean;
    property WalkFrom: TKMPoint read fWalkFrom;
    property WalkTo: TKMPoint read fWalkTo;
    function RouteBuilt: Boolean;

    //Modify route to go to this destination instead
    procedure ChangeWalkTo(const aLoc: TKMPoint; aDistance: Single); overload;
    procedure ChangeWalkTo(aNewTargetUnit: TKMUnit; aDistance: Single); overload;

    function Execute: TKMActionResult; override;
    procedure Save(SaveStream: TKMemoryStream); override;
    procedure Paint; override; //Used only for debug so far
    function NeedToPaint(const aRect: TKMRect): Boolean; //Used only for debug so far

    function ObjToStringShort(const aSeparator: string = ' '): string; override;
    function ObjToString(const aSeparator: string = ' '): string; override;
  end;


implementation
uses
  Math, TypInfo, SysUtils,
  KM_Entity,
  KM_RenderAux, KM_Game, KM_GameParams,
  KM_HandsCollection, KM_HandTypes, KM_HandEntity,
  KM_Terrain, KM_ResUnits, KM_UnitGroup,
  KM_UnitActionGoInOut, KM_UnitActionStay, KM_UnitTaskBuild, KM_PathFinding,
  KM_UnitWarrior, KM_Log, KM_Resource, KM_CommonClassesExt,
  KM_CommonExceptions;

type
  TKMSetByteSet = TSet<TKMByteSet>;

//INTERACTION CONSTANTS: (may need to be tweaked for optimal performance)
//TIMEOUT is the time after which each solution things will be checked.
//FREQ is the frequency that it will be checked, to save CPU time.
//     e.g. 10 means check when TIMEOUT is first reached then every 10 ticks after that.
//     Lower FREQ will mean faster solutions but more CPU usage. Only solutions with time consuming checks have FREQ
const
  EXCHANGE_TIMEOUT = 0;                      //Pass with unit
  PUSH_TIMEOUT     = 1;                      //Push unit out of the way
  PUSHED_TIMEOUT   = 10;                     //Try a different way when pushed
  DODGE_TIMEOUT    = 5;     DODGE_FREQ = 8;  //Pass with a unit on a tile next to our target if they want to
  AVOID_TIMEOUT    = 10;    AVOID_FREQ = 50; //Go around busy units
  SIDESTEP_TIMEOUT = 10; SIDESTEP_FREQ = 15; //Step to empty tile next to target
  WAITING_TIMEOUT  = 40;                     //After this time we can be forced to exchange


{ TKMUnitActionWalkTo }
constructor TKMUnitActionWalkTo.Create( aUnit: TKMUnit;
                                        const aLocB: TKMPoint;
                                        aActionType: TKMUnitActionType;
                                        aDistance: Single;
                                        aSetPushed: Boolean;
                                        aTargetUnit: TKMUnit;
                                        aTargetHouse: TKMHouse;
                                        aTargetPassability: TKMTerrainPassability = tpNone;
                                        aTargetWalkConnectSet: TKMByteSet = [];
                                        aUseExactTarget: Boolean = True;
                                        aAvoidLockedByMovementCost: Boolean = True;
                                        aSilent: Boolean = False);
var
  errorStr: string;
  routeWasBuilt: Boolean; //Check if route was built, otherwise return nil
begin
  inherited Create(aUnit, aActionType, False);

  if not gTerrain.TileInMapCoords(aLocB.X, aLocB.Y) and (aLocB <> KMPOINT_INVALID_TILE) then
    raise ELocError.Create('Invalid Walk To for '+gRes.Units[aUnit.UnitType].GUIName,aLocB);

  Assert(not (fUnit.UnitType in [ANIMAL_MIN..ANIMAL_MAX])); //Animals should using TUnitActionSteer instead

  fDistance := aDistance;
  // aSetPushed Doesn't need to be rememberred (it is used only in Create here)

  fAvoidLockedAsMovementCost := aAvoidLockedByMovementCost;

  if aTargetUnit  <> nil then
    fTargetUnit  := aTargetUnit.GetPointer;
  if aTargetHouse <> nil then
    fTargetHouse := aTargetHouse.GetPointer;

  fWalkFrom     := fUnit.Position;
  fNewWalkTo    := KMPOINT_ZERO;
  fPass         := fUnit.DesiredPassability;

  if (aTargetPassability <> tpNone) and (aTargetWalkConnectSet <> []) then
  begin
    fWalkTo := gTerrain.GetClosestRoad(fWalkFrom, aTargetWalkConnectSet);
  end else
  begin
    if aUseExactTarget then
      fWalkTo := aLocB
    else
      fWalkTo := gTerrain.GetClosestTile(aLocB, aUnit.Position, fPass, False);
  end;

  //Walking on roads is preferable, but not esential. Some cases (e.g. citizens going
  //to home with no road below doorway) it will crash if we strictly enforce it
  if (fPass = tpWalkRoad) and (gTerrain.GetRoadConnectID(fWalkTo) = 0) then
    fPass := tpWalk;

  ExplanationLogCreate;
  fExplanation := 'Walk action created';
  ExplanationLogAdd;

  if fWalkTo.X*fWalkTo.Y = 0 then
    raise ELocError.Create('WalkTo 0:0', fWalkTo);

  fNodeList := TKMPointList.Create; //Freed on destroy
  SetInitValues;

  if KMSamePoint(fWalkFrom,fWalkTo) then //We don't care for this case, Execute will report action is done immediately
    Exit; //so we don't need to perform any more processing

  if aSetPushed then
  begin
    //Mark destination and current position as 'jammed', so as bad place to be pushed to
    gTerrain.Land^[aLocB.Y, aLocB.X].IncJamMeter(1);
    gTerrain.Land^[fUnit.Position.Y, fUnit.Position.X].IncJamMeter(1);

    fInteractionStatus := kisPushed; //So that unit knows it was pushed not just walking somewhere
    fExplanation := 'We were asked to get out of the way';
    ExplanationLogAdd;
    fPass := GetEffectivePassability; //Units are allowed to step off roads when they are pushed
  end;

  routeWasBuilt := AssembleTheRoute;

  //If route fails to build that's a serious issue, (consumes CPU) Can*** should mean that never happens
  if not routeWasBuilt // Means it will exit in Execute
    and not aSilent then // do not log this error in silent mode (we could expect route could not be build in some cases (f.e. warrior reRoute when attack house)
    //NoFlush logging here because this log is not much important
  begin
    errorStr := Format('Unable to make a route for %s:%d from %s to %s with "%s" TargetWC_Set = %s',
                       [gRes.Units[aUnit.UnitType].GUIName, aUnit.UID, fWalkFrom.ToString, fWalkTo.ToString,
                        PASSABILITY_GUI_TEXT[fPass], TKMSetByteSet.SetToString(aTargetWalkConnectSet)]);
    gLog.AddNoTime(errorStr);
    {$IFDEF RUNNER}
    raise Exception.Create(errorStr);
    {$ENDIF}
  end;
end;


procedure TKMUnitActionWalkTo.ExplanationLogCreate;
begin
  if not WRITE_WALKTO_LOG then Exit;

  fExplanationLog := TStringList.Create;
  if FileExists(ExeDir+'ExpLog'+IntToStr(fUnit.UID)+'.txt') then
    fExplanationLog.LoadFromFile(ExeDir+'ExpLog'+IntToStr(fUnit.UID)+'.txt');
end;


procedure TKMUnitActionWalkTo.ExplanationLogAdd;
begin
  if not WRITE_WALKTO_LOG then
    Exit;
  fExplanationLog.Add(Format(
    '%d' + #9 + '%d:%d > %d:%d > %d:%d' + #9 + fExplanation + '',
    [gGameParams.Tick,
    fUnit.PositionPrev.X,
    fUnit.PositionPrev.Y,
    fUnit.Position.X,
    fUnit.Position.Y,
    fUnit.PositionNext.X,
    fUnit.PositionNext.Y]
    ));
end;


procedure TKMUnitActionWalkTo.SetInitValues;
begin
  fNodePos              := 0;
  fDoExchange          := False;
  fDoesWalking         := False;
  fWaitingOnStep       := False;
  fDestBlocked         := False;
  fLastSideStepNodePos := -3; //Start negitive so it is at least 2 less than NodePos at the start
  fVertexOccupied      := KMPOINT_ZERO;
  fInteractionCount    := 0;
  fInteractionStatus   := kisNone;
end;


constructor TKMUnitActionWalkTo.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.CheckMarker('UnitActionWalkTo');
  LoadStream.Read(fWalkFrom);
  LoadStream.Read(fWalkTo);
  LoadStream.Read(fNewWalkTo);
  LoadStream.Read(fDistance);
  LoadStream.Read(fTargetUnit, 4); //substitute it with reference on SyncLoad
  LoadStream.Read(fTargetHouse, 4); //substitute it with reference on SyncLoad
  LoadStream.Read(fPass, SizeOf(fPass));
  LoadStream.Read(fDoesWalking);
  LoadStream.Read(fWaitingOnStep);
  LoadStream.Read(fDestBlocked);
  LoadStream.Read(fDoExchange);
  LoadStream.Read(fInteractionCount);
  LoadStream.Read(fLastSideStepNodePos);
  LoadStream.Read(fInteractionStatus, SizeOf(fInteractionStatus));
  LoadStream.Read(fAvoidLockedAsMovementCost);

  LoadStream.Read(fVertexOccupied);
  fNodeList := TKMPointList.Create;
  fNodeList.LoadFromStream(LoadStream);
  LoadStream.Read(fNodePos);
end;


procedure TKMUnitActionWalkTo.SyncLoad;
begin
  inherited;
  fTargetUnit   := gHands.GetUnitByUID(Integer(fTargetUnit));
  fTargetHouse  := gHands.GetHouseByUID(Integer(fTargetHouse));
end;


destructor TKMUnitActionWalkTo.Destroy;
begin
  if fDoExchange and (gGame <> nil) and not gGame.IsExiting then
    Assert(not fDoExchange, 'Oops, thats a very bad situation');

  if WRITE_WALKTO_LOG then
  begin
    fExplanation := 'WalkTo destroyed at'+floattostr(fUnit.PositionF.X)+':'+floattostr(fUnit.PositionF.Y);
    ExplanationLogAdd;
    fExplanationLog.SaveToFile(ExeDir+'ExpLog'+IntToStr(fUnit.UID)+'.txt');
  end;

  FreeAndNil(fExplanationLog);
  FreeAndNil(fNodeList);

  if not KMSamePoint(fVertexOccupied, KMPOINT_ZERO) then
    DecVertex;

  if fUnit <> nil then
    fUnit.IsExchanging := False;

  gHands.CleanUpUnitPointer(fTargetUnit);
  gHands.CleanUpHousePointer(fTargetHouse);
  inherited;
end;


function TKMUnitActionWalkTo.CanAbandonInternal: boolean;
begin
  Result := (fInteractionStatus <> kisPushed) //Can be removed, but decreases effectiveness
            and not fDoExchange; //Other unit could have set this
end;


// Returns True only when unit is stuck for some reason
function TKMUnitActionWalkTo.CanAbandonExternal: Boolean;
begin
  Result := (not fDoExchange) //Other unit could have set this
            and KMSamePointF(KMPointF(fUnit.Position), fUnit.PositionF);
end;


function TKMUnitActionWalkTo.ActName: TKMUnitActionName;
begin
  Result := uanWalkTo;
end;


function TKMUnitActionWalkTo.GetExplanation: UnicodeString;
const
  InteractionStatusName: array [TKMInteractionStatus] of string = (
    'None', 'Pushing', 'Pushed', 'Trying', 'Waiting');
begin
  Result := InteractionStatusName[fInteractionStatus] + ': ' + fExplanation;
end;


function TKMUnitActionWalkTo.WasPushed: Boolean;
begin
  Result := fInteractionStatus = kisPushed;
end;


function TKMUnitActionWalkTo.RouteBuilt: Boolean;
begin
  Result := fNodeList.Count > 0;
end;


procedure TKMUnitActionWalkTo.PerformExchange(const aForcedExchangePos: TKMPoint);
begin
  //If we are being forced to exchange then modify our route to make the exchange,
  //  then return to the tile we are currently on, then continue the route
  if not KMSamePoint(aForcedExchangePos,KMPOINT_ZERO) then
  begin
    fExplanation := 'We were forced to exchange places';
    ExplanationLogAdd;
    fDoExchange := True;
    if KMLengthDiag(aForcedExchangePos, fNodeList[fNodePos+1]) >= 1.5 then
      fNodeList.Insert(fNodePos+1, fUnit.PositionNext); //We must back-track if we cannot continue our route from the new tile
    fNodeList.Insert(fNodePos+1, aForcedExchangePos);
    if KMSamePoint(fUnit.PositionNext, aForcedExchangePos) then
      raise ELocError.Create('Exchange to same place', fUnit.PositionNext);
    fUnit.Direction := KMGetDirection(fUnit.PositionNext, aForcedExchangePos);
    fDoesWalking := True;
  end
  else
  begin
    //Unforced exchanging
    fExplanation := 'We were asked to exchange places';
    ExplanationLogAdd;
    fDoExchange := True;
  end;
end;


//Used for dodging and side stepping
procedure TKMUnitActionWalkTo.ChangeStepTo(const aPos: TKMPoint);
begin
  if (fNodePos+2 <= fNodeList.Count-1) and (KMLengthDiag(aPos, fNodeList[fNodePos+2]) < 1.5) then
    fNodeList[fNodePos+1] := aPos //We can simply replace the entry because it is near the next tile
  else //Otherwise we must insert it
    fNodeList.Insert(fNodePos+1, aPos);

  fUnit.Direction := KMGetDirection(fUnit.PositionNext, aPos); //Face the new tile
end;


procedure TKMUnitActionWalkTo.SmoothDiagSideStep;
var
  A, B, C, candidate: TKMPoint;
begin
  //Attempt to smooth out unnecessary side-steps in the route
  //Pathfinding will sometimes make a straight line route dodge diagonally
  //around a unit that was occupying the tile. If that unit is no longer there
  //we can smooth out the diagonal side step: (x is the tile unnecessarily dodged)
  // .
  //.x
  // .

  if (fNodePos+2 <= fNodeList.Count-1) then
  begin
    A := fNodeList[fNodePos];
    B := fNodeList[fNodePos+1];
    C := fNodeList[fNodePos+2];

    if (A.X = C.X) and (Abs(A.Y - C.Y) = 2) //We are headed in straight line
    and (A.X <> B.X) then //Next step is diagonal
      candidate := KMPoint(A.X, B.Y)
    else
      if (A.Y = C.Y) and (Abs(A.X - C.X) = 2) //We are headed in straight line
      and (A.Y <> B.Y) then //Next step is diagonal
        candidate := KMPoint(B.X, A.Y)
      else
        Exit;

    //Check if candidate is walkable and doesn't have a unit
    if (fPass in gTerrain.Land^[candidate.Y, candidate.X].Passability)
    and not gTerrain.HasUnit(candidate) then
    begin
      //Candidate is better, so update route
      fNodeList[fNodePos+1] := candidate;
    end;
  end;
end;


function TKMUnitActionWalkTo.AssembleTheRoute: Boolean;
var
  I: Integer;
  nodeList2: TKMPointList;
  avoidLocked: TKMPathAvoidLocked;
begin
  //Build a piece of route to return to nearest road piece connected to destination road network
  if (fPass = tpWalkRoad)
    and ((fDistance = 0) or gRes.Units[fUnit.UnitType].IsCitizen) //That is Citizens walking to spot
    and (gTerrain.GetRoadConnectID(fWalkFrom) <> gTerrain.GetRoadConnectID(fWalkTo)) //NoRoad returns 0
    and (gTerrain.GetRoadConnectID(fWalkTo) <> 0) then //Don't bother returning to the road if our target is off road anyway
    if CanWalkToTarget(fWalkFrom, tpWalk) then
      gGame.Pathfinding.Route_ReturnToWalkable(fWalkFrom, fWalkTo, wcRoad, gTerrain.GetRoadConnectID(fWalkTo), [tpWalk], fNodeList);

  avoidLocked := palNoAvoid;
  if (fUnit is TKMUnitWarrior)
    and (TKMUnitWarrior(fUnit).Task <> nil)
    and (TKMUnitWarrior(fUnit).Task.TaskType = uttAttackHouse) then
  begin
    if fAvoidLockedAsMovementCost then
      avoidLocked := palAvoidByMovementCost
    else
      avoidLocked := palAvoidAsUnwalkable;
  end;

  //Build a route A*
  if fNodeList.Count = 0 then //Build a route from scratch
  begin
    if CanWalkToTarget(fWalkFrom, fPass) then
      gGame.Pathfinding.Route_Make(fWalkFrom, fWalkTo, [fPass], fDistance, fTargetHouse, fNodeList, avoidLocked); //Try to make the route with fPass
  end
  else //Append route to existing part
  begin
    nodeList2 := TKMPointList.Create;
    try
      //Make a route
      if CanWalkToTarget(fNodeList[fNodeList.Count-1], fPass) then
        gGame.Pathfinding.Route_Make(fNodeList.Last, fWalkTo, [fPass], fDistance, fTargetHouse, nodeList2, avoidLocked); //Try to make the route with fPass

      //If this part of the route fails, the whole route has failed
      //At minimum Route_Make returns Count = 1 (fWalkTo)
      if nodeList2.Count > 0 then
        for I := 1 to nodeList2.Count - 1 do
          fNodeList.Add(nodeList2[I])
      else
        fNodeList.Clear; //Clear NodeList so we return False
    finally
      nodeList2.Free;
    end;
  end;

  Result := fNodeList.Count > 0;
end;


function TKMUnitActionWalkTo.CheckForNewDestination: TKMDestinationCheck;
begin
  if KMSamePoint(fNewWalkTo, KMPOINT_ZERO) then
    Result := dcNoChanges
  else
  begin
    Result := dcRouteChanged;
    fWalkTo := fNewWalkTo;
    fWalkFrom := fNodeList[fNodePos];
    fNewWalkTo := KMPOINT_ZERO;
    fNodeList.Clear;
    fNodePos := 0;
    if not AssembleTheRoute then
      Result := dcNoRoute;
  end;
end;


function TKMUnitActionWalkTo.CheckTargetHasDied: Boolean;
begin
  Result := (fTargetUnit <> nil) and fTargetUnit.IsDeadOrDying;
end;


function TKMUnitActionWalkTo.CheckAllTilesAroundHouseLocked: Boolean;
var
  I: Integer;
  cellsAround: TKMPointDirList;
begin
  Result := (fTargetHouse <> nil) and not fTargetHouse.IsDestroyed;
  if not Result then
    Exit;

  cellsAround := TKMPointDirList.Create;
  try
    fTargetHouse.GetListOfCellsAround(cellsAround, fPass);

    for I := 0 to cellsAround.Count - 1 do
      if not gTerrain.TileIsLocked(cellsAround[I].Loc) then
        Exit(False);
  finally
    cellsAround.Free;
  end;
end;


{ There's unexpected immovable obstacle on our way (suddenly grown up tree, wall, house)
1. go around the obstacle and keep on walking
2. rebuild the route from current position from scratch
  aDir - previous Unit Direction, need it to restore Direction for Warrior attacking House}
function TKMUnitActionWalkTo.CheckForObstacle(aDir: TKMDirection): TKMObstacleCheck;
var
  nextPos: TKMPoint;
  distNext: Single;
  allTilesAroundLocked: Boolean;
  U: TKMUnit;
  animStep: Integer;
begin
  Result := ocNoObstacle;

  nextPos := fNodeList[fNodePos+1];

  if (fUnit is TKMUnitWorker) then
  begin
    distNext := gHands.DistanceToEnemyTowers(nextPos, fUnit.Owner);
    if (distNext <= WATCHTOWER_RANGE_MAX)
    and (distNext < gHands.DistanceToEnemyTowers(fUnit.Position, fUnit.Owner)) then
    begin
      // Cancel the plan if we cant approach it
      if fUnit.Task is TKMTaskBuild then
        TKMTaskBuild(fUnit.Task).CancelThePlan;

      Exit(ocNoRoute);
    end;
  end;

  // Check if there is an real obstacle first
  if (not gTerrain.CheckPassability(nextPos, GetEffectivePassability))
  or (not gTerrain.CanWalkDiagonally(fUnit.Position, nextPos.X, nextPos.Y)) then
  begin
    //Try side stepping the obstacle.
    //By making HighestInteractionCount be the required timeout, we assure the solution is always checked
    if IntSolutionSideStep(nextPos, SIDESTEP_TIMEOUT) then
      Result := ocNoObstacle
    else
    //Completely re-route if no simple side step solution is available
    if CanWalkToTarget(fUnit.Position, GetEffectivePassability) then
    begin
      U := fUnit; //Local copy since Self will get freed if TrySetActionWalk succeeds
      animStep := fUnit.AnimStep; //Save anim step locally
      fUnit.SetActionWalk(fWalkTo, fType, fDistance, fTargetUnit, fTargetHouse);
      //Now Self = nil since the walk action was replaced! Don't access members and exit ASAP
      //Restore direction, cause it usually looks unpleasant,
      //when warrior turns to locked Loc and then immediately (in 1 tick) turns away when on new route
      U.Direction := aDir;
      U.AnimStep := animStep; //Restore anim step as well, it looks smoother (otherwise unit will stay still for a 1 tick)
      //Now Self = nil since the walk action was replaced! Don't access members and exit ASAP
      Exit(ocReRouteMade);
    end else
      Result := ocNoRoute;
  end
  else
  // And if there is no obstacle, then apply special for warriors attacking house
  // Warriors should replan when attacking houses if the chosen target tile is locked (by fellow attacking unit)
  if (fUnit is TKMUnitWarrior)
    and (TKMUnitWarrior(fUnit).Task <> nil)
    and (TKMUnitWarrior(fUnit).Task.TaskType = uttAttackHouse)
    and (gTerrain.TileIsLocked(fNodeList.Last)) then
  begin
    if CanWalkToTarget(fUnit.Position, GetEffectivePassability) then
    begin
      allTilesAroundLocked := CheckAllTilesAroundHouseLocked;

      if allTilesAroundLocked then
        // Keep on walking. Some spot may free up.
        // Also, "greedy" warriors look and feel better.
        Exit(ocNoObstacle)
      else
      begin
        U := fUnit; //Local copy since Self will get freed if TrySetActionWalk succeeds
        animStep := fUnit.AnimStep; //Save anim step locally
        if fUnit.TrySetActionWalk(fWalkTo, fType, fDistance, fTargetUnit, fTargetHouse, False) then
        begin
          //Now Self = nil since the walk action was replaced! Don't access members and exit ASAP
          //Restore direction, cause it usually looks unpleasant,
          //when warrior turns to locked Loc and then immediately (in 1 tick) turns away when on new route
          U.Direction := aDir;
          U.AnimStep := animStep; //Restore anim step as well, it looks smoother (otherwise unit will stay still for a 1 tick)
          Exit(ocReRouteMade);
        end else
          Exit(ocNoObstacle); //Same as when AllTilesAroundLocked
      end;
    end else
      Result := ocNoRoute;
    Exit;
  end;
end;


{ Walk is complete when one of the following is True:
  - We reached last node en route irregardless of walkTarget (position, house, unit)
  - We were walking to spot and required range is reached
  - We were walking to house and required range to house is reached
  - We were walking to unit and met it early
  - The Task wants us to abandon }
function TKMUnitActionWalkTo.CheckWalkComplete: Boolean;
begin
  Result := (fNodePos >= fNodeList.Count - 1)
            or ((fTargetHouse = nil) and (Round(KMLengthDiag(fUnit.Position,fWalkTo)) <= fDistance))
            or ((fTargetHouse <> nil) and (fTargetHouse.GetDistance(fUnit.Position) <= fDistance))
            or ((fTargetUnit <> nil) and (KMLengthDiag(fUnit.Position,fTargetUnit.Position) <= fDistance))
            or ((fUnit.Task <> nil) and fUnit.Task.WalkShouldAbandon);
end;


procedure TKMUnitActionWalkTo.IncVertex;
begin
  //Tell gTerrain that this vertex is being used so no other unit walks over the top of us
  if not KMSamePoint(fVertexOccupied, KMPOINT_ZERO) then
    raise ELocError.Create('IncVertex', fVertexOccupied);

  gTerrain.UnitVertexAdd(fUnit.PositionPrev, fUnit.PositionNext);
  fVertexOccupied := KMGetDiagVertex(fUnit.PositionPrev, fUnit.PositionNext);
end;


procedure TKMUnitActionWalkTo.DecVertex;
begin
  //Tell gTerrain that this vertex is not being used anymore
  if KMSamePoint(fVertexOccupied, KMPOINT_ZERO) then
    raise ELocError.Create('DecVertex 0:0', fVertexOccupied);

  gTerrain.UnitVertexRem(fVertexOccupied);
  fVertexOccupied := KMPOINT_ZERO;
end;


function TKMUnitActionWalkTo.IntCheckIfPushing(aOpponent: TKMUnit): Boolean;
begin
  Result := False;

  //If we are asking someone to move away then just wait until they are gone
  if (fInteractionStatus <> kisPushing) then
    Exit;

  //Make sure they are still moving out of the way
  if (aOpponent.Action is TKMUnitActionWalkTo)
  and (TKMUnitActionWalkTo(aOpponent.Action).fInteractionStatus = kisPushed) then
  begin
    fExplanation := 'Unit is blocking the way and has been asked to move';
    ExplanationLogAdd;
    Result := True; //Means exit DoUnitInteraction
  end
  else
  begin //We pushed a unit out of the way but someone else took it's place! Now we must start over to solve problem with this new opponent
    fInteractionCount := 0;
    fInteractionStatus := kisTrying;
    fExplanation := 'Someone took the pushed unit''s place';
    ExplanationLogAdd;
  end;
end;


{ We can push idling unit }
function TKMUnitActionWalkTo.IntSolutionPush(aOpponent: TKMUnit; aHighestInteractionCount: Integer): Boolean;
var
  opponentPass: TKMTerrainPassability;
begin
  Result := False;

  if aHighestInteractionCount < PUSH_TIMEOUT then
    Exit;

  //Ask the other unit to step aside, only if they are idle!
  if (aOpponent.Action is TKMUnitActionStay)
    and not TKMUnitActionStay(aOpponent.Action).Locked then
  begin
    //We must alert the opponent to our presence because it looks bad when you warrior is pushed
    //by the enemy instead of fighting them.
    //CheckAlliance is for optimisation since pushing allies doesn't matter
    if (aOpponent is TKMUnitWarrior)
      and (gHands.CheckAlliance(aOpponent.Owner, fUnit.Owner) = atEnemy)
      and TKMUnitWarrior(aOpponent).CheckForEnemy then
      Exit;

    opponentPass := aOpponent.DesiredPassability;
    if opponentPass = tpWalkRoad then
      opponentPass := tpWalk;

    //We tell opponent, that we were also pushed, so he could avoid unhelpful exchange with us
    //So ipdate fInteractionStatus after that
    aOpponent.SetActionWalkPushed(gTerrain.GetOutOfTheWay(aOpponent, fUnit.Position, opponentPass, WasPushed));

    fInteractionStatus := kisPushing;

    if not CanAbandonInternal then
      raise ELocError.Create('Unit walk IntSolutionPush', fUnit.Position);

    fExplanation := 'Unit was blocking the way but it has been forced to go away now';
    ExplanationLogAdd; //Hopefully next tick tile will be free and we will walk there
    Result := True; //Means exit DoUnitInteraction
  end;
end;


function TKMUnitActionWalkTo.IntSolutionExchange(aOpponent: TKMUnit; aHighestInteractionCount: Integer): Boolean;
var
  opponentNextNextPos: TKMPoint;
begin
  Result := False;

  //Do not initiate exchanges if we are in DestBlocked mode, as we are zero priority and other units will
  if not fDestBlocked
  and (((aHighestInteractionCount >= EXCHANGE_TIMEOUT) and (fInteractionStatus <> kisPushed)) or //When pushed this timeout/counter is different
     (fInteractionStatus = kisPushed)) then //If we get pushed then always try exchanging (if we are here then there is no free tile)
  begin //Try to exchange with the other unit if they are willing

    //We must alert the opponent to our presence because it looks bad when you exchange places
    //with the enemy instead of fighting them.
    //CheckAlliance is for optimisation since pushing allies doesn't matter
    if (aOpponent is TKMUnitWarrior)
    and (gHands.CheckAlliance(aOpponent.Owner, fUnit.Owner) = atEnemy)
    and TKMUnitWarrior(aOpponent).CheckForEnemy then
      Exit;

    //If Unit on the way is walking somewhere and not exchanging with someone else
    if (aOpponent.Action is TKMUnitActionWalkTo)
    and (not TKMUnitActionWalkTo(aOpponent.Action).fDoExchange)
    //Unit not yet arrived on tile, wait till it does, otherwise there might be 2 units on one tile
    and (not TKMUnitActionWalkTo(aOpponent.Action).fDoesWalking)
    //Diagonal vertex must not be in use
    and ((not KMStepIsDiag(fUnit.Position,fNodeList[fNodePos+1])) or (not gTerrain.HasVertexUnit(KMGetDiagVertex(fUnit.Position,fNodeList[fNodePos+1])))) then
      //Check that our tile is walkable for the opponent! (we could be a worker on a building site)
      if (TKMUnitActionWalkTo(aOpponent.Action).GetEffectivePassability in gTerrain.Land^[fUnit.Position.Y,fUnit.Position.X].Passability) then
      begin
        //Check unit's future position is where we are now and exchange (use NodeList rather than direction as it's not always right)
        if TKMUnitActionWalkTo(aOpponent.Action).GetNextNextPosition(opponentNextNextPos) then
        begin
          if KMSamePoint(opponentNextNextPos, fUnit.Position) then
          begin
            //Graphically both units are walking side-by-side, but logically they simply walk through each-other.
            TKMUnitActionWalkTo(aOpponent.Action).PerformExchange(KMPOINT_ZERO); //Request unforced exchange

            fExplanation := 'Unit in the way is walking in the opposite direction. Performing an exchange';
            ExplanationLogAdd;
            fDoExchange := True;
            //They both will exchange next tick
            Result := True; //Means exit DoUnitInteraction
          end
          else //Otherwise try to force the unit to exchange IF they are in the waiting phase
            if TKMUnitActionWalkTo(aOpponent.Action).fInteractionStatus = kisWaiting then
            begin
              //Because we are forcing this exchange we must inject into the other unit's nodelist by passing our current position
              TKMUnitActionWalkTo(aOpponent.Action).PerformExchange(fUnit.Position);

              fExplanation := 'Unit in the way is in waiting phase. Forcing an exchange';
              ExplanationLogAdd;
              fDoExchange := True;
              //They both will exchange next tick
              Result := True; //Means exit DoUnitInteraction
            end;
        end;
      end;
  end;
end;


//If we were asked to move away then all we are allowed to do is push and exchanging,
//no re-routing, dodging etc. so we must exit here before any more tests
function TKMUnitActionWalkTo.IntCheckIfPushed(aHighestInteractionCount: Integer): Boolean;
begin
  Result := False;

  if fInteractionStatus = kisPushed then
  begin
    //If we've been trying to get out of the way for a while but we haven't found a solution,
    //(i.e. other unit is stuck) try a different direction
    if aHighestInteractionCount >= PUSHED_TIMEOUT then
    begin

      fInteractionStatus := kisNone;
      if not CanAbandonInternal then //in fact tests only for fDoExchange
        raise ELocError.Create('Unit walk IntCheckIfPushed',fUnit.Position);

      //Since only Idle units can be pushed, we don't need to carry on TargetUnit/TargetHouse/etc props
      fUnit.SetActionWalkPushed(gTerrain.GetOutOfTheWay(fUnit, KMPOINT_ZERO,GetEffectivePassability));
      //This action has now been freed, so we must exit without changing anything
      Exit(True); //Means exit DoUnitInteraction
    end;
    Inc(fInteractionCount);
    fExplanation := 'We were pushed and are now waiting for a space to clear for us';
    ExplanationLogAdd;
    Result := True; //Means exit DoUnitInteraction
  end;
end;


function TKMUnitActionWalkTo.IntSolutionDodge(aOpponent: TKMUnit; aHighestInteractionCount: Integer): Boolean;
var
  I: Byte; //Test 2 options really
  tempPos: TKMPoint;
  opponentNextNextPos: TKMPoint;
  altOpponent: TKMUnit;
begin
  //If there is a unit on one of the tiles either side of target that wants to swap, do so
  Result := False;
  if aHighestInteractionCount >= DODGE_TIMEOUT then
  //UnitsHitTest (used twice here) is fairly CPU intensive, so don't run it every time
  if CheckInteractionFreq(aHighestInteractionCount,DODGE_TIMEOUT,DODGE_FREQ) then
  begin
    //Tiles to the left (-1) and right (+1) (relative to unit) of the one we are walking to
    for I := 0 to 1 do
    begin
      if I = 0 then tempPos := KMGetPointInDir(fUnit.Position, KMPrevDirection(KMGetDirection(fUnit.PositionNext,fNodeList[fNodePos+1])));
      if I = 1 then tempPos := KMGetPointInDir(fUnit.Position, KMNextDirection(KMGetDirection(fUnit.PositionNext,fNodeList[fNodePos+1])));

      //First make sure tile is on map and walkable!
      if gTerrain.TileInMapCoords(tempPos.X, tempPos.Y)
      and gTerrain.CanWalkDiagonally(fUnit.Position, tempPos.X, tempPos.Y)
      and (GetEffectivePassability in gTerrain.Land^[tempPos.Y, tempPos.X].Passability) then

        if gTerrain.HasUnit(tempPos) then //Now see if it has a unit
        begin
          //There is a unit here, first find our alternate opponent
          altOpponent := gTerrain.UnitsHitTest(tempPos.X, tempPos.Y);

          //Make sure unit really exists, is walking and has arrived on tile
          if (altOpponent <> nil) and (altOpponent.Action is TKMUnitActionWalkTo) and
            (not TKMUnitActionWalkTo(altOpponent.Action).fDoExchange)
            and (not TKMUnitActionWalkTo(altOpponent.Action).fDoesWalking)
            and ((not KMStepIsDiag(fUnit.PositionNext,fNodeList[fNodePos+1])) //Isn't diagonal
            or (KMStepIsDiag(fUnit.PositionNext,fNodeList[fNodePos+1])       //...or is diagonal and...
            and not gTerrain.HasVertexUnit(KMGetDiagVertex(fUnit.Position, tempPos)))) then //...vertex is free
            if TKMUnitActionWalkTo(altOpponent.Action).GetNextNextPosition(opponentNextNextPos) then
              if KMSamePoint(opponentNextNextPos, fUnit.Position) //Now see if they want to exchange with us
              //Check that our tile is walkable for the opponent! (we could be a worker on a building site)
              and (TKMUnitActionWalkTo(altOpponent.Action).GetEffectivePassability in gTerrain.Land^[fUnit.Position.Y,fUnit.Position.X].Passability) then
              begin
                //Perform exchange from our position to tempPos
                TKMUnitActionWalkTo(altOpponent.Action).PerformExchange(KMPOINT_ZERO); //Request unforced exchange

                fExplanation:='Unit on tile next to target tile wants to swap. Performing an exchange';
                ExplanationLogAdd;
                fDoExchange := True;
                ChangeStepTo(tempPos);
                //They both will exchange next tick
                //Means exit DoUnitInteraction
                Exit(True); //Once we've found a solution, do NOT check the other alternative dodge position (when for loop i=1)
              end;
        end;
    end;
  end;
end;


//If the blockage won't go away because it's busy (Locked by other unit) then try going around it
//by re-routing our route and avoiding that tile and all other Locked tiles
function TKMUnitActionWalkTo.IntSolutionAvoid(aOpponent: TKMUnit): Boolean;
var
  newNodeList: TKMPointList;
begin
  Result := False;

  if (fInteractionCount >= AVOID_TIMEOUT) or fDestBlocked then
  //Route_MakeAvoid is very CPU intensive, so don't run it every time
  if CheckInteractionFreq(fInteractionCount, AVOID_TIMEOUT, AVOID_FREQ) then
  begin
    //Can't go around our target position unless it's a house
    if KMSamePoint(aOpponent.Position, fWalkTo) and (fTargetHouse = nil) and aOpponent.Action.Locked then
    begin
      fDestBlocked := True; //When in this mode we are zero priority as we cannot reach our destination. This allows serfs with stone to get through and clear our path.
      fInteractionStatus := kisWaiting; //If route cannot be made it means our destination is currently not available (workers in the way) So allow us to be pushed.
      fExplanation := 'Our destination is blocked by busy units';
      ExplanationLogAdd;
      Exit;
    end;
    //We should try to make a new route if we're blocked by a locked opponent, or if we were blocked in the past (to clear fDestBlocked)
    if fDestBlocked or aOpponent.Action.Locked then
    begin
      newNodeList := TKMPointList.Create;
      // Make a new route avoiding tiles with busy units

      //todo -cComplicated: try to not make completely new route with penalty for a walk offroad (for a delivering serfs f.e.)
      // In that case we can still get a serf going offroad in some cases when its better for him to make a shortcut
      // Better would be to try to make a new route, which will try to reunite with an old route and then those routes will be merged
      // This way we will get still only-road route except the small route around blocked tile
      if gGame.Pathfinding.Route_MakeAvoid(fUnit.Position, fWalkTo, fPass, GetEffectivePassability, fDistance, fTargetHouse, newNodeList) then
        //Check if the new route still goes through busy units (no other route exists)
        if (newNodeList.Count > 1) and gTerrain.TileIsLocked(newNodeList[1]) then
        begin
          fDestBlocked := True; //When in this mode we are zero priority as we cannot reach our destination. This allows serfs with stone to get through and clear our path.
          fInteractionStatus := kisWaiting; //If route cannot be made it means our destination is currently not available (workers in the way) So allow us to be pushed.
          fExplanation := 'Our destination is blocked by busy units';
          ExplanationLogAdd;
        end
        else
        begin
          //NodeList has now been re-routed, so we need to re-init everything else and start walk again
          fNodeList.Free; //Free our current node list and swap in this new one
          fNodeList := newNodeList;
          newNodeList := nil; //So we don't FreeAndNil it at the end (it's now our main node list)
          SetInitValues;
          fExplanation := 'Unit in the way is working so we will re-route around it';
          ExplanationLogAdd;
          fDestBlocked := False;
          //Exit, then on next tick new walk will start
          Result := True; //Means exit DoUnitInteraction
        end;
        FreeAndNil(newNodeList);
    end;
  end;
end;


{This solution tries to find an unoccupied tile where unit can side-step}
function TKMUnitActionWalkTo.IntSolutionSideStep(const aPosition: TKMPoint; aHighestInteractionCount: Integer): Boolean;
var
  sideStepTest: TKMPoint;
  found: Boolean;
begin
  Result := False; //Should only return True if a sidestep was taken (for use in CheckForObstacle)
  if (aHighestInteractionCount < SIDESTEP_TIMEOUT) or fDoExchange then exit;
  if KMSamePoint(aPosition, fWalkTo) then Exit; //Someone stays right on target, no point in side-stepping
  if not CheckInteractionFreq(aHighestInteractionCount, SIDESTEP_TIMEOUT, SIDESTEP_FREQ) then Exit; //FindSideStepPosition is CPU intensive, so don't run it every time

  //Find a node
  if fNodePos+2 > fNodeList.Count - 1 then //Tell Terrain about our next position if we can
    found := gTerrain.FindSideStepPosition(fUnit.Position, aPosition, KMPOINT_ZERO, GetEffectivePassability, sideStepTest, fNodePos - fLastSideStepNodePos < 2)
  else
    found := gTerrain.FindSideStepPosition(fUnit.Position, aPosition, fNodeList[fNodePos+2], GetEffectivePassability, sideStepTest, fNodePos - fLastSideStepNodePos < 2);

  if not found then Exit; //It could be 0,0 if all tiles were blocked (return False)

  //Otherwise the sidestep is valid so modify our route to go via this tile
  fExplanation := 'Sidestepping to a tile next to target';
  ExplanationLogAdd;
  ChangeStepTo(sideStepTest);
  fLastSideStepNodePos := fNodePos;
  Result := True; //Means exit DoUnitInteraction, but also means a sidestep has been taken (for use in CheckForObstacle)
end;


//States whether we are allowed to run time consuming tests
//  1. We must have been stuck for more than aTimeout
//  2. We must only return True every aFreq ticks.
//For example: say we are checking whether we can use the solution Avoid. aTimeout = 10, aFreq = 20.
//Therefore we return True on these ticks: 10, 30, 50, 70....
//You could sum this up in words as: After 10 ticks, check the solution, then every 20 ticks
//after that, check it again. I hope that makes sense, please rewrite it in a more obvious way.
//Read the memo at the top of this file explaining what TIMEOUT and FREQ mean.
function TKMUnitActionWalkTo.CheckInteractionFreq(aIntCount, aTimeout, aFreq: Integer): Boolean;
begin
  Result := (aIntCount - aTimeout >= 0) and ((aIntCount - aTimeout) mod aFreq = 0);
end;


function TKMUnitActionWalkTo.CanWalkToTarget(const aFrom: TKMPoint; aPass: TKMTerrainPassability): Boolean;
begin
  Result := ((fTargetHouse = nil) and fUnit.CanWalkTo(aFrom, fWalkTo, aPass, fDistance))
         or ((fTargetHouse <> nil) and fUnit.CanWalkTo(aFrom, fTargetHouse, aPass, fDistance));
end;


function TKMUnitActionWalkTo.DoUnitInteraction: Boolean;
var
  opponent: TKMUnit;
  highestInteractionCount: Integer;
begin
  Result := True; //False = interaction yet unsolved, stay and wait.
  if not FEAT_UNIT_INTERACTION then Exit;

  //If there's a unit using this vertex to walk diagonally then we must wait, they will be finished after this step
  if KMStepIsDiag(fUnit.Position,fNodeList[fNodePos+1]) and
    gTerrain.HasVertexUnit(KMGetDiagVertex(fUnit.Position,fNodeList[fNodePos+1])) then
  begin
    fExplanation := 'Diagonal vertex is being used, we must wait';
    ExplanationLogAdd;
    Exit(False);
  end;

  //If there's no unit we can keep on walking, interaction does not need to be solved
  if not gTerrain.HasUnit(fNodeList[fNodePos+1]) then Exit;
  //From now on there is a blockage, so don't allow to walk unless the problem is resolved
  Result := False;

  //Find the unit that is in our path
  opponent := gTerrain.UnitsHitTest(fNodeList[fNodePos+1].X, fNodeList[fNodePos+1].Y);
  //If there's currently no unit in the way but tile is pre-occupied
  if opponent = nil then
  begin
    //Do nothing and wait till unit is actually there so we can interact with it
    fExplanation:='Can''t walk. No Unit in the way but tile is occupied';
    ExplanationLogAdd;
    Exit;
  end;

  // Can't interact with animals
  if opponent.IsAnimal then
    Exit;

  //If we are in DestBlocked mode then only use our counter so we are always zero priority until our path clears
  if ((opponent.Action is TKMUnitActionWalkTo) and not fDestBlocked) then
    highestInteractionCount := Max(fInteractionCount,TKMUnitActionWalkTo(opponent.Action).fInteractionCount)
  else highestInteractionCount := fInteractionCount;

  if (opponent.Action is TKMUnitActionGoInOut) then
  begin //Unit is walking into house, we can wait
    fExplanation:='Unit is walking into house, we can wait';
    ExplanationLogAdd;
    Exit;
  end;

  if fDestBlocked then fInteractionStatus := kisWaiting;

  //INTERACTION SOLUTIONS: Split into different sections or "solutions". If True returned it means exit.

  //If we are asking someone to move away then just wait until they are gone
  if IntCheckIfPushing(opponent) then Exit;
  if IntSolutionPush(opponent,highestInteractionCount) then Exit;
  if IntSolutionExchange(opponent,highestInteractionCount) then Exit;
  if IntCheckIfPushed(fInteractionCount) then Exit;
  if not fDestBlocked then fInteractionStatus := kisTrying; //If we reach this point then we don't have a solution...
  if IntSolutionDodge(opponent,highestInteractionCount) then Exit;
  if IntSolutionAvoid(opponent) then Exit;
  if IntSolutionSideStep(opponent.Position,fInteractionCount) then Exit;

  //We will allow other units to force an exchange with us as we haven't found a solution or our destination is blocked
  if (fInteractionCount >= WAITING_TIMEOUT) or fDestBlocked then fInteractionStatus := kisWaiting;

  //If we haven't exited yet we must increment the counters so we know how long we've been here
  Inc(fInteractionCount);
end;


function TKMUnitActionWalkTo.GetNextNextPosition(out NextNextPos: TKMPoint): Boolean;
begin
  if InRange(fNodePos+1, 0, fNodeList.Count - 1) then
  begin
    NextNextPos := fNodeList[fNodePos+1];
    Result := True;
  end
  else
  begin
    NextNextPos := KMPOINT_ZERO;
    Result := False; //Our route is not that long, so there is no "NextNext" position
  end;
end;


//Modify route to go to this destination instead. Kind of like starting the walk over again but without recreating the action
procedure TKMUnitActionWalkTo.ChangeWalkTo(const aLoc: TKMPoint; aDistance: Single);
begin
  if not gTerrain.TileInMapCoords(aLoc.X, aLoc.Y) then
    raise ELocError.Create('Invalid Change Walk To for '+gRes.Units[fUnit.UnitType].GUIName, aLoc);

  if fWalkTo = aLoc then Exit; //We are walking to the same loc

  //We are no longer being pushed
  if fInteractionStatus = kisPushed then
    fInteractionStatus := kisNone;

  fNewWalkTo := aLoc;
  fDistance  := aDistance;

  //Release pointers if we had them
  gHands.CleanUpHousePointer(fTargetHouse);
  gHands.CleanUpUnitPointer(fTargetUnit);
end;


procedure TKMUnitActionWalkTo.ChangeWalkTo(aNewTargetUnit: TKMUnit; aDistance: Single);
begin
  //We are no longer being pushed
  if fInteractionStatus = kisPushed then
    fInteractionStatus := kisNone;

  fNewWalkTo := aNewTargetUnit.Position;
  fDistance  := aDistance;

  //Release pointers if we had them
  gHands.CleanUpHousePointer(fTargetHouse);
  gHands.CleanUpUnitPointer(fTargetUnit);
  if aNewTargetUnit <> nil then
    fTargetUnit := aNewTargetUnit.GetPointer; //Change target
end;


// Returns passability that unit is allowed to walk on
function TKMUnitActionWalkTo.GetEffectivePassability: TKMTerrainPassability;
begin
  //Road walking is only recomended. (i.e. for route building) We are allowed to step off the road sometimes.
  if fPass = tpWalkRoad then
    Result := tpWalk
  else
    Result := fPass;
end;


function TKMUnitActionWalkTo.Execute: TKMActionResult;
var
  dx, dy: ShortInt;
  walkX, walkY, distance: Single;
  oldDir: TKMDirection;
begin
  Result := arActContinues;
  StepDone := False;
  fDoesWalking := False; // Set it to False at start of update

  // Happens whe e.g. Serf stays in front of Store and gets Deliver task
  if KMSamePoint(fWalkFrom, fWalkTo) then
    Exit(arActDone);

  // Route was not built
  if fNodeList.Count = 0 then
    Exit(arActAborted);

  // Walk complete - NodePos cannot be greater than NodeCount (this should not happen, cause is unknown but for now this check stops crashes)
  if fNodePos > fNodeList.Count - 1 then
  begin
    if KMStepIsDiag(fUnit.PositionPrev, fUnit.PositionNext) then
      DecVertex; // Unoccupy vertex
    fUnit.IsExchanging := False; // Disable sliding (in case it was set in previous step)
    Exit(arActDone);
  end;

  // Execute the route in series of moves
  // Use umtWalk move type here, since we just want to evaluate if we are close enough
  distance := gRes.Units[fUnit.UnitType].GetEffectiveWalkSpeed(False);

  //Check if unit has arrived on tile
  if KMSamePointF(fUnit.PositionF, KMPointF(fNodeList[fNodePos]), distance/2) then
  begin
    //Set precise position to avoid rounding errors
    fUnit.PositionF := KMPointF(fNodeList[fNodePos]);

    if (fNodePos > 0) and (not fWaitingOnStep)
      and KMStepIsDiag(fNodeList[fNodePos-1],fNodeList[fNodePos]) then
      DecVertex; //Unoccupy vertex

    fWaitingOnStep := True;

    StepDone := True; //Unit stepped on a new tile
    fUnit.IsExchanging := False; //Disable sliding (in case it was set in previous step)


    { Update destination point }

    //Make changes to our route if we are supposed to be following a unit
    if CanAbandonInternal
      and (fTargetUnit <> nil)
      and (not fTargetUnit.IsDeadOrDying)
      and not KMSamePoint(fTargetUnit.Position, fWalkTo)
      //It's wasteful to run pathfinding to correct route every step of the way, so if the target unit
      //is within 8 tiles, update every step. Within 16, every 2 steps, 24, every 3 steps, etc.
      and (fNodePos mod Max((Round(KMLengthDiag(fUnit.Position, fTargetUnit.Position)) div 8), 1) = 0) then
    begin
      //If target unit has moved then change course and keep following it
      ChangeWalkTo(fTargetUnit, fDistance);
    end;

    //Check if we need to walk to a new destination
    if CanAbandonInternal and (CheckForNewDestination = dcNoRoute) then
      Exit(arActAborted);

    //Check for units nearby to fight
    if CanAbandonInternal and (fUnit is TKMUnitWarrior) then
      if TKMUnitWarrior(fUnit).CheckForEnemy then
        //If we've picked a fight it means this action no longer exists,
        //so we must exit out (don't set DoEnd as that will now apply to fight action)
        Exit;

    //Walk complete
    if not fDoExchange and CheckWalkComplete then
    begin
      if (fDistance > 0) and ((fUnit.Task = nil) or (not fUnit.Task.WalkShouldAbandon))
      and not KMSamePoint(fNodeList[fNodePos], fWalkTo) then //Happens rarely when we asked to sidestep towards our not locked target (Warrior)
        fUnit.Direction := KMGetDirection(fNodeList[fNodePos], fWalkTo); //Face tile (e.g. worker)
      Exit(arActDone);
    end;

    //Check if target unit (warrior) has died and if so abandon our walk and so delivery task can exit itself
    if CanAbandonInternal then
      if CheckTargetHasDied then
        Exit(arActAborted);

    //This is sometimes caused by unit interaction changing the route so simply ignore it
    if KMSamePoint(fNodeList[fNodePos], fNodeList[fNodePos+1]) then
    begin
      Inc(fNodePos); //Inc the node pos and exit so this step is simply skipped
      Exit; //Will take next step during next execute
    end;

    //Attempt to smooth out unnecessary side-steps in the route
    if not fDoExchange then
      SmoothDiagSideStep;

    //If we were in Worker mode but have now reached the walk network of our destination switch to CanWalk mode to avoid walking on other building sites
    {if (fPass = CanWorker) and (fTerrain.GetWalkConnectID(fWalkTo) <> 0) and
      (fTerrain.GetWalkConnectID(fWalkTo) = fTerrain.GetWalkConnectID(NodeList[NodePos])) then
      fPass := CanWalk;}

    //Save unit dir in case we will need to restore it
    oldDir := fUnit.Direction;

    //Update unit direction according to next Node
    fUnit.Direction := KMGetDirection(fNodeList[fNodePos], fNodeList[fNodePos+1]);

    // Check if we can walk to next tile in the route
    // Don't use CanAbandonInternal because skipping this check can cause crashes (e.g. tile become unwalkable)
    if not fDoExchange then
      case CheckForObstacle(oldDir) of
        ocNoObstacle:   ;
        ocReRouteMade:  Exit; //Self was freed so exit immediately. New route will pick-up
        ocNoRoute:      Exit(arActAborted);
      end;

    //Perform exchange
    //Both exchanging units have fDoExchange:=True assigned by 1st unit, hence 2nd should not try doing UnitInteraction!
    if fDoExchange then
    begin
       //If this is a diagonal exchange we must make sure someone (other than the other unit) is not crossing our path
      if KMStepIsDiag(fUnit.Position,fNodeList[fNodePos+1])
      and (not gTerrain.VertexUsageCompatible(fUnit.Position,fNodeList[fNodePos+1])) then
        Exit; //Someone is crossing the path of our exchange, so we will wait until they are out of the way (this check guarantees both units in the exchange will wait)

      Inc(fNodePos);

      fUnit.PositionNext := fNodeList[fNodePos];

      //Check if we are the first or second unit (has the swap already been performed?)
      if fUnit = gTerrain.Land^[fUnit.PositionPrev.Y,fUnit.PositionPrev.X].IsUnit then
        gTerrain.UnitSwap(fUnit.PositionPrev,fUnit.PositionNext,fUnit);

      fInteractionStatus := kisNone;
      fDoExchange := False;
      fUnit.IsExchanging := True; //So unit knows that it must slide
      fInteractionCount := 0;
      if KMStepIsDiag(fUnit.PositionPrev, fUnit.PositionNext) then IncVertex; //Occupy the vertex
    end else
    begin
      if not DoUnitInteraction then
        Exit //Do no further walking until unit interaction is solved
      else
        fInteractionCount := 0; //Reset the counter when there is no blockage and we can walk

      Inc(fNodePos);
      fUnit.PositionNext := fNodeList[fNodePos];

      if KMLength(fUnit.PositionPrev, fUnit.PositionNext) > 1.5 then
        raise ELocError.Create('Unit walk length > 1.5', fUnit.PositionPrev);

      if gTerrain.Land^[fUnit.PositionPrev.Y, fUnit.PositionPrev.X].IsUnit = nil then
        raise ELocError.Create('Unit walk Prev position IsUnit = nil', fUnit.PositionPrev);

      fUnit.Walk(fUnit.PositionPrev, fUnit.PositionNext); //Pre-occupy next tile
      if KMStepIsDiag(fUnit.PositionPrev, fUnit.PositionNext) then IncVertex; //Occupy the vertex
    end;

  end;
  fWaitingOnStep := False;

  if fNodePos > fNodeList.Count - 1 then
    raise ELocError.Create('WalkTo overrun', fUnit.Position);

  walkX := fNodeList[fNodePos].X - fUnit.PositionF.X;
  walkY := fNodeList[fNodePos].Y - fUnit.PositionF.Y;
  dx := Sign(walkX); //-1,0,1
  dy := Sign(walkY); //-1,0,1

  distance := gRes.Units[fUnit.UnitType].GetEffectiveWalkSpeed((dx <> 0) and (dy <> 0));

  fUnit.PositionF := KMPointF(fUnit.PositionF.X + dx * Min(distance, Abs(walkX)),
                              fUnit.PositionF.Y + dy * Min(distance, Abs(walkY)));

  Inc(fUnit.AnimStep);
  StepDone := False; //We are not actually done because now we have just taken another step
  fDoesWalking := True; //Now it's definitely True that unit did walked one step
end;


procedure TKMUnitActionWalkTo.Save(SaveStream: TKMemoryStream);
begin
  inherited;

  SaveStream.PlaceMarker('UnitActionWalkTo');
  SaveStream.Write(fWalkFrom);
  SaveStream.Write(fWalkTo);
  SaveStream.Write(fNewWalkTo);
  SaveStream.Write(fDistance);
  SaveStream.Write(fTargetUnit.UID); //Store ID, then substitute it with reference on SyncLoad
  SaveStream.Write(fTargetHouse.UID); //Store ID, then substitute it with reference on SyncLoad

  SaveStream.Write(fPass,SizeOf(fPass));
  SaveStream.Write(fDoesWalking);
  SaveStream.Write(fWaitingOnStep);
  SaveStream.Write(fDestBlocked);
  SaveStream.Write(fDoExchange);
  SaveStream.Write(fInteractionCount);
  SaveStream.Write(fLastSideStepNodePos);
  SaveStream.Write(fInteractionStatus,SizeOf(fInteractionStatus));
  SaveStream.Write(fAvoidLockedAsMovementCost);

  SaveStream.Write(fVertexOccupied);
  fNodeList.SaveToStream(SaveStream);
  SaveStream.Write(fNodePos);
end;


procedure TKMUnitActionWalkTo.Paint;
var
  showRoute: Boolean;
begin
  showRoute := False;
  if SHOW_UNIT_ROUTES then
    if not ((gMySpectator.Selected is TKMUnit) or (gMySpectator.Selected is TKMUnitGroup))
      or (gMySpectator.Selected = fUnit)
      or ((fUnit is TKMUnitWarrior)
        and (gMySpectator.Selected is TKMUnitGroup)
        and (TKMUnitGroup(gMySpectator.Selected).SelectedUnit = fUnit)) then
      showRoute := True;

  showRoute := showRoute or (gMySpectator.HighlightRoute.Entity = fUnit);

  if showRoute then
    gRenderAux.UnitRoute(fNodeList, fNodePos, fUnit.UID);
end;


function TKMUnitActionWalkTo.CanBeInterrupted(aForced: Boolean = True): Boolean;
begin
  Result := CanAbandonExternal and StepDone;//Only when unit is idling during Interaction pauses
end;


// Check if our path is through viewport, to show debug unit route
function TKMUnitActionWalkTo.NeedToPaint(const aRect: TKMRect): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to fNodeList.Count - 1 do
    if KMInRect(fNodeList[I], aRect) then
      Exit(True);
end;


function TKMUnitActionWalkTo.ObjToStringShort(const aSeparator: string = ' '): string;
begin
  Result := inherited + Format('%sFrom = %s%sTo = %s', [
                                aSeparator,
                                fWalkFrom.ToString, aSeparator,
                                fWalkTo.ToString]);
end;


function TKMUnitActionWalkTo.ObjToString(const aSeparator: string = ' '): string;
begin
  Result := inherited + Format('%sNewWalkTo = %s%sDist = %s%sTargetUnit = %d%sTargetHouse = %d%sPass = %s%sDoesWalk = %s%s' +
                               'WaitOnStep = %s%sDestBlocked = %s%sDoExchange = %s%sInterCnt = %d%sLastSideStepNode = %d%sInterStatus = %s',
                               [aSeparator,
                                fNewWalkTo.ToString, aSeparator,
                                FormatFloat('#0.#', fDistance), aSeparator,
                                fTargetUnit.UID, aSeparator,
                                fTargetHouse.UID, aSeparator,
                                GetEnumName(TypeInfo(TKMTerrainPassability), Integer(fPass)), aSeparator,
                                BoolToStr(fDoesWalking, True), aSeparator,
                                BoolToStr(fWaitingOnStep, True), aSeparator,
                                BoolToStr(fDestBlocked, True), aSeparator,
                                BoolToStr(fDoExchange, True), aSeparator,
                                fInteractionCount, aSeparator,
                                fLastSideStepNodePos, aSeparator,
                                GetEnumName(TypeInfo(TKMInteractionStatus), Integer(fInteractionStatus))]);
end;


end.
