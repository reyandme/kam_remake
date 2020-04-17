{*_* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Author:       François PIETTE
Description:  Time functions.
Creation:     Nov 24, 1999 from Bruce Christensen <bkc51831234@hotmail.com>
              code used with his permission. Thanks.
Version:      8.60
EMail:        francois.piette@overbyte.be  http://www.overbyte.be
Support:      Use the mailing list twsocket@elists.org
              Follow "support" link at http://www.overbyte.be for subscription.
Legal issues: Copyright (C) 1999-2019 by François PIETTE
              Rue de Grady 24, 4053 Embourg, Belgium.
              <francois.piette@overbyte.be>

              This software is provided 'as-is', without any express or
              implied warranty.  In no event will the author be held liable
              for any  damages arising from the use of this software.

              Permission is granted to anyone to use this software for any
              purpose, including commercial applications, and to alter it
              and redistribute it freely, subject to the following
              restrictions:

              1. The origin of this software must not be misrepresented,
                 you must not claim that you wrote the original software.
                 If you use this software in a product, an acknowledgment
                 in the product documentation would be appreciated but is
                 not required.

              2. Altered source versions must be plainly marked as such, and
                 must not be misrepresented as being the original software.

              3. This notice may not be removed or altered from any source
                 distribution.

              4. You must register this software by sending a picture postcard
                 to the author. Use a nice stamp and mention your name, street
                 address, EMail address and any comment you like to say.

History:
Apr 02, 2000 V1.01 Added definition for TIME_ZONE_ID_STANDARD for BCB1 and BCB3
May 20, 2000 V1.01 Added definition for TIME_ZONE_ID_STANDARD for Delphi 3
Oct 23, 2003 V1.10 Added UTCToLocalDT by Angus Robertson, angus@magsys.co.uk
Jan 12, 2004 V1.11 Made function TimeDateStr and DateTimeToUTC public.
Sep 06, 2005 V1.12 Added atoi64, GetFileSize64, DecodeMlsResp64, MySeek64 by Angus Robertson
Aug 31, 2006 V1.13 Removed MySeek64, GetFileSize64 by A.Garrels.
June 11, 2007 V1.14 FileUtcStr now work with directories. Andreas Haas <andreas.haas@ops.de>
                   MDTM2Date now accepts 1, 2 or 3 decimal places for fraction time, by Angus Robertson
                   Note: sysutils FileAge functions used only support round seconds
Dec 04, 2007  V1.15 Added Tick and Trigger functions for timing stuff which
                      supports wrap around after 49 days, by Angus Robertson
                    Added recursive directory listing and argument scanning
                    Added SlashesToBackSlashes and vice versa from FtpSrv
                    Added IntToKbyte to format large numbers
                    Added GetUAgeSizeFile to get age and size of file
                    Added GetFreeSpacePath
Mar 10, 2008 V1.16 FPiette made some changes to prepare code for Unicode
                   GetFileAge: do not use set of char
Apr 22, 2008 V1.17 AGarrels Removed checks for faVolumeID
12 May 2008  V1.18 Removed function atoi it's in OverbyteIcsUtils.pas now.
Jul 10, 2008 V6.01 bumped version, now using TryEncodeDate/Time since D7 and later only
Nov 16, 2008 V7.02 Angus added IcsGetFileSize
Apr 16, 2009 V7.07 Angus FtpFileMD5 and FtpFileCrc32B using buffered stream with unicode
                   Fixed IcsGetTickCountX to never return triggers (two in four billion bug)
Apr 18, 2009 V7.07a Arno added an explicit string conversion in FtpFileMD5() to
                   remove a compiler warning.
May 17, 2009 V7.08 Angus assume STREAM64
                   Added progress callback for IcsBuildDirList/IcsGetDirList so session does
                      not timeout indexing large directories
                   Made IcsBuildDirList and IcsCompareDirNext public
Feb 22, 2011 V7.09 Angus IcsGetDirList always keeps directories for FTP recursive
                      subdirectory listings
May 2012 - V8.00 - Arno added FireMonkey cross platform support with POSIX/MacOS
                   also IPv6 support, include files now in sub-directory
Feb 23, 2016 V8.01 Angus renamed TBufferedFileStream to TIcsBufferedFileStream
Mar 3, 2017  V8.42 Angus TULargeInteger now ULARGE_INTEGER
June 21 2017 V8.49 Moved IcsGetFileSize and GetUAgeSizeFile to Utils
Apr 25, 2018 V8.54 Moved IntToKbyte and ticks stuff to utils
Jan 14, 2019 V8.60 Removed old code moved elsewhere
                   PadIntZero now public and supports integer

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
unit OverbyteIcsFtpSrvT;

interface

{$B-}           { Enable partial boolean evaluation   }
{$T-}           { Untyped pointers                    }
{$X+}           { Enable extended syntax              }
{$H+}           { Use long strings                    }
{$J+}           { Allow typed constant to be modified }
{$I Include\OverbyteIcsDefs.inc}
{$IFDEF COMPILER14_UP}
  {$IFDEF NO_EXTENDED_RTTI}
    {$RTTI EXPLICIT METHODS([]) FIELDS([]) PROPERTIES([])}
  {$ENDIF}
{$ENDIF}
{$WARN SYMBOL_PLATFORM   OFF}
{$WARN SYMBOL_LIBRARY    OFF}
{$WARN SYMBOL_DEPRECATED OFF}
{$IFDEF BCB}
    {$ObjExportAll On}
{$ENDIF}

uses
{$IFDEF MSWindows}
    {$IFDEF RTL_NAMESPACES}Winapi.Windows{$ELSE}Windows{$ENDIF},
{$ENDIF}
    {$IFDEF RTL_NAMESPACES}System.Classes{$ELSE}Classes{$ENDIF},
    {$IFDEF RTL_NAMESPACES}System.SysUtils{$ELSE}SysUtils{$ENDIF},
    OverbyteIcsCRC,        { angus V7.7 }
    OverbyteIcsMD5,        { angus V7.7 }
    OverbyteIcsUtils,
    OverbyteIcsStreams;    { angus V7.7 }

const
    FtpSrvT_Unit       = 860;
    CopyRight : String = ' FtpSrvT  (c) 1999-2019 F. Piette V8.60 ';

type
    TFtpBigInt = Int64;  { V1.13, V7.08 }

    TIcsFileRec = record
        FrSearchRec: TSearchRec; { sysutils record }
        FrSubDirs: string;       { \ for base directory, else located sub directories }
        FrDirLevel: integer;     { 0 for base directory, or level of sub dirs }
        FrDirBaseLen: integer;   { length of basedir within FullName - used for display }
        FrFullName: string;      { basedir, subdirs, filename - complete path }
    end;
    TIcsFileRecs = array of TIcsFileRec ;   { lots of records }
    PTIcsFileRec = ^TIcsFileRec ;           { pointer once record added to TList }

function GetLocalBiasUTC : LongInt; {$IFDEF USE_INLINE} inline; {$ENDIF}
function FileUtcStr(const cFileName : String) : String;
function UTCToLocalDT(dtDT : TDateTime) : TDateTime; {$IFDEF USE_INLINE} inline; {$ENDIF}
function LocalToUtcDT(dtDT : TDateTime) : TDateTime; {$IFDEF USE_INLINE} inline; {$ENDIF}
function UpdateFileAge (const FName: String; const NewDT: TDateTime): boolean;
function UpdateUFileAge (const FName: String; const NewDT: TDateTime): boolean;
function MDTM2Date (S: String): TDateTime;
function DecodeMlsResp (Response: String; var Fname, FType, FAttr: String;
                            var FSize: Integer; var FileUDT: TDateTime): boolean;
function TimeDateStr(dDateTime : TDateTime) : String;
function DateTimeToUTC(dtDT : TDateTime) : TDateTime;
function DecodeMlsResp64 (Response: String; var Fname, FType, FAttr: String;
                            var FSize: Int64; var FileUDT: TDateTime): boolean;

{ V1.15 recursive directory listing and argument scanning }
function IcsGetDirList (const Path: string; SubDirs, Hidden: boolean; var LocFiles:
                 TIcsFileRecs; var LocFileList: TList; Obj: TObject = Nil;
                                    ProgressCallback: TMD5Progress = Nil): integer ;  { V7.08 }
function IcsBuildDirList (const LocDir, LocPartName: String; SubDirs, Hidden: boolean;
     Level, InitDLen: integer ; var TotFiles: integer; var LocFiles: TIcsFileRecs;    { V7.08 }
                         Obj: TObject = Nil; ProgressCallback: TMD5Progress = Nil): boolean ;
function IcsCompareDirNext (Item1, Item2: Pointer): Integer;    { V7.08 renamed }
procedure ScanFindArg (const Params: String; var Start: integer);
function ScanGetAsciiArg (const Params: String; var Start: integer): String;
function ScanGetNextArg(const Params: String; var Start: integer): String;

function SlashesToBackSlashes(const S : String) : String;
function BackSlashesToSlashes(const S : String) : String;

function GetFreeSpacePath(const Path: String): Int64;

function FtpFileMD5(const Filename: String; Obj: TObject = Nil;
                ProgressCallback : TMD5Progress = Nil; StartPos: Int64 = 0;
                            EndPos: Int64 = 0; Mode: Word = DefaultMode): String;
function FtpFileCRC32B(const Filename: String; Obj: TObject = Nil;
                ProgressCallback : TCrcProgress = Nil; StartPos: Int64 = 0;
                            EndPos: Int64 = 0; Mode: Word = DefaultMode): String;
function PadIntZero(num : Integer; nWidth : Byte): String;  { V8.60 }


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
implementation

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function PadIntZero(num : Integer; nWidth : Byte): String;  { V8.60 integer not word }
var
    cResult : String;
begin
    cResult := IntToStr(num);
    while Length(cResult) < nWidth do
        cResult := '0' + cResult;

    Result := cResult;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TimeDateStr(dDateTime : TDateTime) : String;
var
    nYear, nMonth, nDay, nHours, nMinutes, nSeconds, nMilliSecs : Word;
begin
    DecodeDate(dDateTime, nYear, nMonth, nDay);
    DecodeTime(dDateTime, nHours, nMinutes, nSeconds, nMilliSecs);

    Result := PadIntZero(nYear,  4) +
              PadIntZero(nMonth, 2) +
              PadIntZero(nDay,   2) +
              PadIntZero(nHours,   2) +
              PadIntZero(nMinutes, 2) +
              PadIntZero(nSeconds, 2) + '.' +
              PadIntZero(nMilliSecs, 3);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function GetLocalBiasUTC : LongInt;
begin
    Result := OverbyteIcsUtils.IcsGetLocalTimeZoneBias;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function DateTimeToUTC(dtDT : TDateTime) : TDateTime;
begin
    Result := dtDT + GetLocalBiasUTC / (60.0 * 24.0);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function GetFileAge(cFile : String) : Integer;
var
    Ch : Char;
begin
    Ch := cFile[Length(cFile)];         // Unicode change
    if (Ch = '\') or (Ch = '/') then    // Unicode change
        cFile := cFile + '.';
    Result := FileAge(cFile);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{Andreas Haas, 19.12.2006, reworked by Arno 06/12/2007 }
function GetDirAge(const cFile : String) : Integer;
var
    SR : TSearchRec;
begin
    if FindFirst(cFile, faAnyFile, SR) = 0 then begin
        Result := SR.Time;
        {$IFDEF RTL_NAMESPACES}System.{$ENDIF}SysUtils.FindClose(SR);
    end
    else
        Result := -1;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{Andreas Haas, 19.12.2006 get file or directory age, reworked by angus }
function FileUtcStr(const cFileName : String) : String;
var
    FileDate : Integer ;
begin
    FileDate := GetFileAge(cFileName);
    if FileDate = -1 then
        FileDate := GetDirAge(cFileName);
    if FileDate >= 0 then
        Result := TimeDateStr(DateTimeToUTC(FileDateToDateTime(FileDate)))
    else
        Result := '';
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function UTCToLocalDT(dtDT : TDateTime) : TDateTime;
begin
    Result := dtDT - IcsGetLocalTimeZoneBias / (60.0 * 24.0);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function LocalToUtcDT(dtDT : TDateTime) : TDateTime;
begin
    Result := dtDT + IcsGetLocalTimeZoneBias / (60.0 * 24.0);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ Set file time stamp, local time                                           }
{ Sets modified date                                                        }
function UpdateFileAge(const FName: String; const NewDT: TDateTime): boolean;
{$IFNDEF COMPILER16_UP}
var
    H: Integer;
begin
    Result := FALSE;
    H := FileOpen(FName, fmOpenWrite);
    if H < 0 then
        Exit;
    FileSetDate(H, DateTimeToFileDate (NewDT));
    FileClose(H);
    Result := TRUE;
{$ELSE}
begin
    Result := FileSetDate(FName, DateTimeToFileDate(NewDT)) = 0;
{$ENDIF}
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ Set file time stamp, UTC time                                             }
{ Sets modified date                                                        }
function UpdateUFileAge(const FName: String; const NewDT: TDateTime): boolean;
{$IFDEF MSWINDOWS}
var
    H, Age   : Integer;
    FileTime : TFileTime;
