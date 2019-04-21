unit KM_Points;
{$I KaM_Remake.inc}
interface


type
  TKMDirection = (dirNA, dirN, dirNE, dirE, dirSE, dirS, dirSW, dirW, dirNW);

type
  //Records must be packed so they are stored identically in MP saves (padding bytes are unknown values)
  TKMPoint = record
    X,Y: Integer;
    class operator Equal(const A, B: TKMPoint): Boolean;
    class operator NotEqual(const A, B: TKMPoint): Boolean;
  end;

  TKMPointF = record
    X,Y: Single;
    class operator Equal(const A, B: TKMPointF): Boolean;
    class operator NotEqual(A: TKMPointF; B: TKMPointF): Boolean;
  end;

  TKMPointDir = packed record Loc: TKMPoint; Dir: TKMDirection; end;
  TKMPointExact = packed record Loc: TKMPoint; Exact: Boolean; end;
  TKMPointW = record X,Y: Word; end; // For backwards compatibility with cmp files
  TKMPointArray = array of TKMPoint;
  TKMPoint2Array = array of array of TKMPoint;
  TKMTrisArray = array of array [0..2] of Integer;

  TKMTriMesh = record
    Vertices: TKMPointArray;
    Polygons: TKMTrisArray;
  end;

  //We have our own TKMRect that consistently matches TKMPoint range
  //Rects are often used without range checking and include negative off-map coords
  TKMRect = packed record Left, Top, Right, Bottom: Integer end;
  TKMRectF = packed record Left, Top, Right, Bottom: Single end;

  TKMRangeInt = record
    Min, Max: Integer;
  end;

  TKMRangeSingle = record
    Min, Max: Single;
  end;

  TKMPointFunction = function(aPoint: TKMPoint): Boolean of object;

  function KMPoint(X,Y: Integer): TKMPoint;
  function KMPointF(X,Y: Single): TKMPointF; overload;
  function KMPointF(const P: TKMPoint):  TKMPointF; overload;
  function KMPointDir(X,Y: Integer; Dir: TKMDirection): TKMPointDir; overload;
  function KMPointDir(const P: TKMPoint; Dir: TKMDirection): TKMPointDir; overload;
  function KMPointX1Y1(const P:TKMPoint): TKMPoint;
  function KMPointBelow(const P: TKMPoint): TKMPoint;
  function KMPointAbove(const P: TKMPoint): TKMPoint;
  function KMNormVector(const P: TKMPoint; R: Integer): TKMPoint;

  function KMPointRound(const P: TKMPointF): TKMPoint;
  function KMSamePoint(const P1,P2: TKMPoint): Boolean; overload;
  function KMSamePointF(const P1,P2: TKMPointF): Boolean; overload;
  function KMSamePointF(const P1,P2: TKMPointF; Epsilon: Single): Boolean; overload;
  function KMSamePointDir(const P1,P2: TKMPointDir): Boolean;

  function KMRect(aLeft, aTop, aRight, aBottom: SmallInt): TKMRect; overload;
  function KMRect(const aPoint: TKMPoint): TKMRect; overload;
  function KMRect(const aPoint: TKMPointF): TKMRect; overload;
  function KMRectF(const aRect: TKMRect): TKMRectF; overload;
  function KMRectF(const aPoint: TKMPointF): TKMRectF; overload;
  function KMRectF(aLeft, aTop, aRight, aBottom: SmallInt): TKMRectF; overload;
  function KMRectRound(const aRect: TKMRectF): TKMRect;
  function KMSameRect(const aRect1, aRect2: TKMRect): Boolean;
  function KMRectWidth(const aRect: TKMRect): Integer;
  function KMRectHeight(const aRect: TKMRect): Integer;
  function KMRectGrow(const aRect: TKMRect; aInset: Integer): TKMRect; overload;
  function KMRectGrow(const aRect: TKMRect; const aDir: TKMDirection; aInset: Integer = 1): TKMRect; overload;
  function KMRectGrowTopLeft(const aRect: TKMRect; aInset: Integer = 1): TKMRect;
  function KMRectGrowTopRight(const aRect: TKMRect; aInset: Integer = 1): TKMRect;
  function KMRectGrowBottomLeft(const aRect: TKMRect; aInset: Integer = 1): TKMRect;
  function KMRectShinkTopLeft(const aRect: TKMRect): TKMRect;
  function KMRectGrowBottomRight(const aRect: TKMRect; aInset: Integer = 1): TKMRect;
  function KMClipRect(const aRect: TKMRect; X1,Y1,X2,Y2: Integer): TKMRect;
  function KMRectCorners(const aRect: TKMRect): TKMPointArray;
  function KMInRect(const aPoint: TKMPoint; const aRect: TKMRect): Boolean; overload;
  function KMInRect(const aPoint: TKMPointF; const aRect: TKMRect): Boolean; overload;
  function KMInRect(const aPoint: TKMPointF; const aRect: TKMRectF): Boolean; overload;
  function KMRectFitInRect(const aInnerRect, aOuterRect: TKMRect): Boolean;
  function KMRectArea(const aRect: TKMRect): Integer;
  function KMRectMove(const aRect: TKMRect; X,Y: Integer): TKMRect;
  procedure KMRectIncludePoint(var aRect: TKMRect; X,Y: Integer); overload;
  procedure KMRectIncludePoint(var aRect: TKMRect; const aPoint: TKMPoint); overload;
  procedure KMRectIncludeRect(var aRect: TKMRect; aRect2: TKMRect);

  function KMGetDirection(X,Y: Integer): TKMDirection; overload;
  function KMGetDirection(X,Y: Single): TKMDirection; overload;
  function KMGetDirection(const P: TKMPointF): TKMDirection; overload;
  function KMGetDirection(const FromPos, ToPos: TKMPoint): TKMDirection; overload;
  function KMGetDirection(const FromPos, ToPos: TKMPointF): TKMDirection; overload;
  function GetDirModifier(const Dir1,Dir2: TKMDirection): Byte;
  function KMGetVertexDir(X,Y: Integer): TKMDirection;
  function KMGetVertexTile(const P: TKMPoint; const Dir: TKMDirection): TKMPoint;
  function KMGetVertex(const Dir: TKMDirection): TKMPointF;
  function KMGetPointInDir(const aPoint: TKMPoint; const aDir: TKMDirection; aDist: Byte = 1): TKMPoint;

  function KMAddDirection(const aDir: TKMDirection; aAdd: Byte): TKMDirection;
  function KMNextDirection(const aDir: TKMDirection): TKMDirection;
  function KMPrevDirection(const aDir: TKMDirection): TKMDirection;

  function KMPointsAround(const P: TKMPoint; aIncludeSelf: Boolean = False): TKMPointArray;

  function KMGetDiagVertex(const P1,P2:TKMPoint): TKMPoint;
  function KMStepIsDiag(const P1,P2:TKMPoint): Boolean;

  function KMPointAverage(const A, B: TKMPoint): TKMPoint;
  function KMPointSubtract(const A, B: TKMPoint): TKMPoint;
  function KMPointAdd(const A, B: TKMPoint): TKMPoint; overload;
  function KMPointAdd(const A, B, C: TKMPoint): TKMPoint; overload;
  function KMDotProduct(const A, B: TKMPoint): Single;
  function KMDistanceAbs(const A, B: TKMPoint): Integer; overload;
  function KMDistanceAbs(const A, B: TKMPointF): Single; overload;
  function KMDistanceSqr(const A, B: TKMPoint): Single; overload;
  function KMDistanceSqr(const A, B: TKMPointF): Single; overload;

  function KMPerpendecular(const A,B: TKMPoint): TKMPointF;
  //Cross product of 2D vectors, pointed either Up or Down
  function KMNormal2Poly(const v1,v2,v3: TKMPoint): Single; overload;
  function KMPointInTriangle(const P, A, B, C: TKMPoint): Boolean;
  function KMSegmentsIntersect(const A, B, C, D: TKMPoint): Boolean;
  function KMSegmentsIntersectOrTouch(const A, B, C, D: TKMPoint): Boolean;

  function KMLength(const A, B: TKMPoint): Single; overload;
  function KMLength(const A, B: TKMPointF): Single; overload;
  function KMLengthDiag(const A, B: TKMPoint): Single; overload;
  function KMLengthDiag(X,Y: Integer; const B: TKMPoint): Single; overload;
  function KMLengthSqr(const A, B: TKMPoint): Integer; overload;
  function KMLengthSqr(const A, B: TKMPointF): Single; overload;

  function KMLerp(const A,B: TKMPoint; MixValue: Single): TKMPointF; overload;
  function KMLerp(const A,B: TKMPointF; MixValue: Single): TKMPointF; overload;

  procedure KMSwapPoints(var A,B: TKMPoint);
  procedure KMSwapPointDir(var A,B: TKMPointDir);

  function TypeToString(const P: TKMPoint): string; overload;
  function TypeToString(const P: TKMPointDir): string; overload;
  function TypeToString(const P: TKMPointF): string; overload;
  function TypeToString(const T: TKMDirection): string; overload;

  function StringToType(const Str: String): TKMPoint; overload;

  function KMRange(aMin, aMax: Integer): TKMRangeInt; overload;
  function KMRange(aMin, aMax: Single): TKMRangeSingle; overload;

  function KMInRange(aValue: Integer; const aRangeInt: TKMRangeInt): Boolean; overload;
  function KMInRange(aValue: Single; const aRangeSingle: TKMRangeSingle): Boolean; overload;

  function KMEnsureRange(aValue: Integer; const aRange: TKMRangeInt): Integer; overload;
  function KMEnsureRange(aValue: Single; const aRange: TKMRangeSingle): Single; overload;

  function KMEnlargeRange(const aRange: TKMRangeInt; aValue: Integer): TKMRangeInt; overload;
  function KMEnlargeRange(const aRange: TKMRangeSingle; aValue: Single): TKMRangeSingle; overload;


