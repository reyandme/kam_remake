unit KM_GUIMenuSingleMap;
{$I KaM_Remake.inc}
interface
uses
  Controls, Math, SysUtils,
  KM_Defaults,
  KM_Maps, KM_MapTypes,
  KM_Controls, KM_Pics, KM_InterfaceDefaults, KM_Minimap, KM_CommonTypes;


const
  MAX_UI_GOALS = 7;


type
  TKMMenuSingleMap = class (TKMMenuPageCommon)
  private
    fOnPageChange: TKMMenuChangeEventText;

    fMaps: TKMapsCollection;
    fMinimap: TKMMinimap;

    fLastMapCRC: Cardinal; //CRC of selected map

    fUpdatedLastListId: Integer;  // item id, on which last time update was invoked. Avoid multiple updates for same item, which could happen on every ListRefresh
    fScanCompleted: Boolean;      // True, after scan was completed

    fSingleLoc: Integer;
    fSingleColor: Cardinal;

    fDifficulty: TKMMissionDifficulty;
    fAIType: TKMAIType;

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

    procedure BackClick(Sender: TObject);
  protected
    Panel_Single:TKMPanel;
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
        Image_VictGoal: array [0..MAX_UI_GOALS-1] of TKMImage;
        Label_VictGoal: array [0..MAX_UI_GOALS-1] of TKMLabel;
        Image_VictGoalSt: array [0..MAX_UI_GOALS-1] of TKMImage;
        Image_SurvGoal: array [0..MAX_UI_GOALS-1] of TKMImage;
        Label_SurvGoal: array [0..MAX_UI_GOALS-1] of TKMLabel;
        Image_SurvGoalSt: array [0..MAX_UI_GOALS-1] of TKMImage;
      ColumnBox_Maps: TKMColumnBox;
      Button_Back, Button_Start: TKMButton;
  public
    constructor Create(aParent: TKMPanel; aOnPageChange: TKMMenuChangeEventText);
    destructor Destroy; override;

    procedure Show;
    procedure UpdateState;
  end;


implementation
uses
  KM_ResTexts, KM_GameApp, KM_CommonUtils, KM_RenderUI, KM_ResFonts;


{ TKMGUIMenuSingleMap }
constructor TKMMenuSingleMap.Create(aParent: TKMPanel; aOnPageChange: TKMMenuChangeEventText);
begin
  inherited Create;
              
  fOnPageChange := aOnPageChange;
  OnEscKeyDown := BackClick;

  fMaps := TKMapsCollection.Create([mfSP, mfMP, mfDL]);
  fMinimap := TKMMinimap.Create(True, True);

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
  gGameApp.GameSettings.MenuMapSPType := Radio_MapType.ItemIndex;
end;


procedure TKMMenuSingleMap.Create_SingleMap(aParent: TKMPanel);
const
  PAD_VERT = 44; //Padding from top/bottom
  PAD_SIDE = 44; //Padding from sides
var
  I: Integer;
  Half: Word; //Half width for panes
  L: TKMLabel;
  B: TKMBevel;
