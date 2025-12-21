unit KM_Projectiles;
{$I KaM_Remake.inc}
interface
uses
  KM_Units, KM_Houses,
  KM_CommonClasses, KM_CommonGameTypes, KM_Points, KM_RenderTypes;


type
  // Projectiles in-game: arrows, bolts, rocks, etc..
  // Once launched they are on their own
  TKMProjectiles = class
  private
    fItems: array of record //1..n
      fScreenStart: TKMPointF; //Screen-space trajectory start
      fScreenEnd: TKMPointF;   //Screen-space trajectory end

      fAim: TKMPointF;  //Where we were aiming to hit
      fTarget: TKMPointF; //Where projectile will hit
      fShotFrom: TKMPointF; //Where the projectile was launched from

      fType: TKMProjectileType; //type of projectile (arrow, bolt, rocks, etc..)
      fOwner: TKMUnit; //The projectiles owner, used for kill statistics and script events
      fSpeed: Single; //Each projectile speed may vary a little bit
      fArc: Single; //Thats how high projectile will go along parabola (varies a little more)
      fPosition: Single; //Projectiles position along the route Start>>End
      fLength: Single; //Route length to look-up for hit
      fMaxLength: Single; //Maximum length the archer could have shot
    end;

    fOnAddProjectileToRenderPool: TKMRenderPoolAddProjectileEvent;

    function AddItem(const aStart,aAim,aEnd: TKMPointF; aSpeed, aArc, aMaxLength: Single; aProjType: TKMProjectileType; aOwner: TKMUnit): Word;
    procedure RemItem(aIndex: Integer);
    function ProjectileVisible(aIndex: Integer): Boolean;
    procedure AddProjectileToRenderPool(aProj: TKMProjectileType; const aRenderPos, aTilePos: TKMPointF; aDir: TKMDirection; aFlight: Single); inline;
  public
    constructor Create(aOnAddProjectileToRenderPool: TKMRenderPoolAddProjectileEvent);

    function AimTargetUnit(const aStart: TKMPointF; aTarget: TKMUnit; aProjType: TKMProjectileType; aOwner: TKMUnit; aMaxRange, aMinRange: Single): Word;
    function AimTargetHouse(const aStart: TKMPointF; aTarget: TKMHouse; aProjType: TKMProjectileType; aOwner: TKMUnit; aMaxRange, aMinRange: Single): Word;

    procedure UpdateState;
    procedure Paint(aTickLag: Single);

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad;
  end;


var
  gProjectiles: TKMProjectiles;


implementation
uses
  Math, KromUtils,
  KM_Entity,
  KM_Terrain, KM_RenderAux,
  KM_Resource, KM_ResSound, KM_ResUnits,
  KM_Hand, KM_HandsCollection, KM_HandTypes, KM_HandEntity,
  KM_Sound,
  KM_CommonUtils, KM_Defaults;


const
  PROJECTILE_LAUNCH_SOUND: array[TKMProjectileType] of TKMSoundEffectOriginal = (sfxBowShoot, sfxCrossbowShoot, sfxNone, sfxRockThrow);
  PROJECTILE_HIT_SOUND:   array[TKMProjectileType] of TKMSoundEffectOriginal = (sfxArrowHit, sfxArrowHit, sfxArrowHit, sfxNone);
  PROJECTILE_SPEED: array[TKMProjectileType] of Single = (0.75, 0.75, 0.6, 0.8);
  PROJECTILE_ARC: array[TKMProjectileType,1..2] of Single = ((1.6, 0.5), (1.4, 0.4), (2.5, 1), (1.2, 0.2)); //Arc curve and random fraction
  PROJECTILE_JITTER: array[TKMProjectileType] of Single = (0.26, 0.29, 0.26, 0.2); //Fixed Jitter added every time
  PROJECTILE_JITTER_HOUSE: array[TKMProjectileType] of Single = (0.6, 0.6, 0.6, 0); //Fixed Jitter added every time
  // Jitter added according to target's speed (moving target harder to hit) Note: Walking = 0.1, so the added jitter is 0.1*X
  PROJECTILE_PREDICT_JITTER: array[TKMProjectileType] of Single = (2, 2, 2, 3);


