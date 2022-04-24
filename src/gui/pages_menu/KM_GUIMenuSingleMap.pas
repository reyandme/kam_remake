unit KM_GUIMenuSingleMap;
{$I KaM_Remake.inc}
interface
uses
  Math, SysUtils,
  KM_Defaults,
  KM_Maps, KM_MapTypes, KM_GameTypes,
  KM_Controls, KM_ControlsBase, KM_ControlsDrop, KM_ControlsList, KM_ControlsMemo, KM_ControlsMinimapView, KM_ControlsSwitch,
  KM_Pics, KM_InterfaceDefaults, KM_InterfaceTypes, KM_MinimapMission, KM_CommonTypes;


const
  MAX_UI_GOALS = 7;


type
  TKMMenuSingleMap = class(TKMMenuPageCommon)
  private
    fOnPageChange: TKMMenuChangeEventText;

    fMaps: TKMapsCollection;
    fMinimap: TKMMinimapMission;

    fLastMapCRC: Cardinal; //CRC of selected map

    fUpdatedLastListId: Integer;  // item id, on which last time update was invoked. Avoid multiple updates for same item, which could happen on every ListRefresh
    fScanCompleted: Boolean;      // True, after scan was completed

    fSingleLoc: Integer;
    fSingleColor: Cardinal;

    fDifficulty: TKMMissionDifficulty;
    fAIType: TKMAIType;

    fLastColIndex: Integer; // Last index of color DropBox

    function GetPlayerLoc(aMap: TKMMapInfo): TKMHandID;
    function GetPanelHalf: Integer;

    procedure Create_SingleMap(aParent: TKMPanel);
    procedure MapTypeChanged(Sender: TObject);

    procedure ScanUpdate(Sender: TObject);
    procedure SortUpdate(Sender: TObject);
    procedure ScanTerminate(Sender: TObject);
    procedure ListUpdate;
    procedure ListRefresh(aJumpToSelected: Boolean);
    procedure ListClick(Sender: TObject);
    procedure DoOptionsChange(aForceUpdate: Boolean = False);
    procedure OptionsChange(Sender: TObject);
    procedure Update(aForceUpdate: Boolean = False);
    procedure ResetUI;
    procedure ResetExtraInfo;
    procedure UpdateDropBoxes;

    procedure StartClick(Sender: TObject);
    procedure ListSort(aColumn: Integer);
    procedure MinimapLocClick(aValue: Integer);
    procedure ReadmeClick(Sender: TObject);

    procedure BackClick(Sender: TObject);
  protected
    Panel_Single: TKMPanel;
      Label_MapType: TKMLabel;
      Radio_MapType: TKMRadioGroup;
      Panel_Desc: TKMPanel;
        Label_Title: TKMLabel;
        Memo_Desc: TKMMemo;
        MinimapView: TKMMinimapView;
        DropBox_Loc: TKMDropList;
        DropBox_Color: TKMDropColumns;
        Label_Difficulty: TKMLabel;
        DropBox_Difficulty: TKMDropList;
        Label_AIPlayerType: TKMLabel;
        DropBox_AIPlayerType: TKMDropList;
        Image_Allies: array [0..MAX_HANDS-1] of TKMImage;
        Image_Enemies: array [0..MAX_HANDS-1] of TKMImage;
        Panel_VictGoal: array [0..MAX_UI_GOALS-1] of TKMPanel;
          Bevel_VictGoal: array [0..MAX_UI_GOALS-1] of TKMBevel;
          Image_VictGoal: array [0..MAX_UI_GOALS-1] of TKMImage;
          Label_VictGoal: array [0..MAX_UI_GOALS-1] of TKMLabel;
          Image_VictGoalSt: array [0..MAX_UI_GOALS-1] of TKMImage;
        Panel_SurvGoal: array [0..MAX_UI_GOALS-1] of TKMPanel;
          Bevel_SurvGoal: array [0..MAX_UI_GOALS-1] of TKMBevel;
          Image_SurvGoal: array [0..MAX_UI_GOALS-1] of TKMImage;
          Label_SurvGoal: array [0..MAX_UI_GOALS-1] of TKMLabel;
          Image_SurvGoalSt: array [0..MAX_UI_GOALS-1] of TKMImage;
      ColumnBox_Maps: TKMColumnBox;
      Button_Back, Button_Start: TKMButton;
      Button_SetupReadme: TKMButton;
  public
    OnNewSingleMap: TKMNewSingleMapEvent;

    constructor Create(aParent: TKMPanel; aOnPageChange: TKMMenuChangeEventText);
    destructor Destroy; override;

    procedure Show;
    procedure UpdateState;
  end;


implementation
uses
  KM_ResTexts, KM_ResFonts, KM_ResTypes,
  KM_CommonUtils, KM_RenderUI, KM_GameSettings,
  KM_MapUtils, KM_MapUtilsExt;

const
  PAD_VERT = 44; //Padding from top/bottom
  PAD_SIDE = 40; //Padding from sides
  BUTTON_DIST = 6;
  FLAG_W = 22;


