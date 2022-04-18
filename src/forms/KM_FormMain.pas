unit KM_FormMain;
{$I KaM_Remake.inc}
interface
uses
  SysUtils, StrUtils, Classes, Math,
  ComCtrls, Controls, Buttons, Dialogs, ExtCtrls, Forms, Graphics, Menus, StdCtrls,
  KM_RenderControl, KM_CommonTypes,
  KM_WindowParams, KM_SettingsDev,
  {$IFDEF FPC} LResources, Spin, {$ENDIF}
  {$IFDEF WDC} Vcl.Samples.Spin, {$ENDIF}
  {$IFDEF MSWindows} KM_VclMenuHint, ShellAPI, Windows, Messages; {$ENDIF}
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
    chkSuperSpeed: TCheckBox;
    Export_Deliverlists1: TMenuItem;
    Export_Sounds1: TMenuItem;
    Export_HouseAnim1: TMenuItem;
    Export_UnitAnim1: TMenuItem;
    RGPlayer: TRadioGroup;
    btnGameStop: TButton;
    OpenMissionMenu: TMenuItem;
    AnimData1: TMenuItem;
    Other1: TMenuItem;
    Debug_ShowPanel: TMenuItem;
    Export_TreeAnim1: TMenuItem;
    ExportMainMenu: TMenuItem;
    Debug_EnableCheats: TMenuItem;
    ExportUIPages: TMenuItem;
    Resources1: TMenuItem;
    mnExportHousesDat: TMenuItem;
    chkShowOwnership: TCheckBox;
    chkShowNavMesh: TCheckBox;
    chkShowAvoid: TCheckBox;
    chkShowBalance: TCheckBox;
    tbOwnMargin: TTrackBar;
    tbOwnThresh: TTrackBar;
    Label5: TLabel;
    Label6: TLabel;
    chkShowDefences: TCheckBox;
    chkBuild: TCheckBox;
    chkCombat: TCheckBox;
    ResourceValues1: TMenuItem;
    chkUIControlsBounds: TCheckBox;
    chkUITextBounds: TCheckBox;
    tbAngleX: TTrackBar;
    tbAngleY: TTrackBar;
    Label3: TLabel;
    Label4: TLabel;
    tbBuildingStep: TTrackBar;
    Label1: TLabel;
    tbPassability: TTrackBar;
    Label2: TLabel;
    chkShowRoutes: TCheckBox;
    chkShowWires: TCheckBox;
    tbAngleZ: TTrackBar;
    Label7: TLabel;
    chkSelectionBuffer: TCheckBox;
    chkLogDelivery: TCheckBox;
    chkLogNetConnection: TCheckBox;
    RGLogNetPackets: TRadioGroup;
    chkLogShowInChat: TCheckBox;
    chkUIControlsID: TCheckBox;
    Debug_ShowLogistics: TMenuItem;
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
    N6: TMenuItem;
    GameStats: TMenuItem;
    ExportGameStats: TMenuItem;
    ValidateGameStats: TMenuItem;
    chkLogRngChecks: TCheckBox;
    chkSkipRender: TCheckBox;
    chkSkipSound: TCheckBox;
    chkShowSoil: TCheckBox;
    chkShowFlatArea: TCheckBox;
    chkShowEyeRoutes: TCheckBox;
    {$IFDEF WDC}
    mainGroup: TCategoryPanelGroup;
    cpGameControls: TCategoryPanel;
    cpDebugRender: TCategoryPanel;
    cpAI: TCategoryPanel;
    cpUserInreface: TCategoryPanel;
    cpGraphicTweaks: TCategoryPanel;
    cpLogs: TCategoryPanel;
    cpGameAdv: TCategoryPanel;
    cpPerfLogs: TCategoryPanel;
    chkSnowHouses: TCheckBox;
    chkInterpolatedRender: TCheckBox;
    chkLoadUnsupSaves: TCheckBox;
    chkJamMeter: TCheckBox;
    chkShowTerrainOverlays: TCheckBox;
    chkDebugScripting: TCheckBox;
    chkLogSkipTempCmd: TCheckBox;
    chkShowDefencesAnimate: TCheckBox;
    chkShowArmyVectorFieldEnemy: TCheckBox;
    chkShowArmyVectorFieldAlly: TCheckBox;
    chkShowClusters: TCheckBox;
    chkShowAlliedGroups: TCheckBox;
    chkHeight: TCheckBox;
    chkTreeAge: TCheckBox;
    chkFieldAge: TCheckBox;
    chkTileLock: TCheckBox;
    chkTileOwner: TCheckBox;
    chkTileUnit: TCheckBox;
    chkVertexUnit: TCheckBox;
    chkTileObject: TCheckBox;

    chkSupervisor: TCheckBox;
    cpScripting: TCategoryPanel;
    chkShowDefencePos: TCheckBox;
    chkShowUnitRadius: TCheckBox;
    chkShowTowerRadius: TCheckBox;
    chkShowMiningRadius: TCheckBox;
    chkShowDeposits: TCheckBox;
    chkShowOverlays: TCheckBox;
    chkShowUnits: TCheckBox;
    chkShowHouses: TCheckBox;
    chkShowObjects: TCheckBox;
    chkShowFlatTerrain: TCheckBox;

    sePauseBeforeTick: TSpinEdit;
    Label8: TLabel;
    Label9: TLabel;
    seMakeSaveptBeforeTick: TSpinEdit;
    Label12: TLabel;
    seCustomSeed: TSpinEdit;
    chkUIFocusedControl: TCheckBox;
    chkUIControlOver: TCheckBox;
    chkPaintSounds: TCheckBox;
    cpMisc: TCategoryPanel;
    chkBevel: TCheckBox;
    rgDebugFont: TRadioGroup;
    mnExportRPL: TMenuItem;
    chkPathfinding: TCheckBox;
    chkGipAsBytes: TCheckBox;
    cpDebugInput: TCategoryPanel;
    gbFindObjByUID: TGroupBox;
    Label14: TLabel;
    Label15: TLabel;
    Label13: TLabel;
    seFindObjByUID: TSpinEdit;
    btFindObjByUID: TButton;
    seEntityUID: TSpinEdit;
    seWarriorUID: TSpinEdit;
    GroupBox2: TGroupBox;
    Label10: TLabel;
    Label11: TLabel;
    seDebugValue: TSpinEdit;
    edDebugText: TEdit;
    chkFindObjByUID: TCheckBox;
    tbWaterLight: TTrackBar;
    lblWaterLight: TLabel;
    chkSkipRenderText: TCheckBox;
    {$ENDIF}
    {$IFDEF FPC}
    mainGroup: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    GroupBox5: TGroupBox;
    GroupBoxLogs: TGroupBox;
    {$ENDIF}
    N5: TMenuItem;
    LoadSavThenRpl: TMenuItem;
    N7: TMenuItem;
    ReloadLibx: TMenuItem;
    N8: TMenuItem;
    N10: TMenuItem;
    N9: TMenuItem;
    Debug_UnlockCmpMissions: TMenuItem;
    N11: TMenuItem;
    mnExportRngChecks: TMenuItem;
    chkLogShowInGUI: TCheckBox;
    chkLogUpdateForGUI: TCheckBox;
    chkCursorCoordinates: TCheckBox;
    chkInterpolatedAnims: TCheckBox;
    cpDebugOutput: TCategoryPanel;
    chkUIDs: TCheckBox;
    chkSelectedObjInfo: TCheckBox;
    chkHands: TCheckBox;
    chkGIP: TCheckBox;
    chkShowFPS: TCheckBox;
    chkShowGameTick: TCheckBox;
    CategoryPanel1: TCategoryPanel;
    chkShowTerrainIds: TCheckBox;
    chkShowTerrainKinds: TCheckBox;
    chkTilesGrid: TCheckBox;
    chkDebugTerrainRender: TCheckBox;
    gbRenderTerrain: TGroupBox;
    chkTerrainRenderAnim: TCheckBox;
    chkTerrainRenderLight: TCheckBox;
    chkTerrainRenderShadow: TCheckBox;
    gbDebugLayers: TGroupBox;
    chkDebugLayerBase: TCheckBox;
    chkDebugLayer1: TCheckBox;
    chkDebugLayer2: TCheckBox;
    chkDebugLayer3: TCheckBox;
    Debug_SaveGameWholeMapToImage: TMenuItem;
    chkViewport: TCheckBox;
    gbSaveGameMapToImage: TGroupBox;
    seMaxImageSize: TSpinEdit;
    Label16: TLabel;
    rgImageType: TRadioGroup;
    btnSaveMapImage: TButton;
    btnPrintScreen: TButton;
    N12: TMenuItem;
    miExportMemoryUsage: TMenuItem;
    chkShowRoutesSteps: TCheckBox;
    btnGameSave: TButton;
    seHighlightNavMesh: TSpinEdit;
    mnExportUnitsDat: TMenuItem;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);

    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);

    procedure RenderAreaMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure RenderAreaMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
    procedure RenderAreaMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure RenderAreaMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);

    procedure RenderAreaResize(aWidth, aHeight: Integer);
    procedure RenderAreaRender(aSender: TObject);

    procedure AboutClick(Sender: TObject);
    procedure ExitClick(Sender: TObject);

    procedure MenuItem1Click(Sender: TObject);

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
    procedure Export_TreeAnim1Click(Sender: TObject);
    procedure Export_Fonts1Click(Sender: TObject);
    procedure Export_DeliverLists1Click(Sender: TObject);
    procedure UnitAnim_AllClick(Sender: TObject);
    procedure SoldiersClick(Sender: TObject);
    procedure Civilians1Click(Sender: TObject);

    procedure Debug_PrintScreenClick(Sender: TObject);
    procedure Debug_SaveGameWholeMapToImageClick(Sender: TObject);
    procedure Debug_ExportMenuClick(Sender: TObject);
    procedure Debug_EnableCheatsClick(Sender: TObject);
    procedure Debug_UnlockCmpMissionsClick(Sender: TObject);
    procedure Debug_ShowLogisticsClick(Sender: TObject);
    procedure Debug_ShowPanelClick(Sender: TObject);
    procedure Debug_ExportUIPagesClick(Sender: TObject);

    procedure btnGameStopClick(Sender: TObject);
    procedure RGPlayerClick(Sender: TObject);
    procedure Open_MissionMenuClick(Sender: TObject);
    procedure chkSuperSpeedClick(Sender: TObject);
    procedure mnExportHousesDatClick(Sender: TObject);
    procedure ExportGameStatsClick(Sender: TObject);
    procedure ResourceValues1Click(Sender: TObject);
    procedure ReloadSettingsClick(Sender: TObject);
    procedure SaveSettingsClick(Sender: TObject);
    procedure SaveEditableMission1Click(Sender: TObject);
    procedure ValidateGameStatsClick(Sender: TObject);
    procedure LoadSavThenRplClick(Sender: TObject);
    procedure ReloadLibxClick(Sender: TObject);
    procedure mnExportRngChecksClick(Sender: TObject);
    procedure btFindObjByUIDClick(Sender: TObject);
    procedure mnExportRPLClick(Sender: TObject);
    procedure radioGroupExit(Sender: TObject);
    procedure miExportMemoryUsageClick(Sender: TObject);

    procedure ControlsUpdate(Sender: TObject);
    procedure btnGameSaveClick(Sender: TObject);
    procedure mnExportUnitsDatClick(Sender: TObject);
  private
    {$IFDEF MSWindows}
    fMenuItemHint: TKMVclMenuItemHint; // Custom hint over menu item
    {$ENDIF}
    fStartVideoPlayed: Boolean;
    fUpdating: Boolean;
    fMissionDefOpenPath: UnicodeString;
    fOnControlsUpdated: TObjectIntegerEvent;
    procedure FormKeyDownProc(aKey: Word; aShift: TShiftState);
    procedure FormKeyUpProc(aKey: Word; aShift: TShiftState);
