unit KM_GUIMenuMapEditor;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLType, {$ENDIF}
  Classes, Controls, SysUtils, Math,
  KM_Controls, KM_Maps, KM_Minimap,
  KM_InterfaceDefaults, KM_Defaults, KM_CommonTypes, KM_GameTypes;


type
  TKMMenuMapEditor = class (TKMMenuPageCommon)
  private
    fOnPageChange: TKMMenuChangeEventText; //will be in ancestor class

    fMaps: TKMapsCollection;
    fMinimap: TKMMinimap;
    fMinimapLastListId: Integer;  // column id, on which last time minimap was loaded. Avoid multiple loads of same minimap, which could happen on every RefreshList
    fScanCompleted: Boolean;      // True, after scan was completed

    fSelectedMapInfo: TKMFileIdentInfo; // Identification info about last selected map

    procedure LoadClick(Sender: TObject);
    procedure MapTypeChange(Sender: TObject);
    procedure MapFilterChanged(Sender: TObject);
    procedure MapFilterReset(Sender: TObject);
    procedure UpdateSelectedMapCRC;
    procedure ListUpdate;
    procedure UpdateFilterUI;
    procedure UpdateUI;
    procedure SetSelectedMapInfo(aID: Integer = -1); overload;
    procedure SetSelectedMapInfo(aCRC: Cardinal; const aName: UnicodeString); overload;

    procedure ScanUpdate(Sender: TObject);
    procedure ScanTerminate(Sender: TObject);
    procedure SortUpdate(Sender: TObject);
    procedure ScanComplete(Sender: TObject);

    procedure Radio_MapSizes_HeightChange(Sender: TObject; aValue: Integer);

    procedure RefreshCampaignsList;
    procedure RefreshList(aJumpToSelected: Boolean);
    procedure ColumnClick(aValue: Integer);
    procedure UpdateMapInfo(aID: Integer = -1);
    procedure UpdateCampInfo;
    procedure UpdateCampMapInfo;
    procedure ReadmeClick(Sender: TObject);
    procedure SelectMap(Sender: TObject);
    procedure SelectCampaign(Sender: TObject);
    function ColumnBoxMaps_CellClick(Sender: TObject; const X, Y: Integer): Boolean;
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
    procedure KeyDown(Key: Word; Shift: TShiftState);
  protected
    Panel_MapEd: TKMPanel;

      Panel_MapType: TKMPanel;
        Radio_MapType: TKMRadioGroup;

      Panel_MapFilter: TKMPanel;
        Radio_BuildFight, Radio_CoopSpecial: TKMRadioGroup;
        CheckBox_ByPlayerCnt: TKMCheckBox;
        TrackBar_PlayersCnt: TKMTrackBar;
        Panel_MapFilter_Size: TKMPanel;
          CheckBox_Sizes: array [MAP_SIZE_ENUM_MIN..MAP_SIZE_ENUM_MAX] of TKMCheckBox;
        Button_ResetFilter: TKMButton;

      Panel_Campaigns: TKMPanel;
        ListBox_Campaigns: TKMListBox;
        Button_CampaignsNew, Button_CampaignsDelete, Button_CampaignEdit: TKMButton;
        Image_Campaign: TKMImage;

      Panel_MapEdLoad: TKMPanel;
        ColumnBox_MapEd: TKMColumnBox;
        Button_MapCreate, Button_MapMove, Button_MapRename, Button_MapDelete, Button_Load: TKMButton;

      Panel_MapInfo: TKMPanel;
        MinimapView_MapEd: TKMMinimapView;
        Label_MapType: TKMLabel;
        Memo_MapDesc: TKMMemo;
        Button_ViewReadme: TKMButton;

      //PopUp Menus
      PopUp_Delete: TKMPopUpMenu;
        Image_Delete: TKMImage;
        Button_MapDeleteConfirm, Button_MapDeleteCancel: TKMButton;
        Label_MapDeleteConfirmTitle, Label_MapDeleteConfirm: TKMLabel;

      PopUp_Rename: TKMPopUpMenu;
        Image_Rename: TKMImage;
        Label_RenameTitle, Label_RenameName: TKMLabel;
        Edit_Rename: TKMEdit;
        Button_MapRenameConfirm, Button_MapRenameCancel: TKMButton;

      PopUp_Move: TKMPopUpMenu;
        Image_Move: TKMImage;
        Button_MapMoveConfirm, Button_MapMoveCancel: TKMButton;
        Edit_MapMove: TKMEdit;
        Label_MoveExists: TKMLabel;
        CheckBox_MoveExists: TKMCheckBox;
        Label_MapMoveConfirmTitle, Label_MapMoveName: TKMLabel;

      Button_MapEdBack: TKMButton;

  public
    OnNewMapEditor: TKMNewMapEditorEvent;

    constructor Create(aParent: TKMPanel; aOnPageChange: TKMMenuChangeEventText);
    destructor Destroy; override;
    procedure Show;
    procedure UpdateState;
  end;


implementation
uses
  KM_ResTexts, 
  KM_GameSettings, 
  KM_ServerSettings,
  KM_RenderUI, KM_Resource, KM_ResFonts,
  KM_Pics, KM_CommonUtils, KM_Campaigns, KM_GameApp;

const
  MAPSIZES_COUNT = 8;
  MapSize: array [0..MAPSIZES_COUNT-1] of Word = (32, 64, 96, 128, 160, 192, 224, 256);


{ TKMGUIMainMapEditor }
constructor TKMMenuMapEditor.Create(aParent: TKMPanel; aOnPageChange: TKMMenuChangeEventText);
const
  FILTER_PAD_X = 10;
  FILTER_PAD_Y = 8;
  NEW_MAP_PAD_Y = 6;
var
  I: Integer;
  MS: TKMMapSize;
