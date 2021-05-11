unit KM_Console;
{$I KaM_Remake.inc}
interface
uses
  Generics.Collections,
  KM_CommonTypes, KM_NetworkTypes;


type
  TKMChatMode = (cmAll, cmTeam, cmSpectators, cmWhisper);

  TKMConsole = class
  private
    fLastConsoleTime: Cardinal;
    fHistory: TList<String>;
    fCurrConsoleHistoryId: Integer;
    fOnChange: TEvent;
    fOnPost: TUnicodeStringEvent;
    fOnPostLocal: TUnicodeStringEvent;
    fOnError: TUnicodeStringEvent;
    fMessages: UnicodeString;

    procedure SetMessages(const aMessages: UnicodeString);

    function TryDoCallConsoleCommand: Boolean;
  public
    Text: UnicodeString;

    constructor Create;
    destructor Destroy; override;

    property Messages: UnicodeString read fMessages write SetMessages;

    property OnPost: TUnicodeStringEvent read fOnPost write fOnPost;
    property OnPostLocal: TUnicodeStringEvent read fOnPostLocal write fOnPostLocal;
    property OnError: TUnicodeStringEvent read fOnError write fOnError;
    property OnChange: TEvent read fOnChange write fOnChange;

    procedure Post(aPropagate: Boolean = True);
    function IsPostAllowed: Boolean;
    function TryCallConsoleCommand: Boolean;

    function GetNextHistoryMsg: UnicodeString;
    function GetPrevHistoryMsg: UnicodeString;

    procedure Add(const aMessage: UnicodeString);
    procedure AddLine(const aMessage: UnicodeString);

    procedure Clear; virtual;
  end;


  TKMChat = class(TKMConsole)
  private
    fMode: TKMChatMode;
    procedure SetMode(aMode: TKMChatMode);
  public
    WhisperRecipient: TKMNetHandleIndex;

    constructor Create;
    destructor Destroy; override;

    property Mode: TKMChatMode read fMode write SetMode;

    procedure Clear; override;
  end;


var
  gChat: TKMChat;

const
  CHAT_COOLDOWN = 500;  //Minimum time in milliseconds between chat messages
  CHAT_TAG: array[TKMChatMode] of Integer = (
    -1,  //cmAll
    -2,  //cmTeam
    -3,  //cmSpectators
    -1); //cmWhisper

  
implementation
uses
  Math, SysUtils, StrUtils,
  KM_ResTexts,
  KM_ScriptingEvents, KM_ScriptingConsoleCommands,
  KM_Game, KM_GameInputProcess,
  KM_CommonUtils, KM_Defaults;

const
  DEF_CURR_CONSOLE_HISTORY_ID = -1;


{ TKMConsole }
constructor TKMConsole.Create;
begin
  inherited;

  fHistory := TList<String>.Create;

  Clear;
end;


destructor TKMConsole.Destroy;
begin
  FreeAndNil(fHistory);

  inherited;
end;


procedure TKMConsole.Clear;
begin
  fLastConsoleTime := 0;
  fHistory.Clear;
  fCurrConsoleHistoryId := DEF_CURR_CONSOLE_HISTORY_ID;
  Messages := '';
  Text := '';
end;


procedure TKMConsole.SetMessages(const aMessages: UnicodeString);
begin
  fMessages := aMessages;
end;


function TKMConsole.GetNextHistoryMsg: UnicodeString;
begin
  if fHistory.Count = 0 then
  begin
    Result := '';
    Exit;
  end;

  fCurrConsoleHistoryId := Min(fCurrConsoleHistoryId + 1, fHistory.Count - 1);
  Result := fHistory[fCurrConsoleHistoryId];
end;


function TKMConsole.GetPrevHistoryMsg: UnicodeString;
begin
  if fHistory.Count = 0 then Exit('');

  fCurrConsoleHistoryId := Max(0, fCurrConsoleHistoryId - 1);
  Result := fHistory[fCurrConsoleHistoryId];
end;


procedure TKMConsole.Add(const aMessage: UnicodeString);
begin
  fMessages := fMessages + aMessage;

  if Assigned(fOnChange) then
    fOnChange;
end;


procedure TKMConsole.AddLine(const aMessage: UnicodeString);
begin
  if fMessages <> '' then
  begin
    //if not fMessages.EndsWith('[]') then
    if not EndsText('[]', fMessages) then
      fMessages := fMessages + '[]';
    fMessages := fMessages + '|';
  end;

  Add(aMessage);
end;


function TKMConsole.IsPostAllowed : Boolean;
begin
  Result := (Trim(Text) <> '') and (TimeSince(fLastConsoleTime) >= CHAT_COOLDOWN)
end;


