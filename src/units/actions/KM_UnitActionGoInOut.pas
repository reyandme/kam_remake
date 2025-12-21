unit KM_UnitActionGoInOut;
{$I KaM_Remake.inc}
interface
uses
  Classes, KromUtils, SysUtils,
  KM_CommonClasses, KM_CommonTypes, KM_Defaults, KM_Points,
  KM_Houses, KM_Units;


type
  TKMBestExit = (beNone, beLeft, beCenter, beRight);

  {This is a [fairly :P] simple action making unit go inside/outside of house}
  TKMUnitActionGoInOut = class(TKMUnitAction)
  private
    fStep: Single;
    fHouse: TKMHouse;
    fDirection: TKMGoInDirection;
    fDoor: TKMPoint;
    fStreet: TKMPoint;
    fInitiated: Boolean;
    fPushedUnit: TKMUnit;
    fWaitingForPush: Boolean;
    fUsedDoorway: Boolean;
    procedure IncDoorway;
    procedure DecDoorway;
    function FindBestExit(const aLoc: TKMPoint): TKMBestExit;
    function TileHasIdleUnitToPush(X,Y: Word): TKMUnit;
    function TileHasUnitOnHouseEntrance: Boolean;
    procedure WalkIn;
    procedure WalkOut;
    function GetIsStarted: Boolean;
  public
    OnWalkedOut: TKMEvent; //NOTE: Caller must sync these events after loading, used with caution
    OnWalkedIn: TKMEvent;
    constructor Create(aUnit: TKMUnit; aAction: TKMUnitActionType; aDirection: TKMGoInDirection; aHouse: TKMHouse);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure SyncLoad; override;
    destructor Destroy; override;
    function ActName: TKMUnitActionName; override;
    function CanBeInterrupted(aForced: Boolean = True): Boolean; override;
    function GetExplanation: UnicodeString; override;
    property IsStarted: Boolean read GetIsStarted; // Is unit actually started exiting or going inside?
    property Direction: TKMGoInDirection read fDirection;
    function GetDoorwaySlide(aCheck: TKMCheckAxis): Single;
    function GetDoorwaySlides: TKMPointF;
    function Execute: TKMActionResult; override;
    procedure Save(SaveStream: TKMemoryStream); override;
  end;


implementation
uses
  KM_Entity,
  KM_HandsCollection, KM_HandTypes, KM_HandEntity,
  KM_Resource, KM_Terrain, KM_UnitActionStay, KM_UnitActionWalkTo,
  KM_HouseBarracks, KM_ResHouses, KM_ResUnits, KM_CommonUtils, KM_GameParams,
  KM_ResTypes;


{ TKMUnitActionGoInOut }
constructor TKMUnitActionGoInOut.Create(aUnit: TKMUnit; aAction: TKMUnitActionType; aDirection: TKMGoInDirection; aHouse: TKMHouse);
begin
  inherited Create(aUnit, aAction, True);

  //We might stuck trying to exit when house gets destroyed (1)
  //and we might be dying in destroyed house (2)
  fHouse          := aHouse.GetPointer;
  fDirection      := aDirection;
  fInitiated      := False;
  fWaitingForPush := False;

  if fDirection = gdGoInside then
    fStep := 1  //go Inside (one cell up)
  else
    fStep := 0; //go Outside (one cell down)
end;


constructor TKMUnitActionGoInOut.Load(LoadStream: TKMemoryStream);
begin
  inherited;

  LoadStream.CheckMarker('UnitActionGoInOut');
  LoadStream.Read(fStep);
  LoadStream.Read(fHouse, 4);
  LoadStream.Read(fPushedUnit, 4);
  LoadStream.Read(fDirection, SizeOf(fDirection));
  LoadStream.Read(fDoor);
  LoadStream.Read(fStreet);
  LoadStream.Read(fInitiated);
  LoadStream.Read(fWaitingForPush);
  LoadStream.Read(fUsedDoorway);
end;


