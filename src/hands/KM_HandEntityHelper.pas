unit KM_HandEntityHelper;
{$I KaM_Remake.inc}
interface
uses
  KM_HandEntity, KM_Units, KM_UnitWarrior, KM_UnitGroup, KM_Houses;

type
  TKMHandEntityHelper = class helper for TKMHandEntity
    function AsUnit: TKMUnit;
    function AsUnitWarrior: TKMUnitWarrior;
    function AsGroup: TKMUnitGroup;
    function AsHouse: TKMHouse;
  end;
  
  
implementation


{ TKMHandEntityHelper }
function TKMHandEntityHelper.AsGroup: TKMUnitGroup;
begin
  if (Self = nil)
  or not IsGroup
  or not (Self is TKMUnitGroup) then
    Exit(nil);

  Result := TKMUnitGroup(Self);
end;


function TKMHandEntityHelper.AsHouse: TKMHouse;
begin
  if (Self = nil)
  or not IsHouse
  or not (Self is TKMHouse) then
    Exit(nil);

  Result := TKMHouse(Self);
end;


function TKMHandEntityHelper.AsUnit: TKMUnit;
begin
  if (Self = nil)
  or not IsUnit
  or not (Self is TKMUnit) then
    Exit(nil);

  Result := TKMUnit(Self);
end;


function TKMHandEntityHelper.AsUnitWarrior: TKMUnitWarrior;
begin
  if (Self = nil)
  or not IsUnit
  or not (Self is TKMUnitWarrior) then
    Exit(nil);

  Result := TKMUnitWarrior(Self);
end;


end.
