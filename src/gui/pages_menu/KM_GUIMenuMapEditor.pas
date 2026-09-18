unit KM_GUIMenuMapEditor;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLType, {$ENDIF}
  Classes, SysUtils, Math,
  KM_Controls, KM_ControlsBase, KM_ControlsEdit, KM_ControlsList, KM_ControlsMemo, KM_ControlsMinimapView,
  KM_ControlsForm, KM_ControlsSwitch, KM_ControlsTrackBar, KM_ControlsTypes,
  KM_Maps, KM_MapTypes, KM_MinimapMission, KM_Campaigns,
  KM_InterfaceDefaults, KM_InterfaceTypes, KM_Defaults, KM_GameTypes,
  KM_GUIMapsBrowsePanel, KM_GUICampaignMapView;


type
  TKMSelectedMapInfo = record
    CRC: Cardinal;
    Name: UnicodeString;
  end;

  TKMMenuMapEditor = class(TKMMenuPageCommon)
  private
    fOnPageChange: TKMMenuChangeEventText; //will be in ancestor class

    fBrowse: TKMMapsBrowsePanel;
    fMinimap: TKMMinimapMission;
    fMinimapLastListId: Integer;  // column id, on which last time minimap was loaded. Avoid multiple loads of same minimap, which could happen on every RefreshList

    fSelectedMapInfo: TKMSelectedMapInfo; // Identification info about last selected map

    fCampMaps: array of TKMMapInfo;
    fCampMapIndices: array of Byte;

    procedure FreeCampMaps;
    function GetDisplayedMap(aIndex: Integer): TKMMapInfo;
    function IsCampaignTab: Boolean;

    procedure RefreshCampaignsList;
    procedure UpdateCampInfo;
    procedure MissionMoveClick(Sender: TObject);
    procedure SelectCampaign(Sender: TObject);
    procedure CampaignCreateClick(Sender: TObject);
    procedure EditCampaignChange(Sender: TObject);
    procedure CampaignEditOkClick(Sender: TObject);
    procedure CampaignEditCancelClick(Sender: TObject);
    procedure CampaignMapEditClick(Sender: TObject);

    procedure CreateNewClick(Sender: TObject);
    procedure SizeChangeByRadio(Sender: TObject);
    procedure SizeChangeByEdit(Sender: TObject);
    procedure NewMapNumEdFocusChanged(Sender: TObject; aValue: Boolean);
    procedure NewMapEnsureNumEdValues;
    procedure UpdateRadioMapEdSizes;
    procedure MapCreateConfirmClick(Sender: TObject);
    procedure MapCreateCancelClick(Sender: TObject);
    procedure LoadExistingClick(Sender: TObject);
    procedure BrowseCategoryChanged(Sender: TObject);
    procedure UpdateSelectedMapCRC;
    procedure UpdateUI;
    procedure SetSelectedMapInfo(aID: Integer = -1); overload;
    procedure SetSelectedMapInfo(aCRC: Cardinal; const aName: UnicodeString); overload;

    procedure RefreshAll;

    procedure BrowseSelectionChanged(Sender: TObject);

    procedure Radio_MapSizes_HeightChange(Sender: TObject; const aValue: Integer);

    procedure RefreshList(aJumpToSelected: Boolean);
    procedure UpdateMapInfo(aID: Integer = -1);
    procedure ReadmeClick(Sender: TObject);
    procedure CampaignVictoryVideoClick(Sender: TObject);
    function MissionHasVictoryVideo(const aMissionDir: string): Boolean;
    procedure SelectMap(Sender: TObject);
    procedure BackClick(Sender: TObject);
    procedure DeleteClick(Sender: TObject);
    procedure DeleteConfirm(aVisible: Boolean);
    procedure RenameClick(Sender: TObject);
    procedure Edit_Rename_Change(Sender: TObject);
    procedure RenameConfirm(aVisible: Boolean);
    procedure MoveConfirm(aVisible: Boolean);
    procedure MoveEditChange(Sender: TObject);
    procedure MoveClick(Sender: TObject);
    procedure EscKeyDown(Sender: TObject);
    procedure KeyDown(Sender: TObject; Key: Word; Shift: TShiftState);
  protected
    Panel_MapEd: TKMPanel;

      Panel_MapFilter: TKMPanel;
        Panel_MapFilterOptions: TKMPanel;

      Panel_Campaigns: TKMPanel;
        ListBox_Campaigns: TKMListBox;
        MapView_Campaign: TKMCampaignMapView;
        Button_CampaignsNew, Button_CampaignMapEdit: TKMButton;

      Panel_MapEdLoad: TKMPanel;
        Label_MapAvailable: TKMLabel;
        Panel_MapEdListSlot: TKMPanel;
        ColumnBox_MapEd: TKMColumnBox;
        Button_MapMove, Button_MapRename, Button_MapCreate, Button_MapDelete, Button_Load: TKMButton;
        Button_MissionMoveUp, Button_MissionMoveDown: TKMButton;


      Panel_MapInfo: TKMPanel;
        Panel_MapEdPreviewSlot: TKMPanel;
        MinimapView_MapEd: TKMMinimapView;
        Label_MapType: TKMLabel;
        Memo_MapDesc: TKMMemo;
        Button_ViewReadme: TKMButton;
        Button_CampaignVictoryVideo: TKMButton;

      //Popups
      Form_Delete: TKMForm;
        Image_Delete: TKMImage;
        Button_MapDeleteConfirm, Button_MapDeleteCancel: TKMButton;
        Label_MapDeleteConfirmTitle, Label_MapDeleteConfirm: TKMLabel;

      Form_Rename: TKMForm;
        Image_Rename: TKMImage;
        Label_RenameTitle, Label_RenameName: TKMLabel;
        FilenameEdit_Rename: TKMFilenameEdit;
        Button_MapRenameConfirm, Button_MapRenameCancel: TKMButton;

      Form_Move: TKMForm;
        Image_Move: TKMImage;
        Button_MapMoveConfirm, Button_MapMoveCancel: TKMButton;
        FilenameEdit_MapMove: TKMFilenameEdit;
        Label_MoveExists: TKMLabel;
        CheckBox_MoveExists: TKMCheckBox;
        Label_MapMoveConfirmTitle, Label_MapMoveName: TKMLabel;

      Form_CampaignEdit: TKMForm;
        Image_CampaignEdit: TKMImage;
        Label_CampaignEditTitle: TKMLabel;
        Label_CampaignEditId, Label_CampaignEditDir: TKMLabel;
        Edit_CampaignId, Edit_CampaignDirectoryName: TKMEdit;
        Button_CampaignEditOk, Button_CampaignEditCancel: TKMButton;

      Form_MapCreate: TKMForm;
        Image_MapCreate: TKMImage;
        Label_MapCreateTitle: TKMLabel;
        Label_MapCreateWidth, Label_MapCreateHeight: TKMLabel;
        Radio_NewMapSizeX, Radio_NewMapSizeY: TKMRadioGroup;
        NumEdit_MapSizeX, NumEdit_MapSizeY: TKMNumericEdit;
        Button_MapCreateConfirm, Button_MapCreateCancel: TKMButton;

      Button_MapEdBack: TKMButton;
  public
    OnNewMapEditor: TKMNewMapEditorEvent;

    constructor Create(aParent: TKMPanel; aOnPageChange: TKMMenuChangeEventText);
    destructor Destroy; override;
    procedure Show;
    procedure UpdateState;
    procedure RefreshCampaign;
  end;


implementation
uses
  KM_CommonTypes, KM_ResTexts,
  KM_GameSettings, KM_ServerSettings,
  KM_RenderUI, KM_Pics,
  KM_Resource, KM_ResFonts, KM_ResTypes,
  KM_CommonUtils, KM_MapUtilsExt,
  KM_CampaignClasses, KM_CampaignUtils, KM_GameApp, KM_Log,
  KM_GameAppSettings,
  KM_Video;

const
  MAPSIZES_COUNT = 8;
  MapSize: array [0..MAPSIZES_COUNT-1] of Word = (32, 64, 96, 128, 160, 192, 224, 256);

  CAMP_EDIT_CONTENT_W = 330;
  CAMP_EDIT_CONTENT_H = 130;
  CAMP_EDIT_TITLE_TOP = 20;
  CAMP_EDIT_FIELDS_TOP = 60;
  CAMP_EDIT_FIELD_W = 280;
  CAMP_EDIT_ITEM_H = 20;
  CAMP_EDIT_LABEL_GAP = 2;
  CAMP_EDIT_FIELD_GAP = 20;
  CAMP_EDIT_BUTTONS_GAP = 26;
  CAMP_EDIT_BUTTON_W = 135;
  CAMP_EDIT_BUTTON_H = 30;
  CAMP_EDIT_BUTTON_SPACING = 10;


