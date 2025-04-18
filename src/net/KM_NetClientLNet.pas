unit KM_NetClientLNet;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, SysUtils, LNet, dialogs;


{ This unit knows nothing about KaM, it's just a puppet in hands of KM_ClientControl,
doing all the low level work on TCP. So we can replace this unit with other TCP client
without KaM even noticing. }
const
  MAX_SEND_BUFFER = 1048576; //1 MB

type
  TNotifyDataEvent = procedure(aData: Pointer; aLength: Cardinal) of object;

  TKMNetClientLNet = class
  private
    fSocket: TLTCP;
    fBuffer: array of byte;
    fBufferLen: Cardinal;

    fOnError: TGetStrProc;
    fOnConnectSucceed: TNotifyEvent;
    fOnConnectFailed: TGetStrProc;
    fOnSessionDisconnected: TNotifyEvent;
    fOnRecieveData: TNotifyDataEvent;
    procedure Connected(aSocket: TLSocket);
    procedure Disconnected(aSocket: TLSocket);
    procedure Receive(aSocket: TLSocket);
    procedure Error(const aMsg: string; aSocket: TLSocket);
    procedure CanSend(aSocket: TLSocket);

    procedure PutInBuffer(aData: Pointer; aLength: Cardinal);
    procedure AttemptSend;
    function BufferFull: Boolean;
  public
    destructor Destroy; override;
    function MyIPString: string;
    function SendBufferEmpty: Boolean;
    procedure ConnectTo(const aAddress: string; const aPort: Word);
    procedure Disconnect;
    procedure SendData(aData: Pointer; aLength: Cardinal);
    procedure SetHandleBackgrounException;
    procedure UpdateStateIdle;
    property OnError: TGetStrProc write fOnError;
    property OnConnectSucceed: TNotifyEvent write fOnConnectSucceed;
    property OnConnectFailed: TGetStrProc write fOnConnectFailed;
    property OnSessionDisconnected: TNotifyEvent write fOnSessionDisconnected;
    property OnRecieveData: TNotifyDataEvent write fOnRecieveData;
  end;


implementation


{ TKMNetClientLNet }
destructor TKMNetClientLNet.Destroy;
begin
  fSocket.Free;
  inherited;
end;


function TKMNetClientLNet.MyIPString: string;
begin
  Result := 'Not implemented yet';
end;


function TKMNetClientLNet.SendBufferEmpty: Boolean;
begin
  Result := (fSocket = nil) or (fBufferLen = 0);
end;


procedure TKMNetClientLNet.ConnectTo(const aAddress: string; const aPort: Word);
begin
  FreeAndNil(fSocket);
  fSocket := TLTCP.Create(nil);
  fSocket.OnDisconnect := Disconnected;
  fSocket.OnConnect := Connected;
  fSocket.OnReceive := Receive;
  fSocket.OnError := Error;
  fSocket.Timeout := 0;
  try
    fSocket.Connect(aAddress, aPort);
    fSocket.CallAction;
  except
    on E: Exception do
    begin
      //Trap the exception and tell the user. Note: While debugging, Delphi will still stop execution for the exception, but normally the dialouge won't show.
      fOnConnectFailed(E.Message);
    end;
  end;
end;


procedure TKMNetClientLNet.Disconnect;
begin
  if fSocket <> nil then fSocket.Disconnect(True);
end;


procedure TKMNetClientLNet.PutInBuffer(aData: Pointer; aLength: Cardinal);
begin
  SetLength(fBuffer, fBufferLen + aLength);
  Move(aData^, fBuffer[fBufferLen], aLength);
  fBufferLen := fBufferLen + aLength;
end;


procedure TKMNetClientLNet.AttemptSend;
var
  LenSent: Integer;
begin
  if fBufferLen <= 0 then Exit;

  LenSent := fSocket.Send(fBuffer[0], fBufferLen);

  if LenSent > 0 then
  begin
    fBufferLen := fBufferLen - LenSent;
    if fBufferLen > 0 then
      Move(fBuffer[LenSent], fBuffer[0], fBufferLen);
  end;
end;

function TKMNetClientLNet.BufferFull: Boolean;
begin
  Result := fBufferLen >= MAX_SEND_BUFFER;
end;


procedure TKMNetClientLNet.SendData(aData: Pointer; aLength: Cardinal);
begin
  if fSocket.Connected then
  begin
    if BufferFull then
    begin
      fOnError('LNet Client Error: Send buffer full');
      Exit;
    end;
    PutInBuffer(aData, aLength);
    AttemptSend;
  end;
end;


procedure TKMNetClientLNet.SetHandleBackgrounException;
begin
  // Do nothing for now
end;


procedure TKMNetClientLNet.CanSend(aSocket: TLSocket);
begin
  AttemptSend;
end;


procedure TKMNetClientLNet.Connected(aSocket: TLSocket);
begin
  fOnConnectSucceed(Self);
  aSocket.SetState(ssNoDelay, True); //Send packets ASAP (disables Nagle's algorithm)
end;


procedure TKMNetClientLNet.Disconnected(aSocket: TLSocket);
begin
  fOnSessionDisconnected(Self);
end;


procedure TKMNetClientLNet.Receive(aSocket: TLSocket);
const
  BUFFER_SIZE = 10240; //10kb
var
  P: Pointer;
  L: Integer; //L could be -1 when no data is available
begin
  GetMem(P, BUFFER_SIZE+1); //+1 to avoid RangeCheckError when L = BufferSize
  L := aSocket.Get(P^, BUFFER_SIZE);

  if L > 0 then //if L=0 then exit;
    fOnRecieveData(P, L);

  FreeMem(P);
end;


procedure TKMNetClientLNet.Error(const aMsg: string; aSocket: TLSocket);
begin
  fOnError('LNet Client Error: ' + aMsg);
end;


procedure TKMNetClientLNet.UpdateStateIdle;
begin
  if fSocket <> nil then fSocket.CallAction; //Process network events
end;


end.
