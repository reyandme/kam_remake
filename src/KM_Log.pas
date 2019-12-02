unit KM_Log;
{$I KaM_Remake.inc}
interface
uses
  SyncObjs, KM_CommonTypes;


type

  // Log message type
  TKMLogMessageType = (
    lmtDefault,            //default type
    lmtDelivery,           //delivery messages
    lmtCommands,           //all GIC commands
    lmtRandomChecks,       //Random Checks
    lmtNetConnection,      //messages about net connection/disconnection/reconnection
    lmtNetPacketOther,     //log messages about net packets (all packets, except GIP commands/ping/fps)
    lmtNetPacketCommand,   //log messages about GIP commands net packets
    lmtNetPacketPingFps,   //log messages about ping/fps net packets
    lmtDebug);             //debug

  TKMLogMessageTypeSet = set of TKMLogMessageType;

  //Logging system
  TKMLog = class
  private
    CS: TCriticalSection;
    fl: textfile;
    fLogPath: UnicodeString;
    fFirstTick: cardinal;
    fPreviousTick: cardinal;
    fPreviousDate: TDateTime;
    fOnLogMessage: TUnicodeStringEvent;

    procedure Lock;
    procedure Unlock;

    procedure AddLineTime(const aText: UnicodeString; aLogType: TKMLogMessageType; aDoCloseFile: Boolean = True); overload;
    procedure AddLineTime(const aText: UnicodeString; aFlushImmidiately: Boolean = True); overload;
    procedure AddLineNoTime(const aText: UnicodeString; aDoCloseFile: Boolean = True); overload;
    procedure AddLineNoTime(const aText: UnicodeString; aLogType: TKMLogMessageType; aDoCloseFile: Boolean = True); overload;
  public
    MultithreadLogging: Boolean; // Enable thread safe mode (resource protection) while logging with multi threads
    MessageTypes: TKMLogMessageTypeSet;
    constructor Create(const aPath: UnicodeString);
    destructor Destroy; override;
    procedure InitLog;
    // AppendLog adds the line to Log along with time passed since previous line added
    procedure AddTime(const aText: UnicodeString); overload;
    procedure AddTimeNoFlush(const aText: UnicodeString); overload;
    procedure AddTime(const aText: UnicodeString; num: Integer); overload;
    procedure AddTime(const aText: UnicodeString; num: Single); overload;
    procedure AddTime(num: Integer; const aText: UnicodeString); overload;
    procedure AddTime(const aText: UnicodeString; Res: boolean); overload;
    procedure AddTime(a, b: integer); overload;
    function IsDegubLogEnabled: Boolean;
    procedure LogDebug(const aText: UnicodeString);
    procedure LogDelivery(const aText: UnicodeString);
    procedure LogCommands(const aText: UnicodeString);
    procedure LogRandomChecks(const aText: UnicodeString);
    procedure LogNetConnection(const aText: UnicodeString);
    procedure LogNetPacketOther(const aText: UnicodeString);
    procedure LogNetPacketCommand(const aText: UnicodeString);
    procedure LogNetPacketPingFps(const aText: UnicodeString);
    function CanLogDelivery: Boolean;
    function CanLogCommands: Boolean;
    function CanLogRandomChecks: Boolean;
    function CanLogNetConnection: Boolean;
    function CanLogNetPacketOther: Boolean;
    function CanLogNetPacketCommand: Boolean;
    function CanLogNetPacketPingFps: Boolean;

    // Add line if TestValue=false
    procedure AddAssert(const aMessageText: UnicodeString);
    // AddToLog simply adds the text
    procedure AddNoTime(const aText: UnicodeString);
    procedure AddNoTimeNoFlush(const aText: UnicodeString);
    procedure DeleteOldLogs;
    property LogPath: UnicodeString read fLogPath; //Used by dedicated server
    property OnLogMessage: TUnicodeStringEvent read fOnLogMessage write fOnLogMessage;
  end;

var
  gLog: TKMLog;


implementation
uses
  Classes, SysUtils,
  KM_Defaults, KM_CommonUtils;

const
  DEFAULT_LOG_TYPES_TO_WRITE: TKMLogMessageTypeSet = [lmtDefault, lmtNetConnection];


//New thread, in which old logs are deleted (used internally)
type
  TKMOldLogsDeleter = class(TThread)
  private
    fPathToLogs: UnicodeString;
  public
    constructor Create(const aPathToLogs: UnicodeString);
    procedure Execute; override;
  end;


{ TKMOldLogsDeleter }
constructor TKMOldLogsDeleter.Create(const aPathToLogs: UnicodeString);
begin
  //Thread isn't started until all constructors have run to completion
  //so Create(False) may be put in front as well
  inherited Create(False);

  //Must set these values BEFORE starting the thread
  FreeOnTerminate := True; //object can be automatically removed after its termination
  fPathToLogs := aPathToLogs;
