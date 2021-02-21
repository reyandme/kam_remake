﻿unit KM_FileIO;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF FPC} lconvencoding, FileUtil, LazUTF8, windirs, {$ENDIF}
  {$IFDEF WDC} System.IOUtils, {$ENDIF}
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLType, {$ENDIF}
  Classes, SysUtils
  {$IFDEF WDC OR FPC_FULLVERSION >= 30200}, KM_WorkerThread{$ENDIF};

  //Read text file into ANSI string (scripts, locale texts)
  function ReadTextA(const afilename: UnicodeString): AnsiString;

  //Read text file into unicode string (locale texts)
  function ReadTextU(const afilename: UnicodeString; aEncoding: Word): UnicodeString;

  //Copy a file (CopyFile is different between Delphi and Lazarus)
  procedure KMCopyFile(const aSrc, aDest: UnicodeString); overload;
  procedure KMCopyFile(const aSrc, aDest: UnicodeString; aOverwrite: Boolean); overload;

  {$IFDEF WDC OR FPC_FULLVERSION >= 30200}
  procedure KMCopyFileAsync(const aSrc, aDest: UnicodeString; aOverwrite: Boolean; aWorkerThread: TKMWorkerThread);
  {$ENDIF}

  //Delete a folder (DeleteFolder is different between Delphi and Lazarus)
  procedure KMDeleteFolder(const aPath: UnicodeString);
  procedure KMDeleteFolderContent(const aPath: UnicodeString);

  //Rename a file (RenameFile is different between Delphi and Lazarus)
  procedure KMRenamePath(const aSourcePath, aDestPath: UnicodeString);

  //Move a folder and rename all the files inside it (MoveFolder is different between Delphi and Lazarus)
  function KMMoveFolder(const aSourceFolder, aDestFolder: UnicodeString): Boolean;

  //Rename all the files inside folder (MoveFolder is different between Delphi and Lazarus)
  procedure KMRenameFilesInFolder(const aPathToFolder, aFromName, aToName: UnicodeString);

  function IsFilePath(const aPath: UnicodeString): Boolean;

  function GetDocumentsSavePath: string;

  procedure CheckFolderPermission(const aPath: string; var aRead, aWrite, aExec: Boolean);

implementation
uses
  StrUtils, KM_CommonUtils,
  KM_Defaults;


function ReadTextA(const aFilename: UnicodeString): AnsiString;
var
  MS: TMemoryStream;
  Head: Cardinal;
begin
  MS := TMemoryStream.Create;
  try
    // We can't rely on StringList because it applies default codepage encoding,
    // which may differ between MP players.
    // Instead we read plain ANSI text. If there's BOM - clip it
    MS.LoadFromFile(aFileName);

    MS.Read(Head, 4);

    //Trim UTF8 BOM (don't know how to deal with others yet)
    if Head and $FFFFFF = $BFBBEF then
      MS.Position := 3
    else
      MS.Position := 0;

    SetLength(Result, MS.Size - MS.Position);
    if MS.Size - MS.Position > 0 then
      MS.Read(Result[1], MS.Size - MS.Position);
  finally
    MS.Free;
  end;
end;


//Load ANSI file with codepage we say into unicode string
function ReadTextU(const aFilename: UnicodeString; aEncoding: Word): UnicodeString;
var
  {$IFDEF WDC}
    SL: TStringList;
    DefaultEncoding: TEncoding;
  {$ENDIF}
  {$IFDEF FPC}
    MS: TMemoryStream;
    Head: Cardinal;
    HasBOM: Boolean;
    TmpA: AnsiString;
  {$ENDIF}
begin
  {$IFDEF WDC}
    SL := TStringList.Create;
    DefaultEncoding := TEncoding.GetEncoding(aEncoding);
    try
      //Load the text file with default ANSI encoding. If file has embedded BOM it will be used
      SL.DefaultEncoding := DefaultEncoding;
      SL.LoadFromFile(aFilename);
      Result := SL.Text;
    finally
      SL.Free;
      DefaultEncoding.Free;
    end;
  {$ENDIF}
  {$IFDEF FPC}
    MS := TMemoryStream.Create;
    try
      MS.LoadFromFile(aFileName);
      MS.Read(Head, 4);

      //Trim UTF8 BOM (don't know how to deal with others yet)
      HasBOM := Head and $FFFFFF = $BFBBEF;

      if HasBOM then
        MS.Position := 3
      else
        MS.Position := 0;

      SetLength(TmpA, MS.Size - MS.Position);
      MS.Read(TmpA[1], MS.Size - MS.Position);

      //Non-UTF8 files must be converted from their native encoding
      if not HasBOM then
        TmpA := ConvertEncoding(TmpA, 'cp' + IntToStr(aEncoding), EncodingUTF8);

      Result := UTF8ToUTF16(TmpA);
    finally
      MS.Free;
    end;
  {$ENDIF}
