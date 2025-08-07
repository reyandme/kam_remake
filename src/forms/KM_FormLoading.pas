unit KM_FormLoading;
{$I KaM_Remake.inc}
interface
uses
  Classes,
  {$IFDEF FPC} LResources, {$ENDIF}
  Forms, Controls, ComCtrls, ExtCtrls, StdCtrls, Graphics;

type
  TFormLoading = class(TForm)
    Label1: TLabel;
    Bar1: TProgressBar;
    Image1: TImage;
    Label3: TLabel;
    Bevel1: TBevel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label2: TLabel;
    Label8: TLabel;
    procedure FormHide(Sender: TObject);
  public
    procedure LoadingStep;
    procedure LoadingText(const aData: UnicodeString);
  end;


implementation
//{$IFDEF WDC}
  {$R *.dfm}
//{$ENDIF}


{ TFormLoading }
procedure TFormLoading.FormHide(Sender: TObject);
begin
  //Put loading screen out of screen bounds, while hidden
  //This fixes bug, when on loading with fullscreen mode, user Alt-Tab into other window.
  //Then loading screen will be invisible, but prevents user interaction (block clicks etc)
  Left := -4000;
  Top := -4000;
end;


procedure TFormLoading.LoadingStep;
begin
  try
	  if not Visible then Exit;
	  Bar1.StepIt;
	  Refresh;
	  Assert(1=0);
  except
      FormStyle := fsNormal;
      raise;
  end;
end;


procedure TFormLoading.LoadingText(const aData: UnicodeString);
begin
  if not Visible then Exit;
  Label1.Caption := aData;
  Refresh;
end;


{$IFDEF FPC}
initialization
{$I KM_FormLoading.lrs}
{$ENDIF}

end.
