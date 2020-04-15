unit KM_CommonTypes;
{$I KaM_Remake.inc}
interface

uses
  KM_Points;

type
  TKMByteSet = set of Byte;
  TByteSet = set of Byte; //Legasy support for old scripts

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
  TIntegerArray = array of Integer;
  TInteger2Array = array of array of Integer;
  TAnsiStringArray = array of AnsiString;
  TSingleArray = array of Single;
  TSingle2Array = array of array of Single;
  TKMStringArray = array of string;
  TKMCharArray = array of Char;
  TRGB = record R,G,B: Byte end;
  TRGBArray = array of TRGB;
  TKMStaticByteArray = array [0..MaxInt - 1] of Byte;
  PKMStaticByteArray = ^TKMStaticByteArray;

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
  TBooleanStringFunc = function (aValue: String): Boolean of object;
  TBooleanFuncSimple = function: Boolean of object;
  TBoolIntFuncSimple = function (aValue: Integer): Boolean of object;
  TObjectIntBoolEvent = procedure (Sender: TObject; aIntValue: Integer; aBoolValue: Boolean) of object;

  TKMAnimLoop = packed record
                  Step: array [1 .. 30] of SmallInt;
                  Count: SmallInt;
                  MoveX, MoveY: Integer;
                end;

  //Message kind determines icon and available actions for Message
  TKMMessageKind = (
    mkText, //Mission text message
    mkHouse,
    mkUnit,
    mkQuill //Utility message (warnings in script loading)
    );

  TKMAudioFormat = (afWav, afOgg);

  TWonOrLost = (wolNone, wolWon, wolLost);

  //Menu load type - load / no load / load unsupported version
  TKMGameStartMode = (gsmNoStart, gsmStart, gsmStartWithWarn, gsmNoStartWithWarn);

  TKMCustomScriptParam = (cspTHTroopCosts, cspMarketGoldPrice);

  TKMCustomScriptParamData = record
    Added: Boolean;
    Data: UnicodeString;
  end;


  TKMAIType = (aitNone, aitClassic, aitAdvanced);
  TKMAITypeSet = set of TKMAIType;

  TKMUserActionType = (uatNone, uatKeyDown, uatKeyUp, uatKeyPress, uatMouseDown, uatMouseUp, uatMouseMove, uatMouseWheel);
  TKMUserActionEvent = procedure (aActionType: TKMUserActionType) of object;


  TKMCustomScriptParamDataArray = array [TKMCustomScriptParam] of TKMCustomScriptParamData;

  TKMPlayerColorMode = (pcmNone, pcmDefault, pcmAllyEnemy, pcmTeams);

  TKMGameRevision = Word; //Word looks enought for now...

  TKMColor3f = record
    R,G,B: Single;
    function ToCardinal: Cardinal;
    class function Generic(aIndex: Integer): TKMColor3f; static;
  end;
//             Result := R + G shl 8 + B shl 16 + A shl 24;
  TKMColor4f = record
    R,G,B,A: Single;
    constructor New(aCol: TKMColor3f); overload;
    constructor New(aCol: TKMColor3f; aAlpha: Single); overload;
    class function White(): TKMColor4f; static;
    function Alpha50(): TKMColor4f;
    function Alpha(aAlpha: Single): TKMColor4f;
  end;

const
  WonOrLostText: array [TWonOrLost] of UnicodeString = ('None', 'Won', 'Lost');

implementation
uses
  Math;

{ TKMColor3f }
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


{ TKMColor4f }
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


end.
