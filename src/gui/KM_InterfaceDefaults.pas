unit KM_InterfaceDefaults;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLType, {$ENDIF}
  Controls, Classes,
  KM_Controls, KM_Points, KM_ResFonts,
  KM_ResTypes, KM_InterfaceTypes;


type
  TKMMenuPageCommon = class
  protected
    fMenuType: TKMMenuPageType;
    OnKeyDown: TNotifyEventKeyShift;
    OnEscKeyDown: TNotifyEvent;
  public
    constructor Create(aMenuType: TKMMenuPageType);
    property MenuType: TKMMenuPageType read fMenuType;
    procedure MenuKeyDown(Key: Word; Shift: TShiftState);
  end;

  TKMFileIdentInfo = record // File identification info (for maps/saves)
    CRC: Cardinal;
    Name: UnicodeString;
  end;


  TKMUserInterfaceCommon = class
  private
    fPrevHint: TObject;
    fPrevHintMessage: UnicodeString;
  protected
    fMyControls: TKMMasterControl;
    Panel_Main: TKMPanel;

    Label_Hint: TKMLabel;
    Bevel_HintBG: TKMBevel;

    procedure DisplayHint(Sender: TObject);
    procedure AfterCreateComplete;

    function GetHintPositionBase: TKMPoint; virtual; abstract;
    function GetHintFont: TKMFont; virtual; abstract;
  public
    constructor Create(aScreenX, aScreenY: Word);
    destructor Destroy; override;

    property MyControls: TKMMasterControl read fMyControls;
    procedure ExportPages(const aPath: string); virtual; abstract;
    procedure DebugControlsUpdated(aSenderTag: Integer); virtual;

    procedure KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean); virtual; abstract;
    procedure KeyPress(Key: Char); virtual;
    procedure KeyUp(Key: Word; Shift: TShiftState; var aHandled: Boolean); virtual;
    //Child classes don't pass these events to controls depending on their state
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer); virtual;
    procedure MouseMove(Shift: TShiftState; X,Y: Integer); overload;
    procedure MouseMove(Shift: TShiftState; X,Y: Integer; var aHandled: Boolean); overload; virtual; abstract;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X,Y: Integer); virtual; abstract;
    procedure MouseWheel(Shift: TShiftState; WheelSteps: Integer; X,Y: Integer; var aHandled: Boolean); virtual;
    procedure Resize(X,Y: Word); virtual;
    procedure UpdateState(aTickCount: Cardinal); virtual;
    procedure Paint; virtual;
  end;

const
  SUB_MENU_ACTIONS_CNT = 7;

type
  TKMMapEdMenuPage = class
  protected
    procedure DoShowSubMenu(aIndex: Byte); virtual;
    procedure DoExecuteSubMenuAction(aIndex: Byte; var aHandled: Boolean); virtual;
  public
    procedure ShowSubMenu(aIndex: Byte);
    procedure ExecuteSubMenuAction(aIndex: Byte; var aHandled: Boolean);

    function Visible: Boolean; virtual; abstract;
    function IsFocused: Boolean; virtual;
  end;


  TKMMapEdSubMenuPage = class
  protected
    fSubMenuActionsEvents: array[0..SUB_MENU_ACTIONS_CNT - 1] of TNotifyEvent;
    fSubMenuActionsCtrls: array[0..SUB_MENU_ACTIONS_CNT - 1] of array[0..1] of TKMControl;
  public
    procedure ExecuteSubMenuAction(aIndex: Byte; var aHandled: Boolean);
    function Visible: Boolean; virtual; abstract;
    function IsFocused: Boolean; virtual;
  end;


var
  MAPED_SUBMENU_HOTKEYS: array[0..5] of TKMKeyFunction;
  MAPED_SUBMENU_ACTIONS_HOTKEYS: array[0..SUB_MENU_ACTIONS_CNT - 1] of TKMKeyFunction;


implementation
uses
  SysUtils, KM_Resource, KM_ResKeys, KM_RenderUI, KM_Defaults, KM_DevPerfLog, KM_DevPerfLogTypes,
  KM_Music,
  KM_Sound,
  KM_GameSettings,
  KM_Main;


