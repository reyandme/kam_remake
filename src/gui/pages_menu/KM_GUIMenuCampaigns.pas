unit KM_GUIMenuCampaigns;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLType, {$ENDIF}
  Classes, SysUtils, Math,
  KM_Controls, KM_ControlsBase, KM_ControlsList, KM_ControlsMemo,
  KM_Pics, KM_CommonTypes,
  KM_Campaigns, KM_InterfaceDefaults, KM_InterfaceTypes;


type
  TKMMenuCampaigns = class(TKMMenuPageCommon)
  private
    fOnPageChange: TKMMenuChangeEventText; //will be in ancestor class
    fOnCampaignsScanComplete: TEvent;

    fCampaigns: TKMCampaignsCollection;
    fScanCompleted: Boolean;

    procedure ListChange(Sender: TObject);
    procedure StartClick(Sender: TObject);
    procedure BackClick(Sender: TObject);

    procedure ScanInit;
    procedure ScanUpdate(Sender: TObject);
    procedure ScanTerminate(Sender: TObject);
  protected
    Panel_CampSelect: TKMPanel;
      Panel_Campaigns: TKMPanel;
        ColumnBox_Camps: TKMColumnBox;
        Image_CampsPreview: TKMImage;
        Memo_CampDesc: TKMMemo;
        Button_Camp_Start, Button_Camp_Back: TKMButton;
  public
    constructor Create(aParent: TKMPanel; aCampaigns: TKMCampaignsCollection; aOnPageChange: TKMMenuChangeEventText; aOnCampaignsScanComplete: TEvent);

    procedure RefreshList;
    procedure Show;

    procedure UpdateState;
  end;


implementation
uses
  KM_ResTexts, KM_ResFonts, KM_ResTypes,
  KM_RenderUI,
  KM_GameSettings,
  KM_CampaignClasses;


{ TKMMainMenuInterface }
constructor TKMMenuCampaigns.Create(aParent: TKMPanel; aCampaigns: TKMCampaignsCollection; aOnPageChange: TKMMenuChangeEventText; aOnCampaignsScanComplete: TEvent);
const
  PAD_W = 80;
  PAN_W = 1024 - PAD_W * 2;
  BTN_W = 300;
  BTN_PAD_W = 40;
  LIST_TOP = 30;
  LIST_W = 505;
  LIST_H = 540;
  COL_PAD = 14;
  RIGHT_W = PAN_W - LIST_W - COL_PAD;
  MAP_IMG_W = 337;
  MAP_IMG_H = 252;
  MAP_PAD = 4;
  DESC_PAD_H = 12;
  DESC_TOP = LIST_TOP + MAP_IMG_H + DESC_PAD_H;
  DESC_H = LIST_H - MAP_IMG_H - DESC_PAD_H;
  DESC_W = MAP_IMG_W + 2*MAP_PAD;
begin
  inherited Create(gpCampSelect);

  fCampaigns := aCampaigns;

  fOnCampaignsScanComplete := aOnCampaignsScanComplete;

  // Rescan campaigns on campaigns menu creation (f.e. on game start or game locale change)
  ScanInit;

  fOnPageChange := aOnPageChange;
  OnEscKeyDown := BackClick;

  Panel_CampSelect := TKMPanel.Create(aParent, 0, 0, aParent.Width, aParent.Height);
  Panel_CampSelect.AnchorsStretch;
    Panel_Campaigns := TKMPanel.Create(Panel_CampSelect, PAD_W, 60, PAN_W, aParent.Height - 100);
    Panel_Campaigns.AnchorsStretch;

    TKMLabel.Create(Panel_Campaigns, 0, 0, Panel_Campaigns.Width, 20, gResTexts[TX_MENU_CAMP_HEADER], fntOutline, taCenter).AnchorsCenter;
    ColumnBox_Camps := TKMColumnBox.Create(Panel_Campaigns, 0, LIST_TOP, LIST_W, LIST_H, fntGrey, bsMenu);
    ColumnBox_Camps.SetColumns(fntOutline, [gResTexts[TX_MENU_CAMPAIGNS_TITLE],
                                             gResTexts[TX_MENU_CAMPAIGNS_MAPS_COUNT],
                                             gResTexts[TX_MENU_CAMPAIGNS_MAPS_UNLOCKED]],
                                             [0, 305, 405]);
    ColumnBox_Camps.AnchorsCenter;
    ColumnBox_Camps.SearchColumn := 0;
    ColumnBox_Camps.OnChange := ListChange;
    ColumnBox_Camps.OnDoubleClick := StartClick;

    TKMBevel.Create(Panel_Campaigns, LIST_W + COL_PAD, 30, MAP_IMG_W + 2*MAP_PAD, MAP_IMG_H + 2*MAP_PAD).AnchorsCenter;
    Image_CampsPreview := TKMImage.Create(Panel_Campaigns, LIST_W + COL_PAD + MAP_PAD, 34, MAP_IMG_W, MAP_IMG_H, 0, rxGuiMain);
    Image_CampsPreview.ImageStretch;
    Image_CampsPreview.AnchorsCenter;

    Memo_CampDesc := TKMMemo.Create(Panel_Campaigns, LIST_W + COL_PAD, DESC_TOP, DESC_W, DESC_H, fntGame, bsMenu);
    Memo_CampDesc.AnchorsCenter;
    Memo_CampDesc.WordWrap := True;
    Memo_CampDesc.ItemHeight := 16;

    with TKMLabel.Create(Panel_Campaigns, 0, ColumnBox_Camps.Bottom + 15, 864, 40, gResTexts[TX_MENU_CAMP_HINT], fntGrey, taCenter) do
    begin
      AnchorsCenter;
      WordWrap := True;
    end;

    Button_Camp_Back := TKMButton.Create(Panel_Campaigns, BTN_PAD_W, 620, BTN_W, 30, gResTexts[TX_MENU_BACK], bsMenu);
    Button_Camp_Back.AnchorsCenter;
    Button_Camp_Back.OnClick := BackClick;

    Button_Camp_Start := TKMButton.Create(Panel_Campaigns, PAN_W - BTN_W - BTN_PAD_W, 620, BTN_W, 30, gResTexts[TX_MENU_CAMP_START], bsMenu);
    Button_Camp_Start.AnchorsCenter;
    Button_Camp_Start.OnClick := StartClick;
