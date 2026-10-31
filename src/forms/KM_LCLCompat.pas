unit KM_LCLCompat;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils,
  ExtCtrls, StdCtrls;


type
  // The shared developer form refers to VCL containers absent from LCL.
  TKMCategoryPanel = class(TPanel)
  private
    fCollapsed: Boolean;
  published
    property Collapsed: Boolean read fCollapsed write fCollapsed;
  end;

  TKMCategoryPanelSurface = class(TPanel);

  TKMCategoryPanelGroup = class(TGroupBox)
  private
    fPanels: TList;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    property Panels: TList read fPanels;
  end;

  TCategoryPanel = TKMCategoryPanel;
  TCategoryPanelSurface = TKMCategoryPanelSurface;
  TCategoryPanelGroup = TKMCategoryPanelGroup;


implementation


constructor TKMCategoryPanelGroup.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);

  fPanels := TList.Create;
end;


destructor TKMCategoryPanelGroup.Destroy;
begin
  FreeAndNil(fPanels);

  inherited;
end;


initialization
  RegisterClassAlias(TKMCategoryPanelGroup, 'TCategoryPanelGroup');
  RegisterClassAlias(TKMCategoryPanel, 'TCategoryPanel');

end.
