{
Random Map Generator
@author: Martin Toupal
@e-mail: poznamenany@gmail.com
}
unit KM_RandomMapGenerator;
{$I KaM_Remake.inc}
interface
uses
  KM_CommonTypes, KM_Terrain, Math,  // KM_Utils = random number
  KM_Points, KM_RMGUtils, KM_Defaults, KM_ResWares;


type

  TBiomeType = (btGrass,btBigGrass,btWetland,btSwamp,btWater,btCoal,btGrassGround,btGround,btTreeGrass,btGroundSnow,btSnow1,btSnow2,btIce,btCoastSand,btGrassSand1,btGrassSand2,btGrassSand3,btSand,btStone,btGold,btEgold,btIron,btEIron,btDark);
  TObstacleType = (otSwamp,otWater,otWetland,otEgold,otEIron);
  TObjects = (oStone,oShrub,oBranch,oMushroom,oFlower,oGrass,oDebris,oTreeDry,oTree,oConifer,oTreeTropical,oCactus,oPalm,oWaterTypes);
  TObjectMix = (omStone,omGrass,omSwamp,omGround,omSnow,omCoal,omDesert,omWater, omWetland);
  TBiomeTypeArray = array of TBiomeType;


  TTileParts = record // This construction allows to make search classes universal (they will work with TKMByte2Array instead of TTileParts)
    Terrain: TKMWord2Array;
    Rotation, Height, Obj: TKMByte2Array;
  end;

  TKMRMGSettings = record
    Locs: record
      Active: Boolean;
      Players: Byte;
      Layout, ProtectedRadius: Byte;
      Resource: record
        Active, ConnectLocs, MineFix: Boolean;
        Stone, Gold, Iron: Integer;
      end;
      InitialResources: Word;
    end;
    Obstacle: record
      Active: Boolean;
      Ratio: array[TObstacleType] of Byte;
      Density, Size, Variance: Byte;
    end;
    Walkable: record
      Active, Grass, Ground, Snow, Sand: Boolean;
      FirstLayerStep, FirstLayerLimit, SecondLayerStep, SecondLayerLimit: Word;
    end;
    Height: record
      Active, HideNonSmoothTransition: Boolean;
      Step,Slope,Height: Integer;
    end;
    OnePath: record
      NoGoZones, ReplaceTerrain: Boolean;
    end;
    Objects: record
      Active, Animals: Boolean;
      ObjectDensity, ForestDensity, Trees: Byte;
    end;
    Seed: Integer;
    BasicTiles, CA: Boolean;
  end;


  TKMRandomMapGenerator = class
  private
    fMapX, fMapY: Word;
    fRNG: TKMRandomNumberGenerator;
    fRes: TKMBalancedResources;
  // Generators of random points / seeds / shapes / shapes with certain rules
    function RandomPlayerLocs(): TKMPointArray;
    function LinearInterpolation(const aStep,aMaxNum: Integer): TInteger2Array;
    function VoronoiMod(const aStep: Integer; var aPoints: TKMPoint2Array): TInteger2Array;
    function RNDPointsInGrid(const acnt: Single; aSpace: Integer; const aMinimum,aMaximum: TKMPoint): TKMPointArray;
    function RNDPointInCircle(aMin,aMax,aCenter: TKMPoint; aMaxRadius: Single): TKMPoint;

    procedure SnowMountains(var A: TKMByte2Array);
    procedure NoGoZones(var Locs: TKMPointArray; var TilesPartsArr: TTileParts);
  // Rules for extraction shapes from linear interpolation
    procedure Rules(const aTopLim,aTopLim2,aDownLim,aDownLim2: Integer; var aArr: TInteger2Array);
  // Procedures wich make composition of biomes
    procedure CreateResources(var aLocs: TKMPointArray; var A: TKMByte2Array);
    procedure CreateObstacles(var aLocs: TKMPointArray; var A: TKMByte2Array; var aVoronoi,aCountArr: TInteger2Array; var aPointsArr: TKMPoint2Array);
    procedure CreateBiomes(var A: TKMByte2Array);
  // Fix of mountain to be able to construct mine there
    //procedure MineFix(const Position: TKMPoint; const MINESIZE, Resource: Byte; var Visited: TBoolean2Array; var A: TKMByte2Array);
    procedure MineFix(var A: TKMByte2Array);
  // These functions secure smooth transitions
    procedure CellularAutomaton(var A: TKMByte2Array);
    function TileTemplate(var A: TKMByte2Array): TKMByte2Array;
    //function TileTemplateCA(var A: TKMByte2Array; const Settings: Byte): TKMByte2Array;
    //function TileTemplateOLD(var A: TKMByte2Array; const Settings: Byte): TKMByte2Array;
  // Generators of right rotated tiles and objects
    //procedure GenerateTilesOLD(var TilesPartsArr: TTileParts; var A: TKMByte2Array);
    procedure GenerateTiles(var TilesPartsArr: TTileParts; var A: TKMByte2Array; var B: TKMByte2Array);
    procedure GenerateBasicTiles(var TilesPartsArr: TTileParts; var A: TKMByte2Array);
    procedure GenerateHeight(var aLocs: TKMPointArray; var TilesPartsArr: TTileParts; var A: TKMByte2Array; var TileTempl: TKMByte2Array);
    procedure GenerateObjects(var TilesPartsArr: TTileParts; var A: TKMByte2Array);
    procedure MineFinalFixer(var TilesPartsArr: TTileParts; var A: TKMByte2Array);
  public
    RMGSettings: TKMRMGSettings;
    constructor Create();
    destructor Destroy(); override;
    procedure SaveSettings();
    procedure LoadSettings();

    property Resources: TKMBalancedResources read fRes;
  // Random number generators
    procedure GenerateMap(aSetLocProperties: Boolean);
  end;



  const
  len_BIOME = 24;
  BT: array[0..len_BIOME-1,0..len_BIOME-1] of Integer = (
  //  0  1  2  3  4   5  6  7  8  9  10 11 12 13 14  15 16 17 18 19  20 21 22 23
	  (-1,-1,-1,-1,-1, -1,-1,-1,-1,-1, -1,-1,-1,-1,-1, 14,-1,16,-1,-1, -1,-1,-1,-1), //  0 btGrass
    ( 0,-1, 0, 0, 0,  0, 0, 0, 0,-1, -1,-1,-1, 0, 0, -1, 0,-1, 0, 0,  0, 0, 0,-1), //  1 btBigGrass
    ( 0, 0,-1, 0,-1,  0, 0, 0, 0,-1, -1,-1,-1, 0, 0, -1, 0,-1, 0, 0,  0, 0, 0,-1), //  2 btWetland
    ( 0, 0, 0,-1, 0,  0, 0, 0, 0,-1, -1,-1,-1, 0, 0, -1, 0,-1, 0, 0,  0, 0, 0,-1), //  3 btSwamp
    ( 0, 0, 2, 0,-1, -1, 7,-1, 0, 7, -1,-1,-1,-1,15, -1,15,-1,-1,-1, -1,-1,-1,-1), //  4 btWater
    ( 0, 0, 0, 0, 4, -1,-1,-1, 6,-1,  9,-1,-1,-1, 0,  0, 0,-1,-1,-1, -1,-1,-1,-1), //  5 btCoal
    ( 0, 0, 0, 0, 7,  7,-1,-1,-1, 7, -1,-1,-1, 0, 0, -1, 0,-1, 0, 7,  7, 7, 7,-1), //  6 btGrassGround
    ( 0, 0, 0, 0, 4,  7, 6,-1, 6,-1,  9,-1,-1,-1, 0,  0, 0,-1,-1,-1, -1,-1,-1,-1), //  7 btGround
    ( 0, 0, 0, 0, 0,  6, 6, 6,-1,-1, -1,-1,-1, 0, 0, -1, 0,-1, 0, 0,  0, 0, 0,-1), //  8 btTreeGrass
    ( 0,-1,-1,-1, 7,  7, 7, 7,-1,-1, -1,10,-1, 7,-1, -1,-1,-1,-1,-1, -1,-1,-1,-1), //  9 btGroundSnow
    ( 0,-1,-1,-1,-1,  9,-1, 9,-1, 9, -1,-1,-1,-1,-1, -1,-1,-1,-1,-1, -1,-1,-1,-1), // 10 btSnow1
    (-1,-1,-1,-1,-1, -1,-1,-1,-1,10, 10,-1,-1,-1,-1, -1,-1,-1,-1,-1, -1,-1,-1,-1), // 11 btSnow2
    (-1,-1,-1,-1, 4, -1,-1,-1,-1,-1, 10,-1,-1,-1,-1, -1,-1,-1,-1,-1, -1,-1,-1,-1), // 12 btIce
    ( 0, 0, 0, 0, 4, -1, 0, 7, 0, 7, -1,-1,-1,-1,15, -1,15,-1,-1,-1, -1,-1,-1,-1), // 13 btCoastSand
    ( 0, 0, 0, 0,15,  0, 0, 0, 0,-1, -1,-1,-1,-1,-1, -1,15,15, 0,15, 15,15,15,-1), // 14 btGrassSand1
    (14,-1,-1,-1, 4, 14,-1,14,-1,-1, -1,-1,-1,13,14, -1,-1,-1,14,-1, -1,-1,-1,-1), // 15 btGrassSand2
    ( 0, 0, 0, 0,15,  0, 0, 0, 0,-1, -1,-1,-1,15,15, 15,-1,-1, 0,15, 15,15,15,-1), // 16 btGrassSand3
    (16,-1,-1,-1,-1, -1,-1,-1,-1,-1, -1,-1,-1,13,16, 16,16,-1, 0,15, 15,15,15,-1), // 17 btSand
    ( 0, 0, 0, 0, 4,  7, 0, 7, 0, 9, 10,-1,-1,13, 0,  0, 0, 0,-1, 0,  0, 0, 0,-1), // 18 btStone
    ( 0, 0, 0, 0, 4,  7, 7, 7, 0, 9, 10,-1,-1,13,15, 15,15,15, 0,-1, -1,-1,-1,-1), // 19 btGold
    ( 0, 0, 0, 0, 4,  7, 7, 7, 0, 9, 10,-1,-1,13,15, 15,15,15, 0,-1, -1,-1,-1,-1), // 20 btEgold
    ( 0, 0, 0, 0, 4,  7, 7, 7, 0, 9, 10,-1,-1,13,15, 15,15,15, 0,20, 20,-1,-1,-1), // 21 btIron
    ( 0, 0, 0, 0, 4,  7, 7, 7, 0, 9, 10,-1,-1,13,15, 15,15,15, 0,20, 20,-1,-1,-1), // 22 btEIron
    (-1,-1,-1,-1,-1, -1,-1,-1,-1,-1, -1,-1,-1,-1,-1, -1,-1,-1,-1,20, 20,22,22,-1)  // 23 btDark
  );

  T_FIX: array[0..len_BIOME-1,0..len_BIOME-1] of Byte = ( // Transition fixer
  // 0  1  2  3  4   5  6  7  8  9  10 11 12 13 14  15 16 17 18 19  20 21 22 23
    (1, 1, 1, 1, 1,  1, 1, 1, 1, 1,  0, 0, 0, 1, 1,  2, 1, 2, 1, 1,  1, 1, 1, 0), //  0 btGrass
    (1, 1, 2, 2, 2,  2, 2, 2, 2, 0,  0, 0, 0, 2, 2,  0, 2, 0, 2, 2,  2, 2, 2, 0), //  1 btBigGrass
    (1, 2, 1, 2, 1,  2, 2, 2, 2, 0,  0, 0, 0, 2, 2,  0, 2, 0, 2, 2,  2, 2, 2, 0), //  2 btWetland
    (1, 2, 2, 1, 2,  2, 2, 2, 2, 0,  0, 0, 0, 2, 2,  0, 2, 0, 2, 2,  2, 2, 2, 0), //  3 btSwamp
    (1, 2, 1, 2, 1,  1, 2, 1, 2, 2,  0, 0, 1, 1, 2,  1, 2, 0, 1, 1,  1, 1, 1, 0), //  4 btWater
    (1, 2, 2, 2, 1,  1, 1, 1, 2, 1,  2, 0, 0, 1, 2,  2, 2, 0, 1, 1,  1, 1, 1, 0), //  5 btCoal
    (1, 2, 2, 2, 2,  1, 1, 1, 1, 2,  0, 0, 0, 2, 2,  0, 2, 0, 2, 2,  2, 2, 2, 0), //  6 btGrassGround
    (1, 2, 2, 2, 1,  1, 1, 1, 2, 1,  2, 0, 0, 1, 2,  2, 2, 0, 1, 1,  1, 1, 1, 0), //  7 btGround
    (1, 2, 2, 2, 2,  2, 1, 2, 1, 0,  0, 0, 0, 2, 2,  0, 2, 0, 2, 2,  2, 2, 2, 0), //  8 btTreeGrass
    (1, 0, 0, 0, 2,  1, 2, 1, 0, 1,  1, 2, 0, 2, 0,  0, 0, 0, 1, 1,  1, 1, 1, 0), //  9 btGroundSnow
    (0, 0, 0, 0, 0,  2, 0, 2, 0, 1,  1, 1, 1, 0, 0,  0, 0, 0, 1, 1,  1, 1, 1, 0), // 10 btSnow1
    (0, 0, 0, 0, 0,  0, 0, 0, 0, 2,  1, 1, 0, 0, 0,  0, 0, 0, 0, 0,  0, 0, 0, 0), // 11 btSnow2
    (0, 0, 0, 0, 1,  0, 0, 0, 0, 0,  1, 0, 1, 0, 0,  0, 0, 0, 0, 0,  0, 0, 0, 0), // 12 btIce
    (1, 2, 2, 2, 1,  1, 2, 1, 2, 2,  0, 0, 0, 1, 2,  1, 2, 1, 1, 1,  1, 1, 1, 0), // 13 btCoastSand
    (1, 2, 2, 2, 2,  2, 2, 2, 2, 0,  0, 0, 0, 2, 1,  1, 2, 2, 2, 2,  2, 2, 2, 0), // 14 btGrassSand1
    (2, 0, 0, 0, 1,  2, 0, 2, 0, 0,  0, 0, 0, 1, 1,  1, 1, 1, 2, 1,  1, 1, 1, 0), // 15 btGrassSand2
    (1, 2, 2, 2, 2,  2, 2, 2, 2, 0,  0, 0, 0, 2, 2,  1, 1, 1, 2, 2,  2, 2, 2, 0), // 16 btGrassSand3
    (2, 0, 0, 0, 0,  0, 0, 0, 0, 0,  0, 0, 0, 1, 2,  1, 1, 1, 2, 2,  2, 2, 2, 0), // 17 btSand
    (1, 2, 2, 2, 1,  1, 2, 1, 2, 1,  1, 0, 0, 1, 2,  2, 2, 2, 1, 2,  2, 2, 2, 0), // 18 btStone
    (1, 2, 2, 2, 1,  1, 2, 1, 2, 1,  1, 0, 0, 1, 2,  1, 2, 2, 2, 1,  1, 0, 0, 1), // 19 btGold
    (1, 2, 2, 2, 1,  1, 2, 1, 2, 1,  1, 0, 0, 1, 2,  1, 2, 2, 2, 1,  1, 0, 0, 1), // 20 btEgold
    (1, 2, 2, 2, 1,  1, 2, 1, 2, 1,  1, 0, 0, 1, 2,  1, 2, 2, 2, 1,  1, 1, 1, 1), // 21 btIron
    (1, 2, 2, 2, 1,  1, 2, 1, 2, 1,  1, 0, 0, 1, 2,  1, 2, 2, 2, 1,  1, 1, 1, 1), // 22 btEIron
    (0, 0, 0, 0, 0,  0, 0, 0, 0, 0,  0, 0, 0, 0, 0,  0, 0, 0, 0, 1,  1, 1, 1, 1)  // 23 btDark
  );

  canWalk: array[0..len_BIOME-1] of Boolean = (
    True,  //  0 btGrass
    True,  //  1 btBigGrass
    False, //  2 btWetland
    False, //  3 btSwamp
    False, //  4 btWater
    True,  //  5 btCoal
    True,  //  6 btGrassGround
    True,  //  7 btGround
    True,  //  8 btTreeGrass
    True,  //  9 btGroundSnow
    True,  // 10 btSnow1
    True,  // 11 btSnow2
    False, // 12 btIce
    True,  // 13 btCoastSand
    True,  // 14 btGrassSand1
    True,  // 15 btGrassSand2
    True,  // 16 btGrassSand3
    True,  // 17 btSand
    False, // 18 btStone
    False, // 19 btGold
    False, // 20 btEgold
    False, // 21 btIron
    False, // 22 btEIron
    False  // 23 btDark
  );

  WT: array[0..399] of Boolean = ( // Walkable tiles
  //  0      1      2      3      4        5      6      7      8      9       10     11     12     13     14       15
    True,  True,  True,  True,  False,   True,  True,  False, True,  True,    False, True,  False, True,  True,    False,
    True,  True,  True,  True,  True,    True,  True,  False, False, True,    True,  True,  True,  True,  True,    True,
    True,  True,  True,  True,  True,    True,  True,  True,  False, False,   False, False, True,  True,  True,    True,
    False, True,  False, False, True,    False, False, True,  True,  True,    True,  True,  True,  True,  True,    True,
    True,  True,  True,  True,  True,    True,  True,  True,  True,  True,    True,  True,  True,  True,  True,    True,
    True,  True,  True,  True,  True,    True,  True,  True,  True,  True,    True,  True,  True,  True,  True,    True,
    True,  True,  True,  True,  True,    True,  True,  True,  True,  False,   True,  True,  True,  True,  False,   True,
    True,  True,  False, False, True,    True,  False, False, True,  True,    True,  True,  True,  True,  False,   False,
    False, False, False, False, False,   False, False, False, False, False,   False, True,  False, False, False,   False,
    False, False, False, False, False,   False, False, False, True,  True,    True,  True,  False, False, False,   False,
    False, False, False, False, False,   False, True,  True,  True,  True,    True,  True,  True,  True,  True,    True,
    False, False, False, False, True,    True,  True,  True,  False, False,   False, False, True,  True,  True,    True,
    False, False, False, False, False,   True,  False, False, False, False,   True,  True,  True,  True,  False,   True,
    False, False, False, False, True,    True,  True,  True,  False, False,   False, False, True,  True,  True,    True,
    False, False, False, False, False,   False, False, False, False, False,   False, False, False, False, False,   False,
    False, False, True,  True,  False,   False, True,  True,  True,  True,    True,  True,  True,  True,  True,    True,
	  True,  True,  False, False, False,   True,  True,  False, False, False,   False, False, False, True,  True,    True,
    False, True,  False, False, False,   False, True,  True,  True,  False,   True,  False, False, False, True,    True,
    True,  False, True,  False, False,   False, True,  True,  True,  False,   True,  False, False, False, True,    True,
    False, True,  True,  False, False,   False, False, False, False, False,   False, False, False, False, False,   False,
    False, False, False, False, False,   False, False, False, False, False,   False, False, False, False, False,   False,
    False, False, False, False, False,   False, False, False, False, False,   False, False, False, False, False,   False,
    False, False, False, False, False,   False, False, False, False, False,   False, False, False, False, False,   False,
    False, False, False, False, False,   False, False, False, False, False,   False, False, False, False, False,   False,
    False, False, False, False, False,   False, False, False, False, False,   False, False, False, False, False,   False
  );

implementation

uses
  SysUtils, KM_HandsCollection, KM_CommonClasses, KM_Game, KM_ResMapElements, KM_Hand, Dialogs;



{ TKMRandomMapGenerator }
constructor TKMRandomMapGenerator.Create();
begin
  fRNG := TKMRandomNumberGenerator.Create;
  fRes := TKMBalancedResources.Create;

  // Default configuration
  with RMGSettings do
  begin
    with Locs do
    begin
      Active := True;
      Players := 4;
      Layout := 0;
      ProtectedRadius := 6;
      with Resource do
      begin
        Active := True;
        ConnectLocs := True;
        MineFix := True;
        Stone := 1000;
        Gold := 350;
        Iron := 300;
      end;
    end;
    with Obstacle do
    begin
      Active := True;
      Density := 10;
      Size := 10;
      Variance := 10;
      Ratio[otEgold] := 8;
      Ratio[otEIron] := 7;
      Ratio[otSwamp] := 1;
      Ratio[otWetland] := 2;
      Ratio[otWater] := 4;
    end;
    with Walkable do
    begin
      Active := True;
      Grass := True;
      Ground := True;
      Snow := True;
      Sand := True;
      FirstLayerStep := 5;
      FirstLayerLimit := 6;
      SecondLayerStep := 5;
      SecondLayerLimit := 6;
    end;
    with OnePath do
    begin
      NoGoZones := True;
      ReplaceTerrain := True;
    end;
    with Height do
    begin
      Active := True;
      Step := 4;
      Slope := 40;
      Height := 10;
      HideNonSmoothTransition := True;
    end;
    with Objects do
    begin
      Active := True;
      ObjectDensity := 6;
      ForestDensity := 10;
      Trees := 20;
      Animals := True;
    end;
    Seed := 0;
    BasicTiles := False;
    CA := True;
  end;
end;


destructor TKMRandomMapGenerator.Destroy();
begin
  fRNG.Free;
  fRes.Free;

  inherited;
end;


procedure TKMRandomMapGenerator.SaveSettings();
begin

end;


procedure TKMRandomMapGenerator.LoadSettings();
begin

end;


// Main procedure for RMG - requires also RMGSettings: TKMRMGSettings (global variable)
procedure TKMRandomMapGenerator.GenerateMap(aSetLocProperties: Boolean);
var
  Y, X, K, L: Integer;
  A,TileTemplateArr: TKMByte2Array;
  TilesPartsArr: TTileParts;
  Locs: TKMPointArray;
  LocProperty: TKMChooseLoc;
  Revealers: TKMPointTagList;
  Tiles: TKMTerrainTileBriefArray;
  Errors: TKMTerrainTileChangeErrorArray;
  InitResStr: String;
