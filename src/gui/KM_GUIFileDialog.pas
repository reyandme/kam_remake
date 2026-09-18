unit KM_GUIFileDialog;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils,
  KM_Controls, KM_ControlsBase, KM_ControlsList, KM_ControlsForm;

type
  TKMFileDialogEvent = procedure (const aFileName: string) of object;

  TKMGUIFileDialog = class
  private
    fExtension: string;
    fPath: string;
    fOnFileSelected: TKMFileDialogEvent;

    procedure FileChange(Sender: TObject);
    procedure FileDoubleClick(Sender: TObject);
    procedure DriveClick(Sender: TObject);
    procedure OkClick(Sender: TObject);
    procedure CancelClick(Sender: TObject);

    procedure UpdateDrives;
    procedure UpdateList;
    procedure SelectFile;
  protected
    Form_FileDialog: TKMForm;
    ButtonFlat_Drives: array ['A'..'Z'] of TKMButtonFlat;
    Label_Path: TKMLabel;
    ColumnBox_Files: TKMColumnBox;
    Button_Ok, Button_Cancel: TKMButton;
  public
    constructor Create(aParent: TKMPanel; const aCaption: UnicodeString; const aExtension: string; aOnFileSelected: TKMFileDialogEvent);

    procedure Show(const aStartPath: string);
    procedure Hide;
    function IsVisible: Boolean;
  end;


implementation
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  Math,
  KM_RenderUI,
  KM_ResFonts, KM_ResTexts, KM_ResTypes, KM_Resource, KM_Pics;


const
  CONTENT_W = 600;
  CONTENT_H = 500;

  DRIVE_BUTTON_W = 50;
  DRIVE_BUTTON_H = 30;
  DRIVE_BUTTON_GAP = 5;
  DRIVE_BUTTON_TEX = 38;
  DRIVE_TEX_OFFSET_X = -10;
  DRIVE_TEX_OFFSET_Y = 6;
  DRIVE_CAP_OFFSET_X = 12;
  DRIVE_CAP_OFFSET_Y = -10;

  DRIVE_ICON_FLOPPY = 702;
  DRIVE_ICON_REMOVABLE = 703;
  DRIVE_ICON_FIXED = 700;
  DRIVE_ICON_REMOTE = 704;
  DRIVE_ICON_CDROM = 701;
  DRIVE_ICON_RAMDISK = 705;
  ICON_FOLDER_UP = 710;
  ICON_FOLDER = 711;
  ICON_FILE = 712;
  ICON_OFFSET_Y = -2;

  GAP = 3;
  PATH_H = 24;
  PATH_PAD = 4;
  PATH_LABEL_H = 20;
  LIST_LEFT_COLUMN = 20;
  LIST_SIZE_COLUMN_FROM_RIGHT = 260;
  LIST_DATE_COLUMN_FROM_RIGHT = 125;
  BUTTON_W = 150;
  BUTTON_H = 30;
  BUTTON_GAP = 4;
  BUTTON_BOTTOM = 10;
  BUTTONS_AREA_H = BUTTON_H + 2 * BUTTON_BOTTOM;

  ROW_TAG_FOLDER = 0;
  ROW_TAG_FILE = 1;

  PARENT_FOLDER = '..';
  CURRENT_FOLDER = '.';


function ExistingTex(aTexID: Word): Word;
begin
  if aTexID <= gRes.Sprites[rxGui].RXData.Count then
    Result := aTexID
  else
    Result := 0;
end;


function IsDriveRoot(const aPath: string): Boolean;
begin
  Result := (Length(aPath) = 3) and (aPath[2] = ':') and (aPath[3] = PathDelim);
end;


{ TKMGUIFileDialog }
constructor TKMGUIFileDialog.Create(aParent: TKMPanel; const aCaption: UnicodeString; const aExtension: string;
                                    aOnFileSelected: TKMFileDialogEvent);
const
  DRIVE_TOP = 0;
  PATH_TOP = DRIVE_TOP + DRIVE_BUTTON_H + GAP;
  LIST_TOP = PATH_TOP + PATH_H + GAP;
var
  drive: Char;
  listHeight: Integer;
