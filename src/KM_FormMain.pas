unit KM_FormMain;
{$I KaM_Remake.inc}
interface
uses
  Classes, ComCtrls, Controls, Buttons, Dialogs, ExtCtrls, Forms, Graphics, Math, Menus, StdCtrls, SysUtils, StrUtils,
  KM_RenderControl, KM_Settings,
  KM_GameTypes,
  {$IFDEF FPC} LResources, {$ENDIF}
  {$IFDEF MSWindows} ShellAPI, Windows, Messages; {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType; {$ENDIF}


type

  { TFormMain }

  TFormMain = class(TForm)
    chkAIEye: TCheckBox;
    chkLogGameTick: TCheckBox;
    MenuItem1: TMenuItem;
    SaveEditableMission1: TMenuItem;
    N2: TMenuItem;
    OpenDialog1: TOpenDialog;
    StatusBar1: TStatusBar;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Exit1: TMenuItem;
    N1: TMenuItem;
    About1: TMenuItem;
    Debug1: TMenuItem;
    Debug_PrintScreen: TMenuItem;
    Export1: TMenuItem;
    Export_GUIRX: TMenuItem;
    Export_TreesRX: TMenuItem;
    Export_HousesRX: TMenuItem;
    Export_UnitsRX: TMenuItem;
    Export_GUIMainRX: TMenuItem;
    Export_Custom: TMenuItem;
    Export_Tileset: TMenuItem;
    Export_Fonts1: TMenuItem;
    GroupBox1: TGroupBox;
    chkSuperSpeed: TCheckBox;
    Export_Deliverlists1: TMenuItem;
    Export_Sounds1: TMenuItem;
    Export_HouseAnim1: TMenuItem;
    Export_UnitAnim1: TMenuItem;
    RGPlayer: TRadioGroup;
    Button_Stop: TButton;
    OpenMissionMenu: TMenuItem;
    AnimData1: TMenuItem;
    Other1: TMenuItem;
    Debug_ShowPanel: TMenuItem;
    Export_TreeAnim1: TMenuItem;
    ExportMainMenu: TMenuItem;
    Debug_EnableCheats: TMenuItem;
    ExportUIPages: TMenuItem;
    Resources1: TMenuItem;
    HousesDat1: TMenuItem;
    GroupBox2: TGroupBox;
    chkShowOwnership: TCheckBox;
    chkShowNavMesh: TCheckBox;
    chkShowAvoid: TCheckBox;
    chkShowBalance: TCheckBox;
    tbOwnMargin: TTrackBar;
    tbOwnThresh: TTrackBar;
    Label5: TLabel;
    Label6: TLabel;
    chkShowDefences: TCheckBox;
    chkBuildAI: TCheckBox;
    chkCombatAI: TCheckBox;
    ResourceValues1: TMenuItem;
    GroupBox3: TGroupBox;
    chkUIControlsBounds: TCheckBox;
    chkUITextBounds: TCheckBox;
    GroupBox4: TGroupBox;
    tbAngleX: TTrackBar;
    tbAngleY: TTrackBar;
    Label3: TLabel;
    Label4: TLabel;
    tbBuildingStep: TTrackBar;
    Label1: TLabel;
    GroupBox5: TGroupBox;
    tbPassability: TTrackBar;
    Label2: TLabel;
    chkShowRoutes: TCheckBox;
    chkShowWires: TCheckBox;
    tbAngleZ: TTrackBar;
    Label7: TLabel;
    chkSelectionBuffer: TCheckBox;
    GroupBoxLogs: TGroupBox;
    chkLogDelivery: TCheckBox;
    chkLogNetConnection: TCheckBox;
    RGLogNetPackets: TRadioGroup;
    chkLogsShowInChat: TCheckBox;
    chkUIControlsID: TCheckBox;
    ShowLogistics: TMenuItem;
    chkShowTerrainIds: TCheckBox;
    chkShowTerrainKinds: TCheckBox;
    UnitAnim_All: TMenuItem;
    N3: TMenuItem;
    Soldiers: TMenuItem;
    Civilians1: TMenuItem;
    SaveSettings: TMenuItem;
    N4: TMenuItem;
    ReloadSettings: TMenuItem;
    SaveDialog1: TSaveDialog;
    chkLogCommands: TCheckBox;
    ScriptData1: TMenuItem;
    chkBevel: TCheckBox;
    chkTilesGrid: TCheckBox;
    N6: TMenuItem;
    GameStats: TMenuItem;
    ExportGameStats: TMenuItem;
    ValidateGameStats: TMenuItem;
    chkLogRngChecks: TCheckBox;
    chkShowGameTick: TCheckBox;
    chkSkipRender: TCheckBox;
    chkSkipSound: TCheckBox;
    chkUIDs: TCheckBox;
    chkShowSoil: TCheckBox;
    chkShowFlatArea: TCheckBox;
    chkShowEyeRoutes: TCheckBox;
    chkSelectedObjInfo: TCheckBox;
    chkShowFPS: TCheckBox;
    procedure Export_TreeAnim1Click(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Debug_ExportMenuClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure Debug_EnableCheatsClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure AboutClick(Sender: TObject);
    procedure ExitClick(Sender: TObject);
    procedure Debug_PrintScreenClick(Sender: TObject);
    procedure Export_TreesRXClick(Sender: TObject);
    procedure Export_HousesRXClick(Sender: TObject);
    procedure Export_UnitsRXClick(Sender: TObject);
    procedure Export_ScriptDataClick(Sender: TObject);
    procedure Export_GUIClick(Sender: TObject);
    procedure Export_GUIMainRXClick(Sender: TObject);
    procedure Export_CustomClick(Sender: TObject);
    procedure Export_TilesetClick(Sender: TObject);
    procedure Export_Sounds1Click(Sender: TObject);
    procedure Export_HouseAnim1Click(Sender: TObject);
    procedure Export_Fonts1Click(Sender: TObject);
    procedure Export_DeliverLists1Click(Sender: TObject);
    procedure Button_StopClick(Sender: TObject);
    procedure RGPlayerClick(Sender: TObject);
    procedure Open_MissionMenuClick(Sender: TObject);
    procedure chkSuperSpeedClick(Sender: TObject);
    procedure Debug_ShowPanelClick(Sender: TObject);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure Debug_ExportUIPagesClick(Sender: TObject);
    procedure HousesDat1Click(Sender: TObject);
    procedure ExportGameStatsClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ResourceValues1Click(Sender: TObject);
    procedure ControlsUpdate(Sender: TObject);

    procedure RenderAreaMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure RenderAreaMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
    procedure RenderAreaMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure RenderAreaMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure RenderAreaResize(aWidth, aHeight: Integer);
    procedure RenderAreaRender(aSender: TObject);
    procedure ShowLogisticsClick(Sender: TObject);
    procedure UnitAnim_AllClick(Sender: TObject);
    procedure SoldiersClick(Sender: TObject);
    procedure Civilians1Click(Sender: TObject);
    procedure ReloadSettingsClick(Sender: TObject);
    procedure SaveSettingsClick(Sender: TObject);
    procedure SaveEditableMission1Click(Sender: TObject);
    procedure ValidateGameStatsClick(Sender: TObject);
  private
    fUpdating: Boolean;
    fMissionDefOpenPath: UnicodeString;
    procedure FormKeyDownProc(aKey: Word; aShift: TShiftState);
    procedure FormKeyUpProc(aKey: Word; aShift: TShiftState);
    function ConfirmExport: Boolean;
    {$IFDEF MSWindows}
    function GetWindowParams: TKMWindowParamsRecord;
    procedure WMSysCommand(var Msg: TWMSysCommand); message WM_SYSCOMMAND;
    procedure WMExitSizeMove(var Msg: TMessage) ; message WM_EXITSIZEMOVE;
    procedure WMAppCommand(var Msg: TMessage); message WM_APPCOMMAND;
  protected
    procedure WndProc(var Message : TMessage); override;
    {$ENDIF}
  public
    RenderArea: TKMRenderControl;
    SuppressAltForMenu: Boolean; //Suppress Alt key 'activate window menu' function
    procedure ControlsSetVisibile(aShowCtrls, aShowGroupBox: Boolean); overload;
    procedure ControlsSetVisibile(aShowCtrls: Boolean); overload;
    procedure ControlsReset;
    procedure ControlsRefill;
    procedure ToggleFullscreen(aFullscreen, aWindowDefaultParams: Boolean);
    procedure SetSaveEditableMission(aEnabled: Boolean);
    procedure SetExportGameStats(aEnabled: Boolean);
  end;


implementation
//{$IFDEF WDC}
  {$R *.dfm}
//{$ENDIF}

uses
  {$IFDEF WDC} UITypes, {$ENDIF}
  KromUtils,
  KromShellUtils,
  KM_Defaults,
  KM_Main,
  //Use these units directly to avoid pass-through methods in fMain
  KM_Resource,
  KM_ResSprites,
  KM_ResTexts,
  KM_GameApp,
  KM_HandsCollection,
  KM_ResSound,
  KM_Pics,
  KM_RenderPool,
  KM_Hand,
  KM_ResKeys, KM_FormLogistics, KM_Game,
  KM_Log, KM_CommonClasses;


//Remove VCL panel and use flicker-free TMyPanel instead
procedure TFormMain.FormCreate(Sender: TObject);
begin
  RenderArea := TKMRenderControl.Create(Self);
  RenderArea.Parent := Self;
  RenderArea.Align := alClient;
  RenderArea.Color := clMaroon;
  RenderArea.OnMouseDown := RenderAreaMouseDown;
  RenderArea.OnMouseMove := RenderAreaMouseMove;
  RenderArea.OnMouseUp := RenderAreaMouseUp;
  RenderArea.OnResize := RenderAreaResize;
  RenderArea.OnRender := RenderAreaRender;
  SuppressAltForMenu := False;

  chkSuperSpeed.Caption := 'Speed x' + IntToStr(DEBUG_SPEEDUP_SPEED);

  //Lazarus needs OnMouseWheel event to be for the panel, not the entire form
  {$IFDEF FPC} RenderArea.OnMouseWheel := RenderAreaMouseWheel; {$ENDIF}

  {$IFDEF MSWindows}
    //Means it will receive WM_SIZE WM_PAINT always in pair (if False - WM_PAINT is not called if size becames smaller)
    RenderArea.FullRepaint := True;
    RenderArea.BevelOuter := bvNone;
  {$ENDIF}

  //Put debug panel on top
  RenderArea.SendToBack;
  GroupBox1.BringToFront;
end;

procedure TFormMain.FormShow(Sender: TObject);
var BordersWidth, BordersHeight: Integer;
begin
  //We do this in OnShow rather than OnCreate as the window borders aren't
  //counted properly in OnCreate
  BordersWidth := Width - ClientWidth;
  BordersHeight := Height - ClientHeight;
  //Constraints includes window borders, so we add them on as Margin
  Constraints.MinWidth := MIN_RESOLUTION_WIDTH + BordersWidth;
  Constraints.MinHeight := MIN_RESOLUTION_HEIGHT + BordersHeight;

  // We have to put it here, to proper window positioning for multimonitor systems
  if not gMain.Settings.FullScreen then
  begin
    Left := gMain.Settings.WindowParams.Left;
    Top := gMain.Settings.WindowParams.Top;
  end;

  fMissionDefOpenPath := ExeDir;
end;


procedure TFormMain.SetSaveEditableMission(aEnabled: Boolean);
begin
  SaveEditableMission1.Enabled := aEnabled;
end;


procedure TFormMain.SetExportGameStats(aEnabled: Boolean);
begin
  ExportGameStats.Enabled := aEnabled;
end;


procedure TFormMain.FormKeyDownProc(aKey: Word; aShift: TShiftState);
begin
  if gGameApp <> nil then gGameApp.KeyDown(aKey, aShift);
end;


procedure TFormMain.FormKeyUpProc(aKey: Word; aShift: TShiftState);
begin
  if aKey = gResKeys[SC_DEBUG_WINDOW].Key then
  begin
    SHOW_DEBUG_CONTROLS := not SHOW_DEBUG_CONTROLS;
    ControlsSetVisibile(SHOW_DEBUG_CONTROLS, not (ssCtrl in aShift)); //Hide groupbox when Ctrl is pressed
  end;

  if gGameApp <> nil then gGameApp.KeyUp(aKey, aShift);
end;


procedure TFormMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  Assert(KeyPreview, 'MainForm should recieve all keys to pass them to fGame');
  FormKeyDownProc(Key, Shift);
end;


procedure TFormMain.FormKeyPress(Sender: TObject; var Key: Char);
begin
  Assert(KeyPreview, 'MainForm should recieve all keys to pass them to fGame');
  if gGameApp <> nil then gGameApp.KeyPress(Key);
end;


procedure TFormMain.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  Assert(KeyPreview, 'MainForm should recieve all keys to pass them to fGame');

  FormKeyUpProc(Key, Shift);
end;


procedure TFormMain.ReloadSettingsClick(Sender: TObject);
begin
  gMain.Settings.ReloadSettings;
  gGameApp.GameSettings.ReloadSettings;
end;


procedure TFormMain.RenderAreaMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  // Handle middle mouse button as Key
  if Button = mbMiddle then
    FormKeyDownProc(VK_MBUTTON, Shift)
  else if gGameApp <> nil then
    gGameApp.MouseDown(Button, Shift, X, Y);
end;


procedure TFormMain.RenderAreaMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
begin
  if gGameApp <> nil then gGameApp.MouseMove(Shift, X, Y);
end;


procedure TFormMain.RenderAreaMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if gGameApp <> nil then
  begin
    //Somehow Shift state does not contain mouse buttons ssLeft/ssRight/ssMiddle
    if Button = mbLeft then
      Include(Shift, ssLeft)
    else if Button = mbRight then
      Include(Shift, ssRight)
    else if Button = mbMiddle then
      Include(Shift, ssMiddle);

    // Handle middle mouse button as Key
    if Button = mbMiddle then
      FormKeyUpProc(VK_MBUTTON, Shift)
    else
      gGameApp.MouseUp(Button, Shift, X, Y);
  end;
end;


procedure TFormMain.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  if gGameApp <> nil then
    gGameApp.MouseWheel(Shift, WheelDelta, RenderArea.ScreenToClient(MousePos).X, RenderArea.ScreenToClient(MousePos).Y);
end;


procedure TFormMain.RenderAreaMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  if gGameApp <> nil then
    gGameApp.MouseWheel(Shift, WheelDelta, MousePos.X, MousePos.Y);
end;


procedure TFormMain.RenderAreaResize(aWidth, aHeight: Integer);
begin
  gMain.Resize(aWidth, aHeight, GetWindowParams);
end;


procedure TFormMain.RenderAreaRender(aSender: TObject);
begin
  gMain.Render;
end;


//Open
procedure TFormMain.Open_MissionMenuClick(Sender: TObject);
begin
  if RunOpenDialog(OpenDialog1, '', fMissionDefOpenPath, 'Knights & Merchants Mission (*.dat)|*.dat') then
  begin
    gGameApp.NewSingleMap(OpenDialog1.FileName, TruncateExt(ExtractFileName(OpenDialog1.FileName)));
    fMissionDefOpenPath := ExtractFileDir(OpenDialog1.FileName);
  end;
end;


procedure TFormMain.MenuItem1Click(Sender: TObject);
begin
  if RunOpenDialog(OpenDialog1, '', fMissionDefOpenPath, 'Knights & Merchants Mission (*.dat)|*.dat') then
  begin
    gGameApp.NewMapEditor(OpenDialog1.FileName);
    fMissionDefOpenPath := ExtractFileDir(OpenDialog1.FileName);
  end;
end;


procedure TFormMain.SaveEditableMission1Click(Sender: TObject);
begin
  if gGameApp.Game = nil then Exit;

  if not gGameApp.Game.IsMapEditor then Exit;

  if RunSaveDialog(SaveDialog1, gGameApp.Game.MapEditor.MissionDefSavePath, ExtractFileDir(gGameApp.Game.MapEditor.MissionDefSavePath), 'Knights & Merchants Mission (*.dat)|*.dat') then
    gGameApp.SaveMapEditor(SaveDialog1.FileName);
end;


//Exit
procedure TFormMain.ExitClick(Sender: TObject);
begin
  Close;
end;


//About
procedure TFormMain.AboutClick(Sender: TObject);
begin
  gMain.ShowAbout;
end;


//Debug Options
procedure TFormMain.Debug_EnableCheatsClick(Sender: TObject);
begin
  Debug_EnableCheats.Checked := not Debug_EnableCheats.Checked;
  DEBUG_CHEATS := Debug_EnableCheats.Checked;
end;


procedure TFormMain.Debug_PrintScreenClick(Sender: TObject);
begin
  if gGameApp <> nil then
    gGameApp.PrintScreen;
end;


procedure TFormMain.Debug_ShowPanelClick(Sender: TObject);
begin
  GroupBox1.Visible := not GroupBox1.Visible;
end;


//Exports
procedure TFormMain.Export_TreesRXClick(Sender: TObject);
begin
  if ConfirmExport then
    gRes.Sprites.ExportToPNG(rxTrees);
end;

procedure TFormMain.Export_HousesRXClick(Sender: TObject);
begin
  if ConfirmExport then
    gRes.Sprites.ExportToPNG(rxHouses);
end;

procedure TFormMain.Export_UnitsRXClick(Sender: TObject);
begin
  if ConfirmExport then
    gRes.Sprites.ExportToPNG(rxUnits);
end;

procedure TFormMain.Export_ScriptDataClick(Sender: TObject);
begin
  if (gGame <> nil)
    and (gGame.Scripting <> nil) then
    gGame.Scripting.ExportDataToText;
end;

procedure TFormMain.Export_GUIClick(Sender: TObject);
begin
  if ConfirmExport then
    gRes.Sprites.ExportToPNG(rxGUI);
end;

procedure TFormMain.Export_GUIMainRXClick(Sender: TObject);
begin
  if ConfirmExport then
    gRes.Sprites.ExportToPNG(rxGUIMain);
end;

procedure TFormMain.Export_CustomClick(Sender: TObject);
begin
  gRes.Sprites.ExportToPNG(rxCustom);
end;

procedure TFormMain.Export_TilesetClick(Sender: TObject);
begin
  gRes.Sprites.ExportToPNG(rxTiles);
end;

procedure TFormMain.Export_Sounds1Click(Sender: TObject);
begin
  gRes.Sounds.ExportSounds;
end;

procedure TFormMain.Export_TreeAnim1Click(Sender: TObject);
begin
  if ConfirmExport then
    gRes.ExportTreeAnim;
end;

procedure TFormMain.Export_HouseAnim1Click(Sender: TObject);
begin
  if ConfirmExport then
    gRes.ExportHouseAnim;
end;


procedure TFormMain.HousesDat1Click(Sender: TObject);
begin
  gRes.Houses.ExportCSV(ExeDir + 'Export' + PathDelim + 'houses.dat.csv')
end;


procedure TFormMain.ExportGameStatsClick(Sender: TObject);
var
  DateS: UnicodeString;
begin
  if (gGame <> nil) and not gGame.IsMapEditor then
  begin
    DateS := FormatDateTime('yyyy-mm-dd_hh-nn', Now);
    gHands.ExportGameStatsToCSV(ExeDir + 'Export' + PathDelim + gGame.GameName + '_' + DateS + '.csv',
                            Format('Statistics for game at map ''%s'' on %s', [gGame.GameName, DateS]));
  end;
end;


procedure TFormMain.Export_Fonts1Click(Sender: TObject);
begin
  Assert(gRes <> nil, 'Can''t export Fonts cos they aren''t loaded yet');
  gRes.Fonts.ExportFonts;
end;


procedure TFormMain.Export_DeliverLists1Click(Sender: TObject);
var I: Integer;
begin
  if gHands = nil then Exit;
  //You could possibly cheat in multiplayer by seeing what supplies your enemy has
  if (gGameApp.Game <> nil) and (not gGameApp.Game.IsMultiPlayerOrSpec or MULTIPLAYER_CHEATS) then
  for I := 0 to gHands.Count - 1 do
    gHands[I].Deliveries.Queue.ExportToFile(ExeDir + 'Player_' + IntToStr(I) + '_Deliver_List.txt');
end;


procedure TFormMain.RGPlayerClick(Sender: TObject);
begin
  if (gGameApp.Game = nil)
    or gGameApp.Game.IsMapEditor
    or gGameApp.Game.IsMultiPlayerOrSpec then
    Exit;

  if (gHands <> nil) and (RGPlayer.ItemIndex < gHands.Count) then
    gMySpectator.HandID := RGPlayer.ItemIndex;
end;


procedure TFormMain.SaveSettingsClick(Sender: TObject);
begin
  gMain.Settings.SaveSettings(True);
  gGameApp.GameSettings.SaveSettings(True);
end;


procedure TFormMain.ShowLogisticsClick(Sender: TObject);
begin
  if not Assigned(FormLogistics) then
    FormLogistics := TFormLogistics.Create(Self);
  FormLogistics.Show;
end;


procedure TFormMain.SoldiersClick(Sender: TObject);
begin
  if ConfirmExport then
    gRes.ExportUnitAnim(WARRIOR_MIN, WARRIOR_MAX);
end;


procedure TFormMain.chkSuperSpeedClick(Sender: TObject);
begin
  if (gGameApp.Game = nil)
    or (gGameApp.Game.IsMultiPlayerOrSpec
      and not gGameApp.Game.IsMPGameSpeedChangeAllowed
      and not MULTIPLAYER_SPEEDUP
      and not gGameApp.Game.IsReplay) then
    Exit;

  gGameApp.Game.SetGameSpeed(IfThen(chkSuperSpeed.Checked, DEBUG_SPEEDUP_SPEED, gGameApp.Game.GetNormalGameSpeed), False);

  ActiveControl := nil; //Do not allow to focus on anything on debug panel
end;


procedure TFormMain.Button_StopClick(Sender: TObject);
begin
  if gGameApp.Game <> nil then
    if gGameApp.Game.IsMapEditor then
      gGameApp.StopGame(grMapEdEnd)
    else
      gGameApp.StopGame(grCancel);

  ActiveControl := nil; //Do not allow to focus on anything on debug panel
end;


procedure TFormMain.Civilians1Click(Sender: TObject);
begin
  if ConfirmExport then
    gRes.ExportUnitAnim(CITIZEN_MIN, CITIZEN_MAX);
end;


//Revert all controls to defaults (e.g. before MP session)
procedure TFormMain.ControlsReset;
  procedure ResetGroupBox(aBox: TGroupBox);
  var
    I: Integer;
  begin
    for I := 0 to aBox.ControlCount - 1 do
      if aBox.Controls[I] is TCheckBox then
        TCheckBox(aBox.Controls[I]).Checked :=    (aBox.Controls[I] = chkBevel)
                                               or (aBox.Controls[I] = chkLogNetConnection)
      else
      if aBox.Controls[I] is TTrackBar then
        TTrackBar(aBox.Controls[I]).Position := 0
      else
      if aBox.Controls[I] is TRadioGroup then
        TRadioGroup(aBox.Controls[I]).ItemIndex := 0
      else
      if (aBox.Controls[I] is TGroupBox) then
        ResetGroupBox(TGroupBox(aBox.Controls[I]));
  end;
begin
  if not RESET_DEBUG_CONTROLS then
    Exit;

  fUpdating := True;
  ResetGroupBox(GroupBox1);

  tbOwnMargin.Position := OWN_MARGIN_DEF;
  tbOwnThresh.Position := OWN_THRESHOLD_DEF;

  fUpdating := False;

  if Assigned(FormLogistics) then
    FormLogistics.Clear;

  ControlsUpdate(nil);
end;


procedure TFormMain.ControlsRefill;
begin
  if (gGame = nil) or not gGame.IsMapEditor then Exit;

  tbPassability.Max := Byte(High(TKMTerrainPassability));
  tbPassability.Position := SHOW_TERRAIN_PASS;
  Label2.Caption := IfThen(SHOW_TERRAIN_PASS <> 0, PassabilityGuiText[TKMTerrainPassability(SHOW_TERRAIN_PASS)], '');
  chkShowWires.Checked := SHOW_TERRAIN_WIRES;
  chkShowTerrainIds.Checked := SHOW_TERRAIN_IDS;
  chkShowTerrainKinds.Checked := SHOW_TERRAIN_KINDS;
  chkTilesGrid.Checked := SHOW_TERRAIN_TILES_GRID;
  chkShowRoutes.Checked := SHOW_UNIT_ROUTES;
  chkSelectionBuffer.Checked := SHOW_SEL_BUFFER;
end;


procedure TFormMain.ControlsSetVisibile(aShowCtrls: Boolean);
begin
  ControlsSetVisibile(aShowCtrls, aShowCtrls);
end;


procedure TFormMain.ControlsSetVisibile(aShowCtrls, aShowGroupBox: Boolean);
var
  I: Integer;
begin
  Refresh;

  GroupBox1.Visible  := aShowGroupBox and aShowCtrls;
  StatusBar1.Visible := aShowCtrls;

  //For some reason cycling Form.Menu fixes the black bar appearing under the menu upon making it visible.
  //This is a better workaround than ClientHeight = +20 because it works on Lazarus and high DPI where Menu.Height <> 20.
  Menu := nil;
  if aShowCtrls then Menu := MainMenu1;

  GroupBox1.Enabled  := aShowGroupBox and aShowCtrls;
  StatusBar1.Enabled := aShowCtrls;
  for I := 0 to MainMenu1.Items.Count - 1 do
    MainMenu1.Items[I].Enabled := aShowCtrls;

  Refresh;

  RenderArea.Top    := 0;
  RenderArea.Height := ClientHeight;
  RenderArea.Width  := ClientWidth;
  gMain.Resize(RenderArea.Width, RenderArea.Height, GetWindowParams);
end;


procedure TFormMain.ControlsUpdate(Sender: TObject);
var
  I: Integer;
  AllowDebugChange: Boolean;
begin
  if fUpdating then Exit;

  //You could possibly cheat in multiplayer by seeing debug render info
  AllowDebugChange := gMain.IsDebugChangeAllowed
                      or (Sender = nil); //Happens in ControlsReset only (using this anywhere else could allow MP cheating)

  //Debug render
  if AllowDebugChange then
  begin
    I := tbPassability.Position;
    tbPassability.Max := Byte(High(TKMTerrainPassability));
    Label2.Caption := IfThen(I <> 0, PassabilityGuiText[TKMTerrainPassability(I)], '');
    SHOW_TERRAIN_PASS := I;
    SHOW_TERRAIN_WIRES := chkShowWires.Checked;
    SHOW_TERRAIN_IDS := chkShowTerrainIds.Checked;
    SHOW_TERRAIN_KINDS := chkShowTerrainKinds.Checked;
    SHOW_TERRAIN_TILES_GRID := chkTilesGrid.Checked;
    SHOW_UNIT_ROUTES := chkShowRoutes.Checked;
    SHOW_SEL_BUFFER := chkSelectionBuffer.Checked;
    SHOW_GAME_TICK := chkShowGameTick.Checked;
    SHOW_FPS := chkShowFPS.Checked;
    SHOW_UIDs := chkUIDs.Checked;
    SHOW_SELECTED_OBJ_INFO := chkSelectedObjInfo.Checked;

    SKIP_RENDER := chkSkipRender.Checked;
    SKIP_SOUND := chkSkipSound.Checked;
  end;

  //AI
  if AllowDebugChange then
  begin
    SHOW_AI_WARE_BALANCE := chkShowBalance.Checked;
    SHOW_DEBUG_OVERLAY_BEVEL := chkBevel.Checked;
    OVERLAY_DEFENCES := chkShowDefences.Checked;
    OVERLAY_AI_BUILD := chkBuildAI.Checked;
    OVERLAY_AI_COMBAT := chkCombatAI.Checked;
    OVERLAY_AI_EYE := chkAIEye.Checked;
    OVERLAY_AI_SOIL := chkShowSoil.Checked;
    OVERLAY_AI_FLATAREA := chkShowFlatArea.Checked;
    OVERLAY_AI_ROUTES := chkShowEyeRoutes.Checked;
    OVERLAY_AVOID := chkShowAvoid.Checked;
    OVERLAY_OWNERSHIP := chkShowOwnership.Checked;
    OVERLAY_NAVMESH := chkShowNavMesh.Checked;

    OWN_MARGIN := tbOwnMargin.Position;
    tbOwnThresh.Max := OWN_MARGIN;
    OWN_THRESHOLD := tbOwnThresh.Position;
  end;

  //UI
  SHOW_CONTROLS_OVERLAY := chkUIControlsBounds.Checked;
  SHOW_TEXT_OUTLINES := chkUITextBounds.Checked;
  SHOW_CONTROLS_ID := chkUIControlsID.Checked;

  //Graphics
  if AllowDebugChange then
  begin
    //Otherwise it could crash on the main menu
    if gRenderPool <> nil then
    begin
      RENDER_3D := False;//tbAngleX.Position + tbAngleY.Position <> 0;
      Label3.Caption := 'AngleX ' + IntToStr(tbAngleX.Position);
      Label4.Caption := 'AngleY ' + IntToStr(tbAngleY.Position);
      Label7.Caption := 'AngleZ ' + IntToStr(tbAngleZ.Position);
      gRenderPool.SetRotation(-tbAngleX.Position, -tbAngleZ.Position, -tbAngleY.Position);
      gMain.Render;
    end;
    HOUSE_BUILDING_STEP := tbBuildingStep.Position / tbBuildingStep.Max;
  end;

  //Logs
  SHOW_LOGS_IN_CHAT := chkLogsShowInChat.Checked;
  LOG_GAME_TICK := chkLogGameTick.Checked;

  if AllowDebugChange then
  begin
    if chkLogDelivery.Checked then
      Include(gLog.MessageTypes, lmtDelivery)
    else
      Exclude(gLog.MessageTypes, lmtDelivery);

    if chkLogCommands.Checked then
      Include(gLog.MessageTypes, lmtCommands)
    else
      Exclude(gLog.MessageTypes, lmtCommands);

    if chkLogRngChecks.Checked then
      Include(gLog.MessageTypes, lmtRandomChecks)
    else
      Exclude(gLog.MessageTypes, lmtRandomChecks);

    if chkLogNetConnection.Checked then
      Include(gLog.MessageTypes, lmtNetConnection)
    else
      Exclude(gLog.MessageTypes, lmtNetConnection);

    case RGLogNetPackets.ItemIndex of
      0:    begin
              Exclude(gLog.MessageTypes, lmtNetPacketOther);
              Exclude(gLog.MessageTypes, lmtNetPacketCommand);
              Exclude(gLog.MessageTypes, lmtNetPacketPingFps);
            end;
      1:    begin
              Include(gLog.MessageTypes, lmtNetPacketOther);
              Exclude(gLog.MessageTypes, lmtNetPacketCommand);
              Exclude(gLog.MessageTypes, lmtNetPacketPingFps);
            end;
      2:    begin
              Include(gLog.MessageTypes, lmtNetPacketOther);
              Include(gLog.MessageTypes, lmtNetPacketCommand);
              Exclude(gLog.MessageTypes, lmtNetPacketPingFps);
            end;
      3:    begin
              Include(gLog.MessageTypes, lmtNetPacketOther);
              Include(gLog.MessageTypes, lmtNetPacketCommand);
              Include(gLog.MessageTypes, lmtNetPacketPingFps);
            end;
      else  raise Exception.Create('Unexpected RGLogNetPackets.ItemIndex = ' + IntToStr(RGLogNetPackets.ItemIndex));
    end;
  end;

  ActiveControl := nil; //Do not allow to focus on anything on debug panel
end;


procedure TFormMain.ToggleFullscreen(aFullscreen, aWindowDefaultParams: Boolean);
begin
  if aFullScreen then begin
    Show; //Make sure the form is shown (e.g. on game creation), otherwise it won't wsMaximize
    BorderStyle  := bsSizeable; //if we don't set Form1 sizeable it won't maximize
    WindowState  := wsNormal;
    WindowState  := wsMaximized;
    BorderStyle  := bsNone;     //and now we can make it borderless again
  end else begin
    BorderStyle  := bsSizeable;
    WindowState  := wsNormal;
    if (aWindowDefaultParams) then
    begin
      Position := poScreenCenter;
      ClientWidth  := MENU_DESIGN_X;
      ClientHeight := MENU_DESIGN_Y;
      // We've set default window params, so update them
      gMain.UpdateWindowParams(GetWindowParams);
      // Unset NeedResetToDefaults flag
      gMain.Settings.WindowParams.NeedResetToDefaults := False;
    end else begin
      // Here we set window Width/Height and State
      // Left and Top will set on FormShow, so omit setting them here
      Position := poDesigned;
      ClientWidth  := gMain.Settings.WindowParams.Width;
      ClientHeight := gMain.Settings.WindowParams.Height;
      Left := gMain.Settings.WindowParams.Left;
      Top := gMain.Settings.WindowParams.Top;
      WindowState  := gMain.Settings.WindowParams.State;
    end;
  end;

  //Make sure Panel is properly aligned
  RenderArea.Align := alClient;
end;


procedure TFormMain.UnitAnim_AllClick(Sender: TObject);
begin
  if ConfirmExport then
    gRes.ExportUnitAnim(UNIT_MIN, UNIT_MAX, True);
end;


function TFormMain.ConfirmExport: Boolean;
begin
  case MessageDlg(Format(gResTexts[TX_FORM_EXPORT_CONFIRM_MSG], [ExeDir + 'Export']), mtWarning, [mbYes, mbNo], 0) of
    mrYes:  Result := True;
    else    Result := False;
  end;
end;


procedure TFormMain.ValidateGameStatsClick(Sender: TObject);
var
  MS: TKMemoryStream;
  SL: TStringList;
  CRC: Int64;
  IsValid: Boolean;
begin
  if RunOpenDialog(OpenDialog1, '', ExeDir, 'KaM Remake statistics (*.csv)|*.csv') then
  begin
    IsValid := False;
    SL := TStringList.Create;
    try
      try
        SL.LoadFromFile(OpenDialog1.FileName);
        if TryStrToInt64(SL[0], CRC) then
        begin
          SL.Delete(0); //Delete CRC from file
          MS := TKMemoryStream.Create;
          try
            MS.WriteHugeString(SL.Text);
            if CRC = Adler32CRC(MS) then
              IsValid := True;
          finally
            FreeAndNil(MS);
          end;
        end;

        if IsValid then
          MessageDlg('Game statistics from file [ ' + OpenDialog1.FileName + ' ] is valid', mtInformation , [mbOK ], 0)
        else
          MessageDlg('Game statistics from file [ ' + OpenDialog1.FileName + ' ] is NOT valid !', mtError, [mbClose], 0);

      except
        on E: Exception do
          MessageDlg('Error while validating game statistics from file [ ' + OpenDialog1.FileName + ' ] :' + EolW
                     + E.Message, mtError, [mbClose], 0);
      end;
    finally
      FreeAndNil(SL);
    end;
  end;
end;


// Return current window params
function TFormMain.GetWindowParams: TKMWindowParamsRecord;
  // FindTaskBar returns the Task Bar's position, and fills in
  // ARect with the current bounding rectangle.
  function FindTaskBar(var aRect: TRect): Integer;
  {$IFDEF MSWINDOWS}
  var	AppData: TAppBarData;
  {$ENDIF}
  begin
    Result := -1;
    {$IFDEF MSWINDOWS}
    // 'Shell_TrayWnd' is the name of the task bar's window
    AppData.Hwnd := FindWindow('Shell_TrayWnd', nil);
    if AppData.Hwnd <> 0 then
    begin
      AppData.cbSize := SizeOf(TAppBarData);
      // SHAppBarMessage will return False (0) when an error happens.
      if SHAppBarMessage(ABM_GETTASKBARPOS,
        {$IFDEF FPC}@AppData{$ENDIF}
        {$IFDEF WDC}AppData{$ENDIF}
        ) <> 0 then
      begin
        Result := AppData.uEdge;
        aRect := AppData.rc;
      end;
    end;
    {$ENDIF}
  end;
var
  Wp: TWindowPlacement;
  BordersWidth, BordersHeight: SmallInt;
  Rect: TRect;
begin
  Result.State := WindowState;
  case WindowState of
    wsMinimized:  ;
    wsNormal:     begin
                    Result.Width := ClientWidth;
                    Result.Height := ClientHeight;
                    Result.Left := Left;
                    Result.Top := Top;
                  end;
    wsMaximized:  begin
                    Wp.length := SizeOf(TWindowPlacement);
                    GetWindowPlacement(Handle, @Wp);

                    // Get current borders width/height
                    BordersWidth := Width - ClientWidth;
                    BordersHeight := Height - ClientHeight;

                    // rcNormalPosition do not have ClientWidth/ClientHeight
                    // so we have to calc it manually via substracting borders width/height
                    Result.Width := Wp.rcNormalPosition.Right - Wp.rcNormalPosition.Left - BordersWidth;
                    Result.Height := Wp.rcNormalPosition.Bottom - Wp.rcNormalPosition.Top - BordersHeight;

                    // Adjustment of window position due to TaskBar position/size
                    case FindTaskBar(Rect) of
                      ABE_LEFT: begin
                                  Result.Left := Wp.rcNormalPosition.Left + Rect.Right;
                                  Result.Top := Wp.rcNormalPosition.Top;
                                end;
                      ABE_TOP:  begin
                                  Result.Left := Wp.rcNormalPosition.Left;
                                  Result.Top := Wp.rcNormalPosition.Top + Rect.Bottom;
                                end
                      else      begin
                                  Result.Left := Wp.rcNormalPosition.Left;
                                  Result.Top := Wp.rcNormalPosition.Top;
                                end;
                    end;
                  end;
  end;
end;


{$IFDEF MSWindows}
procedure TFormMain.WMSysCommand(var Msg: TWMSysCommand);
begin
  //If the system message is screensaver or monitor power off then trap the message and set its result to -1
  if (Msg.CmdType = SC_SCREENSAVE) or (Msg.CmdType = SC_MONITORPOWER) then
    Msg.Result := -1
  else
    inherited;
end;


// Handle extra mouse buttons (forward/backward)
procedure TFormMain.WMAppCommand(var Msg: TMessage);
  // Parse DwKeys flags to get ShiftState
  function GetShiftState(aDwKeys: Word): TShiftState;
  begin
    Result := [];
    if (aDwKeys and MK_LBUTTON) <> 0 then
      Include(Result, ssLeft)
    else if (aDwKeys and MK_RBUTTON) <> 0 then
      Include(Result, ssRight)
    else if (aDwKeys and MK_MBUTTON) <> 0 then
      Include(Result, ssMiddle)
    else if (aDwKeys and MK_CONTROL) <> 0 then
      Include(Result, ssCtrl)
    else if (aDwKeys and MK_SHIFT) <> 0 then
      Include(Result, ssShift);
  end;

var dwKeys,uDevice,cmd: Word;
  ShiftState: TShiftState;
begin
  ShiftState := [];
  {$IFDEF WDC}
  uDevice := GET_DEVICE_LPARAM(Msg.lParam);
  if uDevice = FAPPCOMMAND_MOUSE then
  begin
    dwKeys := GET_KEYSTATE_LPARAM(Msg.lParam);
    ShiftState := GetShiftState(dwKeys);
    cmd := GET_APPCOMMAND_LPARAM(Msg.lParam);
    case cmd of
       APPCOMMAND_BROWSER_FORWARD:  FormKeyUpProc(VK_XBUTTON1, ShiftState);
       APPCOMMAND_BROWSER_BACKWARD: FormKeyUpProc(VK_XBUTTON2, ShiftState);
       else
         inherited;
     end;
  end;
  {$ENDIF}
end;


//Supress default activation of window menu when Alt pressed, as Alt used in some shortcuts
procedure TFormMain.WndProc(var Message : TMessage);
begin
  if (Message.Msg = WM_SYSCOMMAND)
    and (Message.WParam = SC_KEYMENU)
    and SuppressAltForMenu then Exit;

  inherited WndProc(Message);
end;


procedure TFormMain.WMExitSizeMove(var Msg: TMessage) ;
begin
  gMain.Move(GetWindowParams);
end;
{$ENDIF}


procedure TFormMain.Debug_ExportMenuClick(Sender: TObject);
begin
  ForceDirectories(ExeDir + 'Export' + PathDelim);
  gGameApp.MainMenuInterface.MyControls.SaveToFile(ExeDir + 'Export' + PathDelim + 'MainMenu.txt');
end;


procedure TFormMain.Debug_ExportUIPagesClick(Sender: TObject);
begin
  if (gGameApp.Game <> nil) and (gGameApp.Game.ActiveInterface <> nil) then
    gGameApp.Game.ActiveInterface.ExportPages(ExeDir + 'Export' + PathDelim)
  else
  if gGameApp.MainMenuInterface <> nil then
    gGameApp.MainMenuInterface.ExportPages(ExeDir + 'Export' + PathDelim);
end;


//Tell fMain if we want to shut down the program
procedure TFormMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var MenuHidden: Boolean;
begin
  //Hacky solution to MessageBox getting stuck under main form: In full screen we must show
  //the menu while displaying a MessageBox otherwise it goes under the main form on some systems
  MenuHidden := (BorderStyle = bsNone) and (Menu = nil);
  if MenuHidden then Menu := MainMenu1;
  gMain.CloseQuery(CanClose);
  if MenuHidden then Menu := nil;
end;


procedure TFormMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  gMain.Stop(Self);
end;


procedure TFormMain.ResourceValues1Click(Sender: TObject);
begin
  gRes.Wares.ExportCostsTable('ResourceValues.txt');
end;


{$IFDEF FPC}
initialization
{$I KM_FormMain.lrs}
{$ENDIF}


end.
