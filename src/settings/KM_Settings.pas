unit KM_Settings;
{$I KaM_Remake.inc}
interface

type
  // Abstract settings entity
  TKMSettings = class abstract
  private
    fUseLocalFolder: Boolean;
    procedure LoadFromDefaultFile;
    procedure SaveToDefaultFile;

    function GetDirectory: string;
    function GetPath: string;
  protected
    fNeedsSave: Boolean;

    procedure Changed;
    function GetDefaultSettingsName: string; virtual; abstract;
    function NeedToSave: Boolean; virtual;

    procedure LoadFromFile(const aPath: string); virtual; abstract;
    procedure SaveToFile(const aPath: string); virtual; abstract;

    function GetSettingsName: string; virtual; abstract;
  public
    constructor Create(aUseLocalFolder: Boolean);
    destructor Destroy; override;

    property Path: string read GetPath;

    procedure ReloadSettings;
    procedure SaveSettings(aForce: Boolean = False);

    class function GetDir(aUseLocalFolder: Boolean = False): string;
  end;


implementation
uses
  SysUtils,
  KM_Defaults,
  KM_FileIO,
  KM_Log;


{ TKMSettings }
constructor TKMSettings.Create(aUseLocalFolder: Boolean);
begin
  inherited Create;

  fUseLocalFolder := aUseLocalFolder;

  LoadFromDefaultFile;
  // Save settings to default directory immidiately
  // If there were any problems with settings then we want to be able to customise them
  SaveToDefaultFile;

  fNeedsSave := False;
end;


destructor TKMSettings.Destroy;
begin
  SaveToDefaultFile;

  inherited;
end;


function TKMSettings.GetPath: string;
begin
  Result := GetDirectory + GetDefaultSettingsName;
end;


function TKMSettings.GetDirectory: string;
begin
  Result := GetDir(fUseLocalFolder);
end;


procedure TKMSettings.LoadFromDefaultFile;
var
  path: string;
begin
  path := GetPath;
  gLog.AddTime(Format('Start loading ''%s'' from ''%s''', [GetSettingsName, path]));
  LoadFromFile(path);
  gLog.AddTime(Format('''%s'' was successfully loaded from ''%s''', [GetSettingsName, path]));
end;


procedure TKMSettings.SaveToDefaultFile;
var
  saveFolder, path: string;
begin
  saveFolder := GetDirectory;
  ForceDirectories(saveFolder);
  path := saveFolder + GetDefaultSettingsName;
  gLog.AddTime(Format('Start saving ''%s'' to ''%s''', [GetSettingsName, path]));
  SaveToFile(path);
  gLog.AddTime(Format('''%s'' was successfully saved to ''%s''', [GetSettingsName, path]));
end;


function TKMSettings.NeedToSave: Boolean;
begin
  Result := fNeedsSave;
end;


procedure TKMSettings.ReloadSettings;
begin
  LoadFromDefaultFile;
end;


procedure TKMSettings.SaveSettings(aForce: Boolean);
begin
  if SKIP_SETTINGS_SAVE then Exit;

  if NeedToSave or aForce then
    SaveToDefaultFile;
end;


procedure TKMSettings.Changed;
begin
  fNeedsSave := True;
end;


class function TKMSettings.GetDir(aUseLocalFolder: Boolean = False): string;
begin
  if aUseLocalFolder then
    Result := ExtractFilePath(ParamStr(0))
  else
    Result := CreateAndGetDocumentsSavePath; // Use %My documents%/My Games/
end;


end.

