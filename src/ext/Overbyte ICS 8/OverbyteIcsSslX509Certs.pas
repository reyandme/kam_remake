{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Author:       Angus Robertson, Magenta Systems Ltd
Description:  Automatically download SSL X509 certificates from various
              issuers, including free certificates from Let's Encrypt, and
              commercial certificates from CertCentre AG and Servertastic.
              Supports and ACME V2 protocols (RFC8555), and REST protocols
              for specific vendors.  Domain validated certificates should
              generally be issued without internvention, other commercial
              certificates may take days to be approved.
Creation:     Apr 2018
Updated:      Nov 2019
Version:      8.63
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

Trade Marks:  Let’s Encrypt and ISRG are trademarks of the Internet Security
              Research Group. All rights reserved.


Overview
--------

SSL/TLS X509 certificates
-------------------------

There are effectively three classes of SSL/TLS X509 certificates, Domain Validated,
Organisation Validated and Extended Validated, in order of cost and benefit,
usually with three variations, single domain, multiple domains (SANs), and
wildcard.  Adding multiple domains to a certificate can ease administration and
is cheaper than multiple certificates, wild card means any subdmains usually for
the cost of about six single domains.

Domain Validated certificate issuance is mostly automated so they are cheap (or
free), using one of four challenge methods: file validation where the supplier
checks for a specific file under the domain, usually http://domain/.well-known/file,
domain validation where a special DNS record is created that can be accessed by
the supplier, TLS-ALPN SSL SNI (server name indication) validated where an
https://domain/ connection is opened passing data using the ALPN extension, with
the server returning a special self signed SSL certificate. and email validation
where an email is sent to a predefined address at the domain, ie admin@domain,
with a supplier link that must be clicked to confirm receipt and domain ownership.

File, SNI and domain validation challenges can both be automated, file is easiest
using a simple HTTP server, SNI using an HTTPS server, while domain validation is
dependent on being able to access and control the DNS server of which there are
many different products.  Note file validation challenges are not instant, the
supplier may have a queue of challenges waiting to the tested, but usually happen
within a couple of minutes. Applications need to be aware the wait may be longer.
Automated wild card certificates typically use the domain validation challenge.

Organisation and Extended Validated certificates can be ordered online, but
require manual validation that the company or organisation legally exists and is
entitled to use the domain name, which may take several days or weeks for extended
validation if legal evidence is required.  Once approved, the certificate and be
downloaded automatically.


TSslX509Certs Overview
----------------------

The TSslX509Certs component automatically downloads SSL/TLS X509 certificates from
various suppliers, including free certificates from Let's Encrypt, and commercial
certificates for Digicert, Comodo, Thawte and GeoTrust from CertCentre AG and
Servertastic (not done yet).  The component  automates the process from creating
a new private key and certificate request, placing the order, arranging for
domain validated certificates to be checked by various challenge methods,
collecting the certificate and intermediate, creating PEM and PKC12 bundle files
with the private key, then copying the files to the web server ready for
automatic installation. The TSslWSocketServer, TSslHttpServer, TSslHttpAppSrv,
TIcsProxy and TIcsHttpProxy components can assign a TSslX509Certs component to
support automatic certificate ordering of domain validated certificates with
very little extra code.

The component supports automated file challenge for Domain Validated certificates,
using an external HTTP server such as IIS or HTTP server component such as
TSslHttpServer or TSslHttpAppSrv to which files may be copied using UNC
shares, or a built-in local HTTP server so the component is self contained.
In all cases, the web server must be accessible from the public internet for the
domain (or domains) for which a certificate is being ordered.  The application
can also use an FTP server to copy files to an external HTTP server. DNS
challenge currently require the application to update the DNS server, the demo
application waits a few minutes for the user to manually update the DNS server
which allows wild card certificates to be ordered.  A pending feature is
TLS-ALPN SSL SNI challenges for Let's Encrypt using HTTPS.

The component supports the ACME V1 and V2 protocols as implemented by Let's
Encrypt to download free domain validated certificates, beware V1 bears little
resemblance to any of the Acme Internet Draft specifications, V2 is much closer
to draft 10 but only implemented sufficiently for Let's Encrypt, V2 is designed
to also handle commercial certificates which are more complicated to process.
Note that Acme V1 has been superseded by V2, and was only supported because V2
did not go public until March 2018.

You don't need to register with Let's Encrypt, but it only supplies domain
validated certificates so the domains for which you order certificates must
already be registered and have DNS pointing to a live HTTP (HTTPS next release)
server to satisfy the domain challenge.

Commercial suppliers of certificates have their own APIs, usually using HTTP
REST, currently the component supports CertCentre AG https://www.certcenter.de/,
https://www.certcenter.co.uk/ or https://www.certcenter.com/ from where you
can buy certificates issued by Comondo/Sectigo, DigiCert (including GeoTrust,
Symantec and Thawte) and GlobalSign.  You need to register with
CertCentre AG and open a reseller account to pay for any certificates bought,
although for testing most can be cancelled within 30 days without charge.
CertCentre AG uses OAuth2 authentication which is complex to set-up, but then
mostly invisible.  Domain validated certificates can be purchased and downloaded
automatically using file or DNS challenges, other types of certificates can be
ordered and then downloaded when the order is completed.

The TSslX509Certs component includes a database of certificate orders and pending
challenges, allowing certificates to be re-ordered and the supplier periodically
checked to see if a challenge has been successful when the X509 certificate can
be automatically downloaded and installed.  Events are generated upon completion
or failure, allowing the application to inform the user (by email) of certificate
ordering progress.


TSslX509Certs Accounts
----------------------

The TSslX509Certs component has a concept of an Account Directory for a
certificate supplier into which all certificate and related files will be saved,
with a database file ics-control.db containing information about the account.
certificate orders and pending challenges.  For Let's Encrypt Acme, the directory
includes an account private key (separate to certificate private keys) that is
used to identify the account, this is created automatically if the directory is
blank. This account private key will be needed to cancel or revoke any
certificates issued using it.  Note an account directory and database can only
be accessed by one application at a time, they can not be shared between
different servers.

When ordering a new certificate, temporary files may be created in the account
directory, the new certificate private key and certificate request.  Once the
order is accepted and an order number is available, these files are renamed to
include the order number for historic purposes, and when the order is completed
a second copy of all files is saved without the order number for final distribution
to the web server, and optionally copied to the web server using a UNC file share.
Note the files without order numbers are always automatically overwritten by new
orders.  So an Let's Encrypt order for the domain test3.telecom-tariffs.co.uk
will generally find the following files upon completion:

ics-control.db
AcmePrivateKey.pem
AcmePublicKey.pem
LE-SA-v1.2-November-15-2017.pdf
LE-5860824-test3_telecom-tariffs_co_uk-bundle.pem
LE-5860824-test3_telecom-tariffs_co_uk-certonly.pem
LE-5860824-test3_telecom-tariffs_co_uk-inters.pem
LE-5860824-test3_telecom-tariffs_co_uk-privatekey.pem
LE-5860824-test3_telecom-tariffs_co_uk-request.pem
LE-5860824-test3_telecom-tariffs_co_uk.pfx
test3_telecom-tariffs_co_uk-bundle.pem
test3_telecom-tariffs_co_uk-certonly.pem
test3_telecom-tariffs_co_uk-inters.pem
test3_telecom-tariffs_co_uk-privatekey.pem
test3_telecom-tariffs_co_uk-request.pem
test3_telecom-tariffs_co_uk.pfx

There is a PEM certificate signing request (CSR) file, separate PEM files for the
private key, domain certificate and intermediate certificates, then a combined PEM
bundle  with the certificates and private key, and a PKCS12 PFX file which is a
similar bundle that Windows certificate store accepts.  The certificate private
key files (and bundles) may be optionally password protected, the PFX file always
has a password since Windows requires that, it will be 'password' if not otherwise
specified. Note AcmePrivateKey is unprotected.  A wildcard order for
*.telecom-tariffs.co.uk will have a file name x_telecom-tariffs_co_uk since * can
not be used in file names.  Until the order number is available, the file name
will be LE-work, or CC-work for CertCentre.   There are component options to
ignore some of these files, if not needed.


TSslX509Certs Database
----------------------

For each account there is a database file ics-control.db containing information
about the account. certificate orders and pending challenges.  This is a simple
INI file, and is generally updated only by the TSslX509Certs component.

There is an [account] section or record with general information about the
supplier, logging, next order sequence number, account private key (for Let's
Encrypt), etc.

There are then multiple [domain-mydomain] sections or records for each X509 order
placed where my-domain is the Common Name of the certificate, and then one
section or record for each Subject Alternate Name on the certificate
[san-mydomain=mysan] including the Common Name which are used for domain
validation. These records are updated as the order progresses and may be
checked afterwards to see the main files created and certificate details.  The
record may be used to re-order a certificate, but not on the same day a
certificate was downloaded to prevent wild repeated orders.

When an order has been placed, a temporary section [challenge-mysan] is created
for each SAN on the certificate to keep track of challenge progress, effectively
a queue of waiting challenges.  This queue is checked every 30 seconds and
the supplier contacted to see if the challenge has completed or failed, the
section is then removed with the main domain and san records updated.



TSslX509Certs Sample Application
--------------------------------

There is a application Samples\Delphi\SslInternet\OverbyteIcsX509CertsTst.dpr
that illustrates all the functionality of the TSslX509Certs component, allowing
certificates to be ordered and collected by clicking a few buttons.   The
sample also shows all certificates ordered by ICS components and saved in the
account databases and allows them to be re-ordered.

In the following sample descriptions, all the fields and buttons mentioned have
corresponding properties and methods in the TSslX509Certs component itself.

On the Common tab, there are various logging options, to keep track of activity
and for diagnostics when things don't work as expected, if the Log Directory is
not blank.  There are several levels of debug logging from just connections,
through SSL negotiations, then HTTP headers and content, also Json logging for
protocol errors (or changes).  The Domain Challenge Methods are File Web Server
UNC (external), File Web Server FTP (manual), File Local Web Server (built in),
Domain Name Server (manual), Email Manually, TLS-ALPN Cert (next release).  If
using the Local Web Server, specify the IP address from the drop down box and
start it with the button, this IP address must routed to be accessible from the
public internet with any domains requiring certificates pointing at it.  Specify
a Supplier Account Email address for orders, that will receive progress
information. Add an optional private key password and encryption type (3DES) if
needed.  Certificate CSR Origin specifies whether the component should create a
new private key and CSR for a new order, or use files previously created, in
which case both should be specified and many properties will be ignored.  Click
the 'Check CSR' button to read the files and check they contain the correct
domain and the key matches.  Automatic Order Completion being ticked means the
component will check every 30 seconds to see if an order is ready for collection
and finish it automatically.

For CertCentre AG, you must create an account at https://www.certcenter.com/signup
first, then go to Settings, Your Apps & API Keys, under OAuth2 Your Apps, click
the blue + icon to create a new App, with OAuth2 Redirect-URI:
http://localhost:8080/certcenter/. Back in the sample application, on the
CertCentre 0Auth tab, copy the various parameters from your new app to the sample
fields, App Auth URl, Client ID, Client Secret and Redirect-URI, set App Token
URL to https://api.certcenter.com/oauth2/token and scope to write, web server IP
to 127.0.0.1 port 8080.  The first time you access a CertCentre function, OAuth2
authentication will be triggered to display an account login page in your default
browser, then a German language page appears so click the 'Akzeptieren' button
which should result in the sample application completing OAuth2 and displaying
access and refresh tokens with an expiry date and time, and the browser saying
'App Token Generated Successfully'.  The tokens initially remain valid for 24
hours before another login is required, but may be refreshed manually or
automatically before they expire without needing another login. Refreshed tokens
expire after six hours, but can be extended again and again, provided the sample
application is still running.

On the Domain tab set the Certificate Domain Common Name and any Subject
Alternate Names, the sample application will add the Common Name to the SAN list
if not done manually. If Domain Challenge is for UNC file, set the Web Server UNC
HTTP .Well-Known Directory' for the Common Name, and optionally for each SAN if
different.  If the final certificates are to be copied to the web server, set the
Web Server UNC Public Certificates Directory. Clicking the Test Well-Known button
will copy a file to the web server and attempt to access it using the domain name,
to prove future challenges will be successful.  If commercial certificates are
being ordered using Email Challenge, each SAN should specify the Approval Email
address required (scroll across the grid).  There are various Output Certificate
Formats that may be ticked or unticked to reduce the number of unneeded files,
Separate PEM Files, PEM Bundle File, PKCS12/PFX Bundle File, PKCS7 Bundle File
and CSR PEM File.

The Cert Admin tab has a lot more fields relating to certificate orders. All
certificates need to specify a Private Key Type and Size depending on security
requirements (generally RSA2048, EC256 is better but not supported by many
certificates), Signature Digest Type usually SHA256, Serial Number Type either
random or sequential (stored in the database), Certificate Period in days,
usually 365 for one year, 366 or more for two years, ignored for Let's Encrypt
which is always 90 days.  For commercial certificates, contact details,
organisation name, address, email and phone numbers are usually required as well.
Note that private keys EdDSA ED25519 and SHA3 hashes are not yet tested since
they are not supported by any certificate suppliers, likewise longer keys and
SHA sizes may not work.


TSslX509Certs ACME/Let's Encrypt Order Process
----------------------------------------------

ACME (Automatic Certificate Management Environment) is the protocol designed by
Let's Encrypt, currently at draft 16 and which should eventually become an
official RFC.  It is hoped other certificate suppliers will use ACME in future,
but currently only Let's Encrypt.  ACME V1 is partially supported by the
component since it was done before V2 became public, but should generally be
ignored.  Beware Let's Encrypt does not implement any of the ACME draft protocols
precisely, which is difficult for developers, but they are getting closer with V2.

Let's Encrypt offers live and staging servers, the latter is best for testing
since it issue certificates signed by a fake CA and there are fewer rate limits
than the live server which will only issue five duplicate certificates a week
(if ordering goes mad), no more than 50 per domain per week and five failed
domain validations per hour.

Select a Account Directory for the database and certificates files, either by
typing a path or clicking the square path box to select a Database Directory
using a dialog window.  Click 'Register Account' which will create a new account
private key or open an old one, and then register the account.  Once the account
 is open, the Supplier Database tab will be updated with account details and any
 certificate orders in the account database, with their issue state and details.

After completing all the necessary domain name and certificate details on the
Common, Domain and Cert Admin tabs, click 'Check Order' which will check the
challenge method specified on the Common tab is valid and repeat the local
'Test Well-Known' check for file challenges.  If the checks succeed, the order
will be written to the account database, and the 'Order Certificate' button
enabled.  The Supplier Database tab will be updated with the new order with
an Issue State of Checked.

Now click the 'Order Certificate' button to start the order process.  There will
be another local 'Test Well-Known' check.  Then Let's Encrypt is asked if it can
register each of the domain names for the certificate.  If the names are
acceptable, information about the actual challenge is returned by the supplier
and the component prepares it by writing a queue record to the database and then
by copying a file to the web server .well-known directory or starting the local
web server, or for FTP and DNS by raising an event so the application can prepare
the challenge before returning.  The sample application waits five minutes for
the DNS server to be updated manually.

Once the challenge is ready, Let's Encrypt is instructed to test the challenge,
which may take a few seconds or minutes, and the Issue State on the Supplier
Database tab will be updated to 'Challg Pend', and the 'Collect Certificate'
button will be enabled.

If Automatic Order Completion is enabled (on the Common tab), the component will
check for successful or failed challenges every 30 seconds while the sample
application is running, updating Issue Status to 'Challg OK', 'Collected' and
'Installed' if the order is successful, or 'None' if it fails the challenges or
problems in collecting the certificate. If Automatic Order Completion is not
enabled, clicking the 'Collect Certificate' button will check if the challenges
have been successful and proceed to collect the new SSL certificate.

Multiple certificate orders may be placed using the same account, without waiting
for earlier orders to be completed.  If the sample application is stopped, the
next time it is run and the Supplier Account opened, any pending orders will be
checked and completed if possible, or failed.

Once all challenges succeed, the component proceeds to collect the certificate.
First, a new private key and certificate signing request will be created and
submitted or old ones uses if so specified on the Common tab. If the CSR matches
the domain challenge, a new domain SSL/TLS X509 certificate is downloaded and
saved including the order number, then the intermediate certificate that will be
needed by the web server, then the PEM and PKCS12 bundles are built by adding the
private key, as detailed above.  Finally the component runs a check to validate
the certificate chain, and reports all the details. If validation passes, all the
files are saved a second time without the order number, as detailed above. and
the Issue Status updated to 'Collected'.  If a Web Server UNC Public Certificate
Directory has been specified, the certificates will be copied to the servers,
and the Issue Status updated to 'Installed'.  Servers based on TWSocketServer
will periodically check for new SSL certificates (RecheckSslCerts method) and
will automatically install the new certificate.

Note that Let's Encrypt certificates are only valid for three months since they
are intended to be renewed automatically.


TSslX509Certs CertCentre Order Process
--------------------------------------

CertCentra AG orders are similar in concept to Let's Encrypt, but require a
commercial reseller account to opened to pay for commercial certificates, as
described earlier.  It is also necessary to choose the Certificate Product
carefully, probably with the assistance of the CertCentre web site, although
the sample application provides basic certificate features and cost.  Note
that Certificate Products change periodically as companies change name, issue
new products or cease old ones.  So renewing orders annually may not always work.

Select a Account Directory for the database and certificates files.  Click the
'Get Profile' button  will trigger OAuth2 if necessary (see earlier), then
check your account  and list the Certificate Products that can be ordered as
a list.  Clicking on a Certificate Product will display details and cost,
similarly to these examples:

PositiveSSL
Cost 6.7 GBP/year
Max Validity: 24 months, Features: "DV","ECC"
CA: Comodo, Refund Period: 30 days
DV Methods: "FILE","DNS","EMAIL"
Predicted Approval Duration: 3 mins

InstantSSL
Cost 23.1 GBP/year
Max Validity: 24 months, Features: "OV","RI","ECC"
CA: Comodo, Refund Period: 30 days
Predicted Approval Duration: 2 hours

PositiveSSL Wildcard
Cost 77. GBP/year
Max Validity: 24 months, Features: "DV","WC","ECC"
CA: Comodo, Refund Period: 30 days
DV Methods: "FILE","DNS","EMAIL"
Predicted Approval Duration: 3 mins

Comodo mit EV Multi-Domain (MDC)
Cost 183.2 GBP/year
Max Validity: 24 months, Features: "EV","SAN","RI","ECC"
CA: Comodo, Refund Period: 30 days
SANMaxHosts: 250 at 60.2 GBP/year each
Predicted Approval Duration: 3 hours


Only certifcates showing DV Methods as FILE or DNS can use automated challenges,
EMAIL will need a manual response but collection will be automatic.  Organisation
and Extended validation (OV and EV) are processed manually.  ECC means that
EC private keys are supported.  WC means wild card, SAN is multiple domain names.

For commercial certificates, when checking the order a quotation is returned for
the certificate cost.  The word BUY needs to typed to avoid spending money
too easily, then 'Order Commercial Cert' clicked. The private key and CSR are
generated and the order placed.  A number of errors may occur at this stage,
mostly related to missing fields such as address, telephone, etc.  For domain
validated certificates, challenge validation will then start, being automatic
for file similarly to Acme.  For email validation, organisation and extended
validated certificates, an order number is returned and the process now stalls
 for manual processing.

If Automatic Order Completion is enabled (on the Common tab), the component will
check for successful or failed challenges and completed orders ready to collect
the certificate, and complete them.

The 'List Orders' button will generate a list in the log of recent CertCentre
orders with their order number and status.  For orders that are completed, the
order number can be entered in the field and 'Collect Order' clicked to collect
the certificate, similarly to Acme.  Likewise, specific orders may be cancelled
within 30 days, and certificates revoked if necessary.

The Supplier Database tab also shows any orders for the account in the database,
and allows them to be Collected, Cancelled or Revoked.


TSslX509Certs Own CA Order Process
----------------------------------

For internal network use and testing, it is possible to create your Own
Certificate Authority and issue your own SSL certificates for devices that are
not accessible from the public internet.  To avoid horrible browser warnings,
your CA certificate needs to be installed as a trusted root on each device that
will access servers running certificates issued by the CA.

The sample application does not currently create self signed SSL certificates,
you need to use the OverbyteIcsPemTool sample instead.  You should create a new
private key and self signed certificate with your organisation's common name,
ie Magenta Development CA.  Rather than signing certificates directly with the
new trusted CA, it is better create an intermediate CA signed by the trusted CA,
allowing variations of key types and digests, ie Magenta Intermediate EC CA1.
The intermediate CA certificate does not need to be installed on client devices,
only the trusted CA.

On the Own CA tab, the Certificate Directory should be specified, note the
account database for Own CA certificates currently does not store certificate
details so they can not be ordered automatically by TWSocketServer. Then specify
the CA Certificate or Bundle File and CA Private Key File (if not in bundle) and
click the 'Load CA'  button check and load it, with Issued to and Issued by
being shown.

To issue your own signed SSL certificates, the usual settings on the Domain and
Cert Admin tabs should be completed, and the 'CA Signed Cert' button pressed.
The component will then create a new private key and CSR files, then a new
certificate signed by the Own CA, in a process otherwise identical to collecting
an ACME certificate, using a sequential order number, with files saved with and
without the order number and optionally distributed to the web server.  Note
this sample sets common certificate extensions only, for more control you
should create your own CSR using OverbyteIcsPemTool or it's functions.

Each certificate signed by the Own CA is logged to the index.txt database file
in the Certificate Directory, in OpenSSL CA command format, which is tab
delimited with status, expiry date, SHA1 fingerprint, file name, subject and
subject alternate names. This file could be updated if the certificate is
revoked and used to support Certificate Revocation Lists (not implemented).


TSslX509Certs Supplier Database
-------------------------------

As mention above, each Supplier Directory includes an Account Database, and
the Supplier Database tab has options to view Supplier Certificate Orders, and
perform most of functions previously discussed on those orders.

First select a Supplier Database from the drop down box, or a new one either by
typing a path or clicking the square path box to select a Database Directory
using a dialog window.  Click the 'Open Supplier' button, the database will be
opened, the supplier details shown in the yellow box and the Supplier Certificate
Orders list populated with the principal order details, clicking any line will
show extra details in the yellow box.  Certain buttons will be enabled or
disabled depending on each Issue State.

Buttons available are: Check Order, Order Certificate, Collect Certificate,
Redistribute (copy to web server again), Cancel Order (without revoke), Revoke
Certificate and Remove Order (removed from database only), most of which have
been described for the order process earlier.

Revoke an order should generally only be done if the certificate is in public
use and the private key has been compromised.  Revoke means the certificate will
be added to supplier CRL and OCSP databases which are checked by browsers to
prevent compromised certificates being trusted until expiry.

The TSslX509Certs component provides several functions for dealing with accounts
and the database, which relate closely to the buttons on the Supplier Database
tab.  These functions are used by the TSslWSocketServer method OrderCert.


function OpenAccount(const WorkDir: String; CreateNew: Boolean = False): Boolean;

Opens the supplier account in the specified directory, optionally creating a new
account if the directory does not exist or is empty.  For a new account, several
properties are needed: DebugLevel, DomWebSrvIP, LogJson, LogPkeys, SupplierEmail,
SupplierProto, SupplierServer and SupplierTitle. SupplierEmail and SupplierProto
as SuppProtoAcmeV2 and SuppProtoCertCentre and SupplierServer from
GetServerAPIUrl are required, others are optional.  For SuppProtoCertCentre
several more OAuth2 properties for the CertCentre AG account are needed: OAAppUrl,
OAClientId. OAClientSecret, OARedirectUrl, OARefrMinsPrior, OAScope, OATokenUrl,
OAWebSrvIP and OAWebSrvPort, see sample application for more info.

Once the account is opened, the property DomainItems returns an array of
TDomainItems containing the main details of each domain record in the database,
and an event is triggered whenever this changes.

The function will fail if ics-control.db can not be found or the working
directory mismatches the database.


function CloseAccount: Boolean;

Close the account, if open.


function CertReadDomain(const aDomain: String): Boolean;

For an open account, reads all the properties for an X509 SSL certificate with
the Common Name from the database, if found, including one or more subject
alternate names.

The function will fail if the domain has not been saved in the database.


function CertSaveDomain(const aDomain: String): Boolean;

Save or update properties for an X509 SSL certificate with the Common Name to
the database.  There are many possible properties, depending on the type of
certificate being ordered, the supplier, challenge type, etc, all of which are
illustrated in the sample application.  The main properties are: CertCommonName,
SuppCertChallenge as TChallengeType supports ChallFileUNC, ChallFileFtp,
ChallFileSrv, ChallDNS, ChallEmail, ChallAlpnUNC, ChallAlpnSrv, ChallManual,
CertPKeyType as type TSslPrivKeyType typically PrivKeyRsa2048, CertSignDigest as
type TEvpDigest typically Digest_sha256, CertCsrOrigin usually CsrOriginProps,
CertSerNumType usually SerNumRandom, CertOutFmts usually set [OutFmtBudl,
OutFmtP12], DirWellKnown if ChallFileUNC, DirPubWebCert as a path,
PrivKeyPassword, PrivKeyCipher usually PrivKeyEncTripleDES, CertSubAltNames as
multiple subject alternate names if supported by the certificate, CertValidity
in days (usually 365 or 730), SuppCertProduct.

For SuppProtoCertCentre contact and address details are required: CertAddress,
CertContactEmail, CertContactFirst, CertContactLast, CertContactTitle,
CertCountry, CertLocality, CertOrgUnit, CertOrganization, CertPhone,
CertPostCode, CertState.  For commercial certificates, the sample application
provides ProductCA, ProductCertType, ProductDVAuth, ProductFeatures,
ProductMaxSan and ProductQuote, and will show the price of the certificate
with a warning before the product is saved, but once in the database it can
be ordered automatically if the CertCentre AG account has sufficient credit.
CertApprovEmail for email challenge.

Fails if account not opened, if CertCommonName does not match aDomain, if
SupplierProto is not set, or CertSubAltNames is empty.  But otherwise does
not check properties for validity.


function CertCheckDomain(const aDomain: String): Boolean;

For an open account, reads all the properties for an X509 SSL certificate with
the Common Name from the database, if found, including one or more subject
alternate names. If CertCsrOrigin is CsrOriginCSR, the Common Name and SANs
are read from an old CSR file at CertOldCsrFile and the key file from
CertOldPrvKey.  It then checks the Common Name is included in the SANs and adds
it if not, then checks the challenge method and SAN number are supported by
the certificate product. Finally for domain file validation, the component copies
a file to the server Well-Known directory and checks it can be accessed using
each of the SANs domain names.  Any changes are saved to the database.


function CertOrderDomain(const aDomain: String): Boolean;

First calls CertCheckDomain, if that passes continues to place the SSL
certificate order with the supplier, whose processes vary as described in
the ACME and CertCentre AG order processes earlier.  Collection will be
automatic once the challenges succeed.


function CertCollectDomain(const aDomain: String): Boolean;

For an order with issue state challenge pending, checks if all the challenges
have been completed successfully and then collects the order.


function CertCancelDomain(const aDomain: String): Boolean;

For an order with issue state Collected or Installed, will cancel the order
with the supplier, which may result in a refund if done within a reasonable
period.


function CertRevokeDomain(const aDomain: String): Boolean;

For an order with issue state Collected or Installed, will cancel and revoke the
order with the supplier.


function CertRemoveDomain(const aDomain: String): Boolean;

Removes any order from the database, to stop further processing or re-use.


function CertRedistDomain(const aDomain: String): Boolean;

For an order with issue state Collected or Installed, copies the certificate
files to the web server again, if lost.



----------------------------------------------------------------

Updates:
May 22, 2018  - V8.54 - baseline
July 03, 2018 - V8.55 - don't load LoadCATrust in Create, it loads OpenSSL in IDE.
Oct 2, 2018   - V8.57 - Added database for domains and challenges (INI file).
                        Added challenges for local web server, FTP and DNS server.
                        Order AcmeV2 certificates with multiple SANs or wildcard.
                        Order CertCentre orders with multiple SANs.
                        Automatic order completion when challenge completed.
                        Added own CA to issue local certificates.
                        Use own CSR and PKey instead of creating them new.
                        Builds with FMX but not tested.
Nov 2, 2018   - V8.58 - Bug fixes and more documentation.
                        Descend components from TIcsWndControl not TComponent
Feb 6, 2019   - V8.60   Added SocketFamily property to allow both IPv4 and IPv6.
Apr 16, 2017  - V8.61   Certificate dates are in UTC not local time.
Aug 07, 2019  - V8.62   TDomainItem adds DDirWellKnown and DDirPubWebCert
                        Added literals for various types to assist apps.
                        Removed Acme V1 protocol support (withdrawn from Nov 2019)
                        AcmeV2 now supports POST-as-GET per RFC8555 for the final
                          ACME specification, GET alone being removed later in 2019.
                        Added Proxy URL support, might be needed for servers behind
                          NAT firewalls for public access.
                       CertCenter AlwaysOn is discontinued and removed.
                       Comodo is now called Sectigo, sometimes old name still used.
                       Moved BuildCertName to OverbyteIcsWSocketS.
                       Check can create certificate directories before order starts.
                       Added ChallFileApp and ChallAlpnApp which mean SocketServer
                         checks the challenge database in this unit using an event
                         rather than writing files.
                       Support tls-alpn-01 challenge for local web server on 443.
                       BEWARE tls-alpn-01 challenge not working yet, wrong certificate
                         is sent to client.
                       Builds without USE_SSL
Nov 12, 2019 - V8.63 - OpenAccount will now create a new account correctly.
                       Better response for CertOrderDomain if order collected.
                       Changed challenge checking from every 30 seconds to 10 seconds
                         after a challenge started for faster completion.
                       Clear Acme nonce after errors so a fresh nonce is found.
                       Added AutoAccountClose property so account is closed after
                         order is completed or fails and AccountTimeOutMins to
                         close it anyway when idle.  This avoids potential hacking
                         attempts that often follow listing in SSL certificate
                         transparency logs immediately after issue. 
                       Improved local web server and REST logging.
                       Added LastError to try and keep the last real order error.
                       Expire and remove challenges from the databsee after 24 hours
                         or a week for manual/email/dns.
                         


Pending - more documentation
Pending - keep CertCentre admin details as supplier
Pending - Acme EC accounts, signing currently fails validation
Pending - Acme revoke certificate
Pending - CertCentre re-issue certificate, use ModifiedOrders for last x days
Pending - Servertastic APIv2 for commercial certificates
Pending - install PKCS12 certificates into Windows cert store for IIS
Pending - Comodo intermediates have too many certificates including a root
Pending - Add self signed and CA certs to database
Pending - check well-known challenge made to TSslHttpServer
}

{$IFNDEF ICS_INCLUDE_MODE}
unit OverbyteIcsSslX509Certs;
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
    Ics.Fmx.OverbyteIcsWndControl,
    Ics.Fmx.OverbyteIcsWSocket,
    Ics.Fmx.OverbyteIcsWSocketS,
    Ics.Fmx.OverbyteIcsHttpProt,
    Ics.Fmx.OverbyteIcsSslJose,
    Ics.Fmx.OverbyteIcsSslHttpRest,
    Ics.Fmx.OverbyteIcsSslX509Utils,
    Ics.Fmx.OverbyteIcsMsSslUtils,
{$ELSE}
    OverbyteIcsWndControl,
    OverbyteIcsWSocket,
    OverbyteIcsWSocketS,
    OverbyteIcsHttpProt,
    OverbyteIcsSslJose,
    OverbyteIcsSslHttpRest,
    OverbyteIcsSslX509Utils,
    OverbyteIcsMsSslUtils,
{$ENDIF FMX}
    OverbyteIcsTypes,
    OverbyteIcsIniFiles,
    OverbyteIcsUtils,
    OverbyteIcsLogger,     { for TLogOption }
    OverbyteIcsUrl,
    OverbyteIcsMimeUtils,
    OverbyteIcsTicks64, 
    OverbyteIcsSuperObject;

{ NOTE - these components only build with SSL, there is no non-SSL option }

const
    ComponentVersion = 'V8.63';  // used in user agent

 // file suffixes to build various file names
    FileSuffPKey     = '-privatekey.pem' ;
    FileSuffCSR      = '-request.pem' ;
    FileSuffCertPem  = '-certonly.pem' ;
    FileSuffInterPem = '-inters.pem' ;
    FileSuffBundPem  = '-bundle.pem' ;
    FileSuffBundP12  = '.pfx' ;
    FileSuffBundP7   = '.p7' ;
    FileIcsCntlDB    = 'ics-control.db';  // INI file
    FileCADB         = 'index.txt';

 // INI file section headers
    CntlDBAccount   = 'account' ;    // ie, [account]
    CntlDBDomainPre = 'domain-' ;    // ie, [domain-www.magsys.co.uk]
    CntlDBSANPre    = 'san-' ;       // ie, [san-www.magsys.co.uk=www.magsys.uk]
    CntlDBChallenge = 'challenge-' ; // ie, [challenge-www.magsys.co.uk]

    DateMaskPacked = 'yyyymmdd"-"hhnnss' ;

type

 // certficate serial number
    TSerNumType = (SerNumRandom, SerNumSequential);

 // issue state within the component
    TIssueState = (IssStateNone, IssStateAccount, IssStateChecked,
                   IssStateChallgPend, IssStateChallgOK, IssStateCollect,
                   IssStateInstall, IssStateCancel);

 // certificate CSR origin
    TCertCsrOrigin = (CsrOriginProps, CsrOriginFile);

 // certificate output formats
    TCertOutFmt = (OutFmtSep, OutFmtBudl, OutFmtP12, OutFmtP7, OutFmtReq);
    TCertOutFmts = Set of TCertOutFmt;

 // domains information from database, display only
    TDomainItem = record
        DCommonName: String;
        DCertSANs: String;
        DProduct: String;
        DSuppOrderId: String;
        DIssueState: TIssueState;
        DSuppCertChallg: TChallengeType;
        DStartDT: TDateTime;
        DEndDT: TDateTime;
        DDirWellKnown: String;   { V8.62 }
        DDirPubWebCert: String;  { V8.62 }
    end;
    TDomainItems = array of TDomainItem;

 // challenge item for a single domain, a certificate may have several domains
    TChallengeItem = record
        CDomain: String;      // domain being tested, might be CommonName or SAN
        CCommonName: String;  // common name for certificate, might be same as Domain
        CSanIdx: Integer;     // index into SubAltNames
        CSuppOrderId: String;
        CDirWellKnown: String;
        CDirPubWebCert: String;
        CWKFullName: String;    // challenge full file name
        CSupplierProto: TSupplierProto;
        CType: TChallengeType;
        CIssueState: TIssueState;
        CAuthzURL: String;      // Authorisation object URL or DNS Pointer (TXT or CNAME)
        ChallengeURL: String;  // challenge URL
        ChallgToken: String;   // random token from supplier
        CPage: String;         // .well-known/page URL for challenge or domain for DNS
        CResp: String;         // page token content for challenge
        CDNSValue: String;     // DNS record value
        CAcmeAlpnCert: String; // V8.62 full file name for acme-tls/1 challenge SSL certificate
        CStartDT: TDateTime;
        CDoneDT: TDateTime;
        CValidResult: String;   // challenge validation result or error
    end;
    TChallengeItems = array of TChallengeItem;

 // Acme URLs for specific commands
    AcmeActionDir = record
        Action: string ;
        URL: string ;
    end;

    TChallengeEvent = procedure (Sender: TObject; ChallengeItem: TChallengeItem) of object;

(*
{ Acme V2
  "Qa5SoBHy3FM": "https://community.letsencrypt.org/t/adding-random-entries-to-the-directory/33417",
  "keyChange": "https://acme-staging-v02.api.letsencrypt.org/acme/key-change",
  "meta": {
    "termsOfService": "https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf"
  },
  "newAccount": "https://acme-staging-v02.api.letsencrypt.org/acme/new-acct",
  "newNonce": "https://acme-staging-v02.api.letsencrypt.org/acme/new-nonce",
  "newOrder": "https://acme-staging-v02.api.letsencrypt.org/acme/new-order",
  "revokeCert": "https://acme-staging-v02.api.letsencrypt.org/acme/revoke-cert"
}
 *)

const
    SupplierProtoLits: array[TSupplierProto] of String =
        ('None', 'Own CA', 'AcmeV2', 'CertCentre', 'Servertastic');

    ChallengeTypeLits: array[TChallengeType] of String =
        ('None', 'File - Web Server - UNC', 'File - Web Server - FTP',
        'File - Local Web Server', 'File - App Web Server', 'Domain Name Server',
        'Email manually', 'TLS-ALPN Cert - Web UNC', 'TLS-ALPN Cert - Local Web',
        'TLS-ALPN Cert - App Web', 'Manual');

    IssueStateLits: array[TIssueState] of String =
         ('None', 'Ready', 'Checked', 'Challg Pend', 'Challg OK',
          'Collected', 'Installed', 'Cancelled');

    AcmeResNewNonce2 = 'newNonce';     // V2 only
    AcmeResNewAccount2 = 'newAccount'; // V2
    AcmeResNewOrder2 = 'newOrder';     // V2 aka new-cert
    AcmeResRevokeCert2 = 'revokecert'; // V2
    AcmeResKeyChange2 = 'keychange';   // V2
    AcmeResNewAuthz2 = 'newauthz';     // V2 not implemented by Boulder

 // Acme Actions
    AcmeNewNonce2 = 1;
    AcmeNewAccount2 = 2;
    AcmeNewOrder2 = 3;
    AcmeRevokeCert2 = 4;
    AcmeKeyChange2 = 5;
    AcmeNewAuthz2 =  6;

    AcmeActionTot = 6 ;

