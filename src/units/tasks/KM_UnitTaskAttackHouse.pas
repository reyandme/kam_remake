unit KM_UnitTaskAttackHouse;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, Math,
  KM_CommonClasses, KM_Defaults, KM_CommonUtils, KM_Houses, KM_Units, KM_UnitWarrior, KM_Points;


type
  // Attack a house
  TKMTaskAttackHouse = class(TKMUnitTask)
  private
    fHouse: TKMHouse;
  public
    constructor Create(aWarrior: TKMUnitWarrior; aHouse: TKMHouse);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure SyncLoad; override;
    destructor Destroy; override;

    property House: TKMHouse read fHouse;

    function WalkShouldAbandon: Boolean; override;
    function Execute: TKMTaskResult; override;
    procedure Save(SaveStream: TKMemoryStream); override;
  end;


implementation
uses
  KM_HandsCollection, KM_ResSound, KM_Sound, KM_Resource, KM_Projectiles, KM_Game, KM_ResUnits;


const
  MeleeSoundsHouse: array [0..12] of TSoundFX = (
    sfxMelee37, sfxMelee38, sfxMelee39, sfxMelee40, sfxMelee41,
    sfxMelee42, sfxMelee43, sfxMelee47, sfxMelee51, sfxMelee52,
    sfxMelee53, sfxMelee54, sfxMelee57
  );


{ TTaskAttackHouse }
constructor TKMTaskAttackHouse.Create(aWarrior: TKMUnitWarrior; aHouse: TKMHouse);
begin
  inherited Create(aWarrior);
  fType := uttAttackHouse;
  fHouse := aHouse.GetHousePointer;
end;


constructor TKMTaskAttackHouse.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.Read(fHouse, 4);
end;


procedure TKMTaskAttackHouse.SyncLoad;
begin
  inherited;
  fHouse := gHands.GetHouseByUID(Cardinal(fHouse));
end;


destructor TKMTaskAttackHouse.Destroy;
begin
  gHands.CleanUpHousePointer(fHouse);
  inherited;
end;


function TKMTaskAttackHouse.WalkShouldAbandon: Boolean;
begin
  Result := fHouse.IsDestroyed;
end;


function TKMTaskAttackHouse.Execute: TKMTaskResult;
var
   AnimLength: Integer;
   Delay, Cycle: Integer;
begin
  Result := trTaskContinues;

  //If the house is destroyed drop the task
  if WalkShouldAbandon then
  begin
    Result := trTaskDone;
    Exit;
  end;

  with TKMUnitWarrior(fUnit) do
    case fPhase of
      0:  if IsRanged then
            if fHouse.GetDistance(CurrPosition) < GetFightMinRange then
              //Archer is too close, try to step back to the minimum range
              SetActionWalkFromHouse(fHouse, GetFightMinRange)
            else
            if fHouse.GetDistance(CurrPosition) > GetFightMaxRange then
              SetActionWalkToHouse(fHouse, GetFightMaxRange)
            else
              SetActionStay(0, uaWalk)
          else
            SetActionWalkToHouse(fHouse, 1);
      1:  begin
            if IsRanged then
            begin
              //Check if the walk failed
              if (fHouse.GetDistance(CurrPosition) < GetFightMinRange) or (fHouse.GetDistance(CurrPosition) > GetFightMaxRange) then
              begin
                SetActionStay(0, uaWalk);
                Result := trTaskDone;
                Exit;
              end;

              //Calculate base aiming delay
              Delay := AimingDelay;

              //Prevent rate of fire exploit by making archers pause for longer if they shot recently
              Cycle := Max(gRes.Units[UnitType].UnitAnim[uaWork, Direction].Count, 1) - FiringDelay;
              if NeedsToReload(Cycle) then
                Delay := Delay + Cycle - (gGame.GameTick - LastShootTime);

              SetActionLockedStay(Delay,uaWork); //Pretend to aim

              if not KMSamePoint(CurrPosition, fHouse.GetClosestCell(CurrPosition)) then //Unbuilt houses can be attacked from within
                Direction := KMGetDirection(CurrPosition, fHouse.Entrance); //Look at house

              if gMySpectator.FogOfWar.CheckTileRevelation(Round(PositionF.X), Round(PositionF.Y)) >= 255 then
              case UnitType of
                utArbaletman: gSoundPlayer.Play(sfxCrossbowDraw, PositionF); //Aiming
                utBowman:     gSoundPlayer.Play(sfxBowDraw,      PositionF); //Aiming
                utSlingshot:  ;
                else           raise Exception.Create('Unknown shooter');
              end;
            end
            else
            begin
              //Check if the walk failed
              if fHouse.GetDistance(CurrPosition) > GetFightMaxRange then
              begin
                SetActionStay(0, uaWalk);
                Result := trTaskDone;
                Exit;
              end;
              SetActionLockedStay(0,uaWork,False); //Melee units pause after the hit
              if not KMSamePoint(CurrPosition, fHouse.GetClosestCell(CurrPosition)) then //Unbuilt houses can be attacked from within
                Direction := KMGetDirection(CurrPosition, fHouse.GetClosestCell(CurrPosition)); //Look at house

            end;
          end;
      2:  begin
            //Special case - slingshot, he has AimSoundDelay
            if UnitType = utSlingshot then
              SetActionLockedStay(AimSoundDelay, uaWork, False) //Start shooting before sound
            else
            begin
              Inc(fPhase); //Skip slingshot special phase
              if IsRanged then
                SetActionLockedStay(FiringDelay, uaWork, False) //Start shooting
              else
                SetActionLockedStay(6, uaWork, False); //Start the hit
            end;
          end;
      3:  begin
            gSoundPlayer.Play(sfxSlingerShoot, PositionF);
            SetActionLockedStay(FiringDelay - AimSoundDelay, uaWork, False, 0, AimSoundDelay) //Start shooting before sound
          end;
      4:  begin
            if IsRanged then
            begin
              //Launch the missile and forget about it
              //Shooting range is not important now, houses don't walk (except Howl's Moving Castle perhaps)
              //todo: Slingers (rogues) should launch rock part on SLINGSHOT_FIRING_DELAY like they do in ActionFight (animation looks wrong now)
              gProjectiles.AimTarget(PositionF, fHouse, ProjectileType, fUnit, RangeMax, RangeMin);

              SetLastShootTime; //Record last time the warrior shot
              AnimLength := gRes.Units[UnitType].UnitAnim[uaWork, Direction].Count;
              SetActionLockedStay(AnimLength - FiringDelay, uaWork, False, 0, FiringDelay); //Reload for next attack
              fPhase := 0; //Go for another shot (will be 1 after inc below)
            end
            else
            begin
              SetActionLockedStay(6, uaWork, False, 0, 6); // Pause for next attack

              //All melee units do 2 damage per strike
              fHouse.AddDamage(2, fUnit);

              //Play a sound. We should not use KaMRandom here because sound playback depends on FOW and is individual for each player
              if gMySpectator.FogOfWar.CheckTileRevelation(CurrPosition.X, CurrPosition.Y) >= 255 then
                gSoundPlayer.Play(MeleeSoundsHouse[Random(Length(MeleeSoundsHouse))], PositionF);

              fPhase := 1; //Go for another hit (will be 2 after inc below)
            end;
          end;
    end;

  Inc(fPhase);
end;


procedure TKMTaskAttackHouse.Save(SaveStream: TKMemoryStream);
begin
  inherited;

  if fHouse <> nil then
    SaveStream.Write(fHouse.UID)
  else
    SaveStream.Write(Integer(0));
end;


end.
