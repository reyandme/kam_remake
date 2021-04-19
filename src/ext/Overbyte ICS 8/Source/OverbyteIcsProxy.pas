{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Author:       Angus Robertson, Magenta Systems Ltd
Description:  Forward and Reverse SSL HTTP Proxy
Creation:     May 2017
Updated:      Apr 2020
Version:      8.64
Sponsor:      This component was sponsored in part by Avenir Health and
              Banxia Software Ltd. http://www.avenirhealth.org
EMail:        francois.piette@overbyte.be  http://www.overbyte.be
Support:      https://en.delphipraxis.net/forum/37-ics-internet-component-suite/
Legal issues: Copyright (C) 1997-2020 by François PIETTE
              Rue de Grady 24, 4053 Embourg, Belgium.

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


Overview
--------

TIcsProxy is protocol agnostic and may be used to proxy any TCP protocol,
the sample includes SMTP, POP3, NNTP and telnet. It may be used to allow
non-SSL news readers to access forums.embarcadero.com or other similar old
applications and protocols.

TIcsHttpProxy is a full forward and reverse HTTP/HTTPS proxy with header
and body parsing and processing host names and URLs to match the source and
destination. Could potentially be used as a caching proxy, but needs more
events.  Can be used to monitor HTTP connections.  Reverse proxy targets
may be selected according to partial paths, or using an event for more
complex selection such as load sharing to multiple targets.  Or it can
be used to add SSL support to non-SSL servers.  The HTTP proxy will
uncompress received pages and/or compress pages returned by the proxy.

These components require USE_SSL to be set, there is no non-SSL version,
but SSL is optional for source and targets.  The components support multiple
sources and targets, with multiple ports and IP addresses.  To an extent,
data may be intercepted and changed by the proxy, provided the protocols
are not broken.  SSL server name identification is supported so multiple
hosts can share the same server address and port.

A forward proxy generally runs on a client or gateway server, and browsers
are configured to redirect all traffic to the proxy, which forwards it to
the remote target in the URL, typically logging or examining that target
and perhaps rejecting it.  The browser may specify authentication login
and password, which the proxy sends to the onHttpPxyAuth event.  For
non-SSL traffic, the proxy processes requests and responses which may be
checked and manipulated if necessary.  But the browser will send SSL
traffic using the CONNECT method which opens a direct connection to the
remote server and the proxy behaves as a transparent tunnel passing
encrypted data back and forward, so requests and responses can not be
seen.

A reverse proxy generally runs in front of the remote web server, perhaps to
provide SSL access to a non-SSL server, for load sharing between multiple
servers, or to direct different URLs to different servers.  Potentially,
the proxy can cache static pages, but this is not implemented yet.

Proxy configuration is based on a concept of multiple sources and targets:

Source - TSslWSocketServer listening for incoming source connections, part
   of TIcsProxy, defined as a collection of IcsHosts.  Each source can listen
   on two different IP addresses BindIpAddr and BindIpAddr2 (perhaps IPv4
   and IPv6) each with non-SSL BindNonPort and/or SSL BindSslPort.  Multiple
   source clients can connect to each listening socket.  Each source needs
   a unique HostTag alphabetic name, and one or more HostNames that match
   DNS and SSL certificate names.  Each source should define Proto as HTTP
   or other, and ForwardProxy as true if that behaviour is required otherwise
   reverse proxy is assumed.  If SSL is used, an SSL certificate must also
   be specified that matches the HostNames, see below.  Note IcsHosts is
   part of TSslWSocketServer and is used for other server components such
   as the web server.

Target - TSslWSocket that connects to a remote target destination,   Part
   of TProxyClient, at least one for each source client (unless ForwardProxy
   is defined), defined as a collection of ProxyTargets, each with a HostTag
   alphabetic name that must match a source in the IcsHosts collection, but
   for HTTP the request path may be examined and there may be multiple
   ProxyTargets.  Each target specifies TarHost, TarPort and TarSsl as the
   remote target.  If the target is SSL, the remote SSL certificate chain may
   be validated and reported according to the TCertVerMethod setting.  The
   OnSetTarget event is called immediately before each remote target connection
   is started and may be used for logging or TarHost, TarPort and TarSsl may be
   changed to alter the target for this connection only.  If TarPort is zero,
   the source port and SSL method are copied for the target.

See OverbyteIcsWSocketS.pas for documentation on TSslWSocketServer whose
properties are exposed by TSslWSocketServer and for IcsHosts which is each
Source. including automatic SSL certificate ordering.

Once source and target are connected, traffic from source is sent to target,
and vice versa.  The proxy receives data in a temporary TBytes buffer of size
RxBuffSize (default 64K).  For HTTP, entire request and response headers are
saved into a String for ease of processing and each line parsed into
THttpProxyClient RequestXX and ResponseXX properties.   The event handlers
onHttpReqHdr and onHttpRespHdr allow the complete headers to be logged or
changed, with care because changes may break the proxy or protocol.

If the target specifies UpdateHttp, the proxy may modify the Location, Host
and Referrer headers from and to the source and target host names, ports
and http/https, so the HTTP protocol works correctly.

If UpdateHtml is specified, textual body content also has absolute URLs
modified similarly, with the header page length modified if the content
length changes.  To modify bodies, the proxy needs to read the entire body
first which has required local memory and also delays response to the
source that might cause a timeout, so body size is restricted by the
HttpMaxBody setting, defaulting to 10MB, the assumption being larger
textual bodies will not contain absolute server links.  If the
onHttpRespBody event is set, it will be called with the body, but note
only for textual bodies smaller than HttpMaxBody.

To support SSL sources, the SslCert property should ideally be set the
SSL certificate bundle file name in PEM, PFX or P12 format that also
includes the private key and any intermediate certificates required.
But SslCert also accepts a bundle as Base64 encoded ASCII.  SslPassword
should be set to the private key password, if required.   If SslCert only
specifies a PEM, DER or PK7 certificate, SslKey and SslInter may be used
to specify the private key and intermediate bundle file names (or ASCII
versions).  SslSrvSecurity sets TSslSrvSecurity which may stop low security
protocols or certificates being used.

There is an ICS sample application OverbyteIcsProxySslServer that illustrates
the use of TIcsHttpProxy.  It reads all it's settings from an INI file, using
three functions in the main ICS components, IcsLoadIcsHostsFromIni in
OverbyteIcsWSocketS.pas, and IcsLoadProxyTargetsFromIni and
IcsLoadTIcsHttpProxyFromIni in this proxy unit.  The sample INI file is
OverbyteIcsProxySslServer.ini with several source and target sections.
So the application just needs to open an INI file and these three functions
will read all necessary settings.  This is all optional, the application
could keep settings in XML or the registry and set-up the proxy collection
properties directly. nut using the same INI settings will ease adding future
functionality to the proxy with minimal application changes.





Updates:
28 May 2017  - 8.48 - baseline
6 July 2017  - 8.49 - Changed target behaviour for host listening on both 80 and
                        443 so source port copied only if target is zero.
                      Start no longer gives exception if some binding fail, but
                        opens as many source listeners as possible.
                      Various logging improvements to make things clearer.
                      Added host redirection and .well-known directory support.
                      If the source specifies WellKnownPath as a path, any
                        access to /.well-known/xx is handled locally by the
                        proxy either in an event or by returning a local file,
                        this is primarily for Let's Encrypt challenges but
                        will be used for a status web page, real soon.
                      If the source specifies WebRedirectStat as a response status
                        codes like 301, immediate redirection is made to WebRedirectURL
                        which is an absolute URL.
                      Proxy generates an error 502 page if target connection fails
                        or is not configured, maybe other pages would be useful?
                      Moved TBytes functions to OverbyteIcsUtils
                      Look for target path with all requests, not just common ones
4  Oct 2017  - 8.50 - Check document meta for charset
                      Convert html TByte buffers to unicode instead of ANSI
                      Post data now calls onHttpReqBody event
                      Don't try and access Windows cert store on MacOS, etc
Jul 2, 2018  V8.55 - Builds with NO_DEBUG_LOG
Oct 2, 2018  V8.57 - Added OnSslAlpnSelect called after OnSslServerName for HTTP/2
                     INI file reads CertVerTar, DebugLevel and TarSecLevel to be
                       read as typed literals as well as numeric values.
                     Added SslCliCertMethod to allow server to request a client
                       SSL certificate from the browser, NOTE you should check it
                       the OnSslHandshakeDone event and close the connection if
                       invalid, beware this usually causes the browser to request
                       a certificate which can be obtrusive.
                     Allow SSL certificates to be ordered and installed automatically
                       by RecheckSslCerts if SslCertAutoOrder=True and so specified in
                       IcsHosts, if a TSslX509Certs component is attached and a
                       certificate supplier account has been created (by the
                       OverbyteIcsX509CertsTst sample application).
                    Note certificate ordering currently only works with Proto=HTTP.
                    INI file reads SslCliCertMethod, SslCertAutoOrder and CertExpireDays.
                    Support FMX
Oct 19, 2018  V8.58 version only
Nov 19, 2018  V8.59 Sanity checks reading mistyped enumerated values from INI file.
Dec 04, 2018  V8.59 Added AUTO_X509_CERTS define set in OverbyteIcsDefs.inc which
                      can be disabled to remove a lot of units if automatic SSL/TLS
                      ordering is not required, saves up to 1 meg of code.
27 Apr 2020 - V8.64 Added SSL certificate ordering ChallFileApp and ChallAlpnApp
                      challenges, as well as ChallFileUNC.



pending...
Test Transfer-Encoding: gzip, chunked
Proxy statistics
}

{$IFNDEF ICS_INCLUDE_MODE}
unit OverbyteIcsProxy;
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

{$IFDEF USE_SSL}

uses
{$IFDEF MSWINDOWS}
    {$IFDEF RTL_NAMESPACES}Winapi.Messages{$ELSE}Messages{$ENDIF},
    {$IFDEF RTL_NAMESPACES}Winapi.Windows{$ELSE}Windows{$ENDIF},
    {$IFDEF RTL_NAMESPACES}System.TypInfo{$ELSE}TypInfo{$ENDIF},
    {$IFDEF RTL_NAMESPACES}System.IniFiles{$ELSE}IniFiles{$ENDIF},
{$ENDIF}
{$IFDEF POSIX}
    Posix.Time,
    Ics.Posix.WinTypes,
    Ics.Posix.Messages,
{$ENDIF}
    {$Ifdef Rtl_Namespaces}System.Classes{$Else}Classes{$Endif},
    {$Ifdef Rtl_Namespaces}System.Sysutils{$Else}Sysutils{$Endif},
    {$IFDEF Rtl_Namespaces}System.StrUtils{$ELSE}StrUtils{$ENDIF},
    OverbyteIcsSsleay, OverbyteIcsLibeay,
    {$I Include\OverbyteIcsZlib.inc}
    OverbyteIcsZlibHigh,
    {$IFDEF USE_ZLIB_OBJ}
        OverbyteIcsZLibObj,     {interface to access ZLIB C OBJ files}
    {$ELSE}
        OverbyteIcsZLibDll,     {interface to access zLib1.dll}
    {$ENDIF}
    OverbyteIcsLogger,
{$IFDEF FMX}
    Ics.Fmx.OverbyteIcsWndControl,
    Ics.Fmx.OverbyteIcsWSocket,
    Ics.Fmx.OverbyteIcsWSocketS,
    Ics.Fmx.OverbyteIcsSslSessionCache,
    Ics.Fmx.OverbyteIcsMsSslUtils,     { V8.57 }
{$IFDEF AUTO_X509_CERTS}  { V8.59 }
    Ics.Fmx.OverbyteIcsSslX509Certs,   { V8.57 }
{$ENDIF} // AUTO_X509_CERTS
{$ELSE}
    OverbyteIcsWndControl,
    OverbyteIcsWSocket,
    OverbyteIcsWSocketS,
    OverbyteIcsSslSessionCache,
    OverbyteIcsMsSslUtils,      { V8.57 }
{$IFDEF AUTO_X509_CERTS}  { V8.59 }
    OverbyteIcsSslX509Certs,    { V8.57 }
{$ENDIF} // AUTO_X509_CERTS
{$ENDIF FMX}
{$IFDEF MSWINDOWS}
    OverbyteIcsWinCrypt,
{$ENDIF MSWINDOWS}
    OverbyteIcsTypes,
    OverbyteIcsMimeUtils,
    OverbyteIcsFormDataDecoder,
    OverbyteIcsCharsetUtils,   { V8.50 }
    OverbyteIcsURL,
    OverbyteIcsUtils;

{ NOTE - these components only build with SSL, there is no non-SSL option }

