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
    procedure House_Demolish;
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
    procedure Message_Click(Sender: TObject);
    procedure Message_Close(Sender: TObject);
    procedure Message_Delete(Sender: TObject);
    procedure Message_Show(aIndex: Integer);
    procedure Message_GoTo(Sender: TObject);
    procedure Message_UpdateStack;
    procedure MessageLog_Click(Sender: TObject);
    procedure MessageLog_ShowMessage(aMessageId: Integer);
    procedure MessageLog_ItemClick(Sender: TObject);
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
    Label_ClockSpeedup: TKMLabel;

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
      Button_Menu_TrackUp, Button_Menu_TrackDown, Button_ShowStats: TKMButton;
      Label_Menu_Track, Label_GameTime, Label_MapName: TKMLabel;

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
  public
    constructor Create(aRender: TRender; aUIMode: TUIMode); reintroduce;
    destructor Destroy; override;
    procedure MessageIssue(aKind: TKMMessageKind; const aText: UnicodeString); overload;
    procedure MessageIssue(aKind: TKMMessageKind; const aText: UnicodeString; const aLoc: TKMPoint); overload;
    procedure SetMenuState(aTactic: Boolean);
    procedure ShowClock(aSpeed: Single);
    procedure ShowPlayMore(DoShow: Boolean; Msg: TKMGameResultMsg);
    procedure ShowMPPlayMore(Msg: TKMGameResultMsg);
    procedure ShowNetworkLag(aShow: Boolean; aPlayers: TKMByteArray; IsHost: Boolean);
    procedure SetScriptedOverlay(const aText: UnicodeString);
    procedure UpdateOverlayControls;
    procedure ReleaseDirectionSelector;
    procedure ChatMessage(const aData: UnicodeString);
    procedure AlliesOnPlayerSetup(Sender: TObject);
    procedure AlliesOnPingInfo(Sender: TObject);
    procedure AlliesTeamChange(Sender: TObject);
    procedure CinematicUpdate;
    procedure LoadHotkeysFromHand;
    procedure SetButtons(aPaused: Boolean);
    procedure ReplaySaved;

    property UIMode: TUIMode read fUIMode;

    procedure SetPause(aValue: Boolean);
    procedure GameStarted;

    property GuiGameResultsMP: TKMGameResultsMP read fGuiGameResultsMP;
    property GuiGameSpectator: TKMGUIGameSpectator read fGuiGameSpectator;

    property Alerts: TKMAlerts read fAlerts;

    procedure ExportPages(const aPath: string); override;

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
  KM_Utils, KM_ScriptingEvents,
  KM_CommonUtils, KM_ResLocales, KM_ResSound, KM_Resource, KM_Log, KM_ResCursors, KM_ResFonts, KM_ResKeys,
  KM_ResSprites, KM_ResUnits, KM_ResWares, KM_FogOfWar, KM_Sound, KM_NetPlayersList, KM_MessageLog, KM_NetworkTypes,
  KM_InterfaceMapEditor, KM_HouseWoodcutters,
  KM_GameTypes;

const
  ALLIES_ROWS = 7;
  PANEL_ALLIES_WIDTH = 840;


procedure TKMGamePlayInterface.Menu_Save_ListChange(Sender: TObject);
begin
  fSaves.Lock;
  try
    if InRange(TKMListBox(Sender).ItemIndex, 0, fSaves.Count-1) then
    begin
      fSave_Selected := TKMListBox(Sender).ItemIndex;
      Edit_Save.Text := fSaves[ListBox_Save.ItemIndex].FileName;
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
    CheckBox_SaveExists.Enabled := FileExists(gGame.SaveName(Edit_Save.Text, EXT_SAVE_MAIN, (fUIMode in [umMP, umSpectate])));
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
var I, PrevTop: Integer;
begin
  PrevTop := ListBox_Save.TopIndex;
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
  ListBox_Save.TopIndex := PrevTop;
end;


procedure TKMGamePlayInterface.Menu_Save_Click(Sender: TObject);
var
  SaveName: string;
begin
  SaveName := Trim(Edit_Save.Text);
  // Edit.OnChange event happens on key up, so it's still possible for the user to click save button
  // with an invalid file name entered, if the click while still holding down a key.
  // In general it's bad to rely on events like that to ensure validity, doing check here is a good idea
  if SaveName = '' then Exit;

  fLastSaveName := SaveName; // Do this before saving so it is included in the save
  gGame.Save(SaveName, UTCNow);

  fSaves.TerminateScan; // stop scan as it is no longer needed
  SwitchPage(nil); // Close save menu after saving
end;


procedure TKMGamePlayInterface.Menu_Load_ListClick(Sender: TObject);
begin
  fSaves.Lock;
  try
    Button_Load.Enabled := InRange(ListBox_Load.ItemIndex, 0, fSaves.Count - 1)
                           and fSaves[ListBox_Load.ItemIndex].IsValid;
    if InRange(ListBox_Load.ItemIndex,0,fSaves.Count-1) then
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
var I, PrevTop: Integer;
begin
  PrevTop := ListBox_Load.TopIndex;
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

  ListBox_Load.TopIndex := PrevTop;
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
    gGameApp.GameSettings.SaveSettings;

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
      fSaves.Refresh(Menu_Save_RefreshList, (fUIMode in [umMP, umSpectate]));
      Panel_Save.Show;
      Label_MenuTitle.Caption := gResTexts[TX_MENU_SAVE_GAME];
      if fLastSaveName = '' then
        Edit_Save.Text := gGame.GameName
      else
        Edit_Save.Text := fLastSaveName;
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
      fGuiMenuSettings.Menu_Settings_Fill;
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
  path: String;
  I, K: Integer;
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
  Loc: TKMPoint;
  Group: TKMUnitGroup;
begin
  Loc := MinimapView.LocalToMapCoords(X, Y);
  if not gTerrain.TileInMapCoords(Loc.X, Loc.Y) then Exit; // Must be inside map

  // Send move order, if applicable
  if (gMySpectator.Selected is TKMUnitGroup) and not fPlacingBeacon
    and (fUIMode in [umSP, umMP]) and not HasLostMPGame then
  begin
    Group := TKMUnitGroup(gMySpectator.Selected);
    if Group.CanTakeOrders and (Group.Owner = gMySpectator.HandID)
      and Group.CanWalkTo(Loc, 0) then
    begin
      gGame.GameInputProcess.CmdArmy(gicArmyWalk, Group, Loc, dirNA);
      gSoundPlayer.PlayWarrior(Group.UnitType, spMove);
    end;
  end;
  if ((gMySpectator.Selected is TKMHouseBarracks) or (gMySpectator.Selected is TKMHouseWoodcutters)) and not fPlacingBeacon
    and (fUIMode in [umSP, umMP]) and not HasLostMPGame then
  begin
    if gTerrain.Route_CanBeMade(TKMHouse(gMySpectator.Selected).PointBelowEntrance, Loc, tpWalk, 0) then
    begin
      if gMySpectator.Selected is TKMHouseBarracks then
        gGame.GameInputProcess.CmdHouse(gicHouseBarracksRally, TKMHouse(gMySpectator.Selected), Loc)
      else
      if gMySpectator.Selected is TKMHouseTownHall then
        gGame.GameInputProcess.CmdHouse(gicHouseTownHallRally, TKMHouse(gMySpectator.Selected), Loc)
      else
        if gMySpectator.Selected is TKMHouseWoodcutters then
          gGame.GameInputProcess.CmdHouse(gicHouseWoodcuttersCutting, TKMHouse(gMySpectator.Selected), Loc);
    end
    else
      gSoundPlayer.Play(sfxCantPlace, Loc, False, 4);
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
  Radio_PlayersColorMode.ItemIndex := Byte(gGameApp.GameSettings.PlayersColorMode) - 1;
  //Update minimap
  fMinimap.Update;
end;


procedure TKMGamePlayInterface.Replay_PlayersColorModeClick(Sender: TObject);
begin
  gGameApp.GameSettings.PlayersColorMode := TKMPlayerColorMode(Radio_PlayersColorMode.ItemIndex + 1);
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
  Label_ClockSpeedup := TKMLabel.Create(Panel_Main,265,48,'x1',fntMetal,taCenter);
  Label_ClockSpeedup.Hide;

  Create_ScriptingOverlay; // Scripting Overlay controls

  Image_DirectionCursor := TKMImage.Create(Panel_Main,0,0,35,36,519);
  Image_DirectionCursor.Hide;

  // Debugging displays
  Bevel_DebugInfo := TKMBevel.Create(Panel_Main,224+8-10,133-10,Panel_Main.Width - 224 - 8, 0);
  Bevel_DebugInfo.BackAlpha := 0.5;
  Bevel_DebugInfo.Hitable := False;
  Bevel_DebugInfo.Hide;
  Label_DebugInfo := TKMLabel.Create(Panel_Main,224+8,133,'',fntOutline,taLeft);
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
  TKMImage.Create(Panel_Stats,-448,-216, 960, 600, 17, rxGuiMain).AnchorsCenter;
  TKMImage.Create(Panel_Stats, 512,-216, 960, 600, 18, rxGuiMain).AnchorsCenter;
  TKMImage.Create(Panel_Stats,-448, 384, 960, 600, 19, rxGuiMain).AnchorsCenter;
  TKMImage.Create(Panel_Stats, 512, 384, 960, 600, 20, rxGuiMain).AnchorsCenter;
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

  // Needs to be -10 when the swords are hidden so it fits 1024x576
  Panel_Controls.Top := Sidebar_Top.Height - 10 + (10+Sidebar_Middle.Height) * Byte(showSwords);
  Panel_Controls.Height := Panel_Main.Height - Panel_Controls.Top;

  if fGuiGameStats.Visible then
    fGuiGameStats.Resize;

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

      Label_NetWait  := TKMLabel.Create(Panel_NetWaitMsg,Panel_Main.Width div 2,80,NO_TEXT,fntOutline,taCenter);
      Label_NetDropPlayersDelay := TKMLabel.Create(Panel_NetWaitMsg,Panel_Main.Width div 2,110,NO_TEXT,fntOutline,taCenter);
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
    Image_Message[I].OnClick := Message_Click;
  end;
end;


