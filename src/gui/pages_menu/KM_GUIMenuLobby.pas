unit KM_GUIMenuLobby;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLType, {$ENDIF}
  Classes, Controls, Math, SysUtils,
  KM_Defaults, KM_NetworkTypes, KM_Console, KM_ResTexts,
  KM_Controls, KM_Maps, KM_Saves, KM_Pics, KM_InterfaceDefaults, KM_Minimap, KM_Networking;


type
  TKMLobbyTab = (ltDesc, ltOptions);

  TKMMenuLobby = class (TKMMenuPageCommon)
  private
    fOnPageChange: TKMMenuChangeEventText; //will be in ancestor class

    fLastTimeResetBans: Cardinal;
    fLastTimeAskReady: Cardinal;

    fMapsMP: TKMapsCollection;
    fSavesMP: TKMSavesCollection;
    fMinimap: TKMMinimap;
    fNetworking: TKMNetworking;

    fLobbyTab: TKMLobbyTab;

    fLocalToNetPlayers: array [1..MAX_LOBBY_SLOTS] of Integer;
    fNetPlayersToLocal: array [1..MAX_LOBBY_SLOTS] of Integer;

    fDropBoxPlayers_LastItemIndex: Integer;

    fMapsSortUpdateNeeded: Boolean;
    fMainHeight: Integer;

    procedure UpdateMappings;
    procedure UpdateSpectatorDivide;

    procedure CreateControls(aParent: TKMPanel);
    procedure CreateChatMenu(aParent: TKMPanel);
    procedure CreatePlayerMenus(aParent: TKMPanel);
    procedure CreateSettingsPopUp(aParent: TKMPanel);

    procedure Reset(aKind: TKMNetPlayerKind; aPreserveMaps: Boolean = False);
    procedure GameOptionsTabSwitch(Sender: TObject);
    procedure GameOptionsChange(Sender: TObject);
    procedure FileDownloadClick(Sender: TObject);
    procedure ReadmeClick(Sender: TObject);

    procedure ChatMenuSelect(aItemTag: TKMNetHandleIndex);
    procedure ChatMenuClick(Sender: TObject);
    procedure ChatMenuShow(Sender: TObject);

    procedure HostMenuClick(Sender: TObject);
    procedure JoinerMenuClick(Sender: TObject);
    function CanShowPlayerMenu(Sender: TObject): Boolean;
    procedure PlayerMenuShow(Sender: TObject);

    procedure ToggleMutePlayer(aPlayerIndex: Integer);
    procedure UpdateMuteMenuItem(aMenu: TKMPopUpMenu; aItemIndex: Integer; aIsMuted: Boolean);
    procedure UpdateImageLobbyFlag(aIndex: Integer);

    procedure PlayersSetupChange(Sender: TObject);
    procedure MapColumnClick(aValue: Integer);
    procedure MapTypeChanged(Sender: TObject);
    procedure InitDropColMapsList;
    procedure MapList_OnShow(Sender: TObject);
    procedure UpdateMapList;

    procedure MapList_SortUpdate(Sender: TObject);
    procedure MapList_ScanUpdate(Sender: TObject);
    procedure MapList_ScanComplete(Sender: TObject);

    procedure WakeUpNotReadyClick(Sender: TObject);

    procedure RefreshMapList(aJumpToSelected: Boolean);
    procedure RefreshSaveList(aJumpToSelected: Boolean);
    procedure MapChange(Sender: TObject);
    function DropBoxMaps_CellClick(Sender: TObject; const X, Y: Integer): Boolean;
    function DropBoxPlayers_CellClick(Sender: TObject; const X, Y: Integer): Boolean;
    procedure DropBoxPlayers_Show(Sender: TObject);
    procedure PercentBar_PlayerDl_ChVisibility(aPlayerIndex: Integer; aShow: Boolean);

    function DoPost: Boolean;
    function PostKeyDown(Sender: TObject; Key: Word; Shift: TShiftState): Boolean;
    function IsKeyEvent_Return_Handled(Sender: TObject; Key: Word): Boolean;
    procedure PostMsg(const aMsg: UnicodeString);
    procedure PostLocalMsg(const aMsg: UnicodeString);
    procedure HandleError(const aMsg: UnicodeString);

    function AISlotsAvailable(aAIPlayerTypes: TKMNetPlayerTypeSet = [AI_PLAYER_TYPE_MIN..AI_PLAYER_TYPE_MAX]): Byte;
    procedure MinimapLocClick(aValue: Integer);

    function Speed2TrackBarPos(aSpeed: Single): Integer;
    function TrackBarPos2Speed(aTrackPos: Integer): Single;

    procedure UpdateGameOptionsUI;
    procedure UpdateDescNOptionsUI;
    procedure UpdateDifficultyLevels(aSave: TKMSaveInfo); overload;
    procedure UpdateDifficultyLevels(aMap: TKMapInfo); overload;

    procedure Lobby_OnDisconnect(const aData: UnicodeString);
    procedure Lobby_OnGameOptions(Sender: TObject);
    procedure Lobby_OnMapName(const aData: UnicodeString);
    procedure Lobby_OnMapMissing(const aData: UnicodeString; aStartTransfer: Boolean);
    procedure Lobby_OnMessage(const aText: UnicodeString);
    procedure Lobby_OnPingInfo(Sender: TObject);
    procedure Lobby_OnPlayersSetup(Sender: TObject);
    procedure Lobby_OnUpdateMinimap(Sender: TObject);
    procedure Lobby_OnReassignedToHost(Sender: TObject);
    procedure Lobby_OnReassignedToJoiner(Sender: TObject);
    procedure Lobby_OnFileTransferProgress(aTotal, aProgress: Cardinal);
    procedure Lobby_OnPlayerFileTransferProgress(aNetPlayerIndex: Integer; aTotal, aProgress: Cardinal);
    procedure Lobby_OnSetPassword(const aPassword: AnsiString);

    procedure StartBtnChangeEnabled(Sender: TObject; aEnable: Boolean);

    function DetectMapType: Integer;
    procedure SettingsClick(Sender: TObject);
    procedure StartClick(Sender: TObject);
    procedure BackClick(Sender: TObject);
    procedure EscKeyDown(Sender: TObject);
    procedure KeyDown(Key: Word; Shift: TShiftState);

    procedure ChatTextChanged(Sender: TObject);
    procedure SetChatHandlers;
    procedure UpdateChatControls;
  protected
    Panel_Lobby: TKMPanel;
      Panel_Settings: TKMPanel;
        Edit_Description: TKMEdit;
        Edit_Password: TKMEdit;
        Button_SettingsUseLastPassword: TKMButton;
        Checkbox_RememberPassword: TKMCheckbox;
        Button_SettingsResetBans: TKMButton;
        Button_SettingsAskReady: TKMButton;
        Button_SettingsSave: TKMButton;
        Button_SettingsCancel: TKMButton;

      Menu_Chat: TKMPopUpMenu;
      Menu_Host: TKMPopUpMenu;
      Menu_Joiner: TKMPopUpMenu;

      Panel_ServerName: TKMPanel;
        Label_ServerName: TKMLabel;

      Panel_Players: TKMPanel;
        Image_PasswordLock: TKMImage;
        Bevel_Players: TKMBevel;
        CheckBox_HostControl: TKMCheckBox;
        CheckBox_RandomizeTeamLocations: TKMCheckBox;
        CheckBox_Spectators: TKMCheckBox;
        Bevel_SpecsDivide: TKMBevel;
        Image_HostStar: TKMImage;
        Image_Flag: array [1..MAX_LOBBY_SLOTS] of TKMImage;
        DropBox_PlayerSlot: array [1..MAX_LOBBY_SLOTS] of TKMDropColumns;
        Label_Player: array [1..MAX_LOBBY_SLOTS] of TKMLabel;
        PercentBar_DownloadProgress: array [1..MAX_LOBBY_SLOTS] of TKMPercentBar;
        DropBox_Loc: array [1..MAX_LOBBY_SLOTS] of TKMDropList;
        DropBox_Team: array [1..MAX_LOBBY_SLOTS] of TKMDropList;
        DropBox_Colors: array [1..MAX_LOBBY_SLOTS] of TKMDropColumns;
        Image_Ready: array [1..MAX_LOBBY_SLOTS] of TKMImage;
        Label_Ping: array [1..MAX_LOBBY_SLOTS] of TKMLabel;

      Panel_Setup: TKMPanel;
        Radio_MapType: TKMRadioGroup;
        DropCol_Maps: TKMDropColumns;
        Label_MapName: TKMLabel;
        Panel_SetupTransfer: TKMPanel;
          Button_SetupDownload: TKMButton;
          PercentBar_SetupProgress: TKMPercentBar;
        Panel_SetupMinimap: TKMPanel;
          MinimapView: TKMMinimapView;
        Button_TabDesc, Button_TabOptions: TKMButton;
        Panel_SetupDesc: TKMPanel;
          Memo_MapDesc: TKMMemo;
          Button_SetupReadme: TKMButton;
        Panel_SetupOptions: TKMPanel;
          Label_GameOptions: TKMLabel;
          Panel_Difficulty: TKMPanel;
            Label_Difficulty: TKMLabel;
            DropBox_Difficulty: TKMDropList;
          Panel_GameOptions: TKMPanel;
            TrackBar_LobbyPeacetime: TKMTrackBar;
            TrackBar_SpeedPT, TrackBar_SpeedAfterPT: TKMTrackBar;

      Memo_Posts: TKMMemo;
      Button_Post: TKMButtonFlat;
      Edit_Post: TKMEdit;

      Button_Back: TKMButton;
      Button_ChangeSettings: TKMButton;
      Button_Start: TKMButton;
  public
    constructor Create(aParent: TKMPanel; aOnPageChange: TKMMenuChangeEventText);
    destructor Destroy; override;

    procedure Show(aKind: TKMNetPlayerKind; aNetworking: TKMNetworking; aMainHeight: Word);
    procedure Lobby_Resize(aMainHeight: Word);
    procedure ReturnToLobby(const aSaveName: UnicodeString);
    procedure UpdateState;
  end;

var
  LOBBY_PLAYER_NAMES_TEXT_ID_RESERVED: array[0..3] of Word =
    (TX_LOBBY_SLOT_CLOSED, TX_LOBBY_SLOT_OPEN, TX_AI_PLAYER_CLASSIC, TX_AI_PLAYER_ADVANCED);


implementation
uses
  KM_CommonTypes, KM_ResLocales, KM_CommonUtils, KM_Sound, KM_ResSound, KM_RenderUI,
  KM_Resource, KM_ResFonts, KM_NetPlayersList, KM_Main, KM_GameApp, KM_Points, KM_MapTypes;

const
  PANEL_SETUP_OPTIONS_TOP = 548;
  PANEL_SETUP_OPTIONS_HEIGHT = 170;
  RESET_BANS_COOLDOWN = 1000;
  ASK_READY_COOLDOWN = 1000;
  SPEED_MAX_VALUE = 2.5;
  SPEED_STEP = 0.1;


{ TKMGUIMenuLobby }
constructor TKMMenuLobby.Create(aParent: TKMPanel; aOnPageChange: TKMMenuChangeEventText);
begin
  inherited Create;

  fOnPageChange := aOnPageChange;
  OnEscKeyDown := EscKeyDown;
  OnKeyDown := KeyDown;

  fMapsSortUpdateNeeded := False;

  fMinimap := TKMMinimap.Create(True, True);

  fLastTimeResetBans := 0;
  fLastTimeAskReady := 0;

  fMapsMP := TKMapsCollection.Create([mfMP, mfDL], smByNameDesc, True);
  fSavesMP := TKMSavesCollection.Create;

  fDropBoxPlayers_LastItemIndex := -1;
  fLobbyTab := ltDesc;

  CreateControls(aParent);
  CreateChatMenu(aParent);
  CreatePlayerMenus(aParent);
  CreateSettingsPopUp(aParent);
end;


destructor TKMMenuLobby.Destroy;
begin
  fMapsMP.Free;
  fSavesMP.Free;
  fMinimap.Free;

  inherited;
end;


procedure TKMMenuLobby.UpdateMappings;
var
  I, K: Integer;
  OldLocalToNetPlayers: array[1..MAX_LOBBY_SLOTS] of Integer;
begin
  //First empty everything
  for I:=1 to MAX_LOBBY_SLOTS do
  begin
    OldLocalToNetPlayers[I] := fLocalToNetPlayers[I];
    fLocalToNetPlayers[I] := -1;
    fNetPlayersToLocal[I] := -1;
  end;
  K := 1;

  //Host (unless host is spectator)
  if (fNetworking.HostIndex <> -1) and not fNetworking.NetPlayers[fNetworking.HostIndex].IsSpectator then
  begin
    fLocalToNetPlayers[K] := fNetworking.HostIndex;
    fNetPlayersToLocal[fNetworking.HostIndex] := K;
    Inc(K);
  end;

  //Normal players
  for I:=1 to fNetworking.NetPlayers.Count do
    if (I <> fNetworking.HostIndex) and not fNetworking.NetPlayers[I].IsSpectator then
    begin
      fLocalToNetPlayers[K] := I;
      fNetPlayersToLocal[I] := K;
      Inc(K);
    end;

  //Host if spectator, always goes at the end
  if (fNetworking.HostIndex <> -1) and fNetworking.NetPlayers[fNetworking.HostIndex].IsSpectator then
  begin
    fLocalToNetPlayers[MAX_LOBBY_SLOTS] := fNetworking.HostIndex;
    fNetPlayersToLocal[fNetworking.HostIndex] := MAX_LOBBY_SLOTS;
  end;

  //Spectators, place them at the end
  K := MAX_LOBBY_SLOTS - fNetworking.NetPlayers.GetSpectatorCount + 1;
  for I:=1 to fNetworking.NetPlayers.Count do
    if (I <> fNetworking.HostIndex) and fNetworking.NetPlayers[I].IsSpectator then
    begin
      Assert((K <= MAX_LOBBY_SLOTS) and (fLocalToNetPlayers[K] = -1), 'Too many spectators');
      fLocalToNetPlayers[K] := I;
      fNetPlayersToLocal[I] := K;
      Inc(K);
    end;

  //If a player has moved slots on the list the dropboxes can get stuck open
  for I:=1 to MAX_LOBBY_SLOTS do
    if OldLocalToNetPlayers[I] <> fLocalToNetPlayers[I] then
    begin
      DropBox_PlayerSlot[I].CloseList;
      DropBox_Loc[I].CloseList;
      DropBox_Team[I].CloseList;
      DropBox_Colors[I].CloseList;
    end;
end;


procedure TKMMenuLobby.UpdateSpectatorDivide;
const
  TOP_OFF = 68;
  LINE_Y = 23;
  DIVIDE_Y = 5;
var
  I, DivideRow, OffY: Integer;