//    function ConfirmExport: Boolean;
    function GetMouseWheelStepsCnt(aWheelData: Integer): Integer;

    procedure ConstrolsDisableTabStops;
    procedure ControlDisableTabStop(aCtrl: TControl);
    procedure SubPanelDisableTabStop(aPanel: TWinControl);

    procedure ResetControl(aCtrl: TControl);
    procedure ResetSubPanel(aPanel: TWinControl);

    procedure FindObjByUID(aUID: Integer);
    function AllowFindObjByUID: Boolean;
    {$IFDEF MSWindows}
    function GetWindowParams: TKMWindowParamsRecord;
    procedure WMSysCommand(var Msg: TWMSysCommand); message WM_SYSCOMMAND;
    procedure WMExitSizeMove(var Msg: TMessage) ; message WM_EXITSIZEMOVE;
    procedure WMAppCommand(var Msg: TMessage); message WM_APPCOMMAND;
    procedure WMMouseWheel(var Msg: TMessage); message WM_MOUSEWHEEL;
    procedure WMMenuSelect(var Msg: TWMMenuSelect); message WM_MENUSELECT;
  private
    fDevSettings: TKMDevSettings;
  protected
    procedure WndProc(var Message: TMessage); override;
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
    procedure SetSaveGameWholeMapImage(aEnabled: Boolean);
    procedure SetExportGameStats(aEnabled: Boolean);
    procedure ShowFolderPermissionError;
    procedure SetEntitySelected(aEntityUID: Integer; aEntity2UID: Integer = 0);
    property OnControlsUpdated: TObjectIntegerEvent read fOnControlsUpdated write fOnControlsUpdated;

    procedure Defocus;

    procedure AfterFormCreated;
  end;


implementation
//{$IFDEF WDC}
  {$R *.dfm}
//{$ENDIF}

uses
  {$IFDEF WDC} UITypes, {$ENDIF}
  {$IFDEF FASTMM} FastMM4, {$ENDIF}
  KromUtils,
  KromShellUtils,
  KM_Defaults,
  KM_Main,
  //Use these units directly to avoid pass-through methods in fMain
  KM_Resource, KM_ResHouses, KM_ResWares,

  KM_ResTexts,
  KM_GameApp, KM_GameParams,
  KM_HandsCollection,
  KM_ResSound,
  KM_Pics,
  KM_RenderPool,
  KM_Hand,
  KM_ResKeys, KM_ResExporter,
  KM_FormLogistics, KM_Game,
  KM_RandomChecks,
  KM_Log, KM_CommonClasses, KM_VclHelpers, KM_Video,
  KM_MainSettings, KM_GameSettings,
  KM_ServerSettings,

  KM_IoXML,
  KM_GameInputProcess,
  KM_ResTypes,
  KM_GameAppSettings;


procedure ExportDone(aResourceName: String);
begin
  MessageDlg(Format(gResTexts[TX_RESOURCE_EXPORT_DONE_MSG], [aResourceName]), mtInformation, [mbOk], 0);
end;


//Remove VCL panel and use flicker-free TMyPanel instead
procedure TFormMain.FormCreate(Sender: TObject);
begin
  fStartVideoPlayed := False;
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
    fMenuItemHint := TKMVclMenuItemHint.Create(Self);
    //Means it will receive WM_SIZE WM_PAINT always in pair (if False - WM_PAINT is not called if size becames smaller)
    RenderArea.FullRepaint := True;
    RenderArea.BevelOuter := bvNone;
  {$ENDIF}

  //Put debug panel on top
  {$IFDEF WDC}
  RenderArea.BringToFront;
  mainGroup.SendToBack;
  StatusBar1.SendToBack;
  {$ENDIF}
  {$IFDEF FPC}
  RenderArea.SendToBack;
  mainGroup.BringToFront;
  {$ENDIF}

  chkShowFlatTerrain.Tag := Ord(dcFlatTerrain);
  tbWaterLight.Tag := Ord(dcFlatTerrain);
