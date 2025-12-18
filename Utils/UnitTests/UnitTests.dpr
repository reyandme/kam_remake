program UnitTests;
{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

//{$DEFINE DUNIT_TEST} Defined in ProjectOptions

uses
  //FastMM4,
  Forms,
  TestFramework,
  GUITestRunner,
  TextTestRunner,
  TestKM_CommonClasses in 'TestKM_CommonClasses.pas',
  TestKM_CommonUtils in 'TestKM_CommonUtils.pas',
  TestKM_Points in 'TestKM_Points.pas',
  TestKM_Utils in 'TestKM_Utils.pas';

{$R *.RES}

begin
  Application.Initialize;
  if IsConsole then
    with TextTestRunner.RunRegisteredTests do
      Free
  else
    GUITestRunner.RunRegisteredTests;
end.

