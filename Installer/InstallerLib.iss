; Knights and Merchants: Remake
; Installer Script
#define MyAppName 'KaM Remake'
#define MyAppExeName 'KaM_Remake.exe';
#define Website 'http://www.kamremake.com/'

#define CheckKaM

;http://stfx-wow.googlecode.com/svn-history/r418/trunk/NetFxIS/setup.iss
;http://tdmaker.googlecode.com/svn/trunk/Setup/tdmaker-anycpu.iss
;http://tdmaker.googlecode.com/svn/trunk/Setup/scripts/products.iss

[Setup]
AppId={{FDE049C8-E4B2-4EB5-A534-CF5C581F5D32}
AppName={#MyAppName}
AppVerName={#MyAppName} {#InstallType} {#Revision}
AppPublisherURL={#Website}
AppSupportURL={#Website}
AppUpdatesURL={#Website}
DefaultDirName={sd}\Games\{#MyAppName}
LicenseFile=License.eng.txt
DisableProgramGroupPage=yes
OutputDir=Output
OutputBaseFilename={#OutputEXE}_{#Revision}
Compression=lzma2
SolidCompression=no
ShowLanguageDialog=yes
Uninstallable=yes
SetupIconFile=Embedded\KaM_Remake.ico
WizardImageFile=Embedded\WizardImage.bmp
WizardSmallImageFile=Embedded\WizardSmallImage.bmp
  
[Languages]  
Name: "eng"; MessagesFile: "compiler:Default.isl";
Name: "cze"; MessagesFile: "compiler:Languages\Czech.isl"; LicenseFile: "License.cze.txt"
Name: "dut"; MessagesFile: "compiler:Languages\Dutch.isl"; LicenseFile: "License.dut.txt"
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
Name: "srb"; MessagesFile: "compiler:Languages\SerbianCyrillic.isl"; LicenseFile: "License.srb.txt"
Name: "slv"; MessagesFile: "compiler:Languages\Slovenian.isl"; LicenseFile: "License.slv.txt"

[CustomMessages]  
#include "Translations.iss"


[Registry]
Root: HKLM; Subkey: "SOFTWARE\JOYMANIA Entertainment\KnightsandMerchants TPR"; ValueType: string; ValueName: "RemakeVersion"; ValueData: {#Revision}; Flags:uninsdeletevalue;
Root: HKLM; Subkey: "SOFTWARE\JOYMANIA Entertainment\KnightsandMerchants TPR"; ValueType: string; ValueName: "RemakeDIR"; ValueData: "{app}"; Flags:uninsdeletevalue;

[Run]
Filename: "{app}\PostInstallClean.bat"; WorkingDir: "{app}"; Flags: runhidden
Filename: "{code:GetReadmeLang}";  Description: {cm:ViewReadme};  Flags: postinstall shellexec skipifsilent
Filename: "{app}\{#MyAppExeName}"; Description: {cm:LaunchProgram,{#MyAppName}}; Flags: postinstall nowait skipifsilent unchecked

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
    Warnings := ExpandConstant('{cm:NoKaM}');
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
var ResultCode: Integer; MyText:String;
begin
  Result := false; //We never require a restart, this is just a handy event for post install

  //First create the ini file with the right language selected
  MyText := '[Game]'+#13+#10+'Locale='+ExpandConstant('{language}');
  SaveStringToFile(ExpandConstant('{app}\KaM_Remake_Settings.ini'), MyText, False);
  
  //Now install OpenAL, if needed
  if FileExists(ExpandConstant('{sys}')+'\OpenAL32.dll') then exit; //User already has OpenAL installed
  if MsgBox(ExpandConstant('{cm:OpenAL}'), mbConfirmation, MB_YESNO) = idYes then
  begin
    Exec(ExpandConstant('{app}\oalinst.exe'), '/S', '', SW_SHOW, ewWaitUntilTerminated, ResultCode);
  end;
end;

function GetReadmeLang(Param: String): string;
begin
  Result := ExpandConstant('{app}\Readme_{language}.html'); //Use the user's language if possible
  if not FileExists(Result) then
    Result := ExpandConstant('{app}\Readme_eng.html'); //Otherwise use English
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

[Files]
Source: "{#BuildFolder}\*"; DestDir: "{app}"; Excludes: "*.svn,*.svn\*"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "oalinst.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "PostInstallClean.bat"; DestDir: "{app}"; Flags: ignoreversion

[Tasks]
Name: programgroup; Description: {cm:CreateStartShortcut};
Name: desktopicon; Description: {cm:CreateDesktopIcon}; Flags:Unchecked

[Icons]
Name: "{commonprograms}\{#MyAppName}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: programgroup
Name: "{commonprograms}\{#MyAppName}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"; Tasks: programgroup; Flags: excludefromshowinnewinstall
Name: "{commonprograms}\{#MyAppName}\{cm:ViewReadme}"; Filename: "{code:GetReadmeLang}"; Tasks: programgroup; Flags: excludefromshowinnewinstall
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
