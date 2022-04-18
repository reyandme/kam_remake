unit KM_AITypes;
{$I KaM_Remake.inc}
interface

type
  //* AI defence position type
  // For now IDs must match with KaM
  TKMAIDefencePosType = (dtFrontLine, //Front line troops may not go on attacks, they are for defence
                         dtBackLine); //Back line troops may attack
  //* AI attack type
  TKMAIAttackType = (
    aatOnce,     // Attack will occur once (after the set time has passed and if they have enough troops
    aatRepeating // Attack will happen multiple times, (after delay time) whenever the AI has enough troops
  );

  //* AI attack target
  //Indexes must match with KaM script values (for now)
  TKMAIAttackTarget = (attClosestUnit, //Closest enemy unit (untested as to whether this is relative to army or start position)
                       attClosestBuildingFromArmy, //Closest building from the group(s) lauching the attack
                       attClosestBuildingFromStartPos, //Closest building from the AI's start position
                       attCustomPosition); //Custom point defined with CustomPosition

  TKMFormation = record
    NumUnits: Integer;
    UnitsPerRow: Integer;
    procedure CopyFrom(aFormation: TKMFormation);
  end;

  //* House repair mode
  TKMAIRepairMode = (
    rmNone,
    rmRepairNever,   // disable AI repair for all houses
    rmRepairAlways,  // enable AI repair for all houses
    rmRepairManual); // repair state is set by script manually via Actions.HouseRepairEnable

implementation

{ TKMFormation }
procedure TKMFormation.CopyFrom(aFormation: TKMFormation);
begin
  NumUnits := aFormation.NumUnits;
  UnitsPerRow := aFormation.UnitsPerRow;
end;


end.

