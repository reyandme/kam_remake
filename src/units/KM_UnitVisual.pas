unit KM_UnitVisual;
{$I KaM_Remake.inc}
interface
uses
  KM_CommonSave, KM_Points;

type
  // Purely visual thing. Split from TKMUnit to aviod mixup of game-logic and render Positions
  TKMUnitVisual = class
  private
    fUnit: TObject;
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

  // Fill in initial values (Unit is nil in PreviewUnit)
  fUnit := TKMUnit(aUnit).GetUnitPointer;
end;


procedure TKMUnitVisual.UpdateState;
begin
end;


end.
