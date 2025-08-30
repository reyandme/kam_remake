unit KM_GUIMenuReplays;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLType, {$ENDIF}
  Classes, SysUtils, Math,
  KM_CommonTypes,
  KM_Controls, KM_ControlsBase, KM_ControlsEdit, KM_ControlsList, KM_ControlsMinimapView, KM_ControlsForm, KM_ControlsSwitch,
  KM_Saves,
  KM_InterfaceDefaults, KM_InterfaceTypes, KM_MinimapGame;


type
  TKMMenuReplays = class(TKMMenuPageCommon)
  private
    fOnPageChange: TKMMenuChangeEventText;

    fSaves: TKMSavesCollection;
    fMinimap: TKMMinimapGame;

    // column id, on which last time minimap was loaded. Avoid multiple loads of same minimap, which could happen on every RefreshList
    fMinimapLastListId: Integer;
    fScanCompleted: Boolean;      // True, after scan was completed

    fSelectedSaveName: UnicodeString;

    fLoadKind: TKMGameStartMode;

    procedure UpdateUI;
    procedure ListUpdate;
    procedure LoadMinimap(aID: Integer = -1);
    procedure SetSelectedSaveInfo(aID: Integer = -1); overload;
    procedure SetSelectedSaveName(const aName: UnicodeString); overload;
    function  IsSaveValidNotStrictly(aID: Integer): Boolean;
    function  IsSaveValidStrictly(aID: Integer): Boolean;

    procedure Replays_ListClick(Sender: TObject);
    procedure Replay_TypeChange(Sender: TObject);
    procedure Replays_ScanUpdate(Sender: TObject);
    procedure Replays_ScanTerminate(Sender: TObject);
    procedure Replays_SortUpdate(Sender: TObject);
    procedure Replays_RefreshList(aJumpToSelected:Boolean);
    procedure Replays_Sort(Sender: TObject; const aColumn: Integer);
    procedure Replays_Play(Sender: TObject);
    procedure BackClick(Sender: TObject);
    procedure DeleteClick(Sender: TObject);
    procedure DeleteConfirm(aVisible: Boolean);
    procedure RenameClick(Sender: TObject);
    procedure Edit_Rename_Change(Sender: TObject);
    procedure RenameConfirm(aVisible: Boolean);
    procedure EscKeyDown(Sender: TObject);
    procedure KeyDown(Sender: TObject; Key: Word; Shift: TShiftState);
  protected
    Panel_Replays: TKMPanel;
      Radio_Replays_Type: TKMRadioGroup;
      ColumnBox_Replays: TKMColumnBox;
      Button_ReplaysPlay: TKMButton;
      Button_ReplaysBack: TKMButton;
      MinimapView_Replay: TKMMinimapView;

      // Popups
      Form_Delete: TKMForm;
        Label_DeleteConfirm: TKMLabel;
        Button_Delete, Button_DeleteConfirm, Button_DeleteCancel: TKMButton;
      Form_Rename: TKMForm;
        Image_Rename: TKMImage;
        FilenameEdit_Rename: TKMFilenameEdit;
        Button_Rename, Button_RenameConfirm, Button_RenameCancel: TKMButton;
  public
    OnNewReplay: TUnicodeStringEvent;

    constructor Create(aParent: TKMPanel; aOnPageChange: TKMMenuChangeEventText);
    destructor Destroy; override;

    procedure Show;
    procedure UpdateState;
  end;


implementation
uses
  KM_CommonUtils, KM_Pics, KM_Defaults, KM_Log,
  KM_RenderUI,
  KM_ResTexts, KM_ResFonts, KM_ResTypes,
  KM_GameSettings,
  KM_MapTypes;

const
  MINIMAP_NOT_LOADED = -100; // smth, but not -1, as -1 is used for ColumnBox.ItemIndex, when no item is selected


{ TKMMenuReplays }
constructor TKMMenuReplays.Create(aParent: TKMPanel; aOnPageChange: TKMMenuChangeEventText);
const
  PAD = 30;
  BTN_LEFT = 180;