{ TKMGUIMainMapEditor }
constructor TKMMenuMapEditor.Create(aParent: TKMPanel; aOnPageChange: TKMMenuChangeEventText);
var
  I: Integer;
  mapCreateContentLeft: Integer;
  campEditLeft, campEditTop: Integer;
begin
  inherited Create(gpMapEditor);

  fOnPageChange := aOnPageChange;
  OnEscKeyDown := EscKeyDown;
  OnKeyDown := KeyDown;

  fMinimap := TKMMinimapMission.Create(True);

  Panel_MapEd := TKMPanel.Create(aParent, 0, 0, aParent.Width, aParent.Height);
  Panel_MapEd.AnchorsStretch;

    Panel_MapFilter := TKMPanel.Create(Panel_MapEd, 60, 30, 220, 500);
    Panel_MapFilter.Anchors := [anLeft, anTop];
      TKMLabel.Create(Panel_MapFilter, 6, 0, Panel_MapFilter.Width, 20, gResTexts[TX_MENU_MAP_FILTER], fntOutline, taLeft);

      Panel_MapFilterOptions := TKMPanel.Create(Panel_MapFilter, 0, 20, Panel_MapFilter.Width, Panel_MapFilter.Height - 20);
      Panel_MapFilterOptions.Anchors := [anLeft, anTop];

    Panel_MapEdLoad := TKMPanel.Create(Panel_MapEd, 305, 30, 440, 708);
    Panel_MapEdLoad.Anchors := [anLeft, anTop, anBottom];
      Label_MapAvailable := TKMLabel.Create(Panel_MapEdLoad, 6, 0, Panel_MapEdLoad.Width - 12, 20, gResTexts[TX_MENU_MAP_AVAILABLE], fntOutline, taLeft);

      Panel_MapEdListSlot := TKMPanel.Create(Panel_MapEdLoad, 0, 20, 440, 576);
      Panel_MapEdListSlot.Anchors := [anLeft, anTop, anBottom];

      ColumnBox_MapEd := TKMColumnBox.Create(Panel_MapEdLoad, 0, 20, 440, 576, fntMetal,  bsMenu);
      ColumnBox_MapEd.Anchors := [anLeft, anTop, anBottom];
      ColumnBox_MapEd.SetColumns(fntOutline, ['', '', gResTexts[TX_MENU_MAP_TITLE], gResTexts[TX_MENU_MAP_HUMAN_TITLE], '#',
                                              gResTexts[TX_MENU_MAP_SIZE]],
                                             [0, 22, 44, 310, 335, 360]);
      ColumnBox_MapEd.SearchColumn := 2;
      ColumnBox_MapEd.OnChange := SelectMap;
      ColumnBox_MapEd.OnDoubleClick := LoadExistingClick;
      ColumnBox_MapEd.ShowHintWhenShort := True;
      ColumnBox_MapEd.HintBackColor := TKMColor4f.New(149, 128, 69); //Dark yellow color

      Button_Load := TKMButton.Create(Panel_MapEdLoad, 0, 606, 440, 30, gResTexts[TX_MENU_MAP_LOAD_EXISTING], bsMenu);
      Button_Load.Anchors := [anLeft, anBottom];
      Button_Load.OnClick := LoadExistingClick;

      Button_MapMove := TKMButton.Create(Panel_MapEdLoad, 0, 642, 440, 30, gResTexts[TX_MENU_MAP_MOVE_DOWNLOAD], bsMenu);
      Button_MapMove.Anchors := [anLeft, anBottom];
      Button_MapMove.OnClick := MoveClick;
      Button_MapMove.Hide;

      Button_MapRename := TKMButton.Create(Panel_MapEdLoad, 0, 642, 440, 30, gResTexts[TX_MENU_MAP_RENAME], bsMenu);
      Button_MapRename.Anchors := [anLeft, anBottom];
      Button_MapRename.OnClick := RenameClick;

      Button_MissionMoveUp := TKMButton.Create(Panel_MapEdLoad, 0, 642, Panel_MapEdLoad.Width div 2 - 4, 30, gResTexts[TX_MENU_MISSION_MOVE_UP], bsMenu);
      Button_MissionMoveUp.Anchors := [anLeft, anBottom];
      Button_MissionMoveUp.OnClick := MissionMoveClick;

      Button_MissionMoveDown := TKMButton.Create(Panel_MapEdLoad, Panel_MapEdLoad.Width div 2 + 4, 642, Panel_MapEdLoad.Width div 2 - 4, 30,
                                                 gResTexts[TX_MENU_MISSION_MOVE_DOWN], bsMenu);
      Button_MissionMoveDown.Anchors := [anLeft, anBottom];
      Button_MissionMoveDown.OnClick := MissionMoveClick;

      Button_MapCreate := TKMButton.Create(Panel_MapEdLoad, 0, 678, Panel_MapEdLoad.Width div 2 - 4, 30, gResTexts[TX_MENU_MAP_CREATE_NEW_MAP], bsMenu);
      Button_MapCreate.Anchors := [anLeft, anBottom];
      Button_MapCreate.OnClick := CreateNewClick;

      Button_MapDelete := TKMButton.Create(Panel_MapEdLoad, Panel_MapEdLoad.Width div 2 + 4, 678, Panel_MapEdLoad.Width div 2 - 4, 30, gResTexts[TX_MENU_MAP_DELETE], bsMenu);
      Button_MapDelete.Anchors := [anLeft, anBottom];
      Button_MapDelete.OnClick := DeleteClick;

    Panel_MapInfo := TKMPanel.Create(Panel_MapEd, 320+448, 50, 199, 688);
    Panel_MapInfo.Anchors := [anLeft, anTop, anBottom];

      Panel_MapEdPreviewSlot := TKMPanel.Create(Panel_MapInfo, 0, 0, Panel_MapInfo.Width, Panel_MapInfo.Height);
      Panel_MapEdPreviewSlot.Anchors := [anLeft, anTop, anBottom];

      MinimapView_MapEd := TKMMinimapView.Create(fMinimap, Panel_MapInfo, 4, 4, 191, 191, True);
      MinimapView_MapEd.Anchors := [anLeft, anTop];

      Label_MapType := TKMLabel.Create(Panel_MapInfo, 0, 199+10, '', fntMetal, taLeft);
      Label_MapType.Anchors := [anLeft, anTop];
      Memo_MapDesc := TKMMemo.Create(Panel_MapInfo, 0, 199+10, 199, Panel_MapInfo.Height - 199 - 10, fntGame, bsMenu);
      Memo_MapDesc.Anchors := [anLeft, anTop, anBottom];
      Memo_MapDesc.WordWrap := True;
      Memo_MapDesc.ItemHeight := 16;

      Button_ViewReadme := TKMButton.Create(Panel_MapInfo, 0, 225, 199, 25, gResTexts[TX_LOBBY_VIEW_README], bsMenu);
      Button_ViewReadme.Anchors := [anLeft, anBottom];
      Button_ViewReadme.OnClick := ReadmeClick;
      Button_ViewReadme.Hide;

      Button_CampaignVictoryVideo := TKMButton.Create(Panel_MapInfo, 0, 255, 199, 25, gResTexts[TX_MENU_CAMPAIGN_VICTORY_VIDEO], bsMenu);
      Button_CampaignVictoryVideo.Anchors := [anLeft, anBottom];
      Button_CampaignVictoryVideo.OnClick := CampaignVictoryVideoClick;
      Button_CampaignVictoryVideo.Hide;

    fBrowse := TKMMapsBrowsePanel.Create(Panel_MapFilterOptions, Panel_MapEdListSlot, Panel_MapEdPreviewSlot, True);
    fBrowse.OnSelectionChanged := BrowseSelectionChanged;
    fBrowse.OnMapDoubleClick := LoadExistingClick;
    fBrowse.OnCategoryChanged := BrowseCategoryChanged;

      Panel_Campaigns := TKMPanel.Create(Panel_MapFilterOptions, 0, fBrowse.ContentTop,
                                         Panel_MapFilterOptions.Width, Panel_MapFilterOptions.Height - fBrowse.ContentTop);
      Panel_Campaigns.Anchors := [anLeft, anTop];

        TKMLabel.Create(Panel_Campaigns, 6, 0, Panel_Campaigns.Width, 20, gResTexts[TX_MENU_CAMPAIGNS], fntOutline, taLeft);

        ListBox_Campaigns := TKMListBox.Create(Panel_Campaigns, 0, 22, Panel_Campaigns.Width, 205, fntMetal, bsMenu);
        ListBox_Campaigns.OnChange := SelectCampaign;

        Button_CampaignsNew := TKMButton.Create(Panel_Campaigns, 0, ListBox_Campaigns.Bottom + 8, Panel_Campaigns.Width, 30, gResTexts[TX_MENU_CAMPAIGN_NEW], bsMenu);
        Button_CampaignsNew.OnClick := CampaignCreateClick;

        MapView_Campaign := TKMCampaignMapView.Create(Panel_Campaigns, 0, Button_CampaignsNew.Bottom + 10, Panel_Campaigns.Width,
                                                      Round(Panel_Campaigns.Width * (MAP_DESIGN_H / MAP_DESIGN_W)), cmPreview);

        Button_CampaignMapEdit := TKMButton.Create(Panel_Campaigns, 0, MapView_Campaign.Bottom + 10, Panel_Campaigns.Width, 30,
                                                   gResTexts[TX_MENU_CAMPAIGN_MAP_EDIT], bsMenu);
        Button_CampaignMapEdit.OnClick := CampaignMapEditClick;
      Panel_Campaigns.Hide;

    Button_MapEdBack := TKMButton.Create(Panel_MapEd, 60, 708, 220, 30, gResTexts[TX_MENU_BACK], bsMenu);
    Button_MapEdBack.Anchors := [anLeft, anBottom];
    Button_MapEdBack.OnClick := BackClick;

      //Delete PopUp
      Form_Delete := TKMForm.Create(Panel_MapEd, 380, 70);
      // Keep the pop-up centered
      Form_Delete.AnchorsCenter;
      Form_Delete.Left := (Panel_MapEd.Width div 2) - (Form_Delete.Width div 2);
      Form_Delete.Top := (Panel_MapEd.Height div 2) - 90;

        TKMBevel.Create(Form_Delete, -2000,  -2000, 5000, 5000);

        Image_Delete := TKMImage.Create(Form_Delete, 0, 0, Form_Delete.Width, Form_Delete.Height, 15, rxGuiMain);
        Image_Delete.ImageStretch;

        Label_MapDeleteConfirmTitle := TKMLabel.Create(Form_Delete, Form_Delete.Width div 2, 40, gResTexts[TX_MENU_MAP_DELETE], fntOutline, taCenter);
        Label_MapDeleteConfirmTitle.Anchors := [anLeft, anBottom];

        Label_MapDeleteConfirm := TKMLabel.Create(Form_Delete, Form_Delete.Width div 2, 85, gResTexts[TX_MENU_MAP_DELETE_CONFIRM], fntMetal, taCenter);
        Label_MapDeleteConfirm.Anchors := [anLeft, anBottom];

        Button_MapDeleteConfirm := TKMButton.Create(Form_Delete, 20, 155, 195, 30, gResTexts[TX_MENU_LOAD_DELETE_DELETE], bsMenu);
        Button_MapDeleteConfirm.Anchors := [anLeft, anBottom];
        Button_MapDeleteConfirm.OnClick := DeleteClick;

        Button_MapDeleteCancel  := TKMButton.Create(Form_Delete, 235, 155, 195, 30, gResTexts[TX_MENU_LOAD_DELETE_CANCEL], bsMenu);
        Button_MapDeleteCancel.Anchors := [anLeft, anBottom];
        Button_MapDeleteCancel.OnClick := DeleteClick;

      Form_Rename := TKMForm.Create(Panel_MapEd, 330, 70);
      // Keep the pop-up centered
      Form_Rename.AnchorsCenter;
      Form_Rename.Left := (Panel_MapEd.Width div 2) - (Form_Rename.Width div 2);
      Form_Rename.Top := (Panel_MapEd.Height div 2) - 90;

        TKMBevel.Create(Form_Rename, -2000,  -2000, 5000, 5000);

        Image_Rename := TKMImage.Create(Form_Rename, 0, 0, Form_Rename.Width, Form_Rename.Height, 15, rxGuiMain);
        Image_Rename.ImageStretch;

        Label_RenameTitle := TKMLabel.Create(Form_Rename, 20, 50, 360, 30, gResTexts[TX_MENU_MAP_RENAME], fntOutline, taCenter);
        Label_RenameTitle.Anchors := [anLeft,anBottom];

        Label_RenameName := TKMLabel.Create(Form_Rename, 25, 100, 60, 20, gResTexts[TX_MENU_REPLAY_RENAME_NAME], fntMetal, taLeft);
        Label_RenameName.Anchors := [anLeft,anBottom];

        FilenameEdit_Rename := TKMFilenameEdit.Create(Form_Rename, 105, 97, 275, 20, fntMetal);
        FilenameEdit_Rename.Anchors := [anLeft,anBottom];
        FilenameEdit_Rename.OnChange := Edit_Rename_Change;

        Button_MapRenameConfirm := TKMButton.Create(Form_Rename, 20, 155, 170, 30, gResTexts[TX_MENU_REPLAY_RENAME_CONFIRM], bsMenu);
        Button_MapRenameConfirm.Anchors := [anLeft,anBottom];
        Button_MapRenameConfirm.OnClick := RenameClick;

        Button_MapRenameCancel := TKMButton.Create(Form_Rename, 210, 155, 170, 30, gResTexts[TX_MENU_LOAD_DELETE_CANCEL], bsMenu);
        Button_MapRenameCancel.Anchors := [anLeft,anBottom];
        Button_MapRenameCancel.OnClick := RenameClick;

      //Move PopUp
      Form_Move := TKMForm.Create(Panel_MapEd, 330, 70);
      // Keep the pop-up centered
      Form_Move.AnchorsCenter;
      Form_Move.Left := (Panel_MapEd.Width div 2) - (Form_Move.Width div 2);
      Form_Move.Top := (Panel_MapEd.Height div 2) - 90;

        TKMBevel.Create(Form_Move, -2000,  -2000, 5000, 5000);

        Image_Move := TKMImage.Create(Form_Move, 0, 0, Form_Move.Width, Form_Move.Height, 15, rxGuiMain);
        Image_Move.ImageStretch;

        Label_MapMoveConfirmTitle := TKMLabel.Create(Form_Move, Form_Move.Width div 2, 40, gResTexts[TX_MENU_MAP_MOVE_DOWNLOAD], fntOutline, taCenter);
        Label_MapMoveConfirmTitle.Anchors := [anLeft, anBottom];

        Label_MapMoveName := TKMLabel.Create(Form_Move, 25, 75, 60, 20, gResTexts[TX_MENU_MAP_MOVE_NAME_TITLE], fntMetal, taLeft);
        Label_MapMoveName.Anchors := [anLeft,anBottom];

        FilenameEdit_MapMove := TKMFilenameEdit.Create(Form_Move, 105, 72, 275, 20, fntGrey);
        FilenameEdit_MapMove.Anchors := [anLeft, anBottom];
        FilenameEdit_MapMove.OnChange := MoveEditChange;

        Label_MoveExists := TKMLabel.Create(Form_Move, 25, 100, gResTexts[TX_MAPED_SAVE_EXISTS], fntOutline, taLeft);
        Label_MoveExists.Anchors := [anLeft, anBottom];
        Label_MoveExists.Hide;
        CheckBox_MoveExists := TKMCheckBox.Create(Form_Move, 25, 125, 300, 20, gResTexts[TX_MAPED_SAVE_OVERWRITE], fntMetal);
        CheckBox_MoveExists.Anchors := [anLeft, anBottom];
        CheckBox_MoveExists.OnClick := MoveEditChange;

        Button_MapMoveConfirm := TKMButton.Create(Form_Move, 20, 150, 170, 30, gResTexts[TX_MENU_MAP_MOVE_CONFIRM], bsMenu);
        Button_MapMoveConfirm.Anchors := [anLeft, anBottom];
        Button_MapMoveConfirm.OnClick := MoveClick;

        Button_MapMoveCancel  := TKMButton.Create(Form_Move, 210, 150, 170, 30, gResTexts[TX_MENU_LOAD_DELETE_CANCEL], bsMenu);
        Button_MapMoveCancel.Anchors := [anLeft, anBottom];
        Button_MapMoveCancel.OnClick := MoveClick;

      Form_CampaignEdit := TKMForm.Create(Panel_MapEd, CAMP_EDIT_CONTENT_W, CAMP_EDIT_CONTENT_H);
      Form_CampaignEdit.AnchorsCenter;
      Form_CampaignEdit.Left := (Panel_MapEd.Width - Form_CampaignEdit.Width) div 2;
      Form_CampaignEdit.Top := (Panel_MapEd.Height - Form_CampaignEdit.Height) div 2;

        TKMBevel.Create(Form_CampaignEdit, -2000,  -2000, 5000, 5000);

        Image_CampaignEdit := TKMImage.Create(Form_CampaignEdit, 0, 0, Form_CampaignEdit.Width, Form_CampaignEdit.Height, 15, rxGuiMain);
        Image_CampaignEdit.ImageStretch;

        campEditLeft := (Form_CampaignEdit.Width - CAMP_EDIT_FIELD_W) div 2;
        campEditTop := CAMP_EDIT_FIELDS_TOP;

        Label_CampaignEditTitle := TKMLabel.Create(Form_CampaignEdit, Form_CampaignEdit.Width div 2, CAMP_EDIT_TITLE_TOP, gResTexts[TX_MAPED_CAMPAIGN_NEW], fntOutline, taCenter);
        Label_CampaignEditTitle.Anchors := [anLeft, anBottom];

        Label_CampaignEditId := TKMLabel.Create(Form_CampaignEdit, campEditLeft, campEditTop, CAMP_EDIT_FIELD_W, CAMP_EDIT_ITEM_H,
                                                gResTexts[TX_MAPED_CAMPAIGN_ID], fntMetal, taLeft);
        Label_CampaignEditId.Anchors := [anLeft, anBottom];
        campEditTop := campEditTop + CAMP_EDIT_ITEM_H + CAMP_EDIT_LABEL_GAP;
        Edit_CampaignId := TKMEdit.Create(Form_CampaignEdit, campEditLeft, campEditTop, CAMP_EDIT_FIELD_W, CAMP_EDIT_ITEM_H, fntMetal);
        Edit_CampaignId.Anchors := [anLeft, anBottom];
        Edit_CampaignId.AllowedChars := acANSI7;
        Edit_CampaignId.MaxLen := 3;
        Edit_CampaignId.IsUpperCase := True;
        Edit_CampaignId.OnChange := EditCampaignChange;
        campEditTop := campEditTop + CAMP_EDIT_ITEM_H + CAMP_EDIT_FIELD_GAP;

        Label_CampaignEditDir := TKMLabel.Create(Form_CampaignEdit, campEditLeft, campEditTop, CAMP_EDIT_FIELD_W, CAMP_EDIT_ITEM_H,
                                                 gResTexts[TX_MAPED_CAMPAIGN_DIRECTORY], fntMetal, taLeft);
        Label_CampaignEditDir.Anchors := [anLeft, anBottom];
        campEditTop := campEditTop + CAMP_EDIT_ITEM_H + CAMP_EDIT_LABEL_GAP;
        Edit_CampaignDirectoryName := TKMEdit.Create(Form_CampaignEdit, campEditLeft, campEditTop, CAMP_EDIT_FIELD_W, CAMP_EDIT_ITEM_H, fntMetal);
        Edit_CampaignDirectoryName.Anchors := [anLeft, anBottom];
        Edit_CampaignDirectoryName.AllowedChars := acFileName;
        Edit_CampaignDirectoryName.MaxLen := 255;
        Edit_CampaignDirectoryName.OnChange := EditCampaignChange;
        campEditTop := campEditTop + CAMP_EDIT_ITEM_H + CAMP_EDIT_BUTTONS_GAP;

        Button_CampaignEditOk := TKMButton.Create(Form_CampaignEdit, campEditLeft, campEditTop, CAMP_EDIT_BUTTON_W, CAMP_EDIT_BUTTON_H, gResTexts[TX_WORD_OK], bsMenu);
        Button_CampaignEditOk.Anchors := [anLeft, anBottom];
        Button_CampaignEditOk.OnClick := CampaignEditOkClick;

        Button_CampaignEditCancel := TKMButton.Create(Form_CampaignEdit, campEditLeft + CAMP_EDIT_BUTTON_W + CAMP_EDIT_BUTTON_SPACING, campEditTop,
                                                      CAMP_EDIT_BUTTON_W, CAMP_EDIT_BUTTON_H, gResTexts[TX_MENU_LOAD_DELETE_CANCEL], bsMenu);
        Button_CampaignEditCancel.Anchors := [anLeft, anBottom];
        Button_CampaignEditCancel.OnClick := CampaignEditCancelClick;

      Form_MapCreate := TKMForm.Create(Panel_MapEd, 280, 250);
      Form_MapCreate.AnchorsCenter;
      Form_MapCreate.Left := (Panel_MapEd.Width div 2) - (Form_MapCreate.Width div 2);
      Form_MapCreate.Top := (Panel_MapEd.Height div 2) - (Form_MapCreate.Height div 2);

        TKMBevel.Create(Form_MapCreate, -2000,  -2000, 5000, 5000);

        Image_MapCreate := TKMImage.Create(Form_MapCreate, 0, 0, Form_MapCreate.Width, Form_MapCreate.Height, 15, rxGuiMain);
        Image_MapCreate.ImageStretch;

        Label_MapCreateTitle := TKMLabel.Create(Form_MapCreate, Form_MapCreate.Width div 2, 20, gResTexts[TX_MENU_NEW_MAP_SIZE], fntOutline, taCenter);
        Label_MapCreateTitle.Anchors := [anLeft, anBottom];

        mapCreateContentLeft := (Form_MapCreate.Width - 220) div 2;

        TKMBevel.Create(Form_MapCreate, mapCreateContentLeft, 60, 220, 250);
        Label_MapCreateWidth := TKMLabel.Create(Form_MapCreate, mapCreateContentLeft + 8, 68, 88, 20, gResTexts[TX_MENU_MAP_WIDTH], fntOutline, taLeft);
        Label_MapCreateWidth.Anchors := [anLeft, anBottom];
        Label_MapCreateHeight := TKMLabel.Create(Form_MapCreate, mapCreateContentLeft + 118, 68, 88, 20, gResTexts[TX_MENU_MAP_HEIGHT], fntOutline, taLeft);
        Label_MapCreateHeight.Anchors := [anLeft, anBottom];

        Radio_NewMapSizeX := TKMRadioGroup.Create(Form_MapCreate, mapCreateContentLeft + 10, 92, 88, 180, fntMetal);
        Radio_NewMapSizeX.Anchors := [anLeft, anBottom];
        Radio_NewMapSizeX.OnHeightChange := Radio_MapSizes_HeightChange;
        Radio_NewMapSizeY := TKMRadioGroup.Create(Form_MapCreate, mapCreateContentLeft + 120, 92, 88, 180, fntMetal);
        Radio_NewMapSizeY.Anchors := [anLeft, anBottom];
        Radio_NewMapSizeY.OnHeightChange := Radio_MapSizes_HeightChange;

        for I := 0 to MAPSIZES_COUNT - 1 do
        begin
          Radio_NewMapSizeX.Add(IntToStr(MapSize[I]));
          Radio_NewMapSizeY.Add(IntToStr(MapSize[I]));
        end;

        Radio_NewMapSizeX.OnChange := SizeChangeByRadio;
        Radio_NewMapSizeY.OnChange := SizeChangeByRadio;

        NumEdit_MapSizeX := TKMNumericEdit.Create(Form_MapCreate, mapCreateContentLeft + 8, Radio_NewMapSizeX.Bottom + 6, MIN_MAP_SIZE, MAX_MAP_SIZE);
        NumEdit_MapSizeY := TKMNumericEdit.Create(Form_MapCreate, mapCreateContentLeft + 118, Radio_NewMapSizeY.Bottom + 6, MIN_MAP_SIZE, MAX_MAP_SIZE);
        NumEdit_MapSizeX.Anchors := [anLeft, anBottom];
        NumEdit_MapSizeY.Anchors := [anLeft, anBottom];
        NumEdit_MapSizeX.AutoFocusable := False;
        NumEdit_MapSizeY.AutoFocusable := False;
        NumEdit_MapSizeX.OnChange := SizeChangeByEdit;
        NumEdit_MapSizeY.OnChange := SizeChangeByEdit;
        NumEdit_MapSizeX.OnFocus := NewMapNumEdFocusChanged;
        NumEdit_MapSizeY.OnFocus := NewMapNumEdFocusChanged;

        Button_MapCreateConfirm := TKMButton.Create(Form_MapCreate, mapCreateContentLeft, 318, 106, 30, gResTexts[TX_MENU_MAP_CREATE], bsMenu);
        Button_MapCreateConfirm.Anchors := [anLeft, anBottom];
        Button_MapCreateConfirm.OnClick := MapCreateConfirmClick;

        Button_MapCreateCancel := TKMButton.Create(Form_MapCreate, mapCreateContentLeft + 114, 318, 106, 30, gResTexts[TX_MENU_LOAD_DELETE_CANCEL], bsMenu);
        Button_MapCreateCancel.Anchors := [anLeft, anBottom];
        Button_MapCreateCancel.OnClick := MapCreateCancelClick;