procedure TKMGamePlayInterface.Create_Replay;
begin
  Panel_ReplayBar := TKMPanel.Create(Panel_Main, 320, 8, 400, 45);
    ReplayBar_Replay := TKMReplayBar.Create(Panel_ReplayBar, 0, 0, 400, 25);
    Label_ReplayBar  := TKMLabel.Create(Panel_ReplayBar, ReplayBar_Replay.Width div 2,
                                                         ReplayBar_Replay.Height div 2 - 7, NO_TEXT, fntGrey, taCenter);

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
    Dropbox_ReplayFOW.DropCount := MAX_LOBBY_PLAYERS;
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
    Button_MessageDelete.OnClick := Message_Delete;
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
  I: Integer;
  H: Integer;
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
    ColumnBox_MessageLog.OnClick := MessageLog_ItemClick;
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
  T: TKMTabButtons;
  I: Integer;
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
  I,K: Integer;
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

  Button_Menu_TrackUp := TKMButton.Create(Panel_Menu, 160, 300, 20, 30, '>', bsGame);
  Button_Menu_TrackDown := TKMButton.Create(Panel_Menu, 0, 300, 20, 30, '<', bsGame);
  Button_Menu_TrackUp.Hint := gResTexts[TX_MUSIC_NEXT_HINT];
  Button_Menu_TrackDown.Hint := gResTexts[TX_MUSIC_PREV_HINT];
  Button_Menu_TrackUp.OnClick := Menu_NextTrack;
  Button_Menu_TrackDown.OnClick := Menu_PreviousTrack;
  TKMLabel.Create(Panel_Menu, 0, 285, TB_WIDTH, 30, gResTexts[TX_MUSIC_PLAYER], fntOutline, taCenter);
  Label_Menu_Track := TKMLabel.Create(Panel_Menu, 23, 306, TB_WIDTH - 46, 30, '', fntGrey, taCenter);
  Label_Menu_Track.Hitable := False; // It can block hits for the track Up/Down buttons as they overlap
  TKMLabel.Create(Panel_Menu, 0, 198, TB_WIDTH, 30, gResTexts[TX_GAMEPLAY_GAME_TIME] + ':', fntOutline, taCenter);
  Label_GameTime := TKMLabel.Create(Panel_Menu, 0, 218, TB_WIDTH, 20, '', fntGrey, taCenter);
  TKMLabel.Create(Panel_Menu, 0, 240, TB_WIDTH, 30, gResTexts[TX_WORD_MAP] + ':', fntOutline, taCenter);
  Label_MapName := TKMLabel.Create(Panel_Menu, -3, 260, TB_WIDTH + 3, 20, '', fntGrey, taCenter);
end;


{ Save page }
procedure TKMGamePlayInterface.Create_Save;
begin
  Panel_Save := TKMPanel.Create(Panel_Controls, TB_PAD, 44, TB_WIDTH, 332);

    // Edit field created first to pick a focus on panel show
    Edit_Save := TKMEdit.Create(Panel_Save, 0, 235, TB_WIDTH, 20, fntMetal);
    Edit_Save.AllowedChars := acFileName;
    Edit_Save.MaxLen := MAX_SAVENAME_LENGTH;
    Edit_Save.OnChange := Menu_Save_EditChange;

    ListBox_Save := TKMListBox.Create(Panel_Save, 0, 4, TB_WIDTH, 220, fntMetal, bsGame);
    ListBox_Save.AutoHideScrollBar := True;
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
var I: Integer;
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
    SetMenuState(gGame.MissionMode = mmTactic); // Disabled main buttons

    MinimapView.Disable;
    Sidebar_Top.Disable;
    Sidebar_Middle.Disable;
    for I := Low(Sidebar_Bottom) to High(Sidebar_Bottom) do
      Sidebar_Bottom[I].Disable;
  end
  else
  begin
    SetMenuState(gGame.MissionMode = mmTactic); // Enable main buttons

    MinimapView.Enable;
    Sidebar_Top.Enable;
    Sidebar_Middle.Enable;
    for I := Low(Sidebar_Bottom) to High(Sidebar_Bottom) do
      Sidebar_Bottom[I].Enable;
  end;
end;


// Used when loading MP save since hotkeys must be network synced
procedure TKMGamePlayInterface.LoadHotkeysFromHand;
var I: Integer;
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


procedure TKMGamePlayInterface.House_Demolish;
begin
  SwitchPage(Button_Main[tbBuild]);
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
procedure TKMGamePlayInterface.Message_Click(Sender: TObject);
begin
  if TKMImage(Sender).Tag <> fShownMessage then
    Message_Show(TKMImage(Sender).Tag)
  else
    Message_Close(Sender);
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


procedure TKMGamePlayInterface.Message_Delete(Sender: TObject);
var
  OldMsg: Integer;
begin
  if fShownMessage = -1 then Exit; // Player pressed DEL with no Msg opened

  OldMsg := fShownMessage;

  Message_Close(Sender);
  fMessageStack.RemoveStack(OldMsg);

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
  ShowStats, ReinitStatsLastTime: Boolean;
begin
  if aMsg <> grGameContinues then
    gGame.GameResult := aMsg;

  ShowStats := False;
  ReinitStatsLastTime := False;

  case aMsg of
    grWin,
    grDefeat,
    grCancel,
    grReplayEnd:     begin
                        gGameApp.PrepageStopGame(gGame.GameResult);
                        ShowStats := True;
                        ReinitStatsLastTime := True;
                      end;
    grGameContinues: ShowStats := True;
    grError,
    grDisconnect,
    grSilent,
    grMapEdEnd:  StopGame;
  end;

  if ShowStats then
  begin
    if (gGame.GameMode in [gmMulti, gmMultiSpectate, gmReplayMulti]) or MP_RESULTS_IN_SP then
      fGuiGameResultsMP.Show(aMsg)
    else begin
      if ReinitStatsLastTime then
      begin
        fGuiGameResultsMP.Show(aMsg, True); //Show and hide MP results, so they will be synced with SP results page
        fGuiGameResultsMP.Hide;
      end;
      fGuiGameResultsSP.Show(aMsg, ReinitStatsLastTime);
    end;
  end;
end;


// Quit the mission and return to main menu
procedure TKMGamePlayInterface.Menu_QuitMission(Sender: TObject);
begin
  //Defeat player, if he intentionally quit, when game result is not determined yet (grCancel)
  if (gGame.GameMode = gmMulti) and (gGame.GameResult = grCancel) then
    gGame.GameResult := grDefeat
  else if gGame.IsReplay then
    gGame.GameResult := grReplayEnd;
  // Show outcome depending on actual situation.
  // By default PlayOnState is grCancel, if playing on after victory/defeat it changes
  StopPlay(gGame.GameResult);
end;


procedure TKMGamePlayInterface.Menu_ReturnToMapEd(Sender: TObject);
var
  MapPath, GameName: UnicodeString;
  IsMultiplayer: Boolean;
begin
  IsMultiplayer := gGame.StartedFromMapEdAsMPMap;
  MapPath := TKMapsCollection.FullPath(gGame.GameName, '.dat', IsMultiplayer);
  GameName := gGame.GameName;
  FreeThenNil(gGame);
  gGameApp.NewMapEditor(MapPath, 0, 0, TKMapsCollection.GetMapCRC(GameName, IsMultiplayer));
  TKMapEdInterface(gGame.ActiveInterface).SetLoadMode(IsMultiplayer);
end;


procedure TKMGamePlayInterface.Menu_NextTrack(Sender: TObject);
begin
  gGameApp.MusicLib.PlayNextTrack;
end;


procedure TKMGamePlayInterface.Menu_PreviousTrack(Sender: TObject);
begin
  gGameApp.MusicLib.PlayPreviousTrack;
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
    gGame.Networking.ToggleMuted(fLineIdToNetPlayerId[Image.Tag]);
    Update_Image_AlliesMute(Image);
  end;
end;


procedure TKMGamePlayInterface.Update_Image_AlliesMute(aImage: TKMImage);
begin
  if gGame.Networking.IsMuted(fLineIdToNetPlayerId[aImage.Tag]) then
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
  Teams: TKMByteSetArray;
  HandIdToNetPlayersId: array [0..MAX_HANDS - 1] of Integer;
begin
  // First empty everything
  fPlayerLinesCnt := 0;

  for I := 0 to MAX_LOBBY_SLOTS - 1 do
    fLineIdToNetPlayerId[I] := -1;

  for I := 0 to MAX_HANDS - 1 do
    HandIdToNetPlayersId[I] := -1;

  for I := 1 to gGame.Networking.NetPlayers.Count do
    if not gGame.Networking.NetPlayers[I].IsSpectator then
      HandIdToNetPlayersId[gGame.Networking.NetPlayers[I].HandIndex] := I;

  Teams := gHands.Teams;

  K := 0;
  for J := Low(Teams) to High(Teams) do
    for I in Teams[J] do
      if HandIdToNetPlayersId[I] <> -1 then //HandIdToNetPlayersId could -1, if we play in the save, where 1 player left
      begin
        fLineIdToNetPlayerId[K] := HandIdToNetPlayersId[I];
        Inc(K);
      end;

  // Spectators
  for I := 1 to gGame.Networking.NetPlayers.Count do
    if gGame.Networking.NetPlayers[I].IsSpectator then
    begin
      fLineIdToNetPlayerId[K] := I;
      Inc(K);
    end;

  fPlayerLinesCnt := K;
end;


procedure TKMGamePlayInterface.SetButtons(aPaused: Boolean);
begin
  Button_ReplayPause.Enabled := aPaused;
  Button_ReplayStep.Enabled := not aPaused;
  Button_ReplayResume.Enabled := not aPaused;
end;


procedure TKMGamePlayInterface.ReplaySaved;
begin
  if (gGame.SavedReplays <> nil) then
    ReplayBar_Replay.AddMark(gGame.GameTick);
end;


procedure TKMGamePlayInterface.Replay_DropBox_JumpToPlayer(aDropBoxIndex: Integer);
begin
  Dropbox_ReplayFOW.ItemIndex := EnsureRange(0, aDropBoxIndex, Dropbox_ReplayFOW.Count - 1);

  Replay_JumpToPlayer(Dropbox_ReplayFOW.GetTag(aDropBoxIndex));
end;


procedure TKMGamePlayInterface.Replay_JumpToPlayer(aHandIndex: Integer);
var
  LastSelectedObj: TObject;
  OldHandIndex: Integer;
