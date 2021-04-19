{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Author:       Angus Robertson, Magenta Systems Ltd
Description:  JOSE - Json Object Signing and Encryption, used for:
                 JWS (Json Web Signing)
                 JWT (Json Web Tokens)
                 JWK (Json Web Key)
                 JWE (Hson Web Encryption)
                 variously used by OAuth1, ACME and other protocols.
              Includes OpenSSL Message Authentication Code functions used
              for signing JOSE structures with secret or private/public keys.
Creation:     Feb 2018
Updated:      May 2020
Version:      8.64
EMail:        francois.piette@overbyte.be  http://www.overbyte.be
Support:      https://en.delphipraxis.net/forum/37-ics-internet-component-suite/
Legal issues: Copyright (C) 2019 by Angus Robertson, Magenta Systems Ltd,
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


Overview
--------

Message Authentication Code are a way of verifying a block of data
has not been corrupted or changed, using a key.

Keyed-Hash Message Authentication Code (HMAC)
---------------------------------------------
Uses the same secret key to generate and verify a message, using
a hash alogrithm.

Cipher-based Message Authentication Code (CMAC)  (1.1.0 and later)
-----------------------------------------------
Uses the same secret key to generate and verify a message, using
a block cipher-based message authentication code algorithm.
Aka One-key MAC (OMAC).  Not done yet.

Asymmetric Key-Hash Message Authentication Code (Async MAC)
-------------------------------------------------------
Uses a private key to generate a message, but a public key to
verify it, using a hash alogrithm.





Updates:
May 21, 2018  - 8.54 - baseline
Oct 2, 2018   - 8.57 - build with FMX
Aug 07, 2019  - 8.62 - build Jason Web Token (JWT)
                       Builds without USE_SSL
May 17, 2020  - 8.64 - IcsJoseFindAlg accepts RSA-PSS keys for jsigRsa256/512
                         (Google) and Ed25519 keys for jsigEdDSA
                       IcsJoseJWKPubKey needs OpenSSL 1.1.1e to support RSA-PSS keys.
                       Fixed a bug in IcsBase64UrlDecode thanks to Linden Roth.
                       Cleaned up signing and verifying functions.
                       Fixed various EVP digests with size_t for Win64, thanks
                         to Alexander Pastuhov.



Pending
-------

Check IcsJoseJWKPubKey creates correct EC values

Create Json Web Key from OpenSSL private key (only public at moment)

Convert Json Web Key into OpenSSL public and private key (needed for verify)

Verify Json Web Signed message using public key (only creating at moment)

Test RSA-PSS and Ed25519 keys for signing with IcsAsymSignDigest

}

{$IFNDEF ICS_INCLUDE_MODE}
unit OverbyteIcsSslJose;
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
//    {$IFDEF RTL_NAMESPACES}System.IniFiles{$ELSE}IniFiles{$ENDIF},
{$ENDIF}
{$IFDEF POSIX}
    Posix.Time,
    Ics.Posix.WinTypes,
    Ics.Posix.Messages,
{$ENDIF}
    {$Ifdef Rtl_Namespaces}System.Classes{$Else}Classes{$Endif},
    {$Ifdef Rtl_Namespaces}System.Sysutils{$Else}Sysutils{$Endif},
    {$IFDEF RTL_NAMESPACES}System.TypInfo{$ELSE}TypInfo{$ENDIF},
    OverbyteIcsSsleay, OverbyteIcsLibeay,
{$IFDEF FMX}
    Ics.Fmx.OverbyteIcsWSocket,
{$ELSE}
    OverbyteIcsWSocket,
{$ENDIF FMX}
    OverbyteIcsTypes,
    OverbyteIcsMimeUtils,
    OverbyteIcsUtils;

{ NOTE - these components only build with SSL, there is no non-SSL option }

type
    EDigestException = class(Exception);

