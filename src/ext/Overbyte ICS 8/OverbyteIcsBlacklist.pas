{*_* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Author:       Angus Robertson, Magenta Systems Ltd
Description:  TIcsBlackList supports blackisting or block listing of IP addresses
              that attempt repeated failed access to TCP/IP servers. It maintains
              a list of IP addresses or Values that have previously exceeded a
              specific number of failed attempts, against which new attempts may
              be checked.  Unit also contains logging functions.
Creation:     March 2009
Updated:      Feb 2019
Version:      8.60
EMail:        francois.piette@overbyte.be  http://www.overbyte.be
Support:      https://en.delphipraxis.net/forum/37-ics-internet-component-suite/
Legal issues: Copyright (C) 2002-2019 by Angus Robertson, Magenta Systems Ltd,
              Croydon, England. delphi@magsys.co.uk, https://www.magsys.co.uk/delphi/

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



BlockAttempts - maximum attempts allowed within BlockAfterMins period
BlockAfterMins - period in minutes in which BlockAttempts allowed
BlockForMins - minutes for which further attempts blocked after max reached


Baseline - March 2009
2 June 2010  - better attempt to clear old data when removed IPs from blacklist
18 July 2012 - added GetCountAll and GetCountBlock
14 Oct 2016  - added SaveAscii to save strings instead of IP addresses
               added ListName propertry for events
               better check for old saved duplicates
14 Nar 2019  - V8.60 - Adapted for main ICS packages and FMX support.
                       Renamed from TMagBlacklist to TIcsBlacklist
                       Added TIcsStringBuild to efficiently build Ansi or Unicode
                        strings on all versions of Delphi.
                       Added TIcsBuffLogStream buffered log stream designed to
                        write large log files, flushing regularly to disk by
                        opening, writing and closing each time the buffer fills
                        or after a timeout of X seconds. The file name is
                        date/time mask format, typically for one log file per day.
                        Write files in ANSI, UTF-9 or UTF-16, with a BOM.
                       Added IcsSimpleLogging write text to end of old or new
                        file, opening and closing file, ignores any errors,
                        not designed for continual updating!  The file name is
                        date/time mask format, typically for one log file per day.


Note: TIcsBlacklist IP Mask, and White List not implemented yet

There is a web server test application OverbyteIcsSslMultiWebServ.dpr that
uses TIcsBlacklist to block potential hackers and abusers.


 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{$IFNDEF ICS_INCLUDE_MODE}
unit OverbyteIcsBlacklist;
{$ENDIF}

{$I Include\OverbyteIcsDefs.inc}

{$IFDEF COMPILER14_UP}
  {$IFDEF NO_EXTENDED_RTTI}
    {$RTTI EXPLICIT METHODS([]) FIELDS([]) PROPERTIES([])}
  {$ENDIF}
{$ENDIF}
{$B-}             { Enable partial boolean evaluation   }
{$T-}             { Untyped pointers                    }
{$X+}             { Enable extended syntax              }
{$H+}             { Use long strings                    }
{$IFDEF BCB}
    {$ObjExportAll On}
{$ENDIF}

interface

uses
{$IFDEF MSWINDOWS}
    {$IFDEF RTL_NAMESPACES}Winapi.Messages{$ELSE}Messages{$ENDIF},
    {$IFDEF RTL_NAMESPACES}Winapi.Windows{$ELSE}Windows{$ENDIF},
{$ENDIF}
{$IFDEF POSIX}
    Posix.Time,
    Ics.Posix.WinTypes,
    Ics.Posix.Messages,
{$ENDIF}
    {$Ifdef Rtl_Namespaces}System.Classes{$Else}Classes{$Endif},
    {$Ifdef Rtl_Namespaces}System.Sysutils{$Else}Sysutils{$Endif},
    {$IFDEF Rtl_Namespaces}System.DateUtils{$ELSE}DateUtils{$ENDIF},
{$IFDEF FMX}
    Ics.Fmx.OverbyteIcsWndControl,
{$ELSE}
    OverbyteIcsWndControl,
{$ENDIF FMX}
    OverbyteIcsTypes,
    OverbyteIcsTicks64,
    OverbyteIcsUtils;


const
    CopyRight    : String     = ' TIcsBlacklist  (c) 2019 V8.60 ';

    OneMask = '255.255.255.255' ;
    MaxAttempts = 9999 ;  // 1 Sept 2009, was 100

type

  TBlackRec = record
    Addr: LongWord ;       // 32-bit IP address
    Mask: LongWord ;
    Value: string ;      // Oct 2016
    Ascii: boolean ;     // Oct 2016
    FirstUtime: int64 ;  // Unix time, seconds since 1970
    LastUtime: int64 ;
    Attempts: integer ;
    ReasonId: integer ;
  end ;
  PTBlackRec = ^TBlackRec ;

  TWhiteRec = record
    Addr: LongWord ;
    Mask: LongWord ;
    Value: string ;      // Oct 2016
  end ;

  TBlackLogEvent = procedure (const info: string) of object ;

  TIcsBlacklist = class(TIcsWndControl)
  private
    { Private declarations }
  protected
    { Protected declarations }
    fBlackRecs: array of TBlackRec ;
    fBlackIdx: TIcsFindList ;
    fTotBlackRecs: integer ;
    fWhiteRecs: array of TWhiteRec ;
    fWhiteIdx: TIcsFindList ;
    fTotWhiteRecs: integer ;
    fBlackFile: string ;
    fWhiteFile: string ;
    fTimer: TIcsTimer ;
    fChangedFlag: boolean ;
    fFlushMins: integer ;
    fCleanMins: integer ;
    fFlushTrg: int64 ;
    fCleanTrg: int64 ;
    fBlockAfterMins: integer ;
    fBlockAttempts: integer ;
    fBlockForMins: integer ;
    fSaveAscii: boolean ;  // Oct 2016
    fListName: string ;    // Oct 2016
    fBlackLogEvent: TBlackLogEvent ;
    procedure SetFlushMins (Value: integer) ;
    procedure SetCleanMins (Value: integer) ;
    procedure SetBlackFile (Value: string) ;
    procedure OnTimer (Sender: TObject);
    function ResizeArray (NewLen: integer): integer ;
  public
    { Public declarations }
    constructor Create(Aowner:TComponent); override;
    destructor Destroy; override;
    procedure doLogEvent (const info: string) ;
    procedure FlushToFiles ;
    procedure LoadFromFiles ;
    procedure ClearList ;
    procedure CleanList ;
    procedure RebuildList;
    procedure AddBlackList (const IpAddr, IpMask: string; ReasonId: integer) ;
    procedure AddWhiteList (const IpAddr, IpMask: string) ;
    procedure RemBlackList (const IpAddr: string) ;
    procedure RemWhiteList (const IpAddr: string) ;
    function CheckBlackList (const IpAddr: string): boolean ;
    function GetFullBlackList(const IpAddr: string): TBlackRec ;
    function FailedBlackList (const IpAddr: string; ReasonId: integer): boolean ;
    function InternalAddBlack (const IpAddr, IpMask: string;
                                  MoreAttempts: boolean; ReasonId: integer): TBlackRec ;
    function ReportBlackList (All: boolean): string ;
    function GetCountAll: integer ;    // 18 July 2012
    function GetCountBlock: integer ;   // 18 July 2012
  published
    { Published declarations }
    property SaveAscii: boolean         read fSaveAscii      write fSaveAscii;  // Oct 2016
    property ListName: string           read fListName       write fListName;
    property BlackFile: string          read fBlackFile      write SetBlackFile;
    property WhiteFile: string          read fWhiteFile      write fWhiteFile;
    property FlushMins: integer         read fFlushMins      write SetFlushMins;
    property CleanMins: integer         read fCleanMins      write SetCleanMins;
    property BlockAfterMins: integer    read fBlockAfterMins write fBlockAfterMins;
    property BlockAttempts: integer     read fBlockAttempts  write fBlockAttempts;
    property BlockForMins: integer      read fBlockForMins   write fBlockForMins;
    property BlackLogEvent: TBlackLogEvent read fBlackLogEvent write fBlackLogEvent;

  end;

  // TIcsStringBuild Class

  TIcsStringBuild = class(TObject)
  private
    FBuffMax: integer;
    FBuffSize: integer;
    FIndex: integer;
    FBuffer: TBytes;
    FCharSize: integer;
    procedure ExpandBuffer;
  public
    constructor Create (ABufferSize: integer = 4096; Wide: Boolean = False) ;
    destructor Destroy; override;
    procedure AppendBuf(const AString: AnsiString); overload;
    procedure AppendBuf(const AString: UnicodeString); overload;
    procedure AppendBufW(const AString: UnicodeString);
    procedure AppendLine(const AString: AnsiString); overload;
    procedure AppendLine(const AString: UnicodeString); overload;
    procedure AppendLineW(const AString: UnicodeString);
    procedure Clear ;
    function GetAString: AnsiString;
    function GetWString: UnicodeString;
    function GetString: String;
    procedure Capacity (ABufferSize: integer);
    property Len: integer            read FIndex;
    property Buffer: TBytes          read FBuffer;
  end;



  // buffered log file stream, designed to write log files, flushing regularly to disk
  TFileCodePage = (FileCPAnsi, FileCPUtf8, FileCPUtf16);
  TIcsBuffLogStream = class(TIcsWndControl)
  private
    FBuffer: TIcsStringBuild;
    FIdleSecs: Integer;
    FIdleTimer: TIcsTimer;
    FHeader: String;
    FBuffMax: Integer;
    FNameMask: String;
    FLogSize: integer;
    FFullName: string;
    FOpenAttempts: integer;
    FOpenDelayMs: LongWord;
    FFileCP: TFileCodePage;
  protected
    procedure OnTimer(Sender: TObject);
    procedure SetIdleSecs(IdleSecs: Integer);
    procedure SetNameMask(sNameMask: String);
    procedure SetFileCP(sFileCP: TFileCodePage);
  public
    constructor Create(Aowner: TComponent; const sNameMask, sHeader: String;
                                    sFileCP: TFileCodePage = FileCPAnsi); reintroduce;
    destructor Destroy; override;
    function FlushFile(OldFName: Boolean = False): Integer;
    function WriteLine(const Line: String; AddCRLF: Boolean = True): Integer;
    property BuffMax: Integer        read FBuffMax      write FBuffMax;
    property Header: String          read FHeader       write FHeader;
    property IdleSecs: Integer       read FIdleSecs     write SetIdleSecs;
    property NameMask: String        read FNameMask     write SetNameMask;
    property FileCP: TFileCodePage   read FFileCP       write SetFileCP;
    property OpenAttempts: Integer   read FOpenAttempts write FOpenAttempts;
    property OpenDelayMs: LongWord   read FOpenDelayMs  write FOpenDelayMs;
    property LogSize: integer        read FLogSize ;
    property FullName: string        read FFullName ;
  end;

procedure IcsSimpleLogging (const FNameMask, Msg: String);  { V8.60 }

resourcestring
  SFBuffOpenError = 'Cannot open buffer file %s';

implementation

{ TIcsBlacklist }

// must turn off range checking off
{$R-}
{$Q-}

// convert IP address into ASCII and vice versa


function ConvertIPAddr (Addr: LongWord): string ;
var
   I: integer ;
   num4: longword ;
   num1: array [1..4] of byte absolute num4 ;
begin
    num4 := Addr ;
    result := '' ;
    for I := 1 to 4 do
    begin
        result := result + IntToStr (num1 [I]) ;
        if I = 4 then exit ;
        result := result + '.' ;
    end ;
end ;

function IpToStr (Addr: LongWord): string ;
begin
    result := ConvertIPAddr (Addr) ;
end;

function Str2IP (strIP: string; var IPAddr: LongWord): boolean ;
var
    I, len, value, startpos, dotpos: Integer;
    MyIPAddr: array [1..4] of byte ;
    nonzeroflag: boolean ;
begin
    result := false ;
    IPAddr := 0;
    len := Length (strIP) ;
    if len < 7 then exit ;    // 0.0.0.0 bare IP address

// read each dotted number
    nonzeroflag := false ;
    startpos := 1 ;
    for I := 1 to 4 do
    begin
        if len <= 0 then exit ;
        if I < 4 then
            dotpos := Pos ('.', Copy (strIP, startpos, len))
        else
            dotpos := len + 1 ;
        if dotpos <= 0 then exit ;   // not enough dots
        if dotpos > 1 then
            value := atoi (Copy (strIP, startpos, Pred (dotpos)))
        else
            value := 0 ;  // allow for blank
        if value > 255 then exit ;   // number invalid for conversion
        if value > 0 then nonzeroflag := true ;
        MyIPAddr [I] := value ;
        startpos := startpos + dotpos ;
        len := len - dotpos ;
    end ;

// check valid IP address, only allowed all zeroes
    if (MyIPAddr [1] = 0) and nonzeroflag then exit ;

// found a valid IP address, keep it
    Move (MyIPAddr, IPAddr, SizeOf(LongWord)) ;
    result := true ;
end ;

function StrToIP (strIP: string): LongWord ;
begin
    Str2IP (strIP, result) ;
end ;

function IsIPStr (strIP: string): boolean ;
var
    IPAddr: LongWord ;
begin
   result := Str2IP (strIP, IPAddr) ;
end ;

function IsFmtIPStr (var strIP: string): boolean ;
var
    IPAddr: LongWord ;
begin
    result := Str2IP (strIP, IPAddr) ;
    if result then strIP := ConvertIPAddr (IPAddr) ;  // formats less space, zeros, etc.
end ;


constructor TIcsBlacklist.Create(Aowner: TComponent);
begin
    inherited;
    SetLength (fBlackRecs, 0) ;
    fBlackIdx := TIcsFindList.Create ;
    fBlackIdx.Sorted := true ;
    fTotBlackRecs := 0 ;
    SetLength (fWhiteRecs, 0) ;
    fWhiteIdx := TIcsFindList.Create ;
    fWhiteIdx.Sorted := true ;
    fTotWhiteRecs := 0 ;
    fBlackFile := '' ;
    fWhiteFile := '' ;
    fChangedFlag := false ;
    SetFlushMins (5) ;
    SetCleanMins (2) ;
    fBlockAfterMins := 5 ;
    fBlockAttempts := 5 ;
    fBlockForMins := 120 ;
    fSaveAscii := false ;  // Oct 2016
    fListName := 'Blacklist' ;  // Oct 2016
    AllocateHWnd;
    fTimer := TIcsTimer.Create (self) ;
    fTimer.OnTimer := OnTimer ;
    fTimer.Interval := 30 * TicksPerSecond ;
    fTimer.Enabled := true ;
end;

destructor TIcsBlacklist.Destroy;
begin
    try
        if fChangedFlag then FlushToFiles ;
    except
    end ;
    SetLength (fBlackRecs, 0) ;
    FreeAndNil (fBlackIdx) ;
    SetLength (fWhiteRecs, 0) ;
    FreeAndNil (fWhiteIdx) ;
    FreeAndNil (fTimer) ;
    inherited;
end;

{ swap 32-bit longword endian, useful for IP addresses so they sort }

function EndianLong (L: LongWord): LongWord;
begin
  result := Swap (L shr 16) or (LongWord (Swap (L and $ffff)) shl 16);
end;


// called by TFindList for sort and find comparison
// swap endian of IP addresses so they sort nicely

function CompareBlackRec (Item1, Item2: Pointer): Integer;
// Compare returns < 0 if Item1 is less than Item2, 0 if they are equal
// and > 0 if Item1 is greater than Item2.
begin
    if PTBlackRec (Item1).Ascii then
    begin
        result := CompareText (PTBlackRec (Item1).Value, PTBlackRec (Item2).Value) ;
    end
    else
    begin
        if PTBlackRec (Item1).Addr = PTBlackRec (Item2).Addr then
            result := 0
        else if EndianLong (PTBlackRec (Item1).Addr) < EndianLong (PTBlackRec (Item2).Addr) then
            result := -1
        else
            result := 1 ;
    end;
end ;

// resize array and list for new records

function TIcsBlacklist.ResizeArray (NewLen: integer): integer ;
var
    OldLen, K: integer ;
begin
    OldLen := Length (fBlackRecs) ;
    if NewLen < 16 then NewLen := 16 ;
    SetLength (fBlackRecs, NewLen) ;
    for K := OldLen to Pred (NewLen) do
    begin
        with fBlackRecs [K] do
        begin
            Addr := 0 ;  // clear new addresses
            Value := '' ;
            Ascii := false ;
            Attempts := 0 ;  // 2 June 2010 clear record
            FirstUtime := 0 ;
            LastUtime := 0 ;
        end ;
    end;
    fBlackIdx.Capacity := NewLen ;
    result := NewLen ;
    RebuildList;  // 20 May 2009 rebuild index
    doLogEvent (fListName + ': Increased Empty List Size to ' + IntToStr (NewLen)) ;
end ;

// internal add IP address to blacklist, incremented attempts if done already
// information is saved in a dynamic array, with a sorted list pointing to the
// each record used to search actual IP address (saved as 32-bits).  If an IP
// is removed, the IP for the record is set to zero, and the record then re-used.
// The array is increased in size if too short.

function TIcsBlacklist.InternalAddBlack (const IpAddr, IpMask: string;
                                   MoreAttempts: boolean; ReasonId: integer): TBlackRec ;
var
    BlackRec: TBlackRec ;
    Index, OldLen, K: integer ;
begin
    result.Addr := 0 ;
    result.Value := '' ;
    result.Attempts := 0 ;  // 2 June 2010
    result.ascii := fSaveAscii ;     // Oct 2016
    BlackRec.ascii := fSaveAscii ;   // Oct 2016
    if fSaveAscii then
    begin
        if IpAddr = '' then exit ;
         BlackRec.Value := IpAddr ;  // Oct 2016
    end
    else
    begin
        if NOT Str2IP (IpAddr, BlackRec.Addr) then exit ;  // sanity check
    end ;
    if fBlackIdx.Find (@BlackRec, CompareBlackRec, Index) then
    begin
     // IP already listed, update record and increment attempts
        PTBlackRec (fBlackIdx [Index]).LastUtime := IcsGetUnixTime ;
        if MoreAttempts then
        begin
            if PTBlackRec (fBlackIdx [Index]).Attempts < MaxAttempts then
            begin
                inc (PTBlackRec (fBlackIdx [Index]).Attempts) ;
                fChangedFlag := true ;
            end ;
        end
        else
        begin
            PTBlackRec (fBlackIdx [Index]).Attempts := MaxAttempts ;
            fChangedFlag := true ;
        end ;
        result := PTBlackRec (fBlackIdx [Index])^ ;
    end
    else
    begin
    // create new record for this IP
        Str2IP (IpMask, BlackRec.Mask) ;
        BlackRec.ReasonId := ReasonId ;
        BlackRec.FirstUtime := IcsGetUnixTime ;
        BlackRec.LastUtime := BlackRec.FirstUtime ;
        if MoreAttempts then
            BlackRec.Attempts := 1
        else
            BlackRec.Attempts := MaxAttempts ;
        result := BlackRec ;

       // see if allocating more memory in array
        OldLen := Length (fBlackRecs) ;
        if OldLen <= fTotBlackRecs then OldLen := ResizeArray (OldLen * 2) ;

     // find first free record in array
        Index := -1 ;
        for K := 0 to Pred (OldLen) do
        begin
            if fBlackRecs [K].ascii then
            begin
                if fBlackRecs [K].Value = '' then
                begin
                    Index := K ;
                    break ;
                end ;
            end
            else
            begin
                if fBlackRecs [K].Addr = 0 then
                begin
                    Index := K ;
                    break ;
                end ;
            end;
        end ;
        if Index < 0 then
        begin
            doLogEvent (fListName + ': Internal Error, No Blank Records') ;
            exit ;
        end ;

      // add record to array and sorted list
        fBlackRecs [Index] := BlackRec ;
        fBlackIdx.AddSorted (@fBlackRecs [Index], CompareBlackRec) ;
        inc (fTotBlackRecs) ;
        fChangedFlag := true ;
        doLogEvent (fListName + ': Added New Item: ' + IpAddr +
                                    ', Total Items ' + IntToStr (fTotBlackRecs)) ;
    end ;
end;

// unconditional add IP address to blacklist, no more attempts allowed

procedure TIcsBlacklist.AddBlackList(const IpAddr, IpMask: string;
                                                      ReasonId: integer);
begin
    InternalAddBlack (IpAddr, IpMask, false, ReasonId) ;
end;

// add IP address and mask to white list

procedure TIcsBlacklist.AddWhiteList(const IpAddr, IpMask: string);
begin

end;

// get black list record for specific IP address

function TIcsBlacklist.GetFullBlackList(const IpAddr: string): TBlackRec ;
var
    BlackRec: TBlackRec ;
    Index: integer ;
begin
    result.Addr := 0 ;
    result.Value := '' ;
    result.Attempts := 0 ;  // 2 June 2010
    result.Ascii := fSaveAscii ;   // Oct 2016
    BlackRec.ascii := fSaveAscii ;   // Oct 2016
    if fSaveAscii then
    begin
        if IpAddr = '' then exit ;
         BlackRec.Value := IpAddr ;  // Oct 2016
    end
    else
    begin
        if NOT Str2IP (IpAddr, BlackRec.Addr) then exit ;  // sanity check
    end ;
    if (fTotBlackRecs = 0) then exit ;
    if fBlackIdx.Find (@BlackRec, CompareBlackRec, Index) then
                            result := PTBlackRec (fBlackIdx [Index])^ ;
end;

// check if IP address in black list and exceeded maximum attempts
// return true if blocked

function TIcsBlacklist.CheckBlackList(const IpAddr: string): boolean;
var
    BlackRec: TBlackRec ;
begin
    result := false ;
    BlackRec := GetFullBlackList (IpAddr) ;
    if (BlackRec.Attempts = 0) then exit ;  // not found
    if (BlackRec.Attempts >= fBlockAttempts) then result := true ;
end;

// notify a failed login attempt, add IP address to black list if not already
// done otherwise increment attempts counter, return true if now blocked

function TIcsBlacklist.FailedBlackList(const IpAddr: string;
                                            ReasonId: integer): boolean;
var
    BlackRec: TBlackRec ;
begin
    result := false ;
    BlackRec := InternalAddBlack (IpAddr, OneMask, true, ReasonId) ;
    if (BlackRec.Attempts = 0) then exit ;  // not found
    if (BlackRec.Attempts >= fBlockAttempts) then result := true ;
end;

// remove an IP address from black list

procedure TIcsBlacklist.RemBlackList(const IpAddr: string);
var
    BlackRec: TBlackRec ;
    Index: integer ;
begin
    Blackrec.ascii := fSaveAscii ;   // Oct 2016
    if fSaveAscii then
    begin
        if IpAddr = '' then exit ;
         BlackRec.Value := IpAddr ;  // Oct 2016
    end
    else
    begin
        if NOT Str2IP (IpAddr, BlackRec.Addr) then exit ;  // sanity check
    end ;
    if (fTotBlackRecs = 0) then exit ;
    if fBlackIdx.Find (@BlackRec, CompareBlackRec, Index) then
    begin
        PTBlackRec (fBlackIdx [Index]).Addr := 0 ;
        PTBlackRec (fBlackIdx [Index]).Value := '' ;
        PTBlackRec (fBlackIdx [Index]).Attempts := 0 ;
        PTBlackRec (fBlackIdx [Index]).Ascii := false ;
        PTBlackRec (fBlackIdx [Index]).FirstUtime := 0 ;
        PTBlackRec (fBlackIdx [Index]).LastUtime := 0 ;
        fBlackIdx.Delete (Index) ;
        dec (fTotBlackRecs) ;
        fChangedFlag := true ;
    end ;
end;

// remove an IP address from white list

procedure TIcsBlacklist.RemWhiteList(const IpAddr: string);
begin
    //
end;

// rebuild black list sorted index to array ignoring blank records
// pending - could also compact list periodically if too many blanks

procedure TIcsBlacklist.RebuildList;
var
    I: integer ;
begin
    fBlackIdx.Clear ;
    if fBlackIdx.Capacity < (Length (fBlackRecs) * 2) then
                        fBlackIdx.Capacity := Length (fBlackRecs) * 2 ;
    for I := 0 to Pred (Length (fBlackRecs)) do
    begin
        if (fBlackRecs [I].Attempts <> 0) then
                fBlackIdx.AddSorted (@fBlackRecs [I], CompareBlackRec) ;
    end ;
    fTotBlackRecs := fBlackIdx.Count ;
    doLogEvent (fListName + ': Rebuilt List, Total Items ' + IntToStr (fTotBlackRecs)) ;
    fChangedFlag := true ;
end ;

// clean black list by removing any IP addresses that have been blocked but
// whose blocked time has now expired, and IPs not blocked because they did not
// reach the maximum within the allowed period

procedure TIcsBlacklist.CleanList;
var
    I: integer ;
    rebuild: boolean ;
    utime: int64 ;
begin
    if (fTotBlackRecs = 0) then exit ;
    rebuild := false ;
    utime := IcsGetUnixTime ;
    for I := 0 to Pred (Length (fBlackRecs)) do
    begin
        with fBlackRecs [I] do
        begin
            if (Attempts > 0) then
            begin
                if (Attempts >= fBlockAttempts) then
                begin
                    if (((utime - LastUtime) div 60) >= fBlockForMins) or
                                                        (LastUtime > utime) then
                    begin
                        if Ascii then
                            doLogEvent (fListName + ': Removed Blocked Item: ' + Value)
                        else
                            doLogEvent (fListName + ': Removed Blocked Item: ' + IpToStr (Addr)) ;
                        Addr := 0 ;
                        Ascii := false ;
                        Value := '' ;
                        Attempts := 0 ;  // 2 June 2010 clear record
                        FirstUtime := 0 ;
                        LastUtime := 0 ;
                        rebuild := true ;
                    end ;
                end
                else
                begin
                    if (((utime - FirstUtime) div 60) >= fBlockAfterMins) or
                                                        (FirstUtime > utime) then
                    begin
                        if Ascii then
                            doLogEvent (fListName + ': Removed Old Item: ' + Value)
                        else
                            doLogEvent (fListName + ': Removed Old Item: ' + IpToStr (Addr)) ;
                        Addr := 0 ;
                        Value := '' ;
                        Ascii := false ;
                        Attempts := 0 ;  // 2 June 2010 clear record
                        FirstUtime := 0 ;
                        LastUtime := 0 ;
                        rebuild := true ;
                    end ;
                end ;
            end ;
        end ;
    end ;
    if rebuild then RebuildList;
end;

// clear black list of all IP addresses

procedure TIcsBlacklist.ClearList;
begin
    fTotBlackRecs := 0 ;
    SetLength (fBlackRecs, 0) ;
    fBlackIdx.Clear ;
    fChangedFlag := true ;
end;

// log event

procedure TIcsBlacklist.doLogEvent (const info: string) ;
begin
    if Assigned (fBlackLogEvent) then fBlackLogEvent (info) ;
end;

// flush black and white lists to comma separated ASCII files
// this is done automatically every two minutes and when the component
// is destroyed

procedure TIcsBlacklist.FlushToFiles;
var
    FileLines: TStringList ;
    I: integer ;
    S: string ;
begin
    fChangedFlag := false ;
    if fBlackFile = '' then exit ;  // no file name means nothing to save
    if NOT Assigned (fBlackIdx) then exit ;  // sanity check
    FileLines := TStringList.Create ;
    try
        if (fTotBlackRecs > 0) then
        begin
            for I := 0 to Pred (Length (fBlackRecs)) do
            begin
                with fBlackRecs [I] do
                begin
                    if (Attempts = 0) or (FirstUtime = 0) then continue ;
                    if Ascii then
                    begin
                        S := Value ;
                        if S = '' then continue ;
                    end
                    else
                    begin
                        if Addr = 0 then continue ;
                        S := IpToStr (Addr) ;
                    end;
                    FileLines.Add (S + ',' + IpToStr (Mask) + ',' +
                        IntToStr (FirstUtime) + ',' + IntToStr (LastUtime) + ',' +
                                     IntToStr (Attempts) + ',' + IntToStr (ReasonId) ) ;
                end ;
            end ;
        end ;
        try
            if FileExists (fBlackFile) then
                {$Ifdef Rtl_Namespaces}System.Sysutils{$Else}Sysutils{$Endif}.DeleteFile (fBlackFile) ;
            FileLines.SaveToFile (fBlackFile) ;
            doLogEvent (fListName + ': Saved to File: ' + fBlackFile) ;
        except
            doLogEvent (fListName + ': Failed File Save: ' + fBlackFile +
                                         ' - ' + IcsGetExceptMess (ExceptObject)) ;
        end ;
    finally
        FileLines.Free ;
        fChangedFlag := false ;
    end ;
end;

// load black and white lists from comma separated ASCII files, then Clean
// any IP addresses that have expired and flush back to disk
// this is done automatically when the BlackFile property is assigned a file name

procedure TIcsBlacklist.LoadFromFiles;
var
    FileLines, FileRecord: TStringList ;
    I, BadNr, Index: integer ;
begin
    fChangedFlag := false ;
    if fBlackFile = '' then exit ;  // no file name means nothing to read
    if NOT Assigned (fBlackIdx) then exit ;  // sanity check
    FileLines := TStringList.Create ;
    FileRecord := TStringList.Create ;
    try
        try
            if NOT FileExists (fBlackFile) then
            begin
                doLogEvent (fListName + ': File Not Found: ' + fBlackFile) ;
                exit ;
            end ;
            FileLines.LoadFromFile (fBlackFile) ;
        except
            doLogEvent (fListName + ': Failed to File Load: ' + fBlackFile +
                                         ' - ' + IcsGetExceptMess (ExceptObject)) ;
            exit ;
        end ;
        ClearList ;
         if FileLines.Count > 0 then
        begin
            BadNr := 0 ;
            ResizeArray (FileLines.Count * 2) ;
            for I := 0 to Pred (FileLines.Count) do
            begin
                FileRecord.CommaText := FileLines [I] ;
                if FileRecord.Count >= 6 then
                begin
                    with fBlackRecs [fTotBlackRecs] do
                    begin
                        Ascii := FSaveAscii ;
                        if FSaveAscii then
                            Value := FileRecord [0]
                        else
                            Str2IP (FileRecord [0], Addr) ;
                        if ((Value <> '') or (Addr <> 0)) and (atoi64 (FileRecord [2]) > 0) and
                                                                    (atoi (FileRecord [4]) > 0) then
                        begin
                            if NOT fBlackIdx.Find (@fBlackRecs [fTotBlackRecs], CompareBlackRec, Index) then
                            begin
                                Str2IP (FileRecord [1], Mask) ;
                                FirstUtime := atoi64 (FileRecord [2]) ;
                                LastUtime := atoi64 (FileRecord [3]) ;
                                Attempts := atoi (FileRecord [4]) ;
                                ReasonId := atoi (FileRecord [5]) ;
                                fBlackIdx.AddSorted (@fBlackRecs [fTotBlackRecs],
                                                                     CompareBlackRec) ;
                                inc (fTotBlackRecs) ;
                            end
                            else
                            begin
                                 Addr := 0 ;
                                 Value := '' ;
                                 doLogEvent (fListName + ': Ignored old saved duplicate') ;
                                 inc (BadNr) ;
                            end;
                        end
                        else
                            inc (BadNr) ;
                    end ;
                end
                else
                    inc (BadNr) ;
            end ;
            doLogEvent (fListName + ': Loaded from File: ' + fBlackFile +
                               ', Total Items ' + IntToStr (fTotBlackRecs) +
                                            ', Bad Records ' + IntToStr (BadNr)) ;
            fChangedFlag := false ;
            CleanList;
            if fChangedFlag then FlushToFiles ;
        end
        else
            doLogEvent (fListName + ': File Empty: ' + fBlackFile) ;

    finally
        FileLines.Free ;
        FileRecord.Free ;
        fChangedFlag := false ;
    end ;
end;

// timer called every 30 seconds to Clean and Flush lists

procedure TIcsBlacklist.OnTimer(Sender: TObject);
begin
    fTimer.Enabled := false ;
    try
        if IcsTestTrgTick64 (fCleanTrg) then
        begin
            fCleanTrg := IcsGetTrgMins64 (fCleanMins) ;
            CleanList ;
            if fChangedFlag then FlushToFiles ;
        end ;
        if IcsTestTrgTick64 (fFlushTrg) then
        begin
            fFlushTrg := IcsGetTrgMins64 (fFlushMins) ;
            if fChangedFlag then FlushToFiles ;
        end ;

    finally
        fTimer.Enabled := true ;
    end ;
end;

function TIcsBlacklist.ReportBlackList (All: boolean): string ;
var
    I: integer ;
begin
    result := '' ;
    if (fTotBlackRecs = 0) then exit ;
    for I := 0 to Pred (fBlackIdx.Count) do
    begin
        with PTBlackRec (fBlackIdx [I])^ do
        begin
            if (Attempts >= fBlockAttempts) or All then
            begin
                if Ascii then
                begin
                    if Value = '' then continue ;
                    result := result + Value ;
                end
                else
                begin
                    if Addr = 0 then continue ;
                    result := result + IpToStr (Addr) ;
                end;
                result := result + ' attempts ' + IcsIntToCStr (Attempts) +
                    ', first at ' + TimeToStr (UnixToDateTime (FirstUtime)) +
                          ', last at ' + TimeToStr (UnixToDateTime (LastUtime)) ;
                if Attempts >= fBlockAttempts then result := result + ' BLOCKED' ;
                result := result + IcsCRLF ;
            end;
        end;
    end;
end;

function TIcsBlacklist.GetCountAll: integer ;    // 18 July 2012
var
    I: integer ;
begin
    result := 0 ;
    if (fTotBlackRecs = 0) then exit ;
    for I := 0 to Pred (fBlackIdx.Count) do
    begin
        with PTBlackRec (fBlackIdx [I])^ do
        begin
           if (Attempts = 0) then continue ;
           inc (result) ;
        end;
    end;
end;

function TIcsBlacklist.GetCountBlock: integer ;   // 18 July 2012
var
    I: integer ;
begin
    result := 0 ;
    if (fTotBlackRecs = 0) then exit ;
    for I := 0 to Pred (fBlackIdx.Count) do
    begin
        with PTBlackRec (fBlackIdx [I])^ do
        begin
            if (Attempts = 0) then continue ;
            if (Attempts >= fBlockAttempts) then inc (result) ;
        end;
    end;
end;

// property setters

procedure TIcsBlacklist.SetCleanMins(Value: integer);
begin
    fCleanMins := Value ;
    if fCleanMins = 0 then fCleanMins := 2 ;
    fCleanTrg := IcsGetTrgMins64 (fCleanMins) ;
end;

procedure TIcsBlacklist.SetFlushMins(Value: integer);
begin
    fFlushMins := Value ;
    if fFlushMins = 0 then fFlushMins := 2 ;
    fFlushTrg := IcsGetTrgMins64 (fFlushMins) ;
end;

procedure TIcsBlacklist.SetBlackFile(Value: string);
begin
    if Value <> fBlackFile then
    begin
        fBlackFile := Value ;
        if fTotBlackRecs = 0 then LoadFromFiles;  // don't kill existing black list
    end ;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ IcsStringBuild Class  }
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TIcsStringBuild.Create (ABufferSize: integer = 4096; Wide: Boolean = False) ;
begin
    inherited Create;
    FIndex := 0;
    if Wide then
        FCharSize := 2
    else
        FCharSize := SizeOf(Char);
    Capacity(ABufferSize);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsStringBuild.Capacity(ABufferSize: integer);
