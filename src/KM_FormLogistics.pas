unit KM_FormLogistics;

interface
uses
  {$IFDEF FPC} LResources, {$ENDIF}
  {$IFDEF MSWindows} Windows, Messages, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, ComCtrls;

type
  TFormLogistics = class(TForm)
    DeliveriesList: TListView;
    OffersList: TListView;
    DemandsList: TListView;
    TabControl1: TTabControl;
    procedure TabControl1Change(Sender: TObject);
  private

  public
    procedure Clear;

  end;

var
  FormLogistics: TFormLogistics;

implementation

{$R *.dfm}



procedure TFormLogistics.TabControl1Change(Sender: TObject);
begin
  case TabControl1.TabIndex of
    0:  begin
          DeliveriesList.Visible := True;
          OffersList.Visible := False;
          DemandsList.Visible := False;
        end;
    1:  begin
          DeliveriesList.Visible := False;
          OffersList.Visible := True;
          DemandsList.Visible := False;
        end;
    2:  begin
          DeliveriesList.Visible := False;
          OffersList.Visible := False;
          DemandsList.Visible := True;
        end;
  end;
end;


procedure TFormLogistics.Clear;
begin
  DeliveriesList.Clear;
  OffersList.Clear;
  DemandsList.Clear;
end;


end.