end;


procedure KMCopyFile(const aSrc, aDest: UnicodeString);
begin
  {$IFDEF FPC}
  CopyFile(pchar(aSrc), pchar(aDest), True);
  {$ENDIF}
  {$IFDEF WDC}
  TFile.Copy(aSrc, aDest);
  {$ENDIF}
end;


procedure KMCopyFile(const aSrc, aDest: UnicodeString; aOverwrite: Boolean);
begin
  if aOverwrite and FileExists(aDest) then
    DeleteFile(aDest);

  {$IFDEF FPC}
  CopyFile(pchar(aSrc), pchar(aDest), True);
  {$ENDIF}
  {$IFDEF WDC}
  TFile.Copy(aSrc, aDest);
  {$ENDIF}
end;


{$IFDEF WDC OR FPC_FULLVERSION >= 30200}
procedure KMCopyFileAsync(const aSrc, aDest: UnicodeString; aOverwrite: Boolean; aWorkerThread: TKMWorkerThread);
begin
  {$IFDEF WDC}
  aWorkerThread.QueueWork(procedure
  begin
    KMCopyFile(aSrc, aDest, aOverwrite);
  end, 'KMCopyFile');
  {$ELSE}
  KMCopyFile(aSrc, aDest, aOverwrite);
  {$ENDIF}
end;
{$ENDIF}


procedure KMDeleteFolder(const aPath: UnicodeString);
{$IFDEF WDC}
var
  S: string;
{$ENDIF}
begin
  if DirectoryExists(aPath) then
  begin
    {$IFDEF FPC}
      DeleteDirectory(aPath, False);
    {$ENDIF}
    {$IFDEF WDC}

      //TDirectory.Delete will sometimes delay deletion due to Windows behaviour
      //Suggested workarounds:
      // - Empty the directory first (seems to work, commented out below)
      // - Move the directory to a temporary name then delete it (sounds more robust)
      //Discussions of workarounds:
      //https://stackoverflow.com/questions/42809389/tdirectory-delete-seems-to-be-asynchronous
      //https://github.com/dotnet/runtime/issues/27958

      //Generate a temporary name based on time and random number
      //S := TDirectory.GetParent(ExcludeTrailingPathDelimiter(aPath)) + PathDelim + IntToStr(Random(MaxInt)) + UIntToStr(TimeGet);
      //TDirectory.Move(aPath, S);
      //TDirectory.Delete(S, True);

      // Rename folder approach could trigger antivirus sometimes (f.e. Kaspersky)
      // so there could be many (almost) empty folders after antivirus block folders deletion
      // "(folder deletion is potentionly dangeroues operation because of data corruption)"
      for S in TDirectory.GetFiles(aPath) do
        DeleteFile(S);
      TDirectory.Delete(aPath, True);
      //Assert(not DirectoryExists(aPath));
    {$ENDIF}
  end;
end;


procedure KMDeleteFolderContent(const aPath: UnicodeString);
{$IFDEF WDC}
var
  S: string;
{$ENDIF}
begin
  if DirectoryExists(aPath) then
  begin
    {$IFDEF FPC}
      DeleteDirectory(aPath, False);
      ForceDirectories(aPath); // We do not care too much about FPC now, recreating directory is ok
    {$ENDIF}
    {$IFDEF WDC}

      //TDirectory.Delete will sometimes delay deletion due to Windows behaviour
      //Suggested workarounds:
      // - Empty the directory first (seems to work, commented out below)
      // - Move the directory to a temporary name then delete it (sounds more robust)
      //Discussions of workarounds:
      //https://stackoverflow.com/questions/42809389/tdirectory-delete-seems-to-be-asynchronous
      //https://github.com/dotnet/runtime/issues/27958

      //Generate a temporary name based on time and random number
      //S := TDirectory.GetParent(ExcludeTrailingPathDelimiter(aPath)) + PathDelim + IntToStr(Random(MaxInt)) + UIntToStr(TimeGet);
      //TDirectory.Move(aPath, S);
      //TDirectory.Delete(S, True);

      // Rename folder approach could trigger antivirus sometimes (f.e. Kaspersky)
      // so there could be many (almost) empty folders after antivirus block folders deletion
      // "(folder deletion is potentionly dangeroues operation because of data corruption)"
      for S in TDirectory.GetFiles(aPath) do
        DeleteFile(S);
      //Assert(not DirectoryExists(aPath));
    {$ENDIF}
  end;
