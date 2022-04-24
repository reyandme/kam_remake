unit KM_UnitActionStormAttack;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math,
  KM_CommonClasses, KM_Defaults, KM_Points, KM_CommonUtils,
  KM_Units;


{Charge forwards until we are tired or hit an obstacle}
type
  TKMUnitActionStormAttack = class(TKMUnitAction)
  private
    fDelay: Integer; //Delay before action starts
    fTileSteps: Integer; //The number of tiles we have walked onto so far
    fStamina: Integer; //How much stamina to run do we have
    fNextPos: TKMPoint; //The tile we are currently walking to
    fVertexOccupied: TKMPoint; //The diagonal vertex we are currently occupying
    procedure IncVertex(const aFrom, aTo: TKMPoint);
    procedure DecVertex;
  public
    constructor Create(aUnit: TKMUnit; aActionType: TKMUnitActionType; aRow: Integer);
    constructor Load(LoadStream: TKMemoryStream); override;
    destructor Destroy; override;
    function ActName: TKMUnitActionName; override;
    function CanBeInterrupted(aForced: Boolean = True): Boolean; override;
    function GetExplanation: UnicodeString; override;
    function GetSpeed: Single;
    function Execute: TKMActionResult; override;
    procedure Save(SaveStream: TKMemoryStream); override;
  end;

implementation
uses
  KM_Resource, KM_ResUnits, KM_UnitWarrior;


{ TUnitActionStormAttack }
constructor TKMUnitActionStormAttack.Create(aUnit: TKMUnit; aActionType: TKMUnitActionType; aRow: Integer);
const
  //Tiles traveled measured in KaM TPR: Min 8, maximum 13
  //We reduced the variation in order to make storm attack more useful
  MIN_STAMINA = 12;
  MAX_STAMINA = 13;
begin
  inherited Create(aUnit, aActionType, True);
  fTileSteps      := -1; //-1 so the first initializing step makes it 0
  fDelay          := aRow * 5; //No delay for the first row
  fStamina        := MIN_STAMINA + KaMRandom(MAX_STAMINA-MIN_STAMINA+1, 'TKMUnitActionStormAttack.Create');
  fNextPos        := KMPOINT_ZERO;
  fVertexOccupied := KMPOINT_ZERO;
end;


destructor TKMUnitActionStormAttack.Destroy;
begin
  if not KMSamePoint(fVertexOccupied, KMPOINT_ZERO) then
    DecVertex;
  inherited;
end;


constructor TKMUnitActionStormAttack.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.CheckMarker('UnitActionStormAttack');
  LoadStream.Read(fDelay);
  LoadStream.Read(fTileSteps);
  LoadStream.Read(fStamina);
  LoadStream.Read(fNextPos);
  LoadStream.Read(fVertexOccupied);
end;


function TKMUnitActionStormAttack.ActName: TKMUnitActionName;
begin
  Result := uanStormAttack;
end;


function TKMUnitActionStormAttack.GetExplanation: UnicodeString;
begin
  Result := 'Storming';
end;


procedure TKMUnitActionStormAttack.IncVertex(const aFrom, aTo: TKMPoint);
begin
  //Tell gTerrain that this vertex is being used so no other unit walks over the top of us
  Assert(KMSamePoint(fVertexOccupied, KMPOINT_ZERO), 'Storm vertex in use');
  //Assert(not gTerrain.HasVertexUnit(KMGetDiagVertex(aFrom,aTo)), 'Storm vertex blocked');

  fUnit.VertexAdd(aFrom,aTo); //Running counts as walking
  fVertexOccupied := KMGetDiagVertex(aFrom,aTo);
end;


procedure TKMUnitActionStormAttack.DecVertex;
begin
  //Tell gTerrain that this vertex is not being used anymore
  Assert(not KMSamePoint(fVertexOccupied, KMPOINT_ZERO), 'DecVertex 0:0 Storm');

  fUnit.VertexRem(fVertexOccupied);
  fVertexOccupied := KMPOINT_ZERO;
end;


function TKMUnitActionStormAttack.GetSpeed: Single;
begin
  if (fTileSteps <= 0) or (fTileSteps >= fStamina-1) then
    Result := gRes.Units[fUnit.UnitType].GetEffectiveWalkSpeed(DIAG_DIRECTION[fUnit.Direction])
  else
    Result := gRes.Units[fUnit.UnitType].GetEffectiveStormSpeed(DIAG_DIRECTION[fUnit.Direction]);