begin
  Image_HostStar.Hide; //In case host is unknown
  if (fNetworking <> nil) and (fNetworking.NetPlayers <> nil) then
    DivideRow := MAX_LOBBY_SLOTS - Max(MAX_LOBBY_SPECTATORS, fNetworking.NetPlayers.GetSpectatorCount)
  else
    DivideRow := MAX_LOBBY_PLAYERS;
  for I := 1 to MAX_LOBBY_SLOTS do
  begin
    OffY := TOP_OFF + (I-1) * LINE_Y;

    if I = DivideRow+1 then
      Bevel_SpecsDivide.Top := OffY;

    if I > DivideRow then
      Inc(OffY, DIVIDE_Y);

    Image_Flag[I].Top            := OffY;
    Label_Player[I].Top          := OffY+2;
    PercentBar_DownloadProgress[I].Top := OffY;
    DropBox_PlayerSlot[I].Top    := OffY;
    DropBox_Loc[I].Top           := OffY;
    DropBox_Team[I].Top          := OffY;
    DropBox_Colors[I].Top        := OffY;
    Image_Ready[I].Top           := OffY;
    Label_Ping[I].Top            := OffY;

    if (fNetworking <> nil) and (fLocalToNetPlayers[I] = fNetworking.HostIndex) then
    begin
      Image_HostStar.Top := OffY+2;
      Image_HostStar.Show;
      PercentBar_PlayerDl_ChVisibility(I, False);
    end;
  end;
  if (fNetworking <> nil) and (fNetworking.NetPlayers <> nil)
  and fNetworking.NetPlayers.SpectatorsAllowed then
  begin
    Panel_Players.Height := TOP_OFF + LINE_Y*MAX_LOBBY_SLOTS + DIVIDE_Y + 2;
    Bevel_SpecsDivide.Show;
  end
  else
  begin
    Panel_Players.Height := TOP_OFF + LINE_Y*MAX_LOBBY_PLAYERS + 2;
    Bevel_SpecsDivide.Hide;
  end;
  Bevel_Players.Height := Panel_Players.Height;
  Memo_Posts.Top := Panel_Players.Top + Panel_Players.Height + 5;
  Memo_Posts.Height := Edit_Post.Top - Memo_Posts.Top - 2;
end;


procedure TKMMenuLobby.CreateControls(aParent: TKMPanel);
  function MakeRow(const aCaption: array of string; aIndex: Integer): TKMListRow;
  var I: Integer;
  begin
    Result := MakeListRow(aCaption, aIndex);
    for I := Low(aCaption) to High(aCaption) do
    begin
      Result.Cells[I].HighlightOnMouseOver := True;
      if I = 1 then
      begin
        Result.Cells[I].Color := clLobbyOpponentAll;
        Result.Cells[I].HighlightColor := clLobbyOpponentAllHL;
      end
      else
        Result.Cells[I].HighlightColor := icGray;
    end;
  end;
const
  CW = 690; C1 = 35; C2 = 200; C3 = 360; C4 = 445; C5 = 570; C6 = 650;
  C1W = 155; C2W = 150; C3W = 75; C4W = 80;
  TC2_ADD = 50;
var
  I, K, OffY, SlotTxtWidth, AllTxtWidth, SpeedsCnt: Integer;
begin
  Panel_Lobby := TKMPanel.Create(aParent,0,0,aParent.Width, aParent.Height);
  Panel_Lobby.AnchorsStretch;

    //Server Name
    Panel_ServerName := TKMPanel.Create(Panel_Lobby, 30, 30, CW, 26);
      TKMBevel.Create(Panel_ServerName,   0,  0, CW, 26);
      Label_ServerName := TKMLabel.Create(Panel_ServerName, 10, 7, CW-20, 20, '', fntMetal, taLeft);

    //Players
    Panel_Players := TKMPanel.Create(Panel_Lobby, 30, 61, CW, 340);
      Bevel_Players := TKMBevel.Create(Panel_Players,  0,  0, CW, 340);

      CheckBox_HostControl := TKMCheckBox.Create(Panel_Players, 10, 10, (CW div 2) + TC2_ADD - 10, 20, gResTexts[TX_LOBBY_HOST_DOES_SETUP], fntMetal);
      CheckBox_HostControl.OnClick := PlayersSetupChange;

      CheckBox_Spectators := TKMCheckbox.Create(Panel_Players, (CW div 2) + TC2_ADD, 10, (CW div 2) - TC2_ADD - 10, 20, gResTexts[TX_LOBBY_ALLOW_SPECTATORS], fntMetal);
      CheckBox_Spectators.OnClick := PlayersSetupChange;

      CheckBox_RandomizeTeamLocations := TKMCheckBox.Create(Panel_Players, 10, 28, CW-20, 20, gResTexts[TX_LOBBY_RANDOMIZE_LOCATIONS], fntMetal);
      CheckBox_RandomizeTeamLocations.OnClick := PlayersSetupChange;

    OffY := 49;

      Image_PasswordLock := TKMImage.Create(Panel_Players, 13, OffY, 12, 16, 73, rxGuiMain);
      Image_PasswordLock.Hide;

      //Column titles
      TKMLabel.Create(Panel_Players, C1, OffY, C1W,  20, gResTexts[TX_LOBBY_HEADER_PLAYERS], fntOutline, taLeft);
      TKMLabel.Create(Panel_Players, C2, OffY, C2W,  20, gResTexts[TX_LOBBY_HEADER_STARTLOCATION], fntOutline, taLeft);
      TKMLabel.Create(Panel_Players, C3, OffY, C3W,  20, gResTexts[TX_LOBBY_HEADER_TEAM], fntOutline, taLeft);
      TKMLabel.Create(Panel_Players, C4, OffY, C4W,  20, gResTexts[TX_LOBBY_HEADER_FLAGCOLOR], fntOutline, taLeft);
      TKMLabel.Create(Panel_Players, C5, OffY, gResTexts[TX_LOBBY_HEADER_READY], fntOutline, taCenter);
      TKMLabel.Create(Panel_Players, C6, OffY, gResTexts[TX_LOBBY_HEADER_PING], fntOutline, taCenter);

      Bevel_SpecsDivide := TKMBevel.Create(Panel_Players, 10, 50, CW-20, 3);

      Image_HostStar := TKMImage.Create(Panel_Players, C2-25, 50, 20, 20, 77, rxGuiMain);
      Image_HostStar.Hide;

      SlotTxtWidth := Max(C1W - 45,
                          gRes.Fonts[fntGrey].GetMaxPrintWidthOfStrings([gResTexts[TX_LOBBY_SLOT_OPEN],
                                                                          gResTexts[TX_LOBBY_SLOT_CLOSED],
                                                                          gResTexts[TX_AI_PLAYER_CLASSIC],
                                                                          gResTexts[TX_AI_PLAYER_ADVANCED]]));

      AllTxtWidth := Max(40, gRes.Fonts[fntGrey].GetMaxPrintWidthOfStrings([gResTexts[TX_LOBBY_SLOT_OPEN_ALL],
                                                                             gResTexts[TX_LOBBY_SLOT_CLOSED_ALL],
                                                                             gResTexts[TX_LOBBY_SLOT_AI_ALL]]));

      for I := 1 to MAX_LOBBY_SLOTS do
      begin
        OffY := 70 + (I-1) * 23;
        Image_Flag[I] := TKMImage.Create(Panel_Players, 10, OffY, 20, 20, 0, rxGuiMain);
        Image_Flag[I].ImageCenter;
        Image_Flag[I].Tag := I; //Required for PlayerMenuShow
        Image_Flag[I].OnClick := PlayerMenuShow;
        Image_Flag[I].HighlightOnMouseOver := True;

        Label_Player[I] := TKMLabel.Create(Panel_Players, C1, OffY+2, C1W, 20, '', fntGrey, taLeft);
        Label_Player[I].Hide;


        DropBox_PlayerSlot[I] := TKMDropColumns.Create(Panel_Players, C1, OffY, C1W, 20, fntGrey, '', bsMenu, False);
        DropBox_PlayerSlot[I].DropWidth := SlotTxtWidth + 5 + AllTxtWidth;
        DropBox_PlayerSlot[I].SetColumns(fntOutline, ['', gResTexts[TX_MENU_MAP_TITLE]], [0, SlotTxtWidth + 5], [True, False]);
        //1st column is used to set 'All' (All Open/All AI/All Closed),
        //Its external button analogue, so we do not want to invoke f.e. OnChange (AI) when 'AI All' clicked
        DropBox_PlayerSlot[I].List.Columns[1].TriggerOnChange := False;
        if I <= MAX_LOBBY_PLAYERS then
        begin
          DropBox_PlayerSlot[I].Add(MakeRow([gResTexts[TX_LOBBY_SLOT_OPEN], gResTexts[TX_LOBBY_SLOT_OPEN_ALL]], I)); //Player can join into this slot
          DropBox_PlayerSlot[I].Add(MakeRow([gResTexts[TX_LOBBY_SLOT_CLOSED], gResTexts[TX_LOBBY_SLOT_CLOSED_ALL]], I)); //Closed, nobody can join it
          DropBox_PlayerSlot[I].Add(MakeRow([gResTexts[TX_AI_PLAYER_CLASSIC], gResTexts[TX_LOBBY_SLOT_AI_ALL]], I)); //This slot is an AI player
          DropBox_PlayerSlot[I].Add(MakeRow([gResTexts[TX_AI_PLAYER_ADVANCED], gResTexts[TX_LOBBY_SLOT_AI_ALL]], I)); //This slot is an advanced AI player
        end
        else
        begin
          DropBox_PlayerSlot[I].Add(MakeRow([gResTexts[TX_LOBBY_SLOT_OPEN], gResTexts[TX_LOBBY_SLOT_OPEN_ALL]], I));
          DropBox_PlayerSlot[I].Add(MakeRow([gResTexts[TX_LOBBY_SLOT_CLOSED], gResTexts[TX_LOBBY_SLOT_CLOSED_ALL]], I));
        end;
        DropBox_PlayerSlot[I].ItemIndex := 0; //Open
        DropBox_PlayerSlot[I].OnChange := PlayersSetupChange;
        DropBox_PlayerSlot[I].List.OnCellClick := DropBoxPlayers_CellClick;
        DropBox_PlayerSlot[I].OnShowList := DropBoxPlayers_Show;

        DropBox_Loc[I] := TKMDropList.Create(Panel_Players, C2, OffY, C2W, 20, fntGrey, '', bsMenu);
        DropBox_Loc[I].Add(gResTexts[TX_LOBBY_RANDOM], LOC_RANDOM);
        DropBox_Loc[I].OnChange := PlayersSetupChange;
        DropBox_Loc[I].DropCount := MAX_LOBBY_PLAYERS + 2; //also 'Random' and possible 'Spectator'

        PercentBar_DownloadProgress[I] := TKMPercentBar.Create(Panel_Players, C2, OffY, 150, 20, fntGrey);
        PercentBar_DownloadProgress[I].Caption := gResTexts[TX_LOBBY_DOWNLOADING];
        PercentBar_DownloadProgress[I].Hide;
        PercentBar_DownloadProgress[I].TextYOffset := -3;

        DropBox_Team[I] := TKMDropList.Create(Panel_Players, C3, OffY, C3W, 20, fntGrey, '', bsMenu);
        DropBox_Team[I].Add('-');
        for K := 1 to MAX_TEAMS do DropBox_Team[I].Add(IntToStr(K));
        DropBox_Team[I].OnChange := PlayersSetupChange;

        DropBox_Colors[I] := TKMDropColumns.Create(Panel_Players, C4, OffY, C4W, 20, fntGrey, '', bsMenu);
        DropBox_Colors[I].SetColumns(fntOutline, [''], [0]);
        DropBox_Colors[I].List.ShowHeader := False;
        DropBox_Colors[I].DropCount := 13;
        DropBox_Colors[I].FadeImageWhenDisabled := False;
        DropBox_Colors[I].Add(MakeListRow([''], [$FFFFFFFF], [MakePic(rxGuiMain, 31)], 0));
        for K := Low(MP_TEAM_COLORS) to High(MP_TEAM_COLORS) do
          DropBox_Colors[I].Add(MakeListRow([''], [MP_TEAM_COLORS[K]], [MakePic(rxGuiMain, 30)]));
        DropBox_Colors[I].OnChange := PlayersSetupChange;

        Image_Ready[I] := TKMImage.Create(Panel_Players, C5-8, OffY, 16, 16, 32, rxGuiMain);
        Label_Ping[I] := TKMLabel.Create(Panel_Players, C6, OffY, '', fntMetal, taCenter);
      end;

    //Chat area
    Memo_Posts := TKMMemo.Create(Panel_Lobby, 30, 406, CW, 282, fntArial, bsMenu);
    Memo_Posts.Anchors := [anLeft, anTop, anBottom];
    Memo_Posts.AutoWrap := True;
    Memo_Posts.IndentAfterNL := True; //Don't let players fake system messages
    Memo_Posts.ScrollDown := True;

    Button_Post := TKMButtonFlat.Create(Panel_Lobby, 30, 696, 30, 22, 0);
    Button_Post.CapOffsetY := -11;
    Button_Post.Font := fntGrey;
    Button_Post.OnClick := ChatMenuShow;
    Button_Post.Anchors := [anLeft, anBottom];

    Edit_Post := TKMEdit.Create(Panel_Lobby, 60, 696, CW, 22, fntArial);
    Edit_Post.OnChange := ChatTextChanged;
    Edit_Post.OnKeyDown := PostKeyDown;
    Edit_Post.OnIsKeyEventHandled := IsKeyEvent_Return_Handled;
    Edit_Post.Anchors := [anLeft, anBottom];
    Edit_Post.ShowColors := True;

    //Setup
    Panel_Setup := TKMPanel.Create(Panel_Lobby, 725, 30, 270, 723);
    Panel_Setup.Anchors := [anLeft, anTop, anBottom];
      with TKMBevel.Create(Panel_Setup,  0,  0, 270, 723) do AnchorsStretch;
      Radio_MapType := TKMRadioGroup.Create(Panel_Setup, 10, 10, 250, 80, fntMetal);
      Radio_MapType.Add(gResTexts[TX_LOBBY_MAP_BUILD]);
      Radio_MapType.Add(gResTexts[TX_LOBBY_MAP_FIGHT]);
      Radio_MapType.Add(gResTexts[TX_LOBBY_MAP_COOP]);
      Radio_MapType.Add(gResTexts[TX_LOBBY_MAP_SPECIAL]);
      Radio_MapType.Add(gResTexts[TX_LOBBY_MAP_SAVED]);
      Radio_MapType.ItemIndex := 0;
      Radio_MapType.OnChange := MapTypeChanged;

      DropCol_Maps := TKMDropColumns.Create(Panel_Setup, 10, 95, 250, 20, fntMetal, gResTexts[TX_LOBBY_MAP_SELECT], bsMenu);
      DropCol_Maps.DropCount := 19;
      InitDropColMapsList;
      DropCol_Maps.OnShowList := MapList_OnShow;
      DropCol_Maps.List.OnColumnClick := MapColumnClick;
      DropCol_Maps.List.SearchColumn := 1;
      DropCol_Maps.OnChange := MapChange;
      DropCol_Maps.List.OnCellClick := DropBoxMaps_CellClick;

      Label_MapName := TKMLabel.Create(Panel_Setup, 10, 95, 250, 20, '', fntMetal, taLeft);

      Panel_SetupMinimap := TKMPanel.Create(Panel_Setup, 0, 120, 270, 200);
        MinimapView := TKMMinimapView.Create(Panel_SetupMinimap, 39, 4, 191, 191, True);
        MinimapView.ShowLocs := True; //In the minimap we want player locations to be shown
        MinimapView.OnLocClick := MinimapLocClick;

      Panel_SetupTransfer := TKMPanel.Create(Panel_Setup, 0, 120, 270, 200);
        Button_SetupDownload := TKMButton.Create(Panel_SetupTransfer, 10, 0, 250, 30, gResTexts[TX_LOBBY_DOWNLOAD], bsMenu);
        Button_SetupDownload.OnClick := FileDownloadClick;
        PercentBar_SetupProgress := TKMPercentBar.Create(Panel_SetupTransfer, 10, 0, 250, 24, fntGame);
      Panel_SetupTransfer.Hide;

      Button_TabDesc := TKMButton.Create(Panel_Setup, 10, 324, 125, 20, gResTexts[TX_LOBBY_MAP_DESCRIPTION], bsMenu);
      Button_TabDesc.OnClick := GameOptionsTabSwitch;
      Button_TabDesc.Hide;
      Button_TabOptions := TKMButton.Create(Panel_Setup, 10+125, 324, 125, 20, gResTexts[TX_LOBBY_OPTIONS], bsMenu);
      Button_TabOptions.OnClick := GameOptionsTabSwitch;
      Button_TabOptions.Hide;

      Panel_SetupDesc := TKMPanel.Create(Panel_Setup, 0, 324, 270, 218);
      Panel_SetupDesc.Anchors := [anLeft, anTop, anBottom];
        Memo_MapDesc := TKMMemo.Create(Panel_SetupDesc, 10, 0, 250, 218, fntGame, bsMenu);
        Memo_MapDesc.Anchors := [anLeft,anTop,anBottom];
        Memo_MapDesc.AutoWrap := True;
        Memo_MapDesc.ItemHeight := 16;

        Button_SetupReadme := TKMButton.Create(Panel_SetupDesc, 10, 200, 250, 25, gResTexts[TX_LOBBY_VIEW_README], bsMenu);
        Button_SetupReadme.Anchors := [anLeft,anBottom];
        Button_SetupReadme.OnClick := ReadmeClick;
        Button_SetupReadme.Hide;

      Panel_SetupOptions := TKMPanel.Create(Panel_Setup, 0, PANEL_SETUP_OPTIONS_TOP, 270, PANEL_SETUP_OPTIONS_HEIGHT);
      Panel_SetupOptions.Anchors := [anLeft,anBottom];

        Label_GameOptions := TKMLabel.Create(Panel_SetupOptions, 10, 4, 250, 20, gResTexts[TX_LOBBY_GAME_OPTIONS], fntOutline, taLeft);
        Label_GameOptions.Anchors := [anLeft,anTop];

        Panel_Difficulty := TKMPanel.Create(Panel_SetupOptions, 0, 26, 270, 25);
          Label_Difficulty := TKMLabel.Create(Panel_Difficulty, 10, 2, gResTexts[TX_MISSION_DIFFICULTY_CAMPAIGN], fntMetal, taLeft);
          Label_Difficulty.Anchors := [anLeft, anBottom];
          DropBox_Difficulty := TKMDropList.Create(Panel_Difficulty, 130, 0, 130, 20, fntMetal, gResTexts[TX_MISSION_DIFFICULTY], bsMenu);
          DropBox_Difficulty.Anchors := [anLeft, anBottom];
          DropBox_Difficulty.OnChange := GameOptionsChange;
        Panel_Difficulty.Hide;

        Panel_GameOptions := TKMPanel.Create(Panel_SetupOptions, 0, 26, 270, 150);
          TrackBar_LobbyPeacetime := TKMTrackBar.Create(Panel_GameOptions, 10, 0, 250, 0, 120);
          TrackBar_LobbyPeacetime.Anchors := [anLeft,anBottom];
          TrackBar_LobbyPeacetime.Caption := gResTexts[TX_LOBBY_PEACETIME];
          TrackBar_LobbyPeacetime.Step := 5; //Round to 5min steps
          TrackBar_LobbyPeacetime.OnChange := GameOptionsChange;

          SpeedsCnt := Round((SPEED_MAX_VALUE - 1) / SPEED_STEP) + 1;

          TrackBar_SpeedPT := TKMTrackBar.Create(Panel_GameOptions, 10, 46, 250, 1, SpeedsCnt);
          TrackBar_SpeedPT.Anchors := [anLeft,anBottom];
          TrackBar_SpeedPT.Caption := gResTexts[TX_LOBBY_GAMESPEED_PEACETIME];
          TrackBar_SpeedPT.ThumbWidth := 45; //Enough to fit 'x1.5' 'x1.25'
          TrackBar_SpeedPT.OnChange := GameOptionsChange;

          TrackBar_SpeedAfterPT := TKMTrackBar.Create(Panel_GameOptions, 10, 90, 250, 1, SpeedsCnt);
          TrackBar_SpeedAfterPT.Anchors := [anLeft,anBottom];
          TrackBar_SpeedAfterPT.Caption := gResTexts[TX_LOBBY_GAMESPEED];
          TrackBar_SpeedAfterPT.ThumbWidth := 45; //Enough to fit 'x1.25'
          TrackBar_SpeedAfterPT.OnChange := GameOptionsChange;

    Button_Back := TKMButton.Create(Panel_Lobby, 30, 723, 220, 30, gResTexts[TX_LOBBY_QUIT], bsMenu);
    Button_Back.Anchors := [anLeft, anBottom];
    Button_Back.OnClick := BackClick;

    Button_ChangeSettings := TKMButton.Create(Panel_Lobby, 265, 723, 220, 30, gResTexts[TX_LOBBY_ROOMSETTINGS], bsMenu);
    Button_ChangeSettings.Anchors := [anLeft, anBottom];
    Button_ChangeSettings.OnClick := SettingsClick;

    Button_Start := TKMButton.Create(Panel_Lobby, 500, 723, 220, 30, NO_TEXT, bsMenu);
    Button_Start.Anchors := [anLeft, anBottom];
    Button_Start.OnClick := StartClick;
    Button_Start.OnChangeEnableStatus := StartBtnChangeEnabled;

  UpdateSpectatorDivide;
