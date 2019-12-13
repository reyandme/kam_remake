unit Unit4;
{$I ..\..\KaM_Remake.inc}
interface
uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Spin, ComCtrls,
  KM_Defaults,
  KM_Settings,
  KM_DedicatedServer,
  KM_Log,
  KM_NetworkClasses;


type
  //Distinct states for the server
  TKMServerStatus = (ssOffline, ssOnline);

  TForm4 = class(TForm)
    ButtonApply: TButton;
    cAnnounceServer: TCheckBox;
    cAnnounceUDP: TCheckBox;
    cAutoKickTimeout: TSpinEdit;
    cHTMLStatusFile: TEdit;
    cMasterAnnounceInterval: TSpinEdit;
    cMasterServerAddress: TEdit;
    cMaxRooms: TSpinEdit;
    cPingInterval: TSpinEdit;
    cServerName: TEdit;
    cServerPort: TEdit;
    cServerWelcomeMessage: TEdit;
    cServerPacketsAccDelay: TEdit;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label2: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    PageControl1: TPageControl;
    SendCmdButton: TButton;
    Edit1: TEdit;
    Label1: TLabel;
    PlayersList: TListBox;
    LogsMemo: TMemo;
    Panel1: TPanel;
    Panel2: TPanel;
    Splitter1: TSplitter;
    StartStopButton: TButton;
    Basic: TTabSheet;
    Advanced: TTabSheet;
    cUDPScanPort: TEdit;
    Label3: TLabel;

    //saveing setting to file and update (it will do it only if server is online)
    procedure ButtonApplyClick(Sender: TObject);

    //handles controls OnChange events
    procedure ControlChange(Sender: TObject);

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure StartStopButtonClick(Sender: TObject);
    procedure ChangeServerStatus(aStatus: TKMServerStatus);
    procedure LoadSettings;

    //those procs run KM_Log.AppendLog() and add same log line to Memo control
    procedure ServerStatusMessage(const aData: UnicodeString);
    procedure ServerStatusMessageNoTime(const aData: UnicodeString);

    //this proc can change state (enable/disable) of controls that CAN'T be modyfied when server is online
    procedure ChangeEnableStateOfControls(state: Boolean);

    //whenever there is a change in the settings controls while server is online, we call this proc to enable "ButtonApply" button
    procedure ChangeEnableStateOfApplyButton(state: Boolean);
    procedure ApplicationIdle(Sender: TObject; var Done: Boolean);
    procedure FillPlayersList;
  private
    fSettings: TKMGameSettings;
    fSettingsLastModified: integer;
    fServerStatus: TKMServerStatus;
    fDedicatedServer: TKMDedicatedServer;
    Players: TList;
  end;


var
  FormMain4: TForm4;


implementation
uses
  KM_NetworkTypes, KM_Points;

{$IFDEF WDC}
  {$R *.dfm}
{$ENDIF}

{$IFDEF FPC}
  {$R *.lfm}
{$ENDIF}


{ TForm4 }
procedure TForm4.FormCreate(Sender: TObject);
begin
  fServerStatus := ssOffline;
  ChangeEnableStateOfApplyButton(False);
  Application.Title := 'KaM Remake Dedicated Server GUI (' + GAME_REVISION + ')';
  Caption := 'KaM Remake Dedicated Server GUI (' + GAME_REVISION + ')';

  ExeDir := ExtractFilePath(ParamStr(0));
  CreateDir(ExeDir + 'Logs');
  gLog := TKMLog.Create(ExeDir + 'Logs' + PathDelim + 'KaM_Server_' + FormatDateTime('yyyy-mm-d_hh-nn-ss-zzz', Now) + '.log');

  //this is shown only at application start (tip. check the strange -. in morse code translator ;)
  ServerStatusMessageNoTime('-.- .- -- / .-. . -- .- -.- . / .. ... / - .... . / -... . ... -');
  ServerStatusMessage      ('== KaM Remake ' + GAME_VERSION + ' Dedicated Server ==');
  ServerStatusMessageNoTime('');
  ServerStatusMessage      ('Settings file: ' + ExeDir + SETTINGS_FILE);
  ServerStatusMessage      ('Log file: ' + gLog.LogPath);
