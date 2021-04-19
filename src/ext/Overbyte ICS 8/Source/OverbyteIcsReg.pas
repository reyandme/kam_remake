{$IFNDEF ICS_INCLUDE_MODE}
unit OverbyteIcsReg;
  {$DEFINE ICS_COMMON}
{$ENDIF}

{
Feb 15, 2012 Angus - added OverbyteIcsMimeUtils
May 2012 - V8.00 - Arno added FireMonkey cross platform support with POSIX/MacOS
                   also IPv6 support, include files now in sub-directory
Jun 2012 - V8.00 - Angus added SysLog and SNMP components VCL only for now
Jul 2012   V8.02   Angus added TSslHttpAppSrv
Sep 2013   V8.03 - Angus added TSmtpSrv and TSslSmtpSrv
May 2017   V8.45 - Angus added TIcsProxy, TIcsHttpProxy
Apr 2018   V8.54 - Angus added TSslHttpRest, TSimpleWebSrv and TRestOAuth
May 2018   V8.54 - Angus added TSslX509Certs
Oct 2018   V8.58 - New components now installed for FMX and VCL
                   Added subversion to sIcsLongProductName for splash screen
Nov 2019   V8.59 - Version only
Mar 2019   V8.60 - Angus added TIcsMailQueue, TIcsIpStrmLog, TIcsWhoisCli,
                     TIcsTimeServer, TIcsTimeClient, TIcsBlacklist,
                     TIcsFileCopy, TIcsFtpMulti, TIcsHttpMulti.
                   For Delphi 2007 only, added TFtpClientW, TFtpServerW,
                     TIcsFileCopyW, TIcsFtpMultiW and TIcsHttpMultiW.
                   Added Forum and Wiki URLs to About Box.
Apr 2019  V8.61  - Added TDnsQueryHttps, TIcsSms
May 2019  V8.62  - Version only
Oct 2019  V8.63  - Version only
Nov 2019  V8.64  - Version only

}


{$I Include\OverbyteIcsDefs.inc}
{$IFDEF USE_SSL}
    {$I Include\OverbyteIcsSslDefs.inc}
{$ENDIF}
(*
{$IFDEF BCB}
  { So far no FMX support for C++ Builder, to be removed later }
  {$DEFINE VCL}
  {$IFDEF FMX}
    {$UNDEF FMX}
  {$ENDIF}
{$ENDIF}
*)
{$IFNDEF COMPILER16_UP}
  {$DEFINE VCL}
  {$IFDEF FMX}
    {$UNDEF FMX}
  {$ENDIF}
{$ENDIF}

{$IFDEF VCL}
  {$DEFINE VCL_OR_FMX}
{$ELSE}
  {$IFDEF FMX}
    {$DEFINE VCL_OR_FMX}
  {$ENDIF}
{$ENDIF}

interface

