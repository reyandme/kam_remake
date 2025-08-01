unit KM_ScriptErrorHandler;
{$I KaM_Remake.inc}
interface
uses
  KM_ScriptingTypes, KM_CommonTypes, KM_GameParams, KM_CommonUtils;

type
  TKMScriptErrorHandler = class
  private
    fErrorString: TKMScriptErrorMessage; //Info about found mistakes (Unicode, can be localized later on)
    fWarningsString: TKMScriptErrorMessage;
    fHintsString: TKMScriptErrorMessage;

    fRuntimeErrorOccured: Boolean; // Has runtime error occurred? (only display first error)
    fScriptLogFile: UnicodeString;
    fOnScriptError: TUnicodeStringEvent;

    fLogLinesCnt: Integer; // number of log messages (lines) logged
    fLogLinesCntMax: Integer; // Max number of lines to log (could be changed via scripts)
    fLoggedTooManyLines: Boolean; // Flag if we have logged 'too many log lines' message

    procedure SetScriptLogFile(const aScriptLogFile: UnicodeString);
    function AppendErrorPrefix(const aPrefix: UnicodeString; var aError: TKMScriptErrorMessage): TKMScriptErrorMessage;
  public
    constructor Create(aOnScriptError: TUnicodeStringEvent);

    property ScriptLogFile: UnicodeString read fScriptLogFile write SetScriptLogFile;
    property ErrorString: TKMScriptErrorMessage read fErrorString;
    property WarningsString: TKMScriptErrorMessage read fWarningsString;

    procedure HandleScriptError(aType: TKMScriptErrorType; const aError: TKMScriptErrorMessage);
    procedure HandleScriptErrorString(aType: TKMScriptErrorType; const aErrorString: UnicodeString;
                                      const aDetailedErrorString: UnicodeString = '');

    procedure SetLogLinesCntMax(aValue: Integer);

    function HasErrors: Boolean;
    function HasWarnings: Boolean;
    function HasHints: Boolean;
    procedure AppendError(aError: TKMScriptErrorMessage);
    procedure AppendWarning(const aWarning: TKMScriptErrorMessage);
    procedure AppendHint(const aHint: TKMScriptErrorMessage);
    procedure AppendErrorStr(const aErrorString: String; const aDetailedErrorString: String = '');
    procedure AppendWarningStr(const aWarningString: String; const aDetailedWarningString: String = '');
    procedure HandleErrors;

    procedure Clear; // Used by ScriptValidator
  end;

implementation
uses
  SysUtils, Math,
  KromUtils,
  KM_Defaults, KM_Log;

const
  MAX_LOG_SIZE = 1024 * 1024; //1 MB
  MAX_LOG_LINES_CNT_DEFAULT = 100; //Default max number of log lines, allowed to be made by script


{ TKMScriptErrorHandler }
constructor TKMScriptErrorHandler.Create(aOnScriptError: TUnicodeStringEvent);
begin
  inherited Create;

  fOnScriptError := aOnScriptError;
  fLogLinesCntMax := MAX_LOG_LINES_CNT_DEFAULT;
end;


procedure TKMScriptErrorHandler.AppendError(aError: TKMScriptErrorMessage);
begin
  fErrorString.GameMessage := fErrorString.GameMessage + aError.GameMessage;
  fErrorString.LogMessage := fErrorString.LogMessage + aError.LogMessage;
end;


procedure TKMScriptErrorHandler.AppendHint(const aHint: TKMScriptErrorMessage);
begin
  fHintsString.GameMessage := fHintsString.GameMessage + aHint.GameMessage;
  fHintsString.LogMessage := fHintsString.LogMessage + aHint.LogMessage;
end;


procedure TKMScriptErrorHandler.AppendWarning(const aWarning: TKMScriptErrorMessage);
begin
  fWarningsString.GameMessage := fWarningsString.GameMessage + aWarning.GameMessage;
  fWarningsString.LogMessage := fWarningsString.LogMessage + aWarning.LogMessage;
end;


procedure TKMScriptErrorHandler.AppendErrorStr(const aErrorString: String; const aDetailedErrorString: String = '');
begin
  fErrorString.GameMessage := fErrorString.GameMessage + aErrorString;
  fErrorString.LogMessage := fErrorString.LogMessage + aDetailedErrorString;
end;


procedure TKMScriptErrorHandler.AppendWarningStr(const aWarningString: String; const aDetailedWarningString: String = '');
begin
  fWarningsString.GameMessage := fWarningsString.GameMessage + aWarningString;
  fWarningsString.LogMessage := fWarningsString.LogMessage + aDetailedWarningString;
end;


function TKMScriptErrorHandler.AppendErrorPrefix(const aPrefix: UnicodeString; var aError: TKMScriptErrorMessage): TKMScriptErrorMessage;
begin
  // Append prefix only for non-empty messages
  if aError.GameMessage <> '' then
    aError.GameMessage := aPrefix + aError.GameMessage;

  if aError.LogMessage <> '' then
    aError.LogMessage := aPrefix + aError.LogMessage;
  Result := aError;
end;


function TKMScriptErrorHandler.HasErrors: Boolean;
begin
  Result := fErrorString.GameMessage <> '';
end;


function TKMScriptErrorHandler.HasWarnings: Boolean;
begin
  Result := fWarningsString.GameMessage <> '';
end;


function TKMScriptErrorHandler.HasHints: Boolean;
begin
  Result := fHintsString.GameMessage <> '';
