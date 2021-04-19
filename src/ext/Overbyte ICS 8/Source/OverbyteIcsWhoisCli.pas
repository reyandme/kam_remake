{*_* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Author:       Angus Robertson, Magenta Systems Ltd
Description:  TIcsWhoisCli is a Whois protocol client using TWSocket
              Conform to RFC-954 (which is not really very detailed)
Creation:     Aug 2002
Updated:      Jan 2019
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


Aug 2002    - Baseline
3 Nov 2006  - renamed unit for ICS V6
Sept 2017 - V8.50 -   Made unicode compatible.
24 Jan 2019 - V8.60 - Adapted for main ICS packages and FMX support.
                      Renamed from TWhois to TIcsWhoisCli.
                      Added automatic whois server lookup.
                      Added full built-in whois server directory.


WHOIS - Howto
-------------

Not much to it really, set the Query property to the domain or IP address
you want to look-up and call the StartAutoQuery method.  The event OnQueryDone
is called when the query is complete, with the textual result in the WhoisResp
property.  Note the response is free form with different formats for different
whois servers.

The component has an internal list of over 200 top level domains available
through the WhoisServers property with their whois servers, if none is found
the IANA registry is checked instead.

Some queries will result in a secondary query to another whois server for more
detail, the result of just the last query is available as property LastResp.
Most COM queries are two stage due to multiple registries, likewise IP address
queries are first to ARIN then often to the regional registry.

Alternatively, the StartQuery method does a single query to the server
specified in the Host property.

Due to European Union GPDR so called privacy regulations most of the useful
information about domains has now been removed from public Whois responses so
you no longer know who a domain belongs to and whether it is legitimate or
owned by spammers, aome registries don't even show when it was registered.

There is a test application OverbyteIcsWhoisTst.dpr.







 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{$IFNDEF ICS_INCLUDE_MODE}
unit OverbyteIcsWhoisCli;
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
    WhoisCliVersion            = 860;
    CopyRight    : String     = ' WhoisCli (c) 2019 V8.60 ';


type
    TIcsWhoisCli = class(TComponent)
    protected
        FWSocket1           : TWSocket;
        FWSocket2           : TWSocket;
        FQuery              : String;
        FHost               : String;
        FWhoisResp          : String;
        FLastResp           : String;
        FQueryDoneFlag      : Boolean;
        FAutoQueryFlag      : Boolean;
        FSecondaryAllowed   : Boolean;
        FWhoisServers       : TStringList;
        FOnDataAvailable    : TDataAvailable;
        FOnQueryDone        : TSessionClosed;
        procedure WSocketSessionConnected(Sender: TObject; Error: Word);
        procedure WSocketDataAvailable(Sender: TObject; Error: Word);
        procedure WSocketSessionClosed(Sender: TObject; Error: Word);
        procedure TriggerQueryDone(Error: Word);
        procedure SetWhoisServers(const Value: TStringList);
        procedure AutoQueryResponse;
    published
        constructor Create(AOwner: TComponent); override;
        destructor  Destroy; override;
        procedure   StartQuery;
        procedure   StartAutoQuery;
        procedure   Abort;
        property Query : String                         read  FQuery
                                                        write FQuery;
        property Host  : String                         read  FHost
                                                        write FHost;
        property WhoisResp : String                     read  FWhoisResp;
        property LastResp : String                      read  FLastResp;
        property WhoisServers: TStringList              read  FWhoisServers
                                                        write SetWhoisServers;
        property OnQueryDone : TSessionClosed           read  FOnQueryDone
                                                        write FOnQueryDone;
    end;

const
{
;WHOIS Servers List
;Maintained by Nir Sofer
;This servers list if freely available for any use and without any restriction.
;For more information: http://www.nirsoft.net/whois_servers_list.html
;Last updated on 16/02/2016  }

  WhoisNames: array [0..232] of PChar = (
    '?? whois.iana.org',      // specials, top level
    '00 whois.ripe.net',      // specials, European addresses
    '00 whois.arin.net',      // specials, Nothern American addresses
    '00 whois.apnic.net',     // specials, Far East addresses
    'com whois.verisign-grs.com', // moved common servers to top
    'org whois.pir.org',
    'net whois.verisign-grs.com',
    'uk whois.nic.uk',
    'ac whois.nic.ac',
    'ad whois.ripe.net',
    'ae whois.aeda.net.ae',
    'aero whois.aero',
    'af whois.nic.af',
    'ag whois.nic.ag',
    'ai whois.ai',
    'al whois.ripe.net',
    'am whois.amnic.net',
    'as whois.nic.as',
    'asia whois.nic.asia',
    'at whois.nic.at',
    'au whois.aunic.net',
    'aw whois.nic.aw',
    'ax whois.ax ',
    'az whois.ripe.net',
    'ba whois.ripe.net',
    'bar whois.nic.bar',
    'be whois.dns.be',
    'berlin whois.nic.berlin',
    'best whois.nic.best',
    'bg whois.register.bg',
    'bi whois.nic.bi',
    'biz whois.neulevel.biz',
    'bj www.nic.bj',
    'bo whois.nic.bo',
    'br whois.nic.br',
    'br.com whois.centralnic.com',
    'bt whois.netnames.net',
    'bw whois.nic.net.bw',
    'by whois.cctld.by',
    'bz whois.belizenic.bz',
    'bzh whois-bzh.nic.fr',
    'ca whois.cira.ca',
    'cat whois.cat',
    'cc whois.nic.cc',
    'cd whois.nic.cd',
    'ceo whois.nic.ceo',
    'cf whois.dot.cf',
    'ch whois.nic.ch ',
    'ci whois.nic.ci',
    'ck whois.nic.ck',
    'cl whois.nic.cl',
    'cloud whois.nic.cloud',
    'club whois.nic.club',
    'cn whois.cnnic.net.cn',
    'cn.com whois.centralnic.com',
    'co whois.nic.co',
    'co.nl whois.co.nl',
    'coop whois.nic.coop',
    'cx whois.nic.cx',
    'cy whois.ripe.net',
    'cz whois.nic.cz',
    'de whois.denic.de',
    'dk whois.dk-hostmaster.dk',
    'dm whois.nic.cx',
    'dz whois.nic.dz',
    'ec whois.nic.ec',
    'edu whois.educause.net',
    'ee whois.tld.ee',
    'eg whois.ripe.net',
    'es whois.nic.es',
    'eu whois.eu',
    'eu.com whois.centralnic.com',
    'eus whois.nic.eus',
    'fi whois.fi',
    'fo whois.nic.fo',
    'fr whois.nic.fr',
    'gb whois.ripe.net',
    'gb.com whois.centralnic.com',
    'gb.net whois.centralnic.com',
    'qc.com whois.centralnic.com',
    'ge whois.ripe.net',
    'gg whois.gg',
    'gi whois2.afilias-grs.net',
    'gl whois.nic.gl',
    'gm whois.ripe.net',
    'gov whois.nic.gov',
    'gr whois.ripe.net',
    'gs whois.nic.gs',
    'gy whois.registry.gy',
    'hamburg whois.nic.hamburg',
    'hiphop whois.uniregistry.net',
    'hk whois.hknic.net.hk',
    'hm whois.registry.hm',
    'hn whois2.afilias-grs.net',
    'host whois.nic.host',
    'hr whois.dns.hr',
    'ht whois.nic.ht',
    'hu whois.nic.hu',
    'hu.com whois.centralnic.com',
    'id whois.pandi.or.id',
    'ie whois.domainregistry.ie',
    'il whois.isoc.org.il',
    'im whois.nic.im',
    'in whois.inregistry.net',
    'info whois.afilias.info',
    'ing domain-registry-whois.l.google.com',
    'ink whois.centralnic.com',
    'int whois.isi.edu',
    'io whois.nic.io',
    'iq whois.cmc.iq',
    'ir whois.nic.ir',
    'is whois.isnic.is',
    'it whois.nic.it',
    'je whois.je',
    'jobs jobswhois.verisign-grs.com',
    'jp whois.jprs.jp',
    'ke whois.kenic.or.ke',
    'kg whois.domain.kg',
    'ki whois.nic.ki',
    'kr whois.kr',
    'kz whois.nic.kz',
    'la whois2.afilias-grs.net',
    'li whois.nic.li',
    'london whois.nic.london',
    'lt whois.domreg.lt',
    'lu whois.restena.lu',
    'lv whois.nic.lv',
    'ly whois.lydomains.com',
    'ma whois.iam.net.ma',
    'mc whois.ripe.net',
    'md whois.nic.md',
    'me whois.nic.me',
    'mg whois.nic.mg',
    'mil whois.nic.mil',
    'mk whois.ripe.net',
    'ml whois.dot.ml',
    'mo whois.monic.mo',
    'mobi whois.dotmobiregistry.net',
    'ms whois.nic.ms',
    'mt whois.ripe.net',
    'mu whois.nic.mu',
    'museum whois.museum',
    'mx whois.nic.mx',
    'my whois.mynic.net.my',
    'mz whois.nic.mz',
    'na whois.na-nic.com.na',
    'name whois.nic.name',
    'nc whois.nc',
    'nf whois.nic.cx',
    'ng whois.nic.net.ng',
    'nl whois.domain-registry.nl',
    'no whois.norid.no',
    'no.com whois.centralnic.com',
    'nu whois.nic.nu',
    'nz whois.srs.net.nz',
    'om whois.registry.om',
    'ong whois.publicinterestregistry.net',
    'ooo whois.nic.ooo',
    'paris whois-paris.nic.fr',
    'pe kero.yachay.pe',
    'pf whois.registry.pf',
    'pics whois.uniregistry.net',
    'pl whois.dns.pl',
    'pm whois.nic.pm',
    'pr whois.nic.pr',
    'press whois.nic.press',
    'pro whois.registrypro.pro',
    'pt whois.dns.pt',
    'pub whois.unitedtld.com',
    'pw whois.nic.pw',
    'qa whois.registry.qa',
    're whois.nic.re',
    'ro whois.rotld.ro',
    'rs whois.rnids.rs',
    'ru whois.tcinet.ru',
    'sa saudinic.net.sa',
    'sa.com whois.centralnic.com',
    'sb whois.nic.net.sb',
    'sc whois2.afilias-grs.net',
    'se whois.nic-se.se',
    'se.com whois.centralnic.com',
    'se.net whois.centralnic.com',
    'sg whois.nic.net.sg',
    'sh whois.nic.sh',
    'si whois.arnes.si',
    'sk whois.sk-nic.sk',
    'sm whois.nic.sm',
    'st whois.nic.st',
    'so whois.nic.so',
    'su whois.tcinet.ru',
    'sx whois.sx',
    'sy whois.tld.sy',
    'tc whois.adamsnames.tc',
    'tel whois.nic.tel',
    'tf whois.nic.tf',
    'th whois.thnic.net',
    'tj whois.nic.tj',
    'tk whois.nic.tk',
    'tl whois.domains.tl',
    'tm whois.nic.tm',
    'tn whois.ati.tn',
    'to whois.tonic.to',
    'top whois.nic.top',
    'tp whois.domains.tl',
    'tr whois.nic.tr',
    'travel whois.nic.travel',
    'tw whois.twnic.net.tw',
    'tv whois.nic.tv',
    'tz whois.tznic.or.tz',
    'ua whois.ua',
    'ug whois.co.ug',
    'uk.com whois.centralnic.com',
    'uk.net whois.centralnic.com',
    'ac.uk whois.ja.net',
    'gov.uk whois.ja.net',
    'us whois.nic.us',
    'us.com whois.centralnic.com',
    'uy nic.uy',
    'uy.com whois.centralnic.com',
    'uz whois.cctld.uz',
    'va whois.ripe.net',
    'vc whois2.afilias-grs.net',
    've whois.nic.ve',
    'vg ccwhois.ksregistry.net',
    'vu vunic.vu',
    'wang whois.nic.wang',
    'wf whois.nic.wf',
    'wiki whois.nic.wiki',
    'ws whois.website.ws',
    'xxx whois.nic.xxx',
    'xyz whois.nic.xyz',
    'yu whois.ripe.net',
    'za.com whois.centralnic.com');

implementation


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function CleanDomain (const domain: string): string ;
begin
    result := Trim (domain) ;
    if Pos ('http://', LowerCase(Result)) = 1 then result := Copy (Result, 8, 99) ;
    if Pos ('https://', LowerCase(Result)) = 1 then result := Copy (Result, 9, 99) ;
    If Result [Length (Result)] = '/' then SetLength (Result, Length (Result) - 1) ;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TIcsWhoisCli.Create(AOwner: TComponent);
var
    I: Integer;
begin
    inherited Create(AOwner);
    FWhoisServers := TStringList.Create;
    for I := 0 to Length(WhoisNames) - 1 do
                FWhoisServers.add(WhoisNames[I]);
    FWSocket1 := TWSocket.Create(Self);
    FWSocket1.OnSessionConnected := WSocketSessionConnected;
    FWSocket1.OnDataAvailable := WSocketDataAvailable;
    FWSocket1.OnSessionClosed := WSocketSessionClosed;
  { use async DNS to avoid needing DnsLookpDone event }
    FWSocket1.ComponentOptions := FWSocket1.ComponentOptions +
                                    [wsoAsyncDnsLookup, wsoIcsDnsLookup];
    FWSocket2 := TWSocket.Create(Self);
    FWSocket2.OnSessionConnected := WSocketSessionConnected;
    FWSocket2.OnDataAvailable := WSocketDataAvailable;
    FWSocket2.OnSessionClosed := WSocketSessionClosed;
  { use async DNS to avoid needing DnsLookpDone event }
    FWSocket2.ComponentOptions := FWSocket2.ComponentOptions +
                                    [wsoAsyncDnsLookup, wsoIcsDnsLookup];
    FHost := 'whois.ripe.net' ;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
destructor TIcsWhoisCli.Destroy;
begin
    FreeAndNil(FWhoisServers);
    FreeAndNil(FWSocket1);
    FreeAndNil(FWSocket2);
    inherited Destroy;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsWhoisCli.SetWhoisServers(const Value: TStringList);
begin
    if FWhoisServers.Text <> Value.Text then begin
        FWhoisServers.Assign(Value);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ simple query to specified Whois server }
