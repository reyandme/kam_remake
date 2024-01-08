unit KM_CommonUtils;
{$I KaM_Remake.inc}
interface
uses
  Classes, DateUtils, Math, SysUtils, KM_Defaults, KM_Points, KM_CommonTypes
  {$IFDEF MSWindows}
  ,Windows
  ,MMSystem //Required for TimeGet which is defined locally because this unit must NOT know about KromUtils as it is not Linux compatible (and this unit is used in Linux dedicated servers)
  {$ENDIF}
  {$IFDEF Unix}
  ,unix, baseunix, UnixUtil
  {$ENDIF}
  ;

  function IfThenS(aCondition: Boolean; const aIfTrue, aIfFalse: String): String;

  function GetPositionInGroup2(OriginX, OriginY: Word; aDir: TKMDirection; aIndex, aUnitPerRow: Word; MapX, MapY: Word; out aTargetCanBeReached: Boolean): TKMPoint;
  function GetPositionFromIndex(const aOrigin: TKMPoint; aIndex: Byte): TKMPoint;

  function FixDelim(const aString: UnicodeString): UnicodeString;

  function Max3(const A,B,C: Integer): Integer; overload;
  function Min3(const A,B,C: Integer): Integer; overload;
  function Max4(const A,B,C,D: Integer): Integer;
  function Min4(const A,B,C,D: Integer): Integer;

  function Max3(const A,B,C: Single): Single; overload;
  function Min3(const A,B,C: Single): Single; overload;

  function GetStackTrace(aLinesCnt: Integer): UnicodeString;

  function RGB2BGR(aRGB: Cardinal): Cardinal;
  function BGR2RGB(aRGB: Cardinal): Cardinal;

  function RGB2XYZ(aRGB: TKMColor3f): TKMColor3f;
  function RGB2CEILAB(aRGB: TKMColor3f): TKMColor3f;
  function RGB2CEILUV(aRGB: TKMColor3f): TKMColor3f;

  function ApplyColorCoef(aColor: Cardinal; aAlpha, aRed, aGreen, aBlue: Single): Cardinal;
  function GetGreyColor(aGreyLevel: Byte): Cardinal;
  procedure ConvertRGB2HSB(aR, aG, aB: Integer; out oH, oS, oB: Single);
  procedure ConvertHSB2RGB(aHue, aSat, aBri: Single; out R, G, B: Byte);
  function GetColorBrightness(aR, aG, aB: Integer): Single; overload;
  function GetColorBrightness(aRGB: Cardinal): Single; overload;
  function GetRandomColorWSeed(aSeed: Integer): Cardinal;
  function EnsureBrightness(aColor: Cardinal; aMinBrightness: Single; aMaxBrightness: Single = 1): Cardinal;
  function MultiplyBrightnessByFactor(aColor: Cardinal; aBrightnessFactor: Single; aMinBrightness: Single = 0; aMaxBrightness: Single = 1): Cardinal;
  function ReduceBrightness(aColor: Cardinal; aBrightness: Byte): Cardinal;
  function IsColorCloseToColors(aColor: Cardinal; const aColors: TKMCardinalArray; aDist: Single): Boolean;
  function GetColorDistance(aColor1, aColor2: Cardinal): Single; overload;
  function GetColorDistance(aColor1, aColor2: TKMColor3f): Single; overload;
  function GetRandomColor: Cardinal;
  function GetPingColor(aPing: Word): Cardinal;
  function GetFPSColor(aFPS: Word): Cardinal;
  function FlagColorToTextColor(aColor: Cardinal): Cardinal;
  function TimeToString(aTime: TDateTime): UnicodeString;
  function TickToTimeStr(aTick: Cardinal): String;

  function StrToHex(const S: String): String;
  function HexToStr(const H: String): String;

  function WrapColor(aValue: Integer; aColor: Cardinal): UnicodeString; overload;
  function WrapColor(const aText: UnicodeString; aColor: Cardinal): UnicodeString; overload;
  function WrapColorA(const aText: AnsiString; aColor: Cardinal): AnsiString;
  function WrapWrappedColor(const aText: UnicodeString; aColor: Cardinal): UnicodeString;
  function StripColor(const aText: UnicodeString): UnicodeString;
  function GetContrastTextColor(aBackgroundColor: Cardinal): Cardinal;
  function FindMPColor(aColor: Cardinal): Integer;

  procedure ParseDelimited(const Value, Delimiter: UnicodeString; SL: TStringList);

  function EnsureRangeF(const aValue, aMin, aMax: Single): Single;

  procedure SetKaMSeed(aSeed: Integer);
  function GetKaMSeed: Integer;
  function KaMRandomWSeed(var aSeed: Integer): Extended; overload;
  function KaMRandomWSeed(var aSeed: Integer; aMax: Integer): Integer; overload;
  function KaMRandomWSeedS1(var aSeed: Integer; aMax: Integer): Single;
  function KaMRandomWSeedI2(var aSeed: Integer; Range_Both_Directions: Integer): Integer;
  function KaMRandom(const aCaller: AnsiString; aLogRng: Boolean = True): Extended; overload;
  function KaMRandom(aMax: Integer; const aCaller: AnsiString; aLogRng: Boolean = True): Integer; overload;
  function KaMRandom(aMax: Cardinal; const aCaller: AnsiString; aLogRng: Boolean = True): Cardinal; overload;
  function KaMRandom(aMax: Int64; const aCaller: AnsiString; aLogRng: Boolean = True): Int64; overload;
  function KaMRandomS1(aMax: Single; const aCaller: AnsiString): Single;
  function KaMRandomI2(Range_Both_Directions: Integer; const aCaller: AnsiString): Integer; overload;
  function KaMRandomS2(Range_Both_Directions: Single; const aCaller: AnsiString): Single; overload;

  function IsGameStartAllowed(aGameStartMode: TKMGameStartMode): Boolean;
  function GetGameVersionNum(const aGameVersionStr: AnsiString): Integer; overload;
  function GetGameVersionNum(const aGameVersionStr: UnicodeString): Integer; overload;

  function TimeGet: Cardinal;
  function TimeGetUsec: Int64;
  function TimeSince(aTime: Cardinal): Cardinal;
  function TimeSinceUSec(aTime: Int64): Int64;
  function UTCNow: TDateTime;
  function UTCToLocal(Input: TDateTime): TDateTime;

  function MapSizeIndex(X, Y: Word): TKMMapSize;
  function MapSizeText(X,Y: Word): UnicodeString; overload;
  function MapSizeText(aMapSize: TKMMapSize): UnicodeString; overload;

  //Taken from KromUtils to reduce dependancies (required so the dedicated server compiles on Linux without using Controls)
  procedure KMSwapInt(var A,B: Byte); overload;
  procedure KMSwapInt(var A,B: Shortint); overload;
  procedure KMSwapInt(var A,B: Smallint); overload;
  procedure KMSwapInt(var A,B: Word); overload;
  procedure KMSwapInt(var A,B: Integer); overload;
  procedure KMSwapInt(var A,B: LongWord); overload;

  procedure KMSwapFloat(var A,B: Single); overload;
  procedure KMSwapFloat(var A,B: Double); overload;

  function ToBoolean(aVal: Byte): Boolean;
  function BoolStrShort(aVal: Boolean): string;

  function VarRecToStr(aVarRec: TVarRec): string;
  function VarRecArrToStr(aVarRecArr: array of TVarRec; aSep: string = ', '): string;

  //Extended == Double, so already declared error
  //https://forum.lazarus.freepascal.org/index.php?topic=29678.0
  {$IFDEF WDC}
  procedure KMSwapFloat(var A,B: Extended); overload;
  {$ENDIF}

  procedure KMSummArr(aArr1, aArr2: PKMCardinalArray);
  procedure KMSummAndEnlargeArr(aArr1, aArr2: PKMCardinalArray);

  function RoundP(Value, Precision: Double): Double;

  function ArrayContains(aValue: Integer; const aArray: array of Integer): Boolean; overload;
  function ArrayContains(aValue: Word; const aArray: array of Word): Boolean; overload;
  function ArrayContains(aPoint: TKMPoint; const aArray: TKMPointArray): Boolean; overload;
  function ArrayContains(aPoint: TKMPoint; const aArray: TKMPointArray; aElemCnt: Integer): Boolean; overload;

  procedure ArrayReverse(var aArray: TKMPointArray);

  function Pack4ByteToInteger(aByte1, aByte2, aByte3, aByte4: Byte): Integer;
  procedure UnpackIntegerTo4Byte(aInt: Integer; out aByte1, aByte2, aByte3, aByte4: Byte);

  function GetFileDirName(const aFilePath: UnicodeString): UnicodeString;

  function GetNoColorMarkupText(const aText: UnicodeString): UnicodeString;

  procedure GetAllPathsInDir(const aDir: String; aSL: TStringList; aIncludeSubdirs: Boolean = True); overload;
  procedure GetAllPathsInDir(const aDir: String; aSL: TStringList; const aExt: String; aIncludeSubdirs: Boolean = True); overload;
  procedure GetAllPathsInDir(const aDir: String; aSL: TStringList; aValidateFn: TBooleanStringFunc; aIncludeSubdirs: Boolean = True); overload;

  function DeleteDoubleSpaces(const aString: string): string;

  function CountOccurrences(const aSubstring, aText: String): Integer;
  function IntToBool(aValue: Integer): Boolean;
  function HumanRound(X: Extended): Integer;

  //String functions
  function GetNextWordPos(const aStr: String; aPos: Integer): Integer;
  function GetPrevWordPos(const aStr: String; aPos: Integer): Integer;

  function StrIndexOf(const aStr, aSubStr: String): Integer;
  function StrLastIndexOf(const aStr, aSubStr: String): Integer;
  function StrSubstring(const aStr: String; aFrom, aLength: Integer): String; overload;
  function StrSubstring(const aStr: String; aFrom: Integer): String; overload;
  function StrContains(const aStr, aSubStr: String): Boolean;
  function StrTrimRight(const aStr: String; aCharsToTrim: TKMCharArray): String;
  function StrTrimChar(const aStr: String; aChar: Char): String;
  procedure StringSplit(const aStr: string; aDelimiter: Char; aListOfStrings: TStrings);
  {$IFDEF WDC}
  procedure StrSplit(const aStr, aDelimiters: String; var aStrings: TStringList);
  {$ENDIF}
  function StrSplitA(const aStr, aDelimiters: String): TAnsiStringArray;

  procedure DeleteFromArray(var Arr: TAnsiStringArray; const Index: Integer); overload;
  procedure DeleteFromArray(var Arr: TIntegerArray; const Index: Integer); overload;

  {$IFDEF FPC}
  {$IFDEF Unix}
  function AtomicExchange (var Target: longint;Source : longint) : longint; external name 'FPC_INTERLOCKEDEXCHANGE';
  {$ENDIF}
  {$ENDIF}

