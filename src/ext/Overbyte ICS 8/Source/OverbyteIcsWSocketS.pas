{*_* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Author:       François PIETTE
Description:  A TWSocket that has server functions: it listen to connections
              an create other TWSocket to handle connection for each client.
Creation:     Aug 29, 1999
Version:      8.64
EMail:        francois.piette@overbyte.be     http://www.overbyte.be
Support:      https://en.delphipraxis.net/forum/37-ics-internet-component-suite/
Legal issues: Copyright (C) 1999-2020 by François PIETTE
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
Sep 05, 1999 V1.01 Adpted for Delphi 1
Oct 09, 1999 V1.02 Added intermediate class TCustomWSocket
Nov 12, 1999 V1.03 Added OnClientCreate event just after client component has
                   been created.
Apr 02, 2000 V1.04 Added FSessionClosedFlag to avoid double SessionClosed
                   event triggering
Apr 13, 2002 V1.05 When sending banner to client, add LineEnd instead of CR/LF
                   as suggested by David Aguirre Grazio <djagra@xaire.com>
Sep 13, 2002 V1.06 Check if Assigned(Server) in TriggerSessionClosed.
                   Reported by Matthew Meadows <matthew.meadows@inquisite.com>
Sep 16, 2002 V1.07 Fixed a Delphi 1 issue in TriggerSessionClosed where
                   property was used in place of field variable.
Jan 04, 2003 V1.08 Renamed BannerToBusy to BannerTooBusy. This will cause
                   trouble in applications already using this property. You
                   have to rename the property in your app !
Jan 24, 2003 V5.00 Skipped to version 5 because of SSL code
Jan 26, 2004 V5.01 Introduced ICSDEFS.INC and reordered uses for FPC
                   compatibility.
May 01, 2004 V5.02 WMClientClosed was incorrectly referencing global Error
                   variable instead of the real winsock error code. Now pass
                   the errcode in WParam at the time of PostMessage.
                   Removed Forms and Graphics units from the uses clause.
May 23, 2005 V5.03 Added intermediate variable NewHSocket in procedure
                   TriggerSessionAvailable
Dec 30, 2005 V6.00b A.Garrels added IcsLogger
Jan 06, 2008 V6.01 Angus added Disconnect(Client) and DisconnectAll
May 01, 2008 V6.02 A. Garrels - Function names adjusted according to changes in
                   OverbyteIcsLibrary.pas.
May 14, 2008 V6.03 A. Garrels - Type change from String to AnsiString in
                   TWSocketClient (FPeerPort and FPeerAddr).
Aug 11, 2008 V6.04 A. Garrels - Type AnsiString rolled back String.
Nov 6,  2008 V7.00 Angus added CliId property used to ensure correct client freed
                    (did not call it ID to avoid conflicts with existing clients)
Aug 8,  2010 V7.01 FPiette enhanced TriggerSessionAvailable so catch exception
                   in client class constructor and ClientCreate, and close the
                   remote socket in that case.
Feb 4,  2011 V7.02 Angus added bandwidth throttling using TCustomThrottledWSocket.
                   Client sockets inherit server settings for BandwidthLimit and
                   BandwidthSampling, but these can be changed ideally in
                   OnClientCreate event, but also in OnClientConnect but note a
                   timer may have been started by then so better to default to
                   BandwidthLimit=0 and set it, than to disable it.
Apr 15, 2011 V7.03 Arno prepared for 64-bit.
May 13, 2011 V7.04 Anton S. found a small issue with CliId.
May 2012 - V8.00 - Arno added FireMonkey cross platform support with POSIX/MacOS
                   also IPv6 support, include files now in sub-directory
Jul 21, 2012 V8.01 Fix in TCustomMultiListenWSocketServer.TriggerClientConnect.
Jun 03, 2013 V8.02 FPiette added unit "Types" so that some inlines are
                   expanded.
Jun 09, 2013 V8.03 FPiette WMClientClosed clear CliId before freeing.
Aug 18, 2013 V8.04 Arno - It was not possible to clear both string properties
                   Banner and BannerTooBusy in OI since empty strings were not
                   stored in the .dfm.
Aug 18, 2013 V8.05 Arno added some default property specifiers.
Mar 10, 2015 V8.06 Angus CloseDelayed when too many clients so closes cleanly
Mar 23, 2015 V8.07 Angus onSslServerName and OnBgException events set for clients
Oct 26, 2016 V8.36 Angus TWSocketMultiListenItem now has SslEnable moved from SSL class
                   Added extended exception information
Nov 9,  2016  V8.37 Client inherits server SocketErrs
Apr 11, 2017  V8.45 Added multiple SSL host support to TSslWSocketServer.
                    There is a new IcsHosts property which allows multiple hosts
                      to be specified, each with one or two IP addresses and
                      non-SSL and SSL port bindings, SSL certificates and private
                      key, SSL context and security level, and other web server
                      host related properties (not used here).
                    If IcsHosts is specified, TSslWSocketServer ignores existing
                      bindings and SSLContext, and creates new bindings and
                      initialises an SSL context for each host checking and
                      reporting all server certificate chains.
                    IcsHosts includes SslSrvSecurity SSL server security
                       level, that sets protocol, cipher and SslSecLevel according
                       to eight levels from sslSrvSecNone to sslSrvSecHigh192 to
                       avoid needing to set protocols and ciphers in SSL context.
                    IcsHosts includes SslCert, SslKey, SslPassword and SslInter.
                      SslCert may be a file name or a ASCII PEM string containing
                      an Ssl server certificate. The file may be PEM/CER/DER/PFX/P12/etc,
                      either a single certificate or bundle with private key and
                      any intermediates (PEM/PFX/P12 only), SslPassword is the private
                      key password if encrypted.  If a bundle is not found, SslKey is
                      a PEM file or ASCII PEM private key, and SslInters is any
                      intermediate SSL certificates used to sign the server SSL cert
                      as a file name in PEM/CER/DER format or ASCII PEM.
                    TSslWSocketServer has new RootCA property which should be loaded
                      with CA Root certificates to validates the server chain and
                      new DHParams property for a context DHParams file or string.
                    The ValidateHosts property checks all host properties and
                      attempts to validate SSL certificate chains and hosts,
                      it keeps certificate chain information in the IcsHosts CertInfo
                      property and validation warnings or error in ErrInfo.
                    TWSocketClient includes new properties IcsHostIdx, MultiListenIdx
                      and HostTag to identify which IcsHost and MultiListen socket
                      accepted the connection.  Published client server and remote peer
                      address and port as CServerAddr, CServerPort, CPeerAddr and
                      CPeerPort since many clients need this information.
Apr 20, 2017  V8.46 New RootCA property is now a String (filename or base84 string)
                    Improved IcsHost.GetDisplayName a little
                    Set IcsLogger for SSL context
May 16, 2017  V8.47 IcsHosts keeps file time stamps of SSL certs to check if
                      changed, and BindInfo with reportable bindings.
                    Added IcsLoadIcsHostsFromIni function which loads IcsHosts from
                      an open INI file to simplify application creation.
                    Fixed IcsLogger conditional.
May 24, 2017  V8.48 ValidateHosts has options to return all errors as a string
                      instead of raising an exception on the first error.  The idea
                      is that some hosts may still work, even if one or more SSL
                      certificates are bad.
                    Added RecheckSslCerts which shoulld be called at least once a
                      day (after midnight) to check if new SSL certificates are
                      available and if old ones have expired.
                    Added ListenAllOK which returns true if all sockets are listening
                      OK, note starting a multilistener server does not give errors
                      if some listeners fail due to port conflicts.
                    Added ListenStates which returns a multiline string listing the
                       IP, port, SSL and state of all socket listeners.
                    Updated Added IcsLoadIcsHostsFromIni to add web server properties.
June 23, 2017 V8.49 Fixes so we support MacOS again, thanks to Michael Berg.
                    Added more elements to IcsHosts for a .well-known path and
                      web redirection.
                    Added MultiListenEx which opens all possible sockets ignoring
                      errors, which are returned as a string.
Aug 10, 2017  V8.50 Minor clean up
Nov 22, 2017  V8.51 SSL certificate file stamp now stored as UTC date to avoid
                       summer time triggers as file system stamps change
Feb 14, 2018  V8.52 Better error reporting when validating SSL certificates
                    Add TLSv3 ciphers for OpenSSL 1.1.1 and later only
Jun 12, 2018  V8.55 sslSrvSecInter/FS now requires TLS1.1, PCI council EOF TLS1.0 30 June 2018
Jul 6, 2018   V8.56 Added OnSslAlpnSelect called after OnSslServerName for HTTP/2.
Oct 5, 2018   V8.57 Fixed bug so that a newly found SSL certificate is immediately
                      loaded to the context.
                    IcsHosts INI file now accepts enum string for SslSecLevel, ie
                       SslSecLevel=sslSrvSecHigh as well as sslSrvSecHigh=5 .
                    IcsHosts INI file prefers new HostEnabled to older Enabled,
                       avoids confusion with other Enabled properties.
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
                    Added LoadOneCert which consolidates all certificate loading code
                       from ValidateHosts and RecheckSslCerts.
Oct 19, 2018  V8.58 Increased ListenBacklog property default to 15 to handle
                      higher server loads before rejecting new connections.
                    Documentation on IcsHosts and main components.
Dec 04, 2018  V8.59 Sanity checks reading mistyped enumerated values from INI file.
                    Updated ListenStates so unit compiles without USE_SSL
                    Added AUTO_X509_CERTS define set in OverbyteIcsDefs.inc which
                      can be disabled to remove a lot of units if automatic SSL/TLS
                      ordering is not required, saves up to 350KB of code.
Mar 18, 2019  V8.60 Added WebLogIdx to IcsHosts for web server logging.
                    Added sslSrvSecTls12Less and sslSrvSecTls13Only to disable
                       in server IcsHosts if TLS1.3 fails.
Aug 06, 2019  V8.62 When ordering X509 certificate, ChallFileSrv challenge now
                     uses separate local web server for servers not using ports
                      80 or 443 such as FTP, SMTP, proxies, etc.
                    If IcsHosts SslCert is not found but have a valid directory,
                      try default certificate file name based on Common Name instead,
                      ie www_domain_com.pfx.  Ideally application should check if
                      SslCert changes during ValidateHosts and update persistent
                      storage.
                    Moved BuildCertName here from X509Certs.
                    Added source to HandleBackGroundException so we know where
                        errors come from, when using IcsLogger.
Nov 18, 2019 V8.63 ValidateHosts, RecheckSslCerts and LoadOneCert have new
                     AllowSelfSign to stop errors with self signed certificates.
                   Automatic cert ordering now works if cert file name has -bundle
                     or -cert appended to end.
                   IcsHosts has new AuthSslCmd property for when SSL is allowed
                     on non-SSL port after AUTH SSL command or similar.
                   Automatic cert ordering now closes the account and local web
                     server automatically and after order errors, and when the
                     the server is stopped.
                   Automatic cert ordering now Logs activity via the SslX509Certs
                     component since this one does not have logging.
                   Corrected INI file reading NostEnabled instead of HostEnabled.
May 18, 2020 V8.64 IcsHosts allows NonSSlPort to be zero for random port, not for SSL.
                   Added BindPort read only property with real port while listening.
                   Added BindSrvPort to IcsHosts set while listening.
                   ListenStates now shows BindPort rather than requested port.
                   IcsHosts has new AuthForceSsl property, login only allowed once
                     SSL/TLS negotiated so credentials never sent clear.
                   Added sanity check to OrderClose.
                   Support ChallengeType=ChallAlpnApp for tls-alpn-01 SSL
                      ertificate challenge, client has new OnClientAlpnChallg
                      event that should provide the new self signed ACME certificate
                      for the challenge sent using a temporary SslContext.
                   Support CertChallenge=ChallFileApp for http challenge, needs
                       code adding in HTTP server onWellKnownDir event but avoids
                       writing files.
                   Removed ALPN handling added in V8.62 which was called too
                      late by OpenSSL to change the SSL context, now checking
                      ALPN earlier from new ClientHello callback.
                   Breaking change!  Internally replaced FRootCAX509 with FX509CAList
                      TX509List for use by ValidateCertChain as Root CA store,
                      specified by file RootCA, loaded by LoadRootCAList and
                      available as RootCAList.  Any applications directly calling
                      ValidateCertChain will need to load CA certificates into a
                      TX509List to pass to that function.
                   Create a self signed SSL certificate so server can start if
                      certificate file can not be found or is missing.  Needed
                      for ChallengeType=ChallAlpnApp to create a new certificate,
                      but always done to make life easier.  Tries to use the
                      specified certificate directory, TEMPDIR if none specified.
                   Don't start SSL certificate order until server is listening.
                   ACME tls-alpn-01 challenge context swapping now logged to
                      X509Certs log instead of debug log.



Quick reference guide:
----------------------

TWSocketServer will normally be used to listen on a given tcp port. When a
client connect, it will instanciate a new TWSocketClient component to handle
communication with client. Normally you will derive your own component from
TWSocketClient to add private data and methods to handle it. You tell
TWSocketServer which component it has to instantiate using ClientClass
property. You have to initialize instances from OnClientConnect event handler.
TWSocketServer maintain a list of connected clients. You can access it using
Client[] indexed property and ClientCount property.


IcsHosts
--------

When originally designed TWSocketServer only supported listening on a single IP
address and port, subsequently MultiListenSockets were added to listen on multiple
IP addresses and ports, and TSslWSocketServer SSL support required a lot of extra
code in the application to specify SSL certificates, protocols, ciphers and
security using multiple SslContexts for multiple hosts.

The IcsHosts property is an alternate way for specifying multiple listeners for
TSslWSocketServer that allows multiple hosts to be specified, each with one or
two IP addresses and non-SSL and SSL port bindings, SSL certificates and private
key (perhaps combined in a bundle), SSL context and security level, and other web
server host related properties (used by higher level components).  Each IcsHost
has one or more HostNames to which it will recognise, that can share IP addresses.

If IcsHosts is specified, TSslWSocketServer ignores existing bindings and SSL
context, and creates new bindings and initializes an SSL context for each host
checking and reporting all server certificate chains.  To ease implementation,
functions are provided to read IcsHosts and TWSocketServer from an INI file, or
they may be specified through IDE form properties and saved by other means.

Note IcsHosts is only available for TSslWSocketServer, not TWSocketServer, but
you don't need to use SSL for any Hosts.

HostNames     - One or more domain Host Names to which the server will respond,
                comma separated list, no quotes.  Host Names are matched initially
                against SSL Server Name Indication (SNI), or against the HTTP
                Host: header if no SSL or SNI for web and proxy servers. Note
                INI file reads as Hosts.  Wild card host names are not allowed,
                but SNI may match a wild card certificate to an IcsHost.
HostEnabled   - True or False if this IcsHost is enabled, NOTE INI file also
                reads Enabled if HostEnabled missing for backward compatibility.
BindIpAddr    - Listening IP Address for this IcsHost, may be 0.0.0.0 for all IP
                Addresses, must exist.  Multiple IcsHosts can use the same IP
                Address which will then be chosen from HostNames using SNI or
                Host: header.
BindIpAddr2   - Optional second IP Address for this IcsHost, perhaps an IPv6
                address.
BindNonPort   - Optional non-SSL/TLS Port, may be blank or zero if only SSL is
                supported by IcsHost, usually 80 for HTTP, required if
                WellKnownPath specified for SSL automatic certificates.
BindSslPort   - Optional SSL/TLS Port, may be blank or zero if SSL not supported
                by IcsHost, if used generally 443 for HTTPS, and several other SSL
                parameters are required.  Either BindNonPort or BindSslPort is
                required.
HostTag       - A short alphabetic name for the IcsHost, used variously in
                high level servers.  The web application server uses HostTag in
                the AddGetHandler, AddPostHandler and AddGetAllowedPath to cause
                that handler to be matched.  The proxy server uses HostTag to
                match source to one or more targets.  When SocketServer creates
                a TWSocketClient for a new connection it sets the IcsHostIdx and
                HostTag properties to this value, also ServerAddr and ServerPort
                for the bindings.
Descr         - Optional free description of the IcsHost, may be used for logging.
Proto         - Optional high level protocol used by this IcsHost, used variously
                in servers.  The proxy server uses HTTP, SMTP, POP3, etc.
ForwardProxy  - Optional True/False used by the proxy server if this IcsHost is
                functioning as a Forward Proxy rather than a Reverse Proxy. A
                forward supports multiple targets according to the URL, while a
                reverse proxy generally ignores the URL and has a single fixed
                target, sometimes multiple fixed targets depending on the URL.
                See OverbyteIcsProxy.pas for more information.
WebDocDir     - Optional default web document directory for this IcsHost, used by
                the web server.
WebTemplDir   - Optional default web template directory for this IcsHost, used by
                the web server.
WebDefDoc     - Optional default web document for this IcsHost, used by the web
                server.
WebLogDir     - Optional web logging directory for this IcsHost, for use by web
                server applications (not by the server itself which has not
                logging).
WebLogIdx     - Optional web logging index for this IcsHost, for use by web
                server applications (not by the server itself which has not
                logging).
AuthSslCmd    - Optional, if SSL/TLS should be initialised to support an AUTH SSL
                command or similar on an initial non-SSL connection.
AuthForceSsl  - Optional, if login only allowed once SSL/TLS negotiated so
                   credentials never sent clear.
SslCert       - Optional SSL server certificate file name, may be PEM, DER, PFX,
                P12, P7 format, optionally a bundle including a private key and
                one or more intermediate certificates.  Required if BindSslPort
                set. If a private key is included, will use SslPassword for an
                encrypted file. Rather than a file name, may be an ASCII PEM string
                containing the certificate without any line endings.  HostNames
                will be checked against those listed on the certificate, and a not
                warning given for mismatches so a single certificate needs to
                contain all the HostName, or wild cards * so they match.
                TSslWSocketServer has a method RecheckSslCerts that should be
                called from the server application periodically, at least once
                a day, which will check the certificate file time stamp and
                reload it if changed, issue warnings if it expires within
                CertExpireDays (default 30) and optionally order a new
                certificate, see CertSupplierProto below.  Note if automatic
                certificate ordering is used, the file name in SslCert must
                conform to the format used by the TSslX509Certs component, with
                the host name having all dots replaced by underscore and * by x,
                then with suffix .pfx or -bundle.pem, ie
                test3_telecom-tariffs_co_uk-bundle.pem or
                test3_telecom-tariffs_co_uk.pfx.
SslKey        - Optional SSL private key file name, PEM format, will use
                SslPassword for an encrypted file.  Ignored if SslCert was a
                bundle file with a private key.  Note all SSL servers need an
                SSL certificate and matching private key to function, and these
                are checked before the server will start. Rather than a file
                name, may be an ASCII PEM string containing the private key
                without any line endings.
SslInter      - Optional SSL intermediate certificate bundle file name, PEM, DER,
                P12 or P7 format. Ignored if SslCert was a bundle with
                intermediate certificates.  The SSL certificate chains is checked
                to ensure the server certificate is signed by an intermediate or
                trusted root certificate, and likewise the intermediate(s). The
                TSslWSocketServer RootCA property specifies a PEM bundle file
                containing the trusted root certificates, if not specified an
                internal bundle of about 36 major root certificates is used.
SslPassword   - Optional password for the SSL private key, if encrypted.  Note
                this is clear text in the INI file, steps should be taken to read
                an encrypted password if security is required.  Beware most
                PFX/P12 bundles need a password, since Windows will not import
                them without a password.
SslSrvSecurity - Optional SSL server security level, that sets protocol, cipher
                and SslSecLevel according to eight levels from type TSslSrvSecurity:
                sslSrvSecNone, sslSrvSecSsl3, sslSrvSecBack, sslSrvSecInter,
                sslSrvSecInterFS, sslSrvSecHigh, sslSrvSecHigh128, sslSrvSecHigh192.
                Details of each are in the OverbyteIcsSSLEAY.pas unit.  Beware the
                server may not start, ie High128 requires an RSA private key length
                greater than the 2,048 bits commonly used.  If not specified,
                sslSrvSecDefault is used which is currently sslSrvSecInterFS
                meaning TLSv1.1 or later with forward security ciphers.
WellKnownPath - Optional, full file directory path for .Well-Known web URLs, used
                by the web and proxy servers for automated SSL certificates.
WebRedirectURL - Optional, a web server redirection URL, used in the proxy server
                to redirect HTTP connections to HTTPS, if WebRedirectStat is none
                zero.  Not currently used by the web server, but web server
                applications can add event code to use these values, see event
                SslHttpAppSrv1GetDocument in OverbyteIcsSslMultiWebServ1.pas.
                Or more intelligent redirection could be implemented like
                changing http:// to https://.
WebRedirectStat - Optional, a web server redirection status code, 301, 302, 307
                or 308 depending on reason.
CertSupplierProto - Optional, if SSL X509 certificates are to be automatically
                ordered, downloaded and installed, specifies the Supplier and
                Protocol to be used as type TSupplierProto. Currently supports
                SuppProtoNone, SuppProtoAcmeV2 and SuppProtoCertCentre. Ignored
                unless TSslWSocketServer property SslCertAutoOrder is True.
                Note any SSL certificates ordered will use all HostNames so must
                support multiple Subject Alternative Names if more than one host
                is specified.  Note wild card certificates can not currently be
                ordered by IcsHosts, but can be done using TSslX509Certs.
                Automatic certificate ordering is triggered by calling the server
                method RecheckSslCerts after the server has started listening,
                which checks all certificates and chains for expiry within
                CertExpireDays (default 30) and will then order a new certificate
                for any that fail, including certificate file missing.  The server
                application should call RecheckSslCerts at least once a day, but
                it can be more often to give more chances to check for ordering
                problems.  The TSslX509Certs has an internal timer that checks
                for order completion and calls an onNewCert event when the new
                certificate is ready, this event should call RecheckSslCerts again
                which will find the new certificate file and load it into
                SslContext.
CertDirWork   - Optional, if CertSupplierProto is not SuppProtoNone, specifies
                the Certificate Database Working Directory, in which an account
                that matches CertSupplierProto should already have been created,
                see OverbyteIcsSslX509Certs.pas for more information.  All new
                certificates, requests and private keys are saved in the work
                directory with a unique order number, then again with the final
                name format, and finally the certificate bundles as PEM and PFX
                are copied to the directory used by SslCert.  CertDirWork must
                not be the same directory as SslCert.  Generally, CertDirWork
                should be the same for all Hosts that order certificates for the
                server, because the TSslX509Certs currently only checks for
                completed order for one supplier database at a time.  Different
                directories can be used, provided certificates do not expire the
                same day.
CertChallenge - Optional, if CertSupplierProto is not SuppProtoNone, specifies
                the Challenge Type as TChallengeType, used by the supplier to
                check the domain names for the certificate resolve to this server.
                Currently supports ChallNone, ChallFileUNC, ChallFileFtp,
                ChallFileSrv, ChallFileApp, ChallDnsAuto, ChallDnsMan, ChallEmail,
                ChallAlpnUNC, ChallAlpnSrv and ChallAlpnApp, which are described
                in OverbyteIcsSslX509Certs.pas.  Note most challenges need a
                little extra code in the server application.
CertProduct   - Optional, primarily for CertSupplierProto is SuppProtoCertCentre
                to specify the particular certificate issuer and product,
                currently only AlwaysOnSSL.AlwaysOnSSL supported since all
                commercial certificates require contact details not in these
                properties.  For SuppProtoAcmeV2, use Let's Encrypt currently
                for descriptive purposes although in theory other suppliers may
                use the same Acme2 protocol for other certificates.
CertPKeyType  - Optional, specifies the new SSL certificate Private Key algorithm
                and key length as type TSslPrivKeyType. Typically use
                PrivKeyRsa2048, PrivKeyRsa3072, PrivKeyRsa4096, PrivKeyECsecp256,
                PrivKeyECsecp384, PrivKeyECsecp512 or PrivKeyEd25519, although
                the supplier may reject any of them. Beware RSA keys longer than
                4,096 bits can take many minute to generate blocking the server.
CertSignDigest - Optional, specifies the new SSL certificate request signing
                digest as type TEvpDigest.  Typically use Digest_sha256,
                Digest_sha384 or Digest_sha512, there are now SHA3 options but
                unlikely to be supported by suppliers yet.


Example from \Samples\Delphi\SslInternet\OverbyteIcsSslMultiWebServ.ini which can
be read using the function IcsLoadIcsHostsFromIni.

[Host4]
Hosts=test7.ftptest.org,test7.ftptest.org.uk,test7.ftptest.co.uk
HostTag=HTTP-FTPTEST
Desc=test7-LetsEncrypt
BindIpAddr=192.168.1.123
BindNonPort=80
BindSslPort=443
HostEnabled=False
SslSecLevel=sslSrvSecInterFS
WellKnownPath=c:\websites\well-known\
WebRedirectURL=https://www.telecom-tariffs.co.uk/
WebRedirectStat=301
SslCert=c:\certificates\local\test7_ftptest_org.pfx
SslPassword=password
CertSupplierProto=SuppProtoAcmeV2
CertProduct=Let's Encrypt
CertDirWork=c:\weblogs\acme-certs\
CertChallenge=ChallFileUNC
CertPKeyType=PrivKeyRsa2048
CertSignDigest=Digest_sha256

Once IcsHosts have been validated, a number of read only properties are available
with more information about the IcsHost from the certificate and bindings, that
may be usefully logged for configuration and error checking purposes.

SslCtx       - TSslContext component used by IcsHost.
HostNameTot  - Number of items in HostNames TStrings.
DisplayName  - IcsHost display name, variously using HostTag, Descr, and bind
               IP addresses and ports.
CertDomains  - Comma separated list of SSL certificate host names from Subject
               Alternate Names field.
CertInfo     - A long multiple line text block describing all the main fields of
               one or more SSL certificates in the chain including subject,
               issuer, expiry, public key type and signature method.
BindInfo     - List of one or more IP addresses and ports.
CertExiry    - SSL certificate expiry UTC date and time, as TDateTime.
CertFStamp   - Unix file time stamp for SSL server certificate, to check if
               changed.
InterFStamp  - Unix file time stamp for SSL intermediate certificates, to check
               if changed.
CertErrs     - Description of any errors found in the SSL certificate chain
               during validation.
CertValRes   - SSL certificate chain validation result as type TChainResult,
               chainOK, chainFail, chainWarn, chainNone.
BindIdxNone  - MultiListenIdx for first IP address, non-SSL.
BindIdxSsl   - MultiListenIdx for first IP address, SSL.
BindIdx2None - MultiListenIdx for second IP address, non-SSL.
BindIdx2Ssl  - MultiListenIdx for second IP address, SSL.
BindSrvPort  - Actual listening port, useful if Port=0 for dynamic port.


0Auth2 Consideration
--------------------

If the CertSupplierProto requirss 0Auth2 authentication, ie SuppProtoCertCentre,
a TSslX509Certs event is triggered with a browser URL that should be visited to
login to the supplier account.  For a background server, the application can
send an email to an administrator who performs the login manually on the same
PC as the server is running, and the TSslX509Certs component will accept and
save the authentication token automatically and use it for the next certificate
order attempt. Authentication tokens usually expire after one to 24 hours. Often
a refresh token is also supplied allowing the server to automatically refresh
the token, sometimes within the expiry period, sometimes for several months.


TSslWSocketServer
-----------------

Proto        - Server protocol, always TCP.
Addr         - Server listen IP address, IPv4 or IPv6, maybe 0.0.0.0 or :: to
               listen on all available addresses, ignored if any IcsHosts
               specified.  IP address must exist and not be in use elsewhere
               for the same port.
Port         - Server listen port, usually 80 or 443, ignored if any IcsHosts
               specified, zero means dynamic port.
BindPort     - While listening actual port, useful if Port=0 for dynamic port.
SocketFamily - IP address socket family as TSocketFamily, from sfIPv4, sfIPv6.
SslEnable    - True if an SSL connection should be negotiated. ignored if any
               IcsHosts specified.
SslContext   - Assign to an TSslContext component for SSL support, where SSL
               certificates, keys, protocols and ciphers are specified, ignored
               if any IcsHosts specified.
MultiListenSockets - Allows one or more extra server listen IP addresses and
               ports to be specified, as type TWSocketMultiListenCollection,
               allowing server to listen on several IP addresses/ports at the
               same time, in addition to the that specified as Addr/Port props.
               Each TWSocketMultiListenItem has Addr, Port, SocketFamily,
               SslEnable and ListenBacklog properties. Better to use IcsHosts
               for new applications which does the same, ignored if any IcsHosts
               specified.
MultiListenIndex - Read only, which listen socket accepted last connection, -1
               if default Addr.Poprt used, 0 or above is index into
               MultiListenSockets collection.
MaxClients   - Maximum number of simultaneous clients the server should accept
               if non-zero.  Any further clients will receive then BannerTooBusy
               response and the connection closed, until earlier connections
               are closed.
Banner       - If non-blank, a text string that will be sent in response to a
               new incoming connection, should generally be blank.
BannerTooBusy - If non-blank, a text string that will be sent once MaxClients
               is exceeded.
ClientClass  - The class type the application has derived from TSslWSocketClient
               for client application code.
Client       - Currently active clients of ClientClass, indexed base zero.  Note
               the index value may change each time a new client connects or
               disconnects, so check CliId to confirm it's the correct one.
ClientCount  - Number of active client connected.
SocketErrs   - How socket error messages should be presented as type TSocketErrs,
               wsErrTech or wsErrFriendly.
ExclusiveAddr - True is other applications should be blocked from sharing the
               server IP addresses.
ListenBacklog - How many new client connections should be queued by Windows while
               the server accepts them, before the server starts rejecting new
               connections by immediately closing them.  Recommended as 15 for
               heavy use servers, may be up to 250.
IcsHosts     - Allows one or more TIcsHosts to be set, as TIcsHostCollection, an
               alternate way for specifying multiple listeners that allows
               multiple hosts to be specified, each with one or two IP addresses
               and non-SSL and SSL port bindings, SSL certificates and private
               key (perhaps combined in a bundle), SSL context and security level,
               and other web server host related properties (used by higher level
               components).  Each IcsHost has one or more HostNames to which it
               will recognise, that can share IP addresses.  See above for more
               detail.
RootCA       - Specifying a file name containing a PEM bundle of trusted root SSL
               certificates allows validation of SSL server certificate chains.
               ICS includes RootCaCertsBundle.pem (large) and TrustedCABundle.pem
               (medium size), and a default built-in (small) that will be used
               if no file is specified.
DHParams     - Specifies a DHParams file name, created using the PenTools sample,
               or use the provided dhparam1024.pem or dhparam2048.pem files. Used
               for DH and DHE ciphers, but not needed for modern ECDHE ciphers.
               Rather than a file name, may be an ASCII PEM string containing
               the DHParams without any line endings.
SslCliCertMethod - Allows server to request a client SSL certificate from the
               browser or remote application, as type TSslCliCertMethod, with
               sslCliCertNone, sslCliCertOptional or sslCliCertRequire. Require
               will close the connection unless a valid certificate is received
               and validated against RootCA. Beware requesting a client
               certificate usually causes the browser to prompt the user for
               which certificate to send which can be obtrusive.
CertExpireDays - When using IcsHosts, the number of days before an SSL server
               certificate is due to expire that warnings will be generated (by
               the method RecheckSslCerts, perhaps triggering automatic SSL
               certificate ordering.
SslCertAutoOrder - True if IcsHosts are allowed to order and install SSL
               certificates automatically.  Requires SslX509Certs property to
               be set, and CertSupplierProto set for any IcsHost that will order
               certificates.
SslX509Certs - Assign to a TSslX509Certs component if automatic SSL certificate
               ordering is required.  Ir ia very important that the onCertProg
               is used to log progress messages from the certificate ordering
               process in case of errors.  The onCertsChallengeDNS event is
               called if a DNS server should be updated, onCertsOAuthAuthUrl if
               0Auth2 authenication is needed, and onCertsNewCert when a new
               certificate is available which should be logged and the
               RecheckSslCerts method called to cause the server to load it.


TSslWSocketClient
-----------------

Each new incoming connection to TSslWSocketServer causes a new instance of
TSslWSocketClient to be created, with a number of read only properties set,
that may be useful for client application code.  Generally, applications will
create their own class descended from TSslWSocketClient which is where all
the code to listen to requests and send responses will go.

Server      - TCustomWSocketServer component to which the client belongs.
PeerAddr    - Remote IP address of the client, IPv4 or IPv6.
PeerPort    - Remote IP port of the client.
SessionClosedFlag - True if the client is in the process of closing.
CliId       - A sequential client ID number that may be used to identify the
              client, note clients are creating and destroyed regularly.
IcsHostIdx  - If 0 or higher index into the IcsHosts collection, -1 if
              IcsHosts not used.
MultiListenIdx - -1 if default SocketServer listener used, 0 or above is
              index into MultiListenSockets collection.
HostTag     - A short alphabetic name for the IcsHost, used variously in
              high level servers.
CServerAddr - Local server IP address for listener.
CServerPort - Local server IP port for listener.



 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{$IFNDEF ICS_INCLUDE_MODE}
unit OverbyteIcsWSocketS;
{$ENDIF}

interface

{$B-}           { Enable partial boolean evaluation   }
{$T-}           { Untyped pointers                    }
{$X+}           { Enable extended syntax              }
{ You must define USE_SSL so that SSL code is included in the component.    }
{ Either in OverbyteIcsDefs.inc or in the project/package options.          }
{$I Include\OverbyteIcsDefs.inc}
{$IFDEF COMPILER14_UP}
  {$IFDEF NO_EXTENDED_RTTI}
    {$RTTI EXPLICIT METHODS([]) FIELDS([]) PROPERTIES([])}
  {$ENDIF}
{$ENDIF}
{$IFDEF COMPILER12_UP}
    { These are usefull for debugging !}
    {$WARN IMPLICIT_STRING_CAST       OFF}
    {$WARN IMPLICIT_STRING_CAST_LOSS  OFF}
    {$WARN EXPLICIT_STRING_CAST       OFF}
    {$WARN EXPLICIT_STRING_CAST_LOSS  OFF}
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

uses
{$IFDEF MSWINDOWS}
    {$IFDEF RTL_NAMESPACES}Winapi.Messages{$ELSE}Messages{$ENDIF},
    {$IFDEF RTL_NAMESPACES}Winapi.Windows{$ELSE}Windows{$ENDIF},
    {$IFDEF RTL_NAMESPACES}System.Types{$ELSE}Types{$ENDIF},
    {$IFDEF RTL_NAMESPACES}System.IniFiles{$ELSE}IniFiles{$ENDIF},
    {$IFDEF RTL_NAMESPACES}System.TypInfo{$ELSE}TypInfo{$ENDIF},
    OverbyteIcsWinsock,
{$ENDIF}
{$IFDEF MACOS}  { V8.49 }
    System.IniFiles,
    System.Types,
{$ENDIF}
{$IFDEF POSIX}
    Posix.Errno,
    Posix.NetinetIn,
    Posix.SysSocket,
    Ics.Posix.WinTypes,
    Ics.Posix.Messages,
{$ENDIF}
    {$IFDEF RTL_NAMESPACES}System.SysUtils{$ELSE}SysUtils{$ENDIF},
    {$IFDEF RTL_NAMESPACES}System.Classes{$ELSE}Classes{$ENDIF},
{$IFDEF USE_SSL}
    OverbyteIcsSSLEAY, OverbyteIcsLIBEAY,
{$ENDIF}
{$IFNDEF NO_DEBUG_LOG}
    OverbyteIcsLogger,
{$ENDIF}
{$IFDEF FMX}
    Ics.Fmx.OverbyteIcsWSocket,
    Ics.Fmx.OverbyteIcsSslX509Utils,
{$ELSE}
    OverbyteIcsWSocket,
    OverbyteIcsSslX509Utils,   { V8.64 }
{$ENDIF}
    OverbyteIcsUtils,
    OverbyteIcsTypes;

const
    WSocketServerVersion     = 864;
    CopyRight : String       = ' TWSocketServer (c) 1999-2020 F. Piette V8.64 ';
 { V8.62 ALPN requests that may arrive during SSL helo }
    AlpnAcmeTls1 = 'acme-tls/1';
    AlpnHttp11   = 'http/1.1';
    AlpnHttp2    = 'h2';

type
    TCustomWSocketServer       = class;
    TWSocketClient             = class;
    TWSocketClientClass        = class of TWSocketClient;
    TWSocketClientCreateEvent  = procedure (Sender : TObject;
                                            Client : TWSocketClient) of object;
    TWSocketClientConnectEvent = procedure (Sender : TObject;
                                            Client : TWSocketClient;
                                            Error  : Word) of object;

    TClientIdRec = record    { angus V7.00 }
        PClient : Pointer;
        CliId   : LongInt;
    end;
    PClientIdRec = ^TClientIdRec;

    { TWSocketClient is used to handle all client connections.           }
    { Altough you may use it directly, you'll probably wants to use your }
    { own derived component to add data and methods suited to your       }
    { application.                                                       }
    { If you use a derived component, then assign it's class to          }
    { TWSocketServer ClientClass property.                               }
    TWSocketClient = class(TWSocket)
    protected
        FBanner            : String;
        FServer            : TCustomWSocketServer;
        FPeerAddr          : String;
        FPeerPort          : String;
        FSessionClosedFlag : Boolean;
        FCliId             : LongInt;          { angus V7.00 }
{$IFDEF USE_SSL}
        FIcsHostIdx        : Integer;          { V8.45 }
        FMultiListenIdx    : Integer;          { V8.45 }
        FHostTag           : String;           { V8.45 }
        FServerAddr        : String;           { V8.45 }
        FServerPort        : String;           { V8.45 }
{$ENDIF} // USE_SSL
    public
        procedure   StartConnection; virtual;
        procedure   TriggerSessionClosed(ErrCode : Word); override;
        procedure   Dup(newHSocket : TSocket); override;
        function    GetPeerAddr: String; override;
        function    GetPeerPort: String; override;
        property    Server : TCustomWSocketServer read  FServer
                                                  write FServer;
        property    CliId : LongInt               read  FCliId              { angus V7.00 }
                                                  write FCliId;
        property    CPeerAddr : String            read  FPeerAddr;        { V8.45 }
        property    CPeerPort : String            read  FPeerPort;        { V8.45 }
{$IFDEF USE_SSL}
        property    IcsHostIdx : Integer          read FIcsHostIdx;       { V8.45 }
        property    MultiListenIdx : Integer      read FMultiListenIdx;   { V8.45 }
        property    HostTag : String              read FHostTag;          { V8.45 }
        property    CServerAddr : String          read FServerAddr;      { V8.45 }
        property    CServerPort : String          read FServerPort;      { V8.45 }
{$ENDIF} // USE_SSL
    published
        property    Banner : String               read  FBanner
                                                  write FBanner;
    end;

    { TWSocketServer is made for listening for tcp client connections.      }
    { For each connection, it instanciate a new TWSocketClient (or derived) }
    { to handle connection. Use ClientClass to specify your derived.        }
    TCustomWSocketServer = class(TWSocket)
    private
        procedure ReadBannerValue(Reader: TReader);
        procedure WriteBannerValue(Writer: TWriter);
        procedure WriteBannerTooBusyValue(Writer: TWriter);
        procedure ReadBannerTooBusyValue(Reader: TReader);
        function  IsBannerStored: Boolean;
        function  IsBannerTooBusyStored: Boolean;
    protected
        FBanner                 : String;
        FBannerTooBusy          : String;
        FClientClass            : TWSocketClientClass;
        FClientList             : TList;
        FClientNum              : LongInt;
        FMaxClients             : LongInt;
        FMsg_WM_CLIENT_CLOSED   : UINT;
        FBindPort               : string;                           { V8.64 }
        FOnClientCreate         : TWSocketClientCreateEvent;
        FOnClientConnect        : TWSocketClientConnectEvent;
        FOnClientDisconnect     : TWSocketClientConnectEvent;
        procedure DefineProperties(Filer: TFiler); override;
        procedure WndProc(var MsgRec: TMessage); override;
        procedure Notification(AComponent: TComponent; operation: TOperation); override;
        procedure TriggerSessionAvailable(Error : Word); override;
        procedure TriggerClientCreate(Client : TWSocketClient); virtual;
        procedure TriggerClientConnect(Client : TWSocketClient; Error : Word); virtual;
        procedure TriggerClientDisconnect(Client : TWSocketClient; Error : Word); virtual;
        function  GetClientCount : Integer; virtual;
        function  GetClient(nIndex : Integer) : TWSocketClient; virtual;
        procedure WMClientClosed(var msg: TMessage); virtual;
        function  MsgHandlersCount: Integer; override;
        procedure AllocateMsgHandlers; override;
        procedure FreeMsgHandlers; override;
    public
        constructor Create(AOwner: TComponent); override;
        destructor  Destroy; override;
        { Check  if a given object is one of our clients }
        function  IsClient(SomeThing : TObject) : Boolean;
        procedure Listen; override;                                   { V8.64 }
        procedure Disconnect(Client: TWSocketClient); virtual;        { angus V6.01 }
        procedure DisconnectAll; virtual;                             { angus V6.01 }
        property  BindPort: string                    read FBindPort; { V8.64 }
    protected
        { TWSocketClient derived class to instanciate for each client }
        property  ClientClass            : TWSocketClientClass
                                                      read  FClientClass
                                                      write FClientClass;
        { How many active clients we currently have }
        property  ClientCount   : Integer             read  GetClientCount;
        { Client[] give direct access to anyone of our clients }
        property  Client[nIndex : Integer] : TWSocketClient
                                                      read  GetClient;
    published
        { Banner sent to client as welcome message. Can be empty. }
        property  Banner                 : String     read  FBanner
                                                      write FBanner
                                                      stored IsBannerStored;
        property  BannerTooBusy          : String     read  FBannerTooBusy
                                                      write FBannerTooBusy
                                                      stored IsBannerTooBusyStored;
        property  MaxClients             : LongInt    read  FMaxClients
                                                      write FMaxClients
                                                      default 0;
        { Triggered when a client disconnect }
        property  OnClientDisconnect     : TWSocketClientConnectEvent
                                                      read  FOnClientDisconnect
                                                      write FOnClientDisconnect;
        { Triggered when a new client is connecting }
        property  OnClientConnect        : TWSocketClientConnectEvent
                                                      read  FOnClientConnect
                                                      write FOnClientConnect;
        { Triggered when a new client component has been created }
        property  OnClientCreate         : TWSocketClientCreateEvent
                                                      read  FOnClientCreate
                                                      write FOnClientCreate;
    end;

    TWSocketServer = class;

    TCustomMultiListenWSocketServer = class;

    TWSocketMultiListenItem = class(TCollectionItem {$IFDEF POSIX}, IIcsEventSource{$ENDIF})
    private
      FAddr: string;
      FHSocket: TSocket;
      FListenBacklog: Integer;
      FPort: string;
      FSocketFamily: TSocketFamily;
      FOldSocketFamily: TSocketFamily;
      FState: TSocketState;
      FPortNum: Integer;
      FLastError: Integer;
      FCloseInvoked: Boolean;
      FPaused: Boolean;
      FSelectEvent: LongWord;
{$IFDEF USE_SSL}
      FSslEnable : Boolean;         { V8.36 moved from SSL class }
{$ENDIF} // USE_SSL
      FBindPort: string;                           { V8.64 }
      procedure SetAddr(const Value: string);
      procedure SetSocketFamily(const Value: TSocketFamily);
      function GetAddrResolved: string;
  {$IFDEF POSIX} { IIcsEventSource }
    strict private
      FPxEventMask        : LongWord;
      FPxFileDescriptor   : Integer;
      FPxEventState       : TIcsAsyncEventState;
      FPxEventMessageID   : UINT;
      FPxEventWindow      : HWND;
      FPxObjectID         : NativeInt;
      function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
      function _AddRef: Integer; stdcall;
      function _Release: Integer; stdcall;
      function  GetEventMask: LongWord;
      procedure SetEventMask(const AValue: LongWord);
      function  GetNotifyMessageID: UINT;
      procedure SetNotifyMessageID(const AValue: UINT);
      function  GetNotifyWindow: HWND;
      function  GetEventState: TIcsAsyncEventState;
      function  GetFileDescriptor: Integer;
      procedure SetFileDescriptor(const AValue: Integer);
      function  GetObject: TObject;
      procedure SetEventState(const AValue: TIcsAsyncEventState);
      procedure SetNotifyWindow(const AValue: HWND);
      function  GetObjectID: NativeInt;
  {$ENDIF POSIX IIcsEventSource}
    protected
      procedure AssignDefaults; virtual;
      procedure SetCloseInvoked(const AValue: Boolean);
      function  GetCloseInvoked: Boolean;
      property  CloseInvoked: Boolean read GetCloseInvoked write SetCloseInvoked;
    public
      Fsin: TSockAddrIn6;
      constructor Create(Collection: TCollection); override;
      destructor Destroy; override;
      procedure Close;
      procedure Listen;
      function  OwnerServer: TCustomMultiListenWSocketServer;
      function  Pause: Boolean;
      function  Resume: Boolean;
      property  AddrResolved: string read GetAddrResolved;
      property  HSocket: TSocket read FHSocket write FHSocket;
      property  LastError: Integer read FLastError write FLastError;
      property  Paused: Boolean read FPaused;
      property  PortNum: Integer read FPortNum write FPortNum;
      property  State: TSocketState read FState write FState;
      function  SetAddressListChangeNotification: Boolean;
      function  SetRoutingInterfaceChangeNotification: Boolean;
      property  SelectEvent: LongWord read FSelectEvent;
      property  BindPort: string read FBindPort;                      { V8.64 }
    published
      property Addr: string read FAddr write SetAddr;
      property ListenBacklog: Integer           read  FListenBacklog
                                                write FListenBacklog default 5;
      property Port: string read FPort write FPort;
      property SocketFamily: TSocketFamily      read  FSocketFamily
                                                write SetSocketFamily
                                                default DefaultSocketFamily;
 {$IFDEF USE_SSL}
      property SslEnable : Boolean read FSslEnable write FSslEnable;   { V8.36 moved from SSL class }
{$ENDIF} // USE_SSL
   end;

    TWSocketMultiListenItemClass = class of TWSocketMultiListenItem;

    TWSocketMultiListenCollection = class(TOwnedCollection)
    protected
      function GetItem(Index: Integer): TWSocketMultiListenItem;
        {$IFDEF USE_INLINE} inline; {$ENDIF}
      procedure SetItem(Index: Integer; Value: TWSocketMultiListenItem);
        {$IFDEF USE_INLINE} inline; {$ENDIF}
    public
      constructor Create(AOwner     : TPersistent;
                         AItemClass : TWSocketMultiListenItemClass);
      function Add: TWSocketMultiListenItem;
          {$IFDEF USE_INLINE} inline; {$ENDIF}
      function FindItemIndex(const AHSocket: TSocket): Integer;
          {$IFDEF USE_INLINE} inline; {$ENDIF}
      function FindItemHandle(const AHSocket: TSocket): TWSocketMultiListenItem;
      function FindItemID(ID: Integer): TWSocketMultiListenItem;
          {$IFDEF USE_INLINE} inline; {$ENDIF}
      function Insert(Index: Integer): TWSocketMultiListenItem;
          {$IFDEF USE_INLINE} inline; {$ENDIF}
      function Owner: TCustomMultiListenWSocketServer;
      property Items[Index: Integer]: TWSocketMultiListenItem
                                                        read  GetItem
                                                        write SetItem; default;
    end;

    TCustomMultiListenWSocketServer = class(TCustomWSocketServer)
    private
        FMultiListenSockets: TWSocketMultiListenCollection;
        FMultiListenIndex: Integer;
    protected
        procedure Ml_Do_FD_CLOSE(AItem: TWSocketMultiListenItem;
                                  AMsg: TMessage); virtual;
        procedure MlListen(AItem: TWSocketMultiListenItem); virtual;
        procedure MlClose(AItem: TWSocketMultiListenItem); virtual;
        procedure MlSocketError(AItem: TWSocketMultiListenItem;
            const ASockFunc: String; ALastError: Integer = 0;
                FriendlyMsg: String = ''); virtual;  { V8.36 added FriendlyMsg }
        procedure MlPause(AItem: TWSocketMultiListenItem); virtual;
        procedure MlResume(AItem: TWSocketMultiListenItem); virtual;
        procedure MlSetAddr(var FldAddr              : string;
                            var FldSocketFamily      : TSocketfamily;
                            const FldOldSocketFamily : TSocketfamily;
                            const NewValue           : string); virtual;
        procedure MlSetSocketFamily(var FldSocketFamily    : TSocketfamily;
                                    var FldOldSocketFamily : TSocketfamily;
                                    const NewValue         : TSocketFamily);
        function  MultiListenItemClass: TWSocketMultiListenItemClass; virtual;
        procedure SetMultiListenIndex(const Value: Integer);
        procedure TriggerClientConnect(Client: TWSocketClient; Error: Word); override;
        procedure WMASyncSelect(var msg: TMessage); override;
    public
        constructor Create(AOwner: TComponent); override;
        destructor Destroy; override;
        function  Accept: TSocket; override;
        procedure Close; override;
        procedure Listen; override;
        procedure MultiListen; virtual;
        function  MultiListenEx: string; virtual;                    { V8.49 }
        procedure MultiClose; virtual;
        procedure ThreadAttach; override;
        procedure ThreadDetach; override;
        function  ListenAllOK: Boolean;                              { V8.48 }
        function  ListenStates: String;                              { V8.48 }
        property  MultiListenIndex: Integer read  FMultiListenIndex;

        property  MultiListenSockets: TWSocketMultiListenCollection
                                                      read  FMultiListenSockets
                                                      write FMultiListenSockets;
    end;

    TWSocketServer = class(TCustomMultiListenWSocketServer)
    public
        property  ClientClass;
        property  ClientCount;
        property  Client;
    published
    {$IFNDEF NO_DEBUG_LOG}
        property  IcsLogger;                                 { V5.04 }
    {$ENDIF}
        property  Banner;
        property  BannerTooBusy;
        property  MaxClients;
        property  MultiListenSockets;
        property  OnClientDisconnect;
        property  OnClientConnect;
    end;

{ You must define USE_SSL so that SSL code is included in the component.    }
{ Either in OverbyteIcsDefs.inc or in the project/package options.          }
{$IFDEF USE_SSL}
{*_* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Author:       François PIETTE
Description:  A component adding SSL support to TWSocketServer.
              Requires OpenSSL (http://www.openssl.org).
              More details in ReadMeIcsSsl.txt and IcsSslHowTo.txt.
              SSL demo applications can be found in /Delphi/SslInternet.
              If you use Delphi 7 and later, you may want to disable warnings
              for unsage type, unsafe code and unsafe typecast in the project
              options. Those warning are intended for .NET programs. You may
              also want to turn off deprecated symbol and platform symbol
              warnings.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{const
     SslWSocketServerVersion            = 100;
     SslWSocketServerDate               = 'Feb 02, 2003';
     SslWSocketServerCopyRight : String = ' TSslWSocket (c) 2003 Francois Piette V1.00.3 ';   }

type

  TClientAlpnChallgEvent = procedure (Sender: TObject; const Host: string; var CertFName: string) of object;   { V8.62 }


{ TIcsHost defines the bindings for an SSL TCP/IP server, usually a web server,
   such as which address and port to listen, which host names to accept using
   which SSL certificate, and server related set-up such as directories }

  TIcsHost = class(TCollectionItem)    { V8.45 }
  private
    FHostNames: TStrings;
    FHostEnabled: boolean;
    FBindIpAddr: String;
    FBindIpAddr2: String;
    FBindSslPort: integer;
    FBindNonPort: integer;
    FHostTag: String;
    FDescr: String;
    FProto: String;
    FForwardProxy: Boolean;
    FWebDocDir: string;
    FWebTemplDir: string;
    FWebDefDoc: string;
    FWebLogDir: string;
    FSslCert: string;
    FSslKey: string;
    FSslInter: string;
    FSslPassword: string;
    FSslSrvSecurity: TSslSrvSecurity;
    FCertDomains: string;
    FCertInfo: string;
    FBindInfo: string;
    FCertExiry: TDateTime;
    FCertFStamp: TDateTime;    { V8.51 was integer }
    FInterFStamp: TDateTime;  { V8.51 was integer }
    FCertErrs: string;
    FCertValRes: TChainResult;
    FBindIdxNone: Integer;
    FBindIdxSsl: Integer;
    FBindIdx2None: Integer;
    FBindIdx2Ssl: Integer;
    FWellKnownPath: string;    { V8.49 }
    { see http://www.iana.org/assignments/well-known-uris/well-known-uris.xhtml }
    FWebRedirectURL: string;   { V8.49 }
    FWebRedirectStat: integer; { V8.49 }
  { V8.57 following are for automatic ordering and installation of SSL certificates }
    FCertSupplierProto: TSupplierProto;
    FCertDirWork: String;
    FCertChallenge: TChallengeType;
    FCertPKeyType: TSslPrivKeyType;
    FCertProduct: String;
    FCertSignDigest: TEvpDigest;
    FWebLogIdx: Integer;    { V8.60 }
    FAuthSslCmd: Boolean;   { V8.63 }
    FBindSrvPort: string;   { V8.64 }
    FAuthForceSsl: Boolean; { V8.64 }
  protected
    function GetDisplayName: string; override;
    function GetHostNameTot: integer;
    procedure SetHostNames(Value : TStrings);
  public
    SslCtx: TSslContext;
//    SavedX509: TX509Base;  { V8.62 used during tls-alpn-01 cert swapping }
    property HostNameTot : Integer               read  GetHostNameTot;
    property DisplayName : String                read  GetDisplayName;
    property CertDomains : String                read  FCertDomains;
    property CertInfo : String                   read  FCertInfo;
    property BindInfo : String                   read  FBindInfo;
    property CertExiry : TDateTime               read  FCertExiry;
    property CertFStamp: TDateTime               read  FCertFStamp;
    property InterFStamp: TDateTime              read  FInterFStamp;
    property CertErrs : String                   read  FCertErrs;
    property CertValRes : TChainResult           read  FCertValRes;
    property BindIdxNone : Integer               read  FBindIdxNone;
    property BindIdxSsl : Integer                read  FBindIdxSsl;
    property BindIdx2None : Integer              read  FBindIdx2None;
    property BindIdx2Ssl : Integer               read  FBindIdx2Ssl;
  published
    constructor Create (Collection: TCollection); Override ;
    destructor Destroy; override;
    property HostNames : TStrings                read  FHostNames
                                                 write SetHostNames;
    property HostEnabled : boolean               read  FHostEnabled
                                                 write FHostEnabled;
    property BindIpAddr : String                 read  FBindIpAddr
                                                 write FBindIpAddr;
    property BindIpAddr2 : String                read  FBindIpAddr2
                                                 write FBindIpAddr2;
    property BindSslPort : Integer               read  FBindSslPort
                                                 write FBindSslPort;
    property BindNonPort : Integer               read  FBindNonPort
                                                 write FBindNonPort;
    property HostTag: String                     read  FHostTag
                                                 write FHostTag;
    property Descr: String                       read  FDescr
                                                 write FDescr;
    property Proto: String                       read  FProto
                                                 write FProto;
    property ForwardProxy : Boolean              read  FForwardProxy
                                                 write FForwardProxy;
    property WebDocDir : String                  read  FWebDocDir
                                                 write FWebDocDir;
    property WebTemplDir : String                read  FWebTemplDir
                                                 write FWebTemplDir;
    property WebDefDoc : String                  read  FWebDefDoc
                                                 write FWebDefDoc;
    property WebLogDir : String                  read  FWebLogDir
                                                 write FWebLogDir;
    property WebLogIdx : Integer                 read  FWebLogIdx
                                                 write FWebLogIdx; { V8.60 }
    property SslCert : String                    read  FSslCert
                                                 write FSslCert;
    property SslKey : String                     read  FSslKey
                                                 write FSslKey;
    property SslInter : String                   read  FSslInter
                                                 write FSslInter;
    property SslPassword : String                read  FSslPassword
                                                 write FSslPassword;
    property SslSrvSecurity : TSslSrvSecurity    read  FSslSrvSecurity
                                                 write FSslSrvSecurity;
    property AuthSslCmd : Boolean                read  FAuthSslCmd
                                                 write FAuthSslCmd;      { V8.63 }
    property AuthForceSsl: Boolean               read  FAuthForceSsl
                                                 write FAuthForceSsl;    { V8.64 }
    property WellKnownPath: string               read  FWellKnownPath
                                                 write FWellKnownPath;   { V8.49 }
    property WebRedirectURL: string              read  FWebRedirectURL
                                                 write FWebRedirectURL;  { V8.49 }
    property WebRedirectStat: integer            read  FWebRedirectStat
                                                 write FWebRedirectStat; { V8.49 }
  { V8.57 following are for automatic ordering and installation of SSL certificates }
    property CertSupplierProto: TSupplierProto   read  FCertSupplierProto
                                                 write FCertSupplierProto;
    property CertDirWork: String                 read  FCertDirWork
                                                 write FCertDirWork;
    property CertChallenge: TChallengeType       read  FCertChallenge
                                                 write FCertChallenge;
    property CertPKeyType: TSslPrivKeyType       read  FCertPKeyType
                                                 write FCertPKeyType;
    property CertProduct: String                 read  FCertProduct
                                                 write FCertProduct;
    property CertSignDigest: TEvpDigest          read  FCertSignDigest
                                                 write FCertSignDigest;
  end;

  { TIcsHosts defines a collection of TIcsHost }

  TIcsHostCollection = class(TCollection)     { V8.45 }
  private
    FOwner: TPersistent;
    function GetItem(Index: Integer): TIcsHost;
    procedure SetItem(Index: Integer; Value: TIcsHost);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(Owner: TPersistent);
    property Items[Index: Integer]: TIcsHost read GetItem write SetItem; default;
  end;

type
    TSslWSocketMultiListenItem = class(TWSocketMultiListenItem)
    public
      constructor Create(Collection: TCollection); override;
    end;

    TSslWSocketClient = class(TWSocketClient)
    public
        AlpnSslCtx: TSslContext;                          { V8.64 used during tls-alpn-01 cert swapping }
        OnClientAlpnChallg: TClientAlpnChallgEvent;       { V8.62 }
        constructor Create(AOwner : TComponent); override;
        destructor  Destroy; override;                    { V8.62 }
        procedure   StartConnection; override;
        procedure   TriggerSslServerName(var Ctx: TSslContext; var ErrCode: TTlsExtError); override; { V8.45 }
        procedure   TriggerSslAlpnSelect(ProtoList: TStrings;
                             var SelProto: String; var ErrCode: TTlsExtError); override; { V8.56 }
    end;

    TSslWSocketServer = class(TWSocketServer)
    protected
        FIcsHosts: TIcsHostCollection;            { V8.45 }
        FX509CAList: TX509List;                   { V8.64 replaced FRootCAX509: TX509Base }
        FRootCA: String;                          { V8.46 }
        FDHParams: String;                        { V8.45 }
        FValidated: Boolean;                      { V8.48 }
        FSslCliCertMethod: TSslCliCertMethod;     { V8.57 }
        FSslCertAutoOrder: Boolean;               { V8.57 }
        FCertExpireDays: Integer;                 { V8.57 }
     { should be TSslX509Certs but causes circular reference, so need to cast }
{$IFDEF AUTO_X509_CERTS}  { V8.59 }
        FSslX509Certs: TComponent;             { V8.57 }
{$ENDIF} // AUTO_X509_CERTS
        procedure TriggerClientConnect(Client : TWSocketClient; Error : Word); override;
        function  MultiListenItemClass: TWSocketMultiListenItemClass; override;
    public
        constructor Create(AOwner : TComponent); override;
        destructor Destroy; override;
        procedure Close; override;                                   { V8.63 }
        property  ClientClass;
        property  ClientCount;
        property  Client;
        property  SslMode;
        procedure Listen; override;
        function  GetIcsHosts: TIcsHostCollection;                   { V8.45 }
        procedure SetIcsHosts(const Value: TIcsHostCollection);      { V8.45 }
        function  FindBinding(const MAddr: String; MPort: Integer;
                                 var MIndex: Integer): boolean;      { V8.45 }
        function  ValidateHosts(Stop1stErr: Boolean=True; NoExceptions: Boolean=False;
                                          AllowSelfSign: Boolean=False): String; virtual; { V8.48, V8.63 }
        function  RecheckSslCerts(var CertsInfo: String; Stop1stErr: Boolean=True;
                        NoExceptions: Boolean=False; AllowSelfSign: Boolean=False): Boolean; { V8.48, V8.63 }
        function  LoadOneCert(HostNr: Integer; ForceLoad: Boolean;
                                var LoadNew: Boolean; AllowSelfSign: Boolean=False): Boolean; { V8.57, V8.63 }
        function  OrderCert(HostNr: Integer): Boolean;               { V8.57 }
        procedure OrderClose;                                        { V8.63 }
        procedure LoadRootCAList;                                    { V8.64 }
{$IFDEF AUTO_X509_CERTS}  { V8.59 }
        function  GetSslX509Certs: TComponent;                       { V8.57 }
        procedure SetSslX509Certs(const Value : TComponent);         { V8.57 }
{$ENDIF} // AUTO_X509_CERTS
        property  Validated: Boolean                     read FValidated;    { V8.64 }
        property  RootCAList: TX509List                  read  FX509CAList;  { V8.64 }
    published
        property  SslContext;
        property  Banner;
        property  BannerTooBusy;
        property  MaxClients;
        property  OnClientDisconnect;
        property  OnClientConnect;
        property  SslEnable;
        property  SslAcceptableHosts;
        property  IcsHosts: TIcsHostCollection           read  GetIcsHosts
                                                         write SetIcsHosts;   { V8.45 }
        property  RootCA: String                         read  FRootCA
                                                         write FRootCA;       { V8.46 }
        property  DHParams: String                       read  FDHParams
                                                         write FDHParams;     { V8.45 }
        property  SslCliCertMethod: TSslCliCertMethod    read  FSslCliCertMethod
                                                         write FSslCliCertMethod; { V8.57 }
        property  SslCertAutoOrder: Boolean              read  FSslCertAutoOrder
                                                         write FSslCertAutoOrder; { V8.57 }
        property  CertExpireDays: Integer                read  FCertExpireDays
                                                         write FCertExpireDays; { V8.57 }
{$IFDEF AUTO_X509_CERTS}  { V8.59 }
        property  SslX509Certs: TComponent               read  GetSslX509Certs
                                                         write SetSslX509Certs; { V8.57 }
{$ENDIF} // AUTO_X509_CERTS
        property  OnSslVerifyPeer;
        property  OnSslSetSessionIDContext;
        property  OnSslSvrNewSession;
        property  OnSslSvrGetSession;
        property  OnSslHandshakeDone;
        property  OnSslServerName;    { V8.07 }
        property  OnSslAlpnSelect;    { V8.56 }
  end;

{ public functions }
function IcsLoadIcsHostsFromIni(MyIniFile: TCustomIniFile; IcsHosts:
                TIcsHostCollection; const Prefix: String = 'IcsHost'): Integer;
function BuildCertName(const Domain: String): String;  { V8.62 }

{$ENDIF} // USE_SSL

implementation

{$IFDEF USE_SSL}
{$IFDEF AUTO_X509_CERTS}  { V8.59 }
{$IFDEF FMX}
Uses
    Ics.Fmx.OverbyteIcsSslX509Certs;  { V8.57 }
{$ELSE}
Uses
    OverbyteIcsSslX509Certs; { V8.57 }
{$ENDIF} // FMX
{$ENDIF} // AUTO_X509_CERTS
{$ENDIF} // USE_SSL

const
    DefaultBanner            = 'Welcome to OverByte ICS TcpSrv';
    DefaultBannerTooBusy     = 'Sorry, too many clients';

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomWSocketServer.DefineProperties(Filer: TFiler);
begin
    inherited DefineProperties(Filer);
    Filer.DefineProperty('Banner', ReadBannerValue, WriteBannerValue, (Banner = ''));
    Filer.DefineProperty('BannerTooBusy', ReadBannerTooBusyValue,
      WriteBannerTooBusyValue, (BannerTooBusy = ''));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TCustomWSocketServer.IsBannerStored: Boolean;
begin
    Result := Banner <> DefaultBanner;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TCustomWSocketServer.IsBannerTooBusyStored: Boolean;
begin
  Result := BannerTooBusy <> DefaultBannerTooBusy;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomWSocketServer.WriteBannerValue(Writer: TWriter);
begin
    Writer.WriteString(Banner);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomWSocketServer.WriteBannerTooBusyValue(Writer: TWriter);
begin
    Writer.WriteString(BannerTooBusy);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomWSocketServer.ReadBannerValue(Reader: TReader);
begin
    Banner := Reader.ReadString;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomWSocketServer.ReadBannerTooBusyValue(Reader: TReader);
begin
    BannerTooBusy := Reader.ReadString;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TCustomWSocketServer.Create(AOwner: TComponent);
begin
    inherited Create(AOwner);
    FClientList      := TList.Create;
    FClientClass     := TWSocketClient;
    FBanner          := DefaultBanner;
    FBannerTooBusy   := DefaultBannerTooBusy;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
destructor TCustomWSocketServer.Destroy;
var
    I : Integer;
begin
    if Assigned(FClientList) then begin
        { We need to destroy all clients }
        for I := FClientList.Count - 1 downto 0 do begin
            try
                TWSocketClient(FClientList.Items[I]).Free;
            except
                { Ignore any exception here }
            end;
        end;
        { Then we can destroy client list }
        FClientList.Free;
        FClientList := nil;
    end;
    { And finally destroy ourself }
    inherited Destroy;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TCustomWSocketServer.MsgHandlersCount : Integer;
begin
    Result := 1 + inherited MsgHandlersCount;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomWSocketServer.AllocateMsgHandlers;
begin
    inherited AllocateMsgHandlers;
    FMsg_WM_CLIENT_CLOSED := FWndHandler.AllocateMsgHandler(Self);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomWSocketServer.FreeMsgHandlers;
begin
    if Assigned(FWndHandler) then
        FWndHandler.UnregisterMessage(FMsg_WM_CLIENT_CLOSED);
    inherited FreeMsgHandlers;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ Message handler                                                           }
procedure TCustomWSocketServer.WndProc(var MsgRec: TMessage);
begin
    with MsgRec do begin
        if Msg = FMsg_WM_CLIENT_CLOSED then begin
            { We *MUST* handle all exception to avoid application shutdown }
            try
                WMClientClosed(MsgRec)
            except
                on E:Exception do
                    HandleBackGroundException(E, 'TCustomWSocketServer.WndProc');
            end;
        end
        else
            inherited WndProc(MsgRec);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ Called by destructor when child component (a clients) is create or        }
{ destroyed.                                                                }
procedure TCustomWSocketServer.Notification(
    AComponent : TComponent;
    Operation  : TOperation);
begin
    inherited Notification(AComponent, Operation);
    if Assigned(FClientList) and (AComponent is TWSocketClient) then begin
        if Operation = opInsert then
            { A new client has been created, add it to our list }
            FClientList.Add(AComponent)
        else if Operation = opRemove then
            { If one of our client has been destroyed, remove it from our list }
            FClientList.Remove(AComponent);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ Called when a session is available, that is when a client is connecting   }
procedure TCustomWSocketServer.TriggerSessionAvailable(Error : Word);
var
    Client     : TWSocketClient;
    TempHandle : TSocket;
begin
{$IFDEF DEBUG_OUTPUT}
    OutputDebugString('OnSessionAvailable');
{$ENDIF}
    { Call parent event handler }
    inherited TriggerSessionAvailable(Error);
    { In case of error, do nothing }
    if Error <> 0 then
        Exit;

    if Cardinal(FClientNum) >= Cardinal(MaxInt) then    { V7.04 }
        FClientNum := 0;                                { angus V7.00 }
    Inc(FClientNum);
    Client := nil;
    try                                                 { FPiette V7.01 }
        Client                 := FClientClass.Create(Self);
        Client.FCliId          := FClientNum;           { angus V7.00 }
        Client.OnBgException   := FOnBgException;       { angus V8.07 }
        Client.SocketErrs      := FSocketErrs;          { V8.37 }
{$IFDEF BUILTIN_THROTTLE}
        Client.BandwidthLimit    := Self.BandwidthLimit;     { angus V7.02 may be changed in event for different limit }
        Client.BandwidthSampling := Self.BandwidthSampling;  { angus V7.02 }
{$ENDIF}
        TriggerClientCreate(Client);
    except                                               { FPiette V7.01 }
        try                                              { FPiette V7.01 }
            TempHandle := Accept;                        { FPiette V7.01 }
            if TempHandle <> INVALID_SOCKET then         { FPiette V7.01 }
                WSocket_closesocket(TempHandle);         { FPiette V7.01 }
            if Assigned(Client) then                     { FPiette V7.01 }
                Client.Free;                             { FPiette V7.01 }
        except                                           { FPiette V7.01 }
            // safely ignore any exception here. Component user may already
            // have accepted and closed the connection.
        end;                                             { FPiette V7.01 }
        raise;                                           { FPiette V7.01 }
    end;                                                 { FPiette V7.01 }
    Client.Name            := Name + 'Client' + IntToStr(FClientNum);
    Client.Banner          := FBanner;
    Client.Server          := Self;
{$IFNDEF NO_DEBUG_LOG}
    Client.IcsLogger       := IcsLogger;                           { V5.04 }
{$ENDIF}
{$IFDEF MSWINDOWS}
    Client.HSocket         := Accept;
{$ENDIF}
{$IFDEF POSIX}
    TempHandle := Accept;
    { Accept() doesn't raise a socket error for WSAEWOULDBLOCK in POSIX. }
    { IMO Accept() should never raise a socket error here but we should  }
    { call Dup() only if Accept() returned a valid socket handle,        }
    { otherwise pass the error code to TriggerClientConnect() and free   }
    { the client object afterwards, so this is just a workaround.  AG    }
    if (TempHandle = INVALID_SOCKET) and (LastError = WSAEWOULDBLOCK) then
        Error := LastError
    else
        Client.HSocket := TempHandle;
{$ENDIF}
    TriggerClientConnect(Client, Error);
    { The event handler may have destroyed the client ! }
    if FClientList.IndexOf(Client) < 0 then
        Exit;
{$IFDEF POSIX}
    if Error <> 0 then begin
        Client.Free;
        Exit;
    end;
{$ENDIF}
    { The event handler may have closed the connection }
    if Client.State <> wsConnected then
        Exit;
    { Ok, the client is still there, process with the connection }
    if (FMaxClients > 0) and (FMaxClients < ClientCount) then begin
        { Sorry, toomuch clients }
        Client.Banner := FBannerTooBusy;
        Client.StartConnection;
        Client.CloseDelayed;  { V8.06 was Close but too quick }
    end
    else
        Client.StartConnection;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomWSocketServer.TriggerClientConnect(
    Client : TWSocketClient; Error : Word);
begin
    if Assigned(FOnClientConnect) then
        FOnClientConnect(Self, Client, Error);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomWSocketServer.TriggerClientCreate(Client : TWSocketClient);
begin
    if Assigned(FOnClientCreate) then
        FOnClientCreate(Self, Client);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomWSocketServer.TriggerClientDisconnect(
    Client : TWSocketClient; Error : Word);
begin
    if Assigned(FOnClientDisconnect) then
        FOnClientDisconnect(Self, Client, Error);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ get number of connect clients                                               }
function TCustomWSocketServer.GetClientCount : Integer;
begin
    if Assigned(FClientList) then
        Result := FClientList.Count
    else
        Result := 0;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ Acces method to return a client by index.                                   }
{ Return nil if index is out of range.                                        }
function TCustomWSocketServer.GetClient(nIndex : Integer) : TWSocketClient;
begin
    if not Assigned(FClientList) then begin
        Result := nil;
        Exit;
    end;
    if (nIndex < 0) or (nIndex >= FClientList.Count) then begin
        Result := nil;
        Exit;
    end;
    Result := TWSocketClient(FClientList.Items[nIndex]);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomWSocketServer.Listen;     { V8.64 }
begin
    inherited Listen;
    FBindPort := GetXPort;  { V8.64 keep actual port listening, might be random }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ Client has closed. Remove it from client list and destroy component.        }
procedure TCustomWSocketServer.WMClientClosed(var msg: TMessage);
var
    Client : TWSocketClient;
    PIdRec : PClientIdRec;
begin
    PIdRec := PClientIdRec(Msg.LParam);  { angus V7.00 }
    try
        Client := TWSocketClient(PIdRec^.PClient);
        { angus V7.00 ensure client not freed already }
        if IsClient(Client) and (Client.CliId = PIdRec^.CliId) then begin
            try
                TriggerClientDisconnect(Client, Msg.WParam);
            finally
                { Calling Free will automatically remove client from list     }
                { because we installed a notification handler.                }
                Client.CliId := 0;  { V8.03 }
                Client.Free;
            end;
        end;
    finally
        System.Dispose(PIdRec);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ Check if a given object is one of our clients.                              }
function TCustomWSocketServer.IsClient(SomeThing : TObject) : Boolean;
begin
    if not Assigned(FClientList) then
        Result := FALSE
    else
        Result := (FClientList.IndexOf(SomeThing) >= 0);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomWSocketServer.Disconnect(Client: TWSocketClient);        { angus V6.01 }
var
    Msg : TMessage;
    PIdRec : PClientIdRec;
begin
    FillChar(Msg, SizeOf(Msg), 0);
{ angus V7.00 pass CliId to WMClientClosed so correct client is closed  }
    New(PIdRec);
    PIdRec^.PClient := Client;
    PIdRec^.CliId   := Client.CliId;
    Msg.WParam      := WSAECONNABORTED;
    Msg.LParam      := LPARAM(PIdRec);
    WMClientClosed(Msg);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomWSocketServer.DisconnectAll;                             { angus V6.01 }
begin
    while ClientCount > 0 do
        Disconnect(Client[0]);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{*                                                                           *}
{*                   TCustomMultiListenWSocketServer                         *}
{*                                                                           *}
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function SizeOfAddr(const AAddr: TSockAddrIn6): Integer;
    {$IFDEF USE_INLINE} inline; {$ENDIF}
begin
    if AAddr.sin6_family = AF_INET6 then
        Result := SizeOf(TSockAddrIn6)
    else
        Result := SizeOf(TSockAddrIn);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TCustomMultiListenWSocketServer.Accept: TSocket;
var
    Len     : Integer;
    AItem   : TWSocketMultiListenItem;
  {$IFDEF POSIX}
    LastErr : Integer;
  {$ENDIF}
begin
    if FMultiListenIndex = -1 then
    begin
        Result := inherited Accept;
    end
    else begin
      {$IFDEF POSIX}
        AItem := nil;
        try
      {$ENDIF}
            AItem := FMultiListenSockets[FMultiListenIndex];
            if AItem.State <> wsListening then begin
                WSocket_WSASetLastError(WSAEINVAL);
                MlSocketError(AItem, 'not a listening socket');
                Result := INVALID_SOCKET;
                Exit;
            end;
            Len := SizeOf(AItem.Fsin);
            FASocket := WSocket_Accept(AItem.HSocket, @AItem.Fsin, @Len);
            Result := FASocket;
            if FASocket = INVALID_SOCKET then begin
              {$IFDEF MSWINDOWS}
                MlSocketError(AItem, 'Accept');
              {$ENDIF}
              {$IFDEF POSIX}
                LastErr := WSocket_WSAGetLastError;
                if LastErr <> WSAEWOULDBLOCK then
                    MlSocketError(AItem, 'Accept', LastErr);
              {$ENDIF}
                Exit;
            end;
      {$IFDEF POSIX}
        finally
            if (AItem <> nil) and (AItem.State = wsListening) then
                WSocketSynchronizedEnableAcceptEvent(AItem);
        end;
      {$ENDIF}
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomMultiListenWSocketServer.Close;
begin
    FMultiListenIndex := -1;
    inherited;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TCustomMultiListenWSocketServer.Create(AOwner: TComponent);
begin
    inherited;
    FMultiListenIndex := -1;
    FMultiListenSockets := TWSocketMultiListenCollection.Create(
                              Self, MultiListenItemClass);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
destructor TCustomMultiListenWSocketServer.Destroy;
begin
  FMultiListenSockets.Free;
  inherited;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomMultiListenWSocketServer.Listen;
begin
    FMultiListenIndex := -1;
    inherited Listen;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomMultiListenWSocketServer.MlClose(
  AItem: TWSocketMultiListenItem);
var
    iStatus : Integer;
begin
    FMultiListenIndex := AItem.Index;
    if AItem.HSocket = INVALID_SOCKET then
    begin
        AItem.AssignDefaults;
        Exit;
    end;

    if AItem.State = wsClosed then
        Exit;

    if AItem.HSocket <> INVALID_SOCKET then begin
        repeat
            { Close the socket }
            iStatus := WSocket_closesocket(AItem.HSocket);
            if iStatus <> 0 then begin
                AItem.LastError := WSocket_WSAGetLastError;
                if AItem.LastError <> WSAEWOULDBLOCK then begin
                  {$IFDEF POSIX}
                    WSocketSynchronizedRemoveEvents(AItem, False);
                    IcsClearMessages(Handle, FMsg_WM_ASYNCSELECT, WPARAM(AItem.HSocket));
                  {$ENDIF}
                    AItem.HSocket := INVALID_SOCKET;
                  {$IFDEF MSWINDOWS}
                    { Ignore the error occuring when winsock DLL not      }
                    { initialized (occurs when using TWSocket from a DLL) }
                    if AItem.LastError = WSANOTINITIALISED then
                        Break;
                  {$ENDIF}
                    MlSocketError(AItem, 'Disconnect (closesocket)');
                    Exit;
                end;
                MessagePump;
            end;
        until iStatus = 0;
      {$IFDEF POSIX}
        WSocketSynchronizedRemoveEvents(AItem, True);
        IcsClearMessages(Handle, FMsg_WM_ASYNCSELECT, WPARAM(AItem.HSocket));
      {$ENDIF}
        AItem.HSocket := INVALID_SOCKET;
    end;
    AItem.State := wsClosed;
    if (not (csDestroying in ComponentState)) and
       (not AItem.CloseInvoked) {and Assigned(FOnSessionClosed)} then begin
        AItem.CloseInvoked := TRUE;
        TriggerSessionClosed(0);
    end;
    { 29/09/98 Protect AssignDefaultValue because SessionClosed event handler }
    { may have destroyed the component.                                       }
    try
        AItem.AssignDefaults;
    except
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomMultiListenWSocketServer.MlSocketError(
    AItem: TWSocketMultiListenItem; const ASockFunc: String;
    ALastError: Integer = 0; FriendlyMsg: String = '');   { V8.36 added FriendlyMsg }
var
    ErrCode  : Integer;
    Line : String;
begin
    FMultiListenIndex := AItem.Index;
    try
        if ALastError = 0 then
            ErrCode := WSocket_WSAGetLastError
        else
            ErrCode := ALastError;
        Line  := 'Listening socket index #' + IntToStr(FMultiListenIndex) + ' ' +
                  WSocketErrorDesc(ErrCode) + ' (#' + IntToStr(ErrCode) +
                  ' in ' + ASockFunc + ')' ;
        if (ErrCode = WSAECONNRESET) or
           (ErrCode = WSAENOTCONN) then begin
            WSocket_closesocket(AItem.HSocket);
            AItem.HSocket := INVALID_SOCKET;
            if AItem.State <> wsClosed then
               TriggerSessionClosed(ErrCode);
            AItem.State := wsClosed;
        end;

        AItem.LastError := ErrCode;
        LastError := ErrCode;
        RaiseException(Line, ErrCode, WSocketErrorDesc(ErrCode), FriendlyMsg,  { V8.49 }
                                   ASockfunc, AItem.Addr, AItem.Port, FProtoStr);  { V8.36 }
    finally
        FMultiListenIndex := -1;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomMultiListenWSocketServer.Ml_Do_FD_CLOSE(
    AItem : TWSocketMultiListenItem;
    AMsg  : TMessage);
begin
    if (AItem.HSocket <> INVALID_SOCKET) then begin
        if not AItem.CloseInvoked then
        begin
            AItem.CloseInvoked := TRUE;
            TriggerSessionClosed(IcsHiWord(AMsg.LParam));
        end;
        if AItem.State <> wsClosed then
            MlClose(AItem);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomMultiListenWSocketServer.MlListen(
    AItem: TWSocketMultiListenItem);
var
    iStatus : Integer;
    ErrorCode : Integer;
    FriendlyMsg : string;
    optval : Integer;
    saddr : TSockAddrIn6;
    saddrlen : Integer;
begin
    FMultiListenIndex := AItem.Index;
    FriendlyMsg := '';
    AItem.FBindPort := '';  { V8.64 }
    try
        if (AItem.State <> wsClosed) then begin
            WSocket_WSASetLastError(WSAEINVAL);
            MlSocketError(AItem, 'listen: socket is already listening');
            Exit;
        end;

        if IcsLowerCase(FProtoStr) <> 'tcp' then begin
            WSocket_WSASetLastError(WSAEINVAL);
            MlSocketError(AItem, 'listen: protocol unsupported');
            Exit;
        end;

        if AItem.Port = '' then begin
            WSocket_WSASetLastError(WSAEINVAL);
            MlSocketError(AItem, 'listen: port not assigned');
            Exit;
        end;

        if AItem.Addr = '' then begin
            //WSocket_Synchronized_WSASetLastError(WSAEINVAL);
            WSocket_WSASetLastError(WSAEINVAL);
            MlSocketError(AItem, 'listen: address not assigned');
            Exit;
        end;

        try
            { The next line will trigger an exception in case of failure }
            AItem.PortNum := WSocketResolvePort(
                                  AnsiString(AItem.Port), AnsiString('tcp'));
            AItem.Fsin.sin6_port := WSocket_htons(AItem.PortNum);

            { The next line will trigger an exception in case of failure }
            if AItem.SocketFamily = sfIPv4 then
            begin
                AItem.Fsin.sin6_family := AF_INET;
                PSockAddrIn(@AItem.Fsin).sin_addr.s_addr :=
                    WSocketResolveHost(AnsiString(AItem.Addr)).s_addr;
            end
            else
                WSocketResolveHost(AItem.Addr, AItem.Fsin, AItem.SocketFamily,
                                   IPPROTO_TCP);
        except
            on E: Exception do begin
                AItem.AssignDefaults;
                raise ESocketException.Create('listen: ' + E.Message);
            end;
        end;

        { Remove any data from the internal output buffer }
        { (should already be empty !)                     }
        DeleteBufferedData;

        AItem.HSocket := WSocket_socket(AItem.Fsin.sin6_family, SOCK_STREAM, IPPROTO_TCP);
        if AItem.HSocket = INVALID_SOCKET then begin
            MlSocketError(AItem, 'listen: socket');
            Exit;
        end;

      {$IFDEF MSWINDOWS}  { V8.49 }
        if FExclusiveAddr then begin
        { V8.36 Prevent other applications accessing this address and port }
            optval  := -1;
            iStatus := WSocket_SetSockOpt(AItem.HSocket, SOL_SOCKET,
                                                       SO_EXCLUSIVEADDRUSE,
                                                       @optval, SizeOf(optval));
            if iStatus <> 0 then begin
                MlSocketError(AItem, 'setsockopt(SO_EXCLUSIVEADDRUSE)');
                MlClose(AItem);
                Exit;
            end;
        end;
      {$ENDIF}

        iStatus := WSocket_bind(AItem.HSocket, PSockAddr(@AItem.Fsin)^,
                                           SizeOfAddr(AItem.Fsin));
        if iStatus = 0 then
            AItem.State := wsBound
        else begin
            ErrorCode := WSocket_WSAGetLastError;
            if (ErrorCode = WSAEADDRINUSE) or (ErrorCode = WSAEACCES)  then   { V8.36 more friendly message for common error }
                FriendlyMsg := 'Another server is already listening on ' +
                                                 AItem.Addr + ':' + AItem.Port;
            MlSocketError(AItem, 'listen: Bind', ErrorCode, FriendlyMsg);
            MlClose(AItem);
            Exit;
        end;

        iStatus := WSocket_listen(AItem.HSocket, AItem.ListenBacklog);
        if iStatus = 0 then begin
            AItem.State := wsListening;
         { V8.64 keep actual port }
            saddrlen := sizeof(saddr);
            if WSocket_getsockname(AItem.HSocket,
                                      PSockAddr(@saddr)^, saddrlen) = 0 then
                AItem.FBindPort := IntToStr(WSocket_ntohs(saddr.sin6_port));
        end
        else begin
            MlSocketError(AItem, 'listen: Listen');
            Exit;
        end;

        AItem.FSelectEvent := FD_ACCEPT or FD_CLOSE;

      {$IFDEF MSWINDOWS}
        if wsoNotifyAddressListChange in ComponentOptions then
            AItem.FSelectEvent := AItem.FSelectEvent or FD_ADDRESS_LIST_CHANGE;
        if wsoNotifyRoutingInterfaceChange in ComponentOptions then
            AItem.FSelectEvent := AItem.FSelectEvent or FD_ROUTING_INTERFACE_CHANGE;
      {$ENDIF}

        iStatus := WSocket_WSAASyncSelect(
                                        {$IFDEF POSIX}
                                          AItem,
                                        {$ENDIF}
                                          AItem.HSocket,
                                          Handle,
                                          FMsg_WM_ASYNCSELECT,
                                          AItem.FSelectEvent);
        if iStatus <> 0 then begin
            MlSocketError(AItem, 'listen: WSAASyncSelect');
            Exit;
        end;

      {$IFDEF MSWINDOWS}
        if (wsoNotifyAddressListChange in ComponentOptions) and
           (not AItem.SetAddressListChangeNotification) then begin
            MlSocketError(AItem, 'listen: SetAddressListChangeNotification');
            Exit;
        end;

        if (wsoNotifyRoutingInterfaceChange in ComponentOptions) and
           (not AItem.SetRoutingInterfaceChangeNotification)then begin
            MlSocketError(AItem, 'listen: SetRoutingInterfaceChangeNotification');
            Exit;
        end;
      {$ENDIF}
    finally
        FMultiListenIndex := -1;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomMultiListenWSocketServer.MlPause(
    AItem: TWSocketMultiListenItem);
begin
    if not AItem.Paused then
        AItem.FPaused := WSocket_WSAASyncSelect(
                                              {$IFDEF POSIX}
                                                AItem,
                                              {$ENDIF}
                                                AItem.HSocket,
                                                Handle, 0, 0) = 0;

end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomMultiListenWSocketServer.MLResume(
    AItem: TWSocketMultiListenItem);
begin
    if AItem.Paused then
        AItem.FPaused := not (WSocket_WSAASyncSelect(
                                                {$IFDEF POSIX}
                                                  AItem,
                                                {$ENDIF}
                                                  AItem.HSocket,
                                                  Handle,
                                                  FMsg_WM_ASYNCSELECT,
                                                  AItem.SelectEvent) = 0);

end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomMultiListenWSocketServer.MlSetAddr(
  var FldAddr: string; var FldSocketFamily: TSocketfamily;
  const FldOldSocketFamily: TSocketfamily;
  const NewValue: string);
var
    LSocketFamily: TSocketFamily;
begin
    FldAddr := IcsTrim(NewValue);
    if FldAddr = '' then
        Exit;
    { If the address is either a valid IPv4 or IPv6 address }
    { change current SocketFamily.                          }
    if WSocketIsIP(FldAddr, LSocketFamily) then
    begin
        if (LSocketFamily = sfIPv4) or (IsIPv6APIAvailable) then
            FldSocketFamily := LSocketFamily
        else
            FldSocketFamily := FldOldSocketFamily;
    end
    else
        FldSocketFamily := FldOldSocketFamily;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomMultiListenWSocketServer.MlSetSocketFamily(
  var FldSocketFamily: TSocketfamily;
  var FldOldSocketFamily: TSocketfamily;
  const NewValue: TSocketFamily);
begin
    if NewValue <> FldSocketFamily then begin
        if NewValue <> sfIPv4 then begin
            try
                if not IsIPv6APIAvailable then
                    raise ESocketException.Create(
                     'SetSocketFamily: New API requires winsock 2.2 ' +
                     'and Windows XP, property "SocketFamily" reset to "sfIPv4"');
            except
                FldSocketFamily := sfIPv4;
                FldOldSocketFamily := FldSocketFamily;
                Exit;
            end;
        end;
        FldSocketFamily := NewValue;
        FldOldSocketFamily :=FldSocketFamily;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomMultiListenWSocketServer.MultiClose;
var
    I: Integer;
begin
    if State <> wsClosed then
        Close;
    if Assigned(FMultiListenSockets) then begin
        for I := 0 to FMultiListenSockets.Count - 1 do
            if FMultiListenSockets[I].State <> wsClosed then
                MlClose(FMultiListenSockets[I]);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ beware this function does not give errors if some listeners fail due to port conflicts }
