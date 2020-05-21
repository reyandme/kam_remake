unit KM_DedicatedServer;
{$I KaM_Remake.inc}
interface
uses
  SysUtils, Classes, Math,
  {$IFDEF MSWindows}Windows,{$ENDIF}
  KM_NetServer, KM_MasterServer, KM_NetUDP, KM_CommonTypes;

type
  TKMDedicatedServer = class
  private
    fLastPing, fLastAnnounce: cardinal;
    fNetServer: TKMNetServer;
    fMasterServers: array of TKMMasterServer;
    fUDPAnnounce: TKMNetUDPAnnounce;
    fOnMessage: TUnicodeStringEvent;
    fPublishServer: Boolean;
    fAnnounceInterval: Word;
    fPingInterval: Word;
    fPort: Word;
    fServerName: AnsiString;
    fAnnounceUDP: Boolean;
    procedure StatusMessage(const aData: string);
    procedure MasterServerError(const aData: string);
    procedure RecreateMasterServers(const aMasterServerAddress: TStringList);
  public
    constructor Create(aMaxRooms, aKickTimeout, aPingInterval, aAnnounceInterval, aServerUDPScanPort: Word;
                       const aMasterServerAddress: TStringList; const aHTMLStatusFile: String;
                       const aWelcomeMessage: UnicodeString; aDedicated: Boolean);
    destructor Destroy; override;

    procedure Start(const aServerName: AnsiString; const aPort: Word; aPublishServer, aAnnounceUDP: Boolean);
    procedure Stop;
    procedure UpdateState;
    procedure UpdateSettings(const aServerName: AnsiString; aPublishServer, aAnnounceUDP: Boolean;
                             aKickTimeout, aPingInterval, aAnnounceInterval, aServerUDPScanPort: Word;
                             const aMasterServerAddress: TStringList; const aHTMLStatusFile: string;
                             const aWelcomeMessage: UnicodeString; const aServerPacketsAccDelay: Integer);
    property OnMessage: TUnicodeStringEvent write fOnMessage;
    
    procedure GetServerInfo(var aList: TList);
    function IsListening: Boolean;

    property Server: TKMNetServer read fNetServer;
  end;


implementation
uses
  KM_CommonUtils;

const
  // Enforce a minimum so our master server doesn't get spammed
  MINIMUM_ANNOUNCE_INTERVAL = 180;


//Announce interval of -1 means the server will not be published (LAN)
constructor TKMDedicatedServer.Create(aMaxRooms, aKickTimeout, aPingInterval, aAnnounceInterval, aServerUDPScanPort: Word;
                                      const aMasterServerAddress: TStringList; const aHTMLStatusFile: String;
                                      const aWelcomeMessage: UnicodeString; aDedicated: Boolean);
var i: integer;
begin
  inherited Create;
  fNetServer := TKMNetServer.Create(aMaxRooms, aKickTimeout, aHTMLStatusFile, aWelcomeMessage);
  RecreateMasterServers(aMasterServerAddress);
  fUDPAnnounce := TKMNetUDPAnnounce.Create(aServerUDPScanPort);
  fUDPAnnounce.OnError := StatusMessage;

  fAnnounceInterval := Max(MINIMUM_ANNOUNCE_INTERVAL, aAnnounceInterval);
  fPingInterval := aPingInterval;
  fLastPing := 0;
  fLastAnnounce := 0;
end;


destructor TKMDedicatedServer.Destroy;
var i: integer;
begin
  FreeAndNil(fNetServer);
  for i := Low(fMasterServers) to High(fMasterServers) do
    FreeAndNil(fMasterServers[i]);
  fMasterServers := nil;
  FreeAndNil(fUDPAnnounce);
  StatusMessage('Server destroyed');
  inherited;
end;


procedure TKMDedicatedServer.Start(const aServerName: AnsiString; const aPort: Word; aPublishServer, aAnnounceUDP: Boolean);
begin
  fPort := aPort;
  fServerName := aServerName;
  fPublishServer := aPublishServer;
  fAnnounceUDP := aAnnounceUDP;
  fNetServer.OnStatusMessage := StatusMessage;
  fNetServer.StartListening(fPort, fServerName);
  fUDPAnnounce.StartAnnouncing(fPort, fServerName, fAnnounceUDP);
