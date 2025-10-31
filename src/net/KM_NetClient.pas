unit KM_NetClient;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, KM_NetTypes
  {$IFDEF WDC} ,KM_NetClientOverbyte {$ENDIF}
  {$IFDEF FPC} ,KM_NetClientLNet {$ENDIF}
  {,KM_Log};

{ Contains basic items we need for smooth Net experience:

    - connect to server
    - signal if we have successfully connected to server
    - signal if we could not connect to server

    - disconnect from server (always successful)
    - signal if we were forcefully disconnected by server

    - send binary data to other server clients
    - recieve binary data from other server clients

    - optionaly report non-important status messages }

type
  {$IFDEF WDC}
    TKMNetClientImplementation = class(TKMNetClientOverbyte);
  {$ENDIF}
  {$IFDEF FPC}
    TKMNetClientImplementation = class(TKMNetClientLNet);
  {$ENDIF}

  TKMNetClient = class;
  TNotifySenderDataEvent = procedure (aNetClient: TKMNetClient; aSenderIndex: SmallInt; aData: Pointer; aLength: Cardinal) of object;

  TKMNetClient = class
  private
    fClient: TKMNetClientImplementation;
    fConnected: Boolean;

    fTotalSize: Cardinal;
    fBufferSize: Cardinal;
    fBuffer: array of Byte;

    fOnConnectSucceed: TNotifyEvent;
    fOnConnectFailed: TGetStrProc;
    fOnForcedDisconnect: TNotifyEvent;
    fOnRecieveData: TNotifySenderDataEvent;
    fOnStatusMessage: TGetStrProc;
    procedure Error(const aText: string);
    procedure ConnectSucceed(Sender: TObject);
    procedure ConnectFailed(const aText: string);
    procedure ForcedDisconnect(Sender: TObject);
    procedure RecieveData(aData: Pointer; aLength: Cardinal);
  public
    constructor Create;
    destructor Destroy; override;

    property Connected: Boolean read fConnected;
    function MyIPString: string;
    function SendBufferEmpty: Boolean;

    procedure ConnectTo(const aAddress: string; const aPort: Word); //Try to connect to server
    property OnConnectSucceed: TNotifyEvent write fOnConnectSucceed; //Signal success
    property OnConnectFailed: TGetStrProc write fOnConnectFailed; //Signal fail and text description

    procedure Disconnect; //Disconnect from server
    property OnForcedDisconnect: TNotifyEvent write fOnForcedDisconnect; //Signal we were forcelly disconnected

    property OnRecieveData: TNotifySenderDataEvent write fOnRecieveData;
    procedure SetHandleBackgrounException;
    procedure SendData(aSender, aRecepient: TKMNetHandleIndex; aData: Pointer; aLength: Cardinal);
    procedure UpdateStateIdle;

    property OnStatusMessage: TGetStrProc write fOnStatusMessage;
  end;


implementation


 { TKMNetClient }
constructor TKMNetClient.Create;
begin
  inherited;

  fClient := TKMNetClientImplementation.Create;
  fConnected := False;
  SetLength(fBuffer, 0);
  fBufferSize := 0;
end;


destructor TKMNetClient.Destroy;
begin
  fClient.Free;
  inherited;
end;


function TKMNetClient.MyIPString:string;
begin
  Result := fClient.MyIPString;
end;


function TKMNetClient.SendBufferEmpty: Boolean;
begin
  Result := fClient.SendBufferEmpty;
end;


procedure TKMNetClient.Error(const aText: string);
begin
  if Assigned(fOnStatusMessage) then fOnStatusMessage('Client: Error ' + aText);
end;


procedure TKMNetClient.SetHandleBackgrounException;
begin
  fClient.SetHandleBackgrounException;
end;


procedure TKMNetClient.ConnectTo(const aAddress: string; const aPort: Word);
begin
  SetLength(fBuffer, 0);
  fBufferSize := 0;
  fClient.OnError := Error;
  fClient.OnConnectSucceed := ConnectSucceed;
  fClient.OnConnectFailed := ConnectFailed;
  fClient.OnSessionDisconnected := ForcedDisconnect;
  fClient.OnRecieveData := RecieveData;
  fClient.ConnectTo(aAddress, aPort);
  if Assigned(fOnStatusMessage) then fOnStatusMessage('Client: Connecting..');
end;


procedure TKMNetClient.ConnectSucceed(Sender: TObject);
begin
  fConnected := True;
  if Assigned(fOnStatusMessage) then fOnStatusMessage('Client: Connected');
  if Assigned(fOnConnectSucceed) then fOnConnectSucceed(Self);
end;


procedure TKMNetClient.ConnectFailed(const aText: string);
begin
  fConnected := False;
  if Assigned(fOnStatusMessage) then fOnStatusMessage('Client: Connection failed. ' + aText);
  if Assigned(fOnConnectFailed) then fOnConnectFailed(aText);
end;