procedure TCustomMultiListenWSocketServer.MultiListen;
var
    I: Integer;
begin
    if State <> wsListening then
        Listen;
    if Assigned(FMultiListenSockets) then begin
        for I := 0 to FMultiListenSockets.Count - 1 do begin
            if FMultiListenSockets[I].State <> wsListening then
            MlListen(FMultiListenSockets[I]);
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ this function ignores errors if some listeners fail due to port conflicts }
function TCustomMultiListenWSocketServer.MultiListenEx: string;    { V8.49 }
var
    I: Integer;
begin
    Result := '';
    if State <> wsListening then
    try
        Listen;
    except
        on E:Exception do
            Result := 'Socket 1 Listen Failed: ' + Self.Addr +
                          ' port ' + Self.Port + ' - ' + E.Message;
    end;
    if Assigned(FMultiListenSockets) then begin
        for I := 0 to FMultiListenSockets.Count - 1 do begin
            if FMultiListenSockets[I].State <> wsListening then
            try
                MlListen(FMultiListenSockets[I]);
            except
                on E:Exception do begin
                    if Result <> '' then Result := Result + #13#10;
                    Result := Result + 'Socket ' + IntToStr (I + 1) +
                        ' Listen Failed: ' + Self.Addr +
                              ' port ' + Self.Port + ' - ' + E.Message;
                end;
            end;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TCustomMultiListenWSocketServer.MultiListenItemClass: TWSocketMultiListenItemClass;