{ TKMProjectiles }
constructor TKMProjectiles.Create(aOnAddProjectileToRenderPool: TKMRenderPoolAddProjectileEvent);
begin
  inherited Create;

  fOnAddProjectileToRenderPool := aOnAddProjectileToRenderPool;
end;


procedure TKMProjectiles.RemItem(aIndex: Integer);
begin
  gHands.CleanUpUnitPointer(fItems[aIndex].fOwner);
  fItems[aIndex].fSpeed := 0;
end;


function TKMProjectiles.AimTargetUnit(const aStart: TKMPointF; aTarget: TKMUnit; aProjType: TKMProjectileType; aOwner: TKMUnit; aMaxRange, aMinRange: Single): Word;
var
  targetVector, target, targetPosition: TKMPointF;
  A,B,C,D: Single;
  timeToHit, time1, time2, distanceToHit, distanceInRange: Single;
  jitter, speed, arc: Single;
  U: TKMUnit;
begin
  //Now we know projectiles speed and aim, we can predict where target will be at the time projectile hits it

  //I wonder if medieval archers knew about vectors and quadratic equations

  targetPosition.X := (aTarget.PositionF.X - aStart.X);
  targetPosition.Y := (aTarget.PositionF.Y - aStart.Y);
  targetVector := aTarget.GetMovementVector;

  { This comment explains how we came to final ABC equation

    Target = TargetPosition + TargetVector * Time;
    FlightDistance := ArrowSpeed * Time;

    sqr(Target) = sqr(FlightDistance);

    sqr(TargetPosition + TargetVector * Time) = sqr(ArrowSpeed * Time)

    sqr(TargetPosition.X) + 2 * Time * TargetPosition.X * TargetVector.X + sqr(Time) * sqr(TargetVector.X) +
    sqr(ArrowSpeed) * sqr(Time)

    sqr(Time) * (sqr(TargetVector.X) + sqr(TargetVector.Y) - sqr(ArrowSpeed)) +
    2 * Time * (TargetPosition.X * TargetVector.X + TargetPosition.Y * TargetVector.Y) +
    sqr(TargetPosition.X) + sqr(TargetPosition.Y) = 0

    //Lets try to solve this quadratic equation
    //ATT + BT + C = 0
    //by using formulae X = (-B +- sqrt(B*B - 4*A*C)) / 2*A
    A = sqr(TargetVector.X) + sqr(TargetVector.Y) - sqr(ArrowSpeed)
    B = 2 * (TargetPosition.X * TargetVector.X + TargetPosition.Y * TargetVector.Y)
    C = sqr(TargetPosition.X) + sqr(TargetPosition.Y) }

  speed := PROJECTILE_SPEED[aProjType] + KaMRandomS2(0.05{$IFDEF DBG_RNG_SPY}, 'TKMProjectiles.AimTarget'{$ENDIF});

  A := sqr(targetVector.X) + sqr(targetVector.Y) - sqr(speed);
  B := 2 * (targetPosition.X * targetVector.X + targetPosition.Y * targetVector.Y);
  C := sqr(targetPosition.X) + sqr(targetPosition.Y);

  D := sqr(B) - 4 * A * C;

  if (D >= 0) and (A <> 0) then
  begin
    time1 := (-B + sqrt(D)) / (2 * A);
    time2 := (-B - sqrt(D)) / (2 * A);

    //Choose smallest positive time
    if (time1 > 0) and (time2 > 0) then
      timeToHit := Math.min(time1, time2)
    else
    if (time1 < 0) and (time2 < 0) then
      timeToHit := 0
    else
      timeToHit := Math.max(time1, time2);
  end
  else
    timeToHit := 0;

  if timeToHit <> 0 then
  begin
    jitter := PROJECTILE_JITTER[aProjType]
            + KMLength(KMPOINTF_ZERO, targetVector) * PROJECTILE_PREDICT_JITTER[aProjType];

    //Calculate the target position relative to start position (the 0;0)
    target.X := targetPosition.X + targetVector.X*timeToHit + KaMRandomS2(jitter{$IFDEF DBG_RNG_SPY}, 'TKMProjectiles.AimTarget 2'{$ENDIF});
    target.Y := targetPosition.Y + targetVector.Y*timeToHit + KaMRandomS2(jitter{$IFDEF DBG_RNG_SPY}, 'TKMProjectiles.AimTarget 3'{$ENDIF});

    //We can try and shoot at a target that is moving away,
    //but the arrows can't flight any further than their max_range
    distanceToHit := GetLength(target.X, target.Y);
    distanceInRange := EnsureRange(distanceToHit, aMinRange, aMaxRange);
    target.X := aStart.X + target.X / distanceToHit * distanceInRange;
    target.Y := aStart.Y + target.Y / distanceToHit * distanceInRange;

    //Calculate the arc, less for shorter flights
    arc := ((distanceInRange-aMinRange)/(aMaxRange-aMinRange))*(PROJECTILE_ARC[aProjType, 1] + KaMRandomS2(PROJECTILE_ARC[aProjType, 2]{$IFDEF DBG_RNG_SPY}, 'TKMProjectiles.AimTarget 4'{$ENDIF}));

    //Check whether this predicted target will hit a friendly unit
    if gTerrain.TileInMapCoords(Round(target.X), Round(target.Y)) then //Arrows may fly off map, UnitsHitTest doesn't like negative coordinates
    begin
      U := gTerrain.UnitsHitTest(Round(target.X), Round(target.Y));
      if (U <> nil) and (gHands.CheckAlliance(aOwner.Owner, U.Owner) = atAlly) then
        target := aTarget.PositionF; //Shoot at the target's current position instead
    end;

    Result := AddItem(aStart, aTarget.PositionF, target, speed, arc, aMaxRange, aProjType, aOwner);

    //Tell the Opponent that he is under attack (when arrows are in the air)
    gHands[aTarget.Owner].AI.UnitAttackNotification(aTarget, aOwner);
  end else
    Result := 0;
