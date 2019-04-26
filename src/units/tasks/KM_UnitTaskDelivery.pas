unit KM_UnitTaskDelivery;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils,
  KM_CommonClasses, KM_Defaults, KM_Points,
  KM_Houses, KM_Units, KM_ResWares;


type
  TKMDeliverKind = (dkToHouse, dkToConstruction, dkToUnit);
  TKMDeliverStage = (dsUnknown,
                     dsToFromHouse,     //Serf is walking to the offer house
                     dsAtFromHouse,     //Serf is getting in / out from offer house
                     dsToDestination,   //Serf is walking to destination (unit/house)
                     dsAtDestination);  //Serf is operating with destination

  TKMTaskDeliver = class(TKMUnitTask)
  private
    fFrom: TKMHouse;
    fToHouse: TKMHouse;
    fToUnit: TKMUnit;
    fWareType: TKMWareType;
    fDeliverID: Integer;
    fDeliverKind: TKMDeliverKind;
    //Force delivery, even if fToHouse blocked ware from delivery.
    //Used in exceptional situation, when ware was carried by serf and delivery demand was destroyed and no one new was found
    fForceDelivery: Boolean;
    fPointBelowToHouse: TKMPoint; //Have to save that point separately, in case ToHouse will be destroyed
    fPointBelowFromHouse: TKMPoint; //Have to save that point separately, in case FromHouse will be destroyed
    procedure CheckForBetterDestination;
    function FindBestDestination: Boolean;
    function GetDeliverStage: TKMDeliverStage;
    procedure SetToHouse(aToHouse: TKMHouse);
    procedure SetFromHouse(aFromHouse: TKMHouse);
    property FromHouse: TKMHouse read fFrom write SetFromHouse;
    property ToHouse: TKMHouse read fToHouse write SetToHouse;
  public
    constructor Create(aSerf: TKMUnitSerf; aFrom: TKMHouse; aToHouse: TKMHouse; Res: TKMWareType; aID: Integer); overload;
    constructor Create(aSerf: TKMUnitSerf; aFrom: TKMHouse; aToUnit: TKMUnit; Res: TKMWareType; aID: Integer); overload;
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure SyncLoad; override;
    destructor Destroy; override;
    function WalkShouldAbandon: Boolean; override;
    property DeliverKind: TKMDeliverKind read fDeliverKind;
    property DeliverStage: TKMDeliverStage read GetDeliverStage;
    procedure DelegateToOtherSerf(aToSerf: TKMUnitSerf);
    function Execute: TKMTaskResult; override;
    function CouldBeCancelled: Boolean; override;
    procedure Save(SaveStream: TKMemoryStream); override;
  end;


implementation
uses
  Math,
  KM_HandsCollection, KM_Hand, KM_ResHouses,
  KM_Terrain, KM_UnitWarrior, KM_HouseBarracks, KM_HouseTownHall, KM_HouseInn,
  KM_UnitTaskBuild, KM_Log;


{ TTaskDeliver }
constructor TKMTaskDeliver.Create(aSerf: TKMUnitSerf; aFrom: TKMHouse; aToHouse: TKMHouse; Res: TKMWareType; aID: Integer);
begin
  inherited Create(aSerf);
  fType := uttDeliver;

  Assert((aFrom <> nil) and (aToHouse <> nil) and (Res <> wtNone), 'Serf ' + IntToStr(fUnit.UID) + ': invalid delivery task');

  gLog.LogDelivery('Serf ' + IntToStr(fUnit.UID) + ' created delivery task ' + IntToStr(fDeliverID));

  FromHouse := aFrom.GetHousePointer; //Also will set fPointBelowFromHouse
  ToHouse := aToHouse.GetHousePointer; //Also will set fPointBelowToHouse
  //Check it once to begin with as the house could become complete before the task exits (in rare circumstances when the task
  // does not exit until long after the ware has been delivered due to walk interactions)
  if aToHouse.IsComplete then
    fDeliverKind := dkToHouse
  else
    fDeliverKind := dkToConstruction;

  fWareType   := Res;
  fDeliverID  := aID;
end;


constructor TKMTaskDeliver.Create(aSerf: TKMUnitSerf; aFrom: TKMHouse; aToUnit: TKMUnit; Res: TKMWareType; aID: Integer);
begin
  inherited Create(aSerf);
  fType := uttDeliver;

  Assert((aFrom <> nil) and (aToUnit <> nil) and ((aToUnit is TKMUnitWarrior) or (aToUnit is TKMUnitWorker)) and (Res <> wtNone), 'Serf '+inttostr(fUnit.UID)+': invalid delivery task');
  gLog.LogDelivery('Serf ' + IntToStr(fUnit.UID) + ' created delivery task ' + IntToStr(fDeliverID));

  fFrom    := aFrom.GetHousePointer;
  fToUnit  := aToUnit.GetUnitPointer;
  fDeliverKind := dkToUnit;
  fWareType := Res;
  fDeliverID := aID;
  fPointBelowToHouse := KMPOINT_INVALID_TILE;
  fPointBelowFromHouse := KMPOINT_INVALID_TILE;
