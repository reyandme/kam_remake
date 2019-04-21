unit KM_ScriptingConsoleCommands;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils,
  KM_Defaults, KM_CommonClasses;

const
  MAX_SCRIPT_CONSOLE_COMMAND_PARAMS = 4;
type

  TKMScriptCommandParamsArray = array [0..MAX_SCRIPT_CONSOLE_COMMAND_PARAMS-1] of String;

  TKMCmdProcParamTypeKind = (
    cpkNone,
    cpkBool,
    cpkIntg,
    cpkSngl,
    cpkUStr
  );


  TKMConsoleCommand = class
  private
    fName: AnsiString;
    fProcName: AnsiString;
    fHandler: TMethod;
    fPT: array[0..MAX_SCRIPT_CONSOLE_COMMAND_PARAMS - 1] of TKMCmdProcParamTypeKind; //We support up to 4 params

    function GetProcParamType(aIndex: Integer): TKMCmdProcParamTypeKind;
    function GetProcParamsCnt: Integer;

    function P2B(const aParam: String): Boolean; inline;
    function P2I(const aParam: String): Integer; inline;
    function P2S(const aParam: String): Single; inline;
    function P2U(const aParam: String): String; inline;
  public
    constructor Create; overload;
    constructor Create(const aName, aProcName: AnsiString); overload;
    constructor Create(const aName, aProcName: AnsiString; const aParamTypes: array of TKMCmdProcParamTypeKind); overload;

    property Name: AnsiString read fName;
    property ProcName: AnsiString read fProcName;
    property ProcParamsCnt: Integer read GetProcParamsCnt;
    property ProcParam[aIndex: Integer]: TKMCmdProcParamTypeKind read GetProcParamType;
    property Handler: TMethod read fHandler write fHandler;

    procedure TryCallProcedure(aHandID: TKMHandID; const P: TKMScriptCommandParamsArray);
    function ValidateParams(const aParams: TKMScriptCommandParamsArray): Boolean;
    function ParseParameters(const aProcedureStr: String; aRow: Integer): Boolean;
    function Params2String(const aParams: TKMScriptCommandParamsArray; aColorfull: Boolean = True): String;
    function ParamsTypes2String(aColorfull: Boolean = True): String;

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    
//    class procedure GenerateProcClasses(aSL: TStringList);
//    class procedure GenerateCaseClause(aSL: TStringList);
  end;


  EConsoleCommandParseError = class(Exception)
  public
    Row: Integer;
    Col: Integer;
    Token: String;
    constructor Create(const aErrorMsg: String); overload;
    constructor Create(const aErrorMsg: String; aRow, aCol: Integer; const aToken: String); overload;
  end;


var
  gSingleDotFormat: TFormatSettings;


implementation
uses
  TypInfo, StrUtils,
  KM_MethodParser, KM_ResTexts,
  KM_CommonUtils;

const
  CLASS_TYPE_STR: array[TKMCmdProcParamTypeKind] of  String = ('', 'Boolean', 'Integer', 'Single', 'String');

