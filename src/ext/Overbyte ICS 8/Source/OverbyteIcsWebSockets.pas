{*_* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Author:       Stan Korotky <stasson@orc.ru>
Description:  Websocket server implementation (HIXIE and HYBIE protocols)
              (ported from phpws project)
Creation:     05 Mar 2012
Updated:      March 2020
Version:      8.64
EMail:        francois.piette@overbyte.be  http://www.overbyte.be
Support:      https://en.delphipraxis.net/forum/37-ics-internet-component-suite/
Legal issues: Copyright (C) 1999-2020 by François PIETTE
              Rue de Grady 24, 4053 Embourg, Belgium.
              <francois.piette@overbyte.be>
              Portions Copyright (C) 2011, 2012 Chris Tanaskoski,
              https://github.com/Devristo/phpws/

              This software is provided 'as-is', without any express or
              implied warranty.  In no event will the author be held liable
              for any  damages arising from the use of this software.

              Permission is granted to anyone to use this software for any
              purpose, including commercial applications, and to alter it
              and redistribute it freely, subject to the following
              restrictions:

              1. The origin of this software must not be misrepresented,
                 you must not claim that you wrote the original software.
                 If you use this software in a product, an acknowledgment
                 in the product documentation would be appreciated but is
                 not required.

              2. Altered source versions must be plainly marked as such, and
                 must not be misrepresented as being the original software.

              3. This notice may not be removed or altered from any source
                 distribution.


Comment from the author:
Subject:  [twsocket] Design principles of WebSockets server for ICS
From: "Stan" <stasson@orc.ru>
To: "ICS support mailing" <twsocket@elists.org>
Date: Sun, 4 Mar 2012 18:09:14 +0300
The test project uses port number 12345 for websocket connections
by default. Test client web-page is also included and uses the same port.
All websockets-related stuff is implemented as a set of classes/units inside
'websockets' folder. Actually, this is a port of phpws project available at
https://github.com/Devristo/phpws/.
There is no a specific component for websockets, they are handled internally
from a custom TWebSockSrvClient.


Please note this is an experiemental server websocket implementation, that needs
a lot more testing in case the protocol has changed in the last eight years.

History:
05 Mar 2012   V0.01 Initial release
23 Nov 2012   Bug fix in cookie_parse
Mar 13, 2020 - V8.64 - Angus combined several original units into single unit
                        here, renamed main derived client to TWebSockSrvClient
                        to avoid conflicts with other components.

Pending
Integrate with ICS web server so it can listen on same address and port as main web server.
SSL support, wss:// protocol.
Client component. 
Replace AnsiStrings where not actually needed!!!!

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

Unit OverbyteIcsWebSockets;

interface

uses
  Classes,
  SysUtils,
  Math,
  OverbyteIcsWSocket,
  OverbyteIcsWSocketS,
  OverbyteIcsTypes,
  OverbyteIcsUrl,
  OverbyteIcsSha1,
  OverbyteIcsMimeUtils,
  OverbyteIcsMd5;

type
  TWebSocketSocket = class;

  {
   * Enum-like construct containing all opcodes defined in the WebSocket protocol
   *
  }
  TWebSocketOpcode = (
      __default = 0,
      ContinuationFrame = $00,
      TextFrame = $01,
      BinaryFrame = $02,
      CloseFrame = $08,
      PingFrame = $09,
      PongFrame = $09);

  {
   * Interface for WebSocket frames. One or more frames compose a message.
   * In the case of the Hixie protocol, a message contains of one frame only
  }
  TWebSocketFrame = class
    public
      {
       * Serialize the frame so that it can be send over a socket
       * @return AnsiString Serialized binary AnsiString
      }
      function encode: AnsiString; virtual; abstract;

      {
       * @return AnsiString Payload Data inside the frame
      }
      function getData: AnsiString; virtual; abstract;

      {
       * @return int The frame type
      }
      function getType: TWebSocketOpcode; virtual; abstract;

      function isReady: Boolean; virtual; abstract;

      {
       * Deserialize a binary AnsiString into a IWebSocketFrame
       * @return AnsiString Serialized binary AnsiString
      }
      class function decode(var raw: AnsiString; head: TWebSocketFrame = nil): TWebSocketFrame; virtual; abstract;

      {
       * Create a frame by type and payload data
       * @param int $type
       * @param AnsiString $data
      }
      constructor Create(code: TWebSocketOpcode; data: AnsiString = ''); virtual; abstract;
      destructor Destroy; override;

  end;

  TWebSocketFrameEnumerator = class
    private
      _pointers: TList;
    public
      constructor Create;
      destructor Destroy; override;
      procedure Add(tframe: TWebSocketFrame);
      procedure Delete(index: Integer);
      function Count: Integer;
      function Get(index: Integer): TWebSocketFrame;
      property Frame[index: Integer]: TWebSocketFrame read Get;
  end;

  IWebSocketMessage = class
    {
     * Retreive an array of frames of which this message is composed
     *
     * @return WebSocketFrame[]
    }
    function getFrames: TWebSocketFrameEnumerator; virtual; abstract;
    {
     * Set the body of the message
     * This should recompile the array of frames
     * @param AnsiString data
    }
    procedure setData(data: AnsiString); virtual; abstract;
    {
     * Retreive the body of the message
     * @return AnsiString
    }
    function getData: AnsiString; virtual; abstract;
    {
     * Check if we have received the last frame of the message
     *
     * @return boolean
    }
    function isFinalised: boolean; virtual; abstract;

    procedure takeFrame(pframe: TWebSocketFrame); virtual; abstract;
  end;


  IWebSocketConnection = class
    function sendHandshakeResponse: Boolean; virtual; abstract;

    function readFrame(data: AnsiString): TWebSocketFrame; virtual; abstract;
    function sendFrame(tframe: TWebSocketFrame): Boolean; virtual; abstract;
    function sendMessage(msg: IWebSocketMessage): Boolean; virtual; abstract;
    procedure sendString(msg: AnsiString); virtual; abstract;

    function getHeaders: TStringList; virtual; abstract;
    function getUriRequested: AnsiString; virtual; abstract;
    function getCookies: TStringList; virtual; abstract;

    procedure disconnect; virtual; abstract;
  end;


  TWebSocketMessage = procedure(Sender: TObject; Msg: String) of object;
  TWebSessionConnected = procedure(Sender: TObject; con: IWebSocketConnection) of object;


  TWebSocketMessageHybie = class (IWebSocketMessage)
    public
      constructor Create(data: AnsiString);
      destructor Destroy; override;
      procedure createFrames;
      {
       * Create a message from it's first frame
       * @param IWebSocketFrame $frame
      }
      class function fromFrame(tframe: TWebSocketFrame): IWebSocketMessage;

      // interface
      function getFrames: TWebSocketFrameEnumerator; override;
      procedure setData(data: AnsiString); override;
      function getData: AnsiString; override;
      function isFinalised: boolean; override;
      procedure takeFrame(tframe: TWebSocketFrame); override;
    protected
      _frames: TWebSocketFrameEnumerator;
      _data: AnsiString;
  end;

  TWebSocketMessageHixie = class (IWebSocketMessage)
    public
      constructor Create(data: AnsiString);
      destructor Destroy; override;
      class function fromFrame(tframe: TWebSocketFrame): IWebSocketMessage;

      // interface
      function getFrames: TWebSocketFrameEnumerator; override;
      procedure setData(data: AnsiString); override;
      function getData: AnsiString; override;
      function isFinalised: Boolean; override;
      procedure takeFrame(tframe: TWebSocketFrame); override;
    protected
      _frame: TWebSocketFrame;
      _data: AnsiString;
  end;

  TWebSocketFrameHybie = class (TWebSocketFrame)
    protected
      // First Byte
      FIN: Integer;
      RSV1: Integer;
      RSV2: Integer;
      RSV3: Integer;
      opcode: TWebSocketOpcode;

      // Second Byte
      mask: Integer;
      payloadLength: Integer;
      maskingKey: AnsiString;

      payloadData: AnsiString;
      actualLength: Integer;

    public
      constructor Create(code: TWebSocketOpcode; data: AnsiString = ''); override;
      function encode: AnsiString; override;
      function getData: AnsiString; override;
      function getType: TWebSocketOpcode; override;
      class function decode(var raw: AnsiString; head: TWebSocketFrame = nil): TWebSocketFrame; override;
      function isReady: Boolean; override;

      function isFinal: Boolean;
      function isMasked: Boolean;

    protected
      procedure setType(code: TWebSocketOpcode);
  end;

  TWebSocketFrame76 = class (TWebSocketFrame)
    public
      payloadData: AnsiString;
      constructor Create(code: TWebSocketOpcode; data: AnsiString = ''); override;

      function encode: AnsiString; override;
      function getData: AnsiString; override;
      function getType: TWebSocketOpcode; override;
      class function decode(var raw: AnsiString; head: TWebSocketFrame = nil): TWebSocketFrame; override;
      function isReady: Boolean; override;

    protected
      opcode: TWebSocketOpcode;
  end;


  { TWebSockSrvClient is the class which will be instanciated by server component }
  { for each new client. N simultaneous clients means N TWebSockSrvClient will be }
  { instanciated. Each being used to handle only a single client.             }
  { We can add any data that has to be private for each client, such as       }
  { receive buffer or any other data needed for processing.                   }
  TWebSockSrvClient = class(TWSocketClient)
    protected
      FOnWebSocketMessage : TWebSocketMessage;
      FOnWebSocketConnected : TWebSessionConnected;
    public
      RcvdLine    : String;
      ConnectTime : TDateTime;
      property OnWebSocketMessage : TWebSocketMessage read  FOnWebSocketMessage
                                                      write FOnWebSocketMessage;
      property OnWebSocketConnected : TWebSessionConnected read  FOnWebSocketConnected
                                                      write FOnWebSocketConnected;
  end;

  TWebSocketSocket = class
    public
      constructor Create(socket: TWebSockSrvClient);
      destructor Destroy; override;
      function getResource: TWebSockSrvClient;

      // procedure setConnection(con: IWebSocketConnection);
      // to be used by implementors of clients, server creates connections internally

      function getConnection: IWebSocketConnection;
      procedure establishConnection(data: AnsiString);

      procedure onMessage(m: IWebSocketMessage);

      procedure onData(data: AnsiString); // read from client
      procedure write(data: AnsiString);  // write to client
      procedure disconnect;

      function getLastChanged: TDateTime;

    protected
      procedure handleSessionClosed(Sender: TObject; ErrCode: Word);
      procedure handleDataAvailable(Sender: TObject; ErrCode: Word);

    private
      _socket: TWebSockSrvClient;
      _con: IWebSocketConnection;
      _lastChanged: TDateTime;

  end;


  TWebSocketConnectionFactory = class
  public
    class function fromSocketData(socket: TWebSocketSocket; data: AnsiString): IWebSocketConnection;
  end;

  // default base implementation
  TWebSocketConnection = class (IWebSocketConnection)
    public
      constructor Create(socket: TWebSocketSocket; headers: TStringList);
      destructor Destroy; override;
      procedure setHeaders(headers: TStringList);

      // interface
      function sendHandshakeResponse: Boolean; override;

      function readFrame(data: AnsiString): TWebSocketFrame; override;
      function sendFrame(tframe: TWebSocketFrame): Boolean; override;
      function sendMessage(msg: IWebSocketMessage): Boolean; override;
      procedure sendString(msg: AnsiString); override;

      function getHeaders: TStringList; override;
      function getUriRequested: AnsiString; override;
      function getCookies: TStringList; override;

      procedure disconnect; override;

    protected
      _headers: TStringList;
      _socket: TWebSocketSocket;
      _cookies: TStringList;
      _parameters: TStringList;

      procedure getQueryParts;
  end;

  TWebSocketConnectionHybie = class (TWebSocketConnection)
    public
      constructor Create(socket: TWebSocketSocket; headers: TStringList);

      // interface
      function sendHandshakeResponse: Boolean; override;

      function readFrame(data: AnsiString): TWebSocketFrame; override;
      procedure sendString(msg: AnsiString); override;

      procedure disconnect; override;

    protected
      procedure processMessageFrame(tframe: TWebSocketFrameHybie);
      procedure processControlFrame(tframe: TWebSocketFrameHybie);

    private
      _openMessage: IWebSocketMessage;
      _lastFrame: TWebSocketFrameHybie;
  end;

  TWebSocketConnectionHixie = class (TWebSocketConnection)
    public
      constructor Create(socket: TWebSocketSocket; headers: TStringList; clientHandshake: AnsiString);

      // interface
      function sendHandshakeResponse: Boolean; override;

      function readFrame(data: AnsiString): TWebSocketFrame; override;
      procedure sendString(msg: AnsiString); override;

      procedure disconnect; override;

    private
      _clientHandshake: AnsiString;
  end;

  THixieKey = class
  public
    number: Integer;
    key: AnsiString;
    constructor Create(number: Integer; key: AnsiString);
    end;

  TWebSocketProtocolVersions =
    (HIXIE_76 = 0, HYBI_8 = 8, HYBI_9 = 8, HYBI_10 = 8, HYBI_11 = 8, HYBI_12 = 8, LATEST = 8);

  TWebSocketFunctions = class
    class function cookie_parse(line: AnsiString): TStringList;
    class function parseHeaders(header: AnsiString): TStringList;
    class function calcHybiResponse(challenge: AnsiString): AnsiString;
    class function calcHixieResponse(key1, key2, l8b: AnsiString): AnsiString;
    class function randHybiKey: AnsiString;
    class procedure say(msg: String = '');
    class function genKey3: AnsiString;
    class function randHixieKey: THixieKey;
  public
  end;


implementation


function IsBitSet(byte: Byte; p: Integer): Boolean; forward;
function rotMask(data: AnsiString; key: AnsiString; offset: Integer = 0): AnsiString; forward;
// HYBIE

constructor TWebSocketMessageHybie.Create(data: AnsiString);
begin
  _frames := TWebSocketFrameEnumerator.Create;
  _data := '';
  if data <> '' then
    setData(data);
end;

destructor TWebSocketMessageHybie.Destroy;
var
  i: Integer;
begin
  for i := 0 to _frames.Count - 1 do
    _frames.Frame[i].Free;

  _frames.Free;
end;

procedure TWebSocketMessageHybie.createFrames;
var
  t: TWebSocketFrame;
begin
  t := TWebSocketFrameHybie.Create(TextFrame, _data);
  _frames.Add(t);
end;

{
 * Create a message from it's first frame
 * @param IWebSocketFrame $frame
}
class function TWebSocketMessageHybie.fromFrame(tframe: TWebSocketFrame): IWebSocketMessage;
var
  m: IWebSocketMessage;
begin
  m := TWebSocketMessageHybie.Create('');

  m.takeFrame(TWebSocketFrame(tframe));
  Result := m;
end;

function TWebSocketMessageHybie.getFrames: TWebSocketFrameEnumerator;
begin
  Result := _frames;
end;

procedure TWebSocketMessageHybie.setData(data: AnsiString);
begin
  _data := data;
  createFrames;
end;

function TWebSocketMessageHybie.getData: AnsiString;
var
  i: Integer;
begin
  if not isFinalised then
    raise Exception.Create('WebSocketMessageNotFinalised');

  _data := '';

  for i := 0 to _frames.Count - 1 do
    _data := _data + _frames.Frame[i].getData;

  Result := _data;
end;

function TWebSocketMessageHybie.isFinalised: boolean;
var
  f: TWebSocketFrameHybie;
begin
  if _frames.Count = 0 then
  begin
    result := false;
    exit;
  end;

  f := TWebSocketFrameHybie(_frames.Frame[_frames.Count - 1]);
  Result := f.isFinal;
end;

procedure TWebSocketMessageHybie.takeFrame(tframe: TWebSocketFrame);
begin
  _frames.Add(tframe);
end;

// HIXIE

constructor TWebSocketMessageHixie.Create(data: AnsiString);
begin
  if data <> '' then
    setData(data);
end;

destructor TWebSocketMessageHixie.Destroy;
begin
  if Assigned(_frame) then _frame.Free;
end;

class function TWebSocketMessageHixie.fromFrame(tframe: TWebSocketFrame): IWebSocketMessage;
begin
  Result := TWebSocketMessageHixie.Create('');
  Result.takeFrame(tframe);
end;

function TWebSocketMessageHixie.getFrames: TWebSocketFrameEnumerator;
var
  e: TWebSocketFrameEnumerator;
begin
  e := TWebSocketFrameEnumerator.Create;
  e.Add(_frame);
  Result := e;
end;

procedure TWebSocketMessageHixie.setData(data: AnsiString);
var
  tframe: TWebSocketFrame76;
begin
  _data := data;
  tframe := TWebSocketFrame76.create(TextFrame, data);
  _frame := TWebSocketFrame(tframe);
end;

function TWebSocketMessageHixie.getData: AnsiString;
begin
  Result := _frame.getData;
end;

function TWebSocketMessageHixie.isFinalised: boolean;
begin
  Result := true;
end;

procedure TWebSocketMessageHixie.takeFrame(tframe: TWebSocketFrame);
begin
  _frame := tframe;
end;

type
  THixieResponse = packed record
    key1     : Integer;
    key2     : Integer;
    suffix   : array[0..7] of Byte;
  end;

constructor THixieKey.Create(number: Integer; key: AnsiString);
begin
  self.number := number;
  self.key := key;
end;

{
     * Parse a HTTP HEADER 'Cookie:' value into a key-value pair array
     *
     * @param AnsiString $line Value of the COOKIE header
     * @return array Key-value pair array
}
class function TWebSocketFunctions.cookie_parse(line: AnsiString): TStringList;
var
  cookies: TStringList;
  csplit: TStringList;
  cinfo: TStringList;
  i: Integer;
  key, val: AnsiString;
begin
  cookies := TStringList.Create;
  csplit := TStringList.Create;
  csplit.Delimiter := ';';

  cinfo := TStringList.Create;
  cinfo.Delimiter := '=';

  csplit.DelimitedText := String(line);

  for i := 0 to csplit.Count - 1 do
  begin
    cinfo.DelimitedText := csplit.Strings[i];

    key := AnsiString(Trim(cinfo.Strings[0]));
    val := AnsiString(UrlDecode(cinfo.Strings[1])); // can be empty

    cookies.Add(String(key + '=' + val));

  end;

  cinfo.Free;
  csplit.Free;

  Result := cookies;
end;

{
     * Parse HTTP request into an array
     *
     * @param AnsiString header HTTP request as a AnsiString
     * @return array Headers as a key-value pair array
}
class function TWebSocketFunctions.parseHeaders(header: AnsiString): TStringList;
var
  HeaderList: TStringList;
  retVal: TStringList;
  i, k, p: Integer;
  name, value: String;
begin
  retVal := TStringList.Create;
  HeaderList := TStringList.Create;
  HeaderList.Delimiter := #10;
  HeaderList.Text := String(header);
  // unfold header lines, removing internal linebreaks
  k := 0;
  for i := 0 to HeaderList.Count - 1 do
  begin
    if Length(HeaderList.Strings[i]) = 0 then continue;
    if (HeaderList.Strings[i][1] = AnsiChar(9)) or (HeaderList.Strings[i][1] = AnsiChar(32)) then
    begin
      HeaderList.Strings[k] := HeaderList.Strings[k] + Trim(HeaderList.Strings[i]);
      HeaderList.Strings[i] := '';
    end
    else
    begin
      HeaderList.Strings[i] := Trim(HeaderList.Strings[i]);
      k := i; // store index of starting line
    end;
  end;

  for i := 0 to HeaderList.Count - 1 do
  begin
    if Length(HeaderList.Strings[i]) > 0 then
    begin
      if Copy(HeaderList.Strings[i], 1, 3) = 'GET' then
      begin
        p := Pos(' HTTP/', HeaderList.Strings[i]);
        name := 'GET';
        value := Copy(HeaderList.Strings[i], 5, p - 5);
      end
      else
      begin
        p := Pos(':', HeaderList.Strings[i]);
        name := Trim(Copy(HeaderList.Strings[i], 1, p - 1));
        value := Trim(Copy(HeaderList.Strings[i], p + 1, MaxInt));
      end;
      retVal.Add(name + '=' + value);
    end;
  end;

  HeaderList.Free;

    Result := retVal;
end;

class function TWebSocketFunctions.calcHybiResponse(challenge: AnsiString): AnsiString;
begin
  Result := Base64Encode(SHA1ofStr(challenge + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'));
end;

procedure HixieTest;
begin
  TWebSocketFunctions.say(String(TWebSocketFunctions.calcHixieResponse('3e6b263  4 17 80', '17  9 G`ZD9   2 2b 7X 3 /r90', 'WjN}|M(6')));
end;

function GetMD5Raw(Buffer: Pointer; BufSize: Integer): AnsiString;
var
    I          : Integer;
    MD5Digest  : TMD5Digest;
    MD5Context : TMD5Context;
begin
    for I := 0 to 15 do
        Byte(MD5Digest[I]) := I + 1;
    MD5Init(MD5Context);
    MD5UpdateBuffer(MD5Context, Buffer, BufSize);
    MD5Final(MD5Digest, MD5Context);
    //Result := MD5Digest;
    SetString(Result, PAnsiChar(@MD5Digest[0]), 16);
end;

function PackN64(num: Int64): AnsiString;
begin
  Result :=
    AnsiChar((num and $ff00000000000000) shr 56)
  + AnsiChar((num and $ff000000000000) shr 48)
  + AnsiChar((num and $ff0000000000) shr 40)
  + AnsiChar((num and $ff00000000) shr 32)
  + AnsiChar((num and $ff000000) shr 24)
  + AnsiChar((num and $ff0000) shr 16)
  + AnsiChar((num and $ff00) shr 8)
  + AnsiChar(num and $ff);
end;

function PackN32(num: Cardinal): AnsiString;
begin
  Result :=
    AnsiChar((num and $ff000000) shr 24)
  + AnsiChar((num and $ff0000) shr 16)
  + AnsiChar((num and $ff00) shr 8)
  + AnsiChar(num and $ff);
end;

function UnPackN32(x: AnsiString): Cardinal;
begin
  Result :=
    (Ord(x[1]) shl 24)
  + (Ord(x[2]) shl 16)
  + (Ord(x[3]) shl 8)
  + Ord(x[4]);
end;

function PackN16(num: Word): AnsiString;
begin
  Result := AnsiChar((num and $ff00) shr 8) + AnsiChar(num and $ff);
end;

function UnPackN16(x: AnsiString): Word;
begin
  Result := (Ord(x[1]) shl 8) + Ord(x[2]);
end;

{
     * Calculate the #76 draft key based on the 2 challenges from the client and the last 8 bytes of the request
     *
     * @param AnsiString key1 Sec-WebSocket-Key1
     * @param AnsiString key2 Sec-Websocket-Key2
     * @param AnsiString l8b Last 8 bytes of the client's opening handshake
}
class function TWebSocketFunctions.calcHixieResponse(key1, key2, l8b: AnsiString): AnsiString;
var
  numbers1, numbers2: AnsiString;
  num1, num2: Int64;
  spaces1, spaces2: Integer;
  i: Integer;
  complex: THixieResponse;
begin
  spaces1 := 0;
  spaces2 := 0;

  for i := 1 to Length(key1) do
  begin
    if (key1[i] >= '0') and (key1[i] <= '9') then numbers1 := numbers1 + key1[i];
    if key1[i] = ' ' then Inc(spaces1);
  end;

  for i := 1 to Length(key2) do
  begin
    if (key2[i] >= '0') and (key2[i] <= '9') then numbers2 := numbers2 + key2[i];
    if key2[i] = ' ' then Inc(spaces2);
  end;

  if (spaces1 = 0) or (spaces2 = 0) then
    raise Exception.Create('WebSocketInvalidKeyException:Space');

  num1 := StrToInt64(String(numbers1));
  num2 := StrToInt64(String(numbers2));

  if (num1 mod spaces1 <> 0) or (num2 mod spaces2 <> 0) then
    raise Exception.Create('WebSocketInvalidKeyException:Mod');

  num1 := num1 div spaces1;
  num2 := num2 div spaces2;

  complex.key1 := swap(num1 shr 16) or (longint(swap(num1 and $ffff)) shl 16);
  complex.key2 := swap(num2 shr 16) or (longint(swap(num2 and $ffff)) shl 16);
  Move(l8b[1], complex.suffix, 8 * SizeOf(AnsiChar));

  result := GetMD5Raw(@complex, 16);

end;

class function TWebSocketFunctions.randHybiKey: AnsiString;
begin
    Result := Base64Encode(
            AnsiChar(random(256)) + AnsiChar(random(256)) + AnsiChar(random(256)) + AnsiChar(random(256))
            + AnsiChar(random(256)) + AnsiChar(random(256)) + AnsiChar(random(256)) + AnsiChar(random(256))
            + AnsiChar(random(256)) + AnsiChar(random(256)) + AnsiChar(random(256)) + AnsiChar(random(256))
            + AnsiChar(random(256)) + AnsiChar(random(256)) + AnsiChar(random(256)) + AnsiChar(random(256))
        );
end;

class procedure TWebSocketFunctions.say(msg: String = '');
begin
//  WebSocketForm.Display(msg);  angus diag 
end;

class function TWebSocketFunctions.genKey3: AnsiString;
begin
    Result := AnsiString('') + AnsiChar(random(256)) + AnsiChar(random(256)) + AnsiChar(random(256)) + AnsiChar(random(256))
                 + AnsiChar(random(256)) + AnsiChar(random(256)) + AnsiChar(random(256)) + AnsiChar(random(256));
end;

class function TWebSocketFunctions.randHixieKey: THixieKey;
var
  spaces_n: Integer;
  max_n: Integer;
  number_n: Integer;
  product_n: Int64;
  key_n, key_n1, key_n2: AnsiString;
  range: Integer;
  i: Integer;
  c: AnsiChar;
  len: Integer;
  p: Integer;
begin
  spaces_n := random(12) + 1;

  max_n := MaxInt div spaces_n;
  number_n := random(max_n + 1);
  product_n := number_n * spaces_n;
  key_n := AnsiString(IntToStr(product_n));
  range := random(12) + 1;
  for i := 0 to range - 1 do
  begin
    if (random(2) > 0 ) then
            c := AnsiChar(random($2f + 1) + $21)
        else
            c := AnsiChar(random($7e + 1) + $3a);
    len := Length(key_n);
    p := random(len + 1);
    key_n1 := Copy(key_n, 1, p);
    key_n2 := Copy(key_n, p + 1, MaxInt);
    key_n := key_n1 + c + key_n2;
  end;

  for i := 0 to spaces_n - 1 do
  begin
    len := Length(key_n);
    p := random(len) + 1;
    key_n1 := Copy(key_n, 1, p);
    key_n2 := Copy(key_n, p + 1, MaxInt);
    key_n := key_n1 + ' ' + key_n2;
  end;

  Result := THixieKey.Create(number_n, key_n);

end;


////////////////////////////////////////////


{
 * Check if a opcode is a control frame. Control frames should be handled internally by the server.
 * @param TWebSocketOpcode type
}
function isControlFrame(code: TWebSocketOpcode): Boolean;
begin
  Result := false;

  if (code = CloseFrame) or
     (code = PingFrame) or
     (code = PongFrame) then
      Result := true;
end;

{
 * HYBIE WebSocketFrame
}
constructor TWebSocketFrameHybie.Create(code: TWebSocketOpcode; data: AnsiString = '');
begin
  FIN := 1;
  RSV1 := 0;
  RSV2 := 0;
  RSV3 := 0;
  setType(code);

  mask := 0;
  payloadLength := Length(data);
  maskingKey := '';

  payloadData := data;

  actualLength := 0;
end;

destructor TWebSocketFrame.Destroy;
begin
end;

function TWebSocketFrameHybie.isMasked: Boolean;
begin
  Result := (mask = 1);
end;

procedure TWebSocketFrameHybie.setType(code: TWebSocketOpcode);
begin
  opcode := code;

  if (code = CloseFrame) then
    mask := 1;
end;

function IsBitSet(byte: Byte; p: Integer): Boolean;
begin
  Result := (byte and (1 shl p)) > 0;
end;

function rotMask(data: AnsiString; key: AnsiString; offset: Integer = 0): AnsiString;
var
  i, j: Integer;
begin
  for i := 1 to Length(data) do
  begin
    j := (i - 1 + offset) mod 4;
    Result := Result + AnsiChar(Ord(data[i]) xor Ord(Key[j + 1]));
  end;
end;

function TWebSocketFrameHybie.getType: TWebSocketOpcode;
begin
  Result := opcode;
end;

function TWebSocketFrameHybie.encode: AnsiString;
var
  firstByte, secondByte: Byte;
  encoded, key: AnsiString;
begin
  payloadLength := Length(payloadData);

  firstByte := Integer(opcode);

  firstByte := firstByte + FIN * 128 + RSV1 * 64 + RSV2 * 32 + RSV3 * 16;

  encoded := AnsiChar(firstByte);

  if (payloadLength <= 125) then
  begin
    secondByte := payloadLength;
    secondByte := secondByte + mask * 128;
    encoded := encoded + AnsiChar(secondByte);
  end
  else
  if (payloadLength <= 255 * 255 - 1) then
  begin
    secondByte := 126;
    secondByte := secondByte + mask * 128;
    encoded := encoded + AnsiChar(secondByte) + packN16(payloadLength);
  end
  else
  begin
    secondByte := 127;
    secondByte := secondByte + mask * 128;
    encoded := encoded + AnsiChar(secondByte);
    encoded := encoded + packN64(payloadLength);
  end;

  key := '';
  if (mask = 1) then
  begin
    key := packN32(random(MaxInt));
    encoded := encoded + key;
  end;

  if (Length(payloadData) > 0) then
  begin
    if mask = 1 then
      encoded := encoded + rotMask(payloadData, key)
    else
      encoded := encoded + payloadData;
  end;

  Result := encoded;
end;

class function TWebSocketFrameHybie.decode(var raw: AnsiString; head: TWebSocketFrame = nil): TWebSocketFrame;
var
  tframe: TWebSocketFrame;
  this: TWebSocketFrameHybie;
  firstByte, secondByte: Byte;
  len: Integer;
  currentOffset, fullLength: Integer;
  frameData: AnsiString;
  h, l: Cardinal;
begin
  if head <> nil then
  begin
    this := TWebSocketFrameHybie(head);
  end
  else
  begin
    tframe := TWebSocketFrameHybie.Create(TextFrame);
    this := TWebSocketFrameHybie(tframe);

    // Read the first two bytes, then chop them off
    firstByte := Byte(raw[1]);
    secondByte := Byte(raw[2]);
    raw := Copy(raw, 3, MaxInt);

    this.FIN := Integer(IsBitSet(firstByte, 7));
    this.RSV1 := Integer(IsBitSet(firstByte, 6));
    this.RSV2 := Integer(IsBitSet(firstByte, 5));
    this.RSV3 := Integer(IsBitSet(firstByte, 4));

    this.mask := Integer(IsBitSet(secondByte, 7));

    this.opcode := TWebSocketOpcode(firstByte and $F);

    len := secondByte and (not 128);

    if (len <= 125) then
      this.payloadLength := len
    else
    if (len = 126) then
    begin
      this.payloadLength := UnPackN16(raw);
      raw := Copy(raw, 3, MaxInt);
    end
    else
    if (len = 127) then
    begin
      h := UnPackN32(raw);
      raw := Copy(raw, 5, MaxInt);
      l := UnPackN32(raw);
      this.payloadLength := (l + (h * $100000000));
      raw := Copy(raw, 5, MaxInt);
    end;

    if (this.mask = 1) then
    begin
      this.maskingKey := Copy(raw, 1, 4);
      raw := Copy(raw, 5, MaxInt);
    end;
  end;

  currentOffset := this.actualLength;
  fullLength := min(this.payloadLength - this.actualLength, Length(raw));
  this.actualLength := this.actualLength + fullLength;

  if (fullLength < Length(raw)) then
  begin
    frameData := Copy(raw, 1, fullLength);
    raw := Copy(raw, fullLength + 1, MaxInt);
  end
  else
  begin
    frameData := raw;
    raw := '';
  end;

  if (this.mask = 1) then
    this.payloadData := this.payloadData + rotMask(frameData, this.maskingKey, currentOffset)
  else
    this.payloadData := this.payloadData + frameData;

  Result := this;
end;

function TWebSocketFrameHybie.isReady: Boolean;
begin
  if (actualLength > payloadLength) then
    raise Exception.Create('WebSocketFrameSizeMismatch')
  else
    Result := (actualLength = payloadLength);
end;

function TWebSocketFrameHybie.isFinal: Boolean;
begin
  Result := (FIN = 1);
end;

function TWebSocketFrameHybie.getData: AnsiString;
begin
  Result := payloadData;
end;

{
 * HIXIE WebSocketFrame
}

constructor TWebSocketFrame76.create(code: TWebSocketOpcode; data: AnsiString = '');
begin
  payloadData := data;
  opcode := code;
end;

function TWebSocketFrame76.encode: AnsiString;
begin
  Result := AnsiChar(0) + payloadData + AnsiChar(255);
end;

function TWebSocketFrame76.getData: AnsiString;
begin
  Result := payloadData;
end;

function TWebSocketFrame76.getType: TWebSocketOpcode;
begin
  Result := opcode;
end;

class function TWebSocketFrame76.decode(var raw: AnsiString; head: TWebSocketFrame = nil): TWebSocketFrame;
var
  tframe: TWebSocketFrame;
begin
  if ((Length(raw) = 2) and (Ord(raw[1]) = 0) and (Ord(Raw[2]) = $FF))
  or (Length(raw) = 0) then
    Result := nil
  else
  begin
    tframe := TWebSocketFrame76.Create(TextFrame, Copy(raw, 2, Length(raw) - 2));
    Result := tframe;
  end;
end;

function TWebSocketFrame76.isReady: Boolean;
begin
  Result := true;
end;



constructor TWebSocketFrameEnumerator.Create;
begin
  _pointers := TList.Create;
end;

destructor TWebSocketFrameEnumerator.Destroy;
begin
  _pointers.Free;
end;

procedure TWebSocketFrameEnumerator.Add(tframe: TWebSocketFrame);
begin
  _pointers.Add(tframe);
end;

procedure TWebSocketFrameEnumerator.Delete(index: Integer);
begin
  _pointers.Delete(index);
end;

function TWebSocketFrameEnumerator.Get(index: Integer): TWebSocketFrame;
begin
  Result := _pointers[index];
end;

function TWebSocketFrameEnumerator.Count: Integer;
begin
  Result := _pointers.Count;
end;

constructor TWebSocketSocket.Create(socket: TWebSockSrvClient);
begin
  _socket := socket;
  _socket.OnDataAvailable := handleDataAvailable;
  _socket.OnSessionClosed := handleSessionClosed;
end;

destructor TWebSocketSocket.Destroy;
begin
end;

procedure TWebSocketSocket.handleDataAvailable(Sender: TObject; ErrCode: Word);
begin
  with Sender as TWebSockSrvClient do begin
    RcvdLine := ReceiveStr;
    //Display('Received from ' + GetPeerAddr + ': ''' + RcvdLine + '''');
    onData(AnsiString(RcvdLine));
  end;
end;

procedure TWebSocketSocket.handleSessionClosed(Sender: TObject; ErrCode: Word);
begin
  self.Free;
end;

function TWebSocketSocket.getResource: TWebSockSrvClient;
begin
  Result := _socket;
end;

function TWebSocketSocket.getConnection: IWebSocketConnection;
begin
  Result := _con;
end;

procedure TWebSocketSocket.establishConnection(data: AnsiString);
begin
  _con := TWebSocketConnectionFactory.fromSocketData(self, data);

  if assigned(_con) and assigned(_socket.OnWebSocketConnected) then
    _socket.OnWebSocketConnected(self, _con);
end;

procedure TWebSocketSocket.onMessage(m: IWebSocketMessage);
begin
  if assigned(_con) and assigned(_socket.OnWebSocketMessage) then
    _socket.OnWebSocketMessage(self, String(m.getData));
end;

procedure TWebSocketSocket.onData(data: AnsiString); // read from client
begin
  try
    _lastChanged := Now;

    if assigned(_con) then
      _con.readFrame(data)
    else
      establishConnection(data);
  except
    on E: Exception do
    begin
      TWebSocketFunctions.say(E.Message);
    end;
  end;
end;

procedure TWebSocketSocket.write(data: AnsiString);
begin
  if Assigned(_socket) then
  begin
    _socket.SendStr(data);
  end;
end;

function TWebSocketSocket.getLastChanged: TDateTime;
begin
  Result := _lastChanged;
end;

procedure TWebSocketSocket.disconnect;
begin
  _socket.CloseDelayed;
end;

class function TWebSocketConnectionFactory.fromSocketData(socket: TWebSocketSocket; data: AnsiString): IWebSocketConnection;
var
  headers: TStringList;
  s: IWebSocketConnection;
begin
  s := nil;
  headers := TWebSocketFunctions.parseHeaders(data);
  if headers.Values['Sec-Websocket-Key1'] <> '' then
  begin
    s := TWebSocketConnectionHixie.Create(socket, headers, data);
    s.sendHandshakeResponse;
  end
  else
  if (Pos(AnsiString('<policy-file-request/>'), data) = 1) then
  begin
    // TODO: $s = new WebSocketConnectionFlash($socket, $data);
  end
  else
  if headers.Values['Sec-Websocket-Key'] <> '' then
  begin
    s := TWebSocketConnectionHybie.Create(socket, headers);
    s.sendHandshakeResponse;
  end;
  Result := s;
end;

constructor TWebSocketConnection.Create(socket: TWebSocketSocket; headers: TStringList);
begin
  _headers := TStringList.Create;
  _headers.Sorted := true;
  _cookies := TStringList.Create;
  _parameters := TStringList.Create;

  setHeaders(headers);
  _socket := socket;
end;

destructor TWebSocketConnection.Destroy;
begin
  _headers.Free;
  _cookies.Free;
  _parameters.Free;
end;

procedure TWebSocketConnection.setHeaders(headers: TStringList);
var
  cookieIndex, i: Integer;
begin
  _headers.Assign(headers);
  cookieIndex := _headers.IndexOfName('Cookie');
  if cookieIndex <> -1 then
  begin
    for i := cookieIndex to _headers.Count - 1 do
    begin
      if _headers.Names[i] <> 'Cookie' then Break;
      _cookies.AddStrings(TWebSocketFunctions.cookie_parse(AnsiString(_headers.ValueFromIndex[i])));
    end;
  end;

  getQueryParts;
end;

function TWebSocketConnection.sendHandshakeResponse: Boolean;
begin
  Result := false;
end;

function TWebSocketConnection.readFrame(data: AnsiString): TWebSocketFrame;
begin
  Result := nil;
end;

procedure TWebSocketConnection.sendString(msg: AnsiString);
begin
end;

procedure TWebSocketConnection.disconnect;
begin
end;

function TWebSocketConnection.getHeaders: TStringList;
begin
  Result := _headers;
end;


procedure TWebSocketConnection.getQueryParts;
var
  url, q, kv: AnsiString;
  p, i: Integer;
  kvpairs: TStringList;
  Proto, User, Pass, Host, Port, Path : String;
begin
  url := getUriRequested;
  p := Pos(AnsiString('?'), url);

  if p > 0 then
  begin
    q := Copy(url, p + 1, MaxInt);

    kvpairs := TStringList.Create;
    kvpairs.Delimiter := '&';
    kvpairs.Text := String(q);

    for i := 0 to kvpairs.Count - 1 do
    begin
      kv := AnsiString(kvpairs.Strings[i]);
      p := Pos(AnsiString('='), kv);
      _parameters.Add(UrlDecode(Copy(kv, 1, p - 1)) + '=' + UrlDecode(Copy(kv, p + 1, MaxInt)));
    end;

    kvpairs.Free;
  end
  else
    q := url;

  ParseURL(String(url), Proto, User, Pass, Host, Port, Path);
  if Proto <> '' then _headers.Add('PROTO=' + Proto);
  if User <> '' then _headers.Add('USER=' + User);
  if Pass <> '' then _headers.Add('PASSWORD=' + Pass);
  if Host <> '' then _headers.Add('HOST=' + Host);
  if Port <> '' then _headers.Add('PORT=' + Port);
  if Path <> '' then _headers.Add('PATH=' + Path);

end;

function TWebSocketConnection.sendFrame(tframe: TWebSocketFrame): Boolean;
begin
  _socket.write(tframe.encode);
  Result := true;
end;

function TWebSocketConnection.sendMessage(msg: IWebSocketMessage): Boolean;
var
  e: TWebSocketFrameEnumerator;
  i: Integer;
begin
  e := msg.getFrames;
  for i := 0 to e.Count - 1 do
  begin
    if not sendFrame(e.Frame[i]) then
    begin
      Result := false;
      Exit;
    end;
  end;

  Result := true;
end;

function TWebSocketConnection.getCookies: TStringList;
begin
  Result := _cookies;
end;

function TWebSocketConnection.getUriRequested: AnsiString;
begin
    Result := AnsiString(_headers.Values['GET']);
end;


constructor TWebSocketConnectionHybie.Create(socket: TWebSocketSocket; headers: TStringList);
begin
  inherited Create(socket, headers);
  _openMessage := nil;
  _lastFrame := nil;
end;

// INTERFACE

function TWebSocketConnectionHybie.sendHandshakeResponse: Boolean;
var
  challenge: AnsiString;
  response: AnsiString;
begin
  // Check for handshake values
  if _headers.Values['Sec-Websocket-Key'] <> '' then
    challenge := AnsiString(_headers.Values['Sec-Websocket-Key']);

  if challenge = '' then
  begin
    Result := false;
    exit;
  end;

  // Build HTTP response
  response := 'HTTP/1.1 101 WebSocket Protocol Handshake' + #13#10 +
              'Upgrade: WebSocket' + #13#10 +
              'Connection: Upgrade' + #13#10;

  // Build HYBI response
  response := response + 'Sec-WebSocket-Accept: ' + TWebSocketFunctions.calcHybiResponse(challenge) + #13#10#13#10;

  _socket.write(response);

  TWebSocketFunctions.say('HYBI Response SENT!');
  Result := true;
end;

function TWebSocketConnectionHybie.readFrame(data: AnsiString): TWebSocketFrame;
var
  frame: TWebSocketFrameHybie;
begin
  frame := nil;
  while (Length(data) > 0) do
  begin
    frame := TWebSocketFrameHybie(TWebSocketFrameHybie.decode(data, TWebSocketFrame(_lastFrame)));
    if (frame.isReady) then
    begin
      if (isControlFrame(frame.getType)) then
      begin
        processControlFrame(frame);
        // control frames are not used further
        frame.Free;
        frame := nil;
      end
      else
        processMessageFrame(frame);
        // now the message is responsible for new frame

      _lastFrame := nil;
    end
    else
    begin
      _lastFrame := frame;
    end;

    //frames[] = frame;
  end;

  Result := TWebSocketFrame(frame);
end;


{
 * Process a Message Frame
 *
 * Appends or creates a new message and attaches it to the user sending it.
 *
 * When the last frame of a message is received, the message is sent for processing to the
 * abstract WebSocket::onMessage() method.
 *
 * @param WebSocketFrame tframe
}
procedure TWebSocketConnectionHybie.processMessageFrame(tframe: TWebSocketFrameHybie);
begin
  if (_openMessage <> nil) and (not _openMessage.isFinalised) then
  begin
    _openMessage.takeFrame(TWebSocketFrame(tframe));
  end
  else
  begin
    _openMessage := TWebSocketMessageHybie.fromFrame(tframe);
  end;

  if (_openMessage <> nil) and (_openMessage.isFinalised) then
  begin
    _socket.onMessage(_openMessage);
    TWebSocketMessageHybie(_openMessage).Free;
    _openMessage := nil;
  end;
end;

{
 * Handle incoming control frames
 *
 * Sends Pong on Ping and closes the connection after a Close request.
 *
 * @param WebSocketFrame $frame
}
procedure TWebSocketConnectionHybie.processControlFrame(tframe: TWebSocketFrameHybie);
var
  r: TWebSocketFrameHybie;
begin
  case tframe.getType of
    CloseFrame :
      begin
      r := TWebSocketFrameHybie.Create(CloseFrame);
      sendFrame(TWebSocketFrame(r));
      r.Free;
      _socket.disconnect;
      end;
    PingFrame :
      begin
      r := TWebSocketFrameHybie.Create(PongFrame);
      sendFrame(TWebSocketFrame(r));
      r.Free;
      end;
  end;
end;

procedure TWebSocketConnectionHybie.sendString(msg: AnsiString);
var
  m: TWebSocketMessageHybie;
begin
  m := TWebSocketMessageHybie.Create(msg);

  sendMessage(m);
  m.Free;
end;

procedure TWebSocketConnectionHybie.disconnect;
var
  f: TWebSocketFrameHybie;
begin
  f := TWebSocketFrameHybie.Create(CloseFrame);
  sendFrame(TWebSocketFrame(f));
  f.Free;
  _socket.disconnect;
end;

constructor TWebSocketConnectionHixie.Create(socket: TWebSocketSocket; headers: TStringList; clientHandshake: AnsiString);
begin
  inherited Create(socket, headers);
  _clientHandshake := clientHandshake;
end;

function TWebSocketConnectionHixie.sendHandshakeResponse: Boolean;
var
  l8b, key1, key2, origin, host, location, response: AnsiString;
begin
  // Last 8 bytes of the client's handshake are used for key calculation later
  l8b := Copy(_clientHandshake, Length(_clientHandshake) - 7, 8);

  // Check for 2-key based handshake (Hixie protocol draft)
  key1 := AnsiString(_headers.Values['Sec-Websocket-Key1']);
  key2 := AnsiString(_headers.Values['Sec-Websocket-Key2']);

  // Origin checking (TODO)
  origin := AnsiString(_headers.Values['Origin']);
  host := AnsiString(_headers.Values['Host']);
  location := AnsiString(_headers.Values['GET']);

  // Build HTTP response
  response := 'HTTP/1.1 101 WebSocket Protocol Handshake' + #13#10 +
              'Upgrade: WebSocket' + #13#10 +
              'Connection: Upgrade' + #13#10;

  // Build HIXIE response
  response := response + 'Sec-WebSocket-Origin: ' + origin + #13#10 +
                         'Sec-WebSocket-Location: ws://' + host + location + #13#10;
  response := response + #13#10 + TWebSocketFunctions.calcHixieResponse(key1, key2, l8b);

  _socket.write(response);
  TWebSocketFunctions.say('HIXIE Response SENT!');

  Result := true;
end;

function TWebSocketConnectionHixie.readFrame(data: AnsiString): TWebSocketFrame;
var
  f: TWebSocketFrame;
  m: IWebSocketMessage;
begin
  f := TWebSocketFrame76.decode(data);
  if Assigned(f) then
  begin
    m := TWebSocketMessageHixie.fromFrame(f);
    _socket.onMessage(m);
    TWebSocketMessageHixie(m).Free;
  end
  else
    _socket.disconnect;

    Result := f;
end;

procedure TWebSocketConnectionHixie.sendString(msg: AnsiString);
var
  m: IWebSocketMessage;
begin
  m := TWebSocketMessageHixie.Create(msg);

  sendMessage(m);
end;

procedure TWebSocketConnectionHixie.disconnect;
begin
  _socket.disconnect;
end;

end.
