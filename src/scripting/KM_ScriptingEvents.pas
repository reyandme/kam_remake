unit KM_ScriptingEvents;
{$I KaM_Remake.inc}
{$WARN IMPLICIT_STRING_CAST OFF}
interface
uses
  Generics.Collections,
  Classes, Math, SysUtils, StrUtils, uPSRuntime, uPSDebugger, uPSPreProcessor,
  KM_Defaults, KM_Houses, KM_ScriptingIdCache, KM_Units, KM_ScriptingConsoleCommands,
  KM_UnitGroup, KM_ResHouses, KM_ResWares, KM_ScriptingTypes, KM_CommonClasses,
  KM_ResTypes, KM_HouseWoodcutters, KM_Points;


const
  FLOAT_PARAM_NONE = MaxSingle;

type
  TKMScriptEntity = class
  protected
    fIDCache: TKMScriptingIdCache;
    fOnScriptError: TKMScriptErrorEvent;
    procedure LogWarning(const aFuncName, aWarnMsg: String);
    procedure LogIntParamWarn(const aFuncName: String; const aValues: array of Integer);
    procedure LogParamWarn(const aFuncName: String; const aValues: array of const); overload;
    procedure LogParamWarn(const aFuncName: String; aValues1, aValues2: array of const); overload;
  public
    constructor Create(aIDCache: TKMScriptingIdCache);
    property OnScriptError: TKMScriptErrorEvent write fOnScriptError;
  end;

  TKMCustomEventHandler = record
    ProcName: AnsiString; // Handler procedure name in the script file (needs to be unique across included scripts)
    Handler: TMethod;
  end;

  TKMCustomEventHandlerArray = array of TKMCustomEventHandler;

  TKMScriptEvents = class(TKMScriptEntity)
  private
    fExec: TPSExec;
    fPreProcessor: TPSPreProcessor;

    fEventHandlers: array[TKMScriptEventType] of TKMCustomEventHandlerArray;

    fConsoleCommands: TDictionary<AnsiString, TKMConsoleCommand>;

    procedure CallEventHandlers(aEventType: TKMScriptEventType; const aParams: array of Integer; aFloatParam: Single = FLOAT_PARAM_NONE);

    function GetConsoleCommand(const aName: AnsiString): TKMConsoleCommand;
    function GetEventHandlers(aEvent: TKMScriptEventType): TKMCustomEventHandlerArray;

    procedure HandleScriptProcCallError(const aMethod: String);
    procedure CallEventProc(const aProc: TKMCustomEventHandler; const aIntParams: array of Integer; aFloatParam: Single);
    function MethodAssigned(aProc: TMethod): Boolean; overload; inline;
    function MethodAssigned(aEventType: TKMScriptEventType): Boolean; overload; inline;
    function MethodAssigned(const aCmdName: AnsiString): Boolean; overload; inline;

    procedure ProcHouseAfterDestroyed(aHouseType: Integer; aOwner: TKMHandID; aX, aY: Integer);
    procedure ProcHouseAfterDestroyedEx(aHouseType: TKMHouseType; aOwner: TKMHandID; aX, aY: Integer);

    procedure ProcHousePlanPlaced(aPlayer: TKMHandID; aX, aY, aHouseType: Integer);
    procedure ProcHousePlanPlacedEx(aPlayer: TKMHandID; aX, aY: Integer; aHouseType: TKMHouseType);

    procedure ProcHousePlanRemoved(aPlayer: TKMHandID; aX, aY, aHouseType: Integer);
    procedure ProcHousePlanRemovedEx(aPlayer: TKMHandID; aX, aY: Integer; aHouseType: TKMHouseType);

    procedure ProcMarketTrade(aMarket: TKMHouse; aFrom, aTo: Integer);
    procedure ProcMarketTradeEx(aMarket: TKMHouse; aFrom, aTo: TKMWareType);

    procedure ProcUnitAfterDied(aUnitType: Integer; aOwner: TKMHandID; aX, aY: Integer);
    procedure ProcUnitAfterDiedEx(aUnitType: TKMUnitType; aOwner: TKMHandID; aX, aY: Integer);
  public
    //todo: This could be replaced with ENonScriptException = class(Exception)
    ExceptionOutsideScript: Boolean; //Flag that the exception occured in a State or Action call not script

    constructor Create(aExec: TPSExec; aPreProcessor: TPSPreProcessor; aIDCache: TKMScriptingIdCache);
    destructor Destroy; override;

    procedure AddDefaultEventHandlersNames;
    procedure AddEventHandlerName(aEventType: TKMScriptEventType; const aEventHandlerName: AnsiString);
    procedure AddConsoleCommand(const aCmdName, aProcName: AnsiString);
    procedure LinkEventsAndCommands;

    function ParseConsoleCommandsProcedures(const aScriptCode: AnsiString): Boolean;
    function HasConsoleCommand(const aCmdName: AnsiString) : Boolean;
    function HasConsoleCommands: Boolean;
    function CallConsoleCommand(aHandID: TKMHandID; const aCmdName: AnsiString; const aParams: TKMScriptCommandParamsArray): Boolean;

    property ConsoleCommand[const aName: AnsiString]: TKMConsoleCommand read GetConsoleCommand;
    property EventHandlers[aEvent: TKMScriptEventType]: TKMCustomEventHandlerArray read GetEventHandlers;

    procedure Clear;

    procedure ProcBeacon(aPlayer: TKMHandID; aX, aY: Integer);
    procedure ProcFieldBuilt(aPlayer: TKMHandID; aX, aY: Integer);
    procedure EventHouseAfterDestroyed(aHouseType: TKMHouseType; aOwner: TKMHandID; aX, aY: Integer);
    procedure ProcHouseBuilt(aHouse: TKMHouse);
    procedure ProcHousePlanDigged(aHouse: TKMHouse);
    procedure EventHousePlanPlaced(aPlayer: TKMHandID; aX, aY: Integer; aType: TKMHouseType);
    procedure EventHousePlanRemoved(aPlayer: TKMHandID; aX, aY: Integer; aType: TKMHouseType);
    procedure ProcHouseDamaged(aHouse: TKMHouse; aAttacker: TKMUnit);
    procedure ProcHouseDeliveryModeChanged(aHouse: TKMHouse; aOldMode: TKMDeliveryMode; aNewMode: TKMDeliveryMode);
    procedure ProcHouseDestroyed(aHouse: TKMHouse; aDestroyerIndex: TKMHandID);
    procedure ProcHouseFlagPointChanged(aHouse: TKMHouse; aOldX, aOldY, aNewX, aNewY: Integer);
    procedure ProcHouseRepaired(aHouse: TKMHouse; aRepairAmount, aDamage: Integer);
    procedure ProcHouseWareCountChanged(aHouse: TKMHouse; aWare: TKMWareType; aCnt, aChangeCnt: Integer);
    procedure ProcGameSpeedChanged(aSpeed: Single);
    procedure ProcGroupHungry(aGroup: TKMUnitGroup);
    procedure ProcGroupOrderAttackHouse(aGroup: TKMUnitGroup; aHouse: TKMHouse);
    procedure ProcGroupOrderAttackUnit(aGroup: TKMUnitGroup; aUnit: TKMUnit);
    procedure ProcGroupBeforeOrderSplit(aGroup: TKMUnitGroup; var aNewType: TKMUnitType; var aNewCnt: Integer; var aMixed: Boolean);
    procedure ProcGroupOrderMove(aGroup: TKMUnitGroup; aX, aY: Integer; aDir: TKMDirection);
    procedure ProcGroupOrderLink(aGroup1, aGroup2: TKMUnitGroup);
    procedure ProcGroupOrderSplit(aGroup, aNewGroup: TKMUnitGroup);
    procedure EventMarketTrade(aMarket: TKMHouse; aFrom, aTo: TKMWareType);
    procedure ProcMissionStart;
    procedure ProcPeacetimeEnd;
    procedure ProcPlanRoadDigged(aPlayer: TKMHandID; aX, aY: Integer);
    procedure ProcPlanRoadPlaced(aPlayer: TKMHandID; aX, aY: Integer);
    procedure ProcPlanRoadRemoved(aPlayer: TKMHandID; aX, aY: Integer);
    procedure ProcPlanFieldPlaced(aPlayer: TKMHandID; aX, aY: Integer);
    procedure ProcPlanFieldRemoved(aPlayer: TKMHandID; aX, aY: Integer);
    procedure ProcPlanWinefieldDigged(aPlayer: TKMHandID; aX, aY: Integer);
    procedure ProcPlanWinefieldPlaced(aPlayer: TKMHandID; aX, aY: Integer);
    procedure ProcPlanWinefieldRemoved(aPlayer: TKMHandID; aX, aY: Integer);
    procedure ProcPlayerDefeated(aPlayer: TKMHandID);
    procedure ProcPlayerVictory(aPlayer: TKMHandID);
    procedure ProcRoadBuilt(aPlayer: TKMHandID; aX, aY: Integer);
    procedure ProcTick;
    procedure EventUnitAfterDied(aUnitType: TKMUnitType; aOwner: TKMHandID; aX, aY: Integer);
    procedure ProcUnitAttacked(aUnit, aAttacker: TKMUnit);
    procedure ProcUnitDied(aUnit: TKMUnit; aKillerOwner: TKMHandID);
    procedure ProcUnitDismissed(aUnit: TKMUnit);
    procedure ProcUnitTrained(aUnit: TKMUnit);
    procedure ProcUnitWounded(aUnit, aAttacker: TKMUnit);
    procedure ProcWareProduced(aHouse: TKMHouse; aWareType: TKMWareType; aCount: Integer);
    procedure ProcWarriorEquipped(aUnit: TKMUnit; aGroup: TKMUnitGroup);
    procedure ProcWarriorWalked(aUnit: TKMUnit; aToX, aToY: Integer);
    procedure ProcWinefieldBuilt(aPlayer: TKMHandID; aX, aY: Integer);
    procedure ProcWoodcuttersModeChanged(aHouse: TKMHouse; aOldMode: TKMWoodcutterMode; aNewMode: TKMWoodcutterMode);

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
  end;