end;


procedure TKMMenuCampaigns.RefreshList;
var
  I: Integer;
begin
  if Self = nil then Exit;

  Image_CampsPreview.TexID := 0; //Clear preview image
  ColumnBox_Camps.Clear;
  Memo_CampDesc.Clear;
  for I := 0 to fCampaigns.Count - 1 do
  begin
    ColumnBox_Camps.AddItem(MakeListRow(
                        [fCampaigns[I].Spec.GetCampaignTitle, IntToStr(fCampaigns[I].Spec.MissionsCount),
                         IntToStr(fCampaigns[I].SavedData.UnlockedMission + 1)],
                        [$FFFFFFFF, $FFFFFFFF, $FFFFFFFF], I));
    if fCampaigns[I].Spec.IdStr = gGameSettings.MenuCampaignName then
    begin
      ColumnBox_Camps.ItemIndex := I;
      ListChange(nil);
    end;

  end;

  if ColumnBox_Camps.ItemIndex = -1 then
    Button_Camp_Start.Disable
  else
    Button_Camp_Start.Enable;
end;


procedure TKMMenuCampaigns.ListChange(Sender: TObject);
var
  cmpID: TKMCampaignId;
  camp: TKMCampaign;
begin
  //Key press can cause ItemIndex = -1
  if ColumnBox_Camps.ItemIndex = -1 then
  begin
    Button_Camp_Start.Disable;
    Image_CampsPreview.TexID := 0;
    Memo_CampDesc.Clear;
  end
  else
  begin
    Button_Camp_Start.Enable;
    cmpID := fCampaigns[ColumnBox_Camps.Rows[ColumnBox_Camps.ItemIndex].Tag].Spec.CampaignId;
    camp := fCampaigns.CampaignById(cmpID);

    Image_CampsPreview.RX := camp.BackGroundPic.RX;
    Image_CampsPreview.TexID := camp.BackGroundPic.ID;

    Memo_CampDesc.Text := camp.Spec.GetCampaignDescription;
    gGameSettings.MenuCampaignName := camp.Spec.IdStr;
  end;
end;


procedure TKMMenuCampaigns.StartClick(Sender: TObject);
var
  cmp: UnicodeString;
begin
  if ColumnBox_Camps.ItemIndex < 0 then Exit;

  //Get the caption and pass it to Campaign selection menu (it will be casted to TKMCampaignName there)
  //so that we avoid cast/uncast/cast along the event chain
  cmp := fCampaigns[ColumnBox_Camps.Rows[ColumnBox_Camps.ItemIndex].Tag].Spec.IdStr;
  fOnPageChange(gpCampaign, cmp);
end;


procedure TKMMenuCampaigns.BackClick(Sender: TObject);
begin
  fOnPageChange(gpSingleplayer);
end;


procedure TKMMenuCampaigns.ScanUpdate(Sender: TObject);
begin
  if not fScanCompleted then  // Don't refresh list, if scan was completed already
    RefreshList; //Don't jump to selected with each scan update
end;


procedure TKMMenuCampaigns.ScanTerminate(Sender: TObject);
begin
  fScanCompleted := True;
  RefreshList; //After scan complete jump to selected item
  if Assigned(fOnCampaignsScanComplete) then
    fOnCampaignsScanComplete();
end;


procedure TKMMenuCampaigns.ScanInit;
begin
  // Reset scan variables
  fScanCompleted := False;

  fCampaigns.Refresh(ScanUpdate, ScanTerminate, ScanTerminate);
end;


procedure TKMMenuCampaigns.Show;
begin
  RefreshList;
  Panel_CampSelect.Show;
end;


procedure TKMMenuCampaigns.UpdateState;
begin
  fCampaigns.UpdateState;
end;


end.
