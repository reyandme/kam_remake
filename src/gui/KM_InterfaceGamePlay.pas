unit KM_InterfaceGamePlay;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  StrUtils, SysUtils, KromUtils, Math, Classes, Controls, TypInfo,
  KM_Controls, KM_CommonClasses, KM_CommonTypes, KM_Defaults, KM_Pics, KM_Points,
  KM_InterfaceDefaults, KM_InterfaceGame, KM_Terrain, KM_Houses, KM_Units, KM_Minimap, KM_Viewport, KM_Render,
  KM_UnitGroup, KM_UnitWarrior, KM_Saves, KM_MessageStack, KM_ResHouses, KM_Alerts, KM_Networking,
  KM_GUIGameResultsSP,
  KM_GUIGameResultsMP,
  KM_GUIGameBuild, KM_GUIGameChat, KM_GUIGameHouse, KM_GUIGameUnit, KM_GUIGameRatios, KM_GUIGameStats,KM_GUIGameMenuSettings,
  KM_GUIGameSpectator;


const
  MAX_VISIBLE_MSGS = 32;
  MAX_LOG_MSGS = 8;
  //Limit names length to fit interface width
  MAX_MAPNAME_LENGTH = 22;
  MAX_TRACKNAME_LENGTH = 18;

type
  //tbNone is the last, since we use Byte(Value) at some places
  //TODO refactor
  TKMTabButtons = (tbBuild, tbRatio, tbStats, tbMenu, tbNone);

  TKMGamePlayInterface = class (TKMUserInterfaceGame)
  private
    fAlerts: TKMAlerts;

    fUIMode: TUIMode;
    fSave_Selected: Integer; // Save selected from list (needed because of scanning)

    fGuiGameBuild: TKMGUIGameBuild;
    fGuiGameChat: TKMGUIGameChat;
    fGuiGameHouse: TKMGUIGameHouse;
    fGuiGameUnit: TKMGUIGameUnit;
    fGuiGameRatios: TKMGUIGameRatios;
    fGuiGameStats: TKMGUIGameStats;
    fGuiMenuSettings: TKMGameMenuSettings;
    fGuiGameSpectator: TKMGUIGameSpectator;
    fGuiGameResultsSP: TKMGameResultsSP;
    fGuiGameResultsMP: TKMGameResultsMP;

    // Not saved
    fOpenedMenu: TKMTabButtons;
    fShowTeamNames: Boolean; // True while the SC_SHOW_TEAM key is pressed
    fLastDragPoint: TKMPoint; // Last mouse point that we drag placed/removed a road/field
    fLastBeaconTime: Cardinal; //Last time a beacon was sent to enforce cooldown
    fShownMessage: Integer;
    fPlayMoreMsg: TKMGameResultMsg; // Remember which message we are showing
    fPlacingBeacon: Boolean;
    fNetWaitDropPlayersDelayStarted: Cardinal;
    SelectedDirection: TKMDirection;
    SelectingTroopDirection: Boolean;
    SelectingDirPosition: TPoint;
    fSaves: TKMSavesCollection;
    fUnitsTeamNames: TList;
    fGroupsTeamNames: TList;
    fHousesTeamNames: TList;
    fLastSyncedMessage: Word; // Last message that we synced with MessageLog
    fLastKbdSelectionTime: Cardinal; //Last we select object from keyboard

    fLineIdToNetPlayerId: array [0..MAX_LOBBY_SLOTS - 1] of Integer;
    fPlayerLinesCnt: Integer;

    // Saved (in singleplayer only)
    fLastSaveName: UnicodeString; // The file name we last used to save this file (used as default in Save menu)
    fMessageStack: TKMMessageStack;
    fSelection: array [0..DYNAMIC_HOTKEYS_NUM - 1] of Integer;

    procedure Create_Controls;
    procedure Create_Replay;
    procedure Create_ScriptingOverlay;
    procedure Create_Allies;
    procedure Create_Message;
    procedure Create_MessageLog;
    procedure Create_Pause;
    procedure Create_PlayMore;
    procedure Create_MPPlayMore;
    procedure Create_NetWait;
    procedure Create_MessageStack;
    procedure Create_Menu;
    procedure Create_Save;
    procedure Create_Load;
    procedure Create_Quit;

    procedure Beacon_Cancel;
    procedure Beacon_Place(const aLoc: TKMPointF);
    procedure Chat_Click(Sender: TObject);
    procedure House_Demolish(Sender: TObject; Shift: TShiftState);
    procedure Reset_Menu;
    function ArmyCanTakeOrder(aObject: TObject): Boolean;
    function IsSelectingTroopDirection(aObject: TObject): Boolean;
    procedure Menu_QuitMission(Sender: TObject);
    procedure Menu_ReturnToMapEd(Sender: TObject);
    procedure Menu_NextTrack(Sender: TObject);
    procedure Menu_PreviousTrack(Sender: TObject);
    procedure Allies_Click(Sender: TObject);
    procedure Allies_Show(Sender: TObject);
    procedure MessageStack_UpdatePositions;
    procedure Message_Click(Sender: TObject; Shift: TShiftState);
    procedure Message_Close(Sender: TObject);
    procedure Message_Delete(aIndex: Integer);
    procedure Message_DeleteClick(Sender: TObject);
    procedure Message_Show(aIndex: Integer);
    procedure Message_GoTo(Sender: TObject);
    procedure Message_UpdateStack;
    procedure MessageLog_Click(Sender: TObject);
    procedure MessageLog_ShowMessage(aMessageId: Integer; aJumpToLoc: Boolean = True);
    function MessageLog_ItemClick(Sender: TObject; Shift: TShiftState; const X,Y: Integer): Boolean;
    procedure MessageLog_Close(Sender: TObject);
    procedure MessageLog_Update(aFullRefresh: Boolean);
    procedure Minimap_Update(Sender: TObject; const X,Y:integer);
    procedure Minimap_RightClick(Sender: TObject; const X,Y:integer);
    procedure Minimap_Click(Sender: TObject; const X,Y:integer);
    procedure GameSettingsChanged;

    procedure Menu_Save_RefreshList(Sender: TObject);
    procedure Menu_Save_ListChange(Sender: TObject);
    procedure Menu_Save_EditChange(Sender: TObject);
    procedure Menu_Save_CheckboxChange(Sender: TObject);
    procedure Menu_Save_Click(Sender: TObject);
    procedure Menu_Load_RefreshList(Sender: TObject);
    procedure Menu_Load_ListClick(Sender: TObject);
    procedure Menu_Load_Click(Sender: TObject);
    procedure Selection_Assign(aId: Word; aObject: TObject);
    procedure Selection_Link(aId: Word; aObject: TObject);
    procedure Selection_Select(aId: Word);
    procedure SelectUnit(aUnit: TKMUnit);
    procedure SelectUnitGroup(aGroup: TKMUnitGroup);
    procedure SelectNextGameObjWSameType;
    procedure SwitchPage(Sender: TObject);
    procedure OpenMenuPage(aPage: TKMTabButtons);
    procedure ShowStats(Sender: TObject);
    procedure PlayMoreClick(Sender: TObject);
    procedure MPPlayMoreClick(Sender: TObject);
    procedure NetWaitClick(Sender: TObject);
    procedure ReplayClick(Sender: TObject);
    procedure Replay_PlayersColorModeClick(Sender: TObject);
    function Replay_ListKeyUp(Sender: TObject; Key: Word; Shift: TShiftState): Boolean;
    procedure ReturnToLobbyClick(Sender: TObject);
    procedure Allies_Close(Sender: TObject);
    procedure Allies_Mute(Sender: TObject);
    procedure Update_Image_AlliesMute(aImage: TKMImage);
    procedure UpdateNetPlayersMapping;
    procedure Menu_Update;
    procedure DirectionCursorShow(X,Y: Integer; Dir: TKMDirection);
    procedure DirectionCursorHide;
    function HasLostMPGame: Boolean;
    procedure UpdateDebugInfo;
    procedure UpdateSelectedObject;
    procedure HidePages;
    procedure HideOverlay(Sender: TObject);
    procedure Replay_DropBox_JumpToPlayer(aDropBoxIndex: Integer);
    procedure Replay_JumpToPlayer(aHandIndex: Integer);
    procedure Replay_ViewPlayer(aPlayerIndex: Integer);
    procedure Replay_ListDoubleClick(Sender: TObject);
    procedure Replay_UpdatePlayerInterface(aFromPlayer, aToPlayer: Integer);
    procedure Replay_Single_SetPlayersDropbox;
    procedure Replay_Multi_SetPlayersDropbox;
    procedure ReplayMarkClick(aTick: Integer);

    procedure StopPlay(aMsg: TKMGameResultMsg; aPrepareToStopGame: Boolean = True);
    procedure StopGame(const aText: UnicodeString = '');
    procedure ShowMPStats;
    procedure ShowSPStats;

    procedure SetViewportPos(const aLoc: TKMPointF);
    procedure CheckMessageKeys(Key: Word);
    function CanShowChat: Boolean;
    function CanShowAllies: Boolean;
    procedure UpdateMessageImages;
    procedure UpdateReplayBar;

    function CanUpdateClockUI: Boolean;
  protected
    Sidebar_Top: TKMImage;
    Sidebar_Middle: TKMImage;
    Sidebar_Bottom: array of TKMImage;
    MinimapView: TKMMinimapView;
    Bevel_DebugInfo: TKMBevel;
    Label_DebugInfo: TKMLabel;

    Image_Chat, Image_MPAllies: TKMImage; // Multiplayer buttons
    Image_MessageLog: TKMImage;
    Label_ChatUnread: TKMLabel;
    Image_Message: array[0..MAX_VISIBLE_MSGS] of TKMImage; // Queue of messages covers 32*48=1536px height
    Image_Clock: TKMImage; // Clock displayed when game speed is increased
    Label_Clock: TKMLabel;
    Label_ClockSpeedActual, Label_ClockSpeedRecorded: TKMLabel;

    Label_ScriptedOverlay: TKMLabel; // Label that can be set from script
    Button_ScriptedOverlay: TKMButton;
    Label_OverlayShow, Label_OverlayHide: TKMLabel;

    Label_MenuTitle: TKMLabel; // Displays the title of the current menu to the right of return
    Image_DirectionCursor: TKMImage;

    Label_TeamName: TKMLabel;

    Panel_Controls: TKMPanel;
      Button_Main: array [tbBuild..tbMenu] of TKMButton; // 4 common buttons + Return
      Button_Back: TKMButton;

    Panel_Stats: TKMPanel;
      Panel_Stats_Background: TKMImage;

    Panel_ReplayBar: TKMPanel;
      ReplayBar_Replay: TKMReplayBar;
      Label_ReplayBar: TKMLabel;
    Panel_ReplayCtrl: TKMPanel; // Smaller Panel to contain replay controls
      Button_ReplayRestart: TKMButton;
      Button_ReplayPause: TKMButton;
      Button_ReplayStep: TKMButton;
      Button_ReplayResume: TKMButton;
      Button_ReplayExit: TKMButton;
      Button_ReplaySaveAt: TKMButton;
      Button_ShowStatsReplay: TKMButton;

    Panel_ReplayFOW: TKMPanel;
      Button_ShowStatsSpec: TKMButton;
      Dropbox_ReplayFOW: TKMDropList;
      Checkbox_ReplayFOW: TKMCheckBox;
      Label_PlayersColorMode: TKMLabel;
      Radio_PlayersColorMode: TKMRadioGroup;
    Panel_Allies: TKMPanel;
      Label_PeacetimeRemaining: TKMLabel;
      Image_AlliesHostStar: TKMImage;
      Image_AlliesMute: array [0..MAX_LOBBY_SLOTS-1] of TKMImage;
      Image_AlliesWinLoss: array [0..MAX_LOBBY_SLOTS-1] of TKMImage;
      Image_AlliesFlag: array [0..MAX_LOBBY_SLOTS-1] of TKMImage;
      Label_AlliesPlayer: array [0..MAX_LOBBY_SLOTS-1] of TKMLabel;
      DropBox_AlliesTeam: array [0..MAX_LOBBY_SLOTS-1] of TKMDropList;
      Label_AlliesTeam: array [0..MAX_LOBBY_SLOTS-1] of TKMLabel;
      Label_AlliesPing: array [0..MAX_LOBBY_SLOTS-1] of TKMLabel;
      Label_AlliesPingFpsSlash: array [0..MAX_LOBBY_SLOTS-1] of TKMLabel;
      Label_AlliesFPS: array [0..MAX_LOBBY_SLOTS-1] of TKMLabel;
      Image_AlliesClose: TKMImage;
    Panel_Message: TKMPanel;
      Label_MessageText: TKMLabel;
      Button_MessageGoTo: TKMButton;
      Button_MessageDelete: TKMButton;
      Image_MessageClose: TKMImage;
    Panel_MessageLog: TKMPanel;
      ColumnBox_MessageLog: TKMColumnBox;
      Image_MessageLogClose: TKMImage;
    Panel_Pause: TKMPanel;
      Bevel_Pause: TKMBevel;
      Image_Pause: TKMImage;
      Label_Pause1: TKMLabel;
      Label_Pause2: TKMLabel;
    Panel_PlayMore: TKMPanel;
      Bevel_PlayMore: TKMBevel;
      Panel_PlayMoreMsg: TKMPanel;
        Image_PlayMore: TKMImage;
        Label_PlayMore: TKMLabel;
        Button_PlayMore,Button_PlayQuit: TKMButton;
    Panel_MPPlayMore: TKMPanel;
      Bevel_MPPlayMore: TKMBevel;
      Image_MPPlayMore: TKMImage;
      Label_MPPlayMore: TKMLabel;
      Button_MPPlayMore,Button_MPPlayQuit: TKMButton;
    Panel_NetWait: TKMPanel;
      Bevel_NetWait: TKMBevel;
      Panel_NetWaitMsg: TKMPanel;
        Image_NetWait: TKMImage;
        Label_NetWait,Label_NetDropPlayersDelay: TKMLabel;
        Panel_NetWaitButtons: TKMPanel;
          Button_NetQuit,Button_NetDropPlayers: TKMButton;
        Panel_NetWaitConfirm: TKMPanel;
          Label_NetWaitConfirm: TKMLabel;
          Button_NetConfirmYes,Button_NetConfirmNo: TKMButton;
    Panel_Menu: TKMPanel;
      Button_Menu_Save, Button_Menu_Load, Button_Menu_ReturnLobby, Button_Menu_Settings, Button_Menu_Quit,
      Button_ShowStats: TKMButton;
      Label_GameTime, Label_MapName: TKMLabel;
      Panel_Track: TKMPanel;
        Label_Menu_Track: TKMLabel;
        Button_Menu_TrackUp, Button_Menu_TrackDown: TKMButton;

      Panel_Save: TKMPanel;
        ListBox_Save: TKMListBox;
        Edit_Save: TKMEdit;
        Label_SaveExists: TKMLabel;
        CheckBox_SaveExists: TKMCheckBox;
        Button_Save: TKMButton;

      Panel_Load: TKMPanel;
        ListBox_Load: TKMListBox;
        Label_LoadDescription: TKMLabel;
        Button_Load: TKMButton;

      Panel_Quit: TKMPanel;
        Label_QuitQuestion: TKMLabel;
        Button_Quit_Yes, Button_Quit_No: TKMButton;
        Button_ReturnToMapEd: TKMButton;

      function IsDragScrollingAllowed: Boolean; override;

      function GetToolBarWidth: Integer; override;
  public
    constructor Create(aRender: TRender; aUIMode: TUIMode); reintroduce;
    destructor Destroy; override;
    procedure MessageIssue(aKind: TKMMessageKind; const aText: UnicodeString); overload;
    procedure MessageIssue(aKind: TKMMessageKind; const aText: UnicodeString; const aLoc: TKMPoint); overload;
    procedure UpdateUI;
    procedure UpdateClock(aSpeedActual, aSpeedRecorded: Single; aShowRecorded: Boolean);
    procedure ShowPlayMore(DoShow: Boolean; Msg: TKMGameResultMsg);
    procedure ShowMPPlayMore(Msg: TKMGameResultMsg);
    procedure ShowNetworkLag(aShow: Boolean; aPlayers: TKMByteArray; IsHost: Boolean);
    procedure SetScriptedOverlay(const aText: UnicodeString);
    procedure UpdateOverlayControls;
    procedure ReleaseDirectionSelector;
    procedure ChatMessage(const aData: UnicodeString);
    procedure AlliesOnPlayerSetup;
    procedure AlliesOnPingInfo;
    procedure AlliesTeamChange(Sender: TObject);
    procedure CinematicUpdate;
    procedure LoadHotkeysFromHand;
    procedure UpdateReplayButtons(aPaused: Boolean);
    procedure AddReplayMark(aTick: Cardinal);
    procedure UpdateReplayMarks;

    property UIMode: TUIMode read fUIMode;

    procedure SetPause(aValue: Boolean);
    procedure GameStarted;

    property GuiGameResultsMP: TKMGameResultsMP read fGuiGameResultsMP;
    property GuiGameSpectator: TKMGUIGameSpectator read fGuiGameSpectator;

    function StatsOpened: Boolean;
    procedure SelectEntityByUID(aUID: Integer);

    property Alerts: TKMAlerts read fAlerts;

    procedure ExportPages(const aPath: string); override;
    procedure UpdateClockUI;

    procedure Save(SaveStream: TKMemoryStream);
    procedure SaveMinimap(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure LoadMinimap(LoadStream: TKMemoryStream);

    procedure KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean); override;
    procedure KeyUp(Key: Word; Shift: TShiftState; var aHandled: Boolean); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X,Y: Integer; var aHandled: Boolean); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X,Y: Integer); override;
    procedure Resize(X,Y: Word); override;
    procedure SyncUI(aMoveViewport: Boolean = True); override;
    procedure UpdateState(aTickCount: Cardinal); override;
    procedure UpdateStateIdle(aFrameTime: Cardinal); override;
    procedure Paint; override;
  end;


implementation
uses
  Generics.Collections,
  KM_Main, KM_GameInputProcess, KM_GameInputProcess_Multi, KM_AI, KM_RenderUI, KM_GameCursor, KM_Maps,
  KM_HandsCollection, KM_Hand, KM_RenderPool, KM_ResTexts, KM_Game, KM_GameApp, KM_HouseBarracks, KM_HouseTownHall,
  KM_ScriptingEvents, KM_AIFields, KM_GameSettings,
  KM_CommonUtils, KM_ResLocales, KM_ResSound, KM_Resource, KM_Log, KM_ResCursors, KM_ResFonts, KM_ResKeys,
  KM_Sound, KM_NetPlayersList, KM_MessageLog, KM_NetworkTypes,
  KM_InterfaceMapEditor, KM_HouseWoodcutters, KM_MapTypes,
  KM_GameTypes, KM_GameParams, KM_Video, KM_Music,
  KM_HandEntity,
  KM_HandEntityHelper,
  KM_ResTypes,
  KM_Utils;

const
  ALLIES_ROWS = 7;
  PANEL_ALLIES_WIDTH = 840;
  PANEL_TRACK_TOP = 285;
  REPLAYBAR_DEFAULT_WIDTH = 400;

  KEY_FUNCS_ALLOWED_ON_PAUSE: set of TKMKeyFunction = [kfMusicPrevTrack, kfMusicNextTrack, kfChat,
                                                       kfSpecpanelSelectDropbox, kfReplayPlayNextTick];


procedure TKMGamePlayInterface.Menu_Save_ListChange(Sender: TObject);
begin
  fSaves.Lock;
  try
    if InRange(TKMListBox(Sender).ItemIndex, 0, fSaves.Count-1) then
    begin
      fSave_Selected := TKMListBox(Sender).ItemIndex;
      Edit_Save.SetTextSilently(fSaves[ListBox_Save.ItemIndex].FileName);
      // We just selected something from the list so it exists
      CheckBox_SaveExists.Enabled := True;
      CheckBox_SaveExists.Checked := False;
      Label_SaveExists.Visible := True;
      Button_Save.Enabled := False;
    end;
  finally
    fSaves.Unlock;
  end;
end;


procedure TKMGamePlayInterface.Menu_Save_EditChange(Sender: TObject);
begin
  if (Sender <> fSaves) then
  begin
    ListBox_Save.ItemIndex := -1;
    fSave_Selected := -1;
    CheckBox_SaveExists.Enabled := FileExists(gGame.SaveName(Edit_Save.Text,
                                                             EXT_SAVE_MAIN,
                                                             (fUIMode in [umMP, umSpectate])
                                                             or (ALLOW_SAVE_IN_REPLAY and (gGameParams.Mode = gmReplayMulti))));
    Label_SaveExists.Visible := CheckBox_SaveExists.Enabled;
    CheckBox_SaveExists.Checked := False;
    // we should protect ourselves from empty names and whitespaces at beggining and at end of name
    Button_Save.Enabled := (not CheckBox_SaveExists.Enabled) and (Edit_Save.Text <> '') and
                           not (Edit_Save.Text[1] = ' ') and not (Edit_Save.Text[Length(Edit_Save.Text)] = ' ');
  end;
end;


procedure TKMGamePlayInterface.Menu_Save_CheckboxChange(Sender: TObject);
begin
  // we should protect ourselves from empty names and whitespaces at beggining and at end of name
  Button_Save.Enabled := CheckBox_SaveExists.Checked and (Edit_Save.Text <> '') and
                         not (Edit_Save.Text[1] = ' ') and not (Edit_Save.Text[Length(Edit_Save.Text)] = ' ');
end;


procedure TKMGamePlayInterface.Menu_Save_RefreshList(Sender: TObject);
var
  I, prevTop: Integer;
begin
  prevTop := ListBox_Save.TopIndex;
  ListBox_Save.Clear;

  if (Sender = fSaves) then
    Menu_Save_EditChange(fSaves)
  else
    Menu_Save_EditChange(nil);

  if (Sender = fSaves) then
  begin
    fSaves.Lock;
    try
      for I := 0 to fSaves.Count - 1 do
        ListBox_Save.Add(fSaves[i].FileName);
    finally
      fSaves.Unlock;
    end;
  end;

  ListBox_Save.ItemIndex := fSave_Selected;
  ListBox_Save.TopIndex := prevTop;
end;


procedure TKMGamePlayInterface.Menu_Save_Click(Sender: TObject);
var
  saveName: string;
begin
  saveName := Trim(Edit_Save.Text);
  // Edit.OnChange event happens on key up, so it's still possible for the user to click save button
  // with an invalid file name entered, if the click while still holding down a key.
  // In general it's bad to rely on events like that to ensure validity, doing check here is a good idea
  if saveName = '' then Exit;

  fLastSaveName := saveName; // Do this before saving so it is included in the save
  gGame.Save(saveName, UTCNow);

  fSaves.TerminateScan; // stop scan as it is no longer needed
  SwitchPage(nil); // Close save menu after saving
end;


procedure TKMGamePlayInterface.Menu_Load_ListClick(Sender: TObject);
begin
  fSaves.Lock;
  try
    Button_Load.Enabled := InRange(ListBox_Load.ItemIndex, 0, fSaves.Count - 1)
                           and fSaves[ListBox_Load.ItemIndex].IsValid;
    if InRange(ListBox_Load.ItemIndex, 0 ,fSaves.Count - 1) then
    begin
      Label_LoadDescription.Caption := fSaves[ListBox_Load.ItemIndex].GameInfo.GetTitleWithTime;
      fSave_Selected := ListBox_Load.ItemIndex;
    end;
  finally
    fSaves.Unlock;
  end;
end;


procedure TKMGamePlayInterface.Menu_Load_Click(Sender: TObject);
begin
  if not InRange(ListBox_Load.ItemIndex, 0, fSaves.Count - 1) then Exit;

  fSaves.TerminateScan; // Stop scan as it is no longer needed
  gGameApp.NewSingleSave(fSaves[ListBox_Load.ItemIndex].FileName);
end;


procedure TKMGamePlayInterface.Menu_Load_RefreshList(Sender: TObject);
var
  I, prevTop: Integer;
begin
  prevTop := ListBox_Load.TopIndex;
  ListBox_Load.Clear;

  if (Sender = fSaves) then
  begin
    fSaves.Lock;
    try
      for I := 0 to fSaves.Count - 1 do
        ListBox_Load.Add(fSaves[I].FileName);
    finally
      fSaves.Unlock;
    end;
  end;

  ListBox_Load.TopIndex := prevTop;
  ListBox_Load.ItemIndex := fSave_Selected;

  Menu_Load_ListClick(nil);
end;


procedure TKMGamePlayInterface.HidePages;
var
  I: Integer;
begin
  // Hide all existing pages
  for I := 0 to Panel_Controls.ChildCount - 1 do
    if (Panel_Controls.Childs[I] is TKMPanel) then
      Panel_Controls.Childs[I].Hide;

  fGuiGameBuild.Hide;
  fGuiGameHouse.Hide;
  fGuiGameRatios.Hide;
  fGuiGameStats.Hide;
  fGuiMenuSettings.Hide;
end;


procedure TKMGamePlayInterface.OpenMenuPage(aPage: TKMTabButtons);
begin
  if aPage = tbNone then
    SwitchPage(nil)
  else
    SwitchPage(Button_Main[aPage]);
end;


{ Switch between pages }
procedure TKMGamePlayInterface.SwitchPage(Sender: TObject);
var
  LastVisiblePage: TObject;

  procedure Flip4MainButtons(ShowEm: Boolean);
  var T: TKMTabButtons;
  begin
    for T := tbBuild to tbMenu do
      Button_Main[T].Visible := ShowEm;
    Button_Back.Visible := not ShowEm;
    Label_MenuTitle.Visible := not ShowEm;
  end;