begin
  // Clean memory (data from the previous generation)
  fRes.ClearArray();

  // Seed MUST be <> 0!!!
  if (RMGSettings.Seed = 0) then
    RMGSettings.Seed := Round(High(Integer)*Random);

  // Init arrays and variables
  fMapX := gTerrain.MapX;
  fMapY := gTerrain.MapY;
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

  SetLength(Locs, 0);
  fRNG.Seed := RMGSettings.Seed;
  if RMGSettings.Locs.Active then
    Locs := RandomPlayerLocs();

  // Generate map

  // Create resources
  fRNG.Seed := RMGSettings.Seed;
  CreateResources(Locs, A);

  // Create biomes
  fRNG.Seed := RMGSettings.Seed;
  if RMGSettings.Walkable.Active then
    CreateBiomes(A);

  // Apply cellular automaton
  if RMGSettings.CA then
    CellularAutomaton(A);

  // Fix mines
  if RMGSettings.Locs.Resource.MineFix AND (Length(Locs) > 0) then
    MineFix(A);

  // Detect and replace inaccessible terrain
  fRNG.Seed := RMGSettings.Seed;
  if RMGSettings.OnePath.ReplaceTerrain then
    SnowMountains(A);

  // Create tile decomposition (every tile have 4 parts and max 2 biomes)
  fRNG.Seed := RMGSettings.Seed;
  TileTemplateArr := TileTemplate(A);

  // Generate correct  tiles
  fRNG.Seed := RMGSettings.Seed;
  if RMGSettings.BasicTiles then
    GenerateBasicTiles(TilesPartsArr,A)
  else
    GenerateTiles(TilesPartsArr, A, TileTemplateArr);

  // Mark inaccessible places with no-walk object
  fRNG.Seed := RMGSettings.Seed;
  if RMGSettings.OnePath.NoGoZones AND (Length(Locs) > 0) then
    NoGoZones(Locs, TilesPartsArr);

  // Generate height
  fRNG.Seed := RMGSettings.Seed;
  if RMGSettings.Height.Active then
    GenerateHeight(Locs, TilesPartsArr, A, TileTemplateArr);

  // Generate objects
  fRNG.Seed := RMGSettings.Seed;
  if RMGSettings.Objects.Active then
    GenerateObjects(TilesPartsArr, A);

  // Fix mine (Final version)
  if RMGSettings.Locs.Resource.MineFix then
    MineFinalFixer(TilesPartsArr, A);

  // Update Tiles + Rotation, Height and Objects
  SetLength(Tiles, fMapY * fMapX);
  K := 0;
  for Y := 1 to fMapY-1 do
    for X := 1 to fMapX-1 do
    begin
      //K := (Y-1)*(fMapX-1)+X-1;
      Tiles[K].Y := Y;
      Tiles[K].X := X;
      Tiles[K].Terrain := TilesPartsArr.Terrain[Y,X];
      Tiles[K].Rotation := TilesPartsArr.Rotation[Y,X];
      Tiles[K].Height := TilesPartsArr.Height[Y,X];
      Tiles[K].Obj := TilesPartsArr.Obj[Y,X];
      Tiles[K].UpdateTerrain := True;
      Tiles[K].UpdateRotation := True;
      Tiles[K].UpdateHeight := True;
      Tiles[K].UpdateObject := True;
      K := K + 1;
    end;
  gTerrain.ScriptTrySetTilesArray(Tiles, False, Errors);

  // Add animals
   //gHands[K].CanBeHuman := True;
   // if gTerrain.CanPlaceUnit(P, TKMUnitType(gGameCursor.Tag1)) then
   // gHands.PlayerAnimals.AddUnit(TKMUnitType(gGameCursor.Tag1), P);
   // gMySpectator.Hand.AddUnit(TKMUnitType(gGameCursor.Tag1), P, False)

  // Prepare init resources
  FillChar(LocProperty, SizeOf(LocProperty), #0);
  if aSetLocProperties then
    with LocProperty do
    begin
      Allowed := True;
      Placed := False;
      case RMGSettings.Locs.InitialResources of
        0:
          begin
            Resources[wtStone] := 70;
            Resources[wtWood] := 50;
            Resources[wtGold] := 60;
            Resources[wtWine] := 60;
            Resources[wtBread] := 35;
            Resources[wtSausages] := 15;
            Resources[wtFish] := 30;
            Units[utSerf] := 4;
            Units[utWorker] := 3;
            InitResStr := 'Low';
          end;
        1:
          begin
            Resources[wtStone] := 100;
            Resources[wtWood] := 70;
            Resources[wtGold] := 80;
            Resources[wtWine] := 70;
            Resources[wtBread] := 50;
            Resources[wtSausages] := 30;
            Resources[wtFish] := 40;
            Units[utSerf] := 5;
            Units[utWorker] := 4;
            InitResStr := 'Medium';
          end;
        2:
          begin
            Resources[wtStone] := 130;
            Resources[wtWood] := 90;
            Resources[wtGold] := 100;
            Resources[wtWine] := 80;
            Resources[wtBread] := 65;
            Resources[wtSausages] := 45;
            Resources[wtFish] := 50;
            Units[utSerf] := 7;
            Units[utWorker] := 5;
            InitResStr := 'High';
          end;
      end;
    end;
  // Hand properties
  for K := 0 to Length(Locs) - 1 do
  begin
    gHands[K].CenterScreen := Locs[K];
    gHands[K].ChooseLocation := LocProperty;
    Revealers := gGame.MapEditor.Revealers[K];
    Revealers.Clear;
    Revealers.Add(Locs[K], 20);
    for L := 0 to fRes.Count - 1 do
      with fRes.Resources[L] do
        if (InitOwner = K) then //InitOwner, Resource, MinesCnt: Byte;
          for X := Low(Points) to High(Points) do
            Revealers.Add(Points[X], 10);
  end;

  // Update game info
  if (gGame <> nil) then
  begin
    //gGame.MissionMode := mmNormal;

    if (Length(gGame.MapTxtInfo.Author) = 0) then
      gGame.MapTxtInfo.Author := 'Random number generator';
    if (Length(gGame.MapTxtInfo.SmallDesc) = 0) then
      gGame.MapTxtInfo.SmallDesc := 'Randomly generated map';
    if (Length(gGame.MapTxtInfo.GetBigDesc) = 0) then
      with RMGSettings.Locs do
        gGame.MapTxtInfo.SetBigDesc( Format(
          'This is a randomly generated map [%dx%d] for %d players||Parameters:| Stones = %d| Gold = %d| Iron = %d| Initial resources: %s',
          [fMapX, fMapY, Players, Resource.Stone, Resource.Gold, Resource.Iron, InitResStr]
        ));

    gGame.MapTxtInfo.IsRMG := True;

    gGame.MapTxtInfo.BlockTeamSelection := False;
    gGame.MapTxtInfo.BlockColorSelection := False;
    gGame.MapTxtInfo.BlockPeacetime := False;
    gGame.MapTxtInfo.BlockFullMapPreview := False;
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
  Xmax := ((fMapX div aStep) + 1) * aStep + 1;
  Ymax := ((fMapY div aStep) + 1) * aStep + 1;
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
  //X0,X2,Y0,Y2,move,
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
      //}
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
    I, Distance, Variance, Step: Integer;
    PhaseArr: array[0..3] of Integer;
  begin
    PhaseArr[0] := aMaxOffset.X - aMinOffset.X;
    PhaseArr[1] := aMaxOffset.Y - aMinOffset.Y + PhaseArr[0];
    PhaseArr[2] := aMaxOffset.X - aMinOffset.X + PhaseArr[1];
    PhaseArr[3] := aMaxOffset.Y - aMinOffset.Y + PhaseArr[2];

    Step := Round(PhaseArr[3] / (Length(aLocs)*1.0));
    Variance := Step shr 1;
    Distance := fRNG.RandomI(Variance);
    for I := Low(aLocs) to High(aLocs) do
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
      Distance := Step * (I+1) + fRNG.RandomI(Variance);
    end;
  end;

  // Locs in Vertical position
  procedure Vertical(var aLocs: TKMPointArray; aMinOffset, aMaxOffset: TKMPoint);
  var
    I, StepLeft, StepRight, cntLeft, cntRight, VarianceX, VarianceYLeft, VarianceYRight: Integer;
  begin
    cntLeft := Length(aLocs) shr 1;
    cntRight := Length(aLocs) - cntLeft;
    if (cntLeft <> cntRight) AND (fRNG.RandomI(2) = 1) then  // If there is not equal cnt of players swap sometimes loc
    begin
      Inc(cntLeft, 1);
      Dec(cntRight, 1);
    end;

    StepLeft := Round((aMinOffset.Y+aMaxOffset.Y - 4) / Max(1, cntLeft));
    StepRight := Round((aMinOffset.Y+aMaxOffset.Y - 4) / Max(1, cntRight));
    //StepLeft :=  Round((aMaxOffset.Y - aMinOffset.Y) / Max(1, cntLeft));
    //StepRight := Round((aMaxOffset.Y - aMinOffset.Y) / Max(1, cntRight));

    VarianceYLeft := StepLeft shr 1;
    VarianceYRight := StepRight shr 1;
    VarianceX := (aMaxOffset.X - aMinOffset.X) shr 3;
    I := 0;
    while I < cntLeft do
    begin
      aLocs[I].X := aMinOffset.X + fRNG.RandomI(VarianceX);
      aLocs[I].Y := aMinOffset.Y + StepLeft * I + fRNG.RandomI(VarianceYLeft);
      I := I + 1;
    end;
    while I < Length(aLocs) do
    begin
      aLocs[I].X := aMaxOffset.X - fRNG.RandomI(VarianceX);
      aLocs[I].Y := Min(fMapY, aMinOffset.Y + StepRight * (I - cntLeft) + fRNG.RandomI(VarianceYRight));
      I := I + 1;
    end;
  end;

  // Locs in Horizontal position
  procedure Horizontal(var aLocs: TKMPointArray; aMinOffset, aMaxOffset: TKMPoint);
  var
    I: Byte;
  begin
    // Swap X and Y and do Vertical procedure
    aMinOffset := KMPoint(aMinOffset.Y, aMinOffset.X);
    aMaxOffset := KMPoint(aMaxOffset.Y, aMaxOffset.X);
    Vertical(aLocs, aMinOffset, aMaxOffset);
    for I := Low(aLocs) to High(aLocs) do
      aLocs[I] := KMPoint(aLocs[I].Y, aLocs[I].X);
  end;

  // Random locs selected from group of generated points (brute force algorithm but for 1-12 locs it is fine)
  procedure Random(var Locs: TKMPointArray; const Minimum,Maximum: TKMPoint);
  const
    POINTS_PER_A_LOC = 20;
  var
    Change, PointSelected: Boolean;
    I,K,L, RemIdx, overflow: Integer;
    distNew, distOld: Single;
    Size: TKMPoint;
    LocIdx: TIntegerArray;
    Distances: TSingle2Array;
    Points: TKMPointArray;
  begin
    SetLength(LocIdx, Length(Locs));
    SetLength(Points, POINTS_PER_A_LOC*Length(Locs));
    SetLength(Distances, Length(Points), Length(Points));

  // Generate points
    Size := KMPoint(Maximum.X - Minimum.X, Maximum.Y - Minimum.Y);
    for I := Low(Points) to High(Points) do
    begin
      Points[I] := KMPoint(fRNG.RandomI(Size.X), fRNG.RandomI(Size.Y));
      for K := I-1 downto Low(Points) do
      begin
        Distances[I,K] := KMDistanceSqr(Points[I], Points[K]);
        Distances[K,I] := Distances[I,K];
      end;
    end;

  // Select first set of indexes (points)
  for I := Low(LocIdx) to High(LocIdx) do
    LocIdx[I] := I;

  // Try to remove every selected point and replace it with different point with max distance
  overflow := 0;
  repeat
    overflow := overflow + 1;
    // Get distances
    Change := False;
    // Try to find better point
    for I := Low(Points) to High(Points) do
    begin
      // Check if point is already selected
      PointSelected := False;
      for K := Low(LocIdx) to High(LocIdx) do
        if (I = LocIdx[K]) then
        begin
          PointSelected := True;
          break;
        end;
      if PointSelected then
        continue;
      // Try to replace the point
      for RemIdx := Low(LocIdx) to High(LocIdx) do
      begin
        // Compute the new best distances
        distNew := 1e10;
        distOld := 1e10;
        for K := Low(LocIdx) to High(LocIdx) do
          if (K <> RemIdx) then
          begin
            distNew := Min(distNew, Distances[LocIdx[K],I]);
            distOld := Min(distOld, Distances[LocIdx[K],LocIdx[RemIdx]]);
          end;
        if (distNew > distOld) then
        begin
          Change := True;
          LocIdx[RemIdx] := I;
          break;
        end;
      end;
    end;
  until not Change OR (overflow > 10000);

  // Convert locs to real coords
  for I := Low(LocIdx) to High(LocIdx) do
    Locs[I] := KMPointAdd(Minimum,Points[ LocIdx[I] ]);
  end;

  // Get locs from center screen position
  procedure CenterScreen(var aLocs: TKMPointArray);
  var
    I, idx: Integer;
  begin
    idx := 0;
    SetLength(aLocs, gHands.Count);
    for I := 0 to gHands.Count-1 do
      if gHands[I].Enabled  AND not ((gHands[I].CenterScreen.X = (fMapX div 2)) AND (gHands[I].CenterScreen.Y = (fMapY div 2))) then
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
  EDGE_DIST = 0.08; // in %, must be > 0 !!!
begin
  SetLength(Output, RMGSettings.Locs.Players);

  MinOffset.X := Max(1, Round(fMapX * EDGE_DIST));
  MinOffset.Y := Max(1, Round(fMapY * EDGE_DIST));
  MaxOffset.X := Min(fMapX - 1, fMapX - MinOffset.X);
  MaxOffset.Y := Min(fMapY - 1, fMapY - MinOffset.Y);

  case RMGSettings.Locs.Layout of
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
// aSpace = minimal space between generated points (points will be in grid if it is equal to infinity)
// aMinimum, aMaximum = point will be generated in rectangle given by this points
// Result = TKMPointArray of pseudorandom points
function TKMRandomMapGenerator.RNDPointsInGrid(const aCnt: Single; aSpace: Integer; const aMinimum,aMaximum: TKMPoint): TKMPointArray;
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


// Generator of random points inside circle
function TKMRandomMapGenerator.RNDPointInCircle(aMin,aMax,aCenter: TKMPoint; aMaxRadius: Single): TKMPoint;
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
			  if (Shape2Arr[Y,X] = -1) OR (Shape2Arr[Y,X] = -2) then
        begin
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
// Note: add elements into class fRes: TBalancedResource1Array
//   = array of shapes which represents resources (each shape have its own count of resources and points which were get from Voronoi diagram)
//     Cellular automaton can change shapes so it is important to keep more points to secure that every shape will have its resources in GenerateTiles
procedure TKMRandomMapGenerator.CreateResources(var aLocs: TKMPointArray; var A: TKMByte2Array);
const
  RESOURCES: array[0..4] of TBiomeType = (btIron,btGold,btStone,btCoal,btCoal);
  BASE_RES_RADIUS: array[0..4] of Single = (1.5,1.5,0.5,2,2);
  VORONOI_STEP = 3;
  RES_PROB: array[0..4] of Single = (0.000001,0.000001,0.1,0.08,0.08); // Probability penalization (only afect final shape: 0 = circle, 1 = multiple separated mountains)
  //SPEC_RES_RADIUS: array[0..4] of Byte = (5, 5, 5, 5, 5); // Iron, Gold, Stone, Coal, Coal
  RES_AMOUNT: array[0..4] of Integer = (1, 1, 1, 2, 1);
  RES_TILES_AMOUNT: array[0..4] of Single = (0.2, 0.2, 0.066, 0.27,0.30);
  RES_MINES_CNT: array[0..4] of Single = (0.005, 0.01, 1.0, 1.0, 1.0);

  // Find best place for resources (scan area around and find empy space)
  function FindBestResLoc(const aIgnoreNegativeValues: Boolean; const aRADIUS: Single; aMin,aMax,aCenter: TKMPoint; var aCountArr: TInteger2Array; var aResLoc: TKMPoint): Boolean;
  const
    RESRAD = 2;
    BREAK_LIMIT = 20;
    INC_RADIUS = 0.4;
    MAX_RADIUS = 30;
  var
    I,X,Y, BestResCnt, ResCnt: Integer;
    ResPoint: TKMPoint;
  begin
    Result := False;
    if (aRadius > MAX_RADIUS) then
      Exit;
    aResLoc := KMPOINT_ZERO;
    BestResCnt := 0;
    for I := 0 to 20 do
    begin
      ResCnt := 0;
      ResPoint := RNDPointInCircle(aMin,aMax,aCenter, aRADIUS);
      if (aIgnoreNegativeValues AND (aCountArr[ResPoint.Y,ResPoint.X] > 0))
        OR (not aIgnoreNegativeValues AND (aCountArr[ResPoint.Y,ResPoint.X] <> 0)) then
        for Y := Max(Low(aCountArr), ResPoint.Y-RESRAD) to Min(High(aCountArr), ResPoint.Y+RESRAD) do
        for X := Max(Low(aCountArr[Y]), ResPoint.X-RESRAD) to Min(High(aCountArr[Y]), ResPoint.X+RESRAD) do
          if (aIgnoreNegativeValues AND (aCountArr[Y,X] > 0))
            OR (not aIgnoreNegativeValues AND (aCountArr[Y,X] <> 0)) then
            ResCnt := ResCnt + 1;
      if (BestResCnt < ResCnt) then
      begin
        BestResCnt := ResCnt;
        aResLoc := ResPoint;
      end;
      if (BestResCnt >= BREAK_LIMIT) then
        break;
    end;
    if KMSamePoint(aResLoc, KMPOINT_ZERO) then
    begin
      aMin := KMPoint(   Max(  1, Round( aMin.X*(1.0-INC_RADIUS) )  ), Max(  1, Round( aMin.Y*(1.0-INC_RADIUS) )  )   );
      aMax := KMPoint(   Min(  High(aCountArr[0]), Round( aMax.X*(1.0+INC_RADIUS) )  ), Min(  High(aCountArr), Round( aMax.Y*(1.0+INC_RADIUS) )  )   );
      Result := FindBestResLoc(aIgnoreNegativeValues, aRADIUS*(1.0+INC_RADIUS), aMin,aMax,aCenter, aCountArr, aResLoc)
    end
    else
      Result := True;
  end;

  // Determine size of mountain to be sure that there will be possible to place specific number of mines
  procedure SetSizeOfMountain(aInitPoint: TKMPoint; var aReqSize, aNewSize: Integer; var aCountArr: TInteger2Array; var aPointsArr: TKMPoint2Array; var aPointArr: TKMPointArray);
  var
    Left, Right: Boolean;
    I,X,Y, cnt, elements: Integer;
  begin
    SetLength(aPointArr, Ceil(aReqSize / (VORONOI_STEP*1.0))+10);
    Left := True;
    Right := True;
    X := aInitPoint.X;
    Y := aInitPoint.Y;
    cnt := 1;
    elements := 1;
    aPointArr[0] := KMPoint(X,Y);
    for I := 1 to aReqSize do
    begin
      if (cnt >= aReqSize) then
            break;
      if Right AND (X+I <= High(aCountArr[Y])) AND (aCountArr[Y,X+I] > 0) then
      begin
        aPointArr[elements] := KMPoint(X+I,Y);
        cnt := cnt - aPointsArr[Y,X+I-1].X + aPointsArr[Y,X+I].X;
        elements := elements + 1;
      end
      else
        Right := False;
      if (cnt >= aReqSize) then
        break;
      if Left AND (X-I >= Low(aCountArr[Y])) AND (aCountArr[Y,X-I] > 0) then
      begin
        aPointArr[elements] := KMPoint(X-I,Y);
        cnt := cnt + aPointsArr[Y,X-I+1].X - aPointsArr[Y,X-I].X;
        elements := elements + 1;
      end
      else
        Left := False;
    end;
    aNewSize := Max(0, aReqSize - cnt);
    SetLength(aPointArr, elements);
  end;

  // Mark map edges to negative counts = it prevents placing resources here
  procedure MarkEdges(var aCountArr: TInteger2Array);
  const
    DIST_FROM_BOTTOM = 1; // Iron, Gold and Stone mines will be placed max in distance [DIST_FROM_BOTTOM] of Voronoi steps from bottom of the map
  var
    X,Y,XMin,YMin,XMax,YMax: Integer;
  begin
    YMin := Low(aCountArr);
    YMax := High(aCountArr);
    XMin := Low(aCountArr[YMin]);
    XMax := High(aCountArr[YMin]);
    // Distance from bottom
    for Y := Max(YMax-DIST_FROM_BOTTOM, YMin) to YMax do
      for X := XMin to XMax do
        aCountArr[Y,X] := -aCountArr[Y,X];
    // 1 shape from map sides
    for Y := YMin to Max(YMax-DIST_FROM_BOTTOM-1, YMin) do
    begin
      aCountArr[Y,XMin] := -aCountArr[Y,XMin];
      aCountArr[Y,XMax] := -aCountArr[Y,XMax];
    end;
    for X := XMin to XMax do
      aCountArr[YMin,X] := -aCountArr[YMin,X];
  end;

  // Create protected belt around resources so obstacles will not be here
  procedure ProtectResourceArea(var aCountArr: TInteger2Array);
  const
    X_RANGE = 1;
    Y_RANGE_1 = 1;
    Y_RANGE_2 = 1;
  var
    Check: Boolean;
    X,Y,X2,Y2: Integer;
  begin
    for Y := High(aCountArr) downto Low(aCountArr) do
      for X := Low(aCountArr[Y]) to High(aCountArr[Y]) do
        if (aCountArr[Y,X] < 0) then
        begin
          Check := False;
          for Y2 := Max( Low(aCountArr),Y-Y_RANGE_1 ) to Max( Low(aCountArr),Y-Y_RANGE_2 ) do
            for X2 := Max( Low(aCountArr[Y2]),X-X_RANGE ) to Min( High(aCountArr[Y2]),X+X_RANGE ) do
              if (aCountArr[Y2,X2] = 0) then
              begin
                Check := True;
                break;
              end;
          if Check then
            aCountArr[Y,X] := 0;
        end;
  end;

var
  X,Y,Loc,I,K,overflow, ALL_RES_RADIUS, cntFINAL, cntACTUAL, cntPREVIOUS, cntREQUESTED, RESOURCE, sizeMountain, newSize: Integer;
  PROB_REDUCER, Fraction: Single;
  TP_S,TP_E, ResLoc: TKMPoint;
  Voronoi,CountArr: TInteger2Array;
  ResSettings: TIntegerArray;
  ResAmount, ResTilesAmount, MinesCnt: array[0..4] of Integer; // Amount of tiles of specific resources
  Locs, PointArr, ResPoints: TKMPointArray;
  PointsArr: TKMPoint2Array;
  SearchResource: TKMSearchBiome;
  FillResource: TKMFloodWithQueue;
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
      ResAmount[I] := ResSettings[I] * RES_AMOUNT[I];
      ResTilesAmount[I] := Trunc(ResAmount[I] * RES_TILES_AMOUNT[I]);
      if (I < 2) then // Only Iron and Gold
        MinesCnt[I] := Ceil(ResAmount[I] * RES_MINES_CNT[I])
      else
        MinesCnt[I] := 0;
    end;
    ALL_RES_RADIUS := Round(((ResAmount[1]*3 + ResAmount[2]*2 + ResAmount[3]) shr 1) / VORONOI_STEP);
    //CENTER_RES := Round(ALL_RES_RADIUS / 2);
  end;

  // Resources
  //{
  if RMGSettings.Locs.Resource.Active then
  begin
    // Avoid to build resources in edges of the map (except coal = count is negative)
    MarkEdges(CountArr);
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
          RESOURCE := Byte(RESOURCES[I]);
          PROB_REDUCER := RES_PROB[I];
          if (RESOURCES[I] = btIron) OR (RESOURCES[I] = btGold) then
            //sizeMountain := Ceil((MinesCnt[I]*(3+Byte(RESOURCES[I] = btIron))+1) / (VORONOI_STEP*1.0))
            sizeMountain := Ceil(MinesCnt[I]*(3+Byte(RESOURCES[I] = btIron))+1)
          else
            sizeMountain := 1;
          cntFINAL := ResTilesAmount[I];
          cntACTUAL := 0;
          cntREQUESTED := 0;
          cntPREVIOUS := 0;
          overflow := 0;
          // Create new "mountain" of resources
          while (cntACTUAL < cntFINAL) AND (overflow < 10) do
          begin
            overflow := overflow + 1;
            // Try find unused shape
            if not FindBestResLoc((RESOURCE <> Byte(btCoal)), BASE_RES_RADIUS[I] * RMGSettings.Locs.ProtectedRadius, TP_S,TP_E,Locs[Loc], CountArr, ResLoc) then
              break;
            // Check if there is enought points to create mountains with specific size
            SetSizeOfMountain(ResLoc, sizeMountain, newSize, CountArr, PointsArr, PointArr);
            // Merge shapes from Voronoi until we reach desired size
            if (RESOURCES[I] = btIron) OR (RESOURCES[I] = btGold) then
              cntREQUESTED := Round(   (cntFINAL - cntACTUAL) * Max(  1.0, newSize / ( Max(1.0,sizeMountain*1.0) )  )   )
            else
              cntREQUESTED := cntFINAL;
            ResPoints := nil;
            //SetLength(ResPoints, 0);
            FillResource.FloodFillWithQueue(PointArr, cntREQUESTED, cntACTUAL, RESOURCE, 1, PROB_REDUCER, ResPoints);
            // Actualize shape
            Fraction := (Min(cntFINAL, cntACTUAL) - cntPREVIOUS) / Max(1,cntFINAL);
            fRes.AddResource( Loc, RESOURCE, Round( Fraction * MinesCnt[I] ), // Owner, Resource, MinesCnt
                              Round( Fraction * ResAmount[I] ), // Quantity
                              ResPoints // Centers of Voronoi shapes
                            );
            cntPREVIOUS := cntACTUAL;
            sizeMountain := newSize + 1; // Size of requested mines + edge (= 1)
          end;
        end;
      end;
    finally
      FillResource.Free;
    end;

    ProtectResourceArea(CountArr);
  end;
  //}

  if RMGSettings.Obstacle.Active then
    CreateObstacles(Locs, A,  Voronoi, CountArr, PointsArr);

end;
//}



// Create obstacles (eIron, eGold, watter, swamp and wetland) - obstacles are created via seeds and array of probabilities it is basicaly RANDOM WALK in probability array
// aLocs = expected player's position (those will have protected radius to secure that player have place for city)
// A = TKMByte2Array for obstacles
// aVoronoi = Voronoi diagram (same diagram for resource generator and for obstacle generator => avoid to replace resources with obstacles)
// aPointsArr = points of Voronoi diagram (easy way how to find each shape)
procedure TKMRandomMapGenerator.CreateObstacles(var aLocs: TKMPointArray; var A: TKMByte2Array; var aVoronoi, aCountArr: TInteger2Array; var aPointsArr: TKMPoint2Array);
const
  OBST2BIOME: array[TObstacleType] of TBiomeType = (btSwamp,btWater,btWetland,btEgold,btEIron);
var
  FillObstacle: TKMFillBiome;
  P: TSingle2Array;

// Connect points with zero chance to create obstacles = secure that player in loc X can walk to player with loc Y
  function LinearConnection(Probability: Single; FinP,StartP: TKMPoint): Boolean;
  var
    Owerflow: Integer;
    Vector, ActP: TKMPoint;
  begin
    Result := False;
    // Create vector in direction of second point (connected route will not be completely linear but in "L" shape)
    Vector.X := Byte(FinP.X > StartP.X) - Byte(FinP.X < StartP.X); // = 1 in firs case; -1 in second case; 0 otherwise
    Vector.Y := Byte(FinP.Y > StartP.Y) - Byte(FinP.Y < StartP.Y);
    //  Make route to final point or another route
    ActP := StartP;
    Owerflow := 0;
    while ( (Owerflow < 500) AND (not Result) AND ((FinP.X <> ActP.X) OR (FinP.Y <> ActP.Y)) ) do
    begin
      Owerflow := Owerflow + 1;
      // Actualize current point
      if (FinP.X <> ActP.X) then ActP.X := ActP.X + Vector.X;
      if (FinP.Y <> ActP.Y) then ActP.Y := ActP.Y + Vector.Y;
      // If we detect zero chance (or almost zero) we reached existing connection and algoritm may end
      if (P[ ActP.Y,ActP.X ] < Probability) then
        Result := True;
      // Mark zero probability
      P[ActP.Y,ActP.X] := Probability;
      // Mark surrounding Voronoi shapes with 0 probability too
      // (CA may connect some inacessible texture and break walkable network so better make this area bigger)
      if ((ActP.Y-Vector.Y) >= Low(P)) AND ((ActP.Y-Vector.Y) <= High(P)) then
      begin
        P[ActP.Y-Vector.Y,ActP.X] := Probability;
        if ((ActP.X-Vector.X) >= Low(P[0])) AND ((ActP.X-Vector.X) <= High(P[0])) then
        begin
          P[ActP.Y,ActP.X-Vector.X] := Probability;
          P[ActP.Y-Vector.Y,ActP.X-Vector.X] := Probability;
        end;
      end
      else if ((ActP.X-Vector.X) >= Low(P[0])) AND ((ActP.X-Vector.X) <= High(P[0])) then
        P[ActP.Y,ActP.X-Vector.X] := Probability;
    end;
  end;

// Linear connection is too ugly -> generate several random points in map and create linear connection between those points and player Loc
  procedure ConnectLocs(aLocs: TKMPointArray);
  const
    POINT_RADIUS = 10;
    MAX_ATTEMPTS = 15;
    POBABILITY_ADD = 0.000001; // We just need quick way how to distinguish each for cycle
  var
    Connected: Boolean;
    I, HighIdx, idx, Overflow, BestDistance, Distance: Integer;
    Probability: Single;
    Loc, StartLoc, NewPoint, BestPoint, MinLimit, MaxLimit: TKMPoint;
    Locs: TKMPointArray;
  begin
    // Just to be sure copy locs
    SetLength(Locs, Length(aLocs));
    for HighIdx := Low(Locs) to High(Locs) do
      Locs[HighIdx] := aLocs[HighIdx];
    MinLimit := KMPoint( Low(P[0]), Low(P) );
    MaxLimit := KMPoint( High(P[0]), High(P) );
    Probability := 0;
    for HighIdx := High(Locs)-1 downto Low(Locs) do
    begin
      // Randomly pick 1 loc
      idx := fRNG.RandomI(HighIdx);
      // Get randomly picked loc to the end of the array (in actual index: untouched points ... new point, previous point, ... old points)
      Loc := Locs[HighIdx+1]; // Previous point
      StartLoc := Locs[idx]; // Target point
      Locs[idx] := Locs[HighIdx];
      Locs[HighIdx] := StartLoc;

      // Connect locs with non-linear road
      Connected := False;
      Overflow := 0;
      while not Connected AND (Overflow < 100) do
      begin
        Overflow := Overflow + 1;
        BestDistance := KMDistanceAbs(StartLoc, Loc);
        BestPoint := StartLoc;
        for I := 0 to MAX_ATTEMPTS do
        begin
          NewPoint := RNDPointInCircle(MinLimit,MaxLimit,StartLoc, POINT_RADIUS);
          Distance := KMDistanceAbs(NewPoint, Loc);
          if (BestDistance > Distance) then
          begin
            BestDistance := Distance;
            BestPoint := NewPoint;
          end;
        end;
        Connected := LinearConnection(Probability, StartLoc,BestPoint) OR KMSamePoint(StartLoc, Loc);
        StartLoc := BestPoint;
      end;

      Probability := Probability + POBABILITY_ADD;
    end;
  end;

  procedure RndPointsInRadius(aObstacle: TObstacleType; aX,aY: Integer);
  const
    ADAPTIVE_RADIUS: array[TObstacleType] of Single = (0.6,0.5,0.8,0.5,0.5); //(otSwamp,otWater,otWetland,otEgold,otEIron);
  var
    X,Y, Cnt, MaxCnt, Overflow, MaxAttempt: Integer;
    Radius, RandomSize: Single;
    Point, MaxP, MinP: TKMPoint;
  begin
    MinP := KMPoint(Low(aPointsArr[0]), Low(aPointsArr));
    MaxP := KMPoint(High(aPointsArr[0]), High(aPointsArr));
    RandomSize := 1 - fRNG.Random() * RMGSettings.Obstacle.Variance * 0.1;
    MaxCnt := Max(1, Round( RMGSettings.Obstacle.Size * RandomSize) );
    Radius := Max(1, Round(sqrt(MaxCnt)) * ADAPTIVE_RADIUS[aObstacle] );
    MaxAttempt := MaxCnt * 5;
    Overflow := 0;
    Cnt := 0;
    while (Cnt < MaxCnt) AND (Overflow < MaxAttempt) do
    begin
      Overflow := Overflow + 1;
      Point := RNDPointInCircle(MinP,MaxP,KMPoint(aX,aY),Radius);
      if (fRNG.Random() < P[Point.Y,Point.X]) AND (aVoronoi[Point.Y,Point.X] <> 0) then
      begin
        X := aPointsArr[ Point.Y, Point.X ].X;
        Y := aPointsArr[ Point.Y, Point.X ].Y;
        FillObstacle.QuickFlood(X, Y, aVoronoi[Y,X], 0, Byte(OBST2BIOME[aObstacle]));
        Cnt := Cnt + 1;
      end;
    end;
  end;

  procedure RndWalk(aObstacle: TObstacleType; aX,aY: Integer);
  const
    EXPAND_RESTRICTION: array[TObstacleType] of Byte = (3,1,2,4,4);
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
    finalCnt := Max(1,Round((1 - fRNG.Random() * RMGSettings.Obstacle.Variance * 0.1) * (RMGSettings.Obstacle.Size)));
    if (otWater = aObstacle) then
      finalCnt := Round(finalCnt*1.5);
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
      for K := 1 to Min(MaxCnt, fRNG.RandomI(EXPAND_RESTRICTION[aObstacle]) + 1) do
      begin
        MaxIdx := fRNG.RandomI(MaxCnt);
        if (fRNG.Random < Prob[ ProbIdx[MaxIdx] ]) then
        begin
          X1 := aPointsArr[  Dir[ ProbIdx[MaxIdx] ].Y, Dir[ ProbIdx[MaxIdx] ].X  ].X;
          Y1 := aPointsArr[  Dir[ ProbIdx[MaxIdx] ].Y, Dir[ ProbIdx[MaxIdx] ].X  ].Y;
          if (aVoronoi[Y1,X1] <> 0) then
            FillObstacle.QuickFlood(X1, Y1, aVoronoi[Y1,X1], 0, Byte(OBST2BIOME[aObstacle]));
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

  var
    X,Y,I, MaxCnt: Integer;
    Factor,Probability, ProbabilityReducer, ProbabilityOffset: Single;
    MinP, MaxP: TKMPoint;
    Obstacle: TObstacleType;
    ObstacleSeeds: TKMPointArray;
    VisitedArr: TKMByte2Array;
    ShapeFixer: TKMSharpShapeFixer;
    OBST_Probability: array[TObstacleType] of Single;
begin

// Initialization
  SetLength(P, Length(aPointsArr), Length(aPointsArr[Low(aPointsArr)]));
  for Y := Low(aPointsArr) to High(aPointsArr) do
    for X := Low(aPointsArr[Y]) to High(aPointsArr[Y]) do
      P[Y,X] := 1;

// Create protected radius = array with smaller chance to spawn obstacle near aLocs
  if RMGSettings.Locs.Resource.Active then
  begin
    ProbabilityReducer := sqrt(11 - RMGSettings.Locs.ProtectedRadius) * 0.05;
    ProbabilityOffset := RMGSettings.Locs.ProtectedRadius * 1.5;
    MaxCnt := Round(1 / ProbabilityReducer);
    if RMGSettings.Locs.Resource.ConnectLocs then
      ConnectLocs(aLocs);
    for I := Low(aLocs) to High(aLocs) do
      for Y := Max(  Low(P), aLocs[I].Y - MaxCnt  ) to Min(  High(P), aLocs[I].Y + MaxCnt  ) do
        for X := Max(  Low(P[Y]), aLocs[I].X - MaxCnt  ) to Min(  High(P[Y]), aLocs[I].X + MaxCnt  ) do
        begin
          Probability := Max(0, (KMLengthDiag(X,Y,aLocs[I]) - ProbabilityOffset) * ProbabilityReducer );
          if (P[Y,X] > Probability) then
            P[Y,X] := Probability;
        end;
    // Set zero probability for shapes which are used by resources and protected radius around them
    for Y := Low(P) to High(P) do
      for X := Low(P[Y]) to High(P[Y]) do
        if (aCountArr[Y,X] = 0) then
          P[Y,X] := 0;
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
  Factor := fMapX * fMapY * RMGSettings.Obstacle.Density / 5000;
  MinP := KMPoint(Low(P[0]), Low(P));
  MaxP := KMPoint(High(P[0]), High(P));
  ObstacleSeeds := RNDPointsInGrid(Max(1,Round(Factor)), 0, MinP, MaxP);
  MinP := KMPoint(Low(A[0]), Low(A));
  MaxP := KMPoint(High(A[0]), High(A));
  FillObstacle := TKMFillBiome.Create( MinP, MaxP, aVoronoi, A);
  try
    for I := Low(ObstacleSeeds) to High(ObstacleSeeds) do
    begin
      // Get seed and obstacle biome
      X := ObstacleSeeds[I].X;
      Y := ObstacleSeeds[I].Y;
      Probability := fRNG.Random();
      for Obstacle := Low(TObstacleType) to High(TObstacleType) do
        if (Probability < OBST_Probability[Obstacle]) then
          break;

      case Obstacle of
        otSwamp, otWetland: RndPointsInRadius(Obstacle, X,Y);
        otWater, otEgold, otEIron: RndWalk(Obstacle, X,Y);
        else begin end;
      end;
    end;
  finally
    FillObstacle.Free;
  end;

  // Fix ugly mountains edges (edges with 1 or 2 tiles - 1 tiles will be fixed by CA but still 2xN tiles are ugly)
  SetLength(VisitedArr, Length(A), Length(A[0]));
  for Y := Low(VisitedArr) to High(VisitedArr) do
    for X := Low(VisitedArr[Y]) to High(VisitedArr[Y]) do
      VisitedArr[Y,X] := 0;
  ShapeFixer := TKMSharpShapeFixer.Create( MinP, MaxP, A, VisitedArr );
  try
    for Y := Low(VisitedArr) to High(VisitedArr) do
      for X := Low(VisitedArr[Y]) to High(VisitedArr[Y]) do
        if (VisitedArr[Y,X] = 0) AND (A[Y,X] >= Byte(btStone)) then
          ShapeFixer.QuickFlood( X,Y, A[Y,X], 1 );
  finally
    ShapeFixer.Free;
  end;
end;





// Fixer of mountains with iron or gold to be able to place mines there
procedure TKMRandomMapGenerator.MineFix(var A: TKMByte2Array);
type
  TLimitShape = record
    Active: Boolean;
    Min,Max: SmallInt;
  end;
var
  Shape: array of TLimitShape;
// Search maximal and minimal values of each column in shape
  //procedure MinerFixFloodSearch(const Resource: Byte; const Y,X: Integer; var aVisited: TBoolean2Array);
  //begin
  //  if not aVisited[Y,X] AND (A[Y,X] = Resource) then
  //  begin
  //    aVisited[Y,X] := True;
  //    Shape[X].Active := True;
  //    if (Y >= Shape[X].Max) then
  //    begin
  //      Shape[X].Max := Y;
  //      if (A[Y+1,X] <> Resource) AND (A[Y+1,X] <> Byte(btCoal)) then
  //        A[Y+1,X] := 0;
  //    end;
  //    if (Y < Shape[X].Min) then
  //      Shape[X].Min := Y;
  //
  //    if (Y < fMapY-1) then MinerFixFloodSearch(Resource, Y+1,X, aVisited);
  //    if (Y > 1)               then MinerFixFloodSearch(Resource, Y-1,X, aVisited);
  //    if (X < fMapX-1) then MinerFixFloodSearch(Resource, Y,X+1, aVisited);
  //    if (X > 1)               then MinerFixFloodSearch(Resource, Y,X-1, aVisited);
  //  end;
  //end;

  procedure Fixer(MINESIZE, Resource, MineCnt: Byte; aPosition: TKMPoint; var aVisited: TBoolean2Array);
  var
    X,Y,X1,X2,maxY,minX,maxX,MinMineSize, minVal, maxIndex, startIndex, actVal, MaxPosIdx: Integer;
    X_RESERVE, X_FLOAT: Single;
    MinLimit, MaxLimit: TSmallIntArray;
    MineSearch: TKMMinerFixSearch;
  begin
    if (MineCnt < 1) then
      Exit;
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
    MineSearch := TKMMinerFixSearch.Create(  KMPoint(  Low(A[0]), Low(A) ), KMPoint( High(A[0]), High(A) ), MinLimit, MaxLimit, aVisited, A  );
    try
      MineSearch.QuickFlood(aPosition.X,aPosition.Y,Resource);
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

  // Find start index of shape
    X := 0;
    while not Shape[X].Active AND (X < High(Shape)) do
      X := X+1;
    minX := X;
    while Shape[X].Active AND (X < High(Shape)) do
      X := X+1;
    maxX := X-1;

  // Change shape to be able to mine resources here
    MinMineSize := MINESIZE + 1;
    X_RESERVE := (maxX - minX) / (MineCnt*1.0) - MinMineSize;
    X := minX;
    X_FLOAT := MinX;
    MaxPosIdx := 0;
    startIndex := 0;
    while (X+MinMineSize <= MaxX) do
    begin
      minVal := High(Integer);
      maxIndex := High(A);
    // Scan last interval of tiles and find best spot for fix
      for X1 := X to Max(X,Round(X_FLOAT+X_RESERVE)) do
      begin
      // Find a southernmost point in minimal interval of possible mine
        maxY := 0;
        for X2 := X1+1 to Min(maxX,X1+MINESIZE) do // We need to focus only on balancing of 2 or 3 tiles where will be mine (edge tiles may be higher but we dont care)
          if (Shape[X2].Max > maxY) then
          begin
            maxY := Shape[X2].Max;
            MaxPosIdx := X2;
          end;
      // Calculate the price of transformation which secure place mine (price = penalization of deleted tiles)
        actVal := 0;
        for X2 := X1 to Min(maxX,X1+MINESIZE) do
          actVal := actVal + Max(0, maxY - Shape[X2].Max); // Edges of potential mine tiles may be higher but it is fine
      // Save best solution (closer to right is better)
        if (actVal < minVal) then
        begin
          minVal := actVal;
          maxIndex := MaxPosIdx;
          startIndex := X1;
        end;
      end;
    // Apply changes
      maxY := Shape[maxIndex].Max;
      for X1 := startIndex to startIndex + MinMineSize do
      begin
        Y := Shape[X1].Max;
        while (Y <= maxY) AND (Y < High(A)) do
        begin
          Shape[X1].Max := Shape[X1].Max + 1;
          A[Y,X1] := Resource;
          aVisited[Y,X1] := True;
          Y := Y + 1;
        end;
      end;
      X_FLOAT := X_FLOAT + X_RESERVE + MinMineSize;
      X := Round(X_FLOAT);
    end;
  end;

var
  RESOURCE: Byte;
  I, K: Integer;
  Visited: TBoolean2Array;
  Resources: TBalancedResource1Array;
begin
  SetLength(Visited, fMapY+1, fMapX+1);
  for I := Low(Visited) to High(Visited) do
    for K := Low(Visited[I]) to High(Visited[I]) do
      Visited[I,K] := False;

  Resources := fRes.Resources;
  for I := 0 to fRes.Count - 1 do
  begin
    if (Resources[I].Resource = Byte(btGold)) then
      RESOURCE := 2
    else if (Resources[I].Resource = Byte(btIron)) then
      RESOURCE := 3
    else // Coal and Stone are always fine
      continue;
    for K := Low(Resources[I].Points) to High(Resources[I].Points) do
      if not Visited[ Resources[I].Points[K].Y, Resources[I].Points[K].X ]
         AND (A[ Resources[I].Points[K].Y, Resources[I].Points[K].X ] = Resources[I].Resource) then
        Fixer(RESOURCE, Resources[I].Resource, Resources[I].MinesCnt, Resources[I].Points[K], Visited);
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
  //    ___________________________                          _________
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
      while (X1 < High(A[Y1])-2) do
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
  TerrainPreference: array[0..len_BIOME-1,0..4] of Byte = (
    (  0,  1, 14,255,255), //  0 btGrass
    (  0,  1, 14,255,255), //  1 btBigGrass
    (  2,  3,  4,  0,255), //  2 btWetland
    (  2,  3,  4,  0,255), //  3 btSwamp
    (  2, 19, 20, 21, 22), //  4 btWater
    (  5,  6,  7,  8,255), //  5 btCoal
    (  5,  6,  7,  8,255), //  6 btGrassGround
    (  5,  6,  7,  8,255), //  7 btGround
    (  6,  7,  0,  1,255), //  8 btTreeGrass
    (  5,  6,  7,255,255), //  9 btGroundSnow
    (  9, 10, 11,255,255), // 10 btSnow1
    (  9, 10, 11,255,255), // 11 btSnow2
    (  4,255,255,255,255), // 12 btIce
    ( 13, 15, 16, 17,255), // 13 btCoastSand
    (  0,  1,  8, 14,255), // 14 btGrassSand1
    ( 13, 15, 16, 17,255), // 15 btGrassSand2
    ( 13, 15, 16, 17,255), // 16 btGrassSand3
    ( 13, 15, 16, 17,255), // 17 btSand
    (  0,255,255,255,255), // 18 btStone
    ( 19, 20,255,255,255), // 19 btGold
    ( 19, 20,255,255,255), // 20 btEgold
    ( 21, 22,255,255,255), // 21 btIron
    ( 21, 22,255,255,255), // 22 btEIron
    ( 22, 20,255,255,255)  // 23 btDark
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
	for Y1 := 1 to fMapY-1 do
  begin
    Y0 := Y1 - 1;
		for X1 := 1 to fMapX-1 do
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
  for Y1 := 1 to fMapY-1 do
  begin
    Y := Y1 shl 1;
    Y0 := Y1 - 1;
    Y2 := Y1 + 1;
    for X1 := 1 to fMapX-1 do
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
      // Note: conditions are for special transitions between iron and gold mountains
        // Left Top Right %0111
        7: begin
          if (B[Y1,X1,1,1] <= Byte(btStone)) OR (B[Y1,X1,1,1] = Byte(btDark)) then
            begin LT := B[Y1,X1,1,1]; RT := B[Y1,X1,1,1]; RD := B[Y1,X1,2,1]; LD := B[Y1,X1,2,1]; end else
            begin LT := B[Y1,X1,1,1]; RT := B[Y1,X1,1,1]; RD := B[Y1,X1,2,2]; LD := B[Y1,X1,2,0]; end;
        end;
        // Left Down Right %1101
       13: begin
         if (B[Y1,X1,1,1] <= Byte(btStone)) OR (B[Y1,X1,1,1] = Byte(btDark)) then
           begin LT := B[Y1,X1,0,1]; RT := B[Y1,X1,0,1]; RD := B[Y1,X1,1,1]; LD := B[Y1,X1,1,1]; end else
           begin LT := B[Y1,X1,0,0]; RT := B[Y1,X1,0,2]; RD := B[Y1,X1,1,1]; LD := B[Y1,X1,1,1]; end;
       end;
        // Top Right Down %1110
       14: begin
         if (B[Y1,X1,1,1] <= Byte(btStone)) OR (B[Y1,X1,1,1] = Byte(btDark)) then
           begin LT := B[Y1,X1,1,0]; RT := B[Y1,X1,1,1]; RD := B[Y1,X1,1,1]; LD := B[Y1,X1,1,0]; end else
           begin LT := B[Y1,X1,0,0]; RT := B[Y1,X1,1,1]; RD := B[Y1,X1,1,1]; LD := B[Y1,X1,2,0]; end;
       end;
        // Top Left Down %1011
       11: begin
         if (B[Y1,X1,1,1] <= Byte(btStone)) OR (B[Y1,X1,1,1] = Byte(btDark)) then
           begin LT := B[Y1,X1,1,1]; RT := B[Y1,X1,1,2]; RD := B[Y1,X1,1,2]; LD := B[Y1,X1,1,1]; end else
           begin LT := B[Y1,X1,1,1]; RT := B[Y1,X1,0,2]; RD := B[Y1,X1,2,2]; LD := B[Y1,X1,1,1]; end;
        end;
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

// Advanced detection (when we cannot draw tile try another logic with 2x2 array which represents each tile)
//{
  for Y := 1 to fMapY-1 do
  begin
    Y1 := Y shl 1;
    Y2 := Y1 + 1;
  	for X := 1 to fMapX-1 do
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
    IronMix: array[0..2] of TBiomeType = (btGroundSnow, btSnow1, btDark);
    GoldMix: array[0..2] of TBiomeType = (btGroundSnow, btSnow1, btDark);
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
    for Y := 1 to fMapY-1 do
    for X := 1 to fMapX-1 do
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
procedure TKMRandomMapGenerator.NoGoZones(var Locs: TKMPointArray; var TilesPartsArr: TTileParts);
var
  Y1,X1,Y0,Y2,X0,X2, i, step: Integer;
  PathArr: TInteger2Array;
  FillObject: TKMFillObject;
begin
  SetLength(PathArr, fMapY, fMapX);
  for Y1 := Low(PathArr) to High(PathArr) do
  	for X1 := High(PathArr[Y1]) to High(PathArr[Y1]) do
  		PathArr[Y1,X1] := 0;

  // Walk from Locs everywhere (if it is possible)
  FillObject := TKMFillObject.Create(KMPoint(1,1), KMPoint(fMapX-1, fMapY-1), PathArr, TilesPartsArr.Obj, TilesPartsArr.Terrain, False);
  try
    for i := Low(Locs) to High(Locs) do
    begin
      step := 1;
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
        FillObject.QuickFlood(X1, Y1, 0, 1, OBJ_NONE);
    end;

    // Now find accessible tiles which are not visited and replace object
    for Y1 := 1 to fMapY-1 do
      for X1 := 1 to fMapX-1 do
        if (PathArr[Y1,X1] = 0) AND WT[ TilesPartsArr.Terrain[Y1,X1] ] then
          FillObject.QuickFlood(X1, Y1, 0, 1, OBJ_BLOCK);
  finally
    FillObject.Free;
  end;
end;



// Converts biomes into numbers which represents specific tiles with right direction and nice variance, it also make balanced resources
// Resources = array of balanced resources request
// TilesPartsArr = tiles composition array
// A = array of biomes
// B = array of biome-decomposition
procedure TKMRandomMapGenerator.GenerateTiles(var TilesPartsArr: TTileParts; var A: TKMByte2Array; var B: TKMByte2Array);
const
  TT: array[0..len_BIOME-1,0..len_BIOME-1,0..5] of Word = ( // Textures of transitions + direction set
                          {btGrass}            {btBigGrass}          {btWetland}           {btSwamp}            {btWater}            {btCoal}         {btGrassGround}         {btGround}          {btTreeGrass}       {btGroundSnow}         {btSnow1}            {btSnow2}             {btIce}           {btCoastSand}        {btGrassSand1}       {btGrassSand2}       {btGrassSand3}          {btSand}             {btStone}            {btGold}             {btEgold}            {btIron}            {btEIron}             {btDark}
    {btGrass}       ( (  1,  1,  1,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), ( 74, 73, 72,1,1,1), (  0,  0,  0,0,0,0), ( 95, 94, 93,1,1,1), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0) ), {btGrass}
    {btBigGrass}    ( ( 18, 19,  8,1,1,1), (  1,  1,  1,0,0,0), ( 18, 19,  8,1,1,1), ( 18, 19,  8,1,1,1), ( 18, 19,  8,1,1,1), ( 18, 19,  8,1,1,1), ( 18, 19,  8,1,1,1), ( 18, 19,  8,1,1,1), ( 18, 19,  8,1,1,1), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), ( 18, 19,  8,1,1,1), ( 18, 19,  8,1,1,1), (  0,  0,  0,0,0,0), ( 18, 19,  8,1,1,1), (  0,  0,  0,0,0,0), ( 18, 19,  8,1,1,1), ( 18, 19,  8,1,1,1), ( 18, 19,  8,1,1,1), ( 18, 19,  8,1,1,1), ( 18, 19,  8,1,1,1), (  0,  0,  0,0,0,0) ), {btBigGrass}
    {btWetland}     ( (120,121,122,0,0,0), (120,121,122,0,0,0), (  1,  1,  1,0,0,0), (120,121,122,0,0,0), (  0,  0,  0,0,0,0), (120,121,122,0,0,0), (120,121,122,0,0,0), (120,121,122,0,0,0), (120,121,122,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (120,121,122,0,0,0), (120,121,122,0,0,0), (  0,  0,  0,0,0,0), (120,121,122,0,0,0), (  0,  0,  0,0,0,0), (120,121,122,0,0,0), (120,121,122,0,0,0), (120,121,122,0,0,0), (120,121,122,0,0,0), (120,121,122,0,0,0), (  0,  0,  0,0,0,0) ), {btWetland}
    {btSwamp}       ( ( 90, 91, 92,0,0,0), ( 90, 91, 92,0,0,0), ( 90, 91, 92,0,0,0), (  1,  1,  1,0,0,0), ( 90, 91, 92,0,0,0), ( 90, 91, 92,0,0,0), ( 90, 91, 92,0,0,0), ( 90, 91, 92,0,0,0), ( 90, 91, 92,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), ( 90, 91, 92,0,0,0), ( 90, 91, 92,0,0,0), (  0,  0,  0,0,0,0), ( 90, 91, 92,0,0,0), (  0,  0,  0,0,0,0), ( 90, 91, 92,0,0,0), ( 90, 91, 92,0,0,0), ( 90, 91, 92,0,0,0), ( 90, 91, 92,0,0,0), ( 90, 91, 92,0,0,0), (  0,  0,  0,0,0,0) ), {btSwamp}
    {btWater}       ( (123,125,127,0,1,0), (123,125,127,0,0,0), (114,115,119,0,0,0), (123,125,127,0,1,0), (  1,  1,  1,0,0,0), (  0,  0,  0,0,0,0), (107,106,105,1,1,1), (  0,  0,  0,0,0,0), (123,125,127,0,1,0), (107,106,105,1,1,1), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (243,242,241,1,1,1), (  0,  0,  0,0,0,0), (243,242,241,1,1,1), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0) ), {btWater}
    {btCoal}        ( ( 56, 57, 58,0,0,0), ( 56, 57, 58,0,0,0), ( 56, 57, 58,0,0,0), ( 56, 57, 58,0,0,0), (105,106,107,0,0,0), (  1,  1,  1,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), ( 87, 88, 89,0,0,0), (  0,  0,  0,0,0,0), ( 65, 64,247,1,1,1), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), ( 56, 57, 58,0,0,0), ( 56, 57, 58,0,0,0), ( 56, 57, 58,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0) ), {btCoal}
    {btGrassGround} ( ( 84, 85, 86,0,0,0), ( 84, 85, 86,0,0,0), ( 84, 85, 86,0,0,0), ( 84, 85, 86,0,0,0), ( 89, 88, 87,1,1,1), ( 89, 88, 87,1,1,1), (  1,  1,  1,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), ( 89, 88, 87,1,1,1), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), ( 84, 85, 86,0,0,0), ( 84, 85, 86,0,0,0), (  0,  0,  0,0,0,0), ( 84, 85, 86,0,0,0), (  0,  0,  0,0,0,0), ( 84, 85, 86,0,0,0), ( 89, 88, 87,1,1,1), ( 89, 88, 87,1,1,1), ( 89, 88, 87,1,1,1), ( 89, 88, 87,1,1,1), (  0,  0,  0,0,0,0) ), {btGrassGround}
    {btGround}      ( ( 56, 57, 58,0,0,0), ( 56, 57, 58,0,0,0), ( 56, 57, 58,0,0,0), ( 56, 57, 58,0,0,0), (105,106,107,0,0,0), ( 35, 36, 37,1,1,1), ( 87, 88, 89,0,0,0), (  1,  1,  1,0,0,0), ( 87, 88, 89,0,0,0), (  0,  0,  0,0,0,0), ( 65, 64,247,1,1,1), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), ( 56, 57, 58,0,0,0), ( 56, 57, 58,0,0,0), ( 56, 57, 58,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0) ), {btGround}
    {btTreeGrass}   ( ( 66, 67, 68,0,0,0), ( 66, 67, 68,0,0,0), ( 66, 67, 68,0,0,0), ( 66, 67, 68,0,0,0), ( 66, 67, 68,0,0,0), ( 96, 97, 98,0,0,0), ( 96, 97, 98,0,0,0), ( 96, 97, 98,0,0,0), (  1,  1,  1,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), ( 66, 67, 68,0,0,0), ( 66, 67, 68,0,0,0), (  0,  0,  0,0,0,0), ( 66, 67, 68,0,0,0), (  0,  0,  0,0,0,0), ( 66, 67, 68,0,0,0), ( 66, 67, 68,0,0,0), ( 66, 67, 68,0,0,0), ( 66, 67, 68,0,0,0), ( 66, 67, 68,0,0,0), (  0,  0,  0,0,0,0) ), {btTreeGrass}
    {btGroundSnow}  ( (316,317,318,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (247, 64, 65,0,1,0), (247, 64, 65,0,0,0), (247, 64, 65,0,0,0), (247, 64, 65,0,0,0), (  0,  0,  0,0,0,0), (  1,  1,  1,0,0,0), (  0,  0,  0,0,0,0), (213,212,220,1,1,1), (  0,  0,  0,0,0,0), (247, 64, 65,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0) ), {btGroundSnow}
    {btSnow1}       ( (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (220,212,213,0,0,0), (  0,  0,  0,0,0,0), (220,212,213,0,0,0), (  0,  0,  0,0,0,0), (220,212,213,0,0,0), (  1,  1,  1,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0) ), {btSnow1}
    {btSnow2}       ( (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (203,204,205,0,0,0), (203,204,205,0,0,0), (  1,  1,  1,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0) ), {btSnow2}
    {btIce}         ( (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), ( 23, 12, 22,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), ( 44,  4, 10,0,0,0), (  0,  0,  0,0,0,0), (  1,  1,  1,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0) ), {btIce}
    {btCoastSand}   ( ( 69, 70, 71,0,0,0), ( 69, 70, 71,0,0,0), ( 69, 70, 71,0,0,0), ( 69, 70, 71,0,0,0), (118,117,116,1,0,1), (111,112,113,0,0,0), ( 69, 70, 71,0,0,0), (111,112,113,0,0,0), ( 69, 70, 71,0,0,0), (111,112,113,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  1,  1,  1,0,0,0), (104,103,102,1,1,1), (  0,  0,  0,0,0,0), (104,103,102,1,1,1), (  0,  0,  0,0,0,0), ( 69, 70, 71,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0) ), {btCoastSand}
    {btGrassSand1}  ( ( 72, 73, 74,0,0,0), ( 72, 73, 74,0,0,0), ( 72, 73, 74,0,0,0), ( 72, 73, 74,0,0,0), ( 75, 76, 77,1,1,1), ( 72, 73, 74,0,0,0), ( 72, 73, 74,0,0,0), ( 72, 73, 74,0,0,0), ( 72, 73, 74,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), ( 77, 76, 75,1,1,1), (  1,  1,  1,0,0,0), (  0,  0,  0,0,0,0), ( 77, 76, 75,1,1,1), ( 77, 76, 75,1,1,1), ( 72, 73, 74,0,0,0), ( 77, 76, 75,1,1,1), ( 77, 76, 75,1,1,1), ( 77, 76, 75,1,1,1), ( 77, 76, 75,1,1,1), (  0,  0,  0,0,0,0) ), {btGrassSand1}
    {btGrassSand2}  ( ( 75, 76, 77,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (241,242,243,0,0,0), ( 75, 76, 77,0,0,0), (  0,  0,  0,0,0,0), ( 75, 76, 77,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (102,103,104,0,0,0), ( 75, 76, 77,0,0,0), (  1,  1,  1,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), ( 75, 76, 77,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0) ), {btGrassSand2}
    {btGrassSand3}  ( ( 93, 94, 95,0,0,0), ( 93, 94, 95,0,0,0), ( 93, 94, 95,0,0,0), ( 93, 94, 95,0,0,0), ( 78, 79, 80,0,0,0), ( 93, 94, 95,0,0,0), ( 93, 94, 95,0,0,0), ( 93, 94, 95,0,0,0), ( 93, 94, 95,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), ( 78, 79, 80,0,0,0), ( 78, 79, 80,0,0,0), ( 78, 79, 80,0,0,0), (  1,  1,  1,0,0,0), (  0,  0,  0,0,0,0), ( 93, 94, 95,0,0,0), ( 78, 79, 80,0,0,0), ( 78, 79, 80,0,0,0), ( 78, 79, 80,0,0,0), ( 78, 79, 80,0,0,0), (  0,  0,  0,0,0,0) ), {btGrassSand3}
    {btSand}        ( ( 93, 94, 95,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), ( 99,100,101,0,0,0), ( 81, 82, 83,0,0,0), ( 81, 82, 83,0,0,0), ( 81, 82, 83,0,0,0), (  1,  1,  1,0,0,0), ( 93, 94, 95,0,0,0), ( 78, 79, 80,0,0,0), ( 78, 79, 80,0,0,0), ( 78, 79, 80,0,0,0), ( 78, 79, 80,0,0,0), (  0,  0,  0,0,0,0) ), {btSand}
    {btStone}       ( (  0,139,138,0,0,0), (  0,139,138,0,0,0), (  0,139,138,0,0,0), (  0,139,138,0,0,0), (236,200,143,0,0,0), (282,278,277,0,0,0), (  0,139,138,0,0,0), (282,278,277,0,0,0), (  0,139,138,0,0,0), (298,294,293,0,0,0), (290,286,285,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,139,138,0,0,0), (  0,139,138,0,0,0), (  0,139,138,0,0,0), (  0,139,138,0,0,0), (  0,139,138,0,0,0), (  1,  1,  1,0,0,0), (  0,139,138,0,0,0), (  0,139,138,0,0,0), (  0,139,138,0,0,0), (  0,139,138,0,0,0), (  0,  0,  0,0,0,0) ), {btStone}
    {btGold}        ( (180,172,176,0,0,0), (180,172,176,0,0,0), (180,172,176,0,0,0), (180,172,176,0,0,0), (236,200,237,0,0,0), (183,175,179,0,0,0), (183,175,179,0,0,0), (183,175,179,0,0,0), (180,172,176,0,0,0), ( 49,171, 51,0,0,0), (261,262,306,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (181,173,177,0,0,0), (182,174,178,0,0,0), (182,174,178,0,0,0), (182,174,178,0,0,0), (182,174,178,0,0,0), (180,172,176,0,0,0), (  1,  1,  1,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0) ), {btGold}
    {btEgold}       ( (180,172,176,0,0,0), (180,172,176,0,0,0), (180,172,176,0,0,0), (180,172,176,0,0,0), (236,200,237,0,0,0), (183,175,179,0,0,0), (183,175,179,0,0,0), (183,175,179,0,0,0), (180,172,176,0,0,0), ( 49,171, 51,0,0,0), (261,262,306,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (181,173,177,0,0,0), (182,174,178,0,0,0), (182,174,178,0,0,0), (182,174,178,0,0,0), (182,174,178,0,0,0), (180,172,176,0,0,0), (144,145,145,0,0,0), (  1,  1,  1,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0) ), {btEgold}
    {btIron}        ( (188,168,184,0,0,0), (188,168,184,0,0,0), (188,168,184,0,0,0), (188,168,184,0,0,0), (236,200,239,0,0,0), (191,167,187,0,0,0), (191,167,187,0,0,0), (191,167,187,0,0,0), (188,168,184,0,0,0), (256,257,258,0,0,0), ( 52,166, 54,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (189,169,185,0,0,0), (190,170,186,0,0,0), (190,170,186,0,0,0), (190,170,186,0,0,0), (190,170,186,0,0,0), (188,168,184,0,0,0), (322,323,324,0,0,0), (322,323,324,0,0,0), (  1,  1,  1,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0) ), {btIron}
    {btEIron}       ( (188,168,184,0,0,0), (188,168,184,0,0,0), (188,168,184,0,0,0), (188,168,184,0,0,0), (236,200,239,0,0,0), (191,167,187,0,0,0), (191,167,187,0,0,0), (191,167,187,0,0,0), (188,168,184,0,0,0), (256,257,258,0,0,0), ( 52,166, 54,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (189,169,185,0,0,0), (190,170,186,0,0,0), (190,170,186,0,0,0), (190,170,186,0,0,0), (190,170,186,0,0,0), (188,168,184,0,0,0), (322,323,324,0,0,0), (322,323,324,0,0,0), (328,329,330,0,0,0), (  1,  1,  1,0,0,0), (  0,  0,  0,0,0,0) ), {btEIron}
    {btDark}        ( (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (  0,  0,  0,0,0,0), (346,347,348,0,0,0), (346,347,348,0,0,0), ( 53, 50,165,1,1,1), ( 53, 50,165,1,1,1), (  1,  1,  1,0,0,0) )  {btDark}
  );
  DF: array[0..1,0..3] of Byte = ( // Direction fixer (sometimes are tiles inverted so this will fix it)
    (0,1,2,3),(2,3,0,1)
  );
  FT: array[0..len_BIOME-1,0..9] of Word = ( // Full textures + variance
    (  0,  1,  2,  3,  5,  6, 13, 14,  0,  0), //  0 btGrass
    (  8,  9, 11,  0,  0,  0,  0,  0,  0,  0), //  1 btBigGrass
    ( 48,  0,  0,  0,  0,  0,  0,  0,  0,  0), //  2 btWetland
    ( 40, 41, 42, 43,  0,  0,  0,  0,  0,  0), //  3 btSwamp
    (192,193,196,  0,  0,  0,  0,  0,  0,  0), //  4 btWater
    (263,155,154,153,152,  7,  0,  0,  0,  0), //  5 btCoal
    ( 34,  0,  0,  0,  0,  0,  0,  0,  0,  0), //  6 btGrassGround
    ( 35, 36, 37,  0,  0,  0,  0,  0,  0,  0), //  7 btGround
    ( 17, 16,  0,  0,  0,  0,  0,  0,  0,  0), //  8 btTreeGrass
    ( 47,  0,  0,  0,  0,  0,  0,  0,  0,  0), //  9 btGroundSnow
    ( 46,  0,  0,  0,  0,  0,  0,  0,  0,  0), // 10 btSnow1
    ( 45,  0,  0,  0,  0,  0,  0,  0,  0,  0), // 11 btSnow2
    ( 44,  0,  0,  0,  0,  0,  0,  0,  0,  0), // 12 btIce
    ( 31, 32, 33,  0,  0,  0,  0,  0,  0,  0), // 13 btCoastSand
    ( 26,  0,  0,  0,  0,  0,  0,  0,  0,  0), // 14 btGrassSand1
    ( 27,  0,  0,  0,  0,  0,  0,  0,  0,  0), // 15 btGrassSand2
    ( 28,  0,  0,  0,  0,  0,  0,  0,  0,  0), // 16 btGrassSand3
    ( 29, 30,  0,  0,  0,  0,  0,  0,  0,  0), // 17 btSand
    (137,132,131,130,129, 18,128,136,135,134), // 18 btStone
    (307,147,146,145,144, 20,  0,  0,  0,  0), // 19 btGold
    (156,157,158,159,201,  0,  0,  0,  0,  0), // 20 btEgold
    (260,151,150,149,148, 22,  0,  0,  0,  0), // 21 btIron
    (160,161,162,163,164,  0,  0,  0,  0,  0), // 22 btEIron
    (245,  0,  0,  0,  0,  0,  0,  0,  0,  0)  // 23 btDark
  );
  PT: array[0..len_BIOME-1,0..9] of Single = ( // Probability of the specific full texture
    (0.667,0.834,0.890,0.913,0.947,0.981,0.993,1,1,1), //  0 btGrass
    (0.385,0.77 ,1    ,1    ,1    ,1    ,1    ,1,1,1), //  1 btBigGrass
    (1    ,1    ,1    ,1    ,1    ,1    ,1    ,1,1,1), //  2 btWetland
    (0.295,0.59 ,0.885,1    ,1    ,1    ,1    ,1,1,1), //  3 btSwamp
    (0.455,0.91 ,1    ,1    ,1    ,1    ,1    ,1,1,1), //  4 btWater
    (0.02 ,0.119,0.414,1    ,1    ,1    ,1    ,1,1,1), //  5 btCoal
    (1    ,1    ,1    ,1    ,1    ,1    ,1    ,1,1,1), //  6 btGrassGround
    (0.556,0.834,1    ,1    ,1    ,1    ,1    ,1,1,1), //  7 btGround
    (0.715,1    ,1    ,1    ,1    ,1    ,1    ,1,1,1), //  8 btTreeGrass
    (1    ,1    ,1    ,1    ,1    ,1    ,1    ,1,1,1), //  9 btGroundSnow
    (1    ,1    ,1    ,1    ,1    ,1    ,1    ,1,1,1), // 10 btSnow1
    (1    ,1    ,1    ,1    ,1    ,1    ,1    ,1,1,1), // 11 btSnow2
    (1    ,1    ,1    ,1    ,1    ,1    ,1    ,1,1,1), // 12 btIce
    (0.125,0.75 ,1    ,1    ,1    ,1    ,1    ,1,1,1), // 13 btCoastSand
    (1    ,1    ,1    ,1    ,1    ,1    ,1    ,1,1,1), // 14 btGrassSand1
    (1    ,1    ,1    ,1    ,1    ,1    ,1    ,1,1,1), // 15 btGrassSand2
    (1    ,1    ,1    ,1    ,1    ,1    ,1    ,1,1,1), // 16 btGrassSand3
    (0.75 ,1    ,1    ,1    ,1    ,1    ,1    ,1,1,1), // 17 btSand
    (0    ,0    ,0    ,0    ,0    ,0    ,1    ,1,1,1), // 18 btStone
    (0    ,0    ,0    ,0.223,1    ,1    ,1    ,1,1,1), // 19 btGold
    (0.2  ,0.4  ,0.6  ,0.8  ,1    ,1    ,1    ,1,1,1), // 20 btEgold
    (0    ,0    ,0    ,0.223,1    ,1    ,1    ,1,1,1), // 21 btIron
    (0.2  ,0.4  ,0.6  ,0.8  ,1    ,1    ,1    ,1,1,1), // 22 btEIron
    (1    ,1    ,1    ,1    ,1    ,1    ,1    ,1,1,1)  // 23 btDark
  );

  // Return full texture of specific biome (with variance)
  function GetFullTexture(Biome: Word): Word;
  var
    rnd: Single;
    K: Integer;
  begin
    Result := 0;
    rnd := fRNG.Random();
    for K := Low( PT[Biome] ) to High( PT[Biome] ) do
      if (rnd < PT[Biome,K]) then
      begin
        Result := FT[Biome,K];
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
    for Y1 := Max(1,Y-2) to Min(fMapY-1,Y+2) do
      for X1 := Max(1,X-2) to Min(fMapY-1,X+2) do
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
  procedure TransitionTexture(var T1, T2, Rotation: Byte; var Terrain: Word; const T1dir, T2dir, T1E, T2E, T1ER, T2ER: Byte);
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
    I,K,cntRes,difference, incK, incPerATile: Integer;
    Output: TInteger2Array;
  begin
    SetLength(Output, 5, 6); // 4 types of resources, 6 quantity types (none, 1, 2, 3, 4, 5)

    // Coal / Gold / Iron = 5 resources on a tile, Stone = 15
    incPerATile := 1 + (Byte(Resource = Byte(btStone)) shl 1); // 3 for Stone, 1 else

    // Fill with maximal possible quantity for each tile
    cntRes := 0;
    K := 0;
    for I := Low(Output) to High(Output) do
    begin
      K := High(Output[I]);
      Output[I,K] := count[I];
      cntRes := cntRes + count[I];
    end;
    cntRes := cntRes * (K * incPerATile + 3*Byte(Resource = Byte(btStone))); // Maximal capacity of shape

    // Decrease maximal resource capacity of shape by move specific tiles into lower levels of Output array
    incK := High(Output[0]);
    while (cntRes > Quantity) AND (incK >= -5) do // incK anti overflow condition
    begin
      I := 0;
      K := incK;
      while (cntRes > Quantity) AND (I <= High(Output)) AND (K <= High(Output[I])) do
      begin
        if (K >= 1) then
        begin
          difference := Min( Round((cntRes-Quantity)/incPerATile + 0.5), Output[I,K] );
          Output[I,K] := Output[I,K] - difference;
          Output[I,K-1] := difference;
          cntRes := cntRes - difference*incPerATile;
        end;
        I := I + 1;
        K := K + 1;
      end;
      incK := incK - 1;
    end;
    Result := Output;
  end;

var
   Rotation: Byte;
   Terrain: Word;
   X1,X2,Y1,Y2,sum,I,K,L, MaxLen: Integer;
   S,S2: TInteger2Array;
   BalanceResArr: TInteger2Array;
   TileFloodSearch: TKMTileFloodSearch;
   PointArr: TKMPointArray;
   LevelArr: TKMByteArray;
   Resources: TBalancedResource1Array;
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
  while Y1 < (fMapY shl 1) do
  begin
    Y2 := Y1 + 1;
    X1 := 2;
    while X1 < (fMapX shl 1) do
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
                //Terrain := GetFullTexture(FT[ B[Y1,X1] ,4]); // Place empty resources there and replace them with full variants later
              end
            // Other textures
              else
                Terrain := GetFullTexture(B[Y1,X1]);
              Rotation := fRNG.RandomI(3);
            end;
      // Transitions (line)
        $A: TransitionTexture(B[Y1,X1], B[Y1,X2], Rotation, Terrain, 1, 3, 1, 1, 4, 4);// Vertical transition
        $5: TransitionTexture(B[Y1,X1], B[Y2,X1], Rotation, Terrain, 2, 0, 1, 1, 4, 4);// Horizontal transition
      // Transitions (big edge for dominant texture and vice versa)
        $3: TransitionTexture(B[Y1,X1], B[Y2,X1], Rotation, Terrain, 1, 3, 2, 0, 5, 3);
        $6: TransitionTexture(B[Y1,X1], B[Y1,X2], Rotation, Terrain, 0, 2, 0, 2, 3, 5);
        $C: TransitionTexture(B[Y1,X1], B[Y2,X2], Rotation, Terrain, 1, 3, 0, 2, 3, 5);
        $9: TransitionTexture(B[Y1,X1], B[Y2,X1], Rotation, Terrain, 2, 0, 0, 2, 3, 5);
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
  Resources := fRes.Resources;
  TileFloodSearch := TKMTileFloodSearch.Create(KMPoint(1,1), KMPoint(fMapX-1,fMapY-1), S, S2);
  try
    // Detect all shapes (merge / split existing shapes if they are / are not connected because could CA changed it)
    for I := 0 to fRes.Count - 1 do
    begin
      Resources[I].TileCounter := TIntegerArray.Create(0,0,0,0,0);
      K := Low(Resources[I].Points);
      // Calculate the count of tiles which can be changed to specific resource (it is represented by multiple points from Voronoi which represent multiple shapes)
      MaxLen := Length(Resources[I].Points);
      while K < MaxLen do
      begin
        X1 := Resources[I].Points[K].X;
        Y1 := Resources[I].Points[K].Y;
        // Sometimes are points in edge of 2 transition textures (or are moved by CA) -> scan 1 tile around
        sum := (Byte(  S[Y1,X1] = Resources[I].Resource  )) OR
               (Byte(  (Y1+1 < fMapY) AND (S[Y1+1,X1] = Resources[I].Resource)  ) shl 1) OR
               (Byte(  (X1+1 < fMapX) AND (S[Y1,X1+1] = Resources[I].Resource)  ) shl 2) OR
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

    for I := 0 to fRes.Count - 1 do
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
            LevelArr[L] := 5 - LevelArr[L];
            if (LevelArr[L] <> 5) then
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


// The last step in fix mines -> check count, height and TRY to balance the map
// TilesPartsArr = tiles composition array
// A = array of biomes
procedure TKMRandomMapGenerator.MineFinalFixer(var TilesPartsArr: TTileParts; var A: TKMByte2Array);
//var
//  X,Y,X1,X2,maxY,minX,maxX,MinMineSize, minVal, maxIndex, startIndex, actVal, MaxPosIdx: Integer;
//  X_RESERVE, X_FLOAT: Single;
//  MinLimit, MaxLimit: TSmallIntArray;
//  MineSearch: TKMMinerFixSearch;
//begin
//  if (MineCnt < 1) then
//    Exit;
//// Initialization
//  SetLength(Shape,Length(A[0])+2);
//  SetLength(MinLimit, Length(A[0])+2);
//  SetLength(MaxLimit, Length(A[0])+2);
//  for X := Low(Shape) to High(Shape) do
//  begin
//    Shape[X].Active := False;
//    Shape[X].Min := High(MinLimit);
//    MinLimit[X] := High(MinLimit);
//    Shape[X].Max := Low(MaxLimit);
//    MaxLimit[X] := Low(MaxLimit);
//  end;
//
//// Detect shape of resource
//  //if RMGSettings.Objects.Active then
//  //begin
//  //
//    MineSearch := TKMMinerFixSearch.Create(  KMPoint(  Low(A[0]), Low(A) ), KMPoint( High(A[0]), High(A) ), MinLimit, MaxLimit, aVisited, A  );
//    try
//      MineSearch.QuickFlood(aPosition.X,aPosition.Y,Resource);
//    finally
//      MineSearch.Free;
//    end;
//    for X := Low(Shape) to High(Shape) do
//      if (Shape[X].Min <> MinLimit[X]) then
//      begin
//        Shape[X].Active := True;
//        Shape[X].Min := MinLimit[X];
//        Shape[X].Max := MaxLimit[X];
//      end;
//  //end
//  //else
//  //  MinerFixFloodSearch(Resource, aPosition.Y, aPosition.X, aVisited);
//
//// Find start index of shape
//  X := 0;
//  while not Shape[X].Active AND (X < High(Shape)) do
//    X := X+1;
//  minX := X;
//  while Shape[X].Active AND (X < High(Shape)) do
//    X := X+1;
//  maxX := X-1;
//
//// Change shape to be able to mine resources here
//  MinMineSize := MINESIZE + 1;
//  X_RESERVE := (maxX - minX) / (MineCnt*1.0) - MinMineSize;
//  X := minX;
//  X_FLOAT := MinX;
//  while (X+MinMineSize <= MaxX) do
//  begin
//    minVal := High(Integer);
//    maxIndex := High(A);
//  // Scan last interval of tiles and find best spot for fix
//    for X1 := X to Max(X,Round(X_FLOAT+X_RESERVE)) do
//    begin
//    // Find a southernmost point in minimal interval of possible mine
//      maxY := 0;
//      for X2 := X1+1 to Min(maxX,X1+MINESIZE) do // We need to focus only on balancing of 2 or 3 tiles where will be mine (edge tiles may be higher but we dont care)
//        if (Shape[X2].Max > maxY) then
//        begin
//          maxY := Shape[X2].Max;
//          MaxPosIdx := X2;
//        end;
//    // Calculate the price of transformation which secure place mine (price = penalization of deleted tiles)
//      actVal := 0;
//      for X2 := X1 to Min(maxX,X1+MINESIZE) do
//        actVal := actVal + Max(0, maxY - Shape[X2].Max); // Edges of potential mine tiles may be higher but it is fine
//    // Save best solution (closer to right is better)
//      if (actVal < minVal) then
//      begin
//        minVal := actVal;
//        maxIndex := MaxPosIdx;
//        startIndex := X1;
//      end;
//    end;
//  // Apply changes
//    maxY := Shape[maxIndex].Max;
//    for X1 := startIndex to startIndex + MinMineSize do
//    begin
//      Y := Shape[X1].Max;
//      while (Y <= maxY) AND (Y < High(A)) do
//      begin
//        Shape[X1].Max := Shape[X1].Max + 1;
//        A[Y,X1] := Resource;
//        aVisited[Y,X1] := True;
//        Y := Y + 1;
//      end;
//    end;
//    X_FLOAT := X_FLOAT + X_RESERVE + MinMineSize;
//    X := Round(X_FLOAT);
//  end;
//end;
//

  function CheckObject(aID: Word): Boolean;
  begin
    with gMapElements[aID] do
      Result := CanBeRemoved AND not AllBlocked;
  end;

  procedure FixMine(aX,aY,aBiome: Integer);
  var
    X,Y, MineHeight: Integer;
  begin
    // Check tiles if placing mine is possible
    for X := aX to aX + 3 + Byte(aBiome = Byte(btIron)) do
      if (A[aY,X] <> aBiome) then
        Exit;
    for X := aX + 1 to aX + 3 - 1 + Byte(aBiome = Byte(btIron)) do
      if (A[aY+1,X] >= Byte(btStone)) then
        Exit;

    // Check final height and obstacles (objects)
    MineHeight := 0;
    for Y := aY to aY + 1 do
      for X := aX to aX + 3 + Byte(aBiome = Byte(btIron)) do
        MineHeight := MineHeight + TilesPartsArr.Height[Y,X];
    // Normalize height
    MineHeight := MineHeight div (8 + 2*Byte(aBiome = Byte(btIron)));
    // Update tiles of potential mine
    for Y := aY to aY + 1 do
      for X := aX to aX + 3 + Byte(aBiome = Byte(btIron)) do
      begin
        // Update height
        TilesPartsArr.Height[Y,X] := (TilesPartsArr.Height[Y,X] + MineHeight) div 2;
        // Check object
        if not CheckObject(TilesPartsArr.Obj[Y,X]) then
          TilesPartsArr.Obj[Y,X] := 255;
      end;
  end;

var
//  RESOURCE: Byte;
  X,Y: Integer;
//  Visited: TBoolean2Array;
//  Resources: TBalancedResource1Array;
begin
  for Y := 2 to fMapY-2 do
    for X := 2 to fMapX-2-5 do
    begin
      if (A[Y,X] = Byte(btStone)) AND (A[Y+1,X] < Byte(btStone)) then
      begin
        if not CheckObject(TilesPartsArr.Obj[Y,X]) then
          TilesPartsArr.Obj[Y,X] := 255;
      end
      else if (A[Y,X] = Byte(btGold)) then FixMine(X,Y,Byte(btGold))
      else if (A[Y,X] = Byte(btIron)) then FixMine(X,Y,Byte(btIron));
    end;
  //Resources := fRes.Resources;
  //for I := 0 to fRes.Count - 1 do
  //begin
  //  if (Resources[I].Resource = Byte(btGold)) then
  //    RESOURCE := 2
  //  else if (Resources[I].Resource = Byte(btIron)) then
  //    RESOURCE := 3
  //  else // Coal and Stone are always fine
  //    continue;
  //  for K := Low(Resources[I].Points) to High(Resources[I].Points) do
  //    if not Visited[ Resources[I].Points[K].Y, Resources[I].Points[K].X ]
  //       AND (A[ Resources[I].Points[K].Y, Resources[I].Points[K].X ] = Resources[I].Resource) then
  //      Fixer(RESOURCE, Resources[I].Resource, Resources[I].MinesCnt, Resources[I].Points[K], Visited);
  //end;
end;



// Debug function (only full textures without transitions)
// TilesPartsArr = tiles composition array
// A = array of biomes
procedure TKMRandomMapGenerator.GenerateBasicTiles(var TilesPartsArr: TTileParts; var A: TKMByte2Array);
var
   X,Y: Integer;
const
  FT: array[0..len_BIOME-1] of Byte = (
    0,   //  0 btGrass
    8,   //  1 btBigGrass
    48,  //  2 btWetland
    40,  //  3 btSwamp
    192, //  4 btWater
    155, //  5 btCoal
    34,  //  6 btGrassGround
    35,  //  7 btGround
    17,  //  8 btTreeGrass
    47,  //  9 btGroundSnow
    46,  // 10 btSnow1
    45,  // 11 btSnow2
    44,  // 12 btIce
    31,  // 13 btCoastSand
    26,  // 14 btGrassSand1
    27,  // 15 btGrassSand2
    28,  // 16 btGrassSand3
    29,  // 17 btSand
    132, // 18 btStone
    147, // 19 btGold
    156, // 20 btEgold
    151, // 21 btIron
    160, // 22 btEIron
    245  // 23 btDark
  );
begin
	for Y := 1 to fMapY-1 do
		for X := 1 to fMapX-1 do
    begin
      TilesPartsArr.Terrain[Y,X] := FT[ A[Y,X] ];
      TilesPartsArr.Rotation[Y,X] := 0;
		end;
end;



// Height generator
// aLocs = player's locs
// TilesPartsArr = tiles composition array
// A = array of biomes
// TileTempl = array of biome-decomposition
procedure TKMRandomMapGenerator.GenerateHeight(var aLocs: TKMPointArray; var TilesPartsArr: TTileParts; var A: TKMByte2Array; var TileTempl: TKMByte2Array);

  procedure ScanObstacle(aStartPoint,aEndPoint,aInitDir: TKMPoint; var aPointsCnt: Integer; var aVisitArr: TBoolean2Array; var CopyA: TKMByte2Array; var aBorderPoints: TKMPointArray);
  var
    X,Y,Counter,Overflow: Integer;
    v: TKMPoint;
  begin
    X := aStartPoint.X;
    Y := aStartPoint.Y;
    v := aInitDir; // Init vector
    //Dir := ifthen(aRightHanded, -1, 1); // Determine direction of rotation
    Counter := 0;
    aPointsCnt := 0;
    Overflow := 0;
    repeat
      Overflow := Overflow + 1;
      Counter := Counter + 1;
      // Find next CanBeVisited tile and rotate vector
      if (CopyA[ Y-v.X{*Dir}, X+v.Y{*Dir} ] > Byte(btStone)) then // Left {Right}
      begin
        Counter := Counter - 1;
        v := KMPoint(+v.Y,-v.X)
      end
      else if (CopyA[ Y+v.Y, X+v.X ] > Byte(btStone)) then // Forward
      begin
        //v := KMPoint(+v.X,+v.Y)
      end
      else if (CopyA[ Y+v.X{*Dir}, X-v.Y{*Dir}  ] > Byte(btStone)) then // Right {Left}
      begin
        v := KMPoint(-v.Y,+v.X)
      end
      else if (CopyA[ Y-v.Y, X-v.X ] > Byte(btStone)) then // Backward
      begin
        v := KMPoint(-v.X,-v.Y)
      end
      else
        break;
      // Mark point
      aVisitArr[Y,X] := True;
      if (Counter >= 2) then
      begin
        Counter := 0;
        if (aPointsCnt >= Length(aBorderPoints)) then
          SetLength(aBorderPoints, aPointsCnt + 200);
        aBorderPoints[aPointsCnt] := KMPoint(X,Y);
        aPointsCnt := aPointsCnt + 1;
      end;
      // Move into new point
      X := X + v.X;
      Y := Y + v.Y;
    until KMSamePoint( KMPoint(X,Y), aEndPoint ) OR (Overflow > 65536);
  end;

  function GetWalkablePoint(aP: TKMPoint): TKMPoint;
  var
    X,Y: Word;
  begin
    Result := aP;
    if (A[aP.Y,aP.X] > Byte(btStone)) then
      for Y := Max(1,aP.Y-1) to Min(fMapY-1,aP.Y+1) do
      for X := Max(1,aP.X-1) to Min(fMapX-1,aP.X+1) do
        if (A[Y,X] < Byte(btStone)) then
        begin
          Result := KMPoint(X,Y);
          Exit;
        end;
  end;

  procedure CreateCliffs(var H: TInteger2Array; var HFWA: TKMHeightFillWalkableAreas);
  const
    DEC_COEF = 4;
  var
    PointsCnt, I,K,X,Y: Integer;
    P1,P2: TKMPoint;
    VisitArr: TBoolean2Array;
    CopyA: TKMByte2Array;
    Points, HillSeeds:TKMPointArray;
  begin
    // Copy A (biomes) and create borders so no conditions have to be used in ScanObstacle
    SetLength(CopyA, Length(A), Length(A[0]));
    for Y := Low(A) to High(A) do
      Move(A[Y,0], CopyA[Y,0], SizeOf(A[Y,0])*Length(A[Y]));
    for Y := Low(A) to High(A) do
    begin
      CopyA[Y,0] := 0;
      CopyA[Y,fMapX] := 0;
    end;
    for X := Low(A[0]) to High(A[0]) do
    begin
      CopyA[0,X] := 0;
      CopyA[fMapY,X] := 0;
    end;
    // Init Visit arr
    SetLength(VisitArr, fMapY, fMapX);
    for Y := 0 to fMapY-1 do
      FillChar(VisitArr[Y,0], SizeOf(VisitArr[Y,0]) * Length(VisitArr[Y]), #0);
    // Find the right biomes (mountains)
    SetLength(HillSeeds,1);
	  for Y := 1 to fMapY-1 do
      for X := 1 to fMapX-1 do
        if not VisitArr[Y,X] AND (A[Y,X] > Byte(btStone)) AND (A[Y,X-1] < Byte(btStone)) then
        begin
          // Scan the mountain
          ScanObstacle(KMPoint(X,Y), KMPoint(X,Y), KMPoint(0,-1), PointsCnt, VisitArr, CopyA, Points);
          // Find points with best evaluation = points which are close to each other and have indexes too far away
          for I := 0 to PointsCnt - 1 do
            for K := I+1 to PointsCnt - 1 do
              if (KMDistanceAbs(Points[I],Points[K]) < 7)
                 AND (Min(abs(I-K),abs(PointsCnt-K+I)) > 25)
                 AND (fRNG.Random > 0.3) then
              begin
                P1 := Points[I];
                P2 := Points[K];
                if (Abs(H[P1.Y,P1.X]) > 10) OR (Abs(H[P2.Y,P2.X]) > 10) then
                  continue;
                if (H[P1.Y,P1.X] > H[P2.Y,P2.X]) // Make sure that cliff is just on 1 side
                   OR (H[P1.Y,P1.X] = 0) AND (H[P2.Y,P2.X] = 0) AND (fRNG.Random > 0.5) then // Random element
                  KMSwapPoints(P1,P2);
                HillSeeds[0] := GetWalkablePoint( P1 );
                HFWA.ExpandHeight(HillSeeds, -100, DEC_COEF);
                HillSeeds[0] := GetWalkablePoint( P2 );
                HFWA.ExpandHeight(HillSeeds, 100, DEC_COEF);
              end;
        end;
  end;

  procedure RandomSelector(aStep: Word; var ShapePoints: TKMPointArray);
  var
    Check: Boolean;
    K,L, Cnt: Integer;
  begin
    K := 0;
    Cnt := 0;
    while (K < Length(ShapePoints)) do
    begin
      // Consider protected radius
      Check := True;
      for L := Low(aLocs) to High(aLocs) do
        if (KMDistanceSqr(aLocs[L],ShapePoints[K]) < Sqr(RMGSettings.Locs.ProtectedRadius * 5) ) then
        begin
          Check := False;
          break;
        end;
      if Check then
      begin
        ShapePoints[Cnt] := ShapePoints[K];
        Cnt := Cnt + 1;
      end;
      K := K + Max(1,fRNG.RandomI(aStep));
    end;
    SetLength(ShapePoints,Cnt);
  end;

const
  //HeightMix: array [0..len_BIOME-1] of Byte = (
  //  //20,18,15,15,15,21,19,22,23,24,25,20,20,19,18,17,18,21,20,20,20,20,20,20
  //  10,10,5,5,3,5,10,1,10,10,20,20,0,5,10,10,15,20,10,20,20,20,20,0
  //);
  //TBiomeType = (
  //10,15,0,0,0,10,5,0,15,15,20,20,10,5,btGrassSand1,btGrassSand2,btGrassSand3,btSand,btStone,btGold,btEgold,btIron,btEIron,btDark);

  HeightVariance: array [0..len_BIOME-1] of Byte = (
    10, //  0 btGrass
    10, //  1 btBigGrass
    5,  //  2 btWetland
    5,  //  3 btSwamp
    3,  //  4 btWater
    5,  //  5 btCoal
    10, //  6 btGrassGround
    10, //  7 btGround
    10, //  8 btTreeGrass
    10, //  9 btGroundSnow
    15, // 10 btSnow1
    15, // 11 btSnow2
    0,  // 12 btIce
    5,  // 13 btCoastSand
    10, // 14 btGrassSand1
    10, // 15 btGrassSand2
    15, // 16 btGrassSand3
    20, // 17 btSand
    10, // 18 btStone
    20, // 19 btGold
    20, // 20 btEgold
    0,  // 21 btIron
    0,  // 22 btEIron
    0   // 23 btDark
  );
  HNST: array[0..len_BIOME-1,0..len_BIOME-1] of Byte = ( // Hide Non-Smooth Transition (height fix)
  // 0  1  2  3  4    5  6  7  8  9   10 11 12 13 14   15 16 17 18 19   20  21  22  23
    (0, 0, 0, 2, 3,   5, 2, 5, 1, 5,   5, 5, 5, 3, 1,   4, 3, 4, 0, 0,   0,  0,  0,  0), //  0 btGrass
    (0, 0, 0, 2, 3,   5, 2, 5, 1, 5,   5, 5, 5, 3, 1,   4, 3, 4, 0, 0,   0,  0,  0,  0), //  1 btBigGrass
    (0, 0, 0, 2, 0,   5, 2, 3, 2, 5,   5, 5, 5, 2, 1,   2, 3, 4, 0, 0,   0,  0,  0,  0), //  2 btWetland
    (2, 2, 2, 0, 3,   5, 0, 1, 2, 5,   5, 5, 5, 3, 3,   3, 4, 5, 0, 0,   0,  0,  0,  0), //  3 btSwamp
    (3, 3, 0, 3, 0,   5, 3, 3, 3, 3,   5, 5, 5, 3, 3,   3, 3, 3, 0, 0,   0,  0,  0,  0), //  4 btWater
    (5, 5, 5, 5, 5,   0, 2, 0, 0, 5,   5, 5, 5, 4, 4,   4, 4, 4, 0, 0,   0,  0,  0,  0), //  5 btCoal
    (2, 2, 2, 0, 3,   2, 0, 0, 0, 5,   5, 5, 5, 5, 5,   5, 5, 3, 0, 0,   0,  0,  0,  0), //  6 btGrassGround
    (5, 5, 3, 1, 3,   0, 0, 0, 5, 5,   5, 5, 5, 4, 4,   4, 4, 3, 0, 0,   0,  0,  0,  0), //  7 btGround
    (1, 1, 2, 2, 3,   0, 0, 5, 0, 5,   5, 5, 5, 5, 5,   5, 5, 5, 0, 0,   0,  0,  0,  0), //  8 btTreeGrass
    (5, 5, 5, 5, 3,   5, 5, 5, 5, 0,   5, 5, 5, 5, 5,   5, 5, 5, 0, 0,   0,  0,  0,  0), //  9 btGroundSnow
    (5, 5, 5, 5, 5,   5, 5, 5, 5, 5,   0, 5, 5, 5, 5,   5, 5, 5, 0, 0,   0,  0,  0,  0), // 10 btSnow1
    (5, 5, 5, 5, 5,   5, 5, 5, 5, 5,   5, 0, 5, 5, 5,   5, 5, 5, 0, 0,   0,  0,  0,  0), // 11 btSnow2
    (5, 5, 5, 5, 5,   5, 5, 5, 5, 5,   5, 5, 0, 3, 3,   3, 3, 3, 0, 0,   0,  0,  0,  0), // 12 btIce
    (3, 3, 2, 3, 3,   4, 5, 4, 5, 5,   5, 5, 3, 0, 0,   0, 0, 0, 0, 0,   0,  0,  0,  0), // 13 btCoastSand
    (1, 1, 1, 3, 3,   4, 5, 4, 5, 5,   5, 5, 3, 0, 0,   0, 0, 0, 0, 0,   0,  0,  0,  0), // 14 btGrassSand1
    (4, 4, 2, 3, 3,   4, 5, 4, 5, 5,   5, 5, 3, 0, 0,   0, 0, 0, 0, 0,   0,  0,  0,  0), // 15 btGrassSand2
    (3, 3, 3, 4, 3,   4, 5, 4, 5, 5,   5, 5, 3, 0, 0,   0, 0, 0, 0, 0,   0,  0,  0,  0), // 16 btGrassSand3
    (4, 4, 4, 5, 3,   4, 3, 3, 5, 5,   5, 5, 3, 0, 0,   0, 0, 0, 0, 0,   0,  0,  0,  0), // 17 btSand
    (0, 0, 0, 0, 0,   0, 0, 0, 0, 0,   0, 0, 0, 0, 0,   0, 0, 0, 0, 0,   0,  0,  0,  0), // 18 btStone
    (0, 0, 0, 0, 0,   0, 0, 0, 0, 0,   0, 0, 0, 0, 0,   0, 0, 0, 0, 0,   0,100,100,  0), // 19 btGold
    (0, 0, 0, 0, 0,   0, 0, 0, 0, 0,   0, 0, 0, 0, 0,   0, 0, 0, 0, 0,   0,100,100,  0), // 20 btEgold
    (0, 0, 0, 0, 0,   0, 0, 0, 0, 0,   0, 0, 0, 0, 0,   0, 0, 0, 0, 100, 100,0,  0,  0), // 21 btIron
    (0, 0, 0, 0, 0,   0, 0, 0, 0, 0,   0, 0, 0, 0, 0,   0, 0, 0, 0, 100, 100,0,  0,  0), // 22 btEIron
    (0, 0, 0, 0, 0,   0, 0, 0, 0, 0,   0, 0, 0, 0, 0,   0, 0, 0, 0, 0,   0,  0,  0,  0)  // 23 btDark
  );
  DECREASE_HEIGHT_SET: set of Byte = [Byte(btWater),Byte(btWetland),Byte(btSwamp)];
  CHANGE_HEIGHT_SET: set of Byte = [Byte(btBigGrass), Byte(btGrassGround), Byte(btTreeGrass), Byte(btGroundSnow), Byte(btSnow1), Byte(btSnow2), Byte(btGrassSand2), Byte(btSand)];
var
  X_0,Y_0,X_1,Y_1,X_2,Y_2,X1,X2,Y1,Y2,sum: Integer;
  H1,H2,H3: TInteger2Array;
  ShapePoints: TKMPointArray;
  VisitedArr: TKMByte2Array;
  HFWA: TKMHeightFillWalkableAreas;
  SPE: TKMShapePointsExtractor;
begin

  SetLength(H3, Length(TilesPartsArr.Terrain), Length(TilesPartsArr.Terrain[0]));
  for Y1 := Low(H3) to High(H3) do
    FillChar(H3[Y1,0], SizeOf(H3[Y1,0]) * Length(H3[Y1]), #0);

  HFWA := TKMHeightFillWalkableAreas.Create(A,H3);
  try
   CreateCliffs(H3, HFWA);
   // Decrease height of swamp / wetland / water and change height of special biomes
    // Init VisitedArr
    SetLength(VisitedArr,Length(TilesPartsArr.Terrain), Length(TilesPartsArr.Terrain[0]));
    for Y1 := Low(VisitedArr) to High(VisitedArr) do
      FillChar(VisitedArr[Y1,0], SizeOf(VisitedArr[Y1,0]) * Length(VisitedArr[Y1]), #0);

    SPE := TKMShapePointsExtractor.Create(KMPoint( Low(VisitedArr[0]), Low(VisitedArr) ), KMPoint( High(VisitedArr[0]), High(VisitedArr) ), A, VisitedArr, False);
    try
      for Y1 := Low(VisitedArr) to High(VisitedArr) do
        for X1 := Low(VisitedArr[Y1]) to High(VisitedArr[Y1]) do
          if (VisitedArr[Y1,X1] = 0) AND ((A[Y1,X1] in DECREASE_HEIGHT_SET) OR (A[Y1,X1] in CHANGE_HEIGHT_SET)) then
          begin
            SPE.QuickFlood(X1,Y1,A[Y1,X1],1, ShapePoints);
            {
            case A[Y1,X1] of
              Byte(btBigGrass):    RandomSelector(RMGSettings.Height.H1+fRNG.RandomI(5),ShapePoints);
              Byte(btGrassGround): RandomSelector(RMGSettings.Height.H1+fRNG.RandomI(3),ShapePoints);
              Byte(btTreeGrass):   RandomSelector(RMGSettings.Height.H1+fRNG.RandomI(5),ShapePoints);
              Byte(btGroundSnow):  RandomSelector(RMGSettings.Height.H1+fRNG.RandomI(3),ShapePoints);
              Byte(btSnow1):       RandomSelector(RMGSettings.Height.H1+fRNG.RandomI(10),ShapePoints);
              Byte(btSnow2):       RandomSelector(RMGSettings.Height.H1+fRNG.RandomI(10),ShapePoints);
              Byte(btGrassSand2):  RandomSelector(RMGSettings.Height.H1+fRNG.RandomI(3),ShapePoints);
              Byte(btSand):        RandomSelector(RMGSettings.Height.H1+fRNG.RandomI(10),ShapePoints);
            end;
            //}
            case A[Y1,X1] of
              Byte(btWater):       HFWA.ExpandHeight(ShapePoints, -40 - fRNG.RandomI(5), 10 + fRNG.RandomI(3));
              Byte(btWetland):     HFWA.ExpandHeight(ShapePoints, -10 - fRNG.RandomI(3), 5 + fRNG.RandomI(3));
              Byte(btSwamp):       HFWA.ExpandHeight(ShapePoints, -10 - fRNG.RandomI(3), 5 + fRNG.RandomI(3));
              {
              Byte(btBigGrass):    HFWA.ExpandHeight(ShapePoints, RMGSettings.Height.H2 + 10 + fRNG.RandomI(15),  3 + fRNG.RandomI(3));
              Byte(btGrassGround): HFWA.ExpandHeight(ShapePoints, RMGSettings.Height.H2 + 15 + fRNG.RandomI(10),  3 + fRNG.RandomI(4));
              Byte(btTreeGrass):   HFWA.ExpandHeight(ShapePoints, RMGSettings.Height.H2 + 10 + fRNG.RandomI(15),  3 + fRNG.RandomI(3));
              Byte(btGroundSnow):  HFWA.ExpandHeight(ShapePoints, RMGSettings.Height.H2 + 15 + fRNG.RandomI(10),  3 + fRNG.RandomI(4));
              Byte(btSnow1):       HFWA.ExpandHeight(ShapePoints, RMGSettings.Height.H2 + 20 + fRNG.RandomI(15),  5 + fRNG.RandomI(3));
              Byte(btSnow2):       HFWA.ExpandHeight(ShapePoints, RMGSettings.Height.H2 + 20 + fRNG.RandomI(15),  5 + fRNG.RandomI(3));
              Byte(btGrassSand2):  HFWA.ExpandHeight(ShapePoints, RMGSettings.Height.H2 + 15 + fRNG.RandomI(10),  3 + fRNG.RandomI(3));
              Byte(btSand):        HFWA.ExpandHeight(ShapePoints, RMGSettings.Height.H2 + 20 + fRNG.RandomI(5),   3 + fRNG.RandomI(3));
              //}
            end;
          end;
    finally
      SPE.Free;
    end;

    // Protected radius
    if RMGSettings.Locs.Active AND (Length(aLocs) > 0) then
    begin
      for Y1 := Low(VisitedArr) to High(VisitedArr) do
        FillChar(VisitedArr[Y1,0], SizeOf(VisitedArr[Y1,0]) * Length(VisitedArr[Y1]), #0);
      HFWA.ExpandHeight(aLocs, -100, 15 / RMGSettings.Locs.ProtectedRadius, True);
    end;

  finally
    HFWA.Free();
  end;

  H1 := LinearInterpolation(Max(1, 5 - Trunc(RMGSettings.Height.Step / 2)),RMGSettings.Height.Slope);
  H2 := LinearInterpolation(Max(1, 6 + Round(RMGSettings.Height.Step / 2)),RMGSettings.Height.Height);
	for Y1 := 1 to fMapY-1 do
    for X1 := 1 to fMapX-1 do
      TilesPartsArr.Height[Y1,X1] := Min(100, Min(90,Max(5, -H1[Y1,X1] + H2[Y1,X1] + H3[Y1,X1])) + fRNG.RandomI(HeightVariance[ A[Y1,X1] ]));

  for Y_1 := 1 to fMapY-1 do
  begin
    Y2 := Y_1 shl 1;
    Y1 := Y2 - 1;
    Y_0 := Max(0, Y_1 - 2);
    Y_2 := Min(fMapY, Y_1 + 1);
    for X_1 := 1 to fMapX-1 do
    begin
      X2 := X_1 shl 1;
      X1 := X2 - 1;
      X_0 := Max(0, X_1 - 2);
      X_2 := Min(fMapX, X_1 + 1);

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
          sum := + Byte(A[Y_0,X_0] >= Byte(btStone))
                 + Byte(A[Y_0,X_1] >= Byte(btStone))
                 + Byte(A[Y_0,X_2] >= Byte(btStone))
                 + Byte(A[Y_1,X_2] >= Byte(btStone))
                 + Byte(A[Y_1,X_0] >= Byte(btStone))
                 + Byte(A[Y_2,X_0] >= Byte(btStone))
                 + Byte(A[Y_2,X_1] >= Byte(btStone))
                 + Byte(A[Y_2,X_2] >= Byte(btStone));
        // Tile is surrounded by mountains
        if (sum = 8) then
          TilesPartsArr.Height[Y_1,X_1] := Max(0, Min(100, TilesPartsArr.Height[Y_1,X_1] - 10 + fRNG.RandomI(50))) ;
      end;

    // Set lower height to non-smooth transitions (hide it)
      if RMGSettings.Height.HideNonSmoothTransition then
      begin
        sum := + HNST[ TileTempl[Y1,X1] ][ TileTempl[Y2,X1] ]
               + HNST[ TileTempl[Y1,X1] ][ TileTempl[Y1,X2] ]
               + HNST[ TileTempl[Y1,X2] ][ TileTempl[Y2,X2] ]
               + HNST[ TileTempl[Y2,X1] ][ TileTempl[Y2,X2] ];
        if (sum > 0) then
          TilesPartsArr.Height[Y_1,X_1] := Max(0, TilesPartsArr.Height[Y_1,X_1] - sum);
      end;
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
      (  0,  1,  2,  3,  4, 68,  8,  9,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0), // oStone
      (  5,  6,210,211,214,212,213,215,  7,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0), // oShrub
      ( 10, 11, 12, 13, 14, 15, 16, 38, 42, 43, 46,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0), // oBranch
      ( 17, 18, 19, 21,251,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0), // oMushroom
      ( 22, 23, 24,249,250,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0), // oFlower
      ( 58, 59, 60, 62, 63,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0), // oGrass
      ( 68, 69, 70, 71, 72, 73,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0), // oDebris
      (190,191,192,193,195,196,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0), // oTreeDry
      ( 88, 89, 90, 92, 93, 94, 95, 97, 98, 99,100,102,103,104,105,107,108,109,110,  0,  0), // oTree
      (149,150,151,153,154,155,157,158,159,160,162,163,164,165,167,168,169,170,172,  0,  0), // oConifer
      (113,114,116,117,118,119,121,122,123,124,112,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0), // oTreeTropical
      (216,217,218,219,220,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0), // oCactus
      (200,201,202,203,204,205,206,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0), // oPalm
      ( 31, 32, 33, 34, 35, 36, 37,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0)  // oWaterTypes
    );
    Probability: ( // Probability of specific object
      (0.17,0.34,0.51,0.68,0.85,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1), // oStone
      (0.19,0.38,0.57,0.76,0.95,0.97,0.99,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1), // oShrub
      (0.1 ,0.2 ,0.3 ,0.4 ,0.5 ,0.6 ,0.7 ,0.8 ,0.9 ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1), // oBranch
      (0.25,0.5 ,0.75,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1), // oMushroom
      (0.34,0.68,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1), // oFlower
      (0.04,0.08,0.44,0.8 ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1), // oGrass
      (0.2 ,0.4 ,0.6 ,0.8 ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1), // oDebris
      (0.17,0.34,0.51,0.68,0.85,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1), // oTreeDry
      (0.06,0.12,0.18,0.24,0.3 ,0.36,0.42,0.48,0.54,0.6 ,0.66,0.72,0.78,0.84,0.9 ,0.96,1   ,1   ,1   ,1   ,1), // oTree
      (0.06,0.12,0.18,0.24,0.3 ,0.36,0.42,0.48,0.54,0.6 ,0.66,0.72,0.78,0.84,0.9 ,0.96,1   ,1   ,1   ,1   ,1), // oConifer
      (0.1 ,0.2 ,0.3 ,0.4 ,0.5 ,0.6 ,0.7 ,0.8 ,0.9 ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1), // oTreeTropical
      (0.25,0.5 ,0.75,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1), // oCactus
      (0.15,0.3 ,0.45,0.6 ,0.75,0.9 ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1), // oPalm
      (0.29,0.32,0.38,0.53,0.82,0.88,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1   ,1)  // oWaterTypes
    );
  );
  ObjectMix: array [TObjectMix] of array[TObjects] of Single = ( // Probability of mix for specific biome (for example the swamp have big probability of a reed but zero for a stone)
  // oStone oShrub  oBranch oMushro oFlower oGrass  oDebris oTreeDr oTree   oConife oTreeTr oCactus oPalm   oWaterTypes
    (0.4    ,0.4    ,0.4    ,0.4    ,0.5    ,9      ,1      ,1      ,1      ,1      ,1      ,1      ,1      ,1), // omStone
    (0.2    ,0.4    ,0.6    ,0.7    ,0.9    ,1      ,1      ,1      ,1      ,1      ,1      ,1      ,1      ,1), // omGrass
    (0      ,0      ,0.31   ,0.31   ,0.31   ,0.7    ,0.82   ,1      ,1      ,1      ,1      ,1      ,1      ,1), // omSwamp
    (0.27   ,0.27   ,0.43   ,0.7    ,0.7    ,0.7    ,0.81   ,1      ,1      ,1      ,1      ,1      ,1      ,1), // omGround
    (1      ,1      ,1      ,1      ,1      ,1      ,1      ,1      ,1      ,1      ,1      ,1      ,1      ,1), // omSnow
    (0.22   ,0.22   ,0.54   ,0.54   ,0.54   ,0.54   ,0.7    ,1      ,1      ,1      ,1      ,1      ,1      ,1), // omCoal
    (0.28   ,0.5    ,0.5    ,0.5    ,0.78   ,0.78   ,0.78   ,0.89   ,0.89   ,0.89   ,0.89   ,1      ,1      ,1), // omDesert
    (0      ,0      ,0      ,0      ,0      ,0      ,0      ,0      ,0      ,0      ,0      ,0      ,0      ,1), // omWater
    (0.3    ,0.3    ,0.3    ,0.3    ,0.5    ,1      ,1      ,1      ,1      ,1      ,1      ,1      ,1      ,1)  // omWetland
  );

  // Return number which represent specific (include variation)
  function GetObject(const obj: TObjects): Byte;
  var
    rnd: Single;
    K, Output: Byte;
  begin
    Output := 255;
    rnd := fRNG.Random();
    for K := Low( O.Probability[obj] ) to High( O.Probability[obj] ) do
      if rnd < O.Probability[obj,K] then begin
        Output := O.Objects[obj,K];
        break;
      end;
    Result := Output;
  end;

  // Return number which represent specific object
  function GetObjectFromMix(const ObjMixType: TObjectMix): Byte;
  var
    rnd: Single;
    K: TObjects;
    Output: Byte;
  begin
    Output := 255; // no object
    rnd := fRNG.Random();
    for K := Low(TObjects) to High(TObjects) do
      if rnd < ObjectMix[ ObjMixType , K ] then
      begin
        Output := GetObject(K);
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
  if (RMGSettings.Objects.ForestDensity > 0) then
  begin
    Minimum := KMPoint(1,1);
    Maximum.X := Max(fMapX - FOREST_RADIUS, Minimum.X + 1);
    Maximum.Y := Max(fMapY - FOREST_RADIUS, Minimum.Y + 1);
    forests := RNDPointsInGrid(fMapX*fMapY / sqr(4*(12-RMGSettings.Objects.ForestDensity)), 0, Minimum, Maximum);
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
			  X := Min(forests[cntForests].X + fRNG.RandomI(FOREST_RADIUS), fMapX-1);
			  Y := Min(forests[cntForests].Y + fRNG.RandomI(FOREST_RADIUS), fMapY-1);
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
    OBJ_DENSITY := 15 - RMGSettings.Objects.ObjectDensity; // If 0 is none; 1 must be small; 10 maximum -> invert it
    for Y := 1 to fMapY-1 do
    begin
      num := fRNG.RandomI(OBJ_DENSITY) + 1;
		  X := num + 1;
		  while X < fMapX do
      begin
        if (TilesPartsArr.Obj[Y,X] = 255) then
			    case A[Y,X] of
				    Byte(btStone):
              TilesPartsArr.Obj[Y,X] := GetObjectFromMix(omStone);

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
              //Tiles[K].Obj := GetObjectFromMix(omWater);

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
//function TKMRandomMapGenerator.TileTemplateCA(var A: TKMByte2Array; const Settings: Byte): TKMByte2Array;
//type
//  TileTemplateArr = array[0..2,0..2] of Integer;
//var
//   aX,aY, X0,X1,X2, Y0,Y1,Y2, Step, sum: Integer;
//   check: Boolean;
//   B: array of array of TileTemplateArr;
//   Vystup: TKMByte2Array;
//const
//  MAX_LAYER = 255;
//  canWalk: array[0..len_BIOME-1] of Boolean = (
//    True,True,False,False,False,True,True,True,True,True,True,False,True,True,True,True,True,True,False,False,False,False,False,False
//  );
//  TerrainPreference: array[0..len_BIOME-1,0..3] of Byte = (
//    (0,1,7,14),(0,1,7,14),(2,3,4,0),(2,3,4,0),(2,3,4,0),(5,6,8,12),(5,6,8,12),(0,1,7,14),(5,6,8,12),(8,9,10,255),(8,9,10,255),(4,255,255,255),(5,6,8,12),(13,15,16,17),(0,1,7,14),(13,15,16,17),(13,15,16,17),(13,15,16,17),(0,255,255,255),(19,20,255,255),(19,20,255,255),(21,22,255,255),(21,22,255,255),(21,22,255,255)
//  );
//
//  function ChooseMin(var A,B: Integer): Integer;
//  begin
//    if ((not canWalk[B] OR (A < B)) AND canWalk[A]) then
//      Result := A
//    else
//      Result := B;
//  end;
//
//  procedure ET3(var T1, T2, Base: Byte);
//  var
//    i: Integer;
//  begin
//    for i := Low(TerrainPreference[Base]) to High(TerrainPreference[Base]) do
//    begin
//      if (TerrainPreference[Base,i] = T1) then
//      begin
//        T2 := T1;
//        Exit;
//      end
//      else if (TerrainPreference[Base,i] = T2) then
//      begin
//        T1 := T2;
//        Exit;
//      end;
//    end;
//    if (not canWalk[T1] OR (T1 > T2)) AND canWalk[T2] then
//      T1 := T2
//    else
//      T2 := T1;
//  end;
//
//  procedure ET2(const bY,bX,invY,invX,TTA_Y1,TTA_X1,TTA_Y2,TTA_X2: Integer);
//  var
//    val,TTA_X,TTA_Y,X,Y: Integer;
//  begin
//    TTA_X := TTA_X1;
//    TTA_Y := TTA_Y2;
//    //{
//    if (B[Y1,X1,TTA_Y,TTA_X] = A[Y1,X1]) OR not canWalk[B[Y1,X1,TTA_Y,TTA_X]] then
//    begin
//      B[Y1,X1,TTA_Y,TTA_X] := ChooseMin(B[Y1,X1,1,TTA_X], B[Y1,X1,TTA_Y,1]);
//    end;
//    //}
//
//    B[Y1,X1,TTA_Y1,TTA_X2] := ChooseMin(B[Y1,bX,TTA_Y1,TTA_X1], B[bY,X1,TTA_Y2,TTA_X2]);
//    B[Y1,X1,TTA_Y2,TTA_X2] := B[Y1,bX,TTA_Y2,TTA_X1];
//    B[Y1,X1,TTA_Y1,TTA_X1] := B[bY,X1,TTA_Y2,TTA_X1];
//    B[Y1,X1,1,1] := step;
//
//    val := (Byte(B[Y1,X1,2,0] = B[Y1,X1,0,0]) shl 0) OR // Left
//           (Byte(B[Y1,X1,0,0] = B[Y1,X1,0,2]) shl 1) OR // Top
//           (Byte(B[Y1,X1,0,2] = B[Y1,X1,2,2]) shl 2) OR // Right
//           (Byte(B[Y1,X1,2,2] = B[Y1,X1,2,0]) shl 3);   // Down
//
//    {
//    if B[Y1,X1,TTA_Y,TTA_X] = A[Y1,X1] then
//    begin
//      if B[Y1,X1,TTA_Y,1] <> A[Y1,X1] then
//        B[Y1,X1,TTA_Y,TTA_X] := B[Y1,X1,TTA_Y,1]
//      else if B[Y1,X1,1,TTA_X] <> A[Y1,X1] then
//        B[Y1,X1,TTA_Y,TTA_X] := B[Y1,X1,1,TTA_X];
//    end;
//    //}
//
//
//    case val of
//    // 3-tiles transition
//      1: begin // Left %0001
//           if (TTA_X = 0) then
//           begin
//             TTA_X := 2;
//             if (ChooseMin(B[Y1,X1,0,2], B[Y1,X1,2,2]) = B[Y1,X1,2,2]) then
//               TTA_Y := 0
//             else
//               TTA_Y := 2;
//           end;
//           Y := abs(TTA_Y - 2); // from 0 it makes 2 and from 2 it makes 0
//           B[Y1,X1,TTA_Y,TTA_X] := ChooseMin(B[Y1,X1,0,0], B[Y1,X1,Y,2]);
//         end;
//      2: begin // Top %0010
//           if (TTA_Y = 0) then
//           begin
//             TTA_Y := 2;
//             if (ChooseMin(B[Y1,X1,2,0], B[Y1,X1,2,2]) = B[Y1,X1,2,2]) then
//               TTA_X := 0
//             else
//               TTA_X := 2;
//           end;
//           X := abs(TTA_X - 2); // from 0 it makes 2 and from 2 it makes 0
//           B[Y1,X1,TTA_Y,TTA_X] := ChooseMin(B[Y1,X1,0,0], B[Y1,X1,2,X]);
//         end;
//      4: begin // Right %0100
//           if (TTA_X = 2) then
//           begin
//             TTA_X := 0;
//             if (ChooseMin(B[Y1,X1,0,0], B[Y1,X1,2,0]) = B[Y1,X1,0,0]) then
//               TTA_Y := 2
//             else
//               TTA_Y := 0;
//           end;
//           Y := abs(TTA_Y - 2); // from 0 it makes 2 and from 2 it makes 0
//           B[Y1,X1,TTA_Y,TTA_X] := ChooseMin(B[Y1,X1,2,2], B[Y1,X1,Y,0]);
//         end;
//      8: begin // Down %1000
//           if (TTA_Y = 2) then
//           begin
//             TTA_Y := 0;
//             if (ChooseMin(B[Y1,X1,0,0], B[Y1,X1,0,2]) = B[Y1,X1,0,0]) then
//               TTA_X := 2
//             else
//               TTA_X := 0;
//           end;
//           X := abs(TTA_X - 2); // from 0 it makes 2 and from 2 it makes 0
//           B[Y1,X1,TTA_Y,TTA_X] := ChooseMin(B[Y1,X1,2,2], B[Y1,X1,0,X]);
//         end;
//    // 4-tiles transition
//      0: begin // None  %0000
//        // Special case where are 2 diagonal tiles same
//           if (B[Y1,X1,0,0] = B[Y1,X1,2,2]) then // 1 = 4
//           begin
//             B[Y1,X1,TTA_Y2,TTA_X1] := B[Y1,X1,0,0];
//           end
//           else if (B[Y1,X1,0,2] = B[Y1,X1,2,0]) then // 2 = 3
//           begin
//             if (B[Y1,X1,TTA_Y2,TTA_X1] <> B[Y1,X1,0,2]) then
//               B[Y1,X1,TTA_Y2,TTA_X1] := B[Y1,X1,0,2]
//             else
//             begin
//
//             end;
//           end;
//
//          // 4 different tiles
//          {
//            if check then
//            begin
//              B[Y1,X1] := Byte(btDark);
//              B[Y1,X2] := Byte(btDark);
//              B[Y2,X1] := Byte(btDark);
//              B[Y2,X2] := Byte(btDark);
//            end;
//            }
//          end;
//    end;
//  end;
//
//
//begin
//
//  SetLength(B, Length(A), Length(A[Low(A)]));
//  SetLength(Vystup, Length(A) shl 1, Length(A[Low(A)]) shl 1);
//
//	for Y1 := 1 to fMapY-1 do
//  begin
//    Y0 := Y1 - 1;
//		for X1 := 1 to fMapX-1 do
//    begin
//      X0 := X1 - 1;
//
//    // Detect 8 surrounding tiles and store ideal transition of each tile into B
//      //{
//      check := true;
//      for aY := 0 to 2 do
//        for aX := 0 to 2 do
//        begin
//          B[Y1,X1,aY,aX] := BT[ A[Y1,X1] , A[Y0+aY,X0+aX] ];
//          if (B[Y1,X1,aY,aX] <> -1) then
//            check := false
//          else
//            B[Y1,X1,aY,aX] := A[Y1,X1];
//        end;
//    // Store final value for no-transition tile
//      if check then
//        B[Y1,X1,1,1] := MAX_LAYER
//      else
//        B[Y1,X1,1,1] := -1;
//      //}
//    end;
//  end;
//
//  // Left and top edge of map
//  for Y1 := 1 to fMapY-1 do
//  begin
//    B[Y1,0,1,2] := BT[ A[Y1,0] , A[Y1,1] ];
//    if (B[Y1,0,1,2] = -1) then
//      B[Y1,0,1,2] := A[Y1,X1];
//    B[Y1,0,0,2] := B[Y1,0,1,2];
//    if (B[Y1,0,0,2] = -1) then
//      B[Y1,0,0,2] := A[Y1,X1];
//    B[Y1,0,2,2] := BT[ A[Y1,0] , A[Y1+1,1] ];
//    if (B[Y1,0,2,2] = -1) then
//      B[Y1,0,2,2] := A[Y1,X1];
//    B[Y1,0,1,1] := MAX_LAYER;
//  end;
//
//	for X1 := 1 to fMapX-1 do
//  begin
//      B[0,X1,2,1] := BT[ A[0,X1] , A[1,X1] ];
//      if (B[0,X1,2,1] = -1) then
//        B[0,X1,2,1] := A[Y1,X1];
//      B[0,X1,2,0] := B[0,X1,2,1];
//      if (B[0,X1,2,0] = -1) then
//        B[0,X1,2,0] := A[Y1,X1];
//      B[0,X1,2,2] := BT[ A[0,X1] , A[1,X1+1] ];
//      if (B[0,X1,2,2] = -1) then
//        B[0,X1,2,2] := A[Y1,X1];
//      B[0,X1,1,1] := MAX_LAYER;
//  end;
//
////{
//  for step := MAX_LAYER-1 downto MAX_LAYER-Settings do
//  begin
//	  for Y1 := 1 to fMapY-1 do
//    begin
//      Y0 := Y1 - 1;
//      Y2 := Y1 + 1;
//		  for X1 := 1 to fMapX-1 do
//      begin
//        if (B[Y1,X1,1,1] = -1) then
//        begin
//          X0 := X1 - 1;
//          X2 := X1 + 1;
//          sum := (Byte(B[Y1,X0,1,1] > step) shl 0) OR
//                 (Byte(B[Y0,X1,1,1] > step) shl 1) OR
//                 (Byte(B[Y1,X2,1,1] > step) shl 2) OR
//                 (Byte(B[Y2,X1,1,1] > step) shl 3);
//          case sum of
//          // 2 exist transitions
//            3: begin // Left Top %0011
//                ET2(Y0,X0,Y2,X2,0,2,2,0);
//               end;
//            6: begin // Right Top %0110
//                ET2(Y0,X2,Y2,X0,0,0,2,2);
//               end;
//            12:begin // Right Down %1100
//                ET2(Y2,X2,Y0,X0,2,0,0,2);
//               end;
//            9: begin // Left Down %1001
//                ET2(Y2,X0,Y0,X2,2,2,0,0);
//               end;
//          // 3 exist transitions
//            7: begin // Left Top Right %0111
//                B[Y1,X1,0,0] := ChooseMin(B[Y1,X0,0,2], B[Y0,X1,2,0]);
//                B[Y1,X1,0,2] := ChooseMin(B[Y1,X2,0,0], B[Y0,X1,2,2]);
//                B[Y1,X1,2,0] := B[Y1,X0,2,2];
//                B[Y1,X1,2,2] := B[Y1,X2,2,0];
//                B[Y1,X1,1,1] := step;
//               end;
//            13: begin // Left Down Right %1101
//                B[Y1,X1,2,0] := ChooseMin(B[Y1,X0,2,2], B[Y2,X1,0,0]);
//                B[Y1,X1,2,2] := ChooseMin(B[Y1,X2,2,0], B[Y2,X1,0,2]);
//                B[Y1,X1,0,0] := B[Y1,X0,0,2];
//                B[Y1,X1,0,2] := B[Y1,X2,0,0];
//                B[Y1,X1,1,1] := step;
//               end;
//            14: begin // Top Right Down %1110
//                B[Y1,X1,0,2] := ChooseMin(B[Y0,X1,2,2], B[Y1,X2,0,0]);
//                B[Y1,X1,2,2] := ChooseMin(B[Y2,X1,0,2], B[Y1,X2,2,0]);
//                B[Y1,X1,0,0] := B[Y0,X1,2,0];
//                B[Y1,X1,2,0] := B[Y2,X1,0,0];
//                B[Y1,X1,1,1] := step;
//               end;
//            11: begin // Top Left Down %1011
//                B[Y1,X1,0,0] := ChooseMin(B[Y0,X1,2,0], B[Y1,X0,0,2]);
//                B[Y1,X1,2,0] := ChooseMin(B[Y2,X1,0,0], B[Y1,X0,2,2]);
//                B[Y1,X1,0,2] := B[Y0,X1,2,2];
//                B[Y1,X1,2,2] := B[Y2,X1,0,2];
//                B[Y1,X1,1,1] := step;
//               end;
//          // 4 exist transitions
//            15: begin // Left down %1001
//                B[Y1,X1,0,0] := ChooseMin(B[Y1,X0,0,2], B[Y0,X1,2,0]);
//                B[Y1,X1,0,2] := ChooseMin(B[Y1,X2,0,0], B[Y0,X1,2,2]);
//                B[Y1,X1,2,2] := ChooseMin(B[Y1,X2,2,0], B[Y2,X1,0,2]);
//                B[Y1,X1,2,0] := ChooseMin(B[Y1,X0,2,2], B[Y2,X1,0,0]);
//                B[Y1,X1,1,1] := step;
//               end;
//            else begin   end;
//          end;
//
//
//        end;
//      end;
//    end;
//  end;
//  //}
//
//	for Y1 := 1 to fMapY-1 do
//  begin
//    Y0 := Y1 - 1;
//    Y2 := Y1 + 1;
//    for X1 := 1 to fMapX-1 do
//    begin
//      {
//      X0 := X1 - 1;
//      X2 := X1 + 1;
//      Vystup[Y1<<1,X1<<1] := ChooseMin(B[Y1,X0,0,2], B[Y0,X1,2,0]);
//      Vystup[Y1<<1,(X1<<1)+1] := ChooseMin(B[Y1,X2,0,0], B[Y0,X1,2,2]);
//      Vystup[(Y1<<1)+1,(X1<<1)+1] := ChooseMin(B[Y1,X2,2,0], B[Y2,X1,0,2]);
//      Vystup[(Y1<<1)+1,X1<<1] := ChooseMin(B[Y1,X0,2,2], B[Y2,X1,0,0]);
//      }
//      //{
//      if (B[Y1,X1,1,1] > -1) then
//      begin
//        Vystup[Y1 shl 1,X1 shl 1] := B[Y1,X1,0,0];
//        Vystup[Y1 shl 1,(X1 shl 1)+1] := B[Y1,X1,0,2];
//        Vystup[(Y1 shl 1)+1,(X1 shl 1)+1] := B[Y1,X1,2,2];
//        Vystup[(Y1 shl 1)+1,X1 shl 1] := B[Y1,X1,2,0];
//      end
//      else
//      begin
//        Vystup[Y1 shl 1,X1 shl 1] := Byte(btSnow2);
//        Vystup[Y1 shl 1,X1 shl 1+1] := Byte(btSnow2);
//        Vystup[Y1 shl 1+1,X1 shl 1+1] := Byte(btSnow2);
//        Vystup[Y1 shl 1+1,X1 shl 1] := Byte(btSnow2);
//      end;
//      //}
//    end;
//  end;
//  {
//  if (Settings > 4) then
//  begin
//	for Y1 := 1 to fMapY-1 do
//		for X1 := 1 to fMapX-1 do
//    begin
//      if (B[Y1,X1,0,0] < 0) then
//        B[Y1,X1,0,0] := Byte(btDark);
//      if (B[Y1,X1,0,2] < 0) then
//        B[Y1,X1,0,2] := Byte(btDark);
//      if (B[Y1,X1,2,0] < 0) then
//        B[Y1,X1,2,0] := Byte(btDark);
//      if (B[Y1,X1,2,2] < 0) then
//        B[Y1,X1,2,2] := Byte(btDark);
//      Vystup[Y1<<1,X1<<1] := B[Y1,X1,0,0];
//      Vystup[Y1<<1,(X1<<1)+1] := B[Y1,X1,0,2];
//      Vystup[(Y1<<1)+1,(X1<<1)+1] := B[Y1,X1,2,2];
//      Vystup[(Y1<<1)+1,X1<<1] := B[Y1,X1,2,0];
//    end;
//  end;
//    end;
//    end;
//  //}
//  Result := Vystup;
//end;



// Old version of TileTemplate (version with CA and actual version provides better results)
//function TKMRandomMapGenerator.TileTemplateOLD(var A: TKMByte2Array; const Settings: Byte): TKMByte2Array;
//var
//   aX,aY,Y, X, X0,X1,X2,Y0,Y1,Y2,cross: Integer;
//   check: Boolean;
//   B: TKMByte2Array;
//   BArr: array[0..2,0..2] of Integer;
//const
//  canWalk: array[0..len_BIOME-1] of Boolean = (
//    True,True,False,False,False,True,True,True,True,True,True,False,True,True,True,True,True,True,False,False,False,False,False,False
//  );
//  TerrainPreference: array[0..len_BIOME-1,0..3] of Byte = (
//    (0,1,7,14),(0,1,7,14),(2,3,4,0),(2,3,4,0),(2,3,4,0),(5,6,8,12),(5,6,8,12),(0,1,7,14),(5,6,8,12),(8,9,10,255),(8,9,10,255),(4,255,255,255),(5,6,8,12),(13,15,16,17),(0,1,7,14),(13,15,16,17),(13,15,16,17),(13,15,16,17),(0,255,255,255),(19,20,255,255),(19,20,255,255),(21,22,255,255),(21,22,255,255),(21,22,255,255)
//  );
//
//  function IdealTransitions(var T1, T2, Corner: Integer; var Original: Byte): Byte;
//  begin
//    if (T1 <> -1) AND (T2 <> -1) then
//    begin
//      if      (T1 = Corner) then Result := Corner
//      else if (T2 = Corner) then Result := Corner
//      else if (T1 < T2) then     Result := T1
//      else                       Result := T2;
//    end
//    else if (T1 <> -1) then      Result := T1
//    else if (T2 <> -1) then      Result := T2
//    else if (Corner <> -1) then  Result := Corner
//    else                         Result := Original;
//  end;
//
//  function GetSameTile(var Tile: Byte; Arr: array of Integer): Boolean;
//  var
//    i,j: Integer;
//  begin
//    Result := false;
//    for i := Low(Arr) to High(Arr)-1 do
//    begin
//      Tile := Arr[I];
//      for j := i+1 to High(Arr) do
//        if (Tile = Arr[j]) then
//        begin
//          Result := true;
//          Exit;
//        end;
//    end;
//  end;
//
//  procedure ThreeTilesTransition(var T1, T2, Base: Byte);
//  var
//    i: Integer;
//  begin
//    for i := Low(TerrainPreference[Base]) to High(TerrainPreference[Base]) do
//    begin
//      if (TerrainPreference[Base,i] = T1) then
//      begin
//        T2 := T1;
//        Exit;
//      end
//      else if (TerrainPreference[Base,i] = T2) then
//      begin
//        T1 := T2;
//        Exit;
//      end;
//    end;
//    if (not canWalk[T1] OR (T1 > T2)) AND canWalk[T2] then
//      T1 := T2
//    else
//      T2 := T1;
//  end;
//
//begin
//
//  SetLength(B, High(A) shl 1, High(A[Low(A)]) shl 1);
//
//// Surrounding tiles detection
//// Shortcuts (orientation in array A):
////    _____________________________
////   | [Y0,X0]   [Y0,X1]   [Y0,X2] |
////   | [Y1,X0]   [Y1,X1]   [Y1,X2] |    where [Y1,X1] is center point which will be modified
////   | [Y2,X0]   [Y2,X1]   [Y2,X2] |
////    —————————————————————————————
//	for Y1 := 1 to fMapY-1 do
//  begin
//    Y0 := Y1 - 1;
//    Y2 := Y1 + 1;
//    Y := Y1 shl 1;
//		for X1 := 1 to fMapX-1 do
//    begin
//      X0 := X1 - 1;
//      X2 := X1 + 1;
//      X := X1 shl 1;
//
//    // Detect 8 surrounding tiles and store ideal transition of each tile into BArr
//      for aY := 0 to 2 do
//        for aX := 0 to 2 do
//        begin
//          if (BT[ A[Y1,X1] , A[aY+Y0,aX+X0] ] <> -1) then // Transitions
//            BArr[aY,aX] := BT[ A[Y1,X1] , A[aY+Y0,aX+X0] ]
//          else // No transitions
//            BArr[aY,aX] := -1;
//        end;
//
//    // Select 4 ideal transitions from BArr
//      // Left top
//      B[Y,X] := IdealTransitions(BArr[0,1], BArr[1,0], BArr[0,0], A[Y1,X1]);
//      // Right top
//      X := X + 1;
//      B[Y,X] := IdealTransitions(BArr[0,1], BArr[1,2], BArr[0,2], A[Y1,X1]);
//      // Right down
//      Y := Y + 1;
//      B[Y,X] := IdealTransitions(BArr[2,1], BArr[1,2], BArr[2,2], A[Y1,X1]);
//      // Left down
//      X := X - 1;
//      B[Y,X] := IdealTransitions(BArr[2,1], BArr[1,0], BArr[2,0], A[Y1,X1]);
//      Y := Y - 1;
//    end;
//  end;
//
//
//  if (Settings > 2) then
//  begin
//
//
//
//
//  for Y1 := 1 to High(B)-1 do
//  begin
//    Y0 := Y1 - 1;
//    Y2 := Y1 + 1;
//		for X1 := 1 to High(B[Y1])-1 do
//    begin
//      X0 := X1 - 1;
//      X2 := X1 + 1;
//      // Non-accessible texture fix (edge of water)
//      if not canWalk[ B[Y1,X1] ] then
//      begin
//        if canWalk[ B[Y0,X1] ] AND canWalk[ B[Y2,X1] ] then
//        begin
//          if (B[Y0,X1] < B[Y2,X1]) then
//            B[Y1,X1] := B[Y0,X1]
//          else
//            B[Y1,X1] := B[Y2,X1];
//          //if canWalk[ A[Y1 >> 1,X1 >> 1] ] then
//          //  B[Y1,X1] := A[Y1 >> 1,X1 >> 1]
//          //else if ((Y1 mod 2) = 0) then
//          //  B[Y1,X1] := B[Y0,X1]
//          //else
//          //  B[Y1,X1] := B[Y2,X1];
//        end
//        else if canWalk[ B[Y1,X0] ] AND canWalk[ B[Y1,X2] ] then
//        begin
//          if (B[Y1,X0] < B[Y1,X2]) then
//            B[Y1,X1] := B[Y1,X0]
//          else
//            B[Y1,X1] := B[Y1,X2];
//        //  if canWalk[ A[Y1 >> 1,X1 >> 1] ] then
//        //    B[Y1,X1] := A[Y1 >> 1,X1 >> 1]
//        //  else if ((X1 mod 2) = 0) then
//        //    B[Y1,X1] := B[Y1,X0]
//        //  else
//        //    B[Y1,X1] := B[Y1,X2];
//        end;
//      end
//      // Problems which are caused by two tiles transitions
//      else
//      if (B[Y1,X0] = B[Y1,X2]) AND (B[Y1,X1] <> B[Y1,X0]) AND canWalk[ B[Y1,X0] ] then // Vertical problem
//        B[Y1,X1] := B[Y1,X0]
//      else if (B[Y0,X1] = B[Y2,X1]) AND (B[Y1,X1] <> B[Y0,X1]) AND canWalk[ B[Y0,X1] ] then // Horizontal problem
//        B[Y1,X1] := B[Y0,X1];
//      // Single point of different tile (in comparison with surrounding tiles)
//      if (B[Y1,X1] <> B[Y0,X1]) AND (B[Y1,X1] <> B[Y2,X1]) AND (B[Y1,X1] <> B[Y1,X0]) AND (B[Y1,X1] <> B[Y1,X2]) then
//      begin
//        GetSameTile(B[Y1,X1], [ B[Y0,X1],B[Y2,X1],B[Y1,X0],B[Y1,X2] ]);
//      end;
//    end;
//  end;
//  //}
//
//
//// Shortcuts:
////    _______                 ___________________
////   | 1   2 |  is equal to  | [Y1,X1]   [Y1,X2] |
////   | 3   4 |               | [Y2,X1]   [Y2,X2] |
////    ———————                 ———————————————————
//// Transitions:
////    ______________     ____________     _______________
////   | 1 › top  ‹ 2 |   | 1 › $2 ‹ 2 |   | 1 › %0010 ‹ 2 |
////   | ˇ          ˇ |   | ˇ        ˇ |   | ˇ           ˇ |
////   | left   right |   | $1      $4 |   | %0001   %0100 |
////   | ^          ^ |   | ^        ^ |   | ^           ^ |
////   | 3 › down ‹ 4 |   | 3 › $8 ‹ 4 |   | 3 › %1000 ‹ 4 |
////    ——————————————     ————————————     ———————————————
//
//  if (Settings > 3) then
//  begin
////{
//  Y1 := 0;
//  while Y1 < High(B)-2 do
//  begin
//    Y1 := Y1 + 2;
//    Y2 := Y1 + 1;
//    X1 := 0;
//  	while X1 < High(B[Y1])-2 do
//    begin
//      X1 := X1 + 2;
//      X2 := X1 + 1;
//      cross := 0;
//  	  if (B[Y1,X1] <> B[Y2,X1]) then cross := cross OR $1;// Left
//  	  if (B[Y1,X1] <> B[Y1,X2]) then cross := cross OR $2;// Top
//  	  if (B[Y1,X2] <> B[Y2,X2]) then cross := cross OR $4;// Right
//  	  if (B[Y2,X1] <> B[Y2,X2]) then cross := cross OR $8;// Down
//
//      case cross of
//      // 3-tiles transition
//        14: ThreeTilesTransition(B[Y1,X2], B[Y2,X2], B[Y1,X1]); // Left  %1110
//        13: ThreeTilesTransition(B[Y2,X1], B[Y2,X2], B[Y1,X1]); // Top   %1101
//        11: ThreeTilesTransition(B[Y2,X1], B[Y1,X1], B[Y2,X2]); // Right %1011
//        7:  ThreeTilesTransition(B[Y1,X2], B[Y1,X1], B[Y2,X2]); // Down  %0111
//      // 4-tiles transition
//        15: begin
//            // Special case where are 2 diagonal tiles same
//              check := false;
//              if (B[Y1,X1] = B[Y2,X2]) then // 1 = 4
//              begin
//                if not canWalk[ B[Y1,X2] ] then
//                  B[Y1,X2] := B[Y1,X1] // 2 := 1
//                else if not canWalk[ B[Y2,X1] ] then
//                  B[Y2,X1] := B[Y1,X1] // 3 := 1
//                else
//                   check := true;
//              end
//              else if (B[Y2,X1] = B[Y1,X2]) then // 2 = 3
//              begin
//                if not canWalk[ B[Y1,X1] ] then
//                  B[Y1,X1] := B[Y2,X1] // 1 := 2
//                else if not canWalk[ B[Y2,X2] ] then
//                  B[Y2,X2] := B[Y2,X1] // 4 := 2
//                else
//                   check := true;
//              end
//              else
//                check := true;
//
//            // 4 different tiles
//              if check then
//              begin
//                B[Y1,X1] := Byte(btDark);
//                B[Y1,X2] := Byte(btDark);
//                B[Y2,X1] := Byte(btDark);
//                B[Y2,X2] := Byte(btDark);
//              end;
//            end;
//        else
//        begin
//        end;
//
//      end;
//    end;
//  end;
//  //}
//  end;
//  end;
//
//
//  Result := B;
//end;



// JUNK
{
{
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
      if (Y < fMapY-1) then MinerFixFloodSearch(Y+1,X);
      if (Y > 1)               then MinerFixFloodSearch(Y-1,X);
      if (X < fMapX-1) then MinerFixFloodSearch(Y,X+1);
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
  MAX_MINE_DIST_COEF := MinMineSize + 1;
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
        minPosition := fMapY;
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
// Resources and INACCESSIBLE texture generator
// aLocs = estimated player's positions
// A = array to fill resources / obstacles
// Result = TBalancedResource1Array = array of shapes which represents resources (each shape have its own count of resources and points which were get from Voronoi diagram)
//          Cellular automaton can change shapes so it is important to keep more points to secure that every shape will have its resources in GenerateTiles
function TKMRandomMapGenerator.CreateResources(aLocs: TKMPointArray; var A: TKMByte2Array): TBalancedResource1Array;
var
  X,Y,Loc,I,K,overflow,cntADD, ALL_RES_RADIUS, CENTER_RES, cntFINAL, cntACTUAL, RESOURCE: Integer;
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
        Points := RNDPointsInGrid(3, CENTER_RES, TP_S, TP_E);
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
            cntFINAL := ResTilesAmount[I];
            cntACTUAL := 0;
            cntADD := 0;
            TP_S := KMPoint(  Max(Points[I].X - SPEC_RES_RADIUS[I], 1), Max(Points[I].Y - SPEC_RES_RADIUS[I], 1)  );
            TP_E := KMPoint(  Min(Points[I].X + SPEC_RES_RADIUS[I], High(PointsArr[0]) - 1), Min(Points[I].Y + SPEC_RES_RADIUS[I], High(PointsArr) - 1)  );
          // Create new "mountain" of resources
            overflow := 0;
            while (cntACTUAL < cntFINAL) AND (overflow < 10) do
            begin
              overflow := overflow + 1;
            // Find unused shape
              Points[I] := KMPoint(  TP_S.X + fRNG.RandomI(TP_E.X-TP_S.X), TP_S.Y + fRNG.RandomI(TP_E.Y-TP_S.Y)  );
              if (Count[Points[I].Y,Points[I].X] > 0) then
              begin
                SetLength(Output, Length(Output)+1); // Just a few interation so SetLength is fine
              // Merge shapes from Voronoi until we reach desired size
                FillResource.FloodFillWithQueue(Points[I].X, Points[I].Y, cntFINAL, cntACTUAL, RESOURCE, 1, PROB_REDUCER, Output[ High(Output) ].Points);
                Output[ High(Output) ].Quantity := Round( (Min(cntFINAL, cntACTUAL) - cntADD) / Max(1,cntFINAL) * ResAmount[I]);
                Output[ High(Output) ].Resource := RESOURCE;
                cntADD := cntACTUAL;
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
      SetLength(Visited, fMapY+1, fMapX+1);
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
function TKMRandomMapGenerator.RNDPointsInGridBF(const cnt: Integer; Minimum,Maximum: TKMPoint): TKMPointArray;
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
  SetLength(Dist, fMapY >> 4, fMapX >> 4); // division by 16 will increase speed (size of map is always 16*x, x = <2,16>)
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
    Result[LocNum].X := Min(X << 4 + fRNG.RandomI(16), fMapX-1);
    Result[LocNum].Y := Min(Y << 4 + fRNG.RandomI(16), fMapY-1);
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
  TT: array[0..len_BIOME-1,0..len_BIOME-1,0..5] of Byte = ( // Textures of transitions + direction set
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
  FT: array[0..len_BIOME-1,0..20] of Byte = ( // Full textures + variance
    (0,0,0,0,1,1,1,2,2,2,3,3,3,5,5,6,6,13,14,0,19),(8,8,8,9,9,9,11,0,0,0,0,0,0,0,0,0,0,0,0,0,7),
    (48,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1),(40,40,41,41,42,42,43,0,0,0,0,0,0,0,0,0,0,0,0,0,7),
    (192,192,192,193,193,196,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6),(34,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1),
    (35,36,37,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3),(17,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2),
    (47,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1),(46,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1),
    (45,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1),(44,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1),
    (155,155,155,154,153,153,153,152,0,0,0,0,0,0,0,0,0,0,0,0,8),(31,32,32,32,33,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5),
    (26,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1),(27,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1),
    (28,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1),(29,29,30,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3),
    (128,129,130,131,132,133,134,135,136,137,0,0,0,0,0,0,0,0,0,0,10),(144,145,146,146,147,147,147,0,0,0,0,0,0,0,0,0,0,0,0,0,7),
    (156,157,158,159,201,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5),(148,149,150,150,151,151,151,151,0,0,0,0,0,0,0,0,0,0,0,0,8),
    (160,161,162,163,164,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5),(245,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1)
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
	for Y1 := 1 to fMapY-1 do begin
		Y0 := Y1-1; Y2 := Y1+1;
		for X1 := 1 to fMapX-1 do begin
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
  cntFINAL, cntACTUAL, RESOURCE: Integer;
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
    while not IsQueueEmpty AND (cnt_actual < cntFINAL) do
    begin
      RemoveFromQueue(X, Y, Probability);
      if (Count[Y,X] <> 0) AND (cnt_actual < cntFINAL) AND (fRNG.Random() < (probability * P[Y,X])) then
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
  procedure InacessibleTextures(const RES, COUNT, basePOINTS, variance_POINTS, cntFIN: Integer; const probREDUC, BASE_PROBABILITY: Single);
  var
    i,j,len: Integer;
    TP_S,TP_E: TKMPoint;
    CenterPoints, Point: TKMPointArray;
  begin
    RESOURCE := RES;
    PROB_REDUCER := probREDUC;
    cntFINAL := cntFIN;
    TP_S.X := 1;
    TP_S.Y := 1;
    TP_E.X := High(PointsArr[0])-1;
    TP_E.Y := High(PointsArr)-1;
    CenterPoints := RNDPointsInGrid(COUNT, 0, TP_S, TP_E);
    for i := Low(CenterPoints) to High(CenterPoints) do
    begin
      if BASE_PROBABILITY < fRNG.Random() then
        continue;
      TP_S := CenterPoints[I];
      len := 9 - fRNG.RandomI(9);
      TP_E.X := Min(High(PointsArr[0]), CenterPoints[I].X + len);
      TP_E.Y := Min(High(PointsArr), CenterPoints[I].Y + 10 - len);
      Point := RNDPointsInGrid(basePOINTS+fRNG.RandomI(variance_POINTS), 0, TP_S, TP_E);
      for j := Low(Point) to High(Point) do
      begin
        cntACTUAL := 0;
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
    //Locs := RNDPointsInGrid(PLAYERS, MIN_PL_DISTANCE, TP_Start, TP_End);
    Locs := RNDPointsInGridBF(PLAYERS, MIN_PL_DISTANCE, TP_Start, TP_End);
    for Loc := 0 to PLAYERS-1 do
    begin
      TP_Start.X := Locs[Loc].X;
      TP_Start.Y := Locs[Loc].Y;
      TP_End.X := Locs[Loc].X + ALL_RES_RADIUS;
      TP_End.Y := Locs[Loc].Y + ALL_RES_RADIUS;
      Points := RNDPointsInGrid(3, CENTER_RES, TP_Start, TP_End);
      SetLength(Points,Length(Points)+2);
      Points[3] := Points[1];
      Points[4] := Points[2];
      for i := Low(ResAmount) to High(ResAmount) do
        if ResAmount[I] > 0 then
        begin
          Quantity := ResAmount[I];// << (3*Byte(Resources[I]=btStone));    //BALANCE IT !!!!!!!!!!!!!!
          Tiles := Quantity >> 1;
          cntFINAL := Tiles;
          cntACTUAL := 0;
          RESOURCE := Byte(Resources[I]);
          PROB_REDUCER := RES_PROB[I];
          TP_Start.X := Max(Points[I].X - SPEC_RES_RADIUS[I], 1);
          TP_Start.Y := Max(Points[I].Y - SPEC_RES_RADIUS[I], 1);
          TP_End.X := Min(Points[I].X + SPEC_RES_RADIUS[I], High(PointsArr[0]) - 1);
          TP_End.Y := Min(Points[I].Y + SPEC_RES_RADIUS[I], High(PointsArr) - 1);
          overflow := 0;
          while (cntACTUAL < cntFINAL) AND (overflow < 10) do
          begin
            overflow := overflow + 1;
            if Count[Points[I].Y,Points[I].X] <> 0 then
            begin
              FloodFillWithQueue(Points[I].X, Points[I].Y, 1);
              SetLength(Result, Length(Result)+1); // Just a few interation so SetLength is fine
              idx := High(Result);
              Result[idx].Point := PointsArr[Points[I].Y,Points[I].X];
              Result[idx].Quantity := Round(cntFINAL / Max(1,Min(cntFINAL, cntACTUAL)) * Quantity);
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
  SetLength(Visited,fMapY,fMapX);
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
  SetLength(Result, fMapY+1, fMapX+1);
  SetLength(History, fMapY+1, fMapX+1);
  SetLength(Points, RoundUP((fMapY-1) / (Step*1.0)), RoundUP((fMapX-1) / (Step*1.0)));
  for Y := Low(Result) to High(Result) do
    for X := Low(Result[Y]) to High(Result[Y]) do
    begin
      History[Y,X] := 0;
      Result[Y,X] := 0;
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
      Points[idxY,idxX].Y := Min(fMapY-1, Y + fRNG.RandomI(Step));
      Points[idxY,idxX].X := Min(fMapX-1, X + fRNG.RandomI(Step));
      Y1 := Points[idxY,idxX].Y;
      X1 := Points[idxY,idxX].X;
      move := 0;
      price := Step;
      while move < Step do
      begin
        Y0 := Max(1, Y1 - move);
        X0 := Max(1, X1 - move);
        Y2 := Min(fMapY-1, Y1 + move);
        X2 := Min(fMapX-1, X1 + move);
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