end;


destructor TKMMenuMapEditor.Destroy;
begin
  FreeCampMaps;
  FreeAndNil(fBrowse);
  fMinimap.Free;

  inherited;
end;


procedure TKMMenuMapEditor.FreeCampMaps;
var
  I: Integer;
begin
  for I := 0 to High(fCampMaps) do
    FreeAndNil(fCampMaps[I]);
  SetLength(fCampMaps, 0);
  SetLength(fCampMapIndices, 0);
end;


function TKMMenuMapEditor.IsCampaignTab: Boolean;
begin
  Result := fBrowse.IsCampaignCategory;
end;


function TKMMenuMapEditor.GetDisplayedMap(aIndex: Integer): TKMMapInfo;
begin
  Result := fCampMaps[aIndex];
end;


procedure TKMMenuMapEditor.CreateNewClick(Sender: TObject);
begin
  NumEdit_MapSizeX.Value := gGameSettings.MenuMapEdNewMapX;
  NumEdit_MapSizeY.Value := gGameSettings.MenuMapEdNewMapY;
  NewMapEnsureNumEdValues;
  UpdateRadioMapEdSizes;

  Form_MapCreate.Show;
end;


procedure TKMMenuMapEditor.MapCreateConfirmClick(Sender: TObject);
begin
  Form_MapCreate.Hide;

  gGameSettings.MenuMapEdNewMapX := NumEdit_MapSizeX.Value;
  gGameSettings.MenuMapEdNewMapY := NumEdit_MapSizeY.Value;

  if Assigned(OnNewMapEditor) then
    OnNewMapEditor('', NumEdit_MapSizeX.Value, NumEdit_MapSizeY.Value);
