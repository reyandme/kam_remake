{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Authors:      Arno Garrels
              Angus Robertson <delphi@magsys.co.uk>
Creation:     Aug 26, 2007
Description:  SSL key and X509 certification creation
Version:      8.64
EMail:        francois.piette@overbyte.be  http://www.overbyte.be
Support:      https://en.delphipraxis.net/forum/37-ics-internet-component-suite/
Legal issues: Copyright (C) 2007-2020 by François PIETTE
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
Jun 30, 2008 A.Garrels made some changes to prepare SSL code for Unicode.
Jun 30, 2008 A.Garrels added some RSA and Blowfish crypto functions.
Jul 11, 2008 v1.01 RTT <pdfe@oniduo.pt> contributed function CreateCertRequest(),
             slightly modified by A. Garrels.
Jan 29, 2009 V1.03 A.Garrels added overloads which take UnicodeStrings to
             CreateCertRequest() and CreateSelfSignedCert() in D2009 and better.
             Both functions now create UTF-8 certificate fields if they contain
             characters beyond the ASCII range.
Apr 24, 2011 V1.04 Record TEVP_PKEY_st changed in OpenSSL 1.0.0 and had to be
             declared as dummy. Use new functions from OverbyteIcsLibeay to
             make this unit compatible with OpenSSL 1.0.0+.
Apr 24, 2011 V1.05 Include OverbyteIcsTypes.pas to make inlining work.
Nov 12, 2013 V1.06 Angus allow private key and certificate to be saved to separate files
Feb 14, 2014 V1.07 Angus added class TX509Ex derived from TX509Base adding
             properties for most common certificate entries including extensions
             Optionally add clear text comments to PEM files to easily identify
             certifcates.
Apr 18, 2014 V1.07a Arno removed some compiler warnings.
Jul 07, 2014 V1.08 Angus improved certificate comment
June 2015    Angus moved to main source dir
Oct 25, 2015 V1.09 Angus added SignatureAlgorithm property to TX509Ex so we can check
             certificates are SHA256, also KeyInfo, SerialNumHex
             CertInfo provides multiline string of main certificate information for logging
Nov 5, 2015  V8.20 Angus removed a compiler warning, version matches wsocket
Mar 17, 2015 V8.21 Angus use SHA256 for unicode self signed and non-unicode request
May 24, 2016 V8.27 Angus, initial support for OpenSSL 1.1.0
Aug 27, 2016 V8.32 Angus, moved sslRootCACertsBundle long constant from twsocket and
               aplit smaller and make function so it will compile under C++ Builder
Oct 18, 2016 V8.35 Angus, no longer need OverbyteIcsLibeayEx
             added CreateRsaKeyPair
Oct 26, 2016  V8.36 Now using new names for imports renamed in OpenSSL 1.1.0
Nov 22, 2016  V8.39 Moved TX509Ex properties into TX509Class in OverbyteIcsWSocket
Jan 27, 2017  V8.40 Angus New TSslCertTools component to create and sign certificates
              Create Elliptic Curve/ECDSA private keys
              Create certificate request from old certificate
              Sign certificate requests as CA
              Create DHParam files
              Add alternate extended properties to certs, DNS and IP addresses
              Added TEvpCipher and TEvpDigest (hash) types supported by OpenSSL
              Display Sha1Hex in General certificate as Fingerprint
Feb 24, 2017  V8.41 Added CreateCertBundle to build a new PEM or PKCS12 file
                 combining certificate, private key and intermediate files
              Added more certificate request extension properties including alt domains
              Creating requests now adds alternate domains, IP addresses, etc
              Create certificate from request now optionally copies extensions
              The old CreateCertRequest and CreateSelfSignedCert functions now
                 use the TSslCertTools component and provide backward compatibitity
Mar 3, 2017  V8.42 Angus TULargeInteger now ULARGE_INTEGER
Jun 21, 2017 V8.49 Added ISRG Root X1 certificate for Let's Encrypt
             Fixed AV creating second EC key (OpenSSL function fails)
             Now creating X25519 Elliptic Curve private keys
             Total rewrite creating private keys using EVP_PKEY_CTX functions
Sep 22, 2017 V8.50 Alternate DNS names now added correctly to requests and certs
             Corrected X25519 private keys to ED25519, requires OpenSSL 1.1.1
Nov 3, 2017  V8.51 Tested ED25519 keys, can now sign requests and certs
             Added RSA-PSS keys and SHA3 digest hashes, requires OpenSSL 1.1.1
Feb 21, 2018 V8.52 Added DigiCert Global Root G2 and G3 root certificates
             Added key and signature to ReqCertInfo
             Added SaveToDERText
Mar 27, 2018 V8.53 Added GlobalSign Root CA - R2 and GlobalSign ECC Root CA - R5
                root certificates, R2 used by Google.
             Added DST Root CA X3 root, used by Let's Encrypt crossed signing
Oct 2, 2018  V8.57 tidy up UnwrapNames.
             DoSelfSignCert can now use a CSR instead of properties
             Added DoClearCA
             Added SaveToCADatabase which saves CA database entry to CADBFile
             Added COMODO ECC Certification Authority root
             Build with FMX
Aug 07, 2019 V8.62  Added literals for various types to assist apps.
             Added AcmeIdentifier property for ACME validation certificate
             Builds without USE_SSL
Oct 24, 2019 V8.63 Added 'Starfield Services Root Certificate Authority - G2'
               (used by Amazon buckets), and 'Amazon Root CA 1', CA 2, CA 3,
               CA 4 which are replacing Starfield.  Removed expired certs.
May 18, 2020 V8.64 DoKeyPair raises exception for unknown key type.
              CreateSelfSignedCert ignored Days and always created 7 day expiry.
              Added support for International Domain Names for Applications (IDNA),
                i.e. using accents and unicode characters in domain names.
              X509 certificates always have A-Lavels (Punycode ASCII) domain names,
                never UTF8 or Unicode.
              CreateRsaKeyPair uses Unicode file names, as do all other SSL
                certificate functions (through IcsSslOpenFileBio).
              Added CreateSelfSignCertEx to create self signed certificates with
                 subject alternate names and specific key type, used by TSocketServer
                 to start servers with missing certificates.
              Renamed SaveToDERText to SaveReqToDERText for clarity, added
                SaveCertToDERText.
              Added root 'AAA Certificate Services' for Comodo, aka Sectigo.
              Simplified building alternate subject name extensions so that both
                DNS and IP Address can be used together, and IP address is now
                saved correctly.
              ClearAltStack dies on Win64 so suppressed part of the code until
                work out why.


Pending - long term
Create string and file encryption component from existing functions


Using TSslCertTools component
=============================

The main test application for the component is the OverbyteIcsPemtool sample,
which illustrates use of all the methods and properties.

Message digests or hashes:
    TEvpDigest = (Digest_md5, Digest_mdc2, Digest_sha1, Digest_sha224,
        Digest_sha256, Digest_sha384, Digest_sha512, Digest_ripemd160);

Private key algorithm and key length in bits, bracketed comment is security
level and effective bits, beware long RSA key lengths increase SSL overhead heavily:
    TSslPrivKeyType = (
        PrivKeyRsa1024,   // level 1 - 80 bits
        PrivKeyRsa2048,   // level 2 - 112 bits
        PrivKeyRsa3072,   // level 3 - 128 bits
        PrivKeyRsa4096,   // level 3 - 148 bits?
        PrivKeyRsa7680,   // level 4 - 192 bits
        PrivKeyRsa15360,  // level 5 - 256 bits
        PrivKeyECsecp256, // level 3 - 128 bits
        PrivKeyECsecp384, // level 4 - 192 bits
        PrivKeyECsecp512, // level 5 - 256 bits
        PrivKeyECX25519); // level 3 - 128 bits

Private key file encryption:
   TSslPrivKeyCipher = (
        PrivKeyEncNone, PrivKeyEncTripleDES, PrivKeyEncIDEA, PrivKeyEncAES128,
        PrivKeyEncAES192, PrivKeyEncAES256, PrivKeyEncBlowfish128);


Create a new private key file
-----------------------------
A private key is required to create a self signed certificate or a certificate
request, and needs to be installed on any SSL servers (never distribute it).
1 - Set property PrivKeyType (RSA or EC) from TSslPrivKeyType.
2 - Create keys using DoKeyPair method checking exception for any errors.
3 - PrivateKey property contains pointer to new private key.
4 - If file to be encrypted, set property PrivKeyCipher from TSslPrivKeyCipher.
5 - Save private key to file using PrivateKeySaveToPemFile method with optional password.
6 - Optionally save public key to file using PublicKeySaveToPemFile method.

Create a new certificate request from properties
------------------------------------------------
A certificate request is needed to buy a commercial SSL certificate from a public
certificate authority and most importantly specifies the host domain name of the
public SSL server it will secure.
1 - Create a new private key (see above) or load an old key using
PrivateKeyLoadFromPemFile or PrivateKeyLoadFromText methods.
2 - Specify request properties, CommonName (host domain name), Country, State,
Locality, Organization, OrgUnit, KeyDigiSign, KeyKeyEnc, etc, as needed.
3 - Create request using DoCertReqProps method checking exception for any errors.
4 - X509Req property contains pointer to new request.
5 - Save request to PEM file using SaveReqToFile method.
6 - Optionally save request to string using SaveReqToText method.

Create a new certificate request from old certificate
-----------------------------------------------------
This is a shorter way to create a new request when renewing an existing
certificate with the same private key.
1 - Load existing certificate using LoadFromFile or LoadFromText methods.
2 - Load private key for existing certificate using PrivateKeyLoadFromPemFile or
PrivateKeyLoadFromText methods.
3 - Create request using DoCertReqOld method checking exception for any errors.
4 - X509Req property contains pointer to new request.
5 - Save request to PEM file using SaveReqToFile method.
6 - Optionally save request to string using SaveReqToText method.

Create new self signed certificate from properties
--------------------------------------------------
Self signed certificates are mostly used for testing SSL applications on
temporary servers, prior to final deployment to a public server with a
commercial SSL certificate.  Can also used for internal networks.   May
also be used to create your own CA certificate if you want to sign your
own certificates.
1 - Create a new private key (see above) or load an old key using
PrivateKeyLoadFromPemFile or PrivateKeyLoadFromText methods.
2 - Specify certificate properties, CommonName (host domain name), Country, State,
Locality, Organization, OrgUnit, KeyDigiSign, KeyKeyEnc, etc, as needed.
3 - Select CertDigest (hash) property from TEvpDigest.
4 - Create certificate using DoSelfSignCert method checking exception for any errors.
5 - X509 property contains pointer to new certificate.
6 - If file to be encrypted, set property PrivKeyCipher from TSslPrivKeyCipher.
7 - Save certificate to file using SaveToFile method with the file extension
specifying the format that should be used.  Options include IncludePrivateKey
which will save the private key into the same PEM or P12 file, and optional password.
8 - Optionally save certificate to string using SaveCertToText method.

Create new CA signed certificate from certificate request
---------------------------------------------------------
This is how commercial certificate authorities create SSL certificates from
a request, signing it with their own CA certificate (root or intermediate) that
will be trusted by Windows due to the root already being installed locally.
For development, you can create your own CA root certificate and install it in
the Windows certificate store of any test computers, then create certificates
signed by the root and they will be trusted by Windows without needing to accept
security exceptions as happens with self signed certificates.
1 - The CA certificate and CA private key need to loaded using LoadFromFile and
PrivateKeyLoadFromPemFile into X509 and PrivateKey, and these properties
assigned to X509CA and PrivKeyCA respectively.
2 - Load certificate request using LoadReqFromFile.
3 - Currently the subject certificate properties are taken from the request and
can not be edited, extended properties are currently taken from properties,
KeyDigiSign, KeyKeyEnc, etc, as needed.  This needs more work for flexibility.
4 - Select CertDigest (hash) property from TEvpDigest.
5 - Create certificate using DoSignCertReq method checking exception for any errors.
6 - X509 property contains pointer to new certificate.
7 - If file to be encrypted, set property PrivKeyCipher from TSslPrivKeyCipher.
8 - Save certificate to file using SaveToFile method with the file extension
specifying the format that should be used.  Options include IncludePrivateKey
which will save the private key into the same PEM or P12 file, and optional password.
9 - Optionally save certificate to string using SaveCertToText method.

Beware the private key used to create the request must be loaded into PrivateKey
property before saving a private key with the certificate, otherwise the CA key
may be incorrectly saved.

Pending - save details of certificates created to database, to support
transparency and certificate revocation lists.  Currently certificates have
random serial numbers, should allow sequential numbers to be allocated.

Convert certificate from one file format to another
---------------------------------------------------
1 - Load existing certificate using LoadFromFile or LoadFromText methods.
2 - Optionally load private key for existing certificate using
PrivateKeyLoadFromPemFile or PrivateKeyLoadFromText methods.
4 - If file to be encrypted, set property PrivKeyCipher from TSslPrivKeyCipher.
4 - Save certificate to file using SaveToFile method with the file extension
specifying the format that should be used.  Options include IncludePrivateKey
which will save the private key into the same PEM or P12 file, and optional password.
One use for this is to convert base64 DER/PEM certificates into P12/PVX format
that can be easily installed into the Windows certificate store.

Create New DHParams File
------------------------
DHParams contain prime numbers needed to support DH and DHE ciphers (but not
ECDH and ECDHE).  Ideally they should be unique per server and/or application
and some applications even generate new params each day.  But finding prime
numbers is time consuming, the shortest 1,024 bits can take up a minute, 2,048
bits several minutes, 4,096 bits a few hours, and gave up with 8,192 bits after
two days.  ICS include constants sslDHParams2048 and sslDHParams4096 to save
you calculating your own.
1 - Assign OnKeyProgress event handler with Application.ProcessMessages and
optionally a progress indicator so the application remains responsive while
calculating DHParams.
2 - Create DHParams using DoDHParams method passing new file name and number of
bits, 768, 1024, 20248, 4096, 8192.
3 - Optionally save DHParams string returned by DoDHParams method.

Create Certificate Bundle
-------------------------
Builds a new PEM or PKCS12 file by combining certificate, private key and
intermediate files (in any formats with correct file extension).  For servers,
a bundle file is easier to distribute and load than three separate files.
1 - CreateCertBundle is a simple function, that requires four full file names
for the three input files and output file, optional load and save passwords,
and the cipher optionally to encrypt the output file.


 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{$IFNDEF ICS_INCLUDE_MODE}
unit OverbyteIcsSslX509Utils;
{$ENDIF}

{$I include\OverbyteIcsDefs.inc}
{$I Include\OverbyteIcsSslDefs.inc}
{$IFDEF COMPILER14_UP}
  {$IFDEF NO_EXTENDED_RTTI}
    {$RTTI EXPLICIT METHODS([]) FIELDS([]) PROPERTIES([])}
  {$ENDIF}
{$ENDIF}
{$IFDEF COMPILER12_UP}
    { These are usefull for debugging !}
    {$WARN IMPLICIT_STRING_CAST       ON}
    {$WARN IMPLICIT_STRING_CAST_LOSS  ON}
    {$WARN EXPLICIT_STRING_CAST       OFF}
    {$WARN EXPLICIT_STRING_CAST_LOSS  OFF}
{$ENDIF}
{$WARN SYMBOL_PLATFORM   OFF}
{$WARN SYMBOL_LIBRARY    OFF}
{$WARN SYMBOL_DEPRECATED OFF}
{$IFDEF BCB}
    {$ObjExportAll On}
{$ENDIF}
{$IFDEF CPUX64}
  {.$DEFINE PUREPASCAL}
{$ENDIF}

interface

{$IFDEF USE_SSL}

uses

{$IFDEF MSWINDOWS}
  {$IFDEF RTL_NAMESPACES}Winapi.Windows{$ELSE}Windows{$ENDIF},
{$ENDIF}
  {$IFDEF RTL_NAMESPACES}System.SysUtils{$ELSE}SysUtils{$ENDIF},
  {$IFDEF RTL_NAMESPACES}System.Classes{$ELSE}Classes{$ENDIF},
    OverbyteIcsSSLEAY, OverbyteIcsLibeay,
{$IFDEF FMX}
    Ics.Fmx.OverbyteIcsWSocket,
{$ELSE}
    OverbyteIcsWSocket,
{$ENDIF FMX}
    OverByteIcsMD5,
    OverbyteIcsTypes,
    OverbyteIcsLogger,
    OverbyteIcsMimeUtils,
    OverbyteIcsUtils;

const
    BF_BLOCK_SIZE     = 8;

    DigestDispList: array [0..8] of TEvpDigest =
        (Digest_sha1, Digest_sha224, Digest_sha256, Digest_sha384, Digest_sha512,
         Digest_sha3_224, Digest_sha3_256, Digest_sha3_384, Digest_sha3_512);

    DigestListLitsLast = 8;
    DigestListLits: array [0..DigestListLitsLast] of PChar = (   { V8.62 }
        'SHA1 (old)', 'SHA224', 'SHA256', 'SHA384', 'SHA512',
        'SHA3_224', 'SHA3_256', 'SHA3_384', 'SHA3_512');

  { not showing RSA PSS yet }
    SslPrivKeyTypeLitsLast1 = 9;
    SslPrivKeyTypeLitsLast2 = 14;
    SslPrivKeyTypeLits: array [0..SslPrivKeyTypeLitsLast2] of PChar = (   { V8.62 }
        'RSA 1,024 bits (level 1 - 80 bits)',
        'RSA 2,048 bits (level 2 - 112 bits)',
        'RSA 3,072 bits (level 3 - 128 bits, NIST min)',
        'RSA 4,096 bits (level 3 - 128 bits)',
        'RSA 7,680 bits (level 4 - 192 bits)',
        'RSA 15,360 bits (level 5 - 256 bits)',
        'Elliptic Curve secp256  (level 3 - 128 bits)',
        'Elliptic Curve secp384  (level 4 - 192 bits)',
        'Elliptic Curve secp512  (level 5 - 256 bits)',
        'EdDSA ED25519 (level 3 - 128 bits)',
        'RSA-PSS 2,048 bits (level 2 - 112 bits)',
        'RSA-PSS 3,072 bits (level 3 - 128 bits)',
        'RSA-PSS 4,096 bits (level 3 - 128 bits)',
        'RSA-PSS 7,680 bits (level 4 - 192 bits)',
        'RSA-PSS 15,360 bits (level 5 - 256 bits)');

    SslPrivKeyCipherLits: array[TSslPrivKeyCipher] of PChar = (   { V8.62 }
        'None', 'Triple DES', 'IDEA', 'AES128', 'AES192', 'AES256', 'Blowfish');

    SslCertFileOpenExts = 'Certs *.pem;*.cer;*.crt;*.der;*.p12;*.pfx;*.p7*;*.spc|' +
                 '*.pem;*.cer;*.crt;*.der;*.p12;*.pfx;*.p7*;*.spc|All Files *.*|*.*';    { V8.62 }

type
    TCryptProgress = procedure(Obj: TObject; Count: Int64; var Cancel: Boolean);

    PMD5Digest = ^TMD5Digest;
    TCipherType = (ctBfCbc, ctBfCfb64, ctBfOfb, ctBfEcb);

    TIVector = array[0..8] of Byte;
    PIVector = ^TIVector;

    TCipherKey = array[0..47] of Byte;
    TCipherKeyLen = (cklDefault, ckl64bit, ckl128bit, ckl256bit);
    PCipherKey = ^TCipherKey;

    TCipherSalt = String[PKCS5_SALT_LEN];//array[0..PKCS5_SALT_LEN -1] of Byte;

    TCiphContext = packed record
        Key       : TCipherKey;
        IV        : TIVector;
          //IVLen     : Integer;
        Ctx       : PEVP_CIPHER_CTX;
        Cipher    : PEVP_CIPHER;
        Encrypt   : Boolean;
        BlockSize : Integer;
    end;
    PCiphContext = ^TCiphContext;

    TAltItem = record      { V8.64 }
        AltName:  AnsiString;
        AltType:  Integer;
        PunyFlag: Boolean;
    end;

type
    ECertToolsException = class(Exception);

  { V8.40 component to create SSL certificates and keys }
    TSslCertTools = class(TX509Base)
    private
        FNewCert           : PX509;
        FNewReq            : PX509_REQ;
        FRsaKey            : PRSA;
        FPrivKey           : PEVP_PKEY;
        FECkey             : PEC_KEY;
        FECgroup           : PEC_GROUP;
        FX509Req           : Pointer;
        FX509CA            : Pointer;
        FPrivKeyCA         : PEVP_PKEY;
        FCountry           : String;
        FState             : String;
        FLocality          : String;
        FOrganization      : String;
        FOrgUnit           : String;
        FDescr             : String;
        FEmail             : String;
        FCommonName        : String;
        FAltDNSList        : TStrings;
        FAltIpList         : TStrings;
        FAltEmailList      : TStrings;
        FAltIssuer         : String;
        FCRLDistPoint      : String;  // URI:http://myhost.com/myca.crl
        FAuthInfoAcc       : String;  // OCSP;URI:http://ocsp.myhost.com/
        FBasicIsCA         : Boolean;
        FBasicPathLen      : Integer;
        FKeyCertSign       : Boolean;
        FKeyCRLSign        : Boolean;
        FKeyDigiSign       : Boolean;
        FKeyDataEnc        : Boolean;
        FKeyKeyEnc         : Boolean;
        FKeyKeyAgree       : Boolean;
        FKeyNonRepud       : Boolean;
        FKeyExtClient      : Boolean;
        FKeyExtServer      : Boolean;
        FKeyExtEmail       : Boolean;
        FKeyExtCode        : Boolean;
        FExpireDays        : Integer;
        FSerialNum         : Int64;
        FAddComments       : boolean;
        FPrivKeyType       : TSslPrivKeyType;
        FPrivKeyCipher     : TSslPrivKeyCipher;
        FCertDigest        : TEvpDigest;
        FOnKeyProgress     : TNotifyEvent;
        FAltAnsiStr        : array of AnsiString;
        FAltIa5Str         : array of PASN1_STRING;
        FAltGenStr         : array of PGENERAL_NAME;
        FCADBFile          : String;   { V8.57 }
        FAcmeIdentifier    : String;   { V8.62 }
        FAltItems          : array of TAltItem;  { V8.64 }
        FTotAltItems       : Integer;            { V8.64 }
    protected
        function    BuildBasicCons(IsCA: Boolean): AnsiString;
        function    BuildKeyUsage: AnsiString;
        function    BuildExKeyUsage: AnsiString;
        procedure   SetCertExt(Cert: PX509; Nid: integer; const List: AnsiString);
        procedure   BuildAltPropList;                      { V8.64 }
        procedure   BuildAltReqList;                       { V8.64 }
        function    BuildAltStackAll: PStack;              { V8.64 }
        procedure   BuildCertAltSubjAll(Cert: PX509);      { V8.64 }
        procedure   ClearAltStack;
        procedure   FreeAndNilX509CA;
        procedure   FreeAndNilPrivKeyCA;
        procedure   FreeAndNilX509Req;
        procedure   SetX509Req(X509Req: Pointer);
        procedure   SetX509CA(Cert: Pointer);
        procedure   SetPrivKeyCA(Pkey: PEVP_PKEY);
        function    GetReqSubjOneLine: String;
        function    GetReqSubjCName: String;
        function    GetReqSubjOName: String;
        function    GetReqSubjAltNameDNS: String;
        function    GetReqSubjAltNameIP: String;
        function    GetReqKeyUsage: String;
        function    GetReqExKeyUsage: String;
        function    GetReqCertInfo: String;
        function    GetIsReqLoaded: Boolean;
        function    GetIsCALoaded: Boolean;
        procedure   WriteReqToBio(ABio: PBIO; AddInfoText: Boolean = FALSE; const FName: String = ''); virtual;
        function    GetReqKeyInfo: string;       { V8.52 }
        function    GetReqSignAlgo: String;      { V8.52 }
    public
        constructor Create(AOwner: TComponent);
        destructor  Destroy; override;
        procedure   DoCertReqProps;
        procedure   DoCertReqOld;
        procedure   DoSelfSignCert(UseCSR: Boolean = False);   { V8.57 added UseCSR }
        procedure   DoSignCertReq(CopyExtns: Boolean);
        procedure   DoKeyPair;
//        procedure   DoKeyPairOld;
        function    DoDHParams(const FileName: String; Bits: integer): String;
        procedure   DoClearCerts;
        procedure   DoClearCA;  { V8.57 split from DoClearCerts }
        function    SaveToCADatabase(const CertFName: String = 'unknown'): Boolean;  { V8.57 }
        procedure   CreateCertBundle(const CertFile, PKeyFile, InterFile, LoadPw,
                      SaveFile, SavePw: String; KeyCipher: TSslPrivKeyCipher = PrivKeyEncNone);
        function    GetReqEntryByNid(ANid: Integer): String;
        function    GetRequestRawText: String;
        procedure   LoadReqFromFile(const FileName: String);
        procedure   SaveReqToFile(const FileName: String; AddInfoText: Boolean = FALSE);
        function    SaveReqToText(AddInfoText: Boolean = FALSE): String;
        function    SaveReqToDERText: AnsiString;                             { V8.52, V8.64 was SaveToDERText }
        function    SaveCertToDERText: AnsiString;                            { V8.64 }
        function    GetReqExtValuesByName(const ShortName, FieldName: String): String;
        function    GetReqExtByName(const S: String): TExtension;
        property    X509Req             : Pointer       read FX509Req       write SetX509Req;
        property    X509CA              : Pointer       read FX509CA        write SetX509CA;
        property    PrivKeyCA           : PEVP_PKEY     read FPrivKeyCA     write SetPrivKeyCA;
        property    ReqSubjOneLine      : String        read GetReqSubjOneLine;
        property    ReqSubjCName        : String        read GetReqSubjCName;
        property    ReqSubjOName        : String        read GetReqSubjOName;
        property    ReqSubjAltNameDNS   : String        read GetReqSubjAltNameDNS;
        property    ReqSubjAltNameIP    : String        read GetReqSubjAltNameIP;
        property    ReqKeyUsage         : String        read GetReqKeyUsage;
        property    ReqExKeyUsage       : String        read GetReqExKeyUsage;
        property    ReqCertInfo         : String        read GetReqCertInfo;
        property    IsReqLoaded         : Boolean       read GetIsReqLoaded;
        property    IsCALoaded          : Boolean       read GetIsCALoaded;
        property    ReqKeyInfo          : string        read GetReqKeyInfo;       { V8.52 }
        property    ReqSignAlgo         : string        read GetReqSignAlgo;      { V8.52 }
    published
        property Country           : String             read FCountry       write FCountry;
        property State             : String             read FState         write FState;
        property Locality          : String             read FLocality      write FLocality;
        property Organization      : String             read FOrganization  write FOrganization;
        property OrgUnit           : String             read FOrgUnit       write FOrgUnit;
        property Descr             : String             read FDescr         write FDescr;
        property Email             : String             read FEmail         write FEmail;
        property CommonName        : String             read FCommonName    write FCommonName;
        property AltDNSList        : TStrings           read FAltDNSList    write FAltDNSList;
        property AltIpList         : TStrings           read FAltIpList     write FAltIpList;
        property AltEmailList      : TStrings           read FAltEmailList  write FAltEmailList;
        property AltIssuer         : String             read FAltIssuer     write FAltIssuer;
        property CRLDistPoint      : String             read FCRLDistPoint  write FCRLDistPoint;
        property AuthInfoAcc       : String             read FAuthInfoAcc   write FAuthInfoAcc;
        property AcmeIdentifier    : String             read FAcmeIdentifier write FAcmeIdentifier; { V8.62 }
        property BasicIsCA         : Boolean            read FBasicIsCA     write FBasicIsCA;
        property BasicPathLen      : Integer            read FBasicPathLen  write FBasicPathLen;
        property KeyCertSign       : Boolean            read FKeyCertSign   write FKeyCertSign;
        property KeyCRLSign        : Boolean            read FKeyCRLSign    write FKeyCRLSign;
        property KeyDigiSign       : Boolean            read FKeyDigiSign   write FKeyDigiSign;
        property KeyDataEnc        : Boolean            read FKeyDataEnc    write FKeyDataEnc;
        property KeyKeyEnc         : Boolean            read FKeyKeyEnc     write FKeyKeyEnc;
        property KeyKeyAgree       : Boolean            read FKeyKeyAgree   write FKeyKeyAgree;
        property KeyNonRepud       : Boolean            read FKeyNonRepud   write FKeyNonRepud;
        property KeyExtClient      : Boolean            read FKeyExtClient  write FKeyExtClient;
        property KeyExtServer      : Boolean            read FKeyExtServer  write FKeyExtServer;
        property KeyExtEmail       : Boolean            read FKeyExtEmail   write FKeyExtEmail;
        property KeyExtCode        : Boolean            read FKeyExtCode    write FKeyExtCode;
        property ExpireDays        : Integer            read FExpireDays    write FExpireDays;
        property SerialNum         : Int64              read FSerialNum     write FSerialNum;
        property AddComments       : boolean            read FAddComments   write FAddComments;
        property PrivKeyType       : TSslPrivKeyType    read FPrivKeyType   write FPrivKeyType;
        property PrivKeyCipher     : TSslPrivKeyCipher  read FPrivKeyCipher write FPrivKeyCipher;
        property CertDigest        : TEvpDigest         read FCertDigest    write FCertDigest;
        property CADBFile          : String             read FCADBFile      write FCADBFile;    { V8.57 }
        property OnKeyProgress     : TNotifyEvent       read FOnKeyProgress write FOnKeyProgress;
    end;



procedure CreateCertRequest(const RequestFileName, KeyFileName, Country,
  State, Locality, Organization, OUnit, CName, Email: String;
  Bits: Integer; Comment: boolean = false); overload;
procedure CreateSelfSignedCert(const FileName, Country, State,
  Locality, Organization, OUnit, CName, Email: String; Bits: Integer;
  IsCA: Boolean; Days: Integer;
  const KeyFileName: String = ''; Comment: boolean = false);  overload;
procedure CreateSelfSignCertEx(const FileName, CName: String; AltDNSLst: TStrings;
       PKeyType: TSslPrivKeyType = PrivKeyECsecp256; const PW: String = '';
                                             const AcmeId: String = '');  { V8.64 }


{ RSA crypto functions }

procedure CreateRsaKeyPair(const PubFName, PrivFName: String; Bits: Integer);  { V8.35 }

type
  TRsaPadding = (rpPkcs1, rpPkcs1Oaep, rpNoPadding);
  { rpPkcs1 - This currently is the most widely used mode             }
  { rpPkcs1Oaep - This mode is recommended for all new applications   }
  { rpNoPadding - Don't use                                           }
  { http://www.openssl.org/docs/crypto/RSA_public_encrypt.html        }

  function DecryptPrivateRSA(
      PrivKey     : PEVP_PKEY;
      InBuf       : Pointer;
      InLen       : Cardinal;
      OutBuf      : Pointer;
      var OutLen  : Cardinal;
      Padding     : TRsaPadding): Boolean;

  function EncryptPublicRSA(
      PubKey      : PEVP_PKEY;
      InBuf       : Pointer;
      InLen       : Cardinal;
      OutBuf      : Pointer;
      var OutLen  : Cardinal;
      Padding     : TRsaPadding): Boolean;

function StrEncRsa(PubKey: PEVP_PKEY; const S: AnsiString; B64: Boolean;
    Padding: TRsaPadding = rpPkcs1): AnsiString;
function StrDecRsa(PrivKey: PEVP_PKEY; S: AnsiString; B64: Boolean;
    Padding: TRsaPadding = rpPkcs1): AnsiString;

{ Symmetric cipher stuff, far from being completed.       }
{ Should probably be implemented as a class or component. }


procedure CiphPasswordToKey(InBuf: AnsiString; Salt: TCipherSalt; Count: Integer;
    var Key: TCipherKey; var KeyLen: Integer; var IV: TIVector; var IVLen: Integer);
procedure CiphInitialize(var CiphCtx: TCiphContext; const Pwd: AnsiString; Key: PCipherKey;
    IVector: PIVector; CipherType: TCipherType; KeyLen: TCipherKeyLen; Enc: Boolean);
procedure CiphSetIVector(var CiphCtx: TCiphContext; IVector: PIVector);
procedure CiphFinalize(var CiphCtx: TCiphContext);
procedure CiphUpdate(const InBuf; InLen: Integer; const OutBuf;
    var OutLen: Integer; CiphCtx: TCiphContext);
procedure CiphFinal(const OutBuf; var OutLen : Integer; CiphCtx : TCiphContext);

function StrEncBf(const S: AnsiString; const Pwd: AnsiString; IV: PIVector;
    KeyLen: TCipherKeyLen; B64: Boolean): AnsiString;
function StrDecBf(S: AnsiString; const Pwd: AnsiString; IV: PIVector;
    KeyLen: TCipherKeyLen; B64: Boolean): AnsiString;

procedure StreamEncrypt(SrcStream: TStream; DestStream: TStream;
    StrBlkSize: Integer; CiphCtx: TCiphContext; RandomIV: Boolean); overload;
procedure StreamDecrypt(SrcStream: TStream; DestStream: TStream;
    StrBlkSize: Integer; CiphCtx: TCiphContext; RandomIV: Boolean); overload;
procedure StreamEncrypt(SrcStream: TStream; DestStream: TStream;
    StrBlkSize: Integer; CiphCtx: TCiphContext; RandomIV: Boolean;
    Obj: TObject; ProgressCallback : TCryptProgress); overload;
procedure StreamDecrypt(SrcStream: TStream; DestStream: TStream;
    StrBlkSize: Integer; CiphCtx: TCiphContext; RandomIV: Boolean;
    Obj: TObject; ProgressCallback : TCryptProgress); overload;
function sslRootCACertsBundle: string ;


const
  { V8.27 Root CA Certs Bundle of about 30 PEM certificates extracted from
    Windows 2012 R2 server by OverbyteIcsPemtool, assign this to
    SslContext.SslCALines.Text to verify remote SSL certificates in client
    aplications, not for servers }
  { V8.32 C++ Builder max constant 2048 so split into separate certificates }
    sslRootCACerts001 =
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Organisation: VeriSign Trust Network' + #13#10 +
        '# Subject Organisation Unit: VeriSign, Inc., VeriSign Time Stamping Service Root, NO LIABILITY ACCEPTED, (c)97 VeriSign, Inc.' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 07/01/2004' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIICvDCCAiUCEEoZ0jiMglkcpV1zXxVd3KMwDQYJKoZIhvcNAQEEBQAwgZ4xHzAd' + #13#10 +
        'BgNVBAoTFlZlcmlTaWduIFRydXN0IE5ldHdvcmsxFzAVBgNVBAsTDlZlcmlTaWdu' + #13#10 +
        'LCBJbmMuMSwwKgYDVQQLEyNWZXJpU2lnbiBUaW1lIFN0YW1waW5nIFNlcnZpY2Ug' + #13#10 +
        'Um9vdDE0MDIGA1UECxMrTk8gTElBQklMSVRZIEFDQ0VQVEVELCAoYyk5NyBWZXJp' + #13#10 +
        'U2lnbiwgSW5jLjAeFw05NzA1MTIwMDAwMDBaFw0wNDAxMDcyMzU5NTlaMIGeMR8w' + #13#10 +
        'HQYDVQQKExZWZXJpU2lnbiBUcnVzdCBOZXR3b3JrMRcwFQYDVQQLEw5WZXJpU2ln' + #13#10 +
        'biwgSW5jLjEsMCoGA1UECxMjVmVyaVNpZ24gVGltZSBTdGFtcGluZyBTZXJ2aWNl' + #13#10 +
        'IFJvb3QxNDAyBgNVBAsTK05PIExJQUJJTElUWSBBQ0NFUFRFRCwgKGMpOTcgVmVy' + #13#10 +
        'aVNpZ24sIEluYy4wgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBANMuIPBofCwt' + #13#10 +
        'LoEcsQaypwu3EQ1X2lPYdePJMyqy1PYJWzTz6ZD+CQzQ2xtauc3n9oixncCHJet9' + #13#10 +
        'WBBzanjLcRX9xlj2KatYXpYE/S1iEViBHMpxlNUiWC/VzBQFhDa6lKq0TUrp7jsi' + #13#10 +
        'rVaZfiGcbIbASkeXarSmNtX8CS3TtDmbAgMBAAEwDQYJKoZIhvcNAQEEBQADgYEA' + #13#10 +
        'YVUOPnvHkhJ+ERCOIszUsxMrW+hE5At4nqR+86cHch7iWe/MhOOJlEzbTmHvs6T7' + #13#10 +
        'Rj1QNAufcFb2jip/F87lY795aQdzLrCVKIr17aqp0l3NCsoQCY/Os68olsR5KYSS' + #13#10 +
        '3P+6Z0JIppAQ5L9h+JxT5ZPRcz/4/Z1PhKxV0f0RY2M=' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts002 =
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Common Name: UTN-USERFirst-Object' + #13#10 +
        '# Subject Organisation: The USERTRUST Network' + #13#10 +
        '# Subject Organisation Unit: http://www.usertrust.com' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 09/07/2019' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIEZjCCA06gAwIBAgIQRL4Mi1AAJLQR0zYt4LNfGzANBgkqhkiG9w0BAQUFADCB' + #13#10 +
        'lTELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAlVUMRcwFQYDVQQHEw5TYWx0IExha2Ug' + #13#10 +
        'Q2l0eTEeMBwGA1UEChMVVGhlIFVTRVJUUlVTVCBOZXR3b3JrMSEwHwYDVQQLExho' + #13#10 +
        'dHRwOi8vd3d3LnVzZXJ0cnVzdC5jb20xHTAbBgNVBAMTFFVUTi1VU0VSRmlyc3Qt' + #13#10 +
        'T2JqZWN0MB4XDTk5MDcwOTE4MzEyMFoXDTE5MDcwOTE4NDAzNlowgZUxCzAJBgNV' + #13#10 +
        'BAYTAlVTMQswCQYDVQQIEwJVVDEXMBUGA1UEBxMOU2FsdCBMYWtlIENpdHkxHjAc' + #13#10 +
        'BgNVBAoTFVRoZSBVU0VSVFJVU1QgTmV0d29yazEhMB8GA1UECxMYaHR0cDovL3d3' + #13#10 +
        'dy51c2VydHJ1c3QuY29tMR0wGwYDVQQDExRVVE4tVVNFUkZpcnN0LU9iamVjdDCC' + #13#10 +
        'ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAM6qgT+jo2F4qjEAVZURnicP' + #13#10 +
        'HxzfOpuCaDDASmEd8S8O+r5596Uj71VRloTN2+O5bj4x2AogZ8f02b+U60cEPgLO' + #13#10 +
        'KqJdhwQJ9jCdGIqXsqoc/EHSoTbL+z2RuufZcDX65OeQw5ujm9M89RKZd7G3CeBo' + #13#10 +
        '5hy485RjiGpq/gt2yb70IuRnuasaXnfBhQfdDWy/7gbHd2pBnqcP1/vulBe3/IW+' + #13#10 +
        'pKvEHDHd17bR5PDv3xaPslKT16HUiaEHLr/hARJCHhrh2JU022R5KP+6LhHC5ehb' + #13#10 +
        'kkj7RwvCbNqtMoNB86XlQXD9ZZBt+vpRxPm9lisZBCzTbafc8H9vg2XiaquHhnUC' + #13#10 +
        'AwEAAaOBrzCBrDALBgNVHQ8EBAMCAcYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4E' + #13#10 +
        'FgQU2u1kdBScFDyr3ZmpvVsoTYs8ydgwQgYDVR0fBDswOTA3oDWgM4YxaHR0cDov' + #13#10 +
        'L2NybC51c2VydHJ1c3QuY29tL1VUTi1VU0VSRmlyc3QtT2JqZWN0LmNybDApBgNV' + #13#10 +
        'HSUEIjAgBggrBgEFBQcDAwYIKwYBBQUHAwgGCisGAQQBgjcKAwQwDQYJKoZIhvcN' + #13#10 +
        'AQEFBQADggEBAAgfUrE3RHjb/c652pWWmKpVZIC1WkDdIaXFwfNfLEzIR1pp6ujw' + #13#10 +
        'NTX00CXzyKakh0q9G7FzCL3Uw8q2NbtZhncxzaeAFK4T7/yxSPlrJSUtUbYsbUXB' + #13#10 +
        'mMiKVl0+7kNOPmsnjtA6S4ULX9Ptaqd1y9Fahy85dRNacrACgZ++8A+EVCBibGnU' + #13#10 +
        '4U3GDZlDAQ0Slox4nb9QorFEqmrPF3rPbw/U+CRVX/A0FklmPlBGyWNxODFiuGK5' + #13#10 +
        '81OtbLUrohKqGU8J2l7nk8aOFAj+8DCAGKCGhU3IfdeLA/5u1fedFqySLKAj5ZyR' + #13#10 +
        'Uh+U3xeUc8OzwcFxBSAAeL0TUh2oPs0AH8g=' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts003 =
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Common Name: GeoTrust Global CA' + #13#10 +
        '# Subject Organisation: GeoTrust Inc.' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 21/05/2022' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIDVDCCAjygAwIBAgIDAjRWMA0GCSqGSIb3DQEBBQUAMEIxCzAJBgNVBAYTAlVT' + #13#10 +
        'MRYwFAYDVQQKEw1HZW9UcnVzdCBJbmMuMRswGQYDVQQDExJHZW9UcnVzdCBHbG9i' + #13#10 +
        'YWwgQ0EwHhcNMDIwNTIxMDQwMDAwWhcNMjIwNTIxMDQwMDAwWjBCMQswCQYDVQQG' + #13#10 +
        'EwJVUzEWMBQGA1UEChMNR2VvVHJ1c3QgSW5jLjEbMBkGA1UEAxMSR2VvVHJ1c3Qg' + #13#10 +
        'R2xvYmFsIENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2swYYzD9' + #13#10 +
        '9BcjGlZ+W988bDjkcbd4kdS8odhM+KhDtgPpTSEHCIjaWC9mOSm9BXiLnTjoBbdq' + #13#10 +
        'fnGk5sRgprDvgOSJKA+eJdbtg/OtppHHmMlCGDUUna2YRpIuT8rxh0PBFpVXLVDv' + #13#10 +
        'iS2Aelet8u5fa9IAjbkU+BQVNdnARqN7csiRv8lVK83Qlz6cJmTM386DGXHKTubU' + #13#10 +
        '1XupGc1V3sjs0l44U+VcT4wt/lAjNvxm5suOpDkZALeVAjmRCw7+OC7RHQWa9k0+' + #13#10 +
        'bw8HHa8sHo9gOeL6NlMTOdReJivbPagUvTLrGAMoUgRx5aszPeE4uwc2hGKceeoW' + #13#10 +
        'MPRfwCvocWvk+QIDAQABo1MwUTAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTA' + #13#10 +
        'ephojYn7qwVkDBF9qn1luMrMTjAfBgNVHSMEGDAWgBTAephojYn7qwVkDBF9qn1l' + #13#10 +
        'uMrMTjANBgkqhkiG9w0BAQUFAAOCAQEANeMpauUvXVSOKVCUn5kaFOSPeCpilKIn' + #13#10 +
        'Z57QzxpeR+nBsqTP3UEaBU6bS+5Kb1VSsyShNwrrZHYqLizz/Tt1kL/6cdjHPTfS' + #13#10 +
        'tQWVYrmm3ok9Nns4d0iXrKYgjy6myQzCsplFAMfOEVEiIuCl6rYVSAlk6l5PdPcF' + #13#10 +
        'PseKUgzbFbS9bZvlxrFUaKnjaZC2mqUPuLk/IH2uSrW4nOQdtqvmlKXBx4Ot2/Un' + #13#10 +
        'hw4EbNX/3aBd7YdStysVAq45pmp06drE57xNNB6pXE0zX5IJL4hmXXeXxx12E6nV' + #13#10 +
        '5fEWCRE11azbJHFwLJhWC9kXtNHjUStedejV0NxPNO3CBWaAocvmMw==' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts004 =
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Common Name: SwissSign Gold CA - G2' + #13#10 +
        '# Subject Organisation: SwissSign AG' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 25/10/2036' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIFujCCA6KgAwIBAgIJALtAHEP1Xk+wMA0GCSqGSIb3DQEBBQUAMEUxCzAJBgNV' + #13#10 +
        'BAYTAkNIMRUwEwYDVQQKEwxTd2lzc1NpZ24gQUcxHzAdBgNVBAMTFlN3aXNzU2ln' + #13#10 +
        'biBHb2xkIENBIC0gRzIwHhcNMDYxMDI1MDgzMDM1WhcNMzYxMDI1MDgzMDM1WjBF' + #13#10 +
        'MQswCQYDVQQGEwJDSDEVMBMGA1UEChMMU3dpc3NTaWduIEFHMR8wHQYDVQQDExZT' + #13#10 +
        'd2lzc1NpZ24gR29sZCBDQSAtIEcyMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC' + #13#10 +
        'CgKCAgEAr+TufoskDhJuqVAtFkQ7kpJcyrhdhJJCEyq8ZVeCQD5XJM1QiyUqt2/8' + #13#10 +
        '76LQwB8CJEoTlo8jE+YoWACjR8cGp4QjK7u9lit/VcyLwVcfDmJlD909Vopz2q5+' + #13#10 +
        'bbqBHH5CjCA12UNNhPqE21Is8w4ndwtrvxEvcnifLtg+5hg3Wipy+dpikJKVyh+c' + #13#10 +
        '6bM8K8vzARO/Ws/BtQpgvd21mWRTuKCWs2/iJneRjOBiEAKfNA+k1ZIzUd6+jbqE' + #13#10 +
        'emA8atufK+ze3gE/bk3lUIbLtK/tREDFylqM2tIrfKjuvqblCqoOpd8FUrdVxyJd' + #13#10 +
        'MmqXl2MT28nbeTZ7hTpKxVKJ+STnnXepgv9VHKVxaSvRAiTysybUa9oEVeXBCsdt' + #13#10 +
        'MDeQKuSeFDNeFhdVxVu1yzSJkvGdJo+hB9TGsnhQ2wwMC3wLjEHXuendjIj3o02y' + #13#10 +
        'MszYF9rNt85mndT9Xv+9lz4pded+p2JYryU0pUHHPbwNUMoDAw8IWh+Vc3hiv69y' + #13#10 +
        'FGkOpeUDDniOJihC8AcLYiAQZzlG+qkDzAQ4embvIIO1jEpWjpEA/I5cgt6IoMPi' + #13#10 +
        'aG59je883WX0XaxR7ySArqpWl2/5rX3aYT+YdzylkbYcjCbaZaIJbcHiVOO5ykxM' + #13#10 +
        'gI93e2CaHt+28kgeDrpOVG2Y4OGiGqJ3UM/EY5LsRxmd6+ZrzsECAwEAAaOBrDCB' + #13#10 +
        'qTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUWyV7' + #13#10 +
        'lqRlUX64OfPAeGZe6Drn8O4wHwYDVR0jBBgwFoAUWyV7lqRlUX64OfPAeGZe6Drn' + #13#10 +
        '8O4wRgYDVR0gBD8wPTA7BglghXQBWQECAQEwLjAsBggrBgEFBQcCARYgaHR0cDov' + #13#10 +
        'L3JlcG9zaXRvcnkuc3dpc3NzaWduLmNvbS8wDQYJKoZIhvcNAQEFBQADggIBACe6' + #13#10 +
        '45R88a7A3hfm5djV9VSwg/S7zV4Fe0+fdWavPOhWfvxyeDgD2StiGwC5+OlgzczO' + #13#10 +
        'UYrHUDFu4Up+GC9pWbY9ZIEr44OE5iKHjn3g7gKZYbge9LgriBIWhMIxkziWMaa5' + #13#10 +
        'O1M/wySTVltpkuzFwbs4AOPsF6m43Md8AYOfMke6UiI0HTJ6CVanfCU2qT1L2sCC' + #13#10 +
        'bwq7EsiHSycR+R4tx5M/nttfJmtS2S6K8RTGRI0Vqbe/vd6mGu6uLftIdxf+u+yv' + #13#10 +
        'GPUqUfA5hJeVbG4bwyvEdGB5JbAKJ9/fXtI5z0V9QkvfsywexcZdylU6oJxpmo/a' + #13#10 +
        '77KwPJ+HbBIrZXAVUjEaJM9vMSNQH4xPjyPDdEFjHFWoFN0+4FFQz/EbMFYOkrCC' + #13#10 +
        'hdiDyyJkvC24JdVUorgG6q2SpCSgwYa1ShNqR88uC1aVVMvOmttqtKay20EIhid3' + #13#10 +
        '92qgQmwLOM7XdVAyksLfKzAiSNDVQTglXaTpXZ/GlHXQRf0wl0OPkKsKx4ZzYEpp' + #13#10 +
        'Ld6leNcG2mqeSz53OiATIgHQv2ieY2BrNU0LbbqhPcCT4H8js1WtciVORvnSFu+w' + #13#10 +
        'ZMEBnunKoGqYDs/YYPIvSbjkQuE4NRb0yG5P94FW6LqjviOvrv1vA+ACOzB2+htt' + #13#10 +
        'Qc8Bsem4yWb02ybzOqR08kkkW8mw0FfB+j564ZfJ' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts005 =
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Common Name: Baltimore CyberTrust Root' + #13#10 +
        '# Subject Organisation: Baltimore' + #13#10 +
        '# Subject Organisation Unit: CyberTrust' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 12/05/2025' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIDdzCCAl+gAwIBAgIEAgAAuTANBgkqhkiG9w0BAQUFADBaMQswCQYDVQQGEwJJ' + #13#10 +
        'RTESMBAGA1UEChMJQmFsdGltb3JlMRMwEQYDVQQLEwpDeWJlclRydXN0MSIwIAYD' + #13#10 +
        'VQQDExlCYWx0aW1vcmUgQ3liZXJUcnVzdCBSb290MB4XDTAwMDUxMjE4NDYwMFoX' + #13#10 +
        'DTI1MDUxMjIzNTkwMFowWjELMAkGA1UEBhMCSUUxEjAQBgNVBAoTCUJhbHRpbW9y' + #13#10 +
        'ZTETMBEGA1UECxMKQ3liZXJUcnVzdDEiMCAGA1UEAxMZQmFsdGltb3JlIEN5YmVy' + #13#10 +
        'VHJ1c3QgUm9vdDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKMEuyKr' + #13#10 +
        'mD1X6CZymrV51Cni4eiVgLGw41uOKymaZN+hXe2wCQVt2yguzmKiYv60iNoS6zjr' + #13#10 +
        'IZ3AQSsBUnuId9Mcj8e6uYi1agnnc+gRQKfRzMpijS3ljwumUNKoUMMo6vWrJYeK' + #13#10 +
        'mpYcqWe4PwzV9/lSEy/CG9VwcPCPwBLKBsua4dnKM3p31vjsufFoREJIE9LAwqSu' + #13#10 +
        'XmD+tqYF/LTdB1kC1FkYmGP1pWPgkAx9XbIGevOF6uvUA65ehD5f/xXtabz5OTZy' + #13#10 +
        'dc93Uk3zyZAsuT3lySNTPx8kmCFcB5kpvcY67Oduhjprl3RjM71oGDHweI12v/ye' + #13#10 +
        'jl0qhqdNkNwnGjkCAwEAAaNFMEMwHQYDVR0OBBYEFOWdWTCCR1jMrPoIVDaGezq1' + #13#10 +
        'BE3wMBIGA1UdEwEB/wQIMAYBAf8CAQMwDgYDVR0PAQH/BAQDAgEGMA0GCSqGSIb3' + #13#10 +
        'DQEBBQUAA4IBAQCFDF2O5G9RaEIFoN27TyclhAO992T9Ldcw46QQF+vaKSm2eT92' + #13#10 +
        '9hkTI7gQCvlYpNRhcL0EYWoSihfVCr3FvDB81ukMJY2GQE/szKN+OMY3EU/t3Wgx' + #13#10 +
        'jkzSswF07r51XgdIGn9w/xZchMB5hbgF/X++ZRGjD8ACtPhSNzkE1akxehi/oCr0' + #13#10 +
        'Epn3o0WC4zxe9Z2etciefC7IpJ5OCBRLbf1wbWsaY71k5h+3zvDyny67G7fyUIhz' + #13#10 +
        'ksLi4xaNmjICq44Y3ekQEe5+NauQrz4wlHrQMz2nZQ/1/I6eYs9HRCwBXbsdtTLS' + #13#10 +
        'R9I4LtD+gdwyah617jzV/OeBHRnDJELqYzmp' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts007 =
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Common Name: QuoVadis Root CA 2' + #13#10 +
        '# Subject Organisation: QuoVadis Limited' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 24/11/2031' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIFtzCCA5+gAwIBAgICBQkwDQYJKoZIhvcNAQEFBQAwRTELMAkGA1UEBhMCQk0x' + #13#10 +
        'GTAXBgNVBAoTEFF1b1ZhZGlzIExpbWl0ZWQxGzAZBgNVBAMTElF1b1ZhZGlzIFJv' + #13#10 +
        'b3QgQ0EgMjAeFw0wNjExMjQxODI3MDBaFw0zMTExMjQxODIzMzNaMEUxCzAJBgNV' + #13#10 +
        'BAYTAkJNMRkwFwYDVQQKExBRdW9WYWRpcyBMaW1pdGVkMRswGQYDVQQDExJRdW9W' + #13#10 +
        'YWRpcyBSb290IENBIDIwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCa' + #13#10 +
        'GMpLlA0ALa8DKYrwD4HIrkwZhR0In6spRIXzL4GtMh6QRr+jhiYaHv5+HBg6XJxg' + #13#10 +
        'Fyo6dIMzMH1hVBHL7avg5tKifvVrbxi3Cgst/ek+7wrGsxDp3MJGF/hd/aTa/55J' + #13#10 +
        'WpzmM+Yklvc/ulsrHHo1wtZn/qtmUIttKGAr79dgw8eTvI02kfN/+NsRE8Scd3bB' + #13#10 +
        'rrcCaoF6qUWD4gXmuVbBlDePSHFjIuwXZQeVikvfj8ZaCuWw419eaxGrDPmF60Tp' + #13#10 +
        '+ARz8un+XJiM9XOva7R+zdRcAitMOeGylZUtQofX1bOQQ7dsE/He3fbE+Ik/0XX1' + #13#10 +
        'ksOR1YqI0JDs3G3eicJlcZaLDQP9nL9bFqyS2+r+eXyt66/3FsvbzSUr5R/7mp/i' + #13#10 +
        'Ucw6UwxI5g69ybR2BlLmEROFcmMDBOAENisgGQLodKcftslWZvB1JdxnwQ5hYIiz' + #13#10 +
        'PtGo/KPaHbDRsSNU30R2be1B2MGyIrZTHN81Hdyhdyox5C315eXbyOD/5YDXC2Og' + #13#10 +
        '/zOhD7osFRXql7PSorW+8oyWHhqPHWykYTe5hnMz15eWniN9gqRMgeKh0bpnX5UH' + #13#10 +
        'oycR7hYQe7xFSkyyBNKr79X9DFHOUGoIMfmR2gyPZFwDwzqLID9ujWc9Otb+fVuI' + #13#10 +
        'yV77zGHcizN300QyNQliBJIWENieJ0f7OyHj+OsdWwIDAQABo4GwMIGtMA8GA1Ud' + #13#10 +
        'EwEB/wQFMAMBAf8wCwYDVR0PBAQDAgEGMB0GA1UdDgQWBBQahGK8SEwzJQTU7tD2' + #13#10 +
        'A8QZRtGUazBuBgNVHSMEZzBlgBQahGK8SEwzJQTU7tD2A8QZRtGUa6FJpEcwRTEL' + #13#10 +
        'MAkGA1UEBhMCQk0xGTAXBgNVBAoTEFF1b1ZhZGlzIExpbWl0ZWQxGzAZBgNVBAMT' + #13#10 +
        'ElF1b1ZhZGlzIFJvb3QgQ0EgMoICBQkwDQYJKoZIhvcNAQEFBQADggIBAD4KFk2f' + #13#10 +
        'BluornFdLwUvZ+YTRYPENvbzwCYMDbVHZF34tHLJRqUDGCdViXh9duqWNIAXINzn' + #13#10 +
        'g/iN/Ae42l9NLmeyhP3ZRPx3UIHmfLTJDQtyU/h2BwdBR5YM++CCJpNVjP4iH2Bl' + #13#10 +
        'fF/nJrP3MpCYUNQ3cVX2kiF495V5+vgtJodmVjB3pjd4M1IQWK4/YY7yarHvGH5K' + #13#10 +
        'WWPKjaJW1acvvFYfzznB4vsKqBUsfU16Y8Zsl0Q80m/DShcK+JDSV6IZUaUtl0Ha' + #13#10 +
        'B0+pUNqQjZRG4T7wlP0QADj1O+hA4bRuVhogzG9Yje0uRY/W6ZM/57Es3zrWIozc' + #13#10 +
        'hLsib9D45MY56QSIPMO661V6bYCZJPVsAfv4l7CUW+v90m/xd2gNNWQjrLhVoQPR' + #13#10 +
        'TUIZ3Ph1WVaj+ahJefivDrkRoHy3au000LYmYjgahwz46P0u05B/B5EqHdZ+XIWD' + #13#10 +
        'mbA4CD/pXvk1B+TJYm5Xf6dQlfe6yJvmjqIBxdZmv3lh8zwc4bmCXF2gw+nYSL0Z' + #13#10 +
        'ohEUGW6yhhtoPkg3Goi3XZZenMfvJ2II4pEZXNLxId26F0KCl3GBUzGpn/Z9Yr9y' + #13#10 +
        '4aOTHcyKJloJONDO1w2AFrR4pTqHTI2KpdVGl/IsELm8VCLAAVBpQ570su9t+Oza' + #13#10 +
        '8eOx79+Rj1QqCyXBJhnEUhAFZdWCEOrCMc0u' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts008 =
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Common Name: Starfield Root Certificate Authority - G2' + #13#10 +
        '# Subject Organisation: Starfield Technologies, Inc.' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 31/12/2037' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIID3TCCAsWgAwIBAgIBADANBgkqhkiG9w0BAQsFADCBjzELMAkGA1UEBhMCVVMx' + #13#10 +
        'EDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxJTAjBgNVBAoT' + #13#10 +
        'HFN0YXJmaWVsZCBUZWNobm9sb2dpZXMsIEluYy4xMjAwBgNVBAMTKVN0YXJmaWVs' + #13#10 +
        'ZCBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAtIEcyMB4XDTA5MDkwMTAwMDAw' + #13#10 +
        'MFoXDTM3MTIzMTIzNTk1OVowgY8xCzAJBgNVBAYTAlVTMRAwDgYDVQQIEwdBcml6' + #13#10 +
        'b25hMRMwEQYDVQQHEwpTY290dHNkYWxlMSUwIwYDVQQKExxTdGFyZmllbGQgVGVj' + #13#10 +
        'aG5vbG9naWVzLCBJbmMuMTIwMAYDVQQDEylTdGFyZmllbGQgUm9vdCBDZXJ0aWZp' + #13#10 +
        'Y2F0ZSBBdXRob3JpdHkgLSBHMjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC' + #13#10 +
        'ggEBAL3twQP89o/8ArFvW59I2Z154qK3A2FWGMNHttfKPTUuiUP3oWmb3ooa/RMg' + #13#10 +
        'nLRJdzIpVv257IzdIvpy3Cdhl+72WoTsbhm5iSzchFvVdPtrX8WJpRBSiUZV9Lh1' + #13#10 +
        'HOZ/5FSuS/hVclcCGfgXcVnrHigHdMWdSL5stPSksPNkN3mSwOxGXn/hbVNMYq/N' + #13#10 +
        'Hwtjuzqd+/x5AJhhdM8mgkBj87JyahkNmcrUDnXMN/uLicFZ8WJ/X7NfZTD4p7dN' + #13#10 +
        'dloedl40wOiWVpmKs/B/pM293DIxfJHP4F8R+GuqSVzRmZTRouNjWwl2tVZi4Ut0' + #13#10 +
        'HZbUJtQIBFnQmA4O5t78w+wfkPECAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAO' + #13#10 +
        'BgNVHQ8BAf8EBAMCAQYwHQYDVR0OBBYEFHwMMh+n2TB/xH1oo2Kooc6rB1snMA0G' + #13#10 +
        'CSqGSIb3DQEBCwUAA4IBAQARWfolTwNvlJk7mh+ChTnUdgWUXuEok21iXQnCoKjU' + #13#10 +
        'sHU48TRqneSfioYmUeYs0cYtbpUgSpIB7LiKZ3sx4mcujJUDJi5DnUox9g61DLu3' + #13#10 +
        '4jd/IroAow57UvtruzvE03lRTs2Q9GcHGcg8RnoNAX3FWOdt5oUwF5okxBDgBPfg' + #13#10 +
        '8n/Uqgr/Qh037ZTlZFkSIHc40zI+OIF1lnP6aI+xy84fxez6nH7PfrHxBy22/L/K' + #13#10 +
        'pL/QlwVKvOoYKAKQvVR4CSFx09F9HdkWsKlhPdAKACL8x3vLCWRFCztAgfd9fDL1' + #13#10 +
        'mMpYjn0q7pBZc2T5NnReJaH1ZgUufzkVqSr7UIuOhWn0' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts009 =
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Common Name: Entrust Root Certification Authority' + #13#10 +
        '# Subject Organisation: Entrust, Inc.' + #13#10 +
        '# Subject Organisation Unit: www.entrust.net/CPS is incorporated by reference, (c) 2006 Entrust, Inc.' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 27/11/2026' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIEkTCCA3mgAwIBAgIERWtQVDANBgkqhkiG9w0BAQUFADCBsDELMAkGA1UEBhMC' + #13#10 +
        'VVMxFjAUBgNVBAoTDUVudHJ1c3QsIEluYy4xOTA3BgNVBAsTMHd3dy5lbnRydXN0' + #13#10 +
        'Lm5ldC9DUFMgaXMgaW5jb3Jwb3JhdGVkIGJ5IHJlZmVyZW5jZTEfMB0GA1UECxMW' + #13#10 +
        'KGMpIDIwMDYgRW50cnVzdCwgSW5jLjEtMCsGA1UEAxMkRW50cnVzdCBSb290IENl' + #13#10 +
        'cnRpZmljYXRpb24gQXV0aG9yaXR5MB4XDTA2MTEyNzIwMjM0MloXDTI2MTEyNzIw' + #13#10 +
        'NTM0MlowgbAxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1FbnRydXN0LCBJbmMuMTkw' + #13#10 +
        'NwYDVQQLEzB3d3cuZW50cnVzdC5uZXQvQ1BTIGlzIGluY29ycG9yYXRlZCBieSBy' + #13#10 +
        'ZWZlcmVuY2UxHzAdBgNVBAsTFihjKSAyMDA2IEVudHJ1c3QsIEluYy4xLTArBgNV' + #13#10 +
        'BAMTJEVudHJ1c3QgUm9vdCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTCCASIwDQYJ' + #13#10 +
        'KoZIhvcNAQEBBQADggEPADCCAQoCggEBALaVtkNC+sZtKm9I35RMOVcF7sN5EUFo' + #13#10 +
        'Nu3s/poBj6E4KPz3EEZmLk0eGrEaTsbRwJWIsMn/MYszA9u3g3s+IIRe7bJWKKf4' + #13#10 +
        '4LlAcTfFy0cOlypowCKVYhXbR9n10Cv/gkvJrT7eTNuQgFA/CYqEAOwwCj0Yzfv9' + #13#10 +
        'KlmaI5UXLEWeH25DeW0MXJj+SKfFI0dcXv1u5x609mhF0YaDW6KKjbHjKYD+JXGI' + #13#10 +
        'rb68j6xSlkuqUY3kEzEZ6E5Nn9uss2rVvDlUccp6en+Q3X0dgNmBu1kmwhH+5pPi' + #13#10 +
        '94DkZfs0Nw4pgHBNrziGLp5/V6+eF67rHMsoIV+2HNjnogQi+dPa2MsCAwEAAaOB' + #13#10 +
        'sDCBrTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUwAwEB/zArBgNVHRAEJDAi' + #13#10 +
        'gA8yMDA2MTEyNzIwMjM0MlqBDzIwMjYxMTI3MjA1MzQyWjAfBgNVHSMEGDAWgBRo' + #13#10 +
        'kORnpKZTgMeGZqTx90tD+4S9bTAdBgNVHQ4EFgQUaJDkZ6SmU4DHhmak8fdLQ/uE' + #13#10 +
        'vW0wHQYJKoZIhvZ9B0EABBAwDhsIVjcuMTo0LjADAgSQMA0GCSqGSIb3DQEBBQUA' + #13#10 +
        'A4IBAQCT1DCw1wMgKtD5Y+iRDAUgqV8ZyntyTtSx29CW+1RaGSwMCPeyvIWonX9t' + #13#10 +
        'O1KzKtvn1ISMY/YPyyYBkVBs9F8U4pN0wBOeMDpQ47RgxRzwIkSNcUesyBrJ6Zua' + #13#10 +
        'AGAT/3B+XxFNSRuzFVJ7yVTav52Vr2ua2J7p8eRDjeIRRDq/r72DQnNSi6q7pynP' + #13#10 +
        '9WQcCk3RvKqsnyrQ/39/2n3qse0wJcGE2jTSW3iDVuycNsMm4hH2Z0kdkquM++v/' + #13#10 +
        'eu6FSqdQgPCnXEqULl8FmTxSQeDNtGPPAUO6nIPcj2A781q0tHuu2guQOHXvgR1m' + #13#10 +
        '0vdXcDazv/wor3ElhVsT/h5/WrQ8' + #13#10;
    sslRootCACerts010 =
        '-----END CERTIFICATE-----' + #13#10 +
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Common Name: GlobalSign Root CA' + #13#10 +
        '# Subject Organisation: GlobalSign nv-sa' + #13#10 +
        '# Subject Organisation Unit: Root CA' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 28/01/2028' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIDdTCCAl2gAwIBAgILBAAAAAABFUtaw5QwDQYJKoZIhvcNAQEFBQAwVzELMAkG' + #13#10 +
        'A1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExEDAOBgNVBAsTB1Jv' + #13#10 +
        'b3QgQ0ExGzAZBgNVBAMTEkdsb2JhbFNpZ24gUm9vdCBDQTAeFw05ODA5MDExMjAw' + #13#10 +
        'MDBaFw0yODAxMjgxMjAwMDBaMFcxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9i' + #13#10 +
        'YWxTaWduIG52LXNhMRAwDgYDVQQLEwdSb290IENBMRswGQYDVQQDExJHbG9iYWxT' + #13#10 +
        'aWduIFJvb3QgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDaDuaZ' + #13#10 +
        'jc6j40+Kfvvxi4Mla+pIH/EqsLmVEQS98GPR4mdmzxzdzxtIK+6NiY6arymAZavp' + #13#10 +
        'xy0Sy6scTHAHoT0KMM0VjU/43dSMUBUc71DuxC73/OlS8pF94G3VNTCOXkNz8kHp' + #13#10 +
        '1Wrjsok6Vjk4bwY8iGlbKk3Fp1S4bInMm/k8yuX9ifUSPJJ4ltbcdG6TRGHRjcdG' + #13#10 +
        'snUOhugZitVtbNV4FpWi6cgKOOvyJBNPc1STE4U6G7weNLWLBYy5d4ux2x8gkasJ' + #13#10 +
        'U26Qzns3dLlwR5EiUWMWea6xrkEmCMgZK9FGqkjWZCrXgzT/LCrBbBlDSgeF59N8' + #13#10 +
        '9iFo7+ryUp9/k5DPAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBBjAPBgNVHRMBAf8E' + #13#10 +
        'BTADAQH/MB0GA1UdDgQWBBRge2YaRQ2XyolQL30EzTSo//z9SzANBgkqhkiG9w0B' + #13#10 +
        'AQUFAAOCAQEA1nPnfE920I2/7LqivjTFKDK1fPxsnCwrvQmeU79rXqoRSLblCKOz' + #13#10 +
        'yj1hTdNGCbM+w6DjY1Ub8rrvrTnhQ7k4o+YviiY776BQVvnGCv04zcQLcFGUl5gE' + #13#10 +
        '38NflNUVyRRBnMRddWQVDf9VMOyGj/8N7yy5Y0b2qvzfvGn9LhJIZJrglfCm7ymP' + #13#10 +
        'AbEVtQwdpf5pLGkkeB6zpxxxYu7KyJesF12KwvhHhm4qxFYxldBniYUr+WymXUad' + #13#10 +
        'DKqC5JlR3XC321Y9YeRq4VzW9v493kHMB65jUr9TU/Qr6cf9tveCX4XSQRjbgbME' + #13#10 +
        'HMUfpIBvFSDJ3gyICh3WZlXi/EjJKSZp4A==' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts011 =
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Common Name: COMODO RSA Certification Authority' + #13#10 +
        '# Subject Organisation: COMODO CA Limited' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 18/01/2038' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIF2DCCA8CgAwIBAgIQTKr5yttjb+Af907YWwOGnTANBgkqhkiG9w0BAQwFADCB' + #13#10 +
        'hTELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4G' + #13#10 +
        'A1UEBxMHU2FsZm9yZDEaMBgGA1UEChMRQ09NT0RPIENBIExpbWl0ZWQxKzApBgNV' + #13#10 +
        'BAMTIkNPTU9ETyBSU0EgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMTAwMTE5' + #13#10 +
        'MDAwMDAwWhcNMzgwMTE4MjM1OTU5WjCBhTELMAkGA1UEBhMCR0IxGzAZBgNVBAgT' + #13#10 +
        'EkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEaMBgGA1UEChMR' + #13#10 +
        'Q09NT0RPIENBIExpbWl0ZWQxKzApBgNVBAMTIkNPTU9ETyBSU0EgQ2VydGlmaWNh' + #13#10 +
        'dGlvbiBBdXRob3JpdHkwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCR' + #13#10 +
        '6FSS0gpWsawNJN3Fz0RndJkrN6N9I3AAcbxT38T6KhKPS38QVr2fcHK3YX/JSw8X' + #13#10 +
        'pz3jsARh7v8Rl8f0hj4K+j5c+ZPmNHrZFGvnnLOFoIJ6dq9xkNfs/Q36nGz637CC' + #13#10 +
        '9BR++b7Epi9Pf5l/tfxnQ3K9DADWietrLNPtj5gcFKt+5eNu/Nio5JIk2kNrYrhV' + #13#10 +
        '/erBvGy2i/MOjZrkm2xpmfh4SDBF1a3hDTxFYPwyllEnvGfDyi62a+pGx8cgoLEf' + #13#10 +
        'Zd5ICLqkTqnyg0Y3hOvozIFIQ2dOciqbXL1MGyiKXCJ7tKuY2e7gUYPDCUZObT6Z' + #13#10 +
        '+pUX2nwzV0E8jVHtC7ZcryxjGt9XyD+86V3Em69FmeKjWiS0uqlWPc9vqv9JWL7w' + #13#10 +
        'qP/0uK3pN/u6uPQLOvnoQ0IeidiEyxPx2bvhiWC4jChWrBQdnArncevPDt09qZah' + #13#10 +
        'SL0896+1DSJMwBGB7FY79tOi4lu3sgQiUpWAk2nojkxl8ZEDLXB0AuqLZxUpaVIC' + #13#10 +
        'u9ffUGpVRr+goyhhf3DQw6KqLCGqR84onAZFdr+CGCe01a60y1Dma/RMhnEw6abf' + #13#10 +
        'Fobg2P9A3fvQQoh/ozM6LlweQRGBY84YcWsr7KaKtzFcOmpH4MN5WdYgGq/yapiq' + #13#10 +
        'crxXStJLnbsQ/LBMQeXtHT1eKJ2czL+zUdqnR+WEUwIDAQABo0IwQDAdBgNVHQ4E' + #13#10 +
        'FgQUu69+Aj36pvE8hI6t7jiY7NkyMtQwDgYDVR0PAQH/BAQDAgEGMA8GA1UdEwEB' + #13#10 +
        '/wQFMAMBAf8wDQYJKoZIhvcNAQEMBQADggIBAArx1UaEt65Ru2yyTUEUAJNMnMvl' + #13#10 +
        'wFTPoCWOAvn9sKIN9SCYPBMtrFaisNZ+EZLpLrqeLppysb0ZRGxhNaKatBYSaVqM' + #13#10 +
        '4dc+pBroLwP0rmEdEBsqpIt6xf4FpuHA1sj+nq6PK7o9mfjYcwlYRm6mnPTXJ9OV' + #13#10 +
        '2jeDchzTc+CiR5kDOF3VSXkAKRzH7JsgHAckaVd4sjn8OoSgtZx8jb8uk2Intzna' + #13#10 +
        'FxiuvTwJaP+EmzzV1gsD41eeFPfR60/IvYcjt7ZJQ3mFXLrrkguhxuhoqEwWsRqZ' + #13#10 +
        'CuhTLJK7oQkYdQxlqHvLI7cawiiFwxv/0Cti76R7CZGYZ4wUAc1oBmpjIXUDgIiK' + #13#10 +
        'boHGhfKppC3n9KUkEEeDys30jXlYsQab5xoq2Z0B15R97QNKyvDb6KkBPvVWmcke' + #13#10 +
        'jkk9u+UJueBPSZI9FoJAzMxZxuY67RIuaTxslbH9qh17f4a+Hg4yRvv7E491f0yL' + #13#10 +
        'S0Zj/gA0QHDBw7mh3aZw4gSzQbzpgJHqZJx64SIDqZxubw5lT2yHh17zbqD5daWb' + #13#10 +
        'QOhTsiedSrnAdyGN/4fy3ryM7xfft0kL0fJuMAsaDk527RH89elWsn2/x20Kk4yl' + #13#10 +
        '0MC2Hb46TpSi125sC8KKfPog88Tk5c0NqMuRkrF8hey1FGlmDoLnzc7ILaZRfyHB' + #13#10 +
        'NVOFBkpdn627G190' + #13#10;
    sslRootCACerts012 =
        '-----END CERTIFICATE-----' + #13#10 +
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Organisation: Starfield Technologies, Inc.' + #13#10 +
        '# Subject Organisation Unit: Starfield Class 2 Certification Authority' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 29/06/2034' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIEDzCCAvegAwIBAgIBADANBgkqhkiG9w0BAQUFADBoMQswCQYDVQQGEwJVUzEl' + #13#10 +
        'MCMGA1UEChMcU3RhcmZpZWxkIFRlY2hub2xvZ2llcywgSW5jLjEyMDAGA1UECxMp' + #13#10 +
        'U3RhcmZpZWxkIENsYXNzIDIgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMDQw' + #13#10 +
        'NjI5MTczOTE2WhcNMzQwNjI5MTczOTE2WjBoMQswCQYDVQQGEwJVUzElMCMGA1UE' + #13#10 +
        'ChMcU3RhcmZpZWxkIFRlY2hub2xvZ2llcywgSW5jLjEyMDAGA1UECxMpU3RhcmZp' + #13#10 +
        'ZWxkIENsYXNzIDIgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwggEgMA0GCSqGSIb3' + #13#10 +
        'DQEBAQUAA4IBDQAwggEIAoIBAQC3Msj+6XGmBIWtDBFk385N78gDGIc/oav7PKaf' + #13#10 +
        '8MOh2tTYbitTkPskpD6E8J7oX+zlJ0T1KKY/e97gKvDIr1MvnsoFAZMej2YcOadN' + #13#10 +
        '+lq2cwQlZut3f+dZxkqZJRRU6ybH838Z1TBwj6+wRir/resp7defqgSHo9T5iaU0' + #13#10 +
        'X9tDkYI22WY8sbi5gv2cOj4QyDvvBmVmepsZGD3/cVE8MC5fvj13c7JdBmzDI1aa' + #13#10 +
        'K4UmkhynArPkPw2vCHmCuDY96pzTNbO8acr1zJ3o/WSNF4Azbl5KXZnJHoe0nRrA' + #13#10 +
        '1W4TNSNe35tfPe/W93bC6j67eA0cQmdrBNj41tpvi/JEoAGrAgEDo4HFMIHCMB0G' + #13#10 +
        'A1UdDgQWBBS/X7fRzt0fhvRbVazc1xDCDqmI5zCBkgYDVR0jBIGKMIGHgBS/X7fR' + #13#10 +
        'zt0fhvRbVazc1xDCDqmI56FspGowaDELMAkGA1UEBhMCVVMxJTAjBgNVBAoTHFN0' + #13#10 +
        'YXJmaWVsZCBUZWNobm9sb2dpZXMsIEluYy4xMjAwBgNVBAsTKVN0YXJmaWVsZCBD' + #13#10 +
        'bGFzcyAyIENlcnRpZmljYXRpb24gQXV0aG9yaXR5ggEAMAwGA1UdEwQFMAMBAf8w' + #13#10 +
        'DQYJKoZIhvcNAQEFBQADggEBAAWdP4id0ckaVaGsafPzWdqbAYcaT1epoXkJKtv3' + #13#10 +
        'L7IezMdeatiDh6GX70k1PncGQVhiv45YuApnP+yz3SFmH8lU+nLMPUxA2IGvd56D' + #13#10 +
        'eruix/U0F47ZEUD0/CwqTRV/p2JdLiXTAAsgGh1o+Re49L2L7ShZ3U0WixeDyLJl' + #13#10 +
        'xy16paq8U4Zt3VekyvggQQto8PT7dL5WXXp59fkdheMtlb71cZBDzI0fmgAKhynp' + #13#10 +
        'VSJYACPq4xJDKVtHCN2MQWplBqjlIapBtJUhlbl90TSrE9atvNziPTnNvT51cKEY' + #13#10 +
        'WQPJIrSPnNVeKtelttQKbfi3QBFGmh95DmK/D5fs4C8fF5Q=' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts013 =
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Common Name: DigiCert Global Root CA' + #13#10 +
        '# Subject Organisation: DigiCert Inc' + #13#10 +
        '# Subject Organisation Unit: www.digicert.com' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 10/11/2031' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIDrzCCApegAwIBAgIQCDvgVpBCRrGhdWrJWZHHSjANBgkqhkiG9w0BAQUFADBh' + #13#10 +
        'MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3' + #13#10 +
        'd3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBD' + #13#10 +
        'QTAeFw0wNjExMTAwMDAwMDBaFw0zMTExMTAwMDAwMDBaMGExCzAJBgNVBAYTAlVT' + #13#10 +
        'MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j' + #13#10 +
        'b20xIDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290IENBMIIBIjANBgkqhkiG' + #13#10 +
        '9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4jvhEXLeqKTTo1eqUKKPC3eQyaKl7hLOllsB' + #13#10 +
        'CSDMAZOnTjC3U/dDxGkAV53ijSLdhwZAAIEJzs4bg7/fzTtxRuLWZscFs3YnFo97' + #13#10 +
        'nh6Vfe63SKMI2tavegw5BmV/Sl0fvBf4q77uKNd0f3p4mVmFaG5cIzJLv07A6Fpt' + #13#10 +
        '43C/dxC//AH2hdmoRBBYMql1GNXRor5H4idq9Joz+EkIYIvUX7Q6hL+hqkpMfT7P' + #13#10 +
        'T19sdl6gSzeRntwi5m3OFBqOasv+zbMUZBfHWymeMr/y7vrTC0LUq7dBMtoM1O/4' + #13#10 +
        'gdW7jVg/tRvoSSiicNoxBN33shbyTApOB6jtSj1etX+jkMOvJwIDAQABo2MwYTAO' + #13#10 +
        'BgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUA95QNVbR' + #13#10 +
        'TLtm8KPiGxvDl7I90VUwHwYDVR0jBBgwFoAUA95QNVbRTLtm8KPiGxvDl7I90VUw' + #13#10 +
        'DQYJKoZIhvcNAQEFBQADggEBAMucN6pIExIK+t1EnE9SsPTfrgT1eXkIoyQY/Esr' + #13#10 +
        'hMAtudXH/vTBH1jLuG2cenTnmCmrEbXjcKChzUyImZOMkXDiqw8cvpOp/2PV5Adg' + #13#10 +
        '06O/nVsJ8dWO41P0jmP6P6fbtGbfYmbW0W5BjfIttep3Sp+dWOIrWcBAI+0tKIJF' + #13#10 +
        'PnlUkiaY4IBIqDfv8NZ5YBberOgOzW6sRBc4L0na4UU+Krk2U886UAb3LujEV0ls' + #13#10 +
        'YSEY1QSteDwsOoBrp+uvFRTp2InBuThs4pFsiv9kuXclVzDAGySj4dzp30d8tbQk' + #13#10 +
        'CAUw7C29C79Fv1C5qfPrmAESrciIxpg0X40KPMbp1ZWVbd4=' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts014 =
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Common Name: thawte Primary Root CA' + #13#10 +
        '# Subject Organisation: thawte, Inc.' + #13#10 +
        '# Subject Organisation Unit: Certification Services Division, (c) 2006 thawte, Inc. - For authorized use only' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 16/07/2036' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIEIDCCAwigAwIBAgIQNE7VVyDV7exJ9C/ON9srbTANBgkqhkiG9w0BAQUFADCB' + #13#10 +
        'qTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDHRoYXd0ZSwgSW5jLjEoMCYGA1UECxMf' + #13#10 +
        'Q2VydGlmaWNhdGlvbiBTZXJ2aWNlcyBEaXZpc2lvbjE4MDYGA1UECxMvKGMpIDIw' + #13#10 +
        'MDYgdGhhd3RlLCBJbmMuIC0gRm9yIGF1dGhvcml6ZWQgdXNlIG9ubHkxHzAdBgNV' + #13#10 +
        'BAMTFnRoYXd0ZSBQcmltYXJ5IFJvb3QgQ0EwHhcNMDYxMTE3MDAwMDAwWhcNMzYw' + #13#10 +
        'NzE2MjM1OTU5WjCBqTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDHRoYXd0ZSwgSW5j' + #13#10 +
        'LjEoMCYGA1UECxMfQ2VydGlmaWNhdGlvbiBTZXJ2aWNlcyBEaXZpc2lvbjE4MDYG' + #13#10 +
        'A1UECxMvKGMpIDIwMDYgdGhhd3RlLCBJbmMuIC0gRm9yIGF1dGhvcml6ZWQgdXNl' + #13#10 +
        'IG9ubHkxHzAdBgNVBAMTFnRoYXd0ZSBQcmltYXJ5IFJvb3QgQ0EwggEiMA0GCSqG' + #13#10 +
        'SIb3DQEBAQUAA4IBDwAwggEKAoIBAQCsoPD7gFnUnMekz52hWXMJEEUMDSxuaPFs' + #13#10 +
        'W0hoSVk3/AszGcJ3f8wQLZU0HObrTQmnHNK4yZc2AreJ1CRfBsDMRJSUjQJib+ta' + #13#10 +
        '3RGNKJpchJAQeg29dGYvajig4tVUROsdB58Hum/u6f1OCyn1PoSgAfGcq/gcfomk' + #13#10 +
        '6KHYcWUNo1F77rzSImANuVud37r8UVsLr5iy6S7pBOhih94ryNdOwUxkHt3Ph1i6' + #13#10 +
        'Sk/KaAcdHJ1KxtUvkcx8cXIcxcBn6zL9yZJclNqFwJu/U30rCfSMnZEfl2pSy94J' + #13#10 +
        'NqR32HuHUETVPm4pafs5SSYeCaWAe0At6+gnhcn+Yf1+5nyXHdWdAgMBAAGjQjBA' + #13#10 +
        'MA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMB0GA1UdDgQWBBR7W0XP' + #13#10 +
        'r87Lev0xkhpqtvNG61dIUDANBgkqhkiG9w0BAQUFAAOCAQEAeRHAS7ORtvzw6WfU' + #13#10 +
        'DW5FvlXok9LOAz/t2iWwHVfLHjp2oEzsUHboZHIMpKnxuIvW1oeEuzLlQRHAd9mz' + #13#10 +
        'YJ3rG9XRbkREqaYB7FViHXe4XI5ISXycO1cRrK1zN44veFyQaEfZYGDm/Ac9IiAX' + #13#10 +
        'xPcW6cTYcvnIc3zfFi8VqT79aie2oetaupgf1eNNZAqdE8hhuvU5HIe6uL17In/2' + #13#10 +
        '/qxAeeWsEG89jxt5dovEN7MhGITlNgDrYyCZuen+MwS7QcjBAvlEYyCegc5C09Y/' + #13#10 +
        'LHbTY5xZ3Y+m4Q6gLkH3LpVHz7z9M/P2C2F+fpErgUfCJzDupxBdN49cOSvkBPB7' + #13#10 +
        'jVaMaA==' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts015 =
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Common Name: Entrust Root Certification Authority - G2' + #13#10 +
        '# Subject Organisation: Entrust, Inc.' + #13#10 +
        '# Subject Organisation Unit: See www.entrust.net/legal-terms, (c) 2009 Entrust, Inc. - for authorized use only' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 07/12/2030' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIEPjCCAyagAwIBAgIESlOMKDANBgkqhkiG9w0BAQsFADCBvjELMAkGA1UEBhMC' + #13#10 +
        'VVMxFjAUBgNVBAoTDUVudHJ1c3QsIEluYy4xKDAmBgNVBAsTH1NlZSB3d3cuZW50' + #13#10 +
        'cnVzdC5uZXQvbGVnYWwtdGVybXMxOTA3BgNVBAsTMChjKSAyMDA5IEVudHJ1c3Qs' + #13#10 +
        'IEluYy4gLSBmb3IgYXV0aG9yaXplZCB1c2Ugb25seTEyMDAGA1UEAxMpRW50cnVz' + #13#10 +
        'dCBSb290IENlcnRpZmljYXRpb24gQXV0aG9yaXR5IC0gRzIwHhcNMDkwNzA3MTcy' + #13#10 +
        'NTU0WhcNMzAxMjA3MTc1NTU0WjCBvjELMAkGA1UEBhMCVVMxFjAUBgNVBAoTDUVu' + #13#10 +
        'dHJ1c3QsIEluYy4xKDAmBgNVBAsTH1NlZSB3d3cuZW50cnVzdC5uZXQvbGVnYWwt' + #13#10 +
        'dGVybXMxOTA3BgNVBAsTMChjKSAyMDA5IEVudHJ1c3QsIEluYy4gLSBmb3IgYXV0' + #13#10 +
        'aG9yaXplZCB1c2Ugb25seTEyMDAGA1UEAxMpRW50cnVzdCBSb290IENlcnRpZmlj' + #13#10 +
        'YXRpb24gQXV0aG9yaXR5IC0gRzIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK' + #13#10 +
        'AoIBAQC6hLZy254Ma+KZ6TABp3bqMriVQRrJ2mFOWHLP/vaCeb9zYQYKpSfYs1/T' + #13#10 +
        'RU4cctZOMvJyig/3gxnQaoCAAEUesMfnmr8SVycco2gvCoe9amsOXmXzHHfV1IWN' + #13#10 +
        'cCG0szLni6LVhjkCsbjSR87kyUnEO6fe+1R9V77w6G7CebI6C1XiUJgWMhNcL3hW' + #13#10 +
        'wcKUs/Ja5CeanyTXxuzQmyWC48zCxEXFjJd6BmsqEZ+pCm5IO2/b1BEZQvePB7/1' + #13#10 +
        'U1+cPvQXLOZprE4yTGJ36rfo5bs0vBmLrpxR57d+tVOxMyLlbc9wPBr64ptntoP0' + #13#10 +
        'jaWvYkxN4FisZDQSA/i2jZRjJKRxAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBBjAP' + #13#10 +
        'BgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBRqciZ60B7vfec7aVHUbI2fkBJmqzAN' + #13#10 +
        'BgkqhkiG9w0BAQsFAAOCAQEAeZ8dlsa2eT8ijYfThwMEYGprmi5ZiXMRrEPR9RP/' + #13#10 +
        'jTkrwPK9T3CMqS/qF8QLVJ7UG5aYMzyorWKiAHarWWluBh1+xLlEjZivEtRh2woZ' + #13#10 +
        'Rkfz6/djwUAFQKXSt/S1mja/qYh2iARVBCuch38aNzx+LaUa2NSJXsq9rD1s2G2v' + #13#10 +
        '1fN2D807iDginWyTmsQ9v4IbZT+mD12q/OWyFcq1rca8PdCE6OoGcrBNOTJ4vz4R' + #13#10 +
        'nAuknZoh8/CbCzB428Hch0P+vGOaysXCHMnHjf87ElgI5rY97HosTvuDls4MPGmH' + #13#10 +
        'VHOkc8KT/1EQrBVUAdj8BbGJoX90g5pJ19xOe4pIb4tF9g==' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts016 =
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Common Name: SecureTrust CA' + #13#10 +
        '# Subject Organisation: SecureTrust Corporation' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 31/12/2029' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIDuDCCAqCgAwIBAgIQDPCOXAgWpa1Cf/DrJxhZ0DANBgkqhkiG9w0BAQUFADBI' + #13#10 +
        'MQswCQYDVQQGEwJVUzEgMB4GA1UEChMXU2VjdXJlVHJ1c3QgQ29ycG9yYXRpb24x' + #13#10 +
        'FzAVBgNVBAMTDlNlY3VyZVRydXN0IENBMB4XDTA2MTEwNzE5MzExOFoXDTI5MTIz' + #13#10 +
        'MTE5NDA1NVowSDELMAkGA1UEBhMCVVMxIDAeBgNVBAoTF1NlY3VyZVRydXN0IENv' + #13#10 +
        'cnBvcmF0aW9uMRcwFQYDVQQDEw5TZWN1cmVUcnVzdCBDQTCCASIwDQYJKoZIhvcN' + #13#10 +
        'AQEBBQADggEPADCCAQoCggEBAKukgeWVzfX2FI7CT8rU4niVWJxB4Q2ZQCQXOZEz' + #13#10 +
        'Zum+4YOvYlyJ0fwkW2Gz4BERQRwdbvC4u/jep4G6pkjGnx29vo6pQT64lO0pGtSO' + #13#10 +
        '0gMdA+9tDWccV9cGrcrI9f4Or2YlSASWC12juhbDCE/RRvgUXPLIXgGZbf2IzIao' + #13#10 +
        'wW8xQmxSPmjL8xk037uHGFaAJsTQ3MBv396gwpEWoGQRS0S8Hvbn+mPeZqx2pHGj' + #13#10 +
        '7DaUaHp3pLHnDi+BeuK1cobvomuL8A/b01k/unK8RCSc43Oz969XL0Imnal0ugBS' + #13#10 +
        '8kvNU3xHCzaFDmapCJcWNFfBZveA4+1wVMeT4C4oFVmHursCAwEAAaOBnTCBmjAT' + #13#10 +
        'BgkrBgEEAYI3FAIEBh4EAEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB' + #13#10 +
        '/zAdBgNVHQ4EFgQUQjK2FvoE/f5dS3rD/fdMQB1aQ68wNAYDVR0fBC0wKzApoCeg' + #13#10 +
        'JYYjaHR0cDovL2NybC5zZWN1cmV0cnVzdC5jb20vU1RDQS5jcmwwEAYJKwYBBAGC' + #13#10 +
        'NxUBBAMCAQAwDQYJKoZIhvcNAQEFBQADggEBADDtT0rhWDpSclu1pqNlGKa7UTt3' + #13#10 +
        '6Z3q059c4EVlew3KW+JwULKUBRSuSceNQQcSc5R+DCMh/bwQf2AQWnL1mA6s7Ll/' + #13#10 +
        '3XpvXdMc9P+IBWlCqQVxyLesJugutIxq/3HcuLHfmbx8IVQr5Fiiu1cprp6poxkm' + #13#10 +
        'D5kuCLDv/WnPmRoJjeOnnyvJNjR7JLN4TJUXpAYmHrZkUjZfYGfZnMUFdAvnZyPS' + #13#10 +
        'CPyI6a6Lf+Ew9Dd+/cYy2i2eRDAwbO4H3tI0/NL/QPZL9GZGBlSm8jIKYyYwa5vR' + #13#10 +
        '3ItHuuG51WLQoqD0ZwV4KWMabwTW+MZMo5qxN7SN5ShLHZ4swrhovO0C7jE=' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts017 =
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Common Name: Deutsche Telekom Root CA 2' + #13#10 +
        '# Subject Organisation: Deutsche Telekom AG' + #13#10 +
        '# Subject Organisation Unit: T-TeleSec Trust Center' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 09/07/2019' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIDnzCCAoegAwIBAgIBJjANBgkqhkiG9w0BAQUFADBxMQswCQYDVQQGEwJERTEc' + #13#10 +
        'MBoGA1UEChMTRGV1dHNjaGUgVGVsZWtvbSBBRzEfMB0GA1UECxMWVC1UZWxlU2Vj' + #13#10 +
        'IFRydXN0IENlbnRlcjEjMCEGA1UEAxMaRGV1dHNjaGUgVGVsZWtvbSBSb290IENB' + #13#10 +
        'IDIwHhcNOTkwNzA5MTIxMTAwWhcNMTkwNzA5MjM1OTAwWjBxMQswCQYDVQQGEwJE' + #13#10 +
        'RTEcMBoGA1UEChMTRGV1dHNjaGUgVGVsZWtvbSBBRzEfMB0GA1UECxMWVC1UZWxl' + #13#10 +
        'U2VjIFRydXN0IENlbnRlcjEjMCEGA1UEAxMaRGV1dHNjaGUgVGVsZWtvbSBSb290' + #13#10 +
        'IENBIDIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCrC6M14IspFLEU' + #13#10 +
        'ha88EOQ5bzVdSq7d6mGNlUn0b2SjGmBmpKlAIoTZ1KXleJMOaAGtuU1cOs7TuKhC' + #13#10 +
        'QN/Po7qCWWqSG6wcmtoIKyUn+WkjR/Hg6yx6m/UTAtB+NHzCnjwAWav12gz1Mjwr' + #13#10 +
        'rFDa1sPeg5TKqAyZMg4ISFZbavva4VhYAUlfckE8FQYBjl2tqriTtM2e66foai1S' + #13#10 +
        'NNs671x1Udrb8zH57nGYMsRUFUQM+ZtV7a3fGAigo4aKSe5TBY8ZTNXeWHmb0moc' + #13#10 +
        'QqvF1afPaA+W5OFhmHZhyJF81j4A4pFQh+GdCuatl9Idxjp9y7zaAzTVjlsB9WoH' + #13#10 +
        'txa2bkp/AgMBAAGjQjBAMB0GA1UdDgQWBBQxw3kbuvVT1xfgiXotF2wKsyudMzAP' + #13#10 +
        'BgNVHRMECDAGAQH/AgEFMA4GA1UdDwEB/wQEAwIBBjANBgkqhkiG9w0BAQUFAAOC' + #13#10 +
        'AQEAlGRZrTlk5ynrE/5aw4sTV8gEJPB0d8Bg42f76Ymmg7+Wgnxu1MM9756Abrsp' + #13#10 +
        'tJh6sTtU6zkXR34ajgv8HzFZMQSyzhfzLMdiNlXiItiJVbSYSKpk+tYcNthEeFpa' + #13#10 +
        'IzpXl/V6ME+un2pMSyuOoAPjPuCp1NJ70rOo4nI8rZ7/gFnkm0W09juwzTkZmDLl' + #13#10 +
        '6iFhkOQxIY40sfcvNUqFENrnijchvllj4PKFiDFT1FQUhXB59C4Gdyd1Lx+4ivn+' + #13#10 +
        'xbrYNuSD7Odlt79jWvNGr4GUN9RBjNYj1h7P9WgbRGOiWrqnNVmh5XAFmw4jV5mU' + #13#10 +
        'Cm26OWMohpLzGITY+9HPBVZkVw==' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts018 =
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Organisation: VeriSign, Inc.' + #13#10 +
        '# Subject Organisation Unit: Class 3 Public Primary Certification Authority' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 01/08/2028' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIICPDCCAaUCEHC65B0Q2Sk0tjjKewPMur8wDQYJKoZIhvcNAQECBQAwXzELMAkG' + #13#10 +
        'A1UEBhMCVVMxFzAVBgNVBAoTDlZlcmlTaWduLCBJbmMuMTcwNQYDVQQLEy5DbGFz' + #13#10 +
        'cyAzIFB1YmxpYyBQcmltYXJ5IENlcnRpZmljYXRpb24gQXV0aG9yaXR5MB4XDTk2' + #13#10 +
        'MDEyOTAwMDAwMFoXDTI4MDgwMTIzNTk1OVowXzELMAkGA1UEBhMCVVMxFzAVBgNV' + #13#10 +
        'BAoTDlZlcmlTaWduLCBJbmMuMTcwNQYDVQQLEy5DbGFzcyAzIFB1YmxpYyBQcmlt' + #13#10 +
        'YXJ5IENlcnRpZmljYXRpb24gQXV0aG9yaXR5MIGfMA0GCSqGSIb3DQEBAQUAA4GN' + #13#10 +
        'ADCBiQKBgQDJXFme8huKARS0EN8EQNvjV69qRUCPhAwL0TPZ2RHP7gJYHyX3KqhE' + #13#10 +
        'BarsAx94f56TuZoAqiN91qyFomNFx3InzPRMxnVx0jnvT0Lwdd8KkMaOIG+YD/is' + #13#10 +
        'I19wKTakyYbnsZogy1Olhec9vn2a/iRFM9x2Fe0PonFkTGUugWhFpwIDAQABMA0G' + #13#10 +
        'CSqGSIb3DQEBAgUAA4GBALtMEivPLCYATxQT3ab7/AoRhIzzKBxnki98tsX63/Do' + #13#10 +
        'lbwdj2wsqFHMc9ikwFPwTtYmwHYBV4GSXiHx0bH/59AhWM1pF+NEHJwZRDmJXNyc' + #13#10 +
        'AA9WjQKZ7aKQRUzkuxCkPfAyAw7xzvjoyVGM5mKf5p/AfbdynMk2OmufTqj/ZA1k' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts020 =
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Common Name: Thawte Premium Server CA' + #13#10 +
        '# Subject Organisation: Thawte Consulting cc' + #13#10 +
        '# Subject Organisation Unit: Certification Services Division' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 31/12/2020' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIDJzCCApCgAwIBAgIBATANBgkqhkiG9w0BAQQFADCBzjELMAkGA1UEBhMCWkEx' + #13#10 +
        'FTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTESMBAGA1UEBxMJQ2FwZSBUb3duMR0wGwYD' + #13#10 +
        'VQQKExRUaGF3dGUgQ29uc3VsdGluZyBjYzEoMCYGA1UECxMfQ2VydGlmaWNhdGlv' + #13#10 +
        'biBTZXJ2aWNlcyBEaXZpc2lvbjEhMB8GA1UEAxMYVGhhd3RlIFByZW1pdW0gU2Vy' + #13#10 +
        'dmVyIENBMSgwJgYJKoZIhvcNAQkBFhlwcmVtaXVtLXNlcnZlckB0aGF3dGUuY29t' + #13#10 +
        'MB4XDTk2MDgwMTAwMDAwMFoXDTIwMTIzMTIzNTk1OVowgc4xCzAJBgNVBAYTAlpB' + #13#10 +
        'MRUwEwYDVQQIEwxXZXN0ZXJuIENhcGUxEjAQBgNVBAcTCUNhcGUgVG93bjEdMBsG' + #13#10 +
        'A1UEChMUVGhhd3RlIENvbnN1bHRpbmcgY2MxKDAmBgNVBAsTH0NlcnRpZmljYXRp' + #13#10 +
        'b24gU2VydmljZXMgRGl2aXNpb24xITAfBgNVBAMTGFRoYXd0ZSBQcmVtaXVtIFNl' + #13#10 +
        'cnZlciBDQTEoMCYGCSqGSIb3DQEJARYZcHJlbWl1bS1zZXJ2ZXJAdGhhd3RlLmNv' + #13#10 +
        'bTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA0jY2aovXwlue2oFBYo847kkE' + #13#10 +
        'VdbQ7xwblRZH7xhINTpS9CtqBo87L+pW46+GjZ4X9560ZXUCTe/LCaIhUdib0GfQ' + #13#10 +
        'ug2SBhRz1JPLlyoAnFxODLz6FVL88kRu2hFKbgifLy3j+ao6hnO2RlNYyIkFvYMR' + #13#10 +
        'uHM/qgeN9EJN50CdHDcCAwEAAaMTMBEwDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG' + #13#10 +
        '9w0BAQQFAAOBgQAmSCwWwlj66BZ0DKqqX1Q/8tfJeGBeXm43YyJ3Nn6yF8Q0ufUI' + #13#10 +
        'hfzJATj/Tb7yFkJD57taRvvBxhEf8UqwKEbJw8RCfbz6q1lu1bdRiBHjpIUZa4JM' + #13#10 +
        'pAwSremkrj/xw0llmozFyD4lt5SZu5IycQfwhl7tUCemDaYj+bvLpgcUQg==' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts021 =
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Common Name: DigiCert High Assurance EV Root CA' + #13#10 +
        '# Subject Organisation: DigiCert Inc' + #13#10 +
        '# Subject Organisation Unit: www.digicert.com' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 10/11/2031' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIDxTCCAq2gAwIBAgIQAqxcJmoLQJuPC3nyrkYldzANBgkqhkiG9w0BAQUFADBs' + #13#10 +
        'MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3' + #13#10 +
        'd3cuZGlnaWNlcnQuY29tMSswKQYDVQQDEyJEaWdpQ2VydCBIaWdoIEFzc3VyYW5j' + #13#10 +
        'ZSBFViBSb290IENBMB4XDTA2MTExMDAwMDAwMFoXDTMxMTExMDAwMDAwMFowbDEL' + #13#10 +
        'MAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3' + #13#10 +
        'LmRpZ2ljZXJ0LmNvbTErMCkGA1UEAxMiRGlnaUNlcnQgSGlnaCBBc3N1cmFuY2Ug' + #13#10 +
        'RVYgUm9vdCBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMbM5XPm' + #13#10 +
        '+9S75S0tMqbf5YE/yc0lSbZxKsPVlDRnogocsF9ppkCxxLeyj9CYpKlBWTrT3JTW' + #13#10 +
        'PNt0OKRKzE0lgvdKpVMSOO7zSW1xkX5jtqumX8OkhPhPYlG++MXs2ziS4wblCJEM' + #13#10 +
        'xChBVfvLWokVfnHoNb9Ncgk9vjo4UFt3MRuNs8ckRZqnrG0AFFoEt7oT61EKmEFB' + #13#10 +
        'Ik5lYYeBQVCmeVyJ3hlKV9Uu5l0cUyx+mM0aBhakaHPQNAQTXKFx01p8VdteZOE3' + #13#10 +
        'hzBWBOURtCmAEvF5OYiiAhF8J2a3iLd48soKqDirCmTCv2ZdlYTBoSUeh10aUAsg' + #13#10 +
        'EsxBu24LUTi4S8sCAwEAAaNjMGEwDgYDVR0PAQH/BAQDAgGGMA8GA1UdEwEB/wQF' + #13#10 +
        'MAMBAf8wHQYDVR0OBBYEFLE+w2kD+L9HAdSYJhoIAu9jZCvDMB8GA1UdIwQYMBaA' + #13#10 +
        'FLE+w2kD+L9HAdSYJhoIAu9jZCvDMA0GCSqGSIb3DQEBBQUAA4IBAQAcGgaX3Nec' + #13#10 +
        'nzyIZgYIVyHbIUf4KmeqvxgydkAQV8GK83rZEWWONfqe/EW1ntlMMUu4kehDLI6z' + #13#10 +
        'eM7b41N5cdblIZQB2lWHmiRk9opmzN6cN82oNLFpmyPInngiK3BD41VHMWEZ71jF' + #13#10 +
        'hS9OMPagMRYjyOfiZRYzy78aG6A9+MpeizGLYAiJLQwGXFK3xPkKmNEVX58Svnw2' + #13#10 +
        'Yzi9RKR/5CYrCsSXaQ3pjOLAEFe4yHYSkVXySGnYvCoCWw9E1CAx2/S6cCZdkGCe' + #13#10 +
        'vEsXCS+0yx5DaMkHJ8HSXPfqIbloEpw8nL+e/IBcm2PN7EeqJSdnoDfzAIJ9VNep' + #13#10 +
        '+OkuE6N36B9K' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts022 =
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Common Name: Entrust.net Certification Authority (2048)' + #13#10 +
        '# Subject Organisation: Entrust.net' + #13#10 +
        '# Subject Organisation Unit: www.entrust.net/CPS_2048 incorp. by ref. (limits liab.), (c) 1999 Entrust.net Limited' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 24/07/2029' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIEKjCCAxKgAwIBAgIEOGPe+DANBgkqhkiG9w0BAQUFADCBtDEUMBIGA1UEChML' + #13#10 +
        'RW50cnVzdC5uZXQxQDA+BgNVBAsUN3d3dy5lbnRydXN0Lm5ldC9DUFNfMjA0OCBp' + #13#10 +
        'bmNvcnAuIGJ5IHJlZi4gKGxpbWl0cyBsaWFiLikxJTAjBgNVBAsTHChjKSAxOTk5' + #13#10 +
        'IEVudHJ1c3QubmV0IExpbWl0ZWQxMzAxBgNVBAMTKkVudHJ1c3QubmV0IENlcnRp' + #13#10 +
        'ZmljYXRpb24gQXV0aG9yaXR5ICgyMDQ4KTAeFw05OTEyMjQxNzUwNTFaFw0yOTA3' + #13#10 +
        'MjQxNDE1MTJaMIG0MRQwEgYDVQQKEwtFbnRydXN0Lm5ldDFAMD4GA1UECxQ3d3d3' + #13#10 +
        'LmVudHJ1c3QubmV0L0NQU18yMDQ4IGluY29ycC4gYnkgcmVmLiAobGltaXRzIGxp' + #13#10 +
        'YWIuKTElMCMGA1UECxMcKGMpIDE5OTkgRW50cnVzdC5uZXQgTGltaXRlZDEzMDEG' + #13#10 +
        'A1UEAxMqRW50cnVzdC5uZXQgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkgKDIwNDgp' + #13#10 +
        'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArU1LqRKGsuqjIAcVFmQq' + #13#10 +
        'K0vRvwtKTY7tgHalZ7d4QMBzQshowNtTK91euHaYNZOLGp18EzoOH1u3Hs/lJBQe' + #13#10 +
        'sYGpjX24zGtLA/ECDNyrpUAkAH90lKGdCCmziAv1h3edVc3kw37XamSrhRSGlVuX' + #13#10 +
        'MlBvPci6Zgzj/L24ScF2iUkZ/cCovYmjZy/Gn7xxGWC4LeksyZB2ZnuU4q941mVT' + #13#10 +
        'XTzWnLLPKQP5L6RQstRIzgUyVYr9smRMDuSYB3Xbf9+5CFVghTAp+XtIpGmG4zU/' + #13#10 +
        'HoZdenoVve8AjhUiVBcAkCaTvA5JaJG/+EfTnZVCwQ5N328mz8MYIWJmQ3DW1cAH' + #13#10 +
        '4QIDAQABo0IwQDAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUwAwEB/zAdBgNV' + #13#10 +
        'HQ4EFgQUVeSB0RGAvtiJuQijMfmhJAkWuXAwDQYJKoZIhvcNAQEFBQADggEBADub' + #13#10 +
        'j1abMOdTmXx6eadNl9cZlZD7Bh/KM3xGY4+WZiT6QBshJ8rmcnPyT/4xmf3IDExo' + #13#10 +
        'U8aAghOY+rat2l098c5u9hURlIIM7j+VrxGrD9cv3h8Dj1csHsm7mhpElesYT6Yf' + #13#10 +
        'zX1XEC+bBAlahLVu2B064dae0Wx5XnkcFMXj0EyTO2U87d89vqbllRrDtRnDvV5b' + #13#10 +
        'u/8j72gZyxKTJ1wDLW8w0B62GqzeWvfRqqgnpv55gcR5mTNXuhKwqeBCbJPKVt7+' + #13#10 +
        'bYQLCIt+jerXmCHG8+c8eS9enNFMFY3h7CI3zJpDC5fcgJCNs2ebb0gIFVbPv/Er' + #13#10 +
        'fF6adulZkMV8gzURZVE=' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts023 =
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Common Name: VeriSign Class 3 Public Primary Certification Authority - G5' + #13#10 +
        '# Subject Organisation: VeriSign, Inc.' + #13#10 +
        '# Subject Organisation Unit: VeriSign Trust Network, (c) 2006 VeriSign, Inc. - For authorized use only' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 16/07/2036' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIE0zCCA7ugAwIBAgIQGNrRniZ96LtKIVjNzGs7SjANBgkqhkiG9w0BAQUFADCB' + #13#10 +
        'yjELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDlZlcmlTaWduLCBJbmMuMR8wHQYDVQQL' + #13#10 +
        'ExZWZXJpU2lnbiBUcnVzdCBOZXR3b3JrMTowOAYDVQQLEzEoYykgMjAwNiBWZXJp' + #13#10 +
        'U2lnbiwgSW5jLiAtIEZvciBhdXRob3JpemVkIHVzZSBvbmx5MUUwQwYDVQQDEzxW' + #13#10 +
        'ZXJpU2lnbiBDbGFzcyAzIFB1YmxpYyBQcmltYXJ5IENlcnRpZmljYXRpb24gQXV0' + #13#10 +
        'aG9yaXR5IC0gRzUwHhcNMDYxMTA4MDAwMDAwWhcNMzYwNzE2MjM1OTU5WjCByjEL' + #13#10 +
        'MAkGA1UEBhMCVVMxFzAVBgNVBAoTDlZlcmlTaWduLCBJbmMuMR8wHQYDVQQLExZW' + #13#10 +
        'ZXJpU2lnbiBUcnVzdCBOZXR3b3JrMTowOAYDVQQLEzEoYykgMjAwNiBWZXJpU2ln' + #13#10 +
        'biwgSW5jLiAtIEZvciBhdXRob3JpemVkIHVzZSBvbmx5MUUwQwYDVQQDEzxWZXJp' + #13#10 +
        'U2lnbiBDbGFzcyAzIFB1YmxpYyBQcmltYXJ5IENlcnRpZmljYXRpb24gQXV0aG9y' + #13#10 +
        'aXR5IC0gRzUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCvJAgIKXo1' + #13#10 +
        'nmAMqudLO07cfLw8RRy7K+D+KQL5VwijZIUVJ/XxrcgxiV0i6CqqpkKzj/i5Vbex' + #13#10 +
        't0uz/o9+B1fs70PbZmIVYc9gDaTY3vjgw2IIPVQT60nKWVSFJuUrjxuf6/WhkcIz' + #13#10 +
        'SdhDY2pSS9KP6HBRTdGJaXvHcPaz3BJ023tdS1bTlr8Vd6Gw9KIl8q8ckmcY5fQG' + #13#10 +
        'BO+QueQA5N06tRn/Arr0PO7gi+s3i+z016zy9vA9r911kTMZHRxAy3QkGSGT2RT+' + #13#10 +
        'rCpSx4/VBEnkjWNHiDxpg8v+R70rfk/Fla4OndTRQ8Bnc+MUCH7lP59zuDMKz10/' + #13#10 +
        'NIeWiu5T6CUVAgMBAAGjgbIwga8wDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8E' + #13#10 +
        'BAMCAQYwbQYIKwYBBQUHAQwEYTBfoV2gWzBZMFcwVRYJaW1hZ2UvZ2lmMCEwHzAH' + #13#10 +
        'BgUrDgMCGgQUj+XTGoasjY5rw8+AatRIGCx7GS4wJRYjaHR0cDovL2xvZ28udmVy' + #13#10 +
        'aXNpZ24uY29tL3ZzbG9nby5naWYwHQYDVR0OBBYEFH/TZafC3ey78DAJ80M5+gKv' + #13#10 +
        'MzEzMA0GCSqGSIb3DQEBBQUAA4IBAQCTJEowX2LP2BqYLz3q3JktvXf2pXkiOOzE' + #13#10 +
        'p6B4Eq1iDkVwZMXnl2YtmAl+X6/WzChl8gGqCBpH3vn5fJJaCGkgDdk+bW48DW7Y' + #13#10 +
        '5gaRQBi5+MHt39tBquCWIMnNZBU4gcmU7qKEKQsTb47bDN0lAtukixlE0kF6BWlK' + #13#10 +
        'WE9gyn6CagsCqiUXObXbf+eEZSqVir2G3l6BFoMtEMze/aiCKm0oHw0LxOXnGiYZ' + #13#10 +
        '4fQRbxC1lfznQgUy286dUV4otp6F01vvpX1FQHKOtw5rDgb7MzVIcbidJ4vEZV8N' + #13#10 +
        'hnacRHr2lVz2XTIIM6RUthg/aFzyQkqFOFSDX9HoLPKsEdao7WNq' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10 +
        '# X509 SSL Certificate' + #13#10;
    sslRootCACerts026 =
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Organisation: The Go Daddy Group, Inc.' + #13#10 +
        '# Subject Organisation Unit: Go Daddy Class 2 Certification Authority' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 29/06/2034' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIEADCCAuigAwIBAgIBADANBgkqhkiG9w0BAQUFADBjMQswCQYDVQQGEwJVUzEh' + #13#10 +
        'MB8GA1UEChMYVGhlIEdvIERhZGR5IEdyb3VwLCBJbmMuMTEwLwYDVQQLEyhHbyBE' + #13#10 +
        'YWRkeSBDbGFzcyAyIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MB4XDTA0MDYyOTE3' + #13#10 +
        'MDYyMFoXDTM0MDYyOTE3MDYyMFowYzELMAkGA1UEBhMCVVMxITAfBgNVBAoTGFRo' + #13#10 +
        'ZSBHbyBEYWRkeSBHcm91cCwgSW5jLjExMC8GA1UECxMoR28gRGFkZHkgQ2xhc3Mg' + #13#10 +
        'MiBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTCCASAwDQYJKoZIhvcNAQEBBQADggEN' + #13#10 +
        'ADCCAQgCggEBAN6d1+pXGEmhW+vXX0iG6r7d/+TvZxz0ZWizV3GgXne77ZtJ6XCA' + #13#10 +
        'PVYYYwhv2vLM0D9/AlQiVBDYsoHUwHU9S3/Hd8M+eKsaA7Ugay9qK7HFiH7Eux6w' + #13#10 +
        'wdhFJ2+qN1j3hybX2C32qRe3H3I2TqYXP2WYktsqbl2i/ojgC95/5Y0V4evLOtXi' + #13#10 +
        'EqITLdiOr18SPaAIBQi2XKVlOARFmR6jYGB0xUGlcmIbYsUfb18aQr4CUWWoriMY' + #13#10 +
        'avx4A6lNf4DD+qta/KFApMoZFv6yyO9ecw3ud72a9nmYvLEHZ6IVDd2gWMZEewo+' + #13#10 +
        'YihfukEHU1jPEX44dMX4/7VpkI+EdOqXG68CAQOjgcAwgb0wHQYDVR0OBBYEFNLE' + #13#10 +
        'sNKR1EwRcbNhyz2h/t2oatTjMIGNBgNVHSMEgYUwgYKAFNLEsNKR1EwRcbNhyz2h' + #13#10 +
        '/t2oatTjoWekZTBjMQswCQYDVQQGEwJVUzEhMB8GA1UEChMYVGhlIEdvIERhZGR5' + #13#10 +
        'IEdyb3VwLCBJbmMuMTEwLwYDVQQLEyhHbyBEYWRkeSBDbGFzcyAyIENlcnRpZmlj' + #13#10 +
        'YXRpb24gQXV0aG9yaXR5ggEAMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQEFBQAD' + #13#10 +
        'ggEBADJL87LKPpH8EsahB4yOd6AzBhRckB4Y9wimPQoZ+YeAEW5p5JYXMP80kWNy' + #13#10 +
        'OO7MHAGjHZQopDH2esRU1/blMVgDoszOYtuURXO1v0XJJLXVggKtI3lpjbi2Tc7P' + #13#10 +
        'TMozI+gciKqdi0FuFskg5YmezTvacPd+mSYgFFQlq25zheabIZ0KbIIOqPjCDPoQ' + #13#10 +
        'HmyW74cNxA9hi63ugyuV+I6ShHI56yDqg+2DzZduCLzrTia2cyvk0/ZM/iZx4mER' + #13#10 +
        'dEr/VxqHD3VILs9RaRegAhJhldXRQLIQTO7ErBBDpqWeCtWVYpoNz4iCxTIM5Cuf' + #13#10 +
        'ReYNnyicsbkqWletNw+vHX/bvZ8=' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts027 =
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Common Name: DigiCert Assured ID Root CA' + #13#10 +
        '# Subject Organisation: DigiCert Inc' + #13#10 +
        '# Subject Organisation Unit: www.digicert.com' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 10/11/2031' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIDtzCCAp+gAwIBAgIQDOfg5RfYRv6P5WD8G/AwOTANBgkqhkiG9w0BAQUFADBl' + #13#10 +
        'MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3' + #13#10 +
        'd3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJv' + #13#10 +
        'b3QgQ0EwHhcNMDYxMTEwMDAwMDAwWhcNMzExMTEwMDAwMDAwWjBlMQswCQYDVQQG' + #13#10 +
        'EwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNl' + #13#10 +
        'cnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwggEi' + #13#10 +
        'MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCtDhXO5EOAXLGH87dg+XESpa7c' + #13#10 +
        'JpSIqvTO9SA5KFhgDPiA2qkVlTJhPLWxKISKityfCgyDF3qPkKyK53lTXDGEKvYP' + #13#10 +
        'mDI2dsze3Tyoou9q+yHyUmHfnyDXH+Kx2f4YZNISW1/5WBg1vEfNoTb5a3/UsDg+' + #13#10 +
        'wRvDjDPZ2C8Y/igPs6eD1sNuRMBhNZYW/lmci3Zt1/GiSw0r/wty2p5g0I6QNcZ4' + #13#10 +
        'VYcgoc/lbQrISXwxmDNsIumH0DJaoroTghHtORedmTpyoeb6pNnVFzF1roV9Iq4/' + #13#10 +
        'AUaG9ih5yLHa5FcXxH4cDrC0kqZWs72yl+2qp/C3xag/lRbQ/6GW6whfGHdPAgMB' + #13#10 +
        'AAGjYzBhMA4GA1UdDwEB/wQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQW' + #13#10 +
        'BBRF66Kv9JLLgjEtUYunpyGd823IDzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYun' + #13#10 +
        'pyGd823IDzANBgkqhkiG9w0BAQUFAAOCAQEAog683+Lt8ONyc3pklL/3cmbYMuRC' + #13#10 +
        'dWKuh+vy1dneVrOfzM4UKLkNl2BcEkxY5NM9g0lFWJc1aRqoR+pWxnmrEthngYTf' + #13#10 +
        'fwk8lOa4JiwgvT2zKIn3X/8i4peEH+ll74fg38FnSbNd67IJKusm7Xi+fT8r87cm' + #13#10 +
        'NW1fiQG2SVufAQWbqz0lwcy2f8Lxb4bG+mRo64EtlOtCt/qMHt1i8b5QZ7dsvfPx' + #13#10 +
        'H2sMNgcWfzd8qVttevESRmCD1ycEvkvOl77DZypoEd+A5wwzZr8TDRRu838fYxAe' + #13#10 +
        '+o0bJW1sj6W3YQGx0qMmoRBxna3iw/nDmVG3KwcIzi7mULKn+gpFL6Lw8g==' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts029 =
        '# Subject Common Name: AddTrust External CA Root' + #13#10 +
        '# Subject Organisation: AddTrust AB' + #13#10 +
        '# Subject Organisation Unit: AddTrust External TTP Network' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 30/05/2020' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIENjCCAx6gAwIBAgIBATANBgkqhkiG9w0BAQUFADBvMQswCQYDVQQGEwJTRTEU' + #13#10 +
        'MBIGA1UEChMLQWRkVHJ1c3QgQUIxJjAkBgNVBAsTHUFkZFRydXN0IEV4dGVybmFs' + #13#10 +
        'IFRUUCBOZXR3b3JrMSIwIAYDVQQDExlBZGRUcnVzdCBFeHRlcm5hbCBDQSBSb290' + #13#10 +
        'MB4XDTAwMDUzMDEwNDgzOFoXDTIwMDUzMDEwNDgzOFowbzELMAkGA1UEBhMCU0Ux' + #13#10 +
        'FDASBgNVBAoTC0FkZFRydXN0IEFCMSYwJAYDVQQLEx1BZGRUcnVzdCBFeHRlcm5h' + #13#10 +
        'bCBUVFAgTmV0d29yazEiMCAGA1UEAxMZQWRkVHJ1c3QgRXh0ZXJuYWwgQ0EgUm9v' + #13#10 +
        'dDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALf3GjPm8gAELTngTlvt' + #13#10 +
        'H7xsD821+iO2zt6bETOXpClMfZOfvUq8k+0DGuOPz+VtUFrWlymUWoCwSXrbLpX9' + #13#10 +
        'uMq/NzgtHj6RQa1wVsfwTz/oMp50ysiQVOnGXw94nZpAPA6sYapeFI+eh6FqUNzX' + #13#10 +
        'mk6vBbOmcZSccbNQYArHE504B4YCqOmoaSYYkKtMsE8jqzpPhNjfzp/haW+710LX' + #13#10 +
        'a0Tkx63ubUFfclpxCDezeWWkWaCUN/cALw3CknLa0Dhy2xSoRcRdKn23tNbE7qzN' + #13#10 +
        'E0S3ySvdQwAl+mG5aWpYIxG3pzOPVnVZ9c0p10a3CitlttNCbxWyuHv77+ldU9U0' + #13#10 +
        'WicCAwEAAaOB3DCB2TAdBgNVHQ4EFgQUrb2YejS0Jvf6xCZU7wO94CTLVBowCwYD' + #13#10 +
        'VR0PBAQDAgEGMA8GA1UdEwEB/wQFMAMBAf8wgZkGA1UdIwSBkTCBjoAUrb2YejS0' + #13#10 +
        'Jvf6xCZU7wO94CTLVBqhc6RxMG8xCzAJBgNVBAYTAlNFMRQwEgYDVQQKEwtBZGRU' + #13#10 +
        'cnVzdCBBQjEmMCQGA1UECxMdQWRkVHJ1c3QgRXh0ZXJuYWwgVFRQIE5ldHdvcmsx' + #13#10 +
        'IjAgBgNVBAMTGUFkZFRydXN0IEV4dGVybmFsIENBIFJvb3SCAQEwDQYJKoZIhvcN' + #13#10 +
        'AQEFBQADggEBALCb4IUlwtYj4g+WBpKdQZic2YR5gdkeWxQHIzZlj7DYd7usQWxH' + #13#10 +
        'YINRsPkyPef89iYTx4AWpb9a/IfPeHmJIZriTAcKhjW88t5RxNKWt9x+Tu5w/Rw5' + #13#10 +
        '6wwCURQtjr0W4MHfRnXnJK3s9EK0hZNwEGe6nQY1ShjTK3rMUUKhemPR5ruhxSvC' + #13#10 +
        'Nr4TDea9Y355e6cJDUCrat2PisP29owaQgVR1EX1n6diIWgVIEM8med8vSTYqZEX' + #13#10 +
        'c4g/VhsxOBi0cQ+azcgOno4uG+GMmIPLHzHxREzGBHNJdmAPx/i9F4BrLunMTA5a' + #13#10 +
        'mnkPIAou1Z5jJh5VkpTYghdae9C8x49OhgQ=' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts030 =
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Common Name: ISRG Root X1' + #13#10 +
        '# Subject Organisation: Internet Security Research Group' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 04/06/2035' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIFazCCA1OgAwIBAgIRAIIQz7DSQONZRGPgu2OCiwAwDQYJKoZIhvcNAQELBQAw' + #13#10 +
        'TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh' + #13#10 +
        'cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMTUwNjA0MTEwNDM4' + #13#10 +
        'WhcNMzUwNjA0MTEwNDM4WjBPMQswCQYDVQQGEwJVUzEpMCcGA1UEChMgSW50ZXJu' + #13#10 +
        'ZXQgU2VjdXJpdHkgUmVzZWFyY2ggR3JvdXAxFTATBgNVBAMTDElTUkcgUm9vdCBY' + #13#10 +
        'MTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAK3oJHP0FDfzm54rVygc' + #13#10 +
        'h77ct984kIxuPOZXoHj3dcKi/vVqbvYATyjb3miGbESTtrFj/RQSa78f0uoxmyF+' + #13#10 +
        '0TM8ukj13Xnfs7j/EvEhmkvBioZxaUpmZmyPfjxwv60pIgbz5MDmgK7iS4+3mX6U' + #13#10 +
        'A5/TR5d8mUgjU+g4rk8Kb4Mu0UlXjIB0ttov0DiNewNwIRt18jA8+o+u3dpjq+sW' + #13#10 +
        'T8KOEUt+zwvo/7V3LvSye0rgTBIlDHCNAymg4VMk7BPZ7hm/ELNKjD+Jo2FR3qyH' + #13#10 +
        'B5T0Y3HsLuJvW5iB4YlcNHlsdu87kGJ55tukmi8mxdAQ4Q7e2RCOFvu396j3x+UC' + #13#10 +
        'B5iPNgiV5+I3lg02dZ77DnKxHZu8A/lJBdiB3QW0KtZB6awBdpUKD9jf1b0SHzUv' + #13#10 +
        'KBds0pjBqAlkd25HN7rOrFleaJ1/ctaJxQZBKT5ZPt0m9STJEadao0xAH0ahmbWn' + #13#10 +
        'OlFuhjuefXKnEgV4We0+UXgVCwOPjdAvBbI+e0ocS3MFEvzG6uBQE3xDk3SzynTn' + #13#10 +
        'jh8BCNAw1FtxNrQHusEwMFxIt4I7mKZ9YIqioymCzLq9gwQbooMDQaHWBfEbwrbw' + #13#10 +
        'qHyGO0aoSCqI3Haadr8faqU9GY/rOPNk3sgrDQoo//fb4hVC1CLQJ13hef4Y53CI' + #13#10 +
        'rU7m2Ys6xt0nUW7/vGT1M0NPAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBBjAPBgNV' + #13#10 +
        'HRMBAf8EBTADAQH/MB0GA1UdDgQWBBR5tFnme7bl5AFzgAiIyBpY9umbbjANBgkq' + #13#10 +
        'hkiG9w0BAQsFAAOCAgEAVR9YqbyyqFDQDLHYGmkgJykIrGF1XIpu+ILlaS/V9lZL' + #13#10 +
        'ubhzEFnTIZd+50xx+7LSYK05qAvqFyFWhfFQDlnrzuBZ6brJFe+GnY+EgPbk6ZGQ' + #13#10 +
        '3BebYhtF8GaV0nxvwuo77x/Py9auJ/GpsMiu/X1+mvoiBOv/2X/qkSsisRcOj/KK' + #13#10 +
        'NFtY2PwByVS5uCbMiogziUwthDyC3+6WVwW6LLv3xLfHTjuCvjHIInNzktHCgKQ5' + #13#10 +
        'ORAzI4JMPJ+GslWYHb4phowim57iaztXOoJwTdwJx4nLCgdNbOhdjsnvzqvHu7Ur' + #13#10 +
        'TkXWStAmzOVyyghqpZXjFaH3pO3JLF+l+/+sKAIuvtd7u+Nxe5AW0wdeRlN8NwdC' + #13#10 +
        'jNPElpzVmbUq4JUagEiuTDkHzsxHpFKVK7q4+63SM1N95R1NbdWhscdCb+ZAJzVc' + #13#10 +
        'oyi3B43njTOQ5yOf+1CceWxG1bQVs5ZufpsMljq4Ui0/1lvh+wjChP4kqKOJ2qxq' + #13#10 +
        '4RgqsahDYVvTH9w7jXbyLeiNdd8XM2w9U/t7y0Ff/9yi0GE44Za4rF2LN9d11TPA' + #13#10 +
        'mRGunUHBcnWEvgJBQl9nJEiU0Zsnvgc/ubhPgXRR4Xq37Z0j4r7g1SgEEzwxA57d' + #13#10 +
        'emyPxgcYxn/eR44/KJ4EBs+lVDR3veyJm+kXQ99b21/+jh5Xos1AnX5iItreGCc=' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts031 =                                                           { V8.52 }
        '# X509 SSL Certificate' + #13#10 +
        'Issued to (CN): DigiCert Global Root G2, (O): DigiCert Inc' + #13#10 +
        'Issuer: Self Signed' + #13#10 +
        'Serial Number: 033af1e6a711a9a0bb2864b11d09fae5' + #13#10 +
        'Fingerprint (sha1): df3c24f9bfd666761b268073fe06d1cc8d4f82a4' + #13#10 +
        'Expires: 15/01/2038, Signature: sha256WithRSAEncryption' + #13#10 +
        'Public Key: RSA Key Encryption 2048 bits, 112 security bits' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIDjjCCAnagAwIBAgIQAzrx5qcRqaC7KGSxHQn65TANBgkqhkiG9w0BAQsFADBh' + #13#10 +
        'MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3' + #13#10 +
        'd3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBH' + #13#10 +
        'MjAeFw0xMzA4MDExMjAwMDBaFw0zODAxMTUxMjAwMDBaMGExCzAJBgNVBAYTAlVT' + #13#10 +
        'MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j' + #13#10 +
        'b20xIDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290IEcyMIIBIjANBgkqhkiG' + #13#10 +
        '9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuzfNNNx7a8myaJCtSnX/RrohCgiN9RlUyfuI' + #13#10 +
        '2/Ou8jqJkTx65qsGGmvPrC3oXgkkRLpimn7Wo6h+4FR1IAWsULecYxpsMNzaHxmx' + #13#10 +
        '1x7e/dfgy5SDN67sH0NO3Xss0r0upS/kqbitOtSZpLYl6ZtrAGCSYP9PIUkY92eQ' + #13#10 +
        'q2EGnI/yuum06ZIya7XzV+hdG82MHauVBJVJ8zUtluNJbd134/tJS7SsVQepj5Wz' + #13#10 +
        'tCO7TG1F8PapspUwtP1MVYwnSlcUfIKdzXOS0xZKBgyMUNGPHgm+F6HmIcr9g+UQ' + #13#10 +
        'vIOlCsRnKPZzFBQ9RnbDhxSJITRNrw9FDKZJobq7nMWxM4MphQIDAQABo0IwQDAP' + #13#10 +
        'BgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQEAwIBhjAdBgNVHQ4EFgQUTiJUIBiV' + #13#10 +
        '5uNu5g/6+rkS7QYXjzkwDQYJKoZIhvcNAQELBQADggEBAGBnKJRvDkhj6zHd6mcY' + #13#10 +
        '1Yl9PMWLSn/pvtsrF9+wX3N3KjITOYFnQoQj8kVnNeyIv/iPsGEMNKSuIEyExtv4' + #13#10 +
        'NeF22d+mQrvHRAiGfzZ0JFrabA0UWTW98kndth/Jsw1HKj2ZL7tcu7XUIOGZX1NG' + #13#10 +
        'Fdtom/DzMNU+MeKNhJ7jitralj41E6Vf8PlwUHBHQRFXGU7Aj64GxJUTFy8bJZ91' + #13#10 +
        '8rGOmaFvE7FBcf6IKshPECBV1/MUReXgRPTqh5Uykw7+U0b6LJ3/iyK5S9kJRaTe' + #13#10 +
        'pLiaWN0bfVKfjllDiIGknibVb63dDcY3fe0Dkhvld1927jyNxF1WW6LZZm6zNTfl' + #13#10 +
        'MrY=' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts032 =                                                               { V8.52 }
        '# X509 SSL Certificate' + #13#10 +
        'Issued to (CN): DigiCert Global Root G3, (O): DigiCert Inc' + #13#10 +
        'Issuer: Self Signed' + #13#10 +
        'Serial Number: 055556bcf25ea43535c3a40fd5ab4572' + #13#10 +
        'Fingerprint (sha1): 7e04de896a3e666d00e687d33ffad93be83d349e' + #13#10 +
        'Expires: 15/01/2038, Signature: ecdsa-with-SHA384' + #13#10 +
        'Public Key: ECDSA Key Encryption secp384r1 384 bits, 192 security bits' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIICPzCCAcWgAwIBAgIQBVVWvPJepDU1w6QP1atFcjAKBggqhkjOPQQDAzBhMQsw' + #13#10 +
        'CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cu' + #13#10 +
        'ZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBHMzAe' + #13#10 +
        'Fw0xMzA4MDExMjAwMDBaFw0zODAxMTUxMjAwMDBaMGExCzAJBgNVBAYTAlVTMRUw' + #13#10 +
        'EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x' + #13#10 +
        'IDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290IEczMHYwEAYHKoZIzj0CAQYF' + #13#10 +
        'K4EEACIDYgAE3afZu4q4C/sLfyHS8L6+c/MzXRq8NOrexpu80JX28MzQC7phW1FG' + #13#10 +
        'fp4tn+6OYwwX7Adw9c+ELkCDnOg/QW07rdOkFFk2eJ0DQ+4QE2xy3q6Ip6FrtUPO' + #13#10 +
        'Z9wj/wMco+I+o0IwQDAPBgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQEAwIBhjAd' + #13#10 +
        'BgNVHQ4EFgQUs9tIpPmhxdiuNkHMEWNpYim8S8YwCgYIKoZIzj0EAwMDaAAwZQIx' + #13#10 +
        'AK288mw/EkrRLTnDCgmXc/SINoyIJ7vmiI1Qhadj+Z4y3maTD/HMsQmP3Wyr+mt/' + #13#10 +
        'oAIwOWZbwmSNuJ5Q3KjVSaLtx9zRSX8XAbjIho9OjIgrqJqpisXRAL34VOKa5Vt8' + #13#10 +
        'sycX' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts033 =                                                               { V8.53 }
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Common Name: GlobalSign' + #13#10 +
        '# Subject Organisation: GlobalSign' + #13#10 +
        '# Subject Organisation Unit: GlobalSign Root CA - R2' + #13#10 +
        '# GlobalSign Root R2 SHA1 • RSA • 2048' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 15/12/2021' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIDujCCAqKgAwIBAgILBAAAAAABD4Ym5g0wDQYJKoZIhvcNAQEFBQAwTDEgMB4G' + #13#10 +
        'A1UECxMXR2xvYmFsU2lnbiBSb290IENBIC0gUjIxEzARBgNVBAoTCkdsb2JhbFNp' + #13#10 +
        'Z24xEzARBgNVBAMTCkdsb2JhbFNpZ24wHhcNMDYxMjE1MDgwMDAwWhcNMjExMjE1' + #13#10 +
        'MDgwMDAwWjBMMSAwHgYDVQQLExdHbG9iYWxTaWduIFJvb3QgQ0EgLSBSMjETMBEG' + #13#10 +
        'A1UEChMKR2xvYmFsU2lnbjETMBEGA1UEAxMKR2xvYmFsU2lnbjCCASIwDQYJKoZI' + #13#10 +
        'hvcNAQEBBQADggEPADCCAQoCggEBAKbPJA6+Lm8omUVCxKs+IVSbC9N/hHD6ErPL' + #13#10 +
        'v4dfxn+G07IwXNb9rfF73OX4YJYJkhD10FPe+3t+c4isUoh7SqbKSaZeqKeMWhG8' + #13#10 +
        'eoLrvozps6yWJQeXSpkqBy+0Hne/ig+1AnwblrjFuTosvNYSuetZfeLQBoZfXklq' + #13#10 +
        'tTleiDTsvHgMCJiEbKjNS7SgfQx5TfC4LcshytVsW33hoCmEofnTlEnLJGKRILzd' + #13#10 +
        'C9XZzPnqJworc5HGnRusyMvo4KD0L5CLTfuwNhv2GXqF4G3yYROIXJ/gkwpRl4pa' + #13#10 +
        'zq+r1feqCapgvdzZX99yqWATXgAByUr6P6TqBwMhAo6CygPCm48CAwEAAaOBnDCB' + #13#10 +
        'mTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUm+IH' + #13#10 +
        'V2ccHsBqBt5ZtJot39wZhi4wNgYDVR0fBC8wLTAroCmgJ4YlaHR0cDovL2NybC5n' + #13#10 +
        'bG9iYWxzaWduLm5ldC9yb290LXIyLmNybDAfBgNVHSMEGDAWgBSb4gdXZxwewGoG' + #13#10 +
        '3lm0mi3f3BmGLjANBgkqhkiG9w0BAQUFAAOCAQEAmYFThxxol4aR7OBKuEQLq4Gs' + #13#10 +
        'J0/WwbgcQ3izDJr86iw8bmEbTUsp9Z8FHSbBuOmDAGJFtqkIk7mpM0sYmsL4h4hO' + #13#10 +
        '291xNBrBVNpGP+DTKqttVCL1OmLNIG+6KYnX3ZHu01yiPqFbQfXf5WRDLenVOavS' + #13#10 +
        'ot+3i9DAgBkcRcAtjOj4LaR0VknFBbVPFd5uRHg5h6h+u/N5GJG79G+dwfCMNYxd' + #13#10 +
        'AfvDbbnvRG15RjF+Cv6pgsH/76tuIMRQyV+dTZsXjAzlAcmgQWpzU/qlULRuJQ/7' + #13#10 +
        'TBj0/VLZjmmx6BEP3ojY+x1J96relc8geMJgEtslQIxq/H5COEBkEveegeGTLg==' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts034 =                                                               { V8.53 }
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Common Name: GlobalSign' + #13#10 +
        '# Subject Organisation: GlobalSign' + #13#10 +
        '# Subject Organisation Unit: GlobalSign ECC Root CA - R5' + #13#10 +
        '# GlobalSign ECC Root R5 SHA384 • ECC • 384' + #13#10 +
        '# Issuer: Self Signed' + #13#10 +
        '# Expires: 19/01/2038' + #13#10 +
        '' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIICHjCCAaSgAwIBAgIRYFlJ4CYuu1X5CneKcflK2GwwCgYIKoZIzj0EAwMwUDEk' + #13#10 +
        'MCIGA1UECxMbR2xvYmFsU2lnbiBFQ0MgUm9vdCBDQSAtIFI1MRMwEQYDVQQKEwpH' + #13#10 +
        'bG9iYWxTaWduMRMwEQYDVQQDEwpHbG9iYWxTaWduMB4XDTEyMTExMzAwMDAwMFoX' + #13#10 +
        'DTM4MDExOTAzMTQwN1owUDEkMCIGA1UECxMbR2xvYmFsU2lnbiBFQ0MgUm9vdCBD' + #13#10 +
        'QSAtIFI1MRMwEQYDVQQKEwpHbG9iYWxTaWduMRMwEQYDVQQDEwpHbG9iYWxTaWdu' + #13#10 +
        'MHYwEAYHKoZIzj0CAQYFK4EEACIDYgAER0UOlvt9Xb/pOdEh+J8LttV7HpI6SFkc' + #13#10 +
        '8GIxLcB6KP4ap1yztsyX50XUWPrRd21DosCHZTQKH3rd6zwzocWdTaRvQZU4f8ke' + #13#10 +
        'hOvRnkmSh5SHDDqFSmafnVmTTZdhBoZKo0IwQDAOBgNVHQ8BAf8EBAMCAQYwDwYD' + #13#10 +
        'VR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUPeYpSJvqB8ohREom3m7e0oPQn1kwCgYI' + #13#10 +
        'KoZIzj0EAwMDaAAwZQIxAOVpEslu28YxuglB4Zf4+/2a4n0Sye18ZNPLBSWLVtmg' + #13#10 +
        '515dTguDnFt2KaAJJiFqYgIwcdK1j1zqO+F4CYWodZI7yFz9SO8NdCKoCOJuxUnO' + #13#10 +
        'xwy8p2Fp8fc74SrL+SvzZpA3' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts035 =                                                               { V8.53 }
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Common Name: DST Root CA X3' + #13#10 +
        '# Subject Organisation: Digital Signature Trust Co.' + #13#10 +
        '#Issuer: Self Signed' + #13#10 +
        '# Expires: 30/09/2021' + #13#10 +
        '' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIDSjCCAjKgAwIBAgIQRK+wgNajJ7qJMDmGLvhAazANBgkqhkiG9w0BAQUFADA/' + #13#10 +
        'MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT' + #13#10 +
        'DkRTVCBSb290IENBIFgzMB4XDTAwMDkzMDIxMTIxOVoXDTIxMDkzMDE0MDExNVow' + #13#10 +
        'PzEkMCIGA1UEChMbRGlnaXRhbCBTaWduYXR1cmUgVHJ1c3QgQ28uMRcwFQYDVQQD' + #13#10 +
        'Ew5EU1QgUm9vdCBDQSBYMzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB' + #13#10 +
        'AN+v6ZdQCINXtMxiZfaQguzH0yxrMMpb7NnDfcdAwRgUi+DoM3ZJKuM/IUmTrE4O' + #13#10 +
        'rz5Iy2Xu/NMhD2XSKtkyj4zl93ewEnu1lcCJo6m67XMuegwGMoOifooUMM0RoOEq' + #13#10 +
        'OLl5CjH9UL2AZd+3UWODyOKIYepLYYHsUmu5ouJLGiifSKOeDNoJjj4XLh7dIN9b' + #13#10 +
        'xiqKqy69cK3FCxolkHRyxXtqqzTWMIn/5WgTe1QLyNau7Fqckh49ZLOMxt+/yUFw' + #13#10 +
        '7BZy1SbsOFU5Q9D8/RhcQPGX69Wam40dutolucbY38EVAjqr2m7xPi71XAicPNaD' + #13#10 +
        'aeQQmxkqtilX4+U9m5/wAl0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNV' + #13#10 +
        'HQ8BAf8EBAMCAQYwHQYDVR0OBBYEFMSnsaR7LHH62+FLkHX/xBVghYkQMA0GCSqG' + #13#10 +
        'SIb3DQEBBQUAA4IBAQCjGiybFwBcqR7uKGY3Or+Dxz9LwwmglSBd49lZRNI+DT69' + #13#10 +
        'ikugdB/OEIKcdBodfpga3csTS7MgROSR6cz8faXbauX+5v3gTt23ADq1cEmv8uXr' + #13#10 +
        'AvHRAosZy5Q6XkjEGB5YGV8eAlrwDPGxrancWYaLbumR9YbK+rlmM6pZW87ipxZz' + #13#10 +
        'R8srzJmwN0jP41ZL9c8PDHIyh8bwRLtTcm1D9SZImlJnt1ir/md2cXjbDaJWFBM5' + #13#10 +
        'JDGFoqgCWjBH4d1QB7wCCZAA62RjYJsWvIjJEubSfZGL+T0yjWW06XyxV3bqxbYo' + #13#10 +
        'Ob8VZRzI9neWagqNdwvYkQsEjgfbKbYK7p2CNTUQ' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts036 =                                                               { V8.57 }
        '# X509 SSL Certificate' + #13#10 +
        '# Subject Common Name: COMODO ECC Certification Authority' + #13#10 +
        '# Subject Organisation: COMODO CA Limited' + #13#10 +
        '#Issuer: Self Signed' + #13#10 +
        '# Expires: 18/01/2038' + #13#10 +
        '' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIICiTCCAg+gAwIBAgIQH0evqmIAcFBUTAGem2OZKjAKBggqhkjOPQQDAzCBhTEL' + #13#10 +
        'MAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UE' + #13#10 +
        'BxMHU2FsZm9yZDEaMBgGA1UEChMRQ09NT0RPIENBIExpbWl0ZWQxKzApBgNVBAMT' + #13#10 +
        'IkNPTU9ETyBFQ0MgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMDgwMzA2MDAw' + #13#10 +
        'MDAwWhcNMzgwMTE4MjM1OTU5WjCBhTELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdy' + #13#10 +
        'ZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEaMBgGA1UEChMRQ09N' + #13#10 +
        'T0RPIENBIExpbWl0ZWQxKzApBgNVBAMTIkNPTU9ETyBFQ0MgQ2VydGlmaWNhdGlv' + #13#10 +
        'biBBdXRob3JpdHkwdjAQBgcqhkjOPQIBBgUrgQQAIgNiAAQDR3svdcmCFYX7deSR' + #13#10 +
        'FtSrYpn1PlILBs5BAH+X4QokPB0BBO490o0JlwzgdeT6+3eKKvUDYEs2ixYjFq0J' + #13#10 +
        'cfRK9ChQtP6IHG4/bC8vCVlbpVsLM5niwz2J+Wos77LTBumjQjBAMB0GA1UdDgQW' + #13#10 +
        'BBR1cacZSBm8nZ3qQUfflMRId5nTeTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/' + #13#10 +
        'BAUwAwEB/zAKBggqhkjOPQQDAwNoADBlAjEA7wNbeqy3eApyt4jf/7VGFAkK+qDm' + #13#10 +
        'fQjGGoe9GKhzvSbKYAydzpmfz1wPMOG+FDHqAjAU9JM8SaczepBGR7NjfRObTrdv' + #13#10 +
        'GDeAU/7dIOA1mjbRxwG55tzd8/8dLDoWV9mSOdY=' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts037 =                                                               { V8.63 }
        'Issued to (CN): Starfield Services Root Certificate Authority - G2, (O): Starfield Technologies, Inc.' + #13#10 +
        'Issuer: Self Signed' + #13#10 +
        'Expires: 31/12/2037 23:59:59, Signature: sha256WithRSAEncryption' + #13#10 +
        'Valid From: 01/09/2009, Serial Number: 00' + #13#10 +
        'Fingerprint (sha256): 568d6905a2c88708a4b3025190edcfedb1974a606a13c6e5290fcb2ae63edab5' + #13#10 +
        'Public Key: RSA Key Encryption 2048 bits, 112 security bits' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIID7zCCAtegAwIBAgIBADANBgkqhkiG9w0BAQsFADCBmDELMAkGA1UEBhMCVVMx' + #13#10 +
        'EDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxJTAjBgNVBAoT' + #13#10 +
        'HFN0YXJmaWVsZCBUZWNobm9sb2dpZXMsIEluYy4xOzA5BgNVBAMTMlN0YXJmaWVs' + #13#10 +
        'ZCBTZXJ2aWNlcyBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAtIEcyMB4XDTA5' + #13#10 +
        'MDkwMTAwMDAwMFoXDTM3MTIzMTIzNTk1OVowgZgxCzAJBgNVBAYTAlVTMRAwDgYD' + #13#10 +
        'VQQIEwdBcml6b25hMRMwEQYDVQQHEwpTY290dHNkYWxlMSUwIwYDVQQKExxTdGFy' + #13#10 +
        'ZmllbGQgVGVjaG5vbG9naWVzLCBJbmMuMTswOQYDVQQDEzJTdGFyZmllbGQgU2Vy' + #13#10 +
        'dmljZXMgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgLSBHMjCCASIwDQYJKoZI' + #13#10 +
        'hvcNAQEBBQADggEPADCCAQoCggEBANUMOsQq+U7i9b4Zl1+OiFOxHz/Lz58gE20p' + #13#10 +
        'OsgPfTz3a3Y4Y9k2YKibXlwAgLIvWX/2h/klQ4bnaRtSmpDhcePYLQ1Ob/bISdm2' + #13#10 +
        '8xpWriu2dBTrz/sm4xq6HZYuajtYlIlHVv8loJNwU4PahHQUw2eeBGg6345AWh1K' + #13#10 +
        'Ts9DkTvnVtYAcMtS7nt9rjrnvDH5RfbCYM8TWQIrgMw0R9+53pBlbQLPLJGmpufe' + #13#10 +
        'hRhJfGZOozptqbXuNC66DQO4M99H67FrjSXZm86B0UVGMpZwh94CDklDhbZsc7tk' + #13#10 +
        '6mFBrMnUVN+HL8cisibMn1lUaJ/8viovxFUcdUBgF4UCVTmLfwUCAwEAAaNCMEAw' + #13#10 +
        'DwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAQYwHQYDVR0OBBYEFJxfAN+q' + #13#10 +
        'AdcwKziIorhtSpzyEZGDMA0GCSqGSIb3DQEBCwUAA4IBAQBLNqaEd2ndOxmfZyMI' + #13#10 +
        'bw5hyf2E3F/YNoHN2BtBLZ9g3ccaaNnRbobhiCPPE95Dz+I0swSdHynVv/heyNXB' + #13#10 +
        've6SbzJ08pGCL72CQnqtKrcgfU28elUSwhXqvfdqlS5sdJ/PHLTyxQGjhdByPq1z' + #13#10 +
        'qwubdQxtRbeOlKyWN7Wg0I8VRw7j6IPdj/3vQQF3zCepYoUz8jcI73HPdwbeyBkd' + #13#10 +
        'iEDPfUYd/x7H4c7/I9vG+o1VTqkC50cRRj70/b17KSa7qWFiNyi2LSr2EIZkyXCn' + #13#10 +
        '0q23KXB56jzaYyWf/Wi3MOxw+3WKt21gZ7IeyLnp2KhvAotnDU0mV3HaIPzBSlCN' + #13#10 +
        'sSi6' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts038 =                                                               { V8.63 }
        'Issued to (CN): Amazon Root CA 1, (O): Amazon' + #13#10 +
        'Issuer: Self Signed' + #13#10 +
        'Expires: 17/01/2038, Signature: sha256WithRSAEncryption' + #13#10 +
        'Valid From: 26/05/2015, Serial Number: 066c9fcf99bf8c0a39e2f0788a43e696365bca' + #13#10 +
        'Fingerprint (sha256): 8ecde6884f3d87b1125ba31ac3fcb13d7016de7f57cc904fe1cb97c6ae98196e' + #13#10 +
        'Public Key: RSA Key Encryption 2048 bits, 112 security bits' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIDQTCCAimgAwIBAgITBmyfz5m/jAo54vB4ikPmljZbyjANBgkqhkiG9w0BAQsF' + #13#10 +
        'ADA5MQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRkwFwYDVQQDExBBbWF6' + #13#10 +
        'b24gUm9vdCBDQSAxMB4XDTE1MDUyNjAwMDAwMFoXDTM4MDExNzAwMDAwMFowOTEL' + #13#10 +
        'MAkGA1UEBhMCVVMxDzANBgNVBAoTBkFtYXpvbjEZMBcGA1UEAxMQQW1hem9uIFJv' + #13#10 +
        'b3QgQ0EgMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALJ4gHHKeNXj' + #13#10 +
        'ca9HgFB0fW7Y14h29Jlo91ghYPl0hAEvrAIthtOgQ3pOsqTQNroBvo3bSMgHFzZM' + #13#10 +
        '9O6II8c+6zf1tRn4SWiw3te5djgdYZ6k/oI2peVKVuRF4fn9tBb6dNqcmzU5L/qw' + #13#10 +
        'IFAGbHrQgLKm+a/sRxmPUDgH3KKHOVj4utWp+UhnMJbulHheb4mjUcAwhmahRWa6' + #13#10 +
        'VOujw5H5SNz/0egwLX0tdHA114gk957EWW67c4cX8jJGKLhD+rcdqsq08p8kDi1L' + #13#10 +
        '93FcXmn/6pUCyziKrlA4b9v7LWIbxcceVOF34GfID5yHI9Y/QCB/IIDEgEw+OyQm' + #13#10 +
        'jgSubJrIqg0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMC' + #13#10 +
        'AYYwHQYDVR0OBBYEFIQYzIU07LwMlJQuCFmcx7IQTgoIMA0GCSqGSIb3DQEBCwUA' + #13#10 +
        'A4IBAQCY8jdaQZChGsV2USggNiMOruYou6r4lK5IpDB/G/wkjUu0yKGX9rbxenDI' + #13#10 +
        'U5PMCCjjmCXPI6T53iHTfIUJrU6adTrCC2qJeHZERxhlbI1Bjjt/msv0tadQ1wUs' + #13#10 +
        'N+gDS63pYaACbvXy8MWy7Vu33PqUXHeeE6V/Uq2V8viTO96LXFvKWlJbYK8U90vv' + #13#10 +
        'o/ufQJVtMVT8QtPHRh8jrdkPSHCa2XV4cdFyQzR1bldZwgJcJmApzyMZFo6IQ6XU' + #13#10 +
        '5MsI+yMRQ+hDKXJioaldXgjUkK642M4UwtBV8ob2xJNDd2ZhwLnoQdeXeGADbkpy' + #13#10 +
        'rqXRfboQnoZsG4q5WTP468SQvvG5' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts039 =                                                               { V8.63 }
        'Issued to (CN): Amazon Root CA 2, (O): Amazon' + #13#10 +
        'Issuer: Self Signed' + #13#10 +
        'Expires: 26/05/2040, Signature: sha384WithRSAEncryption' + #13#10 +
        'Valid From: 26/05/2015, Serial Number: 066c9fd29635869f0a0fe58678f85b26bb8a37' + #13#10 +
        'Fingerprint (sha256): 1ba5b2aa8c65401a82960118f80bec4f62304d83cec4713a19c39c011ea46db4' + #13#10 +
        'Public Key: RSA Key Encryption 4096 bits, 128 security bits' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIFQTCCAymgAwIBAgITBmyf0pY1hp8KD+WGePhbJruKNzANBgkqhkiG9w0BAQwF' + #13#10 +
        'ADA5MQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRkwFwYDVQQDExBBbWF6' + #13#10 +
        'b24gUm9vdCBDQSAyMB4XDTE1MDUyNjAwMDAwMFoXDTQwMDUyNjAwMDAwMFowOTEL' + #13#10 +
        'MAkGA1UEBhMCVVMxDzANBgNVBAoTBkFtYXpvbjEZMBcGA1UEAxMQQW1hem9uIFJv' + #13#10 +
        'b3QgQ0EgMjCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAK2Wny2cSkxK' + #13#10 +
        'gXlRmeyKy2tgURO8TW0G/LAIjd0ZEGrHJgw12MBvIITplLGbhQPDW9tK6Mj4kHbZ' + #13#10 +
        'W0/jTOgGNk3Mmqw9DJArktQGGWCsN0R5hYGCrVo34A3MnaZMUnbqQ523BNFQ9lXg' + #13#10 +
        '1dKmSYXpN+nKfq5clU1Imj+uIFptiJXZNLhSGkOQsL9sBbm2eLfq0OQ6PBJTYv9K' + #13#10 +
        '8nu+NQWpEjTj82R0Yiw9AElaKP4yRLuH3WUnAnE72kr3H9rN9yFVkE8P7K6C4Z9r' + #13#10 +
        '2UXTu/Bfh+08LDmG2j/e7HJV63mjrdvdfLC6HM783k81ds8P+HgfajZRRidhW+me' + #13#10 +
        'z/CiVX18JYpvL7TFz4QuK/0NURBs+18bvBt+xa47mAExkv8LV/SasrlX6avvDXbR' + #13#10 +
        '8O70zoan4G7ptGmh32n2M8ZpLpcTnqWHsFcQgTfJU7O7f/aS0ZzQGPSSbtqDT6Zj' + #13#10 +
        'mUyl+17vIWR6IF9sZIUVyzfpYgwLKhbcAS4y2j5L9Z469hdAlO+ekQiG+r5jqFoz' + #13#10 +
        '7Mt0Q5X5bGlSNscpb/xVA1wf+5+9R+vnSUeVC06JIglJ4PVhHvG/LopyboBZ/1c6' + #13#10 +
        '+XUyo05f7O0oYtlNc/LMgRdg7c3r3NunysV+Ar3yVAhU/bQtCSwXVEqY0VThUWcI' + #13#10 +
        '0u1ufm8/0i2BWSlmy5A5lREedCf+3euvAgMBAAGjQjBAMA8GA1UdEwEB/wQFMAMB' + #13#10 +
        'Af8wDgYDVR0PAQH/BAQDAgGGMB0GA1UdDgQWBBSwDPBMMPQFWAJI/TPlUq9LhONm' + #13#10 +
        'UjANBgkqhkiG9w0BAQwFAAOCAgEAqqiAjw54o+Ci1M3m9Zh6O+oAA7CXDpO8Wqj2' + #13#10 +
        'LIxyh6mx/H9z/WNxeKWHWc8w4Q0QshNabYL1auaAn6AFC2jkR2vHat+2/XcycuUY' + #13#10 +
        '+gn0oJMsXdKMdYV2ZZAMA3m3MSNjrXiDCYZohMr/+c8mmpJ5581LxedhpxfL86kS' + #13#10 +
        'k5Nrp+gvU5LEYFiwzAJRGFuFjWJZY7attN6a+yb3ACfAXVU3dJnJUH/jWS5E4ywl' + #13#10 +
        '7uxMMne0nxrpS10gxdr9HIcWxkPo1LsmmkVwXqkLN1PiRnsn/eBG8om3zEK2yygm' + #13#10 +
        'btmlyTrIQRNg91CMFa6ybRoVGld45pIq2WWQgj9sAq+uEjonljYE1x2igGOpm/Hl' + #13#10 +
        'urR8FLBOybEfdF849lHqm/osohHUqS0nGkWxr7JOcQ3AWEbWaQbLU8uz/mtBzUF+' + #13#10 +
        'fUwPfHJ5elnNXkoOrJupmHN5fLT0zLm4BwyydFy4x2+IoZCn9Kr5v2c69BoVYh63' + #13#10 +
        'n749sSmvZ6ES8lgQGVMDMBu4Gon2nL2XA46jCfMdiyHxtN/kHNGfZQIG6lzWE7OE' + #13#10 +
        '76KlXIx3KadowGuuQNKotOrN8I1LOJwZmhsoVLiJkO/KdYE+HvJkJMcYr07/R54H' + #13#10 +
        '9jVlpNMKVv/1F2Rs76giJUmTtt8AF9pYfl3uxRuw0dFfIRDH+fO6AgonB8Xx1sfT' + #13#10 +
        '4PsJYGw=' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts040 =                                                               { V8.63 }
        'Issued to (CN): Amazon Root CA 3, (O): Amazon' + #13#10 +
        'Issuer: Self Signed' + #13#10 +
        'Expires: 26/05/2040, Signature: ecdsa-with-SHA256' + #13#10 +
        'Valid From: 26/05/2015, Serial Number: 066c9fd5749736663f3b0b9ad9e89e7603f24a' + #13#10 +
        'Fingerprint (sha256): 18ce6cfe7bf14e60b2e347b8dfe868cb31d02ebb3ada271569f50343b46db3a4' + #13#10 +
        'Public Key: ECDSA Key Encryption prime256v1 256 bits, 128 security bits' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIBtjCCAVugAwIBAgITBmyf1XSXNmY/Owua2eiedgPySjAKBggqhkjOPQQDAjA5' + #13#10 +
        'MQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRkwFwYDVQQDExBBbWF6b24g' + #13#10 +
        'Um9vdCBDQSAzMB4XDTE1MDUyNjAwMDAwMFoXDTQwMDUyNjAwMDAwMFowOTELMAkG' + #13#10 +
        'A1UEBhMCVVMxDzANBgNVBAoTBkFtYXpvbjEZMBcGA1UEAxMQQW1hem9uIFJvb3Qg' + #13#10 +
        'Q0EgMzBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABCmXp8ZBf8ANm+gBG1bG8lKl' + #13#10 +
        'ui2yEujSLtf6ycXYqm0fc4E7O5hrOXwzpcVOho6AF2hiRVd9RFgdszflZwjrZt6j' + #13#10 +
        'QjBAMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgGGMB0GA1UdDgQWBBSr' + #13#10 +
        'ttvXBp43rDCGB5Fwx5zEGbF4wDAKBggqhkjOPQQDAgNJADBGAiEA4IWSoxe3jfkr' + #13#10 +
        'BqWTrBqYaGFy+uGh0PsceGCmQ5nFuMQCIQCcAu/xlJyzlvnrxir4tiz+OpAUFteM' + #13#10 +
        'YyRIHN8wfdVoOw==' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts041 =                                                               { V8.63 }
        'Issued to (CN): Amazon Root CA 4, (O): Amazon' + #13#10 +
        'Issuer: Self Signed' + #13#10 +
        'Expires: 26/05/2040, Signature: ecdsa-with-SHA384' + #13#10 +
        'Valid From: 26/05/2015, Serial Number: 066c9fd7c1bb104c2943e5717b7b2cc81ac10e' + #13#10 +
        'Fingerprint (sha256): e35d28419ed02025cfa69038cd623962458da5c695fbdea3c22b0bfb25897092' + #13#10 +
        'Public Key: ECDSA Key Encryption secp384r1 384 bits, 192 security bits' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIB8jCCAXigAwIBAgITBmyf18G7EEwpQ+Vxe3ssyBrBDjAKBggqhkjOPQQDAzA5' + #13#10 +
        'MQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRkwFwYDVQQDExBBbWF6b24g' + #13#10 +
        'Um9vdCBDQSA0MB4XDTE1MDUyNjAwMDAwMFoXDTQwMDUyNjAwMDAwMFowOTELMAkG' + #13#10 +
        'A1UEBhMCVVMxDzANBgNVBAoTBkFtYXpvbjEZMBcGA1UEAxMQQW1hem9uIFJvb3Qg' + #13#10 +
        'Q0EgNDB2MBAGByqGSM49AgEGBSuBBAAiA2IABNKrijdPo1MN/sGKe0uoe0ZLY7Bi' + #13#10 +
        '9i0b2whxIdIA6GO9mif78DluXeo9pcmBqqNbIJhFXRbb/egQbeOc4OO9X4Ri83Bk' + #13#10 +
        'M6DLJC9wuoihKqB1+IGuYgbEgds5bimwHvouXKNCMEAwDwYDVR0TAQH/BAUwAwEB' + #13#10 +
        '/zAOBgNVHQ8BAf8EBAMCAYYwHQYDVR0OBBYEFNPsxzplbszh2naaVvuc84ZtV+WB' + #13#10 +
        'MAoGCCqGSM49BAMDA2gAMGUCMDqLIfG9fhGt0O9Yli/W651+kI0rz2ZVwyzjKKlw' + #13#10 +
        'CkcO8DdZEv8tmZQoTipPNU0zWgIxAOp1AE47xDqUEpHJWEadIRNyp4iciuRMStuW' + #13#10 +
        '1KyLa2tJElMzrdfkviT8tQp21KW8EA==' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;
    sslRootCACerts042 =                                                               { V8.64 }
        'Issued to (CN): AAA Certificate Services, (O): Comodo CA Limited' + #13#10 +
        'Issuer: Self Signed' + #13#10 +
        'Expires: 31/12/2028 23:59:59, Signature: sha1WithRSAEncryption' + #13#10 +
        'Valid From: 01/01/2004, Serial Number: 01' + #13#10 +
        'Fingerprint (sha256): d7a7a0fb5d7e2731d771e9484ebcdef71d5f0c3e0a2948782bc83ee0ea699ef4' + #13#10 +
        'Public Key: RSA Key Encryption 2048 bits, 112 security bits' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIEMjCCAxqgAwIBAgIBATANBgkqhkiG9w0BAQUFADB7MQswCQYDVQQGEwJHQjEb' + #13#10 +
        'MBkGA1UECAwSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHDAdTYWxmb3JkMRow' + #13#10 +
        'GAYDVQQKDBFDb21vZG8gQ0EgTGltaXRlZDEhMB8GA1UEAwwYQUFBIENlcnRpZmlj' + #13#10 +
        'YXRlIFNlcnZpY2VzMB4XDTA0MDEwMTAwMDAwMFoXDTI4MTIzMTIzNTk1OVowezEL' + #13#10 +
        'MAkGA1UEBhMCR0IxGzAZBgNVBAgMEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UE' + #13#10 +
        'BwwHU2FsZm9yZDEaMBgGA1UECgwRQ29tb2RvIENBIExpbWl0ZWQxITAfBgNVBAMM' + #13#10 +
        'GEFBQSBDZXJ0aWZpY2F0ZSBTZXJ2aWNlczCCASIwDQYJKoZIhvcNAQEBBQADggEP' + #13#10 +
        'ADCCAQoCggEBAL5AnfRu4ep2hxxNRUSOvkbIgwadwSr+GB+O5AL686tdUIoWMQua' + #13#10 +
        'BtDFcCLNSS1UY8y2bmhGC1Pqy0wkwLxyTurxFa70VJoSCsN6sjNg4tqJVfMiWPPe' + #13#10 +
        '3M/vg4aijJRPn2jymJBGhCfHdr/jzDUsi14HZGWCwEiwqJH5YZ92IFCokcdmtet4' + #13#10 +
        'YgNW8IoaE+oxox6gmf049vYnMlhvB/VruPsUK6+3qszWY19zjNoFmag4qMsXeDZR' + #13#10 +
        'rOme9Hg6jc8P2ULimAyrL58OAd7vn5lJ8S3frHRNG5i1R8XlKdH5kBjHYpy+g8cm' + #13#10 +
        'ez6KJcfA3Z3mNWgQIJ2P2N7Sw4ScDV7oL8kCAwEAAaOBwDCBvTAdBgNVHQ4EFgQU' + #13#10 +
        'oBEKIz6W8Qfs4q8p74Klf9AwpLQwDgYDVR0PAQH/BAQDAgEGMA8GA1UdEwEB/wQF' + #13#10 +
        'MAMBAf8wewYDVR0fBHQwcjA4oDagNIYyaHR0cDovL2NybC5jb21vZG9jYS5jb20v' + #13#10 +
        'QUFBQ2VydGlmaWNhdGVTZXJ2aWNlcy5jcmwwNqA0oDKGMGh0dHA6Ly9jcmwuY29t' + #13#10 +
        'b2RvLm5ldC9BQUFDZXJ0aWZpY2F0ZVNlcnZpY2VzLmNybDANBgkqhkiG9w0BAQUF' + #13#10 +
        'AAOCAQEACFb8AvCb6P+k+tZ7xkSAzk/ExfYAWMymtrwUSWgEdujm7l3sAg9g1o1Q' + #13#10 +
        'GE8mTgHj5rCl7r+8dFRBv/38ErjHT1r0iWAFf2C3BUrz9vHCv8S5dIa2LX1rzNLz' + #13#10 +
        'Rt0vxuBqw8M0Ayx9lt1awg6nCpnBBYurDC/zXDrPbDdVCYfeU0BsWO/8tqtlbgT2' + #13#10 +
        'G9w84FoVxp7Z8VlIMCFlA2zs6SFz7JsDoeA3raAVGI/6ugLOpyypEBMs1OUIJqsi' + #13#10 +
        'l2D4kF501KKaU73yqWjgom7C12yxow+ev+to51byrvLjKzg6CYG1a4XXvi3tPxq3' + #13#10 +
        'smPi9WIsgtRqAEFQ8TmDn5XpNpaYbg==' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;

{$ENDIF}  { USE_SSL }

implementation

{$IFDEF USE_SSL}

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function sslRootCACertsBundle: string ;  { V8.32 }
begin
    result :=
        sslRootCACerts001 + sslRootCACerts002 + sslRootCACerts003 + sslRootCACerts004 + sslRootCACerts005 +
        sslRootCACerts007 + sslRootCACerts008 + sslRootCACerts009 + sslRootCACerts010 +
        sslRootCACerts011 + sslRootCACerts012 + sslRootCACerts013 + sslRootCACerts014 + sslRootCACerts015 +
        sslRootCACerts016 + sslRootCACerts017 + sslRootCACerts018 + sslRootCACerts020 +
        sslRootCACerts021 + sslRootCACerts022 + sslRootCACerts023 +
        sslRootCACerts026 + sslRootCACerts027 + sslRootCACerts029 + sslRootCACerts030 +
        sslRootCACerts031 + sslRootCACerts032 + sslRootCACerts033 + sslRootCACerts034 + sslRootCACerts035 +
        sslRootCACerts036 + sslRootCACerts037 + sslRootCACerts038 + sslRootCACerts039 + sslRootCACerts040 +
        sslRootCACerts041 + sslRootCACerts042;
    end ;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure RaiseLastOpenSslError(
    EClass          : ExceptClass;
    Dump            : Boolean = FALSE;
    const CustomMsg : AnsiString  = '');
const
    CRLF = AnsiString(#13#10);
begin
    if Length(CustomMsg) > 0 then
        raise EClass.Create(String(CRLF + CustomMsg + CRLF +
                            LastOpenSslErrMsg(Dump) + CRLF))
    else
        raise EClass.Create(String(CRLF + LastOpenSslErrMsg(Dump) + CRLF));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure AddNameEntryByTxt(Name: PX509_NAME; const Field: AnsiString; const Value: String);
var
    AStr : AnsiString;
    SType: Cardinal;
begin
    if IsUsAscii(Value) then begin
        AStr  := AnsiString(Value);
        SType := MBSTRING_ASC;
    end
    else begin
        AStr  := StringToUtf8(Value);
        { If we used MBSTRING_UTF8 the string would be converted to Ansi }
        { with current code page by OpenSSL silently, strange.           }
        SType := V_ASN1_UTF8STRING;
    end;
    if Length(AStr) = 0 then exit;
    if f_X509_NAME_add_entry_by_txt(Name, PAnsiChar(Field),
                                  SType, PAnsiChar(AStr), -1, -1, 0) = 0 then
         RaiseLastOpenSslError(ECertToolsException, FALSE, 'Can not add name entry ' + Field);
end;


{ V8.40 component to create SSL certificates and keys }
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
Constructor TSslCertTools.Create(AOwner: TComponent);
begin
    inherited Create(AOwner);
    FPrivKeyType := PrivKeyRsa2048;
    FPrivKeyCipher := PrivKeyEncNone;
    FCertDigest := Digest_sha256;
    FBasicPathLen := 0;
    FNewCert := Nil;
    FNewReq := Nil;
    FRsaKey := Nil;
    FPrivKey := Nil;
    FECkey := Nil;
    FECgroup := Nil;
    FX509Req := nil;
    FX509CA := Nil;
    FPrivKeyCA := Nil;
    FAltDNSList  := TStringList.Create;
    FAltIpList := TStringList.Create;
    FAltEmailList := TStringList.Create;
    SetLength (FAltAnsiStr, 0);
    SetLength (FAltGenStr, 0);
    SetLength (FAltIa5Str, 0);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
destructor TSslCertTools.Destroy;
begin
    if FSslInitialized then begin
        FAltDNSList.Free;
        FAltIpList.Free;
        FAltEmailList.Free;
     // must free public pointers before those they point to
        PrivateKey := Nil;
        X509 := Nil;
        if Assigned(FNewCert) then
            f_X509_free(FNewCert);
        if Assigned(FNewReq) then
            f_X509_REQ_free(FNewReq);
        if Assigned(FPrivKey) then
            f_EVP_PKEY_free(FPrivKey);
         FreeAndNilX509Req;
         FreeAndNilX509CA;
         FreeAndNilPrivKeyCA;
    end;
    inherited Destroy;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslCertTools.FreeAndNilX509Req;
begin
    if Assigned(FX509Req) then begin
        f_X509_REQ_free(FX509Req);
        FX509Req := nil;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslCertTools.FreeAndNilX509CA;
begin
    if NOT FSslInitialized then Exit;
    if Assigned(FX509CA) then begin
        f_X509_free(FX509CA);
        FX509CA := nil;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslCertTools.FreeAndNilPrivKeyCA;
begin
    if NOT FSslInitialized then Exit;
    if Assigned(FPrivKeyCA) then begin
        f_EVP_PKEY_free(FPrivKeyCA);
        FPrivKeyCA := nil;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslCertTools.SetX509CA(Cert: Pointer);
begin
    InitializeSsl;
    FreeAndNilX509CA;
    if Assigned(Cert) then begin
        FX509CA := f_X509_dup(Cert);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslCertTools.GetIsReqLoaded: Boolean;
begin
    Result := Assigned(FX509Req);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslCertTools.GetIsCALoaded: Boolean;
begin
    Result := Assigned(FX509CA);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslCertTools.SetPrivKeyCA(Pkey: PEVP_PKEY);
begin
    InitializeSsl;
    FreeAndNilPrivKeyCA;
    if Assigned(PKey) then begin
        FPrivKeyCA := Ics_EVP_PKEY_dup(PKey);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslCertTools.SetX509Req(X509Req: Pointer);
begin
    InitializeSsl;
    FreeAndNilX509Req;
    if Assigned(X509Req) then begin
        FX509Req := f_X509_REQ_dup(X509Req);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ returns formatted text with raw certificate request fields }
function TSslCertTools.GetRequestRawText: String;
var
    Bio  : PBIO;
    Len  : Integer;
    AStr : AnsiString;
begin
    Result := '';
    if FX509Req = nil then Exit;
    Bio := f_BIO_new(f_BIO_s_mem);
    if Assigned(Bio) then
    try
        f_X509_REQ_print(Bio, FX509Req);
        Len := f_BIO_ctrl(Bio, BIO_CTRL_PENDING, 0, nil);
        SetLength(AStr, Len);
        if Len > 0 then begin
            f_Bio_read(Bio, PAnsiChar(AStr), Len);
            SetLength(AStr, StrLen(PAnsiChar(AStr)));
            Result := String(AStr);
        end;
    finally
        f_bio_free(Bio);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ PKCS#10 certificate request, typical file extension .PEM, .DER }
procedure TSslCertTools.LoadReqFromFile(const FileName: String);
var
    FileBio : PBIO;
    Req : PX509_REQ;
begin
    InitializeSsl;
    FileBio := IcsSslOpenFileBio(FileName, bomReadOnly);
    try
        Req := f_PEM_read_bio_X509_REQ(FileBio, Nil, Nil, Nil);  { base64 version }
        if NOT Assigned (Req) then begin
            f_BIO_ctrl(FileBio, BIO_CTRL_RESET, 0, nil);
            Req := f_d2i_X509_REQ_bio(FileBio, Nil);            { DER binary version }
        end;
        if NOT Assigned (Req) then
            RaiseLastOpenSslError(EX509Exception, TRUE,
                                  'Error reading certificate request from file');
        SetX509Req(Req);
        f_X509_REQ_free(Req);
    finally
        f_bio_free(FileBio);
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ write PKCS10 certificate request to BIO }
procedure TSslCertTools.WriteReqToBio(ABio: PBIO; AddInfoText: Boolean = FALSE; const FName: String = '');
var
    comments: AnsiString;
begin
    if not Assigned(ABio) then
        raise EX509Exception.Create('BIO not assigned');
    if not Assigned(FX509Req) then
        raise EX509Exception.Create('FX509Req not assigned');
    if AddInfoText then begin
        comments := AnsiString(GetReqCertInfo) + #13#10;
        if f_BIO_write(ABio, @comments [1], Length (comments)) = 0 then
            RaiseLastOpenSslError(EX509Exception, TRUE, 'Error writing raw text to ' + FName);
    end;
    if f_PEM_write_bio_X509_REQ(ABio, PX509_REQ(FX509Req)) = 0 then
        RaiseLastOpenSslError(EX509Exception, TRUE, 'Error writing request to BIO' + FName);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ save PKCS10 certificate request }
procedure TSslCertTools.SaveReqToFile(const FileName: String; AddInfoText: Boolean = FALSE);
var
    FileBio : PBIO;
begin
    if not Assigned(FX509Req) then
        raise EX509Exception.Create('Certificate request not assigned');
    FileBio := IcsSslOpenFileBio(FileName, bomWrite);
    try
        WriteReqToBio(FileBIO, AddInfoText);
    finally
        f_bio_free(FileBio);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ returns base64 encoded DER PEM certificate request }
