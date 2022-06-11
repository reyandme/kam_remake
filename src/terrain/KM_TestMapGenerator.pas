unit KM_TestMapGenerator;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLType, {$ENDIF}
  KM_CommonTypes, KM_Terrain, Math, SysUtils,
  KM_Controls, KM_Defaults, KM_Pics, KM_Minimap,
  KM_Points, KM_RMGUtils, KM_TerrainTypes, KM_CommonClasses;


type

  TTileParts = record // This construction allows to make search classes universal (they will work with TKMByte2Array instead of TTileParts)
    Terrain: TKMWord2Array;
    Rotation, Height, Obj: TKMByte2Array;
  end;
  TKMLayoutType = (mtRandomPlace, mtRandomGroups, mtDefense, mtOffense);
  TKMArmyType = (atMelee, atAntiHorse, atRanged, atMounted, atAll, atNoMounted, atNoRanged, atMoreRanged);


  TKMTestMapSettings = record
    Map: record
      MaxX, MaxY, Number, Seed: Integer;
    end;
    Obstacle: record
      WalkableTile, NonWalkableTile, VoronoiStep: Integer;
      RndPointsInRadius: record
        Variance, Size, Radius: Single;
      end;
      RandomWalk: record
        ObstacleSize, ObstacleVariance, ExpandRestriction: Single;
      end;
    end;
    Army: record
      NewAIGroupRatio: Single;
      Layout: TKMLayoutType;
      SpaceBetweenGroups: Integer;
      VarianceCnt: Integer; // AI 2 variance of group count
      GroupsCnt: Single;
      ArmyType: TKMArmyType;
    end;
    AISettings: record
      ScriptedAttack: boolean;  // AI 2 auto attack range
      AttackRange: Integer; // AI 2 auto attack range
    end;
  end;


  TKMTestMapGenerator = class
  private
    fMapX, fMapY: Word;
    fRNG: TKMRandomNumberGenerator;

    procedure RandomizeSettings();

    procedure GenerateMap();
    function VoronoiMod(const aStep: Integer; var aPoints: TKMPoint2Array): TInteger2Array;
    function RNDPointInCircle(aMin,aMax,aCenter: TKMPoint; aMaxRadius: Single): TKMPoint;
    function RNDPointsInGrid(const aCnt: Single; aSpace: Integer; const aMinimum,aMaximum: TKMPoint): TKMPointArray;
    procedure CreateObstacles(var A: TKMByte2Array);
    procedure CreateArmies();
    procedure SetMapSettings();
  public
    Settings: TKMTestMapSettings;

    constructor Create;
    destructor Destroy; override;

    procedure CreateMap(aMapName: String);
    procedure CreateMaps();
  end;


implementation
uses
  KM_Game, KM_GameTypes,
  KM_RenderUI, KM_HandsCollection,
  KM_ResTexts, KM_ResFonts, KM_ResTypes,
  KM_UnitGroup, KM_Units, KM_MapTypes, KM_GameParams, KM_AIAttacks, KM_AITypes;


{ TKMTestMapGenerator }
constructor TKMTestMapGenerator.Create;
begin
  inherited;
  fRNG := TKMRandomNumberGenerator.Create;
  fRNG.Seed := 1386438438;
end;


destructor TKMTestMapGenerator.Destroy;
begin
  fRNG.Free;
  inherited;
end;


procedure TKMTestMapGenerator.RandomizeSettings();
begin
  // Change settings
  with Settings.Map do
  begin
    MaxX := 128;
    MaxY := 128;
    Number := 1;
    Seed := fRNG.RandomI(High(Integer));
  end;
  with Settings.Obstacle do
  begin
    WalkableTile := 35;
    NonWalkableTile := 245;
    VoronoiStep := 3;
    RndPointsInRadius.Variance   := 0.4 + fRNG.Random()*0.2;
    RndPointsInRadius.Size       := 4   + fRNG.RandomI(3);
    RndPointsInRadius.Radius     := 2   + fRNG.RandomI(3);
    RandomWalk.ObstacleSize      := 4   + fRNG.RandomI(5);
    RandomWalk.ObstacleVariance  := 0.1 + fRNG.Random()*0.1;
    RandomWalk.ExpandRestriction := 1   + fRNG.RandomI(2);
  end;
  with Settings.Army do
  begin
    NewAIGroupRatio := 0.4;
    Layout := mtRandomPlace;
    SpaceBetweenGroups := 5;
    GroupsCnt := 20 + fRNG.RandomI(20);
    VarianceCnt := 6 + fRNG.RandomI(2);
    ArmyType := atAll;
  end;
  with Settings.AISettings do
  begin
    ScriptedAttack := True;
    AttackRange := 3;
  end;