begin
    if ABufferSize <= 1024 then ABufferSize := 1024;
    if ABufferSize < FBuffSize then exit;  // not smaller
    if ABufferSize <= FIndex then exit;    // sanity check
    FBuffSize := ABufferSize * FCharSize;
    FBuffMax := FBuffSize - 1;
    SetLength(FBuffer, FBuffSize);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsStringBuild.ExpandBuffer ;
begin
    FBuffSize := FBuffSize shl 1;
    Capacity(FBuffSize);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
destructor TIcsStringBuild.Destroy;
begin
    SetLength(FBuffer, 0);
    inherited Destroy;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsStringBuild.AppendBuf(const AString: AnsiString);
var
    Len: integer;
begin
    Len := length (AString);
    if ((Len + FIndex) >= FBuffMax) then begin
        Capacity(Len + FIndex + 32);
        ExpandBuffer ;
    end;
    Move(AString[1], FBuffer[FIndex], Len);
    Inc(FIndex, Len);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsStringBuild.AppendBufW(const AString: UnicodeString);
var
    Len : integer;
begin
    FCharSize := 2;
    Len := Length (AString) * FCharSize;
    if ((Len + FIndex) >= FBuffMax) then begin
        Capacity(Len + FIndex + 32);
        ExpandBuffer ;
    end;
    Move(AString[1], FBuffer[FIndex], Len);
    Inc(FIndex, Len);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsStringBuild.AppendBuf(const AString: UnicodeString);
