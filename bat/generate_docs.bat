
echo Generating Remake documentation...

@SET RS_INIT=False
call rsvars.bat

@SET curr_directory=%cd%
cd ..\Docs\Readme

%PandocDir_LOCAL%\pandoc.exe -s -f markdown getting-started_eng.md -o Readme_eng.html --metadata title="Getting started with Knights and Merchants: Remake"
%PandocDir_LOCAL%\pandoc.exe -s -f markdown getting-started_ger.md -o Readme_ger.html --metadata title="Erste Schritte mit Knights and Merchants: Remake"
%PandocDir_LOCAL%\pandoc.exe -s -f markdown getting-started_pol.md -o Readme_pol.html --metadata title="Pierwsze kroki z Knights and Merchants: Remake"
%PandocDir_LOCAL%\pandoc.exe -s -f markdown getting-started_rus.md -o Readme_rus.html --metadata title="Начало работы с Knights and Merchants: Remake"

cd /D %curr_directory%

echo Generating finished.
