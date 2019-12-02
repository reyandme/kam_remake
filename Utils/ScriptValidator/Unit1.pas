unit Unit1;
{$WARN SYMBOL_PLATFORM OFF}
{$WARN UNIT_PLATFORM OFF}

interface
uses
  Windows, Messages, Classes, Controls, Dialogs, Forms, StdCtrls, StrUtils, SysUtils,
  FileCtrl,
  KM_Defaults, KM_Scripting, shellapi;

type
  TKMFileOrFolder = (fof_None, fof_File, fof_Folder);

  TForm1 = class(TForm)
    Edit1: TEdit;
    btnBrowseFile: TButton;
    Label1: TLabel;
    btnValidate: TButton;
    OpenDialog: TOpenDialog;
    Memo1: TMemo;
    Label2: TLabel;
    btnValidateAll: TButton;
    btnBrowsePath: TButton;
    FileOpenDlg: TFileOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure btnBrowseFileClick(Sender: TObject);
    procedure btnValidateClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnValidateAllClick(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure btnBrowsePathClick(Sender: TObject);
  private
    fScripting: TKMScripting;
    fIsValidatePath : TKMFileOrFolder;
    fListFileInFolder : TStringList;

    procedure ValidateFileList; overload;
    procedure ValidateDir(aDir: String; aClear: Boolean = True); overload;
    procedure FindFiles(aPath: String; out aList: TStringList);
    function Validate(aPath: string; aReportGood: Boolean): Boolean;
    procedure WMDropFiles(var Msg: TWMDropFiles); message WM_DROPFILES;
    procedure EnableFormComponents(aEnabled : Boolean);
  end;

var
  Form1: TForm1;
implementation
uses
  KM_Maps, KM_CommonUtils;

{$R *.dfm}

procedure TForm1.FindFiles(aPath: String; out aList: TStringList);
var
  SearchRec:TSearchRec;
begin
  FindFirst(aPath + PathDelim + '*', faAnyFile, SearchRec);
  repeat
    if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
      if (SearchRec.Attr and faDirectory = faDirectory) then
        FindFiles(aPath + PathDelim + SearchRec.Name, aList)
      else
        if SameText(ExtractFileExt(SearchRec.Name), '.' + EXT_FILE_SCRIPT) then
          aList.Add(aPath + PathDelim + SearchRec.Name);
  until (FindNext(SearchRec) <> 0);
  FindClose(SearchRec);
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  KmrDir: String;
begin
  KmrDir := ExtractFilePath(ParamStr(0));

  Caption                   := 'KaM Remake Script Validator (' + GAME_REVISION + ')';
  OpenDialog.InitialDir     := KmrDir;
  FileOpenDlg.DefaultFolder := KmrDir;
  fScripting                := TKMScriptingCreator.CreateScripting(nil);
  fListFileInFolder         := TStringList.Create;
  DragAcceptFiles(Handle, True);
  Edit1Change(nil);
end;


procedure TForm1.FormDestroy(Sender: TObject);
begin
  FreeAndNil(fScripting);
  fListFileInFolder.Free;
  DragAcceptFiles(Handle, False);
end;


procedure TForm1.btnBrowseFileClick(Sender: TObject);
begin
  if not OpenDialog.Execute then Exit;
  Edit1.Text := OpenDialog.FileName;
end;


procedure TForm1.btnBrowsePathClick(Sender: TObject);
var
  DirToValidate : String;
begin
  if Win32MajorVersion >= 6 then // For Vista+ Windows version we can use FileOpenDlg
  begin
    FileOpenDlg.FileName := '';
    if FileOpenDlg.Execute then
    begin
      FileOpenDlg.DefaultFolder := FileOpenDlg.FileName;
      Edit1.Text := FileOpenDlg.FileName;
    end;
  end else begin // Fine for XP+
    if SelectDirectory('Select folder to Validate scripts', '', DirToValidate) then
      Edit1.Text := DirToValidate;
  end;
end;


procedure TForm1.Edit1Change(Sender: TObject);
begin
  fIsValidatePath := fof_None;

  if FileExists(Edit1.Text) and (ExtractFileExt(Edit1.Text) = '.' + EXT_FILE_SCRIPT) then
    fIsValidatePath := fof_File
  else
    if SysUtils.DirectoryExists(Edit1.Text) then
      fIsValidatePath := fof_Folder;

  case fIsValidatePath of
    fof_None:   begin
                  if Sender <> nil then
                    Memo1.Text := 'Wrong script file/folder path selected'
                  else
                    Memo1.Text := 'Select file or folder to validate';
                  btnValidate.Enabled := False;
                  btnValidate.Caption := 'Validate';
                end;
    fof_File:   begin
                  Memo1.Text := 'File selected';
                  btnValidate.Enabled := True;
                  btnValidate.Caption := 'Validate file';
                end;
    fof_Folder: begin
                  Memo1.Text := 'Folder selected';
                  btnValidate.Enabled := True;
                  btnValidate.Caption := 'Validate folder';
                end;
  end;
end;


procedure TForm1.EnableFormComponents(aEnabled: Boolean);
begin
  btnBrowsePath.Enabled := aEnabled;
  btnBrowseFile.Enabled := aEnabled;
  btnValidate.Enabled := aEnabled;
  btnValidateAll.Enabled := aEnabled;
  Edit1.Enabled := aEnabled;
end;


procedure TForm1.btnValidateClick(Sender: TObject);
begin
  EnableFormComponents(False);
  Memo1.Lines.Clear;
  if fIsValidatePath = fof_Folder then
  begin
    ExcludeTrailingPathDelimiter(Edit1.Text);
    if not SysUtils.DirectoryExists(Edit1.Text) then
      Memo1.Lines.Append('Directory not found ' + Edit1.Text)
    else
    begin
      fListFileInFolder.Clear;
      FindFiles(Edit1.Text, fListFileInFolder);
      ValidateFileList;
    end;
  end else if fIsValidatePath = fof_File then
    Validate(Edit1.Text, True);

  EnableFormComponents(True);
end;


procedure TForm1.ValidateFileList;
var
  I,ErrFilesCnt: Integer;
begin
  ErrFilesCnt := 0;
  if fListFileInFolder.Count = 0 then
    Memo1.Lines.Append('No files in a directory :(')
  else
  begin
    Memo1.Lines.Append('Files in the folder: '+IntToStr(fListFileInFolder.Count));
    for I := 0 to fListFileInFolder.Count - 1 do
      if not Validate(ChangeFileExt(fListFileInFolder[I], '.' + EXT_FILE_SCRIPT), False) then
        Inc(ErrFilesCnt);

    Memo1.Lines.Append(Format('Checked: %d. Script files with errors: %d', [fListFileInFolder.Count, ErrFilesCnt]));
  end;
end;


procedure TForm1.ValidateDir(aDir: String; aClear: Boolean = True);
begin
  if aClear then
    Memo1.Lines.Clear
  else
    Memo1.Lines.Append('');
  Memo1.Lines.Append('Check ' + aDir);
  TKMapsCollection.GetAllMapPaths(aDir, fListFileInFolder);
  ValidateFileList;
end;


procedure TForm1.btnValidateAllClick(Sender: TObject);
begin
  EnableFormComponents(False);

  // Exe path
  ValidateDir(ExtractFilePath(ParamStr(0)));
  // Utils path
  ValidateDir(ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\'), False);

  EnableFormComponents(True);
end;

function TForm1.Validate(aPath: string; aReportGood: Boolean): Boolean;
var
  CampaignFile: UnicodeString;
  txt:          string;
begin
  Result := True;
  if not FileExists(aPath) and aReportGood then
  begin
    Memo1.Lines.Append('File not found ' + aPath);
    Exit;
  end;

  fScripting.ErrorHandler.Clear;

  CampaignFile := ExtractFilePath(aPath) + '..\campaigndata.' + EXT_FILE_SCRIPT;
  fScripting.LoadFromFile(aPath, CampaignFile, nil);

  txt := StringReplace(fScripting.ErrorHandler.ErrorString.GameMessage, '|', sLineBreak, [rfReplaceAll]);

  if fScripting.ErrorHandler.HasWarnings then
  begin
    if txt <> '' then
      txt := txt + sLineBreak;
    txt := txt + 'Warnings:' + sLineBreak;
    txt := txt + StringReplace(fScripting.ErrorHandler.WarningsString.GameMessage, '|', sLineBreak, [rfReplaceAll]);
  end;

  if txt <> '' then
  begin
    Memo1.Lines.Append(aPath + sLineBreak + txt);
    Result := False;
  end else
    if aReportGood then
      Memo1.Lines.Append(aPath + ' - No errors :)');
end;


procedure TForm1.WMDropFiles(var Msg: TWMDropFiles);
var
  Filename: array[0 .. MAX_PATH] of Char;
begin
  DragQueryFile(Msg.Drop, 0, Filename, MAX_PATH);
  Edit1.Text := Filename;
  DragFinish(Msg.Drop);
end;

end.