begin
  inherited Create;

  fExtension := aExtension;
  fOnFileSelected := aOnFileSelected;

  Form_FileDialog := TKMForm.Create(aParent, CONTENT_W, CONTENT_H, aCaption, fbYellow, True, False, True);
  Form_FileDialog.HandleCloseKey := True;

  for drive := Low(ButtonFlat_Drives) to High(ButtonFlat_Drives) do
  begin
    ButtonFlat_Drives[drive] := TKMButtonFlat.Create(Form_FileDialog.ItemsPanel, 0, DRIVE_TOP, DRIVE_BUTTON_W, DRIVE_BUTTON_H,
                                                     ExistingTex(DRIVE_BUTTON_TEX), rxGui);
    ButtonFlat_Drives[drive].TexOffsetX := DRIVE_TEX_OFFSET_X;
    ButtonFlat_Drives[drive].TexOffsetY := DRIVE_TEX_OFFSET_Y;
    ButtonFlat_Drives[drive].CapOffsetX := DRIVE_CAP_OFFSET_X;
    ButtonFlat_Drives[drive].CapOffsetY := DRIVE_CAP_OFFSET_Y;
    ButtonFlat_Drives[drive].Caption := drive;
    ButtonFlat_Drives[drive].OnClick := DriveClick;
    ButtonFlat_Drives[drive].Hide;
  end;

  TKMBevel.Create(Form_FileDialog.ItemsPanel, 0, PATH_TOP, CONTENT_W, PATH_H);
  Label_Path := TKMLabel.Create(Form_FileDialog.ItemsPanel, PATH_PAD, PATH_TOP + PATH_PAD, CONTENT_W - 2 * PATH_PAD, PATH_LABEL_H, '', fntMetal, taLeft);

  listHeight := CONTENT_H - LIST_TOP - GAP - BUTTONS_AREA_H;
  ColumnBox_Files := TKMColumnBox.Create(Form_FileDialog.ItemsPanel, 0, LIST_TOP, CONTENT_W, listHeight, fntMetal, bsMenu);
  ColumnBox_Files.SetColumns(fntOutline, ['', gResTexts[TX_MENU_LOAD_FILE], gResTexts[TX_MENU_MAP_SIZE], gResTexts[TX_MENU_LOAD_DATE]],
                             [0, LIST_LEFT_COLUMN, CONTENT_W - LIST_SIZE_COLUMN_FROM_RIGHT, CONTENT_W - LIST_DATE_COLUMN_FROM_RIGHT]);
  ColumnBox_Files.Columns[2].TextAlign := taRight;
  ColumnBox_Files.Columns[3].TextAlign := taRight;
  ColumnBox_Files.OnChange := FileChange;
  ColumnBox_Files.OnDoubleClick := FileDoubleClick;

  Button_Ok := TKMButton.Create(Form_FileDialog.ItemsPanel, CONTENT_W div 2 - BUTTON_W - BUTTON_GAP div 2, CONTENT_H - BUTTON_H - BUTTON_BOTTOM,
                                BUTTON_W, BUTTON_H, gResTexts[TX_MAPED_OK], bsMenu);
  Button_Ok.OnClick := OkClick;

  Button_Cancel := TKMButton.Create(Form_FileDialog.ItemsPanel, CONTENT_W div 2 + BUTTON_GAP div 2, CONTENT_H - BUTTON_H - BUTTON_BOTTOM,
                                    BUTTON_W, BUTTON_H, gResTexts[TX_MAPED_CANCEL], bsMenu);
  Button_Cancel.OnClick := CancelClick;

  Form_FileDialog.Hide;
end;


procedure TKMGUIFileDialog.Show(const aStartPath: string);
begin
  fPath := IncludeTrailingPathDelimiter(aStartPath);
  Button_Ok.Disable;
  UpdateList;
  Form_FileDialog.Show;
end;


procedure TKMGUIFileDialog.Hide;
begin
  Form_FileDialog.Hide;
end;


function TKMGUIFileDialog.IsVisible: Boolean;
begin
  Result := Form_FileDialog.Visible;
end;


procedure TKMGUIFileDialog.FileChange(Sender: TObject);
begin
  Button_Ok.Enabled := ColumnBox_Files.IsSelected and (ColumnBox_Files.SelectedItemTag = ROW_TAG_FILE);
end;


procedure TKMGUIFileDialog.FileDoubleClick(Sender: TObject);
var
  folderCaption: string;
begin
  if not ColumnBox_Files.IsSelected then
    Exit;

  if ColumnBox_Files.SelectedItemTag = ROW_TAG_FOLDER then
  begin
    folderCaption := ColumnBox_Files.SelectedItem.Cells[1].Caption;
    folderCaption := Copy(folderCaption, 2, Length(folderCaption) - 2);
    fPath := ExpandFileName(fPath + folderCaption + PathDelim);
    Button_Ok.Disable;
    UpdateList;
  end
  else
    SelectFile;
end;


procedure TKMGUIFileDialog.DriveClick(Sender: TObject);
begin
  fPath := TKMButtonFlat(Sender).Caption + ':' + PathDelim;
  Button_Ok.Disable;
  UpdateList;
end;


procedure TKMGUIFileDialog.OkClick(Sender: TObject);
begin
  SelectFile;
end;


procedure TKMGUIFileDialog.CancelClick(Sender: TObject);
begin
  Hide;
