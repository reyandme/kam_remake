unit ComInterface;
{$I KaM_Remake.inc}
interface
uses
  Classes, Windows, Sysutils, Forms,
  GeneticAlgorithm;


var
  PARALLEL_RUN: Boolean = False;


type
  TGASetup = record
    MapCnt: Integer;
    Population: TGAPopulation;
  end;
  TSimSetup = record
    SimFile, WorkDir, RunningClass: String;
    SimTimeInMin, SimNumber: Integer;
  end;

  TKMComInterface = class // Communication Interface
  private
    procedure LogInConsole(aString: AnsiString);
    procedure DebugLogString(const aString: String; const aFileName: String);
    function CaptureConsoleOutput(aWorkDir: String; aCommand: String): String;
  public
    procedure DecryptSetup(aParams: String; var aSimSetup: TSimSetup; var aGASetup: TGASetup);
    function EncryptSetup(var aSimSetup: TSimSetup; var aGASetup: TGASetup; aIgnoreGenes, aIgnoreFitness: Boolean): String;
    procedure SetupSimulation(var aSimSetup: TSimSetup; var aGASetup: TGASetup);
    procedure LogSimulationResults(var aSimSetup: TSimSetup; var aGASetup: TGASetup);
    function CreateNewSimulation(var aSimSetup: TSimSetup; var aGASetup: TGASetup): Boolean;
  end;

const
  COMMAND_START = '{';
  COMMAND_END = '}';
  INT_START = '(';
  INT_END = ')';
  FLOAT_START = '[';
  FLOAT_END = ']';
  STRING_START = '<';
  STRING_END = '>';
  CMND_RunningClass = 0;
  CMND_SimTimeInMin = 1;
  CMND_SimNumber = 2;

  CMND_GA_GenCnt = 3;
  CMND_GA_MapCnt = 4;
  CMND_GA_IdvCnt = 5;
  CMND_GA_NewIdv = 6;
  CMND_GA_Fit = 7;
  CMND_GA_Genes = 8;
  CMND_GA_DONE = 9;

  DEBUG_LOG = False;
  DEBUG_INPUT = False;

implementation


procedure TKMComInterface.DebugLogString(const aString: String; const aFileName: String);
var
  debugFile: TextFile;
begin
  if not DEBUG_LOG then
    Exit;
  AssignFile(debugFile, aFileName);
  try
    rewrite(debugFile);
    writeln(debugFile, aString);
    CloseFile(debugFile);
  except
    //on E: EInOutError do
    //  writeln('File handling error occurred. Details: ', E.ClassName, '/', E.Message);
  end;
end;