end;


procedure TKMMenuMapEditor.MapCreateCancelClick(Sender: TObject);
begin
  Form_MapCreate.Hide;
end;


procedure TKMMenuMapEditor.Radio_MapSizes_HeightChange(Sender: TObject; const aValue: Integer);
const
  RADIO_MAPSIZE_LINE_H = 20;
  RADIO_MAPSIZE_LINE_MAX_H = 25;
  // Indexes of new map sizes to skip. First less important
  RADIO_SKIP_SIZES_I: array [0..MAPSIZES_COUNT - 1] of Integer = (1,5,7,3,4,6,0,2);
var
  rg: TKMRadioGroup;
  cnt: Integer;
begin
  rg := TKMRadioGroup(Sender);
  cnt := rg.Count - 1;

  while (rg.LineHeight < RADIO_MAPSIZE_LINE_H)
  and (rg.VisibleCount >= 0)
  and (cnt >= 0) do
  begin
    rg.SetItemVisible(RADIO_SKIP_SIZES_I[cnt], False);
    Dec(cnt);
  end;

  cnt := 0;
  while ((rg.LineHeight > RADIO_MAPSIZE_LINE_MAX_H) or ((rg.LineHeight > RADIO_MAPSIZE_LINE_H) and (rg.VisibleCount = 0)))
  and (cnt < rg.Count) do
  begin
    rg.SetItemVisible(RADIO_SKIP_SIZES_I[cnt], True);
    Inc(cnt);
  end;
