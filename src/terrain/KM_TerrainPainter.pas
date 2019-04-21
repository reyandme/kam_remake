unit KM_TerrainPainter;
{$I KaM_Remake.inc}
interface
uses
  Classes, KromUtils, Math, SysUtils,
  KM_CommonClasses, KM_Defaults, KM_Points,
  KM_Terrain, KM_ResTileset;

const
  MAX_UNDO = 50;

type
  //Tile data that we store in undo checkpoints
  TKMUndoTile = packed record
    BaseLayer: TKMTerrainLayer;
    LayersCnt: Byte;
    Layer: array [0..2] of TKMTerrainLayer;
    Height: Byte;
    Obj: Byte;
    IsCustom: Boolean;
    TerKind: TKMTerrainKind;
    Tiles: SmallInt;
    HeightAdd: Byte;
  end;

  TKMPainterTile = packed record
    TerKind: TKMTerrainKind; //Stores terrain type per node
    Tiles: SmallInt;  //Stores kind of transition tile used, no need to save into MAP footer
    HeightAdd: Byte; //Fraction part of height, for smooth height editing
  end;

  //Terrain helper that is used to paint terrain types in Map Editor
  TKMTerrainPainter = class
  private
    fUndoPos: Byte;
    fUndos: array [0..MAX_UNDO-1] of record
      HasData: Boolean;
      Data: array of array of TKMUndoTile;
    end;
    fTime: array[0..12] of record
      Desc: String;
      Data: Cardinal;
    end;

    // Temp data, do not saved
    fUseTempLand: Boolean;
    fReplaceLayers: Boolean;
    fBrushAreaTerKindCnt: Integer;
    fBrushAreaTerKind: array of TKMPoint;
    fTempLand: array of array of TKMTerrainTileBasic;

    fMapXn, fMapYn: Integer; //Cursor position node
    fMapXc, fMapYc: Integer; //Cursor position cell

    function BrushAreaTerKindContains(aCell: TKMPoint): Boolean;
    function GetVertexCornerTerKinds(X,Y: Word): TKMTerrainKindsArray;
    function GetTileOwnCornersTKinds(aCell: TKMPoint): TKMTerrainKindsArray;
    function GetTileLandNodeTKinds(aCell: TKMPoint): TKMTerrainKindsArray;
    function GetTileCornersTKinds(aCell: TKMPoint; aGetOnlyTileCornersTK: Boolean = False; aGetOnlyLandNodeTK: Boolean = False): TKMTerrainKindsArray;
    procedure CheckpointToTerrain;
    procedure BrushTile(const X, Y: Integer);
    procedure BrushTerrainTile(const X, Y: Integer; aTerKind: TKMTerrainKind);
    procedure MagicBrush(const X,Y: Integer);
    procedure UseMagicBrush(X,Y,aSize: Integer; aSquare: Boolean; aAroundTiles: Boolean = False);
    procedure UpdateTempLand;
    procedure EditBrush;
    procedure EditHeight;
    procedure EditTile(const aLoc: TKMPoint; aTile: Word; aRotation: Byte; aIsCustom: Boolean = True);
    procedure GenerateAddnData;
    procedure InitSize(X,Y: Word);
    function GetTerKind(aTKValue: Integer; aUseKamFormat: Boolean): TKMTerrainKind;

    function IsTerrainRepresentTerKind(aTerId: Word; aTerKind: TKMTerrainKind): Boolean;

    procedure RebuildTile(const X,Y: Integer);
  public
    LandTerKind: array of array of TKMPainterTile;
    RandomizeTiling: Boolean;
    ForcePaint: Boolean;
    procedure InitEmpty;

    procedure LoadFromFile(const aFileName: UnicodeString);
    procedure SaveToFile(const aFileName: UnicodeString); overload;
    procedure SaveToFile(const aFileName: UnicodeString; const aInsetRect: TKMRect); overload;

    procedure Eyedropper(const aLoc: TKMPoint);
    procedure RotateTile(const aLoc: TKMPoint);
    procedure MagicWater(const aLoc: TKMPoint);

    procedure RMG2MapEditor(X,Y: Integer; aTile: Word);
    procedure RebuildMap(X,Y,aSize: Integer; aSquare: Boolean; aAroundTiles: Boolean = False); overload;
    procedure RebuildMap(const aRect: TKMRect); overload;
    function PickRandomTile(aTerrainKind: TKMTerrainKind): Word;

    procedure FixTerrainKindInfo;

    class function GetRandomTile(aTerrainKind: TKMTerrainKind; aSkipRandom: Boolean = False): Word;

    function CanUndo: Boolean;
    function CanRedo: Boolean;

    procedure MakeCheckpoint;
    procedure Undo;
    procedure Redo;

    procedure UpdateStateIdle;
    procedure UpdateState;
  end;