procedure TKMComInterface.DecryptSetup(aParams: String; var aSimSetup: TSimSetup; var aGASetup: TGASetup);
var
  Str: String;
  Command: Byte;
  Int, GA_IdvCnt, GA_GenCnt, GA_IdvIdx, GA_GenIdx, GA_FitIdx: Integer;
  Flt: Single;

  procedure NewIdv();
  begin
    if (aGASetup.Population = nil) then
    begin
      aGASetup.Population := TGAPopulation.Create(GA_IdvCnt, GA_GenCnt, aGASetup.MapCnt, True);
      GA_IdvIdx := 0;
    end
    else
      GA_IdvIdx := GA_IdvIdx + 1;
    GA_GenIdx := 0; // Reset Genes Index
    GA_FitIdx := 0; // Reset Fitness Index
  end;

  procedure AddGene();
  begin
    aGASetup.Population.Individual[ GA_IdvIdx ].Gene[ GA_GenIdx ] := Flt;
    GA_GenIdx := GA_GenIdx + 1;
  end;

  procedure AddFitness();
  begin
    aGASetup.Population.Individual[ GA_IdvIdx ].Fitness[ GA_FitIdx ] := Flt;
    GA_FitIdx := GA_FitIdx + 1;
  end;

  function GetCommand(var aIdx: Integer): Byte;
  var
    initIdx: Integer;
  begin
    Result := 0;
    initIdx := aIdx+1;
    while (aIdx < Length(aParams)) AND (aParams[aIdx] <> COMMAND_END) do
      aIdx := aIdx + 1;
    Try
      Result := Byte(  StrToInt( copy(aParams, initIdx, aIdx-initIdx) )  );
      if (Result = CMND_GA_NewIdv) then // The only command which does not have parameter
        NewIdv();
    except
      //On E : EConvertError do
      //  Writeln ('Invalid number encountered');
    end;
  end;
  function GetString(var aIdx: Integer): String;
  var
    initIdx: Integer;
  begin
    initIdx := aIdx+1;
    while (aIdx < Length(aParams)) AND (aParams[aIdx] <> STRING_END) do
      aIdx := aIdx + 1;
    Result := copy(aParams, initIdx, aIdx-initIdx);
  end;
  function GetInt(var aIdx: Integer): Integer;
  var
    initIdx: Integer;
  begin
    Result := 0;
    initIdx := aIdx+1;
    while (aIdx < Length(aParams)) AND (aParams[aIdx] <> INT_END) do
      aIdx := aIdx + 1;
    Try
      Result := StrToInt( copy(aParams, initIdx, aIdx-initIdx) );
    except
      //On E : EConvertError do
      //  Writeln ('Invalid number encountered');
    end;
  end;
  function GetFloat(var aIdx: Integer): Single;
  var
    initIdx: Integer;
  begin
    Result := 0;
    initIdx := aIdx+1;
    while (aIdx < Length(aParams)) AND (aParams[aIdx] <> FLOAT_END) do
      aIdx := aIdx + 1;
    Try
      Result := StrToFloat( copy(aParams, initIdx, aIdx-initIdx) );
    except
      //On E : EConvertError do
      //  Writeln ('Invalid number encountered');
    end;
  end;

  procedure SaveInformation(aIdx: Integer);
  begin
    case Command of
      CMND_RunningClass: aSimSetup.RunningClass := Str;
      CMND_SimTimeInMin: aSimSetup.SimTimeInMin := Int;
      CMND_SimNumber: aSimSetup.SimNumber := Int;
      CMND_GA_MapCnt: aGASetup.MapCnt := Int;
      CMND_GA_IdvCnt: GA_IdvCnt := Int;
      CMND_GA_GenCnt: GA_GenCnt := Int;
      CMND_GA_NewIdv: NewIdv();
      CMND_GA_Genes:  AddGene();
      CMND_GA_Fit:    AddFitness();
      else begin end;
    end;
  end;
var
  K: Integer;
begin
  GA_IdvCnt := 0;
  GA_GenCnt := 0;
  aGASetup.Population := nil;

  K := 1; // Strings starts with 1
  while (K < Length(aParams)) do
  begin
    case aParams[K] of
      COMMAND_START: Command := GetCommand(K);
      STRING_START:
      begin
        Str := GetString(K);
        SaveInformation(K);
      end;
      INT_START:
      begin
        Int := GetInt(K);
        SaveInformation(K);
      end;
      FLOAT_START:
      begin
        Flt := GetFloat(K);
        SaveInformation(K);
      end;
      else begin end;
    end;
    K := K + 1;
  end;
end;