end;


procedure TKMMenuMapEditor.NewMapEnsureNumEdValues;
begin
  NumEdit_MapSizeX.Value := EnsureRange(NumEdit_MapSizeX.Value, MIN_MAP_SIZE, MAX_MAP_SIZE);
  NumEdit_MapSizeY.Value := EnsureRange(NumEdit_MapSizeY.Value, MIN_MAP_SIZE, MAX_MAP_SIZE);
end;


procedure TKMMenuMapEditor.NewMapNumEdFocusChanged(Sender: TObject; aValue: Boolean);
begin
  if not aValue then
    NewMapEnsureNumEdValues;
end;


procedure TKMMenuMapEditor.UpdateRadioMapEdSizes;
var
  I: Integer;
begin
  Radio_NewMapSizeX.ItemIndex := -1;
  Radio_NewMapSizeY.ItemIndex := -1;

  for I := 0 to MAPSIZES_COUNT - 1 do
  begin
    if NumEdit_MapSizeX.Value = MapSize[I] then
      Radio_NewMapSizeX.ItemIndex := I;
    if NumEdit_MapSizeY.Value = MapSize[I] then
      Radio_NewMapSizeY.ItemIndex := I;
  end;
end;


procedure TKMMenuMapEditor.SizeChangeByEdit(Sender: TObject);
begin
  UpdateRadioMapEdSizes;

  gGameSettings.MenuMapEdNewMapX := EnsureRange(NumEdit_MapSizeX.Value, MIN_MAP_SIZE, MAX_MAP_SIZE);
  gGameSettings.MenuMapEdNewMapY := EnsureRange(NumEdit_MapSizeY.Value, MIN_MAP_SIZE, MAX_MAP_SIZE);
end;


procedure TKMMenuMapEditor.SizeChangeByRadio(Sender: TObject);
begin
  if Radio_NewMapSizeX.ItemIndex <> -1 then
    NumEdit_MapSizeX.Value := MapSize[Radio_NewMapSizeX.ItemIndex];
  if Radio_NewMapSizeY.ItemIndex <> -1 then
    NumEdit_MapSizeY.Value := MapSize[Radio_NewMapSizeY.ItemIndex];
  gGameSettings.MenuMapEdNewMapX := NumEdit_MapSizeX.Value;
  gGameSettings.MenuMapEdNewMapY := NumEdit_MapSizeY.Value;
end;


procedure TKMMenuMapEditor.LoadExistingClick(Sender: TObject);
var
  map: TKMMapInfo;
begin
  //This is also called by double clicking on a map in the list
  if not Button_Load.Enabled then
    Exit;

  if IsCampaignTab then
  begin
    if not ColumnBox_MapEd.IsSelected then
      Exit;

    map := GetDisplayedMap(ColumnBox_MapEd.SelectedItemTag);

    if Assigned(OnNewMapEditor) then
      OnNewMapEditor(map.FullPath('.dat'), 0, 0, map.CRC, map.MapAndDatCRC, False);
  end
  else
  begin
    if not fBrowse.HasSelection then
      Exit;

    map := fBrowse.SelectedMap;
    fBrowse.TerminateScan;

    if Assigned(OnNewMapEditor) then
      OnNewMapEditor(map.FullPath('.dat'), 0, 0, map.CRC, map.MapAndDatCRC,
                      fBrowse.IsMultiplayerCategory or fBrowse.IsDownloadedCategory);
  end;
end;


procedure TKMMenuMapEditor.BrowseCategoryChanged(Sender: TObject);
begin
  case fBrowse.Category of
    mkMP: gGameSettings.MenuMapEdMapType := 1;
    mkCM: gGameSettings.MenuMapEdMapType := 2;
    mkDL: gGameSettings.MenuMapEdMapType := 3;
  else
    gGameSettings.MenuMapEdMapType := 0;
  end;
  UpdateSelectedMapCRC;

  fBrowse.SetVisible(not IsCampaignTab);
  Panel_Campaigns.Visible := IsCampaignTab;
  ColumnBox_MapEd.Visible := IsCampaignTab;
  Panel_MapEdListSlot.Visible := not IsCampaignTab;
  Panel_MapEdPreviewSlot.Visible := not IsCampaignTab;

  if IsCampaignTab then
  begin
    Label_MapAvailable.Caption := gResTexts[TX_MENU_MAP_AVAILABLE_MISSIONS];
    Button_Load.Caption := gResTexts[TX_MENU_MAP_LOAD_EXISTING_MISSION];
    Button_MapCreate.Caption := gResTexts[TX_MENU_MAP_CREATE_NEW_MISSION];
    Button_MapDelete.Caption := gResTexts[TX_MENU_MAP_DELETE_MISSION];

    Memo_MapDesc.Show;

    fMinimapLastListId := ITEM_NOT_LOADED;
    RefreshCampaignsList;
    UpdateCampInfo;
    RefreshList(True);
  end
  else
  begin
    Label_MapAvailable.Caption := gResTexts[TX_MENU_MAP_AVAILABLE];
    Button_Load.Caption := gResTexts[TX_MENU_MAP_LOAD_EXISTING];
    Button_MapCreate.Caption := gResTexts[TX_MENU_MAP_CREATE_NEW_MAP];
    Button_MapDelete.Caption := gResTexts[TX_MENU_MAP_DELETE];

    MinimapView_MapEd.Hide;
    Label_MapType.Hide;
    Memo_MapDesc.Clear;
    Memo_MapDesc.Hide;
    Button_ViewReadme.Hide;
    Button_CampaignVictoryVideo.Hide;

    fBrowse.SetPreselect(fSelectedMapInfo.CRC, fSelectedMapInfo.Name);
    fBrowse.SetCategory(fBrowse.Category);
  end;

  UpdateUI;
