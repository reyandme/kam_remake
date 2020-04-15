unit KM_DevPerfLogForm;
{$I KaM_Remake.inc}
interface
uses
  SysUtils, Classes, Vcl.Graphics, Vcl.Forms, Vcl.StdCtrls, Vcl.Controls, Vcl.ExtCtrls, Types,
  KM_DevPerfLog, KM_DevPerfLogTypes, Vcl.Samples.Spin, KM_Helpers;

type
  TFormPerfLogs = class(TForm)
    Label1: TLabel;
    cbStackedGFX: TCheckBox;
    seFrameBudget: TSpinEdit;
    Label2: TLabel;
    cbStackedCPU: TCheckBox;
    cbSmoothLines: TCheckBox;
    procedure DoChange(Sender: TObject);
    procedure seFrameBudgetKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    fPerfLogs: TKMPerfLogs;
    fControlsCreated: Boolean;
    fUpdating: Boolean;
    fAllClicked: Boolean;

    CheckBoxes: array [TPerfSectionDev, 0..2] of TCheckBox;
  public
    procedure Show(aPerfLogs: TKMPerfLogs); reintroduce;
    function FormHeight: Integer;
  end;


implementation
{$R *.dfm}
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  Math;


{ TFormPerfLogs }
procedure TFormPerfLogs.seFrameBudgetKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_PRIOR then
    seFrameBudget.Value := seFrameBudget.Value + 10
  else
  if Key = VK_NEXT then
    seFrameBudget.Value := seFrameBudget.Value - 10
end;


function TFormPerfLogs.FormHeight: Integer;
begin
  Result := CheckBoxes[High(TPerfSectionDev), 0].Top + CheckBoxes[High(TPerfSectionDev), 0].Height + 25;
end;


procedure TFormPerfLogs.Show(aPerfLogs: TKMPerfLogs);
const
  TY = 56;
  DY = 16;
var
  PS: TPerfSectionDev;
  lbl: TLabel;
  shp: TShape;
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

    for PS := Low(TPerfSectionDev) to High(TPerfSectionDev) do
    begin
      CheckBoxes[PS, 0] := TCheckBox.Create(Self);
      CheckBoxes[PS, 0].Parent := Self;
      CheckBoxes[PS, 0].Left := 8;
      CheckBoxes[PS, 0].Top := TY + DY + Ord(PS) * DY;
      CheckBoxes[PS, 0].Tag := Ord(PS);
      CheckBoxes[PS, 0].OnClick := DoChange;

      CheckBoxes[PS, 1] := TCheckBox.Create(Self);
      CheckBoxes[PS, 1].Parent := Self;
      CheckBoxes[PS, 1].Left := 45;
      CheckBoxes[PS, 1].Top := TY + DY + Ord(PS) * DY;
      CheckBoxes[PS, 1].Tag := Ord(PS);
      CheckBoxes[PS, 1].OnClick := DoChange;

      CheckBoxes[PS, 2] := TCheckBox.Create(Self);
      CheckBoxes[PS, 2].Parent := Self;
      CheckBoxes[PS, 2].Left := 82;
      CheckBoxes[PS, 2].Top := TY + DY + Ord(PS) * DY;
      CheckBoxes[PS, 2].Tag := Ord(PS);
      CheckBoxes[PS, 2].OnClick := DoChange;

      if PS <> psNone then
      begin
        CheckBoxes[PS, 0].Checked := fPerfLogs[PS].Enabled;
        CheckBoxes[PS, 1].Checked := fPerfLogs[PS].Display;
        CheckBoxes[PS, 2].Checked := fPerfLogs.StackCPU[PS].Show or fPerfLogs.StackGFX[PS].Show;

        shp := TShape.Create(Self);
        shp.Parent := Self;
        shp.SetBounds(110, TY + DY + Ord(PS) * DY + 1, DY, DY);
        shp.Pen.Style := psClear;
        shp.Brush.Color := SECTION_INFO[PS].Color.ToCardinal;
      end
      else
      begin
        CheckBoxes[PS, 0].AllowGrayed := True;
        CheckBoxes[PS, 1].AllowGrayed := True;
        CheckBoxes[PS, 2].AllowGrayed := True;
      end;

      lbl := TLabel.Create(Self);
      lbl.Parent := Self;
      lbl.Left := 130;
      lbl.Top := TY + DY + Ord(PS) * DY + 1;
      lbl.Caption := SECTION_INFO[PS].Name;
    end;
    fUpdating := False;

    seFrameBudget.Value := fPerfLogs.FrameBudget;

    fControlsCreated := True;
  end;

  inherited Show;