const
    LetsEncryptCrossInterLines =
        '# Common Name (CN): Let''s Encrypt Authority X3' + #13#10 +
        '# Organisation (O): Let''s Encrypt' + #13#10 +
        '# ISSUED BY' + #13#10 +
        '# Common Name (CN): DST Root CA X3' + #13#10 +
        '# Organisation (O): Digital Signature Trust Co.' + #13#10 +
        '# Serial Number: 0a0141420000015385736a0b85eca708' + #13#10 +
        '# Issued on: 17/03/2016' + #13#10 +
        '# Expires on: 17/03/2021' + #13#10 +
        '# Fingerprint (sha1): e6a3b45b062d509b3382282d196efe97d5956ccb' + #13#10 +
        '# Key Info: RSA Key Encryption 2048 bits, 112 security bits' + #13#10 +
        '-----BEGIN CERTIFICATE-----' + #13#10 +
        'MIIEkjCCA3qgAwIBAgIQCgFBQgAAAVOFc2oLheynCDANBgkqhkiG9w0BAQsFADA/' + #13#10 +
        'MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT' + #13#10 +
        'DkRTVCBSb290IENBIFgzMB4XDTE2MDMxNzE2NDA0NloXDTIxMDMxNzE2NDA0Nlow' + #13#10 +
        'SjELMAkGA1UEBhMCVVMxFjAUBgNVBAoTDUxldCdzIEVuY3J5cHQxIzAhBgNVBAMT' + #13#10 +
        'GkxldCdzIEVuY3J5cHQgQXV0aG9yaXR5IFgzMIIBIjANBgkqhkiG9w0BAQEFAAOC' + #13#10 +
        'AQ8AMIIBCgKCAQEAnNMM8FrlLke3cl03g7NoYzDq1zUmGSXhvb418XCSL7e4S0EF' + #13#10 +
        'q6meNQhY7LEqxGiHC6PjdeTm86dicbp5gWAf15Gan/PQeGdxyGkOlZHP/uaZ6WA8' + #13#10 +
        'SMx+yk13EiSdRxta67nsHjcAHJyse6cF6s5K671B5TaYucv9bTyWaN8jKkKQDIZ0' + #13#10 +
        'Z8h/pZq4UmEUEz9l6YKHy9v6Dlb2honzhT+Xhq+w3Brvaw2VFn3EK6BlspkENnWA' + #13#10 +
        'a6xK8xuQSXgvopZPKiAlKQTGdMDQMc2PMTiVFrqoM7hD8bEfwzB/onkxEz0tNvjj' + #13#10 +
        '/PIzark5McWvxI0NHWQWM6r6hCm21AvA2H3DkwIDAQABo4IBfTCCAXkwEgYDVR0T' + #13#10 +
        'AQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8EBAMCAYYwfwYIKwYBBQUHAQEEczBxMDIG' + #13#10 +
        'CCsGAQUFBzABhiZodHRwOi8vaXNyZy50cnVzdGlkLm9jc3AuaWRlbnRydXN0LmNv' + #13#10 +
        'bTA7BggrBgEFBQcwAoYvaHR0cDovL2FwcHMuaWRlbnRydXN0LmNvbS9yb290cy9k' + #13#10 +
        'c3Ryb290Y2F4My5wN2MwHwYDVR0jBBgwFoAUxKexpHsscfrb4UuQdf/EFWCFiRAw' + #13#10 +
        'VAYDVR0gBE0wSzAIBgZngQwBAgEwPwYLKwYBBAGC3xMBAQEwMDAuBggrBgEFBQcC' + #13#10 +
        'ARYiaHR0cDovL2Nwcy5yb290LXgxLmxldHNlbmNyeXB0Lm9yZzA8BgNVHR8ENTAz' + #13#10 +
        'MDGgL6AthitodHRwOi8vY3JsLmlkZW50cnVzdC5jb20vRFNUUk9PVENBWDNDUkwu' + #13#10 +
        'Y3JsMB0GA1UdDgQWBBSoSmpjBH3duubRObemRWXv86jsoTANBgkqhkiG9w0BAQsF' + #13#10 +
        'AAOCAQEA3TPXEfNjWDjdGBX7CVW+dla5cEilaUcne8IkCJLxWh9KEik3JHRRHGJo' + #13#10 +
        'uM2VcGfl96S8TihRzZvoroed6ti6WqEBmtzw3Wodatg+VyOeph4EYpr/1wXKtx8/' + #13#10 +
        'wApIvJSwtmVi4MFU5aMqrSDE6ea73Mj2tcMyo5jMd6jmeWUHK8so/joWUoHOUgwu' + #13#10 +
        'X4Po1QYz+3dszkDqMp4fklxBwXRsW10KXzPMTZ+sOPAveyxindmjkW8lGy+QsRlG' + #13#10 +
        'PfZ+G6Z6h7mjem0Y+iWlkYcV4PIWL1iwBi8saCbGS5jN2p8M+X+Q7UNKEkROb3N6' + #13#10 +
        'KOqkqm57TH2H3eDJAkSnh6/DNFu0Qg==' + #13#10 +
        '-----END CERTIFICATE-----' + #13#10;

var
    AcmeActionDirs: array [1..AcmeActionTot] of AcmeActionDir = (
      ( Action: AcmeResNewNonce2; URL: ''),
      ( Action: AcmeResNewAccount2; URL: ''),
      ( Action: AcmeResNewOrder2; URL: ''),
      ( Action: AcmeResRevokeCert2; URL: ''),
      ( Action: AcmeResKeyChange2; URL: ''), 
      ( Action: AcmeResNewAuthz2; URL: '') );

type
{ TSubAltName is one subject alternate domain name }
  TSubAltName = class(TCollectionItem)
  private
    SADomain: String;
    SADirWellKnown: String;
    SADirPubWebCert: String;
    SAApprovalEmail: String;
    SAIssueState: TIssueState;
    SAStartDT: TDateTime;
    SADoneDT: TDateTime;
    SAValidResult: String;   // challenge validation result or error
  protected
    function GetDisplayName: string; override;
  published
    constructor Create (Collection: TCollection); Override ;
    property Domain: String                read  SADomain
                                           write SADomain;
    property DirWellKnown: String          read  SADirWellKnown
                                           write SADirWellKnown;
    property DirPubWebCert: String         read  SADirPubWebCert
                                           write SADirPubWebCert;
    property ApprovalEmail: String         read  SAApprovalEmail
                                           write SAApprovalEmail;
  end;

{ TSubAltNames defines a collection of TSubAltName }
  TSubAltNames = class(TCollection)
  private
    FOwner: TPersistent;
    function GetItem(Index: Integer): TSubAltName;
    procedure SetItem(Index: Integer; Value: TSubAltName);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(Owner: TPersistent);
    function IndexOf(const aDomain: String): Integer;
    function AddItem(const aDomain: String; aDirWellKnown: string = '';
            aDirPubWebCert: string = ''; aApprovalEmail: String = ''): Integer;
    property Items[Index: Integer]: TSubAltName     read GetItem
                                                    write SetItem; default;
  end;

TSslX509Certs = class(TIcsWndControl)
  private
    { Private declarations }
// components
    FHttpRest: TSslHttpRest;
    FHttpTest: TSslHttpRest;
    FRestOAuth: TRestOAuth;
    FDomWebServer: TSimpleWebSrv;
    FNewSslCert: TSslCertTools;
    FAcmePrivKey: TSslCertTools;
    FRootCAX509: TX509Base;
    FChallengeTimer: TIcsTimer;

// published properties
    FAcmeAccKeyType: TSslPrivKeyType;
    FCertAddress: String;
    FCertApprovEmail: String;
    FCertSubAltNames: TSubAltNames;
    FCertCommonName: String;
    FCertContactEmail: String;
    FCertContactFirst: String;
    FCertContactLast: String;
    FCertContactPhone: String;
    FCertContactTitle: String;
    FCertCountry: String;
    FCertDescr: String;
    FCertLocality: String;
    FCertOrgUnit: String;
    FCertOrganization: String;
    FCertPostcode: String;
    FCertPhone: String;
    FCertSignDigestType: TEvpDigest;
    FCertState: String;
    FCertValidity: Integer;
    FDebugLevel: THttpDebugLevel;
    FDirCertWork: String;
    FDirPubWebCert: TStringList;  // may be several wildcard servers
    FDirWellKnown: String;
    FDomWebSrvIP: String;
    FLogJson: Boolean;
    FLogPkeys: Boolean;
    FOAAccToken: String;
    FOAAppUrl: String;
    FOAAuthType: TOAuthType;
    FOAClientId: String;
    FOAClientSecret: String;
    FOAExpireDT: TDateTime;
    FOARedirectUrl: String;
    FOARefrMinsPrior: Integer;
    FOARefreshAuto: Boolean;
    FOARefreshToken: String;
    FOAScope: String;
    FOATokenUrl: String;
    FOAWebSrvIP: String;
    FOAWebSrvPort: String;
    FPrivKeyCipher: TSslPrivKeyCipher;
    FPrivKeyPassword: String;
    FPrivKeyType: TSslPrivKeyType;
    FSuppCertChallenge: TChallengeType;
    FSuppCertFeatures: String;
    FSuppCertProduct: String;
    FSuppOrderId: String;
    FSuppOrderRef: String;
    FSupplierProto: TSupplierProto;
    FSupplierServer: String;
    FSupplierEmail: String;
    FOnCertProg: THttpRestProgEvent;
    FOnNewToken: TNotifyEvent;
    FOnNewCert: TNotifyEvent;
    FOnDomainsRefresh: TNotifyEvent;
    FOnSuppDBRefresh: TNotifyEvent;
    FOnChallgRefresh: TNotifyEvent;
    FOnOAuthAuthUrl: TOAuthAuthUrlEvent;
    FonChallengeEmail: TChallengeEvent;
    FonChallengeFTP: TChallengeEvent;
    FonChallengeDNS: TChallengeEvent;
    FonChallengeManual: TChallengeEvent;
    FAutoOrderComplete: Boolean;
    FCAPkeyPw: String;
    FOwnCACertDir: String;
    FCertCsrOrigin: TCertCsrOrigin;
    FCAPkeyFile: String;
    FCACertFile: String;
    FCertOldCsrFile: String;
    FCertOldPrvKey: String;
    FCertOutFmts: TCertOutFmts;
    FSupplierTitle: String;
    FSeqOrderNum: Integer;
    FCertSerNumType: TSerNumType;
    FProxyURL: String;         // following V8.62
    FAutoAccountClose: Boolean;  // following V8.63
    FAccountTimeOutMins: Integer;

// internal vars
    FAcmeHost: String;
    FIssueState: TIssueState;
    FCCLastStatCode: Integer;
    FPartFNameWork: String;
    FPartFNameFinal: String;
    FPartFNameServer: TStringList;
    FPartFNameOrder: String;
    FFileCSR: string;
    FFilePrvKey: string;
    FFileCertPem: string;
    FFileBundPem: string;
    FFileInterPem: string;
    FFileBundP12: String;
    FFileBundP7: String;
    FCSRLines: string;
    FPrvKeyLines: string;
    FNewCertPrefix: string;
    FNewCertLines: string;
    FNewInterLines: string;
    FNewCertP7Lines: string;
    FNewCertCN: string;
    fNewCertSAN: string ;
    FNewCertChainInfo: string;
    FNewCertErrs: string;
    FNewCertEndDT: TDateTime;
    FNewCertStartDT: TDateTime;
    FNewCertValRes: TChainResult;
    FNewOrderNum: Integer;
    FAcmePubFName: string;
    FAcmePrivFName: string;
    FLastErrMsg: String;
    FProductJson: ISuperObject;
    FProductDVAuth: String;
    FProductFeatures: String;
    FProductInfo: String;
    FProductCertType: String;
    FProductCA: String;
    FProductMaxSan: Integer;
    FProductQuote: String;
    FProductList: TStringList;
    FApproverEmails: TStringList;
    FAcmeLastStatus: Integer;
    FAcmeRespNonce: string;
    FAcmeRespLink: String;
    FAcmeRespRequester: String;
    FAcmeRespLocation: String;
    FAcmeRespContLoc: string;
    FAcmeKwkPub: String;
    FAcmeKwkKid: String;
    FAcmeJwsAlg: String;
    FAcmeJoseAlg: TJoseAlg;
    FAcmeAccountNum: String;
    FAcmeAccountUrl: String;
    FAcmeTermsUrl: String;
    FAcmeKwkThumb: String;
    FAcmeCertLines: String;
    FAcmeCertUrl: String;
    FAcmeCertSerial: String;
    FAcmeOrderFinalizeUrl: String;
    FAcmeOrderStatus: String;
    FAcmeOrderExpiresDT: TDateTime;
    FAcmeOrderObjUrl: String;
    FDbIniSections: TStringList;
    FDomainItems: TDomainItems;
    FControlFile: TIcsIniFile;
    FCnrtFileName: String;
    FChallengeItems: TChallengeItems;  // domain blank is unused
    FChallengesTot: Integer;           // used challenges
    FFileFinalCSR: String;
    FFileFinalPrvKey: String;
    FFileFinalBundle: String;
    FFileFinalCert: String;
    FOrderStartDT: TDateTime;
    FChallgStartDT: TDateTime;
    FChallgDoneDT: TDateTime;
    FOrderCertsDT: TDateTime;
    FOrderAttempts: Integer;
    FCertSANs: TStringList;  // matches FCertSubAltNames.Domain
    FCertSANTot: Integer;
    FPendingChallg: Integer;
    FX509BusyFlag: Boolean;
    FPendOpenAccount: String;
    FLastResponse: String;
    FSocketFamily: TSocketFamily;   { V8.60 }
    FFileCertLocalHost: String;     { V8.60 }
    FChkChallgTrg: Int64;           { V8.63 }
    FPendAccountClose: Boolean;     { V8.63 }
    FAccountLastTick: Int64;        { V8.63 }
    FLastError: String;             { V8.63 }
  protected
    { Protected declarations }
    procedure RestProg(Sender: TObject; LogOption: TLogOption; const Msg: string);
    procedure LogTimeStamp;
//    procedure SetError(ErrCode: Integer; const Msg: String);
    procedure WebSrvReq(Sender: TObject; const Host, Path, Params: string; var RespCode, Body: string);
    procedure WebSrvAlpn(Sender: TObject; const Host: string; var CertFName: string);  { V8.62 }
    procedure ChallengeOnTimer(Sender: TObject);
    procedure SetSubAltNames(Value: TSubAltNames);
    procedure OAuthNewToken(Sender: TObject);
    procedure OAuth1OAuthAuthUrl(Sender: TObject; const URL: string);
    procedure SetCertCommonName(const Value: String);
    procedure SetDirWellKnown(const Value: String);
    procedure SetDirPubWebCert(const Value: TStringList);
    procedure SetDirCertWork(const Value: String);
    procedure WebSrvProg(Sender: TObject; LogOption: TLogOption; const Msg: string);  { V8.63 }
  public
    { Public declarations }
    constructor  Create (Aowner: TComponent); override;
    destructor   Destroy; override;
    procedure LogEvent(const Msg: String);                              { V8.63  was protected }
    function  StartDomSrv(const HostName, CertBundle: String): Boolean ;
    function  StopDomSrv: boolean ;
    function  DomSrvIsRunning: Boolean;
    procedure HttpRestRestRequestDone(Sender: TObject;
                              RqType: THttpRequest; ErrCode: Word);
    function GetServerAPIUrl(Supplier: TSupplierProto; TestApi: Boolean = False): String;
    procedure SetOAuth2;
    function OAGrantRefresh: boolean;
    function OAGrantAuthToken(const Code: String): boolean;
    function TestWellKnown(const aDomain, aDirWellKnown: String): Boolean;
    function TestTlsAlpn(const aDomain, aDirWellKnown: String): Boolean;  { V8.62 }
    function SaveDataFile(const FName, Data: String): Boolean;
    procedure SetFullFileNames(const FileDir: String);
    function CreateKeyandReq: boolean;
    procedure DumpJson(const Item: String = '');
    function SetPartFNames (ReadOnly: Boolean = False): Boolean;
    function SaveCertificateFiles(const CertName: string): Boolean;
    function RedistribteFiles: Boolean;
    function SetCertCentre(CreateNew: Boolean = False): boolean;
    function CCGetRequest(HttpReq: THttpRequest;
                const PageURL: String; const RawParams: String = ''): boolean;
    function CCGetProfile: Boolean;
    function CCGetProducts(Log: Boolean = False): boolean;
    function CCGetOneProduct(const Product: String): Boolean;
    function CCGetApproverEmail: Boolean;
    function CCFullfillment (JsonOrder: ISuperObject; const CertName: string): Boolean;
    function CCListAllOrders: Boolean;
    function CCGetCert: Boolean;
    function CCCheckChallg(ChallgNum: Integer): Boolean;
    function CCOrderCert: Boolean;
    function CCCheckOrder(DomainCheck: Boolean = True; UpdateDB: Boolean = False): Boolean;
    function CCCancelOrder(Revoke: Boolean): Boolean;
    function SetAcmeAccount(CreateNew: Boolean = False): boolean;
    function AcmeGetRequest(HttpReq: THttpRequest;
                const FullURL: String; AcmeJson: ISuperObject): boolean;
    function AcmeLoadPKey(New: Boolean): Boolean;
    function AcmeGetActions: Boolean;
    function AcmeCheckOrder(DomainCheck: Boolean = True; UpdateDB: Boolean = False): Boolean;
    function AcmeV2NewAccount: Boolean;
    function AcmeV2OrderCert: Boolean;
    function AcmeV2GetCert: Boolean;
    function AcmeV2CheckChallg(ChallgNum: Integer): Boolean;
    function AcmeV2OrderCancel (Revoke: Boolean): Boolean;
    function CheckChallg(const aDomain: String): Boolean;
    procedure RemoveChallgs(const CNDomain: String);
    function DBOpenINI(const WorkDir: String; CreateNew: Boolean = False): Boolean;
    function DBReadCNDomain(const CNDomain: String; UseStoredProps: Boolean): Boolean;
    function DBWriteCNDomain: Boolean;
    function DBDeleteCNDomain(const CNDomain: String): Boolean;
    function DBReadAccount(const WorkDir: String; UseStoredProps: Boolean): Boolean;
    function DBWriteAccount: Boolean;
    function DBNewOrderNum: Integer;
    function DBFindSAN(const adomain: String): Integer;
    function DBWriteOneChallenge (Item: TChallengeItem): Integer;
    function DBReadChallenges: Boolean;
    function DBFindDomain(const CNDomain: String): Integer;
    function DBReadSections: Boolean;
    function DBAddChallenge(Item: TChallengeItem): Integer;
    function DBRemoveChallenge(ChallgNum: Integer): Boolean;
    function DBFindChallengeNum (const Domain: String): Integer;
    function DBFreeChallengeNum: Integer;
    function DBDeleteChallenge (const Domain: String): Boolean;
    function OpenAccount(const WorkDir: String; CreateNew: Boolean = False): Boolean;
    function CloseAccount: Boolean;
    procedure BuildSANList;
    function CertReadDomain(const aDomain: String): Boolean;
    function CertSaveDomain(const aDomain: String): Boolean;
    function CertCheckDomain(const aDomain: String): Boolean;
    function CertOrderDomain(const aDomain: String): Boolean;
    function CertCollectDomain(const aDomain: String): Boolean;
    function CertCancelDomain(const aDomain: String): Boolean;
    function CertRevokeDomain(const aDomain: String): Boolean;
    function CertRemoveDomain(const aDomain: String): Boolean;
    function CertRedistDomain(const aDomain: String): Boolean;
    function LoadOwnCA: Boolean;
    function OwnCASign: Boolean;
    function SelfSign: Boolean;
    function CheckCSR(RequirePkey: Boolean = True): Boolean;
    function GetOrderResult: String;
    function CreateAcmeAlpnCert(const FileName, CName, KeyAuth: String): Boolean;  { V8.62 }

    property ProductJson: ISuperObject              read FProductJson;
    property ProductDVAuth: String                  read FProductDVAuth;
    property ProductFeatures: String                read FProductFeatures;
    property ProductInfo: String                    read FProductInfo;
    property ProductList: TStringList               read FProductList;
    property ProductQuote: String                   read FProductQuote;
    property ApproverEmails: TStringList            read FApproverEmails;
    property NewSslCert: TSslCertTools              read FNewSslCert;
    property IssueState: TIssueState                read FIssueState;
    property NewCertPrefix: string                  read FNewCertPrefix;
    property NewCertLines: string                   read FNewCertLines;
    property NewInterLines: string                  read FNewInterLines;
    property NewCertP7Lines: string                 read FNewCertP7Lines;
    property NewCertCN: string                      read FNewCertCN;
    property NewCertSAN: string                     read FNewCertSAN;
    property NewCertChainInfo: string               read FNewCertChainInfo;
    property NewCertErrs: string                    read FNewCertErrs;
    property NewCertEndDT: TDateTime                read FNewCertEndDT;
    property NewCertStartDT: TDateTime              read FNewCertStartDT;
    property NewCertValRes: TChainResult            read FNewCertValRes;
    property NewOrderNum: Integer                   read FNewOrderNum;
    property DomainItems: TDomainItems              read FDomainItems;
    property ChallengeItems: TChallengeItems        read FChallengeItems;
    property ChallengesTot: Integer                 read FChallengesTot;
    property CertSANs: TStringList                  read FCertSANs;  // matches FCertSubAltNames.Domain
    property LastResponse: String                   read FLastResponse;
    property FileBundPem: String                    read FFileBundPem;      { V8.62 }
    property FileBundP12: String                    read FFileBundP12;      { V8.62 }
    property FileFinalPrvKey: String                read FFileFinalPrvKey;  { V8.62 }
    property LastError: String                      read FLastError;        { V8.63 }
  published
    { Published declarations }
    property AcmeAccKeyType: TSslPrivKeyType        read  FAcmeAccKeyType
                                                    write FAcmeAccKeyType;
    property AutoOrderComplete: Boolean             read  FAutoOrderComplete
                                                    write FAutoOrderComplete;
    property CAPkeyFile: String                     read  FCAPkeyFile
                                                    write FCAPkeyFile;
    property CAPkeyPw: String                       read  FCAPkeyPw
                                                    write FCAPkeyPw;
    property CACertFile: String                     read  FCACertFile
                                                    write FCACertFile;
    property CertAddress: String                    read  FCertAddress
                                                    write FCertAddress;
    property CertSubAltNames: TSubAltNames          read  FCertSubAltNames
                                                    write SetSubAltNames;
    property CertApprovEmail: String                read  FCertApprovEmail
                                                    write FCertApprovEmail;
    property CertCommonName: String                 read  FCertCommonName
                                                    write SetCertCommonName;
    property CertContactEmail: String               read  FCertContactEmail
                                                    write FCertContactEmail;
    property CertContactFirst: String               read  FCertContactFirst
                                                    write FCertContactFirst;
    property CertContactLast: String                read  FCertContactLast
                                                    write FCertContactLast;
    property CertContactPhone: String               read  FCertContactPhone
                                                    write FCertContactPhone;
    property CertContactTitle: String               read  FCertContactTitle
                                                    write FCertContactTitle;
    property CertCountry: String                    read  FCertCountry
                                                    write FCertCountry;
    property CertCsrOrigin: TCertCsrOrigin          read  FCertCsrOrigin
                                                    write FCertCsrOrigin;
    property CertDescr: String                      read  FCertDescr
                                                    write FCertDescr;
    property CertLocality: String                   read  FCertLocality
                                                    write FCertLocality;
    property CertOldCsrFile: String                 read  FCertOldCsrFile
                                                    write FCertOldCsrFile;
    property CertOldPrvKey: String                  read  FCertOldPrvKey
                                                    write FCertOldPrvKey;
    property CertOrgUnit: String                    read  FCertOrgUnit
                                                    write FCertOrgUnit;
    property CertOrganization: String               read  FCertOrganization
                                                    write FCertOrganization;
    property CertOutFmts: TCertOutFmts              read  FCertOutFmts
                                                    write FCertOutFmts;
    property CertPhone: String                      read  FCertPhone
                                                    write FCertPhone;
    property CertPostCode: String                   read  FCertPostCode
                                                    write FCertPostCode;
    property CertSerNumType: TSerNumType            read  FCertSerNumType
                                                    write FCertSerNumType;
    property CertSignDigestType: TEvpDigest         read  FCertSignDigestType
                                                    write FCertSignDigestType;
    property CertState: String                      read  FCertState
                                                    write FCertState;
    property CertValidity: Integer                  read  FCertValidity
                                                    write FCertValidity;
    property DebugLevel: THttpDebugLevel            read  FDebugLevel
                                                    write FDebugLevel;
    property DirCertWork: String                    read  FDirCertWork
                                                    write SetDirCertWork;
    property DirPubWebCert: TStringList             read  FDirPubWebCert
                                                    write SetDirPubWebCert;
    property DirWellKnown: String                   read  FDirWellKnown
                                                    write SetDirWellKnown;
    property DomWebSrvIP: String                    read  FDomWebSrvIP
                                                    write FDomWebSrvIP;
    property LogJson: Boolean                       read  FLogJson
                                                    write FLogJson;
    property LogPkeys: Boolean                      read  FLogPkeys
                                                    write FLogPkeys;
    property OAAppUrl: string                       read  FOAAppUrl
                                                    write FOAAppUrl;
    property OAClientId: string                     read  FOAClientId
                                                    write FOAClientId;
    property OAAccToken: String                     read  FOAAccToken
                                                    write FOAAccToken;
    property OAAuthType: TOAuthType                 read  FOAAuthType
                                                    write FOAAuthType;
    property OAExpireDT: TDateTime                  read  FOAExpireDT
                                                    write FOAExpireDT;
    property OAClientSecret: string                 read  FOAClientSecret
                                                    write FOAClientSecret;
    property OARedirectUrl: string                  read  FOARedirectUrl
                                                    write FOARedirectUrl;
    property OARefreshAuto: Boolean                 read  FOARefreshAuto
                                                    write FOARefreshAuto;
    property OARefrMinsPrior: Integer               read  FOARefrMinsPrior
                                                    write FOARefrMinsPrior;
    property OARefreshToken: string                 read  FOARefreshToken
                                                    write FOARefreshToken;
    property OAScope: string                        read  FOAScope
                                                    write FOAScope;
    property OATokenUrl: string                     read  FOATokenUrl
                                                    write FOATokenUrl;
    property OAWebSrvIP: string                     read  FOAWebSrvIP
                                                    write FOAWebSrvIP;
    property OAWebSrvPort: string                   read  FOAWebSrvPort
                                                    write FOAWebSrvPort;
    property OwnCACertDir: String                   read  FOwnCACertDir
                                                    write FOwnCACertDir;
    property PrivKeyCipher: TSslPrivKeyCipher       read  FPrivKeyCipher
                                                    write FPrivKeyCipher;
    property PrivKeyPassword: string                read  FPrivKeyPassword
                                                    write FPrivKeyPassword;
    property PrivKeyType: TSslPrivKeyType           read  FPrivKeyType
                                                    write FPrivKeyType;
    property ProxyURL: String                       read  FProxyURL       { V8.62 }
                                                    write FProxyURL;
    property AutoAccountClose: Boolean              read  FAutoAccountClose     { V8.63 }
                                                    write FAutoAccountClose;
    property AccountTimeOutMins: Integer            read  FAccountTimeOutMins  { V8.63 }
                                                    write FAccountTimeOutMins;
    property SeqOrderNum: Integer                   read  FSeqOrderNum
                                                    write FSeqOrderNum;
    property SocketFamily: TSocketFamily            read  FSocketFamily
                                                    write FSocketFamily;   { V8.60 }
    property SuppCertChallenge: TChallengeType      read  FSuppCertChallenge
                                                    write FSuppCertChallenge;
    property SuppCertFeatures: String               read  FSuppCertFeatures
                                                    write FSuppCertFeatures;
    property SuppOrderId: String                    read  FSuppOrderId
                                                    write FSuppOrderId;
    property SuppOrderRef: String                   read  FSuppOrderRef
                                                    write FSuppOrderRef;
    property SuppCertProduct: String                read  FSuppCertProduct
                                                    write FSuppCertProduct;
    property SupplierEmail: String                  read  FSupplierEmail
                                                    write FSupplierEmail;
    property SupplierProto: TSupplierProto          read  FSupplierProto
                                                    write FSupplierProto;
    property SupplierServer: String                 read  FSupplierServer
                                                    write FSupplierServer;
    property SupplierTitle: String                  read  FSupplierTitle
                                                    write FSupplierTitle;
    property OnCertProg: THttpRestProgEvent         read  FOnCertProg
                                                    write FOnCertProg;
    property OnNewCert: TNotifyEvent                read  FOnNewCert
                                                    write FOnNewCert;
    property OnNewToken: TNotifyEvent               read  FOnNewToken
                                                    write FOnNewToken;
    property OnOAuthAuthUrl: TOAuthAuthUrlEvent     read  FOnOAuthAuthUrl
                                                    write FOnOAuthAuthUrl;
    property OnDomainsRefresh: TNotifyEvent         read  FOnDomainsRefresh
                                                    write FOnDomainsRefresh;
    property OnSuppDBRefresh: TNotifyEvent          read  FOnSuppDBRefresh
                                                    write FOnSuppDBRefresh;
    property OnChallgRefresh: TNotifyEvent          read  FOnChallgRefresh
                                                    write FOnChallgRefresh;
    property OnChallengeEmail: TChallengeEvent      read  FOnChallengeEmail
                                                    write FOnChallengeEmail;
    property OnChallengeFTP: TChallengeEvent        read  FOnChallengeFTP
                                                    write FOnChallengeFTP;
    property OnChallengeDNS: TChallengeEvent        read  FOnChallengeDNS
                                                    write FOnChallengeDNS;
    property OnChallengeManual: TChallengeEvent     read  FOnChallengeManual
                                                    write FOnChallengeManual;
   end;

{$ENDIF USE_SSL}

implementation

{$IFDEF USE_SSL}

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ TSubAltName }
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TSubAltName.Create(Collection: TCollection);
begin
    inherited;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSubAltName.GetDisplayName: string;
begin
   Result := Inherited GetDisplayName
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ TSubAltNames }
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TSubAltNames.Create(Owner: TPersistent);
begin
  FOwner := Owner;
  inherited Create(TSubAltName);
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSubAltNames.GetItem(Index: Integer): TSubAltName;
begin
  Result := TSubAltName(inherited GetItem(Index));
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSubAltNames.SetItem(Index: Integer; Value: TSubAltName);
begin
  inherited SetItem(Index, TCollectionItem(Value));
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSubAltNames.GetOwner: TPersistent;
begin
  Result := FOwner;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSubAltNames.IndexOf(const aDomain: string): Integer;
var
    I: Integer;
begin
    Result := -1;
    if Count = 0 then Exit;
    for I := 0 to Count - 1 do begin
        if Items[I].Domain = aDomain then begin
            Result := I;
            Exit;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSubAltNames.AddItem(const aDomain: String; aDirWellKnown: string = '';
               aDirPubWebCert: string = ''; aApprovalEmail: String = ''): Integer;
begin
    Result := -1;
    if Trim(aDomain) = '' then Exit;
    Result := IndexOf(aDomain);
    if Result < 0 then begin
        Result := Count;
        Add;
    end;
    Items[Result].SADomain := IcsLowercase(Trim(aDomain));
    if aDirWellKnown <> '' then
        Items[Result].SADirWellKnown := IncludeTrailingPathDelimiter(Trim(aDirWellKnown))
    else
        Items[Result].SADirWellKnown := '';
    if aDirPubWebCert <> '' then
        Items[Result].SADirPubWebCert := IncludeTrailingPathDelimiter(Trim(aDirPubWebCert))
    else
        Items[Result].SADirPubWebCert := '';
    Items[Result].SAApprovalEmail := aApprovalEmail;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ TSslX509Certs }
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TSslX509Certs.Create (Aowner: TComponent);
begin
    inherited Create(AOwner);
    FDomWebServer := TSimpleWebSrv.Create(self);
    FDomWebServer.OnServerProg := WebSrvProg;      { V8.63 } 
    FDomWebServer.OnSimpWebSrvReq := WebSrvReq;
    FDomWebServer.OnSimpWebSrvAlpn := WebSrvAlpn;  { V8.62 }
    FHttpRest := TSslHttpRest.Create(self);   // REST requests
    FHttpRest.OnHttpRestProg := RestProg;
    FHttpTest := TSslHttpRest.Create(self);   // test .well-known requests
    FHttpTest.OnHttpRestProg := RestProg;
    FRestOAuth := TRestOAuth.Create(self);
    FRestOAuth.OnOAuthProg := RestProg;
    FRestOAuth.OnOAuthNewToken := OAuthNewToken;
    FRestOAuth.OnOAuthAuthUrl := OAuth1OAuthAuthUrl;
    FDomWebSrvIP := '0.0.0.0';
    FOAWebSrvIP := '127.0.0.1';
    FOAWebSrvPort := '8080';
    FDebugLevel := DebugConn;
    FAcmeAccKeyType := PrivKeyRsa2048;
    FSupplierProto := SuppProtoNone;
    FPrivKeyType := PrivKeyRsa2048;
    FCertSignDigestType := Digest_sha256;
    FCertValidity := 365; // days
    FRestOAuth.ProtoType := OAuthv2;
    FOAAuthType := OAuthTypeWeb;
    FOARefrMinsPrior := 120;
    FPrivKeyCipher := PrivKeyEncNone;
    FChallengeTimer := TIcsTimer.Create(FHttpRest);
    FChallengeTimer.OnTimer := ChallengeOnTimer;
    FChallengeTimer.Interval := 5 * TicksPerSecond;  { V8.63 was 30 }
    FChkChallgTrg := Trigger64Immediate;             { V8.63 }
    FChallengeTimer.Enabled := False;
    FNewSslCert := TSslCertTools.Create(self) ;
    FAcmePrivKey := TSslCertTools.Create(self);
    FDirPubWebCert := TStringList.Create;
    FProductList := TStringList.Create;
    FApproverEmails := TStringList.Create;
    FIssueState := IssStateNone;
    FCertSubAltNames := TSubAltNames.Create(self);
    FCertSANs := TStringList.Create;  // matches FCertSubAltNames.Domain
    FDBIniSections := TStringList.Create;
    FPartFNameServer := TStringList.Create;
    FSocketFamily := sfAny;         // V8.60 allow IPv6
    FAccountTimeOutMins := 10;      // V8.63
    Randomize;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
destructor TSslX509Certs.Destroy;
begin
    FChallengeTimer.Enabled := False;
    StopDomSrv;
    FreeAndNil(FChallengeTimer);
    FreeAndNil(FHttpTest);
    FreeAndNil(FHttpRest);
    FreeAndNil(FDomWebServer);
    FreeAndNil(FRestOAuth);
    FreeAndNil(FNewSslCert);
    FreeAndNil(FAcmePrivKey);
    FreeAndNil(FRootCAX509);
    FreeAndNil(FDirPubWebCert);
    FreeAndNil(FProductList);
    FreeAndNil(FApproverEmails);
    FreeAndNil(FControlFile);
    FreeAndNil(FCertSubAltNames);
    FreeAndNil(FDBIniSections);
    FreeAndNil(FCertSANs);
    FreeAndNil(FPartFNameServer);
    inherited Destroy;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslX509Certs.SetSubAltNames(Value: TSubAltNames);
begin
    FCertSubAltNames.Assign(Value);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslX509Certs.SetCertCommonName(const Value: String);
begin
    if FCertCommonName <> Value then
        FCertCommonName := IcsLowercase(Trim(Value));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslX509Certs.SetDirWellKnown(const Value: String);
begin
    if FDirWellKnown <> Value then begin
        if Value = '' then
            FDirWellKnown := ''
        else
            FDirWellKnown := IncludeTrailingPathDelimiter(Trim(Value));
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslX509Certs.SetDirPubWebCert(const Value: TStringList);
var
    I: Integer;
begin
    if FDirPubWebCert.Text <> Value.Text then begin
        FDirPubWebCert.Clear;
        if Value.Count > 0 then begin
            for I := 0 to Value.Count - 1 do begin
                if Trim(Value[I]) <> '' then
                    FDirPubWebCert.Add(IncludeTrailingPathDelimiter(Trim(Value[I])));
            end;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslX509Certs.SetDirCertWork(const Value: String);
begin
    if FDirCertWork <> Value then begin
        if Value = '' then
            FDirCertWork := ''
        else
            FDirCertWork := IncludeTrailingPathDelimiter(Trim(Value));
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslX509Certs.RestProg(Sender: TObject; LogOption: TLogOption; const Msg: string);
begin
    if Assigned(FOnCertProg) then
        FOnCertProg(Self, LogOption, 'HTTP REST ' + Msg);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslX509Certs.WebSrvProg(Sender: TObject; LogOption: TLogOption; const Msg: string);
begin
    if Assigned(FOnCertProg) then
        FOnCertProg(Self, LogOption, 'Challenge Web Server ' + Msg);    { V8.63 }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslX509Certs.LogEvent(const Msg : String);
begin
    FLastResponse := Msg;
    if FDebugLevel = DebugNone then Exit;
    if Assigned(FOnCertProg) then begin
            FOnCertProg(Self, loProtSpecInfo, Msg);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslX509Certs.LogTimeStamp;
begin
    LogEvent(RFC3339_DateToStr(Now));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.StartDomSrv(const HostName, CertBundle: String): Boolean ;
begin
//    if (FDomWebServer.WebSrvHostName <> HostName) then StopDomSrv;   { V8.62 }
    Result := DomSrvIsRunning;
    if (NOT Result) then begin
        DBReadChallenges;  // get pending challenges
        FDomWebServer.DebugLevel := Self.FDebugLevel;
        FDomWebServer.WebSrvIP := FDomWebSrvIP;
        FDomWebServer.WebSrvPort := '80';
        if HostName <> '' then begin   { V8.62 }
            FDomWebServer.WebSrvPort := '80';
            FDomWebServer.WebSrvPortSsl := '443';
            FDomWebServer.WebSrvHostName := HostName;
            if CertBundle <> '' then
                FDomWebServer.WebSrvCertBundle := CertBundle
            else begin
                if FDirCertWork = '' then begin
                    LogEvent('Need Working Directory to Create LocalHost Certificate');
                    Exit;
                end;
                FFileCertLocalHost := IncludeTrailingPathDelimiter(FDirCertWork) + 'cert-localhost.pem';
                if NOT FileExists(FFileCertLocalHost) then begin
                    if NOT CreateAcmeAlpnCert(FFileCertLocalHost, 'localhost', '') then begin
                        LogEvent('Failed to Create LocalHost Certificate: ' + FFileCertLocalHost);
                        Exit;
                    end;
                end;
                FDomWebServer.WebSrvCertBundle := FFileCertLocalHost;
            end;
        end
        else begin
            FDomWebServer.WebSrvPortSsl := '0';
            FDomWebServer.WebSrvHostName := '';
        end;
        Result := FDomWebServer.StartSrv;
        if Result then
            LogEvent('Challenge Web Server Started on: ' + FDomWebServer.ListenStates)    { V8.62 }
        else
            LogEvent('Challenge Web Server Failed to Start');
    end
    else
       LogEvent('Challenge Web Server Already Running');
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.StopDomSrv: boolean ;    { returns false if stopped }
begin
//    FLastWebTick := TriggerDisabled;
    Result := False;   { V8.63 only if running, log it }
    if FDomWebServer.IsRunning then begin
        Result := FDomWebServer.StopSrv;
        if Result then
            LogEvent('Challenge Web Server Failed to Stop')
        else
            LogEvent('Challenge Web Server Stopped OK');
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.DomSrvIsRunning: Boolean;
begin
    Result := FDomWebServer.IsRunning;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ event called by simple web server when any page is requested }