type
  EWrongParamType = class(Exception);

  TKMScriptCmdProc     = procedure(aIndex: Integer) of object;
  TKMScriptCmdProcB    = procedure(aIndex: Integer; aP1: Boolean) of object;
  TKMScriptCmdProcBB   = procedure(aIndex: Integer; aP1: Boolean; aP2: Boolean) of object;
  TKMScriptCmdProcBBB  = procedure(aIndex: Integer; aP1: Boolean; aP2: Boolean; aP3: Boolean) of object;
  TKMScriptCmdProcBBBB = procedure(aIndex: Integer; aP1: Boolean; aP2: Boolean; aP3: Boolean; aP4: Boolean) of object;
  TKMScriptCmdProcBBBI = procedure(aIndex: Integer; aP1: Boolean; aP2: Boolean; aP3: Boolean; aP4: Integer) of object;
  TKMScriptCmdProcBBBS = procedure(aIndex: Integer; aP1: Boolean; aP2: Boolean; aP3: Boolean; aP4: Single) of object;
  TKMScriptCmdProcBBBU = procedure(aIndex: Integer; aP1: Boolean; aP2: Boolean; aP3: Boolean; aP4: String) of object;
  TKMScriptCmdProcBBI  = procedure(aIndex: Integer; aP1: Boolean; aP2: Boolean; aP3: Integer) of object;
  TKMScriptCmdProcBBIB = procedure(aIndex: Integer; aP1: Boolean; aP2: Boolean; aP3: Integer; aP4: Boolean) of object;
  TKMScriptCmdProcBBII = procedure(aIndex: Integer; aP1: Boolean; aP2: Boolean; aP3: Integer; aP4: Integer) of object;
  TKMScriptCmdProcBBIS = procedure(aIndex: Integer; aP1: Boolean; aP2: Boolean; aP3: Integer; aP4: Single) of object;
  TKMScriptCmdProcBBIU = procedure(aIndex: Integer; aP1: Boolean; aP2: Boolean; aP3: Integer; aP4: String) of object;
  TKMScriptCmdProcBBS  = procedure(aIndex: Integer; aP1: Boolean; aP2: Boolean; aP3: Single) of object;
  TKMScriptCmdProcBBSB = procedure(aIndex: Integer; aP1: Boolean; aP2: Boolean; aP3: Single; aP4: Boolean) of object;
  TKMScriptCmdProcBBSI = procedure(aIndex: Integer; aP1: Boolean; aP2: Boolean; aP3: Single; aP4: Integer) of object;
  TKMScriptCmdProcBBSS = procedure(aIndex: Integer; aP1: Boolean; aP2: Boolean; aP3: Single; aP4: Single) of object;
  TKMScriptCmdProcBBSU = procedure(aIndex: Integer; aP1: Boolean; aP2: Boolean; aP3: Single; aP4: String) of object;
  TKMScriptCmdProcBBU  = procedure(aIndex: Integer; aP1: Boolean; aP2: Boolean; aP3: String) of object;
  TKMScriptCmdProcBBUB = procedure(aIndex: Integer; aP1: Boolean; aP2: Boolean; aP3: String; aP4: Boolean) of object;
  TKMScriptCmdProcBBUI = procedure(aIndex: Integer; aP1: Boolean; aP2: Boolean; aP3: String; aP4: Integer) of object;
  TKMScriptCmdProcBBUS = procedure(aIndex: Integer; aP1: Boolean; aP2: Boolean; aP3: String; aP4: Single) of object;
  TKMScriptCmdProcBBUU = procedure(aIndex: Integer; aP1: Boolean; aP2: Boolean; aP3: String; aP4: String) of object;
  TKMScriptCmdProcBI   = procedure(aIndex: Integer; aP1: Boolean; aP2: Integer) of object;
  TKMScriptCmdProcBIB  = procedure(aIndex: Integer; aP1: Boolean; aP2: Integer; aP3: Boolean) of object;
  TKMScriptCmdProcBIBB = procedure(aIndex: Integer; aP1: Boolean; aP2: Integer; aP3: Boolean; aP4: Boolean) of object;
  TKMScriptCmdProcBIBI = procedure(aIndex: Integer; aP1: Boolean; aP2: Integer; aP3: Boolean; aP4: Integer) of object;
  TKMScriptCmdProcBIBS = procedure(aIndex: Integer; aP1: Boolean; aP2: Integer; aP3: Boolean; aP4: Single) of object;
  TKMScriptCmdProcBIBU = procedure(aIndex: Integer; aP1: Boolean; aP2: Integer; aP3: Boolean; aP4: String) of object;
  TKMScriptCmdProcBII  = procedure(aIndex: Integer; aP1: Boolean; aP2: Integer; aP3: Integer) of object;
  TKMScriptCmdProcBIIB = procedure(aIndex: Integer; aP1: Boolean; aP2: Integer; aP3: Integer; aP4: Boolean) of object;
  TKMScriptCmdProcBIII = procedure(aIndex: Integer; aP1: Boolean; aP2: Integer; aP3: Integer; aP4: Integer) of object;
  TKMScriptCmdProcBIIS = procedure(aIndex: Integer; aP1: Boolean; aP2: Integer; aP3: Integer; aP4: Single) of object;
  TKMScriptCmdProcBIIU = procedure(aIndex: Integer; aP1: Boolean; aP2: Integer; aP3: Integer; aP4: String) of object;
  TKMScriptCmdProcBIS  = procedure(aIndex: Integer; aP1: Boolean; aP2: Integer; aP3: Single) of object;
  TKMScriptCmdProcBISB = procedure(aIndex: Integer; aP1: Boolean; aP2: Integer; aP3: Single; aP4: Boolean) of object;
  TKMScriptCmdProcBISI = procedure(aIndex: Integer; aP1: Boolean; aP2: Integer; aP3: Single; aP4: Integer) of object;
  TKMScriptCmdProcBISS = procedure(aIndex: Integer; aP1: Boolean; aP2: Integer; aP3: Single; aP4: Single) of object;
  TKMScriptCmdProcBISU = procedure(aIndex: Integer; aP1: Boolean; aP2: Integer; aP3: Single; aP4: String) of object;
  TKMScriptCmdProcBIU  = procedure(aIndex: Integer; aP1: Boolean; aP2: Integer; aP3: String) of object;
  TKMScriptCmdProcBIUB = procedure(aIndex: Integer; aP1: Boolean; aP2: Integer; aP3: String; aP4: Boolean) of object;
  TKMScriptCmdProcBIUI = procedure(aIndex: Integer; aP1: Boolean; aP2: Integer; aP3: String; aP4: Integer) of object;
  TKMScriptCmdProcBIUS = procedure(aIndex: Integer; aP1: Boolean; aP2: Integer; aP3: String; aP4: Single) of object;
  TKMScriptCmdProcBIUU = procedure(aIndex: Integer; aP1: Boolean; aP2: Integer; aP3: String; aP4: String) of object;
  TKMScriptCmdProcBS   = procedure(aIndex: Integer; aP1: Boolean; aP2: Single) of object;
  TKMScriptCmdProcBSB  = procedure(aIndex: Integer; aP1: Boolean; aP2: Single; aP3: Boolean) of object;
  TKMScriptCmdProcBSBB = procedure(aIndex: Integer; aP1: Boolean; aP2: Single; aP3: Boolean; aP4: Boolean) of object;
  TKMScriptCmdProcBSBI = procedure(aIndex: Integer; aP1: Boolean; aP2: Single; aP3: Boolean; aP4: Integer) of object;
  TKMScriptCmdProcBSBS = procedure(aIndex: Integer; aP1: Boolean; aP2: Single; aP3: Boolean; aP4: Single) of object;
  TKMScriptCmdProcBSBU = procedure(aIndex: Integer; aP1: Boolean; aP2: Single; aP3: Boolean; aP4: String) of object;
  TKMScriptCmdProcBSI  = procedure(aIndex: Integer; aP1: Boolean; aP2: Single; aP3: Integer) of object;
  TKMScriptCmdProcBSIB = procedure(aIndex: Integer; aP1: Boolean; aP2: Single; aP3: Integer; aP4: Boolean) of object;
  TKMScriptCmdProcBSII = procedure(aIndex: Integer; aP1: Boolean; aP2: Single; aP3: Integer; aP4: Integer) of object;
  TKMScriptCmdProcBSIS = procedure(aIndex: Integer; aP1: Boolean; aP2: Single; aP3: Integer; aP4: Single) of object;
  TKMScriptCmdProcBSIU = procedure(aIndex: Integer; aP1: Boolean; aP2: Single; aP3: Integer; aP4: String) of object;
  TKMScriptCmdProcBSS  = procedure(aIndex: Integer; aP1: Boolean; aP2: Single; aP3: Single) of object;
  TKMScriptCmdProcBSSB = procedure(aIndex: Integer; aP1: Boolean; aP2: Single; aP3: Single; aP4: Boolean) of object;
  TKMScriptCmdProcBSSI = procedure(aIndex: Integer; aP1: Boolean; aP2: Single; aP3: Single; aP4: Integer) of object;
  TKMScriptCmdProcBSSS = procedure(aIndex: Integer; aP1: Boolean; aP2: Single; aP3: Single; aP4: Single) of object;
  TKMScriptCmdProcBSSU = procedure(aIndex: Integer; aP1: Boolean; aP2: Single; aP3: Single; aP4: String) of object;
  TKMScriptCmdProcBSU  = procedure(aIndex: Integer; aP1: Boolean; aP2: Single; aP3: String) of object;
  TKMScriptCmdProcBSUB = procedure(aIndex: Integer; aP1: Boolean; aP2: Single; aP3: String; aP4: Boolean) of object;
  TKMScriptCmdProcBSUI = procedure(aIndex: Integer; aP1: Boolean; aP2: Single; aP3: String; aP4: Integer) of object;
  TKMScriptCmdProcBSUS = procedure(aIndex: Integer; aP1: Boolean; aP2: Single; aP3: String; aP4: Single) of object;
  TKMScriptCmdProcBSUU = procedure(aIndex: Integer; aP1: Boolean; aP2: Single; aP3: String; aP4: String) of object;
  TKMScriptCmdProcBU   = procedure(aIndex: Integer; aP1: Boolean; aP2: String) of object;
  TKMScriptCmdProcBUB  = procedure(aIndex: Integer; aP1: Boolean; aP2: String; aP3: Boolean) of object;
  TKMScriptCmdProcBUBB = procedure(aIndex: Integer; aP1: Boolean; aP2: String; aP3: Boolean; aP4: Boolean) of object;
  TKMScriptCmdProcBUBI = procedure(aIndex: Integer; aP1: Boolean; aP2: String; aP3: Boolean; aP4: Integer) of object;
  TKMScriptCmdProcBUBS = procedure(aIndex: Integer; aP1: Boolean; aP2: String; aP3: Boolean; aP4: Single) of object;
  TKMScriptCmdProcBUBU = procedure(aIndex: Integer; aP1: Boolean; aP2: String; aP3: Boolean; aP4: String) of object;
  TKMScriptCmdProcBUI  = procedure(aIndex: Integer; aP1: Boolean; aP2: String; aP3: Integer) of object;
  TKMScriptCmdProcBUIB = procedure(aIndex: Integer; aP1: Boolean; aP2: String; aP3: Integer; aP4: Boolean) of object;
  TKMScriptCmdProcBUII = procedure(aIndex: Integer; aP1: Boolean; aP2: String; aP3: Integer; aP4: Integer) of object;
  TKMScriptCmdProcBUIS = procedure(aIndex: Integer; aP1: Boolean; aP2: String; aP3: Integer; aP4: Single) of object;
  TKMScriptCmdProcBUIU = procedure(aIndex: Integer; aP1: Boolean; aP2: String; aP3: Integer; aP4: String) of object;
  TKMScriptCmdProcBUS  = procedure(aIndex: Integer; aP1: Boolean; aP2: String; aP3: Single) of object;
  TKMScriptCmdProcBUSB = procedure(aIndex: Integer; aP1: Boolean; aP2: String; aP3: Single; aP4: Boolean) of object;
  TKMScriptCmdProcBUSI = procedure(aIndex: Integer; aP1: Boolean; aP2: String; aP3: Single; aP4: Integer) of object;
  TKMScriptCmdProcBUSS = procedure(aIndex: Integer; aP1: Boolean; aP2: String; aP3: Single; aP4: Single) of object;
  TKMScriptCmdProcBUSU = procedure(aIndex: Integer; aP1: Boolean; aP2: String; aP3: Single; aP4: String) of object;
  TKMScriptCmdProcBUU  = procedure(aIndex: Integer; aP1: Boolean; aP2: String; aP3: String) of object;
  TKMScriptCmdProcBUUB = procedure(aIndex: Integer; aP1: Boolean; aP2: String; aP3: String; aP4: Boolean) of object;
  TKMScriptCmdProcBUUI = procedure(aIndex: Integer; aP1: Boolean; aP2: String; aP3: String; aP4: Integer) of object;
  TKMScriptCmdProcBUUS = procedure(aIndex: Integer; aP1: Boolean; aP2: String; aP3: String; aP4: Single) of object;
  TKMScriptCmdProcBUUU = procedure(aIndex: Integer; aP1: Boolean; aP2: String; aP3: String; aP4: String) of object;
  TKMScriptCmdProcI    = procedure(aIndex: Integer; aP1: Integer) of object;
  TKMScriptCmdProcIB   = procedure(aIndex: Integer; aP1: Integer; aP2: Boolean) of object;
  TKMScriptCmdProcIBB  = procedure(aIndex: Integer; aP1: Integer; aP2: Boolean; aP3: Boolean) of object;
  TKMScriptCmdProcIBBB = procedure(aIndex: Integer; aP1: Integer; aP2: Boolean; aP3: Boolean; aP4: Boolean) of object;
  TKMScriptCmdProcIBBI = procedure(aIndex: Integer; aP1: Integer; aP2: Boolean; aP3: Boolean; aP4: Integer) of object;
  TKMScriptCmdProcIBBS = procedure(aIndex: Integer; aP1: Integer; aP2: Boolean; aP3: Boolean; aP4: Single) of object;
  TKMScriptCmdProcIBBU = procedure(aIndex: Integer; aP1: Integer; aP2: Boolean; aP3: Boolean; aP4: String) of object;
  TKMScriptCmdProcIBI  = procedure(aIndex: Integer; aP1: Integer; aP2: Boolean; aP3: Integer) of object;
  TKMScriptCmdProcIBIB = procedure(aIndex: Integer; aP1: Integer; aP2: Boolean; aP3: Integer; aP4: Boolean) of object;
  TKMScriptCmdProcIBII = procedure(aIndex: Integer; aP1: Integer; aP2: Boolean; aP3: Integer; aP4: Integer) of object;
  TKMScriptCmdProcIBIS = procedure(aIndex: Integer; aP1: Integer; aP2: Boolean; aP3: Integer; aP4: Single) of object;
  TKMScriptCmdProcIBIU = procedure(aIndex: Integer; aP1: Integer; aP2: Boolean; aP3: Integer; aP4: String) of object;
  TKMScriptCmdProcIBS  = procedure(aIndex: Integer; aP1: Integer; aP2: Boolean; aP3: Single) of object;
  TKMScriptCmdProcIBSB = procedure(aIndex: Integer; aP1: Integer; aP2: Boolean; aP3: Single; aP4: Boolean) of object;
  TKMScriptCmdProcIBSI = procedure(aIndex: Integer; aP1: Integer; aP2: Boolean; aP3: Single; aP4: Integer) of object;
  TKMScriptCmdProcIBSS = procedure(aIndex: Integer; aP1: Integer; aP2: Boolean; aP3: Single; aP4: Single) of object;
  TKMScriptCmdProcIBSU = procedure(aIndex: Integer; aP1: Integer; aP2: Boolean; aP3: Single; aP4: String) of object;
  TKMScriptCmdProcIBU  = procedure(aIndex: Integer; aP1: Integer; aP2: Boolean; aP3: String) of object;
  TKMScriptCmdProcIBUB = procedure(aIndex: Integer; aP1: Integer; aP2: Boolean; aP3: String; aP4: Boolean) of object;
  TKMScriptCmdProcIBUI = procedure(aIndex: Integer; aP1: Integer; aP2: Boolean; aP3: String; aP4: Integer) of object;
  TKMScriptCmdProcIBUS = procedure(aIndex: Integer; aP1: Integer; aP2: Boolean; aP3: String; aP4: Single) of object;
  TKMScriptCmdProcIBUU = procedure(aIndex: Integer; aP1: Integer; aP2: Boolean; aP3: String; aP4: String) of object;
  TKMScriptCmdProcII   = procedure(aIndex: Integer; aP1: Integer; aP2: Integer) of object;
  TKMScriptCmdProcIIB  = procedure(aIndex: Integer; aP1: Integer; aP2: Integer; aP3: Boolean) of object;
  TKMScriptCmdProcIIBB = procedure(aIndex: Integer; aP1: Integer; aP2: Integer; aP3: Boolean; aP4: Boolean) of object;
  TKMScriptCmdProcIIBI = procedure(aIndex: Integer; aP1: Integer; aP2: Integer; aP3: Boolean; aP4: Integer) of object;
  TKMScriptCmdProcIIBS = procedure(aIndex: Integer; aP1: Integer; aP2: Integer; aP3: Boolean; aP4: Single) of object;
  TKMScriptCmdProcIIBU = procedure(aIndex: Integer; aP1: Integer; aP2: Integer; aP3: Boolean; aP4: String) of object;
  TKMScriptCmdProcIII  = procedure(aIndex: Integer; aP1: Integer; aP2: Integer; aP3: Integer) of object;
  TKMScriptCmdProcIIIB = procedure(aIndex: Integer; aP1: Integer; aP2: Integer; aP3: Integer; aP4: Boolean) of object;
  TKMScriptCmdProcIIII = procedure(aIndex: Integer; aP1: Integer; aP2: Integer; aP3: Integer; aP4: Integer) of object;
  TKMScriptCmdProcIIIS = procedure(aIndex: Integer; aP1: Integer; aP2: Integer; aP3: Integer; aP4: Single) of object;
  TKMScriptCmdProcIIIU = procedure(aIndex: Integer; aP1: Integer; aP2: Integer; aP3: Integer; aP4: String) of object;
  TKMScriptCmdProcIIS  = procedure(aIndex: Integer; aP1: Integer; aP2: Integer; aP3: Single) of object;
  TKMScriptCmdProcIISB = procedure(aIndex: Integer; aP1: Integer; aP2: Integer; aP3: Single; aP4: Boolean) of object;
  TKMScriptCmdProcIISI = procedure(aIndex: Integer; aP1: Integer; aP2: Integer; aP3: Single; aP4: Integer) of object;
  TKMScriptCmdProcIISS = procedure(aIndex: Integer; aP1: Integer; aP2: Integer; aP3: Single; aP4: Single) of object;
  TKMScriptCmdProcIISU = procedure(aIndex: Integer; aP1: Integer; aP2: Integer; aP3: Single; aP4: String) of object;
  TKMScriptCmdProcIIU  = procedure(aIndex: Integer; aP1: Integer; aP2: Integer; aP3: String) of object;
  TKMScriptCmdProcIIUB = procedure(aIndex: Integer; aP1: Integer; aP2: Integer; aP3: String; aP4: Boolean) of object;
  TKMScriptCmdProcIIUI = procedure(aIndex: Integer; aP1: Integer; aP2: Integer; aP3: String; aP4: Integer) of object;
  TKMScriptCmdProcIIUS = procedure(aIndex: Integer; aP1: Integer; aP2: Integer; aP3: String; aP4: Single) of object;
  TKMScriptCmdProcIIUU = procedure(aIndex: Integer; aP1: Integer; aP2: Integer; aP3: String; aP4: String) of object;
  TKMScriptCmdProcIS   = procedure(aIndex: Integer; aP1: Integer; aP2: Single) of object;
  TKMScriptCmdProcISB  = procedure(aIndex: Integer; aP1: Integer; aP2: Single; aP3: Boolean) of object;
  TKMScriptCmdProcISBB = procedure(aIndex: Integer; aP1: Integer; aP2: Single; aP3: Boolean; aP4: Boolean) of object;
  TKMScriptCmdProcISBI = procedure(aIndex: Integer; aP1: Integer; aP2: Single; aP3: Boolean; aP4: Integer) of object;
  TKMScriptCmdProcISBS = procedure(aIndex: Integer; aP1: Integer; aP2: Single; aP3: Boolean; aP4: Single) of object;
  TKMScriptCmdProcISBU = procedure(aIndex: Integer; aP1: Integer; aP2: Single; aP3: Boolean; aP4: String) of object;
  TKMScriptCmdProcISI  = procedure(aIndex: Integer; aP1: Integer; aP2: Single; aP3: Integer) of object;
  TKMScriptCmdProcISIB = procedure(aIndex: Integer; aP1: Integer; aP2: Single; aP3: Integer; aP4: Boolean) of object;
  TKMScriptCmdProcISII = procedure(aIndex: Integer; aP1: Integer; aP2: Single; aP3: Integer; aP4: Integer) of object;
  TKMScriptCmdProcISIS = procedure(aIndex: Integer; aP1: Integer; aP2: Single; aP3: Integer; aP4: Single) of object;
  TKMScriptCmdProcISIU = procedure(aIndex: Integer; aP1: Integer; aP2: Single; aP3: Integer; aP4: String) of object;
  TKMScriptCmdProcISS  = procedure(aIndex: Integer; aP1: Integer; aP2: Single; aP3: Single) of object;
  TKMScriptCmdProcISSB = procedure(aIndex: Integer; aP1: Integer; aP2: Single; aP3: Single; aP4: Boolean) of object;
  TKMScriptCmdProcISSI = procedure(aIndex: Integer; aP1: Integer; aP2: Single; aP3: Single; aP4: Integer) of object;
  TKMScriptCmdProcISSS = procedure(aIndex: Integer; aP1: Integer; aP2: Single; aP3: Single; aP4: Single) of object;
  TKMScriptCmdProcISSU = procedure(aIndex: Integer; aP1: Integer; aP2: Single; aP3: Single; aP4: String) of object;
  TKMScriptCmdProcISU  = procedure(aIndex: Integer; aP1: Integer; aP2: Single; aP3: String) of object;
  TKMScriptCmdProcISUB = procedure(aIndex: Integer; aP1: Integer; aP2: Single; aP3: String; aP4: Boolean) of object;
  TKMScriptCmdProcISUI = procedure(aIndex: Integer; aP1: Integer; aP2: Single; aP3: String; aP4: Integer) of object;
  TKMScriptCmdProcISUS = procedure(aIndex: Integer; aP1: Integer; aP2: Single; aP3: String; aP4: Single) of object;
  TKMScriptCmdProcISUU = procedure(aIndex: Integer; aP1: Integer; aP2: Single; aP3: String; aP4: String) of object;
  TKMScriptCmdProcIU   = procedure(aIndex: Integer; aP1: Integer; aP2: String) of object;
  TKMScriptCmdProcIUB  = procedure(aIndex: Integer; aP1: Integer; aP2: String; aP3: Boolean) of object;
  TKMScriptCmdProcIUBB = procedure(aIndex: Integer; aP1: Integer; aP2: String; aP3: Boolean; aP4: Boolean) of object;
  TKMScriptCmdProcIUBI = procedure(aIndex: Integer; aP1: Integer; aP2: String; aP3: Boolean; aP4: Integer) of object;
  TKMScriptCmdProcIUBS = procedure(aIndex: Integer; aP1: Integer; aP2: String; aP3: Boolean; aP4: Single) of object;
  TKMScriptCmdProcIUBU = procedure(aIndex: Integer; aP1: Integer; aP2: String; aP3: Boolean; aP4: String) of object;
  TKMScriptCmdProcIUI  = procedure(aIndex: Integer; aP1: Integer; aP2: String; aP3: Integer) of object;
  TKMScriptCmdProcIUIB = procedure(aIndex: Integer; aP1: Integer; aP2: String; aP3: Integer; aP4: Boolean) of object;
  TKMScriptCmdProcIUII = procedure(aIndex: Integer; aP1: Integer; aP2: String; aP3: Integer; aP4: Integer) of object;
  TKMScriptCmdProcIUIS = procedure(aIndex: Integer; aP1: Integer; aP2: String; aP3: Integer; aP4: Single) of object;
  TKMScriptCmdProcIUIU = procedure(aIndex: Integer; aP1: Integer; aP2: String; aP3: Integer; aP4: String) of object;
  TKMScriptCmdProcIUS  = procedure(aIndex: Integer; aP1: Integer; aP2: String; aP3: Single) of object;
  TKMScriptCmdProcIUSB = procedure(aIndex: Integer; aP1: Integer; aP2: String; aP3: Single; aP4: Boolean) of object;
  TKMScriptCmdProcIUSI = procedure(aIndex: Integer; aP1: Integer; aP2: String; aP3: Single; aP4: Integer) of object;
  TKMScriptCmdProcIUSS = procedure(aIndex: Integer; aP1: Integer; aP2: String; aP3: Single; aP4: Single) of object;
  TKMScriptCmdProcIUSU = procedure(aIndex: Integer; aP1: Integer; aP2: String; aP3: Single; aP4: String) of object;
  TKMScriptCmdProcIUU  = procedure(aIndex: Integer; aP1: Integer; aP2: String; aP3: String) of object;
  TKMScriptCmdProcIUUB = procedure(aIndex: Integer; aP1: Integer; aP2: String; aP3: String; aP4: Boolean) of object;
  TKMScriptCmdProcIUUI = procedure(aIndex: Integer; aP1: Integer; aP2: String; aP3: String; aP4: Integer) of object;
  TKMScriptCmdProcIUUS = procedure(aIndex: Integer; aP1: Integer; aP2: String; aP3: String; aP4: Single) of object;
  TKMScriptCmdProcIUUU = procedure(aIndex: Integer; aP1: Integer; aP2: String; aP3: String; aP4: String) of object;
  TKMScriptCmdProcS    = procedure(aIndex: Integer; aP1: Single) of object;
  TKMScriptCmdProcSB   = procedure(aIndex: Integer; aP1: Single; aP2: Boolean) of object;
  TKMScriptCmdProcSBB  = procedure(aIndex: Integer; aP1: Single; aP2: Boolean; aP3: Boolean) of object;
  TKMScriptCmdProcSBBB = procedure(aIndex: Integer; aP1: Single; aP2: Boolean; aP3: Boolean; aP4: Boolean) of object;
  TKMScriptCmdProcSBBI = procedure(aIndex: Integer; aP1: Single; aP2: Boolean; aP3: Boolean; aP4: Integer) of object;
  TKMScriptCmdProcSBBS = procedure(aIndex: Integer; aP1: Single; aP2: Boolean; aP3: Boolean; aP4: Single) of object;
  TKMScriptCmdProcSBBU = procedure(aIndex: Integer; aP1: Single; aP2: Boolean; aP3: Boolean; aP4: String) of object;
  TKMScriptCmdProcSBI  = procedure(aIndex: Integer; aP1: Single; aP2: Boolean; aP3: Integer) of object;
  TKMScriptCmdProcSBIB = procedure(aIndex: Integer; aP1: Single; aP2: Boolean; aP3: Integer; aP4: Boolean) of object;
  TKMScriptCmdProcSBII = procedure(aIndex: Integer; aP1: Single; aP2: Boolean; aP3: Integer; aP4: Integer) of object;
  TKMScriptCmdProcSBIS = procedure(aIndex: Integer; aP1: Single; aP2: Boolean; aP3: Integer; aP4: Single) of object;
  TKMScriptCmdProcSBIU = procedure(aIndex: Integer; aP1: Single; aP2: Boolean; aP3: Integer; aP4: String) of object;
  TKMScriptCmdProcSBS  = procedure(aIndex: Integer; aP1: Single; aP2: Boolean; aP3: Single) of object;
  TKMScriptCmdProcSBSB = procedure(aIndex: Integer; aP1: Single; aP2: Boolean; aP3: Single; aP4: Boolean) of object;
  TKMScriptCmdProcSBSI = procedure(aIndex: Integer; aP1: Single; aP2: Boolean; aP3: Single; aP4: Integer) of object;
  TKMScriptCmdProcSBSS = procedure(aIndex: Integer; aP1: Single; aP2: Boolean; aP3: Single; aP4: Single) of object;
  TKMScriptCmdProcSBSU = procedure(aIndex: Integer; aP1: Single; aP2: Boolean; aP3: Single; aP4: String) of object;
  TKMScriptCmdProcSBU  = procedure(aIndex: Integer; aP1: Single; aP2: Boolean; aP3: String) of object;
  TKMScriptCmdProcSBUB = procedure(aIndex: Integer; aP1: Single; aP2: Boolean; aP3: String; aP4: Boolean) of object;
  TKMScriptCmdProcSBUI = procedure(aIndex: Integer; aP1: Single; aP2: Boolean; aP3: String; aP4: Integer) of object;
  TKMScriptCmdProcSBUS = procedure(aIndex: Integer; aP1: Single; aP2: Boolean; aP3: String; aP4: Single) of object;
  TKMScriptCmdProcSBUU = procedure(aIndex: Integer; aP1: Single; aP2: Boolean; aP3: String; aP4: String) of object;
  TKMScriptCmdProcSI   = procedure(aIndex: Integer; aP1: Single; aP2: Integer) of object;
  TKMScriptCmdProcSIB  = procedure(aIndex: Integer; aP1: Single; aP2: Integer; aP3: Boolean) of object;
  TKMScriptCmdProcSIBB = procedure(aIndex: Integer; aP1: Single; aP2: Integer; aP3: Boolean; aP4: Boolean) of object;
  TKMScriptCmdProcSIBI = procedure(aIndex: Integer; aP1: Single; aP2: Integer; aP3: Boolean; aP4: Integer) of object;
  TKMScriptCmdProcSIBS = procedure(aIndex: Integer; aP1: Single; aP2: Integer; aP3: Boolean; aP4: Single) of object;
  TKMScriptCmdProcSIBU = procedure(aIndex: Integer; aP1: Single; aP2: Integer; aP3: Boolean; aP4: String) of object;
  TKMScriptCmdProcSII  = procedure(aIndex: Integer; aP1: Single; aP2: Integer; aP3: Integer) of object;
  TKMScriptCmdProcSIIB = procedure(aIndex: Integer; aP1: Single; aP2: Integer; aP3: Integer; aP4: Boolean) of object;
  TKMScriptCmdProcSIII = procedure(aIndex: Integer; aP1: Single; aP2: Integer; aP3: Integer; aP4: Integer) of object;
  TKMScriptCmdProcSIIS = procedure(aIndex: Integer; aP1: Single; aP2: Integer; aP3: Integer; aP4: Single) of object;
  TKMScriptCmdProcSIIU = procedure(aIndex: Integer; aP1: Single; aP2: Integer; aP3: Integer; aP4: String) of object;
  TKMScriptCmdProcSIS  = procedure(aIndex: Integer; aP1: Single; aP2: Integer; aP3: Single) of object;
  TKMScriptCmdProcSISB = procedure(aIndex: Integer; aP1: Single; aP2: Integer; aP3: Single; aP4: Boolean) of object;
  TKMScriptCmdProcSISI = procedure(aIndex: Integer; aP1: Single; aP2: Integer; aP3: Single; aP4: Integer) of object;
  TKMScriptCmdProcSISS = procedure(aIndex: Integer; aP1: Single; aP2: Integer; aP3: Single; aP4: Single) of object;
  TKMScriptCmdProcSISU = procedure(aIndex: Integer; aP1: Single; aP2: Integer; aP3: Single; aP4: String) of object;
  TKMScriptCmdProcSIU  = procedure(aIndex: Integer; aP1: Single; aP2: Integer; aP3: String) of object;
  TKMScriptCmdProcSIUB = procedure(aIndex: Integer; aP1: Single; aP2: Integer; aP3: String; aP4: Boolean) of object;
  TKMScriptCmdProcSIUI = procedure(aIndex: Integer; aP1: Single; aP2: Integer; aP3: String; aP4: Integer) of object;
  TKMScriptCmdProcSIUS = procedure(aIndex: Integer; aP1: Single; aP2: Integer; aP3: String; aP4: Single) of object;
  TKMScriptCmdProcSIUU = procedure(aIndex: Integer; aP1: Single; aP2: Integer; aP3: String; aP4: String) of object;
  TKMScriptCmdProcSS   = procedure(aIndex: Integer; aP1: Single; aP2: Single) of object;
  TKMScriptCmdProcSSB  = procedure(aIndex: Integer; aP1: Single; aP2: Single; aP3: Boolean) of object;
  TKMScriptCmdProcSSBB = procedure(aIndex: Integer; aP1: Single; aP2: Single; aP3: Boolean; aP4: Boolean) of object;
  TKMScriptCmdProcSSBI = procedure(aIndex: Integer; aP1: Single; aP2: Single; aP3: Boolean; aP4: Integer) of object;
  TKMScriptCmdProcSSBS = procedure(aIndex: Integer; aP1: Single; aP2: Single; aP3: Boolean; aP4: Single) of object;
  TKMScriptCmdProcSSBU = procedure(aIndex: Integer; aP1: Single; aP2: Single; aP3: Boolean; aP4: String) of object;
  TKMScriptCmdProcSSI  = procedure(aIndex: Integer; aP1: Single; aP2: Single; aP3: Integer) of object;
  TKMScriptCmdProcSSIB = procedure(aIndex: Integer; aP1: Single; aP2: Single; aP3: Integer; aP4: Boolean) of object;
  TKMScriptCmdProcSSII = procedure(aIndex: Integer; aP1: Single; aP2: Single; aP3: Integer; aP4: Integer) of object;
  TKMScriptCmdProcSSIS = procedure(aIndex: Integer; aP1: Single; aP2: Single; aP3: Integer; aP4: Single) of object;
  TKMScriptCmdProcSSIU = procedure(aIndex: Integer; aP1: Single; aP2: Single; aP3: Integer; aP4: String) of object;
  TKMScriptCmdProcSSS  = procedure(aIndex: Integer; aP1: Single; aP2: Single; aP3: Single) of object;
  TKMScriptCmdProcSSSB = procedure(aIndex: Integer; aP1: Single; aP2: Single; aP3: Single; aP4: Boolean) of object;
  TKMScriptCmdProcSSSI = procedure(aIndex: Integer; aP1: Single; aP2: Single; aP3: Single; aP4: Integer) of object;
  TKMScriptCmdProcSSSS = procedure(aIndex: Integer; aP1: Single; aP2: Single; aP3: Single; aP4: Single) of object;
  TKMScriptCmdProcSSSU = procedure(aIndex: Integer; aP1: Single; aP2: Single; aP3: Single; aP4: String) of object;
  TKMScriptCmdProcSSU  = procedure(aIndex: Integer; aP1: Single; aP2: Single; aP3: String) of object;
  TKMScriptCmdProcSSUB = procedure(aIndex: Integer; aP1: Single; aP2: Single; aP3: String; aP4: Boolean) of object;
  TKMScriptCmdProcSSUI = procedure(aIndex: Integer; aP1: Single; aP2: Single; aP3: String; aP4: Integer) of object;
  TKMScriptCmdProcSSUS = procedure(aIndex: Integer; aP1: Single; aP2: Single; aP3: String; aP4: Single) of object;
  TKMScriptCmdProcSSUU = procedure(aIndex: Integer; aP1: Single; aP2: Single; aP3: String; aP4: String) of object;
  TKMScriptCmdProcSU   = procedure(aIndex: Integer; aP1: Single; aP2: String) of object;
  TKMScriptCmdProcSUB  = procedure(aIndex: Integer; aP1: Single; aP2: String; aP3: Boolean) of object;
  TKMScriptCmdProcSUBB = procedure(aIndex: Integer; aP1: Single; aP2: String; aP3: Boolean; aP4: Boolean) of object;
  TKMScriptCmdProcSUBI = procedure(aIndex: Integer; aP1: Single; aP2: String; aP3: Boolean; aP4: Integer) of object;
  TKMScriptCmdProcSUBS = procedure(aIndex: Integer; aP1: Single; aP2: String; aP3: Boolean; aP4: Single) of object;
  TKMScriptCmdProcSUBU = procedure(aIndex: Integer; aP1: Single; aP2: String; aP3: Boolean; aP4: String) of object;
  TKMScriptCmdProcSUI  = procedure(aIndex: Integer; aP1: Single; aP2: String; aP3: Integer) of object;
  TKMScriptCmdProcSUIB = procedure(aIndex: Integer; aP1: Single; aP2: String; aP3: Integer; aP4: Boolean) of object;
  TKMScriptCmdProcSUII = procedure(aIndex: Integer; aP1: Single; aP2: String; aP3: Integer; aP4: Integer) of object;
  TKMScriptCmdProcSUIS = procedure(aIndex: Integer; aP1: Single; aP2: String; aP3: Integer; aP4: Single) of object;
  TKMScriptCmdProcSUIU = procedure(aIndex: Integer; aP1: Single; aP2: String; aP3: Integer; aP4: String) of object;
  TKMScriptCmdProcSUS  = procedure(aIndex: Integer; aP1: Single; aP2: String; aP3: Single) of object;
  TKMScriptCmdProcSUSB = procedure(aIndex: Integer; aP1: Single; aP2: String; aP3: Single; aP4: Boolean) of object;
  TKMScriptCmdProcSUSI = procedure(aIndex: Integer; aP1: Single; aP2: String; aP3: Single; aP4: Integer) of object;
  TKMScriptCmdProcSUSS = procedure(aIndex: Integer; aP1: Single; aP2: String; aP3: Single; aP4: Single) of object;
  TKMScriptCmdProcSUSU = procedure(aIndex: Integer; aP1: Single; aP2: String; aP3: Single; aP4: String) of object;
  TKMScriptCmdProcSUU  = procedure(aIndex: Integer; aP1: Single; aP2: String; aP3: String) of object;
  TKMScriptCmdProcSUUB = procedure(aIndex: Integer; aP1: Single; aP2: String; aP3: String; aP4: Boolean) of object;
  TKMScriptCmdProcSUUI = procedure(aIndex: Integer; aP1: Single; aP2: String; aP3: String; aP4: Integer) of object;
  TKMScriptCmdProcSUUS = procedure(aIndex: Integer; aP1: Single; aP2: String; aP3: String; aP4: Single) of object;
  TKMScriptCmdProcSUUU = procedure(aIndex: Integer; aP1: Single; aP2: String; aP3: String; aP4: String) of object;
  TKMScriptCmdProcU    = procedure(aIndex: Integer; aP1: String) of object;
  TKMScriptCmdProcUB   = procedure(aIndex: Integer; aP1: String; aP2: Boolean) of object;
  TKMScriptCmdProcUBB  = procedure(aIndex: Integer; aP1: String; aP2: Boolean; aP3: Boolean) of object;
  TKMScriptCmdProcUBBB = procedure(aIndex: Integer; aP1: String; aP2: Boolean; aP3: Boolean; aP4: Boolean) of object;
  TKMScriptCmdProcUBBI = procedure(aIndex: Integer; aP1: String; aP2: Boolean; aP3: Boolean; aP4: Integer) of object;
  TKMScriptCmdProcUBBS = procedure(aIndex: Integer; aP1: String; aP2: Boolean; aP3: Boolean; aP4: Single) of object;
  TKMScriptCmdProcUBBU = procedure(aIndex: Integer; aP1: String; aP2: Boolean; aP3: Boolean; aP4: String) of object;
  TKMScriptCmdProcUBI  = procedure(aIndex: Integer; aP1: String; aP2: Boolean; aP3: Integer) of object;
  TKMScriptCmdProcUBIB = procedure(aIndex: Integer; aP1: String; aP2: Boolean; aP3: Integer; aP4: Boolean) of object;
  TKMScriptCmdProcUBII = procedure(aIndex: Integer; aP1: String; aP2: Boolean; aP3: Integer; aP4: Integer) of object;
  TKMScriptCmdProcUBIS = procedure(aIndex: Integer; aP1: String; aP2: Boolean; aP3: Integer; aP4: Single) of object;
  TKMScriptCmdProcUBIU = procedure(aIndex: Integer; aP1: String; aP2: Boolean; aP3: Integer; aP4: String) of object;
  TKMScriptCmdProcUBS  = procedure(aIndex: Integer; aP1: String; aP2: Boolean; aP3: Single) of object;
  TKMScriptCmdProcUBSB = procedure(aIndex: Integer; aP1: String; aP2: Boolean; aP3: Single; aP4: Boolean) of object;
  TKMScriptCmdProcUBSI = procedure(aIndex: Integer; aP1: String; aP2: Boolean; aP3: Single; aP4: Integer) of object;
  TKMScriptCmdProcUBSS = procedure(aIndex: Integer; aP1: String; aP2: Boolean; aP3: Single; aP4: Single) of object;
  TKMScriptCmdProcUBSU = procedure(aIndex: Integer; aP1: String; aP2: Boolean; aP3: Single; aP4: String) of object;
  TKMScriptCmdProcUBU  = procedure(aIndex: Integer; aP1: String; aP2: Boolean; aP3: String) of object;
  TKMScriptCmdProcUBUB = procedure(aIndex: Integer; aP1: String; aP2: Boolean; aP3: String; aP4: Boolean) of object;
  TKMScriptCmdProcUBUI = procedure(aIndex: Integer; aP1: String; aP2: Boolean; aP3: String; aP4: Integer) of object;
  TKMScriptCmdProcUBUS = procedure(aIndex: Integer; aP1: String; aP2: Boolean; aP3: String; aP4: Single) of object;
  TKMScriptCmdProcUBUU = procedure(aIndex: Integer; aP1: String; aP2: Boolean; aP3: String; aP4: String) of object;
  TKMScriptCmdProcUI   = procedure(aIndex: Integer; aP1: String; aP2: Integer) of object;
  TKMScriptCmdProcUIB  = procedure(aIndex: Integer; aP1: String; aP2: Integer; aP3: Boolean) of object;
  TKMScriptCmdProcUIBB = procedure(aIndex: Integer; aP1: String; aP2: Integer; aP3: Boolean; aP4: Boolean) of object;
  TKMScriptCmdProcUIBI = procedure(aIndex: Integer; aP1: String; aP2: Integer; aP3: Boolean; aP4: Integer) of object;
  TKMScriptCmdProcUIBS = procedure(aIndex: Integer; aP1: String; aP2: Integer; aP3: Boolean; aP4: Single) of object;
  TKMScriptCmdProcUIBU = procedure(aIndex: Integer; aP1: String; aP2: Integer; aP3: Boolean; aP4: String) of object;
  TKMScriptCmdProcUII  = procedure(aIndex: Integer; aP1: String; aP2: Integer; aP3: Integer) of object;
  TKMScriptCmdProcUIIB = procedure(aIndex: Integer; aP1: String; aP2: Integer; aP3: Integer; aP4: Boolean) of object;
  TKMScriptCmdProcUIII = procedure(aIndex: Integer; aP1: String; aP2: Integer; aP3: Integer; aP4: Integer) of object;
  TKMScriptCmdProcUIIS = procedure(aIndex: Integer; aP1: String; aP2: Integer; aP3: Integer; aP4: Single) of object;
  TKMScriptCmdProcUIIU = procedure(aIndex: Integer; aP1: String; aP2: Integer; aP3: Integer; aP4: String) of object;
  TKMScriptCmdProcUIS  = procedure(aIndex: Integer; aP1: String; aP2: Integer; aP3: Single) of object;
  TKMScriptCmdProcUISB = procedure(aIndex: Integer; aP1: String; aP2: Integer; aP3: Single; aP4: Boolean) of object;
  TKMScriptCmdProcUISI = procedure(aIndex: Integer; aP1: String; aP2: Integer; aP3: Single; aP4: Integer) of object;
  TKMScriptCmdProcUISS = procedure(aIndex: Integer; aP1: String; aP2: Integer; aP3: Single; aP4: Single) of object;
  TKMScriptCmdProcUISU = procedure(aIndex: Integer; aP1: String; aP2: Integer; aP3: Single; aP4: String) of object;
  TKMScriptCmdProcUIU  = procedure(aIndex: Integer; aP1: String; aP2: Integer; aP3: String) of object;
  TKMScriptCmdProcUIUB = procedure(aIndex: Integer; aP1: String; aP2: Integer; aP3: String; aP4: Boolean) of object;
  TKMScriptCmdProcUIUI = procedure(aIndex: Integer; aP1: String; aP2: Integer; aP3: String; aP4: Integer) of object;
  TKMScriptCmdProcUIUS = procedure(aIndex: Integer; aP1: String; aP2: Integer; aP3: String; aP4: Single) of object;
  TKMScriptCmdProcUIUU = procedure(aIndex: Integer; aP1: String; aP2: Integer; aP3: String; aP4: String) of object;
  TKMScriptCmdProcUS   = procedure(aIndex: Integer; aP1: String; aP2: Single) of object;
  TKMScriptCmdProcUSB  = procedure(aIndex: Integer; aP1: String; aP2: Single; aP3: Boolean) of object;
  TKMScriptCmdProcUSBB = procedure(aIndex: Integer; aP1: String; aP2: Single; aP3: Boolean; aP4: Boolean) of object;
  TKMScriptCmdProcUSBI = procedure(aIndex: Integer; aP1: String; aP2: Single; aP3: Boolean; aP4: Integer) of object;
  TKMScriptCmdProcUSBS = procedure(aIndex: Integer; aP1: String; aP2: Single; aP3: Boolean; aP4: Single) of object;
  TKMScriptCmdProcUSBU = procedure(aIndex: Integer; aP1: String; aP2: Single; aP3: Boolean; aP4: String) of object;
  TKMScriptCmdProcUSI  = procedure(aIndex: Integer; aP1: String; aP2: Single; aP3: Integer) of object;
  TKMScriptCmdProcUSIB = procedure(aIndex: Integer; aP1: String; aP2: Single; aP3: Integer; aP4: Boolean) of object;
  TKMScriptCmdProcUSII = procedure(aIndex: Integer; aP1: String; aP2: Single; aP3: Integer; aP4: Integer) of object;
  TKMScriptCmdProcUSIS = procedure(aIndex: Integer; aP1: String; aP2: Single; aP3: Integer; aP4: Single) of object;
  TKMScriptCmdProcUSIU = procedure(aIndex: Integer; aP1: String; aP2: Single; aP3: Integer; aP4: String) of object;
  TKMScriptCmdProcUSS  = procedure(aIndex: Integer; aP1: String; aP2: Single; aP3: Single) of object;
  TKMScriptCmdProcUSSB = procedure(aIndex: Integer; aP1: String; aP2: Single; aP3: Single; aP4: Boolean) of object;
  TKMScriptCmdProcUSSI = procedure(aIndex: Integer; aP1: String; aP2: Single; aP3: Single; aP4: Integer) of object;
  TKMScriptCmdProcUSSS = procedure(aIndex: Integer; aP1: String; aP2: Single; aP3: Single; aP4: Single) of object;
  TKMScriptCmdProcUSSU = procedure(aIndex: Integer; aP1: String; aP2: Single; aP3: Single; aP4: String) of object;
  TKMScriptCmdProcUSU  = procedure(aIndex: Integer; aP1: String; aP2: Single; aP3: String) of object;
  TKMScriptCmdProcUSUB = procedure(aIndex: Integer; aP1: String; aP2: Single; aP3: String; aP4: Boolean) of object;
  TKMScriptCmdProcUSUI = procedure(aIndex: Integer; aP1: String; aP2: Single; aP3: String; aP4: Integer) of object;
  TKMScriptCmdProcUSUS = procedure(aIndex: Integer; aP1: String; aP2: Single; aP3: String; aP4: Single) of object;
  TKMScriptCmdProcUSUU = procedure(aIndex: Integer; aP1: String; aP2: Single; aP3: String; aP4: String) of object;
  TKMScriptCmdProcUU   = procedure(aIndex: Integer; aP1: String; aP2: String) of object;
  TKMScriptCmdProcUUB  = procedure(aIndex: Integer; aP1: String; aP2: String; aP3: Boolean) of object;
  TKMScriptCmdProcUUBB = procedure(aIndex: Integer; aP1: String; aP2: String; aP3: Boolean; aP4: Boolean) of object;
  TKMScriptCmdProcUUBI = procedure(aIndex: Integer; aP1: String; aP2: String; aP3: Boolean; aP4: Integer) of object;
  TKMScriptCmdProcUUBS = procedure(aIndex: Integer; aP1: String; aP2: String; aP3: Boolean; aP4: Single) of object;
  TKMScriptCmdProcUUBU = procedure(aIndex: Integer; aP1: String; aP2: String; aP3: Boolean; aP4: String) of object;
  TKMScriptCmdProcUUI  = procedure(aIndex: Integer; aP1: String; aP2: String; aP3: Integer) of object;
  TKMScriptCmdProcUUIB = procedure(aIndex: Integer; aP1: String; aP2: String; aP3: Integer; aP4: Boolean) of object;
  TKMScriptCmdProcUUII = procedure(aIndex: Integer; aP1: String; aP2: String; aP3: Integer; aP4: Integer) of object;
  TKMScriptCmdProcUUIS = procedure(aIndex: Integer; aP1: String; aP2: String; aP3: Integer; aP4: Single) of object;
  TKMScriptCmdProcUUIU = procedure(aIndex: Integer; aP1: String; aP2: String; aP3: Integer; aP4: String) of object;
  TKMScriptCmdProcUUS  = procedure(aIndex: Integer; aP1: String; aP2: String; aP3: Single) of object;
  TKMScriptCmdProcUUSB = procedure(aIndex: Integer; aP1: String; aP2: String; aP3: Single; aP4: Boolean) of object;
  TKMScriptCmdProcUUSI = procedure(aIndex: Integer; aP1: String; aP2: String; aP3: Single; aP4: Integer) of object;
  TKMScriptCmdProcUUSS = procedure(aIndex: Integer; aP1: String; aP2: String; aP3: Single; aP4: Single) of object;
  TKMScriptCmdProcUUSU = procedure(aIndex: Integer; aP1: String; aP2: String; aP3: Single; aP4: String) of object;
  TKMScriptCmdProcUUU  = procedure(aIndex: Integer; aP1: String; aP2: String; aP3: String) of object;
  TKMScriptCmdProcUUUB = procedure(aIndex: Integer; aP1: String; aP2: String; aP3: String; aP4: Boolean) of object;
  TKMScriptCmdProcUUUI = procedure(aIndex: Integer; aP1: String; aP2: String; aP3: String; aP4: Integer) of object;
  TKMScriptCmdProcUUUS = procedure(aIndex: Integer; aP1: String; aP2: String; aP3: String; aP4: Single) of object;
  TKMScriptCmdProcUUUU = procedure(aIndex: Integer; aP1: String; aP2: String; aP3: String; aP4: String) of object;