{ TKMGUIMenuSingleMap }
constructor TKMMenuSingleMap.Create(aParent: TKMPanel; aOnPageChange: TKMMenuChangeEventText);
begin
  inherited Create(gpSingleMap);

  fOnPageChange := aOnPageChange;
  OnEscKeyDown := BackClick;

  fMaps := TKMapsCollection.Create([mkSP, mkMP, mkDL]);
  fMinimap := TKMMinimapMission.Create(True);

  Create_SingleMap(aParent);
end;


destructor TKMMenuSingleMap.Destroy;
begin
  fMaps.Free;
  fMinimap.Free;

  inherited;
end;


procedure TKMMenuSingleMap.MapTypeChanged(Sender: TObject);
begin
  ResetUI;
  ListUpdate;
  ListRefresh(True);
  Update;
  gGameSettings.MenuMapSPType := Radio_MapType.ItemIndex;
end;


function TKMMenuSingleMap.GetPlayerLoc(aMap: TKMMapInfo): TKMHandID;
begin
  Result := IfThen(fSingleLoc = -1, aMap.DefaultHuman, fSingleLoc);
end;


function TKMMenuSingleMap.GetPanelHalf: Integer;
begin
  Result := (Panel_Single.Width - PAD_SIDE) div 2 - PAD_SIDE;
end;


procedure TKMMenuSingleMap.Create_SingleMap(aParent: TKMPanel);
var
  I: Integer;
  half, descL, buttonW: Word; //Half width for panes
  L: TKMLabel;
  B: TKMBevel;
  backCol: TKMColor4f;
