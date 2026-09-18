unit KM_GUIMapEdMenuMapsBrowse;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils,
  KM_Controls, KM_ControlsBase, KM_ControlsEdit, KM_ControlsSwitch,
  KM_ControlsForm,
  KM_Maps, KM_MapTypes, KM_Campaigns, KM_CommonTypes, KM_Defaults,
  KM_GUIMapsBrowsePanel;

type
  TKMMapEdMapsBrowseMode = (mbUndefined, mbSave, mbLoad);

  TKMMapEdMenuMapsBrowse = class
  private
    fMode: TKMMapEdMapsBrowseMode;
    fOnDone: TNotifyEvent;
    fBrowse: TKMMapsBrowsePanel;

    fOriginalMapCRC: Cardinal;
    fIsOriginalCampaign: Boolean;
    fOriginalCampaignPath: string;
    fOriginalMissionName: string;

    procedure CategoryChange(Sender: TObject);
    procedure BrowseSelectionChanged(Sender: TObject);
    procedure BrowseDoubleClick(Sender: TObject);

    procedure UpdateActionState;
    function GetCampaignMissionSaveName(campaign: TKMCampaign): UnicodeString;
    function IsExistingCampaignMission(campaign: TKMCampaign; const aMissionName: UnicodeString): Boolean;
    procedure RegisterNewCampaignMission(campaign: TKMCampaign);

    procedure NameEditChange(Sender: TObject);
    procedure ExistsCheckClick(Sender: TObject);
    procedure ActionClick(Sender: TObject);
    procedure CancelClick(Sender: TObject);
    procedure FormClosed;
  protected
    Form_MapsBrowse: TKMForm;

      Panel_MapsBrowseFilter: TKMPanel;

      Panel_MapsBrowseList: TKMPanel;
      Panel_MapsBrowsePreview: TKMPanel;

      FilenameEdit_MapsBrowseName: TKMFilenameEdit;
      Label_MapsBrowseExists: TKMLabel;
      CheckBox_MapsBrowseExists: TKMCheckBox;
      Button_MapsBrowseAction, Button_MapsBrowseClose: TKMButton;
  public
    constructor Create(aParent: TKMPanel; aOnDone: TNotifyEvent);
    destructor Destroy; override;

    procedure ShowSave;
    procedure ShowLoad;
    function Visible: Boolean;
    procedure UpdateState;
  end;


implementation
uses
  Math,
  KM_RenderUI,
  KM_ResTexts, KM_ResFonts, KM_Resource, KM_Game, KM_GameApp, KM_GameParams, KM_GameSettings, KM_MapUtils, KM_CommonUtils;


{ TKMMapEdMenuMapsBrowse }
constructor TKMMapEdMenuMapsBrowse.Create(aParent: TKMPanel; aOnDone: TNotifyEvent);
const
  BG_IMAGE_W = 1071;
  BG_IMAGE_H = 822;
  MARGIN_SIDE = 35;
  MARGIN_TOP = 80;
  MARGIN_BOTTOM = 50;
  CONTENT_WIDTH = BG_IMAGE_W - 2*MARGIN_SIDE;
  CONTENT_HEIGHT = BG_IMAGE_H - MARGIN_TOP - MARGIN_BOTTOM;

  TOP_MARGIN = 10;
  FILTER_W = 220;
  LIST_W = 440;
  PREVIEW_W = 199;
  GAP_FILTER_LIST = 25;
  GAP_LIST_PREVIEW = 23;
  COLUMNS_WIDTH = FILTER_W + GAP_FILTER_LIST + LIST_W + GAP_LIST_PREVIEW + PREVIEW_W;
  SIDE_PAD = (CONTENT_WIDTH - COLUMNS_WIDTH) div 2;
  FILTER_LEFT = SIDE_PAD;
  LIST_LEFT = FILTER_LEFT + FILTER_W + GAP_FILTER_LIST;
  PREVIEW_LEFT = LIST_LEFT + LIST_W + GAP_LIST_PREVIEW;
  LIST_H = 576;
  HEADER_H = 20;
  HEADER_GAP = 4;
  PANELS_TOP = TOP_MARGIN + HEADER_H + HEADER_GAP;
  BOTTOM_ROW_GAP = 60;
  BOTTOM_ROW_BASE = PANELS_TOP + LIST_H + BOTTOM_ROW_GAP;
  HEADER_INDENT = 6;
  ITEM_H = 20;
  BUTTON_H = 30;
  NAME_ROW_OFFSET = 45;
  EXISTS_LABEL_OFFSET = 22;
  EXISTS_CHECKBOX_OFFSET = 25;
  EXISTS_LABEL_W = 250;