procedure TKMUnitActionGoInOut.SyncLoad;
begin
  inherited;

  fHouse := gHands.GetHouseByUID(Integer(fHouse));
  fPushedUnit := gHands.GetUnitByUID(Integer(fPushedUnit));
end;


destructor TKMUnitActionGoInOut.Destroy;
begin
  if fUsedDoorway then
    DecDoorway;

  gHands.CleanUpHousePointer(fHouse);
  gHands.CleanUpUnitPointer(fPushedUnit);


  if (fUnit <> nil)
    and fInitiated
    and (gTerrain.Land^[fUnit.PositionNext.Y, fUnit.PositionNext.X].IsUnit = fUnit) then
  begin
    case fDirection of
      //Clear terrain lock for house entrance that made while unit was entering the house
      gdGoInside:   gTerrain.UnitRem(fUnit.PositionNext);

      //A bug can occur because this action is destroyed early when a unit is told to die.
      //If we are still invisible then TTaskDie assumes we are inside and creates a new
      //GoOut action. Therefore if we are invisible we do not occupy a tile.
      gdGoOutside:  if not fUnit.Visible then
                    begin
                      gTerrain.UnitRem(fUnit.PositionNext);
                      if not KMSamePoint(fDoor, KMPOINT_ZERO) then
                        fUnit.PositionF := KMPointF(fDoor); //Put us back inside the house
                    end;
    end;
  end;

  if (fDirection = gdGoOutside) and fUnit.Visible then
    fUnit.InHouse := nil; //We are not in any house now

  inherited;
end;


function TKMUnitActionGoInOut.ActName: TKMUnitActionName;
begin
  Result := uanGoInOut;
end;


function TKMUnitActionGoInOut.GetExplanation: UnicodeString;
begin
  Result := 'Walking in/out';
end;


// Is unit actually started exiting or going inside?
function TKMUnitActionGoInOut.GetIsStarted: Boolean;
begin
  Result := fInitiated and not fWaitingForPush;
end;


procedure TKMUnitActionGoInOut.IncDoorway;
begin
  Assert(not fUsedDoorway, 'Inc doorway when already in use?');

  if fHouse <> nil then Inc(fHouse.DoorwayUse);
  fUsedDoorway := True;
end;


procedure TKMUnitActionGoInOut.DecDoorway;
begin
  Assert(fUsedDoorway, 'Dec doorway when not in use?');

  if fHouse<>nil then dec(fHouse.DoorwayUse);
  fUsedDoorway := False;
end;


//Attempt to find a tile below the door (on the street) we can walk to
//We can push idle units away. Check center first
function TKMUnitActionGoInOut.FindBestExit(const aLoc: TKMPoint): TKMBestExit;

  function ChooseBestExit(aL, aR: Boolean): TKMBestExit;
  begin
    //Choose randomly between left and right
    if (aL and aR) then
    begin
      if KaMRandom(2{$IFDEF DBG_RNG_SPY}, 'TKMUnitActionGoInOut.FindBestExit.ChooseBestExit'{$ENDIF}) = 0 then
        Result := beLeft
      else
        Result := beRight;
    end
    else
    if aL then
      Result := beLeft
    else
    if aR then
      Result := beRight
    else
      Result := beNone;
  end;

var
  U, UC, UL, UR: TKMUnit;
  L, R: Boolean;