end;


function TKMProjectiles.AimTargetHouse(const aStart: TKMPointF; aTarget: TKMHouse; aProjType: TKMProjectileType; aOwner: TKMUnit; aMaxRange, aMinRange: Single): Word;
var
  speed, arc: Single;
  distanceToHit, distanceInRange: Single;
  aim, target: TKMPointF;
begin
  speed := PROJECTILE_SPEED[aProjType] + KaMRandomS2(0.05{$IFDEF DBG_RNG_SPY}, 'TKMProjectiles.AimTarget 5'{$ENDIF});

  aim := KMPointF(aTarget.GetRandomCellWithin);
  target.X := aim.X + KaMRandomS2(PROJECTILE_JITTER_HOUSE[aProjType]{$IFDEF DBG_RNG_SPY}, 'TKMProjectiles.AimTarget 6'{$ENDIF}); //So that arrows were within house area, without attitude to tile corners
  target.Y := aim.Y + KaMRandomS2(PROJECTILE_JITTER_HOUSE[aProjType]{$IFDEF DBG_RNG_SPY}, 'TKMProjectiles.AimTarget 7'{$ENDIF});

  //Calculate the arc, less for shorter flights
  distanceToHit := GetLength(aStart.X - target.X, aStart.Y - target.Y);
  distanceInRange := EnsureRange(distanceToHit, aMinRange, aMaxRange);

  var arcRandom := KaMRandomS2(PROJECTILE_ARC[aProjType, 2]{$IFDEF DBG_RNG_SPY}, 'TKMProjectiles.AimTarget 8'{$ENDIF});
  arc := Math.Max((distanceInRange - aMinRange) / (aMaxRange - aMinRange) * PROJECTILE_ARC[aProjType, 1] + arcRandom, 0);

  Result := AddItem(aStart, aim, target, speed, arc, aMaxRange, aProjType, aOwner);
end;