begin
    Result := FALSE;
    H      := FileOpen(FName, fmOpenWrite);
    if H < 0 then
        Exit;
    Age := DateTimeToFileDate (NewDT);
    if DosDateTimeToFileTime(LongRec(Age).Hi, LongRec (Age).Lo, FileTime) then begin
        if SetFileTime(H, nil, nil, @FileTime) then
            Result := TRUE;
    end;
    FileClose(H);
{$ELSE}
begin
    Result := FileSetDate(FName,
      DateTimeToFileDate(NewDT + (IcsGetLocalTimeZoneBias / (60.0 * 24.0)))) = 0;
{$ENDIF}
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function MDTM2Date(S: String): TDateTime;
{ yyyymmddhhnnss.zzz  }
{ 20030909221537.1    }
{ 20030909221537.12   }
{ 20030909221537.123  }
{ 1234567890123456789 }
var
    yy, mm, dd, hh, nn, ss, zz: Integer;
    timeDT: TDateTime;

    function GetNum(offset, len: Integer): Integer;
    var
        E: Integer;
    begin
        Val(Copy(S, offset, len), Result, E);
    end;

begin
    Result := 0;
    if Length(S) < 14 then
        Exit;
    yy := GetNum (1, 4);
    mm := GetNum (5, 2);
    if (mm = 0) or (mm > 12) then
        Exit;
    dd := GetNum(7, 2);
    if (dd = 0) or (dd > 31) then
        Exit;
    if not TryEncodeDate (yy, mm, dd, Result) then begin
        Result := -1;
        Exit;
    end;
 {   try   // V6.01 removed, for D5 and earlier
        Result := EncodeDate(yy, mm, dd);
    except
        Result := -1;
        Exit;
    end; }
    hh := GetNum(9, 2);
    nn := GetNum(11, 2);
    ss := GetNum(13, 2);
{ V1.14 allow fractional seconds, 1, 2 or 3 decimal places }
    zz := 0;
    if (Length(S) >= 15) and (Length(S) <= 18) then begin
        if S [15] = '.' then begin
            if Length(S) = 16 then ZZ := GetNum(16, 1) * 100
            else if Length(S) = 17 then ZZ := GetNum(16, 2) * 10
            else ZZ := GetNum(16, 3)
        end;
    end;
    if not TryEncodeTime (hh, nn, ss, zz, timeDT) then begin
        Result := -1;
        Exit;
    end;
    Result := Result + timeDT;
   { try         // V6.01 removed, for D5 and earlier
        Result := Result + EncodeTime(hh, nn, ss, zz);
    except
        Result := -1;
        Exit;
    end; }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function FindMlsFact(const response, fact: String): String;
