unit KM_DevPerfLogForm;
{$I KaM_Remake.inc}
interface
uses
  SysUtils, Classes, Graphics, Forms, StdCtrls, Controls, ExtCtrls, Types,
  KM_CommonTypes,
  KM_DevPerfLog, KM_DevPerfLogTypes, Spin, KM_VclHelpers;

type
  TFormPerfLogs = class(TForm)
    Label1: TLabel;
    cbStackedGFX: TCheckBox;
    seScale: TSpinEdit;
    Label2: TLabel;
    cbStackedCPU: TCheckBox;
    cbSmoothLines: TCheckBox;
    sePerfLogSaveThreshold: TSpinEdit;
    lblPerflogSaveThreshold: TLabel;
    btnPerfLogExport: TButton;
    cbEnabled: TCheckBox;
    cbClearOnGameStart: TCheckBox;
    procedure UpdateAllChkboxState;
    procedure DoChange(Sender: TObject);
    procedure DoExport(Sender: TObject);
    procedure seScaleKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    fPerfLogs: TKMPerfLogs;
    fControlsCreated: Boolean;
    fUpdating: Boolean;
    fAllClicked: Boolean;

    fOnFormChanged: TEvent;

    CheckBoxesAll: array[plkCPU..plkGFX, 0..2] of TCheckBox;
    CheckBoxes: array [Succ(Low(TPerfSectionDev))..High(TPerfSectionDev), 0..2] of TCheckBox;
  public
    property OnFormChanged: TEvent read fOnFormChanged write fOnFormChanged;
    procedure Show(aPerfLogs: TKMPerfLogs); reintroduce;
    function FormHeight: Integer;
  end;


implementation
{$R *.dfm}
uses
  TypInfo,
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  Math, KM_Defaults, KM_CommonUtils;

const
  PS_IS_GFX_KIND: array[Boolean] of TKMPerfLogKind = (plkCPU, plkGFX);


{ TFormPerfLogs }
procedure TFormPerfLogs.seScaleKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_PRIOR then
    seScale.Value := seScale.Value + 10
  else
  if Key = VK_NEXT then
    seScale.Value := seScale.Value - 10
end;


function TFormPerfLogs.FormHeight: Integer;
begin
  Result := btnPerfLogExport.Top + btnPerfLogExport.Height + 25;
end;


procedure TFormPerfLogs.Show(aPerfLogs: TKMPerfLogs);
const
  TY = 70;
  DY = 16;
  DY_SPLIT = DY + 10;
  DX_SPLIT = 37;

  function LineNum(aPS: TPerfSectionDev; aIsGFX: Boolean): Integer;
  begin
    if aPS <> psNone then
      Exit(Ord(aPS));

    Result := Byte(aIsGFX)*(Ord(FIRST_GFX_SECTION) - 1);
  end;

  procedure FillCheckBox(aCheckBox: TCheckBox; aPS: TPerfSectionDev; aN: Integer; aIsGFX: Boolean);
  begin
    aCheckBox.Parent := Self;
    aCheckBox.Left := 8 + aN*DX_SPLIT;
    aCheckBox.Top := TY + DY + LineNum(aPS, aIsGFX) * DY + Byte(aIsGFX or IsGFXSection(aPS))*DY_SPLIT;
    aCheckBox.Tag := Ord(aPS);
    aCheckBox.OnClick := DoChange;
    aCheckBox.Name := 'cbA' + GetEnumName(TypeInfo(TPerfSectionDev), Integer(aPS)) + IntToStr(aN) + BoolStrShort(aIsGFX);
    aCheckBox.Caption := '';
  end;


  procedure CreateCheckboxesLine(aPS: TPerfSectionDev; aIsGFX: Boolean = False);
  var
    I: Integer;
    lbl: TLabel;
    shp: TShape;
    chk: TCheckBox;
  begin
    for I := 0 to 2 do
    begin
      chk := TCheckBox.Create(Self);
      FillCheckBox(chk, aPS, I, aIsGFX);

      if aPS <> psNone then
        CheckBoxes[aPS, I] := chk
      else
      begin
        CheckBoxesAll[PS_IS_GFX_KIND[aIsGFX], I] := chk
      end;
    end;

    if aPS <> psNone then
    begin
      CheckBoxes[aPS, 0].Checked := fPerfLogs[aPS].Enabled;
      CheckBoxes[aPS, 1].Checked := fPerfLogs[aPS].Display;
      CheckBoxes[aPS, 2].Checked := fPerfLogs.StackCPU[aPS].Show or fPerfLogs.StackGFX[aPS].Show;

      shp := TShape.Create(Self);
      shp.Parent := Self;
      shp.SetBounds(110, TY + DY + LineNum(aPS, aIsGFX) * DY + 1 + Byte(IsGFXSection(aPS))*DY_SPLIT, DY, DY);
      shp.Pen.Style := psClear;
      shp.Brush.Color := SECTION_INFO[aPS].Color.ToCardinal;
    end
    else
      for I := 0 to 2 do
        CheckBoxesAll[PS_IS_GFX_KIND[aIsGFX], I].AllowGrayed := True;

    lbl := TLabel.Create(Self);
    lbl.Parent := Self;
    lbl.Left := 130;
    lbl.Top := TY + DY + LineNum(aPS, aIsGFX) * DY + 1 + Byte(aIsGFX or IsGFXSection(aPS))*DY_SPLIT;
    lbl.Caption := SECTION_INFO[aPS].Name;
  end;

