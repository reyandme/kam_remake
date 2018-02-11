Creating Full Build:
1. Create the "BuildFull" folder
2. Place there all files to install KaM Remake
3. Compile InstallerFull.iss

Creating Update Build:
1. Create the "BuildUpdate" folder
2. Place there only those files that have been updated since the last build
3. Compile InstallerUpdate.iss

Resulting .exe file will be placed into "Output" folder

Also you can use bat script 'bat\bat_prepare_for_installer.bat', which will make KMR build and copy all files into "Installer\BuildFull" folder
