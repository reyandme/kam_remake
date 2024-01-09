unit KM_SettingsDev;
{$I KaM_Remake.inc}
interface
uses
  SysUtils, StrUtils, Classes, Math,
  ComCtrls, Controls, ExtCtrls, StdCtrls,
  Forms, Spin
  {$IFDEF Unix} , LCLIntf, LCLType {$ENDIF}
  ;


type
  TKMDebugFormState = ( fsNone,       // No debug panel or menu are open
                        fsDebugMenu,  // Only debug menu is visible
                        fsDebugFull); // Debug panel and menu are visible

  // Manager of F11 controls settings save/load
  TKMDevSettings = class
  private
    fSettingsPath: UnicodeString;

    fDebugFormState: TKMDebugFormState; // State of the Debug form

    fMainGroup: TCategoryPanelGroup;
    fDontCollapse: TCategoryPanel;

    procedure DoLoad;
    procedure DoSave;
    function GetXmlSectionName(aPanel: TCategoryPanel): string;
  public
    constructor Create(const aExeDir: string; aMainGroup: TCategoryPanelGroup; aDontCollapse: TCategoryPanel);

    property DebugFormState: TKMDebugFormState read fDebugFormState write fDebugFormState;

    procedure Load;
    procedure Save;
  end;


implementation
uses
  KM_Defaults, KM_Log, KM_IoXML;



{ TKMDevSettings }
constructor TKMDevSettings.Create(const aExeDir: string; aMainGroup: TCategoryPanelGroup; aDontCollapse: TCategoryPanel);
begin
  inherited Create;

  fSettingsPath := aExeDir + DEV_SETTINGS_XML_FILENAME;

  fMainGroup := aMainGroup;
  fDontCollapse := aDontCollapse;
end;


function TKMDevSettings.GetXmlSectionName(aPanel: TCategoryPanel): string;
begin
  Result := StringReplace(aPanel.Caption, ' ', '_', [rfReplaceAll]);
end;


procedure TKMDevSettings.DoLoad;

  procedure LoadSubPanel(aPanel: TWinControl; aNode: TKMXmlNode);
  var
    I: Integer;
    ctrl: TControl;
    nSection: TKMXmlNode;
  begin
    for I := 0 to aPanel.ControlCount - 1 do
    begin
      ctrl := aPanel.Controls[I];

      if ctrl is TGroupBox then
        LoadSubPanel(TGroupBox(ctrl), aNode)
      else
      if ctrl is TForm then
        LoadSubPanel(TForm(ctrl), aNode)
      else
        if (ctrl is TCheckBox)
        or (ctrl is TTrackBar)
        or (ctrl is TRadioGroup)
        or (ctrl is TSpinEdit)
        or (ctrl is TEdit) then
        if aNode.HasChild(ctrl.Name) then
        begin
          nSection := aNode.FindNode(ctrl.Name); // Add section only if its needed

          if (ctrl is TCheckBox) and nSection.HasAttribute('Checked') then
            TCheckBox(ctrl).Checked := nSection.Attributes['Checked'].AsBoolean
          else
          if (ctrl is TTrackBar) and nSection.HasAttribute('Position') then
            TTrackBar(ctrl).Position := nSection.Attributes['Position'].AsInteger
          else
          if (ctrl is TRadioGroup) and nSection.HasAttribute('ItemIndex') then
            TRadioGroup(ctrl).ItemIndex := nSection.Attributes['ItemIndex'].AsInteger
          else
          if (ctrl is TSpinEdit) and nSection.HasAttribute('Value') then
            TSpinEdit(ctrl).Value := nSection.Attributes['Value'].AsInteger
          else
          if (ctrl is TEdit) and nSection.HasAttribute('Text') then
            TEdit(ctrl).Text := nSection.Attributes['Text'].AsString;
        end;
    end;
  end;

var
  I: Integer;
  newXML: TKMXMLDocument;
  cp: TCategoryPanel;
  cpSurface: TCategoryPanelSurface;
  cpName: string;
  nRoot, nDebugForm, nSection: TKMXmlNode;
