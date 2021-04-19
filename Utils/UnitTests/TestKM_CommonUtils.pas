unit TestKM_CommonUtils;
interface
uses
  TestFramework, StrUtils, Classes,
  SysUtils,
  KM_CommonUtils;

type
  TestKMCommonUtils = class(TTestCase)
  published
    procedure TestStrTrimChar;
  end;

implementation

procedure TestKMCommonUtils.TestStrTrimChar;
const
  EMPTY_STRING = '';
begin
  // Empty strings
  CheckEqualsString('', StrTrimChar(EMPTY_STRING, '1'), 'A1');
  CheckEqualsString('', StrTrimChar(EMPTY_STRING, #39), 'A2');
  CheckEqualsString(#0, StrTrimChar(#0, '1'), 'A3');
  CheckEqualsString(#0#0, StrTrimChar(#0#0, '1'), 'A4');
  CheckEqualsString('', StrTrimChar(EMPTY_STRING, #0), 'A5');

  // No trimming
  CheckEqualsString('1', StrTrimChar('1', #0), 'B1');
  CheckEqualsString('1', StrTrimChar('1', '2'), 'B2');
  CheckEqualsString('1221', StrTrimChar('1221', '2'), 'B3');

  // Trimming
  CheckEqualsString('', StrTrimChar(#39, #39), 'C1');
  CheckEqualsString('', StrTrimChar(#39#39, #39), 'C2');
  CheckEqualsString('22', StrTrimChar('221', '1'), 'C3');
  CheckEqualsString('22', StrTrimChar('122', '1'), 'C4');
  CheckEqualsString('22', StrTrimChar('2211', '1'), 'C5');
  CheckEqualsString('22', StrTrimChar('1122', '1'), 'C6');
  CheckEqualsString('22', StrTrimChar('112211', '1'), 'C7');
  CheckEqualsString('212', StrTrimChar('1121211', '1'), 'C8');
  CheckEqualsString('212', StrTrimChar('"212"', '"'), 'C9');
  CheckEqualsString('KaM Remake Server', StrTrimChar(#39'KaM Remake Server'#39, #39), 'C10');
end;


initialization
  // Register any test cases with the test runner
  RegisterTest('CommonUtils', TestKMCommonUtils.Suite);
end.