begin
  inherited Create(gpMapEditor);

  fOnPageChange := aOnPageChange;
  OnEscKeyDown := EscKeyDown;
  OnKeyDown := KeyDown;

  fMaps := TKMapsCollection.Create([mfSP, mfMP, mfDL], smByNameDesc, True);

  fMinimap := TKMMinimap.Create(True, True);

  Panel_MapEd := TKMPanel.Create(aParent, 0, 0, aParent.Width, aParent.Height);
  Panel_MapEd.AnchorsStretch;

    Panel_MapType := TKMPanel.Create(Panel_MapEd, 30, 30, 260, 80);
    Panel_MapType.Anchors := [anLeft, anTop];
      TKMLabel.Create(Panel_MapType, 6, 0, Panel_MapType.Width, 20, 'Map type', fntOutline, taLeft);

      TKMBevel.Create(Panel_MapType, 0, 20, Panel_MapType.Width, 80 + FILTER_PAD_Y);
      Radio_MapType := TKMRadioGroup.Create(Panel_MapType, FILTER_PAD_X, 20+FILTER_PAD_Y, Panel_MapType.Width - 2*FILTER_PAD_X,76,fntGrey);
      Radio_MapType.Add(gResTexts[TX_MENU_MAPED_SPMAPS]);
      Radio_MapType.Add(gResTexts[TX_MENU_MAPED_MPMAPS_SHORT]);
      Radio_MapType.Add(gResTexts[TX_MENU_CAMPAIGNS]);
      Radio_MapType.Add(gResTexts[TX_MENU_MAPED_DLMAPS]);
      Radio_MapType.ItemIndex := 0;
      Radio_MapType.OnChange := MapTypeChange;

    /////

    Panel_MapFilter := TKMPanel.Create(Panel_MapEd, 30, 140, 260, 284);
    Panel_MapFilter.Anchors := [anLeft, anTop];
      TKMLabel.Create(Panel_MapFilter, 6, 0, Panel_MapFilter.Width, 20, gResTexts[TX_MENU_MAP_FILTER], fntOutline, taLeft);

      TKMBevel.Create(Panel_MapFilter, 0, 20, Panel_MapFilter.Width, 40 + FILTER_PAD_Y);
      Radio_BuildFight := TKMRadioGroup.Create(Panel_MapFilter, FILTER_PAD_X, 20+FILTER_PAD_Y, Panel_MapFilter.Width - 2*FILTER_PAD_X, 40, fntGrey);

      Radio_BuildFight.Add(gResTexts[TX_LOBBY_MAP_BUILD]);
      Radio_BuildFight.Add(gResTexts[TX_LOBBY_MAP_FIGHT]);
      Radio_BuildFight.AllowUncheck := True; //Allow uncheck filter radio
      Radio_BuildFight.OnChange := MapFilterChanged;

      TKMBevel.Create(Panel_MapFilter, 0, Radio_BuildFight.Bottom + FILTER_PAD_Y, Panel_MapFilter.Width, 40 + FILTER_PAD_Y);
      Radio_CoopSpecial := TKMRadioGroup.Create(Panel_MapFilter, FILTER_PAD_X, Radio_BuildFight.Bottom + 2*FILTER_PAD_Y, Panel_MapFilter.Width - 2*FILTER_PAD_X, 40, fntGrey);
      Radio_CoopSpecial.Add(gResTexts[TX_LOBBY_MAP_SPECIAL]);
      Radio_CoopSpecial.Add(gResTexts[TX_LOBBY_MAP_Coop]);
      Radio_CoopSpecial.AllowUncheck := True; //Allow uncheck filter radio
      Radio_CoopSpecial.OnChange := MapFilterChanged;

      TKMBevel.Create(Panel_MapFilter, 0, Radio_CoopSpecial.Bottom + FILTER_PAD_Y, Panel_MapFilter.Width, 45 + 2*FILTER_PAD_Y);
      CheckBox_ByPlayerCnt := TKMCheckBox.Create(Panel_MapFilter, FILTER_PAD_X, Radio_CoopSpecial.Bottom + 2*FILTER_PAD_Y,
                                                 Panel_MapFilter.Width - 2*FILTER_PAD_X, 20, gResTexts[TX_MENU_MAP_FILTER_BY_PLAYERS_NUMBER], fntGrey);
      CheckBox_ByPlayerCnt.OnClick := MapFilterChanged;
      TrackBar_PlayersCnt := TKMTrackBar.Create(Panel_MapFilter, FILTER_PAD_X, CheckBox_ByPlayerCnt.Bottom + FILTER_PAD_Y,
                                                Panel_MapFilter.Width - 2*FILTER_PAD_X, 1, MAX_HANDS);
      TrackBar_PlayersCnt.Anchors := [anLeft,anTop];
      TrackBar_PlayersCnt.Disable;
      TrackBar_PlayersCnt.OnChange := MapFilterChanged;

      Panel_MapFilter_Size := TKMPanel.Create(Panel_MapFilter, 0, TrackBar_PlayersCnt.Bottom + FILTER_PAD_Y + 5, Panel_MapFilter.Width, 40 + FILTER_PAD_Y);
        TKMBevel.Create(Panel_MapFilter_Size, 0, 0, Panel_MapFilter_Size.Width, Panel_MapFilter_Size.Height);

        for MS := MAP_SIZE_ENUM_MIN to MAP_SIZE_ENUM_MAX do
        begin
          CheckBox_Sizes[MS] := TKMCheckBox.Create(Panel_MapFilter_Size, FILTER_PAD_X + 70*((Byte(MS)-1) div 2),
                                                   FILTER_PAD_Y + 20*((Byte(MS)-1) mod 2), 60, 20, MapSizeText(MS), fntMetal);
          CheckBox_Sizes[MS].Check;
          CheckBox_Sizes[MS].OnClick := MapFilterChanged;
        end;

      Button_ResetFilter := TKMButton.Create(Panel_MapFilter, 0, Panel_MapFilter_Size.Bottom + FILTER_PAD_Y, Panel_MapFilter.Width, 20,
                                             gResTexts[TX_MENU_MAP_FILTER_RESET], bsMenu);
      Button_ResetFilter.OnClick := MapFilterReset;

    /////

    Panel_Campaigns := TKMPanel.Create(Panel_MapEd, 30, 140, 260, 284);
    Panel_Campaigns.Anchors := [anLeft, anTop];
      TKMLabel.Create(Panel_Campaigns, 6, 0, Panel_Campaigns.Width, 20, gResTexts[TX_MENU_CAMPAIGNS], fntOutline, taLeft);

      ListBox_Campaigns := TKMListBox.Create(Panel_Campaigns, 0, 20, Panel_Campaigns.Width, 229, fntMetal,  bsMenu);
      ListBox_Campaigns.Anchors := [anLeft, anTop];
      ListBox_Campaigns.OnChange := SelectCampaign;

      Button_CampaignsNew := TKMButton.Create(Panel_Campaigns, 0, ListBox_Campaigns.Bottom + 8, Panel_Campaigns.Width div 2 - 4, 20, 'Add', bsMenu);

      Button_CampaignsNew.Anchors := [anLeft, anBottom];
      Button_CampaignsNew.OnClick := LoadClick;

      Button_CampaignsDelete := TKMButton.Create(Panel_Campaigns, Panel_Campaigns.Width div 2 + 4, ListBox_Campaigns.Bottom + 8, Panel_Campaigns.Width div 2 - 4, 20, 'Delete', bsMenu);
      Button_CampaignsDelete.Anchors := [anLeft, anBottom];
      Button_CampaignsDelete.OnClick := LoadClick;

      TKMImage.Create(Panel_Campaigns, -5, Button_CampaignsNew.Bottom + 5, Panel_Campaigns.Width+10, Round(Panel_Campaigns.Width * (768 / 1027))+10, 18, rxGuiMain).ImageStretch;
      Image_Campaign := TKMImage.Create(Panel_Campaigns, 0, Button_CampaignsNew.Bottom + 8, Panel_Campaigns.Width, Round(Panel_Campaigns.Width * (768 / 1027)), 18, rxGuiMain);
      Image_Campaign.ImageStretch;
      Image_Campaign.Hide;

      Button_CampaignEdit := TKMButton.Create(Panel_Campaigns, 0, Image_Campaign.Bottom + 8, Panel_Campaigns.Width, 20, 'Edit', bsMenu);
      Button_CampaignEdit.Anchors := [anLeft, anBottom];
      Button_CampaignEdit.OnClick := LoadClick;

    Panel_Campaigns.Hide;

    /////

    Panel_MapEdLoad := TKMPanel.Create(Panel_MapEd, 305, 30, 440, 708);
    Panel_MapEdLoad.Anchors := [anLeft, anTop, anBottom];
      TKMLabel.Create(Panel_MapEdLoad, 6, 0, Panel_MapEdLoad.Width - 12, 20, gResTexts[TX_MENU_MAP_AVAILABLE], fntOutline, taLeft);

      ColumnBox_MapEd := TKMColumnBox.Create(Panel_MapEdLoad, 0, 20, 440, 576, fntMetal,  bsMenu);
      ColumnBox_MapEd.Anchors := [anLeft, anTop, anBottom];
      //ColumnBox_MapEd.SetColumns(fntOutline, ['', '', gResTexts[TX_MENU_MAP_TITLE], '#', gResTexts[TX_MENU_MAP_SIZE]], [0, 22, 44, 310, 340]);
      ColumnBox_MapEd.SearchColumn := 2;
      ColumnBox_MapEd.OnColumnClick := ColumnClick;
      ColumnBox_MapEd.OnChange := SelectMap;
      ColumnBox_MapEd.OnDoubleClick := LoadClick;
      ColumnBox_MapEd.OnCellClick := ColumnBoxMaps_CellClick;

      Button_Load := TKMButton.Create(Panel_MapEdLoad, 0, ColumnBox_MapEd.Bottom + 8, Panel_MapEdLoad.Width, 30, gResTexts[TX_MENU_MAP_LOAD_EXISTING], bsMenu);
      Button_Load.Anchors := [anLeft, anBottom];
      Button_Load.OnClick := LoadClick;

      Button_MapMove := TKMButton.Create(Panel_MapEdLoad, 0, Button_Load.Bottom + 8, Panel_MapEdLoad.Width, 30, gResTexts[TX_MENU_MAP_MOVE_DOWNLOAD], bsMenu);
      Button_MapMove.Anchors := [anLeft, anBottom];
      Button_MapMove.OnClick := MoveClick;
      Button_MapMove.Hide;

      Button_MapRename := TKMButton.Create(Panel_MapEdLoad, 0, Button_Load.Bottom + 8, Panel_MapEdLoad.Width, 30, gResTexts[TX_MENU_MAP_RENAME], bsMenu);
      Button_MapRename.Anchors := [anLeft, anBottom];
      Button_MapRename.OnClick := RenameClick;

      Button_MapCreate := TKMButton.Create(Panel_MapEdLoad, 0, Button_MapMove.Bottom + 8, Panel_MapEdLoad.Width div 2 - 4, 30, gResTexts[TX_MENU_MAP_CREATE_NEW_MAP], bsMenu);
      Button_MapCreate.Anchors := [anLeft, anBottom];
      Button_MapCreate.OnClick := LoadClick;

      Button_MapDelete := TKMButton.Create(Panel_MapEdLoad, Panel_MapEdLoad.Width div 2 + 4, Button_MapMove.Bottom + 8, Panel_MapEdLoad.Width div 2 - 4, 30, gResTexts[TX_MENU_MAP_DELETE], bsMenu);
      Button_MapDelete.Anchors := [anLeft, anBottom];
      Button_MapDelete.OnClick := DeleteClick;

    /////

    Panel_MapInfo := TKMPanel.Create(Panel_MapEd, 320+448, 50, 199, 688);
    Panel_MapInfo.Anchors := [anLeft, anTop, anBottom];

      MinimapView_MapEd := TKMMinimapView.Create(Panel_MapInfo, 4, 4, 191, 191, True);
      MinimapView_MapEd.Anchors := [anLeft, anTop];

      Label_MapType := TKMLabel.Create(Panel_MapInfo, 0, 199+10, '', fntMetal, taLeft);
      Label_MapType.Anchors := [anLeft, anTop];
      Memo_MapDesc := TKMMemo.Create(Panel_MapInfo, 0, 199+10, 199, Panel_MapInfo.Height - 199 - 10, fntGame, bsMenu);
      Memo_MapDesc.Anchors := [anLeft, anTop, anBottom];
      Memo_MapDesc.AutoWrap := True;
      Memo_MapDesc.ItemHeight := 16;

      Button_ViewReadme := TKMButton.Create(Panel_MapInfo, 0, 225, 199, 25, gResTexts[TX_LOBBY_VIEW_README], bsMenu);
      Button_ViewReadme.Anchors := [anLeft, anBottom];
      Button_ViewReadme.OnClick := ReadmeClick;
      Button_ViewReadme.Hide;

    /////

    Button_MapEdBack := TKMButton.Create(Panel_MapEd, 30, 708, 260, 30, gResTexts[TX_MENU_BACK], bsMenu);
    Button_MapEdBack.Anchors := [anLeft, anBottom];
    Button_MapEdBack.OnClick := BackClick;

      //Delete PopUp
      PopUp_Delete := TKMPopUpMenu.Create(Panel_MapEd, 450);
      PopUp_Delete.Height := 200;
      // Keep the pop-up centered
      PopUp_Delete.AnchorsCenter;
      PopUp_Delete.Left := (Panel_MapEd.Width div 2) - (PopUp_Delete.Width div 2);
      PopUp_Delete.Top := (Panel_MapEd.Height div 2) - 90;

        TKMBevel.Create(PopUp_Delete, -2000,  -2000, 5000, 5000);

        Image_Delete := TKMImage.Create(PopUp_Delete, 0, 0, PopUp_Delete.Width, PopUp_Delete.Height, 15, rxGuiMain);
        Image_Delete.ImageStretch;

        Label_MapDeleteConfirmTitle := TKMLabel.Create(PopUp_Delete, PopUp_Delete.Width div 2, 40, gResTexts[TX_MENU_MAP_DELETE], fntOutline, taCenter);
        Label_MapDeleteConfirmTitle.Anchors := [anLeft, anBottom];

        Label_MapDeleteConfirm := TKMLabel.Create(PopUp_Delete, PopUp_Delete.Width div 2, 85, gResTexts[TX_MENU_MAP_DELETE_CONFIRM], fntMetal, taCenter);
        Label_MapDeleteConfirm.Anchors := [anLeft, anBottom];

        Button_MapDeleteConfirm := TKMButton.Create(PopUp_Delete, 20, 155, 195, 30, gResTexts[TX_MENU_LOAD_DELETE_DELETE], bsMenu);
        Button_MapDeleteConfirm.Anchors := [anLeft, anBottom];
        Button_MapDeleteConfirm.OnClick := DeleteClick;

        Button_MapDeleteCancel  := TKMButton.Create(PopUp_Delete, 235, 155, 195, 30, gResTexts[TX_MENU_LOAD_DELETE_CANCEL], bsMenu);
        Button_MapDeleteCancel.Anchors := [anLeft, anBottom];
        Button_MapDeleteCancel.OnClick := DeleteClick;

    /////

      PopUp_Rename := TKMPopUpMenu.Create(Panel_MapEd, 400);
      PopUp_Rename.Height := 200;
      // Keep the pop-up centered
      PopUp_Rename.AnchorsCenter;
      PopUp_Rename.Left := (Panel_MapEd.Width div 2) - (PopUp_Rename.Width div 2);
      PopUp_Rename.Top := (Panel_MapEd.Height div 2) - 90;

        TKMBevel.Create(PopUp_Rename, -2000,  -2000, 5000, 5000);

        Image_Rename := TKMImage.Create(PopUp_Rename, 0, 0, PopUp_Rename.Width, PopUp_Rename.Height, 15, rxGuiMain);
        Image_Rename.ImageStretch;

        Label_RenameTitle := TKMLabel.Create(PopUp_Rename, 20, 50, 360, 30, 'Rename Map', fntOutline, taCenter);
        Label_RenameTitle.Anchors := [anLeft,anBottom];

        Label_RenameName := TKMLabel.Create(PopUp_Rename, 25, 100, 60, 20, gResTexts[TX_MENU_REPLAY_RENAME_NAME], fntMetal, taLeft);
        Label_RenameName.Anchors := [anLeft,anBottom];

        Edit_Rename := TKMEdit.Create(PopUp_Rename, 105, 97, 275, 20, fntMetal);
        Edit_Rename.Anchors := [anLeft,anBottom];
        Edit_Rename.AllowedChars := acFileName;
        Edit_Rename.OnChange := Edit_Rename_Change;

        Button_MapRenameConfirm := TKMButton.Create(PopUp_Rename, 20, 155, 170, 30, gResTexts[TX_MENU_REPLAY_RENAME_CONFIRM], bsMenu);
        Button_MapRenameConfirm.Anchors := [anLeft,anBottom];
        Button_MapRenameConfirm.OnClick := RenameClick;

        Button_MapRenameCancel := TKMButton.Create(PopUp_Rename, 210, 155, 170, 30, gResTexts[TX_MENU_LOAD_DELETE_CANCEL], bsMenu);
        Button_MapRenameCancel.Anchors := [anLeft,anBottom];
        Button_MapRenameCancel.OnClick := RenameClick;

      //Move PopUp
      PopUp_Move := TKMPopUpMenu.Create(Panel_MapEd, 400);
      PopUp_Move.Height := 200;
      // Keep the pop-up centered
      PopUp_Move.AnchorsCenter;
      PopUp_Move.Left := (Panel_MapEd.Width div 2) - (PopUp_Move.Width div 2);
      PopUp_Move.Top := (Panel_MapEd.Height div 2) - 90;

        TKMBevel.Create(PopUp_Move, -2000,  -2000, 5000, 5000);

        Image_Move := TKMImage.Create(PopUp_Move, 0, 0, PopUp_Move.Width, PopUp_Move.Height, 15, rxGuiMain);
        Image_Move.ImageStretch;

        Label_MapMoveConfirmTitle := TKMLabel.Create(PopUp_Move, PopUp_Move.Width div 2, 40, gResTexts[TX_MENU_MAP_MOVE_DOWNLOAD], fntOutline, taCenter);
        Label_MapMoveConfirmTitle.Anchors := [anLeft, anBottom];

        Label_MapMoveName := TKMLabel.Create(PopUp_Move, 25, 75, 60, 20, gResTexts[TX_MENU_MAP_MOVE_NAME_TITLE], fntMetal, taLeft);
        Label_MapMoveName.Anchors := [anLeft,anBottom];

        Edit_MapMove := TKMEdit.Create(PopUp_Move, 105, 72, 275, 20, fntGrey);
        Edit_MapMove.Anchors := [anLeft, anBottom];
        Edit_MapMove.OnChange := MoveEditChange;

        Label_MoveExists := TKMLabel.Create(PopUp_Move, 25, 100, gResTexts[TX_MAPED_SAVE_EXISTS], fntOutline, taLeft);
        Label_MoveExists.Anchors := [anLeft, anBottom];
        Label_MoveExists.Hide;
        CheckBox_MoveExists := TKMCheckBox.Create(PopUp_Move, 25, 125, 300, 20, gResTexts[TX_MAPED_SAVE_OVERWRITE], fntMetal);
        CheckBox_MoveExists.Anchors := [anLeft, anBottom];
        CheckBox_MoveExists.OnClick := MoveEditChange;

        Button_MapMoveConfirm := TKMButton.Create(PopUp_Move, 20, 150, 170, 30, gResTexts[TX_MENU_MAP_MOVE_CONFIRM], bsMenu);
        Button_MapMoveConfirm.Anchors := [anLeft, anBottom];
        Button_MapMoveConfirm.OnClick := MoveClick;

        Button_MapMoveCancel  := TKMButton.Create(PopUp_Move, 210, 150, 170, 30, gResTexts[TX_MENU_LOAD_DELETE_CANCEL], bsMenu);
        Button_MapMoveCancel.Anchors := [anLeft, anBottom];
        Button_MapMoveCancel.OnClick := MoveClick;