begin
    AppendBufW(AString);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsStringBuild.AppendLine(const AString: AnsiString);
begin
    AppendBuf(AString);
    AppendBuf(IcsCRLF);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsStringBuild.AppendLine(const AString: UnicodeString);
begin
    AppendBuf(AString);
    AppendBuf(UnicodeString(IcsCRLF));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsStringBuild.AppendLineW(const AString: UnicodeString);
begin
    AppendBufW(AString);
    AppendBufW(UnicodeString(IcsCRLF));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TIcsStringBuild.GetAString: AnsiString;
begin
    if FCharSize <> SizeOf (Char) then begin
        Result := 'Need WideString Result';
        exit ;
    end;
    SetLength(Result, FIndex div FCharSize);
    Move(FBuffer[0], Result[1], FIndex);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TIcsStringBuild.GetWString: UnicodeString;
begin
    if FCharSize <> 2 then begin
        Result := 'Need AnsiString Result';
        exit ;
    end;
    SetLength(Result, FIndex div FCharSize);
    Move(FBuffer[0], Result[1], FIndex);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TIcsStringBuild.GetString: String;
begin
    if FCharSize = 2 then
        Result := String(GetWString)
    else
        Result := String(GetAString);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsStringBuild.Clear;
begin
    FIndex := 0;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ TIcsBuffLogStream }
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TIcsBuffLogStream.Create(Aowner: TComponent; const sNameMask, sHeader: String;
                                                      sFileCP: TFileCodePage = FileCPAnsi);
