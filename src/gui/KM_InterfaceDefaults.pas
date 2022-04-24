unit KM_InterfaceDefaults;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLType, {$ENDIF}
  Classes,
  Controls,
  KM_Controls, KM_ControlsBase,
  KM_Points, KM_ResFonts,
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

  TKMHintStage = (hsFadeIn, hsShown, hsReset);


  TKMUserInterfaceCommon = class
  private
    fHintOver: TKMControl;
    fHintPrevOver: TKMControl;
    fHintPrepareShowTick: Cardinal;
    fHintPrepareResetTick: Cardinal;
    fHintVisible: Boolean;
    fHintCtrl: TKMControl;
    fHintStage: TKMHintStage;

    fHintDebug: TKMShape;
    fHintDebugLbl: TKMLabel;

//    fPrevHint: TKMControl;
//    fPrevHintMessage: UnicodeString;

    procedure PaintHint;
    procedure UpdateHint(aGlobalTickCount: Cardinal);

    function GetHintActualKind: TKMHintKind;
    function GetHintActualFont: TKMFont;

    procedure SetHintBackStaticAlpha;

    procedure HandleSoundVolumeKeys(Key: Word; var aHandled: Boolean);
    procedure HandleSoundKeys(Key: Word; var aHandled: Boolean);
  protected
    fMyControls: TKMMasterControl;
    Panel_Main: TKMPanel;

    Label_Hint: TKMLabel;
    Bevel_HintBG: TKMBevel;

//    procedure DisplayHint(Sender: TObject);
    procedure AfterCreateComplete;

    function GetHintPositionBase: TKMPoint; virtual;
    function GetHintFont: TKMFont; virtual; abstract;
    function GetHintKind: TKMHintKind; virtual; abstract;

    procedure UpdateCursor(X, Y: Integer; Shift: TShiftState);

    procedure ResetHint;

    function GetToolbarWidth: Integer; virtual;
  public
    constructor Create(aScreenX, aScreenY: Word);
    destructor Destroy; override;

    property MyControls: TKMMasterControl read fMyControls;
    procedure ExportPages(const aPath: string); virtual; abstract;
    procedure DebugControlsUpdated(aSenderTag: Integer); virtual;

    function GetMainPanelSize: TKMPoint;

    property ToolbarWidth: Integer read GetToolbarWidth;

    procedure KeyDown(Key: Word; Shift: TShiftState; aIsFirst: Boolean; var aHandled: Boolean); virtual;
    procedure KeyPress(Key: Char); virtual;
    procedure KeyUp(Key: Word; Shift: TShiftState; var aHandled: Boolean); virtual;
    //Child classes don't pass these events to controls depending on their state
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer); virtual;
    procedure MouseMove(Shift: TShiftState; X,Y: Integer); overload;
    procedure MouseMove(Shift: TShiftState; X,Y: Integer; var aHandled: Boolean); overload; virtual; abstract;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X,Y: Integer); virtual; abstract;
    procedure MouseWheel(Shift: TShiftState; WheelSteps: Integer; X,Y: Integer; var aHandled: Boolean); virtual;
    procedure Resize(X,Y: Word); virtual;
    procedure UpdateHotkeys; virtual; abstract;
    procedure UpdateState(aGlobalTickCount: Cardinal); virtual;
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
  SysUtils, Math,
  KM_ControlsSwitch,
  KM_Resource, KM_ResKeys, KM_RenderUI, KM_RenderAux, KM_Defaults, KM_DevPerfLog, KM_DevPerfLogTypes,
  KM_Cursor,
  KM_Music,
  KM_Sound,
  KM_GameSettings,
  KM_Main,
  KM_CommonTypes;


{ TKMUserInterface }
constructor TKMUserInterfaceCommon.Create(aScreenX, aScreenY: Word);
begin
  inherited Create;

  fMyControls := TKMMasterControl.Create;

  //Parent Panel for whole UI
  Panel_Main := TKMPanel.Create(fMyControls, 0, 0, aScreenX, aScreenY);
end;


destructor TKMUserInterfaceCommon.Destroy;
begin
  fMyControls.Free;
  inherited;
end;


procedure TKMUserInterfaceCommon.AfterCreateComplete;
var
  hintBase: TKMPoint;