end;


procedure TKMMenuLobby.CreateChatMenu(aParent: TKMPanel);
begin
  Menu_Chat := TKMPopUpMenu.Create(aParent, 140);
  Menu_Chat.Anchors := [anLeft, anBottom];
  //Menu gets populated right before show
  Menu_Chat.AddItem(NO_TEXT);
  Menu_Chat.OnClick := ChatMenuClick;
end;


procedure TKMMenuLobby.CreatePlayerMenus(aParent: TKMPanel);
begin
  Menu_Host := TKMPopUpMenu.Create(aParent, gRes.Fonts[fntGrey].GetMaxPrintWidthOfStrings( // Calc max width for popup which depends of texts translation
    [gResTexts[TX_LOBBY_PLAYER_KICK], 
    gResTexts[TX_LOBBY_PLAYER_BAN], 
    gResTexts[TX_LOBBY_PLAYER_SET_HOST], 
    gResTexts[TX_MUTE_PLAYER],
    gResTexts[TX_UNMUTE_PLAYER]])
    + 10);
  Menu_Host.AddItem(gResTexts[TX_LOBBY_PLAYER_KICK]);
  Menu_Host.AddItem(gResTexts[TX_LOBBY_PLAYER_BAN]);
  Menu_Host.AddItem(gResTexts[TX_LOBBY_PLAYER_SET_HOST]);
  Menu_Host.AddItem('');
  Menu_Host.OnClick := HostMenuClick;

  // Calc max width for popup which depends of texts translation
  Menu_Joiner := TKMPopUpMenu.Create(aParent, gRes.Fonts[fntGrey].GetMaxPrintWidthOfStrings(
    [gResTexts[TX_MUTE_PLAYER],
     gResTexts[TX_UNMUTE_PLAYER]])
    + 10);
  Menu_Joiner.AddItem('');
  Menu_Joiner.OnClick := JoinerMenuClick;
end;


procedure TKMMenuLobby.CreateSettingsPopUp(aParent: TKMPanel);
const
  SET_W = 400;
begin
  Panel_Settings := TKMPanel.Create(aParent, 362, 250, SET_W, 350);
  Panel_Settings.AnchorsCenter;
    TKMBevel.Create(Panel_Settings, -1000,  -1000, 4000, 4000);
    with TKMImage.Create(Panel_Settings, -20, -75, SET_W + 40, 440, 15, rxGuiMain) do ImageStretch;
    TKMBevel.Create(Panel_Settings,   0,  0, SET_W, 343);
    TKMLabel.Create(Panel_Settings,  20, 10, SET_W - 40, 20, gResTexts[TX_LOBBY_ROOMSETTINGS], fntOutline, taCenter);

    TKMLabel.Create(Panel_Settings, 20, 50, SET_W - 40, 20, gResTexts[TX_LOBBY_ROOM_DESCRIPTION], fntOutline, taCenter);
    Edit_Description := TKMEdit.Create(Panel_Settings, 20, 70, SET_W - 40, 20, fntGrey);
    Edit_Description.AllowedChars := acText;
    Edit_Description.MaxLen := 60;

    TKMLabel.Create(Panel_Settings, 20, 100, SET_W - 40, 20, gResTexts[TX_LOBBY_ROOM_PASSWORD], fntOutline, taCenter);
    Edit_Password := TKMEdit.Create(Panel_Settings, 20, 120, SET_W - 40, 20, fntGrey);
    Edit_Password.AllowedChars := acANSI7; //Passwords are basic ANSI so everyone can type them
    Checkbox_RememberPassword := TKMCheckbox.Create(Panel_Settings, 20, 153, SET_W - 20, 30, gResTexts[TX_LOBBY_REMEMBER_PASSWORD], fntGrey);

    Button_SettingsResetBans := TKMButton.Create(Panel_Settings, 20, 180, SET_W - 40, 30, gResTexts[TX_LOBBY_RESET_BANS], bsMenu);
    Button_SettingsUseLastPassword := TKMButton.Create(Panel_Settings, 20, 220, SET_W - 40, 30, gResTexts[TX_LOBBY_USE_LAST_PASSWORD], bsMenu);
    Button_SettingsResetBans.OnClick := SettingsClick;
    Button_SettingsUseLastPassword.OnClick := SettingsClick;

    Button_SettingsAskReady := TKMButton.Create(Panel_Settings, 20, 260, SET_W - 40, 30, gResTexts[TX_LOBBY_ALERT_READY_BTN], bsMenu);
    Button_SettingsAskReady.OnClick := WakeUpNotReadyClick;
    Button_SettingsAskReady.Enabled := False;
    Button_SettingsSave := TKMButton.Create(Panel_Settings, 20, 300, (SET_W - 50) div 2, 30, gResTexts[TX_LOBBY_ROOM_OK], bsMenu);
    Button_SettingsSave.OnClick := SettingsClick;
    Button_SettingsCancel := TKMButton.Create(Panel_Settings, (SET_W div 2) + 10, 300, (SET_W - 50) div 2, 30, gResTexts[TX_LOBBY_ROOM_CANCEL], bsMenu);
    Button_SettingsCancel.OnClick := SettingsClick;
end;


procedure TKMMenuLobby.ChatMenuSelect(aItemTag: TKMNetHandleIndex);

  procedure UpdateButtonCaption(aCaption: UnicodeString; aColor: Cardinal = 0);
  var CapWidth: Integer;
  const MIN_SIZE = 80; //Minimum size for the button
  begin
    //Update button width according to selected item
    CapWidth := gRes.Fonts[Button_Post.Font].GetTextSize(aCaption).X;
    CapWidth := Max(MIN_SIZE, CapWidth+10); //Apply minimum size
    if aColor <> 0 then
      aCaption := WrapColor(aCaption, aColor);
    Button_Post.Caption := aCaption;
    Button_Post.Width := CapWidth;

    Edit_Post.AbsLeft := Button_Post.AbsLeft + Button_Post.Width + 4;
    Edit_Post.Width := Memo_Posts.Width - Button_Post.Width - 4;
  end;

var NetI: Integer;
begin
  case aItemTag of
    CHAT_MENU_ALL:        begin //All
                            gGameApp.Chat.Mode := cmAll;
                            UpdateButtonCaption(gResTexts[TX_CHAT_ALL]);
                            Edit_Post.DrawOutline := False; //No outline for All
                          end;
    CHAT_MENU_TEAM:       begin //Team
                            gGameApp.Chat.Mode := cmTeam;
                            UpdateButtonCaption(gResTexts[TX_CHAT_TEAM], $FF66FF66);
                            Edit_Post.DrawOutline := True;
                            Edit_Post.OutlineColor := $FF66FF66;
                          end;
    CHAT_MENU_SPECTATORS: begin //Spectators
                            gGameApp.Chat.Mode := cmSpectators;
                            UpdateButtonCaption(gResTexts[TX_CHAT_SPECTATORS], $FF66FF66);
                            Edit_Post.DrawOutline := True;
                            Edit_Post.OutlineColor := $FF66FF66;
                          end;
    else  begin //Whisper to player
            NetI := fNetworking.NetPlayers.ServerToLocal(aItemTag);
            if NetI <> -1 then
            begin
              gGameApp.Chat.Mode := cmWhisper;
              Edit_Post.DrawOutline := True;
              Edit_Post.OutlineColor := $FF00B9FF;
              with fNetworking.NetPlayers[NetI] do
              begin
                gGameApp.Chat.WhisperRecipient := IndexOnServer;
                UpdateButtonCaption(NiknameU, IfThen(FlagColorID <> 0, FlagColorToTextColor(FlagColor), 0));
              end;
            end;
          end;
    end;
end;


procedure TKMMenuLobby.ChatMenuClick(Sender: TObject);
begin
  if Menu_Chat.ItemIndex <> -1 then
    ChatMenuSelect(Menu_Chat.ItemTags[Menu_Chat.ItemIndex]);
end;


procedure TKMMenuLobby.ChatMenuShow(Sender: TObject);
var
  C: TKMControl;
  I: Integer;
  n: TKMNetPlayerInfo;
begin
  //Populate menu with right options
  Menu_Chat.Clear;

  Menu_Chat.AddItem(gResTexts[TX_CHAT_ALL], CHAT_MENU_ALL);

  //Only show "Team" if the player is on a team
  if fNetworking.MyNetPlayer.Team <> 0 then
    Menu_Chat.AddItem('[$66FF66]' + gResTexts[TX_CHAT_TEAM], CHAT_MENU_TEAM);

  //Only show "Spectators" if the player is a spectator
  if fNetworking.MyNetPlayer.IsSpectator then
    Menu_Chat.AddItem('[$66FF66]' + gResTexts[TX_CHAT_SPECTATORS], CHAT_MENU_SPECTATORS);

  for I := 1 to fNetworking.NetPlayers.Count do
  if I <> fNetworking.MyIndex then //Can't whisper to yourself
  begin
    n := fNetworking.NetPlayers[I];

    if n.IsHuman and n.Connected and not n.Dropped then
      Menu_Chat.AddItem(n.NiknameColoredU, n.IndexOnServer);
  end;

  C := TKMControl(Sender);
  //Position the menu next to the icon, but do not overlap players name
  Menu_Chat.ShowAt(C.AbsLeft, C.AbsTop - Menu_Chat.Height);
end;


//Try to detect which kind it is
function TKMMenuLobby.DetectMapType: Integer;
begin
  //Default
  Result := 0;

  case fNetworking.SelectGameKind of
    ngkMap:  if fNetworking.MapInfo.TxtInfo.IsCoop then
                Result := 2
              else
              if fNetworking.MapInfo.TxtInfo.IsSpecial then
                Result := 3
              else
              if fNetworking.MapInfo.MissionMode = mmTactic then
                Result := 1;
    ngkSave: Result := 4;
  end;