begin
  inherited Create;

  fOnDone := aOnDone;

  Form_MapsBrowse := TKMForm.Create(aParent, CONTENT_WIDTH, CONTENT_HEIGHT, '', fbYellow, True, False, True);
  Form_MapsBrowse.OnClose := FormClosed;
  Form_MapsBrowse.HandleCloseKey := True;

  TKMLabel.Create(Form_MapsBrowse.ItemsPanel, FILTER_LEFT + HEADER_INDENT, TOP_MARGIN, FILTER_W, HEADER_H, gResTexts[TX_MENU_MAP_FILTER], fntOutline, taLeft);
  TKMLabel.Create(Form_MapsBrowse.ItemsPanel, LIST_LEFT + HEADER_INDENT, TOP_MARGIN, LIST_W, HEADER_H, gResTexts[TX_MENU_MAP_AVAILABLE], fntOutline, taLeft);

  Panel_MapsBrowseFilter := TKMPanel.Create(Form_MapsBrowse.ItemsPanel, FILTER_LEFT, PANELS_TOP, FILTER_W, LIST_H);
  Panel_MapsBrowseFilter.Anchors := [anLeft, anTop];

  Panel_MapsBrowseList := TKMPanel.Create(Form_MapsBrowse.ItemsPanel, LIST_LEFT, PANELS_TOP, LIST_W, LIST_H);
  Panel_MapsBrowseList.Anchors := [anLeft, anTop];

  Panel_MapsBrowsePreview := TKMPanel.Create(Form_MapsBrowse.ItemsPanel, PREVIEW_LEFT, PANELS_TOP, PREVIEW_W, LIST_H);
  Panel_MapsBrowsePreview.Anchors := [anLeft, anTop];

  fBrowse := TKMMapsBrowsePanel.Create(Panel_MapsBrowseFilter, Panel_MapsBrowseList, Panel_MapsBrowsePreview, False);
  fBrowse.OnSelectionChanged := BrowseSelectionChanged;
  fBrowse.OnMapDoubleClick := BrowseDoubleClick;
  fBrowse.OnCategoryChanged := CategoryChange;

  FilenameEdit_MapsBrowseName := TKMFilenameEdit.Create(Form_MapsBrowse.ItemsPanel, LIST_LEFT, BOTTOM_ROW_BASE - NAME_ROW_OFFSET, LIST_W, ITEM_H, fntGrey);
  FilenameEdit_MapsBrowseName.AutoFocusable := False;
  FilenameEdit_MapsBrowseName.OnChange := NameEditChange;

  Label_MapsBrowseExists := TKMLabel.Create(Form_MapsBrowse.ItemsPanel, LIST_LEFT, BOTTOM_ROW_BASE - EXISTS_LABEL_OFFSET, EXISTS_LABEL_W, 0, gResTexts[TX_MAPED_SAVE_EXISTS], fntOutline, taLeft);

  CheckBox_MapsBrowseExists := TKMCheckBox.Create(Form_MapsBrowse.ItemsPanel, LIST_LEFT + EXISTS_LABEL_W, BOTTOM_ROW_BASE - EXISTS_CHECKBOX_OFFSET,
                                                  LIST_W - EXISTS_LABEL_W, ITEM_H, gResTexts[TX_MAPED_SAVE_OVERWRITE], fntMetal);
  CheckBox_MapsBrowseExists.OnClick := ExistsCheckClick;

  Button_MapsBrowseAction := TKMButton.Create(Form_MapsBrowse.ItemsPanel, PREVIEW_LEFT, BOTTOM_ROW_BASE - NAME_ROW_OFFSET, PREVIEW_W, BUTTON_H, '', bsMenu);
  Button_MapsBrowseAction.OnClick := ActionClick;

  Button_MapsBrowseClose := TKMButton.Create(Form_MapsBrowse.ItemsPanel, FILTER_LEFT, BOTTOM_ROW_BASE - NAME_ROW_OFFSET, FILTER_W, BUTTON_H, gResTexts[TX_WORD_CLOSE], bsMenu);
  Button_MapsBrowseClose.OnClick := CancelClick;

  Form_MapsBrowse.Hide;