begin
    Result := TWSocketMultiListenItem;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomMultiListenWSocketServer.SetMultiListenIndex(
  const Value: Integer);
begin
    FMultiListenIndex := Value;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomMultiListenWSocketServer.ThreadAttach;
var
    I : Integer;
    LItem : TWSocketMultiListenItem;
begin
    FMultiListenIndex := -1;
    inherited ThreadAttach;
    for I := 0 to FMultiListenSockets.Count -1 do begin
        LItem := FMultiListenSockets[I];
        if (LItem.HSocket <> INVALID_SOCKET) then
            WSocket_WSAASyncSelect(
                                  {$IFDEF POSIX}
                                    LItem,
                                  {$ENDIF}
                                    LItem.HSocket,
                                    Handle, FMsg_WM_ASYNCSELECT,
                                    LItem.SelectEvent);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomMultiListenWSocketServer.ThreadDetach;
var
    I : Integer;
    LItem : TWSocketMultiListenItem;
begin
    FMultiListenIndex := -1;
    if ThreadID = IcsGetCurrentThreadID then begin // not thread-safe
        for I := 0 to FMultiListenSockets.Count -1 do begin
            LItem := FMultiListenSockets[I];
            if (LItem.HSocket <> INVALID_SOCKET) then
                WSocket_WSAASyncSelect(
                                      {$IFDEF POSIX}
                                        LItem,
                                      {$ENDIF}
                                        LItem.HSocket,
                                        Handle, 0, 0);
        end;
    end;
    inherited ThreadDetach;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomMultiListenWSocketServer.TriggerClientConnect(
    Client : TWSocketClient; Error : Word);