begin
  if (Sender = Button_Main[tbBuild]) or (Sender = Button_Main[tbRatio])
    or (Sender = Button_Main[tbStats]) or (Sender = Button_Main[tbMenu])
    or (Sender = Button_Menu_Settings) or (Sender = Button_Menu_Quit) then
    gMySpectator.Selected := nil;

  // Set LastVisiblePage to which ever page was last visible, out of the ones needed
  if fGuiMenuSettings.Visible then LastVisiblePage := fGuiMenuSettings else
  if Panel_Save.Visible       then LastVisiblePage := Panel_Save     else
  if Panel_Load.Visible       then LastVisiblePage := Panel_Load     else
    LastVisiblePage := nil;

  // If they just closed settings then we should save them (if something has changed)
  if LastVisiblePage = fGuiMenuSettings then
    gGameSettings.SaveSettings;

  // Ensure, that saves scanning will be stopped when user leaves save/load page
  if (LastVisiblePage = Panel_Save) or (LastVisiblePage = Panel_Load) then
    fSaves.TerminateScan;

  HidePages;

  // If Sender is one of 4 main buttons, then open the page, hide the buttons and show Return button
  Flip4MainButtons(false);
  fOpenedMenu := tbNone;
  if Sender = Button_Main[tbBuild] then
  begin
    Label_MenuTitle.Caption := gResTexts[TX_MENU_TAB_BUILD];
    fGuiGameBuild.Show;
    fOpenedMenu := tbBuild;
  end else

  if Sender = Button_Main[tbRatio] then
  begin
    Label_MenuTitle.Caption := gResTexts[TX_MENU_TAB_DISTRIBUTE];
    fGuiGameRatios.Show;
    fOpenedMenu := tbRatio;
  end else

  if Sender = Button_Main[tbStats] then
  begin
    Label_MenuTitle.Caption := gResTexts[TX_MENU_TAB_STATISTICS];
    fGuiGameStats.Show;
    fOpenedMenu := tbStats;
  end else
  begin
    fOpenedMenu := tbMenu;
    if (Sender = Button_Main[tbMenu])
    or (Sender = Button_Quit_No)
    or ((Sender = Button_Back) and ((LastVisiblePage = fGuiMenuSettings)
                                 or (LastVisiblePage = Panel_Load)
                                 or (LastVisiblePage = Panel_Save))) then begin
      Menu_Update; // Make sure updating happens before it is shown
      Label_MenuTitle.Caption := gResTexts[TX_MENU_TAB_OPTIONS];
      Panel_Menu.Show;
    end else

    if Sender = Button_Menu_Save then
    begin
      fSave_Selected := -1;
      // Stop current now scan so it can't add a save after we clear the list
      fSaves.TerminateScan;
      Menu_Save_RefreshList(nil); // Need to call it at last one time to setup GUI even if there are no saves
      // Initiate refresh and process each new save added
      fSaves.Refresh(Menu_Save_RefreshList, (fUIMode in [umMP, umSpectate])
                                            or (ALLOW_SAVE_IN_REPLAY and (gGameParams.Mode = gmReplayMulti)));
      Panel_Save.Show;
      Label_MenuTitle.Caption := gResTexts[TX_MENU_SAVE_GAME];
      if fLastSaveName = '' then
        Edit_Save.Text := gGameParams.Name
      else
        Edit_Save.Text := fLastSaveName;
      Edit_Save.Focus;
      Menu_Save_EditChange(nil); // Displays "confirm overwrite" message if necessary
    end else

    if Sender = Button_Menu_Load then begin
      fSave_Selected := -1;
      // Stop current now scan so it can't add a save after we clear the list
      fSaves.TerminateScan;
      Menu_Load_RefreshList(nil); // Need to call it at least one time to setup GUI even if there are no saves
      // Initiate refresh and process each new save added
      fSaves.Refresh(Menu_Load_RefreshList, (fUIMode in [umMP, umSpectate]));
      Panel_Load.Show;
      Label_MenuTitle.Caption := gResTexts[TX_MENU_LOAD_GAME];
    end else

    if Sender = Button_Menu_Settings then begin
      fGuiMenuSettings.Refresh;
      fGuiMenuSettings.Show;
      Label_MenuTitle.Caption := gResTexts[TX_MENU_SETTINGS];
    end else

    if Sender = Button_Menu_Quit then
      Panel_Quit.Show
    else // If Sender is anything else - then show all 4 buttons and hide Return button
    begin
      Flip4MainButtons(True);
      fOpenedMenu := tbNone;
    end;
  end;
end;


procedure TKMGamePlayInterface.ShowStats(Sender: TObject);
begin
  StopPlay(grGameContinues);
end;


procedure TKMGamePlayInterface.ExportPages(const aPath: string);
var
  I, K: Integer;
  path: String;
begin
  inherited;

  path := aPath + 'Gameplay' + PathDelim;
  ForceDirectories(aPath);

  for I := 0 to Panel_Main.ChildCount - 1 do
    if (Panel_Main.Childs[I] is TKMPanel)
    and (Panel_Main.Childs[I].Width > 100) then
    begin
      // Hide all other panels
      for K := 0 to Panel_Main.ChildCount - 1 do
        if Panel_Main.Childs[K] is TKMPanel then
          Panel_Main.Childs[K].Hide;

      Panel_Main.Childs[I].Show;

      gGameApp.PrintScreen(aPath + 'Panel' + int2fix(I, 3) + '.jpg');
    end;
end;


// Update viewport position when user interacts with minimap
procedure TKMGamePlayInterface.Minimap_Update(Sender: TObject; const X,Y: Integer);
begin
  if gMySpectator.Hand.InCinematic then
    Exit;

  fViewport.Position := KMPointF(X,Y);
end;


procedure TKMGamePlayInterface.Minimap_RightClick(Sender: TObject; const X,Y:integer);
var
  loc: TKMPoint;
  group: TKMUnitGroup;
begin
  loc := MinimapView.LocalToMapCoords(X, Y);
  if not gTerrain.TileInMapCoords(loc.X, loc.Y) then Exit; // Must be inside map

  // Send move order, if applicable
  if (gMySpectator.Selected is TKMUnitGroup) and not fPlacingBeacon
    and (fUIMode in [umSP, umMP]) and not HasLostMPGame then
  begin
    group := TKMUnitGroup(gMySpectator.Selected);
    if group.CanTakeOrders and (group.Owner = gMySpectator.HandID)
      and group.CanWalkTo(loc, 0) then
    begin
      gGame.GameInputProcess.CmdArmy(gicArmyWalk, group, loc, dirNA);
      gSoundPlayer.PlayWarrior(group.UnitType, spMove);
    end;
  end;
  if  (gMySpectator.Selected is TKMHouseWFlagPoint)
    and not fPlacingBeacon
    and (fUIMode in [umSP, umMP]) and not HasLostMPGame then
  begin
    if gTerrain.Route_CanBeMade(TKMHouse(gMySpectator.Selected).PointBelowEntrance, loc, tpWalk, 0) then
    begin
      if gMySpectator.Selected is TKMHouseBarracks then
        gGame.GameInputProcess.CmdHouse(gicHouseBarracksRally, TKMHouse(gMySpectator.Selected), loc)
      else
      if gMySpectator.Selected is TKMHouseTownHall then
        gGame.GameInputProcess.CmdHouse(gicHouseTownHallRally, TKMHouse(gMySpectator.Selected), loc)
      else
        if gMySpectator.Selected is TKMHouseWoodcutters then
          gGame.GameInputProcess.CmdHouse(gicHouseWoodcuttersCutting, TKMHouse(gMySpectator.Selected), loc);
    end
    else
      gSoundPlayer.Play(sfxCantPlace, loc, False, 4);
  end;
end;


procedure TKMGamePlayInterface.Minimap_Click(Sender: TObject; const X,Y:integer);
begin
  if fPlacingBeacon then
    Beacon_Place(KMPointF(X,Y));
end;


procedure TKMGamePlayInterface.GameSettingsChanged;
begin
  //Update player color mode radio
  Radio_PlayersColorMode.ItemIndex := Byte(gGameSettings.PlayersColorMode) - 1;
  //Update minimap
  fMinimap.Update;
end;


procedure TKMGamePlayInterface.Replay_PlayersColorModeClick(Sender: TObject);
begin
  gGameSettings.PlayersColorMode := TKMPlayerColorMode(Radio_PlayersColorMode.ItemIndex + 1);
  fGuiMenuSettings.UpdateView; //Update settings
  //Update minimap
  fMinimap.Update;
end;


constructor TKMGamePlayInterface.Create(aRender: TRender; aUIMode: TUIMode);
const
  COLOR_B_SIZE = 20;
var
  I: Integer;
  S: TKMShape;
begin
  inherited Create(aRender);
  fUIMode := aUIMode;

  fAlerts := TKMAlerts.Create(fViewport);

  // Instruct to use global Terrain
  fLastSaveName := '';
  fLastKbdSelectionTime := 0;
  fPlacingBeacon := False;
  SelectingTroopDirection := False;
  SelectingDirPosition.X := 0;
  SelectingDirPosition.Y := 0;
  fShownMessage := -1; // 0 is the first message, -1 is invalid
  for I := Low(fSelection) to High(fSelection) do
    fSelection[I] := -1; // Not set

  fMessageStack := TKMMessageStack.Create;
  fSaves := TKMSavesCollection.Create;

  fUnitsTeamNames := TList.Create;
  fGroupsTeamNames := TList.Create;
  fHousesTeamNames := TList.Create;

  Label_TeamName := TKMLabel.Create(Panel_Main, 0, 0, '', fntGrey, taCenter);

  Sidebar_Top       := TKMImage.Create(Panel_Main, 0,    0, 224, 200, 407);
  Sidebar_Middle    := TKMImage.Create(Panel_Main, 0,  200, 224, 168, 554);

  MinimapView := TKMMinimapView.Create(Panel_Main, 10, 10, 176, 176);
  MinimapView.OnChange := Minimap_Update; // Allow dragging with LMB pressed
  MinimapView.OnClickRight := Minimap_RightClick;
  MinimapView.OnMinimapClick := Minimap_Click; // For placing beacons

  Image_Clock := TKMImage.Create(Panel_Main,232,8,67,65,556);
  Image_Clock.Hide;
  Label_Clock := TKMLabel.Create(Panel_Main,265,80,'mm:ss',fntOutline,taCenter);
  Label_Clock.Hide;
  Label_ClockSpeedActual := TKMLabel.Create(Panel_Main,265,48,'x1',fntMetal,taCenter);
  Label_ClockSpeedActual.Hide;
  Label_ClockSpeedRecorded := TKMLabel.Create(Panel_Main,265,68,'x1',fntGrey,taCenter);
  Label_ClockSpeedRecorded.Hide;

  Create_ScriptingOverlay; // Scripting Overlay controls

  Image_DirectionCursor := TKMImage.Create(Panel_Main,0,0,35,36,519);
  Image_DirectionCursor.Hide;

  // Debugging displays
  Bevel_DebugInfo := TKMBevel.Create(Panel_Main,224+8-10,133-10,Panel_Main.Width - 224 - 8, 0);
  Bevel_DebugInfo.BackAlpha := 0.5;
  Bevel_DebugInfo.Hitable := False;
  Bevel_DebugInfo.Hide;
  Label_DebugInfo := TKMLabel.Create(Panel_Main, 224+8, 133, '', fntMini, taLeft);
  Label_DebugInfo.Monospaced := True;
  Label_DebugInfo.Hide;

{ I plan to store all possible layouts on different pages which gets displayed one at a time }
{ ========================================================================================== }
  Create_Controls; // Includes all the child pages

  Create_NetWait; // Overlay blocking everyhitng but sidestack and messages
  Create_Allies; // MessagePage sibling

  // On top of NetWait to allow players to chat while waiting for late opponents
  fGuiGameChat := TKMGUIGameChat.Create(Panel_Main, fUIMode, ChatMessage);

  Create_Message; // Must go bellow message stack
  Create_MessageLog; // Must go bellow message stack
  Create_MessageStack; // Messages, Allies, Chat icons

  Create_Pause;
  Create_Replay; // Replay controls
  Create_PlayMore; // Must be created last, so that all controls behind are blocked
  Create_MPPlayMore;

  if OVERLAY_RESOLUTIONS then
  begin
    S := TKMShape.Create(Panel_Main, 0, 96, 1024, 576);
    S.LineColor := $FF00FFFF;
    S.LineWidth := 1;
    S.Hitable := False;
    S := TKMShape.Create(Panel_Main, 0, 0, 1024, 768);
    S.LineColor := $FF00FF00;
    S.LineWidth := 1;
    S.Hitable := False;
  end;

  Panel_Stats := TKMPanel.Create(Panel_Main, (aRender.ScreenX - MENU_DESIGN_X) div 2, (aRender.ScreenY - MENU_DESIGN_Y) div 2, MENU_DESIGN_X, MENU_DESIGN_Y);
  Panel_Stats.AnchorsCenter;

  // Background image

  Panel_Stats_Background := TKMImage.Create(Panel_Stats, 0, 0, 700, 800, 17, rxGuiMain);
  Panel_Stats_Background.Tiled := True;
  TKMImage.Create(Panel_Stats, -18, -18, 1071, 822, 18, rxGuiMain).AnchorsCenter;

  Panel_Stats.Hide;

  fGuiGameResultsSP := TKMGameResultsSP.Create(Panel_Stats, StopGame, ShowMPStats);
  fGuiGameResultsSP.Hide;
  fGuiGameResultsMP := TKMGameResultsMP.Create(Panel_Stats, StopGame, ShowSPStats);
  fGuiGameResultsMP.Hide;

  SwitchPage(nil); // Update
  Resize(aRender.ScreenX, aRender.ScreenY); // Hide/show swords according to player's resolution when game starts
  // Panel_Main.Width := aScreenX;
  // Panel_Main.Height := aScreenY;
  // UpdatePositions; //Reposition messages stack etc.

  AfterCreateComplete;
end;


destructor TKMGamePlayInterface.Destroy;
begin
  ReleaseDirectionSelector; // Make sure we don't exit leaving the cursor restrained

  fGuiGameBuild.Free;
  fGuiGameChat.Free;
  fGuiGameHouse.Free;
  fGuiGameUnit.Free;
  fGuiGameRatios.Free;
  fGuiGameStats.Free;
  fGuiMenuSettings.Free;
  fGuiGameResultsSP.Free;
  fGuiGameResultsMP.Free;
  if Assigned(fGuiGameSpectator) then
    fGuiGameSpectator.Free;

  fMessageStack.Free;
  fSaves.Free;
  FreeAndNil(fHousesTeamNames);
  FreeAndNil(fGroupsTeamNames);
  FreeAndNil(fUnitsTeamNames);
  fAlerts.Free;
  inherited;
end;


procedure TKMGamePlayInterface.UpdateReplayBar;
begin
  if fGuiGameSpectator <> nil then
    Panel_ReplayBar.Width := fGuiGameSpectator.DropBox.AbsLeft - Panel_ReplayBar.AbsLeft - 10
  else
    Panel_ReplayBar.Width := REPLAYBAR_DEFAULT_WIDTH;
end;


procedure TKMGamePlayInterface.Resize(X,Y: Word);
var
  showSwords: Boolean;
begin
  inherited;

  // Show swords filler if screen height allows
  showSwords := (Panel_Main.Height >= 758);
  Sidebar_Middle.Visible := showSwords;

  Panel_Stats.Top := (Panel_Main.Height - Panel_Stats.Height) div 2;
  Panel_Stats.Height := Min(Panel_Main.Height, MENU_DESIGN_Y);

  Panel_Stats_Background.Left := -Panel_Stats.Left;
  Panel_Stats_Background.Top := -Panel_Stats.Top;
  Panel_Stats_Background.Width := X;
  Panel_Stats_Background.Height := Y;

  // Needs to be -10 when the swords are hidden so it fits 1024x576
  Panel_Controls.Top := Sidebar_Top.Height - 10 + (10+Sidebar_Middle.Height) * Byte(showSwords);
  Panel_Controls.Height := Panel_Main.Height - Panel_Controls.Top;

  if fGuiGameStats.Visible then
    fGuiGameStats.Resize;

  UpdateReplayBar;

  fViewport.Resize(X, Y);
end;


{ Pause overlay page }
procedure TKMGamePlayInterface.Create_Pause;
begin
  Panel_Pause := TKMPanel.Create(Panel_Main, 0, 0, Panel_Main.Width, Panel_Main.Height);
  Panel_Pause.AnchorsStretch;
  Bevel_Pause := TKMBevel.Create(Panel_Pause, -1, -1, Panel_Main.Width + 2, Panel_Main.Height + 2);
  Image_Pause := TKMImage.Create(Panel_Pause, (Panel_Main.Width div 2), (Panel_Main.Height div 2) - 40, 0, 0, 556);
  Label_Pause1 := TKMLabel.Create(Panel_Pause, (Panel_Main.Width div 2), (Panel_Main.Height div 2),
    gResTexts[TX_POPUP_PAUSE], fntAntiqua, taCenter);
  Label_Pause2 := TKMLabel.Create(Panel_Pause, (Panel_Main.Width div 2), (Panel_Main.Height div 2) + 20,
    Format(gResTexts[TX_GAMEPLAY_PAUSE_INFO], ['"P"']), fntGrey, taCenter);
  Bevel_Pause.AnchorsStretch; // Anchor to all sides
  Image_Pause.ImageCenter;
  Label_Pause1.AnchorsCenter;
  Label_Pause2.AnchorsCenter;
  Image_Pause.AnchorsCenter;
  Panel_Pause.Hide
end;


{ Play More overlay page,
  It's backgrounded with a full-screen bevel area which not only fades image a bit,
  but also blocks all mouse clicks - neat }
procedure TKMGamePlayInterface.Create_PlayMore;
begin
  Panel_PlayMore := TKMPanel.Create(Panel_Main,0,0,Panel_Main.Width,Panel_Main.Height);
  Panel_PlayMore.AnchorsStretch;
    Bevel_PlayMore := TKMBevel.Create(Panel_PlayMore,-1,-1,Panel_Main.Width+2,Panel_Main.Height+2);
    Bevel_PlayMore.AnchorsStretch;

    Panel_PlayMoreMsg := TKMPanel.Create(Panel_PlayMore,(Panel_Main.Width div 2)-100,(Panel_Main.Height div 2)-100,200,200);
    Panel_PlayMoreMsg.AnchorsCenter;
      Image_PlayMore := TKMImage.Create(Panel_PlayMoreMsg,100,40,0,0,556);
      Image_PlayMore.ImageCenter;

      Label_PlayMore  := TKMLabel.Create(Panel_PlayMoreMsg,100,80,NO_TEXT,fntOutline,taCenter);
      Button_PlayMore := TKMButton.Create(Panel_PlayMoreMsg,0,100,200,30,NO_TEXT,bsGame);
      Button_PlayQuit := TKMButton.Create(Panel_PlayMoreMsg,0,140,200,30,NO_TEXT,bsGame);
      Button_PlayMore.OnClick := PlayMoreClick;
      Button_PlayQuit.OnClick := PlayMoreClick;
    Panel_PlayMore.Hide; // Initially hidden
end;


procedure TKMGamePlayInterface.Create_MPPlayMore;
begin
  Panel_MPPlayMore := TKMPanel.Create(Panel_Main,(Panel_Main.Width div 2)-200,(Panel_Main.Height div 2)-100,400,200);
  Panel_MPPlayMore.AnchorsCenter;
    Bevel_MPPlayMore := TKMBevel.Create(Panel_MPPlayMore,-1,-1,Panel_MPPlayMore.Width+2,Panel_MPPlayMore.Height+2);
    Bevel_MPPlayMore.AnchorsStretch;

      Image_MPPlayMore := TKMImage.Create(Panel_MPPlayMore,200,40,0,0,556);
      Image_MPPlayMore.ImageCenter;

      Label_MPPlayMore  := TKMLabel.Create(Panel_MPPlayMore,200,80,NO_TEXT,fntOutline,taCenter);
      Button_MPPlayMore := TKMButton.Create(Panel_MPPlayMore,100,100,200,30,NO_TEXT,bsGame);
      Button_MPPlayQuit := TKMButton.Create(Panel_MPPlayMore,100,140,200,30,NO_TEXT,bsGame);
      Button_MPPlayMore.OnClick := MPPlayMoreClick;
      Button_MPPlayQuit.OnClick := MPPlayMoreClick;
    Panel_MPPlayMore.Hide; // Initially hidden
end;


// Waiting for Net events page, it's similar to PlayMore, but is layered differentlybelow chat panel
procedure TKMGamePlayInterface.Create_NetWait;
begin
  Panel_NetWait := TKMPanel.Create(Panel_Main,0,0,Panel_Main.Width,Panel_Main.Height);
  Panel_NetWait.AnchorsStretch;
    Bevel_NetWait := TKMBevel.Create(Panel_NetWait,-1,-1,Panel_Main.Width+2,Panel_Main.Height+2);
    Bevel_NetWait.AnchorsStretch;

    Panel_NetWaitMsg := TKMPanel.Create(Panel_NetWait,0,(Panel_Main.Height div 2)-200,Panel_Main.Width,400);
    Panel_NetWaitMsg.AnchorsCenter;
      Image_NetWait := TKMImage.Create(Panel_NetWaitMsg,Panel_Main.Width div 2,40,0,0,556);
      Image_NetWait.ImageCenter;

      Label_NetWait  := TKMLabel.Create(Panel_NetWaitMsg,Panel_Main.Width div 2,77,NO_TEXT,fntOutline,taCenter);
      Label_NetDropPlayersDelay := TKMLabel.Create(Panel_NetWaitMsg,Panel_Main.Width div 2,115,NO_TEXT,fntOutline,taCenter);
      Panel_NetWaitButtons := TKMPanel.Create(Panel_NetWaitMsg,0,140,Panel_Main.Width,80);
        Button_NetQuit := TKMButton.Create(Panel_NetWaitButtons,(Panel_Main.Width div 2)-150,0,300,30,gResTexts[TX_GAMEPLAY_QUIT_TO_MENU],bsGame);
        Button_NetQuit.OnClick := NetWaitClick;
        Button_NetDropPlayers := TKMButton.Create(Panel_NetWaitButtons,(Panel_Main.Width div 2)-150,40,300,30,gResTexts[TX_GAMEPLAY_DROP_PLAYERS],bsGame);
        Button_NetDropPlayers.OnClick := NetWaitClick;

      Panel_NetWaitConfirm := TKMPanel.Create(Panel_NetWaitMsg,0,180,Panel_Main.Width,140);
        Label_NetWaitConfirm := TKMLabel.Create(Panel_NetWaitConfirm,(Panel_Main.Width div 2),10,NO_TEXT,fntOutline,taCenter);
        Button_NetConfirmYes := TKMButton.Create(Panel_NetWaitConfirm,(Panel_Main.Width div 2)-150,40,300,30,NO_TEXT,bsGame);
        Button_NetConfirmYes.OnClick := NetWaitClick;
        Button_NetConfirmNo := TKMButton.Create(Panel_NetWaitConfirm,(Panel_Main.Width div 2)-150,80,300,30,gResTexts[TX_GAMEPLAY_CONFIRM_CANCEL],bsGame);
        Button_NetConfirmNo.OnClick := NetWaitClick;
      Panel_NetWaitConfirm.Hide;
    Panel_NetWait.Hide; // Initially hidden
end;


procedure TKMGamePlayInterface.Create_MessageStack;
var
  I: Integer;
begin
  Image_Chat := TKMImage.Create(Panel_Main,TOOLBAR_WIDTH,Panel_Main.Height-48,30,48,494);
  Image_Chat.Anchors := [anLeft, anBottom];
  Image_Chat.HighlightOnMouseOver := true;
  Image_Chat.Hint := gResTexts[TX_GAMEPLAY_CHAT_HINT];
  Image_Chat.OnClick := Chat_Click;
  Label_ChatUnread := TKMLabel.Create(Panel_Main,TOOLBAR_WIDTH,Panel_Main.Height-30,30,36,'',fntOutline,taCenter);
  Label_ChatUnread.FontColor := $FF0000FF; // Red
  Label_ChatUnread.Anchors := [anLeft, anBottom];
  Label_ChatUnread.Hitable := false; // Clicks should only go to the image, not the flashing label
  Label_ChatUnread.AutoWrap := true;

  Image_MPAllies := TKMImage.Create(Panel_Main,TOOLBAR_WIDTH,Panel_Main.Height-48*2,30,48,496);
  Image_MPAllies.Anchors := [anLeft, anBottom];
  Image_MPAllies.HighlightOnMouseOver := True;
  Image_MPAllies.Hint := gResTexts[TX_GAMEPLAY_PLAYERS_HINT];
  Image_MPAllies.OnClick := Allies_Click;

  Image_MessageLog := TKMImage.Create(Panel_Main,TOOLBAR_WIDTH,Panel_Main.Height - 48 - IfThen(fUIMode in [umMP, umSpectate], 48*2),30,48,495);
  Image_MessageLog.Anchors := [anLeft, anBottom];
  Image_MessageLog.HighlightOnMouseOver := true;
  Image_MessageLog.Hint := gResTexts[TX_GAME_MESSAGE_LOG];
  Image_MessageLog.OnClick := MessageLog_Click;
  Image_MessageLog.Hide; // Will be shows on first message

  for I := 0 to MAX_VISIBLE_MSGS do
  begin
    Image_Message[I] := TKMImage.Create(Panel_Main, TOOLBAR_WIDTH, 0, 30, 48, 495);
    Image_Message[I].Top := Panel_Main.Height - 48 - I * 48 - IfThen(fUIMode in [umMP, umSpectate], 48 * 2);
    Image_Message[I].Anchors := [anLeft, anBottom];
    Image_Message[I].Disable;
    Image_Message[I].Hide;
    Image_Message[I].HighlightOnMouseOver := True;
    Image_Message[I].Tag := I;
    Image_Message[I].OnClickShift := Message_Click;
  end;
