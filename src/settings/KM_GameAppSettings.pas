unit KM_GameAppSettings;
{$I KaM_Remake.inc}
interface
uses
  Generics.Collections,
  KM_IoXML,
  KM_Settings;


type
  // Common implementation for settings stored and loaded from XML
  TKMSettingsXML = class(TKMSettings)
  private
    fXML: TKMXMLDocument;
  protected
    fRoot: TXMLNode;
    procedure LoadFromFile(const aPath: string); override;
    procedure SaveToFile(const aPath: string); override;
  public
    constructor Create;
    destructor Destroy; override;
  end;


  TKMGameAppSettingsPart = class;


  // GameApp settings, stored in the XML
  // Loaded and saved only once
  TKMGameAppSettings = class(TKMSettingsXML)
  private
    fSettingParts: TList<TKMGameAppSettingsPart>;

    procedure RegisterSettingPart(aSettingPart: TKMGameAppSettingsPart);
    procedure UnRegisterSettingPart(aSettingPart: TKMGameAppSettingsPart);
  protected
    procedure LoadFromFile(const aPath: string); override;
    procedure SaveToFile(const aPath: string); override;
    function GetDefaultSettingsName: string; override;
    function GetSettingsName: string; override;
  public
    constructor Create;
    destructor Destroy; override;

    property Root: TXMLNode read fRoot;
  end;


  // Part of GameApp settings, which are stored in the XML
  TKMGameAppSettingsPart = class abstract
  private
    function GetNeedSave: Boolean;
    function GetRoot: TXMLNode;
  protected
    procedure Changed;
    property NeedsSave: Boolean read GetNeedSave;
    function GetDefaultSettingsName: string;

    property Root: TXMLNode read GetRoot;
  public
    constructor Create;
    destructor Destroy; override;

    procedure SaveToXML; virtual; abstract;
    procedure LoadFromXML; virtual; abstract;
    procedure SaveSettings(aForce: Boolean = False); virtual;
  end;

var
  gGameAppSettings: TKMGameAppSettings;


implementation
uses
  SysUtils, INIfiles, Math,

  KM_XmlHelper,
  KM_Defaults;


{ TKMSettings }
constructor TKMSettingsXML.Create;
begin
  // Create xml Settings in the shared folder
  inherited Create(False);
end;


destructor TKMSettingsXML.Destroy;
begin
//  fXML.Free;

  inherited;
end;


procedure TKMSettingsXML.LoadFromFile(const aPath: string);
begin
  inherited;

  fXML.LoadFromFile(aPath);
  fRoot := fXML.Root;
end;


procedure TKMSettingsXML.SaveToFile(const aPath: string);
begin
  inherited;

  fXML.SaveToFile(aPath);
end;


{ TKMGameAppSettings }
constructor TKMGameAppSettings.Create;
begin
  fXML := TKMXMLDocument.Create;
  fSettingParts := TList<TKMGameAppSettingsPart>.Create;

  inherited;

  gGameAppSettings := Self;
end;


destructor TKMGameAppSettings.Destroy;
begin
  inherited;

  fSettingParts.Free;
  fXML.Free;

  gGameAppSettings := nil;
end;


procedure TKMGameAppSettings.RegisterSettingPart(aSettingPart: TKMGameAppSettingsPart);
begin
  fSettingParts.Add(aSettingPart);
end;


procedure TKMGameAppSettings.UnRegisterSettingPart(aSettingPart: TKMGameAppSettingsPart);
begin
  fSettingParts.Remove(aSettingPart);
end;


procedure TKMGameAppSettings.LoadFromFile(const aPath: string);
var
  I: Integer;
begin
  inherited;

  for I := 0 to fSettingParts.Count - 1 do
    fSettingParts[I].LoadFromXML;
end;


procedure TKMGameAppSettings.SaveToFile(const aPath: string);
var
  I: Integer;
begin
  for I := 0 to fSettingParts.Count - 1 do
    fSettingParts[I].SaveToXML;

  inherited;
end;


function TKMGameAppSettings.GetDefaultSettingsName: string;
begin
  Result := SETTINGS_FILE;
end;


function TKMGameAppSettings.GetSettingsName: string;
const
  GAME_APP_SETTINGS_NAME = 'GameApp settings';
begin
  Result := GAME_APP_SETTINGS_NAME;
end;


{ TKMGameAppSettingsPart }
constructor TKMGameAppSettingsPart.Create;
begin
  inherited;

  LoadFromXML;
  gGameAppSettings.RegisterSettingPart(Self);
end;


destructor TKMGameAppSettingsPart.Destroy;
begin
  SaveToXML;
  gGameAppSettings.UnRegisterSettingPart(Self);

  inherited;
end;


procedure TKMGameAppSettingsPart.Changed;
begin
  gGameAppSettings.Changed;
end;


function TKMGameAppSettingsPart.GetDefaultSettingsName: string;
begin
  Result := SETTINGS_FILE;
end;


function TKMGameAppSettingsPart.GetNeedSave: Boolean;
begin
  Result := gGameAppSettings.fNeedsSave;
end;


function TKMGameAppSettingsPart.GetRoot: TXMLNode;
begin
  Result := gGameAppSettings.fRoot;
end;


procedure TKMGameAppSettingsPart.SaveSettings(aForce: Boolean = False);
begin
  if SKIP_SETTINGS_SAVE then Exit;

  gGameAppSettings.SaveSettings(aForce);
end;


end.

