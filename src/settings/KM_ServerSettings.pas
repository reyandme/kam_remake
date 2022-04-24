unit KM_ServerSettings;
{$I KaM_Remake.inc}
interface
uses
  Classes,
  {$IFDEF FPC}Forms,{$ENDIF}   // Lazarus does not know about UITypes
  {$IFDEF WDC}UITypes,{$ENDIF} // We use settings in console modules
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

    // Server
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
    procedure SaveToFile(const aFilename: UnicodeString); override;

    function GetDefaultSettingsName: string; override;
    function GetSettingsName: string; override;
  public
    constructor Create(aSettingsLoc: TKMSettingsLocation);
    destructor Destroy; override;

    // Server
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
constructor TKMServerSettings.Create(aSettingsLoc: TKMSettingsLocation);
begin
  fServerMapsRoster := TKMMapsCRCList.Create;
  fServerMapsRoster.OnMapsUpdate := SetServerMapsRosterStr;

  inherited Create(aSettingsLoc);

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
  ini: TMemIniFile;
  serverName: UnicodeString;
begin
  inherited;

  ini := TMemIniFile.Create(aPath {$IFDEF WDC}, TEncoding.UTF8 {$ENDIF} );
  try
    fServerPort             := ini.ReadString ('Server','ServerPort','56789');
    fServerUDPScanPort      := ini.ReadInteger('Server','UDPScanPort',SERVER_DEFAULT_UDP_SCAN_PORT);
    fServerUDPAnnounce      := ini.ReadBool   ('Server','UDPAnnounce',True);

    //We call it MasterServerAddressNew to force it to update in everyone's .ini file when we changed address.
    //If the key stayed the same then everyone would still be using the old value from their settings.
    fMasterServerAddress    := ini.ReadString ('Server','MasterServerAddressNew','http://master.kamremake.com/');
    fMasterAnnounceInterval := ini.ReadInteger('Server','MasterServerAnnounceInterval',180);
    fAnnounceServer         := ini.ReadBool   ('Server','AnnounceDedicatedServer',True);

    serverName              := ini.ReadString ('Server','ServerName','KaM Remake Server');
    fServerName             := AnsiString(StrTrimChar(serverName, #39)); //Trim single quotes from the start and from the end of servername

    fMaxRooms               := ini.ReadInteger('Server','MaxRooms',16);
    ServerPacketsAccumulatingDelay := ini.ReadInteger('Server','PacketsAccumulatingDelay',20);
    fAutoKickTimeout        := ini.ReadInteger('Server','AutoKickTimeout',20);
    fPingInterval           := ini.ReadInteger('Server','PingMeasurementInterval',1000);
    fHTMLStatusFile         := ini.ReadString ('Server','HTMLStatusFile','KaM_Remake_Server_Status.html');
    fServerWelcomeMessage   := {$IFDEF FPC} UTF8Decode {$ENDIF} (ini.ReadString ('Server','WelcomeMessage',''));

    fServerDynamicFOW       := ini.ReadBool  ('Server', 'DynamicFOW', False);
    fServerMapsRosterEnabled:= ini.ReadBool  ('Server', 'MapsRosterEnabled', False);
    fServerMapsRoster.Enabled := fServerMapsRosterEnabled; //Set enabled before fServerMapsRoster load

    if fServerMapsRosterEnabled then
      fServerMapsRosterStr := ini.ReadString('Server', 'MapsRoster', '')
    else
      fServerMapsRosterStr := '';

    fServerMapsRoster.LoadFromString(fServerMapsRosterStr);

    fServerLimitPTFrom      := ini.ReadInteger('Server', 'LimitPTFrom',     0);
    fServerLimitPTTo        := ini.ReadInteger('Server', 'LimitPTTo',       300);
    fServerLimitSpeedFrom   := ini.ReadFloat  ('Server', 'LimitSpeedFrom',  0);
    fServerLimitSpeedTo     := ini.ReadFloat  ('Server', 'LimitSpeedTo',    10);
    fServerLimitSpeedAfterPTFrom  := ini.ReadFloat('Server', 'LimitSpeedAfterPTFrom', 0);
    fServerLimitSpeedAfterPTTo    := ini.ReadFloat('Server', 'LimitSpeedAfterPTTo',   10);
  finally
    ini.Free;
  end;
end;


// Don't rewrite the file for each individual change, do it in one batch for simplicity
procedure TKMServerSettings.SaveToFile(const aFilename: UnicodeString);
var
  ini: TMemIniFile;
begin
  if BLOCK_FILE_WRITE then
    Exit;

  ForceDirectories(ExtractFilePath(ExpandFileName(aFilename))); // Create folder, if it does not exist

  ini := TMemIniFile.Create(aFilename {$IFDEF WDC}, TEncoding.UTF8 {$ENDIF} );
  try
    ini.WriteString ('Server','ServerName',                   '''' + UnicodeString(fServerName) + ''''); //Add single quotes for server name
    ini.WriteString ('Server','WelcomeMessage',               {$IFDEF FPC} UTF8Encode {$ENDIF}(fServerWelcomeMessage));
    ini.WriteString ('Server','ServerPort',                   fServerPort);
    ini.WriteInteger('Server','UDPScanPort',                  fServerUDPScanPort);
    ini.WriteBool   ('Server','UDPAnnounce',                  fServerUDPAnnounce);
    ini.WriteBool   ('Server','AnnounceDedicatedServer',      fAnnounceServer);
    ini.WriteInteger('Server','MaxRooms',                     fMaxRooms);
    ini.WriteInteger('Server','PacketsAccumulatingDelay',     fServerPacketsAccumulatingDelay);
    ini.WriteString ('Server','HTMLStatusFile',               fHTMLStatusFile);
    ini.WriteInteger('Server','MasterServerAnnounceInterval', fMasterAnnounceInterval);
    ini.WriteString ('Server','MasterServerAddressNew',       fMasterServerAddress);
    ini.WriteInteger('Server','AutoKickTimeout',              fAutoKickTimeout);
    ini.WriteInteger('Server','PingMeasurementInterval',      fPingInterval);

    ini.WriteBool   ('Server','DynamicFOW',             fServerDynamicFOW);
    ini.WriteBool   ('Server','MapsRosterEnabled',      fServerMapsRosterEnabled);
    ini.WriteString ('Server','MapsRoster',             fServerMapsRosterStr);
    ini.WriteInteger('Server','LimitPTFrom',            fServerLimitPTFrom);
    ini.WriteInteger('Server','LimitPTTo',              fServerLimitPTTo);
    ini.WriteFloat  ('Server','LimitSpeedFrom',         fServerLimitSpeedFrom);
    ini.WriteFloat  ('Server','LimitSpeedTo',           fServerLimitSpeedTo);
    ini.WriteFloat  ('Server','LimitSpeedAfterPTFrom',  fServerLimitSpeedAfterPTFrom);
    ini.WriteFloat  ('Server','LimitSpeedAfterPTTo',    fServerLimitSpeedAfterPTTo);

    ini.UpdateFile; //Write changes to file
  finally
    ini.Free;
  end;
end;


procedure TKMServerSettings.SetServerPacketsAccumulatingDelay(aValue: Integer);
begin
  fServerPacketsAccumulatingDelay := EnsureRange(aValue, 0, 1000); //This is rough restrictions. Real one are in TKMNetServer
end;


procedure TKMServerSettings.SetServerPort(const aValue: string);
begin
  fServerPort := aValue;
end;


procedure TKMServerSettings.SetServerUDPAnnounce(aValue: Boolean);
begin
  fServerUDPAnnounce := aValue;
end;


procedure TKMServerSettings.SetServerUDPScanPort(const aValue: Word);
begin
  fServerUDPScanPort := aValue;
end;


procedure TKMServerSettings.SetServerMapsRosterStr(const aValue: UnicodeString);
begin
  fServerMapsRosterStr := aValue;
end;


procedure TKMServerSettings.SetMasterServerAddress(const aValue: string);
begin
  fMasterServerAddress := aValue;
end;


procedure TKMServerSettings.SetServerName(const aValue: AnsiString);
begin
  fServerName := aValue;
end;


procedure TKMServerSettings.SetMaxRooms(eValue: Integer);
begin
  fMaxRooms := eValue;
end;


procedure TKMServerSettings.SetHTMLStatusFile(const eValue: UnicodeString);
begin
  fHTMLStatusFile := eValue;
end;


procedure TKMServerSettings.SetMasterAnnounceInterval(eValue: Integer);
begin
  fMasterAnnounceInterval := eValue;
end;


procedure TKMServerSettings.SetPingInterval(aValue: Integer);
begin
  fPingInterval := aValue;
end;


procedure TKMServerSettings.SetAutoKickTimeout(aValue: Integer);
begin
  fAutoKickTimeout := aValue;
end;


procedure TKMServerSettings.SetAnnounceServer(aValue: Boolean);
begin
  fAnnounceServer := aValue;
end;


procedure TKMServerSettings.SetServerWelcomeMessage(const aValue: UnicodeString);
begin
  fServerWelcomeMessage := aValue;
end;


end.