end;


function IsFilePath(const aPath: UnicodeString): Boolean;
begin
  //For now we assume, that folder path always ends with PathDelim
  Result := RightStr(aPath, 1) <> PathDelim;
end;


procedure KMRenameFolder(const aSourcePath, aDestPath: UnicodeString);
begin
  {$IFDEF FPC} RenameFile(aSourcePath, aDestPath); {$ENDIF}
  {$IFDEF WDC} TDirectory.Move(aSourcePath, aDestPath); {$ENDIF}
end;


procedure KMRenamePath(const aSourcePath, aDestPath: UnicodeString);
var
  ErrorStr: UnicodeString;
begin
  if IsFilePath(aSourcePath) then
  begin
    if FileExists(aSourcePath) then
      {$IFDEF FPC} RenameFile(aSourcePath, aDestPath); {$ENDIF}
      {$IFDEF WDC} TFile.Move(aSourcePath, aDestPath); {$ENDIF}
  end
  else
  if DirectoryExists(aSourcePath) then
  begin
    //Try to delete folder up to 3 times. Sometimes folder could not be deleted for some reason
    if not TryExecuteMethodProc(aDestPath, 'KMDeleteFolder', ErrorStr, KMDeleteFolder) then
      raise Exception.Create('Can''t delete folder ' + aDestPath);

     //Try to rename folder up to 3 times. Sometimes folder could not be renamed for some reason
    if not TryExecuteMethodProc(aSourcePath, aDestPath, 'KMRenameFolder', ErrorStr, KMRenameFolder) then
      raise Exception.Create(Format('Can''t rename folder from %s to %s', [aSourcePath, aDestPath]));
  end;
end;


//Rename all files inside folder by pattern _old_name_suffix to _new_name_suffix
//Pattern that we use for most of the files for our maps/saves
procedure KMRenameFilesInFolder(const aPathToFolder, aFromName, aToName: UnicodeString);
var
  I: Integer;
  RenamedFile: UnicodeString;
  SearchRec: TSearchRec;
  FilesToRename: TStringList;
begin
  if (Trim(aFromName) = '')
    or (Trim(aToName) = '')
    or (aFromName = aToName) then
    Exit;

  FilesToRename := TStringList.Create;
  try
    //Find all files to rename in path
    //Need to find them first, rename later, because we can possibly find files, that were already renamed, in case NewName = OldName + Smth
    FindFirst(aPathToFolder + aFromName + '*', faAnyFile - faDirectory, SearchRec);
    try
      repeat
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..')
          and (Length(SearchRec.Name) > Length(aFromName)) then
          FilesToRename.Add(SearchRec.Name);
      until (FindNext(SearchRec) <> 0);
    finally
      FindClose(SearchRec);
    end;

    //Move all previously finded files
    for I := 0 to FilesToRename.Count - 1 do
    begin
       RenamedFile := aPathToFolder + aToName + RightStr(FilesToRename[I], Length(FilesToRename[I]) - Length(aFromName));
       if not FileExists(RenamedFile) and (aPathToFolder + FilesToRename[I] <> RenamedFile) then
         KMRenamePath(aPathToFolder + FilesToRename[I], RenamedFile);
    end;
  finally
    FilesToRename.Free;
  end;
end;


//Move folder and rename all files inside by pattern _old_name_suffix to _new_name_suffix
//Pattern that we use for most of the files for our maps/saves
function KMMoveFolder(const aSourceFolder, aDestFolder: UnicodeString): Boolean;
var
  SrcName, DestName: UnicodeString;
begin
  Result := False;
  if (Trim(aSourceFolder) = '')
    or (Trim(aDestFolder) = '')
    or (aSourceFolder = aDestFolder)
    or not DirectoryExists(aSourceFolder) then Exit;

  KMDeleteFolder(aDestFolder);

  //Move directory to dest first
  KMRenamePath(aSourceFolder, aDestFolder);

  SrcName := GetFileDirName(aSourceFolder);
  DestName := GetFileDirName(aDestFolder);
  //Rename all files there
  KMRenameFilesInFolder(aDestFolder, SrcName, DestName);

  Result := True;
end;