end;


procedure TFormMain.FormDestroy(Sender: TObject);
begin
  {$IFDEF MSWindows}
  fMenuItemHint.Free;
  {$ENDIF}

  FreeAndNil(fDevSettings);
end;


procedure TFormMain.FormShow(Sender: TObject);
var
  bordersWidth, bordersHeight: Integer;
begin
  //We do this in OnShow rather than OnCreate as the window borders aren't
  //counted properly in OnCreate
  bordersWidth := Width - ClientWidth;
  bordersHeight := Height - ClientHeight;
  //Constraints includes window borders, so we add them on as Margin
  Constraints.MinWidth := MIN_RESOLUTION_WIDTH + bordersWidth;
  Constraints.MinHeight := MIN_RESOLUTION_HEIGHT + bordersHeight;

  // We have to put it here, to proper window positioning for multimonitor systems
  if not gMainSettings.FullScreen then
  begin
    Left := gMainSettings.WindowParams.Left;
    Top := gMainSettings.WindowParams.Top;
  end;

  fMissionDefOpenPath := ExeDir;

  Application.ProcessMessages;

  if not fStartVideoPlayed and (gGameSettings <> nil) and gGameSettings.VideoStartup then
  begin
    gVideoPlayer.AddVideo(CAMPAIGNS_FOLDER_NAME + PathDelim + 'The Peasants Rebellion' + PathDelim + 'Logo', vfkStarting);
    gVideoPlayer.AddVideo('KaM', vfkStarting);
    gVideoPlayer.Play;
    fStartVideoPlayed := True;
  end;
end;


procedure TFormMain.SetSaveEditableMission(aEnabled: Boolean);
begin
  SaveEditableMission1.Enabled := aEnabled;
end;


procedure TFormMain.SetSaveGameWholeMapImage(aEnabled: Boolean);
begin
  Debug_SaveGameWholeMapToImage.Enabled := aEnabled;
  btnSaveMapImage.Enabled := aEnabled;
  seMaxImageSize.Enabled := aEnabled;
end;


procedure TFormMain.SetExportGameStats(aEnabled: Boolean);
begin
  ExportGameStats.Enabled := aEnabled;
end;


procedure TFormMain.FormKeyDownProc(aKey: Word; aShift: TShiftState);
begin
  if aKey = gResKeys[kfDebugWindow] then
  begin
    SHOW_DEBUG_CONTROLS := not SHOW_DEBUG_CONTROLS;
    ControlsSetVisibile(SHOW_DEBUG_CONTROLS, not (ssCtrl in aShift)); //Hide groupbox when Ctrl is pressed
  end;

  if gGameApp <> nil then gGameApp.KeyDown(aKey, aShift);
end;


procedure TFormMain.FormKeyUpProc(aKey: Word; aShift: TShiftState);
begin
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


procedure TFormMain.ReloadLibxClick(Sender: TObject);
begin
  gRes.LoadLocaleAndFonts(gGameSettings.Locale, gGameSettings.LoadFullFonts);
end;


procedure TFormMain.ReloadSettingsClick(Sender: TObject);
begin
  gGameAppSettings.ReloadSettings;
  gServerSettings.ReloadSettings;

  if gGameApp.Game <> nil then
    gGameApp.Game.GamePlayInterface.UpdateClockUI;
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


procedure TFormMain.RenderAreaMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  gGameApp.MouseWheel(Shift, WheelDelta, MousePos.X, MousePos.Y, Handled);
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


procedure TFormMain.miExportMemoryUsageClick(Sender: TObject);
begin
  {$IFDEF FASTMM}
  LogMemoryManagerStateToFile(ExeDir + 'Logs' + PathDelim + 'memusage_' + IntToStr(GetTickCount) + '.log');
  {$ENDIF}
end;


procedure TFormMain.mnExportRngChecksClick(Sender: TObject);
var
  rngLogger: TKMRandomCheckLogger;
begin
  if RunOpenDialog(OpenDialog1, '', ExeDir, 'KaM Remake Random checks log (*.rng)|*.rng') then
  begin
    rngLogger := TKMRandomCheckLogger.Create;

    rngLogger.LoadFromPathAndParseToDict(OpenDialog1.FileName);
    rngLogger.SaveAsText(OpenDialog1.FileName + '.log');

    rngLogger.Free;
  end;
end;


procedure TFormMain.mnExportRPLClick(Sender: TObject);
var
  gip: TKMGameInputProcess;
begin
  if RunOpenDialog(OpenDialog1, '', ExeDir, 'KaM Remake replay commands (*.rpl)|*.rpl') then
  begin
    gip := TKMGameInputProcess.Create(gipReplaying);
    gip.LoadFromFile(OpenDialog1.FileName);
    gip.SaveToFileAsText(OpenDialog1.FileName + '.log');
  end;
end;


procedure TFormMain.mnExportUnitsDatClick(Sender: TObject);
begin
  gRes.Units.ExportCSV(ExeDir + 'Export' + PathDelim + 'units.dat.csv')
end;


procedure TFormMain.SaveEditableMission1Click(Sender: TObject);
begin
  if gGameApp.Game = nil then Exit;

  if not gGameApp.Game.Params.IsMapEditor then Exit;

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
    gGameApp.PrintScreen('', TKMImageType(rgImageType.ItemIndex));
end;


procedure TFormMain.Debug_SaveGameWholeMapToImageClick(Sender: TObject);
begin
  if gGameApp <> nil then
    gGameApp.SaveGameWholeMapToImage(TKMImageType(rgImageType.ItemIndex), seMaxImageSize.Value);
end;


procedure TFormMain.Debug_ShowPanelClick(Sender: TObject);
begin
  mainGroup.Visible := not mainGroup.Visible;
end;


procedure TFormMain.Debug_UnlockCmpMissionsClick(Sender: TObject);
begin
  case MessageDlg(Format(gResTexts[TX_MENU_DEBUG_UNLOCK_CAMPAIGNS_CONFIRM], [ExeDir + 'Saves']), mtWarning, [mbYes, mbNo], 0) of
    mrYes:  begin
              Debug_UnlockCmpMissions.Checked := not Debug_UnlockCmpMissions.Checked;
              UNLOCK_CAMPAIGN_MAPS := Debug_UnlockCmpMissions.Checked;
              if UNLOCK_CAMPAIGN_MAPS then
                gGameApp.UnlockAllCampaigns;
            end;
  end;
end;


procedure TFormMain.Defocus;
begin
  if Assigned(ActiveControl) then
    DefocusControl(ActiveControl, True);
end;


//Exports
procedure TFormMain.Export_TreesRXClick(Sender: TObject);
begin
  gResExporter.ExportSpritesToPNG(rxTrees, ExportDone);
end;

procedure TFormMain.Export_HousesRXClick(Sender: TObject);
begin
  gResExporter.ExportSpritesToPNG(rxHouses, ExportDone);
end;

procedure TFormMain.Export_UnitsRXClick(Sender: TObject);
begin
  gResExporter.ExportSpritesToPNG(rxUnits, ExportDone);
end;

procedure TFormMain.Export_ScriptDataClick(Sender: TObject);
begin
  if (gGameApp <> nil)
  and (gGameApp.Game <> nil)
  and (gGame.Scripting <> nil) then
    gGame.Scripting.ExportDataToText;
end;

procedure TFormMain.Export_GUIClick(Sender: TObject);
begin
  gResExporter.ExportSpritesToPNG(rxGUI, ExportDone);
end;

procedure TFormMain.Export_GUIMainRXClick(Sender: TObject);
begin
  gResExporter.ExportSpritesToPNG(rxGUIMain, ExportDone);
end;

procedure TFormMain.Export_CustomClick(Sender: TObject);
begin
  gResExporter.ExportSpritesToPNG(rxCustom, ExportDone);
end;