const
    THttpServerVersion = 864;
    CopyRight : String = ' TIcsHttpProxy (c) 2020 F. Piette V8.64 ';
    DefServerHeader : string = 'Server: ICS-Proxy-8.64';
    CompressMinSize = 5000;     // 5K minimum to make it worth compressing a page
    CompressMaxSize = 5000000;  // 5M bigger takes too long
    DefRxBuffSize = 65536;
    DefMaxBodySize = 1000000;  // 10M general maximum length of body to buffer and process
    MaxBodyDumpSize = 200000;  // 200K maximum length of body to log
    Ssl_Session_ID_Context = 'IcsProxy';
    MaxPipelineReqs = 10;
    cLF = #10;
    cFF = #12;
    cCR = #13;
    cCRLF: PChar = cCR+cLF;
    cCRLF_ = cCR+cLF;
    cDoubleCRLF = cCR+cLF+cCR+cLF;
    FlushSslCacheMins = 120;  // how often to clear SSL domain cache
    WellKnownDir = '/.well-known/';
    { see http://www.iana.org/assignments/well-known-uris/well-known-uris.xhtml }

type
{ forware declarations }
  TIcsProxy = class;
  TIcsHttpProxy = class;
  TProxyClient = Class;
  THttpProxyClient = Class;

{ event handlers }
  TProxyProgEvent  = procedure (Sender: TObject; LogOption: TLogOption; const Msg: string) of object;
  TProxyDataEvent  = procedure (Sender: TObject; ProxyClient: TProxyClient; DataPtr: Pointer; var DataLen: Integer) of object;
  TProxyTarEvent   = procedure (Sender: TObject; ProxyClient: TProxyClient) of object;
  TProxyHttpEvent  = procedure (Sender: TObject; ProxyClient: THttpProxyClient; var Arg: String) of object;

{ property and state types }
  TPxyTarState     = (PxyClosed, PxyHdrFind, PxyLenEnd, PxyCnkEnd, PxyGetBody, PxyNoBody, PxySendBody);
  TPxyChunkState   = (PxyChunkGetSize, PxyChunkGetExt, PxyChunkGetData, PxyChunkSkipDataEnd, PxyChunkDone);
  TCertVerMethod   = (CertVerNone, CertVerBundle, CertVerWinStore);
  TDebugLevel      = (DebugNone, DebugConn, DebugSsl, DebugHttpHdr, DebugHttpBody, DebugChunks, DebugAll);
  THttpReqMethod   = (httpMethodNone, httpMethodGet, httpMethodPost, httpMethodHead, httpMethodOptions,
                      httpMethodPut, httpMethodDelete, httpMethodTrace, httpMethodPatch, httpMethodConnect);
  THttpReqState   =  (httpStNone, httpStReqStart, httpStReqHdrWait, httpStWaitResp, httpStRespStart,
                      httpStRespHdrWait, httpStRespBody, httpStRespSend, httpStRespDone);


{ used for pipelining, all information about one request for when we process the response }
{ we may receive two or three requests together, then all the responses }
  THttpInfo = record
    HttpReqState: THttpReqState;                     // HTTP State, doing request and response
    HttpReqMethod: THttpReqMethod;                   // HTTP request type only
    ReqContentLen: Integer;                          // expected request content length according to header
    ReqStartLine: String;                            // request method, path and version
    ReqAcceptEnc: String;                            // request accept-encoding
    TickReqStart: LongWord;                          // when request started
    TickReqSend: LongWord;                           // when request was forwarded
    TickWaitResp: LongWord;                          // when request finished. wait response
    TickRespStart: LongWord;                         // when response started
    TickRespBody: LongWord;                          // when response body started
    TickRespSend: LongWord;                          // when response forwarding started
    TickRespDone: LongWord;                          // when response forwarding finished
    TickRespEnd: LongWord;                           // when response all forwarded
  end;


  { TProxyTarget defines the reverse proxy target, or act as forward proxy }

  TProxyTarget = class(TCollectionItem)
  private
    FHostTag: String;
    FHostEnabled: Boolean;
    FDescr: String;
    FSrcPath: String;
    FTarHost: String;
    FTarPort: Integer;
    FTarSsl: Boolean;
    FIdleTimeout: Integer;
    FUpdateHttp: Boolean;
    FUpdateHtml: Boolean;
  protected
    function GetDisplayName: string; override;
  published
    constructor Create (Collection: TCollection); Override ;
    property HostTag: String                     read  FHostTag
                                                 write FHostTag;
    property HostEnabled : boolean               read  FHostEnabled
                                                 write FHostEnabled;
    property Descr : String                      read  FDescr
                                                 write FDescr;
    property SrcPath: String                     read  FSrcPath
                                                 write FSrcPath;
    property TarHost : String                    read  FTarHost
                                                 write FTarHost;
    property TarPort : Integer                   read  FTarPort
                                                 write FTarPort;
    property TarSsl : Boolean                    read  FTarSsl
                                                 write FTarSsl;
    property IdleTimeout: Integer                read  FIdleTimeout
                                                 write FIdleTimeout;
    property UpdateHttp : Boolean                read  FUpdateHttp
                                                 write FUpdateHttp;
    property UpdateHtml : Boolean                read  FUpdateHtml
                                                 write FUpdateHtml;
  end;


  { TProxyTargets defines a collection of TProxyTarget }

  TProxyTargets = class(TCollection)
  private
    FOwner: TPersistent;
    function GetItem(Index: Integer): TProxyTarget;
    procedure SetItem(Index: Integer; Value: TProxyTarget);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(Owner: TPersistent);
    property Items[Index: Integer]: TProxyTarget read GetItem write SetItem; default;
  end;

  { socket server client, one instance for each proxy remote target session }

  TProxyClient = class(TSslWSocketClient)
  private
    FProxySource: TIcsProxy;        // pointer back to our server
    FSrcHost: String;               // source host, same as SslServerName for SSL
    FTarSocket: TSslWSocket;        // remote target socket
    FTarHost: String;               // remote IP address or host
    FTarIP: String;                 // remote IP address looked-up
    FTarPort: String;               // remote IP port
    FTarSsl: Boolean;               // is remote SSL
    FTarHttp: Boolean;              // are we processing HTTP requests and responses
    FTarCurHost: String;            // last host to which we connected, checking if changed
    FSrcBuffer: TBytes;             // temporary source data waiting to be sent to target
    FSrcBufMax: Integer;            // maximum size of SrcBuffer
    FSrcWaitTot: Integer;           // current data in of SrcBuffer
    FTarBuffer: TBytes;             // temporary target data waiting to be sent to server
    FTarBufMax: Integer;            // maximum size of TarBuffer
    FTarWaitTot: integer;           // current data in of TarBuffer
    FClosingFlag: Boolean;          // local client about to close
    FTunnelling: Boolean;           // tunnelling data without processing it (probably using SSL)
    FForwardPrxy: Boolean;          // HTTP forward proxy
    FTarConditional: Boolean;       // target is conditional upon path or something
    FPxyTargetIdx: Integer;         // which ProxyTarget are we using
    FDelayedDisconn: Boolean;       // do we need to send stuff before disconnecting
    FIdleTimeout: Integer;          // close an idle connection after x seconds, if non-zero
    FLogDescr: String;              // source description and clientId for logging
    FSrcPendClose: Boolean;         // close local client once all data forwarded
    FTarClosedFlag: Boolean;        // target has closed, must send any pending data to source
  protected
    procedure SourceDataAvailable(Sender: TObject; Error: Word);
    procedure SourceSessionClosed(Sender: TObject; Error: Word); Virtual;
//    procedure TargetDnsLookupDone(Sender: TObject; Error: Word);
    procedure TargetSessionConnected(Sender: TObject; Error: Word); Virtual;
    procedure TargetSessionClosed(Sender: TObject; Error: Word); Virtual;
    procedure TargetVerifyPeer(Sender: TObject; var Ok : Integer; Cert: TX509Base);
    procedure TargetHandshakeDone(Sender: TObject; ErrCode: Word;
                                    PeerCert: TX509Base; var Disconnect : Boolean);
    procedure TargetDataAvailable(Sender: TObject; Error: Word);
    procedure TargetCliNewSession(Sender: TObject; SslSession: Pointer;
                                            WasReused: Boolean; var IncRefCount : Boolean);
    procedure TargetCliGetSession(Sender: TObject;
                        var SslSession: Pointer; var FreeSession : Boolean);
    procedure SourceDataSent(Sender: TObject; ErrCode : Word); Virtual;
    procedure TargetDataSent(Sender: TObject; ErrCode : Word); Virtual;
  public
    constructor Create(Owner: TComponent); override;
    destructor  Destroy; override;
    procedure SourceBufRecv; Virtual;
    procedure SourceXferData; Virtual;
    procedure SourceBufXmit(SendNr: Integer); Virtual;
    procedure TargetInitialiase; Virtual;
    procedure TargetCheck; Virtual;
    procedure TargetSpecify; Virtual;
    function  TargetConnect: Boolean;
    procedure TargetBufRecv; Virtual;
    procedure TargetXferData; Virtual;
    procedure TargetBufXmit(SendNr: Integer); Virtual;
    procedure LogEvent(const Msg: String);
    procedure LogTarEvent(const Msg: String);
    procedure LogSrcEvent(const Msg: String);
    property  TarHost: String                  read  FTarHost
                                               write FTarHost;
    property  TarPort: String                  read  FTarPort
                                               write FTarPort;
    property  TarSsl: Boolean                  read  FTarSsl
                                               write FTarSsl;
    property  SrcHost: String                  read  FSrcHost;
    property  Tunnelling: Boolean              read  FTunnelling;
    property  TarConditional: Boolean          read  FTarConditional;
    property  PxyTargetIdx: Integer            read  FPxyTargetIdx;
  end;

{ TIcsProxy - forwards TCP/IP streams from source (server) to target (client) and back again, without
  examening any of the streams }

  TIcsProxy = class(TIcsWndControl)
  private
     { Private declarations }
    FSourceServer: TSslWSocketServer;
    FProxyTargets: TProxyTargets;
    FSslSessCache: TSslAvlSessionCache;
    FTarSslCtx: TSslContext;
    FTarSslCertList: TStringList;
{$IFDEF MSWINDOWS}
    FMsCertChainEngine: TMsCertChainEngine;   { V8.50 }
{$ENDIF}
    FRxBuffSize: Integer;
    FMaxClients: Integer;
    FServerHeader: String;
    FSocketErrs : TSocketErrs;
    FExclusiveAddr: Boolean;
    FLocalAddr: String;
    FCertVerTar: TCertVerMethod;
    FTarSecLevel: TSslSecLevel;
    FSslRevocation: Boolean;
    FSslReportChain: Boolean;
    FDebugLevel: TDebugLevel;
    FonProxyProg: TProxyProgEvent;
    FOnSetTarget: TProxyTarEvent;
    FOnDataSendTar: TProxyDataEvent;
    FOnDataRecvTar: TProxyDataEvent;
    FMsg_TARGET_CONNECTED: longword;
    FCleanupTimer: TIcsTimer;
    FTimerBusyFlag: Boolean;
    FCurDate: Integer;
    FFlushTick: LongWord;
    FOnSrcConnect: TWSocketClientConnectEvent;    // when source client connects
    FOnSrcDisconnect: TWSocketClientConnectEvent; // when source client disconnects
    FOnTarConnect: TWSocketClientConnectEvent;    // when remote target connects
    FOnTarDisconnect: TWSocketClientConnectEvent; // when remote target disconnects
    FOnSslAlpnSelect: TSslAlpnSelect;             { V8.57 }
    function  GetIcsHosts: TIcsHostCollection;
    procedure SetIcsHosts(const Value: TIcsHostCollection);
    function  GetRootCA: String;
    procedure SetRootCA(const Value: String);
    function  GetDHParams: String;
    procedure SetDHParams(const Value: String);
    procedure SetProxyTargets(const Value: TProxyTargets);
    function  GetRunning: Boolean;
    function  GetClientCount: Integer;
{$IFDEF AUTO_X509_CERTS}  { V8.59 }
    function  GetSslX509Certs: TSslX509Certs;                     { V8.57 }
    procedure SetSslX509Certs(const Value : TSslX509Certs);       { V8.57 }
{$ENDIF} // AUTO_X509_CERTS
    function  GetSslCliCertMethod: TSslCliCertMethod;             { V8.57 }
    procedure SetSslCliCertMethod(const Value : TSslCliCertMethod); { V8.57 }
    function  GetCertExpireDays: Integer;                         { V8.57 }
    procedure SetCertExpireDays(const Value : Integer);           { V8.57 }
    function  GetSslCertAutoOrder: Boolean;                       { V8.57 }
    procedure SetSslCertAutoOrder(const Value : Boolean);         { V8.57 }
  protected
   { Protected declarations }
    procedure IcsLogEvent (Sender: TObject; LogOption: TLogOption;
                                                      const Msg : String);
    procedure LogProgEvent (const Msg : String);
    procedure LogErrEvent (const Msg : String);
    procedure SocketBgException(Sender: TObject;
                          E: Exception; var CanClose: Boolean);
    procedure ServerClientCreate(Sender : TObject; Client : TWSocketClient);
    procedure ServerClientConnect(Sender: TObject;
                                  Client: TWSocketClient; Error: Word);
    procedure ServerClientDisconnect(Sender: TObject;
                                 Client: TWSocketClient; Error: Word);
    procedure ServerSetSessionIDContext(Sender : TObject;
                                    var SessionIDContext : TSslSessionIdContext);
    procedure ServerSvrNewSession(Sender: TObject; SslSession, SessId: Pointer;
                                            Idlen: Integer; var AddToInternalCache: Boolean);
    procedure ServerSvrGetSession(Sender: TObject; var SslSession: Pointer; SessId: Pointer;
                                                        Idlen: Integer; var IncRefCount: Boolean);
    procedure ServerVerifyPeer(Sender: TObject; var Ok : Integer; Cert: TX509Base);
    procedure ServerHandshakeDone(Sender: TObject; ErrCode: Word;
                                PeerCert: TX509Base; var Disconnect : Boolean);
    procedure ServerServerName(Sender: TObject;
                          var Ctx: TSslContext; var ErrCode: TTlsExtError);
    procedure ServerAlpnSelect(Sender: TObject;
        ProtoList: TStrings; var SelProto : String; var ErrCode: TTlsExtError);  { V8.57 }
    procedure WndProc(var MsgRec: TMessage); override;
    procedure WMTargetConnected(var msg: TMessage);
    function  MsgHandlersCount: Integer; override;
    procedure AllocateMsgHandlers; override;
    procedure FreeMsgHandlers; override;
    procedure CleanupTimerOnTimer (Sender : TObject);

  public
    FIcsLog : TIcsLogger;
      { Public declarations }
    constructor Create(Owner:TComponent); override;
    destructor Destroy; override;
    function  FindPxyTarget(const Tag: String): Integer;
    function  FindPxySourceHost(const HHostName: String; MLIndx: Integer): Integer;
    function  ValidateHosts(Stop1stErr: Boolean=True;
                                           NoExceptions: Boolean=False): String;
    function  RecheckSslCerts(var CertsInfo: String;
                  Stop1stErr: Boolean=True; NoExceptions: Boolean=False): Boolean;
    procedure Start;
    procedure Stop;
    function  ListenAllOK: Boolean;
    function  ListenStates: String;
    property  Running: Boolean                      read  GetRunning;
    property  ClientCount: Integer                  read  GetClientCount;
    property  SourceServer: TSslWSocketServer       read  FSourceServer;
  published
      { Published declarations }
    property  IcsHosts : TIcsHostCollection         read  GetIcsHosts
                                                    write SetIcsHosts;
    property  ProxyTargets : TProxyTargets          read FProxyTargets
                                                    write SetProxyTargets;
    property  RxBuffSize: Integer                   read  FRxBuffSize
                                                    write FRxBuffSize;
    property  MaxClients : Integer                  read  FMaxClients
                                                    write FMaxClients;
    property  ServerHeader : String                 read  FServerHeader
                                                    write FServerHeader;
    property  SocketErrs : TSocketErrs              read  FSocketErrs
                                                    write FSocketErrs;
    property  LocalAddr: String                     read  FLocalAddr
                                                    write FLocalAddr;
    property  ExclusiveAddr : Boolean               read  FExclusiveAddr
                                                    write FExclusiveAddr;
    property  RootCA : String                       read  GetRootCA
                                                    write SetRootCA;
    property  DHParams : String                     read  GetDHParams
                                                    write SetDHParams;
    property  DebugLevel: TDebugLevel               read  FDebugLevel
                                                    write FDebugLevel;
    property  SslSessCache: TSslAvlSessionCache     read  FSslSessCache
                                                    write FSslSessCache;
    property  TarSecLevel: TSslSecLevel             read  FTarSecLevel
                                                    write FTarSecLevel;
    property  CertVerTar: TCertVerMethod            read  FCertVerTar
                                                    write FCertVerTar;
    property  SslRevocation: Boolean                read  FSslRevocation
                                                    write FSslRevocation;
    property  SslReportChain : boolean              read  FSslReportChain
                                                    write FSslReportChain;
    property  SslCliCertMethod: TSslCliCertMethod   read  GetSslCliCertMethod
                                                    write SetSslCliCertMethod; { V8.57 }
    property  SslCertAutoOrder: Boolean             read  GetSslCertAutoOrder
                                                    write SetSslCertAutoOrder; { V8.57 }
    property  CertExpireDays: Integer               read  GetCertExpireDays
                                                    write SetCertExpireDays; { V8.57 }
{$IFDEF AUTO_X509_CERTS}  { V8.59 }
    property  SslX509Certs: TSslX509Certs           read  GetSslX509Certs
                                                    write SetSslX509Certs; { V8.57 }
{$ENDIF} // AUTO_X509_CERTS
    property  onProxyProg: TProxyProgEvent          read  FonProxyProg
                                                    write FonProxyProg;
    property  OnSetTarget: TProxyTarEvent           read  FOnSetTarget
                                                    write FOnSetTarget;
    property  OnDataSendTar: TProxyDataEvent        read  FOnDataSendTar
                                                    write FOnDataSendTar;
    property  OnDataRecvTar: TProxyDataEvent        read  FOnDataRecvTar
                                                    write FOnDataRecvTar;
    property  OnBgException;
    property  OnSrcConnect: TWSocketClientConnectEvent
                                                    read  FOnSrcConnect
                                                    write FOnSrcConnect;
    property  OnSrcDisconnect: TWSocketClientConnectEvent
                                                    read  FOnSrcDisconnect
                                                    write FOnSrcDisconnect;
    property  OnTarConnect: TWSocketClientConnectEvent
                                                    read  FOnTarConnect
                                                    write FOnTarConnect;
    property  OnTarDisconnect: TWSocketClientConnectEvent
                                                    read  FOnTarDisconnect
                                                    write FOnTarDisconnect;
    property  OnSslAlpnSelect: TSslAlpnSelect       read  FOnSslAlpnSelect
                                                    write FOnSslAlpnSelect;     { V8.57 }
  end;

{ THtttpProxyClient - similar to TProxyClient, but processing HTTP/HTML }
  THttpProxyClient = class(TProxyClient)
  private
     { Private declarations }
    FPxyReqState: TPxyTarState;     // HTTP request state
    FPxyRespState: TPxyTarState;    // HTTP responsestate
    FPxyChunkState: TPxyChunkState; // HTTTP response chunked state
    FHttpInfo: array [0..MaxPipelineReqs] of THttpInfo;  // pipelined requests
    FHttpReqHdr: String;            // HTTP request header lines
    FHttpRespHdr: String;           // HTTP response header lines
    FHtmlReqBody: TBytes;           // HTTP POST content
    FHtmlReqBodyLen: Integer;       // HTTP length of post content in buffer
    FHtmlRespBody: TBytes;          // HTTP response body content
    FHtmlRespBodyLen: integer;      // HTTP length of response body in buffer, zero no body
    FHttpTotReqs: integer;          // count of request in this connection
    FHttpTotResps: integer;         // count of responses in this connection
    FHttpCurrReq: Integer;          // next HttpInfo for new request
    FHttpCurrResp: Integer;         // next HttpInfo for response
    FHttpWaiting: Integer;          // total outstanding responses
    FTarReqLenRemain: Int64;        // request content length not yet received
    FTarReqTooLarge: Boolean;       // don't try to process massive bodies
    FTarReqModified: Boolean;       // did we modify request header
    FTarRespLenRemain: Int64;       // request content length not yet received
    FTarRespTooLarge: Boolean;      // don't try to process massive bodies
    FTarRespModified: Boolean;      // did we modify response header
 // FChunkOff: Integer;             // current offset into buffer
    FChunkState: TPxyChunkState;    // chunk state
    FChunkRcvd: Integer;            // how much chunked data so far
    FChunkTot: Integer;             // how many chunks in page
    FChunkGzip: Boolean;            // is each separate chunk compressed?
    FLastReqPath: String;           // last path conditionally checked for target
    FReqKAFlag: Boolean;            // did local client send Connection: Keep-Alive or Close
    FReqKASecs: integer;            // keep-alive timeout for idle client connection
    FReqBinary: Boolean;            // request POST content is binary
    FRespBinary: Boolean;           // response body content is binary
    FRespGzip: Boolean;             // response is compressed
    FHttpSrcURL: String;            // HTTP source URL for seaching
    FHttpTarURL1: String;           // HTTP target URL for seachingm with port
    FHttpTarURL2: String;           // HTTP target URL for seaching without port
    FUpdateHttp: Boolean;           // from Targets
    FUpdateHtml: Boolean;           // from Targets
{ following are parsed from HTTP request header }
    FRequestMethod: THttpReqMethod;      // HTTP request header field
    FRequestVersion: String;             // HTTP request header field
    FRequestAccept: String;              // HTTP request header field
    FRequestAcceptEncoding: String;      // HTTP request header field
    FRequestConnection: String;          // HTTP request header field
    FRequestContentLength: Int64;       // HTTP request header field
    FRequestContentType: String;         // HTTP request header field
    FRequestCookies: String;             // HTTP request header field
    FRequestHost: String;                // HTTP request header field
    FRequestHostName: String;            // HTTP request header field
    FRequestHostPort: String;            // HTTP request header field
    FRequestIfModSince: TDateTime;       // HTTP request header field
    FRequestKeepAlive: String;           // HTTP request header field
    FRequestPath: String;                // HTTP request header field
    FRequestProxyAuthorization: String;  // HTTP request header field
    FRequestProxyConnection: String;     // HTTP request header field
    FRequestReferer: String;             // HTTP request header field
    FRequestStartLine: String;           // HTTP request start line
    FRequestUpgrade: String;             // HTTP request header field
    FRequestUserAgent: String;           // HTTP request header field
//    FRequestAcceptLanguage: String;    // HTTP request header field
//    FRequestAuth: String;              // HTTP request header field
{ following are parsed from HTTP response header }
    FRespStatusCode: integer;            // HTTP response header field
    FRespVersion: String;                // HTTP response header field
    FRespConnection: String;             // HTTP response header field
    FRespContentEncoding: String;        // HTTP response header field
    FRespContentLength: Int64;           // HTTP response header field
    FRespContentLenSet: Boolean;         // HTTP response header field
    FRespContentType: String;            // HTTP response header field
    FRespContent: String;                // HTTP response header field
    FRespCharset: String;                // HTTP response header field
    FRespCookies: String;                // HTTP response header field
    FRespKAFlag: Boolean;                // did local client send Connection: Keep-Alive or Close
    FRespKASecs: integer;                // keep-alive timeout for idle client connection
    FRespKeepAlive: String;              // HTTP response header field
    FRespLastModified: TDateTime;        // HTTP response header field
    FRespLocation: String;               // HTTP response header field
    FRespReasonPhase: String;            // HTTP response header field
    FRespStatusLine: String;             // HTTP response status line
    FRespTransferEncoding: String;       // HTTP response header field

  protected
      { Protected declarations }
    procedure SourceSessionClosed(Sender: TObject; Error: Word); override;
    procedure TargetSessionConnected(Sender: TObject; Error: Word); override;
    procedure TargetSessionClosed(Sender: TObject; Error: Word); override;
    procedure SourceDataSent(Sender: TObject; ErrCode : Word); override;
    procedure TargetDataSent(Sender: TObject; ErrCode : Word); override;
  public
      { Public declarations }
    constructor Create(Owner:TComponent); override;
    destructor Destroy; override;
    procedure TargetCheck; override;
    procedure TargetSpecify; override;
    function  RemoveHdrLine(const Hdr: String; var Headers: string): boolean;
    function  UpdateHdrLine(const Hdr, Arg: String; var Headers: string): boolean;
    procedure SourceHdrRespXmit;
    procedure TargetHdrReqXmit;
    procedure TargetBodyXmit;
    procedure SourceBodyBufXmit;
 //   procedure SourceBodyStrXmit;
    procedure TargetForwardProxy; Virtual;
    function  FindPxyPathTarget(const HTag, HPath: String): Integer; Virtual;
    procedure UpdatePostData; Virtual;    { V8.50 }
    procedure UpdateBody; Virtual;
    procedure CompressBody; Virtual;
    procedure DecompressBody; Virtual;
    procedure ParseReqHdr; Virtual;
    procedure ParseRespHdr; Virtual;
    procedure SourceXferData; override;
    procedure SourceCreatePage(const Status, ContentType, ExtraHdr, BodyStr: String); Virtual;
    procedure TargetXferData; override;
    procedure TargetWellKnown; Virtual;
    procedure TargetRedirection; Virtual;
    procedure TargetErrorResponse(const RespStatus, Msg: string); Virtual;
    property  RequestMethod : THttpReqMethod        read  FRequestMethod;
    property  RequestVersion: String                read  FRequestVersion;
    property  RequestAccept : String                read  FRequestAccept;
    property  RequestAcceptEncoding : String        read  FRequestAcceptEncoding;
    property  RequestConnection  : String           read  FRequestConnection;
    property  RequestContentLength : Int64          read  FRequestContentLength;
    property  RequestContentType : String           read  FRequestContentType;
    property  RequestCookies : String               read  FRequestCookies;
    property  RequestHost : String                  read  FRequestHost
                                                    write FRequestHost;
    property  RequestHostName : String              read  FRequestHostName;
    property  RequestHostPort : String              read  FRequestHostPort;
    property  RequestIfModSince : TDateTime         read  FRequestIfModSince;
    property  RequestKeepAlive: String              read  FRequestKeepAlive;
    property  RequestPath: String                   read  FRequestPath
                                                    write FRequestPath;
    property  RequestProxyAuthorization : String    read  FRequestProxyAuthorization;
    property  RequestProxyConnection: String        read  FRequestProxyConnection;
    property  RequestReferer : String               read  FRequestReferer;
    property  RequestStartLine: String              read  FRequestStartLine;
    property  RequestUpgrade : string               read  FRequestUpgrade;
    property  RequestUserAgent : String             read  FRequestUserAgent;
    property  RespStatusCode: integer               read  FRespStatusCode;
    property  RespVersion: String                   read  FRespVersion;
    property  RespConnection: String                read  FRespConnection;
    property  RespContentEncoding: String           read  FRespContentEncoding;
    property  RespContentLength: Int64              read  FRespContentLength;
    property  RespContentType: String               read  FRespContentType;
    property  RespContent: String                   read  FRespContent;
    property  RespCharset: String                   read  FRespCharset;
    property  RespCookies: String                   read  FRespCookies;
    property  RespKeepAlive: String                 read  FRespKeepAlive;
    property  RespLastModified: TDateTime           read  FRespLastModified;
    property  RespLocation: String                  read  FRespLocation;
    property  RespReasonPhase: String               read  FRespReasonPhase;
    property  RespStatusLine: String                read  FRespStatusLine;
    property  RespTransferEncoding: String          read  FRespTransferEncoding;
  published
      { Published declarations }
  end;

{ TIcsHtttpProxy - forwards HTTP requests from source (server) to target (client) and responses back again,
  modifying the HTTP headers and HTML body if necessary to change host names and ports, and other headers,
  uncompessing and compressing body content if required }

  TIcsHttpProxy = class(TIcsProxy)
  private
     { Private declarations }
    FHttpIgnoreClose: Boolean;          // HTTP force keep-alive
    FHttpSrcCompress: Boolean;          // HTTP Gzip source responses
    FHttpTarCompress: Boolean;          // HTTP Gzip target responses
    FHttpCompMinSize: Integer;          // minimum body size to compress
    FHttpStripUpgrade: Boolean;         // HTTP strip Upgrade: header to stop HTTP/2
    FHttpStopCached: Boolean;           // HTTP strip If-Modified header
    FHttpMaxBody: Integer;              // HTTP maximum body size to cached and process
    FonHttpReqHdr: TProxyHttpEvent;     // HTTP request header has been parsed
    FonHttpRespHdr: TProxyHttpEvent;    // HTTP response header has been parsed
    FonHttpPxyAuth: TProxyHttpEvent;    // HTTP proxy authorisation needed
    FonHttpReqBody: TProxyHttpEvent;    // HTTP request POST body has been read
    FonHttpRespBody: TProxyHttpEvent;   // HTTP response body has been read
    FonHttpWellKnown: TProxyHttpEvent;  // HTTP well-known directory found
  protected
      { Protected declarations }
  public
      { Public declarations }
    constructor Create(Owner:TComponent); override;
    destructor Destroy; override;
  published
      { Published declarations }
    property  HttpIgnoreClose : Boolean             read  FHttpIgnoreClose
                                                    write FHttpIgnoreClose;
    property  HttpSrcCompress : Boolean             read  FHttpSrcCompress
                                                    write FHttpSrcCompress;
    property  HttpTarCompress : Boolean             read  FHttpTarCompress
                                                    write FHttpTarCompress;
    property  HttpCompMinSize : Integer             read  FHttpCompMinSize
                                                    write FHttpCompMinSize;
    property  HttpStripUpgrade : Boolean            read  FHttpStripUpgrade
                                                    write FHttpStripUpgrade;
    property  HttpStopCached: Boolean               read  FHttpStopCached
                                                    write FHttpStopCached;
    property  HttpMaxBody: Integer                  read  FHttpMaxBody
                                                    write FHttpMaxBody;
    property  onHttpReqHdr: TProxyHttpEvent         read  FonHttpReqHdr
                                                    write FonHttpReqHdr;
    property  onHttpRespHdr: TProxyHttpEvent        read  FonHttpRespHdr
                                                    write FonHttpRespHdr;
    property  onHttpPxyAuth: TProxyHttpEvent        read  FonHttpPxyAuth
                                                    write FonHttpPxyAuth;
    property  onHttpReqBody: TProxyHttpEvent        read  FonHttpReqBody
                                                    write FonHttpReqBody;
    property  onHttpRespBody: TProxyHttpEvent       read  FonHttpRespBody
                                                    write FonHttpRespBody;
    property  onHttpWellKnown: TProxyHttpEvent      read  FonHttpWellKnown
                                                    write FonHttpWellKnown;
  end;

{ public functions }
function IcsLoadProxyTargetsFromIni(MyIniFile: TCustomIniFile; ProxyTargets:
               TProxyTargets; const Prefix: String = 'Target'): Integer;
procedure IcsLoadTIcsHttpProxyFromIni(MyIniFile: TCustomIniFile; IcsHttpProxy:
                TIcsHttpProxy; const Section: String = 'Proxy');

{$ENDIF}  { USE_SSL }

implementation

{$IFDEF USE_SSL}

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ TProxyTargets }
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TProxyTargets.Create(Owner: TPersistent);
begin
  FOwner := Owner;
  inherited Create(TProxyTarget);
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TProxyTargets.GetItem(Index: Integer): TProxyTarget;
begin
  Result := TProxyTarget(inherited GetItem(Index));
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TProxyTargets.SetItem(Index: Integer; Value: TProxyTarget);
begin
  inherited SetItem(Index, TCollectionItem(Value));
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TProxyTargets.GetOwner: TPersistent;
begin
  Result := FOwner;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ TProxyTarget }
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TProxyTarget.Create(Collection: TCollection);
begin
    inherited;
    FHostEnabled := True;
    FIdleTimeout := 70;  // seconds
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TProxyTarget.GetDisplayName: string;
begin
    if TarHost <> '' then
        Result := TarHost
    else
        Result := Inherited GetDisplayName
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ TProxyClient }
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TProxyClient.Create(Owner: TComponent);
begin
    inherited Create(Owner);
    FTarSocket := TSslWSocket.Create(Self);
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
destructor TProxyClient.Destroy;
begin
    FreeAndNil(FTarSocket) ;
    inherited Destroy;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TProxyClient.LogEvent(const Msg : String);
begin
    if Assigned (FProxySource.FonProxyProg) then
        FProxySource.LogProgEvent(FLogDescr + Msg);
end ;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TProxyClient.LogSrcEvent(const Msg : String);
var
    dur: Integer;
begin
    if Assigned (FProxySource.FonProxyProg) then begin
        dur := IcsCalcTickDiff(Self.Counter.ConnectTick, IcsGetTickCount);
        LogEvent('Source ' + FloatToStrF (dur / 1000, ffFixed, 7, 2) + ' - ' + Msg);
    end;
end ;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TProxyClient.LogTarEvent(const Msg : String);
var
    dur: Integer;
begin
    if Assigned (FProxySource.FonProxyProg) then begin
        dur := IcsCalcTickDiff(FTarSocket.Counter.ConnectTick, IcsGetTickCount);
        LogEvent('Target ' + FloatToStrF (dur / 1000, ffFixed, 7, 2) + ' - ' + Msg);
    end;
end ;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ send buffered data to remote target }
procedure TProxyClient.TargetBufXmit(SendNr: Integer);
var
    DataPtr: Pointer;
    DataLen: Integer;
