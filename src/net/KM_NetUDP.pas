unit KM_NetUDP;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, SysUtils, KM_CommonClasses, KM_Defaults
  {$IFDEF WDC} ,KM_NetUDPOverbyte {$ENDIF}
  {$IFDEF FPC} ,KM_NetUDPLNet {$ENDIF}
  ;


type
  TNotifyServerDetectedEvent = procedure(const aAddress: string; const aPort: Word; const aName: string) of object;

  TKMNetUDP = class
  private
    {$IFDEF WDC} fUDP: TKMNetUDPOverbyte; {$ENDIF}
    {$IFDEF FPC} fUDP: TKMNetUDPLNet;     {$ENDIF}

    fOnError: TGetStrProc;
    procedure Receive(const aAddress: string; aData: Pointer; aLength: Cardinal); virtual; abstract;
    procedure Error(const msg: string);
  protected
    fScanPort: Word;
  public
    constructor Create(aScanPort: Word);
    destructor Destroy; override;
    procedure UpdateStateIdle;
    property OnError: TGetStrProc write fOnError;
  end;

  TKMNetUDPAnnounce = class(TKMNetUDP)
  private
    fGamePort: Word;
    fServerName: AnsiString;
    procedure Receive(const aAddress: string; aData: Pointer; aLength: Cardinal); override;
  public
    procedure StartAnnouncing(const aGamePort: Word; const aName: AnsiString; aAnnounce: Boolean);
    procedure StopAnnouncing;
    procedure UpdateSettings(const aName: AnsiString; aScanPort: Word);
  end;

  TKMNetUDPScan = class(TKMNetUDP)
  private
    fOnServerDetected: TNotifyServerDetectedEvent;
    procedure Receive(const aAddress: String; aData: Pointer; aLength: Cardinal); override;
  public
    procedure ScanForServers;
    procedure TerminateScan;
    property OnServerDetected: TNotifyServerDetectedEvent write fOnServerDetected;
  end;


implementation


constructor TKMNetUDP.Create(aScanPort: Word);
begin
  Inherited Create;
  {$IFDEF WDC} fUDP := TKMNetUDPOverbyte.Create; {$ENDIF}
  {$IFDEF FPC} fUDP := TKMNetUDPLNet.Create;     {$ENDIF}
  fScanPort := aScanPort;
  fUDP.OnError := Error;
  fUDP.OnRecieveData := Receive;
end;


destructor TKMNetUDP.Destroy;
begin
  if fUDP<>nil then fUDP.Free;
  Inherited;
end;


procedure TKMNetUDP.Error(const Msg: String);
begin
  if Assigned(fOnError) then fOnError(msg);
end;


procedure TKMNetUDP.UpdateStateIdle;
begin
  {$IFDEF FPC} fUDP.UpdateStateIdle; {$ENDIF}
end;


{ TKMNetUDPAnnounce }
procedure TKMNetUDPAnnounce.StartAnnouncing(const aGamePort: Word; const aName: AnsiString; aAnnounce: Boolean);
begin
  fGamePort := aGamePort;
  fServerName := aName;
  fUDP.StopListening;
  if aAnnounce then
    try
      fUDP.Listen(SERVER_DEFAULT_UDP_ANNOUNCE_PORT);
    except
      //UDP announce is not that important, and will fail whenever you start more than 1 server per machine
      on E: Exception do
        if Assigned(fOnError) then fOnError('UDP listen for local server detection failed to start: ' + E.Message);
    end;
end;


procedure TKMNetUDPAnnounce.StopAnnouncing;
begin
  fUDP.StopListening;
end;


procedure TKMNetUDPAnnounce.UpdateSettings(const aName: AnsiString; aScanPort: Word);
begin
  fServerName := aName;
  fScanPort := aScanPort;
end;


procedure TKMNetUDPAnnounce.Receive(const aAddress: string; aData: Pointer; aLength: Cardinal);
var
  M: TKMemoryStream;
  S: AnsiString;
begin
  M := TKMemoryStreamBinary.Create;
  try
    M.WriteBuffer(aData^, aLength);
    M.Position := 0;

    //Check header
    M.ReadA(S);
    if S <> 'KaM Remake' then Exit;
    M.ReadA(S);
    if S <> NET_PROTOCOL_REVISON then Exit;

    //Only care about scan packets
    M.ReadA(S);
    if S <> 'scan' then Exit;

    //Send a response to this scanner
    M.Free;
    M := TKMemoryStreamBinary.Create;
    M.WriteA('KaM Remake');
    M.WriteA(NET_PROTOCOL_REVISON);
    M.WriteA('announce');
    M.Write(fGamePort);
    M.WriteA(fServerName);

    fUDP.SendPacket(aAddress, fScanPort, M.Memory, M.Size);
  finally
    M.Free;
  end;
end;


{ TKMNetUDPDetect }
procedure TKMNetUDPScan.ScanForServers;
var
  M: TKMemoryStream;
begin
  //Prepare to receive responses
  fUDP.StopListening;
  try
    fUDP.Listen(fScanPort);
  except
    //UDP scan is not that important, and could fail during debugging if running two KaM Remake instances
    on E: Exception do
    begin
      if Assigned(fOnError) then fOnError('UDP scan failed to listen: ' + E.Message);
      Exit;
    end;
  end;

  M := TKMemoryStreamBinary.Create;
  try
    M.WriteA('KaM Remake');
    M.WriteA(NET_PROTOCOL_REVISON);
    M.WriteA('scan');
    try
      //Broadcast
      fUDP.SendPacket('255.255.255.255', 56789, M.Memory, M.Size);
    except
      on E: Exception do
      begin
        if Assigned(fOnError) then fOnError('UDP broadcast failed: ' + E.Message);
        Exit;
      end;
    end;

  finally
    M.Free;
  end;
end;


procedure TKMNetUDPScan.TerminateScan;
begin
  fUDP.StopListening;
end;


procedure TKMNetUDPScan.Receive(const aAddress: String; aData: Pointer; aLength: Cardinal);
var
  M: TKMemoryStream;
  S, ServerName: AnsiString;
  serverPort: Word;
begin
  M := TKMemoryStreamBinary.Create;
  try
    M.WriteBuffer(aData^, aLength);
    M.Position := 0;

    M.ReadA(S);
    if S <> 'KaM Remake' then Exit;
    M.ReadA(S);
    if S <> NET_PROTOCOL_REVISON then Exit;
    //Only care about announce packets
    M.ReadA(S);
    if S <> 'announce' then Exit;

    //Read the server's game port and report it
    M.Read(serverPort);
    M.ReadA(ServerName);
    fOnServerDetected(aAddress, serverPort, UnicodeString(ServerName));
  finally
    M.Free;
  end;
end;


end.