{ the JOSE Json Web Signature algorithm "alg" }
{ https://www.iana.org/assignments/jose/jose.xhtml }
    TJoseAlg = (jsigNone,
       jsigHmac256, jsigHmac384, jsigHmac512,    { HMAC with SHA-x -  }
       jsigRsa256, jsigRsa384, jsigRsa512,       { RSASSA-PKCS1-v1_5 using SHA-x }
       jsigEcdsa256, jsigEcdsa384, jsigEcdsa512, { ECDSA using P-x and SHA-x }
       jsigRsaPss256, jsigRsaPss384, jsigRsaPss512, { RSASSA-PSS using SHA-x and MGF1, 1.1.1 and later }
       jsigEdDSA);                               { Ed25519 no hash }



{ public functions }

{ digests and hashes - note all digests are binary bytes in AnsiStrings }
function IcsHMACDigest(const Data, Key: AnsiString;
                HashDigest: TEvpDigest = Digest_sha256): AnsiString;
function IcsHMACDigestEx(const Data, Key: AnsiString;
                HashDigest: TEvpDigest = Digest_sha256): AnsiString;
function IcsHMACDigestVerify(const Data, Key, OldDigest: AnsiString;
                        HashDigest: TEvpDigest = Digest_sha256): Boolean;
function IcsHashDigest(const Data: AnsiString;
                HashDigest: TEvpDigest = Digest_sha256): AnsiString;
function IcsAsymSignDigest(const Data: AnsiString; PrivateKey: PEVP_PKEY;
                HashDigest: TEvpDigest = Digest_sha256): AnsiString;
function IcsAsymVerifyDigest(const Data, OldDigest: AnsiString; PublicKey: PEVP_PKEY;
                HashDigest: TEvpDigest = Digest_sha256): Boolean; Overload;
//function IcsAsymVerifyDigest(const Data, OldDigest, PubKeyStr: AnsiString;
//                HashDigest: TEvpDigest = Digest_sha256): Boolean; Overload;

{ RFC4658 base64 decode with trailing == removed, need to add them back  }
function IcsBase64UrlDecode(const Input: String): String;

{ RFC4658 base64 encode with trailing == removed and made URL safe, no CRLF allowed either  }
function IcsBase64UrlEncode(const Input: String): String;
function IcsBase64UrlEncodeA(const Input: AnsiString): AnsiString;

{ RFC7515 Jose Header for Json Web Signature or Token, with Acme private fields }
function IcsJoseHeader(const Alg, Typ, Jwk, Kid, Nonce: string;
                                                const Url: string = ''): String;

{ RFC7515 find Json Web Signature hash type }
function IcsJoseFindHash(JoseAlg: TJoseAlg): TEvpDigest;

{ RFC7515 find Json Web Signature algorithm and check private key matches it }
function IcsJoseFindAlg(JoseAlg: TJoseAlg; PrivateKey: PEVP_PKEY): string;

{ RFC7517 Jose JSON Web Key (JWK) with Hmac shared secret key }
function IcsJoseJWKHmac(const Secret, Alg: String;
                  const Kid: String = ''; const Use: String = ''): String;

{ RFC7517 Jose JSON Web Key (JWK) with public key }
function IcsJoseJWKPubKey(PrivateKey: PEVP_PKEY; const Alg: String;
                  const Kid: String = ''; const Use: String = ''): String;

{ RFC7515 get JWS signature from protected header and payload }
{ by periods, ie xxx.xxx.xxx }
function IcsJoseGetSig(JoseAlg: TJoseAlg; const CombinedEn, HmacSecret: AnsiString;
                                                   PrivateKey: PEVP_PKEY): String;

{ RFC7515 build Json Web Signature or Token, with Acme private fields, }
{ using JWS Compact Serialization with is three base64url blocks separated }
{ by periods, ie xxx.xxx.xxx }
function IcsJoseJWSComp(JoseAlg: TJoseAlg; const Payload, HmacSecret: string;
          PrivateKey: PEVP_PKEY; const Typ, Jwk, Kid, Nonce: string;
                                                 const Url: string = ''): string;

{ RFC7515 build Json Web Signature or Token, with Acme private fields, }
{ using JWS JSON Serialization with is three Json blocks }
{ used by ACME v2 }
function IcsJoseJWSJson(JoseAlg: TJoseAlg; const Payload, HmacSecret: string;
          PrivateKey: PEVP_PKEY; const Typ, Jwk, Kid, Nonce: string;
                                                 const Url: string = ''): string;

{ build Acme v1 Json Web Signature or Token, non-standard with extra header }
{ gone V8.64 no longer used
function IcsJoseJWSAcme1(JoseAlg: TJoseAlg; const Payload: string;
          PrivateKey: PEVP_PKEY; const Jwk, Nonce: string): string;  }

{ build Json Web Token (JWT) by Base64Url encoding three components as long string V8.62 }
function IcsJoseJWT(const Header, Payload, Signature: string): string;

{$ENDIF USE_SSL}

implementation

{$IFDEF USE_SSL}

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

{ create HMAC hash keyed message authentication code for some data with a simple
  key, using md5, sha1, sha256, sha512, etc, the old way  }

function IcsHMACDigest(const Data, Key: AnsiString;
                HashDigest: TEvpDigest = Digest_sha256): AnsiString;
var
    DigLen: integer;
    Digest: array [0..EVP_MAX_MD_SIZE] of AnsiChar;   // binary result, not hex or base64
begin
    Result := '';
    if ICS_OPENSSL_VERSION_NUMBER = 0 then LoadSsl;
    DigLen := 0;
    f_HMAC(IcsSslGetEVPDigest(HashDigest), PByte(Key), Length(Key),
                                   PByte(Data), Length(Data), @Digest, DigLen);
    if DigLen > 0 then begin
        SetLength( Result, DigLen);
        Move(Digest[0], Result[1], DigLen);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ create HMAC hash keyed message authentication code for some data with a simple
  key, using md5, sha1, sha256, sha512, etc, the new way  }

function IcsHMACDigestEx(const Data, Key: AnsiString;
                HashDigest: TEvpDigest = Digest_sha256): AnsiString;
var
    Signature: array [0..1025] of AnsiChar;   // binary result, not hex or base64
    PKey: PEVP_PKEY;
    Etype: PEVP_MD;
    DigestCtx: PEVP_MD_CTX;
    PkeyCtx: PEVP_PKEY_CTX;   { V8.64 }
    SigLen: size_t;           { V8.64 }
    Ret: integer;