begin
  Panel_Single := TKMPanel.Create(aParent, 0, 0, aParent.Width, aParent.Height);
  Panel_Single.AnchorsStretch;

    half := GetPanelHalf;

    TKMBevel.Create(Panel_Single, (aParent.Width + PAD_SIDE) div 2, PAD_VERT + 20, half, 70);

    Label_MapType := TKMLabel.Create(Panel_Single, (aParent.Width + PAD_SIDE) div 2 + 5, PAD_VERT, gResTexts[TX_MENU_MAP_TYPE], fntOutline, taLeft);

    Radio_MapType := TKMRadioGroup.Create(Panel_Single, (aParent.Width + PAD_SIDE) div 2 + 5, PAD_VERT + 25, half - 10, 60, fntMetal);
    Radio_MapType.Add(gResTexts[TX_MENU_SP_MAP_SCENARIO]);
    Radio_MapType.Add(gResTexts[TX_LOBBY_MAP_BUILD]);
    Radio_MapType.Add(gResTexts[TX_LOBBY_MAP_FIGHT]);
    Radio_MapType.Add(gResTexts[TX_LOBBY_MAP_SPECIAL]);
    Radio_MapType.ItemIndex := 0;
    Radio_MapType.OnChange := MapTypeChanged;

    ColumnBox_Maps := TKMColumnBox.Create(Panel_Single,
                                                  (aParent.Width + PAD_SIDE) div 2,
                                                  PAD_VERT + Radio_MapType.Height + 35,
                                                  half,
                                                  aParent.Height - PAD_VERT*2 - Radio_MapType.Height - 15,
                                                  fntMetal, bsMenu);
    ColumnBox_Maps.Anchors := [anTop, anBottom];
    ColumnBox_Maps.ShowHintWhenShort := True;
    ColumnBox_Maps.HintBackColor := TKMColor4f.New(75, 60, 35);
    ColumnBox_Maps.SetColumns(fntOutline, ['', '', gResTexts[TX_MENU_MAP_TITLE], gResTexts[TX_MENU_MAP_SIZE]], [0, 50, 100, 380]);
    ColumnBox_Maps.Columns[2].Font := fntMetal;
    ColumnBox_Maps.Columns[2].HintFont := fntGrey;
    ColumnBox_Maps.Columns[1].TextAlign := taCenter;
    ColumnBox_Maps.Columns[3].TextAlign := taCenter;
    ColumnBox_Maps.ItemHeight := 40;
    ColumnBox_Maps.SearchColumn := 2;
    ColumnBox_Maps.ShowLines := True;
    ColumnBox_Maps.Header.Height := 40;
    ColumnBox_Maps.Header.TextAlign := taCenter;
    ColumnBox_Maps.Header.Columns[0].Glyph := MakePic(rxGui, 42);
    ColumnBox_Maps.Header.Columns[1].Glyph := MakePic(rxGui, 31);
    ColumnBox_Maps.OnColumnClick := ListSort;
    ColumnBox_Maps.OnChange := ListClick;
    ColumnBox_Maps.OnDoubleClick := StartClick;

    Panel_Desc := TKMPanel.Create(Panel_Single, PAD_SIDE, PAD_VERT, half, aParent.Height - PAD_VERT*2);
    Panel_Desc.Anchors := [anTop, anBottom];

      //Description
      Label_Title := TKMLabel.Create(Panel_Desc, half div 2, 0, '', fntOutline, taCenter);
      Memo_Desc  := TKMMemo.Create(Panel_Desc, 0, 20, half, 300, fntMetal, bsMenu);
      Memo_Desc.Anchors := [anTop, anBottom];
      Memo_Desc.WordWrap := True;

      //Minimap preview
      MinimapView := TKMMinimapView.Create(fMinimap, Panel_Desc, 4, 332, 191, 191, True);
      MinimapView.Anchors := [anLeft, anBottom];
      MinimapView.OnLocClick := MinimapLocClick;

      descL := MinimapView.Right + 10;

      //Setup (loc and flag placed alongside just like in MP lobby)
      //Other setup settings can go below
      L := TKMLabel.Create(Panel_Desc, descL, 330, 150, 20, gResTexts[TX_LOBBY_HEADER_STARTLOCATION], fntMetal, taLeft);
      L.Anchors := [anLeft, anBottom];
      DropBox_Loc := TKMDropList.Create(Panel_Desc, descL, 350, 150, 20, fntMetal, gResTexts[TX_MENU_MAP_LOCATION], bsMenu);
      DropBox_Loc.Anchors := [anLeft, anBottom];
      DropBox_Loc.OnChange := OptionsChange;

      L := TKMLabel.Create(Panel_Desc, half - 80, 330, 80, 20, gResTexts[TX_LOBBY_HEADER_FLAGCOLOR], fntMetal, taLeft);
      L.Anchors := [anLeft, anBottom];
      DropBox_Color := TKMDropColumns.Create(Panel_Desc, half - 80, 350, 80, 20, fntGrey, '', bsMenu);
      DropBox_Color.Anchors := [anLeft, anBottom];
      DropBox_Color.SetColumns(fntOutline, [''], [0]);
      DropBox_Color.List.ShowHeader := False;
      DropBox_Color.FadeImageWhenDisabled := False;
      DropBox_Color.Add(MakeListRow([''], [$FFFFFFFF], [MakePic(rxGuiMain, 31)], 0));
      DropBox_Color.OnChange := OptionsChange;
      fLastColIndex := 0;

      Label_Difficulty := TKMLabel.Create(Panel_Desc, descL, 385, gResTexts[TX_MISSION_DIFFICULTY], fntMetal, taLeft);
      Label_Difficulty.Anchors := [anLeft, anBottom];
      Label_Difficulty.Hide;
      DropBox_Difficulty := TKMDropList.Create(Panel_Desc, descL, 405, 150, 20, fntMetal, gResTexts[TX_MISSION_DIFFICULTY], bsMenu);
      DropBox_Difficulty.Anchors := [anLeft, anBottom];
      DropBox_Difficulty.OnChange := OptionsChange;
      DropBox_Difficulty.Hide;

      Label_AIPlayerType := TKMLabel.Create(Panel_Desc, descL, 435, gResTexts[TX_AI_PLAYER_TYPE], fntMetal, taLeft);
      Label_AIPlayerType.Anchors := [anLeft, anBottom];
      Label_AIPlayerType.Hide;
      DropBox_AIPlayerType := TKMDropList.Create(Panel_Desc, descL, 455, half - descL, 20, fntMetal, gResTexts[TX_AI_PLAYER_TYPE], bsMenu);
      DropBox_AIPlayerType.Anchors := [anLeft, anBottom];
      DropBox_AIPlayerType.OnChange := OptionsChange;
      DropBox_AIPlayerType.Hide;

      Button_SetupReadme := TKMButton.Create(Panel_Desc, descL, 523 - 25, half - descL, 25, gResTexts[TX_LOBBY_VIEW_README], bsMenu);
      Button_SetupReadme.Anchors := [anLeft,anBottom];
      Button_SetupReadme.OnClick := ReadmeClick;
      Button_SetupReadme.Hide;

      //Goals
      B := TKMBevel.Create(Panel_Desc, 0, 530, half, 30);
      B.Anchors := [anLeft, anBottom];
      L := TKMLabel.Create(Panel_Desc, 4, 538, 190, 30, gResTexts[TX_MENU_WIN_CONDITION], fntMetal, taLeft);
      L.Anchors := [anLeft, anBottom];
      B := TKMBevel.Create(Panel_Desc, 0, 560, half, 30);
      B.Anchors := [anLeft, anBottom];
      L := TKMLabel.Create(Panel_Desc, 4, 568, 190, 30, gResTexts[TX_MENU_DEFEAT_CONDITION], fntMetal, taLeft);
      L.Anchors := [anLeft, anBottom];
      backCol := TKMColor4f.New(50, 40, 25);
      for I := 0 to MAX_UI_GOALS - 1 do
      begin
        Panel_VictGoal[I] := TKMPanel.Create(Panel_Desc, 200 + I*35, 530, 35, 35);
        Panel_VictGoal[I].Anchors := [anLeft, anBottom];
          Image_VictGoal[I] := TKMImage.Create(Panel_VictGoal[I], 0, 0, 30, 30, 41);
          Image_VictGoal[I].ImageCenter;
          Label_VictGoal[I] := TKMLabel.Create(Panel_VictGoal[I], 15, 5, '', fntGrey, taCenter);
          Image_VictGoalSt[I] := TKMImage.Create(Panel_VictGoal[I], 17, 15, 20, 20, 371, rxGui);
          // Bevel used just for a unified hint when hover over any goal part
          // Thus its added last
          Bevel_VictGoal[I] := TKMBevel.Create(Panel_VictGoal[I], 0, 0, Panel_VictGoal[I].Width, Panel_VictGoal[I].Height);
          Bevel_VictGoal[I].BackAlpha := 0;
          Bevel_VictGoal[I].EdgeAlpha := 0;
          Bevel_VictGoal[I].HintBackColor := backCol;

        Panel_SurvGoal[I] := TKMPanel.Create(Panel_Desc, 200 + I*35, 560, 35, 35);
        Panel_SurvGoal[I].Anchors := [anLeft, anBottom];
          Image_SurvGoal[I] := TKMImage.Create(Panel_SurvGoal[I], 0, 0, 30, 30, 41);
          Image_SurvGoal[I].ImageCenter;
          Label_SurvGoal[I] := TKMLabel.Create(Panel_SurvGoal[I], 15, 5, '', fntGrey, taCenter);
          Image_SurvGoalSt[I] := TKMImage.Create(Panel_SurvGoal[I], 18, 15, 20, 20, 44, rxGui);
          // Bevel used just for a unified hint when hover over any goal part
          // Thus its added last
          Bevel_SurvGoal[I] := TKMBevel.Create(Panel_SurvGoal[I], 0, 0, Panel_SurvGoal[I].Width, Panel_SurvGoal[I].Height);
          Bevel_SurvGoal[I].BackAlpha := 0;
          Bevel_SurvGoal[I].EdgeAlpha := 0;
          Bevel_SurvGoal[I].HintBackColor := backCol;
      end;

      //Alliances
      B := TKMBevel.Create(Panel_Desc, 0, 590, half, 20);
      B.Anchors := [anLeft, anBottom];
      L := TKMLabel.Create(Panel_Desc, 4, 594, 190, 20, gResTexts[TX_MENU_ALLIES], fntMetal, taLeft);
      L.Anchors := [anLeft, anBottom];
      B := TKMBevel.Create(Panel_Desc, 0, 610, half, 20);
      B.Anchors := [anLeft, anBottom];
      L := TKMLabel.Create(Panel_Desc, 4, 614, 190, 20, gResTexts[TX_MENU_ENEMIES], fntMetal, taLeft);
      L.Anchors := [anLeft, anBottom];

      for I := 0 to MAX_HANDS - 1 do
      begin
        Image_Allies[I] := TKMImage.Create(Panel_Desc, 200 + I*FLAG_W, 593, 50, 20, 81, rxGuiMain);
        Image_Allies[I].Anchors := [anLeft, anBottom];
        Image_Enemies[I] := TKMImage.Create(Panel_Desc, 200 + I*FLAG_W, 613, 50, 20, 81, rxGuiMain);
        Image_Enemies[I].Anchors := [anLeft, anBottom];
      end;

    buttonW := (half - BUTTON_DIST) div 2;
    Button_Back := TKMButton.Create(Panel_Single, PAD_SIDE, aParent.Height - PAD_VERT - 30,
                                    buttonW, 30, gResTexts[TX_MENU_BACK], bsMenu);
    Button_Back.Anchors := [anLeft, anBottom];
    Button_Back.OnClick := BackClick;
    Button_Start := TKMButton.Create(Panel_Single, PAD_SIDE + BUTTON_DIST + buttonW, aParent.Height - PAD_VERT - 30,
                                     buttonW, 30, gResTexts[TX_MENU_SINGLE_START_MAP], bsMenu);
    Button_Start.Anchors := [anLeft, anBottom];
    Button_Start.OnClick := StartClick;
