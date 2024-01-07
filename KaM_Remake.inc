// WDC/FPC defines used for RTL-specific cases
// If you use any Delphi compiler that is not listed here - you need to add it
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
{.$DEFINE FPC} //Define Free Pascal compiler (defined automatically by Lazarus)

//Lazarus compiler specific settings
{$IFDEF FPC}
  //Set FPC to work in Delphi mode
  {$MODE Delphi}
  //allow advanced records in Lazarus
  {$modeSwitch advancedRecords}

  //Currently FPC does not define UNICODE define because in Delphi it means more than just a
  //default string type but a full RTL implementation : using Windows 'W' functions instead of 'A',
  //another class declarations(TStringStream for example).
  {$IFDEF FPC_UNICODESTRINGS}
    {$DEFINE UNICODE}
  {$ENDIF}
{$ENDIF} 

//Delphi compiler specific settings
{$IFDEF WDC}
  {$IFNDEF WDC64} // Not available on Win64
    //Project can be compiled without madExcept features (if you dont have madExcept installed)
    {$DEFINE USE_MAD_EXCEPT}
    //Delphi compiler video play
    {$DEFINE VIDEOS}
    
    {.$DEFINE FASTMM}
  {$ENDIF}
  
  {$DEFINE USE_VIRTUAL_TREEVIEW}
{$ENDIF}

//Use secure authentication unit (KM_NetAuthSecure)
{$DEFINE USESECUREAUTH}

//Enable perflog (should be disabled for release / release candidate versions)
{$DEFINE PERFLOG}

//Enable asynchronius game resource loading
{$IFNDEF NO_ASYNC_LOAD}
  {$DEFINE LOAD_GAME_RES_ASYNC}
{$ENDIF}

//Enable some debug features
{.$DEFINE DEBUG}