//  ServerStatusMessageNoTime('-.- .- -- / .-. . -- .- -.- . / .. ... / - .... . / -... . ... -');
//  ServerStatusMessageNoTime('');
  ServerStatusMessage('Using protocol for clients running ' + NET_PROTOCOL_REVISON);

  fSettings := TKMGameSettings.Create;
  fSettings.SaveSettings(true);
  fSettingsLastModified := FileAge(ExeDir+SETTINGS_FILE);

  //we load settings from file to controls
  LoadSettings;

  Application.OnIdle := ApplicationIdle;
end;


procedure TForm4.FormDestroy(Sender: TObject);
begin
  //Terminate online server on exit
  if fServerStatus = ssOnline then
    ChangeServerStatus(ssOffline);

  FreeAndNil(gLog);
  fSettings.Free;
end;


procedure TForm4.ServerStatusMessage(const aData: UnicodeString);
begin
  LogsMemo.Lines.Add(FormatDateTime('yyyy-mm-dd hh-nn-ss ', Now) + aData);
  gLog.AddNoTime(aData);
end;


procedure TForm4.ServerStatusMessageNoTime(const aData: UnicodeString);
begin
  LogsMemo.Lines.Add(aData);
  gLog.AddNoTime(aData);
end;


procedure TForm4.StartStopButtonClick(Sender: TObject);
begin
  ButtonApply.Enabled := True;

  //turn off server when it was on and vice-versa
  case fServerStatus of
    ssOffline: FormMain4.ChangeServerStatus(ssOnline);
    ssOnline:  FormMain4.ChangeServerStatus(ssOffline);
  end;
end;


procedure TForm4.ChangeEnableStateOfControls(state: Boolean);
begin
  cMaxRooms.Enabled   := state;
  cServerPort.Enabled := state;
  cUDPScanPort.Enabled := state;
  cAnnounceUDP.Enabled := state;
end;


procedure TForm4.ChangeServerStatus(aStatus: TKMServerStatus);
var
  GameFilter: TKMPGameFilter;
begin
  case aStatus of
    ssOnline:
      begin
        ChangeEnableStateOfControls(False);

        fDedicatedServer := TKMDedicatedServer.Create(fSettings.MaxRooms,
                                                      fSettings.AutoKickTimeout,
                                                      fSettings.PingInterval,
                                                      fSettings.MasterAnnounceInterval,
                                                      fSettings.ServerUDPScanPort,
                                                      fSettings.MasterServerAddress,
                                                      fSettings.HTMLStatusFile,
                                                      fSettings.ServerWelcomeMessage,
                                                      True);
        GameFilter := TKMPGameFilter.Create(fSettings.ServerDynamicFOW,
                                            fSettings.ServerMapsRosterEnabled,
                                            fSettings.ServerMapsRosterStr,
                                            KMRange(fSettings.ServerLimitPTFrom, fSettings.ServerLimitPTTo),
                                            KMRange(fSettings.ServerLimitSpeedFrom, fSettings.ServerLimitSpeedTo),
                                            KMRange(fSettings.ServerLimitSpeedAfterPTFrom, fSettings.ServerLimitSpeedAfterPTTo));
        fDedicatedServer.Server.GameFilter := GameFilter;
        fDedicatedServer.OnMessage := ServerStatusMessage;
        fDedicatedServer.Start(fSettings.ServerName, StrToInt(fSettings.ServerPort), fSettings.AnnounceServer,
                               fSettings.ServerUDPAnnounce);

        fServerStatus := aStatus;
        StartStopButton.Caption := 'Server is ONLINE';

        ChangeEnableStateOfApplyButton(False);
      end;
    ssOffline:
      begin
        //Reenable disabled controls
        ChangeEnableStateOfControls(True);

        FreeAndNil(fDedicatedServer);

        fServerStatus := aStatus;
        StartStopButton.Caption := 'Server is OFFLINE';
        ServerStatusMessage('Dedicated Server is now Offline');
        ServerStatusMessageNoTime('');
      end;
  end;
end;


procedure TForm4.ChangeEnableStateOfApplyButton(state: Boolean);
begin
  ButtonApply.Enabled := state;
end;


procedure TForm4.FillPlayersList;
var i:           Integer;
    RowInfo:     String;

begin
  Players := TList.Create;
  fDedicatedServer.GetServerInfo(Players);

  //first we clear list
  PlayersList.Items.Clear;

  //then we read each row and add to list
  for i := 0 to Players.Count - 1 do
  begin
    RowInfo := TKMPGameInfo(Players[i]).GetFormattedTime;// + IntToStr(TKMGameInfo(Players[i]).PlayerCount);
    PlayersList.Items.Add(RowInfo);
  end;

  Players.Free;
