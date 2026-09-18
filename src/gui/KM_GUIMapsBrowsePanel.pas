unit KM_GUIMapsBrowsePanel;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, Math,
  KM_Controls, KM_ControlsBase, KM_ControlsList, KM_ControlsMemo, KM_ControlsMinimapView,
  KM_ControlsSwitch, KM_ControlsTrackBar,
  KM_Maps, KM_MapTypes, KM_MinimapMission, KM_CommonTypes, KM_Defaults;

type
  TKMMapsBrowsePanel = class
  private
    fIsFavouritesShown: Boolean;
    fCategory: TKMMapKind;
    fIsUpdatingCategoryRadio: Boolean;
    fIsListeningCampaigns: Boolean;
    fMaps: TKMapsCollection;
    fMinimap: TKMMinimapMission;
    fMinimapLastListId: Integer;
    fPreselectCRC: Cardinal;
    fPreselectName: UnicodeString;
    fPreselectCampaignPath: string;

    fCampMaps: array of TKMMapInfo;
    fCampMapIndices: array of Byte;

    fOnSelectionChanged: TNotifyEvent;
    fOnMapDoubleClick: TNotifyEvent;
    fOnCategoryChanged: TNotifyEvent;

    function GetSelectedMap: TKMMapInfo;
    function GetDisplayedMap(aIndex: Integer): TKMMapInfo;
    function GetContentTop: Integer;
    procedure FreeCampMaps;

    procedure CategoryRadioChange(Sender: TObject);
    procedure ApplyCategory(aKind: TKMMapKind);

    procedure FilterChanged(Sender: TObject);
    procedure FilterReset(Sender: TObject);
    procedure UpdateFilterUI;

    procedure ScanUpdate(Sender: TObject);
    procedure ScanTerminate(Sender: TObject);
    procedure SortUpdate(Sender: TObject);
    procedure ScanComplete(Sender: TObject);

    function SelectedCampaignPath: string;
    procedure RefreshCampaignsList(const aSelectPath: string);
    procedure CampaignsListUpdated(Sender: TObject);
    procedure UpdateCampInfo;
    procedure SelectCampaignClick(Sender: TObject);

    procedure RefreshList(aJumpToSelected: Boolean = True);
    procedure ColumnClick(Sender: TObject; const aColumn: Integer);
    procedure CellClick(Sender: TObject; const aCellX, aCellY: Integer; var aHandled: Boolean);
    procedure SelectMapClick(Sender: TObject);
    procedure DoubleClick(Sender: TObject);
    procedure UpdateMapInfo(aID: Integer);
    procedure ReadmeClick(Sender: TObject);
  protected
    Radio_Category: TKMRadioGroup;

    Panel_Filter: TKMPanel;
    Radio_BuildFight, Radio_CoopSpecial: TKMRadioGroup;
    CheckBox_ByPlayerCnt: TKMCheckBox;
    TrackBar_PlayersCnt: TKMTrackBar;
    CheckBox_Sizes: array [MAP_SIZE_ENUM_MIN..MAP_SIZE_ENUM_MAX] of TKMCheckBox;
    Button_ResetFilter: TKMButton;
    ListBox_Campaigns: TKMListBox;

    ColumnBox: TKMColumnBox;

    MinimapView: TKMMinimapView;
    Label_MapType: TKMLabel;
    Memo_Desc: TKMMemo;
    Button_ViewReadme: TKMButton;
  public
    constructor Create(aFilterParent, aListParent, aPreviewParent: TKMPanel; aShowFavourites: Boolean = False);
    destructor Destroy; override;

    property OnSelectionChanged: TNotifyEvent read fOnSelectionChanged write fOnSelectionChanged;
    property OnMapDoubleClick: TNotifyEvent read fOnMapDoubleClick write fOnMapDoubleClick;
    property OnCategoryChanged: TNotifyEvent read fOnCategoryChanged write fOnCategoryChanged;

    property Category: TKMMapKind read fCategory;
    property ContentTop: Integer read GetContentTop;

    function IsMultiplayerCategory: Boolean;
    function IsDownloadedCategory: Boolean;
    function IsCampaignCategory: Boolean;
    function HasSelection: Boolean;
    function SelectByName(const aName: UnicodeString): Boolean;
    property SelectedMap: TKMMapInfo read GetSelectedMap;
    function SelectedCampaignIndex: Integer;
    function SelectedCampaignMissionIndex: Integer;

    procedure SetPreselect(aCRC: Cardinal; const aName: UnicodeString; const aCampaignPath: string = '');
    procedure SetCategory(aKind: TKMMapKind);
    procedure Refresh;
    procedure UpdateState;
    procedure TerminateScan;
    procedure SetVisible(aVisible: Boolean);
    procedure Focus;
    procedure SetListFocusable(aFocusable: Boolean);

    function ContainsMapName(const aName: UnicodeString): Boolean;

    procedure DeleteSelectedMap;
    procedure RenameSelectedMap(const aNewName: UnicodeString);
    procedure MoveSelectedMap(const aNewName: UnicodeString; aKind: TKMMapKind);
  end;


