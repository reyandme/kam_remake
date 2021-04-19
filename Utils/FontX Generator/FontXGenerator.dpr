program FontXGenerator;
{$I ..\..\KaM_Remake.inc}
uses
  Forms,
  Form_Generator in 'Form_Generator.pas' {Form1},
  KM_ResFonts in '..\..\src\res\KM_ResFonts.pas',
  KM_ResFontsEdit in '..\..\src\res\KM_ResFontsEdit.pas',
  KM_FontXGenerator in 'KM_FontXGenerator.pas';

begin
  Application.Initialize;
  {$IFDEF FPC} Application.MainFormOnTaskbar := True; {$ENDIF}
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
