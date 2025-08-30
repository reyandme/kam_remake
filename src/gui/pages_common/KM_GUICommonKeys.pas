unit KM_GUICommonKeys;
{$I KaM_Remake.inc}
interface
uses
  Classes,
  KM_ResKeys,
  KM_Controls, KM_ControlsBase, KM_ControlsList, KM_ControlsForm,
  KM_CommonTypes;

type
  TKMGUICommonKeys = class
  private
    fTempKeys: TKMResKeys;

    fOnKeysUpdated: TKMEvent;

    procedure Hide;
    procedure ButtonOkClick(Sender: TObject);
    procedure ButtonCancelClick(Sender: TObject);
    procedure ButtonClearClick(Sender: TObject);
    procedure ButtonResetClick(Sender: TObject);
    procedure ListClick(Sender: TObject);
    procedure KeysRefreshList;
    function ListKeyUp(Sender: TObject; Key: Word; Shift: TShiftState): Boolean;
    function GetVisible: Boolean;
  protected
    Form_OptionsKeys: TKMForm;
    Panel_Content: TKMPanel;
    ColumnBox_OptionsKeys: TKMColumnBox;
    Button_OptionsKeysClear: TKMButton;
    Button_OptionsKeysReset: TKMButton;
    Button_OptionsKeysOK: TKMButton;
    Button_OptionsKeysCancel: TKMButton;
  public
    OnClose: TKMEvent;
    constructor Create(aParent: TKMPanel; aOnKeysUpdated: TKMEvent; aDrawBGBevel: Boolean = True);
    destructor Destroy; override;

    procedure Show;
    property Visible: Boolean read GetVisible;
  end;

implementation
uses
  SysUtils, Math,
  KM_ResTypes, KM_Sound, KM_ResSound, KM_ResKeyFuncs,
  KM_GameSettings,
  KM_ResTexts, KM_RenderUI, KM_Pics, KM_ResFonts;


{ TKMGUICommonKeys }
constructor TKMGUICommonKeys.Create(aParent: TKMPanel; aOnKeysUpdated: TKMEvent; aDrawBGBevel: Boolean = True);
const
  FULL_WIDTH = 660;
  FULL_HEIGHT = 620;
  PAD = 20;
  BTN_WIDTH = ((FULL_WIDTH - PAD * 2) - 10 * 2) div 3;
