unit KM_CommonTypes;
{$I KaM_Remake.inc}
interface
uses
  KM_Points;

type
  TKMByteSet = set of Byte;
  //* Array of bytes
  //Legacy support for old scripts
  TByteSet = set of Byte;

  TBooleanArray = array of Boolean;
  TBoolean2Array = array of array of Boolean;
  TKMByteArray = array of Byte;
  TKMByte2Array = array of TKMByteArray;
  TKMByteSetArray = array of TKMByteSet;
  PKMByte2Array = ^TKMByte2Array;
  TKMWordArray = array of Word;
  TKMWord2Array = array of array of Word;
  PKMWordArray = ^TKMWordArray;
  TKMCardinalArray = array of Cardinal;
  PKMCardinalArray = ^TKMCardinalArray;
  TSmallIntArray = array of SmallInt;
  //* array of integer values
  TIntegerArray = array of Integer;
  TInteger2Array = array of array of Integer;
  //* array of string values
  TAnsiStringArray = array of AnsiString;
  TSingleArray = array of Single;
  TSingle2Array = array of array of Single;
  TKMStringArray = array of string;
  TKMCharArray = array of Char;
  TRGB = record R,G,B: Byte end;
  TRGBArray = array of TRGB;
  TKMStaticByteArray = array [0..MaxInt - 1] of Byte;
  PKMStaticByteArray = ^TKMStaticByteArray;
  TKMVarRecArray = array of TVarRec;

  TEvent = procedure of object;
  TPointEvent = procedure (Sender: TObject; const X,Y: Integer) of object;
  TPointEventSimple = procedure (const X,Y: Integer) of object;
  TPointEventFunc = function (Sender: TObject; const X,Y: Integer): Boolean of object;
  TPointFEvent = procedure (const aPoint: TKMPointF) of object;
  TBooleanEvent = procedure (aValue: Boolean) of object;
  TBooleanObjEvent = procedure (Sender: TObject; aValue: Boolean) of object;
  TIntegerEvent = procedure (aValue: Integer) of object;
  TIntBoolEvent = procedure (aIntValue: Integer; aBoolValue: Boolean) of object;
  TObjectIntegerEvent = procedure (Sender: TObject; X: Integer) of object;
  TSingleEvent = procedure (aValue: Single) of object;
  TAnsiStringEvent = procedure (const aData: AnsiString) of object;
  TUnicodeStringEvent = procedure (const aData: UnicodeString) of object;
  TUnicodeStringWDefEvent = procedure (const aData: UnicodeString = '') of object;
  TUnicodeStringEventProc = procedure (const aData: UnicodeString);
  TUnicode2StringEventProc = procedure (const aData1, aData2: UnicodeString);
  TUnicodeStringObjEvent = procedure (Obj: TObject; const aData: UnicodeString) of object;
  TUnicodeStringObjEventProc = procedure (Sender: TObject; const aData: UnicodeString);
  TUnicodeStringBoolEvent = procedure (const aData: UnicodeString; aBool: Boolean) of object;
  TGameStartEvent = procedure (const aData: UnicodeString; Spectating: Boolean) of object;
  TResyncEvent = procedure (aSender: ShortInt; aTick: cardinal) of object;
  TIntegerStringEvent = procedure (aValue: Integer; const aText: UnicodeString) of object;
  TBooleanFunc = function(Obj: TObject): Boolean of object;
  TBooleanWordFunc = function (aValue: Word): Boolean of object;
  TBooleanStringFunc = function (const aValue: String): Boolean of object;
  TBooleanFuncSimple = function: Boolean of object;
  TBoolIntFuncSimple = function (aValue: Integer): Boolean of object;
  TBoolCardFuncSimple = function (aValue: Cardinal): Boolean of object;
  TCardinalEvent = procedure (aValue: Cardinal) of object;
  TObjectIntBoolEvent = procedure (Sender: TObject; aIntValue: Integer; aBoolValue: Boolean) of object;
  TCoordDistanceFn = function (X, Y: Integer): Single;

  {$IFDEF FPC}
  TProc = procedure;
  {$ENDIF}

  TKMAnimLoop = packed record
    Step: array [1 .. 30] of SmallInt;
    Count: SmallInt;
    MoveX, MoveY: Integer;
  end;

  TKMCursorDir = (cdNone = 0, cdForward = 1, cdBack = -1);

  TWonOrLost = (wolNone, wolWon, wolLost);

  //Menu load type - load / no load / load unsupported version
  TKMGameStartMode = (gsmNoStart, gsmStart, gsmStartWithWarn, gsmNoStartWithWarn);

  TKMCustomScriptParam = (cspTHTroopCosts, cspMarketGoldPrice);

  TKMCustomScriptParamData = record
    Added: Boolean;
    Data: UnicodeString;
  end;

  TKMImageType = (itJpeg, itPng, itBmp);

  TKMUserActionType = (uatNone, uatKeyDown, uatKeyUp, uatKeyPress, uatMouseDown, uatMouseUp, uatMouseMove, uatMouseWheel);
  TKMUserActionEvent = procedure (aActionType: TKMUserActionType) of object;


  TKMCustomScriptParamDataArray = array [TKMCustomScriptParam] of TKMCustomScriptParamData;

  TKMPlayerColorMode = (pcmNone, pcmDefault, pcmAllyEnemy, pcmTeams);

  TKMGameRevision = Word; // Word looks enough for now...

  TKMColor3f = record
    R,G,B: Single;
    function ToCardinal: Cardinal;
    class function Generic(aIndex: Integer): TKMColor3f; static;
    class function RandomWSeed(aSeed: Integer): TKMColor3f; static;
    constructor New(aR,aG,aB: Single);
    constructor NewB(aR,aG,aB: Byte);
    constructor NewC(aRGB: Cardinal);
    function ToString: string;
  end;

  TKMColor3b = record
    R,G,B: Byte;
    function ToCardinal: Cardinal;
    constructor New(aR,aG,aB: Byte);
  end;
