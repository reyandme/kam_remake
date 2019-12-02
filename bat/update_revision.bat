
@REM get revision number from git
@FOR /F "tokens=* USEBACKQ" %%F IN (`git rev-list --count HEAD`) DO (
  @SET kam_revision=%%F
)
@REM increment revision number by 1, as we are going to make one more commit for KM_Revision.inc
@SET /A kam_revision=kam_revision+1

@REM update revision number in KM_Revision.inc file 
@echo GAME_REVISION_NUM=%kam_revision% > ..\KM_Revision.inc

@REM update revision for Installer
@echo #define Revision 'r%kam_revision%' > ..\Installer\Revision.iss

@REM add, commit and push changes to github
git reset
git add ..\KM_Revision.inc
git add ..\Installer\Revision.iss
git commit -m "r%kam_revision%: update revision number"
git push
@REM create revision tag and push it to remote origin
git tag -a r%kam_revision% -m "r%kam_revision%: update revision number"
git push origin r%kam_revision%

@echo !
@echo !
@echo ================================================================================
@echo ######     Rebuild KaM_Remake.exe, as revision number was changed !!!!!    #####
@echo ================================================================================
@echo !  
@echo !
