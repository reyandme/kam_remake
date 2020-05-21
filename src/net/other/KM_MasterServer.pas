unit KM_MasterServer;
{$I KaM_Remake.inc}
{$WARN IMPLICIT_STRING_CAST OFF}
interface
uses
  Classes, SysUtils,
  URLUtils, //This is a common URLUtils file used by both Delphi and Lazarus for two reasons:
            //1. Library specific stuff should all be done in wrappers (e.g. KM_NetServer_Overbyte) so we can easily switch systems.
            //2. Lazarus' LNet library has broken/incorrectly implemented URLUtils at the moment, so we can't rely on them.
  KM_Defaults, KM_HTTPClient, KM_Log;


type
  //Interaction with MasterServer
  TKMMasterServer = class
  private
    fIsDedicated: Boolean;

    fMasterServerAddress: TStringList; // List with at least one master server
    fActiveMasterServer: Integer; //Currently active master server
    fHTTPClientRetryCount: Integer; //Retry count to go through the list of master servers
    fHTTPClient: TKMHTTPClient; //To update server status and fetch server list

    fHTTPAnnouncementsClient: TKMHTTPClient; //To fetch the annoucenemnts at the same time as the server list
    fHTTPMapsClient: TKMHTTPClient; //To tell master server about the map we played

    fOnError: TGetStrProc;
    fOnServerList: TGetStrProc;
    fOnAnnouncements: TGetStrProc;

    function GetActiveServer : string;
    procedure SetActiveServer(const S: string);
    procedure SwitchToNextServer;
    procedure ResetRetryCount;
    procedure DoQueryServerList;
    procedure ReceiveServerList(const S: string);
    procedure ReceiveAnnouncements(const S: string);
    procedure Error(const S: string);
  public
    constructor Create(const aMasterServerAddress: TStringList; aDedicated:Boolean);
    constructor CreateDedicated(const aMasterServerAddress: string);
    destructor Destroy; override;

    property OnError: TGetStrProc write fOnError;
    property OnServerList: TGetStrProc write fOnServerList;
    property OnAnnouncements: TGetStrProc write fOnAnnouncements;
    procedure AnnounceServer(const aName: string; aPort: Word; aPlayerCount, aTTL: Integer);
    procedure QueryServerList;
    procedure FetchAnnouncements(const aLang: AnsiString);
    procedure SendMapInfo(const aMapName: string; aCRC: Cardinal; aPlayerCount: Integer);
    procedure UpdateStateIdle;

    property MasterServerAddress: string read GetActiveServer write SetActiveServer;
  end;


implementation

const
  {$IFDEF MSWindows} OS = 'Windows'; {$ENDIF}
  {$IFDEF UNIX}      OS = 'Unix'; {$ENDIF}
  {$IFDEF WDC} COMPILER = 'WDC'; {$ENDIF}
  {$IFDEF FPC} COMPILER = 'FPC'; {$ENDIF}


constructor TKMMasterServer.Create(const aMasterServerAddress: TStringList; aDedicated:Boolean);
begin
  inherited Create;
  fHTTPClient := TKMHTTPClient.Create;
  fHTTPAnnouncementsClient := TKMHTTPClient.Create;
  fHTTPMapsClient := TKMHTTPClient.Create;
  fHTTPClient.OnReceive := nil;
  fHTTPClient.OnError := Error;
  fMasterServerAddress := aMasterServerAddress;
  if fMasterServerAddress.Count = 0 then
    fMasterServerAddress.Add(''); // add at least one element to avoid bound checks
  fIsDedicated := aDedicated;
  fActiveMasterServer := 0;
  ResetRetryCount();
end;

constructor TKMMasterServer.CreateDedicated(const aMasterServerAddress: string);
var addresses: TStringList;
begin
  addresses := TStringList.Create;
  addresses.Add(aMasterServerAddress);
  Create(addresses, True);
end;


destructor TKMMasterServer.Destroy;
begin
  fHTTPClient.Free;
  fHTTPAnnouncementsClient.Free;
  fHTTPMapsClient.Free;
  inherited;
end;

function TKMMasterServer.GetActiveServer : string;
begin
  Result := fMasterServerAddress.Strings[fActiveMasterServer];