end;


procedure TKMMenuSingleMap.ScanUpdate(Sender: TObject);
begin
  if not fScanCompleted then  // Don't refresh list, if scan was completed already
    ListRefresh(False); //Don't jump to selected with each scan update
end;


procedure TKMMenuSingleMap.SortUpdate(Sender: TObject);
begin
  ListRefresh(True); //After sorting jump to the selected item
end;


procedure TKMMenuSingleMap.ScanTerminate(Sender: TObject);
begin
  fScanCompleted := True;
  ListRefresh(True); //After scan complete jump to selected item
end;


procedure TKMMenuSingleMap.ListRefresh(aJumpToSelected: Boolean);
var
  I, listI, prevTop: Integer;
  R: TKMListRow;
begin
  prevTop := ColumnBox_Maps.TopIndex;
  ColumnBox_Maps.Clear;
  fMaps.Lock;
  try
    listI := 0;
    for I := 0 to fMaps.Count - 1 do
    begin
      //Ignore not SP maps in list
      if not fMaps[I].IsPlayableForSP then Continue;

      case Radio_MapType.ItemIndex of
        0:  if not (fMaps[I].IsSinglePlayerKind and fMaps[I].IsBuildingMission and not fMaps[I].TxtInfo.IsSpecial) then
              Continue;
        1:  if not (not fMaps[I].IsSinglePlayerKind and fMaps[I].IsBuildingMission and not fMaps[I].TxtInfo.IsSpecial) then
              Continue;
        2:  if not (fMaps[I].IsFightingMission and not fMaps[I].TxtInfo.IsSpecial) then
              Continue;
        3:  if not fMaps[I].TxtInfo.IsSpecial then
              Continue;
      end;

      R := MakeListRow(['', IntToStr(fMaps[I].LocCount), fMaps[I].Name, MapSizeText(fMaps[I].MapSizeX, fMaps[I].MapSizeY)]);
      R.Cells[2].SubTxt := fMaps[I].TxtInfo.SmallDesc;
      R.Cells[0].Pic := MakePic(rxGui, 28 + Byte(fMaps[I].MissionMode <> mmFighting) * 14);
      R.Tag := I;
      ColumnBox_Maps.AddItem(R);

      if (fMaps[I].MapAndDatCRC = fLastMapCRC) then
      begin
        ColumnBox_Maps.ItemIndex := listI;
        ListClick(nil);
      end;
      Inc(listI);
    end;
  finally
    fMaps.Unlock;
  end;

  ColumnBox_Maps.TopIndex := prevTop;
  if aJumpToSelected
    and not InRange(ColumnBox_Maps.ItemIndex - ColumnBox_Maps.TopIndex, 0, ColumnBox_Maps.GetVisibleRows - 1)
  then
    if ColumnBox_Maps.ItemIndex < ColumnBox_Maps.TopIndex + ColumnBox_Maps.GetVisibleRows - 1 then
      ColumnBox_Maps.TopIndex := ColumnBox_Maps.ItemIndex
    else
    if ColumnBox_Maps.ItemIndex > ColumnBox_Maps.TopIndex + ColumnBox_Maps.GetVisibleRows - 1 then
      ColumnBox_Maps.TopIndex := ColumnBox_Maps.ItemIndex - ColumnBox_Maps.GetVisibleRows + 1;