end;

procedure TForm4.ApplicationIdle(Sender: TObject; var Done: Boolean);
begin
  if fServerStatus = ssOnline then
  begin
    fDedicatedServer.UpdateState;
    Sleep(1); //Don't use 100% CPU
    Done := False; //Repeats OnIdle asap without performing Form-specific idle code
  end
  else
    Done := True;
end;


//one event for each control
procedure TForm4.ControlChange(Sender: TObject);
begin
  ChangeEnableStateOfApplyButton(True);
end;


procedure TForm4.ButtonApplyClick(Sender: TObject);
var
  ServerPacketsAccDelay, UDPScanPort: Integer;
begin
  //Disable the button asap to indicate we are at it
  ChangeEnableStateOfApplyButton(False);

  fSettings.ServerName              := cServerName.Text;
  fSettings.ServerWelcomeMessage    := cServerWelcomeMessage.Text;

  if TryStrToInt(cServerPacketsAccDelay.Text, ServerPacketsAccDelay) then
    fSettings.ServerPacketsAccumulatingDelay := ServerPacketsAccDelay
  else begin
    ServerPacketsAccDelay := fSettings.ServerPacketsAccumulatingDelay;
    cServerPacketsAccDelay.Text := IntToStr(fSettings.ServerPacketsAccumulatingDelay);
  end;

  fSettings.AnnounceServer          := cAnnounceServer.Checked;
  fSettings.ServerUDPAnnounce       := cAnnounceUDP.Checked;
  fSettings.AutoKickTimeout         := cAutoKickTimeout.Value;
  fSettings.PingInterval            := cPingInterval.Value;
  fSettings.MasterAnnounceInterval  := cMasterAnnounceInterval.Value;
  fSettings.MasterServerAddress     := cMasterServerAddress.Text;
  fSettings.HTMLStatusFile          := cHTMLStatusFile.Text;
  fSettings.ServerPort              := cServerPort.Text;

  if TryStrToInt(cUDPScanPort.Text, UDPScanPort) then
    fSettings.ServerUDPScanPort := UDPScanPort
  else begin
    UDPScanPort := fSettings.ServerUDPScanPort;
    cUDPScanPort.Text := IntToStr(fSettings.ServerUDPScanPort);
  end;

  fSettings.MaxRooms                := cMaxRooms.Value;

  fSettings.SaveSettings(True);

  //We can update only if server is online
  if fServerStatus = ssOnline then
  begin

    fDedicatedServer.UpdateSettings(cServerName.Text,
                                    cAnnounceServer.Checked,
                                    cAnnounceUDP.Checked,
                                    cAutoKickTimeout.Value,
                                    cPingInterval.Value,
                                    cMasterAnnounceInterval.Value,
                                    UDPScanPort,
                                    cMasterServerAddress.Text,
                                    cHTMLStatusFile.Text,
                                    cServerWelcomeMessage.Text,
                                    ServerPacketsAccDelay);
    ServerStatusMessage('Settings saved, updated and are now live.');
  end;
end;


procedure TForm4.LoadSettings;
begin
  fSettings.ReloadSettings;

  cServerName.Text              := fSettings.ServerName;
  cServerWelcomeMessage.Text    := fSettings.ServerWelcomeMessage;
  cServerPacketsAccDelay.Text   := IntToStr(fSettings.ServerPacketsAccumulatingDelay);
  cAnnounceServer.Checked       := fSettings.AnnounceServer;
  cAnnounceUDP.Checked          := fSettings.ServerUDPAnnounce;
  cAutoKickTimeout.Value        := fSettings.AutoKickTimeout;
  cPingInterval.Value           := fSettings.PingInterval;
  cMasterAnnounceInterval.Value := fSettings.MasterAnnounceInterval;
  cMasterServerAddress.Text     := fSettings.MasterServerAddress;
  cHTMLStatusFile.Text          := fSettings.HTMLStatusFile;
  cServerPort.Text              := fSettings.ServerPort;
  cUDPScanPort.Text             := IntToStr(fSettings.ServerUDPScanPort);
  cMaxRooms.Value               := fSettings.MaxRooms;

  ServerStatusMessageNoTime('');
  ChangeEnableStateOfApplyButton(False);
end;


end.