{ EConsoleCommandParseError }
constructor EConsoleCommandParseError.Create(const aErrorMsg: String);
begin
  Create(aErrorMsg, 0, 0, '');
end;


constructor EConsoleCommandParseError.Create(const aErrorMsg: String; aRow, aCol: Integer; const aToken: String);
begin
  inherited Create(aErrorMsg);

  Row := aRow;
  Col := aCol;
  Token := aToken;
end;


{ TKMConsoleCommand }
constructor TKMConsoleCommand.Create;
begin
  Create('', '', [cpkNone,cpkNone,cpkNone,cpkNone]);
end;


constructor TKMConsoleCommand.Create(const aName, aProcName: AnsiString);
begin
  Create(aName, aProcName, [cpkNone,cpkNone,cpkNone,cpkNone]);
end;


constructor TKMConsoleCommand.Create(const aName, aProcName: AnsiString; const aParamTypes: array of TKMCmdProcParamTypeKind);
var
  I: Integer;
begin
  inherited Create;

  Assert(Length(aParamTypes) = MAX_SCRIPT_CONSOLE_COMMAND_PARAMS, 'Wrong console command params number');

  fName := aName;
  fProcName := aProcName;

  for I := 0 to MAX_SCRIPT_CONSOLE_COMMAND_PARAMS - 1 do
    fPT[I] := aParamTypes[I];