var
  PS: TPerfSectionDev;
  lbl: TLabel;
  bottom: Integer;
begin
  fPerfLogs := aPerfLogs;

  if not fControlsCreated then
  begin
    fUpdating := True;

    lbl := TLabel.Create(Self);
    lbl.Parent := Self;
    lbl.Left := 8;
    lbl.Top := TY;
    lbl.Caption := 'Enable';

    lbl := TLabel.Create(Self);
    lbl.Parent := Self;
    lbl.Left := 45;
    lbl.Top := TY;
    lbl.Caption := 'Show';

    lbl := TLabel.Create(Self);
    lbl.Parent := Self;
    lbl.Left := 82;
    lbl.Top := TY;
    lbl.Caption := 'Stacked';

    lbl := TLabel.Create(Self);
    lbl.Parent := Self;
    lbl.Left := 130;
    lbl.Top := TY;
    lbl.Caption := 'Section';

    CreateCheckboxesLine(psNone);
    for PS := Succ(Low(TPerfSectionDev)) to High(TPerfSectionDev) do
    begin
      if not IsCPUSection(PS) then Continue; //Create CPU sections first

      CreateCheckboxesLine(PS);
    end;

    CreateCheckboxesLine(psNone, True);
    for PS := Succ(Low(TPerfSectionDev)) to High(TPerfSectionDev) do
    begin
      if not IsGFXSection(PS) then Continue; //Create GFX sections afterwards

      CreateCheckboxesLine(PS);
    end;
    fUpdating := False;

    seScale.Value := fPerfLogs.Scale;

    fControlsCreated := True;

    bottom := CheckBoxes[High(TPerfSectionDev), 0].Top + CheckBoxes[High(TPerfSectionDev), 0].Height + 15;

    lblPerflogSaveThreshold.Top := bottom;
    sePerfLogSaveThreshold.Top := bottom;
    btnPerfLogExport.Top := bottom;
  end;

  cbEnabled.Checked     := False;
  cbStackedCPU.Enabled  := False;
  cbStackedGFX.Enabled  := False;
  seScale.Enabled       := False;
  cbSmoothLines.Enabled := False;
  cbClearOnGameStart.Enabled := False;
  sePerfLogSaveThreshold.Enabled := False;
  btnPerfLogExport.Enabled := False;

  UpdateAllChkboxState;

  inherited Show;
end;


procedure TFormPerfLogs.DoExport(Sender: TObject);
begin
  {$IFDEF PERFLOG}
  gPerflogs.SaveToFile(ExeDir + PathDelim + 'Export' + PathDelim + 'Perflog.txt',
                       1000*sePerfLogSaveThreshold.Value); //threshold in ms
  {$ENDIF}
end;


procedure TFormPerfLogs.UpdateAllChkboxState;
var
  I: Integer;
  PS: TPerfSectionDev;
  PLK: TKMPerfLogKind;
  allChecked, allUnchecked: Boolean;
begin
  for PLK := Low(CheckBoxesAll) to High(CheckBoxesAll) do
    for I := 0 to 2 do
    begin
      allChecked := True;
      allUnchecked := True;
      for PS := LOW_PERF_SECTION to High(TPerfSectionDev) do
      begin
        if PLK <> SECTION_INFO[PS].Kind then Continue;

        if not CheckBoxes[PS, I].Checked then
          allChecked := False;

        if CheckBoxes[PS, I].Checked then
          allUnchecked := False;

        CheckBoxes[PS, I].Enabled := cbEnabled.Checked;
      end;

      if allChecked then
        CheckBoxesAll[PLK, I].SetStateWithoutClick(cbChecked)
      else
      if allUnchecked then
        CheckBoxesAll[PLK, I].SetStateWithoutClick(cbUnchecked)
      else
        CheckBoxesAll[PLK, I].SetStateWithoutClick(cbGrayed);

      CheckBoxesAll[PLK, I].Enabled := cbEnabled.Checked;
    end;
end;