function TSslCertTools.SaveReqToText(AddInfoText: Boolean = FALSE): String;
var
    Bio  : PBIO;
    Len  : Integer;
    AStr : AnsiString;
begin
    Result := '';
    if FX509Req = nil then Exit;
    Bio := f_BIO_new(f_BIO_s_mem);
    if Assigned(Bio) then
    try
        WriteReqToBio(Bio, AddInfoText);
        Len := f_BIO_ctrl(Bio, BIO_CTRL_PENDING, 0, nil);
        SetLength(AStr, Len);
        if Len > 0 then begin
            f_Bio_read(Bio, PAnsiChar(AStr), Len);
            SetLength(AStr, StrLen(PAnsiChar(AStr)));
            Result := String(AStr);
        end;
    finally
        f_bio_free(Bio);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ returns binary DER certificate request }
function TSslCertTools.SaveReqToDERText: AnsiString;      { V8.52, V8.64 was SaveToDERText }
var
    Bio  : PBIO;
    Len: Integer;
begin
    Result := '';
    if FX509Req = nil then Exit;
    Bio := f_BIO_new(f_BIO_s_mem);
    if Assigned(Bio) then
    try
        if f_i2d_X509_REQ_bio(Bio, PX509_REQ(FX509Req)) = 0 then
           RaiseLastOpenSslError(EX509Exception, TRUE, 'Error writing request to BIO');

        Len := f_BIO_ctrl(Bio, BIO_CTRL_PENDING, 0, nil);
        if Len > 0 then begin
            SetLength(Result, Len);
            f_Bio_read(Bio, PAnsiChar(Result), Len);
        end;
    finally
        f_bio_free(Bio);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ returns binary DER certificate }