procedure TIcsWhoisCli.StartQuery;
var
    J: Integer;
begin
    FQueryDoneFlag := FALSE;
    FAutoQueryFlag := FALSE;
    FWhoisResp := '' ;
    FLastResp := '' ;
    FQuery := CleanDomain (FQuery) ;
    if (FQuery = '') or ((Pos ('.', FQuery) <= 0) and (Pos (':', FQuery) <= 0)) then begin
        FWhoisResp := 'Invalid domain or IP address: ' + FQuery + IcsCRLF;
        TriggerQueryDone(0);
        Exit ;
    end;
    J := Pos (' [', FHost) ; // strip [descript] from end of server, if found
    if J > 1 then FHost := Trim (Copy (FHost, 1, J - 1)) ;
    if FWSocket1.State <> wsClosed then Abort;
    if FHost = '' then begin
        FWhoisResp := 'Failed to find Whois server: ' + FHost + IcsCRLF;
        TriggerQueryDone(0);
        Exit ;
    end;
    FWSocket1.Addr := FHost;
    FWSocket1.Proto := 'tcp';
    FWSocket1.Port := 'whois' ;
    FWSocket1.Connect;
    FWhoisResp := 'Query started: ' + FQuery + ' to ' + FWSocket1.Addr + IcsCRLF;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ automatic query looking up Whois server, repeatedly if necessary }
