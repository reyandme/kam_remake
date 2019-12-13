unit MainSimThread;

interface

uses
  Windows,
  Classes, SysUtils, StrUtils, IOUtils, System.Math,
  ComInterface, SimThread, GeneticAlgorithm, GeneticAlgorithmParameters, PlotGraph,
  KM_Log, KM_AIParameters;

const
  SAVE_RESULTS = True;
  CREATE_BACKUPS = True;
  dir_RESULTS = 'Results';
  dir_BACKUPS = 'Backups';

type
  TStringArr = array of String;
  TKMSimulationRequest = (srRun,srNone,srTerminate);
  TMainSimThread = class(TThread)
  private
    fSimulationInitialized: Boolean;
    fSimulationRequest: TKMSimulationRequest;
    fExePath: String;
    fPlotGraph: TPlotGraph;
    fSimSetup: TSimSetup;
    fGASetup: TGASetup;
    fParLog: TKMLog;
    fParametrization: TGAParameterization;

    function RunThreads(const THREADS: Byte): Boolean;
    procedure RunSimulation();
    procedure SaveResults(aGenNumber: Integer; aPopulation: TGAPopulation);
    function SaveBackup(): Boolean;
    function LoadBackup(aBackup: String): Boolean;
  protected
    procedure Execute; override;
  public
    SIM_Class: String;
    SIM_TimeInMin: Integer; // Time of each simulation (GA doest not take simulation from game menu because it is only in minutes)
    SIM_CountThreads: Word;
    GA_Generations: Word;
    GA_CountIndividuals: Word; // Population count
    GA_CountGenes: Word; // Count of genes
    GA_CountMaps: Word; // Count of simulated maps for each invididual
    GA_START_TOURNAMENT_IndividualsCnt: Word; // Initial count of individuals in tournament
    GA_FINAL_TOURNAMENT_IndividualsCnt: Word; // Final count of individuals in tournament
    GA_START_MUTATION_ResetGene: Single; // Initial mutation (first generation)
    GA_FINAL_MUTATION_ResetGene: Single; // Final mutation (last generation)
    GA_START_MUTATION_Gaussian: Single; // Initial mutation (first generation)
    GA_FINAL_MUTATION_Gaussian: Single; // Final mutation (last generation)
    GA_START_MUTATION_Variance: Single; // Initial variance coefficient (first generation)
    GA_FINAL_MUTATION_Variance: Single; // Final variance coefficient (last generation)

    constructor Create(aPlotGraph: TPlotGraph; aExePath: String);
    destructor Destroy(); override;

    property SimulationRequest: TKMSimulationRequest read fSimulationRequest write fSimulationRequest;
    property SimulationInitialized: boolean read fSimulationInitialized write fSimulationInitialized;
    property Parametrization: TGAParameterization read fParametrization;

    function InitSimulation(aBackup: String): Boolean;
    function GetBackups(var aBackups: TStringList): Boolean;
  end;

implementation
uses
  Log;


constructor TMainSimThread.Create(aPlotGraph: TPlotGraph; aExePath: String);
var
  dir: String;
