unit SimThread;

interface

uses
  Classes, SysUtils, Math, ComInterface;

Type
  TSimThread = class(TThread)
  private
    fSimulationSuccessful: Boolean;
    fThreadNumber: Integer;
    function SimulateGeneration(): Boolean;
    procedure Log(const aStr: String);
  protected
    procedure Execute; override;
  public
    SimSetup: TSimSetup;
    GASetup: TGASetup;

    constructor Create(aNumber: Integer; aCreateSuspended: boolean); reintroduce;
    destructor Destroy(); override;

    property SimulationSuccessful: Boolean read fSimulationSuccessful;
  end;


implementation
uses
  Log;

constructor TSimThread.Create(aNumber: Integer; aCreateSuspended: boolean);
begin
  inherited Create(aCreateSuspended);
  fThreadNumber := aNumber;
  FreeOnTerminate := False;
  Log('Thread ' + IntToStr(fThreadNumber) + ': Constructor');
end;


destructor TSimThread.Destroy();
begin
  Log('Thread ' + IntToStr(fThreadNumber) + ': Destructor');
  inherited Destroy;
end;


function TSimThread.SimulateGeneration(): Boolean;
var
  CI: TKMComInterface;
begin
  fSimulationSuccessful := False;
  Log('Thread ' + IntToStr(fThreadNumber) + ': Start simulation');
  CI := TKMComInterface.Create();
  try
    fSimulationSuccessful := CI.CreateNewSimulation(SimSetup, GASetup);
    if not fSimulationSuccessful then
      Log('Thread ' + IntToStr(fThreadNumber) + ': no output string was received');
  finally
    CI.Free;
  end;
  Log('Thread ' + IntToStr(fThreadNumber) + ': Finish simulation');
  Result := True;
end;

procedure TSimThread.Log(const aStr: String);
const
  INDENTATION = '    ';
begin
  gLog.Log(INDENTATION + aStr);
end;


procedure TSimThread.Execute();
var
  SimulationIsFinished: Boolean;
begin
  SimulationIsFinished := False;
  while (not Terminated) AND not SimulationIsFinished do
  begin
    SimulationIsFinished := SimulateGeneration();
  end;
end;



end.