// Return flight time (archers like to know when they hit target before firing again)
function TKMProjectiles.AddItem(const aStart, aAim, aEnd: TKMPointF; aSpeed, aArc, aMaxLength: Single; aProjType: TKMProjectileType; aOwner: TKMUnit): Word;
const
  // TowerRock position is a bit different for reasons said below
  // Recruit stands in entrance, Tower middleline is X-0.75
  OFFSET_X: array [TKMDirection] of array [TKMProjectileType] of Single =
    ((0.5, 0.5, 0.5, -0.25),  // dirNA
     (0.5, 0.5, 0.7, -0.25),  // dirN
     (1.0, 0.5, 0.7, -0.25),  // dirNE
     (0.7, 0.5, 0.7, -0.25),  // dirE
     (0.7, 0.5, 0.7, -0.25),  // dirSE
     (0.4, 0.4, 0.3, -0.25),  // dirS
     (0.4, 0.4, 0.5, -0.25),  // dirSW
     (0.4, 0.4, 0.5, -0.25),  // dirW
     (0.3, 0.5, 0.5, -0.25)); // dirNW
  // Add towers height
  OFFSET_Y: array [TKMDirection] of array [TKMProjectileType] of Single =
    ((0.2, 0.2, 0.2, -0.2),  // dirNA
     (0.2, 0.2, 0.2, -0.2),  // dirN
     (0.0, 0.6, 0.5, -0.2),  // dirNE
     (0.3, 0.35,0.3, -0.2),  // dirE
     (0.5, 0.4, 0.5, -0.2),  // dirSE
     (0.3, 0.2, 0.4, -0.2),  // dirS
     (0.4, 0.4, 0.2, -0.2),  // dirSW
     (0.2, 0.3, 0.3, -0.2),  // dirW
     (0.1, 0.3, 0.3, -0.2)); // dirNW
var
  I: Integer;
begin
  I := -1;
  repeat
    Inc(I);
    if I >= Length(fItems) then
      SetLength(fItems, I+8); //Add new
  until(fItems[I].fSpeed = 0);

  //Fill in basic info
  fItems[I].fType   := aProjType;
  fItems[I].fSpeed  := aSpeed;
  fItems[I].fArc    := aArc;
  fItems[I].fOwner  := aOwner.GetPointer;
  fItems[I].fAim    := aAim;
  //Don't allow projectile to land off map, (we use fTaret for hit tests, FOW, etc.) but on borders is fine
  fItems[I].fTarget.X := EnsureRange(aEnd.X, 0, gTerrain.MapX-0.01);
  fItems[I].fTarget.Y := EnsureRange(aEnd.Y, 0, gTerrain.MapY-0.01);
  fItems[I].fShotFrom := aStart;

  fItems[I].fScreenStart.X := aStart.X + OFFSET_X[aOwner.Direction, aProjType];
  fItems[I].fScreenStart.Y := gTerrain.FlatToHeight(aStart).Y + OFFSET_Y[aOwner.Direction, aProjType];
  fItems[I].fScreenEnd.X := fItems[I].fTarget.X + 0.5; //projectile hits on Unit's chest height
  fItems[I].fScreenEnd.Y := gTerrain.FlatToHeight(fItems[I].fTarget).Y + 0.5;

  fItems[I].fPosition := 0; //projectile position on its route
  fItems[I].fLength   := KMLength(fItems[I].fScreenStart, fItems[I].fScreenEnd); //route length
  fItems[I].fMaxLength:= aMaxLength;

  if (gMySpectator.FogOfWar.CheckTileRevelation(KMPointRound(aStart).X, KMPointRound(aStart).Y) >= 255) then
    gSoundPlayer.Play(PROJECTILE_LAUNCH_SOUND[aProjType], aStart);

  Result := Round(fItems[I].fLength / fItems[I].fSpeed);
end;


//Update all items positions and kill some targets
procedure TKMProjectiles.UpdateState;
const
  H_TICKS = 6; //The number of ticks before hitting that an arrow will make the hit noise
var
  I: Integer;
  U: TKMUnit;
  H: TKMHouse;
  Damage: Smallint;