end;


procedure TKMMenuSingleMap.ListClick(Sender: TObject);
var
  I: Integer;
  mapId: Integer;
  lastColor: Integer;
  MD: TKMMissionDifficulty;
  aiColors: TKMCardinalArray;
  map: TKMMapInfo;
begin
  fMaps.Lock;
  try
    if ColumnBox_Maps.IsSelected then
      mapId := ColumnBox_Maps.SelectedItem.Tag
    else
      mapId := -1;

    //User could have clicked on empty space in list and we get -1 or unused MapId
    if not InRange(mapId, 0, fMaps.Count - 1) then
    begin
      fLastMapCRC := 0;
      Label_Title.Caption   := '';
      Memo_Desc.Text        := '';
      DropBox_Loc.ItemIndex := -1;

      MinimapView.Hide;

      DropBox_Loc.Clear;
      DropBox_Color.Clear;

      Label_Difficulty.Hide;
      DropBox_Difficulty.Hide;

      Button_SetupReadme.Hide;

      Label_AIPlayerType.Hide;
      DropBox_AIPlayerType.Hide;

      Button_Start.Enabled := False;
    end
    else
    begin
      map := fMaps[mapId];
      //Prepare extra data we are about to display
      map.LoadExtra(True);

      fLastMapCRC := map.MapAndDatCRC;
      case Radio_MapType.ItemIndex of
        0:  gGameSettings.MenuSPScenarioMapCRC  := fLastMapCRC;
        1:  gGameSettings.MenuSPMissionMapCRC   := fLastMapCRC;
        2:  gGameSettings.MenuSPTacticMapCRC    := fLastMapCRC;
        3:  gGameSettings.MenuSPSpecialMapCRC   := fLastMapCRC;
      end;

      Label_Title.Caption := map.Name;
      Memo_Desc.Text      := map.BigDesc;
      MinimapView.Show;

      //Location
      DropBox_Loc.Clear;
      for I := 0 to map.LocCount - 1 do
        if map.CanBeHuman[I] or ALLOW_TAKE_AI_PLAYERS then
          DropBox_Loc.Add(map.LocationName(I), I);

      //Difficulty levels
      DropBox_Difficulty.Clear;
      if map.TxtInfo.HasDifficultyLevels then
      begin
        I := 0;
        for MD in map.TxtInfo.DifficultyLevels do
        begin
          DropBox_Difficulty.Add(gResTexts[DIFFICULTY_LEVELS_TX[MD]], Byte(MD));
          if MD = mdNormal then //Default difficulty is "Normal"
            DropBox_Difficulty.ItemIndex := I;
          Inc(I);
        end;
        if not DropBox_Difficulty.IsSelected then
          DropBox_Difficulty.ItemIndex := 0;
        DropBox_Difficulty.DoSetVisible;
        Label_Difficulty.DoSetVisible;
      end else begin
        Label_Difficulty.Hide;
        DropBox_Difficulty.Hide;
      end;

      //AI type
      DropBox_AIPlayerType.Clear;
      if map.HasDifferentAITypes(map.DefaultHuman) then
      begin
        DropBox_AIPlayerType.Add(gResTexts[TX_AI_PLAYER_CLASSIC_SHORT], Byte(aitClassic));
        DropBox_AIPlayerType.Add(gResTexts[TX_AI_PLAYER_ADVANCED_SHORT], Byte(aitAdvanced));

        if not DropBox_AIPlayerType.IsSelected then
          DropBox_AIPlayerType.ItemIndex := 1;

        DropBox_AIPlayerType.DoSetVisible;
        Label_AIPlayerType.DoSetVisible;
      end else begin
        Label_AIPlayerType.Hide;
        DropBox_AIPlayerType.Hide;
      end;

      Button_SetupReadme.Visible := map.HasReadme;

      DropBox_Loc.SelectByTag(map.DefaultHuman);

      //Color
      //Fill in colors for each map individually
      //I plan to skip colors that are similar to those on a map already
      lastColor := DropBox_Color.ItemIndex;
      if lastColor = -1 then
        lastColor := 0; //Default
      DropBox_Color.Clear;
      //Default colour chosen by map author
      DropBox_Color.Add(MakeListRow([''], [map.FlagColors[map.DefaultHuman]], [MakePic(rxGuiMain, 30)]));
      //Separator
      DropBox_Color.Add(MakeListRow([''], [$FF000000], [MakePic(rxGuiMain, 0)]));
      aiColors := map.AIOnlyLocsColors; // save it locally to avoid multiple calculations
      //MP colours
      for I := Low(MP_PLAYER_COLORS) to High(MP_PLAYER_COLORS) do
      begin
        // Do not add used AI colors to the list
        if IsColorCloseToColors(MP_PLAYER_COLORS[I], aiColors, MIN_PLAYER_COLOR_DIST) then
          Continue;

        DropBox_Color.Add(MakeListRow([''], [MP_PLAYER_COLORS[I]], [MakePic(rxGuiMain, 30)]));
      end;
      DropBox_Color.ItemIndex := lastColor; //Keep previous selection
    end;

    //Block options if there's nothing to choose there
    DropBox_Loc.Enabled := DropBox_Loc.Count > 1;
    MinimapView.ShowLocs := DropBox_Loc.Count > 1;
    DropBox_Color.Enabled := not fMaps[mapId].TxtInfo.BlockColorSelection and (DropBox_Color.Count > 1);
    Button_Start.Enabled := fMaps[mapId].IsValid;

    DoOptionsChange;
  finally
    fMaps.Unlock;
  end;