begin
    if (FTarSocket.State <> wsConnected) then Exit ;
    if (FSrcWaitTot <= 0) then Exit;
    if (SendNr >  FSrcWaitTot) then SendNr := FSrcWaitTot;
    DataPtr := @FSrcBuffer[0];
    DataLen := SendNr;
    if Assigned(FProxySource.FOnDataSendTar) then begin
        FProxySource.FOnDataSendTar(FProxySource, Self, DataPtr, DataLen);
        if NOT Assigned(DataPtr) then DataLen := 0;  // sanity test
    end;
    if (DataLen > 0) then
        FTarSocket.Send(DataPtr, DataLen);

 { remove what we sent from buffer }
    FSrcWaitTot := FSrcWaitTot - SendNr;
    if FSrcWaitTot > 0 then
        IcsMoveTBytes(FSrcBuffer, SendNr, 0, FSrcWaitTot);
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ receive as much data from remote target as buffer will take }
procedure TProxyClient.TargetBufRecv;
var
    RxRead, RxCount, LoopCounter: Integer;
begin
    LoopCounter := 0;
    if FTarWaitTot < 0 then FTarWaitTot := 0; // sanity check
    while TRUE do begin
        inc (LoopCounter);
        if (LoopCounter > 100) then Exit;  // sanity check
        RxCount := FTarBufMax - FTarWaitTot - 1;
        if RxCount <= 0 then Exit;         // sanity check
        RxRead := FTarSocket.Receive (@FTarBuffer[FTarWaitTot], RxCount);
        if RxRead <= 0 then Exit;          // nothing read
        FTarWaitTot := FTarWaitTot + RxRead;
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ send buffered data to source server }
procedure TProxyClient.SourceBufXmit(SendNr: Integer);
var
    DataPtr: Pointer;
    DataLen: Integer;
begin
    if (Self.State <> wsConnected) then Exit ;
    if (FTarWaitTot <= 0) then Exit;
    if (SendNr >  FTarWaitTot) then SendNr := FTarWaitTot;
    DataPtr := @FTarBuffer[0];
    DataLen := SendNr;
    if Assigned(FProxySource.FOnDataRecvTar) then begin
        FProxySource.FOnDataRecvTar(FProxySource, Self, DataPtr, DataLen);
        if NOT Assigned(DataPtr) then DataLen := 0;  // sanity test
    end;
    if (DataLen > 0) then
        Self.Send(DataPtr, DataLen);

 { remove what we sent from buffer }
    FTarWaitTot := FTarWaitTot - SendNr;
    if FTarWaitTot > 0 then
        IcsMoveTBytes(FTarBuffer, SendNr, 0, FTarWaitTot);
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ receive as much data from source server as buffer will take }
procedure TProxyClient.SourceBufRecv;
var
    RxRead, RxCount, LoopCounter: Integer;