end;


procedure TKMMenuMapEditor.UpdateUI;
var
  realIndex: Integer;
  isSelected: Boolean;
begin
  if IsCampaignTab then
    isSelected := ColumnBox_MapEd.IsSelected
  else
    isSelected := fBrowse.HasSelection;

  Button_Load.Enabled := isSelected;
  Button_MapDelete.Enabled := isSelected;
  Button_MapMove.Visible := not IsCampaignTab and fBrowse.IsDownloadedCategory and fBrowse.HasSelection;
  Button_MapRename.Enabled := isSelected and not IsCampaignTab;
  Button_MapRename.Visible := not IsCampaignTab and not Button_MapMove.Visible;

  Button_MissionMoveUp.Visible := IsCampaignTab;
  Button_MissionMoveDown.Visible := IsCampaignTab;
  if IsCampaignTab and ColumnBox_MapEd.IsSelected and (ListBox_Campaigns.ItemIndex >= 0) then
  begin
    realIndex := fCampMapIndices[ColumnBox_MapEd.SelectedItemTag];
    Button_MissionMoveUp.Enabled := realIndex > 0;
    Button_MissionMoveDown.Enabled := realIndex < gGameApp.Campaigns[ListBox_Campaigns.ItemIndex].Spec.MissionsCount - 1;
  end
  else
  begin
    Button_MissionMoveUp.Enabled := False;
    Button_MissionMoveDown.Enabled := False;
  end;

  if IsCampaignTab then
    UpdateMapInfo(ColumnBox_MapEd.SelectedItemTag);
end;


procedure TKMMenuMapEditor.UpdateSelectedMapCRC;
begin
  fSelectedMapInfo.CRC := 0;
  fSelectedMapInfo.Name := '';
  case fBrowse.Category of
    mkMP: begin
            fSelectedMapInfo.CRC := gGameSettings.MenuMapEdMPMapCRC;
            fSelectedMapInfo.Name := gGameSettings.MenuMapEdMPMapName;
          end;
    mkCM: fSelectedMapInfo.CRC := gGameSettings.MenuMapEdCMMapCRC;
    mkDL: fSelectedMapInfo.CRC := gGameSettings.MenuMapEdDLMapCRC;
  else
    fSelectedMapInfo.CRC := gGameSettings.MenuMapEdSPMapCRC;
  end;
end;


procedure TKMMenuMapEditor.BrowseSelectionChanged(Sender: TObject);
begin
  DeleteConfirm(False);
  MoveConfirm(False);

  if fBrowse.HasSelection then
    SetSelectedMapInfo(fBrowse.SelectedMap.MapAndDatCRC, fBrowse.SelectedMap.Name);

  UpdateUI;
end;


procedure TKMMenuMapEditor.RefreshCampaign;
begin
  if Self = nil then
    Exit;

  if ListBox_Campaigns.Count < gGameApp.Campaigns.Count then
    RefreshCampaignsList;

  UpdateCampInfo;
end;


procedure TKMMenuMapEditor.RefreshCampaignsList;
var
  I: Integer;
begin
  ListBox_Campaigns.Clear;
  for I := 0 to gGameApp.Campaigns.Count - 1 do
    ListBox_Campaigns.Add(gGameApp.Campaigns[I].Spec.GetCampaignTitle);

  if InRange(gGameSettings.MenuMapEdCMIndex, 0, ListBox_Campaigns.Count - 1) then
    ListBox_Campaigns.ItemIndex := gGameSettings.MenuMapEdCMIndex
  else
  if ListBox_Campaigns.Count > 0 then
  begin
    ListBox_Campaigns.ItemIndex := 0;
    gGameSettings.MenuMapEdCMIndex := 0;
  end
  else
    ListBox_Campaigns.ItemIndex := -1;

  if ListBox_Campaigns.ItemIndex >= 0 then
    ListBox_Campaigns.SetTopIndex(ListBox_Campaigns.ItemIndex, True);
end;


procedure TKMMenuMapEditor.UpdateCampInfo;
var
  I, count: Integer;
  campaign: TKMCampaign;
  missionDir, missionName: string;
begin
  FreeCampMaps;

  MapView_Campaign.Visible := ListBox_Campaigns.ItemIndex >= 0;
  Button_CampaignMapEdit.Enabled := ListBox_Campaigns.ItemIndex >= 0;

  if ListBox_Campaigns.ItemIndex < 0 then
    Exit;

  campaign := gGameApp.Campaigns[ListBox_Campaigns.ItemIndex];
  MapView_Campaign.SetCampaign(campaign);

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
end;


procedure TKMMenuMapEditor.SelectCampaign(Sender: TObject);
begin
  gGameSettings.MenuMapEdCMIndex := Math.Max(ListBox_Campaigns.ItemIndex, 0);
  UpdateCampInfo;
  RefreshList(True);
end;


procedure TKMMenuMapEditor.MissionMoveClick(Sender: TObject);
var
  campaign: TKMCampaign;
  realIndex, otherRealIndex: Integer;
begin
  if not IsCampaignTab or (ListBox_Campaigns.ItemIndex < 0) or not ColumnBox_MapEd.IsSelected then
    Exit;

  realIndex := fCampMapIndices[ColumnBox_MapEd.SelectedItemTag];
  if Sender = Button_MissionMoveUp then
    otherRealIndex := realIndex - 1
  else
    otherRealIndex := realIndex + 1;

  campaign := gGameApp.Campaigns[ListBox_Campaigns.ItemIndex];
  if not InRange(otherRealIndex, 0, campaign.Spec.MissionsCount - 1) then
    Exit;

  campaign.SwapMissions(realIndex, otherRealIndex);

  UpdateCampInfo;
  RefreshList(True);
end;


procedure TKMMenuMapEditor.CampaignMapEditClick(Sender: TObject);
begin
  if ListBox_Campaigns.ItemIndex < 0 then
    Exit;

  fOnPageChange(gpCampaignMapEditor, gGameApp.Campaigns[ListBox_Campaigns.ItemIndex].Spec.IdStr);
end;


procedure TKMMenuMapEditor.CampaignCreateClick(Sender: TObject);
begin
  Edit_CampaignId.Text := '';
  Edit_CampaignDirectoryName.Text := '';
  Button_CampaignEditOk.Enabled := False;

  Form_CampaignEdit.Show;
end;


procedure TKMMenuMapEditor.EditCampaignChange(Sender: TObject);
begin
  Button_CampaignEditOk.Enabled := (Edit_CampaignId.Text.Length = 3)
                                and (Trim(Edit_CampaignDirectoryName.Text) <> '')
                                and not DirectoryExists(ExeDir + CAMPAIGNS_FOLDER_NAME + PathDelim + Trim(Edit_CampaignDirectoryName.Text));
end;


procedure TKMMenuMapEditor.CampaignEditOkClick(Sender: TObject);
var
  I: Integer;
  campaignId: TKMCampaignId;
  campaign: TKMCampaign;
begin
  Form_CampaignEdit.Hide;

  campaignId := TKMCampaignId.Create(AnsiString(UpperCase(Edit_CampaignId.Text)));
  campaign := gGameApp.Campaigns.CreateCampaign(campaignId, Trim(Edit_CampaignDirectoryName.Text));

  RefreshCampaignsList;

  for I := 0 to gGameApp.Campaigns.Count - 1 do
    if gGameApp.Campaigns[I] = campaign then
      ListBox_Campaigns.ItemIndex := I;

  ListBox_Campaigns.SetTopIndex(ListBox_Campaigns.ItemIndex, True);
  SelectCampaign(nil);
end;


procedure TKMMenuMapEditor.CampaignEditCancelClick(Sender: TObject);
begin
  Form_CampaignEdit.Hide;
end;


procedure TKMMenuMapEditor.ReadmeClick(Sender: TObject);
var
  ID: Integer;
begin
  ID := ColumnBox_MapEd.SelectedItemTag;
  TryOpenMapPDF(GetDisplayedMap(ID));
end;


function TKMMenuMapEditor.MissionHasVictoryVideo(const aMissionDir: string): Boolean;
var
  searchRec: TSearchRec;
begin
  Result := FindFirst(aMissionDir + 'Victory.*', faAnyFile, searchRec) = 0;
  FindClose(searchRec);
end;


procedure TKMMenuMapEditor.CampaignVictoryVideoClick(Sender: TObject);
var
  ID: Integer;
  map: TKMMapInfo;