procedure TFormMain.Export_TilesetClick(Sender: TObject);
begin
  gResExporter.ExportSpritesToPNG(rxTiles, ExportDone);
end;

procedure TFormMain.Export_Sounds1Click(Sender: TObject);
begin
  gRes.Sounds.ExportSounds;
end;

procedure TFormMain.Export_TreeAnim1Click(Sender: TObject);
begin
  gResExporter.ExportTreeAnim(ExportDone);
end;

procedure TFormMain.Export_HouseAnim1Click(Sender: TObject);
begin
  gResExporter.ExportHouseAnim(ExportDone);
end;


procedure TFormMain.mnExportHousesDatClick(Sender: TObject);
begin
  gResHouses.ExportCSV(ExeDir + 'Export' + PathDelim + 'houses.dat.csv')
end;


procedure TFormMain.LoadSavThenRplClick(Sender: TObject);
var
  savPath, rplPath: UnicodeString;
begin
  if RunOpenDialog(OpenDialog1, '', fMissionDefOpenPath, 'Knights & Merchants Save (*.sav)|*.sav') then
  begin
    savPath := OpenDialog1.FileName;
    fMissionDefOpenPath := ExtractFileDir(OpenDialog1.FileName);
    if RunOpenDialog(OpenDialog1, '', fMissionDefOpenPath, 'Knights & Merchants Replay (*.rpl)|*.rpl') then
    begin
      rplPath := OpenDialog1.FileName;

      gGameApp.NewSaveAndReplay(savPath, rplPath);
    end;
  end;
end;


procedure TFormMain.ExportGameStatsClick(Sender: TObject);
var
  dateS: UnicodeString;
begin
  if (gGame <> nil) and not gGame.Params.IsMapEditor then
  begin
    gResTexts.ForceDefaultLocale := True; //Use only eng for exported csv
    dateS := FormatDateTime('yyyy-mm-dd_hh-nn', Now);
    gHands.ExportGameStatsToCSV(ExeDir + 'Export' + PathDelim + gGameParams.Name + '_' + dateS + '.csv',
                            Format('Statistics for game at map ''%s'' on %s', [gGameParams.Name, dateS]));
    gResTexts.ForceDefaultLocale := False;
  end;
end;


procedure TFormMain.Export_Fonts1Click(Sender: TObject);
begin
  Assert(gRes <> nil, 'Can''t export Fonts cos they aren''t loaded yet');
  gRes.Fonts.ExportFonts;
end;


procedure TFormMain.Export_DeliverLists1Click(Sender: TObject);
var
  I: Integer;
begin
  if gHands = nil then Exit;

  // You could possibly cheat in multiplayer by seeing what supplies your enemy has
  if (gGameApp.Game <> nil) and (not gGameApp.Game.Params.IsMultiPlayerOrSpec or MULTIPLAYER_CHEATS) then
  for I := 0 to gHands.Count - 1 do
    gHands[I].Deliveries.Queue.ExportToFile(ExeDir + 'Player_' + IntToStr(I) + '_Deliver_List.txt');
end;


procedure TFormMain.RGPlayerClick(Sender: TObject);
begin
  if (gGameApp.Game = nil)
  or gGameApp.Game.Params.IsMapEditor
  or gGameApp.Game.Params.IsMultiPlayerOrSpec then
    Exit;

  if (gHands <> nil) and (RGPlayer.ItemIndex < gHands.Count) then
    gMySpectator.HandID := RGPlayer.ItemIndex;
end;


procedure TFormMain.SaveSettingsClick(Sender: TObject);
begin
  gGameAppSettings.SaveSettings;
  gServerSettings.SaveSettings;
end;


procedure TFormMain.Debug_ShowLogisticsClick(Sender: TObject);
begin
  if not Assigned(FormLogistics) then
    FormLogistics := TFormLogistics.Create(Self);
  FormLogistics.Show;
end;


procedure TFormMain.UnitAnim_AllClick(Sender: TObject);
begin
  gResExporter.ExportUnitAnim(UNIT_MIN, UNIT_MAX, True, ExportDone);
end;


procedure TFormMain.Civilians1Click(Sender: TObject);
begin
  gResExporter.ExportUnitAnim(CITIZEN_MIN, CITIZEN_MAX, False, ExportDone);
end;


procedure TFormMain.SoldiersClick(Sender: TObject);
begin
  gResExporter.ExportUnitAnim(WARRIOR_MIN, WARRIOR_MAX, False, ExportDone);
end;


procedure TFormMain.chkSuperSpeedClick(Sender: TObject);
begin
  if (gGameApp.Game = nil)
    or (gGameApp.Game.Params.IsMultiPlayerOrSpec
      and not gGameApp.Game.CanMPPlayerChangeSpeed
      and not MULTIPLAYER_SPEEDUP
      and not gGameApp.Game.Params.IsReplay) then
    Exit;

  gGameApp.Game.SetSpeed(IfThen(chkSuperSpeed.Checked, DEBUG_SPEEDUP_SPEED, 1), False);

  ActiveControl := nil; //Do not allow to focus on anything on debug panel
end;


procedure TFormMain.FindObjByUID(aUID: Integer);
begin
  if gGameApp.Game.GamePlayInterface = nil then Exit;

  gGameApp.Game.GamePlayInterface.SelectNHighlightEntityByUID(aUID);
end;


procedure TFormMain.btFindObjByUIDClick(Sender: TObject);
begin
  FindObjByUID(seFindObjByUID.Value);
end;


procedure TFormMain.btnGameSaveClick(Sender: TObject);
var
  path: string;
  allowSave: Boolean;
begin
  if (gGameApp.Game <> nil) and not gGameApp.Game.Params.IsMapEditor then
  begin
    path := gGameApp.Game.Params.Name + '_' + FormatDateTime('yyyy-mm-dd_hh-nn-ss-zzz', Now);

    // Store old value
    allowSave := ALLOW_SAVE_IN_REPLAY;
    ALLOW_SAVE_IN_REPLAY := True;

    gGameApp.Game.Save(path);

    // Restore old value
    ALLOW_SAVE_IN_REPLAY := allowSave;
  end;

  ActiveControl := nil; //Do not allow to focus on anything on debug panel
end;


procedure TFormMain.btnGameStopClick(Sender: TObject);
begin
  if gGameApp.Game <> nil then
    if gGameApp.Game.Params.IsMapEditor then
      gGameApp.StopGame(grMapEdEnd)
    else
    if gGameApp.Game.Params.IsReplay then
      gGameApp.StopGame(grReplayEnd)
    else
      gGameApp.StopGame(grCancel);

  ActiveControl := nil; //Do not allow to focus on anything on debug panel
end;


// It is annoying to have Tab cycling through F11 controls. Hence we disable it (@Rey: Correct?)
procedure TFormMain.ConstrolsDisableTabStops;

  {$IFDEF WDC}
  procedure CategoryPanelDisableTabStops(aPanel: TCategoryPanel);
  var
    panelSurface: TCategoryPanelSurface;
  begin
    if (aPanel.ControlCount > 0) and (aPanel.Controls[0] is TCategoryPanelSurface) then
    begin
      panelSurface := TCategoryPanelSurface(aPanel.Controls[0]);
      SubPanelDisableTabStop(panelSurface);
    end;
  end;

  procedure GroupDisableTabStops(aGroup: TCategoryPanelGroup);
  var
    I: Integer;
  begin
    for I := 0 to aGroup.ControlCount - 1 do
      if (aGroup.Controls[I] is TCategoryPanel) then
        CategoryPanelDisableTabStops(TCategoryPanel(aGroup.Controls[I]));
  end;
  {$ENDIF}

begin
  {$IFDEF WDC}
  GroupDisableTabStops(mainGroup);
  {$ENDIF}
end;