var
  gScriptEvents: TKMScriptEvents;


implementation
uses
  uPSUtils,
  {$IFDEF WDC}
  System.RegularExpressions,
  {$ENDIF}
  {$IFDEF FPC}
  RegExpr,
  {$ENDIF}
  TypInfo, KromUtils,
  KM_Entity,
  KM_Game,
  KM_HandTypes,
  KM_ResTexts, KM_ResUnits,
  KM_Resource,
  KM_DevPerfLog, KM_DevPerfLogTypes,
  KM_CommonUtils;


type
  TKMScriptEventProc = procedure of object;
  TKMScriptEventProc1I = procedure (aIndex: Integer) of object;
  TKMScriptEventProc2I = procedure (aIndex, aParam: Integer) of object;
  TKMScriptEventProc3I = procedure (aIndex, aParam1, aParam2: Integer) of object;
  TKMScriptEventProc4I = procedure (aIndex, aParam1, aParam2, aParam3: Integer) of object;
  TKMScriptEventProc5I = procedure (aIndex, aParam1, aParam2, aParam3, aParam4: Integer) of object;
  TKMScriptEventProc1S = procedure (aParam: Single) of object;

  TKMScriptBeforeOrderSplitEvent = procedure (aIndex: Integer; var aParam1: TKMUnitType; var aParam2: Integer; var aParam3: Boolean) of object;

  //We need to check all input parameters as could be wildly off range due to
  //mistakes in scripts. In that case we have two options:
  // - skip silently and log
  // - report to player


function HouseTypeValid(aHouseType: Integer): Boolean; inline;
begin
  Result := (aHouseType in [Low(HOUSE_ID_TO_TYPE)..High(HOUSE_ID_TO_TYPE)])
            and (HOUSE_ID_TO_TYPE[aHouseType] <> htNone); //KaM index 26 is unused (htNone)
end;


{ TKMScriptEvents }
constructor TKMScriptEvents.Create(aExec: TPSExec; aPreProcessor: TPSPreProcessor; aIDCache: TKMScriptingIdCache);
begin
  inherited Create(aIDCache);

  fExec := aExec;
  fPreProcessor := aPreProcessor;
  fConsoleCommands := TDictionary<AnsiString, TKMConsoleCommand>.Create;

  AddDefaultEventHandlersNames;
end;


destructor TKMScriptEvents.Destroy;
var
  command: TKMConsoleCommand;
begin
  for command in fConsoleCommands.Values do
    command.Free;

  fConsoleCommands.Clear;

  FreeAndNil(fConsoleCommands);

  inherited;
end;


procedure TKMScriptEvents.AddDefaultEventHandlersNames;
var
  EVT: TKMScriptEventType;
begin
  for EVT := Low(TKMScriptEventType) to High(TKMScriptEventType) do
    // evtTick - > OnTick
    AddEventHandlerName(EVT, AnsiString(StringReplace(GetEnumName(TypeInfo(TKMScriptEventType), Integer(EVT)), 'evt', 'On', [])));
end;


procedure TKMScriptEvents.LinkEventsAndCommands;
var
  I: Integer;
  ET: TKMScriptEventType;
  cmdName: AnsiString;
begin
  //Link events
  for ET := Low(TKMScriptEventType) to High(TKMScriptEventType) do
    for I := Low(fEventHandlers[ET]) to High(fEventHandlers[ET]) do
    begin
      fEventHandlers[ET][I].Handler := fExec.GetProcAsMethodN(fEventHandlers[ET][I].ProcName);
      if (I > 0) //It's okay to not have default event handler
        and not MethodAssigned(fEventHandlers[ET][I].Handler) then
        fOnScriptError(sePreprocessorError,
                       Format('Declared custom handler ''%s'' for event ''%s'' not found',
                              [fEventHandlers[ET][I].ProcName, GetEnumName(TypeInfo(TKMScriptEventType), Integer(ET))]));
    end;

  //Link Console commands
  for cmdName in fConsoleCommands.Keys do
    fConsoleCommands.Items[cmdName].Handler := fExec.GetProcAsMethodN(fConsoleCommands.Items[cmdName].ProcName);
end;


function TKMScriptEvents.MethodAssigned(aProc: TMethod): Boolean;
begin
  Result := aProc.Code <> nil;
end;


function TKMScriptEvents.MethodAssigned(aEventType: TKMScriptEventType): Boolean;
var
  I: Integer;
begin
  if Self = nil then Exit(False);
  
  Result := False;
  for I := Low(fEventHandlers[aEventType]) to High(fEventHandlers[aEventType]) do
    if fEventHandlers[aEventType][I].Handler.Code <> nil then
      Exit(True);
end;


