{*_* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Author:       François PIETTE
Description:  Component to query DNS records.
              Implement most of RFC 1035 (A, NS, AAAA, PTR, MX, etc).
Creation:     January 29, 1999
Version:      8.64
EMail:        http://www.overbyte.be        francois.piette@overbyte.be
Support:      https://en.delphipraxis.net/forum/37-ics-internet-component-suite/
Legal issues: Copyright (C) 1999-2020 by François PIETTE
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
Feb 14, 1999 V0.02 Indirectly call winsock functions using wsocket because
             wsocket provide runtime dynamic link instead of loadtime link.
             This allows a program to use DnsQuery if it discover that winsock
             is installed and still run if winsock is not installed.
Feb 24, 1999 V1.00 Added code for reverse lookup (PTR record).
Mar 07, 1999 V1.01 Adapted for Delphi 1
Aug 20, 1999 V1.02 Revise compile time option. Adapted for BCB4
Jul 27, 2001 V1.03 Holger Lembke <holger@hlembke.de> implemented a few new
                   queries or propreties (QueryAny, LongLatToDMS, Loc2Geo, Loc)
                   and related data types.
Sep 04, 2003 V1.04 Replaced all htons by WSocket_htons
May 31, 2004 V1.05 Used ICSDEFS.INC
Nov 19, 2004 V1.06 Added Multithreaded property
Mar 06, 2005 V1.07 DecodeAnswer has been fixed to avoid winsock ntohs and
                   ntohl function which have range check errors because Borland
                   defined the function as returning LongInt instead of Cardinal
May 29, 2005 V1.08 Jack <jlist9@gmail.com> added TCP support
Mar 26, 2006 V6.00 New version 6 started
Jun 05, 2008 A. Garrels made some changes to prepare code for Unicode
Aug 11, 2008 V6.02 A. Garrels - Type AnsiString rolled back to String.
Oct 09, 2009 V6.03 Yaroslav Chernykh fixed a bug in WSocketSessionConnected()
                   when using UDP.
May 2012 - V8.00 - Arno added FireMonkey cross platform support with POSIX/MacOS
                   also IPv6 support, include files now in sub-directory
Apr 22 2019 V8.61  Angus added more DnsQuery literals and removed obsolete ones.
                   DecodeWireResp split from WSocketDataAvailable so can be
                     used for DNS over HTTPS.
                   Queries now started with QueryAny.
                   Added QueryAll to return results from seven queries.
                   No longer ignores NS and Alternate results that sometimes
                     return extra useful records (like A for NS and CNAME).
                   New result array AnswerRecord with AnswerTotal records which
                     is a TRRRecord response record with all result information
                     so other arrays can be ignored, based on unpublished work
                     by Holger Lembke but implemented with backward compatibility.
                  Added DnsReqTable of common queries with descriptive literals.
                  Added DnsPublicServerTable and DnsPublicHttpsTabl of public
                    DNS server addresses.
                  Supporting all queries and responses including AAAA, NS and TXT,
                    common ones decoded in TRRRecord, rest returned as text or hex.
                  PTR query now supports IPv6 addresses as well as IPV4.
                  Call RequestDone if connection fails.
 May 04 2020 V8.64 Make sure data not processed beyond end of response buffer.
                  Added support for International Domain Names for Applications (IDNA),
                  All methods and arrays use String instead of AnsiString to support
                    Unicode domain names.  This may need application changes.
                  All Unicode queries are converted to Punycode ASCII, and responses
                    with ACE zn-- prefix are converted back to Unicode.
                    TRRRecord has AnswerName and HostName for unicode responses.


Note - OverbyteIcsHttpRest contains a derived component DnsQueryHttps which makes
DNS over HTTPS requests per RFC8484, illustrated in the OverbyteIcsHttpRest sample
which displays results in a more friendly grid.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{$IFNDEF ICS_INCLUDE_MODE}
unit OverbyteIcsDnsQuery;
{$ENDIF}

{$B-}           { Enable partial boolean evaluation   }
{$T-}           { Untyped pointers                    }
{$X+}           { Enable extended syntax              }
{$I Include\OverbyteIcsDefs.inc}
{$IFDEF COMPILER14_UP}
  {$IFDEF NO_EXTENDED_RTTI}
    {$RTTI EXPLICIT METHODS([]) FIELDS([]) PROPERTIES([])}
  {$ENDIF}
{$ENDIF}
{$IFDEF DELPHI6_UP}
    {$WARN SYMBOL_PLATFORM   OFF}
    {$WARN SYMBOL_LIBRARY    OFF}
    {$WARN SYMBOL_DEPRECATED OFF}
{$ENDIF}
{$IFNDEF VER80}   { Not for Delphi 1                    }
    {$H+}         { Use long strings                    }
    {$J+}         { Allow typed constant to be modified }
{$ENDIF}
{$IFDEF BCB3_UP}
    {$ObjExportAll On}
{$ENDIF}

interface

uses
{$IFDEF MSWINDOWS}
    {$IFDEF RTL_NAMESPACES}Winapi.Windows{$ELSE}Windows{$ENDIF},
{$ENDIF}
{$IFDEF POSIX}
    Ics.Posix.WinTypes,
{$ENDIF}
    {$IFDEF RTL_NAMESPACES}System.SysUtils{$ELSE}SysUtils{$ENDIF},
    {$IFDEF RTL_NAMESPACES}System.Classes{$ELSE}Classes{$ENDIF},
{$IFDEF FMX}
    Ics.Fmx.OverbyteIcsWSocket,
{$ELSE}
    OverbyteIcsWSocket,
{$ENDIF}
    OverbyteIcsUtils,
    OverbyteIcsWinsock;

const
  DnsQueryVersion    = 864;
  CopyRight : String = ' TDnsQuery  (c) 1999-2020 F. Piette V8.64 ';

  { Maximum answers (responses) count }
  MAX_ANCOUNT     = 50;
  { Maximum number of MX records taken into account in responses }
  MAX_MX_RECORDS  = 20;
  MAX_A_RECORDS   = 30;
  MAX_PTR_RECORDS = 10;

// https://www.iana.org/assignments/dns-parameters/dns-parameters.txt

  { DNS Classes }
  DnsClassIN      = 1;   { The internet                                      }
  DnsClassCS      = 2;   { obsolete }
  DnsClassCH      = 3;   { The CHAOS class                                   }
  DnsClassHS      = 4;   { Hesiod name service                               }
  DnsClassALL     = 255; { Any class                                         }

  { Type of query/response a DNS can handle }
  { https://en.wikipedia.org/wiki/List_of_DNS_record_types }
  { V8.61 suppress obsolete types so we don't waste time using them }
  DnsQueryA       = 1;  { A     HostAddress                                  }
  DnsQueryNS      = 2;  { NS    Authoritative name server                    }
//DnsQueryMD      = 3;  { MD    MailDestination, obsolete, use Mail Exchange }
//DnsQueryMF      = 4;  { MF    MailForwarder, obsolete, use Mail Exchange   }
  DnsQueryCNAME   = 5;  { CNAME CanonicalName                                }
  DnsQuerySOA     = 6;  { SOA   Start of a Zone of Authority                 }
//DnsQueryMB      = 7;  { MB    MailBox, experimental                        }
//DnsQueryMG      = 8;  { MG    MailGroup, experimental                      }
//DnsQueryMR      = 9;  { MR    MailRename, experimental                     }
//DnsQueryNULL    = 10; { NULL  Experimental                                 }
//DnsQueryWKS     = 11; { WKS   Well Known Service Description               }
  DnsQueryPTR     = 12; { PTR   Domain Name Pointer                          }
//DnsQueryHINFO   = 13; { HINFO Host Information                             }
//DnsQueryMINFO   = 14; { MINFO Mailbox information                          }
  DnsQueryMX      = 15; { MX    Mail Exchange                                }
  DnsQueryTXT     = 16; { TXT   Text Strings                                 }
  { !!KAP!! }
//DnsQueryRP      = 17;
  DnsQueryAFSDB   = 18;
//DnsQueryX25     = 19;
//DnsQueryISDN    = 20;
//DnsQueryRT      = 21;
//DnsQueryNSAP    = 22;
//DnsQueryNSAPPTR = 23;
  DnsQuerySIG     = 24; { see RFC-2065                                       }
  DnsQueryKEY     = 25; { see RFC-2065                                       }
//DnsQueryPX      = 26;
//DnsQueryGPOS    = 27;
  DnsQueryAAAA    = 28; { see IP6 Address                                    }
  DnsQueryLOC     = 29; { see RFC-1876  http://rfc.net/rfc1876.html  }
//DnsQueryNXT     = 30; { see RFC-2065                                     }
//DnsQueryEID     = 31;                                    }
//DnsQueryNB      = 32;                                    }
//DnsQueryNBSTAT  = 33;                                    }
  DnsQuerySRV     = 33; { see RFC-2052                                       }
//DnsQueryATMA    = 34;                                    }
  DnsQueryNAPTR   = 35; { see RFC-2168                                       }
// following V8.61
  DnsQueryKX           = 36;  // Key Exchanger   [RFC2230]
  DnsQueryCERT         = 37;  // CERT            [RFC4398]
//DnsQueryA6           = 38;  // A6 (OBSOLETE -  use AAAA)
  DnsQueryDNAME        = 39;  // DNAME           [RFC6672]
//DnsQuerySINK         = 40;  // SINK            [Donald_E_Eastlake]
  DnsQueryOPT          = 41;  // OPT             [RFC6891][RFC3225]
//DnsQueryAPL          = 42;  // APL             [RFC3123]
  DnsQueryDS           = 43;  // Delegation Signer     [RFC4034][RFC3658]
  DnsQuerySSHFP        = 44;  // SSH Key Fingerprint        [RFC4255]
  DnsQueryIPSECKEY     = 45;  // IPSECKEY        [RFC4025]
  DnsQueryRRSIG        = 46;  // RRSIG           [RFC4034][RFC3755]
  DnsQueryNSEC         = 47;  // NSEC            [RFC4034][RFC3755]
  DnsQueryDNSKEY       = 48;  // DNSKEY          [RFC4034][RFC3755]
  DnsQueryDHCID        = 49;  // DHCID           [RFC4701]
  DnsQueryNSEC3        = 50;  // NSEC3           [RFC5155]
  DnsQueryNSEC3PARAM   = 51;  // NSEC3PARAM      [RFC5155]
  DnsQueryTLSA         = 52;  // TLSA            [RFC6698]
  DnsQuerySMIMEA       = 53;  // S/MIME cert association    [RFC8162]
  DnsQueryHIP          = 55;  // Host Identity Protocol   [RFC8005]
//DnsQueryNINFO        = 56;  // NINFO           [Jim_Reid]
//DnsQueryRKEY         = 57;  // RKEY            [Jim_Reid]
  DnsQueryTALINK       = 58;  // Trust Anchor LINK  [Wouter_Wijngaards]
  DnsQueryCDS          = 59;  // Child DS DNSKEY(s) the        [RFC7344]
  DnsQueryCDNSKEY      = 60;  // Child wants reflected in DS    [RFC7344]
  DnsQueryOPENPGPKEY   = 61;  // OpenPGP Key     [RFC7929]
  DnsQueryCSYNC        = 62;  // Child-To-Parent Synchronization [RFC7477]
  DnsQueryZONEMD       = 63;  // message digest for DNS zone  [draft-wessels-dns-zone-digest]
//DnsQuerySPF          = 99;  // [RFC7208]
//DnsQueryUINFO        = 100; // [IANA-Reserved]
//DnsQueryUID          = 101; // [IANA-Reserved]
//DnsQueryGID          = 102; // [IANA-Reserved]
//DnsQueryUNSPEC       = 103; // [IANA-Reserved]
  DnsQueryNID          = 104; // [Identifier-Locator Network Protocol (ILNP) RFC6742]
  DnsQueryL32          = 105; // [Identifier-Locator Network Protocol (ILNP) RFC6742]
  DnsQueryL64          = 106; // [Identifier-Locator Network Protocol (ILNP) RFC6742]
  DnsQueryLP           = 107; // [Identifier-Locator Network Protocol (ILNP) RFC6742]
  DnsQueryEUI48        = 108; // an EUI-48 address      [RFC7043]
  DnsQueryEUI64        = 109; // an EUI-64 address      [RFC7043]
  DnsQueryTKEY         = 249; // Transaction Key [RFC2930]
  DnsQueryTSIG         = 250; // Transaction Signature    [RFC2845]
  DnsQueryIXFR         = 251; // incremental transfer    [RFC1995]
  { Some additional type only allowed in queries }
  DnsQueryAXFR        = 252; { Transfer for an entire zone                       }
//DnsQueryMAILB        = 253; { Mailbox related records (MB, MG or MR)            }
//DnsQueryMAILA        = 254; { MailAgent, obsolete, use MX instead               }
//DnsQueryALL          = 255; { * Request ALL records  - ofifically deaD          }
  DnsQueryURI          = 256; // URI Certification  [RFC7553]
  DnsQueryCAA          = 257; // Authority Restriction Application  [RFC6844]
  DnsQueryAVC          = 258; // Visibility and Control [Wolfgang_Riedel]
  DnsQueryDOA          = 259; // Digital Object Architecture [draft-durand-doa-over-dns]
  DnsQueryAMTRELAY     = 260; // Automatic Multicast Tunneling Relay      [draft-ietf-mboned-driad-amt-discovery]
  DnsQueryTA           = 32768;  // DNSSEC TrustAuthorities
  DnsQueryDLV          = 32769;  //DNSSEC Lookaside  Validation     [RFC4431]

{ Opcode field in query flags }
  DnsOpCodeQUERY  = 0;
  DnsOpCodeIQUERY = 1;
  DnsOpCodeSTATUS = 2;
  DnsOpCodeNOTIFY = 4;
  DnsOpCodeUPDATE = 5;
  DnsOpCodeDSO    = 6;

{ V8.61 status response codes }
  DnsRCodeNoError        = 0;
  DnsRCodeFormaatError   = 1;
  DnsRCodeServerFailure  = 2;
  DnsRCodeNameError      = 3;
  DnsRCodeNotImplemented = 4;
  DnsRCodeRefused        = 5;


{ V8.61 table of common DNS record types }
type
    TQueryInfo = record
        Num  : Integer;
        Asc  : String;
        Desc : String;
    end;

const
    DnsReqTable: array[0..40] of TQueryInfo = (
      (Num: DnsQueryA;      Asc: 'A';      Desc: 'Host Address IPv4'),
      (Num: DnsQueryNS;     Asc: 'NS';     Desc: 'Name Server'),
      (Num: DnsQueryCNAME;  Asc: 'CNAME';  Desc: 'Canonical Name'),
      (Num: DnsQuerySOA;    Asc: 'SOA';    Desc: 'Start of a Zone of Authority'),
      (Num: DnsQueryPTR;    Asc: 'PTR';    Desc: 'Domain Name Pointer'),
      (Num: DnsQueryMX;     Asc: 'MX';     Desc: 'Mail Exchange'),
      (Num: DnsQueryTXT;    Asc: 'TXT';    Desc: 'SPF, DKIM, DMARC, etc'),
      (Num: DnsQueryAFSDB;  Asc: 'AFSDB';  Desc: 'AFS DB'),
      (Num: DnsQuerySIG;    Asc: 'SIG';    Desc: 'Signature'),
      (Num: DnsQueryKEY;    Asc: 'KEY';    Desc: 'Key record'),
      (Num: DnsQueryAAAA;   Asc: 'AAAA' ;  Desc: 'Host Address IPv6'),
      (Num: DnsQueryLOC;    Asc: 'LOC';    Desc: 'Location'),
      (Num: DnsQuerySRV;    Asc: 'SRV';    Desc: 'Service Locator'),
      (Num: DnsQueryNAPTR;  Asc: 'NAPTR';  Desc: 'Name Authority Pointer'),
      (Num: DnsQueryKX ;    Asc: 'KX';     Desc: 'Key Exchanger'),
      (Num: DnsQueryCERT;   Asc: 'CERT';   Desc: 'Certificate'),
      (Num: DnsQueryDNAME;  Asc: 'DNAME';  Desc: 'Canonical Name'),
      (Num: DnsQueryOPT;    Asc: 'OPT';    Desc: 'OPT'),
      (Num: DnsQueryDS;     Asc: 'DS';     Desc: 'Delegation Signer (DNSSEC)'),
      (Num: DnsQuerySSHFP;  Asc: 'SSHFP';  Desc: 'SSH Key Fingerprint'),
      (Num: DnsQueryIPSECKEY;  Asc: 'IPSECKEY';   Desc: 'IPSec key'),
      (Num: DnsQueryRRSIG;  Asc: 'RRSIG';  Desc: 'DNSSEC Signature (DNSSEC)'),
      (Num: DnsQueryNSEC;   Asc: 'NSEC';   Desc: 'Next Secure Record (DNSSEC)'),
      (Num: DnsQueryDNSKEY; Asc: 'DNSKEY'; Desc: 'DNS key (DNSSEC)'),
      (Num: DnsQueryDHCID;  Asc: 'DHCID';  Desc: 'DHCP ID'),
      (Num: DnsQueryNSEC3;  Asc: 'NSEC3';  Desc: 'Next Secure Record v3 (DNSSEC)'),
      (Num: DnsQueryNSEC3PARAM;  Asc: 'NSEC3PARAM'; Desc: 'NSEC3 Params (DNSSEC)'),
      (Num: DnsQueryTLSA;   Asc: 'TLSA';   Desc: 'TLSA Certificate'),
      (Num: DnsQuerySMIMEA; Asc: 'SMIMEA'; Desc: 'S/MIME cert association'),
      (Num: DnsQueryHIP;    Asc: 'HIP';    Desc: 'Host Identity Protocol'),
      (Num: DnsQueryTALINK; Asc: 'TALINK'; Desc: 'Trust Anchor LINK'),
      (Num: DnsQueryCDS;    Asc: 'CDS';    Desc: 'Child DS DNSKEY (DNSSEC)'),
      (Num: DnsQueryCDNSKEY;Asc: 'CDNDKEY';Desc: 'Child copy of DNSKEY (DNSSEC)'),
      (Num: DnsQueryOPENPGPKEY;   Asc: 'OPENPGKEY'; Desc: 'OpenPGP Key'),
      (Num: DnsQueryCSYNC;  Asc: 'CSYNC';  Desc: 'Child-To-Parent Sync'),
      (Num: DnsQueryZONEMD; Asc: 'ZONEMD'; Desc: 'Message digest for DNS zone'),
      (Num: DnsQueryEUI48;  Asc: 'EUI48';  Desc: 'an EUI-48 address'),
      (Num: DnsQueryEUI64;  Asc: 'EUI64';  Desc: 'an EUI-64 address'),
      (Num: DnsQueryTKEY;   Asc: 'TKEY';   Desc: 'Transaction Key'),
      (Num: DnsQueryURI;    Asc: 'URI';    Desc: 'URI Certification'),
      (Num: DnsQueryCAA;    Asc: 'CAA';    Desc: 'Authority Restriction Application') );

  { V8.61 status respoonse code literals }
    DnsRCodeTable: array[DnsRCodeNoError..DnsRCodeRefused] of String = (
      'Success', 'Formaat Error', 'Server Failure', 'Name Error', 'Not Implemented', 'Refused');

  { V8.61 perform all (or most) requests sequentiually }
    DnsAllReqTot = 7;
    DnsAllReqTable:  array[1..DnsAllReqTot] of Integer = (
       DnsQueryA, DnsQueryAAAA, DnsQueryCNAME, DnsQueryNS, DnsQueryMX, DnsQuerySOA, DnsQueryTXT);

  { V8.61 public DNS servers }
    DnsPublicServerTable: array[0..15] of String = (
       '1.1.1.1 [Cloudfare]',
       '8.8.8.8 [Google]',
       '9.9.9.9 [Quad9]',
       '208.67.222.222 [OpenDNS]',
       '1.0.0.1 [Cloudfare]',
       '8.8.4.4 [Google]',
       '149.112.112.112 [Quad9]',
       '208.67.220.220 [OpenDNS]',
       '2606:4700:4700::1111 [Cloudfare]',
       '2001:4860:4860::8888 [Google]',
       '2620:fe::fe [Quad9]',
       '2620:119:35::35 [OpenDNS]',
       '2606:4700:4700::1001 [Cloudfare]',
       '2001:4860:4860::8844 [Google]',
       '2620:fe::9 [Quad9]',
       '2620:119:53::53 [OpenDNS]');

  { V8.61 public DNS servers using DOS - Dns over Https }
    DnsPublicHttpsTable: array[0..6] of String = (
        'https://cloudflare-dns.com/dns-query',
        'https://dns.quad9.net/dns-query',
        'https://doh.powerdns.org',
        'https://doh.securedns.eu/dns-query',
        'https://doh.appliedprivacy.net/query',
        'https://dns.google.com/resolve',         // only supports Json
        'https://dns.google.com/experimental');   // only supports wire format

type
  TDnsRequestDoneEvent = procedure (Sender : TObject; Error : WORD) of Object;

  TDnsRequestHeader = packed record
      ID      : WORD;
      Flags   : WORD;
      QDCount : WORD;
      ANCount : WORD;
      NSCount : WORD;
      ARCount : WORD;
  end;
  PDnsRequestHeader = ^TDnsRequestHeader;

  // rfc 1035 p.19
  TSoaRecord = record
    mname   : AnsiString;
    rname   : AnsiString;
    serial  : Cardinal;
    refresh : Cardinal;
    retry   : Cardinal;
    expire  : Cardinal;
    minimum : Cardinal;
  end;

  // Question Data rfc1035 p.28
  TQuestion = record
    QuestionType   : word;
    QuestionClass  : word;
    QuestionName   : AnsiString;
  end;


  // rfc 1035 p.10
  TRRInternal = packed record
    rrtype   : word;     // r due to token conflict
    rrclass  : word;     // same
    rrttl    : cardinal; // same
    rdlength : word;
  end;
  pRRInternal = ^TRRInternal;


  TLOCInfo = packed record { need to be 16 bytes }
    version    : byte;
    size       : byte;
    horizpre   : byte;
    vertpre    : byte;
    latitude   : longint;
    longitude  : longint;
    altitude   : longint;
  end;
  PLOCInfo = ^TLOCInfo;

  { Decoded TLOCInfo }
  TLogGeo = record
    version             : byte;
    longsize            : integer;
    latsize             : integer;
    horizpre            : integer;
    vertpre             : integer;
    { Latitude, degree, minutes, seconds, milliseconds }
    lad, lam, las, lams : integer;
    lahem               : AnsiChar;
    { same for Longitude }
    lod, lom, los, loms : integer;
    lohem               : AnsiChar;
    altitude            : integer;
  end;

 // V8.61 Result Record
  TRRRecord = packed record
    RRName    : AnsiString;
    RRType    : Word;      // r due to token conflict
    RRClass   : Word;      // same
    TTL       : Cardinal;  // same
    RDLength  : Word;
    RDData    : AnsiString;  // actual result as raw string
    HostName  : String;      // V8.64 for MX and PTR hostnames, IDN
    AnswerName : String;     // V8.64 for MX and PTR hostnames, IDN xxxx
    IPV4      : TInAddr;
    IPv6      : TIcsIPv6Address;
    MxPref    : Integer;
    SOA       : TSoaRecord;
    Locdecode : TLogGeo;
 end;

  TDnsAnswerNameArray   = packed array [0..MAX_ANCOUNT - 1]     of String;     { V8.64 }
  TDnsAnswerTypeArray   = packed array [0..MAX_ANCOUNT - 1]     of Integer;
  TDnsAnswerClassArray  = packed array [0..MAX_ANCOUNT - 1]     of Integer;
  TDnsAnswerTTLArray    = packed array [0..MAX_ANCOUNT - 1]     of LongInt;
  TDnsAnswerTagArray    = packed array [0..MAX_ANCOUNT - 1]     of Integer;
  TDnsRRRecordArray     = packed array [0..MAX_ANCOUNT - 1]     of TRRRecord; // V8.61
  TDnsMXPreferenceArray = packed array [0..MAX_MX_RECORDS - 1]  of Integer;
  TDnsMXExchangeArray   = packed array [0..MAX_MX_RECORDS - 1]  of String;     { V8.64 }
  TDnsAddressArray      = packed array [0..MAX_A_RECORDS - 1]   of TInAddr;
  TDnsHostnameArray     = packed array [0..MAX_PTR_RECORDS - 1] of String;     { V8.64 }

  TDnsQuery = class(TComponent)
  protected
    FWSocket                    : TWSocket;
    FPort                       : String;
    FAddr                       : String;
    FIDCount                    : WORD;
    FQueryBuf                   : array [0..511] of AnsiChar;
    FQueryLen                   : Integer;
    FResponseBuf                : array [0..2047] of AnsiChar;
    FResponseLen                : Integer;
    FResponseID                 : Integer;
    FResponseCode               : Integer;
    FResponseOpCode             : Integer;
    FResponseAuthoritative      : Boolean;
    FResponseTruncation         : Boolean;
    FResponseRecursionAvailable : Boolean;
    FResponseQDCount            : Integer;
    FResponseANCount            : Integer;
    FResponseNSCount            : Integer;
    FResponseARCount            : Integer;
    FQuestionType               : Integer;
    FQuestionClass              : Integer;
    FQuestionName               : String;              { V8.64 }
    FAnswerNameArray            : TDnsAnswerNameArray;
    FAnswerTypeArray            : TDnsAnswerTypeArray;
    FAnswerClassArray           : TDnsAnswerClassArray;
    FAnswerTTLArray             : TDnsAnswerTTLArray;
    FAnswerTagArray             : TDnsAnswerTagArray;
    FAnswerRecordArray          : TDnsRRRecordArray;   { V8.61 }
    FAnsTot                     : Integer;             { V8.61 }
    FMultiReqSeq                : Integer;             { V8.61 }
    FMultiHost                  : String;              { V8.64 }
    FMXRecordCount              : Integer;
    FMXPreferenceArray          : TDnsMXPreferenceArray; { For MX request  }
    FMXExchangeArray            : TDnsMXExchangeArray;   { For MX request  }
    FARecordCount               : Integer;
    FAddressArray               : TDnsAddressArray;      { For A request   }
    FPTRRecordCount             : Integer;
    FHostnameArray              : TDnsHostnameArray;     { For PTR request }
    FOnRequestDone              : TDnsRequestDoneEvent;
    FProto                      : String;                { default to udp  }
    FGotPacketLength            : Boolean; { for tcp, set if packet length received }
    FLengthByte                 : array [0..1] of BYTE; {  for tcp         }
    fLOCInfo                    : TLOCInfo;
    function GetMXPreference(nIndex : Integer) : Integer;
    function GetMXExchange(nIndex : Integer)   : String;
    function GetAnswerName(nIndex : Integer)   : String;
    function GetAnswerType(nIndex : Integer)   : Integer;
    function GetAnswerClass(nIndex : Integer)  : Integer;
    function GetAnswerTTL(nIndex : Integer)    : LongInt;
    function GetAnswerRecord(nIndex : Integer) : TRRRecord;   { V8.61 }
    function GetAnswerTag(nIndex : Integer)    : Integer;
    function GetAddress(nIndex : Integer)      : TInAddr;
    function GetHostname(nIndex : Integer)     : String;
    procedure WSocketDataAvailable(Sender: TObject; Error: WORD); virtual;
    procedure WSocketSessionConnected(Sender: TObject; Error: WORD); virtual;
    procedure TriggerRequestDone(Error: WORD); virtual;
    function  GetResponseBuf : PAnsiChar;
    procedure SendQuery;
    function  ExtractName(Base       : PAnsiChar;
                          From       : PAnsiChar;
                          var Name   : AnsiString) : PAnsiChar;
    function  GetMultiThreaded: Boolean;
    procedure SetMultiThreaded(const Value: Boolean);
    procedure SetProto(const Value : String);
    procedure SetAddr(const Value : String);
    function    DecodeWireResp(RespBuffer: PAnsiChar; BufLen: Integer): Boolean;
    procedure   BuildRequestHeader(Dst     : PDnsRequestHeader;
                                 ID        : WORD;
                                 OPCode    : BYTE;
                                 Recursion : Boolean;
                                 QDCount   : WORD;
                                 ANCount   : WORD;
                                 NSCount   : WORD;
                                 ARCount   : WORD); virtual;
    function    BuildQuestionSection(Dst       : PAnsiChar;
                                   QName       : String;   { V8.64 }
                                   QType       : WORD;
                                   QClass      : WORD) : Integer; virtual;
  public
    constructor Create(AOwner : TComponent); override;
    destructor  Destroy; override;
    procedure   Notification(AComponent: TComponent; operation: TOperation); override;
    function    MXLookup(Domain : String) : Integer;    { V8.64 }
    function    ALookup(Host : String) : Integer;       { V8.64 }
    function    PTRLookup(IP : String) : Integer;       { V8.64 }
    function    QueryAll(Host : String) : Integer;      { V8.64 }
    function    QueryAny(Host : String; QNumber : integer; MultiRequests: Boolean = False) : Integer;  { V8.64 }
    procedure   AbortQuery;                                { V8.61 }
    property ResponseID                 : Integer read FResponseID;
    property ResponseCode               : Integer read FResponseCode;
    property ResponseOpCode             : Integer read FResponseOpCode;
    property ResponseAuthoritative      : Boolean read FResponseAuthoritative;
    property ResponseTruncation         : Boolean read FResponseTruncation;
    property ResponseRecursionAvailable : Boolean read FResponseRecursionAvailable;
    property ResponseQDCount            : Integer read FResponseQDCount;
    property ResponseANCount            : Integer read FResponseANCount;
    property ResponseNSCount            : Integer read FResponseNSCount;
    property ResponseARCount            : Integer read FResponseARCount;
    property ResponseBuf                : PAnsiChar   read GetResponseBuf;
    property ResponseLen                : Integer read FResponseLen;
    property QuestionType               : Integer read FQuestionType;
    property QuestionClass              : Integer read FQuestionClass;
    property QuestionName               : String  read FQuestionName;       { V8.64 }
    property AnswerName[nIndex : Integer]   : String  read GetAnswerName;   { V8.64 }
    property AnswerType[nIndex : Integer]   : Integer read GetAnswerType;
    property AnswerClass[nIndex : Integer]  : Integer read GetAnswerClass;
    property AnswerTTL[nIndex : Integer]    : LongInt read GetAnswerTTL;
    property AnswerTag[nIndex : Integer]    : Integer read GetAnswerTag;
    property AnswerRecord[nIndex : Integer] : TRRRecord read GetAnswerRecord;  { V8.61 }
    property AnswerTotal                    : Integer read FAnsTot;            { V8.61 }
    property MXPreference[nIndex : Integer] : Integer read GetMXPreference;
    property MXExchange[nIndex : Integer]   : String  read GetMXExchange;    { V8.64 }
    property Address[nIndex : Integer]      : TInAddr read GetAddress;
    property Hostname[nIndex : Integer]     : String  read GetHostname;      { V8.64 }
    property Loc                            : TLOCInfo read fLOCInfo;
  published
    property Port    : String read  FPort  write FPort;
    property Addr    : String read  FAddr  write SetAddr;
    property Proto   : String read  FProto write SetProto;
    property MultiThreaded   : Boolean            read  GetMultiThreaded
                                                  write SetMultiThreaded;
    property OnRequestDone : TDnsRequestDoneEvent read  FOnRequestDone
                                                  write FOnRequestDone;
  end;


function ReverseIP(const IP : String) : AnsiString;
function ReverseIPv6(const IPv6: String): AnsiString;  { V8.61 }
function LongLatToDMS(longlat : longint; hemis : AnsiString) : AnsiString; { !!KAP!! }
function Loc2Geo(loc : TLOCInfo) : TLogGeo;                        { !!KAP!! }
function FindDnsReqTypeName(TypeID: Integer): String;  { V8.61 }
function FindDnsReqTypeId(TypeName: String): Integer;  { V8.61 }

implementation

type
    PWORD  = ^WORD;
    PDWORD = ^DWORD;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function ReverseIP(const IP : String) : AnsiString;   { V8.64 was ansi }
var
    I, J : Integer;
begin
    Result := '';
    if Length(IP) = 0 then
        Exit;
    J := Length(IP);
    I := J;
    while I >= 0 do begin
        if (I = 0) or (IP[I] = '.') then begin
            Result := Result + '.' + AnsiString(Copy(IP, I + 1, J - I));
            J := I - 1;
        end;
        Dec(I);
    end;
    if Result[1] = '.' then
        Delete(Result, 1, 1);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function ReverseIPv6(const IPv6: String): AnsiString;    { V8.61 } { V8.64 was ansi }
var
    I, J: Integer;
    Pair: Word;
    IPv6Addr: TIcsIPv6Address;
    Success: Boolean;
    Hex: AnsiString;
begin
    Result := '';
    IPv6Addr := WSocketStrToIPv6(IPv6, Success);
    if NOT Success then Exit;
    for I := 7 downto 0 do begin
        pair := IPv6Addr.Words[I];
    {$IFNDEF BIG_ENDIAN}
        pair := IcsSwap16(pair);
    {$ENDIF}
        Hex := AnsiString(IntToHex(pair, 4));
        for J := 4 downto 1 do
            Result := Result + Hex[J] + '.';
    end;
    Result := IcsLowerCaseA(Result);
    SetLength(Result, Length(Result) - 1);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function FindDnsReqTypeName(TypeID: Integer): String;  { V8.61 }
var
    I: integer;
begin
    Result := '';
    for I := Low(DnsReqTable) to High(DnsReqTable) do begin
        if DnsReqTable[I].Num = TypeID then begin
             Result := DnsReqTable[I].Asc;
             Exit;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function FindDnsReqTypeId(TypeName: String): Integer;  { V8.61 }
var
    I: integer;
begin
    Result := 0;
    for I := Low(DnsReqTable) to High(DnsReqTable) do begin
        if DnsReqTable[I].Asc = TypeName then begin
             Result := DnsReqTable[I].Num;
             Exit;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TDnsQuery.Create(AOwner : TComponent);
begin
    inherited Create(AOwner);
    FWSocket         := TWSocket.Create(nil);
    FPort            := '53';
    FProto           := 'tcp';
    FGotPacketLength := FALSE;
    FMultiReqSeq     := 0;
    FAnsTot          := 0;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
destructor TDnsQuery.Destroy;
begin
    if Assigned(FWSocket) then begin
        FWSocket.Destroy;
        FWSocket := nil;
    end;
    inherited Destroy;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TDnsQuery.SetMultiThreaded(const Value: Boolean);
begin
    if Assigned(FWSocket) then
        FWSocket.Multithreaded := Value;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TDnsQuery.GetMultiThreaded: Boolean;
begin
    if Assigned(FWSocket) then
        Result := FWSocket.Multithreaded
    else
        Result := FALSE;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TDnsQuery.SetProto(const Value: String);
var
    Buf : String;
begin
    Buf := LowerCase(Value);
    if not ((Buf = 'tcp') or (Buf = 'udp')) then
        raise Exception.Create('TDnsQuery accept only TCP or UDP protocol');
    FProto := Value;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TDnsQuery.SetAddr(const Value : String);  { V8.61 }
var
    I: Integer;
begin
    FAddr := Value;
    I := Pos (' [', FAddr);  // remove comment after IP address
    if I > 1 then SetLength (FAddr, I - 1);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TDnsQuery.Notification(AComponent: TComponent; operation: TOperation);
begin
    inherited Notification(AComponent, operation);
    if operation = opRemove then begin
        if AComponent = FWSocket then
            FWSocket := nil;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TDnsQuery.GetMXPreference(nIndex : Integer) : Integer;
begin
    { Silently ignore index out of bounds error }
    if (nIndex < Low(FMXPreferenceArray)) or
       (nIndex > High(FMXPreferenceArray)) then
        Result := 0
    else
        Result := FMXPreferenceArray[nIndex];
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TDnsQuery.GetMXExchange(nIndex : Integer) : String;  { V8.64 }
begin
    { Silently ignore index out of bounds error }
    if (nIndex < Low(FMXExchangeArray)) or
       (nIndex > High(FMXExchangeArray)) then
        Result := ''
    else
        Result := FMXExchangeArray[nIndex];
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TDnsQuery.GetAnswerName(nIndex : Integer) : String;  { V8.64 }
begin
    { Silently ignore index out of bounds error }
    if (nIndex < Low(FAnswerNameArray)) or
       (nIndex > High(FAnswerNameArray)) then
        Result := ''
    else
        Result := FAnswerNameArray[nIndex];
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TDnsQuery.GetAnswerType(nIndex : Integer) : Integer;
begin
    { Silently ignore index out of bounds error }
    if (nIndex < Low(FAnswerTypeArray)) or
       (nIndex > High(FAnswerTypeArray)) then
        Result := 0
    else
        Result := FAnswerTypeArray[nIndex];
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TDnsQuery.GetAnswerClass(nIndex : Integer) : Integer;
begin
    { Silently ignore index out of bounds error }
    if (nIndex < Low(FAnswerClassArray)) or
       (nIndex > High(FAnswerClassArray)) then
        Result := 0
    else
        Result := FAnswerClassArray[nIndex];
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TDnsQuery.GetAnswerTTL(nIndex : Integer) : LongInt;
begin
    { Silently ignore index out of bounds error }
    if (nIndex < Low(FAnswerTTLArray)) or
       (nIndex > High(FAnswerTTLArray)) then
        Result := 0
    else
        Result := FAnswerTTLArray[nIndex];
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TDnsQuery.GetAnswerTag(nIndex : Integer) : Integer;
begin
    { Silently ignore index out of bounds error }
    if (nIndex < Low(FAnswerTagArray)) or
       (nIndex > High(FAnswerTagArray)) then
        Result := 0
    else
        Result := FAnswerTagArray[nIndex];
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TDnsQuery.GetAnswerRecord(nIndex : Integer) : TRRRecord;   { V8.61 }
begin
    { Silently ignore index out of bounds error }
    if (nIndex < Low(FAnswerRecordArray)) or
       (nIndex > High(FAnswerRecordArray)) then
     //   Result := Nil
    else
        Result := FAnswerRecordArray[nIndex];
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TDnsQuery.GetAddress(nIndex : Integer) : TInAddr;
begin
    { Silently ignore index out of bounds error }
    if (nIndex < Low(FAddressArray)) or
       (nIndex > High(FAddressArray)) then
        Result.S_addr := 0
    else
        Result := FAddressArray[nIndex];
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TDnsQuery.GetHostname(nIndex : Integer) : String;  { V8.64 }
begin
    { Silently ignore index out of bounds error }
    if (nIndex < Low(FHostnameArray)) or
       (nIndex > High(FHostnameArray)) then
        Result := ''
    else
        Result := FHostnameArray[nIndex];
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TDnsQuery.GetResponseBuf : PAnsiChar;
begin
    Result := @FResponseBuf;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TDnsQuery.MXLookup(Domain : String) : Integer;
begin
    Result := QueryAny(Domain, DnsQueryMX);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TDnsQuery.ALookup(Host : String) : Integer;
begin
    Result := QueryAny(Host, DnsQueryA);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TDnsQuery.PTRLookup(IP : String) : Integer;
begin
    Result := QueryAny(IP, DnsQueryPTR);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
 { V8.61 simulate ALL by asking list of multiple questions }
function TDnsQuery.QueryAll(Host : String) : Integer;
begin
    FMultiReqSeq  := 1;
    FMultiHost := Host;
    FAnsTot := 0;
    Result := QueryAny(FMultiHost, DnsAllReqTable[FMultiReqSeq], True);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ V8.61 support all request }
function TDnsQuery.QueryAny(Host : String; QNumber : integer; MultiRequests: Boolean = False) : Integer;
begin
    Inc(FIDCount);
    if NOT MultiRequests then FAnsTot := 0;  { V8.61 reset result records }
    BuildRequestHeader(PDnsRequestHeader(@FQueryBuf), FIDCount, DnsOpCodeQuery, TRUE, 1, 0, 0, 0);
    FQueryLen := BuildQuestionSection(@FQueryBuf[SizeOf(TDnsRequestHeader)], Host, QNumber, DnsClassIN);
    FQueryLen := FQueryLen + SizeOf(TDnsRequestHeader);
    Result    := FIDCount;
    SendQuery;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TDnsQuery.AbortQuery;                                { V8.61 }
begin
    FWSocket.Abort;
    FResponseLen := -1;
    FMultiReqSeq  := 1;
    FMultiHost := '';
    FAnsTot := 0;
    TriggerRequestDone(999);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TDnsQuery.SendQuery;
begin
    FResponseLen                := -1;
    FGotPacketLength            := FALSE;
    FWSocket.OnDataAvailable    := nil;
    if FWSocket.State = wsConnected then FWSocket.Abort;
    FWSocket.OnDataAvailable    := WSocketDataAvailable;
    FWSocket.OnSessionConnected := WSocketSessionConnected;
    FWSocket.Proto              := FProto;
    FWSocket.Port               := FPort;
    FWSocket.Addr               := FAddr;
    FWSocket.Connect;
    { Note: UDP is connectionless, nevertheless, TWSocket call              }
    { OnSessionConnected event handler immediately. For TCP the event       }
    { handler is called only when session is connected (or fails to)        }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TDnsQuery.BuildQuestionSection(
    Dst         : PAnsiChar;
    QName       : String;   { V8.64 }
    QType       : WORD;
    QClass      : WORD) : Integer;
var
    I   : Integer;
    p   : PAnsiChar;
    Ptr : PAnsiChar;
    PunycodeHost: AnsiString;
    ErrFlag: Boolean;
begin
    Ptr := Dst;
    if Ptr = nil then begin
        Result := 0;
        Exit;
    end;
    I := 1;

// IPv6  4321:0:1:2:3:4:567:89ab becomes  b.a.9.8.7.6.5.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.0.0.0.0.1.2.3.4.ip6.arpa.
// IPv4  217.146.102.139 becomes 139.102.146.217.in-addr.arpa.
    if QType = DnsQueryPTR then begin   { V8.61 }
        if Pos (':', QName) > 1 then
            PunycodeHost := ReverseIPv6(QName) + '.ip6.arpa.'
        else
            PunycodeHost := ReverseIP(QName) + '.in-addr.arpa.';
    end
    else begin
    { V8.64 convert Unicode International Domain Name into Punycode ASCII }
    { ignore any conversion errors }
        PunycodeHost := AnsiString(IcsIDNAToASCII(IcsTrim(QName), False, ErrFlag));
        if ErrFlag then PunycodeHost := AnsiString(QName);
    end;

    while I <= Length(PunycodeHost) do begin
        p := Ptr;
        Inc(Ptr);
        while (I <= Length(PunycodeHost)) and (PunycodeHost[I] <> '.') do begin
            Ptr^ := PunycodeHost[I];
            Inc(Ptr);
            Inc(I);
        end;
        p^ := AnsiChar(Ptr - p - 1);
        Inc(I);
    end;
    Ptr^ := #0;
    Inc(Ptr);
    PWORD(Ptr)^ := WSocket_htons(QType);
    Inc(Ptr, 2);
    PWORD(Ptr)^ := WSocket_htons(QClass);
    Inc(Ptr, 2);
    Result := Ptr - Dst;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TDnsQuery.BuildRequestHeader(
    Dst       : PDnsRequestHeader;
    ID        : WORD;
    OPCode    : BYTE;
    Recursion : Boolean;
    QDCount   : WORD;
    ANCount   : WORD;
    NSCount   : WORD;
    ARCount   : WORD);
begin
    if Dst = nil then
        Exit;
    Dst^.ID      := WSocket_htons(ID);
    Dst^.Flags   := WSocket_htons((OpCode shl 11) + (Ord(Recursion) shl 8));
    Dst^.QDCount := WSocket_htons(QDCount);
    Dst^.ANCount := WSocket_htons(ANCount);
    Dst^.NSCount := WSocket_htons(NSCount);
    Dst^.ARCount := WSocket_htons(ARCount);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TDnsQuery.TriggerRequestDone(Error: WORD);
begin
    if Assigned(FOnRequestDone) then
        FOnRequestDone(Self, Error);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TDnsQuery.WSocketDataAvailable(Sender: TObject; Error: WORD);
var
    Len    : Integer;
begin
    FillChar(FResponseBuf, SizeOf(FResponseBuf), 0);  { V8.64 }
    if FProto = 'tcp' then begin
        if not FGotPacketLength then begin
            Len := FWSocket.PeekData(@FLengthByte, 2);
            if Len < 2 then
                Exit;
            FWSocket.Receive(@FLengthByte, 2);
            FGotPacketLength := TRUE;
        end;

        if not FGotPacketLength then
            Exit
        else begin
            Len := FWSocket.PeekData(@FResponseBuf, FLengthByte[0] * 256 + FLengthByte[1]);
            if Len < FLengthByte[0] * 256 + FLengthByte[1] then
                Exit;
            Len := FWSocket.Receive(@FResponseBuf, FLengthByte[0] * 256 + FLengthByte[1]);
            if Error <> 0 then begin
                TriggerRequestDone(Error);
                Exit;
            end;
        end;
    end
    else begin
        Len := FWSocket.Receive(@FResponseBuf, SizeOf(FResponseBuf));
        if Error <> 0 then begin
            TriggerRequestDone(Error);
            Exit;
        end;
    end;

 // get results
    DecodeWireResp(@FResponseBuf, Len); { V8.61 }
    FWSocket.Close;  // note TCP session closed each request

 // if simulating ALL request make next request in sequence
    if FMultiReqSeq > 0 then begin
        FMultiReqSeq := FMultiReqSeq + 1;
        if FMultiReqSeq <= DnsAllReqTot then begin
            QueryAny(FMultiHost, DnsAllReqTable[FMultiReqSeq], True);
            Exit;
        end;
        FMultiReqSeq := 0;
    end;
    TriggerRequestDone(0);  // all done
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function ntohs(V : WORD) : Integer;
begin
    Result := ((V and $FF) shl 8) or ((V shr 8) and $FF);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function ntohl(V : DWORD) : LongInt;
begin
    Result := (ntohs(V and $FFFF) shl 16) or ntohs((V shr 16) and $FFFF);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TDnsQuery.DecodeWireResp(RespBuffer: PAnsiChar; BufLen: Integer): Boolean; { V8.61 }
var
    AnsPtr: PDnsRequestHeader;
    Flags  : Integer;
    P, PEnd  : PAnsiChar;
    Temp: AnsiString;   { V8.64 }

    function ProcessRespRecord: Boolean;
    var
        RRRecord : TRRRecord;  { V8.61 keep everything in single record }
        RDataPtr : PAnsiChar;
    begin
        Result := False;
        FillChar(RRRecord, SizeOf(RRRecord), 0);
        P := ExtractName(RespBuffer, P, RRRecord.RRName);
     { V8.64 if rrname has ACE xn--. convert it to Unicode, ignore errors }
        RRRecord.AnswerName := IcsIDNAToUnicode(String(RRRecord.RRName));
        RRRecord.RRType := ntohs(PWORD(P)^);  { 06/03/2005 WSocket_ntohs(PWORD(P)^); }
      // ignore if SOA response to different question
        Inc(P, 2);
        RRRecord.RRClass := ntohs(PWORD(P)^);  { 06/03/2005 WSocket_ntohs(PWORD(P)^); }
        Inc(P, 2);
        RRRecord.TTL := ntohl(PDWORD(P)^); { 06/03/2005 WSocket_ntohl(PDWORD(P)^); }
        Inc(P, 4);
        RRRecord.RDLength := ntohs(PWORD(P)^);  { 06/03/2005 WSocket_ntohs(PWORD(P)^) };
        Inc(P, 2);
        RDataPtr := P;
        P := P + RRRecord.RDLength;
        if (RRRecord.RRType = DnsQuerySOA) and (FQuestionType <> DnsQuerySOA) then Exit;
        if FAnsTot >= MAX_ANCOUNT then Exit;  // sanity test, too many results

     // keep backward compatible vy filling old arrays
        FAnswerNameArray[FAnsTot] := RRRecord.AnswerName;   { V8.64 }
        FAnswerTypeArray[FAnsTot] := RRRecord.RRType;
        FAnswerClassArray[FAnsTot] := RRRecord.RRClass;
        FAnswerTTLArray[FAnsTot] := RRRecord.TTL;
        FAnswerTagArray[FAnsTot] := -1;

        case RRRecord.RRType of
            DnsQueryMX:  begin
                    if FMXRecordCount <= High(FMXPreferenceArray) then begin
                        FAnswerTagArray[FAnsTot] := FMXRecordCount;
                        RRRecord.MxPref := WSocket_ntohs(PWORD(RDataPtr)^);
                        FMXPreferenceArray[FMXRecordCount] := RRRecord.MxPref;
                        Inc(RDataPtr, 2);
                        ExtractName(RespBuffer, RDataPtr, RRRecord.RDData);
                    { V8.64 if result has ACE xn--. convert it to Unicode, ignore errors }
                        RRRecord.HostName := IcsIDNAToUnicode(String(RRRecord.RDData));
                        FMXExchangeArray[FMXRecordCount] := RRRecord.HostName;
                        Inc(FMXRecordCount);
                    end;
            end;
            DnsQueryA: begin
                    if FARecordCount <= High(FAddressArray) then begin
                        FAnswerTagArray[FAnsTot] := FARecordCount;
                        RRRecord.IPv4.S_addr := Integer(PDWORD(RDataPtr)^);   { 06/03/2005 added cast }
                        FAddressArray[FARecordCount].S_addr := RRRecord.IPv4.S_addr;
                        RRRecord.RDData := WSocket_inet_ntoa(RRRecord.IPv4);
                        Inc(FARecordCount);
                    end;
            end;
            DnsQueryPTR: begin
                    if FPTRRecordCount <= High(FHostnameArray) then begin
                        FAnswerTagArray[FAnsTot] := FPTRRecordCount;
                         SetLength(Temp, RRRecord.RDLength - 1);   { V8.64 }
                         Inc(RDataPtr, 1);  // skip length byte
                         Move(RDataPtr^, Temp[1], RRRecord.RDLength - 1);
                         RRRecord.RDData := Temp;  // us ascii conversion
                    { V8.64 if result has ACE xn--. convert it to Unicode, ignore errors }
                        RRRecord.HostName := IcsIDNAToUnicode(String(RRRecord.RDData));
                        FHostnameArray[FPTRRecordCount] := RRRecord.HostName;
                        Inc(FPTRRecordCount);
                    end;
            end;
            { !!KAP!! }
            DnsQueryLOC: begin
                    { for security reasons, if recompiled with future versions of delphi }
                    // alink.net return LOC!!
                    if (RRRecord.RDLength = 16) and (RRRecord.RDLength = sizeof(fLOCInfo)) then begin
                        Move(RDataPtr^, fLOCInfo, 16);
                        RRRecord.LocDecode := Loc2Geo(fLOCInfo);
                        RRRecord.RDData := AnsiString('Lat: ' + IntToStr(RRRecord.LocDecode.lad) + '°' +
                                         IntToStr(RRRecord.LocDecode.lam) + '''' +
                                         IntToStr(RRRecord.LocDecode.las) + '"' +
                                         ', Long: ' + IntToStr(RRRecord.LocDecode.lod) + '°' +
                                         IntToStr(RRRecord.LocDecode.lom) + '''' +
                                         IntToStr(RRRecord.LocDecode.los) + '"' +
                                         ', Alt: ' + IntToStr(RRRecord.LocDecode.altitude));
                    end
                    else
                        FillChar(fLOCInfo, SizeOf(fLOCInfo), 0);
            end;
            DnsQueryAAAA: begin
                   Move(RDataPtr^, RRRecord.IPv6, sizeof(RRRecord.IPv6));
                   RRRecord.RDData := AnsiString(WSocketIPv6ToStr (RRRecord.IPv6));  // April 2013
            end;
            DnsQuerySOA: begin
                   RDataPtr := ExtractName(RespBuffer, RDataPtr, RRRecord.SOA.mname);
                   RDataPtr := ExtractName(RespBuffer, RDataPtr, RRRecord.SOA.rname);
                   RRRecord.SOA.serial := WSocket_ntohl(PDWORD(RDataPtr)^);
                   Inc(RDataPtr, 4);
                   RRRecord.SOA.refresh := WSocket_ntohl(PDWORD(RDataPtr)^);
                   Inc(RDataPtr, 4);
                   RRRecord.SOA.retry := WSocket_ntohl(PDWORD(RDataPtr)^);
                   Inc(RDataPtr, 4);
                   RRRecord.SOA.expire := WSocket_ntohl(PDWORD(RDataPtr)^);
                   Inc(RDataPtr, 4);
                   RRRecord.SOA.minimum := WSocket_ntohl(PDWORD(RDataPtr)^);
                   RRRecord.RDData := AnsiString('name: ' + String(RRRecord.SOA.mname) +
                                    ', email: ' + String(RRRecord.SOA.rname) +
                                    ', serial: ' + IntToStr(RRRecord.SOA.serial) +
                                    ', refresh: ' + IntToStr(RRRecord.SOA.refresh) +
                                    ', retry: ' + IntToStr(RRRecord.SOA.retry) +
                                    ', expire: ' + IntToStr(RRRecord.SOA.expire) +
                                    ', default TTL: ' + IntToStr(RRRecord.SOA.minimum));
            end;

        // pending, DNSSEC buffers contain several fields, should handle them properly
        // so tempoarily return them as hex
            DnsQueryRRSIG, DnsQueryDNSKEY, DnsQueryDS, DnsQueryNSEC, DnsQueryNSEC3,
              DnsQueryCDS, DnsQueryCDNSKEY, DnsQueryTLSA, DnsQuerySMIMEA: begin
                 SetLength(Temp, RRRecord.RDLength);   { V8.64 }
                 Move(RDataPtr^ , Temp[1], RRRecord.RDLength);
                 RRRecord.RDData := AnsiString(IcsBufferToHex(Temp, RRRecord.RDLength));
            end
            else begin   // assume all other records are textual, TXT, etc
            //    ExtractName(RespBuffer, RDataPtr, RRRecord.RDData);  failed if multiple responses
                 SetLength(Temp, RRRecord.RDLength - 1);   { V8.64 }
                 Inc(RDataPtr, 1);  // skip length byte
                 Move(RDataPtr^ , Temp[1], RRRecord.RDLength - 1);
                 RRRecord.RDData := Temp;  // us ascii conversion
            end;
        end;
        FAnswerRecordArray[FAnsTot] := RRRecord;
        Result := True;
    end;

begin
    Result := False;
    { Check for minimum response length }
    if BufLen < SizeOf(TDnsRequestHeader) then
        Exit;
   AnsPtr := PDnsRequestHeader(RespBuffer);
   Flags := WSocket_ntohs(AnsPtr^.Flags);
    { Check if we got a response }
    if (Flags and $8000) = 0 then
        Exit;
    FResponseLen := BufLen;

    { Decode response header }
    FResponseID                 := WSocket_ntohs(AnsPtr^.ID);
    FResponseCode               := Flags and $000F;
//  fDnsRequestAnswer.qr        := (Flags and $8000) = $8000;
    FResponseOpCode             := (Flags shr 11) and $000F;
    FResponseAuthoritative      := (Flags and $0400) = $0400;
    FResponseTruncation         := (Flags and $0200) = $0200;
//  fDnsRequestAnswer.RecursionDesired := (Flags and $0100) = $0100;
    FResponseRecursionAvailable := (Flags and $0080) = $0080;
//  fDnsRequestAnswer.z         := (Flags shr 4) and $0007;
//  fDnsRequestAnswer.rcode     := (Flags and $000F);
    FResponseQDCount            := WSocket_ntohs(AnsPtr^.QDCount);
    FResponseANCount            := WSocket_ntohs(AnsPtr^.ANCount);
    FResponseNSCount            := WSocket_ntohs(AnsPtr^.NSCount);
    FResponseARCount            := WSocket_ntohs(AnsPtr^.ARCount);

    P := RespBuffer + SizeOf(TDnsRequestHeader);
    PEnd := RespBuffer + FResponseLen;
    PEnd^ := #0;  // V8.84 null at end of buffer
    if FResponseQDCount = 0 then begin
        { I don't think we could receive 0 questions }
        FQuestionName  := '';
        FQuestionType  := 0;
        FQuestionClass := 0;
    end
    else begin
        { Should never be greater than 1 because we sent only one question }
        P := ExtractName(RespBuffer, P, Temp);
        FQuestionName := String(Temp);              { V8.64 }
        FQuestionType := WSocket_ntohs(PWORD(P)^);
        Inc(P, 2);
        FQuestionClass := WSocket_ntohs(PWORD(P)^);
        Inc(P, 2);
    end;

    FMXRecordCount  := 0;
    FARecordCount   := 0;
    FPTRRecordCount := 0;
  // note we don't reset FAnsTot here to collect answers from multiple queries

 // read all answers
    while PEnd > P do begin
        if ProcessRespRecord then begin
          // special case, Cloudfare add empty record which we ignore
            if (FAnswerRecordArray[FAnsTot].RRType <> DnsQueryOPT) or
                            (FAnswerRecordArray[FAnsTot].RRName <> '') then
                                  FAnsTot := FAnsTot + 1;
         end;
    end;
    Result := True;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TDnsQuery.WSocketSessionConnected(Sender: TObject; Error: WORD);
var
    Buf: array [0..1] of BYTE;
begin
    if Error = 0 then begin
        if FProto = 'tcp' then begin { V6.03 }
            Buf[0] := FQueryLen div 256;
            Buf[1] := FQueryLen mod 256;
            { Send 2 byte length for tcp packets, see RFC 1035 - 4.2.2. TCP usage }
            FWSocket.Send(@Buf[0], 2);
        end;
        FWSocket.Send(@FQueryBuf, FQueryLen);
    end
    else
        TriggerRequestDone(Error);  { V8.61 don't ignore error }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TDnsQuery.ExtractName(
    Base       : PAnsiChar;
    From       : PAnsiChar;
    var Name   : AnsiString) : PAnsiChar;
var
    N       : Integer;
    I       : Integer;
    P       : PAnsiChar;
    NameEnd : AnsiString;
begin
    P := From;
    if P^ = #0 then begin
        Name := '';
        Inc(P);
    end
    else begin
        Name := '';
        while TRUE do begin
            { Get name part length }
            N := Ord(P^);
            if (N and $C0) = $C0 then begin
                 { Message compression }
                 N := ((N and $3F) shl 8) + Ord(P[1]);
                 if Length(Name) = 0 then
                     Self.ExtractName(Base, Base + N, Name)
                 else begin
                     Self.ExtractName(Base, Base + N, NameEnd);
                     Name := Name + NameEnd;
                 end;
                 Inc(P, 2);
                 break;
            end;
            Inc(P);
            if N = 0 then
                break;
            { Copy name part }
            for I := 1 to N do begin
                Name := Name + P^;
                Inc(P);
            end;
            if P^ <> #0 then
                Name := Name + '.';
        end;
    end;
    Result := P;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{
  <0><1><129><128><0><1><0><1><0><4><0><5><7>inp
  rise<3>com<0><0><15><0><1><192><12><0>
  <15><0><1><0><1>QV<0><10><0><10><5>drui
  d<192><12><192><12><0><2><0><1><0><1>Qc<0><6><3>
  ns1<192><12><192><12><0><2><0><1><0><1>Qc<0>
  <20><3>NS1<10>SPRINTLINK
  <3>NET<0><192><12><0><2><0><1><0><1>Qc<0>
  <6><3>NS2<192>U<192><12><0><2><0><1><0><1>Q
  c<0><6><3>NS3<192>U<192>+<0><1><0><1><0>
  <1>QV<0><4><143><186><11>F<192>?<0><1><0><1><0>
  <1>Qc<0><4><207>iS<30><192>Q<0><1><0><1><0>
  <2><144>i<0><4><204>u<214><10><192>q<0><1><0><1><0>
  <2><144>i<0><4><199><2><252><10><192><131><0><1><0><1><0>
  <2><142><182><0><4><204>a<212><10>
}
{
  <0><3><129><128><0><1><0><1><0><2><0><3><4>rtf
  m<2>be<0><0><15><0><1><192><12><0><15><0><1><0>
  <1>.b<0><9><0><10><4>mail<192><12><192><12>
  <0><2><0><1><0><1>.b<0><11><2>ns<3>dn
  s<2>be<0><192><12><0><2><0><1><0><1>.b<0>
  <5><2>ns<192><12><192>'<0><1><0><1><0><1>.b
  <0><4><195><0>d<253><192>:<0><1><0><1><0><1>QY
  <0><4><134>:J!<192>Q<0><1><0><1><0><1>.b
  <0><4><195><0>d<253>
}
{
  <0><7><133><128><0><1><0><1><0><2><0><2><3>www
  <4>rtfm<2>be<0><0><1><0><1><192><12><0>
  <1><0><1><0><1>Q<128><0><4><195><0>d<253><4>rt
  fm<2>be<0><0><2><0><1><0><1>Q<128><0><5>
  <2>ns<192>-<192>-<0><2><0><1><0><1>Q<128><0>
  <9><2>ns<3>dns<192>2<192>@<0><1><0><1>
  <0><1>Q<128><0><4><195><0>d<253><192>Q<0><1><0><1>
  <0><0><26><132><0><4><134>:J!
}
(*
<0><1><129><128><0><1><0><1><0><5><0><5><9>fu-berlin
<2>de<0><0>

<29><0><1><192><12><0><29><0><1><0><0>,

<0><16><0><21><22><19><139>Av<167><130><218>L<242>
<0><152><156>\<192><12><0><2><0><1><0><0><12><176>
<0>"<4>arbi<10>informatik<13>uni-oldenburg<2>de<0>
<192><12><0><2><0><1><0><0><12><176><0><12><5>deneb<3>
dfn<192>d<192><12><0><2><0><1><0><0><12><176><0><6><3>
ns3<192><12><192><12><0><2><0><1><0><0><12><176><0><6>
<3>ns2<192><12><192><12><0><2><0><1><0><0><12><176><0>
<6><3>ns1<192><12><192>F<0><1><0><1><0><0>t<169><0><4>
<134>j<1><7><192>t<0><1><0><1><0><0>9<209><0><4><192>L
<176><9><192><140><0><1><0><1><0><0>T<19><0><4><130>
<133><1>9<192><158><0><1><0><1><0><0><28><206><0><4>
<160>-<10><12><192><176><0><1><0><1><0><0>1<198><0>
<4><160>-<8><8>
*)

{ !!KAP!! }
{raw translation of some perl-source LOC.pm from package Net::DNS::RR::LOC;

fu-berlin.de   LOC  52 27 19.591 N 13 17 40.978 E 15.00m 1000.00m 10000.00m 10.00m
}
const conv_sec = 1000.0;
      conv_min = 60.0 * conv_sec;
      conv_deg = 60.0 * conv_min;
      zh31     = 1 shl 31;

procedure SubLOCgeo(longlat : longint;
                    hemis : AnsiString;
                    var ldeg, lmin, lsec, lmsec : Extended;
                    var hemic : AnsiChar);
var
    Labs : Extended;
begin
    LongLat := WSocket_ntohl(LongLat);
    Labs    := Abs(1.0 * LongLat - zh31);
    Ldeg    := Trunc(labs / conv_deg);
    Labs    := Labs - ldeg * conv_deg;
    Lmin    := Trunc(labs / conv_min);
    Labs    := Labs - lmin * conv_min;
    Lsec    := Trunc(labs / conv_sec);
    Labs    := Labs - lsec * conv_sec;
    Lmsec   := Labs;
    Hemic   := Copy(Hemis, 1 + ord(LongLat <= zh31), 1)[1]; { yeah. }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function LongLatToDMS(longlat : longint; hemis : AnsiString): AnsiString;
Var ldeg, lmin, lsec, lmsec : extended;
    hemi                    : AnsiChar;
begin
  SubLOCgeo(longlat,hemis,ldeg,lmin,lsec,lmsec,hemi);
  result := AnsiString(Format('%d %02d %02d.%03d',
               [round(ldeg), round(lmin), round(lsec),
                round(lmsec)]) + ' ' + Char(hemi));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ in cm!! }
function LocAltToAlt(Localt : LongInt) : LongInt;
begin
    Result := Round((WSocket_ntohl(localt) - 100000.0 * 100.0) / 100.0);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ !!KAP!! }
function Loc2Geo(loc : TLOCInfo):TLogGeo;
  { dolle umwandlung }
  procedure du(longlat : Integer;
               hemis   : AnsiString;
               var ideg, imin, isec, imsec : Integer;
               var hemic : AnsiChar);
  var
      ldeg, lmin, lsec, lmsec : extended;
  begin
      SubLOCgeo(longlat, hemis, ldeg, lmin, lsec, lmsec, hemic);
      ideg  := Round(ldeg);
      imin  := Round(lmin);
      isec  := Round(lsec);
      imsec := Round(lmsec);
  end;

begin
    Result.version  := Loc.version;
    Result.longsize := Round(Exp(Ln(10)*(loc.size and $f)));
    Result.latsize  := Round(Exp(Ln(10)*(loc.size shr 4)));

    Result.horizpre := Loc.horizpre;
    Result.vertpre  := Loc.vertpre;

    du(loc.latitude, 'NS', result.lad, result.lam,
       result.las, result.lams, result.lahem);
    du(loc.longitude, 'EW', result.lod, result.lom,
       result.los, result.loms, result.lohem);

    Result.altitude := LocAltToAlt(loc.altitude);
end;


end.
