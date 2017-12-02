{
Random Map Generator
@author: Martin Toupal
@e-mail: poznamenany@gmail.com
}
unit KM_RandomMapGenerator;
{$I KaM_Remake.inc}
interface
uses
  KM_CommonTypes, KM_Terrain, KM_Utils, Math,  // KM_Utils = random number
  KM_Points, KM_RMGUtils, KM_Defaults,
  LclIntf; // Measure of time in Lazarus ... DELETE THIS!!!!!!!!!!  and delete command (GetTickCount) in code


type

  TBiomeType = (btGrass,btBigGrass,btWetland,btSwamp,btWater,btCoal,btGrassGround,btGround,btTreeGrass,btGroundSnow,btSnow1,btSnow2,btIce,btCoastSand,btGrassSand1,btGrassSand2,btGrassSand3,btSand,btStone,btGold,btEgold,btIron,btEIron,btDark);
  TObstacleType = (otSwamp,otWater,otWetland,otEgold,otEIron);
  TObjects = (oStone,oShrub,oBranch,oMushroom,oFlower,oGrass,oDebris,oTreeDry,oTree,oConifer,oTreeTropical,oCactus,oPalm,oWaterTypes);
  TObjectMix = (omGrass,omSwamp,omGround,omSnow,omCoal,omDesert,omWater, omWetland);
  TBiomeTypeArray = array of TBiomeType;


  TTileParts = record
    Terrain, Rotation, Height, Obj: TKMByte2Array;  // This construction allows to make search classes universal (they will work with TKMByte2Array instead of TTileParts)
  end;

  TKMRMGSettings = record
    Walkable: record
      Active, Grass, Ground, Snow, Sand: Boolean;
      FirstLayerStep, FirstLayerLimit, SecondLayerStep, SecondLayerLimit: Word;
    end;
    Obstacle: record
      Active: Boolean;
      Ratio: array[TObstacleType] of Byte;
      ProtectedRadius, Density, Size, Variance: Byte;
    end;
    Locs: record
      Active: Boolean;
      Players: Byte;
      LocsPosition: Byte;
      Resource: record
        Active, ConnectLocs, MineFix: Boolean;
        Stone, Gold, Iron: Integer;
      end;
    end;
    Height: record
      Active, HideNonSmoothTransition: Boolean;
    end;
    OnePath: record
      NoGoZones, ReplaceTerrain: Boolean;
    end;
    Objects: record
      Active, Animals: Boolean;
      ObjectDensity, Forests, Trees: Byte;
    end;
    Seed: Integer;
    BasicTiles, CA: Boolean;
  end;

  TBalancedResource = record
    Points: TKMPointArray;
    Quantity: Integer;
    Resource: Byte;
    TileCounter: TIntegerArray;
  end;
  TBalancedResource1Array = array of TBalancedResource;


  TKMRandomMapGenerator = class
  private
    fRNG: TKMRandomNumberGenerator;
  // Generators of random points / seeds / shapes / shapes with certain rules
    function RandomPlayerLocs(): TKMPointArray;
    function LinearInterpolation(const aStep,aMaxNum: Integer): TInteger2Array;
    function VoronoiMod(const aStep: Integer; var aPoints: TKMPoint2Array): TInteger2Array;
    function RNDPoints(const acnt: Single; aSpace: Integer; const aMinimum,aMaximum: TKMPoint): TKMPointArray;

    procedure SnowMountains(var A: TKMByte2Array);
    procedure NoGoZones(Locs: TKMPointArray; var TilesPartsArr: TTileParts);
  // Rules for extraction shapes from linear interpolation
    procedure Rules(const aTopLim,aTopLim2,aDownLim,aDownLim2: Integer; var aArr: TInteger2Array);
  // Procedures wich make composition of biomes
    function CreateResources(aLocs: TKMPointArray; var A: TKMByte2Array): TBalancedResource1Array;
    procedure CreateObstacles(aLocs: TKMPointArray; var A: TKMByte2Array; var aVoronoi: TInteger2Array; var aPointsArr: TKMPoint2Array);
    procedure CreateBiomes(var A: TKMByte2Array);
  // Fix of mountain to be able to construct mine there
    procedure MineFix(const Position: TKMPoint; const MINESIZE, Resource: Byte; var Visited: TBoolean2Array; var A: TKMByte2Array);
  // These functions secure smooth transitions
    procedure CellularAutomaton(var A: TKMByte2Array);
    function TileTemplate(var A: TKMByte2Array): TKMByte2Array;
    function TileTemplateCA(var A: TKMByte2Array; const Settings: Byte): TKMByte2Array;
    function TileTemplateOLD(var A: TKMByte2Array; const Settings: Byte): TKMByte2Array;
  // Generators of right rotated tiles and objects
    //procedure GenerateTilesOLD(var TilesPartsArr: TTileParts; var A: TKMByte2Array);
    procedure GenerateTiles(var Resources: TBalancedResource1Array; var TilesPartsArr: TTileParts; var A: TKMByte2Array; var B: TKMByte2Array);
    procedure GenerateBasicTiles(var TilesPartsArr: TTileParts; var A: TKMByte2Array);
    procedure GenerateHeight(var TilesPartsArr: TTileParts; var A: TKMByte2Array; var TileTempl: TKMByte2Array);
    procedure GenerateObjects(var TilesPartsArr: TTileParts; var A: TKMByte2Array);
  public
    RMGSettings: TKMRMGSettings;
    constructor Create();
    destructor Destroy(); override;
  // Random number generators
    procedure GenerateMap(var aTiles: TKMTerrainTileBriefArray);
  end;



  const
  BT: array[0..23,0..23] of Integer = (
    (-1,-1,-1,-1,-1,-1,-1,-1,-1,7,-1,-1,-1,-1,-1,14,-1,16,-1,-1,-1,-1,-1,-1),
    (0,-1,0,0,0,0,0,0,0,-1,-1,-1,-1,0,0,-1,0,-1,0,0,0,0,0,-1),
    (0,0,-1,0,-1,0,0,0,0,-1,-1,-1,-1,0,0,-1,0,-1,0,0,0,0,0,-1),
    (0,0,0,-1,0,0,0,0,0,-1,-1,-1,-1,0,0,-1,0,-1,0,0,0,0,0,-1),
    (0,0,2,0,-1,-1,7,-1,0,7,-1,-1,-1,-1,15,-1,15,-1,-1,-1,-1,-1,-1,-1),
    (0,0,0,0,4,-1,-1,-1,6,-1,9,-1,-1,-1,0,0,0,-1,0,-1,-1,-1,-1,-1),
    (0,0,0,0,7,7,-1,-1,-1,7,-1,-1,-1,0,0,-1,0,-1,0,7,7,7,7,-1),
    (0,0,0,0,4,7,6,-1,6,-1,9,-1,-1,-1,0,0,0,-1,0,-1,-1,-1,-1,-1),
    (0,0,0,0,0,6,6,6,-1,-1,-1,-1,-1,0,0,-1,0,-1,0,0,0,0,0,-1),
    (7,-1,-1,-1,7,7,7,7,-1,-1,-1,10,-1,7,-1,-1,-1,-1,-1,-1,-1,7,7,-1),
    (-1,-1,-1,-1,-1,9,-1,9,-1,9,-1,-1,-1,-1,-1,-1,-1,-1,-1,9,9,-1,-1,-1),
    (-1,-1,-1,-1,-1,-1,-1,-1,-1,10,10,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1),
    (-1,-1,-1,-1,4,-1,-1,-1,-1,-1,10,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1),
    (0,0,0,0,4,-1,0,7,0,7,-1,-1,-1,-1,15,-1,15,-1,0,-1,-1,-1,-1,-1),
    (0,0,0,0,15,0,0,0,0,-1,-1,-1,-1,-1,-1,-1,15,15,0,15,15,15,15,-1),
    (14,-1,-1,-1,4,14,-1,14,-1,-1,-1,-1,-1,13,14,-1,-1,-1,14,-1,-1,-1,-1,-1),
    (0,0,0,0,15,0,0,0,0,-1,-1,-1,-1,15,15,15,-1,-1,0,15,15,15,15,-1),
    (16,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,13,16,16,16,-1,0,15,15,15,15,-1),
    (0,0,0,0,4,0,0,0,0,-1,-1,-1,-1,0,0,0,0,0,-1,0,0,0,0,-1),
    (0,0,0,0,4,7,7,7,0,9,9,-1,-1,13,15,15,15,15,0,-1,-1,-1,-1,-1),
    (0,0,0,0,4,7,7,7,0,9,9,-1,-1,13,15,15,15,15,0,-1,-1,-1,-1,-1),
    (0,0,0,0,4,7,7,7,0,7,10,-1,-1,13,15,15,15,15,0,-1,-1,-1,-1,-1),
    (0,0,0,0,4,7,7,7,0,7,10,-1,-1,13,15,15,15,15,0,-1,-1,-1,-1,-1),
    (-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,22,21,-1)
  );

  T_FIX: array[0..23,0..23] of Byte = ( // Transition fixer
    (1,1,1,1,1,1,1,1,1,2,0,0,0,1,1,2,1,2,1,1,1,1,1,0),
    (1,1,2,2,2,2,2,2,2,0,0,0,0,2,2,0,2,0,2,2,2,2,2,0),
    (1,2,1,2,1,2,2,2,2,0,0,0,0,2,2,0,2,0,2,2,2,2,2,0),
    (1,2,2,1,2,2,2,2,2,0,0,0,0,2,2,0,2,0,2,2,2,2,2,0),
    (1,2,1,2,1,1,2,1,2,2,0,0,1,1,2,1,2,0,1,1,1,1,1,0),
    (1,2,2,2,1,1,1,1,2,1,2,0,0,1,2,2,2,0,2,1,1,1,1,0),
    (1,2,2,2,2,1,1,1,1,2,0,0,0,2,2,0,2,0,2,2,2,2,2,0),
    (1,2,2,2,1,1,1,1,2,1,2,0,0,1,2,2,2,0,2,1,1,1,1,0),
    (1,2,2,2,2,2,1,2,1,0,0,0,0,2,2,0,2,0,2,2,2,2,2,0),
    (2,0,0,0,2,1,2,1,0,1,1,2,0,2,0,0,0,0,0,1,1,2,2,0),
    (0,0,0,0,0,2,0,2,0,1,1,1,1,0,0,0,0,0,0,2,2,0,0,0),
    (0,0,0,0,0,0,0,0,0,2,1,1,0,0,0,0,0,0,0,0,0,0,0,0),
    (0,0,0,0,1,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0),
    (1,2,2,2,1,1,2,1,2,2,0,0,0,1,2,1,2,1,2,1,1,1,1,0),
    (1,2,2,2,2,2,2,2,2,0,0,0,0,2,1,1,2,2,2,2,2,2,2,0),
    (2,0,0,0,1,2,0,2,0,0,0,0,0,1,1,1,1,1,2,1,1,1,1,0),
    (1,2,2,2,2,2,2,2,2,0,0,0,0,2,2,1,1,1,2,2,2,2,2,0),
    (2,0,0,0,0,0,0,0,0,0,0,0,0,1,2,1,1,1,2,2,2,2,2,0),
    (1,2,2,2,1,2,2,2,2,0,0,0,0,2,2,2,2,2,1,2,2,2,2,0),
    (1,2,2,2,1,1,2,1,2,1,2,0,0,1,2,1,2,2,2,1,1,0,0,0),
    (1,2,2,2,1,1,2,1,2,1,2,0,0,1,2,1,2,2,2,1,1,0,0,0),
    (1,2,2,2,1,1,2,1,2,2,0,0,0,1,2,1,2,2,2,0,0,1,1,1),
    (1,2,2,2,1,1,2,1,2,2,0,0,0,1,2,1,2,2,2,0,0,1,1,1),
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1)
  );

  canWalk: array[0..23] of Boolean = (
    True,True,False,False,False,True,True,True,True,True,True,True,False,True,True,True,True,True,False,False,False,False,False,False
  );

  WT: array[0..255] of Boolean = ( // Walkable tiles
    True,True,True,True,False,True,True,False,True,True,False,True,False,True,True,False,
    True,True,True,True,True,True,True,False,False,True,True,True,True,True,True,True,
    True,True,True,True,True,True,True,True,False,False,False,False,True,True,True,True,
    False,True,False,False,True,False,False,True,True,True,True,True,True,True,True,True,
    True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,
    True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,True,
    True,True,True,True,True,True,True,True,True,False,True,True,True,True,False,True,
    True,True,False,False,True,True,False,False,True,True,True,True,True,True,False,False,
    False,False,False,False,False,False,False,False,False,False,False,True,False,False,False,False,
    False,False,False,False,False,False,False,False,True,True,True,True,False,False,False,False,
    False,False,False,False,False,False,True,True,True,True,True,True,True,True,True,True,
    False,False,False,False,True,True,True,True,False,False,False,False,True,True,True,True,
    False,False,False,False,False,True,False,False,False,False,True,True,True,True,False,True,
    False,False,False,False,True,True,True,True,False,False,False,False,True,True,True,True,
    False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,
    False,False,True,True,False,False,True,True,True,True,True,True,True,True,True,True
  );

implementation

uses
  KM_HandsCollection, KM_Hand, Dialogs;



{ TKMRandomMapGenerator }
constructor TKMRandomMapGenerator.Create();
begin
  fRNG := TKMRandomNumberGenerator.Create;
end;


destructor TKMRandomMapGenerator.Destroy();
begin
  fRNG.Free;
end;

// Main procedure for RMG - requires also RMGSettings: TKMRMGSettings (global variable)
// aTiles = empty TKMTerrainTileBriefArray
procedure TKMRandomMapGenerator.GenerateMap(var aTiles: TKMTerrainTileBriefArray);
var
  aX,aY,Y, X, K, X0,X1,X2,Y0,Y1,Y2,i: Integer;
  Pmin,Pmax: TKMPoint;
  S1,S2,S3,S4: TInteger2Array;
  A,TileTemplateArr: TKMByte2Array;
  S: TInteger2Array;
  TDAP: TKMPoint2Array;
  P: TKMPointArray;
  Points: TKMPoint2Array;
  Resources: TBalancedResource1Array;
  TilesPartsArr: TTileParts;

  //Queue: TKMQuickFlood;
  FillBiome: TKMFillBiome;

  LocMin, LocMax: TKMPoint;
  Locs: TKMPointArray;


  diff: longint;
  Sdiff: String;
