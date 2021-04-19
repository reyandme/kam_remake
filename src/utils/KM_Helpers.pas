unit KM_Helpers;
{$I KaM_Remake.inc}
interface
uses
  Vcl.StdCtrls, Vcl.Samples.Spin, ExtCtrls;


type
  TCheckBoxHelper = class helper for TCheckBox
    procedure SetStateWithoutClick(const aState: TCheckBoxState);
    procedure SetCheckedWithoutClick(const aChecked: Boolean);
  end;


  TEditHelper = class helper for TEdit
    procedure SetTextWithoutChange(const aText: string);
  end;


  TSpinEditHelper = class helper for TSpinEdit
    procedure SetValueWithoutChange(const aValue: Integer);
  end;


  TCategoryPanelHelper = class helper for TCategoryPanel
  private
    function GetXmlSectionName: string;
  public
    property XmlSectionName: string read GetXmlSectionName;
  end;


implementation
uses
  Classes, SysUtils;


{ TCheckBoxHelper }
procedure TCheckBoxHelper.SetStateWithoutClick(const aState: TCheckBoxState);
var
  bckEvent: TNotifyEvent;
begin
  bckEvent := OnClick;
  OnClick := nil;
  try
    State := aState;
  finally
    OnClick := bckEvent;
  end;
end;


procedure TCheckBoxHelper.SetCheckedWithoutClick(const aChecked: Boolean);
var
  bckEvent: TNotifyEvent;
begin
  bckEvent := OnClick;
  OnClick := nil;
  try
    Checked := aChecked;
  finally
    OnClick := bckEvent;
  end;
end;


{ TEditHelper }
procedure TEditHelper.SetTextWithoutChange(const aText: string);
var
  bckEvent: TNotifyEvent;
begin
  bckEvent := OnChange;
  OnChange := nil;
  try
    Text := aText;
  finally
    OnChange := bckEvent;
  end;
end;


{ TSpinEditHelper }
procedure TSpinEditHelper.SetValueWithoutChange(const aValue: Integer);
var
  bckEvent: TNotifyEvent;
begin
  bckEvent := OnChange;
  OnChange := nil;
  try
    Value := aValue;
  finally
    OnChange := bckEvent;
  end;

end;


{ TCategoryPanelHelper }
function TCategoryPanelHelper.GetXmlSectionName: string;
begin
  Result := StringReplace(Caption, ' ', '_', [rfReplaceAll]);
end;


end.