begin
  ID := ColumnBox_MapEd.SelectedItemTag;
  map := GetDisplayedMap(ID);
  gVideoPlayer.AddMissionVideo(ExtractRelativePath(ExeDir, map.FullPath('.dat')), 'Victory');
  gVideoPlayer.Play;
end;


procedure TKMMenuMapEditor.RefreshList(aJumpToSelected: Boolean);
var
  I, prevTop: Integer;
  R: TKMListRow;
  color: Cardinal;
begin
  prevTop := ColumnBox_MapEd.TopIndex;
  ColumnBox_MapEd.Clear;

  for I := 0 to High(fCampMaps) do
  begin
    color := fCampMaps[I].GetLobbyColor;
    R := MakeListRow(['', '', fCampMaps[I].Name, '', IntToStr(fCampMapIndices[I] + 1), fCampMaps[I].SizeText],
                     ['', '', '', '', '', fCampMaps[I].Dimensions.ToString],
                     [color, color, color, color, color, color],
                     I);
    R.Cells[1].Pic := MakePic(rxGui, 657 + Byte(fCampMaps[I].IsFightingMission));
    R.Tag := I;
    ColumnBox_MapEd.AddItem(R);

    if fCampMaps[I].MapAndDatCRC = fSelectedMapInfo.CRC then
      ColumnBox_MapEd.ItemIndex := I;
  end;

  ColumnBox_MapEd.TopIndex := prevTop;
  UpdateUI;
end;


procedure TKMMenuMapEditor.SelectMap(Sender: TObject);
var
  mapId: Integer;
begin
  UpdateUI;
  if ColumnBox_MapEd.IsSelected then
  begin
    mapId := ColumnBox_MapEd.SelectedItemTag;

    DeleteConfirm(False);
    MoveConfirm(False);

    SetSelectedMapInfo(mapId);
    UpdateMapInfo(mapId);
  end else
  begin
    SetSelectedMapInfo;
    MinimapView_MapEd.Hide;
  end;
end;