function TKMScriptEvents.MethodAssigned(const aCmdName: AnsiString): Boolean;
begin
  Result := False;
  if fConsoleCommands.ContainsKey(AnsiString(LowerCase(aCmdName)))
    and (fConsoleCommands.Items[AnsiString(LowerCase(aCmdName))].Handler.Code <> nil) then
    Exit(True);
end;


function TKMScriptEvents.GetConsoleCommand(const aName: AnsiString): TKMConsoleCommand;
begin
  Result := fConsoleCommands[AnsiString(LowerCase(aName))];
end;


function TKMScriptEvents.GetEventHandlers(aEvent: TKMScriptEventType): TKMCustomEventHandlerArray;
begin
  Result := fEventHandlers[aEvent];
end;


procedure TKMScriptEvents.AddEventHandlerName(aEventType: TKMScriptEventType; const aEventHandlerName: AnsiString);
var
  I, len: Integer;
begin
  Assert(Trim(aEventHandlerName) <> '', 'Can''t add empty event handler for event type: ' +
         GetEnumName(TypeInfo(TKMScriptEventType), Integer(aEventType)));
  for I := Low(fEventHandlers[aEventType]) to High(fEventHandlers[aEventType]) do
    if UpperCase(fEventHandlers[aEventType][I].ProcName) = UpperCase(aEventHandlerName) then
    begin
      fOnScriptError(sePreprocessorError,
                     Format('Duplicate event handler declaration ''%s'' for event ''%s''',
                     [aEventHandlerName, GetEnumName(TypeInfo(TKMScriptEventType), Integer(aEventType))]));
      Exit;
    end;

  len := Length(fEventHandlers[aEventType]);
  //todo: rewrite it not to enlarge array by 1 element
  SetLength(fEventHandlers[aEventType], len + 1);
  fEventHandlers[aEventType][len].ProcName := aEventHandlerName;
end;


procedure TKMScriptEvents.AddConsoleCommand(const aCmdName, aProcName: AnsiString);
begin
  Assert((Trim(aCmdName) <> '') and (Trim(aProcName) <> ''),
         Format('Console command name and procedure name should be specified: [CmdName = %s] [ProcName = [', [aCmdName, aProcName]));

  if fConsoleCommands.ContainsKey(AnsiString(LowerCase(aCmdName))) then
  begin
    fOnScriptError(sePreprocessorError,
                   Format('Duplicate command declaration: [%s] , command procedure: [%s]',
                   [aCmdName, aProcName]));
    Exit;
  end;

  fConsoleCommands.Add(AnsiString(LowerCase(aCmdName)), TKMConsoleCommand.Create(aCmdName, aProcName));
end;


procedure TKMScriptEvents.Save(SaveStream: TKMemoryStream);
var
  I: Integer;
  ET: TKMScriptEventType;
  cmdPair: TPair<AnsiString, TKMConsoleCommand>;
begin
  SaveStream.PlaceMarker('CustomScriptEvents');
  //Save custom events
  for ET := Low(TKMScriptEventType) to High(TKMScriptEventType) do
  begin
    SaveStream.Write(Byte(High(fEventHandlers[ET]))); //Save only (Count - 1) here (do not save default one)
    for I := 1 to High(fEventHandlers[ET]) do //Start from 1, as we do not need to save default (0) handler
      SaveStream.WriteA(fEventHandlers[ET][I].ProcName);
  end;

  //Save console commands
  SaveStream.Write(Integer(fConsoleCommands.Count));
  for cmdPair in fConsoleCommands do
    cmdPair.Value.Save(SaveStream);
end;


procedure TKMScriptEvents.Load(LoadStream: TKMemoryStream);
var
  I, cmdCount: Integer;
  cnt: Byte;
  handlerName: AnsiString;
  ET: TKMScriptEventType;
  command: TKMConsoleCommand;
begin
  LoadStream.CheckMarker('CustomScriptEvents');
  //Load custom events
  for ET := Low(TKMScriptEventType) to High(TKMScriptEventType) do
  begin
    LoadStream.Read(cnt); //We saved only custom event handler names (no need to save/load default one), then load them all
    for I := 0 to cnt - 1 do
    begin
      LoadStream.ReadA(handlerName);
      AddEventHandlerName(ET, handlerName);
    end;
  end;

  //Load console commands
  LoadStream.Read(cmdCount);
  for I := 0 to cmdCount - 1 do
  begin
    //Create new command instance
    //Commands destruction will be handled by fConsoleCommands TDictionary in TKMScriptEvents.Destroy
    command := TKMConsoleCommand.Create;
    command.Load(LoadStream);
    fConsoleCommands.Add(AnsiString(LowerCase(command.Name)), command);
  end;
end;


procedure TKMScriptEvents.CallEventHandlers(aEventType: TKMScriptEventType; const aParams: array of Integer;
                                            aFloatParam: Single = FLOAT_PARAM_NONE);
var
  I: Integer;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psScripting);
  {$ENDIF}
  try
    for I := Low(fEventHandlers[aEventType]) to High(fEventHandlers[aEventType]) do
      CallEventProc(fEventHandlers[aEventType][I], aParams, aFloatParam)
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psScripting);
    {$ENDIF}
  end;
end;


function TKMScriptEvents.HasConsoleCommands: Boolean;
begin
  Result := fConsoleCommands.Count > 0;
end;


function TKMScriptEvents.ParseConsoleCommandsProcedures(const aScriptCode: AnsiString): Boolean;
//Use const for ScriptValidator. We do not want to load txt libraries for it since it could be placed anywhere
const
  TX_SCRIPT_CONSOLE_CMD_PROC_NOT_FOUND_STR = 'The procedure [ %s ] declared for the script console command /%s was not found';

  function GetErrorStr: String;
  begin
    if gResTexts <> nil then
      Result := gResTexts[TX_SCRIPT_CONSOLE_CMD_PROC_NOT_FOUND]
    else
      Result := TX_SCRIPT_CONSOLE_CMD_PROC_NOT_FOUND_STR;
  end;

var
  I: Integer;
  cmdFound: Boolean;
  SL: TStringList;
  cmdPair: TPair<AnsiString, TKMConsoleCommand>;

  {$IFDEF WDC}
  RegEx: TRegEx;
  {$ENDIF}
  {$IFDEF FPC}
  RegEx: TRegExpr;
  {$ENDIF}
begin
  Result := False;
  SL := TStringList.Create;
  try
    SL.Text := aScriptCode;
    for cmdPair in fConsoleCommands do
    begin
      cmdFound := False;
      //Check procedure name with regular expression
      {$IFDEF WDC}
      RegEx := TRegEx.Create(Format('^\s*procedure\s+%s\s*\(.+\).*$', [cmdPair.Value.ProcName]), [roIgnoreCase]);
      {$ENDIF}
      {$IFDEF FPC}
      RegEx := TRegExpr.Create(Format('^\s*procedure\s+%s\s*\(.+\).*$', [CmdPair.Value.ProcName]));
      RegEx.ModifierI := True;
      {$ENDIF}
      for I := 0 to SL.Count - 1 do
      begin
        {$IFDEF WDC}
        if RegEx.Match(SL[I]).Success then
        {$ENDIF}
        {$IFDEF FPC}
        if RegEx.Exec(SL[I]) then
        {$ENDIF}
        begin
          cmdPair.Value.ParseParameters(SL[I], I + 1);
          cmdFound := True;
          Break;
        end;
      end;
      if not cmdFound then
        raise EConsoleCommandParseError.Create(Format(GetErrorStr,
                                                     [cmdPair.Value.ProcName, cmdPair.Value.Name]),
                                               0, 0, cmdPair.Value.ProcName);
    end;
  finally
    FreeAndNil(SL);
  end;
