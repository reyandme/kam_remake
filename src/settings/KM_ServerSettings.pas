unit KM_ServerSettings;
{$I KaM_Remake.inc}
interface
uses
  Classes,
  {$IFDEF FPC}Forms,{$ENDIF}   //Lazarus do not know UITypes
  {$IFDEF WDC}UITypes,{$ENDIF} //We use settings in console modules
  KM_Defaults, KM_CommonClasses,
  KM_Settings;

type
  // Server settings
  // Saved in the ini file, since we dont want depend dedicated servers with xml units yet (f.e. they use Generics)
  TKMServerSettings = class(TKMSettings)
  private
    //Server
    fServerPort: string;
    fServerUDPScanPort: Word;
    fServerUDPAnnounce: Boolean;
    fMasterServerAddress: string;
    fServerName: AnsiString;
    fMasterAnnounceInterval: Integer;
    fMaxRooms: Integer;
    fServerPacketsAccumulatingDelay: Integer;
    fAutoKickTimeout: Integer;
    fPingInterval: Integer;
    fAnnounceServer: Boolean;
    fHTMLStatusFile: UnicodeString;
    fServerWelcomeMessage: UnicodeString;

    fServerDynamicFOW: Boolean;
    fServerMapsRosterEnabled: Boolean;
    fServerMapsRosterStr: UnicodeString;
    fServerLimitPTFrom, fServerLimitPTTo: Integer;
    fServerLimitSpeedFrom, fServerLimitSpeedTo: Single;
    fServerLimitSpeedAfterPTFrom, fServerLimitSpeedAfterPTTo: Single;

    fServerMapsRoster: TKMMapsCRCList;

    //Server
    procedure SetMasterServerAddress(const aValue: string);
    procedure SetServerName(const aValue: AnsiString);
    procedure SetServerPort(const aValue: string);
    procedure SetServerUDPAnnounce(aValue: Boolean);
    procedure SetServerUDPScanPort(const aValue: Word);
    procedure SetServerWelcomeMessage(const aValue: UnicodeString);
    procedure SetAnnounceServer(aValue: Boolean);
    procedure SetAutoKickTimeout(aValue: Integer);
    procedure SetPingInterval(aValue: Integer);
    procedure SetMasterAnnounceInterval(eValue: Integer);
    procedure SetHTMLStatusFile(const eValue: UnicodeString);
    procedure SetMaxRooms(eValue: Integer);
    procedure SetServerPacketsAccumulatingDelay(aValue: Integer);
    procedure SetServerMapsRosterStr(const aValue: UnicodeString);
  protected
    procedure LoadFromFile(const aPath: string); override;
    procedure SaveToFile(const aFilename: string); override;

    function GetDefaultSettingsName: string; override;
    function GetSettingsName: string; override;
  public
    constructor Create(aUseLocalFolder: Boolean);
    destructor Destroy; override;

    //Server
    property ServerPort: string read fServerPort write SetServerPort;
    property ServerUDPAnnounce: Boolean read fServerUDPAnnounce write SetServerUDPAnnounce;
    property ServerUDPScanPort: Word read fServerUDPScanPort write SetServerUDPScanPort;
    property MasterServerAddress: string read fMasterServerAddress write SetMasterServerAddress;
    property ServerName: AnsiString read fServerName write SetServerName;
    property MasterAnnounceInterval: Integer read fMasterAnnounceInterval write SetMasterAnnounceInterval;
    property AnnounceServer: Boolean read fAnnounceServer write SetAnnounceServer;
    property MaxRooms: Integer read fMaxRooms write SetMaxRooms;
    property ServerPacketsAccumulatingDelay: Integer read fServerPacketsAccumulatingDelay write SetServerPacketsAccumulatingDelay;

    property AutoKickTimeout: Integer read fAutoKickTimeout write SetAutoKickTimeout;
    property PingInterval: Integer read fPingInterval write SetPingInterval;
    property HTMLStatusFile: UnicodeString read fHTMLStatusFile write SetHTMLStatusFile;
    property ServerWelcomeMessage: UnicodeString read fServerWelcomeMessage write SetServerWelcomeMessage;
    property ServerDynamicFOW: Boolean read fServerDynamicFOW;
    property ServerMapsRosterEnabled: Boolean read fServerMapsRosterEnabled;
    property ServerMapsRosterStr: UnicodeString read fServerMapsRosterStr;
    property ServerLimitPTFrom: Integer read fServerLimitPTFrom;
    property ServerLimitPTTo: Integer read fServerLimitPTTo;
    property ServerLimitSpeedFrom: Single read fServerLimitSpeedFrom;
    property ServerLimitSpeedTo: Single read fServerLimitSpeedTo;
    property ServerLimitSpeedAfterPTFrom: Single read fServerLimitSpeedAfterPTFrom;
    property ServerLimitSpeedAfterPTTo: Single read fServerLimitSpeedAfterPTTo;

    property ServerMapsRoster: TKMMapsCRCList read fServerMapsRoster;
  end;

