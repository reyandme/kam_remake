unit RXXPackerForm;
{$I ..\..\KaM_Remake.inc}
interface
uses
  Classes, Controls, Dialogs,
  ExtCtrls, Forms, Graphics, Spin, StdCtrls, SysUtils,
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF FPC} LResources, LCLIntf, {$ENDIF}
  KM_Defaults, KM_Log, KM_Pics, KM_ResPalettes, KM_ResSprites;


type
  TRXXForm1 = class(TForm)
    btnPackRXX: TButton;
    ListBox1: TListBox;
    btnUpdateList: TButton;
    edSourceRxPath: TEdit;
    Label2: TLabel;
    chkPackToRXA: TCheckBox;
    chkPackToRXX: TCheckBox;
    Label3: TLabel;
    edDestinationPath: TEdit;
    meLog: TMemo;
    rbRXXFormat0: TRadioButton;
    rbRXXFormat1: TRadioButton;
    rbRXXFormat2: TRadioButton;
    edSourceInterpPath: TEdit;
    Label1: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    procedure btnPackRXXClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnUpdateListClick(Sender: TObject);
    procedure chkPackToRXXClick(Sender: TObject);
    procedure chkPackToRXAClick(Sender: TObject);
    procedure edSourceRxPathChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    fPalettes: TKMResPalettes;

    fSettingsPath: string;
    fUpdating: Boolean;

    procedure UpdateUI;
    procedure UpdateSettings;
    procedure UpdateList;

    procedure LoadSettings;
    procedure SaveSettings;
  end;


implementation
uses
  INIFiles,
  KM_RXXPacker,
  KM_ResHouses, KM_ResUnits, KM_ResTypes,
  KM_Points;

{$R *.dfm}


{ TRXXForm1 }
procedure TRXXForm1.UpdateList;
var
  RT: TRXType;
  rxSet: TRXTypeSet;
  path: string;
begin
  path := IncludeTrailingPathDelimiter(edSourceRxPath.Text);
  // fRxxPacker is our SPOT, so we ask it about what it dims doable
  rxSet := TKMRxxPacker.GetAvailableToPack(path);

  ListBox1.Items.Clear;
  for RT := Low(TRXType) to High(TRXType) do
    if RT in rxSet then
      ListBox1.Items.AddObject(RX_INFO[RT].FileName, TObject(RT));

  if ListBox1.Items.Count = 0 then
  begin
    ShowMessage('No .RX files were found in' + sLineBreak + path);
    btnPackRXX.Enabled := False;
  end else
  begin
    btnPackRXX.Enabled := True;
    ListBox1.ItemIndex := 0;
    ListBox1.SelectAll;
  end;
end;


procedure TRXXForm1.UpdateSettings;
begin
  if fUpdating then Exit;

  SaveSettings;
end;


procedure TRXXForm1.btnUpdateListClick(Sender: TObject);
begin
  UpdateList;
end;


procedure TRXXForm1.UpdateUI;
begin
  btnPackRXX.Enabled := chkPackToRXX.Checked or chkPackToRXA.Checked;
end;


procedure TRXXForm1.chkPackToRXAClick(Sender: TObject);
begin
  UpdateUI;
  UpdateSettings;
end;


procedure TRXXForm1.chkPackToRXXClick(Sender: TObject);
begin
  UpdateUI;
  UpdateSettings;
end;


procedure TRXXForm1.edSourceRxPathChange(Sender: TObject);
begin
  UpdateSettings;
end;


procedure TRXXForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  UpdateSettings;
end;


