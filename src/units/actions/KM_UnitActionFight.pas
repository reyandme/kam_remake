unit KM_UnitActionFight;
{$I KaM_Remake.inc}
interface
uses
  Classes, KM_CommonClasses, KM_Defaults, KM_CommonUtils, KromUtils, Math, SysUtils, KM_Units, KM_Points;


//Fight until we die or the opponent dies
type
  TKMUnitActionFight = class(TKMUnitAction)
  private
    fFightDelay: Integer; //Pause for this many ticks before going onto the next Step
    fOpponent: TKMUnit; //Who we are fighting with
    fVertexOccupied: TKMPoint; //The diagonal vertex we are currently occupying

    //Execute is broken up into multiple methods
      function ExecuteValidateOpponent(Step: Byte): TKMActionResult;
      function ExecuteProcessRanged(Step: Byte): Boolean;
      function ExecuteProcessMelee(Step: Byte): Boolean;

    function UpdateVertexUsage(const aFrom, aTo: TKMPoint): Boolean;
    procedure IncVertex(const aFrom, aTo: TKMPoint);
    procedure DecVertex;
    procedure MakeSound(IsHit: Boolean);
  public
    constructor Create(aUnit: TKMUnit; aActionType: TKMUnitActionType; aOpponent: TKMUnit);
    constructor Load(LoadStream:TKMemoryStream); override;
    destructor Destroy; override;
    function ActName: TKMUnitActionName; override;
    function CanBeInterrupted(aForced: Boolean = True): Boolean; override;
    function GetExplanation: UnicodeString; override;
    procedure SyncLoad; override;
    property GetOpponent: TKMUnit read fOpponent;
    function Execute: TKMActionResult; override;
    procedure Save(SaveStream: TKMemoryStream); override;
  end;


implementation
uses
  KM_HandsCollection, KM_ResSound, KM_Sound, KM_UnitWarrior, KM_Resource, KM_Projectiles,
  KM_ResUnits, KM_Hand;


const
  STRIKE_STEP = 5; //Melee units place hit on step 5

  MeleeSoundsHit: array [0..14] of TSoundFX = (
    sfxMelee34, sfxMelee35, sfxMelee36, sfxMelee41, sfxMelee42,
    sfxMelee44, sfxMelee45, sfxMelee46, sfxMelee47, sfxMelee48,
    sfxMelee49, sfxMelee50, sfxMelee55, sfxMelee56, sfxMelee57);

  MeleeSoundsMiss: array [0..8] of TSoundFX = (
    sfxMelee37, sfxMelee38, sfxMelee39,
    sfxMelee40, sfxMelee43, sfxMelee51,
    sfxMelee52, sfxMelee53, sfxMelee54);


{ TUnitActionFight }
constructor TKMUnitActionFight.Create(aUnit: TKMUnit; aActionType: TKMUnitActionType; aOpponent: TKMUnit);
begin
  inherited Create(aUnit, aActionType, True);

  Assert(aUnit is TKMUnitWarrior, 'Can''t create fight action for not Warrior unit');

  fFightDelay     := -1;
  fOpponent       := aOpponent.GetUnitPointer;
  aUnit.Direction := KMGetDirection(fUnit.PositionF, fOpponent.PositionF); //Face the opponent from the beginning
  fVertexOccupied := KMPOINT_ZERO;
  if KMStepIsDiag(fUnit.CurrPosition, fOpponent.CurrPosition) and not TKMUnitWarrior(fUnit).IsRanged then
    IncVertex(fUnit.CurrPosition, fOpponent.CurrPosition);
end;


destructor TKMUnitActionFight.Destroy;
begin
  gHands.CleanUpUnitPointer(fOpponent);
  if not KMSamePoint(fVertexOccupied, KMPOINT_ZERO) then
    DecVertex;
  inherited;
end;


constructor TKMUnitActionFight.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.Read(fOpponent, 4);
  LoadStream.Read(fFightDelay);
  LoadStream.Read(fVertexOccupied);
end;


procedure TKMUnitActionFight.SyncLoad;
begin
  inherited;
  fOpponent := gHands.GetUnitByUID(Cardinal(fOpponent));
end;


function TKMUnitActionFight.ActName: TKMUnitActionName;
begin
  Result := uanFight;
end;


function TKMUnitActionFight.GetExplanation: UnicodeString;
begin
  Result := 'Fighting';
end;


function TKMUnitActionFight.UpdateVertexUsage(const aFrom, aTo: TKMPoint): Boolean;
begin
  Result := True;
  if KMStepIsDiag(aFrom, aTo) then
  begin
    //If the new target has the same vertex as the old one, no change is needed
    if KMSamePoint(KMGetDiagVertex(aFrom, aTo), fVertexOccupied) then Exit;
    //Otherwise the new target's vertex is different to the old one, so remove old vertex usage and add new
    DecVertex;
    if fUnit.VertexUsageCompatible(aFrom, aTo) then
      IncVertex(aFrom, aTo)
    else
      Result := False; //This vertex is being used so we can't fight
  end
  else
    //The new target is not diagonal, make sure any old vertex usage is removed
    DecVertex;