begin
  OldHandIndex := gMySpectator.HandID;
  gMySpectator.HandID := aHandIndex;

  LastSelectedObj := gMySpectator.LastSpecSelectedObj;
  if LastSelectedObj <> nil then
  begin
    // Center screen on last selected object for chosen hand
    if LastSelectedObj is TKMUnit then begin
      fViewport.Position := TKMUnit(LastSelectedObj).PositionF;
    end else if LastSelectedObj is TKMHouse then
      fViewport.Position := KMPointF(TKMHouse(LastSelectedObj).Entrance)
    else if LastSelectedObj is TKMUnitGroup then
      fViewport.Position := TKMUnitGroup(LastSelectedObj).FlagBearer.PositionF
    else
      raise Exception.Create('Could not determine last selected object type');
  end
  else
    if not KMSamePoint(gHands[gMySpectator.HandID].CenterScreen, KMPOINT_ZERO) then
      fViewport.Position := KMPointF(gHands[gMySpectator.HandID].CenterScreen); //By default set viewport position to hand CenterScreen

  gMySpectator.Selected := LastSelectedObj;  // Change selected object to last one for this hand or Reset it to nil

  UpdateSelectedObject;
  Replay_UpdatePlayerInterface(OldHandIndex, gMySpectator.HandID);
end;


procedure TKMGamePlayInterface.Replay_ViewPlayer(aPlayerIndex: Integer);
var
  OldHandIndex: Integer;
begin
  Dropbox_ReplayFOW.ItemIndex := EnsureRange(0, aPlayerIndex, Dropbox_ReplayFOW.Count - 1);

  OldHandIndex := gMySpectator.HandID;
  gMySpectator.HandID := Dropbox_ReplayFOW.GetTag(aPlayerIndex);

  if (gMySpectator.Selected <> nil)
    and (OldHandIndex <> gMySpectator.HandID) then
  begin
    gMySpectator.Selected := nil;   // Reset selection when start viewing another player
    UpdateSelectedObject;
  end;

  Replay_UpdatePlayerInterface(OldHandIndex, gMySpectator.HandID);
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
  if Sender = Button_ReplayRestart then
  begin
    // Restart the replay by loading from stream
    ReplayMarkClick(1);

    Exit; // Restarting the replay will destroy Self, so exit immediately
  end;

  if Sender = Button_ReplayPause then
  begin
    gGame.IsPaused := True;
    SetButtons(False);
  end;

  if Sender = Button_ReplayStep then
  begin
    gGame.StepOneFrame;
    gGame.IsPaused := False;
    SetButtons(False);
  end;

  if Sender = Button_ReplayResume then
  begin
    gGame.IsPaused := False;
    SetButtons(True);
  end;

  if Sender = Button_ReplayExit then
  begin
    gGame.GameHold(True, grReplayEnd);
    SetButtons(True);
  end;

  if Sender = Button_ReplaySaveAt then
  begin
    gGame.SaveReplayToMemory();
    ReplaySaved;
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
  gGame.Networking.VoteReturnToLobby;
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


procedure TKMGamePlayInterface.MessageLog_ShowMessage(aMessageId: Integer);
var
  Msg: TKMLogMessage;
  H: TKMHouse;
  G: TKMUnitGroup;
begin
  Msg := gMySpectator.Hand.MessageLog[aMessageId];
  Msg.IsReadLocal := True;
  gGame.GameInputProcess.CmdGame(gicGameMessageLogRead, aMessageId);

  // Jump to location
  fViewport.Position := KMPointF(Msg.Loc);

  // Try to highlight the house in question
  H := gHands.HousesHitTest(Msg.Loc.X, Msg.Loc.Y);

  // Do not highlight a house if it is not the one that has issued the notification
  // (happens when note is issues and house is destroyed and a new one is build in the same place)
  // NOTE: It will highlight next house built on the 'ruins' which is unoccupied to be precise
  //       even the NEW message has not been issued yet
  if (H <> nil) then
  begin
    if (gRes.IsMsgHouseUnnocupied(Msg.fTextID) and not H.HasOwner
        and (gRes.Houses[H.HouseType].OwnerType <> utNone) and (H.HouseType <> htBarracks))
      or H.ResourceDepletedMsgIssued
      or H.OrderCompletedMsgIssued then
    begin
      gMySpectator.Highlight := H;
      gMySpectator.Selected := H;
      UpdateSelectedObject;
    end;
  end else begin
    G := gHands.GroupsHitTest(Msg.Loc.X, Msg.Loc.Y);
    if (G <> nil) and not G.IsDead then
    begin
      SelectUnitGroup(G);
      UpdateSelectedObject;
    end;
  end;

  MessageLog_Update(True);
end;


procedure TKMGamePlayInterface.MessageLog_ItemClick(Sender: TObject);
var
  ItemId, MessageId: Integer;
begin
  ItemId := ColumnBox_MessageLog.ItemIndex;
  if ItemId = -1 then Exit;

  MessageId := ColumnBox_MessageLog.Rows[ItemId].Tag;
  if MessageId = -1 then Exit;

  MessageLog_ShowMessage(MessageId);
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
  Pad: Integer;
begin
  Pad := Byte(fUIMode in [umMP, umSpectate]) * 2 +
         Byte(Image_MessageLog.Visible);
  for I := 0 to MAX_VISIBLE_MSGS do
    Image_Message[I].Top := Panel_Main.Height - 48 - (I + Pad) * 48;
end;


procedure TKMGamePlayInterface.Menu_Update;
begin
  if gGameApp.GameSettings.MusicOff then
    Label_Menu_Track.Caption := '-'
  else
    Label_Menu_Track.Caption := gGameApp.MusicLib.GetTrackTitle;

  Label_Menu_Track.AutoWrap := Length(Label_Menu_Track.Caption) > MAX_TRACKNAME_LENGTH;
  Label_Menu_Track.Top := IfThen(Label_Menu_Track.AutoWrap, 301, 306);
  Button_Menu_TrackUp.Height := IfThen(Label_Menu_Track.AutoWrap, 38, 30);
  Button_Menu_TrackDown.Height := IfThen(Label_Menu_Track.AutoWrap, 38, 30);

  Label_GameTime.Caption := TimeToString(gGame.MissionTime);
  Label_MapName.Caption := Copy(gGame.GameName, 0, EnsureRange(Length(gGame.GameName), 1, MAX_MAPNAME_LENGTH));

  Label_Menu_Track.Enabled      := not gGameApp.GameSettings.MusicOff;
  Button_Menu_TrackUp.Enabled   := not gGameApp.GameSettings.MusicOff;
  Button_Menu_TrackDown.Enabled := not gGameApp.GameSettings.MusicOff;
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
  if (GetTimeSince(fLastBeaconTime) >= BEACON_COOLDOWN) then
  begin
    fLastBeaconTime := TimeGet;
    // In replays we show the beacon directly without GIP. In spectator we use -1 for hand index
    case fUIMode of
      umReplay:   Alerts.AddBeacon(aLoc, gMySpectator.HandID, gMySpectator.Hand.FlagColor, gGameApp.GlobalTickCount + ALERT_DURATION[atBeacon]);
      umSpectate: gGame.GameInputProcess.CmdGame(gicGameAlertBeacon, aLoc, PLAYER_NONE, gGame.Networking.MyNetPlayer.FlagColor);
      else        gGame.GameInputProcess.CmdGame(gicGameAlertBeacon, aLoc, gMySpectator.HandID, gMySpectator.Hand.FlagColor);
    end;
    Beacon_Cancel;
  end else
    MinimapView.ClickableOnce := True; //Restore ClickableOnce state, because it could be reset by previous click on minimap
end;


procedure TKMGamePlayInterface.Replay_Single_SetPlayersDropbox;
var
  I, DropBoxIndex, HumanIndexInList: Integer;
begin
  HumanIndexInList := -1;
  DropBoxIndex := 0;
  for I := 0 to gHands.Count - 1 do
  begin
    if (HumanIndexInList = -1)        // Set HumanIndexInList only once
      and gHands[I].IsHuman then
      HumanIndexInList := DropBoxIndex;
    if gHands[I].Enabled then
    begin
      Dropbox_ReplayFOW.Add(WrapColor(gHands[I].OwnerName, FlagColorToTextColor(gHands[I].FlagColor)), I);
      Inc(DropBoxIndex);
    end;
  end;
  if HumanIndexInList = -1 then HumanIndexInList := 0; // In case there is no Humans in game
  Dropbox_ReplayFOW.ItemIndex := HumanIndexInList;
end;


procedure TKMGamePlayInterface.ReplayMarkClick(aTick: Integer);
var
  TicksList: TList<Cardinal>;
  Tick: Cardinal;
  OldCenter: TKMPointF;
  OldZoom: Single;
  IsPaused: Boolean;
  GuiSpecPage: Integer;
  IsPlayerDropOpen: Boolean;
  PlayerDropItem, PlayersColorMode: Integer;
  ShowPlayerFOW: Boolean;
  MainMenuTab: TKMTabButtons;
begin
  Assert(aTick >= 0, 'Tick should be >= 0'); //May be even > 0

  //Save Replay GUI locally
  MainMenuTab := fOpenedMenu;
  OldCenter := fViewport.Position;
  OldZoom := fViewport.Zoom;
  IsPaused := gGame.IsPaused;
  GuiSpecPage := fGuiGameSpectator.GetOpenedPage;
  IsPlayerDropOpen := Dropbox_ReplayFOW.IsOpen;
  PlayerDropItem := Dropbox_ReplayFOW.ItemIndex;
  ShowPlayerFOW := Checkbox_ReplayFOW.Checked;
  PlayersColorMode := Radio_PlayersColorMode.ItemIndex;

  if not gGameApp.TryLoadSavedReplay( aTick ) then
    Exit;

  if gGame.SavedReplays = nil then
    Exit;

  //!!!!Carefull!!!!
  //Self TKMGamePlayInterface is now destroyed and we can't access any fields here
  //Use gGame.GamePlayInterface instead

  //Restore Replay GUI
  gGame.GamePlayInterface.OpenMenuPage(MainMenuTab);
  gGame.GamePlayInterface.SyncUIView(OldCenter, OldZoom);

  gGame.GamePlayInterface.GuiGameSpectator.OpenPage(GuiSpecPage);

  if IsPlayerDropOpen then
    gGame.GamePlayInterface.Dropbox_ReplayFOW.OpenList;
  gGame.GamePlayInterface.Dropbox_ReplayFOW.ItemIndex := PlayerDropItem;

  gGame.GamePlayInterface.Checkbox_ReplayFOW.Checked := ShowPlayerFOW;
  ReplayClick(gGame.GamePlayInterface.Checkbox_ReplayFOW); //Apply FOW

  gGame.GamePlayInterface.Radio_PlayersColorMode.ItemIndex := PlayersColorMode;

  if IsPaused then
  begin
    gGame.IsPaused := True;
    SetButtons(False); //Update buttons
    gGame.GamePlayInterface.UpdateState(gGame.GameTick);
  end;

  TicksList := Tlist<Cardinal>.Create;
  try
    gGame.SavedReplays.FillTicks(TicksList);

    for Tick in TicksList do
      ReplayBar_Replay.AddMark(Tick);
  finally
    FreeAndNil(TicksList);
  end;