end;


procedure TKMTestMapGenerator.CreateMaps();
var
  K: Integer;
  procedure ChangeSettings(aLayout: TKMLayoutType; aArmy: TKMArmyType; aRatio: Single; aScriptedAttack: boolean);
  begin
    Settings.Army.Layout := aLayout;
    Settings.Army.ArmyType := aArmy;
    Settings.Army.NewAIGroupRatio := 0.4 + (1 - aRatio) * 0.3 - Byte(aLayout = mtOffense) * 0.15 + Byte(aScriptedAttack) * 0.05;
    Settings.AISettings.ScriptedAttack := aScriptedAttack;
    Settings.AISettings.AttackRange := 0;
    if not aScriptedAttack then
      Settings.AISettings.AttackRange := fRNG.RandomI(10) + Byte(aLayout = mtOffense) * 10;
  end;
  function ifThenArmy(aChoise: boolean; aArmy1, aArmy2: TKMArmyType): TKMArmyType;
  begin
    Result := aArmy2;
    if (aChoise) then
      Result := aArmy1;
  end;
  procedure RandomPlaceNoRanged(aOrder: Single);
  begin
    ChangeSettings(mtRandomPlace, atNoRanged, aOrder, boolean(K mod 2));
  end;
  procedure RandomPlaceAll(aOrder: Single);
  begin
    ChangeSettings(mtRandomPlace, ifThenArmy(K mod 2 > 0, atNoMounted, atAll), aOrder,  boolean(K mod 2));
  end;
  procedure DefenceNoRanged(aOrder: Single);
  begin
    ChangeSettings(mtDefense, atNoRanged, aOrder, True);
  end;
  procedure DefenceAll(aOrder: Single);
  begin
    ChangeSettings(mtDefense, ifThenArmy(K mod 2 > 0, atNoMounted, atMoreRanged), aOrder, True);
  end;
  procedure RandomGroupsNoRanged(aOrder: Single);
  begin
    ChangeSettings(mtRandomGroups, atNoRanged, aOrder, boolean(K mod 3));
  end;
  procedure RandomGroupsAll(aOrder: Single);
  begin
    ChangeSettings(mtRandomGroups, ifThenArmy(K mod 2 > 0, atNoMounted, atMoreRanged), aOrder, boolean(K mod 3));
  end;
  procedure OffenceNoRanged(aOrder: Single);
  begin
    ChangeSettings(mtOffense, atNoRanged, aOrder, False);
  end;
  procedure OffenceAll(aOrder: Single);
  begin
    ChangeSettings(mtOffense, ifThenArmy(K mod 2 > 0, atNoMounted, atMoreRanged), aOrder, False);
  end;
const
  OFFSET = 10;
  G0 = 0;
  G1 = 10;
  G2 = 20;
  G3 = 30;
  G4 = 40;
  G5 = 50;
  G6 = 60;
  G7 = 70;
  G8 = 80;
begin
  for K := 1 to G8 do
  begin
    RandomizeSettings();
    Settings.Map.Number := K;
    if      (K > G0) AND (K <= G1) then OffenceNoRanged      (1.0 - (G1 - K)/(G1 - G0))
    else if (K > G1) AND (K <= G2) then OffenceAll           (1.0 - (G2 - K)/(G2 - G1))
    else if (K > G2) AND (K <= G3) then DefenceNoRanged      (1.0 - (G3 - K)/(G3 - G2))
    else if (K > G3) AND (K <= G4) then DefenceAll           (1.0 - (G4 - K)/(G4 - G3))
    else if (K > G4) AND (K <= G5) then RandomGroupsNoRanged (1.0 - (G5 - K)/(G5 - G4))
    else if (K > G5) AND (K <= G6) then RandomGroupsAll      (1.0 - (G6 - K)/(G6 - G5))
    else if (K > G6) AND (K <= G7) then RandomPlaceNoRanged  (1.0 - (G7 - K)/(G7 - G6))
    else if (K > G7) AND (K <= G8) then RandomPlaceAll       (1.0 - (G8 - K)/(G8 - G7))
    else begin end;

    CreateMap(Format('GA_S2_%.*d',[3, K + OFFSET]));
  end;
end;