end;


constructor TKMTaskDeliver.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.Read(fFrom, 4);
  LoadStream.Read(fToHouse, 4);
  LoadStream.Read(fToUnit, 4);
  LoadStream.Read(fForceDelivery);
  LoadStream.Read(fPointBelowToHouse);
  LoadStream.Read(fPointBelowFromHouse);
  LoadStream.Read(fWareType, SizeOf(fWareType));
  LoadStream.Read(fDeliverID);
  LoadStream.Read(fDeliverKind, SizeOf(fDeliverKind));
end;



procedure TKMTaskDeliver.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  if fFrom <> nil then
    SaveStream.Write(fFrom.UID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Integer(0));
  if fToHouse <> nil then
    SaveStream.Write(fToHouse.UID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Integer(0));
  if fToUnit <> nil then
    SaveStream.Write(fToUnit.UID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Integer(0));
  SaveStream.Write(fForceDelivery);
  SaveStream.Write(fPointBelowToHouse);
  SaveStream.Write(fPointBelowFromHouse);
  SaveStream.Write(fWareType, SizeOf(fWareType));
  SaveStream.Write(fDeliverID);
  SaveStream.Write(fDeliverKind, SizeOf(fDeliverKind));
end;


procedure TKMTaskDeliver.SyncLoad;
begin
  inherited;
  fFrom    := gHands.GetHouseByUID(Cardinal(fFrom));
  fToHouse := gHands.GetHouseByUID(Cardinal(fToHouse));
  fToUnit  := gHands.GetUnitByUID(Cardinal(fToUnit));
end;


destructor TKMTaskDeliver.Destroy;
begin
  gLog.LogDelivery('Serf ' + IntToStr(fUnit.UID) + ' abandoned delivery task ' + IntToStr(fDeliverID) + ' at phase ' + IntToStr(fPhase));

  if fUnit <> nil then
  begin
    if fDeliverID <> 0 then
      gHands[fUnit.Owner].Deliveries.Queue.AbandonDelivery(fDeliverID);

    if TKMUnitSerf(fUnit).Carry <> wtNone then
    begin
      gHands[fUnit.Owner].Stats.WareConsumed(TKMUnitSerf(fUnit).Carry);
      TKMUnitSerf(fUnit).CarryTake; //empty hands
    end;
  end;

  gHands.CleanUpHousePointer(fFrom);
  gHands.CleanUpHousePointer(fToHouse);
  gHands.CleanUpUnitPointer(fToUnit);
  inherited;
end;


//Note: Phase is -1 because it will have been increased at the end of last Execute
function TKMTaskDeliver.WalkShouldAbandon: Boolean;
begin
  Result := False;

  if fPhase2 <> 0 then //we are at 'go to road' stage, no need to cancel that action
    Exit;

  //After step 2 we don't care if From is destroyed or doesn't have the ware
  if fPhase <= 2 then
    Result := Result or fFrom.IsDestroyed or (not fFrom.ResOutputAvailable(fWareType, 1) {and (fPhase < 5)});

  //do not abandon the delivery if target is destroyed/dead, we will find new target later
  case fDeliverKind of
    dkToHouse:         if fPhase <= 8 then
                        begin
                          Result := Result or fToHouse.IsDestroyed
                                   or (not fForceDelivery and fToHouse.ShouldAbandonDelivery(fWareType));
                        end;
    dkToConstruction:  if fPhase <= 7 then
                          Result := Result or fToHouse.IsDestroyed;
    dkToUnit:          if fPhase <= 6 then
                          Result := Result or (fToUnit = nil) or fToUnit.IsDeadOrDying;
  end;
end;


procedure TKMTaskDeliver.CheckForBetterDestination;
var
  NewToHouse: TKMHouse;
  NewToUnit: TKMUnit;
begin
  gHands[fUnit.Owner].Deliveries.Queue.CheckForBetterDemand(fDeliverID, NewToHouse, NewToUnit, TKMUnitSerf(fUnit));

  gHands.CleanUpHousePointer(fToHouse);
  gHands.CleanUpUnitPointer(fToUnit);
  if NewToHouse <> nil then
  begin
    fToHouse := NewToHouse.GetHousePointer;
    if fToHouse.IsComplete then
      fDeliverKind := dkToHouse
    else
      fDeliverKind := dkToConstruction;
  end
  else
  begin
    fToUnit := NewToUnit.GetUnitPointer;
    fDeliverKind := dkToUnit;
  end;