end;


procedure TKMOldLogsDeleter.Execute;
var
  SearchRec: TSearchRec;
  fileDateTime: TDateTime;
begin
  if not DirectoryExists(fPathToLogs) then Exit;
  try
    if FindFirst(fPathToLogs + 'KaM*.log', faAnyFile - faDirectory, SearchRec) = 0 then
    repeat
      Assert(FileAge(fPathToLogs + SearchRec.Name, fileDateTime), 'How is that it does not exists any more?');

      if (Abs(Now - fileDateTime) > DEL_LOGS_OLDER_THAN) then
        DeleteFile(fPathToLogs + SearchRec.Name);
    until (FindNext(SearchRec) <> 0);
  finally
    FindClose(SearchRec);
  end;

end;


{ TKMLog }
constructor TKMLog.Create(const aPath: UnicodeString);
begin
  inherited Create;
  MultithreadLogging := False;
  fLogPath := aPath;
  fFirstTick := TimeGet;
  fPreviousTick := TimeGet;
  MessageTypes := DEFAULT_LOG_TYPES_TO_WRITE;
  if DEBUG_LOGS then
    Include(MessageTypes, lmtDebug);

  CS := TCriticalSection.Create;
  InitLog;
end;


destructor TKMLog.Destroy;
begin
  CS.Free;
  inherited;
end;


procedure TKMLog.Lock;
begin
  CS.Enter;
end;


procedure TKMLog.Unlock;
begin
  CS.Leave;
end;


procedure TKMLog.InitLog;
begin
  if BLOCK_FILE_WRITE then Exit;

  ForceDirectories(ExtractFilePath(fLogPath));

  AssignFile(fl, fLogPath);
  Rewrite(fl);
  //           hh:nn:ss.zzz 12345.678s 1234567ms     text-text-text
  WriteLn(fl, '   Timestamp    Elapsed     Delta     Description');
  CloseFile(fl);

  AddLineTime('Log is up and running. Game version: ' + UnicodeString(GAME_VERSION));
end;


//Run thread to delete old logs.
procedure TKMLog.DeleteOldLogs;
begin
  if Self = nil then Exit;

  //No need to remember the instance, it's set to FreeOnTerminate
  TKMOldLogsDeleter.Create(ExtractFilePath(fLogPath));
end;


//Lines are timestamped, each line invokes file open/close for writing,
//meaning that no lines will be lost if Remake crashes
procedure TKMLog.AddLineTime(const aText: UnicodeString; aLogType: TKMLogMessageType; aDoCloseFile: Boolean = True);
begin
  if Self = nil then Exit;

  if BLOCK_FILE_WRITE then Exit;
  
  if not (aLogType in MessageTypes) then // write into log only for allowed types
    Exit;

  // Lock/Unlock only when in multithread logging mode. Its quite rare, so we do not need all the time
  if MultithreadLogging then
    Lock;
  try
    if not FileExists(fLogPath) then
      InitLog;  // Recreate log file, if it was deleted

    Append(fl);
    //Write a line when the day changed since last time (useful for dedicated server logs that could be over months)
    if Abs(Trunc(fPreviousDate) - Trunc(Now)) >= 1 then
    begin
      WriteLn(fl, '========================');
      WriteLn(fl, '    Date: ' + FormatDateTime('yyyy/mm/dd', Now));
      WriteLn(fl, '========================');
    end;
    WriteLn(fl, Format('%12s %9.3fs %7dms     %s', [
                  FormatDateTime('hh:nn:ss.zzz', Now),
                  GetTimeSince(fFirstTick) / 1000,
                  GetTimeSince(fPreviousTick),
                  aText]));

    if aDoCloseFile then
      CloseFile(fl);

    fPreviousTick := TimeGet;
    fPreviousDate := Now;
  finally
    if MultithreadLogging then
      UnLock;
  end;

  if Assigned(fOnLogMessage) then
    fOnLogMessage(aText);
end;


//Add line with timestamp
procedure TKMLog.AddLineTime(const aText: UnicodeString; aFlushImmidiately: Boolean = True);
begin
  AddLineTime(aText, lmtDefault, aFlushImmidiately);
end;


//Add line but without timestamp
procedure TKMLog.AddLineNoTime(const aText: UnicodeString; aLogType: TKMLogMessageType; aDoCloseFile: Boolean = True);
begin
  if Self = nil then Exit;

  if BLOCK_FILE_WRITE then Exit;

  if not (aLogType in MessageTypes) then // write into log only for allowed types
    Exit;

  if not FileExists(fLogPath) then
    InitLog;  // Recreate log file, if it was deleted

  // Lock/Unlock only when in multithread logging mode. Its quite rare, so we do not need all the time
  if MultithreadLogging then
    Lock;
  try
    Append(fl);
    WriteLn(fl, '                                      ' + aText);
    if aDoCloseFile then
      CloseFile(fl);
  finally
    if MultithreadLogging then
      UnLock;
  end;

  if Assigned(fOnLogMessage) then
    fOnLogMessage(aText);