function TSslCertTools.SaveCertToDERText: AnsiString;                  { V8.64 }
var
    Bio  : PBIO;
    Len: Integer;
begin
    Result := '';
    if not Assigned(X509) then Exit;
    Bio := f_BIO_new(f_BIO_s_mem);
    if Assigned(Bio) then
    try
        if f_i2d_X509_bio(Bio, X509) = 0 then
            RaiseLastOpenSslError(EX509Exception, TRUE,
                           'Error writing DER certificate to BIO');
        Len := f_BIO_ctrl(Bio, BIO_CTRL_PENDING, 0, nil);
        if Len > 0 then begin
            SetLength(Result, Len);
            f_Bio_read(Bio, PAnsiChar(Result), Len);
        end;
    finally
        f_bio_free(Bio);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ Returns a CRLF-separated list if multiple entries exist }
function TSslCertTools.GetReqEntryByNid(ANid: Integer): String;
var
    Name    : PX509_NAME;
begin
    Result := '';
    if not Assigned(X509Req) then
        Exit;
    Name := f_Ics_X509_REQ_get_subject_name(X509Req);
    if Name <> nil then
        Result := GetPX509NameByNid(Name, ANid);  { V8.41 }
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslCertTools.GetReqSubjOneLine: String;
var
    Str : AnsiString;