end;


procedure TKMGamePlayInterface.Create_Replay;
begin
  Panel_ReplayBar := TKMPanel.Create(Panel_Main, 320, 5, REPLAYBAR_DEFAULT_WIDTH, 25);
    ReplayBar_Replay := TKMReplayBar.Create(Panel_ReplayBar, 0, 0, REPLAYBAR_DEFAULT_WIDTH, 25);
    ReplayBar_Replay.AnchorsStretch;
    Label_ReplayBar  := TKMLabel.Create(Panel_ReplayBar, ReplayBar_Replay.Width div 2,
                                                         ReplayBar_Replay.Height div 2 - 7, NO_TEXT, fntGrey, taCenter);
    Label_ReplayBar.AnchorsCenter;

    ReplayBar_Replay.OnMarkClick := ReplayMarkClick;
    ReplayBar_Replay.HintResText := TX_REPLAY_LOAD_AT_HINT;

  Panel_ReplayFOW := TKMPanel.Create(Panel_Main, 320, 8+29, 400, 80);
    Button_ShowStatsSpec  := TKMButton.Create(Panel_ReplayFOW, 0, 4, 22, 22, 669, rxGui, bsGame);
    Button_ShowStatsSpec.OnClick := ShowStats;
    Button_ShowStatsSpec.Hint := gResTexts[TX_GAME_MENU_SHOW_STATS_HINT];

    Checkbox_ReplayFOW := TKMCheckBox.Create(Panel_ReplayFOW, 27, 7, 200-27, 20, gResTexts[TX_REPLAY_SHOW_FOG], fntMetal);
    Checkbox_ReplayFOW.OnClick := ReplayClick;

    Label_PlayersColorMode := TKMLabel.Create(Panel_ReplayFOW, 200, 5, 200, 20, gResTexts[TX_PLAYERS_COLOR_MODE_CAPTION], fntMetal, taLeft);

    Radio_PlayersColorMode := TKMRadioGroup.Create(Panel_ReplayFOW,200,25,200,60,fntMetal);
      Radio_PlayersColorMode.Anchors := [anLeft, anBottom];
    Radio_PlayersColorMode.ItemIndex := 0;
    Radio_PlayersColorMode.Add(gResTexts[TX_PLAYERS_COLOR_MODE_DEFAULT], gResTexts[TX_PLAYERS_COLOR_MODE_DEFAULT_HINT]);
    Radio_PlayersColorMode.Add(gResTexts[TX_PLAYERS_COLOR_MODE_ALLY_ENEMY], gResTexts[TX_PLAYERS_COLOR_MODE_ALLY_ENEMY_HINT]);
    Radio_PlayersColorMode.Add(gResTexts[TX_PLAYERS_COLOR_MODE_TEAMS], gResTexts[TX_PLAYERS_COLOR_MODE_TEAMS_HINT]);
    Radio_PlayersColorMode.OnChange := Replay_PlayersColorModeClick;

    Dropbox_ReplayFOW := TKMDropList.Create(Panel_ReplayFOW, 0, 30, 185, 20, fntMetal, '', bsGame, False, 0.5);
    Dropbox_ReplayFOW.Hint := gResTexts[TX_REPLAY_PLAYER_PERSPECTIVE];
    Dropbox_ReplayFOW.OnChange := ReplayClick;
    Dropbox_ReplayFOW.DropCount := MAX_HANDS; //There could be only AI hands as well, not only Lobby players
    Dropbox_ReplayFOW.List.AutoFocusable := False;
    Dropbox_ReplayFOW.List.OnKeyUp := Replay_ListKeyUp;
    Dropbox_ReplayFOW.List.OnDoubleClick := Replay_ListDoubleClick;
    Dropbox_ReplayFOW.List.SeparatorHeight := 4;
    Dropbox_ReplayFOW.List.SeparatorColor := $C0606060;

  Panel_ReplayCtrl := TKMPanel.Create(Panel_Main, 320, 8+29, 185, 24);

    Button_ReplayRestart    := TKMButton.Create(Panel_ReplayCtrl,  0, 0, 24, 24, 582, rxGui, bsGame);
    Button_ReplayPause      := TKMButton.Create(Panel_ReplayCtrl, 25, 0, 24, 24, 583, rxGui, bsGame);
    Button_ReplayStep       := TKMButton.Create(Panel_ReplayCtrl, 50, 0, 24, 24, 584, rxGui, bsGame);
    Button_ReplayResume     := TKMButton.Create(Panel_ReplayCtrl, 75, 0, 24, 24, 585, rxGui, bsGame);
    Button_ReplayExit       := TKMButton.Create(Panel_ReplayCtrl,100, 0, 24, 24, 586, rxGui, bsGame);
    Button_ReplaySaveAt     := TKMButton.Create(Panel_ReplayCtrl,125, 0, 24, 24, 592, rxGui, bsGame);

    Button_ShowStatsReplay  := TKMButton.Create(Panel_ReplayCtrl, 185 - 24, 0, 24, 24, 669, rxGui, bsGame);
    //TODO: Button_ReplayFF       := TKMButton.Create(Panel_ReplayCtrl,125, 24, 24, 24, 393, rxGui, bsGame);
    Button_ReplayRestart.OnClick := ReplayClick;
    Button_ReplayPause.OnClick   := ReplayClick;
    Button_ReplayStep.OnClick    := ReplayClick;
    Button_ReplayResume.OnClick  := ReplayClick;
    Button_ReplayExit.OnClick    := ReplayClick;
    Button_ReplaySaveAt.OnClick  := ReplayClick;
    Button_ReplayRestart.Hint := gResTexts[TX_REPLAY_RESTART];
    Button_ReplayPause.Hint   := gResTexts[TX_REPLAY_PAUSE];
    Button_ReplayStep.Hint    := gResTexts[TX_REPLAY_STEP];
    Button_ReplayResume.Hint  := gResTexts[TX_REPLAY_RESUME];
    Button_ReplayExit.Hint    := gResTexts[TX_REPLAY_QUIT];
    Button_ReplaySaveAt.Hint  := gResTexts[TX_REPLAY_SAVE_AT];

    Button_ShowStatsReplay.OnClick := ShowStats;
    Button_ShowStatsReplay.Hint := gResTexts[TX_GAME_MENU_SHOW_STATS_HINT];

    Button_ReplayStep.Disable; // Initial state
    Button_ReplayResume.Disable; // Initial state
 end;


procedure TKMGamePlayInterface.Create_ScriptingOverlay;
begin
  Label_ScriptedOverlay := TKMLabel.Create(Panel_Main, 260, 110, '', fntMetal, taLeft);

  Button_ScriptedOverlay := TKMButton.Create(Panel_Main, 260, 92, 15, 15, '', bsGame);
  Button_ScriptedOverlay.Hint := gResTexts[TX_GAMEPLAY_OVERLAY_HIDE];
  Button_ScriptedOverlay.Hide;
  Button_ScriptedOverlay.OnClick := HideOverlay;

  Label_OverlayHide := TKMLabel.Create(Panel_Main,263,91,'-',fntMetal,taLeft);
  Label_OverlayShow := TKMLabel.Create(Panel_Main,263,93,'+',fntMetal,taLeft);
  Label_OverlayHide.Hitable := False;
  Label_OverlayShow.Hitable := False;
  Label_OverlayHide.Hide;
  Label_OverlayShow.Hide;
end;


// Individual message page
procedure TKMGamePlayInterface.Create_Message;
begin
  Panel_Message := TKMPanel.Create(Panel_Main, TOOLBAR_WIDTH, Panel_Main.Height - MESSAGE_AREA_HEIGHT, 600, MESSAGE_AREA_HEIGHT);
  Panel_Message.Anchors := [anLeft, anBottom];
  Panel_Message.Hide; // Hide it now because it doesn't get hidden by SwitchPage

    TKMImage.Create(Panel_Message, 0, 0, 600, 500, 409);

    Label_MessageText := TKMLabel.Create(Panel_Message, 47, 58, 432, 112, '', fntAntiqua, taLeft);
    Label_MessageText.AutoWrap := True;

    Button_MessageGoTo := TKMButton.Create(Panel_Message, 490, 74, 100, 24, gResTexts[TX_MSG_GOTO], bsGame);
    Button_MessageGoTo.Font := fntAntiqua;
    Button_MessageGoTo.Hint := gResTexts[TX_MSG_GOTO_HINT];
    Button_MessageGoTo.OnClick := Message_GoTo;

    Button_MessageDelete := TKMButton.Create(Panel_Message, 490, 104, 100, 24, gResTexts[TX_MSG_DELETE], bsGame);
    Button_MessageDelete.Font := fntAntiqua;
    Button_MessageDelete.Hint := gResTexts[TX_MSG_DELETE_HINT];
    Button_MessageDelete.OnClick := Message_DeleteClick;
    Button_MessageDelete.MakesSound := False; // Don't play default Click as these buttons use sfxMessageClose

    Image_MessageClose := TKMImage.Create(Panel_Message, 600 - 76, 24, 32, 32, 52);
    Image_MessageClose.Anchors := [anTop, anLeft];
    Image_MessageClose.Hint := gResTexts[TX_MSG_CLOSE_HINT];
    Image_MessageClose.OnClick := Message_Close;
    Image_MessageClose.HighlightOnMouseOver := True;
end;


// Message log page
// there's a queue of not-that-important messages
procedure TKMGamePlayInterface.Create_MessageLog;
var
  I, H: Integer;
begin
  H := 20 * MAX_LOG_MSGS + 2; // +2 for some margin at the bottom

  Panel_MessageLog := TKMPanel.Create(Panel_Main, TOOLBAR_WIDTH, Panel_Main.Height - (H + 65 + 20), 600, H + 65 + 20);
  Panel_MessageLog.Anchors := [anLeft, anBottom];
  Panel_MessageLog.Hide; // Hide it now because it doesn't get hidden by SwitchPage

    TKMImage.Create(Panel_MessageLog, 0, 0, 600, 500, 409);

    Image_MessageLogClose := TKMImage.Create(Panel_MessageLog, 600 - 76, 24, 32, 32, 52);
    Image_MessageLogClose.Anchors := [anTop, anLeft];
    Image_MessageLogClose.Hint := gResTexts[TX_MSG_CLOSE_HINT];
    Image_MessageLogClose.OnClick := MessageLog_Close;
    Image_MessageLogClose.HighlightOnMouseOver := True;

    ColumnBox_MessageLog := TKMColumnBox.Create(Panel_MessageLog, 45, 60, 600 - 90, H, fntGrey, bsGame);
    ColumnBox_MessageLog.AnchorsStretch;
    ColumnBox_MessageLog.SetColumns(fntOutline, ['Icon', 'Message'], [0, 25]);
    ColumnBox_MessageLog.ShowHeader := False;
    ColumnBox_MessageLog.HideSelection := True;
    ColumnBox_MessageLog.HighlightOnMouseOver := True;
    ColumnBox_MessageLog.ItemHeight := 20;
    ColumnBox_MessageLog.BackAlpha := 0;
    ColumnBox_MessageLog.EdgeAlpha := 0;
    ColumnBox_MessageLog.OnCellClickShift := MessageLog_ItemClick;
    for I := 0 to MAX_LOG_MSGS - 1 do
      ColumnBox_MessageLog.AddItem(MakeListRow(['', ''], -1));
end;


procedure TKMGamePlayInterface.Create_Controls;
const
  MAIN_BTN_HINT: array [tbBuild..tbMenu] of Word = (
    TX_MENU_TAB_HINT_BUILD,
    TX_MENU_TAB_HINT_DISTRIBUTE,
    TX_MENU_TAB_HINT_STATISTICS,
    TX_MENU_TAB_HINT_OPTIONS);
var
  I: Integer;
  T: TKMTabButtons;
begin
  Panel_Controls := TKMPanel.Create(Panel_Main, 0, 368, 224, 376);
  // Resized manually on .Resize to be most efficient in space management

    // We need several of these to cover max of 1534x2560 (vertically oriented)
    SetLength(Sidebar_Bottom, 6);
    for I := Low(Sidebar_Bottom) to High(Sidebar_Bottom) do
      Sidebar_Bottom[I] := TKMImage.Create(Panel_Controls, 0, 400*I, 224, 400, 404);

    // Main 4 buttons
    for T := tbBuild to tbMenu do begin
      Button_Main[T] := TKMButton.Create(Panel_Controls,  TB_PAD + 46 * Byte(T), 4, 42, 36, 439 + Byte(T), rxGui, bsGame);
      Button_Main[T].Hint := gResTexts[MAIN_BTN_HINT[T]];
      Button_Main[T].OnClick := SwitchPage;
    end;
    Button_Back := TKMButton.Create(Panel_Controls, TB_PAD, 4, 42, 36, 443, rxGui, bsGame);
    Button_Back.OnClick := SwitchPage;
    Button_Back.Hint := gResTexts[TX_MENU_TAB_HINT_GO_BACK];

    Label_MenuTitle := TKMLabel.Create(Panel_Controls, 54, 4, 138, 0, '', fntMetal, taLeft);
    Label_MenuTitle.AutoWrap := True;

  fGuiGameBuild := TKMGUIGameBuild.Create(Panel_Controls);
  fGuiGameRatios := TKMGUIGameRatios.Create(Panel_Controls, fUIMode in [umSP, umMP]);
  fGuiGameStats := TKMGUIGameStats.Create(Panel_Controls, ShowStats, SetViewportPos);
  Create_Menu;
    Create_Save;
    Create_Load;
    fGuiMenuSettings := TKMGameMenuSettings.Create(Panel_Controls, GameSettingsChanged);
    Create_Quit;

  fGuiGameUnit := TKMGUIGameUnit.Create(Panel_Controls, SetViewportPos);
  fGuiGameUnit.OnUnitDismiss := Reset_Menu;
  fGuiGameUnit.OnArmyCanTakeOrder := ArmyCanTakeOrder;
  fGuiGameUnit.OnSelectingTroopDirection := IsSelectingTroopDirection;
  fGuiGameHouse := TKMGUIGameHouse.Create(Panel_Controls, SetViewportPos);
  fGuiGameHouse.OnHouseDemolish := House_Demolish;
end;


{ Allies page }
procedure TKMGamePlayInterface.Create_Allies;
const
  LINE_W = 395;
var
  I, K: Integer;
begin
  Panel_Allies := TKMPanel.Create(Panel_Main, TOOLBAR_WIDTH, Panel_Main.Height - MESSAGE_AREA_HEIGHT - 50,
                                                             PANEL_ALLIES_WIDTH, MESSAGE_AREA_HEIGHT + 50);
  Panel_Allies.Anchors := [anLeft, anBottom];
  Panel_Allies.Hide;

    with TKMImage.Create(Panel_Allies,0,0,PANEL_ALLIES_WIDTH,190,409) do ImageAnchors := [anLeft, anRight, anTop];

    Label_PeacetimeRemaining := TKMLabel.Create(Panel_Allies,400,15,'',fntOutline,taCenter);
    Image_AlliesHostStar := TKMImage.Create(Panel_Allies, 50, 82, 20, 20, 77, rxGuiMain);
    Image_AlliesHostStar.Hint := gResTexts[TX_PLAYER_HOST];
    Image_AlliesHostStar.Hide;

    for I := 0 to MAX_LOBBY_SLOTS - 1 do
    begin
      if (I mod ALLIES_ROWS) = 0 then // Header for each column
      begin
        TKMLabel.Create(Panel_Allies, 80+(I div ALLIES_ROWS)*LINE_W, 60, 140, 20, gResTexts[TX_LOBBY_HEADER_PLAYERS], fntOutline, taLeft);
        TKMLabel.Create(Panel_Allies, 230+(I div ALLIES_ROWS)*LINE_W, 60, 140, 20, gResTexts[TX_LOBBY_HEADER_TEAM], fntOutline, taLeft);
        TKMLabel.Create(Panel_Allies, 360+(I div ALLIES_ROWS)*LINE_W, 60, gResTexts[TX_LOBBY_HEADER_PINGFPS], fntOutline, taCenter);
      end;

      Image_AlliesWinLoss[I] := TKMImage.Create(Panel_Allies, 42 +(I div ALLIES_ROWS)*LINE_W, 81+(I mod ALLIES_ROWS)*20, 16, 16, 0, rxGuiMain);
      Image_AlliesWinLoss[I].Hide;

      Image_AlliesMute[I] := TKMImage.Create(Panel_Allies, 45 + 15 +(I div ALLIES_ROWS)*LINE_W, 82+(I mod ALLIES_ROWS)*20, 11, 11, 0, rxGuiMain);
      Image_AlliesMute[I].OnClick := Allies_Mute;
      Image_AlliesMute[I].Tag := I;
      Image_AlliesMute[I].HighlightOnMouseOver := True;
      Image_AlliesMute[I].Hide;

      Image_AlliesFlag[I] := TKMImage.Create(Panel_Allies,     15 + 60+(I div ALLIES_ROWS)*LINE_W, 82+(I mod ALLIES_ROWS)*20, 16,  11,  0, rxGuiMain);
      Label_AlliesPlayer[I] := TKMLabel.Create(Panel_Allies,   15 + 80+(I div ALLIES_ROWS)*LINE_W, 80+(I mod ALLIES_ROWS)*20, 140, 20, '', fntGrey, taLeft);
      Label_AlliesTeam[I]   := TKMLabel.Create(Panel_Allies,   15 + 230+(I div ALLIES_ROWS)*LINE_W, 80+(I mod ALLIES_ROWS)*20, 120, 20, '', fntGrey, taLeft);
      DropBox_AlliesTeam[I] := TKMDropList.Create(Panel_Allies,15 + 230+(I div ALLIES_ROWS)*LINE_W, 80+(I mod ALLIES_ROWS)*20, 120, 20, fntGrey, '', bsGame);
      DropBox_AlliesTeam[I].Hide; // Use label for demos until we fix exploits
      DropBox_AlliesTeam[I].Add('-');
      for K := 1 to MAX_TEAMS do
        DropBox_AlliesTeam[I].Add(IntToStr(K));
      DropBox_AlliesTeam[I].OnChange := AlliesTeamChange;
      DropBox_AlliesTeam[I].DropUp := True; // Doesn't fit if it drops down
      Label_AlliesPing[I] :=          TKMLabel.Create(Panel_Allies, 15 + 347+(I div ALLIES_ROWS)*LINE_W, 80+(I mod ALLIES_ROWS)*20, '', fntGrey, taRight);
      Label_AlliesPingFpsSlash[I] :=  TKMLabel.Create(Panel_Allies, 15 + 354+(I div ALLIES_ROWS)*LINE_W, 80+(I mod ALLIES_ROWS)*20, '', fntGrey, taCenter);
      Label_AlliesFPS[I] :=           TKMLabel.Create(Panel_Allies, 15 + 361+(I div ALLIES_ROWS)*LINE_W, 80+(I mod ALLIES_ROWS)*20, '', fntGrey, taLeft);
    end;

    Image_AlliesClose:=TKMImage.Create(Panel_Allies,PANEL_ALLIES_WIDTH-98,24,32,32,52,rxGui);
    Image_AlliesClose.Hint := gResTexts[TX_MSG_CLOSE_HINT];
    Image_AlliesClose.OnClick := Allies_Close;
    Image_AlliesClose.HighlightOnMouseOver := True;
end;


{ Menu page }
procedure TKMGamePlayInterface.Create_Menu;
begin
  Panel_Menu := TKMPanel.Create(Panel_Controls, TB_PAD, 44, TB_WIDTH, 332);
  Button_Menu_Load := TKMButton.Create(Panel_Menu, 0, 20, TB_WIDTH, 30, gResTexts[TX_MENU_LOAD_GAME], bsGame);
  Button_Menu_Load.OnClick := SwitchPage;
  Button_Menu_Load.Hint := gResTexts[TX_MENU_LOAD_GAME];
  Button_Menu_Load.Visible := not (fUIMode in [umMP, umSpectate]);

  Button_Menu_ReturnLobby := TKMButton.Create(Panel_Menu, 0, 20, TB_WIDTH, 30, gResTexts[TX_MENU_VOTE_RETURN_LOBBY], bsGame);
  Button_Menu_ReturnLobby.OnClick := ReturnToLobbyClick;
  Button_Menu_ReturnLobby.Hint := gResTexts[TX_MENU_VOTE_RETURN_LOBBY_HINT];
  Button_Menu_ReturnLobby.Visible := fUIMode in [umMP, umSpectate];

  Button_Menu_Save := TKMButton.Create(Panel_Menu, 0, 60, TB_WIDTH, 30, gResTexts[TX_MENU_SAVE_GAME], bsGame);
  Button_Menu_Save.OnClick := SwitchPage;
  Button_Menu_Save.Hint := gResTexts[TX_MENU_SAVE_GAME];
  Button_Menu_Settings := TKMButton.Create(Panel_Menu, 0, 100, TB_WIDTH, 30, gResTexts[TX_MENU_SETTINGS], bsGame);
  Button_Menu_Settings.OnClick := SwitchPage;
  Button_Menu_Settings.Hint := gResTexts[TX_MENU_SETTINGS];

  Button_Menu_Quit := TKMButton.Create(Panel_Menu, 0, 160, TB_WIDTH, 30, gResTexts[TX_MENU_QUIT_MISSION], bsGame);
  Button_Menu_Quit.Hint := gResTexts[TX_MENU_QUIT_MISSION];
  Button_Menu_Quit.OnClick := SwitchPage;

  TKMLabel.Create(Panel_Menu, 0, 198, TB_WIDTH, 30, gResTexts[TX_GAMEPLAY_GAME_TIME] + ':', fntOutline, taCenter);
  Label_GameTime := TKMLabel.Create(Panel_Menu, 0, 218, TB_WIDTH, 20, '', fntGrey, taCenter);
  TKMLabel.Create(Panel_Menu, 0, 240, TB_WIDTH, 30, gResTexts[TX_WORD_MAP] + ':', fntOutline, taCenter);
  Label_MapName := TKMLabel.Create(Panel_Menu, -3, 260, TB_WIDTH + 3, 20, '', fntGrey, taCenter);

  Panel_Track := TKMPanel.Create(Panel_Menu, 0, PANEL_TRACK_TOP, TB_WIDTH, 60);
  TKMLabel.Create(Panel_Track, 0, 0, TB_WIDTH, 30, gResTexts[TX_MUSIC_PLAYER], fntOutline, taCenter);
  Label_Menu_Track := TKMLabel.Create(Panel_Track, 23, 21, TB_WIDTH - 46, 30, '', fntGrey, taCenter);
  Label_Menu_Track.Hitable := False; // It can block hits for the track Up/Down buttons as they overlap

  Button_Menu_TrackUp := TKMButton.Create(Panel_Track, 160, 15, 20, 30, '>', bsGame);
  Button_Menu_TrackDown := TKMButton.Create(Panel_Track, 0, 15, 20, 30, '<', bsGame);
  Button_Menu_TrackUp.Hint := GetHintWHotKey(TX_MUSIC_NEXT_HINT, kfMusicNextTrack);
  Button_Menu_TrackDown.Hint := GetHintWHotKey(TX_MUSIC_PREV_HINT, kfMusicPrevTrack);
  Button_Menu_TrackUp.OnClick := Menu_NextTrack;
  Button_Menu_TrackDown.OnClick := Menu_PreviousTrack;
end;


{ Save page }
procedure TKMGamePlayInterface.Create_Save;
begin
  Panel_Save := TKMPanel.Create(Panel_Controls, TB_PAD, 44, TB_WIDTH, 332);

    // Edit field created first to pick a focus on panel show
    Edit_Save := TKMEdit.Create(Panel_Save, 0, 235, TB_WIDTH, 20, fntMetal);
    Edit_Save.AllowedChars := acFileName;
    Edit_Save.MaxLen := MAX_SAVENAME_LENGTH;
    Edit_Save.AutoFocusable := False;
    Edit_Save.OnChange := Menu_Save_EditChange;

    ListBox_Save := TKMListBox.Create(Panel_Save, 0, 4, TB_WIDTH, 220, fntMetal, bsGame);
    ListBox_Save.AutoHideScrollBar := True;
    ListBox_Save.SearchEnabled := True;
    ListBox_Save.OnChange := Menu_Save_ListChange;

    Label_SaveExists := TKMLabel.Create(Panel_Save,0,260,TB_WIDTH,30,gResTexts[TX_GAMEPLAY_SAVE_EXISTS],fntOutline,taLeft);
    CheckBox_SaveExists := TKMCheckBox.Create(Panel_Save,0,280,TB_WIDTH,20,gResTexts[TX_GAMEPLAY_SAVE_OVERWRITE], fntMetal);
    CheckBox_SaveExists.OnClick := Menu_Save_CheckboxChange;

    Button_Save := TKMButton.Create(Panel_Save,0,300,TB_WIDTH,30,gResTexts[TX_GAMEPLAY_SAVE_SAVE], bsGame);
    Button_Save.OnClick := Menu_Save_Click;
end;


{ Load page }
procedure TKMGamePlayInterface.Create_Load;
begin
  Panel_Load := TKMPanel.Create(Panel_Controls, TB_PAD, 44, TB_WIDTH, 332);

    ListBox_Load := TKMListBox.Create(Panel_Load, 0, 2, TB_WIDTH, 260, fntMetal, bsGame);
    ListBox_Load.AutoHideScrollBar := True;
    ListBox_Load.SearchEnabled := True;
    ListBox_Load.OnChange := Menu_Load_ListClick;
    ListBox_Load.OnDoubleClick := Menu_Load_Click;

    Label_LoadDescription := TKMLabel.Create(Panel_Load,0,265,TB_WIDTH,0,'',fntGrey,taLeft);
    Label_LoadDescription.AutoWrap := True;

    Button_Load := TKMButton.Create(Panel_Load,0,300,TB_WIDTH,30,gResTexts[TX_GAMEPLAY_LOAD], bsGame);
    Button_Load.OnClick := Menu_Load_Click;
