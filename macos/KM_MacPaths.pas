unit KM_MacPaths;
{$I ../KaM_Remake.inc}
interface

function MacGameDataDir: string;


implementation
uses
  Classes, SysUtils, Process;

const
  ASSET_FOLDERS: array[0..6] of string = ('data', 'Sounds', 'Music', 'Maps', 'MapsMP', 'Campaigns', 'Tutorials');
  ASSET_VERSION_FILE = 'assets-version.txt';

var
  gGameDataDir: string;


procedure CopyAssetFolder(const aSource, aDestination: string);
var
  copyProcess: TProcess;
begin
  copyProcess := TProcess.Create(nil);
  try
    // Cloning avoids a second physical copy on APFS. Other volumes use a regular copy.
    copyProcess.Executable := '/bin/cp';
    copyProcess.Options := [poWaitOnExit];
    copyProcess.Parameters.Add('-cR');
    copyProcess.Parameters.Add(aSource);
    copyProcess.Parameters.Add(ExcludeTrailingPathDelimiter(aDestination));
    copyProcess.Execute;
    if copyProcess.ExitStatus <> 0 then
    begin
      copyProcess.Parameters[0] := '-R';
      copyProcess.Execute;
    end;
    if copyProcess.ExitStatus <> 0 then
      raise Exception.Create('Could not copy game assets into ' + aDestination);
  finally
    FreeAndNil(copyProcess);
  end;
end;


function MacGameDataDir: string;
var
  source, destination, sourceVersion, installedVersion: string;
  versionFile: TStringList;
  I: Integer;
begin
  if gGameDataDir <> '' then
    Exit(gGameDataDir);

  source := ExpandFileName(ExtractFilePath(ParamStr(0)) + '../Resources/game/');
  if not DirectoryExists(source + 'data') then
    Exit(ExtractFilePath(ParamStr(0)));

  destination := GetEnvironmentVariable('KAM_DATA_DIR');
  if destination = '' then
    destination := GetEnvironmentVariable('HOME') + '/Library/Application Support/KaM Remake';
  destination := IncludeTrailingPathDelimiter(ExpandFileName(destination));
  if not ForceDirectories(destination) then
    raise Exception.Create('Could not create game data directory ' + destination);

  versionFile := TStringList.Create;
  try
    versionFile.LoadFromFile(source + ASSET_VERSION_FILE);
    sourceVersion := versionFile.Text;
    installedVersion := '';
    if FileExists(destination + ASSET_VERSION_FILE) then
    begin
      versionFile.LoadFromFile(destination + ASSET_VERSION_FILE);
      installedVersion := versionFile.Text;
    end;
    // Keep writable saves and settings outside the signed application bundle.
    if sourceVersion <> installedVersion then
    begin
      for I := Low(ASSET_FOLDERS) to High(ASSET_FOLDERS) do
        if DirectoryExists(source + ASSET_FOLDERS[I]) then
          CopyAssetFolder(source + ASSET_FOLDERS[I], destination);
      versionFile.Text := sourceVersion;
      versionFile.SaveToFile(destination + ASSET_VERSION_FILE);
    end;
  finally
    FreeAndNil(versionFile);
  end;

  gGameDataDir := destination;
  Result := gGameDataDir;
end;


end.