procedure TKMTestMapGenerator.CreateMap(aMapName: String);
begin
  // Create fake game
  gGame := TKMGame.Create(gmMapEd);
  try
    fMapX := Settings.Map.MaxX;
    fMapY := Settings.Map.MaxY;
    fRNG.Seed := Settings.Map.Seed;
    // Create empty map in background
    gGame.MapEdStartEmptyMap(fMapX, fMapY);
    // Generate map
    GenerateMap();
    // Generate army
    CreateArmies();
    // Change map settings
    SetMapSettings();
    // Save map MP = MAPS_MP_FOLDER_NAME, SP = MAPS_FOLDER_NAME
    gGame.SaveMapEditor(Format('%s\%s\%s\%s.dat',[ExtractFilePath(ParamStr(0)), MAPS_FOLDER_NAME, aMapName, aMapName]));
  finally
    gGame.Free;
    gGame := nil;
  end;
end;


procedure TKMTestMapGenerator.CreateArmies();
type
  TKMArmyLayout = array[1..2] of TKMPointArray;
const

  ARMY: array[0..12] of TKMUnitType = (
    utMilitia,      utAxeFighter,   utSwordFighter,  utBowman,
    utCrossbowman,  utLanceCarrier, utPikeman,       utScout,
    utKnight,       utBarbarian,
    utRebel,        utRogue,        utVagabond // utWarrior, // Skip second barbarian because of identical stats
  );
  ARMY_MELEE:     array[0..3] of TKMUnitType = (utMilitia, utAxeFighter, utSwordFighter, utBarbarian);
  ARMY_ANTIHORSE: array[0..2] of TKMUnitType = (utRebel, utPikeman, utLanceCarrier);
  ARMY_RANGED:    array[0..2] of TKMUnitType = (utRogue, utBowman, utCrossbowman);
  ARMY_MOUNTED:   array[0..2] of TKMUnitType = (utVagabond, utScout, utKnight);

  procedure CreateLayout(var aLayout: TKMArmyLayout);
  var
    K, L, PL1Len, cnt1, cnt2, sqrtCnt, rndCnt, rndIdx: Integer;
    points: TKMPointArray;
  begin
    case Settings.Army.Layout of
      mtRandomPlace:
      begin
        points := RNDPointsInGrid(Settings.Army.GroupsCnt, Settings.Army.SpaceBetweenGroups, KMPoint(5,5), KMPoint(fMapX-5,fMapY-5));
        setLength(aLayout[1], length(Points));
        setLength(aLayout[2], length(Points));
        cnt1 := 0;
        cnt2 := 0;
        for K := Low(points) to High(points) do
        begin
          if (fRNG.Random() < Settings.Army.NewAIGroupRatio) then
          begin
            aLayout[1,cnt1] := points[K];
            Inc(cnt1);
          end
          else
          begin
            aLayout[2,cnt2] := points[K];
            Inc(cnt2);
          end;
        end;
        setLength(aLayout[1], cnt1);
        setLength(aLayout[2], cnt2);
      end;
      mtRandomGroups:
      begin
        points := RNDPointsInGrid(Round(Settings.Army.GroupsCnt/4), Settings.Army.SpaceBetweenGroups*3, KMPoint(5,5), KMPoint(fMapX-5,fMapY-5));
        rndCnt := Round(Length(points) * Settings.Army.NewAIGroupRatio);
        for K := Low(points) to High(points) do
        begin
          rndIdx := K + fRNG.RandomI(length(points) - K);
          rndCnt := rndCnt - 1;
          if (rndCnt > 0) then
          begin
            cnt1 := Length(aLayout[1]);
            SetLength(aLayout[1], Length(aLayout[1]) + 2 + fRNG.RandomI(3));
            for L := cnt1 to High(aLayout[1]) do
              aLayout[1,L] := RNDPointInCircle(KMPoint(5,5),KMPoint(fMapX-5,fMapY-5),points[rndIdx], 5);
            points[rndIdx] := points[K];
          end
          else
          begin
            cnt1 := Length(aLayout[2]);
            SetLength(aLayout[2], Length(aLayout[2]) + 2 + fRNG.RandomI(3));
            for L := cnt1 to High(aLayout[2]) do
              aLayout[2,L] := RNDPointInCircle(KMPoint(5,5),KMPoint(fMapX-5,fMapY-5),points[K], 5);
          end;
        end;
      end;
      mtOffense, mtDefense:
      begin
        points := RNDPointsInGrid(Settings.Army.GroupsCnt, Settings.Army.SpaceBetweenGroups, KMPoint(5,5), KMPoint(fMapX-5,fMapY-5));
        sqrtCnt := Round(sqrt(Settings.Army.GroupsCnt)/2); // Create space between north and south
        PL1Len := Round(length(Points) * Settings.Army.NewAIGroupRatio - sqrtCnt);
        setLength(aLayout[1], PL1Len);
        setLength(aLayout[2], length(Points) - PL1Len - sqrtCnt * 2);
        move(points[0], aLayout[1,0], sizeof(points[0]) * Length(aLayout[1]));
        move(points[PL1Len + sqrtCnt * 2], aLayout[2,0], sizeof(points[0]) * Length(aLayout[2]));
      end;
    end;
  end;