end;


{ Quit page }
procedure TKMGamePlayInterface.Create_Quit;
begin
  Panel_Quit := TKMPanel.Create(Panel_Controls, TB_PAD, 44, TB_WIDTH, 332);
    Label_QuitQuestion := TKMLabel.Create(Panel_Quit, 0, 30, TB_WIDTH, 70, gResTexts[TX_MENU_QUIT_QUESTION], fntOutline, taCenter);
    Label_QuitQuestion.AutoWrap := True;
    Button_Quit_Yes := TKMButton.Create(Panel_Quit, 0, 100, TB_WIDTH, 30, gResTexts[TX_MENU_QUIT_MISSION], bsGame);
    Button_Quit_Yes.Hint := gResTexts[TX_MENU_QUIT_MISSION];
    Button_Quit_Yes.OnClick := Menu_QuitMission;

    Button_ReturnToMapEd := TKMButton.Create(Panel_Quit, 0, 140, TB_WIDTH, 30, gResTexts[TX_MENU_RETURN_TO_MAPED], bsGame);
    Button_ReturnToMapEd.Hint := gResTexts[TX_MENU_RETURN_TO_MAPED_HINT];
    Button_ReturnToMapEd.OnClick := Menu_ReturnToMapEd;
    Button_ReturnToMapEd.Hide;

    Button_Quit_No := TKMButton.Create(Panel_Quit, 0, 190, TB_WIDTH, 30, gResTexts[TX_MENU_DONT_QUIT_MISSION], bsGame);
    Button_Quit_No.Hint := gResTexts[TX_MENU_DONT_QUIT_MISSION];
    Button_Quit_No.OnClick := SwitchPage;
end;


procedure TKMGamePlayInterface.Chat_Click(Sender: TObject);
begin
  if fGuiGameChat.Visible then
    fGuiGameChat.Hide
  else
  begin
    Allies_Close(nil);
    Message_Close(nil);
    MessageLog_Close(nil);
    Label_ChatUnread.Caption := ''; // No unread messages
    fGuiGameChat.Show;
  end;
end;


procedure TKMGamePlayInterface.CinematicUpdate;
var
  I: Integer;
begin
  if gMySpectator.Hand.InCinematic then
  begin
    gMySpectator.Selected := nil;
    UpdateSelectedObject;
    // Close panels unless it is an allowed menu
    if not Panel_Menu.Visible and not Panel_Load.Visible and not Panel_Save.Visible
    and not fGuiMenuSettings.Visible and not Panel_Quit.Visible and not fGuiGameStats.Visible then
      SwitchPage(nil);

    fDragScrolling := False;
    fGuiGameUnit.JoiningGroups := False;
    ReleaseDirectionSelector;
    gRes.Cursors.Cursor := kmcDefault; // Might have been scrolling or joining groups
    UpdateUI; // Disabled main buttons

    MinimapView.Disable;
    Sidebar_Top.Disable;
    Sidebar_Middle.Disable;
    for I := Low(Sidebar_Bottom) to High(Sidebar_Bottom) do
      Sidebar_Bottom[I].Disable;
  end
  else
  begin
    UpdateUI; // Enable main buttons

    Viewport.CinematicReset; //Reset Pan points for future cinematics

    MinimapView.Enable;
    Sidebar_Top.Enable;
    Sidebar_Middle.Enable;
    for I := Low(Sidebar_Bottom) to High(Sidebar_Bottom) do
      Sidebar_Bottom[I].Enable;
  end;
end;


// Used when loading MP save since hotkeys must be network synced
procedure TKMGamePlayInterface.LoadHotkeysFromHand;
var
  I: Integer;
begin
  for I := Low(fSelection) to High(fSelection) do
    fSelection[I] := gMySpectator.Hand.SelectionHotkeys[I];
end;


procedure TKMGamePlayInterface.Allies_Click(Sender: TObject);
begin
  if Panel_Allies.Visible then
    Allies_Close(Sender)
  else
    Allies_Show(Sender);
end;


procedure TKMGamePlayInterface.Allies_Show(Sender: TObject);
begin
  gSoundPlayer.Play(sfxnMPChatOpen);
  Panel_Allies.Show;
  fGuiGameChat.Hide;
  Message_Close(nil);
  MessageLog_Close(nil);
end;


procedure TKMGamePlayInterface.House_Demolish(Sender: TObject; Shift: TShiftState);
begin
  SwitchPage(Button_Main[tbBuild]);
  if ssShift in Shift then
    fGuiGameBuild.ErasePlan; //Enable Delete mode again
end;


procedure TKMGamePlayInterface.Reset_Menu;
begin
  SwitchPage(nil);
end;


function TKMGamePlayInterface.ArmyCanTakeOrder(aObject: TObject): Boolean;
begin
  Result := (fUIMode in [umSP, umMP]) and not HasLostMPGame;
end;


function TKMGamePlayInterface.IsSelectingTroopDirection(aObject: TObject): Boolean;
begin
  Result := SelectingTroopDirection;
end;


// Click on the same message again closes it
procedure TKMGamePlayInterface.Message_Click(Sender: TObject; Shift: TShiftState);
begin
  if ssLeft in Shift then
  begin
    if TKMImage(Sender).Tag <> fShownMessage then
      Message_Show(TKMImage(Sender).Tag)
    else
      Message_Close(Sender);
  end
  else
  begin
    Message_Delete(TKMImage(Sender).Tag);
    if (TKMImage(Sender).Tag < fShownMessage) then
        Dec(fShownMessage);
  end;
end;


procedure TKMGamePlayInterface.Message_Show(aIndex: Integer);
var
  I: Integer;
begin
  fShownMessage := aIndex;

  // Highlight target message icon
  for I := 0 to MAX_VISIBLE_MSGS do
    Image_Message[I].Highlight := (fShownMessage = I);

  Label_MessageText.Caption := fMessageStack[fShownMessage].Text;
  Button_MessageGoTo.Visible := not KMSamePoint(fMessageStack[fShownMessage].Loc, KMPOINT_ZERO);

  Allies_Close(nil);
  fGuiGameChat.Hide;
  MessageLog_Close(nil);
  Panel_Message.Show;
  // Must update top AFTER showing panel, otherwise Button_MessageGoTo.Visible will always return false
  Button_MessageDelete.Top := IfThen(Button_MessageGoTo.Visible, 104, 74);
  gSoundPlayer.Play(sfxMessageOpen); // Play parchment sound when they open the message
end;


// Message has been closed
procedure TKMGamePlayInterface.Message_Close(Sender: TObject);
begin
  // Remove highlight
  if fShownMessage <> -1 then
  begin
    Image_Message[fShownMessage].Highlight := False;

    // Play sound
    if Sender <> nil then
      gSoundPlayer.Play(sfxMessageClose);
  end;

  fShownMessage := -1;
  Panel_Message.Hide;
end;


procedure TKMGamePlayInterface.Message_DeleteClick(Sender: TObject);
var
  oldMsg: Integer;
begin
  if fShownMessage = -1 then Exit; // Player pressed DEL with no Msg opened

  oldMsg := fShownMessage;
  Message_Close(Sender);
  Message_Delete(oldMsg);
end;


procedure TKMGamePlayInterface.Message_Delete(aIndex: Integer);
begin
  if aIndex = fShownMessage then
    Message_Close(nil);

  fMessageStack.RemoveStack(aIndex);

  Message_UpdateStack;
  DisplayHint(nil);
end;


procedure TKMGamePlayInterface.Message_GoTo(Sender: TObject);
begin
  fViewport.Position := KMPointF(fMessageStack.MessagesStack[fShownMessage].Loc);
end;


procedure TKMGamePlayInterface.Message_UpdateStack;
var
  I: Integer;
begin
  // MessageList is unlimited, while Image_Message has fixed depth and samples data from the list on demand
  for I := 0 to MAX_VISIBLE_MSGS do
  begin
    // Disable and hide at once for safety
    Image_Message[I].Enabled := (I <= fMessageStack.CountStack - 1);
    Image_Message[I].Visible := (I <= fMessageStack.CountStack - 1);
    if I <= fMessageStack.CountStack - 1 then
      Image_Message[i].TexID := fMessageStack.MessagesStack[I].Icon;
  end;
end;


procedure TKMGamePlayInterface.StopPlay(aMsg: TKMGameResultMsg; aPrepareToStopGame: Boolean = True);
var
  showStats, reinitStatsLastTime: Boolean;
begin
  if aMsg <> grGameContinues then
    gGame.GameResult := aMsg;

  showStats := False;
  reinitStatsLastTime := False;

  // Add victory / defeat videos to play
  if gGameParams.IsNormalGame then // Don't play Victory / Defeat videos for specs
  begin
    case aMsg of
      grWin:              gVideoPlayer.AddMissionVideo(gGameParams.MissionFile, 'Victory');
      grDefeat, grCancel: gVideoPlayer.AddMissionVideo(gGameParams.MissionFile, 'Defeat');
    end;
    gVideoPlayer.Play;
  end;

  case aMsg of
    grWin,
    grDefeat,
    grCancel,
    grReplayEnd:     begin
                        gGameApp.PrepageStopGame(gGame.GameResult);
                        showStats := True;
                        reinitStatsLastTime := True;
                      end;
    grGameContinues: showStats := True;
    grError,
    grDisconnect,
    grSilent,
    grMapEdEnd:  StopGame;
  end;

  if showStats then
  begin
    if (gGameParams.Mode in [gmMulti, gmMultiSpectate, gmReplayMulti]) or MP_RESULTS_IN_SP then
      fGuiGameResultsMP.Show(aMsg)
    else begin
      if reinitStatsLastTime then
      begin
        fGuiGameResultsMP.Show(aMsg, True); //Show and hide MP results, so they will be synced with SP results page
        fGuiGameResultsMP.Hide;
      end;
      fGuiGameResultsSP.Show(aMsg, reinitStatsLastTime);
    end;
  end;
end;


// Quit the mission and return to main menu
procedure TKMGamePlayInterface.Menu_QuitMission(Sender: TObject);
begin
  //Defeat player, if he intentionally quit, when game result is not determined yet (grCancel)
  if gGameParams.IsMultiplayerGame and (gGame.GameResult = grCancel) then
    gGame.GameResult := grDefeat
  else if gGameParams.IsReplay then
    gGame.GameResult := grReplayEnd;
  // Show outcome depending on actual situation.
  // By default PlayOnState is grCancel, if playing on after victory/defeat it changes
  StopPlay(gGame.GameResult);
end;


procedure TKMGamePlayInterface.Menu_ReturnToMapEd(Sender: TObject);
var
  mapPath, gameName: UnicodeString;
  isMultiplayer: Boolean;
begin
  isMultiplayer := gGame.StartedFromMapEdAsMPMap;
  mapPath := TKMapsCollection.FullPath(gGameParams.Name, '.dat', isMultiplayer);
  gameName := gGameParams.Name;
  FreeThenNil(gGame);
  gGameApp.NewMapEditor(mapPath, 0, 0, TKMapsCollection.GetMapCRC(gameName, isMultiplayer));
  TKMapEdInterface(gGame.ActiveInterface).SetLoadMode(isMultiplayer);
end;


procedure TKMGamePlayInterface.Menu_NextTrack(Sender: TObject);
begin
  gMusic.PlayNextTrack;
end;


procedure TKMGamePlayInterface.Menu_PreviousTrack(Sender: TObject);
begin
  gMusic.PlayPreviousTrack;
end;


procedure TKMGamePlayInterface.Allies_Close(Sender: TObject);
begin
  if Panel_Allies.Visible then gSoundPlayer.Play(sfxnMPChatClose);
  Panel_Allies.Hide;
end;


procedure TKMGamePlayInterface.Allies_Mute(Sender: TObject);
var Image: TKMImage;
begin
  if (Sender is TKMImage) then
  begin
    Image := TKMImage(Sender);
    if gLog.IsDegubLogEnabled then
      gLog.LogDebug(Format('TKMGamePlayInterface.Allies_mute: Image.tag = %d NetPlayerIndex = %d',
                           [Image.Tag, fLineIdToNetPlayerId[Image.Tag]]));
    gNetworking.ToggleMuted(fLineIdToNetPlayerId[Image.Tag]);
    Update_Image_AlliesMute(Image);
  end;
end;


procedure TKMGamePlayInterface.Update_Image_AlliesMute(aImage: TKMImage);
begin
  if gNetworking.IsMuted(fLineIdToNetPlayerId[aImage.Tag]) then
  begin
    aImage.Hint := gResTexts[TX_UNMUTE_PLAYER];
    aImage.TexId := 84;
  end else begin
    aImage.Hint := gResTexts[TX_MUTE_PLAYER];
    aImage.TexId := 83;
  end;
end;


procedure TKMGamePlayInterface.UpdateNetPlayersMapping;
var
  I, J, K: Integer;
  teams: TKMByteSetArray;
  handIdToNetPlayersId: array [0..MAX_HANDS - 1] of Integer;
begin
  // First empty everything
  fPlayerLinesCnt := 0;

  for I := 0 to MAX_LOBBY_SLOTS - 1 do
    fLineIdToNetPlayerId[I] := -1;

  for I := 0 to MAX_HANDS - 1 do
    handIdToNetPlayersId[I] := -1;

  for I := 1 to gNetworking.NetPlayers.Count do
    if not gNetworking.NetPlayers[I].IsSpectator then
      handIdToNetPlayersId[gNetworking.NetPlayers[I].HandIndex] := I;

  teams := gHands.Teams;

  K := 0;
  for J := Low(teams) to High(teams) do
    for I in teams[J] do
      if handIdToNetPlayersId[I] <> -1 then //HandIdToNetPlayersId could -1, if we play in the save, where 1 player left
      begin
        fLineIdToNetPlayerId[K] := handIdToNetPlayersId[I];
        Inc(K);
      end;

  // Spectators
  for I := 1 to gNetworking.NetPlayers.Count do
    if gNetworking.NetPlayers[I].IsSpectator then
    begin
      fLineIdToNetPlayerId[K] := I;
      Inc(K);
    end;

  fPlayerLinesCnt := K;
end;


procedure TKMGamePlayInterface.UpdateReplayButtons(aPaused: Boolean);
begin
  Button_ReplayPause.Enabled := aPaused;
  Button_ReplayStep.Enabled := not aPaused;
  Button_ReplayResume.Enabled := not aPaused;
end;


procedure TKMGamePlayInterface.AddReplayMark(aTick: Cardinal);
begin
  if Self = nil then Exit;

  if (gGame.SavePoints <> nil) then
    ReplayBar_Replay.AddMark(aTick);
end;


// Update replay marks according to Game SavedReplays (checkpoints)
procedure TKMGamePlayInterface.UpdateReplayMarks;
var
  tick: Cardinal;
  ticksList: TList<Cardinal>;
begin
  if (Self = nil) or (gGame.SavePoints = nil) then Exit;

  ticksList := TList<Cardinal>.Create;
  try
    gGame.SavePoints.FillTicks(ticksList);

    ReplayBar_Replay.Clear; // Clear marks, we are going to refill them all

    for tick in ticksList do
      AddReplayMark(tick);
  finally
    FreeAndNil(ticksList);
  end;
end;


procedure TKMGamePlayInterface.SelectEntityByUID(aUID: Integer);
var
  entity: TKMHandEntity;
begin
  if Self = nil then Exit;
  if gHands = nil then Exit;

  entity := gHands.GetObjectByUID(aUID);
  gMySpectator.HighlightDebug := entity;

  if (entity = nil) or not entity.IsSelectable then Exit;

  fViewport.Position := entity.PositionF;

  if entity is TKMUnitWarrior then
    gMySpectator.Selected := entity.AsUnitWarrior.Group
  else
    gMySpectator.Selected := entity;

  UpdateSelectedObject;
end;


procedure TKMGamePlayInterface.Replay_DropBox_JumpToPlayer(aDropBoxIndex: Integer);
begin
  Dropbox_ReplayFOW.ItemIndex := EnsureRange(0, aDropBoxIndex, Dropbox_ReplayFOW.Count - 1);

  Replay_JumpToPlayer(Dropbox_ReplayFOW.GetTag(aDropBoxIndex));
end;


procedure TKMGamePlayInterface.Replay_JumpToPlayer(aHandIndex: Integer);
var
  lastSelectedEntity: TKMHandEntity;
  oldHandIndex: Integer;
begin
  oldHandIndex := gMySpectator.HandID;
  gMySpectator.HandID := aHandIndex;

  lastSelectedEntity := gMySpectator.LastSpecSelectedEntity;
  if lastSelectedEntity <> nil then
    // Center screen on last selected object for chosen hand
    fViewport.Position := lastSelectedEntity.PositionF
  else
  if not KMSamePoint(gHands[gMySpectator.HandID].CenterScreen, KMPOINT_ZERO) then
    fViewport.Position := gHands[gMySpectator.HandID].CenterScreen.ToFloat //By default set viewport position to hand CenterScreen
  else
    fViewport.Position := gHands[gMySpectator.HandID].FindCityCenter.ToFloat;

  gMySpectator.Selected := lastSelectedEntity;  // Change selected object to last one for this hand or Reset it to nil

  UpdateSelectedObject;
  Replay_UpdatePlayerInterface(oldHandIndex, gMySpectator.HandID);
end;


procedure TKMGamePlayInterface.Replay_ViewPlayer(aPlayerIndex: Integer);
var
  oldHandIndex: Integer;
begin
  Dropbox_ReplayFOW.ItemIndex := EnsureRange(0, aPlayerIndex, Dropbox_ReplayFOW.Count - 1);

  oldHandIndex := gMySpectator.HandID;
  gMySpectator.HandID := Dropbox_ReplayFOW.GetTag(aPlayerIndex);

  if (gMySpectator.Selected <> nil)
    and (oldHandIndex <> gMySpectator.HandID) then
  begin
    gMySpectator.Selected := nil;   // Reset selection when start viewing another player
    UpdateSelectedObject;
  end;

  Replay_UpdatePlayerInterface(oldHandIndex, gMySpectator.HandID);
end;


procedure TKMGamePlayInterface.Replay_UpdatePlayerInterface(aFromPlayer, aToPlayer: Integer);
begin
  if Checkbox_ReplayFOW.Checked then
    gMySpectator.FOWIndex := aToPlayer
  else
    gMySpectator.FOWIndex := -1;
  fMinimap.Update; // Force update right now so FOW doesn't appear to lag
  gGame.OverlayUpdate; // Display the overlay seen by the selected player

  Dropbox_ReplayFOW.SelectByTag(aToPlayer);

  // When switch to other team player clear all beacons, except Spectators beacons
  if (gHands.CheckAlliance(aFromPlayer, aToPlayer) <> atAlly)
    or not gHands[aFromPlayer].ShareBeacons[aToPlayer] then
    gGame.GamePlayInterface.Alerts.ClearBeaconsExcept(PLAYER_NONE);
end;


procedure TKMGamePlayInterface.Replay_ListDoubleClick(Sender: TObject);
begin
  //Double clicking on an item in the list jumps to the previously selected object of that player
  Replay_DropBox_JumpToPlayer(Dropbox_ReplayFOW.ItemIndex);
end;


function TKMGamePlayInterface.Replay_ListKeyUp(Sender: TObject; Key: Word; Shift: TShiftState): Boolean;
begin
  Result := False;
  case Key of
    VK_ESCAPE:  if Sender = Dropbox_ReplayFOW.List then
                begin
                  TKMListBox(Sender).Unfocus;
                  Result := True;
                end;
  end;
end;


procedure TKMGamePlayInterface.ReplayClick(Sender: TObject);
begin
  if Self = nil then Exit;

  if Sender = Button_ReplayRestart then
  begin
    // Restart the replay by loading from stream
    ReplayMarkClick(1);

    Exit; // Restarting the replay will destroy Self, so exit immediately
  end;

  if Sender = Button_ReplayPause then
  begin
    gGame.IsPaused := True;
    UpdateReplayButtons(False);
  end;

  if Sender = Button_ReplayStep then
  begin
    gGame.StepOneFrame;
    gGame.IsPaused := False;
    UpdateReplayButtons(False);
  end;

  if Sender = Button_ReplayResume then
  begin
    gGame.IsPaused := False;
    UpdateReplayButtons(True);
  end;

  if Sender = Button_ReplayExit then
  begin
    gGame.Hold(True, grReplayEnd);
    UpdateReplayButtons(True);
  end;

  if Sender = Button_ReplaySaveAt then
  begin
    gGame.MakeSavePoint();
    AddReplayMark(gGameParams.Tick);
  end;

  if Sender = Dropbox_ReplayFOW then
    Replay_ViewPlayer(Dropbox_ReplayFOW.ItemIndex);

  if (Sender = Checkbox_ReplayFOW) then
  begin
    if Checkbox_ReplayFOW.Checked then
      gMySpectator.FOWIndex := gMySpectator.HandID
    else
      gMySpectator.FOWIndex := -1;
    fMinimap.Update; // Force update right now so FOW doesn't appear to lag
  end;
end;


procedure TKMGamePlayInterface.ReturnToLobbyClick(Sender: TObject);
begin
  gNetworking.VoteReturnToLobby;
end;


procedure TKMGamePlayInterface.MessageIssue(aKind: TKMMessageKind; const aText: UnicodeString);
begin
  MessageIssue(aKind, aText, KMPOINT_ZERO);
end;


procedure TKMGamePlayInterface.MessageIssue(aKind: TKMMessageKind; const aText: UnicodeString; const aLoc: TKMPoint);
begin
  if fUIMode in [umReplay, umSpectate] then Exit; // No message stack in replay/spectate
  fMessageStack.Add(aKind, aText, aLoc);
  Message_UpdateStack;
  gSoundPlayer.Play(sfxMessageNotice, 4); // Play horn sound on new message if it is the right type
end;


procedure TKMGamePlayInterface.MessageLog_Click(Sender: TObject);
begin
  if Panel_MessageLog.Visible then
  begin
    Panel_MessageLog.Hide;
    gSoundPlayer.Play(sfxMessageClose);
  end
  else
  begin
    MessageLog_Update(True);

    Allies_Close(nil);
    fGuiGameChat.Hide;
    MessageLog_Close(nil);
    Message_Close(nil);

    Panel_MessageLog.Show;
    ColumnBox_MessageLog.TopIndex := ColumnBox_MessageLog.RowCount;
    gSoundPlayer.Play(sfxMessageOpen); // Play parchment sound when they open the message
  end;
end;


procedure TKMGamePlayInterface.MessageLog_Close(Sender: TObject);
begin
  Panel_MessageLog.Hide;
  if Sender = Image_MessageLogClose then
    gSoundPlayer.Play(sfxMessageClose);
end;


procedure TKMGamePlayInterface.MessageLog_ShowMessage(aMessageId: Integer; aJumpToLoc: Boolean = True);
var
  msg: TKMLogMessage;
  H: TKMHouse;
  G: TKMUnitGroup;
begin
  msg := gMySpectator.Hand.MessageLog[aMessageId];
  msg.IsReadLocal := True;
  gGame.GameInputProcess.CmdGame(gicGameMessageLogRead, aMessageId);

  if aJumpToLoc then
  begin
    // Jump to location
    fViewport.Position := KMPointF(msg.Loc);

    // Try to highlight the house in question
    H := gHands.HousesHitTest(msg.Loc.X, msg.Loc.Y);

    // Do not highlight a house if it is not the one that has issued the notification
    // (happens when note is issues and house is destroyed and a new one is build in the same place)
    // NOTE: It will highlight next house built on the 'ruins' which is unoccupied to be precise
    //       even the NEW message has not been issued yet
    if (H <> nil) then
    begin
      if (gRes.IsMsgHouseUnnocupied(msg.fTextID) and not H.HasOwner
          and (gRes.Houses[H.HouseType].OwnerType <> utNone) and (H.HouseType <> htBarracks))
        or H.ResourceDepleted
        or H.OrderCompletedMsgIssued then
      begin
        gMySpectator.Highlight := H;
        gMySpectator.Selected := H;
        UpdateSelectedObject;
      end;
    end else begin
      G := gHands.GroupsHitTest(msg.Loc.X, msg.Loc.Y);
      if (G <> nil) and not G.IsDead then
      begin
        SelectUnitGroup(G);
        UpdateSelectedObject;
      end;
    end;
  end;

  MessageLog_Update(True);
end;


function TKMGamePlayInterface.MessageLog_ItemClick(Sender: TObject; Shift: TShiftState; const X,Y: Integer): Boolean;
var
  itemId, messageId: Integer;
begin
  Result := False;
  itemId := Y;
  if itemId >= Length(ColumnBox_MessageLog.Rows) then Exit;

  messageId := ColumnBox_MessageLog.Rows[itemId].Tag;
  if messageId = -1 then Exit;

  Result := True;

  MessageLog_ShowMessage(messageId, ssLeft in Shift);
end;


// Sync displayed messages with queue
// We show only last 8 messages by design
procedure TKMGamePlayInterface.MessageLog_Update(aFullRefresh: Boolean);
var
  I, K: Integer;
  R: TKMListRow;