begin
  inherited Create(gpReplays);

  fOnPageChange := aOnPageChange;
  OnEscKeyDown := EscKeyDown;
  OnKeyDown := KeyDown;

  fSaves := TKMSavesCollection.Create;
  fMinimap := TKMMinimapGame.Create(True);

  Panel_Replays := TKMPanel.Create(aParent, 0, 0, aParent.Width, aParent.Height);
  Panel_Replays.AnchorsStretch;

  TKMLabel.Create(Panel_Replays, aParent.Width div 2, 45, gResTexts[TX_MENU_LOAD_LIST], fntOutline, taCenter);

  TKMBevel.Create(Panel_Replays, PAD, 86, aParent.Width - 2*PAD, 46);
  Radio_Replays_Type := TKMRadioGroup.Create(Panel_Replays, PAD + 8, 91, 250, 40, fntGrey);
  Radio_Replays_Type.ItemIndex := 0;
  Radio_Replays_Type.Add(gResTexts[TX_MENU_MAPED_SPMAPS]);
  Radio_Replays_Type.Add(gResTexts[TX_MENU_MAPED_MPMAPS]);
  Radio_Replays_Type.OnChange := Replay_TypeChange;

  ColumnBox_Replays := TKMColumnBox.Create(Panel_Replays, PAD, 140, aParent.Width - 2*PAD, 400, fntMetal, bsMenu);
  ColumnBox_Replays.SetColumns(fntOutline,
                               ['', gResTexts[TX_MENU_LOAD_FILE], gResTexts[TX_MENU_LOAD_DATE], gResTexts[TX_MENU_LOAD_MAP_NAME],
                                gResTexts[TX_MENU_LOAD_TIME], gResTexts[TX_MENU_LOAD_GAME_VERSION]],
                               [0, 22, 440, 580, 805, 885]);
  ColumnBox_Replays.Anchors := [anLeft,anTop,anBottom];
  ColumnBox_Replays.ShowHintWhenShort := True;
  ColumnBox_Replays.HintBackColor := TKMColor4f.New(87, 72, 37);
  ColumnBox_Replays.SearchColumn := 1;
  ColumnBox_Replays.ColumnIdForScroll := 2;
  ColumnBox_Replays.OnChange := Replays_ListClick;
  ColumnBox_Replays.OnColumnClick := Replays_Sort;
  ColumnBox_Replays.OnDoubleClick := Replays_Play;

  MinimapView_Replay := TKMMinimapView.Create(fMinimap, Panel_Replays, PAD + 580, 555, 191, 191, True);
  MinimapView_Replay.Anchors := [anLeft, anBottom];

  Button_ReplaysPlay := TKMButton.Create(Panel_Replays, BTN_LEFT, 560, 350, 30, gResTexts[TX_MENU_VIEW_REPLAY], bsMenu);
  Button_ReplaysPlay.Anchors := [anLeft,anBottom];
  Button_ReplaysPlay.OnClick := Replays_Play;

  Button_Rename := TKMButton.Create(Panel_Replays, BTN_LEFT, 597, 350, 30, gResTexts[TX_MENU_REPLAY_RENAME], bsMenu);
  Button_Rename.Anchors := [anLeft,anBottom];
  Button_Rename.OnClick := RenameClick;

  Button_Delete := TKMButton.Create(Panel_Replays, BTN_LEFT, 634, 350, 30, gResTexts[TX_MENU_REPLAY_DELETE], bsMenu);
  Button_Delete.Anchors := [anLeft,anBottom];
  Button_Delete.OnClick := DeleteClick;

  Button_ReplaysBack := TKMButton.Create(Panel_Replays, BTN_LEFT, 700, 350, 30, gResTexts[TX_MENU_BACK], bsMenu);
  Button_ReplaysBack.Anchors := [anLeft,anBottom];
  Button_ReplaysBack.OnClick := BackClick;

  Form_Delete := TKMForm.Create(Panel_Replays, 400, 200, gResTexts[TX_MENU_REPLAY_DELETE_TITLE], fbGray, False, False);
  // Keep the pop-up centered
  Form_Delete.Left := (Panel_Replays.Width div 2) - (Form_Delete.Width div 2);
  Form_Delete.Top := (Panel_Replays.Height div 2) - 90;

  Label_DeleteConfirm := TKMLabel.Create(Form_Delete.ItemsPanel, 25, 50, 350, 75, gResTexts[TX_MENU_REPLAY_DELETE_CONFIRM], fntMetal, taCenter);
  Label_DeleteConfirm.WordWrap := True;

  Button_DeleteConfirm := TKMButton.Create(Form_Delete.ItemsPanel, 20, 155, 170, 30, gResTexts[TX_MENU_LOAD_DELETE_DELETE], bsMenu);
  Button_DeleteConfirm.OnClick := DeleteClick;

  Button_DeleteCancel  := TKMButton.Create(Form_Delete.ItemsPanel, 210, 155, 170, 30, gResTexts[TX_MENU_LOAD_DELETE_CANCEL], bsMenu);
  Button_DeleteCancel.OnClick := DeleteClick;

  Form_Rename := TKMForm.Create(Panel_Replays, 400, 200, gResTexts[TX_MENU_REPLAY_RENAME_TITLE], fbGray, False, False);
  // Keep the pop-up centered
  Form_Rename.Left := (Panel_Replays.Width div 2) - (Form_Rename.Width div 2);
  Form_Rename.Top := (Panel_Replays.Height div 2) - 90;

  TKMLabel.Create(Form_Rename.ItemsPanel, 25, 75, 60, 20, gResTexts[TX_MENU_REPLAY_RENAME_NAME], fntMetal, taLeft);

  FilenameEdit_Rename := TKMFilenameEdit.Create(Form_Rename.ItemsPanel, 105, 72, 275, 20, fntMetal);
  FilenameEdit_Rename.OnChange := Edit_Rename_Change;

  Button_RenameConfirm := TKMButton.Create(Form_Rename.ItemsPanel, 20, 155, 170, 30, gResTexts[TX_MENU_REPLAY_RENAME_CONFIRM], bsMenu);
  Button_RenameConfirm.OnClick := RenameClick;

  Button_RenameCancel := TKMButton.Create(Form_Rename.ItemsPanel, 210, 155, 170, 30, gResTexts[TX_MENU_LOAD_DELETE_CANCEL], bsMenu);
  Button_RenameCancel.OnClick := RenameClick;