begin
    LoopCounter := 0;
    if FSrcWaitTot < 0 then FSrcWaitTot := 0; // sanity check
    while TRUE do begin
        inc (LoopCounter);
        if (LoopCounter > 100) then Exit;    // sanity check
        RxCount := FSrcBufMax - FSrcWaitTot - 1;
        if RxCount <= 0 then Exit;           // sanity check
        RxRead := Self.Receive (@FSrcBuffer[FSrcWaitTot], RxCount);
        if RxRead <= 0 then Exit;            // nothing read
        FSrcWaitTot := FSrcWaitTot + RxRead;
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ receive data from source server, and send to remote target }
{ note this is overwritten for the HTTP client, it's more compicated }
procedure TProxyClient.SourceXferData;
var
    LoopCounter: Integer;
begin
    LoopCounter := 0;
    if (FProxySource.DebugLevel >= DebugAll) then LogTarEvent('Forwarding data to target');
    while TRUE do begin
        inc (LoopCounter);
        if (LoopCounter > 100) then Exit;  // sanity check
        if (FTarSocket.State <> wsConnected) then Exit;
        SourceBufRecv;
        if FSrcWaitTot = 0 then Exit;  // nothing to send
        TargetBufXmit(FSrcWaitTot);
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ note this is overwritten for the HTTP client, it's more compicated }
procedure TProxyClient.TargetXferData;
var
    LoopCounter: Integer;
begin
    if (FProxySource.DebugLevel >= DebugAll) then LogTarEvent('Forwarding data to source');
    LoopCounter := 0;
    while TRUE do begin
        inc (LoopCounter);
        if (LoopCounter > 100) then Exit;  // sanity check
        if (Self.State <> wsConnected) then Exit;
        TargetBufRecv;
        if FTarWaitTot = 0 then Exit;  // nothing to send
        SourceBufXmit(FTarWaitTot);
    end;
end;




{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TProxyClient.SourceDataAvailable(Sender: TObject; Error: Word);
begin
  { target already connected, send data immediately }
    if (FTarSocket.State = wsConnected) or FTarHttp then
        SourceXferData
    else begin
     { target not connected, buffer data until we can xfer it }
        SourceBufRecv;

      { if we got something, see if need a new target connection }
        if (FSrcWaitTot > 0) then begin
            if (FProxySource.DebugLevel >= DebugAll) then begin
                if FClosingFlag then
                    LogSrcEvent('Warning, received data while tryinmg to close')
                else
                    LogSrcEvent('Received data before target connected, bytes ' + IntToStr(FSrcWaitTot));
             end;

          { start another target connection if last one closed  }
            if (FTarCurHost <> '') and { (NOT FTarConnecting) and }
                        (FTarSocket.State in [wsClosed, wsInvalidState]) then begin
                if (FProxySource.DebugLevel >= DebugConn) then
                    LogSrcEvent('Starting new target connection');
                if NOT TargetConnect then begin
                    FClosingFlag := True;
                    Close;
                end;
            end;
        end;
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ triggered when all target data forwarded to client, see if closing client }
{ note this is overwritten for the HTTP client, it's more compicated }
procedure TProxyClient.SourceDataSent(Sender: TObject; ErrCode : Word);
begin
end;




{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ note this is overwritten for the HTTP client, it's more compicated }
procedure TProxyClient.SourceSessionClosed(Sender: TObject; Error: Word);
begin
    FSrcPendClose := False;
    if FTarSocket.State = wsConnected then FTarSocket.Close;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TProxyClient.TargetInitialiase;
begin
  { setup client server socket to receive data }
    Self.OnDataAvailable := SourceDataAvailable;
    Self.OnDataSent := SourceDataSent;
    Self.OnSessionClosed := SourceSessionClosed;
    Self.OnBgException := FProxySource.SocketBgException;
    Self.CreateCounter;
    Self.Counter.SetConnected;

 { setup remote targer socket to which we connect and send data }
    FTarSocket.SslContext := FProxySource.FTarSslCtx;
    FTarSocket.SslMode := sslModeClient;
    FTarSocket.Proto := 'tcp';
    FTarSocket.OnDataAvailable := TargetDataAvailable;
    FTarSocket.OnSessionClosed := TargetSessionClosed;
//    FTarSocket.OnDnsLookupDone := TargetDnsLookupDone;
    FTarSocket.OnSessionConnected := TargetSessionConnected;
    FTarSocket.OnSslCliNewSession := TargetCliNewSession;
    FTarSocket.OnSslCliGetSession := TargetCliGetSession;
    FTarSocket.OnSslVerifyPeer := TargetVerifyPeer;
    FTarSocket.OnSslHandshakeDone := TargetHandshakeDone;
{$IFNDEF NO_DEBUG_LOG}
    FTarSocket.IcsLogger := FProxySource.FIcsLog;
{$ENDIF}
    FTarSocket.LingerOnOff := wsLingerOff;
    FTarSocket.LingerTimeout := 0;
    FTarSocket.LineMode := false;
    FTarSocket.OnBgException := FProxySource.SocketBgException;
  { important, set AsyncDnsLookup so we don't need OnDnsLookup event }
    FTarSocket.ComponentOptions := [wsoNoReceiveLoop, wsoAsyncDnsLookup, wsoIcsDnsLookup];
    FTarSocket.LocalAddr := FProxySource.FLocalAddr;
    FTarSocket.Addr := '';
    FTarSocket.SocketErrs := wsErrFriendly;
    FTarSocket.CreateCounter;
    FTarSocket.Counter.SetConnected;

  { buffers to receive data }
    FSrcBufMax := FProxySource.RxBuffSize;
    FTarBufMax := FProxySource.RxBuffSize;
    SetLength(FSrcBuffer, FSrcBufMax + 1);
    SetLength(FTarBuffer, FTarBufMax + 1);
    FSrcWaitTot := 0;
    FTarWaitTot := 0;

 { other stuff }
//    FTarConnecting := False;
    FSrcPendClose := False;
    FTarCurHost := '';
    FTarClosedFlag := False;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ log source, find target according to HostTag }
{ note this is overwritten for the HTTP client, it's more compicated }
procedure TProxyClient.TargetCheck;
begin
    Self.FLogDescr := FHostTag + ' - ' + FProxySource.IcsHosts[IcsHostIdx].Descr +    { V8.49 }
                                                   ' (' + IntToStr (FCliId) + ') ';
    if (FProxySource.DebugLevel >= DebugConn) then
        LogSrcEvent('Host #' + IntToStr(FIcsHostIdx) + ' ' + FSrcHost +
                           ', Listener ' + CServerAddr + ':' + CServerPort);

  { find ProxyTarget may change later if checking path in HTTP header }
    FPxyTargetIdx := FProxySource.FindPxyTarget(FHostTag);
    if FPxyTargetIdx < 0 then begin  { should have been checked earlier }
        if (FProxySource.DebugLevel >= DebugConn) then
            LogSrcEvent('Host #' + IntToStr(FIcsHostIdx) + ', no matching proxy target found');
        FClosingFlag := True;
        Self.Close;
        exit;
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ sets target host and stuff from ProxyTarget collection }
{ note this is overwritten for the HTTP client, it's more compicated }
procedure TProxyClient.TargetSpecify;
begin
    if FPxyTargetIdx < 0 then Exit;
    FTarSocket.Counter.SetConnected;  // reset
    with FProxySource.ProxyTargets[FPxyTargetIdx] do begin
        if (FProxySource.DebugLevel >= DebugConn) then
            LogSrcEvent('Target #' + IntToStr(FPxyTargetIdx) + ' - ' +
                                          TarHost + ':' + IntToStr(TarPort));
        Self.FTarHost := TarHost;
       { V4.49 zero target means copy source port }
         if TarPort > 0 then begin
            Self.FTarPort := IntToStr(TarPort);
            Self.FTarSsl := TarSsl;
        end
        else begin
            Self.FTarSsl := SslEnable;
            Self.FTarPort := CServerPort;
            if (FProxySource.DebugLevel >= DebugConn) then
                LogSrcEvent('Copied source port for target - ' +
                                            TarHost + ':' + CServerPort);
        end;
        Self.FIdleTimeout := IdleTimeout;
    end;

  { if IcsHost specified both non-SSL and SSL port, don't change SSL method }
  { V4.49 bad idea, removed
    with  FProxySource.IcsHosts[IcsHostIdx] do begin
        if (BindSslPort = 443) and (BindNonPort = 80) then begin
            Self.FTarSsl := SslEnable;
            Self.FTarPort := CServerPort;
        end;
    end;    }

  { let application change target before we connect }
    if Assigned(FProxySource.FOnSetTarget) then begin
        FProxySource.FOnSetTarget(FProxySource, Self);
    end;
 end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TProxyClient.TargetConnect: Boolean;
begin
    Result := True;
    if (FTarSocket.State = wsConnected) then Exit;
//    if FTarConnecting then Exit;
    if (FTarHost = '') or (FTarPort = '') then begin
        LogSrcEvent('Failed to Target #' +
                IntToStr(FPxyTargetIdx) + ' - Host and/or Port Blank');
        Result := False;
        exit;
    end;
    FTarClosedFlag := False;
    FTarSocket.Counter.SetConnected;  // reset
    FTarCurHost := FTarHost;  // used to see if need to reconnect later
    FTarSocket.SslEnable := FTarSsl;
    FTarSocket.SslServerName := FTarHost;  // SNI
  { localhost fails if real local address used }
    if (FTarHost = ICS_LOCAL_HOST_V4) or (IcsLowerCase(FTarHost) = 'localhost') then
        FTarSocket.LocalAddr := ICS_ANY_HOST_V4;
    if (FProxySource.DebugLevel >= DebugConn) then begin
        if FPxyTargetIdx >= 0 then
            LogSrcEvent('Connecting to Target #' +
                IntToStr(FPxyTargetIdx) + ' - ' + FTarHost + ':' + FTarPort)
        else
            LogSrcEvent('Connecting to conditional Target - ' + FTarHost + ':' + FTarPort);
    end ;
    try
        FTarSocket.Addr := FTarHost;    // use for new internal lookup
        FTarSocket.Port := FTarPort;
        FTarSocket.Connect;
        Result := True;
    except
        on E:Exception do begin
            LogSrcEvent('Target connection error: ' + E.Message);
            Result := False;
        end;
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ note this is overwritten for the HTTP client, it's more compicated }
procedure TProxyClient.TargetSessionConnected(Sender: TObject; Error: Word);
begin
    try
        if (Error <> 0) then begin
           if (FProxySource.DebugLevel >= DebugConn) then begin
     { see if we looked up a DNS address, that might be silly }
                if (FTarSocket.DnsResult <> '') then
                    LogTarEvent('Remote IP Adress ' + FTarSocket.DnsResult);
                LogTarEvent('Remote connection failed (' + WSocketErrorDesc(Error) + ')');
            end;
            if Assigned(FProxySource.FOnTarConnect) then
                FProxySource.FOnTarDisconnect(FProxySource, Self, Error);
            Self.Close;
            Exit;
        end;
        FTarSocket.Counter.SetConnected;
        FTarIP := FTarSocket.GetPeerAddr;  // keep looked-up IP>
        if (FProxySource.DebugLevel >= DebugConn) then
            LogTarEvent('Remote IP Adress ' + FTarIP);
        if Assigned(FProxySource.FOnTarConnect) then
            FProxySource.FOnTarDisconnect(FProxySource, Self, Error);
        if FTarSocket.SslEnable then begin
            if (FProxySource.DebugLevel >= DebugSsl) then
                    LogTarEvent('Remote starting SSL handshake to ' + FTarHost);
            FTarSocket.StartSslHandshake;
        end
        else begin
            if (FProxySource.DebugLevel >= DebugConn) then
                 LogTarEvent('Remote connection OK to ' + FTarHost);
            PostMessage(FProxySource.Handle, FProxySource.FMsg_TARGET_CONNECTED, 0, LPARAM(Self))
        end;
    except
        on E:Exception do begin
            if (FProxySource.DebugLevel >= DebugSsl) then
                LogTarEvent('Remote start SSL handshake error: ' + E.Message);
            Self.Close;
        end;
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TProxyClient.TargetVerifyPeer(Sender: TObject; var Ok : Integer; Cert: TX509Base);
begin
    OK := 1; // check certificate later
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TProxyClient.TargetHandshakeDone(Sender: TObject; ErrCode: Word;
                                    PeerCert: TX509Base; var Disconnect : Boolean);
var
    CertChain: TX509List;
    ChainVerifyResult: LongWord;
    Hash, info, VerifyInfo: String;
    Safe: Boolean;
begin
    with Sender as TSslWSocket do begin
        if (ErrCode <> 0) or Disconnect then begin
            if (FProxySource.DebugLevel >= DebugSsl) then
                LogTarEvent('Remote SSL handshake failed - ' + SslHandshakeRespMsg);
            Disconnect := TRUE;
            CloseDelayed;
            exit;
        end ;
        if (FProxySource.DebugLevel >= DebugConn) then
            LogTarEvent('Remote connection OK to ' + FTarHost + ' - ' + SslHandshakeRespMsg) ;
        PostMessage(FProxySource.Handle, FProxySource.FMsg_TARGET_CONNECTED, 0, LPARAM(Self));

     { it don't need to check SSL certificate, escape here  }
        if SslSessionReused OR (FProxySource.CertVerTar = CertVerNone) then begin
            exit;
        end ;

      { don't check localhost certificate, we trust our own server }
        if (FTarHost = ICS_LOCAL_HOST_V4) or (IcsLowerCase(FTarHost) = 'localhost') then begin
            exit;
        end ;

     { Is current host already in the list of temporarily accepted hosts ? }
        Hash := PeerCert.Sha1Hex ;
        if (FProxySource.FTarSslCertList.IndexOf(SslServerName + Hash ) > -1) then begin
            exit;
        end ;

     { Property SslCertChain contains all certificates in current verify chain }
        CertChain := SslCertChain;

     { see if validating against Windows certificate store, V8.50 not on MacOS  }
{$IFDEF MSWINDOWS}
        if FProxySource.CertVerTar = CertVerWinStore then begin

            { start engine }
            if not Assigned (FProxySource.FMsCertChainEngine) then
                FProxySource.FMsCertChainEngine := TMsCertChainEngine.Create;

          { see if checking revoocation, CRL checks and OCSP checks in Vista+, very slow!!!! }
            if FProxySource.SslRevocation then
                FProxySource.FMsCertChainEngine.VerifyOptions := [mvoRevocationCheckChainExcludeRoot]
            else
                FProxySource.FMsCertChainEngine.VerifyOptions := [];

          { This option doesn't seem to work, at least when a DNS lookup fails }
            FProxySource.FMsCertChainEngine.UrlRetrievalTimeoutMsec := 10 * 1000;

          { Pass the certificate and the chain certificates to the engine      }
            FProxySource.FMsCertChainEngine.VerifyCert (PeerCert, CertChain, ChainVerifyResult, True);

            Safe := (ChainVerifyResult = 0) or
                    { We ignore the case if a revocation status is unknown.      }
                    (ChainVerifyResult = CERT_TRUST_REVOCATION_STATUS_UNKNOWN) or
                    (ChainVerifyResult = CERT_TRUST_IS_OFFLINE_REVOCATION) or
                    (ChainVerifyResult = CERT_TRUST_REVOCATION_STATUS_UNKNOWN or
                                         CERT_TRUST_IS_OFFLINE_REVOCATION);

          { The MsChainVerifyErrorToStr function works on chain error codes     }
            VerifyInfo := MsChainVerifyErrorToStr (ChainVerifyResult);

          { MSChain ignores host name, so see if it failed using OpenSSL }
            if PeerCert.VerifyResult = X509_V_ERR_HOSTNAME_MISMATCH then begin
                Safe := False;
                VerifyInfo := PeerCert.FirstVerifyErrMsg;
             end;
        end
        else
{$ENDIF}
        if FProxySource.CertVerTar = CertVerBundle then begin
            VerifyInfo := PeerCert.FirstVerifyErrMsg;
           { check whether SSL chain verify result was OK }
            Safe := (PeerCert.VerifyResult = X509_V_OK);
        end
        else begin
            exit;  // unknown method
        end ;

      { allow self signed certs }
        if (CertChain.Count > 0) and (CertChain[0].FirstVerifyResult =
                                          X509_V_ERR_SELF_SIGNED_CERT_IN_CHAIN) then begin
            Safe := true;
            if (FProxySource.DebugLevel >= DebugSsl) then
                LogTarEvent('SSL self signed certificate succeeded: ' +
                                         PeerCert.UnwrapNames (PeerCert.IssuerCName));
        end;

      { tell user verification failed }
        if (FProxySource.DebugLevel >= DebugConn) and (NOT Safe) then begin
            info := 'SSL chain verification failed: ' + VerifyInfo + ', Domain: ';
            if PeerCert.SubAltNameDNS = '' then
                info := info + IcsUnwrapNames(PeerCert.SubjectCName)
            else
                info := info + IcsUnwrapNames(PeerCert.SubAltNameDNS);
            info := info + ', Expected: ' + SslServerName;
            LogTarEvent(info);
        end

      { check certificate was issued to remote host for out connection  }
        else begin
            if (FProxySource.DebugLevel >= DebugSsl) then
                LogTarEvent('SSL chain verification succeeded, Domain: ' + SslCertPeerName);
        end;

     { if certificate checking failed, see if the host is specifically listed as being allowed anyway }
        if (NOT Safe) and (FProxySource.FTarSslCertList.IndexOf(SslServerName) > -1) then begin
            Safe := true;
            if (FProxySource.DebugLevel >= DebugSsl) then
               LogTarEvent('SSL succeeded with acceptable Host Name');
        end;

      { keep this server name and certificate in server list to stop if being check again for a few hours }
        if Safe then begin
            FProxySource.FTarSslCertList.Add(SslServerName + Hash);
        end;

      { tell user about all the certificates we found }
        if (FProxySource.DebugLevel >= DebugSsl) and
            (FProxySource.SslReportChain) and (CertChain.Count > 0) then begin
            if (FProxySource.CertVerTar = CertVerWinStore) then
                 info := 'Verify result: ' + MsCertVerifyErrorToStr(CertChain[0].CustomVerifyResult) + #13#10
            else
                 info := 'Verify result: ' + CertChain[0].FirstVerifyErrMsg + #13#10 ;
            info := info + IntToStr(CertChain.Count) + ' SSL certificates in the verify chain:' +
                                                         #13#10 + CertChain.AllCertInfo (true, true) ;
            LogTarEvent(info);
        end;

      { all failed, die }
        if NOT Safe then
        begin
            Disconnect := TRUE;
            exit ;
        end;
    end;
end;




{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TProxyClient.TargetDataAvailable(Sender: TObject; Error: Word);
begin
    if Self.State = wsConnected then
        TargetXferData
    else begin
        if (FProxySource.DebugLevel >= DebugAll) then
            LogTarEvent('Send data after source server disconnected');
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ !!! might not need this }
{ note this is overwritten for the HTTP client, it's more compicated }
procedure TProxyClient.TargetDataSent(Sender: TObject; ErrCode : Word);
begin
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TProxyClient.TargetCliNewSession(Sender: TObject; SslSession: Pointer;
                                            WasReused: Boolean; var IncRefCount : Boolean);
begin
    if NOT Assigned (FProxySource.SslSessCache) then exit;
    if (NOT WasReused) then  begin
        with Sender as TSslWSocket do
            FProxySource.SslSessCache.CacheCliSession(SslSession, PeerAddr + PeerPort, IncRefCount);
        if (FProxySource.DebugLevel >= DebugSsl) then LogTarEvent('SSL New Session');
    end
    else begin
            if (FProxySource.DebugLevel >= DebugSsl) then LogTarEvent('SSL Session Reused');
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TProxyClient.TargetCliGetSession(Sender: TObject;
                        var SslSession: Pointer; var FreeSession : Boolean);
begin
    if NOT Assigned (FProxySource.SslSessCache) then exit;
    with Sender as TSslWSocket do
        SslSession := FProxySource.SslSessCache.GetCliSession(PeerAddr + PeerPort, FreeSession);
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ note this is overwritten for the HTTP client, it's more compicated }
procedure TProxyClient.TargetSessionClosed(Sender: TObject; Error: Word);
begin
    FTarClosedFlag := True;
    if (Self.State = wsConnected) and (FTarWaitTot <> 0) then
        TargetXferData;
    if (FProxySource.DebugLevel >= DebugConn) then begin
        if (Error = 0) or (Error = 10053) then
            LogTarEvent('Remote closed, Data sent ' +
                IntToStr (FTarSocket.WriteCount) + ', Data recvd ' + IntToStr (FTarSocket.ReadCount))
        else
            LogTarEvent('Remote lost (' + WSocketErrorDesc(Error) + '), Data sent ' +
                IntToStr (FTarSocket.WriteCount) + ', Data recvd ' + IntToStr (FTarSocket.ReadCount));
    end;
    if Assigned(FProxySource.FOnTarDisconnect) then
        FProxySource.FOnTarDisconnect(FProxySource, Self, Error);

    if (NOT FClosingFlag) then begin
        if (FProxySource.DebugLevel >= DebugConn) then
            LogSrcEvent('Client closing after target');
        Self.CloseDelayed;
        FClosingFlag := True;
    end
    else if (FProxySource.DebugLevel >= DebugConn) then
        LogSrcEvent('Client already closing');
    FDelayedDisconn := false;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ TIcsProxy main proxy component }
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TIcsProxy.Create(Owner: TComponent);
begin
    inherited Create(Owner);
  { several component properties set FSourceServer so it must be created
    first and never freed }
    FSourceServer := TSslWSocketServer.Create(Self);
    FSourceServer.ClientClass := TProxyClient;
    FProxyTargets := TProxyTargets.Create(Self);
    FTarSslCtx := TSslContext.Create(Self);
    FTarSslCertList := TStringList.Create;
    FTarSecLevel := sslSecLevel80bits;
    FCertVerTar := CertVerNone;
    FDebugLevel := DebugSsl;
    FSocketErrs := wsErrFriendly;
    FMaxClients := 999;
    FRxBuffSize := DefRxBuffSize;
{$IFDEF MSWINDOWS}
   FMsCertChainEngine := Nil;
{$ENDIF}
    FIcsLog := TIcsLogger.Create (nil);
    FIcsLog.OnIcsLogEvent := IcsLogEvent;
    FIcsLog.LogOptions := [loDestEvent];
    FCurDate := Trunc(Date);
    FFlushTick := IcsGetTickCount;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
destructor TIcsProxy.Destroy;
begin
    Stop;
{$IFDEF MSWINDOWS}
    FreeAndNil(FMsCertChainEngine);
{$ENDIF}
    FreeAndNil(FTarSslCtx);
    FreeAndNil(FProxyTargets);
    FreeAndNil(FTarSslCertList);
    FreeAndNil(FSourceServer);
    FreeAndNil(FCleanupTimer);
    FreeAndNil(FIcsLog);
    inherited Destroy;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TIcsProxy.MsgHandlersCount : Integer;
begin
    Result := 1 + inherited MsgHandlersCount;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.AllocateMsgHandlers;
begin
    inherited AllocateMsgHandlers;
    FMsg_TARGET_CONNECTED := FWndHandler.AllocateMsgHandler(Self);
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.FreeMsgHandlers;
begin
    if Assigned(FWndHandler) then
        FWndHandler.UnregisterMessage(FMsg_TARGET_CONNECTED);
    inherited FreeMsgHandlers;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.WndProc(var MsgRec: TMessage);
var
    CanClose: boolean;
begin
    with MsgRec do begin
        if Msg = FMsg_TARGET_CONNECTED then begin
       { We *MUST* handle all exception to avoid application shutdown }
            try
                WMTargetConnected(MsgRec)
            except
                on E:Exception do
                    SocketBgException(Self, E, CanClose);
            end;
        end
        else
            inherited WndProc(MsgRec);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.IcsLogEvent(Sender: TObject; LogOption: TLogOption;
                                                      const Msg : String);
begin
    if Assigned (FonProxyProg) then FonProxyProg(Self, LogOption, Msg) ;
end ;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.LogProgEvent(const Msg : String);
begin
    if Assigned (FonProxyProg) then  FonProxyProg(Self, loProtSpecInfo, Msg) ;
end ;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.LogErrEvent(const Msg : String);
begin
    if Assigned (FonProxyProg) then FonProxyProg(Self, loProtSpecErr, Msg) ;
end ;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.SetProxyTargets(const Value: TProxyTargets);
begin
    FProxyTargets.Assign(Value);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TIcsProxy.GetIcsHosts: TIcsHostCollection;
begin
    if Assigned(FSourceServer) then
        Result := FSourceServer.GetIcsHosts
    else
        Result := nil;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.SetIcsHosts(const Value: TIcsHostCollection);
begin
    if Assigned(FSourceServer) then FSourceServer.SetIcsHosts(Value);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TIcsProxy.GetRootCA: String;
begin
    if Assigned(FSourceServer) then
        Result := FSourceServer.RootCA
    else
        Result := '';
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.SetRootCA(const Value: String);
begin
    if Assigned(FSourceServer) then FSourceServer.RootCA := Value;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TIcsProxy.GetDHParams: String;
begin
    if Assigned(FSourceServer) then
        Result := FSourceServer.DHParams
    else
        Result := '';
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.SetDHParams(const Value: String);
begin
    if Assigned(FSourceServer) then FSourceServer.DHParams := Value;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TIcsProxy.GetSslCliCertMethod: TSslCliCertMethod;             { V8.57 }
begin
    if Assigned(FSourceServer) then
        Result := TSslWSocketServer(FSourceServer).SslCliCertMethod
    else
        Result := sslCliCertNone;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.SetSslCliCertMethod(const Value : TSslCliCertMethod); { V8.57 }
begin
    if Assigned(FSourceServer) then
        TSslWSocketServer(FSourceServer).SslCliCertMethod := Value;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TIcsProxy.GetSslCertAutoOrder: Boolean;                       { V8.57 }
begin
    if Assigned(FSourceServer) then
        Result := TSslWSocketServer(FSourceServer).SslCertAutoOrder
    else
        Result := False;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.SetSslCertAutoOrder(const Value : Boolean);         { V8.57 }
begin
    if Assigned(FSourceServer) then
        TSslWSocketServer(FSourceServer).SslCertAutoOrder := Value;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TIcsProxy.GetCertExpireDays: Integer;                         { V8.57 }
begin
    if Assigned(FSourceServer) then
        Result := TSslWSocketServer(FSourceServer).CertExpireDays
    else
        Result := 30;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.SetCertExpireDays(const Value : Integer);           { V8.57 }
begin
    if Assigned(FSourceServer) then
        TSslWSocketServer(FSourceServer).CertExpireDays := Value;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{$IFDEF AUTO_X509_CERTS}  { V8.59 }
function TIcsProxy.GetSslX509Certs: TSslX509Certs;    { V8.57 }
begin
    if Assigned(FSourceServer) then
        Result := TSslWSocketServer(FSourceServer).GetSslX509Certs as TSslX509Certs
    else
        Result := nil;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.SetSslX509Certs(const Value : TSslX509Certs);    { V8.57 }
begin
    if Assigned(FSourceServer) then
        TSslWSocketServer(FSourceServer).SetSslX509Certs(Value);
end;


{$ENDIF} // AUTO_X509_CERTS
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TIcsProxy.ValidateHosts(Stop1stErr: Boolean=True;
                                        NoExceptions: Boolean=False): String;
var
    I, J, K: Integer;
    HTag: String;
begin
    Result := '';
    if Assigned(FSourceServer) then begin
        Result := TSslWSocketServer(FSourceServer).ValidateHosts(Stop1stErr, NoExceptions);

     { each IcsHost must have at least one matching Target HostTag }
        for I := 0 to IcsHosts.Count - 1 do begin
            if NOT IcsHosts[I].HostEnabled then Continue;
            if IcsHosts[I].ForwardProxy then Continue;  // no target needed
            if IcsHosts[I].WebRedirectStat <> 0 then Continue;  // no target needed
            HTag := IcsHosts[I].HostTag;
            J := FindPxyTarget(HTag);
            if (J < 0) then begin
                Result := Result + 'Host ' + IntToStr(I) +
                                ' ' + HTag + ', no matching proxy target found';
                if Stop1stErr then raise ESocketException.Create(Result);
                continue;
            end;

          { check source tag is not a duplicate }
            if I > 0 then begin
                for K := 0 to I - 1 do begin
                    if NOT IcsHosts[K].HostEnabled then Continue;
                    if HTag = IcsHosts[K].HostTag then begin
                        Result := Result + 'Host ' + IntToStr(I) +
                                               ' ' + HTag + ' is a duplicate';
                        if Stop1stErr then raise ESocketException.Create(Result);
                        continue;
                    end;
                end;
            end;
            if Assigned(FSslSessCache) then begin
                IcsHosts[I].SslCtx.SslSessionCacheModes := [sslSESS_CACHE_CLIENT,
                  sslSESS_CACHE_NO_INTERNAL_LOOKUP, sslSESS_CACHE_NO_INTERNAL_STORE];
            end;
        end;
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TIcsProxy.RecheckSslCerts(var CertsInfo: String;
                    Stop1stErr: Boolean=True; NoExceptions: Boolean=False): Boolean;
begin
    Result := False;
    if Assigned(FSourceServer) then begin
        Result := TSslWSocketServer(FSourceServer).RecheckSslCerts(CertsInfo,
                                                        Stop1stErr, NoExceptions);
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TIcsProxy.ListenAllOK: Boolean;
begin
    if Assigned(FSourceServer) then
        Result := FSourceServer.ListenAllOK
    else
        Result := False;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TIcsProxy.ListenStates: String;
begin
    if Assigned(FSourceServer) then
        Result := FSourceServer.ListenStates
    else
        Result := '';
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TIcsProxy.GetRunning: Boolean;
begin
    if Assigned(FSourceServer) then
        Result := (FSourceServer.State = wsListening)
    else
        Result := False;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TIcsProxy.GetClientCount: Integer;
begin
    if Assigned(FSourceServer) then
        Result := FSourceServer.ClientCount
     else
        Result := 0;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ find first enabled matching proxy target, there may be more than one ! }
function TIcsProxy.FindPxyTarget(const Tag: String): Integer;
var
    I: Integer;
begin
    Result := -1;
    for I := 0 to ProxyTargets.Count - 1 do begin
        if NOT ProxyTargets[I].HostEnabled then Continue;
        if ProxyTargets[I].HostTag = Tag then begin
            Result := I;
            Exit;
         end;
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ find matching proxy target, checking hostname, no change if not found }
function TIcsProxy.FindPxySourceHost(const HHostName: String; MLIndx: Integer): Integer;
var
    I, J: Integer;
begin
    Result := -1;
    if IcsHosts.Count > 0 then begin
        for I := 0 to IcsHosts.Count - 1 do begin
            with IcsHosts[I] do begin
                if NOT HostEnabled then continue;
                if ((BindIdxNone = MLIndx) or (BindIdx2None = MLIndx) or
                     (BindIdxSsl = MLIndx) or (BindIdx2Ssl = MLIndx)) and
                       (HostNameTot > 0) then begin
                    for J := 0 to HostNameTot - 1 do begin
                        if ((HostNames[J] = '*') or
                                 (HostNames[J] = HHostName)) then begin
                            Result := I;
                            Exit;
                        end;
                    end;
                end;
            end;
        end;
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.Start;
var
    I: Integer;
    ErrInfo: String;
begin
  { If already listening, then do nothing }
    if FSourceServer.State = wsListening then Exit;

  { without these collections, nothing will work }
    if IcsHosts.Count = 0 then begin
        raise ESocketException.Create('Must specify Proxy Server Listen Hosts');
        exit ;
    end;
    if ProxyTargets.Count = 0 then begin
        raise ESocketException.Create('Must specify Proxy Server Targets');
        exit ;
    end;

 { each IcsHost must have at least one matching Target HostTag }
   if Assigned(FSslSessCache) then begin
        for I := 0 to IcsHosts.Count - 1 do begin
            IcsHosts[I].SslCtx.SslSessionCacheModes := [sslSESS_CACHE_CLIENT,
              sslSESS_CACHE_NO_INTERNAL_LOOKUP, sslSESS_CACHE_NO_INTERNAL_STORE];
        end;
    end;

  { allocates message windows and numbers in TIcsWndControl, needed before TIcsTimer }
    Self.Handle;

  { single SslContext for all target sockets }
{$IFNDEF NO_DEBUG_LOG}
    FTarSslCtx.IcsLogger := FIcsLog;
 {$ENDIF}
   FTarSslCtx.SslSessionCacheModes := [];
    if Assigned(FSslSessCache) then begin
        FTarSslCtx.SslSessionCacheModes := [sslSESS_CACHE_CLIENT,
            sslSESS_CACHE_NO_INTERNAL_LOOKUP, sslSESS_CACHE_NO_INTERNAL_STORE];
    end;
    FTarSslCtx.SslVerifyPeer := false;
    FTarSslCtx.SslVerifyPeerModes := [] ;
    FTarSslCtx.SslSecLevel := FTarSecLevel;
    if FCertVerTar > CertVerNone then begin
        FTarSslCtx.SslVerifyPeer := true;
        FTarSslCtx.SslVerifyPeerModes := [SslVerifyMode_PEER];
    end;
    FTarSslCtx.SslVersionMethod := sslBestVer_CLIENT ;
    FTarSslCtx.SslMinVersion := sslVerTLS1;
    FTarSslCtx.SslMaxVersion := sslVerMax;
    FTarSslCtx.SslECDHMethod := sslECDHAuto;
    FTarSslCtx.SslCipherList := sslCiphersNoDH;
    FTarSslCtx.SslOptions := [];
    if RootCA <> '' then begin
        if (Pos(PEM_STRING_HDR_BEGIN, RootCA) > 0) then
            FTarSslCtx.SslCALines.Text := RootCA
        else
            FTarSslCtx.SslCAFile := RootCA;
    end;
    FTarSslCtx.InitContext;

  { setup SocketServer events and properties, start it  }
    with FSourceServer do begin
        OnClientCreate := ServerClientCreate;
        OnClientConnect := ServerClientConnect;
        OnClientDisconnect := ServerClientDisconnect;
        SslMode := sslModeServer;
        OnSslVerifyPeer := ServerVerifyPeer;
        OnSslSetSessionIDContext := ServerSetSessionIDContext;
        OnSslSvrNewSession := ServerSvrNewSession;
        OnSslSvrGetSession := ServerSvrGetSession;
        OnSslHandshakeDone := ServerHandshakeDone;
        OnSslServerName := ServerServerName;
        OnSslAlpnSelect := ServerAlpnSelect;  { V8.57 }
        Banner := ''; { must not send anything upon connect }
        BannerTooBusy := '';
        Proto := 'tcp';
        MaxClients := FMaxClients;
        ExclusiveAddr := FExclusiveAddr;
        SocketErrs := FSocketErrs;
{$IFNDEF NO_DEBUG_LOG}
        IcsLogger := FIcsLog;
{$ENDIF}
        CreateCounter;
     { V8.49 returns list of exceptions, if any }
        ErrInfo := MultiListenEx;    { listen on multiple sockets, if more than one configured }
        if ErrInfo <> '' then LogProgEvent(ErrInfo);
        if FSourceServer.ListenAllOK then
            LogProgEvent('Proxy server started listening OK' +
                                        cCRLF + FSourceServer.ListenStates)
        else
            LogProgEvent('Proxy server failed to start listening' +
                                        cCRLF + FSourceServer.ListenStates);
    end;
    if NOT Assigned(FCleanupTimer) then begin
        FCleanupTimer := TIcsTimer.Create(Self);
        FCleanupTimer.OnTimer := CleanupTimerOnTimer;
        FCleanupTimer.Interval := 5000;
    end;
    FCleanupTimer.Enabled := True;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.Stop;
begin
    if not Assigned(FSourceServer) then Exit;
    if FSourceServer.State = wsListening then begin
        FCleanupTimer.Enabled := False;
        FSourceServer.MultiClose;
        LogProgEvent('Proxy server stopped listening');
        { Disconnect all clients }
        FSourceServer.DisconnectAll;
        { may take a while for all connections to cease, you should
          wait until ClientCount drops to zero }
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.SocketBgException(Sender: TObject; E: Exception; var CanClose: Boolean);
begin
    LogErrEvent('Socket Bg Exception - ' + E.Message);
    CanClose := true ;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.ServerClientCreate(Sender : TObject; Client : TWSocketClient);
begin
// do we need to do anythinf before ClientConnect??
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.ServerClientConnect(Sender: TObject; Client: TWSocketClient; Error: Word);
var
    MyClient: TProxyClient;
begin
    MyClient := Client as TProxyClient;
    MyClient.FProxySource := Self;  // before logging
    try
        if Error <> 0 then begin
            if Assigned(FOnSrcConnect) then
                FOnSrcConnect(Sender, Client, Error);
            LogErrEvent('Source listen connect error: ' + WSocketErrorDesc(Error));
            MyClient.FClosingFlag := True;
            MyClient.Close;
            exit;
        end;

    { create target socket, sets up event handlers and buffers, and counters  }
        MyClient.FPxyTargetIdx := -1;  // not found yet, may be forward proxy without one
        MyClient.FLogDescr := IcsHosts[MyClient.IcsHostIdx].Descr +
                                       ' (' + IntToStr (MyClient.CliId) + ') ';
        MyClient.FTarHttp := (Pos('HTTP', IcsHosts[MyClient.IcsHostIdx].Proto) = 1);
        MyClient.FForwardPrxy := IcsHosts[MyClient.IcsHostIdx].ForwardProxy;
        if MyClient.FForwardPrxy then MyClient.FTarConditional := True;
        MyClient.TargetInitialiase;   { no LogDurEvent before this }

    { application may be interested }
        if Assigned(FOnSrcConnect) then
            FOnSrcConnect(Sender, Client, Error);

    { is source SSL connection - note SocketServer starts handshake }
    { note MyClient.FPxyTargetIdx may be changed when SNI is checked for SSL }
        if MyClient.SslEnable then begin
            if (DebugLevel >= DebugSsl) then
                MyClient.LogSrcEvent('Client SSL handshake start from ' + MyClient.CPeerAddr);
        end
        else begin
            if (DebugLevel >= DebugConn) then
                MyClient.LogSrcEvent('Client connection from ' + MyClient.CPeerAddr);

        { check HTTP Host: header later }
            if NOT MyClient.FTarHttp then begin
                MyClient.FSrcHost := IcsHosts[MyClient.IcsHostIdx].HostNames [0];
                MyClient.TargetCheck;

             { start target connection, beware server may be receive data before it connects }
                MyClient.TargetSpecify;
                if NOT MyClient.TargetConnect then begin
                    MyClient.FClosingFlag := True;
                    MyClient.Close;
                end;
             end;
        end;
    except
        on E:Exception do begin
            LogErrEvent('Source server connect exception: ' + E.Message);
            MyClient.FClosingFlag := True;
            MyClient.Close;
        end;
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.ServerClientDisconnect(Sender: TObject; Client: TWSocketClient; Error: Word);
begin
    try
        if Assigned(FOnSrcDisconnect) then
            FOnSrcDisconnect(Sender, Client, Error);
        if Assigned (Client) then begin
            with Client as TProxyClient do begin
                if (DebugLevel >= DebugConn) then begin
                    if (Error = 0) or (Error = 10053) then
                        LogSrcEvent('Client disconnection from ' + CPeerAddr +
                           ', Data sent ' + IntToStr(WriteCount) + ', Data recvd ' + IntToStr(ReadCount))
                    else
                        LogSrcEvent('Client disconnection from ' + CPeerAddr + ': ' + WSocketErrorDesc(Error) +
                         ', Data sent ' + IntToStr(WriteCount) + ', Data recvd ' + IntToStr(ReadCount)) ;
                end;
            end
        end
        else begin
            if (DebugLevel >= DebugConn) then
                LogProgEvent('Source client disconnection: ' + WSocketErrorDesc(Error));
        end;
    except
        on E:Exception do begin
            LogErrEvent('Source client disconnection exception: ' + E.Message);
        end;
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.ServerServerName(Sender: TObject; var Ctx: TSslContext; var ErrCode: TTlsExtError);
begin
    if (DebugLevel >= DebugSsl) then begin
        with Sender as TProxyClient do
            LogSrcEvent('Client SNI: ' + SslServerName);
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.ServerAlpnSelect(Sender: TObject;
    ProtoList: TStrings; var SelProto : String; var ErrCode: TTlsExtError);  { V8.57 }
begin
    if Assigned(FOnSslAlpnSelect) then
        FOnSslAlpnSelect(Sender, ProtoList, SelProto, ErrCode);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.ServerSetSessionIDContext(Sender : TObject;
                                    var SessionIDContext : TSslSessionIdContext);
begin
    { Tell Openssl a Session_ID_Context.                                    }
    { Openssl uses this data to tag a session before it's cached.           }
    SessionIDContext := Ssl_Session_ID_Context;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.ServerSvrNewSession(Sender: TObject; SslSession, SessId: Pointer;
                                            Idlen: Integer; var AddToInternalCache: Boolean);
var
    LookupKey : string;
    MyClient: TProxyClient;
begin
    if NOT Assigned(FSslSessCache) then Exit;
    MyClient := Sender as TProxyClient;
{$IFDEF UNICODE}
    { We need to get binary data into a UnicodeString, allocate enough space. }
    { Not nice, however works in this case.                                   }
    SetLength(LookupKey, (IDLen div 2) + (IdLen mod 2));
{$ELSE}
    SetLength(LookupKey, IDLen);
{$ENDIF}
    Move(SessId^, Pointer(LookupKey)^, IDLen);
    FSslSessCache.CacheSvrSession(SslSession, LookupKey + Ssl_Session_ID_Context, AddToInternalCache);
    if (DebugLevel >= DebugSsl) then
        MyClient.LogSrcEvent('Client new SSL session created and cached');
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.ServerSvrGetSession(Sender: TObject; var SslSession: Pointer; SessId: Pointer;
                                                        Idlen: Integer; var IncRefCount: Boolean);
var
    LookupKey : string;
begin
    if NOT Assigned(FSslSessCache) then Exit;
{$IFDEF UNICODE}
    { We need to get binary data into a UnicodeString, allocate enough space. }
    { Not nice, however works in this case.                                   }
    SetLength(LookupKey, (IDLen div 2) + (IdLen mod 2));
{$ELSE}
    SetLength(LookupKey, IDLen);
{$ENDIF}
    Move(SessId^, Pointer(LookupKey)^, IDLen);
    SslSession := FSslSessCache.GetSvrSession(LookupKey + Ssl_Session_ID_Context, IncRefCount);
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.ServerVerifyPeer(Sender: TObject; var Ok : Integer; Cert: TX509Base);
begin
    OK := 1; // don't check certificate for server
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.ServerHandshakeDone(Sender: TObject; ErrCode: Word;
                                PeerCert: TX509Base; var Disconnect : Boolean);
var
    MyClient: TProxyClient;
begin
    try
        MyClient := Sender as TProxyClient;
        if (ErrCode <> 0) or Disconnect then begin
            if (DebugLevel >= DebugSsl) then
                MyClient.LogSrcEvent('Client SSL handshake failed: ' + MyClient.SslHandshakeRespMsg);
            Disconnect := TRUE;
        end
        else begin
            if (DebugLevel >= DebugSsl) then
                MyClient.LogSrcEvent('Client ' + MyClient.SslHandshakeRespMsg);

        { check HTTP Host: header later }
            if NOT MyClient.FTarHttp then begin
                MyClient.FSrcHost := MyClient.SslServerName;
                MyClient.TargetCheck;

             { start target connection, beware server may be receive data before it connects }
                MyClient.TargetSpecify;
                if NOT MyClient.TargetConnect then begin
                    MyClient.FClosingFlag := True;
                    MyClient.Close;
                end;
            end;
        end;
    except
        on E:Exception do begin
            LogErrEvent('Source listen SSL handshake exception: ' + E.Message);
            Disconnect := TRUE;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.WMTargetConnected(var msg: TMessage);
var
    MyClient: TProxyClient;
    Resp: String;
begin
    MyClient := TProxyClient(Msg.LParam);
    if NOT Assigned (MyClient) then exit;
    if NOT MyClient.FTunnelling then begin
        MyClient.SourceXferData;
    end
    else begin
         Resp := 'HTTP/1.1 200 Connection established' + cCRLF +
                 'Server: Proxy' + cDoubleCRLF;
         MyClient.LogSrcEvent('Sending Response to Source: ' + cCRLF + Resp);
         MyClient.SendText (Resp);
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsProxy.CleanupTimerOnTimer(Sender : TObject);
var
    MyClient: TProxyClient;
    I, Timeout, Duration : integer;
    CurTicks : LongWord;
begin
    if FTimerBusyFlag then Exit;
    FTimerBusyFlag := true;

  { midnight }
    if (FCurDate <> Trunc(Date)) then begin
        FCurDate := Trunc(Date);
    end;

  { periodically flush SSL host list so certificates are rechecked }
    Duration := IcsCalcTickDiff (FFlushTick, IcsGetTickCount) div (1000*60);
    if (Duration > FlushSslCacheMins) then begin
        FFlushTick := IcsGetTickCount;
        if FTarSslCertList.Count > 0 then begin
            LogProgEvent('Clearing target SSL certificate cache, total ' +
                                            IntToStr(FTarSslCertList.Count));
            FTarSslCertList.Clear;
        end;
    end;

 { look for idle clients }
    try
        if FSourceServer.ClientCount = 0 then exit;   // no clients
        try
            CurTicks := IcsGetTickCount;
            for I := Pred (FSourceServer.ClientCount) downto 0 do begin
                MyClient := FSourceServer.Client[I] as TProxyClient;
                if MyClient.FClosingFlag then Continue ;
                if MyClient.FSessionClosedFlag then Continue;  // Client will close soon
                if MyClient.Counter = Nil then Continue;

                { different length timeouts depending on what's happening }
                Timeout := MyClient.FIdleTimeout;
                if Timeout > 0 then begin
                    Duration := IcsCalcTickDiff(MyClient.Counter.LastAliveTick, CurTicks) div 1000;
                    if Duration >= Timeout then begin   { seconds }
                    if (MyClient.FTarSocket.State = wsConnected) then begin  // see if receiving remote data
                        if MyClient.FTarSocket.Counter = Nil then Continue;
                        Duration := IcsCalcTickDiff(MyClient.FTarSocket.Counter.LastAliveTick, CurTicks) div 1000;
                        if Duration < Timeout then continue;   { seconds }
                        if (DebugLevel >= DebugConn) then
                            MyClient.LogTarEvent('Closing target and client on proxy server timeout');
                        MyClient.FTarSocket.Close;
                    end
                    else
                        if (DebugLevel >= DebugConn) then
                            MyClient.LogSrcEvent('Closing client on proxy server timeout');
                        MyClient.FClosingFlag := True;
                        MyClient.Close;
                    end;
                end;
            end;
        except
            on E:Exception do begin
                LogErrEvent('Exception in Client Timeout Loop: ' + E.Message);
            end;
        end;
    finally
        FTimerBusyFlag := False;
  end ;

end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ THttpProxyClient }
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor THttpProxyClient.Create(Owner: TComponent);
begin
    inherited Create(Owner);
    FHttpTotReqs := 0;
    FHttpTotResps := 0;
    FHttpCurrReq := 0;
    FHttpCurrResp := 0;
    FHttpWaiting := 0;
    FPxyReqState := PxyHdrFind;       // HTTP request state
    FPxyRespState := PxyHdrFind;      // HTTP response state
    FPxyChunkState := PxyChunkGetSize; // HTTTP response chunked state
    FLastReqPath := 'xxx';
    FSrcHost := 'xxx';
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
destructor THttpProxyClient.Destroy;
begin
    inherited Destroy;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ send HTTP response to source client }
procedure THttpProxyClient.SourceHdrRespXmit;
var
    Actual: Integer;
begin
    if (Self.State <> wsConnected) then Exit ;
    if Length(FHttpRespHdr) = 0 then Exit;
    Actual := Self.SendStr(FHttpRespHdr);
    if (FProxySource.DebugLevel >= DebugHttpHdr) then
        LogTarEvent('Sent response header to source, length ' + IntToStr(Actual));
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ send request header to remote target }
procedure THttpProxyClient.TargetHdrReqXmit;
var
    Actual: Integer;
begin
    if (FTarSocket.State <> wsConnected) then Exit ;
    if Length(FHttpReqHdr) = 0 then Exit;
    Actual := FTarSocket.SendStr(FHttpReqHdr);
    if (FProxySource.DebugLevel >= DebugHttpHdr) then
        LogTarEvent('Sent request header to target, length ' + IntToStr(Actual));
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ send POST data to remote target }
procedure THttpProxyClient.TargetBodyXmit;
var
    DataPtr: Pointer;
    DataLen, Actual: Integer;
begin
    if (FTarSocket.State <> wsConnected) then Exit ;
    if (FHtmlReqBodyLen <= 0) then Exit;
    DataPtr := @FHtmlReqBody[0];
    DataLen := FHtmlReqBodyLen;
    if Assigned(FProxySource.FOnDataSendTar) then begin
        FProxySource.FOnDataSendTar(FProxySource, Self, DataPtr, DataLen);
        if NOT Assigned(DataPtr) then DataLen := 0;  // sanity test
    end;
    if (DataLen > 0) then begin
        Actual := FTarSocket.Send(DataPtr, DataLen);
        if (FProxySource.DebugLevel >= DebugAll) then
            LogTarEvent('Sent POST content to target, length ' + IntToStr(Actual));
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ send content body in bytes buffer to source client }
procedure THttpProxyClient.SourceBodyBufXmit;
var
    DataPtr: Pointer;
    DataLen, Actual: Integer;
begin
    if (Self.State <> wsConnected) then Exit ;
    if (FHtmlRespBodyLen <= 0) then Exit;
    DataPtr := @FHtmlRespBody[0];
    DataLen := FHtmlRespBodyLen;
    if Assigned(FProxySource.FOnDataRecvTar) then begin
        FProxySource.FOnDataRecvTar(FProxySource, Self, DataPtr, DataLen);
        if NOT Assigned(DataPtr) then DataLen := 0;  // sanity test
    end;
    if (DataLen > 0) then begin
        Actual := Self.Send(DataPtr, DataLen);
        if (FProxySource.DebugLevel >= DebugAll) then
            LogTarEvent('Sent body content to source, length ' + IntToStr(Actual));
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ triggered when all target data forwarded to client, see if closing client }
procedure THttpProxyClient.SourceDataSent(Sender: TObject; ErrCode : Word);
begin
    if (NOT FTarHttp) or FTunnelling then Exit;

  { processing response, event is triggered in other places  }
    if (FHttpCurrResp <> FHttpCurrReq) or (FHttpCurrResp < 1) then Exit;    // sanity check
    if (FHttpInfo [FHttpCurrResp].HttpReqState = httpStRespDone) then begin
        FHttpInfo [FHttpCurrResp].TickRespEnd := IcsGetTickCount;
        FHttpInfo [FHttpCurrResp].HttpReqState := httpStNone;
    //  ReportStats (FPxyRouting.rtNextResp);
        if FSrcPendClose then begin
            if (FProxySource.DebugLevel >= DebugHttpHdr) then
                    LogTarEvent('Finished Forwarding Response Data, Closing');
            if (Self.State = wsConnected) and (not FClosingFlag) then begin
                Self.CloseDelayed;
                FClosingFlag := True;
            end;
        end
        else if (FProxySource.DebugLevel >= DebugHttpHdr) then
              LogTarEvent('Finished Forwarding Response Data, Leave Open');
    end;
end;



 { !!! might not need this }
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure THttpProxyClient.TargetDataSent(Sender: TObject; ErrCode : Word);
begin
    inherited TargetDataSent(Sender, ErrCode);
end;




{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure THttpProxyClient.SourceSessionClosed(Sender: TObject; Error: Word);
begin
    inherited SourceSessionClosed(Sender, Error);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ log source, find target according to HostTag }
procedure THttpProxyClient.TargetCheck;
begin
    Self.FLogDescr := FHostTag + ' - ' + FProxySource.IcsHosts[IcsHostIdx].Descr +    { V8.49 }
                                                   ' (' + IntToStr (FCliId) + ') ';
    if (FProxySource.DebugLevel >= DebugConn) then
        LogSrcEvent('Host #' + IntToStr(FIcsHostIdx) + ' ' + FSrcHost +
                           ', Listener ' + CServerAddr + ':' + CServerPort);

  { find ProxyTarget may change later if checking path in HTTP header }
    FPxyTargetIdx := FProxySource.FindPxyTarget(FHostTag);
    if FPxyTargetIdx < 0 then begin  { should have been checked earlier }
        if (FProxySource.DebugLevel >= DebugConn) then
            LogSrcEvent('Host #' + IntToStr(FIcsHostIdx) + ', no matching proxy target found');
    { V8.49 tell the user something before closing the connectionn }
       if FTarHttp then TargetErrorResponse('502 Bad Gateway',
                                           'The gateway can not be found');
       FClosingFlag := True;
        Self.Close;
        exit;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ create the URLs we need to search and replace in headers and bodies }
procedure THttpProxyClient.TargetSpecify;
begin
    inherited TargetSpecify;
    if FSslEnable then
        FHttpSrcURL := 'https://'      // HTTP source URL for seaching
    else
        FHttpSrcURL := 'http://';
    FHttpSrcURL := FHttpSrcURL + IcsLowercase(FSrcHost);
    if (FServerPort <> '80') and (FServerPort <> '443') then
        FHttpSrcURL := FHttpSrcURL + ':' + FServerPort;
    if FTarSsl then
        FHttpTarURL1 := 'https://'       // HTTP target URL for seaching
    else
        FHttpTarURL1 := 'http://';
    FHttpTarURL1 := FHttpTarURL1 + IcsLowercase(FTarHost);
    FHttpTarURL2 := FHttpTarURL1;  // without port
    if (FTarPort <> '80') and (FTarPort <> '443') then
        FHttpTarURL1 := FHttpTarURL1 + ':' + FTarPort;
    LogTarEvent('Source URL: ' + FHttpSrcURL + ', Target URL: ' + FHttpTarURL1);
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure THttpProxyClient.TargetSessionConnected(Sender: TObject; Error: Word);
begin
    try
        if (Error <> 0) then begin
           if (FProxySource.DebugLevel >= DebugConn) then begin
     { see if we looked up a DNS address, that might be silly }
                if (FTarSocket.DnsResult <> '') then
                    LogTarEvent('Remote IP Adress ' + FTarSocket.DnsResult);
                LogTarEvent('Remote connection failed (' + WSocketErrorDesc(Error) + ')');
            end;
        { V8.49 tell the user something before closing the connectionn }
            if FTarHttp then TargetErrorResponse('502 Bad Gateway',
                   'The gateway can not connect to the requested server: ' + FTarHost);
            if Assigned(FProxySource.FOnTarDisconnect) then
                FProxySource.FOnTarDisconnect(FProxySource, Self, Error);
            Self.Close;
            Exit;
        end;
        FTarSocket.Counter.SetConnected;
        FTarIP := FTarSocket.GetPeerAddr;  // keep looked-up IP>
        if (FProxySource.DebugLevel >= DebugConn) then
            LogTarEvent('Remote IP Adress ' + FTarIP);
        if Assigned(FProxySource.FOnTarDisconnect) then
            FProxySource.FOnTarDisconnect(FProxySource, Self, Error);
        if FTarSocket.SslEnable then begin
            if (FProxySource.DebugLevel >= DebugSsl) then
                    LogTarEvent('Remote starting SSL handshake to ' + FTarHost);
            FTarSocket.StartSslHandshake;
        end
        else begin
            if (FProxySource.DebugLevel >= DebugConn) then
                 LogTarEvent('Remote connection OK to ' + FTarHost);
            PostMessage(FProxySource.Handle, FProxySource.FMsg_TARGET_CONNECTED, 0, LPARAM(Self))
        end;
    except
        on E:Exception do begin
            if (FProxySource.DebugLevel >= DebugSsl) then
                LogTarEvent('Remote start SSL handshake error: ' + E.Message);
            Self.Close;
        end;
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ send local werb page for errors and stuff }
procedure THttpProxyClient.SourceCreatePage(const Status, ContentType, ExtraHdr, BodyStr: String);
begin
  { create response header }
    FHttpRespHdr := FRequestVersion + ' ' + Status + cCRLF +
       'Content-Length: ' + IntToStr(Length(BodyStr)) + cCRLF +
       'Connection: close' + cCRLF;
    if ContentType <> '' then FHttpRespHdr := FHttpRespHdr +
       'Content-Type: ' + ContentType + cCRLF;
    if ExtraHdr <> '' then
        FHttpRespHdr := FHttpRespHdr + ExtraHdr + cCRLF;
    FHttpRespHdr := FHttpRespHdr + cCRLF;

  { create response body }
    FHtmlRespBodyLen := Length(BodyStr);
    FRespContentLength := FHtmlRespBodyLen;
    if (Length(FHtmlRespBody) <= FHtmlRespBodyLen) then
        SetLength(FHtmlRespBody, FHtmlRespBodyLen + 1);
    IcsMoveStringToTBytes(BodyStr, FHtmlRespBody, FHtmlRespBodyLen);

  { send header and body }
    LogTarEvent('Sending Response Header:' + cCRLF + FHttpRespHdr);
    SourceHdrRespXmit;
    if (FRequestMethod <> httpMethodHead) and (FHtmlRespBodyLen > 0) then begin
        LogTarEvent('Sending single-block body content, length ' +
                                   IntToStr(FHtmlRespBodyLen));
      { add body to debug log, before it was compressed }
       if FHtmlRespBodyLen < 20000 then begin
            if NOT FRespBinary then begin
                LogTarEvent('Body:'+ cCRLF + BodyStr);
            end;
        end;
        SourceBodyBufXmit;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ V8.49 create and send response error page }
