unit KM_RMGUtils;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, Math, Contnrs, KM_CommonTypes,
  KM_Points, KM_Terrain, KM_FloodFill;

type
  {
  RPoint = Record
          Case Boolean of
          False : (X,Y : Real);
          True : (R,theta,phi : Real);
          end;
  }
  TElementPointer = ^TElement;

  TElement = record
    X,Y: SmallInt;
    Next: TElementPointer;
  end;

  TResElementPointer = ^TResElement;

  TResElement = record
    X,Y: SmallInt;
    Probability: Single;
    Next: TResElementPointer;
  end;

  THeightElementPointer = ^THeightElement;

  THeightElement = record
    X,Y: SmallInt;
    Distance: Word;
  end;


  TBalancedResource = record
    InitOwner, Resource, MinesCnt: Byte;
    //Owners: array[0..MAX_HANDS] of Byte;
    Quantity: Integer;
    TileCounter: TIntegerArray;
    Points: TKMPointArray;
  end;

  TBalancedResource1Array = array of TBalancedResource;

// Random number generator for RMG
  TKMRandomNumberGenerator = class
  private
    fSeed: LongInt;
  public
    property Seed: LongInt read fSeed write fSeed;
    procedure NextSeed();
    function Random(): Single;
    function RandomI(const Max: Integer): Integer;
  end;