begin
  // Exit if synced already
  if not aFullRefresh and (fLastSyncedMessage = gMySpectator.Hand.MessageLog.CountLog) then Exit;

  // Clear the selection if a new item is added so the wrong one is not selected
  if fLastSyncedMessage <> gMySpectator.Hand.MessageLog.CountLog then
    ColumnBox_MessageLog.ItemIndex := -1;

  // Clear all rows in case gMySpectator.HandIndex was changed and MessageLog now contains less items
  for I := 0 to MAX_LOG_MSGS - 1 do
    ColumnBox_MessageLog.Rows[I] := MakeListRow(['', ''], -1);

  K := 0;
  for I := Max(gMySpectator.Hand.MessageLog.CountLog - MAX_LOG_MSGS, 0) to gMySpectator.Hand.MessageLog.CountLog - 1 do
  begin
    R := MakeListRow(['', gMySpectator.Hand.MessageLog[I].Text], I);

    if gMySpectator.Hand.MessageLog[I].Kind = mkUnit then
    begin
      R.Cells[0].Pic := MakePic(rxGui, 588);
      if gMySpectator.Hand.MessageLog[I].IsRead then
      begin
        R.Cells[1].Color := clMessageUnitRead;
        R.Cells[1].HighlightColor := clMessageUnitReadHL;
      end
      else
      begin
        R.Cells[1].Color := clMessageUnitUnread;
        R.Cells[1].HighlightColor := clMessageUnitUnreadHL;
      end;
    end
    else
    begin
      R.Cells[0].Pic := MakePic(rxGui, 587);
      if gMySpectator.Hand.MessageLog[I].IsRead then
      begin
        R.Cells[1].Color := $FFA0A0A0;
        R.Cells[1].HighlightColor := icGray;
      end
      else
      begin
        R.Cells[1].Color := $FFFFFFFF;
        R.Cells[1].HighlightColor := $FFC7C7C7;
      end;
    end;

    ColumnBox_MessageLog.Rows[K] := R;
    Inc(K);
  end;

  fLastSyncedMessage := gMySpectator.Hand.MessageLog.CountLog;
end;


// Update message stack when first log message arrives
procedure TKMGamePlayInterface.MessageStack_UpdatePositions;
var
  I: Integer;
  pad: Integer;
begin
  pad := Byte(fUIMode in [umMP, umSpectate]) * 2 +
         Byte(Image_MessageLog.Visible);
  for I := 0 to MAX_VISIBLE_MSGS do
    Image_Message[I].Top := Panel_Main.Height - 48 - (I + pad) * 48;
end;


procedure TKMGamePlayInterface.Menu_Update;
begin
  if gGameSettings.MusicOff then
    Label_Menu_Track.Caption := '-'
  else
    Label_Menu_Track.Caption := gMusic.GetTrackTitle;

  Label_Menu_Track.AutoWrap := Length(Label_Menu_Track.Caption) > MAX_TRACKNAME_LENGTH;
  Label_Menu_Track.Top := IfThen(Label_Menu_Track.AutoWrap, 19, 22);
  Button_Menu_TrackUp.Height := IfThen(Label_Menu_Track.AutoWrap, 38, 30);
  Button_Menu_TrackDown.Height := IfThen(Label_Menu_Track.AutoWrap, 38, 30);

  Label_GameTime.Caption := TimeToString(gGame.MissionTime);
  Label_MapName.Caption := Copy(gGameParams.Name, 0, EnsureRange(Length(gGameParams.Name), 1, MAX_MAPNAME_LENGTH));
  if gGameParams.HasMissionDifficulty then
  begin
    Label_MapName.Caption := Format('%s|[$%s]( %s )[]', [Label_MapName.Caption,
                                    IntToHex(DIFFICULTY_LEVELS_COLOR[gGameParams.MissionDifficulty] and $00FFFFFF, 6),
                                    gResTexts[DIFFICULTY_LEVELS_TX[gGameParams.MissionDifficulty]]]);
    Panel_Track.Top := PANEL_TRACK_TOP + 15;
  end else
    Panel_Track.Top := PANEL_TRACK_TOP;

  Label_Menu_Track.Enabled      := not gGameSettings.MusicOff;
  Button_Menu_TrackUp.Enabled   := not gGameSettings.MusicOff;
  Button_Menu_TrackDown.Enabled := not gGameSettings.MusicOff;
end;


procedure TKMGamePlayInterface.Beacon_Cancel;
begin
  fPlacingBeacon := False; // Right click cancels it
  MinimapView.ClickableOnce := False;
  if gRes.Cursors.Cursor = kmcBeacon then
    gRes.Cursors.Cursor := kmcDefault;
end;


procedure TKMGamePlayInterface.Beacon_Place(const aLoc: TKMPointF);
begin
  if (TimeSince(fLastBeaconTime) >= BEACON_COOLDOWN) then
  begin
    fLastBeaconTime := TimeGet;
    // In replays we show the beacon directly without GIP. In spectator we use -1 for hand index
    case fUIMode of
      umReplay:   Alerts.AddBeacon(aLoc, gMySpectator.HandID, gMySpectator.Hand.FlagColor, gGameApp.GlobalTickCount + ALERT_DURATION[atBeacon]);
      umSpectate: gGame.GameInputProcess.CmdGameBeacon(aLoc, PLAYER_NONE, gNetworking.MyNetPlayer.FlagColor);
      else        gGame.GameInputProcess.CmdGameBeacon(aLoc, gMySpectator.HandID, gMySpectator.Hand.FlagColor);
    end;
    Beacon_Cancel;
  end else
    MinimapView.ClickableOnce := True; //Restore ClickableOnce state, because it could be reset by previous click on minimap
end;


procedure TKMGamePlayInterface.Replay_Single_SetPlayersDropbox;
var
  I, dropBoxIndex, humanIndexInList: Integer;
begin
  humanIndexInList := -1;
  dropBoxIndex := 0;
  for I := 0 to gHands.Count - 1 do
  begin
    if (humanIndexInList = -1)        // Set HumanIndexInList only once
      and gHands[I].IsHuman then
      humanIndexInList := dropBoxIndex;
    if gHands[I].Enabled then
    begin
      Dropbox_ReplayFOW.Add(WrapColor(gHands[I].OwnerName, FlagColorToTextColor(gHands[I].FlagColor)), I);
      Inc(dropBoxIndex);
    end;
  end;
  if humanIndexInList = -1 then humanIndexInList := 0; // In case there is no Humans in game
  Dropbox_ReplayFOW.ItemIndex := humanIndexInList;
end;


procedure TKMGamePlayInterface.ReplayMarkClick(aTick: Integer);
var
  oldCenter: TKMPointF;
  oldZoom: Single;
  isPaused: Boolean;
  guiSpecPage: Integer;
  isPlayerDropOpen: Boolean;
  playerDropItem, playersColorMode: Integer;
  showPlayerFOW: Boolean;
  mainMenuTab: TKMTabButtons;
begin
  Assert(aTick >= 0, 'Tick should be >= 0'); //May be even > 0

  //Save Replay GUI locally
  mainMenuTab := fOpenedMenu;
  oldCenter := fViewport.Position;
  oldZoom := fViewport.Zoom;
  isPaused := gGame.IsPaused;
  guiSpecPage := fGuiGameSpectator.GetOpenedPage;
  isPlayerDropOpen := Dropbox_ReplayFOW.IsOpen;
  playerDropItem := Dropbox_ReplayFOW.ItemIndex;
  showPlayerFOW := Checkbox_ReplayFOW.Checked;
  playersColorMode := Radio_PlayersColorMode.ItemIndex;

  if not gGameApp.TryLoadSavePoint( aTick ) then
    Exit;

  if gGame.SavePoints = nil then
    Exit;

  //!!!!Carefull!!!!
  //Self TKMGamePlayInterface is destroyed, but new GamePlayInterface is already created. Point Self to it
  //Other option is to use gGame.GamePlayInterface instead
  Self := gGame.GamePlayInterface;

  //Restore Replay GUI
  OpenMenuPage(mainMenuTab);
  SyncUIView(oldCenter, oldZoom);

  GuiGameSpectator.OpenPage(guiSpecPage);

  if isPlayerDropOpen then
    Dropbox_ReplayFOW.OpenList;
  Dropbox_ReplayFOW.ItemIndex := playerDropItem;

  Checkbox_ReplayFOW.Checked := showPlayerFOW;
  ReplayClick(Checkbox_ReplayFOW); //Apply FOW

  Radio_PlayersColorMode.ItemIndex := playersColorMode;

  if isPaused then
  begin
    gGame.IsPaused := True;
    UpdateReplayButtons(False); //Update buttons
    UpdateState(gGameParams.Tick);
  end;

  UpdateReplayMarks;
end;


procedure TKMGamePlayInterface.Replay_Multi_SetPlayersDropbox;
var
  I, J, dropBoxIndex, humanIndexInList: Integer;
  teams: TKMByteSetArray;
  nonTeamHands: set of Byte;
  teamSeparatorAdded: Boolean;
begin
  teams := gHands.GetTeamsOfAllies;
  nonTeamHands := [0..gHands.Count - 1];

  //Get non team hands
  for I := Low(teams) to High(teams) do
    nonTeamHands := nonTeamHands - teams[I];

  humanIndexInList := -1;
  dropBoxIndex := 0;

  // first output nonteam hands
  for I in nonTeamHands do
  begin
    if (humanIndexInList = -1)        // Set HumanIndexInList only once
      and gHands[I].IsHuman then
      humanIndexInList := dropBoxIndex;
    if gHands[I].Enabled then
    begin
      Dropbox_ReplayFOW.Add(WrapColor(gHands[I].OwnerName, FlagColorToTextColor(gHands[I].FlagColor)), I);
      if dropBoxIndex > 0 then
        Dropbox_ReplayFOW.List.AddSeparator(dropBoxIndex);
      Inc(dropBoxIndex);
    end;
  end;

  for I := Low(teams) to High(teams) do
  begin
    teamSeparatorAdded := False;
    for J in teams[I] do
    begin
      if (humanIndexInList = -1)        // Set HumanIndexInList only once
        and gHands[J].IsHuman then
        humanIndexInList := dropBoxIndex;
      if gHands[J].Enabled then
      begin
        if dropBoxIndex = 0 then
          teamSeparatorAdded := True; //Do not add separator if there was no NonTeamHands
        if not teamSeparatorAdded then
        begin
          Dropbox_ReplayFOW.List.AddSeparator(dropBoxIndex); //Add Team separator at the start of the team
          teamSeparatorAdded := True;
        end;

        Dropbox_ReplayFOW.Add(WrapColor(gHands[J].OwnerName, FlagColorToTextColor(gHands[J].FlagColor)), J);
        Inc(dropBoxIndex);
      end;
    end;
  end;

  if Length(teams) = 0 then
    Dropbox_ReplayFOW.List.ClearSeparators;

  if humanIndexInList = -1 then humanIndexInList := 0; // In case there is no Humans in game
  Dropbox_ReplayFOW.ItemIndex := humanIndexInList;
end;


procedure TKMGamePlayInterface.UpdateMessageImages;
var
  I: Integer;
begin
  for I := 0 to MAX_VISIBLE_MSGS do
    Image_Message[I].Top := Panel_Main.Height - 48 - I * 48
                            - IfThen(CanShowChat, 48)
                            - IfThen(CanShowAllies, 48);
end;


procedure TKMGamePlayInterface.UpdateUI;
var
  isTactic: Boolean;
begin
  UpdateMessageImages;

  AlliesOnPlayerSetup;

  isTactic := gGameParams.IsTactic;

  Button_Main[tbBuild].Enabled := not isTactic and not HasLostMPGame and not gMySpectator.Hand.InCinematic; //Allow to 'test build' if we are in replay / spectate mode
  Button_Main[tbRatio].Enabled := not isTactic and ((fUIMode in [umReplay, umSpectate]) or (not HasLostMPGame and not gMySpectator.Hand.InCinematic));
  Button_Main[tbStats].Enabled := not isTactic;

  Button_Menu_Load.Enabled := fUIMode = umSP; // No loading during multiplayer games
  Button_Menu_Save.Enabled := (fUIMode in [umSP, umMP, umSpectate]) or (ALLOW_SAVE_IN_REPLAY and (fUIMode = umReplay));

  if (fUIMode = umReplay) then
  begin
    Button_Menu_Quit.Caption := gResTexts[TX_REPLAY_QUIT];
    Button_Menu_Quit.Hint := gResTexts[TX_REPLAY_QUIT];
    Label_QuitQuestion.Caption := gResTexts[TX_REPLAY_QUIT_CONFIRMATION];
    Button_Quit_Yes.Caption := gResTexts[TX_REPLAY_QUIT];
    Button_Quit_Yes.Hint := gResTexts[TX_REPLAY_QUIT];
  end else begin
    Button_Menu_Quit.Caption := gResTexts[TX_MENU_QUIT_MISSION];
    Button_Menu_Quit.Hint := gResTexts[TX_MENU_QUIT_MISSION];
    Label_QuitQuestion.Caption := gResTexts[TX_MENU_QUIT_QUESTION];
    Button_Quit_Yes.Caption := gResTexts[TX_MENU_QUIT_MISSION];
    Button_Quit_Yes.Hint := gResTexts[TX_MENU_QUIT_MISSION];
  end;

  if gGame.StartedFromMapEditor then
  begin
    Button_ReturnToMapEd.Visible := True; //Do not use Show here, as we will show this tab in UI immidiately
    Button_Quit_No.Top := Button_ReturnToMapEd.Bottom + 20;
  end else begin
    Button_ReturnToMapEd.Hide;
    Button_Quit_No.Top := Button_ReturnToMapEd.Top;
  end;

  // Toggle gameplay options
  fGuiMenuSettings.SetAutosaveEnabled(fUIMode in [umSP, umMP, umSpectate]);

  // Chat and Allies setup should be accessible only in Multiplayer
  Image_Chat.Visible       := CanShowChat;
  Label_ChatUnread.Visible := CanShowChat;
  Image_MPAllies.Visible   := CanShowAllies;

  // Message stack is visible in Replay as it shows which messages player got
  // and does not affect replay consistency

  Panel_ReplayCtrl.Visible := fUIMode = umReplay;
  Panel_ReplayBar.Visible := fUIMode = umReplay;
  Panel_ReplayFOW.Visible := fUIMode in [umSpectate, umReplay];
  Panel_ReplayFOW.Top := IfThen(fUIMode = umSpectate, 3, 8+29);
  Button_ShowStatsSpec.Visible := not Panel_ReplayCtrl.Visible;
  Checkbox_ReplayFOW.Left := IfThen(Button_ShowStatsSpec.Visible, 27, 0);
  Checkbox_ReplayFOW.Top := IfThen(Panel_ReplayCtrl.Visible, 24+8, 7);
  Dropbox_ReplayFOW.Top := IfThen(Panel_ReplayCtrl.Visible, 24+31, 30);
  Label_PlayersColorMode.Top := IfThen(Panel_ReplayCtrl.Visible, 0, 5);
  Radio_PlayersColorMode.Top := IfThen(Panel_ReplayCtrl.Visible, 20, 25);

  if fUIMode in [umSpectate, umReplay] then
  begin
    //In singleplayer replays, start with fog enabled so replays can be watched without spoilers
    Checkbox_ReplayFOW.Checked := gGameParams.IsSingleplayer and gGameParams.IsReplay;
    ReplayClick(Checkbox_ReplayFOW); //Apply FOW
    Dropbox_ReplayFOW.Clear;

    // Set dropbox in different ways
    case gGameParams.Mode of
      gmReplaySingle:   Replay_Single_SetPlayersDropbox; // Do not show team, as its meaningless
      // Use team info from ally states:
      // consider team as a group of hands where all members are allied to each other and not allied to any other hands.
      gmReplayMulti,
      gmMultiSpectate:  Replay_Multi_SetPlayersDropbox;
      else              raise Exception.Create(Format('Wrong game mode [%s], while spectating/watching replay',
                                                      [GetEnumName(TypeInfo(TKMGameMode), Integer(gGameParams.Mode))]));
    end;
    // We could update UI while watching replay, when some player type/name was updated
    if fGuiGameSpectator = nil then
      fGuiGameSpectator := TKMGUIGameSpectator.Create(Panel_Main, Replay_JumpToPlayer, SetViewportPos);

    UpdateReplayBar;
    gMySpectator.HandID := Dropbox_ReplayFOW.GetTag(Dropbox_ReplayFOW.ItemIndex); //Update HandIndex
  end;
end;


procedure TKMGamePlayInterface.UpdateClock(aSpeedActual, aSpeedRecorded: Single; aShowRecorded: Boolean);
var
  doShowClock: Boolean;
begin
  if Self = nil then Exit;

  doShowClock := (aSpeedActual <> GAME_SPEED_NORMAL)
              or (aShowRecorded and (aSpeedRecorded <> GAME_SPEED_NORMAL));

  Image_Clock.Visible := doShowClock;
  Label_Clock.Visible := doShowClock or gGameSettings.ShowGameTime or SHOW_GAME_TICK;
  Label_ClockSpeedActual.Visible := doShowClock;
  Label_ClockSpeedActual.Caption := 'x' + FormatFloat('##0.##', aSpeedActual);

  if aShowRecorded then
  begin
    Label_ClockSpeedRecorded.Visible := doShowClock;
    Label_ClockSpeedRecorded.Caption := 'x' + FormatFloat('##0.##', aSpeedRecorded);
  end
  else
    Label_ClockSpeedRecorded.Hide;

  if not Image_Clock.Visible and Label_Clock.Visible then
    Label_Clock.Top := 8
  else
    Label_Clock.Top := 80;

  // With slow GPUs it will keep old values till next frame, that can take some seconds
  // Thats why we refresh Clock.Caption here
  if doShowClock then
    Label_Clock.Caption := TimeToString(gGame.MissionTime);
end;


procedure TKMGamePlayInterface.SetPause(aValue: Boolean);
begin
  ReleaseDirectionSelector; // Don't restrict cursor movement to direction selection while paused
  fViewport.ReleaseScrollKeys;
  gGame.IsPaused := aValue;
  UpdateReplayButtons(aValue);
  Panel_Pause.Visible := aValue;
end;


procedure TKMGamePlayInterface.ShowPlayMore(DoShow: Boolean; Msg: TKMGameResultMsg);
begin
  ReleaseDirectionSelector;
  fPlayMoreMsg := Msg;
  case Msg of
    grWin:       begin
                    Label_PlayMore.Caption := gResTexts[TX_GAMEPLAY_WON];
                    Button_PlayMore.Caption := gResTexts[TX_GAMEPLAY_CONTINUE_PLAYING];
                    Button_PlayQuit.Caption := gResTexts[TX_GAMEPLAY_VICTORY];
                  end;
    grDefeat:    begin
                    Label_PlayMore.Caption := gResTexts[TX_GAMEPLAY_LOST];
                    Button_PlayMore.Caption := gResTexts[TX_GAMEPLAY_DEFEAT_CONTINUEWATCHING];
                    Button_PlayQuit.Caption := gResTexts[TX_GAMEPLAY_DEFEAT];
                  end;
    grReplayEnd: begin
                    Label_PlayMore.Caption := gResTexts[TX_GAMEPLAY_REPLAY_ENDED];
                    Button_PlayMore.Caption := gResTexts[TX_GAMEPLAY_REPLAY_CONTINUEWATCHING];
                    Button_PlayQuit.Caption := gResTexts[TX_GAMEPLAY_QUIT_TO_MENU];
                 end;
    else if DoShow then
      raise Exception.Create('Wrong message in ShowPlayMore'); // Can become hidden with any message
  end;
  Panel_PlayMore.Visible := DoShow;
end;


procedure TKMGamePlayInterface.ShowMPPlayMore(Msg: TKMGameResultMsg);
begin
  ReleaseDirectionSelector;
  fPlayMoreMsg := Msg;
  case Msg of
    grWin:       begin
                    Label_MPPlayMore.Caption := gResTexts[TX_GAMEPLAY_WON];
                    Button_MPPlayMore.Caption := gResTexts[TX_GAMEPLAY_CONTINUE_PLAYING];
                    Button_MPPlayQuit.Caption := gResTexts[TX_GAMEPLAY_VICTORY];
                  end;
    grDefeat:    begin
                    // Refresh it so that menu buttons become disabled
                    UpdateUI;
                    // Close e.g. the build menu if it was open
                    SwitchPage(Button_Back);

                    Label_MPPlayMore.Caption := gResTexts[TX_GAMEPLAY_LOST];
                    Button_MPPlayMore.Caption := gResTexts[TX_GAMEPLAY_DEFEAT_CONTINUEWATCHING];
                    Button_MPPlayQuit.Caption := gResTexts[TX_GAMEPLAY_DEFEAT];
                  end;
    else raise Exception.Create('Wrong message in ShowMPPlayMore');
  end;
  Panel_MPPlayMore.Visible := true;
end;


procedure TKMGamePlayInterface.PlayMoreClick(Sender: TObject);
begin
  Panel_PlayMore.Hide; // Hide anyways

  if Sender = Button_PlayQuit then
    case fPlayMoreMsg of
      grWin:       StopPlay(grWin);
      grDefeat:    StopPlay(grDefeat);
      grReplayEnd: StopPlay(grReplayEnd);
    end
  else // GameStop has Destroyed our Sender by now
  if Sender = Button_PlayMore then
    case fPlayMoreMsg of
      grWin:       gGame.Hold(false, grWin);
      grDefeat:    gGame.Hold(false, grDefeat);
      grReplayEnd: begin
                      gGame.SkipReplayEndCheck := True;
                      gGame.Hold(False, grReplayEnd);
                    end;
    end;
end;


procedure TKMGamePlayInterface.MPPlayMoreClick(Sender: TObject);
begin
  Panel_MPPlayMore.Hide;

  if Sender = Button_MPPlayQuit then
    case fPlayMoreMsg of
      grWin:       StopPlay(grWin);
      grDefeat:    StopPlay(grDefeat);
      grReplayEnd: StopPlay(grReplayEnd);
    end
  // If they click continue no other action is necessary, the game is still running
end;


procedure TKMGamePlayInterface.ShowNetworkLag(aShow: Boolean; aPlayers: TKMByteArray; IsHost: Boolean);
var
  I: Integer;
  waitPlayersMsg, waitDCPlayersMsg: UnicodeString;
begin
  if aShow then ReleaseDirectionSelector;
  if not aShow then // Reset the confirm when we hide this screen so it's not on confirm when it reshows
  begin
    Panel_NetWaitConfirm.Hide;
    Panel_NetWaitButtons.Show;
  end;

  if gNetworking.IsReconnecting then
  begin
    waitPlayersMsg := gResTexts[TX_MULTIPLAYER_ATTEMPT_RECONNECTING];
    Button_NetDropPlayers.Visible := False;
    fNetWaitDropPlayersDelayStarted := 0;
    Label_NetDropPlayersDelay.Caption := '';
  end
  else
  begin
//    txt := gResTexts[TX_MULTIPLAYER_WAITING] + ' ';
    waitPlayersMsg := '';
    waitDCPlayersMsg := '';
    for I := Low(aPlayers) to High(aPlayers) do
      if not gNetworking.NetPlayers[aPlayers[I]].Dropped then
        waitPlayersMsg := waitPlayersMsg + gNetworking.NetPlayers[aPlayers[I]].NiknameU + IfThen(I <> High(aPlayers), ', ')
      else
        waitDCPlayersMsg := waitDCPlayersMsg + gNetworking.NetPlayers[aPlayers[I]].NiknameU + IfThen(I <> High(aPlayers), ', ');

    if waitPlayersMsg <> '' then
      waitPlayersMsg := gResTexts[TX_MULTIPLAYER_WAITING] + ' ' + waitPlayersMsg;

    if waitDCPlayersMsg <> '' then
      waitDCPlayersMsg := gResTexts[TX_MULTIPLAYER_WAITING_DC_PLAYERS_DATA] + ' ' + waitDCPlayersMsg;

    if (waitPlayersMsg <> '') and (waitDCPlayersMsg <> '') then
      waitPlayersMsg := waitPlayersMsg + '|';

    waitPlayersMsg := waitPlayersMsg + waitDCPlayersMsg;

    Button_NetDropPlayers.Visible := IsHost;

    if not aShow then
      fNetWaitDropPlayersDelayStarted := 0
    else
      if fNetWaitDropPlayersDelayStarted = 0 then
      begin
        Label_NetDropPlayersDelay.Caption := '';
        fNetWaitDropPlayersDelayStarted := TimeGet; // Initialise it
        Button_NetDropPlayers.Disable; // Must wait the minimum time before enabling it
      end;
  end;

  Label_NetWait.Caption := waitPlayersMsg;
  Panel_NetWait.Visible := aShow;
end;


procedure TKMGamePlayInterface.SetScriptedOverlay(const aText: UnicodeString);
begin
  Label_ScriptedOverlay.Caption := aText;
  UpdateOverlayControls;
end;


procedure TKMGamePlayInterface.HideOverlay(Sender: TObject);
begin
  Label_ScriptedOverlay.Visible := not Label_ScriptedOverlay.Visible;
  if not Label_ScriptedOverlay.Visible then
  begin
    Label_OverlayHide.Hide;
    Label_OverlayShow.Show;
    Button_ScriptedOverlay.Hint := gResTexts[TX_GAMEPLAY_OVERLAY_SHOW];
  end
  else
  begin
    Label_OverlayHide.Show;
    Label_OverlayShow.Hide;
    Button_ScriptedOverlay.Hint := gResTexts[TX_GAMEPLAY_OVERLAY_HIDE];
  end;
  UpdateOverlayControls;
end;


procedure TKMGamePlayInterface.UpdateOverlayControls;
var
  overlayTop, overlayLeft: Integer;
