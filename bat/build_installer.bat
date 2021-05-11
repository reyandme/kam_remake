echo called build_installer.bat

call "%ISC_DIR%"\iscc.exe "..\Installer\InstallerFull.iss" > iscc.log 2>&1