end;


destructor TKMMenuReplays.Destroy;
begin
  fSaves.Free;
  fMinimap.Free;

  inherited;
end;


function TKMMenuReplays.IsSaveValidNotStrictly(aID: Integer): Boolean;
begin
  Result := InRange(aID, 0, fSaves.Count - 1)
            and fSaves[aID].IsValid
            and fSaves[aID].IsReplayValid;
end;


function TKMMenuReplays.IsSaveValidStrictly(aID: Integer): Boolean;
begin
  Result := InRange(aID, 0, fSaves.Count - 1)
            and fSaves[aID].IsValidStrictly
            and fSaves[aID].IsReplayValid;
end;


procedure TKMMenuReplays.UpdateUI;
var
  ID: Integer;
begin
  ID := ColumnBox_Replays.ItemIndex;

  if IsSaveValidStrictly(ID) then
  begin
    Button_ReplaysPlay.Enable;
    Button_ReplaysPlay.Caption := gResTexts[TX_MENU_VIEW_REPLAY];
    fLoadKind := gsmStart;
  end
  else
  if IsSaveValidNotStrictly(ID) then
  begin
    Button_ReplaysPlay.Enable;
    Button_ReplaysPlay.Caption := gResTexts[TX_MENU_REPLAY_TRY_TO_VIEW];
    fLoadKind := gsmStartWithWarn;
  end
  else
  begin
    Button_ReplaysPlay.Disable;
    Button_ReplaysPlay.Caption := gResTexts[TX_MENU_VIEW_REPLAY];
    fLoadKind := gsmNoStart;
  end;

  Button_Delete.Enabled := InRange(ID, 0, fSaves.Count-1);
  Button_Rename.Enabled := InRange(ID, 0, fSaves.Count-1);

  if (ColumnBox_Replays.ItemIndex = -1) then
    MinimapView_Replay.Hide;
end;


procedure TKMMenuReplays.SetSelectedSaveInfo(aID: Integer = -1);
var
  name: UnicodeString;
begin
  if (aID <> -1) then
    name := fSaves[aID].FileName
  else
    name := '';
  SetSelectedSaveName(name);
end;