begin
    Result := '';
    PKey := f_EVP_PKEY_new_mac_key(EVP_PKEY_HMAC, Nil, PAnsiChar(Key), Length(Key));
    DigestCtx := f_EVP_MD_CTX_new;
    try
        Etype := IcsSslGetEVPDigest(HashDigest);
        if NOT Assigned(Etype) then
              Raise EDigestException.Create('Unsupported hash digest ' +
                           GetEnumName(TypeInfo(TEvpDigest), Ord(HashDigest)));
    // ?? this might not be necessary...test it
        Ret := f_EVP_DigestInit_Ex(DigestCtx, Etype, Nil);
        if (Ret <= 0) then RaiseLastOpenSslError(EDigestException, FALSE,
                                    'Failed to initialise hash digest');
        Ret := f_EVP_DigestSignInit(DigestCtx, PkeyCtx, Etype, Nil, PKey);
        if (Ret <= 0) then RaiseLastOpenSslError(EDigestException, FALSE,
                                    'Failed to initialise signing digest');
     // Update can be called repeatedly for large streams
        ret := f_EVP_DigestSignUpdate(DigestCtx, Pointer(Data), Length(Data));
        if (Ret <= 0) then RaiseLastOpenSslError(EDigestException, FALSE,
                                    'Failed to update signing digest');
        SigLen := SizeOf(Signature);
        ret := f_EVP_DigestSignFinal(DigestCtx, @Signature, SigLen);
        if (Ret <= 0) then RaiseLastOpenSslError(EDigestException, FALSE,
                                    'Failed to finalise signing digest');
        if SigLen > 0 then begin
            SetLength(Result, SigLen);
            Move(Signature[0], Result[1], SigLen);
        end;
    finally
        f_EVP_MD_CTX_free(DigestCtx);
        f_EVP_PKEY_free(Pkey);  { V8.64 }
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ verify a HMAC hash keyed message authentication code for some data with a simple
  key, using md5, sha1, sha256, sha512, etc, the new way  }

function IcsHMACDigestVerify(const Data, Key, OldDigest: AnsiString;
                        HashDigest: TEvpDigest = Digest_sha256): Boolean;
var
    NewDigest: AnsiString;
begin
    NewDigest := IcsHMACDigestEx(Data, Key, HashDigest);
  // constant time comparison to avoid timing attacks
    Result := (f_CRYPTO_memcmp(PAnsiChar(OldDigest), PAnsiChar(NewDigest), Length(NewDigest)) = 0);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ create a hash digest for a string, using numerous hashes, SHA, SHA2, SHA3, shake }

function IcsHashDigest(const Data: AnsiString;
                HashDigest: TEvpDigest = Digest_sha256): AnsiString;
var
    DigestCtx: PEVP_MD_CTX;
    Etype: PEVP_MD;
    DigLen, Ret: integer;
    Digest: array [0..EVP_MAX_MD_SIZE] of AnsiChar;   // binary result, not hex or base64
begin
    Result := '';
    DigestCtx := f_EVP_MD_CTX_new;
    try
        Etype := IcsSslGetEVPDigest(HashDigest);
        if NOT Assigned(Etype) then
              Raise EDigestException.Create('Unsupported hash digest ' +
                           GetEnumName(TypeInfo(TEvpDigest), Ord(HashDigest)));
        Ret := f_EVP_DigestInit_Ex(DigestCtx, Etype, Nil);
        if (Ret = 0) then RaiseLastOpenSslError(EDigestException, FALSE,
                                    'Failed to initialise hash digest');
     // Update can be called repeatedly for large streams
        ret := f_EVP_DigestUpdate(DigestCtx, PByte(Data), Length(Data));
        if (Ret = 0) then RaiseLastOpenSslError(EDigestException, FALSE,
                                    'Failed to update hash digest');
        ret := f_EVP_DigestFinal_Ex(DigestCtx, @Digest, DigLen);
        if (Ret = 0) then RaiseLastOpenSslError(EDigestException, FALSE,
                                    'Failed to finalise hash digest');
        if DigLen > 0 then begin
            SetLength( Result, DigLen);
            Move(Digest[0], Result[1], DigLen);
        end;
    finally
        f_EVP_MD_CTX_free(DigestCtx);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ create asymmetic MAC hash keyed message authentication code for some data with
  a private key, using md5, sha1, sha256, sha512, etc  }
{Note - ECDSA keys contain a random element, so are dfferent each time for same data }
function IcsAsymSignDigest(const Data: AnsiString; PrivateKey: PEVP_PKEY;
                HashDigest: TEvpDigest = Digest_sha256): AnsiString;
var
    Signature: array [0..1025] of AnsiChar;   // binary result, not hex or base64
    Etype: PEVP_MD;
    PkeyCtx: PEVP_PKEY_CTX;
    DigestCtx: PEVP_MD_CTX;
    SigLen: size_t;           { V8.64 }
    Ret, keytype: integer;
