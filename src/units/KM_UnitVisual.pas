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
  end;

  // Purely visual thing. Split from TKMUnit to aviod mixup of game-logic and render Positions
  TKMUnitVisual = class
  private
    fUnit: TObject;
    Curr: TKMUnitVisualState;
    Prev: TKMUnitVisualState;
  public
    constructor Create(aUnit: TObject);

    procedure UpdateState;
  end;


implementation
uses
  KromUtils, Math, SysUtils,
  KM_Units, KM_Game, KM_Terrain;


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


{ TKMUnitVisual }
constructor TKMUnitVisual.Create(aUnit: TObject);
begin
  inherited Create;
  fUnit := TKMUnit(aUnit);
  Prev.SetFromUnit(fUnit);
  Curr.SetFromUnit(fUnit);
end;


procedure TKMUnitVisual.UpdateState;
begin
  Prev := Curr;
  Curr.SetFromUnit(fUnit);
end;

end.