var
    I: Integer;
    S: String;
begin
    Result := '';
    I := Pos(fact, response);   { ie type=, size=, modify=, perm=  }
    if I <= 0 then
        Exit;
    I := I + Length(fact);
    if I > Length(response) then
        Exit;
    S := Copy(response, I, 999);   { ie size=183977;type=fil }
    I := Pos(';', S);  { fact terminator }
    if I <= 0 then
        Exit;
    Result := Copy(S, 1, Pred (I));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function DecodeMlsResp(
    Response: String;   var Fname, FType, FAttr: String;
    var FSize: Integer; var FileUDT: TDateTime): boolean;
var
    I: Integer;
begin
    Result  := FALSE;
    FName   := '';
    FType   := '';
    FAttr   := '';
    FSize   := 0;
    FileUDT := 0;
    I := Pos(#32, Response);  { file name follows first space in line, may be mixed case }
    if I = 1 then
        Exit;
    if Length(Response) < Succ (I) then
        Exit;
    FName    := Copy(Response, Succ (I), 999);
    Response := LowerCase(Response);  { remaining arguments all case insensitive }
    FType    := FindMlsFact(Response, 'type=');
    FSize    := atoi(FindMlsFact(Response, 'size='));
    FileUDT  := MDTM2Date(FindMlsFact(Response, 'modify='));
    FAttr    := FindMlsFact(Response, 'perm=');
    Result   := TRUE;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function DecodeMlsResp64(
    Response: String;   var Fname, FType, FAttr: String;
    var FSize: Int64; var FileUDT: TDateTime): boolean;
var
    I: Integer;
begin
    Result  := FALSE;
    FName   := '';
    FType   := '';
    FAttr   := '';
    FSize   := 0;
    FileUDT := 0;
    I := Pos(#32, Response);  { file name follows first space in line, may be mixed case }
    if I = 1 then
        Exit;
    if Length(Response) < Succ (I) then
        Exit;
    FName    := Copy(Response, Succ (I), 999);
    Response := LowerCase(Response);  { remaining arguments all case insensitive }
    FType    := FindMlsFact(Response, 'type=');
    FSize    := atoi64(FindMlsFact(Response, 'size='));
    FileUDT  := MDTM2Date(FindMlsFact(Response, 'modify='));
    FAttr    := FindMlsFact(Response, 'perm=');
    Result   := TRUE;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ V1.15, builds list of files in a directory and sub directories, optional
  search path Level and InitDLen should be 0, except when called recursively
  LocFiles array should be set to length zero, generally
  returns FALSE for error or if cancelled from copyevent  }
function IcsBuildDirList (const LocDir, LocPartName: String; SubDirs, Hidden: boolean;
     Level, InitDLen: integer ; var TotFiles: integer; var LocFiles: TIcsFileRecs;
                         Obj: TObject = Nil; ProgressCallback: TMD5Progress = Nil): boolean ;
var
    SearchRec: TSearchRec ;
    curname: string;
    retcode: integer;
    savename: boolean;
    Cancel: boolean;
begin
    if (Length(LocFiles) = 0) then SetLength(LocFiles, 100);
    Result := TRUE;
    Cancel := false;
    if InitDLen = 0 then InitDLen := Length(LocDir);
    try
        try
            if Assigned(ProgressCallback) then  { V7.08 indexing may take several minutes }
            begin
                ProgressCallback(Obj, TotFiles, Cancel);
                if Cancel then
                begin
                    Result := FALSE;
                    Exit;
                end;
            end;

      { loop through directory getting all file names in directory }
            retcode := FindFirst (LocDir + LocPartName, faAnyFile, SearchRec);
            while (retcode = 0) do
            begin
                curname := SearchRec.Name;

             { don't save directory markers unless no subs }
                savename := ((curname <> '.') and (curname <> '..')) OR (not SubDirs);

             { ignore hidden files and directories }
                if (not Hidden) and ((SearchRec.Attr and faHidden) = faHidden) then
                                                                    savename := FALSE;
                //if ((SearchRec.Attr and faVolumeID) = faVolumeID) then savename := FALSE;

             { found another directory, recursively call this function to process it }
                if savename and (((SearchRec.Attr and faDirectory) =
                                               faDirectory) and SubDirs) then begin
                    if not IcsBuildDirList (LocDir + CurName + '\', LocPartName,
                                     SubDirs, Hidden, succ(Level), InitDLen, TotFiles,
                                                        LocFiles, Obj, ProgressCallback) then  { V7.08 }
                        exit;
                  { savename := FALSE;  V7.09 always keep directories }
                end;

             { add file to dynamic array, allocating more memory if needed }
                if savename then begin
                    inc(TotFiles);
                    if Length(LocFiles) <= TotFiles then
                                         SetLength(LocFiles, TotFiles * 2);
                    with LocFiles[pred(TotFiles)] do
                    begin
                        FrSearchRec := SearchRec;
                        FrSubDirs := Copy(LocDir, InitDLen, 255);
                        FrFullName := LocDir + curname;
                        FrDirLevel := Level;
                        FrDirBaseLen := Pred (InitDLen);
                    end;
                end;
                retcode := FindNext (SearchRec);
            end;
        except
            Result := FALSE;
        end;
    finally
        FindClose(SearchRec);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ V1.15 called by TList for sort and find comparison of file records - case
  insensitive, Compare returns < 0 if Item1 is less than Item2, 0 if they are
  equal and > 0 if Item1 is greater than Item2. }
function IcsCompareDirNext (Item1, Item2: Pointer): Integer;    { V7.08 renamed }
var
    Sort1, Sort2: string ;
begin
{ using fullname might be faster, ! as last path delim makes files sort before dirs }
    Sort1  := PTIcsFileRec (Item1).FrSubDirs + '!' + PTIcsFileRec (Item1).FrSearchRec.Name;
    Sort2  := PTIcsFileRec (Item2).FrSubDirs + '!' + PTIcsFileRec (Item2).FrSearchRec.Name;
    Result := CompareText (Sort1, Sort2);  // case insensitive
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ V1.15 builds sorted list of files in a directory and sub directories, optional
  search path returns total files, or -1 for error }
