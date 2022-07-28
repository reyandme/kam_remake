{$IFDEF VER140} {$DEFINE WDC} {$ENDIF} //Define Windows Delphi 6 compiler
{$IFDEF VER150} {.$DEFINE WDC} {$ENDIF} //Define Windows Delphi 7 compiler //FPC >= 3.2.0 has defined VER150, so just disable it here
{$IFDEF VER220} {$DEFINE WDC} {$ENDIF} //Define Windows Delphi XE compiler
{$IFDEF VER230} {$DEFINE WDC} {$ENDIF} //Define Windows Delphi XE2 compiler
{$IFDEF VER240} {$DEFINE WDC} {$ENDIF} //Define Windows Delphi XE3 compiler
{$IFDEF VER250} {$DEFINE WDC} {$ENDIF} //Define Windows Delphi XE4 compiler
{$IFDEF VER260} {$DEFINE WDC} {$ENDIF} //Define Windows Delphi XE5 compiler
{$IFDEF VER270} {$DEFINE WDC} {$ENDIF} //Define Windows Delphi XE6 compiler
{$IFDEF VER280} {$DEFINE WDC} {$ENDIF} //Define Windows Delphi XE7 compiler
{$IFDEF VER290} {$DEFINE WDC} {$ENDIF} //Define Windows Delphi XE8 compiler
{$IFDEF VER300} {$DEFINE WDC} {$ENDIF} //Define Windows Delphi 10 Seattle compiler
{$IFDEF VER310} {$DEFINE WDC} {$ENDIF} //Define Windows Delphi 10.1 Berlin compiler
{$IFDEF VER320} {$DEFINE WDC} {$ENDIF} //Define Windows Delphi 10.2 Tokyo compiler
{$IFDEF VER330} {$DEFINE WDC} {$ENDIF} //Define Windows Delphi 10.3 Rio compiler
{$IFDEF VER340} {$DEFINE WDC} {$ENDIF} //Define Windows Delphi 10.4 Sydney compiler
{$IFDEF VER350} {$DEFINE WDC} {$ENDIF} //Define Windows Delphi 11 Alexandria
{.$DEFINE FPC} //Define Free Pascal compiler (defined automatically in Lazarus)