begin
  if Self = nil then Exit;

  gLog.AddTime('Loading dev settings from file ''' + fSettingsPath + '''');

  // Apply default settings
  if not FileExists(fSettingsPath) then
  begin
    for I := 0 to fMainGroup.Panels.Count - 1 do
      TCategoryPanel(fMainGroup.Panels[I]).Collapsed := True;

    fDontCollapse.Collapsed := False; //The only not collapsed section
    Exit;
  end;

  //Load dev data from XML
  newXML := TKMXMLDocument.Create;
  newXML.LoadFromFile(fSettingsPath);
  nRoot := newXML.Root;

  nDebugForm := nRoot.AddOrFindChild('DebugForm');
  fDebugFormState := TKMDebugFormState(nDebugForm.Attributes['State'].AsInteger(0));

  for I := 0 to fMainGroup.Panels.Count - 1 do
  begin
    cp := TCategoryPanel(fMainGroup.Panels[I]);
    cpName := GetXmlSectionName(cp);

    if nDebugForm.HasChild(cpName) then
    begin
      nSection := nDebugForm.FindNode(cpName);
      cp.Collapsed := nSection.Attributes['Collapsed'].AsBoolean(True);

      if (cp.ControlCount > 0) and (cp.Controls[0] is TCategoryPanelSurface) then
      begin
        cpSurface := TCategoryPanelSurface(cp.Controls[0]);
        LoadSubPanel(cpSurface, nSection);
      end;
    end;
  end;

  newXML.Free;
end;


// Save dev settings to kmr_dev.xml
procedure TKMDevSettings.DoSave;

  procedure SaveSubPanel(aPanel: TWinControl; aNode: TKMXmlNode);
  var
    I: Integer;
    ctrl: TControl;
    nSection: TKMXmlNode;
  begin
    for I := 0 to aPanel.ControlCount - 1 do
    begin
      ctrl := aPanel.Controls[I];

      if ctrl is TGroupBox then
        SaveSubPanel(TGroupBox(ctrl), aNode)
      else
      if ctrl is TForm then
        SaveSubPanel(TForm(ctrl), aNode)
      else
        if (ctrl is TCheckBox)
        or (ctrl is TTrackBar)
        or (ctrl is TRadioGroup)
        or (ctrl is TSpinEdit)
        or (ctrl is TEdit) then
        begin
          nSection := aNode.AddOrFindChild(ctrl.Name); // Add section only if its needed
          if ctrl is TCheckBox then
            nSection.Attributes['Checked'] := TCheckBox(ctrl).Checked
          else
          if ctrl is TTrackBar then
            nSection.Attributes['Position'] := TTrackBar(ctrl).Position
          else
          if ctrl is TRadioGroup then
            nSection.Attributes['ItemIndex'] := TRadioGroup(ctrl).ItemIndex
          else
          if ctrl is TSpinEdit then
            nSection.Attributes['Value'] := TSpinEdit(ctrl).Value
          else
          if ctrl is TEdit then
            nSection.Attributes['Text'] := TEdit(ctrl).Text;
        end;
    end;
  end;

var
  I: Integer;
  newXML: TKMXMLDocument;
  cp: TCategoryPanel;
  cpSurface: TCategoryPanelSurface;
  nRoot, nDebugForm, nSection: TKMXmlNode;
begin
  if Self = nil then Exit;

  gLog.AddTime('Saving dev settings to file ''' + fSettingsPath + '''');

  //Save dev data to XML
  newXML := TKMXMLDocument.Create;
  newXML.LoadFromFile(fSettingsPath);
  nRoot := newXML.Root;

  nDebugForm := nRoot.AddOrFindChild('DebugForm');
  nDebugForm.Attributes['State'] := Ord(fDebugFormState);

  for I := 0 to fMainGroup.Panels.Count - 1 do
  begin
    cp := TCategoryPanel(fMainGroup.Panels[I]);

    nSection := nDebugForm.AddOrFindChild(GetXmlSectionName(cp));

    nSection.Attributes['Collapsed'] := cp.Collapsed;

    if (cp.ControlCount > 0) and (cp.Controls[0] is TCategoryPanelSurface) then
    begin
      cpSurface := TCategoryPanelSurface(cp.Controls[0]);
      SaveSubPanel(cpSurface, nSection);
    end;
  end;

  newXML.SaveToFile(fSettingsPath);
  newXML.Free;
end;


// Load dev settings from kmr_dev.xml
procedure TKMDevSettings.Load;
begin
  if Self = nil then Exit;

  {$IFDEF DEBUG}
  // allow crash while debugging
  DoLoad;
  {$ELSE}
  try
    // Skip crash on released version, only log the error
    DoLoad;
  except
    on E: Exception do
      gLog.AddTime('Error while loading dev settings from ''' + fSettingsPath + ''':' + sLineBreak + E.Message
          {$IFDEF WDC}+ sLineBreak + E.StackTrace{$ENDIF}
        );
  end;
  {$ENDIF}
end;


// Save dev settings to kmr_dev.xml
procedure TKMDevSettings.Save;
begin
  if Self = nil then Exit;

  {$IFDEF DEBUG}
  // allow crash while debugging
  DoSave;
  {$ELSE}
  try
    // Skip crash on released version, only log the error
    DoSave;
  except
    on E: Exception do
      gLog.AddTime('Error while saving dev settings to ''' + fSettingsPath + ''':' + sLineBreak + E.Message
          {$IFDEF WDC}+ sLineBreak + E.StackTrace{$ENDIF}
        );
  end;
  {$ENDIF}
end;


end.