uses
  {$IFDEF FMX}
    FMX.Types,
    Ics.Fmx.OverbyteIcsWndControl,
    Ics.Fmx.OverbyteIcsWSocket,
    Ics.Fmx.OverbyteIcsDnsQuery,
    Ics.Fmx.OverbyteIcsFtpCli,
    Ics.Fmx.OverbyteIcsFtpSrv,
    Ics.Fmx.OverbyteIcsMultipartFtpDownloader,
    Ics.Fmx.OverbyteIcsHttpProt,
    Ics.Fmx.OverbyteIcsHttpSrv,
    Ics.Fmx.OverbyteIcsMultipartHttpDownloader,
    Ics.Fmx.OverbyteIcsHttpAppServer,
    Ics.Fmx.OverbyteIcsCharsetComboBox,
    Ics.Fmx.OverbyteIcsPop3Prot,
    Ics.Fmx.OverbyteIcsSmtpProt,
    Ics.Fmx.OverbyteIcsNntpCli,
    Ics.Fmx.OverbyteIcsFingCli,
    Ics.Fmx.OverbyteIcsPing,
    {$IFDEF USE_SSL}
      Ics.Fmx.OverbyteIcsSslSessionCache,
      Ics.Fmx.OverbyteIcsSslThrdLock,
      Ics.Fmx.OverbyteIcsProxy,
      Ics.Fmx.OverbyteIcsSslHttpRest,
      Ics.Fmx.OverbyteIcsSslX509Certs,
      Ics.Fmx.OverbyteIcsIpStreamLog,
      Ics.Fmx.OverbyteIcsMailQueue,
      Ics.Fmx.OverbyteIcsFtpMulti,
      Ics.Fmx.OverbyteIcsHttpMulti,
    {$ENDIF}
    Ics.Fmx.OverbyteIcsWSocketE,
    Ics.Fmx.OverbyteIcsWSocketS,
    Ics.Fmx.OverbyteIcsWhoisCli,
    Ics.Fmx.OverbyteIcsSntp,
    Ics.Fmx.OverbyteIcsBlacklist,
    Ics.Fmx.OverbyteIcsFileCopy,
  {$ENDIF FMX}
  {$IFDEF VCL}
    Controls,
    OverbyteIcsWndControl,
    OverbyteIcsWSocket,
    OverbyteIcsDnsQuery,
    OverbyteIcsFtpCli,
    OverbyteIcsFtpSrv,
    OverbyteIcsMultipartFtpDownloader,
    OverbyteIcsHttpProt,
    OverbyteIcsHttpSrv,
    OverbyteIcsMultipartHttpDownloader,
    OverbyteIcsHttpAppServer,
    OverbyteIcsCharsetComboBox,
    OverbyteIcsPop3Prot,
    OverbyteIcsSmtpProt,
    OverbyteIcsNntpCli,
    OverbyteIcsFingCli,
    OverbyteIcsPing,
    {$IFDEF USE_SSL}
      OverbyteIcsSslSessionCache,
      OverbyteIcsSslThrdLock,
      OverbyteIcsProxy,
      OverbyteIcsSslHttpRest,
      OverbyteIcsSslX509Certs,
      OverbyteIcsIpStreamLog,
      OverbyteIcsMailQueue,
      OverbyteIcsFtpMulti,
      OverbyteIcsHttpMulti,
    {$ENDIF}
    OverbyteIcsWSocketE,
    OverbyteIcsWSocketS,
    OverbyteIcsSysLogClient,
    OverbyteIcsSysLogServer,
    OverbyteIcsSnmpCli,
    OverbyteIcsSmtpSrv,
    OverbyteIcsWhoisCli,
    OverbyteIcsSntp,
    OverbyteIcsBlacklist,
    OverbyteIcsFileCopy,
   {$IFDEF DELPHI11}
      OverbyteIcsFtpCliW,
      OverbyteIcsFtpSrvW,
      OverbyteIcsFileCopyW,
      OverbyteIcsFtpMultiW,
      OverbyteIcsHttpMultiW,
   {$ENDIF}
    // VCL only
    OverbyteIcsMultiProgressBar,
    OverbyteIcsEmulVT, OverbyteIcsTnCnx, OverbyteIcsTnEmulVT, OverbyteIcsTnScript,
    {$IFNDEF BCB}
      OverbyteIcsWSocketTS,
    {$ENDIF}
  {$ENDIF VCL}
  {$IFDEF ICS_COMMON}
    OverbyteIcsMimeDec,
    OverbyteIcsMimeUtils,
    OverbyteIcsTimeList,
    OverbyteIcsLogger,
    {$IFNDEF BCB}
      OverbyteIcsCookies,
    {$ENDIF !BCB}
  {$ENDIF}
  {$IFDEF RTL_NAMESPACES}System.SysUtils{$ELSE}SysUtils{$ENDIF},
  {$IFDEF RTL_NAMESPACES}System.Classes{$ELSE}Classes{$ENDIF};

procedure Register;

implementation

