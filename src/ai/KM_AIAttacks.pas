unit KM_AIAttacks;
{$I KaM_Remake.inc}
interface
uses
  KM_Defaults, KM_CommonClasses, KM_Points;

type
  TKMAIAttackType = (
    aatOnce,     // Attack will occur once (after the set time has passed and if they have enough troops
    aatRepeating // Attack will happen multiple times, (after delay time) whenever the AI has enough troops
  );

const
  //KaM uses 0 for repeating attack in TSK (disused and replaced with later by Remake), 1 for once and 2 for repeating in TPR
  RemakeAttackType: array [0..2] of TKMAIAttackType = (aatRepeating, aatOnce, aatRepeating);
  KaMAttackType: array [TKMAIAttackType] of Byte = (1, 0);

type
  //Indexes must match with KaM script values (for now)
  TKMAIAttackTarget = (attClosestUnit, //Closest enemy unit (untested as to whether this is relative to army or start position)
                       attClosestBuildingFromArmy, //Closest building from the group(s) lauching the attack
                       attClosestBuildingFromStartPos, //Closest building from the AI's start position
                       attCustomPosition); //Custom point defined with CustomPosition


  //Records must be packed so they are stored identically in MP saves (? padding bytes are unknown values)
  TKMAIAttack = packed record
    Id: Word; //Attack ID, used to remove attack from script
    AttackType: TKMAIAttackType; //Once or repeating
    HasOccured: Boolean; //Has this attack happened already?
    Delay: Cardinal; //The attack will not occur before this time has passed
    TotalMen: Integer; //Number of idle (i.e. back line) warriors required in the AI army before the attack will launch
    GroupAmounts: TKMGroupTypeArray; //How many squads of each group type will be taken
    TakeAll: Boolean; //Used instead of GroupAmounts, chooses groups randomly taking at most TotalMen warriors
    Target: TKMAIAttackTarget;
    Range: Integer; //Will only occur when target is within this tile range (not properly tested yet)
    CustomPosition: TKMPoint; //Used when Target = attCustomPosition
  end;


  TKMAIAttacks = class
  private
    fGlobalAttackId: Word; //global attack id counter
    fCount: Integer;
    fAttacks: array of TKMAIAttack;
    function GetAttack(aIndex: Integer): TKMAIAttack;
    procedure SetAttack(aIndex: Integer; const aValue: TKMAIAttack);
  public
    constructor Create;

    property Count: Integer read fCount;
    property Items[aIndex: Integer]: TKMAIAttack read GetAttack write SetAttack; default;

    function GetNextAttackId: Word;

    function AddAttack(aAttack: TKMAIAttack): Word; overload;
    function AddAttack(aAttackType: TKMAIAttackType; aDelay: Cardinal; aTotalMen: Integer; aGroupAmounts: TKMGroupTypeArray;
                       aTakeAll: Boolean; aTarget: TKMAIAttackTarget; aRange: Integer; aCustomPosition: TKMPoint): Word; overload;
    function AddAttack(aAttackType: TKMAIAttackType; aDelay: Cardinal; aTotalMen: Integer;
                       aMeleeCount, aAntiHorseCount, aRangedCount, aMountedCount: Word;
                       aTakeAll: Boolean; aTarget: TKMAIAttackTarget; aRange: Integer; aCustomPosition: TKMPoint): Word; overload;
    function RemoveAttack(aAttackId: Word): Boolean;
    procedure Delete(aIndex: Integer);
    function CanOccur(aIndex: Integer; const aMenAvailable: TKMGroupTypeArray; const aGroupsAvailable: TKMGroupTypeArray; aTick: Cardinal): Boolean;
    procedure HasOccured(aIndex: Integer);
    procedure Clear;

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
  end;


implementation
uses
  Math;


{ TAIAttacks }
constructor TKMAIAttacks.Create;
begin
  fGlobalAttackId := 0;
end;


function TKMAIAttacks.CanOccur(aIndex: Integer; const aMenAvailable: TKMGroupTypeArray; const aGroupsAvailable: TKMGroupTypeArray; aTick: Cardinal): Boolean;
var
  GT: TKMGroupType;
  TotalMenAvailable: Word;
begin
  TotalMenAvailable := 0;
  //Must have enough men available out of the types of groups that will attack
  for GT := Low(TKMGroupType) to High(TKMGroupType) do
    if fAttacks[aIndex].TakeAll or (fAttacks[aIndex].GroupAmounts[GT] > 0) then
      Inc(TotalMenAvailable, aMenAvailable[GT]);

  Result := ((fAttacks[aIndex].AttackType = aatRepeating) or not fAttacks[aIndex].HasOccured)
            and (aTick >= fAttacks[aIndex].Delay)
            and (TotalMenAvailable >= fAttacks[aIndex].TotalMen);

  //Must have enough groups of each type
  if not fAttacks[aIndex].TakeAll then
    for GT := Low(TKMGroupType) to High(TKMGroupType) do
      Result := Result and (aGroupsAvailable[GT] >= fAttacks[aIndex].GroupAmounts[GT]);

  //todo: Add support for the AI attack feature Range