begin

  // Seed MUST be <> 0!!!
  if RMGSettings.Seed = 0 then
    //RMGSettings.Seed := Round(High(Integer)*KaMRandom);
    RMGSettings.Seed := Round(High(Integer)*Random);
    //RMGSettings.Seed := 648161831;
    //RMGSettings.Seed := 8;
  //RMGSettings.Seed := RandomRange(1,High(Integer));

  fRNG.Seed := RMGSettings.Seed;
 //ShowMessage('Hello World');


  SetLength(A, gTerrain.MapY+1, gTerrain.MapX+1);
  SetLength(TilesPartsArr.Terrain, gTerrain.MapY+1, gTerrain.MapX+1);
  SetLength(TilesPartsArr.Rotation, gTerrain.MapY+1, gTerrain.MapX+1);
  SetLength(TilesPartsArr.Height, gTerrain.MapY+1, gTerrain.MapX+1);
  SetLength(TilesPartsArr.Obj, gTerrain.MapY+1, gTerrain.MapX+1);
  for Y := Low(A) to High(A) do
  	for X := Low(A[Y]) to High(A[Y]) do
    begin
  		A[Y,X] := 0;
      TilesPartsArr.Obj[Y,X] := 255;
  	end;

  diff := GetTickCount;


  SetLength(S, gTerrain.MapY+1, gTerrain.MapX+1);
  for Y := Low(S) to High(S) do
  	for X := Low(S[Y]) to High(S[Y]) do
      S[Y,X] := 0;

  {
  for Y := 5 to 10 do
    for X := 5 to 10 do
      S[Y,X] := 5;
  for Y := 15 to 20 do
    for X := 5 to 10 do
      S[Y,X] := 5;
  for Y := 5 to 20 do
    for X := 8 to 8 do
      S[Y,X] := 5;
  for Y := 13 to 15 do
    for X := 10 to 30 do
      S[Y,X] := 5;
  for Y := 20 to 25 do
    for X := 10 to 30 do
      S[Y,X] := 5;
  for Y := 12 to 15 do
    for X := 2 to 5 do
      S[Y,X] := 5;
  for Y := 20 to 23 do
     for X := 2 to 5 do
       S[Y,X] := 5;
  for Y := 25 to 25 do
     for X := 4 to 10 do
       S[Y,X] := 5;
  for Y := 25 to 28 do
     for X := 3 to 5 do
       S[Y,X] := 5;
  for Y := 26 to 27 do
     for X := 31 to 32 do
       S[Y,X] := 5;
  for Y := 18 to 19 do
     for X := 31 to 32 do
       S[Y,X] := 5;
  for Y := 2 to 4 do
     for X := 2 to 4 do
       S[Y,X] := 5;
  for Y := 29 to 31 do
     for X := 1 to 2 do
       S[Y,X] := 5;

  Pmin := KMPoint(0,0);
  Pmax := KMPoint(High(A[0]),High(A));
  FillBiome := TKMFillBiome.Create(Pmin, Pmax, S, A);
  FillBiome.QuickFlood(8,13, 5, 0, 5);



  {
  for Y := Low(S) to High(S) do
  	for X := Low(S[Y]) to High(S[Y]) do
      if S[Y,X] <> 0 then
      begin
        Queue.FloodFillWithQueue(X,Y);
      end;
  //}

  //if RMGSettings.CA then
  //  FloodFill(7,7,5, 5, A,S);

  //GenerateBasicTiles(TilesPartsArr,A);

  //{
  SetLength(Locs, 0);
  fRNG.Seed := RMGSettings.Seed;
  if RMGSettings.Locs.Active then
    Locs := RandomPlayerLocs();

  // Generate layers of shapes
  fRNG.Seed := RMGSettings.Seed;
  Resources := CreateResources(Locs, A);

  fRNG.Seed := RMGSettings.Seed;
  if RMGSettings.Walkable.Active then
    CreateBiomes(A);

  if RMGSettings.CA then
    CellularAutomaton(A);

  fRNG.Seed := RMGSettings.Seed;
  if RMGSettings.OnePath.ReplaceTerrain then
    SnowMountains(A);

  fRNG.Seed := RMGSettings.Seed;
  TileTemplateArr := TileTemplate(A);

  fRNG.Seed := RMGSettings.Seed;
  if RMGSettings.BasicTiles then
    GenerateBasicTiles(TilesPartsArr,A)
  else
    GenerateTiles(Resources, TilesPartsArr, A, TileTemplateArr);

  fRNG.Seed := RMGSettings.Seed;
  if RMGSettings.OnePath.NoGoZones AND (length(Locs) > 0) then
    NoGoZones(Locs, TilesPartsArr);

  fRNG.Seed := RMGSettings.Seed;
  if RMGSettings.Height.Active then
    GenerateHeight(TilesPartsArr, A, TileTemplateArr);

  fRNG.Seed := RMGSettings.Seed;
  if RMGSettings.Objects.Active then
    GenerateObjects(TilesPartsArr, A);
  //}
  diff := GetTickCount - diff;
  Str(diff,Sdiff);
  //ShowMessage(Sdiff);
  // Show loc postion (Debug)
  //
  {
  if Length(Locs) > 0 then
    for i := Low(Locs) to High(Locs) do
    begin
      A[Locs[I].Y,Locs[I].X] := Byte(btDark);
      A[Locs[I].Y+1,Locs[I].X] := Byte(btDark);
      A[Locs[I].Y,Locs[I].X+1] := Byte(btDark);
      A[Locs[I].Y+1,Locs[I].X+1] := Byte(btDark);
    end;
  GenerateBasicTiles(TilesPartsArr,A);
  //}
  {
  Pmin.X := 1;
  Pmax.X := High(A[1])-1;
  Pmin.Y := 1;
  Pmax.Y := High(A)-1;
  P := POMRNDPoints(RMGSettings.Obstacle.Density, RMGSettings.Objects.Trees,Pmin,Pmax,A);
  for Y := 0 to High(P) do
    A[P[Y].Y,P[Y].X] := Byte(btDark);
  GenerateBasicTiles(TilesPartsArr,A);
  //}
  {
  Seed := RMGSettings.Seed;
  S := VoronoiMod(3,Points);
  i := 0;
  for Y := 0 to High(Points) do
    for X := 0 to High(Points[Y]) do
    begin
      aX := Points[Y,X].X;
      aY := Points[Y,X].Y;
      i := i + 1;
      if i > High(BIO) then
        i := 0;
      FloodFill(aX,aY,S[aY,aX], Byte(BIO[I]), A,S);
      A[aY,aX] := Byte(btDark);
    end;
  GenerateBasicTiles(TilesPartsArr,A);
  {
  X := Points[5,5].X;
  Y := Points[5,5].Y;
  FloodFill(X,Y,S[Y,X], Byte(btGrassGround), A,S);
  X := Points[5,6].X;
  Y := Points[5,6].Y;
  FloodFill(X,Y,S[Y,X], Byte(btGround), A,S);
  X := Points[6,5].X;
  Y := Points[6,5].Y;
  FloodFill(X,Y,S[Y,X], Byte(btSnow1), A,S);
  X := Points[6,6].X;
  Y := Points[6,6].Y;
  FloodFill(X,Y,S[Y,X], Byte(btSnow2), A,S);
  GenerateBasicTiles(TilesPartsArr,A);
  }
  {
  for Y := 0 to gTerrain.MapY do
  begin
    S[Y,0] := 0;
    S[Y,gTerrain.MapX] := 0;
  end;
  for X := 0 to gTerrain.MapX do
  begin
    S[0,X] := 0;
    S[gTerrain.MapY,X] := 0;
  end;
  for Y := 1 to gTerrain.MapY-1 do
    for X := 1 to gTerrain.MapX-1 do
    begin
      if S[Y,X] <> 0 then
        FloodFill(X,Y,S[Y,X], Byte(BIO[TGRandomI(Length(BIO))]), A,S);
    end;
  GenerateBasicTiles(TilesPartsArr,A);
  //}

  // Generate objects
  //GenerateObjects(aTiles, A);

  {
  Pmin.X := 50;
  Pmin.Y := 50;
  Pmax.X := 100;
  Pmax.Y := 100;;

  P := RNDPoints(50,0,Pmin,Pmax);

  for i := Low(P) to High(P) do
  begin
    A[P[I].Y,P[I].X] := Byte(BtDark);

  end;
  //}

  SetLength(aTiles, gTerrain.MapY * gTerrain.MapX);
  K := 0;
  for Y := 1 to gTerrain.MapY-1 do
    for X := 1 to gTerrain.MapX-1 do
    begin
      //K := (Y-1)*(gTerrain.MapX-1)+X-1;
      aTiles[K].Y := Y;
      aTiles[K].X := X;
      aTiles[K].Terrain := TilesPartsArr.Terrain[Y,X];
      aTiles[K].Rotation := TilesPartsArr.Rotation[Y,X];
      aTiles[K].Height := TilesPartsArr.Height[Y,X];
      aTiles[K].Obj := TilesPartsArr.Obj[Y,X];
      Include(aTiles[K].ChangeSet, tctTerrain);
      Include(aTiles[K].ChangeSet, tctHeight);
      Include(aTiles[K].ChangeSet, tctObject);
      K := K + 1;
    end;
end;






// Linear interpolation for grid of random points (for GenerateHeight or CreateBiomes functions)
// aStep = step of linear interpolation (size of shapes)
// aMaxNum = generated numbers will be in interval <0, aMaxNum)
// Result = TInteger2Array of numbers which basicaly represent height of terrain
function TKMRandomMapGenerator.LinearInterpolation(const aStep, aMaxNum: Integer): TInteger2Array;
var
  Y, X, Ymax, Xmax, i: Integer;
  ShiftArr, invShiftArr: TSingleArray;
  Output: TInteger2Array;
begin
  // Initialization
  Xmax := ((gTerrain.MapX div aStep) + 1) * aStep + 1;
  Ymax := ((gTerrain.MapY div aStep) + 1) * aStep + 1;
  SetLength(Output, Ymax, Xmax);

  // Precomputation of shares in interpolation
  SetLength(ShiftArr,aStep);
  SetLength(invShiftArr,aStep);
  for i := 1 to High(ShiftArr) do
  begin
    ShiftArr[I] := (aStep - i) / (aStep * 1.0);
    invShiftArr[I] := 1 - ShiftArr[I];
  end;

  // Make grid of random numbers
  Y := 0;
  while Y <= High(Output) do
  begin
    X := 0;
    while X <= High(Output[0]) do
    begin
      Output[Y,X] := fRNG.RandomI(aMaxNum);
      X := X + aStep;
    end;
    Y := Y + aStep;
  end;

  // Linear interpolation of Y columns in aStep distances (it depends only at Y axis => faster do it now and use those data in X axis)
  Y := 0;
  while Y < High(Output) do
  begin
    Ymax := Y + aStep;
    X := 0;
    while X <= High(Output[0]) do
    begin
      for i := 1 to High(ShiftArr) do
        Output[Y+i,X] := Trunc(ShiftArr[I] * Output[Y,X] + invShiftArr[I] * Output[Ymax,X]);
      X := X + aStep;
    end;
    Y := Ymax;
  end;

  //Linear interpolation of X rows from Y columns
  X := 0;
  while X < High(Output[0]) do
  begin
    Xmax := X + aStep;
    for Y := 0 to High(Output) do
      for i := 1 to High(ShiftArr) do
        Output[Y,X+i] := Trunc(ShiftArr[I] * Output[Y,X] + invShiftArr[I] * Output[Y,Xmax]);
    X := Xmax;
  end;

  Result := Output;
end;



// Create shapes using specific limits from TInteger2Array
// aTopLim, aTopLim2 = top limit for first / second level of shape
// aDownLim,aDownLim2 = down limit for first / second level of shape
// aArr = TInteger2Array of values (created by linear interpolation)
procedure TKMRandomMapGenerator.Rules(const aTopLim,aTopLim2,aDownLim,aDownLim2: Integer; var aArr: TInteger2Array);
var
  X1,X2,Y1,Y2: Integer;
begin
// Shortcuts (indexes in array):
//    ___________________________
//   |        :         :        |
//   | ... [Y1,X1]   [Y1,X2] ... |
//   | ... [Y2,X1]   [Y2,X2] ... |
//   |        :         :        |
//    ———————————————————————————
  for Y1 := High(aArr) - 1 downto 0 do
  begin
    Y2 := Y1 + 1;
    for X1 := High(aArr[0]) - 1 downto 0 do
    begin
      X2 := X1 + 1;
      if (aArr[Y1,X1] > aTopLim2) OR (aArr[Y1,X1] < aDownLim2) then
      begin
        aArr[Y1,X1] := -2;
        aArr[Y1,X2] := -2;
        aArr[Y2,X1] := -2;
        aArr[Y2,X2] := -2;
      end
      else if (aArr[Y1,X1] > aTopLim) OR (aArr[Y1,X1] < aDownLim) then
      begin
        aArr[Y1,X1] := -1;
        if aArr[Y1,X2] > 0 then aArr[Y1,X2] := -1;
        if aArr[Y2,X1] > 0 then aArr[Y2,X1] := -1;
        if aArr[Y2,X2] > 0 then aArr[Y2,X2] := -1;
      end;
    end;
  end;
end;


// Fast Voronoi diagram (shape generator)
// aStep = generated step = size of generated shapes
// aPoints = array of TKMPoints belonging to its shapes (1 point = 1 shape)
function TKMRandomMapGenerator.VoronoiMod(const aStep: Integer; var aPoints: TKMPoint2Array): TInteger2Array;
var
  X,aX,X0,X1,X2,Y,aY,Y0,Y1,Y2,i,idxX,idxY,move,price: Integer;
  Output, History: TInteger2Array;
begin
  SetLength(Output, gTerrain.MapY+1, gTerrain.MapX+1);
  SetLength(History, gTerrain.MapY+1, gTerrain.MapX+1);
  SetLength(aPoints, ceil((gTerrain.MapY-1) / (aStep*1.0)), ceil((gTerrain.MapX-1) / (aStep*1.0)));
  for Y := Low(Output) to High(Output) do
    for X := Low(Output[Y]) to High(Output[Y]) do
    begin
      History[Y,X] := High(Integer);
      Output[Y,X] := 0;
    end;

  i := 1;
  idxY := 0;
  Y := 1;
  while Y < gTerrain.MapY do
  begin
    idxX := 0;
    X := 1;
    while X < gTerrain.MapX do
    begin
    // Generate random point in restricted interval
      aPoints[idxY,idxX].Y := Min(gTerrain.MapY-1, Y + fRNG.RandomI(aStep));
      aPoints[idxY,idxX].X := Min(gTerrain.MapX-1, X + fRNG.RandomI(aStep));
      Y1 := aPoints[idxY,idxX].Y;
      X1 := aPoints[idxY,idxX].X;
    // Fill surroundings points by specific price (initial points have highest price and with increased distance is price lower)
    // There is possible to use FloodFill but aStep is in RMG very small
      //{ Rhombus (better solution for following flood fill processing)
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
      //}
      { Square (for flood fill without scan 8 tiles in CreateResources it is not good solution)
      move := 1;
      price := aStep;
      History[Y1,X1] := aStep+1;
      Output[Y1,X1] := i;
      while (price > 0) do
      begin
        Y0 := Max(Low(Output),  Y1 - move);
        X0 := Max(Low(Output[Y0]),  X1 - move);
        Y2 := Min(High(Output), Y1 + move);
        X2 := Min(High(Output[Y2]), X1 + move);


        for aX := X0 to X2 do
        begin
          if (History[Y0,aX] < price) then
          begin
            History[Y0,aX] := price;
            Output[Y0,aX] := i;
          end;
          if (History[Y2,aX] < price) then
          begin
            History[Y2,aX] := price;
            Output[Y2,aX] := i;
          end;
        end;
        for aY := Y0 to Y2 do
        begin
          if (History[aY,X0] < price) then
          begin
            History[aY,X0] := price;
            Output[aY,X0] := i;
          end;
          if (History[aY,X2] < price) then
          begin
            History[aY,X2] := price;
            Output[aY,X2] := i;
          end;
        end;
        move := move + 1;
        price := price - 1;

      end;
      }
      i := i + 1;
      idxX := idxX + 1;
      X := X + aStep;
    end;
    idxY := idxY + 1;
    Y := Y + aStep;
  end;

  Result := Output;
end;




// Generator of random points with best possible distance between them (quite slow algorithm, only for Locs)
// Result = TKMPointArray which represents Locs
function TKMRandomMapGenerator.RandomPlayerLocs(): TKMPointArray;

  // Rectangle of Locs around map borders
  procedure Rectangle(var aLocs: TKMPointArray; aMinOffset, aMaxOffset: TKMPoint);
  var
    i, Distance, Variance, Step: Integer;
    PhaseArr: array[0..3] of Integer;
  begin
    PhaseArr[0] := aMaxOffset.X - aMinOffset.X;
    PhaseArr[1] := aMaxOffset.Y - aMinOffset.Y + PhaseArr[0];
    PhaseArr[2] := aMaxOffset.X - aMinOffset.X + PhaseArr[1];
    PhaseArr[3] := aMaxOffset.Y - aMinOffset.Y + PhaseArr[2];

    Step := Round(PhaseArr[3] / (Length(aLocs)*1.0));
    Variance := Step shr 1;
    Distance := fRNG.RandomI(Variance);
    for i := Low(aLocs) to High(aLocs) do
    begin
      if (Distance > PhaseArr[3]) then
        Distance := Distance - PhaseArr[3];
      if (Distance > PhaseArr[2]) then
      begin
        aLocs[I].X := aMinOffset.X;
        aLocs[I].Y := aMaxOffset.Y - Distance + PhaseArr[2];
      end
      else if (Distance > PhaseArr[1]) then
      begin
        aLocs[I].X := aMaxOffset.X - Distance + PhaseArr[1];
        aLocs[I].Y := aMaxOffset.Y;
      end
      else if (Distance > PhaseArr[0]) then
      begin
        aLocs[I].X := aMaxOffset.X;
        aLocs[I].Y := aMinOffset.Y + Distance - PhaseArr[0];
      end
      else
      begin
        aLocs[I].X := aMinOffset.X + Distance;
        aLocs[I].Y := aMinOffset.Y;
      end;
      Distance := Step * (i+1) + fRNG.RandomI(Variance);
    end;
  end;

  // Locs in Vertical position
  procedure Vertical(var aLocs: TKMPointArray; aMinOffset, aMaxOffset: TKMPoint);
  var
    i, StepLeft, StepRight, cntLeft, cntRight, VarianceX, VarianceYLeft, VarianceYRight: Integer;
  begin
    cntLeft := Length(aLocs) shr 1;
    cntRight := Length(aLocs) - cntLeft;
    if (cntLeft <> cntRight) AND (fRNG.RandomI(2) = 1) then
    begin
      Inc(cntLeft, 1);
      Dec(cntRight, 1);
    end;

    StepLeft := Round((aMinOffset.Y+aMaxOffset.Y - 4) / Max(1, cntLeft));
    StepRight := Round((aMinOffset.Y+aMaxOffset.Y - 4) / Max(1, cntRight));

    VarianceYLeft := StepLeft shr 1;
    VarianceYRight := StepRight shr 1;
    VarianceX := (aMaxOffset.X - aMinOffset.X) shr 2;
    i := 0;
    while i < cntLeft do
    begin
      aLocs[I].X := aMinOffset.X + fRNG.RandomI(VarianceX);
      aLocs[I].Y := aMinOffset.Y + StepLeft * i + fRNG.RandomI(VarianceYLeft);
      i := i + 1;
    end;
    while i < Length(aLocs) do
    begin
      aLocs[I].X := aMaxOffset.X - fRNG.RandomI(VarianceX);
      aLocs[I].Y := aMinOffset.Y + StepRight * (i - cntLeft) + fRNG.RandomI(VarianceYRight);
      i := i + 1;
    end;
  end;

  // Locs in Horizontal position
  procedure Horizontal(var aLocs: TKMPointArray; aMinOffset, aMaxOffset: TKMPoint);
  var
    i: Byte;
  begin
    aMinOffset := KMPoint(aMinOffset.Y, aMinOffset.X);
    aMaxOffset := KMPoint(aMaxOffset.Y, aMaxOffset.X);
    Vertical(aLocs, aMinOffset, aMaxOffset);
    for i := Low(aLocs) to High(aLocs) do
      aLocs[I] := KMPoint(aLocs[I].Y, aLocs[I].X);
  end;

  // Random locs selected from group of generated points (brute force algorithm but for 1-12 locs it is fine)
  procedure Random(var Locs: TKMPointArray; const Minimum,Maximum: TKMPoint);
    var
      i,j,k, min_idx_overall, min_dist, sum_dist, min_dist_overall, sum_dist_overall: Integer;
      Size: TKMPoint;
      Distances: TInteger2Array;
      Points: TKMPointArray;
      Used: TBooleanArray;
    const
      POINTS_PER_A_LOC = 5;
  begin
    SetLength(Points, POINTS_PER_A_LOC*Length(Locs));
    SetLength(Used, Length(Points));
    SetLength(Distances, Length(Points), Length(Points));

  // Generate points
    Size := KMPoint(Maximum.X - Minimum.X, Maximum.Y - Minimum.Y);
    for i := Low(Points) to High(Points) do
    begin
      Points[I] := KMPoint(fRNG.RandomI(Size.X), fRNG.RandomI(Size.Y));
      for j := i-1 downto Low(Points) do
      begin
        Distances[i,j] := KMDistanceAbs(Points[I], Points[j]); // Abs is faster than Euclidean space
        Distances[j,i] := Distances[i,j];
      end;
      //Distances[i,i] := High(Integer);
      Used[I] := False;
    end;

  // Find points with max distance
    for i := 1 to (Length(Points) - Length(Locs)) do
    begin
      min_dist_overall := High(Integer);
      sum_dist_overall := High(Integer);
      for j := Low(Points) to High(Points) do
        if not Used[j] then
        begin
          min_dist := High(Integer);
          sum_dist := 0;
          for k := Low(Points) to High(Points) do
            if not Used[k] AND (j <> k) then
            begin
              if (Distances[j,k] < min_dist) then
                min_dist := Distances[j,k];
              sum_dist := sum_dist + Distances[j,k];
            end;
          if (min_dist_overall > min_dist) OR ( (min_dist_overall = min_dist) AND (sum_dist_overall > sum_dist) ) then
          begin
            min_idx_overall := j;
            min_dist_overall := min_dist;
            sum_dist_overall := sum_dist;
          end;
        end;
      Used[min_idx_overall] := True;
    end;

    i := Low(Locs);
    for j := Low(Points) to High(Points) do
      if not Used[j] then
      begin
        Locs[I] := KMPoint(Minimum.X + Points[j].X, Minimum.Y + Points[j].Y);
        i := i + 1;
      end;
  end;

  // Get locs from center screen position
  procedure CenterScreen(var aLocs: TKMPointArray);
  var
    I, idx: Integer;
  begin
    idx := 0;
    SetLength(aLocs, gHands.Count);
    for I := 0 to gHands.Count-1 do
      if gHands[I].Enabled  AND not ((gHands[I].CenterScreen.X = (gTerrain.MapX div 2)) AND (gHands[I].CenterScreen.Y = (gTerrain.MapY div 2))) then
      begin
        aLocs[idx] := KMPointRound(  KMPointF( gHands[I].CenterScreen )  );
        Inc(idx, 1);
      end;
    SetLength(aLocs, idx);
  end;

var
  MinOffset, MaxOffset: TKMPoint;
  Output: TKMPointArray;
const
  EDGE_DIST = 0.1; // in %, must be > 0 !!!
begin
  SetLength(Output, RMGSettings.Locs.Players);

  MinOffset.X := Round(gTerrain.MapX * EDGE_DIST);
  MinOffset.Y := Round(gTerrain.MapY * EDGE_DIST);
  MaxOffset.X := gTerrain.MapX - MinOffset.X;
  MaxOffset.Y := gTerrain.MapY - MinOffset.Y;

  case RMGSettings.Locs.LocsPosition of
    0: Rectangle(Output, MinOffset, MaxOffset);
    1: Vertical(Output, MinOffset, MaxOffset);
    2: Horizontal(Output, MinOffset, MaxOffset);
    3: Random(Output, MinOffset, MaxOffset);
    4: CenterScreen(Output);
    else begin end;
  end;
  Result := Output;
end;



// Generator of random points with minimal distance between them (algorithmic from division into areas with indetical size = very fast)
// aCnt = minimal count (it will adapt to map size to secure that it is balanced
// aSpace = minimal space between generated points (when it is high number points will be in grid)
// aMinimum, aMaximum = point will be generated in rectangle given by this points
// Result = TKMPointArray of pseudorandom points
function TKMRandomMapGenerator.RNDPoints(const aCnt: Single; aSpace: Integer; const aMinimum,aMaximum: TKMPoint): TKMPointArray;
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



// Biomes generator (basic ACCESSIBLE terrain)
// A = TKMByte2Array which will be fill by biomes
procedure TKMRandomMapGenerator.CreateBiomes(var A: TKMByte2Array);
var
  X,Y,RandBiom,POM1,POM2,ShapeNum: Integer;
  ShapeArr,Shape2Arr: TInteger2Array;
  Biomes: TBiomeTypeArray;
  SearchSimilarBiome: TKMSearchSimilarBiome;
  FillBiome: TKMFillBiome;
const
  // Biomes
  // Grass: btBigGrass,btGrass
	// Water: btSwamp,btWetland,btWater
	// Ground: btGrassGround,btGround,btTreeGrass
	// Snow: btGroundSnow,btSnow1,btSnow2,btIce
	// Sand: btCoastSand,btGrassSand1,btGrassSand2,btGrassSand3,btSand
	// Resources: btCoal,btStone,btGold,btEgold,btIron,btEIron    btDark
  // Transitions
  Tr_Grass: array[0..3] of TBiomeType = (btGrass,btBigGrass,btTreeGrass,btGrassGround);
  Tr_BigGrass: array[0..2] of TBiomeType = (btGrass,btTreeGrass,btGrassGround);
  Tr_GrassGround: array[0..3] of TBiomeType = (btGrass,btBigGrass,btTreeGrass,btGround);
  Tr_Ground: array[0..1] of TBiomeType = (btTreeGrass,btGrassGround);
  Tr_TreeGrass: array[0..3] of TBiomeType = (btGrassGround,btGround,btBigGrass,btGrassSand1);
  Tr_CoastSand: array[0..3] of TBiomeType = (btGrass,btGround,btGrassSand2,btSand);
  Tr_GrassSand1: array[0..2] of TBiomeType = (btGrass,btGrassSand2,btGrassSand3);
  Tr_GrassSand2: array[0..2] of TBiomeType = (btGrassSand1,btGrassSand3,btSand);
  Tr_GrassSand3: array[0..2] of TBiomeType = (btGrassSand1,btGrassSand2,btSand);
  Tr_Sand: array[0..2] of TBiomeType = (btGrassSand1,btGrassSand2,btGrassSand3);
  Tr_GroundSnow: array[0..2] of TBiomeType = (btGround,btGroundSnow,btSnow1);
begin

  // Create Shapes (multiple layers)
  ShapeArr := LinearInterpolation((RMGSettings.Walkable.FirstLayerStep shl 4),1000);
  Shape2Arr := LinearInterpolation((RMGSettings.Walkable.FirstLayerStep shl 2),1000);
	for Y := Low(A) to High(A) do
		for X := Low(A) to High(A[Y]) do
      ShapeArr[Y,X] := ShapeArr[Y,X] + Shape2Arr[Y,X];

  // Extract data from RMGSettings and create appropriate shapes
  POM1 := RMGSettings.Walkable.FirstLayerLimit * 50 + 500;
  Rules(2000 - POM1, 2000, POM1, 0, ShapeArr);
  Shape2Arr := LinearInterpolation(RMGSettings.Walkable.SecondLayerStep, 1000);
  POM1 := RMGSettings.Walkable.SecondLayerLimit * 25 + 125;
  POM2 := RMGSettings.Walkable.SecondLayerLimit * 6;
  Rules(1000-POM1, 1000-POM2, POM1, POM2, Shape2Arr);

  // Do not allow to rewrite exist Non-walk textures (they already are in array A)
  for Y := Low(A) to High(A) do
		for X := Low(A) to High(A[Y]) do
      if (A[Y,X] <> 0) then
      begin
        ShapeArr[Y,X] := 0;
        Shape2Arr[Y,X] := 0;
      end;

  // Get another RMGSetting
  if RMGSettings.Walkable.Ground then
  begin
    SetLength(Biomes, 3);
    Biomes[ 0 ] := btTreeGrass;
    Biomes[ 1 ] := btGrassGround;
    Biomes[ 2 ] := btGround;
  end;
  if RMGSettings.Walkable.Snow then
  begin
    SetLength(Biomes, Length(Biomes) + 1);
    Biomes[ High(Biomes) ] := btGroundSnow;
  end;
  if RMGSettings.Walkable.Sand then
  begin
    SetLength(Biomes, Length(Biomes) + 2);
    Biomes[ High(Biomes)-1 ] := btGrassSand1;
    Biomes[ High(Biomes) ] := btGrassSand3;
  end;

  // Fill 1 layer of biomes (big layer)
  Y := Low(A);
  SearchSimilarBiome := TKMSearchSimilarBiome.Create(  KMPoint(  Low(A[Y]), Low(A) ), KMPoint(  High(A[Y]), High(A)  ), ShapeArr, A  );
  FillBiome := TKMFillBiome.Create(  KMPoint(  Low(A[Y]), Low(A) ), KMPoint(  High(A[Y]), High(A)  ), ShapeArr, A  );
  try
    if (Length(Biomes) > 0) then
      for Y := Low(A) to High(A) do
		    for X := Low(A) to High(A[Y]) do
          if (ShapeArr[Y,X] = -1) then
          begin
            RandBiom := Byte(  Biomes[ fRNG.RandomI(length(Biomes)) ]  );
            SearchSimilarBiome.QuickFlood(X,Y, ShapeArr[Y,X], 1, RandBiom);
            if (SearchSimilarBiome.Count > 50) then
              FillBiome.QuickFlood(X,Y, ShapeArr[Y,X], 0, RandBiom );
          end;

    // Fill 2 and 3 layer of biomes (small and very small layer)
    SearchSimilarBiome.SearchArr := Shape2Arr;
    FillBiome.SearchArr := Shape2Arr;
    ShapeNum := -10;
	  for Y := 1 to High(A) do
		  for X := 1 to High(A[Y]) do
			  if (Shape2Arr[Y,X] = -1) OR (Shape2Arr[Y,X] = -2) then begin
          case A[Y,X-1] of
            Byte(btGrass):      RandBiom := Byte(  Tr_Grass[ fRNG.RandomI(length(Tr_BigGrass)) ]           );
            Byte(btBigGrass):   RandBiom := Byte(  Tr_BigGrass[ fRNG.RandomI(length(Tr_BigGrass)) ]        );
            Byte(btGrassGround):RandBiom := Byte(  Tr_GrassGround[ fRNG.RandomI(length(Tr_GrassGround)) ]  );
            Byte(btGround):     RandBiom := Byte(  Tr_Ground[ fRNG.RandomI(length(Tr_Ground)) ]            );
            Byte(btTreeGrass):  RandBiom := Byte(  Tr_TreeGrass[ fRNG.RandomI(length(Tr_TreeGrass)) ]      );
            Byte(btCoastSand):  RandBiom := Byte(  Tr_CoastSand[ fRNG.RandomI(length(Tr_CoastSand)) ]      );
            Byte(btGrassSand1): RandBiom := Byte(  Tr_GrassSand1[ fRNG.RandomI(length(Tr_GrassSand1)) ]    );
            Byte(btGrassSand2): RandBiom := Byte(  Tr_GrassSand2[ fRNG.RandomI(length(Tr_GrassSand2)) ]    );
            Byte(btGrassSand3): RandBiom := Byte(  Tr_GrassSand3[ fRNG.RandomI(length(Tr_GrassSand3)) ]    );
            Byte(btSand):       RandBiom := Byte(  Tr_Sand[ fRNG.RandomI(length(Tr_Sand)) ]                );
            Byte(btGroundSnow): RandBiom := Byte(  Tr_GroundSnow[ fRNG.RandomI(length(Tr_GroundSnow)) ]    );
            else begin Continue; end;
          end;
          SearchSimilarBiome.QuickFlood(X,Y, Shape2Arr[Y,X], ShapeNum, RandBiom);
          if (SearchSimilarBiome.Count > 3) then
            FillBiome.QuickFlood(X,Y, ShapeNum, 0, RandBiom);
          ShapeNum := ShapeNum - 1;
			  end;
  finally
    SearchSimilarBiome.Free;
    FillBiome.Free;
  end;
end;


// Resources and INACCESSIBLE texture generator
// aLocs = estimated player's positions
// A = array to fill resources / obstacles
// Result = TBalancedResource1Array = array of shapes which represents resources (each shape have its own count of resources and points which were get from Voronoi diagram)
//          Cellular automaton can change shapes so it is important to keep more points to secure that every shape will have its resources in GenerateTiles
{
function TKMRandomMapGenerator.CreateResources(aLocs: TKMPointArray; var A: TKMByte2Array): TBalancedResource1Array;

function RNDPointInCircle(aMin,aMax,aCenter: TKMPoint; aMaxRadius: Single): TKMPoint;
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

function FindBestResLoc(const aRADIUS: Single; aMin,aMax,aCenter: TKMPoint; var aCountArr: TInteger2Array; var aResLoc: TKMPoint): boolean;
const
  RESRAD = 2;
  BREAK_LIMIT = 20;
var
  I,X,Y, BestResCnt, ResCnt: Integer;
  ResPoint: TKMPoint;
begin
  aResLoc := KMPOINT_ZERO;
  BestResCnt := 0;
  for I := 0 to 10 do
  begin
    ResCnt := 0;
    ResPoint := RNDPointInCircle(aMin,aMax,aCenter, aRADIUS);
    if (aCountArr[ResPoint.Y,ResPoint.X] > 0) then
      for Y := Max(Low(aCountArr), ResPoint.Y-RESRAD) to Min(High(aCountArr), ResPoint.Y+RESRAD) do
        for X := Max(Low(aCountArr[0]), ResPoint.X-RESRAD) to Min(High(aCountArr[0]), ResPoint.X+RESRAD) do
          if (aCountArr[Y,X] > 0) then
            ResCnt := ResCnt + 1;
    if (BestResCnt < ResCnt) then
    begin
      BestResCnt := ResCnt;
      aResLoc := ResPoint;
    end;
    if (BestResCnt >= BREAK_LIMIT) then
      break;
  end;
  Result := not KMSamePoint(aResLoc, KMPOINT_ZERO);
end;

var
  X,Y,Loc,I,K,overflow,cnt_ADD, ALL_RES_RADIUS, CENTER_RES, cnt_FINAL, cnt_ACTUAL, RESOURCE: Integer;

  PROB_REDUCER: Single;
  Voronoi,CountArr: TInteger2Array;
  TP_S,TP_E,ResPoint,BestResPoint, Pom: TKMPoint;
  ResSettings: TIntegerArray;
  ResAmount, ResTilesAmount: array[0..4] of Integer; // Amount of tiles of specific resources
  Locs, Points: TKMPointArray;
  Visited: TBoolean2Array;
  PointsArr: TKMPoint2Array;
  SearchResource: TKMSearchBiome;
  FillResource: TKMFloodWithQueue;
  Output: TBalancedResource1Array;

  ResLoc: TKMPoint;
  ResCnt, BestResCnt: Integer;
const
  Resources: array[0..4] of TBiomeType = (btIron,btGold,btStone,btCoal,btCoal);
  VORONOI_STEP = 3;
  RES_PROB: array[0..4] of Single = (0.0007,0.07,0.15,0.03,0.03); // Probability penalization (only afect final shape: 0 = circle, 1 = multiple separated mountains)
  SPEC_RES_RADIUS: array[0..4] of Byte = (5, 5, 5, 5, 5); // Iron, Gold, Stone, Coal, Coal
  RES_MULTIPLICATION: array[0..4] of Integer = (50, 50, 200, 100, 50);
  RES_DIVISION: array[0..4] of Single = (1/1.7, 1/1.7, 1/7, 1/1.7, 1/1.7); // Inverse it now and in computation use multiplication (faster)

begin

  // Initialization - Voroni diagram = divide map into small shapes which will be merged later; each shape have its point in PointsArr for fast searching
  Voronoi := VoronoiMod(VORONOI_STEP, PointsArr);

  // Make grid from Voronoi diagram with center points (PointsArr) and CountArr of points in 1 shape (CountArr)
  SetLength(CountArr, Length(PointsArr), Length(PointsArr[Low(PointsArr)]));
  SearchResource := TKMSearchBiome.Create(  KMPoint(  Low(A[0]), Low(A) ), KMPoint(  High(A[0]), High(A)  ), Voronoi  );
  try
    for I := Low(PointsArr) to High(PointsArr) do
      for K := Low(PointsArr[I]) to High(PointsArr[I]) do
      begin
        CountArr[I,K] := 0;
        X := PointsArr[I,K].X;
        Y := PointsArr[I,K].Y;
        SearchResource.QuickFlood(X,Y, Voronoi[Y,X], -Voronoi[Y,X]);
        CountArr[I,K] := SearchResource.Count;
      end;
  finally
    SearchResource.Free;
  end;

  with RMGSettings.Locs.Resource do
  begin
    ResSettings := TIntegerArray.Create(Iron, Gold, Stone, Iron, Gold);
    for I := Low(ResSettings) to High(ResSettings) do
    begin
      ResAmount[I] := ResSettings[I] * RES_MULTIPLICATION[I];
      ResTilesAmount[I] := Trunc(ResAmount[I] * RES_DIVISION[I]);
    end;
    ALL_RES_RADIUS := Round(((Iron*3 + Gold*2 + Stone) shr 1) / VORONOI_STEP);
    CENTER_RES := Round(ALL_RES_RADIUS / 2);
  end;

  // Resources
  //{
  if RMGSettings.Locs.Resource.Active then
  begin
    SetLength(Locs,Length(aLocs));
    FillResource := TKMFloodWithQueue.Create(fRNG, PointsArr, CountArr, Voronoi, A);
    try
      for Loc := Low(aLocs) to High(aLocs) do
      begin
      // Transfer aLoc into new coordination (Voronoi array is VORONOI_STEPx smaller)
        Locs[Loc] := KMPoint(  aLocs[Loc].X div VORONOI_STEP, aLocs[Loc].Y div VORONOI_STEP  );
      // Generate points around loc (center points of resources)
        TP_S := KMPoint(  Max(0, Locs[Loc].X - ALL_RES_RADIUS), Max(0, Locs[Loc].Y - ALL_RES_RADIUS)  );
        TP_E := KMPoint(  Min(High(CountArr[0]), Locs[Loc].X + ALL_RES_RADIUS), Min(High(CountArr), Locs[Loc].Y + ALL_RES_RADIUS)  );
        for I := Low(ResAmount) to High(ResAmount) do
        begin
        // Initialization of parameters for shape generator
          RESOURCE := Byte(Resources[I]);
          PROB_REDUCER := RES_PROB[I];
          cnt_FINAL := ResTilesAmount[I];
          cnt_ACTUAL := 0;
          cnt_ADD := 0;
          overflow := 0;
          // Create new "mountain" of resources
          while (cnt_ACTUAL < cnt_FINAL) AND (overflow < 10) do
          begin
            overflow := overflow + 1;
            // Try find unused shape
            if not FindBestResLoc(5.0, TP_S,TP_E,Locs[Loc], CountArr, ResLoc) then
              break;
            // Just a few interation so SetLength is fine
            SetLength(Output, Length(Output)+1);
            // Merge shapes from Voronoi until we reach desired size
            FillResource.FloodFillWithQueue(ResLoc.X, ResLoc.Y, cnt_FINAL, cnt_ACTUAL, RESOURCE, 1, PROB_REDUCER, Output[ High(Output) ].Points);
            Output[ High(Output) ].Quantity := Round( (Min(cnt_FINAL, cnt_ACTUAL) - cnt_ADD) / Max(1,cnt_FINAL) * ResAmount[I]);
            Output[ High(Output) ].Resource := RESOURCE;
            cnt_ADD := cnt_ACTUAL;
          end;
        end;
      end;
    finally
      FillResource.Free;
    end;
  end;


  Result := Output;
end;
//}

//{
// Resources and INACCESSIBLE texture generator
// aLocs = estimated player's positions
// A = array to fill resources / obstacles
// Result = TBalancedResource1Array = array of shapes which represents resources (each shape have its own count of resources and points which were get from Voronoi diagram)
//          Cellular automaton can change shapes so it is important to keep more points to secure that every shape will have its resources in GenerateTiles
function TKMRandomMapGenerator.CreateResources(aLocs: TKMPointArray; var A: TKMByte2Array): TBalancedResource1Array;
var
  X,Y,Loc,I,K,overflow,cnt_ADD, ALL_RES_RADIUS, CENTER_RES, cnt_FINAL, cnt_ACTUAL, RESOURCE: Integer;
  PROB_REDUCER: Single;
  Voronoi,Count: TInteger2Array;
  TP_S,TP_E, Pom: TKMPoint;
  ResSettings: TIntegerArray;
  ResAmount, ResTilesAmount: array[0..4] of Integer; // Amount of tiles of specific resources
  Locs, Points: TKMPointArray;
  Visited: TBoolean2Array;
  PointsArr: TKMPoint2Array;
  SearchResource: TKMSearchBiome;
  FillResource: TKMFloodWithQueue;
  Output: TBalancedResource1Array;
const
  Resources: array[0..4] of TBiomeType = (btIron,btGold,btStone,btCoal,btCoal);
  VORONOI_STEP = 3;
  RES_PROB: array[0..4] of Single = (0.07,0.07,0.15,0.03,0.03); // Probability penalization (only afect final shape: 0 = circle, 1 = multiple separated mountains)
  SPEC_RES_RADIUS: array[0..4] of Byte = (5, 5, 5, 5, 5); // Iron, Gold, Stone, Coal, Coal
  RES_MULTIPLICATION: array[0..4] of Integer = (50, 50, 200, 100, 50);
  RES_DIVISION: array[0..4] of Single = (1/1.7, 1/1.7, 1/7, 1/1.7, 1/1.7); // Inverse it now and in computation use multiplication (faster)

begin

  // Initialization - Voroni diagram = divide map into small shapes which will be merged later; each shape have its point in PointsArr for fast searching
  Voronoi := VoronoiMod(VORONOI_STEP, PointsArr);

  // Make grid from Voronoi diagram with center points (PointsArr) and count of points in 1 shape (Count)
  SetLength(Count, Length(PointsArr), Length(PointsArr[Low(PointsArr)]));
  SearchResource := TKMSearchBiome.Create(  KMPoint(  Low(A[0]), Low(A) ), KMPoint(  High(A[0]), High(A)  ), Voronoi  );
  try
    for I := Low(PointsArr) to High(PointsArr) do
      for K := Low(PointsArr[I]) to High(PointsArr[I]) do
      begin
        Count[I,K] := 0;
        X := PointsArr[I,K].X;
        Y := PointsArr[I,K].Y;
        SearchResource.QuickFlood(X,Y, Voronoi[Y,X], -Voronoi[Y,X]);
        Count[I,K] := SearchResource.Count;
      end;
  finally
    SearchResource.Free;
  end;

  with RMGSettings.Locs.Resource do
  begin
    ResSettings := TIntegerArray.Create(Iron, Gold, Stone, Iron, Gold);
    for I := Low(ResSettings) to High(ResSettings) do
    begin
      ResAmount[I] := ResSettings[I] * RES_MULTIPLICATION[I];
      ResTilesAmount[I] := Trunc(ResAmount[I] * RES_DIVISION[I]);
    end;
    ALL_RES_RADIUS := Round(((Iron*3 + Gold*2 + Stone) shr 1) / VORONOI_STEP);
    CENTER_RES := Round(ALL_RES_RADIUS / 2);
  end;

  // Resources
  //{
  if RMGSettings.Locs.Resource.Active then
  begin
    SetLength(Locs,Length(aLocs));
    FillResource := TKMFloodWithQueue.Create(fRNG, PointsArr, Count, Voronoi, A);
    try
      for Loc := Low(aLocs) to High(aLocs) do
      begin
      // Transfer aLoc into new coordination (Voronoi array is VORONOI_STEPx smaller)
        Locs[Loc] := KMPoint(  aLocs[Loc].X div VORONOI_STEP, aLocs[Loc].Y div VORONOI_STEP  );
      // Generate points around loc (center points of resources)
        TP_S := KMPoint(  Locs[Loc].X - ALL_RES_RADIUS, Locs[Loc].Y - ALL_RES_RADIUS  );
        TP_E := KMPoint(  Locs[Loc].X + ALL_RES_RADIUS, Locs[Loc].Y + ALL_RES_RADIUS  );
        Points := RNDPoints(3, CENTER_RES, TP_S, TP_E);
      // Sometimes switch gold and iron
        if (fRNG.RandomI(2) = 1) then
        begin
          Pom := Points[0];
          Points[0] := Points[1];
          Points[1] := Pom;
        end;
      // Add space for coal
        SetLength(Points,Length(Points)+2);
        Points[3] := Points[1];
        Points[4] := Points[2];
        for I := Low(ResAmount) to High(ResAmount) do
          if (ResAmount[I] > 0) then
          begin
          // Initialization of parameters for shape generator
            RESOURCE := Byte(Resources[I]);
            PROB_REDUCER := RES_PROB[I];
            cnt_FINAL := ResTilesAmount[I];
            cnt_ACTUAL := 0;
            cnt_ADD := 0;
            TP_S := KMPoint(  Max(Points[I].X - SPEC_RES_RADIUS[I], 1), Max(Points[I].Y - SPEC_RES_RADIUS[I], 1)  );
            TP_E := KMPoint(  Min(Points[I].X + SPEC_RES_RADIUS[I], High(PointsArr[0]) - 1), Min(Points[I].Y + SPEC_RES_RADIUS[I], High(PointsArr) - 1)  );
          // Create new "mountain" of resources
            overflow := 0;
            while (cnt_ACTUAL < cnt_FINAL) AND (overflow < 10) do
            begin
              overflow := overflow + 1;
            // Find unused shape
              Points[I] := KMPoint(  TP_S.X + fRNG.RandomI(TP_E.X-TP_S.X), TP_S.Y + fRNG.RandomI(TP_E.Y-TP_S.Y)  );
              if (Count[Points[I].Y,Points[I].X] > 0) then
              begin
                SetLength(Output, Length(Output)+1); // Just a few interation so SetLength is fine
              // Merge shapes from Voronoi until we reach desired size
                FillResource.FloodFillWithQueue(Points[I].X, Points[I].Y, cnt_FINAL, cnt_ACTUAL, RESOURCE, 1, PROB_REDUCER, Output[ High(Output) ].Points);
                Output[ High(Output) ].Quantity := Round( (Min(cnt_FINAL, cnt_ACTUAL) - cnt_ADD) / Max(1,cnt_FINAL) * ResAmount[I]);
                Output[ High(Output) ].Resource := RESOURCE;
                cnt_ADD := cnt_ACTUAL;
              end;
            end;
          end;
      end;
    finally
      FillResource.Free;
    end;
  end;

  if RMGSettings.Obstacle.Active then
    CreateObstacles(Locs, A,  Voronoi,  PointsArr);


  if RMGSettings.Locs.Resource.Active then
  begin
    // Debug: add edges of resources (non-walk textures have low priority and their edges are always transitions)
    //for Y := High(A)-1 downto 1 do
	   // for X := High(A[Y])-1 downto 1 do
    //    if (A[Y,X] = Byte(btStone)) OR (A[Y,X] = Byte(btGold)) OR (A[Y,X] = Byte(btIron)) then //OR (A[Y,X] = Byte(btCoal))
    //    begin
    //       A[Y+1,X] := A[Y,X];
    //       A[Y,X+1] := A[Y,X];
    //       A[Y+1,X+1] := A[Y,X];
    //    end;
    //for Y := 1 to High(A)-1 do
	   // for X := 1 to High(A[Y])-1 do
    //    if (A[Y,X] = Byte(btStone)) OR (A[Y,X] = Byte(btGold)) OR (A[Y,X] = Byte(btIron)) then //OR (A[Y,X] = Byte(btCoal))
    //    begin
    //       A[Y-1,X] := A[Y,X];
    //       A[Y,X-1] := A[Y,X];
    //       A[Y-1,X-1] := A[Y,X];
    //    end;


    if RMGSettings.Locs.Resource.MineFix then
    begin
      SetLength(Visited, gTerrain.MapY+1, gTerrain.MapX+1);
      for I := Low(Visited) to High(Visited) do
        for K := Low(Visited[I]) to High(Visited[I]) do
          Visited[I,K] := False;

      for i := Low(Output) to High(Output) do
      begin
        if (Output[I].Resource = Byte(btGold)) then
          RESOURCE := 2
        else if (Output[I].Resource = Byte(btIron)) then
          RESOURCE := 3
        else // Coal and Stone are always fine
          continue;
        for K := Low(Output[I].Points) to High(Output[I].Points) do
          if not Visited[ Output[I].Points[K].Y , Output[I].Points[K].X ] then
            MineFix(Output[I].Points[K], RESOURCE, Output[I].Resource, Visited, A);
      end;
    end;
  end;

  Result := Output;
end;
//}


// Create obstacles (eIron, eGold, watter, swamp and wetland) - obstacles are created via seeds and array of probabilities it is basicaly RANDOM WALK in probability array
// aLocs = expected player's position (those will have protected radius to secure that player have place for city)
// A = TKMByte2Array for obstacles
// aVoronoi = Voronoi diagram (same diagram for resource generator and for obstacle generator => avoid to replace resources with obstacles)
// aPointsArr = points of Voronoi diagram (easy way how to find each shape)
procedure TKMRandomMapGenerator.CreateObstacles(aLocs: TKMPointArray; var A: TKMByte2Array; var aVoronoi: TInteger2Array; var aPointsArr: TKMPoint2Array);
// Connect Locs with zero chance to create obstacles = secure that player in loc X can walk to player with loc Y
  procedure ConnectLocs(aLocs: TKMPointArray; var P: TSingle2Array);
  var
    HighIdx, idx: Integer;
    Loc, Pos, Vector: TKMPoint;
  begin
    HighIdx := High(aLocs);
    while HighIdx > 0 do
    begin
      // Randomly pick locs
      idx := fRNG.RandomI(HighIdx);
      Pos := aLocs[idx];
      Loc := aLocs[HighIdx];
      // Create vector in direction of second player (connected route will be line)
      if (Loc.X > Pos.X) then      Vector.X := 1
      else if (Loc.X = Pos.X) then Vector.X := 0
      else                         Vector.X := -1;
      if (Loc.Y > Pos.Y) then      Vector.Y := 1
      else if (Loc.Y = Pos.Y) then Vector.Y := 0
      else                         Vector.Y := -1;
      //  Make route to another one
      while (Loc.X <> Pos.X) OR (Loc.Y <> Pos.Y) do
      begin
        if (Pos.X <> Loc.X) then Pos.X := Pos.X + Vector.X;
        if (Pos.Y <> Loc.Y) then Pos.Y := Pos.Y + Vector.Y;
        if (P[Pos.Y,Pos.X] = 0) then
          break;
        P[Pos.Y,Pos.X] := 0;
        if ((Pos.Y-Vector.Y) >= Low(P)) AND ((Pos.Y-Vector.Y) <= High(P)) then
        begin
          P[Pos.Y-Vector.Y,Pos.X] := 0;
          if ((Pos.X-Vector.X) >= Low(P[0])) AND ((Pos.X-Vector.X) <= High(P[0])) then
          begin
            P[Pos.Y,Pos.X-Vector.X] := 0;
            P[Pos.Y-Vector.Y,Pos.X-Vector.X] := 0;
          end;
        end
        else if ((Pos.X-Vector.X) >= Low(P[0])) AND ((Pos.X-Vector.X) <= High(P[0])) then
          P[Pos.Y,Pos.X-Vector.X] := 0;
      end;
      HighIdx := HighIdx - 1;
      Loc := aLocs[idx];
      aLocs[idx] := aLocs[HighIdx];
      aLocs[HighIdx] := Loc;
    end;
  end;

  var
    X,Y,I,K, MaxIdx, MaxCnt, cntr, finalCnt, ObstBiome, ObstVariance: Integer;
    Factor,Probability, ProbabilityReducer: Single;
    check: Boolean;
    Obstacle: TObstacleType;
    ProbIdx: array[0..3] of Byte;
    Prob: array[0..3] of Single;
    Dir: array[0..3] of TKMPoint;
    P: TSingle2Array;
    ObstacleSeeds: TKMPointArray;
    OBST_Probability: array[TObstacleType] of Single;
    FillObstacle: TKMFillBiome;
  const
    EXPAND_RESTRICTION: array[TObstacleType] of Byte = (3,1,2,4,4);
    OBST2BIOME: array[TObstacleType] of TBiomeType = (btSwamp,btWater,btWetland,btEgold,btEIron);
begin

// Initialization
  SetLength(P, Length(aPointsArr), Length(aPointsArr[Low(aPointsArr)]));
  for Y := Low(aPointsArr) to High(aPointsArr) do
    for X := Low(aPointsArr[Y]) to High(aPointsArr[Y]) do
      P[Y,X] := 1;

  // Create protected radius = array with smaller chance to spawn obstacle near aLocs
  if RMGSettings.Locs.Resource.Active then
  begin
    ProbabilityReducer := (11 - RMGSettings.Obstacle.ProtectedRadius) * 0.01;
    MaxCnt := Round(1 / ProbabilityReducer);
    if RMGSettings.Locs.Resource.ConnectLocs then
      ConnectLocs(aLocs, P);
    for I := Low(aLocs) to High(aLocs) do
      for Y := Max(  Low(P), aLocs[I].Y - MaxCnt  ) to Min(  High(P), aLocs[I].Y + MaxCnt  ) do
        for X := Max(  Low(P[Y]), aLocs[I].X - MaxCnt  ) to Min(  High(P[Y]), aLocs[I].X + MaxCnt  ) do
        begin
          Probability := (  Abs(aLocs[I].X - X) + Abs(aLocs[I].Y - Y)  ) * ProbabilityReducer;
          if (P[Y,X] > Probability) then
            P[Y,X] := Probability;
        end;
  end;

  // Calculate probability of all obstacles from RMGSettings (obstacles are selected by random number in interval <0,1) )
  Factor := 0;
  for Obstacle := Low(TObstacleType) to High(TObstacleType) do
    Factor := Factor + Trunc(RMGSettings.Obstacle.Ratio[ Obstacle ]);
  OBST_Probability[otSwamp] := RMGSettings.Obstacle.Ratio[ otSwamp ] / Factor;
  OBST_Probability[otWater] := OBST_Probability[otSwamp] + RMGSettings.Obstacle.Ratio[ otWater ] / Factor;
  OBST_Probability[otWetland] := OBST_Probability[otWater] + RMGSettings.Obstacle.Ratio[ otWetland ] / Factor;
  OBST_Probability[otEgold] := OBST_Probability[otWetland] + RMGSettings.Obstacle.Ratio[ otEgold ] / Factor;
  OBST_Probability[otEIron] := 1;

  // Make obstacles
  ObstacleSeeds := RNDPoints(RMGSettings.Obstacle.Density*10, 0, KMPoint( Low(P[0]), Low(P) ), KMPoint( High(P[0]), High(P) ));
  FillObstacle := TKMFillBiome.Create( KMPoint(  Low(A[0]), Low(A) ), KMPoint( High(A[0]), High(A) ), aVoronoi, A);
  try
    for I := Low(ObstacleSeeds) to High(ObstacleSeeds) do
    begin
      // Get seed
      X := ObstacleSeeds[I].X;
      Y := ObstacleSeeds[I].Y;
      Probability := fRNG.Random();
      for Obstacle := Low(TObstacleType) to High(TObstacleType) do
        if (Probability < OBST_Probability[Obstacle]) then
          break;
      ObstBiome := Byte( OBST2BIOME[Obstacle] );

      // Fill array A with obstacles
      cntr := 0;
      finalCnt := Max(1,Round((1 - fRNG.Random() * RMGSettings.Obstacle.Variance / 10) * RMGSettings.Obstacle.Size));
      check := True;
      while check AND (cntr < finalCnt) do
      begin
        // Scan surrounding points
        cntr := cntr + 1;
        Dir[0] := KMPoint( X, Min(Y+1, High(P)) );
        Dir[1] := KMPoint( X, Max(Y-1, Low(P)) );
        Dir[2] := KMPoint( Min(X+1, High(P[Y])), Y );
        Dir[3] := KMPoint( Max(X-1, Low(P[Y])), Y );

        MaxIdx := 0;
        for K := Low(Dir) to High(Dir) do
        begin
          Prob[K] := P[Dir[K].Y,Dir[K].X];
          if (Prob[MaxIdx] < Prob[K]) then
            MaxIdx := K;
        end;
        MaxCnt := 0;
        for K := Low(Dir) to High(Dir) do
          if (Prob[MaxIdx] = Prob[K]) then
          begin
            ProbIdx[MaxCnt] := K;
            MaxCnt := MaxCnt + 1;
          end;

        check := False;
        for K := 1 to Min(MaxCnt, fRNG.RandomI(EXPAND_RESTRICTION[Obstacle]) + 1) do
        begin
          MaxIdx := fRNG.RandomI(MaxCnt);
          if (fRNG.Random < Prob[ ProbIdx[MaxIdx] ]) then
          begin
            X := aPointsArr[  Dir[ ProbIdx[MaxIdx] ].Y, Dir[ ProbIdx[MaxIdx] ].X  ].X;
            Y := aPointsArr[  Dir[ ProbIdx[MaxIdx] ].Y, Dir[ ProbIdx[MaxIdx] ].X  ].Y;
            if (aVoronoi[Y,X] <> 0) then
              FillObstacle.QuickFlood(X, Y, aVoronoi[Y,X], 0, ObstBiome);

            X := Dir[ ProbIdx[MaxIdx] ].X;
            Y := Dir[ ProbIdx[MaxIdx] ].Y;
            P[Y,X] := 0;
            ProbIdx[MaxIdx] := ProbIdx[MaxCnt-1];
            MaxCnt := MaxCnt - 1;
            check := True;
          end;
        end;
      end;
    end;
  finally
    FillObstacle.Free;
  end;
end;





// Fixer of mountains with iron or gold to be able to place mines there
procedure TKMRandomMapGenerator.MineFix(const Position: TKMPoint; const MINESIZE, Resource: Byte; var Visited: TBoolean2Array; var A: TKMByte2Array);
type
  TLimitShape = record
    Active: Boolean;
    Min,Max: SmallInt;
  end;
var
  Shape: array of TLimitShape;
// Search maximal and minimal values of each column in shape
  procedure MinerFixFloodSearch(const Y,X: Integer);
  begin
    if not Visited[Y,X] AND (A[Y,X] = Resource) then
    begin
      Visited[Y,X] := True;
      Shape[X].Active := True;
      if (Y >= Shape[X].Max) then
      begin
        Shape[X].Max := Y;
        if (A[Y+1,X] <> Resource) AND (A[Y+1,X] <> Byte(btCoal)) then
          A[Y+1,X] := 0;
      end;
      if (Y < Shape[X].Min) then
        Shape[X].Min := Y;

      if (Y < gTerrain.MapY-1) then MinerFixFloodSearch(Y+1,X);
      if (Y > 1)               then MinerFixFloodSearch(Y-1,X);
      if (X < gTerrain.MapX-1) then MinerFixFloodSearch(Y,X+1);
      if (X > 1)               then MinerFixFloodSearch(Y,X-1);
    end;
  end;

  var
    X,aX,aaX,PossibleMineTileCnt,MinMineSize,DistFromLastMine, minVal, minIndex, startIndex, actVal, minPosition, MinPosIdx, MAX_MINE_DIST_COEF: Integer;
    MinLimit, MaxLimit: TSmallIntArray;
    MineSearch: TKMMinerFixSearch;
begin

// Initialization
  SetLength(Shape,Length(A[0])+2);
  SetLength(MinLimit, Length(A[0])+2);
  SetLength(MaxLimit, Length(A[0])+2);
  for X := Low(Shape) to High(Shape) do
  begin
    Shape[X].Active := False;
    Shape[X].Min := High(MinLimit);
    MinLimit[X] := High(MinLimit);
    Shape[X].Max := Low(MaxLimit);
    MaxLimit[X] := Low(MaxLimit);
  end;

// Detect shape of resource
  if RMGSettings.Objects.Active then
  begin

    MineSearch := TKMMinerFixSearch.Create(  KMPoint(  Low(A[0]), Low(A) ), KMPoint( High(A[0]), High(A) ), MinLimit, MaxLimit, Visited, A  );
    try
      MineSearch.QuickFlood(Position.X,Position.Y,Resource);
    finally
      MineSearch.Free;
    end;
    for X := Low(Shape) to High(Shape) do
      if (Shape[X].Min <> MinLimit[X]) then
      begin
        Shape[X].Active := True;
        Shape[X].Min := MinLimit[X];
        Shape[X].Max := MaxLimit[X];
      end;
  end
  else
    MinerFixFloodSearch(Position.Y, Position.X);

// Find start index of shape
  X := 0;
  while not Shape[X].Active AND (X < High(Shape)) do
    X := X+1;

// Change shape to be able to mine resources here
  PossibleMineTileCnt := 0;
  DistFromLastMine := 0;
  MinMineSize := MINESIZE + 2;
  MAX_MINE_DIST_COEF := MinMineSize shl 1;
  while Shape[X].Active do
  begin
    X := X + 1;
    DistFromLastMine := DistFromLastMine + 1;
  // Calculate difference of 2 neighboring tiles - when they are same check whether we can place mines there
    if (Shape[X-1].Max - Shape[X].Max) = 0 then
    begin
      PossibleMineTileCnt := PossibleMineTileCnt + 1;
      if (PossibleMineTileCnt >= MinMineSize) then
        DistFromLastMine := 0;  // And reset counter of last mine if we can
    end
    else
      PossibleMineTileCnt := 0; // Or reset counter of possible mine
  // When we are too far tiles must be fixed
    if (DistFromLastMine > MAX_MINE_DIST_COEF) then
    begin
      minVal := High(Integer);
      minIndex := 0;
    // Scan last interval of tiles and find best spot for fix
      for aX := X-DistFromLastMine to X-MinMineSize do
      begin
      // Find a smallest point in minimal interval of possible mine
        minPosition := gTerrain.MapY;
        for aaX := aX to aX+MinMineSize do
          if (Shape[aaX].Max < minPosition) then
          begin
            minPosition := Shape[aaX].Max;
            MinPosIdx := aaX;
          end;
      // Calculate the price of transformation which secure place mine (price = penalization of deleted tiles)
        actVal := 0;
        for aaX := aX to aX+MinMineSize do
          actVal := actVal + Shape[aaX].Max - minPosition;
      // Save best solution (closer to right is better)
        if (actVal <= minVal) then
        begin
          minVal := actVal;
          minIndex := MinPosIdx;
          startIndex := aX;
        end;
      end;
    // Apply changes
      for aX := startIndex to startIndex + MinMineSize do
      begin
        aaX := Shape[aX].Max;
        while (aaX > Shape[minIndex].Max) AND (aaX >= Shape[aX].Min) do
        begin
          Shape[aX].Max := Shape[aX].Max - 1;
          A[aaX,aX] := 0;
          aaX := aaX - 1;
        end;
      end;
      X := minIndex + MinMineSize;
      DistFromLastMine := 0;
      PossibleMineTileCnt := MinMineSize;
    end;
  end;
end;






// Cellular automaton - CA will secure that each tile has in his surrounding at leas another 3 tiles and together they make square
// A = TKMByte2Array of biomes
procedure TKMRandomMapGenerator.CellularAutomaton(var A: TKMByte2Array);
var
  X0,X1,X2,Y0,Y1,Y2,overflow: Integer;
  LT,RT,RD,LD,repeatWhile: Boolean;
begin
  // Cellular automaton, Moore neighborhood:
  //    ____________________________                         _________
  //   | [Y0,X0]  [Y0,X1]  [Y0,X2] |    indexes of Result:  | 0  1  2 |
  //   | [Y1,X0]     X     [Y1,X2] |                        | 7  x  3 |
  //   | [Y2,X0]  [Y2,X1]  [Y2,X2] |                        | 6  5  4 |
  //    ———————————————————————————                          —————————
  overflow := 0;
  repeatWhile := true;
  // There are changes which affect previous tiles so the cycle somethimes have to be repeated
  while repeatWhile AND (overflow < 10) do
  begin
    overflow := overflow + 1;
    repeatWhile := false;
    for Y1 := 1 to High(A)-2 do
    begin
      Y0 := Y1-1;
      Y2 := Y1+1;
      X1 := 1;
    while X1 < High(A[Y1])-2 do
      begin
	      X0 := X1-1;
        X2 := X1+1;

        LT := False;
        RT := False;
        RD := False;
        LD := False;

        // Detect same corners
        if (A[Y0,X0] = A[Y1,X0]) AND (A[Y0,X0] = A[Y0,X1]) then LT := True;
        if (A[Y0,X2] = A[Y0,X1]) AND (A[Y0,X2] = A[Y1,X2]) then RT := True;
        if (A[Y2,X2] = A[Y1,X2]) AND (A[Y2,X2] = A[Y2,X1]) then RD := True;
        if (A[Y2,X0] = A[Y2,X1]) AND (A[Y2,X0] = A[Y1,X0]) then LD := True;

        // If are rules broken, apply another logic
        if      (A[Y0,X0] = A[Y1,X1]) AND LT then begin  end
        else if (A[Y0,X2] = A[Y1,X1]) AND RT then begin  end
        else if (A[Y2,X2] = A[Y1,X1]) AND RD then begin  end
        else if (A[Y2,X0] = A[Y1,X1]) AND LD then begin  end
        else
        begin
          if LT then
          begin
            A[Y1,X1] := A[Y0,X0];
            if RD AND not RT then
              A[Y2,X0] := A[Y0,X0];
          end else if RT then
          begin
            A[Y1,X1] := A[Y0,X2];
            if LD then
              A[Y2,X2] := A[Y0,X2];
          end else if RD then
            A[Y1,X1] := A[Y2,X2]
          else if LD then
            A[Y1,X1] := A[Y2,X0]

          else// if A[Y1,X1] > 0 then // When is grass here do nothing
          begin
            repeatWhile := true;
            if (A[Y1,X1] = A[Y1,X0]) then
            begin
              A[Y2,X0] := A[Y1,X1];
              A[Y2,X1] := A[Y1,X1];
            end
            else if (A[Y1,X1] = A[Y1,X2]) then
            begin
              A[Y2,X1] := A[Y1,X1];
              A[Y2,X2] := A[Y1,X1];
            end
            else// if A[Y1,X0] = A[Y1,X2] then
              A[Y1,X1] := A[Y1,X0];
          end;
        end;

        // Corners are OK, now check tiles under rectangle
        //{
        if (X1 > 1) AND (A[Y1,X1] <> A[Y2,X1]) then
        begin
      	  if (A[Y2,X1] = A[Y2,X0]) AND (A[Y2,X1] = A[Y1,X0]) AND (A[Y2,X1] = A[Y1,X0-1]) then
          begin
      	    A[Y2,X0-1] := A[Y2,X1];
            A[Y2+1,X0-1] := A[Y2,X1];
            A[Y2+1,X0] := A[Y2,X1];
      	  end;
      	  if (A[Y2,X1] = A[Y2,X2]) AND (A[Y2,X1] = A[Y1,X2]) AND (A[Y2,X1] = A[Y1,X2+1]) then
          begin
      	    A[Y2,X2+1] := A[Y2,X1];
            A[Y2+1,X2+1] := A[Y2,X1];
            A[Y2+1,X2] := A[Y2,X1];
      	  end;
        end;
        //}
        X1 := X1 + 1;
      end;
    end;
  end;

  // Debug
  {
  if overflow > 8 then
  begin
  end;
  //}
end;



// This function will try to create smooth transitions with special decomposition of basic tiles
// A = TKMByte2Array of biomes
// Result = TKMByte2Array of tiles decomposition (1 tile of biome = array of 2x2 tiles of biomes)
// for more info visit KaM Remake forum in section Map Design topic Random Map Generator
function TKMRandomMapGenerator.TileTemplate(var A: TKMByte2Array): TKMByte2Array;
type
  TileTemplateArr = array[0..2,0..2] of Integer;
var
   X,Y, X0,X1,X2,X3, Y0,Y1,Y2,Y3, sum,LT,LD,RT,RD: Integer;
   B: array of array of TileTemplateArr;
   Res: TKMByte2Array;
const
  canWalk: array[0..23] of Boolean = (
    True,True,False,False,False,True,True,True,True,True,True,True,False,True,True,True,True,True,False,False,False,False,False,False
  );
  TerrainPreference: array[0..23,0..4] of Byte = (
    (0,1,14,255,255),(0,1,14,255,255),(2,3,4,0,255),(2,3,4,0,255),(2,19,20,21,22),(5,6,7,8,255),(5,6,7,8,255),(5,6,7,8,255),(6,7,0,1,255),(5,6,7,255,255),(9,10,11,255,255),(9,10,11,255,255),(4,255,255,255,255),(13,15,16,17,255),(0,1,8,14,255),(13,15,16,17,255),(13,15,16,17,255),(13,15,16,17,255),(0,255,255,255,255),(19,20,255,255,255),(19,20,255,255,255),(21,22,255,255,255),(21,22,255,255,255),(21,22,255,255,255)
  );

  // Choose minimal value (biome) by specific rules
  function ChooseMin(const A,B: Integer): Integer;
  begin
    if ((not canWalk[B] OR (A < B)) AND canWalk[A]) then
      Result := A
    else
      Result := B;
  end;

  // Check whether is biome similar to another biom
  function IsEqualBiom(var Base, Biom: Integer): Boolean;
  var
    I: Integer;
  begin
    Result := False;
    for I := Low(TerrainPreference[Base]) to High(TerrainPreference[Base]) do
      if (TerrainPreference[Base,I] = Biom) then
      begin
        Result := True;
        Exit;
      end;
  end;

  // Choose similar biom for which we have exist (base) tile
  procedure TilePreference(var T1, T2, Base: Integer);
  begin
    if IsEqualBiom(Base, T1) then
      T1 := Base
    else if IsEqualBiom(Base, T2) then
      T2 := Base
    else if (not canWalk[T1] OR (T1 > T2)) AND canWalk[T2] then
      T1 := T2
    else
      T2 := T1;
  end;

  // Water-transition with mountain is fully-watter texture so it must be fixed by this procedure
  procedure WaterMountainFix(var Res1, Walk1,Walk2: Byte);
  begin
    if canWalk[ Walk1 ] then
    begin
      Res1 := Byte(btWater);
      Walk2 := Byte(btWater);
    end
    else if canWalk[ Walk2 ] then
    begin
      Res1 := Byte(btWater);
      Walk1 := Byte(btWater);
    end;
  end;

begin

  SetLength(B, Length(A), Length(A[Low(A)]));
  SetLength(Res, Length(A) shl 1, Length(A[Low(A)]) shl 1);

// Shortcuts (orientation in array A and B [+ array B have another 3x3 array in each element]):
//    _____________________________
//   | [Y0,X0]   [Y0,X1]   [Y0,X2] |
//   | [Y1,X0]   [Y1,X1]   [Y1,X2] |    where [Y1,X1] is center point which will be modified
//   | [Y2,X0]   [Y2,X1]   [Y2,X2] |
//    —————————————————————————————
	for Y1 := 1 to gTerrain.MapY-1 do
  begin
    Y0 := Y1 - 1;
		for X1 := 1 to gTerrain.MapX-1 do
    begin
      X0 := X1 - 1;
    // Detect 8 surrounding tiles and store ideal transition of each tile into B
      for Y := 0 to 2 do
        for X := 0 to 2 do
        begin
          B[Y1,X1,Y,X] := BT[ A[Y1,X1] , A[Y0+Y,X0+X] ];
          if (B[Y1,X1,Y,X] = -1) then
            B[Y1,X1,Y,X] := A[Y1,X1];
        end;
      B[Y1,X1,1,1] := A[Y1,X1];
    end;
  end;

// Transitions (decimal, hexadecimal, binary):
//    ______________     ____________     _______________
//   | 1 › Top  ‹ 2 |   | 1 › $2 ‹ 2 |   | 1 › %0010 ‹ 2 |
//   | ˇ          ˇ |   | ˇ        ˇ |   | ˇ           ˇ |
//   | Left   Right |   | $1      $4 |   | %0001   %0100 |
//   | ^          ^ |   | ^        ^ |   | ^           ^ |
//   | 3 › Down ‹ 4 |   | 3 › $8 ‹ 4 |   | 3 › %1000 ‹ 4 |
//    ——————————————     ————————————     ———————————————

// Basic detection (can / cannot draw tile)
//{
  for Y1 := 1 to gTerrain.MapY-1 do
  begin
    Y := Y1 shl 1;
    Y0 := Y1 - 1;
    Y2 := Y1 + 1;
    for X1 := 1 to gTerrain.MapX-1 do
    begin
      X := X1 shl 1;
      // Create mask
      sum := (Byte(B[Y1,X1,1,1] = B[Y1,X1,1,0]) shl 0) OR
             (Byte(B[Y1,X1,1,1] = B[Y1,X1,0,1]) shl 1) OR
             (Byte(B[Y1,X1,1,1] = B[Y1,X1,1,2]) shl 2) OR
             (Byte(B[Y1,X1,1,1] = B[Y1,X1,2,1]) shl 3);

      case sum of
      // 1 side is equal
        // Left %0001
        1:  begin LT := B[Y1,X1,1,1]; RT := B[Y1,X1,1,2]; RD := B[Y1,X1,1,2]; LD := B[Y1,X1,1,1]; end;
        // Top %0010
        2:  begin LT := B[Y1,X1,1,1]; RT := B[Y1,X1,1,1]; RD := B[Y1,X1,2,1]; LD := B[Y1,X1,2,1]; end;
        // Right %0100
        4:  begin LT := B[Y1,X1,1,0]; RT := B[Y1,X1,1,1]; RD := B[Y1,X1,1,1]; LD := B[Y1,X1,1,0]; end;
        // Down %1000
        8:  begin LT := B[Y1,X1,0,1]; RT := B[Y1,X1,0,1]; RD := B[Y1,X1,1,1]; LD := B[Y1,X1,1,1]; end;
      // 2 sides are equal
        // Left Top %0011
        3: begin LT := B[Y1,X1,1,1]; RT := B[Y0,X1,2,2]; RD := B[Y1,X1,2,2]; LD := B[Y2,X1,0,0]; end;
        // Right Top %0110
        6: begin LT := B[Y0,X1,2,0]; RT := B[Y1,X1,1,1]; RD := B[Y2,X1,0,2]; LD := B[Y1,X1,2,0]; end;
        // Right Down %1100
       12: begin LT := B[Y1,X1,0,0]; RT := B[Y0,X1,2,2]; RD := B[Y1,X1,1,1]; LD := B[Y2,X1,0,0]; end;
        // Left Down %1001
        9: begin LT := B[Y0,X1,2,0]; RT := B[Y1,X1,0,2]; RD := B[Y2,X1,0,2]; LD := B[Y1,X1,1,1]; end;
      // 3 sides are equal
        // Left Top Right %0111
        7: begin LT := B[Y1,X1,1,1]; RT := B[Y1,X1,1,1]; RD := B[Y1,X1,2,1]; LD := B[Y1,X1,2,1]; end;
        // Left Down Right %1101
       13: begin LT := B[Y1,X1,0,1]; RT := B[Y1,X1,0,1]; RD := B[Y1,X1,1,1]; LD := B[Y1,X1,1,1]; end;
        // Top Right Down %1110
       14: begin LT := B[Y1,X1,1,0]; RT := B[Y1,X1,1,1]; RD := B[Y1,X1,1,1]; LD := B[Y1,X1,1,0]; end;
        // Top Left Down %1011
       11: begin LT := B[Y1,X1,1,1]; RT := B[Y1,X1,1,2]; RD := B[Y1,X1,1,2]; LD := B[Y1,X1,1,1]; end;
      // All sides are equal
        else // or 15: begin end;
           begin LT := B[Y1,X1,0,0]; RT := B[Y1,X1,0,2]; RD := B[Y1,X1,2,2]; LD := B[Y1,X1,2,0]; end;
        end;
      // Actualize tile (array 2x2 which represent it)
        Res[Y,X] := LT;
        Res[Y,X+1] := RT;
        Res[Y+1,X+1] := RD;
        Res[Y+1,X] := LD;
    end;
  end;
//}

// Advanced detection (when we cannot draw tile try another logic with 2x2 array wich represet each tile)
//{
  for Y := 1 to gTerrain.MapY-1 do
  begin
    Y1 := Y shl 1;
    Y2 := Y1 + 1;
  	for X := 1 to gTerrain.MapX-1 do
    begin
      X1 := X shl 1;
      X2 := X1 + 1;
      sum := Byte(Res[Y1,X1] = Res[Y1,X2]) +
             Byte(Res[Y1,X1] = Res[Y2,X1]) +
             Byte(Res[Y2,X2] = Res[Y1,X2]) +
             Byte(Res[Y2,X2] = Res[Y2,X1]);
      if (sum < 2) then
      begin
        Y0 := Y1 - 1;
        Y3 := Y1 + 2;
        X0 := X1 - 1;
        X3 := X1 + 2;
        LT := ChooseMin( ChooseMin(Res[Y0,X0],Res[Y1,X0]), Res[Y0,X1] );
        RT := ChooseMin( ChooseMin(Res[Y0,X3],Res[Y1,X3]), Res[Y0,X2] );
        RD := ChooseMin( ChooseMin(Res[Y3,X3],Res[Y2,X3]), Res[Y3,X2] );
        LD := ChooseMin( ChooseMin(Res[Y3,X0],Res[Y2,X0]), Res[Y3,X1] );
        sum := (Byte(LD = LT) shl 0) OR
               (Byte(LT = RT) shl 1) OR
               (Byte(RT = RD) shl 2) OR
               (Byte(RD = LD) shl 3);
        case sum of
        // 3 different tiles, 2 same tiles are in:
          1:  begin // Left
                TilePreference(RT, RD, LT);
              end;
          2:  begin // Top
                TilePreference(LD, RD, LT);
              end;
          4:  begin // Right
                TilePreference(LT, LD, RD);
              end;
          8:  begin // Down
                TilePreference(LT, RT, RD);
              end;
          // 4 different tiles
          0:  begin
              // Special case with same diagonal tiles
                if (LT = RD) then // Left top = right down
                begin
                  if (RT < LD) then
                    LD := LT
                  else
                    RT := LT;
                end
                else if (RT = LD) then // Right top = left down
                begin
                  if (LT < RD) then
                    RD := RT
                  else
                    LT := RT;
                end
              // 4 different tiles
                else
                begin
                  if IsEqualBiom(LD, LT) then // Left
                  begin
                    LT := ChooseMin(LT, LD);
                    LD := LT;
                    TilePreference(RT, RD, LT);
                  end
                  else if IsEqualBiom(LT, RT) then // Top
                  begin
                    LT := ChooseMin(LT, RT);
                    RT := LT;
                    TilePreference(LD, RD, LT);
                  end
                  else if IsEqualBiom(RT, RD) then // Right
                  begin
                    RT := ChooseMin(RT, RD);
                    RD := RT;
                    TilePreference(LT, LD, RT);
                  end
                  else if IsEqualBiom(RD, LD) then // Down
                  begin
                    RD := ChooseMin(RD, LD);
                    LD := RD;
                    TilePreference(LT, RT, RD);
                  end
                  else if IsEqualBiom(LT, RD) then // Main diagonal
                  begin
                    LT := ChooseMin(LT, RD);
                    RD := LT;
                    if (RT < LD) then
                      LD := LT
                    else
                      RT := LT;
                  end
                  else if IsEqualBiom(RT, LD) then // Second diagonal
                  begin
                    RT := ChooseMin(RT, LD);
                    LD := RT;
                    if (LT < RD) then
                      RD := RT
                    else
                      LT := RT;
                  end
                  else // Try another loghic (this tile will have ugly transition anyway)
                  begin
                    RT := ChooseMin(RT, LT); LT := RT; RD := ChooseMin(RD, LD); LD := RD;
                    //LT := Byte(btDark); RT := Byte(btDark); RD := Byte(btDark); LD := Byte(btDark); // Debug
                  end;
                end;
              end;
        // Other cases
          else begin end;
        end;
        Res[Y1,X1] := LT;
        Res[Y1,X2] := RT;
        Res[Y2,X2] := RD;
        Res[Y2,X1] := LD;
      end;
    end;
  end;
  //}

// Problems which are caused by two tiles transitions (especialy in water)
//{
  for Y1 := 1 to High(Res)-1 do
  begin
    Y0 := Y1 - 1;
    Y2 := Y1 + 1;
		for X1 := 1 to High(Res[Y1])-1 do
    begin
      X0 := X1 - 1;
      X2 := X1 + 1;

      // Water fix
      if not canWalk[ Res[Y1,X1] ] then
      begin
        if canWalk[ Res[Y0,X1] ] AND canWalk[ Res[Y2,X1] ] then
        begin
          if (Y1 mod 2) > 0 then
            Res[Y1,X1] := Res[Y0,X1]
          else
            Res[Y1,X1] := Res[Y2,X1];
        end
        else if canWalk[ Res[Y1,X0] ] AND canWalk[ Res[Y1,X2] ] then
        begin
          if ((X1 mod 2) > 0)  then
            Res[Y1,X1] := Res[Y1,X0]
          else
            Res[Y1,X1] := Res[Y1,X2];
        end
        // Smooth transition in water near mountains and accessible terrain (make edge from side)
        else if (Res[Y1,X1] = Byte(btWater)) then
        begin
          if      canWalk[ Res[Y0,X1] ] AND not canWalk[ Res[Y2,X1] ] AND (Res[Y2,X1] >= Byte(btGold)) AND ((Y1 div 2) = (Y2 div 2)) then Res[Y0,X1] := Res[Y1,X1]
          else if canWalk[ Res[Y2,X1] ] AND not canWalk[ Res[Y0,X1] ] AND (Res[Y0,X1] >= Byte(btGold)) AND ((Y1 div 2) = (Y0 div 2)) then Res[Y2,X1] := Res[Y1,X1]
          else if canWalk[ Res[Y1,X0] ] AND not canWalk[ Res[Y1,X2] ] AND (Res[Y1,X2] >= Byte(btGold)) AND ((X1 div 2) = (X2 div 2)) then Res[Y1,X0] := Res[Y1,X1]
          else if canWalk[ Res[Y1,X2] ] AND not canWalk[ Res[Y1,X0] ] AND (Res[Y1,X0] >= Byte(btGold)) AND ((X1 div 2) = (X0 div 2)) then Res[Y1,X2] := Res[Y1,X1];
        end
        // Smooth transition: water - mountain - accessible biome
        else if (Res[Y1,X1] >= Byte(btGold)) then
        begin
          if      (Res[Y1,X0] = Byte(btWater)) AND (Res[Y0,X1] = Byte(btWater)) then WaterMountainFix( Res[Y1,X1], Res[Y1,X2], Res[Y2,X1])
          else if (Res[Y1,X2] = Byte(btWater)) AND (Res[Y0,X1] = Byte(btWater)) then WaterMountainFix( Res[Y1,X1], Res[Y1,X0], Res[Y2,X1])
          else if (Res[Y1,X0] = Byte(btWater)) AND (Res[Y2,X1] = Byte(btWater)) then WaterMountainFix( Res[Y1,X1], Res[Y1,X2], Res[Y0,X1])
          else if (Res[Y1,X2] = Byte(btWater)) AND (Res[Y2,X1] = Byte(btWater)) then WaterMountainFix( Res[Y1,X1], Res[Y1,X0], Res[Y0,X1]);
        end;
      end

      // 2 sides transition fix
      else if (Res[Y1,X0] = Res[Y1,X2]) AND (Res[Y1,X1] <> Res[Y1,X0]) AND canWalk[ Res[Y1,X0] ] then // Vertical problem
        Res[Y1,X1] := Res[Y1,X0]
      else if (Res[Y0,X1] = Res[Y2,X1]) AND (Res[Y1,X1] <> Res[Y0,X1]) AND canWalk[ Res[Y0,X1] ] then // Horizontal problem
        Res[Y1,X1] := Res[Y0,X1];
    end;
  end;
  //}

  Result := Res;
end;



// Replace textures which are surrounded by mountains by snow biome
// A = TKMByte2Array of biomes
procedure TKMRandomMapGenerator.SnowMountains(var A: TKMByte2Array);
  const
    IronMix: array[0..1] of TBiomeType = (btSnow1, btDark);
    GoldMix: array[0..1] of TBiomeType = (btGroundSnow, btSnow1);
  var
    X,Y, Count: Integer;
    PresentBiomes: Cardinal;
    lg2: Single;
    PathArr: TInteger2Array;
    FloodWalkSearch: TKMSearchWalkableAreas;
    FloodFill: TKMFillBiome;
begin
  SetLength(PathArr, Length(A), Length(A[0]));
  for Y := Low(PathArr) to High(PathArr) do
  for X := Low(PathArr[Y]) to High(PathArr[Y]) do
    PathArr[Y,X] := 0;

  FloodWalkSearch := TKMSearchWalkableAreas.Create( KMPoint(Low(A[0]), Low(A)), KMPoint(High(A[0]), High(A)), PathArr, A, True);
  FloodFill := TKMFillBiome.Create( KMPoint(Low(A[0]), Low(A)), KMPoint(High(A[0]), High(A)), PathArr, A, True);
  try
    for Y := 1 to gTerrain.MapY-1 do
    for X := 1 to gTerrain.MapX-1 do
      if (PathArr[Y,X] = 0) AND canWalk[ A[Y,X] ] then
      begin
        FloodWalkSearch.QuickFlood(X,Y,0,1, Count, PresentBiomes);
        lg2 := 1;
        if (PresentBiomes > 0) then
          lg2 := log2(PresentBiomes);
        if (Count < 50) AND (Frac(lg2) = 0) then // Simple check which will detect different biomes inside scaned area
          case Trunc(lg2)-1 of
            Byte(btGold),Byte(btEGold): FloodFill.QuickFlood(X,Y,1,2,  Byte(GoldMix[ fRNG.RandomI(Length(IronMix)) ]));
            Byte(btIron),Byte(btEIron): FloodFill.QuickFlood(X,Y,1,2,  Byte(IronMix[ fRNG.RandomI(Length(IronMix)) ]));
            else
              begin
              end;
          end;
      end;
  finally
    FloodWalkSearch.Free;
    FloodFill.Free;
  end;
end;


// Find NoGoZones and create NO_WALK object there; NoGoZones are zones which are inaccessible by walking from potential storehouse location
// Locs = locs of players positions
// TilesPartsArr = tiles composition array
procedure TKMRandomMapGenerator.NoGoZones(Locs: TKMPointArray; var TilesPartsArr: TTileParts);
const
  NO_WALK_TILE_OBJ = 61; // Number of no-walk object
  NO_OBJECT = 255; // Tile without object
var
  Y1,X1,Y0,Y2,X0,X2, i, step: Integer;
  PathArr: TInteger2Array;
  FillObject: TKMFillObject;
begin
  SetLength(PathArr, gTerrain.MapY, gTerrain.MapX);
  for Y1 := Low(PathArr) to High(PathArr) do
  	for X1 := High(PathArr[Y1]) to High(PathArr[Y1]) do
  		PathArr[Y1,X1] := 0;

  // Walk from Locs everywhere (if it is possible)
  FillObject := TKMFillObject.Create(KMPoint(1,1), KMPoint(gTerrain.MapX-1, gTerrain.MapY-1), PathArr, TilesPartsArr.Obj, TilesPartsArr.Terrain, False);
  try
    for i := Low(Locs) to High(Locs) do
    begin
      step := 0;
      X1 := Locs[I].X;
      Y1 := Locs[I].Y;
      while (step < 10) AND not WT[ TilesPartsArr.Terrain[Y1,X1] ] do
      begin
        X0 := Max(X1-step, 1);
        X2 := Min(X1+step, High(PathArr[0]));
        for Y2 := Max(Y1-step, 1) to Min(Y1+step, High(PathArr[0])) do
          if WT[ TilesPartsArr.Terrain[Y2,X0] ] then
          begin
            X1 := X0;
            Y1 := Y2;
            break;
          end
          else if WT[ TilesPartsArr.Terrain[Y2,X2] ] then
          begin
            X1 := X2;
            Y1 := Y2;
            break;
          end;
        if not WT[ TilesPartsArr.Terrain[Y1,X1] ] then
        begin
          Y0 := Max(Y1-step, 1);
          Y2 := Min(Y1+step, High(PathArr));
          for X2 := Max(X1-step, 1) to Min(X1+step, High(PathArr)) do
            if WT[ TilesPartsArr.Terrain[Y2,X0] ] then
            begin
              X1 := X2;
              Y1 := Y0;
              break;
            end
            else if WT[ TilesPartsArr.Terrain[Y2,X2] ] then
            begin
              X1 := X2;
              Y1 := Y2;
              break;
            end;
        end;
        step := step + 1;
      end;
      if WT[ TilesPartsArr.Terrain[Y1,X1] ] then
        FillObject.QuickFlood(X1, Y1, 0, 1, NO_OBJECT);
    end;

    // Now find accessible tiles which are not visited and replace object
    for Y1 := 1 to gTerrain.MapY-1 do
      for X1 := 1 to gTerrain.MapX-1 do
        if (PathArr[Y1,X1] = 0) AND WT[ TilesPartsArr.Terrain[Y1,X1] ] then
          FillObject.QuickFlood(X1, Y1, 0, 1, NO_WALK_TILE_OBJ);
  finally
    FillObject.Free;
  end;
end;



// Converts biomes into numbers which represents specific tiles with right direction and nice variance, it also make balanced resources
// Resources = array of balanced resources request
// TilesPartsArr = tiles composition array
// A = array of biomes
// B = array of biome-decomposition
procedure TKMRandomMapGenerator.GenerateTiles(var Resources: TBalancedResource1Array; var TilesPartsArr: TTileParts; var A: TKMByte2Array; var B: TKMByte2Array);
const
  TT: array[0..23,0..23,0..5] of Byte = ( // Textures of transitions + direction set
    ((1,1,1,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(58,57,56,1,1,1),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(74,73,72,1,1,1),			(0,0,0,0,0,0),			(95,94,93,1,1,1),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0)),
    ((18,19,8,1,1,1),			(1,1,1,0,0,0),			(18,19,8,1,1,1),			(18,19,8,1,1,1),			(18,19,8,1,1,1),			(18,19,8,1,1,1),			(18,19,8,1,1,1),			(18,19,8,1,1,1),			(18,19,8,1,1,1),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(18,19,8,1,1,1),			(18,19,8,1,1,1),			(0,0,0,0,0,0),			(18,19,8,1,1,1),			(0,0,0,0,0,0),			(18,19,8,1,1,1),			(18,19,8,1,1,1),			(18,19,8,1,1,1),			(18,19,8,1,1,1),			(18,19,8,1,1,1),			(0,0,0,0,0,0)),
    ((120,121,122,0,0,0),			(120,121,122,0,0,0),			(1,1,1,0,0,0),			(120,121,122,0,0,0),			(0,0,0,0,0,0),			(120,121,122,0,0,0),			(120,121,122,0,0,0),			(120,121,122,0,0,0),			(120,121,122,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(120,121,122,0,0,0),			(120,121,122,0,0,0),			(0,0,0,0,0,0),			(120,121,122,0,0,0),			(0,0,0,0,0,0),			(120,121,122,0,0,0),			(120,121,122,0,0,0),			(120,121,122,0,0,0),			(120,121,122,0,0,0),			(120,121,122,0,0,0),			(0,0,0,0,0,0)),
    ((90,91,92,0,0,0),			(90,91,92,0,0,0),			(90,91,92,0,0,0),			(1,1,1,0,0,0),			(90,91,92,0,0,0),			(90,91,92,0,0,0),			(90,91,92,0,0,0),			(90,91,92,0,0,0),			(90,91,92,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(90,91,92,0,0,0),			(90,91,92,0,0,0),			(0,0,0,0,0,0),			(90,91,92,0,0,0),			(0,0,0,0,0,0),			(90,91,92,0,0,0),			(90,91,92,0,0,0),			(90,91,92,0,0,0),			(90,91,92,0,0,0),			(90,91,92,0,0,0),			(0,0,0,0,0,0)),
    ((123,125,127,0,1,0),			(123,125,127,0,0,0),			(114,115,119,0,0,0),			(123,125,127,0,1,0),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(107,106,105,1,1,1),			(0,0,0,0,0,0),			(123,125,127,0,1,0),			(107,106,105,1,1,1),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(243,242,241,1,1,1),			(0,0,0,0,0,0),			(243,242,241,1,1,1),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0)),
    ((56,57,58,0,0,0),			(56,57,58,0,0,0),			(56,57,58,0,0,0),			(56,57,58,0,0,0),			(105,106,107,0,0,0),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(87,88,89,0,0,0),			(0,0,0,0,0,0),			(65,64,247,1,1,1),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(56,57,58,0,0,0),			(56,57,58,0,0,0),			(56,57,58,0,0,0),			(0,0,0,0,0,0),			(56,57,58,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0)),
    ((84,85,86,0,0,0),			(84,85,86,0,0,0),			(84,85,86,0,0,0),			(84,85,86,0,0,0),			(89,88,87,1,1,1),			(89,88,87,1,1,1),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(89,88,87,1,1,1),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(84,85,86,0,0,0),			(84,85,86,0,0,0),			(0,0,0,0,0,0),			(84,85,86,0,0,0),			(0,0,0,0,0,0),			(84,85,86,0,0,0),			(89,88,87,1,1,1),			(89,88,87,1,1,1),			(89,88,87,1,1,1),			(89,88,87,1,1,1),			(0,0,0,0,0,0)),
    ((56,57,58,0,0,0),			(56,57,58,0,0,0),			(56,57,58,0,0,0),			(56,57,58,0,0,0),			(105,106,107,0,0,0),			(35,36,37,1,1,1),			(87,88,89,0,0,0),			(1,1,1,0,0,0),			(87,88,89,0,0,0),			(0,0,0,0,0,0),			(65,64,247,1,1,1),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(56,57,58,0,0,0),			(56,57,58,0,0,0),			(56,57,58,0,0,0),			(0,0,0,0,0,0),			(56,57,58,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0)),
    ((66,67,68,0,0,0),			(66,67,68,0,0,0),			(66,67,68,0,0,0),			(66,67,68,0,0,0),			(66,67,68,0,0,0),			(96,97,98,0,0,0),			(96,97,98,0,0,0),			(96,97,98,0,0,0),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(66,67,68,0,0,0),			(66,67,68,0,0,0),			(0,0,0,0,0,0),			(66,67,68,0,0,0),			(0,0,0,0,0,0),			(66,67,68,0,0,0),			(66,67,68,0,0,0),			(66,67,68,0,0,0),			(66,67,68,0,0,0),			(66,67,68,0,0,0),			(0,0,0,0,0,0)),
    ((247,64,65,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(247,64,65,0,1,0),			(247,64,65,0,0,0),			(247,64,65,0,0,0),			(247,64,65,0,0,0),			(0,0,0,0,0,0),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(213,212,220,1,1,1),			(0,0,0,0,0,0),			(247,64,65,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(247,64,65,0,0,0),			(247,64,65,0,0,0),			(0,0,0,0,0,0)),
    ((0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(220,212,213,0,0,0),			(0,0,0,0,0,0),			(220,212,213,0,0,0),			(0,0,0,0,0,0),			(220,212,213,0,0,0),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(220,212,213,0,0,0),			(220,212,213,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0)),
    ((0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(203,204,205,0,0,0),			(203,204,205,0,0,0),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0)),
    ((0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(23,12,22,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(44,4,10,0,0,0),			(0,0,0,0,0,0),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0)),
    ((69,70,71,0,0,0),			(69,70,71,0,0,0),			(69,70,71,0,0,0),			(69,70,71,0,0,0),			(118,117,116,1,0,1),			(111,112,113,0,0,0),			(69,70,71,0,0,0),			(111,112,113,0,0,0),			(69,70,71,0,0,0),			(111,112,113,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(1,1,1,0,0,0),			(104,103,102,1,1,1),			(0,0,0,0,0,0),			(104,103,102,1,1,1),			(0,0,0,0,0,0),			(69,70,71,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0)),
    ((72,73,74,0,0,0),			(72,73,74,0,0,0),			(72,73,74,0,0,0),			(72,73,74,0,0,0),			(75,76,77,1,1,1),			(72,73,74,0,0,0),			(72,73,74,0,0,0),			(72,73,74,0,0,0),			(72,73,74,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(77,76,75,1,1,1),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(77,76,75,1,1,1),			(77,76,75,1,1,1),			(72,73,74,0,0,0),			(77,76,75,1,1,1),			(77,76,75,1,1,1),			(77,76,75,1,1,1),			(77,76,75,1,1,1),			(0,0,0,0,0,0)),
    ((75,76,77,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(241,242,243,0,0,0),			(75,76,77,0,0,0),			(0,0,0,0,0,0),			(75,76,77,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(102,103,104,0,0,0),			(75,76,77,0,0,0),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(75,76,77,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0)),
    ((93,94,95,0,0,0),			(93,94,95,0,0,0),			(93,94,95,0,0,0),			(93,94,95,0,0,0),			(78,79,80,0,0,0),			(93,94,95,0,0,0),			(93,94,95,0,0,0),			(93,94,95,0,0,0),			(93,94,95,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(78,79,80,0,0,0),			(78,79,80,0,0,0),			(78,79,80,0,0,0),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(93,94,95,0,0,0),			(78,79,80,0,0,0),			(78,79,80,0,0,0),			(78,79,80,0,0,0),			(78,79,80,0,0,0),			(0,0,0,0,0,0)),
    ((93,94,95,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(99,100,101,0,0,0),			(81,82,83,0,0,0),			(81,82,83,0,0,0),			(81,82,83,0,0,0),			(1,1,1,0,0,0),			(93,94,95,0,0,0),			(78,79,80,0,0,0),			(78,79,80,0,0,0),			(78,79,80,0,0,0),			(78,79,80,0,0,0),			(0,0,0,0,0,0)),
    ((0,139,138,0,0,0),			(0,139,138,0,0,0),			(0,139,138,0,0,0),			(0,139,138,0,0,0),			(236,200,143,0,0,0),			(0,139,138,0,0,0),			(0,139,138,0,0,0),			(0,139,138,0,0,0),			(0,139,138,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,139,138,0,0,0),			(0,139,138,0,0,0),			(0,139,138,0,0,0),			(0,139,138,0,0,0),			(0,139,138,0,0,0),			(1,1,1,0,0,0),			(0,139,138,0,0,0),			(0,139,138,0,0,0),			(0,139,138,0,0,0),			(0,139,138,0,0,0),			(0,0,0,0,0,0)),
    ((180,172,176,0,0,0),			(180,172,176,0,0,0),			(180,172,176,0,0,0),			(180,172,176,0,0,0),			(236,200,237,0,0,0),			(183,175,179,0,0,0),			(183,175,179,0,0,0),			(183,175,179,0,0,0),			(180,172,176,0,0,0),			(49,171,51,0,0,0),			(49,171,51,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(181,173,177,0,0,0),			(182,174,178,0,0,0),			(182,174,178,0,0,0),			(182,174,178,0,0,0),			(182,174,178,0,0,0),			(180,172,176,0,0,0),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0)),
    ((180,172,176,0,0,0),			(180,172,176,0,0,0),			(180,172,176,0,0,0),			(180,172,176,0,0,0),			(236,200,237,0,0,0),			(183,175,179,0,0,0),			(183,175,179,0,0,0),			(183,175,179,0,0,0),			(180,172,176,0,0,0),			(49,171,51,0,0,0),			(49,171,51,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(181,173,177,0,0,0),			(182,174,178,0,0,0),			(182,174,178,0,0,0),			(182,174,178,0,0,0),			(182,174,178,0,0,0),			(180,172,176,0,0,0),			(144,145,145,0,0,0),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0)),
    ((188,168,184,0,0,0),			(188,168,184,0,0,0),			(188,168,184,0,0,0),			(188,168,184,0,0,0),			(236,200,239,0,0,0),			(191,167,187,0,0,0),			(191,167,187,0,0,0),			(191,167,187,0,0,0),			(188,168,184,0,0,0),			(191,167,187,0,0,0),			(52,166,54,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(189,169,185,0,0,0),			(190,170,186,0,0,0),			(190,170,186,0,0,0),			(190,170,186,0,0,0),			(190,170,186,0,0,0),			(188,168,184,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0)),
    ((188,168,184,0,0,0),			(188,168,184,0,0,0),			(188,168,184,0,0,0),			(188,168,184,0,0,0),			(236,200,239,0,0,0),			(191,167,187,0,0,0),			(191,167,187,0,0,0),			(191,167,187,0,0,0),			(188,168,184,0,0,0),			(191,167,187,0,0,0),			(52,166,54,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(189,169,185,0,0,0),			(190,170,186,0,0,0),			(190,170,186,0,0,0),			(190,170,186,0,0,0),			(190,170,186,0,0,0),			(188,168,184,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(148,149,149,0,0,0),			(1,1,1,0,0,0),			(0,0,0,0,0,0)),
    ((0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(53,50,165,1,1,1),			(53,50,165,1,1,1),			(1,1,1,0,0,0))
  );
  DF: array[0..1,0..3] of Byte = ( // Direction fixer (sometimes are tiles inverted so this will fix it)
    (0,1,2,3),(2,3,0,1)
  );
  FT: array[0..23,0..9] of Byte = ( // Full textures + variance
    (0,1,2,3,5,6,13,14,0,0),
    (8,9,11,0,0,0,0,0,0,0),
    (48,0,0,0,0,0,0,0,0,0),
    (40,41,42,43,0,0,0,0,0,0),
    (192,193,196,0,0,0,0,0,0,0),
    (155,154,153,152,7,0,0,0,0,0),
    (34,0,0,0,0,0,0,0,0,0),
    (35,36,37,0,0,0,0,0,0,0),
    (17,16,0,0,0,0,0,0,0,0),
    (47,0,0,0,0,0,0,0,0,0),
    (46,0,0,0,0,0,0,0,0,0),
    (45,0,0,0,0,0,0,0,0,0),
    (44,0,0,0,0,0,0,0,0,0),
    (31,32,33,0,0,0,0,0,0,0),
    (26,0,0,0,0,0,0,0,0,0),
    (27,0,0,0,0,0,0,0,0,0),
    (28,0,0,0,0,0,0,0,0,0),
    (29,30,0,0,0,0,0,0,0,0),
    (132,131,130,129,18,128,136,135,134,133),
    (147,146,145,144,20,0,0,0,0,0),
    (156,157,158,159,201,0,0,0,0,0),
    (151,150,149,148,22,0,0,0,0,0),
    (160,161,162,163,164,0,0,0,0,0),
    (245,0,0,0,0,0,0,0,0,0)
  );
  PT: array[0..23,0..9] of Single = ( // Probability of the specific full texture
    (0.667,0.834,0.89,0.913,0.947,0.981,0.993,1,1,1),
    (0.385,0.77,1,1,1,1,1,1,1,1),
    (1,1,1,1,1,1,1,1,1,1),
    (0.295,0.59,0.885,1,1,1,1,1,1,1),
    (0.455,0.91,1,1,1,1,1,1,1,1),
    (0.02,0.119,0.414,1,1,1,1,1,1,1),
    (1,1,1,1,1,1,1,1,1,1),
    (0.556,0.834,1,1,1,1,1,1,1,1),
    (0.715,1,1,1,1,1,1,1,1,1),
    (1,1,1,1,1,1,1,1,1,1),
    (1,1,1,1,1,1,1,1,1,1),
    (1,1,1,1,1,1,1,1,1,1),
    (1,1,1,1,1,1,1,1,1,1),
    (0.125,0.75,1,1,1,1,1,1,1,1),
    (1,1,1,1,1,1,1,1,1,1),
    (1,1,1,1,1,1,1,1,1,1),
    (1,1,1,1,1,1,1,1,1,1),
    (0.75,1,1,1,1,1,1,1,1,1),
    (0.,0.,0.,0.,0.,1,1,1,1,1),
    (0.,0.,0.223,1,1,1,1,1,1,1),
    (0.2,0.4,0.6,0.8,1,1,1,1,1,1),
    (0.,0.,0.223,1,1,1,1,1,1,1),
    (0.2,0.4,0.6,0.8,1,1,1,1,1,1),
    (1,1,1,1,1,1,1,1,1,1)
  );

  // Return full texture of specific biome (with variance)
  function GetFullTexture(Biome: Byte): Byte;
  var
    rnd: Single;
    i: Integer;
  begin
    Result := 0;
    rnd := fRNG.Random();
    for i := Low( PT[Biome] ) to High( PT[Biome] ) do
      if (rnd < PT[Biome,i]) then
      begin
        Result := FT[Biome,i];
        break;
      end;
  end;

  {
  // Old function for coal texture generation
  function GetCoalTexture(Y,X: Integer): Byte;
  var
    X1,Y1,count: Integer;
  begin
    Result := 0;
    count := 0;
    for Y1 := Max(1,Y-2) to Min(gTerrain.MapY-1,Y+2) do
      for X1 := Max(1,X-2) to Min(gTerrain.MapY-1,X+2) do
        if (A[Y1,X1] <> A[Y,X]) then
          count := count + 1;
    case count of
      0:      Result := 155;
      1,2:    Result := 154;
      3,4,5:  Result := 153;
      else    Result := 152;
    end;
  end;
  }

  // Finds right transition texture by specific rules
  procedure TransitionTexture(var T1, T2, Terrain, Rotation: Byte; const T1dir, T2dir, T1E, T2E, T1ER, T2ER: Byte);
  begin
    if (T1 < T2) then
    begin
      Terrain := TT[ T2 , T1 , T1E ];
      Rotation := DF[ TT[ T2 , T1 , T1ER ] , T1dir ];
    end
    else
    begin
      Terrain := TT[ T1 , T2 , T2E ];
      Rotation := DF[ TT[ T1 , T2 , T2ER ] , T2dir ];
    end;
  end;

  // Split a shape of the future mine into segments with different density of resource (less coal in edges and more in center tiles)
  function CalculateCountOfResources(const Resource: Byte; const Quantity: Integer; var count: array of Integer): TInteger2Array;
  var
    i,j,cntRes,difference, incJ, incPerATile: Integer;
    Output: TInteger2Array;
  begin
    SetLength(Output, 4, 5); // 4 types of resources, 5 quantity types (none, 1, 2, 3, 4)

    // Coal / Gold / Iron = 4 resources on a tile, Stone = 15
    incPerATile := 1 + (Byte(Resource = Byte(btStone)) shl 1); // 3 for Stone, 1 else

    // Fill with maximal possible quantity for each tile
    cntRes := 0;
    for i := Low(Output) to High(Output) do
    begin
      j := High(Output[I]);
      Output[i,j] := count[I];
      cntRes := cntRes + count[I];
    end;
    cntRes := cntRes * (j * incPerATile + 3*Byte(Resource = Byte(btStone))); // Maximal capacity of shape

    // Decrease maximal resource capacity of shape by move specific tiles into lower levels of Output array
    incJ := High(Output[0]);
    while (cntRes > Quantity) AND (incJ >= -5) do // incJ anti overflow condition
    begin
      i := 0;
      j := incJ;
      while (cntRes > Quantity) AND (i <= High(Output)) AND (j <= High(Output[I])) do
      begin
        if (j >= 1) then
        begin
          difference := Min( Round((cntRes-Quantity)/incPerATile + 0.5), Output[i,j] );
          Output[i,j] := Output[i,j] - difference;
          Output[i,j-1] := difference;
          cntRes := cntRes - difference*incPerATile;
        end;
        i := i + 1;
        j := j + 1;
      end;
      incJ := incJ - 1;
    end;
    Result := Output;
  end;

var
   X1,X2,Y1,Y2,sum,I,K,L, MaxLen: Integer;
   Terrain, Rotation: Byte;
   S,S2: TInteger2Array;
   BalanceResArr: TInteger2Array;
   TileFloodSearch: TKMTileFloodSearch;
   PointArr: TKMPointArray;
   LevelArr: TKMByteArray;
begin

  // Initialization
    SetLength(S, Length(A), Length(A[Low(A)]));
    SetLength(S2, Length(A), Length(A[Low(A)]));
    for Y1 := Low(S) to High(S) do
      for X1 := Low(S[Y1]) to High(S[Y1]) do
      begin
        S[Y1,X1] := 1;
        S2[Y1,X1] := 0;
      end;

// Shortcuts:
//    _______                 ___________________
//   | 1   2 |  is equal to  | [Y1,X1]   [Y1,X2] |
//   | 3   4 |               | [Y2,X1]   [Y2,X2] |
//    ———————                 ———————————————————
// Transitions:
//    ______________     ____________     _______________
//   | 1 › Top  ‹ 2 |   | 1 › $2 ‹ 2 |   | 1 › %0010 ‹ 2 |
//   | ˇ          ˇ |   | ˇ        ˇ |   | ˇ           ˇ |
//   | Left   Right |   | $1      $4 |   | %0001   %0100 |
//   | ^          ^ |   | ^        ^ |   | ^           ^ |
//   | 3 › Down ‹ 4 |   | 3 › $8 ‹ 4 |   | 3 › %1000 ‹ 4 |
//    ——————————————     ————————————     ———————————————

// Generate tiles of basic textures (everything except resources)
  Y1 := 2;
  while Y1 < (gTerrain.MapY shl 1) do
  begin
    Y2 := Y1 + 1;
    X1 := 2;
    while X1 < (gTerrain.MapX shl 1) do
    begin
      X2 := X1 + 1;
      sum := (Byte(B[Y1,X1] <> B[Y2,X1]) shl 0) OR // Left
			       (Byte(B[Y1,X1] <> B[Y1,X2]) shl 1) OR // Top
			       (Byte(B[Y1,X2] <> B[Y2,X2]) shl 2) OR // Right
			       (Byte(B[Y2,X1] <> B[Y2,X2]) shl 3);   // Down

      case sum of
      // Full texture
        $0: begin
            // Resources
              if (B[Y1,X1] = Byte(btStone)) OR (B[Y1,X1] = Byte(btGold)) OR (B[Y1,X1] = Byte(btIron)) OR (B[Y1,X1] = Byte(btCoal)) then
              begin
                S[Y1 shr 1,X1 shr 1] := B[Y1,X1];
                Terrain := GetFullTexture(FT[ B[Y1,X1] ,4]); // Place empty resources there and replace them with full variants later
              end
            // Other textures
              else
                Terrain := GetFullTexture(B[Y1,X1]);
              Rotation := fRNG.RandomI(3);
            end;
      // Transitions (line)
        $A: TransitionTexture(B[Y1,X1], B[Y1,X2], Terrain, Rotation, 1, 3, 1, 1, 4, 4);// Vertical transition
        $5: TransitionTexture(B[Y1,X1], B[Y2,X1], Terrain, Rotation, 2, 0, 1, 1, 4, 4);// Horizontal transition
      // Transitions (big edge for dominant texture and vice versa)
        $3: TransitionTexture(B[Y1,X1], B[Y2,X1], Terrain, Rotation, 1, 3, 2, 0, 5, 3);
        $6: TransitionTexture(B[Y1,X1], B[Y1,X2], Terrain, Rotation, 0, 2, 0, 2, 3, 5);
        $C: TransitionTexture(B[Y1,X1], B[Y2,X2], Terrain, Rotation, 1, 3, 0, 2, 3, 5);
        $9: TransitionTexture(B[Y1,X1], B[Y2,X1], Terrain, Rotation, 2, 0, 0, 2, 3, 5);
        else
        begin
          // 3-4 biom transitions will never happen (TileTemplate will fix it)
        end;
      end;
      TilesPartsArr.Terrain[Y1 shr 1,X1 shr 1] := Terrain;
      TilesPartsArr.Rotation[Y1 shr 1,X1 shr 1] := Rotation;
      X1 := X1 + 2;
    end;
    Y1 := Y1 + 2;
  end;

// Generate balanced resources
  TileFloodSearch := TKMTileFloodSearch.Create(KMPoint(1,1), KMPoint(gTerrain.MapX-1,gTerrain.MapY-1), S, S2);
  try
    // Detect all shapes (merge / split existing shapes if they are / are not connected because could CA changed it)
    for I := Low(Resources) to High(Resources) do
    begin
      Resources[I].TileCounter := TIntegerArray.Create(0,0,0,0);
      K := Low(Resources[I].Points);
      // Calculate the count of tiles which can be changed to specific resource (it is represented by multiple points from Voronoi which represent multiple shapes)
      MaxLen := Length(Resources[I].Points);
      while K < MaxLen do
      begin
        X1 := Resources[I].Points[K].X;
        Y1 := Resources[I].Points[K].Y;
        // Sometimes are points in edge of 2 transition textures (or are moved by CA) -> scan 1 tile around
        sum := (Byte(  S[Y1,X1] = Resources[I].Resource  )) OR
               (Byte(  (Y1+1 < gTerrain.MapY) AND (S[Y1+1,X1] = Resources[I].Resource)  ) shl 1) OR
               (Byte(  (X1+1 < gTerrain.MapX) AND (S[Y1,X1+1] = Resources[I].Resource)  ) shl 2) OR
               (Byte(  (Y1-1 > 0)             AND (S[Y1-1,X1] = Resources[I].Resource)  ) shl 3) OR
               (Byte(  (X1-1 > 0)             AND (S[Y1,X1-1] = Resources[I].Resource)  ) shl 4);
        // We have right tile in a neighborhood
        if (sum > 0) then
        begin
          // Get point with right tile
          if      (sum >= $10) then X1 := X1 - 1
          else if (sum >= $8)  then Y1 := Y1 - 1
          else if (sum >= $4)  then X1 := X1 + 1
          else if (sum >= $2)  then Y1 := Y1 + 1;
          // Scan shape of resource and save count of tiles in shape
          TileFloodSearch.QuickFlood(X1, Y1, Resources[I].Resource, -I, Resources[I].TileCounter);
          Resources[I].Points[K].X := X1;
          Resources[I].Points[K].Y := Y1;
          K := K + 1;
          continue;
        end
        // Already scanned tile from different shape (make 1 big shape with sum of all needed resources)
        // (for example coal tiles created as a part of gold tiles and coal tiles created as a part of iron tiles can be sometimes merged together but GenerateResources doesn't see it because CA can change it)
        else if (S[Y1,X1] < 0) AND (S[Y1,X1] <> -i) AND (Resources[-S[Y1,X1]].Resource = Resources[I].Resource) then
        begin
          sum := Round(Resources[I].Quantity / MaxLen);
          Resources[-S[Y1,X1]].Quantity := Resources[-S[Y1,X1]].Quantity + sum;
          Resources[I].Quantity := Resources[I].Quantity - sum;
        end;
        // Remove useless point from array
        Dec(MaxLen,1);
        Resources[I].Points[K] := Resources[I].Points[ MaxLen ];
      end;
      SetLength( Resources[I].Points, MaxLen );
    end;

    for I := Low(Resources) to High(Resources) do
      // Fill textures with positive quantity (zero quantity = merged shapes)
      if (Resources[I].Quantity > 0) then
      begin
        // Split a request of the future mine (count of resources) into segments sorted by tiles with different density of resource (less coal in edges and more in center tiles)
        BalanceResArr := CalculateCountOfResources(Resources[I].Resource, Resources[I].Quantity, Resources[I].TileCounter);
        sum := 0;
        for K := Low(Resources[I].TileCounter) to High(Resources[I].TileCounter) do
          sum := sum + Resources[I].TileCounter[K];
        SetLength(PointArr, sum);
        SetLength(LevelArr, sum);
        // Scan all shapes
        for K := Low(Resources[I].Points) to High(Resources[I].Points) do
        begin
          X1 := Resources[I].Points[K].X;
          Y1 := Resources[I].Points[K].Y;
          TileFloodSearch.QuickFlood(X1, Y1, S[Y1,X1], 1, sum, BalanceResArr, PointArr, LevelArr);
          for L := Low(PointArr) to sum do
          begin
            LevelArr[L] := 4 - LevelArr[L];
            if (LevelArr[L] <> 4) then
              TilesPartsArr.Terrain[PointArr[L].Y,PointArr[L].X] := FT[Resources[I].Resource,LevelArr[L]]
            else
              TilesPartsArr.Terrain[PointArr[L].Y,PointArr[L].X] := GetFullTexture(FT[Resources[I].Resource,LevelArr[L]]);
          end;
        end;
      end;
  finally
    TileFloodSearch.Free;
  end;
end;



// Debug function (only full textures without transitions)
// TilesPartsArr = tiles composition array
// A = array of biomes
procedure TKMRandomMapGenerator.GenerateBasicTiles(var TilesPartsArr: TTileParts; var A: TKMByte2Array);
var
   X,Y: Integer;
const
  FT: array[0..23] of Byte = (0,8,48,40,192,155,34,35,17,47,46,45,44,31,26,27,28,29,132,147,156,151,160,245);
begin
	for Y := 1 to gTerrain.MapY-1 do
		for X := 1 to gTerrain.MapX-1 do
    begin
      TilesPartsArr.Terrain[Y,X] := FT[ A[Y,X] ];
      TilesPartsArr.Rotation[Y,X] := 0;
		end;
end;



// Height generator
// TilesPartsArr = tiles composition array
// A = array of biomes
// TileTempl = array of biome-decomposition
procedure TKMRandomMapGenerator.GenerateHeight(var TilesPartsArr: TTileParts; var A: TKMByte2Array; var TileTempl: TKMByte2Array);
var
  X_0,Y_0,X_1,Y_1,X_2,Y_2,X0,X1,X2,Y0,Y1,Y2,sum: Integer;
  H1,H2: TInteger2Array;
const
  HeightMix: array [0..23] of Byte = (
    //20,18,15,15,15,21,19,22,23,24,25,20,20,19,18,17,18,21,20,20,20,20,20,20
    10,10,5,5,3,5,10,1,10,10,20,20,0,5,10,10,15,20,10,20,20,20,20,0
  );
  //TBiomeType = (
  //10,15,0,0,0,10,5,0,15,15,20,20,10,5,btGrassSand1,btGrassSand2,btGrassSand3,btSand,btStone,btGold,btEgold,btIron,btEIron,btDark);

  HeightVariance: array [0..23] of Byte = (
    10,10,5,5,3,5,10,10,10,10,20,20,0,5,10,10,15,20,10,20,20,0,0,0
  );
  HNST: array[0..23,0..23] of Byte = ( // Hide Non-Smooth Transition (height fix)
    (0,0,0,2,3,5,2,5,1,5,5,5,5,3,1,4,3,4,0,0,0,0,0,0),
    (0,0,0,2,3,5,2,5,1,5,5,5,5,3,1,4,3,4,0,0,0,0,0,0),
    (0,0,0,2,0,5,2,3,2,5,5,5,5,2,1,2,3,4,0,0,0,0,0,0),
    (2,2,2,0,3,5,0,1,2,5,5,5,5,3,3,3,4,5,0,0,0,0,0,0),
    (3,3,0,3,0,5,3,3,3,3,5,5,5,3,3,3,3,3,0,0,0,0,0,0),
    (5,5,5,5,5,0,2,0,0,5,5,5,5,4,4,4,4,4,0,0,0,0,0,0),
    (2,2,2,0,3,2,0,0,0,5,5,5,5,5,5,5,5,3,0,0,0,0,0,0),
    (5,5,3,1,3,0,0,0,5,5,5,5,5,4,4,4,4,3,0,0,0,0,0,0),
    (1,1,2,2,3,0,0,5,0,5,5,5,5,5,5,5,5,5,0,0,0,0,0,0),
    (5,5,5,5,3,5,5,5,5,0,5,5,5,5,5,5,5,5,0,0,0,0,0,0),
    (5,5,5,5,5,5,5,5,5,5,0,5,5,5,5,5,5,5,0,0,0,0,0,0),
    (5,5,5,5,5,5,5,5,5,5,5,0,5,5,5,5,5,5,0,0,0,0,0,0),
    (5,5,5,5,5,5,5,5,5,5,5,5,0,3,3,3,3,3,0,0,0,0,0,0),
    (3,3,2,3,3,4,5,4,5,5,5,5,3,0,0,0,0,0,0,0,0,0,0,0),
    (1,1,1,3,3,4,5,4,5,5,5,5,3,0,0,0,0,0,0,0,0,0,0,0),
    (4,4,2,3,3,4,5,4,5,5,5,5,3,0,0,0,0,0,0,0,0,0,0,0),
    (3,3,3,4,3,4,5,4,5,5,5,5,3,0,0,0,0,0,0,0,0,0,0,0),
    (4,4,4,5,3,4,3,3,5,5,5,5,3,0,0,0,0,0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,100,100,0),
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,100,100,0),
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,100,100,0,0,0),
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,100,100,0,0,0),
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
  );
begin

  H1 := LinearInterpolation(7,20);
  H2 := LinearInterpolation(5,60);
	for Y1 := 1 to gTerrain.MapY-1 do
    for X1 := 1 to gTerrain.MapX-1 do
    begin
      TilesPartsArr.Height[Y1,X1] := H1[Y1,X1] + H2[Y1,X1] + fRNG.RandomI(HeightVariance[ A[Y1,X1] ]);
      //TilesPartsArr.Height[Y,X] := HeightMix[ A[Y1,X1] ] + H2[Y1,X1] + TGRandomI(HeightVariance[ A[Y1,X1] ]);
    end;

  for Y_1 := 1 to gTerrain.MapY-1 do
  begin
    Y2 := Y_1 shl 1;
    Y1 := Y2 - 1;
    Y_0 := Max(0, Y_1 - 2);
    Y_2 := Min(gTerrain.MapY, Y_1 + 1);
    for X_1 := 1 to gTerrain.MapX-1 do
    begin
      X2 := X_1 shl 1;
      X1 := X2 - 1;
      X_0 := Max(0, X_1 - 2);
      X_2 := Min(gTerrain.MapX, X_1 + 1);

      // Mountains
      if (A[Y_1,X_1] >= Byte(btStone)) then
      begin
        if A[Y_1,X_1] = Byte(btStone) then
          sum := + Byte(A[Y_0,X_0] = A[Y_1,X_1])
                 + Byte(A[Y_0,X_1] = A[Y_1,X_1])
                 + Byte(A[Y_0,X_2] = A[Y_1,X_1])
                 + Byte(A[Y_1,X_2] = A[Y_1,X_1])
                 + Byte(A[Y_1,X_0] = A[Y_1,X_1])
                 + Byte(A[Y_2,X_0] = A[Y_1,X_1])
                 + Byte(A[Y_2,X_1] = A[Y_1,X_1])
                 + Byte(A[Y_2,X_2] = A[Y_1,X_1])
        else
          sum := + Byte(A[Y_0,X_0] >= A[Y_1,X_1])
                 + Byte(A[Y_0,X_1] >= A[Y_1,X_1])
                 + Byte(A[Y_0,X_2] >= A[Y_1,X_1])
                 + Byte(A[Y_1,X_2] >= A[Y_1,X_1])
                 + Byte(A[Y_1,X_0] >= A[Y_1,X_1])
                 + Byte(A[Y_2,X_0] >= A[Y_1,X_1])
                 + Byte(A[Y_2,X_1] >= A[Y_1,X_1])
                 + Byte(A[Y_2,X_2] >= A[Y_1,X_1]);
        if (sum = 8) then
          TilesPartsArr.Height[Y_1,X_1] := fRNG.RandomI(70)+30;
      end;
      //else if (TilesPartsArr.Obj[Y_1,X_1] = 61) AND (  (A[Y_1,X_1] = Byte(btGroundSnow)) OR (A[Y_1,X_1] = Byte(btSnow1)) OR (A[Y_1,X_1] = Byte(btSnow2))  ) then
        //TilesPartsArr.Height[Y_1,X_1] := fRNG.RandomI(30)+60;

    // Set lower height to non-smooth transitions (hide it)
      if RMGSettings.Height.HideNonSmoothTransition then
      begin
        sum := + HNST[ TileTempl[Y1,X1] ][ TileTempl[Y2,X1] ]
               + HNST[ TileTempl[Y1,X1] ][ TileTempl[Y1,X2] ]
               + HNST[ TileTempl[Y1,X2] ][ TileTempl[Y2,X2] ]
               + HNST[ TileTempl[Y2,X1] ][ TileTempl[Y2,X2] ];
        if (sum > 0) then
          TilesPartsArr.Height[Y_1,X_1] := Max(0, H1[Y_1,X_1] + H2[Y_1,X_1] - sum);
      end;
    // Change height of water
    {
      if (A[Y_1,X_1] = Byte(btWater)) then
      begin
        sum :=   Byte(A[Y_2,X_1] = Byte(btWater))
               + Byte(A[Y_0,X_1] = Byte(btWater))
               + Byte(A[Y_1,X_2] = Byte(btWater))
               + Byte(A[Y_1,X_0] = Byte(btWater))
               + Byte(A[Y_2,X_2] = Byte(btWater))
               + Byte(A[Y_2,X_0] = Byte(btWater))
               + Byte(A[Y_0,X_2] = Byte(btWater))
               + Byte(A[Y_0,X_0] = Byte(btWater));
        TilesPartsArr.Height[Y_1,X_1] := Max(0,TilesPartsArr.Height[Y_1,X_1] - (sum * 2));
      end;
      }

    end;
  end;
end;



// Objects generator
// TilesPartsArr = tiles composition array
// A = array of biomes
procedure TKMRandomMapGenerator.GenerateObjects(var TilesPartsArr: TTileParts; var A: TKMByte2Array);
const
  WOLVES = 10;
  FOREST_RADIUS = 15; // maximal radius of forest
  O: record
    Objects: array [TObjects] of array[0..20] of Byte;
    Probability: array [TObjects] of array[0..20] of Single;
  end = (
    Objects: ( // Array of avaiable objects in corelation with specific type of objects (stones, grass, conifers etc)
      (0,1,2,3,4,68,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0),
      (5,6,210,211,214,212,213,215,7,0,0,0,0,0,0,0,0,0,0,0,0),
      (10,11,12,13,14,15,16,38,42,43,46,0,0,0,0,0,0,0,0,0,0),
      (17,18,19,21,251,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
      (22,23,24,249,250,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
      (58,59,60,62,63,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
      (68,69,70,71,72,73,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
      (190,191,192,193,195,196,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
      (88,89,90,92,93,94,95,97,98,99,100,102,103,104,105,107,108,109,110,0,0),
      (149,150,151,153,154,155,157,158,159,160,162,163,164,165,167,168,169,170,172,0,0),
      (113,114,116,117,118,119,121,122,123,124,112,0,0,0,0,0,0,0,0,0,0),
      (216,217,218,219,220,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
      (200,201,202,203,204,205,206,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
      (31,32,33,34,35,36,37,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
    );
    Probability: ( // Probability of specific object
      (0.17,0.34,0.51,0.68,0.85,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1),
      (0.19,0.38,0.57,0.76,0.95,0.97,0.99,1,1,1,1,1,1,1,1,1,1,1,1,1,1),
      (0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1,1,1,1,1,1,1,1,1,1,1,1),
      (0.25,0.5,0.75,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1),
      (0.34,0.68,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1),
      (0.04,0.08,0.44,0.8,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1),
      (0.2,0.4,0.6,0.8,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1),
      (0.17,0.34,0.51,0.68,0.85,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1),
      (0.06,0.12,0.18,0.24,0.3,0.36,0.42,0.48,0.54,0.6,0.66,0.72,0.78,0.84,0.9,0.96,1,1,1,1,1),
      (0.06,0.12,0.18,0.24,0.3,0.36,0.42,0.48,0.54,0.6,0.66,0.72,0.78,0.84,0.9,0.96,1,1,1,1,1),
      (0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1,1,1,1,1,1,1,1,1,1,1,1),
      (0.25,0.5,0.75,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1),
      (0.15,0.3,0.45,0.6,0.75,0.9,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1),
      (0.29,0.32,0.38,0.53,0.82,0.88,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1)
    );
  );
  ObjectMix: array [TObjectMix] of array[TObjects] of Single = ( // Probability of mix for specific biome (for example the swamp have big probability of a reed but zero for a stone)
    (0.2,0.4,0.6,0.7,0.9,1,1,1,1,1,1,1,1,1),
    (0,0,0.31,0.31,0.31,0.7,0.82,1,1,1,1,1,1,1),
    (0.27,0.27,0.43,0.7,0.7,0.7,0.81,1,1,1,1,1,1,1),
    (1,1,1,1,1,1,1,1,1,1,1,1,1,1),
    (0.22,0.22,0.54,0.54,0.54,0.54,0.7,1,1,1,1,1,1,1),
    (0.28,0.5,0.5,0.5,0.78,0.78,0.78,0.89,0.89,0.89,0.89,1,1,1),
    (0,0,0,0,0,0,0,0,0,0,0,0,0,1),
    (0.3,0.3,0.3,0.3,0.5,1,1,1,1,1,1,1,1,1)
  );

  // Return number which represent specific (include variation)
  function GetObject(const obj: TObjects): Byte;
  var
    rnd: Single;
    i, Output: Byte;
  begin
    Output := 255;
    rnd := fRNG.Random();
    for i := Low( O.Probability[obj] ) to High( O.Probability[obj] ) do
      if rnd < O.Probability[obj,i] then begin
        Output := O.Objects[obj,i];
        break;
      end;
    Result := Output;
  end;

  // Return number which represent specific object
  function GetObjectFromMix(const ObjMixType: TObjectMix): Byte;
  var
    rnd: Single;
    i: TObjects;
    Output: Byte;
  begin
    Output := 255; // no object
    rnd := fRNG.Random();
    for i := Low(TObjects) to High(TObjects) do
      if rnd < ObjectMix[ ObjMixType , i ] then
      begin
        Output := GetObject(i);
        break;
      end;
    Result := Output;
  end;

var
   X,Y,num,count,cntForests, overflow, OBJ_DENSITY: Integer;
   Minimum, Maximum: TKMPoint;
   forests: TKMPointArray;
begin

	// Forests
  if (RMGSettings.Objects.Forests > 0) then
  begin
    Minimum := KMPoint(1,1);
    Maximum.X := Max(gTerrain.MapX - FOREST_RADIUS, Minimum.X + 1);
    Maximum.Y := Max(gTerrain.MapY - FOREST_RADIUS, Minimum.Y + 1);
    forests := RNDPoints(RMGSettings.Objects.Forests*5, 0, Minimum, Maximum);
	  for cntForests := Low(forests) to High(forests) do
    begin
		  count := 0;
      overflow := 0;
		  while (count < RMGSettings.Objects.Trees)
        AND (overflow < (RMGSettings.Objects.Trees shl 1))
        AND (forests[cntForests].X > 0)  // Ignore empty points when is required too many forests in small map
        AND (forests[cntForests].Y > 0) do
      begin
        overflow := overflow + 1;
			  X := Min(forests[cntForests].X + fRNG.RandomI(FOREST_RADIUS), gTerrain.MapX-1);
			  Y := Min(forests[cntForests].Y + fRNG.RandomI(FOREST_RADIUS), gTerrain.MapY-1);
        //TilesPartsArr.Terrain[Y,X] := 245; // Debug
        if (TilesPartsArr.Obj[Y,X] = 255) then
        begin
          count := count + 1;
          case A[Y,X] of
            0,1:      TilesPartsArr.Obj[Y,X] := GetObject(oTree);
            6,7,8,9:  TilesPartsArr.Obj[Y,X] := GetObject(oConifer);
            14,15,16: TilesPartsArr.Obj[Y,X] := GetObject(oTreeTropical);
            else
              count := count - 1;
          end;
        end;
      end;
	  end;
  end;

  // Another objects
  if (RMGSettings.Objects.ObjectDensity > 0) then
  begin
    OBJ_DENSITY := 41 - RMGSettings.Objects.ObjectDensity; // If 0 is none, 1 must be small and 40 maximum -> invert it
    for Y := 1 to gTerrain.MapY-1 do
    begin
      num := fRNG.RandomI(OBJ_DENSITY) + 1;
		  X := num + 1;
		  while X < gTerrain.MapX do
      begin
        if (TilesPartsArr.Obj[Y,X] = 255) then
			    case A[Y,X] of
				    Byte(btGrass),Byte(btBigGrass):
              TilesPartsArr.Obj[Y,X] := GetObjectFromMix(omGrass);

				    Byte(btSwamp):
              TilesPartsArr.Obj[Y,X] := GetObjectFromMix(omSwamp);

				    Byte(btWetland):
              TilesPartsArr.Obj[Y,X] := GetObjectFromMix(omWetland);

            Byte(btWater):
              begin
                if RMGSettings.Objects.Animals then
                begin

                end;
              end;
              //aTiles[K].Obj := GetObjectFromMix(omWater);

            Byte(btGrassGround),Byte(btGround),Byte(btTreeGrass):
              TilesPartsArr.Obj[Y,X] := GetObjectFromMix(omGround);

				    Byte(btGroundSnow),Byte(btSnow1),Byte(btSnow2):
              TilesPartsArr.Obj[Y,X] := GetObjectFromMix(omSnow);

				    Byte(btIce):
				      begin end;

				    Byte(btCoal):
              TilesPartsArr.Obj[Y,X] := GetObjectFromMix(omCoal);

				    Byte(btCoastSand):
              TilesPartsArr.Obj[Y,X] := GetObjectFromMix(omDesert);

				    Byte(btGrassSand1),Byte(btGrassSand2),Byte(btGrassSand3),Byte(btSand):
              TilesPartsArr.Obj[Y,X] := GetObjectFromMix(omDesert);

				    Byte(btStone):
              TilesPartsArr.Obj[Y,X] := GetObjectFromMix(omGrass);

            Byte(btGold),Byte(btEgold):
              begin
              end;
            Byte(btIron),Byte(btEIron):
              begin
              end;
            Byte(btDark):
              begin
              end;
				    else
              begin
              end;
			    end;
        num := fRNG.RandomI(OBJ_DENSITY) + 1;
			  X := X + num;
		  end;
	  end;
  end;

  // Animals
  if RMGSettings.Objects.Animals then
  begin
  {
	  count := 0;
	  while count < WOLVES do
		  if Actions.GiveAnimal(30, fRNG.RandomI(Width-1)+1, fRNG.RandomI(Width-1)+1) <> -1 then
			  count := count + 1;
    end;
    end;
  //}
  end;
end;





// TileTemplate with Cellular automaton (developed but unfinished because of performance impact and results)
function TKMRandomMapGenerator.TileTemplateCA(var A: TKMByte2Array; const Settings: Byte): TKMByte2Array;
type
  TileTemplateArr = array[0..2,0..2] of Integer;
var
   aX,aY, X0,X1,X2, Y0,Y1,Y2, Step, sum: Integer;
   check: Boolean;
   B: array of array of TileTemplateArr;
   Vystup: TKMByte2Array;
const
  MAX_LAYER = 255;
  canWalk: array[0..23] of Boolean = (
    True,True,False,False,False,True,True,True,True,True,True,False,True,True,True,True,True,True,False,False,False,False,False,False
  );
  TerrainPreference: array[0..23,0..3] of Byte = (
    (0,1,7,14),(0,1,7,14),(2,3,4,0),(2,3,4,0),(2,3,4,0),(5,6,8,12),(5,6,8,12),(0,1,7,14),(5,6,8,12),(8,9,10,255),(8,9,10,255),(4,255,255,255),(5,6,8,12),(13,15,16,17),(0,1,7,14),(13,15,16,17),(13,15,16,17),(13,15,16,17),(0,255,255,255),(19,20,255,255),(19,20,255,255),(21,22,255,255),(21,22,255,255),(21,22,255,255)
  );

  function ChooseMin(var A,B: Integer): Integer;
  begin
    if ((not canWalk[B] OR (A < B)) AND canWalk[A]) then
      Result := A
    else
      Result := B;
  end;

  procedure ET3(var T1, T2, Base: Byte);
  var
    i: Integer;
  begin
    for i := Low(TerrainPreference[Base]) to High(TerrainPreference[Base]) do
    begin
      if (TerrainPreference[Base,i] = T1) then
      begin
        T2 := T1;
        Exit;
      end
      else if (TerrainPreference[Base,i] = T2) then
      begin
        T1 := T2;
        Exit;
      end;
    end;
    if (not canWalk[T1] OR (T1 > T2)) AND canWalk[T2] then
      T1 := T2
    else
      T2 := T1;
  end;

  procedure ET2(const bY,bX,invY,invX,TTA_Y1,TTA_X1,TTA_Y2,TTA_X2: Integer);
  var
    val,TTA_X,TTA_Y,X,Y: Integer;
  begin
    TTA_X := TTA_X1;
    TTA_Y := TTA_Y2;
    //{
    if (B[Y1,X1,TTA_Y,TTA_X] = A[Y1,X1]) OR not canWalk[B[Y1,X1,TTA_Y,TTA_X]] then
    begin
      B[Y1,X1,TTA_Y,TTA_X] := ChooseMin(B[Y1,X1,1,TTA_X], B[Y1,X1,TTA_Y,1]);
    end;
    //}

    B[Y1,X1,TTA_Y1,TTA_X2] := ChooseMin(B[Y1,bX,TTA_Y1,TTA_X1], B[bY,X1,TTA_Y2,TTA_X2]);
    B[Y1,X1,TTA_Y2,TTA_X2] := B[Y1,bX,TTA_Y2,TTA_X1];
    B[Y1,X1,TTA_Y1,TTA_X1] := B[bY,X1,TTA_Y2,TTA_X1];
    B[Y1,X1,1,1] := step;

    val := (Byte(B[Y1,X1,2,0] = B[Y1,X1,0,0]) shl 0) OR // Left
           (Byte(B[Y1,X1,0,0] = B[Y1,X1,0,2]) shl 1) OR // Top
           (Byte(B[Y1,X1,0,2] = B[Y1,X1,2,2]) shl 2) OR // Right
           (Byte(B[Y1,X1,2,2] = B[Y1,X1,2,0]) shl 3);   // Down

    {
    if B[Y1,X1,TTA_Y,TTA_X] = A[Y1,X1] then
    begin
      if B[Y1,X1,TTA_Y,1] <> A[Y1,X1] then
        B[Y1,X1,TTA_Y,TTA_X] := B[Y1,X1,TTA_Y,1]
      else if B[Y1,X1,1,TTA_X] <> A[Y1,X1] then
        B[Y1,X1,TTA_Y,TTA_X] := B[Y1,X1,1,TTA_X];
    end;
    //}


    case val of
    // 3-tiles transition
      1: begin // Left %0001
           if (TTA_X = 0) then
           begin
             TTA_X := 2;
             if (ChooseMin(B[Y1,X1,0,2], B[Y1,X1,2,2]) = B[Y1,X1,2,2]) then
               TTA_Y := 0
             else
               TTA_Y := 2;
           end;
           Y := abs(TTA_Y - 2); // from 0 it makes 2 and from 2 it makes 0
           B[Y1,X1,TTA_Y,TTA_X] := ChooseMin(B[Y1,X1,0,0], B[Y1,X1,Y,2]);
         end;
      2: begin // Top %0010
           if (TTA_Y = 0) then
           begin
             TTA_Y := 2;
             if (ChooseMin(B[Y1,X1,2,0], B[Y1,X1,2,2]) = B[Y1,X1,2,2]) then
               TTA_X := 0
             else
               TTA_X := 2;
           end;
           X := abs(TTA_X - 2); // from 0 it makes 2 and from 2 it makes 0
           B[Y1,X1,TTA_Y,TTA_X] := ChooseMin(B[Y1,X1,0,0], B[Y1,X1,2,X]);
         end;
      4: begin // Right %0100
           if (TTA_X = 2) then
           begin
             TTA_X := 0;
             if (ChooseMin(B[Y1,X1,0,0], B[Y1,X1,2,0]) = B[Y1,X1,0,0]) then
               TTA_Y := 2
             else
               TTA_Y := 0;
           end;
           Y := abs(TTA_Y - 2); // from 0 it makes 2 and from 2 it makes 0
           B[Y1,X1,TTA_Y,TTA_X] := ChooseMin(B[Y1,X1,2,2], B[Y1,X1,Y,0]);
         end;
      8: begin // Down %1000
           if (TTA_Y = 2) then
           begin
             TTA_Y := 0;
             if (ChooseMin(B[Y1,X1,0,0], B[Y1,X1,0,2]) = B[Y1,X1,0,0]) then
               TTA_X := 2
             else
               TTA_X := 0;
           end;
           X := abs(TTA_X - 2); // from 0 it makes 2 and from 2 it makes 0
           B[Y1,X1,TTA_Y,TTA_X] := ChooseMin(B[Y1,X1,2,2], B[Y1,X1,0,X]);
         end;
    // 4-tiles transition
      0: begin // None  %0000
        // Special case where are 2 diagonal tiles same
           if (B[Y1,X1,0,0] = B[Y1,X1,2,2]) then // 1 = 4
           begin
             B[Y1,X1,TTA_Y2,TTA_X1] := B[Y1,X1,0,0];
           end
           else if (B[Y1,X1,0,2] = B[Y1,X1,2,0]) then // 2 = 3
           begin
             if (B[Y1,X1,TTA_Y2,TTA_X1] <> B[Y1,X1,0,2]) then
               B[Y1,X1,TTA_Y2,TTA_X1] := B[Y1,X1,0,2]
             else
             begin

             end;
           end;

          // 4 different tiles
          {
            if check then
            begin
              B[Y1,X1] := Byte(btDark);
              B[Y1,X2] := Byte(btDark);
              B[Y2,X1] := Byte(btDark);
              B[Y2,X2] := Byte(btDark);
            end;
            }
          end;
    end;
  end;


begin

  SetLength(B, Length(A), Length(A[Low(A)]));
  SetLength(Vystup, Length(A) shl 1, Length(A[Low(A)]) shl 1);

	for Y1 := 1 to gTerrain.MapY-1 do
  begin
    Y0 := Y1 - 1;
		for X1 := 1 to gTerrain.MapX-1 do
    begin
      X0 := X1 - 1;

    // Detect 8 surrounding tiles and store ideal transition of each tile into B
      //{
      check := true;
      for aY := 0 to 2 do
        for aX := 0 to 2 do
        begin
          B[Y1,X1,aY,aX] := BT[ A[Y1,X1] , A[Y0+aY,X0+aX] ];
          if (B[Y1,X1,aY,aX] <> -1) then
            check := false
          else
            B[Y1,X1,aY,aX] := A[Y1,X1];
        end;
    // Store final value for no-transition tile
      if check then
        B[Y1,X1,1,1] := MAX_LAYER
      else
        B[Y1,X1,1,1] := -1;
      //}
    end;
  end;

  // Left and top edge of map
  for Y1 := 1 to gTerrain.MapY-1 do
  begin
    B[Y1,0,1,2] := BT[ A[Y1,0] , A[Y1,1] ];
    if (B[Y1,0,1,2] = -1) then
      B[Y1,0,1,2] := A[Y1,X1];
    B[Y1,0,0,2] := B[Y1,0,1,2];
    if (B[Y1,0,0,2] = -1) then
      B[Y1,0,0,2] := A[Y1,X1];
    B[Y1,0,2,2] := BT[ A[Y1,0] , A[Y1+1,1] ];
    if (B[Y1,0,2,2] = -1) then
      B[Y1,0,2,2] := A[Y1,X1];
    B[Y1,0,1,1] := MAX_LAYER;
  end;

	for X1 := 1 to gTerrain.MapX-1 do
  begin
      B[0,X1,2,1] := BT[ A[0,X1] , A[1,X1] ];
      if (B[0,X1,2,1] = -1) then
        B[0,X1,2,1] := A[Y1,X1];
      B[0,X1,2,0] := B[0,X1,2,1];
      if (B[0,X1,2,0] = -1) then
        B[0,X1,2,0] := A[Y1,X1];
      B[0,X1,2,2] := BT[ A[0,X1] , A[1,X1+1] ];
      if (B[0,X1,2,2] = -1) then
        B[0,X1,2,2] := A[Y1,X1];
      B[0,X1,1,1] := MAX_LAYER;
  end;

//{
  for step := MAX_LAYER-1 downto MAX_LAYER-Settings do
  begin
	  for Y1 := 1 to gTerrain.MapY-1 do
    begin
      Y0 := Y1 - 1;
      Y2 := Y1 + 1;
		  for X1 := 1 to gTerrain.MapX-1 do
      begin
        if (B[Y1,X1,1,1] = -1) then
        begin
          X0 := X1 - 1;
          X2 := X1 + 1;
          sum := (Byte(B[Y1,X0,1,1] > step) shl 0) OR
                 (Byte(B[Y0,X1,1,1] > step) shl 1) OR
                 (Byte(B[Y1,X2,1,1] > step) shl 2) OR
                 (Byte(B[Y2,X1,1,1] > step) shl 3);
          case sum of
          // 2 exist transitions
            3: begin // Left Top %0011
                ET2(Y0,X0,Y2,X2,0,2,2,0);
               end;
            6: begin // Right Top %0110
                ET2(Y0,X2,Y2,X0,0,0,2,2);
               end;
            12:begin // Right Down %1100
                ET2(Y2,X2,Y0,X0,2,0,0,2);
               end;
            9: begin // Left Down %1001
                ET2(Y2,X0,Y0,X2,2,2,0,0);
               end;
          // 3 exist transitions
            7: begin // Left Top Right %0111
                B[Y1,X1,0,0] := ChooseMin(B[Y1,X0,0,2], B[Y0,X1,2,0]);
                B[Y1,X1,0,2] := ChooseMin(B[Y1,X2,0,0], B[Y0,X1,2,2]);
                B[Y1,X1,2,0] := B[Y1,X0,2,2];
                B[Y1,X1,2,2] := B[Y1,X2,2,0];
                B[Y1,X1,1,1] := step;
               end;
            13: begin // Left Down Right %1101
                B[Y1,X1,2,0] := ChooseMin(B[Y1,X0,2,2], B[Y2,X1,0,0]);
                B[Y1,X1,2,2] := ChooseMin(B[Y1,X2,2,0], B[Y2,X1,0,2]);
                B[Y1,X1,0,0] := B[Y1,X0,0,2];
                B[Y1,X1,0,2] := B[Y1,X2,0,0];
                B[Y1,X1,1,1] := step;
               end;
            14: begin // Top Right Down %1110
                B[Y1,X1,0,2] := ChooseMin(B[Y0,X1,2,2], B[Y1,X2,0,0]);
                B[Y1,X1,2,2] := ChooseMin(B[Y2,X1,0,2], B[Y1,X2,2,0]);
                B[Y1,X1,0,0] := B[Y0,X1,2,0];
                B[Y1,X1,2,0] := B[Y2,X1,0,0];
                B[Y1,X1,1,1] := step;
               end;
            11: begin // Top Left Down %1011
                B[Y1,X1,0,0] := ChooseMin(B[Y0,X1,2,0], B[Y1,X0,0,2]);
                B[Y1,X1,2,0] := ChooseMin(B[Y2,X1,0,0], B[Y1,X0,2,2]);
                B[Y1,X1,0,2] := B[Y0,X1,2,2];
                B[Y1,X1,2,2] := B[Y2,X1,0,2];
                B[Y1,X1,1,1] := step;
               end;
          // 4 exist transitions
            15: begin // Left down %1001
                B[Y1,X1,0,0] := ChooseMin(B[Y1,X0,0,2], B[Y0,X1,2,0]);
                B[Y1,X1,0,2] := ChooseMin(B[Y1,X2,0,0], B[Y0,X1,2,2]);
                B[Y1,X1,2,2] := ChooseMin(B[Y1,X2,2,0], B[Y2,X1,0,2]);
                B[Y1,X1,2,0] := ChooseMin(B[Y1,X0,2,2], B[Y2,X1,0,0]);
                B[Y1,X1,1,1] := step;
               end;
            else begin   end;
          end;


        end;
      end;
    end;
  end;
  //}

	for Y1 := 1 to gTerrain.MapY-1 do
  begin
    Y0 := Y1 - 1;
    Y2 := Y1 + 1;
    for X1 := 1 to gTerrain.MapX-1 do
    begin
      {
      X0 := X1 - 1;
      X2 := X1 + 1;
      Vystup[Y1<<1,X1<<1] := ChooseMin(B[Y1,X0,0,2], B[Y0,X1,2,0]);
      Vystup[Y1<<1,(X1<<1)+1] := ChooseMin(B[Y1,X2,0,0], B[Y0,X1,2,2]);
      Vystup[(Y1<<1)+1,(X1<<1)+1] := ChooseMin(B[Y1,X2,2,0], B[Y2,X1,0,2]);
      Vystup[(Y1<<1)+1,X1<<1] := ChooseMin(B[Y1,X0,2,2], B[Y2,X1,0,0]);
      }
      //{
      if (B[Y1,X1,1,1] > -1) then
      begin
        Vystup[Y1 shl 1,X1 shl 1] := B[Y1,X1,0,0];
        Vystup[Y1 shl 1,(X1 shl 1)+1] := B[Y1,X1,0,2];
        Vystup[(Y1 shl 1)+1,(X1 shl 1)+1] := B[Y1,X1,2,2];
        Vystup[(Y1 shl 1)+1,X1 shl 1] := B[Y1,X1,2,0];
      end
      else
      begin
        Vystup[Y1 shl 1,X1 shl 1] := Byte(btSnow2);
        Vystup[Y1 shl 1,X1 shl 1+1] := Byte(btSnow2);
        Vystup[Y1 shl 1+1,X1 shl 1+1] := Byte(btSnow2);
        Vystup[Y1 shl 1+1,X1 shl 1] := Byte(btSnow2);
      end;
      //}
    end;
  end;
  {
  if (Settings > 4) then
  begin

	for Y1 := 1 to gTerrain.MapY-1 do
		for X1 := 1 to gTerrain.MapX-1 do
    begin
      if (B[Y1,X1,0,0] < 0) then
        B[Y1,X1,0,0] := Byte(btDark);
      if (B[Y1,X1,0,2] < 0) then
        B[Y1,X1,0,2] := Byte(btDark);
      if (B[Y1,X1,2,0] < 0) then
        B[Y1,X1,2,0] := Byte(btDark);
      if (B[Y1,X1,2,2] < 0) then
        B[Y1,X1,2,2] := Byte(btDark);
      Vystup[Y1<<1,X1<<1] := B[Y1,X1,0,0];
      Vystup[Y1<<1,(X1<<1)+1] := B[Y1,X1,0,2];
      Vystup[(Y1<<1)+1,(X1<<1)+1] := B[Y1,X1,2,2];
      Vystup[(Y1<<1)+1,X1<<1] := B[Y1,X1,2,0];
    end;
  end;
    end;
    end;
  //}
  Result := Vystup;
end;



// Old version of TileTemplate (version with CA and actual version provides better results)
function TKMRandomMapGenerator.TileTemplateOLD(var A: TKMByte2Array; const Settings: Byte): TKMByte2Array;
var
   aX,aY,Y, X, X0,X1,X2,Y0,Y1,Y2,cross: Integer;
   check: Boolean;
   B: TKMByte2Array;
   BArr: array[0..2,0..2] of Integer;
const
  canWalk: array[0..23] of Boolean = (
    True,True,False,False,False,True,True,True,True,True,True,False,True,True,True,True,True,True,False,False,False,False,False,False
  );
  TerrainPreference: array[0..23,0..3] of Byte = (
    (0,1,7,14),(0,1,7,14),(2,3,4,0),(2,3,4,0),(2,3,4,0),(5,6,8,12),(5,6,8,12),(0,1,7,14),(5,6,8,12),(8,9,10,255),(8,9,10,255),(4,255,255,255),(5,6,8,12),(13,15,16,17),(0,1,7,14),(13,15,16,17),(13,15,16,17),(13,15,16,17),(0,255,255,255),(19,20,255,255),(19,20,255,255),(21,22,255,255),(21,22,255,255),(21,22,255,255)
  );

  function IdealTransitions(var T1, T2, Corner: Integer; var Original: Byte): Byte;
  begin
    if (T1 <> -1) AND (T2 <> -1) then
    begin
      if      (T1 = Corner) then Result := Corner
      else if (T2 = Corner) then Result := Corner
      else if (T1 < T2) then     Result := T1
      else                       Result := T2;
    end
    else if (T1 <> -1) then      Result := T1
    else if (T2 <> -1) then      Result := T2
    else if (Corner <> -1) then  Result := Corner
    else                         Result := Original;
  end;

  function GetSameTile(var Tile: Byte; Arr: array of Integer): Boolean;
  var
    i,j: Integer;
  begin
    Result := false;
    for i := Low(Arr) to High(Arr)-1 do
    begin
      Tile := Arr[I];
      for j := i+1 to High(Arr) do
        if (Tile = Arr[j]) then
        begin
          Result := true;
          Exit;
        end;
    end;
  end;

  procedure ThreeTilesTransition(var T1, T2, Base: Byte);
  var
    i: Integer;
  begin
    for i := Low(TerrainPreference[Base]) to High(TerrainPreference[Base]) do
    begin
      if (TerrainPreference[Base,i] = T1) then
      begin
        T2 := T1;
        Exit;
      end
      else if (TerrainPreference[Base,i] = T2) then
      begin
        T1 := T2;
        Exit;
      end;
    end;
    if (not canWalk[T1] OR (T1 > T2)) AND canWalk[T2] then
      T1 := T2
    else
      T2 := T1;
  end;

begin

  SetLength(B, High(A) shl 1, High(A[Low(A)]) shl 1);

// Surrounding tiles detection
// Shortcuts (orientation in array A):
//    _____________________________
//   | [Y0,X0]   [Y0,X1]   [Y0,X2] |
//   | [Y1,X0]   [Y1,X1]   [Y1,X2] |    where [Y1,X1] is center point which will be modified
//   | [Y2,X0]   [Y2,X1]   [Y2,X2] |
//    —————————————————————————————
	for Y1 := 1 to gTerrain.MapY-1 do
  begin
    Y0 := Y1 - 1;
    Y2 := Y1 + 1;
    Y := Y1 shl 1;
		for X1 := 1 to gTerrain.MapX-1 do
    begin
      X0 := X1 - 1;
      X2 := X1 + 1;
      X := X1 shl 1;

    // Detect 8 surrounding tiles and store ideal transition of each tile into BArr
      for aY := 0 to 2 do
        for aX := 0 to 2 do
        begin
          if (BT[ A[Y1,X1] , A[aY+Y0,aX+X0] ] <> -1) then // Transitions
            BArr[aY,aX] := BT[ A[Y1,X1] , A[aY+Y0,aX+X0] ]
          else // No transitions
            BArr[aY,aX] := -1;
        end;

    // Select 4 ideal transitions from BArr
      // Left top
      B[Y,X] := IdealTransitions(BArr[0,1], BArr[1,0], BArr[0,0], A[Y1,X1]);
      // Right top
      X := X + 1;
      B[Y,X] := IdealTransitions(BArr[0,1], BArr[1,2], BArr[0,2], A[Y1,X1]);
      // Right down
      Y := Y + 1;
      B[Y,X] := IdealTransitions(BArr[2,1], BArr[1,2], BArr[2,2], A[Y1,X1]);
      // Left down
      X := X - 1;
      B[Y,X] := IdealTransitions(BArr[2,1], BArr[1,0], BArr[2,0], A[Y1,X1]);
      Y := Y - 1;
    end;
  end;


  if (Settings > 2) then
  begin




  for Y1 := 1 to High(B)-1 do
  begin
    Y0 := Y1 - 1;
    Y2 := Y1 + 1;
		for X1 := 1 to High(B[Y1])-1 do
    begin
      X0 := X1 - 1;
      X2 := X1 + 1;
      // Non-accessible texture fix (edge of water)
      if not canWalk[ B[Y1,X1] ] then
      begin
        if canWalk[ B[Y0,X1] ] AND canWalk[ B[Y2,X1] ] then
        begin
          if (B[Y0,X1] < B[Y2,X1]) then
            B[Y1,X1] := B[Y0,X1]
          else
            B[Y1,X1] := B[Y2,X1];
          //if canWalk[ A[Y1 >> 1,X1 >> 1] ] then
          //  B[Y1,X1] := A[Y1 >> 1,X1 >> 1]
          //else if ((Y1 mod 2) = 0) then
          //  B[Y1,X1] := B[Y0,X1]
          //else
          //  B[Y1,X1] := B[Y2,X1];
        end
        else if canWalk[ B[Y1,X0] ] AND canWalk[ B[Y1,X2] ] then
        begin
          if (B[Y1,X0] < B[Y1,X2]) then
            B[Y1,X1] := B[Y1,X0]
          else
            B[Y1,X1] := B[Y1,X2];
        //  if canWalk[ A[Y1 >> 1,X1 >> 1] ] then
        //    B[Y1,X1] := A[Y1 >> 1,X1 >> 1]
        //  else if ((X1 mod 2) = 0) then
        //    B[Y1,X1] := B[Y1,X0]
        //  else
        //    B[Y1,X1] := B[Y1,X2];
        end;
      end
      // Problems which are caused by two tiles transitions
      else
      if (B[Y1,X0] = B[Y1,X2]) AND (B[Y1,X1] <> B[Y1,X0]) AND canWalk[ B[Y1,X0] ] then // Vertical problem
        B[Y1,X1] := B[Y1,X0]
      else if (B[Y0,X1] = B[Y2,X1]) AND (B[Y1,X1] <> B[Y0,X1]) AND canWalk[ B[Y0,X1] ] then // Horizontal problem
        B[Y1,X1] := B[Y0,X1];
      // Single point of different tile (in comparison with surrounding tiles)
      if (B[Y1,X1] <> B[Y0,X1]) AND (B[Y1,X1] <> B[Y2,X1]) AND (B[Y1,X1] <> B[Y1,X0]) AND (B[Y1,X1] <> B[Y1,X2]) then
      begin
        GetSameTile(B[Y1,X1], [ B[Y0,X1],B[Y2,X1],B[Y1,X0],B[Y1,X2] ]);
      end;
    end;
  end;
  //}


// Shortcuts:
//    _______                 ___________________
//   | 1   2 |  is equal to  | [Y1,X1]   [Y1,X2] |
//   | 3   4 |               | [Y2,X1]   [Y2,X2] |
//    ———————                 ———————————————————
// Transitions:
//    ______________     ____________     _______________
//   | 1 › top  ‹ 2 |   | 1 › $2 ‹ 2 |   | 1 › %0010 ‹ 2 |
//   | ˇ          ˇ |   | ˇ        ˇ |   | ˇ           ˇ |
//   | left   right |   | $1      $4 |   | %0001   %0100 |
//   | ^          ^ |   | ^        ^ |   | ^           ^ |
//   | 3 › down ‹ 4 |   | 3 › $8 ‹ 4 |   | 3 › %1000 ‹ 4 |
//    ——————————————     ————————————     ———————————————

  if (Settings > 3) then
  begin
//{
  Y1 := 0;
  while Y1 < High(B)-2 do
  begin
    Y1 := Y1 + 2;
    Y2 := Y1 + 1;
    X1 := 0;
  	while X1 < High(B[Y1])-2 do
    begin
      X1 := X1 + 2;
      X2 := X1 + 1;
      cross := 0;
  	  if (B[Y1,X1] <> B[Y2,X1]) then cross := cross OR $1;// Left
  	  if (B[Y1,X1] <> B[Y1,X2]) then cross := cross OR $2;// Top
  	  if (B[Y1,X2] <> B[Y2,X2]) then cross := cross OR $4;// Right
  	  if (B[Y2,X1] <> B[Y2,X2]) then cross := cross OR $8;// Down

      case cross of
      // 3-tiles transition
        14: ThreeTilesTransition(B[Y1,X2], B[Y2,X2], B[Y1,X1]); // Left  %1110
        13: ThreeTilesTransition(B[Y2,X1], B[Y2,X2], B[Y1,X1]); // Top   %1101
        11: ThreeTilesTransition(B[Y2,X1], B[Y1,X1], B[Y2,X2]); // Right %1011
        7:  ThreeTilesTransition(B[Y1,X2], B[Y1,X1], B[Y2,X2]); // Down  %0111
      // 4-tiles transition
        15: begin
            // Special case where are 2 diagonal tiles same
              check := false;
              if (B[Y1,X1] = B[Y2,X2]) then // 1 = 4
              begin
                if not canWalk[ B[Y1,X2] ] then
                  B[Y1,X2] := B[Y1,X1] // 2 := 1
                else if not canWalk[ B[Y2,X1] ] then
                  B[Y2,X1] := B[Y1,X1] // 3 := 1
                else
                   check := true;
              end
              else if (B[Y2,X1] = B[Y1,X2]) then // 2 = 3
              begin
                if not canWalk[ B[Y1,X1] ] then
                  B[Y1,X1] := B[Y2,X1] // 1 := 2
                else if not canWalk[ B[Y2,X2] ] then
                  B[Y2,X2] := B[Y2,X1] // 4 := 2
                else
                   check := true;
              end
              else
                check := true;

            // 4 different tiles
              if check then
              begin
                B[Y1,X1] := Byte(btDark);
                B[Y1,X2] := Byte(btDark);
                B[Y2,X1] := Byte(btDark);
                B[Y2,X2] := Byte(btDark);
              end;
            end;
        else
        begin
        end;

      end;
    end;
  end;
  //}
  end;
  end;


  Result := B;
end;




{
// Old version of random locs generation
function TKMRandomMapGenerator.RandomPlayerLocs(const LocCount: Integer; const Minimum,Maximum: TKMPoint): TKMPointArray;
  var
    i,j,k, min_idx_overall, min_idx, min_dist, sum_dist, min_dist_overall, sum_dist_overall: Integer;
    Size: TKMPoint;
    Distances: TInteger2Array;
    Points: TKMPointArray;
    Used: TBooleanArray;
  const
    POINTS_PER_A_LOC = 5;
begin

  SetLength(Result, LocCount);
  SetLength(Points, POINTS_PER_A_LOC*LocCount);
  SetLength(Used, Length(Points));
  SetLength(Distances, Length(Points), Length(Points));

  Size.X := Maximum.X - Minimum.X;
  Size.Y := Maximum.Y - Minimum.Y;
  for i := Low(Points) to High(Points) do
  begin
    Points[I].X := fRNG.RandomI(Size.X);
    Points[I].Y := fRNG.RandomI(Size.Y);
    for j := i-1 downto Low(Points) do
    begin
      Distances[i,j] := abs(Points[I].X-Points[j].X) + abs(Points[I].Y-Points[j].Y);
      Distances[j,i] := Distances[i,j];
    end;
    //Distances[i,i] := High(Integer);
    Used[I] := False;
  end;

  for i := 1 to (Length(Points) - Length(Result)) do
  begin
    min_dist_overall := High(Integer);
    sum_dist_overall := High(Integer);
    for j := Low(Points) to High(Points) do
      if not Used[j] then
      begin
        min_dist := High(Integer);
        sum_dist := 0;
        for k := Low(Points) to High(Points) do
          if not Used[k] AND (j <> k) then
          begin
            if Distances[j,k] < min_dist then
              min_dist := Distances[j,k];
            sum_dist := sum_dist + Distances[j,k];
          end;
        if (min_dist_overall > min_dist) OR ( (min_dist_overall = min_dist) AND (sum_dist_overall > sum_dist) ) then
        begin
          min_idx_overall := j;
          min_dist_overall := min_dist;
          sum_dist_overall := sum_dist;
        end;
      end;
    Used[min_idx_overall] := True;
  end;

  i := Low(Result);
  for j := Low(Points) to High(Points) do
    if not Used[j] then
    begin
      Result[I].X := Minimum.X + Points[j].X;
      Result[I].Y := Minimum.Y + Points[j].Y;
      i := i + 1;
    end;
end;
//}





{
// Generator of random points in 2d grid with minimal distance between them (brute force)
function TKMRandomMapGenerator.RNDPointsBF(const cnt: Integer; Minimum,Maximum: TKMPoint): TKMPointArray;

  function RoundUP(variable: Single): Integer;
  begin
    if Frac(variable) <> 0 then
      variable := variable + 0.5;
    Result := Round( variable );
  end;

  var
    i,counter,overflow,cycle,lenX,lenY: Integer;
    dist, minDist,lenCnt, row, column: Single;
begin
  SetLength(Result, cnt);

  lenX := Maximum.X - Minimum.X;
  lenY := Maximum.Y - Minimum.Y;

  lenCnt := Sqrt(lenX * lenY / cnt);

  if lenX <= lenY then
  begin
    column := Round( lenX / lenCnt );
    if column = 0 then
      column := 1;
    row := RoundUP( cnt / column );
  end
  else
  begin
    row := Round( lenY / lenCnt );
    if row = 0 then
      row := 1;
    column := RoundUP( cnt / row );
  end;

  row := lenY / row;
  column := lenX / column;
  minDist := (row*row + column*column); // Decrease maximal distance by 20% to secure that points will be calculated fast

  //minDist := 30*30;
  for cycle := 0 to 5 do // Sometimes there are badly generated points and it is better start from 0 than try find right points
  begin
	  overflow := 0;
    counter := 0;
	  while (counter < cnt) AND (overflow < 10000) do
    begin
		  Result[counter].X := Minimum.X + fRNG.RandomI(lenX);
		  Result[counter].Y := Minimum.Y + fRNG.RandomI(lenY);
		  for i := 0 to counter-1 do
      begin
			  dist := (Result[I].X - Result[counter].X) * (Result[I].X - Result[counter].X) + (Result[I].Y - Result[counter].Y) * (Result[I].Y - Result[counter].Y);
			  if dist < minDist then
        begin
          counter := counter - 1;
				  break;
        end;
      end;
      counter := counter + 1;
		  overflow := overflow + 1;
	  end;
    if counter = cnt then
      break;
  end;

end;
//}




{
// Generator of random player locs in maximal distance
function TKMRandomMapGenerator.RandomPlayerLocs(const LocCount: Integer): TKMPointArray;

  type QLocElement = ^element;
     element = record
       X,Y: Integer;
       Num: Byte;
       NextElement: QLocElement;
     end;

  var
    StartQueue, EndQueue: QLocElement;

  procedure MakeNewQueue;
  begin
      new(StartQueue);
      EndQueue := StartQueue;
  end;

  procedure InsertInQueue(X,Y: Integer; Num: Byte);
  begin
      EndQueue^.X := X;
      EndQueue^.Y := Y;
      EndQueue^.Num := Num;
      new(EndQueue^.NextElement);
      EndQueue := EndQueue^.NextElement;
  end;

  function RemoveFromQueue(var X,Y: Integer; var Num: Byte): Boolean;
  var pom: QLocElement;
  begin
    Result := True;
    if StartQueue = EndQueue then
      Result := False
    else
    begin
      X := StartQueue^.X;
      Y := StartQueue^.Y;
      Num := StartQueue^.Num;
      pom := StartQueue;
      StartQueue := StartQueue^.NextElement;
      dispose(pom);
    end;
  end;

  function IsQueueEmpty: boolean;
  begin
    Result := True;
    if StartQueue <> EndQueue then
      Result := False;
  end;

  // Queue is here much faster (there is not second array to secure that we did not get in 1 element multiple times)
  procedure FillDist(X,Y: Integer; Num: Byte; var Dist: TKMByte2Array);
  begin
    MakeNewQueue();
    InsertInQueue(X, Y, Num);
    while not IsQueueEmpty do
    begin
      RemoveFromQueue(X, Y, Num);
      if Dist[Y,X] > Num then
      begin
        Dist[Y,X] := Num;
        Num := Num + 1;
        if X + 1 <= High(Dist[Y]) then InsertInQueue(X+1, Y, Num);
        if X - 1 >= Low(Dist[Y])  then InsertInQueue(X-1, Y, Num);
        if Y + 1 <= High(Dist)    then InsertInQueue(X, Y+1, Num);
        if Y - 1 >= Low(Dist)     then InsertInQueue(X, Y-1, Num);
      end;
    end;
    while not IsQueueEmpty do
      RemoveFromQueue(X, Y, Num);
  end;

  var
    LocNum,MAXNum: Byte;
    X,Y,count,MaxLimit, NewPoint: Integer;
    Dist: TKMByte2Array;
  const
    DISTANCE_TOLERATION = 1;
begin
  SetLength(Result, LocCount);
  SetLength(Dist, gTerrain.MapY >> 4, gTerrain.MapX >> 4); // division by 16 will increase speed (size of map is always 16*x, x = <2,16>)
  for Y := Low(Dist) to High(Dist) do
    for X := Low(Dist[Y]) to High(Dist[Y]) do
      Dist[Y,X] := High(Byte);

  for LocNum := Low(Result) to High(Result) do
  begin
  // Maximal length of array Dist is 16 * 16 = 255 elements so this method is fast
    MAXNum := 0;
    for Y := Low(Dist) to High(Dist) do
      for X := Low(Dist[Y]) to High(Dist[Y]) do
        if Dist[Y,X] > MAXNum then
          MAXNum := Dist[Y,X];

    MaxLimit := MAXNum - DISTANCE_TOLERATION;
    count := 0;
    for Y := Low(Dist) to High(Dist) do
      for X := Low(Dist[Y]) to High(Dist[Y]) do
        if Dist[Y,X] >= MaxLimit then
          count := count + 1;

    NewPoint := fRNG.RandomI(count) + 1;
    count := 0;
    for Y := Low(Dist) to High(Dist) do
    begin
      for X := Low(Dist[Y]) to High(Dist[Y]) do
      begin
        if Dist[Y,X] >= MaxLimit then
          count := count + 1;
        if count = NewPoint then
          break;
      end;
      if count = NewPoint then
        break;
    end;
    Result[LocNum].X := Min(X << 4 + fRNG.RandomI(16), gTerrain.MapX-1);
    Result[LocNum].Y := Min(Y << 4 + fRNG.RandomI(16), gTerrain.MapY-1);

    FillDist(X, Y, 0, Dist);
  end;
end;
//}





{
// Old version of tiles generator (cannot draw balanced resources)
procedure TKMRandomMapGenerator.GenerateTilesOLD(var aTiles: TKMTerrainTileBriefArray; var A: TKMByte2Array);
var
   X,Y,X0,X1,X2,Y0,Y1,Y2,cross,pom,K: Integer;
   Terrain, Rotation, Height: Byte;
const
  TT: array[0..23,0..23,0..5] of Byte = ( // Textures of transitions + direction set
  ((1,1,1,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(58,57,56,1,1,1),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(74,73,72,1,1,1),			(0,0,0,0,0,0),			(95,94,93,1,1,1),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0)),
  ((18,19,8,1,1,1),			(1,1,1,0,0,0),			(18,19,8,1,1,1),			(18,19,8,1,1,1),			(18,19,8,1,1,1),			(18,19,8,1,1,1),			(18,19,8,1,1,1),			(18,19,8,1,1,1),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(18,19,8,1,1,1),			(18,19,8,1,1,1),			(18,19,8,1,1,1),			(0,0,0,0,0,0),			(18,19,8,1,1,1),			(0,0,0,0,0,0),			(18,19,8,1,1,1),			(18,19,8,1,1,1),			(18,19,8,1,1,1),			(18,19,8,1,1,1),			(18,19,8,1,1,1),			(0,0,0,0,0,0)),
  ((120,121,122,0,0,0),			(120,121,122,0,0,0),			(1,1,1,0,0,0),			(120,121,122,0,0,0),			(0,0,0,0,0,0),			(120,121,122,0,0,0),			(120,121,122,0,0,0),			(120,121,122,0,0,0),			(107,106,105,1,1,1),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(120,121,122,0,0,0),			(120,121,122,0,0,0),			(120,121,122,0,0,0),			(0,0,0,0,0,0),			(120,121,122,0,0,0),			(0,0,0,0,0,0),			(120,121,122,0,0,0),			(120,121,122,0,0,0),			(120,121,122,0,0,0),			(120,121,122,0,0,0),			(120,121,122,0,0,0),			(0,0,0,0,0,0)),
  ((90,91,92,0,0,0),			(90,91,92,0,0,0),			(90,91,92,0,0,0),			(1,1,1,0,0,0),			(90,91,92,0,0,0),			(90,91,92,0,0,0),			(90,91,92,0,0,0),			(90,91,92,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(90,91,92,0,0,0),			(90,91,92,0,0,0),			(90,91,92,0,0,0),			(0,0,0,0,0,0),			(90,91,92,0,0,0),			(0,0,0,0,0,0),			(90,91,92,0,0,0),			(90,91,92,0,0,0),			(90,91,92,0,0,0),			(90,91,92,0,0,0),			(90,91,92,0,0,0),			(0,0,0,0,0,0)),
  ((123,125,127,0,1,0),			(123,125,127,0,0,0),			(114,115,119,0,0,0),			(123,125,127,0,1,0),			(1,1,1,0,0,0),			(107,106,105,1,1,1),			(0,0,0,0,0,0),			(123,125,127,0,1,0),			(107,106,105,1,1,1),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(243,242,241,1,1,1),			(0,0,0,0,0,0),			(243,242,241,1,1,1),			(116,117,118,0,1,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0)),
  ((84,85,86,0,0,0),			(84,85,86,0,0,0),			(84,85,86,0,0,0),			(84,85,86,0,0,0),			(89,88,87,1,1,1),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(89,88,87,1,1,1),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(84,85,86,0,0,0),			(84,85,86,0,0,0),			(0,0,0,0,0,0),			(84,85,86,0,0,0),			(0,0,0,0,0,0),			(84,85,86,0,0,0),			(89,88,87,1,1,1),			(89,88,87,1,1,1),			(89,88,87,1,1,1),			(89,88,87,1,1,1),			(0,0,0,0,0,0)),
  ((56,57,58,0,0,0),			(56,57,58,0,0,0),			(56,57,58,0,0,0),			(56,57,58,0,0,0),			(105,106,107,0,0,0),			(87,88,89,0,0,0),			(1,1,1,0,0,0),			(87,88,89,0,0,0),			(0,0,0,0,0,0),			(65,64,247,1,1,1),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(56,57,58,0,0,0),			(56,57,58,0,0,0),			(56,57,58,0,0,0),			(0,0,0,0,0,0),			(56,57,58,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0)),
  ((66,67,68,0,0,0),			(66,67,68,0,0,0),			(66,67,68,0,0,0),			(66,67,68,0,0,0),			(66,67,68,0,0,0),			(96,97,98,0,0,0),			(96,97,98,0,0,0),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(96,97,98,0,0,0),			(66,67,68,0,0,0),			(66,67,68,0,0,0),			(0,0,0,0,0,0),			(66,67,68,0,0,0),			(0,0,0,0,0,0),			(66,67,68,0,0,0),			(66,67,68,0,0,0),			(66,67,68,0,0,0),			(66,67,68,0,0,0),			(66,67,68,0,0,0),			(0,0,0,0,0,0)),
  ((247,64,65,0,0,0),			(0,0,0,0,0,0),			(247,64,65,0,0,0),			(0,0,0,0,0,0),			(247,64,65,0,1,0),			(247,64,65,0,0,0),			(247,64,65,0,0,0),			(0,0,0,0,0,0),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(213,212,220,1,1,1),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(247,64,65,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(213,212,220,1,1,1),			(213,212,220,1,1,1),			(0,0,0,0,0,0)),
  ((0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(220,212,213,0,0,0),			(0,0,0,0,0,0),			(220,212,213,0,0,0),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(220,212,213,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(220,212,213,0,0,0),			(220,212,213,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0)),
  ((0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(203,204,205,0,0,0),			(203,204,205,0,0,0),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0)),
  ((0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(23,12,22,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(44,4,10,0,0,0),			(0,0,0,0,0,0),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0)),
  ((56,57,58,0,0,0),			(56,57,58,0,0,0),			(56,57,58,0,0,0),			(56,57,58,0,0,0),			(105,106,107,0,0,0),			(87,88,89,0,0,0),			(152,153,154,0,0,0),			(87,88,89,0,0,0),			(247,64,65,1,1,1),			(65,64,247,1,1,1),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(56,57,58,0,0,0),			(113,112,111,1,1,1),			(56,57,58,0,0,0),			(113,112,111,1,1,1),			(56,57,58,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0)),
  ((69,70,71,0,0,0),			(69,70,71,0,0,0),			(69,70,71,0,0,0),			(69,70,71,0,0,0),			(118,117,116,1,0,1),			(69,70,71,0,0,0),			(111,112,113,0,0,0),			(69,70,71,0,0,0),			(111,112,113,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(111,112,113,0,0,0),			(1,1,1,0,0,0),			(104,103,102,1,1,1),			(0,0,0,0,0,0),			(104,103,102,1,1,1),			(0,0,0,0,0,0),			(69,70,71,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0)),
  ((72,73,74,0,0,0),			(72,73,74,0,0,0),			(72,73,74,0,0,0),			(72,73,74,0,0,0),			(75,76,77,1,1,1),			(72,73,74,0,0,0),			(72,73,74,0,0,0),			(72,73,74,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(72,73,74,0,0,0),			(77,76,75,1,1,1),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(77,76,75,1,1,1),			(77,76,75,1,1,1),			(72,73,74,0,0,0),			(77,76,75,1,1,1),			(77,76,75,1,1,1),			(77,76,75,1,1,1),			(77,76,75,1,1,1),			(0,0,0,0,0,0)),
  ((75,76,77,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(241,242,243,0,1,0),			(0,0,0,0,0,0),			(75,76,77,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(102,103,104,0,0,0),			(102,103,104,0,0,0),			(75,76,77,0,0,0),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(75,76,77,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0)),
  ((93,94,95,0,0,0),			(93,94,95,0,0,0),			(93,94,95,0,0,0),			(93,94,95,0,0,0),			(78,79,80,0,0,0),			(93,94,95,0,0,0),			(93,94,95,0,0,0),			(93,94,95,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(93,94,95,0,0,0),			(78,79,80,0,0,0),			(78,79,80,0,0,0),			(78,79,80,0,0,0),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(93,94,95,0,0,0),			(78,79,80,0,0,0),			(78,79,80,0,0,0),			(78,79,80,0,0,0),			(78,79,80,0,0,0),			(0,0,0,0,0,0)),
  ((81,82,83,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(99,100,101,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(99,100,101,0,0,0),			(99,100,101,0,0,0),			(81,82,83,0,0,0),			(81,82,83,0,0,0),			(81,82,83,0,0,0),			(1,1,1,0,0,0),			(93,94,95,0,0,0),			(78,79,80,0,0,0),			(78,79,80,0,0,0),			(78,79,80,0,0,0),			(78,79,80,0,0,0),			(0,0,0,0,0,0)),
  ((0,139,138,0,0,0),			(0,139,138,0,0,0),			(0,139,138,0,0,0),			(0,139,138,0,0,0),			(236,200,143,0,0,0),			(0,139,138,0,0,0),			(0,139,138,0,0,0),			(0,139,138,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,139,138,0,0,0),			(0,139,138,0,0,0),			(0,139,138,0,0,0),			(0,139,138,0,0,0),			(0,139,138,0,0,0),			(0,139,138,0,0,0),			(1,1,1,0,0,0),			(0,139,138,0,0,0),			(0,139,138,0,0,0),			(0,139,138,0,0,0),			(0,139,138,0,0,0),			(0,0,0,0,0,0)),
  ((180,172,176,0,0,0),			(180,172,176,0,0,0),			(180,172,176,0,0,0),			(180,172,176,0,0,0),			(236,200,237,0,0,0),			(183,175,179,0,0,0),			(183,175,179,0,0,0),			(180,172,176,0,0,0),			(49,171,51,0,0,0),			(49,171,51,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(183,175,179,0,0,0),			(181,173,177,0,0,0),			(182,174,178,0,0,0),			(182,174,178,0,0,0),			(182,174,178,0,0,0),			(182,174,178,0,0,0),			(0,0,0,0,0,0),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0)),
  ((180,172,176,0,0,0),			(180,172,176,0,0,0),			(180,172,176,0,0,0),			(180,172,176,0,0,0),			(236,200,237,0,0,0),			(183,175,179,0,0,0),			(183,175,179,0,0,0),			(180,172,176,0,0,0),			(49,171,51,0,0,0),			(49,171,51,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(183,175,179,0,0,0),			(181,173,177,0,0,0),			(182,174,178,0,0,0),			(182,174,178,0,0,0),			(182,174,178,0,0,0),			(182,174,178,0,0,0),			(0,0,0,0,0,0),			(144,145,145,0,0,0),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0)),
  ((188,168,184,0,0,0),			(188,168,184,0,0,0),			(188,168,184,0,0,0),			(188,168,184,0,0,0),			(236,200,239,0,0,0),			(191,167,187,0,0,0),			(191,167,187,0,0,0),			(188,168,184,0,0,0),			(52,166,54,0,0,0),			(52,166,54,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(191,167,187,0,0,0),			(189,169,185,0,0,0),			(190,170,186,0,0,0),			(190,170,186,0,0,0),			(190,170,186,0,0,0),			(190,170,186,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(1,1,1,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0)),
  ((188,168,184,0,0,0),			(188,168,184,0,0,0),			(188,168,184,0,0,0),			(188,168,184,0,0,0),			(236,200,239,0,0,0),			(191,167,187,0,0,0),			(191,167,187,0,0,0),			(188,168,184,0,0,0),			(52,166,54,0,0,0),			(52,166,54,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(191,167,187,0,0,0),			(189,169,185,0,0,0),			(190,170,186,0,0,0),			(190,170,186,0,0,0),			(190,170,186,0,0,0),			(190,170,186,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(148,149,149,0,0,0),			(1,1,1,0,0,0),			(0,0,0,0,0,0)),
  ((0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(0,0,0,0,0,0),			(165,50,53,0,0,0),			(165,50,53,0,0,0),			(1,1,1,0,0,0))
);
  FT: array[0..23,0..20] of Byte = ( // Full textures + variance
    (0,0,0,0,1,1,1,2,2,2,3,3,3,5,5,6,6,13,14,0,19),(8,8,8,9,9,9,11,0,0,0,0,0,0,0,0,0,0,0,0,0,7),(48,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1),(40,40,41,41,42,42,43,0,0,0,0,0,0,0,0,0,0,0,0,0,7),(192,192,192,193,193,196,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6),(34,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1),(35,36,37,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3),(17,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2),(47,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1),(46,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1),(45,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1),(44,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1),(155,155,155,154,153,153,153,152,0,0,0,0,0,0,0,0,0,0,0,0,8),(31,32,32,32,33,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5),(26,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1),(27,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1),(28,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1),(29,29,30,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3),(128,129,130,131,132,133,134,135,136,137,0,0,0,0,0,0,0,0,0,0,10),(144,145,146,146,147,147,147,0,0,0,0,0,0,0,0,0,0,0,0,0,7),(156,157,158,159,201,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5),(148,149,150,150,151,151,151,151,0,0,0,0,0,0,0,0,0,0,0,0,8),(160,161,162,163,164,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5),(245,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1)
  );
  DF: array[0..1,0..3] of Byte = ( // Direction fixer
    (0,1,2,3),(2,3,0,1)
  );
begin

	// Used signs giving directions:
	//		2
	//	1	x	4
	//		7

  K := 0;
	for Y1 := 1 to gTerrain.MapY-1 do begin
		Y0 := Y1-1; Y2 := Y1+1;
		for X1 := 1 to gTerrain.MapX-1 do begin
			X0 := X1-1; X2 := X1+1;
			cross := 0;
			// Detect neighborhood
			if (A[Y1,X0] <> A[Y1,X1]) AND (TT[ A[Y1,X1] , A[Y1,X0] , 0 ] <> 0) then cross := cross+1;// Left
			if (A[Y0,X1] <> A[Y1,X1]) AND (TT[ A[Y1,X1] , A[Y0,X1] , 0 ] <> 0) then cross := cross+2;// Top
			if (A[Y1,X2] <> A[Y1,X1]) AND (TT[ A[Y1,X1] , A[Y1,X2] , 0 ] <> 0) then cross := cross+4;// Right
			if (A[Y2,X1] <> A[Y1,X1]) AND (TT[ A[Y1,X1] , A[Y2,X1] , 0 ] <> 0) then cross := cross+7;// Down
			case cross of
        // Direct edge
        1:	begin Terrain := TT[ A[Y1,X1] , A[Y1,X0] , 1 ]; Rotation := DF[ TT[ A[Y1,X1] , A[Y1,X0] , 4 ] , 1 ]; end;//1
        2:	begin Terrain := TT[ A[Y1,X1] , A[Y0,X1] , 1 ]; Rotation := DF[ TT[ A[Y1,X1] , A[Y0,X1] , 4 ] , 2 ]; end;//2
        4:	begin Terrain := TT[ A[Y1,X1] , A[Y1,X2] , 1 ]; Rotation := DF[ TT[ A[Y1,X1] , A[Y1,X2] , 4 ] , 3 ]; end;//4
        7:	begin Terrain := TT[ A[Y1,X1] , A[Y2,X1] , 1 ]; Rotation := DF[ TT[ A[Y1,X1] , A[Y2,X1] , 4 ] , 0 ]; end;//7
        // Small corner
        3:	begin Terrain := TT[ A[Y1,X1] , A[Y1,X0] , 0 ]; Rotation := DF[ TT[ A[Y1,X1] , A[Y1,X0] , 3 ] , 1 ]; end;//1+2
        6:	begin Terrain := TT[ A[Y1,X1] , A[Y1,X2] , 0 ]; Rotation := DF[ TT[ A[Y1,X1] , A[Y1,X2] , 3 ] , 2 ]; end;//2+4
        8:	begin Terrain := TT[ A[Y1,X1] , A[Y1,X0] , 0 ]; Rotation := DF[ TT[ A[Y1,X1] , A[Y1,X0] , 3 ] , 0 ]; end;//1+7
        11: begin Terrain := TT[ A[Y1,X1] , A[Y1,X2] , 0 ]; Rotation := DF[ TT[ A[Y1,X1] , A[Y1,X2] , 3 ] , 3 ]; end;//7+4
        else begin
          // Big corner
					if (A[Y0,X0] <> A[Y1,X1]) AND (TT[ A[Y1,X1] , A[Y0,X0] , 0 ] <> 0) then	     begin Terrain := TT[ A[Y1,X1] , A[Y0,X0] , 2 ]; Rotation := DF[ TT[ A[Y1,X1] , A[Y0,X0] , 5 ] , 1 ]; end
          else if (A[Y0,X2] <> A[Y1,X1]) AND (TT[ A[Y1,X1] , A[Y0,X2] , 0 ] <> 0) then begin Terrain := TT[ A[Y1,X1] , A[Y0,X2] , 2 ]; Rotation := DF[ TT[ A[Y1,X1] , A[Y0,X2] , 5 ] , 2 ]; end
          else if (A[Y2,X0] <> A[Y1,X1]) AND (TT[ A[Y1,X1] , A[Y2,X0] , 0 ] <> 0) then begin Terrain := TT[ A[Y1,X1] , A[Y2,X0] , 2 ]; Rotation := DF[ TT[ A[Y1,X1] , A[Y2,X0] , 5 ] , 0 ]; end
          else if (A[Y2,X2] <> A[Y1,X1]) AND (TT[ A[Y1,X1] , A[Y2,X2] , 0 ] <> 0) then begin Terrain := TT[ A[Y1,X1] , A[Y2,X2] , 2 ]; Rotation := DF[ TT[ A[Y1,X1] , A[Y2,X2] , 5 ] , 3 ]; end
          else begin
          // Full texture + variance
						if (A[Y1,X1] = 12) then begin
							if (A[Y1+2,X1] <> A[Y1,X1]) OR (A[Y1-2,X1] <> A[Y1,X1]) OR (A[Y1,X1+2] <> A[Y1,X1]) OR (A[Y1,X1-2] <> A[Y1,X1]) then
								pom := fRNG.RandomI(4)+4
							else
								pom := fRNG.RandomI(4);
						end else if (A[Y1,X1] <> 0) OR (fRNG.Random() > 0.8) then// 1 = grass, 12 = coal
							pom := fRNG.RandomI(FT[ A[Y1,X1] , 20 ])
						else pom := 0;
            Terrain := FT[ A[Y1,X1] , pom ];
            Rotation := fRNG.RandomI(3);
          end;
        end;
			end;
      // TILE HEIGHT
			if (A[Y1,X1] >= 18) AND (A[Y0,X1] >= 18) AND (A[Y2,X1] >= 18) AND (A[Y1,X2] >= 18) AND (A[Y0,X2] >= 18) AND (X0 > 0) AND (A[Y1,X0-1] >= 18) then begin
        Height := fRNG.RandomI(80)+20;
			end else if (A[Y1,X1] > 1) AND (A[Y1,X1] < 5) then begin
        Height := fRNG.RandomI(10)+5;
			end else begin
        Height := fRNG.RandomI(12)+15;
			end;

      aTiles[K].Terrain := Terrain;
      aTiles[K].Rotation := Rotation;
      aTiles[K].Height := Height;
      //          SMAZAT        !!!!
      aTiles[K].Height := 0;
      K := K + 1;
		end;
	end;
end;
//}


{
// Old resources and INACCESSIBLE texture generator
function TKMRandomMapGenerator.CreateResources(RMGSettings: TKMRMGSettings; var A: TKMByte2Array): TBalancedResource1Array;

  type PtrConnection = ^element;
     element = record
       X,Y: Integer;
       Probability: Single;
       NextElement: PtrConnection;
     end;

var
  cnt_FINAL, cnt_ACTUAL, RESOURCE: Integer;
  PROB_REDUCER: Single;
  StartQueue, EndQueue: PtrConnection;
  S,Count: TInteger2Array;
  P: TSingle2Array;
  PointsArr: TKMPoint2Array;

  procedure MakeNewQueue;
  begin
      new(StartQueue);
      EndQueue := StartQueue;
  end;

  procedure InsertInQueue(X,Y: Integer; Probability: Single);
  begin
      EndQueue^.X := X;
      EndQueue^.Y := Y;
      EndQueue^.Probability := Probability;
      new(EndQueue^.NextElement);
      EndQueue := EndQueue^.NextElement;
  end;

  function RemoveFromQueue(var X,Y: Integer; var Probability: Single): Boolean;
  var pom: PtrConnection;
  begin
    Result := True;
    if StartQueue = EndQueue then
    begin
      Result := False;// Queue is empty
    end
    else
    begin
      X := StartQueue^.X;
      Y := StartQueue^.Y;
      Probability := StartQueue^.Probability;
      pom := StartQueue;
      StartQueue := StartQueue^.NextElement;
      dispose(pom);
    end;
  end;

  function IsQueueEmpty: boolean;
  begin
    Result := True;
    if StartQueue <> EndQueue then
      Result := False;
  end;


  procedure FloodFillWithQueue(X,Y: Integer; Probability: Single);
  var
    prob: Single;
  begin
    MakeNewQueue();
    InsertInQueue(X, Y, Probability);
    while not IsQueueEmpty AND (cnt_actual < cnt_FINAL) do
    begin
      RemoveFromQueue(X, Y, Probability);
      if (Count[Y,X] <> 0) AND (cnt_actual < cnt_FINAL) AND (fRNG.Random() < (probability * P[Y,X])) then
      begin
        cnt_actual := cnt_actual + Count[Y,X];
        Count[Y,X] := 0;
        FloodFill(PointsArr[Y,X].X, PointsArr[Y,X].Y, S[ PointsArr[Y,X].Y , PointsArr[Y,X].X ], RESOURCE, A, S);
        prob := probability - PROB_REDUCER;
        if prob > 0 then
        begin
          if X+1 <= High(PointsArr[Y]) then InsertInQueue( X+1, Y,   prob );
          if Y-1 >= 0 then                  InsertInQueue( X,   Y-1, prob );
          if X-1 >= 0 then                  InsertInQueue( X-1, Y,   prob );
          if Y+1 <= High(PointsArr) then    InsertInQueue( X,   Y+1, prob );
        end;
      end;
    end;
    while not IsQueueEmpty do
      RemoveFromQueue(X, Y, Probability);
  end;

  procedure InacessibleTextures(const RES, COUNT, base_POINTS, variance_POINTS, cnt_FIN: Integer; const prob_REDUC, BASE_PROBABILITY: Single);
  var
    i,j,len: Integer;
    TP_S,TP_E: TKMPoint;
    CenterPoints, Point: TKMPointArray;
  begin
    RESOURCE := RES;
    PROB_REDUCER := prob_REDUC;
    cnt_FINAL := cnt_FIN;
    TP_S.X := 1;
    TP_S.Y := 1;
    TP_E.X := High(PointsArr[0])-1;
    TP_E.Y := High(PointsArr)-1;
    CenterPoints := RNDPoints(COUNT, 0, TP_S, TP_E);
    for i := Low(CenterPoints) to High(CenterPoints) do
    begin
      if BASE_PROBABILITY < fRNG.Random() then
        continue;
      TP_S := CenterPoints[I];
      len := 9 - fRNG.RandomI(9);
      TP_E.X := Min(High(PointsArr[0]), CenterPoints[I].X + len);
      TP_E.Y := Min(High(PointsArr), CenterPoints[I].Y + 10 - len);
      Point := RNDPoints(base_POINTS+fRNG.RandomI(variance_POINTS), 0, TP_S, TP_E);
      for j := Low(Point) to High(Point) do
      begin
        cnt_ACTUAL := 0;
        FloodFillWithQueue(Point[j].X, Point[j].Y, 1);
      end;
    end;
  end;

var
  X,Y,Loc,i,j,overflow, PLAYERS, idx, Quantity, Tiles: Integer;
  val: Single;
  TP_Start,TP_End: TKMPoint;
  Locs,Points,Point: TKMPointArray;
  ResAmount: TIntegerArray; // Amount of tiles of specific resources
  Visited: TBoolean2Array;
const
  //RandomBiom: array[0..5] of TBiomeType = (btBigGrass,btGrassGround, btGround, btTreeGrass, btGrassSand1, btCoastSand);
  EResWat: array[0..4] of TBiomeType = (btSwamp,btWater,btWetland,btEgold,btEIron);
  Resources: array[0..4] of TBiomeType = (btStone,btIron,btGold,btCoal,btCoal);
  //BIO: array[0..12] of TBiomeType = (btGrass,btBigGrass,btGrassGround,btGround,btTreeGrass,btGroundSnow,btSnow1,btSnow2,btCoastSand,btGrassSand1,btGrassSand2,btGrassSand3,btSand);
  // Configuration (all is in voronoi diagram distance: real distance = distance * VORONOI_STEP)
  VORONOI_STEP = 3;
  RES_PROB: array[0..4] of Single = (0.3,0.2,0.2,0.1,0.1); // Probability penalization (only afect final shape: 0 = one line, 1 = multiple separated mountains)
  ALL_RES_RADIUS = Round(30 / VORONOI_STEP);
  CENTER_RES = Round(ALL_RES_RADIUS / 2);
  MIN_PL_DISTANCE = 15;
  SPEC_RES_RADIUS: array[0..4] of Byte = (5, 5, 5, 7, 7); // Stone, Iron, Gold, Coal, Coal

begin
	// Grass: btBigGrass,btGrass
	// Water: btSwamp,btWetland,btWater
	// Ground: btGrassGround,btGround,btTreeGrass
	// Snow: btGroundSnow,btSnow1,btSnow2,btIce
	// Sand: btCoastSand,btGrassSand1,btGrassSand2,btGrassSand3,btSand
	// Resources: btCoal,btStone,btGold,btEgold,btIron,btEIron

  PLAYERS := RMGSettings.Resource.Players;
  ResAmount := TIntegerArray.Create(RMGSettings.Resource.Stone*20, RMGSettings.Resource.Iron*20, RMGSettings.Resource.Gold*20, RMGSettings.Resource.Iron*20*2, RMGSettings.Resource.Gold*20);
  //ResAmount := TIntegerArray.Create(0, 0, RMGSettings.Resource.Gold*20);
  //ResAmount := TIntegerArray.Create(0, RMGSettings.Resource.Gold*100, 0);


// Initialization (init arrays + edges of the map)
  S := VoronoiMod(VORONOI_STEP,PointsArr);
  for X := Low(S) to High(S) do
  begin
    S[Low(S),X] := 0;
    S[High(S),X] := 0;
  end;
  for Y := Low(S) to High(S) do
  begin
    S[Y,Low(S[Y])] := 0;
    S[Y,High(S[Y])] := 0;
  end;
// Make grid from Voronoi diagram with center points (PointsArr) and count of points in 1 shape (Count)
  SetLength(Count,Length(PointsArr),Length(PointsArr[I]));
  SetLength(P,Length(PointsArr),Length(PointsArr[I]));
  for i := Low(PointsArr) to High(PointsArr) do
    for j := Low(PointsArr[I]) to High(PointsArr[I]) do
    begin
      P[i,j] := 1;
      Count[i,j] := 0;
      X := PointsArr[i,j].X;
      Y := PointsArr[i,j].Y;
      FloodSearch(X,Y,S[Y,X],-S[Y,X],Count[i,j],S);
    end;


  if RMGSettings.Resource.Active then
  begin
    // Resources
    TP_Start.X := 1;
    TP_Start.Y := 1;
    TP_End.X := High(PointsArr[0]) - ALL_RES_RADIUS - 1;
    TP_End.Y := High(PointsArr) - ALL_RES_RADIUS - 1;
    //Locs := RNDPoints(PLAYERS, MIN_PL_DISTANCE, TP_Start, TP_End);
    Locs := RNDPointsBF(PLAYERS, MIN_PL_DISTANCE, TP_Start, TP_End);
    for Loc := 0 to PLAYERS-1 do
    begin
      TP_Start.X := Locs[Loc].X;
      TP_Start.Y := Locs[Loc].Y;
      TP_End.X := Locs[Loc].X + ALL_RES_RADIUS;
      TP_End.Y := Locs[Loc].Y + ALL_RES_RADIUS;
      Points := RNDPoints(3, CENTER_RES, TP_Start, TP_End);
      SetLength(Points,Length(Points)+2);
      Points[3] := Points[1];
      Points[4] := Points[2];
      for i := Low(ResAmount) to High(ResAmount) do
        if ResAmount[I] > 0 then
        begin
          Quantity := ResAmount[I];// << (3*Byte(Resources[I]=btStone));    //BALANCE IT !!!!!!!!!!!!!!
          Tiles := Quantity >> 1;

          cnt_FINAL := Tiles;
          cnt_ACTUAL := 0;
          RESOURCE := Byte(Resources[I]);
          PROB_REDUCER := RES_PROB[I];

          TP_Start.X := Max(Points[I].X - SPEC_RES_RADIUS[I], 1);
          TP_Start.Y := Max(Points[I].Y - SPEC_RES_RADIUS[I], 1);
          TP_End.X := Min(Points[I].X + SPEC_RES_RADIUS[I], High(PointsArr[0]) - 1);
          TP_End.Y := Min(Points[I].Y + SPEC_RES_RADIUS[I], High(PointsArr) - 1);
          overflow := 0;
          while (cnt_ACTUAL < cnt_FINAL) AND (overflow < 10) do
          begin
            overflow := overflow + 1;
            if Count[Points[I].Y,Points[I].X] <> 0 then
            begin
              FloodFillWithQueue(Points[I].X, Points[I].Y, 1);
              SetLength(Result, Length(Result)+1); // Just a few interation so SetLength is fine
              idx := High(Result);
              Result[idx].Point := PointsArr[Points[I].Y,Points[I].X];
              Result[idx].Quantity := Round(cnt_FINAL / Max(1,Min(cnt_FINAL, cnt_ACTUAL)) * Quantity);
              val := Result[idx].Quantity;
              Result[idx].Resource := RESOURCE;
            end;
            Points[I].X := TP_Start.X + fRNG.RandomI(TP_End.X-TP_Start.X);
            Points[I].Y := TP_Start.Y + fRNG.RandomI(TP_End.Y-TP_Start.Y);
          end;
        end;
    end;
  end;

  // Mountains
  if RMGSettings.Resource.Active AND RMGSettings.Obstacle.Active then
  begin
  // Decrease probability of inacessible textures near Locs
    for Loc := Low(Locs) to High(Locs) do
    begin
      val := -1;
      TP_Start.X := Locs[Loc].X + CENTER_RES;
      TP_Start.Y := Locs[Loc].Y + CENTER_RES;
      TP_End.X := Locs[Loc].X + CENTER_RES;
      TP_End.Y := Locs[Loc].Y + CENTER_RES;
      while val < 1 do
      begin
        for X := TP_Start.X to TP_End.X do
        begin
          if P[TP_Start.Y,X] > val then
            P[TP_Start.Y,X] := val;
          if P[TP_End.Y,X] > val then
            P[TP_End.Y,X] := val;

          //A[TP_Start.Y*3,X*3] := Byte(btDark);
          //A[TP_End.Y*3,X*3] := Byte(btDark);

        end;
        for Y := TP_Start.Y to TP_End.Y do
        begin
          if P[Y,TP_Start.X] > val then
            P[Y,TP_Start.X] := val;
          if P[Y,TP_End.X] > val then
            P[Y,TP_End.X] := val;

          //A[Y*3,TP_Start.X*3] := Byte(btDark);
          //A[Y*3,TP_End.X*3] := Byte(btDark);

        end;
        TP_Start.X := Max(TP_Start.X - 1, 0);
        TP_Start.Y := Max(TP_Start.Y - 1, 0);
        TP_End.X := Min(TP_End.X + 1, High(P[0]));
        TP_End.Y := Min(TP_End.Y + 1, High(P));
        val := val + 0.2;
      end;
    end;
  end;

  if RMGSettings.Obstacle.Active then
  begin
    if RMGSettings.Obstacle.EGold then
      InacessibleTextures(Byte(btEGold), 20, 3, 2, 30, 0.2, 0.4);
      //InacessibleTextures(Byte(btEGold), 60, 3, 2, 50, 0.25, 0.5);
    if RMGSettings.Obstacle.EIron then
      InacessibleTextures(Byte(btEIron), 20, 3, 2, 30, 0.2, 0.4);
      //InacessibleTextures(Byte(btEIron), 60, 3, 2, 50, 0.25, 0.5);
    if RMGSettings.Obstacle.Water then
      InacessibleTextures(Byte(btWater), 6, 3, 3, 50, 0.25, 0.5);
    if RMGSettings.Obstacle.Swamp then
      InacessibleTextures(Byte(btSwamp), 5, 4, 1, 50, 0.25, 0.5);
    if RMGSettings.Obstacle.Wetland then
      InacessibleTextures(Byte(btWetland), 5, 3, 2, 50, 0.25, 0.5);
  end;

  for Y := High(A)-1 downto 1 do
	  for X := High(A[Y])-1 downto 1 do
      if (A[Y,X] = Byte(btStone)) OR (A[Y,X] = Byte(btGold)) OR (A[Y,X] = Byte(btIron)) OR (A[Y,X] = Byte(btCoal)) then
      begin
         A[Y+1,X] := A[Y,X];
         A[Y,X+1] := A[Y,X];
         A[Y+1,X+1] := A[Y,X];
      end;
  for Y := 1 to High(A)-1 do
	  for X := 1 to High(A[Y])-1 do
      if (A[Y,X] = Byte(btStone)) OR (A[Y,X] = Byte(btGold)) OR (A[Y,X] = Byte(btIron)) OR (A[Y,X] = Byte(btCoal)) then
      begin
         A[Y-1,X] := A[Y,X];
         A[Y,X-1] := A[Y,X];
         A[Y-1,X-1] := A[Y,X];
      end;
  if RMGSettings.Resource.Active then
  begin
    for Loc := Low(Locs) to High(Locs) do
    begin
      X := PointsArr[ Locs[Loc].Y , Locs[Loc].X ].X;
      Y := PointsArr[ Locs[Loc].Y , Locs[Loc].X ].Y;
      A[Y,X] := Byte(btDark);
      A[Y+1,X] := Byte(btDark);
      A[Y,X+1] := Byte(btDark);
      A[Y+1,X+1] := Byte(btDark);
    end;
  end;


  SetLength(Visited,gTerrain.MapY,gTerrain.MapX);
  for i := Low(Visited) to High(Visited) do
    for j := Low(Visited[I]) to High(Visited[I]) do
      Visited[i,j] := False;

  if RMGSettings.Objects.Animals then
    for i := Low(Result) to High(Result) do
    begin
      if Result[I].Resource = Byte(btGold) then
        RESOURCE := 2
      else if Result[I].Resource = Byte(btIron) then
        RESOURCE := 3
      else // Coal and Stone are always fine
        continue;
      if not Visited[ Result[I].Point.Y , Result[I].Point.X ] then
        MinerFixer(Result[I].Point, RESOURCE, Result[I].Resource, Visited, A);
    end;
end;
//}






{
// Old fast Voronoi diagram (without calculation of Euclidean distance)
function TKMRandomMapGenerator.VoronoiMod(const Step: Integer; var Points: TKMPoint2Array): TInteger2Array;

  function RoundUP(variable: Single): Integer;
  begin
    if Frac(variable) <> 0 then
      variable := variable + 0.5;
    Result := Round( variable );
  end;

  var
    X,aX,X0,X1,X2,Y,aY,Y0,Y1,Y2,i,idxX,idxY,move,price: Integer;
    History: TInteger2Array;
begin
  SetLength(Result, gTerrain.MapY+1, gTerrain.MapX+1);
  SetLength(History, gTerrain.MapY+1, gTerrain.MapX+1);
  SetLength(Points, RoundUP((gTerrain.MapY-1) / (Step*1.0)), RoundUP((gTerrain.MapX-1) / (Step*1.0)));
  for Y := Low(Result) to High(Result) do
    for X := Low(Result[Y]) to High(Result[Y]) do
    begin
      History[Y,X] := 0;
      Result[Y,X] := 0;
    end;

  i := 1;
  idxY := 0;
  Y := 1;
  while Y < gTerrain.MapY do
  begin
    idxX := 0;
    X := 1;
    while X < gTerrain.MapX do
    begin
      Points[idxY,idxX].Y := Min(gTerrain.MapY-1, Y + fRNG.RandomI(Step));
      Points[idxY,idxX].X := Min(gTerrain.MapX-1, X + fRNG.RandomI(Step));
      Y1 := Points[idxY,idxX].Y;
      X1 := Points[idxY,idxX].X;
      move := 0;
      price := Step;
      while move < Step do
      begin
        Y0 := Max(1, Y1 - move);
        X0 := Max(1, X1 - move);
        Y2 := Min(gTerrain.MapY-1, Y1 + move);
        X2 := Min(gTerrain.MapX-1, X1 + move);
        for aX := X0 to X2 do
        begin
          if History[Y0,aX] < price then
          begin
            History[Y0,aX] := price;
            Result[Y0,aX] := i;
          end;
          if History[Y2,aX] < price then
          begin
            History[Y2,aX] := price;
            Result[Y2,aX] := i;
          end;
        end;
        for aY := Y0 to Y2 do
        begin
          if History[aY,X0] < price then
          begin
            History[aY,X0] := price;
            Result[aY,X0] := i;
          end;
          if History[aY,X2] < price then
          begin
            History[aY,X2] := price;
            Result[aY,X2] := i;
          end;
        end;
        move := move + 1;
        price := price - 1;
      end;
      i := i + 1;
      idxX := idxX + 1;
      X := X + Step;
    end;
    idxY := idxY + 1;
    Y := Y + Step;
  end;

end;
//}

end.