end;


procedure TKMGamePlayInterface.Replay_Multi_SetPlayersDropbox;
var
  Teams: TKMByteSetArray;
  NonTeamHands: set of Byte;
  I, J, DropBoxIndex, HumanIndexInList: Integer;
  TeamSeparatorAdded: Boolean;
begin
  Teams := gHands.GetTeamsOfAllies;
  NonTeamHands := [0..gHands.Count - 1];

  //Get non team hands
  for I := Low(Teams) to High(Teams) do
    NonTeamHands := NonTeamHands - Teams[I];

  HumanIndexInList := -1;
  DropBoxIndex := 0;

  // first output nonteam hands
  for I in NonTeamHands do
  begin
    if (HumanIndexInList = -1)        // Set HumanIndexInList only once
      and gHands[I].IsHuman then
      HumanIndexInList := DropBoxIndex;
    if gHands[I].Enabled then
    begin
      Dropbox_ReplayFOW.Add(WrapColor(gHands[I].OwnerName, FlagColorToTextColor(gHands[I].FlagColor)), I);
      if DropBoxIndex > 0 then
        Dropbox_ReplayFOW.List.AddSeparator(DropBoxIndex);
      Inc(DropBoxIndex);
    end;
  end;

  for I := Low(Teams) to High(Teams) do
  begin
    TeamSeparatorAdded := False;
    for J in Teams[I] do
    begin
      if (HumanIndexInList = -1)        // Set HumanIndexInList only once
        and gHands[J].IsHuman then
        HumanIndexInList := DropBoxIndex;
      if gHands[J].Enabled then
      begin
        if DropBoxIndex = 0 then
          TeamSeparatorAdded := True; //Do not add separator if there was no NonTeamHands
        if not TeamSeparatorAdded then
        begin
          Dropbox_ReplayFOW.List.AddSeparator(DropBoxIndex); //Add Team separator at the start of the team
          TeamSeparatorAdded := True;
        end;

        Dropbox_ReplayFOW.Add(WrapColor(gHands[J].OwnerName, FlagColorToTextColor(gHands[J].FlagColor)), J);
        Inc(DropBoxIndex);
      end;
    end;
  end;

  if Length(Teams) = 0 then
    Dropbox_ReplayFOW.List.ClearSeparators;

  if HumanIndexInList = -1 then HumanIndexInList := 0; // In case there is no Humans in game
  Dropbox_ReplayFOW.ItemIndex := HumanIndexInList;
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


procedure TKMGamePlayInterface.SetMenuState(aTactic: Boolean);
begin
  UpdateMessageImages;

  Button_Main[tbBuild].Enabled := not aTactic and not HasLostMPGame and not gMySpectator.Hand.InCinematic; //Allow to 'test build' if we are in replay / spectate mode
  Button_Main[tbRatio].Enabled := not aTactic and ((fUIMode in [umReplay, umSpectate]) or (not HasLostMPGame and not gMySpectator.Hand.InCinematic));
  Button_Main[tbStats].Enabled := not aTactic;

  Button_Menu_Load.Enabled := fUIMode = umSP; // No loading during multiplayer games
  Button_Menu_Save.Enabled := fUIMode in [umSP, umMP, umSpectate];

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
    Checkbox_ReplayFOW.Checked := False;
    Dropbox_ReplayFOW.Clear;

    // Set dropbox in different ways
    case gGame.GameMode of
      gmReplaySingle:   Replay_Single_SetPlayersDropbox; // Do not show team, as its meaningless
      // Use team info from ally states:
      // consider team as a group of hands where all members are allied to each other and not allied to any other hands.
      gmReplayMulti,
      gmMultiSpectate:  Replay_Multi_SetPlayersDropbox;
      else              raise Exception.Create(Format('Wrong game mode [%s], while spectating/watching replay',
                                                      [GetEnumName(TypeInfo(TKMGameMode), Integer(gGame.GameMode))]));
    end;
    fGuiGameSpectator := TKMGUIGameSpectator.Create(Panel_Main, Replay_JumpToPlayer, SetViewportPos);
    gMySpectator.HandID := Dropbox_ReplayFOW.GetTag(Dropbox_ReplayFOW.ItemIndex); //Update HandIndex
  end;
end;


procedure TKMGamePlayInterface.ShowClock(aSpeed: Single);
begin
  Image_Clock.Visible := (aSpeed <> 1);
  Label_Clock.Visible := (aSpeed <> 1) or gGameApp.GameSettings.ShowGameTime or SHOW_GAME_TICK;
  Label_ClockSpeedup.Visible := aSpeed <> 1;
  Label_ClockSpeedup.Caption := 'x' + FormatFloat('##0.##', aSpeed);

  if not Image_Clock.Visible and Label_Clock.Visible then
    Label_Clock.Top := 8
  else
    Label_Clock.Top := 80;

  // With slow GPUs it will keep old values till next frame, that can take some seconds
  // Thats why we refresh Clock.Caption here
  if (aSpeed <> 1) then
    Label_Clock.Caption := TimeToString(gGame.MissionTime);
end;


procedure TKMGamePlayInterface.SetPause(aValue: Boolean);
begin
  ReleaseDirectionSelector; // Don't restrict cursor movement to direction selection while paused
  fViewport.ReleaseScrollKeys;
  gGame.IsPaused := aValue;
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
                    SetMenuState(gGame.MissionMode = mmTactic);
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
      grWin:       gGame.GameHold(false, grWin);
      grDefeat:    gGame.GameHold(false, grDefeat);
      grReplayEnd: begin
                      gGame.SkipReplayEndCheck := True;
                      gGame.GameHold(false, grReplayEnd);
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
  txt: UnicodeString;
begin
  if aShow then ReleaseDirectionSelector;
  if not aShow then // Reset the confirm when we hide this screen so it's not on confirm when it reshows
  begin
    Panel_NetWaitConfirm.Hide;
    Panel_NetWaitButtons.Show;
  end;

  if gGame.Networking.IsReconnecting then
  begin
    txt := gResTexts[TX_MULTIPLAYER_ATTEMPT_RECONNECTING];
    Button_NetDropPlayers.Visible := False;
    fNetWaitDropPlayersDelayStarted := 0;
    Label_NetDropPlayersDelay.Caption := '';
  end
  else
  begin
    txt := gResTexts[TX_MULTIPLAYER_WAITING] + ' ';
    for I := Low(aPlayers) to High(aPlayers) do
      txt := txt + gGame.Networking.NetPlayers[aPlayers[I]].NiknameU + IfThen(I <> High(aPlayers), ', ');

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

  Label_NetWait.Caption := txt;
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
var OverlayTop, OverlayLeft: Integer;
begin
  OverlayTop := 12;
  OverlayLeft := 258;

  if Panel_ReplayFOW.Visible then
    OverlayTop := Panel_ReplayFOW.Top + Panel_ReplayFOW.Height - 5;

  if gGame.IsSpeedUpAllowed then
    OverlayTop := Max(OverlayTop, Image_Clock.Top + Image_Clock.Height + 25);

  Label_ScriptedOverlay.Top := OverlayTop + 19;
  Button_ScriptedOverlay.Top := OverlayTop + 1;
  Label_OverlayShow.Top := OverlayTop + 2;
  Label_OverlayHide.Top := OverlayTop;

  Label_ScriptedOverlay.Left := OverlayLeft + 5;
  Button_ScriptedOverlay.Left := OverlayLeft;
  Label_OverlayShow.Left := OverlayLeft + 3;
  Label_OverlayHide.Left := OverlayLeft + 3;

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
var
  OldSelected: TObject;
begin
  if gMySpectator.Hand.InCinematic then
    Exit;

  if not InRange(aId, Low(fSelection), High(fSelection)) then Exit;

  if fSelection[aId] <> -1 then
  begin
    OldSelected := gMySpectator.Selected;
    gMySpectator.Selected := gHands.GetUnitByUID(fSelection[aId]);
    if gMySpectator.Selected <> nil then
    begin
      if TKMUnit(gMySpectator.Selected).IsDeadOrDying then
      begin
        gMySpectator.Selected := nil; // Don't select dead/dying units
        Exit;
      end;
      if (OldSelected <> gMySpectator.Selected) and (fUIMode in [umSP, umMP]) and not HasLostMPGame then
        gSoundPlayer.PlayCitizen(TKMUnit(gMySpectator.Selected).UnitType, spSelect);
      // Selecting a unit twice is the shortcut to center on that unit
      if OldSelected = gMySpectator.Selected then
        fViewport.Position := TKMUnit(gMySpectator.Selected).PositionF;
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
        // Selecting a house twice is the shortcut to center on that house
        if OldSelected = gMySpectator.Selected then
          fViewport.Position := KMPointF(TKMHouse(gMySpectator.Selected).Entrance);
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
        if (OldSelected <> gMySpectator.Selected) and (fUIMode in [umSP, umMP]) and not HasLostMPGame then
          gSoundPlayer.PlayWarrior(TKMUnitGroup(gMySpectator.Selected).SelectedUnit.UnitType, spSelect);
        // Selecting a group twice is the shortcut to center on that group
        if OldSelected = gMySpectator.Selected then
          fViewport.Position := TKMUnitGroup(gMySpectator.Selected).SelectedUnit.PositionF;
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
  NextHouse: TKMHouse;
  NextUnit: TKMUnit;
  NextUnitGroup: TKMUnitGroup;
