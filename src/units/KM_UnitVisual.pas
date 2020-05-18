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
  KM_Defaults, KM_Units, KM_Game, KM_Terrain;


{ TKMUnitVisual }
constructor TKMUnitVisual.Create(aUnit: TObject);
begin
  inherited Create;
  fUnit := TKMUnit(aUnit);
end;


procedure TKMUnitVisual.UpdateState;
var
  U: TKMUnit;
begin
  U := TKMUnit(fUnit);
  Prev := Curr;
  Curr.PosF := U.PositionF;
  Curr.Dir := U.Direction;
  Curr.SlideX := U.GetSlide(axX);
  Curr.SlideY := U.GetSlide(axY);
  Curr.Action := U.Action;
  Curr.AnimStep := U.AnimStep;
end;


end.