end;


procedure TKMMenuLobby.ChatTextChanged(Sender: TObject);
begin
  gGameApp.Chat.Text := Edit_Post.Text;
end;


procedure TKMMenuLobby.UpdateChatControls;
begin
  if gGameApp.Chat.Mode = cmWhisper then
    ChatMenuSelect(gGameApp.Chat.WhisperRecipient)
  else
    ChatMenuSelect(CHAT_TAG[gGameApp.Chat.Mode]);

  Edit_Post.Text := gGameApp.Chat.Text;
  Memo_Posts.Text := gGameApp.Chat.Messages;
  Memo_Posts.ScrollToBottom;
end;


procedure TKMMenuLobby.SetChatHandlers;
begin
  gGameApp.Chat.OnError := HandleError;
  gGameApp.Chat.OnPost := PostMsg;
  gGameApp.Chat.OnPostLocal := PostLocalMsg;
  gGameApp.Chat.OnChange := UpdateChatControls;

  UpdateChatControls
end;


procedure TKMMenuLobby.Show(aKind: TKMNetPlayerKind; aNetworking: TKMNetworking; aMainHeight: Word);
var I: Integer;
begin
  fNetworking := aNetworking;

  Reset(aKind);

  //Events binding is the same for Host and Joiner because of stand-alone Server
  //E.g. If Server fails, Host can be disconnected from it as well as a Joiner
  fNetworking.OnTextMessage  := Lobby_OnMessage;
  fNetworking.OnPlayersSetup := Lobby_OnPlayersSetup;
  fNetworking.OnUpdateMinimap := Lobby_OnUpdateMinimap;
  fNetworking.OnGameOptions  := Lobby_OnGameOptions;
  fNetworking.OnMapName      := Lobby_OnMapName;
  fNetworking.OnMapMissing   := Lobby_OnMapMissing;
  fNetworking.OnPingInfo     := Lobby_OnPingInfo;
  //fNetworking.OnStartMap - already assigned in gGameApp when Net is created
  //fNetworking.OnStartSave - already assigned in gGameApp when Net is created
  fNetworking.OnDisconnect   := Lobby_OnDisconnect;
  fNetworking.OnReassignedHost := Lobby_OnReassignedToHost;
  fNetworking.OnReassignedJoiner := Lobby_OnReassignedToJoiner;
  fNetworking.OnFileTransferProgress := Lobby_OnFileTransferProgress;
  fNetworking.OnPlayerFileTransferProgress := Lobby_OnPlayerFileTransferProgress;
  fNetworking.OnSetPassword := Lobby_OnSetPassword;

  Radio_MapType.ItemIndex := gGameApp.GameSettings.MenuLobbyMapType;
  UpdateMapList;

  //Update chat
  SetChatHandlers;

  for I := 1 to MAX_LOBBY_SLOTS do
  begin
    fLocalToNetPlayers[I] := -1;
    fNetPlayersToLocal[I] := -1;
  end;

  Panel_Lobby.Show;
  Lobby_Resize(aMainHeight);
end;


procedure TKMMenuLobby.UpdateDescNOptionsUI;
var
  DiffHeight: Integer; //Difficulty panel height
begin
  DiffHeight := Panel_Difficulty.Height*Byte(Panel_Difficulty.IsSetVisible);
  if Button_TabDesc.Visible then
  begin
    //Not enough space, so enabled tabbed view
    Panel_SetupDesc.Top := 350;
    Panel_SetupDesc.Height := fMainHeight - 406;
    Panel_SetupOptions.Top := 350;
  end
  else
  begin
    //We have enough space, so stack Options below Desc
    Panel_SetupDesc.Top := 324;
    Panel_SetupDesc.Height := fMainHeight - 550 - DiffHeight;
    Panel_SetupOptions.Top := 330 + Panel_SetupDesc.Height;
  end;
  Panel_SetupOptions.Height := PANEL_SETUP_OPTIONS_HEIGHT + DiffHeight;
  Panel_GameOptions.Top := 26 + DiffHeight;
end;


procedure TKMMenuLobby.Lobby_Resize(aMainHeight: Word);
begin
  if not Panel_Lobby.Visible then Exit;
  fMainHeight := aMainHeight;
  //If the vertical screen height goes below a certain amount we need to switch to "compact" mode
  if aMainHeight >= 660 then
  begin
    //We have enough space, so stack Options below Desc
    Button_TabDesc.Hide;
    Button_TabOptions.Hide;
    Panel_SetupDesc.Show;
    Panel_SetupOptions.Show;
    UpdateDescNOptionsUI;
  end
  else
  begin
    //Not enough space, so enabled tabbed view
    Button_TabDesc.Show;
    Button_TabOptions.Show;
    UpdateDescNOptionsUI;
    GameOptionsTabSwitch(nil);
  end;
end;


procedure TKMMenuLobby.GameOptionsTabSwitch(Sender: TObject);
begin
  if Sender = Button_TabDesc then
    fLobbyTab := ltDesc;
  if Sender = Button_TabOptions then
    fLobbyTab := ltOptions;

  case fLobbyTab of
    ltDesc:    begin
                 Panel_SetupDesc.Show;
                 Panel_SetupOptions.Hide;
               end;
    ltOptions: begin
                 Panel_SetupDesc.Hide;
                 Panel_SetupOptions.Show;
               end;
  end;
end;


procedure TKMMenuLobby.EscKeyDown(Sender: TObject);
begin
  if Button_SettingsCancel.IsClickable then
    SettingsClick(Button_SettingsCancel);
end;