end;


function TKMConsoleCommand.GetProcParamsCnt: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to MAX_SCRIPT_CONSOLE_COMMAND_PARAMS - 1 do
    if fPT[I] <> cpkNone then
      Inc(Result)
    else
      Break;
end;


function TKMConsoleCommand.GetProcParamType(aIndex: Integer): TKMCmdProcParamTypeKind;
begin
  Result := fPT[aIndex];
end;


function TKMConsoleCommand.P2B(const aParam: String): Boolean;
begin
  Result := StrToBool(aParam);
end;

function TKMConsoleCommand.P2I(const aParam: String): Integer;
begin
  Result := StrToInt(aParam);
end;

function TKMConsoleCommand.P2S(const aParam: String): Single;
begin
  Result := StrToFloat(aParam, gSingleDotFormat);
end;

function TKMConsoleCommand.P2U(const aParam: String): String;
begin
  Result := aParam;
end;


function TKMConsoleCommand.Params2String(const aParams: TKMScriptCommandParamsArray; aColorfull: Boolean = True): String;
var
  I: Integer;
  Str: String;
begin
  Result := '';
  for I := 0 to MAX_SCRIPT_CONSOLE_COMMAND_PARAMS - 1 do
  begin
    if aParams[I] = '' then
      Continue;

    if I > 0 then
      Result := Result + ',';

    if aColorfull then
      Str := WrapColor(aParams[I], clScriptCmdParam)
    else
      Str := aParams[I];

    Result := Result + Str;
  end;