end;


// Try to find best destination
function TKMTaskDeliver.FindBestDestination: Boolean;
var
  NewToHouse: TKMHouse;
  NewToUnit: TKMUnit;
begin
  if fPhase <= 2 then
  begin
    Result := False;
    Exit;
  end else
  if InRange(fPhase, 3, 3) then
  begin
    Result := True;
    Exit;
  end;

  fForceDelivery := False; //Reset ForceDelivery from previous runs
  gHands[fUnit.Owner].Deliveries.Queue.DeliveryFindBestDemand(TKMUnitSerf(fUnit), fDeliverID, fWareType, NewToHouse, NewToUnit, fForceDelivery);

  gHands.CleanUpHousePointer(fToHouse);
  gHands.CleanUpUnitPointer(fToUnit);

  // New House
  if (NewToHouse <> nil) and (NewToUnit = nil) then
  begin
    fToHouse := NewToHouse.GetHousePointer;
    if fToHouse.IsComplete then
      fDeliverKind := dkToHouse
    else
      fDeliverKind := dkToConstruction;
    Result := True;
    if fPhase > 4 then
      fPhase := 4;
  end
  else
  // New Unit
  if (NewToHouse = nil) and (NewToUnit <> nil) then
  begin
    fToUnit := NewToUnit.GetUnitPointer;
    fDeliverKind := dkToUnit;
    Result := True;
    if fPhase > 4 then
      fPhase := 4;
  end
  else
  // No alternative
  if (NewToHouse = nil) and (NewToUnit = nil) then
    Result := False
  else
  // Error
    raise Exception.Create('Both destinations could not be');
end;


function TKMTaskDeliver.CouldBeCancelled: Boolean;
begin
  //Allow cancel task only at walking phases
  Result := ((fPhase - 1) //phase was increased at the end of execution
              <= 0)       //<= because fPhase is 0 when task is just created
            or ((fPhase - 1) = 5);
end;


procedure TKMTaskDeliver.SetToHouse(aToHouse: TKMHouse);
begin
  fToHouse := aToHouse;
  fPointBelowToHouse := fToHouse.PointBelowEntrance;
end;


procedure TKMTaskDeliver.SetFromHouse(aFromHouse: TKMHouse);
begin
  fFrom := aFromHouse;
  fPointBelowFromHouse := aFromHouse.PointBelowEntrance;
end;


//Get Delivery stage
function TKMTaskDeliver.GetDeliverStage: TKMDeliverStage;
var
  Phase: Integer;
begin
  Result := dsUnknown;
  Phase := fPhase - 1; //fPhase is increased at the phase end
  case Phase of
    -10..0,4: Result := dsToFromHouse;
    1..3:     Result := dsAtFromHouse;
    else
      case fDeliverKind of
        dkToHouse:         begin
                              case Phase of
                                5:    Result := dsToDestination;
                                else  Result := dsAtDestination;
                              end;
                            end;
        dkToConstruction,
        dkToUnit:          begin
                              case Phase of
                                5,6:  Result := dsToDestination;
                                else  Result := dsAtDestination;
                              end;
                            end;
      end;
  end;
end;


//Delegate delivery task to other serf
procedure TKMTaskDeliver.DelegateToOtherSerf(aToSerf: TKMUnitSerf);
begin
  //Allow to delegate task only while serf is walking to From House
  Assert(DeliverStage = dsToFromHouse, 'DeliverStage <> dsToFromHouse');

  gHands.CleanUpUnitPointer(fUnit);
  fUnit := aToSerf.GetUnitPointer;

  InitDefaultAction; //InitDefaultAction, otherwise serf will not have any action
end;


function TKMTaskDeliver.Execute: TKMTaskResult;

  function NeedGoToRoad: Boolean;
  var
    RoadConnectId: Byte;
  begin
    //Check if we already reach destination, no need to check anymore.
    //Also there is possibility when connected path (not diagonal) to house was cut and we have only diagonal path
    //then its possible, that fPointBelowToHouse COnnect Area will have only 1 tile, that means its WalkConnect will be 0
    if fUnit.CurrPosition = fPointBelowToHouse then
      Exit(False);
    RoadConnectId := gTerrain.GetRoadConnectID(fUnit.CurrPosition);
    Result := ((((fPhase - 1) = 5) and (fDeliverKind = dkToHouse))
                or (((fPhase - 1) in [5,6]) and (fDeliverKind = dkToConstruction)))
              and ((RoadConnectId = 0)
                or ((RoadConnectId <> gTerrain.GetRoadConnectID(fPointBelowToHouse))
                  and (RoadConnectId <> gTerrain.GetRoadConnectID(fPointBelowFromHouse))));
  end;