{ TKMUserInterface }
constructor TKMUserInterfaceCommon.Create(aScreenX, aScreenY: Word);
begin
  inherited Create;

  fMyControls := TKMMasterControl.Create;

  //Parent Panel for whole UI
  Panel_Main := TKMPanel.Create(fMyControls, 0, 0, aScreenX, aScreenY);

  // Controls without a hint will reset the Hint to ''
  fMyControls.OnHint := DisplayHint;
end;


destructor TKMUserInterfaceCommon.Destroy;
begin
  fMyControls.Free;
  inherited;
end;


procedure TKMUserInterfaceCommon.AfterCreateComplete;
var
  HintBase: TKMPoint;
begin
  HintBase := GetHintPositionBase;
  //Hints should be created last, as they should be above everything in UI, to be show on top of all other Controls
  Bevel_HintBG := TKMBevel.Create(Panel_Main, HintBase.X + 35, HintBase.Y - 23, 300, 21);
  Bevel_HintBG.BackAlpha := 0.5;
  Bevel_HintBG.EdgeAlpha := 0.5;
  Bevel_HintBG.Hide;
  Label_Hint := TKMLabel.Create(Panel_Main, HintBase.X + 40, HintBase.Y - 21, 0, 0, '', GetHintFont, taLeft);

  // Controls without a hint will reset the Hint to ''
  fMyControls.OnHint := DisplayHint;
end;


procedure TKMUserInterfaceCommon.DebugControlsUpdated(aSenderTag: Integer);
begin
  // Do nothing
end;


procedure TKMUserInterfaceCommon.DisplayHint(Sender: TObject);
var
  TxtSize: TKMPoint;
begin
  if (Label_Hint = nil) or (Bevel_HintBG = nil) then
    Exit;

  if (fPrevHint = nil) and (Sender = nil) then Exit; //in this case there is nothing to do

  if (fPrevHint <> nil) and (Sender = fPrevHint)
    and (TKMControl(fPrevHint).Hint = fPrevHintMessage) then Exit; // Hint didn't change (not only Hint object, but also Hint message didn't change)

  if (Sender = Label_Hint) or (Sender = Bevel_HintBG) then Exit; // When previous Hint obj is covered by Label_Hint or Bevel_HintBG ignore it.

  if (Sender = nil) or (TKMControl(Sender).Hint = '') then
  begin
    Label_Hint.Caption := '';
    Bevel_HintBG.Hide;
    fPrevHintMessage := '';
  end
  else
  begin
    Label_Hint.Caption := TKMControl(Sender).Hint;
    if SHOW_CONTROLS_ID then
      Label_Hint.Caption := Label_Hint.Caption + ' ' + TKMControl(Sender).GetIDsStr;

    TxtSize := gRes.Fonts[Label_Hint.Font].GetTextSize(Label_Hint.Caption);
    Bevel_HintBG.Width := 10 + TxtSize.X;
    Bevel_HintBG.Height := 2 + TxtSize.Y;
    Bevel_HintBG.Top := GetHintPositionBase.Y - Bevel_HintBG.Height - 2;
    Bevel_HintBG.Show;
    Label_Hint.Top := Bevel_HintBG.Top + 2;
    fPrevHintMessage := TKMControl(Sender).Hint;
  end;

  fPrevHint := Sender;
end;


procedure TKMUserInterfaceCommon.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  // Defocus debug controls on any inout in the player GUI
  gMain.FormMain.Defocus;
end;


procedure TKMUserInterfaceCommon.KeyPress(Key: Char);
begin
  fMyControls.KeyPress(Key);
end;


procedure TKMUserInterfaceCommon.KeyUp(Key: Word; Shift: TShiftState; var aHandled: Boolean);
var
  mutedAll: Boolean;