uses
{$IFDEF MSWINDOWS}
  {$IFDEF COMPILER10_UP}
    {$IFDEF RTL_NAMESPACES}Winapi.Windows{$ELSE}Windows{$ENDIF},
    ToolsApi,
  {$ENDIF}
  {$IFDEF COMPILER6_UP}
    DesignIntf, DesignEditors;
  {$ELSE}
    DsgnIntf;
  {$ENDIF}
{$ENDIF}

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure Register;
{$IFDEF COMPILER16_UP}
{$IFDEF VCL_OR_FMX}
var
    LClassGroup: TPersistentClass;
{$ENDIF}
{$ENDIF}
begin
{$IFDEF COMPILER16_UP}
  {$IFDEF VCL_OR_FMX}
    {$IFDEF FMX}
      LClassGroup := TFmxObject;
    {$ELSE}
      LClassGroup := TControl;
    {$ENDIF}
    GroupDescendentsWith(TIcsWndControl, LClassGroup);
    GroupDescendentsWith(TDnsQuery, LClassGroup);
    GroupDescendentsWith(TFingerCli, LClassGroup);
  {$ENDIF VCL_OR_FMX}
{$ENDIF COMPILER16_UP}

{$IFDEF VCL_OR_FMX}
    RegisterComponents('Overbyte ICS', [
      TWSocket, TWSocketServer,
      THttpCli, THttpServer, THttpAppSrv, TMultipartHttpDownloader,
      TFtpClient, TFtpServer, TMultipartFtpDownloader,
      TSmtpCli, TSyncSmtpCli, THtmlSmtpCli,
      TPop3Cli, TSyncPop3Cli,
      TNntpCli, THtmlNntpCli,
      TDnsQuery, TFingerCli, TPing,
      TIcsCharsetComboBox,
      {$IFDEF DELPHI11}
        TFtpClientW,    { V8.60 }
        TFtpServerW,    { V8.60 }
        TIcsFileCopyW,  { V8.60 }
      {$ENDIF}
      TIcsBlacklist,     { V8.60 }
      TIcsFileCopy       { V8.60 }
    ]);
{$ENDIF}
{$IFDEF VCL}
    RegisterComponents('Overbyte ICS', [
      { Not yet ported to FMX }
      TEmulVT, TTnCnx, TTnEmulVT, TTnScript,
      {$IFNDEF BCB}
        TWSocketThrdServer,
      {$ENDIF}
      TMultiProgressBar,
      TSysLogClient,
      TSysLogServer,
      TSnmpCli,
      TSmtpServer,
      TIcsWhoisCli,      { V8.60 }
      TIcsTimeServer,    { V8.60 }
      TIcsTimeClient     { V8.60 }
    ]);
{$ENDIF VCL}
{$IFDEF ICS_COMMON}
    RegisterComponents('Overbyte ICS', [
      { Components neither depending on the FMX nor on the VCL package }
      TMimeDecode,
      TMimeDecodeEx,
      TMimeDecodeW,
      TMimeTypesList,
   {$IFNDEF BCB}
      TIcsCookies,
   {$ENDIF !BCB}
      TTimeList, TIcsLogger
    ]);
{$ENDIF}

{$IFDEF USE_SSL}
  {$IFDEF COMPILER16_UP}
    {$IFDEF VCL_OR_FMX}
      GroupDescendentsWith(TSslBaseComponent, LClassGroup);
      GroupDescendentsWith(TSslStaticLock, LClassGroup);
    {$ENDIF VCL_OR_FMX}
  {$ENDIF COMPILER16_UP}

  {$IFDEF VCL_OR_FMX}
    RegisterComponents('Overbyte ICS SSL', [
      TSslWSocket, TSslWSocketServer,
      TSslContext,
      TSslFtpClient, TSslFtpServer,
      TSslHttpCli, TSslHttpServer, TSslHttpAppSrv,
      TSslPop3Cli,
      TSslSmtpCli, TSslHtmlSmtpCli,
      TSslNntpCli,
      TSslAvlSessionCache,
      TIcsProxy,
      TIcsHttpProxy,
      TSslHttpRest,   { V8.54 }
      TSimpleWebSrv,  { V8.54 }
      TRestOAuth,     { V8.54 }
      TSslX509Certs,  { V8.54 }
      TIcsMailQueue,  { V8.60 }
      TIcsIpStrmLog,  { V8.60 }
      TIcsFtpMulti,   { V8.60 }
      TIcsHttpMulti,  { V8.60 }
      TDnsQueryHttps, { V8.61 }
      TIcsSms,        { V8.61 }
      {$IFDEF DELPHI11}
        TSslFtpClientW,  { V8.60 }
        TSslFtpServerW,  { V8.60 }
        TIcsFtpMultiW,   { V8.60 }
        TIcsHttpMultiW,  { V8.60 }
      {$ENDIF}
    {$IFDEF VCL}
      {$IFNDEF BCB}
        TSslWSocketThrdServer,
      {$ENDIF}
        TSslSmtpServer,
    {$ENDIF VCL}
    {$IFNDEF NO_DYNLOCK}
      TSslDynamicLock,
    {$ENDIF}
    {$IFNDEF OPENSSL_NO_ENGINE}
      TSslEngine,
    {$ENDIF}
      TSslStaticLock
    ]);
  {$ENDIF VCL_OR_FMX}
{$ENDIF USE_SSL}

