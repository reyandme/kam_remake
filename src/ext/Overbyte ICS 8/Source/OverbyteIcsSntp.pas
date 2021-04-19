{*_* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Author:       Angus Robertson, Magenta Systems Ltd
Description:  TIcsTimeServer and TIcsTimeClient, time server and client,
              supporting time protocol with UDP and TCP portions of RFC868,
              and SNTP v4 (Simple Network Time Protocol) to RFC2030.
              Note current SNTP is RFC4330 but not looked at it.
              Note that full NTP is not supported.
Creation:     Aug 2002
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


TIcsTimeClient was originally written by Chris Barber, Lucas Controls, Inc
but has been extensively improved with SNTP support added.

7 Mar 1999 -   UDP time now works (wsocket will not send empty string)
               Supporting SNTP protocol
               New Protocol property, which determines what to do (time/tcp, time/upd, sntp)
               Added some helper routines for UTC time,
12 Oct 1999  - turn off range checking to avoid error in ConvTimeStamp
25 Sept 2001 - SNTP to host without time server seems to return year 2036,
               assume that's an error
24 July 2002 - support SNTP fractional seconds and round trip time
               corrected bug in ConvTimeStamp that caused two second error for SNTP
               added public vars DTRoundtrip, MSecsRoundtrip, DTDifference,
                   SecsDifference and SecsDiffDisp
               added functions DateTimeZZtoStr, GetUTCNtpTime, Ntp2TDateTime,
                    TimeToFSecs, GetNewTime, ChangeSystemTime
30 Nov 2005 - Register to FPiette not Internet
6 Nov 2006  - renamed unit for ICS V6, reworked to avoid needing WsocketExt
27 Oct 2008 - adapted for D2009, removed DayTime long dead
              ServerAddr must be set, instead of Addr (which will be set with numeric IP)
              use DnsLookup and loop through alternate IP addresses (for pool.ntp.org)
27 Mar 2011 - stop exception if no event allocated
12 Mar 2019 - V8.60 - Adapted for main ICS packages and FMX support.
              Renamed from TWSTimeClient to TIcsTimeClient
              Total rewrite of 20 year old component, using wsoIcsDnsLookup, no
                longer exposing all TWSocket properties, report failure to start.
              Built in failure timeout for no response.
              If multiple DNS addresses for host, try alternates on failure.


Pending - Roughtime a new secure time protocol designed by Google. also s
upported by Cloudfare.  



TIcsTimeServer was originally written by Nathan Anderson but has been extensively
improved with SNTP support added.

7 Mar 2001   - Replaced htonl with ByteSwaps since it went to hyper space
               Using UTC time to avoid messing with timezones
               UDP server does not seem to respond....
26 Jul 2002 -  Added SNTP time server, fairly minimal
               Trigger when UTP completes OK
               Added public SrcIPAddr to make available during end trigger
3 Nov 2006  - Renamed unit for ICS V6
11 Jan 2008 - Use FreeAndNil to avoid crash if not started, check sockets assigned
              fell over with exceptions if all three servers did not start together
27 Oct 2008 - Added Addr property to restrict on which IPs server listens
              adapted for D2009
27 Jan 2019 - V8.60 - Adapted for main ICS packages and FMX support.
                      Renamed from TTimeServ to TIcsTimeServer.
                      Major clean up of 20 year old component, servers all
                       start/stop together and give exception on failure to start.


Windows mostly used the W32Time service to keep the PC clock up to date, it
includes an NTP server on UDP port 123 that is mostly enabled on servers but
disabled on client PCs, this will stop this time server starting.  So this
time client main use is checking Windows is keeping time correctly by checking
alternate NTP time servers.

There is a test application OverbyteIcsTimeTst.dpr.

NTP time servers, most return four alternate IP addresses.
The pool servers change their IP addresses at least hourly, selected from a
pool of amoslty a few hundred time servers.  Google offers IPV6 addresses,
ntp.org only IPv4. 

time.google.com
pool.ntp.org
0.pool.ntp.org
1.pool.ntp.org
2.pool.ntp.org
3.pool.ntp.org
europe.pool.ntp.org
uk.pool.ntp.org
north-america.pool.ntp.org
south-america.pool.ntp.org
africa.pool.ntp.org
asia.pool.ntp.org
oceania.pool.ntp.org


 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{$IFNDEF ICS_INCLUDE_MODE}
unit OverbyteIcsSntp;
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
    OverbyteIcsWinsock,
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
    Ics.Fmx.OverbyteIcsWSocket,
{$ELSE}
    OverbyteIcsWndControl,
    OverbyteIcsWSocket,
{$ENDIF FMX}
    OverbyteIcsUtils;


const
    CopyRight    : String     = ' OverbyteIcsSntp (c) 2019 V8.60 ';

type
    TTimeProtocol = (tpSNTP, tpTCP, tpUDP, tpRoughTime);
    TTimeProtoSet = set of TTimeProtocol;

    TTimeQuery = procedure (Sender: TObject; SocketAddr : TSockAddrIn;
                        TimeProtocol : TTimeProtocol;
                        var Continue : Boolean) of object;
    TTimeQueryDone = procedure (Sender: TObject; Error : Word) of object;

    TIcsTimeServer = class(TComponent)
    public
        SrcIPAddr  : TSockAddrIn ;
        constructor Create(AOwner: TComponent); override;
        destructor  Destroy; override;
        procedure   Start;
        procedure   Stop;
    protected
        FAddrStr            : String;
        FWUDPSocket         : TWSocket;
        FWTCPSocket         : TWSocket;
        FWSNTPSocket        : TWSocket;
        FClientSocket       : TWSocket;
        FOnSessionConnected : TSessionConnected;
        FOnSessionClosed    : TSessionClosed;
        FOnQuery            : TTimeQuery;
        FOnQueryDone        : TTimeQueryDone;
        FTimeProtocol       : TTimeProtoSet;
        FRunning            : Boolean;
        FOnStart            : TNotifyEvent;
        FOnStop             : TNotifyEvent;
        procedure WUDPSocketSessionConnected(Sender: TObject; Error: Word);
        procedure WUDPSocketDataAvailable(Sender: TObject; Error: Word);
        procedure WUDPSocketSessionClosed(Sender: TObject; Error: Word);
        procedure WSNTPSocketSessionConnected(Sender: TObject; Error: Word);
        procedure WSNTPSocketDataAvailable(Sender: TObject; Error: Word);
        procedure WSNTPSocketSessionClosed(Sender: TObject; Error: Word);
        procedure ClientOnDataSent(Sender: TObject; Error: word);
        procedure TriggerQueryDone(Error: Word);
        procedure TriggerServerStart;
        procedure TriggerServerStop;
        procedure WTCPSocketSessionAvailable(Sender: TObject; Error: Word);
        procedure CreateUDPSocket;
        procedure CreateSNTPSocket;
        procedure CreateTCPSocket;
        procedure StartTCPServer;
        procedure StartUDPServer;
        procedure StartSNTPServer;
    published
        property Addr : String                          read  FAddrStr
                                                        write FAddrStr;
        property TimeProtocol : TTimeProtoSet           read  FTimeProtocol
                                                        write FTimeProtocol;
        property OnStop : TNotifyEvent                  read  FOnStop
                                                        write FOnStop;
        property OnStart : TNotifyEvent                 read  FOnStart
                                                        write FOnStart;
        property OnSessionConnected : TSessionConnected read  FOnSessionConnected
                                                        write FOnSessionConnected;
        property OnSessionClosed : TSessionClosed       read  FOnSessionClosed
                                                        write FOnSessionClosed;
        property OnQueryDone : TTimeQueryDone           read  FOnQueryDone
                                                        write FOnQueryDone;
        property OnQuery : TTimeQuery                   read  FOnQuery
                                                        write FOnQuery;
        property IsRunning : Boolean                    read  FRunning;
    end;

  TTimeEvent = procedure(Sender:TObject; DateTime:TDateTime) of object;
//  TDayTimeEvent = procedure(Sender:TObject; DateTime:string) of object;
  TTimeInfoEvent = procedure(Sender:TObject; Info: String) of object;

  TNtpTime = packed record
    Seconds: DWORD ;    // seconds since 1st January 1900
    FracSecs: DWORD ;   // fraction of second
  end;

  SNTPheader = packed record
    LIvnMmode:      byte ;       // 01=leap indicator, 234=version (3), 567=mode (3=client)
    Statum:         byte ;       // 0=unspecified, 1=primary, >2 secondary
    Poll:           byte ;       // 4 (16 secs), 5 (32 secs), 6 (64 secs), etc
    Precision:      shortint ;   // -6 mains freq clocks, to -20 microsecond accuracy
    RootDelay:      integer ;    // delay to primary source
    RootDispersion: integer ;    // error relative to primary source
    RefIdent:       DWORD ;      //  array [0..3] of char ;  // LOCL, PSS, OMEG, GEOS, GPS, etc
    RefTimeStamp:   TNtpTime ;  // time local clock was set/corrected
    OrigTimeStamp:  TNtpTime ;  // time request left client
    RecvTimeStamp:  TNtpTime ;  // time request arrived at server
    XmitTimeStamp:  TNtpTime ;  // time request left server
  end ;

  TIcsTimeClient = class(TComponent)
  private
    { Private declarations }
    FWSocket: TWSocket;
    FServerAddr: String;
    FSocketFamily: TSocketFamily;
    FTimeoutSecs: Integer;
    FOnTime: TTimeEvent;
    FOnTimeInfo: TTimeInfoEvent;
    FTimeProtocol: TTimeProtocol;
    FTimeoutTimer: TIcsTimer;
    FCurrDnsResult: Integer ;
    FTotDnsResult: Integer;
    FAttempts: Integer;
    FLastAddrOK: String;
    FLastProgress: String;
  protected
    { Protected declarations }
    procedure WSocketSessionConnected(Sender: TObject; Error: Word);
    procedure TimeDataAvailable(Sender: TObject; Error: Word) ;
    procedure DnsLookupDone (Sender: TObject; ErrCode: Word);
    procedure TimeoutTimerTimer(Sender: TObject);
    procedure DoProgress(const S: String);
    function  StartTime: Boolean;
  public
    { Public declarations }
    SNTP: SNTPheader ;
    DTRequest: TDateTime ;
    DTOriginate: TDateTime ;
    DTReceive: TDateTime ;
    DTTransmit: TDateTime ;
    DTDestination: TDateTime ;
    DTRoundtrip: TDateTime ;
    MSecsRoundtrip: integer ;
    DTDifference: TDateTime ;
    SecsDifference: Double ;
    SecsDiffDisp: string ;
    Tag2: integer ;
    ServLI: integer ;
    ServVN: integer ;
    ServMode: integer ;
    constructor Create(AComponent:TComponent);override;
    destructor Destroy;override;
    function GetTime: Boolean;
    function GetIpAddr: string;
    procedure Abort;
    property IpAddress: String                  read GetIpAddr;
    property Attempts: Integer                  read FAttempts;
    property LastProgress: String               read FLastProgress;
  published
    { Published declarations }
    property ServerAddr: String                 read  FServerAddr
                                                write FServerAddr;
    property SocketFamily: TSocketFamily        read  FSocketFamily
                                                write FSocketFamily;
    property TimeProtocol: TTimeProtocol        read  FTimeProtocol
                                                write FTimeProtocol;
    property TimeoutSecs: Integer               read  FTimeoutSecs
                                                write FTimeoutSecs;
    property OnTime: TTimeEvent                 read  FOnTime
                                                write FOnTime;
    property OnTimeInfo: TTimeInfoEvent         read  FOnTimeInfo
                                                write FOnTimeInfo;
  end;

  function IcsDateTimeZZtoStr (DT: TDateTime): string ;
  function IcsGetUTCNtpTime: TNtpTime;
  function IcsConvTimeStamp (timestamp: LongWord): TDateTime ;
  function IcsNtp2TDateTime (NtpTime: TNtpTime): TDateTime ;
  function IcsTimeToFSecs (DT: TDateTime): double ;   // returns seconds with fractions


implementation


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// convert date/time to ISO string with milliseconds - yyyy-mm-dd"T"hh:nn:ss.zzz
function IcsDateTimeZZtoStr (DT: TDateTime): string ;
begin
    Result := FormatDateTime(ISODateLongTimeMask, DT);
end ;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// get system date and time as UTC/GMT into NTP Time
function IcsGetUTCNtpTime: TNtpTime;
var
    SystemTime: TSystemTime;
begin
    GetSystemTime(SystemTime);
    with SystemTime do begin
        Result.Seconds := Round ((EncodeTime (wHour, wMinute, wSecond, 0) +
                               EncodeDate (wYear, wMonth, wDay) - 2) * SecsPerDay) ;
        Result.FracSecs := Round ($FFFFFFFF * (wMilliseconds / 1000)) ;
    end ;
    Result.Seconds := IcsSwap32(Result.Seconds);
    Result.FracSecs := IcsSwap32(Result.FracSecs);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function IcsTimeToFSecs (DT: TDateTime): double ;   // returns seconds to 3dp
begin
    try
        Result := (MSecsPerday * Frac (DT)) / 1000 ;      // time
        Result := Result + (Trunc (DT) * SecsPerDay) ;    // date
    except
        Result := 0 ;
    end ;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// convert timestamp into Delphi date and time
// 32-bit wrap at 6h 28m 16s UTC on 7 February 2036.
// after that time assumed to be after 1968 when hi-bit was set
function IcsConvTimeStamp (Timestamp: LongWord): TDateTime ;
begin
    Result := 0 ;
    if timestamp = 0 then exit ;
    try
        Result := (Timestamp / SecsPerDay) + 2.0 ;  // correct for 30 Dec 1899 to 1 Jan 1900
    except
        Result := 0 ;
    end ;
end ;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function IcsNtp2TDateTime (NtpTime: TNtpTime): TDateTime ;
begin
    NtpTime.Seconds := IcsSwap32(NtpTime.Seconds);
    NtpTime.FracSecs := IcsSwap32(NtpTime.FracSecs);
    result := IcsConvTimeStamp (NtpTime.Seconds) +
                            ((NtpTime.FracSecs / $FFFFFFFF) / SecsPerDay) ;
end ;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ TIcsTimeServer }
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TIcsTimeServer.Create(AOwner: TComponent);
begin
    inherited Create(AOwner);
    FAddrStr := '0.0.0.0';
    FTimeProtocol := [tpUDP,tpTCP,tpSNTP];
    FRunning := FALSE;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