begin
  if gMySpectator.Hand.InCinematic then
    Exit;

  if gMySpectator.Selected is TKMUnit then
  begin
    NextUnit := gHands.GetNextUnitWSameType(TKMUnit(gMySpectator.Selected));
    if NextUnit <> nil then
    begin
      SelectUnit(NextUnit);
      fViewport.Position := NextUnit.PositionF; //center viewport on that unit
    end;

  end else if gMySpectator.Selected is TKMHouse then
  begin
    NextHouse := gHands.GetNextHouseWSameType(TKMHouse(gMySpectator.Selected));
    if NextHouse <> nil then
    begin
      gMySpectator.Selected := NextHouse;
      fViewport.Position := KMPointF(NextHouse.Entrance); //center viewport on that house
    end;

  end else if gMySpectator.Selected is TKMUnitGroup then
  begin
    NextUnitGroup := gHands.GetNextGroupWSameType(TKMUnitGroup(gMySpectator.Selected));
    if NextUnitGroup <> nil then
    begin
      SelectUnitGroup(NextUnitGroup);
      fViewport.Position := NextUnitGroup.SelectedUnit.PositionF; //center viewport on that unit
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


procedure TKMGamePlayInterface.AlliesOnPlayerSetup(Sender: TObject);
var
  I, K, NetI: Integer;
  LocaleID: Integer;
begin
  Image_AlliesHostStar.Hide;
  // Can't vote if we already have, and spectators don't get to vote unless there's only spectators left
  Button_Menu_ReturnLobby.Enabled := not gGame.Networking.MyNetPlayer.VotedYes
                                     and (gGame.Networking.NetPlayers.HasOnlySpectators
                                          or not gGame.Networking.MyNetPlayer.IsSpectator);

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
    NetI := fLineIdToNetPlayerId[K];

    if NetI = -1 then Continue; //In case we have AI players at hand, without NetI

    // Show players locale flag
    if gGame.Networking.NetPlayers[NetI].IsComputer then
      Image_AlliesFlag[I].TexID := GetAIPlayerIcon(gGame.Networking.NetPlayers[NetI].PlayerNetType)
    else
    begin
      LocaleID := gResLocales.IndexByCode(gGame.Networking.NetPlayers[NetI].LangCode);
      if LocaleID <> -1 then
        Image_AlliesFlag[I].TexID := gResLocales[LocaleID].FlagSpriteID
      else
        Image_AlliesFlag[I].TexID := 0;
    end;
    if gGame.Networking.HostIndex = NetI then
    begin
      Image_AlliesHostStar.Visible := True;
      Image_AlliesHostStar.Left := 190 + (I div ALLIES_ROWS)*380;
      Image_AlliesHostStar.Top := 80 + (I mod ALLIES_ROWS)*20;
    end;

    if gGame.Networking.NetPlayers[NetI].IsHuman then
      Label_AlliesPlayer[I].Caption := gGame.Networking.NetPlayers[NetI].NiknameU
    else
      Label_AlliesPlayer[I].Caption := gHands[gGame.Networking.NetPlayers[NetI].HandIndex].OwnerName;

    if (gGame.Networking.MyIndex <> NetI)                // If not my player
      and gGame.Networking.NetPlayers[NetI].IsHuman then // and is not Computer
    begin
      Update_Image_AlliesMute(Image_AlliesMute[I]);
      Image_AlliesMute[I].DoSetVisible; //Do not use .Show here, because we do not want change Parent.Visible status from here
    end;

    if gGame.Networking.NetPlayers[NetI].IsSpectator then
    begin
      Label_AlliesPlayer[I].FontColor := gGame.Networking.NetPlayers[NetI].FlagColor;
      DropBox_AlliesTeam[I].ItemIndex := 0;
      Label_AlliesTeam[I].Caption := gResTexts[TX_LOBBY_SPECTATOR];
    end
    else
    begin
      Label_AlliesPlayer[I].FontColor := gHands[gGame.Networking.NetPlayers[NetI].HandIndex].FlagColor;
      DropBox_AlliesTeam[I].ItemIndex := gGame.Networking.NetPlayers[NetI].Team;
      if gGame.Networking.NetPlayers[NetI].Team = 0 then
        Label_AlliesTeam[I].Caption := '-'
      else
        Label_AlliesTeam[I].Caption := IntToStr(gGame.Networking.NetPlayers[NetI].Team);

      case gHands[gGame.Networking.NetPlayers[NetI].HandIndex].AI.WonOrLost of
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
    Image_AlliesMute[I].Enabled := not gGame.Networking.NetPlayers[NetI].Dropped;
    if gGame.Networking.NetPlayers[NetI].Dropped then
      Image_AlliesMute[I].Hint := '';
    Image_AlliesFlag[I].Enabled := not gGame.Networking.NetPlayers[NetI].Dropped;
    Label_AlliesPlayer[I].Strikethrough := gGame.Networking.NetPlayers[NetI].Dropped;
    // Do not strike throught '-' symbol, when player has no team
    Label_AlliesTeam[I].Strikethrough := gGame.Networking.NetPlayers[NetI].Dropped
                                         and (gGame.Networking.NetPlayers[NetI].Team <> 0);
    Label_AlliesPing[I].Strikethrough := gGame.Networking.NetPlayers[NetI].Dropped;
    Label_AlliesFPS[I].Strikethrough := gGame.Networking.NetPlayers[NetI].Dropped;
    DropBox_AlliesTeam[I].Enabled := (NetI = gGame.Networking.MyIndex); // Our index
    DropBox_AlliesTeam[I].Hide; // Use label for demos until we fix exploits

    Inc(I);
  end;
end;


procedure TKMGamePlayInterface.AlliesOnPingInfo(Sender: TObject);
var
  I, K, NetI: Integer;
  Ping: Word;
  Fps: Cardinal;
begin
  UpdateNetPlayersMapping;

  I := 0;
  for K := 0 to fPlayerLinesCnt - 1 do
  begin
    NetI := fLineIdToNetPlayerId[K];

    if NetI = -1 then Continue; //In case we have AI players at hand, without NetI

    if (I < gGame.Networking.NetPlayers.Count) and (gGame.Networking.NetPlayers[NetI].IsHuman) then
    begin
      Ping := gGame.Networking.NetPlayers[NetI].GetInstantPing;
      Fps := gGame.Networking.NetPlayers[NetI].FPS;
      Label_AlliesPing[I].Caption := WrapColor(IntToStr(Ping), GetPingColor(Ping));
      Label_AlliesPingFpsSlash[I].Caption := '/';
      Label_AlliesFPS[I].Caption := WrapColor(IntToStr(Fps), GetFPSColor(Fps));
    end else begin
      Label_AlliesPing[I].Caption := '';
      Label_AlliesPingFpsSlash[I].Caption := '';
      Label_AlliesFPS[I].Caption := '';
    end;
    Inc(I);
  end;
end;


procedure TKMGamePlayInterface.AlliesTeamChange(Sender: TObject);
var I: Integer;
begin
  for I := 0 to MAX_LOBBY_SLOTS - 1 do
    if (Sender = DropBox_AlliesTeam[I]) and DropBox_AlliesTeam[I].Enabled then
      gGame.GameInputProcess.CmdGame(gicGameTeamChange, I+1, DropBox_AlliesTeam[I].ItemIndex);
end;


procedure TKMGamePlayInterface.KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);
var
  Rect: TKMRect;
  KeyHandled: Boolean;
begin
  aHandled := True; // assume we handle all keys here

  if gGame.IsPaused and (fUIMode in [umSP, umMP]) then Exit;

  if fMyControls.KeyDown(Key, Shift) then
  begin
    fViewport.ReleaseScrollKeys; // Release the arrow keys when you open a window with an edit to stop them becoming stuck
    Exit;
  end;

  inherited KeyDown(Key, Shift, KeyHandled);
  if KeyHandled then Exit;

    // As we don't have names for teams in SP we only allow showing team names in MP or MP replays
  if (Key = gResKeys[SC_SHOW_TEAMS].Key) then
    if SHOW_UIDs or (fUIMode in [umMP, umSpectate]) or (gGame.GameMode = gmReplayMulti) then //Only MP replays
    begin
      fShowTeamNames := True;
      // Update it immediately so there's no 300ms lag after pressing the key
      fUnitsTeamNames.Clear;
      Rect := fViewport.GetMinimapClip;
      gHands.GetUnitsInRect(Rect, fUnitsTeamNames);
      if SHOW_UIDs then
      begin
        fGroupsTeamNames.Clear;
        fHousesTeamNames.Clear;
        gHands.GetGroupsInRect(Rect, fGroupsTeamNames);
        gHands.GetHousesInRect(Rect, fHousesTeamNames);
      end;

    end;

  CheckMessageKeys(Key);
end;


procedure TKMGamePlayInterface.GameStarted;
begin
  if gGame.IsMultiPlayerOrSpec and (gGameApp.Chat.Text <> '') then
    fGuiGameChat.Show;
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
  LastAlert: TKMAlert;
  Msg: TKMLogMessage;
begin
  // Messages
  if Key = gResKeys[SC_CENTER_ALERT].Key then
  begin
    // Spacebar centers you on the latest alert
    LastAlert := fAlerts.GetLatestAlert;
    if LastAlert <> nil then
      fViewport.Position := LastAlert.Loc
    else
    begin
      //If there are no active alerts, then centers on last unread message in log (house / unit)
      for I := gMySpectator.Hand.MessageLog.CountLog - 1 downto Max(gMySpectator.Hand.MessageLog.CountLog - MAX_LOG_MSGS, 0) do
      begin
        Msg := gMySpectator.Hand.MessageLog[I];
        
        if not Msg.IsRead and Msg.IsGoto then
        begin
          MessageLog_ShowMessage(I);
          Break;
        end;
      end;
    end;
  end;

  if Key = gResKeys[SC_DELETE_MSG].Key then
    Button_MessageDelete.Click;

  // Enter is the shortcut to bring up chat in multiplayer
  if (Key = gResKeys[SC_CHAT].Key) and CanShowChat then
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
              or gGame.IsMPGameSpeedChangeAllowed
              or MULTIPLAYER_SPEEDUP;
  end;

var
  SelectId: Integer;
  SpecPlayerIndex: ShortInt;
  KeyHandled: Boolean;