procedure TFormMain.ControlDisableTabStop(aCtrl: TControl);
begin
  if aCtrl is TButton then
    TButton(aCtrl).TabStop := False
  else
  if aCtrl is TCheckBox then
    TCheckBox(aCtrl).TabStop := False
  else
  if aCtrl is TTrackBar then
    TTrackBar(aCtrl).TabStop := False
  else
  if (aCtrl is TRadioGroup) then
  begin
// TRadioGroup.TabStop should not be accessed in the 'outside' code, its used for internal use
    radioGroupExit(aCtrl); // Tricky way to disable TabStop on TRadioGroup
  end
  else
  if (aCtrl is TSpinEdit) then
    TSpinEdit(aCtrl).TabStop := False
  else
  if (aCtrl is TEdit) then
    TEdit(aCtrl).TabStop := False
  else
  if (aCtrl is TGroupBox) then
  begin
    TGroupBox(aCtrl).TabStop := False;
    SubPanelDisableTabStop(TGroupBox(aCtrl));
  end;
end;


procedure TFormMain.SubPanelDisableTabStop(aPanel: TWinControl);
var
  I: Integer;
begin
  for I := 0 to aPanel.ControlCount - 1 do
  begin
    aPanel.TabStop := False;
    ControlDisableTabStop(aPanel.Controls[I]);
  end;
end;


procedure TFormMain.ResetControl(aCtrl: TControl);

  function SkipReset(aCtrl: TControl): Boolean;
  begin
    Result := {$IFDEF WDC}
                 (aCtrl = chkSnowHouses)
              or (aCtrl = chkLoadUnsupSaves)
              or (aCtrl = chkDebugScripting)
              or (aCtrl = tbWaterLight)
              or (aCtrl = seMaxImageSize);
              {$ENDIF}
              {$IFDEF FPC} False; {$ENDIF}
  end;

begin
  if SkipReset(aCtrl) then Exit; //Skip reset for some controls

  if aCtrl is TCheckBox then
    TCheckBox(aCtrl).Checked :=   (aCtrl = chkBevel)
                               or (aCtrl = chkLogNetConnection)
                               or (aCtrl = chkLogSkipTempCmd)
                               or ((aCtrl = chkSnowHouses) and gGameSettings.AllowSnowHouses)
                               or ((aCtrl = chkInterpolatedRender) and gGameSettings.InterpolatedRender)
                               or ((aCtrl = chkInterpolatedAnims) and gGameSettings.InterpolatedAnimations)
                               or (aCtrl = chkShowObjects)
                               or (aCtrl = chkShowHouses)
                               or (aCtrl = chkShowUnits)
                               or (aCtrl = chkShowOverlays)
                               or (aCtrl = chkTerrainRenderAnim)
                               or (aCtrl = chkTerrainRenderLight)
                               or (aCtrl = chkTerrainRenderShadow)
                               or (aCtrl = chkDebugLayerBase)
                               or (aCtrl = chkDebugLayer1)
                               or (aCtrl = chkDebugLayer2)
                               or (aCtrl = chkDebugLayer3)
  else
  if aCtrl is TTrackBar then
  begin
    if aCtrl = tbWaterLight then
      TTrackBar(aCtrl).Position := Round(DEFAULT_WATER_LIGHT_MULTIPLIER * 100)
    else
      TTrackBar(aCtrl).Position := 0
  end
  else
  if (aCtrl is TRadioGroup)
    and (aCtrl <> rgDebugFont) then
    TRadioGroup(aCtrl).ItemIndex := 0
  else
  if (aCtrl is TSpinEdit) then
    TSpinEdit(aCtrl).Value := 0
  else
  if (aCtrl is TEdit) then
    TEdit(aCtrl).Text := ''
  else
  if (aCtrl is TGroupBox) then
    ResetSubPanel(TGroupBox(aCtrl));
end;


procedure TFormMain.ResetSubPanel(aPanel: TWinControl);
var
  I: Integer;
begin
  for I := 0 to aPanel.ControlCount - 1 do
    ResetControl(aPanel.Controls[I]);
end;


//Revert all controls to defaults (e.g. before MP session)
procedure TFormMain.ControlsReset;

  {$IFDEF WDC}
  procedure ResetCategoryPanel(aPanel: TCategoryPanel);
  var
    panelSurface: TCategoryPanelSurface;
  begin
    if (aPanel.ControlCount > 0) and (aPanel.Controls[0] is TCategoryPanelSurface) then
    begin
      panelSurface := TCategoryPanelSurface(aPanel.Controls[0]);
      ResetSubPanel(panelSurface);
    end;
  end;

  procedure ResetGroup(aGroup: TCategoryPanelGroup);
  var
    I: Integer;
  begin
    for I := 0 to aGroup.ControlCount - 1 do
      if (aGroup.Controls[I] is TCategoryPanel) then
        ResetCategoryPanel(TCategoryPanel(aGroup.Controls[I]));
  end;
  {$ENDIF}

  {$IFDEF FPC}
  procedure ResetGroup(aBox: TGroupBox);
  var
    I: Integer;
  begin
    for I := 0 to aBox.ControlCount - 1 do
    begin
      if SkipReset(aBox.Controls[I]) then Continue; //Skip reset for some controls

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
        ResetGroup(TGroupBox(aBox.Controls[I]));
    end;
  end;
  {$ENDIF}

begin
  if not RESET_DEBUG_CONTROLS then Exit;

  fUpdating := True;
  
  ResetGroup(mainGroup);

  tbOwnMargin.Position := OWN_MARGIN_DEF;
  tbOwnThresh.Position := OWN_THRESHOLD_DEF;

  fUpdating := False;

  if Assigned(FormLogistics) then
    FormLogistics.Clear;

  ControlsUpdate(nil);
end;


procedure TFormMain.AfterFormCreated;
begin
  fDevSettings := TKMDevSettings.Create(ExeDir, mainGroup, cpGameControls);

  fUpdating := True;
  try
    fDevSettings.Load;
  finally
    fUpdating := False;
    ControlsUpdate(nil); // Update controls after loading all of them
  end;

  ConstrolsDisableTabStops;
end;


function TFormMain.AllowFindObjByUID: Boolean;
begin
  Result := // Update values only if Debug panel is opened or if we are debugging
        ((SHOW_DEBUG_CONTROLS and not cpDebugInput.Collapsed)
          or {$IFDEF DEBUG} True {$ELSE} False {$ENDIF}) // But its ok if we are in Debug build
        and chkFindObjByUID.Checked     // and checkbox is checked
        and gMain.IsDebugChangeAllowed; // and not in MP
end;


procedure TFormMain.SetEntitySelected(aEntityUID: Integer; aEntity2UID: Integer = 0);
begin
  if not AllowFindObjByUID then Exit;

  seEntityUID.SetValueWithoutChange(aEntityUID);
  seWarriorUID.SetValueWithoutChange(aEntity2UID);
                                                                {TODO -oOwner -cGeneral : ActionItem}
  if GetKeyState(VK_MENU) < 0 then
    seFindObjByUID.Value := aEntityUID // will trigger OnChange
  else
  if GetKeyState(VK_SHIFT) < 0 then
  begin
    if aEntity2UID = 0 then
      aEntity2UID := aEntityUID;
    seFindObjByUID.Value := aEntity2UID; // will trigger OnChange
  end
end;


