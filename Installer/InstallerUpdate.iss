; For each "Update" build there are two things to change. Revision and Upgradable Versions

; REVISION
#include "Revision.iss";

; These don't need to change
#define InstallType 'Update'
#define BuildFolder 'BuildUpdate'
#define OutputEXE 'kam_remake_update'

[Code]
// UPGRADABLE VERSIONS
function CheckRemakeVersion(aVersion:string):boolean;
begin
  //Place all Remake versions that are allowed to be upgraded here
  Result := (aVersion = 'r5503');
end;

function CanInstall():boolean;
var RemakeVersion:string;
begin
  Result := False;
  if RegValueExists(HKLM, 'SOFTWARE\JOYMANIA Entertainment\KnightsandMerchants TPR', 'RemakeVersion') then
  begin
    RegQueryStringValue(HKLM, 'SOFTWARE\JOYMANIA Entertainment\KnightsandMerchants TPR', 'RemakeVersion', RemakeVersion);

    if CheckRemakeVersion(RemakeVersion) or
       (RemakeVersion = ExpandConstant('{#Revision}')) then //Allow reinstalling of the same version
    begin
      Result := true;
    end;
  end;
end;

function CanUpdate(): Boolean;
var InstallFolder: string;
begin
  Result := True;
  InstallFolder := ExpandConstant('{app}');
  if(not(
     FileExists(InstallFolder+'\KaM_Remake.exe') and
     FileExists(InstallFolder+'\data\defines\houses.dat') and
     (FileExists(InstallFolder+'\data\gfx\res\gui.rx') or FileExists(InstallFolder+'\data\Sprites\GUI.rxx')) and
     (FileExists(InstallFolder+'\Resource\Tiles1.tga') or FileExists(InstallFolder+'\data\Sprites\Tileset.rxx')) and
     FileExists(InstallFolder+'\data\sfx\sounds.dat')
     )) then
     Result := False;
end;

[Setup]
EnableDirDoesntExistWarning=yes
DirExistsWarning=no
CreateUninstallRegKey=no
#include "InstallerLib.iss"
