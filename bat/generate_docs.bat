
echo Generating Remake documentation...

@SET RS_INIT=False
call rsvars.bat

@SET curr_directory=%cd%
cd ..\Docs\Readme

%PandocDir_LOCAL%\pandoc.exe -c readme.css -s -f markdown getting-started_eng.md -o Readme_eng.html --metadata-file=".\Readme\metadata_eng.yml"
%PandocDir_LOCAL%\pandoc.exe -c readme.css -s -f markdown getting-started_ger.md -o Readme_ger.html --metadata-file=".\Readme\metadata_ger.yml"
%PandocDir_LOCAL%\pandoc.exe -c readme.css -s -f markdown getting-started_pol.md -o Readme_pol.html --metadata-file=".\Readme\metadata_pol.yml"
%PandocDir_LOCAL%\pandoc.exe -c readme.css -s -f markdown getting-started_rus.md -o Readme_rus.html --metadata-file=".\Readme\metadata_rus.yml"

cd /D %curr_directory%

echo Generating finished.
