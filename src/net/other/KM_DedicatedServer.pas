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
    fMasterServer: TKMMasterServer;
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
  public
    constructor Create(aMaxRooms, aKickTimeout, aPingInterval, aAnnounceInterval, aServerUDPScanPort: Word;
                       const aMasterServerAddress: String; const aHTMLStatusFile: String;
                       const aWelcomeMessage: UnicodeString; const aPacketsAccDelay: Integer; aDedicated: Boolean);
    destructor Destroy; override;

    procedure Start(const aServerName: AnsiString; const aPort: Word; aPublishServer, aAnnounceUDP: Boolean);
    procedure Stop;
    procedure UpdateState;
    procedure UpdateSettings(const aServerName: AnsiString; aPublishServer, aAnnounceUDP: Boolean;
                             aKickTimeout, aPingInterval, aAnnounceInterval, aServerUDPScanPort: Word;
                             const aMasterServerAddress: string; const aHTMLStatusFile: string;
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
                                      const aMasterServerAddress: String; const aHTMLStatusFile: String;
                                      const aWelcomeMessage: UnicodeString; const aPacketsAccDelay: Integer; aDedicated: Boolean);
begin
  inherited Create;

  fNetServer := TKMNetServer.Create(aMaxRooms, aKickTimeout, aHTMLStatusFile, aWelcomeMessage, aPacketsAccDelay);
  fMasterServer := TKMMasterServer.Create(aMasterServerAddress, aDedicated);
  fMasterServer.OnError := MasterServerError;
  fUDPAnnounce := TKMNetUDPAnnounce.Create(aServerUDPScanPort);
  fUDPAnnounce.OnError := StatusMessage;

  fAnnounceInterval := Max(MINIMUM_ANNOUNCE_INTERVAL, aAnnounceInterval);
  fPingInterval := aPingInterval;
  fLastPing := 0;
  fLastAnnounce := 0;
end;


destructor TKMDedicatedServer.Destroy;
begin
  FreeAndNil(fNetServer);
  FreeAndNil(fMasterServer);
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
var
  tickCount:Cardinal;
begin
  fNetServer.UpdateStateIdle;
  fMasterServer.UpdateStateIdle;
  fUDPAnnounce.UpdateStateIdle;

  if not fNetServer.Listening then Exit; //Do not measure pings or announce the server if we are not listening

  tickCount := TimeGet;
  if TimeSince(fLastPing) >= fPingInterval then
  begin
    fNetServer.MeasurePings;
    fLastPing := tickCount;
  end;

  if fPublishServer and (TimeSince(fLastAnnounce) >= fAnnounceInterval*1000) then
  begin
    fMasterServer.AnnounceServer(UnicodeString(fServerName), fPort, fNetServer.GetPlayerCount, fAnnounceInterval + 20);
    fLastAnnounce := tickCount;
  end;
end;


procedure TKMDedicatedServer.UpdateSettings(const aServerName: AnsiString; aPublishServer, aAnnounceUDP: Boolean;
                                            aKickTimeout, aPingInterval, aAnnounceInterval, aServerUDPScanPort: Word;
                                            const aMasterServerAddress: String; const aHTMLStatusFile: String;
                                            const aWelcomeMessage: UnicodeString;
                                            const aServerPacketsAccDelay: Integer);
begin
  fAnnounceInterval := Max(MINIMUM_ANNOUNCE_INTERVAL, aAnnounceInterval);
  fPingInterval := aPingInterval;
  fMasterServer.MasterServerAddress := aMasterServerAddress;
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


procedure TKMDedicatedServer.GetServerInfo(var aList: TList);
begin
  fNetServer.GetServerInfo(aList);
end;


function TKMDedicatedServer.IsListening: Boolean;
begin
  Result := fNetServer.Listening;
end;


end.