procedure THttpProxyClient.TargetErrorResponse(const RespStatus, Msg: string);
var
    BodyStr: string;
begin
    BodyStr := '<HTML><HEAD><TITLE>' + RespStatus + '</TITLE></HEAD>' + cCRLF +
            '<BODY>' + cCRLF +
            '<H1>' + RespStatus + '</H1>' + Msg + '<P>' + cCRLF +
            '</BODY></HTML>' + cCRLF;
    SourceCreatePage(RespStatus, 'text/html', '', BodyStr);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ V8.49 handle  /.well-known/ directory - mini web server }
procedure THttpProxyClient.TargetWellKnown;
var
    FName, BodyStr, ContentType: string;
    I, FSize: integer;
    FHandle: THandle;
begin
    if (FRequestMethod <> httpMethodGet) then Exit;
    LogTarEvent('Handling Well-Known Request: ' + FRequestPath);

  { application event may generate a body to send, but blank contenttype }
    BodyStr := '';
    ContentType := 'text/html';
    if Assigned((FProxySource as TIcsHttpProxy).onHttpWellKnown) then begin
        (FProxySource as TIcsHttpProxy).onHttpWellKnown(FProxySource, Self, BodyStr);
        if BodyStr <> '' then ContentType := '';  // no content-type for challenge
    end;

  { nothing returned, look for file, of reasonable size }
    if BodyStr = '' then begin
        FName := IncludeTrailingPathDelimiter(FProxySource.IcsHosts[IcsHostIdx].WellKnownPath);
        FName := FName + Copy(FRequestPath, Length(WellKnownDir) + 1, 9999);
        FSize := IcsGetFileSize(FName);
        if FSize > 0 then begin
            if FSize < (FProxySource as TIcsHttpProxy).FHttpMaxBody then begin
                LogTarEvent('Attempt to open file: ' + Fname + ', Size: ' + IntToStr(FSize));
                SetLength(BodyStr, FSize);
                FHandle := FileOpen(FName, fmOpenRead + fmShareDenyWrite);
                if FHandle <> 0 then begin
                    FileSeek(FHandle, 0, sofromBeginning);
                    I := FileRead(FHandle, BodyStr[1], FSize);
                    if I <> FSize then begin
                        BodyStr := '';
                        LogTarEvent('Failed to read file: ' + Fname);
                    end
                    else begin
                        LogTarEvent('Read file OK: ' + Fname);
                        if Pos('/acme-challenge/', FRequestPath) > 1 then
                            ContentType := ''
                        else
                            ContentType := DocumentToContentType(Fname);
                    end;
                    FileClose(FHandle);
                end;
            end
            else
                LogTarEvent('File too large: ' + Fname + ', Size: ' + IntToStr(FSize));
         end;
    end;

  { create page and send it, connection closed on return }
    if BodyStr = '' then
        TargetErrorResponse('404 Not Found', 'The requested URL ' +
            TextToHtmlText(FRequestPath) + ' was not found on this server.')
    else
        SourceCreatePage('200 OK', ContentType, '', BodyStr);
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ V8.49 handle redirection }
procedure THttpProxyClient.TargetRedirection;
var
    RespStatus: String;
begin
    if FProxySource.IcsHosts[IcsHostIdx].WebRedirectURL = '' then  begin
        LogTarEvent('Redirection URL empty');
        exit;
     end;
     LogTarEvent('Handling redirection to: ' +
                                 FProxySource.IcsHosts[IcsHostIdx].WebRedirectURL);
     case FProxySource.IcsHosts[IcsHostIdx].WebRedirectStat of
        301: RespStatus := '301 Moved Permanently';
        302: RespStatus := '302 Found';
        307: RespStatus := '307 Temporary Rediect';
        308: RespStatus := '308 Permanent Rediect';
     else
        RespStatus := IntToStr(FProxySource.IcsHosts[IcsHostIdx].WebRedirectStat) + ' Unknown';
     end;
  // generally, must close connection after relocation, since port may change
     SourceCreatePage(RespStatus, 'text/html', 'Location: ' +
                         FProxySource.IcsHosts[IcsHostIdx].WebRedirectURL, '');
 end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ remote target has closed, ensure anything received is sent to client }
procedure THttpProxyClient.TargetSessionClosed(Sender: TObject; Error: Word);
begin
//    FTarConnecting := False;
    FTarClosedFlag := True;
    if (Self.State = wsConnected) and (FTarWaitTot <> 0) then
        TargetXferData;

    if (FHttpTotReqs <> FHttpTotResps) and (NOT FTunnelling) then begin
        LogTarEvent('Warning, did not receive response');
        FRespKAFlag := false;
        FDelayedDisconn := false;
    end;

    if (FProxySource.DebugLevel >= DebugConn) then begin
        if (Error = 0) or (Error = 10053) then
            LogTarEvent('Remote closed, Data sent ' +
                IntToStr(FTarSocket.WriteCount) + ', Data recvd ' + IntToStr(FTarSocket.ReadCount))
        else begin
            LogTarEvent('Remote lost (' + WSocketErrorDesc(Error) + '), Data sent ' +
                IntToStr(FTarSocket.WriteCount) + ', Data recvd ' + IntToStr(FTarSocket.ReadCount));
        end;
    end;

  { if still sending data, don't close yet }
    if FTarHttp and (NOT FTunnelling) then begin

        if NOT (FDelayedDisconn or (FRespKAFlag and
                         (FProxySource as TIcsHttpProxy).FHttpIgnoreClose)) then begin
            if ((FHttpCurrReq >= 1) and (FHttpCurrResp = FHttpCurrReq) and
                   (FHttpInfo [FHttpCurrResp].HttpReqState = httpStRespDone)) then begin
                if (FProxySource.DebugLevel >= DebugConn) then
                        LogSrcEvent('Source client will close when all data forwarded');
                FSrcPendClose := True;
            end
            else begin
             //   ReportStats (FPxyRouting.rtNextResp);
                if Self.State = wsConnected then begin
                  if (not FClosingFlag) then begin
                    if (FProxySource.DebugLevel >= DebugConn) then
                        LogSrcEvent('Source client closing after target');
                    Self.CloseDelayed;
                    FClosingFlag := True;
                  end
                  else if (FProxySource.DebugLevel >= DebugConn) then
                        LogSrcEvent('Source client already closing');
                end
                else if (FProxySource.DebugLevel >= DebugConn) then
                    LogSrcEvent('Source client already closed');
            end;
        end
        else begin  // if target was keep-alive we must close
            if FRespKAFlag then
                FSrcPendClose := True;
        end;
    end
    else begin
         if (NOT FClosingFlag) then begin
            if (FProxySource.DebugLevel >= DebugConn) then
                LogSrcEvent('Client closing after target');
            Self.CloseDelayed;
            FClosingFlag := True;
        end
        else if (FProxySource.DebugLevel >= DebugConn) then
            LogSrcEvent('Client already closing');
        FDelayedDisconn := false;
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ remove request header line, true if found and removed }
function THttpProxyClient.RemoveHdrLine(const Hdr: String; var Headers: string): boolean;
var
    P, Q: Integer;
begin
    Result := false ;
    P := Pos(cCRLF + Hdr, Headers) + 2;
    if P <= 2 then Exit;
    Q := PosEx(cCRLF, Headers, P);
    if Q > P then begin
        Delete (Headers, P, Q - P + 2);
        Result := True;
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ update request header line, false if updated, true if new header added }
function THttpProxyClient.UpdateHdrLine(const Hdr, Arg: String; var Headers: string): boolean;
var
    P, Q: Integer;
begin
    Result := false ;
    P := Pos(cCRLF + Hdr, Headers) + 2;
    if P <= 2 then begin
        Q := PosEx(cDoubleCRLF, Headers, P);
        if P > Q then Exit;  // sanity check
        Insert(cCRLF + Hdr + ' ' + Arg, Headers, Q);
        Result := True
    end
    else begin
        Q := PosEx(cCRLF, Headers, P);
        if P > Q then Exit;  // sanity check
        P := P + Length(Hdr);
        if Headers[P] = ' ' then P := P + 1;
        Headers := StuffString(Headers, P, Q - P, Arg);
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ send request header to remote target }
procedure THttpProxyClient.TargetForwardProxy;
var
    Arg: String;
    Proto, User, Pass, Host, Port, Path: String;

    procedure FindPort(AStr: String);
    var
        R: Integer;
    begin
        R := Pos(':', AStr);
        if R > 1 then begin
            FTarHost := Copy (AStr, 1, R - 1);
            FTarPort := Copy (AStr, R + 1, 5);
        end
        else begin
            FTarHost := AStr;
            FTarPort := FServerPort;
        end;
    end;