procedure TFormMain.ControlsRefill;
begin
  fUpdating := True;

  //todo: Fill in rgDebugFont with font names on init, instead of hardcode

  try
    {$IFDEF WDC}
    chkSnowHouses.        SetCheckedWithoutClick(gGameSettings.AllowSnowHouses); // Snow houses checkbox could be updated before game
    chkInterpolatedRender.SetCheckedWithoutClick(gGameSettings.InterpolatedRender);
    chkInterpolatedAnims. SetCheckedWithoutClick(gGameSettings.InterpolatedAnimations);
    chkLoadUnsupSaves.    SetCheckedWithoutClick(ALLOW_LOAD_UNSUP_VERSION_SAVE);
    chkDebugScripting.    SetCheckedWithoutClick(DEBUG_SCRIPTING_EXEC);
    chkPaintSounds.       SetCheckedWithoutClick(DISPLAY_SOUNDS);
    chkSkipRender.        SetCheckedWithoutClick(SKIP_RENDER);
    chkSkipSound.         SetCheckedWithoutClick(SKIP_SOUND);
    chkShowGameTick.      SetCheckedWithoutClick(SHOW_GAME_TICK);
    chkBevel.             SetCheckedWithoutClick(SHOW_DEBUG_OVERLAY_BEVEL);
    rgDebugFont.ItemIndex := DEBUG_TEXT_FONT_ID;
    {$ENDIF}

    if (gGame = nil) or not gMain.IsDebugChangeAllowed then Exit;

    tbPassability.Max := Byte(High(TKMTerrainPassability));
    tbPassability.Position := SHOW_TERRAIN_PASS;
    Label2.Caption := IfThen(SHOW_TERRAIN_PASS <> 0, PASSABILITY_GUI_TEXT[TKMTerrainPassability(SHOW_TERRAIN_PASS)], '');

    chkShowWires.       SetCheckedWithoutClick(SHOW_TERRAIN_WIRES);
    chkShowTerrainIds.  SetCheckedWithoutClick(SHOW_TERRAIN_IDS);
    chkShowTerrainKinds.SetCheckedWithoutClick(SHOW_TERRAIN_KINDS);
    chkTilesGrid.       SetCheckedWithoutClick(SHOW_TERRAIN_TILES_GRID);
    chkTileOwner.       SetCheckedWithoutClick(SHOW_TILES_OWNER);
    chkTileObject.      SetCheckedWithoutClick(SHOW_TILE_OBJECT_ID);
    chkTreeAge.         SetCheckedWithoutClick(SHOW_TREE_AGE);
    chkFieldAge.        SetCheckedWithoutClick(SHOW_FIELD_AGE);
    chkTileLock.        SetCheckedWithoutClick(SHOW_TILE_LOCK);
    chkTileUnit.        SetCheckedWithoutClick(SHOW_TILE_UNIT);
    chkVertexUnit.      SetCheckedWithoutClick(SHOW_VERTEX_UNIT);
    chkShowRoutes.      SetCheckedWithoutClick(SHOW_UNIT_ROUTES);
    chkShowRoutesSteps. SetCheckedWithoutClick(SHOW_UNIT_ROUTES_STEPS);
    chkSelectionBuffer. SetCheckedWithoutClick(SHOW_SEL_BUFFER);

    chkShowObjects.     SetCheckedWithoutClick(mlObjects            in gGameParams.VisibleLayers);
    chkShowHouses.      SetCheckedWithoutClick(mlHouses             in gGameParams.VisibleLayers);
    chkShowUnits.       SetCheckedWithoutClick(mlUnits              in gGameParams.VisibleLayers);
    chkShowOverlays.    SetCheckedWithoutClick(mlOverlays           in gGameParams.VisibleLayers);
    chkShowMiningRadius.SetCheckedWithoutClick(mlMiningRadius       in gGameParams.VisibleLayers);
    chkShowTowerRadius. SetCheckedWithoutClick(mlTowersAttackRadius in gGameParams.VisibleLayers);
    chkShowUnitRadius.  SetCheckedWithoutClick(mlUnitsAttackRadius  in gGameParams.VisibleLayers);
    chkShowDefencePos.  SetCheckedWithoutClick(mlDefencesAll        in gGameParams.VisibleLayers);
    chkShowFlatTerrain. SetCheckedWithoutClick(mlFlatTerrain        in gGameParams.VisibleLayers);
  finally
    fUpdating := False;
  end;
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

  mainGroup.Visible  := aShowGroupBox and aShowCtrls;
  StatusBar1.Visible := aShowCtrls;

  //For some reason cycling Form.Menu fixes the black bar appearing under the menu upon making it visible.
  //This is a better workaround than ClientHeight = +20 because it works on Lazarus and high DPI where Menu.Height <> 20.
  Menu := nil;
  if aShowCtrls then Menu := MainMenu1;

  mainGroup.Enabled  := aShowGroupBox and aShowCtrls;
  StatusBar1.Enabled := aShowCtrls;
  for I := 0 to MainMenu1.Items.Count - 1 do
    MainMenu1.Items[I].Enabled := aShowCtrls;

  Refresh;

  RenderArea.Top    := 0;
  RenderArea.Height := ClientHeight;
  RenderArea.Width  := ClientWidth;
  gMain.Resize(RenderArea.Width, RenderArea.Height, GetWindowParams);
end;


procedure TFormMain.ShowFolderPermissionError;
begin
  MessageDlg(Format(gResTexts[TX_GAME_FOLDER_PERMISSIONS_ERROR], [ExeDir]), mtError, [mbClose], 0);
end;


procedure TFormMain.ControlsUpdate(Sender: TObject);

  procedure UpdateVisibleLayers(aCheckBox: TCheckBox; aLayer: TKMGameVisibleLayer);
  begin
    if Sender = aCheckBox then
      if aCheckBox.Checked then
        gGameParams.VisibleLayers := gGameParams.VisibleLayers + [aLayer]
      else
        gGameParams.VisibleLayers := gGameParams.VisibleLayers - [aLayer];
  end;

var
  I: Integer;
  allowDebugChange: Boolean;