begin
  aHandled := True; // assume we handle all keys here

  if gGame.IsPaused
    and (SpeedChangeAllowed([umSP])
      or ((PAUSE_GAME_AT_TICK <> -1) and (fUIMode <> umReplay))) then
  begin
    if Key = gResKeys[SC_PAUSE].Key then
      SetPause(False);
    Exit;
  end;

  if fMyControls.KeyUp(Key, Shift) then Exit;

  inherited KeyUp(Key, Shift, KeyHandled);
  if KeyHandled then Exit;

  if (fUIMode = umReplay) and (Key = gResKeys[SC_PAUSE].Key) then
  begin
    if Button_ReplayPause.Enabled or not gGame.IsPaused then
      ReplayClick(Button_ReplayPause)
    else if Button_ReplayResume.Enabled or gGame.IsPaused then
      ReplayClick(Button_ReplayResume);
  end;

  // First check if this key was associated with some Spectate/Replay key
  if (fUIMode in [umReplay, umSpectate]) then
  begin
    if Key = gResKeys[SC_SPECTATE_PLAYER_1].Key then
      SpecPlayerIndex := 1
    else if Key = gResKeys[SC_SPECTATE_PLAYER_2].Key then
      SpecPlayerIndex := 2
    else if Key = gResKeys[SC_SPECTATE_PLAYER_3].Key then
      SpecPlayerIndex := 3
    else if Key = gResKeys[SC_SPECTATE_PLAYER_4].Key then
      SpecPlayerIndex := 4
    else if Key = gResKeys[SC_SPECTATE_PLAYER_5].Key then
      SpecPlayerIndex := 5
    else if Key = gResKeys[SC_SPECTATE_PLAYER_6].Key then
      SpecPlayerIndex := 6
    else if Key = gResKeys[SC_SPECTATE_PLAYER_7].Key then
      SpecPlayerIndex := 7
    else if Key = gResKeys[SC_SPECTATE_PLAYER_8].Key then
      SpecPlayerIndex := 8
    else if Key = gResKeys[SC_SPECTATE_PLAYER_9].Key then
      SpecPlayerIndex := 9
    else if Key = gResKeys[SC_SPECTATE_PLAYER_10].Key then
      SpecPlayerIndex := 10
    else if Key = gResKeys[SC_SPECTATE_PLAYER_11].Key then
      SpecPlayerIndex := 11
    else if Key = gResKeys[SC_SPECTATE_PLAYER_12].Key then
      SpecPlayerIndex := 12
    else
      SpecPlayerIndex := -1;

    if (SpecPlayerIndex <> -1) and (Dropbox_ReplayFOW.Count >= SpecPlayerIndex) then
    begin
      if ssCtrl in Shift then
        Replay_DropBox_JumpToPlayer(SpecPlayerIndex - 1)
      else
        Replay_ViewPlayer(SpecPlayerIndex - 1);
      Exit;
    end;
  end;

  // These keys are allowed during replays
  if Key = gResKeys[SC_SHOW_TEAMS].Key then fShowTeamNames := False;
  if Key = gResKeys[SC_BEACON].Key then
    if not SelectingTroopDirection then
    begin
      fPlacingBeacon := True;
      MinimapView.ClickableOnce := True;
      gRes.Cursors.Cursor := kmcBeacon;
    end;
  if Key = gResKeys[SC_CLOSE_MENU].Key then
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
  if Key = gResKeys[SC_SELECT_1].Key  then SelectId := 0 else
  if Key = gResKeys[SC_SELECT_2].Key  then SelectId := 1 else
  if Key = gResKeys[SC_SELECT_3].Key  then SelectId := 2 else
  if Key = gResKeys[SC_SELECT_4].Key  then SelectId := 3 else
  if Key = gResKeys[SC_SELECT_5].Key  then SelectId := 4 else
  if Key = gResKeys[SC_SELECT_6].Key  then SelectId := 5 else
  if Key = gResKeys[SC_SELECT_7].Key  then SelectId := 6 else
  if Key = gResKeys[SC_SELECT_8].Key  then SelectId := 7 else
  if Key = gResKeys[SC_SELECT_9].Key  then SelectId := 8 else
  if Key = gResKeys[SC_SELECT_10].Key then SelectId := 9 else
  if Key = gResKeys[SC_SELECT_11].Key  then SelectId := 10 else
  if Key = gResKeys[SC_SELECT_12].Key  then SelectId := 11 else
  if Key = gResKeys[SC_SELECT_13].Key  then SelectId := 12 else
  if Key = gResKeys[SC_SELECT_14].Key  then SelectId := 13 else
  if Key = gResKeys[SC_SELECT_15].Key  then SelectId := 14 else
  if Key = gResKeys[SC_SELECT_16].Key  then SelectId := 15 else
  if Key = gResKeys[SC_SELECT_17].Key  then SelectId := 16 else
  if Key = gResKeys[SC_SELECT_18].Key  then SelectId := 17 else
  if Key = gResKeys[SC_SELECT_19].Key  then SelectId := 18 else
  if Key = gResKeys[SC_SELECT_20].Key then SelectId := 19 else
    SelectId := -1;

  if SelectId <> -1 then
    if (ssCtrl in Shift) then
      Selection_Assign(SelectId, gMySpectator.Selected)
    else
    if (ssShift in Shift) and (fUIMode in [umSP, umMP]) then
      Selection_Link(SelectId, gMySpectator.Selected)
    else
      Selection_Select(SelectId);

  // Menu shortcuts
  if Key = gResKeys[SC_MENU_BUILD].Key then
    if Button_Main[tbBuild].Enabled then
      SwitchPage(Button_Main[tbBuild]);

  if Key = gResKeys[SC_MENU_RATIO].Key then
    if Button_Main[tbRatio].Enabled then
      SwitchPage(Button_Main[tbRatio]);

  if Key = gResKeys[SC_MENU_STATS].Key then
    if Button_Main[tbStats].Enabled then
      SwitchPage(Button_Main[tbStats]);

  if Key = gResKeys[SC_MENU_MENU].Key then
    SwitchPage(Button_Main[tbMenu]);

  // Switch between same type buildings/units/groups
  if (Key = gResKeys[SC_NEXT_BLD_UNIT_SAME_TYPE].Key)
    and (gMySpectator.Selected <> nil) then
  begin
    SelectNextGameObjWSameType;
  end;

  if (Key = gResKeys[SC_PLAYER_COLOR_MODE].Key) then
  begin
    if fUIMode in [umReplay, umSpectate] then
      gGameApp.GameSettings.PlayersColorMode := TKMPlayerColorMode((Byte(gGameApp.GameSettings.PlayersColorMode) mod 3) + 1)
    else
    begin
      if gGameApp.GameSettings.PlayersColorMode = pcmColors then
        gGameApp.GameSettings.PlayersColorMode := pcmAllyEnemy
      else
        gGameApp.GameSettings.PlayersColorMode := pcmColors;
    end;
    GameSettingsChanged;
    //Update minimap immidiately
//    fMinimap.Update;
  end;

  if SpeedChangeAllowed([umSP, umReplay]) then
  begin
    // Game speed/pause: available in multiplayer mode if the only player left in the game
    if Key = gResKeys[SC_SPEEDUP_1].Key then gGame.SetGameSpeed(1, True);
    if Key = gResKeys[SC_SPEEDUP_2].Key then gGame.SetGameSpeed(gGameApp.GameSettings.SpeedMedium, True);
    if Key = gResKeys[SC_SPEEDUP_3].Key then gGame.SetGameSpeed(gGameApp.GameSettings.SpeedFast, True);
    if Key = gResKeys[SC_SPEEDUP_4].Key then gGame.SetGameSpeed(gGameApp.GameSettings.SpeedVeryFast, True);
  end;

  fGuiGameUnit.KeyUp(Key, Shift);

  // All the following keys don't work in Replay, because they alter game state
  // which is nonsense
  // thus the easy way to make that is to exit now
  if fUIMode = umReplay then Exit;

  // Field plans hotkeys
  if Button_Main[tbBuild].Enabled then
  begin
    if Key = gResKeys[SC_PLAN_ROAD].Key then
    begin
      if not fGuiGameBuild.Visible then
        SwitchPage(Button_Main[tbBuild]);
      fGuiGameBuild.PlanRoad;
    end;

    if Key = gResKeys[SC_PLAN_FIELD].Key then
    begin
      if not fGuiGameBuild.Visible then
        SwitchPage(Button_Main[tbBuild]);
      fGuiGameBuild.PlanField;
    end;

    if Key = gResKeys[SC_PLAN_WINE].Key then
    begin
      if not fGuiGameBuild.Visible then
        SwitchPage(Button_Main[tbBuild]);
      fGuiGameBuild.PlanWine;
    end;

    if Key = gResKeys[SC_ERASE_PLAN].Key then
    begin
      if not fGuiGameBuild.Visible then
        SwitchPage(Button_Main[tbBuild]);
      fGuiGameBuild.ErasePlan;
      gRes.Cursors.Cursor := kmcDefault; //Reset cursor, as it could be kmcInfo, f.e.
    end;
  end;

  // General function keys
  if (Key = gResKeys[SC_PAUSE].Key)
    and SpeedChangeAllowed([umSP]) then
      SetPause(True); // Display pause overlay

  { Temporary cheat codes }
  if DEBUG_CHEATS and (MULTIPLAYER_CHEATS or (fUIMode = umSP)) then
  begin
    if Key = gResKeys[SC_DEBUG_REVEALMAP].Key then gGame.GameInputProcess.CmdTemp(gicTempRevealMap);
    if Key = gResKeys[SC_DEBUG_VICTORY].Key   then gGame.GameInputProcess.CmdTemp(gicTempVictory);
    if Key = gResKeys[SC_DEBUG_DEFEAT].Key    then gGame.GameInputProcess.CmdTemp(gicTempDefeat);
    if Key = gResKeys[SC_DEBUG_ADDSCOUT].Key  then gGame.GameInputProcess.CmdTemp(gicTempAddScout, gGameCursor.Cell);
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
      gGame.GameInputProcess.CmdBuild(gicBuildAddFieldPlan, P, aFieldType);
      fLastDragPoint := gGameCursor.Cell;
    end else if gMySpectator.Hand.CanRemFakeFieldPlan(P, aFieldType) then
    begin
      gGame.GameInputProcess.CmdBuild(gicBuildAddFieldPlan, P, aFieldType);
      fLastDragPoint := gGameCursor.Cell;
      // Set cursor into "Erase" mode, so dragging it will erase next tiles with the same field type
      gGameCursor.Tag1 := Byte(cfmErase);
    end
  end;