end;


destructor TKMMapEdMenuMapsBrowse.Destroy;
begin
  FreeAndNil(fBrowse);

  inherited;
end;


procedure TKMMapEdMenuMapsBrowse.CategoryChange(Sender: TObject);
begin
  FilenameEdit_MapsBrowseName.Visible := fMode = mbSave;

  UpdateActionState;
end;


procedure TKMMapEdMenuMapsBrowse.BrowseSelectionChanged(Sender: TObject);
begin
  if (fMode = mbSave) and fBrowse.HasSelection then
    FilenameEdit_MapsBrowseName.SetTextSilently(fBrowse.SelectedMap.Name);

  UpdateActionState;
end;


procedure TKMMapEdMenuMapsBrowse.BrowseDoubleClick(Sender: TObject);
begin
  ActionClick(nil);
end;


procedure TKMMapEdMenuMapsBrowse.NameEditChange(Sender: TObject);
begin
  if fMode = mbSave then
    fBrowse.SelectByName(Trim(FilenameEdit_MapsBrowseName.Text));

  UpdateActionState;
end;


function TKMMapEdMenuMapsBrowse.GetCampaignMissionSaveName(campaign: TKMCampaign): UnicodeString;
var
  missionName: UnicodeString;
begin
  missionName := Trim(FilenameEdit_MapsBrowseName.Text);
  Result := campaign.Path + missionName + PathDelim + missionName + '.dat';
end;


function TKMMapEdMenuMapsBrowse.IsExistingCampaignMission(campaign: TKMCampaign; const aMissionName: UnicodeString): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to campaign.Spec.MissionsCount - 1 do
    if SameText(campaign.GetMissionName(I), aMissionName) then
      Exit(True);
end;


procedure TKMMapEdMenuMapsBrowse.RegisterNewCampaignMission(campaign: TKMCampaign);
const
  DEFAULT_FLAG_OFFSET = 20;
var
  newIndex: Integer;
begin
  newIndex := campaign.Spec.MissionsCount;
  campaign.Spec.MissionsCount := newIndex + 1;
  campaign.SavedData.SetMapsCount(campaign.Spec.MissionsCount);

  if newIndex > 0 then
  begin
    campaign.Spec.Maps[newIndex].Flag.X := campaign.Spec.Maps[newIndex - 1].Flag.X + DEFAULT_FLAG_OFFSET;
    campaign.Spec.Maps[newIndex].Flag.Y := campaign.Spec.Maps[newIndex - 1].Flag.Y + DEFAULT_FLAG_OFFSET;
  end
  else
  begin
    campaign.Spec.Maps[newIndex].Flag.X := 512;
    campaign.Spec.Maps[newIndex].Flag.Y := 384;
  end;

  campaign.Spec.SaveToFile(campaign.Path + 'info.cmp');
end;


