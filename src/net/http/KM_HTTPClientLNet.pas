unit KM_HTTPClientLNet;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, lNet, URLUtils, lHTTP;

type
  TKMHTTPClientLNet = class
  private
    fHTTPClient: TLHTTPClient;
    HTTPBuffer: AnsiString;
    fOnError: TGetStrProc;
    fOnGetCompleted: TGetStrProc;
    fIsUTF8: Boolean;
    procedure HTTPClientDoneInput(ASocket: TLHTTPClientSocket);
    procedure HTTPClientError(const msg: string; aSocket: TLSocket);
    function HTTPClientInput(ASocket: TLHTTPClientSocket; ABuffer: PChar; ASize: Integer): Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure GetURL(const aURL: string; aIsUTF8: Boolean);
    procedure UpdateStateIdle;

    property OnError: TGetStrProc write fOnError;
    property OnGetCompleted: TGetStrProc write fOnGetCompleted;
  end;

implementation


constructor TKMHTTPClientLNet.Create;
begin
  inherited Create;

  fHTTPClient := TLHTTPClient.Create(nil);
  fHTTPClient.Timeout := 0;
  fHTTPClient.OnInput := HTTPClientInput;
  fHTTPClient.OnError := HTTPClientError;
  fHTTPClient.OnDoneInput := HTTPClientDoneInput;
end;


destructor TKMHTTPClientLNet.Destroy;
begin
  fHTTPClient.Free;

  inherited;
end;


procedure TKMHTTPClientLNet.GetURL(const aURL: string; aIsUTF8: Boolean);
var
  proto, user, pass, host, port, path: string;
begin
  fIsUTF8 := aIsUTF8;
  fHTTPClient.Disconnect(true); //If we were doing something, stop it
  HTTPBuffer := '';
  ParseURL(aURL, proto, user, pass, host, port, path);
  fHTTPClient.Host := host;
  fHTTPClient.URI := path;
  fHTTPClient.Port := StrToIntDef(port, 80);
  fHTTPClient.SendRequest;
end;


procedure TKMHTTPClientLNet.HTTPClientDoneInput(ASocket: TLHTTPClientSocket);
var
  returnString: UnicodeString;
begin
  aSocket.Disconnect;
  if fIsUTF8 then
    returnString := UTF8Decode(HTTPBuffer)
  else
    returnString := UnicodeString(HTTPBuffer);
  if Assigned(fOnGetCompleted) then
    fOnGetCompleted(returnString);
  HTTPBuffer := '';
end;


procedure TKMHTTPClientLNet.HTTPClientError(const msg: string; aSocket: TLSocket);
begin
  if Assigned(fOnError) then
    fOnError(msg);
end;


function TKMHTTPClientLNet.HTTPClientInput(ASocket: TLHTTPClientSocket; ABuffer: PChar; ASize: Integer): Integer;
var
  oldLength: dword;
begin
  if ASize > 0 then
  begin
    oldLength := Length(HTTPBuffer);
    setlength(HTTPBuffer, oldLength + ASize);
    move(ABuffer^, HTTPBuffer[oldLength + 1], ASize);
  end;
  Result := aSize; // tell the http buffer we read it all
end;


procedure TKMHTTPClientLNet.UpdateStateIdle;
begin
  fHTTPClient.CallAction; //Process network events
end;


end.
 