procedure TSslX509Certs.WebSrvReq(Sender: TObject; const Host, Path,
                                Params: string; var RespCode, Body: string);
var
    Title, Msg, RespData: String;
    I: Integer;

    procedure BuildBody;
    begin
        Body := '<HTML><HEAD><TITLE>' + Title + '</TITLE></HEAD>' + IcsCRLF +
            '<BODY>' + IcsCRLF +
            '<H1>' + Title + '</H1>' + Msg + '<P>' + IcsCRLF +
            '</BODY></HTML>' + IcsCRLF;
        LogEvent('Challenge Web Response: ' + RespCode);
    end;

begin
 // ignore favicon requests completely
    if Path = '/favicon.ico' then begin
        RespCode := '404 Not Found';
        Title := RespCode;
        Msg := 'Error: File Not Found';
        BuildBody;
        Exit;
    end;

    LogEvent({RFC3339_DateToStr(Now) + } 'Challenge Web Request, Host: ' + Host + ', Path: ' + Path + ', Params: ' + Params);
 //   FullURL := 'http://' + Host + Path;
    RespData := '';

  /// check if URL is for .well-known and matches a pending challenge
    if ( FChallengesTot > 0) and (Pos ('/.well-known/', Path) = 1) and
                                         (Length(FChallengeItems) > 0) then begin
        for I := 0 to Length(FChallengeItems) - 1 do begin
            if FChallengeItems [I].CDomain = IcsLowerCase(Host) then begin  // was it for our domain
                with FChallengeItems [I] do begin

                 // check it our page requested - beware need forward slashes
                    if (Pos(CPage, Path) >= 1) then begin
                        RespData := CResp;
                        LogEvent('Challenge Web Server Response Sent for: ' + CDomain);
                        FChkChallgTrg := IcsGetTrgSecs64 (10);  { V8.63 next check 10 secs }
                        break;
                    end;
                end;
            end;
        end;
    end;

    if (RespData = '') then begin
        RespCode := '404 Not Found';
        Title := RespCode;
        Msg := 'Error: File Not Found';
        BuildBody;
    end
    else begin
 // found a page o return
        RespCode := '200 OK';
        Body := RespData;
    end;
  { web page is sent by event handler }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ event called by simple web server when tls-alpn-01 challenge requested }
procedure TSslX509Certs.WebSrvAlpn(Sender: TObject; const Host: string; var CertFName: string);
var
    I: Integer;
begin
    LogEvent({RFC3339_DateToStr(Now) +} 'Challenge Web tls-alpn-01 Challenge Request, Host: ' + Host);

    try
      /// check if host has Acme certificate created
        if ( FChallengesTot > 0) and (Length(FChallengeItems) > 0) then begin
            for I := 0 to Length(FChallengeItems) - 1 do begin
                if FChallengeItems [I].CDomain = IcsLowerCase(Host) then begin  // was it for our domain
                    with FChallengeItems [I] do begin
                        if (CAcmeAlpnCert <> '') then begin
                            CertFName := CAcmeAlpnCert;
                            LogEvent('Challenge Web tls-alpn-01 Challenge Certificate: ' + CertFName);
                            break;
                        end;
                    end;
                end;
            end;
        end;
    except
        on E:Exception do begin
            LogEvent('Failed to find tls-alpn-01 Challenge - ' + E.Message);
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.GetServerAPIUrl(Supplier: TSupplierProto;
                                        TestApi: Boolean = False): String;
begin
    Result := '';
    case Supplier of
        SuppProtoAcmeV2: begin
            if TestApi then
                Result := 'https://acme-staging-v02.api.letsencrypt.org/directory'
            else
                Result := 'https://acme-v02.api.letsencrypt.org/directory';
        end;
        SuppProtoCertCentre: begin
                Result := 'https://api.certcenter.com/rest/v1/';
        end;
        SuppProtoServtas: begin
            if TestApi then
                Result := 'https://test-api2.servertastic.com'
            else
                Result := 'https://api2.servertastic.com';
        end;

    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslX509Certs.SetOAuth2;
begin
    FRestOAuth.DebugLevel := FDebugLevel;
    FRestOAuth.ProtoType := OAuthv2;
    FRestOAuth.AuthType := FOAAuthType;
    FRestOAuth.AppUrl := Trim(FOAAppUrl);
    FRestOAuth.RedirectMsg := 'App: ' + FRestOAuth.AppUrl;
    FRestOAuth.ClientId := Trim(FOAClientId);
    FRestOAuth.ClientSecret := Trim(FOAClientSecret);
    FRestOAuth.ExpireDT := FOAExpireDT;
    FRestOAuth.OAOptions := [];
    FRestOAuth.RefreshAuto := FOARefreshAuto;
    FRestOAuth.RefrMinsPrior := FOARefrMinsPrior;
    FRestOAuth.RefreshToken := FOARefreshToken;    // sets RefreshDT
    FRestOAuth.Scope := Trim(FOAScope);
    FRestOAuth.TokenUrl := Trim(FOATokenUrl);
    FRestOAuth.RedirectUrl := Trim(FOARedirectUrl);
    FRestOAuth.WebSrvIP := Trim(FOAWebSrvIP);
    FRestOAuth.WebSrvPort := Trim(FOAWebSrvPort);
end;


{* * * * * * * * * * * ** * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslX509Certs.OAuthNewToken(Sender: TObject);
begin
    FOAAccToken := (Sender as TRestOAuth).AccToken;
    FOARefreshToken := (Sender as TRestOAuth).RefreshToken;
    FOAExpireDT := (Sender as TRestOAuth).ExpireDT;
    if FSupplierProto = SuppProtoCertCentre then
        DBWriteAccount;
    LogEvent('Got New OAuth Token OK');
    if Assigned(FOnNewToken) then FOnNewToken(self);
    if FPendOpenAccount <> '' then begin
        OpenAccount(FPendOpenAccount);
        FPendOpenAccount := '';  // only once
    end;
end;


{* * * * * * * * * * * ** * * * * * * * * * * * * * * * * * * * * * * * *}
{ ask user to access a URL  }
procedure TSslX509Certs.OAuth1OAuthAuthUrl(Sender: TObject; const URL: string);
begin
    LogEvent('Please copy this URL and browse to it, then enter Auth Code: ' + URL);
    if Assigned (OnOAuthAuthUrl) then begin
        OnOAuthAuthUrl(Self, URL);
    end;
end;


 {* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.OAGrantRefresh: boolean;
begin
    SetOAuth2;
    Result := FRestOAuth.GrantRefresh;
    if NOT Result then begin
        FOAAccToken := '';
    //    FOARefreshToken := '';  { V8.63 don't clear it, might not get new one 
        FOAExpireDT := 0;
        if Assigned(FOnNewToken) then FOnNewToken(self);
        if NOT FRestOAuth.StartAuthorization then Exit;
        LogEvent('OAuth2 authorization started, login using browser');
        Result := True;
    end;
end;


 {* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.OAGrantAuthToken(const Code: String): boolean;
begin
    SetOAuth2;
    Result := FRestOAuth.GrantAuthToken(Code);
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.SaveDataFile(const FName, Data: String): Boolean;
var
    NewFStream: TFileStream;
    Attempts: integer;
begin
    Result := False ; ;
    for attempts := 1 to 3 do
    begin
        if attempts > 1 then LogEvent('Failed to save fail, retrying');
        try
            if FileExists (FName) then
            begin
                if NOT DeleteFile(FName) then
                begin
                    LogEvent('Failed to delete old file: ' + FName) ;
                    exit ;
                end;
            end;
            if NOT ForceDirectories(ExtractFileDir (FName)) then
            begin
                LogEvent('Failed to create directory: ' + FName);
                continue;
            end;
            try
                NewFStream := TFileStream.Create (FName, fmCreate) ;
                NewFStream.WriteBuffer(AnsiString(Data) [1], Length (Data)) ;
                LogEvent('Saved file OK: ' + FName);
                Result := true ;
                Exit;
            finally
                FreeAndNil(NewFStream) ;
            end;
        except
            on E:Exception do begin
                LogEvent('Failed to save file: ' + FName + ' - ' + E.Message);
            end;
        end;
    end;
end ;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslX509Certs.HttpRestRestRequestDone(Sender: TObject;
  RqType: THttpRequest; ErrCode: Word);
begin
//    LogEvent(String(FHttpRest.ResponseRaw));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// make sure the host well-known directory is accessible from the internet and
// that we can copy files into it.  Otherwise domain validation will fail.

function TSslX509Certs.TestWellKnown(const aDomain, aDirWellKnown: String): Boolean;
var
    URL, path, testfile, fullname, Randomstr, Content, errinfo: string;
    StatCode, ChallgNum: integer;
    CurChallenge: TChallengeItem;
begin
    result := false;
    Randomstr := 'My ICS Random String at ' + DateTimeToStr (Now) + ' for ' + aDomain;
    testfile := 'icstestfile-' + InttoStr(Random(9999999));
    path := 'ics-validation/' + testfile;  // forward slashes
    URL := 'http://' + aDomain + '/.well-known/' + path;
    ChallgNum := -1;
    fullname := '';

 // start local web server if need it
    if fSuppCertChallenge = ChallFileSrv then begin
        if NOT StartDomSrv('', '') then Exit;
    end;

 // UNC file share, create file on remote server
    if fSuppCertChallenge = ChallFileUNC then begin
        if (Pos ('\', aDirWellKnown) = 0) or (aDirWellKnown[Length(aDirWellKnown)] <> '\') then begin
            LogEvent('Invalid Well Known Directory: ' + aDirWellKnown);
            Exit;
        end;
        LogEvent('Checking the host well-known directory is accessible from the internet ' +
                                          'and that we can copy files into it: ' + aDomain);
        fullname := aDirWellKnown + 'ics-validation\' + testfile;  // backslashes
        if NOT SaveDataFile(fullname, randomstr) then Exit ;
    end
    else if fSuppCertChallenge in [ChallFileSrv, ChallFileApp] then begin
      // save database challenge - only in array, never saved to database since temporary
        CurChallenge.CDomain := aDomain;
        CurChallenge.ChallengeURL := URL;
        CurChallenge.CIssueState := IssStateNone;
        CurChallenge.CPage := path;
        CurChallenge.CResp := Randomstr;
        ChallgNum := DBAddChallenge(CurChallenge);
    end
    else begin
        LogEvent('Well-known challenge not specified');
        exit;
    end;

  // try and read it via HTTP
    try
        FHttpTest.SocketFamily := FSocketFamily;         // V8.60 allow IPv6
        FHttpTest.ProxyURL := FProxyURL;                 // V8.62 proxy support
        FHttpTest.RestParams.Clear;
        StatCode := FHttpTest.RestRequest(HttpGET, URL, False, '');
        errinfo := FHttpTest.ReasonPhrase;
    except
        on E:Exception do begin
            errinfo := 'Could not read file at: ' + URL + ' - ' + E.Message;
            StatCode := 99;
        end;
    end;
    if StatCode <> 200 then begin
        LogEvent('Could not read file at: ' + URL + ' - ' + errinfo);
    end
    else begin
        Content := String(FHttpTest.ResponseOctet); // ignore content coding
        if Content = Randomstr then begin
             LogEvent('Successfully created and accessed Well-Known temporary file at: ' + URL);
             Result := true;
        end
        else
             LogEvent('Failed to compare temporary file content - ' + Content);
    end;
    if ChallgNum >= 0 then DBRemoveChallenge(ChallgNum); // delete challenge
    if (fullname <> '') and FileExists(FullName) then DeleteFile(FullName);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// create a self signed certificate for the ACME tls-alpn-01 challenge with the provided token
// also creates simple self signed if no keyauth, for localhost
function TSslX509Certs.CreateAcmeAlpnCert(const FileName, CName, KeyAuth: String): Boolean;
var
    MySslCertTools: TSslCertTools;
    Hash{, Hash2, temp}: AnsiString;
 {   Ext: TExtension;  }
begin
    Result := False;
    if KeyAuth <> '' then begin
        LogEvent ('keyAuthorization: ' + KeyAuth);
        Hash := IcsHashDigest(AnsiString(KeyAuth), Digest_sha256);
    end;
    MySslCertTools := TSslCertTools.Create(nil);
    try
        try
            MySslCertTools.CommonName := CName;
            MySslCertTools.AltDNSList.Text := CName;
            if KeyAuth <> '' then begin
                MySslCertTools.AcmeIdentifier := IcsBufferToHex(Hash);
                LogEvent ('AcmeIdentifier: ' + MySslCertTools.AcmeIdentifier +
                            ', Len=' + IntToStr(Length (MySslCertTools.AcmeIdentifier)));
            end;
            MySslCertTools.BasicIsCA := False;
            MySslCertTools.PrivKeyType := PrivKeyRsa2048;
            if KeyAuth <> '' then
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

          { now save them to PEM files - no passwords }
            MySslCertTools.SaveToPemFile(FileName, True, True, False);

           { write raw cert to log }
            LogEvent ('SSL certificate: ' + IcsCRLF + MySslCertTools.GetRawText);
         {   if KeyAuth <> '' then begin  // diag
                Ext := MySslCertTools.GetExtensionByName('acmeIdentifier');
                LogEvent('extension DER acmeIdentifier=' + Ext.Value);
                temp := StringReplace(Ext.Value, ':', '', [rfReplaceAll]);
                Hash2 := IcsHexToBin(Copy (temp, 5, 99));  // skip 0420
                if Hash = Hash2 then
                    LogEvent('acmeIdentifier hash matched OK')
                else
                    LogEvent('acmeIdentifier hash mismatch failed');
           end;   }
           result := true ;  // OK
        except
            on E:Exception do begin
                LogEvent ('Failed to create SSL certificate: ' + E.Message);
            end;
        end;
    finally
        MySslCertTools.Free;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// make sure the host accessible from the internet with SSL and supports the
// tls-alpn-01 challenge.  Otherwise domain validation will fail.

function TSslX509Certs.TestTlsAlpn(const aDomain, aDirWellKnown: String): Boolean;
var
    URL, CertFName, fakedomain: string;
    ChallgNum: integer;
    CurChallenge: TChallengeItem;
begin
    result := false;
    URL := 'https://' + aDomain + '/';
    ChallgNum := -1;
    CertFName := 'fake-acmealpn-' + BuildCertName(aDomain) + '.pem';
    fakedomain := 'fake-' + aDomain;
    LogEvent('Checking the tls-alpn-01 challenge works from the internet: ' + aDomain);

 // UNC file share, create file on remote server
    if fSuppCertChallenge = ChallAlpnUNC then begin
        if (Pos ('\', aDirWellKnown) = 0) or (aDirWellKnown[Length(aDirWellKnown)] <> '\') then begin
            LogEvent('Invalid Well Known Directory: ' + aDirWellKnown);
            Exit;
        end;
        CertFName := aDirWellKnown + CertFName;
        if NOT CreateAcmeAlpnCert(CertFName, fakedomain, '1234') then begin
            LogEvent('Failed to Create ACME ALPN SSL Certificate: ' + CertFName);
            Exit;
        end;
    end
    else if fSuppCertChallenge in [ChallAlpnSrv, ChallAlpnApp] then begin
        CertFName := FDirCertWork + CertFName;
        if NOT CreateAcmeAlpnCert(CertFName, fakedomain, '1234') then begin
            LogEvent('Failed to Create ACME ALPN SSL Certificate: ' + CertFName);
            Exit;
        end;
      // save database challenge - only in array, never saved to database since temporary
        CurChallenge.CDomain := aDomain;
        CurChallenge.CIssueState := IssStateNone;
        CurChallenge.CAcmeAlpnCert := CertFName;
        ChallgNum := DBAddChallenge(CurChallenge);
    end
    else begin
        LogEvent('tls-alpn-01 challenge not specified');
        exit;
    end;

  // try and connect via HTTPS, expect to fail due to self signed certificate
    try
        FHttpTest.AlpnProtocols.Text := AlpnAcmeTls1;
        FHttpTest.SocketFamily := FSocketFamily;
        FHttpTest.ProxyURL := FProxyURL;
        FHttpTest.CertVerMethod := CertVerBundle;
        FHttpTest.SslAllowSelfSign := True;
        FHttpTest.SslReportChain := True;
        FHttpTest.RestParams.Clear;
        LogEvent('ALPN Request to: ' + URL);
        FHttpTest.RestRequest(HttpGET, URL, False, '');
        if (FHttpTest.StatusCode <> 200) and (FHttpTest.GetAlpnProtocol = '') then begin
            LogEvent('Failed to check tls-alpn-01 challenge:  ' + FHttpTest.LastResponse);
        end
        else begin
            Result := (FHttpTest.GetAlpnProtocol = AlpnAcmeTls1); // we reached Acme aware server
            if Result then
                LogEvent('Successfully created and accessed tls-alpn-01 challenge')
            else
                LogEvent('Failed tls-alpn-01 challenge, ALPN Received:  ' + FHttpTest.GetAlpnProtocol);

        // pending, check host matched
        end;
    except
        on E:Exception do begin
            LogEvent('Could not access URL: ' + URL + ' - ' + E.Message);
        end;
    end;
    if ChallgNum >= 0 then DBRemoveChallenge(ChallgNum); // delete challenge
//  if (CertFName <> '') and FileExists(CertFName) then DeleteFile(CertFName);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// certificate supplier specific stuff,
function TSslX509Certs.DBOpenINI(const WorkDir: String; CreateNew: Boolean = False): Boolean;
var
    fname: String;
begin
    Result := False;
    fname := IncludeTrailingPathDelimiter(WorkDir) + FileIcsCntlDB;
    if Assigned(FControlFile) then begin
        if FCnrtFileName = fname then begin
            Result := True;
            Exit;
        end;
        FControlFile.Free;
    end;
    FCnrtFileName := fname;
    if (NOT CreateNew) and (NOT FileExists(FCnrtFileName)) then begin
        LogEvent('Account Control File Not Found: ' + FCnrtFileName);
        FCnrtFileName := '';
        Exit;
    end;
    try
        FControlFile := TIcsIniFile.Create(FCnrtFileName);
    except
        on E:Exception do begin
            LogEvent('Could Not Open Account Database: ' +
                                        FCnrtFileName + ' - ' + E.Message);
            FCnrtFileName := '';
            Exit;
        end;
    end;
    Result := True;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// certificate supplier specific stuff,
function TSslX509Certs.DBReadAccount(const WorkDir: String; UseStoredProps: Boolean): Boolean;
var
    section, OldWorkDir: String;
    OldProto: TSupplierProto;
begin
    Result := False;
    if NOT DBOpenINI(WorkDir) then Exit;
    section := CntlDBAccount;
    with FControlFile do begin

    // common stuff
        OldProto := TSupplierProto (GetEnumValue (TypeInfo (TSupplierProto), ReadString (section, 'SupplierProto', 'SuppProtoNone'))) ;
        if (Ord(OldProto) <= 0) or (OldProto <= SuppProtoNone) then begin
            LogEvent('Existing Account Not Found');
            Exit;
        end;
        OldWorkDir := ReadString (section, 'DirCertWork', '') ;
        if (OldWorkDir <> '') and (CompareText(OldWorkDir, WorkDir) <> 0) then begin
            LogEvent('Certifcate Work Directory, Expected ' + WorkDir + ' but found ' + OldWorkDir);
            Exit;
        end;
        if UseStoredProps then begin
            FSupplierProto := OldProto;
            FDirCertWork := OldWorkDir;
            FDebugLevel := THttpDebugLevel (GetEnumValue (TypeInfo (THttpDebugLevel), ReadString (section, 'DebugLevel', 'DebugNone'))) ;
            FDomWebSrvIP := ReadString (section, 'DomWebSrvIP', '') ;
            if ReadString (section, 'LogJson', 'False') = 'True' then FLogJson := true else FLogJson := false ;
            if ReadString (section, 'LogPkeys', 'False') = 'True' then FLogPkeys := true else FLogPkeys := false ;
            FSeqOrderNum := ReadInteger (section, 'SeqOrderNum', 1001) ;
            FSupplierEmail := ReadString (section, 'SupplierEmail', '') ;
            FSupplierServer := ReadString (section, 'SupplierServer', '') ;
            FSupplierTitle := ReadString (section, 'SupplierTitle', '') ;

         // OAuth2 stuff
            if FSupplierProto = SuppProtoCertCentre then begin
                FOAAccToken := ReadString (section, 'OAAccToken', '') ;
                FOAAppUrl := ReadString (section, 'OAAppUrl', '') ;
                FOAClientId := ReadString (section, 'OAClientId', '') ;
                FOAClientSecret := ReadString (section, 'OAClientSecret', '') ;
                FOAExpireDT := RFC3339_StrToDate(ReadString (section, 'OAExpire', '')) ;
                FOARedirectUrl := ReadString (section, 'OARedirectUrl', '') ;
                if ReadString (section, 'OARefreshAuto', 'False') = 'True' then FOARefreshAuto := true else FOARefreshAuto := false ;
                FOARefreshToken := ReadString (section, 'OARefreshToken', '') ;
                FOARefrMinsPrior := ReadInteger (section, 'OARefrMinsPrior', 0) ;
                FOAScope := ReadString (section, 'OAScope', '') ;
                FOATokenUrl := ReadString (section, 'OATokenUrl', '') ;
                FOAWebSrvIP := ReadString (section, 'OAWebSrvIP', '') ;
                FOAWebSrvPort := ReadString (section, 'OAWebSrvPort', '') ;
            end;

         // own CA stuff
            if FSupplierProto = SuppProtoOwnCA then begin
                FCACertFile := ReadString (section, 'CACertFile', '') ;
                FCAPkeyFile := ReadString (section, 'CAPkeyFile', '') ;
                FCAPkeyPw := ReadString (section, 'CAPkeyPw', '') ;
            end;
        end;
        if UseStoredProps then
            LogEvent('Opened Supplier Account for: ' + FSupplierTitle + ', Protocol: ' +
                SupplierProtoLits [FSupplierProto] + ', File: ' + FCnrtFileName);

    // ACME stuff
        if FSupplierProto = SuppProtoAcmeV2 then begin
            if UseStoredProps then begin
                FAcmeAccKeyType := TSslPrivKeyType (GetEnumValue (TypeInfo (TSslPrivKeyType), ReadString (section, 'AcmeAccKeyType', 'PrivKeyRsa2048'))) ;
            end;
            fAcmeAccountUrl := ReadString (section, 'AcmeAccountUrl', '') ;
            fAcmeAccountNum := ReadString (section, 'AcmeAccountNum', '') ;
            if fAcmeAccountUrl <> '' then begin
                LogTimeStamp;
                LogEvent('Loaded Existing ACME Account: ' + fAcmeAccountUrl + ' from ' + WorkDir);
            end;
        end;
    end;
    Result := DBReadSections;
    if Result and UseStoredProps then
        LogEvent('Common Name Domains Found, Total: ' + IntToStr(Length(FDomainItems)));
 end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.DBReadSections: Boolean;
var
    I: Integer;
    MyDomains: TStringList;
    section: String;
begin
    Result := False;
    if NOT DBOpenINI(FDirCertWork) then Exit;
    MyDomains := TStringList.Create;
    try
        FControlFile.ReadSections(FDBIniSections);    // get cert domains and challenges
        for I := 0 to FDBIniSections.Count - 1 do begin
            if Pos(CntlDBDomainPre, FDBIniSections[I]) = 1 then
                 MyDomains.Add(Copy(FDBIniSections[I], Length(CntlDBDomainPre) + 1, 999));
        end;
        MyDomains.Sort;
        SetLength(FDomainItems, MyDomains.Count);
        if MyDomains.Count > 0 then begin
            for I := 0 to MyDomains.Count - 1 do begin
                with FDomainItems[I], FControlFile do begin
                    section := IcsLowerCase(CntlDBDomainPre + MyDomains[I]);
                    DCommonName := MyDomains[I];
                    DCertSANs := ReadString (section, 'CertSubAltList', '') ;
                    DProduct := ReadString (section, 'SuppCertProduct', '') ;
                    DSuppOrderId := ReadString (section, 'SuppOrderId', '') ;
                    DIssueState := TIssueState(GetEnumValue (TypeInfo (TIssueState), ReadString (section, 'IssueState', 'IssStateNone')));
                    DSuppCertChallg := TChallengeType (GetEnumValue (TypeInfo (TChallengeType), ReadString (section, 'SuppCertChallenge', 'ChallNone'))) ;
                    DStartDT := RFC3339_StrToDate(ReadString (section, 'NewCertStartDT', '')) ;
                    DEndDT := RFC3339_StrToDate(ReadString (section, 'NewCertEndDT', '')) ;
                    DDirWellKnown := ReadString (section, 'DirWellKnown', '');   { V8.62 }
                    DDirPubWebCert := ReadString (section, 'DirPubWebCert', ''); { V8.62 }
                end;
            end;
        end;
        Result := True;
        if Assigned(FOnDomainsRefresh) then FOnDomainsRefresh(Self);
    finally
        MyDomains.Free;
    end;
 end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.DBWriteAccount: Boolean;
var
    section, temp: string;
begin
    Result := False;
    if NOT DBOpenINI(FDirCertWork) then Exit;
    section := CntlDBAccount;
    with FControlFile do begin

    // common stuff
        WriteString (section, 'DebugLevel', GetEnumName (TypeInfo (THttpDebugLevel), Ord(FDebugLevel))) ;
        WriteString (section, 'DirCertWork', FDirCertWork) ;
        WriteString (section, 'DomWebSrvIP', FDomWebSrvIP) ;
        if FLogJson then temp := 'True' else temp := 'False' ; WriteString (section, 'LogJson', temp) ;
        if FLogPkeys then temp := 'True' else temp := 'False' ; WriteString (section, 'LogPkeys', temp) ;
        WriteInteger (section, 'SeqOrderNum', FSeqOrderNum) ;
        WriteString (section, 'SupplierEmail', FSupplierEmail) ;
        WriteString (section, 'SupplierProto',  GetEnumName (TypeInfo (TSupplierProto), Ord (FSupplierProto)));
        WriteString (section, 'SupplierServer', FSupplierServer) ;
        WriteString (section, 'SupplierTitle', FSupplierTitle) ;

  // OAuth2 stuff
        if FSupplierProto = SuppProtoCertCentre then begin
             WriteString (section, 'OAAccToken', FOAAccToken) ;
             WriteString (section, 'OAAppUrl', FOAAppUrl) ;
             WriteString (section, 'OAClientId', FOAClientId) ;
             WriteString (section, 'OAClientSecret', FOAClientSecret) ;
             WriteString (section, 'OAExpire', RFC3339_DateToStr(FOAExpireDT)) ;
             WriteString (section, 'OARedirectUrl', FOARedirectUrl) ;
             if FOARefreshAuto then temp := 'True' else temp := 'False' ; WriteString (section, 'OARefreshAuto', temp) ;
             WriteString (section, 'OARefreshToken', FOARefreshToken) ;
             WriteInteger (section, 'OARefrMinsPrior', FOARefrMinsPrior) ;
             WriteString (section, 'OAScope', FOAScope) ;
             WriteString (section, 'OATokenUrl', FOATokenUrl) ;
             WriteString (section, 'OAWebSrvIP', FOAWebSrvIP) ;
             WriteString (section, 'OAWebSrvPort', FOAWebSrvPort) ;
        end;

    // ACME stuff
        if FSupplierProto = SuppProtoAcmeV2 then begin
            WriteString (section, 'AcmeAccKeyType', GetEnumName (TypeInfo (TSslPrivKeyType), Ord(FAcmeAccKeyType))) ;
            WriteString (section, 'AcmeAccountNum', fAcmeAccountNum) ;
            WriteString (section, 'AcmeAccountUrl', fAcmeAccountUrl) ;
        end;

     // own CA stuff
        if FSupplierProto = SuppProtoOwnCA then begin
            WriteString (section, 'CACertFile', FCACertFile) ;
            WriteString (section, 'CAPkeyFile', FCAPkeyFile) ;
            WriteString (section, 'CAPkeyPw', FCAPkeyPw) ;
        end;
    end;
    FControlFile.UpdateFile;  // write INI file
    Result := True;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.DBNewOrderNum: Integer;
var
    section: string;
begin
    Result := 0;
    if NOT DBOpenINI(FDirCertWork) then Exit;
    section := CntlDBAccount;
    with FControlFile do begin
        if FSeqOrderNum < 1001 then begin
            LogEvent('Failed to Read Valid SeqOrderNum, Resetting');
            FSeqOrderNum := 1001;
        end;
        Result := FSeqOrderNum;
        LogEvent('New Sequential Order Number: ' + IntToStr(Result)) ;
        FSeqOrderNum := FSeqOrderNum + 1;
        WriteInteger (section, 'SeqOrderNum', FSeqOrderNum) ;
        FControlFile.UpdateFile;  // write INI file
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.DBFindDomain(const CNDomain: String): Integer;
var
    I: Integer;
begin
    Result := -1;
    if Length(FDomainItems) > 0 then begin
        for I := 0 to Length(FDomainItems) - 1 do begin
            if FDomainItems[I].DCommonName = CNDomain then begin
                Result := I;
                Exit;
            end;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// a certificate common name domain, perhaps with sub domains as well
// UseStoredProps replaces all public properties from database values
function TSslX509Certs.DBReadCNDomain(const CNDomain: String; UseStoredProps: Boolean): Boolean;
var
    section, temp, aDomain, aDirWellKnown, aDirPubWebCert, aApprovalEmail: String;
    I, idx: Integer;
begin
    Result := False;
    if NOT DBOpenINI(FDirCertWork) then Exit;
    section := IcsLowerCase(CntlDBDomainPre + CNDomain);

    with FControlFile do begin
        temp := ReadString (section, 'CertCommonName', '') ;
        if temp <> CNDomain then begin
            LogEvent('Certificate Domain Not Found: ' + CNDOmain);
            Exit;
         end;
        FCertCommonName := temp;

    // stuff supplied by user from public properties
        if UseStoredProps then begin
            FCertAddress := ReadString (Section, 'CertAddress', '') ;
            FCertApprovEmail := ReadString (section, 'CertApprovEmail', '') ;
            FCertContactEmail := ReadString (section, 'CertContactEmail', '') ;
            FCertContactFirst := ReadString (section, 'CertContactFirst', '') ;
            FCertContactLast := ReadString (section, 'CertContactLast', '') ;
            FCertContactTitle := ReadString (section, 'CertContactTitle', '') ;
            FCertCountry := ReadString (section, 'CertCountry', '') ;
            FCertCsrOrigin := TCertCsrOrigin (GetEnumValue (TypeInfo (TCertCsrOrigin), ReadString (section, 'CertCsrOrigin', 'CsrOriginProps'))) ;
            FCertLocality := ReadString (section, 'CertLocality', '') ;
            FCertOldCsrFile := ReadString (section, 'CertOldCsrFile', '') ;
            FCertOldPrvKey := ReadString (section, 'CertOldPrvKey', '') ;
            FCertOrgUnit := ReadString (section, 'CertOrgUnit', '') ;
            FCertOrganization := ReadString (section, 'CertOrganization', '') ;
            IcsStrToSet(TypeInfo (TCertOutFmt), ReadString (section, 'CertOutFmts', ''), FCertOutFmts, SizeOf(FCertOutFmts)) ;
            FCertPhone := ReadString (section, 'CertPhone', '') ;
            FCertPostCode := ReadString (section, 'CertPostCode', '') ;
            FCertSerNumType := TSerNumType (GetEnumValue (TypeInfo (TSerNumType), ReadString (section, 'CertSerNumType', 'SerNumRandom'))) ;
            FCertSignDigestType := TEvpDigest (GetEnumValue (TypeInfo (TEvpDigest), ReadString (section, 'CertSignDigestType', 'Digest_sha256'))) ;
            FCertState := ReadString (section, 'CertState', '') ;
            FCertValidity := ReadInteger (section, 'CertValidity', 0) ;
            FDirPubWebCert.CommaText := ReadString (section, 'DirPubWebCert', '') ;
            FDirWellKnown := ReadString (section, 'DirWellKnown', '') ;
            FPrivKeyCipher := TSslPrivKeyCipher (GetEnumValue (TypeInfo (TSslPrivKeyCipher), ReadString (section, 'PrivKeyCipher', 'PrivKeyEncNone'))) ;
            FPrivKeyPassword := ReadString (section, 'PrivKeyPassword', '') ;  // encrypt password !!!!
            FPrivKeyType := TSslPrivKeyType (GetEnumValue (TypeInfo (TSslPrivKeyType), ReadString (section, 'PrivKeyType', 'PrivKeyRsa2048'))) ;
            FSuppCertChallenge := TChallengeType (GetEnumValue (TypeInfo (TChallengeType), ReadString (section, 'SuppCertChallenge', 'ChallNone'))) ;
            FSuppCertProduct := ReadString (section, 'SuppCertProduct', '') ;
            FSuppOrderId := ReadString (section, 'SuppOrderId', '') ;
            FSuppOrderRef := ReadString (section, 'SuppOrderRef', '') ;
        end;

    // stuff created during certificate processing
        FAcmeOrderFinalizeUrl := ReadString (section, 'AcmeOrderFinalizeUrl', '');
        FAcmeOrderObjUrl := ReadString (section, 'AcmeOrderObjUrl', '');
        FChallgDoneDT := RFC3339_StrToDate(ReadString (section, 'ChallgDoneDT', '')) ;
        FChallgStartDT := RFC3339_StrToDate(ReadString (section, 'ChallgStartDT', '')) ;
        FFileFinalBundle := ReadString (section, 'FileFinalBundle', '') ;
        FFileFinalCSR := ReadString (section, 'FileFinalCSR', '') ;
        FFileFinalCert := ReadString (section, 'FileFinalCert', '') ;
        FFileFinalPrvKey := ReadString (section, 'FileFinalPrvKey', '') ;
        FIssueState := TIssueState(GetEnumValue (TypeInfo (TIssueState), ReadString (section, 'IssueState', 'IssStateNone')));
        FNewCertCN := ReadString (section, 'NewCertCN', '') ;
        FNewCertChainInfo := ReadString (section, 'NewCertChainInfo', '') ;
        FNewCertEndDT := RFC3339_StrToDate(ReadString (section, 'NewCertEndDT', '')) ;
        FNewCertErrs := ReadString (section, 'NewCertErrs', '') ;
        FNewCertSAN := ReadString (section, 'NewCertSAN', '') ;
        FNewCertStartDT := RFC3339_StrToDate(ReadString (section, 'NewCertStartDT', '')) ;
        FNewCertValRes := TChainResult(GetEnumValue (TypeInfo (TChainResult), ReadString (section, 'NewCertValRes', 'chainOK'))) ;
        FNewOrderNum := ReadInteger (section, 'NewOrderNum', 0) ;
        FOrderAttempts := ReadInteger (section, 'OrderAttempts', 0) ;
        FOrderCertsDT := RFC3339_StrToDate(ReadString (section, 'OrderCertsDT', '')) ;
        FOrderStartDT := RFC3339_StrToDate(ReadString (section, 'OrderStartDT', '')) ;
        FPartFNameFinal := ReadString (section, 'PartFNameFinal', '') ;
        FPartFNameOrder := ReadString (section, 'PartFNameOrder', '') ;
        FPartFNameServer.CommaText := ReadString (section, 'PartFNameServer', '') ;
        FPendingChallg := ReadInteger (section, 'PendingChallg', 0) ;
        FProductCA := ReadString (section, 'ProductCA', '') ;
        FProductCertType := ReadString (section, 'ProductCertType', '') ;
        FProductDVAuth := ReadString (section, 'ProductDVAuth', '') ;
        FProductFeatures := ReadString (section, 'ProductFeatures', '') ;
        FProductMaxSan := ReadInteger (section, 'ProductMaxSan', 0) ;
        FProductQuote := ReadString (section, 'ProductQuote', '') ;

    // find Subject Alternate Names
        if UseStoredProps then begin
            FCertSANs.CommaText := ReadString (section, 'CertSubAltList', '') ;
            FCertSubAltNames.Clear;
            FCertSANTot := FCertSANs.Count;
            if FCertSANTot > 0 then begin
                for I := 0 to FCertSANTot - 1 do begin
                    section := IcsLowerCase(CntlDBSANPre + FCertCommonName + '=' + FCertSANs[I]);
                    aDomain := ReadString (section, 'Domain', '') ;
                    aDirWellKnown := ReadString (section, 'DirWellKnown', '') ;
                    aDirPubWebCert := ReadString (section, 'DirPubWebCert', '') ;
                    aApprovalEmail := ReadString (section, 'ApprovalEmail', '') ;
                    if aDomain <> '' then begin
                        idx := FCertSubAltNames.AddItem (aDomain, aDirWellKnown, aDirPubWebCert, aApprovalEmail);
                        with FCertSubAltNames [idx] do begin
                            SAIssueState := TIssueState(GetEnumValue (TypeInfo (TIssueState), ReadString (section, 'SAIssueState', 'IssStateNone'))) ;
                            SAStartDT := RFC3339_StrToDate(ReadString (section, 'SAStartDT', '')) ;
                            SADoneDT := RFC3339_StrToDate(ReadString (section, 'SADoneDT', '')) ;
                            SAValidResult := ReadString (section, 'SAValidResult', '') ;
                        end;
                    end;
                end;
            end;
        end;
    end;
    Result := True;

  // try and update one FDomainItems to avoid reloading lot
    idx := DBFindDomain(CNDomain);
    if idx < 0 then
        DBReadSections
    else begin
        FDomainItems[idx].DCertSANs := FCertSANs.CommaText;
        FDomainItems[idx].DProduct := FSuppCertProduct;
        FDomainItems[idx].DSuppOrderId := FSuppOrderId;
        FDomainItems[idx].DIssueState := FIssueState;
        FDomainItems[idx].DStartDT := FNewCertStartDT;
        FDomainItems[idx].DEndDT := FNewCertEndDT;
        if Assigned(FOnDomainsRefresh) then FOnDomainsRefresh(Self);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.DBWriteCNDomain: Boolean;
var
    section, temp: string;
    I, J: Integer;
    flag: Boolean;
begin
    Result := False;
    if NOT DBOpenINI(FDirCertWork) then Exit;
    section := CntlDBDomainPre + FCertCommonName;
    with FControlFile do begin
        WriteString (section, 'AcmeOrderFinalizeUrl', FAcmeOrderFinalizeUrl);
        WriteString (section, 'AcmeOrderObjUrl', FAcmeOrderObjUrl);
        WriteString (Section, 'CertAddress', FCertAddress) ;
        WriteString (section, 'CertApprovEmail', FCertApprovEmail) ;
        WriteString (section, 'CertCommonName', FCertCommonName) ;
        WriteString (section, 'CertContactEmail', FCertContactEmail) ;
        WriteString (section, 'CertContactFirst', FCertContactFirst) ;
        WriteString (section, 'CertContactLast', FCertContactLast) ;
        WriteString (section, 'CertContactTitle', FCertContactTitle) ;
        WriteString (section, 'CertCountry', FCertCountry) ;
        WriteString (section, 'CertCsrOrigin', GetEnumName (TypeInfo (TCertCsrOrigin), Ord(CertCsrOrigin))) ;
        WriteString (section, 'CertLocality', FCertLocality) ;
        WriteString (section, 'CertOldCsrFile', CertOldCsrFile) ;
        WriteString (section, 'CertOldPrvKey', CertOldPrvKey) ;
        WriteString (section, 'CertOrgUnit', FCertOrgUnit) ;
        WriteString (section, 'CertOrganization', FCertOrganization) ;
        WriteString (section, 'CertOutFmts', IcsSetToStr(TypeInfo (TCertOutFmt), FCertOutFmts, SizeOf(FCertOutFmts))) ;
        WriteString (section, 'CertPhone', FCertPhone) ;
        WriteString (section, 'CertPostCode', FCertPostCode) ;
        WriteString (section, 'CertSerNumType', GetEnumName (TypeInfo (TSerNumType), Ord(FCertSerNumType))) ;
        WriteString (section, 'CertSignDigestType', GetEnumName (TypeInfo (TEvpDigest), Ord(FCertSignDigestType))) ;
        WriteString (section, 'CertState', FCertState) ;
        WriteInteger (section, 'CertValidity', FCertValidity) ;
        WriteString (section, 'ChallgDoneDT', RFC3339_DateToStr(FChallgDoneDT)) ;
        WriteString (section, 'ChallgStartDT', RFC3339_DateToStr(FChallgStartDT)) ;
        WriteString (section, 'DirPubWebCert', FDirPubWebCert.CommaText) ;
        WriteString (section, 'DirWellKnown', FDirWellKnown) ;
        WriteString (section, 'FileFinalBundle', FFileFinalBundle) ;
        WriteString (section, 'FileFinalCSR', FFileFinalCSR) ;
        WriteString (section, 'FileFinalCert', FFileFinalCert) ;
        WriteString (section, 'FileFinalPrvKey', FFileFinalPrvKey) ;
        WriteString (section, 'IssueState', GetEnumName (TypeInfo (TIssueState), Ord(FIssueState)));
        WriteString (section, 'NewCertCN', FNewCertCN) ;
        WriteString (section, 'NewCertChainInfo', FNewCertChainInfo) ;
        WriteString (section, 'NewCertEndDT', RFC3339_DateToStr(FNewCertEndDT)) ;
        WriteString (section, 'NewCertErrs', FNewCertErrs) ;
        WriteString (section, 'NewCertSAN', FNewCertSAN) ;
        WriteString (section, 'NewCertStartDT', RFC3339_DateToStr(FNewCertStartDT)) ;
        WriteString (section, 'NewCertValRes', GetEnumName (TypeInfo (TChainResult), Ord(FNewCertValRes))) ;
        WriteInteger (section, 'NewOrderNum', FNewOrderNum) ;
        WriteInteger (section, 'OrderAttempts', FOrderAttempts) ;
        WriteString (section, 'OrderCertsDT', RFC3339_DateToStr(FOrderCertsDT)) ;
        WriteString (section, 'OrderStartDT', RFC3339_DateToStr(FOrderStartDT)) ;
        WriteString (section, 'PartFNameFinal', FPartFNameFinal) ;
        WriteString (section, 'PartFNameOrder', FPartFNameOrder) ;
        WriteString (section, 'PartFNameServer', FPartFNameServer.CommaText) ;
        WriteInteger (section, 'PendingChallg', FPendingChallg) ;
        WriteString (section, 'PrivKeyCipher', GetEnumName (TypeInfo (TSslPrivKeyCipher), Ord(FPrivKeyCipher))) ;
        WriteString (section, 'PrivKeyPassword', FPrivKeyPassword) ;  // encrypt password !!!!
        WriteString (section, 'PrivKeyType', GetEnumName (TypeInfo (TSslPrivKeyType), Ord(FPrivKeyType))) ;
        WriteString (section, 'ProductCertType', FProductCertType) ;
        WriteString (section, 'ProductDVAuth', FProductDVAuth) ;
        WriteString (section, 'ProductFeatures', FProductFeatures) ;
        WriteInteger (section, 'ProductMaxSan', FProductMaxSan) ;
        WriteString (section, 'ProductQuote', FProductQuote) ;
        WriteString (section, 'SuppCertChallenge', GetEnumName (TypeInfo (TChallengeType), Ord(FSuppCertChallenge)));
        WriteString (section, 'SuppOrderId', FSuppOrderId) ;
        WriteString (section, 'SuppOrderRef', FSuppOrderRef) ;
        WriteString (section, 'SuppCertProduct', FSuppCertProduct) ;
        WriteString (section, 'ProductCA', FProductCA) ;

    // write INI file
        FControlFile.UpdateFile;

    // erase any old SAN sections
        FControlFile.ReadSections(FDBIniSections);
        section := CntlDBSANPre + FCertCommonName + '=';
        for J := 0 to FDBIniSections.Count - 1 do begin
            if Pos(section, FDBIniSections[J]) = 1 then begin
                flag := False;
                if FCertSubAltNames.Count > 0 then begin
                    temp := Copy(FDBIniSections[J], Length(section), 999);
                    for I := 0 to FCertSubAltNames.Count - 1 do begin
                        if FCertSubAltNames[I].SADomain = temp then begin
                            flag := True;
                            break;
                        end;
                    end;
                end;
                if NOT flag then FControlFile.EraseSection(FDBIniSections[J]);
            end;
        end;

    // save Subject Alternate Names
        temp := '';
        FCertSANs.Clear;
        if CertSubAltNames.Count > 0 then begin
        // save current SAN sections
            for I := 0 to FCertSubAltNames.Count - 1 do begin
                with FCertSubAltNames[I] do begin
                    if SADomain = '' then Continue; // sanity check
                    FCertSANs.Add(SADomain);
                    section := CntlDBSANPre + FCertCommonName + '=' + SADomain;
                    WriteString (section, 'Domain', SADomain) ;
                    WriteString (section, 'DirWellKnown', SADirWellKnown) ;
                    WriteString (section, 'DirPubWebCert', SADirPubWebCert) ;
                    WriteString (section, 'ApprovalEmail', SAApprovalEmail) ;
                    WriteString (section, 'SAIssueState', GetEnumName (TypeInfo (TIssueState), Ord(SAIssueState))) ;
                    WriteString (section, 'SAStartDT', RFC3339_DateToStr(SAStartDT)) ;
                    WriteString (section, 'SADoneDT', RFC3339_DateToStr(SADoneDT)) ;
                    WriteString (section, 'SAValidResult', SAValidResult) ;
                end;
            end;
        end;
        section := CntlDBDomainPre + FCertCommonName;
        WriteString (section, 'CertSubAltList', FCertSANs.CommaText) ;
    end;
    FControlFile.UpdateFile;  // write INI file
    DBReadSections;
    if Assigned(FOnDomainsRefresh) then FOnDomainsRefresh(Self);
    Result := True;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// delete certificate common name domain, perhaps with sub domains as well
function TSslX509Certs.DBDeleteCNDomain(const CNDomain: String): Boolean;
var
    section: string;
    J: Integer;
begin
    Result := False;
    if NOT DBOpenINI(FDirCertWork) then Exit;
    section := CntlDBDomainPre + CNDomain;
    if FControlFile.SectionExists(section) then
               FControlFile.EraseSection(section);

  // erase any SAN sections
    FControlFile.ReadSections(FDBIniSections);
    section := IcsLowerCase(CntlDBSANPre + CNDomain + '=');
    for J := 0 to FDBIniSections.Count - 1 do begin
        if Pos(section, FDBIniSections[J]) = 1 then begin
             FControlFile.EraseSection(FDBIniSections[J]);
        end;
    end;
    FControlFile.UpdateFile;  // write INI file
    DBReadSections;
    if Assigned(FOnDomainsRefresh) then FOnDomainsRefresh(Self);
    Result := True;

end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// find SAB record for domain, allowing for wildcards
function TSslX509Certs.DBFindSAN(const adomain: String): Integer;
var
    I: Integer;
begin
    Result := -1;
    for I := 0 to FCertSubAltNames.Count - 1 do begin
        if (adomain = FCertSubAltNames[I].SADomain) then begin
            Result := I;
            Exit;
        end
     // wild card removes *. from domain
        else if (Pos(adomain, FCertSubAltNames[I].SADomain) > 1) and
                  (Pos ('*.', FCertSubAltNames[I].SADomain) = 1) then begin
            Result := I;
            Exit;
        end;
     end;

end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.DBFindChallengeNum(const Domain: String): Integer;
var
    I: Integer;
begin
    Result := -1;
    if FChallengesTot = 0 then Exit;
    for I := 0 to Length(FChallengeItems) - 1 do begin
        if FChallengeItems [I].CDomain = IcsLowerCase(Domain) then begin
            Result := I;
            Exit;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// find first blank challenge in array, or increase array size
function TSslX509Certs.DBFreeChallengeNum: Integer;
var
    I, tot: Integer;
begin
    tot := Length(FChallengeItems);
    if tot > 0 then begin
        for I := 0 to Length(FChallengeItems) - 1 do begin
            if FChallengeItems [I].CDomain = '' then begin
                Result := I;
                Exit;
            end;
        end;
    end;
    SetLength(FChallengeItems, tot + 8);
    for I := tot to Length(FChallengeItems) - 1 do
                            FChallengeItems [I].CDomain := '';    // clear all records
    Result := tot;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.DBReadChallenges: Boolean;
var
    section: string;
    I, Days: Integer;
    StartedDT: TDateTime;
    Updated: Boolean;
    ChallgType: TChallengeType;
begin
    Result := False;
    if NOT DBReadSections then Exit;
    FChallengesTot := 0;
    Updated := False;
    SetLength(FChallengeItems, FDBIniSections.Count + 2);
    for I := 0 to Length(FChallengeItems) - 1 do
                            FChallengeItems [I].CDomain := '';    // clear all records
    for I := 0 to FDBIniSections.Count - 1 do begin
        if Pos(CntlDBChallenge, FDBIniSections[I]) = 1 then begin
            section := FDBIniSections[I];
            with FControlFile do begin

              { V8.63 expire and remove challenge after 24 hours or a week }
                StartedDT := RFC3339_StrToDate(ReadString (section, 'CStartDT', '')) ;
                ChallgType := TChallengeType(GetEnumValue (TypeInfo (TChallengeType), ReadString (section, 'CType', ''))) ;
                Days := 1;
                if (ChallgType in [ChallDNS, ChallEmail, ChallManual]) then Days := 7;
                if ((StartedDT + Days) < Now) then begin
                    EraseSection(section);
                    Updated := True;
                    Continue;
                end;
                with FChallengeItems [FChallengesTot] do begin
                    CDomain := ReadString (section, 'CDomain', '') ;
                    CCommonName := ReadString (section, 'CCommonName', '') ;
                    CSanIdx := ReadInteger (section, 'CSanIdx', -1) ;
                    CSuppOrderId := ReadString (section, 'CSuppOrderId', '') ;
                    CDirWellKnown := ReadString (section, 'CDirWellKnown', '') ;
                    CDirPubWebCert := ReadString (section, 'CDirPubWebCert', '') ;
                    CWKFullName := ReadString (section, 'CWKFullName', '') ;
                    CSupplierProto := TSupplierProto(GetEnumValue (TypeInfo (TSupplierProto), ReadString (section, 'CSupplierProto', ''))) ;
                    CType := ChallgType;
                    CIssueState := TIssueState(GetEnumValue (TypeInfo (TIssueState), ReadString (section, 'CIssueState', ''))) ;
                    CAuthzURL := ReadString (section, 'CAuthzURL', '') ;
                    ChallgToken := IcsUnEscapeCRLF(ReadString (section, 'ChallgToken', '')) ;
                    ChallengeURL := ReadString (section, 'ChallengeURL', '') ;
                    CPage := ReadString (section, 'CPage', '') ;
                    CResp := IcsUnEscapeCRLF(ReadString (section, 'CResp', '')) ;
                    CDNSValue := ReadString (section, 'CDNSValue', '') ;
                    CAcmeAlpnCert := ReadString (section, 'CAcmeAlpnCert', '') ; // V8.62
                    CStartDT := StartedDT;
                    CDoneDT := RFC3339_StrToDate(ReadString (section, 'CDoneDT', '')) ;
                    CValidResult := ReadString (section, 'CValidResult', '') ;
                end;
                FChallengesTot := FChallengesTot + 1;
            end;
        end;
    end;
    LogEvent('Number of Domain Challenges Found: ' + IntToStr(FChallengesTot));
    if Updated then FControlFile.UpdateFile;  // write INI file
    Result := True;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// add or update challenge in array
function TSslX509Certs.DBAddChallenge(Item: TChallengeItem): Integer;
begin
    Result := DBFindChallengeNum(Item.CDomain);
    if Result < 0 then begin
        Result := DBFreeChallengeNum;
        FChallengesTot := FChallengesTot + 1;
    end;
    FChallengeItems [Result] := Item;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// reemove challenge from array
function TSslX509Certs.DBRemoveChallenge(ChallgNum: Integer): Boolean;
begin
    Result := False;
    if (ChallgNum >= 0) and (ChallgNum < Length(FChallengeItems)) then begin
        FChallengeItems [ChallgNum].CDomain := '';
        FChallengesTot := FChallengesTot - 1;
        Result := True;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.DBWriteOneChallenge(Item: TChallengeItem): Integer;
var
    section: string;
begin
    Result := -1;
    if NOT DBOpenINI(FDirCertWork) then Exit;
    with Item do begin
        section := IcsLowerCase(CntlDBChallenge + CDomain);
        with FControlFile do begin
            WriteString (section, 'CDomain', IcsLowerCase(CDomain)) ;
            WriteString (section, 'CCommonName', CCommonName) ;
            WriteInteger (section, 'CSanIdx', CSanIdx) ;
            WriteString (section, 'CSuppOrderId', CSuppOrderId) ;
            WriteString (section, 'CDirWellKnown', CDirWellKnown) ;
            WriteString (section, 'CDirPubWebCert', CDirPubWebCert) ;
            WriteString (section, 'CWKFullName', CWKFullName) ;
            WriteString (section, 'CSupplierProto', GetEnumName (TypeInfo (TSupplierProto), Ord(CSupplierProto))) ;
            WriteString (section, 'CType', GetEnumName (TypeInfo (TChallengeType),Ord(CType))) ;
            WriteString (section, 'CIssueState', GetEnumName (TypeInfo (TIssueState),Ord(CIssueState))) ;
            WriteString (section, 'CAuthzURL', CAuthzURL) ;
            WriteString (section, 'ChallgToken', IcsEscapeCRLF(ChallgToken)) ;
            WriteString (section, 'ChallengeURL', ChallengeURL) ;
            WriteString (section, 'CPage', CPage) ;
            WriteString (section, 'CResp', IcsEscapeCRLF(CResp)) ;
            WriteString (section, 'CDNSValue', CDNSValue) ;
            WriteString (section, 'CAcmeAlpnCert', CAcmeAlpnCert) ; // V8.62
            WriteString (section, 'CStartDT', RFC3339_DateToStr(CStartDT)) ;
            WriteString (section, 'CDoneDT', RFC3339_DateToStr(CDoneDT)) ;
            WriteString (section, 'CValidResult', CValidResult) ;
        end;
    end;
    FControlFile.UpdateFile;  // write INI file

 // now update array
    Result := DBAddChallenge(Item);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.DBDeleteChallenge(const Domain: String): Boolean;
var
    section: string;
begin
    Result := False;
    if NOT DBOpenINI(FDirCertWork) then Exit;
    section := IcsLowerCase(CntlDBChallenge + Domain);
    if NOT FControlFile.SectionExists(section) then Exit;
    FControlFile.EraseSection(section);
    FControlFile.UpdateFile;  // write INI file

 // now update array
    Result := DBRemoveChallenge(DBFindChallengeNum(Domain));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslX509Certs.BuildSANList;
var
    flag: Boolean;
    I: Integer;
    PubDir: string;
begin
 // make sure common name is also in SANs, so we can ignore it subsequently
    flag := false;
    if FCertSubAltNames.Count > 0 then begin
        for I := 0 to FCertSubAltNames.Count - 1 do begin
            if FCertSubAltNames[I].SADomain <> fCertCommonName then flag := True;
        end;
    end;
    if NOT flag then begin
        PubDir := '';
        if FDirPubWebCert.Count > 0 then PubDir := FDirPubWebCert[0];
        FCertSubAltNames.AddItem(fCertCommonName, FDirWellKnown, PubDir, FCertApprovEmail);
    end;
    FCertSANTot := FCertSubAltNames.Count;
    FCertSANs.Clear;
    for  I := 0 to FCertSANTot - 1 do
        FCertSANs.Add(FCertSubAltNames[I].SADomain);
 end;


 {* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// set partial directory names for work and final certificate dictorties
function TSslX509Certs.SetPartFNames(ReadOnly: Boolean = False): Boolean;
var
    CN, NewDir: string;
    I: Integer;
begin
    FPartFNameWork := '';
    FPartFNameFinal := '';
    FPartFNameOrder := '';
    FPartFNameServer.Clear;
    FPartFNameServer.Sorted := True;
    FPartFNameServer.Duplicates := dupIgnore;
    FPartFNameServer.CaseSensitive := false;
    Result := False ;

  // check for domain
    if Pos ('.', FCertCommonName) = 0 then begin
        LogEvent ('Must specify host domain name');
        exit;
    end;

  // work dir here we will save our certificates and keys
    if NOT ReadOnly then begin
        if NOT ForceDirectories (FDirCertWork) then begin
            LogEvent ('Failed to create directory: ' + FDirCertWork);
            exit;
        end;
    end;

  // create certificate file name from domain common name, change . to _ and * to x
    CN := BuildCertName (FCertCommonName) ;

    FPartFNameWork := IncludeTrailingPathDelimiter(FDirCertWork) + FNewCertPrefix + 'work-' + CN ;
    if fSuppOrderId <> '' then begin
        FPartFNameOrder := IncludeTrailingPathDelimiter(FDirCertWork) + FNewCertPrefix + FSuppOrderId + '-' + CN ;
        FPartFNameWork := FPartFNameOrder;
    end;
    fPartFNameFinal := IncludeTrailingPathDelimiter(fDirCertWork) + CN ;

  // build list of remote web server certificate locations, ignoing duplicates
  // also check work directory and remote server are not the same
    if (FDirPubWebCert.Count > 0) then begin
        for I := 0 to FDirPubWebCert.Count - 1 do begin
            NewDir := IncludeTrailingPathDelimiter(FDirPubWebCert[I]);
            FDirPubWebCert[I] := NewDir;
            if NewDir <> fPartFNameFinal then
                FPartFNameServer.Add(NewDir);
        end;
    end;
    if (FCertSubAltNames.Count > 0) then begin
        for I := 0 to FCertSubAltNames.Count - 1 do begin
            NewDir := IncludeTrailingPathDelimiter(FCertSubAltNames[I].SADirPubWebCert);
            if NewDir <> fPartFNameFinal then
                FPartFNameServer.Add(NewDir);
        end;
    end;

 // see if creating remote directories
    if (NOT ReadOnly) and (FPartFNameServer.Count > 0) then begin
        for I := 0 to FPartFNameServer.Count - 1 do begin
            if NOT ForceDirectories (FPartFNameServer[I]) then begin
                LogEvent ('Failed to create certificate directory: ' + FPartFNameServer[I]);
                Exit;
            end;
        end;
    end;

 // finally add common domain name
    FPartFNameServer.Sorted := False;  // now editing list
    if (FPartFNameServer.Count > 0) then begin
        for I := 0 to FPartFNameServer.Count - 1 do begin
            FPartFNameServer[I] := IncludeTrailingPathDelimiter(FPartFNameServer[I]) + CN ;
        end;
    end;
    Result := True ;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslX509Certs.SetFullFileNames (const FileDir: String) ;
begin
    FFileCSR := FileDir + FileSuffCSR ;
    FFilePrvKey := FileDir + FileSuffPKey ;
    FFileCertPem := FileDir + FileSuffCertPem ;
    FFileInterPem := FileDir + FileSuffInterPem ;
    FFileBundPem := FileDir + FileSuffBundPem ;
    FFileBundP12 := FileDir + FileSuffBundP12 ;
    FFileBundP7 := FileDir + FileSuffBundP7 ;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// create new private key and certificate signing request
function TSslX509Certs.CreateKeyandReq: boolean;
var
    I: Integer;
begin
    Result := False ;

 // see if using old CSR
    if FCertCsrOrigin = CsrOriginFile then begin
        if NOT FNewSslCert.IsReqLoaded then begin
            LogEvent ('No Old Certificate Request Loaded: ' + FCertOldCsrFile);
            Exit;
        end;
        if NOT FNewSslCert.IsPKeyLoaded then begin
            LogEvent ('No Old Private Key Loaded: ' + FCertOldPrvKey);
            Exit;
        end;
    end
    else begin
        if (fCertCommonName = '') or (FCertSubAltNames.Count = 0) then begin
            LogEvent ('No Domain Names for Request');
            Exit;
        end;
        LogEvent ('Generating Private and Public Key Pair, Please Wait');
        try
            FNewSslCert.PrivKeyType := FPrivKeyType;
            FNewSslCert.PrivateKey := Nil;
            FNewSslCert.DoKeyPair;
            LogEvent ('Generated private and public key pair OK:' + IcsCRLF + FNewSslCert.PrivateKeyInfo);
        except
            on E:Exception do  begin
                LogEvent ('Failed to Generate Private Key - ' + E.Message);
                exit ;
            end;
        end;

        LogEvent ('Generating Certificate Signing Request');
        try
            FNewSslCert.X509Req := Nil;
            with fNewSslCert do begin
                CommonName := fCertCommonName;
                AltDNSList.Clear;
                for I := 0 to FCertSubAltNames.Count - 1 do begin
                    AltDNSList.Add(FCertSubAltNames[I].SADomain);
                end;
                CertDigest := fCertSignDigestType ;
                Country := FCertCountry;
                State := FCertState;
                Locality := FCertLocality;
                Organization := FCertOrganization;
                OrgUnit := FCertOrgUnit;
                Descr := FCertDescr;
                Email := FCertContactEmail;
            end;
            FNewSslCert.DoCertReqProps;
            LogEvent('Created Certificate Signing Request OK:' + IcsCRLF + FNewSslCert.ReqCertInfo);
        except
            on E:Exception do begin
                LogEvent ('Failed to Generate CSR - ' + E.Message);
                exit ;
            end;
        end;
    end;
    try
        FNewSslCert.PrivateKeySaveToPemFile (fFilePrvKey, FPrivKeyPassword, FPrivKeyCipher) ;
        fPrvKeyLines := FNewSslCert.SavePKeyToText (FPrivKeyPassword, FPrivKeyCipher);
        LogEvent ('Saved private key file: ' + fFilePrvKey) ;
        if FLogPkeys then LogEvent (IcsCRLF + fPrvKeyLines + IcsCRLF) ;
        FNewSslCert.SaveReqToFile(fFileCSR, true);
        fCSRLines := FNewSslCert.SaveReqToText (false) ;  // no comments, confused order
        LogEvent ('Saved certificate signing request file: ' + fFileCSR +
                                           IcsCRLF + IcsCRLF + fCSRLines + IcsCRLF) ;
    except
        on E:Exception do begin
            LogEvent ('Failed to Save CSR or Key - ' + E.Message);
            exit ;
        end;
    end;
    Result := true;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// check old CSR file and old private key files, keep common name and SANs
function TSslX509Certs.CheckCSR(RequirePkey: Boolean = True): Boolean;
var
    ReqSANs: TStringList;
    PubDir: String;
    I: Integer;
begin
    Result := False;
    if (FCertOldCsrFile = '') or (NOT FileExists(FCertOldCsrFile)) then begin
        LogEvent ('Can Not Find Old Certificate Signing Request File: ' + FCertOldCsrFile);
        Exit;
    end;
    if (FCertOldPrvKey = '') or (NOT FileExists(FCertOldPrvKey)) then begin
        LogEvent ('Can Not Find Old Private Key File: ' + FCertOldPrvKey);
        if RequirePkey then Exit;
    end;
    try
        FNewSslCert.LoadReqFromFile(FCertOldCsrFile);
        if NOT FNewSslCert.IsReqLoaded then begin
            LogEvent ('Failed to Load CSR File: ' + FCertOldCsrFile);
            Exit;
        end;
        LogEvent('Loaded Certificate Request OK' + IcsCRLF + FNewSslCert.ReqCertInfo);
        if (FCertOldPrvKey <> '') then begin
            try
                FNewSslCert.PrivateKeyLoadFromPemFile (FCertOldPrvKey, FPrivKeyPassword) ;
            except
                on E:Exception do begin
                    LogEvent ('Failed to Load Private Key File: ' + E.Message);
                end;
            end;
            if NOT FNewSslCert.IsPKeyLoaded then begin
                LogEvent ('Failed to Load Old Private Key File: ' + FCertOldPrvKey);
                if RequirePkey then Exit;
            end;
        end;
        FCertCommonName := FNewSslCert.ReqSubjCName;
        FCertSubAltNames.Clear;
        PubDir := '';
        if FDirPubWebCert.Count > 0 then PubDir := FDirPubWebCert[0];
        FCertSubAltNames.AddItem(FCertCommonName, FDirWellKnown, PubDir);
        ReqSANs := TStringList.Create;
        try
            ReqSANs.Text := FNewSslCert.ReqSubjAltNameDNS;
            if ReqSANs.Count > 0 then begin
                for I := 0 to ReqSANs.Count - 1 do begin
                    if (ReqSANs[I] <> FCertCommonName) then
                        FCertSubAltNames.AddItem(ReqSANs[I], FDirWellKnown, PubDir);
                end;
            end;
        finally
            ReqSANs.Free;
        end;
    except
        on E:Exception do begin
            LogEvent ('Failed to Load CSR File: ' + E.Message);
        end;
    end;

end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ saves up to three copies of all certificate files:
    1 - work directory, includes unique order number for historic purposes
    2 - work directory, final cert name without order, replacing older version
    3 - server directory, final cert name without order, replacing older version
  Also validates certificate chain to ensure intermediate matches and CA available
}
function TSslX509Certs.SaveCertificateFiles(const CertName: string): Boolean;
var
    P12KeyCipher: TSslPrivKeyCipher;
    P12Password: String;
    I: Integer;

    function SaveAllCerts: Boolean;
    begin
        Result := False;
        try
            if (FCSRLines <> '') and (OutFmtReq in FCertOutFmts) then begin
                SaveDataFile (FFileCSR, FCSRLines);
                LogEvent('Saved Certificate Request File: ' + FFileCSR);
            end;
            if (OutFmtSep in FCertOutFmts) then begin
                FNewSslCert.PrivateKeySaveToPemFile (FFilePrvKey, FPrivKeyPassword, FPrivKeyCipher);
                LogEvent ('Saved Private Key File: ' + FFilePrvKey);
                FNewSslCert.SaveToPemFile(FFileCertPem, False, True, False);  // no private key or inters
                LogEvent('Saved PEM Certficate Alone: ' + FFileCertPem);
                if FNewSslCert.IsInterLoaded then begin
                    FNewSslCert.SaveIntersToToPemFile(FFileInterPem, True);
                    LogEvent('Saved PEM Intermediate Certficate: ' + FFileInterPem);
                end;
            end;
            if (OutFmtBudl in FCertOutFmts) then begin
                FNewSslCert.SaveToPemFile(FFileBundPem, True, True, True, FPrivKeyPassword, FPrivKeyCipher);  // add private key and inters
                LogEvent('Saved PEM Bundle with Certficate, Key and Intermediate: ' + FFileBundPem);
            end;
            if (OutFmtP12 in FCertOutFmts) then begin
                FNewSslCert.SaveToP12File(fFileBundP12, P12Password, True, P12KeyCipher);  // add private key and inters
                LogEvent('Saved PKCS12 Bundle with Certficate, Key and Intermediate: ' + FFileBundP12);
            end;
            if (FNewCertP7Lines <> '') and (OutFmtP7 in FCertOutFmts) then begin
                SaveDataFile (FFileBundP7, FNewCertP7Lines) ;
                LogEvent('Saved PKCS7 bundle: ' + FFileBundP7);
            end;
            Result := True;
        except
            on E:Exception do begin
                LogEvent('Failed to Save File - ' + E.Message);
            end;
        end;
    end;

begin
    Result := False;
    LogTimeStamp;
    LogEvent ('Saving SSL Certificate Files for: ' + CertName);
    if FPartFNameOrder = '' then begin
        LogEvent('Can Not Save Certificate Files Without Directory');
        Exit ;
    end;
    SetFullFileNames (FPartFNameOrder);
    if (Pos(PEM_STRING_HDR_BEGIN, FNewCertLines) = 0) then begin
        LogEvent('Did Not Receive a Valid PEM Certificate');
        Exit ;
    end;

 // sanity check, must save some files
    if NOT ((OutFmtSep in FCertOutFmts) OR (OutFmtBudl in
                            FCertOutFmts) OR (OutFmtP12 in FCertOutFmts)) then
        FCertOutFmts := FCertOutFmts + [OutFmtSep];

 // Windows will not load PKCS12 file without a password, so create one if missing
    FPrivKeyPassword := Trim(FPrivKeyPassword);
    if (OutFmtP12 in FCertOutFmts) then begin
        P12KeyCipher := FPrivKeyCipher;
        P12Password := FPrivKeyPassword;
        if (P12KeyCipher = PrivKeyEncNone) or (P12Password = '') then begin
            P12KeyCipher := PrivKeyEncTripleDES;
            if (P12Password = '') then P12Password := 'password';
            LogEvent('Set Required PKCS12 File Password to "password"');
        end;
    end;

    try
        FNewSslCert.LoadFromText(FNewCertLines, croNo, croTry, '');   // look for intermediate cert
        if NOT FNewSslCert.CheckCertAndPKey then
            LogEvent ('!!! WARNING, Private Key Does Not Match Certificate Public Key');
        if (OutFmtSep in FCertOutFmts) then begin
           FNewSslCert.SaveToPemFile(FFileCertPem, False, True, False);  // no private key or inters
            LogEvent('Saved PEM Certficate Alone: ' + FFileCertPem);
            FFileFinalBundle := FFileCertPem; // in case no bundle specified
        end;
    except
        on E:Exception do begin
            LogEvent('Failed to Recognise Certificate - ' + E.Message);
            exit ;
        end;
    end;
    FNewCertCN := FNewSslCert.SubjectCName;
    if CertName <> FNewCertCN then
        LogEvent('Mismatch Subject Common Name, found: ' + FNewCertCN);
    FNewCertSAN := IcsUnwrapNames (FNewSslCert.SubAltNameDNS);
    LogEvent('Certificate Subject Alt Names (SAN): ' + FNewCertSAN);
    FNewCertEndDT := FNewSslCert.ValidNotAfter;
    FNewCertStartDT := FNewSslCert.ValidNotBefore;

    if NOT FNewSslCert.IsInterLoaded then begin
        LogEvent (IcsCRLF + 'PEM Intermediate Certificate' + IcsCRLF + FNewInterLines + IcsCRLF);
        if (Pos(PEM_STRING_HDR_BEGIN, FNewInterLines) = 0) then begin
            LogEvent ('Did Not Receive a Valid PEM Intermediate Certificate: ' + FNewInterLines);
            FNewInterLines := '';
        end
        else begin
            try
                if FNewInterLines <> '' then
                    FNewSslCert.LoadIntersFromString(FNewInterLines);
            except
                on E:Exception do begin
                    LogEvent('Failed to Recognise Intermediate Certificate - ' + E.Message);
                 end;
            end;
        end;
    end;
    if FNewSslCert.IsInterLoaded and (OutFmtSep in FCertOutFmts) then begin
        try
            FNewSslCert.SaveIntersToToPemFile(FFileInterPem, True);
            LogEvent('Saved PEM Intermediate Certficate: ' + FFileInterPem);
        except
            on E:Exception do begin
                LogEvent ('Failed to Recognise Intermediate Certificate - ' + E.Message);
             end;
        end;
    end;

    if (FNewCertP7Lines <> '') and (OutFmtP7 in FCertOutFmts) then begin
        LogEvent(IcsCRLF + 'PEM PKCS7 Certificate' + IcsCRLF + FNewCertP7Lines + IcsCRLF) ;
        SaveDataFile(FFileBundP7, FNewCertP7Lines) ;
    end;

 // log certificate content
    LogEvent (IcsCRLF + 'Certificate Details: ' + IcsCRLF +
                                   FNewSslCert.CertInfo(False) + IcsCRLF + IcsCRLF);

 // save PEM bundle file for Apache and PKCS12 bundle for Windows, both with key passworded
    try
        if (OutFmtBudl in FCertOutFmts) then begin
            FNewSslCert.SaveToPemFile(FFileBundPem, True, True, True, FPrivKeyPassword, FPrivKeyCipher);  // add private key and inters
            LogEvent('Saved PEM Bundle with Certficate, Key and Intermediate: ' + fFileBundPem);
            FFileFinalBundle := FFileBundPem;
        end;

        if (OutFmtP12 in FCertOutFmts) then begin
            FNewSslCert.SaveToP12File(FFileBundP12, P12Password, True, P12KeyCipher);  // add private key and inters
            LogEvent('Saved PKCS12 Bundle with Certficate, Key and Intermediate: ' + FFileBundP12);
            FFileFinalBundle := FFileBundP12;
        end;
    except
        on E:Exception do
        begin
            LogEvent ('Failed to Save Bundle - ' + E.Message);
        end;
    end;

// now validate and report certificate  chain
    try
        if NOT Assigned(FRootCAX509) then begin  { V8.55  }
            FRootCAX509 := TX509Base.Create (Self);
            FRootCAX509.LoadCATrustFromString(sslRootCACertsBundle);  // builtin roots
        end ;
        FNewSslCert.X509CATrust := FRootCAX509.X509CATrust;
     { V8.47 warning, currently only checking first Host name }
        FNewCertValRes := FNewSslCert.ValidateCertChain(CertName, FNewCertChainInfo, FNewCertErrs, 30);
        if FNewCertValRes = chainOK then
            LogEvent ('SSL Certificate Chain Validated OK: ' + IcsCRLF +
                                                FNewCertChainInfo + IcsCRLF + IcsCRLF)
        else begin
            if FNewCertValRes = chainWarn then
                FNewCertErrs := 'Chain Warning - ' + FNewCertErrs
            else begin
                FNewCertErrs := 'Chain Failed - ' + FNewCertErrs;
                LogEvent ('SSL Certificate Errors - ' + FNewCertErrs + IcsCRLF + IcsCRLF);
             end;
        end;
        FNewCertChainInfo := IcsEscapeCRLF(FNewCertChainInfo);
        FNewCertErrs := IcsEscapeCRLF(FNewCertErrs);
    except
        on E:Exception do begin
            LogEvent ('Failed to Validate Chain - ' + E.Message);
            Exit;
        end;
    end;
    FFileFinalCSR := FFileCSR;
    FFileFinalPrvKey := FFilePrvKey;
    FFileFinalCert := FFileCertPem;

// finally save files again without order number, locally
    LogEvent ('Saving final Versions Of All Files Without Order Numbers Locally');
    SetFullFileNames (FPartFNameFinal);
    if NOT SaveAllCerts then SaveAllCerts;  // one repeat

 // pending - did order succeed if some of this copying failed!!!!

// see if copying files to web server directories
    if (FPartFNameServer.Count > 0) then begin
        LogEvent ('Saving Final Versions Of All Files Without Order Numbers on Server');
        for I := 0 to FPartFNameServer.Count - 1 do begin
            SetFullFileNames (FPartFNameServer[I]);
            if NOT SaveAllCerts then begin
                if NOT SaveAllCerts then SaveAllCerts;  // two repeats
            end;
        end;
    end;
    LogEvent('Finished Collecting and Saving Certificate for ' + CertName + IcsCRLF + IcsCRLF);
    Result := True;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

function TSslX509Certs.RedistribteFiles: Boolean;
begin
    Result := False;
    if (fCertCommonName = '') then begin
        LogEvent('Must Specify Domain Common Name for Certifcate');
        Exit;
    end;

 // read internal variables and public properties from database, so same as order
    if NOT DBReadCNDomain(fCertCommonName, True) then Exit;
    if FIssueState < IssStateCollect then begin
        LogEvent('Certifcate Order Must Be Completed First');
        Exit;
    end;
    LogEvent ('Redistributing Old Certificate');
    FNewSslCert.ClearAll;
    try
        if FFileFinalBundle <> '' then
            FNewSslCert.LoadFromFile(FFileFinalBundle, croTry, croTry, FPrivKeyPassword);
        if NOT (FNewSslCert.IsCertLoaded and FNewSslCert.IsPKeyLoaded) then begin
            LogEvent('Failed to Read Certificate Bundle, Trying Separate Files');
            FNewSslCert.LoadFromFile(FFileFinalCert, croTry, croTry, FPrivKeyPassword);
            FNewSslCert.PrivateKeyLoadFromPemFile(FFileFinalPrvKey, FPrivKeyPassword);
        end;
    except
        on E:Exception do begin
            LogEvent ('Failed to Read Old Certificate - ' + E.Message);
            Exit;
        end;
    end;
    if NOT (FNewSslCert.IsCertLoaded and FNewSslCert.IsPKeyLoaded) then begin
        LogEvent ('Failed to Read Old Certificate - ' + FFileFinalBundle);
        Exit;
    end;
    if FNewSslCert.ValidNotAfter < IcsGetUTCTime then begin  { V8.61 }
        LogEvent ('Old Certificate Has Expired');
        Exit;
    end;
    fNewCertLines := FNewSslCert.SaveCertToText(False);

// save lots of certificates in different formats and places
    if NOT SaveCertificateFiles(fCertCommonName) then Exit;
    DBWriteCNDomain;
    if Assigned(FOnNewCert) then FOnNewCert(Self);
    Result := True;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslX509Certs.DumpJson(const Item: String = '');
begin
    if NOT FLogJson then Exit ;
    if FDebugLevel >= DebugBody then Exit; // already done it
    LogEvent('Response (length ' + IntToKbyte(Length(FHttpRest.ResponseRaw)) +
                                              ')' + IcsCRLF +  FHttpRest.ResponseRaw);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.CCGetRequest(HttpReq: THttpRequest;
                const PageURL: String; const RawParams: String = ''): boolean;
var
    FullURL: String;
begin
    Result := False;
    FullURL := FSupplierServer + PageURL;
    if (FOAExpireDT <= Now) or (FOAAccToken = '') then begin
        LogEvent('Failed, Authorization for CertCentre has expired');
        Exit;
    end;
    FHttpRest.AuthBearerToken := FOAAccToken;
    FHttpRest.ServerAuth := httpAuthBearer;
    FHttpRest.DebugLevel := FDebugLevel;
    FHttpRest.Agent := 'ICS-CertCentre-' + ComponentVersion; // V8.60
    FHttpRest.SocketFamily := FSocketFamily;        // V8.60 allow IPv6
    FHttpRest.ProxyURL := FProxyURL;                // V8.62 proxy support
    FAccountLastTick := IcsGetTickCount64;  { V8.63 idle account timeout }

    try
        FCCLastStatCode := FHttpRest.RestRequest(HttpReq, FullURL, false, RawParams);
    except
        on E:Exception do begin
            LogEvent('Failed to contact CertCentre Server: ' + E.Message);
            // don't exit, may still have something useful
        end;
    end;
    Result := (FHttpRest.ResponseRaw <> '');
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.SetCertCentre(CreateNew: Boolean = False): boolean;
begin
    Result := False;
    FSupplierProto := SuppProtoCertCentre;
    FIssueState := IssStateNone;
    FPendAccountClose := False; { V8.63 }
    if (NOT DBReadAccount(FDirCertWork, False)) and (NOT CreateNew) then Exit;

    // create account working directory and database INI file
    if CreateNew then begin
        LogEvent ('Checking Account Directory: ' + FDirCertWork);
        if NOT ForceDirectories(FDirCertWork) then begin
            LogEvent ('Failed to Create Directory: ' + FDirCertWork);
            exit;
        end;
        if NOT DBOpenINI(FDirCertWork, True) then Exit;
        DBWriteAccount;
    end;

    if Pos ('https://', FSupplierServer) <> 1 then begin
        LogEvent('Invalid Certificate Supplier Server: ' + FSupplierServer);
    end;
    FNewCertPrefix := 'CC-' ;

  // clear expired OAuth2 tokens
    SetOAuth2;
    if (FOAExpireDT <= Now) then begin
        FOAAccToken := '';
        FOARefreshToken := '';
        FOAExpireDT := 0;
    end;

  // report next refresh
    if (FRestOAuth.RefreshDT > Now) and FRestOAuth.RefreshAuto then
             LogEvent('Authorization token will Automatically Refresh at: ' +
                                                DateTimeToStr(FRestOAuth.RefreshDT));

  // no tokens, interactive session to login using browser
    DBWriteAccount;
    if (FOAAccToken = '') then begin
        if NOT FRestOAuth.StartAuthorization then Exit;
        LogEvent('OAuth2 Authorization Started, Login Using Browser');
        Exit;
    end;
    Result := True;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// CertCentre account information
function TSslX509Certs.CCGetProfile: boolean;
begin
// CertCentre account Profile
    Result := False;
    LogTimeStamp;
    LogEvent ('Downloading CertCentre Server Profile');
    FHttpRest.RestParams.Clear;
    if NOT CCGetRequest(HttpGET, 'Profile') then exit ;
    DumpJson;
    if FHttpRest.ResponseJson.S['success'] = 'false' then begin
        LogEvent ('Failed to get Profile: ' +  FHttpRest.ResponseJson.S['Message']);
        exit;
    end;

{ expect something like:
Currency=true
Country=
AuthorizationID=999993062
Timezone=Europe/Berlin
AuthType=OAUTH2
Scope=UI
OAuth2_Token=Gxxxxxxxxxxxxxxxx6DVFJJMY.oauth2.certcenter.com
CustomerID=103611
Locale=en_GB

or

success=false
Message=Authorization Failed
ErrorField=Authorization
ErrorId=-2004   }

    LogEvent (IcsCRLF + 'Downloading CertCentre Server Limit');
    FHttpRest.RestParams.Clear;
    if NOT CCGetRequest(HttpGET, 'Limit') then exit ;
    DumpJson;
    Result := CCGetProducts(False);
    if Result then begin
        FIssueState := IssStateAccount;
        DBWriteAccount;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.CCGetProducts(Log: Boolean = False): boolean;
var
    JsonItems: ISuperObject;
    I: integer;
begin
    Result := False;
    LogEvent (IcsCRLF + 'Downloading CertCentre Server Products');
    FHttpRest.RestParams.Clear;
    if NOT CCGetRequest (HttpGET, 'Products') then exit ;
    DumpJson;
    if FHttpRest.ResponseJson.S['success'] = 'false' then begin
        LogEvent ('Failed to get Products: ' +  FHttpRest.ResponseJson.S['Message']) ;
        exit ;
    end;
    JsonItems := FHttpRest.ResponseJson['Products'];
    FProductList.Clear ;
    if Assigned(JsonItems) then begin
        if JsonItems.AsArray.Length > 0 then begin
            for I := 0 to JsonItems.AsArray.Length - 1 do begin
                FProductList.Add(JsonItems.AsArray.S[I]) ;
                if Log then LogEvent (JsonItems.AsArray.S[I]) ;
            end;
            FProductList.Sort;
            LogEvent ('Found ' + IntToStr(FProductList.Count) + ' Certiticate Products');
            Result := True;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.CCGetOneProduct(const Product: String): boolean;
var
    mins: Integer;
begin
    Result := False;
    LogEvent (IcsCRLF + 'Downloading CertCentre Server ProductCode=' + Product);
    fProductJson := Nil;
    FProductInfo := '';
    FHttpRest.RestParams.Clear;
    FHttpRest.RestParams.PContent := PContUrlencoded;
    FHttpRest.RestParams.AddItem('ProductCode', Product, False);
    if NOT CCGetRequest (HttpGET, 'ProductDetails') then exit;
    DumpJson('ProductDetails');
     {   success=true
        Price=21.6
        MaxValidityPeriod=24
        SANHostPrice=0r
        Features=["DV"]
        RenewPeriod=90
        SANPackagePrice=0r
        Currency=GBP
        ProductType=SSL
        ProductName=RapidSSL
        ProductCode=GeoTrust.RapidSSL
        Licenses=0
        RefundPeriod=30
        CA=GeoTrust
        SANPackageSize=0
        SANMaxHosts=0
        DVAuthMethods=["FILE","DNS","EMAIL"]
        SANFeatures=["HostOnlyIncluded"]   }

    FProductJson := FHttpRest.ResponseJson['ProductDetails'];
    if NOT Assigned(FProductJson) then Exit;
    FProductDVAuth := fProductJson.S['DVAuthMethods'];
    if (Pos('[', FProductDVAuth) = 1) then
        FProductDVAuth := Copy (fProductDVAuth, 2, Length(fProductDVAuth) - 2);
    FProductFeatures :=  fProductJson.S['Features'];
    FProductCA := FProductJson.S['CA'];
    if (Pos('[', FProductFeatures) = 1) then
        FProductFeatures := Copy (FProductFeatures, 2, Length(FProductFeatures) - 2);
    FProductInfo := FProductJson.S['ProductName']  + IcsCRLF +
        'Cost ' + FProductJson.S['Price'] + ' ' + FProductJson.S['Currency'] + '/year' + IcsCRLF +
         'Max Validity: ' + FProductJson.S['MaxValidityPeriod'] + ' months, Features: ' +
         FProductFeatures + IcsCRLF  + 'CA: ' + FProductCA +
         ', Refund Period: ' + FProductJson.S['RefundPeriod'] + ' days' + IcsCRLF;
    FProductCertType := '';
    if FProductDVAuth <> '' then begin
        FProductInfo := FProductInfo + 'DV Methods: ' + FProductDVAuth + IcsCRLF;
        FProductCertType := 'DV';
    end
    else begin
        if (Pos('EV', fProductFeatures) > 0) then
            FProductCertType := 'EV'
        else if (Pos('OV', fProductFeatures) > 0) then
            FProductCertType := 'OV';
    end;
    FProductMaxSan := atoi (fProductJson.S['SANMaxHosts']);
    if (FProductMaxSan > 0) then
        FProductInfo := FProductInfo + 'SANMaxHosts: ' + IntToStr(FProductMaxSan) + ' at ' +
          fProductJson.S['SANHostPrice'] + ' ' + fProductJson.S['Currency'] + '/year each' + IcsCRLF;

  // estimate issuance time
    FHttpRest.RestParams.Clear;
    FHttpRest.RestParams.PContent := PContUrlencoded;
    FHttpRest.RestParams.AddItem('CA', FProductCA, False);
    FHttpRest.RestParams.AddItem('Type', FProductCertType, False);
    FHttpRest.RestParams.AddItem('Days', '30', False);  // days of old data
    if CCGetRequest (HttpGET, 'IssuanceTimes') then begin
        DumpJson;
(* {"top": 3.4,
    "median": 217.98,
    "prediction": 3.4,
    "success": true,
    "_meta": {"CA": "DigiCert", "Type": "DV", "Days": 30}}
 *)
        if FHttpRest.ResponseJson.B['success'] then begin
            mins := FHttpRest.ResponseJson.I['prediction'] + 1;  // round up
            FProductInfo := FProductInfo + 'Predicted Approval Duration: ';
            if mins <= 90 then
                FProductInfo := FProductInfo + IntToStr(mins) + ' mins'
            else
                FProductInfo := FProductInfo + IntToStr((mins div 60) + 1) + ' hours';
        end;
    end ;
    Result := True;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.CCGetApproverEmail: boolean;
var
    JsonItems: ISuperObject;
    I: integer;
    S: string ;
begin
    Result := False;
    if (FCertCommonName = '') or (FSuppCertProduct = '') then begin
        LogEvent ('Email Approver List needs certificate Common Name and Product');
        Exit;
    end;
    FApproverEmails.Clear;
    BuildSANList;
    LogEvent (IcsCRLF + 'Downloading CertCentre Approver List');
    FHttpRest.RestParams.Clear;
    FHttpRest.RestParams.PContent := PContUrlencoded;
    FHttpRest.RestParams.AddItem('ProductCode', FSuppCertProduct, False);
    FHttpRest.RestParams.AddItem('CommonName', FCertCommonName, False);
    if FCertSANTot > 1 then
        FHttpRest.RestParams.AddItem('DNSNames', FCertSANs.CommaText, False);
    if NOT CCGetRequest (HttpGET, 'ApproverList') then exit ;
    DumpJson;
(* {"DomainApprovers":
     {"DomainApprover": [
         {"Domain": "telecom-tariffs.co.uk",
         "Approvers": [
           {"ApproverEmail": "admin@telecom-tariffs.co.uk", "ApproverType": "Generic"},
           {"ApproverEmail": "administrator@telecom-tariffs.co.uk", "ApproverType": "Generic"},
           {"ApproverEmail": "hostmaster@telecom-tariffs.co.uk", "ApproverType": "Generic"},
           {"ApproverEmail": "webmaster@telecom-tariffs.co.uk", "ApproverType": "Generic"},
           {"ApproverEmail": "postmaster@telecom-tariffs.co.uk", "ApproverType": "Generic"},
           {"ApproverEmail": "admin@test2.telecom-tariffs.co.uk", "ApproverType": "Generic"},
           {"ApproverEmail": "administrator@test2.telecom-tariffs.co.uk", "ApproverType": "Generic"},
           {"ApproverEmail": "hostmaster@test2.telecom-tariffs.co.uk", "ApproverType": "Generic"},
           {"ApproverEmail": "webmaster@test2.telecom-tariffs.co.uk", "ApproverType": "Generic"},
           {"ApproverEmail": "postmaster@test2.telecom-tariffs.co.uk", "ApproverType": "Generic"}
         ]}
     ]},
     "ApproverList": [
       {"ApproverEmail": "admin@telecom-tariffs.co.uk", "ApproverType": "Generic"},
       {"ApproverEmail": "administrator@telecom-tariffs.co.uk", "ApproverType": "Generic"},
       {"ApproverEmail": "hostmaster@telecom-tariffs.co.uk", "ApproverType": "Generic"},
       {"ApproverEmail": "webmaster@telecom-tariffs.co.uk", "ApproverType": "Generic"},
       {"ApproverEmail": "postmaster@telecom-tariffs.co.uk", "ApproverType": "Generic"},
       {"ApproverEmail": "admin@test2.telecom-tariffs.co.uk", "ApproverType": "Generic"},
       {"ApproverEmail": "administrator@test2.telecom-tariffs.co.uk", "ApproverType": "Generic"},
       {"ApproverEmail": "hostmaster@test2.telecom-tariffs.co.uk", "ApproverType": "Generic"},
       {"ApproverEmail": "webmaster@test2.telecom-tariffs.co.uk", "ApproverType": "Generic"},
       {"ApproverEmail": "postmaster@test2.telecom-tariffs.co.uk", "ApproverType": "Generic"}
     ],
     "success": true}
*)
    if FHttpRest.ResponseJson.S['success'] = 'false' then
        LogEvent ('Failed to get Approver List: ' +  FHttpRest.ResponseJson.S['Message'])
    else
    begin
        JsonItems := FHttpRest.ResponseJson['ApproverList'];
        if Assigned (JsonItems) then begin
            if JsonItems.AsArray.Length > 0 then
            begin
                for I := 0 to JsonItems.AsArray.Length - 1 do begin
                    if JsonItems.AsArray.O[I].S['ApproverType'] <> 'Manual' then begin
                        S := JsonItems.AsArray.O[I].S['ApproverEmail'] ;
                        FApproverEmails.Add (S) ;
                        LogEvent (S) ;
                    end;
                end;
                Result := True;
            end;
        end;
    end;
end ;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// CertCentre check order for a SSL certificate
function TSslX509Certs.CCCheckOrder(DomainCheck: Boolean = True;
                                        UpdateDB: Boolean = False): Boolean;
var
    S, FullName: string;
    I, PeriodMonths: Integer;
begin
    Result := false;

    // see if using details from old CSR
    FNewSslCert.DoClearCerts;
    if FCertCsrOrigin = CsrOriginFile then begin
        if NOT CheckCSR(True) then Exit;  // sets CommonName and SANs
    end;

// initial set-up
    if (FCertCommonName = '') then begin
        LogEvent('Must Specify Domain Common Name for Certifcate');
        Exit;
    end;
    if (FSuppCertProduct = '') then begin
        LogEvent('Must Specify Certificate Product');
        Exit;
    end;

    FIssueState := IssStateNone;

 // read internal variables, but not saved public properties, they may be new
    DBReadCNDomain(fCertCommonName, False);  // ignore errors, may be new domain
    if FIssueState > IssStateChecked then FIssueState := IssStateNone;   // reset old order
    LogTimeStamp;
    LogEvent ('Checking CertCentre Certificate Order for: ' + fCertCommonName);

// check we have product details
    if FProductFeatures = '' then begin
        if NOT CCGetOneProduct(FSuppCertProduct) then Exit;
    end;

 // make sure common name is also in SANs, so we can ignore it subsequently
    BuildSANList;

 // validate some options
    if (fSuppCertChallenge in [ChallAlpnUNC, ChallAlpnUNC, ChallAlpnApp]) then begin
        LogEvent ('ALPN SSL Validation Not Available for this Supplier');
        Exit;
    end;

  // see is need to start local web server
    if DomainCheck and (fSuppCertChallenge in [ChallFileSrv]) then begin
        if NOT StartDomSrv('', '') then Exit;
    end;

  // check challenges and if domain is available for Well-Known
    try // except
        LogTimeStamp;
        LogEvent ('Checking CertCentre ' + FSuppCertProduct + ' certificate order for: ' + fCertCommonName);

        if Pos ('DV', FProductFeatures) > 0 then begin
            if (fSuppCertChallenge <= ChallFileSrv) and (Pos ('FILE', FProductDVAuth) = 0) then begin
                LogEvent ('FILE validation not available for this certificate');
                Exit;
            end;
            if (fSuppCertChallenge = ChallDNS) and (Pos ('DNS', FProductDVAuth) = 0) then begin
                LogEvent ('DNS validation not available for this certificate');
                Exit;
            end;
            if (fSuppCertChallenge = ChallEmail) and (Pos ('EMAIL', FProductDVAuth) = 0) then begin
                LogEvent ('EMAIL validation not available for this certificate');
                Exit;
            end;

          // where the well known directory is located for rach domain
            if DomainCheck then begin
                if FIssueState < IssStateChecked then begin
                    if (fSuppCertChallenge in [ChallFileUNC, ChallFileFtp, ChallFileSrv]) then begin
                        for I := 0 to FCertSubAltNames.Count - 1 do begin
                            if NOT TestWellKnown(FCertSubAltNames[I].SADomain,
                                            FCertSubAltNames[I].SADirWellKnown) then exit;
                        end;
                    end;
                end;
            end;
        end;

    // commercial cerrts, find price
        if fCertValidity > 365 then  // days
            PeriodMonths := 24
        else
            PeriodMonths := 12;
        LogEvent ('Getting quote at CertCentre for: ' + FSuppCertProduct );
        FHttpRest.RestParams.Clear;
        FHttpRest.RestParams.PContent := PContUrlencoded;
        FHttpRest.RestParams.AddItem('ProductCode', FSuppCertProduct, False);
        FHttpRest.RestParams.AddItem('ValidityPeriod', IntToStr (PeriodMonths), False);
        FHttpRest.RestParams.AddItem('ServerCount', '0', False);
        FHttpRest.RestParams.AddItem('SubjectAltName', IntToStr(FCertSANTot{ - 1}), False);
         if NOT CCGetRequest (HttpGET, 'Quote') then exit ;
        DumpJson;
        if FHttpRest.ResponseJson.B['success'] then begin
            FProductQuote := FHttpRest.ResponseJson.S['Price'] + ' ' + FHttpRest.ResponseJson.S['Currency'] ;
            LogEvent ('Price: ' + FProductQuote) ;
            // ask client if happy!!!
        end
        else
            LogEvent ('Failed to get quote: ' + FHttpRest.ResponseJson.AsString);

        LogEvent (IcsCRLF + 'Getting User Agreement at CertCentre for: ' + FSuppCertProduct );
        FHttpRest.RestParams.Clear;
        FHttpRest.RestParams.PContent := PContUrlencoded;
        FHttpRest.RestParams.AddItem('ProductCode', FSuppCertProduct, False);
        if NOT CCGetRequest (HttpGET, 'UserAgreement') then exit ;
        DumpJson;
        if FHttpRest.ResponseJson.B['success'] then  begin
            S := FHttpRest.ResponseJson.S['UserAgreement'] + IcsCRLF;
            FullName := fDirCertWork + FSuppCertProduct + '.txt';
            LogEvent ('Saving user agreement as: ' + FullName);
            SaveDataFile (FullName, S);
            // ask client if happy!!!
        end
        else
            LogEvent ('Failed to get User Agreement: ' + FHttpRest.ResponseJson.AsString);

    except
        on E:Exception do begin
            LogEvent ('Failed to check order - ' + E.Message);
            exit ;
        end;
    end;
    if DomainCheck then FIssueState := IssStateChecked;
    if UpdateDB then begin
        if DBWriteCNDomain then   // write database
            LogEvent ('Saved Domain to Database: ' + fCertCommonName)
        else
            LogEvent ('Failed to Save Domain to Database: ' + fCertCommonName);
    end;
    Result := true ;
 end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// CertCentre order a SSL certificate for an existing
// live HTTP web site whose Well-Known local directory we can access
// from this PC via a UNC path

function TSslX509Certs.CCOrderCert: Boolean;
var
    success: Boolean ;
    SigHash, AuthMethod, Partnerorderid, OrderDT: string ;
    JsonItems, JsonOrderParam, JsonContact, JsonOrg, JsonAddr: ISuperObject;
    SANArray, DomAppArray: ISuperObject;
    HashMd5, HashSha256, UniqueValue: string;
    I, PeriodMonths: Integer;
    CurChallenge: TChallengeItem;

    function SaveFileChallg (FileAuth: ISuperObject): boolean;
    var
        FQDNs: ISuperObject;
        DataFName, DataFPath: string;
        I, TotDom: Integer;
    begin
        Result := false;
        CurChallenge.CCommonName := fCertCommonName;
        CurChallenge.CSuppOrderId := FSuppOrderId;
        CurChallenge.CSupplierProto := FSupplierProto;
        CurChallenge.CType := fSuppCertChallenge;
        CurChallenge.CIssueState := IssStateChallgPend;
        CurChallenge.CStartDT := Now;
(* {
  {"FileAuthDetails":
      {"FileContents": "201808220846340t719hx014iwe942xiz4jxfnu80wc2qrq0u4idw0l49rejb5b3",
       "FilePath": "/.well-known/pki-validation",
       "FQDNs": ["test2.telecom-tariffs.co.uk"],
       "FileName": "fileauth.txt"
     },
  "success": true}
*)
        try
            DataFName := FileAuth.S['FileName'];   // expect fileauth.txt
            DataFPath := FileAuth.S['FilePath'];   // expect /.well-known/pki-validation
            CurChallenge.ChallgToken := FileAuth.S['FileContents']; // beware may have CRLF
            FQDNs := FileAuth.O['FQDNs'];   // array of names
            TotDom := FQDNs.AsArray.Length;
            if TotDom <= 0 then  begin
                LogEvent ('Failed to parse json FileAuthDetails, No Domains Found');
                exit ;
            end;
            DataFPath := StringReplace (DataFPath, '\/', '/', [rfReplaceAll]); //  unescape /
        except
            on E:Exception do begin
                LogEvent ('Failed to parse Json FileAuthDetails');
                exit ;
            end;
        end;
        for I := 0 to TotDom - 1 do begin
            CurChallenge.CDomain := FQDNs.AsArray.S[I];
            CurChallenge.CSanIdx := DBFindSAN(CurChallenge.CDomain);
            if CurChallenge.CSanIdx < 0 then begin  // sanity check
                CurChallenge.CSanIdx := 0;
                LogEvent('!!! Failed to Find Sub Alt Name for ' + CurChallenge.CDomain);
            end;
            CurChallenge.ChallengeURL := 'http://' + CurChallenge.CDomain + DataFPath + '/' + DataFName;
            if Pos ('/.well-known/', DataFPath) = 1 then DataFPath := Copy (DataFPath, 14, 99) ;
            if fSuppCertChallenge in [ChallFileSrv] then
                CurChallenge.CPage := DataFPath + '/' + DataFName  // URL path
            else
                CurChallenge.CPage := DataFPath + '\' + DataFName; // file path
            CurChallenge.CResp := CurChallenge.ChallgToken;
            CurChallenge.CDirWellKnown := FCertSubAltNames[CurChallenge.CSanIdx].SADirWellKnown;
            CurChallenge.CDirPubWebCert := FCertSubAltNames[CurChallenge.CSanIdx].SADirPubWebCert;

            if (fSuppCertChallenge = ChallFileUNC) then begin
                if CurChallenge.CDirWellKnown <> '' then begin
                    CurChallenge.CWKFullName := FDirWellKnown + CurChallenge.CPage;
                    LogEvent ('Built domain validation file name: ' + CurChallenge.CWKFullName + ', saving token: ' + CurChallenge.CResp);
                    if NOT SaveDataFile (CurChallenge.CWKFullName, CurChallenge.CResp) then Exit ;
                    Result := true;
                end
                else
                    LogEvent ('Challenge Failed, No Well-Known Directory Found');
            end;

        // FTP handled by application
           if (CurChallenge.CType = ChallFileFtp) then begin
                CurChallenge.CWKFullName := FDirCertWork + CurChallenge.CPage;
                LogEvent ('Built domain validation file name: ' + CurChallenge.CWKFullName + ', saving token: ' + CurChallenge.CResp);
                if NOT SaveDataFile (CurChallenge.CWKFullName, CurChallenge.CResp) then Exit ;
                LogEvent ('!!! Must FTP Challege File to .Well-Known Directory: ' + CurChallenge.CWKFullName);
                if Assigned(FonChallengeFTP) then begin
                    FonChallengeFTP(Self, CurChallenge);
                    Result := True;
                end;
            end;

        // nothing to do for local web server except start it
           if (CurChallenge.CType = ChallFileSrv) then begin
                if NOT StartDomSrv('', '') then Exit;
                LogEvent ('Local web server will respond to .Well-Known URL: ' + CurChallenge.ChallengeURL);
                Result := True;
            end;

         // update SANs
            FCertSubAltNames[CurChallenge.CSanIdx].SAIssueState := CurChallenge.CIssueState;
            FCertSubAltNames[CurChallenge.CSanIdx].SAStartDT := CurChallenge.CStartDT;
            FCertSubAltNames[CurChallenge.CSanIdx].SADoneDT := CurChallenge.CDoneDT;

         // update database with new challenge
            if (DBWriteOneChallenge(CurChallenge) < 0) then
                    LogEvent('Failed to Update Challenge Database');
        end;
    end;

    function SaveDNSChallg (DNSAuth: ISuperObject): boolean;
    var
        FQDNs: ISuperObject;
        DnsEntry: String;
        I, TotDom: Integer;
    begin
        Result := false;
        CurChallenge.CCommonName := fCertCommonName;
        CurChallenge.CSuppOrderId := FSuppOrderId;
        CurChallenge.CSupplierProto := FSupplierProto;
        CurChallenge.CType := fSuppCertChallenge;
        CurChallenge.CIssueState := IssStateChallgPend;
        CurChallenge.CStartDT := Now;
(*{
  {"DNSAuthDetails":
    `{"PointerType": "TXT",
      "DNSEntry": "test7.telecom-tariffs.uk",
      "DNSValue": "201808231308575pnkcwdtwqbck7lu689q5fgznadwile27x7eitvltczjsrm7w5",
      "Example": "test7.telecom-tariffs.uk. 60 IN TXT \"201808231308575pnkcwdtwqbck7lu689q5fgznadwile27x7eitvltczjsrm7w5\"",
      "FQDNs": ["test7.telecom-tariffs.uk"]},
  "success": true}
*)
        try
            CurChallenge.ChallgToken := DNSAuth.S['DNSValue'];
            CurChallenge.ChallengeURL := DNSAuth.S['Example'];
            DnsEntry := DNSAuth.S['DNSEntry'];  // domain name, repeated in FQDNs
            CurChallenge.CAuthzURL := DNSAuth.S['PointerType'];
            LogEvent (DNSAuth.AsString);   // TEMP
            FQDNs := DNSAuth.O['FQDNs'];   // array of names
            TotDom := FQDNs.AsArray.Length;
            if TotDom <= 0 then  begin
                LogEvent ('Failed to parse json DNSAuthDetails, No Domains Found');
                exit ;
            end;
        except
            on E:Exception do begin
                LogEvent ('Failed to parse Json FileAuthDetails');
                exit ;
            end;
        end;
        for I := 0 to TotDom - 1 do begin
            CurChallenge.CDomain := FQDNs.AsArray.S[I];
            CurChallenge.CSanIdx := DBFindSAN(CurChallenge.CDomain);
            if CurChallenge.CSanIdx < 0 then begin  // sanity check
                CurChallenge.CSanIdx := 0;
                LogEvent('!!! Failed to Find Sub Alt Name for ' + CurChallenge.CDomain);
            end;
            CurChallenge.CPage :=  CurChallenge.CDomain;
            CurChallenge.CDNSValue := CurChallenge.ChallgToken;
            LogEvent ('!!! Add DNS ' + CurChallenge.CAuthzURL + ' Record for: ' + CurChallenge.CPage + ', with: ' + CurChallenge.CDNSValue);
            LogEvent ('!!! Example: ' + CurChallenge.ChallengeURL);
            if Assigned(FOnChallengeDNS) then FOnChallengeDNS(Self, CurChallenge);

         // update SANs
            FCertSubAltNames[CurChallenge.CSanIdx].SAIssueState := CurChallenge.CIssueState;
            FCertSubAltNames[CurChallenge.CSanIdx].SAStartDT := CurChallenge.CStartDT;
            FCertSubAltNames[CurChallenge.CSanIdx].SADoneDT := CurChallenge.CDoneDT;

         // update database with new challenge
            if (DBWriteOneChallenge(CurChallenge) < 0) then begin
                LogEvent('Failed to Update Challenge Database');
                Exit;
            end;
        end;
        Result := True;
    end;

begin
    Result := False;

    if (fCertCommonName = '') then begin
        LogEvent ('Must specify Domain Common Name to place order');
        Exit;
    end;
    if (FSuppCertProduct = '') then begin
        LogEvent ('Must specify certifcate product to place order');
        Exit;
    end;

 // check challenge allowed,  and well known directory for each domain on certificate
 // loads internal variables from database
    if FIssueState <> IssStateChecked then begin
        if NOT CCCheckOrder(True, True) then Exit;    // update database
    end;

    try // except
        LogTimeStamp;
        LogEvent ('Starting CertCentre ' + FSuppCertProduct + ' certificate order for: ' + fCertCommonName);
        fSuppOrderId := '' ;
        HashMd5 := '';   // used for Comondo file validation
        HashSha256 := '';
        UniqueValue := '';
        if NOT SetPartFNames (False) then Exit ;  // will only set short path names, no orderid yet

        case fSuppCertChallenge of
            ChallFileUNC: AuthMethod := 'FILE';
            ChallFileFtp: AuthMethod := 'FILE';
            ChallFileSrv: AuthMethod := 'FILE';
            ChallDNS:     AuthMethod := 'DNS';
            ChallEmail:   AuthMethod := 'EMAIL';
            else begin
                LogEvent ('Unsupported Challenge Method');
                Exit;
            end;
        end;

    // new order so clear stuff from last order
        FPartFNameFinal := '';
        FPartFNameServer.Clear;
        FFileFinalCSR := '';
        FFileFinalPrvKey := '';
        FFileFinalBundle := '';
        FOrderStartDT := Now;
        FChallgStartDT := 0; ;
        FChallgDoneDT := 0;
        FOrderCertsDT := 0;
        FOrderAttempts := FOrderAttempts + 1;
        FNewCertCN := '';
        FNewCertSAN := '';
        FNewCertValRes := chainFail;
        FNewCertErrs := '';
        FNewCertChainInfo := '';
        FNewCertEndDT := 0;
        FNewCertStartDT := 0;
        FPendingChallg := 0;

    // start timer so order completes automatically
        if FAutoOrderComplete and (NOT FChallengeTimer.Enabled) then
                                          FChallengeTimer.Enabled := True;
     // order info
        FNewOrderNum := DBNewOrderNum;
        FSuppOrderRef := 'ICS-' + IntToStr(FNewOrderNum);

      // work file names
        SetFullFileNames (FPartFNameWork);

     // step one
        if fCertValidity > 365 then  // days
            PeriodMonths := 24
        else
            PeriodMonths := 12;

     // step two - create private key and CSR
        if NOT CreateKeyandReq then exit ;
        if FNewSslCert.PrivKeyType >= PrivKeyECsecp256 then
            SigHash := 'SHA256-ECC-HYBRID'
     //   SigHash := 'SHA256-ECC-FULL'   //   Symantec only
        else
            SigHash := 'SHA256-FULL-CHAIN' ;   // RSA only

     // step three - optional
        LogEvent (IcsCRLF + 'Validate certificate request at CertCentre');
        FHttpRest.RestParams.Clear;
        FHttpRest.RestParams.PContent := PContJson;
        FHttpRest.RestParams.AddItem('CSR', fCSRLines, True);
        if NOT CCGetRequest (HttpPOST, 'ValidateCSR') then exit ;
        DumpJson;
(* {"ParsedCSR":
        {"Locality": "Croydon",
         "Country": "GB",
         "CommonName": "test2.telecom-tariffs.co.uk",
         "UniqueValue": "042E44BD69FD9644F1BB",
         "State": "Surrey",
         "SignaturAlgorithm": "sha256WithRSAEncryption",
         "Organization": "Magenta Systems Ltd",
         "Email": "angus@magsys.co.uk",
         "KeyLength": 2048,
         "OrganizationUnit": "Development Testing",
         "KeyEncryptionAlgorithm": "RSA",
         "HashSHA256": "EDBAB518B7E0C16AE073C23670AC3BD015454A19B12482A5F00FDF22E174D033",
         "HashMD5": "EACEC2AB10A98834047D67ED7E34B6FB"
     },
     "success": true} *)
        success := FHttpRest.ResponseJson.B['success'];
        if NOT success then begin
            LogEvent ('Failed to validate CSR: ' +  FHttpRest.ResponseJson.S['Message']);
            exit;
        end;
        LogEvent ('Validated CSR OK: Common Name: ' +  FHttpRest.ResponseJson.S['ParsedCSR.CommonName'] +
           ', Key: ' +  FHttpRest.ResponseJson.S['ParsedCSR.KeyEncryptionAlgorithm'] +
           ', Length: ' +  FHttpRest.ResponseJson.S['ParsedCSR.KeyLength'] +
           ', Signature: ' +  FHttpRest.ResponseJson.S['ParsedCSR.SignaturAlgorithm'] );

    // used for Comondo file validation - not sure we care since order supplies the same info
        HashMd5 := FHttpRest.ResponseJson.S['ParsedCSR.HashMD5'];
        HashSha256 := FHttpRest.ResponseJson.S['ParsedCSR.HashSHA256'];
        UniqueValue := FHttpRest.ResponseJson.S['ParsedCSR.UniqueValue'];
        DBWriteCNDomain;

     // step five  real order
        LogEvent (IcsCRLF + 'Ordering ' + FSuppCertProduct + ' certifcate from CertCentre');
        FHttpRest.RestParams.Clear;
        FHttpRest.RestParams.PContent := PContJson;
        JsonOrderParam := SO(['CSR', fCSRLines, 'ProductCode', FSuppCertProduct,
                           'ValidityPeriod',  PeriodMonths,
                          'SignatureHashAlgorithm', SigHash, 'PartnerOrderID', FSuppOrderRef,
                          'ApproverEmail', fCertApprovEmail ] );
        JsonOrderParam.S['DVAuthMethod'] := AuthMethod;
        if FCertSubAltNames.Count > 1 then begin
            SANArray := SA([]);
            DomAppArray := SA([]);
            for I := 0 to FCertSubAltNames.Count - 1 do begin
             //   if FCertSubAltNames[I].SADomain = FCertCommonName then Continue;
                SANArray.S[''] := FCertSubAltNames[I].SADomain;
                DomAppArray.O[''] := SO(['Domain', FCertSubAltNames[I].SADomain,
                      'Approvers', '[' + FCertSubAltNames[I].SAApprovalEmail + ']' ]);
            end;
            JsonOrderParam.O['SubjectAltNames'] := SANArray;
            if AuthMethod = 'EMAIL' then
                JsonOrderParam.O['DomainApprovers'] := DomAppArray;
        end;
        JsonAddr := SO(['AddressLine1', FCertAddress, 'PostalCode', FCertPostcode,
                        'City', FCertLocality, 'Region', FCertState,
                        'Country', FCertCountry ]) ;
        JsonOrg := SO(['OrganizationName', FCertOrganization,
                            'OrganizationAddress', JsonAddr,
                             'Phone', FCertPhone, 'Email', FCertContactEmail ]);
        JsonContact := SO(['Title', FCertContactTitle, 'FirstName', FCertContactFirst,
                             'LastName', FCertContactLast, 'OrganizationAddress', JsonAddr,
                             'OrganizationName', FCertOrganization,
                             'Phone', FCertPhone, 'Email', FCertContactEmail ]);
    {    JsonItems := SO(['OrderParameters', JsonOrderParam, 'OrganizationInfo', JsonOrg,
                             'AdminContact', JsonContact, 'TechContact', JsonContact,
                             'ApproverEmail', FCertApprovEmail ]) ;  }

  { V8.62 RestParams can now nest Json }
        FHttpRest.RestParams.AddItem('OrderParameters', JsonOrderParam.AsJson(false,false), True);
        FHttpRest.RestParams.AddItem('OrganizationInfo', JsonOrg.AsString, True);
        FHttpRest.RestParams.AddItem('AdminContact', JsonContact.AsString, True);
        FHttpRest.RestParams.AddItem('TechContact', JsonContact.AsString, True);
        FHttpRest.RestParams.AddItem('ApproverEmail', fCertApprovEmail, False);
        LogEvent (String(FHttpRest.RestParams.GetParameters));
        if NOT CCGetRequest (HttpPOST, 'Order') then exit;
        DumpJson;
(*
    {"Timestamp": "2018-08-22T11:46:37Z",
    "OrderParameters": {
        "ProductCode": "AlwaysOnSSL.AlwaysOnSSL",
        "ValidityPeriod": 365,
        "DVAuthMethod": "FILE",
        "PartnerOrderID": "ICS-1001",
        "SubjectAltNameCount": 0,
        "ApproverEmail": "admin@telecom-tariffs.co.uk",
        "ServerCount": 0,
        "CSR": "-----BEGIN CERTIFICATE REQUEST-----\nxx-----END CERTIFICATE REQUEST-----\n",
        "SignatureHashAlgorithm": "SHA256-FULL-CHAIN"
    },
    "CertCenterOrderID": 6352839,
    "success": true,
    "Fulfillment": {
        "Certificate_PKCS7": "-----BEGIN PKCS #7 SIGNED DATA-----\nxx-----END PKCS #7 SIGNED DATA-----",
        "Intermediate": "-----BEGIN CERTIFICATE-----\nxx-----END CERTIFICATE-----",
        "EndDate": "2019-08-22T11:46:37Z",
        "Certificate": "-----BEGIN CERTIFICATE-----\nx----END CERTIFICATE-----",
        "StartDate": "2018-08-22T11:46:37Z"
    }}

{"Errors": [
 {"ErrorMsg": "DNS entry not found.",
 "Message": "File or DNS entry not found or invalid",
 "ErrorField": "failed_dns", "ErrorId": -3202}
 ],"success": false}

    {"Timestamp": "2018-08-24T10:46:20Z",
     "OrderParameters": {
       "ProductCode": "GeoTrust.RapidSSL",
       "ValidityPeriod": 24,
       "DVAuthMethod": "FILE",
       "PartnerOrderID": "ICS-1001",
       "SubjectAltNameCount": 0,
       "ApproverEmail": "admin@telecom-tariffs.uk",
       "ServerCount": 0, "CSR": "-----BEGIN CERTIFICATE REQUEST-----\nxxx\n",
       "SignatureHashAlgorithm": "SHA256-FULL-CHAIN"},
       "CertCenterOrderID": 6353210,
       "success": true,
       "FileAuthDetails": {
            "FileContents": "23gsbsyw7q1tq11r44qy0w4ds7cfgb7j",
            "FilePath": "/.well-known/pki-validation",
            "FQDNs": ["test8.telecom-tariffs.uk"],
            "FileName": "fileauth.txt"
       }
    }

*)
        success := FHttpRest.ResponseJson.B['success'];
        if NOT success then begin
            try
                FLastErrMsg := FHttpRest.ResponseJson.S['Message'] ;
                if FLastErrMsg <> '' then
                    FLastErrMsg := fLastErrMsg + ' - ' + FHttpRest.ResponseJson.S['ErrorField']
                else begin
                    FLastErrMsg := FHttpRest.ResponseJson.S['Errors[0].Message']  + ' - ' +
                                     FHttpRest.ResponseJson.S['Errors[0].ErrorMsg'] + ' - ' +
                                                FHttpRest.ResponseJson.S['Errors[0].ErrorField'] ;
                end;
                LogEvent ('Failed to submit CSR and Order: ' +  fLastErrMsg);
            //    LogEvent ('Response: ' +  FHttpRest.ResponseJson.AsString);
            except
                LogEvent ('Failed to interpret order errors');
                LogEvent ('Response: ' +  FHttpRest.ResponseJson.AsString);
            end;

            FIssueState := IssStateNone;
            RemoveChallgs(FCertCommonName);
            FChallgDoneDT := Now;
            for I := 0 to FCertSubAltNames.Count - 1 do begin
                FCertSubAltNames[I].SAIssueState := FIssueState;
                FCertSubAltNames[I].SAValidResult := FLastErrMsg;
            end;
            DBWriteCNDomain;
            exit;
        end;

     // step six - save order information, might have certificate as well or a hash for FILE authentication
        FSuppOrderId := FHttpRest.ResponseJson.S['CertCenterOrderID'];  // very important !!
        OrderDT  := FHttpRest.ResponseJson.S['Timestamp'];
        Partnerorderid := FHttpRest.ResponseJson['OrderParameters'].S['PartnerOrderID'];
        LogEvent ('Succesfully ordered ' + FSuppCertProduct + ' certifcate for ' + fCertCommonName +
                      ', CertCenterOrderID: ' + fSuppOrderId + ', at ' + OrderDT +
                                                          ', PartnerOrderID: ' + Partnerorderid);

    // fail now if can not create all file directories
        if NOT SetPartFNames (False) then Exit ;  // set long path name with orderid
        SetFullFileNames (FPartFNameOrder) ;
        FNewSslCert.PrivateKeySaveToPemFile (FFilePrvKey, '', PrivKeyEncNone) ;
        LogEvent ('Saved private key file: ' + FFilePrvKey) ;
        FNewSslCert.SaveReqToFile(fFileCSR, true);
        LogEvent ('Saved certificate request file: ' + FFileCSR) ;

    // see if we have certificates or need to wait for them
       FIssueState := IssStateChallgPend;
       if FHttpRest.ResponseJson.S['Fulfillment'] = '' then begin
            if AuthMethod = 'FILE' then
            begin
             // FILE validation, create well-known file
                JsonItems := FHttpRest.ResponseJson['FileAuthDetails'];
                if Assigned (JsonItems) then begin
                    if NOT SaveFileChallg (JsonItems) then exit;
                end
                else
                    LogEvent ('Failed to get Json File Auth Details');
            end;
            if AuthMethod = 'DNS' then begin
                JsonItems := FHttpRest.ResponseJson['DNSAuthDetails'];
                if Assigned (JsonItems) then begin
                    if NOT SaveDNSChallg(JsonItems) then exit;
                end
                else
                    LogEvent('Failed to get Json DNS Auth Details');
            end;
            if AuthMethod = 'EMAIL' then begin
                CurChallenge.CCommonName := fCertCommonName;
                CurChallenge.CSuppOrderId := FSuppOrderId;
                CurChallenge.CSupplierProto := FSupplierProto;
                CurChallenge.CType := fSuppCertChallenge;
                CurChallenge.CIssueState := IssStateChallgPend;
                CurChallenge.CStartDT := Now;
                CurChallenge.CDomain := FCertCommonName;
                CurChallenge.ChallengeURL := fCertApprovEmail;
                CurChallenge.CSanIdx := 0;
                if Assigned(FOnChallengeEmail) then FOnChallengeEmail(Self, CurChallenge);

             // update SANs
                FCertSubAltNames[CurChallenge.CSanIdx].SAIssueState := CurChallenge.CIssueState;
                FCertSubAltNames[CurChallenge.CSanIdx].SAStartDT := CurChallenge.CStartDT;
                FCertSubAltNames[CurChallenge.CSanIdx].SADoneDT := CurChallenge.CDoneDT;

             // update database with new challenge
                if (DBWriteOneChallenge(CurChallenge) < 0) then begin
                    LogEvent('Failed to Update Challenge Database');
                end;
                LogEvent('You should receive an email when the order is completed');
            end;

            if FChallengeTimer.Enabled then
                LogEvent('Certificate Order Placed, Automatic Collection Enabled' + IcsCRLF)
            else
                LogEvent('Certificate Order Placed, You now need to collect the certificate, ' +
                                        'the order is completed, hopefully a few minutes for DV');
            FChallgStartDT := Now;
            FIssueState := IssStateChallgPend;
            FChkChallgTrg := IcsGetTrgSecs64 (10);   { V8.63 first check in 10 seconds }
        end
        else begin

        // order is completed and we have certificates, save them all - only with AlwaysOn
            FIssueState := IssStateChallgOK;
            RemoveChallgs(FCertCommonName);
            FChallgDoneDT := Now;
            if NOT CCFullfillment(FHttpRest.ResponseJson, fCertCommonName) then Exit;
            FIssueState := IssStateCollect;
            FOrderCertsDT := Now;
        end;

    // all done
        for I := 0 to FCertSubAltNames.Count - 1 do begin
            FCertSubAltNames[I].SAIssueState := FIssueState;
            FCertSubAltNames[I].SADoneDT := FOrderCertsDT;
        end;
        DBWriteCNDomain;
        if (FIssueState = IssStateCollect) and Assigned(FOnNewCert) then FOnNewCert(Self);
        Result := True;
    except
        on E:Exception do begin
            LogEvent ('Failed to place order - ' + E.Message);
            exit;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.CCFullfillment (JsonOrder: ISuperObject; const CertName: string): Boolean;
begin
    Result := False;
    try
        FNewCertP7Lines   := JsonOrder['Fulfillment'].S['Certificate_PKCS7'];
        FNewCertLines     := JsonOrder['Fulfillment'].S['Certificate'];
        FNewInterLines    := JsonOrder['Fulfillment'].S['Intermediate'];
        FNewCertStartDT   := RFC3339_StrToDate(JsonOrder['Fulfillment'].S['StartDate']);
        FNewCertEndDT     := RFC3339_StrToDate(JsonOrder['Fulfillment'].S['EndDate']);
        if (JsonOrder.S['OrderParameters'] <> '') then begin
            FCSRLines := JsonOrder['OrderParameters'].S['CSR'];
            if FCSRLines = '' then begin
                LogEvent('Did not find Order CSR');  // not fatal
            end;
        end;
    except
        on E:Exception do begin
            LogEvent ('Failed to parse Fullfillment Json - ' + E.Message);
            exit;
        end;
    end;
    LogEvent(IcsCRLF + 'PEM Certificate for: ' + CertName + IcsCRLF + FNewCertLines + IcsCRLF);
    Result := SaveCertificateFiles(CertName);
    if NOT Result then Exit;
    FIssueState := IssStateCollect;
    if FAutoAccountClose then FPendAccountClose := True; { V8.63 }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}


function TSslX509Certs.CCListAllOrders: Boolean;
var
    success: Boolean ;
    JsonItems, JsonOrder: ISuperObject;
    I: integer;
    CommonName, OrderId, MajorStatus, OrderDate, Product: string;
    UpdateDate: string ;
begin
    Result := False;
    LogEvent (IcsCRLF + 'Downloading Recent CertCentre Orders');
    FHttpRest.RestParams.Clear;
    FHttpRest.RestParams.PContent := PContUrlencoded;
//    URL := 'Orders?Status=COMPLETE,PENDING&includeFulfillment=False&' +
//             'includeOrderParameters=True&ItemsPerPage=100&includeDCVStatus=True' ;
    FHttpRest.RestParams.AddItem('Status', 'COMPLETE,PENDING', False);
    FHttpRest.RestParams.AddItem('includeFulfillment', 'False', False);
    FHttpRest.RestParams.AddItem('includeOrderParameters','True', False);
    FHttpRest.RestParams.AddItem('ItemsPerPage', '100', False);
    FHttpRest.RestParams.AddItem('includeDCVStatus', 'True', False);
    if NOT CCGetRequest (HttpGET, 'Orders') then exit ;
    if NOT Assigned (FHttpRest.ResponseJson) then Exit ;
    DumpJson;
    success := FHttpRest.ResponseJson.B['success'];
    if NOT success then begin
        LogEvent ('Failed to list Orders: ' +  FHttpRest.ResponseJson.S['Message']);
        exit;
    end;
    JsonItems := FHttpRest.ResponseJson['OrderInfos'];
    if NOT Assigned (JsonItems) or (JsonItems.AsArray.Length = 0) then begin
        LogEvent ('Did not find any Orders');
        exit;
    end;
    LogEvent ('Total Orders Found: ' + IntToStr(JsonItems.AsArray.Length) + IcsCRLF);
    Result := True;
    for I := 0 to JsonItems.AsArray.Length - 1 do begin
        JsonOrder := JsonItems.AsArray.O[I] ;  // get one order
     //   LogEvent (JsonOrder.AsString) ;                // print one order
        OrderId := JsonOrder.S['CertCenterOrderID'] ;
        CommonName := JsonOrder.S['CommonName'] ;
        MajorStatus := JsonOrder.S['OrderStatus.MajorStatus'] ;
        OrderDate := JsonOrder.S['OrderStatus.OrderDate'] ;
        UpdateDate := JsonOrder.S['OrderStatus.UpdateDate'] ;
        Product := JsonOrder.S['OrderParameters.ProductCode'] ;
        LogEvent ('Order ' + OrderId + ' for ' + CommonName +  ' - ' + Product +
                 ' at ' + OrderDate + ' ' + MajorStatus + ', Updated ' + UpdateDate) ;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.CCGetCert: Boolean;
var
    success: Boolean ;
    JsonOrder: ISuperObject;
    InfoFlag, CommonName, OrderId, Product, MajorStatus, MinorStatus: string ;
    I: Integer;
begin
    result := false ;
    if (FSuppOrderId = '') then begin
        LogEvent ('Must specify Order ID to check order');
        Exit;
    end;
    if (fCertCommonName = '') then begin
        LogEvent ('Must specify Domain Common Name to check order');
        Exit;
    end;

 // read internal variables and public properties from database, so same as order
    if NOT DBReadCNDomain(fCertCommonName, True) then Exit;
    if FIssueState < IssStateChallgPend then begin
        LogEvent('CertCentre Challenge Not Started, Must Order First');
        Exit;
    end;

    LogTimeStamp;
    LogEvent ('Checking CertCentre Order Status for ' + FSuppOrderId +
                                        ' Certificate Order for: ' + fCertCommonName);
    if NOT SetPartFNames (False) then Exit ;  // set long path name with orderid
    SetFullFileNames (FPartFNameOrder) ;

   // load private key for order
    if NOT FileExists (fFilePrvKey) then begin
        LogEvent ('Can not find private key for this order: ' +  fFilePrvKey);
        Exit ;
    end;
    try
        FNewSslCert.ClearAll ;
        FNewSslCert.PrivateKeyLoadFromPemFile (fFilePrvKey, FPrivKeyPassword) ;
    except
        on E:Exception do begin
            LogEvent ('Failed to load private key file: ' + fFilePrvKey + ' - ' + E.Message);
            Exit ;
        end;
    end;
    if NOT FNewSslCert.IsPKeyLoaded then begin
        LogEvent ('Failed to load private key for this order: ' +  fFilePrvKey);
        Exit ;
    end;
    fPrvKeyLines := FNewSslCert.SavePKeyToText ('', PrivKeyEncNone) ;
    LogEvent (IcsCRLF + 'Downloading CertCentre OrderId: ' + fSuppOrderId);
    if FLogJson then
        InfoFlag := 'True'
    else
        InfoFlag := 'False';
    FHttpRest.RestParams.Clear;
    FHttpRest.RestParams.PContent := PContUrlencoded;
    FHttpRest.RestParams.AddItem('includeFulfillment', 'True', False);
    FHttpRest.RestParams.AddItem('includeOrderParameters',InfoFlag, False);
    FHttpRest.RestParams.AddItem('includeBillingDetails', InfoFlag, False);
    FHttpRest.RestParams.AddItem('includeContacts', InfoFlag, False);
    FHttpRest.RestParams.AddItem('includeOrganizationInfos', InfoFlag, False);
    FHttpRest.RestParams.AddItem('includeVettingDetails', InfoFlag, False);
    FHttpRest.RestParams.AddItem('includeDCVStatus', 'True', False);
    if NOT CCGetRequest (HttpGET, 'Order/' + UrlEncode(fSuppOrderId)) then exit ;
    DumpJson;

(* {
  "OrderInfos": [
    {
      "BillingInfo": {
        "Currency": "EUR",
        "Price": 1234.56,
        "Status": "uncleared"
      },
      "CertCenterOrderID": 1234567890,
      "CommonName": "www.certcenter.com",
      "ConfigurationAssessment": {
        "CriteriaVersion": "2009k",
        "Effective": "2015-11-22T16:40:57Z",
        "Engine": "ssllabs/1.20.28",
        "Ranking": "A+"
      },
      "ContactInfo": {
        "AdminContact": {
          "Email": "vorname.nachname@certcenter.com",
          "FirstName": "Vorname",
          "LastName": "Nachname",
          "OrganizationAddress": {
            "AddressLine1": "Bleichstrasse 8",
            "City": "Giessen",
            "Country": "DE",
            "PostalCode": "35390",
            "Region": "Hessen"
          },
          "OrganizationName": "CertCenter AG",
          "Phone": "0641 80899520",
          "Title": "CIO"
        },
        "TechContact": {
          "Email": "vorname.nachname@certcenter.com",
          "FirstName": "Vorname",
          "LastName": "Nachname",
          "OrganizationAddress": {
            "AddressLine1": "Bleichstrasse 8",
            "City": "Giessen",
            "Country": "DE",
            "PostalCode": "35390",
            "Region": "Hessen"
          },
          "OrganizationName": "CertCenter AG",
          "Phone": "0641 80899520",
          "Title": "CIO"
        }
      },
      "Fulfillment": {
        "CSR": "#CSR#",
        "Certificate": "#Certificate#",
        "DownloadLinks": {
          "Certificate": "https://cert.sh/#Hash#/cert",
          "Intermediate": "https://cert.sh/#Hash#/chain",
          "PKCS7": "https://cert.sh/#Hash#/pkcs7"
        },
        "EndDate": "2016-05-10T22:59:59Z",
        "Intermediate": "#Intermediate#",
        "StartDate": "2015-03-12T00:00:00Z"
      },
      "OrderParameters": {
        "PartnerOrderID": "UI-b4156a48aa7480cab6e4ca0xxxxxxxxx",
        "ProductCode": "Symantec.SecureSite",
        "ServerCount": 1,
        "SubjectAltNames": [
          "certcenter.com",
          "certcenter.co.uk"
        ],
        "ValidityPeriod": 12
      },
      "OrderStatus": {
        "OrderDate": "2015-03-11T13:20:14Z",
        "UpdateDate": "2015-11-19T18:25:03Z",
        "MajorStatus": "COMPLETE",
        "MinorStatus": "COMPLETED",
        "Progress": 100,
        "StartDate": "2015-03-12T00:00:00Z",
        "EndDate": "2016-05-10T22:59:59Z",
      },
      "OrganizationInfo": {
        "OrganizationAddress": {
          "AddressLine1": "Bleichstrasse 8",
          "City": "Giessen",
          "Country": "DE",
          "Fax": "0641 80899521",
          "Phone": "0641 80899520",
          "PostalCode": "35390",
          "Region": "Hessen"
        },
        "OrganizationName": "CertCenter AG"
      }
    },
    "scheduledForReplacement": {
        "eventSymantecDistrust": {
            "phase1": true,
            "phase2": false
        }
    },
    "VettingDetails" : {
        "ct" : -1,
        "call" : 0,
        "org" : 0,
        "dcv" : 1,
        "vcs" : 0
    },
    "DCVStatus": [
        {
            "Domain": "certcenter.com",
            "Status": "pending",
            "DomainControlValidationID": 1234567890,
            "ApproverEmail": "email-1@domain.com,email-2@domain.com",
            "LastCheckDate": "2018-01-18T22:59:59Z",
            "LastUpdateDate": "2018-01-16T19:49:10Z"
        },
        {
            "Domain": "certcenter.co.uk",
            "Status": "approved",
            "DomainControlValidationID": 1234567891,
            "ApproverEmail": "email@domain.co.uk",
            "LastCheckDate": "2018-01-18T22:59:59Z",
            "LastUpdateDate": "2018-01-16T19:49:10Z"
        }
    ]
  ],
  "_meta": {
    "CommonName": "www.certcenter.com",
    "ItemsAvailable": 1,
    "ItemsPerPage": 10,
    "OrderBy": "ID",
    "OrderDir": "DESC",
    "Page": 1,
    "ProductType": [
      "SSL"
    ],
    "Status": [
      "COMPLETE"
    ]
  },
  "success": true
}
    {"OrderInfo": {
        "FileAuthDetails": {
            "FileContents": "23gsbsyw7q1tq11r44qy0w4ds7cfgb7j",
            "FilePath": "/.well-known/pki-validation",
            "PollStatus": "AUTHENTICATED",
            "FQDNs": ["test8.telecom-tariffs.uk"],
            "FileName": "fileauth.txt"},
        "ContactInfo": {
            "TechContact": {
                "LastName": "Robetson",
                "Title": "Mr",
                "Email": "angus@magsys.co.uk",
                "FirstName": "Angus",
                "Phone": "+44286563636"},
           "AdminContact": {
                "OrganizationName":
                "Magenta Systems Ltd",
                "FirstName": "Angus",
                "Title": "Mr",
                "LastName": "Robetson",
                "Phone": "+44286563636",
                "Email": "angus@magsys.co.uk"}},
        "BillingInfo": {
            "Status": "uncleared",
            "Currency": "GBP",
            "Price": 18.55},
        "VettingDetails": {
            "dcv": -1,
            "org": -1,
            "vcs": -1,
            "call": -1,
            "ct": -1},
        "scheduledForReplacement": {
            "eventSymantecDistrust": {
                "phase1": false,
                "phase2": false}},
        "CommonName": "test8.telecom-tariffs.uk",
        "ConfigurationAssessment": {
            "Engine": "ssllabs/unknown",
            "Ranking": null,
            "CriteriaVersion": null,
            "Effective": "1970-01-01T00:00:00Z"},
        "Fulfillment": {
            "StartDate": "2018-08-23T23:00:00Z",
            "EndDate": "2020-08-23T11:00:00Z",
            "Certificate": "-----BEGIN CERTIFICATE-----\nxxx-",
            "Intermediate": "-----BEGIN CERTIFICATE-----\nxx",
            "DownloadLinks": {
                "Intermediate": "https://cert.sh/5b3130333631312c363335333231305d/chain",
                "PKCS7": "https://cert.sh/5b3130333631312c363335333231305d/pkcs7",
                "Certificate": "https://cert.sh/5b3130333631312c363335333231305d/cert"},
            "CSR": "-----BEGIN CERTIFICATE REQUEST-----\nxx"},
        "CertCenterOrderID": 6353210,
        "OrderParameters": {
             "ProductCode": "GeoTrust.RapidSSL",
             "PartnerOrderID": "ICS-1001",
             "DVAuthMethod": "FILE",
             "ServerCount": 0,
             "ValidityPeriod": 24},
        "OrderStatus": {
            "StartDate": "2018-08-23T23:00:00Z",
            "EndDate": "2020-08-23T11:00:00Z",
            "UpdateDate": "2018-08-24T10:52:05Z",
            "Progress": 100,
            "MinorStatus": "COMPLETED",
            "OrderDate": "2018-08-24T10:46:20Z",
            "MajorStatus": "COMPLETE"}},
    "success": true}

  {"Message": "Invalid OrderID (6666)",
  "ErrorField": "CertCenterOrderID",
  "ErrorId": -2011,
  "success": false }
*)

    success := FHttpRest.ResponseJson.B['success'];
    if NOT success then begin
        LogEvent ('Failed to get order: ' +  FHttpRest.ResponseJson.S['Message']);
        exit;
    end;
    JsonOrder := FHttpRest.ResponseJson.O['OrderInfo'];
    OrderId := JsonOrder.S['CertCenterOrderID'];
    CommonName := JsonOrder.S['CommonName'];
    MajorStatus := JsonOrder.S['OrderStatus.MajorStatus'];
    MinorStatus := JsonOrder.S['OrderStatus.MinorStatus'];
    Product := JsonOrder.S['OrderParameters.ProductCode'];
    LogEvent ('Found order ' + OrderId + ' for ' + CommonName + ' - ' + Product +
                                ', Status ' + MajorStatus + ' - ' + MinorStatus);
    if MajorStatus = 'COMPLETE' then
        FIssueState := IssStateChallgOK
    else if MajorStatus = 'PENDING' then
        FIssueState := IssStateChallgPend
    else if MajorStatus = 'FAILED' then   // pending, NOT TESTED !!!!
        FIssueState := IssStateNone;

// now load certitficates and save files
    if FIssueState = IssStateChallgOK then begin
        if JsonOrder.S['Fulfillment'] <> '' then begin
            LogEvent ('Parsing Fulfillment') ;
            DumpJson('Fulfillment');
            RemoveChallgs(FCertCommonName);
            if FChallgDoneDT < 10 then FChallgDoneDT := Now;
            Result := CCFullfillment (JsonOrder, CommonName) ;
            if Result then begin
                FIssueState := IssStateCollect;
                if FOrderCertsDT < 10 then FOrderCertsDT := Now;
                LogEvent ('Finished collecting order for ' + Product) ;
            end;
        end
        else
            LogEvent ('Failed to find Fulfillment') ;
    end;

 // all done
    for I := 0 to FCertSubAltNames.Count - 1 do begin
        FCertSubAltNames[I].SAIssueState := FIssueState;
        FCertSubAltNames[I].SADoneDT := FOrderCertsDT;
    end;
     DBWriteCNDomain;
     if (FIssueState = IssStateCollect) and Assigned(FOnNewCert) then FOnNewCert(Self);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// check if challenge for a domain is completed
// beware, may not have common domain settings loaded
function TSslX509Certs.CCCheckChallg(ChallgNum: Integer): Boolean;
var
    success: Boolean ;
    JsonOrder: ISuperObject;
    CommonName, OrderId, Product, MajorStatus, MinorStatus: string ;
begin
    Result := False;
    with FChallengeItems [ChallgNum] do begin
        LogTimeStamp;
        if CSuppOrderId = '' then begin
            CIssueState := IssStateNone;
            LogEvent('No Challenge OrderId, Failed for: ' + CDomain);
            Exit;
        end;
        LogEvent('Checking CertCenter Challenge for: ' + CDomain + ', OrderId: ' + CSuppOrderId);
        FHttpRest.RestParams.Clear;
        FHttpRest.RestParams.PContent := PContUrlencoded;
        FHttpRest.RestParams.AddItem('includeFulfillment', 'False', False);
        FHttpRest.RestParams.AddItem('includeOrderParameters','True', False);
        FHttpRest.RestParams.AddItem('includeBillingDetails', 'False', False);
        FHttpRest.RestParams.AddItem('includeContacts', 'False', False);
        FHttpRest.RestParams.AddItem('includeOrganizationInfos', 'False', False);
        FHttpRest.RestParams.AddItem('includeVettingDetails', 'True', False);
        FHttpRest.RestParams.AddItem('includeDCVStatus', 'True', False);
        if NOT CCGetRequest (HttpGET, 'Order/' + UrlEncode(CSuppOrderId)) then exit ;
(* {"OrderInfo":
        {"scheduledForReplacement": {
           "eventSymantecDistrust": {
              "phase1": false,
              "phase2": false}},
         "CommonName": "test8.telecom-tariffs.uk",
         "CertCenterOrderID": 6353210,
         "OrderStatus": {
            "Progress": 0,
            "MinorStatus": "NONE",
            "OrderDate": "2018-08-24T10:46:20Z",
            "MajorStatus": "PENDING",
            "UpdateDate": "2018-08-24T10:46:20Z"}},
     "success": true
   }

   {"OrderInfo":
        {"scheduledForReplacement": {
           "eventSymantecDistrust": {
              "phase1": false,
              "phase2": false}},
        "CommonName": "test8.telecom-tariffs.uk",
        "CertCenterOrderID": 6353210,
        "OrderStatus": {
            "Progress": 0,
            "MinorStatus": "WF_FILE_AUTH",
            "OrderDate": "2018-08-24T10:46:20Z",
            "MajorStatus": "PENDING",
            "UpdateDate": "2018-08-24T10:47:05Z"}},
     "success": true}

   {"OrderInfo":
        {"scheduledForReplacement": {
         "eventSymantecDistrust": {
            "phase1": false,
            "phase2": false}},
        "ConfigurationAssessment": {
            "Engine": "ssllabs/unknown",
            "Ranking": null,
            "CriteriaVersion": null,
            "Effective": "1970-01-01T00:00:00Z"},
        "CommonName": "test8.telecom-tariffs.uk",
        "CertCenterOrderID": 6353210,
        "OrderStatus": {
            "StartDate": "2018-08-23T23:00:00Z",
            "EndDate": "2020-08-23T11:00:00Z",
            "UpdateDate": "2018-08-24T10:52:05Z",
            "Progress": 100,
            "MinorStatus": "COMPLETED",
            "OrderDate": "2018-08-24T10:46:20Z",
            "MajorStatus": "COMPLETE"}},
    "success": true}

    {"OrderInfo": {
        "FileAuthDetails": {
            "FileContents": "2B8FEEF2329A1DAFE4AE2EB8F658CB30CC5A1CAB61353AEC80227F876FA55F1B\ncomodoca.com\nC338BF6DD0B4669C6A5E",
            "FilePath": "/.well-known/pki-validation",
            "PollStatus": null,
            "FQDNs": ["test8.telecom-tariffs.co.uk"],
            "FileName": "66E33FE179899106664F4A6BBBC1E04C.txt"},
        "VettingDetails": {
            "dcv": -1,
            "org": -1,
            "vcs": -1,
            "call": -1,
            "ct": -1},
        "scheduledForReplacement": {
            "eventSymantecDistrust": {
                "phase1": false,
                "phase2": false}},
        "CommonName": "test8.telecom-tariffs.co.uk",
        "CertCenterOrderID": 6353240,
        "OrderParameters": {
            "ProductCode": "Comodo.ComodoSSL",
            "PartnerOrderID": "ICS-1001",
            "DVAuthMethod": "FILE",
            "ServerCount": 0,
            "ValidityPeriod": 12},
        "OrderStatus": {
            "Progress": 0,
            "MinorStatus": "NONE",
            "OrderDate": "2018-08-24T17:42:12Z",
            "MajorStatus": "PENDING",
            "UpdateDate": "2018-08-24T17:42:12Z"}},
     "success": true}

 *)
        DumpJson;
     {"Message": "Invalid OrderID (6666)",
      "ErrorField": "CertCenterOrderID",
      "ErrorId": -2011,
      "success": false }
        success := FHttpRest.ResponseJson.B['success'];
        if NOT success then begin
            CIssueState := IssStateNone;
            LogEvent ('Failed to get order: ' +  FHttpRest.ResponseJson.S['Message']);
            exit;
        end;
        JsonOrder := FHttpRest.ResponseJson.O['OrderInfo'];
        OrderId := JsonOrder.S['CertCenterOrderID'];
        CommonName := JsonOrder.S['CommonName'];
        MajorStatus := JsonOrder.S['OrderStatus.MajorStatus'];
        MinorStatus := JsonOrder.S['OrderStatus.MinorStatus'];
        Product := JsonOrder.S['OrderParameters.ProductCode'];
        LogEvent ('Found order ' + OrderId + ' for ' + CommonName + ' - ' + Product +
                                    ', Status ' + MajorStatus + ' - ' + MinorStatus);

    // check challenge details
        if JsonOrder.S['FileAuthDetails'] <> '' then begin
       //   OrderInfos[].OrderParameters.FileAuthDetails.PollStatus - current status of the last check
       //   OrderInfos[].OrderParameters.FileAuthDetails.LastPollDate - last check for the existence of the file
        end;
        if JsonOrder.S['DNSAuthDetails'] <> '' then begin
        //
        end;
        if JsonOrder.S['VettingDetails'] <> '' then begin
         //
        end;
        if JsonOrder.S['DCVStatus'] <> '' then begin
        {   "Domain": "certcenter.com",
            "Status": "pending",
            "DomainControlValidationID": 1234567890,
            "ApproverEmail": "email-1@domain.com,email-2@domain.com",
            "LastCheckDate": "2018-01-18T22:59:59Z",
            "LastUpdateDate": "2018-01-16T19:49:10Z"   }
        end;

        if MajorStatus = 'COMPLETE' then begin
            CIssueState := IssStateChallgOK;
            CDoneDT := Now;
            Result := True;
        end
        else if MajorStatus = 'PENDING' then begin
            LogEvent('CertCentre Has Not Yet Responded to Challenge for: ' + CDomain);
            CIssueState := IssStateChallgPend;
        end
        else if MajorStatus = 'FAILED' then begin  // pending, NOT TESTED !!!!
            CIssueState := IssStateNone;
            LogEvent('CertCentre Challenge Has Failed for: ' + CDomain);
        end;

    // delete challenge fileif no longer need it
        if (CIssueState = IssStateChallgOK) then begin
            if (CWKFullName <> '') then begin
                if NOT DeleteFile(CWKFullName) then
                 LogEvent ('Failed to delete old file: ' + CWKFullName) ;
            end;
        end;

   end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.CCCancelOrder (Revoke: Boolean): Boolean;
var
    JsonOrder: ISuperObject;
    CommonName, OrderId, MajorStatus, MinorStatus: string ;
    I: Integer;
begin
    result := false ;

    if (fCertCommonName = '') then begin
        LogEvent ('Must specify Domain Common Name to Cancel Order');
        Exit;
    end;

 // read internal variables and public properties from database, so same as order
    if NOT DBReadCNDomain(fCertCommonName, True) then Exit;
    if (FSuppOrderId = '') then begin
        LogEvent ('No Order ID Found to Cancel Order');
        Exit;
    end;
    if FIssueState < IssStateChallgPend then begin
        LogEvent('No CertCentre Order To Cancel');
        Exit;
    end;

    if NOT SetPartFNames (False) then Exit ;  // set long path name with orderid
    SetFullFileNames (FPartFNameOrder) ;

   // for revoke, we need the old certificate
    if revoke then begin
       if NOT FileExists (FFileFinalCert) then begin
            LogEvent ('Can not find cetificate for this order: ' +  FFileFinalCert);
            Exit ;
        end;
        try
            FNewSslCert.ClearAll ;
            FNewSslCert.LoadFromPemFile (FFileFinalCert) ;
        except
            on E:Exception do begin
                LogEvent ('Failed to load certifcate file: ' + FFileFinalCert + ' - ' + E.Message);
                Exit ;
            end;
        end;
        if NOT FNewSslCert.IsCertLoaded then begin
            LogEvent ('Failed to load cetificate for this order: ' +  FFileFinalCert);
            Exit ;
        end;
        FNewCertLines := FNewSslCert.SaveCertToText (false) ;
    end;
    LogTimeStamp;
    LogEvent ('Checking CertCentre OrderId: ' + FSuppOrderId + ' for ' + FCertCommonName);
    FHttpRest.RestParams.Clear;
    FHttpRest.RestParams.PContent := PContUrlencoded;
//    URL :='Order/' + UrlEncode(fSuppOrderId) + '?includeFulfillment=False&' +
///        'includeOrderParameters=False=True&includeBillingDetails=False&' +
//                     'includeContacts=False&includeOrganizationInfos=False';
    FHttpRest.RestParams.AddItem('includeFulfillment', 'False', False);
    FHttpRest.RestParams.AddItem('includeOrderParameters','False', False);
    FHttpRest.RestParams.AddItem('includeBillingDetails', 'False', False);
    FHttpRest.RestParams.AddItem('includeContacts', 'False', False);
    FHttpRest.RestParams.AddItem('includeOrganizationInfos', 'False', False);
    if NOT CCGetRequest (HttpGET, 'Order/' + UrlEncode(fSuppOrderId)) then exit ;
    DumpJson;
    if NOT FHttpRest.ResponseJson.B['success'] then begin
        LogEvent ('Failed to find order: ' +  FHttpRest.ResponseJson.S['Message']);
        exit;
    end;
    JsonOrder := FHttpRest.ResponseJson.O['OrderInfo'];
    OrderId := JsonOrder.S['CertCenterOrderID'] ;
    CommonName := JsonOrder.S['CommonName'] ;
    if CommonName <> fCertCommonName then begin
        LogEvent ('Mismatch common name, found: ' +  CommonName);
        exit;
    end;
    MajorStatus := JsonOrder.S['OrderStatus.MajorStatus'] ;
    MinorStatus := JsonOrder.S['OrderStatus.MinorStatus'] ;
    LogEvent ('Found order ' + OrderId + ' for ' + CommonName + ', Status ' +
                                            MajorStatus + ' - ' + MinorStatus) ;

  // revoke adds the certificate to OCP and CRL lists to blacklist it
    if revoke then begin
        LogEvent (IcsCRLF + 'Revoking CertCentre OrderId: ' + FSuppOrderId + ' for ' + FCertCommonName);
        FHttpRest.RestParams.Clear;
        FHttpRest.RestParams.PContent := PContUrlencoded;
     //   URL :='Revoke/' + UrlEncode(fSuppOrderId) + '&RevokeReason=' +
     //       UrlEncode('Replaced certificate') + '&Certificate=' + UrlEncode(fCertLines) ;
        FHttpRest.RestParams.AddItem('RevokeReason', 'Replaced certificate', False);
        FHttpRest.RestParams.AddItem('Certificate', FNewCertLines, False);
        if NOT CCGetRequest (httpDELETE, 'Revoke/' + UrlEncode(FSuppOrderId)) then exit ;
        DumpJson;
        if FHttpRest.ResponseJson.B['success'] then begin
            LogEvent ('Succesfully revoked order: ' +  FHttpRest.ResponseJson.AsString);
            FIssueState := IssStateCancel;
            Result := True;
        end
        else
            LogEvent ('Failed to revoke order: ' +  FHttpRest.ResponseJson.AsString);
      //   {"Message": "Method not found", "ErrorId": 403, "success": false}
    end

  // simple cancellation within 30 days should get a refund
    else begin
        LogEvent (IcsCRLF + 'Cancelling CertCentre OrderId: ' + FSuppOrderId + ' for ' + FCertCommonName);
        FHttpRest.RestParams.Clear;
  //      URL :='Order/' + UrlEncode(fSuppOrderId);
        if NOT CCGetRequest (httpDELETE, 'Order/' + UrlEncode(FSuppOrderId)) then exit ;
        DumpJson;
        if FHttpRest.ResponseJson.B['success'] then begin
            LogEvent ('Succesfully cancelled order: ' +  FHttpRest.ResponseJson.AsString);
            FIssueState := IssStateCancel;
            Result := True;
        end
        else
            LogEvent ('Failed to Cancel order: ' +  FHttpRest.ResponseJson.AsString);
       //  {"Message": "Order has been successfully cancelled", "success": true}
       // {"Errors": [{"Message": "Allgemeiner Fehler", "ErrorField": "ApproverEmail", "ErrorId": -2006}], "success": false}
    end;

 // all done
    for I := 0 to FCertSubAltNames.Count - 1 do begin
        FCertSubAltNames[I].SAIssueState := FIssueState;
    end;
    DBWriteCNDomain;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.AcmeGetRequest(HttpReq: THttpRequest;
                        const FullURL: String; AcmeJson: ISuperObject): boolean;
var
    I: integer;
    S, JsonWebSig, JsonReq: string;
begin
    result := false;
    if Pos ('https://', FullURL) <> 1 then  begin
        LogEvent ('Invalid URL: ' + FullURL);
        exit;
    end;
    FHttpRest.ServerAuth := httpAuthNone;
    FHttpRest.DebugLevel := FDebugLevel;
    FHttpRest.Agent := 'ICS-ACME-' +  ComponentVersion; // V8.60
    FHttpRest.SocketFamily := FSocketFamily;        // V8.60 allow IPv6
    FHttpRest.ProxyURL := FProxyURL;                // V8.62 proxy support
    if (Pos ('/new-cert', FullURL) > 1) or (Pos ('/cert/', FullURL) > 1) or
                                         (Pos ('issuer-cert', FullURL) > 1) then
        FHttpRest.Accept := 'application/pkix-cert'
     else
        FHttpRest.Accept := '*/*' ;
    FHttpRest.FollowRelocation := False;  // nonce will fail since unchanged
    FHttpRest.ContentTypePost := 'application/jose+json';
    fAcmeRespLocation := '';
    FAccountLastTick := IcsGetTickCount64;  { V8.63 idle account timeout }
    try

      // Json parameters need to be signed by private key as a Json Web Signature
      // adding nonce from last request to prevent playback
        if HttpReq = httpPOST then begin
            if AcmeJson = Nil then
                JsonReq := ''  { V8.62 POST-as-GET blank payload }
            else begin
                JsonReq := AcmeJson.AsJson(False, False);
                if FDebugLevel >= DebugParams then
                    LogEvent ('AcmeJson: ' + JsonReq);
             end;

      // Acme v2 sends the public key once, which is stored on the server and then
      // a shorter KeyId sent in subsequent requests , with nonce and URL
            if fAcmeKwkKid = '' then
                JsonWebSig := IcsJoseJWSJson(fAcmeJoseAlg, JsonReq, '',
                    fAcmePrivKey.PrivateKey, '', fAcmeKwkPub, '', fAcmeRespNonce, FullURL)
            else
                JsonWebSig := IcsJoseJWSJson(fAcmeJoseAlg, JsonReq, '',
                    fAcmePrivKey.PrivateKey, '', '', fAcmeKwkKid, fAcmeRespNonce, FullURL);
            FHttpRest.RestParams.Clear;
            fAcmeLastStatus := FHttpRest.RestRequest(httpPOST, FullURL, false, JsonWebSig);
        end
        else
            fAcmeLastStatus := FHttpRest.RestRequest(HttpReq, FullURL, false, '');
    except
        on E:Exception do begin
            LogEvent('Failed to contact Acme Server: ' + E.Message);
            // don't exit, may still have something useful
        end;
    end;

 // pending, should be loop to retry  ???

    try
      { look for special Acme headers
        HTTP/1.1 409 Conflict
        Content-Type: application/problem+json
        Boulder-Requester: 5592135
        Location: https://acme-staging.api.letsencrypt.org/acme/reg/5592135
        Replay-Nonce: r1PKRhkQqI7GWwk1sGNwH_V5w2h0U7S0C44jq8vNhH0

        HTTP/1.1 201 Created
        Content-Type: application/json
        Boulder-Requester: 5592485
        Link: <https://acme-staging.api.letsencrypt.org/acme/new-authz>;rel="next"
        Link: <https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf>;rel="terms-of-service"
        Location: https://acme-staging.api.letsencrypt.org/acme/reg/5592485
        Replay-Nonce: JcprpXrX-4qNnubjMHWy9XjXcCi-B2xbvpS9spgJrqE    }

        if FHttpRest.RcvdHeader.Count > 0 then begin
            for I := 0 to Pred (FHttpRest.RcvdHeader.Count) do begin
                S := FHttpRest.RcvdHeader [I];
                if Pos ('Replay-Nonce: ', S) = 1 then
                    fAcmeRespNonce := Copy (S, 15, 999);
             // warning, may be two or more locations
                if Pos ('Link: ', S) = 1 then
                    fAcmeRespLink := Copy (S, 7, 999);
                if Pos ('Boulder-Requester: ', S) = 1 then
                    fAcmeRespRequester := Copy (S, 20, 999);
                if Pos ('Location: ', S) = 1 then
                    fAcmeRespLocation := Copy (S, 11, 999);
                if Pos ('Content-Location: ', S) = 1 then
                    fAcmeRespContLoc := Copy (S, 19, 999);
            end;
        end;
        if HttpReq = httpHEAD then begin
            if (fAcmeLastStatus <> 200) and (fAcmeLastStatus <> 204) and (fAcmeLastStatus <> 405) then
                 LogEvent ('Failed to contact Server, HEAD:' + FHttpRest.LastResponse)
            else
                Result := true;  // got a new nonce, hopefully
            exit;
        end;
        if FHttpRest.ResponseSize = 0 then begin
            if fAcmeLastStatus <> 200 then
                 LogEvent ('Failed to contact Server, Zero Content:' + FHttpRest.LastResponse)
            else
                Result := true;
            Exit ;
        end;

      { V1 provides binary DER for one certificate, convert it to PEM }
        if (Pos('application/pkix-cert', FHttpRest.ContentType) = 1) then begin
            fAcmeCertLines := '';
            fAcmeCertLines := '-----BEGIN CERTIFICATE-----' + IcsCRLF +
                              String(Base64Encode(FHttpRest.ResponseOctet)) + IcsCRLF +
                              '-----END CERTIFICATE-----' + IcsCRLF;
        end;

      { V2 provides multiple proper PEM certificates }
        if (Pos('application/pem-certificate-chain', FHttpRest.ContentType) = 1) then begin
            fAcmeCertLines := '';
            fAcmeCertLines := String(FHttpRest.ResponseOctet);
        end;
    except
        on E:Exception do begin
            LogEvent ('Failed to process response: ' + E.Message);
        end;
    end;
    result := true ;  // OK
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// find or create Acme account, get action URLs
function TSslX509Certs.SetAcmeAccount(CreateNew: Boolean = False): boolean;
var
    Proto, User, Pass, Port, Path : String;
begin
    Result := False;
    FIssueState := IssStateNone;
    FAcmeAccountUrl := '';
    FAcmeAccountNum := '';
    if NOT DirectoryExists(FDirCertWork) and (NOT CreateNew) then begin
        LogEvent('Can Not Find Account Work Directory: ' + FDirCertWork);
        Exit;
    end;
    if (NOT DBReadAccount(FDirCertWork, False)) then begin
        if (NOT CreateNew) then Exit;

    // create account working directory
        LogEvent ('Checking Account Work Directory: ' + FDirCertWork);
        if NOT ForceDirectories (FDirCertWork) then begin
            LogEvent ('Failed to Create Directory: ' + FDirCertWork);
            Exit;
        end;
        if NOT DBOpenINI(FDirCertWork, True) then Exit;
        DBWriteAccount;
    end;
    if Pos ('https://', FSupplierServer) <> 1 then begin
        LogEvent('Invalid certificate supplier server: ' + FSupplierServer);
    end;
    if (Pos ('@', SupplierEmail) = 0) then begin
        LogEvent('Must Specify Supplier Email Address');
        Exit;
    end;
    LogEvent('Opening ACME Account');
    ParseURL(FSupplierServer, Proto, User, Pass, fAcmeHost, Port, Path);
    FAcmePubFName := FDirCertWork + 'AcmePublicKey.pem' ;
    FAcmePrivFName := FDirCertWork + 'AcmePrivateKey.pem' ;
    FAcmeKwkKid := '';
    FNewCertPrefix := 'LE-' ;
    FAcmeOrderFinalizeURL := '';
    FAcmeOrderObjUrl := '';
    FSuppOrderId := '';
    FAcmeRespNonce := '';
    if NOT AcmeLoadPKey(True) then Exit; // new account and new directory
    if NOT AcmeGetActions then Exit;

  // see if account already exists
    if (FAcmeAccountUrl <> '') and (FAcmeAccountNum <> '') then begin
        FAcmeKwkKid := FAcmeAccountUrl;  // this is our Kid for future requests, V2 only
        FIssueState := IssStateAccount;
        Result := True;
    end
    else begin
        if SupplierProto = SuppProtoAcmeV2 then
            Result := AcmeV2NewAccount;
        if Result then FIssueState := IssStateAccount;
    end;
    if Result and CreateNew then
        Result := DBWriteAccount;
end;


 {* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// create or get Acme account private key for signing Json requests
// an DirCertWork is considered an account, one dir per account
// Not used for any certificates !!!!
function TSslX509Certs.AcmeLoadPKey(New: Boolean): Boolean;
begin
    Result := False;
    if FAcmeAccKeyType > PrivKeyRsa4096 then begin
        LogEvent ('Sorry, Only RSA Private Keys Currently Supported for Acme Accounts');
        exit;
    end;
    try
    // get private keys, Acme prefers Elliptic Curve since shorter
        FAcmePrivKey.PrivKeyType := FAcmeAccKeyType;
        case FAcmeAccKeyType of
            PrivKeyRsa2048, PrivKeyRsa3072, PrivKeyRsa4096: FAcmeJoseAlg := jsigRsa256;
            PrivKeyECsecp256: FAcmeJoseAlg := jsigEcdsa256;
            PrivKeyECsecp384: FAcmeJoseAlg := jsigEcdsa384;
            PrivKeyECsecp512: FAcmeJoseAlg := jsigEcdsa512;
            PrivKeyRsaPss2048, PrivKeyRsaPss3072, PrivKeyRsaPss4096: FAcmeJoseAlg := jsigRsaPss256;
            PrivKeyEd25519: FAcmeJoseAlg := jsigEdDSA;
        end;
        FAcmePrivKey.PrivateKey := Nil;

        if (FileExists (FAcmePrivFName)) then begin  // load account private key
            try
                LogEvent ('Loading old private key file: ' + FAcmePrivFName);
                fAcmePrivKey.PrivateKeyLoadFromPemFile (FAcmePrivFName, '');
                LogEvent ('Loaded old private key OK: ' + FAcmePrivKey.PrivateKeyInfo);
            except
                on E:Exception do begin
                    LogEvent ('Exception loading private key: ' + E.Message + ' - ' + FAcmePrivFName);
                    exit;
                end;
            end;
        end
        else begin
            if NOT New then begin
                LogEvent ('Failed to find old private key: ' + FAcmePrivFName);
                exit;
            end;
            try
                FAcmePrivKey.DoKeyPair;
                LogEvent ('Generated private key OK: ' + FAcmePrivKey.PrivateKeyInfo);
                FAcmePrivKey.PrivateKeySaveToPemFile (FAcmePrivFName, '', PrivKeyEncNone);
                LogEvent ('Saved private key file: ' + FAcmePrivFName);
                FAcmePrivKey.PublicKeySaveToPemFile (FAcmePubFName);
                FPrvKeyLines := fAcmePrivKey.SavePKeyToText ('', PrivKeyEncNone);
                LogEvent ('Saved public key file: ' + FAcmePubFName);
                if FLogPkeys then LogEvent (IcsCRLF + FPrvKeyLines + IcsCRLF);
            except
                on E:Exception do begin
                    LogEvent ('Failed to generate private key - ' + E.Message);
                    exit ;
                end;
            end;
         end;

     // build public Json Web Key for Json Web Signing
     // basic jwk, no alg, kid or sig
        FAcmeJwsAlg := IcsJoseFindAlg(FAcmeJoseAlg, FAcmePrivKey.PrivateKey);
        FAcmeKwkPub := IcsJoseJWKPubKey(FAcmePrivKey.PrivateKey, '', '', '');
        LogEvent ('JWK: ' + FAcmeKwkPub);

     // create JWK Thumbprint, used for challenge
        FAcmeKwkThumb := IcsBase64UrlEncode(String(IcsHashDigest(AnsiString(FAcmeKwkPub), Digest_sha256)));
        LogEvent ('Thumbprint: ' + FAcmeKwkThumb);
        Result := true;
    except
        on E:Exception do begin
            LogEvent ('Fatal ACME protocol error: ' + E.Message);
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// contact ACME server to get ACME Server Action URLs and T&Cs
function TSslX509Certs.AcmeGetActions: Boolean;
var
    MetaJson: ISuperObject;
    TermsFname, FullName: String;
    I: integer;
begin
    Result := False;
    try
        LogEvent ('Getting actions from ACME server: ' + FAcmeHost);
        FAcmeRespNonce := '';
        if NOT AcmeGetRequest(httpGET, FSupplierServer, Nil) then exit;
        if (fAcmeLastStatus <> 200) or (NOT Assigned(FHttpRest.ResponseJson)) then begin     { V8.62 }
            LogEvent ('Failed to get ACME Server Action URLs');
            exit;
        end;
        LogEvent ('Downloaded ACME Server Action URLs OK');
        for I := 1 to AcmeActionTot do begin
            AcmeActionDirs [I].URL := FHttpRest.ResponseJson.S[AcmeActionDirs [I].Action];
        end;
        MetaJson := FHttpRest.ResponseJson.O['meta'];
        if Assigned(MetaJson) then begin
            FAcmeTermsUrl := MetaJson.S['terms-of-service'];   // V1
            if FAcmeTermsUrl = '' then FAcmeTermsUrl := MetaJson.S['termsOfService']; // V2
            if FAcmeTermsUrl <> '' then begin
                I := LastDelimiter('/', FAcmeTermsUrl);
                if I > 0 then begin
                    TermsFname := Copy (FAcmeTermsUrl, I + 1, 999);
                    FullName := DirCertWork + TermsFName;
                    if (IcsGetFileSize (FullName) < 2000) then begin  { V8.62 not blank file }
                        if NOT AcmeGetRequest(httpGET, fAcmeTermsUrl, Nil) then exit;
                        if (fAcmeLastStatus = 200) and (FHttpRest.ResponseStream.Size > 2000) then begin
                            try
                                FHttpRest.ResponseStream.SaveToFile(FullName);
                                LogEvent ('Downloaded new Terms: ' + FullName);
                            except
                                on E:Exception do
                                    LogEvent ('Failed to save terms file: ' +
                                                    Fullname + ' - ' + E.Message);
                            end;
                        end
                        else
                            LogEvent ('Failed to read terms file: ' +
                                        fAcmeTermsUrl + ' - ' + FHttpRest.LastResponse); 
                    end
                    else
                        LogEvent ('Terms already downloaded: ' + FullName);
                end;
            end;
        end;
        Result := True;
    except
        on E:Exception do begin
            LogEvent ('Fatal ACME protocol error: ' + E.Message);
        end;
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.AcmeV2NewAccount: Boolean;
var
    I: Integer;
begin
    LogTimeStamp;
    LogEvent ('Registering Account with ACME Server: ' + fAcmeHost);
    Result := False;
    fAcmeAccountUrl := '';
    fAcmeKwkKid := '';   // must be blank for AcmeNewAccount2
    fAcmeAccountNum := '';
    FPendAccountClose := False; { V8.63 }
    try

    // get first Nonce
        if fAcmeRespNonce = '' then begin
            LogEvent ('Get new nonce');
            if NOT AcmeGetRequest(httpHEAD, AcmeActionDirs [AcmeNewNonce2].URL, Nil) then exit;
            LogEvent ('Initial Nonce: ' + fAcmeRespNonce);
        end;

     // register and create an account, may have one already for this key if old
        if NOT AcmeGetRequest(httpPOST, AcmeActionDirs [AcmeNewAccount2].URL,
              SO(['termsOfServiceAgreed', true, 'contact', SA(['mailto:' + FSupplierEmail]) ]) ) then exit;
        DumpJson;

    // did we creatr an account OK, or find one that matches the private key
        if (fAcmeLastStatus = 200) or (fAcmeLastStatus = 409) then begin
            if fAcmeRespLocation <> '' then begin
                fAcmeAccountUrl := fAcmeRespLocation;
                fAcmeKwkKid := fAcmeAccountUrl;       // this is our Kid for future requests
                I := LastDelimiter('/', fAcmeAccountUrl);
                if I > 10 then
                    fAcmeAccountNum := Copy(fAcmeAccountUrl, I + 1, 999);  // not in response with v2
                LogEvent('Using old Acme Account for this key: ' + fAcmeAccountNum +
                                                        ', URL: ' + fAcmeAccountUrl) ;
            end;
        end
        else if fAcmeLastStatus = 201 then begin
            if fAcmeRespLocation <> '' then begin
                fAcmeAccountUrl := fAcmeRespLocation;
                fAcmeKwkKid := fAcmeAccountUrl;       // this is our Kid for future requests
                fAcmeAccountNum := fAcmeRespRequester;
                LogEvent('Created Acme Account: ' + fAcmeAccountNum +
                                                        ', URL: ' + fAcmeAccountUrl) ;
            end;
        end
        else begin
            LogEvent('Failed to Create Acme Account: ' + FHttpRest.ResponseJson.S['type'] +
                                                 ', ' + FHttpRest.ResponseJson.S['detail']) ;
            FAcmeRespNonce := ''; { V8.63  clear nonce since out of sequence now }
            Exit;
        end;
        FIssueState := IssStateAccount;
        Result := True;
    except
        on E:Exception do begin
            LogEvent ('Fatal ACME protocol error: ' + E.Message);
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// Acme check order for a SSL certificate
// optionally check domain exists for domain challenge
// optionally save order to database
function TSslX509Certs.AcmeCheckOrder(DomainCheck: Boolean = True;
                                        UpdateDB: Boolean = False): Boolean;
var
    I: Integer;
begin
    Result := false ;

// see if using details from old CSR
    FNewSslCert.DoClearCerts;
    if FCertCsrOrigin = CsrOriginFile then begin
        if NOT CheckCSR(True) then Exit;  // sets CommonName and SANs
    end;

// initial set-up
    if (FCertCommonName = '') then begin
        LogEvent('Must Specify Domain Common Name for Certifcate');
        Exit;
    end;
    fAcmeOrderStatus := '';
    FAcmeOrderFinalizeUrl := '';
    FAcmeOrderObjUrl := '';
    FIssueState := IssStateNone;

 // read internal variables, but not saved public properties, they may be new
    DBReadCNDomain(fCertCommonName, False);  // ignore errors, may be new domain
    if FIssueState > IssStateChecked then FIssueState := IssStateNone;   // reset old order
    LogTimeStamp;
    LogEvent ('Checking Let''s Encrypt Certificate Order for: ' + fCertCommonName);

 // only allowed five duplicate orders for the same certificate each week
 // so one only per day
     if ((IcsGetUTCTime - FNewCertStartDT) < 1) then begin  { V8.61 }
        LogEvent ('Only One Order Per Domain Per Day Allowed');
        Exit;
     end;

 // make sure common name is also in SANs, so we can ignore it subsequently
    BuildSANList;

// see if challenge supported
    if (fSuppCertChallenge = ChallNone) then begin
        LogEvent ('No Challenge Validation Specified');
        Exit;
    end;

 // validate some settings
  {  if (FSupplierProto <> SuppProtoAcmeV2) and (FCertSANTot > 1) then begin
        LogEvent ('Acme V2 Required for More Than One Domain Name');
        Exit;
    end;      }

 {   if (FSupplierProto <> SuppProtoAcmeV2) and (Pos ('*.', fCertCommonName) = 1) and
                                            (fSuppCertChallenge <> ChallDNS)  then begin
        LogEvent ('Wild Card Certificates Not Supported by Supplier');
        Exit;
    end;
    if ((fSuppCertChallenge = ChallAlpnUNC) or (fSuppCertChallenge = ChallAlpnUNC)) and
                                             (FSupplierProto <> SuppProtoAcmeV2) then begin
        LogEvent ('ALPN SSL Validation Not Available for this Supplier');
        Exit;
    end;   }

    if (fSuppCertChallenge in [ChallEmail, ChallManual]) then begin
        LogEvent ('EMAIL and Manual Validation Not Available for this Supplier');
        Exit;
    end;

  // see is need to start local web server
    if (fSuppCertChallenge = ChallFileSrv) then begin
        if NOT StartDomSrv('', '') then Exit;
    end
    else if (fSuppCertChallenge = ChallAlpnSrv) then begin
        if NOT StartDomSrv('localhost', '') then Exit;
    end;

 // see if checking challenge by creatng and reading Well-Known file
    if DomainCheck then begin

      // where the well known directory is located for rach domain
        if FIssueState < IssStateChecked then begin
            if (fSuppCertChallenge in [ChallFileUNC, ChallFileFtp, ChallFileApp]) then begin
                for I := 0 to FCertSubAltNames.Count - 1 do begin
                    if NOT TestWellKnown(FCertSubAltNames[I].SADomain,
                                    FCertSubAltNames[I].SADirWellKnown) then exit;
                end;
            end
            else if (fSuppCertChallenge in [ChallAlpnSrv, ChallAlpnUNC, ChallAlpnApp]) then begin
                for I := 0 to FCertSubAltNames.Count - 1 do begin
                    if NOT TestTlsAlpn(FCertSubAltNames[I].SADomain,
                                    FCertSubAltNames[I].SADirWellKnown) then exit;
                end;
            end
            else
                LogEvent ('Order Checking Passed: ' + fCertCommonName);
            FIssueState := IssStateChecked;
        end;
    end;
    if UpdateDB then begin
        if DBWriteCNDomain then   // write database
            LogEvent ('Saved Domain to Database: ' + fCertCommonName)
        else
            LogEvent ('Failed to Save Domain to Database: ' + fCertCommonName);
    end;
    Result := True;
 end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.AcmeV2OrderCert: Boolean;
var
    ArrayChallg, ArrayAuthz, ArrayIdents: ISuperObject;
    ChallgJson, IdentsJson: ISuperObject;
    AuthMethod, ChallgStatus: string ;
    I, J: integer;
    CurChallenge: TChallengeItem;
begin
    Result := False;
    if (fAcmeKwkKid = '') then begin
        LogEvent ('Must Create or Open ACME Account First');
        Exit;
    end;

// new order so clear stuff from last order
    FAcmeOrderFinalizeUrl := '';
    FAcmeOrderObjUrl := '';
    FPartFNameFinal := '';
    FPartFNameServer.Clear;
    FFileFinalCSR := '';
    FFileFinalPrvKey := '';
    FFileFinalBundle := '';
    FOrderStartDT := Now;
    FChallgStartDT := 0; ;
    FChallgDoneDT := 0;
    FOrderCertsDT := 0;
    FOrderAttempts := FOrderAttempts + 1;
    FNewCertCN := '';
    FNewCertSAN := '';
    FNewCertValRes := chainFail;
    FNewCertErrs := '';
    FNewCertChainInfo := '';
    FNewCertEndDT := 0;
    FNewCertStartDT := 0;
    FPendingChallg := 0;
    FPendAccountClose := False; { V8.63 }

// V8.62 check we can creeate certificate directories before order starts
    if NOT SetPartFNames (False) then Exit ;

 // check challenge allowed,  and well known directory for each domain on certificate
 // loads internal variables from database
    if FIssueState <> IssStateChecked then begin
        if NOT AcmeCheckOrder(True, True) then Exit;    // update database
    end;
    LogTimeStamp;
    LogEvent ('Starting Let''s Encrypt Certificate Order for: ' + fCertCommonName);

    // order info
    FNewOrderNum := DBNewOrderNum;
    if FSuppOrderRef = '' then
            FSuppOrderRef := 'ICS-' + IntToStr(FNewOrderNum);
    FSuppCertProduct := 'Let''s Encrypt 3 months';

 // start timer so order completes automatically
    if FAutoOrderComplete and (NOT FChallengeTimer.Enabled) then
                                          FChallengeTimer.Enabled := True;

    try
        case fSuppCertChallenge of
            ChallFileUNC: AuthMethod := 'http-01';
            ChallFileFtp: AuthMethod := 'http-01';
            ChallFileSrv: AuthMethod := 'http-01';
            ChallFileApp: AuthMethod := 'http-01';
            ChallDNS:     AuthMethod := 'dns-01';
            ChallAlpnUNC: AuthMethod := 'tls-alpn-01';
            ChallAlpnSrv: AuthMethod := 'tls-alpn-01';
            ChallAlpnApp: AuthMethod := 'tls-alpn-01';
            else begin
                LogEvent ('Unsupported Challenge Method');
                Exit;
            end;
        end;

    //  must have a valid nonce to do POST requests
        if fAcmeRespNonce = '' then begin
            if NOT AcmeGetRequest(httpHEAD, AcmeActionDirs [AcmeNewNonce2].URL, Nil) then exit;
        end;

    // new authorisation request, get order object with lots of URLs for our domains
    // Acme V2 may have multiple host names, which will get separate challenges
        ArrayIdents := SA([]);
        for I := 0 to FCertSubAltNames.Count - 1 do begin
            ArrayIdents.O[''] := SO (['type', 'dns', 'value', FCertSubAltNames[I].SADomain]);
            FCertSubAltNames[I].SAIssueState := FIssueState;
            if FIssueState < IssStateChallgPend then begin
                FCertSubAltNames[I].SAStartDT := 0;
                FCertSubAltNames[I].SADoneDT := 0;
                FCertSubAltNames[I].SAValidResult := '';
            end;
        end;
        if NOT DBWriteCNDomain then Exit; // save public and private properties
        if NOT AcmeGetRequest(httpPOST, AcmeActionDirs [AcmeNewOrder2].URL,
                                     SO(['identifiers', ArrayIdents])) then Exit;
        DumpJson;
(*
Request completed: 201 Created
Location: https://acme-v02.api.letsencrypt.org/acme/order/31733331/18533383
Response (length 741)
{
  "status": "pending",
  "expires": "2018-07-30T11:26:45.071131264Z",
  "identifiers": [
    {
      "type": "dns",
      "value": "test1.telecom-tariffs.co.uk"
    },
    {
      "type": "dns",
      "value": "test2.telecom-tariffs.co.uk"
    },
    {
      "type": "dns",
      "value": "test3.telecom-tariffs.co.uk"
    }
  ],
  "authorizations": [
    "https://acme-v02.api.letsencrypt.org/acme/authz/JjB-jDQjtA15ogoY-qfAc5cqJscAcBg6gQp0lr4_iFU",
    "https://acme-v02.api.letsencrypt.org/acme/authz/pH4NQhnkRbK1m-VfSSCkijYDkPx8hmceZFUG6YVSrCU",
    "https://acme-v02.api.letsencrypt.org/acme/authz/7Op_FW4ZzPftOFIZvkbGnjQjc_TRHjNEhgEvztvxJGo"
  ],
  "finalize": "https://acme-v02.api.letsencrypt.org/acme/finalize/31717591/21234582"
}
*)

        if fAcmeLastStatus <> 201 then begin
            LogEvent('Failed to get ACME Order Object: ' + FHttpRest.ResponseJson.S['type'] +
                                                 ', ' + FHttpRest.ResponseJson.S['detail']) ;
            FAcmeRespNonce := ''; { V8.63  clear nonce since out of sequence now }
        // see if closing account
            if FAutoAccountClose then FPendAccountClose := True; { V8.63 }
            Exit;
        end;
        fAcmeOrderFinalizeUrl := FHttpRest.ResponseJson.S['finalize'];
        FAcmeOrderObjUrl := fAcmeRespLocation;  // order object
        I := LastDelimiter('/', FAcmeOrderObjUrl);
        if I > 10 then fSuppOrderId := Copy(FAcmeOrderObjUrl, I + 1, 999);
        fAcmeOrderStatus := FHttpRest.ResponseJson.S['status'];
        fAcmeOrderExpiresDT := RFC3339_StrToDate(FHttpRest.ResponseJson.S['expires']);

      // ignore challenges, already done
        if (fAcmeOrderStatus = 'ready') or (fAcmeOrderStatus = 'valid')  then begin
            FIssueState := IssStateChallgOK;
            LogEvent('ACME Certificate Order Already Completed, Collect Certificate' + IcsCRLF);
            Result := True;
        end

     // some fatal error
        else if (fAcmeOrderStatus = 'invalid') then begin
            FIssueState := IssStateNone;
            LogEvent('ACME Certificate Order Failed, Start Again' + IcsCRLF);
            FAcmeRespNonce := ''; { V8.63  clear nonce since out of sequence now }
        // see if closing account
            if FAutoAccountClose then FPendAccountClose := True; { V8.63 }
        end

      // not started challenges yet, add challenges to database
        else if (fAcmeOrderStatus = 'pending') then begin
            ArrayAuthz  := FHttpRest.ResponseJson.O['authorizations'];  // authorization URLs
     //       ArrayIdents := FHttpRest.ResponseJson.O['identifiers'];     // domain names should be copy of input
            if ArrayAuthz.AsArray.Length <> FCertSANTot then
                LogEvent('!! Warning, Order Object Mismatch Domaains Ordered');

         // some challege stuff is common to all domaims
            CurChallenge.CCommonName := fCertCommonName;
            CurChallenge.CSuppOrderId := FSuppOrderId;
            CurChallenge.CSupplierProto := FSupplierProto;
            CurChallenge.CType := fSuppCertChallenge;
            CurChallenge.CIssueState := IssStateChallgPend;
            CurChallenge.CStartDT := Now;
            CurChallenge.CDoneDT := 0;

         // now find challenge for each domaim, update database and start it
         // (will be reusing FHttpRest.ResponseJson)
            for I := 0 to ArrayAuthz.AsArray.Length - 1 do begin
                CurChallenge.CAuthzURL := ArrayAuthz.AsArray[I].AsString;
                if CurChallenge.CAuthzURL = '' then begin
                    LogEvent('Failed to find authorization: ' + AuthMethod);
                    Exit;
                end;

             // now start each authorisation, one for each domain
                if NOT AcmeGetRequest(httpPOST, CurChallenge.CAuthzURL, Nil) then exit;
                if fAcmeLastStatus <> 200 then begin
                    LogEvent('Failed to Get ACME Challenges: ' + FHttpRest.ResponseJson.S['type'] +
                                                         ', ' + FHttpRest.ResponseJson.S['detail']) ;
                    FAcmeRespNonce := ''; { V8.63  clear nonce since out of sequence now }
                    Exit;
                end;
                DumpJson;
(*
Request completed: 200 OK
Response (length 919)
{
  "identifier": {
    "type": "dns",
    "value": "test1.telecom-tariffs.co.uk"
  },
  "status": "pending",
  "expires": "2018-07-30T11:26:45Z",
  "challenges": [
    {
      "type": "dns-01",
      "status": "pending",
      "url": "https://acme-v02.api.letsencrypt.org/acme/challenge/pH4NQhnkRbK1m-VfSSCkijYDkPx8hmceZFUG6YVSrCU/5877772577",
      "token": "S1nSmbqllXEnGIPBstR-Vk9vS5bUs80pBKjVVfcEXsc"
    },
    {
      "type": "http-01",
      "status": "pending",
      "url": "https://acme-v02.api.letsencrypt.org/acme/challenge/pH4NQhnkRbK1m-VfSSCkijYDkPx8hmceZFUG6YVSrCU/5877772578",
      "token": "VGRCea7jdbIjQ9ND-KpRAd96r4hAfJXEMsxUKqZp1H8"
    },
    {
      "type": "tls-alpn-01",
      "status": "pending",
      "url": "https://acme-v02.api.letsencrypt.org/acme/challenge/pH4NQhnkRbK1m-VfSSCkijYDkPx8hmceZFUG6YVSrCU/5877772579",
      "token": "EVM0K8eRUstKD0bk0avHFqDgOGC36xXPixOSPqQT3h0"
    }
  ]
}
*)
           // ACME should have offered us several challenges with different types, we need to choose
           // one and start it, ignore the others
                IdentsJson := FHttpRest.ResponseJson.O['identifier'];
                CurChallenge.CDomain := IdentsJson.S['value'];
                ChallgStatus := FHttpRest.ResponseJson.S['status'];
                CurChallenge.ChallengeURL := '';
                CurChallenge.CDirWellKnown := '';
                CurChallenge.CDirPubWebCert := '';
                CurChallenge.CIssueState := IssStateNone;
                CurChallenge.CSanIdx := DBFindSAN(CurChallenge.CDomain);
                if CurChallenge.CSanIdx < 0 then begin  // sanity check
                    CurChallenge.CSanIdx := 0;
                    LogEvent('!!! Failed to Find Sub Alt Name for ' + CurChallenge.CDomain);
                end;

                if ChallgStatus = 'valid' then begin
                    CurChallenge.CIssueState := IssStateChallgOK;
                    if CurChallenge.CDoneDT < 10 then CurChallenge.CDoneDT := Now;
                    LogEvent('Challenge Already Passed for ' + CurChallenge.CDomain);
                end
                else begin
                    ArrayChallg := FHttpRest.ResponseJson.O['challenges'];  // array of challenges
                    for J := 0 to ArrayChallg.AsArray.Length - 1 do begin
                        ChallgJson := ArrayChallg.AsArray[J];
                        if ChallgJson.S['type'] = AuthMethod then begin
                            CurChallenge.ChallengeURL := ChallgJson.S['url'];
                            CurChallenge.ChallgToken := ChallgJson.S['token'];
                            CurChallenge.CResp := CurChallenge.ChallgToken  + '.' + fAcmeKwkThumb;   // key authorization
                            if fSuppCertChallenge in [ChallAlpnSrv, ChallAlpnUNC, ChallAlpnApp] then begin  { V8.62 }
                                CurChallenge.CAcmeAlpnCert := 'acmealpn-' + BuildCertName(CurChallenge.CDomain) + '.pem';
                                if fSuppCertChallenge = ChallAlpnUNC then
                                    CurChallenge.CPage := 'acme-challenge\' + CurChallenge.CAcmeAlpnCert ; // file path for copying
                                break;
                            end;
                            if fSuppCertChallenge in [ChallFileSrv, ChallFileApp] then
                                CurChallenge.CPage := 'acme-challenge/' + CurChallenge.ChallgToken  // URL path for local server
                            else
                                CurChallenge.CPage := 'acme-challenge\' + CurChallenge.ChallgToken; // file path for copying
                            break;
                        end;
                    end;
                    if CurChallenge.ChallengeURL = '' then begin
                        LogEvent('Failed to find challenge: ' + AuthMethod + ' for ' + CurChallenge.CDomain);
                        Exit;
                    end;
                    CurChallenge.CIssueState := IssStateChallgPend;
                    CurChallenge.CDirWellKnown := FCertSubAltNames[CurChallenge.CSanIdx].SADirWellKnown;
                    CurChallenge.CDirPubWebCert := FCertSubAltNames[CurChallenge.CSanIdx].SADirPubWebCert;

                // save well-known file with Key Authorization content
                    if (CurChallenge.CType = ChallFileUNC) then begin
                        if CurChallenge.CDirWellKnown <> '' then begin
                            CurChallenge.CWKFullName := CurChallenge.CDirWellKnown + CurChallenge.CPage;
                            LogEvent ('Built domain validation file name: ' +
                                        CurChallenge.CWKFullName + ', saving token: ' + CurChallenge.CResp);
                            if NOT SaveDataFile (CurChallenge.CWKFullName, CurChallenge.CResp) then Exit ;
                        end
                        else
                            LogEvent ('Challenge Failed, No Well-Known Directory Found');
                    end;

                // create base64 SHA256 digest of CResp for
                // ie  _acme-challenge.example.org. 300 IN TXT "gfj9Xq...Rg85nM"
                    if (CurChallenge.CType = ChallDNS) then begin
                        CurChallenge.CPage :=  '_acme-challenge.' + CurChallenge.CDomain;
                        CurChallenge.CDNSValue := String(IcsBase64UrlEncodeA
                            (IcsHashDigest(AnsiString(CurChallenge.CResp), Digest_sha256)));
                        LogEvent ('!!! Add DNS TXT Record for: ' + CurChallenge.CPage + ', with: ' + CurChallenge.CDNSValue);
                        if Assigned(FOnChallengeDNS) then FOnChallengeDNS(Self, CurChallenge);
                    end;

                // FTP handled by application
                    if (CurChallenge.CType = ChallFileFtp) then begin
                        CurChallenge.CWKFullName := FDirCertWork + CurChallenge.CPage;
                        LogEvent ('Built domain validation file name: ' +
                                        CurChallenge.CWKFullName + ', saving token: ' + CurChallenge.CResp);
                        if NOT SaveDataFile (CurChallenge.CWKFullName, CurChallenge.CResp) then Exit ;
                        LogEvent ('!!! Must FTP Challege File to .Well-Known Directory for: ' + CurChallenge.CDomain);
                        if Assigned(FonChallengeFTP) then FonChallengeFTP(Self, CurChallenge);
                    end;

                // V8.62 ALPN local or app server, create ACME certificate in working directory
                    if fSuppCertChallenge in [ChallAlpnSrv, ChallAlpnApp] then begin
                        CurChallenge.CAcmeAlpnCert := FDirCertWork + CurChallenge.CAcmeAlpnCert;
                        if NOT CreateAcmeAlpnCert(CurChallenge.CAcmeAlpnCert,
                                CurChallenge.CDomain, CurChallenge.CResp) then begin
                            LogEvent('Failed to Create ACME ALPN SSL Certificate: ' + CurChallenge.CAcmeAlpnCert);
                            Exit;
                        end;
                        LogEvent ('Built ACME ALPN SSL Certificate: ' + CurChallenge.CAcmeAlpnCert);
                    end;

                // V8.62 ALPN UNC path, create ACME certificate in remote directory
                    if fSuppCertChallenge = ChallAlpnUNC then begin
                        CurChallenge.CWKFullName := FDirCertWork + CurChallenge.CPage;
                        if NOT CreateAcmeAlpnCert(CurChallenge.CWKFullName,
                                CurChallenge.CDomain, CurChallenge.CResp) then begin
                            LogEvent('Failed to Create ACME ALPN SSL Certificate: ' + CurChallenge.CWKFullName);
                            Exit;
                        end;
                        LogEvent ('Built ACME ALPN SSL Certificate: ' + CurChallenge.CWKFullName);

                    end;
                end ;

             // update database with new challenge
                if (DBWriteOneChallenge(CurChallenge) < 0) then begin
                    LogEvent('Failed to Update Challenge Database');
                    Exit;
                end;

               //  start challenge, so they look up our file, no parameters, just a special URL
                if CurChallenge.CIssueState <> IssStateChallgOK then begin
                    LogEvent('Starting ACME Challenge for: ' + CurChallenge.CDomain);
                    if NOT AcmeGetRequest(httpPOST, CurChallenge.ChallengeURL, SO([])) then exit;
                    DumpJson;
    (* HTTP/1.1 200 OK
     {
      "type": "http-01",
      "status": "pending",
      "url": "https://acme-staging-v02.api.letsencrypt.org/acme/challenge/6mDYqM5A5a7L3QnD0FxOUYI5FflSq-3MMqvfOWYPxcg/110522443",
      "token": "Or9PmU6EtQUEjph3-g8ljyQWmoMiBiQy_YJtKWrF_O8"
    }
    *)
                   // was challenge accepted ???
                    if fAcmeLastStatus <> 200 then begin
                        LogEvent('Failed to start Acme challenge: ' + FHttpRest.ResponseJson.S['type'] +
                                                             ', ' + FHttpRest.ResponseJson.S['detail']) ;
                        FAcmeRespNonce := ''; { V8.63  clear nonce since out of sequence now }
                        Exit;
                    end;
                    ChallgStatus := FHttpRest.ResponseJson.S['status'];
                    if ChallgStatus = 'valid' then begin  // unlikely to be done yet !!
                        CurChallenge.CIssueState := IssStateChallgOK;
                        DBWriteOneChallenge(CurChallenge);
                        LogEvent('Challenge Already Passed for: ' + CurChallenge.CDomain);
                    end
                    else begin
                        LogEvent('Challenge Requested for: ' + CurChallenge.CDomain);
                        FPendingChallg := FPendingChallg + 1;  // pending challenges
                    end;
                end;
                FCertSubAltNames[CurChallenge.CSanIdx].SAIssueState := CurChallenge.CIssueState;
                FCertSubAltNames[CurChallenge.CSanIdx].SAStartDT := CurChallenge.CStartDT;
                FCertSubAltNames[CurChallenge.CSanIdx].SADoneDT := CurChallenge.CDoneDT;
            end;
            FChallgStartDT := Now;
            FIssueState := IssStateChallgPend;
            FChkChallgTrg := IcsGetTrgSecs64 (10);   { V8.63 first check in 10 seconds }
            if FChallengeTimer.Enabled then
                LogEvent('ACME Certificate Order Placed, Automatic Collection Enabled' + IcsCRLF)
            else
                LogEvent('ACME Certificate Order Placed, Manually Collect When Complete' + IcsCRLF);
            Result := True;
        end
        else begin
            FIssueState := IssStateNone;
            LogEvent('ACME Certificate Order Unknown Result: ' + fAcmeOrderStatus + IcsCRLF);
        end;
        DBWriteCNDomain;
      except
        on E:Exception do begin
            LogEvent ('Fatal ACME protocol error: ' + E.Message);
        end;
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// check if challenge for a domain is completed
// beware, may not have common domain settings loaded
function TSslX509Certs.AcmeV2CheckChallg(ChallgNum: Integer): Boolean;
var
    ValidJson, RecJson: ISuperObject;
    ArrayChallg, ChallgJson, ErrorJson: ISuperObject;
    ChallgStatus: string ;
    J: integer;
begin
    Result := False;
    with FChallengeItems [ChallgNum] do begin
        LogTimeStamp;
        LogEvent('Checking Acme Challenge for: ' + CDomain);
        if NOT AcmeGetRequest(httpPOST, ChallengeURL, Nil) then begin
            LogEvent('Failed to Check ACME Challenge: ' + FHttpRest.ResponseJson.S['type'] +
                                                 ', ' + FHttpRest.ResponseJson.S['detail']) ;
            FAcmeRespNonce := ''; { V8.63  clear nonce since out of sequence now }
            Exit;
        end;
        if fAcmeLastStatus > 202 then Exit;  // not done
        DumpJson;
        ChallgStatus := FHttpRest.ResponseJson.S['status'];
        if ChallgStatus = 'pending' then begin
            LogEvent('Acme Has Not Yet Responded to Challenge for: ' + CDomain);
            Exit;
        end;
        if ChallgStatus = 'processing' then begin
            LogEvent('Acme is Still Processing the Challenge for: ' + CDomain);
            Exit;
        end;
        if ChallgStatus = 'valid' then begin
            CIssueState := IssStateChallgOK;
            CDoneDT := Now;
            Result := True;
        end
        else if ChallgStatus = 'invalid' then begin
            LogEvent('Acme Challenge Has Failed for: ' + CDomain);
            CIssueState := IssStateNone;
        end
        else begin
            CIssueState := IssStateNone;
            Exit;
        end;

    // delete challenge file if no longer need it
        if (CWKFullName <> '') then begin
            if NOT DeleteFile(CWKFullName) then
                        LogEvent ('Failed to delete old file: ' + CWKFullName) ;
        end;
        if (CAcmeAlpnCert <> '') then begin
         // if NOT DeleteFile(CAcmeAlpnCert) then
         //             LogEvent ('Failed to delete old file: ' + CAcmeAlpnCert) ;
        end;

 (*
 Acme V2
Request completed: 200 OK
Response (length 554)
{
  "type": "http-01",
  "status": "valid",
  "url": "https://acme-v02.api.letsencrypt.org/acme/challenge/7Op_FW4ZzPftOFIZvkbGnjQjc_TRHjNEhgEvztvxJGo/5877772581",
  "token": "tEZim0F1rZEXZ6dSN8YlT-J4vYOrBEaRSaTGDXgh6mU",
  "validationRecord": [
    {
      "url": "http://test2.telecom-tariffs.co.uk/.well-known/acme-challenge/tEZim0F1rZEXZ6dSN8YlT-J4vYOrBEaRSaTGDXgh6mU",
      "hostname": "test2.telecom-tariffs.co.uk",
      "port": "80",
      "addressesResolved": [
        "217.146.115.84"
      ],
      "addressUsed": "217.146.115.84"
    }
  ]
}

Response (length 223)
{
  "type": "http-01",
  "status": "pending",
  "url": "https://acme-v02.api.letsencrypt.org/acme/challenge/pH4NQhnkRbK1m-VfSSCkijYDkPx8hmceZFUG6YVSrCU/5877772578",
  "token": "VGRCea7jdbIjQ9ND-KpRAd96r4hAfJXEMsxUKqZp1H8"
}

Response xx
{
  "identifier": {
    "type": "dns",
    "value": "ftptest.org"
  },
  "status": "invalid",
  "expires": "2018-07-31T16:41:05Z",
  "challenges": [
    {
      "type": "dns-01",
      "status": "invalid",
      "error": {
        "type": "urn:ietf:params:acme:error:dns",
        "detail": "DNS problem: NXDOMAIN looking up TXT for _acme-challenge.ftptest.org",
        "status": 400
      },
      "url": "https://acme-v02.api.letsencrypt.org/acme/challenge/SRE4O3zoMyvXzgJRN6HCxUfU0tMfIgmEcOEqZuJPFoE/5907963322",
      "token": "jjtcTRjzhJgNl1CyQsY967xdsWDL2ViQYpRdgx6OvcU"
    }
  ],
  "wildcard": true
}

{
  "type": "dns-01",
  "status": "invalid",
  "error": {
    "type": "urn:ietf:params:acme:error:dns",
    "detail": "DNS problem: NXDOMAIN looking up TXT for _acme-challenge.ftptest.co.uk",
    "status": 400
  },
  "url": "https://acme-v02.api.letsencrypt.org/acme/challenge/_-GEwO0B2kg5TjabHf0dcFiUa4kq-p-iiSkGa4nzRlA/5933169958",
  "token": "63vm15g_0A1kyg8he-nVfGlqQtIKJ0COpyowyMiN-ok"
}
*)
     // success, keep validation details
        if CIssueState = IssStateChallgOK then begin
            ValidJson := FHttpRest.ResponseJson.O['validationRecord'];
            if ValidJson <> Nil then begin
                for J := 0 to ValidJson.AsArray.Length - 1 do begin // should only be one
                    RecJson := ValidJson.AsArray[J];
                    if (RecJson.S['hostname'] = CDomain) then begin;
                        CValidResult := 'OK, URL: ' + RecJson.S['url'] +
                                  ', IP address ' +  RecJson.S['[addressUsed]'];
                        LogEvent('Challenge Validated: ' + CValidResult + '  for: ' + CDomain);
                        Break;
                    end;
                end;
           end;
        end

     // failed, try and find error
        else if CIssueState = IssStateNone then begin
            ArrayChallg := FHttpRest.ResponseJson.O['challenges'];  // array of challenges
            if ArrayChallg <> Nil then begin
                for J := 0 to ArrayChallg.AsArray.Length - 1 do begin
                    ChallgJson := ArrayChallg.AsArray[J];
                    if ChallgJson.S['status'] = ChallgStatus then begin
                        ErrorJson := ChallgJson.O['error'];
                        if ErrorJson <> Nil then CValidResult := ErrorJson.S['detail'];
                        LogEvent('Challenge Failed: ' + CValidResult + '  for: ' + CDomain);
                        break;
                    end;
                end;
            end
            else begin
                ErrorJson := FHttpRest.ResponseJson.O['error'];
                if ErrorJson <> Nil then CValidResult := ErrorJson.S['detail'];
                LogEvent('Challenge Failed: ' + CValidResult + '  for: ' + CDomain);
            end;
        end;

    // update sub domains with progress
    // beware we may not have domain loaded, need to check it, may need it to collect certs
        if (FCertCommonName <> CCommonName) then
            DBReadCNDomain(CCommonName, True);
        if (FCertCommonName = CCommonName) then begin
            if FPendingChallg > 0 then FPendingChallg := FPendingChallg - 1;  // pending challenges
            if (CSanIdx >= 0) then begin
                FCertSubAltNames[CSanIdx].SAIssueState := CIssueState;
                if  FCertSubAltNames[CSanIdx].SADoneDT < 10 then
                    FCertSubAltNames[CSanIdx].SADoneDT := CDoneDT;
                FCertSubAltNames[CSanIdx].SAValidResult := CValidResult;
            end;
            DBWriteCNDomain;
        end
        else
            LogEvent('Challenge Checking Failed to Read Common Name Domain: ' + CCommonName);
    end;

  // upodate database and file
    DBWriteOneChallenge(FChallengeItems [ChallgNum]);

end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.AcmeV2GetCert: Boolean;
var
    CSREn, errstr: string ;
    I: Integer;
begin
    Result := False;
    fAcmeOrderStatus := '';
    FAcmeOrderFinalizeUrl := '';
    FAcmeOrderObjUrl := '';
    if (fCertCommonName = '') or (FCertSubAltNames.Count = 0) then begin
        LogEvent('Must Specify Domain Common Name for Certifcate');
        Exit;
    end;
 // read internal variables and public properties from database, so same as order
    if NOT DBReadCNDomain(fCertCommonName, True) then Exit;
    if FIssueState < IssStateChallgPend then begin
        LogEvent('ACME Challenge Not Started, Must Order First');
        Exit;
    end;
    if (FAcmeOrderFinalizeURL = '') or (FAcmeOrderObjUrl = '') then begin
        LogEvent('Need ACME Order and Fianalize URLs first');
        Exit;
    end;

// look through challenges, keep results
    if NOT DBReadChallenges then begin
        LogEvent('Failed to Read Challenge Database');
        Exit;
    end;
    if FChallengesTot > 0 then begin
        for I := 0 to Length(FChallengeItems) - 1 do begin
            if FChallengeItems [I].CCommonName = fCertCommonName then begin
                if FChallengeItems [I].CIssueState < IssStateChallgOK then begin
                    AcmeV2CheckChallg(I);
                end;
            end;
        end;
        DBWriteCNDomain;
    end;

    try
    // V2 get order object, tells if challenges completed or pending
        if NOT AcmeGetRequest(httpPOST, FAcmeOrderObjUrl, Nil) then exit;
        if fAcmeLastStatus > 202 then begin
            LogEvent('Acme could not find order: ' + FAcmeOrderObjUrl);
            Exit;
        end;
        DumpJson;
        FAcmeOrderExpiresDT := RFC3339_StrToDate(FHttpRest.ResponseJson.S['expires']);
        fAcmeOrderStatus := FHttpRest.ResponseJson.S['status'];
        if (fAcmeOrderStatus = 'ready') or (fAcmeOrderStatus = 'valid')  then begin
            FIssueState := IssStateChallgOK;
            LogEvent('ACME Certificate Order Completed, Collect Certificate');
            if FChallgDoneDT = 0 then FChallgDoneDT := Now;
            FOrderCertsDT := Now;
            DBWriteCNDomain;  // update database
        end

      // see if challenges have completed
        else if (fAcmeOrderStatus = 'pending') or (fAcmeOrderStatus = 'invalid') then begin
            if (fAcmeOrderStatus = 'invalid') then begin
                LogEvent('ACME Certificate Order Failed, Start Again' + IcsCRLF);
                FIssueState := IssStateNone;
            // delete old challenges
                RemoveChallgs(fCertCommonName);
            end
            else begin
                LogEvent('ACME Challenges Not Compeleted Yet');
                FIssueState := IssStateChallgPend;
            end;
            DBWriteCNDomain;  // update database
            Exit;
        end ;

    // challenges compelete
        LogTimeStamp;
        LogEvent ('Collecing Let''s Encrypt SSL certificate for: ' + fCertCommonName);

    //  must have a valid nonce to do POST requests
        if fAcmeRespNonce = '' then begin
            if NOT AcmeGetRequest(httpHEAD, AcmeActionDirs [AcmeNewNonce2].URL, Nil) then exit;
            LogEvent ('Initial Nonce: ' + fAcmeRespNonce);
        end;
        fAcmeCertURL := '';
        fAcmeCertLines := '';
        fNewInterLines := '';

    // work file names, in account directory, with orderid (no work names)
    // fail now if can not create directories
        FNewSslCert.ClearAll;
        if NOT SetPartFNames (False) then Exit ;
        SetFullFileNames (FPartFNameWork) ;

    // if order not yet valid, finalize it
       if fAcmeOrderStatus = 'valid' then begin
            FAcmeCertURL := FHttpRest.ResponseJson.S['certificate'];
       end;
       if (fAcmeOrderStatus = 'ready') or (fAcmeCertURL = '') then begin

          // create private key and certificate service request
            if NOT CreateKeyandReq then exit ;

          // Acme needs DER request UrlBase64 encoded no headers, not PEM base64
            CSREn := IcsBase64UrlEncode(String(FNewSslCert.SaveToDERText));

         // order certificate
            if NOT AcmeGetRequest(httpPOST, fAcmeOrderFinalizeURL, SO([ 'csr', CSREn]) ) then Exit;
            if fAcmeLastStatus > 200 then begin
                errstr := FHttpRest.ResponseJson.S['type'];
                LogEvent('Failed to collect SSL certificate: ' + errstr  +
                                                     ', ' + FHttpRest.ResponseJson.S['detail']) ;
                FAcmeRespNonce := ''; { V8.63  clear nonce since out of sequence now }

             // one repeat for badnonce
                if Pos('badNonce', errstr) = 0 then Exit;
                if NOT AcmeGetRequest(httpHEAD, AcmeActionDirs [AcmeNewNonce2].URL, Nil) then exit;
                if NOT AcmeGetRequest(httpPOST, fAcmeOrderFinalizeURL, SO([ 'csr', CSREn]) ) then Exit;
                if fAcmeLastStatus > 200 then begin
                    errstr := FHttpRest.ResponseJson.S['type'];
                    LogEvent('Failed to collect SSL certificate: ' + errstr  +
                                                     ', ' + FHttpRest.ResponseJson.S['detail']) ;
                    Exit;
                end;
            end;
            DumpJson;
(*  {
  "status": "valid",
  "expires": "2018-03-26T16:57:17Z",
  "identifiers": [
    {
      "type": "dns",
      "value": "test3.telecom-tariffs.co.uk"
    }
  ],
  "authorizations": [
    "https://acme-staging-v02.api.letsencrypt.org/acme/authz/6mDYqM5A5a7L3QnD0FxOUYI5FflSq-3MMqvfOWYPxcg"
  ],
  "finalize": "https://acme-staging-v02.api.letsencrypt.org/acme/finalize/5763117/97378",
  "certificate": "https://acme-staging-v02.api.letsencrypt.org/acme/cert/fac3d324243e1a7c73126018c851287377b5"
}
*)
            fAcmeOrderStatus := FHttpRest.ResponseJson.S['status'];
            fAcmeOrderExpiresDT := RFC3339_StrToDate(FHttpRest.ResponseJson.S['expires']);
            fAcmeCertURL := FHttpRest.ResponseJson.S['certificate'];
            if fAcmeOrderStatus <> 'valid' then begin
                LogEvent('Failed to collect SSL certificate, Order Status: ' + fAcmeOrderStatus);
                exit;
            end;
            if (fAcmeCertURL = '') then begin
                LogEvent('Failed to collect SSL certificate, no certificate URL');
                exit;
            end;
        end;

    // see if downloading certificate
        if fAcmeCertURL <> '' then begin
            LogEvent ('Certificate download URL: ' + fAcmeCertURL);
            if (NOT AcmeGetRequest(httpPOST, fAcmeCertURL, Nil)) then exit;
            if fAcmeLastStatus > 202 then begin
                LogEvent('Failed to download SSL certificate from: ' + fAcmeCertURL);
                Exit;
            end;
            I := LastDelimiter('/', fAcmeCertURL);
            if I > 0 then begin
                fAcmeCertSerial := Copy (fAcmeCertURL, I + 1, 999);
                LogEvent ('Certificate serial: ' + fAcmeCertSerial);
            end;
        end;

    // do we need to load private key
        if NOT FNewSslCert.IsPKeyLoaded then begin
            try
                LogEvent('Loading old private key from: ' + fFilePrvKey);
                FNewSslCert.PrivateKeyLoadFromPemFile(fFilePrvKey, FPrivKeyPassword);
            except
                on E:Exception do
                begin
                    LogEvent ('Failed to load old private key: ' + E.Message);
                    Exit;
                end;
            end;
        end;
        fNewCertLines := fAcmeCertLines;
        LogEvent ('Certificate(s):' + IcsCRLF + fAcmeCertLines);

    // save lots of certificates in different formats and places
        if NOT SaveCertificateFiles(fCertCommonName) then Exit;

    // delete old challenges
        RemoveChallgs(fCertCommonName);

    // all donem
        FIssueState := IssStateCollect;
        for I := 0 to FCertSubAltNames.Count - 1 do begin
            FCertSubAltNames[I].SAIssueState := FIssueState;
            FCertSubAltNames[I].SADoneDT := FOrderCertsDT;
        end;
        DBWriteCNDomain;
        if Assigned(FOnNewCert) then FOnNewCert(Self);

    // see if closing account
        if FAutoAccountClose then FPendAccountClose := True; { V8.63 } 

        Result := True;
    except
        on E:Exception do begin
            LogEvent ('Fatal ACME protocol error: ' + E.Message);
        end;
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslX509Certs.AcmeV2OrderCancel (Revoke: Boolean): Boolean;
var
    CommonName: string ;
begin
    result := false ;
    CommonName := '';
{    if NOT SetPartFNames (true) then Exit ;  // set long path name with orderid
    SetFullFileNames (FPartFNameOrder) ;

   // for revoke, we need the old certificate
    if revoke then begin
        if NOT FileExists (fFileCertPem) then begin
            LogEvent ('Can not find cetificate for this order: ' +  fFileCertPem);
            Exit ;
        end;
        try
            FNewSslCert.ClearAll ;
            FNewSslCert.LoadFromPemFile (fFileCertPem) ;
        except
            on E:Exception do begin
                LogEvent ('Failed to load certifcate file: ' + fFileCertPem + ' - ' + E.Message);
                Exit ;
            end;
        end;
        if NOT FNewSslCert.IsCertLoaded then begin
            LogEvent ('Failed to load cetificate for this order: ' +  fFileCertPem);
            Exit ;
        end;
        FNewCertLines := FNewSslCert.SaveCertToText (false) ;
    end;

    LogEvent (IcsCRLF + 'Checking CertCentre OrderId: ' + fSuppOrderId + ' for ' + fCertCommonName);
 }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// check if challenge for a domain is completed
function TSslX509Certs.CheckChallg(const aDomain: String): Boolean;
var
    ChallgNum: Integer;
begin
    Result := False;
    ChallgNum := DBFindChallengeNum(aDomain);
    if ChallgNum < 0 then begin
        LogTimeStamp;
        LogEvent('Can Not Find Challenge for: ' + aDomain);
        Exit;
    end;
    with FChallengeItems [ChallgNum] do begin
        if (CIssueState = IssStateChallgOK) and (CDoneDT > 10) then
            Result := True
        else begin
            if SupplierProto = SuppProtoAcmeV2 then
                Result := AcmeV2CheckChallg(ChallgNum)
            else
                Result := False;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// remove all challenges for certificate common name, once completed
procedure TSslX509Certs.RemoveChallgs(const CNDomain: String);
var
    I: Integer;
begin
    if FChallengesTot = 0 then Exit;
    for I := 0 to Length(FChallengeItems) - 1 do begin
        if (FChallengeItems [I].CCommonName = CNDomain) then begin
            with FChallengeItems [I] do begin
             // delete old challenge files
                if (CWKFullName <> '') then begin
                    if FileExists(CWKFullName) then DeleteFile(CWKFullName);
                end;
                if (CAcmeAlpnCert <> '') then begin
                    if FileExists(CAcmeAlpnCert) then DeleteFile(CAcmeAlpnCert);
                end;
                DBDeleteChallenge(CDomain);  // remove from database
            end;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// look for any completed challenges, try to complete orders by getting certificate
procedure TSslX509Certs.ChallengeOnTimer(Sender : TObject);
var
    I: Integer;

 // look for other pending challenges for same common namw
    function CheckPending(const CNDomain: String): Boolean;
    var
        J: Integer;
    begin
        Result := False;
        if (FChallengesTot < 1) then Exit;
        for J:= 0 to Length(FChallengeItems) - 1 do begin
            with FChallengeItems [J] do begin
                if (CDomain = '') then continue;
                if (CNDomain <> CCommonName) then continue;
                if (CIssueState = IssStateChallgPend) then begin
                    Result := True;
                end;
           end;
       end;
    end;

begin
    if FX509BusyFlag then Exit;
    if NOT IcsTestTrgTick64 (FChkChallgTrg) then Exit;   { V8.63 not yet }
    FChallengeTimer.Enabled := False;
    FChkChallgTrg := IcsGetTrgSecs64 (120);  { V8.63 next check two minutes }
    FX509BusyFlag := True;
    try // finally
        if (FChallengesTot > 0) then begin
            for I := 0 to Length(FChallengeItems) - 1 do begin
                try // except
                  // sanity check, account may have been closed from newcert event
                    if (FChallengesTot = 0) then Break;
                    if (Length(FChallengeItems) = 0) then Break;
                    if (FControlFile = Nil) then Break;  { V8.63 account may be closed }
                    if (FSupplierProto = SuppProtoNone) then Break;
                    FChkChallgTrg := IcsGetTrgSecs64 (10);  { V8.63 next check 10 secs }
                    with FChallengeItems [I] do begin
                        if (CDomain = '') then continue;

                    // see if challenge has completed
                        if (CIssueState = IssStateChallgPend) then begin
                            if SupplierProto = SuppProtoAcmeV2 then
                                AcmeV2CheckChallg(I)
                            else if SupplierProto = SuppProtoCertCentre then
                                CCCheckChallg(I)
                            else
                                Continue;
                        end;

                    // if all challenges completed, get certificate
                        if (CIssueState = IssStateChallgOK) then begin
                            if CheckPending(CCommonName) then begin
                                LogEvent('Web Server Challenge Response Sent for: ' + CDomain);
                                Continue;
                            end;
                         // delete challenge
                            RemoveChallgs(CDomain);

                         // collect certificates
                            if SupplierProto = SuppProtoAcmeV2 then
                                AcmeV2GetCert
                            else if SupplierProto = SuppProtoCertCentre then
                                CCGetCert
                            else
                                Continue;
                        end;

                      { V8.63 challenge not complete after one hour, slow down checks }
                        if (CIssueState = IssStateChallgPend) and ((Now - CStartDT) > (1.0/24.0)) then begin
                            FChkChallgTrg := IcsGetTrgSecs64 (120);
                        end;
                    end;
                except
                    on E:Exception do begin
                      LogEvent ('Failed to read Challenge Item in Timer: ' + E.Message);
                    end;
                end;
            end;
        end;

    finally
        FX509BusyFlag := False;
        FChallengeTimer.Enabled := True;

      { V8.63 challenges finished should we stop server and close account }
        if ((FChallengesTot = 0) and FPendAccountClose) or
               (IcsElapsedMins64(FAccountLastTick) >= FAccountTimeOutMins) then begin
            StopDomSrv;
            CloseAccount;
            FPendAccountClose := False;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// close certificate supplier account, really just clean up
function TSslX509Certs.CloseAccount: Boolean;
begin
    Result := False;
    FChallengeTimer.Enabled := False;
    FPendAccountClose := False;
    StopDomSrv;
    if (FSupplierProto = SuppProtoNone) and
                 (FControlFile = Nil) and (FCnrtFileName = '') then Exit;
    FSupplierProto := SuppProtoNone;
    FDirCertWork := '';
    FIssueState := IssStateNone;
    FCnrtFileName := '';
    FreeAndNil(FControlFile);
    SetLength(FDomainItems, 0);
    FChallengesTot := 0;
    SetLength(FChallengeItems, 0);
    FCertSANs.Clear;
    LogEvent ('Account Closed OK');
    Result := True;
    if Assigned(FOnSuppDBRefresh) then FOnSuppDBRefresh(Self);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// open certificate supplier account from a specific directory
// optionally create new account if not found
// sets DbCNDomains list of certificate common name domains created using
// the account
function TSslX509Certs.OpenAccount(const WorkDir: String; CreateNew: Boolean = False): Boolean;
var
    NewProto: TSupplierProto ;
begin
    Result := False;
    NewProto := FSupplierProto ;  { V8.63 }
    FSupplierProto := SuppProtoNone;
    CloseAccount;
    FAccountLastTick := IcsGetTickCount64;  { V8.63 }
    FLastError := '';                       { V8.63 }
    if FAccountTimeOutMins <= 2 then FAccountTimeOutMins := 10; { V8.63 }

  // ignore public properties, read everything from database
    if NOT DBReadAccount(IncludeTrailingPathDelimiter(WorkDir), True) then begin
        if NOT CreateNew then Exit;
        LogEvent ('Old Account Not Found, Creating New Account in: ' + WorkDir);
        FSupplierProto := NewProto ;   { V8.63 }
    end;
    if FSupplierProto = SuppProtoAcmeV2 then
        Result := SetAcmeAccount (CreateNew)

 // CertCentre may need manual OAuth2 login to be completed!!!
    else if SupplierProto = SuppProtoCertCentre then begin
        FPendOpenAccount := WorkDir;
        Result := SetCertCentre(CreateNew);
        if (NOT Result) and (FOAAccToken = '') then begin
            LogEvent ('CertCentre Waiting for OAuth2 Login, Will Then Open Again');
            Exit;
        end;
        FPendOpenAccount := '';
    end
    else if SupplierProto = SuppProtoServtas then
      //  Result := SetServtas;
    else begin
            LogEvent ('Can Not Open Account, Unknown Supplier Protocol');
    end;

 // check for old challenges, start timer to see if done
    if Result then begin
        LogEvent ('Opened Supplier Account for: ' + FSupplierTitle +  ', Protocol: ' +
                            SupplierProtoLits [FSupplierProto] + ', From: ' + WorkDir);
        DBReadChallenges;
        FChallengeTimer.Enabled := True;
        ChallengeOnTimer(Self);  // immediate
     end
     else begin
         FSupplierProto := SuppProtoNone;
         FLastError := FLastResponse;   { V8.63 }
     end;
    if Assigned(FOnSuppDBRefresh) then FOnSuppDBRefresh(Self);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// save new common domain name with public properties
function TSslX509Certs.CertSaveDomain(const aDomain: String): Boolean;
begin
    Result := False;
    if aDomain <> CertCommonName then Exit;
    if CertSubAltNames.Count = 0 then Exit;
    if SupplierProto = SuppProtoNone then Exit;
    FLastError := '';                       { V8.63 }

  // read non-public props, it the domain exists
    DBReadCNDomain(aDomain, False);
    if (SupplierProto = SuppProtoAcmeV2) then
        Result := AcmeCheckOrder(False, True)  // update database, no domain check
    else if SupplierProto = SuppProtoCertCentre then
        Result := CCCheckOrder(False, True)  // update database, no domain check
    else if SupplierProto = SuppProtoServtas then
      //  Result := ServtasCheckOrder(True, False)
    else
        LogEvent('Can Not Check Order, Unknown Supplier Protocol');
    if Result then
        LogEvent('Saved New Domain OK in Database: ' + aDomain)
    else begin
        FLastError := FLastResponse;   { V8.63 }
        LogEvent('Failed to Save New Domain in Database: ' + aDomain);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// read common domain name properties from database
function TSslX509Certs.CertReadDomain(const aDomain: String): Boolean;
begin
    Result := False;
    if DBFindDomain (aDomain) < 0 then begin
        LogEvent('Domain Not Found in Database: ' + aDomain);
        Exit;
    end;
    fAcmeOrderStatus := '';
    FAcmeOrderFinalizeUrl := '';
    FAcmeOrderObjUrl := '';
    fCertCommonName := '';
    FCertSubAltNames.Clear;
    FSuppCertProduct := '';
    FSuppOrderId := '';
    FSuppOrderRef := '';
    FLastError := '';                       { V8.63 }

  // ignore public properties, read everything from database
    Result := DBReadCNDomain(aDomain, True);
    if NOT Result then FLastError := FLastResponse;   { V8.63 }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// read and check common domain name properties from database
function TSslX509Certs.CertCheckDomain(const aDomain: String): Boolean;
begin
    Result := CertReadDomain(aDomain);
    if NOT Result then Exit;
    if (SupplierProto = SuppProtoAcmeV2) then
        Result := AcmeCheckOrder(True, False)  // don't update database yet
    else if SupplierProto = SuppProtoCertCentre then
        Result := CCCheckOrder(True, False)    // don't update database yet
    else if SupplierProto = SuppProtoServtas then
      //  Result := ServtasCheckOrder(True, False)
    else
        LogEvent('Can Not Check Order, Unknown Supplier Protocol');
    if Result then
        LogEvent('Checked Certificate Order OK for: ' + aDomain)
    else begin
        FLastError := FLastResponse;   { V8.63 }
        LogEvent('Failed to Check Certificate Order for: ' + aDomain);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// order certificate for common domain name and collect certificate when ready
function TSslX509Certs.CertOrderDomain(const aDomain: String): Boolean;
var
    Collected: Boolean;
begin
    Result := CertReadDomain(aDomain);
    if NOT Result then Exit;
    Collected := False;
    FIssueState := IssStateNone;
    if SupplierProto = SuppProtoAcmeV2 then begin
        Result := AcmeV2OrderCert;
        if FIssueState >= IssStateChallgOK then begin
            Result := AcmeV2GetCert;
            if Result then Collected := True;   { V8.63 }
        end;
    end
    else if SupplierProto = SuppProtoCertCentre then
        Result := CCOrderCert
    else if SupplierProto = SuppProtoServtas then
      //  Result := ServtasOrderCert;
    else begin
            LogEvent('Can Not Order Certificate, Unknown Supplier Protocol');
    end;
    if Result and Collected then
        LogEvent('Collected Certificate OK for: ' + aDomain)    { V8.63 }
    else if Result and (NOT Collected) then
        LogEvent('Ordered Certificate OK for: ' + aDomain)
    else begin
        FLastError := FLastResponse;   { V8.63 }
        LogEvent('Failed to Order Certificate for: ' + aDomain);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// check if order ready and collect certificate
function TSslX509Certs.CertCollectDomain(const aDomain: String): Boolean;
begin
    Result := false ;
    FLastError := '';                       { V8.63 }
    if aDomain <> fCertCommonName then begin
        if NOT CertReadDomain(aDomain) then Exit;
    end;
    if FIssueState < IssStateChallgPend then begin
        LogEvent('Can Not Collect Certificate, No Pending Order');
        Exit;
    end;
    if FIssueState >= IssStateCollect then begin
        LogEvent('Order Already Collected');
        Exit;
    end;
    if SupplierProto = SuppProtoAcmeV2 then
        Result := AcmeV2GetCert
     else if SupplierProto = SuppProtoCertCentre then
        Result := CCGetCert
     else if SupplierProto = SuppProtoServtas then
      //  Result := ServtasGetOneOrder;
     else begin
            LogEvent('Can Not Collect Certificate, Unknown Supplier Protocol');
     end;
    if Result then
        LogEvent('Collected Certificate OK for: ' + aDomain)
    else begin
        FLastError := FLastResponse;   { V8.63 }
        LogEvent('Failed to Collect Certificate for: ' + aDomain);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// cancel order, still pending or completed, may get refund for commercial order
function TSslX509Certs.CertCancelDomain(const aDomain: String): Boolean;
begin
    Result := false ;
    FLastError := '';                       { V8.63 }
    if aDomain <> fCertCommonName then begin
        if NOT CertReadDomain(aDomain) then Exit;
    end;
    if FIssueState < IssStateChallgPend then begin
        LogEvent('Can Not Cancel, No Pending Order');
        Exit;
    end;
    if SupplierProto = SuppProtoAcmeV2 then
        Result := AcmeV2OrderCancel(False)
     else if SupplierProto = SuppProtoCertCentre then
        Result := CCCancelOrder(False)
     else if SupplierProto = SuppProtoServtas then
      //  Result := ServtasCancelOrder(False);
     else begin
        LogEvent('Can Not Cancel Order, Unknown Supplier Protocol');
     end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// cancel order, still pending or completed, may get refund for commercial order
// also revoke certificate if already issued
function TSslX509Certs.CertRevokeDomain(const aDomain: String): Boolean;
begin
    Result := false ;
    if aDomain <> fCertCommonName then begin
        if NOT CertReadDomain(aDomain) then Exit;
    end;
    if FIssueState < IssStateCollect then begin
        LogEvent('Can Not Revoke, No Certificate Collected');
        Exit;
    end;
    if SupplierProto = SuppProtoAcmeV2 then
        Result := AcmeV2OrderCancel(True)
    else if SupplierProto = SuppProtoCertCentre then
        Result := CCCancelOrder(True)
    else if SupplierProto = SuppProtoServtas then
      //  Result := ServtasCancelOrder(True);
    else begin
        LogEvent('Can Not Cancel Order, Unknown Supplier Protocol');
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// redistribute previously collected certicate, locally and to servers
function TSslX509Certs.CertRedistDomain(const aDomain: String): Boolean;
begin
    Result := false ;
    if aDomain <> fCertCommonName then begin
        if NOT CertReadDomain(aDomain) then Exit;
    end;
    Result := RedistribteFiles;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// remove domain from database
function TSslX509Certs.CertRemoveDomain(const aDomain: String): Boolean;
begin
    Result := false ;
    if aDomain <> fCertCommonName then begin
        if NOT CertReadDomain(aDomain) then Exit;
    end;
    RemoveChallgs(aDomain);
    Result := DBDeleteCNDomain(aDomain);
    if Result then
        LogEvent('Common Name Domain Removed from Database: ' + aDomain);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// get order result, as best we can for logging and emails
function TSslX509Certs.GetOrderResult: String;
begin
    if SupplierProto = SuppProtoNone then begin
       Result := 'Order Failed, No Supplier Database Opened';
       Exit;
    end;
    Result := 'Account Database Supplier: ' + FSupplierTitle + IcsCRLF +
              'Supplier: Protocol: ' + SupplierProtoLits [FSupplierProto] + IcsCRLF +
              'Challenge Type: ' + ChallengeTypeLits[FSuppCertChallenge] + IcsCRLF +
              'Product: ' + FSuppCertProduct + IcsCRLF;
    if FIssueState < IssStateCollect then begin
       Result := Result + 'Order Not Yet Completed, State: ' +
                                             IssueStateLits[FIssueState];
    end
    else begin
        Result := Result + 'SSl Certificate Order Completed OK' + IcsCRLF +
            'Supplier Order Id: ' + FSuppOrderId + IcsCRLF +
            'Our Order Number: ' + IntToStr(FNewOrderNum) + IcsCRLF +
            'Certificate Saved at: ' + FFileFinalBundle + IcsCRLF +
            FNewSslCert.CertInfo(False);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// load own Certificate Authority cert and private key ready to sign requests
function TSslX509Certs.LoadOwnCA: Boolean;
begin
    Result := False;
    LogTimeStamp;
    FNewSslCert.DoClearCA;
    FNewInterLines := '';
    if (FCACertFile = '') or (NOT FileExists(FCACertFile)) then begin
        LogEvent ('Can Not Found Own CA Certificate File: ' + FCACertFile);
    end;
    try
        FNewSslCert.LoadFromFile(FCACertFile, croTry, croNo, FCAPkeyPw);
        if NOT FNewSslCert.IsPKeyLoaded then begin
            if (FCAPkeyFile = '') or (NOT FileExists(FCAPkeyFile)) then begin
                LogEvent('Can Not Find Own CA Private Key File: ' + FCAPkeyFile);
                Exit;
            end;
            FNewSslCert.PrivateKeyLoadFromPemFile(FCAPkeyFile, FCAPkeyPw);
        end;
        if NOT FNewSslCert.IsCertLoaded then begin
            LogEvent('No Certificate Loaded');
            exit;
        end;
        if Pos ('CA=TRUE', FNewSslCert.BasicConstraints) = 0 then begin
            LogEvent('Certificate is not a CA');
            exit;
        end;
        if NOT FNewSslCert.SelfSigned then  // need to add intermediate CA to bundle
            FNewInterLines := FNewSslCert.SaveCertToText(False);
        FNewSslCert.X509CA := FNewSslCert.X509;
        FNewSslCert.PrivKeyCA := FNewSslCert.PrivateKey;
        LogEvent('Loaded Own Certificate Authority OK' + IcsCRLF +
                                                FNewSslCert.CertInfo(False));
        Result := True;
    except
        on E:Exception do begin
            LogEvent('Failed to Load Own CA: ' + E.Message);
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// create new certificate signed by our own Certificate Authority
function TSslX509Certs.OwnCASign: Boolean;
begin
    Result := False;
    LogTimeStamp;
    LogEvent ('Checking Account Directory: ' + FDirCertWork);
    if NOT ForceDirectories(FDirCertWork) then begin
        LogEvent ('Failed to Create Directory: ' + FDirCertWork);
        exit;
    end;
    if NOT DBOpenINI(FDirCertWork, True) then Exit;
    DBReadAccount(FDirCertWork, False);  // ignore errors
    if NOT FNewSslCert.IsCALoaded then begin
        LogEvent('Must Specify CA Certificate First');
        exit;
    end;
    FSupplierProto := SuppProtoOwnCA;
    FSupplierTitle := 'Own CA';
    if NOT DBWriteAccount then Exit;

// see if using details from old CSR
    FNewSslCert.DoClearCerts;
    if FCertCsrOrigin = CsrOriginFile then begin
        if NOT CheckCSR(True) then Exit;  // sets CommonName and SANs
    end;

// initial set-up
    if (FCertCommonName = '') then begin
        LogEvent('Must Specify Domain Common Name for Certifcate');
        Exit;
    end;
    LogEvent('Creating Certificate Signed by Own CA Certificate for' + FCertCommonName) ;

 // make sure common name is also in SANs, so we can ignore it subsequently
    BuildSANList;

// order info
    FNewOrderNum := DBNewOrderNum;
    FSuppOrderRef := 'ICS-' + IntToStr(FNewOrderNum);
    FSuppCertProduct := FSupplierTitle;
    FNewCertPrefix := 'OwnCA-' ;


 // create CSR and private key
// work file names, in account directory, with orderid (no work names)
// fails if can not create directories
    FNewSslCert.ClearAll;
    fSuppOrderId := '';
    if NOT SetPartFNames (False) then Exit ;
    SetFullFileNames (FPartFNameWork) ;

// create private key and certificate service request
    if NOT CreateKeyandReq then exit ;

// set extensions
    FNewSslCert.BasicIsCA := False;
    FNewSslCert.ExpireDays := FCertValidity;
    FNewSslCert.BasicPathLen := 0;
    FNewSslCert.KeyCertSign := True;
    FNewSslCert.KeyCRLSign := False;
    FNewSslCert.KeyDigiSign := True;
    FNewSslCert.KeyDataEnc := False;
    FNewSslCert.KeyKeyEnc  := True;
    FNewSslCert.KeyKeyAgree := False;
    FNewSslCert.KeyNonRepud  := False;
    FNewSslCert.KeyExtClient  := True;
    FNewSslCert.KeyExtServer  := True;
    FNewSslCert.KeyExtEmail  := False;
    FNewSslCert.KeyExtCode := False;
    if FCertSerNumType = SerNumRandom then
        FNewSslCert.SerialNum := 0   // random serial
    else
        FNewSslCert.SerialNum := FNewOrderNum;
    FSuppOrderId := IntToStr(FNewOrderNum);
    try
        FNewSslCert.DoSignCertReq(False);
        LogEvent('Created Certificate Signed by Own CA Certificate OK');
    except
        on E:Exception do begin
            LogEvent('Failed to Sign CSR with Own CA: ' + E.Message);
            Exit;
        end;
    end;
    if NOT SetPartFNames (False) then Exit ;   // build file names with order id
    fNewCertLines := FNewSslCert.SaveCertToText(False);
    LogEvent ('Certificate(s):' + IcsCRLF + fNewCertLines);

// save lots of certificates in different formats and places
    Result := SaveCertificateFiles(fCertCommonName);

// add our new certificate to a database
    if Result then begin
        FNewSslCert.CADBFile := FDirCertWork + FileCADB;
        try
            FNewSslCert.SaveToCADatabase(FFileFinalCert);
            LogEvent('Updated CA Database: ' + FNewSslCert.CADBFile);
        except
            on E:Exception do begin
                LogEvent('Failed to Write CA Database: ' + E.Message);
          end;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
// create new self signed certificate
function TSslX509Certs.SelfSign: Boolean;
begin
    Result := False;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

{$ENDIF USE_SSL}

end.