end;


procedure TKMScriptErrorHandler.HandleErrors;
begin
  HandleScriptError(seCompileError, AppendErrorPrefix('Script compile errors: ', fErrorString));
  HandleScriptError(seCompileWarning, AppendErrorPrefix('Script compile warnings: ', fWarningsString));
  HandleScriptError(seCompileHint, AppendErrorPrefix('Script compile hints: ', fHintsString));
end;


procedure TKMScriptErrorHandler.Clear;
begin
  fRuntimeErrorOccured := False;
  fErrorString.GameMessage := '';
  fErrorString.LogMessage := '';
  fWarningsString.GameMessage := '';
  fWarningsString.LogMessage := '';
  fHintsString.GameMessage := '';
  fHintsString.LogMessage := '';
end;


procedure TKMScriptErrorHandler.SetLogLinesCntMax(aValue: Integer);
begin
  fLogLinesCntMax := EnsureRange(aValue, 0, MaxInt);
end;


procedure TKMScriptErrorHandler.SetScriptLogFile(const aScriptLogFile: UnicodeString);
begin
  fScriptLogFile := aScriptLogFile;
  if not DirectoryExists(ExtractFilePath(fScriptLogFile)) then
    fScriptLogFile := '';
end;


procedure TKMScriptErrorHandler.HandleScriptError(aType: TKMScriptErrorType; const aError: TKMScriptErrorMessage);
begin
  HandleScriptErrorString(aType, aError.GameMessage, aError.LogMessage);
end;


procedure TKMScriptErrorHandler.HandleScriptErrorString(aType: TKMScriptErrorType; const aErrorString: UnicodeString;
                                                        const aDetailedErrorString: UnicodeString = '');

  procedure LogError(aLogErrorMsg: string);
  var
    fl: TextFile;
  begin
    //Log to map specific log file
    if fScriptLogFile <> '' then
    begin
      if DEBUG_SCRIPTING_EXEC or (fLogLinesCnt < fLogLinesCntMax) then
      begin
        gLog.AddTime('Script: [gametime ' + TickToTimeStr(gGameParams.Tick) + '] ' + aLogErrorMsg); //log the error to global game log
        AssignFile(fl, fScriptLogFile);
        if not FileExists(fScriptLogFile) then
          Rewrite(fl)
        else
          if GetFileSize(fScriptLogFile) > MAX_LOG_SIZE then
          begin
            //Reset the log if it gets too long so poorly written scripts don't waste disk space
            Rewrite(fl);
            WriteLn(fl, Format('%23s   %s', [FormatDateTime('yyyy/mm/dd hh:nn:ss.zzz', Now),
                    'Log file exceeded ' + IntToStr(MAX_LOG_SIZE) + ' bytes and was reset']));
            fLogLinesCnt := 0;
            fLoggedTooManyLines := False;
          end
          else
            Append(fl);
        WriteLn(fl, Format('%23s   %s', [FormatDateTime('yyyy/mm/dd hh:nn:ss.zzz', Now), aLogErrorMsg]));
        Inc(fLogLinesCnt);
        CloseFile(fl);
      end
      else
      if not fLoggedTooManyLines then
      begin
        AssignFile(fl, fScriptLogFile);
        // File should always exists
        if not FileExists(fScriptLogFile) then
          Rewrite(fl)
        else
          Append(fl);
        gLog.AddTime('Script: ' + aLogErrorMsg); //log the error to global game log
        WriteLn(fl, Format('%23s   %s', [FormatDateTime('yyyy/mm/dd hh:nn:ss.zzz', Now), aLogErrorMsg]));
        aLogErrorMsg := Format('Script log lines exceeded max value of %d. ' +
                              'Check ''Debug Scripting'' checkbox in the F11 debug panel (''Scripting'' section) ' +
                              'or use Actions.LogLinesMaxCnt to set higher value of max log lines', [fLogLinesCntMax]);
        gLog.AddTime('Script: ' + aLogErrorMsg); //log the error to global game log
        WriteLn(fl, Format('%23s   %s', [FormatDateTime('yyyy/mm/dd hh:nn:ss.zzz', Now), aLogErrorMsg]));
        CloseFile(fl);
        fLoggedTooManyLines := True;
      end;
    end;
  end;
var
  logErrorMsg, errorStrToDisplay: UnicodeString;
begin
  if BLOCK_FILE_WRITE then Exit;

  if aDetailedErrorString <> '' then
    logErrorMsg := aDetailedErrorString
  else
    logErrorMsg := aErrorString;

  if logErrorMsg = '' then //No errors occur
    Exit;

  LogError(logErrorMsg);

  errorStrToDisplay := StringReplace(aErrorString, EolW, '|', [rfReplaceAll]);

  // Append preprocessing error
  if aType = sePreprocessorError then
    AppendErrorStr(aErrorString);

  // Display compile errors in-game
  if (aType in [seCompileError, sePreprocessorError]) and Assigned(fOnScriptError) then
    fOnScriptError(errorStrToDisplay);

  // Serious runtime errors should be shown to the player
  if aType = seException then
  begin
    // Only show the first message in-game to avoid spamming the player
    if not fRuntimeErrorOccured and Assigned(fOnScriptError) then
      fOnScriptError('Error(s) have occured in the mission script. ' +
                     'Please check the log file for further details. First error:|' + errorStrToDisplay);
    fRuntimeErrorOccured := True;
  end;
end;


end.