begin
  if aHandled then Exit;

  if Key = gResKeys[kfMusicPrevTrack].Key then
  begin
    gMusic.PlayPreviousTrack;
    aHandled := True;
  end;

  if Key = gResKeys[kfMusicNextTrack].Key then
  begin
    gMusic.PlayNextTrack;
    aHandled := True;
  end;

  if Key = gResKeys[kfMusicDisable].Key then
  begin
    gGameSettings.MusicOff := not gGameSettings.MusicOff;
    gMusic.ToggleEnabled(not gGameSettings.MusicOff);
    aHandled := True;
  end;

  if Key = gResKeys[kfMusicShuffle].Key then
  begin
    gGameSettings.ShuffleOn := not gGameSettings.ShuffleOn;
    gMusic.ToggleShuffle(gGameSettings.ShuffleOn);
    aHandled := True;
  end;

  if Key = gResKeys[kfMusicVolumeUp].Key then
  begin
    gGameSettings.MusicVolume := gGameSettings.MusicVolume + 1 / OPT_SLIDER_MAX;
    gMusic.Volume := gGameSettings.MusicVolume;
    aHandled := True;
  end;

  if Key = gResKeys[kfMusicVolumeDown].Key then
  begin
    gGameSettings.MusicVolume := gGameSettings.MusicVolume - 1 / OPT_SLIDER_MAX;
    gMusic.Volume := gGameSettings.MusicVolume;
    aHandled := True;
  end;

  if Key = gResKeys[kfMusicMute].Key then
  begin
    gMusic.ToggleMuted;
    gGameSettings.MusicVolume := gMusic.Volume;
    aHandled := True;
  end;

  if Key = gResKeys[kfSoundVolumeUp].Key then
  begin
    gGameSettings.SoundFXVolume := gGameSettings.SoundFXVolume + 1 / OPT_SLIDER_MAX;
    gSoundPlayer.UpdateSoundVolume(gGameSettings.SoundFXVolume);
    aHandled := True;
  end;

  if Key = gResKeys[kfSoundVolumeDown].Key then
  begin
    gGameSettings.SoundFXVolume := gGameSettings.SoundFXVolume - 1 / OPT_SLIDER_MAX;
    gSoundPlayer.UpdateSoundVolume(gGameSettings.SoundFXVolume);
    aHandled := True;
  end;

  if Key = gResKeys[kfSoundMute].Key then
  begin
    gSoundPlayer.ToggleMuted;
    gGameSettings.SoundFXVolume := gSoundPlayer.Volume;
    aHandled := True;
  end;

  if Key = gResKeys[kfMuteAll].Key then
  begin
    mutedAll := gSoundPlayer.Muted and gMusic.Muted;
    
    gSoundPlayer.Muted := not mutedAll;
    gMusic.Muted := not mutedAll;
    gGameSettings.SoundFXVolume := gSoundPlayer.Volume;
    gGameSettings.MusicVolume := gMusic.Volume;
    aHandled := True;
  end;
end;


procedure TKMUserInterfaceCommon.MouseMove(Shift: TShiftState; X, Y: Integer);
var MouseMoveHandled: Boolean;
begin
  MouseMove(Shift, X, Y, MouseMoveHandled);
end;


procedure TKMUserInterfaceCommon.MouseWheel(Shift: TShiftState; WheelSteps, X, Y: Integer; var aHandled: Boolean);
begin
  fMyControls.MouseWheel(X, Y, WheelSteps, aHandled);
end;


procedure TKMUserInterfaceCommon.Resize(X, Y: Word);
var
  HintBase: TKMPoint;
begin
  Panel_Main.Width := X;
  Panel_Main.Height := Y;

  if (Bevel_HintBG = nil) or (Label_Hint = nil) then
    Exit;

  HintBase := GetHintPositionBase;
  Bevel_HintBG.Left := HintBase.X + 35;
  Bevel_HintBG.Top := HintBase.Y - 23;
  Label_Hint.Left := HintBase.X + 40;
  Label_Hint.Top := HintBase.Y - 21;
end;


procedure TKMUserInterfaceCommon.UpdateState(aTickCount: Cardinal);
begin
  inherited;
  fMyControls.UpdateState(aTickCount);
end;