end;

procedure TKMMasterServer.SetActiveServer(const S: string);
begin
  fMasterServerAddress.Strings[fActiveMasterServer] := S;
end;

procedure TKMMasterServer.SwitchToNextServer;
begin
  fActiveMasterServer := (fActiveMasterServer + 1) mod fMasterServerAddress.Count;
end;

procedure TKMMasterServer.ResetRetryCount;
begin
  fHTTPClientRetryCount := fMasterServerAddress.Count - 1;
end;

procedure TKMMasterServer.DoQueryServerList;
begin
  fHTTPClient.OnReceive := ReceiveServerList;
  fHTTPClient.GetURL(GetActiveServer()+'serverquery.php?rev='+UrlEncode(NET_PROTOCOL_REVISON)+'&coderev='+UrlEncode(GAME_REVISION)
                     , False); //For now server list is ANSI only
end;

procedure TKMMasterServer.Error(const S: string);
begin
  gLog.AddTime('Error from master server ' + GetActiveServer());

  // Re-try the query again
  if fHTTPClientRetryCount > 0 then
  begin
    SwitchToNextServer();
    fHTTPClientRetryCount := fHTTPClientRetryCount - 1;
    DoQueryServerList();
  end
  else
    if Assigned(fOnError) then fOnError(S);
end;


procedure TKMMasterServer.ReceiveServerList(const S: string);
begin
  if Assigned(fOnServerList) then fOnServerList(S);
end;


procedure TKMMasterServer.ReceiveAnnouncements(const S: string);
begin
  if Assigned(fOnAnnouncements) then fOnAnnouncements(S);
end;


procedure TKMMasterServer.AnnounceServer(const aName: string; aPort: Word; aPlayerCount, aTTL: Integer);
begin
  fHTTPClient.OnReceive := nil; //We don't care about the response
  fHTTPClient.GetURL(GetActiveServer()+'serveradd.php?name='+UrlEncode(aName)+'&port='+UrlEncode(IntToStr(aPort))
                     +'&playercount='+UrlEncode(IntToStr(aPlayerCount))+'&ttl='+UrlEncode(IntToStr(aTTL))
                     +'&rev='+UrlEncode(NET_PROTOCOL_REVISON)+'&coderev='+UrlEncode(GAME_REVISION)
                     +'&os='+UrlEncode(OS)+'&compiler='+UrlEncode(COMPILER)+'&dedicated='+UrlEncode(IntToStr(byte(fIsDedicated)))
                     , False); //Result doesn't matter so ANSI is fine
end;


procedure TKMMasterServer.QueryServerList;
begin
  ResetRetryCount();
  DoQueryServerList();
end;


procedure TKMMasterServer.FetchAnnouncements(const aLang: AnsiString);
begin
  fHTTPAnnouncementsClient.OnReceive := ReceiveAnnouncements;
  fHTTPAnnouncementsClient.GetURL(GetActiveServer()+'announcements.php?lang='
       +UrlEncode(UnicodeString(aLang))+'&rev='+UrlEncode(NET_PROTOCOL_REVISON)
       +'&coderev='+UrlEncode(GAME_REVISION)
       , True); //Announcements are in UTF8
end;


procedure TKMMasterServer.SendMapInfo(const aMapName: string; aCRC: Cardinal; aPlayerCount: Integer);
begin
  fHTTPMapsClient.OnReceive := nil; //We don't care about the response
  fHTTPMapsClient.GetURL(GetActiveServer()+'maps.php?map='+UrlEncode(aMapName)
                         +'&mapcrc='+IntToHex(aCRC, 8)
                         +'&playercount='+UrlEncode(IntToStr(aPlayerCount))
                         +'&rev='+UrlEncode(NET_PROTOCOL_REVISON)
                         +'&coderev='+UrlEncode(GAME_REVISION)
                         , False); //Result doesn't matter so ANSI is fine
end;


procedure TKMMasterServer.UpdateStateIdle;
begin
  fHTTPClient.UpdateStateIdle;
  fHTTPAnnouncementsClient.UpdateStateIdle;
  fHTTPMapsClient.UpdateStateIdle;
end;


end.