begin
  inherited Create;

  fOnKeysUpdated := aOnKeysUpdated;

  fTempKeys := TKMResKeys.Create;

  Form_OptionsKeys := TKMForm.Create(aParent, FULL_WIDTH, FULL_HEIGHT, gResTexts[TX_MENU_OPTIONS_KEYBIND], fbGray, False, False);
  Form_OptionsKeys.AnchorsCenter;
  Form_OptionsKeys.Left := (aParent.Width - Form_OptionsKeys.Width) div 2;
  Form_OptionsKeys.Top := (aParent.Height - Form_OptionsKeys.Height) div 2;
  Form_OptionsKeys.CapOffsetY := 20;

  Panel_Content := TKMPanel.Create(Form_OptionsKeys.ItemsPanel, PAD, 90, FULL_WIDTH - PAD * 2, FULL_HEIGHT - 70 - PAD);
  Panel_Content.AnchorsStretch;
    ColumnBox_OptionsKeys := TKMColumnBox.Create(Panel_Content, 0, 0, Panel_Content.Width, Panel_Content.Height - 80, fntMetal, bsMenu);
    ColumnBox_OptionsKeys.SetColumns(fntOutline, [gResTexts[TX_MENU_OPTIONS_FUNCTION], gResTexts[TX_MENU_OPTIONS_KEY]], [0, 350]);
    ColumnBox_OptionsKeys.AnchorsStretch;
    ColumnBox_OptionsKeys.ShowLines := True;
    ColumnBox_OptionsKeys.ShowHintWhenShort := True;
    ColumnBox_OptionsKeys.HintBackColor := TKMColor4f.New(57, 48, 50); // Dark grey
    ColumnBox_OptionsKeys.PassAllKeys := True;
    ColumnBox_OptionsKeys.OnChange := ListClick;
    ColumnBox_OptionsKeys.OnKeyUp := ListKeyUp;

    var lbl := TKMLabel.Create(Panel_Content, 0, Panel_Content.Height - 30 * 2 - 10, Panel_Content.Width, 20, '* ' + gResTexts[TX_KEY_UNASSIGNABLE], fntMetal, taLeft);
    lbl.Anchors := [anLeft, anRight, anBottom];

    Button_OptionsKeysClear := TKMButton.Create(Panel_Content, BTN_WIDTH * 2 + 10 * 2, Panel_Content.Height - 30 * 2 - 10, BTN_WIDTH, 30, gResTexts[TX_MENU_OPTIONS_CLEAR], bsMenu);
    Button_OptionsKeysClear.Anchors := [anBottom];
    Button_OptionsKeysClear.OnClick := ButtonClearClick;

    Button_OptionsKeysReset := TKMButton.Create(Panel_Content, 0, Panel_Content.Height - 30, BTN_WIDTH, 30, gResTexts[TX_MENU_OPTIONS_RESET], bsMenu);
    Button_OptionsKeysReset.Anchors := [anBottom];
    Button_OptionsKeysReset.OnClick := ButtonResetClick;

    Button_OptionsKeysOK := TKMButton.Create(Panel_Content, BTN_WIDTH + 10, Panel_Content.Height - 30, BTN_WIDTH, 30, gResTexts[TX_MENU_OPTIONS_OK], bsMenu);
    Button_OptionsKeysOK.Anchors := [anBottom];
    Button_OptionsKeysOK.OnClick := ButtonOkClick;

    Button_OptionsKeysCancel := TKMButton.Create(Panel_Content, (BTN_WIDTH + 10) * 2, Panel_Content.Height - 30, BTN_WIDTH, 30, gResTexts[TX_MENU_OPTIONS_CANCEL], bsMenu);
    Button_OptionsKeysCancel.Anchors := [anBottom];
    Button_OptionsKeysCancel.OnClick := ButtonCancelClick;
end;


destructor TKMGUICommonKeys.Destroy;
begin
  FreeAndNil(fTempKeys);

  inherited;
end;


function TKMGUICommonKeys.GetVisible: Boolean;
begin
  Result := Form_OptionsKeys.Visible;
end;


procedure TKMGUICommonKeys.Hide;
begin
  Form_OptionsKeys.Hide;

  if Assigned(OnClose) then
    OnClose();
end;


procedure TKMGUICommonKeys.ButtonOkClick(Sender: TObject);
var
  KF: TKMKeyFunction;
begin
  // Save TempKeys to gResKeys
  for KF := Low(TKMKeyFunction) to High(TKMKeyFunction) do
    gResKeys[KF] := fTempKeys[KF];

  if Assigned(fOnKeysUpdated) then
    fOnKeysUpdated;

  gResKeys.Save;

  Hide;
end;


procedure TKMGUICommonKeys.ButtonCancelClick(Sender: TObject);
begin
  Hide;
end;


procedure TKMGUICommonKeys.ButtonClearClick(Sender: TObject);
begin
  ListKeyUp(Button_OptionsKeysClear, 0, []);
end;


procedure TKMGUICommonKeys.ButtonResetClick(Sender: TObject);
begin
  fTempKeys.ResetKeymap;
  KeysRefreshList;
end;


procedure TKMGUICommonKeys.ListClick(Sender: TObject);
begin
  ColumnBox_OptionsKeys.HighlightError := False;
end;