procedure TKMMapEdMenuMapsBrowse.UpdateActionState;

  function GetSaveName: UnicodeString;
  begin
    Result := TKMapsCollection.FullPath(Trim(FilenameEdit_MapsBrowseName.Text), '.dat', fBrowse.IsMultiplayerCategory);
  end;

  function IsSameAsOriginal: Boolean;
  var
    campaign: TKMCampaign;
  begin
    if fBrowse.IsCampaignCategory then
    begin
      if not fIsOriginalCampaign or (fBrowse.SelectedCampaignIndex < 0) then Exit(False);
      campaign := gGameApp.Campaigns[fBrowse.SelectedCampaignIndex];
      Result := SameFileName(ExcludeTrailingPathDelimiter(campaign.Path), ExcludeTrailingPathDelimiter(fOriginalCampaignPath))
                and SameText(Trim(FilenameEdit_MapsBrowseName.Text), fOriginalMissionName);
    end
    else
      Result := False;
  end;

begin
  if fMode = mbSave then
  begin
    if fBrowse.IsCampaignCategory and (fBrowse.SelectedCampaignIndex < 0) then
    begin
      CheckBox_MapsBrowseExists.Enabled := False;
      Button_MapsBrowseAction.Enabled := False;
    end
    else
    begin
      if IsSameAsOriginal then
        CheckBox_MapsBrowseExists.Enabled := False
      else if fBrowse.IsCampaignCategory then
        CheckBox_MapsBrowseExists.Enabled := fBrowse.ContainsMapName(Trim(FilenameEdit_MapsBrowseName.Text))
      else
        CheckBox_MapsBrowseExists.Enabled := FileExists(GetSaveName);

      Button_MapsBrowseAction.Enabled := not CheckBox_MapsBrowseExists.Enabled and FilenameEdit_MapsBrowseName.IsValid;
    end;
    Label_MapsBrowseExists.Visible := CheckBox_MapsBrowseExists.Enabled;
    CheckBox_MapsBrowseExists.Visible := CheckBox_MapsBrowseExists.Enabled;
    CheckBox_MapsBrowseExists.Checked := False;
  end
  else
  begin
    Label_MapsBrowseExists.Visible := False;
    CheckBox_MapsBrowseExists.Visible := False;
    Button_MapsBrowseAction.Enabled := fBrowse.HasSelection;
  end;
end;


procedure TKMMapEdMenuMapsBrowse.ExistsCheckClick(Sender: TObject);
begin
  Button_MapsBrowseAction.Enabled := CheckBox_MapsBrowseExists.Checked;
end;


procedure TKMMapEdMenuMapsBrowse.ActionClick(Sender: TObject);
var
  map: TKMMapInfo;
  campaign: TKMCampaign;
  saveName, missionName: UnicodeString;
begin
  if fMode = mbSave then
  begin
    if fBrowse.IsCampaignCategory then
    begin
      if fBrowse.SelectedCampaignIndex < 0 then
        Exit;
      campaign := gGameApp.Campaigns[fBrowse.SelectedCampaignIndex];
      missionName := Trim(FilenameEdit_MapsBrowseName.Text);

      if not IsExistingCampaignMission(campaign, missionName)
      and SameText(missionName, campaign.GetMissionName(campaign.Spec.MissionsCount)) then
        RegisterNewCampaignMission(campaign);

      saveName := GetCampaignMissionSaveName(campaign);
    end
    else
      saveName := TKMapsCollection.FullPath(Trim(FilenameEdit_MapsBrowseName.Text), '.dat', fBrowse.IsMultiplayerCategory);

    gGame.SaveMapEditor(saveName);
    gGame.ActiveInterface.SyncUI(False);

    Form_MapsBrowse.Hide;
    FormClosed;
  end
  else
  begin
    if not fBrowse.HasSelection then
      Exit;
    map := fBrowse.SelectedMap;

    fBrowse.TerminateScan;
    gGameApp.NewGameMapEditor(map.FullPath('.dat'), fBrowse.IsMultiplayerCategory or fBrowse.IsDownloadedCategory);
  end;
end;


procedure TKMMapEdMenuMapsBrowse.CancelClick(Sender: TObject);
begin
  Form_MapsBrowse.Hide;
  FormClosed;