//             Result := R + G shl 8 + B shl 16 + A shl 24;

  TKMColor4f = record
    R,G,B,A: Single;
    constructor New(aR,aG,aB,aA: Single); overload;
    constructor New(aR,aG,aB: Byte); overload;
    constructor NewB(aR,aG,aB,aA: Byte); overload;
    constructor New(aCol: Cardinal); overload;
    constructor New(aCol: TKMColor3f); overload;
    constructor New(aCol: TKMColor3f; aAlpha: Single); overload;
    class function White(): TKMColor4f; static;
    class function Black(): TKMColor4f; static;
    function Alpha50(): TKMColor4f;
    function Alpha(aAlpha: Single): TKMColor4f;
    function ToColor3f: TKMColor3f;
    function ToCardinal: Cardinal;
  end;

  TKMColor3bArray = array of TKMColor3b;

const
  COLOR3F_WHITE: TKMColor3f = (R: 1; G: 1; B: 1);
  COLOR3F_BLACK: TKMColor3f = (R: 0; G: 0; B: 0);

  COLOR4F_WHITE: TKMColor4f = (R: 1; G: 1; B: 1; A: 1);
  COLOR4F_BLACK: TKMColor4f = (R: 0; G: 0; B: 0; A: 1);

const
  IMAGE_TYPE_EXT: array[TKMImageType] of string = ('.jpeg', '.png', '.bmp');

const
  WonOrLostText: array [TWonOrLost] of UnicodeString = ('None', 'Won', 'Lost');

  NO_SUCCESS_INT: Integer = -1;

implementation
uses
  Math, SysUtils, KM_CommonUtils;


{ TKMColor3f }
constructor TKMColor3f.New(aR, aG, aB: Single);
begin
  R := aR;
  G := aG;
  B := aB;
end;


constructor TKMColor3f.NewB(aR, aG, aB: Byte);
begin
  R := aR / 255;
  G := aG / 255;
  B := aB / 255;
end;