begin
    Result := '';
    if not Assigned(FX509Req) then
        Exit;

    SetLength(Str, 512);
    Str := f_X509_NAME_oneline(f_ics_X509_REQ_get_subject_name(FX509Req),
                                              PAnsiChar(Str), Length(Str));
    SetLength(Str, StrLen(PAnsiChar(Str)));
    Result := String(Str);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslCertTools.GetReqSubjCName: String;
begin
    Result := GetReqEntryByNid(NID_commonName);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslCertTools.GetReqSubjOName: String;
begin
    Result := GetReqEntryByNid(NID_organizationName);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslCertTools.GetReqExtByName(const S: String): TExtension;
var
    ExtnStack : PStack;
    I         : Integer;
    Ext       : PX509_EXTENSION;
    Count     : Integer;
begin
    Result.Critical  := FALSE;
    Result.ShortName := '';
    Result.Value     := '';
    if NOT Assigned(FX509Req) then Exit;
    ExtnStack := f_X509_REQ_get_extensions(FX509Req);
    if NOT Assigned(ExtnStack) then Exit;
    Count := f_OPENSSL_sk_num(ExtnStack);
    for I := 0 to Count - 1 do begin
        Ext := PX509_EXTENSION(f_OPENSSL_sk_value(ExtnStack, I));
        if not Assigned(Ext) then
            Continue;
        if CheckExtName(Ext, S) then begin    { V8.41 simplify }
            Result := GetExtDetail(Ext);
            Exit;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslCertTools.GetReqExtValuesByName(const ShortName, FieldName: String): String;