procedure TKMMenuReplays.SetSelectedSaveName(const aName: UnicodeString);
begin
  fSelectedSaveName := aName;
  case Radio_Replays_Type.ItemIndex of
    0:  gGameSettings.MenuReplaySPSaveName := aName;
    1:  gGameSettings.MenuReplayMPSaveName := aName;
  end;
end;


procedure TKMMenuReplays.LoadMinimap(aID: Integer = -1);
var
  loaded: Boolean;
begin
  if not Panel_Replays.Visible then Exit;

  loaded := False;
  if (aID <> -1) then
  begin
    if fLoadKind in [gsmStart, gsmStartWithWarn] then
    begin
      if fMinimapLastListId = aID then
      begin
        MinimapView_Replay.Show;
        Exit; //Do not reload same minimap
      end;

      try
        if fSaves[aID].LoadMinimap(fMinimap) then
        begin
          fMinimapLastListId := aID;
          MinimapView_Replay.Show;
          loaded := True;
        end;
      except
        on E: Exception do
          gLog.AddTime('Error loading minimap for replay ' + fSaves[aID].Path); //Silently catch exception
      end;
    end;
  end;
  if not loaded then
    MinimapView_Replay.Hide;
end;


procedure TKMMenuReplays.Replays_ListClick(Sender: TObject);
var
  ID: Integer;
begin
  fSaves.Lock;
  try
    ID := ColumnBox_Replays.ItemIndex;

    UpdateUI;

    if Sender = ColumnBox_Replays then
      DeleteConfirm(False);

    if InRange(ID, 0, fSaves.Count-1) then
      SetSelectedSaveInfo(ID)
    else
      SetSelectedSaveInfo;

    LoadMinimap(ID);
  finally
    fSaves.Unlock;
  end;
end;


procedure TKMMenuReplays.ListUpdate;
begin
  fSaves.TerminateScan;

   //Reset scan variables
  fScanCompleted := False;
  fMinimapLastListId := MINIMAP_NOT_LOADED;

  case Radio_Replays_Type.ItemIndex of
    0:  fSelectedSaveName := gGameSettings.MenuReplaySPSaveName;
    1:  fSelectedSaveName := gGameSettings.MenuReplayMPSaveName;
  end;

  ColumnBox_Replays.Clear;
  UpdateUI;
  fSaves.Refresh(Replays_ScanUpdate, (Radio_Replays_Type.ItemIndex = 1), Replays_ScanTerminate);
end;


procedure TKMMenuReplays.Replay_TypeChange(Sender: TObject);
begin
  gGameSettings.MenuReplaysType := Radio_Replays_Type.ItemIndex;
  ListUpdate;
  DeleteConfirm(False);
  RenameConfirm(False);
  gGameSettings.MenuReplaysType := Radio_Replays_Type.ItemIndex;
end;


procedure TKMMenuReplays.Replays_ScanUpdate(Sender: TObject);
begin
  if not fScanCompleted then  // Don't refresh list, if scan was completed already
    Replays_RefreshList(False); //Don't jump to selected with each scan update
end;


procedure TKMMenuReplays.Replays_ScanTerminate(Sender: TObject);
begin
  fScanCompleted := True;
  Replays_RefreshList(True); //After scan complete jump to the selected item
end;


procedure TKMMenuReplays.Replays_SortUpdate(Sender: TObject);
begin
  Replays_RefreshList(True); //After sorting jump to the selected item
end;


procedure TKMMenuReplays.Replays_RefreshList(aJumpToSelected: Boolean);
var
  I, prevTop: Integer;
  row: TKMListRow;
  color: Cardinal;