end;


procedure TKMDedicatedServer.Stop;
begin
  fNetServer.StopListening;
  fNetServer.ClearClients;
  fUDPAnnounce.StopAnnouncing;
  StatusMessage('Stopped listening');
end;


procedure TKMDedicatedServer.UpdateState;
var TickCount:Cardinal;
var i: integer;
begin
  fNetServer.UpdateStateIdle;
  for i := Low(fMasterServers) to High(fMasterServers) do
    fMasterServers[i].UpdateStateIdle;
  fUDPAnnounce.UpdateStateIdle;

  if not fNetServer.Listening then Exit; //Do not measure pings or announce the server if we are not listening

  TickCount := TimeGet;
  if GetTimeSince(fLastPing) >= fPingInterval then
  begin
    fNetServer.MeasurePings;
    fLastPing := TickCount;
  end;

  if fPublishServer and (GetTimeSince(fLastAnnounce) >= fAnnounceInterval*1000) then
  begin
    for i := Low(fMasterServers) to High(fMasterServers) do
      fMasterServers[i].AnnounceServer(UnicodeString(fServerName), fPort, fNetServer.GetPlayerCount, fAnnounceInterval + 20);
    fLastAnnounce := TickCount;
  end;
end;


procedure TKMDedicatedServer.UpdateSettings(const aServerName: AnsiString; aPublishServer, aAnnounceUDP: Boolean;
                                            aKickTimeout, aPingInterval, aAnnounceInterval, aServerUDPScanPort: Word;
                                            const aMasterServerAddress: TStringList; const aHTMLStatusFile: String;
                                            const aWelcomeMessage: UnicodeString;
                                            const aServerPacketsAccDelay: Integer);
begin
  fAnnounceInterval := Max(MINIMUM_ANNOUNCE_INTERVAL, aAnnounceInterval);
  fPingInterval := aPingInterval;
  RecreateMasterServers(aMasterServerAddress);
  fServerName := aServerName;
  fPublishServer := aPublishServer;
  fAnnounceUDP := aAnnounceUDP;

  fNetServer.UpdateSettings(aKickTimeout, aHTMLStatusFile, aWelcomeMessage, aServerName, aServerPacketsAccDelay);
  fUDPAnnounce.UpdateSettings(aServerName, aServerUDPScanPort);

  fLastAnnounce := 0; //Make the server announce itself next update so the changes are sent to the master server ASAP
end;


procedure TKMDedicatedServer.StatusMessage(const aData: string);
begin
  if Assigned(fOnMessage) then fOnMessage(aData);
end;


procedure TKMDedicatedServer.MasterServerError(const aData: string);
begin
  StatusMessage('HTTP Master Server: '+aData);
end;

procedure TKMDedicatedServer.RecreateMasterServers(const aMasterServerAddress: TStringList);
var recreate: boolean;
var i: integer;
begin
  recreate := false;
  if aMasterServerAddress.Count <> Length(fMasterServers) then
    recreate := true
  else
    for i := 0 to aMasterServerAddress.Count-1 do
      if aMasterServerAddress[i] <> fMasterServers[i].MasterServerAddress then
        recreate := true;

  StatusMessage('(Re-)creating connections to master servers');
  for i := Low(fMasterServers) to High(fMasterServers) do
    FreeAndNil(fMasterServers[i]);
  fMasterServers := nil;

  SetLength(fMasterServers, aMasterServerAddress.Count);
  for i := 0 to aMasterServerAddress.Count-1 do
  begin
    fMasterServers[i] := TKMMasterServer.CreateDedicated(aMasterServerAddress[i]);
    fMasterServers[i].OnError := MasterServerError;
  end
end;


procedure TKMDedicatedServer.GetServerInfo(var aList: TList);
begin
  fNetServer.GetServerInfo(aList);
end;


function TKMDedicatedServer.IsListening: Boolean;
begin
  Result := fNetServer.Listening;
end;


end.