const
  KMPOINT_ZERO: TKMPoint = (X: 0; Y: 0);
  KMPOINTF_ZERO: TKMPointF = (X: 0.0; Y: 0.0);
  KMPOINT_INVALID_TILE: TKMPoint = (X: -1; Y: -1);
  KMPOINTF_INVALID_TILE: TKMPointF = (X: -1; Y: -1);

  KMRECT_ZERO: TKMRect = (Left: 0; Top: 0; Right: 0; Bottom: 0);
  KMRECT_INVALID_TILES: TKMRect = (Left: -1; Top: -1; Right: -1; Bottom: -1);


implementation
uses
  SysUtils, TypInfo, Math, KM_CommonUtils;


class operator TKMPoint.Equal(const A, B: TKMPoint): Boolean;
begin
  Result := KMSamePoint(A,B);
end;


class operator TKMPoint.NotEqual(const A, B: TKMPoint): Boolean;
begin
  Result := not KMSamePoint(A,B);
end;


class operator TKMPointF.Equal(const A, B: TKMPointF): Boolean;
begin
  Result := KMSamePointF(A,B);
end;


class operator TKMPointF.NotEqual(A: TKMPointF; B: TKMPointF): Boolean;
begin
  Result := not KMSamePointF(A,B);
end;


function KMPoint(X,Y: Integer): TKMPoint;
begin
  Result.X := X;
  Result.Y := Y;