end;


procedure TKMMenuSingleMap.DoOptionsChange(aForceUpdate: Boolean = False);
begin
  UpdateDropBoxes;
  Update(aForceUpdate);
end;


procedure TKMMenuSingleMap.ReadmeClick(Sender: TObject);
begin
  if ColumnBox_Maps.IsSelected then
    TryOpenMapPDF(fMaps[ColumnBox_Maps.SelectedItemTag]);
end;


procedure TKMMenuSingleMap.OptionsChange(Sender: TObject);
begin
  UpdateDropBoxes;
  DoOptionsChange(True);

  fLastColIndex := DropBox_Color.ItemIndex;
end;


procedure TKMMenuSingleMap.ListUpdate;
begin
  //ListClear;
  ColumnBox_Maps.Clear;

  fLastMapCRC := 0;
  case Radio_MapType.ItemIndex of
    0:  fLastMapCRC := gGameSettings.MenuSPScenarioMapCRC;
    1:  fLastMapCRC := gGameSettings.MenuSPMissionMapCRC;
    2:  fLastMapCRC := gGameSettings.MenuSPTacticMapCRC;
    3:  fLastMapCRC := gGameSettings.MenuSPSpecialMapCRC;
  end;
end;


procedure TKMMenuSingleMap.ResetUI;
begin
  Label_Title.Caption   := '';
  Memo_Desc.Text        := '';
  DropBox_Loc.ItemIndex := -1;

  MinimapView.Hide;

  DropBox_Loc.Clear;
  DropBox_Color.Clear;
  DropBox_Difficulty.Clear;
  Label_Difficulty.Hide;
  DropBox_Difficulty.Hide;
  Label_AIPlayerType.Hide;
  DropBox_AIPlayerType.Hide;
  Button_SetupReadme.Hide;

  ResetExtraInfo;
end;


procedure TKMMenuSingleMap.ResetExtraInfo;
var
  I: Integer;