var
  gServerSettings: TKMServerSettings;


implementation
uses
  SysUtils, INIfiles, Math,
  KM_CommonUtils;


{ TKMServerSettings }
constructor TKMServerSettings.Create(aUseLocalFolder: Boolean);
begin
  fServerMapsRoster := TKMMapsCRCList.Create;
  fServerMapsRoster.OnMapsUpdate := SetServerMapsRosterStr;

  inherited Create(aUseLocalFolder);

  gServerSettings := Self;
end;


destructor TKMServerSettings.Destroy;
begin
  inherited; // Save settings first

  // Cleanup everything afterwards
  FreeAndNil(fServerMapsRoster);

  gServerSettings := nil;
end;


function TKMServerSettings.GetDefaultSettingsName: string;
begin
  Result := SERVER_SETTINGS_FILE;
end;


function TKMServerSettings.GetSettingsName: string;
const
  SERVER_SETTINGS_NAME = 'Server settings';
begin
  Result := SERVER_SETTINGS_NAME;
end;


procedure TKMServerSettings.LoadFromFile(const aPath: string);
var
  F: TMemIniFile;
  serverName: UnicodeString;
begin
  inherited;

  F := TMemIniFile.Create(aPath {$IFDEF WDC}, TEncoding.UTF8 {$ENDIF} );
  try
    fServerPort             := F.ReadString ('Server','ServerPort','56789');
    fServerUDPScanPort      := F.ReadInteger('Server','UDPScanPort',SERVER_DEFAULT_UDP_SCAN_PORT);
    fServerUDPAnnounce      := F.ReadBool   ('Server','UDPAnnounce',True);

    //We call it MasterServerAddressNew to force it to update in everyone's .ini file when we changed address.
    //If the key stayed the same then everyone would still be using the old value from their settings.
    fMasterServerAddress    := F.ReadString ('Server','MasterServerAddressNew','http://master.kamremake.com/');
    fMasterAnnounceInterval := F.ReadInteger('Server','MasterServerAnnounceInterval',180);
    fAnnounceServer         := F.ReadBool   ('Server','AnnounceDedicatedServer',True);

    serverName              := F.ReadString ('Server','ServerName','KaM Remake Server');
    fServerName             := AnsiString(StrTrimChar(serverName, #39)); //Trim single quotes from the start and from the end of servername

    fMaxRooms               := F.ReadInteger('Server','MaxRooms',16);
    ServerPacketsAccumulatingDelay := F.ReadInteger('Server','PacketsAccumulatingDelay',20);
    fAutoKickTimeout        := F.ReadInteger('Server','AutoKickTimeout',20);
    fPingInterval           := F.ReadInteger('Server','PingMeasurementInterval',1000);
    fHTMLStatusFile         := F.ReadString ('Server','HTMLStatusFile','KaM_Remake_Server_Status.html');
    fServerWelcomeMessage   := {$IFDEF FPC} UTF8Decode {$ENDIF} (F.ReadString ('Server','WelcomeMessage',''));

    fServerDynamicFOW       := F.ReadBool  ('Server', 'DynamicFOW', False);
    fServerMapsRosterEnabled:= F.ReadBool  ('Server', 'MapsRosterEnabled', False);
    fServerMapsRoster.Enabled := fServerMapsRosterEnabled; //Set enabled before fServerMapsRoster load

    if fServerMapsRosterEnabled then
      fServerMapsRosterStr := F.ReadString('Server', 'MapsRoster', '')
    else
      fServerMapsRosterStr := '';

    fServerMapsRoster.LoadFromString(fServerMapsRosterStr);

    fServerLimitPTFrom      := F.ReadInteger('Server', 'LimitPTFrom',     0);
    fServerLimitPTTo        := F.ReadInteger('Server', 'LimitPTTo',       300);
    fServerLimitSpeedFrom   := F.ReadFloat  ('Server', 'LimitSpeedFrom',  0);
    fServerLimitSpeedTo     := F.ReadFloat  ('Server', 'LimitSpeedTo',    10);
    fServerLimitSpeedAfterPTFrom  := F.ReadFloat('Server', 'LimitSpeedAfterPTFrom', 0);
    fServerLimitSpeedAfterPTTo    := F.ReadFloat('Server', 'LimitSpeedAfterPTTo',   10);
  finally
    F.Free;
  end;

  fNeedsSave := False;
end;


//Don't rewrite the file for each individual change, do it in one batch for simplicity
procedure TKMServerSettings.SaveToFile(const aFilename: string);
var
  F: TMemIniFile;
begin
  if BLOCK_FILE_WRITE then
    Exit;

  ForceDirectories(ExtractFilePath(ExpandFileName(aFilename))); // Create folder, if it does not exist

  F := TMemIniFile.Create(aFilename {$IFDEF WDC}, TEncoding.UTF8 {$ENDIF} );
  try
    F.WriteString ('Server','ServerName',                   '''' + UnicodeString(fServerName) + ''''); //Add single quotes for server name
    F.WriteString ('Server','WelcomeMessage',               {$IFDEF FPC} UTF8Encode {$ENDIF}(fServerWelcomeMessage));
    F.WriteString ('Server','ServerPort',                   fServerPort);
    F.WriteInteger('Server','UDPScanPort',                  fServerUDPScanPort);
    F.WriteBool   ('Server','UDPAnnounce',                  fServerUDPAnnounce);
    F.WriteBool   ('Server','AnnounceDedicatedServer',      fAnnounceServer);
    F.WriteInteger('Server','MaxRooms',                     fMaxRooms);
    F.WriteInteger('Server','PacketsAccumulatingDelay',     fServerPacketsAccumulatingDelay);
    F.WriteString ('Server','HTMLStatusFile',               fHTMLStatusFile);
    F.WriteInteger('Server','MasterServerAnnounceInterval', fMasterAnnounceInterval);
    F.WriteString ('Server','MasterServerAddressNew',       fMasterServerAddress);
    F.WriteInteger('Server','AutoKickTimeout',              fAutoKickTimeout);
    F.WriteInteger('Server','PingMeasurementInterval',      fPingInterval);

    F.WriteBool   ('Server','DynamicFOW',             fServerDynamicFOW);
    F.WriteBool   ('Server','MapsRosterEnabled',      fServerMapsRosterEnabled);
    F.WriteString ('Server','MapsRoster',             fServerMapsRosterStr);
    F.WriteInteger('Server','LimitPTFrom',            fServerLimitPTFrom);
    F.WriteInteger('Server','LimitPTTo',              fServerLimitPTTo);
    F.WriteFloat  ('Server','LimitSpeedFrom',         fServerLimitSpeedFrom);
    F.WriteFloat  ('Server','LimitSpeedTo',           fServerLimitSpeedTo);
    F.WriteFloat  ('Server','LimitSpeedAfterPTFrom',  fServerLimitSpeedAfterPTFrom);
    F.WriteFloat  ('Server','LimitSpeedAfterPTTo',    fServerLimitSpeedAfterPTTo);

    F.UpdateFile; //Write changes to file
  finally
    F.Free;
  end;

  fNeedsSave := False;
end;


procedure TKMServerSettings.SetServerPacketsAccumulatingDelay(aValue: Integer);
begin
  fServerPacketsAccumulatingDelay := EnsureRange(aValue, 0, 1000); //This is rough restrictions. Real one are in TKMNetServer
  Changed;
end;


procedure TKMServerSettings.SetServerPort(const aValue: string);
begin
  fServerPort := aValue;
  Changed;
end;


procedure TKMServerSettings.SetServerUDPAnnounce(aValue: Boolean);
begin
  fServerUDPAnnounce := aValue;
  Changed;
end;


procedure TKMServerSettings.SetServerUDPScanPort(const aValue: Word);
begin
  fServerUDPScanPort := aValue;
  Changed;
end;


procedure TKMServerSettings.SetServerMapsRosterStr(const aValue: UnicodeString);
begin
  fServerMapsRosterStr := aValue;
  Changed;
end;


procedure TKMServerSettings.SetMasterServerAddress(const aValue: string);
begin
  fMasterServerAddress := aValue;
  Changed;
end;


procedure TKMServerSettings.SetServerName(const aValue: AnsiString);
begin
  fServerName := aValue;
  Changed;
end;


procedure TKMServerSettings.SetMaxRooms(eValue: Integer);
begin
  fMaxRooms := eValue;
  Changed;
end;


procedure TKMServerSettings.SetHTMLStatusFile(const eValue: UnicodeString);
begin
  fHTMLStatusFile := eValue;
  Changed;
end;


procedure TKMServerSettings.SetMasterAnnounceInterval(eValue: Integer);
begin
  fMasterAnnounceInterval := eValue;
  Changed;
end;


procedure TKMServerSettings.SetPingInterval(aValue: Integer);
begin
  fPingInterval := aValue;
  Changed;
end;


procedure TKMServerSettings.SetAutoKickTimeout(aValue: Integer);
begin
  fAutoKickTimeout := aValue;
  Changed;
end;


procedure TKMServerSettings.SetAnnounceServer(aValue: Boolean);
begin
  fAnnounceServer := aValue;
  Changed;
end;


procedure TKMServerSettings.SetServerWelcomeMessage(const aValue: UnicodeString);
begin
  fServerWelcomeMessage := aValue;
  Changed;
end;

end.