end;


function KMPointF(const P: TKMPoint): TKMPointF;
begin
  Result.X := P.X;
  Result.Y := P.Y;
end;


function KMPointF(X, Y: Single): TKMPointF;
begin
  Result.X := X;
  Result.Y := Y;
end;


function KMPointDir(X,Y: Integer; Dir: TKMDirection): TKMPointDir;
begin
  Result.Loc.X := X;
  Result.Loc.Y := Y;
  Result.Dir := Dir;
end;


function KMPointDir(const P: TKMPoint; Dir: TKMDirection): TKMPointDir;
begin
  Result.Loc := P;
  Result.Dir := Dir;
end;


function KMPointX1Y1(const P: TKMPoint): TKMPoint;
begin
  Result.X := P.X + 1;
  Result.Y := P.Y + 1;
end;


function KMPointBelow(const P: TKMPoint): TKMPoint;
begin
  Result.X := P.X;
  Result.Y := P.Y + 1;
end;


function KMPointAbove(const P: TKMPoint): TKMPoint;
begin
  Result.X := P.X;
  Result.Y := P.Y - 1;
end;

function KMNormVector(const P: TKMPoint; R: Integer): TKMPoint;
begin
  Result.X := Round(R*P.X / sqrt(sqr(P.X) + sqr(P.Y)));
  Result.Y := Round(R*P.Y / sqrt(sqr(P.X) + sqr(P.Y)));
end;

function KMPointRound(const P: TKMPointF): TKMPoint;
begin
  Result.X := Round(P.X);
  Result.Y := Round(P.Y);
end;


function KMSamePoint(const P1,P2: TKMPoint): Boolean;
begin
  Result := ( P1.X = P2.X ) and ( P1.Y = P2.Y );
end;


function KMSamePointF(const P1,P2: TKMPointF): Boolean;
begin
  Result := ( P1.X = P2.X ) and ( P1.Y = P2.Y );
end;


function KMSamePointF(const P1,P2: TKMPointF; Epsilon: Single): Boolean;
begin
  Result := (abs(P1.X - P2.X) < Epsilon) and (abs(P1.Y - P2.Y) < Epsilon);
end;


function KMSamePointDir(const P1,P2: TKMPointDir): boolean;
begin
  Result := ( P1.Loc.X = P2.Loc.X ) and ( P1.Loc.Y = P2.Loc.Y ) and ( P1.Dir = P2.Dir );
end;


function KMRect(aLeft, aTop, aRight, aBottom: SmallInt): TKMRect;
begin
  Result.Left   := aLeft;
  Result.Right  := aRight;
  Result.Top    := aTop;
  Result.Bottom := aBottom;