begin
  overlayTop := 12;
  overlayLeft := 258;

  if Panel_ReplayFOW.Visible then
    overlayTop := Panel_ReplayFOW.Top + Panel_ReplayFOW.Height - 5;

  if CanUpdateClockUI then
    overlayTop := Max(overlayTop, Image_Clock.Top + Image_Clock.Height + 25);

  Label_ScriptedOverlay.Top := overlayTop + 19;
  Button_ScriptedOverlay.Top := overlayTop + 1;
  Label_OverlayShow.Top := overlayTop + 2;
  Label_OverlayHide.Top := overlayTop;

  Label_ScriptedOverlay.Left := overlayLeft + 5;
  Button_ScriptedOverlay.Left := overlayLeft;
  Label_OverlayShow.Left := overlayLeft + 3;
  Label_OverlayHide.Left := overlayLeft + 3;

  Button_ScriptedOverlay.Visible := Label_ScriptedOverlay.Caption <> '';
  Label_OverlayShow.Visible := (Label_ScriptedOverlay.Caption <> '') and not Label_ScriptedOverlay.Visible;
  Label_OverlayHide.Visible := (Label_ScriptedOverlay.Caption <> '') and Label_ScriptedOverlay.Visible;
end;


procedure TKMGamePlayInterface.NetWaitClick(Sender: TObject);
begin
  if Sender = Button_NetQuit then
  begin
    Panel_NetWaitButtons.Hide;
    Label_NetWaitConfirm.Caption := gResTexts[TX_GAMEPLAY_CONFIRM_QUIT];
    Button_NetConfirmYes.Caption := gResTexts[TX_GAMEPLAY_QUIT_TO_MENU];
    Panel_NetWaitConfirm.Show;
  end else
  if Sender = Button_NetDropPlayers then
  begin
    Panel_NetWaitButtons.Hide;
    Label_NetWaitConfirm.Caption := gResTexts[TX_GAMEPLAY_CONFIRM_DROP];
    Button_NetConfirmYes.Caption := gResTexts[TX_GAMEPLAY_DROP_PLAYERS];
    Panel_NetWaitConfirm.Show;
  end else
  if Sender = Button_NetConfirmNo then
  begin
    Panel_NetWaitConfirm.Hide;
    Panel_NetWaitButtons.Show;
  end else
  if Sender = Button_NetConfirmYes then
  begin
    Panel_NetWaitConfirm.Hide;
    if Button_NetConfirmYes.Caption = gResTexts[TX_GAMEPLAY_DROP_PLAYERS] then
      gGame.WaitingPlayersDrop else
    if Button_NetConfirmYes.Caption = gResTexts[TX_GAMEPLAY_QUIT_TO_MENU] then
      StopPlay(grCancel);
  end
  else raise Exception.Create('Wrong Sender in NetWaitClick');
end;


procedure TKMGamePlayInterface.DirectionCursorShow(X,Y: Integer; Dir: TKMDirection);
begin
  Image_DirectionCursor.Visible := True;
  Image_DirectionCursor.Left    := X + gRes.Cursors.CursorOffset(Dir).X;
  Image_DirectionCursor.Top     := Y + gRes.Cursors.CursorOffset(Dir).Y;
  Image_DirectionCursor.TexID   := gRes.Cursors.CursorTexID(Dir);
end;


procedure TKMGamePlayInterface.DirectionCursorHide;
begin
  Image_DirectionCursor.Visible := False;
end;


procedure TKMGamePlayInterface.ReleaseDirectionSelector;
begin
  if SelectingTroopDirection then
  begin
    // Reset the cursor position as it will have moved during direction selection
    SetCursorPos(gMain.ClientToScreen(SelectingDirPosition).X, gMain.ClientToScreen(SelectingDirPosition).Y);
    gMain.ApplyCursorRestriction; // Reset the cursor restrictions from selecting direction
    SelectingTroopDirection := False;
    gRes.Cursors.Cursor := kmcDefault; // Reset direction selection cursor when mouse released
    DirectionCursorHide;
  end;
end;


function TKMGamePlayInterface.HasLostMPGame: Boolean;
begin
  Result := (fUIMode = umMP) and gMySpectator.Hand.AI.HasLost;
end;


// Assign Object to a Key
// we use ID to avoid use of pointer counter
procedure TKMGamePlayInterface.Selection_Assign(aId: Word; aObject: TObject);
begin
  if not InRange(aId, Low(fSelection), High(fSelection)) then Exit;

  if aObject is TKMUnit then
    fSelection[aId] := TKMUnit(aObject).UID
  else
  if aObject is TKMHouse then
    fSelection[aId] := TKMHouse(aObject).UID
  else
  if aObject is TKMUnitGroup then
    fSelection[aId] := TKMUnitGroup(aObject).UID
  else
    fSelection[aId] := -1;

  gGame.GameInputProcess.CmdGame(gicGameHotkeySet, aId, fSelection[aId]);
end;


procedure TKMGamePlayInterface.Selection_Link(aId: Word; aObject: TObject);
var
  G: TKMUnitGroup;
begin
  G := gHands.GetGroupByUID(fSelection[aId]);
  if (aObject <> G) and (aObject is TKMUnitGroup) and (G is TKMUnitGroup)
  and (TKMUnitGroup(aObject).GroupType = G.GroupType) then
  begin
    gSoundPlayer.PlayWarrior(TKMUnitGroup(aObject).UnitType, spJoin); // In SP joining is instant, aObject does not exist after that
    gGame.GameInputProcess.CmdArmy(gicArmyLink, TKMUnitGroup(aObject), G);
  end;
end;


procedure TKMGamePlayInterface.Selection_Select(aId: Word);
const
  SELECT_TWICE_MAX_DELAY = 700; //0.7 second
var
  oldSelected: TObject;

  procedure CheckSelectTwice(aPos: TKMPointF);
  begin
    // Selecting an object twice (during short period of time) is the shortcut to center on that unit
    if (oldSelected = gMySpectator.Selected)
      and (TimeSince(fLastKbdSelectionTime) < SELECT_TWICE_MAX_DELAY) then
      fViewport.Position := aPos;
    fLastKbdSelectionTime := TimeGet;
  end;

begin
  if gMySpectator.Hand.InCinematic then
    Exit;

  if not InRange(aId, Low(fSelection), High(fSelection)) then Exit;

  if fSelection[aId] <> -1 then
  begin
    oldSelected := gMySpectator.Selected;
    gMySpectator.Selected := gHands.GetUnitByUID(fSelection[aId]);
    if gMySpectator.Selected <> nil then
    begin
      if TKMUnit(gMySpectator.Selected).IsDeadOrDying then
      begin
        gMySpectator.Selected := nil; // Don't select dead/dying units
        Exit;
      end;
      if (oldSelected <> gMySpectator.Selected) and (fUIMode in [umSP, umMP]) and not HasLostMPGame then
        gSoundPlayer.PlayCitizen(TKMUnit(gMySpectator.Selected).UnitType, spSelect);

      CheckSelectTwice(TKMUnit(gMySpectator.Selected).PositionF);
    end
    else
    begin
      gMySpectator.Selected := gHands.GetHouseByUID(fSelection[aId]);
      if gMySpectator.Selected <> nil then
      begin
        fGuiGameHouse.AskDemolish := False; //Close AskDemolish dialog, if was open by setting AskDemolish flag to False
        if TKMHouse(gMySpectator.Selected).IsDestroyed then
        begin
          gMySpectator.Selected := nil; // Don't select destroyed houses
          Exit;
        end;

        CheckSelectTwice(KMPointF(TKMHouse(gMySpectator.Selected).Entrance));
      end
      else
      begin
        gMySpectator.Selected := gHands.GetGroupByUID(fSelection[aId]);
        if (gMySpectator.Selected = nil) or TKMUnitGroup(gMySpectator.Selected).IsDead then
        begin
          gMySpectator.Selected := nil; // Don't select dead groups
          Exit;
        end;
        TKMUnitGroup(gMySpectator.Selected).SelectFlagBearer;
        if (oldSelected <> gMySpectator.Selected) and (fUIMode in [umSP, umMP]) and not HasLostMPGame then
          gSoundPlayer.PlayWarrior(TKMUnitGroup(gMySpectator.Selected).SelectedUnit.UnitType, spSelect);

        CheckSelectTwice(TKMUnitGroup(gMySpectator.Selected).SelectedUnit.PositionF);
      end;
    end;
  end;

  // In a replay we want in-game statistics (and other things) to be shown for the owner of the last select object
  if fUIMode in [umReplay, umSpectate] then
  begin
    if gMySpectator.Selected is TKMHouse      then gMySpectator.HandID := TKMHouse    (gMySpectator.Selected).Owner;
    if gMySpectator.Selected is TKMUnit       then gMySpectator.HandID := TKMUnit     (gMySpectator.Selected).Owner;
    if gMySpectator.Selected is TKMUnitGroup  then gMySpectator.HandID := TKMUnitGroup(gMySpectator.Selected).Owner;
    Dropbox_ReplayFOW.SelectByTag(gMySpectator.HandID);
    if Checkbox_ReplayFOW.Checked then
      gMySpectator.FOWIndex := gMySpectator.HandID
    else
      gMySpectator.FOWIndex := -1;
    fMinimap.Update; // Force update right now so FOW doesn't appear to lag
  end;

  UpdateSelectedObject;
end;


procedure TKMGamePlayInterface.SelectUnit(aUnit: TKMUnit);
begin
  gMySpectator.Selected := aUnit;
  if (fUIMode in [umSP, umMP]) and not HasLostMPGame then
    gSoundPlayer.PlayCitizen(aUnit.UnitType, spSelect); // play unit selection sound
end;


procedure TKMGamePlayInterface.SelectUnitGroup(aGroup: TKMUnitGroup);
begin
  gMySpectator.Selected := aGroup;
  aGroup.SelectFlagBearer;
  if (fUIMode in [umSP, umMP]) and not HasLostMPGame then
    gSoundPlayer.PlayWarrior(aGroup.SelectedUnit.UnitType, spSelect); // play unit group selection sound
end;


// Select next building/unit/unit group with the same type for same owner
procedure TKMGamePlayInterface.SelectNextGameObjWSameType;
var
  nextHouse: TKMHouse;
  nextUnit: TKMUnit;
  nextUnitGroup: TKMUnitGroup;
begin
  if gMySpectator.Hand.InCinematic then
    Exit;

  if gMySpectator.Selected is TKMUnit then
  begin
    nextUnit := gHands.GetNextUnitWSameType(TKMUnit(gMySpectator.Selected));
    if nextUnit <> nil then
    begin
      SelectUnit(nextUnit);
      fViewport.Position := nextUnit.PositionF; //center viewport on that unit
    end;

  end else if gMySpectator.Selected is TKMHouse then
  begin
    nextHouse := gHands.GetNextHouseWSameType(TKMHouse(gMySpectator.Selected));
    if nextHouse <> nil then
    begin
      gMySpectator.Selected := nextHouse;
      fViewport.Position := KMPointF(nextHouse.Entrance); //center viewport on that house
    end;

  end else if gMySpectator.Selected is TKMUnitGroup then
  begin
    nextUnitGroup := gHands.GetNextGroupWSameType(TKMUnitGroup(gMySpectator.Selected));
    if nextUnitGroup <> nil then
    begin
      SelectUnitGroup(nextUnitGroup);
      fViewport.Position := nextUnitGroup.SelectedUnit.PositionF; //center viewport on that unit
    end;

  end;

  UpdateSelectedObject;
end;


procedure TKMGamePlayInterface.ChatMessage(const aData: UnicodeString);
begin
  fGuiGameChat.ChatMessage(aData);

  if not fGuiGameChat.Visible then
    Label_ChatUnread.Caption := IntToStr(StrToIntDef(Label_ChatUnread.Caption, 0) + 1); // New message
end;


function TKMGamePlayInterface.CanUpdateClockUI: Boolean;
begin
  if gGame = nil then Exit(False);
  
  //Don't show speed clock in MP (unless there is not human players) since you can't turn it on/off
  Result := gGame.IsSpeedUpAllowed or gGameSettings.ShowGameTime or SHOW_GAME_TICK;
end;


procedure TKMGamePlayInterface.UpdateClockUI;
begin
  if gGame = nil then Exit;

  if CanUpdateClockUI then
    UpdateClock(gGame.SpeedActual, gGame.SpeedGIP, gGameParams.IsReplay);
end;


procedure TKMGamePlayInterface.AlliesOnPlayerSetup;
var
  I, K, netI: Integer;
  localeID: Integer;
begin
  if not gGameParams.IsMultiPlayerOrSpec then Exit;

  Image_AlliesHostStar.Hide;
  // Can't vote if we already have, and spectators don't get to vote unless there's only spectators left
  Button_Menu_ReturnLobby.Enabled := not gNetworking.MyNetPlayer.VotedYes
                                     and (gNetworking.NetPlayers.HasOnlySpectators
                                          or not gNetworking.MyNetPlayer.IsSpectator);

  UpdateNetPlayersMapping;

  //Hide extra player lines
  for I := fPlayerLinesCnt to MAX_LOBBY_SLOTS - 1 do
  begin
    Label_AlliesPlayer[I].Hide;
    DropBox_AlliesTeam[I].Hide;
    Label_AlliesTeam[I].Hide;
  end;

  I := 0;
  for K := 0 to fPlayerLinesCnt - 1 do
  begin
    netI := fLineIdToNetPlayerId[K];

    if netI = -1 then Continue; //In case we have AI players at hand, without NetI

    // Show players locale flag
    if gNetworking.NetPlayers[netI].IsComputer then
      Image_AlliesFlag[I].TexID := GetAIPlayerIcon(gNetworking.NetPlayers[netI].PlayerNetType)
    else
    begin
      localeID := gResLocales.IndexByCode(gNetworking.NetPlayers[netI].LangCode);
      if localeID <> -1 then
        Image_AlliesFlag[I].TexID := gResLocales[localeID].FlagSpriteID
      else
        Image_AlliesFlag[I].TexID := 0;
    end;
    if gNetworking.HostIndex = netI then
    begin
      Image_AlliesHostStar.Visible := True;
      Image_AlliesHostStar.Left := 190 + (I div ALLIES_ROWS)*380;
      Image_AlliesHostStar.Top := 80 + (I mod ALLIES_ROWS)*20;
    end;

    if gNetworking.NetPlayers[netI].IsHuman then
      Label_AlliesPlayer[I].Caption := gNetworking.NetPlayers[netI].NiknameU
    else
      Label_AlliesPlayer[I].Caption := gHands[gNetworking.NetPlayers[netI].HandIndex].OwnerName;

    if (gNetworking.MyIndex <> netI)                // If not my player
      and gNetworking.NetPlayers[netI].IsHuman then // and is not Computer
    begin
      Update_Image_AlliesMute(Image_AlliesMute[I]);
      Image_AlliesMute[I].DoSetVisible; //Do not use .Show here, because we do not want change Parent.Visible status from here
    end;

    if gNetworking.NetPlayers[netI].IsSpectator then
    begin
      Label_AlliesPlayer[I].FontColor := gNetworking.NetPlayers[netI].FlagColorDef;
      DropBox_AlliesTeam[I].ItemIndex := 0;
      Label_AlliesTeam[I].Caption := gResTexts[TX_LOBBY_SPECTATOR];
    end
    else
    begin
      Label_AlliesPlayer[I].FontColor := gHands[gNetworking.NetPlayers[netI].HandIndex].FlagColor;
      DropBox_AlliesTeam[I].ItemIndex := gNetworking.NetPlayers[netI].Team;
      if gNetworking.NetPlayers[netI].Team = 0 then
        Label_AlliesTeam[I].Caption := '-'
      else
        Label_AlliesTeam[I].Caption := IntToStr(gNetworking.NetPlayers[netI].Team);

      case gHands[gNetworking.NetPlayers[netI].HandIndex].AI.WonOrLost of
        wolNone: Image_AlliesWinLoss[I].Hide;
        wolWon:  begin
                    Image_AlliesWinLoss[I].TexId := 8;
                    Image_AlliesWinLoss[I].Hint := gResTexts[TX_PLAYER_WON];
                    Image_AlliesWinLoss[I].DoSetVisible;
                  end;
        wolLost: begin
                    Image_AlliesWinLoss[I].TexId := 87;
                    Image_AlliesWinLoss[I].Hint := gResTexts[TX_PLAYER_LOST];
                    Image_AlliesWinLoss[I].DoSetVisible;
                  end;
      end;
    end;
    // Strikethrough for disconnected players
    Image_AlliesMute[I].Enabled := not gNetworking.NetPlayers[netI].Dropped;
    if gNetworking.NetPlayers[netI].Dropped then
      Image_AlliesMute[I].Hint := '';
    Image_AlliesFlag[I].Enabled := not gNetworking.NetPlayers[netI].Dropped;
    Label_AlliesPlayer[I].Strikethrough := gNetworking.NetPlayers[netI].Dropped;
    // Do not strike throught '-' symbol, when player has no team
    Label_AlliesTeam[I].Strikethrough := gNetworking.NetPlayers[netI].Dropped
                                         and (gNetworking.NetPlayers[netI].Team <> 0);
    Label_AlliesPing[I].Strikethrough := gNetworking.NetPlayers[netI].Dropped;
    Label_AlliesFPS[I].Strikethrough := gNetworking.NetPlayers[netI].Dropped;
    DropBox_AlliesTeam[I].Enabled := (netI = gNetworking.MyIndex); // Our index
    DropBox_AlliesTeam[I].Hide; // Use label for demos until we fix exploits

    Inc(I);
  end;

  UpdateClockUI;
end;


procedure TKMGamePlayInterface.AlliesOnPingInfo;
var
  I, K, netI: Integer;
  ping: Word;
  fps: Cardinal;
begin
  UpdateNetPlayersMapping;

  I := 0;
  for K := 0 to fPlayerLinesCnt - 1 do
  begin
    netI := fLineIdToNetPlayerId[K];

    if netI = -1 then Continue; //In case we have AI players at hand, without NetI

    if (I < gNetworking.NetPlayers.Count) and (gNetworking.NetPlayers[netI].IsHuman) then
    begin
      ping := gNetworking.NetPlayers[netI].GetInstantPing;
      fps := gNetworking.NetPlayers[netI].FPS;
      Label_AlliesPing[I].Caption := WrapColor(IntToStr(ping), GetPingColor(ping));
      Label_AlliesPingFpsSlash[I].Caption := '/';
      Label_AlliesFPS[I].Caption := WrapColor(IntToStr(fps), GetFPSColor(fps));
    end else begin
      Label_AlliesPing[I].Caption := '';
      Label_AlliesPingFpsSlash[I].Caption := '';
      Label_AlliesFPS[I].Caption := '';
    end;
    Inc(I);
  end;
end;


procedure TKMGamePlayInterface.AlliesTeamChange(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to MAX_LOBBY_SLOTS - 1 do
    if (Sender = DropBox_AlliesTeam[I]) and DropBox_AlliesTeam[I].Enabled then
      gGame.GameInputProcess.CmdGame(gicGameTeamChange, I+1, DropBox_AlliesTeam[I].ItemIndex);
end;


procedure TKMGamePlayInterface.KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);
var
  rect: TKMRect;
  keyHandled: Boolean;
begin
  aHandled := True; // assume we handle all keys here

  if gGame.IsPaused and (fUIMode in [umSP, umMP]) then Exit;

  if fMyControls.KeyDown(Key, Shift) then
  begin
    fViewport.ReleaseScrollKeys; // Release the arrow keys when you open a window with an edit to stop them becoming stuck
    Exit;
  end;

  inherited KeyDown(Key, Shift, keyHandled);
  if keyHandled then Exit;

    // As we don't have names for teams in SP we only allow showing team names in MP or MP replays
  if (Key = gResKeys[kfShowTeams].Key) then
    if SHOW_UIDs or (fUIMode in [umMP, umSpectate]) or (gGameParams.Mode = gmReplayMulti) then //Only MP replays
    begin
      fShowTeamNames := True;
      // Update it immediately so there's no 300ms lag after pressing the key
      fUnitsTeamNames.Clear;
      rect := fViewport.GetMinimapClip;
      gHands.GetUnitsInRect(rect, fUnitsTeamNames);
      if SHOW_UIDs then
      begin
        fGroupsTeamNames.Clear;
        fHousesTeamNames.Clear;
        gHands.GetGroupsInRect(rect, fGroupsTeamNames);
        gHands.GetHousesInRect(rect, fHousesTeamNames);
      end;

    end;

  CheckMessageKeys(Key);
end;


procedure TKMGamePlayInterface.GameStarted;
begin
  if gGameParams.IsMultiPlayerOrSpec and (gGameApp.Chat.Text <> '') then
    fGuiGameChat.Show;
end;


function TKMGamePlayInterface.GetToolBarWidth: Integer;
begin
  Result := TOOLBAR_WIDTH;
end;


function TKMGamePlayInterface.CanShowChat: Boolean;
begin
  Result := (fUIMode in [umMP, umSpectate]) or ((fUIMode = umSP) and gScriptEvents.HasConsoleCommands);
end;


function TKMGamePlayInterface.CanShowAllies: Boolean;
begin
  Result := fUIMode in [umMP, umSpectate];
end;


procedure TKMGamePlayInterface.CheckMessageKeys(Key: Word);
var
  I: Integer;
  lastAlert: TKMAlert;
  msg: TKMLogMessage;
begin
  // Messages
  if Key = gResKeys[kfCenterAlert].Key then
  begin
    // Spacebar centers you on the latest alert
    lastAlert := fAlerts.GetLatestAlert;
    if lastAlert <> nil then
      fViewport.Position := lastAlert.Loc
    else
    begin
      //If there are no active alerts, then centers on last unread message in log (house / unit)
      for I := gMySpectator.Hand.MessageLog.CountLog - 1 downto Max(gMySpectator.Hand.MessageLog.CountLog - MAX_LOG_MSGS, 0) do
      begin
        msg := gMySpectator.Hand.MessageLog[I];
        
        if not msg.IsRead and msg.IsGoto then
        begin
          MessageLog_ShowMessage(I);
          Break;
        end;
      end;
    end;
  end;

  if Key = gResKeys[kfDeleteMsg].Key then
    Button_MessageDelete.Click;

  // Enter is the shortcut to bring up chat in multiplayer
  if (Key = gResKeys[kfChat].Key) and CanShowChat then
  begin
    if not fGuiGameChat.Visible then
    begin
      Allies_Close(nil);
      Message_Close(nil);
      MessageLog_Close(nil);
      Label_ChatUnread.Caption := ''; // No unread messages
      fGuiGameChat.Show;
    end else
      fGuiGameChat.Focus;
  end;
end;


// Note: we deliberately don't pass any Keys to MyControls when game is not running
// thats why MyControls.KeyUp is only in gsRunning clause
// Ignore all keys if game is on 'Pause'
procedure TKMGamePlayInterface.KeyUp(Key: Word; Shift: TShiftState; var aHandled: Boolean);

  function SpeedChangeAllowed(aUIModes: TUIModeSet): Boolean;
  begin
    Result := (fUIMode in aUIModes)
              or gGame.CanChangeMPGameSpeed
              or MULTIPLAYER_SPEEDUP;
  end;

  function OnPause: Boolean;
  begin
    Result := gGame.IsPaused
              and (SpeedChangeAllowed([umSP])
                or ((PAUSE_GAME_BEFORE_TICK <> -1) and (fUIMode <> umReplay)));
  end;

var
  selectId: Integer;
  specPlayerIndex: ShortInt;
  keyFunc: TKMKeyFunction;
  keyAreas: TKMKeyFuncAreaSet;
  keyHandled: Boolean;
