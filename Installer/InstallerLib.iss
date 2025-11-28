; Knights and Merchants: Remake
; Installer Script
#define MyAppName 'KaM Remake Beta'
;#define MyAppFullName 'KaM Remake Beta rXXXXX'
#define MyAppExeName 'KaM_Remake.exe';
#define Website 'http://www.kamremake.com/'

#define CheckKaM

[Setup]
AppId={{FDE049C8-E4B2-4EB5-A534-CF5C581F5D32}
AppName={code:GetAppFullName}
AppVersion={#Revision}
AppVerName={code:GetAppFullName}
AppPublisher={#MyAppName}
AppPublisherURL={#Website}
AppSupportURL={#Website}
AppUpdatesURL={#Website}
VersionInfoCompany={#MyAppName}
VersionInfoVersion=1.0
VersionInfoProductName={#MyAppName}
DefaultDirName={autopf}\{code:GetAppFullName} 
LicenseFile=License.eng.txt
DisableProgramGroupPage=yes
UsePreviousAppDir=no
OutputDir={#OutputFolder}
OutputBaseFilename={#OutputEXE} {#Revision}
Compression=lzma2/ultra64
SolidCompression=yes
LZMANumBlockThreads=4
LZMAUseSeparateProcess=yes 
ShowLanguageDialog=yes
Uninstallable=yes
SetupIconFile=Embedded\KaM_Remake.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
WizardImageFile=Embedded\WizardImage.bmp
WizardSmallImageFile=Embedded\WizardSmallImage.bmp
  
[Languages]  
Name: "eng"; MessagesFile: "compiler:Default.isl";
Name: "cze"; MessagesFile: "compiler:Languages\Czech.isl"; LicenseFile: "License.cze.txt"
Name: "dut"; MessagesFile: "compiler:Languages\Dutch.isl"; LicenseFile: "License.dut.txt"
Name: "fin"; MessagesFile: "compiler:Languages\Finnish.isl"; LicenseFile: "License.fin.txt"
Name: "fre"; MessagesFile: "compiler:Languages\French.isl"; LicenseFile: "License.fre.txt"
Name: "ger"; MessagesFile: "compiler:Languages\German.isl"; LicenseFile: "License.ger.txt"
Name: "hun"; MessagesFile: "compiler:Languages\Hungarian.isl"; LicenseFile: "License.hun.txt"
Name: "pol"; MessagesFile: "compiler:Languages\Polish.isl"; LicenseFile: "License.pol.txt"
Name: "rus"; MessagesFile: "compiler:Languages\Russian.isl"; LicenseFile: "License.rus.txt"
Name: "ita"; MessagesFile: "compiler:Languages\Italian.isl"; LicenseFile: "License.ita.txt"
Name: "svk"; MessagesFile: "ExtraLanguages\Slovak.isl"; LicenseFile: "License.svk.txt"
Name: "spa"; MessagesFile: "compiler:Languages\Spanish.isl"; LicenseFile: "License.spa.txt"
Name: "swe"; MessagesFile: "ExtraLanguages\Swedish.isl"; LicenseFile: "License.swe.txt"
Name: "ptb"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"; LicenseFile: "License.ptb.txt"
Name: "bul"; MessagesFile: "ExtraLanguages\Bulgarian.isl"; LicenseFile: "License.bul.txt"
Name: "est"; MessagesFile: "ExtraLanguages\Estonian.isl"; LicenseFile: "License.est.txt"
Name: "rom"; MessagesFile: "ExtraLanguages\Romanian.isl"; LicenseFile: "License.rom.txt"
Name: "lit"; MessagesFile: "ExtraLanguages\Lithuanian.isl";
Name: "ukr"; MessagesFile: "compiler:Languages\Ukrainian.isl"; LicenseFile: "License.ukr.txt"
Name: "chn"; MessagesFile: "ExtraLanguages\ChineseSimplified.isl"; LicenseFile: "License.chn.txt"
Name: "nor"; MessagesFile: "compiler:Languages\Norwegian.isl"; LicenseFile: "License.nor.txt"
Name: "bel"; MessagesFile: "ExtraLanguages\Belarusian.isl"; LicenseFile: "License.bel.txt"
Name: "jpn"; MessagesFile: "compiler:Languages\Japanese.isl"; LicenseFile: "License.jpn.txt"
Name: "tur"; MessagesFile: "ExtraLanguages\Turkish.isl"; LicenseFile: "License.tur.txt"
Name: "kor"; MessagesFile: "ExtraLanguages\Korean.isl"; LicenseFile: "License.kor.txt"
Name: "srb"; MessagesFile: "ExtraLanguages\SerbianCyrillic.isl"; LicenseFile: "License.srb.txt"
Name: "slv"; MessagesFile: "compiler:Languages\Slovenian.isl"; LicenseFile: "License.slv.txt"

[CustomMessages]  
#include "Translations.iss"


[Registry]
Root: HKLM; Subkey: "SOFTWARE\JOYMANIA Entertainment\KnightsandMerchants TPR"; ValueType: string; ValueName: "RemakeVersion"; ValueData: {#Revision}; Flags:uninsdeletevalue;
Root: HKLM; Subkey: "SOFTWARE\JOYMANIA Entertainment\KnightsandMerchants TPR"; ValueType: string; ValueName: "RemakeDIR"; ValueData: "{app}"; Flags:uninsdeletevalue;

[Run]
;Filename: "{app}\PostInstallClean.bat"; WorkingDir: "{app}"; Flags: runhidden
Filename: "{code:GetReadmeLang}";  Description: {cm:ViewReadme};  Flags: postinstall shellexec skipifsilent
Filename: "{app}\{#MyAppExeName}"; Description: {cm:LaunchProgram,{code:GetAppFullName}}; Flags: postinstall nowait skipifsilent unchecked

[UninstallRun]
Filename: "{app}\uninst_clean.bat"; Flags: runhidden

[Code]

#ifdef CheckKaM
#include "CheckKaM.iss"
#endif

procedure InitializeWizard;
var Diff: Integer;
begin
	//Change width of WizardSmallBitmapImage up to 125 
  Diff := ScaleX(125) - WizardForm.WizardSmallBitmapImage.Width;
  WizardForm.WizardSmallBitmapImage.Width := WizardForm.WizardSmallBitmapImage.Width + Diff
	WizardForm.WizardSmallBitmapImage.Left := WizardForm.WizardSmallBitmapImage.Left - Diff - 5; // 5px margin to right border
  WizardForm.PageDescriptionLabel.Width := WizardForm.PageDescriptionLabel.Width - Diff - 5;
  WizardForm.PageNameLabel.Width := WizardForm.PageNameLabel.Width - Diff - 5;
end;


//Executed before the wizard appears, allows us to check that they have KaM installed
function InitializeSetup(): Boolean;
var Warnings:string;
begin
  Warnings := '';

  #ifdef CheckKaM
  if not CheckKaM() then
    Warnings := ExpandConstant('{cm:NoKaM}') + #13#10#13#10 + ExpandConstant('{cm:SteamFirstRun}');
  #endif
  
  if not CanInstall() then
  begin
    if Warnings <> '' then
      Warnings := Warnings + '' + #13#10#13#10; //Two EOLs between messages
    Warnings := Warnings + ExpandConstant('{cm:CantUpdate}')
  end;
  
  if Warnings = '' then
    Result := True
  else
  begin
    Result := False;
    MsgBox(Warnings, mbInformation, MB_OK);
  end;
end;


//This event is executed right after installing, use this time to install OpenAL
function NeedRestart(): Boolean;
var
  ResultCode: Integer;
  settingsText: String;
begin
  Result := false; //We never require a restart, this is just a handy event for post install

  // Create the setting file with the right language selected (if it was missing)
  settingsText := '<?xml version="1.0" encoding="UTF-8"?><Root><Game><GameCommon Locale="' + ExpandConstant('{language}') + '"/></Game></Root>';
  if not FileExists(ExpandConstant('{userdocs}') + '\My Games\Knights and Merchants Remake\KaM Remake Settings.xml') then
  begin
    ForceDirectories(ExpandConstant('{userdocs}') + '\My Games\Knights and Merchants Remake\');
    SaveStringToFile(ExpandConstant('{userdocs}') + '\My Games\Knights and Merchants Remake\KaM Remake Settings.xml', settingsText, False);
  end;

  //Now install OpenAL, if needed
  if not FileExists(ExpandConstant('{sys}') + '\OpenAL32.dll') then 
    if MsgBox(ExpandConstant('{cm:OpenAL}'), mbConfirmation, MB_YESNO or MB_DEFBUTTON2) = idYes then
      Exec(ExpandConstant('{app}\oalinst.exe'), '/S', '', SW_SHOW, ewWaitUntilTerminated, ResultCode);
end;


function GetReadmeLang(Param: String): string;
begin
  Result := ExpandConstant('{app}\Readme_{language}.html'); //Use the user's language if possible
  if not FileExists(Result) then
    Result := ExpandConstant('{app}\Readme_eng.html'); //Otherwise use English
end;


function GetAppFullName(Param: String): string;
begin
  Result := '{#MyAppName} {#Revision}';
end;


function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  NeedsRestart := False;
  if not CanUpdate() then
  begin
    Result := ExpandConstant('{cm:CantUpdate}');
    Exit;
  end;

  Result := '';
  //If previous MapsMP folder exists rename it to -old.
  if DirExists(ExpandConstant('{app}\MapsMP')) then
    RenameFile(ExpandConstant('{app}\MapsMP\'), ExpandConstant('{app}\MapsMP-old\'));
end;


function IsEmptyDir(dirName: String): Boolean;
var
  FindRec: TFindRec;
  FileCount: Integer;
begin
  Result := False;
  if FindFirst(dirName+'\*', FindRec) then begin
    try
      repeat
        if (FindRec.Name <> '.') and (FindRec.Name <> '..') then begin
          FileCount := 1;
          break;
        end;
      until not FindNext(FindRec);
    finally
      FindClose(FindRec);
      if FileCount = 0 then Result := True;
    end;
  end;
end;


procedure CurUninstallStepChanged (CurUninstallStep: TUninstallStep);
begin
  case CurUninstallStep of                   
    usPostUninstall:
      begin
        // Ask confirmation to delete all Maps and Campaigns
        if MsgBox(ExpandConstant('{cm:DeleteMaps}'), mbConfirmation, MB_YESNO or MB_DEFBUTTON2) = idYes then
        begin
          DelTree(ExpandConstant('{app}\Campaigns'), True, True, True);
          DelTree(ExpandConstant('{app}\Maps'), True, True, True);
          DelTree(ExpandConstant('{app}\MapsMP'), True, True, True);
          DelTree(ExpandConstant('{app}\MapsDL'), True, True, True);
        end;
        
        // Ask confirmation to delete all Saves
        if (DirExists(ExpandConstant('{app}\Saves')) or DirExists(ExpandConstant('{app}\SavesMP')) or DirExists(ExpandConstant('{app}\SavesCMP'))) 
          and (MsgBox(ExpandConstant('{cm:DeleteSaves}'), mbConfirmation, MB_YESNO or MB_DEFBUTTON2) = idYes) then
        begin
          DelTree(ExpandConstant('{app}\Saves'), True, True, True);
          DelTree(ExpandConstant('{app}\SavesMP'), True, True, True);
          DelTree(ExpandConstant('{app}\SavesCMP'), True, True, True);
        end;
        
        // Delete app folder if its empty
        if DirExists(ExpandConstant('{app}')) and IsEmptyDir(ExpandConstant('{app}')) then
          DelTree(ExpandConstant('{app}'), True, True, True);
      end;
  end;
end;  


[Dirs]
Name: "{app}"; Permissions: users-modify


[Files]
Source: "{#BuildFolder}\Campaigns\*"; DestDir: "{app}\Campaigns"; Flags: ignoreversion recursesubdirs createallsubdirs uninsneveruninstall
Source: "{#BuildFolder}\Maps\*"; DestDir: "{app}\Maps"; Flags: ignoreversion recursesubdirs createallsubdirs uninsneveruninstall
Source: "{#BuildFolder}\MapsMP\*"; DestDir: "{app}\MapsMP"; Flags: ignoreversion recursesubdirs createallsubdirs uninsneveruninstall
Source: "{#BuildFolder}\*"; DestDir: "{app}"; Excludes: "\Campaigns\*,\Maps\*,\MapsMP\*"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "oalinst.exe"; DestDir: "{app}"; Flags: ignoreversion
;Source: "PostInstallClean.bat"; DestDir: "{app}"; Flags: ignoreversion

[Tasks]
Name: programgroup; Description: {cm:CreateStartShortcut};
Name: desktopicon; Description: {cm:CreateDesktopIcon}; Flags:Unchecked

[Icons]
Name: "{commonprograms}\{code:GetAppFullName}\{code:GetAppFullName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: programgroup
Name: "{commonprograms}\{code:GetAppFullName}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"; Tasks: programgroup; Flags: excludefromshowinnewinstall
Name: "{commonprograms}\{code:GetAppFullName}\{cm:ViewReadme}"; Filename: "{code:GetReadmeLang}"; Tasks: programgroup; Flags: excludefromshowinnewinstall
Name: "{commondesktop}\{code:GetAppFullName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