end;


//Make rect with single point
function KMRect(const aPoint: TKMPoint): TKMRect;
begin
  Result.Left   := aPoint.X;
  Result.Right  := aPoint.X;
  Result.Top    := aPoint.Y;
  Result.Bottom := aPoint.Y;
end;


//Encompass PointF into fixed-point rect (2x2)
function KMRect(const aPoint: TKMPointF): TKMRect;
begin
  Result.Left   := Floor(aPoint.X) - Byte(Frac(aPoint.X) = 0);
  Result.Right  := Ceil(aPoint.X)  + Byte(Frac(aPoint.X) = 0);
  Result.Top    := Floor(aPoint.Y) - Byte(Frac(aPoint.Y) = 0);
  Result.Bottom := Ceil(aPoint.Y)  + Byte(Frac(aPoint.Y) = 0);
end;


function KMRectF(const aRect: TKMRect): TKMRectF;
begin
  Result.Left   := aRect.Left;
  Result.Right  := aRect.Right;
  Result.Top    := aRect.Top;
  Result.Bottom := aRect.Bottom;
end;


function KMRectF(const aPoint: TKMPointF): TKMRectF;
begin
  Result.Left   := aPoint.X;
  Result.Right  := aPoint.X;
  Result.Top    := aPoint.Y;
  Result.Bottom := aPoint.Y;
end;


function KMRectF(aLeft, aTop, aRight, aBottom: SmallInt): TKMRectF;
begin
  Result.Left   := aLeft;
  Result.Right  := aRight;
  Result.Top    := aTop;
  Result.Bottom := aBottom;
end;


function KMRectRound(const aRect: TKMRectF): TKMRect;
begin
  Result.Left   := Round(aRect.Left);
  Result.Right  := Round(aRect.Right);
  Result.Top    := Round(aRect.Top);
  Result.Bottom := Round(aRect.Bottom);
end;


function KMSameRect(const aRect1, aRect2: TKMRect): Boolean;
begin
  Result := (aRect1.Left = aRect2.Left)
        and (aRect1.Top = aRect2.Top)
        and (aRect1.Right = aRect2.Right)
        and (aRect1.Bottom = aRect2.Bottom);
end;


function KMRectWidth(const aRect: TKMRect): Integer;
begin
  Result := aRect.Right - aRect.Left;
end;


function KMRectHeight(const aRect: TKMRect): Integer;
begin
  Result := aRect.Bottom - aRect.Top;
end;


function KMRectGrow(const aRect: TKMRect; aInset: Integer): TKMRect;
begin
  Result.Left   := Math.Max(aRect.Left   - aInset, 0);
  Result.Right  := Math.Max(aRect.Right  + aInset, 0);
  Result.Top    := Math.Max(aRect.Top    - aInset, 0);
  Result.Bottom := Math.Max(aRect.Bottom + aInset, 0);
end;


function KMRectGrow(const aRect: TKMRect; const aDir: TKMDirection; aInset: Integer = 1): TKMRect; overload;
begin
  case aDir of
    dirNA: Result := KMRectGrow(aRect, aInset);
    dirNE: Result := KMRectGrowTopRight(aRect, aInset);
    dirSE: Result := KMRectGrowBottomRight(aRect, aInset);
    dirSW: Result := KMRectGrowBottomLeft(aRect, aInset);
    dirNW: Result := KMRectGrowTopLeft(aRect, aInset);
    dirN, dirE, dirS, dirW: Result := aRect; //not implemented yet
  end;
end;


function KMRectGrowTopLeft(const aRect: TKMRect; aInset: Integer = 1): TKMRect;
begin
  Result.Left   := aRect.Left - aInset;
  Result.Right  := aRect.Right;
  Result.Top    := aRect.Top  - aInset;
  Result.Bottom := aRect.Bottom;
end;


function KMRectGrowTopRight(const aRect: TKMRect; aInset: Integer = 1): TKMRect;
begin
  Result.Left   := aRect.Left;
  Result.Right  := aRect.Right + aInset;
  Result.Top    := aRect.Top - aInset;
  Result.Bottom := aRect.Bottom;
end;


function KMRectGrowBottomLeft(const aRect: TKMRect; aInset: Integer = 1): TKMRect;
begin
  Result.Left   := aRect.Left - aInset;
  Result.Right  := aRect.Right;
  Result.Top    := aRect.Top;
  Result.Bottom := aRect.Bottom + aInset;
end;


function KMRectShinkTopLeft(const aRect: TKMRect): TKMRect;
begin
  Result.Left   := aRect.Left + 1;
  Result.Right  := aRect.Right;
  Result.Top    := aRect.Top  + 1;
  Result.Bottom := aRect.Bottom;
