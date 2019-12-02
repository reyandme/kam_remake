unit Log;
interface
uses
  Classes, SysUtils;

type
  TLogEvent = procedure (const aText: string) of object;

  // Global logger
  TLog = class
  private
    fOnLog: TLogEvent;
  public
    constructor Create(aOnLog: TLogEvent);
    destructor Destroy; override;
    procedure Log(const aText: string); overload;
    procedure Log(const aText: string; aArgs: array of const); overload;
  end;

 var
   gLog: TLog;

implementation


{ TLog }
constructor TLog.Create(aOnLog: TLogEvent);
begin
  inherited Create;

  fOnLog := aOnLog;

  Log('TLog-Create');
end;


destructor TLog.Destroy;
begin
  Log('TLog-Destroy');

  inherited;
end;


procedure TLog.Log(const aText: string);
begin
  if (Self <> nil) and Assigned(fOnLog) then
    TThread.Synchronize(nil,
      procedure
      begin
        fOnLog(aText);
      end
    );
end;


procedure TLog.Log(const aText: string; aArgs: array of const);
begin
  Log(Format(aText, aArgs));
end;


end.
