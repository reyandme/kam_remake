@echo off

echo called prepare_build.bat

call pull_repos.bat

xcopy %KMRPrivateRepoDir%\src\net\KM_NetAuthSecure.pas ..\src\net\KM_NetAuthSecure.pas* /y /r /s

call update_revision_locally.bat