end;


//Add line without timestamp
procedure TKMLog.AddLineNoTime(const aText: UnicodeString; aDoCloseFile: Boolean = True);
begin
  AddLineNoTime(aText, lmtDefault, aDoCloseFile);
end;


procedure TKMLog.AddTime(const aText: UnicodeString);
begin
  AddLineTime(aText);
end;


procedure TKMLog.AddTimeNoFlush(const aText: UnicodeString);
begin
  if Self = nil then Exit;
  AddLineTime(aText, False);
end;


function TKMLog.IsDegubLogEnabled: Boolean;
begin
  Result := lmtDebug in MessageTypes;
end;


procedure TKMLog.LogDebug(const aText: UnicodeString);
begin
  if Self = nil then Exit;
  AddLineTime(aText, lmtDebug);
end;


procedure TKMLog.LogDelivery(const aText: UnicodeString);
begin
  if Self = nil then Exit;
  AddLineTime(aText, lmtDelivery);
end;


procedure TKMLog.LogCommands(const aText: UnicodeString);
begin
  if Self = nil then Exit;
  AddLineTime(aText, lmtCommands);
end;


procedure TKMLog.LogRandomChecks(const aText: UnicodeString);
begin
  if Self = nil then Exit;
  AddLineNoTime(aText, lmtRandomChecks);
end;


procedure TKMLog.LogNetConnection(const aText: UnicodeString);
begin
  if Self = nil then Exit;
  AddLineTime(aText, lmtNetConnection);
end;


procedure TKMLog.LogNetPacketOther(const aText: UnicodeString);
begin
  if Self = nil then Exit;
  AddLineTime(aText, lmtNetPacketOther);
end;


procedure TKMLog.LogNetPacketCommand(const aText: UnicodeString);
begin
  if Self = nil then Exit;
  AddLineTime(aText, lmtNetPacketCommand);
end;


procedure TKMLog.LogNetPacketPingFps(const aText: UnicodeString);
begin
  if Self = nil then Exit;
  AddLineTime(aText, lmtNetPacketPingFps);
end;


function TKMLog.CanLogDelivery: Boolean;
begin
  Result := lmtDelivery in MessageTypes;
end;

function TKMLog.CanLogCommands: Boolean;
begin
  Result := lmtCommands in MessageTypes;
end;

function TKMLog.CanLogRandomChecks: Boolean;
begin
  Result := lmtRandomChecks in MessageTypes;
end;

function TKMLog.CanLogNetConnection: Boolean;
begin
  Result := lmtNetConnection in MessageTypes;
end;

function TKMLog.CanLogNetPacketOther: Boolean;
begin
  Result := lmtNetPacketOther in MessageTypes;
end;

function TKMLog.CanLogNetPacketCommand: Boolean;
begin
  Result := lmtNetPacketCommand in MessageTypes;
end;

function TKMLog.CanLogNetPacketPingFps: Boolean;
begin
  Result := lmtNetPacketPingFps in MessageTypes;
end;


procedure TKMLog.AddTime(const aText: UnicodeString; num: integer);
begin
  if Self = nil then Exit;

  AddLineTime(aText + ' ' + inttostr(num));
end;


procedure TKMLog.AddTime(const aText: UnicodeString; num: single);
begin
  if Self = nil then Exit;

  AddLineTime(aText + ' ' + floattostr(num));
end;


procedure TKMLog.AddTime(num: integer; const aText: UnicodeString);
begin
  if Self = nil then Exit;

  AddLineTime(inttostr(num) + ' ' + aText);
end;


procedure TKMLog.AddTime(const aText: UnicodeString; Res: boolean);
var
  s: UnicodeString;
begin
  if Self = nil then Exit;

  if Res then
    s := 'done'
  else
    s := 'fail';
  AddLineTime(aText + ' ... ' + s);
end;


procedure TKMLog.AddTime(A, B: integer);
begin
  if Self = nil then Exit;

  AddLineTime(inttostr(A) + ' : ' + inttostr(B));
end;


procedure TKMLog.AddAssert(const aMessageText: UnicodeString);
begin
  if Self = nil then Exit;

  AddLineNoTime('ASSERTION FAILED! Msg: ' + aMessageText);
  raise Exception.Create('ASSERTION FAILED! Msg: ' + aMessageText);
end;


procedure TKMLog.AddNoTime(const aText: UnicodeString);
begin
  if Self = nil then Exit;

  AddLineNoTime(aText);
end;



procedure TKMLog.AddNoTimeNoFlush(const aText: UnicodeString);
begin
  if Self = nil then Exit;

  AddLineNoTime(aText, False);
end;


end.