begin
  Panel_Single := TKMPanel.Create(aParent, 0, 0, aParent.Width, aParent.Height);
  Panel_Single.AnchorsStretch;

    Half := (aParent.Width - PAD_SIDE) div 2 - PAD_SIDE;

    TKMBevel.Create(Panel_Single, (aParent.Width + PAD_SIDE) div 2, PAD_VERT + 20, Half, 70);

    Label_MapType := TKMLabel.Create(Panel_Single, (aParent.Width + PAD_SIDE) div 2 + 5, PAD_VERT, gResTexts[TX_MENU_MAP_TYPE], fntOutline, taLeft); 

    Radio_MapType := TKMRadioGroup.Create(Panel_Single, (aParent.Width + PAD_SIDE) div 2 + 5, PAD_VERT + 25, Half - 10, 60, fntMetal);
    Radio_MapType.Add(gResTexts[TX_MENU_SP_MAP_SCENARIO]); 
    Radio_MapType.Add(gResTexts[TX_LOBBY_MAP_BUILD]);
    Radio_MapType.Add(gResTexts[TX_LOBBY_MAP_FIGHT]);
    Radio_MapType.Add(gResTexts[TX_LOBBY_MAP_SPECIAL]);
    Radio_MapType.ItemIndex := 0;
    Radio_MapType.OnChange := MapTypeChanged;

    ColumnBox_Maps := TKMColumnBox.Create(Panel_Single,
                                                  (aParent.Width + PAD_SIDE) div 2,
                                                  PAD_VERT + Radio_MapType.Height + 35,
                                                  Half,
                                                  aParent.Height - PAD_VERT*2 - Radio_MapType.Height - 15,
                                                  fntMetal, bsMenu);
    ColumnBox_Maps.Anchors := [anTop, anBottom];
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

    Panel_Desc := TKMPanel.Create(Panel_Single, PAD_SIDE, PAD_VERT, Half, aParent.Height - PAD_VERT*2);
    Panel_Desc.Anchors := [anTop, anBottom];

      //Description
      Label_Title := TKMLabel.Create(Panel_Desc, Half div 2, 0, '', fntOutline, taCenter);
      Memo_Desc  := TKMMemo.Create(Panel_Desc, 0, 20, Half, 300, fntMetal, bsMenu);
      Memo_Desc.Anchors := [anTop, anBottom];
      Memo_Desc.AutoWrap := True;

      //Minimap preview
      MinimapView := TKMMinimapView.Create(Panel_Desc, 2, 332, 191, 191, True);
      MinimapView.Anchors := [anLeft, anBottom];
      MinimapView.OnLocClick := MinimapLocClick;

      //Setup (loc and flag placed alongside just like in MP lobby)
      //Other setup settings can go below
      L := TKMLabel.Create(Panel_Desc, 200, 330, 150, 20, gResTexts[TX_LOBBY_HEADER_STARTLOCATION], fntMetal, taLeft);
      L.Anchors := [anLeft, anBottom];
      DropBox_Loc := TKMDropList.Create(Panel_Desc, 200, 350, 150, 20, fntMetal, gResTexts[TX_MENU_MAP_LOCATION], bsMenu);
      DropBox_Loc.Anchors := [anLeft, anBottom];
      DropBox_Loc.OnChange := OptionsChange;

      L := TKMLabel.Create(Panel_Desc, 360, 330, 80, 20, gResTexts[TX_LOBBY_HEADER_FLAGCOLOR], fntMetal, taLeft);
      L.Anchors := [anLeft, anBottom];
      DropBox_Color := TKMDropColumns.Create(Panel_Desc, 360, 350, 80, 20, fntGrey, '', bsMenu);
      DropBox_Color.Anchors := [anLeft, anBottom];
      DropBox_Color.SetColumns(fntOutline, [''], [0]);
      DropBox_Color.List.ShowHeader := False;
      DropBox_Color.FadeImageWhenDisabled := False;
      DropBox_Color.Add(MakeListRow([''], [$FFFFFFFF], [MakePic(rxGuiMain, 31)], 0));
      DropBox_Color.OnChange := OptionsChange;

      Label_Difficulty := TKMLabel.Create(Panel_Desc, 200, 385, gResTexts[TX_MISSION_DIFFICULTY], fntMetal, taLeft);
      Label_Difficulty.Anchors := [anLeft, anBottom];
      Label_Difficulty.Hide;
      DropBox_Difficulty := TKMDropList.Create(Panel_Desc, 200, 405, 150, 20, fntMetal, gResTexts[TX_MISSION_DIFFICULTY], bsMenu);
      DropBox_Difficulty.Anchors := [anLeft, anBottom];
      DropBox_Difficulty.OnChange := OptionsChange;
      DropBox_Difficulty.Hide;

      Label_AIPlayerType := TKMLabel.Create(Panel_Desc, 200, 440, gResTexts[TX_AI_PLAYER_TYPE], fntMetal, taLeft);
      Label_AIPlayerType.Anchors := [anLeft, anBottom];
      Label_AIPlayerType.Hide;
      DropBox_AIPlayerType := TKMDropList.Create(Panel_Desc, 200, 460, 240, 20, fntMetal, gResTexts[TX_AI_PLAYER_TYPE], bsMenu);
      DropBox_AIPlayerType.Anchors := [anLeft, anBottom];
      DropBox_AIPlayerType.OnChange := OptionsChange;
      DropBox_AIPlayerType.Hide;

      //Goals
      B := TKMBevel.Create(Panel_Desc, 0, 530, Half, 30);
      B.Anchors := [anLeft, anBottom];
      L := TKMLabel.Create(Panel_Desc, 4, 538, 190, 30, gResTexts[TX_MENU_WIN_CONDITION], fntMetal, taLeft);
      L.Anchors := [anLeft, anBottom];
      B := TKMBevel.Create(Panel_Desc, 0, 560, Half, 30);
      B.Anchors := [anLeft, anBottom];
      L := TKMLabel.Create(Panel_Desc, 4, 568, 190, 30, gResTexts[TX_MENU_DEFEAT_CONDITION], fntMetal, taLeft);
      L.Anchors := [anLeft, anBottom];
      for I := 0 to MAX_UI_GOALS - 1 do
      begin
        Image_VictGoal[I] := TKMImage.Create(Panel_Desc, 200 + I*35, 530, 30, 30, 41);
        Image_VictGoal[I].Anchors := [anLeft, anBottom];
        Image_VictGoal[I].ImageCenter;
        Label_VictGoal[I] := TKMLabel.Create(Panel_Desc, 215 + I*35, 535, '', fntGrey, taCenter);
        Label_VictGoal[I].Anchors := [anLeft, anBottom];
        Image_VictGoalSt[I] := TKMImage.Create(Panel_Desc, 217 + I*35, 545, 20, 20, 371, rxGui);
        Image_VictGoalSt[I].Anchors := [anLeft, anBottom];

        Image_SurvGoal[I] := TKMImage.Create(Panel_Desc, 200 + I*35, 560, 30, 30, 41);
        Image_SurvGoal[I].Anchors := [anLeft, anBottom];
        Image_SurvGoal[I].ImageCenter;
        Label_SurvGoal[I] := TKMLabel.Create(Panel_Desc, 215 + I*35, 565, '', fntGrey, taCenter);
        Label_SurvGoal[I].Anchors := [anLeft, anBottom];
        Image_SurvGoalSt[I] := TKMImage.Create(Panel_Desc, 218 + I*35, 575, 20, 20, 44, rxGui);
        Image_SurvGoalSt[I].Anchors := [anLeft, anBottom];
      end;

      //Alliances
      B := TKMBevel.Create(Panel_Desc, 0, 590, Half, 20);
      B.Anchors := [anLeft, anBottom];
      L := TKMLabel.Create(Panel_Desc, 4, 594, 190, 20, gResTexts[TX_MENU_ALLIES], fntMetal, taLeft);
      L.Anchors := [anLeft, anBottom];
      B := TKMBevel.Create(Panel_Desc, 0, 610, Half, 20);
      B.Anchors := [anLeft, anBottom];
      L := TKMLabel.Create(Panel_Desc, 4, 614, 190, 20, gResTexts[TX_MENU_ENEMIES], fntMetal, taLeft);
      L.Anchors := [anLeft, anBottom];
      for I := 0 to MAX_HANDS - 1 do
      begin
        Image_Allies[I] := TKMImage.Create(Panel_Desc, 200 + I*22, 593, 50, 20, 81, rxGuiMain);
        Image_Allies[I].Anchors := [anLeft, anBottom];
        Image_Enemies[I] := TKMImage.Create(Panel_Desc, 200 + I*22, 613, 50, 20, 81, rxGuiMain);
        Image_Enemies[I].Anchors := [anLeft, anBottom];
      end;

    Button_Back := TKMButton.Create(Panel_Single, 45, aParent.Height - PAD_VERT - 30, 220, 30, gResTexts[TX_MENU_BACK], bsMenu);
    Button_Back.Anchors := [anLeft, anBottom];
    Button_Back.OnClick := BackClick;
    Button_Start := TKMButton.Create(Panel_Single, 270, aParent.Height - PAD_VERT - 30, 220, 30, gResTexts[TX_MENU_SINGLE_START_MAP], bsMenu);
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
  I, ListI, PrevTop: Integer;
  R: TKMListRow;