begin
  aHandled := True; // assume we handle all keys here

  if OnPause then
  begin
    if Key = gResKeys[kfPause].Key then
      SetPause(False);

    keyAreas := [faCommon, faGame];

    if (fUIMode in [umReplay, umSpectate]) then
      Include(keyAreas, faSpecReplay);

    keyFunc := gResKeys.GetKeyFunctionForKey(Key, keyAreas);

    if (keyFunc = kfNone) or not (keyFunc in KEY_FUNCS_ALLOWED_ON_PAUSE) then
      Exit;
  end;

  if fMyControls.KeyUp(Key, Shift) then Exit;

  keyHandled := False;
  inherited KeyUp(Key, Shift, keyHandled);
  if keyHandled then
    fGuiMenuSettings.Refresh;

  if (fUIMode = umReplay) and (Key = gResKeys[kfPause].Key) then
  begin
    if Button_ReplayPause.Enabled or not gGame.IsPaused then
      ReplayClick(Button_ReplayPause)
    else if Button_ReplayResume.Enabled or gGame.IsPaused then
      ReplayClick(Button_ReplayResume);
  end;

  // These keys are allowed during replays
  if Key = gResKeys[kfShowTeams].Key then fShowTeamNames := False;
  if Key = gResKeys[kfBeacon].Key then
    if not SelectingTroopDirection then
    begin
      fPlacingBeacon := True;
      MinimapView.ClickableOnce := True;
      gRes.Cursors.Cursor := kmcBeacon;
    end;
  if Key = gResKeys[kfCloseMenu].Key then
  begin
    // Progressively hide open elements on Esc
    if fGuiGameUnit.JoiningGroups then
      fGuiGameUnit.Army_HideJoinMenu(nil)
    else
    if fShownMessage <> -1 then
      Message_Close(nil)
    else
    if fGuiGameChat.Visible then
      fGuiGameChat.Hide
    else
    if Panel_Allies.Visible then
      Allies_Close(nil)
    else
    if Panel_MessageLog.Visible then
      MessageLog_Close(nil)
    else
    if Button_Back.Visible then
      SwitchPage(Button_Back);
  end;

  // Dynamic key-binding means we cannot use "case of"
  if Key = gResKeys[kfSelect1].Key  then selectId := 0 else
  if Key = gResKeys[kfSelect2].Key  then selectId := 1 else
  if Key = gResKeys[kfSelect3].Key  then selectId := 2 else
  if Key = gResKeys[kfSelect4].Key  then selectId := 3 else
  if Key = gResKeys[kfSelect5].Key  then selectId := 4 else
  if Key = gResKeys[kfSelect6].Key  then selectId := 5 else
  if Key = gResKeys[kfSelect7].Key  then selectId := 6 else
  if Key = gResKeys[kfSelect8].Key  then selectId := 7 else
  if Key = gResKeys[kfSelect9].Key  then selectId := 8 else
  if Key = gResKeys[kfSelect10].Key then selectId := 9 else
  if Key = gResKeys[kfSelect11].Key  then selectId := 10 else
  if Key = gResKeys[kfSelect12].Key  then selectId := 11 else
  if Key = gResKeys[kfSelect13].Key  then selectId := 12 else
  if Key = gResKeys[kfSelect14].Key  then selectId := 13 else
  if Key = gResKeys[kfSelect15].Key  then selectId := 14 else
  if Key = gResKeys[kfSelect16].Key  then selectId := 15 else
  if Key = gResKeys[kfSelect17].Key  then selectId := 16 else
  if Key = gResKeys[kfSelect18].Key  then selectId := 17 else
  if Key = gResKeys[kfSelect19].Key  then selectId := 18 else
  if Key = gResKeys[kfSelect20].Key then selectId := 19 else
    selectId := -1;

  if selectId <> -1 then
    if (ssCtrl in Shift) then
      Selection_Assign(selectId, gMySpectator.Selected)
    else
    if (ssShift in Shift) and (fUIMode in [umSP, umMP]) then
      Selection_Link(selectId, gMySpectator.Selected)
    else
      Selection_Select(selectId);

  // Menu shortcuts
  if Key = gResKeys[kfMenuBuild].Key then
    if Button_Main[tbBuild].Enabled then
      SwitchPage(Button_Main[tbBuild]);

  if Key = gResKeys[kfMenuRatio].Key then
    if Button_Main[tbRatio].Enabled then
      SwitchPage(Button_Main[tbRatio]);

  if Key = gResKeys[kfMenuStats].Key then
    if Button_Main[tbStats].Enabled then
      SwitchPage(Button_Main[tbStats]);

  if Key = gResKeys[kfMenuMenu].Key then
    SwitchPage(Button_Main[tbMenu]);

  // Switch between same type buildings/units/groups
  if (Key = gResKeys[kfNextEntitySameType].Key)
    and (gMySpectator.Selected <> nil) then
  begin
    SelectNextGameObjWSameType;
  end;

  if (Key = gResKeys[kfPlayerColorMode].Key) then
  begin
    if fUIMode in [umReplay, umSpectate] then
      gGameSettings.PlayersColorMode := TKMPlayerColorMode((Byte(gGameSettings.PlayersColorMode) mod 3) + 1)
    else
    begin
      if gGameSettings.PlayersColorMode = pcmDefault then
        gGameSettings.PlayersColorMode := pcmAllyEnemy
      else
        gGameSettings.PlayersColorMode := pcmDefault;
    end;
    GameSettingsChanged;
    //Update minimap immidiately
//    fMinimap.Update;
  end;

  if   (Key = gResKeys[kfSpeedup1].Key)
    or (Key = gResKeys[kfSpeedup2].Key)
    or (Key = gResKeys[kfSpeedup3].Key)
    or (Key = gResKeys[kfSpeedup4].Key) then
  begin
    if SpeedChangeAllowed([umSP, umReplay]) then
    begin
      // Game speed/pause: available in multiplayer mode if the only player left in the game
      if Key = gResKeys[kfSpeedup1].Key then
        gGame.SetSpeed(GAME_SPEED_NORMAL, True, gGame.SpeedGIP);
      if Key = gResKeys[kfSpeedup2].Key then
        gGame.SetSpeed(gGameSettings.SpeedMedium, True);
      if Key = gResKeys[kfSpeedup3].Key then
        gGame.SetSpeed(gGameSettings.SpeedFast, True);
      if Key = gResKeys[kfSpeedup4].Key then
        gGame.SetSpeed(gGameSettings.SpeedVeryFast, True);
    end
    else
    if fUIMode in [umMP, umSpectate] then
    begin
      if not gGame.CanChangeMPGameSpeed then
      begin
        // Show local message why speedup is not allowed
        gNetworking.PostLocalMessage(gResTexts[TX_GAME_CHANGE_IS_NOT_ALLOWED_MSG]);
        gSoundPlayer.Play(sfxCantPlace);
      end;
    end;
  end;

  // First check if this key was associated with some Spectate/Replay key
  if (fUIMode in [umReplay, umSpectate]) then
  begin
    if Key = gResKeys[kfSpecpanelSelectDropbox].Key then
      fGuiGameSpectator.DropBox.SwitchOpen;

    if Key = gResKeys[kfSpectatePlayer1].Key then
      specPlayerIndex := 1
    else if Key = gResKeys[kfSpectatePlayer2].Key then
      specPlayerIndex := 2
    else if Key = gResKeys[kfSpectatePlayer3].Key then
      specPlayerIndex := 3
    else if Key = gResKeys[kfSpectatePlayer4].Key then
      specPlayerIndex := 4
    else if Key = gResKeys[kfSpectatePlayer5].Key then
      specPlayerIndex := 5
    else if Key = gResKeys[kfSpectatePlayer6].Key then
      specPlayerIndex := 6
    else if Key = gResKeys[kfSpectatePlayer7].Key then
      specPlayerIndex := 7
    else if Key = gResKeys[kfSpectatePlayer8].Key then
      specPlayerIndex := 8
    else if Key = gResKeys[kfSpectatePlayer9].Key then
      specPlayerIndex := 9
    else if Key = gResKeys[kfSpectatePlayer10].Key then
      specPlayerIndex := 10
    else if Key = gResKeys[kfSpectatePlayer11].Key then
      specPlayerIndex := 11
    else if Key = gResKeys[kfSpectatePlayer12].Key then
      specPlayerIndex := 12
    else
      specPlayerIndex := -1;

    if (specPlayerIndex <> -1) and (Dropbox_ReplayFOW.Count >= specPlayerIndex) then
    begin
      //Jump to player when ALT is also pressed
      if ssAlt in Shift then
      begin
        Replay_DropBox_JumpToPlayer(specPlayerIndex - 1);
        Exit;
      end else if ssShift in Shift then //Select player when SHIFT is also pressed
      begin
        Replay_ViewPlayer(specPlayerIndex - 1);
        Exit;
      end;
    end;

    if (Key = gResKeys[kfReplayPlayNextTick].Key) and Button_ReplayStep.IsClickable then
      ReplayClick(Button_ReplayStep);
  end;

  fGuiGameUnit.KeyUp(Key, Shift, keyHandled);
  fGuiGameHouse.KeyUp(Key, Shift, keyHandled);

  // All the following keys don't work in Replay, because they alter game state
  // which is nonsense
  // thus the easy way to make that is to exit now
  if fUIMode = umReplay then Exit;

  // Field plans hotkeys
  if Button_Main[tbBuild].Enabled then
  begin
    if Key = gResKeys[kfPlanRoad].Key then
    begin
      if not fGuiGameBuild.Visible then
        SwitchPage(Button_Main[tbBuild]);
      fGuiGameBuild.PlanRoad;
    end;

    if Key = gResKeys[kfPlanField].Key then
    begin
      if not fGuiGameBuild.Visible then
        SwitchPage(Button_Main[tbBuild]);
      fGuiGameBuild.PlanField;
    end;

    if Key = gResKeys[kfPlanWine].Key then
    begin
      if not fGuiGameBuild.Visible then
        SwitchPage(Button_Main[tbBuild]);
      fGuiGameBuild.PlanWine;
    end;

    if Key = gResKeys[kfErasePlan].Key then
    begin
      if not fGuiGameBuild.Visible then
        SwitchPage(Button_Main[tbBuild]);
      fGuiGameBuild.ErasePlan;
      gRes.Cursors.Cursor := kmcDefault; //Reset cursor, as it could be kmcInfo, f.e.
    end;
  end;

  // General function keys
  if (Key = gResKeys[kfPause].Key)
    and SpeedChangeAllowed([umSP]) then
      SetPause(True); // Display pause overlay

  { Temporary cheat codes }
  if DEBUG_CHEATS and (MULTIPLAYER_CHEATS or (fUIMode = umSP)) then
  begin
    if Key = gResKeys[kfDebugRevealmap].Key then gGame.GameInputProcess.CmdTemp(gicTempRevealMap);
    if Key = gResKeys[kfDebugVictory].Key   then gGame.GameInputProcess.CmdTemp(gicTempVictory);
    if Key = gResKeys[kfDebugDefeat].Key    then gGame.GameInputProcess.CmdTemp(gicTempDefeat);
    if Key = gResKeys[kfDebugAddscout].Key  then gGame.GameInputProcess.CmdTemp(gicTempAddScout, gGameCursor.Cell);
  end;
end;


// 1. Process Controls
// 2. Show SelectingTroopDirection
procedure TKMGamePlayInterface.MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);

  procedure HandleFieldLMBDown(const P: TKMPoint; aFieldType: TKMFieldType);
  begin
    //Set cursor into 'Plan' mode by default,
    //even if we click where plan could not be placed we could plan it with mouse move later
    gGameCursor.Tag1 := Byte(cfmPlan);
    if gMySpectator.Hand.CanAddFakeFieldPlan(P, aFieldType) then
    begin
      gGame.GameInputProcess.CmdBuild(gicBuildToggleFieldPlan, P, aFieldType);
      fLastDragPoint := gGameCursor.Cell;
    end else if gMySpectator.Hand.CanRemFakeFieldPlan(P, aFieldType) then
    begin
      gGame.GameInputProcess.CmdBuild(gicBuildToggleFieldPlan, P, aFieldType);
      fLastDragPoint := gGameCursor.Cell;
      // Set cursor into "Erase" mode, so dragging it will erase next tiles with the same field type
      gGameCursor.Tag1 := Byte(cfmErase);
    end
  end;

var
  group: TKMUnitGroup;
  obj: TObject;
  canWalkTo: Boolean;
  P: TKMPoint;
  {$IFDEF MSWindows}
  windowRect: TRect;
  {$ENDIF}
begin
  fMyControls.MouseDown(X, Y, Shift, Button);

  if (gGame.IsPaused and (fUIMode in [umSP, umMP])) or (fMyControls.CtrlOver <> nil)
  or gMySpectator.Hand.InCinematic then
    Exit;

  if SelectingTroopDirection then
  begin
    gMain.ApplyCursorRestriction; // Reset the cursor restrictions from selecting direction
    SelectingTroopDirection := false;
    DirectionCursorHide;
  end;

  //Handle field planss
  if Button = mbLeft then
  begin
    P := gGameCursor.Cell; // Get cursor position tile-wise
    if gMySpectator.Hand.FogOfWar.CheckTileRevelation(P.X, P.Y) > 0 then
      case gGameCursor.Mode of
        cmRoad:   HandleFieldLMBDown(P, ftRoad);
        cmField:  HandleFieldLMBDown(P, ftCorn);
        cmWine:   HandleFieldLMBDown(P, ftWine);
      end;
  end;

  // See if we can show DirectionSelector
  if (Button = mbRight)
    and (fUIMode in [umSP, umMP])
    and not HasLostMPGame
    and not fGuiGameUnit.JoiningGroups
    and not fPlacingBeacon
    and (gMySpectator.Selected is TKMUnitGroup) then
  begin
    group := TKMUnitGroup(gMySpectator.Selected);
    obj := gMySpectator.HitTestCursor;

    canWalkTo := True;

    // Group can walk to allies units place
    if obj is TKMUnit then
      canWalkTo := (gMySpectator.Hand.Alliances[TKMUnit(obj).Owner] = atAlly);

    // Can't walk on to a house
    if obj is TKMHouse then
      canWalkTo := False;

    if canWalkTo then
    begin
      if group.CanWalkTo(gGameCursor.Cell, 0) then
      begin
        SelectingTroopDirection := True; // MouseMove will take care of cursor changing
        // Restrict the cursor to inside the main panel so it does not get jammed when used near
        // the edge of the window in windowed mode
        {$IFDEF MSWindows}
        windowRect := gMain.ClientRect;
        ClipCursor(@windowRect);
        {$ENDIF}
        // Now record it as Client XY
        SelectingDirPosition.X := X;
        SelectingDirPosition.Y := Y;
        SelectedDirection := dirNA;
        DirectionCursorShow(X, Y, SelectedDirection);
        gRes.Cursors.Cursor := kmcInvisible;
      end
      else
        gSoundPlayer.Play(sfxCantPlace, gGameCursor.Cell, False, 4);
    end;
  end;
end;


// 1. Process Controls
// 2. Perform SelectingTroopDirection if it is active
// 3. Display various cursors depending on whats below (might be called often)
procedure TKMGamePlayInterface.MouseMove(Shift: TShiftState; X,Y: Integer; var aHandled: Boolean);

  procedure HandleFieldLMBDrag(const P: TKMPoint; aFieldType: TKMFieldType);
  begin
    if not KMSamePoint(fLastDragPoint, P) then
      if (gMySpectator.Hand.CanAddFakeFieldPlan(P, aFieldType)) and (gGameCursor.Tag1 = Byte(cfmPlan)) then
      begin
        gGame.GameInputProcess.CmdBuild(gicBuildToggleFieldPlan, P, aFieldType);
        fLastDragPoint := gGameCursor.Cell;
      end else if (gMySpectator.Hand.CanRemFakeFieldPlan(P, aFieldType)) and (gGameCursor.Tag1 = Byte(cfmErase)) then
      begin
        gGame.GameInputProcess.CmdBuild(gicBuildToggleFieldPlan, P, aFieldType);
        fLastDragPoint := gGameCursor.Cell;
      end;
  end;

var
  deltaX, deltaY, deltaDistanceSqr: Integer;
  newPoint: TPoint;
  entity: TKMHandEntity;
  P: TKMPoint;
  group: TKMUnitGroup;
begin
  inherited MouseMove(Shift, X, Y, aHandled);
  if aHandled then Exit;

  aHandled := True;

  fMyControls.MouseMove(X,Y,Shift);

  if fPlacingBeacon then
  begin
    // Beacons are a special case, the cursor should be shown over controls to (you can place it on the minimap)
    if fMyControls.CtrlOver = nil then
      UpdateGameCursor(X,Y,Shift); // Keep the game cursor up to date
    gRes.Cursors.Cursor := kmcBeacon;
    Exit;
  end;

  if (fMyControls.CtrlOver is TKMDragger) or (fMyControls.CtrlDown is TKMDragger) then Exit;

  if (fMyControls.CtrlOver <> nil)
  and (fMyControls.CtrlOver <> Image_DirectionCursor)
  and not SelectingTroopDirection then
  begin
    // kmcEdit and kmcDragUp are handled by Controls.MouseMove (it will reset them when required)
    if not fViewport.Scrolling and not (gRes.Cursors.Cursor in [kmcEdit,kmcDragUp]) then
      gRes.Cursors.Cursor := kmcDefault;
    Exit;
  end
  else
    DisplayHint(nil); // Clear shown hint

  if gGame.IsPaused and (fUIMode in [umSP, umMP]) then Exit;

  if SelectingTroopDirection then
  begin
    deltaX := SelectingDirPosition.X - X;
    deltaY := SelectingDirPosition.Y - Y;
    deltaDistanceSqr := Sqr(deltaX)+Sqr(deltaY);
    // Manually force the cursor to remain within a circle (+2 to avoid infinite loop due to rounding)
    if deltaDistanceSqr > Sqr(DIR_CURSOR_CIRCLE_RAD+2) then
    begin
      deltaX := Round(deltaX / Sqrt(deltaDistanceSqr) * DIR_CURSOR_CIRCLE_RAD);
      deltaY := Round(deltaY / Sqrt(deltaDistanceSqr) * DIR_CURSOR_CIRCLE_RAD);
      newPoint := gMain.ClientToScreen(SelectingDirPosition);
      newPoint.X := newPoint.X - deltaX;
      newPoint.Y := newPoint.Y - deltaY;
      SetCursorPos(newPoint.X, newPoint.Y);
    end;

    // Compare cursor position and decide which direction it is
    SelectedDirection := KMGetCursorDirection(deltaX, deltaY);
    // Update the cursor based on this direction and negate the offset
    DirectionCursorShow(SelectingDirPosition.X, SelectingDirPosition.Y, SelectedDirection);
    gRes.Cursors.Cursor := kmcInvisible; // Keep it invisible, just in case
    Exit;
  end;

  UpdateGameCursor(X,Y,Shift);

  if ssLeft in Shift then // Only allow placing of roads etc. with the left mouse button
  begin
    P := gGameCursor.Cell; // Get cursor position tile-wise
    if gMySpectator.Hand.FogOfWar.CheckTileRevelation(P.X, P.Y) > 0 then
      case gGameCursor.Mode of
        cmRoad:   HandleFieldLMBDrag(P, ftRoad);
        cmField:  HandleFieldLMBDrag(P, ftCorn);
        cmWine:   HandleFieldLMBDrag(P, ftWine);
        cmErase:  if not KMSamePoint(fLastDragPoint, P) then
                  begin
                    if gMySpectator.Hand.Constructions.HousePlanList.HasPlan(P) then
                    begin
                      gGame.GameInputProcess.CmdBuild(gicBuildRemoveHousePlan, P);
                      fLastDragPoint := gGameCursor.Cell;
                    end
                    else
                      if (gMySpectator.Hand.Constructions.FieldworksList.HasFakeField(P) <> ftNone) then
                      begin
                        gGame.GameInputProcess.CmdBuild(gicBuildRemoveFieldPlan, P); // Remove any plans
                        fLastDragPoint := gGameCursor.Cell;
                      end;
                  end;
      end;
  end;

  if gGameCursor.Mode <> cmNone then
  begin
    // Use the default cursor while placing roads, don't become stuck on c_Info or others
    if not fViewport.Scrolling then
      gRes.Cursors.Cursor := kmcDefault;
    Exit;
  end;

  entity := gMySpectator.HitTestCursor;

  if fGuiGameUnit.JoiningGroups and (gMySpectator.Selected is TKMUnitGroup) then
  begin
    group := TKMUnitGroup(gMySpectator.Selected);
    if (entity <> nil)
    and (entity is TKMUnitWarrior)
    and (entity.Owner = gMySpectator.HandID)
    and not group.HasMember(TKMUnitWarrior(entity))
    and (UNIT_TO_GROUP_TYPE[TKMUnitWarrior(entity).UnitType] = group.GroupType) then
      gRes.Cursors.Cursor := kmcJoinYes
    else
      gRes.Cursors.Cursor := kmcJoinNo;
    Exit;
  end;

  if not gMySpectator.Hand.InCinematic then
  begin
    // Only own and ally units/houses can be selected
    if (entity.Owner <> -1) and
      ((entity.Owner = gMySpectator.HandID)
      or ((ALLOW_SELECT_ALLY_UNITS
          or ((entity is TKMHouse) and TKMHouse(entity).AllowAllyToView))
        and (gMySpectator.Hand.Alliances[entity.Owner] = atAlly))
      or (ALLOW_SELECT_ENEMIES and (gMySpectator.Hand.Alliances[entity.Owner] = atEnemy)) // Enemies can be selected for debug
      or (fUIMode in [umReplay, umSpectate])) then
    begin
      gRes.Cursors.Cursor := kmcInfo;
      Exit;
    end;
  end;

  if (gMySpectator.Selected.IsGroup)
    and (fUIMode in [umSP, umMP]) and not HasLostMPGame
    and not gMySpectator.Hand.InCinematic
    and (gMySpectator.FogOfWar.CheckTileRevelation(gGameCursor.Cell.X, gGameCursor.Cell.Y) > 0) then
  begin
    if (entity <> nil) and (gMySpectator.Hand.Alliances[entity.Owner] = atEnemy) then
      gRes.Cursors.Cursor := kmcAttack
    else
      if not fViewport.Scrolling then
        gRes.Cursors.Cursor := kmcDefault;
    Exit;
  end;

  if not fViewport.Scrolling then
    gRes.Cursors.Cursor := kmcDefault;
end;