begin
  hintBase := GetHintPositionBase;
  //Hints should be created last, as they should be above everything in UI, to be show on top of all other Controls
  Bevel_HintBG := TKMBevel.Create(Panel_Main, hintBase.X + 35, hintBase.Y - 23, 300, 21);
  SetHintBackStaticAlpha;
  Bevel_HintBG.Hide;
  Label_Hint := TKMLabel.Create(Panel_Main, hintBase.X + 40, hintBase.Y - 21, 0, 0, '', GetHintFont, taLeft);

  fHintDebug := TKMShape.Create(Panel_Main, 0, 0, 50, 20);
  fHintDebug.FillColor := $80888888;
  fHintDebug.LineColor := $B0888888;
  fHintDebugLbl := TKMLabel.Create(Panel_Main, 0, 0, '', fntMonospaced, taLeft);

  fHintDebugLbl.Hide;
  fHintDebug.Hide;
end;


procedure TKMUserInterfaceCommon.DebugControlsUpdated(aSenderTag: Integer);
begin
  // Do nothing
end;


//procedure TKMUserInterfaceCommon.DisplayHint(Sender: TObject);
//var
//  txtSize: TKMPoint;
//begin
//  if (Label_Hint = nil) or (Bevel_HintBG = nil) then
//    Exit;
//
//  if (fPrevHint = nil) and (Sender = nil) then Exit; //in this case there is nothing to do
//
//  if (fPrevHint <> nil) and (Sender = fPrevHint)
//    and (TKMControl(fPrevHint).Hint = fPrevHintMessage) then Exit; // Hint didn't change (not only Hint object, but also Hint message didn't change)
//
//  if (Sender = Label_Hint) or (Sender = Bevel_HintBG) then Exit; // When previous Hint obj is covered by Label_Hint or Bevel_HintBG ignore it.
//
//  if (Sender = nil) or (TKMControl(Sender).Hint = '') then
//  begin
//    Label_Hint.Caption := '';
//    Bevel_HintBG.Hide;
//    fPrevHintMessage := '';
//  end
//  else
//  begin
//    Label_Hint.Caption := TKMControl(Sender).Hint;
//    if SHOW_CONTROLS_ID then
//      Label_Hint.Caption := Label_Hint.Caption + ' ' + TKMControl(Sender).GetIDsStr;
//
//    txtSize := gRes.Fonts[Label_Hint.Font].GetTextSize(Label_Hint.Caption);
//    Bevel_HintBG.Width := 10 + txtSize.X;
//    Bevel_HintBG.Height := 2 + txtSize.Y;
//    Bevel_HintBG.Top := GetHintPositionBase.Y - Bevel_HintBG.Height - 2;
//    Bevel_HintBG.Show;
//    Label_Hint.Top := Bevel_HintBG.Top + 2;
//    fPrevHintMessage := TKMControl(Sender).Hint;
//  end;
//
//  fPrevHint := Sender;
//end;


procedure TKMUserInterfaceCommon.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  // Defocus debug controls on any inout in the player GUI
  gMain.FormMain.Defocus;
end;


procedure TKMUserInterfaceCommon.KeyPress(Key: Char);
begin
  fMyControls.KeyPress(Key);
end;


procedure TKMUserInterfaceCommon.HandleSoundVolumeKeys(Key: Word; var aHandled: Boolean);
begin
  if aHandled then Exit;

  if Key = gResKeys[kfMusicVolumeUp] then
  begin
    gGameSettings.MusicVolume := gGameSettings.MusicVolume + 1 / OPT_SLIDER_MAX;
    gMusic.Volume := gGameSettings.MusicVolume;
    aHandled := True;
  end;

  if Key = gResKeys[kfMusicVolumeDown] then
  begin
    gGameSettings.MusicVolume := gGameSettings.MusicVolume - 1 / OPT_SLIDER_MAX;
    gMusic.Volume := gGameSettings.MusicVolume;
    aHandled := True;
  end;

  if Key = gResKeys[kfSoundVolumeUp] then
  begin
    gGameSettings.SoundFXVolume := gGameSettings.SoundFXVolume + 1 / OPT_SLIDER_MAX;
    gSoundPlayer.UpdateSoundVolume(gGameSettings.SoundFXVolume);
    aHandled := True;
  end;

  if Key = gResKeys[kfSoundVolumeDown] then
  begin
    gGameSettings.SoundFXVolume := gGameSettings.SoundFXVolume - 1 / OPT_SLIDER_MAX;
    gSoundPlayer.UpdateSoundVolume(gGameSettings.SoundFXVolume);
    aHandled := True;
  end;
end;


procedure TKMUserInterfaceCommon.HandleSoundKeys(Key: Word; var aHandled: Boolean);
var
  mutedAll: Boolean;