begin
    Result := '';
    if not Assigned(PrivateKey) then
              Raise EDigestException.Create('Private key required');
    keytype := f_EVP_PKEY_base_id(PrivateKey);
    if (keytype <> EVP_PKEY_RSA) and (keytype <> EVP_PKEY_EC) and
        (keytype <> EVP_PKEY_ED25519) and (keytype <> EVP_PKEY_RSA_PSS) then
              Raise EDigestException.Create('Unsupported private key type');

    DigestCtx := f_EVP_MD_CTX_new;
    PkeyCtx := Nil;
    SigLen := SizeOf(Signature);
    try
        Etype := IcsSslGetEVPDigest(HashDigest);
        if keytype = EVP_PKEY_ED25519 then
            EType := Nil // Needs 1.1.1
        else if NOT Assigned(Etype) then
            Raise EDigestException.Create('Unsupported hash digest ' +
                           GetEnumName(TypeInfo(TEvpDigest), Ord(HashDigest)));

        Ret := f_EVP_DigestSignInit(DigestCtx, PkeyCtx, Etype, Nil, PrivateKey);
        if (Ret <= 0) then RaiseLastOpenSslError(EDigestException, FALSE,
                                    'Failed to initialise signing digest');

     { send an algorithm specific control operation to context }
     { V8.64 these were never called since PkeyCtx was never set due to
         DigestSignInit not having a var declaration, but don't seem to make
         any differece to the output so not yet used }
  (*     if PkeyCtx <> Nil then begin

          // pending, 3.0 uses APIs not macros, need to create in OverbyteIcsSSLEAY

          { do we really need to set digest type?? }
             // EVP_PKEY_CTX_set_signature_md macro, API in 3.0
              if f_EVP_PKEY_CTX_ctrl(PkeyCtx, -1, EVP_PKEY_OP_TYPE_SIG,
                                                  EVP_PKEY_CTRL_MD, 0, Etype) = 0 then   { V8.64 }
                    RaiseLastOpenSslError(EDigestException, FALSE,
                                        'Failed to set digest type for signing digest');

         { set specific EC curve NID}
              if (keytype = EVP_PKEY_EC) then begin
             //  EVP_PKEY_CTX_set_ec_paramgen_curve_nid macro, API in 3.0
                if f_EVP_PKEY_CTX_ctrl(
                     PkeyCtx, EVP_PKEY_EC, EVP_PKEY_OP_PARAMGEN OR EVP_PKEY_OP_KEYGEN,
                        EVP_PKEY_CTRL_EC_PARAMGEN_CURVE_NID, NID_X9_62_prime256v1, Nil) = 0 then
                    RaiseLastOpenSslError(EDigestException, FALSE,
                                        'Failed to set EC curve for signing digest');
            end;
         { pending, may need to set RSA PSS stuff }

        end;   *)

        if ICS_OPENSSL_VERSION_NUMBER < OSSL_VER_1101 then begin   // V8.64 latest Wiki uses this version
            ret := f_EVP_DigestSignUpdate(DigestCtx, Pointer(Data), Length(Data));
            if (Ret <= 0) then RaiseLastOpenSslError(EDigestException, FALSE,
                                               'Failed to update signing digest');
            ret := f_EVP_DigestSignFinal(DigestCtx, @Signature, SigLen);
        end
        else
            ret := f_EVP_DigestSign(DigestCtx, @Signature, SigLen,
                                                PAnsiChar(Data), Length(Data));  // Needs 1.1.1  }
        if (Ret <= 0) then RaiseLastOpenSslError(EDigestException, FALSE,
                                    'Failed to finalise signing digest');
        if SigLen > 0 then begin
            SetLength(Result, SigLen);
            Move(Signature[0], Result[1], SigLen);
        end;
    finally
        f_EVP_MD_CTX_free(DigestCtx);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ verify asymmetic MAC hash keyed message authentication code for some data with
  a public key object, using md5, sha1, sha256, sha512, etc  }

function IcsAsymVerifyDigest(const Data, OldDigest: AnsiString; PublicKey: PEVP_PKEY;
                HashDigest: TEvpDigest = Digest_sha256): Boolean;
var
    Etype: PEVP_MD;
    DigestCtx: PEVP_MD_CTX;
    PkeyCtx: PEVP_PKEY_CTX;   { V8.64 }
    Ret, keytype: integer;
begin
    Result := false;
    if not Assigned(PublicKey) then
              Raise EDigestException.Create('Public key required');
    keytype := f_EVP_PKEY_base_id(PublicKey);
    if (keytype <> EVP_PKEY_RSA) and (keytype <> EVP_PKEY_EC) and
        (keytype <> EVP_PKEY_ED25519) and (keytype <> EVP_PKEY_RSA_PSS) then
              Raise EDigestException.Create('Unsupported public key type');
    DigestCtx := f_EVP_MD_CTX_new;
    PkeyCtx := Nil;
    try
        Etype := IcsSslGetEVPDigest(HashDigest);
        if keytype = EVP_PKEY_ED25519 then
            EType := Nil // Needs 1.1.1
        else if NOT Assigned(Etype) then
            Raise EDigestException.Create('Unsupported hash digest ' +
                           GetEnumName(TypeInfo(TEvpDigest), Ord(HashDigest)));
        Ret := f_EVP_DigestVerifyInit(DigestCtx, PkeyCtx, Etype, Nil, PublicKey);
        if (Ret <= 0) then RaiseLastOpenSslError(EDigestException, FALSE,
                                    'Failed to initialise signing digest');
        if ICS_OPENSSL_VERSION_NUMBER < OSSL_VER_1101 then begin
            ret := f_EVP_DigestVerifyUpdate(DigestCtx, Pointer(Data), Length(Data));  { V8.64 }
            if (Ret <= 0) then RaiseLastOpenSslError(EDigestException, FALSE,
                                        'Failed to update signing digest');
            ret := f_EVP_DigestVerifyFinal(DigestCtx, PAnsiChar(OldDigest), Length(OldDigest));
        end
        else
            ret := f_EVP_DigestVerify(DigestCtx, PAnsiChar(OldDigest),
                            Length(OldDigest), PAnsiChar(Data), Length(Data));
        if (Ret = 1) then
            Result := True
        else
        if (Ret = 0) then
            Result := False
        else
            RaiseLastOpenSslError(EDigestException, FALSE, 'Failed to verify signing digest');
    finally
        f_EVP_MD_CTX_free(DigestCtx);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

