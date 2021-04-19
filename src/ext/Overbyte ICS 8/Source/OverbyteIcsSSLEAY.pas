{*_* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Author:       François PIETTE
Description:  Delphi encapsulation for SSLEAY32.DLL (OpenSSL)
              Renamed libssl32.dll for OpenSSL 1.1.0 and later
              This is only the subset needed by ICS.
Creation:     Jan 12, 2003
Version:      8.64
EMail:        francois.piette@overbyte.be  http://www.overbyte.be
Support:      https://en.delphipraxis.net/forum/37-ics-internet-component-suite/
Legal issues: Copyright (C) 2003-2020 by François PIETTE
              Rue de Grady 24, 4053 Embourg, Belgium.
              <francois.piette@overbyte.be>
              SSL implementation includes code written by Arno Garrels,
              Berlin, Germany, contact: <arno.garrels@gmx.de>

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
Dec 11, 2004 Fixed Load to correctly check for LoadLibrary failure and to
             return correct error number.
Nov 08, 2005 F. Piette Worked around Delphi 6 bug related to type redefinition.
             Search for NoTypeEnforce in the type declarations.
Nov 08, 2005 Arno Garrels - Checked non-dummy structures against different
             OpenSSL versions see comments.
             Changed declaration of TX509_EXTENSION according OpenSSL v.0.9.7g.
Nov 19, 2005 F. Piette fixed internal error for Delphi 5. Same fix as Delphi 6.
             Introduced symbol NoTypeEnforce for that purpose.
Dec 07, 2005 A. Garrels support of OSSL v0.9.8a added.
Jan 27, 2006 A. Garrels made BDS2006 (BCB & Pascal) compilers happy.
Mar 03, 2007 A. Garrels: Small changes to support OpenSSL 0.9.8e.
             Read comments in OverbyteIcsSslDefs.inc.
Jun 30, 2008 A.Garrels made some changes to prepare code for Unicode.
             Added a few constants and dummy records.
Aug 02, 2008 Still one PChar caught in one of the records.
Dec 20, 2009 A.Garrels added plenty of stuff. Some is not yet used some is, like
             Server Name Indication (SNI).
May 08, 2010 A. Garrels added two declarations required to support
             Open SSL 0.9.8n.
Apr 23, 2011 A. Garrels added C-macro f_SSL_clear_options.
Apr 24, 2011 Arno - Record TEVP_PKEY_st changed in 1.0.0 and had to
             be declared as dummy. See helper functions Ics_Ssl_EVP_PKEY_xxx
             in OverbyteIcsLibeay.pas.
May 03, 2011 Arno added some function declarations.
May 31, 2011 Arno removed the packed modifier from non-dummy records.
May 2012 - V8.00 - Arno added FireMonkey cross platform support with POSIX/MacOS
                   also IPv6 support, include files now in sub-directory
Mar 13, 2015 V8.01 Angus updated SSL_OP option literals, added TLS v1.1 and 1.2 methods
             Added functions need to generate DH keys for EDH ciphers with Forward Secrecy
             Note, only OpenSSL 1.0.1 and later are now supported, removed various conditionals
May 08, 2015 V8.02 Angus adding missing SSL_OP_SINGLE_ECDH_USE
Nov 20, 2015 V8.03 Eugene Kotlyarov added RSA key related stuff
Mar 3, 2016  V8.04 Angus support define OPENSSL_ALLOW_SSLV2 to load old OpenSSL
                     DLLs that still export such methods
May 24, 2016 V8.27 Angus match version to Wsocket where most of this API is used
             Initial support for OpenSSL 1.1.0, new DLL file names, old exports gone
             Moved all public GLIBEAY_xx variables here from OverbyteIcsLIBEAY
             Add public variable GSSLEAY_DLL_IgnoreNew which should be set to TRUE before calling
              any SSL functions if OpenSSL 1.1.0 should be ignored.  Otherwise libcrypto-1_1.dll
              found in the PATH will override libeay32.dll in the local directory
             Added public variable GSSL_BUFFER_SIZE defaults to 16384, previously fixed
               at 4096, may improve SSL performance if larger
             Added public variable GSSL_DLL_DIR if set before OpenSSL loaded,
               will use this directory for DLLs, must have trailing \
             Load now SsleayLoad, WhichFailedToLoad now SsleayWhichFailedToLoad
             Added f_SSL_get_ciphers and related functions to get lists of ciphers
             Added TSslHandshakeState more detail about handshakes in 1.1.0
             GetFileVerInfo renamed IcsGetFileVerInfo to prevent conflicts with other libs
June 26, 2016 V8.29 Angus Implement GSSL_DLL_DIR properly to report full file path on error
Aug 5, 2016   V8.31 Angus testing OpenSSL 1.1.0 beta 6
Aug 27, 2016  V8.32 Angus, suuport final release OpenSSL 1.1.0
                OpenSSL 64-bit DLLs have different file names with -x64 added
Sept 5, 2016  V8.34 Angus, make ICS work up to OpenSSL release 1.1.1
                (security and bug releases are 1.1.0a/b/etc with no changed exports, in theory)
              Added public variable GSSLEAY_DLL_IgnoreOld so only OpenSSL 1.1.0 and later are loaded
Oct 18, 2016  V8.35 Angus, major rewrite to simplify loading OpenSSL DLL functions
              Reversed V8.34 fix so this release only supports 1.1.0 not 1.1.1
              OPENSSL_ALLOW_SSLV2 gone with all SSLv2 functions
              stub more removed functions to save some exceptions
Oct 26, 2016  V8.36 Angus more clean up of old stuff gone from 1.1.0
Nov 15, 2016  V8.38 Added public variable GSSL_SignTest_Check to check OpenSSL
                DLLs are digitally signed, and GSSL_SignTest_Certificate to
                check for a valid certificate, both default to false
              Moved IcsGetFileVerInfo to OverbyteIcsUtils
Nov 22, 2016  V8.39 Added functions to check certificate params using X509_VERIFY_PARAM, X509_OBJECT
              Minimum OpenSSL supported is now 1.0.2 (1.0.1 support ceases Dec 2016)
Jan 27, 2017  V8.40 Added more functions to get and check context certs
              Added Protocol Message callback functions for handshake debugging
              Added Security Level functions (1.1.0 and later)
Feb 24, 2017  V8.41 Added more constants
June 13, 2017 V8.49 Fixes to build on MacOs
Sep 22, 2017  V8.50 Added more types
Nov 22, 2017  V8.51 Testing OpenSSL 1.1.1 that adds TLS/1.3
              Corrected various set options to be exports with 1.1.0 instead
                of macros earlier, also SSL_session_reused
              Added more constants and functions for 1.1.1, f_SSL_xx_groups
Feb 27, 2018  V8.52 Added more EVP functions for keys, hashing and signing
Jun 20, 2018  V8.55 Testing with OpenSSL 1.1.1 beta
Oct 10, 2018  V8.57 added APLN APIs and literals
                    Support OpenSSL 1.1.1 final with TLS/1.3
                    Moved some SSL types and lits from Wsocket
                    EVP_MAX_KEY_LENGTH now 64
Oct 19, 2018  V8.58 version only
Nov 27, 2018  V8.59 version only
Mar 18, 2019  V8.60 Next major OpenSSL version is 3.0.0 (due mid 2020)
                    Added sslSrvSecTls12Less and sslSrvSecTls13Only to disable
                      in server IcsHosts if TLS1.3 fails.
Jul 15, 2019  V8.62 Removed two ciphers from TSslPrivKeyCipher which we did not use.
                    SuppProtoAcmeV1 gone, two more added.
                    Added ICS_NID_acmeIdentifier created dynamically on startup.
May 07, 2020  V8.64 Changed sslSrvSecDefault to sslSrvSecHigh since TLSv1.1
                       disabled in most browsers from early 2020.
                    Added SSL_client_hello functions and SSL_bytes_to_cipher_list.
                    Added ChallDnsAuto and ChallDnsMan
                    Fixed declarations of f_SSL_clear, TProto_msg_cb and
                      f_SSL_bytes_to_cipher_list thanks to Ralf Junker.
                      

Notes - OpenSSL ssleay32 changes between 1.0.2 and 1.1.0 - August 2016

file ssleay32.dll > libssl-1_1.dll and libssl-1_1-x64.dll

OpenSSL now auto initialises using OPENSSL_init_crypto and OPENSSL_init_ssl
so these are gone:
method SSL_library_init
method SSL_load_error_strings

method SSL_state > SSL_get_state (with different return value)

new version selection using:
TLS_client_method
TLS_method
TLS_server_method
SSL_set_min_proto_version
SSL_set_max_proto_version

Old exports gone:
SSLv3_method
SSLv3_client_method
SSLv3_server_method
SSLv23_method
SSLv23_client_method
SSLv23_server_method
All version specific TLSv1_1x_methods deprecated so don't load them either

Macros which are now new exported functions (not done until V8.51, sorry):
SSL_CTX_get_options;
SSL_get_options
SSL_CTX_clear_options
SSL_clear_options
SSL_CTX_set_options
SSL_set_options
SSL_session_reused

Notes - OpenSSL libssl-1_1 changes between 1.1.0 and 1.1.1 - November 2017



 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{$B-}                                 { Enable partial boolean evaluation   }
{$T-}                                 { Untyped pointers                    }
{$X+}                                 { Enable extended syntax              }
{$H+}                                 { Use long strings                    }
{$J+}                                 { Allow typed constant to be modified }
{$I Include\OverbyteIcsDefs.inc}
{$I Include\OverbyteIcsSslDefs.inc}
{$A8}

unit OverbyteIcsSSLEAY;

{$IFDEF VER140}
    // Delphi 6 is bugged
    // [Erreur fatale] IcsSSLEAY.pas: Erreur interne : URW533
    {$DEFINE NoTypeEnforce}
{$ENDIF}
{$IFDEF VER130}
    // Delphi 5 is bugged
    // [Erreur fatale] IcsSSLEAY.pas: Erreur interne : URW533
    {$DEFINE NoTypeEnforce}
{$ENDIF}

interface

{$IFDEF USE_SSL}

uses
  {$IFDEF MSWINDOWS}
    {$IFDEF RTL_NAMESPACES}Winapi.Windows{$ELSE}Windows{$ENDIF},
  {$ENDIF}
  {$IFDEF POSIX}
    Posix.Errno,System.Types,   { V8.49 types needed for DWORD }
  {$ENDIF}
    {$IFDEF RTL_NAMESPACES}System.SysUtils{$ELSE}SysUtils{$ENDIF},
    OverbyteIcsTypes,
    OverbyteIcsUtils;

const
    IcsSSLEAYVersion   = 864;
    CopyRight : String = ' IcsSSLEAY (c) 2003-2020 F. Piette V8.64 ';

    EVP_MAX_IV_LENGTH                 = 16;       { 03/02/07 AG }
    EVP_MAX_BLOCK_LENGTH              = 32;       { 11/08/07 AG }
    EVP_MAX_KEY_LENGTH                = 64;       { 11/08/07 AG  { V8.52 was 32 }

{ const - why were these variables ever declared as const??? }
{ V8.27 consolidated from LIBEAY so all in one place }
var
    GLIBEAY_DLL_Handle          : THandle = 0;
    GLIBEAY_DLL_Name            : String  = {$IFDEF MACOS}
                                                '/usr/lib/libcrypto.dylib';
                                            {$ELSE}
                                                'libeay32.dll';
                                            {$ENDIF}
    GLIBEAY_110DLL_Name         : String  = {$IFDEF MACOS}
                                               '/usr/lib/libcrypto.dylib';  { V8.32 !!!! not tested, unknown file name }
                                            {$ELSE}
                                                {$IFDEF CPUX64}
                                                    'libcrypto-1_1-x64.dll';  { V8.32 }
                                                {$ELSE}
                                                    'libcrypto-1_1.dll';  { V8.27 }
                                                {$ENDIF}
                                             {$ENDIF}
    GLIBEAY_DLL_FileName        : String  = '*NOT LOADED*';
    GSSLEAY_DLL_Handle          : THandle = 0;
    GSSLEAY_DLL_Name            : String  = {$IFDEF MACOS}
                                                '/usr/lib/libssl.dylib';
                                            {$ELSE}
                                                'ssleay32.dll';
                                            {$ENDIF}
    GSSLEAY_110DLL_Name         : String  = {$IFDEF MACOS}
                                                '/usr/lib/libssl.dylib';
                                            {$ELSE}
                                                {$IFDEF CPUX64}
                                                    'libssl-1_1-x64.dll';  { V8.32 }
                                                {$ELSE}
                                                    'libssl-1_1.dll';   { V8.27 }
                                                {$ENDIF}
                                            {$ENDIF}
    GSSLEAY_DLL_FileName        : String  = '*NOT_LOADED*';
    GSSLEAY_DLL_FileVersion     : String = '';
    GSSLEAY_DLL_FileDescription : String = '';
 { V8.27 don't attempt to find new name libcrypto-1_1.dll, use libeay32.dll }
    GSSLEAY_DLL_IgnoreNew       : Boolean = False;
 { V8.34 only use libcrypto-1_1.dll, not libeay32.dll }
    GSSLEAY_DLL_IgnoreOld       : Boolean = False;
 { V8.27 write buffer size, was fixed at 4096, but send used a 16K buffer }
    GSSL_BUFFER_SIZE            : Integer = 16384;
 { V8.27 if set before OpenSSL loaded, will use this directory for DLLs, must have trailing \ }
    GSSL_DLL_DIR                : string = '';

 { V8.38 wintrust stuff for authenticode digital signing checking }
    GSSL_SignTest_Check         : Boolean = False;    { check OpenSSL DLLs are digitally signed }
    GSSL_SignTest_Certificate   : Boolean = False;    { False only checks hash, True also checks certificate (longer) }

    { Version stuff added 07/12/05  = V8.27 moved from OverbyteIcsLIBEAY  }
    ICS_OPENSSL_VERSION_NUMBER  : Longword  = 0;
    ICS_SSL_NO_RENEGOTIATION    : Boolean = FALSE;
    ICS_RAND_INIT_DONE          : Boolean = FALSE;   { V8.35 have we initialised random numbers }

  { V8.62 dynamically added NID objects, if any set need call OBJ_cleanup on close down }
    ICS_NID_acmeIdentifier      : Integer = 0;


const
 { found in \include\openssl\opensslv.h }
{ only supporting versions with TLS 1.1, 1.2 and 1.3 }
{ last digit is 0 for dev/beta, F for final release } 
{ V8.27 moved from OverbyteIcsLIBEAY  }
    OSSL_VER_MIN    = $0000000F; // minimum version     { V8.35 }
    OSSL_VER_1002   = $10002000; // 1.0.2 just briefly tested
    OSSL_VER_1002A  = $1000201F; // 1.0.2a just briefly tested
    OSSL_VER_1002ZZ = $10002FFF; // 1.0.2zz not yet released
    OSSL_VER_1100   = $1010000F; // 1.1.0 base final      { V8.32 }
    OSSL_VER_1100A  = $1010001F; // 1.1.0a                { V8.35 }
    OSSL_VER_1100B  = $1010002F; // 1.1.0b                { V8.35 }
    OSSL_VER_1100C  = $1010003F; // 1.1.0c                { V8.38 }
    OSSL_VER_1100D  = $1010004F; // 1.1.0d                { V8.41 }
    OSSL_VER_1100ZZ = $10100FFF; // 1.1.0zz not yet released  { V8.35 }
    OSSL_VER_1101   = $1010100F; // 1.1.1 base                { V8.57 }
    OSSL_VER_1101A  = $1010101F; // 1.1.1a                    { V8.59 }
    OSSL_VER_1101B  = $1010102F; // 1.1.1b                    { V8.59 }
    OSSL_VER_1101C  = $1010103F; // 1.1.1c                    { V8.64 }
    OSSL_VER_1101D  = $1010104F; // 1.1.1d                    { V8.65 }
    OSSL_VER_1101E  = $1010105F; // 1.1.1e                    { V8.66 }
    OSSL_VER_1101F  = $1010106F; // 1.1.1f                    { V8.66 }
    OSSL_VER_1101ZZ = $10101FFF; // 1.1.1zz not yet released  { V8.57 }
    OSSL_VER_30000  = $30000000; // 3.0.0 dev                 { V8.60 }
    OSSL_VER_MAX    = $FFFFFFFF; // maximum version           { V8.35 }

    { Basically versions listed above are tested if not otherwise commented.  }
    { Versions between are assumed to work, however they are untested.        }
    { OpenSSL libraries for ICS are available for download here:              }
    { http://wiki.overbyte.be/wiki/index.php/ICS_Download                     }

    MIN_OSSL_VER   = OSSL_VER_1002;   { V8.39 minimum is now 1.0.2 }
    MAX_OSSL_VER   = OSSL_VER_1101ZZ; { V8.57 1.1.1zz }

    { V8.41 PEM base64 file titles }
    PEM_STRING_HDR_BEGIN   = '-----BEGIN ';    { six hyphens }
    PEM_STRING_HDR_END     = '-----END ';
    PEM_STRING_HDR_TAIL    = '-----'+#13#10;
    PEM_STRING_X509_OLD    = 'X509 CERTIFICATE' ;
    PEM_STRING_X509        = 'CERTIFICATE' ;
    PEM_STRING_X509_TRUSTED= 'TRUSTED CERTIFICATE' ;
    PEM_STRING_X509_REQ_OLD= 'NEW CERTIFICATE REQUEST' ;
    PEM_STRING_X509_REQ    = 'CERTIFICATE REQUEST' ;
    PEM_STRING_X509_CRL    = 'X509 CRL' ;
    PEM_STRING_EVP_PKEY    = 'ANY PRIVATE KEY' ;
    PEM_STRING_PUBLIC      = 'PUBLIC KEY' ;
    PEM_STRING_RSA         = 'RSA PRIVATE KEY' ;
    PEM_STRING_RSA_PUBLIC  = 'RSA PUBLIC KEY' ;
    PEM_STRING_DSA         = 'DSA PRIVATE KEY' ;
    PEM_STRING_DSA_PUBLIC  = 'DSA PUBLIC KEY' ;
    PEM_STRING_PKCS7       = 'PKCS7' ;
    PEM_STRING_PKCS7_SIGNED= 'PKCS #7 SIGNED DATA' ;
    PEM_STRING_PKCS8       = 'ENCRYPTED PRIVATE KEY' ;
    PEM_STRING_PKCS8INF    = 'PRIVATE KEY' ;
    PEM_STRING_DHPARAMS    = 'DH PARAMETERS' ;
    PEM_STRING_DHXPARAMS   = 'X9.42 DH PARAMETERS' ;
    PEM_STRING_SSL_SESSION = 'SSL SESSION PARAMETERS' ;
    PEM_STRING_DSAPARAMS   = 'DSA PARAMETERS' ;
    PEM_STRING_ECDSA_PUBLIC= 'ECDSA PUBLIC KEY' ;
    PEM_STRING_ECPARAMETERS= 'EC PARAMETERS' ;
    PEM_STRING_ECPRIVATEKEY= 'EC PRIVATE KEY' ;
    PEM_STRING_PARAMETERS  = 'PARAMETERS' ;
    PEM_STRING_CMS         = 'CMS' ;

{ V8.56 TLS Application-Layer Protocol Negotiation (ALPN) Protocol IDs }
{ received from one client: h2,h2-14,h2-15,h2-16,h2-17,spdy/1,spdy/2,spdy/3,spdy/3.1,spdy/4,http/1.1,h2-fb,webrtc,c-webrtc,ftp }
    ALPN_ID_HTTP10        = 'http/1.0';
    ALPN_ID_HTTP11        = 'http/1.1';
    ALPN_ID_HTTP2         = 'h2';
    ALPN_ID_HTTP2S        = 'h2s';
    ALPN_ID_HTTP214       = 'h2-14';   { and -15, -16, -17 }
//    ALPN_ID_SPDY1         = 'spdy/1';
//    ALPN_ID_SPDY2         = 'spdy/2';
    ALPN_ID_SPDY3         = 'spdy/3';
    ALPN_ID_SPDY31        = 'spdy/3.1';
    ALPN_ID_TURN          = 'stun.turn';
    ALPN_ID_STUN          = 'stun.nat-discovery';
    ALPN_ID_WEBRTC        = 'webrtc';
    ALPN_ID_CWEBRTC       = 'c-webrtc';
    ALPN_ID_FTP           = 'ftp';
    ALPN_ID_IMAP          = 'imap';
    ALPN_ID_POP3          = 'pop3';
    ALPN_ID_ACME_TLS1     = 'acme-tls/1';


type

    TOSSLImports = record   { V8.35 }
        F: PPointer;   // function pointer
        N: PAnsiChar;  // export name
        MI: LongWord;  // minimum OpenSSL version
        MX: LongWord;  // maximum OpenSSL version
    end;

    EIcsSsleayException = class(Exception);
    PPChar   = ^PChar;
    PPAnsiChar = ^PAnsiChar;
    //PInteger = ^Integer;

    // All datatypes defined below using the Dummy array can't be used
    // directly. They all must be used thru pointers only. If you really need
    // to use those structure, you must replace Dummy member with the actual
    // members defined in the OpenSSL header !
    TCRYPTO_THREADID_st = packed record
        Dummy : array [0..0] of Byte;
          //ptr : Pointer;
          //val : LongWord;
    end;
    PCRYPTO_THREADID = ^TCRYPTO_THREADID_st;

{$IFNDEF OPENSSL_NO_ENGINE}
    TEngine_st = record
        Dummy : array [0..0] of Byte;
    end;
    PENGINE = ^TEngine_st;
{$ENDIF}

    TSSL_st = packed record
        Dummy : array [0..0] of Byte;
    end;
    PSSL            = ^TSSL_st;
    PPSSL           = ^PSSL;    { V8.51 } 

    TSSL_SESSION_st = packed record
        Dummy : array [0..0] of Byte;
    end;
    PSSL_SESSION    = ^TSSL_SESSION_st;
    PPSSL_SESSION   = ^PSSL_SESSION;

    TBIO_st = packed record
        Dummy : array [0..0] of Byte;
    end;
    PBIO            = ^TBIO_st;
    PPBIO           = ^PBIO;

    TBIO_METHOD_st = packed record
        Dummy : array [0..0] of Byte;
    end;
    PBIO_METHOD     = ^TBIO_METHOD_st;

    TSSL_CTX_st = packed record
        Dummy : array [0..0] of Byte;
    end;
    PSSL_CTX        = ^TSSL_CTX_st;

    TSSL_METHOD_st = packed record
        Dummy : array [0..0] of Byte;
    end;
    PSSL_METHOD     = ^TSSL_METHOD_st;

    TSSL_CIPHER_st = packed record           { V8.27 }
        Dummy : array [0..0] of Byte;
    end;
    PSSL_CIPHER     = ^TSSL_CIPHER_st;

    TX509_STORE_st = packed record
        Dummy : array [0..0] of Byte;
    end;
    PX509_STORE = ^TX509_STORE_st;

    TX509_STORE_CTX_st = packed record
        Dummy : array [0..0] of Byte;
    end;
    PX509_STORE_CTX = ^TX509_STORE_CTX_st;

    TX509_NAME_st = packed record
        Dummy : array [0..0] of Byte;
    end;
    PX509_NAME = ^TX509_NAME_st;

  { V8.50 internal representation of stack for debugging
    STACK = record
        num : LongInt;
        data : PPAnsiChar;
        sorted : LongInt;
        num_alloc : LongInt;
        comp : function (_para1: PPAnsiChar; _para2: PPAnsiChar):  LongInt; cdecl;
    end;

    STACK_OF = record
        _stack: STACK;
    end;
    PSTACK_OF = ^STACK_OF;
    PSTACK    = PSTACK_OF;   }

    BN_ULONG = Cardinal;               { V8.03 }
    PBN_ULONG = ^ BN_ULONG; 

    TBIGNUM_st = packed record         { V8.03 }
    //    Dummy : array [0..0] of Byte;
        d: PBN_ULONG;                  { V8.52 need for array }
        top: Integer;
        dmax: Integer;
        neg: Integer;
        flags: Integer;
    end;
    PBIGNUM = ^TBIGNUM_st;
    PPBIGNUM = ^PBIGNUM;                    { V8.52 }
    TBIGNUMS = array [0..0] of TBIGNUM_st;  { V8.52 }
    PBIGNUMS = ^TBIGNUMS;                   { V8.52 }
    PPBIGNUMS = ^PBIGNUMS;                  { V8.52 }

    TSTACK_st = packed record               //AG
        Dummy : array [0..0] of Byte;
    end;
    PSTACK = ^TSTACK_st;

    TASN1_TYPE_st = packed record                   //AG
        Dummy : array [0..0] of Byte;
    end;
    PASN1_TYPE = ^TASN1_TYPE_st;

    TX509_VERIFY_PARAM_st = packed record        { V8.39 }
        Dummy : array [0..0] of Byte;
    end;
    PX509_VERIFY_PARAM = ^TX509_VERIFY_PARAM_st;

    TBN_CTX_st = packed record                   { V8.40 }
        Dummy : array [0..0] of Byte;
    end;
    PBN_CTX = ^TBN_CTX_st;

    TEC_GROUP_st = packed record                 { V8.40 }
        Dummy : array [0..0] of Byte;
    end;
    PEC_GROUP = ^TEC_GROUP_st;

    TEC_METHOD_st = packed record                 { V8.40 }
        Dummy : array [0..0] of Byte;
    end;
    PEC_METHOD = ^TEC_METHOD_st;

    TEC_POINT_st = packed record                  { V8.40 }
     //   Dummy : array [0..0] of Byte;
        meth: PEC_METHOD;                  { V8.52 need full data for array }
        X: PBIGNUM;
        Y: PBIGNUM;
        Z: PBIGNUM;
        Z_is_one: Integer;
    end;
    PEC_POINT = ^TEC_POINT_st;
    TEC_POINTS = array[0..0] of TEC_POINT_st;    { V8.52 }
    PEC_POINTS = ^TEC_POINTS;                    { V8.52 }

    TEC_PKPARAMETERS_st = packed record           { V8.40 }
        Dummy : array [0..0] of Byte;
    end;
    PEC_PKPARAMETERS = ^TEC_PKPARAMETERS_st;

    TEC_PARAMETERS_st = packed record             { V8.40 }
        Dummy : array [0..0] of Byte;
    end;
    PEC_PARAMETERS = ^TEC_PARAMETERS_st;

    TEC_BUILTIN_CURVE_st = packed record          { V8.40 }
        nid: Integer;
        comment: PAnsiChar;
    end;
    PEC_BUILTIN_CURVE = ^TEC_BUILTIN_CURVE_st;
    TEC_BUILTIN_CURVES = array of TEC_BUILTIN_CURVE_st;

    TBN_MONT_CTX_st = packed record             { V8.40 }
        Dummy : array [0..0] of Byte;
    end;
    PBN_MONT_CTX = ^TBN_MONT_CTX_st;
    { Stack - dummies i.e. STACK_OF(X509) }

    PSTACK_OF_X509_EXTENSION    = PStack;     //AG
    PPSTACK_OF_X509_EXTENSION   = ^PSTACK_OF_X509_EXTENSION; { V8.41 }
    PSTACK_OF_X509_ALGOR        = PStack;     //AG

    PSTACK_OF_X509              = PSTACK;     //AG
    PSTACK_OF_X509_CRL          = PSTACK;     //AG

    PPSTACK_OF_X509             = ^PSTACK_OF_X509; //AG

    PSTACK_OF_PKCS7_RECIP_INFO  = PStack;     //AG
    PSTACK_OF_X509_ATTRIBUTE    = PStack;     //AG
    PSTACK_OF_PKCS7_SIGNER_INFO = PStack;     //AG
    PSTACK_OF_509_LOOKUP        = PStack;     //AG
    PSTACK_OF_X509_OBJECT       = PStack;     //AG

    PSTACK_OF_X509_NAME = {$IFNDEF NoTypeEnforce}type{$ENDIF} PStack;
    PSTACK_OF_X509_INFO = {$IFNDEF NoTypeEnforce}type{$ENDIF} PStack;
    PSTACK_OF_X509_VERIFY_PARAM = PStack;     { V8.39 }

    PSTACK_OF_SSL_CIPHER        = PSTACK;                 { V8.27 }
    PPSTACK_OF_SSL_CIPHER       = ^PSTACK_OF_SSL_CIPHER;  { V8.27 }
    PCRYPTO_EX_DATA             = PSTACK;                 { V8.40 }

    TX509_lookup_method_st = packed record
        Dummy : array [0..0] of Byte;
    end;
    PX509_LOOKUP_METHOD = ^TX509_lookup_method_st;

    TX509_lookup_st = packed record
        Dummy : array [0..0] of Byte;
    end;
    PX509_LOOKUP = ^TX509_lookup_st;

    TX509_OBJECT_st = packed record         //AG
        Dummy : array [0..0] of Byte;
    end;
    PX509_OBJECT = ^TX509_OBJECT_st;

    TX509_LOOKUP_TYPE = (X509_LU_NONE, X509_LU_X509, X509_LU_CRL);  { V8.39 }

    TX509_NAME_ENTRY_st = packed record      //AG
        Dummy : array [0..0] of Byte;
    end;
    PX509_NAME_ENTRY = ^TX509_NAME_ENTRY_st;

    TEVP_MD_st = packed record               //AG
        Dummy : array [0..0] of Byte;
    end;
    PEVP_MD = ^TEVP_MD_st;

    TEVP_MD_CTX_st = packed record      { V8.40 }
        Dummy : array [0..0] of Byte;
    end;
    PEVP_MD_CTX = ^TEVP_MD_CTX_st;

    TEVP_PKEY_CTX_st = packed record    { V8.40 }
        Dummy : array [0..0] of Byte;
    end;
    PEVP_PKEY_CTX = ^TEVP_PKEY_CTX_st;

    TRSA_st = packed record
        Dummy : array [0..0] of Byte;      //AG
    end;
    PRSA = ^TRSA_st;
    PPRSA = ^PRSA;                        { V8.03 }

    TCRYPTO_EX_DATA = record
        sk: PSTACK;
        dummy: Integer;
    end;

    TRSAreal = record                     { V8.52 only use for 1.0.2 }
        pad: Integer;
        version: LongWord;
        meth: Pointer;
        engine: Pointer;
        n: PBIGNUM;
        e: PBIGNUM;
        d: PBIGNUM;
        p: PBIGNUM;
        q: PBIGNUM;
        dmp1: PBIGNUM;
        dmq1: PBIGNUM;
        iqmp: PBIGNUM;
     //   prime_infos: Pointer;  // added in 1.1.0?
     //   pss: Pointer;          // added in 1.1.0?
        ex_data: TCRYPTO_EX_DATA;
        references: Integer;
        flags: Integer;
        _method_mod_n: Pointer;
        _method_mod_p: Pointer;
        _method_mod_q: Pointer;
        bignum_data: PAnsiChar; // where are bignums are physically stored
        blinding: Pointer;
        mt_blinding: Pointer;
    end;
    PRSAreal = ^TRSAreal;

    TDSA_st = packed record                //AG
        Dummy : array [0..0] of Byte;
    end;
    PDSA = ^TDSA_st;

    TDH_st = packed record                 //AG
        Dummy : array [0..0] of Byte;
    end;
    PDH = ^TDH_st;
    PPDH = ^PDH;                        { V8.40 }

    TEC_KEY_st = packed record                 //AG
        Dummy : array [0..0] of Byte;
    end;
    PEC_KEY = ^TEC_KEY_st;

    { We may no longer define it since changed in 1.0.0+               }
    { See helper functions Ics_Ssl_EVP_PKEYxxx in OverbyteIcsLibeay32  }
    TEVP_PKEY_st = packed record
        Dummy : array [0..0] of Byte;
    end;
    PEVP_PKEY = ^TEVP_PKEY_st;
    PPEVP_PKEY = ^PEVP_PKEY;

    TEVP_CIPHER_st = packed record
        Dummy : array [0..0] of Byte;
    end;
    PEVP_CIPHER = ^TEVP_CIPHER_st;

    TASN1_OBJECT_st = packed record
        Dummy : array [0..0] of Byte;
    end;
    PASN1_OBJECT = ^TASN1_OBJECT_st;

    PSTACK_OF_ASN1_OBJECT = PStack;     { V8.39 }

    TX509_ALGOR_st = record
        algorithm : PASN1_OBJECT;
        parameter : PASN1_TYPE;
    end;
    PX509_ALGOR = ^TX509_ALGOR_st;

    TX509_PURPOSE_st = packed record
        Dummy : array [0..0] of Byte;
    end;
    PX509_PURPOSE = ^TX509_PURPOSE_st;

    // 0.9.7g, 0.9.8a, 0.9.8e, 1.0.0d
    TASN1_STRING_st = record
        length : Integer;
        type_  : Integer;
        data   : PAnsiChar;
        //* The value of the following field depends on the type being
        //* held.  It is mostly being used for BIT_STRING so if the
        //* input data has a non-zero 'unused bits' value, it will be
        //* handled correctly */
        flags  : Longword;
    end;
    PASN1_STRING       = ^TASN1_STRING_st;
    TASN1_OCTET_STRING = TASN1_STRING_st;
    PASN1_OCTET_STRING = ^TASN1_OCTET_STRING;
    TASN1_BIT_STRING   = TASN1_STRING_st;
    PASN1_BIT_STRING   = ^TASN1_BIT_STRING;

    TASN1_TIME = {$IFNDEF NoTypeEnforce}type{$ENDIF} TASN1_STRING_st;
    PASN1_TIME = ^TASN1_TIME;

    TASN1_INTEGER = {$IFNDEF NoTypeEnforce}type{$ENDIF} TASN1_STRING_st;
    PASN1_INTEGER = ^TASN1_INTEGER;

    TASN1_VALUE_st = packed record
        Dummy : array [0..0] of Byte;
    end;
    PASN1_VALUE  = ^TASN1_VALUE_st;
    PPASN1_VALUE = ^PASN1_VALUE;

    Tasn1_pctx_st = packed record      { V8.40 }
        flags: DWORD;
        nm_flags: DWORD;
        cert_flags: DWORD;
        oid_flags: DWORD;
        str_flags: DWORD;
    end;
    PASN1_PCTX = ^Tasn1_pctx_st;       { V8.40 }

    POTHERNAME = ^TOTHERNAME;           { V8.50 }
    PPOTHERNAME = ^POTHERNAME;
    TOTHERNAME = record
        type_id: PASN1_OBJECT;
        value: PASN1_TYPE;
    end;

    PEDIPARTYNAME = ^TEDIPARTYNAME;     { V8.50 }
    PPEDIPARTYNAME = ^PEDIPARTYNAME;
    TEDIPARTYNAME = record
        nameAssigner: PASN1_STRING;
        partyName: PASN1_STRING;
    end;

    TASN1_IA5STRING = TASN1_STRING_st;     { V8.50 }
    PASN1_IA5STRING = ^TASN1_IA5STRING;

const
    GEN_OTHERNAME  = 0;          { V8.40 type of GENERAL_NAME }
    GEN_EMAIL      = 1;
    GEN_DNS        = 2;
    GEN_X400       = 3;
    GEN_DIRNAME    = 4;
    GEN_EDIPARTY   = 5;
    GEN_URI        = 6;
    GEN_IPADD      = 7;
    GEN_RID        = 8;

type
{ V8.50 help with debugging
    GENERAL_NAME_union = record
    case byte of
        0: (ptr: PAnsiChar);
        1: (otherName: POTHERNAME);
        2: (rfc822Name: PASN1_IA5STRING);
        3: (dNSName: PASN1_IA5STRING);
        4: (x400Address: PASN1_TYPE);
        5: (directoryName: PX509_NAME);
        6: (ediPartyName: PEDIPARTYNAME);
        7: (uniformResourceIdentifier: PASN1_IA5STRING);
        8: (iPAddress: PASN1_OCTET_STRING);
        9: (registeredID: PASN1_OBJECT);
        // Old names
        10: (ip: PASN1_OCTET_STRING);
        11: (dirn: PX509_NAME);
        12: (ia5: PASN1_IA5STRING);
        13: (rid: PASN1_OBJECT);
        14: (other: PASN1_TYPE);
    end;

    PGENERAL_NAME = ^GENERAL_NAME;
    PPGENERAL_NAME = ^PGENERAL_NAME;
    GENERAL_NAME = record
        gtype: LongInt;
        d:     GENERAL_NAME_union;
    end;   }

    TGENERAL_NAME_st  = packed record     { V8.40 }
        Dummy : array [0..0] of Byte;
    end;
    PGENERAL_NAME  = ^TGENERAL_NAME_st;

    // 0.9.7g, 0.9.8a 0.9.8e, 1.0.0d
    TEVP_CIPHER_INFO_st = record      { 03/02/07 AG }
        cipher : PEVP_CIPHER;
        iv     : array [0..EVP_MAX_IV_LENGTH - 1] of AnsiChar;
    end;
    EVP_CIPHER_INFO  = TEVP_CIPHER_INFO_st;
    PEVP_CIPHER_INFO = ^EVP_CIPHER_INFO;

    // 0.9.7g, 0.9.8a 0.9.8e, 1.0.0d
    TPrivate_key_st = record            //AG
        //Dummy : array [0..0] of Byte;
        version     : Integer;
        // The PKCS#8 data types
        enc_algor   : PX509_ALGOR;
        enc_pkey    : PASN1_OCTET_STRING; // encrypted pub key
        // When decrypted, the following will not be NULL
        dec_pkey    : PEVP_PKEY;
        // used to encrypt and decrypt
        key_length  : Integer ;
        key_data    : PAnsiChar;
        key_free    : Integer; // true if we should auto free key_data
        // expanded version of 'enc_algor'
        cipher      : PEVP_CIPHER_INFO;
        references  : Integer ;
    end;
    PX509_PKEY = ^TPrivate_key_st;

 {   TX509_REQ_st = packed record    V8.36 using longer version
        Dummy : array [0..0] of Byte;
    end;
    PX509_REQ = ^TX509_REQ_st;   }

    // 0.9.7g, 0.9.8a 0.9.8e, 1.0.0d
    TX509_CRL_INFO_st = record
        version     : PASN1_INTEGER;
        sig_alg     : PX509_ALGOR;
        issuer      : PX509_NAME;
        lastUpdate  : PASN1_TIME;
        nextUpdate  : PASN1_TIME;
        {
        STACK_OF(X509_REVOKED) *revoked;
        STACK_OF(X509_EXTENSION) /* [0] */ *extensions;
        ASN1_ENCODING enc; }
    end;
    PX509_CRL_INFO = ^TX509_CRL_INFO_st;

    TX509_CRL_st = record
        //* actual signature *//
        crl       : PX509_CRL_INFO;
        sig_alg   : PX509_ALGOR;
        signature : PASN1_BIT_STRING;
        references: Integer;
        {more..}
    end;
    PX509_CRL = ^TX509_CRL_st;
    PPX509_CRL = ^PX509_CRL;


    PX509  = ^TX509_st;
    PPX509 = ^PX509;

    // 0.9.7g, 0.9.8a 0.9.8e, 1.0.0d
    TX509_INFO_st = record
        x509        : PX509;
        crl         : PX509_CRL;
        x_pkey      : PX509_PKEY;
        enc_cipher  : EVP_CIPHER_INFO;
        enc_len     : Integer;
        enc_data    : PAnsiChar;
        references  : Integer;
    end;
    PX509_INFO = ^TX509_INFO_st;

    (* // 0.9.6g                  {11/07/05 AG}
    TX509_EXTENSION = packed record
        object_       : PASN1_OBJECT;
        critical      : SmallInt;
        netscape_hack : SmallInt;
        value         : PASN1_OCTET_STRING;
        method        : PX509V3_EXT_METHOD;
        ext_val       : Pointer;	        // extension value
    end;
    PX509_EXTENSION = ^TX509_EXTENSION;
    *)

    // 0.9.7g, 0.9.8a, 0.9.8e, 1.0.0d
    TX509_VAL_st = record                    {AG 02/06/06}
        notBefore : PASN1_TIME;
        notAfter  : PASN1_TIME;
    end;
    PX509_VAL = ^TX509_VAL_st;

    // 0.9.7g, 0.9.8a, 0.9.8e, 1.0.0d
    TX509_PUBKEY_st = record                 //AG
        algor       : PX509_ALGOR;
        public_key  : PASN1_BIT_STRING;
        pkey        : PEVP_PKEY;
    end;
    PX509_PUBKEY = ^TX509_PUBKEY_st;

    { Certinfo }  // 0.9.7g, 0.9.8a, 0.9.8e, 1.0.0d         {AG 02/06/06}
    TX509_CINF_st = record
        version         : PASN1_INTEGER;            // [ 0 ] default of v1
        serialNumber    : PASN1_INTEGER;
        signature       : PX509_ALGOR;
        issuer          : PX509_NAME;
        validity        : PX509_VAL;
        subject         : PX509_NAME;
        key             : PX509_PUBKEY;
        {issuerUID       : PASN1_BIT_STRING;         // [ 1 ] optional in v2
        subjectUID      : PASN1_BIT_STRING;         // [ 2 ] optional in v2
        extensions      : PSTACK_OF_X509_EXTENSION; // [ 3 ] optional in v3}
    end;
    PX509_CINF = ^TX509_CINF_st;

    // 0.9.7g, 0.9.8a, 0.9.8e, 1.0.0d             {11/07/05 AG}
    ASN1_BOOLEAN = {$IFNDEF NoTypeEnforce}type{$ENDIF} Longint;
    TX509_EXTENSION_st = record
        object_       : PASN1_OBJECT;
        critical      : ASN1_BOOLEAN;
        value         : PASN1_OCTET_STRING;
    end;
    PX509_EXTENSION = ^TX509_EXTENSION_st;

    // 0.9.7g, 0.9.8a, 0.9.8e, 1.0.0d
    TX509_st = record
        cert_info   : PX509_CINF;
        sig_alg     : PX509_ALGOR;
        signature   : PASN1_BIT_STRING;
        valid       : Integer ;
        references  : Integer;
        name        : PAnsiChar;
        {more ...}
    end;

// 8.35 moved lots of declarations from OverbyteIcsLibeayEx so they are all together

type
    TEVP_CIPHER_CTX_st = packed record
        Dummy : array [0..0] of Byte;
    end;
    PEVP_CIPHER_CTX = ^TEVP_CIPHER_CTX_st;

{$IFDEF OPENSSL_NO_ENGINE}
    TEngine_st = packed record
        Dummy : array [0..0] of Byte;
    end;
    PEngine = ^TEngine_st;
{$ENDIF}

    TASN1_ENCODING_st = packed record
        enc       : PAnsiChar;
        len       : LongWord;
        modified  : Integer;
    end;
    TASN1_ENCODING = TASN1_ENCODING_st;
    PASN1_ENCODING = ^TASN1_ENCODING_st;

    TLHASH_st = packed record
        Dummy : array [0..0] of Byte;
    end;
    PLHASH = ^TLHASH_st;

    TX509V3_CTX_st = packed record
        Dummy : array [0..0] of Byte;
    end;
    PX509V3_CTX = ^TX509V3_CTX_st;

    {TX509_PUBKEY_st = packed record
        algor       : PX509_ALGOR;
        public_key  : PASN1_BIT_STRING;
        pkey        : PEVP_PKEY;
    end;
    PX509_PUBKEY = ^TX509_PUBKEY_st;}

    TX509_REQ_INFO_st = packed record
        enc         : TASN1_ENCODING;
        version     : PASN1_INTEGER;
        subject     : PX509_NAME;
        pubkey      : PX509_PUBKEY;
        attributes  : PSTACK;
    end;
    PX509_REQ_INFO = ^TX509_REQ_INFO_st;

    TX509_REQ_st = packed record
        req_info    : PX509_REQ_INFO;
        sig_alg     : PX509_ALGOR;
        signature   : PASN1_STRING;
        references  : Integer;
    end;
    PX509_REQ = ^TX509_REQ_st;
    PPX509_REQ = ^PX509_REQ;            { V8.40 }

    TECDSA_SIG_st = packed record       { V8.40 }
        r  : PBIGNUM;
        s  : PBIGNUM;
    end;                    
    ECDSA_SIG = TECDSA_SIG_st;
    PECDSA_SIG = ^TECDSA_SIG_st;

    TBN_GENCB = packed record            { V8.40 }
        Dummy : array [0..0] of Byte;
    end;
    PBN_GENCB = ^TBN_GENCB;

    TPKCS7_ISSUER_AND_SERIAL_st = packed record     //AG
        Dummy : array [0..0] of Byte;
    end;
    PPKCS7_ISSUER_AND_SERIAL = ^TPKCS7_ISSUER_AND_SERIAL_st;

    TPKCS7_ENC_CONTENT_st = packed record           //AG
        Dummy : array [0..0] of Byte;
    end;
    PPKCS7_ENC_CONTENT = ^TPKCS7_ENC_CONTENT_st;

    TPKCS7_DIGEST_st = packed record                //AG
        Dummy : array [0..0] of Byte;
    end;
    PPKCS7_DIGEST = ^TPKCS7_DIGEST_st;

    TPKCS7_ENCRYPT_st = packed record               //AG
        Dummy : array [0..0] of Byte;
    end;
    PPKCS7_ENCRYPT = ^TPKCS7_ENCRYPT_st;

    { Caution! Structures may change in future versions 0.96g-0.98 beta OK} {AG}
    { However needed for S/MIME PKCS#7 parsing }
    // 0.9.7g, 0.9.8a, 0.9.8e, 1.0.0d
    TPKCS7_SIGNER_INFO_st = record
        version             : PASN1_INTEGER;                // version 1
        issuer_and_serial   : PPKCS7_ISSUER_AND_SERIAL;
        digest_alg          : PX509_ALGOR;
        auth_attr           : PSTACK_OF_X509_ATTRIBUTE;     // [ 0 ]
        digest_enc_alg      : PX509_ALGOR;
        enc_digest          : PASN1_OCTET_STRING;
        unauth_attr         : PSTACK_OF_X509_ATTRIBUTE;     // [ 1 ]
        // The private key to sign with //
        pkey                : PEVP_PKEY;
    end;
    //PKCS7_SIGNER_INFO = ^TPKCS7_SIGNER_INFO_st; // **Name conflict with wincrypt.h**
    PKCS7_SIGNER_INFO_OSSL = ^TPKCS7_SIGNER_INFO_st;

    // 0.9.7g, 0.9.8a, 0.9.8e, 1.0.0d
    TPKCS7_ENVELOPED_st = record
        version       : PASN1_INTEGER;
        recipientinfo : PSTACK_OF_PKCS7_SIGNER_INFO;
        enc_data      : PPKCS7_ENC_CONTENT;
    end;
    PPKCS7_ENVELOPE = ^TPKCS7_ENVELOPED_st;

    PPKCS7  = ^TPKCS7_st;

    // 0.9.7g, 0.9.8a, 0.9.8e, 1.0.0d
    TPKCS7_SIGNED_st = record
        version     : PASN1_INTEGER;
        md_algs     : PSTACK_OF_X509_ALGOR;
        cert        : PSTACK_OF_X509;
        crl         : PSTACK_OF_X509_CRL;
        signer_info : PSTACK_OF_PKCS7_SIGNER_INFO;
        contents    : PPKCS7;
    end;
    PPKCS7_SIGNED = ^TPKCS7_SIGNED_st;

    // 0.9.7g, 0.9.8a, 0.9.8e, 1.0.0d
    PKCS7_signedandenveloped = record
        version         : PASN1_INTEGER;
        md_algs         : PSTACK_OF_X509_ALGOR;
        cert            : PSTACK_OF_X509;
        crl             : PSTACK_OF_X509_CRL;
        signer_info     : PSTACK_OF_PKCS7_SIGNER_INFO;
        enc_data        : PPKCS7_ENC_CONTENT;
        recipientinfo   : PSTACK_OF_PKCS7_RECIP_INFO;
    end;
    PPKCS7_SIGN_ENVELOPE = ^PKCS7_signedandenveloped;

    // 0.9.7g, 0.9.8a, 0.9.8e, 1.0.0d
    TPKCS7_st = record                         //AG
      { The following is non NULL if it contains ASN1 encoding of this structure }
        asn1        : PAnsiChar;
        length      : Integer;
        state       : Integer;
        detached    : Integer;
        type_       : PASN1_OBJECT;
        case Integer of
        0: (ptr                  : PAnsiChar);
        // NID_pkcs7_data
        1: (data                 : PASN1_OCTET_STRING);
        // NID_pkcs7_signed
        2: (sign                 : PPKCS7_SIGNED);
        // NID_pkcs7_enveloped
        3: (enveloped            : PPKCS7_ENVELOPE);
        // NID_pkcs7_signedAndEnveloped
        4: (signed_and_enveloped : PPKCS7_SIGN_ENVELOPE);
        // NID_pkcs7_digest
        5: (digest               : PPKCS7_DIGEST);
        // NID_pkcs7_encrypted
        6: (encrypted            : PPKCS7_ENCRYPT);
        // Anything else
        7: (other                : PASN1_TYPE);
    end;
    PPPKCS7 = ^PPKCS7;
    { Danger ends } {AG}

    TPKCS12_st = packed record                          //AG
        Dummy : array [0..0] of Byte;
    end;
    PPKCS12 = ^TPKCS12_st;
    PPPKCS12 = ^PPKCS12;


    TV3_EXT_CTX_st = packed record
        Dummy : array [0..0] of Byte;
    end;
    PV3_EXT_CTX = ^TV3_EXT_CTX_st;

    // 0.9.7g, 0.9.8a, 0.9.8e
    TCONF_VALUE = record
        Section : PAnsiChar;
        Name    : PAnsiChar;
        Value   : PAnsiChar;
    end;
    PCONF_VALUE = ^TCONF_VALUE;

     //used in old PostConnectionCheck()  {11/07/05 AG}
    { TCONF_VALUE_STACK_st = packed record
        Dummy : array [0..0] of Byte;
    end;
    PCONF_VALUE_STACK = ^TCONF_VALUE_STACK_st; }

    TASN1_ITEM_st  = packed record
        Dummy : array [0..0] of Byte;
    end;
    PASN1_ITEM  = ^TASN1_ITEM_st;

    PASN1_ITEM_EXP     = function: PASN1_ITEM; cdecl;
    PX509V3_EXT_NEW    = function: Pointer; cdecl;
    PX509V3_EXT_FREE   = procedure(Arg: Pointer); cdecl;
    PX509V3_EXT_D2I    = function(Arg1: Pointer; Arg2: PPAnsiChar; Arg3: LongInt): Pointer; cdecl;
    PX509V3_EXT_I2D    = function(Arg1: Pointer; Arg2: PPAnsiChar): Integer; cdecl;
    PX509V3_EXT_I2S    = function(X509V3_EXT_METHOD: Pointer; Ext: Pointer): PAnsiChar; cdecl;
    PX509V3_EXT_S2I    = function(X509V3_EXT_METHOD: Pointer; Ctx: PV3_EXT_CTX; S: PAnsiChar): Pointer; cdecl;
    PX509V3_EXT_I2V    = function(X509V3_EXT_METHOD: Pointer; Ext: Pointer; ExtList: PSTACK): PSTACK; cdecl;
    PX509V3_EXT_V2I    = function(X509V3_EXT_METHOD: Pointer; Ctx: PV3_EXT_CTX; Values: PSTACK): Pointer; cdecl;
    PX509V3_EXT_I2R    = function(X509V3_EXT_METHOD: Pointer; Ext: Pointer; Output: PBIO; Indent: Integer): Integer; cdecl;
    PX509V3_EXT_R2I    = function(X509V3_EXT_METHOD: Pointer; Ctx: PV3_EXT_CTX; S: PAnsiChar): Pointer; cdecl;

    // V3 extension structure 0.9.7g, 0.9.8a, 0.9.8e, 1.0.0d
    TX509V3_EXT_METHOD = record // struct v3_ext_method
        ext_nid   : Integer;
        ext_flags : Integer;

        // If this is set the following four fields are ignored - since v0.9.0.7
        it        : PASN1_ITEM_EXP;                              //AG

        // Old style ASN1 calls
        ext_new   : PX509V3_EXT_NEW;
        ext_free  : PX509V3_EXT_FREE;
        d2i       : PX509V3_EXT_D2I;
        i2d       : PX509V3_EXT_I2D;
        // The following pair is used for string extensions
        i2s       : PX509V3_EXT_I2S;
        s2i       : PX509V3_EXT_S2I;
        // The following pair is used for multi-valued extensions
        i2v       : PX509V3_EXT_I2V;
        v2i       : PX509V3_EXT_V2I;
        // The following are used for raw extensions
        i2r       : PX509V3_EXT_I2R;
        r2i       : PX509V3_EXT_R2I;
        // Any extension specific data
        usr_data  : Pointer;
    end;
    PX509V3_EXT_METHOD = ^TX509V3_EXT_METHOD;

    TPoint_Conversion_Form_t = byte;             { V8.52 }
       { the point is encoded as z||x, where the octet z specifies
         *  which solution of the quadratic equation y is  }
const
    POINT_CONVERSION_COMPRESSED = 2;
        { the point is encoded as z||x||y, where z is the octet 0x04  }
    POINT_CONVERSION_UNCOMPRESSED = 4;
        { the point is encoded as z||x||y, where the octet z specifies
           which solution of the quadratic equation y is  }
    POINT_CONVERSION_HYBRID = 6;

type
  { V8.27  The valid handshake states (one for each type message sent and one for each
           type of message received). There are also two "special" states:
     TLS = TLS or DTLS state
     DTLS = DTLS specific state
     CR/SR = Client Read/Server Read
     CW/SW = Client Write/Server Write
       The "special" states are:
     TLS_ST_BEFORE = No handshake has been initiated yet
     TLS_ST_OK = A handshake has been successfully completed }

    TSslHandshakeState = (       { V8.27 OSSL_HANDSHAKE_STATE for SSL_get_state }
        TLS_ST_Before,
        TLS_ST_OK,
        DTLS_ST_CR_Hello_Verify_Request,
        TLS_ST_CR_Srvr_Hello,
        TLS_ST_CR_Cert,
        TLS_ST_CR_Cert_Status,
        TLS_ST_CR_Key_Exch,
        TLS_ST_CR_Cert_Req,
        TLS_ST_CR_Srvr_Done,
        TLS_ST_CR_Session_Ticket,
        TLS_ST_CR_Change,
        TLS_ST_CR_Finished,
        TLS_ST_CW_Client_Hello,
        TLS_ST_CW_Cert,
        TLS_ST_CW_Key_Exch,
        TLS_ST_CW_Cert_Verify,
        TLS_ST_CW_Change,
        TLS_ST_CW_Next_Proto,
        TLS_ST_CW_Finished,
        TLS_ST_SW_Hello_Req,
        TLS_ST_SR_Client_Hello,
        DTLS_ST_SW_Hello_Verify_Request,
        TLS_ST_SW_Server_Hello,
        TLS_ST_SW_Cert,
        TLS_ST_SW_Key_Exch,
        TLS_ST_SW_Cert_Req,
        TLS_ST_SW_Server_Done,
        TLS_ST_SR_Cert,
        TLS_ST_SR_Key_Exch,
        TLS_ST_SR_Cert_Verify,
        TLS_ST_SR_Next_Proto,
        TLS_ST_SR_Change,
        TLS_ST_SR_Finished,
        TLS_ST_SW_Session_Ticket,
        TLS_ST_SW_Cert_Status,
        TLS_ST_SW_Change,
        TLS_ST_SW_Finished,
        TLS_ST_SW_Encrypted_Extensions,  { V8.51 lots more for TLS/1.3 }
        TLS_ST_CR_Encrypted_Extensions,
        TLS_ST_CR_Cert_Vrfy,
        TLS_ST_SW_Cert_Vrfy,
        TLS_ST_CR_Hello_Req,
        TLS_ST_SW_Hello_Retry_Request,
        TLS_ST_CR_Hello_Retry_Request,
        TLS_ST_SW_Key_Update,
        TLS_ST_CW_Key_Update,
        TLS_ST_SR_Key_Update,
        TLS_ST_CR_Key_Update,
        TLS_ST_Early_Data,
        TLS_ST_Pending_Early_Data_End,
        TLS_ST_CW_End_Of_Early_Data,
        TLS_ST_SR_End_Of_Early_Data) ;

type
    TPem_password_cb = function(Buf      : PAnsiChar;
                                Num      : Integer;
                                RWFlag   : Integer;
                                UserData : Pointer) : Integer; cdecl;

    TRSA_genkey_cb = procedure(N1, N2 : Integer;     //AG
                               cb_arg : Pointer); cdecl;

    TSetVerify_cb = function(Ok : Integer; StoreCtx : PX509_STORE_CTX) : Integer; cdecl;
    TSetInfo_cb   = procedure(const ssl: PSSL; CbType: Integer; Val: Integer); cdecl;

    TNew_session_cb = function(const Ssl : PSSL; Sess : PSSL_SESSION): Integer; cdecl;
    PNew_session_cb = ^TNew_session_cb;
    TRemove_session_cb = procedure(const Ctx : PSSL_CTX; Sess : PSSL_SESSION); cdecl;
    PRemove_session_cb = ^TRemove_session_cb;
    TGet_session_cb = function(const Ssl : PSSL; SessID : Pointer; IdLen : Integer; Ref : PInteger) : PSSL_SESSION; cdecl;
    PGet_session_cb = ^TGet_session_cb;
    TClient_cert_cb = function (Ssl : PSSL; X509 : PPX509; PKEY : PPEVP_PKEY): Integer; cdecl;
    PClient_cert_cb = ^TClient_cert_cb;

    TCallback_ctrl_fp = procedure (p : Pointer); cdecl;
    TSsl_servername_cb = function (s: PSSL; var ad: Integer; arg: Pointer): Integer; cdecl;

    TProto_msg_cb = procedure (write_p, version, content_type: integer;
              buf: PAnsiChar; size_t: integer; ssl: PSSL; arg: Pointer); cdecl;   { V8.40 handshake protocol message callback, V8.64 not a function }

    TSecurity_level_cb = function  (s: PSSL; ctx: PSSL_CTX; op, bits,
              nid: integer; other, ex: Pointer): Integer; cdecl;  { V8.40 security level callback }

    TSsl_alpn_cb = function (s: PSSL; var output: Pointer; var outlen: Integer;
              input: Pointer; inlen: Integer; arg: Pointer): Integer; cdecl;  { V8.56 application layer protocol callback }

    TSsl_client_hello_cb = function(s: PSSL; var al: Integer; arg: Pointer): Integer; cdecl; { V8.64 client hello callback, 1.1.1 and later, replaces servername_cb }


const
    SSL2_VERSION                                = $0002;
    SSL2_VERSION_MAJOR                          = $00;
    SSL2_VERSION_MINOR                          = $02;

    SSL3_VERSION                                = $0300;
    SSL3_VERSION_MAJOR                          = $03;
    SSL3_VERSION_MINOR                          = $00;

    TLS1_VERSION                                = $0301;
    TLS1_VERSION_MAJOR                          = $03;
    TLS1_VERSION_MINOR                          = $01;

    TLS1_1_VERSION                              = $0302;  // V8.01
    TLS1_1_VERSION_MAJOR                        = $03;    // V8.01
    TLS1_1_VERSION_MINOR                        = $02;    // V8.01

    TLS1_2_VERSION                              = $0303;  // V8.01
    TLS1_2_VERSION_MAJOR                        = $03;    // V8.01
    TLS1_2_VERSION_MINOR                        = $03;    // V8.01

    TLS1_3_VERSION                              = $0304;  // V8.40
    TLS1_3_VERSION_MAJOR                        = $03;    // V8.40
    TLS1_3_VERSION_MINOR                        = $04;    // V8.40

    TLS_MAX_VERSION                             = TLS1_3_VERSION;  // V8.51
    TLS_ANY_VERSION                             = $10000;          // V8.27

{$IFNDEF NO_DEBUG_LOG}
{ V8.40 literals for Protocol Message debugging }
type
    TLitLookups = record
        S: String;
        L: integer;
    end ;

const
{ V8.51 following for rotoMsgCallback }
    SSL3_RT_CHANGE_CIPHER_SPEC     = 20;
    SSL3_RT_ALERT                  = 21;
    SSL3_RT_HANDSHAKE              = 22;
    SSL3_RT_APPLICATION_DATA       = 23;
    DTLS1_RT_HEARTBEAT             = 24;

    LitsSslVersions:  array[0..4] of TLitLookups = (
        (S: 'SSL 3.0'; L: SSL3_VERSION),
        (S: 'TLS 1.0'; L: TLS1_VERSION),
        (S: 'TLS 1.1'; L: TLS1_1_VERSION),
        (S: 'TLS 1.2'; L: TLS1_2_VERSION),
        (S: 'TLS 1.3'; L: TLS1_3_VERSION) );


    LitsAlertTypes:  array[0..31] of TLitLookups = (
        (S: 'Close Notify'; L:  0),
        (S: 'Unexpected Message'; L:  10),
        (S: 'Bad Record Mac'; L:  20),
        (S: 'Decryption Failed'; L:  21),
        (S: 'Record Overflow'; L:  22),
        (S: 'Decompression Failure'; L:  30),
        (S: 'Handshake Failure'; L:  40),
        (S: 'Bad Certificate'; L:  42),
        (S: 'Unsupported Certificate'; L:  43),
        (S: 'Certificate Revoked'; L:  44),
        (S: 'Certificate Expired'; L:  45),
        (S: 'Certificate Unknown'; L:  46),
        (S: 'Illegal Parameter'; L:  47),
        (S: 'Unknown CA'; L:  48),
        (S: 'Access Denied'; L:  49),
        (S: 'Decode Error'; L:  50),
        (S: 'Decrypt Error'; L:  51),
        (S: 'Export Restriction'; L:  60),
        (S: 'Protocol Version'; L:  70),
        (S: 'Insufficient Security'; L:  71),
        (S: 'Internal Error'; L:  80),
        (S: 'Inappropriate Fallback'; L:  86),    { V8.51 }
        (S: 'User Cancelled'; L:  90),
        (S: 'No Renegotiation'; L:  100),
        (S: 'Missing Extension'; L:  109),         { V8.51 }
        (S: 'Unsupported Extension'; L:  110),
        (S: 'Certificate Unobtainable'; L:  111),
        (S: 'Unrecognized Name'; L:  112),
        (S: 'Bad Certificate Status Response'; L:  113),
        (S: 'Bad Certificate Hash Value'; L:  114),
        (S: 'Unknown PSK Identity'; L:  115),
        (S: 'Certificate required'; L:  116) ) ;   { V8.51 }

    SSL3_MT_HELLO_REQUEST                 = 0;
    SSL3_MT_CLIENT_HELLO                  = 1;
    SSL3_MT_SERVER_HELLO                  = 2;
    SSL3_MT_NEWSESSION_TICKET             = 4;
    SSL3_MT_END_OF_EARLY_DATA             = 5;
    SSL3_MT_HELLO_RETRY_REQUEST           = 6;
    SSL3_MT_ENCRYPTED_EXTENSIONS          = 8;
    SSL3_MT_CERTIFICATE                   = 11;
    SSL3_MT_SERVER_KEY_EXCHANGE           = 12;
    SSL3_MT_CERTIFICATE_REQUEST           = 13;
    SSL3_MT_SERVER_DONE                   = 14;
    SSL3_MT_CERTIFICATE_VERIFY            = 15;
    SSL3_MT_CLIENT_KEY_EXCHANGE           = 16;
    SSL3_MT_FINISHED                      = 20;
    SSL3_MT_CERTIFICATE_STATUS            = 22;
    SSL3_MT_KEY_UPDATE                    = 24;
    SSL3_MT_NEXT_PROTO                    = 67;
    SSL3_MT_MESSAGE_HASH                  = 254;
    DTLS1_MT_HELLO_VERIFY_REQUEST         = 3;

    LitsHandshake:  array[0..20] of TLitLookups = (
        (S: 'Hello Request'; L:  SSL3_MT_HELLO_REQUEST),
        (S: 'Client Hello'; L:  SSL3_MT_CLIENT_HELLO),
        (S: 'Server Hello'; L:  SSL3_MT_SERVER_HELLO),
        (S: 'Hello Verify Request'; L:  3),
        (S: 'New Session Ticket'; L:  SSL3_MT_NEWSESSION_TICKET),
        (S: 'End of early data'; L:  SSL3_MT_END_OF_EARLY_DATA),       { V8.51 }
        (S: 'Hello retry request'; L:SSL3_MT_HELLO_RETRY_REQUEST),     { V8.51 }
        (S: 'Encrypted extensions'; L:SSL3_MT_ENCRYPTED_EXTENSIONS),   { V8.51 }
        (S: 'Certificate'; L:  SSL3_MT_CERTIFICATE),
        (S: 'Server Key Exchange'; L:  SSL3_MT_SERVER_KEY_EXCHANGE),
        (S: 'Certificate Request'; L:  SSL3_MT_CERTIFICATE_REQUEST),
        (S: 'Server Hello Done'; L:  SSL3_MT_SERVER_DONE),
        (S: 'Certificate Verify'; L:  SSL3_MT_CERTIFICATE_VERIFY),
        (S: 'Client Key Exchange'; L:  SSL3_MT_CLIENT_KEY_EXCHANGE),
        (S: 'Finished'; L:  SSL3_MT_FINISHED),
        (S: 'Certificate URL'; L:  21),
        (S: 'Certificate Status'; L:  SSL3_MT_CERTIFICATE_STATUS),
        (S: 'Supplemental Data'; L:  23) ,
        (S: 'Key update'; L:SSL3_MT_KEY_UPDATE),                { V8.51 }
        (S: 'Next Proto'; L:SSL3_MT_NEXT_PROTO),                { V8.51 }
        (S: 'Message Hash'; L:SSL3_MT_MESSAGE_HASH) ) ;         { V8.51 }

{$ENDIF}

const

 {   DTLS1_2_VERSION is for UDP, sorry not supported yet }

    BIO_NOCLOSE                                 = 0;
    BIO_CLOSE                                   = 1;
    SSL_ERROR_NONE                              = 0;
    SSL_ERROR_SSL                               = 1;
    SSL_ERROR_WANT_READ                         = 2;
    SSL_ERROR_WANT_WRITE                        = 3;
    SSL_ERROR_WANT_X509_LOOKUP                  = 4;
    SSL_ERROR_SYSCALL                           = 5;
    SSL_ERROR_ZERO_RETURN                       = 6;
    SSL_ERROR_WANT_CONNECT                      = 7;
    SSL_ERROR_WANT_ACCEPT                       = 8;
    SSL_ERROR_WANT_ASYNC                        = 9;  { V8.51 following new }
    SSL_ERROR_WANT_ASYNC_JOB                    = 10;
    SSL_ERROR_WANT_CLIENT_HELLO_CB              = 11;

    X509_FILETYPE_PEM                           = 1;
    X509_FILETYPE_ASN1                          = 2;
    X509_FILETYPE_DEFAULT                       = 3;

    X509_EXT_PACK_UNKNOWN                       = 1;
    X509_EXT_PACK_STRING                        = 2;

    SSL_FILETYPE_ASN1                           = X509_FILETYPE_ASN1;
    SSL_FILETYPE_PEM                            = X509_FILETYPE_PEM;
    SSL_VERIFY_NONE                             = 0;
    SSL_VERIFY_PEER                             = 1;
    SSL_VERIFY_FAIL_IF_NO_PEER_CERT             = 2;
    SSL_VERIFY_CLIENT_ONCE                      = 4;

    { V8.27 Flags for building certificate chains )
    { treat any existing certificates as untrusted CAs }
    SSL_BUILD_CHAIN_FLAG_UNTRUSTED              = $00000001;
    { Don't include root CA in chain }
    SSL_BUILD_CHAIN_FLAG_NO_ROOT                = $00000002;
    { Just check certificates already there }
    SSL_BUILD_CHAIN_FLAG_CHECK                  = $00000004;
    { Ignore verification errors }
    SSL_BUILD_CHAIN_FLAG_IGNORE_ERROR           = $00000008;
    { clear verification errors from queue }
    SSL_BUILD_CHAIN_FLAG_CLEAR_ERROR            = $00000010;

    { Removed 12/07/05 - due to changes in v0.9.8a - restored and corrected V8.01 }
 { V8.51 pending, remove some of these once support for 1.0.2 is abandoned }
//  SSL_CTRL_NEED_TMP_RSA                       = 1;     // V8.51 gone in 1.1.0
//  SSL_CTRL_SET_TMP_RSA                        = 2;     // V8.51 gone in 1.1.0
    SSL_CTRL_SET_TMP_DH                         = 3;
    SSL_CTRL_SET_TMP_ECDH                       = 4;
//  SSL_CTRL_SET_TMP_RSA_CB                     = 5;     // V8.51 gone in 1.1.0
    SSL_CTRL_SET_TMP_DH_CB                      = 6;
//  SSL_CTRL_SET_TMP_ECDH_CB                    = 7;     // V8.51 gone in 1.1.0
    SSL_CTRL_GET_SESSION_REUSED                 = 8;     // V8.51 gone in 1.1.0
    SSL_CTRL_GET_CLIENT_CERT_REQUEST            = 9;
    SSL_CTRL_GET_NUM_RENEGOTIATIONS             = 10;
    SSL_CTRL_CLEAR_NUM_RENEGOTIATIONS           = 11;
    SSL_CTRL_GET_TOTAL_RENEGOTIATIONS           = 12;
    SSL_CTRL_GET_FLAGS                          = 13;
    SSL_CTRL_EXTRA_CHAIN_CERT                   = 14;
    SSL_CTRL_SET_MSG_CALLBACK                   = 15;
    SSL_CTRL_SET_MSG_CALLBACK_ARG               = 16;
    SSL_CTRL_SET_MTU                            = 17; // only applies to datagram connections
    SSL_CTRL_SESS_NUMBER                        = 20;
    SSL_CTRL_SESS_CONNECT                       = 21;
    SSL_CTRL_SESS_CONNECT_GOOD                  = 22;
    SSL_CTRL_SESS_CONNECT_RENEGOTIATE           = 23;
    SSL_CTRL_SESS_ACCEPT                        = 24;
    SSL_CTRL_SESS_ACCEPT_GOOD                   = 25;
    SSL_CTRL_SESS_ACCEPT_RENEGOTIATE            = 26;
    SSL_CTRL_SESS_HIT                           = 27;
    SSL_CTRL_SESS_CB_HIT                        = 28;
    SSL_CTRL_SESS_MISSES                        = 29;
    SSL_CTRL_SESS_TIMEOUTS                      = 30;
    SSL_CTRL_SESS_CACHE_FULL                    = 31;
    SSL_CTRL_OPTIONS                            = 32;     // V8.51 gone in 1.1.0
    SSL_CTRL_MODE                               = 33;
    SSL_CTRL_GET_READ_AHEAD                     = 40;
    SSL_CTRL_SET_READ_AHEAD                     = 41;
    SSL_CTRL_SET_SESS_CACHE_SIZE                = 42;
    SSL_CTRL_GET_SESS_CACHE_SIZE                = 43;
    SSL_CTRL_SET_SESS_CACHE_MODE                = 44;
    SSL_CTRL_GET_SESS_CACHE_MODE                = 45;
    SSL_CTRL_GET_MAX_CERT_LIST                  = 50;   // V8.01
    SSL_CTRL_SET_MAX_CERT_LIST                  = 51;   // V8.01
    SSL_CTRL_SET_MAX_SEND_FRAGMENT              = 52;   // V8.01
    SSL_CTRL_SET_TLSEXT_SERVERNAME_CB           = 53;
    SSL_CTRL_SET_TLSEXT_SERVERNAME_ARG          = 54;
    SSL_CTRL_SET_TLSEXT_HOSTNAME                = 55;
    SSL_CTRL_SET_TLSEXT_DEBUG_CB                = 56;
    SSL_CTRL_SET_TLSEXT_DEBUG_ARG               = 57;
    SSL_CTRL_GET_TLSEXT_TICKET_KEYS             = 58;   // V8.01
    SSL_CTRL_SET_TLSEXT_TICKET_KEYS             = 59;   // V8.01
//  SSL_CTRL_SET_TLSEXT_OPAQUE_PRF_INPUT        = 60;   // V8.01   // V8.51 gone in 1.1.0
//  SSL_CTRL_SET_TLSEXT_OPAQUE_PRF_INPUT_CB     = 61;   // V8.01   // V8.51 gone in 1.1.0
//  SSL_CTRL_SET_TLSEXT_OPAQUE_PRF_INPUT_CB_ARG   = 62;   // V8.01 // V8.51 gone in 1.1.0
    SSL_CTRL_SET_TLSEXT_STATUS_REQ_CB           = 63;   // V8.01
    SSL_CTRL_SET_TLSEXT_STATUS_REQ_CB_ARG       = 64;   // V8.01
    SSL_CTRL_SET_TLSEXT_STATUS_REQ_TYPE         = 65;   // V8.01
    SSL_CTRL_GET_TLSEXT_STATUS_REQ_EXTS         = 66;   // V8.01
    SSL_CTRL_SET_TLSEXT_STATUS_REQ_EXTS         = 67;   // V8.01
    SSL_CTRL_GET_TLSEXT_STATUS_REQ_IDS          = 68;   // V8.01
    SSL_CTRL_SET_TLSEXT_STATUS_REQ_IDS          = 69;   // V8.01
    SSL_CTRL_GET_TLSEXT_STATUS_REQ_OCSP_RESP    = 70;   // V8.01
    SSL_CTRL_SET_TLSEXT_STATUS_REQ_OCSP_RESP    = 71;   // V8.01
    SSL_CTRL_SET_TLSEXT_TICKET_KEY_CB           = 72;   // V8.01
    DTLS_CTRL_GET_TIMEOUT                       = 73;   // V8.51
    DTLS_CTRL_HANDLE_TIMEOUT                    = 74;   // V8.51
    SSL_CTRL_SET_TLS_EXT_SRP_USERNAME_CB        = 75;   // V8.01
    SSL_CTRL_SET_SRP_VERIFY_PARAM_CB            = 76;   // V8.01
    SSL_CTRL_GET_RI_SUPPORT                     = 76; { 0.9.8n }
    SSL_CTRL_CLEAR_OPTIONS                      = 77;   //  0.9.8n - V8.51 gone in 1.1.0
    SSL_CTRL_CLEAR_MODE                         = 78;   // V8.01
    SSL_CTRL_SET_SRP_GIVE_CLIENT_PWD_CB         = 77;   // V8.01
    SSL_CTRL_SET_SRP_ARG                        = 78;   // V8.01
    SSL_CTRL_SET_TLS_EXT_SRP_USERNAME           = 79;   // V8.01
    SSL_CTRL_SET_TLS_EXT_SRP_STRENGTH           = 80;   // V8.01
    SSL_CTRL_SET_TLS_EXT_SRP_PASSWORD           = 81;   // V8.01
    SSL_CTRL_TLS_EXT_SEND_HEARTBEAT             = 85;   // V8.01
    SSL_CTRL_GET_TLS_EXT_HEARTBEAT_PENDING      = 86;   // V8.01
    SSL_CTRL_SET_TLS_EXT_HEARTBEAT_NO_REQUESTS  = 87;   // V8.01
    SSL_CTRL_GET_EXTRA_CHAIN_CERTS              = 82;   // V8.01
    SSL_CTRL_CLEAR_EXTRA_CHAIN_CERTS            = 83;   // V8.01
    SSL_CTRL_CHAIN                              = 88;   // V8.01
    SSL_CTRL_CHAIN_CERT                         = 89;   // V8.01
    SSL_CTRL_GET_CURVES                         = 90;   // V8.01  V8.51 curves now named groups for 1.1.1
    SSL_CTRL_SET_CURVES                         = 91;   // V8.01
    SSL_CTRL_SET_CURVES_LIST                    = 92;   // V8.01
    SSL_CTRL_GET_SHARED_CURVE                   = 93;   // V8.01
    SSL_CTRL_GET_GROUPS                         = 90;   // V8.51
    SSL_CTRL_SET_GROUPS                         = 91;   // V8.51
    SSL_CTRL_SET_GROUPS_LIST                    = 92;   // V8.51
    SSL_CTRL_GET_SHARED_GROUP                   = 93;   // V8.51
    SSL_CTRL_SET_ECDH_AUTO                      = 94;   // V8.01  // V8.51 gone in 1.1.0
    SSL_CTRL_SET_SIGALGS                        = 97;   // V8.01
    SSL_CTRL_SET_SIGALGS_LIST                   = 98;   // V8.01
    SSL_CTRL_CERT_FLAGS                         = 99;   // V8.01
    SSL_CTRL_CLEAR_CERT_FLAGS                   = 100;   // V8.01
    SSL_CTRL_SET_CLIENT_SIGALGS                 = 101;   // V8.01
    SSL_CTRL_SET_CLIENT_SIGALGS_LIST            = 102;   // V8.01
    SSL_CTRL_GET_CLIENT_CERT_TYPES              = 103;   // V8.01
    SSL_CTRL_SET_CLIENT_CERT_TYPES              = 104;   // V8.01
    SSL_CTRL_BUILD_CERT_CHAIN                   = 105;   // V8.01
    SSL_CTRL_SET_VERIFY_CERT_STORE              = 106;   // V8.01
    SSL_CTRL_SET_CHAIN_CERT_STORE               = 107;   // V8.01
    SSL_CTRL_GET_PEER_SIGNATURE_NID             = 108;   // V8.01
    SSL_CTRL_GET_SERVER_TMP_KEY                 = 109;   // V8.01
    SSL_CTRL_GET_RAW_CIPHERLIST                 = 110;   // V8.01
    SSL_CTRL_GET_EC_POINT_FORMATS               = 111;   // V8.01
    SSL_CTRL_GET_CHAIN_CERTS                    = 115;   // V8.01
    SSL_CTRL_SELECT_CURRENT_CERT                = 116;   // V8.01
    SSL_CTRL_SET_CURRENT_CERT                   = 117;   // V8.01
    SSL_CTRL_SET_DH_AUTO                        = 118;   // V8.27
    SSL_CTRL_CHECK_PROTO_VERSION                = 119;   // V8.01
    DTLS_CTRL_SET_LINK_MTU                      = 120;   // V8.01
    DTLS_CTRL_GET_LINK_MIN_MTU                  = 121;   // V8.01
    SSL_CTRL_GET_EXTMS_SUPPORT                  = 122;   // V8.27
    SSL_CTRL_SET_MIN_PROTO_VERSION              = 123;   // V8.27
    SSL_CTRL_SET_MAX_PROTO_VERSION              = 124;   // V8.27
    SSL_CTRL_SET_SPLIT_SEND_FRAGMENT            = 125;   // V8.27
    SSL_CTRL_SET_MAX_PIPELINES                  = 126;   // V8.27
    SSL_CTRL_GET_TLSEXT_STATUS_REQ_TYPE         = 127;   // V8.51
    SSL_CTRL_GET_TLSEXT_STATUS_REQ_CB           = 128;   // V8.51
    SSL_CTRL_GET_TLSEXT_STATUS_REQ_CB_ARG       = 129;   // V8.51
    SSL_CTRL_GET_MIN_PROTO_VERSION              = 130;   // V8.51 1.1.1
    SSL_CTRL_GET_MAX_PROTO_VERSION              = 131;   // V8.51 1.1.1

    SSL_CERT_SET_FIRST                          = 1;   // V8.27
    SSL_CERT_SET_NEXT                           = 2;   // V8.27
    SSL_CERT_SET_SERVER                         = 3;   // V8.27

    SSL_OP_MICROSOFT_SESS_ID_BUG                = $00000001;   // gone V8.51
    SSL_OP_NETSCAPE_CHALLENGE_BUG               = $00000002;   // gone V8.51

  // Allow initial connection to servers that don't support RI
    SSL_OP_LEGACY_SERVER_CONNECT                = $00000004;   // new V8.51
    SSL_OP_NETSCAPE_REUSE_CIPHER_CHANGE_BUG     = $00000008;   // gone V8.51
    SSL_OP_TLSEXT_PADDING                       = $00000010;   // V8.01
    SSL_OP_SSLREF2_REUSE_CERT_TYPE_BUG          = $00000000;   // gone V8.01
    SSL_OP_MICROSOFT_BIG_SSLV3_BUFFER           = $00000020;   // gone V8.51
    SSL_OP_SAFARI_ECDHE_ECDSA_BUG               = $00000040;   // V8.01
    SSL_OP_MSIE_SSLV2_RSA_PADDING               = $00000000;   //gone V8.01
    SSL_OP_SSLEAY_080_CLIENT_DH_BUG             = $00000080;   // gone V8.51
    SSL_OP_TLS_D5_BUG                           = $00000100;   // gone V8.51
    SSL_OP_TLS_BLOCK_PADDING_BUG                = $00000200;   // gone V8.51

  // In TLSv1.3 allow a non-(ec)dhe based kex_mode
    SSL_OP_ALLOW_NO_DHE_KEX                     = $00000400;   // new V8.51

    // Disable SSL 3.0/TLS 1.0 CBC vulnerability workaround that was added
    // in OpenSSL 0.9.6d.  Usually (depending on the application protocol)
    // the workaround is not needed.  Unfortunately some broken SSL/TLS
    //implementations cannot handle it at all, which is why we include
    //it in SSL_OP_ALL.
    SSL_OP_DONT_INSERT_EMPTY_FRAGMENTS          = $00000800;

    //* DTLS options */ since 0.9.8
    SSL_OP_NO_QUERY_MTU                         = $00001000;
    //Turn on Cookie Exchange (on relevant for servers)
    SSL_OP_COOKIE_EXCHANGE                      = $00002000;

    // Don't use RFC4507 ticket extension
    SSL_OP_NO_TICKET                            = $00004000;

    // Use Cisco's "speshul" version of DTLS_BAD_VER (as client)
    SSL_OP_CISCO_ANYCONNECT                     = $00008000;    // V8.01

    // As server, disallow session resumption on renegotiation
    SSL_OP_NO_SESSION_RESUMPTION_ON_RENEGOTIATION  = $00010000;

    // Don't use compression even if supported
    SSL_OP_NO_COMPRESSION                          = $00020000; // 1.0.0x

    // Permit unsafe legacy renegotiation { 0.9.8n }
    // which can be set with SSL_CTX_set_options(). This is really
    // not recommended unless you know what you are doing.
    SSL_OP_ALLOW_UNSAFE_LEGACY_RENEGOTIATION    = $00040000;

    // If set, always create a new key when using tmp_ecdh parameters
    SSL_OP_SINGLE_ECDH_USE                       = $00080000;  // V8.02 gone V8.51

  // Disable encrypt-then-mac
    SSL_OP_NO_ENCRYPT_THEN_MAC                   = $00080000;   // new V8.51

 // If set, always create a new key when using tmp_ecdh parameters
    SSL_OP_SINGLE_DH_USE                        = $00100000;    // gone V8.51

   // Set to always use the tmp_rsa key when doing RSA operations,
   // even when this violates protocol specs
    SSL_OP_EPHEMERAL_RSA                        = $00200000;     // gone V8.51

    // Set on servers to choose the cipher according to the server's
    // preferences */
    SSL_OP_CIPHER_SERVER_PREFERENCE             = $00400000;

    // If set, a server will allow a client to issue a SSLv3.0 version number
    // as latest version supported in the premaster secret, even when TLSv1.0
    // (version 3.1) was announced in the client hello. Normally this is
    // forbidden to prevent version rollback attacks.
    SSL_OP_TLS_ROLLBACK_BUG                     = $00800000;

   //  following lot deprecated for 1.1.0 and later, use min/max[proto instead
    SSL_OP_NO_SSLv2                             = $01000000;
    SSL_OP_NO_SSLv3                             = $02000000;
    SSL_OP_NO_TLSv1                             = $04000000;
    SSL_OP_NO_TLSv1_2                           = $08000000;     // V8.01
    SSL_OP_NO_TLSv1_1                           = $10000000;     // V8.01
    SSL_OP_NO_TLSv1_3                           = $20000000;     // new V8.51

// These next two were never actually used for anything since SSLeay
// zap so we have some more flags.
    SSL_OP_PKCS1_CHECK_1                        = $00000000;    // gone V8.01
    SSL_OP_PKCS1_CHECK_2                        = $00000000;    // gone V8.01

    SSL_OP_NETSCAPE_CA_DN_BUG                   = $20000000;

    SSL_OP_NETSCAPE_DEMO_CIPHER_CHANGE_BUG      = $40000000;    // gone V8.51

  // Disallow all renegotiation */
    SSL_OP_NO_RENEGOTIATION                     = $40000000;    // new V8.51

    // Make server add server-hello extension from early version of
    // cryptopro draft, when GOST ciphersuite is negotiated.
    // Required for interoperability with CryptoPro CSP 3.x
    SSL_OP_CRYPTOPRO_TLSEXT_BUG                 = $80000000; // 1.0.0x

    //SSL_OP_ALL: various bug workarounds that should be rather harmless.
    SSL_OP_ALL                                  = { $00000BFF; }   // V8.01
       (SSL_OP_CRYPTOPRO_TLSEXT_BUG OR SSL_OP_DONT_INSERT_EMPTY_FRAGMENTS OR
        SSL_OP_LEGACY_SERVER_CONNECT OR SSL_OP_TLSEXT_PADDING OR SSL_OP_SAFARI_ECDHE_ECDSA_BUG);   // V8.51
    //SSL_OP_ALL                                  = $80000FFF; 1.0.0d


// Allow SSL_write(..., n) to return r with 0 < r < n (i.e. report success
// when just a single record has been written):
    SSL_MODE_ENABLE_PARTIAL_WRITE               = $00000001;
// Make it possible to retry SSL_write() with changed buffer location (buffer
// contents must stay the same!); this is not the default to avoid the
// misconception that non-blocking SSL_write() behaves like non-blocking write():
    SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER         = $00000002;  { V8.51 following modes added } 
// Never bother the application with retries if the transport is blocking:
    SSL_MODE_AUTO_RETRY                         = $00000004;
// Don't attempt to automatically build certificate chain
    SSL_MODE_NO_AUTO_CHAIN                      = $00000008;
// Save RAM by releasing read and write buffers when they're empty. (SSL3 and
// TLS only.) Released buffers are freed.
    SSL_MODE_RELEASE_BUFFERS                    = $00000010;
// Send the current time in the Random fields of the ClientHello and
// ServerHello records for compatibility with hypothetical implementations
// that require it.
    SSL_MODE_SEND_CLIENTHELLO_TIME             = $00000020;
    SSL_MODE_SEND_SERVERHELLO_TIME             = $00000040;
// Send TLS_FALLBACK_SCSV in the ClientHello. To be set only by applications
// that reconnect with a downgraded protocol version; see
// draft-ietf-tls-downgrade-scsv-00 for details. DO NOT ENABLE THIS if your
// application attempts a normal handshake. Only use this in explicit
// fallback retries, following the guidance in
// draft-ietf-tls-downgrade-scsv-00.
    SSL_MODE_SEND_FALLBACK_SCSV                = $00000080;
// Support Asynchronous operation
    SSL_MODE_ASYNC                             = $00000100;    { 1.1.0 and later }

    SSL_SESS_CACHE_OFF                          = $0000;
    SSL_SESS_CACHE_CLIENT                       = $0001;
    SSL_SESS_CACHE_SERVER                       = $0002;
    SSL_SESS_CACHE_BOTH                         = (SSL_SESS_CACHE_CLIENT or SSL_SESS_CACHE_SERVER);
    SSL_SESS_CACHE_NO_AUTO_CLEAR                = $0080;
    //* enough comments already ... see SSL_CTX_set_session_cache_mode(3) */
    SSL_SESS_CACHE_NO_INTERNAL_LOOKUP           = $0100;
    SSL_SESS_CACHE_NO_INTERNAL_STORE            = $0200;
    SSL_SESS_CACHE_NO_INTERNAL                  = (SSL_SESS_CACHE_NO_INTERNAL_LOOKUP or SSL_SESS_CACHE_NO_INTERNAL_STORE);

    SSL_SESSION_CACHE_MAX_SIZE_DEFAULT          = (1024 * 20);

 { V8.27 values for handshake SSL_state up to 1.1.0, no longer used except in info callback }
    SSL_ST_CONNECT                              = $1000;
    SSL_ST_ACCEPT                               = $2000;
    SSL_ST_MASK                                 = $0FFF;
    SSL_ST_INIT                                 = (SSL_ST_CONNECT or SSL_ST_ACCEPT);
    SSL_ST_BEFORE                               = $4000;
    SSL_ST_OK                                   = $03;
    SSL_ST_RENEGOTIATE                          = ($04 or SSL_ST_INIT);

    SSL_CB_LOOP                                 = 1;
    SSL_CB_EXIT                                 = 2;
    SSL_CB_READ                                 = 4;
    SSL_CB_WRITE                                = 8;
    SSL_CB_ALERT                                = $4000; // used in callback
    SSL_CB_READ_ALERT                           = (SSL_CB_ALERT or SSL_CB_READ);
    SSL_CB_WRITE_ALERT                          = (SSL_CB_ALERT or SSL_CB_WRITE);
    SSL_CB_ACCEPT_LOOP                          = (SSL_ST_ACCEPT or SSL_CB_LOOP);
    SSL_CB_ACCEPT_EXIT                          = (SSL_ST_ACCEPT or SSL_CB_EXIT);
    SSL_CB_CONNECT_LOOP                         = (SSL_ST_CONNECT or SSL_CB_LOOP);
    SSL_CB_CONNECT_EXIT                         = (SSL_ST_CONNECT or SSL_CB_EXIT);
    SSL_CB_HANDSHAKE_START                      = $10;
    SSL_CB_HANDSHAKE_DONE                       = $20;

    SSL_NOTHING                                 = 1;
    SSL_WRITING                                 = 2;
    SSL_READING                                 = 3;
    SSL_X509_LOOKUP                             = 4;

    // Used in SSL_set_shutdown()/SSL_get_shutdown()
    SSL_SENT_SHUTDOWN                           = 1;
    SSL_RECEIVED_SHUTDOWN                       = 2;

    X509_TRUST_COMPAT                           = 1; //AG
    X509_TRUST_SSL_CLIENT                       = 2; //AG
    X509_TRUST_SSL_SERVER                       = 3; //AG
    X509_TRUST_EMAIL                            = 4; //AG
    X509_TRUST_OBJECT_SIGN                      = 5; //AG
    X509_TRUST_OCSP_SIGN                        = 6; //AG
    X509_TRUST_OCSP_REQUEST                     = 7; //AG

    SSL_MAX_SSL_SESSION_ID_LENGTH               = 32; //AG
    SSL_MAX_SID_CTX_LENGTH                      = 32; //AG

    {* ExtensionType values from RFC 3546 *}
    TLSEXT_TYPE_server_name                     = 0;
    TLSEXT_TYPE_max_fragment_length             = 1;
    TLSEXT_TYPE_client_certificate_url          = 2;
    TLSEXT_TYPE_trusted_ca_keys                 = 3;
    TLSEXT_TYPE_truncated_hmac                  = 4;
    TLSEXT_TYPE_status_request                  = 5;
    TLSEXT_TYPE_elliptic_curves                 = 10;
    TLSEXT_TYPE_ec_point_formats                = 11;
    TLSEXT_TYPE_signature_algorithms            = 13;  { V8.56 }
    TLSEXT_TYPE_use_srtp                        = 14;  { V8.56 }
    TLSEXT_TYPE_heartbeat                       = 15;  { V8.56 }
    TLSEXT_TYPE_application_layer_protocol_negotiation = 16;  { V8.56 }
    TLSEXT_TYPE_signed_certificate_timestamp    = 18;  { V8.56 }
    TLSEXT_TYPE_padding                         = 21;  { V8.56 }
    TLSEXT_TYPE_encrypt_then_mac                = 22;  { V8.56 }
    TLSEXT_TYPE_extended_master_secret          = 23;  { V8.56 }
    TLSEXT_TYPE_session_ticket                  = 35;
    { As defined for TLS1.3 }
    TLSEXT_TYPE_psk                             = 41;  { V8.56 }
    TLSEXT_TYPE_early_data                      = 42;  { V8.56 }
    TLSEXT_TYPE_supported_versions              = 43;  { V8.56 }
    TLSEXT_TYPE_cookie                          = 44;  { V8.56 }
    TLSEXT_TYPE_psk_kex_modes                   = 45;  { V8.56 }
    TLSEXT_TYPE_certificate_authorities         = 47;  { V8.56 }
    TLSEXT_TYPE_post_handshake_auth             = 49;  { V8.56 }
    TLSEXT_TYPE_signature_algorithms_cert       = 50;  { V8.56 }
    TLSEXT_TYPE_key_share                       = 51;  { V8.56 }
 { Temporary extension type }
    TLSEXT_TYPE_renegotiate                     = $ff01;  { V8.56 }
    TLSEXT_TYPE_next_proto_neg                  = 13172;  { V8.64 }

    TLSEXT_MAXLEN_host_name                     = 255;
    TLSEXT_NAMETYPE_host_name                   = 0;


    SSL_TLSEXT_ERR_OK                           = 0;
    SSL_TLSEXT_ERR_ALERT_WARNING                = 1;
    SSL_TLSEXT_ERR_ALERT_FATAL                  = 2;
    SSL_TLSEXT_ERR_NOACK                        = 3;

  { V8.64 return from SSL_client_hello_cb_fn }   
    SSL_CLIENT_HELLO_SUCCESS                    = 1;
    SSL_CLIENT_HELLO_ERROR                      = 0;
    SSL_CLIENT_HELLO_RETRY                      = -1;

// V8.51 Extension context codes
// This extension is only allowed in TLS
    SSL_EXT_TLS_ONLY                        = $0001;
// This extension is only allowed in DTLS
    SSL_EXT_DTLS_ONLY                       = $0002;
// Some extensions may be allowed in DTLS but we don't implement them for it
    SSL_EXT_TLS_IMPLEMENTATION_ONLY         = $0004;
// Most extensions are not defined for SSLv3 but EXT_TYPE_renegotiate is
    SSL_EXT_SSL3_ALLOWED                    = $0008;
///Extension is only defined for TLS1.2 and below
    SSL_EXT_TLS1_2_AND_BELOW_ONLY           = $0010;
// Extension is only defined for TLS1.3 and above
    SSL_EXT_TLS1_3_ONLY                     = $0020;
// Ignore this extension during parsing if we are resuming
    SSL_EXT_IGNORE_ON_RESUMPTION            = $0040;
    SSL_EXT_CLIENT_HELLO                    = $0080;
// Really means TLS1.2 or below */
    SSL_EXT_TLS1_2_SERVER_HELLO             = $0100;
    SSL_EXT_TLS1_3_SERVER_HELLO             = $0200;
    SSL_EXT_TLS1_3_ENCRYPTED_EXTENSIONS     = $0400;
    SSL_EXT_TLS1_3_HELLO_RETRY_REQUEST      = $0800;
    SSL_EXT_TLS1_3_CERTIFICATE              = $1000;
    SSL_EXT_TLS1_3_NEW_SESSION_TICKET       = $2000;
    SSL_EXT_TLS1_3_CERTIFICATE_REQUEST      = $4000;

type
  { V8.57 whether an SSL server asks a client to send an SSL certificate }
    TSslCliCertMethod = (sslCliCertNone,
                         sslCliCertOptional,
                         sslCliCertRequire);

  { V8.57 certificate supplier protocol, determines which functions are used to get certificates }
    TSupplierProto = (SuppProtoNone, SuppProtoOwnCA, SuppProtoAcmeV2,    { V8.62 Acmev1 gone }
                      SuppProtoCertCentre, SuppProtoServtas);

 { V8.57 challenge types, differing certificate types support differing challenges,
     some have to be processed manually taking several days. }
    TChallengeType = (ChallNone, ChallFileUNC, ChallFileFtp, ChallFileSrv,
                      ChallFileApp, ChallDnsAuto, ChallDnsMan, ChallEmail,      { V8.64 DnsMan added }
                      ChallAlpnUNC, ChallAlpnSrv, ChallAlpnApp, ChallManual);   { V8.62 App added }

{ V8.40 OpenSSL streaming ciphers with various modes }
{ pending ciphers, rc5, cast5, if we care }
    TEvpCipher = (
        Cipher_none,
        Cipher_aes_128_cbc,
        Cipher_aes_128_cfb,
        Cipher_aes_128_ecb,
        Cipher_aes_128_ofb,
        Cipher_aes_128_gcm,
        Cipher_aes_128_ocb,
        Cipher_aes_128_ccm,
        Cipher_aes_192_cbc,
        Cipher_aes_192_cfb,
        Cipher_aes_192_ecb,
        Cipher_aes_192_ofb,
        Cipher_aes_192_gcm,
        Cipher_aes_192_ocb,
        Cipher_aes_192_ccm,
        Cipher_aes_256_cbc,
        Cipher_aes_256_cfb,
        Cipher_aes_256_ecb,
        Cipher_aes_256_ofb,
        Cipher_aes_256_gcm,
        Cipher_aes_256_ocb,
        Cipher_aes_256_ccm,
        Cipher_bf_cbc,        { blowfish needs key length set, 128, 192 or 256 }
        Cipher_bf_cfb64,
        Cipher_bf_ecb,
        Cipher_bf_ofb,
        Cipher_chacha20,      { chacha20 fixed 256 key }
        Cipher_des_ede3_cbc,
        Cipher_des_ede3_cfb64,
        Cipher_des_ede3_ecb,
        Cipher_des_ede3_ofb,
        Cipher_idea_cbc,      { IDEA fixed 128 key }
        Cipher_idea_cfb64,
        Cipher_idea_ecb,
        Cipher_idea_ofb);


{ V8.40 OpenSSL message digests or hashes }
    TEvpDigest = (
        Digest_md5,
        Digest_mdc2,
        Digest_sha1,
        Digest_sha224,
        Digest_sha256,
        Digest_sha384,
        Digest_sha512,
        Digest_ripemd160,
        Digest_sha3_224,    { following V8.51 }
        Digest_sha3_256,
        Digest_sha3_384,
        Digest_sha3_512,
        Digest_shake128,
        Digest_shake256,
        Digest_None);       { V8.52 }

{ V8.40 ICS private key algorithm and key length in bits }
{ bracketed comment is security level and effective bits,
  beware long RSA key lengths increase SSL overhead heavily }
{ creating new RSA keys is computationally expensive, 4096 bits
  a couple of seconds, 7680 maybe a minute, 15360 hours }   
    TSslPrivKeyType = (
        PrivKeyRsa1024,   { level 1 - 80 bits  }
        PrivKeyRsa2048,   { level 2 - 112 bits }
        PrivKeyRsa3072,   { level 3 - 128 bits }
        PrivKeyRsa4096,   { level 3 - 128 bits }
        PrivKeyRsa7680,   { level 4 - 192 bits }
        PrivKeyRsa15360,  { level 5 - 256 bits }
        PrivKeyECsecp256, { level 3 - 128 bits }
        PrivKeyECsecp384, { level 4 - 192 bits }
        PrivKeyECsecp512, { level 5 - 256 bits }
        PrivKeyEd25519,   { level 3 - 128 bits }    { V8.50 was PrivKeyECX25519 }
        PrivKeyRsaPss2048,   { level 2 - 112 bits } { V8.51 several RsaPss keys }
        PrivKeyRsaPss3072,   { level 3 - 128 bits }
        PrivKeyRsaPss4096,   { level 3 - 128 bits }
        PrivKeyRsaPss7680,   { level 4 - 192 bits }
        PrivKeyRsaPss15360); { level 5 - 256 bits }

{ V8.40 ICS private key file encryption and mapping to OpenSSL params }
   TSslPrivKeyCipher = (
        PrivKeyEncNone,
        PrivKeyEncTripleDES,
        PrivKeyEncIDEA,
        PrivKeyEncAES128,
        PrivKeyEncAES192,
        PrivKeyEncAES256,
        PrivKeyEncBlowfish128);
      {  PrivKeyEncBlowfish192,   V8.62 now sure we need these
        PrivKeyEncBlowfish256); }

const
    SslPrivKeyEvpCipher: array[TSslPrivKeyCipher] of TEvpCipher = (
        Cipher_none,
        Cipher_des_ede3_cbc,
        Cipher_idea_cbc,
        Cipher_aes_128_cbc,
        Cipher_aes_192_cbc,
        Cipher_aes_256_cbc,
        Cipher_bf_cbc);
     {   Cipher_bf_cbc,
        Cipher_bf_cbc);  }

    SslPrivKeyEvpBits: array[TSslPrivKeyCipher] of integer = (
         0,0,0,0,0,0,128{,192,256});

type
   { V8.57 SSL/TLS certifioate root validation method }
    TCertVerMethod   = (CertVerNone, CertVerBundle, CertVerWinStore);

   { V8.57 Logging debug level }
    THttpDebugLevel  = (DebugNone, DebugConn, DebugParams, DebugSsl, DebugHdr, DebugBody, DebugSslLow);

   { V8.40 options to read pkey and inters from cert PEM and P12 files,
     croTry will silently fail, croYes will fail with exception  }
    TCertReadOpt = (croNo, croTry, croYes);             { V8.39 }

   { V8.41 SSL/TLS certificate validation result, V8.57 added None }
    TChainResult = (chainOK, chainFail, chainWarn, chainNone);

   { V8.40 1.1.0 and later, sets OpenSSL security level to a number }
    TSslSecLevel = (
                     sslSecLevelAny,        { 0 - anything allowed, old compatibility }
                     sslSecLevel80bits,     { 1 - default, RSA/DH keys=>1024, ECC=>160, no MD5 }
                     sslSecLevel112bits,    { 2 - RSA/DH keys=>2048, ECC=>224, no RC4, no SSL3, no SHA1 certs }
                     sslSecLevel128bits,    { 3 - RSA/DH keys=>3072, ECC=>256, FS forced, no TLS/1.0  }
                     sslSecLevel192bits,    { 4 - RSA/DH keys=>7680, ECC=>384, no SHA1 suites, no TLS/1.1  }
                     sslSecLevel256bits);   { 5 - RSA/DH keys=>15360, ECC=>512  }

   { V8.45 SSL server security level, used by TIcsHost, sets protocol, cipher and SslSecLevel }
   { warning, requiring key lengths higher than 2048 requires all SSL certificates in the chain to
     have that minimum key length, including the root }
   { V8.55 sslSrvSecInter/FS, sslCliSecInter now requires TLS1.1, PCI council EOF TLS1.0 30 June 2018 }
   { V8.60 added sslSrvSecTls12Less and sslSrvSecTls13Only to disable TLS1.3 if it fails }
    TSslSrvSecurity = (
                     sslSrvSecNone,         { 0 - all protocols and ciphers, any key lengths }
                     sslSrvSecSsl3,         { 1 - SSL3 only, all ciphers, any key lengths, MD5 }
                     sslSrvSecBack,         { 2 - TLS1 or later, backward ciphers, RSA/DH keys=>1024, ECC=>160, no MD5, SHA1 }
                     sslSrvSecInter,        { 3 - TLS1.1 or later, intermediate ciphers, RSA/DH keys=>2048, ECC=>224, no RC4, no SHA1 certs }
                     sslSrvSecInterFS,      { 4 - TLS1.1 or later, intermediate FS ciphers, RSA/DH keys=>2048, ECC=>224, no RC4, no SHA1 certs }
                     sslSrvSecHigh,         { 5 - TLS1.2 or later, high ciphers, RSA/DH keys=>2048, ECC=>224, no RC4, no SHA1 certs }
                     sslSrvSecHigh128,      { 6 - TLS1.2 or later, high ciphers, RSA/DH keys=>3072, ECC=>256, FS forced }
                     sslSrvSecHigh192,      { 7 - TLS1.2 or later, high ciphers, RSA/DH keys=>7680, ECC=>384, FS forced }
                     sslSrvSecTls12Less,    { 8 - TLSv1.2 or earlier, intermediate FS ciphers, RSA/DH keys=>2048, ECC=>224, no RC4, no SHA1 certs }
                     sslSrvSecTls13Only);   { 9 - TLSv1.3 only, intermediate FS ciphers, RSA/DH keys=>2048, ECC=>224, no RC4, no SHA1 certs }

const
    sslSrvSecDefault = sslSrvSecHigh;       { V8.55 recommended default, V8.64 improved default since TLSv1.1 disabled in most browsers from early 2020 }

type
   { V8.54 SSL client security level, used by context, sets protocol, cipher and SslSecLevel }
    TSslCliSecurity = (
                     sslCliSecIgnore,       { 0 - ignore, use old settings }
                     sslCliSecNone,         { 1 - all protocols and ciphers, any key lengths }
                     sslCliSecSsl3Only,     { 2 - SSLv3 only, all ciphers, any key lengths, MD5 }
                     sslCliSecTls1Only,     { 3 - TLSv1 only, all ciphers, RSA/DH keys=>2048 }
                     sslCliSecTls11Only,    { 4 - TLSv1.1 only, all ciphers, RSA/DH keys=>2048 }
                     sslCliSecTls12Only,    { 5 - TLSv1.2 only, all ciphers, RSA/DH keys=>2048 }
                     sslCliSecTls13Only,    { 6 - TLSv1.3 only, all ciphers, RSA/DH keys=>2048 }
                     sslCliSecTls1,         { 7 - TLSv1 or later, all ciphers, RSA/DH keys=>1024 }
                     sslCliSecTls11,        { 8 - TLSv1.1 or later, all ciphers, RSA/DH keys=>1024 }
                     sslCliSecTls12,        { 0 - TLSv1.2 or later, all ciphers, RSA/DH keys=>2048 }
                     sslCliSecBack,         { 10 - TLSv1 or later, backward ciphers, RSA/DH keys=>1024, ECC=>160, no MD5, SHA1 }
                     sslCliSecInter,        { 11 - TLSv1.1 or later, intermediate ciphers, RSA/DH keys=>2048, ECC=>224, no RC4, no SHA1 certs }
                     sslCliSecHigh,         { 12 - TLSv1.2 or later, high ciphers, RSA/DH keys=>2048, ECC=>224, no RC4, no SHA1 certs }
                     sslCliSecHigh128,      { 13 - TLSv1.2 or later, high ciphers, RSA/DH keys=>3072, ECC=>256, FS forced }
                     sslCliSecHigh192);     { 14 - TLSv1.2 or later, high ciphers, RSA/DH keys=>7680, ECC=>384, FS forced }

const
    sslCliSecDefault = sslCliSecTls11;  { V8.55 recommended default }



const
    f_BIO_f_ssl :                              function : PBIO_METHOD; cdecl = nil;
    f_SSL_CIPHER_description :                 function(Cipher: Pointer; buf: PAnsiChar; size: Integer): PAnsiChar; cdecl = nil;
    f_SSL_CIPHER_get_bits :                    function(Cipher, Alg_Bits: Pointer): Integer; cdecl = nil;
    f_SSL_CIPHER_get_name :                    function(Cipher: Pointer): PAnsiChar; cdecl = nil;
    f_SSL_CTX_add_client_CA :                  function(C: PSSL_CTX; CaCert: PX509): Integer; cdecl = nil; //AG
    f_SSL_CTX_callback_ctrl:                   function(ctx: PSSL_CTX; cb_id: Integer; fp: TCallback_ctrl_fp): Longint; cdecl = nil;
    f_SSL_CTX_check_private_key :              function(Ctx: PSSL_CTX): integer; cdecl = nil;     { V8.40 }
    f_SSL_CTX_ctrl :                           function(C: PSSL_CTX; Cmd: Integer; LArg: LongInt; PArg: PAnsiChar): LongInt; cdecl = nil;
    f_SSL_CTX_free :                           procedure(C: PSSL_CTX); cdecl = nil;
    f_SSL_CTX_get0_certificate :               function(Ctx: PSSL_CTX): PX509; cdecl = nil;       { V8.40 }
    f_SSL_CTX_get0_param :                     function(Ctx: PSSL_CTX): PX509_VERIFY_PARAM; cdecl = nil;                { V8.39 1.0.2 }
    f_SSL_CTX_get0_privatekey :                function(Ctx: PSSL_CTX): PEVP_PKEY; cdecl = nil;   { V8.40 }
    f_SSL_CTX_get0_security_ex_data :          function(Ctx: PSSL_CTX): Pointer; cdecl = nil;            { V8.40 }
    f_SSL_CTX_get_cert_store :                 function(const Ctx: PSSL_CTX): PX509_STORE; cdecl = nil; //AG
    f_SSL_CTX_get_client_cert_cb:              function(CTX: PSSL_CTX): TClient_cert_cb; cdecl = nil; //AG
    f_SSL_CTX_get_ex_data :                    function(const C: PSSL_CTX; Idx: Integer): PAnsiChar; cdecl = nil;
    f_SSL_CTX_get_security_level :             function(Ctx: PSSL_CTX): Integer; cdecl = nil;             { V8.40 }
    f_SSL_CTX_get_verify_depth :               function(const ctx: PSSL_CTX): Integer; cdecl = nil; //AG
    f_SSL_CTX_get_verify_mode :                function(const C: PSSL_CTX): Integer; cdecl = nil; //AG
    f_SSL_CTX_load_verify_locations :          function(C: PSSL_CTX; const FileName: PAnsiChar; const SearchPath: PAnsiChar): Integer; cdecl = nil;
    f_SSL_CTX_new :                            function(Meth: PSSL_METHOD): PSSL_CTX; cdecl = nil;
    f_SSL_CTX_sess_get_get_cb:                 function(CTX: PSSL_CTX): TGet_session_cb; cdecl = nil; //AG
    f_SSL_CTX_sess_get_new_cb:                 function (CTX: PSSL_CTX): TNew_session_cb; cdecl = nil; //AG
    f_SSL_CTX_sess_get_remove_cb:              function(CTX: PSSL_CTX): TRemove_session_cb; cdecl = nil; //AG
    f_SSL_CTX_sess_set_get_cb:                 procedure(Ctx: PSSL_CTX; CB: TGet_session_cb); cdecl = nil; //AG
    f_SSL_CTX_sess_set_new_cb:                 procedure(Ctx: PSSL_CTX; CB: TNew_session_cb); cdecl = nil; //AG
    f_SSL_CTX_sess_set_remove_cb:              procedure(Ctx: PSSL_CTX; CB: TRemove_session_cb); cdecl = nil; //AG
    f_SSL_CTX_set0_security_ex_data :          procedure(Ctx: PSSL_CTX;  ex: Pointer);  cdecl = nil;      { V8.40 }
    f_SSL_CTX_set1_param :                     function(Ctx: PSSL_CTX; vpm: PX509_VERIFY_PARAM): integer; cdecl = nil;  { V8.39 1.0.2 }
    f_SSL_CTX_set_alpn_protos :                function(Ctx: PSSL_CTX; protos: Pointer; protos_len: integer): integer; cdecl = nil;  { V8.56 }
    f_SSL_CTX_set_alpn_select_cb :             procedure(Ctx: PSSL_CTX; cb: TSsl_alpn_cb; arg: Pointer); cdecl = nil;  { V8.56 }
    f_SSL_CTX_set_cipher_list :                function(C: PSSL_CTX; CipherString: PAnsiChar): Integer; cdecl = nil;
    f_SSL_CTX_set_client_CA_list :             procedure(C: PSSL_CTX; List: PSTACK_OF_X509_NAME); cdecl = nil; //AG
    f_SSL_CTX_set_client_cert_cb:              procedure(CTX: PSSL_CTX; CB: TClient_cert_cb); cdecl = nil; //AG
    f_SSL_CTX_set_client_hello_cb :            procedure(C: PSSL_CTX; cb: TSsl_client_hello_cb; arg: Pointer); cdecl = nil;  { V8.64 }
    f_SSL_CTX_set_default_passwd_cb :          procedure(C: PSSL_CTX; CallBack: TPem_password_cb); cdecl = nil;
    f_SSL_CTX_set_default_passwd_cb_userdata : procedure(C: PSSL_CTX; UData: Pointer); cdecl = nil;
    f_SSL_CTX_set_default_verify_paths :       function(C: PSSL_CTX): Integer; cdecl = nil;
    f_SSL_CTX_set_ex_data :                    function(C: PSSL_CTX; Idx: Integer; Arg: PAnsiChar): Integer; cdecl = nil;
    f_SSL_CTX_set_info_callback:               procedure(ctx: PSSL_CTX; cb : TSetInfo_cb); cdecl = nil;
    f_SSL_CTX_set_msg_callback :               procedure(Ctx: PSSL_CTX; cb: TProto_msg_cb); cdecl = nil;  { V8.40 }
    f_SSL_CTX_set_security_callback :          procedure(Ctx: PSSL_CTX; cb: TSecurity_level_cb); cdecl = nil;   { V8.40 }
    f_SSL_CTX_set_security_level :             procedure(Ctx: PSSL_CTX; level: Integer); cdecl = nil;     { V8.40 }
    f_SSL_CTX_set_session_id_context :         function(Ctx: PSSL_CTX; const Sid_ctx: PAnsiChar; sid_ctx_len: Integer): Integer; cdecl = nil;
    f_SSL_CTX_set_timeout :                    function(Ctx: PSSL_CTX; Timeout: Longword): Longword; cdecl = nil;
    f_SSL_CTX_set_trust :                      function(C: PSSL_CTX; Trust: Integer): Integer; cdecl = nil; //AG
    f_SSL_CTX_set_verify :                     procedure(C: PSSL_CTX; Mode: Integer; CallBack : TSetVerify_cb); cdecl = nil;
    f_SSL_CTX_set_verify_depth :               procedure(C: PSSL_CTX; Depth: Integer); cdecl = nil;
    f_SSL_CTX_use_PrivateKey :                 function(C: PSSL_CTX; pkey: PEVP_PKEY): Integer; cdecl = nil;
    f_SSL_CTX_use_PrivateKey_file :            function(C: PSSL_CTX; const FileName: PAnsiChar; CertType: Integer): Integer; cdecl = nil;
    f_SSL_CTX_use_certificate :                function(C: PSSL_CTX; Cert: PX509): Integer; cdecl = nil;     { V8.27 }
    f_SSL_CTX_use_certificate_chain_file :     function(C: PSSL_CTX; const FileName: PAnsiChar): Integer; cdecl = nil;
    f_SSL_CTX_use_certificate_file :           function(C: PSSL_CTX; const FileName: PAnsiChar; type_: Integer): Integer; cdecl = nil; //AG
    f_SSL_SESSION_get_id:                      function (const Ses: PSSL_SESSION; var Len: LongInt): PAnsiChar; cdecl = nil; //AG
    f_SSL_SESSION_get_time :                   function(const Sess: PSSL_SESSION): Longword; cdecl = nil;
    f_SSL_SESSION_get_timeout :                function(const Sess: PSSL_SESSION): Longword; cdecl = nil;
    f_SSL_SESSION_set_time :                   function(Sess: PSSL_SESSION; T: Longword): Longword; cdecl = nil;
    f_SSL_SESSION_set_timeout :                function(Sess: PSSL_SESSION; T: Longword): Longword; cdecl = nil;
    f_SSL_accept :                             function(S: PSSL): Integer; cdecl = nil;
    f_SSL_add_client_CA :                      function(ssl: PSSL; CaCert: PX509): Integer; cdecl = nil; //AG
    f_SSL_alert_desc_string_long :             function(value: Integer): PAnsiChar; cdecl = nil;
    f_SSL_alert_type_string_long :             function(value: Integer): PAnsiChar; cdecl = nil;
    f_SSL_bytes_to_cipher_list :               function(s: PSSL; cbytes: PAnsiChar; len: size_t; isv2format: Boolean; var sk: PSTACK_OF_SSL_CIPHER; var scvsvs: PSTACK_OF_SSL_CIPHER): LongInt; cdecl = nil;   { V8.64 }
    f_SSL_callback_ctrl:                       function(s: PSSL; cb_id: Integer; fp: TCallback_ctrl_fp): Longint; cdecl = nil;
    f_SSL_clear :                              function(S: PSSL): Integer; cdecl = nil;    { V8.64 was procedure }
    f_SSL_client_hello_isv2 :                  function(s: PSSL): Longint; cdecl = nil;    { V8.64 }
    f_SSL_client_hello_get0_legacy_version :   function(s: PSSL): Longword; cdecl = nil;   { V8.64 }
    f_SSL_client_hello_get0_random :           function(s: PSSL; var OutData: PAnsiChar): size_t; cdecl = nil;       { V8.64 }
    f_SSL_client_hello_get0_session_id :       function(s: PSSL; var OutData: PAnsiChar): size_t; cdecl = nil;       { V8.64 }
    f_SSL_client_hello_get0_ciphers :          function(s: PSSL; var OutData: PAnsiChar): size_t; cdecl = nil;       { V8.64 }
    f_SSL_client_hello_get0_compression_methods : function(s: PSSL; var OutData: PAnsiChar): size_t; cdecl = nil;    { V8.64 }
    f_SSL_client_hello_get1_extensions_present :  function(s: PSSL; var OutData: PAnsiChar; var OutLen: size_t): Longint; cdecl = nil;        { V8.64 }
    f_SSL_client_hello_get0_ext :              function(s: PSSL; EType: LongWord; var OutData: PAnsiChar; var OutLen: size_t): Longint; cdecl = nil; { V8.64 }
    f_SSL_connect :                            function(S: PSSL): Integer; cdecl = nil;
    f_SSL_ctrl :                               function(S: PSSL; Cmd: Integer; LArg: LongInt; PArg: Pointer): LongInt; cdecl = nil;
    f_SSL_do_handshake :                       function(S: PSSL): Integer; cdecl = nil; //AG
    f_SSL_free :                               procedure(S: PSSL); cdecl = nil;
    f_SSL_get0_alpn_selected :                 procedure(S: PSSL; var data: Pointer; var len: Integer); cdecl = nil;  { V8.56 }
    f_SSL_get0_param :                         function(S: PSSL): PX509_VERIFY_PARAM; cdecl = nil;                      { V8.39 1.0.2 }
    f_SSL_get0_security_ex_data :              function(S: PSSL): Pointer; cdecl = nil;                  { V8.40 }
    f_SSL_get1_session :                       function(S: PSSL): PSSL_SESSION; cdecl = nil;
    f_SSL_get1_supported_ciphers :             function(S: PSSL): PSTACK_OF_SSL_CIPHER; cdecl = nil;   { V8.27 }
    f_SSL_get_SSL_CTX:                         function(const S: PSSL): PSSL_CTX; cdecl = nil;
    f_SSL_get_cipher_list :                    function(S: PSSL; Priority: Integer): PAnsiChar; cdecl = nil;  { V8.27 }
    f_SSL_get_ciphers :                        function(S: PSSL): PSTACK_OF_SSL_CIPHER; cdecl = nil;   { V8.27 }
    f_SSL_get_client_CA_list :                 function(const S: PSSL): PSTACK_OF_X509_NAME; cdecl = nil;
    f_SSL_get_client_ciphers :                 function(S: PSSL): PSTACK_OF_SSL_CIPHER; cdecl = nil;   { V8.27 }
    f_SSL_get_current_cipher :                 function(S: PSSL): Pointer; cdecl = nil;
    f_SSL_get_error :                          function(S: PSSL; ErrCode: Integer): Integer; cdecl = nil;
    f_SSL_get_ex_data :                        function(S: PSSL; Idx: Integer): Pointer; cdecl = nil;
    f_SSL_get_ex_data_X509_STORE_CTX_idx:      function: Integer; cdecl = nil;
    f_SSL_get_fd:                              function(S: PSSL): Integer; cdecl = nil; // B.S.
    f_SSL_get_peer_cert_chain :                function(const S: PSSL): PSTACK_OF_X509; cdecl = nil;
    f_SSL_get_peer_certificate :               function(S: PSSL): PX509; cdecl = nil;
    f_SSL_get_rbio :                           function(S: PSSL): PBIO; cdecl = nil;
    f_SSL_get_rfd:                             function(S: PSSL): Integer; cdecl = nil; // B.S.
    f_SSL_get_servername:                      function(const S: PSSL; const type_: Integer): PAnsiChar; cdecl = nil;
    f_SSL_get_servername_type:                 function(const S: PSSL): Integer; cdecl = nil;
    f_SSL_get_session :                        function(S: PSSL): PSSL_SESSION; cdecl = nil;
    f_SSL_get_shutdown :                       function(S: PSSL): Integer; cdecl = nil;
    f_SSL_get_security_level :                 function(S: PSSL): Integer; cdecl = nil;                   { V8.40 }
    f_SSL_get_state :                          function(S: PSSL): TSslHandshakeState; cdecl = nil;   { V8.27 }
    f_SSL_get_verify_depth :                   function(const S: PSSL): Integer; cdecl = nil;
    f_SSL_get_verify_result :                  function(S: PSSL): LongInt; cdecl = nil;
    f_SSL_get_version :                        function(S: PSSL): PAnsiChar; cdecl = nil;
    f_SSL_get_wbio :                           function(S: PSSL): PBIO; cdecl = nil;
    f_SSL_get_wfd:                             function(S: PSSL): Integer; cdecl = nil; // B.S.
    f_SSL_library_init :                       function: Integer; cdecl = nil;
    f_SSL_load_client_CA_file :                function(const FileName: PAnsiChar): PSTACK_OF_X509_NAME; cdecl = nil; //AG
    f_SSL_load_error_strings :                 procedure; cdecl = nil;
    f_SSL_new :                                function(Ctx: PSSL_CTX): PSSL; cdecl = nil;
    f_SSL_read :                               function(S: PSSL; Buf: Pointer; Num: Integer): Integer; cdecl = nil;
    f_SSL_renegotiate :                        function(S: PSSL): Integer; cdecl = nil; //AG
    f_SSL_renegotiate_pending :                function(S: PSSL): Integer; cdecl = nil; //AG
    f_SSL_select_next_proto :                  function (var output: Pointer; var outlen: Integer; input: Pointer; inlen: Integer; client: Pointer; client_len: Integer): Integer; cdecl = nil; { V8.56 }
    f_SSL_session_free :                       procedure(Session: PSSL_SESSION); cdecl = nil;
    f_SSL_set0_security_ex_data :              procedure(S: PSSL;  ex: Pointer);  cdecl = nil;            { V8.40 }
    f_SSL_set1_param :                         function(S: PSSL; vpm: PX509_VERIFY_PARAM): integer; cdecl = nil;        { V8.39 1.0.2 }
    f_SSL_set_SSL_CTX:                         function(S: PSSL; ctx: PSSL_CTX): PSSL_CTX; cdecl = nil;
    f_SSL_set_accept_state :                   procedure(S: PSSL); cdecl = nil; //AG
    f_SSL_set_alpn_protos :                    function(S: PSSL; protos: TBytes; protos_len: integer): integer; cdecl = nil;  { V8.56 }
    f_SSL_set_bio :                            procedure(S: PSSL; RBio: PBIO; WBio: PBIO); cdecl = nil;
    f_SSL_set_client_CA_list :                 procedure(s: PSSL; List: PSTACK_OF_X509_NAME); cdecl = nil; //AG
    f_SSL_set_connect_state :                  procedure(S: PSSL); cdecl = nil;
    f_SSL_set_ex_data :                        function(S: PSSL; Idx: Integer; Arg: Pointer): Integer; cdecl = nil;
    f_SSL_set_fd:                              function(S: PSSL; fd: Integer): Integer; cdecl = nil; // B.S.
    f_SSL_set_info_callback :                  procedure(S: PSSL; cb : TSetInfo_cb); cdecl = nil;
    f_SSL_set_msg_callback :                   procedure(S: PSSL; cb: TProto_msg_cb); cdecl = nil;        { V8.40 }
    f_SSL_set_rfd:                             function(S: PSSL; fd: Integer): Integer; cdecl = nil; // B.S.
    f_SSL_set_security_level :                 procedure(S: PSSL; level: Integer); cdecl = nil;           { V8.40 }
    f_SSL_set_security_callback :              procedure(S: PSSL; cb: TSecurity_level_cb); cdecl = nil;   { V8.40 }
    f_SSL_set_session :                        function(S: PSSL; Session: PSSL_SESSION): Integer; cdecl = nil;
    f_SSL_set_session_id_context :             function(S: PSSL; const Sid_ctx: PAnsiChar; sid_ctx_len: Integer): Integer; cdecl = nil;
    f_SSL_set_shutdown :                       procedure(S: PSSL; Mode: Integer); cdecl = nil;
    f_SSL_set_verify :                         procedure(S: PSSL; Mode: Integer; CallBack : TSetVerify_cb); cdecl = nil;
    f_SSL_set_verify_result :                  procedure(S: PSSL; VResult: LongInt); cdecl = nil;
    f_SSL_set_wfd:                             function(S: PSSL; fd: Integer): Integer; cdecl = nil; // B.S.
    f_SSL_shutdown :                           function(S: PSSL): Integer; cdecl = nil;
    f_SSL_state :                              function(S: PSSL): Integer; cdecl = nil;   { V8.27 gone 1.1.0 }
    f_SSL_state_string :                       function(S: PSSL): PAnsiChar; cdecl = nil;    { V8.40 }
    f_SSL_state_string_long :                  function(S: PSSL): PAnsiChar; cdecl = nil;
    f_SSL_version :                            function(const S: PSSL): Integer; cdecl = nil; //AG
    f_SSL_want :                               function(S: PSSL): Integer; cdecl = nil;
    f_SSL_write :                              function(S: PSSL; const Buf: Pointer; Num: Integer): Integer; cdecl = nil;
    f_SSLv23_client_method :                   function: PSSL_METHOD; cdecl = nil;
    f_SSLv23_method :                          function: PSSL_METHOD; cdecl = nil;
    f_SSLv23_server_method :                   function: PSSL_METHOD; cdecl = nil;
    f_SSLv3_client_method :                    function: PSSL_METHOD; cdecl = nil;
    f_SSLv3_method :                           function: PSSL_METHOD; cdecl = nil;
    f_SSLv3_server_method :                    function: PSSL_METHOD; cdecl = nil;
    f_TLS_client_method :                      function: PSSL_METHOD; cdecl = nil;   { V8.27 }
    f_TLS_method :                             function: PSSL_METHOD; cdecl = nil;   { V8.27 }
    f_TLS_server_method :                      function: PSSL_METHOD; cdecl = nil;   { V8.27 }
    f_TLSv1_1_client_method :                  function: PSSL_METHOD; cdecl = nil;
    f_TLSv1_1_method :                         function: PSSL_METHOD; cdecl = nil;    // V8.01 added TLS 1.1 and 1.2
    f_TLSv1_1_server_method :                  function: PSSL_METHOD; cdecl = nil;
    f_TLSv1_2_client_method :                  function: PSSL_METHOD; cdecl = nil;
    f_TLSv1_2_method :                         function: PSSL_METHOD; cdecl = nil;
    f_TLSv1_2_server_method :                  function: PSSL_METHOD; cdecl = nil;
    f_TLSv1_client_method :                    function: PSSL_METHOD; cdecl = nil;
    f_TLSv1_method :                           function: PSSL_METHOD; cdecl = nil;
    f_TLSv1_server_method :                    function: PSSL_METHOD; cdecl = nil;
    f_d2i_SSL_SESSION :                        function(Session: PPSSL_SESSION; const pp: PPAnsiChar; Length: Longword): PSSL_SESSION; cdecl = nil;
    f_i2d_SSL_SESSION :                        function(InSession: PSSL_SESSION; pp: PPAnsiChar): Integer; cdecl = nil;

    f_SSL_CTX_set_options :                    function(C: PSSL_CTX; Op: LongInt): LongInt; cdecl = nil;  // V8.51 x_options exported as of 1.1.0
    f_SSL_CTX_get_options :                    function(C: PSSL_CTX): LongInt; cdecl = nil;               // V8.51 x_options exported as of 1.1.0
    f_SSL_CTX_clear_options :                  function(C: PSSL_CTX; Op: LongInt): LongInt;  cdecl = nil; // V8.51 x_options exported as of 1.1.0
    f_SSL_get_options :                        function(S: PSSL): LongInt; cdecl = nil;                   // V8.51 x_options exported as of 1.1.0
    f_SSL_set_options :                        function(S: PSSL; Op: LongInt): LongInt; cdecl = nil;      // V8.51 x_options exported as of 1.1.0
    f_SSL_clear_options :                      function(S: PSSL; Op: LongInt): LongInt;  cdecl = nil;     // V8.51 x_options exported as of 1.1.0
    f_SSL_session_reused :                     function(SSL: PSSL): Integer; cdecl = nil;                 // V8.51 exported as of 1.1.0

    f_BIO_new_ssl :                            function(Ctx: PSSL_CTX; Client: Boolean): PBIO; cdecl = nil;  // V8.51  not new, but not used before
    f_BIO_new_ssl_connect :                    function(Ctx: PSSL_CTX): PBIO; cdecl = nil;                   // V8.51
    f_BIO_new_buffer_ssl_connect :             function(Ctx: PSSL_CTX): PBIO; cdecl = nil;                   // V8.51
    f_BIO_ssl_copy_session_id :                function(BioTo: PBIO; BioFrom: PBIO): Integer ; cdecl = nil;  // V8.51
    f_BIO_ssl_shutdown :                       procedure(Bio: PBIO); cdecl = nil;                            // V8.51

{$IFNDEF OPENSSL_NO_ENGINE}
    f_SSL_CTX_set_client_cert_engine :         function(Ctx: PSSL_CTX; e: PENGINE): Integer; cdecl = nil; //AG
{$ENDIF}


function SsleayLoad : Boolean;
function SslGetImports (Handle: THandle; List: array of TOSSLImports): string ;  { V8.35 }

{ V8.38 Windows API to check authenticode code signing digital certificate on OpenSSL files }
{$IFDEF MSWINDOWS} { V8.49 }
procedure IcsVerifySslDll (const Fname: string);
{$ENDIF}

// macro functions not exported from DLL
function  f_Ics_SSL_CTX_set_options(C: PSSL_CTX; Op: LongInt): LongInt; {$IFDEF USE_INLINE} inline; {$ENDIF}    // V8.51 x_options exported as of 1.1.0
function  f_Ics_SSL_CTX_get_options(C: PSSL_CTX): LongInt; {$IFDEF USE_INLINE} inline; {$ENDIF}
function  f_Ics_SSL_CTX_clear_options(C: PSSL_CTX; Op: LongInt): LongInt; {$IFDEF USE_INLINE} inline; {$ENDIF}   // V8.51 new
function  f_Ics_SSL_get_options(S: PSSL): LongInt; {$IFDEF USE_INLINE} inline; {$ENDIF}
function  f_Ics_SSL_set_options(S: PSSL; Op: LongInt): LongInt; {$IFDEF USE_INLINE} inline; {$ENDIF}
function  f_Ics_SSL_clear_options(S: PSSL; Op: LongInt): LongInt; {$IFDEF USE_INLINE} inline; {$ENDIF}
function  f_SSL_want_read(S: PSSL) : Boolean; {$IFDEF USE_INLINE} inline; {$ENDIF}
function  f_SSL_want_write(S: PSSL) : Boolean; {$IFDEF USE_INLINE} inline; {$ENDIF}
function  f_SSL_want_nothing(S: PSSL) : Boolean; {$IFDEF USE_INLINE} inline; {$ENDIF}
function  f_SSL_want_x509_lookup(S: PSSL) : Boolean; {$IFDEF USE_INLINE} inline; {$ENDIF}
function  f_Ics_SSL_session_reused(SSL: PSSL): Integer; {$IFDEF USE_INLINE} inline; {$ENDIF}                 // V8.51 exported as of 1.1.0
function  f_SSL_CTX_set_session_cache_mode(Ctx: PSSL_CTX; Mode: Integer): Integer; {$IFDEF USE_INLINE} inline; {$ENDIF}
function  f_SSL_CTX_sess_set_cache_size(Ctx: PSSL_CTX; CacheSize: Integer): Integer; {$IFDEF USE_INLINE} inline; {$ENDIF}
function  f_SSL_CTX_add_extra_chain_cert(Ctx: PSSL_CTX; Cert: PX509): Longword; {$IFDEF USE_INLINE} inline; {$ENDIF}
function  f_SSL_CTX_set_tmp_dh(C: PSSL_CTX; DH: Pointer) : Integer; {$IFDEF USE_INLINE} inline; {$ENDIF}    { V8.01 }
function  f_SSL_CTX_set_tmp_ecdh(C: PSSL_CTX; ECDH: Pointer) : Integer; {$IFDEF USE_INLINE} inline; {$ENDIF}    { V8.01 }
function  f_SSL_CTX_set_ecdh_auto(C: PSSL_CTX; onoff: integer) : Integer;    { V8.01 }
function  f_SSL_set_tmp_dh(S: PSSL; DH: Pointer) : Integer; {$IFDEF USE_INLINE} inline; {$ENDIF}            { V8.01 }
function  f_SSL_set_tmp_ecdh(S: PSSL; ECDH: Pointer) : Integer; {$IFDEF USE_INLINE} inline; {$ENDIF}    { V8.01 }
function  f_SSL_set_ecdh_auto(S: PSSL; onoff: integer) : Integer; {$IFDEF USE_INLINE} inline; {$ENDIF}    { V8.01 }
function  f_SSL_CTX_set_min_proto_version(C: PSSL_CTX; version: integer) : Integer; {$IFDEF USE_INLINE} inline; {$ENDIF}    { V8.27 }
function  f_SSL_CTX_set_max_proto_version(C: PSSL_CTX;  version: integer) : Integer; {$IFDEF USE_INLINE} inline; {$ENDIF}    { V8.27 }
function  f_SSL_set_min_proto_version(S: PSSL; version: integer) : Integer; {$IFDEF USE_INLINE} inline; {$ENDIF}    { V8.27 }
function  f_SSL_set_max_proto_version(S: PSSL; version: integer) : Integer; {$IFDEF USE_INLINE} inline; {$ENDIF}    { V8.27 }
function  f_SSL_CTX_get_min_proto_version(C: PSSL_CTX) : Integer; {$IFDEF USE_INLINE} inline; {$ENDIF}              { V8.51 added 1.1.1  }
function  f_SSL_CTX_get_max_proto_version(C: PSSL_CTX) : Integer; {$IFDEF USE_INLINE} inline; {$ENDIF}              { V8.51 added 1.1.1  }
function  f_SSL_get_min_proto_version(S: PSSL) : Integer; {$IFDEF USE_INLINE} inline; {$ENDIF}                      { V8.51 added 1.1.1  }
function  f_SSL_get_max_proto_version(S: PSSL) : Integer; {$IFDEF USE_INLINE} inline; {$ENDIF}                      { V8.51 added 1.1.1  }
function  f_SSL_CTX_set0_chain(C: PSSL_CTX; sk: PSTACK_OF_X509): Integer;  {$IFDEF USE_INLINE} inline; {$ENDIF}    { V8.27 }
function  f_SSL_CTX_add0_chain_cert(C: PSSL_CTX; Cert: PX509): Integer;  {$IFDEF USE_INLINE} inline; {$ENDIF}    { V8.27 }
function  f_SSL_CTX_get0_chain_certs(C: PSSL_CTX; sk: PPSTACK_OF_X509): Integer;  {$IFDEF USE_INLINE} inline; {$ENDIF}    { V8.27 }
function  f_SSL_CTX_clear_chain_certs(C: PSSL_CTX): Integer;   {$IFDEF USE_INLINE} inline; {$ENDIF}    { V8.27 }
function  f_SSL_CTX_build_cert_chain(C: PSSL_CTX; flags: integer): Integer;   {$IFDEF USE_INLINE} inline; {$ENDIF}    { V8.27 }

function f_SSL_set_tlsext_host_name(const S: PSSL; const name: String): LongInt; {$IFDEF USE_INLINE} inline; {$ENDIF}
function f_SSL_CTX_set_tlsext_servername_callback(ctx: PSSL_CTX; cb: TCallback_ctrl_fp): LongInt; {$IFDEF USE_INLINE} inline; {$ENDIF}
function f_SSL_CTX_set_tlsext_servername_arg(ctx: PSSL_CTX; arg: Pointer): LongInt; {$IFDEF USE_INLINE} inline; {$ENDIF}
function f_SSL_set_tlsext_debug_callback(S: PSSL; cb: TCallback_ctrl_fp): Longint; {$IFDEF USE_INLINE} inline; {$ENDIF}
function f_SSL_set_tlsext_debug_arg(S: PSSL; arg: Pointer): Longint; {$IFDEF USE_INLINE} inline; {$ENDIF}

function f_SSL_get1_groups(Ctx: PSSL_CTX; GList: Pointer): Integer; {$IFDEF USE_INLINE} inline; {$ENDIF} { V8.51 OpenSSL 1.1.1 }
function f_SSL_get_shared_group(Ssl: PSSL; N: Integer): Integer; {$IFDEF USE_INLINE} inline; {$ENDIF} { V8.51 OpenSSL 1.1.1 }
function f_SSL_CTX_set1_groups(Ctx: PSSL_CTX; GList: Pointer; GListlen: Integer): Integer; {$IFDEF USE_INLINE} inline; {$ENDIF} { V8.51 OpenSSL 1.1.1 }
function f_SSL_CTX_set1_groups_list(Ctx: PSSL_CTX; GList: Pointer): Integer; {$IFDEF USE_INLINE} inline; {$ENDIF} { V8.51 OpenSSL 1.1.1 }
function f_SSL_set1_groups(Ctx: PSSL_CTX; GList: Pointer; GListlen: Integer): Integer; {$IFDEF USE_INLINE} inline; {$ENDIF} { V8.51 OpenSSL 1.1.1 }
function f_SSL_set1_groups_list(Ctx: PSSL_CTX; GList: Pointer): Integer; {$IFDEF USE_INLINE} inline; {$ENDIF} { V8.51 OpenSSL 1.1.1 }

function  f_SSL_CTX_set_mode(C: PSSL_CTX; version: integer) : Integer;     { V8.51 }
function  f_SSL_CTX_get_mode(C: PSSL_CTX) : Integer;                       { V8.51 }
function  f_SSL_CTX_clear_mode(C: PSSL_CTX;  version: integer) : Integer;  { V8.51 }
function  f_SSL_set_mode(S: PSSL; version: integer) : Integer;             { V8.51 }
function  f_SSL_get_mode(S: PSSL) : Integer;                               { V8.51 }
function  f_SSL_clear_mode(S: PSSL; version: integer) : Integer;           { V8.51 }

function IcsSslGetState(S: PSSL): TSslHandshakeState;    { V8.27 }
function IcsSslStub: integer;                            { V8.35 }

procedure  f_SSL_CTX_set_msg_callback_arg(Ctx: PSSL_CTX; arg: Pointer);  {$IFDEF USE_INLINE} inline; {$ENDIF}  { V8.40 }
procedure  f_SSL_set_msg_callback_arg(S: PSSL; arg: Pointer); {$IFDEF USE_INLINE} inline; {$ENDIF}             { V8.40 }


// V8.35 all OpenSSL exports now in tables, with versions if only available conditionally
const
    GSSLEAYImports1: array[0..175] of TOSSLImports = (
    (F: @@f_BIO_f_ssl;                              N: 'BIO_f_ssl';                                 MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_BIO_new_buffer_ssl_connect;             N: 'BIO_new_buffer_ssl_connect';                MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),    { V8.51 }
    (F: @@f_BIO_new_ssl;                            N: 'BIO_new_ssl';                               MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),    { V8.51 }
    (F: @@f_BIO_new_ssl_connect;                    N: 'BIO_new_ssl_connect';                       MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),    { V8.51 }
    (F: @@f_BIO_ssl_copy_session_id;                N: 'BIO_ssl_copy_session_id';                   MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),    { V8.51 }
    (F: @@f_BIO_ssl_shutdown;                       N: 'BIO_ssl_shutdown';                          MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),    { V8.51 }
    (F: @@f_SSL_CIPHER_description;                 N: 'SSL_CIPHER_description';                    MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CIPHER_get_bits;                    N: 'SSL_CIPHER_get_bits';                       MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CIPHER_get_name;                    N: 'SSL_CIPHER_get_name';                       MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_add_client_CA;                  N: 'SSL_CTX_add_client_CA';                     MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_callback_ctrl;                  N: 'SSL_CTX_callback_ctrl';                     MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_check_private_key;              N: 'SSL_CTX_check_private_key';                 MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),   { V8.40 }
    (F: @@f_SSL_CTX_clear_options;                  N: 'SSL_CTX_clear_options';                     MI: OSSL_VER_1100; MX: OSSL_VER_MAX),  { V8.51 }
    (F: @@f_SSL_CTX_ctrl;                           N: 'SSL_CTX_ctrl';                              MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_free;                           N: 'SSL_CTX_free';                              MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_get0_certificate;               N: 'SSL_CTX_get0_certificate';                  MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),   { V8.40 }
    (F: @@f_SSL_CTX_get0_param;                     N: 'SSL_CTX_get0_param';                        MI: OSSL_VER_1002; MX: OSSL_VER_MAX),     { V8.39 }
    (F: @@f_SSL_CTX_get0_privatekey;                N: 'SSL_CTX_get0_privatekey';                   MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),   { V8.40 }
    (F: @@f_SSL_CTX_get0_security_ex_data;          N: 'SSL_CTX_get0_security_ex_data';             MI: OSSL_VER_1100; MX: OSSL_VER_MAX),  { V8.40 }
    (F: @@f_SSL_CTX_set_alpn_protos;                N: 'SSL_CTX_set_alpn_protos';                   MI: OSSL_VER_1002; MX: OSSL_VER_MAX),   { V8.56 }
    (F: @@f_SSL_CTX_set_alpn_select_cb;             N: 'SSL_CTX_set_alpn_select_cb';                MI: OSSL_VER_1002; MX: OSSL_VER_MAX),   { V8.56 }
    (F: @@f_SSL_CTX_get_cert_store;                 N: 'SSL_CTX_get_cert_store';                    MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_get_client_cert_cb;             N: 'SSL_CTX_get_client_cert_cb';                MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_get_ex_data;                    N: 'SSL_CTX_get_ex_data';                       MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_get_options;                    N: 'SSL_CTX_get_options';                       MI: OSSL_VER_1100; MX: OSSL_VER_MAX),  { V8.51 }
    (F: @@f_SSL_CTX_get_security_level;             N: 'SSL_CTX_get_security_level';                MI: OSSL_VER_1100; MX: OSSL_VER_MAX),  { V8.40 }
    (F: @@f_SSL_CTX_get_verify_depth;               N: 'SSL_CTX_get_verify_depth';                  MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_get_verify_mode;                N: 'SSL_CTX_get_verify_mode';                   MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_load_verify_locations;          N: 'SSL_CTX_load_verify_locations';             MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_new;                            N: 'SSL_CTX_new';                               MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_sess_get_get_cb;                N: 'SSL_CTX_sess_get_get_cb';                   MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_sess_get_new_cb;                N: 'SSL_CTX_sess_get_new_cb';                   MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_sess_get_remove_cb;             N: 'SSL_CTX_sess_get_remove_cb';                MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_sess_set_get_cb;                N: 'SSL_CTX_sess_set_get_cb';                   MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_sess_set_new_cb;                N: 'SSL_CTX_sess_set_new_cb';                   MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_sess_set_remove_cb;             N: 'SSL_CTX_sess_set_remove_cb';                MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_set0_security_ex_data;          N: 'SSL_CTX_set0_security_ex_data';             MI: OSSL_VER_1100; MX: OSSL_VER_MAX),  { V8.40 }
    (F: @@f_SSL_CTX_set1_param;                     N: 'SSL_CTX_set1_param';                        MI: OSSL_VER_1002; MX: OSSL_VER_MAX),     { V8.39 }
    (F: @@f_SSL_CTX_set_cipher_list;                N: 'SSL_CTX_set_cipher_list';                   MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_set_client_CA_list;             N: 'SSL_CTX_set_client_CA_list';                MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_set_client_cert_cb;             N: 'SSL_CTX_set_client_cert_cb';                MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_set_client_hello_cb;             N: 'SSL_CTX_set_client_hello_cb';              MI: OSSL_VER_1101; MX: OSSL_VER_MAX),  { V8.64 }
    (F: @@f_SSL_CTX_set_default_passwd_cb;          N: 'SSL_CTX_set_default_passwd_cb';             MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_set_default_passwd_cb_userdata; N: 'SSL_CTX_set_default_passwd_cb_userdata';    MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_set_default_verify_paths;       N: 'SSL_CTX_set_default_verify_paths';          MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_set_ex_data;                    N: 'SSL_CTX_set_ex_data';                       MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_set_info_callback;              N: 'SSL_CTX_set_info_callback';                 MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_set_msg_callback;               N: 'SSL_CTX_set_msg_callback';                  MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),   { V8.40 }
    (F: @@f_SSL_CTX_set_options;                    N: 'SSL_CTX_set_options';                       MI: OSSL_VER_1100; MX: OSSL_VER_MAX),  { V8.51 }
    (F: @@f_SSL_CTX_set_security_callback;          N: 'SSL_CTX_set_security_callback';             MI: OSSL_VER_1100; MX: OSSL_VER_MAX),  { V8.40 }
    (F: @@f_SSL_CTX_set_security_level;             N: 'SSL_CTX_set_security_level';                MI: OSSL_VER_1100; MX: OSSL_VER_MAX),  { V8.40 }
    (F: @@f_SSL_CTX_set_session_id_context;         N: 'SSL_CTX_set_session_id_context';            MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_set_timeout;                    N: 'SSL_CTX_set_timeout';                       MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_set_trust;                      N: 'SSL_CTX_set_trust';                         MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_set_verify;                     N: 'SSL_CTX_set_verify';                        MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_set_verify_depth;               N: 'SSL_CTX_set_verify_depth';                  MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_use_PrivateKey;                 N: 'SSL_CTX_use_PrivateKey';                    MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_use_PrivateKey_file;            N: 'SSL_CTX_use_PrivateKey_file';               MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_use_certificate;                N: 'SSL_CTX_use_certificate';                   MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_use_certificate_chain_file;     N: 'SSL_CTX_use_certificate_chain_file';        MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_CTX_use_certificate_file;           N: 'SSL_CTX_use_certificate_file';              MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_SESSION_free;                       N: 'SSL_SESSION_free';                          MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_SESSION_get_id;                     N: 'SSL_SESSION_get_id';                        MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_SESSION_get_time;                   N: 'SSL_SESSION_get_time';                      MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_SESSION_get_timeout;                N: 'SSL_SESSION_get_timeout';                   MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_SESSION_set_time;                   N: 'SSL_SESSION_set_time';                      MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_SESSION_set_timeout;                N: 'SSL_SESSION_set_timeout';                   MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_accept;                             N: 'SSL_accept';                                MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_add_client_CA;                      N: 'SSL_add_client_CA';                         MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_alert_desc_string_long;             N: 'SSL_alert_desc_string_long';                MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_alert_type_string_long;             N: 'SSL_alert_type_string_long';                MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_bytes_to_cipher_list;               N: 'SSL_bytes_to_cipher_list';                  MI: OSSL_VER_1101; MX: OSSL_VER_MAX),  { V8.64 }
    (F: @@f_SSL_callback_ctrl;                      N: 'SSL_callback_ctrl';                         MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_clear;                              N: 'SSL_clear';                                 MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_clear_options;                      N: 'SSL_clear_options';                         MI: OSSL_VER_1100; MX: OSSL_VER_MAX),  { V8.51 }
    (F: @@f_SSL_client_hello_isv2;                   N: 'SSL_client_hello_isv2';                    MI: OSSL_VER_1101; MX: OSSL_VER_MAX),  { V8.64 }
    (F: @@f_SSL_client_hello_get0_legacy_version;    N: 'SSL_client_hello_get0_legacy_version';     MI: OSSL_VER_1101; MX: OSSL_VER_MAX),  { V8.64 }
    (F: @@f_SSL_client_hello_get0_random;            N: 'SSL_client_hello_get0_random';             MI: OSSL_VER_1101; MX: OSSL_VER_MAX),  { V8.64 }
    (F: @@f_SSL_client_hello_get0_session_id;        N: 'SSL_client_hello_get0_session_id';         MI: OSSL_VER_1101; MX: OSSL_VER_MAX),  { V8.64 }
    (F: @@f_SSL_client_hello_get0_ciphers;           N: 'SSL_client_hello_get0_ciphers';            MI: OSSL_VER_1101; MX: OSSL_VER_MAX),  { V8.64 }
    (F: @@f_SSL_client_hello_get0_compression_methods; N: 'SSL_client_hello_get0_compression_methods'; MI: OSSL_VER_1101; MX: OSSL_VER_MAX),  { V8.64 }
    (F: @@f_SSL_client_hello_get1_extensions_present;  N: 'SSL_client_hello_get1_extensions_present';  MI: OSSL_VER_1101; MX: OSSL_VER_MAX),  { V8.64 }
    (F: @@f_SSL_client_hello_get0_ext;               N: 'SSL_client_hello_get0_ext';                MI: OSSL_VER_1101; MX: OSSL_VER_MAX),  { V8.64 }
    (F: @@f_SSL_connect;                            N: 'SSL_connect';                               MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_ctrl;                               N: 'SSL_ctrl';                                  MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_do_handshake;                       N: 'SSL_do_handshake';                          MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_free;                               N: 'SSL_free';                                  MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get0_alpn_selected;                 N: 'SSL_get0_alpn_selected';                    MI: OSSL_VER_1002; MX: OSSL_VER_MAX),   { V8.56 }
    (F: @@f_SSL_get0_param;                         N: 'SSL_get0_param';                            MI: OSSL_VER_1002; MX: OSSL_VER_MAX),     { V8.39 }
    (F: @@f_SSL_get0_security_ex_data;              N: 'SSL_get0_security_ex_data';                 MI: OSSL_VER_1100; MX: OSSL_VER_MAX),  { V8.40 }
    (F: @@f_SSL_get1_session;                       N: 'SSL_get1_session';                          MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get1_supported_ciphers;             N: 'SSL_get1_supported_ciphers';                MI: OSSL_VER_1100; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get_SSL_CTX;                        N: 'SSL_get_SSL_CTX';                           MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get_cipher_list;                    N: 'SSL_get_cipher_list';                       MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get_ciphers;                        N: 'SSL_get_ciphers';                           MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get_client_CA_list;                 N: 'SSL_get_client_CA_list';                    MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get_client_ciphers;                 N: 'SSL_get_client_ciphers';                    MI: OSSL_VER_1100; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get_current_cipher;                 N: 'SSL_get_current_cipher';                    MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get_error;                          N: 'SSL_get_error';                             MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get_ex_data;                        N: 'SSL_get_ex_data';                           MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get_ex_data_X509_STORE_CTX_idx;     N: 'SSL_get_ex_data_X509_STORE_CTX_idx';        MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get_fd;                             N: 'SSL_get_fd';                                MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get_options;                        N: 'SSL_get_options';                           MI: OSSL_VER_1100; MX: OSSL_VER_MAX),  { V8.51 }
    (F: @@f_SSL_get_peer_cert_chain;                N: 'SSL_get_peer_cert_chain';                   MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get_peer_certificate;               N: 'SSL_get_peer_certificate';                  MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get_rbio;                           N: 'SSL_get_rbio';                              MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get_rfd;                            N: 'SSL_get_rfd';                               MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get_security_level;                 N: 'SSL_get_security_level';                    MI: OSSL_VER_1100; MX: OSSL_VER_MAX),  { V8.40 }
    (F: @@f_SSL_get_servername;                     N: 'SSL_get_servername';                        MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get_servername_type;                N: 'SSL_get_servername_type';                   MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get_session;                        N: 'SSL_get_session';                           MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get_shutdown;                       N: 'SSL_get_shutdown';                          MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get_state;                          N: 'SSL_get_state';                             MI: OSSL_VER_1100; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get_verify_depth;                   N: 'SSL_get_verify_depth';                      MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get_verify_result;                  N: 'SSL_get_verify_result';                     MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get_version;                        N: 'SSL_get_version';                           MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get_wbio;                           N: 'SSL_get_wbio';                              MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_get_wfd;                            N: 'SSL_get_wfd';                               MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_library_init;                       N: 'SSL_library_init';                          MI: OSSL_VER_MIN; MX: OSSL_VER_1002ZZ),
    (F: @@f_SSL_load_client_CA_file;                N: 'SSL_load_client_CA_file';                   MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_load_error_strings;                 N: 'SSL_load_error_strings';                    MI: OSSL_VER_MIN; MX: OSSL_VER_1002ZZ),
    (F: @@f_SSL_new;                                N: 'SSL_new';                                   MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_read;                               N: 'SSL_read';                                  MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_renegotiate;                        N: 'SSL_renegotiate';                           MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_renegotiate_pending;                N: 'SSL_renegotiate_pending';                   MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_select_next_proto;                  N: 'SSL_select_next_proto';                     MI: OSSL_VER_1002; MX: OSSL_VER_MAX),  { V8.56 }
    (F: @@f_SSL_session_reused;                     N: 'SSL_session_reused';                        MI: OSSL_VER_1100; MX: OSSL_VER_MAX),  { V8.51 }
    (F: @@f_SSL_set0_security_ex_data;              N: 'SSL_set0_security_ex_data';                 MI: OSSL_VER_1100; MX: OSSL_VER_MAX),  { V8.40 }
    (F: @@f_SSL_set1_param;                         N: 'SSL_set1_param';                            MI: OSSL_VER_1002; MX: OSSL_VER_MAX),  { V8.39 }
    (F: @@f_SSL_set_SSL_CTX;                        N: 'SSL_set_SSL_CTX';                           MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_set_accept_state;                   N: 'SSL_set_accept_state';                      MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_set_alpn_protos;                    N: 'SSL_set_alpn_protos';                       MI: OSSL_VER_1002; MX: OSSL_VER_MAX),   { V8.56 }
    (F: @@f_SSL_set_bio;                            N: 'SSL_set_bio';                               MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_set_client_CA_list;                 N: 'SSL_set_client_CA_list';                    MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_set_connect_state;                  N: 'SSL_set_connect_state';                     MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_set_ex_data;                        N: 'SSL_set_ex_data';                           MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_set_fd;                             N: 'SSL_set_fd';                                MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_set_info_callback;                  N: 'SSL_set_info_callback';                     MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_set_msg_callback;                   N: 'SSL_set_msg_callback';                      MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),   { V8.40 }
    (F: @@f_SSL_set_options;                        N: 'SSL_set_options';                           MI: OSSL_VER_1100; MX: OSSL_VER_MAX),  { V8.51 }
    (F: @@f_SSL_set_rfd;                            N: 'SSL_set_rfd';                               MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_set_security_callback;              N: 'SSL_set_security_callback';                 MI: OSSL_VER_1100; MX: OSSL_VER_MAX),  { V8.40 }
    (F: @@f_SSL_set_security_level;                 N: 'SSL_set_security_level';                    MI: OSSL_VER_1100; MX: OSSL_VER_MAX),  { V8.40 }
    (F: @@f_SSL_set_session;                        N: 'SSL_set_session';                           MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_set_session_id_context;             N: 'SSL_set_session_id_context';                MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_set_shutdown;                       N: 'SSL_set_shutdown';                          MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_set_verify;                         N: 'SSL_set_verify';                            MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_set_verify_result;                  N: 'SSL_set_verify_result';                     MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_set_wfd;                            N: 'SSL_set_wfd';                               MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_shutdown;                           N: 'SSL_shutdown';                              MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_state;                              N: 'SSL_state';                                 MI: OSSL_VER_MIN; MX: OSSL_VER_1002ZZ),
    (F: @@f_SSL_state_string;                       N: 'SSL_state_string';                          MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),      { V8.40 }
    (F: @@f_SSL_state_string_long;                  N: 'SSL_state_string_long';                     MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_version;                            N: 'SSL_version';                               MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_want;                               N: 'SSL_want';                                  MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSL_write;                              N: 'SSL_write';                                 MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_SSLv23_client_method;                   N: 'SSLv23_client_method';                      MI: OSSL_VER_MIN; MX: OSSL_VER_1002ZZ),
    (F: @@f_SSLv23_method;                          N: 'SSLv23_method';                             MI: OSSL_VER_MIN; MX: OSSL_VER_1002ZZ),
    (F: @@f_SSLv23_server_method;                   N: 'SSLv23_server_method';                      MI: OSSL_VER_MIN; MX: OSSL_VER_1002ZZ),
    (F: @@f_SSLv3_client_method;                    N: 'SSLv3_client_method';                       MI: OSSL_VER_MIN; MX: OSSL_VER_1002ZZ),
    (F: @@f_SSLv3_method;                           N: 'SSLv3_method';                              MI: OSSL_VER_MIN; MX: OSSL_VER_1002ZZ),
    (F: @@f_SSLv3_server_method;                    N: 'SSLv3_server_method';                       MI: OSSL_VER_MIN; MX: OSSL_VER_1002ZZ),
    (F: @@f_TLS_client_method;                      N: 'TLS_client_method';                         MI: OSSL_VER_1100; MX: OSSL_VER_MAX),
    (F: @@f_TLS_method;                             N: 'TLS_method';                                MI: OSSL_VER_1100; MX: OSSL_VER_MAX),
    (F: @@f_TLS_server_method;                      N: 'TLS_server_method';                         MI: OSSL_VER_1100; MX: OSSL_VER_MAX),
    (F: @@f_TLSv1_1_client_method;                  N: 'TLSv1_1_client_method';                     MI: OSSL_VER_MIN; MX: OSSL_VER_1002ZZ),
    (F: @@f_TLSv1_1_method;                         N: 'TLSv1_1_method';                            MI: OSSL_VER_MIN; MX: OSSL_VER_1002ZZ),
    (F: @@f_TLSv1_1_server_method;                  N: 'TLSv1_1_server_method';                     MI: OSSL_VER_MIN; MX: OSSL_VER_1002ZZ),
    (F: @@f_TLSv1_2_client_method;                  N: 'TLSv1_2_client_method';                     MI: OSSL_VER_MIN; MX: OSSL_VER_1002ZZ),
    (F: @@f_TLSv1_2_method;                         N: 'TLSv1_2_method';                            MI: OSSL_VER_MIN; MX: OSSL_VER_1002ZZ),
    (F: @@f_TLSv1_2_server_method;                  N: 'TLSv1_2_server_method';                     MI: OSSL_VER_MIN; MX: OSSL_VER_1002ZZ),
    (F: @@f_TLSv1_client_method;                    N: 'TLSv1_client_method';                       MI: OSSL_VER_MIN; MX: OSSL_VER_1002ZZ),
    (F: @@f_TLSv1_method;                           N: 'TLSv1_method';                              MI: OSSL_VER_MIN; MX: OSSL_VER_1002ZZ),
    (F: @@f_TLSv1_server_method;                    N: 'TLSv1_server_method';                       MI: OSSL_VER_MIN; MX: OSSL_VER_1002ZZ),
    (F: @@f_d2i_SSL_SESSION;                        N: 'd2i_SSL_SESSION';                           MI: OSSL_VER_MIN; MX: OSSL_VER_MAX),
    (F: @@f_i2d_SSL_SESSION;                        N: 'i2d_SSL_SESSION';                           MI: OSSL_VER_MIN; MX: OSSL_VER_MAX) );

{$IFNDEF OPENSSL_NO_ENGINE}
    GSSLEAYImports2: array[0..0] of TOSSLImports = (
    (F: @@f_SSL_CTX_set_client_cert_engine;         N: 'SSL_CTX_set_client_cert_engine';            MI: OSSL_VER_MIN; MX: OSSL_VER_MAX) );
{$ENDIF}

{$ENDIF} // USE_SSL

implementation

{$IFDEF USE_SSL}

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

{$IFDEF MSWINDOWS}

{ V8.38 Windows API to check authenticode code signing digital certificate on OpenSSL files }
procedure IcsVerifySslDll (const Fname: string);
var
    ErrCode: integer;
    TrustResp: String;
begin
    ErrCode := IcsVerifyTrust (FName, NOT GSSL_SignTest_Certificate, false, TrustResp);
    if (ErrCode = TRUST_E_SUBJECT_NOT_TRUSTED) or (ErrCode = TRUST_E_BAD_DIGEST) or
         (ErrCode = TRUST_E_NOSIGNATURE) or (ErrCode = TRUST_E_EXPLICIT_DISTRUST) then begin
         raise  EIcsSsleayException.Create('Failed to load ' + FName + ' - ' + TrustResp);
    end;
    if GSSL_SignTest_Certificate and ((ErrCode = CERT_E_CHAINING) or
        (ErrCode = CERT_E_UNTRUSTEDROOT) or (ErrCode = CERT_E_UNTRUSTEDTESTROOT)) then begin
         raise  EIcsSsleayException.Create('Failed to load ' + FName + ' - ' + TrustResp);
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{$ENDIF}

// import OpenSSL functions from DLLs, returns blank for OK, or list of missing exports

function SslGetImports (Handle: THandle; List: array of TOSSLImports): string ;  { V8.35 }
var
    I: integer ;
begin
    result := '';
    if (Length (List) = 0) then begin
        result := 'No import list specified' ;
    end;
    for I := 0 to Length(List) - 1 do begin
        if (ICS_OPENSSL_VERSION_NUMBER >= List[I].MI) and
               (ICS_OPENSSL_VERSION_NUMBER <= List[I].MX) then begin
            {$IFDEF MACOS}               { V8.49 }
            List[I].F^ := GetProcAddress (Handle, PChar(string(List[I].N)));
            {$ELSE}
            List[I].F^ := GetProcAddress (Handle, List[I].N);
            {$ENDIF}
            if List[I].F^ = nil then
                result := result + String(List[I].N) + ',' ;
        end;
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function SsleayLoad : Boolean;      {  V8.27 make unique }
var
    ErrCode: Integer;
    FullName, errs: String;   { V8.29 }
begin
    Result := TRUE;
    if GSSLEAY_DLL_Handle <> 0 then Exit; // Already loaded

  { V8.27 sanity check }
    if ICS_OPENSSL_VERSION_NUMBER = 0 then begin
       raise EIcsSsleayException.Create('Must load LIBEAY DLL before SSLEAY');
    end;

  { V8.27 see if opening new or old DLL }
  { V8.27 allow a specific DLL directory to be specified in GSSL_DLL_DIR }
    if ICS_OPENSSL_VERSION_NUMBER >= OSSL_VER_1100 then begin
        FullName := GSSL_DLL_DIR+GSSLEAY_110DLL_Name;  { V8.29 }
        GSSLEAY_DLL_Handle := LoadLibrary(PChar(FullName));
        if GSSLEAY_DLL_Handle = 0 then begin
            ErrCode            := GetLastError;
            GSSLEAY_DLL_Handle := 0;
            if ErrCode = {$IFDEF POSIX} ENOENT {$ELSE} ERROR_MOD_NOT_FOUND {$ENDIF} then
                raise EIcsSsleayException.Create('File not found: ' + FullName)
            else
                raise EIcsSsleayException.Create('Unable to load ' + FullName + '. Win32 error #' + IntToStr(ErrCode));
        end;
    end
    else begin
        FullName := GSSL_DLL_DIR+GSSLEAY_DLL_Name;  { V8.29 }
        GSSLEAY_DLL_Handle := LoadLibrary(PChar(FullName));
        if GSSLEAY_DLL_Handle = 0 then begin
            ErrCode            := GetLastError;
            GSSLEAY_DLL_Handle := 0;
            if ErrCode = {$IFDEF POSIX} ENOENT {$ELSE} ERROR_MOD_NOT_FOUND {$ENDIF} then
                raise EIcsSsleayException.Create('File not found: ' + FullName)
            else
                raise EIcsSsleayException.Create('Unable to load ' + FullName  + '. Win32 error #' + IntToStr(ErrCode));
        end;
    end;
    SetLength(GSSLEAY_DLL_FileName, 256);
    SetLength(GSSLEAY_DLL_FileName, GetModuleFileName(GSSLEAY_DLL_Handle,
                 PChar(GSSLEAY_DLL_FileName), Length(GSSLEAY_DLL_FileName)));

  {$IFDEF MSWINDOWS}
    IcsGetFileVerInfo(GSSLEAY_DLL_FileName,      { V8.27 use full path }
                   GSSLEAY_DLL_FileVersion,
                   GSSLEAY_DLL_FileDescription);

   { V8.38 check authenticode digital signature on DLL }
    if GSSL_SignTest_Check then IcsVerifySslDll (GSSLEAY_DLL_FileName);
  {$ENDIF}

  { V8.35 load all main GSSLEAY_DLL exports }
    errs := SslGetImports (GSSLEAY_DLL_Handle, GSSLEAYImports1) ;
    if errs <> '' then
        raise  EIcsSsleayException.Create('Unable to load ' + FullName + '. Can not find: ' + errs);

{$IFNDEF OPENSSL_NO_ENGINE}
  { V8.35 load engine GSSLEAY_DLL exports }
    errs := SslGetImports (GSSLEAY_DLL_Handle, GSSLEAYImports2) ;
    if errs <> '' then
        raise  EIcsSsleayException.Create('Unable to load ' + FullName + '. Can not find: ' + errs);
{$ENDIF}

    { V8.27 older OpenSSL versions have different export }
    if ICS_OPENSSL_VERSION_NUMBER < OSSL_VER_1100 then begin
    // V8.27 fake new best method with old best method }
       f_TLS_method                := @f_SSLv23_method;
       f_TLS_client_method         := @f_SSLv23_client_method;
       f_TLS_server_method         := @f_SSLv23_server_method;
    end

    { V8.27 new OpenSSL versions have some new, fake old ones }
    else begin
    // V8.27 1.1.0 has lost v3 and v23, and tlsv1x are deprecated, so fake the lot }
       @f_SSLv3_method             := @f_TLS_method;
       @f_SSLv3_client_method      := @f_TLS_client_method;
       @f_SSLv3_server_method      := @f_TLS_server_method;
       @f_SSLv23_method            := @f_TLS_method;
       @f_SSLv23_client_method     := @f_TLS_client_method;
       @f_SSLv23_server_method     := @f_TLS_server_method;
       @f_TLSv1_method             := @f_TLS_method;
       @f_TLSv1_client_method      := @f_TLS_client_method;
       @f_TLSv1_server_method      := @f_TLS_server_method;
       @f_TLSv1_1_method           := @f_TLS_method;
       @f_TLSv1_1_client_method    := @f_TLS_client_method;
       @f_TLSv1_1_server_method    := @f_TLS_server_method;
       @f_TLSv1_2_method           := @f_TLS_method;
       @f_TLSv1_2_client_method    := @f_TLS_client_method;
       @f_TLSv1_2_server_method    := @f_TLS_server_method;
       @f_SSL_library_init         := @IcsSslStub;  { V8.35 }
       @f_SSL_load_error_strings   := @IcsSslStub;  { V8.35 }
       @f_SSL_state                := @IcsSslStub;  { V8.35 }
    end;

end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function f_Ics_SSL_CTX_set_options(C: PSSL_CTX; Op: LongInt): LongInt;   { V8.51 was f_SSL_CTX_set_options }
begin
    if ICS_OPENSSL_VERSION_NUMBER < OSSL_VER_1100 then
        Result := f_SSL_CTX_ctrl(C, SSL_CTRL_OPTIONS, Op, nil)
    else
        Result := f_SSL_CTX_set_options(C, Op);      { exported as of 1.1.0 }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function f_Ics_SSL_CTX_get_options(C: PSSL_CTX): LongInt;                    { V8.51 was f_SSL_CTX_get_options }
begin
    if ICS_OPENSSL_VERSION_NUMBER < OSSL_VER_1100 then
        Result := f_SSL_CTX_ctrl(C, SSL_CTRL_OPTIONS, 0, nil)
    else
        Result := f_SSL_CTX_get_options(C);      { exported as of 1.1.0 }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function f_Ics_SSL_CTX_clear_options(C: PSSL_CTX; Op: LongInt): LongInt;   { V8.51 new }
begin
    if ICS_OPENSSL_VERSION_NUMBER < OSSL_VER_1100 then
        Result := f_SSL_CTX_ctrl(C, SSL_CTRL_CLEAR_OPTIONS, Op, nil)
    else
        Result := f_SSL_CTX_clear_options(C, Op);      { exported as of 1.1.0 }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function f_Ics_SSL_set_options(S: PSSL; Op: LongInt): LongInt;               { V8.51 was f_SSSL_set_options }
begin
    if ICS_OPENSSL_VERSION_NUMBER < OSSL_VER_1100 then
        Result := f_SSL_ctrl(S, SSL_CTRL_OPTIONS, Op, nil)
    else
        Result := f_SSL_set_options(S, Op);      { exported as of 1.1.0 }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function f_Ics_SSL_clear_options(S: PSSL; Op: LongInt): LongInt;              { V8.51 was f_SSL_clear_options }
begin
    if ICS_OPENSSL_VERSION_NUMBER < OSSL_VER_1100 then
        Result := f_SSL_ctrl(S, SSL_CTRL_CLEAR_OPTIONS, Op, nil)
    else
        Result := f_SSL_clear_options(S, Op);      { exported as of 1.1.0 }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function f_Ics_SSL_get_options(S: PSSL): LongInt;                            { V8.51 was f_SSL_get_options }
begin
    if ICS_OPENSSL_VERSION_NUMBER < OSSL_VER_1100 then
        Result := f_SSL_ctrl(S, SSL_CTRL_OPTIONS, 0, nil)
    else
        Result := f_SSL_get_options(S);      { exported as of 1.1.0 }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function f_SSL_want_read(S: PSSL) : Boolean;
begin
    Result := (f_SSL_want(S) = SSL_READING);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function f_SSL_want_write(S: PSSL) : Boolean;
begin
    Result := (f_SSL_want(S) = SSL_WRITING);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function f_SSL_want_nothing(S: PSSL) : Boolean;
begin
    Result := (f_SSL_want(S) = SSL_NOTHING);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function f_SSL_want_x509_lookup(S: PSSL) : Boolean;
begin
    Result := (f_SSL_want(S) = SSL_X509_LOOKUP);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function f_SSL_CTX_set_session_cache_mode(Ctx: PSSL_CTX; Mode: Integer): Integer;
begin
    Result := f_SSL_CTX_ctrl(Ctx, SSL_CTRL_SET_SESS_CACHE_MODE, Mode, nil)
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function f_Ics_SSL_session_reused(SSL: PSSL): Integer;
begin
    if ICS_OPENSSL_VERSION_NUMBER < OSSL_VER_1100 then
        Result := f_SSL_ctrl(SSL, SSL_CTRL_GET_SESSION_REUSED, 0, nil)
    else
        Result := f_SSL_session_reused(SSL);      { exported as of 1.1.0 }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function f_SSL_CTX_sess_set_cache_size(Ctx: PSSL_CTX; CacheSize: Integer): Integer;
begin
    Result := f_SSL_CTX_ctrl(Ctx, SSL_CTRL_SET_SESS_CACHE_SIZE, CacheSize, nil)
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function f_SSL_CTX_add_extra_chain_cert(Ctx: PSSL_CTX; Cert: PX509): Longword;
begin
    Result := f_SSL_CTX_ctrl(Ctx, SSL_CTRL_EXTRA_CHAIN_CERT, 0, PAnsiChar(Cert))
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function f_SSL_set_tlsext_host_name(const S: PSSL; const name: String): Longint;
begin
    Result := f_SSL_ctrl(S, SSL_CTRL_SET_TLSEXT_HOSTNAME,
                          TLSEXT_NAMETYPE_host_name, Pointer(AnsiString(name)));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function f_SSL_CTX_set_tlsext_servername_callback(ctx: PSSL_CTX;
  cb: TCallback_ctrl_fp): Longint;
begin
    Result := f_SSL_CTX_callback_ctrl(ctx, SSL_CTRL_SET_TLSEXT_SERVERNAME_CB, cb);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function f_SSL_CTX_set_tlsext_servername_arg(ctx: PSSL_CTX; arg: Pointer): Longint;
begin
    Result := f_SSL_CTX_ctrl(ctx, SSL_CTRL_SET_TLSEXT_SERVERNAME_ARG, 0, arg);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function f_SSL_set_tlsext_debug_callback(S: PSSL; cb: TCallback_ctrl_fp): Longint;
begin
    Result := f_SSL_callback_ctrl(S, SSL_CTRL_SET_TLSEXT_DEBUG_CB, cb);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function f_SSL_set_tlsext_debug_arg(S: PSSL; arg: Pointer): Longint;
begin
    Result := f_SSL_ctrl(S, SSL_CTRL_SET_TLSEXT_DEBUG_ARG, 0, arg);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_CTX_set_tmp_dh(C: PSSL_CTX; DH: Pointer) : Integer;   { V8.01 }
begin
    Result := f_SSL_CTX_ctrl(C, SSL_CTRL_SET_TMP_DH, 0, DH);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_CTX_set_tmp_ecdh(C: PSSL_CTX; ECDH: Pointer) : Integer;    { V8.01 }
begin
    Result := f_SSL_CTX_ctrl(C, SSL_CTRL_SET_TMP_ECDH, 0, ECDH);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_CTX_set_ecdh_auto(C: PSSL_CTX; onoff: Integer): Integer;    { V8.01 }
begin
    if ICS_OPENSSL_VERSION_NUMBER >= OSSL_VER_1100 then
        Result := 1  { V8.27 always enabled }
    else
        Result := f_SSL_CTX_ctrl(C, SSL_CTRL_SET_ECDH_AUTO, onoff, Nil);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_set_tmp_dh(S: PSSL; DH: Pointer) : Integer;     { V8.01 }
begin
    Result := f_SSL_ctrl(S, SSL_CTRL_SET_TMP_DH, 0, DH);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_set_tmp_ecdh(S: PSSL; ECDH: Pointer) : Integer;    { V8.01 }
begin
    Result := f_SSL_ctrl(S, SSL_CTRL_SET_TMP_ECDH, 0, ECDH);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_set_ecdh_auto(S: PSSL; onoff: integer) : Integer;    { V8.01 }
begin
    Result := f_SSL_ctrl(S, SSL_CTRL_SET_ECDH_AUTO, onoff, Nil);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_CTX_set_min_proto_version(C: PSSL_CTX; version: integer) : Integer;  { V8.27 }
begin
    Result := f_SSL_CTX_ctrl(C, SSL_CTRL_SET_MIN_PROTO_VERSION, version, Nil);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_CTX_set_max_proto_version(C: PSSL_CTX;  version: integer) : Integer;  { V8.27 }
begin
    Result := f_SSL_CTX_ctrl(C, SSL_CTRL_SET_MAX_PROTO_VERSION, version, Nil);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_set_min_proto_version(S: PSSL; version: integer) : Integer;     { V8.27 }
begin
    Result := f_SSL_ctrl(S, SSL_CTRL_SET_MIN_PROTO_VERSION, version, Nil);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_set_max_proto_version(S: PSSL; version: integer) : Integer;     { V8.27 }
begin
    Result := f_SSL_ctrl(S, SSL_CTRL_SET_MAX_PROTO_VERSION, version, Nil);
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_CTX_get_min_proto_version(C: PSSL_CTX) : Integer;               { V8.51 added 1.1.1  }
begin
    Result := f_SSL_CTX_ctrl(C, SSL_CTRL_GET_MIN_PROTO_VERSION, 0, Nil);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_CTX_get_max_proto_version(C: PSSL_CTX) : Integer;               { V8.51 added 1.1.1  }
begin
    Result := f_SSL_CTX_ctrl(C, SSL_CTRL_GET_MAX_PROTO_VERSION, 0, Nil);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_get_min_proto_version(S: PSSL) : Integer;                       { V8.51 added 1.1.1  }
begin
    Result := f_SSL_ctrl(S, SSL_CTRL_GET_MIN_PROTO_VERSION, 0, Nil);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_get_max_proto_version(S: PSSL) : Integer;                       { V8.51 added 1.1.1  }
begin
    Result := f_SSL_ctrl(S, SSL_CTRL_GET_MAX_PROTO_VERSION, 0, Nil);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_CTX_set0_chain(C: PSSL_CTX; sk: PSTACK_OF_X509): Integer;       { V8.27 }
begin
    Result := f_SSL_CTX_ctrl(C, SSL_CTRL_CHAIN, 0, PAnsiChar(sk));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_CTX_add0_chain_cert(C: PSSL_CTX; Cert: PX509): Integer;         { V8.27 }
begin
    Result := f_SSL_CTX_ctrl(C, SSL_CTRL_CHAIN_CERT, 0, PAnsiChar(Cert));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_CTX_get0_chain_certs(C: PSSL_CTX; sk: PPSTACK_OF_X509): Integer; { V8.27 }
begin
    Result := f_SSL_CTX_ctrl(C, SSL_CTRL_GET_CHAIN_CERTS, 0, PAnsiChar(Sk));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_CTX_clear_chain_certs(C: PSSL_CTX): Integer;                    { V8.27 }
begin
    Result := f_SSL_CTX_set0_chain (C, nil);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_CTX_build_cert_chain(C: PSSL_CTX; flags: integer): Integer;     { V8.27 }
begin
    Result := f_SSL_CTX_ctrl(C, SSL_CTRL_BUILD_CERT_CHAIN, flags, Nil);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ alternate for f_SSL_state which has gone in 1.1.0 and later }
function IcsSslGetState(S: PSSL): TSslHandshakeState;                           { V8.27 }
var
    oldstate: Integer;
begin
    if ICS_OPENSSL_VERSION_NUMBER >= OSSL_VER_1100 then
        Result := f_SSL_get_state(S)
    else begin
        oldstate := f_SSL_state(S);
        if ((oldstate and SSL_ST_INIT) <> 0) then
            Result := TLS_ST_CR_SRVR_HELLO
         else if oldstate = SSL_ST_OK then
            Result := TLS_ST_OK
         else
            Result := TLS_ST_Before;
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ stub for old removed functions }
function IcsSslStub: integer;                            { V8.35 }
begin
    result := 0;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure  f_SSL_CTX_set_msg_callback_arg(Ctx: PSSL_CTX; arg: Pointer);    { V8.40 }
begin
    f_SSL_CTX_ctrl(Ctx, SSL_CTRL_SET_MSG_CALLBACK_ARG, 0, arg);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure  f_SSL_set_msg_callback_arg(S: PSSL; arg: Pointer);           { V8.40 }
begin
    f_SSL_ctrl(S, SSL_CTRL_SET_MSG_CALLBACK_ARG, 0, arg);
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_get1_groups(Ctx: PSSL_CTX; GList: Pointer): Integer; { V8.51 OpenSSL 1.1.1 }
begin
    Result := f_SSL_CTX_ctrl(Ctx, SSL_CTRL_GET_GROUPS, 0, GList);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_get_shared_group(Ssl: PSSL; N: Integer): Integer; { V8.51 OpenSSL 1.1.1 }
begin
    Result := f_SSL_ctrl(Ssl, SSL_CTRL_GET_SHARED_GROUP, N, nil);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_CTX_set1_groups(Ctx: PSSL_CTX; GList: Pointer; GListlen: Integer): Integer; { V8.51 OpenSSL 1.1.1 }
begin
    Result := f_SSL_CTX_ctrl(Ctx, SSL_CTRL_SET_GROUPS, GListlen, GList);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_CTX_set1_groups_list(Ctx: PSSL_CTX; GList: Pointer): Integer; { V8.51 OpenSSL 1.1.1 }
begin
    Result := f_SSL_CTX_ctrl(Ctx, SSL_CTRL_SET_GROUPS_LIST, 0, GList);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_set1_groups(Ctx: PSSL_CTX; GList: Pointer; GListlen: Integer): Integer; { V8.51 OpenSSL 1.1.1 }
begin
    Result := f_SSL_CTX_ctrl(Ctx, SSL_CTRL_SET_GROUPS, GListlen, GList);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_set1_groups_list(Ctx: PSSL_CTX; GList: Pointer): Integer; { V8.51 OpenSSL 1.1.1 }
begin
    Result := f_SSL_CTX_ctrl(Ctx, SSL_CTRL_SET_GROUPS_LIST, 0, GList);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_CTX_set_mode(C: PSSL_CTX; version: integer) : Integer;     { V8.51 }
begin
    Result := f_SSL_CTX_ctrl(C, SSL_CTRL_MODE, version, Nil);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_CTX_get_mode(C: PSSL_CTX) : Integer;                       { V8.51 }
begin
    Result := f_SSL_CTX_ctrl(C, SSL_CTRL_MODE, 0, Nil);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_CTX_clear_mode(C: PSSL_CTX;  version: integer) : Integer;  { V8.51 }
begin
    Result := f_SSL_CTX_ctrl(C, SSL_CTRL_CLEAR_MODE, version, Nil);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_set_mode(S: PSSL; version: integer) : Integer;             { V8.51 }
begin
    Result := f_SSL_ctrl(S, SSL_CTRL_MODE, version, Nil);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_get_mode(S: PSSL) : Integer;                               { V8.51 }
begin
    Result := f_SSL_ctrl(S, SSL_CTRL_MODE, 0, Nil);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function  f_SSL_clear_mode(S: PSSL; version: integer) : Integer;           { V8.51 }
begin
    Result := f_SSL_ctrl(S, SSL_CTRL_CLEAR_MODE, version, Nil);
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{$ENDIF}//USE_SSL

end.