begin
  prevTop := ColumnBox_Replays.TopIndex;
  ColumnBox_Replays.Clear;

  fSaves.Lock;
  try
    for I := 0 to fSaves.Count - 1 do
    begin
      if fSaves[I].IsValidStrictly then
        color := clSaveLoadOk
      else
      if fSaves[I].IsValid then
        color := clSaveLoadTry
      else
        color := clSaveLoadError;

      row := MakeListRow(['', fSaves[I].FileName, fSaves[I].GameInfo.GetSaveTimestamp, fSaves[I].GameInfo.Title,
                          TickToTimeStr(fSaves[I].GameInfo.TickCount), fSaves[I].GameInfo.VersionU],
                         [color, color, color, color, color, color]);
      row.Cells[0].Pic := MakePic(rxGui, 657 + Byte(fSaves[I].GameInfo.MissionMode = mmFighting));
      ColumnBox_Replays.AddItem(row);
    end;

    for I := 0 to fSaves.Count - 1 do
      if (fSaves[I].FileName = fSelectedSaveName) then
        ColumnBox_Replays.ItemIndex := I;
  finally
    fSaves.Unlock;
  end;

  ColumnBox_Replays.TopIndex := prevTop;

  if aJumpToSelected and (ColumnBox_Replays.ItemIndex <> -1)
  and not InRange(ColumnBox_Replays.ItemIndex - ColumnBox_Replays.TopIndex, 0, ColumnBox_Replays.GetVisibleRows-1)
  then
    if ColumnBox_Replays.ItemIndex < ColumnBox_Replays.TopIndex then
      ColumnBox_Replays.TopIndex := ColumnBox_Replays.ItemIndex
    else
    if ColumnBox_Replays.ItemIndex > ColumnBox_Replays.TopIndex + ColumnBox_Replays.GetVisibleRows - 1 then
      ColumnBox_Replays.TopIndex := ColumnBox_Replays.ItemIndex - ColumnBox_Replays.GetVisibleRows + 1;

  UpdateUI;

  if ColumnBox_Replays.IsSelected then
    LoadMinimap(ColumnBox_Replays.ItemIndex);
end;


procedure TKMMenuReplays.Replays_Sort(Sender: TObject; const aColumn: Integer);
var
  sortMethod: TKMSavesSortMethod;
begin
  with ColumnBox_Replays do
    case SortIndex of
      //Sorting by filename goes A..Z by default
      0:  if SortDirection = sdDown then
            sortMethod := smByModeDesc
          else
            sortMethod := smByModeAsc;
      1:  if SortDirection = sdDown then
            sortMethod := smByFileNameDesc
          else
            sortMethod := smByFileNameAsc;
      //Sorting by description goes Old..New by default
      2:  if SortDirection = sdDown then
            sortMethod := smByDateDesc
          else
            sortMethod := smByDateAsc;
      //Sorting by description goes A..Z by default
      3:  if SortDirection = sdDown then
            sortMethod := smByMapNameDesc
          else
            sortMethod := smByMapNameAsc;
      4:  if SortDirection = sdDown then
            sortMethod := smByTimeDesc
          else
            sortMethod := smByTimeAsc;
      5:  if SortDirection = sdDown then
            sortMethod := smByGameVersionDesc
          else
            sortMethod := smByGameVersionAsc;
    else
      if SortDirection = sdDown then
        sortMethod := smByFileNameDesc
      else
        sortMethod := smByFileNameAsc;
    end;

  fSaves.Sort(sortMethod, Replays_SortUpdate);
end;


procedure TKMMenuReplays.Replays_Play(Sender: TObject);
var
  ID: Integer;
  loadError: UnicodeString;

  procedure DoPlay;
  begin
    if Assigned(OnNewReplay) then
      OnNewReplay(fSaves[ID].Path + fSaves[ID].FileName + EXT_SAVE_BASE_DOT);
  end;

begin
  if not Button_ReplaysPlay.Enabled then Exit; //This is also called by double clicking

  ID := ColumnBox_Replays.ItemIndex;
  if not InRange(ID, 0, fSaves.Count - 1) then Exit;
  fSaves.TerminateScan; //stop scan as it is no longer needed

  case fLoadKind of
    gsmNoStart, gsmNoStartWithWarn: ;
    gsmStart: DoPlay;
    gsmStartWithWarn:
      begin
        try
          DoPlay;
        except
          on E: Exception do
          begin
            loadError := Format(gResTexts[TX_UNSUPPORTED_REPLAY_LOAD_ERROR_MSG], [fSaves[ID].GameInfo.Version, fSaves[ID].Path])
              + '||' + E.ClassName + ': ' + E.Message;
            gLog.AddTime('Replay load Exception: ' + loadError
              {$IFDEF WDC} + sLineBreak + E.StackTrace {$ENDIF}
              );
            fOnPageChange(gpError, loadError);
          end;
        end;
      end;
  end;
end;


procedure TKMMenuReplays.EscKeyDown(Sender: TObject);
begin
  if Button_RenameCancel.IsClickable then
    RenameClick(Button_RenameCancel)
  else if Button_DeleteCancel.IsClickable then
    DeleteClick(Button_DeleteCancel)
  else
    BackClick(nil);