begin
    inherited Create(AOwner);
    FBuffMax := 1024*32;
    FBuffer := TIcsStringBuild.Create(FBuffMax);
    AllocateHWnd;
    FIdleTimer := TIcsTimer.Create (Self);
    FIdleTimer.Enabled := false;
    FIdleTimer.OnTimer := OnTimer;
    FIdleSecs := 30;
    FLogSize := -1;
    FOpenAttempts := 20;
    FOpenDelayMs := 50;
    FIdleTimer.Interval := Longword (FIdleSecs) * TicksPerSecond;
    SetNameMask(sNameMask);
    FHeader := sHeader;
    SetFileCP(sFileCP);
end ;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
destructor TIcsBuffLogStream.Destroy;
begin
    try
        FlushFile(false);
    except
    end;
    if Assigned (FIdleTimer) then begin
        FIdleTimer.Enabled := false;
        FIdleTimer.Free;
    end ;
    if Assigned(FBuffer) then FBuffer.Free;
    inherited Destroy;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsBuffLogStream.OnTimer(Sender: TObject) ;
begin
    FIdleTimer.Enabled := false;
    try
        FlushFile(false);
    except
        // ignore error, buffer will grow if needed
    end ;
end ;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsBuffLogStream.SetNameMask(sNameMask: String);
begin
    if sNameMask = '' then Exit;
    if Pos('"', sNameMask) = 0 then  // expecting name mask, if none create it
        FNameMask := '"' + sNameMask + '"'
    else
        FNameMask := sNameMask;

 // get initial full unmasked file name, repeated before every file flush
    FFullName := FormatDateTime(FNameMask, Now) ;