end;


procedure TKMUnitActionFight.IncVertex(const aFrom, aTo: TKMPoint);
begin
  //Tell gTerrain that this vertex is being used so no other unit walks over the top of us
  Assert(KMSamePoint(fVertexOccupied, KMPOINT_ZERO), 'Fight vertex in use');

  fUnit.VertexAdd(aFrom, aTo);
  fVertexOccupied := KMGetDiagVertex(aFrom,aTo);
end;


procedure TKMUnitActionFight.DecVertex;
begin
  //Tell gTerrain that this vertex is not being used anymore
  if KMSamePoint(fVertexOccupied, KMPOINT_ZERO) then exit;

  fUnit.VertexRem(fVertexOccupied);
  fVertexOccupied := KMPOINT_ZERO;
end;


procedure TKMUnitActionFight.MakeSound(IsHit: Boolean);
var
  //Battlecry is the most noticable random sound, we would like to repeat it exactly the same in each replay (?)
  MakeBattleCry: Boolean;
begin
  //Randomly make a battle cry. KaMRandom must always happen regardless of tile revelation
  MakeBattleCry := KaMRandom(20, 'TKMUnitActionFight.MakeSound') = 0;

  //Do not play sounds if unit is invisible to gMySpectator
  //We should not use KaMRandom below this line because sound playback depends on FOW and is individual for each player
  if gMySpectator.FogOfWar.CheckTileRevelation(fUnit.CurrPosition.X, fUnit.CurrPosition.Y) < 255 then Exit;

  if MakeBattleCry then
    gSoundPlayer.PlayWarrior(fUnit.UnitType, spBattleCry, fUnit.PositionF);

  case fUnit.UnitType of
    utArbaletman: gSoundPlayer.Play(sfxCrossbowDraw, fUnit.PositionF); // Aiming
    utBowman:     gSoundPlayer.Play(sfxBowDraw,      fUnit.PositionF); // Aiming
    utSlingshot:  gSoundPlayer.Play(sfxSlingerShoot, fUnit.PositionF);
    else           begin
                     if IsHit then
                       gSoundPlayer.Play(MeleeSoundsHit[Random(Length(MeleeSoundsHit))], fUnit.PositionF)
                     else
                       gSoundPlayer.Play(MeleeSoundsMiss[Random(Length(MeleeSoundsMiss))], fUnit.PositionF);
                   end;
  end;
end;


function TKMUnitActionFight.ExecuteValidateOpponent(Step: Byte): TKMActionResult;
begin
  Result := arActContinues;
  //See if Opponent has walked away (i.e. Serf) or died
  if fOpponent.IsDeadOrDying //Don't continue to fight dead units
  or not fOpponent.Visible //Don't continue to fight units that have went into a house
  or not TKMUnitWarrior(fUnit).WithinFightRange(fOpponent.CurrPosition)
  or not fUnit.CanWalkDiagonaly(fUnit.CurrPosition, fOpponent.CurrPosition) then //Might be a tree between us now
  begin
    //After killing an opponent there is a very high chance that there is another enemy to be fought immediately
    //Try to start fighting that enemy by reusing this FightAction, rather than destroying it and making a new one
    Locked := False; //Fight can be interrupted by FindEnemy, otherwise it will always return nil!
    gHands.CleanUpUnitPointer(fOpponent); //We are finished with the old opponent
    fOpponent := TKMUnitWarrior(fUnit).FindEnemy; //Find a new opponent
    if fOpponent <> nil then
    begin
      //Start fighting this opponent by resetting the action
      fOpponent.GetUnitPointer; //Add to pointer count
      TKMUnitWarrior(fUnit).OnPickedFight(TKMUnitWarrior(fUnit), fOpponent);
      Locked := true;
      fFightDelay := -1;
      //Ranged units should turn to face the new opponent immediately
      if TKMUnitWarrior(fUnit).IsRanged then
        fUnit.Direction := KMGetDirection(fUnit.PositionF, fOpponent.PositionF)
      else
        //Melee: If we haven't yet placed our strike, reset the animation step
        //Otherwise finish this strike then we can face the new opponent automatically
        if Step <= STRIKE_STEP then
          fUnit.AnimStep := 0; //Rest fight animation/sequence
    end
    else
    begin
      //No one else to fight, so we exit
      Result := arActDone;
    end;
  end;
end;


//A result of true means exit from Execute
function TKMUnitActionFight.ExecuteProcessRanged(Step: Byte): Boolean;
var
  W: TKMUnitWarrior;