var
    Ext    : TExtension;
begin
    Result := '';
    if not Assigned(X509Req) then
        Exit;
    Ext := GetReqExtByName(ShortName);
    if Length(Ext.ShortName) > 0 then begin
        Result := GetExtField(Ext, FieldName);   { V8.41 simplify }
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslCertTools.GetReqSubjAltNameDNS: String;
begin
   Result := GetReqExtValuesByName('subjectAltName', 'DNS');
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslCertTools.GetReqSubjAltNameIP: String;
begin
   Result := GetReqExtValuesByName('subjectAltName', 'IP');
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslCertTools.GetReqKeyUsage: String;
begin
    Result := GetReqExtValuesByName('keyUsage', '');
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslCertTools.GetReqExKeyUsage: String;
begin
    Result := GetReqExtValuesByName('extendedKeyUsage', '');
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslCertTools.GetReqKeyInfo: string;       { V8.52 }
var
    pubkey: PEVP_PKEY;
begin
    result := '' ;
    if NOT Assigned(FX509Req) then Exit;
    pubkey := f_X509_REQ_get_pubkey(FX509Req);
    Result := GetKeyDesc(pubkey);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslCertTools.GetReqSignAlgo: String;      { V8.52 }
var
    Nid: integer ;
    Str : AnsiString;
    MyX509Req: PX509_REQ;