function IcsGetDirList (const Path: string; SubDirs, Hidden: boolean;
                        var LocFiles: TIcsFileRecs; var LocFileList: TList;
                             Obj: TObject = Nil; ProgressCallback: TMD5Progress = Nil): integer ;
var
    I, totfiles: integer ;
    flag: boolean ;
    LocDir, LocPartName: string;
begin
    SetLength(LocFiles, 1000);
    totfiles := 0 ;
    if not Assigned (LocFileList) then LocFileList := TList.Create ;
    LocFileList.Clear ;
    LocDir := ExtractFilePath (Path);
    LocPartName := ExtractFileName (Path);
    if LocPartName = '' then LocPartName := '*.*';
    flag := IcsBuildDirList (LocDir, LocPartName, SubDirs, Hidden,
                             0, 0, totfiles, LocFiles, Obj, ProgressCallback);  { V7.08 }
    if not flag then begin
        SetLength(LocFiles, 0);
        Result := -1 ;
        exit;
    end;
    Result := totfiles ;
    SetLength(LocFiles, totfiles);
    if Result = 0 then
        exit;

  { build list and sort it }
    LocFileList.Capacity := totfiles ;
    for I := 0 to Pred (totfiles) do LocFileList.Add (@LocFiles [I]);
    LocFileList.Sort (IcsCompareDirNext);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ V1.15 scan parameter string for start of next argument }
