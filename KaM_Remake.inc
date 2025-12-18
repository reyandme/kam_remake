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
{$IFDEF VER360} {$DEFINE WDC} {$DEFINE WDC12PLUS} {$ENDIF} //Define Windows Delphi 12 Yukon
{.$DEFINE FPC} //Define Free Pascal compiler (defined automatically by Lazarus)


// Lazarus compiler specific settings
{$IFDEF FPC}
  // Set FPC to work in Delphi mode
  {$MODE Delphi}
  // Allow advanced records in Lazarus
  {$modeSwitch advancedRecords}

  // Currently FPC does not define UNICODE define because in Delphi it means more than just a
  // default string type but a full RTL implementation : using Windows 'W' functions instead of 'A',
  // another class declarations(TStringStream for example).
  {$IFDEF FPC_UNICODESTRINGS}
    {$DEFINE UNICODE}
  {$ENDIF}
{$ENDIF} 


// Delphi compiler specific settings
{$IFDEF WDC}
  {$IFNDEF WDC64} // Not available on Win64
    // Project can be compiled without madExcept features (if you dont have madExcept installed)
    {$DEFINE USE_MAD_EXCEPT}
    // Delphi compiler video play
    {$DEFINE VIDEOS}
    
    {.$DEFINE FASTMM}
  {$ENDIF}

  {$DEFINE USE_VIRTUAL_TREEVIEW}
{$ENDIF}


// Promote some warnings to errors for safety (for all our tools)
//----------------------------------------------------------------------------------------------------
{$IFDEF WDC}
  {$WARN HIDING_MEMBER ERROR}         // W1009 Redeclaration of '%s' hides a member in the base class
  {$WARN HIDDEN_VIRTUAL ERROR}        // W1010 Method '%s' hides virtual method of base type '%s'
  {$WARN GARBAGE ERROR}               // W1011 Text after final 'END.' - ignored by compiler
  {$WARN BOUNDS_ERROR ERROR}          // W1012 Constant expression violates subrange bounds (Delphi)
  {$WARN FOR_VARIABLE ERROR}          // W1019 For loop control variable must be simple local variable (Delphi)
  {$WARN CONSTRUCTING_ABSTRACT ERROR} // W1020 Constructing instance of '%s' containing abstract method '%s.%s' (Delphi)
  {$WARN COMPARISON_FALSE ERROR}      // W1021 Comparison always evaluates to False
  {$WARN COMPARISON_TRUE ERROR}       // W1022 Comparison always evaluates to True
  {$WARN DUPLICATE_CTOR_DTOR ERROR}   // W1029 Duplicate %s '%s' with identical parameters will be inacessible from C++ (Delphi)
  {$WARN NO_RETVAL ERROR}             // W1035 Return value of function '%s' might be undefined
  {$WARN USE_BEFORE_DEF ERROR}        // W1036 Variable '%s' might not have been initialized
  {$WARN FOR_LOOP_VAR_UNDEF ERROR}    // W1037 FOR-Loop variable '%s' may be undefined after loop
  {$WARN UNIT_NAME_MISMATCH ERROR}    // W1038 Unit identifier '%s' does not match file name (Delphi)
  {$WARN DUPLICATES_IGNORED ERROR}    // W1051 Duplicate symbol names in namespace. Using '%s.%s' found in %s. Ignoring duplicate in %s
{$ENDIF}

// Use secure authentication unit (KM_NetAuthSecure)
{$DEFINE USESECUREAUTH}

// Enable perflog (should be disabled for release / release candidate versions)
{$DEFINE PERFLOG}

// Enable asynchronous game resource loading
{$IFNDEF NO_ASYNC_LOAD}
  {$DEFINE LOAD_GAME_RES_ASYNC}
{$ENDIF}

{.$DEFINE RNG_SPY}

// Enable some debug features
{.$DEFINE DEBUG}