begin
  //Clear all so that later we fill only used
  for I := 0 to MAX_UI_GOALS - 1 do
  begin
    Panel_VictGoal[I].Hide;
    Panel_SurvGoal[I].Hide;
  end;
  for I := 0 to MAX_HANDS - 1 do
  begin
    Image_Allies[I].Hide;
    Image_Enemies[I].Hide;
  end;
  Button_Start.Disable;
end;


procedure TKMMenuSingleMap.UpdateDropBoxes;
var
  colItemChange: Integer;
begin
  if DropBox_Loc.ItemIndex <> -1 then
    fSingleLoc := DropBox_Loc.GetSelectedTag
  else
    fSingleLoc := -1;

  if DropBox_Difficulty.Visible and DropBox_Difficulty.IsSelected then
    fDifficulty := TKMMissionDifficulty(DropBox_Difficulty.GetSelectedTag)
  else
    fDifficulty := mdNone;

  if DropBox_AIPlayerType.Visible and DropBox_AIPlayerType.IsSelected then
    fAIType := TKMAIType(DropBox_AIPlayerType.GetSelectedTag)
  else
    fAIType := aitNone;

  //Don't allow selecting separator
  if DropBox_Color.ItemIndex = 1 then
  begin
    colItemChange := DropBox_Color.ItemIndex - fLastColIndex;
    if colItemChange > 0 then
      DropBox_Color.ItemIndex := 2  // Going Down
    else
      DropBox_Color.ItemIndex := 0; // Going Up
  end;

  if InRange(DropBox_Color.ItemIndex, 0, DropBox_Color.List.RowCount - 1) then
    fSingleColor := DropBox_Color.List.Rows[DropBox_Color.ItemIndex].Cells[0].Color;
end;


procedure TKMMenuSingleMap.Update(aForceUpdate: Boolean = False);
const
  GOAL_CONDITION_PIC: array [TKMGoalCondition] of Word = (
    41,   // gcUnknown0         - Not used/unknown
    39,   // gcBuildTutorial    - Must build a tannery (and other buildings from tutorial?) for it to be true. In KaM tutorial messages will be dispalyed if this is a goal
    592,  // gcTime             - A certain time must pass
    38,   // + (allowed) gcBuildings        - Storehouse, school, barracks, TownHall
    62,   // + (allowed) gcTroops           - All troops
    41,   // gcUnknown5         - Not used/unknown
    303,  // gcMilitaryAssets   - All Troops, Coal mine, Weapons Workshop, Tannery, Armory workshop, Stables, Iron mine, Iron smithy, Weapons smithy, Armory smithy, Barracks, Town hall and Vehicles Workshop
    141,  // gcSerfsAndSchools  - Serfs (possibly all citizens?) and schoolhouses
    312); // gcEconomyBuildings - School, Inn and Storehouse
var
  I, J, K: Integer;
  mapId: Integer;
  M: TKMMapInfo;
  G: TKMMapGoalInfo;
begin
  if not ColumnBox_Maps.IsSelected then Exit;
  mapId := ColumnBox_Maps.SelectedItem.Tag;
  if (fUpdatedLastListId = mapId) and not aForceUpdate then Exit; // Do not update same item several times

  fUpdatedLastListId := mapId;

  ResetExtraInfo;

  fMaps.Lock;
  try
    M := fMaps[mapId];

    if fSingleLoc = -1 then
    begin
      // Hide minimap view if this map has no player location to play
      MinimapView.Hide;
      Exit;
    end;

    //Set default colour for this location
    DropBox_Color.List.Rows[0].Cells[0].Color := fMaps[mapId].FlagColors[fSingleLoc];
    if DropBox_Color.ItemIndex = 0 then
      fSingleColor := fMaps[mapId].FlagColors[fSingleLoc];

    //Refresh minimap with selected location and player color
    fMinimap.LoadFromMission(M.FullPath('.dat'), [TKMHandID(fSingleLoc)]);
    fMinimap.HandColors[fSingleLoc] := fSingleColor;
    fMinimap.Update;

    // Populate goals section
    for I := 0 to Min(MAX_UI_GOALS, M.GoalsVictoryCount[fSingleLoc]) - 1 do
    begin
      G := M.GoalsVictory[fSingleLoc,I];
      if G.Play < 0 then Continue; // Could be on some old maps
      Image_VictGoal[I].TexID := GOAL_CONDITION_PIC[G.Cond];
      Image_VictGoal[I].FlagColor := fSingleColor;
      Image_VictGoalSt[I].Show;
      Label_VictGoal[I].Caption := IntToStr(G.Play + 1);
      Bevel_VictGoal[I].Hint := GetGoalDescription(GetPlayerLoc(M), G.Play,
                                                   gltVictory, G.Cond,
                                                   FlagColorToTextColor(fSingleColor),
                                                   FlagColorToTextColor(M.FlagColors[G.Play]),
                                                   icRoyalYellow, icLightOrange);
      Panel_VictGoal[I].Show;
    end;
    for I := 0 to Min(MAX_UI_GOALS, M.GoalsSurviveCount[fSingleLoc]) - 1 do
    begin
      G := M.GoalsSurvive[fSingleLoc,I];
      Image_SurvGoal[I].TexID := GOAL_CONDITION_PIC[G.Cond];
      Image_SurvGoal[I].FlagColor := fSingleColor;
      Image_SurvGoalSt[I].Show;
      Label_SurvGoal[I].Caption := IntToStr(G.Play + 1);
      Bevel_SurvGoal[I].Hint := GetGoalDescription(GetPlayerLoc(M), G.Play,
                                                   gltSurvive, G.Cond,
                                                   FlagColorToTextColor(fSingleColor),
                                                   FlagColorToTextColor(M.FlagColors[G.Play]),
                                                   icRoyalYellow, icLightOrange);
      Panel_SurvGoal[I].Show;
    end;

    // Populate alliances section
    J := 0; K := 0;
    for I := 0 to M.LocCount - 1 do
    if I <> fSingleLoc then
      case M.Alliances[fSingleLoc, I] of
        atEnemy:  begin
                    Image_Enemies[J].Show;
                    Image_Enemies[J].FlagColor := M.FlagColors[I];
                    Inc(J);
                  end;
        atAlly:   begin
                    Image_Allies[K].Show;
                    Image_Allies[K].FlagColor := M.FlagColors[I];
                    Inc(K);
                  end;
      end;

    for I := 0 to MAX_HANDS - 1 do
    begin
      if Image_Allies[I].Right > GetPanelHalf then
        Image_Allies[I].Hide;

      if Image_Enemies[I].Right > GetPanelHalf then
        Image_Enemies[I].Hide;
    end;

  finally
    fMaps.Unlock;
  end;

  Button_Start.Enable;