procedure TIcsWhoisCli.StartAutoQuery;
var
    I, J, K: integer ;
    domain1, domain2: string ;
    LSocketFamily: TSocketFamily;
begin
    FQueryDoneFlag := FALSE;
    FAutoQueryFlag := TRUE;
    FWhoisResp := '';
    FLastResp := '' ;
    FQuery := CleanDomain (FQuery);
    if (FQuery = '') or ((Pos ('.', FQuery) <= 0) and (Pos (':', FQuery) <= 0)) then begin
        FWhoisResp := 'Invalid domain or IP address: ' + FQuery + IcsCRLF;
        TriggerQueryDone(0);
        Exit ;
    end;
    if FWSocket1.State <> wsClosed then Abort;
    FSecondaryAllowed := True;
    domain1 := '' ;
    domain2 := '' ;
    if WSocketIsIP(FQuery, LSocketFamily) then begin
        FWSocket1.Addr := 'whois.arin.net' ;
    end
    else begin

      // find first and second level domains from host.co.uk
        for J := Length (FQuery) downto 2 do begin
            if FQuery [J] = '.' then begin   // search host.co.uk
                if domain1 = '' then
                    domain1 := Copy (FQuery, J + 1, 99) + IcsSpace   // found  uk
                else begin
                    domain2 := Copy (FQuery, J + 1, 99) + IcsSpace ;  // found co.uk
                    Break ;
                end;
            end;
        end;

     // lookup domains in databsee, ie 'gov.uk whois.ja.net'
        K := -1 ;
        if FWhoisServers.Count > 0 then begin
            for I := 0 to FWhoisServers.Count - 1 do
            begin
                if (Pos (domain1, FWhoisServers [I]) = 1) then K := I ;
                if (Pos (domain2, FWhoisServers [I]) = 1) then
                begin
                    K := I ;
                    break ;
                end ;
            end;
            if K >= 0 then begin
                J := Pos (IcsSpace, FWhoisServers [K]) ;
                FWSocket1.Addr := Copy (FWhoisServers [K], J + 1, 99) ;
            end;
        end;
        if K < 0 then begin
            FWSocket1.Addr := 'whois.iana.org';  // top level domains
        end;
    end;
    if FWSocket1.State <> wsClosed then Abort;
    if FWSocket2.State <> wsClosed then Abort;
    FWSocket1.Proto := 'tcp';
    FWSocket1.Port := 'whois' ;
    FWSocket1.Connect;
    FWhoisResp := 'Query started: ' + FQuery + ' to ' + FWSocket1.Addr + IcsCRLF;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsWhoisCli.Abort;