procedure TKMUserInterfaceCommon.Paint;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psFrameGui);
  {$ENDIF}
  fMyControls.Paint;
  {$IFDEF PERFLOG}
  gPerfLogs.SectionLeave(psFrameGui);
  {$ENDIF}
end;


{ TKMMenuPageCommon }
constructor TKMMenuPageCommon.Create(aMenuType: TKMMenuPageType);
begin
  inherited Create;

  fMenuType := aMenuType;
end;


procedure TKMMenuPageCommon.MenuKeyDown(Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE:  if Assigned(OnEscKeyDown) then
                  OnEscKeyDown(Self);
    else        if Assigned(OnKeyDown) then
                  OnKeyDown(Key, Shift);
  end;
end;


{ TKMMapEdSubMenuPage }
procedure TKMMapEdMenuPage.ShowSubMenu(aIndex: Byte);
begin
  if Visible then
    DoShowSubMenu(aIndex);
end;


function TKMMapEdMenuPage.IsFocused: Boolean;
begin
  Result := Visible;
end;


procedure TKMMapEdMenuPage.ExecuteSubMenuAction(aIndex: Byte; var aHandled: Boolean);
begin
  if IsFocused then
    DoExecuteSubMenuAction(aIndex, aHandled);
end;


procedure TKMMapEdMenuPage.DoShowSubMenu(aIndex: Byte);
begin
  //just empty stub here
end;


procedure TKMMapEdMenuPage.DoExecuteSubMenuAction(aIndex: Byte; var aHandled: Boolean);
begin
  //just empty stub here
end;


{ TKMMapEdSubMenuPage }
procedure TKMMapEdSubMenuPage.ExecuteSubMenuAction(aIndex: Byte; var aHandled: Boolean);
var
  I: Integer;
begin
  if aHandled or not IsFocused or not Assigned(fSubMenuActionsEvents[aIndex]) then Exit;

  for I := Low(fSubMenuActionsCtrls[aIndex]) to High(fSubMenuActionsCtrls[aIndex]) do
    if (fSubMenuActionsCtrls[aIndex, I] <> nil)
      and fSubMenuActionsCtrls[aIndex, I].IsClickable then
    begin
      if fSubMenuActionsCtrls[aIndex, I] is TKMCheckBox then
        TKMCheckBox(fSubMenuActionsCtrls[aIndex, I]).SwitchCheck;

      // Call event only once
      fSubMenuActionsEvents[aIndex](fSubMenuActionsCtrls[aIndex, I]);
      aHandled := True;
      Exit;
    end;
end;


function TKMMapEdSubMenuPage.IsFocused: Boolean;
begin
  Result := Visible;
end;


initialization
begin
  MAPED_SUBMENU_HOTKEYS[0] := kfMapedSubMenu1;
  MAPED_SUBMENU_HOTKEYS[1] := kfMapedSubMenu2;
  MAPED_SUBMENU_HOTKEYS[2] := kfMapedSubMenu3;
  MAPED_SUBMENU_HOTKEYS[3] := kfMapedSubMenu4;
  MAPED_SUBMENU_HOTKEYS[4] := kfMapedSubMenu5;
  MAPED_SUBMENU_HOTKEYS[5] := kfMapedSubMenu6;

  MAPED_SUBMENU_ACTIONS_HOTKEYS[0] := kfMapedSubMenuAction1;
  MAPED_SUBMENU_ACTIONS_HOTKEYS[1] := kfMapedSubMenuAction2;
  MAPED_SUBMENU_ACTIONS_HOTKEYS[2] := kfMapedSubMenuAction3;
  MAPED_SUBMENU_ACTIONS_HOTKEYS[3] := kfMapedSubMenuAction4;
  MAPED_SUBMENU_ACTIONS_HOTKEYS[4] := kfMapedSubMenuAction5;
  MAPED_SUBMENU_ACTIONS_HOTKEYS[5] := kfMapedSubMenuAction6;
  MAPED_SUBMENU_ACTIONS_HOTKEYS[6] := kfMapedSubMenuAction7;
end;


end.