const
  //Table of combinations between terrain types (0-based)
  //1 - no transition
  //2 - in half
  //3 - one corner
  //"-" means flip before use
  Combo: array [TKMTerrainKind, TKMTerrainKind, 1..3] of SmallInt = (
  //             Custom    Grass         Moss   PaleGrass        CoastSand      GrassSand1  GrassSand2      GrassSand3          Sand    GrassDirt     Dirt           Cobblest        GrassyWater   Swamp        Ice          ShallowSnow    Snow           DeepSnow     StoneMount       GoldMount        IronMount         Abyss          Gravel        Coal               Gold             Iron           Water           FastWater    Lava
  {Custom}     ((0,0,0),(  0,   0,  0),(0,0,0),(  0,  0,  0),(    0,   0,   0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(  0,    0,    0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Custom
  {Grass}      ((0,0,0),(  0,   0,  0),(0,0,0),(  0,  0,  0),(    0,   0,   0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(  0,    0,    0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Grass
  {Moss}       ((0,0,0),(-19, -18,  9),(8,8,8),(  0,  0,  0),(    0,   0,   0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(  0,    0,    0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Moss
  {PaleGrass}  ((0,0,0),( 66,  67, 68),(0,0,0),( 17, 17, 17),(    0,   0,   0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(  0,    0,    0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //PaleGrass
  {CoastSand}  ((0,0,0),( 69,  70, 71),(0,0,0),(  0,  0,  0),(   32,  32,  32),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(  0,    0,    0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //CoastSand
  {GrassSand1} ((0,0,0),( 72,  73, 74),(0,0,0),(  0,  0,  0),(    0,   0,   0),(26,26,26),(   0,   0,   0),(  0,  0,  0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(  0,    0,    0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //GrassSand1
  {GrassSand2} ((0,0,0),(  0,   0,  0),(0,0,0),(  0,  0,  0),(  102, 103, 104),(75,76,77),(  27,  27,  27),(  0,  0,  0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(  0,    0,    0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //GrassSand2
  {GrassSand3} ((0,0,0),( 93,  94, 95),(0,0,0),(  0,  0,  0),(    0,   0,   0),( 0, 0, 0),(  78,  79,  80),( 28, 28, 28),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(  0,    0,    0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //GrassSand3
  {Sand}       ((0,0,0),(  0,   0,  0),(0,0,0),(  0,  0,  0),(   99, 100, 101),( 0, 0, 0),(  81,  82,  83),( 81, 82, 83),( 29, 29, 29),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(  0,    0,    0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Sand
  {GrassDirt}  ((0,0,0),( 84,  85, 86),(0,0,0),(-98,-97,-96),(    0,   0,   0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(  0,  0,  0),(34,34,34),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(  0,    0,    0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //GrassDirt
  {Dirt}       ((0,0,0),( 56,  57, 58),(0,0,0),(  0,  0,  0),( -113,-112,-111),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(  0,  0,  0),(87,88,89),(  35,  35,  35),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(  0,    0,    0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Dirt
  {Cobblest}   ((0,0,0),(  0,   0,  0),(0,0,0),(  0,  0,  0),(    0,   0,   0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(  0,  0,  0),( 0, 0, 0),(  38,  39, 215),( 215, 215, 215),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(  0,    0,    0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Cobblestone
  {GrassyWater}((0,0,0),(120, 121,122),(0,0,0),(  0,  0,  0),(    0,   0,   0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),( 48, 48, 48),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(  0,    0,    0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //GrassyWater
  {Swamp}      ((0,0,0),( 90,  91, 92),(0,0,0),(  0,  0,  0),(    0,   0,   0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(40,40,40),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(  0,    0,    0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Swamp
  {Ice}        ((0,0,0),(  0,   0,  0),(0,0,0),(  0,  0,  0),(    0,   0,   0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),( 44, 44, 44),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(  0,    0,    0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Ice
  {ShallowSnow}((0,0,0),(  0,   0,  0),(0,0,0),(  0,  0,  0),(    0,   0,   0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(  0,  0,  0),( 0, 0, 0),( 247,  64,  65),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),( 47, 47,  47),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(  0,    0,    0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //ShallowSnow
  {Snow}       ((0,0,0),(  0,   0,  0),(0,0,0),(  0,  0,  0),(    0,   0,   0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),( 44, -4,-10),(220,212, 213),( 46, 46, 46),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(  0,    0,    0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Snow
  {DeepSnow}   ((0,0,0),(  0,   0,  0),(0,0,0),(  0,  0,  0),(    0,   0,   0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(203,204,205),(45,45,45),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(  0,    0,    0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //DeepSnow
  {StoneMount} ((0,0,0),(274, 139,138),(0,0,0),(  0,  0,  0),(  273, 269, 268),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(273,269,268),( 0, 0, 0),( 282, 278, 277),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(298,294, 293),(290,286,285),( 0, 0, 0),( 132, 132, 132),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(  0,    0,    0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Stone Mountain
  {GoldMount}  ((0,0,0),(180, 172,176),(0,0,0),(  0,  0,  0),(  181, 173, 177),( 0, 0, 0),( 182, 174, 178),(  0,  0,  0),(  0,  0,  0),( 0, 0, 0),( 183, 175, 179),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),( 49,171,  51),(261,262,  0),( 0, 0, 0),(   0,   0,   0),( 159, 159, 159),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(  0,    0,    0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Gold Mountains
  {IronMount}  ((0,0,0),(188, 168,184),(0,0,0),(  0,  0,  0),(  189, 169, 185),( 0, 0, 0),( 190, 170, 186),(  0,  0,  0),(  0,  0,  0),( 0, 0, 0),( 191, 167, 187),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(256,257, 258),( 52,166, 54),( 0, 0, 0),(   0,   0,   0),( 299,   0,   0),( 164, 164, 164),(  0, 0,    0),(  0,  0,  0),(  0,    0,    0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Iron Mountains
  {Abyss}      ((0,0,0),(  0,   0,  0),(0,0,0),(  0,  0,  0),(    0,   0,   0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),( -53, -50,-165),(245, 0,    0),(  0,  0,  0),(  0,    0,    0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Abyss
  {Gravel}     ((0,0,0),(  0,   0,  0),(0,0,0),(  0,  0,  0),( -113,-112,-111),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(  0,  0,  0),( 0, 0, 0),(  21,  21,  20),( -38, -39, -38),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(-65,-64,-247),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(-179,-175,-183),(-187,-167,-191),(  0, 0,    0),( 20, 20, 20),(  0,    0,    0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Gravel
  {Coal}       ((0,0,0),( 56,  57, 58),(0,0,0),(  0,  0,  0),( -113,-112,-111),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(  0,  0,  0),(87,88,89),( 152, 153, 154),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(-65,-64,-247),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(-179,-175,-183),(-187,-167,-191),(  0,  0,   0),(  0,  0,  0),(155,    0,    0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Coal
  {Gold}       ((0,0,0),(180, 172,176),(0,0,0),(  0,  0,  0),(  181, 173, 177),( 0, 0, 0),( 182, 174, 178),(  0,  0,  0),(  0,  0,  0),( 0, 0, 0),( 183, 175, 179),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),( 49,171,  51),(261,262,307),( 0, 0, 0),(   0,   0,   0),( 144, 145, 146),(   0,   0,   0),(  0,  0,   0),(183,175,179),(183,  175,  179),( 147,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Gold
  {Iron}       ((0,0,0),(188, 168,184),(0,0,0),(  0,  0,  0),(  189, 169, 185),( 0, 0, 0),( 190, 170, 186),(  0,  0,  0),(  0,  0,  0),( 0, 0, 0),( 191, 167, 187),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(256,257, 258),( 52,166, 54),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),( 148, 149, 150),(-53,-50,-165),(191,167,187),(191,	167,	187),(   0,   0,   0),( 151,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Iron
  {Water}      ((0,0,0),(123,-125,127),(0,0,0),(  0,  0,  0),(  116,-117, 118),( 0, 0, 0),(-243,-242,-241),(  0,  0,  0),(  0,  0,  0),( 0, 0, 0),(-107,-106,-105),(-107,-106,-105),(114,115,119),( 0, 0, 0),(-22,-12,-23),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(-143,-200,-236),(-237,-200,-236),(-239,-200,-236),(245, 0,    0),(  0,  0,  0),(-107,-106, -105),(-237,-200,-236),(-239,-200,-236),( 192,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Water
  {FastWater}  ((0,0,0),(123,-125,127),(0,0,0),(  0,  0,  0),(  116,-117, 118),( 0, 0, 0),(-243,-242,-241),(  0,  0,  0),(  0,  0,  0),( 0, 0, 0),(-107,-106,-105),(-107,-106,-105),(114,115,119),( 0, 0, 0),(-22,-12,-23),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(-143,-200,-236),(-237,-200,-236),(-239,-200,-236),(245, 0,    0),(  0,  0,  0),(-107,-106, -105),(-237,-200,-236),(-239,-200,-236),( 192, 192, 209),( 209, 0, 0),(   0, 0, 0)), //FastWater
  {Lava}       ((0,0,0),(  0,   0,  0),(0,0,0),(  0,  0,  0),(    0,   0,   0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),( -15,   7,   7),(-300,   7,   7),(  0, 0,    0),(  0,  0,  0),(  0,    0,    0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   7, 7, 7))  //Lava
               );

  //0     number of variants (1..X)
  //1..X  tile variants
  //
  RandomTiling: array [tkCustom..tkLava, 0..15] of Word = (
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
    (15,1,1,1,2,2,2,3,3,3,5,5,5,11,13,14), // Grass - reduced chance for "eye-catching" tiles
    (1,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0),     // Moss
    (1,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0),    // PaleGrass
    (2,31,33,0,0,0,0,0,0,0,0,0,0,0,0,0),   // CoastSand
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),     // GrassSand1
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),     // GrassSand2
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),     // GrassSand3
    (1,30,0,0,0,0,0,0,0,0,0,0,0,0,0,0),    // Sand
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),     // GrassDirt
    (2,36,37,0,0,0,0,0,0,0,0,0,0,0,0,0),   // Dirt
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),     // Cobblestone
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),     // GrassyWater
    (3,41,42,43,0,0,0,0,0,0,0,0,0,0,0,0),  // Swamp
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),     // Ice
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),     // ShallowSnow
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),     // Snow
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),     // DeepSnow
    (8,129,130,131,132,134,135,136,137,0,0,0,0,0,0,0),    // StoneMount
    (5,156,157,158,159,201{?},0,0,0,0,0,0,0,0,0,0),       // GoldMount
    (5,160,161,162,163,164,0,0,0,0,0,0,0,0,0,0),          // IronMount
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),                    // Abyss
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),                    // Gravel
    (11,152,153,154,154,154,155,155,155,155,263,263,0,0,0,0),  // Coal (enriched pattern)
    (9,144,145,146,146,146,147,147,147,147,0,0,0,0,0,0),  // Gold
    (13,148,149,150,150,151,151,151,151,259,259,260,260,260,0,0),//259,260,260,260,0,0),  // Iron
    (2,193,193,0,0,0,0,0,0,0,0,0,0,0,0,0),  // Water
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),      // FastWater
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)       // Lava
  );


//  RMG2Painter: array [0..255] of TKMTerrainKind = (
//    tkGrass, tkGrass, tkGrass, tkGrass, tkSnow, tkGrass, tkGrass, tkCustom, tkMoss, tkMoss, tkSnow, tkGrass, tkWater,
//    tkGrass, tkGrass, tkCustom, tkPaleGrass, tkPaleGrass, tkGrass, tkGrass, tkDirt, tkDirt, tkWater, tkWater,
//    tkCustom, tkCustom, tkGrassSand1, tkGrassSand2, tkGrassSand1, tkRichSand, tkRichSand, tkSand, tkSand, tkSand,
//    tkDirtGrass, tkDirt, tkDirt, tkDirt, tkDirt, tkDirt, tkSwamp, tkSwamp, tkSwamp, tkSwamp, tkIce, tkDeepSnow, tkSnow,
//    tkShallowSnow, tkGrassyWater, tkShallowSnow, tkIronMount, tkShallowSnow, tkDeepSnow, tkIronMount, tkDeepSnow,
//    tkCustom, tkGrass, tkGrass, tkGrass, tkCustom, tkCustom, tkCustom, tkCustom, tkCustom, tkDirt, tkDirt, tkGrass,
//    tkGrass, tkGrass, tkGrass, tkGrass, tkGrass, tkGrass, tkGrass, tkGrass, tkRustyGrass2, tkRustyGrass2, tkRustyGrass2,
//    tkGrassSand2, tkGrassSand2, tkGrassSand2, tkGrassSand1, tkGrassSand1, tkGrassSand1, tkGrass, tkGrass, tkGrass,
//    tkDirtGrass, tkDirtGrass, tkDirtGrass, tkGrass, tkGrass, tkGrass, tkGrass, tkGrass, tkGrass, tkDirtGrass, tkDirtGrass,
//    tkDirtGrass, tkRichSand, tkRichSand, tkRichSand, tkGrassSand2, tkGrassSand2, tkGrassSand2, tkWater, tkWater, tkWater,
//    tkSand, tkSand, tkSand, tkDirt, tkDirt, tkDirt, tkGrassyWater, tkGrassyWater, tkWater, tkWater, tkWater, tkGrassyWater,
//    tkGrass, tkGrass, tkGrass, tkGrass, tkGrass, tkGrass, tkGrass, tkGrass, tkStoneMount, tkStoneMount, tkStoneMount,
//    tkStoneMount, tkStoneMount, tkStoneMount, tkStoneMount, tkStoneMount, tkStoneMount, tkStoneMount, tkStoneMount,
//    tkStoneMount, tkStoneMount, tkStoneMount, tkWater, tkWater, tkGold, tkGold, tkGold, tkGold, tkIron, tkIron, tkIron,
//    tkIron, tkCoal, tkCoal, tkCoal, tkCoal, tkGoldMount, tkGoldMount, tkGoldMount, tkGoldMount, tkIronMount, tkIronMount,
//    tkIronMount, tkIronMount, tkIronMount, tkIronMount, tkIronMount, tkIronMount, tkIronMount, tkIronMount, tkIronMount,
//    tkGoldMount, tkGoldMount, tkGoldMount, tkGoldMount, tkGoldMount, tkGoldMount, tkGoldMount, tkGoldMount, tkGoldMount,
//    tkGoldMount, tkGoldMount, tkGoldMount, tkGoldMount, tkIronMount, tkIronMount, tkIronMount, tkIronMount, tkIronMount,
//    tkIronMount, tkIronMount, tkIronMount, tkWater, tkWater, tkWater, tkStoneMount, tkWater, tkDirt, tkCustom, tkCustom,
//    tkWater, tkGoldMount, tkCustom, tkSnow, tkSnow, tkSnow, tkCustom, tkCustom, tkWater, tkWater, tkWater, tkWater, tkSnow,
//    tkSnow, tkCustom, tkDirt, tkCustom, tkCustom, tkCustom, tkCustom, tkSnow, tkCustom, tkCustom, tkCustom, tkCustom,
//    tkCustom, tkCustom, tkCustom, tkCustom, tkCustom, tkCustom, tkCustom, tkCustom, tkCustom, tkWater, tkWater, tkWater,
//    tkWater, tkWater, tkWater, tkWater, tkWater, tkWater, tkWater, tkWater, tkAbyss, tkCustom, tkDirt, tkCustom, tkCustom,
//    tkCustom, tkCustom, tkCustom, tkCustom, tkCustom, tkCustom
//  );


implementation
uses
  KM_GameCursor, KM_Resource, KM_Log, KM_CommonUtils, KM_Utils, KM_CommonTypes, KM_ResSprites, KM_GUIMapEdTerrainBrushes;


type
  TKMTileMaskInfo = record
    TerKind: TKMTerrainKind;
    Rotation: Integer;
    SubType: TKMTileMaskSubType;
    Corners: set of Byte;
  end;


function GetCombo(aTerKindFrom, aTerKindTo: TKMTerrainKind; aTransition: Byte; var aFound: Boolean): SmallInt;
begin
  aFound := True;
  Result := Combo[aTerKindFrom, aTerKindTo, aTransition];
  if (Result = 0)
    and not ((aTerKindFrom = tkGrass) and (aTerKindTo = tkGrass))
    and (aTerKindTo <> tkCustom)
    and (aTerKindFrom <> tkCustom) then
    //We have no direct transition
    aFound := False;
end;


//Convert terrain kind from old format (before r9371, new automatic tile transitions) to new terrain kind
function TKMTerrainPainter.GetTerKind(aTKValue: Integer; aUseKamFormat: Boolean): TKMTerrainKind;
begin
  Result := tkCustom;
  if InRange(aTKValue, ShortInt(Low(TKMTerrainKind)), ShortInt(High(TKMTerrainKind))) then
  begin
    if not aUseKamFormat then
      Result := TKMTerrainKind(aTKValue)
    else begin
      case aTKValue of                //In old format it was:
        0:  Result := tkCustom;       //tkCustom
        1:  Result := tkGrass;        //tkGrass
        2:  Result := tkMoss;         //tkMoss
        3:  Result := tkPaleGrass;    //tkRustyGrass1
        4:  Result := tkGrassSand1;   //tkRustyGrass2
        5:  Result := tkGrassDirt;    //tkDirtGrass
        6:  Result := tkCoastSand;    //tkSand
        7:  Result := tkSand;         //tkRichSand
        8:  Result := tkDirt;         //tkDirt
        9:  Result := tkCobbleStone;  //tkCobbleStone
        10: Result := tkGrassSand3;   //tkGrassSand1
        11: Result := tkGrassSand2;   //tkGrassSand2
        12: Result := tkGrassyWater;  //tkGrassyWater
        13: Result := tkSwamp;        //tkSwamp
        14: Result := tkIce;          //tkIce
        15: Result := tkShallowSnow;  //tkShallowSnow
        16: Result := tkSnow;         //tkSnow
        17: Result := tkDeepSnow;     //tkDeepSnow
        18: Result := tkStone;        //tkStoneMount
        19: Result := tkGoldMount;    //tkGoldMount
        20: Result := tkIronMount;    //tkIronMount,
        21: Result := tkAbyss;        //tkAbyss
        22: Result := tkGravel;       //tkGravel
        23: Result := tkWater;        //tkCoal
        24: Result := tkCoal;         //tkGold
        25: Result := tkGold;         //tkIron
        26: Result := tkIron;         //tkWater
        27: Result := tkFastWater;    //tkFastWater
        28: Result := tkLava;         //tkLava
      end;
    end;
  end;
end;


{ TKMTerrainPainter }
function TKMTerrainPainter.BrushAreaTerKindContains(aCell: TKMPoint): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to fBrushAreaTerKindCnt - 1 do
    if aCell = fBrushAreaTerKind[I] then
    begin
      Result := True;
      Exit;
    end;
end;


procedure TKMTerrainPainter.BrushTile(const X, Y: Integer);
var
  TerKind: TKMTerrainKind;
begin
  TerKind := TKMTerrainKind(gGameCursor.Tag1);
  BrushTerrainTile(X,Y, TerKind);
end;


procedure TKMTerrainPainter.BrushTerrainTile(const X, Y: Integer; aTerKind: TKMTerrainKind);

  procedure AddBrushAreaTerKind(aX,aY: Integer);
  var
    P: TKMPoint;
  begin
    P := KMPoint(aX,aY);
    if not BrushAreaTerKindContains(P) then
    begin
      fBrushAreaTerKind[fBrushAreaTerKindCnt] := P;
      Inc(fBrushAreaTerKindCnt);
    end;
  end;

begin
  if gGameCursor.MapEdSize = 0 then
  begin
    if not gTerrain.VerticeInMapCoords(X, Y) then
      Exit;

    LandTerKind[fMapYn, fMapXn].TerKind := aTerKind;
    AddBrushAreaTerKind(fMapXn, fMapYn);
    Exit;
  end;

  if not gTerrain.TileInMapCoords(X, Y) then
    Exit;

  LandTerKind[Y,   X].TerKind   := aTerKind;
  LandTerKind[Y,   X+1].TerKind := aTerKind;
  LandTerKind[Y+1, X+1].TerKind := aTerKind;
  LandTerKind[Y+1, X].TerKind   := aTerKind;

  gTerrain.Land[Y, X].BaseLayer.Terrain := PickRandomTile(aTerKind);
  gTerrain.Land[Y, X].BaseLayer.Rotation := Random(4); //Random direction for all plain tiles
  gTerrain.Land[Y, X].IsCustom := False;

  AddBrushAreaTerKind(X,  Y);
  AddBrushAreaTerKind(X+1,Y);
  AddBrushAreaTerKind(X+1,Y+1);
  AddBrushAreaTerKind(X,  Y+1);
end;


function TKMTerrainPainter.IsTerrainRepresentTerKind(aTerId: Word; aTerKind: TKMTerrainKind): Boolean;
var
  I: Integer;
begin
  Result := (aTerId = BASE_TERRAIN[aTerKind]);
  for I := 1 to RandomTiling[aTerKind,0] do
  begin
    if Result then Exit;
    Result := Result or (aTerId = RandomTiling[aTerKind,I]);
  end;
end;


function TKMTerrainPainter.PickRandomTile(aTerrainKind: TKMTerrainKind): Word;
begin
  Result := GetRandomTile(aTerrainKind, not RandomizeTiling);
end;


procedure TKMTerrainPainter.FixTerrainKindInfo;

  function EqualTKinds(aTK1, aTK2: TKMTerrainKind): Boolean;
  var
    I: Integer;
  begin
    Result := aTK1 = aTK2;
    if not Result then
      for I := Low(TERRAIN_EQUALITY_PAIRS) to High(TERRAIN_EQUALITY_PAIRS) do
        if (TERRAIN_EQUALITY_PAIRS[I].TK1 in [aTK1, aTK2])
          and (TERRAIN_EQUALITY_PAIRS[I].TK2 in [aTK1, aTK2]) then
          Result := True;
  end;

var
  I,J,K,M: Integer;
  VertexTKinds: TKMTerrainKindsArray;
  SameTKind, NoCustomTK: Boolean;
  TKCounts: array[0..3] of Integer;
  MostTKI: Integer;
begin
  for I := 1 to gTerrain.MapY do
    for J := 1 to gTerrain.MapX do
    begin
      VertexTKinds := GetVertexCornerTerKinds(J,I);
      SameTKind := True;

      for K := 0 to 3 do
        TKCounts[K] := 0;

      //Find most popular TerKind
      //Count all TerKinds occurrences first
      for K := 0 to 3 do
        for M := K + 1 to 3 do
          if VertexTKinds[K] = VertexTKinds[M] then
            Inc(TKCounts[K]);

      //Get Most popular one index
      MostTKI := 0;
      for K := 1 to 3 do
        if TKCounts[K] > TKCounts[MostTKI] then
          MostTKI := K;


      NoCustomTK := VertexTKinds[0] <> tkCustom;
      for K := 1 to 3 do
      begin
        SameTKind := SameTKind and EqualTKinds(VertexTKinds[K], VertexTKinds[K-1]);
        NoCustomTK := NoCustomTK and (VertexTKinds[K] <> tkCustom);
      end;

      //Replace TerKind with most popular one if there all TerKinds are equal or if there is no custom TerKinds
      if SameTKind or NoCustomTK then
      begin
        LandTerKind[I,J].TerKind := VertexTKinds[MostTKI];
        LandTerKind[I,J].Tiles := High(SmallInt);
      end;
    end;

  MakeCheckpoint;
end;


class function TKMTerrainPainter.GetRandomTile(aTerrainKind: TKMTerrainKind; aSkipRandom: Boolean = False): Word;
begin
  Result := Abs(Combo[aTerrainKind, aTerrainKind, 1]);

  if aSkipRandom or (RandomTiling[aTerrainKind, 0] = 0) then Exit;


  if aTerrainKind in [tkStone..tkIronMount, tkCoal..tkIron] then
    //Equal chance
    Result := RandomTiling[aTerrainKind, KaMRandom(RandomTiling[aTerrainKind, 0], 'TKMTerrainPainter.GetRandomTile') + 1]
  else
  if KaMRandom(6, 'TKMTerrainPainter.GetRandomTile 2') = 1 then
    //Chance reduced to 1/6
    Result := RandomTiling[aTerrainKind, KaMRandom(RandomTiling[aTerrainKind, 0], 'TKMTerrainPainter.GetRandomTile 3') + 1];
end;


procedure TKMTerrainPainter.RebuildTile(const X,Y: Integer);
var
  pY, pX, Nodes, Rot, T: Integer;
  Tmp, Ter1, Ter2, A, B, C, D: TKMTerrainKind;
  Found: Boolean;
begin
  if not gTerrain.TileInMapCoords(X, Y) then Exit;

  pX := EnsureRange(X, 1, gTerrain.MapX - 1);
  pY := EnsureRange(Y, 1, gTerrain.MapY - 1);

  //don't touch custom placed tiles (tkCustom type)
//  if (LandTerKind[pY  ,pX].TerKind <> tkCustom)
//    or (LandTerKind[pY  ,pX+1].TerKind <> tkCustom)
//    or (LandTerKind[pY+1,pX].TerKind <> tkCustom)
//    or (LandTerKind[pY+1,pX+1].TerKind <> tkCustom) then
  if not ForcePaint and gTerrain.Land[pY,pX].IsCustom then Exit;

  A := (LandTerKind[pY    , pX    ].TerKind);
  B := (LandTerKind[pY    , pX + 1].TerKind);
  C := (LandTerKind[pY + 1, pX    ].TerKind);
  D := (LandTerKind[pY + 1, pX + 1].TerKind);
  Rot := 0;
  Nodes := 1;

  //A-B
  //C-D
  Ter1 := tkCustom;
  Ter2 := tkCustom;

  if (A=B)or(C=D)  then begin Ter1:=A; Ter2:=C; Nodes:=2; if A<C then Rot:=2 else Rot:=0; end;
  if (A=C)or(B=D)  then begin Ter1:=A; Ter2:=B; Nodes:=2; if A<B then Rot:=1 else Rot:=3; end;

  //special case \ and /
  if A=D then begin Ter1:=A; Ter2:=B; Nodes:=4+1; Rot:=1; end;
  if B=C then begin Ter1:=A; Ter2:=B; Nodes:=4+2; Rot:=0; end;

  if (A=B)and(C=D) then begin Ter1:=A; Ter2:=C; Nodes:=2; if A<C then Rot:=2 else Rot:=0; end;
  if (A=C)and(B=D) then begin Ter1:=A; Ter2:=B; Nodes:=2; if A<B then Rot:=1 else Rot:=3; end;

  if (B=C)and(C=D) then begin Ter1:=C; Ter2:=A; Nodes:=3; if C<A then Rot:=3 else Rot:=1; end;
  if (A=C)and(C=D) then begin Ter1:=A; Ter2:=B; Nodes:=3; if A<B then Rot:=0 else Rot:=2; end;
  if (A=B)and(B=D) then begin Ter1:=A; Ter2:=C; Nodes:=3; if A<C then Rot:=2 else Rot:=0; end;
  if (A=B)and(B=C) then begin Ter1:=A; Ter2:=D; Nodes:=3; if A<D then Rot:=1 else Rot:=3; end;

  if (A=B)and(B=C)and(C=D) then begin Ter1:=A; Ter2:=A; Nodes:=4; Rot:=0; end;

  //Terrain table has only half filled, so make sure first comes bigger ID
  if Ter1 < Ter2 then
  begin
   Tmp := Ter1;
   Ter1 := Ter2;
   Ter2 := Tmp;
   case Nodes of
      1..3: Nodes := 4 - Nodes;  //invert nodes count
      5..6: Rot := 1;
    end;
  end;

  //Some tiles placed upside down or need other special treatment
  if Nodes < 4 then
  begin
    //Flip direction
    if Combo[Ter1, Ter2, Nodes] < 0 then
      Rot := (Rot + 2) mod 4;
    //For some weird reason lava needs to be rotated 90`
    if Ter1 = tkLava then
      Rot := (Rot + 1) mod 4;
  end;

  T := 0;
  if Nodes < 4 then T := Abs(GetCombo(Ter1, Ter2, Nodes, Found));     //transition tiles
  if Nodes = 4 then T := Abs(GetCombo(Ter1, Ter2, 1, Found));         //no transition
  if Nodes > 4 then T := Abs(GetCombo(Ter1, Ter2, 3, Found));         //transition use 1 or 3

  //for plain tiles only
  if Ter1 = Ter2 then
  begin
    T := PickRandomTile(Ter1);

    Rot := Random(4); //random direction for all plain tiles
  end;

  //Need to check if this tile was already smart-painted, "4-Nodes" hence default value is 0
  if (LandTerKind[pY,pX].Tiles <> Byte(Ter1)*Byte(Ter2)*(4-Nodes))
    or ((Nodes = 4) and not IsTerrainRepresentTerKind(gTerrain.Land[pY,pX].BaseLayer.Terrain, Ter1)) //All nodes, but terrain is different from needed TerKind
    or (gTerrain.Land[pY,pX].LayersCnt > 0) then
  begin
    LandTerKind[pY,pX].Tiles := Byte(Ter1)*Byte(Ter2)*(4-Nodes);//store not only nodes info, but also terrain type used
    if Found and ((Nodes = 4) or (TKMTileMaskKind(gGameCursor.MapEdBrushMask) = mkNone)) then
    begin
      gTerrain.Land[pY,pX].BaseLayer.Terrain := T;
      gTerrain.Land[pY,pX].BaseLayer.Corners := [0,1,2,3];
      gTerrain.Land[pY,pX].LayersCnt := 0;
      gTerrain.Land[pY,pX].BaseLayer.Rotation := Rot mod 4;
    end
  end;
end;


procedure TKMTerrainPainter.RebuildMap(const aRect: TKMRect);
var
  I, K: Integer;
begin
  for I := aRect.Top to aRect.Bottom do
    for K := aRect.Left to aRect.Right do
      RebuildTile(K,I);
end;


procedure TKMTerrainPainter.RebuildMap(X,Y,aSize: Integer; aSquare: Boolean; aAroundTiles: Boolean = False);
begin
  IterateOverArea(KMPoint(X,Y), aSize, aSquare, RebuildTile, aAroundTiles);
end;


//Get tile corners terkinds (TKinds, based on TILE_CORNERS_TERRAIN_KINDS or generated mask)
function TKMTerrainPainter.GetTileOwnCornersTKinds(aCell: TKMPoint): TKMTerrainKindsArray;
begin
  Result := GetTileCornersTKinds(aCell, True);
end;


function TKMTerrainPainter.GetTileLandNodeTKinds(aCell: TKMPoint): TKMTerrainKindsArray;
begin
  Result := GetTileCornersTKinds(aCell, False, True);
end;


function TKMTerrainPainter.GetVertexCornerTerKinds(X,Y: Word): TKMTerrainKindsArray;
begin
  SetLength(Result, 4);
  Result[0] := GetTileOwnCornersTKinds(KMPoint(X-1, Y-1))[2];
  Result[1] := GetTileOwnCornersTKinds(KMPoint(X,   Y-1))[3];
  Result[2] := GetTileOwnCornersTKinds(KMPoint(X,   Y))[0];
  Result[3] := GetTileOwnCornersTKinds(KMPoint(X-1, Y))[1];

end;


function TKMTerrainPainter.GetTileCornersTKinds(aCell: TKMPoint;
                                                      aGetOnlyTileCornersTK: Boolean = False;
                                                      aGetOnlyLandNodeTK: Boolean = False): TKMTerrainKindsArray;
var
  TerKindFound: array [0..3] of Boolean;

  procedure CheckTerKind(aX,aY,aI: Integer);
  var
    TerKind: TKMTerrainKind;
  begin
    if not gTerrain.VerticeInMapCoords(aX, aY)
      or (aGetOnlyTileCornersTK and not BrushAreaTerKindContains(KMPoint(aX, aY))) then
      Exit;

    TerKind := LandTerKind[aY,aX].TerKind;
    if TerKind <> tkCustom then
    begin
      TerKindFound[aI] := True;
      Result[aI] := TerKind;
    end;
  end;

var
  I,L: Integer;
  Tile: TKMTerrainTileBasic;

begin
  Assert(not (aGetOnlyTileCornersTK and aGetOnlyLandNodeTK)); //At least 1 of those parameters should be False

  SetLength(Result, 4);

  //Init with tkCustom
  for I := 0 to 3 do
  begin
    TerKindFound[I] := False;
    Result[I] := tkCustom;
  end;

  //Get tile corners TKinds based on LandTerKind
  if not aGetOnlyTileCornersTK then
  begin
    CheckTerKind(aCell.X,   aCell.Y,   0);
    CheckTerKind(aCell.X+1, aCell.Y,   1);
    CheckTerKind(aCell.X+1, aCell.Y+1, 2);
    CheckTerKind(aCell.X,   aCell.Y+1, 3);
  end;

  //Get tile corners terkinds (TKinds, based on TILE_CORNERS_TERRAIN_KINDS or generated mask)
  if not aGetOnlyLandNodeTK and gTerrain.TileInMapCoords(aCell) then
  begin
    if fUseTempLand then
      Tile := fTempLand[aCell.Y, aCell.X]
    else
      Tile := GetTerrainTileBasic(gTerrain.Land[aCell.Y, aCell.X]);

    for I := 0 to 3 do
      if not TerKindFound[I] then
      begin
        if I in Tile.BaseLayer.Corners then
          Result[I] := TILE_CORNERS_TERRAIN_KINDS[Tile.BaseLayer.Terrain, (I + 4 - Tile.BaseLayer.Rotation) mod 4]
        else
          for L := 0 to Tile.LayersCnt - 1 do
            if I in Tile.Layer[L].Corners then
              Result[I] := gRes.Sprites.GetGenTerrainInfo(Tile.Layer[L].Terrain).TerKind;
      end;
  end;
end;


function GetMaskType(aCornerTerKinds: TKMTerrainKindsArray; var aLayerOrder: array of TKMTileMaskInfo): TKMTileMaskType;
var
  A,B,C,D,TK: TKMTerrainKind;
  I, J, Tmp: Integer;
  CornerI: array[0..3] of Integer;
begin
  Result := mtNone; // makes compiler happy
  // A B
  // D C
  A := aCornerTerKinds[0];
  B := aCornerTerKinds[1];
  C := aCornerTerKinds[2];
  D := aCornerTerKinds[3];

  // A A
  // A A
  if (A = B) and (A = C) and (A = D) then
  begin
    Result := mtNone;
    aLayerOrder[0].TerKind := A;
    aLayerOrder[0].Corners := [0,1,2,3];
    aLayerOrder[0].Rotation := 0;
    Exit;
  end;

  // A A
  // D A
  if ((A = B) and (A = C)) then
  begin
    if TER_KIND_ORDER[B] < TER_KIND_ORDER[D] then
    begin
      aLayerOrder[0].TerKind := B;
      aLayerOrder[0].Corners := [0,1,2];
      aLayerOrder[1].TerKind := D;
      aLayerOrder[1].Rotation := 3;
      aLayerOrder[1].Corners := [3];
      Result := mt_2Corner;
    end else
    begin
      aLayerOrder[0].TerKind := D;
      aLayerOrder[0].Corners := [3];
      aLayerOrder[1].TerKind := B;
      aLayerOrder[1].Rotation := 1;
      aLayerOrder[1].Corners := [0,1,2];
      Result := mt_2Diagonal;
    end;
    Exit;
  end;

  // A A
  // A C
  if ((A = B) and (A = D)) then
  begin
    if TER_KIND_ORDER[A] < TER_KIND_ORDER[C] then
    begin
      aLayerOrder[0].TerKind := A;
      aLayerOrder[0].Corners := [0,1,3];
      aLayerOrder[1].TerKind := C;
      aLayerOrder[1].Rotation := 2;
      aLayerOrder[1].Corners := [2];
      Result := mt_2Corner;
    end else
    begin
      aLayerOrder[0].TerKind := C;
      aLayerOrder[0].Corners := [2];
      aLayerOrder[1].TerKind := A;
      aLayerOrder[1].Rotation := 0;
      aLayerOrder[1].Corners := [0,1,3];
      Result := mt_2Diagonal;
    end;
    Exit;
  end;

  // A B
  // B B
  if ((B = C) and (B = D)) then
  begin
    if TER_KIND_ORDER[A] < TER_KIND_ORDER[C] then
    begin
      aLayerOrder[0].TerKind := A;
      aLayerOrder[0].Corners := [0];
      aLayerOrder[1].TerKind := C;
      aLayerOrder[1].Rotation := 2;
      aLayerOrder[1].Corners := [1,2,3];
      Result := mt_2Diagonal;
    end else
    begin
      aLayerOrder[0].TerKind := C;
      aLayerOrder[0].Corners := [1,2,3];
      aLayerOrder[1].TerKind := A;
      aLayerOrder[1].Rotation := 0;
      aLayerOrder[1].Corners := [0];
      Result := mt_2Corner;
    end;
    Exit;
  end;

  // A B
  // A A
  if ((A = C) and (A = D)) then
  begin
    if TER_KIND_ORDER[D] < TER_KIND_ORDER[B] then
    begin
      aLayerOrder[0].TerKind := D;
      aLayerOrder[0].Corners := [0,2,3];
      aLayerOrder[1].TerKind := B;
      aLayerOrder[1].Rotation := 1;
      aLayerOrder[1].Corners := [1];
      Result := mt_2Corner;
    end else
    begin
      aLayerOrder[0].TerKind := B;
      aLayerOrder[0].Corners := [1];
      aLayerOrder[1].TerKind := D;
      aLayerOrder[1].Rotation := 3;
      aLayerOrder[1].Corners := [0,2,3];
      Result := mt_2Diagonal;
    end;
    Exit;
  end;

  // A A
  // C C
  if (A = B) and (C = D) then
  begin
    Result := mt_2Straight;
    if TER_KIND_ORDER[A] < TER_KIND_ORDER[C] then
    begin
      aLayerOrder[0].TerKind := A;
      aLayerOrder[0].Corners := [0,1];
      aLayerOrder[1].TerKind := C;
      aLayerOrder[1].Rotation := 2;
      aLayerOrder[1].Corners := [2,3];
    end else
    begin
      aLayerOrder[0].TerKind := C;
      aLayerOrder[0].Corners := [2,3];
      aLayerOrder[1].TerKind := A;
      aLayerOrder[1].Rotation := 0;
      aLayerOrder[1].Corners := [0,1];
    end;
    Exit;
  end;

  // A B
  // A B
  if (A = D) and (B = C) then
  begin
    Result := mt_2Straight;
    if TER_KIND_ORDER[A] < TER_KIND_ORDER[B] then
    begin
      aLayerOrder[0].TerKind := A;
      aLayerOrder[0].Corners := [0,3];
      aLayerOrder[1].TerKind := B;
      aLayerOrder[1].Rotation := 1;
      aLayerOrder[1].Corners := [1,2];
    end else
    begin
      aLayerOrder[0].TerKind := B;
      aLayerOrder[0].Corners := [1,2];
      aLayerOrder[1].TerKind := A;
      aLayerOrder[1].Rotation := 3;
      aLayerOrder[1].Corners := [0,3];
    end;
    Exit;
  end;


  // A B
  // B A
  if (A = C) and (B = D) then
  begin
    Result := mt_2Opposite;
    if TER_KIND_ORDER[A] < TER_KIND_ORDER[B] then
    begin
      aLayerOrder[0].TerKind := A;
      aLayerOrder[0].Corners := [0,2];
      aLayerOrder[1].TerKind := B;
      aLayerOrder[1].Rotation := 1;
      aLayerOrder[1].Corners := [1,3];
    end else
    begin
      aLayerOrder[0].TerKind := B;
      aLayerOrder[0].Corners := [1,3];
      aLayerOrder[1].TerKind := A;
      aLayerOrder[1].Rotation := 0;
      aLayerOrder[1].Corners := [0,2];
    end;
    Exit;
  end;

  for I := 0 to 3 do
   CornerI[I] := I;

  for I := 0 to 3 do
    for J := I to 3 do
      if TER_KIND_ORDER[aCornerTerKinds[CornerI[I]]] > TER_KIND_ORDER[aCornerTerKinds[CornerI[J]]] then
      begin
        Tmp := CornerI[I];
        CornerI[I] := CornerI[J];
        CornerI[J] := Tmp;
      end;

  // A A
  // C D
  J := 0;
  for I := 0 to 3 do // go up to '4' corner, need to cycle all around to find A = D situation
  begin
    if (I = 0)
      or ((I < 4) and (aCornerTerKinds[CornerI[I]] <> aCornerTerKinds[CornerI[I-1]])) then
    begin
      aLayerOrder[J].TerKind := aCornerTerKinds[CornerI[I]];
      aLayerOrder[J].Rotation := CornerI[I];
      aLayerOrder[J].Corners := [CornerI[I]];
      Inc(J);
    end else
    if (aCornerTerKinds[CornerI[I]] = aCornerTerKinds[CornerI[I-1]]) then
    begin
      // CornerI was not sorted with stable sort, so it could be possible we will find first not the minimum rotation
      if ((CornerI[I] = 0) and (CornerI[I-1] = 3))
        or ((CornerI[I] = 3) and (CornerI[I-1] = 0)) then // use 3rd rotation for A-D situation (choose 3 between 0 and 3)
        aLayerOrder[J-1].Rotation := 3
      else
        aLayerOrder[J-1].Rotation := Min(CornerI[I], CornerI[I-1]);
      aLayerOrder[J-1].SubType := mstExtra;
      if Abs(CornerI[I] - CornerI[I-1]) = 2 then
        Result := mt_3Opposite
      else
        Result := mt_3Straight;
      Include(aLayerOrder[J-1].Corners, CornerI[I]);
    end;
  end;

  case J of
    3:      Exit;
    4:      begin
              Result := mt_4Square;
              Exit;
            end
    else    raise Exception.Create('Wrong number of corners with different TerKind: ' + IntToStr(J));
  end;


  aLayerOrder[0].TerKind := A;
  aLayerOrder[0].Rotation := 0;
  aLayerOrder[0].Corners := [0,1,2,3];

  Result := mtNone;
end;


procedure TKMTerrainPainter.MagicBrush(const X,Y: Integer);

  //This method tries to find the best appropriate TerKind for target cell (aCell) and for specified corner (aCorner)
  //1. We get cells next to aCell aCorner, and within map sizes
  //2. get TerKind from that cells, from corners, which are 'connected' to aCell aCorner, which are jointed
  //3. there could be several possibilities:
  // - no cells were found around aCell (map corner) - return aFound = False
  // - Found several Cells, Get several TerKinds, then
  //   - choose most popular one first
  //   - if all are different (1 occurences for each) then choose from diagonal cell
  //   - else take first one clockwise
  function GetCornerTerKind(aCorner: Byte; aCell: TKMPoint; var aFound: Boolean): TKMTerrainKind;
  var
    I, J, K: Integer;
    Rect: TKMRect;
    Dir: TKMDirection;
    RectCorners: TKMPointArray;
    DiagTerKind: TKMTerrainKind;
    HasCornerTiles: Boolean;
    TerKinds: array [0..2] of TKMTerrainKind;
  begin
    Result := tkCustom;
    case aCorner of
      0: Dir := dirNW;
      1: Dir := dirNE;
      2: Dir := dirSE;
      3: Dir := dirSW;
      else raise Exception.Create('Unknown direction'); // Makes compiler happy
    end;
    //get 4 tiles around corner within map borders
    Rect := KMRect(aCell);                                            // x x  - we will get these x Tiles for corner 0, f.e.
    Rect := KMRectGrow(Rect, Dir);                                    // x o
    Rect := KMClipRect(Rect, 0, 0, gTerrain.MapX, gTerrain.MapY);     // Clip rect with possible nodes boundaries.
    RectCorners := KMRectCorners(Rect);                               //
    //after this preparation we will get 4 points (rect corners)

    K := 0;
    //DiagTerKind := tkNone;
    DiagTerKind := tkCustom;
    HasCornerTiles := False;
    for I := 0 to Length(RectCorners) - 1 do
    begin
      J := (I + aCorner) mod 4;
      if not KMSamePoint(aCell, RectCorners[J]) then //If rect was clipped due to map sizes restriction, then its corner will be same as our target cell (aCell)
      begin
        HasCornerTiles := True;
        //From all tile terkinds get corner we need.
        //we used that fact, that corner formula can be obtained as (I + aCorner + 2).
        //so f.e. for 0 corner, and tile 'above' (tile to the top from tasrget cell(aCell)) we have to get terrainKind from corner 3
        //3 = 1 (I, start from top left alwaysm top tile is the 2nd tile) + 0 (aCorner) + 2
        //and so on
        TerKinds[K] := GetTileCornersTKinds(RectCorners[J])[(I+aCorner+2) mod 4];
        // Find diagTerKind, as its preferrable over other cells
        if (aCell.X <> RectCorners[J].X) and (aCell.Y <> RectCorners[J].Y) then
          DiagTerKind := TerKinds[K];
        Inc(K);
      end;
    end;

    aFound := False;

    if not HasCornerTiles then Exit;

    //Find most popular TerKind
    //choose most popular one TerKind first
    if (TerKinds[0] = TerKinds[1])
      or (TerKinds[0] = TerKinds[2]) then
    begin
      Result := TerKinds[0];
      aFound := True;
    end else if (TerKinds[1] = TerKinds[2]) then
    begin
      Result := TerKinds[1];
      aFound := True;
    end else if DiagTerKind <> tkCustom then
    begin
      Result := DiagTerKind; //if all are different (1 occurences for each) then choose from diagonal cell
      aFound := True;
    end;
  end;

  function GetTerKindsAround(aCell: TKMPoint): TKMTerrainKindsArray;
  var
    I: Integer;
    TerKind: TKMTerrainKind;
    TerKindFound: array[0..3] of Boolean;
  begin
    SetLength(Result, 4);

    //get all 4 terkind for corners
    for I := 0 to 3 do
    begin
      TerKind := GetCornerTerKind(I, aCell, TerKindFound[I]);
      if TerKindFound[I] then
        Result[I] := TerKind;
    end;

    //For corner, where no terkind from around tiles were found - replace it with neighbour corner terkind (there can't be 2 missed terkinds in a row)
    for I := 0 to 3 do
      if not TerKindFound[I] then
        Result[I] := Result[(I+1) mod 4];

  end;

  function HasCollision(aTerKind1, aTerKind2: TKMTerrainKind): Boolean;
  var
    I: Integer;
  begin
    Result := False;
    if aTerKind1 = aTerKind2 then Exit;

    Result := True;
    for I := Low(TERRAIN_EQUALITY_PAIRS) to High(TERRAIN_EQUALITY_PAIRS) do
    begin
      if (TERRAIN_EQUALITY_PAIRS[I].TK1 in [aTerKind1, aTerKind2]) 
        and (TERRAIN_EQUALITY_PAIRS[I].TK2 in [aTerKind1, aTerKind2]) then
      begin
        Result := False;
        Exit;
      end;
    end;
  end;

  procedure ApplyMagicBrush(MaskKind: TKMTileMaskKind);
  var
    I: Integer;
    TileOwnTerKinds: TKMTerrainKindsArray;
    TileNodeTerKinds: TKMTerrainKindsArray;
    AroundTerKinds: TKMTerrainKindsArray;
    CollisionFound: Boolean;
    LayerOrder: array of TKMTileMaskInfo;
    MaskType: TKMTileMaskType;
  begin
    //Do not check tile node corners when using 'force paint' mode
    if not ForcePaint then
    begin
      TileNodeTerKinds := GetTileLandNodeTKinds(KMPoint(X,Y));

      for I := 0 to 3 do
        if TileNodeTerKinds[I] = tkCustom then  // Do not set masks for tiles with at least 1 custom real corner
          Exit;
    end;

    TileOwnTerKinds := GetTileOwnCornersTKinds(KMPoint(X,Y));
    AroundTerKinds := GetTerKindsAround(KMPoint(X,Y));

    for I := 0 to 3 do
      if AroundTerKinds[I] = tkCustom then  // Do not set masks if at least 1 around corner is custom
        Exit;

    CollisionFound := False;
    for I := 0 to 3 do
      if HasCollision(TileOwnTerKinds[I], AroundTerKinds[I]) then
      begin
        CollisionFound := True;
        Break;
      end;

    if CollisionFound then  //Need to apply MagicBrush
      with gTerrain.Land[Y,X] do
      begin
        SetLength(LayerOrder, 4);
        for I := 0 to 3 do
          LayerOrder[I].SubType := mstMain;

        MaskType := GetMaskType(AroundTerKinds, LayerOrder);

        BaseLayer.Terrain := BASE_TERRAIN[LayerOrder[0].TerKind];
        BaseLayer.Rotation := 0;
        BaseLayer.Corners := LayerOrder[0].Corners;
        LayersCnt := TILE_MASKS_LAYERS_CNT[MaskType] - 1;

        if MaskType = mtNone then Exit;

        for I := 1 to LayersCnt do // start from 1, just for convinience
        begin
          Layer[I-1].Terrain := gGenTerrainTransitions[LayerOrder[I].TerKind, MaskKind, MaskType, LayerOrder[I].SubType];
          Layer[I-1].Rotation := LayerOrder[I].Rotation;
          Layer[I-1].Corners := LayerOrder[I].Corners;
        end;
      end
  end;

var
  L: Integer;
  MaskKind: TKMTileMaskKind;
  GenInfo: TKMGenTerrainInfo;
begin
  if not gTerrain.TileInMapCoords(X, Y) or (not ForcePaint and gTerrain.Land[Y,X].IsCustom) then Exit;

  MaskKind := TKMTileMaskKind(gGameCursor.MapEdBrushMask);
  if (MaskKind = mkNone) and not fReplaceLayers then Exit;

  if MaskKind <> mkNone then
    ApplyMagicBrush(MaskKind);

  if fReplaceLayers then
  begin
    case MaskKind of
      mkNone:  begin
                  gTerrain.Land[Y,X].LayersCnt := 0; // Simple way to clear all layers
                  gTerrain.Land[Y,X].BaseLayer.Corners := [0,1,2,3];
                end;
      else      for L := 0 to gTerrain.Land[Y,X].LayersCnt - 1 do
                begin
                  GenInfo := gRes.Sprites.GetGenTerrainInfo(gTerrain.Land[Y,X].Layer[L].Terrain);
                  if GenInfo.Mask.Kind <> MaskKind then
                    gTerrain.Land[Y,X].Layer[L].Terrain :=
                      gGenTerrainTransitions[GenInfo.TerKind, MaskKind, GenInfo.Mask.MType, GenInfo.Mask.SubType];
                end;
    end;
  end;


end;


procedure TKMTerrainPainter.UpdateTempLand;
var
  I,J,L: Integer;
begin
  for I := 1 to gTerrain.MapY do
    for J := 1 to gTerrain.MapX do
    begin
      fTempLand[I,J].BaseLayer := gTerrain.Land[I,J].BaseLayer;
      fTempLand[I,J].LayersCnt := gTerrain.Land[I,J].LayersCnt;
      fTempLand[I,J].Height := gTerrain.Land[I,J].Height;
      fTempLand[I,J].Obj := gTerrain.Land[I,J].Obj;
      for L := 0 to 2 do
        fTempLand[I,J].Layer[L] := gTerrain.Land[I,J].Layer[L];
    end;
end;


procedure TKMTerrainPainter.UseMagicBrush(X,Y,aSize: Integer; aSquare: Boolean; aAroundTiles: Boolean = False);
var
  I: Integer;
begin
  for I := Low(fTime) to High(fTime) do
    fTime[I].Data := 0;

//  gLog.AddTime('Prepare Temp UseMagicBrush');
  UpdateTempLand;

  fUseTempLand := aSize > 0; //Do not use temp land when size = 0
  fReplaceLayers := False;
  IterateOverArea(KMPoint(X,Y), aSize, aSquare, MagicBrush, aAroundTiles);

//  for I := Low(fTime) to High(fTime) do
//    gLog.AddTime(Format('%s: %d ms', [fTime[I].Desc, fTime[I].Data]));
end;


procedure TKMTerrainPainter.EditBrush;
var
  Size, X, Y: Integer;
begin
  //Cell below cursor
  fMapXc := EnsureRange(round(gGameCursor.Float.X+0.5),1,gTerrain.MapX);
  fMapYc := EnsureRange(round(gGameCursor.Float.Y+0.5),1,gTerrain.MapY);

  //Node below cursor
  fMapXn := EnsureRange(round(gGameCursor.Float.X+1),1,gTerrain.MapX);
  fMapYn := EnsureRange(round(gGameCursor.Float.Y+1),1,gTerrain.MapY);

  Size := gGameCursor.MapEdSize;

  // Clear fBrushAreaTerKind array. It will be refilled in BrushTerrainTile
  fBrushAreaTerKindCnt := 0;

  IterateOverArea(KMPoint(fMapXc,fMapYc), Size, gGameCursor.MapEdShape = hsSquare, BrushTile);

  if Size = 0 then
  begin
    X := fMapXn;
    Y := fMapYn;
  end else begin
    X := fMapXc;
    Y := fMapYc;
  end;
  RebuildMap(X, Y, Size, (gGameCursor.MapEdShape = hsSquare), True);

  if TKMTileMaskKind(gGameCursor.MapEdBrushMask) <> mkNone then
    UseMagicBrush(X, Y, Size, (gGameCursor.MapEdShape = hsSquare), True);

  gTerrain.UpdatePassability(KMRectGrow(KMRect(gGameCursor.Cell), (Size div 2) + 1));
end;


procedure TKMTerrainPainter.EditHeight;
var
  I, K: Integer;
  Rad, Slope, Speed: Byte;
  Tmp: Single;
  R: TKMRect;
  aLoc : TKMPointF;
  aRaise, aLower: Boolean;
begin
  aLoc    := KMPointF(gGameCursor.Float.X+1, gGameCursor.Float.Y+1); // Mouse point
  aRaise  := ssLeft in gGameCursor.SState;         // Raise or Lowered (Left or Right mousebtn)
  aLower  := ssRight in gGameCursor.SState;        // Raise or Lowered (Left or Right mousebtn)
  Rad     := gGameCursor.MapEdSize;                // Radius basing on brush size
  Slope   := gGameCursor.MapEdSlope;               // Elevation slope
  Speed   := gGameCursor.MapEdSpeed;               // Elvation speed
  for I := Max((round(aLoc.Y) - Rad), 1) to Min((round(aLoc.Y) + Rad), gTerrain.MapY) do
  for K := Max((round(aLoc.X) - Rad), 1) to Min((round(aLoc.X) + Rad), gTerrain.MapX) do
  begin

    // We have square area basing on mouse point +/- radius
    // Now we need to check whether point is inside brush type area(circle etc.)
    // Every MapEdShape case has it's own check routine
    case gGameCursor.MapEdShape of
      hsCircle: Tmp := Max((1 - GetLength(I - round(aLoc.Y), round(K - aLoc.X)) / Rad), 0);   // Negative number means that point is outside circle
      hsSquare: Tmp := 1 - Max(Abs(I - round(aLoc.Y)), Abs(K - round(aLoc.X))) / Rad;
      else      Tmp := 0;
    end;

    // Default cursor mode is elevate/decrease
    if gGameCursor.Mode = cmEqualize then
    begin // START Unequalize
      if aRaise then
      begin
        if (i > 1) and (k >1) and (i < gTerrain.MapY - 1) and (k < gTerrain.MapX - 1) then
        begin
        // Unequalize compares heights of adjacent tiles and increases differences
          if (gTerrain.Land[I,K].Height < gTerrain.Land[I-1,K+1].Height) then
            Tmp := -Min(gTerrain.Land[I-1,K+1].Height - gTerrain.Land[I,K].Height, Tmp)
          else
          if (gTerrain.Land[I,K].Height > gTerrain.Land[I-1,K+1].Height) then
            Tmp := Min(gTerrain.Land[I,K].Height - gTerrain.Land[I-1,K+1].Height, Tmp)
          else
            Tmp := 0;
        end
        else
          Tmp := 0;
       //END Unequalize
      end else
      if aLower then
      // START Flatten
      begin
      //Flatten compares heights of mouse click and active tile then it increases/decreases height of active tile
        if (gTerrain.Land[I,K].Height < gTerrain.Land[Max(trunc(aLoc.Y), 1), Max(trunc(aLoc.X), 1)].Height) then
          Tmp := - Min(gTerrain.Land[Max(trunc(aLoc.Y), 1), Max(trunc(aLoc.X), 1)].Height - gTerrain.Land[I,K].Height, Tmp)
        else
          if (gTerrain.Land[I,K].Height > gTerrain.Land[Max(trunc(aLoc.Y), 1), Max(trunc(aLoc.X), 1)].Height) then
            Tmp := Min(gTerrain.Land[I,K].Height - gTerrain.Land[Max(trunc(aLoc.Y), 1), Max(trunc(aLoc.X), 1)].Height, Tmp)
          else
            Tmp := 0;
      end;
      //END Flatten
    end;
    //COMMON PART FOR Elevate/Lower and Unequalize/Flatten
    //Compute resulting floating-point height
    Tmp := power(abs(Tmp),(Slope+1)/6)*sign(Tmp); //Modify slopes curve
    Tmp := Tmp * (4.75/14*(Speed - 1) + 0.25);
    Tmp := EnsureRange(gTerrain.Land[I,K].Height + LandTerKind[I,K].HeightAdd/255 + Tmp * (Byte(aRaise)*2 - 1), 0, 100); // (Byte(aRaise)*2 - 1) - LeftButton pressed it equals 1, otherwise equals -1
    gTerrain.Land[I,K].Height := trunc(Tmp);
    LandTerKind[I,K].HeightAdd := round(frac(Tmp)*255); //write fractional part in 0..255 range (1Byte) to save us mem
  end;

  R := KMRectGrow(KMRect(aLoc), Rad);
  gTerrain.UpdateLighting(R);
  gTerrain.UpdatePassability(R);
end;


procedure TKMTerrainPainter.EditTile(const aLoc: TKMPoint; aTile: Word; aRotation: Byte; aIsCustom: Boolean = True);
begin
  if not gTerrain.TileInMapCoords(aLoc.X, aLoc.Y) then Exit;

  gTerrain.Land[aLoc.Y, aLoc.X].IsCustom := aIsCustom;
  gTerrain.Land[aLoc.Y, aLoc.X].BaseLayer.Terrain := aTile;
  gTerrain.Land[aLoc.Y, aLoc.X].BaseLayer.Corners := [0,1,2,3];
  gTerrain.Land[aLoc.Y, aLoc.X].LayersCnt := 0;
  gTerrain.Land[aLoc.Y, aLoc.X].BaseLayer.Rotation := aRotation;

  gTerrain.UpdatePassability(aLoc);
end;


procedure TKMTerrainPainter.RMG2MapEditor(X,Y: Integer; aTile: Word);
begin
  LandTerKind[Y,X].TerKind := TILE_CORNERS_TERRAIN_KINDS[aTile][0];
end;


procedure TKMTerrainPainter.MagicWater(const aLoc: TKMPoint);
type
  TMagicType = (mtNone, mtWater, mtShore, mtIce);
var
  FilledTiles: array of array of TMagicType;

  function CanRotate(aTileID: Word): Boolean;
  begin
    Result := (gRes.Tileset.TileIsWater(aTileID)
              and not (aTileID in [114, 115, 119, 194, 200, 210, 211, 235, 236]))
              or (gRes.Tileset.TileIsIce(aTileID)
              and not (aTileID in [4, 10, 12, 22, 23]));
  end;

  procedure MagicFillArea(X, Y: Word);
  begin
    if FilledTiles[Y, X] <> mtNone then
      Exit;

    //Detect rotateable shores
    if (gTerrain.Land[y,x].BaseLayer.Terrain in [126, 127]) then
      FilledTiles[y,x] := mtShore;

    //Detect full ice tiles
    if (gTerrain.Land[y, x].BaseLayer.Terrain = 44) then
      FilledTiles[y, x] := mtIce;

    //Detect water
    if CanRotate(gTerrain.Land[y,x].BaseLayer.Terrain) then
    begin
      FilledTiles[y,x] := mtWater;

      if x-1>=1 then
      begin
        if y-1>=1 then             MagicFillArea(x-1,y-1);
                                   MagicFillArea(x-1,y  );
        if y+1<=gTerrain.MapY then MagicFillArea(x-1,y+1);
      end;

      if y-1>=1 then               MagicFillArea(x,y-1);
      if y+1<=gTerrain.MapY then   MagicFillArea(x,y+1);

      if x+1<=gTerrain.MapX then
      begin
        if y-1>=1 then             MagicFillArea(x+1,y-1);
                                   MagicFillArea(x+1,y  );
        if y+1<=gTerrain.MapY then MagicFillArea(x+1,y+1);
      end;
    end;
  end;

var
  I,K:Integer;
  NewRot: Byte;
begin
  if not CanRotate(gTerrain.Land[aLoc.Y, aLoc.X].BaseLayer.Terrain) then
    Exit;

  SetLength(FilledTiles, gTerrain.MapY+1, gTerrain.MapX+1);

  MagicFillArea(aLoc.X,aLoc.Y);

  NewRot := (gTerrain.Land[aLoc.Y,aLoc.X].BaseLayer.Rotation + 1) mod 4;
  for I := 1 to gTerrain.MapY do
    for K := 1 to gTerrain.MapX do
      case FilledTiles[I,K] of
        mtWater,
        mtIce:    begin
                    gTerrain.Land[I,K].BaseLayer.Rotation := NewRot;
                  end;
        mtShore:  begin
                    //These shores can be flipped
                    if (gTerrain.Land[I,K].BaseLayer.Terrain in [126, 127]) then
                      case gTerrain.Land[I,K].BaseLayer.Rotation of
                        0: if NewRot = 3 then gTerrain.Land[I,K].BaseLayer.Terrain := 126 else
                           if NewRot = 1 then gTerrain.Land[I,K].BaseLayer.Terrain := 127;

                        1: if NewRot = 0 then gTerrain.Land[I,K].BaseLayer.Terrain := 126 else
                           if NewRot = 2 then gTerrain.Land[I,K].BaseLayer.Terrain := 127;

                        2: if NewRot = 1 then gTerrain.Land[I,K].BaseLayer.Terrain := 126 else
                           if NewRot = 3 then gTerrain.Land[I,K].BaseLayer.Terrain := 127;

                        3: if NewRot = 2 then gTerrain.Land[I,K].BaseLayer.Terrain := 126 else
                           if NewRot = 0 then gTerrain.Land[I,K].BaseLayer.Terrain := 127;
                      end;
                  end;
      end;
  MakeCheckpoint;
end;


procedure TKMTerrainPainter.GenerateAddnData;
const
  SPECIAL_TILES: array[0..28] of Word = ( 24, 25,194,198,199,202,206,207,214,216,217,218,219,221,222,223,224,225,226,227,228,
                                         229,230,231,232,233,246,264,265); //Waterfalls and bridges
  OTHER_WATER_TILES = [193,208,209,240,244]; //Water tiles not used in painting (fast, straight, etc.)
  //Accuracies
  ACC_MAX = 5;  //Special tiles
  ACC_HIGH = 4; //Primary tiles
  ACC_MED = 3; //Random tiling
  ACC_LOW = 2; //Edges
  ACC_MIN = 1; //Coal random tiling (edges are better in this case)
  ACC_NONE = 0;
var
  Accuracy: array of array of Byte;

  procedure SetTerrainKindVertex(X,Y: Integer; T: TKMTerrainKind; aAccuracy: Byte);
  begin
    if not gTerrain.TileInMapCoords(X,Y) then Exit;

    //Special rules to fix stone hill corners:
    // - Never overwrite tkStone with tkGrass
    // - Always allow tkStone to overwrite tkGrass
    if (LandTerKind[Y,X].TerKind = tkStone) and (T = tkGrass) then Exit;
    if (LandTerKind[Y,X].TerKind = tkGrass) and (T = tkStone) then aAccuracy := ACC_MAX;

    //Skip if already set more accurately
    if aAccuracy < Accuracy[Y,X] then Exit;

    LandTerKind[Y,X].TerKind := T;
    Accuracy[Y,X] := aAccuracy;
  end;

  procedure SetTerrainKindTile(X,Y: Integer; T: TKMTerrainKind; aAccuracy: Byte);
  begin
    SetTerrainKindVertex(X  , Y  , T, aAccuracy);
    SetTerrainKindVertex(X+1, Y  , T, aAccuracy);
    SetTerrainKindVertex(X  , Y+1, T, aAccuracy);
    SetTerrainKindVertex(X+1, Y+1, T, aAccuracy);
  end;

var
  I,K,J,Rot: Integer;
  A: Byte;
  T, T2: TKMTerrainKind;
begin
  SetLength(Accuracy, gTerrain.MapY+1, gTerrain.MapX+1);

  for I := 1 to gTerrain.MapY do
  for K := 1 to gTerrain.MapX do
  begin
    LandTerKind[I,K].TerKind := tkCustom; //Everything custom by default
    Accuracy[I,K] := ACC_NONE;
  end;

  for I := 1 to gTerrain.MapY do
  for K := 1 to gTerrain.MapX do
    //Special tiles such as bridges should remain as tkCustom
    if ArrayContains(gTerrain.Land[I,K].BaseLayer.Terrain, SPECIAL_TILES) then
      SetTerrainKindTile(K, I, tkCustom, ACC_MAX) //Maximum accuracy
    else
      //Water tiles not used in painting (fast, straight, etc.)
      if gTerrain.Land[I,K].BaseLayer.Terrain in OTHER_WATER_TILES then
        SetTerrainKindTile(K, I, tkWater, ACC_MED) //Same accuracy as random tiling (see below)
      else
        for T := Low(TKMTerrainKind) to High(TKMTerrainKind) do
          if T <> tkCustom then
          begin
            //METHOD 1: Terrain type is the primary tile for this terrain
            if gTerrain.Land[I,K].BaseLayer.Terrain = Abs(Combo[T,T,1]) then
            begin
              SetTerrainKindTile(K, I, T, ACC_HIGH);
              Break; //Neither of the methods below can beat this one, so save time and don't check more TerrainKinds
            end;

            //METHOD 2: Terrain type is in RandomTiling
            for J := 1 to RandomTiling[T,0] do
              if gTerrain.Land[I,K].BaseLayer.Terrain = RandomTiling[T,J] then
              begin
                A := ACC_MED; //Random tiling is fairly accurate
                if T = tkCoal then A := ACC_MIN; //Random coal tiles are also used for edges, so edges are more accurate
                SetTerrainKindTile(K, I, T, A);
              end;

            //METHOD 3: Edging data
            A := ACC_LOW; //Edging data is not as accurate as other methods (some edges reuse the same tiles)
            for T2 := Low(TKMTerrainKind) to High(TKMTerrainKind) do
            begin
              //1 vertex is T, 3 vertexes are T2
              if gTerrain.Land[I,K].BaseLayer.Terrain = Abs(Combo[T,T2,1]) then
              begin
                Rot := gTerrain.Land[I,K].BaseLayer.Rotation mod 4;
                if Combo[T,T2,1] < 0 then Rot := (Rot+2) mod 4; //Flip
                case Rot of
                  0: begin
                       SetTerrainKindVertex(K,   I,   T2, A);
                       SetTerrainKindVertex(K+1, I,   T, A);
                       SetTerrainKindVertex(K,   I+1, T2, A);
                       SetTerrainKindVertex(K+1, I+1, T2, A);
                     end;
                  1: begin
                       SetTerrainKindVertex(K,   I,   T2, A);
                       SetTerrainKindVertex(K+1, I,   T2, A);
                       SetTerrainKindVertex(K,   I+1, T2, A);
                       SetTerrainKindVertex(K+1, I+1, T, A);
                     end;
                  2: begin
                       SetTerrainKindVertex(K,   I,   T2, A);
                       SetTerrainKindVertex(K+1, I,   T2, A);
                       SetTerrainKindVertex(K,   I+1, T, A);
                       SetTerrainKindVertex(K+1, I+1, T2, A);
                     end;
                  3: begin
                       SetTerrainKindVertex(K,   I,   T, A);
                       SetTerrainKindVertex(K+1, I,   T2, A);
                       SetTerrainKindVertex(K,   I+1, T2, A);
                       SetTerrainKindVertex(K+1, I+1, T2, A);
                     end;
                end;
              end;
              //Half T, half T2
              if gTerrain.Land[I,K].BaseLayer.Terrain = Abs(Combo[T,T2,2]) then
              begin
                Rot := gTerrain.Land[I,K].BaseLayer.Rotation mod 4;
                if Combo[T,T2,2] < 0 then Rot := (Rot+2) mod 4; //Flip
                case Rot of
                  0: begin
                       SetTerrainKindVertex(K,   I,   T, A);
                       SetTerrainKindVertex(K+1, I,   T, A);
                       SetTerrainKindVertex(K,   I+1, T2, A);
                       SetTerrainKindVertex(K+1, I+1, T2, A);
                     end;
                  1: begin
                       SetTerrainKindVertex(K,   I,   T2, A);
                       SetTerrainKindVertex(K+1, I,   T, A);
                       SetTerrainKindVertex(K,   I+1, T2, A);
                       SetTerrainKindVertex(K+1, I+1, T, A);
                     end;
                  2: begin
                       SetTerrainKindVertex(K,   I,   T2, A);
                       SetTerrainKindVertex(K+1, I,   T2, A);
                       SetTerrainKindVertex(K,   I+1, T, A);
                       SetTerrainKindVertex(K+1, I+1, T, A);
                     end;
                  3: begin
                       SetTerrainKindVertex(K,   I,   T, A);
                       SetTerrainKindVertex(K+1, I,   T2, A);
                       SetTerrainKindVertex(K,   I+1, T, A);
                       SetTerrainKindVertex(K+1, I+1, T2, A);
                     end;
                end;
              end;
              //3 vertex are T, 1 vertexes is T2
              if gTerrain.Land[I,K].BaseLayer.Terrain = Abs(Combo[T,T2,3]) then
              begin
                Rot := gTerrain.Land[I,K].BaseLayer.Rotation mod 4;
                if Combo[T,T2,3] < 0 then Rot := (Rot+2) mod 4; //Flip
                case Rot of
                  0: begin
                       SetTerrainKindVertex(K,   I,   T, A);
                       SetTerrainKindVertex(K+1, I,   T, A);
                       SetTerrainKindVertex(K,   I+1, T2, A);
                       SetTerrainKindVertex(K+1, I+1, T, A);
                     end;
                  1: begin
                       SetTerrainKindVertex(K,   I,   T2, A);
                       SetTerrainKindVertex(K+1, I,   T, A);
                       SetTerrainKindVertex(K,   I+1, T, A);
                       SetTerrainKindVertex(K+1, I+1, T, A);
                     end;
                  2: begin
                       SetTerrainKindVertex(K,   I,   T, A);
                       SetTerrainKindVertex(K+1, I,   T2, A);
                       SetTerrainKindVertex(K,   I+1, T, A);
                       SetTerrainKindVertex(K+1, I+1, T, A);
                     end;
                  3: begin
                       SetTerrainKindVertex(K,   I,   T, A);
                       SetTerrainKindVertex(K+1, I,   T, A);
                       SetTerrainKindVertex(K,   I+1, T, A);
                       SetTerrainKindVertex(K+1, I+1, T2, A);
                     end;
                end;
              end;
            end;
          end;
end;


procedure TKMTerrainPainter.InitSize(X, Y: Word);
var
  I: Integer;
begin
  for I := 0 to High(fUndos) do
    SetLength(fUndos[I].Data, Y+1, X+1);

  fBrushAreaTerKindCnt := 0;

  SetLength(LandTerKind, Y+1, X+1);
  SetLength(fTempLand, Y+1, X+1);
  SetLength(fBrushAreaTerKind, Sqr(BRUSH_MAX_SIZE+1));
end;


procedure TKMTerrainPainter.InitEmpty;
var
  I, K: Integer;
begin
  InitSize(gTerrain.MapX, gTerrain.MapY);

  //Fill in default terain type - Grass
  for I := 1 to gTerrain.MapY do
    for K := 1 to gTerrain.MapX do
      LandTerKind[I,K].TerKind := tkGrass;
end;


//Skip the KaM data and load MapEd vertice info
procedure TKMTerrainPainter.LoadFromFile(const aFileName: UnicodeString);
var
  I, K: Integer;
  TerType: ShortInt; //Krom's editor saves terrain kind as ShortInt
  S: TKMemoryStream;
  NewX, NewY: Integer;
  ResHead: packed record
    x1: Word;
    Allocated, Qty1, Qty2, x5, Len17: Integer;
  end;
  Chunk: AnsiString;
  MapEdChunkFound: Boolean;
  UseKaMFormat: Boolean;
  MapDataSize: Cardinal;
begin
  if not FileExists(aFileName) then Exit;

  InitSize(gTerrain.MapX, gTerrain.MapY);

  S := TKMemoryStream.Create;
  try
    S.LoadFromFile(aFileName);

    LoadMapHeader(S, NewX, NewY, UseKaMFormat, MapDataSize);

    //Skip terrain data
    if UseKaMFormat then
      S.Position := S.Position + 23 * NewX * NewY
    else
      S.Position := S.Position + MapDataSize;

    //For now we just throw away the resource footer because we don't understand it (and save a blank one)
    if UseKaMFormat then
    begin
      S.Read(ResHead, 22);
      S.Position := S.Position + 17 * ResHead.Allocated;
    end;

    //ADDN
    MapEdChunkFound := False;
    if S.Position < S.Size then
    begin
      Chunk := '    ';
      S.Read(Chunk[1], 4);
      if Chunk = 'ADDN' then
      begin
        S.Read(Chunk[1], 4);
        if Chunk = 'TILE' then
        begin
          S.Read(I, 4); //Chunk size
          S.Read(I, 4); //Cypher - ommited
          for I := 1 to NewY do
          for K := 1 to NewX do
          begin
            //Krom's editor saves negative numbers for tiles placed manually
            S.Read(TerType, 1);
            LandTerKind[I,K].TerKind := GetTerKind(TerType, UseKaMFormat);
          end;
          MapEdChunkFound := True; //Only set it once it's all loaded successfully
        end
        else
          gLog.AddNoTime(aFileName + ' has no MapEd.TILE chunk');
      end
      else
        gLog.AddNoTime(aFileName + ' has no MapEd.ADDN chunk');
    end
    else
      gLog.AddNoTime(aFileName + ' has no MapEd chunk');
  finally
    S.Free;
  end;

  //We can regenerate the MapEd data if it's missing (won't be as good as the original)
  if not MapEdChunkFound then
  begin
    gLog.AddNoTime('Regenerating missing MapEd data as best as we can');
    GenerateAddnData;
  end;

  MakeCheckpoint;
end;


procedure TKMTerrainPainter.SaveToFile(const aFileName: UnicodeString);
begin
  SaveToFile(aFileName, KMRECT_ZERO);
end;


procedure TKMTerrainPainter.SaveToFile(const aFileName: UnicodeString; const aInsetRect: TKMRect);
var
  I, K, IFrom, KFrom: Integer;
  S: TKMemoryStream;
  NewX, NewY: Integer;
  ResHead: packed record
    x1: Word;
    Allocated, Qty1, Qty2, x5, Len17: Integer;
  end;
  UseKaMFormat: Boolean;
  MapDataSize: Cardinal;
begin
  if not FileExists(aFileName) then Exit;

  S := TKMemoryStream.Create;
  try
    S.LoadFromFile(aFileName);

    LoadMapHeader(S, NewX, NewY, UseKaMFormat, MapDataSize);

    //Skip terrain data
    if UseKaMFormat then
      S.Position := S.Position + 23 * NewX * NewY
    else
      S.Position := S.Position + MapDataSize;

    //For now we just throw away the resource footer because we don't understand it (and save a blank one)
    if UseKaMFormat then
    begin
      S.Read(ResHead, 22);
      S.Position := S.Position + 17 * ResHead.Allocated;
    end;

    S.Write(AnsiString('ADDN')[1], 4);
    S.Write(AnsiString('TILE')[1], 4);

    S.Write(Integer(NewX * NewY)); //Chunk size
    S.Write(Integer(0)); //Cypher - ommited
    for I := 1 to NewY do
    begin
      IFrom := EnsureRange(I - aInsetRect.Top, 1, aInsetRect.Top + gTerrain.MapY);
      for K := 1 to NewX do
      begin
        KFrom := EnsureRange(K - aInsetRect.Left, 1, aInsetRect.Left + gTerrain.MapX);
        if (IFrom <> I - aInsetRect.Top)
          or (KFrom <> K - aInsetRect.Left) then
          S.Write(Byte(tkGrass))             // Its ok if we fill all with grass
        else
          S.Write(LandTerKind[IFrom,KFrom].TerKind, 1);
      end;
    end;

    S.SaveToFile(aFileName);
  finally
    S.Free;
  end;
end;


procedure TKMTerrainPainter.MakeCheckpoint;
var
  I, J, L: Integer;
begin
  //Get next pos in circular buffer
  fUndoPos := (fUndoPos + 1) mod MAX_UNDO;

  //Store new checkpoint
  for I := 1 to gTerrain.MapY do
    for J := 1 to gTerrain.MapX do
      with fUndos[fUndoPos] do
      begin
        Data[I,J].BaseLayer := gTerrain.Land[I,J].BaseLayer;
        Data[I,J].LayersCnt := gTerrain.Land[I,J].LayersCnt;
        Data[I,J].Height    := gTerrain.Land[I,J].Height;
        Data[I,J].Obj       := gTerrain.Land[I,J].Obj;
        Data[I,J].IsCustom  := gTerrain.Land[I,J].IsCustom;
        Data[I,J].TerKind   := LandTerKind[I,J].TerKind;
        Data[I,J].Tiles     := LandTerKind[I,J].Tiles;
        Data[I,J].HeightAdd := LandTerKind[I,J].HeightAdd;
        for L := 0 to 2 do
          Data[I,J].Layer[L] := gTerrain.Land[I,J].Layer[L];
      end;
  fUndos[fUndoPos].HasData := True;

  //Mark next checkpoint pos as invalid, so we can't Redo to it
  fUndos[(fUndoPos + 1) mod MAX_UNDO].HasData := False;
end;


function TKMTerrainPainter.CanUndo: Boolean;
begin
  Result := fUndos[(fUndoPos - 1 + MAX_UNDO) mod MAX_UNDO].HasData;
end;


function TKMTerrainPainter.CanRedo: Boolean;
begin
  Result := fUndos[(fUndoPos + 1) mod MAX_UNDO].HasData;
end;


procedure TKMTerrainPainter.Undo;
var
  Prev: Byte;
begin
  Prev := (fUndoPos - 1 + MAX_UNDO) mod MAX_UNDO;

  if not fUndos[Prev].HasData then Exit;

  fUndoPos := Prev;
  CheckpointToTerrain;
end;


procedure TKMTerrainPainter.Redo;
var
  Next: Byte;
begin
  //Next pos in circular buffer
  Next := (fUndoPos + 1) mod MAX_UNDO;

  if not fUndos[Next].HasData then Exit;

  fUndoPos := Next;

  CheckpointToTerrain;
end;


procedure TKMTerrainPainter.CheckpointToTerrain;
var
  I, J, L: Integer;
begin
  for I := 1 to gTerrain.MapY do
    for J := 1 to gTerrain.MapX do
      with fUndos[fUndoPos] do
      begin
        gTerrain.Land[I,J].BaseLayer.Terrain  := Data[I,J].BaseLayer.Terrain;
        gTerrain.Land[I,J].BaseLayer.Rotation := Data[I,J].BaseLayer.Rotation;
        gTerrain.Land[I,J].BaseLayer.Corners  := Data[I,J].BaseLayer.Corners;
        gTerrain.Land[I,J].LayersCnt          := Data[I,J].LayersCnt;
        gTerrain.Land[I,J].Height             := Data[I,J].Height;
        gTerrain.Land[I,J].Obj                := Data[I,J].Obj;
        gTerrain.Land[I,J].IsCustom           := Data[I,J].IsCustom;
        LandTerKind[I,J].TerKind   := Data[I,J].TerKind;
        LandTerKind[I,J].Tiles     := Data[I,J].Tiles;
        LandTerKind[I,J].HeightAdd := Data[I,J].HeightAdd;
        for L := 0 to 2 do
        begin
          gTerrain.Land[I,J].Layer[L].Terrain := Data[I,J].Layer[L].Terrain;
          gTerrain.Land[I,J].Layer[L].Rotation := Data[I,J].Layer[L].Rotation;
          gTerrain.Land[I,J].Layer[L].Corners := Data[I,J].Layer[L].Corners;
        end;
      end;

  //Update derived fields (lighting)
  gTerrain.UpdateLighting(gTerrain.MapRect);
  gTerrain.UpdatePassability(gTerrain.MapRect);
end;


procedure TKMTerrainPainter.Eyedropper(const aLoc: TKMPoint);
begin
  //Save specified loc's terrain info
  gGameCursor.Tag1 := gTerrain.Land[aLoc.Y, aLoc.X].BaseLayer.Terrain;
  gGameCursor.MapEdDir := gTerrain.Land[aLoc.Y, aLoc.X].BaseLayer.Rotation;
end;


procedure TKMTerrainPainter.RotateTile(const aLoc: TKMPoint);

  procedure RotateCorners(var aLayer: TKMTerrainLayer);
  var
    C: Byte;
    Corners: TKMByteSet;
  begin
    Corners := aLayer.Corners;
    aLayer.Corners := [];
    for C in Corners do
      Include(aLayer.Corners, (C + 1) mod 4);
  end;

var
  L: Integer;
begin
  if not gTerrain.TileInMapCoords(aLoc.X, aLoc.Y) then Exit;

  gTerrain.Land[aLoc.Y, aLoc.X].IsCustom := True;
  gTerrain.Land[aLoc.Y, aLoc.X].BaseLayer.Rotation := (gTerrain.Land[aLoc.Y, aLoc.X].BaseLayer.Rotation + 1) mod 4;
  RotateCorners(gTerrain.Land[aLoc.Y, aLoc.X].BaseLayer);

  for L := 0 to gTerrain.Land[aLoc.Y, aLoc.X].LayersCnt - 1 do
  begin
    gTerrain.Land[aLoc.Y, aLoc.X].Layer[L].Rotation := (gTerrain.Land[aLoc.Y, aLoc.X].Layer[L].Rotation + 1) mod 4;
    RotateCorners(gTerrain.Land[aLoc.Y, aLoc.X].Layer[L]);
  end;

  gTerrain.UpdatePassability(aLoc);
  MakeCheckpoint;
end;


procedure TKMTerrainPainter.UpdateStateIdle;
begin
  case gGameCursor.Mode of
    cmElevate,
    cmEqualize:   if (ssLeft in gGameCursor.SState) or (ssRight in gGameCursor.SState) then
                    EditHeight;
    cmBrush:      if (ssLeft in gGameCursor.SState) then
                  begin
                    if gGameCursor.MapEdMagicBrush then
                    begin
                      fUseTempLand := False;
                      fReplaceLayers := True;
                      IterateOverArea(gGameCursor.Cell, gGameCursor.MapEdSize, gGameCursor.MapEdShape = hsSquare, MagicBrush);
                    end else
                      EditBrush;
                  end;
    cmTiles:      if (ssLeft in gGameCursor.SState) then
                    if gGameCursor.MapEdDir in [0..3] then //Defined direction
                      EditTile(gGameCursor.Cell, gGameCursor.Tag1, gGameCursor.MapEdDir)
                    else //Random direction
                      EditTile(gGameCursor.Cell, gGameCursor.Tag1, KaMRandom(4, 'TKMTerrainPainter.UpdateStateIdle'));
    cmObjects:    if (ssLeft in gGameCursor.SState) then
                    gTerrain.SetObject(gGameCursor.Cell, gGameCursor.Tag1);
  end;
end;


procedure TKMTerrainPainter.UpdateState;
begin
//  case gGameCursor.Mode of
//    cmBrush:      if (ssLeft in gGameCursor.SState) then
//                  begin
//                    if gGameCursor.MapEdMagicBrush then
//                    begin
//                      UpdateTempLand;
//                      MagicBrush(gGameCursor.Cell, False);
//                    end else
//                      EditBrush(gGameCursor.Cell);
//                  end;
//  end;
end;


end.