begin
    Result := '';
    if NOT Assigned(FX509Req) then Exit;
    if (ICS_OPENSSL_VERSION_NUMBER >= OSSL_VER_1100) then
        Nid := f_X509_REQ_get_signature_nid(FX509Req)
    else begin
        MyX509Req := FX509Req;
        Nid := f_OBJ_obj2nid(MyX509Req^.sig_alg.algorithm); 
    end;
    if Nid <> NID_undef then begin
        SetLength(Str, 256);
        Str := f_OBJ_nid2ln(Nid);
        SetLength(Str, IcsStrLen(PAnsiChar(Str)));
        Result := String(Str);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslCertTools.GetReqCertInfo: String;
begin
    Result := 'Request for (CN): ' + IcsUnwrapNames (ReqSubjCName);
    if ReqSubjOName <> '' then
        Result := Result + ', (O): ' + IcsUnwrapNames (ReqSubjOName) + #13#10
    else
        Result := Result + #13#10;
    if ReqSubjAltNameDNS <> '' then
        Result := Result + 'Alt Domains: ' + IcsUnwrapNames (ReqSubjAltNameDNS) + #13#10;
    if ReqSubjAltNameIP <> '' then
        Result := Result + 'Alt IPs: ' + IcsUnwrapNames (ReqSubjAltNameIP) + #13#10;
    if ReqKeyUsage <> '' then
        Result := Result + 'Key Usage: ' + IcsUnwrapNames(ReqKeyUsage) + #13#10;
    if ReqExKeyUsage <> '' then
        Result := Result + 'Extended Key Usage: ' + IcsUnwrapNames(ReqExKeyUsage) + #13#10;
    Result := Result + 'Signature: ' + ReqSignAlgo + #13#10;
    Result := Result + 'Public Key: ' + ReqKeyInfo;

end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslCertTools.SetCertExt(Cert: PX509; Nid: integer; const List: AnsiString);
var
    Ex: PX509_EXTENSION;
begin
    if List = '' then exit;
    Ex := f_X509V3_EXT_conf_nid(nil, nil, Nid, PAnsiChar(List));
    if not Assigned(Ex) then
        RaiseLastOpenSslError(ECertToolsException, FALSE,
                'Failed to add extension to certificate, Nid ' + IntToStr (Nid));
    f_X509_add_ext(cert, Ex, -1);
    f_X509_EXTENSION_free(Ex);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslCertTools.BuildBasicCons(IsCA: Boolean): AnsiString;
begin
    if IsCA then
       Result := 'critical,CA:TRUE, pathlen:' + IcsIntToStrA(FBasicPathLen) // 0=not sign other CAs
    else
       Result := 'critical,CA:FALSE';
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslCertTools.BuildKeyUsage: AnsiString;
begin
    Result := '';
    if FKeyCertSign then Result := Result + ', keyCertSign';
    if FKeyCRLSign  then Result := Result + ', cRLSign';
    if FKeyDigiSign then Result := Result + ', digitalSignature';
    if FKeyDataEnc  then Result := Result + ', dataEncipherment';
    if FKeyKeyEnc   then Result := Result + ', keyEncipherment';
    if FKeyKeyAgree then Result := Result + ', keyAgreement';
    if FKeyNonRepud then Result := Result + ', nonRepudiation';
    { others: encipherOnly, decipherOnly }
    if Result <> '' then Result := 'critical' + Result;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslCertTools.BuildExKeyUsage: AnsiString;
begin
    Result := '';
    if FKeyExtClient then Result := Result + ', clientAuth';
    if FKeyExtServer then Result := Result + ', serverAuth';
    if FKeyExtEmail  then Result := Result + ', emailProtection';
    if FKeyExtCode   then Result := Result + ', codeSigning';
    if Result <> '' then Result := Copy (Result, 3, 999);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ build stack of extension multiple values from combined list of different types }
function TSslCertTools.BuildAltStackAll: PStack;
var
    I: Integer;
    ASocketFamily: TSocketFamily;
    ConvOk: Boolean;
    v4Addr: TIcsIPv4Address;
    v6Addr: TIcsIPv6Address;
begin
    result := f_OPENSSL_sk_new_null;
    if FTotAltItems = 0 then Exit;
    SetLength (FAltAnsiStr, FTotAltItems);    { V8.50 separate memory to allow stack to be built }
    SetLength (FAltIa5Str, FTotAltItems);
    SetLength (FAltGenStr, FTotAltItems);
    for I := 0 to FTotAltItems - 1 do begin
        FAltGenStr[I] := f_GENERAL_NAME_new;
        if NOT Assigned(FAltGenStr[I]) then Exit;
        FAltIa5Str[I] := f_ASN1_STRING_new;
        if NOT Assigned(FAltIa5Str[I]) then Exit;
        if FAltItems[I].AltType = GEN_IPADD then begin  { V8.64 IP saved in binary }
            if NOT WSocketIsIP(String(FAltItems[I].AltName), ASocketFamily) then
                FAltAnsiStr[I] := FAltItems[I].AltName
            else begin
                if ASocketFamily = sfIPv4 then begin
                     v4Addr := WSocketStrToIPv4(String(FAltItems[I].AltName), ConvOk);
                     SetLength(FAltAnsiStr[I], 4);
                     Move(v4Addr,  FAltAnsiStr[I] [1], 4);
                end;
                if ASocketFamily = sfIPv6 then begin
                     v6Addr := WSocketStrToIPv6(String(FAltItems[I].AltName), ConvOk);
                     SetLength(FAltAnsiStr[I], 16);
                     Move(v6Addr,  FAltAnsiStr[I] [1], 16);
                end;
            end;
        end
        else
            FAltAnsiStr[I] := FAltItems[I].AltName;
        if FAltAnsiStr[I] <> '' then begin    { V8.50 skip blanks }
            if f_ASN1_STRING_set(FAltIa5Str[I], PAnsiChar(FAltAnsiStr[I]), Length(FAltAnsiStr[I])) = 0 then   { V8.50 was set0 }
                RaiseLastOpenSslError(ECertToolsException, FALSE, 'Invalid subject_alt_name: ' + String(FAltItems[I].AltName));
            f_GENERAL_NAME_set0_value(FAltGenStr[I], FAltItems[I].AltType, FAltIa5Str[I]);
            f_OPENSSL_sk_push(result, Pointer(FAltGenStr[I]));
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ clear alt extension stack }
procedure TSslCertTools.ClearAltStack;
//var
//    I: Integer;
begin
  { V8.64 fails on Win64, so possible memory leak without this
   if Length (FAltGenStr) > 0 then begin
        for I := 0 to Length (FAltGenStr) - 1 do begin
            if Assigned(FAltGenStr[I]) then f_GENERAL_NAME_free(FAltGenStr[I]);
        end;
    end;
    if Length (FAltIa5Str) > 0 then begin
        for I := 0 to Length (FAltIa5Str) - 1 do begin
            if Assigned(FAltIa5Str[I]) then f_ASN1_STRING_free(FAltIa5Str[I]);
        end;
    end;
    }
    SetLength (FAltAnsiStr, 0);
    SetLength (FAltGenStr, 0);
    SetLength (FAltIa5Str, 0);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ build stack for an X509 certificate }
procedure TSslCertTools.BuildCertAltSubjAll(Cert: PX509);  { V8.64 }
var
    MultiValuesStack : PStack;
begin
    if FTotAltItems = 0 then Exit;
    MultiValuesStack := BuildAltStackAll;
    if NOT Assigned(MultiValuesStack) then Exit;
    try
        if f_X509_add1_ext_i2d(Cert, NID_subject_alt_name, MultiValuesStack, 0, 0) = 0 then
            RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to set subject_alt_name');
    finally
        f_OPENSSL_sk_free(MultiValuesStack);
        ClearAltStack;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ combine various alternate names into sincle list from properties }
procedure TSslCertTools.BuildAltPropList;  { V8.64 }
var
    I, J: Integer;
    ErrFlag, CheckFlag: Boolean;
begin
    FTotAltItems := FAltDNSList.Count + FAltIPList.Count + FAltEmailList.Count;
    SetLength(FAltItems, FTotAltItems);
    if FTotAltItems = 0 then Exit;
    J := 0;

  { subject alternate name - DNS or domain names }
    if FAltDNSList.Count <> 0 then begin
        for I := 0 to FAltDNSList.Count - 1 do begin
            CheckFlag := (Pos('*', FAltDNSList[I]) = 0);  // wild card will fail domain name check
         { V8.64 convert domain to A-Label }
            FAltItems[J].AltName := AnsiString(IcsIDNAToASCII(IcsTrim(FAltDNSList[I]), CheckFlag, ErrFlag));
            FAltItems[J].AltType := GEN_DNS;
            J := J + 1;
        end;
    end;

  { subject alternate name - IP addresses }
    if FAltIPList.Count <> 0 then begin
        for I := 0 to FAltIPList.Count - 1 do begin
            FAltItems[J].AltName := AnsiString(IcsTrim(FAltIPList[I]));
            FAltItems[J].AltType := GEN_IPADD;
            J := J + 1;
        end;
    end;

  { subject alternate name - email addresses }
    if FAltEmailList.Count <> 0 then begin
        for I := 0 to FAltEmailList.Count - 1 do begin
            FAltItems[J].AltName := AnsiString(IcsTrim(FAltEmailList[I]));
            FAltItems[J].AltType := GEN_EMAIL;
            J := J + 1;
        end;
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ combine various alternate names into sincle list from properties }
procedure TSslCertTools.BuildAltReqList;  { V8.64 }
var
    I, J: Integer;
    AltItems: String;
    TempList: TStringList;