end;


procedure TKMMapEdMenuMapsBrowse.FormClosed;
begin
  fBrowse.TerminateScan;
  if Assigned(fOnDone) then
    fOnDone(Self);
end;


function TKMMapEdMenuMapsBrowse.Visible: Boolean;
begin
  Result := Form_MapsBrowse.Visible;
end;


procedure TKMMapEdMenuMapsBrowse.UpdateState;
begin
  fBrowse.UpdateState;
end;


procedure TKMMapEdMenuMapsBrowse.ShowSave;
var
  isNewUnsavedMap: Boolean;
  saveCategory: TKMMapKind;
  suggestedName: UnicodeString;
  fallbackCampaign: TKMCampaign;
begin
  fMode := mbSave;
  Form_MapsBrowse.Caption := gResTexts[TX_MAPED_SAVE_TITLE];
  Button_MapsBrowseAction.Caption := gResTexts[TX_MAPED_SAVE];

  fOriginalMapCRC := gGameParams.MapSimpleCRC;
  fIsOriginalCampaign := IsCampaignMissionPathRel(gGameParams.MissionFileRel);
  isNewUnsavedMap := gGameParams.MissionFileRel = '';
  suggestedName := gGameParams.Name;

  if fIsOriginalCampaign then
  begin
    fOriginalCampaignPath := ExtractFileDir(ExtractFileDir(ExeDir + gGameParams.MissionFileRel)) + PathDelim;
    fOriginalMissionName := gGameParams.Name;
    saveCategory := mkCM;
  end
  else
  begin
    fOriginalCampaignPath := '';
    fOriginalMissionName := '';
    saveCategory := mkSP;
    if isNewUnsavedMap then
      case gGameSettings.MenuMapEdMapType of
        1:  saveCategory := mkMP;
        2:  if InRange(gGameSettings.MenuMapEdCMIndex, 0, gGameApp.Campaigns.Count - 1) then
            begin
              fIsOriginalCampaign := True;
              fallbackCampaign := gGameApp.Campaigns[gGameSettings.MenuMapEdCMIndex];
              fOriginalCampaignPath := fallbackCampaign.Path;
              saveCategory := mkCM;
              suggestedName := fallbackCampaign.GetMissionName(fallbackCampaign.Spec.MissionsCount);
            end;
      end;
  end;

  fBrowse.SetPreselect(fOriginalMapCRC, gGameParams.Name, fOriginalCampaignPath);
  FilenameEdit_MapsBrowseName.Text := suggestedName;

  fBrowse.Refresh;
  fBrowse.SetCategory(saveCategory);
  CategoryChange(nil);

  Form_MapsBrowse.Show;
end;


procedure TKMMapEdMenuMapsBrowse.ShowLoad;
begin
  fMode := mbLoad;
  Form_MapsBrowse.Caption := gResTexts[TX_MAPED_LOAD_TITLE];
  Button_MapsBrowseAction.Caption := gResTexts[TX_MAPED_LOAD];

  fOriginalMapCRC := gGameParams.MapSimpleCRC;
  fIsOriginalCampaign := IsCampaignMissionPathRel(gGameParams.MissionFileRel);
  if fIsOriginalCampaign then
  begin
    fOriginalCampaignPath := ExtractFileDir(ExtractFileDir(ExeDir + gGameParams.MissionFileRel)) + PathDelim;
    fOriginalMissionName := gGameParams.Name;
  end
  else
  begin
    fOriginalCampaignPath := '';
    fOriginalMissionName := '';
  end;

  fBrowse.SetPreselect(fOriginalMapCRC, gGameParams.Name, fOriginalCampaignPath);

  fBrowse.Refresh;
  if fIsOriginalCampaign then
    fBrowse.SetCategory(mkCM)
  else
    fBrowse.SetCategory(mkSP);
  CategoryChange(nil);

  Form_MapsBrowse.Show;
end;


end.