function GetDocumentsSavePath: string;
begin
  // Returns C:\Users\Username\My Documents\My Games\GAME_TITLE\
  // According to GDSE this is the most commonly used savegame location (https://gamedev.stackexchange.com/a/108243)
  if FEAT_SETTINGS_IN_MYDOC then
  {$IFDEF WDC}
    Result := TPath.GetDocumentsPath + PathDelim + 'My Games' + PathDelim + GAME_TITLE + PathDelim
  {$ELSE}
    Result := GetWindowsSpecialDir(CSIDL_PERSONAL) + PathDelim + 'My Games' + PathDelim + GAME_TITLE + PathDelim
  {$ENDIF}
  else
    Result := ExtractFilePath(ParamStr(0));
end;


{$IFDEF WDC}
const
  FILE_READ_DATA = $0001;
  FILE_WRITE_DATA = $0002;
  FILE_APPEND_DATA = $0004;
  FILE_READ_EA = $0008;
  FILE_WRITE_EA = $0010;
  FILE_EXECUTE = $0020;
  FILE_READ_ATTRIBUTES = $0080;
  FILE_WRITE_ATTRIBUTES = $0100;
  FILE_GENERIC_READ = (STANDARD_RIGHTS_READ or FILE_READ_DATA or
    FILE_READ_ATTRIBUTES or FILE_READ_EA or SYNCHRONIZE);
  FILE_GENERIC_WRITE = (STANDARD_RIGHTS_WRITE or FILE_WRITE_DATA or
    FILE_WRITE_ATTRIBUTES or FILE_WRITE_EA or FILE_APPEND_DATA or SYNCHRONIZE);
  FILE_GENERIC_EXECUTE = (STANDARD_RIGHTS_EXECUTE or FILE_READ_ATTRIBUTES or
    FILE_EXECUTE or SYNCHRONIZE);
  FILE_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or SYNCHRONIZE or $1FF;


// example from https://stackoverflow.com/questions/6908152/how-to-get-permission-level-of-a-folder
function CheckFileAccess(const aFileName: string; const aCheckedAccess: Cardinal): Cardinal;
var
  Token: THandle;
  Status: LongBool;
  Access: Cardinal;
  SecDescSize: Cardinal;
  PrivSetSize: Cardinal;
  PrivSet: PRIVILEGE_SET;
  Mapping: GENERIC_MAPPING;
  SecDesc: PSECURITY_DESCRIPTOR;
begin
  Result := 0;
  GetFileSecurity(PChar(aFileName), OWNER_SECURITY_INFORMATION or GROUP_SECURITY_INFORMATION or DACL_SECURITY_INFORMATION, nil, 0, SecDescSize);
  SecDesc := GetMemory(SecDescSize);

  if GetFileSecurity(PChar(aFileName), OWNER_SECURITY_INFORMATION or GROUP_SECURITY_INFORMATION or DACL_SECURITY_INFORMATION, SecDesc, SecDescSize, SecDescSize) then
  begin
    ImpersonateSelf(SecurityImpersonation);
    OpenThreadToken(GetCurrentThread, TOKEN_QUERY, False, Token);
    if Token <> 0 then
    begin
      Mapping.GenericRead := FILE_GENERIC_READ;
      Mapping.GenericWrite := FILE_GENERIC_WRITE;
      Mapping.GenericExecute := FILE_GENERIC_EXECUTE;
      Mapping.GenericAll := FILE_ALL_ACCESS;

      MapGenericMask(Access, Mapping);
      PrivSetSize := SizeOf(PrivSet);
      AccessCheck(SecDesc, Token, aCheckedAccess, Mapping, PrivSet, PrivSetSize, Access, Status);
      CloseHandle(Token);
      if Status then
        Result := Access;
    end;
  end;

  FreeMem(SecDesc, SecDescSize);
end;
{$ENDIF}


// Check game execution dir generic permissions
procedure CheckFolderPermission(const aPath: string; var aRead, aWrite, aExec: Boolean);
begin
  {$IFDEF WDC}
  aRead   := (CheckFileAccess(aPath, FILE_GENERIC_READ) = FILE_GENERIC_READ);
  aWrite  := (CheckFileAccess(aPath, FILE_GENERIC_WRITE) = FILE_GENERIC_WRITE);
  aExec   := (CheckFileAccess(aPath, FILE_GENERIC_EXECUTE) = FILE_GENERIC_EXECUTE);
  {$ENDIF}
  {$IFDEF FPC}
  // No folder permissions check for FPC yet
  aRead   := True;
  aWrite  := True;
  aExec   := True;
  {$ENDIF}
end;


end.