begin
  Result := False;

  W := TKMUnitWarrior(fUnit);

  if Step = 0 then
  begin
    if fFightDelay = -1 then //Initialize
      fFightDelay := W.AimingDelay;
    
    if fFightDelay > 0 then
    begin
      Dec(fFightDelay);
      Result := True; //do not increment AnimStep, just exit;
      Exit;
    end;
  end;

  //Slingshot sound should happen a bit later
  if Step = W.AimSoundDelay then
    MakeSound(False);
  
  if Step = W.FiringDelay then
  begin
    W.SetLastShootTime; //Record last time the warrior shot

    //Fire the arrow
    gProjectiles.AimTarget(fUnit.PositionF, fOpponent, W.ProjectileType, fUnit, W.RangeMax, W.RangeMin);

    fFightDelay := -1; //Reset
  end;
end;


//A result of true means exit from Execute
function TKMUnitActionFight.ExecuteProcessMelee(Step: Byte): Boolean;
var
  IsHit: Boolean;
  Damage: Word;
begin
  Result := False;

  if Step = 1 then
  begin
    //Tell the Opponent we are attacking him
    gHands[fOpponent.Owner].AI.UnitAttackNotification(fOpponent, TKMUnitWarrior(fUnit));

    //Tell our AI that we are in a battle and might need assistance! (only for melee battles against warriors)
    if (fOpponent is TKMUnitWarrior) and not TKMUnitWarrior(fUnit).IsRanged then
      gHands[fUnit.Owner].AI.UnitAttackNotification(fUnit, TKMUnitWarrior(fOpponent), False);
  end;

  //Melee units place hit on this step
  if Step = STRIKE_STEP then
  begin
    //Base damage is the unit attack strength + AttackHorse if the enemy is mounted
    Damage := gRes.Units[fUnit.UnitType].Attack;
    if (fOpponent.UnitType in [low(UnitGroups) .. high(UnitGroups)]) and (UnitGroups[fOpponent.UnitType] = gtMounted) then
      Damage := Damage + gRes.Units[fUnit.UnitType].AttackHorse;

    Damage := Damage * (GetDirModifier(fUnit.Direction,fOpponent.Direction)+1); //Direction modifier
    //Defence modifier
    Damage := Damage div Math.max(gRes.Units[fOpponent.UnitType].Defence, 1); //Not needed, but animals have 0 defence

    IsHit := (Damage >= KaMRandom(101, 'TKMUnitActionFight.ExecuteProcessMelee')); //Damage is a % chance to hit
    if IsHit then
      fOpponent.HitPointsDecrease(1, fUnit);

    MakeSound(IsHit); //Different sounds for hit and for miss
  end;

  //In KaM melee units pause for 1 tick on Steps [0,3,6]. Made it random so troops are not striking in sync,
  //plus it adds randomness to battles
  if Step in [0,3,6] then
  begin
    if fFightDelay = -1 then //Initialize
      fFightDelay := KaMRandom(2, 'TKMUnitActionFight.ExecuteProcessMelee 2');

    if fFightDelay > 0 then
    begin
      dec(fFightDelay);
      Result := True; //Means exit from Execute
      Exit;
    end;

    fFightDelay := -1; //Reset
  end;
end;


function TKMUnitActionFight.Execute: TKMActionResult;
var
  Cycle, Step: Byte;
begin
  Cycle := max(gRes.Units[fUnit.UnitType].UnitAnim[ActionType, fUnit.Direction].Count, 1);
  Step  := fUnit.AnimStep mod Cycle;

  Result := ExecuteValidateOpponent(Step);
  if Result = arActDone then Exit;
  Step := fUnit.AnimStep mod Cycle; //Can be changed by ExecuteValidateOpponent, so recalculate it

  //Opponent can walk next to us, keep facing him
  if Step = 0 then //Only change direction between strikes, otherwise it looks odd
    fUnit.Direction := KMGetDirection(fUnit.PositionF, fOpponent.PositionF);

  //If the vertex usage has changed we should update it
  if not TKMUnitWarrior(fUnit).IsRanged then //Ranged units do not use verticies
    if not UpdateVertexUsage(fUnit.CurrPosition, fOpponent.CurrPosition) then
    begin
      //The vertex is being used so we can't fight
      Result := arActDone;
      Exit;
    end;

  if TKMUnitWarrior(fUnit).IsRanged then
  begin
    if ExecuteProcessRanged(Step) then
      Exit;
  end
  else
    if ExecuteProcessMelee(Step) then
      Exit;

  //Aiming Archers and pausing melee may miss a few ticks, (exited above) so don't put anything critical below!

  StepDone := (fUnit.AnimStep mod Cycle = 0) or TKMUnitWarrior(fUnit).IsRanged; //Archers may abandon at any time as they need to walk off imediantly
  Inc(fUnit.AnimStep);
end;


procedure TKMUnitActionFight.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  if fOpponent <> nil then
    SaveStream.Write(fOpponent.UID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Integer(0));
  SaveStream.Write(fFightDelay);
  SaveStream.Write(fVertexOccupied);
end;


function TKMUnitActionFight.CanBeInterrupted(aForced: Boolean = True): Boolean;
begin
  Result := (TKMUnitWarrior(fUnit).IsRanged and aForced) or not Locked; //Only allowed to interupt ranged fights
end;


end.
