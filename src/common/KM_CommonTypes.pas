unit KM_CommonTypes;
{$I KaM_Remake.inc}
interface

uses
  KM_Points, KM_Defaults;

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
  TStringArray = array of string;
  TKMCharArray = array of Char;
  TRGBArray = array of record R,G,B: Byte end;
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

  {$IFDEF WDC}
  TAnonProc = reference to procedure;
  TAnonBooleanFn = reference to function: Boolean;
  {$ENDIF}

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

  TWonOrLost = (wolNone, wolWon, wolLost);

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

  TKMPlayerColorMode = (pcmNone, pcmColors, pcmAllyEnemy, pcmTeams);

  const
    WonOrLostText: array [TWonOrLost] of UnicodeString = ('None', 'Won', 'Lost');

implementation


end.