var
  Group: TKMUnitGroup;
  Obj: TObject;
  canWalkTo: Boolean;
  P: TKMPoint;
  {$IFDEF MSWindows}
  WindowRect: TRect;
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
    Group := TKMUnitGroup(gMySpectator.Selected);
    Obj := gMySpectator.HitTestCursor;

    canWalkTo := True;

    // Group can walk to allies units place
    if Obj is TKMUnit then
      canWalkTo := (gMySpectator.Hand.Alliances[TKMUnit(Obj).Owner] = atAlly);

    // Can't walk on to a house
    if Obj is TKMHouse then
      canWalkTo := False;

    if canWalkTo then
    begin
      if Group.CanWalkTo(gGameCursor.Cell, 0) then
      begin
        SelectingTroopDirection := True; // MouseMove will take care of cursor changing
        // Restrict the cursor to inside the main panel so it does not get jammed when used near
        // the edge of the window in windowed mode
        {$IFDEF MSWindows}
        WindowRect := gMain.ClientRect;
        ClipCursor(@WindowRect);
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
        gGame.GameInputProcess.CmdBuild(gicBuildAddFieldPlan, P, aFieldType);
        fLastDragPoint := gGameCursor.Cell;
      end else if (gMySpectator.Hand.CanRemFakeFieldPlan(P, aFieldType)) and (gGameCursor.Tag1 = Byte(cfmErase)) then
      begin
        gGame.GameInputProcess.CmdBuild(gicBuildAddFieldPlan, P, aFieldType);
        fLastDragPoint := gGameCursor.Cell;
      end;
  end;
var
  DeltaX, DeltaY, DeltaDistanceSqr: Integer;
  NewPoint: TPoint;
  Obj: TObject;
  P: TKMPoint;
  Group: TKMUnitGroup;
  Owner: TKMHandID;
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
    DeltaX := SelectingDirPosition.X - X;
    DeltaY := SelectingDirPosition.Y - Y;
    DeltaDistanceSqr := Sqr(DeltaX)+Sqr(DeltaY);
    // Manually force the cursor to remain within a circle (+2 to avoid infinite loop due to rounding)
    if DeltaDistanceSqr > Sqr(DirCursorCircleRadius+2) then
    begin
      DeltaX := Round(DeltaX / Sqrt(DeltaDistanceSqr) * DirCursorCircleRadius);
      DeltaY := Round(DeltaY / Sqrt(DeltaDistanceSqr) * DirCursorCircleRadius);
      NewPoint := gMain.ClientToScreen(SelectingDirPosition);
      NewPoint.X := NewPoint.X - DeltaX;
      NewPoint.Y := NewPoint.Y - DeltaY;
      SetCursorPos(NewPoint.X, NewPoint.Y);
    end;

    // Compare cursor position and decide which direction it is
    SelectedDirection := KMGetCursorDirection(DeltaX, DeltaY);
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
                    if gMySpectator.Hand.BuildList.HousePlanList.HasPlan(P) then
                    begin
                      gGame.GameInputProcess.CmdBuild(gicBuildRemoveHousePlan, P);
                      fLastDragPoint := gGameCursor.Cell;
                    end
                    else
                      if (gMySpectator.Hand.BuildList.FieldworksList.HasFakeField(P) <> ftNone) then
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

  Obj := gMySpectator.HitTestCursor;

  if fGuiGameUnit.JoiningGroups and (gMySpectator.Selected is TKMUnitGroup) then
  begin
    Group := TKMUnitGroup(gMySpectator.Selected);
    if (Obj <> nil)
    and (Obj is TKMUnitWarrior)
    and (TKMUnitWarrior(Obj).Owner = gMySpectator.HandID)
    and not Group.HasMember(TKMUnitWarrior(Obj))
    and (UnitGroups[TKMUnitWarrior(Obj).UnitType] = Group.GroupType) then
      gRes.Cursors.Cursor := kmcJoinYes
    else
      gRes.Cursors.Cursor := kmcJoinNo;
    Exit;
  end;

  if not gMySpectator.Hand.InCinematic then
  begin
    // Only own and ally units/houses can be selected
    Owner := GetGameObjectOwnerIndex(Obj);
    if (Owner <> -1) and
      ((Owner = gMySpectator.HandID)
      or ((ALLOW_SELECT_ALLY_UNITS
          or ((Obj is TKMHouse) and (gHands[Owner].IsHuman or not gGame.IsCampaign))) //Do not allow to select allied AI in campaigns
        and (gMySpectator.Hand.Alliances[Owner] = atAlly))
      or (ALLOW_SELECT_ENEMIES and (gMySpectator.Hand.Alliances[Owner] = atEnemy)) // Enemies can be selected for debug
      or (fUIMode in [umReplay, umSpectate])) then
    begin
      gRes.Cursors.Cursor := kmcInfo;
      Exit;
    end;
  end;

  if (gMySpectator.Selected is TKMUnitGroup)
    and (fUIMode in [umSP, umMP]) and not HasLostMPGame
    and not gMySpectator.Hand.InCinematic
    and (gMySpectator.FogOfWar.CheckTileRevelation(gGameCursor.Cell.X, gGameCursor.Cell.Y) > 0) then
  begin
    if ((Obj is TKMUnit) and (gMySpectator.Hand.Alliances[TKMUnit(Obj).Owner] = atEnemy))
      or ((Obj is TKMHouse) and (gMySpectator.Hand.Alliances[TKMHouse(Obj).Owner] = atEnemy)) then
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
  P: TKMPoint;
  Obj: TObject;
  H: TKMHouse;
  Group, Group2: TKMUnitGroup;
  OldSelected: TObject;
  OldSelectedUnit: TKMUnitWarrior;
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

  if (fMyControls.CtrlOver <> nil)
    and (fMyControls.CtrlOver <> Image_DirectionCursor)
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
          Group := TKMUnitGroup(gMySpectator.Selected);
          Obj := gMySpectator.HitTestCursor;

          if (Obj <> nil)
            and (Obj is TKMUnitWarrior)
            and (TKMUnitWarrior(Obj).Owner = gMySpectator.HandID)
            and not Group.HasMember(TKMUnitWarrior(Obj))
            and (UnitGroups[TKMUnitWarrior(Obj).UnitType] = Group.GroupType) then
          begin
            Group2 := gMySpectator.Hand.UnitGroups.GetGroupByMember(TKMUnitWarrior(Obj));
            // Warrior might not have a group yet if he's still walking out of the barracks
            if Group2 <> nil then
            begin
              gSoundPlayer.PlayWarrior(Group.UnitType, spJoin); // In SP joining is instant, Group does not exist after that
              gGame.GameInputProcess.CmdArmy(gicArmyLink, Group, Group2);
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
        if (gGameCursor.Mode <> cmNone) and gGame.IsReplayOrSpectate then
          Exit;

        // Only allow placing of roads etc. with the left mouse button
        if gMySpectator.FogOfWar.CheckTileRevelation(P.X, P.Y) = 0 then
        begin
          if (gGameCursor.Mode in [cmErase, cmRoad, cmField, cmWine, cmHouses]) and not gGame.IsReplayOrSpectate then
            // Can't place noise when clicking on unexplored areas
            gSoundPlayer.Play(sfxCantPlace, P, False, 4);
        end
        else
          case gGameCursor.Mode of
            cmNone:
              begin
                // Remember previous selection to play sound if it changes
                OldSelected := gMySpectator.Selected;
                OldSelectedUnit := nil;

                if OldSelected is TKMUnitGroup then
                  OldSelectedUnit := TKMUnitGroup(gMySpectator.Selected).SelectedUnit;

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
                    and (OldSelected <> gMySpectator.Selected) then
                    gSoundPlayer.PlayCitizen(TKMUnit(gMySpectator.Selected).UnitType, spSelect);
                end;

                if (gMySpectator.Selected is TKMUnitGroup) then
                begin
                  SwitchPage(nil);
                  Group := TKMUnitGroup(gMySpectator.Selected);
                  fGuiGameUnit.ShowGroupInfo(Group);
                  if (fUIMode in [umSP, umMP]) and not HasLostMPGame
                    and ((OldSelected <> Group) or (OldSelectedUnit <> Group.SelectedUnit)) then
                      gSoundPlayer.PlayWarrior(Group.SelectedUnit.UnitType, spSelect);
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
                if not (ssShift in Shift) then
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
                  gMySpectator.UpdateSelect; //Update select, to set up fIsSelectedMyObj
                  HidePages;
                  SwitchPage(nil); // Hide main back button if we were in e.g. stats
                  fGuiGameHouse.Show(H, True);
                  gSoundPlayer.Play(sfxClick);
                end
                else
                begin
                  // Now remove houses that are not started
                  if gMySpectator.Hand.BuildList.HousePlanList.HasPlan(P) then
                    gGame.GameInputProcess.CmdBuild(gicBuildRemoveHousePlan, P)
                  else
                    if gMySpectator.Hand.BuildList.FieldworksList.HasFakeField(P) <> ftNone then
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
          if gTerrain.Route_CanBeMade(TKMHouse(gMySpectator.Selected).PointBelowEntrance, P, tpWalk, 0) then
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
          Group := TKMUnitGroup(gMySpectator.Selected);

          // Attack or Walk
          if Group.CanTakeOrders and (Group.Owner = gMySpectator.HandID) then
          begin
            // Try to Attack unit
            Obj := gMySpectator.HitTestCursor;
            if (Obj is TKMUnit) and (gMySpectator.Hand.Alliances[TKMUnit(Obj).Owner] = atEnemy) then
            begin
              gGame.GameInputProcess.CmdArmy(gicArmyAttackUnit, Group, TKMUnit(Obj));
              gSoundPlayer.PlayWarrior(Group.UnitType, spAttack);
            end
            else
            // If there's no unit - try to Attack house
            if (Obj is TKMHouse) and (gMySpectator.Hand.Alliances[TKMHouse(Obj).Owner] = atEnemy) then
            begin
              gGame.GameInputProcess.CmdArmy(gicArmyAttackHouse, Group, TKMHouse(Obj));
              gSoundPlayer.PlayWarrior(Group.UnitType, spAttack);
            end
            else
            // Ensure down click was successful (could have been over a mountain, then dragged to a walkable location)
            if SelectingTroopDirection and Group.CanWalkTo(P, 0) then
            begin
              gGame.GameInputProcess.CmdArmy(gicArmyWalk, Group, P, SelectedDirection);
              gSoundPlayer.PlayWarrior(Group.UnitType, spMove);
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

  SetMenuState(gGame.MissionMode = mmTactic);