begin
    inherited TriggerClientConnect(Client, Error);
    { Finally reset the MultiListenIndex just to avoid bad component use }
    //FMultiListenIndex := -1;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCustomMultiListenWSocketServer.WMASyncSelect(var msg: TMessage);
var
    Check   : Word;
    ParamLo : Word;
    AItem   : TWSocketMultiListenItem;
begin
    if msg.wParam = WPARAM(FHSocket) then begin
        FMultiListenIndex := -1;

        if FPaused then
          Exit;

        ParamLo := LoWord(msg.lParam);
        Check := ParamLo and FD_ACCEPT;
        if Check <> 0 then begin
            FSelectMessage := FD_ACCEPT;
            Do_FD_ACCEPT(msg);
        end;

        Check := ParamLo and FD_CLOSE;
        if Check <> 0 then begin
            FSelectMessage := FD_CLOSE;
            Do_FD_CLOSE(msg);
        end;

      {$IFDEF MSWINDOWS}
        if ParamLo and FD_ROUTING_INTERFACE_CHANGE <> 0 then begin
            FSelectMessage := FD_ROUTING_INTERFACE_CHANGE;
            Do_FD_ROUTING_INTERFACE_CHANGE(msg);
        end;

        if ParamLo and FD_ADDRESS_LIST_CHANGE <> 0 then begin
            FSelectMessage := FD_ADDRESS_LIST_CHANGE;
            Do_FD_ADDRESS_LIST_CHANGE(msg);
        end;
      {$ENDIF}

        FSelectMessage := 0;

    end
    else begin
        FMultiListenIndex := FMultiListenSockets.FindItemIndex(msg.wParam);
        if FMultiListenIndex = -1 then
            Exit;
        AItem := FMultiListenSockets[FMultiListenIndex];

        if AItem.Paused then
          Exit;

        ParamLo := LoWord(msg.lParam);

        Check := ParamLo and FD_ACCEPT;
        if Check <> 0 then
            Do_FD_ACCEPT(msg);

        Check := ParamLo and FD_CLOSE;
        if Check <> 0 then
            Ml_Do_FD_CLOSE(AItem, msg);

      {$IFDEF MSWINDOWS}
        if ParamLo and FD_ROUTING_INTERFACE_CHANGE <> 0 then begin
            FSelectMessage := FD_ROUTING_INTERFACE_CHANGE;
            Do_FD_ROUTING_INTERFACE_CHANGE(msg);
        end;

        if ParamLo and FD_ADDRESS_LIST_CHANGE <> 0 then begin
            FSelectMessage := FD_ADDRESS_LIST_CHANGE;
            Do_FD_ADDRESS_LIST_CHANGE(msg);
        end;
      {$ENDIF}
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ returns state, ip address and port for all sockets }
function TCustomMultiListenWSocketServer.ListenStates: String;
var
    K: integer ;
    RealPort: String;   { V8.64 }
{$IFDEF USE_SSL}
    ListenItem: TSslWSocketMultiListenItem;    { V8.59 }
{$ELSE}
    ListenItem: TWSocketMultiListenItem;
{$ENDIF}
begin
    RealPort := Self.Port;
    if Self.FState = wsListening then RealPort := Self.BindPort;  { V8.64 for dynamic ports }
    Result := 'Socket 1 State: ' + SocketStateNames[Self.FState] + ' ' +
                  SocketFamilyNames [Self.SocketFamily] + ' on ' +
                                        Self.Addr + ' port ' + RealPort;
{$IFDEF USE_SSL}
    if SslEnable then
        Result := Result + ' SSL' + #13#10
    else
{$ENDIF}
        Result := Result + #13#10;
    if MultiListenSockets.Count > 0 then begin
        for K := 0 to MultiListenSockets.Count - 1 do begin
            ListenItem := MultiListenSockets [K] as
{$IFDEF USE_SSL}
                TSslWSocketMultiListenItem;
{$ELSE}
                TWSocketMultiListenItem;
{$ENDIF}
            RealPort := ListenItem.FPort;
            if ListenItem.FState = wsListening then RealPort := ListenItem.BindPort;  { V8.64 for dynamic ports }
            Result := Result + 'Socket ' + IntToStr (K + 2) +
                 ' State: ' + SocketStateNames[ListenItem.FState] + ' ' +
                     SocketFamilyNames [ListenItem.SocketFamily] +
                       ' on ' + ListenItem.FAddr + ' port ' + RealPort;
{$IFDEF USE_SSL}
            if ListenItem.SslEnable then
               Result := Result + ' SSL' + #13#10
            else
{$ENDIF}
                Result := Result + #13#10;
        end;
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ return true is all sockets are listening OK }
function TCustomMultiListenWSocketServer.ListenAllOK: Boolean ;
var
    K: integer ;
