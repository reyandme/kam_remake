unit KM_Console;
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
      fMessages: String;

      procedure SetMessages(const aMessages: String);

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

      function GetNextHistoryMsg: String;
      function GetPrevHistoryMsg: String;

      procedure Add(aMessage: String);
      procedure AddLine(aMessage: String);

      procedure Clear; virtual;
    end;


  TKMChat = class(TKMConsole)
  private
    fMode: TKMChatMode;
    procedure SetMode(aMode: TKMChatMode);
  public
    WhisperRecipient: TKMNetHandleIndex;

    constructor Create;

    property Mode: TKMChatMode read fMode write SetMode;

    procedure Clear; override;
  end;

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


procedure TKMConsole.SetMessages(const aMessages: String);
begin
  fMessages := aMessages;
end;


function TKMConsole.GetNextHistoryMsg: String;
begin
  if fHistory.Count = 0 then
  begin
    Result := '';
    Exit;
  end;

  fCurrConsoleHistoryId := Min(fCurrConsoleHistoryId + 1, fHistory.Count - 1);
  Result := fHistory[fCurrConsoleHistoryId];
end;


function TKMConsole.GetPrevHistoryMsg: String;
begin
  if fHistory.Count = 0 then
  begin
    Result := '';
    Exit;
  end;

  fCurrConsoleHistoryId := Max(0, fCurrConsoleHistoryId - 1);
  Result := fHistory[fCurrConsoleHistoryId];
end;


procedure TKMConsole.Add(aMessage: String);
begin
  fMessages := fMessages + aMessage;

  if Assigned(fOnChange) then
    fOnChange;
end;


procedure TKMConsole.AddLine(aMessage: String);
begin
  if fMessages <> '' then
    fMessages := fMessages + '|';

  Add(aMessage);
end;



function TKMConsole.IsPostAllowed : Boolean;
begin
  Result := (Trim(Text) <> '') and (GetTimeSince(fLastConsoleTime) >= CHAT_COOLDOWN)
end;


function TKMConsole.TryCallConsoleCommand: Boolean;
begin
  Result := False;
  if gGame = nil then //Can't manage console commands while not in the game
    Exit;

  if (Length(Text) > 0) and (Text[1] = '/') and (Text[2] <> '/') then
  begin
    TryDoCallConsoleCommand;
    //Add command to history, bu t do not propagate post to others
    Post(False);
    Result := True;
  end else
  if (Length(Text) > 1) and (Text[1] = '/') and (Text[2] = '/') then
    Delete(Text, 1, 1); //Remove one of the /'s
end;


function TKMConsole.TryDoCallConsoleCommand: Boolean;
var
  I, ParamsI, ProcParamsCnt, SpacePos: Integer;
  CmdName: AnsiString;
  ParamsStr, Param, ParsingErrorStr: String;
  Params: TKMScriptCommandParamsArray;
  QuoteStart, ParsingError: Boolean;

  procedure AddParam(const aParam: String);
  begin
    if aParam <> '' then
    begin
      if ParamsI < Length(Params) then
        Params[ParamsI] := aParam;
      Inc(ParamsI);
    end;
  end;

begin
  Result := False;
  SpacePos := Pos(' ', Text);
  if SpacePos = 0 then
    SpacePos := Length(Text) + 1;

  CmdName := AnsiString(Copy(Text, 2, SpacePos - 2));

  if not gScriptEvents.HasConsoleCommand(CmdName)
    and Assigned(fOnError) then
  begin
    fOnError(Format(gResTexts[TX_SCRIPT_CONSOLE_CMD_NOT_FOUND], [WrapColorA(CmdName, clScriptCmdName)]));
    Exit;
  end;

  ProcParamsCnt := gScriptEvents.ConsoleCommand[CmdName].ProcParamsCnt;

  ParamsStr := RightStr(Text, Length(Text) - (SpacePos - 1));

  ParamsI := 0;
  Param := '';
  QuoteStart := False;
  ParamsStr := StringReplace(ParamsStr, '\''', #1, [rfReplaceAll]);

  for I := 1 to Length(ParamsStr) do
  begin
    if (ParamsStr[I] = ' ') and not QuoteStart then
    begin
      AddParam(Param);
      Param := '';
    end
    else
    if ParamsStr[I] = '''' then
      QuoteStart := not QuoteStart
    else
      Param := Param + ParamsStr[I];
  end;

  AddParam(Param);

  ParsingError := False;
  ParsingErrorStr := Format(gResTexts[TX_SCRIPT_CONSOLE_CMD_PARSING_ERROR] + '|',
                            [WrapColorA(CmdName, clScriptCmdName),
                            gScriptEvents.ConsoleCommand[CmdName].Params2String(Params)]);

  if (ParamsI > ProcParamsCnt)
    and Assigned(fOnError) then
  begin
    fOnError(ParsingErrorStr +
             Format(gResTexts[TX_SCRIPT_CONSOLE_CMD_TOO_MANY_PARAMS],
                    [WrapColorA(CmdName, clScriptCmdName),
                     WrapColor(IntToStr(ProcParamsCnt), clScriptCmdParam),
                     WrapColor(IntToStr(ParamsI), clScriptCmdParam)])); //We Inc ParamsI at the end
    ParsingError := True;
  end;

  for I := 0 to ParamsI - 1 do
    Params[I] := StringReplace(Params[I], #1, '''', [rfReplaceAll]);

  for I := ParamsI to MAX_SCRIPT_CONSOLE_COMMAND_PARAMS - 1 do
    Params[I] := '';

  if not gScriptEvents.ConsoleCommand[CmdName].ValidateParams(Params)
    and Assigned(fOnError) then
  begin
    fOnError(ParsingErrorStr +
             Format(gResTexts[TX_SCRIPT_CONSOLE_CMD_PARAMS_NOT_VALID],
                    [WrapColorA(CmdName, clScriptCmdName),
                     gScriptEvents.ConsoleCommand[CmdName].ParamsTypes2String]));
    ParsingError := True;
  end;

  if not ParsingError then
  begin
    gGame.GameInputProcess.CmdConsoleCommand(gicScriptConsoleCommand, CmdName, Params);
    if Assigned(fOnPostLocal) then
      fOnPostLocal(Format(gResTexts[TX_SCRIPT_CONSOLE_CMD_CALLED],
                          [WrapColorA(CmdName, clScriptCmdName),
                          gScriptEvents.ConsoleCommand[CmdName].Params2String(Params)]));
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