implementation
uses
  KM_ResTexts, KM_ResFonts, KM_Resource, KM_RenderUI, KM_ResTypes, KM_Pics,
  KM_GameSettings, KM_ServerSettings, KM_GameAppSettings, KM_MapUtilsExt, KM_CommonUtils,
  KM_Campaigns, KM_GameApp, KM_Log;


const
  FILTER_PAD_X = 8;
  FILTER_PAD_Y = 6;
  CATEGORY_TOP = 8;
  CATEGORY_RADIO_H = 80;
  CATEGORY_PANEL_H = 88;
  CONTENT_GAP = 8;
  RADIO_GROUP_H = 40;
  ITEM_H = 20;
  PLAYERS_PANEL_H = 45;
  SIZES_GAP = 5;
  SIZES_PANEL_H = 40;
  SIZE_CHECKBOX_W = 60;
  SIZE_COLUMN_STEP = 70;
  SIZE_ROWS = 2;
  PREVIEW_PAD = 4;
  PREVIEW_GAP = 10;
  README_BUTTON_H = 25;
  DESC_ITEM_H = 16;
  MISSION_MODE_ICON_TEX = 657;
  COLUMNS_FAVOURITES_X: array [0..5] of Word = (0, 22, 44, 310, 335, 360);
  COLUMNS_X: array [0..4] of Word = (0, 22, 288, 313, 338);


{ TKMMapsBrowsePanel }
constructor TKMMapsBrowsePanel.Create(aFilterParent, aListParent, aPreviewParent: TKMPanel; aShowFavourites: Boolean = False);
var
  mapSize: TKMMapSize;
