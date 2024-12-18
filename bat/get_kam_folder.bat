@echo off
echo called get_kam_folder.bat

if defined KAM_FOLDER_INIT ( 
if %KAM_FOLDER_INIT%==True (
goto exit0
)
)

@SET KAM_FOLDER_INIT=True

@REM @echo #                                                          #
@REM @echo #==========================================================#
@REM @echo #               Create new build folder                    #
@REM @echo #==========================================================#
@REM @echo #                                                          #

@echo off
call rsvars.bat

if errorlevel 2 (goto exit2)

@echo off
for /f "delims=" %%a in ('wmic OS Get localdatetime  ^| find "."') do set dt=%%a
set datestamp=%dt:~0,8%
set timestamp=%dt:~8,6%
set YYYY=%dt:~0,4%
set MM=%dt:~4,2%
set DD=%dt:~6,2%
set HH=%dt:~8,2%
set Min=%dt:~10,2%
set Sec=%dt:~12,2%

set stamp=%YYYY%-%MM%-%DD%_%HH%-%Min%-%Sec%
REM echo stamp: "%stamp%"
REM echo datestamp: "%datestamp%"
REM echo timestamp: "%timestamp%"

REM Read last line from the file
for /F "UseBackQ delims=NET_PROTOCOL_REVISION_NUM=" %%i in ("..\KM_NetProtocolRevision.inc") do set "kmr_net_protocol=%%i"

echo KMR Net Protocol = "%kmr_net_protocol%"

REM Replace ' with nothing to get the version info
REM @SET kam_revision=%verinfo:'=%
REM @SET kam_revision=8105

@REM get revision number from git
FOR /F "tokens=* USEBACKQ" %%F IN (`git rev-list --count HEAD`) DO (
  SET kam_revision=%%F
)

@REM increment revision number by 1, as we are going to make one more commit for KM_Revision.inc
@SET /A kam_revision=kam_revision+1

@REM Now we can have a constant with the right folder name
@SET build_full_kmr_dir=%BuildFullDir%\kmr%YYYY%-%MM%-%DD% (%kam_version% r%kam_revision%)
@REM @SET installer_kmr_build_full_dir=..\Installer\BuildFull

@REM default kam_folder is build full directory
@SET kam_folder=%build_full_kmr_dir%

echo KMR Beta folder = "%kam_folder%"


goto exit0

:exit2
@echo off
exit /B 2

:exit0
@echo off
exit /B 0
