unit KM_GUICommonGameOptions;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils,
  KM_GUICommonOptions,
  KM_Controls, KM_ControlsForm,
  KM_CommonTypes, KM_GUICommonKeys;

type
  TKMGUICommonGameOptions = class
  private
    fGUICommonOptions: TKMGUICommonOptions;

    procedure CloseClick;
    function GetCaption: string;
    procedure SetCaption(const aValue: string);
  protected
    Form_Settings: TKMForm;
    Panel_Settings: TKMPanel;
  public
    constructor Create(aParent: TKMPanel; aCaption: string; aOnKeysUpdated: TKMEvent);
    destructor Destroy; override;

    property GUICommonOptions: TKMGUICommonOptions read fGUICommonOptions;
    property Caption: string read GetCaption write SetCaption;

    procedure Refresh;
    procedure Show;
    procedure Hide;
    function Visible: Boolean;
  end;


implementation
uses
  KM_GameSettings, KM_ResTexts, KM_ResFonts, KM_InterfaceGame, KM_Music, KM_Sound, KM_Game, KM_GameParams,
  KM_GameTypes, KM_RenderUI, KM_InterfaceTypes,
  KM_Resource;


{ TKMGUICommonGameOptions }
constructor TKMGUICommonGameOptions.Create(aParent: TKMPanel; aCaption: string; aOnKeysUpdated: TKMEvent);
const
  W_PNL = 600;
  H_PNL = 510;
begin
  inherited Create;

  Form_Settings := TKMForm.Create(aParent.MasterParent, W_PNL, H_PNL, aCaption, fbYellow, False, False);
  Form_Settings.HandleCloseKey := True;
  Form_Settings.CapOffsetY := -5;

  Panel_Settings := TKMPanel.Create(Form_Settings.ItemsPanel, 0, 0, W_PNL, H_PNL);

  fGUICommonOptions := TKMGUICommonOptions.Create(Panel_Settings, guiOptGame, CloseClick, aOnKeysUpdated);

  Form_Settings.Hide;
end;


destructor TKMGUICommonGameOptions.Destroy;
begin
  fGUICommonOptions.Free;

  inherited;
end;


function TKMGUICommonGameOptions.GetCaption: string;
begin
  Result := Form_Settings.Caption;
end;


procedure TKMGUICommonGameOptions.SetCaption(const aValue: string);
begin
  Form_Settings.Caption := aValue;
end;


procedure TKMGUICommonGameOptions.CloseClick;
begin
  Form_Settings.Hide;
end;


procedure TKMGUICommonGameOptions.Refresh;
begin
  fGUICommonOptions.Refresh;
end;


procedure TKMGUICommonGameOptions.Hide;
begin
  Form_Settings.Hide;
end;


procedure TKMGUICommonGameOptions.Show;
begin
  Refresh;
  Form_Settings.Show;
  Form_Settings.Focus; // To be able to handle KeyUp
end;


function TKMGUICommonGameOptions.Visible: Boolean;
begin
  Result := Form_Settings.Visible;
end;


end.