begin
  inherited Create;

  fIsFavouritesShown := aShowFavourites;
  fCategory := mkSP;
  fMinimapLastListId := -1;
  fMaps := TKMapsCollection.Create([mkSP, mkMP, mkDL], smByNameAsc, fIsFavouritesShown);
  fMinimap := TKMMinimapMission.Create(True);

  TKMBevel.Create(aFilterParent, 0, 0, aFilterParent.Width, CATEGORY_PANEL_H);
  Radio_Category := TKMRadioGroup.Create(aFilterParent, FILTER_PAD_X, CATEGORY_TOP, aFilterParent.Width - 2*FILTER_PAD_X, CATEGORY_RADIO_H, fntGrey);
  Radio_Category.Add(gResTexts[TX_MENU_MAPED_SPMAPS]);
  Radio_Category.Add(gResTexts[TX_MENU_MAPED_MPMAPS_SHORT]);
  Radio_Category.Add(gResTexts[TX_MENU_CAMPAIGNS]);
  Radio_Category.Add(gResTexts[TX_MENU_MAPED_DLMAPS]);
  Radio_Category.ItemIndex := 0;
  Radio_Category.OnChange := CategoryRadioChange;

  Panel_Filter := TKMPanel.Create(aFilterParent, 0, GetContentTop, aFilterParent.Width, aFilterParent.Height - GetContentTop);
  Panel_Filter.Anchors := [anLeft, anTop, anBottom, anRight];

  TKMBevel.Create(Panel_Filter, 0, 0, Panel_Filter.Width, RADIO_GROUP_H + FILTER_PAD_Y);
  Radio_BuildFight := TKMRadioGroup.Create(Panel_Filter, FILTER_PAD_X, FILTER_PAD_Y, Panel_Filter.Width - 2*FILTER_PAD_X, RADIO_GROUP_H, fntGrey);
  Radio_BuildFight.Add(gResTexts[TX_LOBBY_MAP_BUILD]);
  Radio_BuildFight.Add(gResTexts[TX_LOBBY_MAP_FIGHT]);
  Radio_BuildFight.AllowUncheck := True;
  Radio_BuildFight.OnChange := FilterChanged;

  TKMBevel.Create(Panel_Filter, 0, Radio_BuildFight.Bottom + FILTER_PAD_Y, Panel_Filter.Width, RADIO_GROUP_H + FILTER_PAD_Y);
  Radio_CoopSpecial := TKMRadioGroup.Create(Panel_Filter, FILTER_PAD_X, Radio_BuildFight.Bottom + 2*FILTER_PAD_Y, Panel_Filter.Width - 2*FILTER_PAD_X, RADIO_GROUP_H, fntGrey);
  Radio_CoopSpecial.Add(gResTexts[TX_LOBBY_MAP_SPECIAL]);
  Radio_CoopSpecial.Add(gResTexts[TX_LOBBY_MAP_COOP]);
  Radio_CoopSpecial.AllowUncheck := True;
  Radio_CoopSpecial.OnChange := FilterChanged;

  TKMBevel.Create(Panel_Filter, 0, Radio_CoopSpecial.Bottom + FILTER_PAD_Y, Panel_Filter.Width, PLAYERS_PANEL_H + 2*FILTER_PAD_Y);
  CheckBox_ByPlayerCnt := TKMCheckBox.Create(Panel_Filter, FILTER_PAD_X, Radio_CoopSpecial.Bottom + 2*FILTER_PAD_Y,
                                             Panel_Filter.Width - 2*FILTER_PAD_X, ITEM_H, gResTexts[TX_MENU_MAP_FILTER_BY_PLAYERS_NUMBER], fntGrey);
  CheckBox_ByPlayerCnt.OnClick := FilterChanged;
  TrackBar_PlayersCnt := TKMTrackBar.Create(Panel_Filter, FILTER_PAD_X, CheckBox_ByPlayerCnt.Bottom + FILTER_PAD_Y,
                                            Panel_Filter.Width - 2*FILTER_PAD_X, 1, MAX_LOBBY_PLAYERS);
  TrackBar_PlayersCnt.Disable;
  TrackBar_PlayersCnt.OnChange := FilterChanged;

  TKMBevel.Create(Panel_Filter, 0, TrackBar_PlayersCnt.Bottom + FILTER_PAD_Y + SIZES_GAP, Panel_Filter.Width, SIZES_PANEL_H + FILTER_PAD_Y);
  for mapSize := MAP_SIZE_ENUM_MIN to MAP_SIZE_ENUM_MAX do
  begin
    CheckBox_Sizes[mapSize] := TKMCheckBox.Create(Panel_Filter, FILTER_PAD_X + SIZE_COLUMN_STEP*((Byte(mapSize)-1) div SIZE_ROWS),
                                             TrackBar_PlayersCnt.Bottom + 2*FILTER_PAD_Y + SIZES_GAP + ITEM_H*((Byte(mapSize)-1) mod SIZE_ROWS),
                                             SIZE_CHECKBOX_W, ITEM_H, MapSizeText(mapSize), fntMetal);
    CheckBox_Sizes[mapSize].Check;
    CheckBox_Sizes[mapSize].OnClick := FilterChanged;
  end;

  Button_ResetFilter := TKMButton.Create(Panel_Filter, 0, TrackBar_PlayersCnt.Bottom + 2*FILTER_PAD_Y + SIZES_GAP + SIZES_PANEL_H + FILTER_PAD_Y,
                                         Panel_Filter.Width, ITEM_H, gResTexts[TX_MENU_MAP_FILTER_RESET], bsMenu);
  Button_ResetFilter.OnClick := FilterReset;

  ListBox_Campaigns := TKMListBox.Create(aFilterParent, 0, GetContentTop, aFilterParent.Width, aFilterParent.Height - GetContentTop, fntMetal, bsMenu);
  ListBox_Campaigns.Anchors := [anLeft, anTop, anBottom, anRight];
  ListBox_Campaigns.AutoHideScrollBar := True;
  ListBox_Campaigns.OnChange := SelectCampaignClick;
  ListBox_Campaigns.Hide;

  ColumnBox := TKMColumnBox.Create(aListParent, 0, 0, aListParent.Width, aListParent.Height, fntMetal, bsMenu);
  ColumnBox.Anchors := [anLeft, anTop, anBottom, anRight];
  if fIsFavouritesShown then
    ColumnBox.SetColumns(fntOutline, ['', '', gResTexts[TX_MENU_MAP_TITLE], gResTexts[TX_MENU_MAP_HUMAN_TITLE], '#', gResTexts[TX_MENU_MAP_SIZE]],
                                     COLUMNS_FAVOURITES_X)
  else
    ColumnBox.SetColumns(fntOutline, ['', gResTexts[TX_MENU_MAP_TITLE], gResTexts[TX_MENU_MAP_HUMAN_TITLE], '#', gResTexts[TX_MENU_MAP_SIZE]],
                                     COLUMNS_X);
  ColumnBox.SearchColumn := Byte(fIsFavouritesShown) + 1;
  ColumnBox.OnColumnClick := ColumnClick;
  ColumnBox.OnChange := SelectMapClick;
  ColumnBox.OnDoubleClick := DoubleClick;
  ColumnBox.OnCellClick := CellClick;
  ColumnBox.ShowHintWhenShort := True;
  ColumnBox.HintBackColor := TKMColor4f.New(149, 128, 69);

  MinimapView := TKMMinimapView.Create(fMinimap, aPreviewParent, PREVIEW_PAD, PREVIEW_PAD, aPreviewParent.Width - 2*PREVIEW_PAD, aPreviewParent.Width - 2*PREVIEW_PAD, True);
  MinimapView.Anchors := [anLeft, anTop];

  Label_MapType := TKMLabel.Create(aPreviewParent, 0, MinimapView.Bottom + PREVIEW_GAP, '', fntMetal, taLeft);
  Label_MapType.Anchors := [anLeft, anTop];

  Memo_Desc := TKMMemo.Create(aPreviewParent, 0, MinimapView.Bottom + PREVIEW_GAP, aPreviewParent.Width, aPreviewParent.Height - MinimapView.Bottom - PREVIEW_GAP, fntGame, bsMenu);
  Memo_Desc.Anchors := [anLeft, anTop, anBottom];
  Memo_Desc.WordWrap := True;
  Memo_Desc.ItemHeight := DESC_ITEM_H;

  Button_ViewReadme := TKMButton.Create(aPreviewParent, 0, aPreviewParent.Height - README_BUTTON_H, aPreviewParent.Width, README_BUTTON_H, gResTexts[TX_LOBBY_VIEW_README], bsMenu);
  Button_ViewReadme.Anchors := [anLeft, anBottom];
  Button_ViewReadme.OnClick := ReadmeClick;
  Button_ViewReadme.Hide;

  UpdateFilterUI;