var
  Worker: TKMUnit;
  NeedWalkToRoad: Boolean;
begin
  Result := trTaskContinues;

  NeedWalkToRoad := NeedGoToRoad();

  if not NeedWalkToRoad then
    fPhase2 := 0;

  if WalkShouldAbandon and fUnit.Visible and not (NeedWalkToRoad or FindBestDestination) then
  begin
    Result := trTaskDone;
    Exit;
  end;

  if NeedWalkToRoad then
  begin
    case fPhase2 of
      0:  begin
            fUnit.SetActionStay(4, uaWalk);
            fUnit.Thought := thQuest;
          end;
      1:  begin
            fUnit.SetActionWalkToRoad(uaWalk, 0, tpWalkRoad,
                              [gTerrain.GetRoadConnectID(fPointBelowToHouse), gTerrain.GetRoadConnectID(fPointBelowFromHouse)]);
            fUnit.Thought := thNone;
            fPhase := 5;
          end;
    end;
    Inc(fPhase2);
    Exit;
  end;

  with TKMUnitSerf(fUnit) do
  case fPhase of
    0:  begin
          SetActionWalkToSpot(fFrom.PointBelowEntrance);
        end;
    1:  begin
          SetActionGoIn(uaWalk, gdGoInside, fFrom);
        end;
    2:  begin
          //Barracks can consume the resource (by equipping) before we arrive
          //All houses can have resources taken away by script at any moment
          if not fFrom.ResOutputAvailable(fWareType, 1) then
          begin
            SetActionGoIn(uaWalk, gdGoOutside, fFrom); //Step back out
            fPhase := 99; //Exit next run
            Exit;
          end;
          SetActionLockedStay(5,uaWalk); //Wait a moment inside
          fFrom.ResTakeFromOut(fWareType);
          CarryGive(fWareType);
          CheckForBetterDestination; //Must run before TakenOffer so Offer is still valid
          gHands[Owner].Deliveries.Queue.TakenOffer(fDeliverID);
        end;
    3:  begin
          if fFrom.IsDestroyed then //We have the resource, so we don't care if house is destroyed
            SetActionLockedStay(0, uaWalk)
          else
            SetActionGoIn(uaWalk, gdGoOutside, fFrom);
          Inc(fPhase); // jump to phase 5 immidiately
        end;
    4:  begin
          SetActionStay(5, uaWalk); //used only from FindBestDestination
          Thought := thQuest;
        end;
  end;

  if fPhase = 5 then
    TKMUnitSerf(fUnit).Thought := thNone; // Clear possible '?' thought after 4th phase

  //Deliver into complete house
  if (fDeliverKind = dkToHouse) then
  with TKMUnitSerf(fUnit) do
  case fPhase of
    0..4:;
    5:  SetActionWalkToSpot(fToHouse.PointBelowEntrance);
    6:  SetActionGoIn(uaWalk, gdGoInside, fToHouse);
    7:  SetActionLockedStay(5, uaWalk); //wait a bit inside
    8:  begin
          fToHouse.ResAddToIn(Carry);
          CarryTake;

          gHands[Owner].Deliveries.Queue.GaveDemand(fDeliverID);
          gHands[Owner].Deliveries.Queue.AbandonDelivery(fDeliverID);
          fDeliverID := 0; //So that it can't be abandoned if unit dies while trying to GoOut

          //If serf bring smth into the Inn and he is hungry - let him eat immidiately
          if fUnit.IsHungry
            and (fToHouse.HouseType = htInn)
            and TKMHouseInn(fToHouse).HasFood
            and TKMHouseInn(fToHouse).HasSpace
            and TKMUnitSerf(fUnit).GoEat(TKMHouseInn(fToHouse), True) then
            Exit //Exit immidiately, since we created new task here and old task is destroyed!
                 //Changing any task fields here (f.e. Phase) could affect new task!
          else
          //Now look for another delivery from inside this house
          //But only if we are not hungry!
          //Otherwise there is a possiblity when he will go between houses until death
          if not fUnit.IsHungry
            and TKMUnitSerf(fUnit).TryDeliverFrom(fToHouse) then
            Exit //Exit immidiately, since we created new task here and old task is destroyed!
                 //Changing any task fields here (f.e. Phase) could affect new task!
          else
            //No delivery found then just step outside
            SetActionGoIn(uaWalk, gdGoOutside, fToHouse);
        end;
    else Result := trTaskDone;
  end;

  //Deliver into wip house
  if (fDeliverKind = dkToConstruction) then
  with TKMUnitSerf(fUnit) do
  case fPhase of
    0..4:;
        // First come close to point below house entrance
    5:  SetActionWalkToSpot(fToHouse.PointBelowEntrance, uaWalk, 1.42);
    6:  begin
          // Then check if there is a worker hitting house just from the entrance
          Worker := gHands[fUnit.Owner].UnitsHitTest(fToHouse.PointBelowEntrance, utWorker);
          if (Worker <> nil) and (Worker.Task <> nil)
            and (Worker.Task is TKMTaskBuildHouse)
            and (Worker.Task.Phase >= 1) then
            // If so, then allow to bring resources diagonally
            SetActionWalkToSpot(fToHouse.Entrance, uaWalk, 1.42)
          else
            // else ask serf to bring resources from point below entrance (not diagonally)
            SetActionWalkToSpot(fToHouse.PointBelowEntrance);
        end;
    7:  begin
          Direction := KMGetDirection(CurrPosition, fToHouse.Entrance);
          fToHouse.ResAddToBuild(Carry);
          gHands[Owner].Stats.WareConsumed(Carry);
          CarryTake;
          gHands[Owner].Deliveries.Queue.GaveDemand(fDeliverID);
          gHands[Owner].Deliveries.Queue.AbandonDelivery(fDeliverID);
          fDeliverID := 0; //So that it can't be abandoned if unit dies while staying
          SetActionStay(1, uaWalk);
        end;
    else Result := trTaskDone;
  end;

  //Deliver to builder or soldier
  if fDeliverKind = dkToUnit then
  with TKMUnitSerf(fUnit) do
  case fPhase of
    0..4:;
    5:  SetActionWalkToUnit(fToUnit, 1.42, uaWalk); //When approaching from diagonal
    6:  begin
          //See if the unit has moved. If so we must try again
          if KMLengthDiag(fUnit.CurrPosition, fToUnit.CurrPosition) > 1.5 then
          begin
            SetActionWalkToUnit(fToUnit, 1.42, uaWalk); //Walk to unit again
            fPhase := 6;
            Exit;
          end;
          //Worker
          if (fToUnit.UnitType = utWorker) and (fToUnit.Task <> nil) then
          begin
            //ToDo: Replace phase numbers with enums to avoid hardcoded magic numbers
            // Check if worker is still digging
            if ((fToUnit.Task is TKMTaskBuildWine) and (fToUnit.Task.Phase < 5))
              or ((fToUnit.Task is TKMTaskBuildRoad) and (fToUnit.Task.Phase < 4)) then
            begin
              SetActionLockedStay(5, uaWalk); //wait until worker finish digging process
              fPhase := 6;
              Exit;
            end;
            fToUnit.Task.Phase := fToUnit.Task.Phase + 1;
            fToUnit.SetActionLockedStay(0, uaWork1); //Tell the worker to resume work by resetting his action (causes task to execute)
          end;
          //Warrior
          if (fToUnit is TKMUnitWarrior) then
          begin
            fToUnit.Feed(UNIT_MAX_CONDITION); //Feed the warrior
            TKMUnitWarrior(fToUnit).RequestedFood := False;
          end;
          gHands[Owner].Stats.WareConsumed(Carry);
          CarryTake;
          gHands[Owner].Deliveries.Queue.GaveDemand(fDeliverID);
          gHands[Owner].Deliveries.Queue.AbandonDelivery(fDeliverID);
          fDeliverID := 0; //So that it can't be abandoned if unit dies while staying
          SetActionLockedStay(5, uaWalk); //Pause breifly (like we are handing over the ware/food)
        end;
    7:  begin
          //After feeding troops, serf should walk away, but ToUnit could be dead by now
          if (fToUnit is TKMUnitWarrior) then
          begin
            if TKMUnitSerf(fUnit).TryDeliverFrom(nil) then
              Exit //Exit immidiately, since we created new task here and old task is destroyed!
                   //Changing any task fields (f.e. Phase) here could affect new task!
            else
              //No delivery found then just walk back to our From house
              //even if it's destroyed, its location is still valid
              //Don't walk to spot as it doesn't really matter
              SetActionWalkToHouse(fFrom, 5);
          end else
            SetActionStay(0, uaWalk); //If we're not feeding a warrior then ignore this step
        end;
    else Result := trTaskDone;
  end;

  Inc(fPhase);
end;


end.