begin
    FWSocket1.CancelDnsLookup;
    FWSocket1.Abort;
    FWSocket2.CancelDnsLookup;
    FWSocket2.Abort;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsWhoisCli.WSocketSessionConnected(Sender: TObject; Error: Word);
begin
    if Error <> 0 then begin
        TriggerQueryDone(Error);
        (Sender as TWSocket).Close;
    end
    else begin
        (Sender as TWSocket).SendStr(FQuery + IcsCRLF);
    end ;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsWhoisCli.WSocketDataAvailable(Sender: TObject; Error: Word);
var
    Buffer : array [0..10000] of AnsiChar;
    Len : Integer;
begin
    while TRUE do begin
        Len := (Sender as TWSocket).Receive(@Buffer, SizeOf(Buffer) - 1);
        if Len <= 0 then break;
        Buffer[Len] := #0;
        FLastResp := FLastResp + String(Buffer) ;
        Buffer[0] := #0;
    end ;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsWhoisCli.TriggerQueryDone(Error: Word);
begin
    if Error > 0 then begin
        if Error = WSAECONNREFUSED then
            FWhoisResp := FWhoisResp + 'No Whois service available' + IcsCRLF
        else if Error = WSAETIMEDOUT then
            FWhoisResp := FWhoisResp + 'Whois Host unreachable'+ IcsCRLF
        else
            FWhoisResp := FWhoisResp + 'Whois Error: ' +
                                     WSocketErrorDesc(Error) + IcsCRLF;
    end;
    FQueryDoneFlag := TRUE;  // in case new query started in done event
    if Assigned(FOnQueryDone) then
        FOnQueryDone(Self, Error);
    // Whois result is in FWhoisResp
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsWhoisCli.WSocketSessionClosed(Sender: TObject; Error: Word);
begin
    if Pos (IcsCRLF, FLastResp) = 0 then   // convert UNIX line endings to CRLF 
        FLastResp := StringReplace (FLastResp, IcsLF, IcsCRLF, [rfReplaceAll]);
    FWhoisResp := FWhoisResp + FLastResp;
    if FAutoQueryFlag and (Error = 0) then
        AutoQueryResponse
    else
        TriggerQueryDone(Error);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsWhoisCli.AutoQueryResponse;