begin
  for I := 0 to Length(fItems) - 1 do
    with fItems[I] do
      if fSpeed <> 0 then
      begin
        fPosition := fPosition + fSpeed;

        //Will hit the target in X..X-1 ticks (this ensures it only happens once)
        //Can't use InRange cos it might get called twice due to <= X <= comparison
        if gMySpectator.FogOfWar.CheckRevelation(fTarget) >= 255 then
          if (fLength - H_TICKS*fSpeed <= fPosition) and (fPosition < fLength - (H_TICKS - 1) * fSpeed) then
            gSoundPlayer.Play(PROJECTILE_HIT_SOUND[fType], fTarget);

        if fPosition >= fLength then
        begin
          U := gTerrain.UnitsHitTestF(fTarget);
          //Projectile can miss depending on the distance to the unit
          if (U = nil) or ((1 - Math.Min(KMLength(U.PositionF, fTarget), 1)) > KaMRandom({$IFDEF DBG_RNG_SPY}'TKMProjectiles.UpdateState'{$ENDIF})) then
          begin
            case fType of
              ptArrow,
              ptSlingRock,
              ptBolt:      if (U <> nil) and not U.IsDeadOrDying and U.Visible and not (U is TKMUnitAnimal)
                            //Can't hit units past max range because that's unintuitive/confusing to player
                            and (KMLengthSqr(fShotFrom, U.PositionF) <= Sqr(fMaxLength)) then
                            begin
                              Damage := 0;
                              if fType = ptArrow then Damage := gRes.Units[utBowman].Attack;
                              if fType = ptBolt then Damage := gRes.Units[utCrossbowman].Attack;
                              if fType = ptSlingRock then Damage := gRes.Units[utRogue].Attack;
                              Damage := Round(Damage / Math.max(gRes.Units[U.UnitType].GetDefenceVsProjectiles(fType = ptBolt), 1)); //Max is not needed, but animals have 0 defence
                              if (FRIENDLY_FIRE or (gHands.CheckAlliance(fOwner.Owner, U.Owner)= atEnemy))
                              and (Damage >= KaMRandom(101{$IFDEF DBG_RNG_SPY}, 'TKMProjectiles.UpdateState'{$ENDIF})) then
                                U.HitPointsDecrease(1, fOwner);
                            end
                            else
                            begin
                              H := gHands.HousesHitTest(Round(fTarget.X), Round(fTarget.Y));
                              if (H <> nil)
                              and (FRIENDLY_FIRE or (gHands.CheckAlliance(fOwner.Owner, H.Owner)= atEnemy))
                              then
                                H.AddDamage(1, fOwner);
                            end;
              ptTowerRock: if (U <> nil) and not U.IsDeadOrDying and U.Visible
                            and not (U is TKMUnitAnimal)
                            and (FRIENDLY_FIRE or (gHands.CheckAlliance(fOwner.Owner, U.Owner)= atEnemy)) then
                              U.HitPointsDecrease(U.HitPointsMax, fOwner); //Instant death
            end;
          end;
          RemItem(I);
        end;
      end;
end;


procedure TKMProjectiles.AddProjectileToRenderPool(aProj: TKMProjectileType; const aRenderPos, aTilePos: TKMPointF; aDir: TKMDirection; aFlight: Single);
begin
  if Assigned(fOnAddProjectileToRenderPool) then
    fOnAddProjectileToRenderPool(aProj, aRenderPos, aTilePos, aDir, aFlight);
end;


//Test wherever projectile is visible (used by rocks thrown from Towers)
function TKMProjectiles.ProjectileVisible(aIndex: Integer): Boolean;
begin
  if (fItems[aIndex].fType = ptTowerRock)
  and ((fItems[aIndex].fScreenEnd.Y - fItems[aIndex].fScreenStart.Y) < 0) then
    Result := fItems[aIndex].fPosition >= 0.2 //fly behind a Tower
  else
    Result := True;
end;


procedure TKMProjectiles.Paint(aTickLag: Single);
var
  I: Integer;
  mixValue, mixValueMax, tickLagOffset, laggedPosition: Single;
  mixArc: Single; //mix Arc shape
  P: TKMPointF; //Arrows and bolts send 2 points for head and tail
  pTileBased: TKMPointF;
  dir: TKMDirection;