var
  count, column, PL, K: Integer;
  dir: TKMDirection;
  //G: TKMUnitGroup;
  U: TKMUnit;
  UT: TKMUnitType;
  armyLayout: TKMArmyLayout;
begin
  // Create 3 units for 3 players so hands are active
  U := gHands[0].AddUnit(utSerf, KMPoint(1,1));
  if U <> nil then U.Condition := 10;
  U := gHands[1].AddUnit(utSerf, KMPoint(2,1));
  if U <> nil then U.Condition := 10;
  U := gHands[2].AddUnit(utSerf, KMPoint(3,1));
  if U <> nil then U.Condition := 10;

  // Default settings
  dir := dirN; // (dirNA, dirN, dirNE, dirE, dirSE, dirS, dirSW, dirW, dirNW);
  UT := utMilitia;

  // Layout
  CreateLayout(armyLayout);

  // Player
  for PL := Low(armyLayout) to High(armyLayout) do
    for K := Low(armyLayout[PL]) to High(armyLayout[PL]) do
    begin
      // Unit type
      if PL = 1 then
      begin
        count := 9;
        column := 3;
        case Settings.Army.ArmyType of
          atMelee:     UT := ARMY_MELEE    [ fRNG.RandomI(length(ARMY_MELEE    )) ];
          atAntiHorse: UT := ARMY_ANTIHORSE[ fRNG.RandomI(length(ARMY_ANTIHORSE)) ];
          atMounted:   UT := ARMY_MOUNTED  [ fRNG.RandomI(length(ARMY_MOUNTED  )) ];
          atRanged:    UT := ARMY_RANGED   [ fRNG.RandomI(length(ARMY_RANGED   )) ];
          atNoMounted:
          begin
            case fRNG.RandomI(3) of
              0: UT := ARMY_MELEE    [ fRNG.RandomI(length(ARMY_MELEE    )) ];
              1: UT := ARMY_ANTIHORSE[ fRNG.RandomI(length(ARMY_ANTIHORSE)) ];
              2: UT := ARMY_RANGED   [ fRNG.RandomI(length(ARMY_RANGED  )) ];
            end;
          end;
          atNoRanged:
          begin
            case fRNG.RandomI(3) of
              0: UT := ARMY_MELEE    [ fRNG.RandomI(length(ARMY_MELEE    )) ];
              1: UT := ARMY_ANTIHORSE[ fRNG.RandomI(length(ARMY_ANTIHORSE)) ];
              2: UT := ARMY_MOUNTED  [ fRNG.RandomI(length(ARMY_MOUNTED  )) ];
            end;
          end;
          atMoreRanged:
          begin
            case fRNG.RandomI(5) of
              0: UT := ARMY_MELEE    [ fRNG.RandomI(length(ARMY_MELEE    )) ];
              1: UT := ARMY_ANTIHORSE[ fRNG.RandomI(length(ARMY_ANTIHORSE)) ];
              2: UT := ARMY_MOUNTED  [ fRNG.RandomI(length(ARMY_MOUNTED  )) ];
              3,4: UT := ARMY_RANGED [ fRNG.RandomI(length(ARMY_RANGED   )) ];
            end;
          end;
          else
            UT := ARMY[ fRNG.RandomI(length(ARMY)) ];
        end;
      end
      else
      begin
        UT := ARMY[ fRNG.RandomI(length(ARMY)) ];
        count := 9 + fRNG.RandomI(Settings.Army.VarianceCnt);
        column := Round(count / 3);
      end;
      // New group
      //G := gHands[PL].AddUnitGroup(UT, armyLayout[PL,K], dir, column, count);
      if (gTerrain.Land^[armyLayout[PL,K].Y,armyLayout[PL,K].X].IsUnit = nil) then
        gHands[PL].AddUnitGroup(UT, armyLayout[PL,K], dir, column, count);
    end;