end;


function TKMUnitActionStormAttack.Execute: TKMActionResult;
var
  dx, dy: ShortInt;
  walkX, walkY, distance: Single;
  isWalking, isDiag: Boolean;
begin
  if KMSamePoint(fNextPos, KMPOINT_ZERO) then
    fNextPos := fUnit.Position; //Set fNextPos to current pos so it initializes on the first run

  //Walk for the first step before running
  if fDelay > 0 then
  begin
    Dec(fDelay);
    fUnit.AnimStep := UNIT_STILL_FRAMES[fUnit.Direction];
    Exit(arActContinues);
  end;

  //Last step is walking, others are running (unit gets tired and slows at the end)
  //In KaM the first step was also walking, but this makes it less useful/surprising

  isWalking := (fTileSteps >= fStamina - 1);
  if isWalking then
  begin
    // Use umtWalk move type here, since we just want to evaluate if we are close enough
    distance := gRes.Units[fUnit.UnitType].GetEffectiveWalkSpeed(False);
    fType := uaWalk;
  end else begin
    distance := gRes.Units[fUnit.UnitType].GetEffectiveStormSpeed(False);
    fType := uaSpec;
  end;

  if KMSamePointF(fUnit.PositionF, KMPointF(fNextPos), distance/2) then
  begin
    Inc(fTileSteps); //We have stepped on a new tile
    //Set precise position to avoid rounding errors
    fUnit.PositionF := KMPointF(fNextPos);

    //No longer using previous vertex
    if KMStepIsDiag(fUnit.PositionPrev, fUnit.PositionNext) and (fTileSteps > 0) then
      DecVertex;

    //Check for units nearby to fight
    Locked := False; //Unlock during this check only so CheckForEnemy can abandon our action
    if (fUnit is TKMUnitWarrior) then
      if TKMUnitWarrior(fUnit).CheckForEnemy then
      begin
        //If we've picked a fight it means this action no longer exists,
        //so we must exit out (don't set ActDone as that will now apply to fight action)
        Exit(arActContinues);
      end;
    Locked := True; //Finished CheckForEnemy, so lock again

    //Begin the next step
    fNextPos := KMGetPointInDir(fUnit.Position, fUnit.Direction);

    //Action ends if: 1: Used up stamina. 2: There is an enemy to fight. 3: NextPos is an obsticle
    if (fTileSteps >= fStamina) or not fUnit.CanStepTo(fNextPos.X, fNextPos.Y, fUnit.DesiredPassability) then
      Exit(arActDone); //Finished run; Must exit right away as we might have changed this action to fight

    //Do some house keeping because we have now stepped on a new tile
    fUnit.PositionNext := fNextPos;
    fUnit.Walk(fUnit.PositionPrev, fUnit.PositionNext); //Pre-occupy next tile
    if KMStepIsDiag(fUnit.PositionPrev,fUnit.PositionNext) then
      IncVertex(fUnit.PositionPrev,fUnit.PositionNext);
  end;

  walkX := fNextPos.X - fUnit.PositionF.X;
  walkY := fNextPos.Y - fUnit.PositionF.Y;
  dx := Sign(walkX); //-1,0,1
  dy := Sign(walkY); //-1,0,1

  isDiag := (dx <> 0) and (dy <> 0);
  if isWalking then
    distance := gRes.Units[fUnit.UnitType].GetEffectiveWalkSpeed(isDiag)
  else
    distance := gRes.Units[fUnit.UnitType].GetEffectiveStormSpeed(isDiag);

  fUnit.PositionF := KMPointF(fUnit.PositionF.X + dx*Math.min(distance, Abs(walkX)),
                              fUnit.PositionF.Y + dy*Math.min(distance, Abs(walkY)));

  Inc(fUnit.AnimStep);
  StepDone := false; //We are not actually done because now we have just taken another step
  Result := arActContinues;
end;


procedure TKMUnitActionStormAttack.Save(SaveStream: TKMemoryStream);
begin
  inherited;

  SaveStream.PlaceMarker('UnitActionStormAttack');
  SaveStream.Write(fDelay);
  SaveStream.Write(fTileSteps);
  SaveStream.Write(fStamina);
  SaveStream.Write(fNextPos);
  SaveStream.Write(fVertexOccupied);
end;


function TKMUnitActionStormAttack.CanBeInterrupted(aForced: Boolean = True): Boolean;
begin
  Result := not Locked; //Never interupt storm attack
end;


end.