function TKMComInterface.EncryptSetup(var aSimSetup: TSimSetup; var aGASetup: TGASetup; aIgnoreGenes, aIgnoreFitness: Boolean): String;
  function CreateCommand(aCommand: Integer): String; inline;
  begin
    Result := COMMAND_START + IntToStr(aCommand) + COMMAND_END;
  end;
  function CreateString(aString: String): String; inline;
  begin
    Result := STRING_START + aString + STRING_END;
  end;
  function CreateInt(aInt: Integer): String; inline;
  begin
    Result := INT_START + IntToStr(aInt) + INT_END;
  end;
  function CreateFloat(aInt: Single): String; inline;
  begin
    Result := FLOAT_START + FloatToStr(aInt) + FLOAT_END;
  end;
  function EncryptGA(): String;
  var
    K,L: Integer;
    Pop: TGAPopulation;
  begin
    Result := '';
    Pop := aGASetup.Population;
    Result := Result + CreateCommand(CMND_GA_MapCnt) + CreateInt(aGASetup.MapCnt);
    Result := Result + CreateCommand(CMND_GA_IdvCnt) + CreateInt(Pop.Count);
    Result := Result + CreateCommand(CMND_GA_GenCnt) + CreateInt(Pop.Individual[0].GenesCount);
    for K := 0 to Pop.Count - 1 do
    begin
      Result := Result + CreateCommand(CMND_GA_NewIdv);
      if not aIgnoreGenes then
      begin
        Result := Result + CreateCommand(CMND_GA_Genes);
        for L := 0 to Pop.Individual[K].GenesCount - 1 do
          Result := Result + CreateFloat( Pop.Individual[K].Gene[L] );
      end;
      if not aIgnoreFitness then
      begin
        Result := Result + CreateCommand(CMND_GA_Fit);
        for L := 0 to Pop.Individual[K].FitnessCount - 1 do
          Result := Result + CreateFloat( Pop.Individual[K].Fitness[L] );
      end;
    end;
  end;
var
  Str: String;
begin
  Str := CreateCommand(CMND_RunningClass) + CreateString(aSimSetup.RunningClass);
  Str := Str + CreateCommand(CMND_SimTimeInMin) + CreateInt(aSimSetup.SimTimeInMin);
  Str := Str + CreateCommand(CMND_SimNumber) + CreateInt(aSimSetup.SimNumber);
  Str := Str + EncryptGA() + CreateCommand(CMND_GA_DONE);
  Result := Str;
end;


procedure TKMComInterface.LogInConsole(aString: AnsiString);
var
  OutputStream: THandleStream;
begin
  OutputStream := THandleStream.Create(GetStdHandle(STD_OUTPUT_HANDLE));
  try
    OutputStream.Write(Pointer(aString)^, Length(aString) * SizeOf(WideChar));
  finally
    OutputStream.Free;
  end;
end;


function TKMComInterface.CaptureConsoleOutput(aWorkDir: String; aCommand: String): String;
const
  CReadBuffer = 540000; // Maybe overkill but I have 16GB so who cares
var
  saSecurity: TSecurityAttributes;
  hRead, hWrite: THandle;
  suiStartup: TStartUpInfo;
  piProcess: TProcessInformation;
  pBuffer: array [0 .. CReadBuffer] of AnsiChar;
  dRead: DWORD;
  dRunning: DWORD;
  Handle: Boolean;
