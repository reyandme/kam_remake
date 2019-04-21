unit KM_UnitActionAbandonWalk;
{$I KaM_Remake.inc}
interface
uses
  Math,
  KM_CommonClasses, KM_Defaults, KM_Units, KM_Points;


{Abandon the current walk, move onto next tile}
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
  KM_Resource, KM_ResUnits;


{ TUnitActionAbandonWalk }
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
  DX, DY: ShortInt;
  WalkX, WalkY, Distance: Single;
begin
  Result := arActContinues;

  //Execute the route in series of moves
  Distance := gRes.Units[fUnit.UnitType].Speed;

  //Check if unit has arrived on tile
  if KMSamePointF(fUnit.PositionF, KMPointF(fWalkTo), Distance/2) then
  begin
    fUnit.PositionF := KMPointF(fWalkTo); //Set precise position to avoid rounding errors
    fUnit.IsExchanging := False; //Disable sliding (in case it was set in previous step)
    if not KMSamePoint(fVertexOccupied, KMPOINT_ZERO) then
    begin
      fUnit.VertexRem(fVertexOccupied); //Unoccupy vertex
      fVertexOccupied := KMPOINT_ZERO;
    end;
    StepDone := True;
    Result := arActDone;
    exit;
  end;

  WalkX := fWalkTo.X - fUnit.PositionF.X;
  WalkY := fWalkTo.Y - fUnit.PositionF.Y;
  DX := sign(WalkX); //-1,0,1
  DY := sign(WalkY); //-1,0,1

  if (DX <> 0) and (DY <> 0) then
    Distance := Distance / 1.41; {sqrt (2) = 1.41421 }

  fUnit.PositionF := KMPointF(fUnit.PositionF.X + DX*Math.min(Distance,abs(WalkX)),
                              fUnit.PositionF.Y + DY*Math.min(Distance,abs(WalkY)));
  Inc(fUnit.AnimStep);
end;


procedure TKMUnitActionAbandonWalk.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fWalkTo);
  SaveStream.Write(fVertexOccupied);
end;


function TKMUnitActionAbandonWalk.CanBeInterrupted(aForced: Boolean = True): Boolean;
begin
  Result := StepDone and not Locked; //Abandon walk should never be abandoned, it will exit within 1 step anyway
end;


end.
