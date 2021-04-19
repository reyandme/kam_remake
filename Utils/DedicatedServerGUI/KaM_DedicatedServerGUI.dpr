program KaM_DedicatedServerGUI;
{$I ..\..\KaM_Remake.inc}

uses
  {$IFDEF UNIX}
  {$IFDEF UseCThreads}
  cthreads,
  {$ENDIF }
  {$ENDIF }
  {$IFDEF FPC}
  Interfaces,
  {$ENDIF }
  Forms,
  Unit4 in 'Unit4.pas' {Form4};

{$IFDEF FPC}
  {$R *.res}
{$ENDIF}


begin
  Application.Initialize;
  Application.CreateForm(TForm4, FormMain4);
  Application.Run;
end.