begin
  Result := '';

  saSecurity.nLength := SizeOf(TSecurityAttributes);
  saSecurity.bInheritHandle := True;
  saSecurity.lpSecurityDescriptor := nil;

  if CreatePipe(hRead, hWrite, @saSecurity, 0) then
  begin
    try
      FillChar(suiStartup, SizeOf(TStartupInfoW), #0);
      suiStartup.cb := SizeOf(TStartupInfoW);

      suiStartup.hStdInput := hRead;
      suiStartup.hStdOutput := hWrite;
      suiStartup.hStdError := hWrite;
      suiStartup.dwFlags := STARTF_USESTDHANDLES OR STARTF_USESHOWWINDOW;
      suiStartup.wShowWindow := SW_HIDE;

      piProcess := Default(TProcessInformation);
      UniqueString(aCommand);
      UniqueString(aWorkDir);

      Handle := CreateProcessW(
          nil,
          PWideChar(aCommand),
          @saSecurity,
          @saSecurity,
          True,
          CREATE_NEW_PROCESS_GROUP OR NORMAL_PRIORITY_CLASS,
          nil,
          PWideChar(aWorkDir),
          suiStartup,
          piProcess
        );
      CloseHandle(hWrite);
      if Handle then
      begin
        try
          repeat
            dRunning := WaitForSingleObject(piProcess.hProcess, 100);
            Application.ProcessMessages;
            // Read from buffer during execution so it does not overflow
            dRead := 0;
            if ReadFile(hRead, pBuffer[0], CReadBuffer, dRead, nil) then
            begin
              pBuffer[dRead] := #0;
              OemToAnsi(pBuffer, pBuffer);
              Result := Result + String(pBuffer);
            end;
          until (dRunning <> WAIT_TIMEOUT);
          repeat
            dRead := 0;
            if ReadFile(hRead, pBuffer[0], CReadBuffer, dRead, nil) then
            begin
              pBuffer[dRead] := #0;
              OemToAnsi(pBuffer, pBuffer);
              Result := Result + String(pBuffer);
            end;
          until (dRead < CReadBuffer);
        finally
          CloseHandle(piProcess.hProcess);
          CloseHandle(piProcess.hThread);
        end;
      end
      else
        raise Exception.Create('Can not CreateProcess ' + QuotedStr(aCommand));
    finally
      CloseHandle(hRead);
    end;
  end
  else
    raise Exception.Create('Can not CreatePipe ' + QuotedStr(aCommand));
end;

procedure TKMComInterface.SetupSimulation(var aSimSetup: TSimSetup; var aGASetup: TGASetup);
  function GetDebugParams(): String;
  begin
    Result :=
     '{'+IntToStr(CMND_RunningClass)+'}<TKMRunnerGA_CityRoadPlanner>'+
     '{'+IntToStr(CMND_SimTimeInMin)+'}(10)'+
     '{'+IntToStr(CMND_SimNumber   )+'}(1)'+
     '{'+IntToStr(CMND_GA_MapCnt   )+'}(2)'+
     '{'+IntToStr(CMND_GA_IdvCnt   )+'}(3)'+
     '{'+IntToStr(CMND_GA_GenCnt   )+'}(2)'+
     '{'+IntToStr(CMND_GA_NewIdv   )+'}'+
     '{'+IntToStr(CMND_GA_Genes    )+'}[0,1][0,3]'+
     '{'+IntToStr(CMND_GA_NewIdv   )+'}'+
     '{'+IntToStr(CMND_GA_Genes    )+'}[0,3][0,1]'+
     '{'+IntToStr(CMND_GA_NewIdv   )+'}'+
     '{'+IntToStr(CMND_GA_Genes    )+'}[0,2][0,2]'+
     '{'+IntToStr(CMND_GA_DONE     )+'}';
  end;
var
  I: Integer;
  Params: String;
begin
  Params := '';
  if DEBUG_INPUT then
    Params := GetDebugParams; // DEBUG LINE

  for I := 1 to ParamCount do
    Params := Params + ParamStr(I);

  DebugLogString(Params, 'DEBUG_ComInterface_Receive.txt');

  DecryptSetup(Params, aSimSetup, aGASetup);
end;


procedure TKMComInterface.LogSimulationResults(var aSimSetup: TSimSetup; var aGASetup: TGASetup);
var
  SetupString: String;
begin
  SetupString := EncryptSetup(aSimSetup, aGASetup, True, False);
  DebugLogString(SetupString, 'DEBUG_ComInterface_Send.txt');
  LogInConsole(SetupString);
end;


function TKMComInterface.CreateNewSimulation(var aSimSetup: TSimSetup; var aGASetup: TGASetup): Boolean;
var
  SetupString, Params: String;
begin
  SetupString := EncryptSetup(aSimSetup, aGASetup, False, True);
  DebugLogString(SetupString, 'DEBUG_ComInterface_Send.txt');

  Params := CaptureConsoleOutput(aSimSetup.WorkDir, '"' + aSimSetup.WorkDir + '\' + aSimSetup.SimFile + '" ' + SetupString + '');

  DecryptSetup(Params, aSimSetup, aGASetup);
  DebugLogString(Params, 'DEBUG_ComInterface_Receive.txt');
  Result := not ('' = Params);
end;



end.