begin
  PrevTop := ColumnBox_Maps.TopIndex;
  ColumnBox_Maps.Clear;

  fMaps.Lock;
  try
    ListI := 0;
    for I := 0 to fMaps.Count - 1 do
    begin
      //Ignore not SP maps in list
      if not fMaps[I].IsPlayableForSP then Continue;

      case Radio_MapType.ItemIndex of
        0:  if not ((fMaps[I].MapFolder = mfSP) and fMaps[I].IsNormalMission and not fMaps[I].TxtInfo.IsSpecial) then
              Continue;
        1:  if not ((fMaps[I].MapFolder <> mfSP) and fMaps[I].IsNormalMission and not fMaps[I].TxtInfo.IsSpecial) then
              Continue;
        2:  if not (fMaps[I].IsTacticMission and not fMaps[I].TxtInfo.IsSpecial) then
              Continue;
        3:  if not fMaps[I].TxtInfo.IsSpecial then
              Continue;
      end;

      R := MakeListRow(['', IntToStr(fMaps[I].LocCount), fMaps[I].FileName, MapSizeText(fMaps[I].MapSizeX, fMaps[I].MapSizeY)]);
      R.Cells[2].SubTxt := fMaps[I].TxtInfo.SmallDesc;
      R.Cells[0].Pic := MakePic(rxGui, 28 + Byte(fMaps[I].MissionMode <> mmTactic) * 14);
      R.Tag := I;
      ColumnBox_Maps.AddItem(R);

      if (fMaps[I].CRC = fLastMapCRC) then
      begin
        ColumnBox_Maps.ItemIndex := ListI;
        ListClick(nil);
      end;
      Inc(ListI);
    end;
  finally
    fMaps.Unlock;
  end;

  ColumnBox_Maps.TopIndex := PrevTop;
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
  MapId: Integer;
  I: Integer;
  LastColor: Integer;
  MD: TKMMissionDifficulty;
