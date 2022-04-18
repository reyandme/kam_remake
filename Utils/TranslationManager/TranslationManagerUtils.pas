unit TranslationManagerUtils;
{$I ..\..\KaM_Remake.inc}
interface


	function GetWorkDir(aShowWarningMess: Boolean = False): UnicodeString;


implementation
uses
	SysUtils, Dialogs;


function GetWorkDir(aShowWarningMess: Boolean = False): UnicodeString;
const
  TGT_FILE_NAME = 'data\locales.txt';
var
  exeDir, projectDir, workDir: UnicodeString;
begin
  Result := '';

  workDir := exeDir + '..\'; // Starting from kam_remake/Utils
	exeDir := ExtractFilePath(ParamStr(0)); // Starting from kam_remake folder
  projectDir := exeDir + '..\..\'; // Starting from kam_remake/Utils/TranslationManager folder

  if FileExists(workDir + TGT_FILE_NAME) then
    Exit(workDir);

  if FileExists(exeDir + TGT_FILE_NAME) then
    Exit(exeDir);

  if FileExists(projectDir + TGT_FILE_NAME) then
    Exit(projectDir);

   if aShowWarningMess then
     ShowMessage(
      'Can''t find locales.txt file at destinations:' + sLineBreak +
       ExpandFileName(workDir) + TGT_FILE_NAME + sLineBreak +
       ExpandFileName(exeDir) + TGT_FILE_NAME + sLineBreak +
       ExpandFileName(projectDir) + TGT_FILE_NAME);
end;


end.