end;


function KMRectGrowBottomRight(const aRect: TKMRect; aInset: Integer = 1): TKMRect;
begin
  Result.Left   := aRect.Left;
  Result.Right  := aRect.Right + aInset;
  Result.Top    := aRect.Top;
  Result.Bottom := aRect.Bottom + aInset;
end;


function KMClipRect(const aRect: TKMRect; X1,Y1,X2,Y2: Integer): TKMRect;
begin
  Result.Left   := EnsureRange(aRect.Left, X1, X2);
  Result.Right  := EnsureRange(aRect.Right, X1, X2);
  Result.Top    := EnsureRange(aRect.Top, Y1, Y2);
  Result.Bottom := EnsureRange(aRect.Bottom, Y1, Y2);
end;


function KMRectCorners(const aRect: TKMRect): TKMPointArray;
begin
  SetLength(Result, 4);
  Result[0] := KMPoint(aRect.Left, aRect.Top);
  Result[1] := KMPoint(aRect.Right, aRect.Top);
  Result[2] := KMPoint(aRect.Right, aRect.Bottom);
  Result[3] := KMPoint(aRect.Left, aRect.Bottom);
end;


function KMInRect(const aPoint: TKMPoint; const aRect: TKMRect): Boolean;
begin
  Result := InRange(aPoint.X, aRect.Left, aRect.Right) and InRange(aPoint.Y, aRect.Top, aRect.Bottom);
end;


function KMInRect(const aPoint: TKMPointF; const aRect: TKMRect): Boolean;
begin
  Result := InRange(aPoint.X, aRect.Left, aRect.Right) and InRange(aPoint.Y, aRect.Top, aRect.Bottom);
end;


function KMInRect(const aPoint: TKMPointF; const aRect: TKMRectF): Boolean;
begin
  Result := InRange(aPoint.X, aRect.Left, aRect.Right) and InRange(aPoint.Y, aRect.Top, aRect.Bottom);
end;


function KMRectFitInRect(const aInnerRect, aOuterRect: TKMRect): Boolean;
begin
  Result := (KMRectHeight(aInnerRect) <= KMRectHeight(aOuterRect))
        and (KMRectWidth(aInnerRect) <= KMRectWidth(aOuterRect))
end;


function KMRectArea(const aRect: TKMRect):Integer;
begin
  Result := (aRect.Right - aRect.Left) * (aRect.Bottom  - aRect.Top);
end;


function KMRectMove(const aRect: TKMRect; X,Y: Integer): TKMRect;
begin
  Result.Left   := aRect.Left + X;
  Result.Right  := aRect.Right + X;
  Result.Top    := aRect.Top + Y;
  Result.Bottom := aRect.Bottom + Y;
end;


procedure KMRectIncludePoint(var aRect: TKMRect; X,Y: Integer);
begin
  KMRectIncludePoint(aRect, KMPoint(X,Y));
end;


procedure KMRectIncludePoint(var aRect: TKMRect; const aPoint: TKMPoint);
begin
  if KMInRect(aPoint, aRect) then Exit;
  aRect.Left    := Min(aPoint.X, aRect.Left);
  aRect.Right   := Max(aPoint.X, aRect.Right);
  aRect.Top     := Min(aPoint.Y, aRect.Top);
  aRect.Bottom  := Max(aPoint.Y, aRect.Bottom);
end;


procedure KMRectIncludeRect(var aRect: TKMRect; aRect2: TKMRect);
begin
  KMRectIncludePoint(aRect, aRect2.Left, aRect2.Top);
  KMRectIncludePoint(aRect, aRect2.Right, aRect2.Top);
  KMRectIncludePoint(aRect, aRect2.Right, aRect2.Bottom);
  KMRectIncludePoint(aRect, aRect2.Left, aRect2.Bottom);
end;


function KMGetDirection(X,Y: Integer): TKMDirection;
const
  DirectionsBitfield: array [-1..1, -1..1] of TKMDirection =
    ((dirNW, dirW,  dirSW),
     (dirN,  dirNA, dirS),
     (dirNE, dirE,  dirSE));
var
  Scale: Integer;
  A, B: ShortInt;
begin
  Scale := Max(Max(Abs(X), Abs(Y)), 1);
  A := Round(X / Scale);
  B := Round(Y / Scale);
  Result := DirectionsBitfield[A, B]; // -1, 0, 1
end;


function KMGetDirection(X,Y: Single): TKMDirection;
const
  DirectionsBitfield: array [-1..1, -1..1] of TKMDirection =
    ((dirNW, dirW,  dirSW),
     (dirN,  dirNA, dirS),
     (dirNE, dirE,  dirSE));
