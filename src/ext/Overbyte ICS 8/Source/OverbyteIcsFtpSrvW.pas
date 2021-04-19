{*_* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Author:       François PIETTE
Description:  TFtpServerW class encapsulate the FTP protocol (server side)
              See RFC-959 for a complete protocol description.
Creation:     April 21, 1998
Version:      8.64W
EMail:        francois.piette@overbyte.be  http://www.overbyte.be
Support:      https://en.delphipraxis.net/forum/37-ics-internet-component-suite/
Legal issues: Copyright (C) 1998-2020 by François PIETTE
              Rue de Grady 24, 4053 Embourg, Belgium
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
If not otherwise noted, changes are by Francois Piette
Apr 29, 1998  V0.90 released for beta testing.
May 01, 1998  V0.92 Adapted for Delphi 1.0
May 03, 1998  V0.93 Adapted for Delphi 2.0 and C++Builder
May 04, 1998  V0.94 Use '/' or '\' as path delimiter. Expose only '/' to the
              outside. Stripped any telnet options (IE send two !). Handled
              absolute path. Implemented SIZE and REST commands.
              Added support for UNC (not finished !)
May 06, 1998  V0.95 Corrected spurious 226 message on PASV mode STOR.
              Made GetInteger retunrs a LongInt.
              Use a LongInt for N in CommandPORT (needed for 16 bits)
              Added slash substitution in BuildFilePath command.
Jul 09, 1998  V1.00 Adapted for Delphi 4, removed beta status.
Jul 21, 1998  V1.01 Added OnValidateDele event
              Changed function to get file size (do not open the file)
Feb 14, 1999  V1.02 Replaced straight winsock call by indirect calls thru
              wsocket (this provide runtime link to winsock DLL).
Mar 06, 1999  V1.03 Added code from  Plegge, Steve <jsp@nciinc.com> to add
              APPE, XMKD, KRMD and STRU commands support.
Jul 24, 1999  V1.04 Replaced msgStorDisabled value from '500 Cannot STOR.' to
              '501 Permission Denied' because CuteFTP doesn't like error 500.
              Suggested by Cedric Veilleux <webmaster@smashweb.com>.
Aug 20, 1999  V1.05 Added compile time options. Revised for BCB4.
              Added Addr property to select interface in multihomed computers.
Oct 02, 1999  V1.06 Added OnValidateRnFr and OnValidateRnTo events.
              Initialized Allowed variable to TRUE before triggerValidateDele.
Nov 24, 1999  V1.07 Added MTDM support. Thanks to Bruce Christensen
              <bkc51831234@hotmail.com> for his code.
Jan 24, 2000  V1.08 Patch IE5 bug in file names. Thanks to <dsnake@infonie.fr>
Jun 08, 2000  V1.09 Added 'A N' type for type command for AIX systems.
Oct 25, 2000  V1.10 Exposed list of clients thru Client[] property.
Oct 29, 2000  V1.11 Added IsClient() method.
              Implemented OnValidateRmd event.
Nov 01, 2000  V1.12 Implemented proposals from Carl@Smotricz.com:
              (1) support for MODE command, but only the default do-nothing
              option S. (2) binding the data socket to the local host address
              and port 20 ('ftp-data'). (3) detection of failure to open the
              data connection for STOR or RETR.
              Added option wsoNoReceiveLoop to sockets. See comments in TWSocket
              about this option. Help in very fast LAN.
Nov 11, 2000  V1.13 Checked for DOS attack. Close connection when buffer
              overflow occured. Thanks to Lester <les@lester.co.uk> for finding
              this security hole.
Jun 18, 2001  V1.14 Fixed file left open when storing and client broken data
              connection. Thanks to Davie <smatters@smatters.com>
Jul 27, 2001  V1.15 I fixed a race condition between WMFtpSrvClientClosed and
              WMFtpSrvCloseData found by Matthew Comb <matt@filesafe.co.nz> who
              worked with Davie <smatters@smatters.com>. Now WMFtpSrvCloseData
              receive Client in LParam and check if client is still in client
              list.
              Fixed a but with resumed put. Thanks Yvan Turkan iturcan@gamo.sk !
              Added a procedure to disconnect a single client.
              Changed all Exception by FtpServerException.
              Changed all "Error" by "AError" to avoid conflict with global var.
              Added Client.ID property to uniquely indentify the client. Pass
              this ID along with all posted messages and verify if the correct
              client still exists when message is processed.
Jul 30, 2001  V1.16 Added same check as above for WMFtpSrvCloseData.
Sep 09, 2001  V1.17 Eric Pascual <e.pascual@cstb.fr> added Store Unique (STOU)
              command.
Feb 26, 2002  V1.18 Fastream Technologies (http://www.fastream.com) found a bug
              in Disconnect and DisconnectAll which prevented data connection
              to be closed and client component to be destroyed.
Jul 06, 2002  V1.19 Fastream Technologies (http://www.fastream.com) fixed
              CommandXPWD and CommandPWD to make the path in answer as
              "/c:/windows" instead of "c:/windows" which is more compatible
              with the UNIX standard that most clients expect.
Sep 16, 2002  V1.20 Added OnValidateSize event.
              Allowed "REST 0" as a valid command.
Sep 17, 2002  V1.21 Sven Schmidts <sven.schmidts@nusec.de> added partional FEAT
              command, must extended, because I doesn't know what commands are
              special-featured.
Oct 26, 2002  V1.22 Introduced OnBuildFilePath to allow component use to change
              the file path on the fly.
              Thanks to Serge Chelli <serge@aceinformatique.com> who proposed
              this change.
Nov 01, 2002  V1.23 When client request passive mode, select a port from a
              range of ports instead of letting the OS choose one. This ease the
              use of a FTP server behind a firewall. Passive mode transferts
              will use port in the specified range.
              Also implemented fixed IP for passive mode.
              Thanks to Ian Tuck <ituck@noglobalborders.com> for code base.
Nov 06, 2002  V1.24 Added definition for PBoolean which is missing in some
              older Delphi version and in BCB.
Nov 11, 2002  V1.25 Revised for Delphi 1
Jan 26, 2003  V1.26 ByteCount fix. Thanks to wilfried@mestdagh.biz and
              fastream@fastream.com for the fix.
Sep 15, 2003  V1.27 Added ICSDEF feature to the source code. Thanks to Marco
              van de Voort <marcov@stack.nl> for his help.
Nov 01, 2003  V1.28 Corrected FormatUnixDirEntry for files greater than 2GB.
Dec 15, 2003  V1.29 Changed ClientRetrSessionConnected to check if file exists
              to avoid TStream exception opening a non existant file.
Jan 15, 2004  V1.30 Made BuildFilePath virtual.
Feb 16, 2004  V1.31 Andreas Mueller <Amueller@Nord-Vision.de> updated
              CommandRNFR and CommandRNTO to handle directories.
Feb 24, 2004  V1.32 Wilfried changed Close by Shutdown(1) in WMFtpSrvCloseData.
Mar 06, 2004  V1.33 Added DirectoryExists function for Delphi below V5
May 26, 2004  V1.34 Added support for hidden files. Thanks to Martin Koberstein
              <MKoberstein@nord-vision.de>.
Jun 07, 2004  V1.35 Fixed DirExists to "see" hidden directories. This
              permit deletion of hidden directories
Jun 08, 2004  V1.36 Removed DirectoryExists function and used DirExists instead.
Jul 23, 2004  V1.37 Added type keyword to "TFtpString = type String;"
Aug 6, 2004   V1.38 Angus Robertson, angus@magsys.co.uk added new Options property
              added MDTM YYYYMMDDHHMMSS support (set file mod date)
              added MLST and MLSD commands for better file listings
              CWD now returns 550 if new directory does not exist and Options=ftpsCWDCheck
              changing to a higher level directory than HomeDir is blocked if Options=ftpsCdupHome
              corrected DirExists to strip trailing backslash so it works
Aug 19, 2004  V1.39 Angus Robertson, corrected Options=ftpsCWDCheck to allow
              root (c:\)
              Options passed to Client as ftpCwdCheck, ftpCdupHome so they
              can be changed per client
              MDTM checks logged-in, new trigger before changing file time stamp
              Added MFMT modify file modification time (same as
              MDTM YYYYMMDDHHMMSS but draft RFC'd)
              (not yet supporting MFCT create time or MFF file facts commands)
              Added MD5 command which returns hash of file content to allow
              corruption check
              (not yet supporting MMD5 multiple file or XMD5 file range commands)
Sep 08, 2004 V1.40 MD5 has been renamed to IcsMD5
Oct 20, 2004 V1.41 Angus Robertson, MLSD command failed in passive mode
Mar 11, 2005 V1.42 Marco van de Voort <marcov@stack.nl> updated the component
             to be compatible with NOFORMS concept.
             He implemented FtpSrvAllocateHWnd and FtpSrvDeallocateHWnd based
             on TWSocket versions.
             Angus Robertson, using ftpCwdCheck and ftpcUNC allow CWD to change
             to root
Sept 6, 2005 V1.43 64-bit support for Delphi 6 and later, for transfers larger
             than 2 gigs, added error handling for failed seeks and TStream issues
             by Angus Robertson, angus@magsys.co.uk
Oct 21, 2005 V1.44 Arno Garrels added SSL features.
Dec 29, 2005 V1.45 Peter Feldbaumer feldbaumer@feldtech.com fixed excessive
             226-response for cancelled passive data-connections. He also
             fixed ByteCount handling, unified passive data-connection-setup.
Dec 30, 2005 V1.46 Arno Garrels added IcsLogger.
Jan 18, 2006 V1.47 TLS/SSL related changes.
Aug 6, 2006  V1.48 using GetWinsockErr in wsocket to give consistent textual and
             numeric winsock errors, by Angus (some constant literals changed from %d to %s)
             wsocket fix for 64-bit transfers with range checking enabled
             for address in use error, report port in proper decimal
             SSL check Self = TSslFtpServerW before accessing SSL properties (Arno)
Aug 31, 2006 V1.49 A.Garrels reworked 64-bit streams support.
Sep 20, 2006 V1.50 A.Garrels implemented smarter MD5 calculation.
             How it works: On new uploads new option ftpsCalcMD5OnTheFly forces
             calculation of the MD5 sum in chunks in ClientStorDataAvailable.
             New property Md5UseThreadFileSize determines whether the checksum
             is calculated in a blocking manner or inside a worker thread
             when FTP command MD5 is processed. Therefore I introduced a new
             ProcessingThread in TFtpCtrlSocketW that may be used for any
             lengthy processing inside the component.
             New event OnMD5Calculated triggers either when the internal MD5
             calculation finished or when the sum needs to be updated, an
             empty parameter Md5Sum signals to delete a possibly cached entry
             except the file has been renamed.
Oct 27, 2006 V1.51 A.Garrels made the command table a dynamic array. Some
             improvements with PasvIpAddr: New options ftpsNoPasvIpAddrInLan
             and ftpsNoPasvIpAddrSameSubnet. New event OnPasvIpAddr.
Dec 05, 2006 Fixed FreeCurrentPasvPort
May 09, 2007 V1.52 changes by A.Garrels. Added two new events (sponsored by
             Fastream Technologies). OnEnterSecurityContext and
             OnLeaveSecurityContext make it possible to switch Windows'
             security context to the context of the logged client. New option
             ftpsHidePhysicalPath. Changed/fixed the STOU command. Fixed
             some security issues: If ftpCdUphome is in the options it's no
             longer possible to change, list, remove, rename or create
             directories above the home directory. Removed trailing
             slash from response-paths except upon root directories.
             Note: ftpsHidePhysicalPath is ignored unless ftpsCdUphome is also
             set.
June 11, 2007 V1.53 MDTM command failed with a directory name.
             Andreas Haas <andreas.haas@ops.de>
             Angus Robertson, MFMT command now supports millisecs when updating
             file time stamp (because MFMD command already returned millisecs)
             Note: sysutils FileAge functions used only supports round seconds
             Angus Robertson, Passive IP 0.0.0.0 now raises exception.
04 Dec 2007 V1.54 added more FEAT extensions, by Angus Robertson, angus@magsys.co.uk
               Note: some FEATs only reported if new events are created
             added support for One Time Passwords (aka S/Key), otp-md5, otp-md4 and otp-sha1,
               see RFC2289, uses new events OnOtpMethodEvent and OnOtpGetPasswordEvent
               (see OverbyteIcsFtpServ1 demo for OTP usage, ignore events for no OTP)
             added timeouts to close sockets on inactivity, new properties
               TimeoutSecsLogin (default 60 seconds), TimeoutSecsIdle (300) and
               TimeoutSecsXfer (900, same as IIS/4) before client is closed with
               421 answer. Note timeout is checked using a timer event once every
               five seconds so not second accurate. This event could be used for other jobs.
               Uses new event OnTimeout which can reset the timeout if needed
             added Clnt command to accept client information, calls new event
                onClntStr and sets Client.ClntStr
             added Allo command to return disk space allocation (before upload)
               checks and returns space on user's volume, but only says OK if
               AlloExtraSpace (default 1 Byte) still left as well, calls OnValidateAllo
               which may check space allocated for a specific account
             added Comb command to allow multiple upload files to be combined,
               used new event onCombine (where the actual file handling should be added)
             added Site Pswd command to change the account password, uses new
               event onSitePswd where the old and new passwords may be parsed
             added Site Exec command to execute a progam, uses new event
               onSiteExec which can decide whether the program should be run, and do it
             added Site Index command to generate a recusive directory and file name
               listing (no date or size) on the control channel, supported by Serv-U
             added Site Zone command to return the server time zone difference from
               UTC (GMT) which the client may use to adjust file listing time stamps
             added SiteMsg command to accept a message to the server, uses
               new event onSiteMsg
             added Site Dmlsd command, similar to MLSD but optional argument
               -SUBDIRS or -R for recursive directories, the path may be quoted if
               it includes spaces, the listing file names includes paths
             added Site Cmlsd command, similar to Site Dmlsd but uses control channel
               to avoid lots of small data channels sessions
             NOTE: Site Dmlsd and SiteCmlsd are new commands supported only by ICS
                FTP Server and may be disabled by removing the option ftpsSiteXmlsd
             the LIST, NLST, MLSD commands now also support -R for recursive
               sub-directores and a quoted file name
             recursive subdirectories are processsed in a thread unless option
                ftpsThreadRecurDirs is removed, ftpsThreadAllDirs similarly for all lists
             added Xcrc command to generate hash optional start and end positions,
               uses new events OnCalculateCrc and OnCrcCalculated, uses
               MD5UseThreadFileSize to check if a thread is used
             added Xmd5 command to generate hash optional start and end positions,
               used existing events OnCalculateMd5 and OnMd5Calculated
             added Mode Z and Opts commands and support for ZLIB compression if
                option ftpsModeZCompress set for server and ftpModeZCompress not disabled
                for client, ZlibMinLevel (1) and ZlibMaxLevel (9) properties restrict
                min and max compress stategies (max takes longer), ZlibNoCompExt is
                list of file extensions which compress with level 0 means no compress,
                defaults to '.zip;.rar;.7z;.cab;.lzh;.gz;.avi;.wmv;.mpg;.mp3;.jpg;.png;',
                ZlibWorkDir runtime property is path where temporary ZLIB files are written
                  defaults to '(systmppath)\icsftpsrv\'
                ZlinMinSpace property is minimum space on ZlibWorkDir for Mode Z to
                  be allowed, defaults to 50MByte
             added onDisplay event for server to log special information
             now reporting upload and download performance via OnDisplay event
             added various Client counters that may be used in the events to track
               server and account usage and performance, TotGetBytes and TotPutBytes
               are cumulative totals for the client which should be read in
               onClientDisconnect, SessStartTick is when client started, SessIdInfo
               may be set with client account info during logon, ReqStartTick is when
               the last request started and ReqDurMilliSecs is set to it's duration
               when the request finishes, XferStartTick is when an upload or download
               connected and starting sending data.
               Note: OverbyteIcsFtpSrvT has new functions for tick processing and timing
             moved building file directory functions to OverbyteIcsFtpSrvC so they
               can be used from client thread
             moved slash/backslash functions to OverbyteIcsFtpSrvT
             using Arno's TBufferedFileStream for improved performance
09 Dec 2007 V1.55 mode z bug fix for resumed transfers, by Angus Robertson, angus@magsys.co.uk
             added ftpsModeZNoResume option to disable resume while in Mode Z
             added ZlibMaxSize property to restrict maximum size of file that can compressed
             added callback in zlib funcs to update LastTick
06 Jan 2008 V1.56 corrected timer interval, timeout improvements
             passive port pool now issues incrementing ports instead of the sames ones
03 Mar 2008 V1.57 added SrvFileModeRead and SrvFileModeWrite as public so share locking
               can be changed, use SrvFileModeRead for MD5SUM (not locked)
            ensure file stream closed if session terminates unexpectedly
Apr 15, 2008 V1.58 A. Garrels, Unicode changes. Changed type of RcvBuf to
             PAnsiChar, corrected line indents.
Apr 25, 2008 V1.59 Removed checks for faVolumeID.
May 01, 2008 V1.60 A.Garrels added new functions DataStreamWriteString and
             DataStreamReadString.
Mar 24, 2008 V6.01 Bumped version number to 6.01
             Francois Piette made some changes to prepare code for Unicode.
Jun 25, 2008 V6.02 A. Garrels SSL code merged.
Apr 14, 2008 V6.03 A. Garrels, some Unicode related changes, basic features
             do work now. Receive buffer type-change from PChar to PAnsiChar.
             Check the various DataAvailableEvents. Fixed a bug in function
             GetInteger().
Apr 22, 2008 Some more Unicode related changes.
May 01, 2008 V6.04 A. Garrels - call new function DataStreamWriteString in
             TFtpServerW.BuildDirectory.
May 12, 2008 v6.05 A. Garrels changed call of GetTempPath in constructor.
             Some type changes from String to AnsiString of published properties.
             Added Setters and Getters for those properties since current
             compiler is not able to handle AnsiString properties correctly.
Jul 11, 2008 V6.03 Angus fixed 'Unicode' bug introduced in V6.01 that stopped PORT command working
             (Just the change log from v6 added here and minor cosmetic changes
              to keep both verions in sync, this issue was already fixed in v7)
Jul 13, 2008 V6.04 Revised socket names used for debugging purpose
                   Added ListenBackLog property
Jul 13, 2008 V6.04 Made Client ReadCount a public property
Aug 04, 2008 V6.07 A. Garrels - CommandAUTH TLS sent Unicode response.
             Removed some getter and setters, they are no longer needed.
Aug 11, 2008 V6.08 A. Garrels - Type AnsiString rolled back to String.
Sep 21, 2008 V6.11 Arno removed some old compiler switches (CBuilder compat.)
Nov 6, 2008  V7.00 Angus component now uses TSocketServer to accept connections
             Client code from OverbyteFtpSrvC now in this unit
             Removed conditional code for obsolete compilers, D7 minimum
             Added more public client variables for account information
             Increased DefaultRcvSize to 16384 from 2048 for performance
             Fixed exception with threaded MD5Sum progress
             Client.Id is now allocated by TSocketServer
Nov 8, 2008  V7.01 Angus added new commands HOST, REIN, LANG and OPTS UTF8 ON/OFF
               (HOST is supported by Microsoft IIS/7 in Windows 2008)
               HOST domain allows multiple domains on the same IP address (like HTTP)
               REINialise reverts the control channel to just connected with no logon
             Added UTF8 and CodePage support, defaults to ANSI mode for compatibility
             Added ftpsEnableUtf8 and ftpsDefaultUtf8On to Options but
                ftpsDefaultUtf8On should generally not be set, otherwise the client
                is expected to be using UTF8 (FileZilla Server default to on!)
             Note UTF8 only supports full Unicode with D2009, otherwise an ANSI CodePage
             Added new commands XCMLSD and XDMLSD same as SITE CMLSD and DMLSD
Nov 14, 2008 V7.02 Arno fixed a few thread issues. And reworked UTF-8 support.
             Angus ensure BuildDirectory adds errors to directory stream in UTF-8
             default options for ftpsCwdCheck and ftpsCdupHome
===================================================================================
Nov 19, 2008 V7.02W wide version TFtpServerW
             Split to support WideStrings with Delphi 2007 and earlier, changes
             kept in step with original version.
Nov 21, 2008 V7.03 Angus fixed TriggerSendAnswer/AnswerToClient did not allow answer
                to be changed, raw protocol no longer available as public
Nov 21, 2008 V7.04 Arno completed V7.03, it did not compile in D2009,
             allow C++ Builder.
Nov 22, 2008 V7.05 Arno fixed the FEAT response, rfc2389 says that each feature
             line in the feature-listing begins with a single space. But in the
             ICS FTP server a feature line in the listing began with two spaces
             which prevented some clients from seeing the features.
Mar 17, 2009 V7.06 Angus added MaxAttempts property to limit failed login attempts
             (default 12) and delays the failed password answer by about five seconds
             after a third of the failed attempts have been exceeded.
             This feature should be combined with an IP black list to
             stop new connections for failed logins (one hacker tried 250,000
             passwords over 36 hours on one of my FTP servers)
Apr 16, 2009 V7.07 Angus MD5 and CRC use buffered stream
             Clean-up MD5 on the fly
             Assume STREAM64, USE_BUFFERED_STREAM, USE_MODEZ
May 17, 2009 V7.08 Angus renamed FileMD5ThreadOnProgress to UpdateThreadProgress since
                used for various functions other than md5 and made public
             UpdateTheadProgress called by Client.BuildDirList so session does not timeout
                 indexing large directories and can be aborted
             Rename Client.BuildDirectory to BuildDirList to avoid confusion with
                Server.BuildDirectory, made virtual, removed Path no longer used and
                return total files listed, and log number of files listed
             Added OnAddVirtFiles event called from BuildDirList which allows extra virtual
                directories or files to be added to directory listings
             Fixed bug in Server.BuildDirectory that meant BuildFilePath was bypassed for a
                blank directory argument which prevented virtual directories working
             Fixed bugs in CommandChangeDir and CommandALLO that meant virtual directories not
                supported because BuildFilePath was not called when checking directory
             IsPathAllowed now calls BuildFilePath event which may validate if a virtual
                directory is allowed by returning non-blank
             FormatResponsePath also calls BuildFilePath to convert translated virtual
                path back to original path in home directory, so it can be removed
             TriggerLang now calls correct event handler
June 04, 2009 V7.09 Angus called TriggerMd5Calculated when changing file date/time
             default for TimeoutSecsXfer reduced from 900 to 60 secs and only aborts
                 data channel not control channel, it must be shorter than TimeoutSecsIdle
             SessIdInfo add client numeric id to identify separate sessions from same IP
Sept 03, 2009 V7.10 Arno exchanged TThread.Resume by TThread.Start for D2010 and later
Dec  15, 2009 V7.11 Arno added type TFtpSrvCommandTable to make C++Builder happy.
June 10, 2010 V7.12 Angus added bandwidth throttling using TCustomThrottledWSocket
              Set BandwidthLimit property to maximum bytes server wide, for
              specific clients set CBandwidthLimit in a client connect event
              (requires BUILTIN_THROTTLE to be defined in project options or
              enabled OverbyteIcsDefs.inc)
Sep 05, 2010 V7.13 Arno renamed conditional defines EXPERIMENTAL_THROTTLE and
             EXPERIMENTAL_TIMEOUT to BUILTIN_THROTTLE and BUILTIN_TIMEOUT.
Sept 09, 2010 Angus fixed bad code in V7.12 that stopped Unicode file names working
Oct 12, 2010 V7.14 Arno published OnBgException from underlaying server socket.
Nov 08, 2010 V7.15 Arno improved final exception handling, more details
             in OverbyteIcsWndControl.pas (V1.14 comments).
Feb 7,  2010 V7.16 Angus ensure control channel is correctly BandwidthLimited
May 21, 2011 V7.17 Arno ensure CommandAUTH resets the SSL prot-level correctly.
Aug 8,  2011 V7.19 Angus added client SndBufSize and RcvBufSize to set data socket
             buffers sizes for better performance, set to 32K to double speeds
May 2012 - V8.00 - Arno added FireMonkey cross platform support with POSIX/MacOS
                   also IPv6 support, include files now in sub-directory
                   New SocketFamily property (sfAny, sfAnyIPv4, sfAnyIPv6, sfIPv4, sfIPv6)
                   New MultiListenSockets property to add extra listening sockets,
                     each with Addr/Port/SocketFamily/FtpSslTypes properties
                     in events check MultiListenIndex, -1 is main socket, >=0 is
                     index into MultiListenSockets[] for socket raising event
Aug 13, 2012 V8.01 Angus ensure SSL not enabled by default, corrected MultiListen
                   Arno added TSslFtpWSocketMultiListenItem with FtpSslTypes
                     for each MultiListen socket
Jul 01, 2013 V8.02 Arno fixed an exception raised in ClientStorSessionClosed()
                   when an upload was aborted.
Jun 02, 2013 V8.03 Arno fixed a bug in TClientProcessingThread (thread-safety).
Jun 24, 2013 V8.04 Angus added new Options of ftpsCompressDirs defaults false
                   ftpsThreadRecurDirs default false due to rare thread bug
                   Skip using thread in zmode if level=Z_NO_COMPRESSION and
                      size less than one meg since really a straight stream copy
Dec 09, 2014 V8.05 - Angus added SslHandshakeRespMsg for better error handling
Feb 23, 2016 V8.06 - Angus renamed TBufferedFileStream to TIcsBufferedFileStream
Nov 09 2016  V8.37 - Added ExclusiveAddr property to stop other applications listening on same socket
                     Added extended exception information, set SocketErrs = wsErrFriendly for
                       some more friendly messages (without error numbers)
Aug 25, 2017 V8.50 - Angus stopped LIST/RETV using ..\..\..\ (already stopped for CWD)
Mar 8, 2019  V8.60 - Version and copyright dates only.
Nov 6, 2019  V8.63 - ftpsNoPasvIpAddrInLan and ftpsNoPasvIpAddrSameSubnet options
                       now work correctly to present local passive IP address on
                       LAN rather than PassIpAddr which is usually external address.
                     Logging various IP addresses for PASV command for debugging.
                     New IcsHosts property which allows multiple hosts to be
                       specified, each with one or two IP addresses and non-SSL and
                       SSL port bindings, SSL certificates and private key, SSL
                       context and security level.
                     If IcsHosts is specified, TSslWSocketServer ignores existing
                       bindings and SSLContext, and creates new bindings and
                       initialises an SSL context for each host checking and reporting
                       all certificates.
                     Allow SSL certificates to be ordered and installed automatically
                       by RecheckSslCerts if SslCertAutoOrder=True and so specified in
                       IcsHosts, if a TSslX509Certs component is attached and a
                       certificate supplier account has been created (by the
                       OverbyteIcsX509CertsTst sample application).
                     New IcsLoadFtpServerWFromIni function that reads server settings
                       from INI file, IcsHosts can be read using IcsLoadIcsHostsFromIni. 
                     When using IcsHosts, FtpSslTypes is set automatically to Implicit
                       if an SSL port is specified or Explicit if AuthSslCmd is true.
May 01, 2020 V8.64 - Added TFtpOptions ftpsAuthForceSsl which require SSL/TLS for
                       LOGIN so no clear credentials allowed.  May also be set using
                       IcsHosts with AuthForceSsl=True for specific Hosts only.
                       Failure gives '533 USER requires a secure connection'.
                     Better error handling when all passive ports are being used.
                     Fixed a range error with passive connections is range checking
                       was enabled, option ftpsNoPasvIpAddrSameSubnet and adaptors
                       had IPv6 addresses.
                       

Angus pending -
CRC on the fly
MD5 on the fly for downloads if not cached already
test app - cache zlib files and CRCs and lock updates

Known Issue (V8.04 Angus)
On some processors only (multi-core Xeon?), using the XDMLSD -R command with a root
directory in passive mode and a thread for ftpsThreadRecurDirs or zmode compression
causes output to be randomly lost, raising an exception in the thread.  The issue is
probably memory corruption, but can not trace the reason.  V8.04 mitigates this bug
by disabling ftpsThreadRecurDirs and ftpsCompressDirs compression for directories and
not using a thread if no compression needed (note in zmode a ZLIB must still be
called but does not actually compress the file).

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
unit OverbyteIcsFtpSrvW;

{$B-}           { Enable partial boolean evaluation   }
{$T-}           { Untyped pointers                    }
{$X+}           { Enable extended syntax              }
{$H+}           { Use long strings                    }
{$J+}           { Allow typed constant to be modified }
{$I Include\OverbyteIcsDefs.inc}
{$IFDEF COMPILER14_UP}
  {$IFDEF NO_EXTENDED_RTTI}
    {$RTTI EXPLICIT METHODS([]) FIELDS([]) PROPERTIES([])}
  {$ENDIF}
{$ENDIF}
{$IFDEF COMPILER12_UP}
    { These are usefull for debugging !}
    {$WARN IMPLICIT_STRING_CAST       OFF}
    {$WARN IMPLICIT_STRING_CAST_LOSS  ON}
    {$WARN EXPLICIT_STRING_CAST       OFF}
    {$WARN EXPLICIT_STRING_CAST_LOSS  OFF}
{$ENDIF}
{$IFNDEF COMPILER7_UP}
    Bomb('This component requires Delphi 7 or later');
{$ENDIF}
{$WARN SYMBOL_PLATFORM   OFF}
{$WARN SYMBOL_LIBRARY    OFF}
{$WARN SYMBOL_DEPRECATED OFF}
{$IFDEF BCB3_UP}
    {$ObjExportAll On}
{$ENDIF}

interface

uses
    Windows,
    Messages,
    OverbyteIcsWinsock,
{$IFNDEF NOFORMS}
    Forms,
{$ENDIF}
{$IFNDEF NO_DEBUG_LOG}
    OverbyteIcsLogger,
{$ENDIF}
{$IFDEF USE_SSL}
    OverByteIcsSSLEAY,
{$ENDIF}
    SysUtils, Classes,
    {$IFDEF RTL_NAMESPACES}System.IniFiles{$ELSE}IniFiles{$ENDIF},
    OverbyteIcsStreams,
    {$I Include\OverbyteIcsZlib.inc}
    OverbyteIcsZlibHigh,
    {$IFDEF USE_ZLIB_OBJ}
        OverbyteIcsZLibObj,     {interface to access ZLIB C OBJ files}
    {$ELSE}
        OverbyteIcsZLibDll,     {interface to access zLib1.dll}
    {$ENDIF}
    OverbyteIcsTypes,
    OverbyteIcsUtils,
    OverbyteIcsWndControl,
    OverbyteIcsWSocket,
    OverbyteIcsSocketUtils,   { IPv6 }
    OverbyteIcsWSocketS, { angus V7.00 }
    OverbyteIcsFtpSrvWT,
    OverbyteIcsOneTimePw,  { angus V1.54 }
    OverbyteIcsCRC,        { angus V1.54 }
    OverbyteIcsMD5,
{$IFDEF USE_SSL}
{$IFDEF AUTO_X509_CERTS}
{$IFDEF FMX}
    Ics.Fmx.OverbyteIcsSslX509Certs,  { V8.63 }
{$ELSE}
    OverbyteIcsSslX509Certs,  { V8.63 }
{$ENDIF}
{$ENDIF} // AUTO_X509_CERTS
{$ENDIF}
    OverbyteIcsWSockBuf;    { AG V6.04 }


const
    FtpServerVersion         = 864;
    CopyRight : String       = ' TFtpServerW (c) 1998-2020 F. Piette V8.64';
    UtcDateMaskPacked        = 'yyyymmddhhnnss';         { angus V1.38 }
    DefaultRcvSize           = 16384;    { V7.00 used for both xmit and recv, was 2048, too small }

    { Angus Nov 2007 - previously the values in this table did not match the
      command table, which is why dimensioning was incorrect, now corrected  }
const
    ftpcPORT      = 0;
    ftpcSTOR      = 1;
    ftpcRETR      = 2;
    ftpcCWD       = 3;
    ftpcXPWD      = 4;
    ftpcPWD       = 5;
    ftpcUSER      = 6;
    ftpcPASS      = 7;
    ftpcLIST      = 8;
    ftpcNLST      = 9;
    ftpcTYPE      = 10;
    ftpcSYST      = 11;
    ftpcQUIT      = 12;
    ftpcDELE      = 13;
    ftpcSIZE      = 14;
    ftpcREST      = 15;
    ftpcRNFR      = 16;
    ftpcRNTO      = 17;
    ftpcMKD       = 18;
    ftpcRMD       = 19;
    ftpcABOR      = 20;
    ftpcPASV      = 21;
    ftpcNOOP      = 22;
    ftpcCDUP      = 23;
    ftpcAPPE      = 24;
    ftpcSTRU      = 25;   {jsp - Added APPE and STRU types }
    ftpcXMKD      = 26;
    ftpcXRMD      = 27;
    ftpcMDTM      = 28;   {bkc - Added MDTM type           }
    ftpcMODE      = 29;
    ftpcOVER      = 31;
    ftpcSTOU      = 32;   {ep  - Added STOU type           }
    ftpcFEAT      = 33;   {SSV - Added FEAT type           }
    ftpcMLST      = 34;   {angus Added MLST type           }
    ftpcMLSD      = 35;   {angus Added MLSD type           }
    ftpcMFMT      = 36;   {angus Added MFMT type           }
    ftpcMD5       = 37;   {angus Added MD5 type            }
    ftpcXCRC      = 38;   {angus Added XCRC type           }
    ftpcXMD5      = 39;   {angus Added XMD5 type           }
    ftpcALLO      = 40;   {angus Added ALLO type           }
    ftpcCLNT      = 41;   {angus Added CLNT type           }
    ftpcOPTS      = 42;   {angus Added OPTS type           }
    ftpcSitePaswd = 43;   {angus Added SITE PASWD type     }
    ftpcSiteExec  = 44;   {angus Added SITE EXEC type      }
    ftpcSiteIndex = 45;   {angus Added SITE INDEX type     }
    ftpcSiteZone  = 46;   {angus Added SITE ZONE type      }
    ftpcSiteMsg   = 47;   {angus Added SITE MSG type       }
    ftpcSiteCmlsd = 48;   {angus Added SITE CMLSD type     }
    ftpcSiteDmlsd = 49;   {angus Added SITE DMLSD type     }
    ftpcCOMB      = 50;   {angus Added COMB                }
    ftpcXCMLSD    = 51;   {angus Added XCMLSD type         }
    ftpcXDMLSD    = 52;   {angus Added XDMLSD type         }
    ftpcHOST      = 53;   {angus Added HOST type           }
    ftpcREIN      = 54;   {angus Added REIN type           }
    ftpcLANG      = 55;   {angus Added LANG type           }
    ftpcEPRT      = 56;   { IPv6 }
    ftpcEPSV      = 57;   { IPv6 }
{$IFNDEF USE_SSL}
    ftpcLast      = 57;   {angus used to dimension FCmdTable}
{$ELSE}
    ftpcAUTH      = 58;
    ftpcCCC       = 59;
    ftpcPBSZ      = 60;   {V1.45}
    ftpcPROT      = 61;
    ftpcLast      = 61;
{$ENDIF}

  {$IFDEF POSIX}
    PathDelim       = '/';
  {$ELSE}
    PathDelim       = '\';
  {$ENDIF}

type
 { published server options }
    TFtpsOption      = (ftpsCwdCheck, ftpsCdupHome,      { angus V1.38 }
                        ftpsCalcMD5OnTheFly,             { AG V1.50 }
                        ftpsCalcCRCOnTheFly,             { angus V1.54 }
                        ftpsNoPasvIpAddrInLan,           { AG V1.51 }
                        ftpsNoPasvIpAddrSameSubnet,      { AG V1.51 }
                        ftpsHidePhysicalPath,            { AG V1.52 }
                        ftpsModeZCompress,               { angus V1.54 }
                        ftpsSiteXmlsd,                   { angus V1.54 }
                        ftpsThreadRecurDirs,             { angus V1.54 }
                        ftpsThreadAllDirs,               { angus V1.54 }
                        ftpsModeZNoResume,               { angus V1.55 }
                        ftpsEnableUtf8,                  { angus V7.01 support Utf8 }
                        ftpsDefaultUtf8On,               { angus V7.01 default Utf8 off is normal for ANSI compatibility }
                        ftpsAutoDetectCodePage,          { AG V7.02 actually detects UTF-8 only! }
                                                         { requires ftpsEnableUtf8 and sets ftpEnableUtf8   }
                                                         { once a valid UTF-8 buffer has been received from }
                                                         { a client.                                        }
                        ftpsCompressDirs,                { angus V8.04 zmode compress directory listings }
                        ftpsAuthForceSsl                 { angus V8.64 require SSL/TLS for LOGIN so no clear credentials }
                         );
    TFtpsOptions     = set of TFtpsOption;               { angus V1.38 }

 { client options }
    TFtpOption    = (ftpcUNC,                { angus V1.39 }
                     ftpCwdCheck,
                     ftpCdupHome,
                     ftpHidePhysicalPath,    { AG V1.52 }
                     ftpModeZCompress,       { angus V1.54 }
                     ftpUtf8On,              { angus V7.01 this is changed by the OPTS UTF8 ON/OFF command }
                     ftpAutoDetectCodePage,  { AG V7.02 actually detects UTF-8 only! }
                                             { requires ftpsEnableUtf8 and sets ftpEnableUtf8   }
                                             { once a valid UTF-8 buffer has been received from }
                                             { a client.                                        }
                     ftpAuthForceSsl         { angus V8.64 require SSL/TLS for LOGIN so no clear credentials }
                     );      { angus V1.54 }
    TFtpOptions   = set of TFtpOption;

    PBoolean = ^Boolean;
    FtpServerException  = class(Exception);
    TFtpString = type UnicodeString;   { V7.02W widestring }

{$IFDEF USE_SSL}
    TFtpSslType  = (ftpAuthSsl,      ftpAuthTls,     ftpAuthTlsP,
                    ftpAuthTlsC ,    ftpImplicitSsl);
    TFtpSslTypes = set of TFtpSslType;
    TCurFtpSslType  = (curftpSslNone,   curftpAuthSsl,      curftpAuthTls,
                       curftpAuthTlsP,  curftpAuthTlsC ,    curftpImplicitSsl);
{$ENDIF}

    TFtpTransMode   = (ftpTransModeStream, ftpTransModeZDeflate) ;  { angus V1.54 }
    TZStreamState   = (ftpZStateNone, ftpZStateSaveDecom, ftpZStateSaveComp{,
                     ftpZStateImmDecon, ftpZStateImmComp});         { angus V1.54 }
    TListType        = (ListTypeName,
                        ListTypeUnix, ListTypeFacts);    { angus V1.54 same as Server }

type
    EFtpCtrlSocketException = class(Exception);
    TFtpCtrlState = (ftpcInvalid, ftpcWaitingUserCode, ftpcWaitingPassword,
                     ftpcReady, ftpcWaitingAnswer, ftpcFailedAuth);  { angus V7.06 }

    { TFtpCmdType is now defined as a byte and enumerated items as constants, }
    { so that new values can be added by sub-components who add new commands  }
    TFtpCmdType   = Byte;

type
    TDisplayEvent = procedure (Sender : TObject; Msg : TFtpString) of object;
    TCommandEvent = procedure (Sender : TObject; CmdBuf : PAnsiChar; CmdLen : Integer) of object; { AG 7.02 Convert the buffer in TriggerCommand}

    TFtpCtrlSocketW = class; //Forward

    TClientProcessingThreadW = class(TThread)  { AG V1.46}
    public
        Client    : TFtpCtrlSocketW;
        Keyword   : String;
        Params    : String;
        InData    : TFtpString;
        AuxData   : String;        { AG V8.03 }
        OutData   : TFtpString;
        ClientID  : Integer;
        StartTick : LongWord;      { angus V1.54 }
        Sender    : TObject;       { angus V1.54 }
    protected                                  { AG 7.02 }
        procedure TriggerEnterSecurityContext; { AG 7.02 }
        procedure TriggerLeaveSecurityContext; { AG 7.02 }
        procedure Execute; override;
    end;

    TFtpServerW     = class; //Forward          { AG 7.02 }

    TFtpCtrlSocketW = class(TWSocketClient)   { angus V7.00 }
    protected
        FDataSocket        : TWSocket;
        FRcvBuf            : PAnsiChar;
        FRcvCnt            : Integer;
        FRcvSize           : Integer;   { used for both smit and revc }
        FBusy              : Boolean;
        FConnectedSince    : TDateTime;
        FLastCommand       : TDateTime;
        FCommandCount      : LongInt;
        FBanner            : TFtpString;
        FUserName          : TFtpString;
        FPassWord          : TFtpString;
        FCloseRequest      : Boolean;
        FHomeDir           : TFtpString;
        FDirectory         : TFtpString;
        FFtpState          : TFtpCtrlState;
        FAbortingTransfer  : Boolean;
        FUserData          : LongInt;        { Reserved for component user }
        FPeerAddr          : String;
        FPeerSAddr         : TSockAddr;      { AG V1.47 }
        FHost              : String;         { angus V7.01 }
        FLang              : String;         { angus V7.01 }
        FOnDisplay         : TDisplayEvent;
        FOnCommand         : TCommandEvent;
        FOptions           : TFtpOptions;    { AG 7.02 }
        FCodePage          : LongWord;       { AG 7.02 }
        FCurrentCodePage   : LongWord;       { AG 7.02 }
        FEpsvAllArgReceived: Boolean;        { IPv6 }
        FSndBufSize        : Integer;        { Angus V7.19}
        FRcvBufSize        : Integer;        { Angus V7.19}
        procedure TriggerSessionConnected(Error : Word); override;
        function  TriggerDataAvailable(Error : Word) : boolean; override;
        procedure TriggerCommand(CmdBuf : PAnsiChar; CmdLen : Integer); virtual; { AG 7.02 }
        procedure SetRcvSize(newValue : Integer);
        procedure SetHomeDir(const newValue: TFtpString);   { AG V1.52}
        procedure SetOptions(const Opts : TFtpOptions); { AG 7.02 }
        procedure SetCodePage(const Value: LongWord);   { AG 7.02 }
        procedure SetCurrentCodePage(const Value: LongWord); { AG 7.02 }
        procedure SetOnBgException(const Value: TIcsBgExceptionEvent); override; { V7.15 }
        procedure SetRcvBufSize(newValue : Integer);   { Angus V7.19}
        procedure SetSndBufSize(newValue : Integer);   { Angus V7.19}
    public
        FtpServer         : TFtpServerW; { AG V7.02 }
        BinaryMode        : Boolean;
        DataAddr          : String;
        DataPort          : String;
        FileName          : TFtpString;
        FilePath          : TFtpString;
        DataSessionActive : Boolean;
        DataStream        : TStream;
        HasOpenedFile     : Boolean;
        TransferError     : TFtpString;
        DataSent          : Boolean;
        CurCmdType        : TFtpCmdType;
        MD5Digest         : TMD5Digest;  { AG V1.46}
        MD5Context        : TMD5Context; { AG V1.46}
        MD5OnTheFlyFlag   : Boolean;     { AG V1.46}
        ProcessingThread  : TClientProcessingThreadW; { AG V1.46}
        AnswerDelayed     : Boolean;     { AG V1.46}
        ByteCount         : Int64;       { upload or download bytes for current data session }
        RestartPos        : Int64;
        HashStartPos      : Int64;       { angus V1.54 start for MD5/CRC }
        HashEndPos        : Int64;       { angus V1.54 start for MD5/CRC }
        FromFileName      : TFtpString;
        ToFileName        : TFtpString;
        PassiveMode       : Boolean;
        PassiveStart      : Boolean;
        PassiveConnected  : Boolean;
        OtpMethod         : TOtpMethod;  { angus V1.54 One Time Password authentication method }
        OtpSequence       : Integer;     { angus V1.54 One Time Password current sequence }
        OtpSeed           : String;      { angus V1.54 One Time Password current seed }
        LastTick          : Longword;    { angus V1.54 last tick for time out checking }
        ClntStr           : TFtpString;      { angus V1.54 from clnt command }
        DirListPath       : TFtpString;      { angus V1.54 last parsed directory listing path }
        DirListSubDir     : Boolean;     { angus V1.54 did we list subdirs }
        DirListHidden     : Boolean;     { angus V1.54 did we list hidden files }
        DirListType       : TListType;   { angus V1.54 how we list files }
        CurrTransMode     : TFtpTransMode; {angus V1.54 current zlib transfer mode }
        ZStreamState      : TZStreamState; { angus V1.54 current Zlib stream state }
        ZReqLevel         : Integer;     { angus V1.54 requested Zlib compression level 1 to 9 }
        ZCurLevel         : Integer;     { angus V1.54 current Zlib compression level 0 to 9 }
   {    ZStreamRec        : TZStreamRec;   angus V1.54 Zlib stream control record for immediate mode }
        ZCompFileName     : TFtpString;      { angus V1.54 zlib file name of compressed file }
        ZFileStream       : TStream;     { angus V1.54 Zlib compressed file stream  }
        ZCompInfo         : TFtpString;      { angus V1.54 zlib compress information to return with 251 OK }
        ZCompFileDelete   : Boolean;     { angus V1.54 zlib delete compressed file when closing it }
        SessStartTick     : Longword;    { angus V1.54 tick when client session started, for duration check }
        ReqStartTick      : Longword;    { angus V1.54 tick when last request started, for duration check }
        XferStartTick     : Longword;    { angus V1.54 tick when last xfer started, for performance check }
        ReqDurMilliSecs   : Integer;     { angus V1.54 how long last request took, in ticks }
        TotGetBytes       : Int64;       { angus V1.54 how many bytes GET during session, data and control }
        TotPutBytes       : Int64;       { angus V1.54 how many bytes PUT during session, data and control }
        SessIdInfo        : String;      { angus V1.54 session identificaton information for application use }
        FileModeRead      : Word;        { angus V1.57 file access fmOpenxx and fmSharexx flags for read  }
        FileModeWrite     : Word;        { angus V1.57 file access fmOpenxx and fmSharexx flags for write }
        AccountIniName    : TFtpString;      { angus V7.00 client account information, INI file }
        AccountPassword   : TFtpString;      { angus V7.00 client account expected password }
        AccountReadOnly   : Boolean;     { angus V7.00 client account read only file access, no uploads  }
        FailedAttempts    : Integer;     { angus V7.06 }
        DelayAnswerTick   : Longword;    { angus V7.06 tick when delayed answer should be sent }
{$IFDEF BUILTIN_THROTTLE}
        CBandwidthLimit    : LongWord;   { angus V7.12 Bytes per second, null = disabled }
        CBandwidthSampling : LongWord;   { angus V7.12 Msec sampling interval }
{$ENDIF}
{$IFDEF USE_SSL}
        ProtP             : Boolean;
        AuthFlag          : Boolean;
        CccFlag           : Boolean;
        FtpSslTypes       : TFtpSslTypes;
        CurFtpSslType     : TCurFtpSslType;
{$ENDIF}
        constructor Create(AOwner: TComponent); override;
        destructor  Destroy; override;
        procedure   SendAnswer(const Answer : RawByteString);         { angus V7.01 }{ AG V7.02 }
        procedure   SetDirectory(newValue : TFtpString); virtual;
        procedure   SetAbortingTransfer(newValue : Boolean);
        procedure   BuildDirList(var TotalFiles: integer); virtual; {angus V7.08 was BuildDirectory, made virtual }
        procedure   TriggerSessionClosed(Error : Word); override;
{$IFDEF USE_SSL}
        function    SslSendPlain(Data : TWSocketData; Len : Integer) : Integer;
{$ENDIF}
        procedure   DataStreamWriteString(const Str: AnsiString);  overload; { AG 7.02 }
        procedure   DataStreamWriteString(const Str: AnsiString; DstCodePage: LongWord);  overload; { AG 7.02 }
        procedure   DataStreamWriteString(const Str: UnicodeString; DstCodePage: LongWord); overload;
        procedure   DataStreamWriteString(const Str: UnicodeString); overload;
        procedure   DataStreamReadString(var Str: AnsiString; Len: TFtpBigInt); overload;
        procedure   DataStreamReadString(var Str: AnsiString; Len: TFtpBigInt; SrcCodePage: LongWord); overload;    { AG 7.02 }
        procedure   DataStreamReadString(var Str: UnicodeString; Len: TFtpBigInt; SrcCodePage: LongWord); overload; { AG 7.02 }
        procedure   DataStreamReadString(var Str: UnicodeString; Len: TFtpBigInt); overload;
        property    DataSocket     : TWSocket    read  FDataSocket;
        property    CodePage       : LongWord    read  FCodePage        { AG 7.02 }
                                                 write SetCodePage;
        property    CurrentCodePage: LongWord    read  FCurrentCodePage { AG 7.02 }
                                                 write SetCurrentCodePage;
        property    ConnectedSince : TDateTime   read  FConnectedSince;
        property    LastCommand    : TDateTime   read  FLastCommand;
        property    CommandCount   : LongInt     read  FCommandCount;
        property    RcvBuf         : PAnsiChar   read  FRcvBuf;
        property    RcvdCount;
        property    CloseRequest   : Boolean     read  FCloseRequest
                                                 write FCloseRequest;
        property    Directory      : TFtpString  read  FDirectory
                                                 write SetDirectory;
        property    HomeDir        : TFtpString  read  FHomeDir
                                                 write SetHomeDir;  { AG V1.52}
        property    AbortingTransfer : Boolean   read  FAbortingTransfer
                                                 write SetAbortingTransfer;
        property    ID             : LongInt     read  FCliId       { angus V7.00 }
                                                 write FCliId;
        property    Options        : TFtpOptions read  FOptions
                                                 write SetOptions;
        property    PeerSAddr      : TSockAddr   read  FPeerSAddr;  { AG V1.47 }
        property    ReadCount      : Int64       read  FReadCount;

    published
        property    FtpState       : TFtpCtrlState
                                                 read  FFtpState
                                                 write FFtpState;
        property    Banner         : TFtpString      read  FBanner
                                                 write FBanner;
        property    RcvSize        : Integer     read  FRcvSize
                                                 write SetRcvSize;
        property    Busy           : Boolean     read  FBusy
                                                 write FBusy;
        property    UserName       : TFtpString      read  FUserName
                                                 write FUserName;
        property    PassWord       : TFtpString      read  FPassWord
                                                 write FPassWord;
        property    UserData       : LongInt     read  FUserData
                                                 write FUserData;
        property    Host           : String      read  FHost
                                                 write FHost;
        property    Lang           : String      read  FHost
                                                 write FHost;
        property    SndBufSize     : Integer     read FSndBufSize       { Angus V7.19}
                                                 write SetSndBufSize;
        property    RcvBufSize     : Integer     read FRcvBufSize       { Angus V7.19}
                                                 write SetRcvBufSize;
        property    OnDisplay      : TDisplayEvent
                                                 read  FOnDisplay
                                                 write FOnDisplay;
        property    OnCommand      : TCommandEvent
                                                 read  FOnCommand
                                                 write FOnCommand;
        property    OnSessionClosed;
        property    OnDataSent;
        property    HSocket;
        property    AllSent;
        property    State;
{$IFNDEF NO_DEBUG_LOG}
        property    IcsLogger;
{$ENDIF}
    end;

    TFtpCtrlSocketWClass = class of TFtpCtrlSocketW;
    TFtpSrvAuthenticateEvent  =  procedure (Sender   : TObject;
                                            Client   : TFtpCtrlSocketW;
                                            UserName : TFtpString;
                                            Password : TFtpString;
                                            var Authenticated : Boolean) of object;
    TFtpSrvOtpMethodEvent  =  procedure (Sender   : TObject;                      { angus V1.54 }
                                         Client   : TFtpCtrlSocketW;
                                         UserName : TFtpString;
                                         var OtpMethod : TOtpMethod) of object;
    TFtpSrvOtpGetPasswordEvent =  procedure (Sender           : TObject;
                                             Client           : TFtpCtrlSocketW;
                                             UserName         : TFtpString;
                                             var UserPassword : TFtpString) of object; { angus V1.54 }
    TFtpSrvChangeDirectoryEvent =  procedure (Sender      : TObject;
                                              Client      : TFtpCtrlSocketW;
                                              Directory   : TFtpString;
                                              var Allowed : Boolean) of object;
    TFtpSrvBuildDirectoryEvent =  procedure (Sender        : TObject;
                                             Client        : TFtpCtrlSocketW;
                                             var Directory : TFtpString;
                                             Detailed      : Boolean) of object;
    TFtpSrvClientConnectEvent = procedure (Sender  : TObject;
                                           Client  : TFtpCtrlSocketW;
                                           AError  : Word) of object;
    TFtpSrvDataSessionConnectedEvent = procedure (Sender  : TObject;
                                                  Client  : TFtpCtrlSocketW;
                                                  Data    : TWSocket;
                                                  AError  : Word) of object;
    TFtpSrvClientCommandEvent = procedure (Sender        : TObject;
                                           Client        : TFtpCtrlSocketW;
                                           var Keyword   : TFtpString;
                                           var Params    : TFtpString;
                                           var Answer    : TFtpString) of object;
    TFtpSrvAnswerToClientEvent = procedure (Sender        : TObject;
                                            Client        : TFtpCtrlSocketW;
                                            var Answer    : TFtpString) of object;
    TFtpSrvValidateXferEvent  = procedure (Sender        : TObject;
                                           Client        : TFtpCtrlSocketW;
                                           var FilePath  : TFtpString;
                                           var Allowed   : Boolean) of object;
    TFtpSrvCalculateMd5Event  = procedure (Sender        : TObject;        { angus V1.39 }
                                           Client        : TFtpCtrlSocketW;
                                           var FilePath  : TFtpString;
                                           var Md5Sum    : TFtpString;
                                           var Allowed   : Boolean) of object;
    TFtpSrvMd5CalculatedEvent = procedure (Sender         : TObject;       { AG V1.50 }
                                           Client         : TFtpCtrlSocketW;
                                           const FilePath : TFtpString;
                                           const Md5Sum   : TFtpString) of object;
    TFtpSrvOnPasvIpAddrEvent = procedure  (Sender : TObject;               { AG V1.51 }
                                           Client : TFtpCtrlSocketW;
                                           var APasvIpAddr: TFtpString;
                                           var SetPasvIpAddr : Boolean) of object;
    TFtpSrvBuildFilePathEvent = procedure (Sender        : TObject;
                                           Client        : TFtpCtrlSocketW;
                                           const Directory   : TFtpString;
                                           const FileName    : TFtpString;
                                           var   NewFileName : TFtpString) of object;
    TFtpSrvDataAvailableEvent = procedure (Sender : TObject;
                                           Client : TFtpCtrlSocketW;
                                           Data   : TWSocket;
                                           Buf    : PAnsiChar;  { AG V6.02 }
                                           Len    : LongInt;
                                           AError : Word) of object;
    TFtpSrvRetrDataSentEvent  = procedure (Sender : TObject;
                                           Client : TFtpCtrlSocketW;
                                           Data   : TWSocket;
                                           AError : Word) of object;
    TFtpSrvGetUniqueFileNameEvent = procedure (Sender       : TObject;
                                               Client       : TFtpCtrlSocketW;
                                               var FileName : TFtpString) of object;
    TFtpSrvGetProcessingEvent     = procedure (Sender          : TObject;
                                               Client          : TFtpCtrlSocketW;
                                               var DelayedSend : Boolean) of object;
    TFtpSrvCommandProc        = procedure (Client        : TFtpCtrlSocketW;
                                           var Keyword   : TFtpString;
                                           var Params    : TFtpString;
                                           var Answer    : TFtpString) of object;
    TFtpSrvCommandTableItem   = record
                                    KeyWord : String;
                                    Proc    : TFtpSrvCommandProc;
                                end;
    TFtpSrvCommandTable = array of TFtpSrvCommandTableItem; { AG V7.11 }

    TFtpSecurityContextEvent  = procedure (Sender : TObject;     { AG V1.52 }
                                           Client : TFtpCtrlSocketW) of object;
    TFtpSrvGeneralEvent = procedure (Sender        : TObject;      { angus V1.54 }
                                     Client        : TFtpCtrlSocketW;
                                     var Params    : TFtpString;
                                     var Answer    : TFtpString) of object;
    TFtpSrvTimeoutEvent =  procedure (Sender      : TObject;               { angus V1.54 }
                                      Client      : TFtpCtrlSocketW;
                                      Duration    : Integer;
                                      var Abort   : Boolean) of object;
    TFtpSrvCompressFileEvent  = procedure (Sender        : TObject;        { angus V1.54 }
                                           Client        : TFtpCtrlSocketW;
                                           var Done      : Boolean) of object;
    TFtpSrvCompressedFileEvent = procedure (Sender       : TObject;        { angus V1.54 }
                                            Client       : TFtpCtrlSocketW) of object;
    TFtpSrvDisplayEvent = procedure (Sender        : TObject;      { angus V1.54 }
                                     Client        : TFtpCtrlSocketW;
                                     Msg           : TFtpString) of object;
    TFtpSrvHostEvent =  procedure (Sender      : TObject;                { angus V7.01 }
                                   Client      : TFtpCtrlSocketW;
                                   Host        : TFtpString;
                                   var Allowed : Boolean) of object;
    TFtpSrvReinEvent =  procedure (Sender      : TObject;                { angus V7.01 }
                                   Client      : TFtpCtrlSocketW;
                                   var Allowed : Boolean) of object;
    TFtpSrvLangEvent =  procedure (Sender      : TObject;                { angus V7.01 }
                                   Client      : TFtpCtrlSocketW;
                                   Lang        : TFtpString;
                                   var Allowed : Boolean) of object;
    TFtpSrvAddVirtFilesEvent = procedure (Sender          : TObject;             { angus V7.08 }
                                          Client          : TFtpCtrlSocketW;
                                          var LocFiles    : TIcsFileRecsW;
                                          var LocFileList : TList;
                                          var TotalFiles  : Integer;
                                          ProgressCallback: TMD5Progress) of object;

    TFtpServerW = class(TIcsWndControl)
    protected
        FAddr                   : String;
        FSocketFamily           : TSocketFamily;      { IPv6 }
        FPort                   : String;
        FListenBackLog          : Integer;
        FBanner                 : TFtpString;
        FSocketServer           : TWSocketServer ;    { new  angus V7.00 }
        FClientClass            : TFtpCtrlSocketWClass;
        FMaxClients             : LongInt;
        FCmdTable               : TFtpSrvCommandTable; { AG V7.11 }
        FLastCmd                : Integer;
        FUserData               : LongInt;      { Reserved for component user }
        FPasvPortRangeStart     : Integer;
        FPasvPortRangeSize      : Integer;
        FPasvPortTable          : PBoolean;     { list of passive ports being used, port freed when closed }
        FPasvPortTableSize      : Integer;
        FPasvIpAddr             : String;
        FPasvNextNr             : Integer;      { angus V1.56 }
        FMd5UseThreadFileSize   : Integer;      { AG V1.50 }
        FTimeoutSecsLogin       : Integer;      { angus V1.54 }
        FTimeoutSecsIdle        : Integer;      { angus V1.54 }
        FTimeoutSecsXfer        : Integer;      { angus V1.54 }
        FEventTimer             : TIcsTimer;    { angus V1.54 }
        FZlibMinLevel           : Integer;      { angus V1.54 }
        FZlibMaxLevel           : Integer;      { angus V1.54 }
        FZlibNoCompExt          : String;       { angus V1.54 }
        FZlibWorkDir            : TFtpString;       { angus V1.54 }
        FZlibMinSpace           : Integer;      { angus V1.54 }
        FAlloExtraSpace         : Integer;      { angus V1.54 }
        FZlibMaxSize            : Int64;        { angus V1.55 }
        FCodePage               : LongWord;     { angus V7.01 for UTF8 support }
        FLanguage               : String;       { angus V7.01 for UTF8 support }
        FMaxAttempts            : Integer;      { angus V7.06 }
        FBindFtpData            : Boolean;      { IPv6 }
{$IFDEF BUILTIN_THROTTLE}
        FBandwidthLimit         : LongWord;     { angus V7.12 Bytes per second, null = disabled }
        FBandwidthSampling      : LongWord;     { angus V7.12 Msec sampling interval }
{$ENDIF}
        FMsg_WM_FTPSRV_CLOSE_REQUEST  : UINT;
        FMsg_WM_FTPSRV_ABORT_TRANSFER : UINT;
        FMsg_WM_FTPSRV_CLOSE_DATA     : UINT;
        FMsg_WM_FTPSRV_START_SEND     : UINT;
        FOnStart                : TNotifyEvent;
        FOnStop                 : TNotifyEvent;
        FOnAuthenticate         : TFtpSrvAuthenticateEvent;
        FOnOtpMethod            : TFtpSrvOtpMethodEvent;           { angus V1.54 }
        FOnOtpGetPassword       : TFtpSrvOtpGetPasswordEvent;      { angus V1.54 }
        FOnClientConnect        : TFtpSrvClientConnectEvent;
        FOnClientDisconnect     : TFtpSrvClientConnectEvent;
        FOnClientCommand        : TFtpSrvClientCommandEvent;
        FOnAnswerToClient       : TFtpSrvAnswerToClientEvent;
        FOnChangeDirectory      : TFtpSrvChangeDirectoryEvent;
        FOnMakeDirectory        : TFtpSrvChangeDirectoryEvent;
        FOnBuildDirectory       : TFtpSrvBuildDirectoryEvent;
        FOnAlterDirectory       : TFtpSrvBuildDirectoryEvent;
        FOnValidatePut          : TFtpSrvValidateXferEvent;
        FOnValidateSize         : TFtpSrvValidateXferEvent;
        FOnValidateDele         : TFtpSrvValidateXferEvent;
        FOnValidateRmd          : TFtpSrvValidateXferEvent;
        FOnValidateRnFr         : TFtpSrvValidateXferEvent;
        FOnValidateRnTo         : TFtpSrvValidateXferEvent;
        FOnStorSessionConnected : TFtpSrvDataSessionConnectedEvent;
        FOnStorSessionClosed    : TFtpSrvDataSessionConnectedEvent;
        FOnStorDataAvailable    : TFtpSrvDataAvailableEvent;
        FOnValidateGet          : TFtpSrvValidateXferEvent;
        FOnRetrSessionConnected : TFtpSrvDataSessionConnectedEvent;
        FOnRetrSessionClosed    : TFtpSrvDataSessionConnectedEvent;
        FOnRetrDataSent         : TFtpSrvRetrDataSentEvent;
        FOnGetUniqueFileName    : TFtpSrvGetUniqueFileNameEvent;
        FOnGetProcessing        : TFtpSrvGetProcessingEvent;
        FOnBuildFilePath        : TFtpSrvBuildFilePathEvent; { serge le 5/10/2002 }
        FOnValidateMfmt         : TFtpSrvValidateXferEvent;  { angus V1.39 }
        FOnCalculateMd5         : TFtpSrvCalculateMd5Event;  { angus V1.39 }
        FOnCalculateCrc         : TFtpSrvCalculateMd5Event;  { angus V1.54 }
        FOptions                : TFtpsOptions;
        FOnMd5Calculated        : TFtpSrvMd5CalculatedEvent; { AG V1.50 }
        FOnCrcCalculated        : TFtpSrvMd5CalculatedEvent; { angus V1.54 }
        FOnPasvIpAddr           : TFtpSrvOnPasvIpAddrEvent;  { AG V1.51 }
        FOnEnterSecurityContext : TFtpSecurityContextEvent;  { AG V1.52 }
        FOnLeaveSecurityContext : TFtpSecurityContextEvent;  { AG V1.52 }
        FOnValidateAllo         : TFtpSrvGeneralEvent;       { angus V1.54 }
        FOnClntStr              : TFtpSrvGeneralEvent;       { angus V1.54 }
        FOnSiteMsg              : TFtpSrvGeneralEvent;       { angus V1.54 }
        FOnSiteExec             : TFtpSrvGeneralEvent;       { angus V1.54 }
        FOnSitePaswd            : TFtpSrvGeneralEvent;       { angus V1.54 }
        FOnCombine              : TFtpSrvGeneralEvent;       { angus V1.54 }
        FOnTimeout              : TFtpSrvTimeoutEvent;       { angus V1.54 }
        FOnDownCompressFile     : TFtpSrvCompressFileEvent;  { angus V1.54 }
        FOnUpCompressFile       : TFtpSrvCompressFileEvent;  { angus V1.54 }
        FOnUpCompressedFile     : TFtpSrvCompressedFileEvent; { angus V1.54 }
        FOnDisplay              : TFtpSrvDisplayEvent;       { angus V1.54 }
        FOnHost                 : TFtpSrvHostEvent;          { angus V7.01 }
        FOnRein                 : TFtpSrvReinEvent;          { angus V7.01 }
        FOnLang                 : TFtpSrvLangEvent;          { angus V7.01 }
        FSystemCodePage         : LongWord;                  { AG 7.02 }
        FOnAddVirtFiles         : TFtpSrvAddVirtFilesEvent;  { angus V7.08 }
        FSocketErrs             : TSocketErrs;               { V8.37 }
        FExclusiveAddr          : Boolean;                   { V8.37 }
        procedure CreateSocket; virtual;                                             { IPv6 }
        function  GetMultiListenIndex: Integer;
        function  GetMultiListenSockets: TWSocketMultiListenCollection;              { IPv6 }
        procedure SetMultiListenSockets(const Value: TWSocketMultiListenCollection); { IPv6 }
        procedure SetOnBgException(const Value: TIcsBgExceptionEvent); override; { V7.15 }
{$IFNDEF NO_DEBUG_LOG}
        function  GetIcsLogger: TIcsLogger;                                      { V1.46 }
        procedure SetIcsLogger(const Value: TIcsLogger);                         { V1.46 }
        procedure DebugLog(LogOption: TLogOption; const Msg : string); virtual;  { V1.46 }
        function  CheckLogOptions(const LogOption: TLogOption): Boolean; virtual;{ V1.46 }
{$ENDIF}
        procedure ClientProcessingThreadTerminate(Sender : TObject); { AG V1.50 }
        procedure Notification(AComponent: TComponent; operation: TOperation); override;
        procedure ServSocketStateChange(Sender : TObject; OldState, NewState : TSocketState);
        procedure ClientDataSent(Sender : TObject; AError  : Word); virtual; { V1.47 }
        procedure ClientCommand(Sender : TObject; CmdBuf : PAnsiChar; CmdLen : Integer); { AG 7.02 }
        procedure ClientPassiveSessionAvailable(Sender : TObject; AError  : Word); virtual; {AG SSL}
        procedure ClientStorSessionConnected(Sender : TObject; AError  : Word);
        procedure ClientStorSessionClosed(Sender : TObject; AError  : Word);
        procedure ClientStorDataAvailable(Sender: TObject; AError  : word); virtual;
        procedure ClientRetrSessionConnected(Sender : TObject; AError  : Word); virtual;
        procedure ClientRetrSessionClosed(Sender : TObject; AError  : Word);
        procedure ClientRetrDataSent(Sender : TObject; AError  : Word);
        procedure SendAnswer(Client : TFtpCtrlSocketW; Answer : TFtpString);  virtual; {AG SSL}
        procedure SendNextDataChunk(Client : TFtpCtrlSocketW; Data : TWSocket); virtual;
        procedure StartSendData(Client : TFtpCtrlSocketW);
        procedure PrepareStorDataSocket(Client : TFtpCtrlSocketW);
        procedure PreparePassiveStorDataSocket(Client : TFtpCtrlSocketW);
        procedure PreparePassiveRetrDataSocket(Client : TFtpCtrlSocketW);
        function  IsPathAllowed(Client : TFtpCtrlSocketW; const Path : TFtpString;
                                ExcludeBackslash : Boolean = FALSE): Boolean; { V1.52 AG}
        function  FormatResponsePath(Client: TFtpCtrlSocketW; const InPath : TFtpString): TFtpString; { AG V1.52 angus V7.08 }
        procedure BuildDirectory(Client : TFtpCtrlSocketW; var Path : TFtpString); { angus V1.54, V7.08 }
        procedure EventTimerOnTimer(Sender : TObject);                            { angus V1.54 }
        procedure ServerClientConnect(Sender: TObject;
                                Client: TWSocketClient; Error: Word);    { angus V7.00 }
        procedure ServerClientDisconnect(Sender: TObject;
                                Client: TWSocketClient; Error: Word);    { angus V7.00 }

        procedure TriggerServerStart; virtual;
        procedure TriggerServerStop; virtual;
        procedure TriggerAuthenticate(Client            : TFtpCtrlSocketW;
                                      UserName          : TFtpString;
                                      PassWord          : TFtpString;
                                      var Authenticated : Boolean); virtual;
        procedure TriggerOtpMethod   (Client   : TFtpCtrlSocketW;
                                      UserName : TFtpString;
                                      var OtpMethod : TOtpMethod); virtual; { angus V1.54 }
        procedure TriggerOtpGetPassword(Client           : TFtpCtrlSocketW;
                                        UserName         : TFtpString;
                                        var UserPassword : TFtpString); virtual; { angus V1.54 }
        procedure TriggerChangeDirectory(Client         : TFtpCtrlSocketW;
                                         Directory      : TFtpString;
                                         var Allowed    : Boolean); virtual;
        procedure TriggerMakeDirectory(Client         : TFtpCtrlSocketW;
                                       Directory      : TFtpString;
                                       var Allowed    : Boolean); virtual;
        procedure TriggerBuildDirectory(Client        : TFtpCtrlSocketW;
                                        var Params    : TFtpString;
                                        Detailed      : Boolean); virtual;
        procedure TriggerAlterDirectory(Client        : TFtpCtrlSocketW;
                                        var Params    : TFtpString;
                                        Detailed      : Boolean); virtual;
        procedure TriggerSendAnswer(Client : TFtpCtrlSocketW;
                                    var Answer : TFtpString); virtual;
        procedure TriggerClientConnect(Client : TFtpCtrlSocketW; AError  : Word); virtual;
        procedure TriggerClientDisconnect(Client : TFtpCtrlSocketW; AError  : Word); virtual;
        procedure TriggerClientCommand(Client      : TFtpCtrlSocketW;
                                       var Keyword : TFtpString;
                                       var Params  : TFtpString;
                                       var Answer  : TFtpString); virtual;
        procedure TriggerStorSessionConnected(Client : TFtpCtrlSocketW;
                                              Data   : TWSocket;
                                              AError : Word); virtual;
        procedure TriggerStorSessionClosed(Client : TFtpCtrlSocketW;
                                           Data   : TWSocket;
                                           AError : Word); virtual;
        procedure TriggerValidatePut(Client        : TFtpCtrlSocketW;
                                     var FilePath  : TFtpString;
                                     var Allowed   : Boolean); virtual;
        procedure TriggerValidateSize(Client        : TFtpCtrlSocketW;
                                      var FilePath  : TFtpString;
                                      var Allowed   : Boolean); virtual;
        procedure TriggerValidateDele(Client        : TFtpCtrlSocketW;
                                      var FilePath  : TFtpString;
                                      var Allowed   : Boolean); virtual;
        procedure TriggerValidateRmd(Client        : TFtpCtrlSocketW;
                                     var FilePath  : TFtpString;
                                     var Allowed   : Boolean); virtual;
        procedure TriggerValidateRnFr(Client        : TFtpCtrlSocketW;
                                      var FilePath  : TFtpString;
                                      var Allowed   : Boolean); virtual;
        procedure TriggerValidateRnTo(Client        : TFtpCtrlSocketW;
                                      var FilePath  : TFtpString;
                                      var Allowed   : Boolean); virtual;
        procedure TriggerRetrSessionConnected(Client : TFtpCtrlSocketW;
                                              Data   : TWSocket;
                                              AError : Word); virtual;
        procedure TriggerRetrSessionClosed(Client : TFtpCtrlSocketW;
                                           Data   : TWSocket;
                                           AError : Word); virtual;
        procedure TriggerValidateGet(Client        : TFtpCtrlSocketW;
                                     var FilePath  : TFtpString;
                                     var Allowed   : Boolean); virtual;
        procedure TriggerStorDataAvailable(Client : TFtpCtrlSocketW;
                                       Data   : TWSocket;
                                       Buf    : PAnsiChar;  { AG V6.02 }
                                       Len    : LongInt;
                                       AError : Word); virtual;
        procedure TriggerRetrDataSent(Client : TFtpCtrlSocketW;
                                      Data   : TWSocket;
                                      AError : Word); virtual;
        procedure TriggerGetUniqueFileName(Client       : TFtpCtrlSocketW;
                                           var FileName : TFtpString); virtual;
        procedure TriggerBuildFilePath(Client            : TFtpCtrlSocketW;
                                       const Directory   : TFtpString;
                                       const FileName    : TFtpString;
                                       var   NewFileName : TFtpString); virtual;
        procedure TriggerValidateMfmt(Client        : TFtpCtrlSocketW;   { angus V1.39 }
                                      var FilePath  : TFtpString;
                                      var Allowed   : Boolean); virtual;
        procedure TriggerCalculateMd5 (Client        : TFtpCtrlSocketW;   { angus V1.39 }
                                      var FilePath  : TFtpString;
                                      var Md5Sum    : TFtpString;
                                      var Allowed   : Boolean); virtual;
        procedure TriggerMd5Calculated(Client         : TFtpCtrlSocketW;  { AG V1.50 }
                                      const FilePath  : TFtpString;
                                      const Md5Sum    : TFtpString); virtual;
        procedure TriggerCalculateCrc (Client        : TFtpCtrlSocketW;   { angus V1.54 }
                                      var FilePath  : TFtpString;
                                      var Md5Sum    : TFtpString;
                                      var Allowed   : Boolean); virtual;
        procedure TriggerCrcCalculated(Client         : TFtpCtrlSocketW;  { angus V1.54 }
                                      const FilePath  : TFtpString;
                                      const Md5Sum    : TFtpString); virtual;
        procedure TriggerEnterSecurityContext(Client : TFtpCtrlSocketW); virtual; { AG V1.52 }
        procedure TriggerLeaveSecurityContext(Client : TFtpCtrlSocketW); virtual; { AG V1.52 }
        procedure TriggerValidateAllo (Client      : TFtpCtrlSocketW;           { angus V1.54 }
                                       var Params  : TFtpString;
                                       var Answer  : TFtpString); virtual;
        procedure TriggerClntStr      (Client      : TFtpCtrlSocketW;           { angus V1.54 }
                                       var Params  : TFtpString;
                                       var Answer  : TFtpString); virtual;
        procedure TriggerSiteMsg      (Client      : TFtpCtrlSocketW;           { angus V1.54 }
                                       var Params  : TFtpString;
                                       var Answer  : TFtpString); virtual;
        procedure TriggerSiteExec     (Client      : TFtpCtrlSocketW;           { angus V1.54 }
                                       var Params  : TFtpString;
                                       var Answer  : TFtpString); virtual;
        procedure TriggerSitePaswd    (Client      : TFtpCtrlSocketW;           { angus V1.54 }
                                       var Params  : TFtpString;
                                       var Answer  : TFtpString); virtual;
        procedure TriggerCombine      (Client      : TFtpCtrlSocketW;           { angus V1.54 }
                                       var Params  : TFtpString;
                                       var Answer  : TFtpString); virtual;
        procedure TriggerTimeout      (Client      : TFtpCtrlSocketW;            { angus V1.54 }
                                       Duration    : Integer;
                                       var Abort   : Boolean); virtual;
        procedure TriggerDownCompressFile (Client    : TFtpCtrlSocketW;          { angus V1.54 }
                                           var Done  : Boolean); virtual;
        procedure TriggerUpCompressFile (Client    : TFtpCtrlSocketW;            { angus V1.54 }
                                         var Done  : Boolean); virtual;
        procedure TriggerUpCompressedFile (Client  : TFtpCtrlSocketW); virtual;  { angus V1.54 }
        procedure TriggerDisplay       (Client      : TFtpCtrlSocketW;
                                       Msg         : TFtpString); virtual;      { angus V1.54 }
        procedure TriggerHost          (Client        : TFtpCtrlSocketW;
                                        Host          : TFtpString;
                                        var Allowed   : Boolean); virtual;      { angus V7.01 }
        procedure TriggerRein          (Client        : TFtpCtrlSocketW;
                                        var Allowed   : Boolean); virtual;      { angus V7.01 }
        procedure TriggerLang          (Client        : TFtpCtrlSocketW;
                                        Lang          : TFtpString;
                                        var Allowed   : Boolean); virtual;      { angus V7.01 }
        procedure TriggerAddVirtFiles  (Client          : TFtpCtrlSocketW;
                                        var LocFiles    : TIcsFileRecsW;
                                        var LocFileList : TList;
                                        var TotalFiles  : Integer;
                                        ProgressCallback: TMD5Progress); virtual; { angus V7.08 }
        function BuildFilePath(Client      : TFtpCtrlSocketW;
                               Directory   : TFtpString;
                               FileName    : TFtpString) : TFtpString; virtual;
        function  GetClientCount : Integer; virtual;
        function  GetClient(nIndex : Integer) : TFtpCtrlSocketW; virtual;
{ !!!!!!!!!!!!!!!! NGB: Added next two lines }
        procedure FreeCurrentPasvPort(AClient : TFtpCtrlSocketW);
        function  GetNextAvailablePasvPort : String;
{ !!!!!!!!!!!!!!!! NGB: Added last two lines }
        function  GetActive : Boolean;
        procedure SetActive(newValue : Boolean);
        procedure SetPasvPortRangeSize(const NewValue: Integer);
        procedure SetPasvPortRangeStart(const NewValue: Integer);
        procedure SetClientClass(const NewValue: TFtpCtrlSocketWClass);     { angus V7.00 }
        procedure AddCommand(const Keyword : String;
                             const Proc : TFtpSrvCommandProc); virtual;
        procedure WMFtpSrvCloseRequest(var msg: TMessage); virtual;
        procedure WMFtpSrvAbortTransfer(var msg: TMessage); virtual;
        procedure WMFtpSrvCloseData(var msg: TMessage); virtual;
        procedure WMFtpSrvStartSend(var msg: TMessage); virtual;
        procedure CommandDirectory(Client      : TFtpCtrlSocketW;
                                   var Keyword : TFtpString;
                                   var Params  : TFtpString;
                                   var Answer  : TFtpString;
                                   Detailed    : Boolean); virtual;
        procedure CommandDirectory2(Client      : TFtpCtrlSocketW;
                                   var Keyword : TFtpString;
                                   var Params  : TFtpString;
                                   var Answer  : TFtpString;
                                   ListType    : TListType);
        procedure CommandUSER(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandPASS(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandQUIT(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandNOOP(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandLIST(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandNLST(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandDELE(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandSIZE(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandREST(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandRNFR(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandRNTO(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandPORT(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandSTOR(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandRETR(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandTYPE(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandCWD (Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandChangeDir(Client : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandMKD (Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandRMD (Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandCDUP(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandXPWD(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandPWD (Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandSYST(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandABOR(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandPASV(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandAPPE(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandSTRU(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandMDTM(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandMODE(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandOverflow(Client  : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandSTOU(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandFEAT(Client      : TFtpCtrlSocketW;
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandMLST(Client      : TFtpCtrlSocketW;   { angus V1.38 }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandMLSD(Client      : TFtpCtrlSocketW;   { angus V1.38 }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandMD5 (Client      : TFtpCtrlSocketW;   { angus V1.39 }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandXCRC (Client     : TFtpCtrlSocketW;   { angus V1.54 }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandALLO (Client     : TFtpCtrlSocketW;   { angus V1.54 }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandCLNT (Client     : TFtpCtrlSocketW;   { angus V1.54 }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandOPTS (Client     : TFtpCtrlSocketW;   { angus V1.54 }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandSitePaswd (Client : TFtpCtrlSocketW;   { angus V1.54 }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandSiteExec (Client : TFtpCtrlSocketW;   { angus V1.54 }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandSiteIndex (Client : TFtpCtrlSocketW;   { angus V1.54 }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandSiteZone (Client : TFtpCtrlSocketW;   { angus V1.54 }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandSiteMsg (Client  : TFtpCtrlSocketW;   { angus V1.54 }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandSiteCmlsd (Client : TFtpCtrlSocketW;   { angus V1.54 }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandSiteDmlsd (Client : TFtpCtrlSocketW;   { angus V1.54 }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandComb (Client     : TFtpCtrlSocketW;   { angus V1.54 }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandXCmlsd (Client : TFtpCtrlSocketW;     { angus V7.01 }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandXDmlsd (Client : TFtpCtrlSocketW;     { angus V7.01 }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandHost (Client : TFtpCtrlSocketW;       { angus V7.01 }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandRein (Client : TFtpCtrlSocketW;       { angus V7.01 }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandLang (Client : TFtpCtrlSocketW;       { angus V7.01 }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandEPRT(Client      : TFtpCtrlSocketW;         { IPv6 }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandEPSV(Client      : TFtpCtrlSocketW;         { IPv6 }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
    public
        SrvFileModeRead   : Word;   { angus V1.57 }
        SrvFileModeWrite  : Word;   { angus V1.57 }
        constructor Create(AOwner: TComponent); override;
        destructor  Destroy; override;
        procedure   Start;
        procedure   Stop;
        procedure   Disconnect(Client : TFtpCtrlSocketW);
        procedure   DisconnectAll;
        procedure   DoStartSendData(Client: TFtpCtrlSocketW; var Answer : TFtpString); virtual;
        procedure   AllocateMsgHandlers; override;
        procedure   FreeMsgHandlers; override;
        function    MsgHandlersCount: Integer; override;
        procedure   WndProc(var MsgRec: TMessage); override;
        { Check  if a given object is one of our clients }
        function    IsClient(SomeThing : TObject) : Boolean;
        function    OpenFileStream(const FileName: TFtpString; Mode: Word): TStream;    { angus V1.54 }
        procedure   CloseFileStreams(Client : TFtpCtrlSocketW);                      { angus V1.54 }
        property  ServSocket    : TWSocketServer      read  FSocketServer;          { angus V7.00 }
        property  ClientCount   : Integer             read  GetClientCount;
        property  Active        : Boolean             read  GetActive
                                                      write SetActive;
        property  ClientClass            : TFtpCtrlSocketWClass
                                                      read  FClientClass
                                                      write SetClientClass;           { angus V7.00 }
        { Client[] give direct access to anyone of our clients }
        property  Client[nIndex : Integer] : TFtpCtrlSocketW
                                                      read  GetClient;
        property  ZlibWorkDir            : TFtpString     read  FZlibWorkDir    { angus V1.54 }
                                                      write FZlibWorkDir;
        property  MultiListenIndex       : Integer    read  GetMultiListenIndex;   { V8.01 }
    published
{$IFNDEF NO_DEBUG_LOG}
        property IcsLogger               : TIcsLogger  read  GetIcsLogger  { V1.46 }
                                                      write SetIcsLogger;
{$ENDIF}
        property  Addr                   : String     read  FAddr
                                                      write FAddr;
        property  BindFtpData            : Boolean    read  FBindFtpData              { IPv6 }
                                                      write FBindFtpData default True;
        property  SocketFamily           : TSocketFamily                              { IPv6 }
                                                      read  FSocketFamily
                                                      write FSocketFamily;
        property  Port                   : String     read  FPort
                                                      write FPort;
        property  ListenBackLog          : Integer    read  FListenBackLog
                                                      write FListenBackLog;
        property  MultiListenSockets     : TWSocketMultiListenCollection              { IPv6 }
                                                      read  GetMultiListenSockets
                                                      write SetMultiListenSockets;
        property  Banner                 : TFtpString     read  FBanner
                                                      write FBanner;
        property  UserData               : LongInt    read  FUserData
                                                      write FUserData;
        property  MaxClients             : LongInt    read  FMaxClients
                                                      write FMaxClients;
        property  PasvIpAddr             : String     read  FPasvIpAddr
                                                      write FPasvIpAddr;
        property  PasvPortRangeStart     : Integer    read  FPasvPortRangeStart
                                                      write SetPasvPortRangeStart;
        property  PasvPortRangeSize      : Integer    read  FPasvPortRangeSize
                                                      write SetPasvPortRangeSize;
        property  Options                : TFtpsOptions
                                                      read  FOptions
                                                      write FOptions;
        property  MD5UseThreadFileSize   : Integer    read  FMd5UseThreadFileSize
                                                      write FMd5UseThreadFileSize;
        property  TimeoutSecsLogin       : Integer    read FTimeoutSecsLogin
                                                      write FTimeoutSecsLogin; { angus V1.54 }
        property  TimeoutSecsIdle        : Integer    read FTimeoutSecsIdle
                                                      write FTimeoutSecsIdle;  { angus V1.54 }
        property  TimeoutSecsXfer        : Integer    read FTimeoutSecsXfer
                                                      write FTimeoutSecsXfer;  { angus V1.54 }
        property  ZlibMinLevel           : Integer    read FZlibMinLevel
                                                      write FZlibMinLevel;   { angus V1.54 }
        property  ZlibMaxLevel           : Integer    read FZlibMaxLevel
                                                      write FZlibMaxLevel;   { angus V1.54 }
        property  ZlibNoCompExt          : String     read  FZlibNoCompExt
                                                      write FZlibNoCompExt;  { angus V1.54 }
        property  AlloExtraSpace         : Integer    read FAlloExtraSpace
                                                      write FAlloExtraSpace; { angus V1.54 }
        property  ZlibMinSpace           : Integer    read FZlibMinSpace
                                                      write FZlibMinSpace;   { angus V1.54 }
        property  ZlibMaxSize            : Int64      read  FZlibMaxSize
                                                      write FZlibMaxSize ;   { angus V1.55 }
        property  CodePage               : LongWord   read  FCodePage
                                                      write FCodePage;       { angus V7.01 }
        property  Language               : String     read  FLanguage
                                                      write FLanguage;       { angus V7.01 }
        property  MaxAttempts            : Integer    read  FMaxAttempts
                                                      write FMaxAttempts ;   { angus V7.06 }
{$IFDEF BUILTIN_THROTTLE}
        property  BandwidthLimit         : LongWord   read  FBandwidthLimit
                                                      write FBandwidthLimit;     { angus V7.12 }
        property  BandwidthSampling      : LongWord   read  FBandwidthSampling
                                                      write FBandwidthSampling;  { angus V7.12 }
{$ENDIF}
        property  OnStart                : TNotifyEvent
                                                      read  FOnStart
                                                      write FOnStart;
        property  OnStop                 : TNotifyEvent
                                                      read  FOnStop
                                                      write FOnStop;
        property  OnAuthenticate         : TFtpSrvAuthenticateEvent
                                                      read  FOnAuthenticate
                                                      write FOnAuthenticate;
        property  OnOtpMethod            : TFtpSrvOtpMethodEvent     { angus V1.54 }
                                                      read FOnOtpMethod
                                                      write FOnOtpMethod;
        property  OnOtpGetPassword       : TFtpSrvOtpGetPasswordEvent     { angus V1.54 }
                                                      read FOnOtpGetPassword
                                                      write FOnOtpGetPassword;
        property  OnClientDisconnect     : TFtpSrvClientConnectEvent
                                                      read  FOnClientDisconnect
                                                      write FOnClientDisconnect;
        property  OnClientConnect        : TFtpSrvClientConnectEvent
                                                      read  FOnClientConnect
                                                      write FOnClientConnect;
        property  OnClientCommand        : TFtpSrvClientCommandEvent
                                                      read  FOnClientCommand
                                                      write FOnClientCommand;
        property  OnAnswerToClient       : TFtpSrvAnswerToClientEvent
                                                      read  FOnAnswerToClient
                                                      write FOnAnswerToClient;
        property  OnChangeDirectory      : TFtpSrvChangeDirectoryEvent
                                                      read  FOnChangeDirectory
                                                      write FOnChangeDirectory;
        property  OnMakeDirectory        : TFtpSrvChangeDirectoryEvent
                                                      read  FOnMakeDirectory
                                                      write FOnMakeDirectory;
        property  OnBuildDirectory       : TFtpSrvBuildDirectoryEvent
                                                      read  FOnBuildDirectory
                                                      write FOnBuildDirectory;
        property  OnAlterDirectory       : TFtpSrvBuildDirectoryEvent
                                                      read  FOnAlterDirectory
                                                      write FOnAlterDirectory;
        property  OnStorSessionConnected : TFtpSrvDataSessionConnectedEvent
                                                      read  FOnStorSessionConnected
                                                      write FOnStorSessionConnected;
        property  OnRetrSessionConnected : TFtpSrvDataSessionConnectedEvent
                                                      read  FOnRetrSessionConnected
                                                      write FOnRetrSessionConnected;
        property  OnStorSessionClosed    : TFtpSrvDataSessionConnectedEvent
                                                      read  FOnStorSessionClosed
                                                      write FOnStorSessionClosed;
        property  OnRetrSessionClosed    : TFtpSrvDataSessionConnectedEvent
                                                      read  FOnRetrSessionClosed
                                                      write FOnRetrSessionClosed;
        property  OnRetrDataSent         : TFtpSrvRetrDataSentEvent
                                                      read  FOnRetrDataSent
                                                      write FOnRetrDataSent;
        property  OnValidatePut          : TFtpSrvValidateXferEvent
                                                      read  FOnValidatePut
                                                      write FOnValidatePut;
        property  OnValidateSize         : TFtpSrvValidateXferEvent
                                                      read  FOnValidateSize
                                                      write FOnValidateSize;
        property  OnValidateDele         : TFtpSrvValidateXferEvent
                                                      read  FOnValidateDele
                                                      write FOnValidateDele;
        property  OnValidateRmd          : TFtpSrvValidateXferEvent
                                                      read  FOnValidateRmd
                                                      write FOnValidateRmd;
        property  OnValidateRnFr         : TFtpSrvValidateXferEvent
                                                      read  FOnValidateRnFr
                                                      write FOnValidateRnFr;
        property  OnValidateRnTo         : TFtpSrvValidateXferEvent
                                                      read  FOnValidateRnTo
                                                      write FOnValidateRnTo;
        property  OnValidateGet          : TFtpSrvValidateXferEvent
                                                      read  FOnValidateGet
                                                      write FOnValidateGet;
        property  OnStorDataAvailable    : TFtpSrvDataAvailableEvent
                                                      read  FOnStorDataAvailable
                                                      write FOnStorDataAvailable;
        property  OnGetUniqueFileName    : TFtpSrvGetUniqueFileNameEvent
                                                      read  FOnGetUniqueFileName
                                                      write FOnGetUniqueFileName;
        property  OnGetProcessing        : TFtpSrvGetProcessingEvent
                                                      read  FOnGetProcessing
                                                      write FOnGetProcessing;
        property  OnBuildFilePath        : TFtpSrvBuildFilePathEvent
                                                      read  FOnBuildFilePath
                                                      write FOnBuildFilePath;
        property  OnValidateMfmt         : TFtpSrvValidateXferEvent        { angus V1.39 }
                                                      read  FOnValidateMfmt
                                                      write FOnValidateMfmt;
        property  OnCalculateMd5         : TFtpSrvCalculateMd5Event        { angus V1.39 }
                                                      read  FOnCalculateMd5
                                                      write FOnCalculateMd5;
        property  OnMd5Calculated        : TFtpSrvMd5CalculatedEvent       { AG V1.50 }
                                                      read  FOnMd5Calculated
                                                      write FOnMd5Calculated;
        property  OnCalculateCrc         : TFtpSrvCalculateMd5Event        { angus V1.54 }
                                                      read  FOnCalculateCrc
                                                      write FOnCalculateCrc;
        property  OnCrcCalculated        : TFtpSrvMd5CalculatedEvent       { angus V1.54 }
                                                      read  FOnCrcCalculated
                                                      write FOnCrcCalculated;
        property  OnPasvIpAddr           : TFtpSrvOnPasvIpAddrEvent       { AG V1.51 }
                                                      read  FOnPasvIpAddr
                                                      write FOnPasvIpAddr;
        property  OnEnterSecurityContext : TFtpSecurityContextEvent { AG V1.52 }
                                                      read  FOnEnterSecurityContext
                                                      write FOnEnterSecurityContext;
        property  OnLeaveSecurityContext : TFtpSecurityContextEvent { AG V1.52 }
                                                      read  FOnLeaveSecurityContext
                                                      write FOnLeaveSecurityContext;
        property  OnValidateAllo         : TFtpSrvGeneralEvent          { angus V1.54 }
                                                      read  FOnValidateAllo
                                                      write FOnValidateAllo;
        property  OnClntStr              : TFtpSrvGeneralEvent          { angus V1.54 }
                                                      read  FOnClntStr
                                                      write FOnClntStr;
        property  OnSiteMsg              : TFtpSrvGeneralEvent          { angus V1.54 }
                                                      read  FOnSiteMsg
                                                      write FOnSiteMsg;
        property  OnSiteExec             : TFtpSrvGeneralEvent          { angus V1.54 }
                                                      read  FOnSiteExec
                                                      write FOnSiteExec;
        property  OnSitePaswd            : TFtpSrvGeneralEvent          { angus V1.54 }
                                                      read  FOnSitePaswd
                                                      write FOnSitePaswd;
        property  OnCombine              : TFtpSrvGeneralEvent          { angus V1.54 }
                                                      read  FOnCombine
                                                      write FOnCombine;
        property  OnTimeout              : TFtpSrvTimeoutEvent          { angus V1.54 }
                                                      read  FOnTimeout
                                                      write FOnTimeout;
        property  OnDownCompressFile     : TFtpSrvCompressFileEvent          { angus V1.54 }
                                                      read  FOnDownCompressFile
                                                      write FOnDownCompressFile;
        property  OnUpCompressFile       : TFtpSrvCompressFileEvent          { angus V1.54 }
                                                      read  FOnUpCompressFile
                                                      write FOnUpCompressFile;
        property  OnUpCompressedFile     : TFtpSrvCompressedFileEvent        { angus V1.54 }
                                                      read  FOnUpCompressedFile
                                                      write FOnUpCompressedFile;
        property  OnDisplay              : TFtpSrvDisplayEvent               { angus V1.54 }
                                                      read  FOnDisplay
                                                      write FOnDisplay;
        property  OnHost                 : TFtpSrvHostEvent                  { angus V7.01 }
                                                      read  FOnHost
                                                      write FOnHost;
        property  OnRein                 : TFtpSrvReinEvent                  { angus V7.01 }
                                                      read  FOnRein
                                                      write FOnRein;
        property  OnLang                 : TFtpSrvLangEvent                  { angus V7.01 }
                                                      read  FOnLang
                                                      write FOnLang;
        property  OnAddVirtFiles         : TFtpSrvAddVirtFilesEvent          { angus V7.08 }
                                                      read  FOnAddVirtFiles
                                                      write FOnAddVirtFiles;
        property  OnBgException;
        property  SocketErrs             : TSocketErrs
                                                      read  FSocketErrs
                                                      write FSocketErrs;      { V8.37 }
        property  ExclusiveAddr          : Boolean    read  FExclusiveAddr
                                                      write FExclusiveAddr;   { V8.37 }
    end;

{ You must define USE_SSL so that SSL code is included in the component.   }
{ Either in OverbyteIcsDefs.inc or in the project/package options.         }
{$IFDEF USE_SSL}
{*_* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Author:       Arno Garrels
Description:  A component adding TLS/SSL support to TFtpServerW.
              Requires OpenSSL (http://www.openssl.org).
              More details in ReadMeIcsSsl.txt and IcsSslHowTo.txt.
              SSL demo applications can be found in /Delphi/SslInternet.
              If you use Delphi 7 and later, you may want to disable warnings
              for unsage type, unsafe code and unsafe typecast in the project
              options. Those warning are intended for .NET programs. You may
              also want to turn off deprecated symbol and platform symbol
              warnings.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

    TSslFtpWSocketMultiListenItem = class(TSslWSocketMultiListenItem)
    private
      FFtpSslTypes : TFtpSslTypes;
      procedure SetFtpSslTypes(const Value: TFtpSslTypes);
    public
      constructor Create(Collection: TCollection); override;
    published
      property  FtpSslTypes        : TFtpSslTypes        read  FFtpSslTypes
                                                         write SetFtpSslTypes;
    end;

    TFtpSslWSocketServer = class(TSslWSocketServer)
    protected
        function  MultiListenItemClass: TWSocketMultiListenItemClass; override;
    end;

    TSslFtpServerW = class(TFtpServerW)
    protected
        FFtpSslTypes                        : TFtpSslTypes;
        FOnSslHandshakeDone                 : TSslHandshakeDoneEvent;
        FOnSslVerifyPeer                    : TSslVerifyPeerEvent;
        FOnSslSvrGetSession                 : TSslSvrGetSession;
        FOnSslSvrNewSession                 : TSslSvrNewSession;
        FOnSslSetSessionIDContext           : TSslSetSessionIDContext;
        FMsg_WM_FTPSRV_ABORT_TRANSFER       : UINT;
        FMsg_WM_FTPSRV_Close_Data           : UINT;
        procedure CreateSocket; override;                   { IPv6 }
        procedure ClientPassiveSessionAvailable(Sender : TObject;
                                                AError : Word); override;
        procedure ClientDataSent(Sender : TObject; AError : Word); override; { 1.03 }
        procedure TriggerClientConnect(Client        : TFtpCtrlSocketW;
                                       AError        : Word); override;
        procedure SendAnswer(Client                  : TFtpCtrlSocketW;
                             Answer                  : TFtpString); override;
        procedure TriggerStorSessionConnected(Client : TFtpCtrlSocketW;
                                              Data   : TWSocket;
                                              AError : Word); override;
        procedure TriggerRetrSessionConnected(Client : TFtpCtrlSocketW;
                                              Data   : TWSocket;
                                              AError : Word); override;
        function  GetSslContext : TSslContext;
        procedure SetSslContext(Value : TSslContext);
        procedure CommandCCC(Client       : TFtpCtrlSocketW;   { 1.03 }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandPBSZ(Client      : TFtpCtrlSocketW;   { 1.03 }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandAUTH(Client      : TFtpCtrlSocketW;   { AG }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure CommandPROT(Client      : TFtpCtrlSocketW;   { AG }
                              var Keyword : TFtpString;
                              var Params  : TFtpString;
                              var Answer  : TFtpString); virtual;
        procedure TransferSslVerifyPeer(Sender        : TObject;
                                        var Ok        : Integer;
                                        Cert          : TX509Base); virtual;
        procedure TransferSslHandshakeDone(Sender         : TObject;
                                           ErrCode        : Word;
                                           PeerCert       : TX509Base;
                                           var Disconnect : Boolean); virtual;
        procedure TransferSslSetSessionIDContext(Sender : TObject;
                                   var SessionIDContext : TSslSessionIdContext); virtual;
        procedure TransferSslSvrNewSession(Sender       : TObject;
                                        SslSession      : Pointer;
                                        SessId          : Pointer;
                                        Idlen           : Integer;
                                 var AddToInternalCache : Boolean); virtual;
        procedure TransferSslSvrGetSession(Sender          : TObject;
                                         var SslSession : Pointer;
                                         SessId         : Pointer;
                                         Idlen          : Integer;
                                         var IncRefCount: Boolean); virtual;
        procedure SetFtpSslTypes(const Value: TFtpSslTypes); { 1.04 }
        function  GetIcsHosts: TIcsHostCollection;                    { V8.63 }
        procedure SetIcsHosts(const Value: TIcsHostCollection);       { V8.63 }
        function  GetRootCA: String;                                  { V8.63 }
        procedure SetRootCA(const Value: String);                     { V8.63 }
{$IFDEF AUTO_X509_CERTS} 
        function  GetSslX509Certs: TSslX509Certs;                     { V8.63 }
        procedure SetSslX509Certs(const Value : TSslX509Certs);       { V8.63 }
{$ENDIF} // AUTO_X509_CERTS
        function  GetCertExpireDays: Integer;                         { V8.63 }
        procedure SetCertExpireDays(const Value : Integer);           { V8.63 }
        function  GetSslCertAutoOrder: Boolean;                       { V8.63 }
        procedure SetSslCertAutoOrder(const Value : Boolean);         { V8.63 }
    public
        constructor Create(AOwner: TComponent); override;
        function  MsgHandlersCount : Integer; override;
        procedure AllocateMsgHandlers; override;
        procedure FreeMsgHandlers; override;
        function  ValidateHosts(Stop1stErr: Boolean=True;
                      NoExceptions: Boolean=False): String; virtual; { V8.63 }
        function  RecheckSslCerts(var CertsInfo: String;
                      Stop1stErr: Boolean=True; NoExceptions: Boolean=False): Boolean; { V8.63 }
        function  ListenAllOK: Boolean;                              { V8.63 }
        function  ListenStates: String;                              { V8.63 }
    published
        property  SslContext         : TSslContext         read  GetSslContext
                                                           write SetSslContext;
        property  OnSslVerifyPeer    : TSslVerifyPeerEvent read  FOnSslVerifyPeer
                                                           write FOnSslVerifyPeer;
        property  OnSslSetSessionIDContext : TSslSetSessionIDContext
                                                           read  FOnSslSetSessionIDContext
                                                           write FOnSslSetSessionIDContext;
        property  OnSslSvrNewSession : TSslSvrNewSession   read  FOnSslSvrNewSession
                                                           write FOnSslSvrNewSession;
        property  OnSslSvrGetSession : TSslSvrGetSession   read  FOnSslSvrGetSession
                                                           write FOnSslSvrGetSession;
        property  OnSslHandshakeDone : TSslHandshakeDoneEvent
                                                           read  FOnSslHandshakeDone
                                                           write FOnSslHandshakeDone;
        property  FtpSslTypes        : TFtpSslTypes        read  FFtpSslTypes  { 1.03 }
                                                           write SetFtpSslTypes; { 1.04 }
        property  IcsHosts           : TIcsHostCollection  read  GetIcsHosts
                                                           write SetIcsHosts;    { V8.63 }
        property  RootCA             : String              read  GetRootCA
                                                           write SetRootCA;      { V8.63 }
        property  SslCertAutoOrder   : Boolean             read  GetSslCertAutoOrder
                                                           write SetSslCertAutoOrder; { V8.63 }
        property  CertExpireDays     : Integer             read  GetCertExpireDays
                                                           write SetCertExpireDays; { V8.63 }
{$IFDEF AUTO_X509_CERTS}
        property  SslX509Certs       : TSslX509Certs       read  GetSslX509Certs
                                                           write SetSslX509Certs; { V8.63 }
{$ENDIF} // AUTO_X509_CERTS
    end;

procedure IcsLoadFtpServerWFromIni(MyIniFile: TCustomIniFile; SslFtpServerW:
                         TSslFtpServerW; const Section: String = 'SslFtpServerW');     { V8.63 }
{$ENDIF} // USE_SSL

function GetZlibCacheFileName(const S : TFtpString) : TFtpString;  { angus V1.54 }
function  IsUNC(S : TFtpString) : Boolean;
procedure PatchIE5(var S : TFtpString);
function FormatFactsDirEntry(F : TIcsSearchRecW; const FileName: TFtpString) : TFtpString;  { angus 1.54  }
function FormatUnixDirEntry(F : TIcsSearchRecW; const FileName: TFtpString) : TFtpString;   { V7.08 }
procedure UpdateThreadOnProgress(Obj: TObject; Count: Int64; var Cancel: Boolean);          { V7.08 }


implementation

var
    ThisYear, ThisMonth, ThisDay : Word;

const
    DefaultBanner     = '220-ICS FTP Server ready';
    msgSyntaxParam    = '501 Syntax error in parameter.';        { V1.52 AG }
    msgSyntaxParamFmt = '501 Syntax error in parameter: %s.';    { V1.52 AG }
    msgDftBanner      = '220 ICS FTP Server ready.';
    msgTooMuchClients = '421 Too many users connected.';
    msgCmdUnknown     = '500 ''%s'': command not understood.';
    msgLoginFailed    = '530 Login incorrect.';
    msgNotLogged      = '530 Please login with USER and PASS.';
    msgEPSVALLDeny    = '501 %s command not allowed after EPSV ALL.';   { IPv6 }
    msgNoUser         = '503 Login with USER first.';
    msgLogged         = '230 User %s logged in.';
    msgPassRequired   = '331 Password required for %s.';
    msgOptRespRequired = '331 Response to %s required for %s.';   { angus V1.54 }
    msgCWDSuccess     = '250 CWD command successful. "%s" is current directory.';
    msgCWDFailed      = '501 CWD failed. %s';
    msgPWDSuccess     = '257 "%s" is current directory.';
    msgQuit           = '221 Goodbye.';
    msgPortSuccess    = '200 Port command successful.';
    msgPortFailed     = '501 Invalid PORT command.';
    msgInvalidProto   = '522 Network protocol not supported, use (%s).';     { IPv6 }
    msgStorDisabled   = '501 Permission Denied'; {'500 Cannot STOR.';}
    msgStorSuccess    = '150 Opening data connection for %s.';
    msgStorFailed     = '501 Cannot STOR. %s';
    msgStorAborted    = '426 Connection closed; %s.';
    msgStorOk         = '226 File received ok';
{   msgStorOk         = '226-Multiple lines answer'#13#10'  Test'#13#10#13#10'226 File received OK'; }
    msgStorError      = '426 Connection closed; transfer aborted. Error %s';
    msgRetrDisabled   = '500 Cannot RETR.';
    msgRetrSuccess    = '150 Opening data connection for %s.';
    msgRetrFailed     = '501 Cannot RETR. %s';
    msgRetrAborted    = '426 Connection closed; %s.';
    msgRetrOk         = '226 File sent ok';
    msgRetrError      = '426 Connection closed; transfer aborted. Error %s';
    msgRetrNotExists  = '550 ''%s'': no such file or directory.';     { angus V1.54 }
    msgRetrFileErr    = '451 Cannot open file: %s.';                  { angus V1.54 }
    msgSystem         = '215 UNIX Type: L8 Internet Component Suite';
    msgDirOpen        = '150 Opening data connection for directory list.';
    msgDirFailed      = '451 Failed: %s.';
    msgTypeOk         = '200 Type set to %s.';
    msgTypeFailed     = '500 ''TYPE %s'': command not understood.';
    msgDeleNotExists  = '550 ''%s'': no such file or directory.';
    msgDeleOk         = '250 File ''%s'' deleted.';
    msgDeleFailed     = '450 File ''%s'' can''t be deleted.';
    msgDeleSyntax     = msgSyntaxParam;//'501 Syntax error in parameter.';  { V1.52 AG }
    msgDeleDisabled   = '550 Cannot delete.';
    msgRnfrNotExists  = '550 ''%s'': no such file or directory.';
    msgRnfrSyntax     = msgSyntaxParam;//'501 Syntax error in parameter.';  { V1.52 AG }
    msgRnfrOk         = '350 File exists, ready for destination name.';
    msgRnFrDisabled   = '500 Cannot RNFR.';
    msgRntoNotExists  = '550 ''%s'': no such file or directory.';
    msgRntoAlready    = '553 ''%s'': file already exists.';
    msgRntoOk         = '250 File ''%s'' renamed to ''%s''.';
    msgRntoFailed     = '450 File ''%s'' can''t be renamed.';
    msgRntoSyntax     = msgSyntaxParam;//'501 Syntax error in parameter.';  { V1.52 AG }
    msgRnToDisabled   = '500 Cannot RNTO.';
    msgMkdOk          = '257 ''%s'': directory created.';
    msgMkdAlready     = '550 ''%s'': file or directory already exists.';
    msgMkdFailed      = '550 ''%s'': can''t create directory.';
    msgMkdSyntax      = msgSyntaxParam;//'501 Syntax error in parameter.';  { V1.52 AG }
    msgRmdOk          = '250 ''%s'': directory removed.';
    msgRmdNotExists   = '550 ''%s'': no such directory.';
    msgRmdFailed      = '550 ''%s'': can''t remove directory.';
    msgRmdDisabled    = '500 Cannot remove directory.';
    msgRmdSyntax      = msgSyntaxParam;//'501 Syntax error in parameter.';  { V1.52 AG }
    msgNoopOk         = '200 Ok. Parameter was ''%s''.';
    msgAborOk         = '225 ABOR command successful.';
    msgPasvLocal      = '227 Entering Passive Mode (127,0,0,1,%d,%d).';
    msgPasvRemote     = '227 Entering Passive Mode (%d,%d,%d,%d,%d,%d).';
    msgEPSVOk         = '229 Entering Extended Passive Mode (|||%d|)';     { IPv6 }
    msgPasvExcept     = '500 PASV exception: ''%s''.';
    msgSizeOk         = '213 %d';
    msgSizeDisabled   = '501 Permission Denied';
    msgSizeFailed     = '550 Command failed: %s.';
    msgSizeSyntax     = msgSyntaxParam;//'501 Syntax error in parameter.';  { V1.52 AG }
    msgRestOk         = '350 REST supported. Ready to resume at byte offset %d.';
    msgRestZero       = '501 Required byte offset parameter bad or missing.';
    msgRestFailed     = msgSyntaxParamFmt;//'501 Syntax error in parameter: %s.'; { V1.52 AG }
    msgRestNotModeZ   = '501 REST not supported while using Mode Z';    { angus V1.55 }
    msgAppeFailed     = '550 APPE failed.';
    msgAppeSuccess    = '150 Opening data connection for %s (append).';
    msgAppeDisabled   = '500 Cannot APPE.';
    msgAppeAborted    = '426 Connection closed; %s.';
    msgAppeOk         = '226 File received ok';
    msgAppeError      = '426 Connection closed; transfer aborted. Error %s';
    msgAppeReady      = '150 APPE supported.  Ready to append file "%s" at offset %d.';
    msgStruOk         = '200 Ok. STRU parameter ''%s'' ignored.';
    msgMdtmOk         = '213 %s';
    msgMdtmFailed     = '550 %s';
    msgMdtmSyntax     = '501 Syntax error in MDTM/MFMT parameter.';
    msgMdtmNotExists  = '550 ''%s'': no such file or directory.';
    msgModeOK         = '200 MODE %s Ok';                               { angus V1.54 add param }
    msgModeSyntax     = '501 Missing argument for MODE';
    msgModeNotS       = '502 MODE %s not supported';                    { angus V1.54 add param }
    msgOverflow       = '500 Command too long';
    msgStouOk         = '250 ''%s'': file created.';
    msgStouSuccess    = msgStorSuccess;
    msgStouFailed     = '501 Cannot STOU. %s';
    msgStouAborted    = msgStorAborted;
    msgStouError      = msgStorError;
    msgFeatFollows    = '211-Extensions supported:';
    msgFeatFollowDone = '211 END';
    msgFeatFailed     = '211 No-Features';
    msgMdtmChangeOK   = '253 Date/time changed OK';                  { angus V1.38 }
    msgMfmtChangeOK   = '213 Date/time changed OK';                  { angus V1.39 }
    msgMdtmChangeFail = '550 MDTM/MFMT cannot change date/time on this server';  { angus V1.38 }
    msgCWDNoDir       = '550 CWD Failed to change directory to %s';  { angus V1.38 }
    msgMlstFollows    = '250-Listing ';                              { angus V1.38 }
    msgMlstFollowDone = '250 END';                                   { angus V1.38 }
    msgMlstNotExists  = '550 ''%s'': no such file or directory.';    { angus V1.38 }
    msgMlstDenied     = '550 Access denied';                         { AG V1.52 }
    msgMd5NotFound    = '550 ''%s'': no such file.';                 { angus V1.39 }
    msgMd5Failed      = '550 MD5 SUM failed : ''%s''.';              { angus V1.39 }
    msgMd5Ok          = '251 "%s" %s';                               { angus V1.39 }
    msgTimeout        = '421 Connection closed, timed out after %d secs.'; { angus V1.54 }
    msgNotedOK        = '200 Noted OK.';                             { angus V1.54 }
    msgSiteZone       = '210 UTC%s';                                 { angus V1.54 }
    msgCrcOk          = '250 %s';                                    { angus V1.54 }
    msgCrcFailed      = '550 CRC failed : ''%s''.';                  { angus V1.54 }
    msgSiteFailed     = '550 SITE command failed.';                  { angus V1.54 }
    msgIndexFollows   = '200-Index %s';                              { angus V1.54 }
    msgIndexDone      = '200 END Index';                             { angus V1.54 }
    msgOtpsOK         = '200 %s Ok.';                                { angus V1.54 }
    msgOptsFailed     = '501 %s is invalid.';                        { angus V1.54 }
    msgAlloOK         = '200 ALLO OK, %d bytes available.';          { angus V1.54 }
    msgAlloFail       = '501 Invalid size parameter.';               { angus V1.54 }
    msgAlloFull       = '501 Insufficient disk space, only %d bytes available.';  { angus V1.54 }
    msgHostOK         = '220 HOST Ok, FTP Server ready.';            { angus V7.01 }
    msgHostUnavail    = '421 HOST unavailable.';                     { angus V7.01 }
    msgHostSyntax     = msgSyntaxParam;  { 501 }                     { angus V7.01 }
    msgHostTooLate    = '503 HOST no longer allowed.';               { angus V7.01 }
    msgHostUnknown    = '504 HOST unknown or not allowed.';          { angus V7.01 }
    msgReinOK         = '220 Reinitialise Ok, FTP Server ready.';    { angus V7.01 }
    msgReinUnavail    = '421 Reinitialise unavailable.';             { angus V7.01 }
    msgLangOK         = '200 %s Ok.';                                { angus V7.01 }
    msgLangUnknown    = '504 %s unknown.' ;                          { angus V7.01 }
    msgNotAllowed     = '421 Connection not allowed.';               { angus V7.06 }

{$IFDEF USE_SSL}
    msgAuthOk         = '234 Using authentication type %s';
    msgAuthDenied     = '502 %s authentication not allowed'; // SSL/TLS
    msgAuthYetSetOkV2 = '234 Auth type already set.';
    msgAuthYetSetOkV3 = msgAuthYetSetOkV2 + ' SSL re-negotiation allowed';
    //msgAuthYetSetErr  = '534 Auth type already set to %s';
    msgAuthInitError  = '431 Could not initialize %s connection';
    msgAuthNoSupport  = '504 Auth type ''%s'' not supported';

    msgErrInSslOnly   = '533 %s requires a secure connection';
    msgProtOk         = '200 Protection level set to %s';
    msgProtNoSupport  = '504 Protection level ''%s'' not supported';
    msgProtUnknown    = '504 Protection level ''%s'' not recognized';
    msgErrSslInit     = 'Fatal error on initializing SSL';
    msgPbszOk         = '200 PBSZ set to 0';
    msgCccOk          = '200 CCC OK Continue using plaintext commands';
{$ENDIF}


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function CreateUniqueFile(Dir, Prefix, Extension: TFtpString): TFtpString; { V1.52 AG}
var
    FileName  : TFtpString;
    I         : Integer;
    hFile     : THandle;
    Err       : DWord;
begin
    Result := '';
    Dir := Trim(Dir);
    if (Length(Dir) = 0) or (not IcsDirExistsW(Dir)) then
        Exit;
    Dir := IcsIncludeTrailingPathDelimiterW(Dir);
    Prefix := Trim(Prefix);
    if Length(Prefix) > 3 then
        SetLength(Prefix, 3);
    Extension := Trim(Extension);
    Dir := Dir + Prefix + FormatDateTime('yymdh', Now);
    I   := 0;
    Err := ERROR_FILE_EXISTS;
    while (Err = ERROR_FILE_EXISTS) and (I < MaxInt) do begin
        FileName := Dir + IntToStr(I) + Extension;
        if Length(FileName) > MAX_PATH then
            Break;
        hFile := CreateFileW(PWideChar(FileName), GENERIC_READ or GENERIC_WRITE,
                            0, nil, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, 0);
        if hFile <> INVALID_HANDLE_VALUE then begin
            CloseHandle(hFile);
            Result := FileName;
            Break;
        end
        else
            Err := GetLastError;
        Inc(I);
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function GetZlibCacheFileName(const S : TFtpString) : TFtpString;  { angus V1.54 }
var
    I : Integer;
    Ticks: String;
begin
    Result := IcsAnsiLowercaseW (S);
    for I := 1 to Length(Result) do begin
        if (Result [I] = PathDelim) or (Result [I] = '.') or
                           (Result [I] = ':') then Result[I] := '_';
    end;
    Ticks := IntToStr(IcsGetTickCountX);  { now make it unique by adding some ms }
    I := Length(Ticks);
    if I < 6 then Ticks := '123' + Ticks; { if windows running short }
    Result := Result + '_' + Copy (Ticks, I-6, 6) + '.zlib';
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function IsSpace(Ch : WideChar) : Boolean;
begin
    Result := (Ch = ' ') or (Ch = Char($09));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function IsDigit(Ch : WideChar) : Boolean; { V6.03 }
begin
    Result := (Ch >= '0') and (Ch <= '9');
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function IsLetterOrDigit(Ch : WideChar) : Boolean;
begin
    Result := ((Ch >= 'a') and (Ch <= 'z')) or
              ((Ch >= 'A') and (Ch <= 'Z')) or
              ((Ch >= '0') and (Ch <= '9'));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function atosi(const value : UnicodeString) : Integer;  { angus V1.38 signed integer, added "const", AG }
var
    i, j : Integer;
begin
    Result := 0;
    i := 1;
    while (i <= Length(Value)) and (Value[i] = ' ') do
        i := i + 1;
    j := i;
    while (i <= Length(Value)) and ((Value[i] = '+') or (Value[i] = '-')) do
       i := i + 1;
    while (i <= Length(Value)) and (Value[i] >= '0') and (Value[i] <= '9')do begin
        Result := Result * 10 + ord(Value[i]) - ord('0');
        i := i + 1;
    end;
    if j < Length(Value) then begin
        if value[j] = '-' then
            Result := -Result;
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CreateSocket;               { IPv6 }
begin
    FSocketServer := TWSocketServer.Create(Self);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TFtpServerW.Create(AOwner: TComponent);
var
    Len : Cardinal;
begin
    inherited Create(AOwner);
    AllocateHWnd;
 { angus V7.00 WSocketServer instead of WSocket }
    FClientClass          := TFtpCtrlSocketW;
    //FSocketServer         := TWSocketServerW.Create(Self);
    CreateSocket;                                  { IPv6 }
    FSocketServer.Name    := 'WSocketServer';
    FSocketServer.ClientClass         := FClientClass;
    FSocketServer.OnClientConnect     := ServerClientConnect;
    FSocketServer.OnClientDisconnect  := ServerClientDisconnect;
{$IFNDEF NO_DEBUG_LOG}
    FSocketServer.IcsLogger           := GetIcsLogger ;
{$ENDIF}

    FPort               := 'ftp';
    FSocketFamily       := DefaultSocketFamily;       { IPv6 }
    FAddr               := ICS_ANY_HOST_V4;           { IPv6 }
    FBanner             := msgDftBanner;
    FListenBackLog      := 5;
    FOptions            := [{tpsThreadRecurDirs,}ftpsSiteXmlsd, ftpsCwdCheck, ftpsCdupHome] ;   { angus V7.02, V8.04 stop thread}
    FMd5UseThreadFileSize   := 0;  { AG V1.50 }
    FTimeoutSecsLogin   := 60;      { angus V1.54 }
    FTimeoutSecsIdle    := 300;     { angus V1.54 }
    FTimeoutSecsXfer    := 60;      { angus V1.54, V7.09 reduced from 900 to 60 secs }
    FZlibMinLevel       := 1;       { angus V1.54 }
    FZlibMaxLevel       := 9;       { angus V1.54 }
    FZlibNoCompExt      := '.zip;.rar;.7z;.cab;.lzh;.gz;.avi;.wmv;.mpg;.mp3;.jpg;.png;'; { angus V1.54 }
    SetLength(FZlibWorkDir, 1024);
    Len := GetTempPathW(Length(FZlibWorkDir) - 1, PWideChar(FZlibWorkDir));{ AG V6.04 }
    SetLength(FZlibWorkDir, Len);                                     { AG V6.04 }
    FZlibWorkDir        := IcsIncludeTrailingPathDelimiterW (FZlibWorkDir) + 'icsftpsrv\' ;  { angus V1.54 }
    FZlibMinSpace       := 50000000;               { angus V1.54 50 Mbyte }
    FZlibMaxSize        := 500000000;              { angus V1.55 - 500 meg }
    FAlloExtraSpace     := 1000000;                { angus V1.54 1 Mbyte }
    FEventTimer         := TIcsTimer.Create(Self); { angus V1.54 }
    FEventTimer.Enabled := false;                  { angus V1.54 }
    FEventTimer.OnTimer := EventTimerOnTimer;      { angus V1.54 }
    FEventTimer.Interval := 5000;     { angus V1.56 only used for timeouts, slow }
    SrvFileModeRead     := fmOpenRead + fmShareDenyNone;         { angus V1.57 }
    SrvFileModeWrite    := fmOpenReadWrite or fmShareDenyWrite;  { angus V1.57 }
    FCodePage           := CP_ACP;  { angus V7.01 }
    FLanguage           := 'EN*';   { angus V7.01 we only support ENglish }
    FSystemCodePage     := GetAcp;  { AG 7.02 }
    FMaxAttempts        := 12 ;     { angus V7.06 }
    FBindFtpData        := True;     { IPv6 }
    FExclusiveAddr      := True;    { V8.37 make our sockets exclusive  }
    {$IFDEF BUILTIN_THROTTLE}
    FBandwidthLimit     := 0;       { angus V7.12 no bandwidth limit, yet, bytes per second }
    FBandwidthSampling  := 1000;    { angus V7.12 Msec sampling interval, less is not possible }
{$ENDIF}
 { !!!!!!!!!!! NGB: Added next five lines }
    FPasvIpAddr         := '';
    FPasvPortRangeStart := 0;
    FPasvPortRangeSize  := 0;
    FPasvPortTable      := nil;
    FPasvPortTableSize  := 0;
{ !!!!!!!!!!! NGB: Added previous five lines }
    FPasvNextNr         := 0;  { angus V1.56 }
    SetLength(FCmdTable, ftpcLast + 1 + 5);
    AddCommand('PORT', CommandPORT);
    AddCommand('STOR', CommandSTOR);
    AddCommand('RETR', CommandRETR);
    AddCommand('CWD',  CommandCWD);
    AddCommand('XPWD', CommandXPWD);
    AddCommand('PWD',  CommandPWD);
    AddCommand('USER', CommandUSER);
    AddCommand('PASS', CommandPASS);
    AddCommand('LIST', CommandLIST);
    AddCommand('NLST', CommandNLST);
    AddCommand('TYPE', CommandTYPE);
    AddCommand('SYST', CommandSYST);
    AddCommand('QUIT', CommandQUIT);
    AddCommand('DELE', CommandDELE);
    AddCommand('SIZE', CommandSIZE);
    AddCommand('REST', CommandREST);
    AddCommand('RNFR', CommandRNFR);
    AddCommand('RNTO', CommandRNTO);
    AddCommand('MKD',  CommandMKD);
    AddCommand('RMD',  CommandRMD);
    AddCommand('ABOR', CommandABOR);
    AddCommand('PASV', CommandPASV);
    AddCommand('NOOP', CommandNOOP);
    AddCommand('CDUP', CommandCDUP);
    AddCommand('APPE', CommandAPPE);
    AddCommand('STRU', CommandSTRU);
    AddCommand('XMKD', CommandMKD);
    AddCommand('XRMD', CommandRMD);
    AddCommand('MDTM', CommandMDTM);
    AddCommand('MODE', CommandMODE);
    AddCommand('OVER', CommandOverflow);
    AddCommand('STOU', CommandSTOU);
    AddCommand('FEAT', CommandFEAT);
    AddCommand('MLST', CommandMLST);  { angus V1.38 }
    AddCommand('MLSD', CommandMLSD);  { angus V1.38 }
    AddCommand('MFMT', CommandMDTM);  { angus V1.39 }
    AddCommand('MD5', CommandMD5);    { angus V1.39 }
    AddCommand('XCRC', CommandXCRC);  { angus V1.54 }
    AddCommand('XMD5', CommandMD5);   { angus V1.54 note same handler as MD5 }
    AddCommand('ALLO', CommandALLO);  { angus V1.54 }
    AddCommand('CLNT', CommandCLNT);  { angus V1.54 }
    AddCommand('OPTS', CommandOPTS);  { angus V1.54 }
    AddCommand('SITE PSWD', CommandSitePaswd);   { angus V1.54 }
    AddCommand('SITE EXEC', CommandSiteExec);    { angus V1.54 }
    AddCommand('SITE INDEX', CommandSiteIndex);  { angus V1.54 }
    AddCommand('SITE ZONE', CommandSiteZone);    { angus V1.54 }
    AddCommand('SITE MSG', CommandSiteMsg);      { angus V1.54 }
    AddCommand('SITE CMLSD', CommandSiteCmlsd);  { angus V1.54 }
    AddCommand('SITE DMLSD', CommandSiteDmlsd);  { angus V1.54 }
    AddCommand('COMB', CommandCOMB);      { angus V1.54 }
    AddCommand('XCMLSD', CommandXCMLSD);  { angus V7.01 }
    AddCommand('XDMLSD', CommandXDMLSD);  { angus V7.01 }
    AddCommand('HOST', CommandHOST);      { angus V7.01 }
    AddCommand('REIN', CommandREIN);      { angus V7.01 }
    AddCommand('LANG', CommandLANG);      { angus V7.01 }
    AddCommand('EPRT', CommandEprt);      { IPv6 }
    AddCommand('EPSV', CommandEpsv);      { IPv6 }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
destructor TFtpServerW.Destroy;
begin
    if Assigned(FEventTimer) then begin  { angus V1.54 }
        FEventTimer.Destroy;
        FEventTimer := nil;
    end;
    if Assigned(FSocketServer) then begin      { angus V7.00 }
        FSocketServer.Destroy;
        FSocketServer := nil;
    end;
    if Assigned(FPasvPortTable) then begin
        FreeMem(FPasvPortTable, FPasvPortTableSize);
        FPasvPortTable     := nil;
        FPasvPortTableSize := 0;
    end;
    SetLength(FCmdTable, 0);
    inherited Destroy;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TFtpServerW.MsgHandlersCount : Integer;
begin
    Result := 5 + inherited MsgHandlersCount;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.AllocateMsgHandlers;
begin
    inherited AllocateMsgHandlers;
    FMsg_WM_FTPSRV_CLOSE_REQUEST  := FWndHandler.AllocateMsgHandler(Self);
    FMsg_WM_FTPSRV_ABORT_TRANSFER := FWndHandler.AllocateMsgHandler(Self);
    FMsg_WM_FTPSRV_CLOSE_DATA     := FWndHandler.AllocateMsgHandler(Self);
    FMsg_WM_FTPSRV_START_SEND     := FWndHandler.AllocateMsgHandler(Self);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.FreeMsgHandlers;
begin
    if Assigned(FWndHandler) then begin
        FWndHandler.UnregisterMessage(FMsg_WM_FTPSRV_CLOSE_REQUEST);
        FWndHandler.UnregisterMessage(FMsg_WM_FTPSRV_ABORT_TRANSFER);
        FWndHandler.UnregisterMessage(FMsg_WM_FTPSRV_CLOSE_DATA);
        FWndHandler.UnregisterMessage(FMsg_WM_FTPSRV_START_SEND);
    end;
    inherited FreeMsgHandlers;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.WndProc(var MsgRec: TMessage);
begin
    try
        with MsgRec do begin
            if  Msg = FMsg_WM_FTPSRV_CLOSE_REQUEST  then
                WMFtpSrvCloseRequest(MsgRec)
            else if Msg = FMsg_WM_FTPSRV_ABORT_TRANSFER then
                WMFtpSrvAbortTransfer(MsgRec)
            else if Msg = FMsg_WM_FTPSRV_CLOSE_DATA then
                WMFtpSrvCloseData(MsgRec)
            else if Msg = FMsg_WM_FTPSRV_START_SEND then
                WMFtpSrvStartSend(MsgRec)
            else
                inherited WndProc(MsgRec);
        end;
    except
        on E:Exception do
            HandleBackGroundException(E);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.WMFtpSrvCloseRequest(var msg: TMessage);
var
    Client : TFtpCtrlSocketW;
begin
    Client := TFtpCtrlSocketW(msg.LParam);
    if FSocketServer.IsClient(Client) then begin      { angus V7.00 }
        { Check if client.ID is still the same as when message where posted }
        if WPARAM(Client.ID) = Msg.WParam then begin
            if Client.AllSent then
                Client.Close
            else
                Client.CloseRequest := TRUE;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.Notification(AComponent: TComponent; operation: TOperation);
begin
    inherited Notification(AComponent, operation);
    if operation = opRemove then begin
        if AComponent = FSocketServer then         { angus V7.00 }
            FSocketServer := nil;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TFtpServerW.OpenFileStream (const FileName: TFtpString; Mode: Word): TStream;   { V1.54 }
begin
    Result := TIcsBufferedFileStream.Create(FileName, Mode, MAX_BUFSIZE);
end ;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CloseFileStreams(Client : TFtpCtrlSocketW);    { V1.54 }
begin
  { delete temporary ZLIB file if not from cache }
    try
        if Assigned (Client.ZFileStream) then Client.ZFileStream.Destroy;
        Client.ZFileStream := Nil;
        if (Client.ZStreamState > ftpzStateNone) and
                                        Client.ZCompFileDelete then begin
            try
                if IcsFileExistsW(Client.ZCompFileName) then
                                           IcsDeleteFileW (Client.ZCompFileName);
            except
            end;
        end;
    except
    end;
    Client.ZStreamState := ftpZStateNone;
    if Client.HasOpenedFile then begin
        if Assigned(Client.DataStream) then Client.DataStream.Destroy;
        Client.DataStream    := nil;
        Client.HasOpenedFile := FALSE;
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.AddCommand(
    const Keyword : String;
    const Proc    : TFtpSrvCommandProc);
begin
    if FLastCmd > High(FCmdTable) then
        raise FtpServerException.Create('Too many command');
    FCmdTable[FLastCmd].KeyWord := KeyWord;
    FCmdTable[FLastCmd].Proc    := Proc;
    Inc(FLastCmd);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.Start;
begin
    if FSocketServer.State = wsListening then                { angus V7.00 }
        Exit;             { Server is already running }
{$IFDEF USE_SSL}
    if TSslWSocketServer(FSocketServer).GetIcsHosts <> Nil then begin  { V8.63 already set from IcsHosts }
        if TSslWSocketServer(FSocketServer).IcsHosts.Count > 0 then begin
            FPort := FSocketServer.Port;
            FAddr := FSocketServer.Addr;
            FSocketFamily := FSocketServer.SocketFamily;
        end;
    end;
{$ENDIF}
    FSocketServer.Proto             := 'tcp';
    FSocketServer.SocketFamily      := FSocketFamily;      { IPv6 }
    FSocketServer.Addr              := FAddr;
    FSocketServer.Port              := FPort;
    FSocketServer.ListenBacklog     := FListenBackLog;
    FSocketServer.MaxClients        := FMaxClients;
    FSocketServer.Banner            := FBanner;
    FSocketServer.BannerTooBusy     := msgTooMuchClients;
    FSocketServer.OnChangeState     := ServSocketStateChange;
    FSocketServer.ComponentOptions  := [wsoNoReceiveLoop];
    FSocketServer.BandwidthLimit    := fBandwidthLimit;     { angus V7.16 in client connect }
    FSocketServer.BandwidthSampling := fBandwidthSampling;  { angus V7.16 }
    FSocketServer.ExclusiveAddr     := FExclusiveAddr;      { V8.37 }
    FSocketServer.SocketErrs        := FSocketErrs;         { V8.37 }
    FSocketServer.MultiListen;             { V8.00 }
    FEventTimer.Enabled := true;                  { angus V1.54 }
{$IFNDEF NO_DEBUG_LOG}
    if CheckLogOptions(loProtSpecInfo) then                            { V1.46 }
        DebugLog(loProtSpecInfo, Name + ' started');                   { V1.46 }
{$ENDIF}
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.Stop;
begin
    FEventTimer.Enabled := false;                  { angus V1.54 }
    FSocketServer.Close;                           { angus V7.00 }
{$IFNDEF NO_DEBUG_LOG}
    if CheckLogOptions(loProtSpecInfo) then                            { V1.46 }
        DebugLog(loProtSpecInfo, Name + ' stopped');                   { V1.46 }
{$ENDIF}
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.DisconnectAll;
begin
    FSocketServer.DisconnectAll;      { angus V7.00 }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.Disconnect(Client : TFtpCtrlSocketW);
begin
    if NOT FSocketServer.IsClient(Client) then
        raise FtpServerException.Create('Disconnect: Not one of our clients');
    FSocketServer.Disconnect(Client);       { angus V7.00 }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TFtpServerW.GetActive : Boolean;
begin
    Result := (FSocketServer.State = wsListening);    { angus V7.00 }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.SetActive(newValue : Boolean);
begin
    if newValue then
        Start
    else
        Stop;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.SetClientClass(const NewValue: TFtpCtrlSocketWClass);    { angus V7.00 }
begin
    if NewValue <> FSocketServer.ClientClass then begin
        FClientClass := NewValue;
        FSocketServer.ClientClass := NewValue;
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.ServSocketStateChange(Sender : TObject; OldState, NewState : TSocketState);
begin
    if csDestroying in ComponentState then
        Exit;
    if NewState = wsListening then
        TriggerServerStart
    else if NewState = wsClosed then
        TriggerServerStop;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.ServerClientConnect(Sender: TObject;
                                Client: TWSocketClient; Error: Word);    { angus V7.00 }
var
    MyClient: TFtpCtrlSocketW;   { renamed to avoid conflict with TWSocketClient angus V7.00 }
begin
    if Error <> 0 then
        raise FtpServerException.Create('Session Available Error - ' +
                                                    GetWinsockErr(Error));
    MyClient := Client as TFtpCtrlSocketW;
    MyClient.DataSocket.Name := Name + '_DataWSocket' + IntToStr(MyClient.ID);
    MyClient.OnCommand       := ClientCommand;
    MyClient.OnDataSent      := ClientDataSent;
    MyClient.FtpServer       := Self; {AG V7.02 }
{$IFNDEF NO_DEBUG_LOG}
    MyClient.IcsLogger       := IcsLogger;                     { V1.46 }
    MyClient.DataSocket.IcsLogger := IcsLogger;                    //<= 01/01/06 AG
{$ENDIF}
{$IFDEF USE_SSL}
    if Self is TSslFtpServerW then begin     {  V1.48 }
        if MultiListenIndex = -1 then
          MyClient.FtpSslTypes := TSslFtpserverW(Self).FFtpSslTypes
        else
          MyClient.FtpSslTypes := TSslFtpWSocketMultiListenItem(MultiListenSockets[MultiListenIndex]).FFtpSslTypes;
        if ftpImplicitSsl in MyClient.FtpSslTypes then   { V1.47 }
            MyClient.CurFtpSslType := curftpImplicitSsl;               { V1.47 }

       { V8.64 see if LOGIN only allowed after SSL/TLS negotiated }
        if ftpsAuthForceSsl in FOptions then
            MyClient.Options := MyClient.Options + [ftpAuthForceSsl];  { V8.64 }
        if TSslFtpserverW(Self).GetIcsHosts <> Nil then begin
             if (TSslFtpserverW(Self).GetIcsHosts.Count > 0) and
                                            (MyClient.FIcsHostIdx >= 0) then begin       { V8.64 }
                if TSslFtpserverW(Self).GetIcsHosts[MyClient.FIcsHostIdx].AuthForceSsl then
                    MyClient.Options := MyClient.Options + [ftpAuthForceSsl];
             end;
         end;
    end;
{$ENDIF}
    if ftpsCdupHome in FOptions then
        MyClient.Options := MyClient.Options + [ftpCdupHome];   { angus V1.39 }
    if ftpsCwdCheck in FOptions then
        MyClient.Options := MyClient.Options + [ftpCwdCheck];   { angus V1.39 }
    if ftpsHidePhysicalPath in FOptions then
        MyClient.Options := MyClient.Options + [ftpHidePhysicalPath]; { AG V1.52 }
    if ftpsModeZCompress in FOptions then
        MyClient.Options := MyClient.Options + [ftpModeZCompress];
    MyClient.CodePage        := FCodePage;           { AG V7.02 }
    MyClient.CurrentCodePage := FCodePage;           { AG V7.02 }
    if (ftpsEnableUtf8 in FOptions) and (ftpsDefaultUtf8On in FOptions) then
        MyClient.Options := MyClient.Options + [ftpUtf8On]     { angus V7.01 }
    else if (ftpsEnableUtf8 in FOptions) and (ftpsAutoDetectCodepage in FOptions) then
        MyClient.FOptions := MyClient.Options + [ftpAutoDetectCodepage]; { AG V7.02 }

{$IFNDEF NO_DEBUG_LOG}                                       { V1.46 }
    if CheckLogOptions(loProtSpecDump) then
        DebugLog(loProtSpecDump,  IntToHex(INT_PTR(MyClient), SizeOf(Pointer) * 2) +
                 ' Client Connect Error - ' + GetWinsockErr(Error) + ' ' +
                  IntToStr(MyClient.HSocket));
{$ENDIF}
    { angus V1.54 may be changed during event, V7.09 add client numeric id to identify separate sessions from same IP }
    MyClient.SessIdInfo      := Client.GetPeerAddr + ' [' + IntToStr (Client.CliId) + ']' ;
    MyClient.CurrTransMode   := FtpTransModeStream ; { angus V1.54 current zlib transfer mode }
    MyClient.ZReqLevel       := FZlibMinLevel;       { angus V1.54 initial compression level, minimum }
    MyClient.FConnectedSince := Now;
    MyClient.FLastCommand    := 0;
    MyClient.FCommandCount   := 0;
    MyClient.FFtpState       := ftpcWaitingUserCode;
    MyClient.FileModeRead    := SrvFileModeRead;     { angus V1.57 }
    MyClient.FileModeWrite   := SrvFileModeWrite;    { angus V1.57 }
    MyClient.ExclusiveAddr   := FExclusiveAddr;      { V8.37 }
    MyClient.SocketErrs      := FSocketErrs;         { V8.37 }
{$IFDEF BUILTIN_THROTTLE}
    MyClient.CBandwidthLimit    := fBandwidthLimit;     { angus V7.12 may be changed in event for different limit }
    MyClient.CBandwidthSampling := fBandwidthSampling;  { angus V7.12 }
{$ENDIF}
    TriggerClientConnect(MyClient, Error);
{$IFDEF BUILTIN_THROTTLE}
    MyClient.BandwidthLimit     := MyClient.CBandwidthLimit;     { angus V7.12 slow down control connection }
    MyClient.BandwidthSampling  := MyClient.CBandwidthSampling;  { angus V7.12 }
{$ENDIF}
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.SendAnswer(Client : TFtpCtrlSocketW; Answer : TFtpString);
var
    RawAnswer: RawByteString;
begin
    try
        { Angus 7.03 fixed trigger needed before UTF8 conversion }
         Client.ReqDurMilliSecs := IcsElapsedMsecs (Client.ReqStartTick);
         TriggerSendAnswer(Client, Answer);
        RawAnswer := UnicodeToAnsi(Answer, Client.CurrentCodePage);
// angus removed ANSI code for old compilers to support Unicode
        Client.SendAnswer(RawAnswer);
    except
        { Just ignore any exception here }
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.ClientCommand(
    Sender : TObject;
    CmdBuf : PAnsiChar;
    CmdLen : Integer);
const
    TELNET_IAC       = #255;
    TELNET_IP        = #244;
    TELNET_DATA_MARK = #242;
var
    Client  : TFtpCtrlSocketW;
    Answer  : TFtpString;
    Params  : TFtpString;
    KeyWord : TFtpString;
    I       : Integer;
    RawParams: RawByteString;
begin
    Client := Sender as TFtpCtrlSocketW;
    Answer := '';

    { Copy the command received, removing any telnet option }
    try
        Client.ReqStartTick := IcsGetTickCountX;    { angus V1.54 tick when request started }
        Client.ReqDurMilliSecs := 0;                { angus V1.54 how long last request took, in ticks }
        RawParams := '';
        I      := 0;
        while I < CmdLen do begin
            if CmdBuf[I] <> TELNET_IAC then begin
                RawParams := RawParams + CmdBuf[I];
                Inc(I);
            end
            else begin
                Inc(I);
                if CmdBuf[I] = TELNET_IAC then
                    RawParams := RawParams + CmdBuf[I];
                Inc(I);
            end;
        end;
        { AG V7.02 - Optionally detect UTF-8. Set option ftpUtf8ON which }
        { in turn sets CurrentCodePage to CP_UTF8 if UTF-8 is detected.  }
        if (Client.CurrentCodePage <> CP_UTF8) and
           (ftpAutoDetectCodepage in Client.Options) and
           (CharsetDetect(RawParams) = cdrUtf8) then
            Client.Options := Client.Options + [ftpUtf8ON];  { AG V7.02  }
        { Convert buffer data to UnicodeString AG V7.02 }
        Params := AnsiToUnicode(RawParams, Client.CurrentCodePage);
// angus removed ANSI code for old compilers to support Unicode

        { Extract keyword, ignoring leading spaces and tabs }
        I := 1; { angus V1.54 moved argument parsing code to FtpSrvT to avoid duplication }
        KeyWord := IcsAnsiUpperCaseW(IcsScanGetAsciiArg (Params, I));
        if KeyWord = 'SITE' then begin  { angus 1.54 special case for two word command }
            KeyWord := 'SITE ' + IcsAnsiUpperCaseW(IcsScanGetAsciiArg (Params, I));
        end ;
        IcsScanFindArg (Params, I);

        { Extract parameters, ignoring leading spaces and tabs }
        Params := Copy(Params, I, Length(Params));

        { Pass the command to the component user to let him a chance to }
        { handle it. If it does, he must return the answer.             }
        TriggerClientCommand(Client, Keyword, Params, Answer);
        if Answer <> '' then begin
            { Event handler has processed the client command, send the answer }
            SendAnswer(Client, Answer);
            Exit;
        end;

        { The command has not been processed, we'll process it }
        if Keyword = '' then begin
            { Empty keyword (should never occurs) }
            SendAnswer(Client, WideFormat(msgCmdUnknown, [Params]));
            Exit;
        end;

        { We need to process the client command, search our command table }
        I := 0;
        while I <= High(FCmdTable) do begin
            if FCmdTable[I].KeyWord = KeyWord then begin
                if I <> ftpcABOR then   { AG V8.02 }
                    Client.CurCmdType := I;             { angus V1.54 }
                Client.AnswerDelayed := FALSE; { AG V1.50 }
                FCmdTable[I].Proc(Client, KeyWord, Params, Answer);
                if not Client.AnswerDelayed then  { AG V1.50 }
                            SendAnswer(Client, Answer);
                Exit;
            end;
            Inc(I);
        end;
        SendAnswer(Client, WideFormat(msgCmdUnknown, [KeyWord]));
    except
        on E:Exception do begin
            SendAnswer(Client, '501 ' + E.Message);
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.ClientDataSent(Sender : TObject; AError  : Word);
var
    Client  : TFtpCtrlSocketW;
begin
    Client := Sender as TFtpCtrlSocketW;
    if Client.CloseRequest then begin
//        Client.CloseRequest := FALSE;
        PostMessage(Handle, FMsg_WM_FTPSRV_CLOSE_REQUEST,
                    WPARAM(Client.ID), LPARAM(Client));
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.ServerClientDisconnect(Sender: TObject;
                                Client: TWSocketClient; Error: Word); { angus V7.00 }
var
    MyClient: TFtpCtrlSocketW;
begin
    try
        MyClient := Client as TFtpCtrlSocketW;
      { close data channel if still open }
        if MyClient.DataSocket.State = wsConnected then begin
            MyClient.TransferError    := 'ABORT on Disconnect';
            MyClient.AbortingTransfer := TRUE;
            MyClient.DataSocket.Close;
        end;
        CloseFileStreams(MyClient);      { angus V1.57 }
        TriggerClientDisconnect(MyClient, Error);
    except
        { Just ignore any exception here }
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.WMFtpSrvAbortTransfer(var msg: TMessage);
var
    Client : TFtpCtrlSocketW;
    Data   : TWSocket;
begin
    Client := TFtpCtrlSocketW(Msg.LParam);
    { Check if client still in our client list }
    if FSocketServer.IsClient(Client) then begin
        { Check if client.ID is still the same as when message where posted }
        if WPARAM(Client.ID) = Msg.WParam then begin
            Data := Client.DataSocket;
            { make sure to free PasvPort even on aborted connections ! }
            if Assigned(Data) then begin
                if Client.PassiveMode then // FLD 29.12.05
                    FreeCurrentPasvPort(Client);

                Data.ShutDown(2);
                Data.Close;
            end;
            CloseFileStreams(Client);      { angus V1.57 }
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.WMFtpSrvCloseData(var msg: TMessage);
var
    Client : TFtpCtrlSocketW;
    Data   : TWSocket;
{ !!!!!!!!!!! NGB: next line changed }
    {PortNumber : String;}
{ !!!!!!!!!!! NGB: previous line changed }
begin
    Client := TFtpCtrlSocketW(Msg.LParam);
    { Check if client still in our client list }
    if FSocketServer.IsClient(Client) then begin
        { Check if client.ID is still the same as when message where posted }
        if WPARAM(Client.ID) = Msg.WParam then begin
            Data := Client.DataSocket;
{ !!!!!!!!!!! NGB: Free Up Current Port - next 5 lines changed }
            if Assigned(Data) then begin
                if Client.PassiveMode then // FLD 29.12.05
                    FreeCurrentPasvPort(Client);
                Data.ShutDown(1);    {  Wilfried 24/02/04 }
            end;
{ !!!!!!!!!!! NGB: previous 5 lines changed }
            CloseFileStreams(Client);      { angus V1.57 }
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TFtpServerW.GetClient(nIndex : Integer) : TFtpCtrlSocketW;
begin
    Result := FSocketServer.Client [nIndex] as TFtpCtrlSocketW;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ Check  if a given object is one of our clients }
function TFtpServerW.IsClient(SomeThing : TObject) : Boolean;
begin
    Result := FSocketServer.IsClient(Something);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TFtpServerW.GetClientCount : Integer;
begin
    Result := FSocketServer.ClientCount;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerServerStart;
begin
    if Assigned(FOnStart) then
        FOnStart(Self);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerServerStop;
begin
    if Assigned(FOnStop) then
        FOnStop(Self);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerAuthenticate(
    Client            : TFtpCtrlSocketW;
    UserName          : TFtpString;
    PassWord          : TFtpString;
    var Authenticated : Boolean);
begin
    if Assigned(FOnAuthenticate) then
        FOnAuthenticate(Self, Client, UserName, Password, Authenticated);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerOtpMethod(           { angus V1.54 }
    Client          : TFtpCtrlSocketW;
    UserName        : TFtpString;
    var OtpMethod   : TOtpMethod);
begin
    if Assigned(FOnOtpMethod) then
        FOnOtpMethod(Self, Client, UserName, OtpMethod);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerOtpGetPassword(      { angus V1.54 }
    Client           : TFtpCtrlSocketW;
    UserName         : TFtpString;
    var UserPassword : TFtpString);
begin
    if Assigned(FOnOtpGetPassword) then
        FOnOtpGetPassword(Self, Client, UserName, UserPassword);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerChangeDirectory(
    Client         : TFtpCtrlSocketW;
    Directory      : TFtpString;
    var Allowed    : Boolean);
begin
    if Assigned(FOnChangeDirectory) then
        FOnChangeDirectory(Self, Client, Directory, Allowed);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerMakeDirectory(
    Client         : TFtpCtrlSocketW;
    Directory      : TFtpString;
    var Allowed    : Boolean);
begin
    if Assigned(FOnMakeDirectory) then
        FOnMakeDirectory(Self, Client, Directory, Allowed);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerBuildDirectory(
    Client        : TFtpCtrlSocketW;
    var Params    : TFtpString;
    Detailed      : Boolean);
begin
    if Assigned(FOnBuildDirectory) then
        FOnBuildDirectory(Self, Client, Params, Detailed);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerAlterDirectory(
    Client        : TFtpCtrlSocketW;
    var Params    : TFtpString;
    Detailed      : Boolean);
begin
    if Assigned(FOnAlterDirectory) then
        FOnAlterDirectory(Self, Client, Params, Detailed);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerSendAnswer(
    Client     : TFtpCtrlSocketW;
    var Answer : TFtpString);
begin
    if Assigned(FOnAnswerToClient) then
        FOnAnswerToClient(Self, Client, Answer);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerClientDisconnect(Client : TFtpCtrlSocketW; AError  : Word);
begin
    if Assigned(FOnClientDisconnect) then
        FOnClientDisconnect(Self, Client, AError);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerClientConnect(Client : TFtpCtrlSocketW; AError  : Word);
begin
    if Assigned(FOnClientConnect) then
        FOnClientConnect(Self, Client, AError);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerStorSessionConnected(
    Client : TFtpCtrlSocketW; Data : TWSocket; AError  : Word);
begin
    if Assigned(FOnStorSessionConnected) then
        FOnStorSessionConnected(Self, Client, Data, AError);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerRetrSessionConnected(
    Client : TFtpCtrlSocketW; Data : TWSocket; AError  : Word);
begin
    if Assigned(FOnRetrSessionConnected) then
        FOnRetrSessionConnected(Self, Client, Data, AError);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerStorSessionClosed(
    Client : TFtpCtrlSocketW; Data : TWSocket; AError  : Word);
begin
    if Assigned(FOnStorSessionClosed) then
        FOnStorSessionClosed(Self, Client, Data, AError);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerRetrSessionClosed(
    Client : TFtpCtrlSocketW; Data : TWSocket; AError  : Word);
begin
    if Assigned(FOnRetrSessionClosed) then
        FOnRetrSessionClosed(Self, Client, Data, AError);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerClientCommand(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
begin
    if Assigned(FOnClientCommand) then
        FOnClientCommand(Self, Client, KeyWord, Params, Answer);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerValidatePut(
    Client        : TFtpCtrlSocketW;
    var FilePath  : TFtpString;
    var Allowed   : Boolean);
begin
    if Assigned(FOnValidatePut) then
        FOnValidatePut(Self, Client, FilePath, Allowed);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerValidateSize(
    Client        : TFtpCtrlSocketW;
    var FilePath  : TFtpString;
    var Allowed   : Boolean);
begin
    if Assigned(FOnValidateSize) then
        FOnValidateSize(Self, Client, FilePath, Allowed);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerValidateDele(
    Client        : TFtpCtrlSocketW;
    var FilePath  : TFtpString;
    var Allowed   : Boolean);
begin
    if Assigned(FOnValidateDele) then
        FOnValidateDele(Self, Client, FilePath, Allowed);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerValidateRmd(
    Client        : TFtpCtrlSocketW;
    var FilePath  : TFtpString;
    var Allowed   : Boolean);
begin
    if Assigned(FOnValidateRmd) then
        FOnValidateRmd(Self, Client, FilePath, Allowed);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerValidateRnFr(
    Client        : TFtpCtrlSocketW;
    var FilePath  : TFtpString;
    var Allowed   : Boolean);
begin
    if Assigned(FOnValidateRnFr) then
        FOnValidateRnFr(Self, Client, FilePath, Allowed);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerValidateRnTo(
    Client        : TFtpCtrlSocketW;
    var FilePath  : TFtpString;
    var Allowed   : Boolean);
begin
    if Assigned(FOnValidateRnTo) then
        FOnValidateRnTo(Self, Client, FilePath, Allowed);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerValidateGet(
    Client        : TFtpCtrlSocketW;
    var FilePath  : TFtpString;
    var Allowed   : Boolean);
begin
    if Assigned(FOnValidateGet) then
        FOnValidateGet(Self, Client, FilePath, Allowed);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerStorDataAvailable(
    Client : TFtpCtrlSocketW;
    Data   : TWSocket;
    Buf    : PAnsiChar; { AG V6.02 }
    Len    : LongInt;
    AError : Word);
begin
    if Assigned(FOnStorDataAvailable) then
        FOnStorDataAvailable(Self, Client, Data, Buf, Len, AError);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerRetrDataSent(
    Client : TFtpCtrlSocketW;
    Data   : TWSocket;
    AError : Word);
begin
    if Assigned(FOnRetrDataSent) then
        FOnRetrDataSent(Self, Client, Data, AError);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerGetUniqueFileName(
    Client       : TFtpCtrlSocketW;
    var FileName : TFtpString);
begin
    if Assigned (FOnGetUniqueFileName) then
        FOnGetUniqueFileName (Self, Client, FileName);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerValidateMfmt(  { angus V1.39 }
    Client        : TFtpCtrlSocketW;
    var FilePath  : TFtpString;
    var Allowed   : Boolean);
begin
    if Assigned (FOnValidateMfmt) then
        FOnValidateMfmt (Self, Client, FilePath, Allowed);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerCalculateMd5(
    Client        : TFtpCtrlSocketW;
    var FilePath  : TFtpString;
    var Md5Sum    : TFtpString;
    var Allowed   : Boolean);
begin
    if Assigned(FOnCalculateMd5) then
        FOnCalculateMd5(Self, Client, FilePath, Md5Sum, Allowed);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerMd5Calculated(Client: TFtpCtrlSocketW; { AG V1.50 }
  const FilePath, Md5Sum: TFtpString);
begin
    if Assigned(FOnMd5Calculated) then
        FOnMd5Calculated(Self, Client, FilePath, Md5Sum);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerCalculateCrc(                           { angus V1.54 }
    Client        : TFtpCtrlSocketW;
    var FilePath  : TFtpString;
    var Md5Sum    : TFtpString;
    var Allowed   : Boolean);
begin
    if Assigned(FOnCalculateCrc) then
        FOnCalculateCrc(Self, Client, FilePath, Md5Sum, Allowed);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerCrcCalculated(Client: TFtpCtrlSocketW;  { angus V1.54 }
  const FilePath, Md5Sum: TFtpString);
begin
    if Assigned(FOnCrcCalculated) then
        FOnCrcCalculated(Self, Client, FilePath, Md5Sum);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerEnterSecurityContext(                  { AG V1.52 }
    Client : TFtpCtrlSocketW);
begin
    if Assigned(FOnEnterSecurityContext) then
        FOnEnterSecurityContext(Self, Client);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerLeaveSecurityContext(                  { AG V1.52 }
    Client : TFtpCtrlSocketW);
begin
    if Assigned(FOnLeaveSecurityContext) then
        FOnLeaveSecurityContext(Self, Client);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerValidateAllo(                          { angus V1.54 }
    Client      : TFtpCtrlSocketW;
    var Params  : TFtpString;
    var Answer  : TFtpString);
begin
    if Assigned(FOnValidateAllo) then
        FOnValidateAllo(Self, Client, Params, Answer);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerClntStr (                            { angus V1.54 }
    Client      : TFtpCtrlSocketW;
    var Params  : TFtpString;
    var Answer  : TFtpString);
begin
    if Assigned(FOnClntStr) then
        FOnClntStr(Self, Client, Params, Answer);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerSiteMsg (                            { angus V1.54 }
    Client      : TFtpCtrlSocketW;
    var Params  : TFtpString;
    var Answer  : TFtpString);
begin
    if Assigned(FOnSiteMsg ) then
        FOnSiteMsg (Self, Client, Params, Answer);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerSiteExec (                            { angus V1.54 }
    Client      : TFtpCtrlSocketW;
    var Params  : TFtpString;
    var Answer  : TFtpString);
begin
    if Assigned(FOnSiteExec) then
        FOnSiteExec(Self, Client, Params, Answer);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerSitePaswd (                            { angus V1.54 }
    Client      : TFtpCtrlSocketW;
    var Params  : TFtpString;
    var Answer  : TFtpString);
begin
    if Assigned(FOnSitePaswd) then
        FOnSitePaswd(Self, Client, Params, Answer);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerCombine (                            { angus V1.54 }
    Client      : TFtpCtrlSocketW;
    var Params  : TFtpString;
    var Answer  : TFtpString);
begin
    if Assigned(FOnCombine) then
        FOnCombine(Self, Client, Params, Answer);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerTimeout(
    Client      : TFtpCtrlSocketW;            { angus V1.54 }
    Duration    : Integer;
    var Abort   : Boolean);
begin
    if Assigned(FOnTimeout) then
        FOnTimeout(Self, Client, Duration, Abort);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerDownCompressFile(
    Client    : TFtpCtrlSocketW;          { angus V1.54 }
    var Done  : Boolean);
begin
    if Assigned(FOnDownCompressFile) then
        FOnDownCompressFile(Self, Client, Done);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerUpCompressFile(
    Client    : TFtpCtrlSocketW;            { angus V1.54 }
    var Done  : Boolean);
begin
    if Assigned(FOnUpCompressFile) then
        FOnUpCompressFile(Self, Client, Done);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerUpCompressedFile(
      Client  : TFtpCtrlSocketW);   { angus V1.54 }
begin
    if Assigned(FOnUpCompressedFile) then
        FOnUpCompressedFile(Self, Client);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerDisplay(
       Client      : TFtpCtrlSocketW;
       Msg         : TFtpString);  { angus V1.54 }
begin
    if Assigned(FOnDisplay) then
        FOnDisplay(Self, Client, Msg);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerHost(
    Client        : TFtpCtrlSocketW;
    Host          : TFtpString;
    var Allowed   : Boolean);      { angus V7.01 }
begin
    if Assigned(FOnHost) then
        FOnHost(Self, Client, Host, Allowed);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerRein(
    Client        : TFtpCtrlSocketW;
    var Allowed   : Boolean);      { angus V7.01 }
begin
    if Assigned(FOnRein) then
        FOnRein(Self, Client, Allowed);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerLang(
    Client        : TFtpCtrlSocketW;
    Lang          : TFtpString;
    var Allowed   : Boolean);      { angus V7.01 }
begin
    if Assigned(FOnLang) then
        FOnLang(Self, Client, Lang, Allowed);     { angus V7.08 }
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerAddVirtFiles(     { angus V7.08 }
    Client          : TFtpCtrlSocketW;
    var LocFiles    : TIcsFileRecsW;
    var LocFileList : TList;
    var TotalFiles  : Integer;
    ProgressCallback: TMD5Progress);
begin
    if Assigned(FOnAddVirtFiles) then
        FOnAddVirtFiles(Self, Client, LocFiles, LocFileList, TotalFiles, ProgressCallback);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandUSER(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
var
    Challenge: string;
begin
    Client.CurCmdType := ftpcUSER;

{$IFDEF USE_SSL}
    { V8.64 check if login only allowed with SSL/TLS }
    if Self is TSslFtpServerW then begin
        if (ftpAuthForceSsl in Client.Options) and
                 (Client.SslState <> sslEstablished) then begin
            Answer := WideFormat(msgErrInSslOnly, ['USER']);
            Exit;
        end;
    end;
{$ENDIF}

    Client.UserName   := Trim(Params);
    Client.FtpState   := ftpcWaitingPassword;
  { angus V1.54 - check if user account is set-up for authentication using a
    one time password. If so, OtpMethod is changed to the method and
    Client.OtpSequence and Client.OtpSeed set to the last values saved for
    the account, or OtpSequence set to -1 to generate a new seed }
    TriggerOtpMethod(Client, Client.UserName, Client.OtpMethod);
    if Client.OtpMethod = OtpKeyNone then
        Answer := WideFormat(msgPassRequired, [Client.UserName])
    else begin
        Challenge := OtpCreateChallenge(Client.OtpMethod,
                                        Client.OtpSequence, Client.OtpSeed);
        Answer := WideFormat(msgOptRespRequired, [Challenge, Client.UserName])
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandPASS(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
var
    Authenticated : Boolean;
    UserPassword : TFtpString ;
    Secs: Integer ;
begin
    if Client.FtpState <> ftpcWaitingPassword then
        Answer := msgNoUser
    else begin
        Client.CurCmdType    := ftpcPASS;
        Client.PassWord      := Trim(Params);
        Authenticated        := TRUE;
     {  angus V1.54 - if authenticating using a one time password, we need to get
       the user account password so that it can tested against the hashed OTP
       password created by the client from the sequence and seed sent in the challenge.
       Note the TriggerAuthenticate event is still called but with Authenticated set
       false if the OTP password failed, allowing the client to check for a clear
       password if required, or log the failure.  If OTP is successful, the new
       Client.OtpSequence should be saved in the user account details }
        if Client.OtpMethod > OtpKeyNone then begin
            UserPassword := '' ;
            TriggerOtpGetPassword(Client, Client.UserName, UserPassword);
            Authenticated := OtpTestPassword(Client.PassWord, UserPassword,
                            Client.OtpMethod, Client.OtpSequence, Client.OtpSeed);
        end;
        TriggerAuthenticate(Client, Client.UserName, Client.PassWord, Authenticated);
        if Authenticated then begin
            Client.FtpState  := ftpcReady;
            Client.Directory := Client.HomeDir;
            Answer           := WideFormat(msgLogged, [Client.UserName])
        end
        else begin
            {angus V7.06 - count failed login attempts, after third MaxAttempts
              delay answer to slow down extra attempts, finally close client
              once MaxAttempts reached (done in EventTimer event) }
            inc (Client.FailedAttempts) ;
            if Client.FailedAttempts > (FMaxAttempts div 3) then begin
                Secs := (Client.FailedAttempts * 2);
                if (Secs > FTimeoutSecsLogin) then Secs := FTimeoutSecsLogin;
                Client.DelayAnswerTick := IcsGetTrgSecs (Secs);
                Client.FtpState        := ftpcFailedAuth;
                Client.AnswerDelayed   := true;
            end
            else begin
                Client.FtpState  := ftpcWaitingUserCode;
                Answer           := msgLoginFailed;
            end;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandCDUP(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;
    Client.CurCmdType := ftpcCDUP;
    Params := '..';
    CommandChangeDir(Client, Keyword, Params, Answer);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandCWD(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;
    Client.CurCmdType    := ftpcCWD;
    CommandChangeDir(Client, Keyword, Params, Answer);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandChangeDir(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
var
    Allowed : Boolean;
    OldDir  : TFtpString;
    DExists : Boolean;
begin
    OldDir := Client.Directory;
    try
        Params := IcsSlashesToBackSlashesW(Params);
        Client.Directory := Trim(Params);
        Allowed := IsPathAllowed(Client, Client.Directory);  { V1.52 AG }
        { should this event be before the ftpsCdupHome test??? }
        TriggerChangeDirectory(Client, Client.Directory, Allowed);
        if Allowed then begin
            TriggerEnterSecurityContext(Client);             { V1.52 AG }
            try
                DExists := IcsDirExistsW(BuildFilePath(Client, Client.Directory, '')); { angus V7.08 support virtual path }
            finally
                TriggerLeaveSecurityContext(Client);         { V1.52 AG }
            end;
            { angus V1.38 make sure windows path exists }
            if (not (ftpCwdCheck in Client.Options)) or DExists or
                    (DExists and (Length(Client.Directory) <= 3)) or  { angus V1.39 }
                    (IcsAnsiLowerCaseW(Client.HomeDir) = IcsAnsiLowerCaseW(Client.Directory)) then { angus V1.42 }
                Answer := WideFormat(msgCWDSuccess, [FormatResponsePath(Client, Client.Directory)])
            else begin
                Answer := WideFormat(msgCWDNoDir, [FormatResponsePath(Client, Client.Directory)]);   { angus V1.38 }
                Client.Directory := OldDir;        { angus V1.38 }
            end;
        end
        else begin
            Client.Directory := OldDir;
            Answer           := WideFormat(msgCWDFailed, ['No permission']);
        end;
    except
        on E:Exception do begin
            Client.Directory := OldDir;
            Answer           := WideFormat(msgCWDFailed, [E.Message]);
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandXPWD(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;

    Client.CurCmdType := ftpcXPWD;
    Answer := WideFormat(msgPWDSuccess,
                   [FormatResponsePath(Client, Client.Directory)]);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandPWD(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;

    Client.CurCmdType := ftpcPWD;
    Answer := WideFormat(msgPWDSuccess,
                   [FormatResponsePath(Client, Client.Directory)]); { AG V1.52 }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandQUIT(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
begin
    Client.CurCmdType := ftpcQUIT;
    Answer            := msgQuit;
    PostMessage(Handle, FMsg_WM_FTPSRV_CLOSE_REQUEST,
                WPARAM(Client.ID), LPARAM(Client));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function GetInteger(var I : Integer; const Src : TFtpString) : LongInt;
begin
    { Skip leading white spaces }
    while (I <= Length(Src)) and IsSpace(Src[I]) do
        Inc(I);
    Result := 0;
    while (I <= Length(Src)) and IsDigit(Src[I]) do begin    { V6.03 }
        Result := Result * 10 + Ord(Src[I]) - Ord('0');
        Inc(I);
    end;
    { Skip trailing white spaces }
    while (I <= Length(Src)) and IsSpace(Src[I]) do
        Inc(I);
    { Check if end of string of comma. If not, error, returns -1 }
    if I <= Length(Src) then begin
        if Src[I] = ',' then
            Inc(I)        { skip comma           }
        else
            raise FtpServerException.Create('GetInteger: unexpected char'); { error, must be comma }
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandPORT(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
var
    I : Integer;
    N : LongInt;
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;
    if Client.FEpsvAllArgReceived then begin             { IPv6 }
        Answer := Format(msgEPSVALLDeny, [Keyword]);
        Exit;
    end;
    try
        Client.CurCmdType := ftpcPORT;
        I                 := 1;
        Client.DataAddr   := IntToStr(GetInteger(I, Params));
        Client.DataAddr   := Client.DataAddr + '.' + IntToStr(GetInteger(I, Params));
        Client.DataAddr   := Client.DataAddr + '.' + IntToStr(GetInteger(I, Params));
        Client.DataAddr   := Client.DataAddr + '.' + IntToStr(GetInteger(I, Params));
        N := GetInteger(I, Params);
        N := (N shl 8) + GetInteger(I, Params);
        Client.DataPort := IcsIntToStrA(N);
        Answer := msgPortSuccess;
    except
        Answer := msgPortFailed;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandSTOR(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
var
    Allowed  : Boolean;
    FilePath : TFtpString;
begin
    try
        if Client.FtpState <> ftpcReady then begin
            Answer := msgNotLogged;
            Exit;
        end;
        if Params = '' then begin                                { V1.52 AG }
            Answer := WideFormat(msgStorFailed, ['File name not specified']);
            Exit;
        end;
        try
            Client.CurCmdType       := ftpcSTOR;
            Client.FileName         := IcsSlashesToBackSlashesW(Params);
            Client.HasOpenedFile    := FALSE;
            FilePath                := BuildFilePath(Client, Client.Directory, Client.FileName);
            Allowed := IsPathAllowed(Client, FilePath); { AG V1.52 }
            TriggerValidatePut(Client, FilePath, Allowed);
            if not Allowed then begin
                Answer := msgStorDisabled;
                Exit;
            end;
            Client.FilePath := FilePath;
            PrepareStorDataSocket(Client);
            Answer := WideFormat(msgStorSuccess, [Params]);
        except
            on E:Exception do begin
                Answer := WideFormat(msgStorFailed, [E.Message]);
            end;
        end;
    finally
        { check for success 150..159 in passive mode              }
        if Client.PassiveMode and (Copy(Answer, 1, 2) <> '15') then begin
            { flag for ClientStorSessionClosed that the error-message was already sent! }
            Client.TransferError    := '';
            Client.AbortingTransfer := TRUE;
            { set up Passive DataSocket.EventHandlers }
            { otherwise FreeCurrentPasvPort won't be called ! }
            PreparePassiveStorDataSocket(Client);
        end;
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ New setup fuction for all STOR-based connections                            }
{ Performes the same task as StartSendData for RETR-based connections         }
procedure TFtpServerW.PrepareStorDataSocket(Client : TFtpCtrlSocketW);
begin
    Client.AbortingTransfer := FALSE;
    Client.TransferError    := 'Transfer Ok';
    Client.DataSocket.ExclusiveAddr := FExclusiveAddr;      { V8.37 }
    Client.DataSocket.SocketErrs    := FSocketErrs;         { V8.37 }

    if Client.PassiveMode then begin
        PreparePassiveStorDataSocket(Client);
    end
    else begin
        Client.DataSocket.Proto               := 'tcp';
        Client.DataSocket.Addr                := Client.DataAddr;
        Client.DataSocket.Port                := Client.DataPort;
        Client.DataSocket.OnSessionConnected  := ClientStorSessionConnected;
        Client.DataSocket.OnSessionClosed     := ClientStorSessionClosed;
        Client.DataSocket.OnDataAvailable     := ClientStorDataAvailable;
        Client.DataSocket.OnDataSent          := nil;
        Client.DataSocket.LingerOnOff         := wsLingerOff;
        Client.DataSocket.LingerTimeout       := 0;
        if FBindFtpData then begin                                    { IPv6 }
            Client.DataSocket.LocalAddr       := Client.GetXAddr;
            Client.DataSocket.LocalPort       := 'ftp-data'; {20}
        end;
        Client.DataSocket.ComponentOptions    := [wsoNoReceiveLoop];
{$IFDEF BUILTIN_THROTTLE}
        Client.DataSocket.BandwidthLimit      := Client.CBandwidthLimit;     { angus V7.12 }
        Client.DataSocket.BandwidthSampling   := Client.CBandwidthSampling;  { angus V7.12 }
{$ENDIF}
        Client.DataSocket.Connect;
        if Client.DataSocket.SocketRcvBufSize <> Client.FRcvBufSize then     { angus  V7.19 }
           Client.DataSocket.SocketRcvBufSize := Client.FRcvBufSize;         { angus  V7.19 }
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ New setup fuction for all Passive STOR-based data connections               }
procedure TFtpServerW.PreparePassiveStorDataSocket(Client : TFtpCtrlSocketW);
begin
    Client.DataSocket.OnSessionConnected  := ClientStorSessionConnected;
    Client.DataSocket.OnSessionClosed     := ClientStorSessionClosed;
    Client.DataSocket.OnDataAvailable     := ClientStorDataAvailable;
    Client.DataSocket.OnDataSent          := nil;
    if Client.PassiveConnected then
        Client.DataSocket.OnSessionConnected(Client.DataSocket, 0)
    else
        Client.PassiveStart := TRUE;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.ClientStorSessionConnected(Sender : TObject; AError  : Word);
var
    Client      : TFtpCtrlSocketW;
    Data        : TWSocket;
begin
    Data                     := TWSocket(Sender);
    Client                   := TFtpCtrlSocketW(Data.Owner);
    Client.DataSessionActive := TRUE;
    Client.ByteCount := 0;
    Client.XferStartTick := IcsGetTickCountX; { angus V1.54 tick when last xfer started, for performance check }
    Client.LastTick := IcsGetTickCountX;      { angus V1.54 last tick for time out checking }
    Client.ZStreamState := ftpZStateNone;

    if Client.AbortingTransfer then
        Exit; // primary command (e.g. STOR) failed - don't trigger StorSessionConnected
    TriggerStorSessionConnected(Client, Data, AError);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.ClientStorSessionClosed(Sender : TObject; AError  : Word);
var
    Client      : TFtpCtrlSocketW;
    Data        : TWSocket;
    Md5Sum      : String;  { AG V1.50 }
    Duration    : Integer;
    S           : TFtpString;
    BytesSec    : Int64;
    Answer      : TFtpString;
begin
    Data                     := TWSocket(Sender);
    Client                   := TFtpCtrlSocketW(Data.Owner);
{ !!!!!!!! NGB: Free Up Current Port - next 2 lines added }
    if Client.PassiveMode then // FLD 29.12.05
        FreeCurrentPasvPort(Client);
{ !!!!!!!! NGB: previous 2 lines added }

    Client.DataSessionActive := FALSE;
    Client.PassiveStart      := FALSE;
    Client.PassiveConnected  := FALSE;
    Client.RestartPos        := 0;
    { Reset data port to standard value }
    Client.DataPort          := 'ftp-data';

{ angus V1.54 report performance }
    if Assigned(FOnDisplay) then begin
        Duration := IcsElapsedMsecs (Client.XferStartTick);
        S := Client.FilePath + ' ' +
                IntToKbyte(Client.ByteCount) + 'bytes received in ';
        if Duration < 2000 then
            S := S + IntToStr(Duration) + ' milliseconds'
        else begin
            S := S + IntToStr(Duration div 1000) + ' seconds';
            if Client.ByteCount > 32767 then
                BytesSec := 1000 * (Client.ByteCount div Duration)
            else
                BytesSec := (1000 * Client.ByteCount) div Duration;
            S := S + ' (' + IntToKbyte(BytesSec) + 'bytes/sec)';
        end;
        TriggerDisplay (Client, S);
    end;

    if Client.AbortingTransfer and (Client.TransferError = '') then
        Exit; { This happens when the Command itself was failed - do not      }
              { reply on command channel and don't trigger StorSessionClosed! }

    Answer := '';  { angus V1.54 don't send answer yet }
    case Client.CurCmdType of
    ftpcSTOR :
        begin
            if Client.AbortingTransfer then
                Answer := WideFormat(msgStorAborted, [Client.TransferError])
            else if AError = 0 then
                Answer := msgStorOk
            else
                Answer := WideFormat(msgStorError, [GetWinsockErr(AError)]);
        end;
    ftpcAPPE :
        begin
            if Client.AbortingTransfer then
                Answer := WideFormat(msgAppeAborted, [Client.TransferError])
            else if AError = 0 then
                Answer := msgAppeOk
            else
                Answer := WideFormat(msgAppeError, [GetWinsockErr(AError)]);
        end;
    ftpcSTOU :
        begin
            if Client.AbortingTransfer then
                Answer := WideFormat(msgStouAborted, [Client.TransferError])
            else if AError = 0 then
                Answer := WideFormat(msgStouOk, [Client.FileName])
            else
                Answer := WideFormat(msgStouError, [GetWinsockErr(AError)]);
        end;
    else { Should never comes here }
        raise Exception.Create('Program error in ClientStorSessionClosed');
        exit;
    end;

    if (Client.ZStreamState = ftpZStateSaveDecom) and
         (Client.ZFileStream.Size > 0) and Assigned(Client.DataStream) and
                     (NOT Client.AbortingTransfer) and (AError = 0) then begin
        try
            TriggerDisplay(Client, 'Using thread to decompress download file: ' +
                                                             Client.ZCompFileName);
            Client.ProcessingThread := TClientProcessingThreadW.Create(TRUE);
            Client.ProcessingThread.Client := Client;
            Client.ProcessingThread.Sender := Data;
            Client.ProcessingThread.InData := Answer;
            Client.ProcessingThread.Keyword := 'DECOMPRESS';
            Client.ProcessingThread.OnTerminate := ClientProcessingThreadTerminate;
            Client.ProcessingThread.FreeOnTerminate := TRUE;
        {$IFDEF COMPILER14_UP}
            Client.ProcessingThread.Start;
        {$ELSE}
            Client.ProcessingThread.Resume;
        {$ENDIF}
            Client.AnswerDelayed := TRUE;
            exit;
        except
            on E:Exception do begin
                Answer := WideFormat(msgStouError, ['Failed to start decompress - ' + E.Message]);
            end;
        end;
    end;

    { If we had opened a data stream ourself, then close it }
    CloseFileStreams(Client);      { angus V1.54 }

    TriggerStorSessionClosed(Client, Data, AError);

    if Client.MD5OnTheFlyFlag then begin { AG V1.50 }
        MD5Final(Client.MD5Digest, Client.MD5Context);
        Md5Sum := MD5DigestToHex(Client.MD5Digest);     { V7.07 }
        TriggerMd5Calculated(Client, Client.FilePath, IcsAnsiUpperCaseW(Md5Sum));
    end;
    SendAnswer(Client, Answer);  { angus V1.54 }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.ClientStorDataAvailable(Sender: TObject; AError  : word);
var
    Len    : Integer;
    Client : TFtpCtrlSocketW;
    Data   : TWSocket;
    NewPos : TFtpBigInt;
begin
    Data   := TWSocket(Sender);
    Client := TFtpCtrlSocketW(Data.Owner);
    Len    := Data.Receive(Client.RcvBuf, Client.RcvSize);
    if Len <= 0 then
        Exit;

    if Client.AbortingTransfer then
        Exit;
    Client.LastTick := IcsGetTickCountX;  { angus V1.54 last tick for time out checking }

    try
        { Trigger the user event for the received data }
        TriggerStorDataAvailable(Client, Data, Client.RcvBuf, Len, AError);

        { We need to open a datastream if not already done and a FilePath }
        { exists (the component user can have nullified the FilePath      }
        if (not Client.HasOpenedFile) and
                     (Length(Client.FilePath) > 0) and
                           (not Assigned(Client.DataStream)) then begin
            { Store the file size temporarily }
            NewPos := IcsGetFileSizeW(Client.FilePath); { V1.49 }
            { Use different file modes for APPE vs STOR }
            if (Client.CurCmdType = ftpcAPPE) and (NewPos > -1) then begin
                TriggerEnterSecurityContext(Client);  { AG V1.52 }
                try
                    Client.DataStream := OpenFileStream(Client.FilePath,
                                                    Client.FileModeWrite); { angus V1.57 }
                finally
                    TriggerLeaveSecurityContext(Client); { AG V1.52 }
                end;
                { Cached Md5Sum should be deleted } { AG V1.50 }
                if (ftpsCalcMD5OnTheFly in FOptions) then
                    TriggerMd5Calculated(Client, Client.FilePath, '');
            end
            else if (Client.RestartPos > 0) and (NewPos > -1) then begin // check file exists!
                TriggerEnterSecurityContext(Client); { AG V1.52 }
                try
                    Client.DataStream := OpenFileStream(Client.FilePath,
                                                    Client.FileModeWrite); { angus V1.57 }
                finally
                    TriggerLeaveSecurityContext(Client); { AG V1.52 }
                end;
                { Cached Md5Sum should be deleted } { AG V1.50 }
                if (ftpsCalcMD5OnTheFly in FOptions) then
                    TriggerMd5Calculated(Client, Client.FilePath, '');
            end
            else begin
                TriggerEnterSecurityContext(Client); { AG V1.52 }
                try
                    Client.DataStream := OpenFileStream(Client.FilePath, fmCreate);  { angus V1.54 }
                finally
                    TriggerLeaveSecurityContext(Client); { AG V1.52 }
                end;
                NewPos := 0;

              { Calcutate MD5 checksum on the fly, when a new file is uploaded } { AG V1.50 }
                Client.MD5OnTheFlyFlag := ftpsCalcMD5OnTheFly in FOptions;
                if (Client.CurrTransMode = ftpTransModeZDeflate) then
                                             Client.MD5OnTheFlyFlag := false; { angus 1.54 }
                if Client.MD5OnTheFlyFlag then begin
                    MD5DigestInit(Client.MD5Digest); { V7.07 }
                    MD5Init(Client.MD5Context);
                    Client.HashStartPos := 0;   { angus 1.54 }
                    Client.HashEndPos := 0;
                end;
            end;
            { We MUST check for file size >= RestartPos since Seek in any      } { V1.49 }
            { write-mode may write to the stream returning always the correct  }
            { new position.                                                    }
            if Client.RestartPos <= NewPos then begin
                TriggerEnterSecurityContext(Client); { AG V1.52 }
                try
                    NewPos := Client.DataStream.Seek(Client.RestartPos, soBeginning);  { V1.49 }
                finally
                    TriggerLeaveSecurityContext(Client); { AG V1.52 }
                end;
            end;
            if NewPos <> Client.RestartPos then begin
                Client.TransferError    := 'Unable to set resume position in local file';
                Client.AbortingTransfer := TRUE;
                PostMessage(Handle, FMsg_WM_FTPSRV_ABORT_TRANSFER,
                            WPARAM(Client.ID), LPARAM(Client));
                Exit;
            end;
            Client.HasOpenedFile := TRUE;
        end;

        { If we have a DataStream, then we need to write the data }
        if Assigned(Client.DataStream) then begin
            Client.ByteCount := Client.ByteCount + Len;
            Client.TotPutBytes := Client.TotPutBytes + Len;    { angus V1.54 }
            TriggerEnterSecurityContext(Client);{ AG V1.52 }
            try
                if (Client.CurrTransMode = ftpTransModeZDeflate) and
                         (Client.ZStreamState = ftpZStateNone) then begin
                 { save compressed data into temp file, decompress on close  }
                    zlibProblemString := '';
                    Client.ZCompFileName := FZlibWorkDir +
                                            GetZlibCacheFileName(Client.FilePath);
                    Client.ZCompFileDelete := True;
                    Client.ZFileStream := OpenFileStream(Client.ZCompFileName, fmCreate);
                    Client.ZStreamState := ftpZStateSaveDecom;
                end;
                if Client.ZStreamState = ftpZStateSaveDecom then
                    Client.ZFileStream.WriteBuffer(Client.RcvBuf^, Len)
                else
                    Client.DataStream.WriteBuffer(Client.RcvBuf^, Len);
            finally
                TriggerLeaveSecurityContext(Client); { AG V1.52 }
            end;
            if Client.MD5OnTheFlyFlag then { AG V1.50 }
                MD5UpdateBuffer(Client.MD5Context, Client.RcvBuf, Len);
        end;
    except
        { An exception occured, so we abort the transfer }
        on E:Exception do begin
            Client.TransferError    := E.Message;
            Client.AbortingTransfer := TRUE;
            PostMessage(Handle, FMsg_WM_FTPSRV_ABORT_TRANSFER,
                        WPARAM(Client.ID), LPARAM(Client));
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.TriggerBuildFilePath(
    Client            : TFtpCtrlSocketW;
    const Directory   : TFtpString;
    const FileName    : TFtpString;
    var   NewFileName : TFtpString);
begin
    if Assigned(FOnBuildFilePath) then
         FOnBuildFilePath(Self, Client, Directory, FileName, NewFileName);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TFtpServerW.IsPathAllowed(                                 { AG V1.52 }
    Client           : TFtpCtrlSocketW;
    const Path       : TFtpString;
    ExcludeBackslash : Boolean) : Boolean;
var
    NewFileName  : TFtpString;    { angus V7.08 }
begin
  { angus V8.50 check for nasty that allowed access to higher level directories than root }
    if (Pos('.\', Path) <> 0) or (Pos('.%2f', Path) <> 0) or (Pos('.%5c', Path) <> 0) then begin
        TriggerDisplay(Client, 'Blocked relative dot notation file path: ' + Path);
        Result := False;
        Exit;
    end;

    if (ftpCdUpHome in Client.Options) then begin
    { angus V7.08 check if a virtual directory is being used, assume allowed if non-blank }
        NewFileName := '';
        TriggerBuildFilePath(Client, Path, '?', NewFileName);   { ? used as flag for reverse translation }
        if NewFileName <> '' then
            Result := TRUE  { end V7.08 change }
        else if ExcludeBackslash then
            Result := (Pos(IcsAnsiLowerCaseW(IcsExcludeTrailingPathDelimiterW(Client.HomeDir)),
                         IcsAnsiLowerCaseW(Path)) = 1)
        else
            Result := (Pos(IcsAnsiLowerCaseW(Client.HomeDir), IcsAnsiLowerCaseW(Path)) = 1);
    end
    else
        Result := TRUE;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TFtpServerW.FormatResponsePath(                                       { AG V1.52 angus V7.08 }
    Client       : TFtpCtrlSocketW;
    const InPath : TFtpString): TFtpString;
const
    Slash = '/';
var
    Home    : TFtpString;
    NewPath : TFtpString ;
begin
    Result := InPath;
    if (ftpHidePhysicalPath in Client.Options) and
       (ftpCdUpHome in Client.Options) then begin
    { angus V7.08 check if a translated virtual directory is being used, returns original virtual path }
        NewPath := '';
        TriggerBuildFilePath(Client, InPath, '?', NewPath);  { ? used as flag for reverse translation }
        if NewPath = '' then NewPath := InPath ;         { no virtual dir, use original path }
        Home := IcsExcludeTrailingPathDelimiterW(Client.HomeDir);
        if Pos(IcsAnsiLowerCaseW(Home), IcsAnsiLowerCaseW(NewPath)) = 1 then
            Result := Copy(NewPath, Length(Home) + 1, Length(NewPath));
    end;
    while (Length(Result) > 0) and (Result[Length(Result)] = PathDelim) do
        SetLength(Result, Length(Result) - 1);
    if (Length(Result) = 0) then
        Result := Slash
    else begin
        Result := IcsBackSlashesToSlashesW(Result);
        if Result[Length(Result)] = ':' then
            Result := Result + Slash;
        if Result[1] <> Slash then
            Result := Slash + Result;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ serge le 5/10/2002 }
function TFtpServerW.BuildFilePath(
    Client      : TFtpCtrlSocketW;
    Directory   : TFtpString;
    FileName    : TFtpString) : TFtpString;
var
    Drive : TFtpString;
    Path  : TFtpString;
begin
    FileName := IcsSlashesToBackSlashesW(FileName);
    PatchIE5(FileName);

    { Gives the application a chance to do the work for us }
    Result := '';
    TriggerBuildFilePath(Client, Directory, FileName, Result);
    if Length(Result) > 0 then
        Exit;                     { Work is done at the app level, done }

    if IsUNC(FileName) then
        Result := FileName
    else if IsUNC(Directory) then begin
        if (Length(FileName) > 0) and (FileName[1] = PathDelim) then begin
            if (ftpCdUpHome in Client.Options) then              { AG V1.52 }
                { absolute path, HomeDir }
                Result := Client.HomeDir + Copy(FileName, 2, Length(FileName))
            else
                Result := IcsExtractFileDriveW(Directory) + FileName;
        end
        else
            Result := Directory + FileName;
    end
    else begin
        if (Length(FileName) > 1) and (FileName[2] = ':') then begin
            Drive := IcsAnsiUpperCaseW(Copy(FileName, 1, 2));
            Path  := Copy(FileName, 3, Length(FileName));
        end
        else if (ftpCdUpHome in Client.Options) and              { AG V1.52 }
                (Length(FileName) > 0) and (FileName[1] = PathDelim) then begin
                { absolute path, HomeDir }
                Drive := IcsExtractFileDriveW(Client.HomeDir);
                Path  := Copy(Client.HomeDir, Length(Drive) + 1, Length(Client.HomeDir)) +
                              Copy(FileName, 2, Length(FileName));
        end
        else begin
            Drive := Copy(Directory, 1, 2);
            Path  := FileName;
        end;
        if (Length(Path) > 0) and (Path[1] = PathDelim) then
            Result := Drive + Path
        else begin
            if Drive <> Copy(Directory, 1, 2) then
                raise FtpServerException.Create('No current dir for ''' + Drive + '''');
            Result := Directory + Path;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandRETR(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
var
    Allowed     : Boolean;
    FilePath    : TFtpString;
    DelayedSend : Boolean;
begin
    try
        if Client.FtpState <> ftpcReady then begin
            Answer := msgNotLogged;
            Exit;
        end;

        try
            Client.CurCmdType    := ftpcRETR;
            Client.HasOpenedFile := FALSE;
            Client.ZStreamState  := ftpZStateNone;
            Client.FileName      := IcsSlashesToBackSlashesW(Params);
            FilePath             := BuildFilePath(Client, Client.Directory, Client.FileName);
            Allowed := IsPathAllowed(Client, FilePath); { AG V1.52 }
            TriggerValidateGet(Client, FilePath, Allowed);
            if not Allowed then begin
                Answer := msgRetrDisabled;
                Exit;
            end;
            Client.FilePath := FilePath;
            Answer          := WideFormat(msgRetrSuccess, [Params]);
            DelayedSend     := FALSE;
            if Assigned(FOnGetProcessing) then
                FOnGetProcessing(Self, Client, DelayedSend);
            if not DelayedSend then
                DoStartSendData(Client, Answer);  { angus V1.54 added Answer }
        except
            on E:Exception do begin
                Answer := WideFormat(msgRetrFailed, [E.Message]);
            end;
        end;
    finally
        { check for success 150..159 in passive mode }
        if Client.PassiveMode and (Copy(Answer, 1, 2) <> '15') then begin
            { flag for ClientStorSessionClosed that the error-message was already sent! }
            Client.TransferError    := '';
            Client.AbortingTransfer := TRUE;
            { set up Passive DataSocket.EventHandlers        }
            { otherwise FreeCurrentPasvPort won't be called! }
            PreparePassiveRetrDataSocket(Client);
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.DoStartSendData(Client : TFtpCtrlSocketW; var Answer : TFtpString);
var
    NewPos  : TFtpBigInt;
    FileExt : TFtpString;
    Done    : Boolean;
    FreeSpace: Int64;
begin
 { angus V1.54 moved main file opening here from ClientRetrSessionConnected so it's
   done before opening the data connection so 451 answer can be given for a missing
   file, and also check if thread needs to be started to compress file }
    Client.HashStartPos := 0;
    Client.HashEndPos := 0;
    Client.ZStreamState := ftpZStateNone;
    Client.ZCompInfo := '';  { text added to 226 OK answer }

{ We need to open a datastream if not already done and a FilePath }
{ exists the component user can have nullified the FilePath or    }
{ created his own data stream (virtual file feature)              }
    try
        if (not Client.HasOpenedFile) and (Length(Client.FilePath) > 0) and
                                       (not Assigned(Client.DataStream)) then begin
            TriggerEnterSecurityContext(Client);
            try
                if not IcsFileExistsW(Client.FilePath) then begin
                    Answer := WideFormat(msgRetrNotExists,
                                     [FormatResponsePath(Client, Client.FilePath)]);
                    Exit;
                end;
                Client.DataStream := OpenFileStream(Client.FilePath,
                                                       Client.FileModeRead); { angus V1.57 }
                NewPos := Client.DataStream.Seek(Client.RestartPos, soBeginning);
            finally
                TriggerLeaveSecurityContext(Client);
            end;
            if NewPos <> Client.RestartPos then begin
                Answer := WideFormat(msgRetrFailed, ['Unable to set resume position in local file']);
                CloseFileStreams(Client);      { angus V1.54 }
                Exit;
            end;
            Client.HasOpenedFile := TRUE;
        end;
        if (not Assigned(Client.DataStream)) then begin
            Answer := WideFormat(msgRetrFailed, ['Failed to open local file']);
            Exit;
        end;
        Client.LastTick := IcsGetTickCountX;  { angus V1.54 last tick for time out checking }

    { angus V1.54 see if compressing the file with zlib }
        if (Client.CurrTransMode = ftpTransModeZDeflate) then begin
            Client.ZStreamState := ftpZStateSaveComp;
            Client.ZCurLevel := Client.ZReqLevel;
            Done := false;
            FreeAndNil (Client.ZFileStream);
            if Client.FilePath <> '' then begin { directory listings don't have file name }
             { don't try to compress certain files any further }
                FileExt := IcsExtractFileExtW(IcsAnsiLowerCaseW(Client.FilePath));
                if Pos (FileExt, FZlibNoCompExt) > 0 then
                                               Client.ZCurLevel := Z_NO_COMPRESSION;
                if Client.DataStream.Size > FZlibMaxSize then            { angus V1.55 }
                                               Client.ZCurLevel := Z_NO_COMPRESSION;
             { check sufficient space on work volume for compressed file }
                FreeSpace := GetFreeSpacePathW (FZlibWorkDir);
                if (Client.DataStream.Size + 100000) > FreeSpace then begin   { don't fill volume!! }
                    TriggerDisplay(Client, 'Insufficient space on ' + FZlibWorkDir +
                        ', need ' + IntToKByte (Client.DataStream.Size) + ', free ' + IntToKByte (FreeSpace));
                    Answer := WideFormat(msgRetrFailed, ['Failed to compress file, insufficient space']);
                    Exit;
                end;
                Client.ZCompFileName := FZlibWorkDir + GetZlibCacheFileName(Client.FilePath);
                Client.ZCompFileDelete := True;
                TriggerUpCompressFile (Client, Done);
                if Done then begin
                    if NOT Assigned (Client.ZFileStream) then begin
                        Done := false;
                        TriggerDisplay(Client, 'Error: no cache file set in UpCompressFile event');
                    end;
                    Client.ZCompInfo := ' compressed size ' + IntToKbyte
                             (Client.ZFileStream.Size) + 'bytes, uncompressed size ' +
                                         IntToKbyte (Client.DataStream.Size) + 'bytes' ;
                end;
            end
            else begin
                if ftpsCompressDirs in Options then         { V8.04 see if compressing directories }
                    Client.ZCurLevel := Z_BEST_SPEED
                else
                    Client.ZCurLevel := Z_NO_COMPRESSION;   { V8.04 skip compressing directories }
                Client.ZCompFileName := 'Directory: ' + Client.DirListPath ;
                Client.ZCompFileDelete := False;
            end;

         { compress file }
            if NOT Done then begin
                if (Client.ProcessingThread <> nil) then begin
                    Answer := WideFormat(msgRetrFailed, ['Failed to compress file, busy']);
                    CloseFileStreams(Client);
                    Exit;
                end;
            { pending - need to allow for another client still compressing this file }
                try
                    TriggerEnterSecurityContext(Client);{ AG 7.02 }
                    try
                        if Client.FilePath <> '' then begin
                            if IcsFileExistsW(Client.ZCompFileName) then
                                                 IcsDeleteFileW(Client.ZCompFileName);
                            Client.ZFileStream := OpenFileStream(Client.ZCompFileName, fmCreate);
                        end
                        else
                            Client.ZFileStream := TMemoryStream.Create;
                    finally
                        TriggerLeaveSecurityContext(Client);{ AG 7.02 }
                    end;
                except
                    Answer := WideFormat(msgRetrFailed, ['Failed to create compress file']);
                    CloseFileStreams(Client);
                    Exit;
                end;

         {angus V8.04 don't use thread if no real compression needed unless more than one meg }
                if (Client.ZCurLevel = Z_NO_COMPRESSION) and
                                            (Client.DataStream.Size < 1000000) then begin
                    TriggerDisplay(Client, 'Skipped thread to compress upload file, no compression');
                    try
                        ZlibCompressStreamEx(Client.DataStream, Client.ZFileStream,
                                    Client.ZCurLevel, zsZLib, false, Self, UpdateThreadOnProgress);
                        Client.ZFileStream.Position := 0 ;
                        Client.ZCompInfo := '' ;
                  { close data file now, not needed any more }
                        Client.DataStream.Destroy;
                        Client.DataStream := Nil;
                    except
                        on E:Exception do begin
                            TriggerDisplay(Client, 'Failed to compress file - ' + E.Message);
                        end;
                    end;
                end
                else begin
                    TriggerDisplay(Client, 'Using thread to compress upload file: ' +
                             Client.ZCompFileName + ', Level ' + IntToStr (Client.ZCurLevel));
                    Client.ProcessingThread := TClientProcessingThreadW.Create(TRUE);
                    Client.ProcessingThread.Client := Client;
                    Client.ProcessingThread.InData := Answer;
                    Client.ProcessingThread.Keyword := 'COMPRESS';
                    Client.ProcessingThread.OnTerminate := ClientProcessingThreadTerminate;
                    Client.ProcessingThread.FreeOnTerminate := TRUE;
                {$IFDEF COMPILER14_UP}
                    Client.ProcessingThread.Start;
                {$ELSE}
                    Client.ProcessingThread.Resume;
                {$ENDIF}
                    { Since answer is sent later when the thread returns we need }
                    { to set this flag!                                          }
                    Client.AnswerDelayed := TRUE;
                    exit;
                end;
            end;
        end;
        PostMessage(Handle, FMsg_WM_FTPSRV_START_SEND, 0, LPARAM(Client));
    except
        on E: Exception do begin
            Answer := WideFormat(msgRetrFailed, [E.Message]);
            CloseFileStreams(Client);      { angus V1.54 }
            Exit;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.WMFtpSrvStartSend(var msg: TMessage);
var
    Client      : TFtpCtrlSocketW;
begin
    Client := TObject(Msg.LParam) as TFtpCtrlSocketW;
    StartSendData(Client);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.ClientPassiveSessionAvailable(Sender : TObject; AError  : Word);
var
    HSocket : TSocket;
    Client  : TFtpCtrlSocketW;
    Data    : TWSocket;
begin
    Data    := TWSocket(Sender);
    Client  := TFtpCtrlSocketW(Data.Owner);
    HSocket := Data.Accept;
    Data.OnSessionClosed := nil;
    Data.Close;   { We don't need to listen any more }

    if Client.CurCmdType in [ftpcSTOR, ftpcAPPE, ftpcSTOU] then begin { FLD V1.45 fixed ftpcSTOU }
        Client.DataSocket.OnSessionConnected  := ClientStorSessionConnected;
        Client.DataSocket.OnSessionClosed     := ClientStorSessionClosed;
        Client.DataSocket.OnDataAvailable     := ClientStorDataAvailable;
        Client.DataSocket.OnDataSent          := nil;
    end
    else if Client.CurCmdType in [ftpcRETR, ftpcLIST, ftpcNLST, ftpcMLSD,
                                   ftpcSiteDMLSD, ftpcXDMLSD] then begin  { angus V1.41, V1.54, V7.01 }
        Client.DataSocket.OnSessionConnected  := ClientRetrSessionConnected;
        Client.DataSocket.OnSessionClosed     := ClientRetrSessionClosed;
        Client.DataSocket.OnDataAvailable     := nil;
        Client.DataSocket.OnDataSent          := ClientRetrDataSent;
    end
    else begin
        Client.DataSocket.OnSessionConnected  := nil;
        Client.DataSocket.OnSessionClosed     := nil;
        Client.DataSocket.OnDataAvailable     := nil;
        Client.DataSocket.OnDataSent          := nil;
    end;
    Client.DataSocket.LingerOnOff             := wsLingerOff;
    Client.DataSocket.LingerTimeout           := 0;
    Client.DataSocket.ExclusiveAddr           := FExclusiveAddr;      { V8.37 }
    Client.DataSocket.SocketErrs              := FSocketErrs;         { V8.37 }
{$IFDEF BUILTIN_THROTTLE}
    Client.DataSocket.BandwidthLimit          := Client.CBandwidthLimit;     { angus V7.12 }
    Client.DataSocket.BandwidthSampling       := Client.CBandwidthSampling;  { angus V7.12 }
{$ENDIF}
    Client.DataSocket.HSocket                 := HSocket;
    Client.PassiveConnected                   := TRUE;
    if Client.DataSocket.SocketRcvBufSize <> Client.FRcvBufSize then         { angus  V7.19 }
        Client.DataSocket.SocketRcvBufSize    := Client.FRcvBufSize;         { angus  V7.19 }
    if Client.DataSocket.SocketSndBufSize <> Client.FSndBufSize then         { angus  V7.19 }
        Client.DataSocket.SocketSndBufSize    := Client.FSndBufSize;         { angus  V7.19 }
    if Client.PassiveStart then
        Client.DataSocket.OnSessionConnected(Client.DataSocket, 0);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.StartSendData(Client : TFtpCtrlSocketW);
begin
    Client.AbortingTransfer              := FALSE;
    Client.DataSent                      := FALSE;
    Client.TransferError                 := 'Transfer Ok';
    Client.DataSocket.ExclusiveAddr      := FExclusiveAddr;      { V8.37 }
    Client.DataSocket.SocketErrs         := FSocketErrs;         { V8.37 }
    if Client.PassiveMode then begin
        PreparePassiveRetrDataSocket(Client);
    end
    else begin
        Client.DataSocket.Close;
        Client.DataSocket.Proto              := 'tcp';
        Client.DataSocket.Addr               := Client.DataAddr;
        Client.DataSocket.Port               := Client.DataPort;
        Client.DataSocket.OnSessionConnected := ClientRetrSessionConnected;
        Client.DataSocket.OnSessionClosed    := ClientRetrSessionClosed;
        Client.DataSocket.OnDataAvailable    := nil;
        Client.DataSocket.OnDataSent         := ClientRetrDataSent;
        Client.DataSocket.LingerOnOff        := wsLingerOff;
        Client.DataSocket.LingerTimeout      := 0;
        if FBindFtpData then begin
            Client.DataSocket.LocalAddr      := Client.GetXAddr;       { IPv6 }
            Client.DataSocket.LocalPort      := 'ftp-data'; {20}
        end;
        Client.DataSocket.ComponentOptions    := [wsoNoReceiveLoop];
{$IFDEF BUILTIN_THROTTLE}
        Client.DataSocket.BandwidthLimit      := Client.CBandwidthLimit;     { angus V7.12 }
        Client.DataSocket.BandwidthSampling   := Client.CBandwidthSampling;  { angus V7.12 }
{$ENDIF}
        Client.DataSocket.Connect;
        if Client.DataSocket.SocketSndBufSize <> Client.FSndBufSize then     { angus  V7.19 }
            Client.DataSocket.SocketSndBufSize := Client.FSndBufSize;        { angus  V7.19 }
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ New setup fuction for all Passive RETR-based data connections               }
procedure TFtpServerW.PreparePassiveRetrDataSocket(Client : TFtpCtrlSocketW);
begin
    Client.DataSocket.OnSessionConnected  := ClientRetrSessionConnected;
    Client.DataSocket.OnSessionClosed     := ClientRetrSessionClosed;
    Client.DataSocket.OnDataAvailable     := nil;
    Client.DataSocket.OnDataSent          := ClientRetrDataSent;
    if Client.PassiveConnected then
        Client.DataSocket.OnSessionConnected(Client.DataSocket, 0)
    else
        Client.PassiveStart := TRUE;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.ClientRetrSessionConnected(Sender : TObject; AError  : Word);
var
    Client      : TFtpCtrlSocketW;
    Data        : TWSocket;
{    NewPos      : TFtpBigInt;   }
begin
    Data                     := TWSocket(Sender);
    Client                   := TFtpCtrlSocketW(Data.Owner);
    Client.DataSessionActive := (AError = 0);

    if Client.AbortingTransfer then
        Exit; { primary command (e.g. RETR) failed - don't trigger }
              { RetrSessionConnected or prepare any data/stream    }

    try
        TriggerRetrSessionConnected(Client, Data, AError);
        if AError <> 0 then
        begin
            raise FtpServerException.Create('Client data socket connection Error - ' +
               GetWinsockErr(AError) + ' - ' + Client.DataAddr + ':' + Client.DataPort); { V1.48 report port in proper decimal }
        end;
    except
        on E: Exception do begin
            Client.AbortingTransfer := TRUE;
            Client.TransferError    := E.Message;
            PostMessage(Handle, FMsg_WM_FTPSRV_ABORT_TRANSFER,
                        WPARAM(Client.ID), LPARAM(Client));
            Exit;
        end;
    end;
  { now start sending data stream }
    Client.ByteCount := 0;
    Client.XferStartTick := IcsGetTickCountX; { angus V1.54 tick when last xfer started, for performance check }
    Client.LastTick := IcsGetTickCountX;      { angus V1.54 last tick for time out checking }
    SendNextDataChunk(Client, Data);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.ClientRetrSessionClosed(Sender : TObject; AError  : Word);
var
    Client      : TFtpCtrlSocketW;
    Data        : TWSocket;
    Duration    : Integer;
    S           : TFtpString;
    BytesSec    : Int64;
begin
    Data                     := TWSocket(Sender);
    Client                   := TFtpCtrlSocketW(Data.Owner);

{ !!!!!!!! NGB: Free Up Current Port - next 2 lines added }
    if Client.PassiveMode then // FLD 29.12.05
        FreeCurrentPasvPort(Client);
{ !!!!!!!! NGB: previous 2 lines added }

    Client.DataSessionActive := FALSE;
    Client.PassiveStart      := FALSE;
    Client.PassiveConnected  := FALSE;
    Client.RestartPos        := 0;
    { Reset data port to standard value }
    Client.DataPort          := 'ftp-data';

    { If we had opened a data stream ourself, then close it }
    CloseFileStreams(Client);      { angus V1.54 }

{ angus V1.54 report performance }
    if Assigned(FOnDisplay) then begin
        Duration := IcsElapsedMsecs (Client.XferStartTick);
        S := Client.FilePath;
        if S = '' then S := 'Directory';
        S := S + ' ' + IntToKbyte(Client.ByteCount) + 'bytes sent in ';
        if Duration < 2000 then
            S := S + IntToStr(Duration) + ' milliseconds'
        else begin
            S := S + IntToStr(Duration div 1000) + ' seconds';
            if Client.ByteCount > 32767 then
                BytesSec := 1000 * (Client.ByteCount div Duration)
            else
                BytesSec := (1000 * Client.ByteCount) div Duration;
            S := S + ' (' + IntToKbyte(BytesSec) + 'bytes/sec)';
        end;
        TriggerDisplay (Client, S);
    end;

    if Client.AbortingTransfer and (Client.TransferError = '') then
        Exit; { This happens when the command itself was failed - do not      }
              { reply on command channel and don't trigger RetrSessionClosed! }

    if Client.AbortingTransfer then
        SendAnswer(Client, WideFormat(msgRetrFailed, [Client.TransferError]))
    else if AError <> 0 then
        SendAnswer(Client, WideFormat(msgRetrFailed, ['Error - ' + GetWinsockErr(AError)]))
    else
        SendAnswer(Client, msgRetrOk + Client.ZCompInfo);  { angus V1.54 }

    TriggerRetrSessionClosed(Client, Data, AError);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.SendNextDataChunk(
    Client : TFtpCtrlSocketW;
    Data   : TWSocket);
var
    Count : LongInt;
begin
    try
        Count := 0;
        TriggerEnterSecurityContext(Client);           { AG V1.52 }
        try
         { angus V1.54 }
            if Client.ZStreamState = ftpZStateSaveComp then begin
                if Assigned(Client.ZFileStream) then
                    Count := Client.ZFileStream.Read(Client.RcvBuf^, Client.RcvSize);
            end
            else begin
                if Assigned(Client.DataStream) then
                    Count := Client.DataStream.Read(Client.RcvBuf^, Client.RcvSize);
            end;
        finally
            TriggerLeaveSecurityContext(Client);       { AG V1.52 }
        end;
        Client.LastTick := IcsGetTickCountX;  { angus V1.54 last tick for time out checking }

        if Count > 0 then begin
            Client.ByteCount := Client.ByteCount + Count;
            Client.TotGetBytes := Client.TotGetBytes + Count;    { angus V1.54 }
            Data.Send(Client.RcvBuf, Count);
        end
        else begin { EOF }
            if not Client.DataSent then begin
                Client.DataSent := TRUE;
                PostMessage(Handle, FMsg_WM_FTPSRV_CLOSE_DATA,
                            WPARAM(Client.ID), LPARAM(Client));
            end;
        end;
    except
        { An exception occured, so we abort the transfer }
        on E:Exception do begin
            Client.TransferError    := E.Message;
            Client.AbortingTransfer := TRUE;
            PostMessage(Handle, FMsg_WM_FTPSRV_ABORT_TRANSFER,
                        WPARAM(Client.ID), LPARAM(Client));
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.ClientRetrDataSent(Sender : TObject; AError : Word);
var
    Client : TFtpCtrlSocketW;
    Data   : TWSocket;
begin
    Data   := TWSocket(Sender);
    Client := TFtpCtrlSocketW(Data.Owner);

    if Client.AbortingTransfer then
        Exit;

    try
        { Trigger the user event for the received data }
        TriggerRetrDataSent(Client, Data, AError);
        if AError <> 0 then
            raise FtpServerException.Create('Send Error - ' + GetWinsockErr(AError));
        SendNextDataChunk(Client, Data);
    except
        { An exception occured, so we abort the transfer }
        on E:Exception do begin
            Client.TransferError    := E.Message;
            Client.AbortingTransfer := TRUE;
            SendAnswer(Client, WideFormat(msgRetrAborted, [Client.TransferError]));
            PostMessage(Handle, FMsg_WM_FTPSRV_ABORT_TRANSFER,
                        WPARAM(Client.ID), LPARAM(Client));
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandSYST(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;

    Client.CurCmdType := ftpcSYST;
    Answer            := msgSystem;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandDirectory(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString;
    Detailed    : Boolean);
var
    ListType: TListType;              { angus V1.38 }
begin
    if Detailed then
        ListType := ListTypeUnix
    else
        ListType := ListTypeName;
    CommandDirectory2(Client, Keyword, Params, Answer, ListType); { angus V1.38 }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandDirectory2(     { angus V1.38 }
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString;
    ListType    : TListType);               { angus V1.38 }
var
    Path       : TFtpString;
    Args       : TFtpString;
    Offset     : Integer;
begin
    try
        CloseFileStreams(Client);      { angus V1.54 }
        Client.AbortingTransfer := FALSE;  { V7.08 }

        try
{ angus 1.54  parse optional file and directory parameters, ie
    (blank)                    ( list all files in working directory set by CWD, shown by PWD )
    -AL                        ( list all files including hidden )
    -R                         ( list all files recursively, include sub-directories )
    -SUBDIRS                   ( list all files recursively, include sub-directories )
    *.zip                      ( list all files with zip extension )
    index.html                 ( list a single file )
    "my index.html"            ( list a single file )
    temp                       ( list all files in specified directory )
    /temp                      ( list all files in specified directory )
    /temp/ -R                  ( list all files in specified directory and sub-directory )
    '/program files' -R
    "/program files/*.zip" -R

        NOTE1: we currently support all parameters for DIR, LIST, NLST, MLSD, SITE INDEX,
              SITE CMLSD, XCMLSD, SITE DMLSD, XDMLSD which is not really RFC compliant, but useful
        NOTE2: we don't yet support multiple arguments, ie only -R or -AL, not both
        NOTE3: -R or -SUBDIRS recursive listings have a file name with path and leading /, ie
               /download/ALLDEPOTS/all/30=page-022864.zip  }

            Params := IcsSlashesToBackSlashesW(Params);
            Path := '';
            Args := '';
            Client.DirListHidden := FALSE;
            Client.DirListSubDir := FALSE;
            Client.DirListType := ListType;

          { angus V8.50 check for nasty that allowed indexing higher level directories than root }
            if (Pos('.\', Params) <> 0) or (Pos('.%2f', Params) <> 0) or (Pos('.%5c', Params) <> 0) then
                raise Exception.Create('Cannot accept relative path using dot notation');

         { angus 1.54  parse parameter for file/path and one argument }
            if Length (Params) > 0 then begin
                if Params [1] = '-' then   { just found a argument }
                    Args := Params
                else begin                 { otherwise filename and option argument }
                   Offset := 1;
                   Path := IcsScanGetNextArg (Params, Offset);  { keep path or file name }
                   Args := IcsScanGetNextArg (Params, Offset);  { and argument, if any }
                end;
            end;

         { angus 1.54  check directory arguments }
            if (UpperCase(Args) = '-LA') or (UpperCase(Args)= '-AL') then
                                                         Client.DirListHidden := TRUE;
            if (Args = '-R') or (UpperCase(Args) = '-SUBDIRS') then
                                                         Client.DirListSubDir := TRUE;
            if (Client.CurCmdType = ftpcSiteIndex) then Client.DirListSubDir := TRUE;

         { see if application wants to build listing, if not we do it }
            TriggerBuildDirectory(Client, Path, (ListType <> ListTypeName));      { angus V1.38 }
            Client.FilePath := '';       { make sure no file open attempt }
            if not Assigned(Client.DataStream) then begin
                Client.DataStream    := TMemoryStream.Create;
                Client.HasOpenedFile := TRUE;
                BuildDirectory(Client, Path);          { angus V1.54  }
                if Client.AnswerDelayed then exit ;    { angus V1.54 using a thread }
                TriggerAlterDirectory(Client, Path, (ListType <> ListTypeName));  { angus V1.38 }
                Client.DataStream.Seek(0, 0);
            end;

         { angus V1.54 see if returning listing on control socket instead of data socket }
            if Client.CurCmdType in [ftpcSiteIndex, ftpcSiteCmlsd, ftpcXCMLSD] then begin   { angus 7.01 }
                Client.DataStreamReadString(UnicodeString (Answer), Client.DataStream.Size, Client.CurrentCodePage); { AG 7.02 } { angus 7.02W  }
                if Client.CurCmdType = ftpcSiteIndex then
                     Answer := WideFormat(msgIndexFollows, [Params]) +
                                                     #13#10 + Answer + msgIndexDone;
                if Client.CurCmdType in [ftpcSiteCmlsd, ftpcXCMLSD] then    { angus 7.01 }
                     Answer := msgMlstFollows + #13#10 + Answer + msgMlstFollowDone;
                CloseFileStreams(Client);
            end
            else
            begin
                Answer := msgDirOpen;
                DoStartSendData(Client, Answer);  { angus V1.54 added Answer }
            end;
        except
            on E:Exception do begin
                Answer := WideFormat(msgDirFailed, [E.Message])
            end;
        end;
    finally
        { check for success 150..159 in passive mode }
        if (Client.HasOpenedFile) and (Client.PassiveMode) and
                     (NOT Client.AnswerDelayed) and (Copy(Answer, 1, 2) <> '15') then begin  { V7.08 }
            { flag for ClientRetrSessionClosed that the error-message was already sent! }
            Client.TransferError    := '';
            Client.AbortingTransfer := TRUE;
            { set up Passive DataSocket.EventHandlers        }
            { otherwise FreeCurrentPasvPort won't be called! }
            PreparePassiveRetrDataSocket(Client);
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandLIST(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;

    Client.CurCmdType := ftpcLIST;
    CommandDirectory(Client, KeyWord, Params, Answer, TRUE);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandNLST(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;

    Client.CurCmdType := ftpcNLST;
    CommandDirectory(Client, KeyWord, Params, Answer, FALSE);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.BuildDirectory(
    Client     : TFtpCtrlSocketW;
    var Path   : TFtpString);    { angus 1.54 now Client.Stream and Client.DirListType }
var
    Buf        : TFtpString;
    Allowed    : Boolean;
    TotalFiles : integer;  { V7.08 }
begin
    DecodeDate(Now, ThisYear, ThisMonth, ThisDay);  { V7.08 moved from BuildDirList }

 {  angus 1.54 hidden argument now parsed in CommandDirectory2,
               params is now only path or file name }

 { angus 1.54 remove leading / to keep BuildFilePath happy, probably not backward compatible!! }
    if (Length (Path) >= 1) and (Path [1] = PathDelim) then Path := Copy (Path, 2, 999);
    if Path = '' then
{        Client.DirListPath := Client.Directory + '*.*'   V7.08 }
        Client.DirListPath := BuildFilePath(Client, Client.Directory, '*.*')  { angus V7.08 must not skip buildpath }
    else begin
        if Path[Length(Path)] = PathDelim then Path := Path + '*.*';
        Client.DirListPath := BuildFilePath(Client, Client.Directory, Path);
    end;

    Allowed := IsPathAllowed(Client, Client.DirListPath);                 { AG V1.52 }
    if not Allowed then { AG V1.52 }
    begin
        Buf := FormatResponsePath(Client, Client.DirListPath) +
                                                 ' Permission denied' + #13#10;
        Client.DataStreamWriteString(Buf, Client.CurrentCodePage); { angus 7.02 }
        Exit; //***
    end;

 { angus 1.54 see if using a thread to list directory }
    if (((ftpsThreadRecurDirs in Options) and (Client.DirListSubDir)) OR
               (ftpsThreadAllDirs in Options)) and
                        (Client.ProcessingThread = nil) then begin
        TriggerDisplay(Client, 'Using thread to list directory');
        Client.ProcessingThread := TClientProcessingThreadW.Create(TRUE);
        Client.ProcessingThread.Client := Client;
        Client.ProcessingThread.InData := Path;
        Client.ProcessingThread.Keyword := 'DIRECTORY';
        Client.ProcessingThread.OnTerminate := ClientProcessingThreadTerminate;
        Client.ProcessingThread.FreeOnTerminate := TRUE;
    {$IFDEF COMPILER14_UP}
        Client.ProcessingThread.Start;
    {$ELSE}
        Client.ProcessingThread.Resume;
    {$ENDIF}
        { Since answer is sent later when the thread returns we need }
        { to set this flag!                                          }
        Client.AnswerDelayed := TRUE;
        exit;
    end;
    TriggerEnterSecurityContext(Client);                  { AG V1.52 }
    try
     { angus 1.54 moved all listing code to FtpSrvC }
        Client.BuildDirList(TotalFiles);         { V7.08 }
        if TotalFiles = -1 then
            TriggerDisplay(Client, 'Completed directory listing for: ' +
                                                    Client.DirListPath + ' failed')
        else
            TriggerDisplay(Client, 'Completed directory listing for: ' +
                        Client.DirListPath + ', Total Files: ' + IntToStr (TotalFiles));
    finally
        TriggerLeaveSecurityContext(Client);              { AG V1.52 }
    end;

    if Client.DataStream.Size = 0 then begin
        if TotalFiles = -1 then
            Buf := 'Listing failed' + #13#10  { V7.08 }
        else
            Buf := FormatResponsePath(Client, Client.DirListPath) + ' not found' + #13#10; { AG V1.52 }
        Client.DataStreamWriteString(Buf, Client.CurrentCodePage);  { AG V6.03 }{ AG 7.02 }
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandTYPE(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
var
    Buf : TFtpString;
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;

    Client.CurCmdType := ftpcTYPE;
    Buf := IcsAnsiUpperCaseW(Trim(Params));
    if (Buf = 'A') or (Buf = 'A N') or (Buf = 'I') then begin
        Answer            := WideFormat(msgTypeOk, [Params]);
        Client.BinaryMode := (Buf = 'I');
    end
    else
        Answer := WideFormat(msgTypeFailed, [Params]);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandDELE(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
var
    FileName : TFtpString;
    Allowed  : Boolean;
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;

    Client.CurCmdType := ftpcDELE;
    FileName          := BuildFilePath(Client, Client.Directory, Params);
    Allowed := IsPathAllowed(Client, FileName); { AG V1.52 }
    TriggerValidateDele(Client, FileName, Allowed);
    if not Allowed then begin
        Answer := msgDeleDisabled;
        Exit;
    end;
    if Params = '' then begin
        Answer := msgDeleSyntax;                             { V1.52 AG}
        Exit;
    end;
    Allowed := FALSE;
    TriggerEnterSecurityContext(Client);
    try
        if IcsFileExistsW(FileName) then begin
            if IcsDeleteFileW(FileName) then begin
                Answer := WideFormat(msgDeleOk, [FormatResponsePath(Client, FileName)]);
                Allowed := TRUE;
            end
            else
                Answer := WideFormat(msgDeleFailed, [FormatResponsePath(Client, FileName)]);
        end
        else
            Answer := WideFormat(msgDeleNotExists, [FormatResponsePath(Client, FileName)]);
    finally
        TriggerLeaveSecurityContext(Client);
    end;
    if Allowed then
        { Cached Md5Sum should be deleted }
        TriggerMd5Calculated(Client, FileName, ''); { AG V1.50 }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandSIZE(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
var
    FilePath : TFtpString;
    Allowed  : Boolean;
    Size     : TFtpBigInt;
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;

    Client.CurCmdType := ftpcSIZE;
    FilePath          := BuildFilePath(Client, Client.Directory, Params);
    Allowed := IsPathAllowed(Client, FilePath); { AG V1.52 }
    TriggerValidateSize(Client, FilePath, Allowed);
    if not Allowed then begin
        Answer := msgSizeDisabled;
        Exit;
    end;

    if Params = '' then
        Answer := msgSizeSyntax                               { V1.52 AG}
    else begin
        try
            TriggerEnterSecurityContext(Client);               { V1.52 AG }
            try
                Size := IcsGetFileSizeW(FilePath);
                if Size >= 0 then
                    Answer := WideFormat(msgSizeOk, [Size])
                else
                    Answer := WideFormat(msgSizeFailed, ['File not found']);
            finally
                TriggerLeaveSecurityContext(Client);           { V1.52 AG }
            end;
        except
            on E:Exception do begin
                Answer := WideFormat(msgSizeFailed, [E.Message])
            end;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandREST(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;

    Client.CurCmdType := ftpcREST;
    try
        Client.RestartPos := atoi64(Params);
        if Client.RestartPos < 0 then begin        { 20020916 }
            Answer            := msgRestZero;
            Client.RestartPos := 0;
        end
        else begin
            if (ftpsModeZNoResume in Options) and
                    (Client.CurrTransMode = ftpTransModeZDeflate) then   { angus V1.55 }
                Answer := msgRestNotModeZ
            else
                Answer := WideFormat(msgRestOk, [Client.RestartPos]);
        end;
    except
        on E:Exception do begin
            Answer            := WideFormat(msgRestFailed, [E.Message]);
            Client.RestartPos := 0;
        end;
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandRNFR(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
var
    FileName : TFtpString;
    Allowed  : Boolean;
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;

    Client.CurCmdType := ftpcRNFR;
    FileName          := BuildFilePath(Client, Client.Directory, Params);
    Allowed := IsPathAllowed(Client, FileName); { AG V1.52 }
    TriggerValidateRnFr(Client, FileName, Allowed);
    if not Allowed then begin
        Answer := msgRnFrDisabled;
        Exit;
    end;
    if Params = '' then
        Answer := msgRnfrSyntax                              { V1.52 AG}
    else begin
        TriggerEnterSecurityContext(Client);                 { V1.52 AG }
        try
            if IcsFileExistsW(FileName) or IcsDirExistsW(Filename) then begin
                Client.FromFileName := FileName;
                Answer              := msgRnfrOk;            { V1.52 AG }
            end
            else
                Answer := WideFormat(msgRnfrNotExists, [FormatResponsePath(Client, FileName)]);
        finally
            TriggerLeaveSecurityContext(Client);             { V1.52 AG }
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandRNTO(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
var
    FileName : TFtpString;
    Allowed  : Boolean;
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;

    Client.CurCmdType := ftpcRNTO;
    FileName          := BuildFilePath(Client, Client.Directory, Params);
    Allowed := IsPathAllowed(Client, FileName); { AG V1.52 }
    TriggerValidateRnTo(Client, FileName, Allowed);
    if not Allowed then begin
        Answer := msgRnToDisabled;
        Exit;
    end;
    if Params = '' then begin
        Answer := msgRntoSyntax;                              { V1.52 AG}
        Exit;
    end;
    Allowed := FALSE;                                         { V1.52 AG }
    TriggerEnterSecurityContext(Client);                      { V1.52 AG }
    try
        if IcsFileExistsW(FileName) or IcsDirExistsW(Filename) then
            Answer := WideFormat(msgRntoAlready, [FormatResponsePath(Client, FileName)])
        else if (not IcsFileExistsW(Client.FromFileName)) and
                   (not IcsDirExistsW(Client.FromFileName)) then
            Answer := WideFormat(msgRntoNotExists, [FormatResponsePath(Client, Client.FromFileName)])
        else begin
            Client.ToFileName := FileName;
            Allowed := IcsRenameFileW(Client.FromFileName, Client.ToFileName);
        end;
    finally
        TriggerLeaveSecurityContext(Client);                  { V1.52 AG }
    end;
    if Allowed then begin
        Answer := WideFormat(msgRntoOk, [FormatResponsePath(Client, Client.FromFileName),
                                    FormatResponsePath(Client, Client.ToFileName)]);
        { Cached Md5Sum should be updated with a new key } { AG V1.50 }
        TriggerMd5Calculated(Client, FileName, '');
    end
    else
        Answer := WideFormat(msgRntoFailed, [FormatResponsePath(Client, Client.FromFileName)]);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandNOOP(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
begin
    Client.CurCmdType := ftpcNOOP;
    Answer            := WideFormat(MsgNoopOk, [Params]);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandMKD(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
var
    Dir : TFtpString;                                    { V1.52 AG}
    Allowed  : Boolean;
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;

    try
        Client.CurCmdType := ftpcMKD;
        Dir               := BuildFilePath(Client, Client.Directory, Params);
        Allowed := IsPathAllowed(Client, Dir); { AG V1.52 }
        TriggerMakeDirectory(Client, Dir, Allowed);
        if not Allowed then
            Answer := WideFormat(msgMkdFailed, [FormatResponsePath(Client, Dir)]) { V1.52 AG }
        else if Params = '' then
            Answer := msgMkdSyntax                              { V1.52 AG}
        else begin
            TriggerEnterSecurityContext(Client);                { V1.52 AG }
            try
                if IcsDirExistsW(Dir) or IcsFileExistsW(Dir) then       { V1.52 AG }
                    Answer := WideFormat(msgMkdAlready, [FormatResponsePath(Client, Dir)]) { V1.52 AG }
                else begin
                    if IcsCreateDirW(Dir) then
                        Answer := WideFormat(msgMkdOk, [FormatResponsePath(Client, Dir)]) { V1.52 AG }
                    else
                        Answer := WideFormat(msgMkdFailed, [FormatResponsePath(Client, Dir)]); { V1.52 AG }
                end;
            finally
                TriggerLeaveSecurityContext(Client);            { V1.52 AG }
            end;
        end;
    except
        on E:Exception do begin
            Answer := WideFormat(msgMkdFailed, [E.Message])
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandAPPE(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
var
    Allowed  : Boolean;
    FilePath : TFtpString;
begin
    try
        if Client.FtpState <> ftpcReady then begin
            Answer := msgNotLogged;
            Exit;
        end;

        try
            Client.CurCmdType       := ftpcAPPE;
            Client.FileName         := IcsSlashesToBackSlashesW(Params);
            Client.HasOpenedFile    := FALSE;
            FilePath                := BuildFilePath(Client, Client.Directory, Client.FileName);
            Allowed := IsPathAllowed(Client, FilePath); { AG V1.52 }
            TriggerValidatePut(Client, FilePath, Allowed);
            if not Allowed then begin
                Answer := msgAppeDisabled;
                Exit;
            end;
            Client.FilePath := FilePath;
            PrepareStorDataSocket(Client);
            Client.RestartPos := IcsGetFileSizeW(Client.FilePath);
            if Client.RestartPos < 0 then
                Client.RestartPos := 0;
            Answer := WideFormat(msgAppeReady, [Params,Client.RestartPos]);
        except
            on E:Exception do begin
                Answer := WideFormat(msgAppeFailed, [E.Message]);
            end;
        end;
    finally
        { check for success 150..159 in passive mode }
        if Client.PassiveMode and (Copy(Answer, 1, 2) <> '15') then begin
            { flag for ClientStorSessionClosed that the error-message was already sent! }
            Client.TransferError    := '';
            Client.AbortingTransfer := TRUE;

            { set up Passive DataSocket.EventHandlers         }
            {  otherwise FreeCurrentPasvPort won't be called! }
            PreparePassiveStorDataSocket(Client);
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandSTRU(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
begin
    Client.CurCmdType := ftpcSTRU;
    Answer            := WideFormat(MsgStruOk, [Params]);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandRMD(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
var
    Dir      : TFtpString;   { V1.52 AG }
    Allowed  : Boolean;
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;

    Client.CurCmdType := ftpcRMD;
    Dir               := BuildFilePath(Client, Client.Directory, Params);
    Allowed := IsPathAllowed(Client, Dir); { AG V1.52 }
    TriggerValidateRmd(Client, Dir, Allowed);
    if not Allowed then begin
        Answer := msgRmdDisabled;
        Exit;
    end;
    if Params = '' then begin
        Answer := msgMkdSyntax;                            { V1.52 AG}
        Exit;
    end;
    TriggerEnterSecurityContext(Client);                    { V1.52 AG }
    try
        if not IcsDirExistsW(Dir) then
            Answer := WideFormat(msgRmdNotExists, [FormatResponsePath(Client, Dir)])
        else begin
            if IcsRemoveDirW(Dir) then
                Answer := WideFormat(msgRmdOk, [FormatResponsePath(Client, Dir)])
            else
                Answer := WideFormat(msgRmdFailed, [FormatResponsePath(Client, Dir)]);
        end;
    finally
        TriggerLeaveSecurityContext(Client);               { V1.52 AG }
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandABOR(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
begin
    if Client.DataSocket.State = wsConnected then begin
        Client.TransferError    := 'ABORT requested by client';
        Client.AbortingTransfer := TRUE;
        Client.DataSocket.Close;
    end;
    Answer := msgAborOk;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TFtpServerW.GetNextAvailablePasvPort : String;
var
    I        : Integer;
    NewPort  : Integer;
    TablePtr : PBoolean;
begin
    if (FPasvPortRangeSize = 0) or (FPasvPortRangeStart = 0) then
        Result := AnsiChar('0')
    else begin
        Result := AnsiChar('0');
        I := 0;
  { angus V1.56 - allocate sequential ports within range instead of same low ports }
        if FPasvNextNr >= FPasvPortRangeSize then FPasvNextNr := 0;      { angus V1.56 }
        while TRUE do begin
            TablePtr := IncPtr(FPasvPortTable, SizeOf(Boolean) * FPasvNextNr); { AG V6.02 }
            if TablePtr^ = FALSE then begin
                TablePtr^ := TRUE;    { mark port as being used }
                NewPort   := FPasvPortRangeStart + FPasvNextNr;          { angus V1.56 }
                Inc(FPasvNextNr);                                        { angus V1.56 }
                Result    := IntToStr(NewPort);
                break;
            end;
            Inc(FPasvNextNr);                                            { angus V1.56 }
            if FPasvNextNr >= FPasvPortRangeSize then FPasvNextNr := 0;  { angus V1.56 }
            Inc(I);
            if I >= FPasvPortRangeSize then begin  { V8.64 reset to start if no free ports }
                Result := IntToStr(FPasvPortRangeStart);
                FPasvNextNr := 0;
                break;  { no free ports in range - angus V1.56 }
            end;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.FreeCurrentPasvPort(AClient : TFtpCtrlSocketW);
var
    CurrentPort : Integer;
{$IFNDEF COMPILER12_UP}
    ErrorCode   : Integer;
{$ENDIF}
begin
    if (FPasvPortRangeSize = 0) or (FPasvPortRangeStart = 0) then
        Exit;
    { FLD changed following lines, because                                   }
    { FreeCurrentPasvPort might be called when the socket is already closed! }
    if AClient.DataSocket.State = wsClosed then
{$IFNDEF COMPILER12_UP}
        Val(AClient.DataSocket.Port, CurrentPort, ErrorCode)
{$ELSE}
        CurrentPort := atoi(AClient.DataSocket.Port)
{$ENDIF}
    else
{$IFNDEF COMPILER12_UP}
        Val(AClient.DataSocket.GetXPort, CurrentPort, ErrorCode);
{$ELSE}
        CurrentPort := atoi(AClient.DataSocket.GetXPort);
{$ENDIF}
    if (CurrentPort >= FPasvPortRangeStart) and
       (CurrentPort <= (FPasvPortRangeStart + FPasvPortRangeSize)) then begin
        PBoolean(IncPtr(FPasvPortTable,                        { AG V6.02 }
                 SizeOf(Boolean) * (CurrentPort - FPasvPortRangeStart)))^ := FALSE;   { free port in table }
    end;
    AClient.PassiveMode := FALSE;  // FLD 29.12.05
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandPASV(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
var
    saddr     : TSockAddrIn;
    saddrlen  : Integer;
    DataPort  : Integer;
    IPAddr    : TIcsInAddr;
    PASVAddr  : TIcsInAddr;
    APasvIp   : TFtpString;
    SetPasvIp : Boolean;
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;
    if Client.FEpsvAllArgReceived then begin       { IPv6 }
        Answer := Format(msgEPSVALLDeny, [Keyword]);
        Exit;
    end;
    try
        { Get our IP address from our control socket }
        saddrlen := SizeOf(saddr);
        Client.GetSockName(saddr, saddrlen);
        IPAddr := PIcsInAddr(@saddr.sin_addr)^;       { IPv6 }

        { FLD Make sure to free up a previous connected passive data-socket!! }
        { can happen if a PASV-command is issued, but a passive connection is }
        { never connected, and then a subsequent PASV-command is issued.      }
        if Client.PassiveMode then // FLD 29.12.05
            FreeCurrentPasvPort(Client);

        Client.DataSocket.Close;
        Client.DataSocket.Addr  := '0.0.0.0';   { Any addr }

        Client.DataSocket.Port  := GetNextAvailablePasvPort; { '0';          Any port  }
        if Client.DataSocket.Port = '' then
            raise Exception.Create('No available PASV Ports');

        Client.DataSocket.Proto := 'tcp';
        Client.DataSocket.OnSessionAvailable := ClientPassiveSessionAvailable;
        Client.DataSocket.OnSessionConnected := nil;
        Client.DataSocket.OnSessionClosed    := nil;
        Client.DataSocket.OnDataAvailable    := nil;
        Client.DataSocket.ComponentOptions   := [wsoNoReceiveLoop];
        Client.DataSocket.ExclusiveAddr      := FExclusiveAddr;      { V8.37 }
        Client.DataSocket.SocketErrs         := FSocketErrs;         { V8.37 }
        Client.DataSocket.Listen;

        { Get the port assigned by winsock }
        saddrlen := SizeOf(saddr);
        Client.DataSocket.GetSockName(saddr, saddrlen);
        DataPort := WSocket_ntohs(saddr.sin_port);

       { V8.63 log some IP addresses and ports for diagnostics }
        TriggerDisplay (Client, '! Server IP: ' + Client.CServerAddr +
                    ', Passive Port: ' + Client.DataSocket.Port + ', External IP: ' +
                                   FPasvIpAddr + ', Remote IP: ' + Client.CPeerAddr);

        if Client.sin.sin_addr.s_addr = WSocket_htonl($7F000001) then
            Answer := WideFormat(msgPasvLocal,
                          [IcsHiByte(DataPort),
                           IcsLoByte(DataPort)])
        else begin
            APasvIp := FPasvIpAddr;  { configured external passive IP address }
          { V8.63 easier to see what is happening here, use string IPs to avoid horrible casts }
            SetPasvIp := (APasvIp <> '');
            if (ftpsNoPasvIpAddrInLan in FOptions) and IcsIsIpPrivate(Client.CPeerAddr) then
                SetPasvIp := False;
            if (ftpsNoPasvIpAddrSameSubnet in FOptions) and
                          IcsAddrSameSubNet(Client.CServerAddr, Client.CPeerAddr) then
                SetPasvIp := False;

            if Assigned(FOnPasvIpAddr) then begin
                FOnPasvIpAddr(Self, Client, APasvIp, SetPasvIp);
                SetPasvIp := SetPasvIp and (APasvIp <> '');
            end;
            if not SetPasvIp then
                Answer := WideFormat(msgPasvRemote,
                          [ord(IPAddr.S_un_b.s_b1),
                           ord(IPAddr.S_un_b.s_b2),
                           ord(IPAddr.S_un_b.s_b3),
                           ord(IPAddr.S_un_b.s_b4),
                           IcsHiByte(DataPort),
                           IcsLoByte(DataPort)])
            else begin
                PASVAddr.S_addr := WSocket_inet_addr(AnsiString(APasvIp));
                if (PASVAddr.S_addr = u_long(INADDR_NONE)) or
                            (PASVAddr.S_addr = 0) then { angus v1.53 0.0.0.0 not allowed }
                    raise Exception.Create('Invalid PASV IP Address')
                else
                    Answer := Format(msgPasvRemote,
                          [ord(PASVAddr.S_un_b.s_b1),
                           ord(PASVAddr.S_un_b.s_b2),
                           ord(PASVAddr.S_un_b.s_b3),
                           ord(PASVAddr.S_un_b.s_b4),
                           IcsHiByte(DataPort),
                           IcsLoByte(DataPort)]);
                end;
        end;
        Client.PassiveMode      := TRUE;
        Client.PassiveStart     := FALSE;
        Client.PassiveConnected := FALSE;
    except
        on E:Exception do begin
            Answer := WideFormat(msgPasvExcept, [E.Message]);
            try
                FreeCurrentPasvPort(Client);  { V8.64 clean up }
                Client.DataSocket.Close;
            except
                { Ignore any exception here }
            end;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ angus V1.38  added set modification date and time version                        }
{ angus v1.53  support fractional seconds, usually milliseconds, updating time
{ MDTM default.asp                    get modification date and time               }
{ MFMT 20040804102811 default.asp     set modification date and time UTC time      }
{ MDTM 20040804102811 default.asp     set modification date and time local time    }
{ MDTM 20040804102811+60 default.asp  set modification date and time UTC + 60 mins }
{ MDTM 20040804102811-60 default.asp  set modification date and time UTC - 60 mins }
{ MFMT 20040804102811.1 default.asp   set modification date and time UTC time      }
{ MFMT 20040804102811.12 default.asp  set modification date and time UTC time      }
{ MFMT 20040804102811.123 default.asp set modification date and time UTC time      }
procedure TFtpServerW.CommandMDTM(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
var
    FileTime : String;
    FileName : TFtpString;
    I, J     : Integer;
    UtcFlag  : Boolean;
    SuccFlag : Boolean;
    FileDT   : TDateTime;
    Bias     : Integer;
    Allowed  : Boolean;         { angus V1.39 }
    FExists  : Boolean;
begin
    if Client.FtpState <> ftpcReady then begin   { angus V1.39 }
        Answer := msgNotLogged;
        Exit;
    end;

    try
        if Keyword = 'MFMT' then            { angus V1.39 else assume MDTM }
            Client.CurCmdType := ftpcMFMT
        else
            Client.CurCmdType := ftpcMDTM;
        J                 := 1;
        FileDT            := 0;
        UtcFlag           := FALSE;
        Allowed           := TRUE;

        { look for numeric date and time - angus V1.53 with or without millisecs }
        while (J <= Length(Params)) and
              (((Params[J] >= '0') and (Params[J] <= '9')) or (Params[J] = '.')) do
           Inc(J);
        if (J >= 15) and (J <= 19) then begin  { found date and time so we are setting it, not getting it }
            FileDT := MDTM2Date (Copy (Params, 1, J - 1));
            if FileDT < 10 then begin
                Answer := msgMdtmSyntax;
                Exit;
            end;
            I := J;

            { see if UTC time offset in minutes is passed }
            while (J <= Length(Params)) and
                  ((Params[J] = '+') or (Params[J] = '-') or
                   ((Params[J] >= '0') and (Params[J] <= '9'))) do
                Inc(J);
            if Client.CurCmdType = ftpcMFMT then
                UtcFlag := TRUE
            else begin
                if I <> J then begin
                    UtcFlag := TRUE;
                    Bias := atosi(Copy (Params, I, 4));   { signed integer, +60, -120, +0 }
                    if Bias <> 0 then FileDT := FileDT + (Bias / (60.0 * 24.0));
                end;
            end;
        end
        else
            J := 1;
        while (J <= Length(Params)) and (Params[J] = ' ') do
           Inc(J);
        FileName := BuildFilePath(Client, Client.Directory , Copy (Params, J, 999));
        if Params = '' then begin
            Answer := msgMdtmSyntax;
            Exit;
        end;
        TriggerEnterSecurityContext(Client);                  { V1.52 AG }
        try
            FExists := IcsFileExistsW(FileName) OR IcsDirExistsW(FileName);  { A. Haas, V1.53 }
        finally
            TriggerLeaveSecurityContext(Client);              { V1.52 AG }
        end;
        if not FExists then
            Answer := WideFormat(msgMdtmNotExists, [FormatResponsePath(Client, FileName)])
        else if FileDT <> 0 then begin     { set file time stamp }
            Allowed := IsPathAllowed(Client, FileName); { AG V1.52 }
            TriggerValidateMfmt(Client, FileName, Allowed);   { angus V1.39 }
            if not Allowed then begin
                Answer := msgStorDisabled;
                Exit;
            end;
            TriggerEnterSecurityContext(Client);              { V1.52 AG }
            try
                if UtcFlag then
                    SuccFlag := UpdateUFileAge (FileName, FileDT)
                else
                    SuccFlag := UpdateFileAge (FileName, FileDT);
            finally
                TriggerLeaveSecurityContext(Client);          { V1.52 AG }
            end;
            if SuccFlag then begin
              { Cached Md5Sum should be updated with a new time and date } { angus V7.09 }
                TriggerMd5Calculated(Client, FileName, '');
                if Client.CurCmdType = ftpcMFMT then    { angus V1.39 }
                    Answer := msgMfmtChangeOK
                else
                    Answer := msgMdtmChangeOK ;
            end
            else
                Answer := msgMdtmChangeFail;
        end
        else if Client.CurCmdType = ftpcMFMT then   { angus V1.39 never returns time }
            Answer := msgMdtmSyntax
        else begin
            TriggerEnterSecurityContext(Client);              { V1.52 AG }
            try
                FileTime := FileUtcStr(FileName);   { return file time stamp }
            finally
                TriggerLeaveSecurityContext(Client);          { V1.52 AG }
            end;
            if Length(FileTime) <> 0 then
                Answer := WideFormat(msgMdtmOk, [FileTime])
            else
                Answer := WideFormat(msgMdtmFailed,
                                 ['UTC File time retrieval failed']) ;
        end;
    except
        on E:Exception do begin
            Answer := WideFormat(msgMdtmChangeFail, [E.Message])
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandMode(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
var
    FreeSpace: Int64;
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;
    if (Params = '') then begin
        Answer := msgModeSyntax;
        Exit;
    end;
    Params := IcsAnsiUpperCaseW (Params);
    if (Params <> 'S') then begin
        Answer := WideFormat(msgModeNotS, [Params]);
      { angus V1.54 }
        if (ftpModeZCompress in Client.Options) and (Params = 'Z') then begin
       { check sufficient space on work volume for compressed files }
            try
                IcsForceDirectoriesW(FZlibWorkDir);
                FreeSpace := GetFreeSpacePathW (FZlibWorkDir);
            except
                FreeSpace := -1;
            end;
            if FZlibMinSpace > FreeSpace then begin   { don't fill volume!! }
                if FreeSpace = -1 then
                    TriggerDisplay(Client, 'Error, working directory volume not available ' +
                                   FZlibWorkDir + ' - ' + GetWindowsErr (GetLastError))
                else
                    TriggerDisplay(Client, 'Insufficient space on ' + FZlibWorkDir +
                     ', need ' + IntToKByte(FZlibMinSpace) + ', free ' + IntToKByte(FreeSpace));
                Client.CurrTransMode := FtpTransModeStream;
            end
            else begin
                Client.CurrTransMode := FtpTransModeZDeflate;
                Answer := WideFormat(msgModeOK, [Params]);
            end;
        end;
        Exit;
    end;
    Client.CurrTransMode := FtpTransModeStream;
    Answer := WideFormat(msgModeOK, [Params]);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandOverflow(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
var
    Buf : array [0..1023] of char;
begin
    Client.CurCmdType := ftpcOVER;
    { Disable receiving }
    Client.Shutdown(0);
    { Flush receive buffer }
    while (Client.Receive(@Buf, SizeOf(buf)) > 0) do;
    { Answer to client }
    Answer := msgOverflow;
    { Will close connection }
    PostMessage(Handle, FMsg_WM_FTPSRV_CLOSE_REQUEST,
                WPARAM(Client.ID), LPARAM(Client));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ [ep] STOU command support                                                   }
{ This code is more or less the same as CommandSTOR, with the addition of     }
{ GetUniqueFileName event triggering to let the user a chance to provide a    }
{ file name.                                                                  }
procedure TFtpServerW.CommandSTOU(
    Client: TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
var
    UniqueName : TFtpString;
    Allowed    : Boolean;
    FilePath   : TFtpString;
begin
    try
        if Client.FtpState <> ftpcReady then begin
            Answer := msgNotLogged;
            Exit;
        end;

        try
            Client.CurCmdType       := ftpcSTOU;
            Client.HasOpenedFile    := FALSE;
            UniqueName              := '';//SlashesToBackSlashes(Params); { V1.52 AG }

            { Fire the GetUniqueFileName event to get the file name  }
            { to be used to store data                               }
            TriggerGetUniqueFileName (Client, UniqueName);

            TriggerEnterSecurityContext(Client);             { V1.52 AG }
            try
                { no file name has been provided, or provided one        }
                { already exists => create one                           }
                if (UniqueName = '') or
                   (IcsFileExistsW(BuildFilePath(Client, Client.Directory,
                                              UniqueName))) then begin
                    UniqueName := IcsExtractFilenameW(CreateUniqueFile(
                                        Client.Directory, 'FTP', ''));
                    if UniqueName = '' then begin
                        Answer := WideFormat(msgStouFailed, ['Error creating unique file']);
                        Exit;
                    end;
                end;
            finally
                TriggerLeaveSecurityContext(Client);         { V1.52 AG }
            end;

            Client.FileName   := UniqueName;
            FilePath          := BuildFilePath(Client, Client.Directory,
                                                     Client.FileName);
            Allowed := IsPathAllowed(Client, FilePath); { V1.52 AG }
            TriggerValidatePut(Client, FilePath, Allowed);
            if not Allowed then begin
                Answer := msgStorDisabled;
                IcsDeleteFileW(FilePath); // delete the created file { V1.52 AG }
                Exit;
            end;
            Client.FilePath := FilePath;
            PrepareStorDataSocket(Client);
            Answer := WideFormat(msgStouSuccess, [UniqueName]);
        except
            on E:Exception do begin
                Answer := WideFormat(msgStouFailed, [E.Message]);
            end;
        end;
    finally
        { check for success 150..159 in passive mode }
        if Client.PassiveMode and (Copy(Answer, 1, 2) <> '15') then begin
            { flag for ClientStorSessionClosed that the error-message was already sent! }
            Client.TransferError    := '';
            Client.AbortingTransfer := TRUE;
            { set up Passive DataSocket.EventHandlers        }
            { otherwise FreeCurrentPasvPort won't be called! }
            PreparePassiveStorDataSocket(Client);
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandFEAT(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;

    try
        Client.CurCmdType := ftpcFEAT;
        Answer := msgFeatFollows + #13#10 +
                  ' HOST'+ #13#10 +             { angus V7.01 }
                  ' SIZE'+ #13#10 +
                  ' REST STREAM'+ #13#10 +      { angus V1.39 (been supported for years) }
                  ' MDTM'+ #13#10 +
                  ' MDTM YYYYMMDDHHMMSS[+-TZ] filename'+ #13#10 +       { angus V1.38 }
                  ' MLST size*;type*;perm*;create*;modify*;'+ #13#10 +  { angus V1.38 }
                  ' MFMT'+ #13#10 +                                     { angus V1.39 }
                  ' MD5'+ #13#10 +                                      { angus V1.39 }
                  ' XCRC "filename" start end'+ #13#10 +                { angus V1.54 }
                  ' XMD5 "filename" start end'+ #13#10 +                { angus V1.54 }
                  ' CLNT'+ #13#10 +                                     { angus V1.54 }
                  ' SITE INDEX;ZONE';                                   { angus V1.54 }
        if Assigned (FOnSiteMsg) then Answer := Answer + ';MSG';         { angus V1.54 }
        if Assigned (FOnSiteExec) then Answer := Answer + ';EXEC';       { angus V1.54 }
        if Assigned (FOnSitePaswd) then Answer := Answer + ';PSWD';      { angus V1.54 }
        if ftpsSiteXmlsd in FOptions then
                        Answer := Answer + ';CMLSD;DMLSD'; { angus V1.54 }
        Answer := Answer + #13#10;
        if Assigned (FOnCombine) then
               Answer := Answer + ' COMB'+ #13#10; { angus V1.54 }
        if ftpModeZCompress in Client.Options then
               Answer := Answer + ' MODE Z'+ #13#10;
        if ftpsSiteXmlsd in FOptions then
               Answer := Answer + ' XCMLSD' + #13#10 +
                                  ' XDMLSD' + #13#10;        { angus V7.01 }
        if ftpsEnableUtf8 in FOptions then
               Answer := Answer + ' UTF8' + #13#10 +
                                  ' LANG ' + FLanguage + #13#10 +
                                  ' OPTS MODE;UTF8;' + #13#10; { angus V7.01 }
    {$IFDEF USE_SSL}
        if Self is TSslFtpServerW then begin     {  V1.48 }
            if Client.FtpSslTypes <> [] then begin             { V1.47 }
                if not (ftpImplicitSsl in Client.FtpSslTypes) then begin
                    Answer := Answer + ' AUTH ';
                if ftpAuthTls in Client.FtpSslTypes then
                    Answer := Answer + 'TLS;';
                if ftpAuthSsl in Client.FtpSslTypes then
                    Answer := Answer + 'SSL;';
                if ftpAuthTlsP in Client.FtpSslTypes then
                    Answer := Answer + 'TLS-P;';
                if ftpAuthTlsC in Client.FtpSslTypes then
                    Answer := Answer + 'TLS-C;';
                Answer := Answer +  #13#10 +
                          ' CCC'+ #13#10;
            end;
            Answer := Answer + ' PROT C;P;' + #13#10 +
                               ' PBSZ'      + #13#10;
            end;
        end;
    {$ENDIF}
        Answer := Answer + msgFeatFollowDone;
    except
        on E:Exception do begin
            Answer := WideFormat(msgFeatFailed, [E.Message]);
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.SetPasvPortRangeSize(const NewValue: Integer);
var
    OldValue : Integer;
    TablePtr : PBoolean;
    I        : Integer;
begin
    if (NewValue < 0) or (NewValue > 65535) then
        raise ERangeError.CreateFmt('Invalid PasvPortRangeSize %d.', [NewValue]);
    if FPasvPortRangeSize = NewValue then
        Exit;
    OldValue := FPasvPortRangeSize;

    { If we reduce the range, we must be sure to not affect any port in use }
    if NewValue < OldValue then begin
        { Check if any port is used before changing }
        TablePtr := IncPtr(FPasvPortTable, SizeOf(Boolean) * NewValue); { AG V6.02 }
        I        := NewValue;
        while I < OldValue do begin
            if TablePtr^ then
                raise Exception.Create('Unable to change PasvPortRangeSize ' +
                                       'when port is in use.');
            Inc(I);
            Inc(TablePtr);
        end;
    end;
    ReallocMem(FPasvPortTable, NewValue);
    FPasvPortTableSize := NewValue;
    FPasvPortRangeSize := NewValue;
    if OldValue >= NewValue then
        Exit;

    TablePtr := IncPtr(FPasvPortTable, SizeOf(Boolean) * OldValue); { AG V6.02 }
    while OldValue < NewValue do begin
        TablePtr^ := FALSE;
        Inc(TablePtr);
        Inc(OldValue);
    end;
    FPasvNextNr := 0;  { angus V1.56 }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.SetPasvPortRangeStart(const NewValue: Integer);
var
    TablePtr : PBoolean;
    I        : Integer;
begin
    if (NewValue < 0) or (NewValue > 65535) then
        raise ERangeError.CreateFmt('Invalid PasvPortRangeStart %d.', [NewValue]);
    if FPasvPortRangeStart = NewValue then
        Exit;
    { Check if any port is used before changing }
    TablePtr := FPasvPortTable;
    I        := 0;
    while I < FPasvPortRangeSize do begin
        if TablePtr^ then
            raise Exception.Create('Unable to change PasvPortRangeStart ' +
                                   'when port is in use.');
        Inc(I);
        Inc(TablePtr);
    end;

    { Now we can change PasvPortRangeStart }
    FPasvPortRangeStart := NewValue;
    FPasvNextNr := 0;  { angus V1.56 }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandMLST(   { angus V1.38 }
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
var
    F          : TIcsSearchRecW;
    FileName   : TFtpString;
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;

    Client.CurCmdType := ftpcMLST;
    if Params = '' then Params := '*.*';   { current directory }
    FileName := BuildFilePath(Client, Client.Directory, Params);
    if not IsPathAllowed(Client, FileName) then begin  { V1.52 AG }
        Answer := msgMlstDenied;
        Exit;
    end;
    TriggerEnterSecurityContext(Client);                    { V1.52 AG }
    try
        if IcsFindFirstW(FileName, faArchive + faDirectory, F) = 0 then
            Answer := msgMlstFollows + Params + #13#10 +
                      ' ' + FormatFactsDirEntry(F, F.Name) + #13#10 + { angus 1.54 added name }
                      msgMlstFollowDone
        else
            Answer := WideFormat(msgMlstNotExists, [Params]);
        IcsFindCloseW(F);
    finally
        TriggerLeaveSecurityContext(Client);                { V1.52 AG }
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandMLSD(   { angus V1.38 }
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;

    Client.CurCmdType := ftpcMLSD;
    CommandDirectory2(Client, KeyWord, Params, Answer, ListTypeFacts);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *} { angus V1.54 }
procedure FileMD5OnProgress(
    Obj: TObject;
    Count: Int64;
    var Cancel: Boolean);
begin
    Cancel := (Obj as TFtpCtrlSocketW).AbortingTransfer;
    (Obj as TFtpCtrlSocketW).LastTick := IcsGetTickCountX;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandMD5(   { angus V1.39 }
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
var
    FileName  : TFtpString;
    Md5Sum    : TFtpString;
    Allowed   : Boolean;
    FileSize  : TFtpBigInt; { AG V1.50 }
    Offset    : Integer;
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;
    Md5Sum  := '';
    Client.HashStartPos := 0;
    Client.HashEndPos := 0;

    try
        if Keyword = 'XMD5' then begin    { angus V1.54 }
            Client.CurCmdType := ftpcXMD5;
            Offset := 1;
            FileName := IcsScanGetNextArg(Params, Offset);                     { keep file name }
            Client.HashStartPos := atoi64(IcsScanGetNextArg (Params, Offset));  { start position, if any }
            Client.HashEndPos := atoi64(IcsScanGetNextArg (Params, Offset));    { end position, if any }
            if (Client.HashStartPos > 0) and (Client.HashEndPos = 0) then begin
                Client.HashEndPos := Client.HashStartPos;  { single argument is end position }
                Client.HashStartPos := 0;
            end ;
        end
        else begin
            Client.CurCmdType := ftpcMD5;
            FileName := Params;
        end;
        FileName := BuildFilePath(Client, Client.Directory, FileName);
        Allowed := IsPathAllowed(Client, FileName); { AG V1.52 }
        { Ideally the MD5 sum is being retrieved from a cache or file so it's not  }
        { done repeatedly, if left blank we'll do it here. MD5 may be used to check}
        { uploaded/downloaded files, so keep a timestamp with the sum.             }
        TriggerCalculateMd5(Client, FileName, Md5Sum, Allowed);
        if not Allowed then begin
             Answer := msgRetrDisabled;
             Exit;
        end;
        if Md5Sum = '' then begin
            FileSize := IcsGetFileSizeW(FileName); { AG V1.50 }
            if FileSize = -1 then begin { AG V1.50 }
                TriggerMd5Calculated(Client, FileName, Md5Sum); { AG V1.50 }
                Answer := WideFormat(msgMd5NotFound, [Params]);
                Exit;
            end ;
            { Calculate a 32-byte MD5 sum. If file size is small we may use }
            { a blocking function.                                 AG V1.50 }
            if (FMd5UseThreadFileSize = 0) or
                               (FileSize < FMd5UseThreadFileSize) then begin
                Md5Sum := FtpFileMD5(FileName, Client, FileMD5OnProgress,
                        Client.HashStartPos, Client.HashEndPos, Client.FileModeRead); { angus V1.57, V7.07 }
                TriggerMd5Calculated(Client, FileName, IcsAnsiUpperCaseW(Md5Sum));
            end
            else begin
                { Use a thread to calculate MD5 checksum which otherwise }
                { would block the server.                       AG V1.50 }
                if Client.ProcessingThread <> nil then begin
                    //TriggerMd5Calculated(Client, FileName, '');
                    Answer := WideFormat(msgMd5Failed, [Params]);
                    Exit;
                end ;
                { AG V1.50 }
                TriggerDisplay(Client, 'Using thread to calculate MD5Sum');  { angus V1.54 }
                Client.ProcessingThread := TClientProcessingThreadW.Create(TRUE);
                Client.ProcessingThread.Client := Client;
                Client.ProcessingThread.InData := FileName;
                Client.ProcessingThread.Params := Params;
                Client.ProcessingThread.Keyword := Keyword;
                Client.ProcessingThread.OnTerminate := ClientProcessingThreadTerminate;
                Client.ProcessingThread.FreeOnTerminate := TRUE;
            {$IFDEF COMPILER14_UP}
                Client.ProcessingThread.Start;
            {$ELSE}
                Client.ProcessingThread.Resume;
            {$ENDIF}
                { Since answer is sent later when the thread returns we need }
                { to set this flag!                                          }
                Client.AnswerDelayed := TRUE;
                exit;                                                { angus V1.54 }
            end;
        end;
        Client.LastTick := IcsGetTickCountX;                         { angus V1.54 }
        if Md5Sum = '' then                                          { angus V1.54 }
             Answer := WideFormat(msgMd5Failed, [Params])
        else begin
            if Client.CurCmdType = ftpcXMD5 then
                Answer := WideFormat(msgCrcOk , [IcsAnsiUpperCaseW (Md5Sum)])
            else
                Answer := WideFormat(msgMd5Ok, [Params, IcsAnsiUpperCaseW (Md5Sum)]);
        end;
    except
        on E:Exception do begin
            Answer := WideFormat(msgMd5Failed, [E.Message]);
        end;
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandXCRC (  { angus V1.54 }
     Client      : TFtpCtrlSocketW;
     var Keyword : TFtpString;
     var Params  : TFtpString;
     var Answer  : TFtpString);
var
    FileName  : TFtpString;
    Crc32b    : TFtpString;
    Allowed   : Boolean;
    FileSize  : TFtpBigInt;
    Offset    : Integer;
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;
    Client.CurCmdType := ftpcXCRC;
    Crc32b  := '';

    try
      { get file name and optional start and end arguments }
        Offset := 1;
        FileName := IcsScanGetNextArg(Params, Offset);             { keep file name }
        Client.HashStartPos := atoi64(IcsScanGetNextArg (Params, Offset));  { start position, if any }
        Client.HashEndPos := atoi64(IcsScanGetNextArg (Params, Offset));    { end position, if any }
        if (Client.HashStartPos > 0) and (Client.HashEndPos = 0) then begin
            Client.HashEndPos := Client.HashStartPos;  { single argument is end position }
            Client.HashStartPos := 0;
        end ;
        FileName := BuildFilePath(Client, Client.Directory, FileName);
        Allowed := IsPathAllowed(Client, FileName);
        { Ideally the CRC sum is being retrieved from a cache or file so it's not  }
        { done repeatedly, if left blank we'll do it here. CRC may be used to check}
        { uploaded/downloaded files, so keep a timestamp with the sum.             }
        TriggerCalculateCrc(Client, FileName, Crc32b, Allowed);
        if not Allowed then begin
             Answer := msgRetrDisabled;
             Exit;
        end;
        if Crc32b = '' then begin
            FileSize := IcsGetFileSizeW(FileName);
            if FileSize = -1 then begin
                TriggerCrcCalculated(Client, FileName, Crc32b);
                Answer := WideFormat(msgMd5NotFound, [Params]);
                Exit;
            end ;
            { Calculate a 32-byte CRC sum. If file size is small we may use }
            { a blocking function.                                          }
            if (FMd5UseThreadFileSize = 0) or
                                   (FileSize < FMd5UseThreadFileSize) then begin
                Crc32b := FtpFileCRC32B(FileName, Client, FileMD5OnProgress,
                        Client.HashStartPos, Client.HashEndPos, Client.FileModeRead); { angus V1.57, V7.07 }
                TriggerCrcCalculated(Client, FileName, IcsAnsiUpperCaseW(Crc32b));
            end
            else begin
                { Use a thread to calculate CRC checksum which otherwise }
                { would block the server.                        }
                if Client.ProcessingThread <> nil then begin
                    Answer := WideFormat(msgCrcFailed, [Params]);
                    Exit;
                end ;
                TriggerDisplay(Client, 'Using thread to calculate CRC32B');
                Client.ProcessingThread := TClientProcessingThreadW.Create(TRUE);
                Client.ProcessingThread.Client := Client;
                Client.ProcessingThread.InData := FileName;
                Client.ProcessingThread.Params := Params;
                Client.ProcessingThread.Keyword := Keyword;
                Client.ProcessingThread.OnTerminate := ClientProcessingThreadTerminate;
                Client.ProcessingThread.FreeOnTerminate := TRUE;
            {$IFDEF COMPILER14_UP}
                Client.ProcessingThread.Start;
            {$ELSE}
                Client.ProcessingThread.Resume;
            {$ENDIF}
                { Since answer is sent later when the thread returns we need }
                { to set this flag!                                          }
                Client.AnswerDelayed := TRUE;
                exit;
            end;
        end;
        Client.LastTick := IcsGetTickCountX;
        if Crc32b = '' then
             Answer := WideFormat(msgCrcFailed, [Params])
        else
             Answer := WideFormat(msgCrcOk , [IcsAnsiUpperCaseW (Crc32b)]);
    except
        on E:Exception do begin
            Answer := WideFormat(msgMd5Failed, [E.Message]);
        end;
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandALLO (  { angus V1.54 short for allocation }
     Client      : TFtpCtrlSocketW;
     var Keyword : TFtpString;
     var Params  : TFtpString;
     var Answer  : TFtpString);
var
    Size, FreeSpace : Int64;
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;
    Client.CurCmdType := ftpcALLO;
    Answer := '';
  { may need to check client account for disk space allocation remaining }
    TriggerValidateAllo (Client, Params, Answer);
    if Answer <> '' then exit;

  { otherwise check for free space on drive with working directory }
    try
        Size := atoi64(Params);
        FreeSpace := GetFreeSpacePathW (BuildFilePath(Client, Client.Directory, '')); { angus V7.08 support virtual path }
        if FreeSpace < 0 then
           Answer := WideFormat(msgAlloOk, [0])   { failed, but pretend Ok for backward compatibility }
        else if (Size = 0) then
            Answer := msgAlloFail             { invalid size }
        else begin
            if (Size + FAlloExtraSpace) < FreeSpace then  { don't allow files to fill drive }
                Answer := WideFormat(msgAlloOk, [FreeSpace])
            else
                Answer := WideFormat(msgAlloFull, [FreeSpace]);
        end;
    except
        on E:Exception do begin
            Answer := msgAlloFail;
        end;
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandCLNT (  { angus V1.54 }
      Client      : TFtpCtrlSocketW;
      var Keyword : TFtpString;
      var Params  : TFtpString;
      var Answer  : TFtpString);
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;
    Client.CurCmdType := ftpcCLNT;
    Client.ClntStr := Params;
    Answer := msgNotedOK;
    TriggerClntStr (Client, Params, Answer);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandOPTS (  { angus V1.54 }
      Client      : TFtpCtrlSocketW;
      var Keyword : TFtpString;
      var Params  : TFtpString;
      var Answer  : TFtpString);
var
    Arg: TFtpString;
    Offset: Integer;
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;
    Answer := WideFormat(msgOptsFailed, [Params]);
    Params := IcsAnsiUpperCaseW (Params);
    Offset := 1;
    Arg := IcsScanGetNextArg (Params, Offset);
    if Arg = 'MODE' then begin
        Arg := IcsScanGetNextArg (Params, Offset);
        if Arg <> 'Z' then exit;
        Arg := IcsScanGetNextArg (Params, Offset);
        if Arg <> 'LEVEL' then exit;
        Arg := IcsScanGetNextArg (Params, Offset);
        if Arg = '' then exit;
        Offset := atoi (Arg);
        if (Offset >= FZlibMinLevel) and (Offset <= FZlibMaxLevel) then begin
            Client.ZReqLevel := Offset;
            Answer := WideFormat(msgOtpsOK, ['MODE Z LEVEL set to ' + Arg]);
        end;
    end
    else if ((Arg = 'UTF8') or (Arg = 'UTF-8')) then begin       { angus V7.01 }
        if NOT (ftpsEnableUtf8 in FOptions) then begin
            Answer := WideFormat(msgOptsFailed, ['UTF8 not supported']);
            exit;
        end ;
        Arg := IcsScanGetNextArg (Params, Offset);
        if Arg = 'ON' then begin
            Client.Options := Client.Options + [ftpUtf8On];
            Answer := WideFormat(msgOtpsOK, ['UTF8 ON']);
        end
        else if Arg = 'OFF' then begin
            Client.Options := Client.Options - [ftpUtf8On];
            Answer := WideFormat(msgOtpsOK, ['UTF8 OFF']);
        end;
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandSitePaswd (  { angus V1.54 }
      Client      : TFtpCtrlSocketW;
      var Keyword : TFtpString;
      var Params  : TFtpString;
      var Answer  : TFtpString);
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;
    Client.CurCmdType := ftpcSitePaswd;
    Answer := msgSiteFailed;
    TriggerSitePaswd (Client, Params, Answer);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandSiteExec (  { angus V1.54 }
      Client      : TFtpCtrlSocketW;
      var Keyword : TFtpString;
      var Params  : TFtpString;
      var Answer  : TFtpString);
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;
    Client.CurCmdType := ftpcSiteExec;
    Answer := msgSiteFailed;
    TriggerSiteExec (Client, Params, Answer);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandSiteIndex (  { angus V1.54 }
      Client      : TFtpCtrlSocketW;
      var Keyword : TFtpString;
      var Params  : TFtpString;
      var Answer  : TFtpString);
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;
    Client.CurCmdType := ftpcSiteIndex;
    CommandDirectory2(Client, Keyword, Params, Answer, ListTypeName);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandSiteZone (  { angus V1.54 }
      Client      : TFtpCtrlSocketW;
      var Keyword : TFtpString;
      var Params  : TFtpString;
      var Answer  : TFtpString);
var
    mins: integer;
    S: TFtpString;
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;
    Client.CurCmdType := ftpcSiteZone;
    mins := GetLocalBiasUTC;
    S := IntToStr (mins);
    if mins >= 0 then S := '+' + S;
    Answer := WideFormat(msgSiteZone, [S])
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandSiteMsg (  { angus V1.54 }
      Client      : TFtpCtrlSocketW;
      var Keyword : TFtpString;
      var Params  : TFtpString;
      var Answer  : TFtpString);
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;
    Client.CurCmdType := ftpcSiteMsg;
    Answer := msgSiteFailed;
    TriggerSiteMsg (Client, Params, Answer);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandSiteCmlsd (  { angus V1.54 }
      Client      : TFtpCtrlSocketW;
      var Keyword : TFtpString;
      var Params  : TFtpString;
      var Answer  : TFtpString);
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;
    Client.CurCmdType := ftpcSiteCmlsd;
    CommandDirectory2(Client, KeyWord, Params, Answer, ListTypeFacts);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandSiteDmlsd (  { angus V1.54 }
      Client      : TFtpCtrlSocketW;
      var Keyword : TFtpString;
      var Params  : TFtpString;
      var Answer  : TFtpString);
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;
    Client.CurCmdType := ftpcSiteDmlsd;
    CommandDirectory2(Client, KeyWord, Params, Answer, ListTypeFacts);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandComb (  { angus V1.54 }
      Client      : TFtpCtrlSocketW;
      var Keyword : TFtpString;
      var Params  : TFtpString;
      var Answer  : TFtpString);
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;
    Client.CurCmdType := ftpcComb;
    Answer := WideFormat(msgCmdUnknown, ['COMB']);
    TriggerCombine (Client, Params, Answer);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandXCmlsd (  { angus V7.01 }
      Client      : TFtpCtrlSocketW;
      var Keyword : TFtpString;
      var Params  : TFtpString;
      var Answer  : TFtpString);
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;
    Client.CurCmdType := ftpcXCMLSD;
    CommandDirectory2(Client, KeyWord, Params, Answer, ListTypeFacts);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandXDmlsd (  { angus V7.01 }
      Client      : TFtpCtrlSocketW;
      var Keyword : TFtpString;
      var Params  : TFtpString;
      var Answer  : TFtpString);
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;
    Client.CurCmdType := ftpcXDMLSD;
    CommandDirectory2(Client, KeyWord, Params, Answer, ListTypeFacts);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandHost (  { angus V7.01 }
      Client      : TFtpCtrlSocketW;
      var Keyword : TFtpString;
      var Params  : TFtpString;
      var Answer  : TFtpString);
var
    Allowed: boolean;
begin
    if Client.FtpState <> ftpcWaitingUserCode then begin  // host is only allowed before logon
        Answer := msgHostTooLate;
        Exit;
    end;
{ expecting HOST ftp.domain.com or HOST [123.123.123.123]   }
    Params := Trim (IcsAnsiLowerCaseW (Params));
    WideFormat(msgHostSyntax, [Params]);
    if Length (Params) <= 2 then exit; // host is only allowed before logon
    if Params [1] = '[' then begin
        if Params [Length (Params)] <> ']' then exit ;
    end;
    Client.CurCmdType := ftpcHost;
    Allowed := false;
    TriggerHost(Client, Params, Allowed);
    if not Allowed then begin
        Answer := msgHostUnknown;   { could be msgHostUnavail }
        Exit;
    end;
    Client.Host := Params;
    Answer := msgHostOK;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandRein (  { angus V7.01 }
      Client      : TFtpCtrlSocketW;
      var Keyword : TFtpString;
      var Params  : TFtpString;
      var Answer  : TFtpString);
var
    Allowed: boolean;
begin
    Client.CurCmdType := ftpcRein;
    Allowed := false;
    TriggerRein(Client, Allowed);
    if not Allowed then begin
        Answer := msgReinUnavail;
        Exit;
    end;

{ reinialise session, as if not yet logged on }
    Client.FtpState := ftpcWaitingUserCode;
// angus pending, more stuff from ServerClientConnect
    Client.Host := '';
    Client.Lang := '' ;
    if (ftpsEnableUtf8 in FOptions) and (ftpsDefaultUtf8On in FOptions) then
        Client.Options := Client.Options + [ftpUtf8On]
    else
        Client.Options := Client.Options - [ftpUtf8On];
    Answer := msgReinOK;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandLang (  { angus V7.01 }
      Client      : TFtpCtrlSocketW;
      var Keyword : TFtpString;
      var Params  : TFtpString;
      var Answer  : TFtpString);
var
    Allowed: boolean;
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;
    Params := Trim (IcsAnsiUpperCaseW (Params));
    Client.CurCmdType := ftpcLang;
    Allowed := (Pos (Params, FLanguage) > 0) OR (Length (Params) = 0);
    TriggerLang(Client, Params, Allowed);
    if not Allowed then begin
        Answer := WideFormat(msgLangUnknown, [Params]);
        Exit;
    end;
    if Length (Params) = 0 then Params := FLanguage;
    Client.Lang := Params;
    Answer := WideFormat(msgLangOK, [Params]);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandEPRT(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
var
    I       : Integer;
    N       : LongInt;
    Delim   : WideChar;
    Proto   : Integer;
    AFamily : TSocketFamily;
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;
    if Client.FEpsvAllArgReceived then begin
        Answer := Format(msgEPSVALLDeny, [Keyword]);
        Exit;
    end;

    try
        Client.CurCmdType := ftpcEPRT;
        Proto             := 0;
        Client.DataAddr   := '';
        Client.DataPort   := '';

        if Length(Params) > 0 then
        begin
            Delim := Params[1];
            if not (Ord(Delim) in [33..126]) then
            begin
                Answer := msgSyntaxParam;
                Exit;
            end;
            N := 2;
            { Get proto }
            for I := N to Length(Params) do
            begin
                if Params[I] = Delim then
                begin
                    Proto := atoi(Copy(Params, N, (I - N)));
                    N := I + 1;
                    Break;
                end;
            end;
            { Check proto }
            if not(((Proto = 1) and (Client.CurrentSocketFamily = sfIPv4)) or
                   ((Proto = 2) and (Client.CurrentSocketFamily = sfIPv6))) then
            begin
                if Client.CurrentSocketFamily = sfIPv6 then
                    Answer := Format(msgInvalidProto, ['2'])
                else
                    Answer := Format(msgInvalidProto, ['1']);
                Exit;
            end;

            { Get address }
            for I := N to Length(Params) do
            begin
                if Params[I] = Delim then
                begin
                    Client.DataAddr := Copy(Params, N, (I - N));
                    N := I + 1;
                    Break;
                end;
            end;
            { Check address }
            if (not WSocketIsIP(Client.DataAddr, AFamily)) then
            begin
                Answer := msgSyntaxParam;
                Exit;
            end
            else if ((Proto = 1) and (AFamily <> sfIPv4)) or
               ((Proto = 2) and (AFamily <> sfIPv6)) then
            begin
                Answer := msgSyntaxParam;
                Exit;
            end;
            {Get port }
            for I := N to Length(Params) do
            begin
                if Params[I] = Delim then
                begin
                    Client.DataPort := Copy(Params, N, (I - N));
                    Break;
                end;
            end;
            { Check port }
            N := atoi(Client.DataPort);
            if (N < 1) or (N > 65535) then
                Answer := msgSyntaxParam
            else
                Answer := msgPortSuccess;

            { Remove a possible scope ID. It is IMO a bug on the client  }
            { side. Filezilla sends it with link local addresses.        }
            { Or should we return a syntax error?                        }
            if (Proto = 2) then
            begin
                N := Pos('%', Client.DataAddr);
                if N > 0 then
                    Client.DataAddr := Copy(Client.DataAddr, 1, N - 1);
            end;
        end
        else begin
            Answer := msgSyntaxParam;
        end;
    except
        Answer := msgPortFailed;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.CommandEPSV(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
var
    saddr     : TSockAddrIn6;
    saddrlen  : Integer;
    DataPort  : Integer;
    Proto     : Integer;
    IPAddr    : TInAddr6;
begin
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;

    try
        Proto := 0;
        if Params = 'ALL' then
            Client.FEpsvAllArgReceived := TRUE
        else if (Params <> '') then
        begin
            Proto := atoi(Params);
            if Proto = 0 then
            begin
                Answer := msgSyntaxParam;
                Exit;
            end;
            if not(((Proto = 1) and (Client.CurrentSocketFamily = sfIPv4)) or
                   ((Proto = 2) and (Client.CurrentSocketFamily = sfIPv6))) then
            begin
                if Client.CurrentSocketFamily = sfIPv6 then
                    Answer := Format(msgInvalidProto, ['2'])
                else
                    Answer := Format(msgInvalidProto, ['1']);
                Exit;
            end;
        end;

        { Get our IP address from our control socket }
        saddrlen := SizeOf(saddr);
        Client.GetSockName(PSockAddr(@saddr)^, saddrlen);
        IPAddr   := saddr.sin6_addr;

        if Client.PassiveMode then
            FreeCurrentPasvPort(Client);

        Client.DataSocket.Close;
        if Proto = 0 then
        begin
            if saddr.sin6_family = AF_INET6 then
                Client.DataSocket.Addr  := ICS_ANY_HOST_V6
            else
                Client.DataSocket.Addr  := ICS_ANY_HOST_V4;
        end
        else begin
            if Proto = 1 then
                Client.DataSocket.Addr  := ICS_ANY_HOST_V4
            else
                Client.DataSocket.Addr  := ICS_ANY_HOST_V6;
        end;

        Client.DataSocket.Port  := GetNextAvailablePasvPort; { '0';          Any port  }
        if Client.DataSocket.Port = '' then
            raise Exception.Create('No available PASV Ports');

        Client.DataSocket.Proto := 'tcp';
        Client.DataSocket.OnSessionAvailable := ClientPassiveSessionAvailable;
        Client.DataSocket.OnSessionConnected := nil;
        Client.DataSocket.OnSessionClosed    := nil;
        Client.DataSocket.OnDataAvailable    := nil;
        Client.DataSocket.ComponentOptions   := [wsoNoReceiveLoop];
        Client.DataSocket.ExclusiveAddr      := FExclusiveAddr;      { V8.37 }
        Client.DataSocket.SocketErrs         := FSocketErrs;         { V8.37 }
        Client.DataSocket.Listen;

        { Get the port assigned by winsock }
        saddrlen := SizeOf(saddr);
        Client.DataSocket.GetSockName(PSockAddr(@saddr)^, saddrlen);
        DataPort := WSocket_ntohs(saddr.sin6_port);
        Answer := Format(msgEPSVOk, [DataPort]);
        Client.PassiveMode      := TRUE;
        Client.PassiveStart     := FALSE;
        Client.PassiveConnected := FALSE;
    except
        on E:Exception do begin
            Answer := Format(msgPasvExcept, [E.Message]);
            try
                Client.DataSocket.Close;
            except
                { Ignore any exception here }
            end;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{$IFDEF NOFORMS}
{ This function is a callback function. It means that it is called by       }
{ windows. This is the very low level message handler procedure setup to    }
{ handle the message sent by windows (winsock) to handle messages.          }
function FtpSrvWindowProc(
    ahWnd   : HWND;
    auMsg   : Integer;
    awParam : WPARAM;
    alParam : LPARAM): Integer; stdcall;
var
    Obj    : TObject;
    MsgRec : TMessage;
begin
    { At window creation asked windows to store a pointer to our object     }
    Obj := TObject(GetWindowLong(ahWnd, 0));

    { If the pointer doesn't represent a TFtpServerW, just call the default procedure}
    if not (Obj is TFtpServerW) then
        Result := DefWindowProc(ahWnd, auMsg, awParam, alParam)
    else begin
        { Delphi use a TMessage type to pass parameter to his own kind of   }
        { windows procedure. So we are doing the same...                    }
        MsgRec.Msg    := auMsg;
        MsgRec.wParam := awParam;
        MsgRec.lParam := alParam;
        { May be a try/except around next line is needed. Not sure ! }
        TFtpServerW(Obj).WndProc(MsgRec);
        Result := MsgRec.Result;
    end;
end;


{$ENDIF}


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TFtpServerW.GetMultiListenIndex: Integer;
begin
  if Assigned(FSocketServer) then
        Result := FSocketServer.MultiListenIndex
    else
        Result := -1;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TFtpServerW.GetMultiListenSockets: TWSocketMultiListenCollection;
begin
    if Assigned(FSocketServer) then
        Result := FSocketServer.MultiListenSockets
    else
        Result := nil;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.SetMultiListenSockets(
  const Value: TWSocketMultiListenCollection);
begin
    if Assigned(FSocketServer) then
        FSocketServer.MultiListenSockets := Value;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{$IFNDEF NO_DEBUG_LOG}
function TFtpServerW.GetIcsLogger: TIcsLogger;                         { V1.46 }
begin
    Result := FSocketServer.IcsLogger;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.SetIcsLogger(const Value: TIcsLogger);           { V1.46 }
begin
    FSocketServer.IcsLogger := Value;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TFtpServerW.CheckLogOptions(const LogOption: TLogOption): Boolean; { V1.46 }
begin
    Result := Assigned(IcsLogger) and (LogOption in IcsLogger.LogOptions);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.DebugLog(LogOption: TLogOption; const Msg: string);  { V1.46 }
begin
    if Assigned(IcsLogger) then
        IcsLogger.DoDebugLog(Self, LogOption, Msg);
end;
{$ENDIF}

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.SetOnBgException(const Value: TIcsBgExceptionEvent); { V7.15 }
begin
    if Assigned(FSocketServer) then
        FSocketServer.OnBgException := Value;
    inherited;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.ClientProcessingThreadTerminate(Sender: TObject); { AG V1.50 }
var
    Answer    : TFtpString;
    AThread   : TClientProcessingThreadW;
    Params    : TFtpString;
    Data      : TWSocket;
begin
    AThread := TClientProcessingThreadW(Sender);
    if IsClient(AThread.Client) and
       (AThread.Client.ID = AThread.ClientID) then begin
        AThread.Client.ProcessingThread := nil;
        if AThread.Client.State <> wsConnected then
            Exit;

        AThread.Client.LastTick := IcsGetTickCountX;                          { angus V1.54 }
        if (AThread.Keyword = 'MD5') or (AThread.Keyword = 'XMD5') then begin { angus V1.54 }
            if AThread.OutData = '' then
                Answer := WideFormat(msgMd5Failed, [AThread.Params])
            else begin
                if (AThread.Keyword = 'XMD5') then                            { angus V1.54 }
                    Answer := WideFormat(msgCrcOk, [IcsAnsiUpperCaseW (AThread.OutData)])
                else
                    Answer := WideFormat(msgMd5Ok, [AThread.Params,
                                                IcsAnsiUpperCaseW (AThread.OutData)]);
            end;
            if Assigned(FOnMd5Calculated) then
                FOnMd5Calculated(Self, AThread.Client,
                                 AThread.InData, IcsAnsiUpperCaseW(AThread.OutData));
        end
        else if (AThread.Keyword = 'XCRC') then begin { angus V1.54 }
            if AThread.OutData = '' then
                Answer := WideFormat(msgCrcFailed, [AThread.Params])
            else
                Answer := WideFormat(msgCrcOk, [IcsAnsiUpperCaseW (AThread.OutData)]);
            if Assigned(FOnCrcCalculated) then
                FOnCrcCalculated(Self, AThread.Client,
                                 AThread.InData, IcsAnsiUpperCaseW(AThread.OutData));
        end
        else if (AThread.Keyword = 'DIRECTORY') then begin { angus V1.54 }
            with AThread.Client do begin
                Params := AThread.InData;
                try
                    if AThread.AuxData <> '' then                           { AG V8.03 }
                        TriggerDisplay(AThread.Client, AThread.AuxData);    { AG V8.03 }
                    TriggerAlterDirectory(AThread.Client, Params,
                                            (DirListType <> ListTypeName));
                    DataStream.Seek(0, 0);
                    FilePath := '';
                    if AThread.OutData <> AThread.Keyword then
                    begin
                        Answer := WideFormat(msgDirFailed, ['Thread Processing Error']);
                        CloseFileStreams(AThread.Client);      { angus V1.54 }
                    end
                 { see if returning listing on control socket instead of data socket }
                    else if CurCmdType in [ftpcSiteIndex, ftpcSiteCmlsd, ftpcXCMLSD] then begin   { angus 7.01 }
                        DataStreamReadString(UnicodeString (Answer), DataStream.Size, CurrentCodePage); { AG 7.02 } { angus 7.02W  }
                        if CurCmdType = ftpcSiteIndex then
                             Answer := WideFormat(msgIndexFollows, [Params]) +
                                                             #13#10 + Answer + msgIndexDone
                        else if CurCmdType in [ftpcSiteCmlsd, ftpcXCMLSD] then   { angus 7.01 }
                             Answer := msgMlstFollows + #13#10 + Answer + msgMlstFollowDone;
                        CloseFileStreams(AThread.Client);      { angus V1.54 }
                    end
                    else
                    begin
                        Answer := msgDirOpen;
                        AThread.Client.AnswerDelayed := FALSE;
                        DoStartSendData(AThread.Client, Answer);   { angus V1.54 added Answer }
                        if AThread.Client.AnswerDelayed then Exit; { about to compress stream }
                    end;
                except
                    on E:Exception do begin
                        Answer := WideFormat(msgDirFailed, [E.Message])
                    end;
                end;

             { check for success 150..159 in passive mode }
                if (HasOpenedFile) and (PassiveMode) and
                                                    (Copy(Answer, 1, 2) <> '15') then begin
                    { flag for ClientRetrSessionClosed that the error-message was already sent! }
                    TransferError    := '';
                    AbortingTransfer := TRUE;
                    { set up Passive DataSocket.EventHandlers        }
                    { otherwise FreeCurrentPasvPort won't be called! }
                    PreparePassiveRetrDataSocket(AThread.Client);
                end;
            end;
        end
           { angus V1.54 }
        else if (AThread.Keyword = 'COMPRESS') then begin
             if AThread.OutData = '' then begin
                TriggerDisplay(AThread.Client, AThread.Client.FilePath + ' took ' +
                         IntToStr(IcsElapsedMsecs(AThread.StartTick)) + 'ms,' +
                                                         AThread.Client.ZCompInfo);
                if AThread.Client.ZCompFileDelete then
                                    TriggerUpCompressedFile(AThread.Client);
                Answer := AThread.InData;
                AThread.Client.AnswerDelayed := FALSE;
                PostMessage(Handle, FMsg_WM_FTPSRV_START_SEND, 0,
                                                     LPARAM(AThread.Client));
            end
            else begin  { compress failed }
                CloseFileStreams(AThread.Client);
                Answer := AThread.OutData;
            end;
        end
        else if (AThread.Keyword = 'DECOMPRESS') then begin
            if AThread.OutData = '' then begin
                TriggerDisplay(AThread.Client, AThread.Client.FilePath + ' took ' +
                    IntToStr(IcsElapsedMsecs(AThread.StartTick)) + 'ms,' +
                                                         AThread.Client.ZCompInfo);
                Answer := AThread.InData + AThread.Client.ZCompInfo;
                CloseFileStreams(AThread.Client);
                Data := TWSocket(AThread.Sender);
                TriggerStorSessionClosed(AThread.Client, Data, 0);
            end
            else begin  { decompress failed }
                CloseFileStreams(AThread.Client);
                Answer := AThread.OutData;
            end;
        end
        else
            Answer := Format('500 Executing command %s failed', [AThread.Keyword]);
        AThread.Client.AnswerDelayed := FALSE;  { angus V1.54 }
        SendAnswer(AThread.Client, Answer);
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpServerW.EventTimerOnTimer (Sender : TObject); { angus V1.54 }
var
    Client   : TFtpCtrlSocketW;
    I        : integer;
    Timeout  : integer;
    Duration : integer;
    Abort    : boolean ;
    CurTicks : LongWord;
begin
    FEventTimer.Enabled := false;
    try
        if FSocketServer.ClientCount = 0 then exit;                              { no clients }
        CurTicks := IcsGetTickCountX; {  V1.56 AG }
        for I := 0 to Pred (FSocketServer.ClientCount) do begin
            Client := FSocketServer.Client[I] as TFtpCtrlSocketW;
            if Client.FSessionClosedFlag then Continue;  { Client will close soon AG }

         { V7.06 angus - failed authentication, send delayed answer to slow to
              failed login attempts, closing connection after MaxAttempts }
            if Client.FtpState = ftpcFailedAuth then begin
                if IcsTestTrgTick (Client.DelayAnswerTick) then begin
                    Client.DelayAnswerTick := TriggerDisabled;
                    Client.FtpState := ftpcWaitingUserCode;
                    if Client.FailedAttempts >= FMaxAttempts then begin
                        SendAnswer(Client, msgNotAllowed);
                     { close control channel }
                        Client.Close;
                    end
                    else begin
                        SendAnswer(Client, msgLoginFailed);
                    end;
                    continue ; // skip testing timeouts
                end;
            end ;

         { different length timeouts depending on what's happening }
            Timeout := 0;
            case Client.FtpState of
                ftpcWaitingUserCode, ftpcWaitingPassword: Timeout := FTimeoutSecsLogin;
                ftpcReady, ftpcWaitingAnswer: Timeout := FTimeoutSecsIdle;
            end;
            if Client.DataSocket.State = wsConnected then begin
                if FTimeoutSecsXfer < FTimeoutSecsIdle then Timeout := FTimeoutSecsXfer;  { V7.09 xfer timeout must be shorted than idle }
            end;
            if Timeout > 0 then begin
                Duration :=  IcsDiffTicks(Client.LastTick, CurTicks) div TicksPerSecond; { V1.56 AG}
                if Duration >= Timeout then begin   { seconds }
                    Abort := true;
                    TriggerTimeout(Client, Duration, Abort);
                    if NOT Abort then
                        Client.LastTick := IcsGetTickCountX  { extend timeout }
                    else begin
                      { close data channel }
                        if Client.DataSocket.State = wsConnected then begin
                            Client.TransferError    := 'ABORT on Timeout';
                            Client.AbortingTransfer := TRUE;
                            Client.DataSocket.Close;
                        end
                        else begin  { V7.09 xfer timeout only close data channel }
                            SendAnswer(Client, WideFormat(msgTimeout, [Duration]));
                          { close control channel }
                            Client.Close;
                        end;
                    end;
                end;
            end;
        end;
    finally
        FEventTimer.Enabled := true;
    end ;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TFtpCtrlSocketW.Create(AOwner: TComponent);
begin
    inherited Create(AOwner);
    FDataSocket      := TWSocket.Create(Self);
{$IFDEF USE_SSL}
    ProtP            := FALSE;
    AuthFlag         := FALSE;
    CccFlag          := FALSE;
    CurFtpSslType    := curftpSslNone;
    FtpSslTypes      := [];
{$ENDIF}
    FDataSocket.Name := 'DataWSocket';
    FBanner          := DefaultBanner;
    FFtpState        := ftpcInvalid;
    FHomeDir         := 'C:\TEMP\';  { Must include a trailing backslash !!}
    FDirectory       := FHomeDir;    { Must include a trailing backslash !!}
    SetRcvSize(DefaultRcvSize);
    OtpMethod        := OtpKeyNone;  { angus V1.54 One Time Password authentication method }
    OtpSequence      := -1;          { angus V1.54 One Time Password current sequence }
    OtpSeed          := '';          { angus V1.54 One Time Password current seed }
    LastTick         := IcsGetTickCountX;  { angus V1.54 last tick for time out checking }
    SessStartTick    := IcsGetTickCountX;     { angus V1.54 tick when client session started, for duration check }
    ReqStartTick     := 0;    { angus V1.54 tick when last request started, for duration check }
    ReqDurMilliSecs  := 0;    { angus V1.54 how long last request took, in ticks }
    TotGetBytes      := 0;    { angus V1.54 how many bytes GET during session, data and control }
    TotPutBytes      := 0;    { angus V1.54 how many bytes PUT during session, data and control }
    FailedAttempts   := 0;    { angus V7.06 count failed login attempts }
    DelayAnswerTick  := TriggerDisabled;  { angus V7.06 when to send a delayed failed login answer }
    FSndBufSize      := DefaultRcvSize;   { Angus V7.19 datasocket buffer}
    FRcvBufSize      := DefaultRcvSize;   { Angus V7.19 datasocket buffer}
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
destructor TFtpCtrlSocketW.Destroy;
begin
    FRcvCnt := 0;      { Clear received data }
    SetRcvSize(0);     { Free the buffer     }
    if Assigned(ProcessingThread) then begin { AG V7.02 }
        ProcessingThread.OnTerminate := nil; { AG V7.02 }
        FreeAndNil(ProcessingThread);        { AG V7.02 }
    end;                                     { AG V7.02 }
    if Assigned(FDataSocket) then begin
        FDataSocket.Destroy;
        FDataSocket := nil;
    end;
    inherited Destroy;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpCtrlSocketW.SetRcvSize(newValue : Integer);
begin
    if FRcvCnt <> 0 then
        raise EFtpCtrlSocketException.Create('Data in buffer, can''t change size');

    if FRcvSize < 0 then
        FRcvSize := 0;

    if FRcvSize = newValue then
        Exit; { No change, nothing to do }

    { Free previously allocated buffer }
    if FRcvBuf <> nil then begin
        FreeMem(FRcvBuf, FRcvSize);
        FRcvBuf := nil;
    end;

    { Allocate new buffer }
    FRcvSize := newValue;

    { If size is nul, then do not allocated the buffer }
    if newValue > 0 then
        GetMem(FRcvBuf, FRcvSize);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpCtrlSocketW.SetRcvBufSize(newValue : Integer);   { Angus V7.19}
begin
    if newValue < 1024 then
        FRcvBufSize := 1024
    else
        FRcvBufSize := newValue;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpCtrlSocketW.SetSndBufSize(newValue : Integer);   { Angus V7.19}
begin
    if newValue < 1024 then
        FSndBufSize := 1024
    else
        FSndBufSize := newValue;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpCtrlSocketW.SetCodePage(const Value: LongWord);{ AG 7.02 }
begin
    if Value = FtpServer.FSystemCodePage then
        FCodePage := CP_ACP
    else
        FCodePage := Value;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpCtrlSocketW.SetCurrentCodePage(const Value: LongWord);{ AG 7.02 }
begin
    if Value = FtpServer.FSystemCodePage then
        FCurrentCodePage := CP_ACP
    else
        FCurrentCodePage := Value;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpCtrlSocketW.SetOnBgException(const Value: TIcsBgExceptionEvent); { V7.15 }
begin
    if Assigned(FDataSocket) then
        FDataSocket.OnBgException := Value;
    inherited;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpCtrlSocketW.SetOptions(const Opts : TFtpOptions);{ AG 7.02 }
begin
    FOptions := Opts;
    if ftpUtf8On in FOptions then
        CurrentCodePage := CP_UTF8
    else
        CurrentCodePage := FCodePage;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpCtrlSocketW.TriggerSessionClosed(Error: Word);
begin
    if Assigned(ProcessingThread) then
        ProcessingThread.Terminate;
    inherited TriggerSessionClosed(Error);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpCtrlSocketW.TriggerSessionConnected(Error : Word);
begin
    FPeerAddr := inherited GetPeerAddr;
    inherited TriggerSessionConnected(Error);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpCtrlSocketW.TriggerCommand(CmdBuf : PAnsiChar; CmdLen : Integer);{ AG 7.02 }
begin
    if Assigned(FOnCommand) then
        FOnCommand(Self as TFtpCtrlSocketW, CmdBuf, CmdLen);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TFtpCtrlSocketW.TriggerDataAvailable(Error : Word) : Boolean;
var
    Len  : Integer;
    I    : Integer;
begin
    Result := TRUE;                                { We read data }

    Len := Receive(@FRcvBuf[FRcvCnt], FRcvSize - FRcvCnt - 1);
    if Len <= 0 then
        Exit;

    FRcvCnt := FRcvCnt + Len;
    FRcvBuf[FRcvCnt] := #0;
    LastTick := IcsGetTickCountX;  { angus V1.54 last tick for time out checking }
    TotPutBytes := TotPutBytes + Len;    { angus V1.54 }

    while TRUE do begin
        I := 0;
        while (I < FRcvCnt) and (FRcvBuf[I] <> #10) do
            Inc(I);
        if I >= FRcvCnt then begin
            { Check line overflow. }
            if FRcvCnt >= (FRcvSize - 1) then begin
                StrPCopy(FRcvBuf, 'OVER' + #13#10);
                FRcvCnt := StrLen(FRcvBuf);
                I       := FRcvCnt - 1;
            end
            else
                Exit;
        end;
        FRcvBuf[I]   := #0;
        FLastCommand := Now;
        Inc(FCommandCount);
        if (I > 1) and (FRcvBuf[I - 1] = #13) then begin
            FRcvBuf[I - 1] := #0;
            TriggerCommand(FRcvBuf, I - 1);{ AG 7.02 }
            FRcvBuf[I - 1] := #13;
        end
        else
            TriggerCommand(FRcvBuf, I);{ AG 7.02 }

        FRcvBuf[I] := #10;
        if I >= (FRcvCnt - 1) then begin
            FRcvCnt    := 0;
            FRcvBuf[0] := #0;
            break;
        end;
        Move(FRcvBuf[I + 1], FRcvBuf^, FRcvCnt - I);
        FRcvCnt := FRcvCnt - I - 1;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpCtrlSocketW.SendAnswer(const Answer : RawByteString);    { angus V7.01  }{ AG 7.02 }
begin
    SendStr(Answer + #13#10);
    LastTick := IcsGetTickCountX;  { angus V1.54 last tick for time out checking }
    TotGetBytes := TotGetBytes + Length (Answer) + 2;    { angus V1.54 }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpCtrlSocketW.DataStreamWriteString(
    const Str: UnicodeString;
    DstCodePage: LongWord);{ AG 7.02 }
begin
    StreamWriteString(DataStream, Str, DstCodePage);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpCtrlSocketW.DataStreamWriteString(const Str: UnicodeString);
begin
    StreamWriteString(DataStream, Str, CP_ACP);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpCtrlSocketW.DataStreamWriteString(const Str: AnsiString);
begin
    DataStream.Write(Pointer(Str)^, Length(Str));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpCtrlSocketW.DataStreamWriteString(                     { AG 7.02 }
  const Str: AnsiString; DstCodePage: LongWord);
var
    S : AnsiString;
begin
    if DstCodePage = CP_ACP then
        DataStream.Write(Pointer(Str)^, Length(Str))
    else begin
        S := ConvertCodePage(Str, CP_ACP, DstCodePage);
        DataStream.Write(Pointer(S)^, Length(S));
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpCtrlSocketW.DataStreamReadString(var Str: AnsiString;
  Len: TFtpBigInt);
var
    ReadLen: Cardinal;
begin
    SetLength(Str, Len);
    ReadLen := DataStream.Read(Pointer(Str)^, Len);
    if ReadLen < Len then
        SetLength(Str, ReadLen);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ Potential data loss if SrcCodePage <> CP_ACP!                       AG 7.02 }
procedure TFtpCtrlSocketW.DataStreamReadString(
  var Str: AnsiString; Len: TFtpBigInt; SrcCodePage: LongWord);
var
    BytesRead : Cardinal;
    Buf       : PAnsiChar;
    BufW      : PWideChar;
    L1, L2    : Integer;
begin
    SetLength(Str, 0);
    if Len < 0 then Exit;
    if (SrcCodePage = CP_ACP) then
    begin
        SetLength(Str, Len);
        BytesRead := DataStream.Read(Pointer(Str)^, Len);
        if BytesRead < Len then
            SetLength(Str, BytesRead);
    end
    else begin
        GetMem(Buf, Len);
        try
            BytesRead := DataStream.Read(Buf^, Len);
            L1 :=  IcsMbToWc{MultiByteToWideChar}(SrcCodePage, 0, Buf, BytesRead, nil, 0);
            GetMem(BufW, L1 * SizeOf(WideChar));
            try
                IcsMbToWc{MultiByteToWideChar}(SrcCodePage, 0, Buf, BytesRead, BufW, L1);
                L2 := IcsWcToMb{WideCharToMultibyte}(CP_ACP, 0, BufW, L1, nil, 0, nil, nil);
                if L2 <> Len then
                    ReallocMem(Buf, L2);
                L1 := IcsWcToMb{WideCharToMultibyte}(CP_ACP, 0, BufW, L1, Buf, L2, nil, nil);
                SetLength(Str, L1);
                Move(Buf[0], Pointer(Str)^, L1);
            finally
                ReallocMem(BufW, 0);
            end;
        finally
            ReallocMem(Buf, 0);
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpCtrlSocketW.DataStreamReadString(var Str: UnicodeString;
  Len: TFtpBigInt; SrcCodePage: LongWord); { AG 7.02 }
var
    SBuf : array [0..2047] of AnsiChar;
    HBuf : PAnsiChar;
    eLen : Cardinal;
begin
    if SrcCodePage <> 1200 {CP_UTF16} then begin
        if Len <= SizeOf(SBuf) then begin
            eLen := DataStream.Read(SBuf[0], Len);
            Len := IcsMbToWc{MultiByteToWideChar}(SrcCodePage, 0, @SBuf, eLen, nil, 0);
            SetLength(Str, Len);
            IcsMbToWc{MultiByteToWideChar}(SrcCodePage, 0, @SBuf, eLen, Pointer(Str), Len);
        end
        else begin
            GetMem(HBuf, Len);
            try
                eLen := DataStream.Read(HBuf^, Len);
                Len := IcsMbToWc{MultiByteToWideChar}(SrcCodePage, 0, HBuf, eLen, nil, 0);
                SetLength(Str, Len);
                IcsMbToWc{MultiByteToWideChar}(SrcCodePage, 0, HBuf, eLen, Pointer(Str), Len);
            finally
                FreeMem(HBuf);
            end;
        end;
    end
    else begin
        SetLength(Str, Len);
        eLen := DataStream.Read(Pointer(Str)^, Len * SizeOf(WideChar));
        if (eLen div SizeOf(WideChar)) < Len then
            SetLength(Str, (eLen div SizeOf(WideChar)));
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpCtrlSocketW.DataStreamReadString(var Str: UnicodeString;
  Len: TFtpBigInt);
begin
    DataStreamReadString(Str, Len, CP_ACP);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function IsUNC(S : TFtpString) : Boolean;
begin
    Result := (Length(S) >= 2) and (S[2] = '\') and (S[1] = '\');
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure PatchIE5(var S : TFtpString);
begin
    { \c:\Temp\ -> c:\Temp\ IE5 like this invalid syntax !}
    if (Length(S) >= 3) and (S[3] = ':') and (S[1] = '\') then
        Delete(S, 1, 1);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpCtrlSocketW.SetDirectory(newValue : TFtpString);
var
    newDrive : TFtpString;
    newPath  : TFtpString;
    I        : Integer;
begin
    if FDirectory = newValue then
        Exit;
    PatchIE5(newValue);
    newDrive := ExtractFileDrive(newValue);
    if IsUNC(newDrive) then begin
        if not (ftpcUNC in Options) then
            raise Exception.Create('Cannot accept UNC path');
        FDirectory := newValue;
        { Always terminate with a backslash }
        if (Length(FDirectory) > 0) and (FDirectory[Length(FDirectory)] <> '\') then
            FDirectory := FDirectory + '\';
        Exit;
    end;
    if Length(newDrive) = 0 then begin        { AG V1.52 }
        if (ftpCdUpHome in Options) then begin
            if (Length(newValue) > 0) and (newValue[1] = '\') then begin
                { absolute path, HomeDir }
                newDrive := IcsExtractFileDriveW(FHomeDir);
                newPath  := Copy(FHomeDir, Length(newDrive) + 1, Length(FHomeDir)) +
                                 Copy(newValue, 2, Length(newValue))
            end
            else begin
                newDrive := ExtractFileDrive(FDirectory);
                newPath  := newValue;
            end;
        end
        else begin
          newDrive := ExtractFileDrive(FDirectory);
          newPath  := newValue;
        end;
    end
    else
        newPath := Copy(newValue, 3, Length(newValue));


    if Pos(':', newPath) <> 0 then
        raise Exception.Create('Invalid directory name syntax');

    if newPath = '..' then begin
        if IsUNC(FDirectory) then begin
            I := Length(FDirectory) - 1;
            while (I > 0) and (FDirectory[I] <> '\') do
                Dec(I);
            if I > Length(newDrive) then
                SetLength(FDirectory, I);
            Exit;
        end
        else begin
            newPath := Copy(FDirectory, 3, Length(FDirectory));
            I := Length(newPath) - 1;
            while (I > 0) and (newPath[I] <> '\') do
                Dec(I);
            SetLength(newPath, I);
        end;
    end;

    if (Length(newPath) > 0) and (newPath[1] <> '\') then begin
        { Relative path }
        if IsUNC(FDirectory) then begin
            FDirectory := FDirectory + newPath;
            { Always terminate with a backslash }
            if (Length(FDirectory) > 0) and (FDirectory[Length(FDirectory)] <> '\') then
                FDirectory := FDirectory + '\';
            Exit;
        end
        else begin
            if IcsAnsiUpperCaseW(newDrive[1]) <> IcsAnsiUpperCaseW(FDirectory[1]) then
                raise Exception.Create('Cannot accept path not relative to current directory');
            if (Pos('.\', newPath) <> 0) or (Pos('.%2f', newPath) <> 0) or (Pos('.%5c', NewPath) <> 0) then  { V8.50 }
                raise Exception.Create('Cannot accept relative path using dot notation');
            if newPath = '.' then
                newPath := Copy(FDirectory, 3, Length(FDirectory))
            else
                newPath := Copy(FDirectory, 3, Length(FDirectory)) + newPath;
        end;
    end
    else begin
        if (Pos('.\', newPath) <> 0) or (Pos('.%2f', newPath) <> 0) or (Pos('.%5c', NewPath) <> 0) then  { V8.50 }
            raise Exception.Create('Cannot accept relative path using dot notation');
    end;

    if Length(newPath) = 0 then begin
        if IcsAnsiUpperCaseW(newDrive[1]) <> IcsAnsiUpperCaseW(FDirectory[1]) then
            newPath := '\'
        else
            newPath := Copy(FDirectory, 3, Length(FDirectory));
    end;

    { Always terminate with a backslash }
    if (Length(newPath) > 0) and (newPath[Length(newPath)] <> PathDelim) then
        newPath := newPath + '\';

    FDirectory := newDrive + newPath;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpCtrlSocketW.SetHomeDir(const newValue: TFtpString);
begin
    if FHomeDir = newValue then
        Exit;
    if (Length(newValue) > 0) and (newValue[Length(newValue)] <> PathDelim) then
        FHomeDir := newValue + '\'
    else
        FHomeDir := newValue;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpCtrlSocketW.SetAbortingTransfer(newValue : Boolean);
begin
    FAbortingTransfer := newValue;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure UpdateThreadOnProgress(
    Obj: TObject;
    Count: Int64;
    var Cancel: Boolean);
begin
    if (Obj is TClientProcessingThreadW) then   { V7.08 }
    begin
        Cancel := (Obj as TClientProcessingThreadW).Terminated;
        (Obj as TClientProcessingThreadW).Client.LastTick := IcsGetTickCountX;
    end
    else if (Obj is TFtpCtrlSocketW) then       { V7.08 }
    begin
        Cancel := (Obj as TFtpCtrlSocketW).AbortingTransfer;
        (Obj as TFtpCtrlSocketW).LastTick := IcsGetTickCountX;
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function FormatUnixDirEntry(F : TIcsSearchRecW; const FileName: TFtpString) : TFtpString;
var
    Attr             : String;
    Ext              : TFtpString;
    Day, Month, Year : Integer;
    Hour, Min        : Integer;
    SizeStr          : String;
    TimeStr          : String;
const
    StrMonth : array [1..12] of String =
        ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
begin
{$WARNINGS OFF}
    { Owner - Group - Others }
    Attr := '-rw-rw-rw-';
    if (F.Attr and faDirectory) <> 0 then
        Attr[1] := 'd';

    if (F.Attr and faReadOnly) <> 0 then begin
        Attr[3] := '-';
        Attr[6] := '-';
        Attr[9] := '-';
    end;
{$WARNINGS ON}

    Ext := IcsAnsiUpperCaseW(IcsExtractFileExtW(FileName));
    if (Ext = '.EXE') or (Ext = '.COM') or (Ext = '.BAT') then begin
        Attr[4]  := 'x';
        Attr[7]  := 'x';
        Attr[10] := 'x';
    end;

    Year  := IcsHiWord(F.Time) shr 9 + 1980;
    Month := IcsHiWord(F.Time) shr 5 and $0F;
    Day   := IcsHiWord(F.Time) and $1F;
    Hour  := IcsLoWord(F.Time) shr 11;
    Min   := IcsLoWord(F.Time) shr 5 and $3F;
    (*
    Day   := (IcsHiWord(F.Time) and $1F);
    Month := ((IcsHiWord(F.Time) shr 5) and $0F);
    Year  := ((IcsHiWord(F.Time) shr 9) and $3F) + 1980;
    Min   := ((F.Time shr 5) and $3F);
    Hour  := ((F.Time shr 11) and $1F);
    *)

    if F.FindData.nFileSizeHigh = 0 then
        SizeStr := IntToStr(F.FindData.nFileSizeLow)
    else
        SizeStr := IntToStr(F.FindData.nFileSizeLow +
                           (Int64(F.FindData.nFileSizeHigh) shl 32));
    if Year = ThisYear then
        TimeStr := WideFormat('%2.2d:%2.2d', [Hour, Min])
    else
        TimeStr := WideFormat('%5d', [Year]);

    Result := Attr + '   1 ftp      ftp  ' +
              WideFormat('%11s %s %2.2d %5s ',
                     [SizeStr, StrMonth[Month], Day, TimeStr]) +
              FileName + #13#10;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function FileTimeToStr(const FileTime: TFileTime): TFtpString;     { angus V1.38 }
const
  FileTimeBase = -109205.0;   { days between years 1601 and 1900 }
  FileTimeStep: Extended = 24.0 * 60.0 * 60.0 * 1000.0 * 1000.0 * 10.0; { 100 nsec per Day }
var
    F64    : Comp absolute FileTime;
    TempDT : TDateTime;
begin
    TempDT := F64 / FileTimeStep;
    TempDT := TempDT + FileTimeBase;
    Result := FormatDateTime (UtcDateMaskPacked, TempDT);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{FTP MLSD command, same format for MSLT for a single file
much nice than LIST since it has a proper date with year, and seconds, and is much easier to parse
size=0;type=cdir;perm=fdelcmp;create=20020616151738;modify=20031002125810; .
size=0;type=pdir;perm=fdelcmp;create=20020616151738;modify=20031002125810; ..
size=17199;type=file;perm=fdrwa;create=20030616152030;modify=20031001190100; 00master.zip
size=182928;type=file;perm=fdrwa;create=20030922195127;modify=20030922190600; 12=page-004394.zip
size=134503;type=file;perm=fdrwa;create=20030923181732;modify=20030923170800; 12=page-004399.zip
size=225460;type=file;perm=fdrwa;create=20030923193147;modify=20030923185600; 12=page-004400.zip
size=205011;type=file;perm=fdrwa;create=20030923120836;modify=20030922225700; 12=page-004405.zip
size=191721;type=file;perm=fdrwa;create=20030905141821;modify=20030904181100; 20=page-004320.zip
size=183977;type=file;perm=fdrwa;create=20030905142247;modify=20030904181100; 20=page-004321.zip
size=0;type=dir;perm=fdelcmp;create=20030219123018;modify=20030305153855; errors
size=0;type=dir;perm=fdelcmp;create=20021217151845;modify=20030903193625; new software
size=0;type=dir;perm=fdelcmp;create=20020805160304;modify=20031002133003; sql logs
size=70806;type=file;perm=fdrwa;create=20030718113340;modify=20031001185600; vehinfiles.zip
size=0;type=dir;perm=fdelcmp;create=20020801100314;modify=20031004124403; zip logs  }

function FormatFactsDirEntry(F : TIcsSearchRecW; const FileName: TFtpString) : TFtpString;  { angus V1.38, 1.54 added FileName }
var
    SizeStr : String;
begin
{$WARNINGS OFF}
    (*  faVolumeID not used in Win32
    if ((F.Attr and faVolumeID) <> 0)  then begin
        { Ignore volume ID entries }
        Result := '';
        Exit;
    end;
    *)
    if F.FindData.nFileSizeHigh = 0 then
        SizeStr := IntToStr(F.FindData.nFileSizeLow)
    else
        SizeStr := IntToStr(F.FindData.nFileSizeLow +
                           (Int64(F.FindData.nFileSizeHigh) shl 32));

    { PERMissions is advisory only, max 10 characters - not properly set here }
    { a - APPE allowed for a file                                             }
    { c - files may be created in this directory                              }
    { d - may be deleted                                                      }
    { e - directory entry allowed                                             }
    { f - may be renamed                                                      }
    { l - directory may be listed                                             }
    { m - new directories may be made                                         }
    { p - file may be deleted from the directory                              }
    { r - RETR allowed for a file                                             }
    { w - STOR allowed for a file                                             }
    if (F.Attr and faDirectory) <> 0 then begin
        if FileName = '.' then
            result := 'size=0;type=cdir;perm=fdelcmp;'
        else if FileName = '..' then
            result := 'size=0;type=pdir;perm=fdelcmp;'
        else
            result := 'size=0;type=dir;perm=fdelcmp;'
    end
    else begin
        result := 'size=' + SizeStr + ';type=file;perm=';
        if (F.Attr and faReadOnly) <> 0 then
            result := result + 'rw;'
        else
            result := result + 'fdrwa;';
    end;
    result := result +
        'create=' + FileTimeToStr (F.FindData.ftCreationTime) +
        ';modify=' + FileTimeToStr (F.FindData.ftLastWriteTime) +
        '; ' + FileName;    { note space before filename is delimiter }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TFtpCtrlSocketW.BuildDirList(var TotalFiles: integer);  { angus V7.08 was BuildDirectory, removed Path, added TotalFiles }
var
    Buf        : TFtpString;
    LocFiles   : TIcsFileRecsW; { angus 1.54 dynamic array of File Records }
    LocFileList: TList;         { angus 1.54 sorted pointers to File Records }
    I          : Integer;
    TotFiles   : Integer;
    FileRecX   : PTIcsFileRecW;
begin
    TotalFiles := 0 ;  { V7.08 }
{    DecodeDate(Now, ThisYear, ThisMonth, ThisDay);   V7.08 moved to BuildDirectory so this procedure can be overriden }

 { angus 1.54 build sorted recursive directory }
    SetLength (LocFiles, 250);   { initial expected number of files }
    LocFileList := TList.Create;
    try
     { fill LocFiles dynamic array with SearchRecs, sorted by LocFileList }
        TotFiles := IcsGetDirList (DirListPath, DirListSubDir,
                     DirListHidden, LocFiles, LocFileList, Self, UpdateThreadOnProgress) ;  { V7.08 }
     { V7.08 allow extra virtual files to be added to the dynamic File Records array }
        if TotFiles <> -1 then
            FtpServer.TriggerAddVirtFiles(Self, LocFiles, LocFileList, TotFiles, UpdateThreadOnProgress) ;
        if TotFiles > 0 then begin
          { need a descendent of TMemoryStream with SetCapacity }
          {  TMemoryStream (Stream).SetCapacity (TotFiles * 128);  }
            for I := 0 to Pred (TotFiles) do begin
                if LocFileList [I] = Nil then continue ;
                FileRecX := LocFileList [I] ;   { get file record pointer }
                if DirListSubDir then   { add path before file name }
                    Buf := IcsBackSlashesToSlashesW(FileRecX^.FrSubDirs) +
                                                 FileRecX^.FrSearchRec.Name
                else
                    Buf := FileRecX^.FrSearchRec.Name;

            { build single line according to listing style }
                if DirListType = ListTypeUnix then
                    Buf := FormatUnixDirEntry(FileRecX^.FrSearchRec, Buf)
                else if DirListType = ListTypeFacts then
                    Buf := FormatFactsDirEntry(FileRecX^.FrSearchRec, Buf) + #13#10
                else
                    Buf := Buf + #13#10;
                if Length(Buf) > 0 then begin
                    if CurCmdType = ftpcSiteIndex then Buf := '200-' + Buf;
                    if CurCmdType in [ftpcSiteCmlsd, ftpcXCMLSD] then
                                                       Buf := '250-' + Buf;    { angus 7.01 }
                    DataStreamWriteString(Buf, CurrentCodePage);
                    inc (TotalFiles) ;   { V7.08 }
                end;
            end;
        end
        else
            TotalFiles := TotFiles;   { V7.08 -1 is an error }
    finally
        SetLength (LocFiles, 0);
        LocFileList.Free;
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{$IFDEF USE_SSL}
function TFtpCtrlSocketW.SslSendPlain(Data : TWSocketData; Len : Integer) : Integer;
begin
    Result := RealSend(Data, Len);
end;
{$ENDIF}


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ Get the function pointer which cannot be niled by another thread. AG V7.02  }
procedure TClientProcessingThreadW.TriggerEnterSecurityContext;
var
    f_EnterSecurityContext : TFtpSecurityContextEvent;
begin
    f_EnterSecurityContext := Client.FtpServer.FOnEnterSecurityContext;
    if Assigned(f_EnterSecurityContext) then
        f_EnterSecurityContext(Client.FtpServer, Client);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ Get the function pointer which cannot be niled by another thread. AG V7.02  }
procedure TClientProcessingThreadW.TriggerLeaveSecurityContext;
var
    f_LeaveSecurityContext : TFtpSecurityContextEvent;
begin
    f_LeaveSecurityContext := Client.FtpServer.FOnLeaveSecurityContext;
    if Assigned(f_LeaveSecurityContext) then
        f_LeaveSecurityContext(Client.FtpServer, Client);

end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ Any lengthy task executed here must stop when Terminated is detected.       }
procedure TClientProcessingThreadW.Execute;                        { AG V1.46}
var
    NewSize: Int64;
    TotalFiles: integer;  { V7.08 }
    Buf: TFtpString;      { V7.08 }
begin
    ClientID := Client.ID;
    try
        with Client.ProcessingThread do begin
            StartTick := IcsGetTickCountX;
            if (Keyword = 'MD5') or (Keyword = 'XMD5')  then    { angus V1.54 }
                OutData := FtpFileMD5(InData, Self, UpdateThreadOnProgress,  { AG V7.02, angus V7.08  }
                   Client.HashStartPos, Client.HashEndPos, Client.FileModeRead) { angus V1.57 }
            else if (Keyword = 'XCRC') then                                   { angus V1.54 }
                OutData := FtpFileCRC32B(InData, Self, UpdateThreadOnProgress, { AG V7.02 }
                   Client.HashStartPos, Client.HashEndPos, Client.FileModeRead) { angus V1.57, V7.08 }
            else if (Keyword = 'DIRECTORY') then begin                  { angus V1.54 }
                OutData := Keyword;
                try
                    TriggerEnterSecurityContext;      { AG V7.02 }
                    try
                        Client.BuildDirList(TotalFiles);         { V7.08 }
                       (*  !! Not thread-safe !!    { AG V8.03 }
                        if TotalFiles = -1 then
                            Client.FtpServer.TriggerDisplay(Client, 'Completed directory listing for: ' +
                                                               Client.DirListPath + ' failed')
                        else
                            Client.FtpServer.TriggerDisplay(Client, 'Completed directory listing for: ' +
                                                  Client.DirListPath + ', Total Files: ' + IntToStr (TotalFiles));
                        *)
                        { AG V8.03 }
                        if TotalFiles = -1 then
                            AuxData := AuxData + 'Completed directory listing for: ' +
                                       Client.DirListPath + ' failed'
                        else
                            AuxData := 'Completed directory listing for: ' +
                                      Client.DirListPath + ', Total Files: ' + IntToStr (TotalFiles);
                        { / AG V8.03 }
                        Client.DataStream.Seek(0, 0);
                    finally
                        TriggerLeaveSecurityContext;  { AG V7.02 }
                    end;
                   if Client.DataStream.Size = 0 then begin   { V7.08 }
                        if TotalFiles = -1 then
                            Buf := 'Listing failed' + #13#10
                        else
                            Buf := Client.FtpServer.FormatResponsePath(Client, Client.DirListPath) + ' not found' + #13#10;
                        Client.DataStreamWriteString(Buf, Client.CurrentCodePage);
                    end;
                except
                    on E:Exception do begin  {angus V8.04 }
                        AuxData := 'Failed to build directory listing - ' + E.Message;
                        Buf := AuxData + #13#10;
                        Client.DataStream.Seek(0, 0);
                        Client.DataStreamWriteString(Buf, Client.CurrentCodePage);
                    end;
                end;
            end
     { angus V1.54 }
            else if (Keyword = 'COMPRESS') then begin { angus V1.54 }
                with Client do begin
                    try
                     { angus V1.55 data stream may be set to restart position, but check sensible }
                        NewSize := DataStream.Size - DataStream.Position;
                        if NewSize < 0 then begin
                            OutData := 'Failed to compress file - Invalid restart position or';
                            ZCompFileDelete := True;
                            Exit;
                        end;
                        ZlibCompressStreamEx(DataStream, ZFileStream, ZCurLevel,
                                             zsZLib, false, Self, UpdateThreadOnProgress); { angus V1.55, V7.08 }
                        if ZFileStream = Nil then begin   {angus V8.04 trap a bug when stream freed accidentally }
                            OutData := 'Failed to compress file - ZFileStream Empty After Zlib';
                            Exit;
                        end;
                        ZFileStream.Position := 0 ;
                        ZCompInfo := ' compressed size ' + IntToKbyte(ZFileStream.Size) +
                            'bytes, uncompressed size ' + IntToKbyte(NewSize) + 'bytes' ;
                     { close data file now, not needed any more }
                        DataStream.Destroy;
                        DataStream := Nil;
                        OutData := ''; { OK }
                    except
                        on E:Exception do begin
                            OutData := 'Failed to compress file - ' + E.Message;
                            ZCompFileDelete := True;
                        end;
                    end;
                end;
            end
            else if (Keyword = 'DECOMPRESS') then begin { angus V1.54 }
                with Client do begin
                    try
                        ZFileStream.Position := 0;
                        NewSize := DataStream.Size ;
                        ZlibDecompressStreamEx(ZFileStream, DataStream,
                                                 Self, UpdateThreadOnProgress) ;   { angus V1.55, V7.08 }
                        NewSize := DataStream.Size - NewSize ;
                        ZCompInfo := ' compressed size ' + IntToKbyte(Client.ZFileStream.Size) +
                             'bytes, uncompressed size ' + IntToKbyte(NewSize) + 'bytes' ;
                        OutData := ''; { OK }
                    except
                        on E:Exception do begin
                            OutData := 'Failed to decompress file - ' + E.Message;
                        end;
                    end;
                end;
            end
            else
                OutData := '';
        end;
    except
        OutData := '';
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ You must define USE_SSL so that SSL code is included in the component.    }
{ Either in OverbyteIcsDefs.inc or in the project/package options.          }
{$IFDEF USE_SSL}
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslFtpServerW.SetFtpSslTypes(const Value: TFtpSslTypes); { 1.04 }
begin
    { Implicit SSL cannot be combined with explicit SSL }
    if Value <> FFtpSslTypes then begin
        if (ftpImplicitSsl in Value) and
           ((ftpAuthSsl in Value) or
           (ftpAuthTls in Value) or
           (ftpAuthTlsP in Value) or
           (ftpAuthTlsC in Value)) then begin
            FFtpSslTypes := [];
            raise Exception.Create('Option ftpImplicitSsl cannot be combined ' +
                                   'with explicit SSL types.');
         end
         else
            FFtpSslTypes := Value;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslFtpServerW.ClientDataSent(Sender : TObject; AError : Word);    { 1.03 }
var
    Client : TFtpCtrlSocketW;
begin
    Client := Sender as TFtpCtrlSocketW;
    if Client.CccFlag then begin
        if AError = 0 then begin
            Client.SslBiShutDownAsync;
            Client.CurFtpSslType := curftpSslNone;
        end;
        Client.CccFlag := FALSE;
    end;
    inherited ClientDataSent(Sender, AError);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslFtpServerW.CommandCCC(                                           { 1.03 }
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
begin
    if (Client.FtpSslTypes = []) or (ftpImplicitSsl in Client.FtpSslTypes) then begin
        Answer := WideFormat(msgCmdUnknown, [Keyword]);
        Exit;
    end;
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;
    Client.CurCmdType := ftpcCCC;
    if (Client.SslState <> sslEstablished) then begin
        Answer := WideFormat(msgErrInSslOnly, ['CCC']);
        Exit;
    end;
    if (Client.CurFtpSslType = curftpSslNone) then begin
        Answer := WideFormat(msgAuthNoSupport, [Params]);
        Exit;
    end;
    Answer := msgCccOk;
    Client.CccFlag := TRUE;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslFtpServerW.CommandAUTH(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
var
    PlainAnswer : TFtpString;
    TmpCurFtpSslType : TCurFtpSslType;
begin
    {
    msgAuthOk         = '234 Using authentication type %s';
    msgAuthDenied     = '502 %s authentication not allowed'; // SSL/TLS
    msgAuthInitError  = '431 Could not initialize %s connection';
    msgAuthNoSupport  = '504 Auth type "%s" not supported';

    // AUTH TLS-P = AUTH SSL + PROT P
    // AUTH TLS-C = AUTH SSL + PROT C
    }
    if (FFtpSslTypes = []) or (ftpImplicitSsl in FFtpSslTypes) then begin
        Answer := WideFormat(msgCmdUnknown, [Keyword]);
        Exit;
    end;

    Client.CurCmdType := ftpcAUTH;
    TmpCurFtpSslType  := curftpSslNone;
    if      (Params = 'TLS')   and (ftpAuthTls  in FFtpSslTypes) then TmpCurFtpSslType := curftpAuthTls
    else if (Params = 'SSL')   and (ftpAuthSsl  in FFtpSslTypes) then TmpCurFtpSslType := curftpAuthSsl
    else if (Params = 'TLS-C') and (ftpAuthTlsC in FFtpSslTypes) then TmpCurFtpSslType := curftpAuthTlsC
    else if (Params = 'TLS-P') and (ftpAuthTlsP in FFtpSslTypes) then TmpCurFtpSslType := curftpAuthTlsP;

    if (TmpCurFtpSslType = curftpSslNone) then begin
        Answer := WideFormat(msgAuthNoSupport, [Params]);
        Exit;
    end;

    try
        Client.SslEnable                := True;
        Client.SslMode                  := sslModeServer;
        Client.SslContext               := FSocketServer.SslContext;    { angus V7.00 }
        Client.OnSslVerifyPeer          := TransferSslVerifyPeer;
        Client.OnSslHandshakeDone       := TransferSslHandshakeDone;
        Client.OnSslSvrNewSession       := TransferSslSvrNewSession;
        Client.OnSslSvrGetSession       := TransferSslSvrGetSession;
        Client.OnSslSetSessionIDContext := TransferSslSetSessionIDContext;
        { AUTH in plaintext mode }
        if (Client.SslState = sslNone) then begin
            Client.AcceptSslHandshake;
            PlainAnswer := WideFormat(msgAuthOk, [Params]) ;
            TriggerSendAnswer(Client, PlainAnswer);
            PlainAnswer := PlainAnswer + #13#10;
            Client.SslSendPlain(Pointer(AnsiString(PlainAnswer)), Length(PlainAnswer)); // includes only ASCII chars
            Client.CurFtpSslType  := TmpCurFtpSslType;
        end  { AUTH in SSL mode, negotiates a new SSL session }
        else
            if (Client.SslState = sslEstablished) and Assigned(Client.Ssl) then begin
                if f_SSL_version(Client.SSL) >= SSL3_VERSION then
                    Answer := msgAuthYetSetOkV3
                else
                    Answer := msgAuthYetSetOkV2;
                Client.CurFtpSslType  := TmpCurFtpSslType;
        end
        else
            Answer := WideFormat(msgAuthDenied, ['SSL/TLS']);
        Client.FtpState  := ftpcWaitingUserCode;     // Need to force re-login

        { V7.17 }
        if Client.CurFtpSslType = curftpAuthTlsP then // Need to reset prot-level as well
            Client.ProtP := TRUE
        else if Client.CurFtpSslType = curftpAuthTlsC then
            Client.ProtP := FALSE;
        { else as is }
        { / V7.17 }

    except
        Client.CurFtpSslType            := curftpSslNone;
        Client.SslEnable                := False;
        Client.OnSslVerifyPeer          := nil;
        Client.OnSslHandshakeDone       := nil;
        Client.OnSslSvrNewSession       := nil;
        Client.OnSslSvrGetSession       := nil;
        Client.OnSslSetSessionIDContext := nil;
        Answer := WideFormat(msgAuthInitError, [Params]);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ DATA CHANNEL PROTECTION LEVEL }
procedure TSslFtpServerW.CommandPROT(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
begin
    { Possible levels
    C - Clear
    S - Safe
    E - Confidential
    P - Private

    msgProtOk         = '200 Protection level set to %s';
    msgProtNotExists  = '504 Protection level ''%s'' not supported';
    msgProtUnknown    = '504 Protection level ''%s'' not recognized';
   }
    if (FFtpSslTypes = []) then begin
        Answer := WideFormat(msgCmdUnknown, [Keyword]);
        Exit;
    end;
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;
    Client.CurCmdType := ftpcPROT;
    if (Client.SslState = sslEstablished) then
    begin
        if (Params = 'C') or (Params = 'P') then begin
            Client.ProtP := Params = 'P';
            Answer := WideFormat(msgProtOK, [Params]);
        end else
        if (Params = 'S') or (Params = 'E') then
            Answer := WideFormat(msgProtNoSupport, [Params])
        else
            Answer := WideFormat(msgProtUnknown, [Params])
    end else
       Answer := WideFormat(msgErrInSslOnly, ['PROT']);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslFtpServerW.CommandPBSZ(
    Client      : TFtpCtrlSocketW;
    var Keyword : TFtpString;
    var Params  : TFtpString;
    var Answer  : TFtpString);
begin
    { Dummy command to fullfill RFC4217 }
    if (FFtpSslTypes = []) then begin
        Answer := WideFormat(msgCmdUnknown, [Keyword]);
        Exit;
    end;
    if Client.FtpState <> ftpcReady then begin
        Answer := msgNotLogged;
        Exit;
    end;
    if (Client.SslState = sslEstablished) then
    begin
        Client.CurCmdType := ftpcPBSZ;
        Answer            := msgPbszOk;
    end
    else
        Answer := WideFormat(msgErrInSslOnly, ['PBSZ']);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslFtpServerW.CreateSocket;
begin
    FSocketServer := TFtpSslWSocketServer.Create(Self);// TSslWSocketServer.Create(Self);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TSslFtpServerW.Create(AOwner: TComponent);
begin
    inherited Create(AOwner);
    FFtpSslTypes   := [];
    FSocketServer.SslEnable := false;  { V8.01 }
    AddCommand('AUTH', CommandAUTH);
    AddCommand('PROT', CommandPROT);
    AddCommand('PBSZ', CommandPBSZ);
    AddCommand('CCC',  CommandCCC);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslFtpServerW.GetSslContext: TSslContext;
begin
    Result := FSocketServer.SslContext;    { angus V7.00 }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslFtpServerW.SetSslContext(Value: TSslContext);
begin
    FSocketServer.SslContext :=  Value;    { angus V7.00 }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslFtpServerW.SendAnswer(Client: TFtpCtrlSocketW;
  Answer: TFtpString);
begin
    if (Client.CurCmdType = ftpcAUTH) and (Answer = '') then
        Exit;
    inherited SendAnswer(Client, Answer);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslFtpServerW.TransferSslHandshakeDone(Sender: TObject;
  ErrCode: Word; PeerCert: TX509Base; var Disconnect: Boolean);
var
    Client  : TFtpCtrlSocketW;
begin
    if Assigned(FOnSslHandshakeDone) then
        FOnSslHandshakeDone(Sender, ErrCode, PeerCert, Disconnect);
    { If SSL handshake failed fatal the socket has been closed already. }
    { Then a "226 File OK" is sent anyway, even with code below.        } //fix needed?
    if (ErrCode <> 0) or Disconnect then begin
        if not (Sender is TFtpCtrlSocketW) then begin
            Client := TFtpCtrlSocketW((Sender as TWSocket).Owner);
            Client.AbortingTransfer := TRUE;
            Client.TransferError    := 'SSL handshake failed - ' + Client.SslHandshakeRespMsg;  { V8.05 }
            PostMessage(FHandle, FMsg_WM_FTPSRV_Close_Data,
                        WPARAM(Client.ID), LPARAM(Client));
            Disconnect := FALSE;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslFtpServerW.TransferSslSetSessionIDContext(Sender: TObject;
  var SessionIDContext: TSslSessionIdContext);
begin
    if Assigned(FOnSslSetSessionIDContext) then
        FOnSslSetSessionIDContext(Sender, SessionIDContext);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslFtpServerW.TransferSslSvrGetSession(Sender: TObject;
  var SslSession: Pointer; SessId: Pointer; Idlen: Integer;
  var IncRefCount: Boolean);
begin
    if Assigned(FOnSslSvrGetSession) then
        FOnSslSvrGetSession(Sender, SslSession, SessId, IdLen, IncRefCount);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslFtpServerW.TransferSslSvrNewSession(Sender: TObject;
  SslSession, SessId: Pointer; Idlen: Integer;
  var AddToInternalCache: Boolean);
begin
    if Assigned(FOnSslSvrNewSession) then
        FOnSslSvrNewSession(Sender, SslSession, SessID, IDLen, AddToInternalCache);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslFtpServerW.TransferSslVerifyPeer(Sender: TObject;
  var Ok: Integer; Cert: TX509Base);
begin
    if Assigned(FOnSslVerifyPeer) then
        FOnSslVerifyPeer(Sender, Ok, Cert);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslFtpServerW.TriggerClientConnect(
    Client  : TFtpCtrlSocketW;
    AError  : Word);
begin
    inherited TriggerClientConnect(Client, AError);
    if NOT FSocketServer.IsClient(Client) then       { angus V7.00 }
        Exit;
    { The event handler may have closed the connection }
    if Client.State <> wsConnected then
        Exit;
    if GetIcsHosts = Nil then  { V8.63 already set }
        Client.SslEnable  := ftpImplicitSsl in Client.FtpSslTypes;
    if Client.SslEnable then begin
        Client.CurFtpSslType            := curftpImplicitSsl;
        Client.SslMode                  := sslModeServer;
        Client.SslContext               := FSocketServer.SslContext;    { angus V7.00 }
        Client.OnSslVerifyPeer          := TransferSslVerifyPeer;
        Client.OnSslHandshakeDone       := TransferSslHandshakeDone;
        Client.OnSslSvrNewSession       := TransferSslSvrNewSession;
        Client.OnSslSvrGetSession       := TransferSslSvrGetSession;
        Client.OnSslSetSessionIDContext := TransferSslSetSessionIDContext;
        try
            Client.AcceptSslHandshake;
        except
            Client.SslEnable := False;
            Client.Banner := msgErrSslInit;
            Client.StartConnection;
            Client.Close;
        end;
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslFtpServerW.ClientPassiveSessionAvailable(Sender : TObject; AError : Word);
var
    Client  : TFtpCtrlSocketW;
    Data    : TWSocket;
begin
    Data    := TWSocket(Sender);
    Client  := TFtpCtrlSocketW(Data.Owner);
    Client.DataSocket.SslEnable := False; // we need to start SSL by ourself

    inherited ClientPassiveSessionAvailable(Sender, AError);

    if (not Client.PassiveStart) and Client.ProtP and
       (Client.DataSocket.SslState = sslNone) then
    begin
        Client.DataSocket.SslEnable                 := TRUE;
        Client.DataSocket.SslMode                   := sslModeServer;
        Client.DataSocket.SslContext                := SslContext;
        Client.DataSocket.OnSslVerifyPeer           := TransferSslVerifyPeer;
        Client.DataSocket.OnSslHandshakeDone        := TransferSslHandshakeDone;
        Client.DataSocket.OnSslSvrNewSession        := TransferSslSvrNewSession;
        Client.DataSocket.OnSslSvrGetSession        := TransferSslSvrGetSession;
        Client.DataSocket.OnSslSetSessionIDContext  := TransferSslSetSessionIDContext;
        try
            Client.DataSocket.AcceptSslHandshake;
        except
            Client.DataSocket.SslEnable                := False;
            Client.DataSocket.OnSslVerifyPeer          := nil;
            Client.DataSocket.OnSslHandshakeDone       := nil;
            Client.DataSocket.OnSslSvrNewSession       := nil;
            Client.DataSocket.OnSslSvrGetSession       := nil;
            Client.DataSocket.OnSslSetSessionIDContext := nil;
            SendAnswer(Client, WideFormat(msgAuthInitError, ['SSL']));
            PostMessage(FHandle, FMsg_WM_FTPSRV_Close_Data,
                        WPARAM(Client.ID), LPARAM(Client));
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslFtpServerW.TriggerStorSessionConnected(Client: TFtpCtrlSocketW;
  Data: TWSocket; AError: Word);
begin
    inherited TriggerStorSessionConnected(Client, Data, AError);
    if ((not Client.PassiveStart) and Client.PassiveConnected) or
       (AError <> 0) then
        Exit;
    Client.DataSocket.SslEnable := False;
    if (Client.DataSocket.State = wsConnected) then
    begin
        if Client.ProtP and (Client.DataSocket.SslState = sslNone) then
        begin
            Client.DataSocket.SslEnable                 := True;
            Client.DataSocket.SslMode                   := sslModeServer;
            Client.DataSocket.SslContext                := SslContext;
            Client.DataSocket.OnSslVerifyPeer           := TransferSslVerifyPeer;
            Client.DataSocket.OnSslHandshakeDone        := TransferSslHandshakeDone;
            Client.DataSocket.OnSslSvrNewSession        := TransferSslSvrNewSession;
            Client.DataSocket.OnSslSvrGetSession        := TransferSslSvrGetSession;
            Client.DataSocket.OnSslSetSessionIDContext  := TransferSslSetSessionIDContext;
            try
                Client.DataSocket.AcceptSslHandshake;
            except
                Client.DataSocket.SslEnable := False;
                Client.DataSocket.OnSslVerifyPeer           := nil;
                Client.DataSocket.OnSslHandshakeDone        := nil;
                Client.DataSocket.OnSslSvrNewSession        := nil;
                Client.DataSocket.OnSslSvrGetSession        := nil;
                Client.DataSocket.OnSslSetSessionIDContext  := nil;
                Client.AbortingTransfer := TRUE;
                Client.TransferError    := msgErrSslInit;
                PostMessage(FHandle, FMsg_WM_FTPSRV_ABORT_TRANSFER,
                        WPARAM(Client.ID), LPARAM(Client));
            end;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslFtpServerW.TriggerRetrSessionConnected(Client: TFtpCtrlSocketW;
  Data: TWSocket; AError: Word);
begin
    inherited TriggerRetrSessionConnected(Client, Data, AError);

    if ((not Client.PassiveStart) and Client.PassiveConnected) or
       (AError <> 0) then
        Exit;

    Client.DataSocket.SslEnable := False;
    if Client.ProtP and (Client.DataSocket.SslState = sslNone) then begin
        Client.DataSocket.SslEnable                 := True;
        Client.DataSocket.SslMode                   := sslModeServer;
        Client.DataSocket.SslContext                := SslContext;
        Client.DataSocket.OnSslVerifyPeer           := TransferSslVerifyPeer;
        Client.DataSocket.OnSslHandshakeDone        := TransferSslHandshakeDone;
        Client.DataSocket.OnSslSvrNewSession        := TransferSslSvrNewSession;
        Client.DataSocket.OnSslSvrGetSession        := TransferSslSvrGetSession;
        Client.DataSocket.OnSslSetSessionIDContext  := TransferSslSetSessionIDContext;
        try
            Client.DataSocket.AcceptSslHandshake;
        except
            Client.DataSocket.SslEnable                := False;
            Client.DataSocket.OnSslVerifyPeer          := nil;
            Client.DataSocket.OnSslHandshakeDone       := nil;
            Client.DataSocket.OnSslSvrNewSession       := nil;
            Client.DataSocket.OnSslSvrGetSession       := nil;
            Client.DataSocket.OnSslSetSessionIDContext := nil;
            Client.AbortingTransfer := TRUE;
            raise Exception.Create(msgErrSslInit);
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslFtpServerW.MsgHandlersCount : Integer;
begin
    Result := 2 + inherited MsgHandlersCount;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslFtpServerW.AllocateMsgHandlers;
begin
    inherited AllocateMsgHandlers;
    FMsg_WM_FTPSRV_ABORT_TRANSFER    := FWndHandler.AllocateMsgHandler(Self);
    FMsg_WM_FTPSRV_Close_Data     := FWndHandler.AllocateMsgHandler(Self);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslFtpServerW.FreeMsgHandlers;
begin
    if Assigned(FWndHandler) then begin
        FWndHandler.UnregisterMessage(FMsg_WM_FTPSRV_ABORT_TRANSFER);
        FWndHandler.UnregisterMessage(FMsg_WM_FTPSRV_Close_Data);
    end;
    inherited FreeMsgHandlers;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ TSslFtpWSocketMultiListenItem }
constructor TSslFtpWSocketMultiListenItem.Create(Collection: TCollection);
begin
    inherited Create(Collection);
    SslEnable       := FALSE;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslFtpWSocketMultiListenItem.SetFtpSslTypes(
  const Value: TFtpSslTypes);
begin
  { Implicit SSL cannot be combined with explicit SSL }
    if Value <> FFtpSslTypes then begin
        if (ftpImplicitSsl in Value) and
           ((ftpAuthSsl in Value) or
           (ftpAuthTls in Value) or
           (ftpAuthTlsP in Value) or
           (ftpAuthTlsC in Value)) then begin
            FFtpSslTypes := [];
            raise Exception.Create('Option ftpImplicitSsl cannot be combined ' +
                                   'with explicit SSL types.');
         end
         else
            FFtpSslTypes := Value;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ TFtpSslWSocketServer }
function TFtpSslWSocketServer.MultiListenItemClass: TWSocketMultiListenItemClass;
begin
    Result := TSslFtpWSocketMultiListenItem;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslFtpServerW.GetIcsHosts: TIcsHostCollection;                     { V8.63 }
begin
    if Assigned(FSocketServer) then
        Result := TSslWSocketServer(FSocketServer).GetIcsHosts
    else
        Result := nil;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslFtpServerW.SetIcsHosts(const Value: TIcsHostCollection);      { V8.63 }
begin
    if Assigned(FSocketServer) then
        TSslWSocketServer(FSocketServer).SetIcsHosts(Value);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslFtpServerW.GetRootCA: String;                                  { V8.63 }
begin
    if Assigned(FSocketServer) then
        Result := TSslWSocketServer(FSocketServer).RootCA
    else
        Result := '';
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslFtpServerW.SetRootCA(const Value: String);                    { V8.63 }
begin
    if Assigned(FSocketServer) then
        TSslWSocketServer(FSocketServer).RootCA := Value;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslFtpServerW.ValidateHosts(Stop1stErr: Boolean=True;
                                              NoExceptions: Boolean=False): String; { V8.63 }
var
    J: Integer;
begin
    if Assigned(FSocketServer) then begin
        Result := TSslWSocketServer(FSocketServer).ValidateHosts(Stop1stErr, NoExceptions);
        if GetIcsHosts <> Nil then begin
            if TSslWSocketServer(FSocketServer).IcsHosts.Count > 0 then begin
         // set SSL modes for server if any Hosts have AuthSslCmd specified
         // implicit handled by SslEnabled on the host
                FtpSslTypes := [];
                for J := 0 to TSslWSocketServer(FSocketServer).IcsHosts.Count - 1 do begin
                    with TSslWSocketServer(FSocketServer).IcsHosts[J] do begin
                        if AuthSslCmd then begin
                           FtpSslTypes := [ftpAuthSsl,ftpAuthTls,ftpAuthTlsP,ftpAuthTlsC];
                           Break;
                        end;
                    end ;
                end;
            end;
        end;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslFtpServerW.RecheckSslCerts(var CertsInfo: String;
                    Stop1stErr: Boolean=True; NoExceptions: Boolean=False): Boolean;  { V8.63 }
begin
    Result := False;
    if Assigned(FSocketServer) then begin
        Result := TSslWSocketServer(FSocketServer).RecheckSslCerts(CertsInfo,
                                                        Stop1stErr, NoExceptions);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslFtpServerW.GetSslCertAutoOrder: Boolean;                       { V8.63 }
begin
    if Assigned(FSocketServer) then
        Result := TSslWSocketServer(FSocketServer).SslCertAutoOrder
    else
        Result := False;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslFtpServerW.SetSslCertAutoOrder(const Value : Boolean);         { V8.63 }
begin
    if Assigned(FSocketServer) then
        TSslWSocketServer(FSocketServer).SslCertAutoOrder := Value;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslFtpServerW.GetCertExpireDays: Integer;                         { V8.63 }
begin
    if Assigned(FSocketServer) then
        Result := TSslWSocketServer(FSocketServer).CertExpireDays
    else
        Result := 30;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslFtpServerW.SetCertExpireDays(const Value : Integer);           { V8.63 }
begin
    if Assigned(FSocketServer) then
        TSslWSocketServer(FSocketServer).CertExpireDays := Value;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslFtpServerW.ListenAllOK: Boolean;                              { V8.48 }
begin
    if Assigned(FSocketServer) then
        Result := FSocketServer.ListenAllOK
    else
        Result := False;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TSslFtpServerW.ListenStates: String;                              { V8.48 }
begin
    if Assigned(FSocketServer) then
        Result := FSocketServer.ListenStates
    else
        Result := '';
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{$IFDEF AUTO_X509_CERTS}
function TSslFtpServerW.GetSslX509Certs: TSslX509Certs;    { V8.63 }
begin
    if Assigned(FSocketServer) then
        Result := TSslWSocketServer(FSocketServer).GetSslX509Certs as TSslX509Certs
    else
        Result := nil;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TSslFtpServerW.SetSslX509Certs(const Value : TSslX509Certs);    { V8.63 }
begin
    if Assigned(FSocketServer) then
        TSslWSocketServer(FSocketServer).SetSslX509Certs(Value);
end;
{$ENDIF} // AUTO_X509_CERTS


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure IcsLoadFtpServerWFromIni(MyIniFile: TCustomIniFile; SslFtpServerW:
                         TSslFtpServerW; const Section: String = 'SslFtpServerW');     { V8.63 }
var
    bandwidth: Integer;
begin
    if NOT Assigned (MyIniFile) then
        raise ESocketException.Create('Must open and assign INI file first');
    if NOT Assigned (SslFtpServerW) then
        raise ESocketException.Create('Must assign SslFtpServerW first');

    with SslFtpServerW do begin
        Banner := MyIniFile.ReadString(Section, 'BannerConnect', Banner);
        MaxAttempts := MyIniFile.ReadInteger(Section, 'MaxAttempts', MaxAttempts);
        MaxClients := MyIniFile.ReadInteger(Section, 'MaxClients', MaxClients);
        PasvIpAddr := MyIniFile.ReadString(Section, 'PasvIpAddr', '');
        PasvPortRangeStart := MyIniFile.ReadInteger(Section, 'PasvPortRangeStart', 0);
        PasvPortRangeSize := MyIniFile.ReadInteger(Section, 'PasvPortRangeSize', 0);
        MD5UseThreadFileSize := MyIniFile.ReadInteger(Section, 'MD5UseThreadFileSize', MD5UseThreadFileSize);
        TimeoutSecsLogin := MyIniFile.ReadInteger(Section, 'TimeoutSecsLogin', TimeoutSecsLogin);
        TimeoutSecsIdle := MyIniFile.ReadInteger(Section, 'TimeoutSecsIdle', TimeoutSecsIdle);
        TimeoutSecsXfer := MyIniFile.ReadInteger(Section, 'TimeoutSecsXfer', TimeoutSecsXfer) ;
        ZlibMinLevel := MyIniFile.ReadInteger(Section, 'ZlibMinLevel', ZlibMinLevel);
        ZlibMaxLevel := MyIniFile.ReadInteger(Section, 'ZlibMaxLevel', ZlibMaxLevel);
        ZlibNoCompExt := MyIniFile.ReadString(Section, 'ZlibNoCompExt', ZlibNoCompExt);
        AlloExtraSpace := MyIniFile.ReadInteger(Section, 'AlloExtraSpace', AlloExtraSpace);
        ZlibMinSpace := MyIniFile.ReadInteger(Section, 'ZlibMinSpace', ZlibMinSpace);
        ZlibMaxSize := MyIniFile.ReadInteger(Section, 'ZlibMaxSize', ZlibMaxSize);
        ListenBackLog := MyIniFile.ReadInteger(Section, 'ListenBackLog', ListenBackLog);
        bandwidth := MyIniFile.ReadInteger(Section, 'BandwidthLimitKB', -1);
        if bandwidth > 0 then
            BandwidthLimit := bandwidth * 1024
        else
            BandwidthLimit := 0;
        IcsStrToSet(TypeInfo(TFtpsOption), MyIniFile.ReadString(Section, 'SrvOptions', '[]'), FOptions, SizeOf(FOptions));
{ ie SrvOptions=[ftpsCwdCheck, ftpsCdupHome, ftpsCalcMD5OnTheFly, ftpsCalcCRCOnTheFly, ftpsNoPasvIpAddrInLan, ftpsNoPasvIpAddrSameSubnet,
                 ftpsHidePhysicalPath, ftpsModeZCompress, ftpsSiteXmlsd, ftpsThreadRecurDirs, ftpsThreadAllDirs, ftpsModeZNoResume,
                 ftpsEnableUtf8, ftpsDefaultUtf8On, ftpsAutoDetectCodePage, ftpsCompressDirs]  }
        RootCA := IcsTrim(MyIniFile.ReadString(Section, 'RootCA', ''));
        SslCertAutoOrder := IcsCheckTrueFalse(MyIniFile.ReadString (section, 'SslCertAutoOrder', 'False'));
        CertExpireDays := MyIniFile.ReadInteger(Section, 'CertExpireDays', CertExpireDays);
    end;
end;


{$ENDIF} // USE_SSL{$ENDIF}

end.