begin
  inherited Create;
  gLog.Log('TMainSimThread: Create');
  fExePath := aExePath;
  fPlotGraph := aPlotGraph;
  // Create folder for logs
  dir := Format('%s\..\%s',[ParamStr(0),dir_RESULTS]);
  if not DirectoryExists(dir) then
    CreateDir(dir);
  dir := Format('%s\%s.txt',[dir,FormatDateTime('yy-mm-dd_hh-nn-ss-zzz',Now)]);
  fParLog := TKMLog.Create(dir);
  fParametrization := TGAParameterization.Create();
  fParametrization.SetLogPar := fParLog;
  // Create folder for backups
  dir := Format('%s\..\%s',[ParamStr(0),dir_BACKUPS]);
  if not DirectoryExists(dir) then
    CreateDir(dir);

  fSimulationRequest := srNone;
  fSimulationInitialized := False;

  // Default cfg
  fParametrization.CurrentClass := 'TKMRunnerGA_TestParRun';
  SIM_Class           := fParametrization.CurrentClass;
  SIM_TimeInMin       := 65; // Time of each simulation (GA doest not take simulation from game menu because it is only in minutes)
  SIM_CountThreads    := 3; //3;
  GA_Generations      := 30; //40; // Count of generations
  GA_CountIndividuals := 30; // Count of individuals in population
  GA_CountGenes       := fParametrization.GetParCnt(); // Count of genes
  GA_CountMaps        := 27; // Count of simulated maps for each invididual
  GA_START_TOURNAMENT_IndividualsCnt := 3; // Initial count of individuals in tournament
  GA_FINAL_TOURNAMENT_IndividualsCnt := 5; // Final count of individuals in tournament
  GA_START_MUTATION_ResetGene := 0.01; // Initial mutation (first generation)
  GA_FINAL_MUTATION_ResetGene := 0.001; // Final mutation (last generation)
  GA_START_MUTATION_Gaussian := 0.1; // Initial mutation (first generation)
  GA_FINAL_MUTATION_Gaussian := 0.4; // Final mutation (last generation)
  // Gaussian distribution generates mostly (-3,3) so variance > 0.1 is recommended
  GA_START_MUTATION_Variance := 0.1; // Initial variance coefficient (first generation)
  GA_FINAL_MUTATION_Variance := 0.05; // Final variance coefficient (last generation)
end;


destructor TMainSimThread.Destroy();
begin
  if (fGASetup.Population <> nil) then
    FreeAndNil(fGASetup.Population);
  fParametrization.Free;
  fParLog.Free;
  gLog.Log('TKMMainSimThread: Destroy');
  inherited;
end;


procedure TMainSimThread.Execute();
begin
//ssIdle,ssInit,ssProgress,ssFinished,ssTerminate
  while not (Terminated OR (fSimulationRequest = srTerminate)) do
  begin
    if (fSimulationRequest = srRun) then
    begin
      RunSimulation();
      SimulationRequest := srNone;
    end;
    Sleep(100);
  end;
end;


function TMainSimThread.RunThreads(const THREADS: Byte): Boolean;
  function SplitPopulation(aStartIdx, aCnt: Integer): TGASetup;
  var
    K,L: Integer;
    DefPop: TGAPopulation;
  begin
    DefPop := fGASetup.Population;
    with Result do
    begin
      MapCnt := fGASetup.MapCnt;
      Population := TGAPopulation.Create(aCnt, DefPop.Individual[0].GenesCount, DefPop.Individual[0].FitnessCount, true);
      for K := 0 to Population.Count - 1 do
      begin
        for L := 0 to DefPop.Individual[K].FitnessCount - 1 do
          Population.Individual[K].Fitness[L] := 0;
        for L := 0 to Population.Individual[K].GenesCount - 1 do
          Population.Individual[K].Gene[L] := DefPop.Individual[aStartIdx].Gene[L];
        aStartIdx := aStartIdx + 1;
      end;
    end;
  end;
  procedure MergePopulation(aStartIdx, aCnt: Integer; var aThreadGAS: TGASetup);
  var
    K,L: Integer;
    DefPop: TGAPopulation;
  begin
    DefPop := fGASetup.Population;
    for K := 0 to aCnt - 1 do
    begin
      for L := 0 to DefPop.Individual[K].FitnessCount - 1 do
        DefPop.Individual[aStartIdx].Fitness[L] := aThreadGAS.Population.Individual[K].Fitness[L];
      aStartIdx := aStartIdx + 1;
    end;
  end;
var
  K, CntInThread, ActualIdx: Integer;
  ThreadArr: array of TSimThread;