begin
    FTotAltItems := 0;
    TempList := TStringList.Create;
    try
        AltItems :=  ReqSubjAltNameDNS;
        J := 0;
        if AltItems <> '' then begin
            TempList.Text := AltItems;
            if TempList.Count > 0 then begin
                FTotAltItems := TempList.Count;
                SetLength(FAltItems, FTotAltItems);
                for I := 0 to TempList.Count - 1 do begin
                    FAltItems[J].AltName := AnsiString(IcsTrim(TempList[I]));
                    FAltItems[J].AltType := GEN_DNS;
                    J := J + 1;
                end;
            end;
        end;
        AltItems :=  ReqSubjAltNameIP;
        J := 0;
        if AltItems <> '' then begin
            TempList.Text := AltItems;
            if TempList.Count > 0 then begin
                FTotAltItems := FTotAltItems + TempList.Count;
                SetLength(FAltItems, FTotAltItems);
                for I := 0 to TempList.Count - 1 do begin
                    FAltItems[J].AltName := AnsiString(IcsTrim(TempList[I]));
                    FAltItems[J].AltType := GEN_IPADD;
                    J := J + 1;
                end;
            end;
        end;
    finally
        TempList.Free;
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ A certificate request is the second step in acquiring a commercial X509 }
{ certificate (usually paid) from a certificate issuing authority. }
{ A private key needs to be created first, then all the certificate subject }
{ properties such as domain name, company name, etc, are specified and an }
{ X509 Request is created.  The request should be passed to the chosen }
{ certificate authority who will create a new X509 certificate signed by }
{ one of their issuing certificates.  For the new X509 certificate to be }
{ trusted by SSL/TLS applications, the issuing certificate needs to installed }
{ in a local root certificate store, which is normally part of the browser or
{ other software.  Often, the CA will use an intermediate certificate which
{ is itself signed by a root certificate, and this intermediate certificiate }
{ needs to be installed on the SSL/TLS server with the X509 certificate so it
{ is sent to clients.   }
{ This method needs PrivateKey completed, and creates the request }
{ in X509Req from where is may be saved by SaveReqTo.   }
procedure TSslCertTools.DoCertReqProps;

  procedure Add_Ext(sk :PSTACK_OF_X509_EXTENSION; Nid :Integer; const Value :AnsiString);
  var
      Ext : PX509_EXTENSION;
  begin
      if Value = '' then Exit;
      Ext := f_X509V3_EXT_conf_nid(nil, nil, NID, PAnsiChar(value));
      if not Assigned(Ext) then
            RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to create extension');
      f_OPENSSL_sk_push(sk, Pointer(ext));
  end;

 { build stack for an X509 certificate request }
    procedure BuildReqAltSubjAll(sk :PSTACK_OF_X509_EXTENSION);  { V8.64 }
    var
        MultiValuesStack : PStack;
    begin
        if FTotAltItems = 0 then Exit;
        MultiValuesStack := BuildAltStackAll;
        if NOT Assigned(MultiValuesStack) then Exit;
        try
          if f_X509V3_add1_i2d(@sk, NID_subject_alt_name, MultiValuesStack, 0, 0) = 0 then
                RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to create extension Altname stack');
        finally
            f_OPENSSL_sk_free(MultiValuesStack);
            ClearAltStack;
        end;
    end;


var
    SubjName  : PX509_NAME;
    Exts      : PSTACK_OF_X509_EXTENSION;
    AName     : String;  { V8.64 }
    ErrFlag, CheckFlag : Boolean;
begin
    InitializeSsl;
    if NOT Assigned(PrivateKey) then
        raise ECertToolsException.Create('Must create private key first');
    if (ICS_OPENSSL_VERSION_NUMBER < OSSL_VER_1101) and (FCertDigest >= Digest_sha3_224) then   { V8.51 }
        raise ECertToolsException.Create('SHA3 hashes not supported');

 { V8.64 convert domain to A-Label (Punycode ASCII, validate for allowed characters }
    if NOT FBasicIsCA then begin
        CheckFlag := (Pos('*', FCommonName) = 0);  // wild card will fail domain name check
        AName := IcsIDNAToASCII(IcsTrim(FCommonName), CheckFlag, ErrFlag);
        if ErrFlag then
            raise ECertToolsException.Create('Invalid Common Name, Illegal Characters');
        end
    else
        AName := IcsTrim(FCommonName); // CA is usually a company name, not a domain

    if Assigned(FNewReq) then f_X509_REQ_free(FNewReq);
    FNewReq := f_X509_Req_new;
    if NOT Assigned(FNewReq) then
         raise ECertToolsException.Create('Can not create new request object');

   if f_X509_REQ_set_version(FNewReq, 2) = 0 then   // v3
        RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to set version in request');

    if f_X509_REQ_set_pubkey(FNewReq, PrivateKey) = 0 then
        RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to add public key to request');

    SubjName := f_ics_X509_REQ_get_subject_name(FNewReq);
    if not Assigned(SubjName) then
        RaiseLastOpenSslError(ECertToolsException, FALSE, 'Can not read X509 subject_name');
    AddNameEntryByTxt(SubjName, 'CN', AName);      { V8.64 }
    AddNameEntryByTxt(SubjName, 'OU', FOrgUnit);
    AddNameEntryByTxt(SubjName, 'ST', FState);
    AddNameEntryByTxt(SubjName, 'O',  FOrganization);
    AddNameEntryByTxt(SubjName, 'C',  FCountry);
    AddNameEntryByTxt(SubjName, 'L',  FLocality);
    AddNameEntryByTxt(SubjName, 'D',  FDescr);

    if Length(AnsiString(FEmail)) > 0 then
        f_X509_NAME_add_entry_by_NID(SubjName, NID_pkcs9_emailAddress,
                    MBSTRING_ASC, PAnsiChar(AnsiString(FEmail)), -1, -1, 0);

 { add extensions - create new stack  }
    Exts := f_OPENSSL_sk_new_null;
    Add_Ext(Exts, NID_key_usage, BuildKeyUsage);

  { Extended Key usage }
    Add_Ext(Exts, NID_ext_key_usage, BuildExKeyUsage);

  { subject alternate names }
  { V8.64 add DNS, IPs and emails together, previously only one }
    BuildAltPropList;
    BuildReqAltSubjAll(Exts);

 { finally add stack of extensions to request }
    if f_X509_REQ_add_extensions(FNewReq, Exts) = 0 then
        RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to add extensions to request');
    f_OPENSSL_sk_pop_free(Exts, @f_X509_EXTENSION_free);

 { sign request with private key and digest/hash }
    if f_EVP_PKEY_base_id(PrivateKey) = EVP_PKEY_ED25519 then begin   { V8.51 no digest for EVP_PKEY_ED25519 }
        if f_X509_REQ_sign(FNewReq, PrivateKey, Nil) = 0 then
            RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to sign request with ED25519 key');
    end
    else begin
        if f_X509_REQ_sign(FNewReq, PrivateKey, IcsSslGetEVPDigest(FCertDigest)) = 0 then
            RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to sign request with digest');
    end;
    SetX509Req(FNewReq);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ similar to DoCertReqProps but creates a new X509 certificate request from }
{ an existing certificate, ie to renew a expiring certificate. }
{ This method needs X509 and PrivateKey completed, and creates }
{ the request in X509Req from where is may be saved by SaveReqTo.   }
procedure TSslCertTools.DoCertReqOld;
begin
    InitializeSsl;
    if NOT Assigned(X509) then
        raise ECertToolsException.Create('Must open old certificate first');
    if NOT Assigned(PrivateKey) then
        raise ECertToolsException.Create('Must create private key first');
    if f_X509_check_private_key(X509, PrivateKey) < 1 then
        raise ECertToolsException.Create('Old certificate and private key do not match');
    if (ICS_OPENSSL_VERSION_NUMBER < OSSL_VER_1101) and (FCertDigest >= Digest_sha3_224) then   { V8.51 }
        raise ECertToolsException.Create('SHA3 hashes not supported');

  { create new request from old certificate - warning ignores alternate subject DNS }
    if Assigned(FNewReq) then f_X509_REQ_free(FNewReq);
    if f_EVP_PKEY_base_id(PrivateKey) = EVP_PKEY_ED25519 then    { V8.51 no digest for EVP_PKEY_ED25519 }
        FNewReq := f_X509_to_X509_REQ(X509, PrivateKey, Nil)
    else
        FNewReq := f_X509_to_X509_REQ(X509, PrivateKey, IcsSslGetEVPDigest(FCertDigest));
    if NOT Assigned (FNewReq) then
        RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to sign request with digest');
     SetX509Req(FNewReq);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ create a self signed certificate from properties or request and private key }
procedure TSslCertTools.DoSelfSignCert(UseCSR: Boolean = False);   { V8.57 added UseCSR }
var
    SubjName  : PX509_NAME;
    TempSerial : ULARGE_INTEGER; { V8.42 was TULargeInteger } { 64-bit integer record }
    AName     : String;  { V8.64 }
    ErrFlag, CheckFlag : Boolean;
begin
    InitializeSsl;
    if (ICS_OPENSSL_VERSION_NUMBER < OSSL_VER_1101) and (FCertDigest >= Digest_sha3_224) then   { V8.51 }
        raise ECertToolsException.Create('SHA3 hashes not supported');
    if NOT Assigned(PrivateKey) then
        raise ECertToolsException.Create('Must create private key first');
    if UseCSR then begin   { V8.57 }
        if NOT Assigned(FX509Req) then
            raise ECertToolsException.Create('Must open certificate request first');
    end;

 { V8.64 convert domain to A-Label (Punycode ASCII, validate for allowed characters }
    if NOT FBasicIsCA then begin
        CheckFlag := (Pos('*', FCommonName) = 0);  // wild card will fail domain name check
        AName := IcsIDNAToASCII(IcsTrim(FCommonName), CheckFlag, ErrFlag);
        if ErrFlag then
            raise ECertToolsException.Create('Invalid Common Name, Illegal Characters');
     end
     else
        AName := IcsTrim(FCommonName); // CA is usually a company name, not a domain

    if Assigned(FNewCert) then f_X509_free(FNewCert);
    FNewCert := f_X509_new;
    if NOT Assigned(FNewCert) then
         RaiseLastOpenSslError(ECertToolsException, FALSE, 'Can not create new X509 object');

   { set version, serial number, expiry }
    if f_X509_set_version(FNewCert, 2) = 0 then   // v3
        RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to set version to certificate');;
    if FSerialNum = 0 then begin
        TempSerial.LowPart := IcsRandomInt($7FFFFFFF);
        TempSerial.HighPart := IcsRandomInt($7FFFFFFF);
        FSerialNum := TempSerial.QuadPart;
    end;
    if FExpireDays < 7 then FExpireDays := 7;  { V8.62 was 30 }
    f_ASN1_INTEGER_set_int64(f_X509_get_serialNumber(FNewCert), FSerialNum);
    f_X509_gmtime_adj(f_Ics_X509_get_notBefore(FNewCert), 0);
    f_X509_gmtime_adj(f_Ics_X509_get_notAfter(FNewCert), 60 * 60 * 24 * FExpireDays);

    if f_X509_set_pubkey(FNewCert, PrivateKey) = 0 then
        RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to add public key to certificate');

 { V8.57 see if using CSR for out new certificate }
    if UseCSR then begin

      { set the cert subject name to the request subject }
        SubjName := f_X509_NAME_dup(f_ics_X509_REQ_get_subject_name(X509Req));
        if NOT Assigned(SubjName) or (f_X509_set_subject_name(FNewCert, SubjName) = 0) then
            RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to set subject from request');

      { It's self signed so set the issuer name to be the same as the subject. }
        f_X509_set_issuer_name(FNewCert, SubjName);

      { Add basic contraints }
        SetCertExt(FNewCert, NID_basic_constraints, BuildBasicCons(FBasicIsCA));

     { copy some extension from request to certificate }
        BuildAltReqList;  { V8.64 }
        BuildCertAltSubjAll(FNewCert);

     { Key usage }
        SetCertExt(FNewCert, NID_key_usage, AnsiString(IcsUnwrapNames(ReqKeyUsage)));

    { Extended Key usage }
        SetCertExt(FNewCert, NID_ext_key_usage, AnsiString(IcsUnwrapNames(ReqExKeyUsage)));
    end

 { build certificate from properties }
    else begin

    { build certificate subject name as one line
      ie Subject: C=GB, ST=Surrey, L=Croydon, O=Magenta Systems Ltd, CN=Magenta Systems Ltd }
        SubjName := f_X509_get_subject_name(FNewCert);
        if not Assigned(SubjName) then
            RaiseLastOpenSslError(ECertToolsException, FALSE, 'Can not read X509 subject_name');
        AddNameEntryByTxt(SubjName, 'CN', AName);      { V8.64 }
        AddNameEntryByTxt(SubjName, 'OU', FOrgUnit);
        AddNameEntryByTxt(SubjName, 'ST', FState);
        AddNameEntryByTxt(SubjName, 'O',  FOrganization);
        AddNameEntryByTxt(SubjName, 'C',  FCountry);
        AddNameEntryByTxt(SubjName, 'L',  FLocality);
        AddNameEntryByTxt(SubjName, 'D',  FDescr);

        if Length(AnsiString(FEmail)) > 0 then
            f_X509_NAME_add_entry_by_NID(SubjName, NID_pkcs9_emailAddress,
                        MBSTRING_ASC, PAnsiChar(AnsiString(FEmail)), -1, -1, 0);

      { It's self signed so set the issuer name to be the same as the subject. }
        f_X509_set_issuer_name(FNewCert, SubjName);

      { Add basic contraints }
        SetCertExt(FNewCert, NID_basic_constraints, BuildBasicCons(FBasicIsCA));

      { Key usage }
        SetCertExt(FNewCert, NID_key_usage, BuildKeyUsage);

      { Extended Key usage }
        SetCertExt(FNewCert, NID_ext_key_usage, BuildExKeyUsage);

      { subject alternate names }
      { V8.64 add DNS, IPs and emails together, previously only one }
        BuildAltPropList;
        BuildCertAltSubjAll(FNewCert);
    end;

  { Issuer Alternative Name. }
    if FAltIssuer <> '' then begin
        SetCertExt(FNewCert, NID_issuer_alt_name, AnsiString(FAltIssuer));
    end;

  { CRL distribution points - URI:http://myhost.com/myca.crl }
    if FCRLDistPoint <> '' then begin
        SetCertExt(FNewCert, NID_crl_distribution_points, AnsiString(FCRLDistPoint));
    end;

  { Authority Info Access - OCSP;URI:http://ocsp.myhost.com/ }
    if FAuthInfoAcc <> '' then begin
        SetCertExt(FNewCert, NID_info_access, AnsiString(FAuthInfoAcc));
    end;

  { V8.62 acmeIdentifier "1.3.6.1.5.5.7.1.31" or OBJ_id_pe,31L, dynamically created NID,
    expecting binary sha256 digest in hex }
//    if Length(FAcmeIdentifier) = 64 then begin
    if Length(FAcmeIdentifier) > 0 then begin
        SetCertExt(FNewCert, ICS_NID_acmeIdentifier,
                        AnsiString('critical,DER:04:20:' + FAcmeIdentifier));  // octet string(4), 32 long, converted from hex to binary
//                            AnsiString('critical,DER:' + FAcmeIdentifier));  // octet string(4), 32 long, converted from hex to binary
    end;

  { self sign it with our key and hash digest }
    if f_EVP_PKEY_base_id(PrivateKey) = EVP_PKEY_ED25519 then begin   { V8.51 no digest for EVP_PKEY_ED25519 }
        if f_X509_sign(FNewCert, PrivateKey, Nil) = 0 then
            RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to sign certifcate with ED25519 key');
    end
    else begin
        if f_X509_sign(FNewCert, PrivateKey, IcsSslGetEVPDigest(FCertDigest)) <= 0 then
            RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to sign certificate with digest');
    end;
    SetX509(FNewCert);

  { add certificate to our database ? }
  { note this is done in OverbyteIcsSslX509Certs }
 end;


 {* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslCertTools.SaveToCADatabase(const CertFName: String = 'unknown'): Boolean;
var
    FStream: TFileStream;
    CertRec: String;
const
  DateTimeMask = 'yymmddhhnnss"Z"';
begin
    Result := False;
    if FCADBFile = '' then Exit;
    if NOT IsCertLoaded then Exit;

// CA database record, similar to OpenSSL but with SANs on the end
// 1 - status - V=valid, R=revoked, E=expired
// 2 - cert expire date
// 3 - cert revoked date (empty is not)
// 4 - serial number in hex
// 5 - cert file name or 'unknown'
// 6 - cert subject including common name
// 7 - cert subject alternate names
    CertRec := 'V' + IcsTAB + FormatDateTime(DateTimeMask, ValidNotAfter) +
      IcsTAB + {no revoke data } IcsTAB + SerialNumHex + IcsTAB + CertFName +
      IcsTAB + SubjectOneLine + IcsTAB + IcsUnwrapNames(GetSubjectAltName.Value) + icsCRLF;
        //  IcsUnwrapNames(SubAltNameDNS) + icsCRLF;

    if NOT ForceDirectories (ExtractFileDir (FCADBFile)) then
        raise ECertToolsException.Create('Failed to create CA DB Directory: ' + FCADBFile);
    FStream := Nil;
    try
        if NOT FileExists((FCADBFile)) then
            FStream := TFileStream.Create (FCADBFile, fmCreate)
        else begin
            FStream := TFileStream.Create (FCADBFile, fmOpenReadWrite OR fmShareDenyWrite);
            FStream.Seek(0, soEnd);
        end;
        FStream.WriteBuffer(AnsiString(CertRec) [1], Length (CertRec));
        Result := True;
    finally
        FStream.Free;
    end;
end ;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ create a new CA signed certificate from a certificate request }
{ need to create a CA certificate (X509CA) and private key (PrivKeyCA) first }
{ not finished, does not copy extensions }
procedure TSslCertTools.DoSignCertReq(CopyExtns: Boolean);
var
    SubjName  : PX509_NAME;
    TempSerial : ULARGE_INTEGER; { V8.42 was TULargeInteger } { 64-bit integer record }
begin
    InitializeSsl;
    if NOT Assigned(FX509CA) then
        raise ECertToolsException.Create('Must open CA certificate first');
    if NOT Assigned(FX509Req) then
        raise ECertToolsException.Create('Must open certificate request first');
    if NOT Assigned(FPrivKeyCA) then
        raise ECertToolsException.Create('Must open CA private key first');
    if f_X509_check_private_key(FX509CA, FPrivKeyCA) = 0 then
        raise ECertToolsException.Create('CA certificate and private key do not match');
    if (ICS_OPENSSL_VERSION_NUMBER < OSSL_VER_1101) and (FCertDigest >= Digest_sha3_224) then   { V8.51 }
        raise ECertToolsException.Create('SHA3 hashes not supported');


    if Assigned(FNewCert) then f_X509_free(FNewCert);
    FNewCert := f_X509_new;
    if NOT Assigned(FNewCert) then
         RaiseLastOpenSslError(ECertToolsException, FALSE, 'Can not create new X509 object');

   { set version, serial number, expiry and public key }
    if f_X509_set_version(FNewCert, 2) = 0 then  { version 3}
        RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to set version to certificate');
    if FSerialNum = 0 then begin
        TempSerial.LowPart := IcsRandomInt($7FFFFFFF);
        TempSerial.HighPart := IcsRandomInt($7FFFFFFF);
        FSerialNum := TempSerial.QuadPart;
    end;
    if FExpireDays < 7 then FExpireDays := 7;   { V8.62 was 30 }
    if f_ASN1_INTEGER_set_int64(f_X509_get_serialNumber(FNewCert), FSerialNum) = 0 then
        RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to set serial num');
    f_X509_gmtime_adj(f_Ics_X509_get_notBefore(FNewCert), 0);
    f_X509_gmtime_adj(f_Ics_X509_get_notAfter(FNewCert), 60 * 60 * 24 * FExpireDays);

  { public key from request, not CA }
    if f_X509_set_pubkey(FNewCert, f_X509_REQ_get0_pubkey(X509Req)) = 0 then
        RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to set public key to certificate');

  { set the cert subject name to the request subject }
    SubjName := f_X509_NAME_dup(f_ics_X509_REQ_get_subject_name(X509Req));
    if NOT Assigned(SubjName) or (f_X509_set_subject_name(FNewCert, SubjName) = 0) then
        RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to set subject from request');

  { set the issuer name to CA subject }
    if f_X509_set_issuer_name(FNewCert, f_X509_get_subject_name(FX509CA)) = 0 then
        RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to set issuer from CA');

  { set extensions }

  { Add basic contraints }
    SetCertExt(FNewCert, NID_basic_constraints, BuildBasicCons(FBasicIsCA));

     if NOT CopyExtns then begin

      { subject alternate names }
      { V8.64 add DNS, IPs and emails together, previously only one }
        BuildAltPropList;
        BuildCertAltSubjAll(FNewCert);

     { Key usage }
        SetCertExt(FNewCert, NID_key_usage, BuildKeyUsage);

    { Extended Key usage }
        SetCertExt(FNewCert, NID_ext_key_usage, BuildExKeyUsage);

    end
    else begin
     { copy some extension from request to certificate }
        BuildAltReqList;  { V8.64 }
        BuildCertAltSubjAll(FNewCert); { V8.64 }

     { Key usage }
        SetCertExt(FNewCert, NID_key_usage, AnsiString(IcsUnwrapNames(ReqKeyUsage)));

    { Extended Key usage }
        SetCertExt(FNewCert, NID_ext_key_usage, AnsiString(IcsUnwrapNames(ReqExKeyUsage)));

    end;

  { Sign it with CA certificate and hash digest }
     if f_EVP_PKEY_base_id(FPrivKeyCA) = EVP_PKEY_ED25519 then begin   { V8.51 no digest for EVP_PKEY_ED25519 }
        if f_X509_sign(FNewCert, FPrivKeyCA, Nil) = 0 then
            RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to sign certifcate with ED25519 key');
    end
    else begin
       if f_X509_sign(FNewCert, FPrivKeyCA, IcsSslGetEVPDigest(FCertDigest)) <= 0 then
        RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to sign certificate with digest');
    end;
    SetX509(FNewCert);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function BNGENCBcallFunc(p: Integer; n: Integer; cb: PBN_GENCB): Integer; cdecl;
var
//    c: AnsiChar;
    Arg: Pointer;
    CertTools: TSslCertTools;
begin
    result := 1; // success, will 0 cause the function to fail??
    if NOT Assigned(cb) then Exit;
    try
        Arg := f_BN_GENCB_get_arg(cb);
        if NOT Assigned (Arg) then exit;
        CertTools := TSslCertTools(Arg);
        with CertTools do begin
          { good idea to call ProcessMessages in event so program remains responsive!!! }
            if Assigned(CertTools.FOnKeyProgress) then
                    CertTools.FOnKeyProgress(CertTools);
        end;
    except
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function EVPPKEYCBcallFunc(pctx: PEVP_PKEY_CTX): Integer; cdecl;
var
    Arg: Pointer;
    CertTools: TSslCertTools;
begin
    result := 1; // success, will 0 cause the function to fail??
    if NOT Assigned(pctx) then Exit;
    try
        Arg := f_EVP_PKEY_CTX_get_app_data(pctx);
        if NOT Assigned (Arg) then exit;
        CertTools := TSslCertTools(Arg);
        with CertTools do begin
          { good idea to call ProcessMessages in event so program remains responsive!!! }
            if Assigned(CertTools.FOnKeyProgress) then
                    CertTools.FOnKeyProgress(CertTools);
        end;
    except
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ Creating a key pair is the first step in creating X509 certificates.  }
{ The private key must be kept secure and never distributed, it will be }
{ needed to use the X509 certificate with an SSL server or client, to sign }
{ X509 certificate requests or self signed X509 certificates or to sign }
{ other documents.  The public key may be extracted from the private key. }
{ The public key is added to the X509 certificate and request and is not
{ normally needed as a separate file }
{ This method creates a new key pair in Privatekey using RSA or EC
{ Elliptic Curve) methods with varying key sizes according to the PrivKeyType
{ property. Various SaveTo methods may be used to write the keys to files, }
{ optionally encrypted with a password to protect it.   }
procedure TSslCertTools.DoKeyPair;
var
    Bits, KeyNid, CurveNid: Integer;
    Pctx: PEVP_PKEY_CTX;      { V8.49 total rewrite uising these methods }
    KeyInfo: string;
begin
    InitializeSsl;
    if NOT ICS_RAND_INIT_DONE then IcsRandPoll;
 //   callback := Nil;

 { note private keys can use DSA, but this is now obsolete }
    if Assigned(FPrivKey) then
        f_EVP_PKEY_free(FPrivKey);   { V8.49 free and new }
    FPrivKey := Nil;

    CurveNid := 0;
    Bits := 0;
    if (FPrivKeyType >= PrivKeyRsa1024) and (FPrivKeyType <= PrivKeyRsa15360) then begin
        KeyNid := EVP_PKEY_RSA;
        KeyInfo := 'RSA';
        case FPrivKeyType of
            PrivKeyRsa1024:  Bits := 1024;
            PrivKeyRsa2048:  Bits := 2048;
            PrivKeyRsa3072:  Bits := 3072;
            PrivKeyRsa4096:  Bits := 4096;
            PrivKeyRsa7680:  Bits := 7680;
            PrivKeyRsa15360: Bits := 15360;
        else
            Bits := 2048;
        end;
    end
    else if (FPrivKeyType = PrivKeyEd25519) then begin   { V8.50 needs OpenSSL 1.1.1 }
        KeyNid := EVP_PKEY_ED25519;
        KeyInfo := 'ED25519';
    end
    else if (FPrivKeyType >= PrivKeyRsaPss2048) and (FPrivKeyType <= PrivKeyRsaPss15360) then begin    { V8.51 needs OpenSSL 1.1.1 }
        KeyNid := EVP_PKEY_RSA_PSS;
        KeyInfo := 'RSA-PSS';
        case FPrivKeyType of
            PrivKeyRsaPss2048:  Bits := 2048;
            PrivKeyRsaPss3072:  Bits := 3072;
            PrivKeyRsaPss4096:  Bits := 4096;
            PrivKeyRsaPss7680:  Bits := 7680;
            PrivKeyRsaPss15360: Bits := 15360;
        else
            Bits := 2048;
        end;
    end
    else if (FPrivKeyType >= PrivKeyECsecp256) and (FPrivKeyType <= PrivKeyECsecp512) then begin
        KeyNid := EVP_PKEY_EC;
        KeyInfo := 'EC';
        case FPrivKeyType of
            PrivKeyECsecp256:  CurveNid := NID_X9_62_prime256v1;
            PrivKeyECsecp384:  CurveNid := NID_secp384r1;
            PrivKeyECsecp512:  CurveNid := NID_secp521r1;
            else
                CurveNid := NID_X9_62_prime256v1;
        end;
    end
    else begin
        RaiseLastOpenSslError(ECertToolsException, true, 'Unknown Private Key Type');  { V8.64 need an error }
        Exit;
    end;

 { initialise context for private keys }
    Pctx := f_EVP_PKEY_CTX_new_id(KeyNid, Nil);
    if NOT Assigned(Pctx) then
            RaiseLastOpenSslError(ECertToolsException, true, 'Failed to create new ' + KeyInfo + ' key');
    if f_EVP_PKEY_keygen_init(Pctx) = 0 then
            RaiseLastOpenSslError(ECertToolsException, true, 'Failed to init ' + KeyInfo + ' keygen');
    if (KeyNid = EVP_PKEY_RSA) or (KeyNid = EVP_PKEY_RSA_PSS) then begin
        if (Bits > 0) and (f_EVP_PKEY_CTX_set_rsa_keygen_bits(Pctx, Bits) = 0) then
            RaiseLastOpenSslError(ECertToolsException, true, 'Failed to set RSA bits');
         // f_EVP_PKEY_CTX_set_rsa_padding
         // f_EVP_PKEY_CTX_set_signature_md
    end;
    if (CurveNid > 0) and (f_EVP_PKEY_CTX_set_ec_paramgen_curve_nid(Pctx, CurveNid) = 0) then
                RaiseLastOpenSslError(ECertToolsException, true, 'Failed to set EC curve');
    if (KeyNid = EVP_PKEY_RSA_PSS) then begin
        // pending - various macros to restrict digests, MGF1 and minimum salt length
        // f_EVP_PKEY_CTX_set_rsa_pss_keygen_md
        // f_EVP_PKEY_CTX_set_rsa_pss_saltlen
        // f_EVP_PKEY_CTX_set_rsa_pss_keygen_mgf1_md
    end;


  { progress callback, really only needed for slow RSA }
    f_EVP_PKEY_CTX_set_app_data(Pctx, Self);
    f_EVP_PKEY_CTX_set_cb(Pctx, @EVPPKEYCBcallFunc);

  { generate private key pair }
    if f_EVP_PKEY_keygen(Pctx, FPrivKey) = 0 then
            RaiseLastOpenSslError(ECertToolsException, true, 'Failed to generate ' + KeyInfo + ' key');
    if NOT Assigned(FPrivKey) then
            RaiseLastOpenSslError(ECertToolsException, true, 'Failed to create new ' + KeyInfo + ' key, empty');
    SetPrivateKey(FPrivKey);
    f_EVP_PKEY_CTX_free(Pctx);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ Old version that uses lower level functions, may still be useful }
(*
procedure TSslCertTools.DoKeyPairOld;
var
    Bne       : PBIGNUM;
    Ret, Bits, Nid  : Integer;
    callback  : PBN_GENCB;
const
    OPENSSL_EC_EXPLICIT_CURVE = 0;
    OPENSSL_EC_NAMED_CURVE    = 1;
begin
    InitializeSsl;
    if NOT ICS_RAND_INIT_DONE then IcsRandPoll;
    callback := Nil;

 { note private keys can use DSA, but this is now obsolete }
    if Assigned(FPrivKey) then
        f_EVP_PKEY_free(FPrivKey);   { V8.49 free and new }
    FPrivKey := f_EVP_PKEY_new;
    if NOT Assigned(FPrivKey) then
           RaiseLastOpenSslError(ECertToolsException, true, 'Failed to create new private key');

 { new RSA private and public key pair }
    if (FPrivKeyType >= PrivKeyRsa1024) and (FPrivKeyType <= PrivKeyRsa15360) then begin
        case FPrivKeyType of
            PrivKeyRsa1024:  Bits := 1024;
            PrivKeyRsa2048:  Bits := 2048;
            PrivKeyRsa3072:  Bits := 3072;
            PrivKeyRsa4096:  Bits := 4096;
            PrivKeyRsa7680:  Bits := 7680;
            PrivKeyRsa15360: Bits := 15360;
        else
            Bits := 2048;
        end;

      { generate fixed odd number exponent }
        Bne := f_BN_new;
        if f_BN_set_word(Bne, RSA_F4) = 0 then
                RaiseLastOpenSslError(ECertToolsException, true, 'Failed to create RSA exponent');
        if NOT Assigned(FRsaKey) then
            FRsaKey := f_RSA_new;
        if NOT Assigned(FRsaKey) then
                RaiseLastOpenSslError(ECertToolsException, true, 'Failed to create new RSA key');
        try
          { create progress callback }
            if ICS_OPENSSL_VERSION_NUMBER >= OSSL_VER_1100 then begin
                callback := f_BN_GENCB_new;
                if Assigned(callback) then
                    f_BN_GENCB_set(callback, @BNGENCBcallFunc, Self);
            end;

          { generate RSA key pair }
            Ret := f_RSA_generate_key_ex (FRsaKey, Bits, Bne, callback);
            if (Ret = 0) or (not Assigned(FRsaKey)) then
                RaiseLastOpenSslError(ECertToolsException, true, 'Failed to generate RSA key');

          { assign them to Private key structure }
            if f_EVP_PKEY_assign(FPrivKey, EVP_PKEY_RSA, PAnsiChar(FRsaKey)) = 0 then
                RaiseLastOpenSslError(ECertToolsException, true, 'Failed to assign RSA key to key object');
            SetPrivateKey(FPrivKey);
        finally
           if Assigned(Bne) then
                f_BN_free(Bne);
            if Assigned (callback) then
                f_BN_GENCB_free(callback);
         end;
    end;

 { new Elliptic Curve private and public key pair for ECDSA certificates }
    if (FPrivKeyType >= PrivKeyECsecp256) and (FPrivKeyType <= PrivKeyECsecp512) then begin
        case FPrivKeyType of
            PrivKeyECsecp256:  Nid := NID_X9_62_prime256v1;
            PrivKeyECsecp384:  Nid := NID_secp384r1;
            PrivKeyECsecp512:  Nid := NID_secp521r1;
            else
                Nid := NID_X9_62_prime256v1;
        end;
   //     if Assigned (FECkey) then
   //         f_EC_KEY_free(FECKey);  // does not seem to work!!!
        if Assigned (FECgroup) then
            f_EC_GROUP_free(FECgroup);
        FECgroup := Nil;
        FECkey := f_EC_KEY_new;
        if NOT Assigned (FECkey) then
                RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to create new EC key');

     { create group first with curve }
        FECgroup := f_EC_GROUP_new_by_curve_name(Nid);
        if NOT Assigned (FECgroup) then
            RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to create new EC curve');
        f_EC_GROUP_set_asn1_flag(FECgroup, OPENSSL_EC_NAMED_CURVE);

      { assign group to EC key, generate public and private key pair }
        if f_EC_KEY_set_group(FECkey, FECgroup) = 0 then
            RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to assign EC group to key');
        if f_EC_KEY_generate_key(FECkey) = 0 then
            RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to generate EC key');
        if f_EVP_PKEY_assign(FPrivKey, EVP_PKEY_EC, PAnsiChar(FECkey)) = 0 then
            RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to assign EC key to key object');
        SetPrivateKey(FPrivKey);
    end;
end;  *)


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ This method creates DHParams which are needed by servers using DH and DHE
{ key exchange (but not for ECDH and ECDHE).  DHParams are usually created once }
{ for a server or application, if they become known it can speed up cracking. }
{ This method only needs a length and output file name specified. }
{ Beware, very time consuming, 1024 less than a min, 2048 few mins, 4096 few hours, }
{ 8192 gave up after two days, so use the OnKeyProgress event to to call }
{ ProcessMessages in event so program remains responsive!!!   }
function TSslCertTools.DoDHParams(const FileName: String; Bits: integer): String;
var
    FileBio   : PBIO;
    DhParam   : PDH;
    Ret, Err, Len : Integer;
    callback  : PBN_GENCB;
    AStr      : AnsiString;
begin
    InitializeSsl;
    callback := Nil;
    result := '';
    DhParam := Nil;
    FileBio := IcsSslOpenFileBio(FileName, bomWrite);
    if NOT Assigned(FileBio) then
            RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to open file = ' + FileName);
    try
      { create progress callback }
        if ICS_OPENSSL_VERSION_NUMBER >= OSSL_VER_1100 then begin
            callback := f_BN_GENCB_new;
            if Assigned(callback) then
                f_BN_GENCB_set(callback, @BNGENCBcallFunc, Self);
        end;

      { generate DHParams }
        DhParam := f_DH_new;
        Ret := f_DH_generate_parameters_ex(DhParam, Bits, 2, callback);
        if (Ret = 0) then
            RaiseLastOpenSslError(ECertToolsException, FALSE, 'Failed to generate DHParams');
        Ret := f_DH_check(DhParam, Err);
        if (Ret = 0) then
            RaiseLastOpenSslError(ECertToolsException, FALSE,
                'Failed to check DHParams, Error ' + IntToHex (Err, 8));

        ret := f_PEM_write_bio_DHparams(FileBio, DhParam);
        if ret = 0 then
            RaiseLastOpenSslError(EX509Exception, TRUE,
                                  'Error writing DHParams to ' + FileName);
        f_BIO_free(FileBIO);

      { now save params again to string }
        FileBio := f_BIO_new(f_BIO_s_mem);
        if Assigned(FileBio) then begin
            f_PEM_write_bio_DHparams(FileBio, DhParam);
            Len := f_BIO_ctrl(FileBio, BIO_CTRL_PENDING, 0, nil);
            SetLength(AStr, Len);
            if Len > 0 then begin
                f_Bio_read(FileBio, PAnsiChar(AStr), Len);
                SetLength(AStr, StrLen(PAnsiChar(AStr)));
                Result := String(AStr);
            end;
        end;

    finally
        if Assigned(FileBIO) then
            f_BIO_free(FileBIO);
        if Assigned(DhParam) then
            f_DH_free(DhParam);
        if Assigned (callback) then
            f_BN_GENCB_free(callback);
    end;

end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslCertTools.DoClearCerts;
begin
    InitializeSsl;
    X509 := Nil;
    PrivateKey := Nil;
    X509Req := Nil;
    X509Inters := Nil;
    FreeAndNilX509Req;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslCertTools.DoClearCA;  { V8.57 split from DoClearCerts }
begin
    InitializeSsl;
    FreeAndNilX509CA;
    FreeAndNilPrivKeyCA;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ method to create an SSL server certificate bundle file with an SSL certificate,
  matching public key and optional itermediate certificate(s), to avoid
  distributing and loading them all separately, output file format is determined
  by the file extension, PEM, PFX or P12 - no others can have cert and pkey }
procedure TSslCertTools.CreateCertBundle(const CertFile, PKeyFile, InterFile, LoadPw,
                      SaveFile, SavePw: String; KeyCipher: TSslPrivKeyCipher = PrivKeyEncNone);
begin
    ClearAll;
    LoadFromFile(CertFile, croNo, croTry, '');
    if NOT IsCertLoaded then
        raise Exception.Create('No certificate found 9n file');
    PrivateKeyLoadFromPemFile(PKeyFile, LoadPw);
    if InterFile <> '' then
        LoadIntersFromPemFile(InterFile);
    SaveToFile(SaveFile, true, true, IsInterLoaded, SavePw, KeyCipher);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

{ V8.41 replaced old code with TSslCertTools component }
procedure CreateSelfSignedCert(const FileName, Country, State,
  Locality, Organization, OUnit, CName, Email: String; Bits: Integer;
  IsCA: Boolean; Days: Integer;
  const KeyFileName: String = ''; Comment: boolean = false);
var
    MySslCertTools: TSslCertTools;
    KeyType: TSslPrivKeyType;
begin
    MySslCertTools := TSslCertTools.Create(nil);
    try
        MySslCertTools.Country        := Country;
        MySslCertTools.State          := State;
        MySslCertTools.Locality       := Locality;
        MySslCertTools.Organization   := Organization;
        MySslCertTools.OrgUnit        := OUnit;
        MySslCertTools.Email          := EMail;
        MySslCertTools.CommonName     := CName;
        MySslCertTools.BasicIsCA      := IsCA;
        MySslCertTools.ExpireDays     := Days;   { V8.64 got lost }
        if Bits > 4096 then
            KeyType := PrivKeyRsa7680
        else if Bits > 3072 then
            KeyType := PrivKeyRsa4096
        else if Bits > 2048 then
            KeyType := PrivKeyRsa3072
        else if Bits > 1024 then
            KeyType := PrivKeyRsa2048
        else
            KeyType := PrivKeyRsa1024;
        MySslCertTools.PrivKeyType := KeyType;

      { create private and public key, then create SSL certificate }
        MySslCertTools.DoKeyPair;
        MySslCertTools.DoSelfSignCert;

      { now save them to PEM files - no passwords }
        if KeyFileName <> '' then begin
            MySslCertTools.PrivateKeySaveToPemFile(KeyFileName);
            MySslCertTools.SaveToPemFile(FileName, False, Comment, False);
        end
        else begin
            MySslCertTools.SaveToPemFile(FileName, True, Comment, False);
       end;
    finally
        MySslCertTools.Free;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// create a self signed certificate with subject alternative names, specific
// private key, optionally with ACME tls-alpn-01 challenge identifier
// used by TSocketServer to create certificate if missing so it can start-up
procedure CreateSelfSignCertEx(const FileName, CName: String; AltDNSLst: TStrings;
        PKeyType: TSslPrivKeyType = PrivKeyECsecp256; const PW: String = '';
                                                      const AcmeId: String = '');  { V8.64 }
var
    MySslCertTools: TSslCertTools;
    PrivKeyType: TSslPrivKeyCipher;
begin
    MySslCertTools := TSslCertTools.Create(nil);
    try
        MySslCertTools.CommonName := CName;
        if Assigned(AltDNSLst) then
            MySslCertTools.AltDNSList.Assign(AltDNSLst)
        else
            MySslCertTools.AltDNSList.Add(CName);
        MySslCertTools.AcmeIdentifier := AcmeId;
        MySslCertTools.BasicIsCA := False;
        MySslCertTools.PrivKeyType := PKeyType;
        if AcmeId <> '' then
            MySslCertTools.ExpireDays := 7
        else
            MySslCertTools.ExpireDays := 2000;
        MySslCertTools.KeyCertSign := true;
        MySslCertTools.KeyDigiSign := true;
        MySslCertTools.KeyNonRepud := true;
        MySslCertTools.KeyKeyEnc := true;
        MySslCertTools.KeyExtServer := true;

      { create private and public key, then create SSL certificate }
        MySslCertTools.DoKeyPair;
        MySslCertTools.DoSelfSignCert;

      { now save them to file - no password unless PKX }
        PrivKeyType := PrivKeyEncNone;
        if PW <> '' then PrivKeyType := PrivKeyEncTripleDES;
        MySslCertTools.SaveToFile(FileName, True, True, False, PW, PrivKeyType);
    finally
        MySslCertTools.Free;
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ V8.41 replaced old code with TSslCertTools component }
procedure CreateCertRequest(const RequestFileName, KeyFileName, Country,
  State, Locality, Organization, OUnit, CName, Email: String;
  Bits: Integer; Comment: boolean = false);
var
    MySslCertTools: TSslCertTools;
    KeyType: TSslPrivKeyType;
begin
    MySslCertTools := TSslCertTools.Create(nil);
    try
        MySslCertTools.Country        := Country;
        MySslCertTools.State          := State;
        MySslCertTools.Locality       := Locality;
        MySslCertTools.Organization   := Organization;
        MySslCertTools.OrgUnit        := OUnit;
        MySslCertTools.Email          := EMail;
        MySslCertTools.CommonName     := CName;
        if Bits > 4096 then
            KeyType := PrivKeyRsa7680
        else if Bits > 3072 then
            KeyType := PrivKeyRsa4096
        else if Bits > 2048 then
            KeyType := PrivKeyRsa3072
        else if Bits > 1024 then
            KeyType := PrivKeyRsa2048
        else
            KeyType := PrivKeyRsa1024;
        MySslCertTools.PrivKeyType := KeyType;

      { create private and public key, then create certificate request }
        MySslCertTools.DoKeyPair;
        MySslCertTools.DoCertReqProps;

      { now save them to PEM files - no passwords }
        MySslCertTools.PrivateKeySaveToPemFile(KeyFileName);
        MySslCertTools.SaveReqToFile(RequestFileName, Comment);
    finally
        MySslCertTools.Free;
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function EncryptPublicRSA(
    PubKey      : PEVP_PKEY;
    InBuf       : Pointer;
    InLen       : Cardinal;
    OutBuf      : Pointer;
    var OutLen  : Cardinal;
    Padding     : TRsaPadding): Boolean;
var
    Bytes     : Word;
    MaxBytes  : Word;
    BlockSize : Word;
    BytesRet  : Integer;
    InBufPtr  : PAnsiChar;
    OutBufPtr : PAnsiChar;
    PadSize   : Byte;
    IntPad    : Integer;
begin
    Result := FALSE;
  {  if not LibeayExLoaded then
        LoadLibeayEx;   }
    if not Assigned(PubKey) then
        raise Exception.Create('Public key not assigned');
    if Ics_Ssl_EVP_PKEY_GetType(PubKey) <> EVP_PKEY_RSA then
        raise Exception.Create('No RSA key');
    if (InBuf = nil) or (InLen = 0) then
        raise Exception.Create('Invalid input buffer');
    case Padding of
      rpNoPadding :
          begin
              IntPad := RSA_NO_PADDING;
              PadSize := 0;
          end;
      rpPkcs1Oaep :
          begin
              IntPad := RSA_PKCS1_OAEP_PADDING;
              PadSize := RSA_PKCS1_OAEP_PADDING_SIZE;
          end;
      else
        IntPad := RSA_PKCS1_PADDING;
        PadSize := RSA_PKCS1_PADDING_SIZE;
    end;
    BlockSize := f_EVP_PKEY_size(PubKey);
    MaxBytes := BlockSize - PadSize;
    { Calculate the required result buffer size }
    if InLen <= MaxBytes then
        BytesRet := BlockSize
    else
        BytesRet := (InLen div MaxBytes + 1) * BlockSize;
    if (OutLen = 0) or (OutBuf = nil) or
       (Integer(OutLen) < BytesRet) then begin
       { Return required size and exit }
        OutLen := BytesRet;
        Exit; //***
    end;
    InBufPtr  := InBuf;
    OutBufPtr := OutBuf;
    OutLen   := 0;
    repeat
        if InLen > MaxBytes then
            Bytes := MaxBytes
        else
            Bytes := InLen;
        if Bytes > 0 then begin
            BytesRet := f_RSA_public_encrypt(
                                            Bytes,
                                            InBufPtr,
                                            OutBufPtr,
                                            Ics_Ssl_EVP_PKEY_GetKey(PubKey),
                                            IntPad);
            if BytesRet <> BlockSize then
            begin
                if BytesRet = -1 then
                    RaiseLastOpenSslError(Exception, TRUE,
                                          'Function f_RSA_public_encrypt:')
                else
                    raise Exception.Create('f_RSA_public_encrypt: ' +
                                        'Ciphertext must match length of key');
            end;
            Dec(InLen, Bytes);
            Inc(InBufPtr, Bytes);
            Inc(OutBufPtr, BytesRet);
            Inc(OutLen, BytesRet);
        end;
    until InLen = 0;
    Result := TRUE;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function DecryptPrivateRSA(
    PrivKey     : PEVP_PKEY;
    InBuf       : Pointer;
    InLen       : Cardinal;
    OutBuf      : Pointer;
    var OutLen  : Cardinal;
    Padding     : TRsaPadding): Boolean;
var
    Bytes     : Word;
    BlockSize : Word;
    BytesRet  : Integer;
    InBufPtr  : PAnsiChar;
    OutBufPtr : PAnsiChar;
    IntPad    : Integer;
begin
    Result := FALSE;
  {  if not LibeayExLoaded then
        LoadLibeayEx;    }
    if PrivKey = nil then
        raise Exception.Create('Private key not loaded');
    if Ics_Ssl_EVP_PKEY_GetType(PrivKey) <> EVP_PKEY_RSA then
        raise Exception.Create('No RSA key');
    if (InBuf = nil) or (InLen = 0) then
        raise Exception.Create('Invalid input buffer');
    if (OutLen = 0) or (OutBuf = nil) or
       (InLen > OutLen) then begin
       { Return required size and exit }
        OutLen := InLen;
        Exit; //***
    end;
    case Padding of
      rpNoPadding : IntPad := RSA_NO_PADDING;
      rpPkcs1Oaep : IntPad := RSA_PKCS1_OAEP_PADDING;
      else
        IntPad := RSA_PKCS1_PADDING;
    end;
    Blocksize := f_EVP_PKEY_size(PrivKey);
    OutLen    := 0;
    InBufPtr  := InBuf;
    OutBufPtr := OutBuf;
    repeat
        if InLen > BlockSize then
            Bytes := BlockSize
        else
            Bytes := InLen;
        if Bytes > 0 then begin
            BytesRet := f_RSA_private_decrypt(
                                             Bytes,
                                             InBufPtr,
                                             OutBufPtr,
                                             Ics_Ssl_EVP_PKEY_GetKey(PrivKey),
                                             IntPad);
            if BytesRet = -1 then
                RaiseLastOpenSslError(Exception, TRUE,
                                      'Function f_RSA_private_decrypt:');
            Dec(InLen, Bytes);
            Inc(InBufPtr, Bytes);
            Inc(OutBufPtr, BytesRet);
            Inc(OutLen, BytesRet);
        end;
    until InLen = 0;
    Result := TRUE;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ Takes plain text, returns an encrypted and base64 encoded string }
function StrEncRsa(
    PubKey  : PEVP_PKEY;
    const S : AnsiString;
    B64     : Boolean;
    Padding : TRsaPadding = rpPkcs1): AnsiString;
var
    Len : Cardinal;
begin
    { First call is to get return buffer size }
    EncryptPublicRSA(PubKey, PAnsiChar(S), Length(S), nil, Len, Padding);
    SetLength(Result, Len);
    if EncryptPublicRSA(PubKey, PAnsiChar(S), Length(S), PAnsiChar(Result), Len, Padding) then
    begin
        if B64 then
            Result := Base64Encode(Result);
    end
    else
        SetLength(Result, 0);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ Takes an encryted and base64 encoded string, returns plain text }
function StrDecRsa(
    PrivKey : PEVP_PKEY;
    S       : AnsiString;
    B64     : Boolean;
    Padding : TRsaPadding = rpPkcs1): AnsiString;
var
    Len : Cardinal;
begin
    if B64 then
        S := Base64Decode(S);
    Len := Length(S);
    SetLength(Result, Len);
    if DecryptPrivateRSA(PrivKey, PAnsiChar(S), Len, PAnsiChar(Result), Len, Padding) then
        { Adjust string length! }
        SetLength(Result, Len)
    else
        SetLength(Result, 0);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure CiphFinalize(var CiphCtx: TCiphContext);
begin
    if Assigned(CiphCtx.Ctx) then begin
        f_EVP_CIPHER_CTX_cleanup(CiphCtx.Ctx);
        f_EVP_CIPHER_CTX_free(CiphCtx.Ctx);
    end;
    FillChar(CiphCtx, SizeOf(CiphCtx), #0);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure CalcMD5(
    Buffer: Pointer;
    BufSize: Integer;
    MD5Digest : PMD5Digest);
var
    I          : Integer;
    MD5Context : TMD5Context;
begin
    for I := 0 to 15 do
        MD5Digest^[I] := I + 1;
    MD5Init(MD5Context);
    MD5UpdateBuffer(MD5Context, Buffer, BufSize);
    MD5Final(MD5Digest^, MD5Context);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure CiphPasswordToKey(
    InBuf       : AnsiString;
    Salt        : TCipherSalt;
    Count       : Integer;
    var Key     : TCipherKey;
    var KeyLen  : Integer;
    var IV      : TIVector;
    var IVLen   : Integer);
var
    I, nKey, nIV : Integer;
    MD5Digest  : TMD5Digest;
    MD5Context : TMD5Context;
    AddDigest  : Boolean;
begin
    FillChar(Key, SizeOf(TCipherKey), #0);
    FillChar(IV, SizeOf(TIVector), #0);
    if (KeyLen = 0) or (Length(InBuf)= 0) then Exit;
    if KeyLen > SizeOf(TCipherKey) then
        KeyLen := SizeOf(TCipherKey);
    nKey := 0;
    nIV  := 0;
    AddDigest := False;
    for I := 0 to 15 do
        MD5Digest[I] := I + 1;
    while True do
    begin
       MD5Init(MD5Context);
       if AddDigest then
          MD5UpdateBuffer(MD5Context, @MD5Digest[0], SizeOf(MD5Digest))
       else
          AddDigest := TRUE;
       MD5UpdateBuffer(MD5Context, @InBuf[1], Length(InBuf));
       if Length(Salt) > 0 then
            MD5UpdateBuffer(MD5Context, @Salt[1], Length(Salt));
       MD5Final(MD5Digest, MD5Context);
       for I := 1 to Count do begin
          MD5Init(MD5Context);
          MD5UpdateBuffer(MD5Context, @MD5Digest[0], SizeOf(MD5Digest));
          MD5Final(MD5Digest, MD5Context);
       end;
       I := 0;
       if nKey <= KeyLen then
       begin
           while True do
           begin
              if (nKey > KeyLen) or (I > SizeOf(MD5Digest)) then
                  Break;
              Key[nKey] := MD5Digest[I];
              Inc(nkey);
              Inc(I);
           end;
       end;
       if nIV <= IVLen then
       begin
           while True do
           begin
              if (nIV > IVLen) or (I > SizeOf(MD5Digest)) then
                  Break;
              IV[nIV] := MD5Digest[I];
              Inc(nIV);
              Inc(I);
           end;
       end;
       if (nKey > KeyLen) and (nIV > IVLen) then Break;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure CiphInitialize(
    var CiphCtx : TCiphContext;
    const Pwd   : AnsiString;
    Key         : PCipherKey; // if not nil Pwd is ignored and the user is responsible to provide a valid Key and IV
    IVector     : PIVector;
    CipherType  : TCipherType;
    KeyLen      : TCipherKeyLen;
    Enc         : Boolean);
var
    SetKeySize  : Integer;
    //I           : Integer;
    PIV         : Pointer;
    KLen, IVLen : Integer;
begin
 {   if not LibeayExLoaded then
        LoadLibeayEx;   }
    SetKeySize := 0;
    KLen := 0;
    CiphFinalize(CiphCtx);
    CiphCtx.Encrypt := Enc;
    case CipherType of
        ctBfCbc, {ctBfCfb64,} ctBfOfb, ctBfEcb :
          { Blowfish keysize 32-448 bits in steps of 8 bits, default 128 bits }
            begin
                CiphCtx.BlockSize := BF_BLOCK_SIZE;
                IVLen := SizeOf(TIVector);
                case KeyLen of
                  cklDefault, ckl128bit : KLen := 16;
                  ckl64bit  : begin Klen := 8; SetKeySize := KLen; end;
                  ckl256bit : begin Klen := EVP_MAX_KEY_LENGTH; SetKeySize := KLen; end;
                end;
                if CipherType = ctBfCbc then
                    CiphCtx.Cipher := f_EVP_bf_cbc
                else if CipherType = ctBfOfb then
                    CiphCtx.Cipher := f_EVP_bf_ofb
                else begin
                    CiphCtx.Cipher := f_EVP_bf_ecb;
                    IVLen := 0;
                end;
            end;
        else
            raise Exception.Create('Not implemented');
    end;
    { Make the key and IV based on password, this is simple, not compatible }
    { with any standards. }
    if Key = nil then begin
        CalcMD5(@Pwd[1], Length(Pwd), @CiphCtx.Key[0]);     //128-bit key
        if KLen + IVLen > 16 then
            CalcMD5(@CiphCtx.Key[0], 16, @CiphCtx.Key[16]); //256-bit key
        if KLen + IVLen > 32 then
            CalcMD5(@CiphCtx.Key[0], 32, @CiphCtx.Key[32]); //384-bit key
        {if KeyLen + CiphCtx.IVLen > 48 then
            CalcMD5(@CiphCtx.Key[0], 48, @CiphCtx.Key[48]); //512-bit key}
    end
    else
        CiphCtx.Key := Key^;
    if IVLen > 0 then begin
        if IVector = nil then
            Move(CiphCtx.Key[KLen], CiphCtx.IV[0], SizeOf(TIVector))
        else
            Move(IVector^[0], CiphCtx.IV[0], SizeOf(TIVector));
        PIV := @CiphCtx.IV[0];
    end
    else
        PIV := nil;

    CiphCtx.Ctx := f_EVP_CIPHER_CTX_new;
    try
        if ICS_OPENSSL_VERSION_NUMBER < OSSL_VER_1100 then
            f_EVP_CIPHER_CTX_init(CiphCtx.Ctx)
        else
            f_EVP_CIPHER_CTX_reset(CiphCtx.Ctx);
        if SetKeySize > 0 then begin
            if not f_EVP_CipherInit_ex(CiphCtx.Ctx, CiphCtx.Cipher, nil, nil, nil,
                                       Ord(Enc)) then
                RaiseLastOpenSslError(Exception, TRUE,
                                      'Function f_EVP_CipherInit_ex:');
            f_EVP_CIPHER_CTX_set_key_length(CiphCtx.Ctx, SetKeySize);
        end;
        if SetKeySize > 0 then begin
            if not f_EVP_CipherInit_ex(CiphCtx.Ctx, nil, nil, @CiphCtx.key[0],
                                       PIV, Ord(Enc)) then
                RaiseLastOpenSslError(Exception, TRUE,
                                      'Function f_EVP_CipherInit_ex:');
        end
        else begin
            if not f_EVP_CipherInit_ex(CiphCtx.Ctx, CiphCtx.Cipher, nil,
                                       @CiphCtx.key[0],
                                       PIV, Ord(Enc)) then
                RaiseLastOpenSslError(Exception, TRUE,
                                      'Function f_EVP_CipherInit_ex:');
        end;
    except
        CiphFinalize(CiphCtx);
        raise;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure CiphSetIVector(
    var CiphCtx : TCiphContext;
    IVector     : PIVector);
var
    PIV : Pointer;
begin
    if not Assigned(CiphCtx.Ctx) then
        raise Exception.Create('Cipher context not initialized');
    if IVector = nil then begin
        FillChar(CiphCtx.IV, SizeOf(TIVector), #0);
        PIV := nil;
    end
    else begin
        CiphCtx.IV := IVector^;
        PIV := @CiphCtx.IV[0];
    end;
    if not f_EVP_CipherInit_ex(CiphCtx.Ctx, nil, nil, nil,
                               PIV, Ord(CiphCtx.Encrypt)) then
        RaiseLastOpenSslError(Exception, TRUE, 'Function f_EVP_CipherInit_ex:');
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure CiphUpdate(
    const InBuf;
    InLen : Integer;
    const OutBuf;
    var OutLen : Integer;
    CiphCtx : TCiphContext);
begin
    if not Assigned(CiphCtx.Ctx) then
        raise Exception.Create('Cipher context not initialized');
    if not f_EVP_CipherUpdate(CiphCtx.Ctx, PAnsiChar(@OutBuf), OutLen,
                              PAnsiChar(@InBuf), InLen) then
        RaiseLastOpenSslError(Exception, TRUE,
                              'Function f_EVP_CipherUpdate:');
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure CiphFinal(
    const OutBuf;
    var OutLen : Integer;
    CiphCtx : TCiphContext);
begin
    if not Assigned(CiphCtx.Ctx) then
        raise Exception.Create('Cipher context not initialized');
    if not f_EVP_CipherFinal_ex(CiphCtx.Ctx, PAnsiChar(@OutBuf), OutLen) then
        RaiseLastOpenSslError(Exception, TRUE,
                              'Function f_EVP_CipherFinal_ex:');
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ Takes plain text, returns an encrypted string, optionally base64 encoded }
function StrEncBf(
    const S   : AnsiString;
    const Pwd : AnsiString;
    IV        : PIVector;
    KeyLen    : TCipherKeyLen;
    B64       : Boolean): AnsiString;
var
    Len, TmpLen : Integer;
    CiphCtx : TCiphContext;
begin
    FillChar(CiphCtx, SizeOf(CiphCtx), #0);
    CiphInitialize(CiphCtx, Pwd, nil, IV, ctBfCbc, KeyLen, True);
    try
        Len := Length(S);
        SetLength(Result, Len + CiphCtx.BlockSize);
        CiphUpdate(S[1], Length(S), Result[1], Len, CiphCtx);
        CiphFinal(Result[Len + 1], TmpLen, CiphCtx);
        Inc(Len, TmpLen);
        SetLength(Result, Len);
    finally
        CiphFinalize(CiphCtx);
    end;
    if B64 then
         Result := Base64Encode(Result);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function StrDecBf(
    S         : AnsiString;
    const Pwd : AnsiString;
    IV        : PIVector;
    KeyLen    : TCipherKeyLen;
    B64       : Boolean): AnsiString;
var
    Len, TmpLen : Integer;
    CiphCtx : TCiphContext;
begin
    FillChar(CiphCtx, SizeOf(CiphCtx), #0);
    CiphInitialize(CiphCtx, Pwd, nil, IV, ctBfCbc, KeyLen, False);
    try
        if B64 then
            S := Base64Decode(S);
        Len := Length(S);
        SetLength(Result, Len + CiphCtx.BlockSize);
        CiphUpdate(S[1], Length(S), Result[1], Len, CiphCtx);
        CiphFinal(Result[Len + 1], TmpLen, CiphCtx);
        Inc(Len, TmpLen);
        SetLength(Result, Len);
    finally
        CiphFinalize(CiphCtx);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure StreamEncrypt(
    SrcStream  : TStream;
    DestStream : TStream;
    StrBlkSize : Integer;
    CiphCtx    : TCiphContext;
    RandomIV   : Boolean);
var
    Bytes, RetLen, TmpLen : Integer;
    Len : Int64;
    InBuf : array of Byte;
    OutBuf : array of Byte;
    IV : TIVector;
begin
    if RandomIV then begin
        f_RAND_bytes(@IV[0], SizeOf(TIVector));
        CiphSetIVector(CiphCtx, @IV);
    end;
    if StrBlkSize < 1024 then StrBlkSize := 1024;
    SetLength(InBuf, StrBlkSize);
    SetLength(OutBuf, StrBlkSize + CiphCtx.BlockSize); // Room for padding
    Len := SrcStream.Size;
    SrcStream.Position  := 0;
    DestStream.Position := 0;
    { The IV must be known to decrypt, it may be public.   }
    { Without a random IV we always get the same cipher    }
    { text when using both same key and data.              }
    { http://en.wikipedia.org/wiki/Block_cipher_modes_of_operation }
    if RandomIV then // prepend the Initialization Vector data
        DestStream.Write(IV[0], SizeOf(TIVector));
    TmpLen := 0;
    RetLen := TmpLen;
    while True do begin
        Bytes := SrcStream.Read(InBuf[0], StrBlkSize);
        if Bytes > 0 then begin
            Dec(Len, Bytes);
            CiphUpdate(InBuf[0], Bytes, OutBuf[0], RetLen, CiphCtx);
            if Len <= 0 then begin
                CiphFinal(OutBuf[RetLen], TmpLen, CiphCtx);
                Inc(RetLen, TmpLen);
            end;
            if RetLen <> 0 then
                DestStream.Write(OutBuf[0], RetLen);
        end
        else
            Break;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure StreamEncrypt(
    SrcStream  : TStream;
    DestStream : TStream;
    StrBlkSize : Integer;
    CiphCtx    : TCiphContext;
    RandomIV   : Boolean;
    Obj        : TObject;
    ProgressCallback : TCryptProgress);
var
    Bytes, RetLen, TmpLen : Integer;
    Len : Int64;
    InBuf : array of Byte;
    OutBuf : array of Byte;
    IV : TIVector;
    Cancel: Boolean;
begin
    Cancel := FALSE;
    if RandomIV then begin
        f_RAND_bytes(@IV[0], SizeOf(TIVector));
        CiphSetIVector(CiphCtx, @IV);
    end;
    if StrBlkSize < 1024 then StrBlkSize := 1024;
    SetLength(InBuf, StrBlkSize);
    SetLength(OutBuf, StrBlkSize + CiphCtx.BlockSize); // Room for padding
    Len := SrcStream.Size;
    SrcStream.Position  := 0;
    DestStream.Position := 0;
    { The IV must be known to decrypt, it may be public.   }
    { Without a random IV we always get the same cipher    }
    { text when using both same key and data.              }
    { http://en.wikipedia.org/wiki/Block_cipher_modes_of_operation }
    if RandomIV then// prepend the Initialization Vector data
        DestStream.Write(IV[0], SizeOf(TIVector));
    TmpLen := 0;
    RetLen := TmpLen;
    while True do begin
        Bytes := SrcStream.Read(InBuf[0], StrBlkSize);
        if Bytes > 0 then begin
            Dec(Len, Bytes);
            CiphUpdate(InBuf[0], Bytes, OutBuf[0], RetLen, CiphCtx);
            if Len <= 0 then begin
                CiphFinal(OutBuf[RetLen], TmpLen, CiphCtx);
                Inc(RetLen, TmpLen);
            end;
            if RetLen <> 0 then begin
                DestStream.Write(OutBuf[0], RetLen);
                if Assigned(ProgressCallback) then begin
                    ProgressCallback(Obj, SrcStream.Position, Cancel);
                    if Cancel then
                        Break;
                end;
            end;
        end
        else
            Break;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure StreamDecrypt(
    SrcStream  : TStream;
    DestStream : TStream;
    StrBlkSize : Integer;
    CiphCtx    : TCiphContext;
    RandomIV   : Boolean);
var
    Bytes, RetLen, TmpLen : Integer;
    Len : Int64;
    InBuf : array of Byte;
    OutBuf : array of Byte;
    IV : TIVector;
begin
    SrcStream.Position := 0;
    if RandomIV then begin
        SrcStream.Read(IV[0], SizeOf(TIVector));
        CiphSetIVector(CiphCtx, @IV);
    end;
    if StrBlkSize < 1024 then StrBlkSize := 1024;
    SetLength(InBuf, StrBlkSize);
    SetLength(OutBuf, StrBlkSize + CiphCtx.BlockSize);
    Len := SrcStream.Size;
    DestStream.Position := 0;
    TmpLen := 0;
    RetLen := TmpLen;
    while True do begin
        Bytes := SrcStream.Read(InBuf[0], StrBlkSize);
        if Bytes > 0 then begin
            Dec(Len, Bytes);
            CiphUpdate(InBuf[0], Bytes, OutBuf[0], RetLen, CiphCtx);
            if Len <= 0 then begin
                CiphFinal(OutBuf[RetLen], TmpLen, CiphCtx);
                Inc(RetLen, TmpLen);
            end;
            if RetLen <> 0 then
                DestStream.Write(OutBuf[0], RetLen);
        end
        else
            Break;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure StreamDecrypt(
    SrcStream  : TStream;
    DestStream : TStream;
    StrBlkSize : Integer;
    CiphCtx    : TCiphContext;
    RandomIV   : Boolean;
    Obj        : TObject;
    ProgressCallback : TCryptProgress);
var
    Bytes, RetLen, TmpLen : Integer;
    Len : Int64;
    InBuf : array of Byte;
    OutBuf : array of Byte;
    IV : TIVector;
    Cancel: Boolean;
begin
    Cancel := FALSE;
    SrcStream.Position := 0;
    if RandomIV then begin
        SrcStream.Read(IV[0], SizeOf(TIVector));
        CiphSetIVector(CiphCtx, @IV);
    end;
    if StrBlkSize < 1024 then StrBlkSize := 1024;
    SetLength(InBuf, StrBlkSize);
    SetLength(OutBuf, StrBlkSize + CiphCtx.BlockSize);
    Len := SrcStream.Size;
    DestStream.Position := 0;
    TmpLen := 0;
    RetLen := TmpLen;
    while True do begin
        Bytes := SrcStream.Read(InBuf[0], StrBlkSize);
        if Bytes > 0 then begin
            Dec(Len, Bytes);
            CiphUpdate(InBuf[0], Bytes, OutBuf[0], RetLen, CiphCtx);
            if Len <= 0 then begin
                CiphFinal(OutBuf[RetLen], TmpLen, CiphCtx);
                Inc(RetLen, TmpLen);
            end;
            if RetLen <> 0 then begin
                DestStream.Write(OutBuf[0], RetLen);
                if Assigned(ProgressCallback) then begin
                    ProgressCallback(Obj, SrcStream.Position, Cancel);
                    if Cancel then
                        Break;
                end;
            end;
        end
        else
            Break;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

procedure CreateRsaKeyPair(const PubFName, PrivFName: String; Bits: Integer);   { V8.35 }
var
    Bne       : PBIGNUM;
    Rsa       : PRSA;
    PubBIO, PrivBio : PBIO;
    Ret       : Integer;
begin
    if NOT ICS_RAND_INIT_DONE then IcsRandPoll;
    PubBIO := nil;
    PrivBIO := nil;
    Rsa := nil;
  { generate fixed odd number exponent }
    Bne := f_BN_new;
    Ret := f_BN_set_word(Bne, RSA_F4);
    if Ret = 0 then
        raise Exception.Create('Failed to create exponent');
    try

      { generate RSA key paid }
        Rsa := f_RSA_new;
        Ret := f_RSA_generate_key_ex (Rsa, Bits, Bne, nil);
        if (Ret = 0) or (not Assigned(Rsa)) then
            raise Exception.Create('Failed to generate rsa key');

      { save public key file }
        PubBIO := f_BIO_new_file(PAnsiChar(StringToUtf8(PubFname)), PAnsiChar('w+'));
        Ret := f_PEM_write_bio_RSAPublicKey (PubBIO, Rsa);
        if Ret = 0 then
            raise Exception.Create('Failed to save public key file: ' + PubFname);

       { save private key file }
        PrivBIO := f_BIO_new_file(PAnsiChar(StringToUtf8(PrivFname)), PAnsiChar('w+'));
        Ret := f_PEM_write_bio_RSAPrivateKey (PrivBIO, Rsa, nil, nil, 0, nil, nil);
        if Ret = 0 then
            raise Exception.Create('Failed to save private key file: ' + PrivFname);

    finally
        if Assigned(Bne) then
            f_BN_free(Bne);
        if Assigned(Rsa) then
            f_RSA_free(Rsa);
        if Assigned(PubBio) then
            f_BIO_free(PubBio);
        if Assigned(PrivBio) then
            f_BIO_free(PrivBio);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

{$ENDIF}  { USE_SSL }


end.