var
  Scale: Single;
  A, B: ShortInt;
begin
  Scale := Max(Max(Abs(X), Abs(Y)), 1);
  A := Round(X / Scale);
  B := Round(Y / Scale);
  Result := DirectionsBitfield[A, B]; // -1, 0, 1
end;


function KMGetDirection(const P: TKMPointF): TKMDirection;
begin
  Result := KMGetDirection(P.X, P.Y);
end;


function KMGetDirection(const FromPos, ToPos: TKMPoint): TKMDirection;
begin
  Result := KMGetDirection(Integer(ToPos.X - FromPos.X), Integer(ToPos.Y - FromPos.Y));
end;


function KMGetDirection(const FromPos, ToPos: TKMPointF): TKMDirection;
begin
  Result := KMGetDirection(ToPos.X - FromPos.X, ToPos.Y - FromPos.Y);
end;


//How big is the difference between directions (in fights hit from behind is 5 times harder)
//  1 0 1
//  2   2
//  3 4 3
function GetDirModifier(const Dir1,Dir2: TKMDirection): Byte;
begin
  Result := Abs(Byte(Dir1) - ((Byte(Dir2) + 4) mod 8));

  if Result > 4 then
    Result := 8 - Result; //Mirror it, as the difference must always be 0..4
end;


function KMGetVertexDir(X,Y: Integer): TKMDirection;
const DirectionsBitfield: array [-1..0, -1..0] of TKMDirection =
        ((dirSE, dirNE), (dirSW, dirNW));
begin
  Result := DirectionsBitfield[X,Y];
end;


function KMGetVertexTile(const P: TKMPoint; const Dir: TKMDirection): TKMPoint;
const
  XBitField: array[TKMDirection] of smallint = (0,0,1,0,1,0,0,0,0);
  YBitField: array[TKMDirection] of smallint = (0,0,0,0,1,0,1,0,0);
begin
  Result := KMPoint(P.X+XBitField[Dir], P.Y+YBitField[Dir]);
end;


function KMGetVertex(const Dir: TKMDirection): TKMPointF;
const
  XBitField: array[TKMDirection] of single = (0, 0, 0.7,1,0.7,0,-0.7,-1,-0.7);
  YBitField: array[TKMDirection] of single = (0,-1,-0.7,0,0.7,1, 0.7, 0,-0.7);
begin
  Result := KMPointF(XBitField[Dir], YBitField[Dir]);
end;


function KMGetPointInDir(const aPoint: TKMPoint; const aDir: TKMDirection; aDist: Byte = 1): TKMPoint;
const
  XBitField: array [TKMDirection] of SmallInt = (0, 0, 1, 1, 1, 0,-1,-1,-1);
  YBitField: array [TKMDirection] of SmallInt = (0,-1,-1, 0, 1, 1, 1, 0,-1);
begin
  Result.X := aPoint.X + XBitField[aDir] * aDist;
  Result.Y := aPoint.Y + YBitField[aDir] * aDist;
end;


function KMAddDirection(const aDir: TKMDirection; aAdd: Byte): TKMDirection;
begin
  Assert(aDir <> dirNA);
  Result := TKMDirection((Byte(aDir) + aAdd - 1) mod 8 + 1);
end;


function KMNextDirection(const aDir: TKMDirection): TKMDirection;
begin
  if aDir < dirNW then
    Result := Succ(aDir)
  else
    Result := dirN; //Rewind to start
end;


function KMPrevDirection(const aDir: TKMDirection): TKMDirection;
begin
  if aDir > dirN then
    Result := Pred(aDir)
  else
    Result := dirNW; //Rewind to end
end;


function KMPointsAround(const P: TKMPoint; aIncludeSelf: Boolean = False): TKMPointArray;
var
  I,J,K: Integer;
begin
  if aIncludeSelf then
    SetLength(Result, 9)
  else
    SetLength(Result, 8);
  K := 0;
  for I := -1 to 1 do
    for J := -1 to 1 do
      if aIncludeSelf or (I <> 0) or (J <> 0) then
      begin
        Result[K] := KMPoint(P.X + J, P.Y + I);
        Inc(K);
      end;
end;


function KMGetDiagVertex(const P1,P2: TKMPoint): TKMPoint;
begin
  //Returns the position of the vertex inbetween the two diagonal points (points must be diagonal)
  Result.X := max(P1.X,P2.X);
  Result.Y := max(P1.Y,P2.Y);
end;


function KMStepIsDiag(const P1,P2: TKMPoint): Boolean;
begin
  Result := (P2.X - P1.X <> 0) and (P2.Y - P1.Y <> 0);
end;