end;


destructor TKMMenuMapEditor.Destroy;
begin
  fMaps.Free;
  fMinimap.Free;

  inherited;
end;


procedure TKMMenuMapEditor.Radio_MapSizes_HeightChange(Sender: TObject; aValue: Integer);
const
  RADIO_MAPSIZE_LINE_H = 20;
  RADIO_MAPSIZE_LINE_MAX_H = 25;
  //Indexes of new map sizes to skip. First less important
  RADIO_SKIP_SIZES_I: array [0..MAPSIZES_COUNT - 1] of Integer = (1,5,7,3,4,6,0,2);
var
  I: Integer;
begin
  Assert(Sender is TKMRadioGroup);
  I := TKMRadioGroup(Sender).Count - 1;

  while (TKMRadioGroup(Sender).LineHeight < RADIO_MAPSIZE_LINE_H)
    and (TKMRadioGroup(Sender).VisibleCount >= 0)
    and (I >= 0) do
  begin
    TKMRadioGroup(Sender).SetItemVisible(RADIO_SKIP_SIZES_I[I], False);
    Dec(I);
  end;

  I := 0;
  while ((TKMRadioGroup(Sender).LineHeight > RADIO_MAPSIZE_LINE_MAX_H)
      or ((TKMRadioGroup(Sender).LineHeight > RADIO_MAPSIZE_LINE_H) and (TKMRadioGroup(Sender).VisibleCount = 0)))
    and (I < TKMRadioGroup(Sender).Count) do
  begin
    TKMRadioGroup(Sender).SetItemVisible(RADIO_SKIP_SIZES_I[I], True);
    Inc(I);
  end;