{$IFDEF VCL_OR_FMX}
    RegisterPropertyEditor(TypeInfo(AnsiString), TWSocket, 'LineEnd',
      TWSocketLineEndProperty);
{$ENDIF}

{$IFDEF COMPILER10_UP}
  {$IFNDEF COMPILER16_UP}
    {$IFDEF ICS_COMMON}
      ForceDemandLoadState(dlDisable); // Required to show our product icon on splash screen
    {$ENDIF}
  {$ENDIF}
{$ENDIF}

end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{$IFDEF COMPILER10_UP}
{$IFDEF VCL}
{$R OverbyteIcsProductIcon.res}
const
{$IFDEF COMPILER14_UP}
    sIcsSplashImg       = 'ICSPRODUCTICONBLACK';
{$ELSE}
    {$IFDEF COMPILER10}
        sIcsSplashImg   = 'ICSPRODUCTICONBLACK';
    {$ELSE}
        sIcsSplashImg   = 'ICSPRODUCTICON';
    {$ENDIF}
{$ENDIF}
    sIcsLongProductName = 'Internet Component Suite V8.64';
    sIcsFreeware        = 'Freeware';
    sIcsDescription     = sIcsLongProductName + #13#10 +
                          //'Copyright (C) 1996-2018 by François PIETTE'+ #13#10 +
                          // Actually there's source included with different
                          // copyright, so either all or none should be mentioned
                          // here.
                          'http://www.overbyte.eu/' + #13#10 +
                          'Wiki: http://wiki.overbyte.eu/' + #13#10 +
                          'Support: https://en.delphipraxis.net/forum/37-ics-internet-component-suite/' + #13#10 +
                          'svn://svn.overbyte.be/ics/trunk' + #13#10 +
                          'http://svn.overbyte.be:8443/svn/ics/trunk' + #13#10 +
                          'User and password = "ics"';

var
    AboutBoxServices: IOTAAboutBoxServices = nil;
    AboutBoxIndex: Integer = -1;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure PutIcsIconOnSplashScreen;
var
    hImage: HBITMAP;
begin
    if Assigned(SplashScreenServices) then begin
        hImage := LoadBitmap(FindResourceHInstance(HInstance), sIcsSplashImg);
        SplashScreenServices.AddPluginBitmap(sIcsLongProductName, hImage,
                                             FALSE, sIcsFreeware);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure RegisterAboutBox;
begin
    if Supports(BorlandIDEServices, IOTAAboutBoxServices, AboutBoxServices) then begin
        AboutBoxIndex := AboutBoxServices.AddPluginInfo(sIcsLongProductName,
          sIcsDescription, 0, FALSE, sIcsFreeware);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure UnregisterAboutBox;
begin
    if (AboutBoxIndex <> -1) and Assigned(AboutBoxServices) then begin
        AboutBoxServices.RemovePluginInfo(AboutBoxIndex);
        AboutBoxIndex := -1;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

initialization
    PutIcsIconOnSplashScreen;
    RegisterAboutBox;

finalization
    UnregisterAboutBox;
{$ENDIF VCL}
{$ENDIF COMPILER10_UP}
end.