procedure TKMGUICommonKeys.KeysRefreshList;

  function GetFunctionName(aTX_ID: Integer): String;
  begin
    case aTX_ID of
      TX_KEY_FUNC_GAME_SPEED_2: Result := Format(gResTexts[aTX_ID], [FormatFloat('##0.##', gGameSettings.SpeedMedium)]);
      TX_KEY_FUNC_GAME_SPEED_3: Result := Format(gResTexts[aTX_ID], [FormatFloat('##0.##', gGameSettings.SpeedFast)]);
      TX_KEY_FUNC_GAME_SPEED_4: Result := Format(gResTexts[aTX_ID], [FormatFloat('##0.##', gGameSettings.SpeedVeryFast)]);
    else
      Result := gResTexts[aTX_ID];
    end;
  end;

const
  KEY_TX: array [TKMKeyFuncArea] of Word = (TX_KEY_COMMON, TX_KEY_GAME, TX_KEY_UNIT, TX_KEY_HOUSE, TX_KEY_SPECTATE_REPLAY, TX_KEY_MAPEDIT);
var
  KF: TKMKeyFunction;
  prevTopIndex: Integer;
  K: TKMKeyFuncArea;
  keyName: UnicodeString;
begin
  prevTopIndex := ColumnBox_OptionsKeys.TopIndex;

  ColumnBox_OptionsKeys.Clear;

  for K := Low(TKMKeyFuncArea) to High(TKMKeyFuncArea) do
  begin
    // Section
    ColumnBox_OptionsKeys.AddItem(MakeListRow([gResTexts[KEY_TX[K]], ' '], [$FF3BB5CF, $FF3BB5CF], [$FF0000FF, $FF0000FF], -1));

    // Do not show the debug keys
    for KF := KEY_FUNC_LOW to High(TKMKeyFunction) do
      if (gResKeyFuncs[KF].Area = K) and not gResKeyFuncs[KF].IsChangableByPlayer then
      begin
        keyName := fTempKeys.GetKeyNameById(KF);
        if (KF = kfDebugWindow) and (keyName <> '') then
          keyName := keyName + ' / Ctrl + ' + keyName; //Also show Ctrl + F11, for debug window hotkey
        if (KF = kfMapedSaveMap) and (keyName <> '') then
          keyName := 'Ctrl + ' + keyName;
        ColumnBox_OptionsKeys.AddItem(MakeListRow(
          [GetFunctionName(gResKeyFuncs[KF].TextId), keyName], [$FFFFFFFF, $FFFFFFFF], [$FF0000FF, $FF0000FF], Integer(KF)));
      end;
  end;

  ColumnBox_OptionsKeys.TopIndex := prevTopIndex;
end;


function TKMGUICommonKeys.ListKeyUp(Sender: TObject; Key: Word; Shift: TShiftState): Boolean;
var
  KF: TKMKeyFunction;
begin
  Result := True; // We handle all keys here
  if ColumnBox_OptionsKeys.ItemIndex = -1 then Exit;

  ColumnBox_OptionsKeys.HighlightError := False;

  if not InRange(ColumnBox_OptionsKeys.Rows[ColumnBox_OptionsKeys.ItemIndex].Tag, 1, gResKeyFuncs.Count) then Exit;

  KF := TKMKeyFunction(ColumnBox_OptionsKeys.Rows[ColumnBox_OptionsKeys.ItemIndex].Tag);

  if not fTempKeys.AllowKeySet(Key) then
  begin
    ColumnBox_OptionsKeys.HighlightError := True;
    gSoundPlayer.Play(sfxnError);
    Exit;
  end;

  fTempKeys.SetKey(KF, Key);

  KeysRefreshList;
end;


procedure TKMGUICommonKeys.Show;
var
  KF: TKMKeyFunction;
begin
  // Reload the keymap in case player changed it and checks his changes in game
  gResKeys.Load;

  // Update TempKeys from gResKeys
  for KF := Low(TKMKeyFunction) to High(TKMKeyFunction) do
    fTempKeys[KF] := gResKeys[KF];

  KeysRefreshList;
  Form_OptionsKeys.Show;
end;


end.