begin
  fMaps.Lock;
  try
    if ColumnBox_Maps.IsSelected then
      MapId := ColumnBox_Maps.SelectedItem.Tag
    else
      MapId := -1;

    //User could have clicked on empty space in list and we get -1 or unused MapId
    if not InRange(MapId, 0, fMaps.Count - 1) then
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

      Label_AIPlayerType.Hide;
      DropBox_AIPlayerType.Hide;

      Button_Start.Enabled := False;
    end
    else
    begin
      //Prepare extra data we are about to display
      fMaps[MapId].LoadExtra;

      fLastMapCRC := fMaps[MapId].CRC;
      case Radio_MapType.ItemIndex of
        0:  gGameApp.GameSettings.MenuSPScenarioMapCRC := fLastMapCRC;
        1:  gGameApp.GameSettings.MenuSPMissionMapCRC := fLastMapCRC;
        2:  gGameApp.GameSettings.MenuSPTacticMapCRC := fLastMapCRC;
        3:  gGameApp.GameSettings.MenuSPSpecialMapCRC := fLastMapCRC;
      end;

      Label_Title.Caption   := fMaps[MapId].FileName;
      Memo_Desc.Text        := fMaps[MapId].BigDesc;
      MinimapView.Show;

      //Location
      DropBox_Loc.Clear;
      for I := 0 to fMaps[MapId].LocCount - 1 do
        if fMaps[MapId].CanBeHuman[I] or ALLOW_TAKE_AI_PLAYERS then
          DropBox_Loc.Add(fMaps[MapId].LocationName(I), I);

      //Difficulty levels
      DropBox_Difficulty.Clear;
      if fMaps[MapId].TxtInfo.HasDifficultyLevels then
      begin
        I := 0;
        for MD in fMaps[MapId].TxtInfo.DifficultyLevels do
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
      if fMaps[MapId].HasDifferentAITypes then
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

      DropBox_Loc.SelectByTag(fMaps[MapId].DefaultHuman);

      //Color
      //Fill in colors for each map individually
      //I plan to skip colors that are similar to those on a map already
      LastColor := DropBox_Color.ItemIndex;
      if LastColor = -1 then
        LastColor := 0; //Default
      DropBox_Color.Clear;
      //Default colour chosen by map author
      DropBox_Color.Add(MakeListRow([''], [fMaps[MapId].FlagColors[fMaps[MapId].DefaultHuman]], [MakePic(rxGuiMain, 30)]));
      //Separator
      DropBox_Color.Add(MakeListRow([''], [$FF000000], [MakePic(rxGuiMain, 0)]));
      //MP colours
      for I := Low(MP_TEAM_COLORS) to High(MP_TEAM_COLORS) do
        DropBox_Color.Add(MakeListRow([''], [MP_TEAM_COLORS[I]], [MakePic(rxGuiMain, 30)]));
      DropBox_Color.ItemIndex := LastColor; //Keep previous selection
    end;

    //Block options if there's nothing to choose there
    DropBox_Loc.Enabled := DropBox_Loc.Count > 1;
    MinimapView.ShowLocs := DropBox_Loc.Count > 1;
    DropBox_Color.Enabled := DropBox_Color.Count > 1;
    Button_Start.Enabled := fMaps[MapId].IsValid;

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