{ RFC4658 base64 with trailing == removed, need to add them back  }

function IcsBase64UrlDecode(const Input: String): String;
var
    S: String;
    NewLen, I: Integer;
begin
    S := Input;
    NewLen := ((3 + Length(S)) div 4) * 4;   { V8.64 too long } 
    while (NewLen > Length(S)) do S := S + '=';
    for I := 1 to Length(S) do begin
        if S[I] = '-' then S[I] := '+';
        if S[I] = '_' then S[I] := '/';
    end;
    Result := Base64Decode(S);
end ;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

{ RFC4658 base64 with trailing == removed and made URL safe, no CRLF allowed either  }

function IcsBase64UrlEncode(const Input: String): String;
var
    I: Integer;
begin
    Result := Base64Encode(Input);
    while (Length(Result) > 0) and (Result[Length(Result)] = '=') do
                                   SetLength(Result, Length(Result) - 1);
    for I := 1 to Length(Result) do begin
        if Result[I] = '+' then Result[I] := '-';
        if Result[I] = '/' then Result[I] := '_';
    end;
end ;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

{ RFC4658 base64 with trailing == removed and made URL safe, no CRLF allowed either  }

function IcsBase64UrlEncodeA(const Input: AnsiString): AnsiString;
var
    I: Integer;
begin
    Result := Base64Encode(Input);
    while (Length(Result) > 0) and (Result[Length(Result)] = '=') do
                                   SetLength(Result, Length(Result) - 1);
    for I := 1 to Length(Result) do begin
        if Result[I] = '+' then Result[I] := '-';
        if Result[I] = '/' then Result[I] := '_';
    end;
end ;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

{ RFC7515 Jose Header for Json Web Signature or Token, with Acme private fields }

function IcsJoseHeader(const Alg, Typ, Jwk, Kid, Nonce: string;
                                                const Url: string = ''): String;
begin
    Result := '{"alg":"' + Alg + '",';
    if Typ <> '' then Result := Result + '"typ":"' + Typ + '",';
    if Jwk <> '' then begin
        if Jwk[1] = '{' then  // Json block
           Result := Result + '"jwk":' + Jwk + ','
        else
            Result := Result + '"jwk":"' + Jwk + '",';
    end;
    if Kid <> '' then Result := Result + '"kid":"' + Kid + '",';
    if Nonce <> '' then Result := Result + '"nonce":"' + Nonce + '",';
    if Url <> '' then Result := Result + '"url":"' + Url + '",';
    SetLength(Result, Length(Result)-1);
    Result := Result + '}';
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

{ RFC7517 Jose JSON Web Key (JWK) with Hmac shared secret key }

function IcsJoseJWKHmac(const Secret, Alg: String;
                  const Kid: String = ''; const Use: String = ''): String;
begin
    if Pos ('HS', alg) <> 1 then
             Raise EDigestException.Create('Need HSxxx Alg for HMAC secret');
    Result := '{"kty":"oct",' +   { octet sequence }
               '"k":"' + IcsBase64UrlEncode(Secret) + '",' +
               '"alg":"' + Alg + '"';
    if Kid <> '' then Result := Result + ',"kid":"' + Kid + '"';
    if Use <> '' then Result := Result + ',"use":"' + Use + '"';
    Result := Result + '}';
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

{ RFC7517 Jose JSON Web Key (JWK) with RSA or EC public key }
{ RFC7638 JWK Thumbprint which specifies members must be in alphabetic order }

function IcsJoseJWKPubKey(PrivateKey: PEVP_PKEY; const Alg: String;
                  const Kid: String = ''; const Use: String = ''): String;
var
    MyRSA: PRSA;
    eckey: PEC_KEY;
    ecgroup: PEC_GROUP;
    ecpoint: PEC_POINT;
    KeyType, KeyLen, Nid: integer;
    Curve: String;
    big1, big2, big3: PBIGNUM;
    Buff: AnsiString;

    function GetBinNum(big: PBIGNUM): AnsiString;
    var
        NumLen: integer;
    begin
        Result := '';
        if NOT Assigned (big) then Exit;
        NumLen := (f_BN_num_bits(big) + 7) div 8;
        SetLength(Result, NumLen + 1);
        NumLen := f_BN_bn2bin(big, @Result[1]);
        SetLength(Result, NumLen);
    end;