end;


procedure TKMTestMapGenerator.SetMapSettings();
var
  K, PL: Integer;
  Revealers: TKMPointTagList;
begin
  // Player type
  for K := 0 to MAX_HANDS - 1 do
  begin
    gHands[K].CanBeHuman := False;
    gHands[K].AI.Setup.ApplyMultiplayerSetup(True);
    gHands[K].CenterScreen := KMPoint(fMapX shr 2,fMapY shr 2);
    Revealers := gGame.MapEditor.Revealers[K];
    Revealers.Clear;
    gGame.MapEditor.RevealAll[K] := True;
    gGame.MapEditor.PlayerHuman[K] := False;
    gGame.MapEditor.PlayerClassicAI[K] := False;
    gGame.MapEditor.PlayerAdvancedAI[K] := False;
  end;
  // Observer
  PL := 0;
  gGame.MapEditor.PlayerHuman[PL] := True;
  gHands[PL].CanBeHuman := True;
  gGame.MapEditor.DefaultHuman := 0;
  // New AI player
  PL := 1;
  gGame.MapEditor.PlayerAdvancedAI[PL] := True;
  // Old AI player
  PL := 2;
  gGame.MapEditor.PlayerClassicAI[PL] := True;
  gHands[PL].AI.Setup.ApplyMultiplayerSetup(False);
  gHands[PL].AI.Setup.AutoAttackRange := Settings.AISettings.AttackRange;
  gHands[PL].AI.Setup.AutoAttack := not Settings.AISettings.ScriptedAttack;
  if Settings.AISettings.ScriptedAttack then
  begin
    gHands[PL].AI.General.Attacks.AddAttack(
      aatRepeating, // TKMAIAttackType
      1, 1, // Delay TotalMen
      0, 0, 0, 0, // MeleeCount AntiHorseCount RangedCount MountedCount
      True, // TakeAll
      attClosestUnit, // Target
      0, // Range
      KMPoint(1,1) // CustomPosition
    );
  end;
  // Alliance
  gHands[0].Alliances[1] := atAlly;
  gHands[1].Alliances[0] := atAlly;

  // Update game info
  if (gGame <> nil) then
  begin
    if (Length(gGame.MapTxtInfo.Author) = 0) then
      gGame.MapTxtInfo.Author := 'Random number generator';
    if (Length(gGame.MapTxtInfo.SmallDesc) = 0) then
      gGame.MapTxtInfo.SmallDesc := 'Test map for combat AI';

    gGame.MapTxtInfo.IsRMG := False;
    gGame.MapTxtInfo.IsSpecial := True;
    gGame.MapTxtInfo.IsPlayableAsSP := True;
    gGame.MapTxtInfo.BlockTeamSelection := False;
    gGame.MapTxtInfo.BlockColorSelection := False;
    gGame.MapTxtInfo.BlockPeacetime := False;
    gGame.MapTxtInfo.BlockFullMapPreview := False;

    gGameParams.MissionMode := mmFighting;
  end;
end;


// Main procedure for RMG - requires also RMGSettings: TKMRMGSettings (global variable)
procedure TKMTestMapGenerator.GenerateMap();
var
  Y, X, K: Integer;
  A: TKMByte2Array;
  TilesPartsArr: TTileParts;
  Tiles: TKMTerrainTileBriefArray;
  Errors: TKMTerrainTileChangeErrorArray;
