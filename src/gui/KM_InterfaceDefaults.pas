unit KM_InterfaceDefaults;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLType, {$ENDIF}
  Controls, Classes,
  KM_Controls, KM_Points, KM_ResFonts;


type
  TUIMode = (umSP, umMP, umReplay, umSpectate);
  TUIModeSet = set of TUIMode;

  TKMMenuPageType =  (gpMainMenu,
                        gpSinglePlayer,
                          gpCampaign,
                          gpCampSelect,
                          gpSingleMap,
                          gpLoad,
                        gpMultiplayer,
                          gpLobby,
                        gpReplays,
                        gpMapEditor,
                        gpOptions,
                        gpCredits,
                      gpLoading,
                      gpError);
  TGUIEvent = procedure (Sender: TObject; Dest: TKMMenuPageType) of object;
  TKMMenuChangeEventText = procedure (Dest: TKMMenuPageType; const aText: UnicodeString = '') of object;

  TKMMenuPageCommon = class
  protected
    OnKeyDown: TNotifyEventKeyShift;
    OnEscKeyDown: TNotifyEvent;
  public
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

    procedure KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean); virtual; abstract;
    procedure KeyPress(Key: Char); virtual;
    procedure KeyUp(Key: Word; Shift: TShiftState; var aHandled: Boolean); virtual; abstract;
    //Child classes don't pass these events to controls depending on their state
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer); virtual; abstract;
    procedure MouseMove(Shift: TShiftState; X,Y: Integer); overload;
    procedure MouseMove(Shift: TShiftState; X,Y: Integer; var aHandled: Boolean); overload; virtual; abstract;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X,Y: Integer); virtual; abstract;
    procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer; X,Y: Integer; var aHandled: Boolean); virtual;
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
    procedure DoExecuteSubMenuAction(aIndex: Byte); virtual;
  public
    procedure ShowSubMenu(aIndex: Byte);
    procedure ExecuteSubMenuAction(aIndex: Byte);

    function Visible: Boolean; virtual; abstract;
  end;


  TKMMapEdSubMenuPage = class
  protected
    fSubMenuActionsEvents: array[0..SUB_MENU_ACTIONS_CNT - 1] of TNotifyEvent;
    fSubMenuActionsCtrls: array[0..SUB_MENU_ACTIONS_CNT - 1] of TKMControl;
  public
    procedure ExecuteSubMenuAction(aIndex: Byte);
    function Visible: Boolean; virtual; abstract;
  end;


const
  //Options sliders
  OPT_SLIDER_MIN = 0;
  OPT_SLIDER_MAX = 20;
  MAX_SAVENAME_LENGTH = 50;

  CHAT_MENU_ALL = -1;
  CHAT_MENU_TEAM = -2;
  CHAT_MENU_SPECTATORS = -3;

  RESULTS_X_PADDING = 50;

var
  MAPED_SUBMENU_HOTKEYS: array[0..5] of Word;
  MAPED_SUBMENU_ACTIONS_HOTKEYS: array[0..SUB_MENU_ACTIONS_CNT - 1] of Word;


const
  ITEM_NOT_LOADED = -100; // smth, but not -1, as -1 is used for ColumnBox.ItemIndex, when no item is selected


implementation
uses
  KM_Resource, KM_ResKeys, KM_RenderUI;


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


procedure TKMUserInterfaceCommon.KeyPress(Key: Char);
begin
  fMyControls.KeyPress(Key);
end;


procedure TKMUserInterfaceCommon.MouseMove(Shift: TShiftState; X, Y: Integer);
var MouseMoveHandled: Boolean;
begin
  MouseMove(Shift, X, Y, MouseMoveHandled);
end;


procedure TKMUserInterfaceCommon.MouseWheel(Shift: TShiftState; WheelDelta, X, Y: Integer; var aHandled: Boolean);
begin
  fMyControls.MouseWheel(X, Y, WheelDelta, aHandled);
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
  fMyControls.Paint;
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


procedure TKMMapEdMenuPage.ExecuteSubMenuAction(aIndex: Byte);
begin
  if Visible then
    DoExecuteSubMenuAction(aIndex);
end;


procedure TKMMapEdMenuPage.DoShowSubMenu(aIndex: Byte);
begin
  //just empty stub here
end;


procedure TKMMapEdMenuPage.DoExecuteSubMenuAction(aIndex: Byte);
begin
  //just empty stub here
end;


{ TKMMapEdSubMenuPage }
procedure TKMMapEdSubMenuPage.ExecuteSubMenuAction(aIndex: Byte);
begin
  if Visible
    and Assigned(fSubMenuActionsEvents[aIndex])
    and (fSubMenuActionsCtrls[aIndex] <> nil)
    and fSubMenuActionsCtrls[aIndex].IsClickable then
  begin
    if fSubMenuActionsCtrls[aIndex] is TKMCheckBox then
      TKMCheckBox(fSubMenuActionsCtrls[aIndex]).SwitchCheck;
    fSubMenuActionsEvents[aIndex](fSubMenuActionsCtrls[aIndex]);
  end;
end;


initialization
begin
  MAPED_SUBMENU_HOTKEYS[0] := SC_MAPEDIT_SUB_MENU_1;
  MAPED_SUBMENU_HOTKEYS[1] := SC_MAPEDIT_SUB_MENU_2;
  MAPED_SUBMENU_HOTKEYS[2] := SC_MAPEDIT_SUB_MENU_3;
  MAPED_SUBMENU_HOTKEYS[3] := SC_MAPEDIT_SUB_MENU_4;
  MAPED_SUBMENU_HOTKEYS[4] := SC_MAPEDIT_SUB_MENU_5;
  MAPED_SUBMENU_HOTKEYS[5] := SC_MAPEDIT_SUB_MENU_6;

  MAPED_SUBMENU_ACTIONS_HOTKEYS[0] := SC_MAPEDIT_SUB_MENU_ACTION_1;
  MAPED_SUBMENU_ACTIONS_HOTKEYS[1] := SC_MAPEDIT_SUB_MENU_ACTION_2;
  MAPED_SUBMENU_ACTIONS_HOTKEYS[2] := SC_MAPEDIT_SUB_MENU_ACTION_3;
  MAPED_SUBMENU_ACTIONS_HOTKEYS[3] := SC_MAPEDIT_SUB_MENU_ACTION_4;
  MAPED_SUBMENU_ACTIONS_HOTKEYS[4] := SC_MAPEDIT_SUB_MENU_ACTION_5;
  MAPED_SUBMENU_ACTIONS_HOTKEYS[5] := SC_MAPEDIT_SUB_MENU_ACTION_6;
  MAPED_SUBMENU_ACTIONS_HOTKEYS[6] := SC_MAPEDIT_SUB_MENU_ACTION_7;
end;


end.