begin
    if ICS_OPENSSL_VERSION_NUMBER = 0 then LoadSsl;
    if (not Assigned(PrivateKey)) then
                  Raise EDigestException.Create('Private key required');
    KeyType := f_EVP_PKEY_base_id(PrivateKey);
    if (keytype = EVP_PKEY_RSA) or (keytype = EVP_PKEY_RSA_PSS) then begin
        if (Alg <> '') and (Pos ('RS', Alg) <> 1) and (Pos ('PS', Alg) <> 1) then
                Raise EDigestException.Create('Need RSxxx Alg for RSA key');

      { V8.64 RSA functions need 1.1.1e to work with RSA-PSS }
        MyRSA := f_EVP_PKEY_get1_RSA(PrivateKey);
        if NOT Assigned(myRSA) then
            RaiseLastOpenSslError(EDigestException, FALSE, 'Failed to read RSA key');
        try
            KeyLen := f_RSA_size(MyRSA) * 8;
            if KeyLen <= 0 then
                 Raise EDigestException.Create('Failed to read RSA key');
            if ICS_OPENSSL_VERSION_NUMBER >= OSSL_VER_1100 then
                f_RSA_get0_key(MyRSA, big1, big2, big3)
            else begin
                big1 := PRSAreal(MyRSA).n;
                big2 := PRSAreal(MyRSA).e;
            end;
         // no spaces, alpha order, or thumbnail fails
            Result := '{"e":"' + IcsBase64UrlEncode(String(GetBinNum(big2))) + '",' +
                      '"kty":"RSA",' +
                      '"n":"' + IcsBase64UrlEncode(String(GetBinNum(big1))) + '"';
        finally
            f_RSA_free(MyRSA);
        end;
    end
    else if (keytype = EVP_PKEY_EC) then begin
        if (Alg <> '') and (Pos ('ES', Alg) <> 1) then
                 Raise EDigestException.Create('Need ESxxx Alg for ECDSA key');
        eckey := f_EVP_PKEY_get1_EC_KEY(PrivateKey);
        if eckey = nil then
            RaiseLastOpenSslError(EDigestException, FALSE, 'Failed to read ECDSA key');
        try
            ecpoint := f_EC_KEY_get0_public_key(eckey);
            ecgroup := f_EC_KEY_get0_group(eckey);
            if (Assigned (ecgroup) and Assigned (ecpoint)) then begin
                Nid := f_EC_GROUP_get_curve_name(ecgroup);
                case Nid of
                    NID_X9_62_prime256v1: Curve := 'P-256';
                    NID_secp384r1: Curve := 'P-384';
                    NID_secp521r1: Curve := 'P-512';
                    else
                        Curve := 'P-256';
                end;
                big1 := f_BN_new;
                big2 := f_BN_new;
                f_EC_POINT_get_affine_coordinates_GFp(ecgroup, ecpoint, big1, big2, Nil);
         // no spaces, alpha order, or thumbnail fails
                Result := '{"crv":"' + Curve + '",' +
                          '"kty":"EC",' +
                          '"x":"' + IcsBase64UrlEncode(String(GetBinNum(big1))) + '",' +
                          '"y":"' + IcsBase64UrlEncode(String(GetBinNum(big2))) + '"';
                f_BN_free(big1);
                f_BN_free(big2);
            end;
        finally
            f_EC_KEY_free(eckey);
        end;
    end
    else if (keytype = EVP_PKEY_ED25519) then begin // different type of EC, 1.1.1 and later
        if ICS_OPENSSL_VERSION_NUMBER < OSSL_VER_1101 then       { V8.64 }
                 Raise EDigestException.Create('Need OpenSSL 1.1.1 or later for Ed25519 key');
        if (Alg <> '') and (Alg <> 'EdDSA') then
                 Raise EDigestException.Create('Need EdDSA Alg for Ed25519 key');
        SetLength(Buff, 256);
        FillChar(Buff[1], 256, #0);
        KeyLen := 255;
        if f_EVP_PKEY_get_raw_public_key(PrivateKey, @Buff[1], KeyLen) = 0 then   { V8.64 correct function }
           RaiseLastOpenSslError(EDigestException, FALSE, 'Failed to read Ed25519 public key');
        SetLength(Buff, KeyLen);
        Result := '{"kty":"OKP",' +   // Ocktet string key pairs
                   '"crv":"Ed25519",' +
               //    '"hex":"' + IcsBufferToHex(Buff[1], KeyLen, ':') + '",' +  // TEMP DIAG
                   '"x":"' + IcsBase64UrlEncode(String(Buff)) + '"';      { V8.64 }
    end
    else
        Result := '';

 // add other optional elements
    if Result <> '' then begin
        if Alg <> '' then Result := Result + ',"alg": "' + Alg + '"';
        if Kid <> '' then Result := Result + ',"kid": "' + Kid + '"';
        if Use <> '' then Result := Result + ',"use": "' + Use + '"';
        Result := Result + '}';
    end;

end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

{ RFC7515 find Json Web Signature hash type }

function IcsJoseFindHash(JoseAlg: TJoseAlg): TEvpDigest;
begin
    Result := Digest_sha256;
    case JoseAlg of
        jsigHmac256, jsigRsa256, jsigEcdsa256, jsigRsaPss256: Result := Digest_sha256;
        jsigHmac384, jsigRsa384, jsigEcdsa384, jsigRsaPss384: Result := Digest_sha384;
        jsigHmac512, jsigRsa512, jsigEcdsa512, jsigRsaPss512: Result := Digest_sha512;
        jsigEdDSA: Result := Digest_none;
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

{ RFC7515 find Json Web Signature algorithm and check private key matches it }

function IcsJoseFindAlg(JoseAlg: TJoseAlg; PrivateKey: PEVP_PKEY): string;
var
    KeyType, Nid: integer;
    eckey: PEC_KEY;
    ecgroup: PEC_GROUP;
begin
    Result := 'none';
    if ICS_OPENSSL_VERSION_NUMBER = 0 then LoadSsl;
    if (JoseAlg >= jsigHmac256) and (JoseAlg <= jsigHmac512) then begin
      // key should be minimum length of has bits, ie 32, 48 or 64 chars
        case JoseAlg of
            jsigHmac256: Result := 'HS256';
            jsigHmac384: Result := 'HS384';
            jsigHmac512: Result := 'HS512';
        end;
    end
    else if (JoseAlg >= jsigRsa256) then begin
        if not Assigned(PrivateKey) then
                  Raise EDigestException.Create('PrivateKey key required');
        KeyType := f_EVP_PKEY_base_id(PrivateKey);

        if (JoseAlg >= jsigRsa256) and (JoseAlg <= jsigRsa512) then begin
            if (f_EVP_PKEY_bits(PrivateKey) < 2048) then    { V8.64 clearer exceptions }
                   Raise EDigestException.Create('RSA private key 2,048 or longer required');
            if (keytype <> EVP_PKEY_RSA) and (keytype <> EVP_PKEY_RSA_PSS) then  { V8.64 allow PSS as well }
                   Raise EDigestException.Create('RSA private key required');
            case JoseAlg of
                jsigRsa256: Result := 'RS256';
                jsigRsa384: Result := 'RS384';
                jsigRsa512: Result := 'RS512';
            end;
        end
        else if (JoseAlg >= jsigEcdsa256) and (JoseAlg <= jsigEcdsa512) then begin
            if (keytype <> EVP_PKEY_EC) then
                   Raise EDigestException.Create('ECDSA key required');
            eckey := f_EVP_PKEY_get1_EC_KEY(PrivateKey);
            if eckey = nil then
                 Raise EDigestException.Create('Failed to read ECDSA key');
            Nid := NID_X9_62_prime256v1;
            try
                ecgroup := f_EC_KEY_get0_group(eckey);
                if Assigned (ecgroup) then Nid := f_EC_GROUP_get_curve_name(ecgroup);
            finally
                f_EC_KEY_free(eckey);
            end;
            case JoseAlg of
                jsigEcdsa256: begin
                    if Nid <> NID_X9_62_prime256v1 then
                        Raise EDigestException.Create('P-256 ECDSA key required for EC256');
                    Result := 'ES256';
                end;
                jsigEcdsa384: begin
                    if Nid <> NID_secp384r1 then
                        Raise EDigestException.Create('P-384 ECDSA key required for EC384');
                    Result := 'ES384';
                end;
                jsigEcdsa512: begin
                    if Nid <> NID_secp521r1 then
                        Raise EDigestException.Create('P-512 ECDSA key required for EC512');
                    Result := 'ES512';
                end;
            end;

        end
        else if (JoseAlg >= jsigRsaPss256) and (JoseAlg <= jsigRsaPss512) then begin
            if (f_EVP_PKEY_bits(PrivateKey) < 2048) then   { V8.64 clearer exceptions }
                   Raise EDigestException.Create('RSA-PSS private key 2,048 or longer required');
            if (keytype <> EVP_PKEY_RSA_PSS) then  { V8.64 }
                   Raise EDigestException.Create('RSA-PSS private key required');
            case JoseAlg of
                jsigRsaPss256: Result := 'PS256';
                jsigRsaPss384: Result := 'PS384';
                jsigRsaPss512: Result := 'PS512';
            end;
        end
        else if (JoseAlg = jsigEdDSA) then begin
            if (keytype <> EVP_PKEY_ED25519) then  // different type of EC, 1.1.1 and later
                Raise EDigestException.Create('EdDSA private key required');
            Result := 'EdDSA';
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

{ RFC7515 get JWS signature from protected header and payload }

function IcsJoseGetSig(JoseAlg: TJoseAlg; const CombinedEn, HmacSecret: AnsiString;
                                                   PrivateKey: PEVP_PKEY): String;
var
    HashDigest: TEvpDigest;
begin
    Result := '';
    HashDigest := IcsJoseFindHash(JoseAlg);
    if ((JoseAlg >= jsigHmac256) and (JoseAlg <= jsigHmac512)) then begin
        if HmacSecret = '' then
              Raise EDigestException.Create('HMAC secret key required');
        Result := IcsBase64UrlEncode(String(IcsHMACDigestEx(CombinedEn, HmacSecret, HashDigest)));
    //    Result := IcsBase64UrlEncode(String(IcsHMACDigest(CombinedEn, HmacSecret, HashDigest)));
    end
    else if (JoseAlg >= jsigRsa256) then begin
        Result := IcsBase64UrlEncode(String(IcsAsymSignDigest(CombinedEn, PrivateKey, HashDigest)));
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

{ RFC7515 build Json Web Signature (JWS) or Json Web Token (JWT), }
{ with Acme private fields, using JWS Compact Serialization which is three }
{ base64url blocks separated by periods, ie xxx.xxx.xxx }

function IcsJoseJWSComp(JoseAlg: TJoseAlg; const Payload, HmacSecret: string;
          PrivateKey: PEVP_PKEY; const Typ, Jwk, Kid, Nonce: string;
                                                 const Url: string = ''): string;
var
    Alg, ProtectedEn, PayloadEn, SignatureEn: String;
begin
    Result := '';

  // not allowed Jwk and Kid together
    if (Jwk <> '') and (Kid <> '') then Exit;

  // find algorithm and hash, checking private key matches
    Alg := IcsJoseFindAlg(JoseAlg, PrivateKey);

  // build Json header and base64url encode it
    ProtectedEn := IcsBase64UrlEncode(String(StringToUtf8
                            (IcsJoseHeader(Alg, Typ, Jwk, Kid, Nonce, Url))));

  // base64url encode payload, which may be json
    PayloadEn := IcsBase64UrlEncode(String(StringToUtf8(Payload)));

  // combine header and payload and get signature
    SignatureEn := IcsJoseGetSig(JoseAlg, AnsiString(ProtectedEn + '.' + PayloadEn),
                                                      AnsiString(HmacSecret), PrivateKey);

 // combine all three together with periods
    Result := ProtectedEn + '.' + PayloadEn + '.' + SignatureEn;

end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
(* Acme V2 - draft 10
 new account sends jwk
 {
     "protected": base64url({
       "alg": "ES256",
       "jwk": {...},
       "nonce": "6S8IqOGY7eL2lsGoTZYifg",
       "url": "https://example.com/acme/new-account"
     }),
     "payload": base64url(xxx),
     "signature": "RZPOnYoPs1PhjszF...-nh6X1qtOFPB519I"
   }
 subsequent requests send kid (from HTTP Location: response to new account
 {
     "protected": base64url({
       "alg": "ES256",
       "kid": /* account key */,
       "nonce": "ax5RnthDqp_Yf4_HZnFLmA",
       "url": "https://example.com/acme/acct/1"
     }),
     "payload":base64url(xxx),
     "signature": "hDXzvcj8T6fbFbmn...rDzXzzvzpRy64N0o"
   }
*)

{ RFC7515 build Json Web Signature or Token, with Acme private fields, }
{ using JWS JSON Serialization which is three Json blocks }
{ used by ACME v2 }
function IcsJoseJWSJson(JoseAlg: TJoseAlg; const Payload, HmacSecret: string;
          PrivateKey: PEVP_PKEY; const Typ, Jwk, Kid, Nonce: string;
                                                 const Url: string = ''): string;
var
    Alg,ProtectedEn, PayloadEn, SignatureEn: String;
begin
    Result := '';

  // not allowed Jwk and Kid together
    if (Jwk <> '') and (Kid <> '') then Exit;

  // find algorithm and hash, checking private key matches
    Alg := IcsJoseFindAlg(JoseAlg, PrivateKey);

  // build Json header and base64url encode it
    ProtectedEn := IcsBase64UrlEncode(String(StringToUtf8(
                        IcsJoseHeader(Alg, Typ, Jwk, Kid, Nonce, Url))));

  // base64url encode payload, which may be json
    PayloadEn := IcsBase64UrlEncode(String(StringToUtf8(Payload)));

  // combine header and payload and get signature
    SignatureEn := IcsJoseGetSig(JoseAlg, AnsiString(ProtectedEn + '.' + PayloadEn),
                                                     AnsiString(HmacSecret), PrivateKey);

 // combine all three together as Json
    Result :=  '{"protected":"' + ProtectedEn +
                '","payload":"' + PayloadEn +
                '","signature":"' + SignatureEn + '"}';
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

{ build Acme v1 Json Web Signature or Token, has extra clear header }

 (* base54url fields truncated below, protected is same as header but with
    with extra field "nonce":"xxxxxx", signature is asymmeritic digest created
    by combining protected and payload fields signed with private key and hashed.

  {"header":
    {
     "alg": "RS256",
     "jwk": {
      "e": "AQAB",
      "kty": "RSA",
      "n": "osJT-PZqVCW4wj8_VdBxxxxx"
     }
   },
   "protected": "eyJhbGciOiAiUlMyxxxxNTYiLCJqd2siOiB7ImUiOxxxxx",
   "payload": "eyJjb250YWN0IjpbIm1haWx0bzphbmd1c0BtYWdzeXMuY2xx",
   "signature": "UYdG9MGyFE0ib68HOISHHq2VdASsLs3Kz1wXzdVWCZxxxx"
 }
*)
(* gone V8.64  no longer used
function IcsJoseJWSAcme1(JoseAlg: TJoseAlg; const Payload: string;
          PrivateKey: PEVP_PKEY; const Jwk, Nonce: string): string;
var
    Alg: string;
    HeaderClr, ProtectedEn, PayloadEn, SignatureEn: String;
begin
    Result := '';

  // find algorithm and hash, checking private key matches
    Alg := IcsJoseFindAlg(JoseAlg, PrivateKey);

  // build unprotected Json header, alg and JKW but no nonce, no encoding
    HeaderClr := String(StringToUtf8(IcsJoseHeader(Alg, '', Jwk, '', '', '')));

  // build protected Json header, alg and JWK with nonce, and base64url encode it
    ProtectedEn := IcsBase64UrlEncode(String(StringToUtf8
                               (IcsJoseHeader(Alg, '', Jwk, '', Nonce, ''))));

  // base64url encode payload, which may be json
    PayloadEn := IcsBase64UrlEncode(String(StringToUtf8(Payload)));

  // combine header and payload and get signature
    SignatureEn := IcsJoseGetSig(JoseAlg, AnsiString(ProtectedEn + '.' + PayloadEn),
                                                                      '', PrivateKey);

 // combine all four together as Json
    Result :=  '{"header":' + HeaderClr +
                ',"protected":"' + ProtectedEn +
                '","payload":"' + PayloadEn +
                '","signature":"' + SignatureEn + '"}';
end;
*)


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

{ build Json Web Token (JWT) by Base64Url encoding three components as long string V8.62 }
function IcsJoseJWT(const Header, Payload, Signature: string): string;
begin
    Result := IcsBase64UrlEncode(String(StringToUtf8(Header))) + '.' +
                 IcsBase64UrlEncode(String(StringToUtf8(Payload))) + '.' +
                    IcsBase64UrlEncode(String(StringToUtf8(Signature)));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

{$ENDIF USE_SSL}

end.