procedure TRXXForm1.FormCreate(Sender: TObject);
begin
  ExeDir := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\');

  Caption := 'RXX Packer (' + GAME_REVISION + ')';

  gLog := TKMLog.Create(ExeDir + 'RXXPacker.log');

  fPalettes := TKMResPalettes.Create;
  fPalettes.LoadPalettes(ExeDir + 'data\gfx\');

  fUpdating := True;
  edSourceRxPath.Text := ExeDir;
  edSourceInterpPath.Text := ExeDir;
  fUpdating := False;

  fSettingsPath := ExtractFilePath(ParamStr(0)) + 'RXXPacker.ini';
  LoadSettings;

  UpdateList;
end;


procedure TRXXForm1.FormDestroy(Sender: TObject);
begin
  FreeAndNil(fPalettes);
  FreeAndNil(gLog);
end;


procedure TRXXForm1.LoadSettings;
var
  ini: TINIFile;
begin
  fUpdating := True;

  ini := TINIFile.Create(fSettingsPath);
  try
    edSourceRxPath.Text     := ini.ReadString('SETTINGS',  'SourceRxPath', '..\..\SpriteResource\');
    edSourceInterpPath.Text := ini.ReadString('SETTINGS',  'SourceInterpPath', '..\..\SpriteInterp\Output\');
    edDestinationPath.Text  := ini.ReadString('SETTINGS',  'DestinationPath', '..\..\data\Sprites\');
    chkPackToRXX.Checked    := ini.ReadBool  ('SETTINGS',  'PackToRXX', True);
    chkPackToRXA.Checked    := ini.ReadBool  ('SETTINGS',  'PackToRXA', False);
  finally
    ini.Free;
  end;

  fUpdating := False;

  if not FileExists(fSettingsPath) then
    SaveSettings;
end;


procedure TRXXForm1.SaveSettings;
var
  ini: TINIFile;
begin
  ini := TINIFile.Create(fSettingsPath);
  try
    ini.WriteString('SETTINGS', 'SourceRxPath',     edSourceRxPath.Text);
    ini.WriteString('SETTINGS', 'SourceInterpPath', edSourceInterpPath.Text);
    ini.WriteString('SETTINGS', 'DestinationPath',  edDestinationPath.Text);
    ini.WriteBool  ('SETTINGS', 'PackToRXX',        chkPackToRXX.Checked);
    ini.WriteBool  ('SETTINGS', 'PackToRXA',        chkPackToRXA.Checked);
  finally
    ini.Free;
  end;
end;


procedure TRXXForm1.btnPackRXXClick(Sender: TObject);
var
  rxSet: TRXTypeSet;
  I: Integer;
begin
  btnPackRXX.Enabled := False;
  chkPackToRXX.Enabled := False;
  chkPackToRXA.Enabled := False;
  rbRXXFormat0.Enabled := False;
  rbRXXFormat1.Enabled := False;
  rbRXXFormat2.Enabled := False;

  rxSet := [];
  for I := 0 to ListBox1.Items.Count - 1 do
    if ListBox1.Selected[I] then
      rxSet := rxSet + [TRXType(ListBox1.Items.Objects[I])];

  TThread.CreateAnonymousThread(
    procedure
    var
      rxxPacker: TKMRXXPacker;
    begin
      rxxPacker := TKMRXXPacker.Create;
      try
        rxxPacker.SourcePathRX      := edSourceRxPath.Text;
        rxxPacker.SourcePathInterp  := edSourceInterpPath.Text;
        rxxPacker.DestinationPath   := edDestinationPath.Text;
        rxxPacker.PackToRXX     := chkPackToRXX.Checked;
        rxxPacker.PackToRXA     := chkPackToRXA.Checked;
        if rbRXXFormat0.Checked then rxxPacker.RXXFormat := rxxZero;
        if rbRXXFormat1.Checked then rxxPacker.RXXFormat := rxxOne;
        if rbRXXFormat2.Checked then rxxPacker.RXXFormat := rxxTwo;

        try
          rxxPacker.PackSet(rxSet, fPalettes,
            procedure (aMsg: string)
            begin
              TThread.Queue(nil,
                procedure
                begin
                  meLog.Lines.Append(aMsg);
                end);
            end);
        except
          on E: Exception do
            MessageBox(Handle, PWideChar(E.Message), 'Error', MB_ICONEXCLAMATION or MB_OK);
        end;
      finally
        FreeAndNil(rxxPacker);

        TThread.Queue(nil,
          procedure
          begin
            ListBox1.ClearSelection;

            btnPackRXX.Enabled := True;
            chkPackToRXX.Enabled := True;
            chkPackToRXA.Enabled := True;
            rbRXXFormat0.Enabled := True;
            rbRXXFormat1.Enabled := True;
            rbRXXFormat2.Enabled := True;
          end);
      end;
    end).Start;
end;


{$IFDEF FPC}
initialization
  {$i RXXPackerForm.lrs}
{$ENDIF}


end.