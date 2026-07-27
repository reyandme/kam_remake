unit KM_UnitTaskDismiss;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils,
  KM_Defaults, KM_Units, KM_Houses, KM_CommonClasses;


type
  TKMTaskDismiss = class(TKMUnitTask)
  private
    fSchool: TKMHouse;
    procedure WalkToSchool;
  protected
    procedure InitDefaultAction; override;
  public
    constructor Create(aUnit: TKMUnit);
    constructor Load(LoadStream: TKMemoryStream); override;
    destructor Destroy; override;
    procedure SyncLoad; override;
    procedure Save(SaveStream: TKMemoryStream); override;
    function ShouldBeCancelled: Boolean;
    function CouldBeCancelled: Boolean; override;

    property School: TKMHouse read fSchool;
    function FindNewSchool: TKMHouse;

    function Execute: TKMTaskResult; override;
  end;


implementation
uses
  KM_Entity, KM_Points,
  KM_HandsCollection, KM_Hand, KM_HandTypes, KM_HandEntity,
  KM_ResTypes, KM_ScriptingEvents;


{ TTaskDismiss }
constructor TKMTaskDismiss.Create(aUnit: TKMUnit);
begin
  Assert(aUnit is TKMCivilUnit, 'Only civil units are allowed to be dismissed');
  inherited;

  gHands[fUnit.Owner].Stats.UnitDismissed(fUnit.UnitType);

  fType := uttDismiss;
  FindNewSchool;
end;


constructor TKMTaskDismiss.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.CheckMarker('TaskDismiss');
  LoadStream.Read(fSchool, 4);
end;


destructor TKMTaskDismiss.Destroy;
begin
  gHands.CleanUpHousePointer(fSchool);
  fUnit.DismissInProgress := False; //Reset dismissInProgress Flag to show proper UI
  gHands[fUnit.Owner].Stats.UnitDismissCanceled(fUnit.UnitType);

  inherited;
end;


function TKMTaskDismiss.ShouldBeCancelled: Boolean;
begin
  Result := (fSchool = nil) or fSchool.IsDestroyed;
end;


function TKMTaskDismiss.CouldBeCancelled: Boolean;
begin
  //Phases 1 (walking out of the house) and 3 (walking into the school) use a locked GoInOut
  //action that can not be interrupted - DismissCancel would just ignore the request then.
  //Only phase 0 (not started yet) and phase 2 (walking to the school point) can actually be cancelled
  Result := (fPhase = 0) or (fPhase = 2);
end;


procedure TKMTaskDismiss.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  SaveStream.PlaceMarker('TaskDismiss');
  if fSchool <> nil then
    SaveStream.Write(fSchool.UID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Integer(0));
end;


procedure TKMTaskDismiss.SyncLoad;
begin
  inherited;
  fSchool := gHands[fUnit.Owner].Houses.GetHouseByUID(Integer(fSchool));
end;


function TKMTaskDismiss.FindNewSchool: TKMHouse;
var
  S: TKMHouse;
  loc: TKMPoint;
begin
  fSchool := nil;

  loc := fUnit.Position;
  //Unit inside a house stands on its entrance tile, which is not walkable, hence no route could
  //ever be made from there. Position stays on that tile for the whole walk out of the house (only
  //Visible flips early, mid-walk), so key this on InHouse alone, same as TKMHand.FindInn does.
  //Search from the tile below the door then
  if fUnit.InHouse <> nil then
    Inc(loc.Y); //From outside the door of the house

  S := gHands[fUnit.Owner].FindHouse(htSchool, loc);

  if (S <> nil) and fUnit.CanWalkTo(loc, S.PointBelowEntrance, tpWalk, 0) then
    fSchool := S.GetPointer;

  Result := fSchool;
end;


procedure TKMTaskDismiss.InitDefaultAction;
begin
  //Do nothing here, as we have to continue old action, until it could be interrupted
end;


procedure TKMTaskDismiss.WalkToSchool;
begin
  fUnit.SetActionWalkToSpot(fSchool.PointBelowEntrance, uaWalk, 0, fUnit.AnimStep); // Preserv current AnimStep
end;


function TKMTaskDismiss.Execute: TKMTaskResult;
begin
  Result := trTaskContinues;

  if (fSchool = nil) or fSchool.IsDestroyed then
  begin
    Result := trTaskDone;
    Exit;
  end;

  with fUnit do
    case fPhase of
      0:  if not Visible and (InHouse <> nil) and not InHouse.IsDestroyed then
          begin
            //Unit could be dismissed while he is inside a house (f.e. a recruit sitting in the barracks,
            //or a citizen resting at his workplace) - he has to step outside first,
            //otherwise he would walk to the school while occupying no terrain tile at all
            if InHouse = Home then
              Home.SetState(hstEmpty); //He is not coming back, do not leave the house with the idle animation on
            SetActionGoIn(uaWalk, gdGoOutside, InHouse); //Walk outside the house
          end
          else
          begin
            //Unit is outside already, so skip the walking out phase right away.
            //Skipping it with a SetActionLockedStay would reset AnimStep and make the unit
            //stand still for a tick, while he could be walking already
            Inc(fPhase);
            WalkToSchool;
          end;
      1:  WalkToSchool;
      2:  SetActionGoIn(uaWalk, gdGoInside, fSchool);
      3:  begin
            //Note: we do not set trTaskDone here, as we are going to destroy this task and Close (delete) unit
            //Setting to trTaskDone will force Unit.UpadateState to find new task/action for this unit
            if gMySpectator.Selected = fUnit then
              gMySpectator.Selected := nil; //Reset view, in case we were watching dismissed unit

            gHands[fUnit.Owner].Stats.UnitLost(fUnit.UnitType);
            gHands[fUnit.Owner].Stats.CitizenRetired(fUnit.UnitType);

            gScriptEvents.ProcUnitDismissed(fUnit);

            TKMCivilUnit(fUnit).KillInHouse; //Kill unit silently inside house
            Exit; //Exit immediately, since we destroyed current task!
                  //Changing any task fields here (f.e. Phase) will try to change freed memory!
          end;
      else Result := trTaskDone;
    end;

  Inc(fPhase);
end;


end.

