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
  ExeDir, ProjectDir, WorkDir: UnicodeString;
begin
  Result := '';

  WorkDir := ExeDir + '..\'; // Starting from kam_remake/Utils
	ExeDir := ExtractFilePath(ParamStr(0)); // Starting from kam_remake folder
  ProjectDir := ExeDir + '..\..\'; // Starting from kam_remake/Utils/TranslationManager folder

  if FileExists(WorkDir + TGT_FILE_NAME) then
    Exit(WorkDir);

  if FileExists(ExeDir + TGT_FILE_NAME) then
    Exit(ExeDir);

  if FileExists(ProjectDir + TGT_FILE_NAME) then
    Exit(ProjectDir);

   if aShowWarningMess then
     ShowMessage(
      'Can''t find locales.txt file at destinations:' + sLineBreak +
       ExpandFileName(WorkDir) + TGT_FILE_NAME + sLineBreak +
       ExpandFileName(ExeDir) + TGT_FILE_NAME + sLineBreak +
       ExpandFileName(ProjectDir) + TGT_FILE_NAME);
end;


end.