begin
    Result := False;
    if FState <> wsListening then Exit;
    if MultiListenSockets.Count > 0 then begin
        for K := 0 to MultiListenSockets.Count - 1 do begin
            if MultiListenSockets [K].FState <> wsListening then Exit;
        end;
    end;
    Result := True;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ TWSocketMultiListenItem }
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

{$IFDEF POSIX}
{ Impl. IIcsEventSource }
function TWSocketMultiListenItem.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TWSocketMultiListenItem._AddRef: Integer;
begin
  Result := -1;  // no ref count
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TWSocketMultiListenItem._Release: Integer;
begin
  Result := -1; // no ref count
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TWSocketMultiListenItem.GetEventMask: LongWord;
begin
    Result := FPxEventMask;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TWSocketMultiListenItem.SetEventMask(const AValue: LongWord);
begin
    FPxEventMask := AValue;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TWSocketMultiListenItem.GetNotifyMessageID: UINT;
begin
    Result := FPxEventMessageID;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TWSocketMultiListenItem.SetNotifyMessageID(const AValue: UINT);
begin
    FPxEventMessageID := AValue;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TWSocketMultiListenItem.GetNotifyWindow: HWND;
begin
    Result := FPxEventWindow;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TWSocketMultiListenItem.SetNotifyWindow(const AValue: HWND);
begin
    FPxEventWindow := AValue;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TWSocketMultiListenItem.GetEventState: TIcsAsyncEventState;
begin
    Result := FPxEventState;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TWSocketMultiListenItem.SetEventState(const AValue: TIcsAsyncEventState);
begin
    FPxEventState := AValue;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TWSocketMultiListenItem.GetFileDescriptor: Integer;
begin
    Result := FPxFileDescriptor;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TWSocketMultiListenItem.SetFileDescriptor(const AValue: Integer);
begin
    FPxFileDescriptor := AValue;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TWSocketMultiListenItem.GetObject: TObject;
begin
    Result := Self;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TWSocketMultiListenItem.GetObjectID: NativeInt;
begin
    Result := FPxObjectID;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{$ENDIF POSIX IIcsEventSource}


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