end;


procedure TKMGamePlayInterface.UpdateSelectedObject;
var
  UpdateNewSelected: Boolean;
begin
  UpdateNewSelected := False;
  // Update unit/house information
  if gMySpectator.Selected is TKMUnitGroup then
  begin
    HidePages;
    fGuiGameUnit.ShowGroupInfo(TKMUnitGroup(gMySpectator.Selected), fGuiGameUnit.AskDismiss);
    UpdateNewSelected := True;
  end else
  if gMySpectator.Selected is TKMUnit then
  begin
    HidePages;
    fGuiGameUnit.ShowUnitInfo(TKMUnit(gMySpectator.Selected), fGuiGameUnit.AskDismiss);
    UpdateNewSelected := True;
  end else
  begin
    fGuiGameUnit.JoiningGroups := False;
    if gMySpectator.Selected is TKMHouse then
    begin
      HidePages;
      SwitchPage(nil); // Hide main back button if we were in e.g. stats
      fGuiGameHouse.Show(TKMHouse(gMySpectator.Selected));
      UpdateNewSelected := True;
    end
    else
      if fGuiGameHouse.Visible then
        fGuiGameHouse.Hide;
      if fGuiGameUnit.Visible then
        fGuiGameUnit.Hide;
  end;

  if UpdateNewSelected then
    gMySpectator.UpdateNewSelected;
end;


{ Should update any items changed by game (resource counts, hp, etc..) }
{ If it ever gets a bottleneck then some static Controls may be excluded from update }
procedure TKMGamePlayInterface.UpdateState(aTickCount: Cardinal);
var
  I, LastTick: Integer;
  Rect: TKMRect;
begin
  inherited;
  // Update minimap every 1000ms
  if aTickCount mod 10 = 0 then
    fMinimap.Update;

  UpdateSelectedObject;

  fAlerts.UpdateState(aTickCount);

  // Update peacetime counter
  if gGame.GameOptions.Peacetime <> 0 then
    Label_PeacetimeRemaining.Caption := Format(gResTexts[TX_MP_PEACETIME_REMAINING],
                                               [TimeToString(gGame.GetPeacetimeRemaining)])
  else
    Label_PeacetimeRemaining.Caption := '';

  // Update replay counters
  if fUIMode = umReplay then
  begin
    LastTick := Max4(gGame.LastReplayTick,
                     gGame.GameInputProcess.GetLastTick,
                     gGame.GameTick,
                     gGame.SavedReplays.LastTick);
    // Replays can continue after end, keep the bar in 0..1 range
    ReplayBar_Replay.SetParameters(gGame.GameTick,
                                   gGame.GameOptions.Peacetime*60*10,
                                   LastTick);

    Label_ReplayBar.Caption := TimeToString(gGame.MissionTime) + ' / ' +
                            TickToTimeStr(LastTick);
  end;

  // Update speedup clocks
  if Image_Clock.Visible then
    Image_Clock.TexID := ((Image_Clock.TexID - 556) + 1) mod 16 + 556;

  if Label_Clock.Visible then
  begin
    Label_Clock.Caption := TimeToString(gGame.MissionTime);
    if SHOW_GAME_TICK then
      Label_Clock.Caption := Label_Clock.Caption + '|' + IntToStr(gGame.GameTick);
  end;

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
    if gGame.Networking.IsReconnecting then
      Label_NetDropPlayersDelay.Caption := ''
    else
    begin
      i := NET_DROP_PLAYER_MIN_WAIT - EnsureRange(GetTimeSince(fNetWaitDropPlayersDelayStarted) div 1000, 0, NET_DROP_PLAYER_MIN_WAIT);
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
      Rect := fViewport.GetMinimapClip;
      gHands.GetUnitsInRect(Rect, fUnitsTeamNames);
      if SHOW_UIDs then
      begin
        gHands.GetGroupsInRect(Rect, fGroupsTeamNames);
        gHands.GetHousesInRect(Rect, fHousesTeamNames);
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
  Received, Sent, RTotal, STotal, Period: Cardinal;
  S, SPackets, S2: String;
  TextSize: TKMPoint;
begin
  S := '';

  // Debug info
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
    S := S + IntToStr(gSoundPlayer.ActiveCount) + ' sounds playing|';

  if SHOW_FPS then
    S := S + gMain.FPSString;

  if SHOW_AI_WARE_BALANCE then
  begin
    if (gMySpectator.Selected <> nil) and not gMySpectator.IsSelectedMyObj then
    begin
      if gHands[GetGameObjectOwnerIndex(gMySpectator.Selected)].AI.Setup.NewAI then
        S := S + gHands[GetGameObjectOwnerIndex(gMySpectator.Selected)].AI.CityManagement.BalanceText + '|'
      else
        S := S + gHands[GetGameObjectOwnerIndex(gMySpectator.Selected)].AI.Mayor.BalanceText + '|'
    end
    else
    begin
      if gMySpectator.Hand.AI.Setup.NewAI then
      begin
        S := S + gMySpectator.Hand.AI.CityManagement.BalanceText + '|';
        S := S + gMySpectator.Hand.AI.ArmyManagement.BalanceText + '|';
      end
      else
        S := S + gMySpectator.Hand.AI.Mayor.BalanceText + '|'
    end;
  end;


  if SHOW_NET_PACKETS_STATS then
  begin
    S2 := '';
    SPackets := '';
    RTotal := 0;
    STotal := 0;
    Period := GetTimeSince(gGame.Networking.PacketsStatsStartTime);
    for mKind := Low(TKMessageKind) to High(TKMessageKind) do
    begin
      Received := gGame.Networking.PacketsReceived[mKind];
      Sent := gGame.Networking.PacketsSent[mKind];
      RTotal := RTotal + Received;
      STotal := STotal + Sent;
      S2 := S2 + Format('%-25s: R: %s S:%s|', [GetEnumName(TypeInfo(TKMessageKind), Integer(mKind)),
                                               FormatFloat('##0.#', Received),
                                               FormatFloat('##0.#', Sent)]);
      if (Received >= SHOW_NET_PACKETS_LIMIT) or (Sent >= SHOW_NET_PACKETS_LIMIT) then
        SPackets := SPackets + Format('%-23s: R: %d S:%d|', [GetEnumName(TypeInfo(TKMessageKind), Integer(mKind)),
                                                                 Received, Sent]);
      S2 := S2 + sLineBreak;
    end;
    S := S + Format('|Average Received: %.1f  Sent: %.1f|', [1000*RTotal/Period, 1000*STotal/Period]) + SPackets;
    if (TimeGet mod 5000) < 50 then
      gLog.AddTime('Packets Stats:' + sLineBreak + S2);
  end;

  if SHOW_SELECTED_OBJ_INFO then
  begin
    if (gMySpectator.Selected <> nil){ and not gMySpectator.IsSelectedMyObj} then
    begin
      if gMySpectator.Selected is TKMUnit then
        S := S + TKMUnit(gMySpectator.Selected).ObjToString
      else if gMySpectator.Selected is TKMUnitGroup then
        S := S + TKMUnitGroup(gMySpectator.Selected).SelectedUnit.ObjToString
      else if gMySpectator.Selected is TKMHouse then
        S := S + TKMHouse(gMySpectator.Selected).ObjToString;
    end;
  end;

  Label_DebugInfo.Font := fntArial;
  Label_DebugInfo.Caption := S;
  Label_DebugInfo.Visible := (Trim(S) <> '');

  TextSize := gRes.Fonts[fntArial].GetTextSize(S);

  Bevel_DebugInfo.Width := IfThen(TextSize.X <= 1, 0, TextSize.X + 20);
  Bevel_DebugInfo.Height := IfThen(TextSize.Y <= 1, 0, TextSize.Y + 20);

  Bevel_DebugInfo.Visible := SHOW_DEBUG_OVERLAY_BEVEL and (Trim(S) <> '') ;
end;


procedure TKMGamePlayInterface.Paint;
var
  I, K: Integer;
  U: TKMUnit;
  G: TKMUnitGroup;
  H: TKMHouse;
  Loc: TKMPointF;
  MapLoc: TKMPointF;
  ScreenLoc: TKMPoint;
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

          Loc := U.PositionF;
          Loc.X := Loc.X - 0.5;
          Loc.Y := Loc.Y - 1;
          MapLoc := gTerrain.FlatToHeight(Loc);
          ScreenLoc := fViewport.MapToScreen(MapLoc);

          if KMInRect(ScreenLoc, KMRect(0, 0, Panel_Main.Width, Panel_Main.Height)) then
          begin
            Label_TeamName.Left := ScreenLoc.X;
            Label_TeamName.Top := ScreenLoc.Y;
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

            Loc := U.PositionF;
            Loc.X := Loc.X - 0.5;
            Loc.Y := Loc.Y - 1.5;
            MapLoc := gTerrain.FlatToHeight(Loc);
            ScreenLoc := fViewport.MapToScreen(MapLoc);

            if KMInRect(ScreenLoc, KMRect(0, 0, Panel_Main.Width, Panel_Main.Height)) then
            begin
              Label_TeamName.Left := ScreenLoc.X;
              Label_TeamName.Top := ScreenLoc.Y;
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

          Loc := KMPointF(H.Entrance);
          Loc.X := Loc.X - 0.5;
          Loc.Y := Loc.Y - 2;
          MapLoc := gTerrain.FlatToHeight(Loc);
          ScreenLoc := fViewport.MapToScreen(MapLoc);

          if KMInRect(ScreenLoc, KMRect(0, 0, Panel_Main.Width, Panel_Main.Height)) then
          begin
            Label_TeamName.Left := ScreenLoc.X;
            Label_TeamName.Top := ScreenLoc.Y;
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