end;


destructor TKMMapsBrowsePanel.Destroy;
begin
  if fIsListeningCampaigns and (gGameApp <> nil) and (gGameApp.Campaigns <> nil) then
    gGameApp.Campaigns.RemoveListUpdateListener(CampaignsListUpdated);

  FreeCampMaps;
  FreeAndNil(fMaps);
  FreeAndNil(fMinimap);

  inherited;
end;


procedure TKMMapsBrowsePanel.FreeCampMaps;
var
  I: Integer;
begin
  for I := 0 to High(fCampMaps) do
    FreeAndNil(fCampMaps[I]);
  SetLength(fCampMaps, 0);
  SetLength(fCampMapIndices, 0);
end;


function TKMMapsBrowsePanel.IsMultiplayerCategory: Boolean;
begin
  Result := fCategory = mkMP;
end;


function TKMMapsBrowsePanel.IsDownloadedCategory: Boolean;
begin
  Result := fCategory = mkDL;
end;


function TKMMapsBrowsePanel.HasSelection: Boolean;
begin
  Result := ColumnBox.IsSelected;
end;


function TKMMapsBrowsePanel.SelectByName(const aName: UnicodeString): Boolean;
var
  I, foundIndex, nameColumn: Integer;
begin
  foundIndex := -1;
  nameColumn := Byte(fIsFavouritesShown) + 1;

  for I := 0 to ColumnBox.RowCount - 1 do
    if SameText(ColumnBox.Item[I].Cells[nameColumn].Caption, aName) then
    begin
      foundIndex := I;
      Break;
    end;

  Result := foundIndex >= 0;
  ColumnBox.ItemIndex := foundIndex;

  fMaps.Lock;
  try
    if Result then
      UpdateMapInfo(ColumnBox.SelectedItemTag)
    else
      UpdateMapInfo(-1);
  finally
    fMaps.Unlock;
  end;
end;


function TKMMapsBrowsePanel.GetSelectedMap: TKMMapInfo;
begin
  if HasSelection then
    Result := GetDisplayedMap(ColumnBox.SelectedItemTag)
  else
    Result := nil;
end;


function TKMMapsBrowsePanel.GetDisplayedMap(aIndex: Integer): TKMMapInfo;
begin
  if fCategory = mkCM then
    Result := fCampMaps[aIndex]
  else
    Result := fMaps[aIndex];
end;


function TKMMapsBrowsePanel.GetContentTop: Integer;
begin
  Result := Radio_Category.Bottom + CONTENT_GAP;
end;


function TKMMapsBrowsePanel.IsCampaignCategory: Boolean;
begin
  Result := fCategory = mkCM;
end;


function TKMMapsBrowsePanel.SelectedCampaignIndex: Integer;
begin
  Result := ListBox_Campaigns.ItemIndex;
end;


function TKMMapsBrowsePanel.SelectedCampaignMissionIndex: Integer;
begin
  if IsCampaignCategory and HasSelection and InRange(ColumnBox.SelectedItemTag, 0, High(fCampMapIndices)) then
    Result := fCampMapIndices[ColumnBox.SelectedItemTag]
  else
    Result := -1;
end;


procedure TKMMapsBrowsePanel.SetPreselect(aCRC: Cardinal; const aName: UnicodeString; const aCampaignPath: string = '');
begin
  fPreselectCRC := aCRC;
  fPreselectName := aName;
  fPreselectCampaignPath := aCampaignPath;
end;


procedure TKMMapsBrowsePanel.ApplyCategory(aKind: TKMMapKind);
begin
  fCategory := aKind;
  Panel_Filter.Visible := aKind <> mkCM;
  ListBox_Campaigns.Visible := aKind = mkCM;
  fMinimapLastListId := -1;

  if aKind = mkCM then
  begin
    if not fIsListeningCampaigns then
    begin
      gGameApp.Campaigns.AddListUpdateListener(CampaignsListUpdated);
      fIsListeningCampaigns := True;
    end;

    RefreshCampaignsList(fPreselectCampaignPath);
    UpdateCampInfo;
  end
  else
  begin
    UpdateFilterUI;
    RefreshList;
  end;
end;


procedure TKMMapsBrowsePanel.SetCategory(aKind: TKMMapKind);
const
  KIND_TO_IDX: array [TKMMapKind] of Integer = (0, 0, 1, 2, 3);
begin
  fIsUpdatingCategoryRadio := True;
  try
    Radio_Category.ItemIndex := KIND_TO_IDX[aKind];
  finally
    fIsUpdatingCategoryRadio := False;
  end;

  ApplyCategory(aKind);
end;


procedure TKMMapsBrowsePanel.CategoryRadioChange(Sender: TObject);
const
  IDX_TO_KIND: array [0..3] of TKMMapKind = (mkSP, mkMP, mkCM, mkDL);