begin
  if aHandled then Exit;

  if Key = gResKeys[kfMusicPrevTrack] then
  begin
    gMusic.PlayPreviousTrack;
    aHandled := True;
  end;

  if Key = gResKeys[kfMusicNextTrack] then
  begin
    gMusic.PlayNextTrack;
    aHandled := True;
  end;

  if Key = gResKeys[kfMusicDisable] then
  begin
    gGameSettings.MusicOff := not gGameSettings.MusicOff;
    gMusic.ToggleEnabled(not gGameSettings.MusicOff);
    aHandled := True;
  end;

  if Key = gResKeys[kfMusicShuffle] then
  begin
    gGameSettings.ShuffleOn := not gGameSettings.ShuffleOn;
    gMusic.ToggleShuffle(gGameSettings.ShuffleOn);
    aHandled := True;
  end;

  if Key = gResKeys[kfMusicMute] then
  begin
    gMusic.ToggleMuted;
    gGameSettings.MusicVolume := gMusic.Volume;
    aHandled := True;
  end;

  if Key = gResKeys[kfSoundMute] then
  begin
    gSoundPlayer.ToggleMuted;
    gGameSettings.SoundFXVolume := gSoundPlayer.Volume;
    aHandled := True;
  end;

  if Key = gResKeys[kfMuteAll] then
  begin
    mutedAll := gSoundPlayer.Muted and gMusic.Muted;

    gSoundPlayer.Muted := not mutedAll;
    gMusic.Muted := not mutedAll;
    gGameSettings.SoundFXVolume := gSoundPlayer.Volume;
    gGameSettings.MusicVolume := gMusic.Volume;
    aHandled := True;
  end;
end;


// This event happens every ~33ms if the Key is Down and holded
procedure TKMUserInterfaceCommon.KeyDown(Key: Word; Shift: TShiftState; aIsFirst: Boolean; var aHandled: Boolean);
begin
  if aHandled then Exit;

  HandleSoundVolumeKeys(Key, aHandled);

  if aIsFirst then Exit;

  HandleSoundKeys(Key, aHandled);
end;


procedure TKMUserInterfaceCommon.KeyUp(Key: Word; Shift: TShiftState; var aHandled: Boolean);
begin
//
end;


procedure TKMUserInterfaceCommon.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  mouseMoveHandled: Boolean;
begin
  UpdateCursor(X, Y, Shift);
  MouseMove(Shift, X, Y, mouseMoveHandled);
end;


procedure TKMUserInterfaceCommon.MouseWheel(Shift: TShiftState; WheelSteps, X, Y: Integer; var aHandled: Boolean);
begin
  fMyControls.MouseWheel(X, Y, WheelSteps, aHandled);
end;


procedure TKMUserInterfaceCommon.SetHintBackStaticAlpha;
begin
  Bevel_HintBG.BackAlpha := 0.5;
  Bevel_HintBG.EdgeAlpha := 0.5;
end;


procedure TKMUserInterfaceCommon.ResetHint;
begin
  fHintCtrl := nil;
end;


procedure TKMUserInterfaceCommon.Resize(X, Y: Word);
begin
  Panel_Main.Width := X;
  Panel_Main.Height := Y;
end;


procedure TKMUserInterfaceCommon.UpdateState(aGlobalTickCount: Cardinal);
begin
  inherited;

  fMyControls.UpdateState(aGlobalTickCount);
  UpdateHint(aGlobalTickCount);
end;


procedure TKMUserInterfaceCommon.UpdateCursor(X, Y: Integer; Shift: TShiftState);
begin
  gCursor.Pixel.X := X;
  gCursor.Pixel.Y := Y;
  gCursor.SState := Shift;
end;


procedure TKMUserInterfaceCommon.UpdateHint(aGlobalTickCount: Cardinal);
const
  FADE_IN_TIME = 10;
  FADE_RESET_TIME = 5;
