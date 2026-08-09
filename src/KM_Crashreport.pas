unit KM_Crashreport;
{$I KaM_Remake.inc}
interface
uses
  MadExcept,
  KM_GameTypes,
  KM_Defaults;

type
  // Intention of this class is to encapsulate the crash report generation,
  // since it is already quite complex task and spans several methods,
  // which are not quite related to the Game's SRP
  TKMCrashReport = class
  private
    fExceptIntf: IMEException;
    fZipFile: UnicodeString;

    fAttachedFilesStr: UnicodeString;
    procedure AttachFile(const aFile: UnicodeString);
    procedure AttachEverything;
    procedure AttachSaveFiles(const aFile: UnicodeString; aAttachRNG: Boolean = True);
    procedure AttachLoadedFiles(aAttachRNG: Boolean);
  public
    constructor Create(const aExceptIntf: IMEException; const aZipFile: UnicodeString);
    class procedure Generate(const aExceptIntf: IMEException; const aZipFile: UnicodeString);
  end;

implementation
uses
  SysUtils, Math,
  KM_CommonUtils, KM_InterfaceTypes, KM_Log, KM_Game;


constructor TKMCrashReport.Create(const aExceptIntf: IMEException; const aZipFile: UnicodeString);
begin
  inherited Create;

  fExceptIntf := aExceptIntf;
  fZipFile := aZipFile;
end;


procedure TKMCrashReport.AttachFile(const aFile: UnicodeString);
begin
  if (aFile <> '') and FileExists(aFile) then
  begin
    if Pos(aFile, fAttachedFilesStr) = 0 then
    begin
      fAttachedFilesStr := fAttachedFilesStr + aFile + '; ';
      fExceptIntf.AdditionalAttachments.Add(aFile, '', fZipFile);
      gLog.AddTime('Attached file: ' + aFile);
    end
    else
      gLog.AddTime('File already attached: ' + aFile);
  end;
end;


procedure TKMCrashReport.AttachSaveFiles(const aFile: UnicodeString; aAttachRNG: Boolean = True);
begin
  AttachFile(ChangeFileExt(aFile, EXT_SAVE_MAIN_DOT));
  AttachFile(ChangeFileExt(aFile, EXT_SAVE_BASE_DOT));
  AttachFile(ChangeFileExt(aFile, EXT_SAVE_REPLAY_DOT));
  AttachFile(ChangeFileExt(aFile, EXT_SAVE_MP_LOCAL_DOT));
  if aAttachRNG then
    AttachFile(ChangeFileExt(aFile, EXT_SAVE_RNG_LOG_DOT));
end;


procedure TKMCrashReport.AttachLoadedFiles(aAttachRNG: Boolean);
begin
  if gGame.SaveFile = '' then Exit;

  gLog.AddTime('Attaching game loaded file: ' + ExeDir + gGame.SaveFile);
  AttachSaveFiles(ExeDir + gGame.SaveFile, aAttachRNG);
end;


procedure TKMCrashReport.AttachEverything;
var
  index: Byte;
  missionFile, path: UnicodeString;
  searchRec: TSearchRec;
  indexesSet: set of Byte;
begin
  gLog.AddTime('Creating crash report...');

  // Attempt to save the game, but if the state is too messed up it might fail
  gGame.SaveWorkerThreadHolder.Worker.fSynchronousExceptionMode := True; //Do saving synchronously in main thread
  try
    try
      if (gGame.Params.Mode in [gmSingle, gmCampaign, gmMulti, gmMultiSpectate])
      and not (gGame.GamePlayInterface.UIMode = umReplay) then //In case game mode was altered or loaded with logical error
      begin
        gGame.Save(CRASHREPORT_SAVE_NAME, UTCNow, gGame.SaveWorkerThreadHolder.Worker);
        gGame.SaveWorkerThreadHolder.Worker.WaitForAllWorkToComplete; //Wait till save is made
        AttachSaveFiles(gGame.SaveName(CRASHREPORT_SAVE_NAME, EXT_SAVE_MAIN, gGame.Params.IsMultiPlayerOrSpec));
      end;
    except
      on E : Exception do
        gLog.AddTime('Exception while trying to save game for crash report: ' + E.ClassName + ': ' + E.Message
                     {$IFDEF WDC}+ sLineBreak + E.StackTrace{$ENDIF});
    end;
  finally
    gGame.SaveWorkerThreadHolder.Worker.fSynchronousExceptionMode := False;
  end;

  missionFile := gGame.Params.MissionFileRel;
  path := ExtractFilePath(ExeDir + missionFile);

  // Try to attach the dat+map
  AttachFile(ExeDir + missionFile);
  AttachFile(ExeDir + ChangeFileExt(missionFile, '.map'));
  AttachFile(ExeDir + ChangeFileExt(missionFile, '.txt'));

  // Try to add main script file and all other scripts, because they could be included
  if FileExists(ExeDir + ChangeFileExt(missionFile, '.script')) then
  begin
    if FindFirst(path + '*.script', faAnyFile - faDirectory, searchRec) = 0 then
    try
      repeat
        if (searchRec.Name <> '.') and (searchRec.Name <> '..') then
          AttachFile(path + searchRec.Name);
      until FindNext(searchRec) <> 0;
    finally
      FindClose(searchRec);
    end;
  end;

  // Try to add libx files
  if FindFirst(path + '*.libx', faAnyFile - faDirectory, searchRec) = 0 then
  try
    repeat
      if (searchRec.Name <> '.') and (searchRec.Name <> '..') then
        AttachFile(path + searchRec.Name);
    until FindNext(searchRec) <> 0;
  finally
    FindClose(searchRec);
  end;

  if gGame.Params.IsReplay
    or ((gGame.GamePlayInterface <> nil) and (gGame.GamePlayInterface.UIMode = umReplay)) then //In case game mode was altered or loaded with logical error
    // For replays attach only replay save files
    AttachLoadedFiles(False)
  else
  if not gGame.Params.IsMapEditor then // no need autosaves for MapEd error...
  begin
    // For other game modes attach last saves
    
    // We want to attach up to 3 saves, lets determine what are best indexes of last saves to attach
    indexesSet := [];
    // 0 is the oldest save
    case gGame.LastSaves.Count of
      0:      ;
      1,2,3:  indexesSet := [0,1,2];
      4:      indexesSet := [0,2,3];
    else
      indexesSet := [0, gGame.LastSaves.Count div 2, gGame.LastSaves.Count - 1];
    end;

    for index in indexesSet do
    begin
      if index >= gGame.LastSaves.Count then Break;

      AttachSaveFiles(gGame.SaveName(gGame.LastSaves[index], EXT_SAVE_MAIN, gGame.Params.IsMultiPlayerOrSpec));
    end;

    // It could be usefull to attach loaded file, to check what was wrong there
    AttachLoadedFiles(True); // Also attach RNG file
  end;

  gLog.AddTime('Crash report created');
end;


class procedure TKMCrashReport.Generate(const aExceptIntf: IMEException; const aZipFile: UnicodeString);
var
  cr: TKMCrashReport;
begin
  cr := TKMCrashReport.Create(aExceptIntf, aZipFile);
  try
    cr.AttachEverything;
  finally
    cr.Free;
  end;
end;


end.