constructor TKMColor3f.NewC(aRGB: Cardinal);
begin
  B := (aRGB and $FF) / 255;
  G := (aRGB shr 8 and $FF) / 255;
  R := (aRGB shr 16 and $FF) / 255;
end;


function TKMColor3f.ToCardinal: Cardinal;
begin
  Result := (Round(R * 255) + (Round(G * 255) shl 8) + (Round(B * 255) shl 16)) {or $FF000000};
end;


class function TKMColor3f.Generic(aIndex: Integer): TKMColor3f;
const
  MAX_GENERIC_COLORS = 6;
  GENERIC_COLORS: array [0..MAX_GENERIC_COLORS-1] of TKMColor3f = (
    (R:1.0; G:0.2; B:0.2),
    (R:1.0; G:1.0; B:0.2),
    (R:0.2; G:1.0; B:0.2),
    (R:0.2; G:1.0; B:1.0),
    (R:0.2; G:0.2; B:1.0),
    (R:1.0; G:0.2; B:1.0)
  );
begin
  Result := GENERIC_COLORS[aIndex mod MAX_GENERIC_COLORS];
end;


class function TKMColor3f.RandomWSeed(aSeed: Integer): TKMColor3f;
begin
  Result.R := KaMRandomWSeedS1(aSeed, 1);
  Result.G := KaMRandomWSeedS1(aSeed, 1);
  Result.B := KaMRandomWSeedS1(aSeed, 1);
end;


function TKMColor3f.ToString: string;
begin
  Result := Format('[%d:%d:%d]', [Round(255*R), Round(255*G), Round(255*B)]);
end;


{ TKMColor3b }
constructor TKMColor3b.New(aR, aG, aB: Byte);
begin
  R := aR;
  G := aG;
  B := aB;
end;


function TKMColor3b.ToCardinal: Cardinal;
begin
  Result := (R + (G shl 8) + (B shl 16)); {or $FF000000};
end;


{ TKMColor4f }
constructor TKMColor4f.New(aR,aG,aB,aA: Single);
begin
  R := aR;
  G := aG;
  B := aB;
  A := aA;
end;


constructor TKMColor4f.New(aR,aG,aB: Byte);
begin
  R := aR / 255;
  G := aG / 255;
  B := aB / 255;
  A := 1;
end;


constructor TKMColor4f.NewB(aR,aG,aB,aA: Byte);
begin
  R := aR / 255;
  G := aG / 255;
  B := aB / 255;
  A := aA / 255;
end;


constructor TKMColor4f.New(aCol: Cardinal);
begin
  R := (aCol and $FF)           / 255;
  G := ((aCol shr 8) and $FF)   / 255;
  B := ((aCol shr 16) and $FF)  / 255;
  A := ((aCol shr 24) and $FF)  / 255;
end;


constructor TKMColor4f.New(aCol: TKMColor3f);
begin
  New(aCol, 1);
end;


constructor TKMColor4f.New(aCol: TKMColor3f; aAlpha: Single);
begin
  R := aCol.R;
  G := aCol.G;
  B := aCol.B;
  A := aAlpha;
end;


class function TKMColor4f.White(): TKMColor4f;
begin
  Result.R := 1;
  Result.G := 1;
  Result.B := 1;
  Result.A := 1;
end;


class function TKMColor4f.Black: TKMColor4f;
begin
  Result.R := 0;
  Result.G := 0;
  Result.B := 0;
  Result.A := 1;
end;


function TKMColor4f.Alpha50(): TKMColor4f;
begin
  Result := Self;
  Result.A := 0.5;
end;


function TKMColor4f.Alpha(aAlpha: Single): TKMColor4f;
begin
  Result := Self;
  Result.A := aAlpha;
end;


function TKMColor4f.ToColor3f: TKMColor3f;
begin
  Result.R := R;
  Result.G := G;
  Result.B := B;
end;


function TKMColor4f.ToCardinal: Cardinal;
begin
  Result := Round(R * 255) + (Round(G * 255) shl 8) + (Round(B * 255) shl 16) + (Round(A * 255) shl 24);
end;


end.