procedure TKMMenuSingleMap.OptionsChange(Sender: TObject);
begin
  UpdateDropBoxes;
  DoOptionsChange(True);
end;


procedure TKMMenuSingleMap.ListUpdate;
begin
  //ListClear;
  ColumnBox_Maps.Clear;

  fLastMapCRC := 0;
  case Radio_MapType.ItemIndex of
    0:  fLastMapCRC := gGameApp.GameSettings.MenuSPScenarioMapCRC;
    1:  fLastMapCRC := gGameApp.GameSettings.MenuSPMissionMapCRC;
    2:  fLastMapCRC := gGameApp.GameSettings.MenuSPTacticMapCRC;
    3:  fLastMapCRC := gGameApp.GameSettings.MenuSPSpecialMapCRC;
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

  ResetExtraInfo;
end;


procedure TKMMenuSingleMap.ResetExtraInfo;
var
  I: Integer;
begin
  //Clear all so that later we fill only used
  for I := 0 to MAX_UI_GOALS - 1 do
  begin
    Image_VictGoal[I].TexID := 0;
    Label_VictGoal[I].Caption := '';
    Image_VictGoalSt[I].Hide;
    Image_SurvGoal[I].TexID := 0;
    Label_SurvGoal[I].Caption := '';
    Image_SurvGoalSt[I].Hide;
  end;
  for I := 0 to MAX_HANDS - 1 do
  begin
    Image_Allies[I].Hide;
    Image_Enemies[I].Hide;
  end;
  Button_Start.Disable;
end;


procedure TKMMenuSingleMap.UpdateDropBoxes;
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
    DropBox_Color.ItemIndex := 0;

  if InRange(DropBox_Color.ItemIndex, 0, DropBox_Color.List.RowCount - 1) then
    fSingleColor := DropBox_Color.List.Rows[DropBox_Color.ItemIndex].Cells[0].Color;
end;


procedure TKMMenuSingleMap.Update(aForceUpdate: Boolean = False);
const
  GoalCondPic: array [TKMGoalCondition] of Word = (
    41, 39, 592, 38, 62, 41, 303, 141, 312);
var
  I,J,K: Integer;
  MapId: Integer;
  M: TKMapInfo;
  G: TKMMapGoalInfo;