end;


function TKMConsoleCommand.ParamsTypes2String(aColorfull: Boolean = True): String;
var
  I: Integer;
  Str: String;
begin
  Result := '';
  for I := 0 to MAX_SCRIPT_CONSOLE_COMMAND_PARAMS - 1 do
    if fPT[I] <> cpkNone then
    begin
      if I > 0 then
        Result := Result + ',';

      if aColorfull then
        Str := WrapColor(CLASS_TYPE_STR[fPT[I]], clScriptCmdParam)
      else
        Str := CLASS_TYPE_STR[fPT[I]];

      Result := Result + Str;
    end;
end;


function TKMConsoleCommand.ParseParameters(const aProcedureStr: String; aRow: Integer): Boolean;
//Use const for ScriptValidator. We do not want to load txt libraries for it since it could be placed anywhere
const
  TX_SCRIPT_CONSOLE_CMD_TOO_MANY_PROC_PARAMS_STR =
    'Too many parameters for script command /%s: [ %s ]. Max number of parameters is [%s] (including mandatory HandID parameter)';
  TX_SCRIPT_CONSOLE_CMD_WRONG_PARAM_TYPE_STR = 'Wrong parameter type for script command /%s: [ %s ]';
  TX_SCRIPT_CONSOLE_CMD_WRONG_1ST_PARAM_TYPE_STR =
    'Wrong first parameter type for script command /%s. Expected: [ %s ], actual: [ %s ]';
var
  Method: TKMMethod;
  I: Integer;
  ParamKind: TKMCmdProcParamTypeKind;

  function GetErrorStr(aTextID: Word): String;
  begin
    if gResTexts <> nil then
      Result := gResTexts[aTextID]
    else
      case aTextID of
        TX_SCRIPT_CONSOLE_CMD_TOO_MANY_PROC_PARAMS: Result := TX_SCRIPT_CONSOLE_CMD_TOO_MANY_PROC_PARAMS_STR;
        TX_SCRIPT_CONSOLE_CMD_WRONG_PARAM_TYPE: Result := TX_SCRIPT_CONSOLE_CMD_WRONG_PARAM_TYPE_STR;
        TX_SCRIPT_CONSOLE_CMD_WRONG_1ST_PARAM_TYPE: Result := TX_SCRIPT_CONSOLE_CMD_WRONG_1ST_PARAM_TYPE_STR;
      end;
  end;

  function GetCommandType(const aStr: String): TKMCmdProcParamTypeKind;
  var
    PTK: TKMCmdProcParamTypeKind;
  begin
    Result := cpkNone;
    for PTK := cpkBool to High(TKMCmdProcParamTypeKind) do
      if UpperCase(CLASS_TYPE_STR[PTK]) = UpperCase(aStr) then
        Result := PTK;
  end;

begin
  Method := TKMMethod.ParseMethodStr(aProcedureStr);
  try
    if Method.Params.Count > MAX_SCRIPT_CONSOLE_COMMAND_PARAMS + 1 then //+1 for HandID parameter
      raise EConsoleCommandParseError.Create(Format(GetErrorStr(TX_SCRIPT_CONSOLE_CMD_TOO_MANY_PROC_PARAMS),
                                                      [fName,
                                                       IntToStr(Method.Params.Count),
                                                       IntToStr(MAX_SCRIPT_CONSOLE_COMMAND_PARAMS + 1)]),
                                             aRow, 0, aProcedureStr);

    for I := 0 to Method.Params.Count - 1 do
    begin
      ParamKind := GetCommandType(Method.Params[I].ParamType);
      //Check if parameter type is valid
      if ParamKind = cpkNone then
        raise EConsoleCommandParseError.Create(Format(GetErrorStr(TX_SCRIPT_CONSOLE_CMD_WRONG_PARAM_TYPE),
                                                      [fName, Method.Params[I].ParamType]),
                                               aRow, 0, aProcedureStr);
      //1st parameter should be always Integer
      if (I = 0) and (ParamKind <> cpkIntg) then
        raise EConsoleCommandParseError.Create(Format(GetErrorStr(TX_SCRIPT_CONSOLE_CMD_WRONG_1ST_PARAM_TYPE),
                                                      [fName,
                                                       CLASS_TYPE_STR[cpkIntg],
                                                       Method.Params[I].ParamType]),
                                               aRow, 0, aProcedureStr);
      if I > 0 then
        fPT[I - 1] := ParamKind;
    end;

  finally
    FreeAndNil(Method);
  end;

  Result := True;
end;


function TKMConsoleCommand.ValidateParams(const aParams: TKMScriptCommandParamsArray): Boolean;
var
  I, IVal: Integer;
  BVal: Boolean;
  SVal: Single;
begin
  Assert(Length(aParams) = MAX_SCRIPT_CONSOLE_COMMAND_PARAMS, 'Wrong number of parameters');

  Result := True;
  for I := 0 to MAX_SCRIPT_CONSOLE_COMMAND_PARAMS - 1 do
    case fPT[I] of
      cpkNone:  ;
      cpkBool:  Result := Result and TryStrToBool(aParams[I], BVal);
      cpkIntg:  Result := Result and TryStrToInt(aParams[I], IVal);
      cpkSngl:  Result := Result and TryStrToFloat(aParams[I], SVal, gSingleDotFormat);
      cpkUStr:  ;
    end;
end;