function TKMConsole.TryCallConsoleCommand: Boolean;
begin
  Result := False;
  if gGame = nil then //Can't manage console commands while not in the game
    Exit;

  // Text starts with / and its long enough to have some script command in there
  if (Length(Text) > 1) and (Text[1] = '/') then
  begin
    if (Text[2] = '/') then
      Delete(Text, 1, 1) //Remove one of the /'s
    else
    begin
      TryDoCallConsoleCommand;
      //Add command to history, but do not propagate post to others
      Post(False);
      Result := True;
    end;
  end;
end;


function TKMConsole.TryDoCallConsoleCommand: Boolean;
var
  I, paramsI, procParamsCnt, spacePos: Integer;
  cmdName: AnsiString;
  paramsStr, param, parsingErrorStr: String;
  params: TKMScriptCommandParamsArray;
  quoteStart, parsingError: Boolean;

  procedure AddParam(const aParam: String);
  begin
    if aParam <> '' then
    begin
      if paramsI < Length(params) then
        params[paramsI] := aParam;
      Inc(paramsI);
    end;
  end;

begin
  Result := False;
  spacePos := Pos(' ', Text);
  if spacePos = 0 then
    spacePos := Length(Text) + 1;

  cmdName := AnsiString(Copy(Text, 2, spacePos - 2));

  if not gScriptEvents.HasConsoleCommand(cmdName)
    and Assigned(fOnError) then
  begin
    fOnError(Format(gResTexts[TX_SCRIPT_CONSOLE_CMD_NOT_FOUND], [WrapColorA(cmdName, clScriptCmdName)]));
    Exit;
  end;

  procParamsCnt := gScriptEvents.ConsoleCommand[cmdName].ProcParamsCnt;

  paramsStr := RightStr(Text, Length(Text) - (spacePos - 1));

  paramsI := 0;
  param := '';
  quoteStart := False;
  paramsStr := StringReplace(paramsStr, '\''', #1, [rfReplaceAll]);

  for I := 1 to Length(paramsStr) do
  begin
    if (paramsStr[I] = ' ') and not quoteStart then
    begin
      AddParam(param);
      param := '';
    end
    else
    if paramsStr[I] = '''' then
      quoteStart := not quoteStart
    else
      param := param + paramsStr[I];
  end;

  AddParam(param);

  parsingError := False;
  parsingErrorStr := Format(gResTexts[TX_SCRIPT_CONSOLE_CMD_PARSING_ERROR] + '|',
                            [WrapColorA(cmdName, clScriptCmdName),
                            gScriptEvents.ConsoleCommand[cmdName].Params2String(params)]);

  if (paramsI > procParamsCnt)
    and Assigned(fOnError) then
  begin
    fOnError(parsingErrorStr +
             Format(gResTexts[TX_SCRIPT_CONSOLE_CMD_TOO_MANY_PARAMS],
                    [WrapColorA(cmdName, clScriptCmdName),
                     WrapColor(IntToStr(procParamsCnt), clScriptCmdParam),
                     WrapColor(IntToStr(paramsI), clScriptCmdParam)])); //We Inc ParamsI at the end
    parsingError := True;
  end;

  for I := 0 to paramsI - 1 do
    params[I] := StringReplace(params[I], #1, '''', [rfReplaceAll]);

  for I := paramsI to MAX_SCRIPT_CONSOLE_COMMAND_PARAMS - 1 do
    params[I] := '';

  if not gScriptEvents.ConsoleCommand[cmdName].ValidateParams(params)
    and Assigned(fOnError) then
  begin
    fOnError(parsingErrorStr +
             Format(gResTexts[TX_SCRIPT_CONSOLE_CMD_PARAMS_NOT_VALID],
                    [WrapColorA(cmdName, clScriptCmdName),
                     gScriptEvents.ConsoleCommand[cmdName].ParamsTypes2String]));
    parsingError := True;
  end;

  if not parsingError then
  begin
    gGame.GameInputProcess.CmdConsoleCommand(gicScriptConsoleCommand, cmdName, params);
    if Assigned(fOnPostLocal) then
      fOnPostLocal(Format(gResTexts[TX_SCRIPT_CONSOLE_CMD_CALLED],
                          [WrapColorA(cmdName, clScriptCmdName),
                          gScriptEvents.ConsoleCommand[cmdName].Params2String(params)]));
    Result := True;
  end;
end;


procedure TKMConsole.Post(aPropagate: Boolean = True);
begin
  fLastConsoleTime := TimeGet;

  fHistory.Insert(0, Text);
  fCurrConsoleHistoryId := -1;

  if aPropagate and Assigned(fOnPost) then
    fOnPost(Text);

  Text := '';
end;


{ TKMChat }
constructor TKMChat.Create;
begin
  inherited;

  Clear;

  gChat := Self;
end;


destructor TKMChat.Destroy;
begin
  gChat := nil;

  inherited;
end;


procedure TKMChat.Clear;
begin
  inherited;

  WhisperRecipient := -1000;
  fMode := cmAll;
end;


procedure TKMChat.SetMode(aMode: TKMChatMode);
begin
  fMode := aMode;
end;


end.