begin
  if fIsUpdatingCategoryRadio then
    Exit;

  ApplyCategory(IDX_TO_KIND[Radio_Category.ItemIndex]);

  if Assigned(fOnCategoryChanged) then
    fOnCategoryChanged(Self);
end;


procedure TKMMapsBrowsePanel.Refresh;
begin
  fMaps.TerminateScan;
  fMinimapLastListId := -1;
  fMaps.Refresh(ScanUpdate, ScanTerminate, ScanComplete);
end;


procedure TKMMapsBrowsePanel.ScanComplete(Sender: TObject);
var
  I: Integer;
  mapsSimpleCRCArray, mapsFullCRCArray: TKMCardinalArray;
begin
  if not fIsFavouritesShown then
    Exit;

  if (Sender = fMaps) and (fMaps.Count > 0) then
  begin
    SetLength(mapsSimpleCRCArray, fMaps.Count);
    SetLength(mapsFullCRCArray, fMaps.Count);

    for I := 0 to fMaps.Count - 1 do
    begin
      mapsSimpleCRCArray[I] := fMaps[I].MapAndDatCRC;
      mapsFullCRCArray[I] := fMaps[I].CRC;

      if gServerSettings.ServerMapsRosterEnabled
        and gGameSettings.FavouriteMaps.Contains(mapsSimpleCRCArray[I]) then
        gServerSettings.ServerMapsRoster.Add(mapsFullCRCArray[I]);
    end;

    gGameSettings.FavouriteMaps.RemoveMissing(mapsSimpleCRCArray);
    gServerSettings.ServerMapsRoster.RemoveMissing(mapsFullCRCArray);
  end;
end;


function TKMMapsBrowsePanel.SelectedCampaignPath: string;
begin
  if ListBox_Campaigns.ItemIndex >= 0 then
    Result := gGameApp.Campaigns[ListBox_Campaigns.ItemIndex].Path
  else
    Result := '';
end;


procedure TKMMapsBrowsePanel.RefreshCampaignsList(const aSelectPath: string);
var
  I: Integer;
  selectTag: Integer;
begin
  ListBox_Campaigns.Clear;
  selectTag := -1;
  for I := 0 to gGameApp.Campaigns.Count - 1 do
  begin
    ListBox_Campaigns.Add(gGameApp.Campaigns[I].Spec.GetCampaignTitle);
    if (aSelectPath <> '') and SameFileName(ExcludeTrailingPathDelimiter(gGameApp.Campaigns[I].Path), ExcludeTrailingPathDelimiter(aSelectPath)) then
      selectTag := I;
  end;
  ListBox_Campaigns.ItemIndex := selectTag;
end;


procedure TKMMapsBrowsePanel.CampaignsListUpdated(Sender: TObject);
var
  previousPath, selectPath: string;
begin
  if not IsCampaignCategory then
    Exit;

  previousPath := SelectedCampaignPath;
  selectPath := previousPath;
  if selectPath = '' then
    selectPath := fPreselectCampaignPath;

  RefreshCampaignsList(selectPath);

  if not SameFileName(SelectedCampaignPath, previousPath) then
    UpdateCampInfo;
end;


procedure TKMMapsBrowsePanel.SelectCampaignClick(Sender: TObject);
begin
  UpdateCampInfo;
end;


procedure TKMMapsBrowsePanel.UpdateCampInfo;
var
  I, count: Integer;
  campaign: TKMCampaign;
  missionDir, missionName: string;