begin
  if fUnit.CanStepTo(aLoc.X, aLoc.Y, tpWalk) then
    Result := beCenter
  else
  begin
    L := fUnit.CanStepTo(aLoc.X-1, aLoc.Y, tpWalk);
    R := fUnit.CanStepTo(aLoc.X+1, aLoc.Y, tpWalk);

    Result := ChooseBestExit(L, R);

    if Result = beNone then
    begin
      U := nil;
      UL := nil;
      UR := nil;
      //U could be nil if tile is unwalkable for some reason
      UC := TileHasIdleUnitToPush(aLoc.X, aLoc.Y);
      if UC <> nil then
        Result := beCenter
      else
      begin
        UL := TileHasIdleUnitToPush(aLoc.X-1, aLoc.Y);
        L := UL <> nil;
        UR := TileHasIdleUnitToPush(aLoc.X+1, aLoc.Y);
        R := UR <> nil;
        Result := ChooseBestExit(L, R);
      end;

      case Result of
        beCenter: U := UC;
        beLeft:   U := UL;
        beRight:  U := UR;
      end;

      if U <> nil then
      begin
        fPushedUnit := U.GetPointer;
        fPushedUnit.SetActionWalkPushed(gTerrain.GetOutOfTheWay(U, KMPOINT_ZERO, tpWalk));
      end;
    end;
  end;
end;


//Check that tile is walkable and there's no unit blocking it or that unit can be pushed away
function TKMUnitActionGoInOut.TileHasIdleUnitToPush(X,Y: Word): TKMUnit;
var
  U: TKMUnit;
begin
  Result := nil;

  if gTerrain.TileInMapCoords(X,Y)
    and (gTerrain.CheckPassability(KMPoint(X,Y), fUnit.DesiredPassability))
    and (gTerrain.CanWalkDiagonally(fUnit.Position, X, Y))
    and (gTerrain.Land^[Y,X].IsUnit <> nil) then //If there's some unit we need to do a better check on him
  begin
    U := gTerrain.UnitsHitTest(X,Y); //Let's see who is standing there

    //Check that the unit is idling and not an enemy, so that we can push it away
    if (U <> nil)
    and not U.IsAnimal // Can't push animals
    and (U.Action is TKMUnitActionStay)
    and not TKMUnitActionStay(U.Action).Locked
    and (gHands.CheckAlliance(U.Owner, fUnit.Owner) = atAlly) then
      Result := U;
  end;
end;


function TKMUnitActionGoInOut.TileHasUnitOnHouseEntrance: Boolean;
begin
  if fHouse.IsDestroyed then Exit(False);

  // There could be a unit walking in the house already,
  // f.e. if serf was added at point below entrance by script and he went straight into the same house
  Result := (gTerrain.Land^[fHouse.Entrance.Y, fHouse.Entrance.X].IsUnit <> nil);
end;


procedure TKMUnitActionGoInOut.WalkIn;
begin
  fUnit.Direction := dirN;  //one cell up
  fUnit.PositionNext := KMPointAbove(fUnit.Position);
  gTerrain.UnitRem(fUnit.Position); // Release tile at point below house entrance
  // Unit occupy a tile on a terrain while he is walking inside house
  // House could be destroyed while while unit was walking in it, so we need to have a tile occupied on terrain for that case
  // After house was destroyed other unit could go there / smth could be placed with as script,
  // but this unit is still walking into house so we have keep it consistent:
  // unit occupied tile if he is standing on that tile or he is going to get onto that tile
  gTerrain.UnitAdd(fUnit.PositionNext, fUnit);

  //We are walking straight
  if fStreet.X = fDoor.X then
    IncDoorway;
end;


//Start walking out of the house. unit is no longer in the house
procedure TKMUnitActionGoInOut.WalkOut;
begin
  fUnit.Direction := KMGetDirection(fDoor, fStreet);
  fUnit.PositionNext := fStreet;
  gTerrain.UnitAdd(fUnit.PositionNext, fUnit); //Unit was not occupying tile while inside

  //Use InHouse instead of Home, since Home could be cleared via ProceedHouseClosedForWorker (f.e. when wGoingForEating = True)
  if (fUnit.UnitType = utRecruit) //Recruit
  and(fUnit.InHouse <> nil) //In some house
  and (fUnit.InHouse.HouseType = htBarracks) //Recruit is in barracks
  and (fUnit.InHouse = fHouse) then //And is the house we are walking from
    TKMHouseBarracks(fHouse).RecruitsRemove(fUnit);

  //We are walking straight
  if fStreet.X = fDoor.X then
    IncDoorway;