procedure TKMNetClient.Disconnect;
begin
  fOnConnectSucceed := nil;
  fOnConnectFailed := nil;
  fOnForcedDisconnect := nil;
  fOnRecieveData := nil;
  fOnStatusMessage := nil;

  SetLength(fBuffer,0);
  fBufferSize := 0;

  fConnected := False;
  fClient.Disconnect;
end;


//Happens in following cases:
//  - when we deliberately disconnect
//  - when connection failed
//  - when server disconnects us
procedure TKMNetClient.ForcedDisconnect(Sender: TObject);
begin
  if fConnected then
  begin
    if Assigned(fOnStatusMessage) then
      fOnStatusMessage('Client: Forced disconnect');
    if Assigned(fOnForcedDisconnect) then
      fOnForcedDisconnect(Self);
  end;
  fConnected := False;
end;


// Assemble the packet as [Sender.Recepient.Length.Data]
// We can pack/clean the header later on (if we hit bandwidth limits)
procedure TKMNetClient.SendData(aSender, aRecepient: TKMNetHandleIndex; aData: Pointer; aLength: Cardinal);
var
  P: Pointer;
begin
  // We use fSocket.Shutdown(1) for disconnection in Overbyte implementation,
  // then we have to check if we actually connected to server before sending any data
  // Otherwise we could get "ESocketException: Can't send after socket shutdown"
  if not fConnected then Exit;

  Assert(aLength <= MAX_PACKET_SIZE, 'Packet over size limit');

  // Sender    2bytes
  // Recepient 2bytes
  // Length    2bytes
  //.Data      MAX_PACKET_SIZE
  GetMem(P, aLength + 6);
  try
    PKMNetHandleIndex(P)^ := aSender;
    PKMNetHandleIndex(NativeUInt(P) + 2)^ := aRecepient;
    PWord(NativeUInt(P) + 4)^ := aLength;
    Move(aData^, Pointer(NativeUInt(P) + 6)^, aLength);
    fClient.SendData(P, aLength + 6);
  finally
    FreeMem(P);
  end;
end;


//Split recieved data into single packets
procedure TKMNetClient.RecieveData(aData: Pointer; aLength: Cardinal);
var
  packetSender: TKMNetHandleIndex;
  packetLength: Word;
//  HeaderSize: Byte;
begin
  //Append new data to buffer
  SetLength(fBuffer, fBufferSize + aLength);
  Move(aData^, fBuffer[fBufferSize], aLength);
  fBufferSize := fBufferSize + aLength;
  //gLog.AddTime('############### recieve data: Length = ' + IntToStr(aLength) + ' fBufferSize = ' + IntTOStr(fBufferSize));

  //HeaderSize := 2*SizeOf(TKMNetHandleIndex) +

  while fBufferSize >= 1 do
  begin
    //Try to read data packet from buffer
//    PacksCnt := PNativeUInt(@fBuffer[0])^;
    //gLog.AddTime('%%%%% receive cumulative packet: packs Cnt = ' + IntToStr(PacksCnt));
    while (fBufferSize >= 7) and (PByte(@fBuffer[0])^ > 0) do
    begin
      packetSender := PKMNetHandleIndex(@fBuffer[1])^;
      //We skip PacketRecipient because thats us
      packetLength := PWord(@fBuffer[5])^;

      //gLog.AddTime('pack %d: sender = %s length = %d' , [PacksCnt - PNativeUInt(@fBuffer[0])^ + 1, GetNetAddressStr(PacketSender), PacketLength]);
      //Buffer is lengthy enough to contain full packet, process it
      if packetLength <= fBufferSize - 7 then
      begin
        Inc(fTotalSize, packetLength);
        //Skip packet header
        // Check if fOnReceiveData is assigned (TKMServerQuery could disconnect client but some messages can still arrive and we are in a different thread at this moment)
        if Assigned(fOnRecieveData) then
          fOnRecieveData(Self, packetSender, @fBuffer[7], packetLength);

        //Check if Network was stopped by processing above packet (e.g. version mismatch)
        if not Assigned(fOnRecieveData) then
          Exit;

        //Trim received packet from buffer
        if packetLength < fBufferSize - 7 then //Check range
          Move(fBuffer[7 + packetLength], fBuffer[1], fBufferSize-packetLength-7);
        fBufferSize := fBufferSize - packetLength - 6;
        PByte(@fBuffer[0])^ := PByte(@fBuffer[0])^ - 1;
      end else
      begin
        //gLog.AddTime('---xxx break: PacketLength = %d < %d = BufferSize-16', [PacketLength, fBufferSize-16]);
        Break;
      end;
    end;
    if PByte(@fBuffer[0])^ = 0 then
    begin
      Move(fBuffer[1], fBuffer[0], fBufferSize - 1);
      fBufferSize := fBufferSize - 1;
      //gLog.AddTime('---%%%% End of cumulative packet. TotalSize = ' + IntToStr(fTotalSize));
      fTotalSize := 0;
    end else
      Exit;
  end;
end;


procedure TKMNetClient.UpdateStateIdle;
begin
  {$IFDEF FPC} fClient.UpdateStateIdle; {$ENDIF}
end;


end.