begin
  if fUpdating then Exit;

  //You could possibly cheat in multiplayer by seeing debug render info
  allowDebugChange := gMain.IsDebugChangeAllowed
                      or (Sender = nil); //Happens in ControlsReset only (using this anywhere else could allow MP cheating)

  //Debug render
  if allowDebugChange then
  begin
    I := tbPassability.Position;
    tbPassability.Max := Ord(High(TKMTerrainPassability));
    Label2.Caption := IfThen(I <> 0, PASSABILITY_GUI_TEXT[TKMTerrainPassability(I)], '');
    SHOW_TERRAIN_PASS := I;
    SHOW_TERRAIN_WIRES := chkShowWires.Checked;
    SHOW_TERRAIN_IDS := chkShowTerrainIds.Checked;
    SHOW_TERRAIN_KINDS := chkShowTerrainKinds.Checked;
    SHOW_TERRAIN_TILES_GRID := chkTilesGrid.Checked;
    SHOW_UNIT_ROUTES := chkShowRoutes.Checked;
    SHOW_UNIT_ROUTES_STEPS := chkShowRoutesSteps.Checked;
    SHOW_SEL_BUFFER := chkSelectionBuffer.Checked;
    SHOW_GAME_TICK := chkShowGameTick.Checked;
    SHOW_FPS := chkShowFPS.Checked;
    SHOW_UIDs := chkUIDs.Checked;
    SHOW_SELECTED_OBJ_INFO := chkSelectedObjInfo.Checked;
    SHOW_HANDS_INFO := chkHands.Checked;
    SHOW_VIEWPORT_INFO := chkViewport.Checked;

    {$IFDEF WDC} //one day update .lfm for lazarus...
    DO_DEBUG_TER_RENDER := chkDebugTerrainRender.Checked;
    gbRenderTerrain.Enabled := DO_DEBUG_TER_RENDER;

    SKIP_TER_RENDER_ANIMS  := DO_DEBUG_TER_RENDER and not chkTerrainRenderAnim.Checked;
    SKIP_TER_RENDER_LIGHT  := DO_DEBUG_TER_RENDER and not chkTerrainRenderLight.Checked;
    SKIP_TER_RENDER_SHADOW := DO_DEBUG_TER_RENDER and not chkTerrainRenderShadow.Checked;

    for I := 0 to gbRenderTerrain.ControlCount - 1 do
      gbRenderTerrain.Controls[I].Enabled := DO_DEBUG_TER_RENDER;

    for I := 0 to gbDebugLayers.ControlCount - 1 do
      gbDebugLayers.Controls[I].Enabled := gbDebugLayers.Enabled;

    if gbDebugLayers.Enabled then
    begin
      DEBUG_TERRAIN_LAYERS := [];
      for I := 0 to gbDebugLayers.ControlCount - 1 do
      begin
        Assert(gbDebugLayers.Controls[I] is TCheckBox);
        // Refill in DEBUG_LAYERS set
        if TCheckBox(gbDebugLayers.Controls[I]).Checked then
          DEBUG_TERRAIN_LAYERS := DEBUG_TERRAIN_LAYERS + [Byte(gbDebugLayers.Controls[I].Tag)];
      end;
    end;

    SHOW_JAM_METER := chkJamMeter.Checked;
    SHOW_TILE_OBJECT_ID := chkTileObject.Checked;
    SHOW_TILES_OWNER := chkTileOwner.Checked;
    SHOW_TREE_AGE := chkTreeAge.Checked;
    SHOW_FIELD_AGE := chkFieldAge.Checked;
    SHOW_TILE_LOCK := chkTileLock.Checked;
    SHOW_TILE_UNIT := chkTileUnit.Checked;
    SHOW_VERTEX_UNIT := chkVertexUnit.Checked;
    SHOW_TERRAIN_HEIGHT := chkHeight.Checked;
    SHOW_TERRAIN_OVERLAYS := chkShowTerrainOverlays.Checked;
    DEBUG_SCRIPTING_EXEC := chkDebugScripting.Checked;
    SKIP_LOG_TEMP_COMMANDS := chkLogSkipTempCmd.Checked;

    SHOW_GIP := chkGIP.Checked;
    SHOW_GIP_AS_BYTES := chkGipAsBytes.Checked;
    PAUSE_GAME_BEFORE_TICK := sePauseBeforeTick.Value;
    MAKE_SAVEPT_BEFORE_TICK := seMakeSaveptBeforeTick.Value;
    CUSTOM_SEED_VALUE := seCustomSeed.Value;

    DEBUG_TEXT := edDebugText.Text;
    DEBUG_VALUE := seDebugValue.Value;

    if gGame <> nil then
    begin
      UpdateVisibleLayers(chkShowObjects,       mlObjects);
      UpdateVisibleLayers(chkShowHouses,        mlHouses);
      UpdateVisibleLayers(chkShowUnits,         mlUnits);
      UpdateVisibleLayers(chkShowOverlays,      mlOverlays);
      UpdateVisibleLayers(chkShowMiningRadius,  mlMiningRadius);
      UpdateVisibleLayers(chkShowTowerRadius,   mlTowersAttackRadius);
      UpdateVisibleLayers(chkShowUnitRadius,    mlUnitsAttackRadius);
      UpdateVisibleLayers(chkShowDefencePos,    mlDefencesAll);
      UpdateVisibleLayers(chkShowFlatTerrain,   mlFlatTerrain);
      chkShowTowerRadius.Tag := 5;
    end;
    {$ENDIF}

    SKIP_RENDER := chkSkipRender.Checked;
    SKIP_SOUND := chkSkipSound.Checked;
    DISPLAY_SOUNDS := chkPaintSounds.Checked;

    gbFindObjByUID.Enabled := chkFindObjByUID.Checked;

    if AllowFindObjByUID then
      btFindObjByUIDClick(nil)
    else
      FindObjByUID(0);
  end;

  //AI
  if allowDebugChange then
  begin
    SHOW_AI_WARE_BALANCE := chkShowBalance.Checked;
    OVERLAY_DEFENCES := chkShowDefences.Checked;
    OVERLAY_DEFENCES_A := chkShowDefencesAnimate.Checked;
    OVERLAY_AI_BUILD := chkBuild.Checked;
    OVERLAY_AI_COMBAT := chkCombat.Checked;
    OVERLAY_AI_PATHFINDING := chkPathfinding.Checked;
    OVERLAY_AI_SUPERVISOR := chkSupervisor.Checked;
    OVERLAY_AI_VEC_FLD_ENEM := chkShowArmyVectorFieldEnemy.Checked;
    OVERLAY_AI_VEC_FLD_ALLY := chkShowArmyVectorFieldAlly.Checked;
    OVERLAY_AI_CLUSTERS := chkShowClusters.Checked;
    OVERLAY_AI_ALLIEDGROUPS := chkShowAlliedGroups.Checked;
    OVERLAY_AI_EYE := chkAIEye.Checked;
    OVERLAY_AI_SOIL := chkShowSoil.Checked;
    OVERLAY_AI_FLATAREA := chkShowFlatArea.Checked;
    OVERLAY_AI_ROUTES := chkShowEyeRoutes.Checked;
    OVERLAY_AVOID := chkShowAvoid.Checked;
    OVERLAY_OWNERSHIP := chkShowOwnership.Checked;
    OVERLAY_NAVMESH := chkShowNavMesh.Checked;
    OVERLAY_HIGHLIGHT_POLY := seHighlightNavMesh.Value;

    OWN_MARGIN := tbOwnMargin.Position;
    tbOwnThresh.Max := OWN_MARGIN;
    OWN_THRESHOLD := tbOwnThresh.Position;
  end;

  //UI
  SHOW_CONTROLS_OVERLAY := chkUIControlsBounds.Checked;
  SHOW_TEXT_OUTLINES := chkUITextBounds.Checked;
  SHOW_CONTROLS_ID := chkUIControlsID.Checked;
  SHOW_FOCUSED_CONTROL := chkUIFocusedControl.Checked;
  SHOW_CONTROL_OVER := chkUIControlOver.Checked;
  SKIP_RENDER_TEXT := chkSkipRenderText.Checked;
  DBG_UI_HINT_POS := chkCursorCoordinates.Checked;

  {$IFDEF WDC} //one day update .lfm for lazarus...
  gGameSettings.AllowSnowHouses := chkSnowHouses.Checked;
  gGameSettings.InterpolatedRender := chkInterpolatedRender.Checked;
  gGameSettings.InterpolatedAnimations := chkInterpolatedAnims.Checked;

  ALLOW_LOAD_UNSUP_VERSION_SAVE := chkLoadUnsupSaves.Checked;
  {$ENDIF}

  //Graphics
  if allowDebugChange then
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

    WATER_LIGHT_MULTIPLIER := tbWaterLight.Position / 100;
    lblWaterLight.Caption := 'Water light x' + ReplaceStr(FormatFloat('0.##', WATER_LIGHT_MULTIPLIER), ',', '.');
  end;

  //Logs
  SHOW_LOG_IN_CHAT := chkLogShowInChat.Checked;
  SHOW_LOG_IN_GUI := chkLogShowInGUI.Checked;
  UPDATE_LOG_FOR_GUI := chkLogUpdateForGUI.Checked;
  LOG_GAME_TICK := chkLogGameTick.Checked;

  if allowDebugChange then
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

  //Misc
  if allowDebugChange then
  begin
    SHOW_DEBUG_OVERLAY_BEVEL := chkBevel.Checked;
    DEBUG_TEXT_FONT_ID := rgDebugFont.ItemIndex;
  end;

  if gGameApp.Game <> nil then
    gGameApp.Game.ActiveInterface.UpdateState(gGameApp.GlobalTickCount);

  if    not (Sender is TSpinEdit)
    and not (Sender is TEdit) then // TSpinEdit need focus to enter value
    ActiveControl := nil; //Do not allow to focus on anything on debug panel

  if Assigned(fOnControlsUpdated) and (Sender is TControl) then
    fOnControlsUpdated(Sender, TControl(Sender).Tag);

  fDevSettings.Save;
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
      gMainSettings.WindowParams.NeedResetToDefaults := False;
    end else begin
      // Here we set window Width/Height and State
      // Left and Top will set on FormShow, so omit setting them here
      Position := poDesigned;
      ClientWidth  := gMainSettings.WindowParams.Width;
      ClientHeight := gMainSettings.WindowParams.Height;
      Left := gMainSettings.WindowParams.Left;
      Top := gMainSettings.WindowParams.Top;
      WindowState  := gMainSettings.WindowParams.State;
    end;
  end;

  //Make sure Panel is properly aligned
  RenderArea.Align := alClient;
