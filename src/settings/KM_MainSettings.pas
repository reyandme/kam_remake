unit KM_MainSettings;
{$I KaM_Remake.inc}
interface
uses
  Classes,
  {$IFDEF WDC}UITypes,{$ENDIF} //We use settings in console modules
  KM_Resolutions,
  KM_Defaults,
  KM_WindowParams,
  KM_IoXML,
  KM_GameAppSettingsPart;

type
  // Settings that are irrelevant to the game (game does not care about them)
  TKMainSettings = class(TKMGameAppSettingsPart)
  private
    // Not a setting
    // This is current screen resolution used used to set default Resolution and Form size
    fScreenWidth: Integer;
    fScreenHeight: Integer;

    fFPSCap: Integer;
    fWindowParams: TKMWindowParams;
    fNoRenderMaxTime: Integer;     // Longest period of time, when there was no Render (usually on hiiiigh game speed like x300)
    function GetWindowParams: TKMWindowParams;
  public
    FullScreen: Boolean;
    Resolution: TKMScreenRes;
    VSync: Boolean;

    constructor Create(aScreenWidth, aScreenHeight: Integer);
    destructor Destroy; override;

    procedure LoadFromXML; override;
    procedure SaveToXML; override;

    property FPSCap: Integer read fFPSCap;
    property WindowParams: TKMWindowParams read GetWindowParams;
    property NoRenderMaxTime: Integer read fNoRenderMaxTime;

    function IsNoRenderMaxTimeSet: Boolean;
  end;


var
  gMainSettings: TKMainSettings;


implementation
uses
  SysUtils, INIfiles, Math, Forms;

const
  NO_RENDER_MAX_TIME_MIN = 10; //in ms
  NO_RENDER_MAX_TIME_DEFAULT = 1000; //in ms
  NO_RENDER_MAX_TIME_UNDEF = -1; //undefined


{ TKMainSettings }
constructor TKMainSettings.Create(aScreenWidth, aScreenHeight: Integer);
begin
  inherited Create;

  fWindowParams := TKMWindowParams.Create;
  fScreenWidth := aScreenWidth;
  fScreenHeight := aScreenHeight;
end;


destructor TKMainSettings.Destroy;
begin
  FreeAndNil(fWindowParams);

  inherited;
end;


function TKMainSettings.GetWindowParams: TKMWindowParams;
begin
  if Self = nil then Exit(nil);

  Result := fWindowParams;
end;


procedure TKMainSettings.LoadFromXML;
var
  nMainSettings, nGFX, nWindow, nMisc: TKMXmlNode;
begin
  if Self = nil then Exit;

  inherited;

  nMainSettings := Root.AddOrFindChild('Main');

  // GFX
  nGFX := nMainSettings.AddOrFindChild('GFX');
  FullScreen         := nGFX.Attributes['FullScreen'].AsBoolean(False);
  VSync              := nGFX.Attributes['VSync'].AsBoolean(True);
  Resolution.Width   := nGFX.Attributes['ResolutionWidth'].AsInteger(Max(MENU_DESIGN_X, fScreenWidth));
  Resolution.Height  := nGFX.Attributes['ResolutionHeight'].AsInteger(Max(MENU_DESIGN_Y, fScreenHeight));
  Resolution.RefRate := nGFX.Attributes['RefreshRate'].AsInteger(60);
  fFPSCap := EnsureRange(nGFX.Attributes['FPSCap'].AsInteger(DEF_FPS_CAP), MIN_FPS_CAP, MAX_FPS_CAP);

  // Window
  // For proper window positioning we need Left and Top records
  // Otherwise reset all window params to defaults
  nWindow := nMainSettings.AddOrFindChild('Window');
  if nWindow.HasAttribute('Left') and nWindow.HasAttribute('Top') then
  begin
    fWindowParams.Left      := nWindow.Attributes['Left'].AsInteger(-1);
    fWindowParams.Top       := nWindow.Attributes['Top'].AsInteger(-1);
    fWindowParams.Width     := nWindow.Attributes['Width'].AsInteger(Max(MENU_DESIGN_X, fScreenWidth));
    fWindowParams.Height    := nWindow.Attributes['Height'].AsInteger(Max(MENU_DESIGN_Y, fScreenHeight));
    fWindowParams.State     := TWindowState(EnsureRange(nWindow.Attributes['State'].AsInteger(Integer(wsNormal)), 0, 2));
    fWindowParams.Position  := TPosition(EnsureRange(nWindow.Attributes['Position'].AsInteger(Integer(poScreenCenter)), 0, 7));
    fWindowParams.FixedPosition  := nWindow.Attributes['FixedPosition'].AsBoolean(False);
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
  nMainSettings, nGFX, nWindow, nMisc: TKMXmlNode;
begin
  if Self = nil then Exit;
  if BLOCK_FILE_WRITE or SKIP_SETTINGS_SAVE then Exit;

  inherited;

  nMainSettings := Root.AddOrFindChild('Main');
  // Clear old data before filling in
  nMainSettings.Clear;

  // GFX
  nGFX := nMainSettings.AddOrFindChild('GFX');
    nGFX.Attributes['FullScreen']       := FullScreen;
    nGFX.Attributes['VSync']            := VSync;
    nGFX.Attributes['ResolutionWidth']  := Resolution.Width;
    nGFX.Attributes['ResolutionHeight'] := Resolution.Height;
    nGFX.Attributes['RefreshRate']      := Resolution.RefRate;
    nGFX.Attributes['FPSCap']           := fFPSCap;

  // Window
  nWindow := nMainSettings.AddOrFindChild('Window');
    nWindow.Attributes['Left']          := fWindowParams.Left;
    nWindow.Attributes['Top']           := fWindowParams.Top;
    nWindow.Attributes['Width']         := fWindowParams.Width;
    nWindow.Attributes['Height']        := fWindowParams.Height;
    nWindow.Attributes['State']         := Ord(fWindowParams.State);
    nWindow.Attributes['Position']      := Ord(fWindowParams.Position);
    nWindow.Attributes['FixedPosition'] := fWindowParams.FixedPosition;

  // Misc
  nMisc := nMainSettings.AddOrFindChild('Misc');
    nMisc.Attributes['NoRenderMaxTime'] := fNoRenderMaxTime;
end;


function TKMainSettings.IsNoRenderMaxTimeSet: Boolean;
begin
  Result := fNoRenderMaxTime <> NO_RENDER_MAX_TIME_UNDEF;
end;


end.