end ;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsBuffLogStream.SetFileCP(sFileCP: TFileCodePage);
begin
    FFileCP := sFileCP;
{$IFNDEF UNICODE}  { don't allow full Unicode on old compilers }
    if FFileCP = FileCPUtf16 then FFileCP := FileCPUtf8;
{$ENDIF}
    case FFileCP of
        FileCPAnsi: FBuffer.FCharSize := 1;
        FileCPUtf8: FBuffer.FCharSize := 1;
        FileCPUtf16: FBuffer.FCharSize := 2;
    end;
end ;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsBuffLogStream.SetIdleSecs (IdleSecs: Integer);
begin
    FIdleSecs := IdleSecs;
    FIdleTimer.Interval := Longword (FIdleSecs) * TicksPerSecond;
    if FIdleTimer.Enabled then
    begin
        FIdleTimer.Enabled := false;
        FIdleTimer.Enabled := true;
    end ;
end ;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ opens log file, writes buffer, closes again }
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TIcsBuffLogStream.FlushFile(OldFName: Boolean = False): Integer;
var
    HdrLine: String;
    Utf8Line: RawByteString;
    LineLen: Integer;
    LogHandle, Attempts: Integer;
    TickCount: Longword;
    Bom : TBytes;
begin
    Result := 0 ;
    FIdleTimer.Enabled := false;
    if FBuffer.Len = 0 then exit;
    if FNameMask = '' then exit ;
    LogHandle := -1 ;

    try // finally

     // generally create new log file name with current time and date
     // but perhaps not at midnight and want stuff in yesterday's log
        if (NOT OldFName) or (FFullName = '') then
            FFullName := FormatDateTime (FNameMask, Now) ;

      // open log file, lots of attempts, probably, beware blocks application
        for Attempts := 1 to FOpenAttempts do begin
            if FileExists(FFullName) then begin
                LogHandle := FileOpen(FFullName, fmOpenReadWrite OR fmShareDenyWrite);
                if LogHandle >= 0 then begin
                    Result := FileSeek(LogHandle, 0, soFromEnd);  // end of file
                    if Result < 0 then exit;
                end;
            end;
            if (LogHandle < 0) and (NOT (FileExists(FFullName))) then begin
                ForceDirectories(ExtractFileDir(FFullName));
                LogHandle := FileCreate(FFullName);
                if LogHandle >= 0 then begin

                  // unicode files like a BOM at the beginning
                    SetLength(bom, 0);
                    if FFileCP = FileCPUtf8 then
                        Bom := GetBomFromCodePage(CP_UTF8)
                    else if FFileCP = FileCPUtf16 then
                        Bom := GetBomFromCodePage(CP_UTF16);
                    if Length(Bom) > 0 then begin
                        FileWrite (LogHandle, Bom[0], Length(Bom));
                    end;

                  // see if writing header to top of log file
                    if (Pos ('"', FHeader) > 0) and (Pos ('","', FHeader) = 0) then
                        HdrLine := FormatDateTime(FHeader, Now)  // warning max 255 characters may be formatted
                    else
                        HdrLine := FHeader;
                    LineLen := Length(HdrLine);
                    if LineLen > 0 then begin
                        HdrLine := HdrLine + IcsCRLF;
                        LineLen := LineLen + 2;
                        if FFileCP = FileCPAnsi then
                            Utf8Line := AnsiString(HdrLine)    // may lose Unicode chars
                        else if FFileCP = FileCPUtf8 then begin
                            Utf8Line := StringToUtf8(HdrLine);
                            LineLen := Length(Utf8Line);
                        end
                        else if FFileCP = FileCPUtf16 then
                            LineLen := LineLen * 2;
                        if FFileCP <> FileCPUtf16 then
                            FileWrite(LogHandle, PAnsiChar(Utf8Line)^, LineLen)
                        else
                            FileWrite(LogHandle, PChar(HdrLine)^, LineLen);
                    end;
                end ;
            end ;
            if LogHandle >= 0 then break ;  // finished OK

         // failed to open file, wait a few milliseconds and try again
            TickCount := GetTickCount ;
            while ((GetTickCount - TickCount) < FOpenDelayMs) do  // 50ms delay
                ProcessMessages;
        end ;

     // did not open file, fatal error raise exception
        if LogHandle < 0 then begin
            HdrLine := SysErrorMessage(GetLastError) + ' [' +
                                    IcsIntToCStr(GetLastError) + '] ' + fullname ;
            raise EFOpenError.CreateResFmt(@SFBuffOpenError, [HdrLine]);
            exit ;
        end ;

    // write buffered text, clear buffer
        Result := FileWrite(LogHandle, Pointer (FBuffer.Buffer)^, FBuffer.Len) ;
        FLogSize := FileSeek(LogHandle, 0, soFromEnd) ;  // end of file
        FBuffer.Clear;
    finally
        if LogHandle >= 0 then FileClose(LogHandle) ;
    end ;