// Fast flood algorithm (Queue + for cycle instead of recursion)
  { This class was moved to KM_FloodFill in \src\utils
  TKMQuickFlood = class
  private
    fStartQueue, fEndQueue: TElementPointer;
    fMinLimit, fMaxLimit: TKMPoint;
    fScanEightTiles: Boolean; // True = scan 8 tiles around, False = scan 4 tiles (no performance impact!)
  protected
    procedure MakeNewQueue(); virtual;
    procedure InsertInQueue(const aX,aY: SmallInt); virtual;
    function RemoveFromQueue(var aX,aY: SmallInt): Boolean; virtual;
    function IsQueueEmpty: Boolean; virtual;

    function CanBeVisited(const aX,aY: SmallInt): Boolean; virtual; abstract;
    function IsVisited(const aX,aY: SmallInt): Boolean; virtual; abstract;
    procedure MarkAsVisited(const aX,aY: SmallInt); virtual; abstract;
    procedure SearchAround(aX,aY: SmallInt); virtual;
  public
    constructor Create(const aScanEightTiles: Boolean = False); virtual;
    procedure QuickFlood(aX,aY: SmallInt); virtual;
  end;
  //}

// Search for specific number (biome) with counter
  TKMSearchBiome = class(TKMQuickFlood)
  private
    fCount: Integer;
    fSearch, fNewSearch: SmallInt;
    fSearchArr: TInteger2Array;
  protected
    function CanBeVisited(const aX,aY: SmallInt): Boolean; override;
    function IsVisited(const aX,aY: SmallInt): Boolean; override;
    procedure MarkAsVisited(const aX,aY: SmallInt); override;
  public
    property Count: Integer read fCount;
    property SearchArr: TInteger2Array read fSearchArr write fSearchArr;
    constructor Create(aMinLimit, aMaxLimit: TKMPoint; var aSearchArr: TInteger2Array; const aScanEightTiles: Boolean = False); reintroduce;//virtual; reintroduce;
    procedure QuickFlood(aX,aY,aSearch,aNewSearch: SmallInt); reintroduce;//virtual; reintroduce;
  end;

// Search for specific number (biome) with counter and protected area in which can not be values specified in constant array T_FIX
  TKMSearchSimilarBiome = class(TKMSearchBiome)
  private
    fBiome: Byte;
    fBiomeArr: TKMByte2Array;
  protected
    function CanBeVisited(const aX,aY: SmallInt): Boolean; override;
  public
    constructor Create(aMinLimit, aMaxLimit: TKMPoint; var aSearchArr: TInteger2Array; var aBiomeArr: TKMByte2Array; const aScanEightTiles: Boolean = False); reintroduce;
    procedure QuickFlood(aX,aY,aSearch,aNewSearch: SmallInt; aBiome: Byte); reintroduce;
  end;

// Search walkable areas to replace mountain top with snow
  TKMSearchWalkableAreas = class(TKMSearchBiome)
  private
    fPresentBiomes: Cardinal;
    fBiomeArr: TKMByte2Array;
  protected
    function CanBeVisited(const aX,aY: SmallInt): Boolean; override;
  public
    constructor Create(aMinLimit, aMaxLimit: TKMPoint; var aSearchArr: TInteger2Array; var aBiomeArr: TKMByte2Array; const aScanEightTiles: Boolean = False); reintroduce;
    procedure QuickFlood(aX,aY,aSearch,aNewSearch: SmallInt; var aCount: Integer; var aPresentBiomes: Cardinal); reintroduce;
  end;

// Search class with fill by specific number in fFillArr
  TKMFillBiome = class(TKMSearchBiome)
  private
    fFill: SmallInt;
    fFillArr: TKMByte2Array;
  protected
    procedure MarkAsVisited(const aX,aY: SmallInt); override;
  public
    constructor Create(aMinLimit, aMaxLimit: TKMPoint; var aSearchArr: TInteger2Array; var aFillArr: TKMByte2Array; const aScanEightTiles: Boolean = False); reintroduce;
    procedure QuickFlood(aX,aY,aSearch,aNewSearch,aFill: SmallInt); reintroduce;
  end;

// Search class with fill by specific number in fObjectArr
  TKMFillObject = class(TKMFillBiome)
  private
    fBiomeArr: TKMWord2Array;
  protected
    function CanBeVisited(const aX,aY: SmallInt): Boolean; override;
  public
    constructor Create(aMinLimit, aMaxLimit: TKMPoint; var aSearchArr: TInteger2Array; var aObjectArr: TKMByte2Array; var aBiomeArr: TKMWord2Array; const aScanEightTiles: Boolean = False); reintroduce;
    procedure QuickFlood(aX,aY,aSearch,aNewSearch,aObject: SmallInt); reintroduce;
  end;


// Search for resources and record its shape
// This is special class for Mine fix in RMG
  TKMMinerFixSearch = class(TKMQuickFlood)
  private
    fSearch: Byte;
    fMinPoint, fMaxPoint: TSmallIntArray;
    fVisited: TBoolean2Array;
    fSearchArr: TKMByte2Array;
  protected
    function CanBeVisited(const aX,aY: SmallInt): Boolean; override;
    function IsVisited(const aX,aY: SmallInt): Boolean; override;
    procedure MarkAsVisited(const aX,aY: SmallInt); override;
  public
    constructor Create(aMinLimit, aMaxLimit: TKMPoint; var aMinPoint, aMaxPoint: TSmallIntArray; var aVisited: TBoolean2Array; var aSearchArr: TKMByte2Array); reintroduce;
    procedure QuickFlood(aX,aY: SmallInt; aSearch: Byte); reintroduce;
  end;

// Search for specific tile and his surrounding tiles (if fReturnTiles then return array of those tiles)
// Made for GenerateTiles procedure in RMG
  TKMTileFloodSearch = class(TKMSearchBiome)
  private
    fReturnTiles: Boolean;
    fTileArr, fTileCounterArr: TInteger2Array;
    fCounter: TIntegerArray;
    fOutIdx: Word;
    fOutPointArr: TKMPointArray;
    fOutLevelArr: TKMByteArray;
  protected
    procedure MarkAsVisited(const aX,aY: SmallInt); override;
  public
    constructor Create(aMinLimit, aMaxLimit: TKMPoint; var aSearchArr, aTileArr: TInteger2Array); reintroduce;
    procedure QuickFlood(aX,aY,aSearch,aNewSearch: SmallInt; aCounter: TIntegerArray = nil); reintroduce; overload;
    procedure QuickFlood(aX,aY,aSearch,aNewSearch: SmallInt; var aOutIdx: Integer; var aTileCounterArr: TInteger2Array; var aOutPointArr: TKMPointArray; var aOutLevelArr: TKMByteArray); reintroduce; overload;
  end;

// Calculator of full tiles inside of shape (good for resources)
TKMInternalTileCounter = class(TKMQuickFlood)
  private
    fCount: Integer;
    fSearchBiome, fVisitedNum: Byte;
    fBiomeArr, fVisitedArr: TKMByte2Array;
  protected
    function CanBeVisited(const aX,aY: SmallInt): Boolean; override;
    function IsVisited(const aX,aY: SmallInt): Boolean; override;
    procedure MarkAsVisited(const aX,aY: SmallInt); override;
  public
    property Count: Integer read fCount;
    property VisitedArr: TKMByte2Array read fVisitedArr write fVisitedArr;
    constructor Create(aMinLimit, aMaxLimit: TKMPoint; var aBiomeArr, aVisitedArr: TKMByte2Array; const aScanEightTiles: Boolean = False); reintroduce;
    procedure QuickFlood(aX,aY,aSearchBiome,aVisitedNum: SmallInt); reintroduce;
  end;

// Remove "sharp" edges of each shape = edges with 1x1 or 2x2 tiles => each tile have at least 2 surrounding tiles in row and 2 tiles in column
TKMSharpShapeFixer = class(TKMInternalTileCounter)
  private
  protected
    procedure MarkAsVisited(const aX,aY: SmallInt); override;
  public
  end;

// Standard flood fill algorithm with queue instead of recursion -> first element is the closest to the center point, second is automatically second closest etc.
// This is class for resources in RMG because it is quite complicated task (randomly generate something which must look like original template but still different...)
  TKMFloodWithQueue = class
  private
    fQueue: TQueue;
    fActualIdx: Byte;
    fPointsArr: TKMPoint2Array;
    fSearchArr, fCount: TInteger2Array;
    fFillArr, fCountVisitedArr: TKMByte2Array;
    fFillResource: TKMFillBiome;
    fTileCounter: TKMInternalTileCounter;
    fShapeFixer: TKMSharpShapeFixer;
    fRNG: TKMRandomNumberGenerator;
  protected
    procedure ClearCountVisitedArr();
    procedure InsertInQueue(aX,aY: Integer; aProbability: Single);
    function RemoveFromQueue(var aX,aY: SmallInt; var aProbability: Single): Boolean;
  public
    constructor Create(var aRNG: TKMRandomNumberGenerator; var aPointsArr: TKMPoint2Array; var aCount, aSearchArr: TInteger2Array; var aFillArr: TKMByte2Array);
    destructor Destroy; override;
    procedure FloodFillWithQueue(var aPointArr: TKMPointArray; var aCnt_FINAL, aCnt_ACTUAL, aRESOURCE: Integer; const aProbability, aPROB_REDUCER: Single; var aPoints: TKMPointArray);
  end;

  TKMBalancedResources = class
  private
  protected
    fResCnt: Word;
    fResources: TBalancedResource1Array;
  public
    constructor Create();
    destructor Destroy(); override;

    property Count: Word read fResCnt;
    property Resources: TBalancedResource1Array read fResources write fResources;

    procedure ClearArray();
    procedure AddResource(aOwner, aResource, aMinesCnt: Byte; aQuantity: Integer; var aPoints: TKMPointArray);
  end;

// Fill walkable areas with height (the impact of height is decreasing with increased distance)
// Made for GenerateHeight procedure in RMG
  TKMHeightFillWalkableAreas = class
  private
    fQueue: TQueue;
    fIgnoreTileType: Boolean;
    fVisited: Byte;
    fHeight: Integer;
    fDecreaseCoef, fMaxDistance: Single;
    fHeightArr: TInteger2Array;
    fVisitedArr, fBiomeArr: TKMByte2Array;
  protected
    procedure ClearVisitedArr();
    function CanBeVisited(const aX,aY: SmallInt; const Distance: Word): Boolean;
    function CanBeExpanded(const aX,aY: SmallInt; const aDistance: Word): Boolean;
    procedure MarkAsVisited(const aX,aY: SmallInt; const Distance: Word);
    procedure InsertInQueue(const aX,aY: SmallInt; const aDistance: Word);
    function RemoveFromQueue(var aX,aY: SmallInt; var aDistance: Word): Boolean;
  public
    constructor Create(var aBiomeArr: TKMByte2Array; var aHeightArr: TInteger2Array); reintroduce;
    destructor Destroy(); override;
    procedure ExpandHeight(var aInitPoints: TKMPointArray; aHeight: Integer; aDecreaseCoef: Single; aIgnoreTileTypes: Boolean = False);
  end;

  // Get all points which are inside of specific shape (biome)
  TKMShapePointsExtractor = class(TKMInternalTileCounter)
  private
    fPointCnt: Word;
    fPoints: TKMPointArray;
  protected
    procedure MarkAsVisited(const aX,aY: SmallInt); override;
  public
    procedure QuickFlood(aX,aY,aSearchBiome,aVisitedNum: SmallInt; var aPoints: TKMPointArray); reintroduce;
  end;


implementation
uses
  KM_RandomMapGenerator;




{ TKMRandomNumberGenerator }
procedure TKMRandomNumberGenerator.NextSeed();
begin
  // xorshift32 (2^32 numbers and 2^31 combinations after modification)
  fSeed := fSeed XOR (fSeed shl 13);
  fSeed := fSeed XOR (fSeed shr 17);
  fSeed := fSeed XOR (fSeed shl 5);
end;

// Random number generator (We want set own seed)
function TKMRandomNumberGenerator.Random(): Single;
begin
  NextSeed();
  Result := fSeed * 0.000000000465661287307739; // Seed / High(Integer) = Seed * (1/2^31) = Seed * 0.000000000465661287307739 -> faster
  if (Result < 0) then
     Result := -Result;
end;

function TKMRandomNumberGenerator.RandomI(const Max: Integer): Integer;
begin
  Result := Trunc(Random() * Max);
end;




{ TKMQuickFlood }
{ This class was moved to KM_FloodFill in \src\utils
constructor TKMQuickFlood.Create(const aScanEightTiles: Boolean = False);
begin
  fScanEightTiles := aScanEightTiles;
end;

procedure TKMQuickFlood.MakeNewQueue();
begin
    new(fStartQueue);
    fEndQueue := fStartQueue;
end;

procedure TKMQuickFlood.InsertInQueue(const aX, aY: SmallInt);
begin
    fEndQueue^.X := aX;
    fEndQueue^.Y := aY;
    new(fEndQueue^.Next);
    fEndQueue := fEndQueue^.Next;
end;

function TKMQuickFlood.RemoveFromQueue(var aX, aY: SmallInt): Boolean;
var pom: TElementPointer;
begin
  Result := True;
  if fStartQueue = fEndQueue then
  begin
    Result := False;
  end
  else
  begin
    aX := fStartQueue^.X;
    aY := fStartQueue^.Y;
    pom := fStartQueue;
    fStartQueue := fStartQueue^.Next;
    Dispose(pom);
  end;
end;

function TKMQuickFlood.IsQueueEmpty: Boolean;
begin
  Result := fStartQueue = fEndQueue;
end;

procedure TKMQuickFlood.SearchAround(aX,aY: SmallInt);

  procedure ScanInColumn(const aX,aY: SmallInt; var PreviousStep: Boolean);
  begin
    if PreviousStep then
      PreviousStep := CanBeVisited(aX,aY)
    else if not IsVisited(aX,aY) AND CanBeVisited(aX,aY) then
    begin
      PreviousStep := True;
      InsertInQueue(aX, aY);
    end;
  end;

  procedure ScanInRow(const aX,aY, Dir: SmallInt; const CheckActualPosition: Boolean = False);
  var
    X,Y_T,Y_D: SmallInt;
    Top,Down, TopCheck,DownCheck: Boolean;
  begin
    Top := aY > fMinLimit.Y;
    Down := aY < fMaxLimit.Y;
    Y_T := aY - 1;
    Y_D := aY + 1;
    TopCheck := False;
    DownCheck := False;
    if Top then
      TopCheck := CanBeVisited(aX,Y_T) AND not IsVisited(aX, Y_T);
    if Down then
      DownCheck := CanBeVisited(aX,Y_D) AND not IsVisited(aX, Y_D);
    if CheckActualPosition then
    begin
      if TopCheck then
        InsertInQueue(aX, Y_T);
      if DownCheck then
        InsertInQueue(aX, Y_D);
    end;
    X := aX + Dir;
    while (X >= fMinLimit.X) AND (X <= fMaxLimit.X) AND CanBeVisited(X,aY) do
    begin
      MarkAsVisited(X, aY);
      if Top then
        ScanInColumn(X,Y_T, TopCheck);
      if Down then
        ScanInColumn(X,Y_D, DownCheck);
      X := X + Dir;
    end;
    if fScanEightTiles AND (X >= fMinLimit.X) AND (X <= fMaxLimit.X) then
    begin
      if Top then
        ScanInColumn(X,Y_T, TopCheck);
      if Down then
        ScanInColumn(X,Y_D, DownCheck);
    end;
  end;

begin
  MarkAsVisited(aX, aY);
  ScanInRow(aX,aY, 1, True);
  ScanInRow(aX,aY, -1, False);
end;

procedure TKMQuickFlood.QuickFlood(aX,aY: SmallInt);
begin
  MakeNewQueue();
  if CanBeVisited(aX, aY) then
    InsertInQueue(aX, aY);
  while not IsQueueEmpty do
  begin
    RemoveFromQueue(aX, aY);
    if not IsVisited(aX, aY) then
      SearchAround(aX, aY);
  end;
end;
//}



{ TKMSearchBiome }
constructor TKMSearchBiome.Create(aMinLimit, aMaxLimit: TKMPoint; var aSearchArr: TInteger2Array; const aScanEightTiles: Boolean = False);
begin
  inherited Create(aScanEightTiles);
  fSearchArr := aSearchArr;
  fMinLimit := aMinLimit;
  fMaxLimit := aMaxLimit;
end;

function TKMSearchBiome.CanBeVisited(const aX,aY: SmallInt): Boolean;
begin
  Result := fSearchArr[aY,aX] = fSearch;
end;

function TKMSearchBiome.IsVisited(const aX,aY: SmallInt): Boolean;
begin
  Result := fSearchArr[aY,aX] = fNewSearch;
end;

procedure TKMSearchBiome.MarkAsVisited(const aX,aY: SmallInt);
begin
  fSearchArr[aY,aX] := fNewSearch;
  fCount := fCount + 1;
end;

procedure TKMSearchBiome.QuickFlood(aX,aY,aSearch,aNewSearch: SmallInt);
begin
  fCount := 0;
  fSearch := aSearch;
  fNewSearch := aNewSearch;
  inherited QuickFlood(aX,aY);
end;



{ TKMSearchSimilarBiome }
constructor TKMSearchSimilarBiome.Create(aMinLimit, aMaxLimit: TKMPoint; var aSearchArr: TInteger2Array; var aBiomeArr: TKMByte2Array; const aScanEightTiles: Boolean = False);
begin
  inherited Create(aMinLimit, aMaxLimit, aSearchArr, aScanEightTiles);
  fBiomeArr := aBiomeArr;
end;

function TKMSearchSimilarBiome.CanBeVisited(const aX,aY: SmallInt): Boolean;
var
  X0, Y0, X2, Y2: SmallInt;
begin
  X0 := Max(fMinLimit.X, aX-2);
  Y0 := Max(fMinLimit.Y, aY-2);
  X2 := Min(fMaxLimit.X, aX+2);
  Y2 := Min(fMaxLimit.Y, aY+2);
  Result := inherited CanBeVisited(aX,aY)
            AND (T_FIX[fBiome, fBiomeArr[Y0,aX] ] > 0)
            AND (T_FIX[fBiome, fBiomeArr[Y2,aX] ] > 0)
            AND (T_FIX[fBiome, fBiomeArr[aY,X0] ] > 0)
            AND (T_FIX[fBiome, fBiomeArr[aY,X2] ] > 0)
            AND (T_FIX[fBiome, fBiomeArr[Y0,X0] ] > 0)
            AND (T_FIX[fBiome, fBiomeArr[Y2,X2] ] > 0)
            AND (T_FIX[fBiome, fBiomeArr[Y2,X0] ] > 0)
            AND (T_FIX[fBiome, fBiomeArr[Y0,X2] ] > 0);
end;

procedure TKMSearchSimilarBiome.QuickFlood(aX,aY,aSearch,aNewSearch: SmallInt; aBiome: Byte);
begin
  fBiome := aBiome;
  inherited QuickFlood(aX,aY,aSearch,aNewSearch);
end;






{ TKMSearchWalkableAreas }
constructor TKMSearchWalkableAreas.Create(aMinLimit, aMaxLimit: TKMPoint; var aSearchArr: TInteger2Array; var aBiomeArr: TKMByte2Array; const aScanEightTiles: Boolean = False);
begin
  inherited Create(aMinLimit, aMaxLimit, aSearchArr, aScanEightTiles);
  fBiomeArr := aBiomeArr;
end;

function TKMSearchWalkableAreas.CanBeVisited(const aX,aY: SmallInt): Boolean;
begin
  Result := canWalk[ fBiomeArr[aY,aX] ];
  if not Result then
    fPresentBiomes := fPresentBiomes OR ($1 shl fBiomeArr[aY,aX]);
end;

procedure TKMSearchWalkableAreas.QuickFlood(aX,aY,aSearch,aNewSearch: SmallInt; var aCount: Integer; var aPresentBiomes: Cardinal);
begin
  fPresentBiomes := 0;
  inherited QuickFlood(aX,aY,aSearch,aNewSearch);
  aPresentBiomes := fPresentBiomes;
  aCount := fCount;
end;





{ TKMFillBiome }
constructor TKMFillBiome.Create(aMinLimit, aMaxLimit: TKMPoint; var aSearchArr: TInteger2Array; var aFillArr: TKMByte2Array; const aScanEightTiles: Boolean = False);
begin
  inherited Create(aMinLimit, aMaxLimit, aSearchArr, aScanEightTiles);
  fFillArr := aFillArr;
end;

procedure TKMFillBiome.MarkAsVisited(const aX,aY: SmallInt);
begin
  inherited MarkAsVisited(aX,aY);
  fFillArr[aY,aX] := fFill;
end;

procedure TKMFillBiome.QuickFlood(aX,aY,aSearch,aNewSearch,aFill: SmallInt);
begin
  fFill := aFill;
  inherited QuickFlood(aX,aY,aSearch,aNewSearch);
end;






{ TKMFillObject }
constructor TKMFillObject.Create(aMinLimit, aMaxLimit: TKMPoint; var aSearchArr: TInteger2Array; var aObjectArr: TKMByte2Array; var aBiomeArr: TKMWord2Array; const aScanEightTiles: Boolean = False);
begin
  inherited Create(aMinLimit, aMaxLimit, aSearchArr, aObjectArr, aScanEightTiles);
  fBiomeArr := aBiomeArr;
end;

function TKMFillObject.CanBeVisited(const aX,aY: SmallInt): Boolean;
begin
  Result := (fSearchArr[aY,aX] = fSearch) AND WT[ fBiomeArr[aY,aX] ];
end;

procedure TKMFillObject.QuickFlood(aX,aY,aSearch,aNewSearch,aObject: SmallInt);
begin
  inherited QuickFlood(aX,aY,aSearch,aNewSearch,aObject);
end;






{ TKMMinerFixSearch }
constructor TKMMinerFixSearch.Create(aMinLimit, aMaxLimit: TKMPoint; var aMinPoint, aMaxPoint: TSmallIntArray; var aVisited: TBoolean2Array; var aSearchArr: TKMByte2Array);
begin
  inherited Create;
  fMinLimit := aMinLimit;
  fMaxLimit := aMaxLimit;
  fMinPoint := aMinPoint;
  fMaxPoint := aMaxPoint;
  fVisited := aVisited;
  fSearchArr := aSearchArr;
end;

function TKMMinerFixSearch.CanBeVisited(const aX,aY: SmallInt): Boolean;
begin
  Result := fSearchArr[aY,aX] = fSearch;
end;

function TKMMinerFixSearch.IsVisited(const aX,aY: SmallInt): Boolean;
begin
  Result := fVisited[aY,aX];
end;

procedure TKMMinerFixSearch.MarkAsVisited(const aX,aY: SmallInt);
begin
  fVisited[aY,aX] := True;
  if fMinPoint[aX] > aY then
    fMinPoint[aX] := aY;
  if fMaxPoint[aX] <= aY then
    fMaxPoint[aX] := aY;
end;

procedure TKMMinerFixSearch.QuickFlood(aX,aY: SmallInt; aSearch: Byte);
begin
  fSearch := aSearch;
  inherited QuickFlood(aX,aY);
end;







{ TKMTileFloodSearch }
constructor TKMTileFloodSearch.Create(aMinLimit, aMaxLimit: TKMPoint; var aSearchArr, aTileArr: TInteger2Array);
begin
  inherited Create(aMinLimit, aMaxLimit, aSearchArr);
  fTileArr := aTileArr;
end;

procedure TKMTileFloodSearch.MarkAsVisited(const aX,aY: SmallInt);
var
  X0,X1,X2,Y0,Y1,Y2, Surroundings, I: SmallInt;
begin
  fSearchArr[aY,aX] := fNewSearch;

  if fReturnTiles then
  begin
    for I := High(fTileCounterArr[fTileArr[aY,aX]]) downto 0 do
      if fTileCounterArr[fTileArr[aY,aX],I] <> 0 then
        break;

    fTileCounterArr[fTileArr[aY,aX],I] := fTileCounterArr[fTileArr[aY,aX],I] - 1;

    fOutPointArr[fOutIdx] := KMPoint(aX,aY);
    fOutLevelArr[fOutIdx] := I;
    fOutIdx := fOutIdx + 1;
  end
  else
  begin
    X0 := Max(1,aX-1);
    X2 := Min(gTerrain.MapX-1,aX+1);
    Y0 := Max(1,aY-1);
    Y2 := Min(gTerrain.MapY-1,aY+1);
    Surroundings := 0;
    for Y1 := Y0 to Y2 do
      for X1 := X0 to X2 do
        Surroundings := Surroundings + Byte((fSearchArr[Y1,X1] = fSearch) OR (fSearchArr[Y1,X1] = fNewSearch));
    case Surroundings of
      5:    begin fTileArr[aY,aX] := 1; fCounter[1] := fCounter[1]+1; end;
      6:    begin fTileArr[aY,aX] := 2; fCounter[2] := fCounter[2]+1; end;
      7, 8: begin fTileArr[aY,aX] := 3; fCounter[3] := fCounter[3]+1; end;
      9:    begin fTileArr[aY,aX] := 4; fCounter[4] := fCounter[4]+1; end;
      else  begin fTileArr[aY,aX] := 0; fCounter[0] := fCounter[0]+1; end;
    end;
  end;
end;

procedure TKMTileFloodSearch.QuickFlood(aX,aY,aSearch,aNewSearch: SmallInt; aCounter: TIntegerArray = nil);
begin
  fReturnTiles := False;
  fCounter := aCounter;
  inherited QuickFlood(aX,aY,aSearch,aNewSearch);
end;

procedure TKMTileFloodSearch.QuickFlood(aX,aY,aSearch,aNewSearch: SmallInt; var aOutIdx: Integer; var aTileCounterArr: TInteger2Array; var aOutPointArr: TKMPointArray; var aOutLevelArr: TKMByteArray);
begin
  fReturnTiles := True;
  fTileCounterArr := aTileCounterArr;
  fOutIdx := 0;
  fOutPointArr := aOutPointArr;
  fOutLevelArr := aOutLevelArr;
  inherited QuickFlood(aX,aY,aSearch,aNewSearch);
  aOutIdx := fOutIdx-1;
end;





{ TKMInternalTileCounter }
constructor TKMInternalTileCounter.Create(aMinLimit, aMaxLimit: TKMPoint; var aBiomeArr, aVisitedArr: TKMByte2Array; const aScanEightTiles: Boolean = False);
begin
  inherited Create(aScanEightTiles);
  fBiomeArr := aBiomeArr;
  fVisitedArr := aVisitedArr;
  fMinLimit := aMinLimit;
  fMaxLimit := aMaxLimit;
end;

function TKMInternalTileCounter.CanBeVisited(const aX,aY: SmallInt): Boolean;
begin
  Result := fBiomeArr[aY,aX] = fSearchBiome;
end;

function TKMInternalTileCounter.IsVisited(const aX,aY: SmallInt): Boolean;
begin
  Result := fVisitedArr[aY,aX] > fVisitedNum;
end;

procedure TKMInternalTileCounter.MarkAsVisited(const aX,aY: SmallInt);
var
  X,Y: SmallInt;
begin
  fVisitedArr[aY,aX] := fVisitedNum + 1;
  for Y := Max(Low(fBiomeArr), aY-1) to Min(High(fBiomeArr), aY+1) do
  for X := Max(Low(fBiomeArr[Y]), aX-1) to Min(High(fBiomeArr[Y]), aX+1) do
    if not CanBeVisited(X,Y) then
      Exit;
  fCount := fCount + 1;
end;

procedure TKMInternalTileCounter.QuickFlood(aX,aY,aSearchBiome,aVisitedNum: SmallInt);
begin
  fCount := 0;
  fSearchBiome := aSearchBiome;
  fVisitedNum := aVisitedNum;
  inherited QuickFlood(aX,aY);
end;






{ TKMSharpShapeFixer }
procedure TKMSharpShapeFixer.MarkAsVisited(const aX,aY: SmallInt);
  procedure InsertInQ();
  begin
    // First mark as visited
    fBiomeArr[aY,aX] := 0;
    fCount := fCount + 1;
    // Now add in queue surrounding points (or use simple recursion but recursion should not be used)
    if (aX+1 <= High(fBiomeArr[aY])) AND CanBeVisited(aX+1,aY) then
    begin
      InsertInQueue(aX+1,aY);
      fVisitedArr[aY,aX+1] := fVisitedNum;
    end;
    if (aX-1 >= Low(fBiomeArr[aY])) AND CanBeVisited(aX-1,aY) then
    begin
      InsertInQueue(aX-1,aY);
      fVisitedArr[aY,aX-1] := fVisitedNum;
    end;
    if (aY+1 <= High(fBiomeArr)) AND CanBeVisited(aX,aY+1) then
    begin
      InsertInQueue(aX,aY+1);
      fVisitedArr[aY+1,aX] := fVisitedNum;
    end;
    if (aY-1 >= Low(fBiomeArr)) AND CanBeVisited(aX,aY-1) then
    begin
      InsertInQueue(aX,aY-1);
      fVisitedArr[aY-1,aX] := fVisitedNum;
    end;
  end;
var
  L,R: Boolean;
  cnt: Word;
  I: SmallInt;
begin
  fVisitedArr[aY,aX] := fVisitedNum + 1; // Mark as visited
  // Compute count of identical tiles on left and right side
  cnt := 0;
  L := True;
  R := True;
  for I := 1 to 2 do
  begin
    if L AND (aY-I >= Low(fBiomeArr)) AND (CanBeVisited(aX,aY-I)) then
      cnt := cnt + 1
    else
      L := False;
    if R AND (aY+I <= High(fBiomeArr)) AND (CanBeVisited(aX,aY+I)) then
      cnt := cnt + 1
    else
      R := False;
  end;
  if (cnt < 2) then
  begin
    InsertInQ();
    Exit;
  end;
  // Compute count of identical tiles on top and down
  cnt := 0;
  L := True;
  R := True;
  for I := 1 to 2 do
  begin
    if L AND (aX-I >= Low(fBiomeArr[aY])) AND (CanBeVisited(aX-I,aY)) then
      cnt := cnt + 1
    else
      L := False;
    if R AND (aX+I <= High(fBiomeArr[aY])) AND (CanBeVisited(aX+I,aY)) then
      cnt := cnt + 1
    else
      R := False;
  end;
  if (cnt < 2) then
    InsertInQ();
end;






{ TKMFloodWithQueue }
constructor TKMFloodWithQueue.Create(var aRNG: TKMRandomNumberGenerator; var aPointsArr: TKMPoint2Array; var aCount, aSearchArr: TInteger2Array; var aFillArr: TKMByte2Array);
var
  MinP, MaxP: TKMPoint;
begin
  fRNG := aRNG;
  fPointsArr := aPointsArr;
  fCount := aCount;
  fFillArr := aFillArr;
  fSearchArr := aSearchArr;
  MinP := KMPoint( Low(fFillArr[0]), Low(fFillArr) );
  MaxP := KMPoint( High(fFillArr[0]), High(fFillArr) );
  SetLength(fCountVisitedArr, Length(fFillArr), Length(fFillArr[0]));
  ClearCountVisitedArr();
  fQueue := TQueue.Create();
  fFillResource := TKMFillBiome.Create( MinP, MaxP, fSearchArr, fFillArr  );
  fTileCounter := TKMInternalTileCounter.Create( MinP, MaxP, fFillArr, fCountVisitedArr);
  fShapeFixer := TKMSharpShapeFixer.Create( MinP, MaxP, fFillArr, fCountVisitedArr);
end;

destructor TKMFloodWithQueue.Destroy();
begin
  fFillResource.Free;
  fTileCounter.Free;
  fShapeFixer.Free;
  fQueue.Free();
  inherited;
end;

procedure TKMFloodWithQueue.ClearCountVisitedArr();
var
  Y: SmallInt;
begin
  fActualIdx := 0;
  for Y := Low(fCountVisitedArr) to High(fCountVisitedArr) do
    FillChar(fCountVisitedArr[Y,0], SizeOf(fCountVisitedArr[Y,0]) * Length(fCountVisitedArr[Y]), #0);
end;

procedure TKMFloodWithQueue.InsertInQueue(aX,aY: Integer; aProbability: Single);
var
  RE: TResElementPointer;
begin
  New(RE);
  RE^.X := aX;
  RE^.Y := aY;
  RE^.Probability := aProbability;
  fQueue.Push(RE);
end;

function TKMFloodWithQueue.RemoveFromQueue(var aX,aY: SmallInt; var aProbability: Single): Boolean;
var
  RE: TResElementPointer;
begin
  Result := (fQueue.Count > 0);
  if Result then
  begin
    RE := fQueue.Pop;
    aX := RE^.X;
    aY := RE^.Y;
    aProbability := RE^.Probability;
    Dispose(RE);
  end;
end;

procedure TKMFloodWithQueue.FloodFillWithQueue(var aPointArr: TKMPointArray; var aCnt_FINAL, aCnt_ACTUAL, aRESOURCE: Integer; const aProbability, aPROB_REDUCER: Single; var aPoints: TKMPointArray);
const
  PROTECT_COEF = 1;
var
  I,X,Y,X2,Y2: SmallInt;
  Cnt, POMCnt: Integer;
  Probability, Prob_POM: Single;
begin
  X := 0;
  Y := 0;
  Cnt := aCnt_actual;
  POMCnt := aCnt_actual;
  // Insert init point into queue (it can be multiple points because of minimal size of iron mines
  for I := Low(aPointArr) to High(aPointArr) do
    InsertInQueue(aPointArr[I].X, aPointArr[I].Y, aProbability);
  // Find avaiable shapes in surrounding tiles and turn them into resources
  while RemoveFromQueue(X, Y, Probability) AND ((Probability = 1) OR (POMCnt < aCnt_FINAL) OR (Cnt < aCnt_FINAL)) do  // Probability = 1 in case that we need this shape in new mine
    if (   (fCount[Y,X] > 0)  OR  ( (aRESOURCE = Byte(btCoal)) AND (fCount[Y,X] < 0) )   )
       AND (fRNG.Random() < Probability) then
    begin
      //aCnt_actual := aCnt_actual + abs(fCount[Y,X]); // After tests it looks like too inaccurate
      POMCnt := POMCnt + abs(fCount[Y,X]);
      fCount[Y,X] := 0;

      SetLength(aPoints, Length(aPoints)+1); // Just a few interactions
      aPoints[ High(aPoints) ] := fPointsArr[Y,X];
      fFillResource.QuickFlood(fPointsArr[Y,X].X, fPointsArr[Y,X].Y, fSearchArr[ fPointsArr[Y,X].Y, fPointsArr[Y,X].X ], 0, aRESOURCE);
      // Do not start counter until we know that final shape is smaller than desired shape
      if (POMCnt >= aCnt_FINAL) then
      begin
        // Now check how many tiles can be turned into resource (some of them will be border tiles)
        fTileCounter.QuickFlood(fPointsArr[Y,X].X, fPointsArr[Y,X].Y, aRESOURCE, fActualIdx);
        Cnt := aCnt_actual + fTileCounter.Count;
        fActualIdx := fActualIdx + 1;
        if (fActualIdx = High(Byte)) then
          ClearCountVisitedArr();
      end;
      // Find avaiable shapes in surrounding tiles
      Prob_POM := Probability - aPROB_REDUCER;
      if (Prob_POM > 0) then
      begin
        if (aRESOURCE < Byte(btGold)) then
        begin
          if (X+1 <= High(fPointsArr[Y])) then InsertInQueue( X+1, Y, Prob_POM );
          if (X-1 >= Low(fPointsArr[Y]))  then InsertInQueue( X-1, Y, Prob_POM );
        end;
        if (Y-1 >= Low(fPointsArr))  then InsertInQueue( X, Y-1, Prob_POM );
        if (Y+1 <= High(fPointsArr)) then InsertInQueue( X, Y+1, Prob_POM );
      end;
    end;
  // Fix shape of created resource (bad shape = shape with width / height 1 or 2 tiles = only transitions are here, no real usage)
  aCnt_actual := Cnt;
  POMCnt := 0;
  I := 0;
  while (I < Length(aPointArr)) AND (POMCnt < 5*Length(aPointArr)) do
  begin
    POMCnt := POMCnt + 1;
    fShapeFixer.QuickFlood(  fPointsArr[ aPointArr[I].Y,aPointArr[I].X ].X, fPointsArr[ aPointArr[I].Y,aPointArr[I].X ].Y, aRESOURCE, fActualIdx  );
    if (fShapeFixer.Count <= 0) then
      I := I + 1;
    fActualIdx := fActualIdx + 1;
    if (fActualIdx = High(Byte)) then
      ClearCountVisitedArr();
  end;
  // Clear queue (create protected radius around resources)
  while RemoveFromQueue(X, Y, Probability) do
  begin
    for Y2 := Max(Low(fPointsArr), Y-PROTECT_COEF) to Min(Y+PROTECT_COEF, High(fPointsArr)) do
    for X2 := Max(Low(fPointsArr[Y]), X-PROTECT_COEF) to Min(X+PROTECT_COEF, High(fPointsArr[Y])) do
      if (fCount[Y2,X2] > 0) then
        fCount[Y2,X2] := -fCount[Y2,X2]; // Create negative count so it can be always used for coal
  end;
end;


{ TKMBalancedResources }
constructor TKMBalancedResources.Create();
begin
  fResCnt := 0;
end;


destructor TKMBalancedResources.Destroy();
begin
  inherited;
end;


procedure TKMBalancedResources.ClearArray();
begin
  SetLength(fResources, 0);
  fResCnt := 0;
end;


procedure TKMBalancedResources.AddResource(aOwner, aResource, aMinesCnt: Byte; aQuantity: Integer; var aPoints: TKMPointArray);
begin
  if (fResCnt >= Length(fResources)) then
    SetLength(fResources, fResCnt + 24);
  with Resources[fResCnt] do
  begin
    InitOwner := aOwner;
    //Owners[0] := aOwner;
    Resource := aResource;
    MinesCnt := aMinesCnt;
    Quantity := aQuantity;
    Points := aPoints;
  end;
  fResCnt := fResCnt + 1;
end;




{ TKMHeightFillWalkableAreas }
constructor TKMHeightFillWalkableAreas.Create(var aBiomeArr: TKMByte2Array; var aHeightArr: TInteger2Array);
begin
  fBiomeArr := aBiomeArr;
  fHeightArr := aHeightArr;

  fVisited := 255;
  SetLength(fVisitedArr, Length(aBiomeArr), Length(aBiomeArr[0]));
  fQueue := TQueue.Create();
end;

destructor TKMHeightFillWalkableAreas.Destroy();
begin
  fQueue.Free();
  inherited;
end;

procedure TKMHeightFillWalkableAreas.ClearVisitedArr();
var
  Y: SmallInt;
begin
  if (fVisited >= 255) then
  begin
    fVisited := 0;
    for Y := Low(fVisitedArr) to High(fVisitedArr) do
      FillChar(fVisitedArr[Y,0], SizeOf(fVisitedArr[Y,0]) * Length(fVisitedArr[Y]), #0);
  end;
  fVisited := fVisited + 1;
end;

function TKMHeightFillWalkableAreas.CanBeVisited(const aX,aY: SmallInt; const Distance: Word): Boolean;
// [btWetland,btSwamp,btWater,btIce]
// [btStone,btGold,btEgold,btIron,btEIron,btDark]
begin
  //Result := (fVisitedArr[aY,aX] <> fVisited) AND WT[ fBiomeArr[aY,aX] ]; // WT = Walkable textures (it is stored in KM_RandomMapGenerator)
  Result := (fVisitedArr[aY,aX] <> fVisited);
end;

function TKMHeightFillWalkableAreas.CanBeExpanded(const aX,aY: SmallInt; const aDistance: Word): Boolean;
begin
  Result := (aDistance < fMaxDistance) AND (
              fIgnoreTileType OR
              (fBiomeArr[aY,aX] < Byte(btStone)) OR
              (fBiomeArr[Max(0,aY-1),aX] < Byte(btStone)) OR
              (fBiomeArr[aY,Max(0,aX-1)] < Byte(btStone)) OR
              (fBiomeArr[Max(0,aY-1),Max(0,aX-1)] < Byte(btStone))
            );
end;

procedure TKMHeightFillWalkableAreas.MarkAsVisited(const aX,aY: SmallInt; const Distance: Word);
begin
  fVisitedArr[aY,aX] := fVisited;
  fHeightArr[aY,aX] := fHeightArr[aY,aX] + Round(fHeight - Distance * fDecreaseCoef);
end;

procedure TKMHeightFillWalkableAreas.InsertInQueue(const aX,aY: SmallInt; const aDistance: Word);
var
  HE: THeightElementPointer;
begin
  MarkAsVisited(aX,aY,aDistance);
  New(HE);
  HE^.X := aX;
  HE^.Y := aY;
  HE^.Distance := aDistance;
  fQueue.Push(HE);
end;

function TKMHeightFillWalkableAreas.RemoveFromQueue(var aX,aY: SmallInt; var aDistance: Word): Boolean;
var
  HE: THeightElementPointer;
begin
  Result := (fQueue.Count > 0);
  if Result then
  begin
    HE := fQueue.Pop;
    aX := HE^.X;
    aY := HE^.Y;
    aDistance := HE^.Distance;
    Dispose(HE);
  end;
end;

procedure TKMHeightFillWalkableAreas.ExpandHeight(var aInitPoints: TKMPointArray; aHeight: Integer; aDecreaseCoef: Single; aIgnoreTileTypes: Boolean = False);
var
  I,X,Y: SmallInt;
  Distance: Word;
begin
  fHeight := aHeight;
  fDecreaseCoef := aDecreaseCoef;
  fIgnoreTileType := aIgnoreTileTypes;
  if (aHeight < 0) then
    fDecreaseCoef := -fDecreaseCoef;
  fMaxDistance := abs(aHeight / aDecreaseCoef);

  ClearVisitedArr();
  for I := 0 to Length(aInitPoints) - 1 do
    InsertInQueue(aInitPoints[I].X,aInitPoints[I].Y,0);
  while RemoveFromQueue(X,Y,Distance) do
    if CanBeExpanded(X,Y,Distance) then
    begin
      Distance := Distance + 1;
      if (X > Low(fVisitedArr[0]))  AND CanBeVisited(X-1,Y,Distance) then InsertInQueue(X-1,Y,Distance);
      if (X < High(fVisitedArr[0])) AND CanBeVisited(X+1,Y,Distance) then InsertInQueue(X+1,Y,Distance);
      if (Y > Low(fVisitedArr))     AND CanBeVisited(X,Y-1,Distance) then InsertInQueue(X,Y-1,Distance);
      if (Y < High(fVisitedArr))    AND CanBeVisited(X,Y+1,Distance) then InsertInQueue(X,Y+1,Distance);
    end;
end;



{ TKMShapePointsExtractor }
procedure TKMShapePointsExtractor.MarkAsVisited(const aX,aY: SmallInt);
begin
  fVisitedArr[aY,aX] := fVisitedNum + 1; // Mark as visited
  if (fPointCnt >= Length(fPoints)) then
    SetLength(fPoints, fPointCnt + 500);
  fPoints[fPointCnt] := KMPoint(aX,aY);
  fPointCnt := fPointCnt + 1;
end;

procedure TKMShapePointsExtractor.QuickFlood(aX,aY,aSearchBiome,aVisitedNum: SmallInt; var aPoints: TKMPointArray);
begin
  fPointCnt := 0;
  inherited QuickFlood(aX,aY,aSearchBiome,aVisitedNum);
  SetLength(fPoints, fPointCnt);
  aPoints := fPoints;
end;

end.