destructor TIcsTimeServer.Destroy;
begin
    FreeAndNil (FWUDPSocket);
    FreeAndNil (FWTCPSocket);
    FreeAndNil (FClientSocket);
    FreeAndNil (FWSNTPSocket);

    inherited Destroy;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsTimeServer.Start;
begin
    if FRunning then
         exit;      {If at least one server is running, then don't start again}

    if tpSNTP in FTimeProtocol then begin
        CreateSNTPSocket;
        StartSNTPServer;
    end;

    if tpUDP in FTimeProtocol then begin
        CreateUDPSocket;
        StartUDPServer;
    end;

    if tpTCP in FTimeProtocol then begin
        CreateTCPSocket;
        StartTCPServer;
   end;
    FRunning := TRUE;
    TriggerServerStart;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsTimeServer.CreateTCPSocket;
begin
   if not Assigned(FWTCPSocket) then begin
      try
         FWTCPSocket                    := TWSocket.Create(Self);
         FClientSocket                  := TWSocket.Create(Self);
         FWTCPSocket.OnSessionConnected := WUDPSocketSessionConnected;
         FWTCPSocket.OnSessionAvailable := WTCPSocketSessionAvailable;
         FClientSocket.OnDataSent       := ClientOnDataSent;
      except
         FreeAndNil (FWTCPSocket);
         FreeAndNil (FClientSocket);
      end;
   end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsTimeServer.CreateUDPSocket;
begin
   if not Assigned(FWUDPSocket) then begin
      try
         FWUDPSocket                    := TWSocket.Create(Self);
         FWUDPSocket.OnSessionConnected := WUDPSocketSessionConnected;
         FWUDPSocket.OnSessionClosed    := WUDPSocketSessionClosed;
         FWUDPSocket.OnDataAvailable    := WUDPSocketDataAvailable;
      except
         FreeAndNil (FWUDPSocket);
      end;
   end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsTimeServer.CreateSNTPSocket;
begin
   if not Assigned(FWSNTPSocket) then begin
      try
         FWSNTPSocket                    := TWSocket.Create(Self);
         FWSNTPSocket.OnSessionConnected := WSNTPSocketSessionConnected;
         FWSNTPSocket.OnSessionClosed    := WSNTPSocketSessionClosed;
         FWSNTPSocket.OnDataAvailable    := WSNTPSocketDataAvailable;
      except
         FreeAndNil (FWSNTPSocket);
      end;
   end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsTimeServer.StartTCPServer;
begin
   FWTCPSocket.Proto := 'tcp';
   FWTCPSocket.Addr  := FAddrStr;
   FWTCPSocket.Port  := 'time';
   FWTCPSocket.Listen;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsTimeServer.StartUDPServer;
begin
   FWUDPSocket.Proto := 'udp';
   FWUDPSocket.Addr  := FAddrStr;
   FWUDPSocket.Port  := 'time';
   FWUDPSocket.Listen;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsTimeServer.StartSNTPServer;
begin
   FWSNTPSocket.Proto := 'udp';
   FWSNTPSocket.Addr  := FAddrStr;
   FWSNTPSocket.Port  := 'ntp';
   FWSNTPSocket.Listen;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsTimeServer.Stop;
begin
   if FRunning then begin
      if Assigned (FWUDPSocket) then FWUDPSocket.Close;  // 11 Jan 2008 sanity checks
      if Assigned (FWTCPSocket) then FWTCPSocket.Close;
      if Assigned (FClientSocket) then FClientSocket.Close;
      if Assigned (FWSNTPSocket) then FWSNTPSocket.Close;
      TriggerServerStop;
      FRunning := FALSE;
   end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsTimeServer.WUDPSocketSessionConnected(Sender: TObject; Error: Word);
begin
    if Assigned(FOnSessionConnected) then
        FOnSessionConnected(Self, Error);

    if Error <> 0 then begin
        TriggerQueryDone(Error);
        FWUDPSocket.Close;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsTimeServer.WUDPSocketDataAvailable(Sender: TObject; Error: Word);
var
    Buffer : array [0..1023] of AnsiChar;
    Src    : TSockAddrIn;
    SrcLen : Integer;
    NewTime  : LongWord;
    Continue : Boolean;
begin
    SrcLen := SizeOf(Src);
    FWUDPSocket.ReceiveFrom(@Buffer, SizeOf(Buffer), Src, SrcLen);
    SrcIPAddr := Src ;
    Continue := TRUE;
    if Assigned(FOnQuery) then begin
       FOnQuery(Self, Src, tpUDP, Continue);
    end;

    if Continue then begin
        NewTime := Trunc ((IcsGetUTCTime - 2) * SecsPerDay) ;  // convert to NTP time
        NewTime := IcsSwap32(NewTime);
        if FWUDPSocket.Sendto (Src, SrcLen, @NewTime, SizeOf(NewTime)) =
                    SOCKET_ERROR then TriggerQueryDone(FWUDPSocket.LastError);
        TriggerQueryDone(0);
    end
    else begin
        TriggerQueryDone($FFFF);
          {According to RFC 868, don't reply if we don't know what time it is}
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsTimeServer.WTCPSocketSessionAvailable(Sender: TObject; Error: Word);
var
    NewHSocket : TSocket;
    NewTime   : longword;
    Src    : TSockAddrIn;
    Continue : Boolean;
begin
    NewHSocket := FWTCPSocket.Accept;
    FClientSocket.Dup(NewHSocket);
    FClientSocket.GetPeerName(Src, SizeOf(Src));
    SrcIPAddr := Src ;
    Continue := TRUE;
    if Assigned(FOnQuery) then begin
        FOnQuery(Self, Src, tpTCP, Continue);
    end;

    if Continue then  begin
        NewTime := Trunc ((IcsGetUTCTime - 2) * SecsPerDay) ;  // convert to NTP time
        NewTime := IcsSwap32(NewTime);
        if FClientSocket.Send (@NewTime, SizeOf(NewTime)) = SOCKET_ERROR then
                                 TriggerQueryDone(FClientSocket.LastError) ;
    end
    else
    begin
        TriggerQueryDone($FFFF);
        {According to RFC 868, don't reply if we don't know what time it is}
        FClientSocket.Shutdown(2);
        FClientSocket.Close;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsTimeServer.WSNTPSocketSessionConnected(Sender: TObject; Error: Word);
begin
    if Assigned(FOnSessionConnected) then
        FOnSessionConnected(Self, Error);

    if Error <> 0 then begin
        TriggerQueryDone(Error);
        FWSNTPSocket.Close;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsTimeServer.WSNTPSocketDataAvailable(Sender: TObject; Error: Word);
var
    Buffer : array [0..1023] of AnsiChar;
    Src    : TSockAddrIn;
    SrcLen : Integer;
    Continue : Boolean;
    SNTP   : SNTPheader ;
    ServVN: integer ;
    ServMode: integer ;
begin
    SrcLen := SizeOf(Src);
    FillChar (Buffer, SizeOf (Buffer), #0);
    FWSNTPSocket.ReceiveFrom(@Buffer, SizeOf(Buffer), Src, SrcLen);
    SrcIPAddr := Src ;
    Continue := FALSE;

// check we got an SNTP request
    Move (Buffer [0], SNTP, SizeOf (SNTP)) ;
    SNTP.RecvTimeStamp := IcsGetUTCNtpTime ;

    ServVN := (SNTP.LIvnMmode and $38) shr 3 ;  // version (most seem to be 6)
    ServMode := SNTP.LIvnMmode and $07 ;        // 3=client, 4=server, 5=broadcast

// ensure that we found an SNTP server meeting RFC 2030
    if (ServMode = 3) or (ServVN <= 3) then Continue := TRUE;

    if Continue then begin
        if Assigned(FOnQuery) then
        begin
            FOnQuery(Self, Src, tpSNTP, Continue);
        end;
    end ;

    if Continue then begin
        SNTP.XmitTimeStamp := IcsGetUTCNtpTime ;
        SNTP.LIvnMmode := $1C ;  // version 3, mode 4 server
        SNTP.Statum := 2 ; // secondary
        SNTP.Poll := 0 ;
        SNTP.Precision := -28 ;  // poor
        SNTP.RootDispersion := 0 ;
        SNTP.RootDelay := 0 ;
        SNTP.RefIdent := 0 ;
        if FWSNTPSocket.Sendto (Src, SrcLen, @SNTP, SizeOf(SNTP)) =
                    SOCKET_ERROR then TriggerQueryDone(FWSNTPSocket.LastError);
        TriggerQueryDone(0);
    end
    else begin
        TriggerQueryDone($FFFF);
          {According to RFC 868, don't reply if we don't know what time it is}
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsTimeServer.TriggerQueryDone(Error: Word);
begin
    if Assigned(FOnQueryDone) then
       FOnQueryDone(Self, Error);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsTimeServer.WUDPSocketSessionClosed(Sender: TObject; Error: Word);
begin
    TriggerQueryDone(Error);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsTimeServer.WSNTPSocketSessionClosed(Sender: TObject; Error: Word);
begin
    TriggerQueryDone(Error);
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsTimeServer.ClientOnDataSent(Sender: TObject; Error: word);
begin
    {RFC says that the time server client will first close its
     connection and then the server will, but I think it's safer
     for this server to NOT wait for the client to close.}
    FClientSocket.Shutdown(2);
    FClientSocket.Close;
    TriggerQueryDone(Error);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsTimeServer.TriggerServerStart;
begin
   if Assigned(FOnStart) then
      FOnStart(Self);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsTimeServer.TriggerServerStop;
begin
   if Assigned(FOnStop) then
      FOnStop(Self);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ TIcsTimeClient }
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TIcsTimeClient.Create(AComponent:TComponent);
begin
    inherited;
    FOnTime := nil;
    FTimeoutSecs := 5;
    FWSocket := TWSocket.Create(Self);
    FWSocket.OnDataAvailable := TimeDataAvailable;
    FWSocket.OnSessionConnected := WSocketSessionConnected;
    FWSocket.OnDnsLookupDone := DnsLookupDone;
    FWSocket.ComponentOptions := FWSocket.ComponentOptions +
                                    [wsoAsyncDnsLookup, wsoIcsDnsLookup];
    FSocketFamily := sfIPv4;
    FTimeoutTimer := TIcsTimer.Create(FWSocket);
    FTimeoutTimer.Enabled := False;
    FTimeoutTimer.OnTimer := TimeoutTimerTimer;
    FTimeProtocol := tpSNTP;
    FServerAddr := 'time.google.com' ;
    FLastAddrOK := '';
    FCurrDnsResult := -1;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
destructor TIcsTimeClient.Destroy;
begin
    FreeAndNil(FTimeoutTimer) ;
    FreeAndNil(FWSocket) ;
    inherited;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsTimeClient.Abort;
begin
    FTimeoutTimer.Enabled := False;
    FWSocket.CancelDnsLookup;
    FWSocket.Abort;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsTimeClient.DoProgress(const S: String);
begin
    FLastProgress := S;
    if Assigned(FOnTimeInfo) then
        FOnTimeInfo(Self, S); 
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsTimeClient.DnsLookupDone (Sender: TObject; ErrCode: Word);
var
    I: Integer;
begin
  // DNS lookup may return multiple IP addreses
    FTotDnsResult := FWSocket.DnsResultList.Count;
    if (Error <> 0) or (FTotDnsResult = 0) then begin
        DoProgress('DNS Lookup Failed: ' + WSocketErrorMsgFromErrorCode(Error));
        if Assigned (FOnTime) then FOnTime(self, 0) ;  // error
        Exit ;
    end ;

    DoProgress('DNS Lookup Results: ' + FWSocket.DnsResultList.CommaText);

  // single DNS result, nothing more to do
    if (FTotDnsResult <= 1) then Exit;

  // if last succesaful IP address in list of results, use it again
    if (FLastAddrOK <> '') then begin
        for I := 0 to FTotDnsResult - 1 do begin
            if FLastAddrOK = FWSocket.DnsResultList[I] then begin
                FCurrDnsResult := I;
                FWSocket.DnsResult := FLastAddrOK;
                DoProgress('Reusing Last OK Address: ' + FLastAddrOK);
                Exit;
            end;
        end;
    end;

  // multiple results, find next, loop to start if gone past last
    inc (FCurrDnsResult);
    if (FCurrDnsResult >= FTotDnsResult) then FCurrDnsResult := 0;
    FWSocket.DnsResult := FWSocket.DnsResultList[FCurrDnsResult];
    DoProgress('Alternate Address: ' + FWSocket.DnsResult);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsTimeClient.TimeoutTimerTimer(Sender: TObject);
begin
    if FWSocket.State = wsDnsLookup then Exit;  // no timeout for DNS, can be slow 
    FTimeoutTimer.Enabled := False;
    if (FTotDnsResult > 1) and (Attempts <  FTotDnsResult) then begin
        FLastAddrOK := '';
        DoProgress('Timeout getting time, trying another address');
        StartTime;  // another attempt
    end
    else begin
        FLastAddrOK := '';
        DoProgress('Timeout getting time, failed');
        Abort;
        if Assigned (FOnTime) then FOnTime(self, 0);  // error
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TIcsTimeClient.GetTime: Boolean;
begin
    FAttempts := 0;
    FTotDnsResult := 0;
    FCurrDnsResult := - 1;
    FTimeoutTimer.Interval := LongWord(FTimeoutSecs) * TicksPerSecond;
    Result := StartTime;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TIcsTimeClient.StartTime: Boolean;
begin
    Result := False;
    FAttempts := FAttempts + 1;
    if FWSocket.State <> wsClosed then FWSocket.Abort;
    FLastProgress := '';
    DTRoundtrip := 0 ;
    MSecsRoundtrip := 0 ;
    DTDifference := 0 ;
    SecsDifference := 0 ;
    SecsDiffDisp := '' ;
    DTDestination := 0 ;
    DTTransmit := 0 ;
    DTOriginate := 0 ;
    DTReceive := 0 ;
    FillChar (SNTP, SizeOf (SNTP), #0);
    if FServerAddr = '' then begin
        DoProgress('No time server specified');
        if Assigned (FOnTime) then  FOnTime(self, 0);  // error
        exit ;
    end ;
    FWSocket.Addr := FServerAddr;
    FWSocket.SocketFamily := FSocketFamily;
    if FTimeProtocol = tpTCP then begin
        FWSocket.Proto := 'tcp' ;
        FWSocket.Port := 'time';
        DTRequest := IcsGetUTCTime ;    // in case OrigTime gets lost
        FWSocket.Connect;     // starts DNS lookup
        Result := True;
    end
    else if FTimeProtocol = tpUDP then begin
        FWSocket.Proto := 'udp' ;
        FWSocket.Port := 'time';
        DTRequest := IcsGetUTCTime ;    // in case OrigTime gets lost
        FWSocket.Connect;    // starts DNS lookup
        Result := True;
    end
    else if FTimeProtocol = tpSNTP then begin
        FWSocket.Proto := 'udp';
        FWSocket.Port := 'ntp';
        SNTP.LIvnMmode := $33 ; //  Li-0, version=3, mode=3 server
        DTRequest := IcsGetUTCTime ;    // in case OrigTime gets lost
        SNTP.OrigTimeStamp := IcsGetUTCNtpTime ;
        FWSocket.Connect;   // starts DNS lookup
        Result := True;
    end;
    FTimeoutTimer.Enabled := True;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TIcsTimeClient.GetIpAddr: string;
begin
    Result := FWSocket.AddrResolvedStr;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsTimeClient.WSocketSessionConnected(Sender: TObject; Error: Word);
begin
    if Error <> 0 then begin
        FLastAddrOK := '';
        FTimeoutTimer.Enabled := False;
        DoProgress('Connection failed: ' + WSocketErrorMsgFromErrorCode(Error));
        if Assigned (FOnTime) then FOnTime(self, 0);  // error
        FWSocket.CloseDelayed;
    end
    else begin
        if FTimeProtocol = tpTCP then
             FWSocket.SendStr(' ')
        else if FTimeProtocol = tpUDP then
             FWSocket.SendStr(' ')
        else if FTimeProtocol = tpSNTP then
            FWSocket.Send (@SNTP, SizeOf (SNTP)) ;
    end ;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsTimeClient.TimeDataAvailable(Sender: TObject; Error: Word) ;
var
    Buffer: array [0..64] of AnsiChar ;
    Count: integer ;
    TimeStamp: LongWord ;
begin
    FTimeoutTimer.Enabled := False;
    if Error <> 0 then begin
        FLastAddrOK := '';
        DoProgress('Date read failed: ' + WSocketErrorMsgFromErrorCode(Error));
        FWSocket.CloseDelayed ;
        if Assigned (FOnTime) then FOnTime(self, 0) ;  // error
        exit ;
    end ;

// read data, only expecting a few bytes so assume come in a single call
    FLastAddrOK := GetIpAddr;
    Count := FWSocket.Receive (@Buffer [0], SizeOf (Buffer)) ;

    DTDestination := IcsGetUTCTime ;   // when time was received here
    if ((FTimeProtocol = tpTCP) or (FTimeProtocol = tpUDP)) and
                                Assigned (FOnTime) and (Count >= 4) then begin
        Move (Buffer, TimeStamp, 4) ;
        TimeStamp := IcsSwap32(TimeStamp);
        DTTransmit := IcsConvTimeStamp (TimeStamp) ;
        DTReceive := DTTransmit ;
        DTOriginate := DTRequest ;

     // calculate round trip time and correction needed, in various formats
        DTRoundtrip := (DTDestination - DTOriginate) ;
        MsecsRoundtrip := Trunc (IcsTimeToFSecs (DTRoundtrip) * 1000) ;
        DTDifference := ((DTTransmit - DTOriginate) + (DTTransmit - DTDestination)) / 2;
        SecsDifference := IcsTimeToFSecs (DTDifference) ;
        SecsDiffDisp := Format ('%.3f', [SecsDifference]) ;

      // tell user what happened
        FOnTime (self, DTTransmit) ;
        FWSocket.CloseDelayed ;
    end
    else if (FTimeProtocol = tpSNTP) and (Count >= SizeOf (SNTP)) then begin

    // get record for easier handling
        FillChar (SNTP, SizeOf (SNTP), #0);
        if Count > SizeOf (SNTP) then Count := SizeOf (SNTP) ;
        Move (Buffer, SNTP, Count) ;
        ServLI := (SNTP.LIvnMmode and $C0) shr 6 ;  // leap indicator
        ServVN := (SNTP.LIvnMmode and $38) shr 3 ;  // version (most seem to 6)
        ServMode := SNTP.LIvnMmode and $07 ;        // 3=client, 4=server, 5=broadcast

     // ensure that we found an SNTP server meeting RFC 2030
        if (ServMode <> 4) or (SNTP.Statum = 0) or
                 (SNTP.Statum > 15) or (SNTP.XmitTimeStamp.Seconds = 0) then begin
            FWSocket.CloseDelayed ;  // UDP does not really close
            FLastAddrOK := '';
            DoProgress('Invalid SNTP Responsed'); 
            if Assigned (FOnTime) then FOnTime(self, 0) ;  // error
        end ;

     // convert NTP time stamps into Delphi dates
        DTTransmit := IcsNtp2TDateTime (SNTP.XmitTimeStamp) ;
        DTOriginate := IcsNtp2TDateTime (SNTP.OrigTimeStamp) ;
        if DTOriginate = 0 then DTOriginate := DTRequest ;  // may come back as zero
        DTReceive := IcsNtp2TDateTime (SNTP.RecvTimeStamp) ;

     // calculate round trip time and correction needed, in various formats
        DTRoundtrip := (DTDestination - DTOriginate) - (DTReceive - DTTransmit);
        MsecsRoundtrip := Trunc (IcsTimeToFSecs (DTRoundtrip) * 1000) ;
        DTDifference := ((DTReceive - DTOriginate) + (DTTransmit - DTDestination)) / 2;
        SecsDifference := IcsTimeToFSecs (DTDifference) ;
        SecsDiffDisp := Format ('%.3f', [SecsDifference]) ;

      // tell user what happened
        if Assigned (FOnTime) then FOnTime (self, DTTransmit) ;
        FWSocket.CloseDelayed ;
    end ;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

end.