procedure TKMGamePlayInterface.MouseUp(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
var
  P, P2: TKMPoint;
  pbj: TObject;
  H: TKMHouse;
  group, group2: TKMUnitGroup;
  oldSelected: TObject;
  oldSelectedUnit: TKMUnitWarrior;
begin
  // Check if mouse was clicked insede MP chat panel
  if not KMInRect(KMPoint(X,Y), fGuiGameChat.PanelChatRect) then
    // Unset chat focus, when mouse clicked outside MP chat panel
    fGuiGameChat.Unfocus
  else
    fGuiGameChat.Focus; // Set focus to MP chat

  if fPlacingBeacon and (Button = mbRight) then
  begin
    Beacon_Cancel;
    if fMyControls.CtrlOver = nil then Exit; // Don't move troops too
  end;

  if (fMyControls.CtrlOver = nil) then
    fMyControls.MouseUp(X,Y,Shift,Button) // That will update control States, f.e.
  else
  if   (fMyControls.CtrlOver <> Image_DirectionCursor)
    and not SelectingTroopDirection then
  begin
    fMyControls.MouseUp(X,Y,Shift,Button);
    Exit;
  end;

  if gGame.IsPaused and (fUIMode in [umSP, umMP]) then Exit;

  P := gGameCursor.Cell; // It's used in many places here

  case Button of
    mbLeft:
      begin
        // Process groups joining
        if fGuiGameUnit.JoiningGroups and (gMySpectator.Selected is TKMUnitGroup) then
        begin
          group := TKMUnitGroup(gMySpectator.Selected);
          pbj := gMySpectator.HitTestCursor;

          if (pbj <> nil)
            and (pbj is TKMUnitWarrior)
            and (TKMUnitWarrior(pbj).Owner = gMySpectator.HandID)
            and not group.HasMember(TKMUnitWarrior(pbj))
            and (UNIT_TO_GROUP_TYPE[TKMUnitWarrior(pbj).UnitType] = group.GroupType) then
          begin
            group2 := gMySpectator.Hand.UnitGroups.GetGroupByMember(TKMUnitWarrior(pbj));
            // Warrior might not have a group yet if he's still walking out of the barracks
            if group2 <> nil then
            begin
              gSoundPlayer.PlayWarrior(group.UnitType, spJoin); // In SP joining is instant, Group does not exist after that
              gGame.GameInputProcess.CmdArmy(gicArmyLink, group, group2);
              if not (ssShift in Shift) then //Do not cancel link mode if Shift is pressed
                fGuiGameUnit.Army_HideJoinMenu(nil);
            end;
          end;
          Exit;
        end;

        if fPlacingBeacon then
        begin
          Beacon_Place(gGameCursor.Float);
          Exit;
        end;

        //Manage only cmNone while spectating / watchingreplay
        if (gGameCursor.Mode <> cmNone) and gGameParams.IsReplayOrSpectate then
          Exit;

        // Only allow placing of roads etc. with the left mouse button
        if gMySpectator.FogOfWar.CheckTileRevelation(P.X, P.Y) = 0 then
        begin
          if (gGameCursor.Mode in [cmErase, cmRoad, cmField, cmWine, cmHouses]) and not gGameParams.IsReplayOrSpectate then
            // Can't place noise when clicking on unexplored areas
            gSoundPlayer.Play(sfxCantPlace, P, False, 4);
        end
        else
          case gGameCursor.Mode of
            cmNone:
              begin
                // Remember previous selection to play sound if it changes
                oldSelected := gMySpectator.Selected;
                oldSelectedUnit := nil;

                if oldSelected is TKMUnitGroup then
                  oldSelectedUnit := TKMUnitGroup(gMySpectator.Selected).SelectedUnit;

                // Don't allow selecting during a cinematic
                if not gMySpectator.Hand.InCinematic then
                  gMySpectator.UpdateSelect;

                // In a replay we want in-game statistics (and other things) to be shown for the owner of the last select object
                if fUIMode in [umReplay, umSpectate] then
                begin
                  Dropbox_ReplayFOW.SelectByTag(gMySpectator.HandID);
                  if Checkbox_ReplayFOW.Checked then
                    gMySpectator.FOWIndex := gMySpectator.HandID
                  else
                    gMySpectator.FOWIndex := -1;
                  fMinimap.Update; // Force update right now so FOW doesn't appear to lag
                end;

                if (gMySpectator.Selected is TKMHouse) then
                begin
                  SwitchPage(nil); // Hide main back button if we were in e.g. stats
                  fGuiGameHouse.Show(TKMHouse(gMySpectator.Selected), False);
                end;

                if (gMySpectator.Selected is TKMUnit) then
                begin
                  SwitchPage(nil);
                  fGuiGameUnit.ShowUnitInfo(TKMUnit(gMySpectator.Selected));
                  if (fUIMode in [umSP, umMP]) and not HasLostMPGame
                    and (oldSelected <> gMySpectator.Selected) then
                    gSoundPlayer.PlayCitizen(TKMUnit(gMySpectator.Selected).UnitType, spSelect);
                end;

                if (gMySpectator.Selected is TKMUnitGroup) then
                begin
                  SwitchPage(nil);
                  group := TKMUnitGroup(gMySpectator.Selected);
                  fGuiGameUnit.ShowGroupInfo(group);
                  if (fUIMode in [umSP, umMP]) and not HasLostMPGame
                    and ((oldSelected <> group) or (oldSelectedUnit <> group.SelectedUnit)) then
                      gSoundPlayer.PlayWarrior(group.SelectedUnit.UnitType, spSelect);
                end;
              end;

            cmRoad:  gGameCursor.Tag1 := Ord(cfmNone);
            cmField: gGameCursor.Tag1 := Ord(cfmNone);
            cmWine:  gGameCursor.Tag1 := Ord(cfmNone);

            cmHouses:
              if gMySpectator.Hand.CanAddHousePlan(P, TKMHouseType(gGameCursor.Tag1)) then
              begin
                gGame.GameInputProcess.CmdBuild(gicBuildHousePlan, P, TKMHouseType(gGameCursor.Tag1));
                // If shift pressed do not reset cursor (keep selected building)
                if not (ssShift in Shift)
                  and not gMySpectator.Hand.NeedToChooseFirstStorehouseInGame then //Do not show Build menu after place first storehouse feature
                  fGuiGameBuild.Show;
              end
              else
                gSoundPlayer.Play(sfxCantPlace, P, False, 4);
            cmErase:
              if KMSamePoint(fLastDragPoint, KMPOINT_ZERO) then
              begin
                H := gMySpectator.Hand.HousesHitTest(P.X, P.Y);
                // Ask wherever player wants to destroy own house (don't ask about houses that are not started, they are removed below)
                if H <> nil then
                begin
                  gMySpectator.Selected := H; // Select the house irregardless of unit below/above
                  //Update select, to set up fIsSelectedMyObj
                  //Don't update selected object again!
                  gMySpectator.UpdateSelect(False);
                  HidePages;
                  SwitchPage(nil); // Hide main back button if we were in e.g. stats
                  fGuiGameHouse.Show(H, True);
                  gSoundPlayer.Play(sfxClick);
                end
                else
                begin
                  // Now remove houses that are not started
                  if gMySpectator.Hand.Constructions.HousePlanList.HasPlan(P) then
                    gGame.GameInputProcess.CmdBuild(gicBuildRemoveHousePlan, P)
                  else
                    if gMySpectator.Hand.Constructions.FieldworksList.HasFakeField(P) <> ftNone then
                      gGame.GameInputProcess.CmdBuild(gicBuildRemoveFieldPlan, P) // Remove plans
                    else
                      gSoundPlayer.Play(sfxCantPlace, P, False, 4); // Otherwise there is nothing to erase
                end;
              end;
          end
      end;
    mbRight:
      begin
        // Cancel build
        if fGuiGameBuild.Visible then
          SwitchPage(Button_Back);

        // Cancel join
        if fGuiGameUnit.JoiningGroups then
        begin
          fGuiGameUnit.Army_HideJoinMenu(nil);
          Exit; // Don't order troops too
        end;

        if not fPlacingBeacon
          and ((gMySpectator.Selected is TKMHouseBarracks)
            or (gMySpectator.Selected is TKMHouseTownHall)
            or (gMySpectator.Selected is TKMHouseWoodcutters))
          and (fUIMode in [umSP, umMP])
          and not HasLostMPGame then
        begin
          P2 := TKMHouse(gMySpectator.Selected).PointBelowEntrance;
          if gTerrain.Route_CanBeMade(P2, P, tpWalk, 0)
            or gTerrain.Route_CanBeMade(KMPointLeft(P2), P, tpWalk, 0)
            or gTerrain.Route_CanBeMade(KMPointRight(P2), P, tpWalk, 0) then
          begin
            if gMySpectator.Selected is TKMHouseBarracks then
              gGame.GameInputProcess.CmdHouse(gicHouseBarracksRally, TKMHouse(gMySpectator.Selected), P)
            else
            if gMySpectator.Selected is TKMHouseTownHall then
              gGame.GameInputProcess.CmdHouse(gicHouseTownHallRally, TKMHouse(gMySpectator.Selected), P)
            else
              if gMySpectator.Selected is TKMHouseWoodcutters then
                gGame.GameInputProcess.CmdHouse(gicHouseWoodcuttersCutting, TKMHouse(gMySpectator.Selected), P);
          end
          else
            gSoundPlayer.Play(sfxCantPlace, P, False, 4);
          Exit;
        end;

        // Process warrior commands
        if (fUIMode in [umSP, umMP])
          and not HasLostMPGame
          and not fGuiGameUnit.JoiningGroups
          and not fPlacingBeacon
          and (gMySpectator.Selected is TKMUnitGroup) then
        begin
          group := TKMUnitGroup(gMySpectator.Selected);

          // Attack or Walk
          if group.CanTakeOrders and (group.Owner = gMySpectator.HandID) then
          begin
            // Try to Attack unit
            pbj := gMySpectator.HitTestCursor;
            if (pbj is TKMUnit) and (gMySpectator.Hand.Alliances[TKMUnit(pbj).Owner] = atEnemy) then
            begin
              gGame.GameInputProcess.CmdArmy(gicArmyAttackUnit, group, TKMUnit(pbj));
              gSoundPlayer.PlayWarrior(group.UnitType, spAttack);
            end
            else
            // If there's no unit - try to Attack house
            if (pbj is TKMHouse) and (gMySpectator.Hand.Alliances[TKMHouse(pbj).Owner] = atEnemy) then
            begin
              gGame.GameInputProcess.CmdArmy(gicArmyAttackHouse, group, TKMHouse(pbj));
              gSoundPlayer.PlayWarrior(group.UnitType, spAttack);
            end
            else
            // Ensure down click was successful (could have been over a mountain, then dragged to a walkable location)
            if SelectingTroopDirection and group.CanWalkTo(P, 0) then
            begin
              gGame.GameInputProcess.CmdArmy(gicArmyWalk, group, P, SelectedDirection);
              gSoundPlayer.PlayWarrior(group.UnitType, spMove);
            end;
          end;
        end;
        // Not selecting direction now (must do it at the end because SelectingTroopDirection is used for Walk above)
        ReleaseDirectionSelector;
      end;
  end;

  fLastDragPoint := KMPOINT_ZERO;
end;


procedure TKMGamePlayInterface.Save(SaveStream: TKMemoryStream);
begin
  fViewport.Save(SaveStream);

  fGuiGameHouse.Save(SaveStream);
  SaveStream.WriteW(fLastSaveName);
  SaveStream.Write(fSelection, SizeOf(fSelection));
  fMessageStack.Save(SaveStream);
  // Everything else (e.g. ShownUnit or AskDemolish) can't be seen in Save_menu anyways
end;


// Save just the minimap for preview (near the start of the file)
procedure TKMGamePlayInterface.SaveMinimap(SaveStream: TKMemoryStream);
begin
  fMinimap.SaveToStream(SaveStream);
end;


procedure TKMGamePlayInterface.Load(LoadStream: TKMemoryStream);
begin
  fViewport.Load(LoadStream);

  fGuiGameHouse.Load(LoadStream);
  LoadStream.ReadW(fLastSaveName);
  LoadStream.Read(fSelection, SizeOf(fSelection));
  fMessageStack.Load(LoadStream);

  // Everything else (e.g. ShownUnit or AskDemolish) can't be seen in Save_menu anyways
  Message_UpdateStack;
  gLog.AddTime('Interface loaded');
end;


// Load the minimap (saved near start of the file)
procedure TKMGamePlayInterface.LoadMinimap(LoadStream: TKMemoryStream);
begin
  fMinimap.LoadFromStream(LoadStream);
end;


procedure TKMGamePlayInterface.SyncUI(aMoveViewport: Boolean = True);
begin
  inherited;

  fMinimap.Alerts := fAlerts;

  MinimapView.SetMinimap(fMinimap);
  MinimapView.SetViewport(fViewport);

  UpdateUI;
end;


procedure TKMGamePlayInterface.UpdateSelectedObject;

  procedure HideUnitHousePage;
  begin
    if fGuiGameHouse.Visible then
      fGuiGameHouse.Hide;
    if fGuiGameUnit.Visible then
      fGuiGameUnit.Hide;
  end;
  
var
  updateNewSelected: Boolean;
begin
  if gMySpectator.Selected = nil then
  begin
    HideUnitHousePage;
    Exit;
  end; 
  
  updateNewSelected := False;
  
  // Update unit/house information
  if gMySpectator.Selected is TKMUnitGroup then
  begin
    HidePages;
    fGuiGameUnit.ShowGroupInfo(TKMUnitGroup(gMySpectator.Selected), fGuiGameUnit.AskDismiss);
    updateNewSelected := True;
  end else
  if gMySpectator.Selected is TKMUnit then
  begin
    HidePages;
    fGuiGameUnit.ShowUnitInfo(TKMUnit(gMySpectator.Selected), fGuiGameUnit.AskDismiss);
    updateNewSelected := True;
  end else
  begin
    fGuiGameUnit.JoiningGroups := False;
    if gMySpectator.Selected is TKMHouse then
    begin
      HidePages;
      SwitchPage(nil); // Hide main back button if we were in e.g. stats
      fGuiGameHouse.Show(TKMHouse(gMySpectator.Selected));
      updateNewSelected := True;
    end
    else
      HideUnitHousePage;
  end;

  if updateNewSelected then
    gMySpectator.UpdateNewSelected;

  if gMain <> nil then
    gMain.FormMain.SetEntitySelected(gMySpectator.Selected.UID, gMySpectator.Selected.AsGroup.SelectedUnit.UID);
end;


{ Should update any items changed by game (resource counts, hp, etc..) }
{ If it ever gets a bottleneck then some static Controls may be excluded from update }
procedure TKMGamePlayInterface.UpdateState(aTickCount: Cardinal);
var
  I, lastTick: Integer;
  rect: TKMRect;
begin
  inherited;
  // Update minimap every 1000ms
  if aTickCount mod 10 = 0 then
    fMinimap.Update;

  UpdateSelectedObject;

  fAlerts.UpdateState(aTickCount);

  // Update peacetime counter
  if gGame.Options.Peacetime <> 0 then
    Label_PeacetimeRemaining.Caption := Format(gResTexts[TX_MP_PEACETIME_REMAINING],
                                               [TimeToString(gGame.GetPeacetimeRemaining)])
  else
    Label_PeacetimeRemaining.Caption := '';

  // Update replay counters
  if fUIMode = umReplay then
  begin
    lastTick := Max4(gGame.LastReplayTick,
                     gGame.GameInputProcess.GetLastTick,
                     gGameParams.Tick,
                     gGame.SavePoints.LastTick);
    // Replays can continue after end, keep the bar in 0..1 range
    ReplayBar_Replay.SetParameters(gGameParams.Tick,
                                   gGame.Options.Peacetime*60*10,
                                   lastTick);

    Label_ReplayBar.Caption := TimeToString(gGame.MissionTime) + ' / ' +
                            TickToTimeStr(lastTick);
  end;

  // Update speedup clocks
  if Image_Clock.Visible then
    Image_Clock.TexID := ((Image_Clock.TexID - 556) + 1) mod 16 + 556;

  if Label_Clock.Visible then
    Label_Clock.Caption := TimeToString(gGame.MissionTime);

  // Keep on updating these menu pages as game data keeps on changing
  if fGuiGameBuild.Visible then
    fGuiGameBuild.UpdateState;
  if fGuiGameRatios.Visible and (fUIMode in [umReplay, umSpectate]) then
    fGuiGameRatios.UpdateState;
  if fGuiGameStats.Visible then
    fGuiGameStats.UpdateState;
  if Panel_Menu.Visible then
    Menu_Update;

  // Update message stack
  // Flash unread message display
  Label_ChatUnread.Visible := (fUIMode in [umMP, umSpectate]) and (Label_ChatUnread.Caption <> '') and not (aTickCount mod 10 < 5);
  Image_Chat.Highlight := fGuiGameChat.Visible or (Label_ChatUnread.Visible and (Label_ChatUnread.Caption <> ''));
  Image_MPAllies.Highlight := Panel_Allies.Visible;
  if (fUIMode in [umSP, umMP]) and not Image_MessageLog.Visible and (gMySpectator.Hand.MessageLog.CountLog > 0) then
  begin
    Image_MessageLog.Show;
    MessageStack_UpdatePositions;
  end;
  Image_MessageLog.Highlight := not Panel_MessageLog.Visible and not (aTickCount mod 10 < 5)
                                and (fLastSyncedMessage <> gMySpectator.Hand.MessageLog.CountLog);

  if Panel_MessageLog.Visible then
    MessageLog_Update(False);

  // Update info on awaited players
  if Panel_NetWait.Visible then
  begin
    if gNetworking.IsReconnecting then
      Label_NetDropPlayersDelay.Caption := ''
    else
    begin
      i := NET_DROP_PLAYER_MIN_WAIT - EnsureRange(TimeSince(fNetWaitDropPlayersDelayStarted) div 1000, 0, NET_DROP_PLAYER_MIN_WAIT);
      if i > 0 then
        Label_NetDropPlayersDelay.Caption := Format(gResTexts[TX_GAMEPLAY_DROP_PLAYERS_DELAY], [i])
      else
        Label_NetDropPlayersDelay.Caption := gResTexts[TX_GAMEPLAY_DROP_PLAYERS_ALLOWED];
      Button_NetDropPlayers.Enabled := i = 0;
    end;
  end;

  // Display team names
  if aTickCount mod 3 = 0 then // Update once every 300ms, player won't notice
  begin
    fUnitsTeamNames.Clear;
    if SHOW_UIDs then
    begin
      fGroupsTeamNames.Clear;
      fHousesTeamNames.Clear;
    end;
    if fShowTeamNames then
    begin
      rect := fViewport.GetMinimapClip;
      gHands.GetUnitsInRect(rect, fUnitsTeamNames);
      if SHOW_UIDs then
      begin
        gHands.GetGroupsInRect(rect, fGroupsTeamNames);
        gHands.GetHousesInRect(rect, fHousesTeamNames);
      end;
    end;
  end;

  fGuiMenuSettings.UpdateView;
  GameSettingsChanged;

  UpdateDebugInfo;
  if fSaves <> nil then fSaves.UpdateState;

  if aTickCount mod RESULTS_UPDATE_RATE = 0 then
  begin
    fGuiGameResultsSP.UpdateState(aTickCount);
    fGuiGameResultsMP.UpdateState(aTickCount);
  end;

  if fGuiGameSpectator <> nil then
    fGuiGameSpectator.UpdateState(aTickCount);
end;


procedure TKMGamePlayInterface.UpdateStateIdle(aFrameTime: Cardinal);
begin
  // Check to see if we need to scroll
  fViewport.UpdateStateIdle(aFrameTime, not fDragScrolling, gMySpectator.Hand.InCinematic);
end;


function TKMGamePlayInterface.IsDragScrollingAllowed: Boolean;
begin
  inherited;

  Result := not (gGame.IsPaused and (fUIMode in [umSP, umMP]))
            and (fMyControls.CtrlOver = nil)
            and not gMySpectator.Hand.InCinematic;
end;


procedure TKMGamePlayInterface.UpdateDebugInfo;
var
  mKind: TKMessageKind;
  received, sent, receivedTotal, sentTotal, period: Cardinal;
  S, sPackets, S2: String;
  textSize: TKMPoint;
  objToShowInfo: TObject;
begin
  S := '';

  // Debug info
  if SHOW_GAME_TICK then
    S := S + 'Tick: ' + IntToStr(gGameParams.Tick) + '|';

  if SHOW_SPRITE_COUNT then
    S := IntToStr(gHands.UnitCount) + ' units on map|' +
         IntToStr(gRenderPool.RenderList.Stat_Sprites) + '/' +
         IntToStr(gRenderPool.RenderList.Stat_Sprites2) + ' sprites/rendered|' +
         IntToStr(CtrlPaintCount) + ' controls rendered|';

  if SHOW_POINTER_COUNT then
    S := S + Format('Pointers: %d units, %d houses|', [gMySpectator.Hand.Units.GetTotalPointers, gMySpectator.Hand.Houses.GetTotalPointers]);

  if SHOW_CMDQUEUE_COUNT then
    S := S + IntToStr(gGame.GameInputProcess.Count) + ' commands stored|';

  if SHOW_NETWORK_DELAY and (fUIMode in [umMP, umSpectate]) then
    S := S + 'Network delay: ' + IntToStr(TKMGameInputProcess_Multi(gGame.GameInputProcess).GetNetworkDelay) + '|';

  if DISPLAY_SOUNDS then
  begin
    S := S + IntToStr(gSoundPlayer.ActiveCount) + ' sounds playing' + gScriptSounds.ToString + '|';
  end;

  if SHOW_FPS then
    S := S + gMain.FPSString;

  if OVERLAY_AI_SUPERVISOR then
    S := S + gAIFields.Supervisor.LogStatus;

  if SHOW_AI_WARE_BALANCE then
  begin
    if (gMySpectator.Selected <> nil) and not gMySpectator.IsSelectedMyObj then
    begin
      if gHands[gMySpectator.Selected.Owner].AI.Setup.NewAI then
      begin
        S := S + gHands[gMySpectator.Selected.Owner].AI.ArmyManagement.BalanceText + '|';
        S := S + gHands[gMySpectator.Selected.Owner].AI.CityManagement.BalanceText + '|';
      end
      else
        S := S + gHands[gMySpectator.Selected.Owner].AI.Mayor.BalanceText + '|'
    end
    else
    begin
      if gMySpectator.Hand.AI.Setup.NewAI then
      begin
        S := S + gMySpectator.Hand.AI.ArmyManagement.BalanceText + '|';
        S := S + gMySpectator.Hand.AI.CityManagement.BalanceText + '|';
      end
      else
        S := S + gMySpectator.Hand.AI.Mayor.BalanceText + '|'
    end;
  end;


  if SHOW_NET_PACKETS_STATS then
  begin
    S2 := '';
    sPackets := '';
    receivedTotal := 0;
    sentTotal := 0;
    period := TimeSince(gNetworking.PacketsStatsStartTime);
    for mKind := Low(TKMessageKind) to High(TKMessageKind) do
    begin
      received := gNetworking.PacketsReceived[mKind];
      sent := gNetworking.PacketsSent[mKind];
      receivedTotal := receivedTotal + received;
      sentTotal := sentTotal + sent;
      S2 := S2 + Format('%-25s: R: %s S:%s|', [GetEnumName(TypeInfo(TKMessageKind), Integer(mKind)),
                                               FormatFloat('##0.#', received),
                                               FormatFloat('##0.#', sent)]);
      if (received >= SHOW_NET_PACKETS_LIMIT) or (sent >= SHOW_NET_PACKETS_LIMIT) then
        sPackets := sPackets + Format('%-23s: R: %d S:%d|', [GetEnumName(TypeInfo(TKMessageKind), Integer(mKind)),
                                                                 received, sent]);
      S2 := S2 + sLineBreak;
    end;
    S := S + Format('|Average Received: %.1f  Sent: %.1f|', [1000*receivedTotal/period, 1000*sentTotal/period]) + sPackets;
    if (TimeGet mod 5000) < 50 then
      gLog.AddTime('Packets Stats:' + sLineBreak + S2);
  end;

  if SHOW_SELECTED_OBJ_INFO then
  begin
    objToShowInfo := nil;

    if (gMySpectator.Selected <> nil){ and not gMySpectator.IsSelectedMyObj} then
      objToShowInfo := gMySpectator.Selected
    else if (gMySpectator.LastSelected <> nil) then
      objToShowInfo := gMySpectator.LastSelected;

    if objToShowInfo <> nil then
    begin
      if objToShowInfo is TKMUnit then
        S := S + TKMUnit(objToShowInfo).ObjToString
      else if (objToShowInfo is TKMUnitGroup)
        and not TKMUnitGroup(objToShowInfo).IsDead
        and (TKMUnitGroup(objToShowInfo).SelectedUnit <> nil) then
        S := S + TKMUnitGroup(objToShowInfo).SelectedUnit.ObjToString
      else if objToShowInfo is TKMHouse then
        S := S + TKMHouse(objToShowInfo).ObjToString;
    end;
  end;

  if SHOW_HANDS_INFO then
    S := S + gHands.ObjToString;

  Label_DebugInfo.Caption := S;
  Label_DebugInfo.Visible := (Trim(S) <> '');
  Label_DebugInfo.Monospaced := DEBUG_TEXT_MONOSPACED;

  Assert(InRange(DEBUG_TEXT_FONT_ID, Byte(Low(TKMFont)), Byte(High(TKMFont))));
  Label_DebugInfo.Font := TKMFont(DEBUG_TEXT_FONT_ID);

  if Label_DebugInfo.Monospaced then
    textSize := gRes.Fonts[Label_DebugInfo.Font].GetMonospacedTextSize(S)
  else
    textSize := gRes.Fonts[Label_DebugInfo.Font].GetTextSize(S);

  Bevel_DebugInfo.Width := IfThen(textSize.X <= 1, 0, textSize.X + 20);
  Bevel_DebugInfo.Height := IfThen(textSize.Y <= 1, 0, textSize.Y + 20);

  Bevel_DebugInfo.Visible := SHOW_DEBUG_OVERLAY_BEVEL and (Trim(S) <> '') ;
end;


procedure TKMGamePlayInterface.Paint;
var
  I, K: Integer;
  U: TKMUnit;
  G: TKMUnitGroup;
  H: TKMHouse;
  loc: TKMPointF;
  mapLoc: TKMPointF;
  screenLoc: TKMPoint;
begin
  if fShowTeamNames then
  begin
    Label_TeamName.Visible := True; // Only visible while we're using it, otherwise it shows up in other places
    for I := 0 to fUnitsTeamNames.Count - 1 do
      try
        if not (TObject(fUnitsTeamNames[I]) is TKMUnit)
          or (TKMUnit(fUnitsTeamNames[I]) = nil)
          or TKMUnit(fUnitsTeamNames[I]).IsDeadOrDying then
          Continue;

        U := TKMUnit(fUnitsTeamNames[I]);
        if U.IsDeadOrDying then
          Continue;

        if SHOW_UIDs
          or (U.Visible and (gMySpectator.FogOfWar.CheckRevelation(U.PositionF) > FOG_OF_WAR_MIN)) then
        begin
          if SHOW_UIDs then
            Label_TeamName.Caption := IntToStr(U.UID)
          else
            Label_TeamName.Caption := gHands[U.Owner].OwnerName;

          Label_TeamName.FontColor := FlagColorToTextColor(gHands[U.Owner].FlagColor);

          loc := U.PositionF;
          loc.X := loc.X - 0.5;
          loc.Y := loc.Y - 1;
          mapLoc := gTerrain.FlatToHeight(loc);
          screenLoc := fViewport.MapToScreen(mapLoc);

          if KMInRect(screenLoc, KMRect(0, 0, Panel_Main.Width, Panel_Main.Height)) then
          begin
            Label_TeamName.Left := screenLoc.X;
            Label_TeamName.Top := screenLoc.Y;
            Label_TeamName.Paint;
          end;
        end;
      except
        on E: Exception do
          ; //Just ignore exceptions here, since its UI function
      end;

    if SHOW_UIDs then
    begin
      for I := 0 to fGroupsTeamNames.Count - 1 do
        try
          if not (TObject(fGroupsTeamNames[I]) is TKMUnitGroup) then
            Continue;

          G := TKMUnitGroup(fGroupsTeamNames[I]);
          if (G = nil) or G.IsDead then
            Continue;

          Label_TeamName.Caption := 'G ' + IntToStr(G.UID);

          Label_TeamName.FontColor := FlagColorToTextColor(GetRandomColorWSeed(G.UID));

          for K := 0 to G.Count - 1 do
          begin
            U := G.Members[K];
            if U.IsDeadOrDying then
              Continue;

            loc := U.PositionF;
            loc.X := loc.X - 0.5;
            loc.Y := loc.Y - 1.5;
            mapLoc := gTerrain.FlatToHeight(loc);
            screenLoc := fViewport.MapToScreen(mapLoc);

            if KMInRect(screenLoc, KMRect(0, 0, Panel_Main.Width, Panel_Main.Height)) then
            begin
              Label_TeamName.Left := screenLoc.X;
              Label_TeamName.Top := screenLoc.Y;
              Label_TeamName.Paint;
            end;
          end;
        except
          on E: Exception do
            ; //Just ignore exceptions here, since its UI function
        end;

      for I := 0 to fHousesTeamNames.Count - 1 do
        try
          if not (TObject(fHousesTeamNames[I]) is TKMHouse) then
            Continue;

          H := TKMHouse(fHousesTeamNames[I]);
          if H.IsDestroyed then
            Continue;

          Label_TeamName.Caption := 'H ' + IntToStr(H.UID);

          Label_TeamName.FontColor := FlagColorToTextColor(gHands[H.Owner].FlagColor);

          loc := KMPointF(H.Entrance);
          loc.X := loc.X - 0.5;
          loc.Y := loc.Y - 2;
          mapLoc := gTerrain.FlatToHeight(loc);
          screenLoc := fViewport.MapToScreen(mapLoc);

          if KMInRect(screenLoc, KMRect(0, 0, Panel_Main.Width, Panel_Main.Height)) then
          begin
            Label_TeamName.Left := screenLoc.X;
            Label_TeamName.Top := screenLoc.Y;
            Label_TeamName.Paint;
          end;
        except
          on E: Exception do
            ; //Just ignore exceptions here, since its UI function
        end;
    end;
  end;
  Label_TeamName.Visible := False; // Only visible while we're using it, otherwise it shows up in other places

  inherited;
end;


function TKMGamePlayInterface.StatsOpened: Boolean;
begin
  Result := fGuiGameResultsSP.Visible or fGuiGameResultsMP.Visible;
end;


procedure TKMGamePlayInterface.StopGame(const aText: UnicodeString = '');
begin
  gGameApp.StopGame(gGame.GameResult, aText);
end;


procedure TKMGamePlayInterface.ShowMPStats;
begin
  fGuiGameResultsSP.Hide;
  fGuiGameResultsMP.Show(fGuiGameResultsSP.GameResultMsg);
end;


procedure TKMGamePlayInterface.ShowSPStats;
begin
  fGuiGameResultsMP.Hide;
  fGuiGameResultsSP.Show(fGuiGameResultsMP.GameResultMsg);
end;


procedure TKMGamePlayInterface.SetViewportPos(const aLoc: TKMPointF);
begin
  fViewport.Position := aLoc;
end;


end.