function KMPointAverage(const A, B: TKMPoint): TKMPoint;
begin
  Result.X := (A.X + B.X) shr 1;
  Result.Y := (A.Y + B.Y) shr 1;
end;


function KMPointSubtract(const A, B: TKMPoint): TKMPoint;
begin
  Result.X := A.X - B.X;
  Result.Y := A.Y - B.Y;
end;


function KMPointAdd(const A, B: TKMPoint): TKMPoint;
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
end;


function KMPointAdd(const A, B, C: TKMPoint): TKMPoint;
begin
  Result.X := A.X + B.X + C.X;
  Result.Y := A.Y + B.Y + C.Y;
end;


function KMDotProduct(const A, B: TKMPoint): Single;
begin
  Result := A.X * B.X + A.Y * B.Y;
end;


// Faster version of distance when we need just approximate information
function KMDistanceAbs(const A, B: TKMPoint): Integer;
begin
  Result := Abs(A.X - B.X) + Abs(A.Y - B.Y);
end;


function KMDistanceAbs(const A, B: TKMPointF): Single;
begin
  Result := Abs(A.X - B.X) + Abs(A.Y - B.Y);
end;


function KMDistanceSqr(const A, B: TKMPoint): Single;
begin
  Result := Sqr(A.X - B.X) + Sqr(A.Y - B.Y);
end;


function KMDistanceSqr(const A, B: TKMPointF): Single;
begin
  Result := Sqr(A.X - B.X) + Sqr(A.Y - B.Y);
end;


function KMPerpendecular(const A,B: TKMPoint): TKMPointF;
var
  Tmp: TKMPointF;
  D: Single;
begin
  Tmp.X := B.X - A.X;
  Tmp.Y := B.Y - A.Y;

  D := Sqrt(Tmp.X * Tmp.X + Tmp.Y * Tmp.Y);

  Result.X := A.X - Tmp.Y / D;
  Result.Y := A.Y + Tmp.X / D;
end;


function KMNormal2Poly(const v1,v2,v3: TKMPoint): Single;
begin
  Result := (v1.Y - v2.Y) * (v1.X - v3.X) - (v1.X - v2.X) * (v1.Y - v3.Y);
end;


function KMPointInTriangle(const P, A, B, C: TKMPoint): Boolean;
begin
  Result := (KMNormal2Poly(A, B, P) > 0) and (KMNormal2Poly(B, C, P) > 0) and (KMNormal2Poly(C, A, P) > 0);
end;


//Segments intersect
function KMSegmentsIntersect(const A, B, C, D: TKMPoint): Boolean;
var
  ABx, ABy, CDx, CDy: Single;
  D2, S, T: Single;
begin
  ABx := B.x - A.x;     ABy := B.y - A.y;
  CDx := D.x - C.x;     CDy := D.y - C.y;

  D2 := -CDx * ABy + ABx * CDy;

  S := (-ABy * (A.x - C.x) + ABx * (A.y - C.y)) / D2;
  T := ( CDx * (A.y - C.y) - CDy * (A.x - C.x)) / D2;

  Result := (S > 0) and (S < 1) and (T > 0) and (T < 1)
            and not IsNaN(S) and not IsNaN(T)
            and not IsInfinite(S) and not IsInfinite(T);
end;


function KMSegmentsIntersectOrTouch(const A, B, C, D: TKMPoint): Boolean;
var
  ABx, ABy, CDx, CDy: Single;
  D2, S, T: Single;
begin
  ABx := B.x - A.x;     ABy := B.y - A.y;
  CDx := D.x - C.x;     CDy := D.y - C.y;

  D2 := -CDx * ABy + ABx * CDy;

  S := (-ABy * (A.x - C.x) + ABx * (A.y - C.y)) / D2;
  T := ( CDx * (A.y - C.y) - CDy * (A.x - C.x)) / D2;

  Result := (S >= 0) and (S <= 1) and (T >= 0) and (T <= 1)
            and not IsNaN(S) and not IsNaN(T)
            and not IsInfinite(S) and not IsInfinite(T);
end;


//True length between 2 points
function KMLength(const A,B: TKMPoint): Single;
begin
  Result := Sqrt(Sqr(A.X - B.X) + Sqr(A.Y - B.Y));
end;


function KMLength(const A,B: TKMPointF): Single;
begin
  Result := Sqrt(Sqr(A.X - B.X) + Sqr(A.Y - B.Y));
end;


//Rough and faster Length as combination of straight and diagonal
function KMLengthDiag(const A, B: TKMPoint): Single;
begin
  if Abs(A.X - B.X) > Abs(A.Y - B.Y) then
    Result := Abs(A.X - B.X) + Abs(A.Y - B.Y) * 0.41
  else
    Result := Abs(A.Y - B.Y) + Abs(A.X - B.X) * 0.41;
