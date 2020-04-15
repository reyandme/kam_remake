unit KM_UnitTaskGoOutShowHungry;
{$I KaM_Remake.inc}
interface
uses
  Classes, KM_Defaults, KM_Units, SysUtils;

type
  TKMTaskGoOutShowHungry = class(TKMUnitTask)
  public
    constructor Create(aUnit:TKMUnit);
    function Execute:TKMTaskResult; override;
  end;


implementation
uses
  KM_CommonUtils;


{ TTaskGoOutShowHungry }
constructor TKMTaskGoOutShowHungry.Create(aUnit:TKMUnit);
begin
  inherited Create(aUnit);
  fType := uttGoOutShowHungry;
end;


function TKMTaskGoOutShowHungry.Execute: TKMTaskResult;
begin
  Result := trTaskContinues;
  if fUnit.Home.IsDestroyed then
  begin
    Result := trTaskDone;
    Exit;
  end;

  with fUnit do
  case fPhase of
    0: begin
         Thought := thEat;
         SetActionStay(20,uaWalk);
       end;
    1: begin
         SetActionGoIn(uaWalk,gdGoOutside,fUnit.Home);
         Home.SetState(hstEmpty);
       end;
    2: SetActionLockedStay(4,uaWalk);
    3: SetActionWalkToSpot(fUnit.Home.PointBelowEntrance);
    4: SetActionGoIn(uaWalk,gdGoInside,fUnit.Home);
    5: begin
         SetActionStay(20+KaMRandom(10, 'TKMTaskGoOutShowHungry.Execute'), uaWalk);
         Home.SetState(hstIdle);
       end;
    else begin
         Thought := thNone;
         Result := trTaskDone;
       end;
  end;
  inc(fPhase);
end;


end.
