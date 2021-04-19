unit KM_MainSettings;
{$I KaM_Remake.inc}
interface
uses
  Classes,
  {$IFDEF FPC}Forms,{$ENDIF}   //Lazarus do not know UITypes
  {$IFDEF WDC}UITypes,{$ENDIF} //We use settings in console modules
  KM_Resolutions,
  KM_Defaults,
  KM_WindowParams,
  KM_IoXML,
  KM_GameAppSettings;

type
  //Settings that are irrelevant to the game (game does not cares about them)
  //Everything gets written through setter to set fNeedsSave flag
  TKMainSettings = class(TKMGameAppSettingsPart)
  private
    //Not a setting, used to properly set default Resolution value
    fScreenWidth: Integer;
    fScreenHeight: Integer;

    fFullScreen: Boolean;
    fFPSCap: Integer;
    fResolution: TKMScreenRes;
    fWindowParams: TKMWindowParams;
    fVSync: Boolean;
    fNoRenderMaxTime: Integer;     //Longest period of time, when there was no Render (usually on hiiiigh game speed like x300)
    procedure SetFullScreen(aValue: Boolean);
    procedure SetResolution(const Value: TKMScreenRes);
    procedure SetVSync(aValue: Boolean);
    function GetWindowParams: TKMWindowParams;
  public
    constructor Create(aScreenWidth, aScreenHeight: Integer);
    destructor Destroy; override;

    procedure LoadFromXML; override;
    procedure SaveToXML; override;

    property FPSCap: Integer read fFPSCap;
    property FullScreen: Boolean read fFullScreen write SetFullScreen;
    property Resolution: TKMScreenRes read fResolution write SetResolution;
    property WindowParams: TKMWindowParams read GetWindowParams;
    property VSync: Boolean read fVSync write SetVSync;
    property NoRenderMaxTime: Integer read fNoRenderMaxTime;

    function IsNoRenderMaxTimeSet: Boolean;
  end;


implementation
uses
  SysUtils, INIfiles, Math,

  KM_XmlHelper;

const
  NO_RENDER_MAX_TIME_MIN = 10; //in ms
  NO_RENDER_MAX_TIME_DEFAULT = 1000; //in ms
  NO_RENDER_MAX_TIME_UNDEF = -1; //undefined


{ TMainSettings }
constructor TKMainSettings.Create(aScreenWidth, aScreenHeight: Integer);
begin
  // Prepare all data containers for settings load first
  fWindowParams := TKMWindowParams.Create;
  fScreenWidth := aScreenWidth;
  fScreenHeight := aScreenHeight;

  // Load settings after
  inherited Create;
end;


destructor TKMainSettings.Destroy;
begin
  inherited; // Save settings first

  FreeAndNil(fWindowParams); // Cleanup everything afterwards
end;


function TKMainSettings.GetWindowParams: TKMWindowParams;
begin
  if Self = nil then Exit(nil);

  Result := fWindowParams;
end;


procedure TKMainSettings.LoadFromXML;
var
  nMainSettings, nGFX, nWindow, nMisc: TXMLNode;
begin
  if Self = nil then Exit;

  inherited;

  nMainSettings := Root.AddOrFindChild('Main');

  // GFX
  nGFX := nMainSettings.AddOrFindChild('GFX');
  fFullScreen         := nGFX.Attributes['FullScreen'].AsBoolean(False);
  fVSync              := nGFX.Attributes['VSync'].AsBoolean(True);
  fResolution.Width   := nGFX.Attributes['ResolutionWidth'].AsInteger(Max(MENU_DESIGN_X, fScreenWidth));
  fResolution.Height  := nGFX.Attributes['ResolutionHeight'].AsInteger(Max(MENU_DESIGN_Y, fScreenHeight));
  fResolution.RefRate := nGFX.Attributes['RefreshRate'].AsInteger(60);
  fFPSCap := EnsureRange(nGFX.Attributes['FPSCap'].AsInteger(DEF_FPS_CAP), MIN_FPS_CAP, MAX_FPS_CAP);

  // Window
  // For proper window positioning we need Left and Top records
  // Otherwise reset all window params to defaults
  nWindow := nMainSettings.AddOrFindChild('Window');
  if nWindow.HasAttribute('Left') and nWindow.HasAttribute('Top') then
  begin
    fWindowParams.Left   := nWindow.Attributes['Left'].AsInteger(-1);
    fWindowParams.Top    := nWindow.Attributes['Top'].AsInteger(-1);
    fWindowParams.Width  := nWindow.Attributes['Width'].AsInteger(Max(MENU_DESIGN_X, fScreenWidth));
    fWindowParams.Height := nWindow.Attributes['Height'].AsInteger(Max(MENU_DESIGN_Y, fScreenHeight));
    fWindowParams.State  := TWindowState(EnsureRange(nWindow.Attributes['State'].AsInteger(0), 0, 2));
  end else
    fWindowParams.NeedResetToDefaults := True;

  // Misc
  nMisc := nMainSettings.AddOrFindChild('Misc');
  fNoRenderMaxTime := nMisc.Attributes['NoRenderMaxTime'].AsInteger(NO_RENDER_MAX_TIME_DEFAULT);
  if fNoRenderMaxTime < NO_RENDER_MAX_TIME_MIN then
    fNoRenderMaxTime := NO_RENDER_MAX_TIME_UNDEF;

  // Reset wsMinimized state to wsNormal
  if (fWindowParams.State = TWindowState.wsMinimized) then
    fWindowParams.State := TWindowState.wsNormal;
end;


//Don't rewrite the file for each individual change, do it in one batch for simplicity
procedure TKMainSettings.SaveToXML;
var
  nMainSettings, nGFX, nWindow, nMisc: TXMLNode;
begin
  if Self = nil then Exit;
  if BLOCK_FILE_WRITE or SKIP_SETTINGS_SAVE then Exit;

  inherited;

  nMainSettings := Root.AddOrFindChild('Main');

  // GFX
  nGFX := nMainSettings.AddOrFindChild('GFX');
    nGFX.Attributes['FullScreen']       := fFullScreen;
    nGFX.Attributes['VSync']            := fVSync;
    nGFX.Attributes['ResolutionWidth']  := fResolution.Width;
    nGFX.Attributes['ResolutionHeight'] := fResolution.Height;
    nGFX.Attributes['RefreshRate']      := fResolution.RefRate;
    nGFX.Attributes['FPSCap']           := fFPSCap;

  // Window
  nWindow := nMainSettings.AddOrFindChild('Window');
    nWindow.Attributes['Left']    := fWindowParams.Left;
    nWindow.Attributes['Top']     := fWindowParams.Top;
    nWindow.Attributes['Width']   := fWindowParams.Width;
    nWindow.Attributes['Height']  := fWindowParams.Height;
    nWindow.Attributes['State']   := Ord(fWindowParams.State);

  // Misc
  nMisc := nMainSettings.AddOrFindChild('Misc');
    nMisc.Attributes['NoRenderMaxTime'] := fNoRenderMaxTime;
end;


function TKMainSettings.IsNoRenderMaxTimeSet: Boolean;
begin
  Result := fNoRenderMaxTime <> NO_RENDER_MAX_TIME_UNDEF;
end;


procedure TKMainSettings.SetFullScreen(aValue: boolean);
begin
  fFullScreen := aValue;
  Changed;
end;


procedure TKMainSettings.SetResolution(const Value: TKMScreenRes);
begin
  fResolution := Value;
  Changed;
end;


procedure TKMainSettings.SetVSync(aValue: boolean);
begin
  fVSync := aValue;
  Changed;
end;


end.
