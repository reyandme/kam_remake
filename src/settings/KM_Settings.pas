unit KM_Settings;
{$I KaM_Remake.inc}
interface

type
  TKMSettingsLocation = (
    slExeDir, // In the games folder (handy for debug)
    slShared  // In the MyDocuments when possible (good for players to retain the settings between game builds)
  );

  // Abstract settings entity
  TKMSettings = class abstract
  private
    fSettingsLoc: TKMSettingsLocation;
    procedure LoadFromDefaultFile;
    procedure SaveToDefaultFile;

    function GetDirectory: string;
  protected
    function GetDefaultSettingsName: string; virtual; abstract;

    procedure LoadFromFile(const aPath: string); virtual; abstract;
    procedure SaveToFile(const aPath: UnicodeString); virtual; abstract;

    function GetSettingsName: string; virtual; abstract;

    function GetPath: string;
  public
    constructor Create(aSettingsLoc: TKMSettingsLocation);
    destructor Destroy; override;

    property Path: string read GetPath;

    procedure ReloadSettings;
    procedure SaveSettings;

    class function GetDir(aSettingsLoc: TKMSettingsLocation = slShared): string;
  end;


implementation
uses
  SysUtils,
  KM_Defaults,
  KM_FileIO,
  KM_CommonUtils,
  KM_Log;


{ TKMSettings }
constructor TKMSettings.Create(aSettingsLoc: TKMSettingsLocation);
begin
  inherited Create;

  fSettingsLoc := aSettingsLoc;

  LoadFromDefaultFile;
  // Save settings to default directory immediately
  // If there were any problems with settings then we want to be able to customise them
  SaveToDefaultFile;
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
  Result := GetDir(fSettingsLoc);
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
  saveFolder, path, errorStr: UnicodeString;
begin
  saveFolder := GetDirectory;
  ForceDirectories(saveFolder);
  path := saveFolder + GetDefaultSettingsName;
  gLog.AddTime(Format('Start saving ''%s'' to ''%s''', [GetSettingsName, path]));
  {$IFNDEF RELEASE_MAJOR}
  // Debug output of the current stacktrace.
  // We want to catch odd bug, when 'Start saving server settings' is called twice one after another
  // (without '%s was successfully saved string in the log)
  // todo: remove from released version after bugfix
  gLog.AddNoTime(GetStackTrace(20), False);
  {$ENDIF}

  // Try to save several times, in case file is blocked (by antivirus f.e.)
  if not TryExecuteMethod(path, 'SaveToFile', errorStr, SaveToFile) then
    raise Exception.Create('Can''t save settings to file ''' + path + ''': ' + errorStr);

  gLog.AddTime(Format('''%s'' was successfully saved to ''%s''', [GetSettingsName, path]));
end;


procedure TKMSettings.ReloadSettings;
begin
  LoadFromDefaultFile;
end;


procedure TKMSettings.SaveSettings;
begin
  if SKIP_SETTINGS_SAVE then Exit;

  SaveToDefaultFile;
end;


class function TKMSettings.GetDir(aSettingsLoc: TKMSettingsLocation = slShared): string;
begin
  if USE_KMR_DIR_FOR_SETTINGS or (aSettingsLoc = slExeDir) then
    Result := ExtractFilePath(ParamStr(0))
  else
    Result := CreateAndGetDocumentsSavePath; // Use %My documents%/My Games/
end;


end.