end;


procedure TFormPerfLogs.DoChange(Sender: TObject);

  procedure UpdateAllChkboxState;
  var
    I: Integer;
    PS: TPerfSectionDev;
    AllEnabled, AllDisabled: Boolean;
  begin
    for I := 0 to 2 do
    begin
      AllEnabled := True;
      AllDisabled := True;
      for PS := LOW_PERF_SECTION to High(TPerfSectionDev) do
      begin
        if not CheckBoxes[PS, I].Checked then
          AllEnabled := False;

        if CheckBoxes[PS, I].Checked then
          AllDisabled := False;
      end;

      if AllEnabled then
        CheckBoxes[psNone, I].SetStateWithoutClick(cbChecked)
      else
      if AllDisabled then
        CheckBoxes[psNone, I].SetStateWithoutClick(cbUnchecked)
      else
        CheckBoxes[psNone, I].SetStateWithoutClick(cbGrayed);
    end;
  end;

  procedure ChangeCheckboxes;
  var
    I: Integer;
    PS: TPerfSectionDev;
  begin
    for I := 0 to 2 do
    begin
      if Sender <> CheckBoxes[psNone, I] then
        Continue;

      case CheckBoxes[psNone, I].State of
        cbChecked:    CheckBoxes[psNone, I].SetStateWithoutClick(cbUnchecked);
        cbGrayed:     CheckBoxes[psNone, I].SetStateWithoutClick(cbChecked);
      end;

      fAllClicked := True; //Prevent UpdateAllChkboxState

      for PS := LOW_PERF_SECTION to High(TPerfSectionDev) do
        CheckBoxes[PS, I].Checked := CheckBoxes[psNone, I].Checked;

      fAllClicked := False;
      UpdateAllChkboxState;

      if I = 1 then
        // No need to trigger OnChange event here, since all section events were already triggered above
        CheckBoxes[psNone, 0].SetCheckedWithoutClick(CheckBoxes[psNone, 0].Checked
                                                     or CheckBoxes[psNone, 1].Checked
                                                     or CheckBoxes[psNone, 2].Checked);
    end;

  end;

var
  section: TPerfSectionDev;
begin
  if fUpdating then Exit;

  section := TPerfSectionDev(TCheckBox(Sender).Tag);

  if section = psNone then
    ChangeCheckboxes
  else
  begin
    if Sender = CheckBoxes[section, 0] then
    begin
      fPerfLogs[section].Enabled := TCheckBox(Sender).Checked;
      if TKMPerfLogs.IsCPUSection(section) then
        fPerfLogs.StackCPU[section].Enabled := TCheckBox(Sender).Checked
      else
        fPerfLogs.StackGFX[section].Enabled := TCheckBox(Sender).Checked;
    end
    else
    begin
      if Sender = CheckBoxes[section, 1] then
      begin
        fPerfLogs[section].Display := TCheckBox(Sender).Checked;
        fPerfLogs[section].Enabled := fPerfLogs[section].Enabled or fPerfLogs[section].Display;
      end
      else
      if Sender = CheckBoxes[section, 2] then
      begin
        if TKMPerfLogs.IsCPUSection(section) then
        begin
          fPerfLogs.StackCPU[section].Show := TCheckBox(Sender).Checked;
          fPerfLogs.StackCPU[section].Enabled := fPerfLogs.StackCPU.SectionData[section].Enabled
                                                 or TCheckBox(Sender).Checked;
        end
        else
        begin
          fPerfLogs.StackGFX[section].Show := TCheckBox(Sender).Checked;
          fPerfLogs.StackGFX[section].Enabled := fPerfLogs.StackGFX.SectionData[section].Enabled
                                                 or TCheckBox(Sender).Checked;
        end;
      end;

      CheckBoxes[section, 0].Checked := fPerfLogs[section].Enabled
                                        or fPerfLogs.StackCPU.SectionData[section].Enabled
                                        or fPerfLogs.StackGFX.SectionData[section].Enabled;
    end;

    if not fAllClicked then
      UpdateAllChkboxState;
  end;

  fPerfLogs.StackCPU.Enabled := cbStackedCPU.Checked;
  fPerfLogs.StackCPU.Display := cbStackedCPU.Checked;

  fPerfLogs.StackGFX.Enabled := cbStackedGFX.Checked;
  fPerfLogs.StackGFX.Display := cbStackedGFX.Checked;

  fPerfLogs.FrameBudget := seFrameBudget.Value;

  fPerfLogs.Smoothing := cbSmoothLines.Checked;
end;


end.