procedure TKMMenuMapEditor.KeyDown(Sender: TObject; Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_RETURN:  if Button_MapDeleteConfirm.IsClickable then
                  DeleteClick(Button_MapDeleteConfirm)
                else if Button_MapRenameConfirm.IsClickable then
                  RenameClick(Button_MapRenameConfirm)
                else if Button_MapMoveConfirm.IsClickable then
                  MoveClick(Button_MapMoveConfirm)
                else if Button_MapCreateConfirm.IsClickable then
                  MapCreateConfirmClick(Button_MapCreateConfirm);
    VK_F2:      RenameClick(Button_MapRename);
    VK_F5:      RefreshAll;
    VK_DELETE:  DeleteClick(Button_MapDelete);
  end;
end;


procedure TKMMenuMapEditor.EscKeyDown(Sender: TObject);
begin
  if Button_MapDeleteCancel.IsClickable then
    DeleteClick(Button_MapDeleteCancel)
  else if Button_MapRenameCancel.IsClickable then
    RenameClick(Button_MapRenameCancel)
  else if Button_MapMoveCancel.IsClickable then
    MoveClick(Button_MapMoveCancel)
  else if Button_MapCreateCancel.IsClickable then
    MapCreateCancelClick(Button_MapCreateCancel)
  else
    BackClick(nil);
end;


procedure TKMMenuMapEditor.BackClick(Sender: TObject);
begin
  fBrowse.TerminateScan;

  // Save settings because we could have updated favourite maps, selected map etc
  gGameAppSettings.SaveSettings;

  fOnPageChange(gpMainMenu);
end;


procedure TKMMenuMapEditor.DeleteClick(Sender: TObject);
var
  isSelected: Boolean;
begin
  if IsCampaignTab then
    isSelected := ColumnBox_MapEd.IsSelected
  else
    isSelected := fBrowse.HasSelection;

  if not isSelected then
    Exit;

  if Sender = Button_MapDelete then
  begin
    if IsCampaignTab then
    begin
      Label_MapDeleteConfirmTitle.Caption := gResTexts[TX_MENU_MAP_DELETE_MISSION];
      Label_MapDeleteConfirm.Caption := gResTexts[TX_MENU_MAP_DELETE_MISSION_CONFIRM];
    end
    else
    begin
      Label_MapDeleteConfirmTitle.Caption := gResTexts[TX_MENU_MAP_DELETE];
      Label_MapDeleteConfirm.Caption := gResTexts[TX_MENU_MAP_DELETE_CONFIRM];
    end;
    DeleteConfirm(True);
  end;

  if (Sender = Button_MapDeleteConfirm) or (Sender = Button_MapDeleteCancel) then
    DeleteConfirm(False);

  if Sender = Button_MapDeleteConfirm then
  begin
    if IsCampaignTab then
    begin
      if (ListBox_Campaigns.ItemIndex >= 0) and InRange(ColumnBox_MapEd.SelectedItemTag, 0, High(fCampMapIndices)) then
      begin
        gGameApp.Campaigns[ListBox_Campaigns.ItemIndex].DeleteMission(fCampMapIndices[ColumnBox_MapEd.SelectedItemTag]);
        UpdateCampInfo;
      end;
      SetSelectedMapInfo;
      RefreshList(True);
    end
    else
    begin
      fBrowse.DeleteSelectedMap;
      SetSelectedMapInfo;
      fBrowse.Refresh;
    end;
  end;
end;


procedure TKMMenuMapEditor.DeleteConfirm(aVisible: Boolean);
begin
  if aVisible then
  begin
    Form_Delete.Show;
    ColumnBox_MapEd.Focusable := False; // Will update focus automatically
    fBrowse.SetListFocusable(False);
  end else
  begin
    Form_Delete.Hide;
    ColumnBox_MapEd.Focusable := True; // Will update focus automatically
    fBrowse.SetListFocusable(True);
  end;
end;


procedure TKMMenuMapEditor.RenameClick(Sender: TObject);
begin
  if IsCampaignTab then
    Exit;
  if not fBrowse.HasSelection then
    Exit;

  if Sender = Button_MapRename then
    RenameConfirm(True);

  if (Sender = Button_MapRenameConfirm) or (Sender = Button_MapRenameCancel) then
    RenameConfirm(False);

  // Change name of the save
  if Sender = Button_MapRenameConfirm then
  begin
    FilenameEdit_Rename.Text := Trim(FilenameEdit_Rename.Text);
    fBrowse.RenameSelectedMap(FilenameEdit_Rename.Text);
    SetSelectedMapInfo(fSelectedMapInfo.CRC, FilenameEdit_Rename.Text);
    fBrowse.Refresh;
  end;
end;


// Check if new name is allowed
procedure TKMMenuMapEditor.Edit_Rename_Change(Sender: TObject);
begin
  Button_MapRenameConfirm.Enabled := FilenameEdit_Rename.IsValid and not fBrowse.ContainsMapName(Trim(FilenameEdit_Rename.Text));
end;


procedure TKMMenuMapEditor.RenameConfirm(aVisible: Boolean);
begin
  if aVisible then
  begin
    FilenameEdit_Rename.Text := fBrowse.SelectedMap.Name;
    Button_MapRenameConfirm.Enabled := False;
    Form_Rename.Show;
  end else
    Form_Rename.Hide;
end;


procedure TKMMenuMapEditor.MoveConfirm(aVisible: Boolean);
begin
  if aVisible then
  begin
    Form_Move.Show;
    ColumnBox_MapEd.Focusable := False; // Will update focus automatically
    fBrowse.SetListFocusable(False);
  end else
  begin
    Form_Move.Hide;
    ColumnBox_MapEd.Focusable := True; // Will update focus automatically
    fBrowse.SetListFocusable(True);
  end;
end;


procedure TKMMenuMapEditor.SetSelectedMapInfo(aID: Integer = -1);
var
  CRC: Cardinal;
  name: UnicodeString;
begin
  if (aID <> -1) then
  begin
    CRC := GetDisplayedMap(aID).MapAndDatCRC;
    name := GetDisplayedMap(aID).Name;
  end else
  begin
    CRC := 0;
    name := '';
  end;
  SetSelectedMapInfo(CRC, name);
end;


procedure TKMMenuMapEditor.SetSelectedMapInfo(aCRC: Cardinal; const aName: UnicodeString);
begin
  fSelectedMapInfo.CRC := aCRC;
  fSelectedMapInfo.Name := aName;
  case fBrowse.Category of
    mkMP: begin
            gGameSettings.MenuMapEdMPMapCRC := aCRC;
            gGameSettings.MenuMapEdMPMapName := aName;
          end;
    mkCM: gGameSettings.MenuMapEdCMMapCRC := aCRC;
    mkDL: gGameSettings.MenuMapEdDLMapCRC := aCRC; // Set only CRC, because we do not save selected DL map name
  else
    gGameSettings.MenuMapEdSPMapCRC := aCRC;
  end;
end;


procedure TKMMenuMapEditor.MoveEditChange(Sender: TObject);
var
  saveName: string;
begin
  // Do not allow not valid file name
  if not FilenameEdit_MapMove.IsValid then
  begin
    CheckBox_MoveExists.Visible := False;
    Label_MoveExists.Visible := False;
    Button_MapMoveConfirm.Enabled := False;
    Exit;
  end;

  saveName := TKMapsCollection.FullPath(Trim(FilenameEdit_MapMove.Text), '.dat', mkMP);

  if (Sender = FilenameEdit_MapMove) or (Sender = Button_MapMove) then
  begin
    CheckBox_MoveExists.Visible := FileExists(saveName);
    Label_MoveExists.Visible := CheckBox_MoveExists.Visible;
    CheckBox_MoveExists.Checked := False;
    Button_MapMoveConfirm.Enabled := not CheckBox_MoveExists.Visible;
  end;

  if Sender = CheckBox_MoveExists then
    Button_MapMoveConfirm.Enabled := CheckBox_MoveExists.Checked;
end;


procedure TKMMenuMapEditor.UpdateMapInfo(aID: Integer = -1);

  function AddLabelDesc(aLabelDesc: UnicodeString; const aAddition: UnicodeString): UnicodeString;
  begin
    if aLabelDesc <> '' then
      aLabelDesc := aLabelDesc + '|';
    aLabelDesc := aLabelDesc + aAddition;
    Result := aLabelDesc;
  end;

var
  map: TKMMapInfo;
  labelHeight: Integer;
begin
  if aID <> -1 then
  begin
    if fMinimapLastListId = aID then Exit; //Do not reload same minimap

    fMinimapLastListId := aID;
    map := GetDisplayedMap(aID);
    fMinimap.LoadFromMission(map.FullPath('.dat'), []);
    fMinimap.Update(True);
    MinimapView_MapEd.Show;
    Panel_MapInfo.Show;
    map.LoadExtra;
    if IsCampaignTab and (ListBox_Campaigns.ItemIndex >= 0) and InRange(aID, 0, High(fCampMapIndices)) then
      Memo_MapDesc.Text := gGameApp.Campaigns[ListBox_Campaigns.ItemIndex].GetMissionBriefing(fCampMapIndices[aID])
    else
      Memo_MapDesc.Text := map.BigDesc;
    if map.HasReadme then
      Button_ViewReadme.Show
    else
      Button_ViewReadme.Hide;

    if IsCampaignTab and MissionHasVictoryVideo(map.Dir) then
      Button_CampaignVictoryVideo.Show
    else
      Button_CampaignVictoryVideo.Hide;

    Label_MapType.Caption := '';

    if map.TxtInfo.IsCoop then
      Label_MapType.Caption := AddLabelDesc(Label_MapType.Caption, gResTexts[TX_LOBBY_MAP_COOP]);

    if map.TxtInfo.IsSpecial then
      Label_MapType.Caption := AddLabelDesc(Label_MapType.Caption, gResTexts[TX_LOBBY_MAP_SPECIAL]);

    if map.TxtInfo.IsPlayableAsSP then
      Label_MapType.Caption := AddLabelDesc(Label_MapType.Caption, gResTexts[TX_MENU_MAP_PLAYABLE_AS_SP]);

    if Label_MapType.Caption = '' then
    begin
      Memo_MapDesc.Top := MinimapView_MapEd.Bottom + 15;
      Label_MapType.Hide;
    end else
    begin
      labelHeight := gRes.Fonts[Label_MapType.Font].GetTextSize(Label_MapType.Caption).Y;
      Memo_MapDesc.Top := MinimapView_MapEd.Bottom + 15 + labelHeight;
      Label_MapType.Show;
    end;

    if Button_CampaignVictoryVideo.Visible then
    begin
      Button_CampaignVictoryVideo.Top := Panel_MapInfo.Height - Button_CampaignVictoryVideo.Height;
      if Button_ViewReadme.Visible then
        Button_ViewReadme.Top := Button_CampaignVictoryVideo.Top - Button_ViewReadme.Height - 5;
    end
    else if Button_ViewReadme.Visible then
      Button_ViewReadme.Top := Panel_MapInfo.Height - Button_ViewReadme.Height;

    Memo_MapDesc.Height := Panel_MapInfo.Height - Memo_MapDesc.Top
                          - (Button_ViewReadme.Height + 5) * Byte(Button_ViewReadme.Visible)
                          - (Button_CampaignVictoryVideo.Height + 5) * Byte(Button_CampaignVictoryVideo.Visible);
  end else
  begin
    MinimapView_MapEd.Hide;
    Memo_MapDesc.Clear;
  end;
end;


procedure TKMMenuMapEditor.MoveClick(Sender: TObject);
begin
  if IsCampaignTab then
    Exit;
  Assert(fBrowse.IsDownloadedCategory);

  if not fBrowse.HasSelection then
    Exit;

  if Sender = Button_MapMove then
  begin
    FilenameEdit_MapMove.Text := fBrowse.SelectedMap.FileNameWithoutHash;
    MoveConfirm(True);
    MoveEditChange(Button_MapMove);
  end;

  if (Sender = Button_MapMoveConfirm) or (Sender = Button_MapMoveCancel) then
    MoveConfirm(False);

  //Move selected map
  if Sender = Button_MapMoveConfirm then
  begin
    fBrowse.MoveSelectedMap(FilenameEdit_MapMove.Text, mkMP);
    SetSelectedMapInfo(fSelectedMapInfo.CRC, FilenameEdit_MapMove.Text); // Update Name of selected item in list
    fBrowse.Focus;
    fBrowse.Refresh;
  end;
end;


procedure TKMMenuMapEditor.RefreshAll;
var
  initialKind: TKMMapKind;
begin
  // Reload settings because we could have updated favourite maps, f.e.
  gGameAppSettings.ReloadFavouriteMaps;

  // we can get access to gGameApp only here, because in Create it could still be nil
  case gGameSettings.MenuMapEdMapType of
    1:  initialKind := mkMP;
    2:  initialKind := mkCM;
    3:  initialKind := mkDL;
  else
    initialKind := mkSP;
  end;
  fBrowse.SetCategory(initialKind);

  fBrowse.SetVisible(not IsCampaignTab);
  Panel_Campaigns.Visible := IsCampaignTab;
  ColumnBox_MapEd.Visible := IsCampaignTab;
  Panel_MapEdListSlot.Visible := not IsCampaignTab;
  Panel_MapEdPreviewSlot.Visible := not IsCampaignTab;

  if IsCampaignTab then
  begin
    Label_MapAvailable.Caption := gResTexts[TX_MENU_MAP_AVAILABLE_MISSIONS];
    Button_Load.Caption := gResTexts[TX_MENU_MAP_LOAD_EXISTING_MISSION];
    Button_MapCreate.Caption := gResTexts[TX_MENU_MAP_CREATE_NEW_MISSION];
    Button_MapDelete.Caption := gResTexts[TX_MENU_MAP_DELETE_MISSION];

    Memo_MapDesc.Show;
  end
  else
  begin
    Label_MapAvailable.Caption := gResTexts[TX_MENU_MAP_AVAILABLE];
    Button_Load.Caption := gResTexts[TX_MENU_MAP_LOAD_EXISTING];
    Button_MapCreate.Caption := gResTexts[TX_MENU_MAP_CREATE_NEW_MAP];
    Button_MapDelete.Caption := gResTexts[TX_MENU_MAP_DELETE];

    MinimapView_MapEd.Hide;
    Label_MapType.Hide;
    Memo_MapDesc.Clear;
    Memo_MapDesc.Hide;
    Button_ViewReadme.Hide;
    Button_CampaignVictoryVideo.Hide;
  end;

  UpdateSelectedMapCRC;

  RefreshCampaignsList;
  UpdateCampInfo;

  if IsCampaignTab then
    RefreshList(True)
  else
  begin
    fBrowse.SetPreselect(fSelectedMapInfo.CRC, fSelectedMapInfo.Name);
    fBrowse.SetCategory(fBrowse.Category);
  end;
  fBrowse.Refresh;

  UpdateUI;
end;


procedure TKMMenuMapEditor.Show;
begin
  RefreshAll;

  Panel_MapEd.Show;
  if IsCampaignTab then
    ColumnBox_MapEd.Focus
  else
    fBrowse.Focus;
end;


procedure TKMMenuMapEditor.UpdateState;
begin
  fBrowse.UpdateState;
end;


end.