procedure ScanFindArg (const Params: String; var Start: integer);
begin
    while (Start <= Length(Params)) and
          ((Params[Start] = ' ') or (Params[Start] = #9)) do
       Inc (Start);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function IsLetterOrDigit(Ch : Char) : Boolean;
begin
    Result := ((Ch >= 'a') and (Ch <= 'z')) or
              ((Ch >= 'A') and (Ch <= 'Z')) or
              ((Ch >= '0') and (Ch <= '9'));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ V1.15 scan parameter string and return argument with only ASCII characters }
function ScanGetAsciiArg (const Params: String; var Start: integer): String;
var
    I: integer;
begin
    Result := '';
    ScanFindArg (Params, Start);
    I := Start;
    while (Start <= Length(Params)) and
          (IsLetterOrDigit(Params[Start])) do
        Inc (Start);
    if Start - I > 0 then
        Result := Copy (Params, I, Start - I);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ V1.15 scan parameter string and return next argument up to next blank
  unless a delimited file name string when ignore embedded blanks }
function ScanGetNextArg(const Params: String; var Start: integer): String;
var
    I: integer;
begin
    Result := '';
    ScanFindArg (Params, Start);
    if Start > Length(Params) then
        exit;
    if (Params[Start] = '"') or (Params[Start] = '''') then begin  { see if file name is delimited }
        I := Start;
        inc (Start);
        while (Start <= Length(Params)) and
            (Params[Start] <> Params [I]) do Inc(Start);  { find second delimiter }
        if Start - I >= 2 then begin
            Result := Copy(Params, I + 1, Start - 2);
            Inc(Start);
        end;
    end
    else begin
        I := Start;
        while (Start <= Length(Params)) and
              (not ((Params[Start] = ' ') or (Params[Start] = #9))) do
            Inc(Start);
        if Start - I > 0 then
            Result := Copy(Params, I, Start - I);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function SlashesToBackSlashes(const S : String) : String;
var
    I : Integer;
begin
    Result := S;
    for I := 1 to Length(Result) do begin
        if Result [I] = '/' then
            Result[I] := '\';
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function BackSlashesToSlashes(const S : String) : String;
var
    I : Integer;
begin
    Result := S;
    for I := 1 to Length(Result) do begin
        if Result [I] = '\' then
            Result[I] := '/';
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ get free space for path or drive }
function GetFreeSpacePath (const Path: String): int64;
begin
    Result := IcsGetFreeDiskSpace(Path);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}     { V7.07 }
function FtpFileMD5(const Filename: String; Obj: TObject = Nil;
                ProgressCallback : TMD5Progress = Nil; StartPos: Int64 = 0;
                            EndPos: Int64 = 0; Mode: Word = DefaultMode): String;
var
    Stream: TStream;
begin
    Result := '';
    { Open file }
    Stream := TIcsBufferedFileStream.Create(FileName, Mode, MAX_BUFSIZE);
//  Stream := TFileStream.Create(Filename, Mode);
    try
        Result := String(StreamMD5(Stream, Obj, ProgressCallback, StartPos, EndPos));  { V7.07a }
    finally
        { Free the file }
        Stream.Free;
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}     { V7.07 }
function FtpFileCRC32B(const Filename: String; Obj: TObject = Nil;
                ProgressCallback : TCrcProgress = Nil; StartPos: Int64 = 0;
                            EndPos: Int64 = 0; Mode: Word = DefaultMode): String;
var
    Stream: TStream;
begin
    Result := '';
    { Open file }
    Stream := TIcsBufferedFileStream.Create(FileName, Mode, MAX_BUFSIZE);
//  Stream := TFileStream.Create(Filename, Mode);
    try
        Result := StreamCRC32B(Stream, Obj, ProgressCallback, StartPos, EndPos);
    finally
        { Free the file }
        Stream.Free;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
initialization

finalization

end.