begin
   if (fSingleLoc <> -1) and (ColumnBox_Maps.IsSelected) then
  begin
    MapId := ColumnBox_Maps.SelectedItem.Tag;
    //Do not update same item several times
    if aForceUpdate or (fUpdatedLastListId <> MapId) then
    begin
      fUpdatedLastListId := MapId;

      ResetExtraInfo;

      fMaps.Lock;
      try
        M := fMaps[MapId];

        //Set default colour for this location
        DropBox_Color.List.Rows[0].Cells[0].Color := fMaps[MapId].FlagColors[fSingleLoc];
        if DropBox_Color.ItemIndex = 0 then
          fSingleColor := fMaps[MapId].FlagColors[fSingleLoc];

        //Refresh minimap with selected location and player color
        fMinimap.LoadFromMission(M.FullPath('.dat'), [TKMHandID(fSingleLoc)]);
        fMinimap.HandColors[fSingleLoc] := fSingleColor;
        fMinimap.Update;
        MinimapView.SetMinimap(fMinimap);

        //Populate goals section
        for I := 0 to Min(MAX_UI_GOALS, M.GoalsVictoryCount[fSingleLoc]) - 1 do
        begin
          G := M.GoalsVictory[fSingleLoc,I];
          Image_VictGoal[I].TexID := GoalCondPic[G.Cond];
          Image_VictGoal[I].FlagColor := fSingleColor;
          Image_VictGoalSt[I].Show;
          Label_VictGoal[I].Caption := IntToStr(G.Play + 1);
        end;
        for I := 0 to Min(MAX_UI_GOALS, M.GoalsSurviveCount[fSingleLoc]) - 1 do
        begin
          G := M.GoalsSurvive[fSingleLoc,I];
          Image_SurvGoal[I].TexID := GoalCondPic[G.Cond];
          Image_SurvGoal[I].FlagColor := fSingleColor;
          Image_SurvGoalSt[I].Show;
          Label_SurvGoal[I].Caption := IntToStr(G.Play + 1);
        end;

        //Populate alliances section
        J := 0; K := 0;
        for I := 0 to M.LocCount - 1 do
        if I <> fSingleLoc then
        begin
          case M.Alliances[fSingleLoc, I] of
            atEnemy: begin
                        Image_Enemies[J].Show;
                        Image_Enemies[J].FlagColor := M.FlagColors[I];
                        Inc(J);
                      end;
            atAlly:  begin
                        Image_Allies[K].Show;
                        Image_Allies[K].FlagColor := M.FlagColors[I];
                        Inc(K);
                      end;
          end;
        end;
      finally
        fMaps.Unlock;
      end;

      Button_Start.Enable;
    end;
  end;
end;


procedure TKMMenuSingleMap.StartClick(Sender: TObject);
var
  I: Integer;
begin
  //This is also called by double clicking on a list entry
  if not Button_Start.Enabled then
    Exit;

  fMaps.Lock;
  try
    for I := 0 to fMaps.Count - 1 do
      if fLastMapCRC = fMaps[I].CRC then
      begin
        //Scan should be terminated, as it is no longer needed
        fMaps.TerminateScan;

        //Provide mission FileName mask and title here
        gGameApp.NewSingleMap(fMaps[I].FullPath('.dat'), fMaps[I].FileName, fSingleLoc, fSingleColor, fDifficulty, fAIType);
        Exit;
      end;
  finally
    fMaps.Unlock; // Even if Exit; happens Unlock will be called anyway
  end;

  raise Exception.Create('We should NOT reach here, since we checked that the start button was enabled'); //We should NOT reach here, since we checked that the start button was enabled
end;


procedure TKMMenuSingleMap.ListSort(aColumn: Integer);
var
  Method: TKMapsSortMethod;
begin
  //Set Descending order by default and invert it if same column selected again
  case aColumn of
    0:  if fMaps.SortMethod = smByMissionModeDesc then
          Method := smByMissionModeAsc
        else
          Method := smByMissionModeDesc;
    1:  if fMaps.SortMethod = smByPlayersDesc then
          Method := smByPlayersAsc
        else
          Method := smByPlayersDesc;
    2:  if fMaps.SortMethod = smByNameDesc then
          Method := smByNameAsc
        else
          Method := smByNameDesc;
    3:  if fMaps.SortMethod = smBySizeDesc then
          Method := smBySizeAsc
        else
          Method := smBySizeDesc;
    else
        Method := smByNameAsc; //Default
  end;

  //Start sorting and wait for SortComplete event
  fMaps.Sort(Method, SortUpdate);
end;


procedure TKMMenuSingleMap.MinimapLocClick(aValue: Integer);
begin
  fSingleLoc := aValue;

  DropBox_Loc.SelectByTag(fSingleLoc);

  Update(True);
end;


procedure TKMMenuSingleMap.Show;
begin
  Radio_MapType.ItemIndex := gGameApp.GameSettings.MenuMapSPType;

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
