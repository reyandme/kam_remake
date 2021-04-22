unit KM_UnitVisual;
{$I KaM_Remake.inc}
interface
uses
  KM_Points, KM_Defaults;

type
  TKMUnitVisualState = record
    PosF: TKMPointF;
    Dir: TKMDirection;
    SlideX, SlideY: Single;
    Action: TKMUnitActionType;
    AnimStep: Integer;

    procedure SetFromUnit(aUnit: TObject);

    class function Lerp(const A, B: TKMUnitVisualState; Mix: Single): TKMUnitVisualState; static;
  end;

  // Purely visual thing. Split from TKMUnit to aviod mixup of game-logic and render Positions
  TKMUnitVisual = class
  private
    fUnit: TObject;
    fCurr: TKMUnitVisualState;
    fPrev: TKMUnitVisualState;
  public
    constructor Create(aUnit: TObject);

    function GetLerp(aLag: Single): TKMUnitVisualState;
    procedure UpdateState;
  end;


implementation
uses
  KromUtils, Math, SysUtils,
  KM_Units;


{ TKMUnitVisualState }
procedure TKMUnitVisualState.SetFromUnit(aUnit: TObject);
var
  U: TKMUnit;
begin
  U := TKMUnit(aUnit);
  PosF := U.PositionF;
  Dir := U.Direction;
  SlideX := U.GetSlide(axX);
  SlideY := U.GetSlide(axY);
  AnimStep := U.AnimStep;

  if U.Action <> nil then
    Action := U.Action.ActionType
  else
    Action := uaUnknown;
end;


class function TKMUnitVisualState.Lerp(const A, B: TKMUnitVisualState; Mix: Single): TKMUnitVisualState;
begin
  Result.PosF := KMLerp(A.PosF, B.PosF, Mix);
  Result.SlideX := KromUtils.Lerp(A.SlideX, B.SlideX, Mix);
  Result.SlideY := KromUtils.Lerp(A.SlideY, B.SlideY, Mix);
  if Mix < 0.5 then
  begin
    Result.Dir := A.Dir;
    Result.AnimStep := A.AnimStep;
    Result.Action := A.Action;
  end
  else
  begin
    Result.Dir := B.Dir;
    Result.AnimStep := B.AnimStep;
    Result.Action := B.Action;
  end;
end;


{ TKMUnitVisual }
constructor TKMUnitVisual.Create(aUnit: TObject);
begin
  inherited Create;

  fUnit := TKMUnit(aUnit);
  fPrev.SetFromUnit(fUnit);
  fCurr.SetFromUnit(fUnit);
end;


function TKMUnitVisual.GetLerp(aLag: Single): TKMUnitVisualState;
begin
  Result := TKMUnitVisualState.Lerp(fCurr, fPrev, aLag);
end;


procedure TKMUnitVisual.UpdateState;
begin
  fPrev := fCurr;
  fCurr.SetFromUnit(fUnit);
end;

end.