begin

  // Init arrays and variables
  SetLength(Tiles, 16);
  SetLength(Errors, 16);
  SetLength(A, fMapY+1, fMapX+1);
  SetLength(TilesPartsArr.Terrain,  Length(A), Length(A[0]));
  SetLength(TilesPartsArr.Rotation, Length(A), Length(A[0]));
  SetLength(TilesPartsArr.Height,   Length(A), Length(A[0]));
  SetLength(TilesPartsArr.Obj,      Length(A), Length(A[0]));
  for Y := Low(A) to High(A) do
  begin
    FillChar(A[Y,0], Length(A[Y])*SizeOf(A[Y,0]), #0);
    FillChar(TilesPartsArr.Obj[Y,0], Length(TilesPartsArr.Obj[Y])*SizeOf(TilesPartsArr.Obj[Y,0]), #255);
  end;

  // Create obstacles
  CreateObstacles(A);
  // Make sure tiles for 3 serfs are walkable
  A[1,1] := Settings.Obstacle.WalkableTile;
  A[1,2] := Settings.Obstacle.WalkableTile;
  A[1,3] := Settings.Obstacle.WalkableTile;

  // Update Tiles + Rotation, Height and Objects
  SetLength(Tiles, fMapY * fMapX);
  K := 0;
  for Y := 1 to fMapY-1 do
    for X := 1 to fMapX-1 do
    begin
      //K := (Y-1)*(fMapX-1)+X-1;
      Tiles[K].Y := Y;
      Tiles[K].X := X;
      Tiles[K].Terrain := A[Y,X];
      Tiles[K].Rotation := 0;
      Tiles[K].Height := 0;
      Tiles[K].Obj := 0;
      Tiles[K].UpdateTerrain := True;
      Tiles[K].UpdateRotation := True;
      Tiles[K].UpdateHeight := True;
      Tiles[K].UpdateObject := False;
      K := K + 1;
    end;
  gTerrain.ScriptTrySetTilesArray(Tiles, False, Errors);

end;


// Generator of random points inside circle
function TKMTestMapGenerator.RNDPointInCircle(aMin,aMax,aCenter: TKMPoint; aMaxRadius: Single): TKMPoint;
const
  MAX_ANGLE = 3.14*2; // = 360°
var
  angle, radius: Single;
begin
  // Random point in Polar coordinates
  angle := fRNG.Random() * MAX_ANGLE;
  radius := fRNG.Random() * aMaxRadius;
  // Back to Cartesian coordinates + check edges
  Result.X := Min(  aMax.X, Max( aMin.X,Round(aCenter.X + radius * cos(angle)) )  );
  Result.Y := Min(  aMax.Y, Max( aMin.Y,Round(aCenter.Y + radius * sin(angle)) )  );
end;


// Generator of random points with minimal distance between them (algorithmic from division into areas with indetical size = very fast)
function TKMTestMapGenerator.RNDPointsInGrid(const aCnt: Single; aSpace: Integer; const aMinimum,aMaximum: TKMPoint): TKMPointArray;
var
  X,X0,Y,Y0, i: Integer;
  Len, Step, Dist: TKMPoint;
  lenCnt, row, column: Single;
  Output: TKMPointArray;
begin
  Len := KMPoint(aMaximum.X - aMinimum.X, aMaximum.Y - aMinimum.Y);
  lenCnt := Max(1, Sqrt(Len.X * Len.Y / aCnt));

  // Compute count of column and row
  if (Len.X <= Len.Y) then
  begin
    column := Max(1, Round(Len.X / lenCnt));
    row := Ceil(aCnt / column);
  end
  else
  begin
    row := Max(1, Round(Len.Y / lenCnt));
    column := Ceil(aCnt / row);
  end;

  Step := KMPoint( Ceil(Len.X / column), Ceil(Len.Y / row) );
  Dist := KMpoint( Step.X - aSpace, Step.Y - aSpace );

  // Compute init points and distances
  X0 := aMinimum.X + (aSpace shr 1);
  Y0 := aMinimum.Y + (aSpace shr 1);
  if (dist.X < 0) then
  begin
    dist.X := 0;
    X0 := aMinimum.X + (Step.X shr 1);
  end;
  if (dist.Y < 0) then
  begin
    dist.Y := 0;
    Y0 := aMinimum.Y + (Step.Y shr 1);
  end;

  // Generate pseudorandom points (they are basicaly in inregular grid = quite balanced distribution)
  SetLength(Output, Ceil(row*column));
  i := 0;
  Y := Y0;
  while Y < aMaximum.Y do
  begin
    X := X0;
    while X < aMaximum.X do
    begin
      Output[I].X := Min(aMaximum.X, X + fRNG.RandomI(dist.X));
      Output[I].Y := Min(aMaximum.Y, Y + fRNG.RandomI(dist.Y));
      i := i + 1;
      X := X + Step.X;
    end;
    Y := Y + Step.Y;
  end;

  Result := Output;
end;


procedure TKMTestMapGenerator.CreateObstacles(var A: TKMByte2Array);
var
  FillObstacle: TKMFillBiome;
  P: TSingle2Array;
  PointsArr: TKMPoint2Array;
  Voronoi: TInteger2Array;


  procedure RndPointsInRadius(aX,aY: Integer);
  var
    X,Y, Cnt, MaxCnt, Overflow, MaxAttempt: Integer;
    Radius: Single;
    Point, MaxP, MinP: TKMPoint;
  begin
    MinP := KMPoint(Low(PointsArr[0]), Low(PointsArr));
    MaxP := KMPoint(High(PointsArr[0]), High(PointsArr));
    //RandomSize := 1 - fRNG.Random() * Settings.Obstacle.RndPointsInRadius.Variance;
    MaxCnt := Max(1, Round(Settings.Obstacle.RndPointsInRadius.Size));
    Radius := Max(1, Round(sqrt(MaxCnt)) * Settings.Obstacle.RndPointsInRadius.Radius);
    MaxAttempt := MaxCnt * 5;
    Overflow := 0;
    Cnt := 0;
    while (Cnt < MaxCnt) AND (Overflow < MaxAttempt) do
    begin
      Overflow := Overflow + 1;
      Point := RNDPointInCircle(MinP,MaxP,KMPoint(aX,aY),Radius);
      if (fRNG.Random() < P[Point.Y,Point.X]) AND (Voronoi[Point.Y,Point.X] <> 0) then
      begin
        X := PointsArr[ Point.Y, Point.X ].X;
        Y := PointsArr[ Point.Y, Point.X ].Y;
        FillObstacle.QuickFlood(X, Y, Voronoi[Y,X], 0, Settings.Obstacle.NonWalkableTile);
        Cnt := Cnt + 1;
      end;
    end;
  end;


  procedure RndWalk(aX,aY: Integer);
  var
    X,Y,X1,Y1,K, MaxIdx, MaxCnt, cntr, finalCnt: Integer;
    check: Boolean;
    ProbIdx: array[0..3] of Byte;
    Prob: array[0..3] of Single;
    Dir: array[0..3] of TKMPoint;
  begin
    X := aX;
    Y := aY;
    // Fill array A with obstacles with using random walk
    cntr := 0;
    finalCnt := Max(1,Round((1 - fRNG.Random() * Settings.Obstacle.RandomWalk.ObstacleVariance) * Settings.Obstacle.RandomWalk.ObstacleSize));
    check := True;
    while check AND (cntr < finalCnt) do
    begin
      // Scan surrounding points
      cntr := cntr + 1;
      Dir[0] := KMPoint( X, Min(Y+1, High(P)) );
      Dir[1] := KMPoint( X, Max(Y-1, Low(P)) );
      Dir[2] := KMPoint( Min(X+1, High(P[Y])), Y );
      Dir[3] := KMPoint( Max(X-1, Low(P[Y])), Y );

      // Get highest probability
      MaxIdx := 0;
      for K := Low(Dir) to High(Dir) do
      begin
        Prob[K] := P[Dir[K].Y,Dir[K].X];
        if (Prob[MaxIdx] < Prob[K]) then
          MaxIdx := K;
      end;
      // Mark all indexes with highest probability
      MaxCnt := 0;
      for K := Low(Dir) to High(Dir) do
        if (Prob[MaxIdx] = Prob[K]) then
        begin
          ProbIdx[MaxCnt] := K;
          MaxCnt := MaxCnt + 1;
        end;
      // Fill several surrounding shapes with our biome
      check := False;
      for K := 1 to Min(MaxCnt, fRNG.RandomI(Round(Settings.Obstacle.RandomWalk.ExpandRestriction)) + 1) do
      begin
        MaxIdx := fRNG.RandomI(MaxCnt);
        if (fRNG.Random < Prob[ ProbIdx[MaxIdx] ]) then
        begin
          X1 := PointsArr[  Dir[ ProbIdx[MaxIdx] ].Y, Dir[ ProbIdx[MaxIdx] ].X  ].X;
          Y1 := PointsArr[  Dir[ ProbIdx[MaxIdx] ].Y, Dir[ ProbIdx[MaxIdx] ].X  ].Y;
          if (Voronoi[Y1,X1] <> 0) then
            FillObstacle.QuickFlood(X1, Y1, Voronoi[Y1,X1], 0, Settings.Obstacle.NonWalkableTile);
          // Get coords of next shape
          X := Dir[ ProbIdx[MaxIdx] ].X;
          Y := Dir[ ProbIdx[MaxIdx] ].Y;
          // Set probability to zero (shape will not be longer used)
          P[Y,X] := 0;
          ProbIdx[MaxIdx] := ProbIdx[MaxCnt-1];
          MaxCnt := MaxCnt - 1;
          check := True;
        end;
      end;
    end;
  end;


  procedure FillGaps();
  var
    X,Y: Integer;
    searchBiome: TKMFillTestMap;
  begin
    searchBiome := TKMFillTestMap.Create(KMPoint(0,0), KMPoint(fMapX,fMapY), A);
    try
      for Y := 0 to fMapY do
      for X := 0 to fMapX do
        if (A[Y,X] = 0) then
        begin
          searchBiome.QuickFlood(X,Y,0,1);
          if (searchBiome.Count < 50) then
            searchBiome.QuickFlood(X,Y,1,Settings.Obstacle.NonWalkableTile)
          else
            searchBiome.QuickFlood(X,Y,1,Settings.Obstacle.WalkableTile);
        end;
    finally
      searchBiome.Free();
    end;
  end;


  var
    X,Y,I: Integer;
    Factor: Single;
    MinP,MaxP: TKMPoint;
    ObstacleSeeds: TKMPointArray;
begin
  // Initialization - Voroni diagram = divide map into small shapes which will be merged later; each shape have its point in PointsArr for fast searching
  Voronoi := VoronoiMod(Settings.Obstacle.VoronoiStep, PointsArr);

// Initialization
  SetLength(P, Length(PointsArr), Length(PointsArr[Low(PointsArr)]));
  for Y := Low(PointsArr) to High(PointsArr) do
    for X := Low(PointsArr[Y]) to High(PointsArr[Y]) do
      P[Y,X] := 1;

  // Make obstacles
  Factor := fMapX * fMapY * 10 / 5000; // OBSTACLE DENSITY
  MinP := KMPoint(Low(P[0]), Low(P));
  MaxP := KMPoint(High(P[0]), High(P));
  ObstacleSeeds := RNDPointsInGrid(Max(1,Round(Factor)), 0, MinP, MaxP);
  // Fill obstacle
  MinP := KMPoint(Low(A[0]), Low(A));
  MaxP := KMPoint(High(A[0]), High(A));
  FillObstacle := TKMFillBiome.Create( MinP, MaxP, Voronoi, A);
  try
    for I := Low(ObstacleSeeds) to High(ObstacleSeeds) do
    begin
      // Get seed and obstacle biome
      X := ObstacleSeeds[I].X;
      Y := ObstacleSeeds[I].Y;
      //Probability := fRNG.Random();

      //RndPointsInRadius(X,Y);

      RndWalk(X,Y);
    end;
  finally
    FillObstacle.Free;
  end;

  FillGaps();
end;



// Fast Voronoi diagram (shape generator)
function TKMTestMapGenerator.VoronoiMod(const aStep: Integer; var aPoints: TKMPoint2Array): TInteger2Array;
var
  X,aX,X1,Y,aY,Y1,i,idxX,idxY,price: Integer;
  Output, History: TInteger2Array;
begin
  SetLength(Output, fMapY+1, fMapX+1);
  SetLength(History, fMapY+1, fMapX+1);
  SetLength(aPoints, ceil((fMapY-1) / (aStep*1.0)), ceil((fMapX-1) / (aStep*1.0)));
  for Y := Low(Output) to High(Output) do
    for X := Low(Output[Y]) to High(Output[Y]) do
    begin
      History[Y,X] := High(Integer);
      Output[Y,X] := 0;
    end;

  i := 1;
  idxY := 0;
  Y := 1;
  while Y < fMapY do
  begin
    idxX := 0;
    X := 1;
    while X < fMapX do
    begin
    // Generate random point in restricted interval
      aPoints[idxY,idxX].Y := Min(fMapY-1, Y + fRNG.RandomI(aStep));
      aPoints[idxY,idxX].X := Min(fMapX-1, X + fRNG.RandomI(aStep));
      Y1 := aPoints[idxY,idxX].Y;
      X1 := aPoints[idxY,idxX].X;
    // Fill surroundings points by specific price (initial points have highest price and with increased distance is price lower)
    // There is possible to use FloodFill but aStep is in RMG very small
      // Rhombus (better solution for following flood fill processing)
      for aY := Max(Low(Output),  Y1 - aStep) to Min(High(Output), Y1 + aStep) do
        for aX := Max(Low(Output[Y1]),  X1 - aStep) to Min(High(Output[Y1]), X1 + aStep) do
        begin
          price := abs(aX-X1) + abs(aY-Y1);
          if (History[aY,aX] > price) then
          begin
            History[aY,aX] := price;
            Output[aY,aX] := i;
          end;
        end;
      i := i + 1;
      idxX := idxX + 1;
      X := X + aStep;
    end;
    idxY := idxY + 1;
    Y := Y + aStep;
  end;

  Result := Output;
end;

end.