end;


procedure TKMMenuSingleMap.StartClick(Sender: TObject);
var
  I: Integer;
  map: TKMMapInfo;
begin
  //This is also called by double clicking on a list entry
  if not Button_Start.Enabled then
    Exit;

  fMaps.Lock;
  try
    for I := 0 to fMaps.Count - 1 do
      if fLastMapCRC = fMaps[I].MapAndDatCRC then
      begin
        map := fMaps[I]; //save map locally, cause we will unlock fMaps before using it

        //Unlock before TerminateScan,
        //or we can get deadlock when try to start game quickly while scanning is still in progress
        //it could be done if press Enter to start the game just after entering SP maps list menu
        fMaps.Unlock;
        //Scan should be terminated, as it is no longer needed
        fMaps.TerminateScan;

        //Provide mission FileName mask and title here
        if Assigned(OnNewSingleMap) then
          OnNewSingleMap(map.FullPath('.dat'), map.Name, fSingleLoc, fSingleColor, fDifficulty, fAIType);
        Exit;
      end;
  finally
    //Even if Exit; happens Unlock will be called anyway
    //Double call Unlock should not harm
    //we just allow other threads to use code after that point
    fMaps.Unlock;
  end;

  raise Exception.Create('We should NOT reach here, since we checked that the start button was enabled'); //We should NOT reach here, since we checked that the start button was enabled
end;


procedure TKMMenuSingleMap.ListSort(aColumn: Integer);
var
  method: TKMapsSortMethod;
begin
  //Set Descending order by default and invert it if same column selected again
  case aColumn of
    0:  if fMaps.SortMethod = smByMissionModeDesc then
          method := smByMissionModeAsc
        else
          method := smByMissionModeDesc;
    1:  if fMaps.SortMethod = smByPlayersDesc then
          method := smByPlayersAsc
        else
          method := smByPlayersDesc;
    2:  if fMaps.SortMethod = smByNameDesc then
          method := smByNameAsc
        else
          method := smByNameDesc;
    3:  if fMaps.SortMethod = smBySizeDesc then
          method := smBySizeAsc
        else
          method := smBySizeDesc;
    else
        method := smByNameAsc; //Default
  end;

  //Start sorting and wait for SortComplete event
  fMaps.Sort(method, SortUpdate);
end;


procedure TKMMenuSingleMap.MinimapLocClick(aValue: Integer);
begin
  fSingleLoc := aValue;

  DropBox_Loc.SelectByTag(fSingleLoc);

  Update(True);
end;


procedure TKMMenuSingleMap.Show;
begin
  Radio_MapType.ItemIndex := gGameSettings.MenuMapSPType;

  ResetUI;
  //Terminate all
  fMaps.TerminateScan;

  //Reset scan variables
  fScanCompleted := False;
  fUpdatedLastListId := ITEM_NOT_LOADED;

  ListUpdate;

  fMaps.Refresh(ScanUpdate, ScanTerminate);

  Panel_Single.Show;
end;


procedure TKMMenuSingleMap.BackClick(Sender: TObject);
begin
  //Scan should be terminated, it is no longer needed
  fMaps.TerminateScan;

  fOnPageChange(gpSingleplayer);
end;


procedure TKMMenuSingleMap.UpdateState;
begin
  fMaps.UpdateState;
end;


end.