procedure TKMMenuLobby.KeyDown(Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_RETURN:  if Panel_Settings.Visible then
                  SettingsClick(Button_SettingsSave);
  end;
end;


procedure TKMMenuLobby.BackClick(Sender: TObject);
begin
  //Scan should be terminated, it is no longer needed
  fMapsMP.TerminateScan;

  fNetworking.AnnounceDisconnect;
  fNetworking.Disconnect;

  fOnPageChange(gpMultiplayer, gResTexts[TX_GAME_ERROR_DISCONNECT]);
end;


//Reset everything to it's defaults depending on users role (Host/Joiner/Reassigned)
procedure TKMMenuLobby.Reset(aKind: TKMNetPlayerKind; aPreserveMaps: Boolean = False);
var I: Integer;
begin
  Label_ServerName.Caption := '';

  for I := 1 to MAX_LOBBY_SLOTS do
  begin
    Label_Player[I].Caption := '.';
    Label_Player[I].FontColor := $FFFFFFFF;
    Image_Flag[I].TexID := 0;
    Image_Flag[I].HighlightOnMouseOver := False;
    Label_Player[I].Hide;
    PercentBar_PlayerDl_ChVisibility(I, False);
    DropBox_PlayerSlot[I].Visible := I <= MAX_LOBBY_PLAYERS; //Spectators hidden initially
    DropBox_PlayerSlot[I].Disable;
    DropBox_PlayerSlot[I].ItemIndex := 0; //Open
    DropBox_Loc[I].ItemIndex := 0;
    DropBox_Loc[I].Disable;
    DropBox_Loc[I].Visible := I <= MAX_LOBBY_PLAYERS; //Spectators hidden initially
    DropBox_Team[I].Disable;
    DropBox_Team[I].ItemIndex := 0;
    DropBox_Team[I].Visible := I <= MAX_LOBBY_PLAYERS; //Spectators hidden initially
    DropBox_Colors[I].Disable;
    DropBox_Colors[I].ItemIndex := 0;
    DropBox_Colors[I].Visible := I <= MAX_LOBBY_PLAYERS; //Spectators hidden initially
    Image_Ready[I].TexID := 0;
    Label_Ping[I].Caption := '';
  end;

  Label_MapName.Caption := '';
  Memo_MapDesc.Clear;

  Memo_MapDesc.Height := Panel_SetupDesc.Height;
  Button_SetupReadme.Hide;

  TrackBar_LobbyPeacetime.Position := 0; //Default peacetime = 0
  TrackBar_SpeedPT.Position := 1; //Default speed = 1
  TrackBar_SpeedPT.ThumbText := 'x1';
  TrackBar_SpeedAfterPT.Position := 1; //Default speed = 1
  TrackBar_SpeedAfterPT.ThumbText := 'x1';

  Lobby_OnMapName('');

  //Setup for Host
  if aKind = lpkHost then
  begin
    Radio_MapType.Enable;
    Radio_MapType.ItemIndex := 0;
    if not aPreserveMaps then UpdateMapList;
    DropCol_Maps.Show;
    Label_MapName.Hide;
    Button_Start.Caption := gResTexts[TX_LOBBY_START]; //Start
    Button_Start.Disable;
    DropBox_Difficulty.Disable;
    TrackBar_LobbyPeacetime.Disable;
    TrackBar_SpeedPT.Disable;
    TrackBar_SpeedAfterPT.Disable;
    CheckBox_HostControl.Enable;
    CheckBox_RandomizeTeamLocations.Enable;
    CheckBox_Spectators.Enable;
    Button_ChangeSettings.Show;
  end
  else //Setup for Joiner
  begin
    Radio_MapType.Disable;
    Radio_MapType.ItemIndex := 0;
    DropCol_Maps.Hide;
    Label_MapName.Show;
    Button_Start.Caption := gResTexts[TX_LOBBY_READY]; //Ready
    Button_Start.Enable;
    DropBox_Difficulty.Disable;
    TrackBar_LobbyPeacetime.Disable;
    TrackBar_SpeedPT.Disable;
    TrackBar_SpeedAfterPT.Disable;
    CheckBox_HostControl.Disable;
    CheckBox_RandomizeTeamLocations.Disable;
    CheckBox_Spectators.Disable;
    Button_ChangeSettings.Hide;
  end;
  UpdateSpectatorDivide;
end;


procedure TKMMenuLobby.GameOptionsChange(Sender: TObject);
var
  MD: TKMMissionDifficulty;
begin
  if (DropBox_Difficulty.Count > 0) and DropBox_Difficulty.IsSelected then
    MD := TKMMissionDifficulty(DropBox_Difficulty.GetSelectedTag)
  else
    MD := mdNone;

  //Update the game options
  fNetworking.UpdateGameOptions(EnsureRange(TrackBar_LobbyPeacetime.Position, 0, 300),
                                TrackBarPos2Speed(TrackBar_SpeedPT.Position),
                                TrackBarPos2Speed(TrackBar_SpeedAfterPT.Position),
                                MD);

  //Refresh the data to controls
  Lobby_OnGameOptions(nil);
end;


procedure TKMMenuLobby.FileDownloadClick(Sender: TObject);
begin
  if Sender = Button_SetupDownload then
  begin
    fNetworking.RequestFileTransfer;
    Button_SetupDownload.Hide;
    Lobby_OnFileTransferProgress(1, 0);
    PercentBar_SetupProgress.Caption := gResTexts[TX_LOBBY_DOWNLOADING];
  end;
end;


procedure TKMMenuLobby.ReadmeClick(Sender: TObject);
begin
  if not fNetworking.MapInfo.ViewReadme then
    gGameApp.Chat.AddLine(gResTexts[TX_LOBBY_PDF_ERROR]);
end;


procedure TKMMenuLobby.UpdateGameOptionsUI;
begin
  TrackBar_SpeedPT.ThumbText := 'x' + FormatFloat('##0.##', TrackBarPos2Speed(TrackBar_SpeedPT.Position));
  TrackBar_SpeedAfterPT.ThumbText := 'x' + FormatFloat('##0.##', TrackBarPos2Speed(TrackBar_SpeedAfterPT.Position));
end;


procedure TKMMenuLobby.Lobby_OnGameOptions(Sender: TObject);
var
  MD: TKMMissionDifficulty;
begin
  TrackBar_LobbyPeacetime.Position := fNetworking.NetGameOptions.Peacetime;

  TrackBar_SpeedPT.Enabled   := (TrackBar_LobbyPeacetime.Position > 0) and TrackBar_SpeedAfterPT.Enabled;
  TrackBar_SpeedPT.Position  := Speed2TrackBarPos(fNetworking.NetGameOptions.SpeedPT);

  TrackBar_SpeedAfterPT.Position  := Speed2TrackBarPos(fNetworking.NetGameOptions.SpeedAfterPT);

  MD := fNetworking.NetGameOptions.MissionDifficulty;

  if MD <> mdNone then
    DropBox_Difficulty.SelectByTag(Byte(MD));

  UpdateGameOptionsUI;
end;


procedure TKMMenuLobby.HostMenuClick(Sender: TObject);
var
  Id: Integer;
begin
  //We can't really do global bans because player's IP addresses change all the time (and we have no other way to identify someone).
  //My idea was for bans to be managed completely by the server, since player's don't actually know each other's IPs.
  //So the host says "please ban client 3257" and the server adds his IP to the ban list for this room. The ban list
  //is then reset when the room becomes empty. Maybe we need to call the button "ban from this lobby" instead.
  //In any way banlist should be editable from within the lobby, so we will need methods to get the list
  //from the server and allow to remove items from it.

  id := fNetworking.NetPlayers.ServerToLocal(TKMControl(Sender).Tag);
  if id = -1 then Exit; //Player has quit the lobby

  //Kick
  if (Sender = Menu_Host) and (Menu_Host.ItemIndex = 0) then
    fNetworking.KickPlayer(id);

  //Ban
  if (Sender = Menu_Host) and (Menu_Host.ItemIndex = 1) then
    fNetworking.BanPlayer(id);

  //Set to host
  if (Sender = Menu_Host) and (Menu_Host.ItemIndex = 2) then
    fNetworking.SetToHost(id);

  // Mute/Unmute
  if (Sender = Menu_Host) and (Menu_Host.ItemIndex = 3) then
    ToggleMutePlayer(id);
end;


procedure TKMMenuLobby.JoinerMenuClick(Sender: TObject);
var id: Integer;
begin
  id := fNetworking.NetPlayers.ServerToLocal(TKMControl(Sender).Tag);
  if id = -1 then Exit; //Player has quit the lobby
  // Mute/Unmute
  if (Sender = Menu_Joiner) and (Menu_Joiner.ItemIndex = 0) then
    ToggleMutePlayer(id);
end;


function TKMMenuLobby.CanShowPlayerMenu(Sender: TObject): Boolean;
var
  ctrl: TKMControl;
begin
  Result := True;
  ctrl := TKMControl(Sender);
  if fLocalToNetPlayers[ctrl.Tag] = -1 then
  begin
    Result := False;
    Exit;
  end;

  //Only human players (excluding ourselves) have the player menu
  if not fNetworking.NetPlayers[fLocalToNetPlayers[ctrl.Tag]].IsHuman //No menu for AI players
  or (fNetworking.MyIndex = fLocalToNetPlayers[ctrl.Tag]) //No menu for ourselves
  or not fNetworking.NetPlayers[fLocalToNetPlayers[ctrl.Tag]].Connected then //Don't show menu for empty slots
  begin
    Result := False;
    Exit;
  end;
end;


procedure TKMMenuLobby.PercentBar_PlayerDl_ChVisibility(aPlayerIndex: Integer; aShow: Boolean);
begin
  if aShow then
  begin
    DropBox_Loc[aPlayerIndex].Hide;
    PercentBar_DownloadProgress[aPlayerIndex].Show;
  end else begin
    DropBox_Loc[aPlayerIndex].Show;
    PercentBar_DownloadProgress[aPlayerIndex].Hide;
  end;
end;


procedure TKMMenuLobby.PlayerMenuShow(Sender: TObject);
var
  ctrl: TKMControl;
begin
  ctrl := TKMControl(Sender);
  if fLocalToNetPlayers[ctrl.Tag] = -1 then Exit;

  if not CanShowPlayerMenu(Sender) then Exit;

  if fNetworking.IsHost then
  begin
    //Remember which player it is by his server index
    //since order of players can change. If someone above leaves we still have the proper Id
    Menu_Host.Tag := fNetworking.NetPlayers[fLocalToNetPlayers[ctrl.Tag]].IndexOnServer;

    UpdateMuteMenuItem(Menu_Host, 3, gGameApp.Networking.IsMuted(fLocalToNetPlayers[ctrl.Tag]));

    //Position the menu next to the icon, but do not overlap players name
    Menu_Host.ShowAt(ctrl.AbsLeft, ctrl.AbsTop + ctrl.Height);
  end else begin
    //Remember which player it is by his server index
    //since order of players can change. If someone above leaves we still have the proper Id
    Menu_Joiner.Tag := fNetworking.NetPlayers[fLocalToNetPlayers[ctrl.Tag]].IndexOnServer;

    UpdateMuteMenuItem(Menu_Joiner, 0, gGameApp.Networking.IsMuted(fLocalToNetPlayers[ctrl.Tag]));
    
    //Position the menu next to the icon, but do not overlap players name
    Menu_Joiner.ShowAt(ctrl.AbsLeft, ctrl.AbsTop + ctrl.Height);
  end;
end;


procedure TKMMenuLobby.ToggleMutePlayer(aPlayerIndex: Integer);
begin
  gGameApp.Networking.ToggleMuted(aPlayerIndex);
  UpdateImageLobbyFlag(fNetPlayersToLocal[aPlayerIndex]);
end;


procedure TKMMenuLobby.UpdateMuteMenuItem(aMenu: TKMPopUpMenu; aItemIndex: Integer; aIsMuted: Boolean);
begin
  if aIsMuted then
    aMenu.UpdateItem(aItemIndex, gResTexts[TX_UNMUTE_PLAYER])
  else
    aMenu.UpdateItem(aItemIndex, gResTexts[TX_MUTE_PLAYER]);
end;


procedure TKMMenuLobby.UpdateImageLobbyFlag(aIndex: Integer);
begin
  // Darken player flag when muted
  if (fLocalToNetPlayers[aIndex] <> -1) and fNetworking.IsMuted(fLocalToNetPlayers[aIndex]) then
    Image_Flag[aIndex].Lightness := -0.66
  else
    Image_Flag[aIndex].Lightness := 0;
end;


function TKMMenuLobby.AISlotsAvailable(aAIPlayerTypes: TKMNetPlayerTypeSet = [AI_PLAYER_TYPE_MIN..AI_PLAYER_TYPE_MAX]): Byte;
var
  OpenedHumansAtAISlots: Byte;
begin
  Result := 0;

  aAIPlayerTypes := aAIPlayerTypes * [AI_PLAYER_TYPE_MIN..AI_PLAYER_TYPE_MAX]; //Restrict with AI player types only

  if (fNetworking.MapInfo <> nil) and fNetworking.MapInfo.IsValid then
  begin
    OpenedHumansAtAISlots := Max(0, fNetworking.MapInfo.CanBeHumanAndAICount - fNetworking.NetPlayers.GetConnectedPlayersCount);
    Result := Max(0, OpenedHumansAtAISlots
                   //+ fNetworking.MapInfo.CanBeOnlyAICount // Only AI is added at the start of the game...
                   - fNetworking.NetPlayers.GetAICount(aAIPlayerTypes));
  end else if (fNetworking.SaveInfo <> nil) and fNetworking.SaveInfo.IsValid then
  begin
    Result := Max(0, fNetworking.SaveInfo.GameInfo.HumanCount
                   - fNetworking.NetPlayers.GetConnectedPlayersCount
                   - fNetworking.NetPlayers.GetAICount(aAIPlayerTypes));
  end;
end;


procedure TKMMenuLobby.DropBoxPlayers_Show(Sender: TObject);
begin
  if Sender is TKMDropColumns then
    fDropBoxPlayers_LastItemIndex := TKMDropColumns(Sender).ItemIndex;
end;


function TKMMenuLobby.DropBoxPlayers_CellClick(Sender: TObject; const X, Y: Integer): Boolean;

  function IsAILine: Boolean;
  begin
    Result := Y in [2,3];
  end;

var
  I, J, NetI: Integer;
  AISlotsToChange, AISlotsChanged: Byte;
  RowChanged: Boolean;
begin
  Result := False;

  //Second column was clicked
  if X = 1 then
  begin
    AISlotsChanged := 0;  //Used to count changed slots while setting ALL to AI
    AISlotsToChange := AISlotsAvailable([TKMNetPlayerType(Y)]); //Luckily row in column box is the same as TKMNetPlayer type (for AI)

    for I := 1 to MAX_LOBBY_SLOTS do
    begin
      if Sender = DropBox_PlayerSlot[I].List then
      begin
        DropBox_PlayerSlot[I].CloseList; //Close opened dropbox manually

        //We have to revert ItemIndex to its previous value, because its value was already switched to AI on MouseDown
        //but we are not sure yet about what value should be there, we will set it properly later on
        if IsAILine and (DropBox_PlayerSlot[I].ItemIndex = Y)
          and (fDropBoxPlayers_LastItemIndex <> -1) then
          DropBox_PlayerSlot[I].ItemIndex := fDropBoxPlayers_LastItemIndex;

        Break;
      end;
    end;

    for I := 1 to MAX_LOBBY_SLOTS do
    begin
      if IsAILine and (AISlotsChanged >= AISlotsToChange) then //Do not add more AI, then we have slots available
        Break;

      case Y of
        0:       J := MAX_LOBBY_SLOTS + 1 - I; // we must Open slots in reverse order
        1, 2, 3: J := I;                       // Closed and AI slots - in straight order
        else     J := I;
      end;

      RowChanged := False;
      NetI := fLocalToNetPlayers[J];
      if (NetI = -1) or not fNetworking.NetPlayers[NetI].IsHuman then
      begin
        if DropBox_PlayerSlot[J].ItemIndex <> Y then //Do not count this slot as changed, if it already has same AI value
        begin
          RowChanged := True;
          Inc(AISlotsChanged);
        end;
        DropBox_PlayerSlot[J].ItemIndex := Y;
        //Do not call for PlayerSetupChange if this row is AIPlayer and did not change (it was AIPlayer before that) - to avoid existing AIPlayer reset
        if RowChanged or not IsAILine then
          PlayersSetupChange(DropBox_PlayerSlot[J]);
      end;
    end;

    // Do not propagate click event further, because
    // we do not want provoke OnChange event handler invokation, we have handled everything here
    Result := True;
  end;
end;


//Try to change players setup, Networking will check if it can be done under current
//conditions immediately and reverts the change without disturbing Host.
//If the change is possible Networking will send query to the Host.
//Host will reply with OnPlayersSetup event and data will be actualized.
procedure TKMMenuLobby.PlayersSetupChange(Sender: TObject);
var
  I, NetI: Integer;
begin
  //Host control toggle
  if Sender = CheckBox_HostControl then
  begin
    fNetworking.NetPlayers.HostDoesSetup := CheckBox_HostControl.Checked;
    fNetworking.SendPlayerListAndRefreshPlayersSetup;
  end;

  if Sender = CheckBox_RandomizeTeamLocations then
  begin
    fNetworking.NetPlayers.RandomizeTeamLocations := CheckBox_RandomizeTeamLocations.Checked;
    fNetworking.SendPlayerListAndRefreshPlayersSetup;
  end;

  if Sender = CheckBox_Spectators then
  begin
    if not CheckBox_Spectators.Checked and (fNetworking.NetPlayers.GetSpectatorCount > 0) then
    begin
      fNetworking.PostLocalMessage(gResTexts[TX_LOBBY_CANNOT_DISABLE_SPECTATORS], csSystem);
      CheckBox_Spectators.Checked := True;
    end
    else
    begin
      fNetworking.NetPlayers.SpectatorsAllowed := CheckBox_Spectators.Checked;
      fNetworking.SendPlayerListAndRefreshPlayersSetup;
    end;
  end;

  for I := 1 to MAX_LOBBY_SLOTS do
  begin
    NetI := fLocalToNetPlayers[I];
    //Starting location
    if (Sender = DropBox_Loc[I]) and DropBox_Loc[I].Enabled then
    begin
      // We can still have cmSpectate chat mode if we were in specs. Reset to cmAll in this case
      if (DropBox_Loc[I].GetSelectedTag <> LOC_SPECTATE) and (gGameApp.Chat.Mode = cmSpectators) then
        ChatMenuSelect(CHAT_MENU_ALL);
      
      fNetworking.SelectLoc(DropBox_Loc[I].GetSelectedTag, NetI);
      //Host with HostDoesSetup could have given us some location we don't know about
      //from a map/save we don't have, so make sure SelectGameKind is valid
      if (fNetworking.SelectGameKind <> ngkNone)
        and not fNetworking.IsHost then //Changes are applied instantly for host
        //Set loc back to NetPlayers value until host processes our request
        DropBox_Loc[I].SelectByTag(fNetworking.NetPlayers[NetI].StartLocation);
    end;

    //Team
    if (Sender = DropBox_Team[I]) and DropBox_Team[I].Enabled then
      fNetworking.SelectTeam(DropBox_Team[I].ItemIndex, NetI);

    //Color
    if (Sender = DropBox_Colors[I]) and DropBox_Colors[I].Enabled then
    begin
      fNetworking.SelectColor(DropBox_Colors[I].ItemIndex, NetI);
      DropBox_Colors[I].ItemIndex := fNetworking.NetPlayers[NetI].FlagColorID;
    end;

    if Sender = DropBox_PlayerSlot[I] then
    begin
      //Modify an existing player
      if (NetI <> -1) and (NetI <= fNetworking.NetPlayers.Count) then
      begin
        case DropBox_PlayerSlot[I].ItemIndex of
          0:  //Open
              begin
                if fNetworking.NetPlayers[NetI].IsComputer
                  or fNetworking.NetPlayers[NetI].IsClosed then
                  fNetworking.NetPlayers.RemPlayer(NetI);
              end;
          1:  //Closed
              fNetworking.NetPlayers.AddClosedPlayer(NetI); //Replace it
          2:  //AI
              fNetworking.NetPlayers.AddAIPlayer(False, NetI); //Replace it
          3:  //Advanced AI
              fNetworking.NetPlayers.AddAIPlayer(True, NetI); //Replace it
        end;
      end
      else
      begin
        if I > MAX_LOBBY_PLAYERS then
        begin
          //These are spectator only slots
          case DropBox_PlayerSlot[I].ItemIndex of
            0: fNetworking.NetPlayers.SpectatorSlotsOpen := MAX_LOBBY_SLOTS - I + 1;
            1: fNetworking.NetPlayers.SpectatorSlotsOpen := MAX_LOBBY_SLOTS - I;
          end;
        end
        else
        begin
          //Add a new player
          case DropBox_PlayerSlot[I].ItemIndex of
            1: fNetworking.NetPlayers.AddClosedPlayer;
            2: fNetworking.NetPlayers.AddAIPlayer(False);
            3: fNetworking.NetPlayers.AddAIPlayer(True);
          end;
        end;
      end;
      DropBox_PlayerSlot[I].CloseList; //We may have cause player list to rearrange
      fNetworking.SendPlayerListAndRefreshPlayersSetup;
    end;
  end;
end;


function TKMMenuLobby.Speed2TrackBarPos(aSpeed: Single): Integer;
begin
  Result := Round((aSpeed - 1) / SPEED_STEP) + 1;
end;


function TKMMenuLobby.TrackBarPos2Speed(aTrackPos: Integer): Single;
begin
  Result := (aTrackPos - 1) * SPEED_STEP + 1
end;


//Players list has been updated
//We should reflect it to UI
procedure TKMMenuLobby.Lobby_OnPlayersSetup(Sender: TObject);

  function ConvertSpeedRange(aSpeedRng: TKMRangeSingle): TKMRangeInt;
  begin
    Result.Min := Speed2TrackBarPos(aSpeedRng.Min);
    Result.Max := Speed2TrackBarPos(aSpeedRng.Max);
  end;

  procedure AddLocation(LocationName: UnicodeString; aIndex, aLocation: Integer);
  begin
    if not fNetworking.CanTakeLocation(fLocalToNetPlayers[aIndex], aLocation, False) then
      LocationName := '[$707070]' + LocationName + '[]';
    DropBox_Loc[aIndex].Add(LocationName, aLocation);
  end;

var
  I,K,ID,LocaleID: Integer;
  MyNik, CanEdit, HostCanEdit, IsSave, IsValid: Boolean;
  CurPlayer: TKMNetPlayerInfo;
  FirstUnused: Boolean;
begin
  UpdateMappings;

  IsSave := fNetworking.SelectGameKind = ngkSave;

  if Radio_MapType.ItemIndex < 4 then //Limit PT for new game
    TrackBar_LobbyPeacetime.Range := fNetworking.NetGameFilter.PeacetimeRng
  else
    TrackBar_LobbyPeacetime.ResetRange; //No limit for saved game

  //Apply speed range filter for all games, even for saves
  TrackBar_SpeedPT.Range := ConvertSpeedRange(fNetworking.NetGameFilter.SpeedRng);
  TrackBar_SpeedAfterPT.Range := ConvertSpeedRange(fNetworking.NetGameFilter.SpeedAfterPTRng);

  UpdateGameOptionsUI;

  FirstUnused := True;
  for I := 1 to MAX_LOBBY_SLOTS do
    if fLocalToNetPlayers[I] = -1 then
    begin
      //This player is unused
      Label_Player[I].Caption := '';
      Image_Flag[I].TexID := 0;
      Label_Player[I].Hide;
      PercentBar_PlayerDl_ChVisibility(I, False);
      DropBox_PlayerSlot[I].Show;
      if I > MAX_LOBBY_PLAYERS then
      begin
        //Spectator slots. Is this one open?
        if MAX_LOBBY_SLOTS - I < fNetworking.NetPlayers.SpectatorSlotsOpen then
        begin
          DropBox_PlayerSlot[I].ItemIndex := 0; //Spectator
          DropBox_PlayerSlot[I].Enabled := fNetworking.IsHost and (MAX_LOBBY_SLOTS - I + 1 = fNetworking.NetPlayers.SpectatorSlotsOpen);
        end
        else
        begin
          DropBox_PlayerSlot[I].ItemIndex := 1; //Closed
          DropBox_PlayerSlot[I].Enabled := fNetworking.IsHost and (MAX_LOBBY_SLOTS - I = fNetworking.NetPlayers.SpectatorSlotsOpen);
        end;
        DropBox_Loc[I].Clear;
        DropBox_Loc[I].Add(gResTexts[TX_LOBBY_SPECTATE], LOC_SPECTATE);

        DropBox_PlayerSlot[I].Visible := fNetworking.NetPlayers.SpectatorsAllowed;
        DropBox_Loc[I].Visible        := fNetworking.NetPlayers.SpectatorsAllowed;
        DropBox_Colors[I].Visible     := fNetworking.NetPlayers.SpectatorsAllowed;
      end
      else
      begin
        DropBox_PlayerSlot[I].ItemIndex := 0; //Open
        //Only host may change player slots, and only the first unused slot may be changed (so there are no gaps in net players list)
        DropBox_PlayerSlot[I].Enabled := fNetworking.IsHost and FirstUnused;
        FirstUnused := False;

        DropBox_Loc[I].Clear;
        if fNetworking.SelectGameKind = ngkSave then
          DropBox_Loc[I].Add(gResTexts[TX_LOBBY_SELECT], LOC_RANDOM)
        else
          DropBox_Loc[I].Add(gResTexts[TX_LOBBY_RANDOM], LOC_RANDOM);
      end;
      DropBox_Loc[I].ItemIndex := 0;
      DropBox_Team[I].ItemIndex := 0;
      DropBox_Colors[I].ItemIndex := 0;
      Image_Ready[I].TexID := 0; //Hidden
      DropBox_Loc[I].Disable;
      DropBox_Team[I].Disable;
      DropBox_Colors[I].Disable;
      DropBox_Team[I].Visible := I <= MAX_LOBBY_PLAYERS;
    end
    else
    begin
      //This player is used
      CurPlayer := fNetworking.NetPlayers[fLocalToNetPlayers[I]];

      DropBox_Team[I].Visible := not CurPlayer.IsSpectator; //Spectators don't get a team
      DropBox_Loc[I].Show;
      DropBox_Colors[I].Show;

      //Flag icon
      if CurPlayer.IsComputer then
        Image_Flag[I].TexID := GetAIPlayerIcon(CurPlayer.PlayerNetType)
      else begin
        LocaleID := gResLocales.IndexByCode(CurPlayer.LangCode);
        if LocaleID <> -1 then
          Image_Flag[I].TexID := gResLocales[LocaleID].FlagSpriteID
        else
          Image_Flag[I].TexID := 0;
      end;

      //Players list
      if fNetworking.IsHost and (not CurPlayer.IsHuman) then
      begin
        Label_Player[I].Hide;
        PercentBar_PlayerDl_ChVisibility(I, False);
        DropBox_PlayerSlot[I].Enable;
        DropBox_PlayerSlot[I].Show;
        Assert(I <= MAX_LOBBY_PLAYERS, 'Spectator slots can''t have AI or closed');
        if CurPlayer.IsClassicComputer then
          DropBox_PlayerSlot[I].ItemIndex := 2 //Classic AI
        else if CurPlayer.IsAdvancedComputer then
          DropBox_PlayerSlot[I].ItemIndex := 3 //Advanced AI
        else
          DropBox_PlayerSlot[I].ItemIndex := 1; //Closed
      end
      else
      begin
        Label_Player[I].Caption := CurPlayer.SlotName;
        if CurPlayer.FlagColorID = 0 then
          Label_Player[I].FontColor := $FFFFFFFF
        else
          Label_Player[I].FontColor := FlagColorToTextColor(CurPlayer.FlagColor);
        Label_Player[I].Show;
        PercentBar_PlayerDl_ChVisibility(I, False);
        DropBox_PlayerSlot[I].Disable;
        DropBox_PlayerSlot[I].Hide;
        DropBox_PlayerSlot[I].ItemIndex := 0; //Open
      end;

      //Starting locations
      //If we can't load the map, don't attempt to show starting locations
      IsValid := False;
      DropBox_Loc[I].Clear;
      case fNetworking.SelectGameKind of
        ngkNone: AddLocation(gResTexts[TX_LOBBY_RANDOM], I, LOC_RANDOM);
        ngkSave: begin
                    IsValid := fNetworking.SaveInfo.IsValid;
                    AddLocation(gResTexts[TX_LOBBY_SELECT], I, LOC_RANDOM);

                    for K := 0 to fNetworking.SaveInfo.GameInfo.PlayerCount - 1 do
                      if fNetworking.SaveInfo.GameInfo.Enabled[K]
                      and (fNetworking.SaveInfo.GameInfo.CanBeHuman[K] or ALLOW_TAKE_AI_PLAYERS) then
                        AddLocation(UnicodeString(fNetworking.SaveInfo.GameInfo.OwnerNikname[K]), I, K+1);
                  end;
        ngkMap:  begin
                    IsValid := fNetworking.MapInfo.IsValid;
                    AddLocation(gResTexts[TX_LOBBY_RANDOM], I, LOC_RANDOM);

                    for K := 0 to fNetworking.MapInfo.LocCount - 1 do
                      //AI-only locations should not be listed for AIs in lobby, since those ones are
                      //automatically added when the game starts (so AI checks CanBeHuman too)
                      if (CurPlayer.IsHuman and (fNetworking.MapInfo.CanBeHuman[K] or ALLOW_TAKE_AI_PLAYERS))
                        or (CurPlayer.IsClassicComputer
                          and fNetworking.MapInfo.CanBeHuman[K]
                          and fNetworking.MapInfo.CanBeAI[K])
                        or (CurPlayer.IsAdvancedComputer
                          and fNetworking.MapInfo.CanBeHuman[K]
                          and fNetworking.MapInfo.CanBeAdvancedAI[K]) then
                        AddLocation(fNetworking.MapInfo.LocationName(K), I, K+1);
                  end;
      end;
      if CurPlayer.IsHuman and fNetworking.NetPlayers.SpectatorsAllowed then
        AddLocation(gResTexts[TX_LOBBY_SPECTATE], I, LOC_SPECTATE);

      if IsValid or CurPlayer.IsSpectator then
        DropBox_Loc[I].SelectByTag(CurPlayer.StartLocation)
      else
        DropBox_Loc[I].ItemIndex := 0;

      //Always show the selected teams, except when the map denies it
      if (fNetworking.SelectGameKind = ngkMap) and fNetworking.MapInfo.TxtInfo.BlockTeamSelection then
        DropBox_Team[I].ItemIndex := 0 //Hide selected teams since they will be overridden
      else
        DropBox_Team[I].ItemIndex := CurPlayer.Team;

      DropBox_Colors[I].ItemIndex := CurPlayer.FlagColorID;

      //Disable colors that are unavailable
      for K := 0 to DropBox_Colors[I].List.RowCount-1 do
        if (K <> CurPlayer.FlagColorID) and (K <> 0)
        and (not fNetworking.NetPlayers.ColorAvailable(K)
             or ((fNetworking.SelectGameKind = ngkSave) and fNetworking.SaveInfo.GameInfo.ColorUsed(K))) then
          DropBox_Colors[I].List.Rows[K].Cells[0].Enabled := False
        else
          DropBox_Colors[I].List.Rows[K].Cells[0].Enabled := True;

      if CurPlayer.IsClosed then
        Image_Ready[I].TexID := 0
      else
        Image_Ready[I].TexID := 32+Byte(CurPlayer.ReadyToStart and CurPlayer.HasMapOrSave);

      MyNik := (fLocalToNetPlayers[I] = fNetworking.MyIndex); //Our index
      //We are allowed to edit if it is our nickname and we are set as NOT ready,
      //or we are the host and this player is an AI
      CanEdit := (MyNik and (fNetworking.IsHost or not fNetworking.NetPlayers.HostDoesSetup) and
                            (fNetworking.IsHost or not CurPlayer.ReadyToStart)) or
                 (fNetworking.IsHost and CurPlayer.IsComputer);
      HostCanEdit := (fNetworking.IsHost and fNetworking.NetPlayers.HostDoesSetup and
                      not CurPlayer.IsClosed);
      DropBox_Loc[I].Enabled := (CanEdit or HostCanEdit);
      //Can't change color or teams in a loaded save (spectators can set color)
      //Can only edit teams for maps (not saves), but the map may deny this
      DropBox_Team[I].Enabled := (CanEdit or HostCanEdit) and not CurPlayer.IsSpectator
                                      and (fNetworking.SelectGameKind = ngkMap)
                                      and not fNetworking.MapInfo.TxtInfo.BlockTeamSelection;
      DropBox_Colors[I].Enabled := (CanEdit or (MyNik and not CurPlayer.ReadyToStart))
                                        and (not IsSave or CurPlayer.IsSpectator);
      if MyNik and not fNetworking.IsHost then
      begin
        if CurPlayer.ReadyToStart then
          Button_Start.Caption := gResTexts[TX_LOBBY_NOT_READY]
        else
          Button_Start.Caption := gResTexts[TX_LOBBY_READY];
      end;
    end;

  // Players flag hightlight, if they are clickable
  for I := 1 to MAX_LOBBY_SLOTS do
    Image_Flag[I].HighlightOnMouseOver := CanShowPlayerMenu(Image_Flag[I]);

  // Darken player flag when muted
  for I := 1 to MAX_LOBBY_SLOTS do
    UpdateImageLobbyFlag(I);

  //If PopUp menu was opened, check if player still connected, otherwise - close PopUp menu
  if Menu_Host.Visible and (fNetworking.NetPlayers.ServerToLocal(Menu_Host.Tag) = -1) then
    Menu_Host.Hide;

  if Menu_Joiner.Visible and (fNetworking.NetPlayers.ServerToLocal(Menu_Joiner.Tag) = -1) then
    Menu_Joiner.Hide;

  //Update the minimap preview with player colors
  for I := 0 to MAX_HANDS - 1 do
  begin
    ID := fNetworking.NetPlayers.StartingLocToLocal(I+1);
    if ID <> -1 then
      fMinimap.HandColors[I] := fNetworking.NetPlayers[ID].FlagColor
    else
      fMinimap.HandColors[I] := $7F000000; //Semi-transparent when not selected
  end;

  //If we have a map selected update the preview
  if (fNetworking.SelectGameKind = ngkMap) and fNetworking.MapInfo.IsValid then
  begin
    fMinimap.Update(not fNetworking.MapInfo.TxtInfo.BlockFullMapPreview);
    MinimapView.SetMinimap(fMinimap);
    for I := 0 to MAX_HANDS - 1 do
    begin
      ID := fNetworking.NetPlayers.StartingLocToLocal(I+1);
      if ID <> -1 then
        fMinimap.HandTeam[I] := fNetworking.NetPlayers[ID].Team
      else
        fMinimap.HandTeam[I] := 0;
    end;
  end;

  //If we are in team chat mode and find ourselves not on a team (player went back to no team), switch back to all
  if (gGameApp.Chat.Mode = cmTeam) and (fNetworking.MyNetPlayer.Team = 0) then
    ChatMenuSelect(CHAT_MENU_ALL);

  //If we are in whisper chat mode and find the player has left, switch back to all
  if gGameApp.Chat.Mode = cmWhisper then
  begin
    if fNetworking.NetPlayers.ServerToLocal(gGameApp.Chat.WhisperRecipient) = -1 then
      ChatMenuSelect(CHAT_MENU_ALL)
    else
      ChatMenuSelect(gGameApp.Chat.WhisperRecipient); //In case that player changed his color
  end;

  CheckBox_HostControl.Checked := fNetworking.NetPlayers.HostDoesSetup;
  CheckBox_RandomizeTeamLocations.Checked := fNetworking.NetPlayers.RandomizeTeamLocations;
  CheckBox_Spectators.Checked := fNetworking.NetPlayers.SpectatorsAllowed;
  if fNetworking.IsHost then
    Button_Start.Enabled := fNetworking.CanStart;

  UpdateSpectatorDivide;
end;


procedure TKMMenuLobby.Lobby_OnPingInfo(Sender: TObject);
var
  I: Integer;
begin
  for I := 1 to MAX_LOBBY_SLOTS do
    if (fNetworking.Connected) and (fLocalToNetPlayers[I] <> -1) and
       (fNetworking.NetPlayers[fLocalToNetPlayers[I]].IsHuman) then
    begin
      Label_Ping[I].Caption := IntToStr(fNetworking.NetPlayers[fLocalToNetPlayers[I]].GetInstantPing);
      Label_Ping[I].FontColor := GetPingColor(fNetworking.NetPlayers[fLocalToNetPlayers[I]].GetInstantPing);
    end
    else
      Label_Ping[I].Caption := '';

  Label_ServerName.Caption := UnicodeString(fNetworking.ServerName) + ' #' + IntToStr(fNetworking.ServerRoom+1) +
                                   '  ' + fNetworking.ServerAddress + ' : ' + IntToStr(fNetworking.ServerPort);
end;


procedure TKMMenuLobby.InitDropColMapsList;
begin
  DropCol_Maps.DropWidth := 460;
  DropCol_Maps.SetColumns(fntOutline,
                          ['', gResTexts[TX_MENU_MAP_TITLE], '#', gResTexts[TX_MENU_MAP_SIZE]],
                          [0, 20, 320, 350],
                          [False, True, True, True]);
end;


procedure TKMMenuLobby.UpdateMapList;
begin
  //Terminate any running scans otherwise they will continue to fill the drop box in the background
  fMapsMP.TerminateScan;
  fSavesMP.TerminateScan;
  DropCol_Maps.Clear; //Clear previous items in case scanning finds no maps/saves
  case Radio_MapType.ItemIndex of
    0,  //Build Map
    1,  //Fight Map
    2,  //Co-op Map
    3:  //Special map Map
        begin
          fMapsMP.Refresh(MapList_ScanUpdate, nil, MapList_ScanComplete);
          DropCol_Maps.DefaultCaption := gResTexts[TX_LOBBY_MAP_SELECT];
          InitDropColMapsList;
        end;
    4:  //Saved Game
        begin
          fSavesMP.Refresh(MapList_ScanUpdate, True);
          DropCol_Maps.DropWidth := 600;
          DropCol_Maps.DefaultCaption := gResTexts[TX_LOBBY_MAP_SELECT_SAVED];
          DropCol_Maps.SetColumns(fntOutline, [gResTexts[TX_MENU_LOAD_FILE], '#', gResTexts[TX_MENU_SAVE_TIME], gResTexts[TX_MENU_LOAD_DATE]], [0, 290, 320, 430]);
        end;
    else
        begin
          DropCol_Maps.DefaultCaption := NO_TEXT;
        end;
  end;
  DropCol_Maps.ItemIndex := -1; //Clear previously selected item
end;


procedure TKMMenuLobby.MapTypeChanged(Sender: TObject);
begin
  UpdateMapList;
  gGameApp.GameSettings.MenuLobbyMapType := Radio_MapType.ItemIndex;
  fNetworking.SelectNoMap('');
end;


//Change starting location
procedure TKMMenuLobby.MinimapLocClick(aValue: Integer);
var
  I: Integer;
  CanEdit: Boolean;
begin
  I := fNetworking.MyIndex;

  CanEdit := ((fNetworking.IsHost or not fNetworking.NetPlayers.HostDoesSetup) and
              (fNetworking.IsHost or not fNetworking.NetPlayers[I].ReadyToStart));

  if CanEdit then
  begin
    fNetworking.SelectLoc(aValue+1, I);
    //Host with HostDoesSetup could have given us some location we don't know about from a map/save we don't have
    if fNetworking.SelectGameKind <> ngkNone then
      DropBox_Loc[fNetPlayersToLocal[I]].SelectByTag(fNetworking.NetPlayers[I].StartLocation);
  end;
end;


procedure TKMMenuLobby.MapList_SortUpdate(Sender: TObject);
begin
  //After sorting jump to the selected item
  if Sender = fSavesMP then
    RefreshSaveList(True);
  if Sender = fMapsMP then
    RefreshMapList(True);
end;


procedure TKMMenuLobby.MapList_ScanUpdate(Sender: TObject);
begin
  //Don't jump to selected with each scan update
  if Sender = fSavesMP then
    RefreshSaveList(False);
  if Sender = fMapsMP then
    RefreshMapList(False);
end;


procedure TKMMenuLobby.MapList_ScanComplete(Sender: TObject);
//var MapsCRCArray: TKMCardinalArray;
//    I: Integer;
begin
//--------//Do not RemoveMissing maps from favourites, as we have only 1 favorites for all maps, including SP maps also//--------//

//  if (Sender = fMapsMP) and (fMapsMP.Count > 0) then
//  begin
//    SetLength(MapsCRCArray, fMapsMP.Count);
//    for I := 0 to fMapsMP.Count - 1 do
//      MapsCRCArray[I] := fMapsMP[I].CRC;
//    gGameApp.GameSettings.FavouriteMaps.RemoveMissing(MapsCRCArray);
//  end;
end;


procedure TKMMenuLobby.WakeUpNotReadyClick(Sender: TObject);
begin
  if GetTimeSince(fLastTimeAskReady) > ASK_READY_COOLDOWN then
  begin
    fNetworking.WakeUpNotReady;
    Button_SettingsAskReady.Disable;
    fLastTimeAskReady := TimeGet;
  end;
end;


procedure TKMMenuLobby.RefreshMapList(aJumpToSelected:Boolean);
  procedure SelectByName(const aName: UnicodeString);
  var I: Integer;
  begin
    for I := 0 to DropCol_Maps.Count - 1 do
      if DropCol_Maps.Item[I].Cells[1].Caption = aName then
      begin
        DropCol_Maps.ItemIndex := I;
        Break;
      end;
  end;
var
  I, PrevTop: Integer;
  PrevMap: string;
  AddMap: Boolean;
  Row: TKMListRow;
begin
  //Remember previous map selected
  if DropCol_Maps.ItemIndex <> -1 then
    PrevMap := DropCol_Maps.Item[DropCol_Maps.ItemIndex].Cells[1].Caption
  else
    PrevMap := '';

  PrevTop := DropCol_Maps.List.TopIndex;
  DropCol_Maps.Clear;

  fMapsMP.Lock;
  try
    for I := 0 to fMapsMP.Count - 1 do
    begin
      //Different modes allow different maps
      case Radio_MapType.ItemIndex of
        0:    AddMap := (fMapsMP[I].MissionMode = mmNormal) and not fMapsMP[I].TxtInfo.IsCoop and not fMapsMP[I].TxtInfo.IsSpecial; //BuildMap
        1:    AddMap := (fMapsMP[I].MissionMode = mmTactic) and not fMapsMP[I].TxtInfo.IsCoop and not fMapsMP[I].TxtInfo.IsSpecial; //FightMap
        2:    AddMap := fMapsMP[I].TxtInfo.IsCoop; //CoopMap
        3:    AddMap := fMapsMP[I].TxtInfo.IsSpecial; //Special map
        else  AddMap := False; //Other cases are already handled in Lobby_MapTypeSelect
      end;

      if AddMap and fNetworking.NetGameFilter.FilterMap(fMapsMP[I].CRC) then
      begin
        Row := MakeListRow(['', fMapsMP[I].FileName, IntToStr(fMapsMP[I].HumanPlayerCountMP), fMapsMP[I].SizeText], //Texts
                           [fMapsMP[I].GetLobbyColor, fMapsMP[I].GetLobbyColor, fMapsMP[I].GetLobbyColor, fMapsMP[I].GetLobbyColor], //Colors
                           I);
        Row.Cells[0].Pic := fMapsMP[I].FavouriteMapPic;
        Row.Cells[0].HighlightOnMouseOver := True;
        DropCol_Maps.Add(Row);
      end;
    end;
  finally
    fMapsMP.Unlock;
  end;

  //Restore previously selected map
  if PrevMap <> '' then
  for I := 0 to DropCol_Maps.Count - 1 do
  if DropCol_Maps.Item[I].Cells[1].Caption = PrevMap then
    DropCol_Maps.ItemIndex := I;

  //Restore the top index
  DropCol_Maps.List.TopIndex := PrevTop;
  if aJumpToSelected and (DropCol_Maps.List.ItemIndex <> -1)
  and not InRange(DropCol_Maps.List.ItemIndex - DropCol_Maps.List.TopIndex, 0, DropCol_Maps.List.GetVisibleRows - 1) then
  begin
    if DropCol_Maps.List.ItemIndex < DropCol_Maps.List.TopIndex + DropCol_Maps.List.GetVisibleRows - 1 then
      DropCol_Maps.List.TopIndex := DropCol_Maps.List.ItemIndex
    else
    if DropCol_Maps.List.ItemIndex > DropCol_Maps.List.TopIndex + DropCol_Maps.List.GetVisibleRows - 1 then
      DropCol_Maps.List.TopIndex := DropCol_Maps.List.ItemIndex - DropCol_Maps.List.GetVisibleRows + 1;
  end;

  //After being reassigned to host we may need to reselect the map
  if (DropCol_Maps.ItemIndex = -1) and (fNetworking.SelectGameKind = ngkMap) then
    SelectByName(fNetworking.MapInfo.FileName);
end;


procedure TKMMenuLobby.RefreshSaveList(aJumpToSelected: Boolean);
  procedure SelectByName(const aName: UnicodeString);
  var I: Integer;
  begin
    for I := 0 to DropCol_Maps.Count - 1 do
      if DropCol_Maps.Item[I].Cells[0].Caption = aName then
      begin
        DropCol_Maps.ItemIndex := I;
        Break;
      end;
  end;
var
  I, PrevTop: Integer;
  PrevSave: string;
begin
  //Remember previous save selected
  if DropCol_Maps.ItemIndex <> -1 then
    PrevSave := DropCol_Maps.Item[DropCol_Maps.ItemIndex].Cells[0].Caption
  else
    PrevSave := '';

  PrevTop := DropCol_Maps.List.TopIndex;

  DropCol_Maps.Clear;

  fSavesMP.Lock;
  try
    for I := 0 to fSavesMP.Count - 1 do
    if fSavesMP[I].IsValid then
      DropCol_Maps.Add(MakeListRow([fSavesMP[I].FileName,
                                         IntToStr(fSavesMP[I].GameInfo.PlayerCount),
                                         fSavesMP[I].GameInfo.GetTimeText,
                                         fSavesMP[I].GameInfo.GetSaveTimestamp], I))
    else
      DropCol_Maps.Add(MakeListRow([fSavesMP[I].FileName, '', '', ''], I));

    //Restore previously selected save
    if PrevSave <> '' then
    for I := 0 to DropCol_Maps.Count - 1 do
    if DropCol_Maps.Item[I].Cells[0].Caption = PrevSave then
      DropCol_Maps.ItemIndex := I;
  finally
    fSavesMP.Unlock;
  end;

  //Restore the top index
  DropCol_Maps.List.TopIndex := PrevTop;
  if aJumpToSelected and (DropCol_Maps.List.ItemIndex <> -1)
  and not InRange(DropCol_Maps.List.ItemIndex - DropCol_Maps.List.TopIndex, 0, DropCol_Maps.List.GetVisibleRows - 1) then
  begin
    if DropCol_Maps.List.ItemIndex < DropCol_Maps.List.TopIndex + DropCol_Maps.List.GetVisibleRows - 1 then
      DropCol_Maps.List.TopIndex := DropCol_Maps.List.ItemIndex
    else
    if DropCol_Maps.List.ItemIndex > DropCol_Maps.List.TopIndex + DropCol_Maps.List.GetVisibleRows - 1 then
      DropCol_Maps.List.TopIndex := DropCol_Maps.List.ItemIndex - DropCol_Maps.List.GetVisibleRows + 1;
  end;

  //After being reassigned to host we may need to reselect the save
  if (DropCol_Maps.ItemIndex = -1) and (fNetworking.SelectGameKind = ngkSave) then
    SelectByName(fNetworking.SaveInfo.FileName);
end;


procedure TKMMenuLobby.MapList_OnShow(Sender: TObject);
begin
  if fMapsSortUpdateNeeded then
  begin
    //Update sort
    if Radio_MapType.ItemIndex < 4 then
      fMapsMP.Sort(fMapsMP.SortMethod, MapList_SortUpdate)
    else
      fSavesMP.Sort(fSavesMP.SortMethod, MapList_SortUpdate);
    fMapsSortUpdateNeeded := False;
  end;
end;


procedure TKMMenuLobby.MapColumnClick(aValue: Integer);
var
  SM: TKMapsSortMethod;
  SSM: TKMSavesSortMethod;
begin
  if Radio_MapType.ItemIndex < 4 then
  begin
    //Determine Sort method depending on which column user clicked
    with DropCol_Maps.List do
    case SortIndex of
      0:  if SortDirection = sdDown then
            SM := smByFavouriteDesc
          else
            SM := smByFavouriteAsc;
      1:  if SortDirection = sdDown then
            SM := smByNameDesc
          else
            SM := smByNameAsc;
      2:  if SortDirection = sdDown then
            SM := smByHumanPlayersMPDesc
          else
            SM := smByHumanPlayersMPAsc;
      3:  if SortDirection = sdDown then
            SM := smBySizeDesc
          else
            SM := smBySizeAsc;
      else SM := smByNameAsc;
    end;
    fMapsMP.Sort(SM, MapList_SortUpdate);
  end
  else
  begin
    //Determine Sort method depending on which column user clicked
    with DropCol_Maps.List do
    case SortIndex of
      0:  if SortDirection = sdDown then
            SSM := smByFileNameDesc
          else
            SSM := smByFileNameAsc;
      1:  if SortDirection = sdDown then
            SSM := smByPlayerCountDesc
          else
            SSM := smByPlayerCountAsc;
      2:  if SortDirection = sdDown then
            SSM := smByTimeDesc
          else
            SSM := smByTimeAsc;
      3:  if SortDirection = sdDown then
            SSM := smByDateDesc
          else
            SSM := smByDateAsc;
      else SSM := smByFileNameAsc;
    end;
    fSavesMP.Sort(SSM, MapList_SortUpdate);
  end;
end;


function TKMMenuLobby.DropBoxMaps_CellClick(Sender: TObject; const X, Y: Integer): Boolean;
var I: Integer;
begin
  Result := False;
  if (Radio_MapType.ItemIndex < 4) and (X = 0) then
  begin
    I := DropCol_Maps.Item[Y].Tag;
    fMapsMP.Lock;
    try
      fMapsMP[I].IsFavourite := not fMapsMP[I].IsFavourite;
      if fMapsMP[I].IsFavourite then
        gGameApp.GameSettings.FavouriteMaps.Add(fMapsMP[I].CRC)
      else
        gGameApp.GameSettings.FavouriteMaps.Remove(fMapsMP[I].CRC);

      //Update pic
      DropCol_Maps.Item[Y].Cells[0].Pic := fMapsMP[I].FavouriteMapPic;
      fMapsSortUpdateNeeded := True; //Ask for resort on next list show
    finally
      fMapsMP.Unlock;
    end;
    Result := True; //we handle mouse click here, and do not want to propagate it further
  end;
end;


//Just pass FileName to Networking, it will check validity itself
procedure TKMMenuLobby.MapChange(Sender: TObject);
var I: Integer;
begin
  I := DropCol_Maps.Item[DropCol_Maps.ItemIndex].Tag;
  if Radio_MapType.ItemIndex < 4 then
  begin
    fMapsMP.Lock;
    try
      fNetworking.SelectMap(fMapsMP[I].FileName, fMapsMP[I].MapFolder);
    finally
      fMapsMP.Unlock;
    end;
    GameOptionsChange(nil); //Need to update GameOptions, since we could get new MissionDifficulty
  end
  else
  begin
    fSavesMP.Lock;
    try
      fNetworking.SelectSave(fSavesMP[I].FileName);
    finally
      fSavesMP.Unlock;
    end;
  end;
end;


procedure TKMMenuLobby.Lobby_OnUpdateMinimap(Sender: TObject);
var
  S: TKMSaveInfo;
begin
  S := fNetworking.SaveInfo;
  if fNetworking.IsSave then
  begin
    if S.IsValid
      and (fNetworking.MyIndex > 0)
      and S.LoadMinimap(fMinimap, fNetworking.MyNetPlayer.StartLocation) then
    begin
      MinimapView.SetMinimap(fMinimap);
      MinimapView.Show;
    end else
      MinimapView.Hide;
  end;
end;


procedure TKMMenuLobby.UpdateDifficultyLevels(aSave: TKMSaveInfo);
var
  MD: TKMMissionDifficulty;
begin
  //Difficulty levels
  DropBox_Difficulty.Clear;
  DropBox_Difficulty.Disable;
  MD := aSave.GameInfo.MissionDifficulty;
  if MD = mdNone then
    Panel_Difficulty.Hide
  else
  begin
    DropBox_Difficulty.Add(gResTexts[DIFFICULTY_LEVELS_TX[MD]], Byte(MD));
    DropBox_Difficulty.ItemIndex := 0; //Select level from save

    Panel_Difficulty.DoSetVisible;
  end;

  UpdateDescNOptionsUI;
end;


procedure TKMMenuLobby.UpdateDifficultyLevels(aMap: TKMapInfo);
var
  I: Integer;
  MD, OldMD, DefMD: TKMMissionDifficulty;
begin
  //Difficulty levels
  if aMap.TxtInfo.HasDifficultyLevels then
  begin
    OldMD := mdNone;
    if DropBox_Difficulty.IsSelected
      and (TKMMissionDifficulty(DropBox_Difficulty.GetSelectedTag) in aMap.TxtInfo.DifficultyLevels) then
      OldMD := TKMMissionDifficulty(DropBox_Difficulty.GetSelectedTag);

    DropBox_Difficulty.Clear;
    I := 0;

    if OldMD <> mdNone then
      DefMD := OldMD     //Try to set value from previously selected map
    else
      DefMD := mdNormal; //Default diffiuculty is "Normal"

    for MD in aMap.TxtInfo.DifficultyLevels do
    begin
      DropBox_Difficulty.Add(gResTexts[DIFFICULTY_LEVELS_TX[MD]], Byte(MD));
      if MD = DefMD then
        DropBox_Difficulty.ItemIndex := I;

      Inc(I);
    end;

    if not DropBox_Difficulty.IsSelected then
      DropBox_Difficulty.ItemIndex := 0;

    Panel_Difficulty.DoSetVisible;
    DropBox_Difficulty.Enabled := fNetworking.IsHost; //Only Host can change map difficulty

  end else
    Panel_Difficulty.Hide;

  UpdateDescNOptionsUI;
end;


//We have received MapName
//Update UI to show it
procedure TKMMenuLobby.Lobby_OnMapName(const aData: UnicodeString);
var
  M: TKMapInfo;
  S: TKMSaveInfo;
begin
  //Common settings
  MinimapView.Visible := (fNetworking.SelectGameKind = ngkMap) and fNetworking.MapInfo.IsValid;
  TrackBar_LobbyPeacetime.Enabled := fNetworking.IsHost
                                     and (fNetworking.SelectGameKind = ngkMap) and fNetworking.MapInfo.IsValid
                                     and not fNetworking.MapInfo.TxtInfo.BlockPeacetime;
  TrackBar_SpeedPT.Enabled := (TrackBar_LobbyPeacetime.Position > 0) and fNetworking.IsHost
                                    and (((fNetworking.SelectGameKind = ngkMap) and fNetworking.MapInfo.IsValid)
                                      or ((fNetworking.SelectGameKind = ngkSave) and fNetworking.SaveInfo.IsValid));
  TrackBar_SpeedAfterPT.Enabled := fNetworking.IsHost
                                        and (((fNetworking.SelectGameKind = ngkMap) and fNetworking.MapInfo.IsValid)
                                          or ((fNetworking.SelectGameKind = ngkSave) and fNetworking.SaveInfo.IsValid));
  CheckBox_RandomizeTeamLocations.Enabled := fNetworking.IsHost and (fNetworking.SelectGameKind <> ngkSave);

  DropBox_Difficulty.Enabled := fNetworking.IsHost and (fNetworking.SelectGameKind = ngkMap) and fNetworking.MapInfo.IsValid;

  //In case it was hidden during file transfer
  Panel_SetupTransfer.Hide;
  Panel_SetupMinimap.Show;

  //Don't reset the selection if no map is selected
  if ((fNetworking.SelectGameKind = ngkMap) and fNetworking.MapInfo.IsValid)
  or ((fNetworking.SelectGameKind = ngkSave) and fNetworking.SaveInfo.IsValid) then
    Radio_MapType.ItemIndex := DetectMapType;

  Memo_MapDesc.Height := Panel_SetupDesc.Height;
  Button_SetupReadme.Hide;

  case fNetworking.SelectGameKind of
    ngkNone: begin
                Memo_MapDesc.Clear;
                if aData = '' then
                  Label_MapName.Caption := gResTexts[TX_LOBBY_MAP_NONE]
                else
                begin
                  Memo_MapDesc.Add(aData);
                  Label_MapName.Caption := aData; //Some error message
                end;
              end;
    ngkSave: begin
                S := fNetworking.SaveInfo;
                Label_MapName.Caption := aData; //Show save name on host (local is always "downloaded")
                Memo_MapDesc.Text := S.GameInfo.GetTitleWithTime + '|' + S.GameInfo.GetSaveTimestamp;
                Lobby_OnUpdateMinimap(nil);
                UpdateDifficultyLevels(S);
              end;
    ngkMap:  begin
                M := fNetworking.MapInfo;

                //Only load the minimap preview if the map is valid
                if M.IsValid then
                begin
                  fMinimap.LoadFromMission(M.FullPath('.dat'), M.HumanUsableLocs);
                  fMinimap.Update(not M.TxtInfo.BlockFullMapPreview);
                  MinimapView.SetMinimap(fMinimap);

                  if not TrackBar_LobbyPeacetime.Enabled and fNetworking.IsHost then
                  begin
                    TrackBar_LobbyPeacetime.Position := 0; //No peacetime in coop (trackbar gets disabled above)
                    GameOptionsChange(nil); //Send it to other clients
                  end;

                  if M.HasReadme then
                  begin
                    Memo_MapDesc.Height := Panel_SetupDesc.Height - 25;
                    Button_SetupReadme.Show;
                  end;

                  UpdateDifficultyLevels(M);
                end;
                Label_MapName.Caption := WrapColor(M.FileName, M.GetLobbyColor);
                Memo_MapDesc.Text := M.BigDesc;
            end;
  end;
end;


procedure TKMMenuLobby.Lobby_OnMapMissing(const aData: UnicodeString; aStartTransfer: Boolean);
begin
  //Common settings
  MinimapView.Visible := (fNetworking.SelectGameKind = ngkMap) and fNetworking.MapInfo.IsValid;
  TrackBar_LobbyPeacetime.Enabled := fNetworking.IsHost and (fNetworking.SelectGameKind = ngkMap)
                                     and fNetworking.MapInfo.IsValid and not fNetworking.MapInfo.TxtInfo.BlockPeacetime;
  TrackBar_SpeedPT.Enabled := (TrackBar_LobbyPeacetime.Position > 0) and fNetworking.IsHost
                               and (fNetworking.SelectGameKind = ngkMap) and fNetworking.MapInfo.IsValid;
  TrackBar_SpeedAfterPT.Enabled := fNetworking.IsHost and (fNetworking.SelectGameKind = ngkMap) and fNetworking.MapInfo.IsValid;
  CheckBox_RandomizeTeamLocations.Enabled := fNetworking.IsHost and (fNetworking.SelectGameKind <> ngkSave);

  DropBox_Difficulty.Enabled := fNetworking.IsHost and (fNetworking.SelectGameKind = ngkMap) and fNetworking.MapInfo.IsValid;

  Label_MapName.Caption := fNetworking.MissingFileName;
  Memo_MapDesc.Text := aData; //aData is some error message
  if fNetworking.MissingFileType = ngkSave then
    Radio_MapType.ItemIndex := 4
  else
    Radio_MapType.ItemIndex := 0;
  Panel_SetupMinimap.Hide;
  Panel_SetupTransfer.Show;
  Button_SetupDownload.Show;
  Lobby_OnFileTransferProgress(0, 0); //Reset progress bar
  if aStartTransfer then
    FileDownloadClick(Button_SetupDownload);
end;


//We have been assigned to be the host of the game because the host disconnected. Reopen lobby page in correct mode.
procedure TKMMenuLobby.Lobby_OnReassignedToHost(Sender: TObject);
begin
  Reset(lpkHost, True); //Will reset the lobby page into host mode, preserving messages/maps

  //Pick correct position of map type selector
  Radio_MapType.ItemIndex := DetectMapType;

  UpdateMapList;
  Lobby_OnGameOptions(nil);

  case fNetworking.SelectGameKind of
    ngkMap:  Lobby_OnMapName(fNetworking.MapInfo.FileName);
    ngkSave: Lobby_OnMapName(fNetworking.SaveInfo.FileName);
  end;
end;


procedure TKMMenuLobby.Lobby_OnReassignedToJoiner(Sender: TObject);
begin
  Reset(lpkJoiner, True); //Will reset the lobby page into host mode, preserving messages/maps

  //Pick correct position of map type selector
  Radio_MapType.ItemIndex := DetectMapType;
end;


procedure TKMMenuLobby.HandleError(const aMsg: UnicodeString);
begin
  fNetworking.PostLocalMessage(aMsg, csSystem);
end;


procedure TKMMenuLobby.PostLocalMsg(const aMsg: UnicodeString);
begin
  fNetworking.PostLocalMessage(aMsg, csChat);
end;


procedure TKMMenuLobby.PostMsg(const aMsg: UnicodeString);
begin
  if gGameApp.Chat.Mode = cmWhisper then
    fNetworking.PostChat(aMsg, gGameApp.Chat.Mode, gGameApp.Chat.WhisperRecipient)
  else
    fNetworking.PostChat(aMsg, gGameApp.Chat.Mode);
end;


function TKMMenuLobby.IsKeyEvent_Return_Handled(Sender: TObject; Key: Word): Boolean;
begin
  Result := Key in [VK_RETURN, VK_UP, VK_DOWN];
end;


function TKMMenuLobby.PostKeyDown(Sender: TObject; Key: Word; Shift: TShiftState): Boolean;
var
  Str: String;
begin
  Result := False;
  if IsKeyEvent_Return_Handled(Self, Key) then
  begin
    case Key of
      VK_RETURN:  Result := DoPost;
      VK_UP:      begin
                    Str := gGameApp.Chat.GetNextHistoryMsg;
                    if Str <> '' then
                    begin
                      Edit_Post.Text := Str;
                      Result := True;
                    end;
                  end;
      VK_DOWN:    begin
                    Str := gGameApp.Chat.GetPrevHistoryMsg;
                    if Str <> '' then
                    begin
                      Edit_Post.Text := Str;
                      Result := True;
                    end;
                  end;
    end;
  end;
end;


//Post what user has typed
function TKMMenuLobby.DoPost: Boolean;
var
  RecipientNetIndex: Integer;
begin
  Result := False;
  if not gGameApp.Chat.IsPostAllowed then
    Exit;

  //Console commands are disabled for now, maybe we'll reuse them later
  //Check for console commands
  {if (Length(ChatMessage) > 1) and (ChatMessage[1] = '/')
  and (ChatMessage[2] <> '/') then //double slash is the escape to place a slash at the start of a sentence
    fNetworking.ConsoleCommand(ChatMessage)
  else
  begin
    if (Length(ChatMessage) > 1) and (ChatMessage[1] = '/') and (ChatMessage[2] = '/') then
      Delete(ChatMessage, 1, 1); //Remove one of the /'s
  end;}

  if gGameApp.Chat.Mode = cmWhisper then
  begin
    RecipientNetIndex := fNetworking.NetPlayers.ServerToLocal(gGameApp.Chat.WhisperRecipient);
    if not fNetworking.NetPlayers[RecipientNetIndex].Connected
      or fNetworking.NetPlayers[RecipientNetIndex].Dropped then
    begin
      fNetworking.PostLocalMessage(Format(gResTexts[TX_MULTIPLAYER_CHAT_PLAYER_NOT_CONNECTED_ANYMORE],
                                          [fNetworking.NetPlayers[RecipientNetIndex].NiknameColored]),
                                    csSystem);
      ChatMenuSelect(CHAT_MENU_ALL);
    end else
      gGameApp.Chat.Post
  end else
    gGameApp.Chat.Post;
  Result := True;
  Edit_Post.Text := '';
end;


procedure TKMMenuLobby.Lobby_OnMessage(const aText: UnicodeString);
begin
  if (gGameApp <> nil) and (gGameApp.GameSettings <> nil) then
  begin
    if gGameApp.GameSettings.FlashOnMessage then
      gMain.FlashingStart;

    gGameApp.Chat.AddLine(aText);
  end;
end;


//We were disconnected from Server. Either we were kicked, or connection broke down
procedure TKMMenuLobby.Lobby_OnDisconnect(const aData: UnicodeString);
begin
  fNetworking.Disconnect;
  gSoundPlayer.Play(sfxnError);

  fOnPageChange(gpMultiplayer, aData);
end;


procedure TKMMenuLobby.Lobby_OnFileTransferProgress(aTotal, aProgress: Cardinal);
begin
  if aTotal = 0 then
  begin
    PercentBar_SetupProgress.Hide;
    PercentBar_SetupProgress.SetCaptions('', gResTexts[TX_LOBBY_DOWNLOADING], '');
  end else begin
    PercentBar_SetupProgress.Show;
    PercentBar_SetupProgress.Position := aProgress / aTotal;
    PercentBar_SetupProgress.SetCaptions(IntToStr(aProgress div 1024) + 'kb ', '/', ' ' + IntToStr(aTotal div 1024) + 'kb');
  end;
end;


procedure TKMMenuLobby.Lobby_OnPlayerFileTransferProgress(aNetPlayerIndex: Integer; aTotal, aProgress: Cardinal);
var
  Row: Integer;
begin
  Row := fNetPlayersToLocal[aNetPlayerIndex];
  if (aProgress >= aTotal) or (aTotal = 0) then
  begin
    PercentBar_DownloadProgress[Row].Position := 0;
    PercentBar_DownloadProgress[Row].SetCaptions('', gResTexts[TX_LOBBY_DOWNLOADING], '');
    PercentBar_PlayerDl_ChVisibility(Row, False);
  end else begin
    PercentBar_DownloadProgress[Row].Position := aProgress / aTotal;
    PercentBar_DownloadProgress[Row].SetCaptions(IntToStr(aProgress div 1024) + 'kb ', '/', ' ' + IntToStr(aTotal div 1024) + 'kb');
    PercentBar_PlayerDl_ChVisibility(Row, True);
  end;
end;


procedure TKMMenuLobby.Lobby_OnSetPassword(const aPassword: AnsiString);
begin
  Image_PasswordLock.Visible := aPassword <> '';
end;


procedure TKMMenuLobby.StartBtnChangeEnabled(Sender: TObject; aEnable: Boolean);
begin
  Button_SettingsAskReady.Enabled := (((fNetworking.MapInfo <> nil) and fNetworking.MapInfo.IsValid)
                                        or ((fNetworking.SaveInfo <> nil) and fNetworking.SaveInfo.IsValid))
                                     and not fNetworking.NetPlayers.AllReady;
end;


procedure TKMMenuLobby.StartClick(Sender: TObject);
begin
  if fNetworking.IsHost then
    fNetworking.StartClick
  else
  begin
    if fNetworking.ReadyToStart then
      Button_Start.Caption := gResTexts[TX_LOBBY_NOT_READY]
    else
      Button_Start.Caption := gResTexts[TX_LOBBY_READY];
  end;
end;


procedure TKMMenuLobby.SettingsClick(Sender: TObject);
begin
  if Sender = Button_ChangeSettings then
  begin
    Edit_Description.Text := fNetworking.Description;
    Edit_Password.Text := UnicodeString(fNetworking.Password);
    Panel_Settings.Show;
  end;

  if Sender = Button_SettingsResetBans then
  begin
    if GetTimeSince(fLastTimeResetBans) > RESET_BANS_COOLDOWN then
    begin
      fNetworking.ResetBans;
      Button_SettingsResetBans.Disable;
      fLastTimeResetBans := TimeGet;
    end;
  end;

  if Sender = Button_SettingsUseLastPassword then
    Edit_Password.Text := gGameApp.GameSettings.LastPassword;

  if Sender = Button_SettingsCancel then
  begin
    Panel_Settings.Hide;
  end;

  if Sender = Button_SettingsSave then
  begin
    Panel_Settings.Hide;
    fNetworking.Description := Edit_Description.Text;
    fNetworking.SetPassword(AnsiString(Edit_Password.Text));
    if Checkbox_RememberPassword.Checked then
      gGameApp.GameSettings.LastPassword := UnicodeString(fNetworking.Password);
  end;
end;


procedure TKMMenuLobby.ReturnToLobby(const aSaveName: UnicodeString);
begin
  Radio_MapType.ItemIndex := 4; //Save
  UpdateMapList;
  Lobby_OnGameOptions(nil);
  if fNetworking.IsHost then
  begin
    fNetworking.SelectSave(aSaveName);
    //Make sure the save was successfully selected
    Radio_MapType.ItemIndex := DetectMapType;
    if fNetworking.SelectGameKind = ngkSave then
      Lobby_OnMapName(aSaveName);
  end;
end;


//Should update anything we want to be updated, obviously
procedure TKMMenuLobby.UpdateState;
begin
  if fMapsMP <> nil then fMapsMP.UpdateState;
  if fSavesMP <> nil then fSavesMP.UpdateState;

  if (fLastTimeResetBans <> 0) and (GetTimeSince(fLastTimeResetBans) > RESET_BANS_COOLDOWN) then
  begin
    Button_SettingsResetBans.Enable;
    fLastTimeResetBans := 0;
  end;

  if (fLastTimeAskReady <> 0) and (GetTimeSince(fLastTimeAskReady) > ASK_READY_COOLDOWN) then
  begin
    StartBtnChangeEnabled(Button_Start, Button_Start.Enabled);
    fLastTimeAskReady := 0;
  end;
end;


end.