begin
  { check proxy authorisation }
    if FRequestProxyAuthorization <> '' then begin
        with FProxySource as TIcsHttpProxy do begin
            if Assigned(FonHttpPxyAuth) then begin
                if Pos ('basic ', IcsLowercase(FRequestProxyAuthorization)) = 1 then
                    Arg := Base64Decode(Copy(FRequestProxyAuthorization, 7, 999))
                else
                    Arg := FRequestProxyAuthorization;
                LogTarEvent('Testing Proxy-Authorization: ' + Arg);
                FonHttpPxyAuth(FProxySource, Self, Arg);
                if Arg = '' then begin
                    LogTarEvent('Failed Proxy-Authorization, Closing');
                    FClosingFlag := True;
                    Close;
                    Exit;
                end;
            end;
        end;
        RemoveHdrLine('Proxy-Authorization:', FHttpReqHdr) ;
        FTarReqModified := True;
    end;

  { MSIE and Firefox send an illegal header we need to remove }
    if (FRequestProxyConnection <> '') then begin
        FReqKAFlag := (Pos('Close', FRequestProxyConnection) > 0);
        RemoveHdrLine('Proxy-Connection:', FHttpReqHdr) ;
        FTarReqModified := True;
    end;

  { CONNECT method means open a transparent tunnel, usually for SSL }
    if FRequestMethod = httpMethodConnect then begin
        LogTarEvent('Tunnel requested to: ' + FRequestPath);
        LogTarEvent('Beware, no more headers will be logged');
        FindPort(FRequestPath); // check for :port, keep host and port
   { SECURITY RISK, only allow HTTP ports to stop 25, etc.  }
        if (FTarPort <> '80') and (FTarPort <> '443') then begin
            LogTarEvent('Tunnel only allowed for HTTP, not port ' + FTarPort);
            FClosingFlag := True;
            Close;
            Exit;
        end;
        FTarSsl := False;  // no SSL for tunnel itself
        FTunnelling := True; // so we don't process anything more
        FHttpReqHdr := '';   // do not forward this request, create 200 response on succesful connect
    end
    else begin
      { not CONNECT, look for absolute URL }
        ParseURL(IcsLowercase(FRequestPath), Proto, User, Pass, Host, Port, Path);
        LogTarEvent('Proxy URL: ' + FRequestPath + ', Host: ' + FRequestHost);
        FTarSsl := (Proto = 'https');
        if FTarSSL or (Proto = 'http') then begin
            if Port <> '' then begin
                FTarHost := Host;
                FTarPort := Port;
            end
            else begin
                FTarHost := Host;
                if FTarSSL then
                    FTarPort := '443'
                else
                    FTarPort := '80';
            end;

            { update HOST header with new host, or add one }
            UpdateHdrLine('Host:', Host, FHttpReqHdr);
        end

      { not absolute URL, process HOST header  }
        else if (FRequestHostName <> '') then begin
            FTarHost := FRequestHostName;
            FTarPort := FRequestHostPort;
            FTarSSL := (FTarPort = '443');
        end
        else begin
            LogTarEvent('Forward proxy failed to find Host: header, Closing');
            FClosingFlag := True;
            Close;
        end;
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ find matching proxy target, checking path }
{ returns last matching tag if no specific paths found }
function THttpProxyClient.FindPxyPathTarget(const HTag, HPath: String): Integer;
var
    I: Integer;
    LowerPath: String;
begin
    Result := -1;
    LowerPath := IcsLowerCase(HPath);  { V8.49 }
    with FProxySource do begin
        for I := 0 to ProxyTargets.Count - 1 do begin
            if NOT ProxyTargets[I].HostEnabled then Continue;
            if ProxyTargets[I].HostTag = HTag then begin
                Result := I;
                if Pos(ProxyTargets[I].FSrcPath, LowerPath) = 1 then begin
                    Exit;
                end;
             end;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ update POST data body in application event }
procedure THttpProxyClient.UpdatePostData;        { V8.50 }
var
    BodyStr: UnicodeString;   { V8.50 process in unicode }
    ArgStr, OldBody: String;  { V8.50 process in unicode }
    ACodePage: Longword;
begin
    if Assigned((FProxySource as TIcsHttpProxy).onHttpReqBody) then begin
        if (Pos ('text/', FRequestContentType) <> 1) and (Pos ('www-form', FRequestContentType) = 0) then Exit;
        ACodePage := IcsContentCodepage(FRequestContentType);

     { first, need to convert TBytes buffer into unicode string so easier to manipulate }
        BodyStr := IcsHtmlToStr(FHtmlReqBody, FHtmlReqBodyLen, ACodePage, false);  // leave entities
        ArgStr := String(BodyStr);  // event is ansi in non-unicode compilers
        OldBody := ArgStr;
        (FProxySource as TIcsHttpProxy).onHttpReqBody(FProxySource, Self, ArgStr);
        if (OldBody <> ArgStr) then begin
            BodyStr := ArgStr;
            LogTarEvent('Updated Request Body in Event');

          { now move string back into TBytes buffer with correct codepage }
            FHtmlReqBodyLen := IcsMoveStringToTBytes(BodyStr, FHtmlReqBody,
                                                Length(BodyStr), ACodePage, false);
            FRequestContentLength := FHtmlReqBodyLen;
            UpdateHdrLine('Content-Length:', IntToStr(FRequestContentLength), FHttpReqHdr);
            if (FProxySource.DebugLevel >= DebugHttpHdr) then
                LogTarEvent('Modified request new content length ' + IntToStr(FRequestContentLength));
        end;
    end ;
end ;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ update response body, checking for URLs, application event may change it as well }
procedure THttpProxyClient.UpdateBody;
var
    P, DoneNr, BOMSize: Integer;
    BodyStr: UnicodeString;   { V8.50 process in unicode }
    ArgStr, OldBody: String;  { V8.50 process in unicode }
    ACodePage: Longword;
begin
    P := IcsTBytesPos(FHttpTarURL2, FHtmlRespBody, 0, FHtmlRespBodyLen);  // URL without port
    if Assigned((FProxySource as TIcsHttpProxy).onHttpRespBody) or (P > 0) then begin

      { V8.50 find codepage, keep Bom so we can restore it later }
        BOMSize := 0;
        ACodePage := IcsContentCodepage(FRespContentType);  // first HTTP header
        if ACodePage = 0 then
            ACodePage := IcsFindHtmlCodepage(FHtmlRespBody, FHtmlRespBodyLen, BOMSize);  // then BOM or meta header

        if (FProxySource.DebugLevel >= DebugHttpHdr) then
            LogTarEvent('Checking for body content URLs, Codepage ' +
               CodePageToMimeCharsetString(ACodepage) + ', Bom size ' + IntToStr(BOMSize));

      { first, need to convert TBytes buffer into unicode string so easier to manipulate }
        BodyStr := IcsHtmlToStr(FHtmlRespBody, FHtmlRespBodyLen, ACodePage, false);  // leave entities

        DoneNr := 0;
        while (Pos(FHttpTarURL1, BodyStr) > 0) do begin   // URL with port
            DoneNr := DoneNr + 1;
            BodyStr := StringReplace(BodyStr, FHttpTarURL1, FHttpSrcURL, [rfIgnoreCase]);
            if DoneNr > 100 then break;  // sanity check, too many URLS
        end;
        while (Pos(FHttpTarURL2, BodyStr) > 0) do begin   // URL without port
            DoneNr := DoneNr + 1;
            BodyStr := StringReplace(BodyStr, FHttpTarURL2, FHttpSrcURL, [rfIgnoreCase]);
            if DoneNr > 100 then break;  // sanity check, too many URLS
        end;
        if DoneNr > 0 then begin
            if (FProxySource.DebugLevel >= DebugHttpHdr) then
                LogTarEvent('Updated ' + IntToStr(DoneNr) + ' URLs, modified body');
            FTarRespModified := True;
        end;

     { application event may process body }
        if Assigned((FProxySource as TIcsHttpProxy).onHttpRespBody) then begin
            ArgStr := String(BodyStr);  // event is ansi in non-unicode compilers
            OldBody := ArgStr;
            (FProxySource as TIcsHttpProxy).onHttpRespBody(FProxySource, Self, ArgStr);
            if (OldBody <> ArgStr) then begin
                FTarRespModified := True;
                BodyStr := ArgStr;
                LogTarEvent('Updated Response Body in Event');
            end;
        end;

      { update HTML header with new content length }
    //    FTarRespModified := True;  // TEMP testing !!!!!!!!!
        if FTarRespModified then begin
          { now move string back into TBytes buffer with correct codepage, keep Bom if it had one }
            FHtmlRespBodyLen := IcsMoveStringToTBytes(BodyStr, FHtmlRespBody,
                                                Length(BodyStr), ACodePage, (BOMSize <> 0));
            FRespContentLength := FHtmlRespBodyLen;
            UpdateHdrLine('Content-Length:', IntToStr(FRespContentLength), FHttpRespHdr);
            if (FProxySource.DebugLevel >= DebugHttpHdr) then
                LogTarEvent('Modified body new content length ' + IntToStr(FRespContentLength));
        end;
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ we don't want to process or display binary stuff, only HTML }
function CheckBinaryContent(const CType: String): Boolean;
begin
    Result := (Pos('image/', CType) > 0) OR
              (Pos('audio/', CType) > 0) OR
              (Pos('video/', CType) > 0) OR
              (Pos('/x-ms', CType) > 0) OR   // exe, etc,
              (Pos('/pdf', CType) > 0) OR  // pdf
              (Pos('/octet-stream', CType) > 0);    // exe etc
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ we only want to compress textual stuff, not binary }
function CheckTextualCotent(const CType: String): Boolean;
begin
    Result := (Pos('text/', CType) > 0) OR
              (Pos('json', CType) > 0) OR
              (Pos('javascript', CType) > 0) OR
              (Pos('xml', CType) > 0);
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ GZIP compress response body being sent back to to source to save bandwidth }
procedure THttpProxyClient.CompressBody;
 var
    ContentEncoding: String;
    InStream, OutStream: TMemoryStream;
    ZStreamType: TZStreamType;
 begin
   { skip small and big files }
    if FHtmlRespBodyLen < (FProxySource as TIcsHttpProxy).FHttpCompMinSize then Exit;
    if FHtmlRespBodyLen > CompressMaxSize then Exit;

  { only compress textual content }
    if NOT CheckTextualCotent(FRespContentType) then Exit;

    try  // except
        if (Pos('deflate', FHttpInfo [FHttpCurrResp].ReqAcceptEnc) > 0) then begin
          ContentEncoding := 'deflate';
          ZStreamType := zsRaw;
        end
        else if (Pos('gzip', FHttpInfo [FHttpCurrResp].ReqAcceptEnc) > 0) then begin
          ContentEncoding := 'gzip';
          ZStreamType := zSGZip;
        end
        else begin
            LogTarEvent('Ignored compression, unknown encoding: ' +
                                        FHttpInfo [FHttpCurrResp].ReqAcceptEnc);
            exit;
        end;

      { read into temp stream, return to same buffer  }
      { PENDING - zlib unit needs to be able to read and write buffers!!! }
        InStream := TMemoryStream.Create;
        OutStream := TMemoryStream.Create;
        try
            try
                InStream.Write (FHtmlRespBody[0], FHtmlRespBodyLen);
                InStream.Seek (0, 0); { reset to start }
                ZlibCompressStreamEx(InStream, OutStream, clDefault, ZStreamType, true);
                OutStream.Seek (0, 0); { reset to start }
                FHtmlRespBodyLen := OutStream.Size;
              { unlikely compressed version will be larger than raw... }
                if (Length(FHtmlRespBody) <= FHtmlRespBodyLen) then
                                SetLength(FHtmlRespBody, FHtmlRespBodyLen + 1);
                OutStream.ReadBuffer (FHtmlRespBody[0], FHtmlRespBodyLen);
            except
                on E:Exception do begin
                    LogTarEvent('Exception compesssing content: ' + E.Message);
                    exit;
                end;
            end;
            UpdateHdrLine('Content-Encoding:', ContentEncoding, FHttpRespHdr);
            FRespContentLength := FHtmlRespBodyLen;
            UpdateHdrLine('Content-Length:', IntToStr(FRespContentLength), FHttpRespHdr);
            FTarRespModified := True;
            if (FProxySource.DebugLevel >= DebugHttpHdr) then
                LogTarEvent('Compressed body from ' + IntToStr(InStream.Size) +
                                            ' to ' + IntToStr(FRespContentLength)) ;
        finally
            InStream.Destroy;
            OutStream.Destroy;
        end;
    except
        on E:Exception do begin
                    LogTarEvent('Exception in CompressResponse: ' + E.Message);
        end;
    end;
 end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ GZIP decompress response body sent from remote target so we can read it }
procedure THttpProxyClient.DecompressBody;
var
    InStream, OutStream: TMemoryStream;
begin
    if FRespContentEncoding  = '' then exit;
    if FHtmlRespBodyLen > CompressMaxSize then Exit;

    try  // except
        InStream := TMemoryStream.Create;
        OutStream := TMemoryStream.Create;
        try
            try
                InStream.Write(FHtmlRespBody[0], FHtmlRespBodyLen);
                InStream.Seek(0, 0); { reset to start }
                ZlibDecompressStream(InStream, OutStream);
                OutStream.Seek(0, 0); { reset to start }
                FHtmlRespBodyLen := OutStream.Size;
                FRespContentLength := FHtmlRespBodyLen;
                if (Length(FHtmlRespBody) <= FHtmlRespBodyLen) then
                                    SetLength(FHtmlRespBody, FHtmlRespBodyLen + 1);
                OutStream.ReadBuffer(FHtmlRespBody[0], FHtmlRespBodyLen);
            except
                on E:Exception do begin
                    LogTarEvent('Exception decompesssing content: ' + E.Message);
                    exit;
                end;
            end;
            RemoveHdrLine('Content-Encoding:', FHttpRespHdr);
            FRespContentEncoding := '';  // clear so we know body is uncompressed
            UpdateHdrLine('Content-Length:', IntToStr(FRespContentLength), FHttpRespHdr);
            FTarRespModified := True;
            if (FProxySource.DebugLevel >= DebugHttpHdr) then
                LogTarEvent('Decompressed body from ' + IntToStr(InStream.Size) +
                                              ' to ' + IntToStr(FRespContentLength)) ;
        finally
            InStream.Destroy;
            OutStream.Destroy;
        end;
    except
        on E:Exception do begin
            LogTarEvent('Exception in DecompresssResponse: ' + E.Message);
        end;
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure THttpProxyClient.ParseReqHdr;
var
    Line, Arg: String;
    I, J, K, L, Lines: Integer;