end;


function TKMMenuMapEditor.ColumnBoxMaps_CellClick(Sender: TObject; const X, Y: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  if X = 0 then //1st column
  begin
    I := ColumnBox_MapEd.Item[Y].Tag;
    fMaps.Lock;
    try
      fMaps[I].IsFavourite := not fMaps[I].IsFavourite;
      if fMaps[I].IsFavourite then
      begin
        gGameSettings.FavouriteMaps.Add(fMaps[I].MapAndDatCRC);
        gServerSettings.ServerMapsRoster.Add(fMaps[I].CRC);
      end else begin
        gGameSettings.FavouriteMaps.Remove(fMaps[I].MapAndDatCRC);
        gServerSettings.ServerMapsRoster.Remove(fMaps[I].CRC);
      end;

      //Update pic
      ColumnBox_MapEd.Item[Y].Cells[0].Pic := fMaps[I].FavouriteMapPic;
    finally
      fMaps.Unlock;
    end;
    Result := True; //we handle mouse click here, and do not want to propagate it further
  end;
end;


procedure TKMMenuMapEditor.LoadClick(Sender: TObject);
var
  Map: TKMapInfo;
  Campaign: TKMCampaign;
begin
  //This is also called by double clicking on a map in the list
    if ((Sender = Button_Load) or (Sender = ColumnBox_MapEd)) and
       Button_Load.Enabled and ColumnBox_MapEd.IsSelected then
    begin
      if Radio_MapType.ItemIndex = 2 then
      begin
        Campaign := gGameApp.Campaigns[ListBox_Campaigns.ItemIndex];
        gGameApp.NewMapEditor(Campaign.GetMissionFile(ColumnBox_MapEd.SelectedItemTag), 0, 0, Map.CRC, Map.MapAndDatCRC);
      end
      else
      begin
        fMaps.Lock;
        try
          //Make local copy of Map before Unlock
          Map := fMaps[ColumnBox_MapEd.SelectedItemTag];

          //Unlock before Terminate!
          fMaps.Unlock;

          //Terminate all
          fMaps.TerminateScan;

          gGameApp.NewMapEditor(Map.FullPath('.dat'), 0, 0, Map.CRC, Map.MapAndDatCRC);
        finally
          fMaps.Unlock; //Double unlock should not harm
        end;
      end;

      if Assigned(OnNewMapEditor) then
        OnNewMapEditor(Map.FullPath('.dat'), 0, 0, Map.CRC, Map.MapAndDatCRC, Radio_MapType.ItemIndex <> 0);
    end;

  //Create new map (NumEdits hold actual dimensions)
  if Sender = Button_MapCreate then
    gGameApp.NewMapEditor('', gGameApp.GameSettings.MenuMapEdNewMapX, gGameApp.GameSettings.MenuMapEdNewMapY);
end;

procedure TKMMenuMapEditor.MapTypeChange(Sender: TObject);
begin
  gGameSettings.MenuMapEdMapType := Radio_MapType.ItemIndex;

  if Radio_MapType.ItemIndex = 2 then
    RefreshCampaignsList()
  else
  begin
    UpdateSelectedMapCRC;
    UpdateFilterUI;
  end;
  RefreshList(True);

  UpdateUI;
end;


procedure TKMMenuMapEditor.MapFilterChanged(Sender: TObject);
begin
  TrackBar_PlayersCnt.Enabled := CheckBox_ByPlayerCnt.Checked;
  fMinimapLastListId := -1; // Clear last loasded minimap ID, as we uncheck the filter, then need to draw minimap again, probably
  RefreshList(True);
end;


procedure TKMMenuMapEditor.MapFilterReset(Sender: TObject);
var
  MS: TKMMapSize;
begin
  Radio_BuildFight.ItemIndex := -1;
  Radio_CoopSpecial.ItemIndex := -1;
  CheckBox_ByPlayerCnt.Uncheck;
  TrackBar_PlayersCnt.Enabled := False;
  for MS := MAP_SIZE_ENUM_MIN to MAP_SIZE_ENUM_MAX do
    CheckBox_Sizes[MS].Check;
  MapFilterChanged(nil);
end;


procedure TKMMenuMapEditor.UpdateFilterUI;
begin
  //Disable Coop map filter for SP maps
  if Radio_MapType.ItemIndex = 0 then
  begin
    Radio_CoopSpecial.SetItemEnabled(1, False);
    if Radio_CoopSpecial.ItemIndex = 1 then
      Radio_CoopSpecial.ItemIndex := -1;
  end else
    Radio_CoopSpecial.SetItemEnabled(1, True);
end;


procedure TKMMenuMapEditor.UpdateUI;
begin
  Panel_MapFilter.Visible := Radio_MapType.ItemIndex <> 2;
  Panel_Campaigns.Visible := Radio_MapType.ItemIndex = 2;

  UpdateFilterUI;

  Button_Load.Enabled := ColumnBox_MapEd.IsSelected;
  Button_MapDelete.Enabled := ColumnBox_MapEd.IsSelected;
  Button_MapMove.Visible := (Radio_MapType.ItemIndex <> 2) and ColumnBox_MapEd.IsSelected and (fMaps[ColumnBox_MapEd.SelectedItemTag].MapFolder = mfDL);
  Button_MapRename.Enabled := ColumnBox_MapEd.IsSelected;
  Button_MapRename.Visible := not Button_MapMove.Visible;

  if Radio_MapType.ItemIndex = 2 then
    UpdateCampMapInfo
  else
    UpdateMapInfo(ColumnBox_MapEd.SelectedItemTag);
end;


procedure TKMMenuMapEditor.UpdateSelectedMapCRC;
begin
  case Radio_MapType.ItemIndex of
    0:  fSelectedMapInfo.CRC := gGameSettings.MenuMapEdSPMapCRC;
    1:  begin
          fSelectedMapInfo.CRC := gGameSettings.MenuMapEdMPMapCRC;
          fSelectedMapInfo.Name := gGameSettings.MenuMapEdMPMapName;
        end;
    2: ;
    3:  fSelectedMapInfo.CRC := gGameSettings.MenuMapEdDLMapCRC;
  end;
end;


//Clear the list and initiate refresh
procedure TKMMenuMapEditor.ListUpdate;
begin
  //Terminate all
  if Radio_MapType.ItemIndex <> 2 then
    fMaps.TerminateScan;

  ColumnBox_MapEd.Clear;

  //Reset scan variables
  fScanCompleted := False;
  fMinimapLastListId := ITEM_NOT_LOADED;

  UpdateSelectedMapCRC;

  if Radio_MapType.ItemIndex <> 2 then
    fMaps.Refresh(ScanUpdate, ScanTerminate, ScanComplete)
  else
    RefreshList(True);
end;


procedure TKMMenuMapEditor.ScanUpdate(Sender: TObject);
begin
  if not fScanCompleted then  // Don't refresh list, if scan was completed already
    RefreshList(False); //Don't jump to selected with each scan update
end;


procedure TKMMenuMapEditor.ScanTerminate(Sender: TObject);
begin
  fScanCompleted := True;
  RefreshList(True); //After scan complete jump to selected item
end;


procedure TKMMenuMapEditor.SortUpdate(Sender: TObject);
begin
  RefreshList(True); //After sorting jump to the selected item
end;


procedure TKMMenuMapEditor.ScanComplete(Sender: TObject);
var
  MapsSimpleCRCArray, MapsFullCRCArray: TKMCardinalArray;
  I: Integer;
begin
  //Cleanup missing Favourite maps from the lists
  if (Sender = fMaps) and (fMaps.Count > 0) then
  begin
    SetLength(MapsSimpleCRCArray, fMaps.Count);
    SetLength(MapsFullCRCArray, fMaps.Count);

    for I := 0 to fMaps.Count - 1 do
    begin
      MapsSimpleCRCArray[I] := fMaps[I].MapAndDatCRC;
      MapsFullCRCArray[I] := fMaps[I].CRC;

      if gServerSettings.ServerMapsRosterEnabled
        and gGameSettings.FavouriteMaps.Contains(MapsSimpleCRCArray[I]) then
        gServerSettings.ServerMapsRoster.Add(MapsFullCRCArray[I]);
    end;

    gGameSettings.FavouriteMaps.RemoveMissing(MapsSimpleCRCArray);
    gServerSettings.ServerMapsRoster.RemoveMissing(MapsFullCRCArray);
  end;
end;


procedure TKMMenuMapEditor.ReadmeClick(Sender: TObject);
var
  ID: Integer;
begin
  ID := ColumnBox_MapEd.SelectedItemTag;
  fMaps[ID].ViewReadme;
end;


procedure TKMMenuMapEditor.RefreshCampaignsList;
var
  I: Integer;
  Camps: TKMCampaignsCollection;
begin
  Camps := gGameApp.Campaigns;

  ListBox_Campaigns.Clear;
  for I := 0 to Camps.Count - 1 do
    ListBox_Campaigns.Add(Camps[I].GetCampaignTitle);

  ListBox_Campaigns.ItemIndex := gGameApp.GameSettings.MenuMapEdCamp;
end;


procedure TKMMenuMapEditor.RefreshList(aJumpToSelected: Boolean);
var
  I, ListI, PrevTop: Integer;
  R: TKMListRow;
  Color: Cardinal;
  MS: TKMMapSize;
  SkipMap: Boolean;

  Campaign: TKMCampaign;
begin
  PrevTop := ColumnBox_MapEd.TopIndex;
  ColumnBox_MapEd.Clear;

  if Radio_MapType.ItemIndex = 2 then
  begin
    ColumnBox_MapEd.SetColumns(fntOutline, ['', '', gResTexts[TX_MENU_MAP_TITLE], gResTexts[TX_MENU_MAP_SIZE]], [0, 22, 44, 340]);
    if ListBox_Campaigns.ItemIndex >= 0 then
    begin
      Campaign := gGameApp.Campaigns[ListBox_Campaigns.ItemIndex];

      for I := 0 to Campaign.Maps.Count - 1 do
      begin


        R := MakeListRow([(I + 1).ToString, '', Campaign.GetMissionName(I), ''],  //Texts
                         [$FFFFFFFF, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF], //Colors
                         I);

        ColumnBox_MapEd.AddItem(R);
      end;

      ColumnBox_MapEd.ItemIndex := Math.Min(ColumnBox_MapEd.RowCount - 1, gGameApp.GameSettings.MenuMapEdCampMap);
    end;
  end
  else
  begin
    ColumnBox_MapEd.SetColumns(fntOutline, ['', '', gResTexts[TX_MENU_MAP_TITLE], '#', gResTexts[TX_MENU_MAP_SIZE]], [0, 22, 44, 310, 340]);
    fMaps.Lock;
    try
      ListI := 0;
      for I := 0 to fMaps.Count - 1 do
      begin
        SkipMap := False;
        if ((Radio_MapType.ItemIndex = 0) and not fMaps[I].IsSinglePlayer)  //SP map filter
          or ((Radio_MapType.ItemIndex = 1) and not fMaps[I].IsMultiPlayer) //MP map filter
          or ((Radio_MapType.ItemIndex = 3) and not fMaps[I].IsDownloaded)  //MP DL map filter
          or ((Radio_BuildFight.ItemIndex = 0) and (fMaps[I].MissionMode <> mmNormal)) //Build map filter
          or ((Radio_BuildFight.ItemIndex = 1) and (fMaps[I].MissionMode <> mmTactic)) //Fight map filter
          or ((Radio_CoopSpecial.ItemIndex = 0) and not fMaps[I].TxtInfo.IsSpecial)     //Special map filter
          or ((Radio_CoopSpecial.ItemIndex = 1) and not fMaps[I].TxtInfo.IsCoop)        //Coop map filter
          or (TrackBar_PlayersCnt.Enabled and (fMaps[I].LocCount <> TrackBar_PlayersCnt.Position)) //Players number map filter
           then
          SkipMap := True;
        for MS := MAP_SIZE_ENUM_MIN to MAP_SIZE_ENUM_MAX do
          if not CheckBox_Sizes[MS].Checked and (fMaps[I].Size = MS) then
          begin
            SkipMap := True;
            Break;
          end;

        if SkipMap then
          Continue;

        Color := fMaps[I].GetLobbyColor;
        R := MakeListRow(['', '', fMaps[I].FileName, IntToStr(fMaps[I].LocCount), fMaps[I].SizeText],  //Texts
                         [Color, Color, Color, Color, Color], //Colors
                         I);
        R.Cells[0].Pic := fMaps[I].FavouriteMapPic;
        R.Cells[0].HighlightOnMouseOver := True;
        R.Cells[1].Pic := MakePic(rxGui, 657 + Byte(fMaps[I].MissionMode = mmTactic));
        R.Tag := I;
        ColumnBox_MapEd.AddItem(R);

        if (fMaps[I].MapAndDatCRC = fSelectedMapInfo.CRC)
          and ((Radio_MapType.ItemIndex = 0)
            or (Radio_MapType.ItemIndex = 2)
            or (fMaps[I].FileName = fSelectedMapInfo.Name)) then  //Check name only for MP maps
        begin
          ColumnBox_MapEd.ItemIndex := ListI;
          UpdateMapInfo(ListI);
        end;
        Inc(ListI);
      end;
    finally
      fMaps.Unlock;
    end;
  end;

  ColumnBox_MapEd.TopIndex := PrevTop;

  if aJumpToSelected and ColumnBox_MapEd.IsSelected
    and not InRange(ColumnBox_MapEd.ItemIndex - ColumnBox_MapEd.TopIndex, 0, ColumnBox_MapEd.GetVisibleRows - 1)
  then
    if ColumnBox_MapEd.ItemIndex < ColumnBox_MapEd.TopIndex then
      ColumnBox_MapEd.TopIndex := ColumnBox_MapEd.ItemIndex
    else
    if ColumnBox_MapEd.ItemIndex > ColumnBox_MapEd.TopIndex + ColumnBox_MapEd.GetVisibleRows - 1 then
      ColumnBox_MapEd.TopIndex := ColumnBox_MapEd.ItemIndex - ColumnBox_MapEd.GetVisibleRows + 1;

  UpdateUI;
end;


procedure TKMMenuMapEditor.ColumnClick(aValue: Integer);
var
  SM: TKMapsSortMethod;
begin
  //Determine Sort method depending on which column user clicked
  with ColumnBox_MapEd do
    case SortIndex of
      0:  if SortDirection = sdDown then
            SM := smByFavouriteDesc
          else
            SM := smByFavouriteAsc;
      1:  if SortDirection = sdDown then
            SM := smByMissionModeDesc
          else
            SM := smByMissionModeAsc;
      2:  if SortDirection = sdDown then
            SM := smByNameDesc
          else
            SM := smByNameAsc;
      3:  if SortDirection = sdDown then
            SM := smByPlayersDesc
          else
            SM := smByPlayersAsc;
      4:  if SortDirection = sdDown then
            SM := smBySizeDesc
          else
            SM := smBySizeAsc;
      else SM := smByNameAsc;
    end;

  //Keep all lists in sync incase user switches between them
  fMaps.Sort(SM, SortUpdate);
end;

procedure TKMMenuMapEditor.SelectCampaign(Sender: TObject);
begin
  gGameApp.GameSettings.MenuMapEdCamp := ListBox_Campaigns.ItemIndex;// ColumnBox_Campaigns.ItemIndex;
  UpdateCampInfo;
  RefreshList(True);
end;

procedure TKMMenuMapEditor.SelectMap(Sender: TObject);
var
  MapId: Integer;
begin
  UpdateUI;
  if ColumnBox_MapEd.IsSelected then
  begin
    MapId := ColumnBox_MapEd.SelectedItemTag;

    DeleteConfirm(False);
    MoveConfirm(False);
              if Radio_MapType.ItemIndex = 2 then
    begin
      gGameApp.GameSettings.MenuMapEdCampMap := ColumnBox_MapEd.ItemIndex;
      UpdateCampMapInfo;
    end
    else
    begin

      fMaps.Lock;
      try
        SetSelectedMapInfo(MapId);
        UpdateMapInfo(MapId);
      finally
        fMaps.Unlock;
      end;
    end;
  end
  else
  begin
    SetSelectedMapInfo;
    MinimapView_MapEd.Hide;
  end;
end;


procedure TKMMenuMapEditor.KeyDown(Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_RETURN:  if Button_MapDeleteConfirm.IsClickable then
                  DeleteClick(Button_MapDeleteConfirm)
                else if Button_MapRenameConfirm.IsClickable then
                  RenameClick(Button_MapRenameConfirm)
                else if Button_MapMoveConfirm.IsClickable then
                  MoveClick(Button_MapMoveConfirm);
    VK_F2:      RenameClick(Button_MapRename);
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
  else
    BackClick(nil);
end;


procedure TKMMenuMapEditor.BackClick(Sender: TObject);
begin
  fMaps.TerminateScan;

  fOnPageChange(gpMainMenu);
end;


procedure TKMMenuMapEditor.DeleteClick(Sender: TObject);
begin
  if not ColumnBox_MapEd.IsSelected then Exit;

  if Sender = Button_MapDelete then
    DeleteConfirm(True);

  if (Sender = Button_MapDeleteConfirm) or (Sender = Button_MapDeleteCancel) then
    DeleteConfirm(False);

  //Delete selected map
  if Sender = Button_MapDeleteConfirm then
  begin
    fMaps.DeleteMap(ColumnBox_MapEd.SelectedItemTag);
    SetSelectedMapInfo;

    RefreshList(True);
  end;
end;


procedure TKMMenuMapEditor.DeleteConfirm(aVisible: Boolean);
begin
  if aVisible then
  begin
    PopUp_Delete.Show;
    ColumnBox_MapEd.Focusable := False; // Will update focus automatically
  end else begin
    PopUp_Delete.Hide;
    ColumnBox_MapEd.Focusable := True; // Will update focus automatically
  end;
end;


procedure TKMMenuMapEditor.RenameClick(Sender: TObject);
begin
  if not ColumnBox_MapEd.IsSelected then Exit;

  if Sender = Button_MapRename then
    RenameConfirm(True);

  if (Sender = Button_MapRenameConfirm) or (Sender = Button_MapRenameCancel) then
    RenameConfirm(False);

  // Change name of the save
  if Sender = Button_MapRenameConfirm then
  begin
    Edit_Rename.Text := Trim(Edit_Rename.Text);
    fMaps.RenameMap(ColumnBox_MapEd.SelectedItemTag, Edit_Rename.Text);
    SetSelectedMapInfo(fSelectedMapInfo.CRC, Edit_Rename.Text);
    ListUpdate;
  end;
end;


// Check if new name is allowed
procedure TKMMenuMapEditor.Edit_Rename_Change(Sender: TObject);
begin
  Button_MapRenameConfirm.Enabled := (Trim(Edit_Rename.Text) <> '') and not fMaps.Contains(Trim(Edit_Rename.Text));
end;


procedure TKMMenuMapEditor.RenameConfirm(aVisible: Boolean);
begin
  if aVisible then
  begin
    Edit_Rename.Text := fMaps[ColumnBox_MapEd.SelectedItemTag].FileName;
    Button_MapRenameConfirm.Enabled := False;
    PopUp_Rename.Show;
  end else
    PopUp_Rename.Hide;
end;


procedure TKMMenuMapEditor.MoveConfirm(aVisible: Boolean);
begin
  if aVisible then
  begin
    PopUp_Move.Show;
    ColumnBox_MapEd.Focusable := False; // Will update focus automatically
  end else begin
    PopUp_Move.Hide;
    ColumnBox_MapEd.Focusable := True; // Will update focus automatically
  end;
end;


procedure TKMMenuMapEditor.SetSelectedMapInfo(aID: Integer = -1);
var CRC: Cardinal;
    Name: UnicodeString;
begin
  if (aID <> -1) then
  begin
    CRC := fMaps[aID].MapAndDatCRC;
    Name := fMaps[aID].FileName;
  end else begin
    CRC := 0;
    Name := '';
  end;
  SetSelectedMapInfo(CRC, Name);
end;


procedure TKMMenuMapEditor.SetSelectedMapInfo(aCRC: Cardinal; const aName: UnicodeString);
begin
  fSelectedMapInfo.CRC := aCRC;
  fSelectedMapInfo.Name := aName;
  case Radio_MapType.ItemIndex of
    0:  gGameSettings.MenuMapEdSPMapCRC := aCRC; // Set only CRC, because we do not save selected SP map name
    1:  begin
          gGameSettings.MenuMapEdMPMapCRC := aCRC;
          gGameSettings.MenuMapEdMPMapName := aName;
        end;
    3:  gGameSettings.MenuMapEdDLMapCRC := aCRC; // Set only CRC, because we do not save selected DL map name
  end;
end;


procedure TKMMenuMapEditor.MoveEditChange(Sender: TObject);
var
  SaveName: string;
begin
  // Do not allow empty file name
  if Trim(Edit_MapMove.Text) = '' then
  begin
    CheckBox_MoveExists.Visible := False;
    Label_MoveExists.Visible := False;
    Button_MapMoveConfirm.Enabled := False;
    Exit;
  end;

  SaveName := TKMapsCollection.FullPath(Trim(Edit_MapMove.Text), '.dat', mfMP);

  if (Sender = Edit_MapMove) or (Sender = Button_MapMove) then
  begin
    CheckBox_MoveExists.Visible := FileExists(SaveName);
    Label_MoveExists.Visible := CheckBox_MoveExists.Visible;
    CheckBox_MoveExists.Checked := False;
    Button_MapMoveConfirm.Enabled := not CheckBox_MoveExists.Visible;
  end;

  if Sender = CheckBox_MoveExists then
    Button_MapMoveConfirm.Enabled := CheckBox_MoveExists.Checked;
end;

procedure TKMMenuMapEditor.UpdateCampInfo;
var
  Campaign: TKMCampaign;
begin
  Image_Campaign.Visible := ListBox_Campaigns.ItemIndex >= 0;
  if ListBox_Campaigns.ItemIndex < 0 then
    Exit;

  Campaign := gGameApp.Campaigns[ListBox_Campaigns.ItemIndex];
  Image_Campaign.RX := Campaign.BackGroundPic.RX;
  Image_Campaign.TexID := Campaign.BackGroundPic.ID;
end;

procedure TKMMenuMapEditor.UpdateCampMapInfo;
var
  MapIndex: Integer;
  Campaign: TKMCampaign;
begin
  MapIndex := Math.Min(ColumnBox_MapEd.SelectedItemTag, ColumnBox_MapEd.RowCount - 1);
  if (MapIndex < 0) or not ColumnBox_MapEd.IsSelected then
    Exit;

  Campaign := gGameApp.Campaigns[ListBox_Campaigns.ItemIndex];

  fMinimap.LoadFromMission(Campaign.GetMissionFile(MapIndex), []);
  fMinimap.Update(True);
  MinimapView_MapEd.SetMinimap(fMinimap);
  MinimapView_MapEd.Show;

  Memo_MapDesc.Text := Campaign.GetMissionBriefing(MapIndex);
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
  Map: TKMapInfo;
  LabelHeight: Integer;
begin
  if aID <> -1 then
  begin
    if fMinimapLastListId = aID then Exit; //Do not reload same minimap

    fMinimapLastListId := aID;
    Map := fMaps[aID];
    fMinimap.LoadFromMission(Map.FullPath('.dat'), []);
    fMinimap.Update(True);
    MinimapView_MapEd.SetMinimap(fMinimap);
    MinimapView_MapEd.Show;
    Panel_MapInfo.Show;
    Map.LoadExtra;
    Memo_MapDesc.Text := Map.BigDesc;
    if Map.HasReadme then
      Button_ViewReadme.Show
    else
      Button_ViewReadme.Hide;

    Label_MapType.Caption := '';

    if Map.TxtInfo.IsCoop then
      Label_MapType.Caption := AddLabelDesc(Label_MapType.Caption, gResTexts[TX_LOBBY_MAP_COOP]);

    if Map.TxtInfo.IsSpecial then
      Label_MapType.Caption := AddLabelDesc(Label_MapType.Caption, gResTexts[TX_LOBBY_MAP_SPECIAL]);

    if Map.TxtInfo.IsPlayableAsSP then
      Label_MapType.Caption := AddLabelDesc(Label_MapType.Caption, gResTexts[TX_MENU_MAP_PLAYABLE_AS_SP]);

    if Label_MapType.Caption = '' then
    begin
      Memo_MapDesc.AbsTop := MinimapView_MapEd.AbsBottom + 15;
      Memo_MapDesc.Height := Panel_MapInfo.Height - 209 - (Button_ViewReadme.Height + 5) * Byte(Button_ViewReadme.Visible);
      Button_ViewReadme.AbsTop := Memo_MapDesc.AbsBottom + 5;
      Label_MapType.Hide;
    end else
    begin
      LabelHeight := gRes.Fonts[Label_MapType.Font].GetTextSize(Label_MapType.Caption).Y;
      Memo_MapDesc.Top := MinimapView_MapEd.Bottom + 15 + LabelHeight;
      Memo_MapDesc.Height := Panel_MapInfo.Height - 209 - LabelHeight - (Button_ViewReadme.Height + 5) * Byte(Button_ViewReadme.Visible);
      Button_ViewReadme.Top := Memo_MapDesc.Bottom + 5;
      Label_MapType.Show;
    end;
  end else begin
    MinimapView_MapEd.Hide;
    Panel_MapInfo.Hide;
    Memo_MapDesc.Clear;
  end;
end;


procedure TKMMenuMapEditor.MoveClick(Sender: TObject);
var
  ID: Integer;
begin
  Assert(Radio_MapType.ItemIndex = 2);

  if not ColumnBox_MapEd.IsSelected then Exit;

  if Sender = Button_MapMove then
  begin
    ID := ColumnBox_MapEd.SelectedItemTag;
    Edit_MapMove.Text := fMaps[ID].FileNameWithoutHash;
    MoveConfirm(True);
    MoveEditChange(Button_MapMove);
  end;

  if (Sender = Button_MapMoveConfirm) or (Sender = Button_MapMoveCancel) then
    MoveConfirm(False);

  //Move selected map
  if Sender = Button_MapMoveConfirm then
  begin
    fMaps.MoveMap(ColumnBox_MapEd.SelectedItemTag, Edit_MapMove.Text, mfMP);
    SetSelectedMapInfo(fSelectedMapInfo.CRC, Edit_MapMove.Text); // Update Name of selected item in list
    ColumnBox_MapEd.Focus;
    ListUpdate;
  end;
end;


procedure TKMMenuMapEditor.Show;
begin
  // we can get access to gGameApp only here, because in Create it could still be nil
  Radio_MapType.ItemIndex := gGameSettings.MenuMapEdMapType;

  RefreshCampaignsList;
  UpdateCampInfo;

  ListUpdate;
  UpdateUI;

  Panel_MapEd.Show;
  ColumnBox_MapEd.Focus;
end;


procedure TKMMenuMapEditor.UpdateState;
begin
  fMaps.UpdateState;
end;


end.
