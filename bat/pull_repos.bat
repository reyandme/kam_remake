@REM pull from private repo
@echo off
echo called pull_repos.bat

call rsvars.bat

@SET curr_directory=%cd%

cd /D %KMRPrivateRepoDir%

git pull

cd /D %KMRResourcesRepoDir%

git pull

cd /D %curr_directory% 