begin
  fHintOver := fMyControls.CtrlOver;

  case fHintStage of
    hsFadeIn: // Hint was hidden a long time ago
              begin
                // If mouse moved to other control then reset fade-in timer
                if fHintPrevOver <> fHintOver then
                  fHintPrepareShowTick := aGlobalTickCount;
                // Mouse is on the same control for a long time
                if (fHintOver <> nil) and (fHintOver.Hint <> '')
                and (((aGlobalTickCount - fHintPrepareShowTick) >= FADE_IN_TIME) {or (fHintOver is TKMHint)}
                    or (GetHintKind = hkStatic)) then
                begin
                  // Display hint
                  fHintCtrl := fHintOver;
                  fHintVisible := True;

                  // Set stage when hint is visible
                  fHintStage := hsShown;
                end;
              end;
    hsShown:  // Hint is visible
              begin
                // If control loses hover we must hide hint
                if (fHintOver = nil) or (fHintOver <> fHintCtrl) then
                begin
                  // Hide hint
                  fHintCtrl := nil;
                  fHintVisible := False;

                  // Launch fade-in resetting timer
                  fHintPrepareResetTick := aGlobalTickCount;

                  // Set stage when hint was hidden recently
                  fHintStage := hsReset;
                end;
              end;
    hsReset:  // Hint was hidden recently
              begin
                // If no control is hovered a long time we must activate fade-in logic
                if (aGlobalTickCount - fHintPrepareResetTick) >= FADE_RESET_TIME then
                begin
                  fHintPrepareShowTick := aGlobalTickCount;

                  // Set stage when hint was hidden a long time ago
                  fHintStage := hsFadeIn;
                end
                else
                // Mouse was on another control in 'fade reset' period, we must show hint immediately
                if (fHintOver <> nil) and (fHintOver.Hint <> '')  then
                begin
                  fHintCtrl := fHintOver;
                  fHintVisible := True;

                  // Set stage when hint is visible
                  fHintStage := hsShown;
                end;
              end;
  end;

  // Save hovered control to compare it on next tick
  fHintPrevOver := fHintOver;
end;


function TKMUserInterfaceCommon.GetHintActualFont: TKMFont;
begin
  Result := GetHintFont;

  if fHintCtrl = nil then Exit;

  if GetHintActualKind = hkTextNotFit then
    Result := fHintCtrl.HintFont;
end;


function TKMUserInterfaceCommon.GetHintActualKind: TKMHintKind;
begin
  Result := GetHintKind;

  if fHintCtrl = nil then Exit;

  if fHintCtrl.HintKind = hkTextNotFit then
    Result := hkTextNotFit; // For lists and columnboxes we should use this one in any case
end;


function TKMUserInterfaceCommon.GetHintPositionBase: TKMPoint;
begin
  Result := KMPOINT_ZERO;
end;


function TKMUserInterfaceCommon.GetMainPanelSize: TKMPoint;
begin
  if Self = nil then Exit(KMPOINT_ZERO);
  
  Result := KMPoint(Panel_Main.Width, Panel_Main.Height);
end;


function TKMUserInterfaceCommon.GetToolbarWidth: Integer;
begin
  Result := 0;
end;


procedure TKMUserInterfaceCommon.PaintHint;
const
  PAD = 8;
  FONT_Y_FIX = 3;
  MARGIN = 2;

  PAD_DBG_X = 5;
  PAD_DBG_Y = 3;
var
  hintBase, hintTxtOffset: TKMPoint;
  hintBackRect: TKMRect;
  left, top: Integer;
begin
  if DBG_UI_HINT_POS then
  begin
    fHintDebugLbl.Caption := gCursor.Pixel.ToString;

    fHintDebug.Width := fHintDebugLbl.TextSize.X + 2*PAD_DBG_X;
    fHintDebug.Height := fHintDebugLbl.TextSize.Y + 2*PAD_DBG_Y;

    left := gCursor.Pixel.X - fHintDebug.Width;
    if left < 0 then
      left := gCursor.Pixel.X + 25;

    fHintDebug.AbsLeft := left;

    top := gCursor.Pixel.Y - fHintDebug.Height;
    if top < 0 then
      top := gCursor.Pixel.Y + 25;

    fHintDebug.AbsTop := top;

    fHintDebugLbl.AbsLeft := fHintDebug.AbsLeft + PAD_DBG_X;
    fHintDebugLbl.AbsTop := fHintDebug.AbsTop + PAD_DBG_Y;

    // Draw axis
    gRenderAux.Line(gCursor.Pixel.X, 0, gCursor.Pixel.X, Panel_Main.Height, icDarkOrange, $F0F0, 2);
    gRenderAux.Line(0, gCursor.Pixel.Y, Panel_Main.Width, gCursor.Pixel.Y, icDarkOrange, $F0F0, 2);

    fHintDebug.Show;
    fHintDebugLbl.Show;
    fHintDebug.Paint;
    fHintDebugLbl.Paint;
    fHintDebugLbl.Hide;
    fHintDebug.Hide;
  end;

  if fHintCtrl = nil then Exit;

  if (Label_Hint = nil) or (Bevel_HintBG = nil) then
    Exit;