const
  DEFAULT_ATTEMPS_CNT_TO_TRY = 3;

  function TryExecuteMethod(const aStrParam, aMethodName: UnicodeString; var aErrorStr: UnicodeString;
                            aMethod: TUnicodeStringEvent; aAttemps: Byte = DEFAULT_ATTEMPS_CNT_TO_TRY): Boolean; overload;

  function TryExecuteMethod(aObjParam: TObject; const aStrParam, aMethodName: UnicodeString; var aErrorStr: UnicodeString;
                            aMethod: TUnicodeStringObjEvent; aAttemps: Byte = DEFAULT_ATTEMPS_CNT_TO_TRY): Boolean; overload;

  function TryExecuteMethodProc(const aStrParam, aMethodName: UnicodeString; var aErrorStr: UnicodeString;
                                aMethodProc: TUnicodeStringEventProc; aAttemps: Byte = DEFAULT_ATTEMPS_CNT_TO_TRY): Boolean; overload;

  function TryExecuteMethodProc(const aStrParam1, aStrParam2, aMethodName: UnicodeString; var aErrorStr: UnicodeString;
                                aMethodProc: TUnicode2StringEventProc; aAttemps: Byte = DEFAULT_ATTEMPS_CNT_TO_TRY): Boolean; overload;


var
  gFormatSettingsDotSeparator: TFormatSettings; // Format settings with `.` as a decimal separator to be used when parse float values


implementation
uses
  StrUtils, Types,
  {$IFDEF USE_MAD_EXCEPT} madStackTrace, {$ENDIF}
  {$IFDEF WDC} KM_RandomChecks, {$ENDIF}
  KM_Log;

const
  //Pretend these are understandable in any language
  MAP_SIZES: array [TKMMapSize] of String = ('???', 'XS', 'S', 'M', 'L', 'XL', 'XXL');

var
  fKaMSeed: Integer;


function IfThenS(aCondition: Boolean; const aIfTrue, aIfFalse: String): String;
begin
  if aCondition then
    Result := aIfTrue
  else
    Result := aIfFalse;
end;


procedure KMSwapInt(var A,B: Byte);
var
  S: byte;
begin
  S := A; A := B; B := S;
end;

procedure KMSwapInt(var A,B: Shortint);
var
  S: Shortint;
begin
  S := A; A := B; B := S;
end;

procedure KMSwapInt(var A,B: Smallint);
var S: Smallint;
begin
  S:=A; A:=B; B:=S;
end;

procedure KMSwapInt(var A,B: Word);
var S: Word;
begin
  S:=A; A:=B; B:=S;
end;

procedure KMSwapInt(var A,B: Integer);
var S: Integer;
begin
  S:=A; A:=B; B:=S;
end;

procedure KMSwapInt(var A,B: LongWord);
var S: cardinal;
begin
  S:=A; A:=B; B:=S;
end;


procedure KMSwapFloat(var A,B: Single);
var S: Single;
begin
  S:=A; A:=B; B:=S;
end;

procedure KMSwapFloat(var A,B: Double);
var S: Double;
begin
  S:=A; A:=B; B:=S;
end;


function ToBoolean(aVal: Byte): Boolean;
begin
  if aVal = 0 then
    Result := False
  else
    Result := True;
end;


function BoolStrShort(aVal: Boolean): string;
begin
  if aVal then
    Result := '1'
  else
    Result := '0';
end;


function VarRecToStr(aVarRec: TVarRec): string;
begin
  with aVarRec do
    case VType of
      vtInteger:        Result := IntToStr(VInteger);
      vtBoolean:        Result := BoolToStr(VBoolean);
      vtChar:           Result := string(VChar);
      vtExtended:       Result := FloatToStr(VExtended^);
      vtString:         Result := string(VString^);
      vtPChar:          Result := string(VPChar);
      vtObject:         Result := VObject.ClassName;
      vtClass:          Result := VClass.ClassName;
      vtPWideChar:      Result := string(VPWideChar);
      vtAnsiString:     Result := string(AnsiString(VAnsiString));
      vtCurrency:       Result := CurrToStr(VCurrency^);
      vtVariant:        Result := string(VVariant^);
      vtInt64:          Result := IntToStr(VInt64^);
      vtUnicodeString:  Result := string(VUnicodeString);
      else              Result := '';
  end;
end;


function VarRecArrToStr(aVarRecArr: array of TVarRec; aSep: string = ', '): string;
var
  I: Integer;
begin
  Result := '';

  for I := Low(aVarRecArr) to High(aVarRecArr) do
    Result := Result + VarRecToStr(aVarRecArr[I]) + IfThen(I <> High(aVarRecArr), aSep);
end;


{$IFDEF WDC}
procedure KMSwapFloat(var A,B: Extended);
var S: Extended;
begin
  S:=A; A:=B; B:=S;
end;
{$ENDIF}


procedure KMSummArr(aArr1, aArr2: PKMCardinalArray);
var
  I: Integer;
begin
  Assert(Length(aArr1^) = Length(aArr2^), 'Arrays should have same length');
  for I := Low(aArr1^) to High(aArr1^) do
    Inc(aArr1^[I], aArr2^[I]);
end;


procedure KMSummAndEnlargeArr(aArr1, aArr2: PKMCardinalArray);
var
  I, OldLen1: Integer;
begin
  OldLen1 := Length(aArr1^);
  if OldLen1 < Length(aArr2^) then
  begin
    SetLength(aArr1^, Length(aArr2^));
    for I := OldLen1 to Length(aArr2^) - 1 do
      aArr1^[I] := 0;                     //Init array with 0
  end;

  for I := Low(aArr2^) to High(aArr2^) do
    Inc(aArr1^[I], aArr2^[I]);
end;


function RoundP(Value, Precision: Double): Double;
begin
  Result := Round(Value/Precision)*Precision;
end;