end ;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// return exception, unless error flushing, might work next time
// write Line adding CRLF optionally
function TIcsBuffLogStream.WriteLine(const Line: String; AddCRLF: Boolean = True): Integer;
var
    Utf8Line: RawByteString;
    LineLen: Integer;
begin
    Result := 0;
    LineLen := Length(Line);
    if FFileCP = FileCPAnsi then
        Utf8Line := AnsiString(Line)    // may lose Unicode chars
    else if FFileCP = FileCPUtf8 then begin
        Utf8Line := StringToUtf8(Line);
        LineLen := Length(Utf8Line);
    end
    else if FFileCP = FileCPUtf16 then
        LineLen := LineLen * 2;

   // add CRLF
    if AddCRLF and (FFileCP <> FileCPUtf16) then begin
        Utf8Line := Utf8Line + IcsCRLF;
    end;

  // see if room in buffer for new line
    if ((FBuffer.Len + LineLen + 16) >= FBuffMax) then begin
        try
            Result := FlushFile(false);
        except
            // ignore error, buffer will grow if needed
        end ;
    end ;
    if FFileCP <> FileCPUtf16 then
        FBuffer.AppendBuf(Utf8Line)
    else begin
        FBuffer.AppendBuf(Line);
        FBuffer.AppendBuf(WideString(IcsCRLF));
    end;