procedure TWSocketMultiListenItem.AssignDefaults;
begin
    FHSocket            := INVALID_SOCKET;
    FPortNum            := 0;
    FState              := wsClosed;
    FPaused             := FALSE;
    FCloseInvoked       := FALSE;
    FillChar(Fsin, SizeOf(Fsin), 0);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TWSocketMultiListenItem.Close;
begin
    OwnerServer.MlClose(Self);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TWSocketMultiListenItem.Create(Collection: TCollection);
begin
    inherited Create(Collection);
    FListenBackLog := 15; { V8.57 was 5 }
    FSocketFamily := DefaultSocketFamily;
    FOldSocketFamily := FSocketFamily;
    AssignDefaults;
{$IFDEF POSIX}
    FPxObjectID := WSocketGenerateObjectID;
{$ENDIF}
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
destructor TWSocketMultiListenItem.Destroy;
begin
    if (FState <> wsInvalidState) and (FState <> wsClosed) then
        OwnerServer.MlClose(Self);
    inherited;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TWSocketMultiListenItem.GetAddrResolved: string;
begin
    if Fsin.sin6_family = AF_INET6 then
        Result := WSocketIPv6ToStr(@Fsin)
    else
        Result := WSocketIPv4ToStr(PInteger(@PSockAddr(@Fsin)^.sin_addr)^);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TWSocketMultiListenItem.GetCloseInvoked: Boolean;
begin
    Result := FCloseInvoked;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TWSocketMultiListenItem.Listen;
begin
    OwnerServer.MlListen(Self);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TWSocketMultiListenItem.OwnerServer: TCustomMultiListenWSocketServer;
begin
    Result := TWSocketMultiListenCollection(Collection).Owner;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TWSocketMultiListenItem.Pause: Boolean;
begin
    OwnerServer.MlPause(Self);
    Result := FPaused;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TWSocketMultiListenItem.Resume: Boolean;
begin
    OwnerServer.MlResume(Self);
    Result := not FPaused;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TWSocketMultiListenItem.SetAddr(const Value: string);
begin
    OwnerServer.MlSetAddr(FAddr, FSocketFamily, FOldSocketFamily, Value);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TWSocketMultiListenItem.SetCloseInvoked(const AValue: Boolean);
begin
    FCloseInvoked := AValue;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TWSocketMultiListenItem.SetSocketFamily(const Value: TSocketFamily);
begin
    OwnerServer.MlSetSocketFamily(FSocketFamily, FOldSocketFamily, Value);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TWSocketMultiListenItem.SetAddressListChangeNotification: Boolean;
{$IFDEF MSWINDOWS}
var
    LBytesRcvd : LongWord;
begin
    if FHSocket <> INVALID_SOCKET then begin
        if FSelectEvent and FD_ADDRESS_LIST_CHANGE = 0 then begin
            FSelectEvent := FSelectEvent or FD_ADDRESS_LIST_CHANGE;
            Result := WSocket_WSAASyncSelect(FHSocket,
                                             OwnerServer.Handle,
                                             OwnerServer.FMsg_WM_ASYNCSELECT,
                                             FSelectEvent) <> SOCKET_ERROR;
        end
        else
            Result := True;
        if Result then
            Result := (WSocket_WSAIoctl(FHSocket, SIO_ADDRESS_LIST_CHANGE, nil, 0,
                                        nil, 0, LBytesRcvd, nil, nil) <> SOCKET_ERROR) or
                      (WSocket_WSAGetLastError = WSAEWOULDBLOCK);
    end
    else
        Result := False;
{$ENDIF}
{$IFDEF POSIX}
begin
    Result := False;
{$ENDIF}
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TWSocketMultiListenItem.SetRoutingInterfaceChangeNotification: Boolean;
{$IFDEF MSWINDOWS}
var
    LBytesRcvd : LongWord;
begin
    if FHSocket <> INVALID_SOCKET then begin
        if FSelectEvent and FD_ROUTING_INTERFACE_CHANGE = 0 then begin
            FSelectEvent := FSelectEvent or FD_ROUTING_INTERFACE_CHANGE;
            Result := WSocket_WSAASyncSelect(FHSocket,
                                             OwnerServer.Handle,
                                             OwnerServer.FMsg_WM_ASYNCSELECT,
                                             FSelectEvent) <> SOCKET_ERROR;
        end
        else
            Result := True;
        if Result then
            Result := (WSocket_WSAIoctl(FHSocket, SIO_ROUTING_INTERFACE_CHANGE,
                                        @Fsin, SizeOfAddr(Fsin), nil, 0, LBytesRcvd,
                                        nil, nil) <> SOCKET_ERROR) or
                      (WSocket_WSAGetLastError = WSAEWOULDBLOCK);
    end
    else
        Result := False;
{$ENDIF}
{$IFDEF POSIX}
begin
    Result := False;
{$ENDIF}
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ TWSocketMultiListenCollection }
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

function TWSocketMultiListenCollection.Add: TWSocketMultiListenItem;
begin
    Result := TWSocketMultiListenItem(inherited Add);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TWSocketMultiListenCollection.Create(AOwner: TPersistent;
    AItemClass: TWSocketMultiListenItemClass);
begin
    inherited Create(AOwner, AItemClass);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TWSocketMultiListenCollection.FindItemHandle(
    const AHSocket: TSocket): TWSocketMultiListenItem;
var
    I: Integer;
begin
    for I := 0 to Count -1 do
    begin
      Result := Items[I];
      if Result.FHSocket = AHSocket then
          Exit;
    end;
    Result := nil;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TWSocketMultiListenCollection.FindItemIndex(
    const AHSocket: TSocket): Integer;
begin
    for Result := 0 to Count -1 do
    begin
      if Items[Result].FHSocket = AHSocket then
          Exit;
    end;
    Result := -1;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TWSocketMultiListenCollection.FindItemID(ID: Integer): TWSocketMultiListenItem;
begin
    Result := TWSocketMultiListenItem(inherited FindItemID(ID));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TWSocketMultiListenCollection.GetItem(Index: Integer): TWSocketMultiListenItem;
begin
    Result := TWSocketMultiListenItem(inherited GetItem(Index));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TWSocketMultiListenCollection.Insert(
  Index: Integer): TWSocketMultiListenItem;
begin
    Result := TWSocketMultiListenItem(inherited Insert(Index));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TWSocketMultiListenCollection.Owner: TCustomMultiListenWSocketServer;
begin
    Result := TCustomMultiListenWSocketServer(GetOwner);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TWSocketMultiListenCollection.SetItem(Index: Integer;
  Value: TWSocketMultiListenItem);
begin
    inherited SetItem(Index, Value);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{*                                                                           *}
{*                            TWSocketClient                                 *}
{*                                                                           *}
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TWSocketClient.StartConnection;
begin
    if Length(FBanner) > 0 then
        SendStr(FBanner + FLineEnd);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ Triggered when socket is closed. Need to inform server socket to update   }
{ client list and trigger client disconnect event.                          }
procedure TWSocketClient.TriggerSessionClosed(ErrCode : Word);
var
    PIdRec : PClientIdRec;
begin
    if not FSessionClosedFlag then begin
        FSessionClosedFlag := TRUE;
        if Assigned(FServer) then begin
            New(PIdRec);
            PIdRec^.PClient := Self;
            PIdRec^.CliId   := FCliId;
            if NOT PostMessage(Server.Handle, Server.FMsg_WM_CLIENT_CLOSED,
                               WPARAM(ErrCode), LPARAM(PIdRec))
            then
                System.Dispose(PIdRec);
        end;
        inherited TriggerSessionClosed(ErrCode);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ This override base class GetPeerAddr. It return cached value.             }
function TWSocketClient.GetPeerAddr: String;
begin
    Result := FPeerAddr;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ This override base class GetPeerPort. It return cached value.             }
function TWSocketClient.GetPeerPort: String;
begin
    Result := FPeerPort;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ Override base class. Dup is called when a client is assigned to a         }
{ TWSocket. Assigning HSocket property will call Dup.                       }
procedure TWSocketClient.Dup(newHSocket : TSocket);
begin
    inherited Dup(newHSocket);
    { Cache PeerAddr value }
    FPeerAddr := inherited GetPeerAddr;
    FPeerPort := inherited GetPeerPort;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{$IFDEF USE_SSL}
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TSslWSocketServer.Create(AOwner : TComponent);
begin
    inherited Create(AOwner);
    // Server socket doesn't use SSL to listen for clients
    FSslEnable       := TRUE;
    Port             := '443';
    Proto            := 'tcp';
    Addr             := '0.0.0.0';
    SslMode          := sslModeServer;
    FIcsHosts        := TIcsHostCollection.Create(self);            { V8.45 }
    FX509CAList      := TX509List.Create(self);                     { V8.64 }
    FValidated       := False;                                      { V8.48 }
    FCertExpireDays  := 30;                                         { V8.57 }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
destructor TSslWSocketServer.Destroy;                                 { V8.45 }
begin
    if Assigned(FIcsHosts) then begin
        FIcsHosts.Free;
        FIcsHosts := nil;
    end;
    if Assigned(FX509CAList) then begin
        FX509CAList.Free;
        FX509CAList := nil;
    end;
    inherited Destroy;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslWSocketServer.Close;                        { V8.63 }
begin
    OrderClose;   { stop any pending X509 certificate orders }
    inherited Close;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslWSocketServer.MultiListenItemClass: TWSocketMultiListenItemClass;
begin
    Result := TSslWSocketMultiListenItem;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslWSocketServer.TriggerClientConnect(
    Client : TWSocketClient; Error : Word);
var
    I: Integer;
begin
   { V8.45 set SslEnable before event handler, so it can be used there }
    if FMultiListenIndex = -1 then
        Client.SslEnable := Self.SslEnable      { V8.50 }
    else begin
        Assert(MultiListenIndex < MultiListenSockets.Count);
        Client.SslEnable := TSslWSocketMultiListenItem(
                  MultiListenSockets[FMultiListenIndex]).SslEnable;
    end;

 { V8.45 keep server binding information for client }
    Client.FMultiListenIdx := FMultiListenIndex;
    if FMultiListenIndex = -1 then begin
        Client.FServerAddr := GetXAddr;
        Client.FServerPort := FBindPort;  { V8.64 }
    end
    else begin
        Client.FServerAddr := MultiListenSockets[FMultiListenIndex].Addr;  { V8.64 }
        Client.FServerPort := MultiListenSockets[FMultiListenIndex].FBindPort; { V8.64 }
    end ;

  { V8.45 check binding for IcsHost - may be changed later if SNI or Host: header checked }
  { beware multiple hosts may have the same binding }
    if FIcsHosts.Count > 0 then begin
        for I := 0 to FIcsHosts.Count - 1 do begin
            if NOT (FIcsHosts [I].HostEnabled) then continue;
            if (FIcsHosts [I].FBindIdxNone = FMultiListenIndex) or
               (FIcsHosts [I].FBindIdxSsl = FMultiListenIndex) or
                 (FIcsHosts [I].FBindIdx2None = FMultiListenIndex) or
                   (FIcsHosts [I].FBindIdx2Ssl = FMultiListenIndex) then begin
                Client.FIcsHostIdx := I;
                Client.FHostTag := FIcsHosts [I].HostTag;
                Break;
            end;
        end;
    end;

    inherited TriggerClientConnect(Client, Error);
    { The event handler may have closed the connection }
    { The event handler may also have started the SSL }
    if (Error <> 0) or (Client.State <> wsConnected) or
       (Client.SslState > sslNone) then
        Exit;

    if Client.SslEnable then begin
        Client.SslMode                  := FSslMode;
        Client.SslAcceptableHosts       := FSslAcceptableHosts;
        Client.SslContext               := FSslContext;
        Client.OnSslVerifyPeer          := OnSslVerifyPeer;
        Client.OnSslSetSessionIDContext := OnSslSetSessionIDContext;
        Client.OnSslSvrNewSession       := OnSslSvrNewSession;
        Client.OnSslSvrGetSession       := OnSslSvrGetSession;
        Client.OnSslHandshakeDone       := OnSslHandshakeDone;
        Client.OnSslServerName          := OnSslServerName;   { V8.07 }
        Client.OnSslAlpnSelect          := OnSslAlpnSelect;   { V8.56 }
        try
            if Client.SslMode = sslModeClient then
                Client.StartSslHandshake
            else
                Client.AcceptSslHandshake;
        except
            on E: Exception do begin                            // AG 12/18/05
                Client.SslEnable := False;
                Client.Abort;
                { Don't abort silently }
                Client.HandleBackGroundException(E, 'TriggerClientConnectd Accept SSL Handshake');    { V8.62 }
            end;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslWSocketServer.GetIcsHosts: TIcsHostCollection;                   { V8.45 }
begin
    Result := FIcsHosts;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslWSocketServer.SetIcsHosts(const Value: TIcsHostCollection);   { V8.45 }
begin
    if FIcsHosts <> Value then begin
        if Assigned(FIcsHosts) then
            FIcsHosts.Free;
        FIcsHosts := Value;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// V8.62 create certificate file name from domain common name, change . and space to _ and * to x
function BuildCertName(const Domain: String): String;
begin
    Result := StringReplace (Domain, '.', '_', [rfReplaceAll]) ;
    Result := StringReplace (Result, IcsSpace, '_', [rfReplaceAll]) ;  { V8.64 }
    if Result = '' then Exit;
    if Result [1] = '*' then Result [1] := 'x';  // can not have * in file names
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{$IFDEF AUTO_X509_CERTS}  { V8.59 }
function  TSslWSocketServer.GetSslX509Certs: TComponent;                       { V8.57 }
begin
    Result := FSslX509Certs;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslWSocketServer.SetSslX509Certs(const Value : TComponent);   { V8.57 }
begin
    if Value <> FSslX509Certs then begin
        FSslX509Certs := Value;
    end;
end;


{$ENDIF} // AUTO_X509_CERTS
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ are we listening on this binding already }
function TSslWSocketServer.FindBinding(const MAddr: String;
                                MPort: Integer; var MIndex: Integer): boolean;      { V8.45 }
var
    J: integer;
begin
    Result := False;
    if (Addr = MAddr) and (Port = IntToStr(MPort)) then begin
        Result := True;
        MIndex := -1;
        Exit;
    end;
    if MultiListenSockets.Count = 0 then Exit;
    for J := 0 to MultiListenSockets.Count -1 do begin
        if (MultiListenSockets[J].Addr = MAddr) and
                     (MultiListenSockets[J].Port = IntToStr(MPort)) then begin
            Result := True;
            MIndex := J;
            Exit;
        end;
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ V8.57 order a new certificates from supplier }
function TSslWSocketServer.OrderCert(HostNr: Integer): Boolean;
{$IFDEF AUTO_X509_CERTS}  { V8.59 }
var
    I: Integer;
    FName, CName: String;

 { V8.63 log what is happening via SslX509Certs component }
    procedure X509Log(const Msg: String);
    begin
        FIcsHosts[HostNr].FCertErrs := Msg;
        (FSslX509Certs as TSslX509Certs).LogEvent(Msg);
    end;

{$ENDIF}
begin
    Result := False;
    if (HostNr < 0) or (HostNr >= FIcsHosts.Count) then Exit;
    with FIcsHosts[HostNr] do begin
{$IFDEF AUTO_X509_CERTS}  { V8.59 }
        if NOT FSslCertAutoOrder then begin
            FCertErrs := 'Server Certificate Ordering Disabled';
            Exit;
        end;
        if NOT Assigned(FSslX509Certs) then begin
            FCertErrs := 'Server Does Not Support Certificate Ordering';
            Exit;
        end;

     { V8.63 something sensible in log before all the ordering stuff }
        X509Log('Starting SSL/TLS Certificate Order for Domain: ' + HostNames[0] +
             ', From: ' + CertProduct + ' Using Challenge: ' + ChallengeTypeLits[CertChallenge] +
             ', With: ' + SupplierProtoLits[CertSupplierProto]);
        FCertErrs := '';  // last one was not an error

        if CertChallenge in [ChallFileFtp, ChallDnsMan, ChallEmail] then begin    { V8.62 }
            X509Log('Unsupported Challenge for Socket Server');
            Exit;
        end;

     { V8.62 HTTP challenges assumes this is a web server that supports the
          .well-known path or SSI ALPN and only works after server starts }
        if CertChallenge in [ChallFileUNC, ChallAlpnUNC, ChallAlpnApp, ChallFileApp] then begin    { V8.62 }
            if WellKnownPath = '' then begin
                X509Log('No .Well-Known Directory Specified for HTTP Challenge');
                Exit;
            end;
            if (CertChallenge in [ChallFileUNC, ChallFileApp] ) and (FBindNonPort <> 80) then begin
                X509Log('Port 80 Not Listening');
                Exit;
            end;
            if (CertChallenge in [ChallAlpnUNC, ChallAlpnApp]) and (FBindSslPort <> 443) then begin
                X509Log('Port 443 Not Listening');
                Exit;
            end;
            if (FState <> wsListening) then begin
                X509Log('Server not Listening');
                Exit;
            end;
        end;

     { V8.62 Local Server uses a separate local web server for servers not using
        ports 80 or 443 such as FTP, SMTP, etc, configure it, will be started automatrically }
        if (CertChallenge = ChallFileSrv) or (CertChallenge = ChallAlpnSrv) then begin
            (FSslX509Certs as TSslX509Certs).DomWebSrvIP := FBindIpAddr;
        end;

      // some sanity checks to make sure sensible settings made
        if CertSupplierProto = SuppProtoNone then begin
            X509Log('No Supplier Protocol');
            Exit;
        end;
        if CertDirWork = '' then begin
            X509Log('No Work Directory Specified');
            Exit;
        end;

     // need to cast type here to avoid circular references with TSslX509Certs unit
     // which uses this server
        with FSslX509Certs as TSslX509Certs do begin
            try

            // open supplier account, based on file directory
                if (SupplierProto <> CertSupplierProto) or
                               (CompareText(DirCertWork, CertDirWork) <> 0) then begin
                  // V8.63 make sure account closes and local web server stops
                    AutoAccountClose := True;
                    AccountTimeOutMins := 5;
                    Result := OpenAccount(CertDirWork, False);  // don't create new account
                    if NOT Result then begin
                        X509Log('Failed to Open Certificate Supplier Database - ' + LastError);  // V8.63
                        Exit;
                    end;
                end;

             // must have correct expected SSL certificate file name
                CertCommonName := HostNames[0];
                FName := IcsExtractNameOnly(FSslCert);
             // V8.63 allow for file name having -bundle or -cert appended to end
                CName := BuildCertName(CertCommonName);
                if Pos (CName, FName) <> 1 then begin
                    X509Log('Certificate File Name Mismatch, File: ' +
                                              Fname + ',  Common Name: ' + CName);
                    Result := False;  // V8.63
                    Exit;
                end;

            // if common name not in database, set minimal stuff
                if NOT CertReadDomain(CertCommonName) then begin
                    CertCommonName := HostNames[0];   { V8.64 }
                    CertCsrOrigin := CsrOriginProps;
                    CertApprovEmail := '';
                    CertSerNumType := SerNumRandom;
                    CertOutFmts := [OutFmtBudl, OutFmtP12];
                end;

            // update domains in case server INI file changed since last time
                DirWellKnown := WellKnownPath;
                DirPubWebCert.Text := ExtractFilePath(SslCert);
                PrivKeyPassword := SslPassword;
                if PrivKeyPassword <> '' then
                    PrivKeyCipher := PrivKeyEncTripleDES
                else
                    PrivKeyCipher := PrivKeyEncNone;
                PrivKeyType := CertPKeyType;
                CertSignDigestType := CertSignDigest;
                SuppCertChallenge := CertChallenge;
                SuppCertProduct := CertProduct;
                CertSubAltNames.Clear;
                for I := 0 to HostNames.Count - 1 do
                    CertSubAltNames.AddItem(HostNames[I], DirWellKnown, DirPubWebCert.Text, CertApprovEmail);

                Result := CertSaveDomain(CertCommonName);
                if NOT Result then begin
                    X509Log('Failed to Save New Domain to Certificate Database - ' + LastError);  // V8.63
                    CloseAccount;  // V8.63
                    Exit;
                end;

                Result := CertGetChallgDomain(CertCommonName);  { V8.64 get challenges first }
                if NOT Result then begin
                    X509Log('Failed to Get Certificate Challenges - ' + LastError);  // V8.63
                    CloseAccount;  // V8.63
                    Exit;
                end;

             // order new SSL certificate
                Result := CertOrderDomain(CertCommonName);      { test and start challenges }
                if NOT Result then begin
                    X509Log('Failed to Order New Certificate - ' + LastError);  // V8.63
                    CloseAccount;  // V8.63
                    Exit;
                end;
              // note order may not be completed yet, event called to install new certificate
            except
                on E:Exception do begin
                    FCertErrs := E.Message; { V8.52 keep exception }
                    Result := False;  // V8.63
                    CloseAccount; // V8.63
                end;
            end;
        end;
{$ELSE}
       FCertErrs := 'Server Does Not Support Certificate Ordering';
{$ENDIF}
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ V8.63 close certificate ordering account, stop challenge web server }
procedure TSslWSocketServer.OrderClose;
begin
{$IFDEF AUTO_X509_CERTS}
    if NOT Assigned(FIcsHosts) then Exit;   { V8.64 }
    if FIcsHosts.Count = 0 then Exit;
    if NOT FSslCertAutoOrder then Exit;
    if NOT Assigned(FSslX509Certs) then Exit;
    (FSslX509Certs as TSslX509Certs).CloseAccount;
{$ENDIF}
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ V8.64 load Root CA to validate SSL certificate chains }
procedure TSslWSocketServer.LoadRootCAList;
begin
    if (Pos(PEM_STRING_HDR_BEGIN, FRootCA) > 0) then
        FX509CAList.LoadAllFromString(FRootCA)
    else if (FRootCA <> '') and FileExists(FRootCA) then
        FX509CAList.LoadAllFromFile(FRootCA)
    else
        FX509CAList.LoadAllFromString(sslRootCACertsBundle);  // builtin roots
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ V8.57 load certificates for one host }
{ ForceLoad=True means ignore timestamps and always load certs but no ordering }
function TSslWSocketServer.LoadOneCert(HostNr: Integer; ForceLoad: Boolean;
                              var LoadNew: Boolean; AllowSelfSign: Boolean=False): Boolean;  { V8.63 }