end;


function KMLengthDiag(X,Y: Integer; const B: TKMPoint): Single;
begin
  if Abs(X - B.X) > Abs(Y - B.Y) then
    Result := Abs(X - B.X) + Abs(Y - B.Y) * 0.41
  else
    Result := Abs(Y - B.Y) + Abs(X - B.X) * 0.41;
end;


//Squared length for cases where we need to compare two lengths
//or pick the best one and actual value is not that important
//we can save some cycles on ommitting SQRT
function KMLengthSqr(const A, B: TKMPoint): Integer;
begin
  Result := Sqr(A.X - B.X) + Sqr(A.Y - B.Y);
end;


function KMLengthSqr(const A, B: TKMPointF): Single;
begin
  Result := Sqr(A.X - B.X) + Sqr(A.Y - B.Y);
end;


function KMLerp(const A,B: TKMPoint; MixValue: Single): TKMPointF;
begin
  Result.X := A.X + (B.X - A.X) * MixValue;
  Result.Y := A.Y + (B.Y - A.Y) * MixValue;
end;


function KMLerp(const A,B: TKMPointF; MixValue: Single): TKMPointF;
begin
  Result.X := A.X + (B.X - A.X) * MixValue;
  Result.Y := A.Y + (B.Y - A.Y) * MixValue;
end;


procedure KMSwapPoints(var A,B: TKMPoint);
var T: Integer;
begin
  T:=A.X; A.X:=B.X; B.X:=T;
  T:=A.Y; A.Y:=B.Y; B.Y:=T;
end;


procedure KMSwapPointDir(var A,B: TKMPointDir);
var
  T: TKMPointDir;
begin
  T := A;
  A := B;
  B := T;
end;


function TypeToString(const P: TKMPoint): string;
begin
  Result := '(' + IntToStr(P.X) + ';' + IntToStr(P.Y) + ')';
end;


function TypeToString(const P: TKMPointDir): string;
begin
  Result := Format('%s Dir = %s', [TypeToString(P.Loc), GetEnumName(TypeInfo(TKMDirection), Integer(P.Dir))]);
end;


function TypeToString(const P: TKMPointF): string;
begin
  Result := Format('(%s;%s)', [FormatFloat('##0.##', P.X), FormatFloat('##0.##', P.Y)]);
end;


function StringToType(const Str: String): TKMPoint;
var
  DelimPos, X, Y: Integer;
begin
  Result := KMPOINT_INVALID_TILE;
  DelimPos := StrIndexOf(Str, ';');
  if DelimPos > 0 then
  begin
    if TryStrToInt(Copy(Str, 2, DelimPos - 1), X)
      and TryStrToInt(Copy(Str, DelimPos + 2, Length(Str) - DelimPos - 2), Y) then
      Result := KMPoint(X,Y);
  end;

end;


function TypeToString(const T: TKMDirection): string;
const
  S: array [TKMDirection] of string = ('N/A', 'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW');
begin
  Result := S[T];
end;


function KMRange(aMin, aMax: Integer): TKMRangeInt;
begin
  Result.Min := Min(aMin, aMax);
  Result.Max := Max(aMin, aMax);
end;


function KMRange(aMin, aMax: Single): TKMRangeSingle;
begin
  Result.Min := Min(aMin, aMax);
  Result.Max := Max(aMin, aMax);
end;


function KMInRange(aValue: Integer; const aRangeInt: TKMRangeInt): Boolean;
begin
  Result := InRange(aValue, aRangeInt.Min, aRangeInt.Max);
end;


function KMInRange(aValue: Single; const aRangeSingle: TKMRangeSingle): Boolean;
begin
  Result := InRange(aValue, aRangeSingle.Min, aRangeSingle.Max);
end;


function KMEnsureRange(aValue: Integer; const aRange: TKMRangeInt): Integer;
begin
  Result := EnsureRange(aValue, aRange.Min, aRange.Max);
end;


function KMEnsureRange(aValue: Single; const aRange: TKMRangeSingle): Single;
begin
  Result := EnsureRange(aValue, aRange.Min, aRange.Max);
end;


function KMEnlargeRange(const aRange: TKMRangeInt; aValue: Integer): TKMRangeInt;
begin
  Result.Min := Min(aRange.Min, aValue);
  Result.Max := Max(aRange.Max, aValue);
end;


function KMEnlargeRange(const aRange: TKMRangeSingle; aValue: Single): TKMRangeSingle;
begin
  Result.Min := Min(aRange.Min, aValue);
  Result.Max := Max(aRange.Max, aValue);
end;


end.