// buffer now full, flush it
    if (FBuffer.Len >= FBuffMax) then begin
        try
            Result := FlushFile(false);
        except
            // ignore error, buffer will grow if needed
        end ;
    end

// idle timeout flush, don't reset in case of low volume writes
    else begin
        if NOT FIdleTimer.Enabled then
            FIdleTimer.Enabled := true;
    end;
end ;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ V8.60 simple log file update, write text to end of old or new file, opening
  and closing file, ignores any errors, not designed for continual updating!
  The file name is date/time mask format, typically for one log file per day,
  avoid time unless you wants lots of files each day.
  Example FNameMask: "mylog-"yyyymmdd".log" or "c:\temp\mylog-"yyyymmdd".log"
  note any non-mask characters are quoted so path needed quote at start.
  If no drive or path is specified, writes to the program directory. }
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure IcsSimpleLogging (const FNameMask, Msg: String);
var
    LogFileName, S: String;
    F: TextFile;
begin
    S := FormatDateTime (ISOTimeMask, Time) + ' ' + Msg;
    try
        LogFileName := FormatDateTime (FNameMask, Date) ;
        if (Pos ('//', LogFileName) <> 1) and (Pos (':', LogFileName) <> 2) then
            LogFileName := IncludeTrailingPathDelimiter (ExtractFileDir (ParamStr (0))) + LogFileName ;
        AssignFile (F, LogFileName);
        if FileExists (LogFileName) then begin
            Append (F);
        end
        else begin
            Rewrite (F);
        end;
        Writeln (F, S);
        CloseFile(F);
    except
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

end.
