program MapUtil;
{$I KaM_Remake.inc}
{$APPTYPE CONSOLE}
uses
  {$IFDEF UNIX}
    {$DEFINE UseCThreads}
    cthreads, //We use a thread for deleting old log files
    BaseUnix,
  {$ENDIF}
  System.SysUtils,

  KM_Defaults in '..\..\src\common\KM_Defaults.pas',
  KM_Log in '..\..\src\KM_Log.pas',

  MapUtilTypes in 'MapUtilTypes.pas',
  ConsoleMain in 'ConsoleMain.pas';


{$R *.res}


var
  fParamRecord: TCLIParamRecord;
  fArgs: string;


procedure ProcessParams;
var
  I: Integer;
begin
  if ParamCount = 0 then
  begin
    fParamRecord.ShowHelp := True;
    Exit;
  end;

  // Default value is RevealAll
  fParamRecord.FOWType := ftRevealAll;
  fParamRecord.OutputFile := '';

  I := 0; // Skip 0, as this is the EXE-path
  while I < ParamCount do
  begin
    Inc(I);
    fArgs := fArgs + ' "' + ParamStr(I) + '"';

    if (ParamStr(I) = '-h') or (ParamStr(I) = '-help') then
    begin
      fParamRecord.ShowHelp := True;
      Continue;
    end;

    if (ParamStr(I) = '-a') or (ParamStr(I) = '-revealAll') then
    begin
      fParamRecord.FOWType := ftRevealAll;
      Continue;
    end;

    if (ParamStr(I) = '-p') or (ParamStr(I) = '-revealPlayers') then
    begin
      fParamRecord.FOWType := ftRevealPlayers;
      Continue;
    end;

    if (ParamStr(I) = '-m') or (ParamStr(I) = '-revealByMapSetting') then
    begin
      fParamRecord.FOWType := ftMapSetting;
      Continue;
    end;

    if (ParamStr(I) = '-o') or (ParamStr(I) = '-outputFile') then
    begin
      if I < ParamCount then
      begin
        Inc(I);
        fArgs := fArgs + ' "' + ParamStr(I) + '"';
        fParamRecord.OutputFile := ParamStr(I);
      end;

      Continue;
    end;

    // Only allow one script file
    if fParamRecord.MapDatPath = '' then
      fParamRecord.MapDatPath := ParamStr(I);
  end;
end;


// This utility console tool generates minimap png file of a map.
// Could be compiled under Windows or Linux (added x64 config for Lazarus (tested on fpcdeluxe FPC 3.2.2 Lazarus 2.0.12))
var
  fConsoleMain: TConsoleMain;
  path: string;
begin
  try
    ExeDir := ExtractFilePath(ParamStr(0));

    ProcessParams;

    gLog := TKMLog.Create(ExtractFilePath(ParamStr(0)) + 'MapUtil.log');
    gLog.AddNoTime('Arguments: ' + fArgs);

    // Detect our location automatically based off of KaM data
    path := 'data' + PathDelim + 'defines' + PathDelim + 'unit.dat';
    if not FileExists(ExeDir + path) 
    and FileExists(ExeDir + '..\..\' + path) then
      ExeDir := ExeDir + '..\..\';

    gLog.AddNoTime('ExeDir: ' + ExeDir);

    fConsoleMain := TConsoleMain.Create;

    fConsoleMain.ShowHeader;

    // Always exit after showing help.
    if fParamRecord.ShowHelp then
    begin
      fConsoleMain.ShowHelp;
      Exit;
    end;

    fConsoleMain.Start(fParamRecord);
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, E.ClassName, ': ', E.Message); // output error to stderr

      gLog.AddTime('Exception while generating minimap: ' + E.Message);
    end;
  end;

  FreeAndNil(fConsoleMain);
end.