var
    NewFStamp: TDateTime;
    FDir, FName: String;

 { V8.64 SslX509Certs component allows better logging }
    procedure X509Log(const Msg: String);
    begin
{$IFDEF AUTO_X509_CERTS}
        if Assigned(FSslX509Certs) then
            (FSslX509Certs as TSslX509Certs).LogEvent(Msg);
{$ENDIF}
    end;

  { V8.64 create self signed certificate }
    function CreateSelfSigned: Boolean;
    begin
        Result := False;
        AllowSelfSign := True;
        with FIcsHosts[HostNr] do begin
            if FName = '' then begin
                FDir := ExtractFileDir(FSslCert);
                if (FDir = '') OR (NOT DirectoryExists(FDir)) then FDir := IcsGetTempPath;
                FName := IncludeTrailingPathDelimiter(FDir) + BuildCertName(HostNames[0]) + '.pfx';
            end;
            if NOT FileExists(FName) then begin
                try
                    CreateSelfSignCertEx(FName, HostNames[0], HostNames,
                                                            PrivKeyECsecp256, FSslPassword, '');
                    NewFStamp := IcsGetFileUAge(FName);
                    FCertErrs := FCertErrs + ', Created New Self Signed Certificate: ' + FName;
                    Result := True;
                except
                   on E:Exception do begin
                        FCertErrs := FCertErrs + ', Failed to Create Signed Certificate: ' +
                                                                        FName + ' - ' + E.Message;
                        X509Log(FCertErrs);
                        Exit;
                   end;
                end;
            end
            else begin
                Result := True;
                FCertErrs := FCertErrs + ', Skipped  New Self Signed Certificate, using: ' + FName;
            end;

      { should we try and download a new certificate }
{$IFDEF AUTO_X509_CERTS}
            if FSslCertAutoOrder and (CertSupplierProto > SuppProtoNone) and
                                                Assigned(FSslX509Certs) then begin
                if ForceLoad then
                    FCertErrs := FCertErrs + ', Pending Order fo New Certificate'
                else if OrderCert(HostNr) then
                    FCertErrs := FCertErrs + ', Ordered New Certificate, May Not Be Available Yet'
                else
                    FCertErrs := FCertErrs + ', Failed to Order New Certificate';
            end;
            X509Log(FCertErrs);
{$ENDIF}
        end;
    end;


begin
    Result := False;
    LoadNew := False;
    if (HostNr < 0) or (HostNr >= FIcsHosts.Count) then Exit;
    with FIcsHosts[HostNr] do begin
    try
        FCertErrs := '';
        FCertInfo := '';
        FCertValRes := chainOK;
        FName := '';
        if FHostNames.Count = 0 then Exit;  // sanity check

    { load certificate, private key and optional intermediates, that may all be
      in the same PEM or PFX bundle file or seperate files, or may be base64 text }

        if (Pos(PEM_STRING_HDR_BEGIN, FSslCert) > 0) then begin
          { can we check this ?? }
            SslCtx.SslCertX509.LoadFromText(FSslCert, croTry, croTry, FSslPassword)
        end
        else begin
            NewFStamp := -1;
            if FSslCert <> '' then
                NewFStamp := IcsGetFileUAge(FSslCert);  { keep file time stamp to check nightly, V8.51 UTC time }
            if NewFStamp <= 0 then begin
                FCertErrs := 'SSL Certificate Not Found: ' + FSslCert;

              { V8.62 see if adjusting name to default used by ordering, need directory }
                FDir := ExtractFileDir(FSslCert);
                if (FDir <> '') and DirectoryExists(FDir) then begin
                    FName := IncludeTrailingPathDelimiter(FDir) +
                                                    BuildCertName(HostNames[0]) + '.pfx';
                    NewFStamp := IcsGetFileUAge(FName);
                    if (NewFStamp > 0) or FSslCertAutoOrder then begin
                        FSslCert := FName;
                        FCertErrs := FCertErrs + ', Using Default SSL certificate Instead: ' + FName;
                    end;
                end;
            end;

         { really need an SSL certificate otherwise SSL does not work }
            if NewFStamp <= 0 then begin

              { V8.64 create self signed certificate so server can start }
                 if NOT CreateSelfSigned then Exit;
                 FSslCert := FName;
            //    Exit;
            end;
            if ForceLoad or (FCertFStamp <> NewFStamp) then begin
                LoadNew := True;
                FCertFStamp := NewFStamp;
                SslCtx.SslCertX509.PrivateKey := Nil;  { V8.57 clear old key }
                SslCtx.SslCertX509.LoadFromFile(FSslCert, croTry, croTry, FSslPassword);
            end;
        end;
        if NOT SslCtx.SslCertX509.IsCertLoaded then begin
            FCertErrs := 'SSL Certificate Failed to Load - ' + FSslCert;

       { V8.64 create self signed certificate so server can start }
           if NOT CreateSelfSigned then Exit;
           FSslCert := FName;
           SslCtx.SslCertX509.PrivateKey := Nil;
           SslCtx.SslCertX509.LoadFromFile(FSslCert, croTry, croTry, FSslPassword);
        end;
        if NOT SslCtx.SslCertX509.IsPKeyLoaded then begin
            if (FSslKey = '') then begin
                FCertErrs := 'SSL Private Key Can Not Be Blank for ' + FSslCert;
                Exit;
            end;
            if (Pos(PEM_STRING_HDR_BEGIN, FSslKey) > 0) then begin
               SslCtx.SslCertX509.PrivateKeyLoadFromText(FSslKey, FSslPassword)
            end
            else
               SslCtx.SslCertX509.PrivateKeyLoadFromPemFile(FSslKey, FSslPassword);
        end ;
        if (NOT SslCtx.SslCertX509.IsInterLoaded) and (FSslInter <> '') then begin
            if (Pos(PEM_STRING_HDR_BEGIN, FSslInter) > 0) then begin
              { can we check this ?? }
                SslCtx.SslCertX509.LoadIntersFromString(FSslInter)
            end
            else begin
                NewFStamp := IcsGetFileUAge(FSslInter);  { keep file time stamp to check nightly, V8.51 UTC time }
                if NewFStamp <= 0 then begin
                    FCertErrs := 'SSL Intermediate Certificate Not Found: ' +
                                        FSslInter + ' for Certificate ' + FSslCert;
                    Exit;
                end;
                if ForceLoad or (FInterFStamp <> NewFStamp) then begin
                    LoadNew := True;
                    FInterFStamp := NewFStamp;
                    SslCtx.SslCertX509.LoadIntersFromPemFile(FSslInter);
                end;
            end;
        end ;

     { validate SSL certificate chain, helps to ensure server will work! }
        FCertDomains := IcsUnwrapNames (SslCtx.SslCertX509.SubAltNameDNS);
        FCertExiry := SslCtx.SslCertX509.ValidNotAfter;
     { V8.47 warning, currently only checking first Host name }
     { V8.57 expire days now configurable }
     { V8.63 optionally don't check self signed }
        if SslCtx.SslCertX509.SelfSigned then begin
            if AllowSelfSign then
                FCertValRes := chainOK
            else
                FCertValRes := chainWarn;
            FCertErrs := 'Certificate self signed';
            FCertInfo := 'Server: ' + SslCtx.SslCertX509.CertInfo(False);
        end
        else
          { V8.64 pass CAList to validate against }
            if FX509CAList.Count = 0 then LoadRootCAList;
            FCertValRes := SslCtx.SslCertX509.ValidateCertChain(FHostNames[0],
                              FX509CAList, FCertInfo, FCertErrs, FCertExpireDays);
        if FCertValRes = chainOK then begin
            FCertErrs := 'Chain Validated OK';
            Result := True;
        end
        else begin
            if FCertValRes = chainWarn then begin
                FCertErrs := 'SSL Certificate Chain Warning - ' + FCertErrs;
                Result := True;
            end
            else begin
                FCertErrs := 'SSL Certificate Chain Failed - ' + FCertErrs;
            end;

         // should we try and download a new certificate
         // V8.64 only once the server is listening, challenges fail otherwise
{$IFDEF AUTO_X509_CERTS}  { V8.62 }
            if FSslCertAutoOrder and (CertSupplierProto > SuppProtoNone) and
                                             Assigned(FSslX509Certs) then begin
                if ForceLoad then
                    FCertErrs := FCertErrs + ', Pending Order fo New Certificate'
                else if OrderCert(HostNr) then
                    FCertErrs := FCertErrs + ', Ordered New Certificate'
                else
                    FCertErrs := FCertErrs + ', Failed to Order New Certificate';
            end;
            X509Log(FCertErrs);
{$ENDIF}
        end;
        except
            on E:Exception do begin
                FCertErrs := E.Message; { V8.52 keep exception }
            end;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
 { V8.45 if IcsHostCollection has been specified, use it to define all
   bindings and SSL contexts, including SSL certificates and security,
   with SSL Server Name Indication (SNI) used to select the correct host.
   HTTP descendants of SocketServer might check the Host: header for
   non=SSL connections }

function TSslWSocketServer.ValidateHosts(Stop1stErr: Boolean=True;
                           NoExceptions: Boolean=False; AllowSelfSign: Boolean=False): String; { V8.48, V8.63 }
var
    I, FirstSsl: integer;
    FirstHost, LoadNew, LoadFlag: Boolean;

    procedure AddBinding(const MAddr: String; MPort: Integer;
                      SslFlag: Boolean; var MIndex: Integer; var Info: String);
    var
        SockFam: TSocketFamily;
        ListenItem: TSslWSocketMultiListenItem;
    begin
        if (MAddr = '') OR (NOT WSocketIsIPEx (MAddr, SockFam)) then begin
            raise ESocketException.Create('Host #' + IntToStr(I) +
                            ', Invalid host listen IP address: ' + MAddr);
            exit ;
        end ;
        if FirstHost then begin    { first is not a multi-listen }
            FirstHost := False;
            Self.Addr := MAddr;
            Self.Port := IntToStr(MPort);
            Self.SocketFamily := SockFam;
            Self.SslEnable := SslFlag;   { V8.50 }
            MIndex := -1;
        end
        else begin
            { ignore duplicates, but keep binding index }
            if NOT FindBinding(MAddr, MPort, MIndex) then begin
                MultiListenSockets.Add;
                MIndex := MultiListenSockets.Count - 1;
                ListenItem := MultiListenSockets [MIndex] as TSslWSocketMultiListenItem;
                ListenItem.Addr := MAddr;
                ListenItem.Port := IntToStr(MPort);
                ListenItem.SocketFamily := SockFam;
                ListenItem.SslEnable := SslFlag;
            end;
        end;
        if Info <> '' then Info := Info + ', ';        { V8.47 }
        Info := Info + MAddr + ':' + IntToStr(MPort);
    end;

    function AddTls13(const Ciphers: String): String; { V8.52 }
    begin
        if ICS_OPENSSL_VERSION_NUMBER < OSSL_VER_1101 then
            result := Ciphers
        else
            result := sslCipherTLS13 + Ciphers;
    end;

begin
    Result := '';
    FValidated := False;                                      { V8.48 }
    if FIcsHosts.Count = 0 then Exit;
    Port := '0';        { V8.64 illegal port in case no hosts set }
    FirstSsl := -1;
    FirstHost := True;

// set-up bindings and SSL context for each host
    MultiListenSockets.Clear;
    for I := 0 to FIcsHosts.Count - 1 do begin
        with FIcsHosts [I] do begin
        try
            FCertInfo := 'No certificates available';   { V8.52 }
            FBindInfo := '';
            FCertErrs := '';
            FBindIdxNone := -2;  { bindings are -1 to +x }
            FBindIdx2None := -2;
            FBindIdxSsl := -2;
            FBindIdx2Ssl := -2;
            if (NOT FHostEnabled) then continue;

         { create up to four bindings for host, IPv4, IPv6, non-SSL, SSL }
          //  if (FBindNonPort = 0) and (BindSslPort = 0) then continue;
         { V8.64 allow NonSSlPort to be zero for random port, not for SSL }
            if (FBindNonPort > 0) or (FBindSslPort = 0) then begin
                AddBinding(FBindIpAddr, FBindNonPort, False, FBindIdxNone, FBindInfo);
                if FBindIpAddr2 <> '' then
                    AddBinding(FBindIpAddr2, FBindNonPort, False, FBindIdx2None, FBindInfo);
            end;
            if (FBindSslPort > 0) then begin
                AddBinding(FBindIpAddr, FBindSslPort, True, FBindIdxSsl, FBindInfo);
                if FBindIpAddr2 <> '' then
                    AddBinding(FBindIpAddr2, FBindSslPort, True, FBindIdx2Ssl, FBindInfo);
            end;

     { if using SSL, set-up context with server certificates }
            if (FBindSslPort > 0) or FAuthSslCmd then begin  { V8.63 optional SSL }
                if (FSslCert = '') then begin
                    FCertErrs := 'Host #' + IntToStr(I) + ', SSL certificate can not be blank';
                    Result := Result + FCertErrs + #13#10;  { V8.52 }
                    if Stop1stErr then raise ESocketException.Create(Result);
                    continue;
                end;
             { V8.64 really need a hostname of some sort to create a certificate file }
                if Length(FHostNames[0]) <= 1 then FHostNames[0] := 'unknown';
                if NOT Assigned(SslCtx) then
                    SslCtx := TSslContext.Create(Self);
                if FirstSsl < 0 then FirstSsl := I;
           {$IFNDEF NO_DEBUG_LOG}
                SslCtx.IcsLogger := IcsLogger;                           { V8.46 }
           {$ENDIF}
                SslCtx.SslVersionMethod := sslBestVer_SERVER;
                SslCtx.SslMinVersion := sslVerTLS1;
                SslCtx.SslMaxVersion := sslVerMax;
                SslCtx.SslOptions := [sslOpt_CIPHER_SERVER_PREFERENCE,
                        sslOpt_NO_SESSION_RESUMPTION_ON_RENEGOTIATION,
                        sslOpt_NO_COMPRESSION,
                        sslOpt_SINGLE_DH_USE, SslOpt_SINGLE_ECDH_USE ];
                SslCtx.SslCipherList := sslCiphersMozillaSrvInter ;  // excludes MSIE6/XP no SSLv3

             { set SSL security choices before loading certificates, which may then fail }
                case FSslSrvSecurity of
                  sslSrvSecNone: begin                { all protocols and ciphers, any key lenghts }
                      SslCtx.SslMinVersion := sslVerSSL3;
                      SslCtx.SslCipherList := 'ALL';
                      SslCtx.SslSecLevel := sslSecLevelAny;
                  end;
                  sslSrvSecSsl3: begin                { SSL3 only, all ciphers, any key lenghts, MD5 }
                      SslCtx.SslMinVersion := sslVerSSL3;
                      SslCtx.SslMaxVersion := sslVerSSL3;
                      SslCtx.SslCipherList := 'ALL';
                      SslCtx.SslSecLevel := sslSecLevelAny;
                  end;
                  sslSrvSecBack: begin                { TLS1 or later, backward ciphers, RSA/DH keys=>1024, ECC=>160, no MD5, SHA1 }
                      SslCtx.SslMinVersion := sslVerTLS1;
                      SslCtx.SslCipherList := AddTls13(sslCiphersMozillaSrvBack);
                      SslCtx.SslSecLevel := sslSecLevel80bits;
                  end;
                  sslSrvSecInter: begin               { TLS1.1 or later, intermediate ciphers, RSA/DH keys=>2048, ECC=>224, no RC4, no SHA1 certs }
                      SslCtx.SslMinVersion := sslVerTLS1_1;   // June 2018 PCI council EOF TLS1.0 30 June 2018
                      SslCtx.SslCipherList := AddTls13(sslCiphersMozillaSrvInter);
                      SslCtx.SslSecLevel := sslSecLevel112bits;  // Dec 2016  keys=>2048, ECC=>224, no RC4, no SSL3, no SHA1 certs
                  end;
                  sslSrvSecInterFS: begin             { TLS1.1 or later, intermediate FS ciphers, RSA/DH keys=>2048, ECC=>224, no RC4, no SHA1 certs }
                      SslCtx.SslMinVersion := sslVerTLS1_1;   // June 2018 PCI council EOF TLS1.0 30 June 2018
                      SslCtx.SslCipherList := AddTls13(sslCiphersMozillaSrvInterFS);
                      SslCtx.SslSecLevel := sslSecLevel112bits;
                  end;
                  sslSrvSecHigh: begin                 { TLS1.2 or later, high ciphers, RSA/DH keys=>2048, ECC=>224, no RC4, no SHA1 certs }
                      SslCtx.SslMinVersion := sslVerTLS1_2;
                      SslCtx.SslCipherList := AddTls13(sslCiphersMozillaSrvHigh);
                      SslCtx.SslSecLevel := sslSecLevel112bits;
                  end;
                  sslSrvSecHigh128: begin               { TLS1.2 or later, high ciphers, RSA/DH keys=>3072, ECC=>256, FS forced }
                      SslCtx.SslMinVersion := sslVerTLS1_2;
                      SslCtx.SslCipherList := AddTls13(sslCiphersMozillaSrvHigh);
                      SslCtx.SslSecLevel :=sslSecLevel128bits;
                  end;
                  sslSrvSecHigh192: begin                { TLS1.2 or later, high ciphers, RSA/DH keys=>7680, ECC=>384, FS forced }
                      SslCtx.SslMinVersion := sslVerTLS1_2;
                      SslCtx.SslCipherList := AddTls13(sslCiphersMozillaSrvHigh);
                      SslCtx.SslSecLevel := sslSecLevel192bits;
                  end;
                  sslSrvSecTls12Less: begin             { TLS1.1 or 1.2, intermediate FS ciphers, RSA/DH keys=>2048, ECC=>224, no RC4, no SHA1 certs }
                      SslCtx.SslMinVersion := sslVerTLS1_1;
                      SslCtx.SslMaxVersion := sslVerTLS1_2;
                      SslCtx.SslCipherList := sslCiphersMozillaSrvInterFS;
                      SslCtx.SslSecLevel := sslSecLevel112bits;
                  end;
                  sslSrvSecTls13Only: begin             { TLS1.3 or later, intermediate FS ciphers, RSA/DH keys=>2048, ECC=>224, no RC4, no SHA1 certs }
                      SslCtx.SslMinVersion := sslVerTLS1_3;
                      SslCtx.SslCipherList := AddTls13(sslCiphersMozillaSrvInterFS);
                      SslCtx.SslSecLevel := sslSecLevel112bits;
                  end;

               end;
                SslCtx.SslECDHMethod := sslECDHAuto;

            { Enables OpenSsl's internal session caching }
                SslCtx.SslSessionCacheModes := [sslSESS_CACHE_SERVER];

             { V8.57 do we want a client SSL certificate from the browser,
                  NOTE you should check it the OnSslHandshakeDone event and
                  close the connection if invalid, beware this usually causes
                  the browser to request a certificate which can be obtrusive. }
                SslCtx.SslVerifyPeer := false;
                if FSslCliCertMethod > sslCliCertNone then begin
                    SslCtx.SslVerifyPeer := True;
                    if FSslCliCertMethod = sslCliCertOptional then
                        SslCtx.SslVerifyPeerModes := [SslVerifyMode_PEER, SslVerifyMode_CLIENT_ONCE]
                    else
                        SslCtx.SslVerifyPeerModes := [SslVerifyMode_PEER,
                                       SslVerifyMode_FAIL_IF_NO_PEER_CERT, SslVerifyMode_CLIENT_ONCE];
                end;
                SslCtx.SslSessionTimeout := 300; //sec
                SslCtx.SslDefaultSessionIDContext := 'AnyStringForSessionCaching';
                if FDHParams <> '' then begin
                    if (Pos(PEM_STRING_HDR_BEGIN, FDHParams) > 0) then
                        SslCtx.SslDHParamLines.Text := FDHParams
                    else
                        SslCtx.SslDHParamFile := FDHParams;
                end;

            { load certificate, private key and optional intermediates, that may all be
              in the same PEM or PFX bundle file or seperate files, or may be base64 text,
              validate SSL certificate chain, helps to ensure server will work!  Note
              will not order new certificate because server not yet running to check domain }
                LoadFlag := LoadOneCert(I, True, LoadNew, AllowSelfSign);  { V8.63 self sign }
                if (NOT LoadFlag) or (FCertValRes <> chainOK) then
                    Result := Result + 'Host #' + IntToStr(I) + ' ' + FHostNames[0] +
                                                               ', '  + FCertErrs + #13#10;
                if NOT LoadFlag then begin
                    if Stop1stErr then begin   //  we may load cert later
                        if NoExceptions then Exit;
                        raise ESocketException.Create(FCertErrs);
                    end;
                end;
                SslCtx.InitContext;
            end;
            except
                on E:Exception do begin
                    FCertErrs := E.Message; { V8.52 keep exception }
                    Result := Result + 'Host #' + IntToStr(I) +  ', ' + E.Message + #13#10;  { V8.52 cosmetic }
                    if Stop1stErr then Raise;
                end;
            end;
        end;
    end;
    if FirstHost then begin    { V8.64 sanity check }
        Result := Result + 'No Bindings Found';
        if NoExceptions then Exit;
        raise ESocketException.Create(Result);
    end;

  { set server context as first host with SSL }
    if FirstSsl >= 0 then FSslContext := FIcsHosts [FirstSsl].SslCtx;
    FValidated := True;                                      { V8.48 }

end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ V8.48 if IcsHostCollection has been specified, recheck SSL certificates
  to see if new files found (returns True) or old certificates are about to expire }
function TSslWSocketServer.RecheckSslCerts(var CertsInfo: String; Stop1stErr: Boolean=True;
                            NoExceptions: Boolean=False; AllowSelfSign: Boolean=False): Boolean; { V8.48, V8.63 }
var
    I: integer;
    LoadNew, LoadFlag: Boolean;
begin
    Result := False;
    CertsInfo := '';
    if FIcsHosts.Count = 0 then Exit;
    for I := 0 to FIcsHosts.Count - 1 do begin
        with FIcsHosts [I] do begin
            if NOT FHostEnabled then continue;
            if (FBindSslPort = 0) and (NOT FAuthSslCmd) then continue;   { V8.63 optional SSL }

          { load any new certificates, might order new SSL certificate }
            try
                LoadFlag := LoadOneCert(I, False, LoadNew, AllowSelfSign); { V8.63 }
                if FCertValRes <> chainOK then
                    CertsInfo := CertsInfo + 'Host #' + IntToStr(I) + ' ' +
                                          FHostNames[0] + ', '  + FCertErrs + #13#10;
                if NOT LoadFlag then begin
                    if Stop1stErr then begin
                        if NOT NoExceptions then
                            raise ESocketException.Create(FCertErrs);
                        Exit;
                    end;
                end;
                if LoadNew and LoadFlag then begin
                    SslCtx.SslSetCertX509;   { V8.57 needed so new certificate recognised }
                    CertsInfo := CertsInfo + 'Loaded new SSL certificate: ' + FSslCert + #13#10;
                    Result := True;
                end;
            except
                on E:Exception do begin
                    FCertErrs := E.Message; { V8.52 keep exception }
                    CertsInfo := CertsInfo + 'Host #' + IntToStr(I) +  ', ' + E.Message + #13#10;  { V8.52 cosmetic }
                    if Stop1stErr then Raise;
                end;
            end;
        end;

     end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ also called when MultiListen is called }
{ beware this function does not give errors if some listeners fail due to port conflicts }
procedure TSslWSocketServer.Listen;                             { V8.46 }
var
    I, K: Integer;