end;


function TKMScriptEvents.HasConsoleCommand(const aCmdName: AnsiString) : Boolean;
begin
  Result := MethodAssigned(aCmdName);
end;


//This procedure allows us to keep the exception handling code in one place
procedure TKMScriptEvents.HandleScriptProcCallError(const aMethod: String);
var
  exceptionProc: TPSProcRec;
  internalProc: TPSInternalProcRec;
  mainErrorStr, errorStr, detailedErrorStr: UnicodeString;
  pos, row, col: Cardinal;
  fileName: tbtstring;
  errorMessage: TKMScriptErrorMessage;
  res: TPSLineInfoResults;
  e: Exception;
begin
  e := Exception(AcquireExceptionObject);
  e.Message := e.Message + ''', raised by ' + aMethod;
  if ExceptionOutsideScript then
  begin
    ExceptionOutsideScript := False; //Reset
    raise e at ExceptAddr; //Exception was in game code not script, so pass up to madExcept
  end
  else
  begin
    ReleaseExceptionObject;
    detailedErrorStr := '';
    mainErrorStr := 'Exception in script: ''' + e.Message + '''';
    exceptionProc := fExec.GetProcNo(fExec.ExceptionProcNo);
    if exceptionProc is TPSInternalProcRec then
    begin
      internalProc := TPSInternalProcRec(exceptionProc);
      mainErrorStr := mainErrorStr + EolW + 'in method ''' + UnicodeString(internalProc.ExportName) + '''' + EolW;
      // With the help of uPSDebugger get information about error position in script code
      if (fExec is TPSDebugExec) and TPSDebugExec(fExec).TranslatePositionEx(fExec.LastExProc, fExec.LastExPos, pos, row, col, fileName) then
      begin
        //Get line according to preprocessor (includes and defines could affect error row/col)
        if fPreProcessor.CurrentLineInfo.GetLineInfo('', pos, res) then
        begin
          pos := res.Pos;
          row := res.Row;
          col := res.Col;
          fileName := res.Name;
        end;
        errorMessage := gGame.Scripting.GetErrorMessage('Error', '', ExtractFileName(fileName), row, col, pos);
        errorStr := mainErrorStr + errorMessage.GameMessage;
        detailedErrorStr := mainErrorStr + errorMessage.LogMessage;
      end
      else
      begin
        errorStr := mainErrorStr;
        detailedErrorStr := mainErrorStr;
      end;
    end;
    fOnScriptError(seException, errorStr, detailedErrorStr);
  end;
end;


procedure TKMScriptEvents.CallEventProc(const aProc: TKMCustomEventHandler; const aIntParams: array of Integer; aFloatParam: Single);
begin
  if not MethodAssigned(aProc.Handler) then Exit;

  try
    if aFloatParam <> FLOAT_PARAM_NONE then
      TKMScriptEventProc1S(aProc.Handler)(aFloatParam)
    else
    case Length(aIntParams) of
      0: TKMScriptEventProc(aProc.Handler);
      1: TKMScriptEventProc1I(aProc.Handler)(aIntParams[0]);
      2: TKMScriptEventProc2I(aProc.Handler)(aIntParams[0], aIntParams[1]);
      3: TKMScriptEventProc3I(aProc.Handler)(aIntParams[0], aIntParams[1], aIntParams[2]);
      4: TKMScriptEventProc4I(aProc.Handler)(aIntParams[0], aIntParams[1], aIntParams[2], aIntParams[3]);
      5: TKMScriptEventProc5I(aProc.Handler)(aIntParams[0], aIntParams[1], aIntParams[2], aIntParams[3], aIntParams[4]);
      else raise Exception.Create('Unexpected Length(aParams)');
    end;
  except
    HandleScriptProcCallError('script event handler ''' + aProc.ProcName + '''');
  end;
end;


procedure TKMScriptEvents.Clear;
var
  ET: TKMScriptEventType;
begin
  //Clear custom event handlers
  for ET := Low(TKMScriptEventType) to High(TKMScriptEventType) do
    SetLength(fEventHandlers[ET], 0);

  // Clear console commands
  fConsoleCommands.Clear;
end;


function TKMScriptEvents.CallConsoleCommand(aHandID: TKMHandID; const aCmdName: AnsiString; const aParams: TKMScriptCommandParamsArray): Boolean;
begin
  Result := False;
  if MethodAssigned(aCmdName) then
    try
      fConsoleCommands[AnsiString(LowerCase(aCmdName))].TryCallProcedure(aHandID, aParams);
      Result := True;
    except
      HandleScriptProcCallError('console command handler ''' + aCmdName + '''');
    end;
end;


//* Version: 6570
//* Occurs when a player places a beacon on the map.
procedure TKMScriptEvents.ProcBeacon(aPlayer: TKMHandID; aX, aY: Integer);
begin
  if MethodAssigned(evtBeacon) then
    CallEventHandlers(evtBeacon, [aPlayer, aX, aY]);
end;


//* Version: 7000+
//* Occurs when player built a field.
procedure TKMScriptEvents.ProcFieldBuilt(aPlayer: TKMHandID; aX, aY: Integer);
begin
  if MethodAssigned(evtFieldBuilt) then
    CallEventHandlers(evtFieldBuilt, [aPlayer, aX, aY]);
end;


//* Version: 6216
//* Occurs when a trade happens in a market (at the moment when resources are exchanged by serfs).
//* aFrom: as Integer from Lookup table
//* aTo: as Integer from Lookup table
procedure TKMScriptEvents.ProcMarketTrade(aMarket: TKMHouse; aFrom, aTo: Integer);
begin
  if MethodAssigned(evtMarketTrade) then
  begin
    fIDCache.CacheHouse(aMarket, aMarket.UID); //Improves cache efficiency since aMarket will probably be accessed soon
    CallEventHandlers(evtMarketTrade, [aMarket.UID, aFrom, aTo]);
  end;
end;


//* Version: 14000
//* Occurs when a trade happens in a market (at the moment when resources are exchanged by serfs).
//* aFrom: as TKMWareType
//* aTo: as TKMWareType
procedure TKMScriptEvents.ProcMarketTradeEx(aMarket: TKMHouse; aFrom, aTo: TKMWareType);
begin
  if MethodAssigned(evtMarketTradeEx) then
  begin
    fIDCache.CacheHouse(aMarket, aMarket.UID); //Improves cache efficiency since aMarket will probably be accessed soon
    CallEventHandlers(evtMarketTradeEx, [aMarket.UID, Ord(aFrom), Ord(aTo)]);
  end;
end;


procedure TKMScriptEvents.EventMarketTrade(aMarket: TKMHouse; aFrom, aTo: TKMWareType);
begin
  ProcMarketTrade(aMarket, WARE_TY_TO_ID[aFrom], WARE_TY_TO_ID[aTo]);
  ProcMarketTradeEx(aMarket, aFrom, aTo);
end;


//* Version: 5057
//* Occurs immediately after the mission is loaded.
procedure TKMScriptEvents.ProcMissionStart;
begin
  if MethodAssigned(evtMissionStart) then
    CallEventHandlers(evtMissionStart, []);
end;


//* Version: 11000
//* Occurs immediately after the end of peacetime
procedure TKMScriptEvents.ProcPeacetimeEnd;
begin
  if MethodAssigned(evtPeacetimeEnd) then
    CallEventHandlers(evtPeacetimeEnd, []);
end;


//* Version: 5057
//* Occurs every game logic update.
procedure TKMScriptEvents.ProcTick;
begin
  if MethodAssigned(evtTick) then
    CallEventHandlers(evtTick, []);
end;


//* Version: 5057
//* Occurs when player has built a house.
procedure TKMScriptEvents.ProcHouseBuilt(aHouse: TKMHouse);
begin
  if MethodAssigned(evtHouseBuilt) then
  begin
    fIDCache.CacheHouse(aHouse, aHouse.UID); //Improves cache efficiency since aHouse will probably be accessed soon
    CallEventHandlers(evtHouseBuilt, [aHouse.UID]);
  end;
end;


//* Version: 5882
//* Occurs when a house gets damaged (e.g. by the enemy soldier).
//* Attacker is -1 the house was damaged some other way, such as from Actions.HouseAddDamage.
procedure TKMScriptEvents.ProcHouseDamaged(aHouse: TKMHouse; aAttacker: TKMUnit);
begin
  if MethodAssigned(evtHouseDamaged) then
  begin
    fIDCache.CacheHouse(aHouse, aHouse.UID); //Improves cache efficiency since aHouse will probably be accessed soon
    if aAttacker <> nil then
    begin
      fIDCache.CacheUnit(aAttacker, aAttacker.UID); //Improves cache efficiency since aAttacker will probably be accessed soon
      CallEventHandlers(evtHouseDamaged, [aHouse.UID, aAttacker.UID]);
    end
    else
      //House was damaged, but we don't know by whom (e.g. by script command)
      CallEventHandlers(evtHouseDamaged, [aHouse.UID, HAND_NONE]);
  end;
end;

//* Version: 15250
//* Occurs when a house delivery mode changed.
procedure TKMScriptEvents.ProcHouseDeliveryModeChanged(aHouse: TKMHouse; aOldMode: TKMDeliveryMode; aNewMode: TKMDeliveryMode);
begin
  if MethodAssigned(evtHouseDeliveryModeChanged) then
  begin
    fIDCache.CacheHouse(aHouse, aHouse.UID); //Improves cache efficiency since aHouse will probably be accessed soon
    CallEventHandlers(evtHouseDeliveryModeChanged, [aHouse.UID, ord(aOldMode), ord(aNewMode)]);
  end;
end;

//* Version: 5407
//* Occurs when a house is destroyed.
//* If DestroyerIndex is -1 the house was destroyed some other way, such as from Actions.HouseDestroy.
//* If DestroyerIndex is the same as the house owner (States.HouseOwner), the house was demolished by the player who owns it.
//* Otherwise it was destroyed by an enemy.
//* Called just before the house is destroyed so HouseID is usable only during this event, and the area occupied by the house is still unusable.
//* aDestroyerIndex: Index of player who destroyed it
procedure TKMScriptEvents.ProcHouseDestroyed(aHouse: TKMHouse; aDestroyerIndex: TKMHandID);
begin
  if MethodAssigned(evtHouseDestroyed) then
  begin
    fIDCache.CacheHouse(aHouse, aHouse.UID); //Improves cache efficiency since aHouse will probably be accessed soon
    CallEventHandlers(evtHouseDestroyed, [aHouse.UID, aDestroyerIndex]);
  end;
end;


//* Version: 15250
//* aOldX, aOldY - Coordinates of the previous FlagPoint position
//* aNewX, aNewY - Coordinates of the new FlagPoint position
//* Occurs when a house flag point position is changed
procedure TKMScriptEvents.ProcHouseFlagPointChanged(aHouse: TKMHouse; aOldX, aOldY, aNewX, aNewY: Integer);
begin
  if MethodAssigned(evtHouseFlagPointChanged) then
  begin
    fIDCache.CacheHouse(aHouse, aHouse.UID); //Improves cache efficiency since aHouse will probably be accessed soon
    CallEventHandlers(evtHouseFlagPointChanged, [aHouse.UID, aOldX, aOldY, aNewX, aNewY]);
  end;
end;


//* Version: 13700
//* Occurs when a house gets repaired.
//* The event gets fired for each repair action
//* aHouse: House ID
//* aRepairAmount: how much house was repaired
//* aDamage: house damage after repairement
procedure TKMScriptEvents.ProcHouseRepaired(aHouse: TKMHouse; aRepairAmount, aDamage: Integer);
begin
  if MethodAssigned(evtHouseRepaired) then
  begin
    fIDCache.CacheHouse(aHouse, aHouse.UID); //Improves cache efficiency since aHouse will probably be accessed soon
    CallEventHandlers(evtHouseRepaired, [aHouse.UID, aRepairAmount, aDamage]);
  end;
end;


//* Version: 10750
//* Occurs when ware count is changed in house
//* aCnt: current ware count in house (after change)
//* aChangeCnt: ware change count. if aChangeCnt > 0 count increased, if aChangeCnt < 0 count decreased
procedure TKMScriptEvents.ProcHouseWareCountChanged(aHouse: TKMHouse; aWare: TKMWareType; aCnt, aChangeCnt: Integer);
begin
  if MethodAssigned(evtHouseWareCountChanged) then
  begin
    fIDCache.CacheHouse(aHouse, aHouse.UID); //Improves cache efficiency since aHouse will probably be accessed soon
    CallEventHandlers(evtHouseWareCountChanged, [aHouse.UID, Ord(aWare), aCnt, aChangeCnt]);
  end;
end;


//* Version: 11000
//* Occurs when game speed was changed
procedure TKMScriptEvents.ProcGameSpeedChanged(aSpeed: Single);
begin
  if MethodAssigned(evtGameSpeedChanged) then
    CallEventHandlers(evtGameSpeedChanged, [], aSpeed);
end;


//* Version: 6114
//* Occurs after a house is destroyed and has been completely removed from the game,
//* meaning the area it previously occupied can be used.
//* If you need more information about the house use the OnHouseDestroyed event.
//* aHouseType as Integer from Lookup table
procedure TKMScriptEvents.ProcHouseAfterDestroyed(aHouseType: Integer; aOwner: TKMHandID; aX, aY: Integer);
begin
  if MethodAssigned(evtHouseAfterDestroyed) then
    CallEventHandlers(evtHouseAfterDestroyed, [aHouseType, aOwner, aX, aY]);
end;


//* Version: 14000
//* Occurs after a house is destroyed and has been completely removed from the game,
//* meaning the area it previously occupied can be used.
//* If you need more information about the house use the OnHouseDestroyed event.
//* aHouseType: as TKMHouseType
procedure TKMScriptEvents.ProcHouseAfterDestroyedEx(aHouseType: TKMHouseType; aOwner: TKMHandID; aX, aY: Integer);
begin
  if MethodAssigned(evtHouseAfterDestroyedEx) then
    CallEventHandlers(evtHouseAfterDestroyedEx, [Ord(aHouseType), aOwner, aX, aY]);
end;


procedure TKMScriptEvents.EventHouseAfterDestroyed(aHouseType: TKMHouseType; aOwner: TKMHandID; aX, aY: Integer);
begin
  ProcHouseAfterDestroyed(HOUSE_TYPE_TO_ID[aHouseType] - 1, aOwner, aX, aY);
  ProcHouseAfterDestroyedEx(aHouseType, aOwner, aX, aY);
end;


//* Version: 7000+
//* Occurs when house plan is digged.
procedure TKMScriptEvents.ProcHousePlanDigged(aHouse: TKMHouse);
begin
  if MethodAssigned(evtHousePlanDigged) then
  begin
    fIDCache.CacheHouse(aHouse, aHouse.UID); //Improves cache efficiency since aHouse will probably be accessed soon
    CallEventHandlers(evtHousePlanDigged, [aHouse.UID]);
  end;
end;


//* Version: 5871
//* Occurs when player has placed a house plan.
//* aHouseType: as Integer from Lookup table
procedure TKMScriptEvents.ProcHousePlanPlaced(aPlayer: TKMHandID; aX, aY, aHouseType: Integer);
begin
  if MethodAssigned(evtHousePlanPlaced) then
    CallEventHandlers(evtHousePlanPlaced, [aPlayer, aX, aY, aHouseType]);
end;


//* Version: 14000
//* Occurs when player has placed a house plan.
//* aHouseType: as TKMHouseType
procedure TKMScriptEvents.ProcHousePlanPlacedEx(aPlayer: TKMHandID; aX, aY: Integer; aHouseType: TKMHouseType);
begin
  if MethodAssigned(evtHousePlanPlacedEx) then
    CallEventHandlers(evtHousePlanPlacedEx, [aPlayer, aX, aY, Ord(aHouseType)]);
end;


procedure TKMScriptEvents.EventHousePlanPlaced(aPlayer: TKMHandID; aX, aY: Integer; aType: TKMHouseType);
begin
  ProcHousePlanPlaced(aPlayer, aX + gRes.Houses[aType].EntranceOffsetX, aY, HOUSE_TYPE_TO_ID[aType] - 1);
  ProcHousePlanPlacedEx(aPlayer, aX + gRes.Houses[aType].EntranceOffsetX, aY, aType);
end;


//* Version: 6298
//* Occurs when player has removed a house plan.
//* aHouseType: as Integer from Lookup table
procedure TKMScriptEvents.ProcHousePlanRemoved(aPlayer: TKMHandID; aX, aY, aHouseType: Integer);
begin
  if MethodAssigned(evtHousePlanRemoved) then
    CallEventHandlers(evtHousePlanRemoved, [aPlayer, aX, aY, aHouseType]);
end;


//* Version: 14000
//* Occurs when player has removed a house plan.
//* aHouseType: as TKMHouseType
procedure TKMScriptEvents.ProcHousePlanRemovedEx(aPlayer: TKMHandID; aX, aY: Integer; aHouseType: TKMHouseType);
begin
  if MethodAssigned(evtHousePlanRemovedEx) then
    CallEventHandlers(evtHousePlanRemovedEx, [aPlayer, aX, aY, Ord(aHouseType)]);
end;


procedure TKMScriptEvents.EventHousePlanRemoved(aPlayer: TKMHandID; aX, aY: Integer; aType: TKMHouseType);
begin
  ProcHousePlanRemoved(aPlayer, aX + gRes.Houses[aType].EntranceOffsetX, aY, HOUSE_TYPE_TO_ID[aType] - 1);
  ProcHousePlanRemovedEx(aPlayer, aX + gRes.Houses[aType].EntranceOffsetX, aY, aType);
end;


//* Version: 6220
//* Occurs when the player would be shown a message about a group being hungry
//* (when they first get hungry, then every 4 minutes after that if there are still hungry group members).
//* Occurs regardless of whether the group has hunger messages enabled or not.
procedure TKMScriptEvents.ProcGroupHungry(aGroup: TKMUnitGroup);
begin
  if MethodAssigned(evtGroupHungry) then
  begin
    fIDCache.CacheGroup(aGroup, aGroup.UID); //Improves cache efficiency since aGroup will probably be accessed soon
    CallEventHandlers(evtGroupHungry, [aGroup.UID]);
  end;
end;


//* Version: 7000+
//* Occurs when the group gets order to attack house
//* aGroup: attackers group ID
//* aHouse: target house ID
procedure TKMScriptEvents.ProcGroupOrderAttackHouse(aGroup: TKMUnitGroup; aHouse: TKMHouse);
begin
  if MethodAssigned(evtGroupOrderAttackHouse) then
  begin
    fIDCache.CacheGroup(aGroup, aGroup.UID); //Improves cache efficiency since aGroup will probably be accessed soon
    fIDCache.CacheHouse(aHouse, aHouse.UID); //Improves cache efficiency since aHouse will probably be accessed soon
    CallEventHandlers(evtGroupOrderAttackHouse, [aGroup.UID, aHouse.UID]);
  end;
end;


//* Version: 7000+
//* Occurs when the group gets order to attack unit
//* aGroup: attackers group ID
//* aUnit: target unit ID
procedure TKMScriptEvents.ProcGroupOrderAttackUnit(aGroup: TKMUnitGroup; aUnit: TKMUnit);
begin
  if MethodAssigned(evtGroupOrderAttackUnit) then
  begin
    fIDCache.CacheGroup(aGroup, aGroup.UID); //Improves cache efficiency since aGroup will probably be accessed soon
    fIDCache.CacheUnit(aUnit, aUnit.UID);    //Improves cache efficiency since aUnit will probably be accessed soon
    CallEventHandlers(evtGroupOrderAttackUnit, [aGroup.UID, aUnit.UID]);
  end;
end;


//* Version: 11200
//* Occurs right before the group gets order to split.
//* Split parameters could be altered by script and returned to the game to be used there
//* aGroup: group ID, which got split order
//* aNewType: new group leader unit type
//* aNewCnt: new group members count
//* aMixed: is new group can have the only unit type or it can have any unit type from original group
procedure TKMScriptEvents.ProcGroupBeforeOrderSplit(aGroup: TKMUnitGroup; var aNewType: TKMUnitType; var aNewCnt: Integer; var aMixed: Boolean);
var
  I: Integer;
  handler: TMethod;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psScripting);
  {$ENDIF}
  try
    if MethodAssigned(evtGroupBeforeOrderSplit) then
    begin
      fIDCache.CacheGroup(aGroup, aGroup.UID); //Improves cache efficiency since aGroup will probably be accessed soon
      for I := Low(fEventHandlers[evtGroupBeforeOrderSplit]) to High(fEventHandlers[evtGroupBeforeOrderSplit]) do
      begin
        handler := fEventHandlers[evtGroupBeforeOrderSplit][I].Handler;
        if MethodAssigned(handler) then
          try
            TKMScriptBeforeOrderSplitEvent(handler)(aGroup.UID, aNewType, aNewCnt, aMixed);
          except
            HandleScriptProcCallError('script event handler ''' + fEventHandlers[evtGroupBeforeOrderSplit][I].ProcName + '''');
          end;
      end;
    end;
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psScripting);
    {$ENDIF}
  end;
end;


//* Version: 7000+
//* Occurs when the group gets order to move to some point
//* aGroup: group ID
//* aX, aY: Point coordinates
procedure TKMScriptEvents.ProcGroupOrderMove(aGroup: TKMUnitGroup; aX, aY: Integer; aDir: TKMDirection);
begin
  if MethodAssigned(evtGroupOrderMove) then
  begin
    fIDCache.CacheGroup(aGroup, aGroup.UID); //Improves cache efficiency since aGroup will probably be accessed soon
    CallEventHandlers(evtGroupOrderMove, [aGroup.UID, aX, aY, Ord(aDir)]);
  end;
end;


//* Version: 7000+
//* Occurs when the group1 gets order to link to group2
//* aGroup1: link group ID
//* aGroup2: link target group ID
procedure TKMScriptEvents.ProcGroupOrderLink(aGroup1, aGroup2: TKMUnitGroup);
begin
  if MethodAssigned(evtGroupOrderLink) then
  begin
    fIDCache.CacheGroup(aGroup1, aGroup1.UID); //Improves cache efficiency since aGroup1 will probably be accessed soon
    fIDCache.CacheGroup(aGroup2, aGroup2.UID); //Improves cache efficiency since aGroup2 will probably be accessed soon
    CallEventHandlers(evtGroupOrderLink, [aGroup1.UID, aGroup2.UID]);
  end;
end;


//* Version: 7000+
//* Occurs when the group gets order to split
//* aGroup: group ID
//* aNewGroup: splitted group ID
procedure TKMScriptEvents.ProcGroupOrderSplit(aGroup, aNewGroup: TKMUnitGroup);
begin
  if MethodAssigned(evtGroupOrderSplit) then
  begin
    fIDCache.CacheGroup(aGroup, aGroup.UID);       //Improves cache efficiency since aGroup will probably be accessed soon
    fIDCache.CacheGroup(aNewGroup, aNewGroup.UID); //Improves cache efficiency since aNewGroup will probably be accessed soon
    CallEventHandlers(evtGroupOrderSplit, [aGroup.UID, aNewGroup.UID]);
  end;
end;


//* Version: 5407
//* Occurs when a unit dies. If KillerIndex is -1 the unit died from another cause such as hunger or Actions.UnitKill.
//* Called just before the unit is killed so UnitID is usable only during this event,
//* and the tile occupied by the unit is still taken.
//* aKillerOwner: Index of player who killed it
procedure TKMScriptEvents.ProcUnitDied(aUnit: TKMUnit; aKillerOwner: TKMHandID);
begin
  if MethodAssigned(evtUnitDied) then
  begin
    fIDCache.CacheUnit(aUnit, aUnit.UID); //Improves cache efficiency since aUnit will probably be accessed soon
    CallEventHandlers(evtUnitDied, [aUnit.UID, aKillerOwner]);
  end;
end;

//* Version: 15250
//* Occurs when a unit is dissmised.
//* Called just before the unit is dissmised so UnitID is usable only during this event,
//* and the tile occupied by the unit is still taken.
procedure TKMScriptEvents.ProcUnitDismissed(aUnit: TKMUnit);
begin
  if MethodAssigned(evtUnitDismissed) then
  begin
    fIDCache.CacheUnit(aUnit, aUnit.UID); //Improves cache efficiency since aUnit will probably be accessed soon
    CallEventHandlers(evtUnitDismissed, [aUnit.UID]);
  end;
end;


//* Version: 6114
//* Occurs after a unit has died and has been completely removed from the game, meaning the tile it previously occupied can be used.
//* If you need more information about the unit use the OnUnitDied event.
//* Note: Because units have a death animation there is a delay of several ticks between OnUnitDied and OnUnitAfterDied.
//* aUnitType: as Integer from Lookup table
procedure TKMScriptEvents.ProcUnitAfterDied(aUnitType: Integer; aOwner: TKMHandID; aX, aY: Integer);
begin
  if MethodAssigned(evtUnitAfterDied) then
    CallEventHandlers(evtUnitAfterDied, [aUnitType, aOwner, aX, aY]);
end;


//* Version: 14000
//* Occurs after a unit has died and has been completely removed from the game, meaning the tile it previously occupied can be used.
//* If you need more information about the unit use the OnUnitDied event.
//* Note: Because units have a death animation there is a delay of several ticks between OnUnitDied and OnUnitAfterDied.
//* aUnitType: as TKMUnitType
procedure TKMScriptEvents.ProcUnitAfterDiedEx(aUnitType: TKMUnitType; aOwner: TKMHandID; aX, aY: Integer);
begin
  if MethodAssigned(evtUnitAfterDiedEx) then
    CallEventHandlers(evtUnitAfterDiedEx, [Ord(aUnitType), aOwner, aX, aY]);
end;


procedure TKMScriptEvents.EventUnitAfterDied(aUnitType: TKMUnitType; aOwner: TKMHandID; aX, aY: Integer);
begin
  ProcUnitAfterDied(UNIT_TYPE_TO_ID[aUnitType], aOwner, aX, aY);
  ProcUnitAfterDiedEx(aUnitType, aOwner, aX, aY);
end;


//* Version: 6587
//* Happens when a unit is attacked (shot at by archers, hit in melee, or shot by a tower).
//* Attacker can be a warrior, recruit in tower or unknown (-1).
//* This event will occur very frequently during battles.
//* aAttacker: Unit who attacked the unit
procedure TKMScriptEvents.ProcUnitAttacked(aUnit, aAttacker: TKMUnit);
begin
  if MethodAssigned(evtUnitAttacked) then
  begin
    fIDCache.CacheUnit(aUnit, aUnit.UID); //Improves cache efficiency since aUnit will probably be accessed soon
    if aAttacker <> nil then
    begin
      fIDCache.CacheUnit(aAttacker, aAttacker.UID); //Improves cache efficiency since aAttacker will probably be accessed soon
      CallEventHandlers(evtUnitAttacked, [aUnit.UID, aAttacker.UID]);
    end
    else
      CallEventHandlers(evtUnitAttacked, [aUnit.UID, -1]);
  end;
end;


//* Version: 5057
//* Occurs when player trains a unit.
procedure TKMScriptEvents.ProcUnitTrained(aUnit: TKMUnit);
begin
  if MethodAssigned(evtUnitTrained) then
  begin
    fIDCache.CacheUnit(aUnit, aUnit.UID); //Improves cache efficiency since aUnit will probably be accessed soon
    CallEventHandlers(evtUnitTrained, [aUnit.UID]);
  end;
end;


//* Version: 5884
//* Happens when unit is wounded.
//* Attacker can be a warrior, recruit in tower or unknown (-1).
//* aAttacker: Unit who attacked the unit
procedure TKMScriptEvents.ProcUnitWounded(aUnit, aAttacker: TKMUnit);
begin
  if MethodAssigned(evtUnitWounded) then
  begin
    fIDCache.CacheUnit(aUnit, aUnit.UID); //Improves cache efficiency since aUnit will probably be accessed soon
    if aAttacker <> nil then
    begin
      fIDCache.CacheUnit(aAttacker, aAttacker.UID); //Improves cache efficiency since aAttacker will probably be accessed soon
      CallEventHandlers(evtUnitWounded, [aUnit.UID, aAttacker.UID]);
    end
    else
      CallEventHandlers(evtUnitWounded, [aUnit.UID, HAND_NONE]);
  end;
end;


//* Version: 5057
//* Occurs when player equips a warrior.
procedure TKMScriptEvents.ProcWarriorEquipped(aUnit: TKMUnit; aGroup: TKMUnitGroup);
begin
  if MethodAssigned(evtWarriorEquipped) then
  begin
    fIDCache.CacheUnit(aUnit, aUnit.UID); //Improves cache efficiency since aUnit will probably be accessed soon
    fIDCache.CacheGroup(aGroup, aGroup.UID);
    CallEventHandlers(evtWarriorEquipped, [aUnit.UID, aGroup.UID]);
  end;
end;


//* Version: 7000+
//* Occurs when road plan is digged.
procedure TKMScriptEvents.ProcPlanRoadDigged(aPlayer: TKMHandID; aX, aY: Integer);
begin
  if MethodAssigned(evtPlanRoadDigged) then
    CallEventHandlers(evtPlanRoadDigged, [aPlayer, aX, aY]);
end;


//* Version: 5964
//* Occurs when player has placed a road plan.
procedure TKMScriptEvents.ProcPlanRoadPlaced(aPlayer: TKMHandID; aX, aY: Integer);
begin
  if MethodAssigned(evtPlanRoadPlaced) then
    CallEventHandlers(evtPlanRoadPlaced, [aPlayer, aX, aY]);
end;


//* Version: 6301
//* Occurs when player has removed a road plan.
procedure TKMScriptEvents.ProcPlanRoadRemoved(aPlayer: TKMHandID; aX, aY: Integer);
begin
  if MethodAssigned(evtPlanRoadRemoved) then
    CallEventHandlers(evtPlanRoadRemoved, [aPlayer, aX, aY]);
end;


//* Version: 5964
//* Occurs when player has placed a field plan.
procedure TKMScriptEvents.ProcPlanFieldPlaced(aPlayer: TKMHandID; aX, aY: Integer);
begin
  if MethodAssigned(evtPlanFieldPlaced) then
    CallEventHandlers(evtPlanFieldPlaced, [aPlayer, aX, aY]);
end;


//* Version: 6301
//* Occurs when player has removed a field plan.
procedure TKMScriptEvents.ProcPlanFieldRemoved(aPlayer: TKMHandID; aX, aY: Integer);
begin
  if MethodAssigned(evtPlanFieldRemoved) then
    CallEventHandlers(evtPlanFieldRemoved, [aPlayer, aX, aY]);
end;


//* Version: 7000+
//* Occurs when winefield is digged
procedure TKMScriptEvents.ProcPlanWinefieldDigged(aPlayer: TKMHandID; aX, aY: Integer);
begin
  if MethodAssigned(evtPlanWinefieldDigged) then
    CallEventHandlers(evtPlanWinefieldDigged, [aPlayer, aX, aY]);
end;


//* Version: 5964
//* Occurs when player has placed a wine field plan.
procedure TKMScriptEvents.ProcPlanWinefieldPlaced(aPlayer: TKMHandID; aX, aY: Integer);
begin
  if MethodAssigned(evtPlanWinefieldPlaced) then
    CallEventHandlers(evtPlanWinefieldPlaced, [aPlayer, aX, aY]);
end;


//* Version: 6301
//* Occurs when player has removed a wine field plan.
procedure TKMScriptEvents.ProcPlanWinefieldRemoved(aPlayer: TKMHandID; aX, aY: Integer);
begin
  if MethodAssigned(evtPlanWinefieldRemoved) then
    CallEventHandlers(evtPlanWinefieldRemoved, [aPlayer, aX, aY]);
end;


//* Version: 5057
//* Occurs when certain player has been defeated.
//* Defeat conditions are checked separately by Player AI.
procedure TKMScriptEvents.ProcPlayerDefeated(aPlayer: TKMHandID);
begin
  if MethodAssigned(evtPlayerDefeated) then
    CallEventHandlers(evtPlayerDefeated, [aPlayer]);
end;


//* Version: 5057
//* Occurs when certain player is declared victorious.
//* Victory conditions are checked separately by Player AI.
procedure TKMScriptEvents.ProcPlayerVictory(aPlayer: TKMHandID);
begin
  if MethodAssigned(evtPlayerVictory) then
    CallEventHandlers(evtPlayerVictory, [aPlayer]);
end;


//* Version: 7000+
//* Occurs when player built a road.
procedure TKMScriptEvents.ProcRoadBuilt(aPlayer: TKMHandID; aX, aY: Integer);
begin
  if MethodAssigned(evtRoadBuilt) then
    CallEventHandlers(evtRoadBuilt, [aPlayer, aX, aY]);
end;


//* Version: 7000+
//* Occurs when player built a winefield.
procedure TKMScriptEvents.ProcWinefieldBuilt(aPlayer: TKMHandID; aX, aY: Integer);
begin
  if MethodAssigned(evtWinefieldBuilt) then
    CallEventHandlers(evtWinefieldBuilt, [aPlayer, aX, aY]);
end;


//* Version: 14000
//* Occurs when resource is produced for specified house.
procedure TKMScriptEvents.ProcWareProduced(aHouse: TKMHouse; aWareType: TKMWareType; aCount: Integer);
begin
  if MethodAssigned(evtWareProduced) and (aWareType <> wtNone) then
  begin
    fIDCache.CacheHouse(aHouse, aHouse.UID); //Improves cache efficiency since aHouse will probably be accessed soon
    CallEventHandlers(evtWareProduced, [aHouse.UID, Ord(aWareType), aCount]);
  end;
end;


//* Version: 7000+
//* Occurs when warrior walk
procedure TKMScriptEvents.ProcWarriorWalked(aUnit: TKMUnit; aToX, aToY: Integer);
begin
  if MethodAssigned(evtWarriorWalked) then
  begin
    fIDCache.CacheUnit(aUnit, aUnit.UID); //Improves cache efficiency since aUnit will probably be accessed soon
    CallEventHandlers(evtWarriorWalked, [aUnit.UID, aToX, aToY]);
  end;
end;

//* Version: 15250
//* Occurs when woodcutters mode changed.
procedure TKMScriptEvents.ProcWoodcuttersModeChanged(aHouse: TKMHouse; aOldMode: TKMWoodcutterMode; aNewMode: TKMWoodcutterMode);
begin
  if MethodAssigned(evtWoodcuttersModeChanged) then
  begin
    fIDCache.CacheHouse(aHouse, aHouse.UID); //Improves cache efficiency since aHouse will probably be accessed soon
    CallEventHandlers(evtWoodcuttersModeChanged, [aHouse.UID, ord(aOldMode), ord(aNewMode)]);
  end;
end;

{ TKMScriptEntity }
constructor TKMScriptEntity.Create(aIDCache: TKMScriptingIdCache);
begin
  inherited Create;
  fIDCache := aIDCache;
end;


procedure TKMScriptEntity.LogWarning(const aFuncName, aWarnMsg: String);
begin
  fOnScriptError(seLog, 'Warning in ' + aFuncName + ': ' + aWarnMsg);
end;


procedure TKMScriptEntity.LogIntParamWarn(const aFuncName: string; const aValues: array of Integer);
var
  I: Integer;
  values: string;
begin
  values := '';

  for I := Low(aValues) to High(aValues) do
    values := values + String(IntToStr(aValues[I])) + IfThen(I <> High(aValues), ', ');

  fOnScriptError(seInvalidParameter, 'Invalid parameter(s) passed to ' + aFuncName + ': ' + values);
end;


procedure TKMScriptEntity.LogParamWarn(const aFuncName: String; aValues1, aValues2: array of const);
var
  str1, str2: string;
begin
  str1 := VarRecArrToStr(aValues1);
  str2 := VarRecArrToStr(aValues2);

  fOnScriptError(seInvalidParameter, Format('Invalid parameter(s) passed to %s: %s, [%s]', [aFuncName, str1, str2]));
end;


procedure TKMScriptEntity.LogParamWarn(const aFuncName: String; const aValues: array of const);
var
  str: string;
begin
  str := VarRecArrToStr(aValues);

  fOnScriptError(seInvalidParameter, 'Invalid parameter(s) passed to ' + aFuncName + ': ' + str);
end;


end.
