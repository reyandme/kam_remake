unit KM_UnitActionAbandonWalk;
{$I KaM_Remake.inc}
interface
uses
  KM_CommonClasses, KM_Defaults, KM_Units, KM_Points;


// Abandon the current walk, move onto next tile
type
  TKMUnitActionAbandonWalk = class(TKMUnitAction)
  private
    fWalkTo: TKMPoint;
    fVertexOccupied: TKMPoint;
  public
    constructor Create(aUnit: TKMUnit; const LocB, aVertexOccupied: TKMPoint; aActionType: TKMUnitActionType);
    constructor Load(LoadStream: TKMemoryStream); override;
    destructor Destroy; override;
    function ActName: TKMUnitActionName; override;
    function CanBeInterrupted(aForced: Boolean = True): Boolean; override;
    function GetExplanation: UnicodeString; override;
    function Execute: TKMActionResult; override;
    procedure Save(SaveStream: TKMemoryStream); override;
  end;


implementation
uses
  Math,
  KM_Resource, KM_ResUnits;


{ TKMUnitActionAbandonWalk }
constructor TKMUnitActionAbandonWalk.Create(aUnit: TKMUnit; const LocB, aVertexOccupied: TKMPoint; aActionType: TKMUnitActionType);
begin
  Assert(LocB.X*LocB.Y <> 0, 'Illegal WalkTo 0:0');
  inherited Create(aUnit, aActionType, False);

  fWalkTo         := LocB;
  fVertexOccupied := aVertexOccupied;
end;


destructor TKMUnitActionAbandonWalk.Destroy;
begin
  if (fUnit <> nil) and not KMSamePoint(fVertexOccupied, KMPOINT_ZERO) then
  begin
    fUnit.VertexRem(fVertexOccupied); //Unoccupy vertex
    fVertexOccupied := KMPOINT_ZERO;
  end;

  inherited;
end;


constructor TKMUnitActionAbandonWalk.Load(LoadStream: TKMemoryStream);
begin
  inherited;

  LoadStream.CheckMarker('UnitActionAbandonWalk');
  LoadStream.Read(fWalkTo);
  LoadStream.Read(fVertexOccupied);
end;


function TKMUnitActionAbandonWalk.ActName: TKMUnitActionName;
begin
  Result := uanAbandonWalk;
end;


function TKMUnitActionAbandonWalk.GetExplanation: UnicodeString;
begin
  Result := 'Abandoning walk';
end;


function TKMUnitActionAbandonWalk.Execute: TKMActionResult;
var
  dx, dy: ShortInt;
  walkX, walkY, distance: Single;
begin
  Result := arActContinues;

  //Execute the route in series of moves
  // Use umtWalk move type here, since we just want to evaluate if we are close enough
  distance := gRes.Units[fUnit.UnitType].GetEffectiveWalkSpeed(False);

  //Check if unit has arrived on tile
  if KMSamePointF(fUnit.PositionF, KMPointF(fWalkTo), distance/2) then
  begin
    fUnit.PositionF := KMPointF(fWalkTo); //Set precise position to avoid rounding errors
    fUnit.IsExchanging := False; //Disable sliding (in case it was set in previous step)
    if not KMSamePoint(fVertexOccupied, KMPOINT_ZERO) then
    begin
      fUnit.VertexRem(fVertexOccupied); //Unoccupy vertex
      fVertexOccupied := KMPOINT_ZERO;
    end;
    StepDone := True;
    Exit(arActDone);
  end;

  walkX := fWalkTo.X - fUnit.PositionF.X;
  walkY := fWalkTo.Y - fUnit.PositionF.Y;
  dx := sign(walkX); //-1,0,1
  dy := sign(walkY); //-1,0,1

  distance := gRes.Units[fUnit.UnitType].GetEffectiveWalkSpeed((dx <> 0) and (dy <> 0));

  fUnit.PositionF := KMPointF(fUnit.PositionF.X + dx*Math.min(distance,abs(walkX)),
                              fUnit.PositionF.Y + dy*Math.min(distance,abs(walkY)));
  Inc(fUnit.AnimStep);
end;


procedure TKMUnitActionAbandonWalk.Save(SaveStream: TKMemoryStream);
begin
  inherited;

  SaveStream.PlaceMarker('UnitActionAbandonWalk');
  SaveStream.Write(fWalkTo);
  SaveStream.Write(fVertexOccupied);
end;


function TKMUnitActionAbandonWalk.CanBeInterrupted(aForced: Boolean = True): Boolean;
begin
  Result := StepDone and not Locked; //Abandon walk should never be abandoned, it will exit within 1 step anyway
end;


end.