begin
  for I := 0 to Length(fItems) - 1 do
    if (fItems[I].fSpeed <> 0) and ProjectileVisible(I) then
    begin
      tickLagOffset := aTickLag*fItems[I].fSpeed;
      laggedPosition := fItems[I].fPosition - tickLagOffset;
      //If the projectile hasn't appeared yet in lagged time
      if laggedPosition < 0 then Continue;

      mixValue := EnsureRange(laggedPosition / fItems[I].fLength, 0.0, 1.0); // 0 >> 1
      mixValueMax := EnsureRange(laggedPosition / fItems[I].fMaxLength, 0.0, 1.0); // 0 >> 1
      P := KMLerp(fItems[I].fScreenStart, fItems[I].fScreenEnd, mixValue);
      pTileBased := KMLerp(fItems[I].fShotFrom, fItems[I].fTarget, mixValue);
      case fItems[I].fType of
        ptArrow, ptSlingRock, ptBolt:
          begin
            mixArc := sin(mixValue*pi);   // 0 >> 1 >> 0 Parabola
            //Looks better moved up, launches from the bow not feet and lands in target's body
            P.Y := P.Y - fItems[I].fArc * mixArc - 0.4;
            dir := KMGetDirection(fItems[I].fScreenStart, fItems[I].fScreenEnd);
            AddProjectileToRenderPool(fItems[I].fType, P, pTileBased, dir, mixValueMax);
          end;

        ptTowerRock:
          begin
            mixArc := cos(mixValue*pi/2); // 1 >> 0      Half-parabola
            //Looks better moved up, lands on the target's body not at his feet
            P.Y := P.Y - fItems[I].fArc * mixArc - 0.4;
            AddProjectileToRenderPool(fItems[I].fType, P, pTileBased, dirN, mixValue); //Direction will be ignored
          end;
      end;

      if SHOW_PROJECTILES then
      begin
        gRenderAux.Projectile(fItems[I].fScreenStart.X,
                              fItems[I].fScreenStart.Y,
                              fItems[I].fScreenEnd.X,
                              fItems[I].fScreenEnd.Y);

        gRenderAux.Projectile(fItems[I].fAim.X,
                              fItems[I].fAim.Y,
                              fItems[I].fTarget.X,
                              fItems[I].fTarget.Y);
      end;
    end;
end;


procedure TKMProjectiles.Save(SaveStream: TKMemoryStream);
var
  I, liveCount: Integer;
begin
  SaveStream.PlaceMarker('Projectiles');

  //Strip dead projectiles
  liveCount := 0;
  for I := 0 to Length(fItems) - 1 do
    //if fItems[I].fSpeed <> 0 then // This causes desynchronization in replay
      Inc(liveCount);

  SaveStream.Write(liveCount);

  for I := 0 to Length(fItems) - 1 do
    //if fItems[I].fSpeed <> 0 then // This causes desynchronization in replay
    begin
      SaveStream.Write(fItems[I].fScreenStart);
      SaveStream.Write(fItems[I].fScreenEnd);
      SaveStream.Write(fItems[I].fAim);
      SaveStream.Write(fItems[I].fTarget);
      SaveStream.Write(fItems[I].fShotFrom);
      SaveStream.Write(fItems[I].fType, SizeOf(TKMProjectileType));
      SaveStream.Write(fItems[I].fOwner.UID); //Store ID
      SaveStream.Write(fItems[I].fSpeed);
      SaveStream.Write(fItems[I].fArc);
      SaveStream.Write(fItems[I].fPosition);
      SaveStream.Write(fItems[I].fLength);
      SaveStream.Write(fItems[I].fMaxLength);
    end;
end;


procedure TKMProjectiles.Load(LoadStream: TKMemoryStream);
var
  I, newCount: Integer;
begin
  LoadStream.CheckMarker('Projectiles');

  LoadStream.Read(newCount);
  SetLength(fItems, newCount);

  for I := 0 to newCount - 1 do
  begin
    LoadStream.Read(fItems[I].fScreenStart);
    LoadStream.Read(fItems[I].fScreenEnd);
    LoadStream.Read(fItems[I].fAim);
    LoadStream.Read(fItems[I].fTarget);
    LoadStream.Read(fItems[I].fShotFrom);
    LoadStream.Read(fItems[I].fType, SizeOf(TKMProjectileType));
    LoadStream.Read(fItems[I].fOwner, 4);
    LoadStream.Read(fItems[I].fSpeed);
    LoadStream.Read(fItems[I].fArc);
    LoadStream.Read(fItems[I].fPosition);
    LoadStream.Read(fItems[I].fLength);
    LoadStream.Read(fItems[I].fMaxLength);
  end;
end;


procedure TKMProjectiles.SyncLoad;
var
  I: Integer;
begin
  inherited;

  for I := 0 to Length(fItems) - 1 do
    fItems[I].fOwner := gHands.GetUnitByUID(Integer(fItems[I].fOwner));
end;


end.