end;


function TKMUnitActionGoInOut.GetDoorwaySlide(aCheck: TKMCheckAxis): Single;
var
  offset: Single;
begin
  if (fHouse = nil) or not fInitiated then
    Result := 0
  else
  begin
    offset := gRes.Houses[fHouse.HouseType].GetDoorwayOffset(aCheck);

    Result := Mix(0, offset, fStep);
  end;
end;


function TKMUnitActionGoInOut.GetDoorwaySlides: TKMPointF;
begin
  if (fHouse = nil) or not fInitiated then
    Result := KMPointF(0, 0)
  else
  begin
    Result.X := Mix(0, gRes.Houses[fHouse.HouseType].GetDoorwayOffset(axX), fStep);
    Result.Y := Mix(0, gRes.Houses[fHouse.HouseType].GetDoorwayOffset(axY), fStep);
  end;
end;


function TKMUnitActionGoInOut.Execute: TKMActionResult;
var
  U: TKMUnit;
  distance: Single;
begin
  Result := arActContinues;

  if not fInitiated then
  begin
    //Set Door and Street locations
    fDoor := KMPoint(fUnit.Position.X, fUnit.Position.Y - Round(fStep));
    fStreet := KMPoint(fUnit.Position.X, fUnit.Position.Y + 1 - Round(fStep));

    case fDirection of
      gdGoInside:   // House could be destroyed on the same tick Action was created
                    // So we can't do the check before this very moment

                    // Do not allow to enter already destroyed houses
                    // Since we did not occupy entrance tile other units inside house could do that already
                    if fHouse.IsDestroyed then
                      Exit(arActCanNotStart)
                    else
                    // There could be a unit walking in the house already,
                    // f.e. if serf was added at point below entrance by script and he went straight into the same house
                    if TileHasUnitOnHouseEntrance then
                      Exit
                    else
                      WalkIn;
      gdGoOutside:  begin
                      case FindBestExit(fStreet) of
                        beLeft:    fStreet.X := fStreet.X - 1;
                        beCenter:  ;
                        beRight:   fStreet.X := fStreet.X + 1;
                        beNone:    Exit; //All street tiles are blocked by busy units. Do not exit the house, just wait
                      end;

                      //If we have pushed an idling unit, wait till it goes away
                      //Wait until our push request is dealt with before we move out
                      if (fPushedUnit <> nil) then
                      begin
                        fWaitingForPush := True;
                        fInitiated := True;
                        Exit;
                      end
                      else
                        WalkOut; //Otherwise we can walk out now
                    end;
    end;

    fInitiated := True;
  end;


  if fWaitingForPush then
  begin
    U := gTerrain.Land^[fStreet.Y,fStreet.X].IsUnit;
    if (U = nil) then //Unit has walked away
    begin
      fWaitingForPush := False;
      gHands.CleanUpUnitPointer(fPushedUnit);
      WalkOut;
    end
    else
    begin //There's still some unit - we can't go outside
      if (U <> fPushedUnit) //The unit has switched places with another one, so we must start again
        or not (U.Action is TKMUnitActionWalkTo) //Unit was interupted (no longer pushed), so start again
        or not TKMUnitActionWalkTo(U.Action).WasPushed then
      begin
        fInitiated := False;
        fWaitingForPush := False;
        gHands.CleanUpUnitPointer(fPushedUnit);
      end;
      Exit;
    end;
  end;

  //IsExchanging can be updated while we have completed less than 20% of the move. If it is changed after that
  //the unit makes a noticable "jump". This needs to be updated after starting because we don't know about an
  //exchanging unit until they have also started walking (otherwise only 1 of the units will have IsExchanging = True)
  if (
      ((fDirection = gdGoOutside) and (fStep < 0.2)) or
      ((fDirection = gdGoInside) and (fStep > 0.8))
      )
    and (fStreet.X = fDoor.X) //We are walking straight
    and (fHouse <> nil) then
    fUnit.IsExchanging := (fHouse.DoorwayUse > 1);

  Assert((fHouse = nil) or KMSamePoint(fDoor, fHouse.Entrance)); //Must always go in/out the entrance of the house

  //Actual speed is slower if we are moving diagonally, due to the fact we are moving in X and Y
  distance := gRes.Units[fUnit.UnitType].GetEffectiveWalkSpeed(fStreet.X - fDoor.X <> 0);

  fStep := fStep - distance * ShortInt(fDirection);
  fUnit.PositionF := KMLerp(fDoor, fStreet, fStep);
  fUnit.Visible := (fHouse = nil) or (fHouse.IsDestroyed) or (fStep > 0); //Make unit invisible when it's inside of House

  if (fStep <= 0) or (fStep >= 1) then
  begin
    Result := arActDone;
    fUnit.IsExchanging := False;
    if fUsedDoorway then DecDoorway;
    if fDirection = gdGoInside then
    begin
      fUnit.PositionF := KMPointF(fDoor);
      if (fUnit.Home <> nil)
      and (fUnit.Home = fHouse)
      and (fUnit.Home.HouseType = htBarracks) //Unit home is barracks
      and not fUnit.Home.IsDestroyed then //And is the house we are walking into and it's not destroyed
        TKMHouseBarracks(fUnit.Home).RecruitsAdd(fUnit); //Add the recruit once it is inside, otherwise it can be equipped while still walking in!
      //Set us as inside even if the house is destroyed. In that case UpdateVisibility will sort things out.

      //When any woodcutter returns home - add an Axe
      //(this might happen when he walks home or when mining is done)
      if (fUnit.UnitType = utWoodcutter)
      and (fUnit.Home <> nil)
      and (fUnit.Home.HouseType = htWoodcutters)
      and (fUnit.Home = fHouse) then //And is the house we are walking from
        fHouse.CurrentAction.SubActionAdd([haFlagpole]);

      if Assigned(OnWalkedIn) then
        OnWalkedIn;

      if fHouse <> nil then
        fUnit.InHouse := fHouse;

      // Release tile, occupied under the house entrance
      // Unit occupied tile, when he was walking inside house, because he could interact with terrain
      // if house was destroyed while he was during walk-in process
      // But when unit entered house he is not on terrain anymore, but is somewhere in the house and he can't interact with terrain
      // Do not remove tile occupation if house was destroyed while unit was walking in it
      // we want to keep this place for exact this unit, so he will be not teleported to some other loc under the house
      // (do not allow other units inside house to get this place occasionaly on house destruction in FindPlaceForUnit method)
      if (fHouse <> nil) and not fHouse.IsDestroyed then
        gTerrain.UnitRem(fUnit.Position);
    end
    else
    begin
      fUnit.PositionF := KMPointF(fStreet);
      fUnit.InHouse := nil; //We are not in a house any longer
      if Assigned(OnWalkedOut) then
        OnWalkedOut;
    end;
  end
  else
    Inc(fUnit.AnimStep);
end;


procedure TKMUnitActionGoInOut.Save(SaveStream: TKMemoryStream);
begin
  inherited;

  SaveStream.PlaceMarker('UnitActionGoInOut');
  SaveStream.Write(fStep);
  SaveStream.Write(fHouse.UID); //Store ID, then substitute it with reference on SyncLoad
  SaveStream.Write(fPushedUnit.UID); //Store ID, then substitute it with reference on SyncLoad
  SaveStream.Write(fDirection, SizeOf(fDirection));
  SaveStream.Write(fDoor);
  SaveStream.Write(fStreet);
  SaveStream.Write(fInitiated);
  SaveStream.Write(fWaitingForPush);
  SaveStream.Write(fUsedDoorway);
end;


function TKMUnitActionGoInOut.CanBeInterrupted(aForced: Boolean = True): Boolean;
begin
  Result := not Locked; //Never interupt leaving barracks
end;


end.