procedure TFormPerfLogs.DoChange(Sender: TObject);

  procedure ChangeCheckboxes;
  var
    I: Integer;
    PS: TPerfSectionDev;
    PLK: TKMPerfLogKind;
  begin
    for PLK := Low(CheckBoxesAll) to High(CheckBoxesAll) do
      for I := 0 to 2 do
      begin
        if Sender <> CheckBoxesAll[PLK, I] then
          Continue;

        case CheckBoxesAll[PLK, I].State of
          cbChecked:    CheckBoxesAll[PLK, I].SetStateWithoutClick(cbUnchecked);
          cbGrayed:     CheckBoxesAll[PLK, I].SetStateWithoutClick(cbChecked);
        end;

        fAllClicked := True; //Prevent UpdateAllChkboxState

        for PS := LOW_PERF_SECTION to High(TPerfSectionDev) do
          if PLK = SECTION_INFO[PS].Kind then
            CheckBoxes[PS, I].Checked := CheckBoxesAll[PLK, I].Checked;

        fAllClicked := False;
        UpdateAllChkboxState;

        if I = 1 then
          // No need to trigger OnChange event here, since all section events were already triggered above
          CheckBoxesAll[PLK, 0].SetCheckedWithoutClick(CheckBoxesAll[PLK, 0].Checked
                                                       or CheckBoxesAll[PLK, 1].Checked
                                                       or CheckBoxesAll[PLK, 2].Checked);
    end;

  end;

  procedure SyncStackPerfLog(aPLK: TKMPerfLogKind);
  var
    PS: TPerfSectionDev;
  begin
      for PS := LOW_PERF_SECTION to High(TPerfSectionDev) do
      begin
        if aPLK <> SECTION_INFO[PS].Kind then Continue;

        case aPLK of
          plkCPU: begin
                    fPerfLogs.StackCPU[PS].Enabled  := CheckBoxes[PS, 0].Checked;
                    fPerfLogs.StackCPU[PS].Show     := CheckBoxes[PS, 2].Checked;
                  end;
          plkGFX: begin
                    fPerfLogs.StackGFX[PS].Enabled  := CheckBoxes[PS, 0].Checked;
                    fPerfLogs.StackGFX[PS].Show     := CheckBoxes[PS, 2].Checked;
                  end;
        end;
      end;
  end;

var
  section: TPerfSectionDev;
  enabled: Boolean;
begin
  if fUpdating then Exit;

  enabled := cbEnabled.Checked;
  fPerfLogs.Enabled := enabled;

  cbStackedCPU.Enabled  := enabled;
  cbStackedGFX.Enabled  := enabled;
  seScale.Enabled       := enabled;
  cbSmoothLines.Enabled := enabled;
  cbClearOnGameStart.Enabled := enabled;
  sePerfLogSaveThreshold.Enabled := enabled;
  btnPerfLogExport.Enabled := enabled;

  fPerfLogs.StackCPU.Enabled := enabled and cbStackedCPU.Checked;
  fPerfLogs.StackCPU.Display := enabled and cbStackedCPU.Checked;

  fPerfLogs.StackGFX.Enabled := enabled and cbStackedGFX.Checked;
  fPerfLogs.StackGFX.Display := enabled and cbStackedGFX.Checked;

  fPerfLogs.Scale := seScale.Value;

  fPerfLogs.Smoothing := cbSmoothLines.Checked;
  fPerfLogs.ClearOnGameStart := cbClearOnGameStart.Checked;

  if (Sender = cbStackedCPU) or (Sender = cbStackedGFX) then
    SyncStackPerfLog(PS_IS_GFX_KIND[Sender = cbStackedGFX])
  else
  if Sender = cbEnabled then
    UpdateAllChkboxState
  else
  begin
    section := TPerfSectionDev(TCheckBox(Sender).Tag);

    if section = psNone then
      ChangeCheckboxes
    else
    begin
      if Sender = CheckBoxes[section, 0] then
      begin
        fPerfLogs[section].Enabled := TCheckBox(Sender).Checked;
        if IsCPUSection(section) then
          fPerfLogs.StackCPU[section].Enabled := enabled and TCheckBox(Sender).Checked
        else
          fPerfLogs.StackGFX[section].Enabled := enabled and TCheckBox(Sender).Checked;
      end
      else
      begin
        if Sender = CheckBoxes[section, 1] then
        begin
          fPerfLogs[section].Display := enabled and TCheckBox(Sender).Checked;
          fPerfLogs[section].Enabled := enabled and (fPerfLogs[section].Enabled or fPerfLogs[section].Display);
        end
        else
        if Sender = CheckBoxes[section, 2] then
        begin
          if IsCPUSection(section) then
          begin
            fPerfLogs.StackCPU[section].Show := enabled and TCheckBox(Sender).Checked;
            fPerfLogs.StackCPU[section].Enabled := enabled
                                                   and (fPerfLogs.StackCPU.SectionData[section].Enabled or TCheckBox(Sender).Checked);
          end
          else
          begin
            fPerfLogs.StackGFX[section].Show := enabled and TCheckBox(Sender).Checked;
            fPerfLogs.StackGFX[section].Enabled := enabled
                                                   and (fPerfLogs.StackGFX.SectionData[section].Enabled or TCheckBox(Sender).Checked);
          end;
        end;

        CheckBoxes[section, 0].Checked := enabled
                                          and (fPerfLogs[section].Enabled
                                            or fPerfLogs.StackCPU.SectionData[section].Enabled
                                            or fPerfLogs.StackGFX.SectionData[section].Enabled);
      end;

      if not fAllClicked then
        UpdateAllChkboxState;
    end;
  end;

  if not fAllClicked and Assigned(fOnFormChanged) then
    fOnFormChanged;
end;


end.