function ArrayContains(aValue: Integer; const aArray: array of Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := Low(aArray) to High(aArray) do
    if aValue = aArray[I] then
      Exit(True);
end;


function ArrayContains(aValue: Word; const aArray: array of Word): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := Low(aArray) to High(aArray) do
    if aValue = aArray[I] then
      Exit(True);
end;


function ArrayContains(aPoint: TKMPoint; const aArray: TKMPointArray): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := Low(aArray) to High(aArray) do
    if KMSamePoint(aPoint, aArray[I]) then
      Exit(True);
end;


function ArrayContains(aPoint: TKMPoint; const aArray: TKMPointArray; aElemCnt: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to aElemCnt - 1 do
    if KMSamePoint(aPoint, aArray[I]) then
      Exit(True);
end;


procedure ArrayReverse(var aArray: TKMPointArray);
var
  I: Integer;
  tmp: TKMPoint;
  IMax: Integer;
begin
  IMax := High(aArray);
  for I := 0 to IMax div 2 do
  begin
    tmp := aArray[I];
    aArray[I] := aArray[IMax - I];
    aArray[IMax - I] := tmp;
  end;
end;


function Pack4ByteToInteger(aByte1, aByte2, aByte3, aByte4: Byte): Integer;
begin
  Result := (aByte1 shl 24) or (aByte2 shl 16) or (aByte3 shl 8) or aByte4;
end;


procedure UnpackIntegerTo4Byte(aInt: Integer; out aByte1, aByte2, aByte3, aByte4: Byte);
begin
  aByte1 := (aInt and $FF000000) shr 24;
  aByte2 := (aInt and $FF0000) shr 16;
  aByte3 := (aInt and $FF00) shr 8;
  aByte4 := aInt and $FF;
end;


function IsGameStartAllowed(aGameStartMode: TKMGameStartMode): Boolean;
begin
  Result := not (aGameStartMode in [gsmNoStart, gsmNoStartWithWarn]);
end;


function GetGameVersionNum(const aGameVersionStr: AnsiString): Integer;
begin
  Result := GetGameVersionNum(UnicodeString(aGameVersionStr));
end;


function GetGameVersionNum(const aGameVersionStr: UnicodeString): Integer;
var
  Rev: Integer;
begin
  Result := 0;
  if Copy(aGameVersionStr, 1, 1) <> 'r' then
    Exit;

  if TryStrToInt(Copy(aGameVersionStr, 2, Length(aGameVersionStr) - 1), Rev) then
    Result := Rev;
end;


//This unit must not know about KromUtils because it is used by the Linux Dedicated servers
//and KromUtils is not Linux compatible. Therefore this function is copied directly from KromUtils.
//Do not remove and add KromUtils to uses, that would cause the Linux build to fail
function TimeGet: Cardinal;
begin
  {$IFDEF MSWindows}
  Result := TimeGetTime; //Return milliseconds with ~1ms precision
  {$ENDIF}
  {$IFDEF Unix}
  Result := Cardinal(Trunc(Now * 24 * 60 * 60 * 1000) mod high(Cardinal));
  {$ENDIF}
end;

// Returns time in micro-seconds (usec)
function TimeGetUsec: Int64;
var
  freq: Int64;
  newTime: Int64;
  factor: Double;
begin
  {$IFDEF FPC}
  //Stub for now
  Result := Int64(Trunc(Now * 24 * 60 * 60 * 1000000) mod High(Int64));
  {$ENDIF}
  {$IFDEF WDC}
  QueryPerformanceFrequency(freq);
  QueryPerformanceCounter(newTime);
  factor := 1000000 / freq; // Separate calculation to avoid "big Int64 * 1 000 000" overflow
  Result := Round(newTime * factor);
  {$ENDIF}
end;


function TimeSince(aTime: Cardinal): Cardinal;
begin
  //TimeGet will loop back to zero after ~49 days since system start
  Result := (Int64(TimeGet) - Int64(aTime) + Int64(High(Cardinal))) mod Int64(High(Cardinal));
end;


function TimeSinceUSec(aTime: Int64): Int64;
begin
  Result := TimeGetUsec - aTime;
end;


function UTCNow: TDateTime;
{$IFDEF MSWindows}
var st: TSystemTime;
begin
  GetSystemTime(st);
  Result := SystemTimeToDateTime(st);
end;
{$ENDIF}
{$IFDEF Unix}
var
  TimeVal: TTimeVal;
  TimeZone: PTimeZone;
  a: Double;
begin
  TimeZone := nil;
  fpGetTimeOfDay(@TimeVal, TimeZone);
  // Convert to milliseconds
  a := (TimeVal.tv_sec * 1000.0) + (TimeVal.tv_usec / 1000.0);
  Result := (a / MSecsPerDay) + UnixDateDelta;
end;
{$ENDIF}


function UTCToLocal(Input: TDateTime): TDateTime;
{$IFDEF WDC}
begin
  Result := TTimeZone.Local.ToLocalTime(Input);
end;
{$ENDIF}
//There seems to be no easy way to do this in FPC without an external library
//From: http://lists.lazarus.freepascal.org/pipermail/lazarus/2010-September/055568.html
{$IFDEF FPC}
var
  TZOffset: Integer;
  {$IFDEF MSWINDOWS}
  BiasType: Byte;
  TZInfo: TTimeZoneInformation;
  {$ENDIF}
begin
  Result := Input;
  {$IFDEF MSWINDOWS}
  BiasType := GetTimeZoneInformation(TZInfo);
  if (BiasType=0) then
    Exit; //No timezone so return the input

  // Determine offset in effect for DateTime UT.
  if (BiasType=2) then
    TZOffset := TZInfo.Bias + TZInfo.DaylightBias
  else
    TZOffset := TZInfo.Bias + TZInfo.StandardBias;
  {$ENDIF}
  {$IFDEF UNIX}
    TZOffset := -Tzseconds div 60;
  {$ENDIF}

  // Apply offset.
  if (TZOffset > 0) then
    // Time zones west of Greenwich.
    Result := Input - EncodeTime(TZOffset div 60, TZOffset mod 60, 0, 0)
  else if (TZOffset = 0) then
    // Time Zone = Greenwich.
    Result := Input
  else if (TZOffset < 0) then
    // Time zones east of Greenwich.
    Result := Input + EncodeTime(Abs(TZOffset) div 60, Abs(TZOffset) mod 60, 0, 0);
end;
{$ENDIF}


function MapSizeIndex(X, Y: Word): TKMMapSize;
begin
  case X * Y of
            1.. 48* 48: Result := msXS;
     48* 48+1.. 80* 80: Result := msS;
     80* 80+1..128*128: Result := msM;
    128*128+1..176*176: Result := msL;
    176*176+1..224*224: Result := msXL;
    224*224+1..320*320: Result := msXXL;
    else                Result := msNone;
  end;
end;


function MapSizeText(X, Y: Word): UnicodeString;
begin
  Result := MAP_SIZES[MapSizeIndex(X, Y)];
end;


function MapSizeText(aMapSize: TKMMapSize): UnicodeString;
begin
  Result := MAP_SIZES[aMapSize];
end;


{Returns point where unit should be placed regarding direction & offset from Commanders position}
// 23145     231456
// 6789X     789xxx
function GetPositionInGroup2(OriginX, OriginY: Word; aDir: TKMDirection; aIndex, aUnitPerRow: Word; MapX, MapY: Word; out aTargetCanBeReached: Boolean): TKMPoint;
const
  DirAngle: array [TKMDirection] of Word   = (0, 0, 45, 90, 135, 180, 225, 270, 315);
  DirRatio: array [TKMDirection] of Single = (0, 1, 1.41, 1, 1.41, 1, 1.41, 1, 1.41);
var
  PlaceX, PlaceY, ResultX, ResultY: integer;
begin
  Assert(aUnitPerRow > 0);
  if aIndex = 0 then
  begin
    ResultX := OriginX;
    ResultY := OriginY;
  end
  else
  begin
    if aIndex <= aUnitPerRow div 2 then
      Dec(aIndex);
    PlaceX := aIndex mod aUnitPerRow - aUnitPerRow div 2;
    PlaceY := aIndex div aUnitPerRow;

    ResultX := OriginX + Round( PlaceX*DirRatio[aDir]*cos(DirAngle[aDir]/180*pi) - PlaceY*DirRatio[aDir]*sin(DirAngle[aDir]/180*pi) );
    ResultY := OriginY + Round( PlaceX*DirRatio[aDir]*sin(DirAngle[aDir]/180*pi) + PlaceY*DirRatio[aDir]*cos(DirAngle[aDir]/180*pi) );
  end;

  aTargetCanBeReached := InRange(ResultX, 1, MapX-1) and InRange(ResultY, 1, MapY-1);
  //Fit to bounds
  Result.X := EnsureRange(ResultX, 1, MapX-1);
  Result.Y := EnsureRange(ResultY, 1, MapY-1);
end;


//See Docs\GetPositionFromIndex.xls for explanation
function GetPositionFromIndex(const aOrigin: TKMPoint; aIndex: Byte): TKMPoint;
const
  Rings: array[1..10] of Word =
//Ring#  1  2  3  4   5   6   7    8    9    10
        (0, 1, 9, 25, 49, 81, 121, 169, 225, 289);
var
  Ring, Span, Span2, Orig: Byte;
  Off1,Off2,Off3,Off4,Off5: Byte;
begin
  //Quick solution
  if aIndex = 0 then
  begin
    Result.X := aOrigin.X;
    Result.Y := aOrigin.Y;
    Exit;
  end;

  //Find ring in which Index is located
  Ring := 0;
  repeat inc(Ring); until(Rings[Ring]>aIndex);
  dec(Ring);

  //Remember Ring span and half-span
  Span := Ring*2-1-1; //Span-1
  Span2 := Ring-1;    //Half a span -1

  //Find offset from Rings 1st item
  Orig := aIndex - Rings[Ring];

  //Find Offset values in each span
  Off1 := min(Orig,Span2); dec(Orig,Off1);
  Off2 := min(Orig,Span);  dec(Orig,Off2);
  Off3 := min(Orig,Span);  dec(Orig,Off3);
  Off4 := min(Orig,Span);  dec(Orig,Off4);
  Off5 := min(Orig,Span2-1); //dec(Orig,Off5);

  //Compute result
  Result.X := aOrigin.X + Off1 - Off3 + Off5;
  Result.Y := aOrigin.Y - Span2 + Off2 - Off4;
end;


//Use this function to convert platform-specific path delimiters
function FixDelim(const aString: UnicodeString): UnicodeString;
begin
  Result := StringReplace(aString, '\', PathDelim, [rfReplaceAll, rfIgnoreCase]);
end;

function Max3(const A,B,C: Integer): Integer;
begin
  Result := Max(A, Max(B, C));
end;

function Min3(const A,B,C: Integer): Integer;
begin
  Result := Min(A, Min(B, C));
end;

function Max4(const A,B,C,D: Integer): Integer;
begin
  Result := Max(Max(A, B), Max(C, D));
end;

function Min4(const A,B,C,D: Integer): Integer;
begin
  Result := Min(Min(A, B), Min(C, D));
end;


function Max3(const A,B,C: Single): Single;
begin
  Result := Math.Max(A, Math.Max(B, C));
end;

function Min3(const A,B,C: Single): Single;
begin
  Result := Math.Min(A, Math.Min(B, C));
end;


type
  EStackTraceInfo = class(Exception);


function GetStackTrace(aLinesCnt: Integer): UnicodeString;
{$IFDEF WDC}
{$IFDEF USE_MAD_EXCEPT}
var
  I: Integer;
  SList: TStringList;
{$ENDIF}
{$ENDIF}
begin
  Result := '';

  {$IFDEF WDC}
  {$IFDEF USE_MAD_EXCEPT}
  try
    SList := TStringList.Create;
    try
      SList.Text := madStackTrace.StackTrace();

      for I := 1 to Min(SList.Count - 1, aLinesCnt) do //Do not print last line (its this method line)
        Result := Result + SList[I] + sLineBreak;
    finally
      SList.Free;
    end
  except
    // Noticed a crash on game exit once somewhere here, just ignore the exception in this case
    on E: Exception do ;
  end;

  // todo: delete unused code later
//  try
//    raise EStackTraceInfo.Create('');
//  except
//    on E: EStackTraceInfo do
//    begin
//      try
//        SList := TStringList.Create;
//        try
//          SList.Text := E.StackTrace;
//
//          for I := 1 to Min(SList.Count - 1, aLinesCnt) do //Do not print last line (its this method line)
//            Result := Result + SList[I] + sLineBreak;
//        finally
//          SList.Free;
//        end
//      except
//        // Noticed a crash on game exit once somewhere here, just ignore the exception in this case
//        on E: Exception do ;
//      end;
//    end;
//  end;
  {$ENDIF}
  {$ENDIF}
end;


function GetPingColor(aPing: Word): Cardinal;
begin
  case aPing of
    0..299  : Result := clPingLow;
    300..599: Result := clPingNormal;
    600..999: Result := clPingHigh;
    else      Result := clPingCritical;
  end;
end;


function GetFPSColor(aFPS: Word): Cardinal;
begin
  case aFPS of
    0..9  : Result := clFpsCritical;
    10..12: Result := clFpsLow;
    13..15: Result := clFpsNormal;
    else    Result := clFpsHigh;
  end;
end;


function RGB2BGR(aRGB: Cardinal): Cardinal;
var
  A, R, G, B: Byte;
begin
  //We split color to RGB values
  R := aRGB and $FF;
  G := aRGB shr 8 and $FF;
  B := aRGB shr 16 and $FF;
  A := aRGB shr 24 and $FF;

  Result := B + G shl 8 + R shl 16 + A shl 24;
end;


function BGR2RGB(aRGB: Cardinal): Cardinal;
var
  A, R, G, B: Byte;
begin
  //We split color to RGB values
  B := aRGB and $FF;
  G := aRGB shr 8 and $FF;
  R := aRGB shr 16 and $FF;
  A := aRGB shr 24 and $FF;

  Result := R + G shl 8 + B shl 16 + A shl 24;
end;


// According to
// http://www.brucelindbloom.com/index.html?Eqn_RGB_to_XYZ.html
function RGB2XYZ(aRGB: TKMColor3f): TKMColor3f;
const
  X_VECTOR: array[0..2] of Single = (0.4124564, 0.3575761, 0.1804375);
  Y_VECTOR: array[0..2] of Single = (0.2126729, 0.7151522, 0.0721570);
  Z_VECTOR: array[0..2] of Single = (0.0193339, 0.1191920, 0.9503041);

  function RBG2(aVal: Single): Single;
  begin
    if aVal < 0.04045 then
      Result := aVal / 12.92
    else
      Result := Math.Power((aVal + 0.055)/1.055, 2.4);
  end;
var
  R2, G2, B2: Single;
begin
  R2 := RBG2(aRGB.R);
  G2 := RBG2(aRGB.G);
  B2 := RBG2(aRGB.B);

  Result.R := X_VECTOR[0]*R2 + X_VECTOR[1]*G2 + X_VECTOR[2]*B2;
  Result.G := Y_VECTOR[0]*R2 + Y_VECTOR[1]*G2 + Y_VECTOR[2]*B2;
  Result.B := Z_VECTOR[0]*R2 + Z_VECTOR[1]*G2 + Z_VECTOR[2]*B2;
end;


// According to
// https://docs.opencv.org/4.5.2/de/d25/imgproc_color_conversions.html#color_convert_rgb_lab
// Tested on online calculators, 100% accurate
function RGB2CEILAB(aRGB: TKMColor3f): TKMColor3f;

  function Fn(aValue: Single): Single;
  begin
    if aValue > 0.008856 then
      Result := Math.Power(aValue, 0.3333)
    else
      Result := 7.787 * aValue + 16 / 116;
  end;

const
  X_N: Single = 0.950456;
  Z_N: Single = 1.088754;
var
  X, Y, Z, L, a, b: Single;
  XYZ: TKMColor3f;
begin
  XYZ := RGB2XYZ(aRGB);
  X := XYZ.R;
  Y := XYZ.G;
  Z := XYZ.B;

  X := X / X_N;
  Z := Z / Z_N;

  if Y > 0.008856 then
    L := 116 * Math.Power(Y, 0.3333) - 16
  else
    L := 903.3 * Y;

  a := 500*(Fn(X) - Fn(Y));

  b := 200*(Fn(Y) - Fn(Z));

  Result.R := L / 100;
  Result.G := (a + 128) / 256;
  Result.B := (b + 128) / 256;
end;


// According to
// https://docs.opencv.org/4.5.2/de/d25/imgproc_color_conversions.html#color_convert_rgb_luv
// Has to be tested, use with caution
function RGB2CEILUV(aRGB: TKMColor3f): TKMColor3f;
const
  U_N: Single = 0.19793943;
  V_N: Single = 0.46831096;

var
  XYZ: TKMColor3f;
  X, Y, Z: Single;
  L, u, v, u_, v_, tmp: Single;
begin
  XYZ := RGB2XYZ(aRGB);
  X := XYZ.R;
  Y := XYZ.G;
  Z := XYZ.B;

  //0 <= L <= 100
  if Y > 0.008856 then
    L := 116*Math.Power(Y, 0.33333) - 16
  else
    L := 903.3*Y;

  tmp := (X + 15*Y + 3*Z);
  u_ := 4*X / tmp;
  v_ := 9*Y / tmp;

  // -134 <= u <= 220
  u := 13*L*(u_ - U_N);
  // -140 <= u <= 122
  v := 13*L*(v_ - V_N);

  // L
  Result.R := L / 100;
  // u
  Result.G := (u + 134) / 354;
  // v
  Result.B := (v + 140) / 262;
end;


//Multiply color by channels
function ApplyColorCoef(aColor: Cardinal; aAlpha, aRed, aGreen, aBlue: Single): Cardinal;
var
  A, R, G, B, A2, R2, G2, B2: Byte;
begin
  //We split color to RGB values
  R := aColor and $FF;
  G := aColor shr 8 and $FF;
  B := aColor shr 16 and $FF;
  A := aColor shr 24 and $FF;

  R2 := Min(Round(aRed * R), 255);
  G2 := Min(Round(aGreen * G), 255);
  B2 := Min(Round(aBlue * B), 255);
  A2 := Min(Round(aAlpha * A), 255);

  Result := R2 + G2 shl 8 + B2 shl 16 + A2 shl 24;
end;


function GetGreyColor(aGreyLevel: Byte): Cardinal;
begin
  Result := aGreyLevel
            or (aGreyLevel shl 8)
            or (aGreyLevel shl 16)
            or $FF000000;
end;


procedure ConvertRGB2HSB(aR, aG, aB: Integer; out oH, oS, oB: Single);
var
  R, G, B: Single;
  Rdlt, Gdlt, Bdlt, Vmin, Vmax, Vdlt: Single;
begin
  R := aR / 255;
  G := aG / 255;
  B := aB / 255;

  Vmin := Math.min(R, Math.min(G, B));
  Vmax := Math.max(R, Math.max(G, B));
  Vdlt := Vmax - Vmin;
  oB := (Vmax + Vmin) / 2;
  if Vdlt = 0 then
  begin
    oH := 0.5;
    oS := 0;
  end
  else
  begin // Middle of HSImage
    if oB < 0.5 then
      oS := Vdlt / (Vmax + Vmin)
    else
      oS := Vdlt / (2 - Vmax - Vmin);

    Rdlt := (R - Vmin) / Vdlt;
    Gdlt := (G - Vmin) / Vdlt;
    Bdlt := (B - Vmin) / Vdlt;

    if R = Vmax then oH := (Gdlt - Bdlt) / 6 else
    if G = Vmax then oH := 1/3 - (Rdlt - Bdlt) / 6 else
    if B = Vmax then oH := 2/3 - (Gdlt - Rdlt) / 6 else
                      oH := 0;

    if oH < 0 then oH := oH + 1;
    if oH > 1 then oH := oH - 1;
  end;
end;


procedure ConvertHSB2RGB(aHue, aSat, aBri: Single; out R, G, B: Byte);
const V = 6;
var Hue, Sat, Bri, Rt, Gt, Bt: Single;
begin
  Hue := EnsureRange(aHue, 0, 1);
  Sat := EnsureRange(aSat, 0, 1);
  Bri := EnsureRange(aBri, 0, 1);

  //Hue
  if Hue < 1/6 then
  begin
    Rt := 1;
    Gt := Hue * V;
    Bt := 0;
  end else
  if Hue < 2/6 then
  begin
    Rt := (2/6 - Hue) * V;
    Gt := 1;
    Bt := 0;
  end else
  if Hue < 3/6 then
  begin
    Rt := 0;
    Gt := 1;
    Bt := (Hue - 2/6) * V;
  end else
  if Hue < 4/6 then
  begin
    Rt := 0;
    Gt := (4/6 - Hue) * V;
    Bt := 1;
  end else
  if Hue < 5/6 then
  begin
    Rt := (Hue - 4/6) * V;
    Gt := 0;
    Bt := 1;
  end else
  //if Hue < 6/6 then
  begin
    Rt := 1;
    Gt := 0;
    Bt := (6/6 - Hue) * V;
  end;

  //Saturation
  Rt := Rt + (0.5 - Rt) * (1 - Sat);
  Gt := Gt + (0.5 - Gt) * (1 - Sat);
  Bt := Bt + (0.5 - Bt) * (1 - Sat);

  //Brightness
  if Bri > 0.5 then
  begin
    //Mix with white
    Rt := Rt + (1 - Rt) * (Bri - 0.5) * 2;
    Gt := Gt + (1 - Gt) * (Bri - 0.5) * 2;
    Bt := Bt + (1 - Bt) * (Bri - 0.5) * 2;
  end
  else if Bri < 0.5 then
  begin
    //Mix with black
    Rt := Rt * (Bri * 2);
    Gt := Gt * (Bri * 2);
    Bt := Bt * (Bri * 2);
  end;
  //if Bri = 127 then color remains the same

  R := Round(Rt * 255);
  G := Round(Gt * 255);
  B := Round(Bt * 255);
end;


function GetColorBrightness(aR, aG, aB: Integer): Single;
var
  R, G, B: Single;
  Vmin, Vmax: Single;
begin
  R := aR / 255;
  G := aG / 255;
  B := aB / 255;
  Vmin := Math.min(R, Math.min(G, B));
  Vmax := Math.max(R, Math.max(G, B));
  Result := (Vmax + Vmin) / 2;
end;


function GetColorBrightness(aRGB: Cardinal): Single;
var
  R, G, B: Byte;
begin
  B := aRGB and $FF;
  G := aRGB shr 8 and $FF;
  R := aRGB shr 16 and $FF;
  Result := GetColorBrightness(R, G, B);
end;


//Reduce brightness
//aBrightness - from 0 to 255, where 255 is current Brightness
function ReduceBrightness(aColor: Cardinal; aBrightness: Byte): Cardinal;
begin
  Result := Round((aColor and $FF) / 255 * aBrightness)
            or
            Round((aColor shr 8 and $FF) / 255 * aBrightness) shl 8
            or
            Round((aColor shr 16 and $FF) / 255 * aBrightness) shl 16
            or
            (aColor and $FF000000);
end;


function IsColorCloseToColors(aColor: Cardinal; const aColors: TKMCardinalArray; aDist: Single): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := Low(aColors) to High(aColors) do
    if GetColorDistance(aColor, aColors[I]) < aDist then
      Exit(True);
end;


function GetRandomColor: Cardinal;
var
  R,G,B: Byte;
begin
  R := Random(255);
  G := Random(255);
  B := Random(255);

  Result := (R + G shl 8 + B shl 16) or $FF000000;
end;


function GetColorDistance(aColor1, aColor2: Cardinal): Single;
var
  R1,G1,B1,A1,R2,G2,B2,A2: Single;
begin
  R1 := (aColor1 and $FF) / 255;
  G1 := (aColor1 shr 8 and $FF) / 255;
  B1 := (aColor1 shr 16 and $FF) / 255;
  A1 := (aColor1 shr 24 and $FF) / 255;

  R2 := (aColor2 and $FF) / 255;
  G2 := (aColor2 shr 8 and $FF) / 255;
  B2 := (aColor2 shr 16 and $FF) / 255;
  A2 := (aColor2 shr 24 and $FF) / 255;

  Result := Sqrt(Sqr(R1 - R2) + Sqr(G1 - G2) + Sqr(B1 - B2) + Sqr(A1 - A2));
end;


function GetColorDistance(aColor1, aColor2: TKMColor3f): Single;
begin
  Result := Sqrt(Sqr(aColor1.R - aColor2.R) + Sqr(aColor1.G - aColor2.G) + Sqr(aColor1.B - aColor2.B));
end;


function GetRandomColorWSeed(aSeed: Integer): Cardinal;
var
  R,G,B: Byte;
begin
  R := KaMRandomWSeed(aSeed, 255);
  G := KaMRandomWSeed(aSeed, 255);
  B := KaMRandomWSeed(aSeed, 255);
  Result := (R + G shl 8 + B shl 16) or $FF000000;
end;


function EnsureBrightness(aColor: Cardinal; aMinBrightness: Single; aMaxBrightness: Single = 1): Cardinal;
begin
  Result := MultiplyBrightnessByFactor(aColor, 1, aMinBrightness, aMaxBrightness);
end;


function MultiplyBrightnessByFactor(aColor: Cardinal; aBrightnessFactor: Single; aMinBrightness: Single = 0; aMaxBrightness: Single = 1): Cardinal;
var
  R, G, B: Byte;
  Hue, Sat, Bri: Single;
begin
  ConvertRGB2HSB(aColor and $FF, aColor shr 8 and $FF, aColor shr 16 and $FF, Hue, Sat, Bri);
  Bri := EnsureRange(Bri*aBrightnessFactor, aMinBrightness, aMaxBrightness);
  ConvertHSB2RGB(Hue, Sat, Bri, R, G, B);

  //Preserve transparency value
  Result := (R + G shl 8 + B shl 16) or (aColor and $FF000000);
end;


//Desaturate and lighten the color best done in HSB colorspace
function FlagColorToTextColor(aColor: Cardinal): Cardinal;
var
  R, G, B: Byte;
  Hue, Sat, Bri: Single;
begin
  ConvertRGB2HSB(aColor and $FF, aColor shr 8 and $FF, aColor shr 16 and $FF, Hue, Sat, Bri);

  //Desaturate and lighten
  Sat := Math.Min(Sat, 0.93);
  Bri := Math.Max(Bri + 0.1, 0.2);
  ConvertHSB2RGB(Hue, Sat, Bri, R, G, B);

  //Preserve transparency value
  Result := (R + G shl 8 + B shl 16) or (aColor and $FF000000);
end;


//Convert DateTime to string xx:xx:xx where hours have at least 2 digits
//F.e. we can have 72:12:34 for 3 days long game
function TimeToString(aTime: TDateTime): UnicodeString;
begin
  //We can't use simple Trunc(aTime * 24 * 60 * 60) maths because it is prone to rounding errors
  //e.g. 3599 equals to 59:58 and 3600 equals to 59:59
  //That is why we resort to DateUtils routines which are slower but much more correct
  Result :=  Format('%.2d', [HoursBetween(aTime, 0)]) + FormatDateTime(':nn:ss', aTime);
end;


function TickToTimeStr(aTick: Cardinal): String;
begin
  Result := TimeToString(aTick / 24 / 60 / 60 / 10);
end;


function StrToHex(const S: String): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(S) do
    Result := Result + IntToHex(Ord(S[I]), 2);
end;


function HexToStr(const H: String): String;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(H) div 2 do
    Result := Result + Char(StrToInt('$' + Copy(H, (I-1)*2+1, 2)));
end;


function WrapColor(aValue: Integer; aColor: Cardinal): UnicodeString;
begin
  Result := WrapColor(IntToStr(aValue), aColor);
end;


//Make a string wrapped into color code
function WrapColor(const aText: UnicodeString; aColor: Cardinal): UnicodeString;
begin
  Result := '[$' + IntToHex(aColor and $00FFFFFF, 6) + ']' + aText + '[]';
end;


// Do not close color tag, its useful for wrapping inside other wrapped colored text
function WrapWrappedColor(const aText: UnicodeString; aColor: Cardinal): UnicodeString;
begin
  Result := '[$' + IntToHex(aColor and $00FFFFFF, 6) + ']' + aText;
end;



function WrapColorA(const aText: AnsiString; aColor: Cardinal): AnsiString;
begin
  Result := '[$' + AnsiString(IntToHex(aColor and $00FFFFFF, 6) + ']') + aText + '[]';
end;


function StripColor(const aText: UnicodeString): UnicodeString;
var
  I: Integer;
  skippingMarkup: Boolean;
begin
  Result := '';
  skippingMarkup := False;

  for I := 1 to Length(aText) do
  begin
    if (I+1 <= Length(aText))
    and ((aText[I] + aText[I+1] = '[$') or (aText[I] + aText[I+1] = '[]')) then
      skippingMarkup := True;

    if not skippingMarkup then
      Result := Result + aText[I];

    if skippingMarkup and (aText[I] = ']') then
      skippingMarkup := False;
  end;
end;


// Return black or white text color, that is contrasst to the specified background color
function GetContrastTextColor(aBackgroundColor: Cardinal): Cardinal;
var
  R,G,B: Byte;
  colorValue: Single;
begin
  B := aBackgroundColor and $FF;
  G := aBackgroundColor shr 8 and $FF;
  R := aBackgroundColor shr 16 and $FF;
  colorValue := (R*299 + G*587 + B*114) / 1000; // some fancy formula, that considers each color luminance
  if colorValue >= 128 then
    Result := clBlackText
  else
    Result := clWhiteText;
end;


function FindMPColor(aColor: Cardinal): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := Low(MP_PLAYER_COLORS) to High(MP_PLAYER_COLORS) do
    if MP_PLAYER_COLORS[I] = aColor then
      Result := I;
end;


//Taken from: http://delphi.about.com/od/adptips2005/qt/parsedelimited.htm
procedure ParseDelimited(const Value, Delimiter: UnicodeString; SL: TStringList);
var
  dx: Integer;
  ns: UnicodeString;
  txt: UnicodeString;
  Delta: Integer;
begin
  Delta := Length(Delimiter);
  txt := Value + Delimiter;
  SL.BeginUpdate;
  SL.Clear;
  try
    while Length(txt) > 0 do
    begin
      dx := Pos(Delimiter, txt);
      ns := Copy(txt, 0, dx-1);
      SL.Add(ns);
      txt := Copy(txt, dx+Delta, MaxInt);
    end;
  finally
    SL.EndUpdate;
  end;
end;


function EnsureRangeF(const aValue, aMin, aMax: Single): Single;
begin
  Result := aValue;
  if aValue < aMin then
    Result := aMin
  else
  if aValue > aMax then
    Result := aMax;
end;


// Quote from page 5 of 'Random Number Generators': "We recommend the construction of an initialization procedure,
// Randomize, which prompts for an initial value of seed and forces it to be an integer between 1 and 2^31 - 2."
procedure SetKaMSeed(aSeed: Integer);
begin
  Assert(InRange(aSeed, 1, 2147483646), 'KaMSeed initialised incorrectly: ' + IntToStr(aSeed));
  if CUSTOM_RANDOM then
    fKaMSeed := aSeed
  else
    RandSeed := aSeed;
end;


function GetKaMSeed: Integer;
begin
  if CUSTOM_RANDOM then
    Result := fKaMSeed
  else
    Result := RandSeed;
end;


procedure DoLogKamRandom(aValue: Extended; const aCaller: AnsiString; const aKaMRandomFunc: AnsiString); overload;
begin
  if ((gLog <> nil) and gLog.CanLogRandomChecks()) then
    gLog.LogRandomChecks(Format('Seed: %12d %12s: %30s Caller: %s', [fKamSeed, aKaMRandomFunc, FormatFloat('0.##############################', aValue), aCaller]));
end;


procedure LogKamRandom(aValue: Single; const aCaller: AnsiString; const aKaMRandomFunc: AnsiString); overload;
begin
  DoLogKamRandom(aValue, aCaller, aKaMRandomFunc);

  {$IFDEF WDC}
  if SAVE_RANDOM_CHECKS and (gRandomCheckLogger <> nil) then
    gRandomCheckLogger.AddToLog(aCaller, aValue, fKaMSeed);
  {$ENDIF}
end;


procedure LogKamRandom(aValue: Extended; const aCaller: AnsiString; const aKaMRandomFunc: AnsiString); overload;
begin
  DoLogKamRandom(aValue, aCaller, aKaMRandomFunc);

  {$IFDEF WDC}
  if SAVE_RANDOM_CHECKS and (gRandomCheckLogger <> nil) then
    gRandomCheckLogger.AddToLog(aCaller, aValue, fKaMSeed);
  {$ENDIF}
end;


procedure LogKamRandom(aValue: Integer; const aCaller: AnsiString; const aKaMRandomFunc: AnsiString); overload;
begin
  DoLogKamRandom(aValue, aCaller, aKaMRandomFunc);

  {$IFDEF WDC}
  if SAVE_RANDOM_CHECKS and (gRandomCheckLogger <> nil) then
    gRandomCheckLogger.AddToLog(aCaller, aValue, fKaMSeed);
  {$ENDIF}
end;


//Taken from "Random Number Generators" by Stephen K. Park and Keith W. Miller.
(*  Integer  Version  2  *)
function KaMRandomWSeed(var aSeed: Integer): Extended; overload;
const
  A = 16807;
  M = 2147483647; //Prime number 2^31 - 1
  Q = 127773; // M div A
  R = 2836; // M mod A
var
  C1, C2, NextSeed: integer;
begin
  if not CUSTOM_RANDOM then
  begin
    Result := Random;
    Exit;
  end;

  Assert(InRange(aSeed,1,M-1), 'KaMSeed is not correct: '+IntToStr(aSeed));
  C2 := aSeed div Q;
  C1 := aSeed mod Q;
  NextSeed := A*C1 - R*C2;

  if NextSeed > 0 then
    aSeed := NextSeed
  else
    aSeed := NextSeed + M;

  Result := aSeed / M;
end;


function KaMRandomWSeed(var aSeed: Integer; aMax: Integer): Integer;
begin
  if CUSTOM_RANDOM then
    Result := Trunc(KaMRandomWSeed(aSeed)*aMax)
  else
    Result := Random(aMax);
end;


function KaMRandomWSeedS1(var aSeed: Integer; aMax: Integer): Single;
begin
  Result := KaMRandomWSeed(aSeed, Round(aMax*10000))/10000;
end;


function KaMRandomWSeedI2(var aSeed: Integer; Range_Both_Directions: Integer): Integer;
begin
  Result := KaMRandomWSeed(aSeed, Range_Both_Directions*2+1) - Range_Both_Directions;
end;


function KaMRandom(const aCaller: AnsiString; aLogRng: Boolean = True): Extended;
begin
  Result := KaMRandomWSeed(fKamSeed);

  if aLogRng then
    LogKamRandom(Result, aCaller, 'KMRand');
end;


function KaMRandom(aMax: Integer; const aCaller: AnsiString; aLogRng: Boolean = True): Integer;
begin
  if CUSTOM_RANDOM then
    Result := Trunc(KaMRandom(aCaller, False)*aMax)
  else
    Result := Random(aMax);

  if aLogRng then
    LogKamRandom(Result, aCaller, 'I*');
end;


function KaMRandom(aMax: Cardinal; const aCaller: AnsiString; aLogRng: Boolean = True): Cardinal;
begin
  if CUSTOM_RANDOM then
    Result := Trunc(KaMRandom(aCaller, False)*aMax)
  else
    Result := Random(aMax);

  if aLogRng then
    LogKamRandom(Integer(Result), aCaller, 'C*');
end;


function KaMRandom(aMax: Int64; const aCaller: AnsiString; aLogRng: Boolean = True): Int64;
begin
  if CUSTOM_RANDOM then
    Result := Trunc(KaMRandom(aCaller, False)*aMax)
  else
    Result := Random(aMax);

  if aLogRng then
    LogKamRandom(Integer(Result), aCaller, 'I64*');
end;


//Returns random number from -Range_Both_Directions to +Range_Both_Directions
function KaMRandomI2(Range_Both_Directions: Integer; const aCaller: AnsiString): Integer;
begin
  Result := KaMRandom(Range_Both_Directions*2+1, aCaller, False) - Range_Both_Directions;

  LogKamRandom(Result, aCaller, 'S2I*');
end;


//Returns random number from -Range_Both_Directions to +Range_Both_Directions
function KaMRandomS2(Range_Both_Directions: Single; const aCaller: AnsiString): Single;
begin
  Result := KaMRandom(Round(Range_Both_Directions*20000)+1, aCaller, False)/10000-Range_Both_Directions;

  LogKamRandom(Result, aCaller, 'S2S*');
end;


//Returns random number from 0 to +aMax
function KaMRandomS1(aMax: Single; const aCaller: AnsiString): Single;
begin
  Result := KaMRandom(Round(aMax*10000), aCaller, False)/10000;

  LogKamRandom(Result, aCaller, 'S1S*');
end;


// Returns file directory name
// F.e. for aFilePath = 'c:/kam/remake/fore.ver' returns 'remake'
// and for 'Maps/My new map' returns 'Maps'
function GetFileDirName(const aFilePath: UnicodeString): UnicodeString;
var
  dirPath: UnicodeString;
begin
  Result := '';
  if Trim(aFilePath) = '' then Exit;

  dirPath := ExtractFileDir(aFilePath);

  if dirPath = '' then Exit;

  if StrIndexOf(dirPath, PathDelim) <> -1 then
    Result := copy(dirPath, StrLastIndexOf(dirPath, PathDelim) + 2)
  else
    Result := dirPath;
end;


// Returnes text ignoring color markup [$FFFFFF][]
function GetNoColorMarkupText(const aText: UnicodeString): UnicodeString;
var I, TmpColor: Integer;
begin
  Result := '';

  if aText = '' then Exit;

  I := 1;
  while I <= Length(aText) do
  begin
    //Ignore color markups [$FFFFFF][]
    if (aText[I]='[') and (I+1 <= Length(aText)) and (aText[I+1]=']') then
      Inc(I) //Skip past this markup
    else
      if (aText[I]='[') and (I+8 <= Length(aText))
      and (aText[I+1] = '$') and (aText[I+8]=']')
      and TryStrToInt(Copy(aText, I+1, 7), TmpColor) then
        Inc(I,8) //Skip past this markup
      else
        //Not markup so count width normally
        Result := Result + aText[I];
    Inc(I);
  end;
end;


procedure GetAllPathsInDir(const aDir: String; aSL: TStringList; aIncludeSubdirs: Boolean = True);
var
  ValidateFn: TBooleanStringFunc;
begin
  ValidateFn := nil;
  GetAllPathsInDir(aDir, aSL, ValidateFn, aIncludeSubdirs);
end;


procedure GetAllPathsInDir(const aDir: String; aSL: TStringList; const aExt: String; aIncludeSubdirs: Boolean = True);
var
  SR: TSearchRec;
begin
  try
    if FindFirst(IncludeTrailingPathDelimiter(aDir) + '*', faAnyFile or faDirectory, SR) = 0 then
      repeat
        if (SR.Attr and faDirectory) = 0 then
        begin
          if AnsiEndsStr(aExt, SR.Name) then
            aSL.Add(IncludeTrailingPathDelimiter(aDir) + SR.Name);
        end
        else
        if aIncludeSubdirs and (SR.Name <> '.') and (SR.Name <> '..') then
          GetAllPathsInDir(IncludeTrailingPathDelimiter(aDir) + SR.Name, aSL, aExt, aIncludeSubdirs);  // recursive call!
      until FindNext(Sr) <> 0;
  finally
    SysUtils.FindClose(SR);
  end;
end;


procedure GetAllPathsInDir(const aDir: String; aSL: TStringList; aValidateFn: TBooleanStringFunc; aIncludeSubdirs: Boolean = True);
var
  SR: TSearchRec;
begin
  try
    if FindFirst(IncludeTrailingPathDelimiter(aDir) + '*', faAnyFile or faDirectory, SR) = 0 then
      repeat
        if (SR.Attr and faDirectory) = 0 then
        begin
          if not Assigned(aValidateFn) or aValidateFn(SR.Name) then
            aSL.Add(IncludeTrailingPathDelimiter(aDir) + SR.Name);
        end
        else
        if aIncludeSubdirs and (SR.Name <> '.') and (SR.Name <> '..') then
          GetAllPathsInDir(IncludeTrailingPathDelimiter(aDir) + SR.Name, aSL, aValidateFn, aIncludeSubdirs);  // recursive call!
      until FindNext(Sr) <> 0;
  finally
    SysUtils.FindClose(SR);
  end;
end;


//Replace continious spaces with single space
function DeleteDoubleSpaces(const aString: string): string;
var I: Integer;
begin
  Result := '';
  if aString = '' then Exit;
  Result := aString[1];

  for I := 2 to Length(aString) do
  begin
    if aString[I] = ' ' then
    begin
      if not (aString[I-1] = ' ') then
        Result := Result + ' ';
    end else
      Result := Result + aString[I];
  end;
end;


function CountOccurrences(const aSubstring, aText: String): Integer;
var
  Offset: integer;
begin
  Result := 0;
  Offset := PosEx(aSubstring, aText, 1);
  while Offset <> 0 do
  begin
    Inc(Result);
    Offset := PosEx(aSubstring, aText, Offset + length(aSubstring));
  end;
end;


function IntToBool(aValue: Integer): Boolean;
begin
  Result := aValue <> 0;
end;


// use this to not get "banker's rounding"
function HumanRound(X: Extended): Integer;
// Rounds a number "normally": if the fractional
// part is >= 0.5 the number is rounded up (see RoundUp)
// Otherwise, if the fractional part is < 0.5, the
// number is rounded down
//   RoundN(3.5) = 4     RoundN(-3.5) = -4
//   RoundN(3.1) = 3     RoundN(-3.1) = -3
begin
  // Trunc() does nothing except conv to integer.  needed because return type of Int() is Extended
  Result := Trunc(Int(X) + Int(Frac(X) * 2));
end;


const
  SPACE_CHARS: set of AnsiChar = [' ', '|'];

//Get next word position in the given aStr, after cirtain position aPos
//positions starts from 0
function GetNextWordPos(const aStr: String; aPos: Integer): Integer;
var
  I, pos: Integer;
  found: Boolean;
begin
  pos := aPos;
  Result := Length(aStr);
  found := False;

  //Cut all spaces
  while (pos + 1 < Length(aStr)) and CharInSet(aStr[pos + 1], SPACE_CHARS) do
    Inc(pos);

  //Result is the position of the latest space after last non-space character
  for I := pos + 1 to Length(aStr) - 1 do
  begin
    if CharInSet(aStr[I], SPACE_CHARS) then
    begin
      Result := I;
      found := True;
    end
    else
    if found then
      Break;
  end;

  Result := Min(Length(aStr), Max(aPos + 1, Result));
end;


//Get previous word position in the given aStr, after cirtain position aPos
//positions starts from 0
function GetPrevWordPos(const aStr: String; aPos: Integer): Integer;
var
  I, pos: Integer;
begin
  pos := aPos;

  //Cut all spaces
  while (pos >= 1) and CharInSet(aStr[pos], SPACE_CHARS) do
    Dec(pos);

  //Result is the first non-space character
  Result := pos;
  for I := pos downto 1 do
  begin
    if not CharInSet(aStr[I], SPACE_CHARS) then
      Result := I - 1
    else
      Break;
  end;

  Result := Max(0, Min(aPos - 1, Result));
end;


{
String functions
These function are replacements for String functions introduced after XE2 (XE5 probably)
Names are the same as in new Delphi versions, but with 'Str' prefix
}
function StrIndexOf(const aStr, aSubStr: String): Integer;
begin
  //todo: refactor:
  //@Krom: Why not just replace StrIndexOf with Pos everywhere in code?
  Result := AnsiPos(aSubStr, aStr) - 1;
end;


function StrLastIndexOf(const aStr, aSubStr: String): Integer;
var I: Integer;
begin
  Result := -1;
  for I := 1 to Length(aStr) do
    if AnsiPos(aSubStr, StrSubstring(aStr, I-1)) <> 0 then
      Result := I - 1;
end;


function StrSubstring(const aStr: String; aFrom: Integer): String;
begin
  //todo: refactor:
  //@Krom: Why not just replace StrSubstring with RightStr everywhere in code?
  Result := Copy(aStr, aFrom + 1, Length(aStr));
end;


function StrSubstring(const aStr: String; aFrom, aLength: Integer): String;
begin
  //todo: refactor:
  //@Krom: Why not just replace StrSubstring with Copy everywhere in code?
  Result := Copy(aStr, aFrom + 1, aLength);
end;


function StrContains(const aStr, aSubStr: String): Boolean;
begin
  //todo: refactor:
  //@Krom: Why not just replace StrContains with Pos() <> 0 everywhere in code?
  Result := StrIndexOf(aStr, aSubStr) <> -1;
end;


function StrTrimRight(const aStr: String; aCharsToTrim: TKMCharArray): String;
var
  found: Boolean;
  I, J: Integer;
begin
  for I := Length(aStr) downto 1 do
  begin
    found := False;
    for J := Low(aCharsToTrim) to High(aCharsToTrim) do
    begin
      if aStr[I] = aCharsToTrim[J] then
      begin
        found := True;
        Break;
      end;
    end;
    if not found then
      Break;
  end;
  Result := Copy(aStr, 1, I);
end;


function StrTrimChar(const aStr: String; aChar: Char): string;
var
  leftSide, rightSide: Integer;
begin
  leftSide := 1;
  while (leftSide <= Length(aStr)) and (aStr[leftSide] = aChar) do Inc(leftSide);

  rightSide := Length(aStr);
  while (rightSide >= 1) and (aStr[rightSide] = aChar) do Dec(rightSide);

  Result := Copy(aStr, leftSide, rightSide - leftSide + 1)
end;


procedure StringSplit(const aStr: string; aDelimiter: Char; aListOfStrings: TStrings) ;
begin
  aListOfStrings.Clear;
  aListOfStrings.Delimiter       := aDelimiter;
  aListOfStrings.StrictDelimiter := True;
  aListOfStrings.DelimitedText   := aStr;
end;


{$IFDEF WDC}
procedure StrSplit(const aStr, aDelimiters: String; var aStrings: TStringList);
var
  StrArray: TStringDynArray;
  I: Integer;
begin
  StrArray := SplitString(aStr, aDelimiters);
  for I := Low(StrArray) to High(StrArray) do
    aStrings.Add(StrArray[I]);
end;

function StrSplitA(const aStr, aDelimiters: String): TAnsiStringArray;
begin
  Result := TAnsiStringArray(SplitString(aStr, aDelimiters));
end;
{$ENDIF}


{$IFDEF FPC}
function StrSplitA(const aStr, aDelimiters: string): TAnsiStringArray;
var
  I: integer;
  PosDel: integer;
  CopyOfText: string;
begin
  CopyOfText := aStr;
  i := 0;
  SetLength(Result, 1);
  PosDel := Pos(aDelimiters, aStr);
  while PosDel > 0 do
    begin
      Result[I] := Copy(CopyOfText, 1, PosDel - 1);
      Delete(CopyOfText, 1, Length(Result[I]) + 1);
      PosDel := Pos(aDelimiters, CopyOfText);
      inc(I);
      SetLength(Result, I + 1);
    end;
  Result[I] := Copy(CopyOfText, 1, Length(CopyOfText));
end;
{$ENDIF}


{$IF Defined(FPC) or Defined(VER230)}
procedure DeleteFromArray(var Arr: TAnsiStringArray; const Index: Integer);
var
  ALength: Integer;
  I: Integer;
begin
  ALength := Length(Arr);
  Assert(ALength > 0);
  Assert(Index < ALength);
  for I := Index + 1 to ALength - 1 do
    Arr[I - 1] := Arr[I];
  SetLength(Arr, ALength - 1);
end;


procedure DeleteFromArray(var Arr: TIntegerArray; const Index: Integer);
var
  ALength: Integer;
  I: Integer;
begin
  ALength := Length(Arr);
  Assert(ALength > 0);
  Assert(Index < ALength);
  for I := Index + 1 to ALength - 1 do
    Arr[I - 1] := Arr[I];
  SetLength(Arr, ALength - 1);
end;
{$ELSE}

procedure DeleteFromArray(var Arr: TAnsiStringArray; const Index: Integer);
begin
  Delete(Arr, Index, 1);
end;


procedure DeleteFromArray(var Arr: TIntegerArray; const Index: Integer);
begin
  Delete(Arr, Index, 1);
end;
{$ENDIF}


function TryExecuteMethod(const aStrParam, aMethodName: UnicodeString; var aErrorStr: UnicodeString;
                          aMethod: TUnicodeStringEvent; aAttemps: Byte = DEFAULT_ATTEMPS_CNT_TO_TRY): Boolean;
var
  tryCnt: Byte;
begin
  Result := False;
  tryCnt := 0;
  aErrorStr := '';
  while not Result and (tryCnt < aAttemps) do
    try
      Inc(tryCnt);

      aMethod(aStrParam);

      Result := True;
    except
      on E: Exception do //Ignore IO exceptions here, try to save file up to 3 times
      begin
        aErrorStr := Format('Error at attemp #%d while executing method %s for parameter: %s', [tryCnt, aMethodName, aStrParam]);
        Sleep(50); // Wait a bit
      end;
    end;

  if not Result then
    aErrorStr := Format('Error executing method (%d tries) %s for parameter: %s', [aAttemps, aMethodName, aStrParam]);
end;


function TryExecuteMethod(aObjParam: TObject; const aStrParam, aMethodName: UnicodeString; var aErrorStr: UnicodeString;
                          aMethod: TUnicodeStringObjEvent; aAttemps: Byte = DEFAULT_ATTEMPS_CNT_TO_TRY): Boolean;
var
  tryCnt: Byte;
begin
  Result := False;
  tryCnt := 0;
  aErrorStr := '';
  while not Result and (tryCnt < aAttemps) do
    try
      Inc(tryCnt);

      aMethod(aObjParam, aStrParam);

      Result := True;
    except
      on E: Exception do //Ignore IO exceptions here, try to save file up to 3 times
      begin
        aErrorStr := Format('Error at attemp #%d while executing method %s for parameter: %s', [tryCnt, aMethodName, aStrParam]);
        Sleep(50); // Wait a bit
      end;
    end;

  if not Result then
    aErrorStr := Format('Error executing method (%d tries) %s for parameter: %s', [aAttemps, aMethodName, aStrParam]);
end;


function TryExecuteMethodProc(const aStrParam, aMethodName: UnicodeString; var aErrorStr: UnicodeString;
                              aMethodProc: TUnicodeStringEventProc; aAttemps: Byte = DEFAULT_ATTEMPS_CNT_TO_TRY): Boolean;
var
  tryCnt: Byte;
begin
  Result := False;
  tryCnt := 0;
  aErrorStr := '';
  while not Result and (tryCnt < aAttemps) do
    try
      Inc(tryCnt);

      aMethodProc(aStrParam);

      Result := True;
    except
      on E: Exception do //Ignore IO exceptions here, try to save file up to 3 times
      begin
        aErrorStr := Format('Error at attemp #%d while executing method %s for parameter: %s', [tryCnt, aMethodName, aStrParam]);
        Sleep(50); // Wait a bit
      end;
    end;

  if not Result then
    aErrorStr := Format('Error executing method (%d tries) %s for parameter: %s', [aAttemps, aMethodName, aStrParam]);
end;


function TryExecuteMethodProc(const aStrParam1, aStrParam2, aMethodName: UnicodeString; var aErrorStr: UnicodeString;
                              aMethodProc: TUnicode2StringEventProc; aAttemps: Byte = DEFAULT_ATTEMPS_CNT_TO_TRY): Boolean;
var
  tryCnt: Byte;
begin
  Result := False;
  tryCnt := 0;
  aErrorStr := '';
  while not Result and (tryCnt < aAttemps) do
    try
      Inc(tryCnt);

      aMethodProc(aStrParam1, aStrParam2);

      Result := True;
    except
      on E: Exception do //Ignore IO exceptions here, try to save file up to 3 times
      begin
        aErrorStr := Format('Error at attemp #%d while executing method %s for parameters: [%s, %s]', [tryCnt, aMethodName, aStrParam1, aStrParam2]);
        Sleep(50); // Wait a bit
      end;
    end;

  if not Result then
    aErrorStr := Format('Error executing method (%d tries) %s for parameters: [%s, %s]', [aAttemps, aMethodName, aStrParam1, aStrParam2]);
end;


initialization
begin
  gFormatSettingsDotSeparator := {$IFDEF WDC} TFormatSettings.Create; {$ENDIF}
                                 {$IFDEF FPC} DefaultFormatSettings;  {$ENDIF}
  gFormatSettingsDotSeparator.DecimalSeparator := '.';
end;


end.