end;


procedure TKMAIAttacks.HasOccured(aIndex: Integer);
begin
  fAttacks[aIndex].HasOccured := True;
end;


procedure TKMAIAttacks.Clear;
begin
  SetLength(fAttacks, 0);
  fCount := 0;
end;


function TKMAIAttacks.GetNextAttackId: Word;
begin
  Inc(fGlobalAttackId);
  Result := fGlobalAttackId;
end;


function TKMAIAttacks.AddAttack(aAttack: TKMAIAttack): Word;
begin
  if fCount >= Length(fAttacks) then
    SetLength(fAttacks, fCount + 16);

  aAttack.Id := GetNextAttackId;
  fAttacks[fCount] := aAttack;
  Inc(fCount);
  Result := aAttack.Id;
end;


function TKMAIAttacks.AddAttack(aAttackType: TKMAIAttackType; aDelay: Cardinal; aTotalMen: Integer; aGroupAmounts: TKMGroupTypeArray;
                                aTakeAll: Boolean; aTarget: TKMAIAttackTarget; aRange: Integer; aCustomPosition: TKMPoint): Word;
var
  Attack: TKMAIAttack;
begin
  Attack.AttackType     := aAttackType;
  Attack.HasOccured     := False;
  Attack.Delay          := aDelay;
  Attack.TotalMen       := aTotalMen;
  Attack.GroupAmounts   := aGroupAmounts;
  Attack.TakeAll        := aTakeAll;
  Attack.Target         := aTarget;
  Attack.Range          := aRange;
  Attack.CustomPosition := aCustomPosition;
  Result := AddAttack(Attack);
end;


function TKMAIAttacks.AddAttack(aAttackType: TKMAIAttackType; aDelay: Cardinal; aTotalMen: Integer;
                                aMeleeCount, aAntiHorseCount, aRangedCount, aMountedCount: Word;
                                aTakeAll: Boolean; aTarget: TKMAIAttackTarget; aRange: Integer; aCustomPosition: TKMPoint): Word;
var
  GroupAmounts: TKMGroupTypeArray;
begin
  GroupAmounts[gtMelee]      := aMeleeCount;
  GroupAmounts[gtAntiHorse]  := aAntiHorseCount;
  GroupAmounts[gtRanged]     := aRangedCount;
  GroupAmounts[gtMounted]    := aMountedCount;
  Result := AddAttack(aAttackType, aDelay, aTotalMen, GroupAmounts, aTakeAll, aTarget, aRange, aCustomPosition);
end;


//Remove AIAttack by its ID
//Result - true, if delete was succesfull, false, if no AIAttack was found
function TKMAIAttacks.RemoveAttack(aAttackId: Word): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to fCount - 1 do
    if fAttacks[I].Id = aAttackId then
    begin
      Delete(I);
      Result := True;
      Exit;
    end;
end;


procedure TKMAIAttacks.Delete(aIndex: Integer);
begin
  Assert(InRange(aIndex, 0, Count - 1));

  if (aIndex <> Count - 1) then
    Move(fAttacks[aIndex + 1], fAttacks[aIndex], (Count - 1 - aIndex) * SizeOf(fAttacks[0]));

  Dec(fCount);
end;


function TKMAIAttacks.GetAttack(aIndex: Integer): TKMAIAttack;
begin
  Assert(InRange(aIndex, 0, fCount - 1));
  Result := fAttacks[aIndex];
end;


procedure TKMAIAttacks.SetAttack(aIndex: Integer; const aValue: TKMAIAttack);
begin
  Assert(InRange(aIndex, 0, fCount - 1));
  fAttacks[aIndex] := aValue;
end;


procedure TKMAIAttacks.Save(SaveStream: TKMemoryStream);
var
  I: Integer;
begin
  SaveStream.PlaceMarker('AIAttacks');
  SaveStream.Write(fCount);
  for I := 0 to fCount - 1 do
    SaveStream.Write(fAttacks[I], SizeOf(fAttacks[I]));
end;


procedure TKMAIAttacks.Load(LoadStream: TKMemoryStream);
var
  I: Integer;
begin
  LoadStream.CheckMarker('AIAttacks');
  LoadStream.Read(fCount);
  SetLength(fAttacks, fCount);
  for I := 0 to fCount - 1 do
    LoadStream.Read(fAttacks[I], SizeOf(fAttacks[I]));
end;


end.