begin
  FreeCampMaps;
  fMinimapLastListId := -1;

  if ListBox_Campaigns.ItemIndex < 0 then
  begin
    RefreshList;
    Exit;
  end;

  campaign := gGameApp.Campaigns[ListBox_Campaigns.ItemIndex];

  SetLength(fCampMaps, campaign.Spec.MissionsCount);
  SetLength(fCampMapIndices, campaign.Spec.MissionsCount);
  count := 0;
  for I := 0 to campaign.Spec.MissionsCount - 1 do
  begin
    missionName := campaign.GetMissionName(I);
    missionDir := campaign.Path + missionName + PathDelim;
    if FileExists(missionDir + missionName + '.dat') and FileExists(missionDir + missionName + '.map') then
    try
      fCampMaps[count] := TKMMapInfo.Create(missionDir, missionName, False, mkCM, True);
      fCampMapIndices[count] := I;
      Inc(count);
    except
      on E: Exception do
        gLog.AddTime('Error loading campaign mission ''' + missionName + ''': ' + E.Message);
    end;
  end;
  SetLength(fCampMaps, count);
  SetLength(fCampMapIndices, count);

  RefreshList;
end;


procedure TKMMapsBrowsePanel.FilterChanged(Sender: TObject);
begin
  TrackBar_PlayersCnt.Enabled := CheckBox_ByPlayerCnt.Checked;
  fMinimapLastListId := -1;
  RefreshList;
end;


procedure TKMMapsBrowsePanel.FilterReset(Sender: TObject);
var
  mapSize: TKMMapSize;
begin
  Radio_BuildFight.ItemIndex := -1;
  Radio_CoopSpecial.ItemIndex := -1;
  CheckBox_ByPlayerCnt.Uncheck;
  TrackBar_PlayersCnt.Enabled := False;
  for mapSize := MAP_SIZE_ENUM_MIN to MAP_SIZE_ENUM_MAX do
    CheckBox_Sizes[mapSize].Check;
  FilterChanged(nil);
end;


procedure TKMMapsBrowsePanel.UpdateFilterUI;
begin
  if fCategory = mkSP then
    Radio_CoopSpecial.SetItemEnabled(1, False)
  else
    Radio_CoopSpecial.SetItemEnabled(1, True);
end;


procedure TKMMapsBrowsePanel.ScanUpdate(Sender: TObject);
begin
  if not IsCampaignCategory then
    RefreshList;
end;


procedure TKMMapsBrowsePanel.ScanTerminate(Sender: TObject);
begin
  if not IsCampaignCategory then
    RefreshList;
end;


procedure TKMMapsBrowsePanel.SortUpdate(Sender: TObject);
begin
  if not IsCampaignCategory then
    RefreshList;
end;


procedure TKMMapsBrowsePanel.ColumnClick(Sender: TObject; const aColumn: Integer);
var
  sortMethod: TKMapsSortMethod;
  favColumn, buildFightColumn, nameColumn, humanColumn, playersColumn, sizeColumn: Integer;
begin
  if IsCampaignCategory then
    Exit;

  favColumn := 0;
  buildFightColumn := Byte(fIsFavouritesShown);
  nameColumn := buildFightColumn + 1;
  humanColumn := nameColumn + 1;
  playersColumn := humanColumn + 1;
  sizeColumn := playersColumn + 1;

  if fIsFavouritesShown and (ColumnBox.SortIndex = favColumn) then
  begin
    if ColumnBox.SortDirection = sdDown then sortMethod := smByFavouriteDesc else sortMethod := smByFavouriteAsc;
  end else
  if ColumnBox.SortIndex = buildFightColumn then
  begin
    if ColumnBox.SortDirection = sdDown then sortMethod := smByMissionModeDesc else sortMethod := smByMissionModeAsc;
  end else
  if ColumnBox.SortIndex = nameColumn then
  begin
    if ColumnBox.SortDirection = sdDown then sortMethod := smByNameDesc else sortMethod := smByNameAsc;
  end else
  if ColumnBox.SortIndex = humanColumn then
  begin
    if ColumnBox.SortDirection = sdDown then sortMethod := smByHumanPlayersDesc else sortMethod := smByHumanPlayersAsc;
  end else
  if ColumnBox.SortIndex = playersColumn then
  begin
    if ColumnBox.SortDirection = sdDown then sortMethod := smByPlayersDesc else sortMethod := smByPlayersAsc;
  end else
  if ColumnBox.SortIndex = sizeColumn then
  begin
    if ColumnBox.SortDirection = sdDown then sortMethod := smBySizeDesc else sortMethod := smBySizeAsc;
  end else
    sortMethod := smByNameAsc;

  fMaps.Sort(sortMethod, SortUpdate);
end;


procedure TKMMapsBrowsePanel.CellClick(Sender: TObject; const aCellX, aCellY: Integer; var aHandled: Boolean);
var
  I: Integer;
begin
  if not fIsFavouritesShown then
    Exit;
  if IsCampaignCategory then
    Exit;
  if aCellX <> 0 then
    Exit;

  I := ColumnBox.Item[aCellY].Tag;
  fMaps.Lock;
  try
    gGameAppSettings.ReloadFavouriteMaps;

    fMaps[I].IsFavourite := not fMaps[I].IsFavourite;
    if fMaps[I].IsFavourite then
    begin
      gGameSettings.FavouriteMaps.Add(fMaps[I].MapAndDatCRC);
      gServerSettings.ServerMapsRoster.Add(fMaps[I].CRC);
    end else
    begin
      gGameSettings.FavouriteMaps.Remove(fMaps[I].MapAndDatCRC);
      gServerSettings.ServerMapsRoster.Remove(fMaps[I].CRC);
    end;

    ColumnBox.Item[aCellY].Cells[0].Pic := fMaps[I].FavouriteMapPic;

    gGameAppSettings.SaveFavouriteMaps;
  finally
    fMaps.Unlock;
  end;
  aHandled := True;
end;


procedure TKMMapsBrowsePanel.RefreshList(aJumpToSelected: Boolean);
var
  I, listI: Integer;
  R: TKMListRow;
  color: Cardinal;
  mapSize: TKMMapSize;
  isMapSkipped: Boolean;
begin
  ColumnBox.Clear;

  if IsCampaignCategory then
  begin
    for I := 0 to High(fCampMaps) do
    begin
      color := fCampMaps[I].GetLobbyColor;
      if fIsFavouritesShown then
      begin
        R := MakeListRow(['', '', fCampMaps[I].Name, '', IntToStr(fCampMapIndices[I] + 1), fCampMaps[I].SizeText],
                         ['', '', '', '', '', fCampMaps[I].Dimensions.ToString],
                         [color, color, color, color, color, color],
                         I);
        R.Cells[1].Pic := MakePic(rxGui, MISSION_MODE_ICON_TEX + Byte(fCampMaps[I].IsFightingMission));
      end
      else
      begin
        R := MakeListRow(['', fCampMaps[I].Name, '', IntToStr(fCampMapIndices[I] + 1), fCampMaps[I].SizeText],
                         ['', '', '', '', fCampMaps[I].Dimensions.ToString],
                         [color, color, color, color, color],
                         I);
        R.Cells[0].Pic := MakePic(rxGui, MISSION_MODE_ICON_TEX + Byte(fCampMaps[I].IsFightingMission));
      end;
      R.Tag := I;
      ColumnBox.AddItem(R);

      if fCampMaps[I].MapAndDatCRC = fPreselectCRC then
        ColumnBox.ItemIndex := I;
    end;

    SelectMapClick(nil);
    Exit;
  end;

  fMaps.Lock;
  try
    listI := 0;
    for I := 0 to fMaps.Count - 1 do
    begin
      isMapSkipped := False;
      if ((fCategory = mkSP) and not fMaps[I].IsSinglePlayerKind)
      or ((fCategory = mkMP) and not fMaps[I].IsMultiPlayerKind)
      or ((fCategory = mkDL) and not fMaps[I].IsDownloadedKind)
      or ((Radio_BuildFight.ItemIndex = 0) and (fMaps[I].MissionMode <> mmBuilding))
      or ((Radio_BuildFight.ItemIndex = 1) and (fMaps[I].MissionMode <> mmFighting))
      or ((Radio_CoopSpecial.ItemIndex = 0) and not fMaps[I].TxtInfo.IsSpecial)
      or ((Radio_CoopSpecial.ItemIndex = 1) and not fMaps[I].TxtInfo.IsCoop)
      or (TrackBar_PlayersCnt.Enabled and (fMaps[I].HumanPlayerCount <> TrackBar_PlayersCnt.Position))
      then
        isMapSkipped := True;

      for mapSize := MAP_SIZE_ENUM_MIN to MAP_SIZE_ENUM_MAX do
        if not CheckBox_Sizes[mapSize].Checked and (fMaps[I].Size = mapSize) then
        begin
          isMapSkipped := True;
          Break;
        end;

      if isMapSkipped then Continue;

      color := fMaps[I].GetLobbyColor;
      if fIsFavouritesShown then
      begin
        R := MakeListRow(['', '', fMaps[I].Name, IntToStr(fMaps[I].HumanPlayerCount), IntToStr(fMaps[I].LocCount), fMaps[I].SizeText],
                         ['', '', '', '', '', fMaps[I].Dimensions.ToString],
                         [color, color, color, color, color, color],
                         I);
        R.Cells[0].Pic := fMaps[I].FavouriteMapPic;
        R.Cells[0].HighlightOnMouseOver := True;
        R.Cells[1].Pic := MakePic(rxGui, MISSION_MODE_ICON_TEX + Byte(fMaps[I].IsFightingMission));
      end
      else
      begin
        R := MakeListRow(['', fMaps[I].Name, IntToStr(fMaps[I].HumanPlayerCount), IntToStr(fMaps[I].LocCount), fMaps[I].SizeText],
                         ['', '', '', '', fMaps[I].Dimensions.ToString],
                         [color, color, color, color, color],
                         I);
        R.Cells[0].Pic := MakePic(rxGui, MISSION_MODE_ICON_TEX + Byte(fMaps[I].IsFightingMission));
      end;
      R.Tag := I;
      ColumnBox.AddItem(R);

      if (fMaps[I].MapAndDatCRC = fPreselectCRC)
      and ((not IsMultiplayerCategory) or (fMaps[I].Name = fPreselectName)) then
        ColumnBox.ItemIndex := listI;
      Inc(listI);
    end;
  finally
    fMaps.Unlock;
  end;

  if aJumpToSelected and ColumnBox.IsSelected
  and not InRange(ColumnBox.ItemIndex - ColumnBox.TopIndex, 0, ColumnBox.GetVisibleRows - 1) then
    if ColumnBox.ItemIndex < ColumnBox.TopIndex then
      ColumnBox.TopIndex := ColumnBox.ItemIndex
    else
    if ColumnBox.ItemIndex > ColumnBox.TopIndex + ColumnBox.GetVisibleRows - 1 then
      ColumnBox.TopIndex := ColumnBox.ItemIndex - ColumnBox.GetVisibleRows + 1;

  SelectMapClick(nil);
end;


procedure TKMMapsBrowsePanel.SelectMapClick(Sender: TObject);
begin
  if HasSelection then
  begin
    fMaps.Lock;
    try
      UpdateMapInfo(ColumnBox.SelectedItemTag);
    finally
      fMaps.Unlock;
    end;
  end
  else
    UpdateMapInfo(-1);

  if Assigned(fOnSelectionChanged) then
    fOnSelectionChanged(Self);
end;


procedure TKMMapsBrowsePanel.DoubleClick(Sender: TObject);
begin
  if Assigned(fOnMapDoubleClick) then
    fOnMapDoubleClick(Self);
end;


procedure TKMMapsBrowsePanel.UpdateMapInfo(aID: Integer);

  function AddLabelDesc(aLabelDesc: UnicodeString; const aAddition: UnicodeString): UnicodeString;
  begin
    if aLabelDesc <> '' then
      aLabelDesc := aLabelDesc + '|';
    Result := aLabelDesc + aAddition;
  end;

var
  map: TKMMapInfo;
  labelHeight: Integer;
begin
  if aID = -1 then
  begin
    fMinimapLastListId := -1;
    MinimapView.Hide;
    Memo_Desc.Clear;
    Label_MapType.Hide;
    Button_ViewReadme.Hide;
    Exit;
  end;

  if fMinimapLastListId = aID then
    Exit;
  fMinimapLastListId := aID;

  map := GetDisplayedMap(aID);
  fMinimap.LoadFromMission(map.FullPath('.dat'), []);
  fMinimap.Update(True);
  MinimapView.Show;
  map.LoadExtra;
  if IsCampaignCategory and (ListBox_Campaigns.ItemIndex >= 0) and InRange(aID, 0, High(fCampMapIndices)) then
    Memo_Desc.Text := gGameApp.Campaigns[ListBox_Campaigns.ItemIndex].GetMissionBriefing(fCampMapIndices[aID])
  else
    Memo_Desc.Text := map.BigDesc;

  if map.HasReadme then
    Button_ViewReadme.Show
  else
    Button_ViewReadme.Hide;

  Label_MapType.Caption := '';
  if map.TxtInfo.IsCoop then
    Label_MapType.Caption := AddLabelDesc(Label_MapType.Caption, gResTexts[TX_LOBBY_MAP_COOP]);
  if map.TxtInfo.IsSpecial then
    Label_MapType.Caption := AddLabelDesc(Label_MapType.Caption, gResTexts[TX_LOBBY_MAP_SPECIAL]);
  if map.TxtInfo.IsPlayableAsSP then
    Label_MapType.Caption := AddLabelDesc(Label_MapType.Caption, gResTexts[TX_MENU_MAP_PLAYABLE_AS_SP]);

  if Label_MapType.Caption = '' then
  begin
    Label_MapType.Hide;
    Memo_Desc.Top := MinimapView.Bottom + 10;
  end
  else
  begin
    Label_MapType.Show;
    labelHeight := gRes.Fonts[Label_MapType.Font].GetTextSize(Label_MapType.Caption).Y;
    Memo_Desc.Top := MinimapView.Bottom + 10 + labelHeight;
  end;

  Memo_Desc.Height := Memo_Desc.Parent.Height - Memo_Desc.Top
                      - (Button_ViewReadme.Height + 5) * Byte(Button_ViewReadme.Visible);
  Button_ViewReadme.Top := Memo_Desc.Bottom + 5;
end;


procedure TKMMapsBrowsePanel.ReadmeClick(Sender: TObject);
begin
  if HasSelection then
    TryOpenMapPDF(SelectedMap);
end;


procedure TKMMapsBrowsePanel.TerminateScan;
begin
  fMaps.TerminateScan;
end;


procedure TKMMapsBrowsePanel.UpdateState;
begin
  if fMaps <> nil then
    fMaps.UpdateState;
end;


procedure TKMMapsBrowsePanel.SetVisible(aVisible: Boolean);
begin
  Panel_Filter.Visible := aVisible and not IsCampaignCategory;
  ListBox_Campaigns.Visible := aVisible and IsCampaignCategory;
  ColumnBox.Visible := aVisible;
  MinimapView.Visible := aVisible and HasSelection;
  Memo_Desc.Visible := aVisible;
  Label_MapType.Visible := aVisible and (Label_MapType.Caption <> '');
  Button_ViewReadme.Visible := aVisible and HasSelection and SelectedMap.HasReadme;
end;


procedure TKMMapsBrowsePanel.Focus;
begin
  if ColumnBox.Focusable then
    ColumnBox.Focus;
end;


procedure TKMMapsBrowsePanel.SetListFocusable(aFocusable: Boolean);
begin
  ColumnBox.Focusable := aFocusable;
end;


function TKMMapsBrowsePanel.ContainsMapName(const aName: UnicodeString): Boolean;
var
  I: Integer;
begin
  if IsCampaignCategory then
  begin
    Result := False;
    for I := 0 to High(fCampMaps) do
      if SameText(fCampMaps[I].Name, aName) then
        Exit(True);
  end
  else
    Result := fMaps.Contains(aName);
end;


procedure TKMMapsBrowsePanel.DeleteSelectedMap;
begin
  if HasSelection and not IsCampaignCategory then
    fMaps.DeleteMap(ColumnBox.SelectedItemTag);
end;


procedure TKMMapsBrowsePanel.RenameSelectedMap(const aNewName: UnicodeString);
begin
  if HasSelection and not IsCampaignCategory then
    fMaps.RenameMap(ColumnBox.SelectedItemTag, aNewName);
end;


procedure TKMMapsBrowsePanel.MoveSelectedMap(const aNewName: UnicodeString; aKind: TKMMapKind);
begin
  if HasSelection and not IsCampaignCategory then
    fMaps.MoveMap(ColumnBox.SelectedItemTag, aNewName, aKind);
end;


end.