begin
  if (fGASetup.Population = nil) OR (fGASetup.Population.Individual[0].GenesCount = 0) then
    Exit(False);

  gLog.Log('  Init Threads: ');
  SetLength(ThreadArr, THREADS);
  ActualIdx := 0;
  CntInThread := Round(fGASetup.Population.Count / (THREADS * 1.0));
  for K := 0 to THREADS - 1 do
  begin
    // Create thread
    ThreadArr[K] := TSimThread.Create(K,True);
    // Init data
    ThreadArr[K].SimSetup := fSimSetup;
    ThreadArr[K].GASetup := SplitPopulation(ActualIdx, CntInThread);
    ActualIdx := ActualIdx + CntInThread;
    if (K = THREADS - 2) then // Next cycle will be the last -> secure that all individual will be part of some thread (round problems)
      CntInThread := fGASetup.Population.Count - ActualIdx;
  end;

  gLog.Log('  Run Threads:');
  // Start thread
  for K := 0 to THREADS - 1 do
    ThreadArr[K].Start;
  // Wait till is every thread finished
  for K := 0 to THREADS - 1 do
    ThreadArr[K].WaitFor;
  // Check if all simulation threads are ok
  for K := 0 to THREADS - 1 do
    if not ThreadArr[K].SimulationSuccessful then
    begin
      //gLog.Log('');
      Exit(False);
    end;

  gLog.Log('  Collecting data: ');
  // Collect data
  ActualIdx := 0;
  CntInThread := Round(fGASetup.Population.Count / (THREADS * 1.0));
  for K := 0 to THREADS - 1 do
  begin
    MergePopulation(ActualIdx, CntInThread, ThreadArr[K].GASetup);
    ActualIdx := ActualIdx + CntInThread;
    if (K = THREADS - 2) then // Next cycle will be the last -> secure that all individual will be part of some thread (round problems)
      CntInThread := fGASetup.Population.Count - ActualIdx;
    gLog.Log('    Thread ' + IntToStr(K));
  end;

  gLog.Log('  Close threads: ');
  // Clear threads
  for K := 0 to THREADS - 1 do
    ThreadArr[K].Free;

  Result := True;
end;


function TMainSimThread.InitSimulation(aBackup: String): Boolean;
var
  K, L: Integer;
