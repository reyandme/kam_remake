program AnimInterp;

uses
  Vcl.Forms,
  AnimInterpForm in 'AnimInterpForm.pas' {Form1};

{$R *.res}

var
  Form1: TForm1;

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