begin
    FRequestMethod := httpMethodNone;
    FRequestStartLine := '';
    FRequestVersion := '';
    FRequestAccept := '';
    FRequestAcceptEncoding := '';
    FRequestConnection := '';
    FRequestContentLength := 0;
    FRequestContentType := '';
    FRequestCookies := '';
    FRequestHost := '';
    FRequestHostName := '';
    FRequestHostPort := '';
    FRequestIfModSince := 0;
    FRequestKeepAlive := '';
    FRequestPath := '/';
    FRequestProxyAuthorization := '';
    FRequestProxyConnection := '';
    FRequestReferer := '';
    FRequestUpgrade := '';
    FRequestUserAgent := '';
    FReqKAFlag := True;
    FReqKASecs := 0;
    FTarReqLenRemain := 0;
    FTarReqTooLarge := false;
    FTarReqModified := false;
    FHtmlReqBodyLen := 0;

 { process one line in header at a time }
    if Length(FHttpReqHdr) <= 4 then Exit;  // sanity check
    I := 1; // start of line
    Lines := 1;
    for J := 1 to Length(FHttpReqHdr) - 2 do begin
        if (FHttpReqHdr[J] = cCR) and (FHttpReqHdr[J + 1] = cLF) then begin  // end of line
            if (J - I) <= 2 then continue;  // ignore blank line, usually at start
            Line := Copy(FHttpReqHdr, I, J - I);
            K := Pos (':', Line) + 1;
            if Lines = 1 then begin
                FRequestStartLine := Line;
                if (Pos('GET ', Line) = 1) then FRequestMethod := httpMethodGet;
                if (Pos('POST ', Line) = 1) then FRequestMethod := httpMethodPost;
                if (Pos('HEAD ', Line) = 1) then FRequestMethod := httpMethodHead;
                if (Pos('OPTIONS ', Line) = 1) then FRequestMethod := httpMethodOptions;
                if (Pos('PUT ', Line) = 1) then FRequestMethod := httpMethodPut;
                if (Pos('DELETE ', Line) = 1) then FRequestMethod := httpMethodDelete;
                if (Pos('TRACE ', Line) = 1) then FRequestMethod := httpMethodTrace;
                if (Pos('PATCH ', Line) = 1) then FRequestMethod := httpMethodPatch;
                if (Pos('CONNECT ', Line) = 1) then FRequestMethod := httpMethodConnect;
                L := Pos(' ', Line);
                If (L > 0) then Line := Copy(Line, L + 1, 99999); // strip request
                L := Pos(' HTTP/1', Line);
                if (L > 0) then begin
                    FRequestPath := Copy(Line, 1, L - 1);
                    FRequestVersion := Copy(Line, L + 1, 99999);
                end;
            end
            else if (K > 3) then begin
                Arg := IcsTrim(Copy(Line, K, 999)); // convert any arguments we scan to lower case later
                if (Pos('Accept:', Line) = 1) then FRequestAccept := Arg;
                if (Pos('Accept-Encoding:', Line) = 1) then FRequestAcceptEncoding := IcsLowercase(Arg);
                if (Pos('Connection:', Line) = 1) then FRequestConnection := IcsLowercase(Arg);   // Keep-Alive or Close
                if (Pos('Content-Length:', Line) = 1) then FRequestContentLength := atoi64(Arg);
                if (Pos('Content-Type:', Line) = 1) then FRequestContentType := IcsLowercase(Arg);
                if (Pos('Cookie:', Line) = 1) then FRequestCookies := Arg;
                if (Pos('Host:', Line) = 1) then begin
                    FRequestHost := Arg;
                    L := Pos(':', FRequestHost);
                    if L > 0 then begin
                        FRequestHostName := Copy(FRequestHost, 1, L - 1);
                        FRequestHostPort := Copy(FRequestHost, L + 1, 99);
                    end
                    else begin
                        FRequestHostName := FRequestHost;
                        FRequestHostPort := FServerPort;
                    end;
                end;
                if (Pos('If-Modified-Since:', Line) = 1) then begin
                    try
                        FRequestIfModSince := RFC1123_StrToDate(Arg);
                    except
                        FRequestIfModSince := 0;
                    end;
                end;
                if (Pos('Keep-Alive:', Line) = 1) then FRequestKeepAlive := Arg;
                if (Pos('Proxy-Authorization:', Line) = 1) then FRequestProxyAuthorization := Arg;
                if (Pos('Proxy-Connection:', Line) = 1) then FRequestProxyConnection := IcsLowercase(Arg);
                if (Pos('Referer:', Line) = 1) then FRequestReferer := IcsLowercase(Arg);
                if (Pos('Upgrade:', Line) = 1) then FRequestUpgrade := Arg;
                if (Pos('User-Agent:', Line) = 1) then FRequestUserAgent := Arg;
            end
            else begin
                if (FProxySource.DebugLevel >= DebugHttpHdr) then
                    LogTarEvent('Warning, ignored header line: ' + Line);
            end;
            Lines := Lines + 1;
            I := J + 2;  // start of next line
        end;
    end;
    if FRequestConnection <> '' then begin
        FReqKAFlag := (Pos('keep-alive', FRequestConnection) > 0);
    end;

  { we don't want to process or display binary stuff, only HTML }
    FReqBinary := CheckBinaryContent(FRespContentType);

    if (FProxySource.DebugLevel >= DebugAll) then
                LogTarEvent('Parsed request header lines, total: ' + IntToStr (Lines));
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure THttpProxyClient.ParseRespHdr;
var
    Line, Arg: String;
    I, J, K, L, Lines: Integer;
begin
    FRespStatusCode := 0;
    FRespVersion := '';
    FRespReasonPhase := '';
    FRespConnection := '';
    FRespContentEncoding := '';
    FRespContentLength := 0;
    FRespContentLenSet := False;
    FRespContentType := '';
    FRespContent := '';
    FRespCharset := '';
    FRespCookies := '';
    FRespKAFlag := False;
    FRespKASecs := 0;
    FRespKeepAlive := '';
    FRespLastModified := 0;
    FRespLocation := '';
    FRespStatusLine := '';
    FRespTransferEncoding := '';
    FHtmlRespBodyLen := 0;
    FTarRespModified := false;
    FRespBinary := false;
    FRespGzip := false;

 { process one line in header at a time }
    if Length(FHttpRespHdr) <= 4 then Exit;  // sanity check
    I := 1; // start of line
    Lines := 1;
    for J := 1 to Length(FHttpRespHdr) - 2 do begin
        if (FHttpRespHdr[J] = cCR) and (FHttpRespHdr[J + 1] = cLF) then begin  // end of line
            if (J - I) <= 2 then continue;  // ignore blank line, usually at start
            Line := Copy(FHttpRespHdr, I, J - I);
            K := Pos (':', Line) + 1;
            if Lines = 1 then begin
                FRespStatusLine := Line;
                if Pos('HTTP', Line) <> 1 then Exit;  // not a valid response header
                L := Pos (' ', Line);
                if (L > 0) then begin
                    FRespVersion := Copy(Line, 1, L - 1);
                    FRespReasonPhase := Copy(Line, L + 1, 999);
                    FRespStatusCode := atoi(FRespReasonPhase);
                end;
            end
            else if (K > 3) then begin
                Arg := Trim(Copy(Line, K, 999));  // convert any arguments we scan to lower case later
                if (Pos('Content-Encoding:', Line) = 1) then FRespContentEncoding := IcsLowercase(Arg);
                if (Pos('Connection:', Line) = 1) then FRespConnection := IcsLowercase(Arg);   // Keep-Alive or Close
                if (Pos('Content-Length:', Line) = 1) then begin
                    FRespContentLength := atoi64(Arg);
                    FRespContentLenSet :=  True;
                end;
                if (Pos('Content-Type:', Line) = 1) then begin
                    FRespContentType := IcsLowercase(Arg);
                    L := Pos('; charset=', FRespContentType);
                    if L > 1 then begin
                        FRespContent := Copy(FRespContentType, 1, L - 1);
                        FRespCharset := Copy(FRespContentType, L +  10, 99);
                    end
                    else
                        FRespContent := FRespContentType;
                end;
                if (Pos('Last-Modified:', Line) = 1) then begin
                    try
                        FRespLastModified := RFC1123_StrToDate(Arg);
                    except
                        FRespLastModified := 0;
                    end;
                end;
                if (Pos('Location:', Line) = 1) then FRespLocation := IcsLowercase(Arg);
                if (Pos('Keep-Alive:', Line) = 1) then FRespKeepAlive := Arg;
                if (Pos('Set-Cookie:', Line) = 1) then FRespCookies := Arg;
                if (Pos('Transfer-Encoding:', Line) = 1) then FRespTransferEncoding := IcsLowercase(Arg);
            end
            else begin
                if (FProxySource.DebugLevel >= DebugHttpHdr) then
                    LogTarEvent('Warning, ignored header line: ' + Line);
            end;
            Lines := Lines + 1;
            I := J + 2;  // start of next line
        end;
    end;
    if FRespConnection <> '' then begin
        FRespKAFlag := (Pos('keep-alive', FRequestConnection) > 0);
    end;

  { we don't want to process or display binary stuff, only HTML }
    FRespBinary := CheckBinaryContent(FRespContentType);

  { Content-Encoding, deflate or gzip - applied to content after unchunking }
  { beware Transfer-Encoding: gzip only relates to chunks }
    if (FRespContentEncoding <> '') then begin
        if (Pos('deflate', FRespContentEncoding) > 0) or
             (Pos('gzip', FRespContentEncoding) > 0) or
               (Pos('compress', FRespContentEncoding) > 0) then begin
            FRespGzip := True;
        end;
    end;

    if (FProxySource.DebugLevel >= DebugAll) then
                LogTarEvent('Parsed response header lines, total: ' + IntToStr (Lines));
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ receive data from source server, process request headers, and send to remote target }
procedure THttpProxyClient.SourceXferData;
var
    LoopCounter, HdrLen, NewLen, I: Integer;
    S: String;
begin
    LoopCounter := 0;
    if (FProxySource.DebugLevel >= DebugAll) then
        LogTarEvent('Forwarding data to target');
    while TRUE do begin
        inc (LoopCounter);
        if (LoopCounter > 100) then Exit;  // sanity check
//        if (FTarSocket.State <> wsConnected) then Exit;
        SourceBufRecv;  { read anything pending }

      { not HTTP, just send it }
        if (NOT FTarHttp) or FTunnelling then begin
            if (FSrcWaitTot = 0) then Exit;  // nothing to process
            TargetBufXmit(FSrcWaitTot);
            Exit;
        end;

      { waiting for headers to arrive }
        if FPxyReqState = PxyHdrFind then begin
            if (FSrcWaitTot = 0) then Exit;  // nothing to process

          { search for blank line in receive buffer which means we have complete request header }
            HdrLen := IcsTBytesPos(cDoubleCRLF, FSrcBuffer, 0, FSrcWaitTot);
            if (HdrLen <= 0) then begin
                if (FProxySource.DebugLevel >= DebugAll) then LogTarEvent('Waiting for more source data');
                Exit;
            end ;
            HdrLen := HdrLen + 4; // add blank line length
            FPxyReqState := PxyNoBody;  // assume no body, check length later
            inc (FHttpTotReqs);

          { keep headers in string so they are easier to process, remove from receive buffer  }
            SetLength(FHttpReqHdr, HdrLen);
            IcsMoveTBytesToString(FSrcBuffer, 0, FHttpReqHdr, 1, HdrLen);
            FSrcWaitTot := FSrcWaitTot - HdrLen;
            if FSrcWaitTot > 0 then
                IcsMoveTBytes(FSrcBuffer, HdrLen, 0, FSrcWaitTot);

           { keep all header arguments }
            ParseReqHdr;
            if (FRequestMethod = httpMethodNone) then begin
                if (FProxySource.DebugLevel >= DebugHttpHdr) then
                    LogTarEvent('No HTTP header fields found, sending anyway');
               { send request header to remote target }
                TargetHdrReqXmit;
                Exit;
            end ;

          { increment request pipeline and keep it, client may send us several requests
            without waiting for responses, so we need to keep stuff to process responses
            correctly }
            if FHttpCurrReq < 1 then begin
                FHttpCurrReq := 1;
            end
            else begin
                if FHttpInfo[FHttpCurrReq].HttpReqState <> httpStReqStart then begin
                    inc (FHttpCurrReq);
                    inc (FHttpWaiting) ;
                    if (FHttpWaiting > 1) and (FProxySource.DebugLevel >= DebugHttpHdr) then
                        LogTarEvent('Pipe Lining Requests, Depth ' + IntToStr(FHttpWaiting)) ;
                    if FHttpCurrReq > MaxPipelineReqs then FHttpCurrReq := 1;
                end;
            end;
            with FHttpInfo[FHttpCurrReq] do begin
                HttpReqState := httpStReqHdrWait;  // request and response
                TickReqStart := IcsGetTickCount;
                TickReqSend := 0;
                TickWaitResp := 0;
                TickRespStart := 0;
                TickRespBody := 0;
                TickRespSend := 0;
                TickRespDone := 0;
                TickRespEnd := 0;
                HttpReqMethod := FRequestMethod;
                ReqStartLine := FRequestStartLine;
                ReqContentLen := FRequestContentLength;
                ReqAcceptEnc := FRequestAcceptEncoding;
            end;

         { tell user what we got }
            if (FProxySource.DebugLevel >= DebugHttpHdr) then
                LogTarEvent('Original Request Header: #' +
                            IntToStr(FHttpTotReqs) + cCRLF + FHttpReqHdr)
            else if (FProxySource.DebugLevel >= DebugConn) then
                LogTarEvent('Request: #' + IntToStr(FHttpTotReqs) + ': ' + FRequestStartLine);

          { application event may process header and update parsed fields  }
            if Assigned((FProxySource as TIcsHttpProxy).onHttpReqHdr) then begin
                (FProxySource as TIcsHttpProxy).onHttpReqHdr(FProxySource, Self, FHttpReqHdr);
            end;

          { V8.49 handle redirection, don't need a target }
            if FProxySource.IcsHosts[IcsHostIdx].WebRedirectStat <> 0 then begin
                TargetRedirection;
                FClosingFlag := True;
                Close;
                exit;
            end;

          { first check Host: to find correct source and target }
            if (NOT FForwardPrxy) and (FSrcHost <> FRequestHostName) then begin
                FSrcHost := FRequestHostName;
                I := FProxySource.FindPxySourceHost(FSrcHost, Self.MultiListenIdx);
                if I >= 0 then begin
                    Self.FIcsHostIdx := I ;
                    Self.FHostTag := FProxySource.IcsHosts[I].HostTag;
                    TargetCheck;   // logs hostidx, find new target
                    if FClosingFlag then Exit;
                    with FProxySource.ProxyTargets[FPxyTargetIdx] do begin
                        if SrcPath <> '' then FTarConditional := True;
                        Self.FUpdateHttp := FUpdateHttp;
                        Self.FUpdateHtml := FUpdateHttp;
                    end;
                end else begin
                    LogSrcEvent('No target - host not supported: ' + FSrcHost);  { V8.49 }
                end;
             end;

          { V8.49 look for /.well-known/ directory, which we handle locally }
            if FProxySource.IcsHosts[IcsHostIdx].WellKnownPath <> '' then begin
                if Pos (WellKnownDir, IcsLowercase(FRequestPath)) = 1 then begin
                    TargetWellKnown;
                    FClosingFlag := True;
                    Close;
                    exit;
                end;
            end;

          { check path for conditional stuff }
          { may exit here, and then come back and reprocess buffer again after target answers }
            if FTarConditional AND (FLastReqPath <> FRequestPath) then begin

              { forward proxy, get target from CONNECT method or HOST header  }
                if FForwardPrxy then begin
                   TargetForwardProxy;
                   if FClosingFlag then Exit;  // error
                end

               { not forward proxy, look for conditional forwarders based on the path }
               { V8.49 ignore request type }
                else begin
                    if (FProxySource.DebugLevel >= DebugHttpHdr) then
                        LogSrcEvent('Checking conditional forwarding for ' + FRequestPath);
                    FPxyTargetIdx := FindPxyPathTarget(HostTag, FRequestPath);
                    if FPxyTargetIdx < 0 then begin  { should have been checked earlier }
                        if (FProxySource.DebugLevel >= DebugConn) then
                                LogSrcEvent('Host #' + IntToStr(IcsHostIdx) + ' -' +
                                        HostTag + ', no matching proxy target found for Path: ' + FRequestPath);
                        FClosingFlag := True;
                        Close;
                        exit;
                    end;
                    TargetSpecify;
                end;
            end;

         { if this a new targert }
            if (FTarSocket.State <> wsConnected) or (FTarHost <> FTarCurHost) or
                                                (FTarPort <> FTarSocket.Port) then begin

              { do we need to disconnect existing session }
                if (FTarSocket.State = wsConnected) then begin
                    LogTarEvent('Target disconnecting ready for new host');
                    FDelayedDisconn := true;
                    FTarSocket.Close;
                    FDelayedDisconn := false;
                end;

              { start connection to target server, request won't be sent until later once target connects }
                if NOT FForwardPrxy then TargetSpecify;    // logs target #
                FTarSocket.Counter.SetConnected;
                if NOT TargetConnect then begin
                    if FTarHttp then TargetErrorResponse('502 Bad Gateway',
                            'The gateway can not connect to the requested server: ' + FTarHost);
                    FClosingFlag := True;
                    Close;
                    Exit;
                end;
            end;

          { sanity text }
            if (FTarHost = '') then begin
                LogSrcEvent('Host #' + IntToStr(IcsHostIdx) + ' -' +
                      HostTag + ', failed to find new target host, closing');
                FClosingFlag := True;
                Close;
                exit;
            end;

          { look for Content-Length header, keep size, POST only  }
            if FRequestContentLength > 1 then begin
                FHttpInfo[FHttpCurrReq].ReqContentLen := FRequestContentLength;
                FPxyReqState := PxyLenEnd;
                FTarReqLenRemain := FRequestContentLength;
                FHtmlReqBodyLen := 0;
                if FRequestContentLength > (FProxySource as TIcsHttpProxy).FHttpMaxBody then
                    FTarReqTooLarge := true
                else
                    SetLength(FHtmlReqBody, FTarReqLenRemain);
                if (FProxySource.DebugLevel >= DebugHttpHdr) then
                            LogTarEvent('Got headers, expected POST request content-length=' + IntToStr(FRequestContentLength));
            end;

          { see if allowed to update headers }
            if FUpdateHttp then begin

              { update Host: and Referrer: headers to those of target }
                if (FRequestHostName <> FTarHost) then begin
                    UpdateHdrLine('Host:', FTarHost, FHttpReqHdr);
                    FTarReqModified := True;
                    if (FProxySource.DebugLevel >= DebugHttpHdr) then
                             LogTarEvent('Updated Host header to: ' + FTarHost);
                  // pending update referrer - may need to change http<>https
                    if FRequestReferer <> '' then begin
                        if Pos (FHttpSrcURL, FRequestReferer) > 0 then begin
                            S := StringReplace(FRequestReferer, FHttpSrcURL, FHttpTarURL1, [rfReplaceAll]);
                            UpdateHdrLine('Referer:', S, FHttpReqHdr);
                            FTarReqModified := True;
                            if (FProxySource.DebugLevel >= DebugHttpHdr) then
                                LogTarEvent('Updated Referer Header from: ' + FRequestReferer + ', to: ' + S);
                        end;
                    end;
                end;

              { look for Accept-Encoding: header, may need to remove it }
                if (FRequestAcceptEncoding <> '') and (NOT FForwardPrxy) then begin
                    if NOT (FProxySource as TIcsHttpProxy).FHttpTarCompress then begin  // don't support GZIP of target responses
                        if RemoveHdrLine('Accept-Encoding:', FHttpReqHdr) then begin
                            FTarReqModified := True;
                            if (FProxySource.DebugLevel >= DebugHttpHdr) then
                                  LogTarEvent('Removed Accept-Encoding: header') ;
                        end;
                    end;
                end
                else begin
                 // pending  - should we add new Accept-Encoding:
                 // if FProxySource.FHttpTarCompress then begin
                end;

              { Keep Alive - remove or update request Connection: header and related Keep-Alive header }
                if (FRequestConnection <> '') and (FProxySource as TIcsHttpProxy).FHttpIgnoreClose then begin
                    if (NOT FRespKAFlag) then begin
                        UpdateHdrLine('Connection:', 'Keep-Alive', FHttpReqHdr);
                        FTarReqModified := True;
                        if (FProxySource.DebugLevel >= DebugHttpHdr) then
                            LogTarEvent('Changed connection header to Keep-Alive');
                    end
                    else begin
                        UpdateHdrLine('Connection:', 'Close', FHttpReqHdr);
                        if (FProxySource.DebugLevel >= DebugHttpHdr) then
                            LogTarEvent('Changed connection header to Close');
                         RemoveHdrLine('Keep-Alive:', FHttpReqHdr);
                         FTarReqModified := True;
                   end
                end
                else begin
                    if (NOT FRespKAFlag) then begin
                        UpdateHdrLine('Connection:', 'Keep-Alive', FHttpReqHdr);
                        if (FProxySource.DebugLevel >= DebugHttpHdr) then
                            LogTarEvent('Added new header: Connection: Keep-Alive');
                        FTarReqModified := True;
                    end;
                end;

              { see if removing conditional headers to force server to return data  }
                if (FRequestIfModSince > 0) and (FProxySource as TIcsHttpProxy).FHttpStopCached then begin
                    if RemoveHdrLine('If-Modified-Since:', FHttpReqHdr) then begin
                        RemoveHdrLine('If-None-Match:', FHttpReqHdr);
                        FTarReqModified := True;
                        if (FProxySource.DebugLevel >= DebugHttpHdr) then
                            LogTarEvent('Removed If-Modified-Since: to stop cached response');
                    end;
                end;

              { see if removeing Upgrade header to stop HTTP/2 }
                if (FProxySource as TIcsHttpProxy).FHttpStripUpgrade then begin
                    if (FRequestUpgrade <> '') then begin
                        if RemoveHdrLine('Upgrade:', FHttpReqHdr) then begin
                            FTarReqModified := True;
                            if (FProxySource.DebugLevel >= DebugHttpHdr) then
                                LogTarEvent('Removed Upgrade: ' + FRequestUpgrade);
                        end;
                    end;
                 { stop server redirecting to SSL site }
                    if RemoveHdrLine('Upgrade-Insecure-Requests:', FHttpReqHdr) then begin
                        FTarReqModified := True;
                        if (FProxySource.DebugLevel >= DebugHttpHdr) then
                            LogTarEvent('Removed Upgrade-Insecure-Requests: header to stop SSL');
                    end;
                end;
            end;

        end;

      { can not send anything, will return here once connected }
        if (FTarSocket.State <> wsConnected) then Exit ;

     { send request header to remote target, once connected }
        if (FPxyReqState > PxyHdrFind) and
                 (FHttpInfo[FHttpCurrReq].HttpReqState = httpStReqHdrWait) then begin
           if FTarReqModified and (FProxySource.DebugLevel >= DebugHttpHdr) then
                LogTarEvent('Modified Request Header: #' +
                            IntToStr(FHttpTotReqs) + cCRLF + FHttpReqHdr);
            TargetHdrReqXmit;
            FHttpInfo[FHttpCurrReq].HttpReqState := httpStWaitResp;
        end;

    { POST content according to length in header }
        if FPxyReqState = PxyLenEnd then begin
            if FSrcWaitTot = 0 then Exit;  // nothing to send
            NewLen := FSrcWaitTot;
            if (NewLen > FTarReqLenRemain) then
                NewLen := FTarReqLenRemain;  // might have body and next header
            FTarReqLenRemain := FTarReqLenRemain - NewLen;

          { if POST content more than 5MB, just send it without processing }
            if FTarReqTooLarge then begin
                TargetBufXmit(NewLen);
            end
            else begin
          // keep POST content in buffer and remove from receive buffer
                IcsMoveTBytesEx(FSrcBuffer, FHtmlReqBody, 0, FHtmlReqBodyLen, NewLen);   // build body buffer
                FHtmlReqBodyLen := FHtmlReqBodyLen + NewLen;
                FSrcWaitTot := FSrcWaitTot - NewLen;
                if FSrcWaitTot > 0 then
                    IcsMoveTBytes(FSrcBuffer, NewLen, 0, FSrcWaitTot);  // remove from receive buffer
                if (FProxySource.DebugLevel >= DebugAll) then
                    LogTarEvent('Building POST body, Length ' + IntToStr(FRequestContentLength) +
                     ', Added ' + IntToStr(NewLen) +  ', Remaining ' + IntToStr(FTarReqLenRemain) +
                     ', Left Over ' + IntToStr(FSrcWaitTot)) ;

            // got whole POST content, send it to target
                if (FTarReqLenRemain <= 0) then begin
                    if (FProxySource.DebugLevel >= DebugHttpHdr) then
                        LogTarEvent('Finished request content, length=' + IntToStr(FRequestContentLength));

                { application event may process upload post data }
                    if Assigned((FProxySource as TIcsHttpProxy).onHttpReqBody) and FUpdateHtml then begin
                        UpdatePostData;    { V8.50 }
                    end;

                    if (FProxySource.DebugLevel >= DebugHttpBody) then begin
                        if NOT FReqBinary then begin
                            NewLen := FHtmlReqBodyLen;
                            if NewLen > MaxBodyDumpSize then NewLen := MaxBodyDumpSize;
                            SetLength(S, NewLen);
                            IcsMoveTBytesToString(FHtmlReqBody, 0, S, 1, NewLen);
                            if NewLen = MaxBodyDumpSize then S := S + cCRLF + '!!! TRUNCATED !!!';
                            LogTarEvent('Body:'+ cCRLF + S);
                        end;
                    end;
                    TargetBodyXmit;
                    FPxyReqState := PxyHdrFind;  // reset state for next request header
                    LoopCounter := 0;
                end
             end;
        end;


    // no request body, send header
        if FPxyReqState = PxyNoBody then begin
            if (FProxySource.DebugLevel >= DebugHttpHdr) then
                            LogTarEvent('Finished request, zero content');
            FPxyReqState := PxyHdrFind;  // reset state for next request header
        end;

     { should never get this state }
        if FPxyReqState = PxyClosed then begin
            Exit;
        end;

    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ receive data from remote target, process response headers, and send to source client }
procedure THttpProxyClient.TargetXferData;
var
    LoopCounter, HdrLen, NewLen, LineLen, P: Integer;
    S, BodyStr: String;

   { send response header to source client }
    procedure SendRespHdr;
    begin
        if FHttpInfo [FHttpCurrResp].HttpReqState <> httpStRespHdrWait then Exit;
        if FTarRespModified and (FProxySource.DebugLevel >= DebugHttpHdr) then
            LogTarEvent('Modified Response Header: #' +
                        IntToStr(FHttpTotResps) + cCRLF + FHttpRespHdr);
        SourceHdrRespXmit;
        FHttpInfo [FHttpCurrResp].HttpReqState := httpStRespSend;
    end;

    procedure DoneResponse;
    begin
        FHtmlRespBodyLen := 0;
        if FHttpInfo [FHttpCurrResp].HttpReqState = httpStRespSend then begin
            FHttpInfo [FHttpCurrResp].HttpReqState := httpStRespDone;
            FHttpInfo [FHttpCurrResp].TickRespDone := IcsGetTickCount;
        end;
    end;

begin
    LoopCounter := 0;
    if (FProxySource.DebugLevel >= DebugAll) then LogTarEvent('Forwarding data to source');
    while TRUE do begin
        inc (LoopCounter);
        if (LoopCounter > 100) then Exit;  // sanity check
        if (Self.State <> wsConnected) then Exit;
        TargetBufRecv;  { read anything pending }

      { not HTTP, just send it }
        if (NOT FTarHttp) or FTunnelling then begin
            if (FTarWaitTot = 0) then Exit;  // nothing to process
            SourceBufXmit(FTarWaitTot);
            Exit;
        end;

      { waiting for headers to arrive }
        if FPxyRespState = PxyHdrFind then begin
            if (FTarWaitTot = 0) then Exit;  // nothing to process

          { search for blank line in receive buffer which means we have complete request header }
            HdrLen := IcsTBytesPos(cDoubleCRLF, FTarBuffer, 0, FTarWaitTot);
            if (HdrLen <= 0) then begin
                if (FProxySource.DebugLevel >= DebugAll) then LogTarEvent('Waiting for more target data');
                Exit;
            end ;
            HdrLen := HdrLen + 4; // add blank line length
            FPxyRespState := PxyNoBody;  // assume no body, check length later
            inc (FHttpTotResps);

          { keep headers in string so they are easier to process, remove from receive buffer  }
            SetLength(FHttpRespHdr, HdrLen);
            IcsMoveTBytesToString(FTarBuffer, 0, FHttpRespHdr, 1, HdrLen);
            FTarWaitTot := FTarWaitTot - HdrLen;
            if FTarWaitTot > 0 then
                IcsMoveTBytes(FTarBuffer, HdrLen, 0, FTarWaitTot);

           { keep all header arguments, give up if none found }
            ParseRespHdr;
            if (FRespStatusCode = 0) then begin
                if (FProxySource.DebugLevel >= DebugHttpHdr) then
                    LogTarEvent('No HTTP header fields found, sending anyway');
               { send response header to source client }
                SourceHdrRespXmit;
                Exit;
            end ;

          { update pipeline responses }
            FHtmlRespBodyLen := 0;
            FTarRespLenRemain := 0;
            FChunkRcvd := 0;
            FChunkTot := 0;      // how many chunks in page
            inc (FHttpCurrResp);
            if FHttpCurrResp > MaxPipelineReqs then FHttpCurrResp := 1;
            if FHttpWaiting > 0 then dec (FHttpWaiting) ;
            FHttpInfo [FHttpCurrResp].HttpReqState := httpStRespStart;
            FHttpInfo [FHttpCurrResp].TickRespStart := IcsGetTickCount;

          { tell user what we got }
            if (FProxySource.DebugLevel >= DebugHttpHdr) then
                LogTarEvent('Original Response Header: #' + IntToStr(FHttpTotResps) +
                  ', for Request: ' + FHttpInfo [FHttpCurrResp].ReqStartLine + cCRLF + FHttpRespHdr)
            else if (FProxySource.DebugLevel >= DebugConn) then
                LogTarEvent('Response: #' + IntToStr(FHttpTotResps) + ', for: ' +
                   FHttpInfo [FHttpCurrResp].ReqStartLine + ', Status: ' +
                     FRespStatusLine + ', Length: ' + IntToStr(FRespContentLength));

          { application event may process header and update parsed fields  }
            if Assigned((FProxySource as TIcsHttpProxy).onHttpRespHdr) then begin
                (FProxySource as TIcsHttpProxy).onHttpRespHdr(FProxySource, Self, FHttpRespHdr);
            end;

         { Transfer-Encoding may be chunked, deflate or gzip - after checking content length }
         { note Transfer-Encoding: chunked and Content-Encoding: gzip is common, uncompress after unchunk }
            if (FRespTransferEncoding <> '') then begin
                FChunkGzip := false;
                if (Pos('deflate', FRespTransferEncoding) > 0) or
                      (Pos('gzip', FRespTransferEncoding) > 0) or
                         (Pos('compress', FRespTransferEncoding) > 0) then begin
                    FChunkGzip := True;
                    LogTarEvent('Expecting compressed chunks');
                end;
                if (Pos('chunked', FRespTransferEncoding) > 0) then begin
                    if (Pos('image/', FRespContentType) > 0) then   { because we don't parse images }
                        LogTarEvent('Ignored chunked image')
                    else begin
                        FPxyRespState := PxyCnkEnd;
                        FChunkState := PxyChunkGetSize;
                        SetLength(FHtmlRespBody, (FProxySource as TIcsHttpProxy).FHttpMaxBody);
                        LogTarEvent('Expecting multiple body chunks');
                    end;
                end;

             { not found a way to test this combination, so cheat for now }
                if FChunkGzip and (FPxyRespState = PxyCnkEnd) then begin
                    FRespGzip := True;
                    FChunkGzip := false;
                    LogTarEvent('!!! Warning, not tested compressed chunks, will attempt content decompress');
                end;
            end;

          { if not chunked, look for Content-Length header, keep size  }
            if FPxyRespState <> PxyCnkEnd then begin
                if FRespContentLength > 0 then begin
                 { ignore actual content with HEAD request }
                    if FHttpInfo [FHttpCurrResp].HttpReqMethod <> httpMethodHead then begin
                        FPxyRespState := PxyLenEnd;
                        FTarRespLenRemain := FRespContentLength;
                        if FRespContentLength > (FProxySource as TIcsHttpProxy).FHttpMaxBody then
                            FTarRespTooLarge := true
                        else
                            SetLength(FHtmlRespBody, FTarRespLenRemain);
                        if (FProxySource.DebugLevel >= DebugHttpHdr) then
                                LogTarEvent('Expected body content length ' +
                                                            IntToStr(FRespContentLength));
                    end
                    else
                        FPxyRespState := PxyNoBody;  // for HEAD
                end
                else begin
                    if FRespContentLenSet or
                        (FRespStatusCode = 204) or (FRespStatusCode = 205) or
                          (FRespStatusCode = 304) or (FRespStatusCode = 400) then begin
                        FPxyRespState := PxyNoBody;
                        if FUpdateHttp and (NOT FRespContentLenSet) then begin
                            UpdateHdrLine('Content-Length:', '0', FHttpRespHdr);  // add zero content length header
                            FTarRespModified := True;
                            if (FProxySource.DebugLevel >= DebugHttpHdr) then
                                LogTarEvent('No content length found, added zero length');
                        end;
                    end
                    else begin
                        FPxyRespState := PxyGetBody;
                        FSrcPendClose := True;  // close after response
                        FTarRespLenRemain := $7FFFFFFFFFFFFFFF;  // aka MaxInt64
                        SetLength(FHtmlRespBody, (FProxySource as TIcsHttpProxy).FHttpMaxBody);
                        if FUpdateHttp then begin
                            RemoveHdrLine('Connection:', FHttpRespHdr);
                            FTarRespModified := True;
                            if (FProxySource.DebugLevel >= DebugHttpHdr) then
                                LogTarEvent('No content length found, will close connection');
                        end;
                    end;
                end;
            end;

          { may need to change Location: header http<>https and or fix host }
            if (FRespLocation <> '') and FUpdateHttp  then begin
                if Pos (FHttpTarURL1, FRespLocation) > 0 then begin   // URL with port
                    S := StringReplace(FRespLocation, FHttpTarURL1, FHttpSrcURL, [rfReplaceAll]);
                    UpdateHdrLine('Location:', S, FHttpRespHdr);
                    FTarRespModified := True;
                    if (FProxySource.DebugLevel >= DebugHttpHdr) then
                        LogTarEvent('Updated Location Header from: ' + FRespLocation + ', to: ' + S);
                    FRespLocation := S;
                end;
                if Pos (FHttpTarURL2, FRespLocation) > 0 then begin   // URL without port
                    S := StringReplace(FRespLocation, FHttpTarURL2, FHttpSrcURL, [rfReplaceAll]);
                    UpdateHdrLine('Location:', S, FHttpRespHdr);
                    FTarRespModified := True;
                    if (FProxySource.DebugLevel >= DebugHttpHdr) then
                        LogTarEvent('Updated Location Header from: ' + FRespLocation + ', to: ' + S);
                    FRespLocation := S;
                end;
            end ;

         { Connection: Close effects keep alive }
            if (FRespConnection <> '') then begin
                if NOT FRespKAFlag then begin
                    if (FProxySource.DebugLevel >= DebugHttpHdr) then
                        LogTarEvent('Remote target connection should close after this response');

                  { change header to keep-alive, don't close local client yet  }
                    if FRespKAFlag and ((FProxySource as TIcsHttpProxy).FHttpIgnoreClose) and
                                                                            FUpdateHttp then begin
                        UpdateHdrLine('Connection:', 'Keep-Alive', FHttpRespHdr);
                        FTarRespModified := True;
                        if (FProxySource.DebugLevel >= DebugHttpHdr) then
                            LogTarEvent('Changed connection header to Keep-Alive');
                    end
                    else
                        FSrcPendClose := True;  // close after response
                end
            end
            else begin
              { don't mess with authentication requests  }
                if FRespStatusCode = 401 then
                    FRespKAFlag := true
                else begin
                    FRespKAFlag := false;
                    FSrcPendClose := True;  // close after response
                    if (FProxySource.DebugLevel >= DebugAll) then
                        LogTarEvent('No Connection: header found, disable Keep-Alive');
                end;
            end;

            FHttpInfo [FHttpCurrResp].HttpReqState := httpStRespHdrWait;
        end;

      { can not send anything }
        if (Self.State <> wsConnected) then Exit ;

      { keep lots of short chunks in FHtmlRespBody TBytes buffer }
        if (FPxyRespState = PxyCnkEnd) then begin
            while TRUE do begin
                Inc(LoopCounter);
                if LoopCounter > 100 then exit;  // sanity check

              { get chunk size, short line with single word hex, ie 5ee5 }
                if (FChunkState = PxyChunkGetSize) and (FTarWaitTot > 2) then begin
                    LineLen := IcsTBytesPos(cCRLF, FTarBuffer, 0, FTarWaitTot);
                    if LineLen < 1 then Break;  // not found a line end
                    SetLength(S, LineLen);
                    IcsMoveTBytesToString(FTarBuffer, 0, S, 1, LineLen);  // get line
                    LineLen := LineLen + 2; // add CRLF
                     if FTarWaitTot > LineLen then
                        FTarWaitTot := FTarWaitTot - LineLen  // gone from buffer
                    else
                        FTarWaitTot := 0;
                    if FTarWaitTot > 0 then
                        IcsMoveTBytes(FTarBuffer, LineLen, 0, FTarWaitTot);  // remove from receive buffer
                    P := Pos(';', S);  // strip off Chunk Extension
                    if P > 1 then SetLength(S, P - 1);
                    NewLen := htoin(PChar(S), Length(S));
                    if (NewLen < 0) or (NewLen > 20000000) then begin  // 20MB snaity check
                        LogTarEvent('!! Warning, invalid chunk encoding length: ' +
                                                         S + ' (' + IntToStr(NewLen) + ')');
                        if (FProxySource.DebugLevel >= DebugAll) then begin
                            SetLength(S, FTarWaitTot);
                            IcsMoveTBytesToString(FTarBuffer, 0, S, 1, FTarWaitTot);
                            LogTarEvent('Raw Chunked Data, Len=' + IntToStr(FTarWaitTot) + cCRLF + S);
                          end;
                        FPxyRespState := PxyGetBody;  // stop chunk processing
                        Break;
                    end

                  { zero size is end of response, but may be followed by trailer header fields, wait for blank line }
                    else if NewLen = 0 then begin
                        if FTarWaitTot = 2 then begin
                            // check for CRLF ??
                            FTarWaitTot := 0;   // remove trailing CRLF
                        end;
                        FChunkState := PxyChunkDone;
                        if (FProxySource.DebugLevel >= DebugAll) then LogTarEvent('End of chunked data');
                    end

                  { got chunk length, get ready to read it }
                    else begin
                        FChunkState := PxyChunkGetData;
                        FChunkRcvd := NewLen;

                      { increase buffer to take chunk, it was initially 1MB }
                        while (Length(FHtmlRespBody) <= (FHtmlRespBodyLen + FChunkRcvd)) do
                            SetLength(FHtmlRespBody, Length(FHtmlRespBody) * 2);

                        LoopCounter := 0;
                        if (FProxySource.DebugLevel >= DebugChunks) then
                            LogTarEvent('Extracting chunk, size=' + IntToStr(FChunkRcvd) +
                                ', new content-len=' + IntToStr(FHtmlRespBodyLen + FChunkRcvd)) ;
                    end;
                end;

              { keep chunk data block }
                if FChunkState = PxyChunkGetData then begin
                    NewLen := FTarWaitTot;
                    if (NewLen > FChunkRcvd) then
                        NewLen := FChunkRcvd;  // might have two chunks
                    FChunkRcvd := FChunkRcvd - NewLen;

                  { keep it in FHtmlRespBody, remove from receive buffer }
                    IcsMoveTBytesEx(FTarBuffer, FHtmlRespBody, 0, FHtmlRespBodyLen, NewLen);   // build body buffer
                    FHtmlRespBodyLen := FHtmlRespBodyLen + NewLen;
                    if (FChunkRcvd <= 0) then NewLen := NewLen + 2; // add trailing CRLF
                     if FTarWaitTot > NewLen then
                        FTarWaitTot := FTarWaitTot - NewLen  // gone from buffer
                    else
                        FTarWaitTot := 0;
                    if FTarWaitTot > 0 then
                        IcsMoveTBytes(FTarBuffer, NewLen, 0, FTarWaitTot);  // remove from receive buffer

                  { whole chunked data block is available }
                    if (FChunkRcvd <= 0) then begin
                      { ??? chunk might be compressed, not found a server to test against yet }
                        inc (FChunkTot);
                        FChunkState := PxyChunkGetSize;
                    end

                  { need to wait for more chunked data to arrive }
                    else begin
                        if (FProxySource.DebugLevel >= DebugAll)  then
                            LogTarEvent('Waiting for more chunked data');  // !! TEMP
                        Exit;
                    end;
                end;

              { finished getting all data, remove 'chunked', add Content-Length header }
                if FChunkState = PxyChunkDone then begin
                    RemoveHdrLine('Transfer-Encoding:', FHttpRespHdr);

                    if (FTarWaitTot <> 0) then begin
                        if (FProxySource.DebugLevel >= DebugHttpHdr)  then begin
                            SetLength(S, FTarWaitTot);
                            IcsMoveTBytesToString(FTarBuffer, 0, S, 1, FTarWaitTot);
                            LogTarEvent('!! Still got chunked content, len=' + IntToStr(FTarWaitTot) + ', Data: ' + S);
                        end;
                    end;
                    FRespContentLength := FHtmlRespBodyLen;
                    UpdateHdrLine('Content-Length:', IntToStr(FRespContentLength), FHttpRespHdr);
                    FTarRespModified := True;
                    if (FProxySource.DebugLevel >= DebugHttpHdr)  then begin
                        LogTarEvent('Unchunked content, total chunks=' + IntToStr(FChunkTot) +
                        ', removed Encoding header, added body content length ' + IntToStr(FRespContentLength));
                    end;
                    FPxyRespState := PxySendBody;
                    Break;
                end;
            end;
        end

      { keep body content in FHtmlRespBody TBytes buffer }
        else if (FPxyRespState = PxyLenEnd) or (FPxyRespState = PxyGetBody) then begin
            if FTarWaitTot = 0 then Exit;  // nothing to send
            NewLen := FTarWaitTot;
            if (NewLen > FTarRespLenRemain) then
                NewLen := FTarRespLenRemain;  // might have body and next header
            FTarRespLenRemain := FTarRespLenRemain - NewLen;

          { if content large, just send it without processing, better response for browser }
            if FTarRespTooLarge then begin
             // send response header now, only once, then partial body
                if (FHttpInfo [FHttpCurrResp].HttpReqState = httpStRespHdrWait) then begin
                    SendRespHdr;
                    if (FProxySource.DebugLevel >= DebugHttpHdr) then
                        LogTarEvent('Sending multi-block body content, length ' +
                                                   IntToStr(FRespContentLength));
                end;
                SourceBufXmit(NewLen);

            { got whole body content or target closed, send it to target }
                if (FTarRespLenRemain <= 0) or FTarClosedFlag then begin
                    FPxyRespState := PxyHdrFind;  // reset state for next response header
                    LoopCounter := 0;
                    DoneResponse;
                    if (FProxySource.DebugLevel >= DebugConn) then
                        LogTarEvent('Finished sending multi-block response');
                end;
            end
            else begin

             { increase buffer size for vatiable length pages }
                while (Length(FHtmlRespBody) <= (FHtmlRespBodyLen + NewLen)) do
                            SetLength(FHtmlRespBody, Length(FHtmlRespBody) * 2);

             { keep body content in buffer and remove from receive buffer }
                IcsMoveTBytesEx(FTarBuffer, FHtmlRespBody, 0, FHtmlRespBodyLen, NewLen);   // build body buffer
                FHtmlRespBodyLen := FHtmlRespBodyLen + NewLen;
                FTarWaitTot := FTarWaitTot - NewLen;
                if FTarWaitTot < 0 then begin
                    LogTarEvent('!! Invalid FTarWaitTot: ' + IntToStr(FTarWaitTot));  // TEMP
                    FTarWaitTot := 0;  // sanity check
                end;
                if FTarWaitTot > 0 then
                    IcsMoveTBytes(FTarBuffer, NewLen, 0, FTarWaitTot);  // remove from receive buffer
                if (FProxySource.DebugLevel >= DebugAll) then
                    LogTarEvent('Building content body, Length ' +
                        IntToStr(FRespContentLength) + ', Added ' + IntToStr(NewLen) +
                           ', Remaining ' + IntToStr(FTarRespLenRemain) +
                                    ', Left Over ' + IntToStr(FTarWaitTot)) ;

            { got whole body content or target closed, send it to target }
                if (FTarRespLenRemain <= 0) or FTarClosedFlag then
                    FPxyRespState := PxySendBody;
            end;
        end

      { no body, just send header, nothing more }
        else if (FPxyRespState = PxyNoBody) then begin
            SendRespHdr;
            FHttpInfo [FHttpCurrResp].HttpReqState := httpStRespSend;
            FHttpInfo [FHttpCurrResp].TickRespSend := IcsGetTickCount;
            LoopCounter := 0;
            DoneResponse;
            if (FProxySource.DebugLevel >= DebugHttpHdr) then
                LogTarEvent('Finished response');
            FPxyRespState := PxyHdrFind;  // look for another response header
        end;

     { got complete body, process it, send header then body }
        if FPxyRespState = PxySendBody then begin

          { uncompress body so we can mess with it }
            if FRespContentEncoding <> '' then begin
                DecompressBody;
            end;

          { do we need to modify body with new URLs, also calls HttpRespBody event }
            if (NOT FRespBinary) and FUpdateHtml then begin
                UpdateBody;
            end ;

          { see if need to get body into string for logging }
            if (FProxySource.DebugLevel >= DebugHttpBody) and (NOT FRespBinary) then begin
                SetLength(BodyStr, FHtmlRespBodyLen);
                IcsMoveTBytesToString(FHtmlRespBody, 0, BodyStr, 1, FRespContentLength);
            end;

          { see if compressing body for source, browser may not be interested }
          { beware, changes headers, so must be before they are sent }
            if ((FProxySource as TIcsHttpProxy).FHttpSrcCompress) and
                        (FHttpInfo [FHttpCurrResp].ReqAcceptEnc  <> '') then begin
                if FRespContentEncoding = '' then  // only if not compressed already
                    CompressBody;
            end;

         { send modified response header, then modified body }
            SendRespHdr;
            if (FProxySource.DebugLevel >= DebugHttpHdr) then
                LogTarEvent('Sending single-block body content, length ' +
                                           IntToStr(FRespContentLength));
            if FHtmlRespBodyLen > 0 then begin

              { add body to debug log, before it was compressed }
                if (FProxySource.DebugLevel >= DebugHttpBody) then begin
                    if NOT FRespBinary then begin
                        if FRespContentLength > MaxBodyDumpSize then begin
                            SetLength(BodyStr, MaxBodyDumpSize);
                            BodyStr := BodyStr + cCRLF + '!!! TRUNCATED !!!';
                        end;
                        LogTarEvent('Body:'+ cCRLF + BodyStr);
                    end;
                end;
                SourceBodyBufXmit;
            end;
            FPxyRespState := PxyHdrFind;  // reset state for next response header
            LoopCounter := 0;
            DoneResponse;
            BodyStr := '';
            if (FProxySource.DebugLevel >= DebugConn) then
                LogTarEvent('Finished sending response');
        end;


     { should never get this state }
        if FPxyRespState = PxyClosed then begin
            Exit;
        end;

    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ TIcsHttpProxy main HTTP proxy component }
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TIcsHttpProxy.Create(Owner: TComponent);
begin
    inherited Create(Owner);
    FSourceServer.ClientClass := THttpProxyClient;
    FHttpMaxBody := DefMaxBodySize;
    FHttpCompMinSize := CompressMinSize;
    FHttpStripUpgrade := True;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
destructor TIcsHttpProxy.Destroy;
begin
    inherited Destroy;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function IcsLoadProxyTargetsFromIni(MyIniFile: TCustomIniFile; ProxyTargets:
               TProxyTargets; const Prefix: String = 'Target'): Integer;
var
    J: Integer;
    section, S: String;
begin
    Result := 0;
    if NOT Assigned (MyIniFile) then
        raise ESocketException.Create('Must open and assign INI file first');
    if NOT Assigned (ProxyTargets) then
        raise ESocketException.Create('Must assign ProxyTargets first');
    ProxyTargets.Clear;

  { allow up to 100 hosts }
    for J := 1 to 100 do begin
        section := Prefix + IntToStr (J);
        S := IcsTrim(MyIniFile.ReadString(section, 'HostTag', ''));
        if S = '' then continue;
        if NOT IcsCheckTrueFalse(MyIniFile.ReadString (section, 'HostEnabled', 'False')) then continue;
        ProxyTargets.Add;
        Result := Result + 1;

    // read site hosts from INI file
        with ProxyTargets[ProxyTargets.Count - 1] do begin
            HostEnabled := True;
            HostTag := S;
            Descr := IcsTrim(MyIniFile.ReadString(section, 'Descr', ''));
            SrcPath := IcsLowerCase(MyIniFile.ReadString(section, 'SrcPath', ''));
            TarHost := MyIniFile.ReadString(section, 'TarHost', '');
            TarPort := MyIniFile.ReadInteger(section, 'TarPort', 0);
            TarSsl := IcsCheckTrueFalse(MyIniFile.ReadString (section, 'TarSsl', 'False'));
            IdleTimeout := MyIniFile.ReadInteger(section, 'IdleTimeout', 0);
            UpdateHttp := IcsCheckTrueFalse(MyIniFile.ReadString (section, 'UpdateHttp', 'False'));
            UpdateHtml := IcsCheckTrueFalse(MyIniFile.ReadString (section, 'UpdateHtml', 'False'));
        end;
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure IcsLoadTIcsHttpProxyFromIni(MyIniFile: TCustomIniFile; IcsHttpProxy:
                TIcsHttpProxy; const Section: String = 'Proxy');
var
    S: String;
    V: Integer;
begin
    if NOT Assigned (MyIniFile) then
        raise ESocketException.Create('Must open and assign INI file first');
    if NOT Assigned (IcsHttpProxy) then
        raise ESocketException.Create('Must assign IcsHttpProxy first');

    with IcsHttpProxy do begin
        RxBuffSize := MyIniFile.ReadInteger(Section, 'RxBuffSize', 65536);
        MaxClients := MyIniFile.ReadInteger(Section, 'MaxClients', 999);
        ServerHeader := IcsTrim(MyIniFile.ReadString(Section, 'ServerHeader', ''));
        LocalAddr := MyIniFile.ReadString(Section, 'LocalAddr', '');
        RootCA := IcsTrim(MyIniFile.ReadString(Section, 'RootCA', ''));
        DHParams := MyIniFile.ReadString(Section, 'DHParams', '');
//        DebugLevel := TDebugLevel(MyIniFile.ReadInteger (Section, 'DebugLevel', 2));
        S := IcsTrim(MyIniFile.ReadString (Section, 'DebugLevel', ''));
        if S = '' then
            V := -1
        else if IsDigit(S[1]) then   { V8.57 ini may contain integer or enum type string }
            V := atoi(S)
        else
            V := GetEnumValue (TypeInfo (TDebugLevel), S);
        if V < 0 then V := Ord(DebugSsl); // sanity check
        DebugLevel := TDebugLevel(V);                                     { V8.57 }
 //        TarSecLevel := TSslSecLevel(MyIniFile.ReadInteger(Section, 'TarSecLevel', 1));
        S := IcsTrim(MyIniFile.ReadString(section, 'TarSecLevel', ''));
        if S = '' then
            V := -1
        else if IsDigit(S[1]) then   { V8.57 ini may contain integer or enum type string }
            V := atoi(S)
        else
            V := GetEnumValue (TypeInfo (TSslSecLevel), S);
        if V < 0 then V := Ord(sslCliSecDefault); // sanity check
        TarSecLevel := TSslSecLevel(V);                                    { V8.57 }
//        CertVerTar := TCertVerMethod(MyIniFile.ReadInteger(Section, 'CertVerTar', 1));
        S := IcsTrim(MyIniFile.ReadString(Section, 'CertVerTar', ''));
        if S = '' then
            V := -1
        else if IsDigit(S[1]) then   { V8.57 ini may contain integer or enum type string }
            V := atoi(S)
        else
            V := GetEnumValue (TypeInfo (TCertVerMethod), S);
        if V < 0 then V := Ord(CertVerBundle); // sanity check
        CertVerTar := TCertVerMethod(V);                                               { V8.57 }
        SslRevocation := IcsCheckTrueFalse(MyIniFile.ReadString (Section, 'SslRevocation', 'False'));
        SslReportChain := IcsCheckTrueFalse(MyIniFile.ReadString (Section, 'SslReportChain', 'False'));
        HttpIgnoreClose := IcsCheckTrueFalse(MyIniFile.ReadString (Section, 'HttpIgnoreClose', 'False'));
        HttpSrcCompress := IcsCheckTrueFalse(MyIniFile.ReadString (Section, 'HttpSrcCompress', 'False'));
        HttpTarCompress := IcsCheckTrueFalse(MyIniFile.ReadString (Section, 'HttpTarCompress', 'False'));
        HttpStripUpgrade := IcsCheckTrueFalse(MyIniFile.ReadString (Section, 'HttpStripUpgrade', 'True'));
        HttpStopCached := IcsCheckTrueFalse(MyIniFile.ReadString (Section, 'SslReportChain', 'False'));
        HttpMaxBody := MyIniFile.ReadInteger(Section, 'HttpMaxBody', 1000000);
        HttpCompMinSize := MyIniFile.ReadInteger(Section, 'HttpCompMinSize', CompressMinSize);
        SslCliCertMethod := TSslCliCertMethod(GetEnumValue (TypeInfo (TSslCliCertMethod),
                        IcsTrim(MyIniFile.ReadString(section, 'SslCliCertMethod', 'sslCliCertNone'))));     { V8.57 }
        if SslCliCertMethod > High(TSslCliCertMethod) then
             SslCliCertMethod := sslCliCertNone;                                                            { V8.59 sanity test }
        SslCertAutoOrder := IcsCheckTrueFalse(MyIniFile.ReadString (section, 'SslCertAutoOrder', 'False')); { V8.57 }
        CertExpireDays := MyIniFile.ReadInteger(Section, 'CertExpireDays', CertExpireDays);                 { V8.57 }
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

{$ENDIF} { USE_SSL}

end.