end;


procedure TKMMenuReplays.BackClick(Sender: TObject);
begin
  //Scan should be terminated, it is no longer needed
  fSaves.TerminateScan;

  fOnPageChange(gpMainMenu);
end;


procedure TKMMenuReplays.DeleteConfirm(aVisible: Boolean);
begin
  if not Panel_Replays.Visible then Exit;

  if aVisible then
  begin
    Form_Delete.Show;
    ColumnBox_Replays.Focusable := False; // Will update focus automatically
  end else begin
    Form_Delete.Hide;
    ColumnBox_Replays.Focusable := True; // Will update focus automatically
  end;
end;


procedure TKMMenuReplays.DeleteClick(Sender: TObject);
var
  oldSelection, newSelection: Integer;
begin
  if ColumnBox_Replays.ItemIndex = -1 then Exit;

  if Sender = Button_Delete then
    DeleteConfirm(True);

  if (Sender = Button_DeleteConfirm) or (Sender = Button_DeleteCancel) then
    DeleteConfirm(False);

  //Delete the save
  if Sender = Button_DeleteConfirm then
  begin
    oldSelection := ColumnBox_Replays.ItemIndex;
    fSaves.DeleteSave(ColumnBox_Replays.ItemIndex);

    if ColumnBox_Replays.RowCount > 1 then
    begin
      newSelection := EnsureRange(oldSelection, 0, ColumnBox_Replays.RowCount - 2);
      SetSelectedSaveInfo(newSelection);
    end else
      SetSelectedSaveInfo;

    Replays_RefreshList(True);
  end;
end;


procedure TKMMenuReplays.RenameConfirm(aVisible: Boolean);
begin
  if not Panel_Replays.Visible then Exit;

  if aVisible then
  begin
    FilenameEdit_Rename.Text := fSaves[ColumnBox_Replays.ItemIndex].FileName;
    Button_RenameConfirm.Enabled := False;
    Form_Rename.Show;
  end else
    Form_Rename.Hide;
end;


// Check if new name is allowed
procedure TKMMenuReplays.Edit_Rename_Change(Sender: TObject);
begin
  Button_RenameConfirm.Enabled := FilenameEdit_Rename.IsValid and not fSaves.Contains(Trim(FilenameEdit_Rename.Text));
end;


procedure TKMMenuReplays.KeyDown(Sender: TObject; Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_RETURN:  if Form_Rename.Visible and Button_RenameConfirm.IsClickable then
                  RenameClick(Button_RenameConfirm)
                else if Form_Delete.Visible and Button_DeleteConfirm.IsClickable then
                  DeleteClick(Button_DeleteConfirm);
    VK_F2:      RenameClick(Button_Rename);
    VK_DELETE:  DeleteClick(Button_Delete);
  end;
end;


procedure TKMMenuReplays.RenameClick(Sender: TObject);
begin
  if ColumnBox_Replays.ItemIndex = -1 then Exit;

  if Sender = Button_Rename then
    RenameConfirm(True);

  if (Sender = Button_RenameConfirm) or (Sender = Button_RenameCancel) then
    RenameConfirm(False);

  // Change name of the save
  if Sender = Button_RenameConfirm then
  begin
    FilenameEdit_Rename.Text := Trim(FilenameEdit_Rename.Text);
    fSaves.RenameSave(ColumnBox_Replays.ItemIndex, FilenameEdit_Rename.Text);
    SetSelectedSaveName(FilenameEdit_Rename.Text);
    ListUpdate;
  end;
end;

procedure TKMMenuReplays.Show;
begin
  Panel_Replays.Show;
  //Copy/Pasted from SwitchPage for now (needed that for ResultsMP BackClick)
  //Probably needs some cleanup when we have GUIMenuReplays
  Radio_Replays_Type.ItemIndex := gGameSettings.MenuReplaysType;
  Replay_TypeChange(nil); //Select SP as this will refresh everything
  Replays_Sort(nil, ColumnBox_Replays.SortIndex); //Apply sorting from last time we were on this page
end;


procedure TKMMenuReplays.UpdateState;
begin
  fSaves.UpdateState;
end;


end.