end;


procedure TKMGUIFileDialog.SelectFile;
var
  fileName: string;
begin
  if not ColumnBox_Files.IsSelected or (ColumnBox_Files.SelectedItemTag <> ROW_TAG_FILE) then
    Exit;

  fileName := fPath + ColumnBox_Files.SelectedItem.Cells[1].Caption;
  Hide;

  if Assigned(fOnFileSelected) then
    fOnFileSelected(fileName);
end;


procedure TKMGUIFileDialog.UpdateDrives;
{$IFDEF MSWindows}
const
  DRIVE_ICONS: array [DRIVE_REMOVABLE..DRIVE_RAMDISK] of Word =
    (DRIVE_ICON_REMOVABLE, DRIVE_ICON_FIXED, DRIVE_ICON_REMOTE, DRIVE_ICON_CDROM, DRIVE_ICON_RAMDISK);
  FLOPPY_DRIVES = ['A'..'B'];
var
  drive: Char;
  driveType: Cardinal;
  left: Integer;
begin
  left := 0;
  for drive := Low(ButtonFlat_Drives) to High(ButtonFlat_Drives) do
  begin
    driveType := GetDriveType(PChar(drive + ':' + PathDelim));

    ButtonFlat_Drives[drive].Visible := driveType > DRIVE_NO_ROOT_DIR;
    if driveType <= DRIVE_NO_ROOT_DIR then
      Continue;

    ButtonFlat_Drives[drive].Down := (fPath <> '') and (UpCase(fPath[1]) = drive);
    if (driveType = DRIVE_REMOVABLE) and CharInSet(drive, FLOPPY_DRIVES) then
      ButtonFlat_Drives[drive].TexID := ExistingTex(DRIVE_ICON_FLOPPY)
    else
    if InRange(driveType, DRIVE_REMOVABLE, DRIVE_RAMDISK) then
      ButtonFlat_Drives[drive].TexID := ExistingTex(DRIVE_ICONS[driveType])
    else
      ButtonFlat_Drives[drive].TexID := ExistingTex(DRIVE_BUTTON_TEX);
    ButtonFlat_Drives[drive].Left := left;
    left := left + DRIVE_BUTTON_W + DRIVE_BUTTON_GAP;
  end;
end;
{$ELSE}
begin
end;
{$ENDIF}


procedure TKMGUIFileDialog.UpdateList;

  function HasExtension(const aFileName: string): Boolean;
  begin
    Result := SameText(ExtractFileExt(aFileName), fExtension);
  end;

var
  searchRec: TSearchRec;
  row: TKMListRow;
begin
  UpdateDrives;
  ColumnBox_Files.Clear;

  if not DirectoryExists(fPath) then
  begin
    Label_Path.Caption := '';
    Label_Path.Hint := '';
    Exit;
  end;

  Label_Path.Caption := fPath;
  Label_Path.Hint := fPath;

  if not IsDriveRoot(fPath) then
  begin
    row := MakeListRow(['', '[' + PARENT_FOLDER + ']', '', ''], ROW_TAG_FOLDER);
    row.Cells[0].Pic := MakePic(rxGui, ExistingTex(ICON_FOLDER_UP), True, 0, ICON_OFFSET_Y);
    ColumnBox_Files.AddItem(row);
  end;

  if FindFirst(fPath + '*', faDirectory, searchRec) = 0 then
  try
    repeat
      if (searchRec.Name <> CURRENT_FOLDER) and (searchRec.Name <> PARENT_FOLDER)
      and (searchRec.Attr and faDirectory = faDirectory) then
      begin
        row := MakeListRow(['', '[' + searchRec.Name + ']', '', ''], ROW_TAG_FOLDER);
        row.Cells[0].Pic := MakePic(rxGui, ExistingTex(ICON_FOLDER), True, 0, ICON_OFFSET_Y);
        ColumnBox_Files.AddItem(row);
      end;
    until FindNext(searchRec) <> 0;
  finally
    SysUtils.FindClose(searchRec);
  end;

  if FindFirst(fPath + '*', faAnyFile, searchRec) = 0 then
  try
    repeat
      if (searchRec.Attr and faDirectory <> faDirectory) and HasExtension(searchRec.Name) then
      begin
        row := MakeListRow(['', searchRec.Name, FormatFloat('#,##0', searchRec.Size), DateToStr(searchRec.TimeStamp)], ROW_TAG_FILE);
        row.Cells[0].Pic := MakePic(rxGui, ExistingTex(ICON_FILE), True, 0, ICON_OFFSET_Y);
        ColumnBox_Files.AddItem(row);
      end;
    until FindNext(searchRec) <> 0;
  finally
    SysUtils.FindClose(searchRec);
  end;
end;


end.