end;


//function TFormMain.ConfirmExport: Boolean;
//begin
//  case MessageDlg(Format(gResTexts[TX_FORM_EXPORT_CONFIRM_MSG], [ExeDir + 'Export']), mtWarning, [mbYes, mbNo], 0) of
//    mrYes:  Result := True;
//    else    Result := False;
//  end;
//end;


procedure TFormMain.ValidateGameStatsClick(Sender: TObject);
var
  MS: TKMemoryStream;
  SL: TStringList;
  CRC: Int64;
  isValid: Boolean;
begin
  if RunOpenDialog(OpenDialog1, '', ExeDir, 'KaM Remake statistics (*.csv)|*.csv') then
  begin
    isValid := False;
    SL := TStringList.Create;
    try
      try
        SL.LoadFromFile(OpenDialog1.FileName);
        if TryStrToInt64(SL[0], CRC) then
        begin
          SL.Delete(0); //Delete CRC from file
          MS := TKMemoryStreamBinary.Create;
          try
            MS.WriteHugeString(AnsiString(SL.Text));
            if CRC = Adler32CRC(MS) then
              isValid := True;
          finally
            FreeAndNil(MS);
          end;
        end;

        if isValid then
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
  wp: TWindowPlacement;
  bordersWidth, bordersHeight: SmallInt;
  rect: TRect;
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
                    wp.length := SizeOf(TWindowPlacement);
                    GetWindowPlacement(Handle, @wp);

                    // Get current borders width/height
                    bordersWidth := Width - ClientWidth;
                    bordersHeight := Height - ClientHeight;

                    // rcNormalPosition do not have ClientWidth/ClientHeight
                    // so we have to calc it manually via substracting borders width/height
                    Result.Width := wp.rcNormalPosition.Right - wp.rcNormalPosition.Left - bordersWidth;
                    Result.Height := wp.rcNormalPosition.Bottom - wp.rcNormalPosition.Top - bordersHeight;

                    // Adjustment of window position due to TaskBar position/size
                    case FindTaskBar(rect) of
                      ABE_LEFT: begin
                                  Result.Left := wp.rcNormalPosition.Left + rect.Right;
                                  Result.Top := wp.rcNormalPosition.Top;
                                end;
                      ABE_TOP:  begin
                                  Result.Left := wp.rcNormalPosition.Left;
                                  Result.Top := wp.rcNormalPosition.Top + rect.Bottom;
                                end
                      else      begin
                                  Result.Left := wp.rcNormalPosition.Left;
                                  Result.Top := wp.rcNormalPosition.Top;
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

var
  dwKeys, uDevice, cmd: Word;
  shiftState: TShiftState;
begin
  shiftState := [];
  {$IFDEF WDC}
  uDevice := GET_DEVICE_LPARAM(Msg.lParam);
  if uDevice = FAPPCOMMAND_MOUSE then
  begin
    dwKeys := GET_KEYSTATE_LPARAM(Msg.lParam);
    shiftState := GetShiftState(dwKeys);
    cmd := GET_APPCOMMAND_LPARAM(Msg.lParam);
    case cmd of
       APPCOMMAND_BROWSER_FORWARD:  FormKeyUpProc(VK_XBUTTON1, shiftState);
       APPCOMMAND_BROWSER_BACKWARD: FormKeyUpProc(VK_XBUTTON2, shiftState);
       else
         inherited;
    end;
  end
  else
    inherited;
  {$ENDIF}
end;


//Supress default activation of window menu when Alt pressed, as Alt used in some shortcuts
procedure TFormMain.WndProc(var Message: TMessage);
begin
  if (Message.Msg = WM_SYSCOMMAND)
  and (Message.WParam = SC_KEYMENU)
  and SuppressAltForMenu then Exit;

  inherited;
end;


procedure TFormMain.WMExitSizeMove(var Msg: TMessage) ;
begin
  gMain.Move(GetWindowParams);
  inherited;
end;


//We use WM_MOUSEWHEEL message handler on Windows, since it prevents some bugs from happaning
//F.e. on Win10 it was reported, that we got event 3 times on single turn of mouse wheel, if use default form event handler
procedure TFormMain.WMMouseWheel(var Msg: TMessage);
var
  mousePos: TPoint;
  keyState: TKeyboardState;
  wheelDelta: Integer;
  handled: Boolean;
begin
  mousePos.X := SmallInt(Msg.LParamLo);
  mousePos.Y := SmallInt(Msg.LParamHi);
  wheelDelta := SmallInt(Msg.WParamHi);
  GetKeyboardState(keyState);

  handled := False;
  gGameApp.MouseWheel(KeyboardStateToShiftState(keyState), GetMouseWheelStepsCnt(wheelDelta),
                      RenderArea.ScreenToClient(mousePos).X, RenderArea.ScreenToClient(mousePos).Y, handled);

  if not handled then
    inherited;
end;


procedure TFormMain.WMMenuSelect(var Msg: TWMMenuSelect);
var
  menuItem: TMenuItem;
  hSubMenu: HMENU;
begin
  inherited; // from TCustomForm

  menuItem:= nil;
  if (Msg.MenuFlag <> $FFFF) or (Msg.IDItem <> 0) then
  begin
    if Self.Menu = nil then Exit;
    
    if Msg.MenuFlag and MF_POPUP = MF_POPUP then
    begin
      hSubMenu:= GetSubMenu(Msg.Menu, Msg.IDItem);
      menuItem:= Self.Menu.FindItem(hSubMenu, fkHandle);
    end
    else
    begin
      menuItem:= Self.Menu.FindItem(Msg.IDItem, fkCommand);
    end;
  end;

  fMenuItemHint.DoActivateHint(menuItem);
end;
{$ENDIF}


procedure TFormMain.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
{$IFNDEF MSWINDOWS}
var
  handled: Boolean;
{$ENDIF}
begin
  // We use WM_MOUSEWHEEL message handler on Windows, since it prevents some bugs from happaning
  // F.e. on Win10 it was reported, that we got event 3 times on single turn of mouse wheel, if use default form event handler
{$IFNDEF MSWINDOWS}
  handled := False;
  gGameApp.MouseWheel(Shift, GetMouseWheelStepsCnt(WheelDelta), RenderArea.ScreenToClient(MousePos).X, RenderArea.ScreenToClient(MousePos).Y, handled);
{$ENDIF}
end;


function TFormMain.GetMouseWheelStepsCnt(aWheelData: Integer): Integer;
begin
  Result := aWheelData div WHEEL_DELTA;
end;


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
var
  menuHidden: Boolean;
begin
  fDevSettings.Save;

  if not QUERY_ON_FORM_CLOSE then
  begin
    CanClose := True;
    Exit;
  end;

  //Hacky solution to MessageBox getting stuck under main form: In full screen we must show
  //the menu while displaying a MessageBox otherwise it goes under the main form on some systems
  menuHidden := (BorderStyle = bsNone) and (Menu = nil);

  if menuHidden then Menu := MainMenu1;

  gMain.CloseQuery(CanClose);

  if menuHidden then Menu := nil;
end;


procedure TFormMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  gMain.Stop(Self);
end;


procedure TFormMain.ResourceValues1Click(Sender: TObject);
begin
  gResWares.ExportCostsTable('ResourceValues.txt');
end;


procedure TFormMain.radioGroupExit(Sender: TObject);
var
  I: Integer;
begin
  // To disable TabStop on TRadioGroup we need to disable it on its contents
  for I := 0 to TRadioGroup(Sender).ControlCount - 1 do
    TRadioButton(TRadioGroup(Sender).Controls[I]).TabStop := False;
end;


{$IFDEF FPC}
initialization
{$I KM_FormMain.lrs}
{$ENDIF}


end.
