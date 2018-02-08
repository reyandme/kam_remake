﻿unit KM_FileIO;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF FPC} lconvencoding, FileUtil, LazUTF8, {$ENDIF}
  {$IFDEF WDC} System.IOUtils, {$ENDIF}
  Classes, SysUtils;

  //Read text file into ANSI string (scripts, locale texts)
  function ReadTextA(const afilename: UnicodeString): AnsiString;

  //Read text file into unicode string (locale texts)
  function ReadTextU(const afilename: UnicodeString; aEncoding: Word): UnicodeString;

  //Copy a file (CopyFile is different between Delphi and Lazarus)
  procedure KMCopyFile(const aSrc, aDest: UnicodeString); overload;
  procedure KMCopyFile(const aSrc, aDest: UnicodeString; aOverwrite: Boolean); overload;

  //Delete a folder (DeleteFolder is different between Delphi and Lazarus)
  procedure KMDeleteFolder(const aPath: UnicodeString);

  //Rename a file (RenameFile is different between Delphi and Lazarus)
  procedure KMRenamePath(const aSourcePath, aDestPath: UnicodeString);

  //Move a folder and rename all the files inside it (MoveFolder is different between Delphi and Lazarus)
  function KMMoveFolder(const aSourceFolder, aDestFolder: UnicodeString): Boolean;

  //Rename all the files inside folder (MoveFolder is different between Delphi and Lazarus)
  procedure KMRenameFilesInFolder(const aPathToFolder, aFromName, aToName: UnicodeString);


  function IsFilePath(const aPath: UnicodeString): Boolean;


implementation
uses
  StrUtils, KM_CommonUtils;


function ReadTextA(const aFilename: UnicodeString): AnsiString;
var
  MS: TMemoryStream;
  Head: Cardinal;
begin
  MS := TMemoryStream.Create;
  try
    //We can't rely on StringList because it applies default codepage encoding,
    //which may differ between MP players.
    //Instead we read plain ansi text. If there's BOM - clip it
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
  CopyFile(aSrc, aDest);
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
  CopyFile(aSrc, aDest);
  {$ENDIF}
  {$IFDEF WDC}
  TFile.Copy(aSrc, aDest);
  {$ENDIF}
end;


procedure KMDeleteFolder(const aPath: UnicodeString);
begin
  if DirectoryExists(aPath) then
    {$IFDEF FPC} DeleteDirectory(aPath, False); {$ENDIF}
    {$IFDEF WDC} TDirectory.Delete(aPath, True); {$ENDIF}
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
    repeat
      if (SearchRec.Name <> '.') and (SearchRec.Name <> '..')
        and (Length(SearchRec.Name) > Length(aFromName)) then
        FilesToRename.Add(SearchRec.Name);
    until (FindNext(SearchRec) <> 0);
    FindClose(SearchRec);

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


end.