begin
  Result := False;
  fSimulationInitialized := True;
  gLog.Log('Init simulation');
  // Load default parameters (they are not stored because they can change)
  fSimSetup.SimFile := 'Runner.exe';
  fSimSetup.WorkDir := Copy( fExePath, 0, Ansipos('\RunnerParallelExtension\', fExePath) ) + 'Runner';

  // Clean up the mess
  if (fGASetup.Population <> nil) then
    FreeAndNil(fGASetup.Population);

  // Use save to load data
  if LoadBackup(aBackup) then
  begin
    Result := True;
    SIM_Class := fSimSetup.RunningClass;
    SIM_TimeInMin := fSimSetup.SimTimeInMin;
    GA_CountIndividuals := fGASetup.Population.Count;
    GA_CountGenes := fGASetup.Population.Individual[0].GenesCount;
    GA_CountMaps := fGASetup.Population.Individual[0].FitnessCount;
    // Draw graphs
    if (fPlotGraph <> nil) then
      fPlotGraph.InitSimulation(2,GA_CountIndividuals,GA_CountGenes,GA_CountMaps,1);
    if Assigned(fPlotGraph) then
        TThread.Synchronize(nil,
          procedure
          begin
            fPlotGraph.AddGeneration(fGASetup.Population);
          end
        );
  end
  else
  // Use GUI to load data
  begin
    fSimSetup.RunningClass := SIM_Class;
    fSimSetup.SimTimeInMin := SIM_TimeInMin;
    with fGASetup do
    begin
      MapCnt := GA_CountMaps; // MapCnt is property of GASetup
      Population := TGAPopulation.Create(GA_CountIndividuals, GA_CountGenes, GA_CountMaps, True);
      with Population do
        for K := 0 to Count - 1 do
        begin
          for L := 0 to Individual[K].FitnessCount - 1 do
            Individual[K].Fitness[L] := 0;
          for L := 0 to Individual[K].GenesCount - 1 do
            Individual[K].Gene[L] := Random();
        end;
    end;
  end;
end;


procedure TMainSimThread.RunSimulation();
  function TimeGetUsec(): Int64;
  var
    freq: Int64;
    newTime: Int64;
    factor: Double;
  begin
    QueryPerformanceFrequency(freq);
    QueryPerformanceCounter(newTime);
    factor := 1000000 / freq; // Separate calculation to avoid "big Int64 * 1 000 000" overflow
    Result := Round(newTime * factor);
  end;
  procedure LogTime(aStartTime: Int64);
  var
    Time: Single;
  begin
    Time := Single(TimeGetUsec()-aStartTime)/1000000.0;
    if (Time/60 < 1) then
      gLog.Log(Format('Time: %.3f [s]',[Time]))
    else if (Time/60/60 < 1) then
      gLog.Log(Format('Time: %.3f [min]',[Time/60]))
    else
      gLog.Log(Format('Time: %.3f [h]',[Time/60/60]));
  end;
var
  K: Integer;
  Ratio: Single;
  NewPopulation: TGAPopulation;
  fAlgorithm: TGAAlgorithm;
  StartT,StartGenT: int64;
begin
  // Do not override loaded simulation
  if not fSimulationInitialized then
    InitSimulation('');
  fSimulationInitialized := False;
  // The configuration could be changed (if load from file) so reset fPlotGraph
  if (fPlotGraph <> nil) then
    fPlotGraph.InitSimulation(GA_Generations,GA_CountIndividuals,GA_CountGenes,GA_CountMaps);
  gLog.Log('Starting simulation');
  StartT := TimeGetUsec();

  fAlgorithm := TGAAlgorithm.Create;
  NewPopulation := nil;
  try
    for K := 0 to GA_Generations - 1 do
    begin
      gLog.Log(IntToStr(K+1) + '. run');
      StartGenT := TimeGetUsec();
      fSimSetup.SimNumber := K + 1;
      if not RunThreads(SIM_CountThreads) then
      begin
        gLog.Log('Simulation failed!!!');
        break;
      end;

      with fAlgorithm do
      begin
        Ratio := 1 - (K / (GA_Generations * 1.0));
        fAlgorithm.MutationResetGene := Abs(GA_FINAL_MUTATION_ResetGene + (GA_START_MUTATION_ResetGene - GA_FINAL_MUTATION_ResetGene) * Ratio);
        fAlgorithm.MutationGaussian  := Abs(GA_FINAL_MUTATION_Gaussian  + (GA_START_MUTATION_Gaussian  - GA_FINAL_MUTATION_Gaussian ) * Ratio);
        fAlgorithm.MutationVariance  := Abs(GA_FINAL_MUTATION_Variance + (GA_START_MUTATION_Variance - GA_FINAL_MUTATION_Variance) * Ratio);
        fAlgorithm.IndividualsInTournament := Ceil(Abs(GA_FINAL_TOURNAMENT_IndividualsCnt + (GA_START_TOURNAMENT_IndividualsCnt - GA_FINAL_TOURNAMENT_IndividualsCnt) * Ratio));
      end;
      // Save results
      if SAVE_RESULTS then
        SaveResults(K, fGASetup.Population);
      // Save backups
      if CREATE_BACKUPS then
        SaveBackup();
      // Visualize results
      if Assigned(fPlotGraph) then
        TThread.Synchronize(nil,
          procedure
          begin
            fPlotGraph.AddGeneration(fGASetup.Population);
          end
        );

      NewPopulation := TGAPopulation.Create( fGASetup.Population.Count, fGASetup.Population.Individual[0].GenesCount, fGASetup.Population.Individual[0].FitnessCount, False);
      fAlgorithm.EvolvePopulation(fGASetup.Population, NewPopulation);
      fGASetup.Population.Free;
      fGASetup.Population := NewPopulation;
      if (fSimulationRequest = srNone) then
        break;
      LogTime(StartGenT);
    end;
  finally
    FreeAndNil(fAlgorithm);
    FreeAndNil(fGASetup.Population);
  end;
  LogTime(StartT);
  gLog.Log('Simulation finished');

end;


procedure TMainSimThread.SaveResults(aGenNumber: Integer; aPopulation: TGAPopulation);
var
  K: Integer;
  BestWIdv,BestIdv: TGAIndividual;
begin
  gLog.Log('Saving results...');
  BestWIdv := aPopulation.GetFittest(nil, True);
  fParLog.AddTime('');
  fParLog.AddTime(Format('%.2d. generation; best weighted individual (fitness = %f15.5)',[aGenNumber,BestWIdv.FitnessSum]));
  fParLog.AddTime('');
  fParLog.AddTime('GA parameters:');
  for K := 0 to BestWIdv.GenesCount - 1 do
    fParLog.AddTime(Format('%16.15f',[BestWIdv.Gene[K]]));
  fParLog.AddTime('KaM Parameters:');
  fParametrization.SetPar(BestWIdv,True);

  BestIdv := aPopulation.GetFittest(nil, True);
  if (BestWIdv <> BestIdv) then
  begin
    fParLog.AddTime(Format('%.2d. generation; best individual (fitness = %f15.5)',[aGenNumber,BestIdv.FitnessSum]));
    fParLog.AddTime('GA parameters:');
    for K := 0 to BestIdv.GenesCount - 1 do
      fParLog.AddTime(Format('%16.15f',[BestIdv.Gene[K]]));
    fParLog.AddTime('KaM Parameters:');
    fParametrization.SetPar(BestIdv,True);
  end;
  gLog.Log('Results have been saved!');
end;


function TMainSimThread.SaveBackup(): Boolean;
var
  BackupFile: TextFile;
  CI: TKMComInterface;
begin
  gLog.Log('Saving backup...');
  Result := True;
  CI := TKMComInterface.Create();
  try
    AssignFile(BackupFile, Format('%s/%s_%s.txt',[dir_BACKUPS,SIM_Class,FormatDateTime('yy-mm-dd_hh-nn-ss-zzz',Now)]) );
    try
      Rewrite(BackupFile);
      Writeln(BackupFile, CI.EncryptSetup(fSimSetup, fGASetup, False, False) );
      CloseFile(BackupFile);
    except
      Result := False;
    end;
  finally
    CI.Free();
  end;
  gLog.Log('Backup has been saved!');
end;


function TMainSimThread.LoadBackup(aBackup: String): Boolean;
var
  CI: TKMComInterface;
begin
  Result := True;
  gLog.Log('Loading backup...');
  if not FileExists(aBackup) then
  begin
    gLog.Log(Format('Backup %s does not exist!!!',[aBackup]));
    Exit(False);
  end;
  CI := TKMComInterface.Create();
  try
    try
      CI.DecryptSetup(TFile.ReadAllText(aBackup), fSimSetup, fGASetup);
    except
      gLog.Log('Backup is corrupted!!!');
      Result := False;
    end;
  finally
    CI.Free();
  end;
  if Result then
    gLog.Log('Backup has been loaded!');
end;


function TMainSimThread.GetBackups(var aBackups: TStringList): Boolean;
var
  Backup: String;
begin
  FreeAndNil(aBackups);
  aBackups := TStringList.Create();
  for Backup in TDirectory.GetFiles(dir_BACKUPS) do
    if (CompareStr(ExtractFileExt(Backup),'.txt') = 0) AND ContainsText(ExtractFileName(Backup),'TKMRunnerGA_') then
      aBackups.Add(Backup);
  Result := aBackups.Count > 0;
end;


{
  // Init result file
  AssignFile(ResultsFile, RESULTS_FILE_NAME);
  AssignFile(GAFile, BACKUP_GA_FILE_NAME);
  try
    rewrite(ResultsFile);
    CloseFile(ResultsFile);
    rewrite(GAFile);
    CloseFile(GAFile);
  except
    on E: EInOutError do
      gLog.Log('TPlotGraph: File handling error occurred.');
  end;
}


end.