//  if (fPrevHint = nil) and (Sender = nil) then Exit; // In this case there is nothing to do
//
//  // Hint didn't change (not only Hint object, but also Hint message didn't change)
//  if (fPrevHint <> nil) and (Sender = fPrevHint)
//    and (TKMControl(fPrevHint).Hint = fPrevHintMessage) then Exit;
//
//  // When previous Hint obj is covered by Label_Hint or Bevel_HintBG ignore it
//  if (Sender = Label_Hint) or (Sender = Bevel_HintBG) then Exit;

  Label_Hint.Font := GetHintActualFont;
  Label_Hint.Caption := fHintCtrl.Hint;
  Label_Hint.FontColor := icWhite;

  if Label_Hint.TextSize.X = 0 then Exit;

  case GetHintActualKind of
    hkControl:      begin
                      Bevel_HintBG.Width := Label_Hint.TextSize.X + PAD;
                      Bevel_HintBG.Height := Label_Hint.TextSize.Y + PAD;
                      Bevel_HintBG.AbsLeft := EnsureRange(fHintCtrl.AbsLeft + fHintCtrl.Width div 2 - Bevel_HintBG.Width div 2,
                                                          MARGIN, Panel_Main.Width - Bevel_HintBG.Width - MARGIN);
                      Bevel_HintBG.AbsTop := fHintCtrl.AbsTop - Bevel_HintBG.Height - FONT_Y_FIX;

                      if Bevel_HintBG.AbsTop <= 0 then
                        Bevel_HintBG.AbsTop := fHintCtrl.AbsTop + fHintCtrl.Height + FONT_Y_FIX;

                      Label_Hint.AbsLeft := Bevel_HintBG.AbsLeft + PAD div 2;//Bevel_HintBG.Width div 2;
                      Label_Hint.AbsTop := Bevel_HintBG.AbsTop + PAD div 2 + (FONT_Y_FIX - 1);

                      Bevel_HintBG.BackAlpha := fHintCtrl.HintBackColor.A;
                      Bevel_HintBG.SetDefEdgeAlpha;
                      Bevel_HintBG.Color := fHintCtrl.HintBackColor.ToColor3f;
                    end;
    hkStatic:       begin
                      hintBase := GetHintPositionBase;

                      Bevel_HintBG.Left := hintBase.X;// Max(0, right - Bevel_HintBG.Width);
                      Bevel_HintBG.Width := Label_Hint.TextSize.X + 10;
                      Bevel_HintBG.Height := Label_Hint.TextSize.Y + 2;
                      Bevel_HintBG.Top := hintBase.Y - Bevel_HintBG.Height - 2;
                      Label_Hint.Left := Bevel_HintBG.Left + 5;
                      Label_Hint.Top := Bevel_HintBG.Top + 2;
                      SetHintBackStaticAlpha;
                    end;
    hkTextNotFit:   begin
                      hintTxtOffset := fHintCtrl.HintTextOffset;
                      hintBackRect := fHintCtrl.HintBackRect;

                      Bevel_HintBG.AbsLeft := fHintCtrl.AbsLeft + hintBackRect.Left;
                      Bevel_HintBG.AbsTop := fHintCtrl.AbsTop + hintBackRect.Top;
                      Bevel_HintBG.Width := Label_Hint.TextSize.X + PAD;
                      Bevel_HintBG.Height := hintBackRect.Height; //Max(Bevel_HintBG.Height, hintBackRect.Height);

                      // We could show outline for a selected element, if we want, in the future
//                      if fHintCtrl.HintSelected then
//                        TKMRenderUI.WriteShape(Bevel_HintBG.AbsLeft, Bevel_HintBG.AbsTop,
//                                               Bevel_HintBG.Width, Bevel_HintBG.Height, icTransparent, icWhite);

                      Label_Hint.AbsLeft := fHintCtrl.AbsLeft + hintTxtOffset.X;
                      Label_Hint.AbsTop := fHintCtrl.AbsTop + hintTxtOffset.Y;
                      Label_Hint.FontColor := fHintCtrl.HintTextColor;

                      Bevel_HintBG.Color := fHintCtrl.HintBackColor.ToColor3f;

                      Bevel_HintBG.BackAlpha := 1;
                      Bevel_HintBG.SetDefEdgeAlpha;
                    end;
  end;

  Bevel_HintBG.Show;
  Label_Hint.Show;

  Bevel_HintBG.Paint;
  Label_Hint.Paint;

  Bevel_HintBG.Hide;
  Label_Hint.Hide;
end;


procedure TKMUserInterfaceCommon.Paint;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psFrameGui);
  {$ENDIF}
  fMyControls.Paint;

  // Hint should be painted above everything
  PaintHint;
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