procedure TKMConsoleCommand.TryCallProcedure(aHandID: TKMHandID; const P: TKMScriptCommandParamsArray);
begin
  case fPT[0] of
    cpkUStr:  case fPT[1] of
                cpkUStr:  case fPT[2] of
                            cpkUStr:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcUUUU(Handler)(aHandId, P2U(P[0]), P2U(P[1]), P2U(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcUUUS(Handler)(aHandId, P2U(P[0]), P2U(P[1]), P2U(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcUUUI(Handler)(aHandId, P2U(P[0]), P2U(P[1]), P2U(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcUUUB(Handler)(aHandId, P2U(P[0]), P2U(P[1]), P2U(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcUUU(Handler)(aHandId, P2U(P[0]), P2U(P[1]), P2U(P[2]));
                                      end;
                            cpkSngl:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcUUSU(Handler)(aHandId, P2U(P[0]), P2U(P[1]), P2S(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcUUSS(Handler)(aHandId, P2U(P[0]), P2U(P[1]), P2S(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcUUSI(Handler)(aHandId, P2U(P[0]), P2U(P[1]), P2S(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcUUSB(Handler)(aHandId, P2U(P[0]), P2U(P[1]), P2S(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcUUS(Handler)(aHandId, P2U(P[0]), P2U(P[1]), P2S(P[2]));
                                      end;
                            cpkIntg:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcUUIU(Handler)(aHandId, P2U(P[0]), P2U(P[1]), P2I(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcUUIS(Handler)(aHandId, P2U(P[0]), P2U(P[1]), P2I(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcUUII(Handler)(aHandId, P2U(P[0]), P2U(P[1]), P2I(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcUUIB(Handler)(aHandId, P2U(P[0]), P2U(P[1]), P2I(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcUUI(Handler)(aHandId, P2U(P[0]), P2U(P[1]), P2I(P[2]));
                                      end;
                            cpkBool:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcUUBU(Handler)(aHandId, P2U(P[0]), P2U(P[1]), P2B(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcUUBS(Handler)(aHandId, P2U(P[0]), P2U(P[1]), P2B(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcUUBI(Handler)(aHandId, P2U(P[0]), P2U(P[1]), P2B(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcUUBB(Handler)(aHandId, P2U(P[0]), P2U(P[1]), P2B(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcUUB(Handler)(aHandId, P2U(P[0]), P2U(P[1]), P2B(P[2]));
                                      end;
                            cpkNone:  TKMScriptCmdProcUU(Handler)(aHandId, P2U(P[0]), P2U(P[1]));
                          end;
                cpkSngl:  case fPT[2] of
                            cpkUStr:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcUSUU(Handler)(aHandId, P2U(P[0]), P2S(P[1]), P2U(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcUSUS(Handler)(aHandId, P2U(P[0]), P2S(P[1]), P2U(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcUSUI(Handler)(aHandId, P2U(P[0]), P2S(P[1]), P2U(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcUSUB(Handler)(aHandId, P2U(P[0]), P2S(P[1]), P2U(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcUSU(Handler)(aHandId, P2U(P[0]), P2S(P[1]), P2U(P[2]));
                                      end;
                            cpkSngl:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcUSSU(Handler)(aHandId, P2U(P[0]), P2S(P[1]), P2S(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcUSSS(Handler)(aHandId, P2U(P[0]), P2S(P[1]), P2S(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcUSSI(Handler)(aHandId, P2U(P[0]), P2S(P[1]), P2S(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcUSSB(Handler)(aHandId, P2U(P[0]), P2S(P[1]), P2S(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcUSS(Handler)(aHandId, P2U(P[0]), P2S(P[1]), P2S(P[2]));
                                      end;
                            cpkIntg:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcUSIU(Handler)(aHandId, P2U(P[0]), P2S(P[1]), P2I(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcUSIS(Handler)(aHandId, P2U(P[0]), P2S(P[1]), P2I(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcUSII(Handler)(aHandId, P2U(P[0]), P2S(P[1]), P2I(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcUSIB(Handler)(aHandId, P2U(P[0]), P2S(P[1]), P2I(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcUSI(Handler)(aHandId, P2U(P[0]), P2S(P[1]), P2I(P[2]));
                                      end;
                            cpkBool:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcUSBU(Handler)(aHandId, P2U(P[0]), P2S(P[1]), P2B(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcUSBS(Handler)(aHandId, P2U(P[0]), P2S(P[1]), P2B(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcUSBI(Handler)(aHandId, P2U(P[0]), P2S(P[1]), P2B(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcUSBB(Handler)(aHandId, P2U(P[0]), P2S(P[1]), P2B(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcUSB(Handler)(aHandId, P2U(P[0]), P2S(P[1]), P2B(P[2]));
                                      end;
                            cpkNone:  TKMScriptCmdProcUS(Handler)(aHandId, P2U(P[0]), P2S(P[1]));
                          end;
                cpkIntg:  case fPT[2] of
                            cpkUStr:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcUIUU(Handler)(aHandId, P2U(P[0]), P2I(P[1]), P2U(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcUIUS(Handler)(aHandId, P2U(P[0]), P2I(P[1]), P2U(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcUIUI(Handler)(aHandId, P2U(P[0]), P2I(P[1]), P2U(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcUIUB(Handler)(aHandId, P2U(P[0]), P2I(P[1]), P2U(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcUIU(Handler)(aHandId, P2U(P[0]), P2I(P[1]), P2U(P[2]));
                                      end;
                            cpkSngl:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcUISU(Handler)(aHandId, P2U(P[0]), P2I(P[1]), P2S(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcUISS(Handler)(aHandId, P2U(P[0]), P2I(P[1]), P2S(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcUISI(Handler)(aHandId, P2U(P[0]), P2I(P[1]), P2S(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcUISB(Handler)(aHandId, P2U(P[0]), P2I(P[1]), P2S(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcUIS(Handler)(aHandId, P2U(P[0]), P2I(P[1]), P2S(P[2]));
                                      end;
                            cpkIntg:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcUIIU(Handler)(aHandId, P2U(P[0]), P2I(P[1]), P2I(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcUIIS(Handler)(aHandId, P2U(P[0]), P2I(P[1]), P2I(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcUIII(Handler)(aHandId, P2U(P[0]), P2I(P[1]), P2I(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcUIIB(Handler)(aHandId, P2U(P[0]), P2I(P[1]), P2I(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcUII(Handler)(aHandId, P2U(P[0]), P2I(P[1]), P2I(P[2]));
                                      end;
                            cpkBool:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcUIBU(Handler)(aHandId, P2U(P[0]), P2I(P[1]), P2B(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcUIBS(Handler)(aHandId, P2U(P[0]), P2I(P[1]), P2B(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcUIBI(Handler)(aHandId, P2U(P[0]), P2I(P[1]), P2B(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcUIBB(Handler)(aHandId, P2U(P[0]), P2I(P[1]), P2B(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcUIB(Handler)(aHandId, P2U(P[0]), P2I(P[1]), P2B(P[2]));
                                      end;
                            cpkNone:  TKMScriptCmdProcUI(Handler)(aHandId, P2U(P[0]), P2I(P[1]));
                          end;
                cpkBool:  case fPT[2] of
                            cpkUStr:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcUBUU(Handler)(aHandId, P2U(P[0]), P2B(P[1]), P2U(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcUBUS(Handler)(aHandId, P2U(P[0]), P2B(P[1]), P2U(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcUBUI(Handler)(aHandId, P2U(P[0]), P2B(P[1]), P2U(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcUBUB(Handler)(aHandId, P2U(P[0]), P2B(P[1]), P2U(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcUBU(Handler)(aHandId, P2U(P[0]), P2B(P[1]), P2U(P[2]));
                                      end;
                            cpkSngl:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcUBSU(Handler)(aHandId, P2U(P[0]), P2B(P[1]), P2S(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcUBSS(Handler)(aHandId, P2U(P[0]), P2B(P[1]), P2S(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcUBSI(Handler)(aHandId, P2U(P[0]), P2B(P[1]), P2S(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcUBSB(Handler)(aHandId, P2U(P[0]), P2B(P[1]), P2S(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcUBS(Handler)(aHandId, P2U(P[0]), P2B(P[1]), P2S(P[2]));
                                      end;
                            cpkIntg:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcUBIU(Handler)(aHandId, P2U(P[0]), P2B(P[1]), P2I(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcUBIS(Handler)(aHandId, P2U(P[0]), P2B(P[1]), P2I(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcUBII(Handler)(aHandId, P2U(P[0]), P2B(P[1]), P2I(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcUBIB(Handler)(aHandId, P2U(P[0]), P2B(P[1]), P2I(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcUBI(Handler)(aHandId, P2U(P[0]), P2B(P[1]), P2I(P[2]));
                                      end;
                            cpkBool:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcUBBU(Handler)(aHandId, P2U(P[0]), P2B(P[1]), P2B(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcUBBS(Handler)(aHandId, P2U(P[0]), P2B(P[1]), P2B(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcUBBI(Handler)(aHandId, P2U(P[0]), P2B(P[1]), P2B(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcUBBB(Handler)(aHandId, P2U(P[0]), P2B(P[1]), P2B(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcUBB(Handler)(aHandId, P2U(P[0]), P2B(P[1]), P2B(P[2]));
                                      end;
                            cpkNone:  TKMScriptCmdProcUB(Handler)(aHandId, P2U(P[0]), P2B(P[1]));
                          end;
                cpkNone:  TKMScriptCmdProcU(Handler)(aHandId, P2U(P[0]));
            end;
    cpkSngl:  case fPT[1] of
                cpkUStr:  case fPT[2] of
                            cpkUStr:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcSUUU(Handler)(aHandId, P2S(P[0]), P2U(P[1]), P2U(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcSUUS(Handler)(aHandId, P2S(P[0]), P2U(P[1]), P2U(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcSUUI(Handler)(aHandId, P2S(P[0]), P2U(P[1]), P2U(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcSUUB(Handler)(aHandId, P2S(P[0]), P2U(P[1]), P2U(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcSUU(Handler)(aHandId, P2S(P[0]), P2U(P[1]), P2U(P[2]));
                                      end;
                            cpkSngl:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcSUSU(Handler)(aHandId, P2S(P[0]), P2U(P[1]), P2S(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcSUSS(Handler)(aHandId, P2S(P[0]), P2U(P[1]), P2S(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcSUSI(Handler)(aHandId, P2S(P[0]), P2U(P[1]), P2S(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcSUSB(Handler)(aHandId, P2S(P[0]), P2U(P[1]), P2S(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcSUS(Handler)(aHandId, P2S(P[0]), P2U(P[1]), P2S(P[2]));
                                      end;
                            cpkIntg:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcSUIU(Handler)(aHandId, P2S(P[0]), P2U(P[1]), P2I(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcSUIS(Handler)(aHandId, P2S(P[0]), P2U(P[1]), P2I(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcSUII(Handler)(aHandId, P2S(P[0]), P2U(P[1]), P2I(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcSUIB(Handler)(aHandId, P2S(P[0]), P2U(P[1]), P2I(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcSUI(Handler)(aHandId, P2S(P[0]), P2U(P[1]), P2I(P[2]));
                                      end;
                            cpkBool:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcSUBU(Handler)(aHandId, P2S(P[0]), P2U(P[1]), P2B(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcSUBS(Handler)(aHandId, P2S(P[0]), P2U(P[1]), P2B(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcSUBI(Handler)(aHandId, P2S(P[0]), P2U(P[1]), P2B(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcSUBB(Handler)(aHandId, P2S(P[0]), P2U(P[1]), P2B(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcSUB(Handler)(aHandId, P2S(P[0]), P2U(P[1]), P2B(P[2]));
                                      end;
                            cpkNone:  TKMScriptCmdProcSU(Handler)(aHandId, P2S(P[0]), P2U(P[1]));
                          end;
                cpkSngl:  case fPT[2] of
                            cpkUStr:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcSSUU(Handler)(aHandId, P2S(P[0]), P2S(P[1]), P2U(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcSSUS(Handler)(aHandId, P2S(P[0]), P2S(P[1]), P2U(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcSSUI(Handler)(aHandId, P2S(P[0]), P2S(P[1]), P2U(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcSSUB(Handler)(aHandId, P2S(P[0]), P2S(P[1]), P2U(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcSSU(Handler)(aHandId, P2S(P[0]), P2S(P[1]), P2U(P[2]));
                                      end;
                            cpkSngl:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcSSSU(Handler)(aHandId, P2S(P[0]), P2S(P[1]), P2S(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcSSSS(Handler)(aHandId, P2S(P[0]), P2S(P[1]), P2S(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcSSSI(Handler)(aHandId, P2S(P[0]), P2S(P[1]), P2S(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcSSSB(Handler)(aHandId, P2S(P[0]), P2S(P[1]), P2S(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcSSS(Handler)(aHandId, P2S(P[0]), P2S(P[1]), P2S(P[2]));
                                      end;
                            cpkIntg:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcSSIU(Handler)(aHandId, P2S(P[0]), P2S(P[1]), P2I(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcSSIS(Handler)(aHandId, P2S(P[0]), P2S(P[1]), P2I(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcSSII(Handler)(aHandId, P2S(P[0]), P2S(P[1]), P2I(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcSSIB(Handler)(aHandId, P2S(P[0]), P2S(P[1]), P2I(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcSSI(Handler)(aHandId, P2S(P[0]), P2S(P[1]), P2I(P[2]));
                                      end;
                            cpkBool:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcSSBU(Handler)(aHandId, P2S(P[0]), P2S(P[1]), P2B(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcSSBS(Handler)(aHandId, P2S(P[0]), P2S(P[1]), P2B(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcSSBI(Handler)(aHandId, P2S(P[0]), P2S(P[1]), P2B(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcSSBB(Handler)(aHandId, P2S(P[0]), P2S(P[1]), P2B(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcSSB(Handler)(aHandId, P2S(P[0]), P2S(P[1]), P2B(P[2]));
                                      end;
                            cpkNone:  TKMScriptCmdProcSS(Handler)(aHandId, P2S(P[0]), P2S(P[1]));
                          end;
                cpkIntg:  case fPT[2] of
                            cpkUStr:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcSIUU(Handler)(aHandId, P2S(P[0]), P2I(P[1]), P2U(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcSIUS(Handler)(aHandId, P2S(P[0]), P2I(P[1]), P2U(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcSIUI(Handler)(aHandId, P2S(P[0]), P2I(P[1]), P2U(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcSIUB(Handler)(aHandId, P2S(P[0]), P2I(P[1]), P2U(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcSIU(Handler)(aHandId, P2S(P[0]), P2I(P[1]), P2U(P[2]));
                                      end;
                            cpkSngl:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcSISU(Handler)(aHandId, P2S(P[0]), P2I(P[1]), P2S(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcSISS(Handler)(aHandId, P2S(P[0]), P2I(P[1]), P2S(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcSISI(Handler)(aHandId, P2S(P[0]), P2I(P[1]), P2S(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcSISB(Handler)(aHandId, P2S(P[0]), P2I(P[1]), P2S(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcSIS(Handler)(aHandId, P2S(P[0]), P2I(P[1]), P2S(P[2]));
                                      end;
                            cpkIntg:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcSIIU(Handler)(aHandId, P2S(P[0]), P2I(P[1]), P2I(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcSIIS(Handler)(aHandId, P2S(P[0]), P2I(P[1]), P2I(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcSIII(Handler)(aHandId, P2S(P[0]), P2I(P[1]), P2I(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcSIIB(Handler)(aHandId, P2S(P[0]), P2I(P[1]), P2I(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcSII(Handler)(aHandId, P2S(P[0]), P2I(P[1]), P2I(P[2]));
                                      end;
                            cpkBool:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcSIBU(Handler)(aHandId, P2S(P[0]), P2I(P[1]), P2B(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcSIBS(Handler)(aHandId, P2S(P[0]), P2I(P[1]), P2B(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcSIBI(Handler)(aHandId, P2S(P[0]), P2I(P[1]), P2B(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcSIBB(Handler)(aHandId, P2S(P[0]), P2I(P[1]), P2B(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcSIB(Handler)(aHandId, P2S(P[0]), P2I(P[1]), P2B(P[2]));
                                      end;
                            cpkNone:  TKMScriptCmdProcSI(Handler)(aHandId, P2S(P[0]), P2I(P[1]));
                          end;
                cpkBool:  case fPT[2] of
                            cpkUStr:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcSBUU(Handler)(aHandId, P2S(P[0]), P2B(P[1]), P2U(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcSBUS(Handler)(aHandId, P2S(P[0]), P2B(P[1]), P2U(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcSBUI(Handler)(aHandId, P2S(P[0]), P2B(P[1]), P2U(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcSBUB(Handler)(aHandId, P2S(P[0]), P2B(P[1]), P2U(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcSBU(Handler)(aHandId, P2S(P[0]), P2B(P[1]), P2U(P[2]));
                                      end;
                            cpkSngl:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcSBSU(Handler)(aHandId, P2S(P[0]), P2B(P[1]), P2S(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcSBSS(Handler)(aHandId, P2S(P[0]), P2B(P[1]), P2S(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcSBSI(Handler)(aHandId, P2S(P[0]), P2B(P[1]), P2S(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcSBSB(Handler)(aHandId, P2S(P[0]), P2B(P[1]), P2S(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcSBS(Handler)(aHandId, P2S(P[0]), P2B(P[1]), P2S(P[2]));
                                      end;
                            cpkIntg:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcSBIU(Handler)(aHandId, P2S(P[0]), P2B(P[1]), P2I(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcSBIS(Handler)(aHandId, P2S(P[0]), P2B(P[1]), P2I(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcSBII(Handler)(aHandId, P2S(P[0]), P2B(P[1]), P2I(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcSBIB(Handler)(aHandId, P2S(P[0]), P2B(P[1]), P2I(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcSBI(Handler)(aHandId, P2S(P[0]), P2B(P[1]), P2I(P[2]));
                                      end;
                            cpkBool:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcSBBU(Handler)(aHandId, P2S(P[0]), P2B(P[1]), P2B(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcSBBS(Handler)(aHandId, P2S(P[0]), P2B(P[1]), P2B(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcSBBI(Handler)(aHandId, P2S(P[0]), P2B(P[1]), P2B(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcSBBB(Handler)(aHandId, P2S(P[0]), P2B(P[1]), P2B(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcSBB(Handler)(aHandId, P2S(P[0]), P2B(P[1]), P2B(P[2]));
                                      end;
                            cpkNone:  TKMScriptCmdProcSB(Handler)(aHandId, P2S(P[0]), P2B(P[1]));
                          end;
                cpkNone:  TKMScriptCmdProcS(Handler)(aHandId, P2S(P[0]));
            end;
    cpkIntg:  case fPT[1] of
                cpkUStr:  case fPT[2] of
                            cpkUStr:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcIUUU(Handler)(aHandId, P2I(P[0]), P2U(P[1]), P2U(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcIUUS(Handler)(aHandId, P2I(P[0]), P2U(P[1]), P2U(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcIUUI(Handler)(aHandId, P2I(P[0]), P2U(P[1]), P2U(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcIUUB(Handler)(aHandId, P2I(P[0]), P2U(P[1]), P2U(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcIUU(Handler)(aHandId, P2I(P[0]), P2U(P[1]), P2U(P[2]));
                                      end;
                            cpkSngl:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcIUSU(Handler)(aHandId, P2I(P[0]), P2U(P[1]), P2S(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcIUSS(Handler)(aHandId, P2I(P[0]), P2U(P[1]), P2S(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcIUSI(Handler)(aHandId, P2I(P[0]), P2U(P[1]), P2S(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcIUSB(Handler)(aHandId, P2I(P[0]), P2U(P[1]), P2S(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcIUS(Handler)(aHandId, P2I(P[0]), P2U(P[1]), P2S(P[2]));
                                      end;
                            cpkIntg:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcIUIU(Handler)(aHandId, P2I(P[0]), P2U(P[1]), P2I(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcIUIS(Handler)(aHandId, P2I(P[0]), P2U(P[1]), P2I(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcIUII(Handler)(aHandId, P2I(P[0]), P2U(P[1]), P2I(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcIUIB(Handler)(aHandId, P2I(P[0]), P2U(P[1]), P2I(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcIUI(Handler)(aHandId, P2I(P[0]), P2U(P[1]), P2I(P[2]));
                                      end;
                            cpkBool:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcIUBU(Handler)(aHandId, P2I(P[0]), P2U(P[1]), P2B(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcIUBS(Handler)(aHandId, P2I(P[0]), P2U(P[1]), P2B(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcIUBI(Handler)(aHandId, P2I(P[0]), P2U(P[1]), P2B(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcIUBB(Handler)(aHandId, P2I(P[0]), P2U(P[1]), P2B(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcIUB(Handler)(aHandId, P2I(P[0]), P2U(P[1]), P2B(P[2]));
                                      end;
                            cpkNone:  TKMScriptCmdProcIU(Handler)(aHandId, P2I(P[0]), P2U(P[1]));
                          end;
                cpkSngl:  case fPT[2] of
                            cpkUStr:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcISUU(Handler)(aHandId, P2I(P[0]), P2S(P[1]), P2U(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcISUS(Handler)(aHandId, P2I(P[0]), P2S(P[1]), P2U(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcISUI(Handler)(aHandId, P2I(P[0]), P2S(P[1]), P2U(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcISUB(Handler)(aHandId, P2I(P[0]), P2S(P[1]), P2U(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcISU(Handler)(aHandId, P2I(P[0]), P2S(P[1]), P2U(P[2]));
                                      end;
                            cpkSngl:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcISSU(Handler)(aHandId, P2I(P[0]), P2S(P[1]), P2S(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcISSS(Handler)(aHandId, P2I(P[0]), P2S(P[1]), P2S(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcISSI(Handler)(aHandId, P2I(P[0]), P2S(P[1]), P2S(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcISSB(Handler)(aHandId, P2I(P[0]), P2S(P[1]), P2S(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcISS(Handler)(aHandId, P2I(P[0]), P2S(P[1]), P2S(P[2]));
                                      end;
                            cpkIntg:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcISIU(Handler)(aHandId, P2I(P[0]), P2S(P[1]), P2I(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcISIS(Handler)(aHandId, P2I(P[0]), P2S(P[1]), P2I(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcISII(Handler)(aHandId, P2I(P[0]), P2S(P[1]), P2I(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcISIB(Handler)(aHandId, P2I(P[0]), P2S(P[1]), P2I(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcISI(Handler)(aHandId, P2I(P[0]), P2S(P[1]), P2I(P[2]));
                                      end;
                            cpkBool:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcISBU(Handler)(aHandId, P2I(P[0]), P2S(P[1]), P2B(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcISBS(Handler)(aHandId, P2I(P[0]), P2S(P[1]), P2B(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcISBI(Handler)(aHandId, P2I(P[0]), P2S(P[1]), P2B(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcISBB(Handler)(aHandId, P2I(P[0]), P2S(P[1]), P2B(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcISB(Handler)(aHandId, P2I(P[0]), P2S(P[1]), P2B(P[2]));
                                      end;
                            cpkNone:  TKMScriptCmdProcIS(Handler)(aHandId, P2I(P[0]), P2S(P[1]));
                          end;
                cpkIntg:  case fPT[2] of
                            cpkUStr:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcIIUU(Handler)(aHandId, P2I(P[0]), P2I(P[1]), P2U(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcIIUS(Handler)(aHandId, P2I(P[0]), P2I(P[1]), P2U(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcIIUI(Handler)(aHandId, P2I(P[0]), P2I(P[1]), P2U(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcIIUB(Handler)(aHandId, P2I(P[0]), P2I(P[1]), P2U(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcIIU(Handler)(aHandId, P2I(P[0]), P2I(P[1]), P2U(P[2]));
                                      end;
                            cpkSngl:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcIISU(Handler)(aHandId, P2I(P[0]), P2I(P[1]), P2S(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcIISS(Handler)(aHandId, P2I(P[0]), P2I(P[1]), P2S(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcIISI(Handler)(aHandId, P2I(P[0]), P2I(P[1]), P2S(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcIISB(Handler)(aHandId, P2I(P[0]), P2I(P[1]), P2S(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcIIS(Handler)(aHandId, P2I(P[0]), P2I(P[1]), P2S(P[2]));
                                      end;
                            cpkIntg:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcIIIU(Handler)(aHandId, P2I(P[0]), P2I(P[1]), P2I(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcIIIS(Handler)(aHandId, P2I(P[0]), P2I(P[1]), P2I(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcIIII(Handler)(aHandId, P2I(P[0]), P2I(P[1]), P2I(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcIIIB(Handler)(aHandId, P2I(P[0]), P2I(P[1]), P2I(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcIII(Handler)(aHandId, P2I(P[0]), P2I(P[1]), P2I(P[2]));
                                      end;
                            cpkBool:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcIIBU(Handler)(aHandId, P2I(P[0]), P2I(P[1]), P2B(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcIIBS(Handler)(aHandId, P2I(P[0]), P2I(P[1]), P2B(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcIIBI(Handler)(aHandId, P2I(P[0]), P2I(P[1]), P2B(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcIIBB(Handler)(aHandId, P2I(P[0]), P2I(P[1]), P2B(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcIIB(Handler)(aHandId, P2I(P[0]), P2I(P[1]), P2B(P[2]));
                                      end;
                            cpkNone:  TKMScriptCmdProcII(Handler)(aHandId, P2I(P[0]), P2I(P[1]));
                          end;
                cpkBool:  case fPT[2] of
                            cpkUStr:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcIBUU(Handler)(aHandId, P2I(P[0]), P2B(P[1]), P2U(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcIBUS(Handler)(aHandId, P2I(P[0]), P2B(P[1]), P2U(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcIBUI(Handler)(aHandId, P2I(P[0]), P2B(P[1]), P2U(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcIBUB(Handler)(aHandId, P2I(P[0]), P2B(P[1]), P2U(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcIBU(Handler)(aHandId, P2I(P[0]), P2B(P[1]), P2U(P[2]));
                                      end;
                            cpkSngl:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcIBSU(Handler)(aHandId, P2I(P[0]), P2B(P[1]), P2S(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcIBSS(Handler)(aHandId, P2I(P[0]), P2B(P[1]), P2S(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcIBSI(Handler)(aHandId, P2I(P[0]), P2B(P[1]), P2S(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcIBSB(Handler)(aHandId, P2I(P[0]), P2B(P[1]), P2S(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcIBS(Handler)(aHandId, P2I(P[0]), P2B(P[1]), P2S(P[2]));
                                      end;
                            cpkIntg:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcIBIU(Handler)(aHandId, P2I(P[0]), P2B(P[1]), P2I(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcIBIS(Handler)(aHandId, P2I(P[0]), P2B(P[1]), P2I(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcIBII(Handler)(aHandId, P2I(P[0]), P2B(P[1]), P2I(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcIBIB(Handler)(aHandId, P2I(P[0]), P2B(P[1]), P2I(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcIBI(Handler)(aHandId, P2I(P[0]), P2B(P[1]), P2I(P[2]));
                                      end;
                            cpkBool:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcIBBU(Handler)(aHandId, P2I(P[0]), P2B(P[1]), P2B(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcIBBS(Handler)(aHandId, P2I(P[0]), P2B(P[1]), P2B(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcIBBI(Handler)(aHandId, P2I(P[0]), P2B(P[1]), P2B(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcIBBB(Handler)(aHandId, P2I(P[0]), P2B(P[1]), P2B(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcIBB(Handler)(aHandId, P2I(P[0]), P2B(P[1]), P2B(P[2]));
                                      end;
                            cpkNone:  TKMScriptCmdProcIB(Handler)(aHandId, P2I(P[0]), P2B(P[1]));
                          end;
                cpkNone:  TKMScriptCmdProcI(Handler)(aHandId, P2I(P[0]));
            end;
    cpkBool:  case fPT[1] of
                cpkUStr:  case fPT[2] of
                            cpkUStr:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcBUUU(Handler)(aHandId, P2B(P[0]), P2U(P[1]), P2U(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcBUUS(Handler)(aHandId, P2B(P[0]), P2U(P[1]), P2U(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcBUUI(Handler)(aHandId, P2B(P[0]), P2U(P[1]), P2U(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcBUUB(Handler)(aHandId, P2B(P[0]), P2U(P[1]), P2U(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcBUU(Handler)(aHandId, P2B(P[0]), P2U(P[1]), P2U(P[2]));
                                      end;
                            cpkSngl:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcBUSU(Handler)(aHandId, P2B(P[0]), P2U(P[1]), P2S(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcBUSS(Handler)(aHandId, P2B(P[0]), P2U(P[1]), P2S(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcBUSI(Handler)(aHandId, P2B(P[0]), P2U(P[1]), P2S(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcBUSB(Handler)(aHandId, P2B(P[0]), P2U(P[1]), P2S(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcBUS(Handler)(aHandId, P2B(P[0]), P2U(P[1]), P2S(P[2]));
                                      end;
                            cpkIntg:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcBUIU(Handler)(aHandId, P2B(P[0]), P2U(P[1]), P2I(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcBUIS(Handler)(aHandId, P2B(P[0]), P2U(P[1]), P2I(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcBUII(Handler)(aHandId, P2B(P[0]), P2U(P[1]), P2I(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcBUIB(Handler)(aHandId, P2B(P[0]), P2U(P[1]), P2I(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcBUI(Handler)(aHandId, P2B(P[0]), P2U(P[1]), P2I(P[2]));
                                      end;
                            cpkBool:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcBUBU(Handler)(aHandId, P2B(P[0]), P2U(P[1]), P2B(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcBUBS(Handler)(aHandId, P2B(P[0]), P2U(P[1]), P2B(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcBUBI(Handler)(aHandId, P2B(P[0]), P2U(P[1]), P2B(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcBUBB(Handler)(aHandId, P2B(P[0]), P2U(P[1]), P2B(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcBUB(Handler)(aHandId, P2B(P[0]), P2U(P[1]), P2B(P[2]));
                                      end;
                            cpkNone:  TKMScriptCmdProcBU(Handler)(aHandId, P2B(P[0]), P2U(P[1]));
                          end;
                cpkSngl:  case fPT[2] of
                            cpkUStr:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcBSUU(Handler)(aHandId, P2B(P[0]), P2S(P[1]), P2U(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcBSUS(Handler)(aHandId, P2B(P[0]), P2S(P[1]), P2U(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcBSUI(Handler)(aHandId, P2B(P[0]), P2S(P[1]), P2U(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcBSUB(Handler)(aHandId, P2B(P[0]), P2S(P[1]), P2U(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcBSU(Handler)(aHandId, P2B(P[0]), P2S(P[1]), P2U(P[2]));
                                      end;
                            cpkSngl:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcBSSU(Handler)(aHandId, P2B(P[0]), P2S(P[1]), P2S(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcBSSS(Handler)(aHandId, P2B(P[0]), P2S(P[1]), P2S(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcBSSI(Handler)(aHandId, P2B(P[0]), P2S(P[1]), P2S(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcBSSB(Handler)(aHandId, P2B(P[0]), P2S(P[1]), P2S(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcBSS(Handler)(aHandId, P2B(P[0]), P2S(P[1]), P2S(P[2]));
                                      end;
                            cpkIntg:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcBSIU(Handler)(aHandId, P2B(P[0]), P2S(P[1]), P2I(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcBSIS(Handler)(aHandId, P2B(P[0]), P2S(P[1]), P2I(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcBSII(Handler)(aHandId, P2B(P[0]), P2S(P[1]), P2I(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcBSIB(Handler)(aHandId, P2B(P[0]), P2S(P[1]), P2I(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcBSI(Handler)(aHandId, P2B(P[0]), P2S(P[1]), P2I(P[2]));
                                      end;
                            cpkBool:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcBSBU(Handler)(aHandId, P2B(P[0]), P2S(P[1]), P2B(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcBSBS(Handler)(aHandId, P2B(P[0]), P2S(P[1]), P2B(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcBSBI(Handler)(aHandId, P2B(P[0]), P2S(P[1]), P2B(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcBSBB(Handler)(aHandId, P2B(P[0]), P2S(P[1]), P2B(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcBSB(Handler)(aHandId, P2B(P[0]), P2S(P[1]), P2B(P[2]));
                                      end;
                            cpkNone:  TKMScriptCmdProcBS(Handler)(aHandId, P2B(P[0]), P2S(P[1]));
                          end;
                cpkIntg:  case fPT[2] of
                            cpkUStr:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcBIUU(Handler)(aHandId, P2B(P[0]), P2I(P[1]), P2U(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcBIUS(Handler)(aHandId, P2B(P[0]), P2I(P[1]), P2U(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcBIUI(Handler)(aHandId, P2B(P[0]), P2I(P[1]), P2U(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcBIUB(Handler)(aHandId, P2B(P[0]), P2I(P[1]), P2U(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcBIU(Handler)(aHandId, P2B(P[0]), P2I(P[1]), P2U(P[2]));
                                      end;
                            cpkSngl:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcBISU(Handler)(aHandId, P2B(P[0]), P2I(P[1]), P2S(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcBISS(Handler)(aHandId, P2B(P[0]), P2I(P[1]), P2S(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcBISI(Handler)(aHandId, P2B(P[0]), P2I(P[1]), P2S(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcBISB(Handler)(aHandId, P2B(P[0]), P2I(P[1]), P2S(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcBIS(Handler)(aHandId, P2B(P[0]), P2I(P[1]), P2S(P[2]));
                                      end;
                            cpkIntg:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcBIIU(Handler)(aHandId, P2B(P[0]), P2I(P[1]), P2I(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcBIIS(Handler)(aHandId, P2B(P[0]), P2I(P[1]), P2I(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcBIII(Handler)(aHandId, P2B(P[0]), P2I(P[1]), P2I(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcBIIB(Handler)(aHandId, P2B(P[0]), P2I(P[1]), P2I(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcBII(Handler)(aHandId, P2B(P[0]), P2I(P[1]), P2I(P[2]));
                                      end;
                            cpkBool:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcBIBU(Handler)(aHandId, P2B(P[0]), P2I(P[1]), P2B(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcBIBS(Handler)(aHandId, P2B(P[0]), P2I(P[1]), P2B(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcBIBI(Handler)(aHandId, P2B(P[0]), P2I(P[1]), P2B(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcBIBB(Handler)(aHandId, P2B(P[0]), P2I(P[1]), P2B(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcBIB(Handler)(aHandId, P2B(P[0]), P2I(P[1]), P2B(P[2]));
                                      end;
                            cpkNone:  TKMScriptCmdProcBI(Handler)(aHandId, P2B(P[0]), P2I(P[1]));
                          end;
                cpkBool:  case fPT[2] of
                            cpkUStr:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcBBUU(Handler)(aHandId, P2B(P[0]), P2B(P[1]), P2U(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcBBUS(Handler)(aHandId, P2B(P[0]), P2B(P[1]), P2U(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcBBUI(Handler)(aHandId, P2B(P[0]), P2B(P[1]), P2U(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcBBUB(Handler)(aHandId, P2B(P[0]), P2B(P[1]), P2U(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcBBU(Handler)(aHandId, P2B(P[0]), P2B(P[1]), P2U(P[2]));
                                      end;
                            cpkSngl:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcBBSU(Handler)(aHandId, P2B(P[0]), P2B(P[1]), P2S(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcBBSS(Handler)(aHandId, P2B(P[0]), P2B(P[1]), P2S(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcBBSI(Handler)(aHandId, P2B(P[0]), P2B(P[1]), P2S(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcBBSB(Handler)(aHandId, P2B(P[0]), P2B(P[1]), P2S(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcBBS(Handler)(aHandId, P2B(P[0]), P2B(P[1]), P2S(P[2]));
                                      end;
                            cpkIntg:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcBBIU(Handler)(aHandId, P2B(P[0]), P2B(P[1]), P2I(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcBBIS(Handler)(aHandId, P2B(P[0]), P2B(P[1]), P2I(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcBBII(Handler)(aHandId, P2B(P[0]), P2B(P[1]), P2I(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcBBIB(Handler)(aHandId, P2B(P[0]), P2B(P[1]), P2I(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcBBI(Handler)(aHandId, P2B(P[0]), P2B(P[1]), P2I(P[2]));
                                      end;
                            cpkBool:  case fPT[3] of
                                        cpkUStr:  TKMScriptCmdProcBBBU(Handler)(aHandId, P2B(P[0]), P2B(P[1]), P2B(P[2]), P2U(P[3]));
                                        cpkSngl:  TKMScriptCmdProcBBBS(Handler)(aHandId, P2B(P[0]), P2B(P[1]), P2B(P[2]), P2S(P[3]));
                                        cpkIntg:  TKMScriptCmdProcBBBI(Handler)(aHandId, P2B(P[0]), P2B(P[1]), P2B(P[2]), P2I(P[3]));
                                        cpkBool:  TKMScriptCmdProcBBBB(Handler)(aHandId, P2B(P[0]), P2B(P[1]), P2B(P[2]), P2B(P[3]));
                                        cpkNone:  TKMScriptCmdProcBBB(Handler)(aHandId, P2B(P[0]), P2B(P[1]), P2B(P[2]));
                                      end;
                            cpkNone:  TKMScriptCmdProcBB(Handler)(aHandId, P2B(P[0]), P2B(P[1]));
                          end;
                cpkNone:  TKMScriptCmdProcB(Handler)(aHandId, P2B(P[0]));
            end;
    cpkNone:  TKMScriptCmdProc(Handler)(aHandId);
  end;
end;


procedure TKMConsoleCommand.Save(SaveStream: TKMemoryStream);
var
  I: Integer;
begin
  SaveStream.WriteA(fName);
  SaveStream.WriteA(fProcName);
  for I := 0 to MAX_SCRIPT_CONSOLE_COMMAND_PARAMS - 1 do
    SaveStream.Write(fPT[I], SIzeOf(fPT[I]));
end;


procedure TKMConsoleCommand.Load(LoadStream: TKMemoryStream);
var
  I: Integer;
begin
  LoadStream.ReadA(fName);
  LoadStream.ReadA(fProcName);
  for I := 0 to MAX_SCRIPT_CONSOLE_COMMAND_PARAMS - 1 do
    LoadStream.Read(fPT[I], SizeOf(fPT[I]));
end;



//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                              //
//                               CONSOLE COMMANDS CODE GENERATOR                                //
//                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////
//const
//  CLASS_PREFIX: String = 'TKMScriptCmdProc';
//  //Class suffix
//  CSUF: array[TKMCmdProcParamTypeKind] of String = (' ', 'B', 'I', 'S', 'U');
//
//
//class procedure TKMConsoleCommand.GenerateProcClasses(aSL: TStringList);
//var
//  PTK1, PTK2, PTK3, PTK4: TKMCmdProcParamTypeKind;
//  ClassStr, ClassSuff, ProcStr, Params: String;
//  I,J,K: Integer;
//  Classes: array of array[0..MAX_SCRIPT_CONSOLE_COMMAND_PARAMS-1] of TKMCmdProcParamTypeKind;
//begin
//  SetLength(Classes, 1000);
//  K := 0;
//  for PTK1 := Low(TKMCmdProcParamTypeKind) to High(TKMCmdProcParamTypeKind) do
//    for PTK2 := Low(TKMCmdProcParamTypeKind) to High(TKMCmdProcParamTypeKind) do
//      for PTK3 := Low(TKMCmdProcParamTypeKind) to High(TKMCmdProcParamTypeKind) do
//        for PTK4 := Low(TKMCmdProcParamTypeKind) to High(TKMCmdProcParamTypeKind) do
//        begin
//          if ((PTK1 = cpkNone) and (Byte(PTK2) + Byte(PTK3) + Byte(PTK4) <> 0))
//            or ((PTK2 = cpkNone) and (Byte(PTK3) + Byte(PTK4) <> 0))
//            or ((PTK3 = cpkNone) and (PTK4 <> cpkNone)) then
//           Continue;
//
//          Classes[K][0] := PTK1;
//          Classes[K][1] := PTK2;
//          Classes[K][2] := PTK3;
//          Classes[K][3] := PTK4;
//          Inc(K);
//        end;
//
//  SetLength(Classes, K);
//
//  //TKMScriptCommand1Si = procedure (aIndex: Single; aP1: Single; aP2: Integer) of object;
//  for I := 0 to Length(Classes) - 1 do
//  begin
//    ClassStr := CLASS_PREFIX;
//    ClassSuff := '';
//    Params := '';
//    for J := 0 to MAX_SCRIPT_CONSOLE_COMMAND_PARAMS - 1 do
//    begin
//      ClassSuff := ClassSuff + CSUF[Classes[I][J]];
//      if Classes[I][J] <> cpkNone then
//        Params := Format('%saP%d: %s; ', [Params, J + 1, CLASS_TYPE_STR[Classes[I][J]]]);
//    end;
//
//    ProcStr := ' = procedure(aIndex: Integer; ';
//    if Params <> '' then
//      Params := LeftStr(Params, Length(Params) - 2)
//    else
//      ProcStr := LeftStr(ProcStr, Length(ProcStr) - 2);
//
//    ClassStr := CLASS_PREFIX + ClassSuff + ProcStr + Params + ') of object;';
//    aSL.Add(ClassStr);
//  end;
//end;
//
//{
//case fPT[0] of
//    cpkNone:  TKMScriptCmdProc(Handler)(aHandId);
//    cpkBool:  case fPT[1] of
//                cpkNone:  TKMScriptCmdProc(Handler)(aHandId, P2S(P[0]));
//                cpkBool:  case fPT[2] of
//                            cpkSngl:  case fPT[3] of
//                                        cpkBool:  TKMScriptCmdProcSSSS(Handler)(aHandID,P2S(P[0]),P2S(P[1]),P2S(P[2]),P2S(P[3]));
//                                        cpkSngl:  TKMScriptCmdProcSSSS(Handler)(aHandID,P2S(P[0]),P2S(P[1]),P2S(P[2]),P2S(P[3]));
//                                      end;
//                          end;
//                cpkSngl:  case fPT[2] of
//                            cpkSngl:  case fPT[3] of
//                                        cpkSngl:  TKMScriptCmdProcSSSS(Handler)(aHandID,P2S(P[0]),P2S(P[1]),P2S(P[2]),P2S(P[3]));
//                                      end;
//                          end;
//              end;
//
//                  }
//class procedure TKMConsoleCommand.GenerateCaseClause(aSL: TStringList);
//const
//  TAB:  String = '  ';
//  TAB2: String = '                ';
//  TAB3: String = '                            ';
//  TAB4: String = '                                        ';
//  TABL: String = '        '; //length of TKMCmdProcParamTypeKind enum string
//
//var
//  PTK1, PTK2, PTK3, PTK4: TKMCmdProcParamTypeKind;
//  PTK1S, PTK2S, PTK3S, PTK4S: String;
//  Str1, Str2, Str3, Str4: String;
//  Pref1, Pref2, Pref3, Pref4, Pref5: String;
//begin
//  aSL.Clear;
//  Str1 := '';
//  Pref1 := '  ';
//  Pref2 := '    ';
//  Pref3 := '      ';
//  Pref4 := '        ';
//  Pref5 := '          ';
//
//  aSL.Add(TAB + 'case fPT[0] of');
//  for PTK1 := High(TKMCmdProcParamTypeKind) downto Low(TKMCmdProcParamTypeKind) do
//  begin
//    PTK1S := GetEnumName(TypeInfo(TKMCmdProcParamTypeKind), Integer(PTK1));
//    Str1 := TAB + TAB + PTK1S + ':';
//    if PTK1 = cpkNone then
//      aSL.Add(Str1 + TAB + CLASS_PREFIX + '(Handler)(aHandId);')
//    else
//    begin
//      aSL.Add(Str1 + TAB + 'case fPT[1] of');
//
//      for PTK2 := High(TKMCmdProcParamTypeKind) downto Low(TKMCmdProcParamTypeKind) do
//      begin
//        PTK2S := GetEnumName(TypeInfo(TKMCmdProcParamTypeKind), Integer(PTK2));
//        Str2 := TAB2 + PTK2S + ':';
//        if PTK2 = cpkNone then
//          aSL.Add(Format('%s(Handler)(aHandId, P2%s(P[0]));',
//                         [Str2 + TAB + CLASS_PREFIX + CSUF[PTK1], CSUF[PTK1]]))
//        else
//        begin
//          aSL.Add(Str2 + TAB + 'case fPT[2] of');
//
//          for PTK3 := High(TKMCmdProcParamTypeKind) downto Low(TKMCmdProcParamTypeKind) do
//          begin
//            PTK3S := GetEnumName(TypeInfo(TKMCmdProcParamTypeKind), Integer(PTK3));
//            Str3 := TAB3 + PTK3S + ':';
//            if PTK3 = cpkNone then
//              aSL.Add(Format('%s(Handler)(aHandId, P2%s(P[0]), P2%s(P[1]));',
//                             [Str3 + TAB + CLASS_PREFIX + CSUF[PTK1] + CSUF[PTK2],
//                              CSUF[PTK1], CSUF[PTK2]]))
//            else
//            begin
//              aSL.Add(Str3 + TAB + 'case fPT[3] of');
//
//              for PTK4 := High(TKMCmdProcParamTypeKind) downto Low(TKMCmdProcParamTypeKind) do
//              begin
//                PTK4S := GetEnumName(TypeInfo(TKMCmdProcParamTypeKind), Integer(PTK4));
//                Str4 := TAB4 + PTK4S + ':' + TAB;
//                if PTK4 = cpkNone then
//                  aSL.Add(Format('%s(Handler)(aHandId, P2%s(P[0]), P2%s(P[1]), P2%s(P[2]));',
//                                 [Str4 + CLASS_PREFIX + CSUF[PTK1] + CSUF[PTK2] + CSUF[PTK3],
//                                  CSUF[PTK1], CSUF[PTK2], CSUF[PTK3]]))
//                else
//                begin
//                  aSL.Add(Format('%s(Handler)(aHandId, P2%s(P[0]), P2%s(P[1]), P2%s(P[2]), P2%s(P[3]));',
//                                 [Str4 + CLASS_PREFIX + CSUF[PTK1] + CSUF[PTK2] + CSUF[PTK3] + CSUF[PTK4],
//                                 CSUF[PTK1], CSUF[PTK2], CSUF[PTK3], CSUF[PTK4]]))
//                end;
//              end;
//              aSL.Add(TAB3 + TABL + TAB + 'end;');
//            end;
//          end;
//          aSL.Add(TAB2 + TABL + TAB + 'end;');
//        end;
//      end;
//      aSL.Add(TAB + TABL + TAB + 'end;');
//    end;
//  end;
//  aSL.Add(TAB + 'end;');
//end;


initialization
begin
  gSingleDotFormat := TFormatSettings.Create;
  gSingleDotFormat.DecimalSeparator := '.';
end;


end.
