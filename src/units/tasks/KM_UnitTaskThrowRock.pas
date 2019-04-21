unit KM_UnitTaskThrowRock;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils,
  KM_CommonClasses, KM_Defaults, KM_Units;


{Throw a rock}
type
  TKMTaskThrowRock = class(TKMUnitTask)
  private
    fTarget: TKMUnit;
    fFlightTime: Word; //Thats how long it will take a stone to hit it's target
  public
    constructor Create(aUnit, aTarget: TKMUnit);
    destructor Destroy; override;
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure SyncLoad; override;
    function Execute: TKMTaskResult; override;
    procedure Save(SaveStream: TKMemoryStream); override;
  end;


implementation
uses
  KM_HandsCollection, KM_Projectiles, KM_ResWares, KM_Hand;


{ TTaskThrowRock }
constructor TKMTaskThrowRock.Create(aUnit, aTarget: TKMUnit);
begin
  inherited Create(aUnit);
  fType := uttThrowRock;
  fTarget := aTarget.GetUnitPointer;
end;


destructor TKMTaskThrowRock.Destroy;
begin
  if (fUnit <> nil)
    and not fUnit.Home.IsDestroyed
    and (fUnit.Home.GetState = hstWork) then
    fUnit.Home.SetState(hstIdle); //Make sure we don't abandon and leave our tower with "working" animations

  gHands.CleanUpUnitPointer(fTarget);
  inherited;
end;


constructor TKMTaskThrowRock.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.Read(fTarget, 4);
  LoadStream.Read(fFlightTime);
end;


procedure TKMTaskThrowRock.SyncLoad;
begin
  inherited;
  fTarget := gHands.GetUnitByUID(cardinal(fTarget));
end;


function TKMTaskThrowRock.Execute: TKMTaskResult;
begin
  Result := trTaskContinues;

  //Target could have been killed by another Tower or in a fight
  if fUnit.Home.IsDestroyed or ((fTarget<>nil) and fTarget.IsDeadOrDying) then
  begin
    Result := trTaskDone;
    Exit;
  end;

  with fUnit do
  case fPhase of
    0:  begin
          Home.SetState(hstWork); //Set house to Work state
          Home.CurrentAction.SubActionWork(haWork2); //show Recruits back
          SetActionStay(2, uaWalk); //pretend to be taking the stone
        end;
    1:  begin
          Home.ResTakeFromIn(wtStone, 1);
          gHands[Owner].Stats.WareConsumed(wtStone);
          fFlightTime := gProjectiles.AimTarget(PositionF, fTarget, ptTowerRock, fUnit, RANGE_WATCHTOWER_MAX, RANGE_WATCHTOWER_MIN);
          gHands.CleanUpUnitPointer(fTarget); //We don't need it anymore
          SetActionLockedStay(1, uaWalk);
        end;
    2:  SetActionLockedStay(fFlightTime, uaWalk); //Pretend to look how it goes
    3:  begin
          Home.SetState(hstIdle);
          SetActionStay(20, uaWalk); //Idle before throwing another rock
        end;
    else Result := trTaskDone;
  end;
  Inc(fPhase);
end;


procedure TKMTaskThrowRock.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  if fTarget <> nil then
    SaveStream.Write(fTarget.UID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Integer(0));
  SaveStream.Write(fFlightTime);
end;



end.