var
    I, J, K : Integer;
    TempList: TStringList ;
    Line, NewWhois: String;
begin
    TempList := TStringList.Create ;
    try
        TempList.Text := FLastResp;
        if FSecondaryAllowed and(TempList.Count > 2) then begin
            FSecondaryAllowed := False ;

        // check for a secondary WHO server, and start another request
            for I := 0 to TempList.Count - 1 do begin
                Line := Lowercase(TempList [I]);
                if (Pos ('whois server:', Line) > 0) or        // internic.net
                   (Pos ('whois:', Line) > 0) then begin       // whois.iana.org
                    J := Pos (':', Line);
                    NewWhois := IcsTrim (Copy (Line, J + 1, 99));
                    if (NewWhois <> '') and (NewWhois <> FWSocket1.Addr) then begin
                        FLastResp := '' ;
                        FWSocket2.Addr := NewWhois;
                        FWSocket2.Proto := 'tcp';
                        FWSocket2.Port := 'whois' ;
                        FWSocket2.Connect;
                        FWhoisResp := FWhoisResp + 'Secondary Query: ' +
                                     FQuery + ' to ' + FWSocket2.Addr + IcsCRLF;
                        exit ;
                    end;
                end ;
    // NetType:        Allocated to RIPE NCC
    // NetType:        Direct Allocation
    // NetType:        Allocated to APNIC
    // NetType:        Early Registrations, Transferred to RIPE NCC

                if Pos ('nettype:', Line) > 0 then begin  // arin.net IP different registry, RIPE, etc,
                    J := Pos ('allocated to', Line);
                    if J <= 0 then J := Pos ('transferred to ', Line);
                    if J > 2 then
                    begin
                        for J := I to Pred (TempList.Count) do
                        begin
    // ResourceLink:  https://apps.db.ripe.net/search/query.html
    // ResourceLink:  whois.ripe.net
    // ReferralServer:  whois://whois.ripe.net
    // ResourceLink:  https://apps.db.ripe.net/search/query.html
                            Line := Lowercase(TempList [J]);
                            K := Pos ('whois.', Line) ;
                            if ((Pos ('resourcelink:', Line) > 0) and
                                   (Pos ('http://', Line) = 0) and (K > 0)) OR
                                (Pos ('referralserver:', Line) > 0) and
                                   (Pos ('http://', Line) = 0) and (K > 0) then begin
                                NewWhois :=  Trim (Copy (Line, K, 99)) ;
                                if (NewWhois <> '') and (NewWhois <> FWSocket1.Addr) then begin
                                    FLastResp := '' ;
                                    FWSocket2.Addr := NewWhois;
                                    FWSocket2.Proto := 'tcp';
                                    FWSocket2.Port := 'whois' ;
                                    FWSocket2.Connect;
                                    FWhoisResp := FWhoisResp + 'Secondary Query: ' +
                                          FQuery + ' to ' + FWSocket2.Addr + IcsCRLF;
                                   exit ;
                                end;
                            end;
                        end;
                    end;
                end ;
            end;
        end ;

    // pending, try and parse the registration and expiry dates, registratar name, etc

        TriggerQueryDone(0);
    finally
        TempList.Free ;
    end ;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

end.