begin
{ better to call this before Listen and handle errors better, but in case not }
    if NOT FValidated then ValidateHosts(True, False, False);    { V8.64 exception for IcsHosts errors }
    FValidated := False;
    inherited Listen;

  { V8.64 keep bindport for each IcsHost }
    if FIcsHosts.Count > 0 then begin
        FIcsHosts[0].FBindSrvPort := Self.FBindPort;
        if MultiListenSockets.Count > 0 then begin
            for K := 0 to MultiListenSockets.Count - 1 do begin
                for I := 0 to FIcsHosts.Count - 1 do begin
                    if NOT (FIcsHosts[I].HostEnabled) then continue;
                    if (FIcsHosts[I].FBindIdxNone = K) or
                                    (FIcsHosts[I].FBindIdxSsl = K) then
                        FIcsHosts[I].FBindSrvPort := MultiListenSockets[K].FBindPort;
                end;
            end;
        end;
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TSslWSocketClient.Create(AOwner : TComponent);
begin
    inherited Create(AOwner);
    FIcsHostIdx := -1;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
destructor TSslWSocketClient.Destroy;   { V8.62 }
begin
    FreeAndNil(AlpnSslCtx);
    inherited;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslWSocketClient.StartConnection;
begin
    inherited StartConnection;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ SSL client has sent a host name using SNI, look up IcsHost }
{ V8.64 now called from ClientHello callback so have ALPN information }
procedure TSslWSocketClient.TriggerSslServerName(var Ctx: TSslContext; var ErrCode: TTlsExtError);  { V8.45 }
var
    I: Integer;
    MyServer: TSslWSocketServer;
{$IFDEF AUTO_X509_CERTS}  { V8.62 }
    CertFName: String;

 { V8.64 log what is happening via SslX509Certs component }
    procedure X509Log(const Msg: String);
    begin
        if Assigned(MyServer.FSslX509Certs) then
            (MyServer.FSslX509Certs as TSslX509Certs).LogEvent(Msg);
    end;

{$ENDIF}
begin
    inherited TriggerSslServerName(Ctx, ErrCode);
    MyServer := FServer as TSslWSocketServer;

  { if event has not set an SslContext, look for IcsHost instead }
    if NOT Assigned(Ctx) then begin
        with MyServer do begin
            if FIcsHosts.Count > 0 then begin
                for I := 0 to FIcsHosts.Count - 1 do begin
                    if NOT (FIcsHosts [I].HostEnabled) then continue;
                    if (FIcsHosts [I].FBindIdxSsl <> Self.FMultiListenIdx) and
                         (FIcsHosts [I].FBindIdx2Ssl <> Self.FMultiListenIdx) then continue;
                    if FIcsHosts [I].SslCtx.SslCertX509.PostConnectionCheck(Self.FSslServerName) then begin
                        Self.FIcsHostIdx := I;
                        Self.FHostTag := FIcsHosts [I].HostTag;
                        Ctx := FIcsHosts [I].SslCtx;
                        {$IFNDEF NO_DEBUG_LOG}
                            if CheckLogOptions(loSslInfo) then
                                DebugLog(loSslInfo, 'SNI Found "' + Self.FSslServerName +
                                                '" for IcsHost #' + IntToStr(I));
                        {$ENDIF}
                        break;
                    end;
                end;
            end;
        end;
    end;

{$IFDEF AUTO_X509_CERTS}  { V8.62 }

  { V8.64 check for Acme TLS challenge for Acme SSL certificate, load it }
    if (CliHelloData.AlpnList = AlpnAcmeTls1) then begin
        ErrCode := teeAlertFatal;   // connection dies unless we handle challenge
        if Assigned(OnClientAlpnChallg) then begin

        // if application can handle ACME tls-alpn-01 challenge, ask for certificate
            CertFName := '';
            try
                OnClientAlpnChallg(Self, Self.SslServerName, CertFName);

              // load new certifcate into ALPN context and swap to it
                if (CertFName <> '') and FileExists(CertFName) then begin
                    if NOT Assigned(AlpnSslCtx) then
                        AlpnSslCtx := TSslContext.Create(Self);
                    AlpnSslCtx.SslCertX509.LoadFromFile(CertFName, croTry, croTry, 'password');
                    AlpnSslCtx.SslVerifyPeer := false;
                    AlpnSslCtx.SslVersionMethod := sslBestVer_SERVER;
                    AlpnSslCtx.SslMinVersion := sslVerTLS1_2;
                    AlpnSslCtx.SslMaxVersion := sslVerMax;
                    AlpnSslCtx.SslCipherList := sslCiphersServer;
                    AlpnSslCtx.InitContext;
                    if AlpnSslCtx.CheckPrivateKey then begin
                        Ctx := AlpnSslCtx;
                         X509Log('Client Hello Loaded new tls-alpn-01 challenge certificate: ' +
                                                                 AlpnSslCtx.SslCertX509.CertInfo(true));
                        ErrCode := teeOk;
                    end
                    else
                        X509Log('Client Hello Failed to load certificate, no private key or Context Error: ' + CertFName);
                end
                else
                    X509Log('Client Hello Failed to find tls-alpn-01 challenge certificate: ' + CertFName);
            except
                on E:Exception do begin
                    X509Log('Client Hello Exception handling tls-alpn-01 challenge: ' + E.Message);
                end;
            end ;
        end
        else
            X509Log('Client Hello ACME tls-alpn-01 challenge not handled');
    end;
   {$ENDIF}
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ V8.62 application layer protocol negotiation, servers only }
procedure TSslWSocketClient.TriggerSslAlpnSelect(ProtoList: TStrings;
                          var SelProto: String; var ErrCode: TTlsExtError);
begin
    inherited  TriggerSslAlpnSelect(ProtoList, SelProto, ErrCode);

 // check for Acme TLS challenge for Acme SSL certificate, set it
    if ProtoList.Count = 0 then Exit;     { sanity check }
    if (ProtoList[0] = AlpnAcmeTls1) then begin
        SelProto := AlpnAcmeTls1;
        ErrCode := teeOk;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ TSslWSocketMultiListenItem }
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TSslWSocketMultiListenItem.Create(Collection: TCollection);
begin
    inherited Create(Collection);
    FSslEnable := TRUE;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ TIcsHost }
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TIcsHost.Create(Collection: TCollection);
begin
    inherited;
    FHostNames := TStringList.Create;
    FHostNames.Add ('*');
    FHostTag := 'HostTag';
    FBindIpAddr := ICS_ANY_HOST_V4;
    FBindNonPort := 0;
    FBindSslPort := 0;
    FSslSrvSecurity := sslSrvSecBack;
    FHostEnabled := True;
    SslCtx := Nil;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
destructor TIcsHost.Destroy;
begin
    FreeAndNil (SslCtx);
    FreeAndNil (FHostNames);
    inherited Destroy;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TIcsHost.GetDisplayName: string;
begin
    Result := FHostTag + ' - ';
    if FDescr <> '' then
        Result := Result + FDescr
    else begin
        Result := Result + FBindIpAddr + ':';
        if FBindNonPort = 0 then
            Result := Result + IntToStr(FBindSslPort)
        else begin
           Result := Result + IntToStr(FBindNonPort);
            if FBindSslPort <> 0 then
                Result := Result + '/' + IntToStr(FBindSslPort);
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsHost.SetHostNames(Value : TStrings);
begin
    FHostNames.Assign(Value);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TIcsHost.GetHostNameTot: integer;
begin
    if Assigned (FHostNames) then
        Result := FHostNames.Count
     else
        Result := 0;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ TIcsHosts }
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TIcsHostCollection.Create(Owner: TPersistent);
begin
  FOwner := Owner;
  inherited Create(TIcsHost);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TIcsHostCollection.GetItem(Index: Integer): TIcsHost;
begin
  Result := TIcsHost(inherited GetItem(Index));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TIcsHostCollection.SetItem(Index: Integer; Value: TIcsHost);
begin
  inherited SetItem(Index, TCollectionItem(Value));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TIcsHostCollection.GetOwner: TPersistent;
begin
  Result := FOwner;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function IcsLoadIcsHostsFromIni(MyIniFile: TCustomIniFile; IcsHosts:
                TIcsHostCollection; const Prefix: String = 'IcsHost'): Integer;
var
    J, V: Integer;
    section, hosts, S: String;
begin
    Result := 0;
    if NOT Assigned (MyIniFile) then
        raise ESocketException.Create('Must open and assign INI file first');
    if NOT Assigned (IcsHosts) then
        raise ESocketException.Create('Must assign IcsHosts first');
    IcsHosts.Clear;

  { allow up to 100 hosts }
    for J := 1 to 100 do begin
        section := Prefix + IntToStr (J);
        hosts := IcsTrim(MyIniFile.ReadString(section, 'Hosts', ''));
        if hosts = '' then continue;
     { V8.57 prefer new HostEnabled over older Enabled, if supplied }
        S := MyIniFile.ReadString(section, 'HostEnabled', '');   { V8.63 typo, was Nost }
        if S = '' then S := MyIniFile.ReadString(section, 'Enabled', 'False');
        if NOT IcsCheckTrueFalse(S) then continue;
        IcsHosts.Add;
        Result := Result + 1;

    { read site hosts from INI file   }
        with IcsHosts[IcsHosts.Count - 1] do begin
            HostEnabled := True;
            HostNames.CommaText := StringReplace(IcsLowercase(hosts), ' ', '', [rfReplaceAll]);
            BindIpAddr := MyIniFile.ReadString(section, 'BindIpAddr', '');
            BindIpAddr2 := MyIniFile.ReadString(section, 'BindIpAddr2', '');
            BindNonPort := MyIniFile.ReadInteger(section, 'BindNonPort', 0);
            BindSslPort := MyIniFile.ReadInteger(section, 'BindSslPort', 0);
            HostTag := IcsTrim(MyIniFile.ReadString(section, 'HostTag', ''));
            Descr := IcsTrim(MyIniFile.ReadString(section, 'Descr', ''));
            ForwardProxy := IcsCheckTrueFalse(MyIniFile.ReadString (section, 'ForwardProxy', 'False'));
            Proto := IcsTrim(MyIniFile.ReadString(section, 'Proto', ''));
            AuthSslCmd := IcsCheckTrueFalse(MyIniFile.ReadString (section, 'AuthSslCmd', 'False'));      { V8.63 }
            AuthForceSsl := IcsCheckTrueFalse(MyIniFile.ReadString (section, 'AuthForceSsl', 'False'));  { V8.64 }
            WebDocDir := IcsTrim(MyIniFile.ReadString(section, 'WebDocDir', ''));
            WebTemplDir := IcsTrim(MyIniFile.ReadString(section, 'WebTemplDir', ''));
            WebDefDoc := IcsTrim(MyIniFile.ReadString(section, 'WebDefDoc', ''));
            WebLogDir := IcsTrim(MyIniFile.ReadString(section, 'WebLogDir', ''));
            WellKnownPath := IcsTrim(MyIniFile.ReadString(section, 'WellKnownPath', ''));   { V8.49 }
            WebRedirectURL := IcsTrim(MyIniFile.ReadString(section, 'WebRedirectURL', '')); { V8.49 }
            WebRedirectStat := MyIniFile.ReadInteger(section, 'WebRedirectStat', 0);        { V8.49 }
            CertSupplierProto := SuppProtoNone;   { V8.59 }

            if BindSslPort <> 0 then begin
                S := IcsTrim(MyIniFile.ReadString(section, 'SslSecLevel', ''));
                if S = '' then
                    V := -1
                else if IsDigit(S[1]) then   { V8.57 ini may contain integer or enum type string }
                    V := atoi(S)
                else
                    V := GetEnumValue (TypeInfo (TSslSrvSecurity), S);
                if V < 0 then V := Ord(sslSrvSecDefault); // sanity check
                SslSrvSecurity := TSslSrvSecurity(V);
                SslCert := IcsTrim(MyIniFile.ReadString(section, 'SslCert', ''));
                SslKey := IcsTrim(MyIniFile. ReadString(section, 'SslKey', ''));
                SslPassword := IcsTrim(MyIniFile.ReadString(section, 'SslPassword', ''));
                SslInter := IcsTrim(MyIniFile.ReadString(section, 'SslInter', ''));
              { V8.57 following are for automatic ordering and installation of SSL certificates }
                CertSupplierProto := TSupplierProto(GetEnumValue (TypeInfo (TSupplierProto),
                          IcsTrim(MyIniFile.ReadString(section, 'CertSupplierProto', 'SuppProtoNone'))));
                if CertSupplierProto > High(TSupplierProto) then
                    CertSupplierProto := SuppProtoNone;                          { V8.59 sanity test }
                CertDirWork := IcsTrim(MyIniFile.ReadString(section, 'CertDirWork', ''));
                CertChallenge := TChallengeType(GetEnumValue (TypeInfo (TChallengeType),
                         IcsTrim(MyIniFile.ReadString(section, 'CertChallenge', 'ChallNone'))));
                if CertChallenge > High(TChallengeType) then
                    CertChallenge := ChallNone;                                 { V8.59 sanity test }
                CertPKeyType := TSslPrivKeyType(GetEnumValue (TypeInfo (TSslPrivKeyType),
                         IcsTrim(MyIniFile.ReadString(section, 'CertPKeyType', 'PrivKeyRsa2048'))));
                if CertPKeyType > High(TSslPrivKeyType) then
                    CertPKeyType := PrivKeyRsa2048;                             { V8.59 sanity test }
                CertProduct := IcsTrim(MyIniFile.ReadString(section, 'CertProduct', ''));
                CertSignDigest := TEvpDigest(GetEnumValue (TypeInfo (TEvpDigest),
                         IcsTrim(MyIniFile.ReadString(section, 'CertSignDigest', 'Digest_sha256'))));
                if CertSignDigest > High(TEvpDigest) then
                    CertSignDigest := Digest_sha256;                          { V8.59 sanity test }
            end;
        end;
    end;
end;




{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

{$ENDIF} // USE_SSL

end.

