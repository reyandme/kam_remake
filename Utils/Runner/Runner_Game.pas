unit Runner_Game;
{$I KaM_Remake.inc}
interface
uses
  Forms, Unit_Runner, Windows, SysUtils, Classes, KromUtils, Math,
  KM_CommonClasses, KM_Defaults, KM_Points, KM_CommonUtils, KM_HandLogistics,
  KM_GameApp, KM_ResLocales, KM_Log, KM_HandsCollection, KM_HouseCollection, KM_ResTexts, KM_Resource,
  KM_Terrain, KM_Units, KM_UnitWarrior, KM_Campaigns, KM_AIFields, KM_Houses,
  GeneticAlgorithm, GeneticAlgorithmParameters, KM_AIParameters,
  ComInterface;


type
  //Typical usage:
  //SetUp, Execute(1), Execute(2) .. Execute(N), TearDown

  TKMRunnerGA_Common = class(TKMRunnerCommon)
  private
    fCrashDetectionMode: Boolean; // only for single thread
    fAlgorithm: TGAAlgorithm;
    fParametrization: TGAParameterization;
    fOldPopulation, fNewPopulation: TGAPopulation;
    //fFitnessCalc: TGAFitnessCalc;
    fLog, fLogPar: TKMLog;

    f_SIM_SimulationTimeInMin: Single; // Time of each simulation (GA doest not take simulation from game menu because it is only in minutes)
    f_SIM_NumberOfMaps: Word; // Count of simulated maps for each invididual
    f_GA_POPULATION_CNT: Word; // Population count
    f_GA_GENE_CNT: Word; // Count of genes
    f_GA_START_TOURNAMENT_IndividualsCnt: Word; // Initial count of individuals in tournament
    f_GA_FINAL_TOURNAMENT_IndividualsCnt: Word; // Final count of individuals in tournament
    f_GA_START_MUTATION_ResetGene: Single; // Initial mutation (first generation)
    f_GA_FINAL_MUTATION_ResetGene: Single; // Final mutation (last generation)
    f_GA_START_MUTATION_Gaussian: Single; // Initial mutation (first generation)
    f_GA_FINAL_MUTATION_Gaussian: Single; // Final mutation (last generation)
    f_GA_START_MUTATION_Variance: Single; // Initial mutation (first generation)
    f_GA_FINAL_MUTATION_Variance: Single; // Final mutation (last generation)

    procedure SetRndGenes(); virtual;
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
    procedure InitGAParameters(); virtual;
    procedure SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False); virtual; abstract;
    procedure SimulateMap(aRun, aIdx, Seed: Integer; aSinglePLMapName: String; aSaveGame: Boolean = False); virtual;
    function CostFunction(): Single; virtual;
    procedure Execute(aRun: Integer); override;
  public
    SimSetup: TSimSetup;
    IOData: TGASetup;
  end;

  TKMRunnerGA_TestParRun = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
    procedure Execute(aRun: Integer); override;
  end;

  TKMRunnerGA_HandLogistics = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
  end;

  TKMRunnerGA_Manager = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
  end;

  TKMRunnerGA_CityBuilder = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
  end;

  TKMRunnerGA_Farm = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
  end;

  TKMRunnerGA_Quarry = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
  end;

  TKMRunnerGA_RoadPlanner = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
  end;

  TKMRunnerGA_Forest = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
  end;

  TKMRunnerGA_CityPlanner = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
  end;

  TKMRunnerFindBugs = class(TKMRunnerCommon)
  private
    fBestScore, fWorstScore, fAverageScore: Double;
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
    procedure Execute(aRun: Integer); override;
  end;

  TKMRunnerStone = class(TKMRunnerCommon)
  protected
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
    procedure TearDown; override;
  end;

  TKMRunnerFight95 = class(TKMRunnerCommon)
  protected
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
    procedure TearDown; override;
  end;

  TKMRunnerAIBuild = class(TKMRunnerCommon)
  private
    HTotal, WTotal, WFTotal, GTotal: Cardinal;
    HAver, WAver, WFAver, GAver: Single;
    HandsCnt, Runs: Integer;
    Time: Cardinal;
  protected
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
    procedure TearDown; override;
  end;

  TKMVortamicPF = class(TKMRunnerCommon)
  protected
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
    procedure TearDown; override;
  end;

  TKMReplay = class(TKMRunnerCommon)
  protected
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
    procedure TearDown; override;
  end;

  TKMVas01 = class(TKMRunnerCommon)
  protected
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
    procedure TearDown; override;
  end;


  TKMStabilityTest = class(TKMRunnerCommon)
  private
    fTime: Cardinal;
    fRuns: Integer;
  protected
    procedure SetUp; override;
    procedure TearDown(); override;
    procedure Execute(aRun: Integer); override;
  end;


implementation
uses KM_HandSpectator, KM_ResWares, KM_ResHouses, KM_Hand, KM_UnitsCollection;




{ TKMRunnerGA_Common }
procedure TKMRunnerGA_Common.InitGAParameters();
begin
  f_SIM_SimulationTimeInMin      := 10;
  f_SIM_NumberOfMaps             := 3;
  f_GA_POPULATION_CNT            := 2;
  f_GA_GENE_CNT                  := 5;
  f_GA_START_TOURNAMENT_IndividualsCnt := 3;
  f_GA_FINAL_TOURNAMENT_IndividualsCnt := 3;
  f_GA_START_MUTATION_ResetGene  := 1;
  f_GA_FINAL_MUTATION_ResetGene  := 5;
  f_GA_START_MUTATION_Gaussian   := 10;
  f_GA_FINAL_MUTATION_Gaussian   := 20;
  f_GA_START_MUTATION_Variance := 1;
  f_GA_FINAL_MUTATION_Variance := 0.1;
end;

procedure TKMRunnerGA_Common.SetUp;
var
  K,L: Integer;
  Pop: TGAPopulation;
begin
  inherited;
  // Create parametrization
  fParametrization := TGAParameterization.Create;
  // Deactivate KaM log
  if (gLog = nil) then
    gLog := TKMLog.Create(Format('%s\Utils\Runner\Runner_Log.log',[ExeDir]));
  gLog.MessageTypes := [];
  // Init common variables
  fOldPopulation := nil;
  fAlgorithm := TGAAlgorithm.Create;
  InitGAParameters();

  // Prepare parallel simulation
  if PARALLEL_RUN then
  begin
    fCrashDetectionMode := False;
    f_SIM_SimulationTimeInMin := SimSetup.SimTimeInMin;
    f_SIM_NumberOfMaps := IOData.MapCnt;
    Pop := IOData.Population;
    if (Pop <> nil) then
    begin
      f_GA_POPULATION_CNT := Pop.Count;
      f_GA_GENE_CNT := Pop.Individual[0].GenesCount;
      // Create new population and copy genes
      fNewPopulation := TGAPopulation.Create(Pop.Count, Pop.Individual[0].GenesCount, f_SIM_NumberOfMaps, True);
      for K := 0 to fNewPopulation.Count - 1 do
        for L := 0 to fNewPopulation.Individual[K].GenesCount - 1 do
          fNewPopulation.Individual[K].Gene[L] := Pop.Individual[K].Gene[L];
    end;
  end
  else
  begin
    fCrashDetectionMode := True;
    // Init new population
    fNewPopulation := TGAPopulation.Create(f_GA_POPULATION_CNT, f_GA_GENE_CNT, f_SIM_NumberOfMaps, True);
    SetRndGenes();
    // Init logs
    fLog := TKMLog.Create(Format('%s\Utils\Runner\LOG_GA.log',[ExeDir]));
    fLogPar := TKMLog.Create(Format('%s\Utils\Runner\LOG_GA_PAR.log',[ExeDir]));
    fParametrization.SetLogPar := fLogPar;
  end;
  // Init simulation
  fResults.ValueCount := 1;
  fResults.TimesCount := Ceil(10*60 * f_SIM_SimulationTimeInMin);
end;


procedure TKMRunnerGA_Common.TearDown;
var
  K,L: Integer;
begin
  // Copy fitness
  if PARALLEL_RUN then
  begin
    for K := 0 to fOldPopulation.Count - 1 do
      for L := 0 to f_SIM_NumberOfMaps - 1 do
        IOData.Population.Individual[K].Fitness[L] := fOldPopulation.Individual[K].Fitness[L];
  end
  else
  begin
    fLog.Free;
    fLogPar.Free;
  end;
  // Do something after simulation
  FreeAndNil(fOldPopulation);
  FreeAndNil(fNewPopulation);
  FreeAndNil(fAlgorithm);
  fParametrization.Free;
  inherited;
end;


procedure TKMRunnerGA_Common.SetRndGenes();
var
  K,L: Integer;
  Idv: TGAIndividual;
begin
  for K := 0 to fNewPopulation.Count - 1 do
  begin
    Idv := fNewPopulation[K];
    for L := 0 to Idv.GenesCount - 1 do
      Idv.Gene[L] := Random;
  end;
end;


procedure TKMRunnerGA_Common.SimulateMap(aRun, aIdx, Seed: Integer; aSinglePLMapName: String; aSaveGame: Boolean = False);
begin
  gGameApp.NewSingleMap(Format('%s..\..\Maps\%s\%s.dat',[ExtractFilePath(ParamStr(0)),aSinglePLMapName,aSinglePLMapName]), 'GA');

  //gMySpectator.Hand.FogOfWar.RevealEverything;
  //gGameApp.Game.GamePlayInterface.Viewport.PanTo(KMPointF(0, 60), 0);
  //gGameApp.Game.GamePlayInterface.Viewport.Zoom := 0.25;
  if fCrashDetectionMode then
    gGameApp.Game.Save('GA Test', Now);

  //SetKaMSeed(Max(1,Seed));
  try
    SimulateGame;
  except
    SimulateMap(aRun + 1, aIdx, Round(Random()*10000)+1, aSinglePLMapName);
  end;
  if aSaveGame then
    gGameApp.Game.Save(Format('GA Test #%dn%d',[aRun,aIdx]), Now);
end;


function TKMRunnerGA_Common.CostFunction(): Single;
const
  PL = 1;
  HOUSE_WEIGHT = 1;
  WEAPONS_WEIGHT = 1;
  CITIZENS_LOST = 10;
  IRON_SOLDIER = 20;
  WOOD_SOLDIER = 10;
  MILITIA_SOLDIER = 3;
  COMPLETE_HOUSE = 5;
var
  I: Integer;
  IronArmy, WoodArmy, Militia, Output: Single;
begin
  with gHands[PL].Stats do
  begin
    Output := + GetHouseQty(htAny) * HOUSE_WEIGHT
              + GetWeaponsProduced * WEAPONS_WEIGHT
              - GetCitizensLost * CITIZENS_LOST;
    IronArmy := Min( GetWaresProduced(wtMetalArmor),
                       GetWaresProduced(wtHallebard)
                     + GetWaresProduced(wtArbalet)
                     + Min(GetWaresProduced(wtSword), GetWaresProduced(wtMetalShield))
                   );
    WoodArmy := Min( GetWaresProduced(wtArmor),
                       GetWaresProduced(wtBow)
                     + GetWaresProduced(wtPike)
                     + Min(GetWaresProduced(wtShield), GetWaresProduced(wtAxe))
                   );
    Militia := Min( Max(0,WoodArmy - GetWaresProduced(wtArmor)), GetWaresProduced(wtAxe));
    Output := Output
              + IronArmy * IRON_SOLDIER
              + WoodArmy * WOOD_SOLDIER
              + Militia * MILITIA_SOLDIER;
  end;

  for I := 0 to gHands[PL].Houses.Count - 1 do
    Output := Output + Byte(gHands[PL].Houses[I].IsComplete) * COMPLETE_HOUSE;

  Result := Output;
end;


procedure TKMRunnerGA_Common.Execute(aRun: Integer);
const
  MIN_SCORE = - 1000000;
var
  K, MapNum: Integer;
  BestScore, Ratio: Single;
  Idv: TGAIndividual;
begin
  // Set up parameters
  Ratio := 1 - aRun / (fResults.ChartsCount * 1.0);
  fAlgorithm.MutationResetGene := Abs(f_GA_FINAL_MUTATION_ResetGene + (f_GA_START_MUTATION_ResetGene - f_GA_FINAL_MUTATION_ResetGene) * Ratio);
  fAlgorithm.MutationGaussian  := Abs(f_GA_FINAL_MUTATION_Gaussian  + (f_GA_START_MUTATION_Gaussian  - f_GA_FINAL_MUTATION_Gaussian ) * Ratio);
  fAlgorithm.MutationVariance  := Abs(f_GA_FINAL_TOURNAMENT_IndividualsCnt + (f_GA_START_TOURNAMENT_IndividualsCnt - f_GA_FINAL_MUTATION_Variance) * Ratio);
  fAlgorithm.IndividualsInTournament := Ceil(Abs(f_GA_FINAL_TOURNAMENT_IndividualsCnt + (f_GA_START_TOURNAMENT_IndividualsCnt - f_GA_FINAL_TOURNAMENT_IndividualsCnt) * Ratio));

  // Evolve population in next run (used because of parallel run)
  if (fOldPopulation <> nil) then
  begin
    fAlgorithm.EvolvePopulation(fOldPopulation, fNewPopulation);
    fOldPopulation.Free;
  end;

  fOldPopulation := fNewPopulation;
  fNewPopulation := nil;
  for MapNum := 1 to f_SIM_NumberOfMaps do
    for K := 0 to f_GA_POPULATION_CNT - 1 do
    begin
      fParametrization.SetPar(fOldPopulation[K], False);
      // Save GA parameters so the game will be identical
      if fCrashDetectionMode then
      begin
        if (fLogPar <> nil) then
          fLogPar.Free;
        fLogPar := TKMLog.Create(Format('%s\Utils\Runner\LOG_GA_PAR.log',[ExeDir]));
        fParametrization.SetPar(fOldPopulation[K], True);
      end;
      SimulateMap(aRun, K, aRun, Format('GA_S1_%.3d',[MapNum]));// Name of maps are GA_001, GA_002 so use %.3d to fill zeros
      fOldPopulation[K].Fitness[MapNum-1] := CostFunction();
    end;

  if not PARALLEL_RUN then
  begin
    fNewPopulation := TGAPopulation.Create(f_GA_POPULATION_CNT, f_GA_GENE_CNT, f_SIM_NumberOfMaps, False);

    // Save best score + parameters of best individual
    Idv := fOldPopulation.GetFittest();
    fResults.Value[aRun, 0] := Round(Idv.FitnessSum);
    fLog.AddTime(Format('GA: %4d. run. Best score: %15.5f',[aRun,Idv.FitnessSum]));

    // Check history and find the most fitness individual
    BestScore := MIN_SCORE;
    for K := 0 to aRun - 1 do
      if (fResults.Value[K, 0] > BestScore) then
        BestScore := fResults.Value[K, 0];
    // If is the individual from the latest generation the best then log parameters
    if (BestScore < Idv.FitnessSum) then
      fParametrization.SetPar(Idv, not PARALLEL_RUN);
  end;

  // Stop simulation
  gGameApp.StopGame(grSilent);
end;




{ TKMRunnerGA_TestParRun }
procedure TKMRunnerGA_TestParRun.InitGAParameters();
begin
  inherited;
  f_GA_GENE_CNT := fParametrization.GetParCnt('TKMRunnerGA_TestParRun');
end;


procedure TKMRunnerGA_TestParRun.Execute(aRun: Integer);
var
  K,L,MapNum: Integer;
  Fitness: Single;
begin
  // Fitness is calculated from genes in this debug class
  if (fNewPopulation <> nil) then
    for MapNum := 0 to f_SIM_NumberOfMaps - 1 do
      for K := 0 to fNewPopulation.Count - 1 do
      begin
        Fitness := 0;
        for L := 0 to fNewPopulation.Individual[K].GenesCount - 1 do
          Fitness := Fitness - abs(L / fNewPopulation.Individual[K].GenesCount - fNewPopulation.Individual[K].Gene[L]);
        fNewPopulation.Individual[K].Fitness[MapNum] := Fitness;
      end;
  fOldPopulation := fNewPopulation;
  fNewPopulation := nil;

  //Sleep(500); // Debug sleep

  // Stop simulation
  gGameApp.StopGame(grSilent);
end;




{ TKMRunnerGA_HandLogistics }
procedure TKMRunnerGA_HandLogistics.InitGAParameters();
begin
  inherited;
  f_GA_GENE_CNT := fParametrization.GetParCnt('TKMRunnerGA_HandLogistics');
end;


{ TKMRunnerGA_Manager }
procedure TKMRunnerGA_Manager.InitGAParameters();
begin
  inherited;
  f_GA_GENE_CNT := fParametrization.GetParCnt('TKMRunnerGA_Manager');
end;


{ TKMRunnerGA_CityBuilder }
procedure TKMRunnerGA_CityBuilder.InitGAParameters();
begin
  inherited;
  f_GA_GENE_CNT := fParametrization.GetParCnt('TKMRunnerGA_CityBuilder');
end;

{ TKMRunnerGA_Farm }
procedure TKMRunnerGA_Farm.InitGAParameters();
begin
  inherited;
  f_GA_GENE_CNT := fParametrization.GetParCnt('TKMRunnerGA_Farm');
end;

{ TKMRunnerGA_Quarry }
procedure TKMRunnerGA_Quarry.InitGAParameters();
begin
  inherited;
  f_GA_GENE_CNT := fParametrization.GetParCnt('TKMRunnerGA_Quarry');
end;

{ TKMRunnerGA_RoadPlanner }
procedure TKMRunnerGA_RoadPlanner.InitGAParameters();
begin
  inherited;
  f_GA_GENE_CNT := fParametrization.GetParCnt('TKMRunnerGA_RoadPlanner');
end;

{ TKMRunnerGA_Forest }
procedure TKMRunnerGA_Forest.InitGAParameters();
begin
  inherited;
  f_GA_GENE_CNT := fParametrization.GetParCnt('TKMRunnerGA_Forest');
end;

{ TKMRunnerGA_CityPlanner }
procedure TKMRunnerGA_CityPlanner.InitGAParameters();
begin
  inherited;
  f_GA_GENE_CNT := fParametrization.GetParCnt('TKMRunnerGA_CityPlanner');
end;





{ TKMRunnerFindBugs }
procedure TKMRunnerFindBugs.SetUp();
begin
  inherited;
  // Deactivate KaM log
  if (gLog = nil) then
    gLog := TKMLog.Create(Format('%s\Utils\Runner\Runner_Log.log',[ExeDir]));
  gLog.MessageTypes := [];
end;


procedure TKMRunnerFindBugs.TearDown();
begin
  inherited;
end;


procedure TKMRunnerFindBugs.Execute(aRun: Integer);
  function EvalGame(): Double;
  const
    PL = 1;
    HOUSE_WEIGHT = 1;
    WEAPONS_WEIGHT = 1;
    CITIZENS_LOST = 10;
    IRON_SOLDIER = 20;
    WOOD_SOLDIER = 10;
    MILITIA_SOLDIER = 3;
    COMPLETE_HOUSE = 5;
  var
    I: Integer;
    IronArmy, WoodArmy, Militia, Output: Single;
  begin
    with gHands[PL].Stats do
    begin
      Output := + GetHouseQty(htAny) * HOUSE_WEIGHT
                + GetWeaponsProduced * WEAPONS_WEIGHT
                - GetCitizensLost * CITIZENS_LOST;
      IronArmy := Min( GetWaresProduced(wtMetalArmor),
                         GetWaresProduced(wtHallebard)
                       + GetWaresProduced(wtArbalet)
                       + Min(GetWaresProduced(wtSword), GetWaresProduced(wtMetalShield))
                     );
      WoodArmy := Min( GetWaresProduced(wtArmor),
                         GetWaresProduced(wtBow)
                       + GetWaresProduced(wtPike)
                       + Min(GetWaresProduced(wtShield), GetWaresProduced(wtAxe))
                     );
      Militia := Min( Max(0,WoodArmy - GetWaresProduced(wtArmor)), GetWaresProduced(wtAxe));
      Output := Output
                + IronArmy * IRON_SOLDIER
                + WoodArmy * WOOD_SOLDIER
                + Militia * MILITIA_SOLDIER;
    end;

    for I := 0 to gHands[PL].Houses.Count - 1 do
      Output := Output + Byte(gHands[PL].Houses[I].IsComplete) * COMPLETE_HOUSE;

    Result := Output;
  end;
const
  // Maps for simulation (I dont use for loop in this array)
  //MAPS: array [1..27] of String = ('GA_S1_001','GA_S1_002','GA_S1_003','GA_S1_004','GA_S1_005','GA_S1_006','GA_S1_007','GA_S1_008','GA_S1_009','GA_S1_010','GA_S1_011','GA_S1_012','GA_S1_013','GA_S1_014','GA_S1_015','GA_S1_016','GA_S1_017','GA_S1_018','GA_S1_019','GA_S1_020','GA_S1_021','GA_S1_022','GA_S1_023','GA_S1_024','GA_S1_025','GA_S1_026','GA_S1_027');
  MAPS: array [1..12] of String = ('GA_S1_002','GA_S1_003','GA_S1_007','GA_S1_008','GA_S1_010','GA_S1_014','GA_S1_015','GA_S1_019','GA_S1_023','GA_S1_024','GA_S1_026','GA_S1_027');
  cnt_MAP_SIMULATIONS = 25;
  CRASH_DETECTION_MODE = True;
var
  K,L: Integer;
  Score: Double;
  MapName: String;
begin
  for K := Low(MAPS) to High(MAPS) do
  begin
    fBestScore := -1e30;
    fAverageScore := 0;
    fWorstScore := 1e30;
    MapName := MAPS[K];
    for L := 1 to cnt_MAP_SIMULATIONS do
    begin
      gGameApp.NewSingleMap(Format('%s..\..\Maps\%s\%s.dat',[ExtractFilePath(ParamStr(0)),MapName,MapName]), MapName);

      if CRASH_DETECTION_MODE then
        gGameApp.Game.Save('CrashDetection', Now);

      //SetKaMSeed(Max(1,Seed));
      SimulateGame();
      Score := Max(0,EvalGame());
      fAverageScore := fAverageScore + Score;
      //gGameApp.Game.Save(Format('%s__No_%.3d__Score_%.6d',[MapName, K, Round(Score)]), Now);
      if (Score < fWorstScore) AND (cnt_MAP_SIMULATIONS > 1) then
      begin
        fWorstScore := Score;
        gGameApp.Game.Save(Format('W__%s__No_%.3d__Score_%.6d',[MapName, L, Round(Score)]), Now);
      end;
      if (Score > fBestScore) AND (cnt_MAP_SIMULATIONS > 1) then
      begin
        fBestScore := Score;
        gGameApp.Game.Save(Format('B__%s__No_%.3d__Score_%.6d',[MapName, L, Round(Score)]), Now);
      end;
    end;
    fAverageScore := fAverageScore / Double(cnt_MAP_SIMULATIONS);
    gGameApp.Game.Save(Format('AVRG_%s__%.6d',[MapName, Round(fAverageScore)]), Now);
  end;

  gGameApp.StopGame(grSilent);
end;




{ TKMRunnerStone }
procedure TKMRunnerStone.SetUp;
begin
  inherited;
  fResults.ValueCount := 1;
//  fResults.TimesCount := 0;

  AI_GEN_INFLUENCE_MAPS := False;
  AI_GEN_NAVMESH := False;
  DYNAMIC_TERRAIN := False;
end;


procedure TKMRunnerStone.TearDown;
begin
  inherited;
  AI_GEN_INFLUENCE_MAPS := True;
  AI_GEN_NAVMESH := True;
  DYNAMIC_TERRAIN := True;
end;


procedure TKMRunnerStone.Execute(aRun: Integer);
var
  I,K: Integer;
  L: TKMPointList;
  P: TKMPoint;
begin
  //Total amount of stone = 4140
  gTerrain := TKMTerrain.Create;
//  gTerrain.LoadFromFile(ExeDir + 'Maps\StoneMines\StoneMines.map', False);
  gTerrain.LoadFromFile(ExeDir + 'Maps\StoneMinesTest\StoneMinesTest.map', False);

  SetKaMSeed(aRun+1);

  //Stonemining is done programmatically, by iterating through all stone tiles
  //and mining them if conditions are right (like Stonemasons would do)

  L := TKMPointList.Create;
  for I := 1 to gTerrain.MapY - 2 do
  for K := 1 to gTerrain.MapX - 1 do
  if gTerrain.TileIsStone(K,I) > 0 then
    L.Add(KMPoint(K,I));

  I := 0;
  fResults.Value[aRun, 0] := 0;
  repeat
    L.GetRandom(P);

    if gTerrain.TileIsStone(P.X,P.Y) > 0 then
    begin
      if gTerrain.CheckPassability(KMPointBelow(P), tpWalk) then
      begin
        gTerrain.DecStoneDeposit(P);
        fResults.Value[aRun, 0] := fResults.Value[aRun, 0] + 3;
        I := 0;
      end;
    end
    else
      L.Remove(P);

    Inc(I);
    if I > 200 then
      Break;
  until (L.Count = 0);

  FreeAndNil(gTerrain);
end;




{ TKMRunnerFight95 }
procedure TKMRunnerFight95.SetUp;
begin
  inherited;
  fResults.ValueCount := 2;
//  fResults.TimesCount := 2*60*10;

  DYNAMIC_TERRAIN := False;
end;


procedure TKMRunnerFight95.TearDown;
begin
  inherited;
  DYNAMIC_TERRAIN := True;
end;


procedure TKMRunnerFight95.Execute(aRun: Integer);
begin
  gGameApp.NewEmptyMap(128, 128);
  SetKaMSeed(aRun + 1);

  //fPlayers[0].AddUnitGroup(ut_Cavalry, KMPoint(63, 64), dir_E, 8, 24);
  //fPlayers[1].AddUnitGroup(ut_Swordsman, KMPoint(65, 64), dir_W, 8, 24);

  //fPlayers[0].AddUnitGroup(ut_Swordsman, KMPoint(63, 64), dir_E, 8, 24);
  //fPlayers[1].AddUnitGroup(ut_Hallebardman, KMPoint(65, 64), dir_W, 8, 24);

  //fPlayers[0].AddUnitGroup(ut_Hallebardman, KMPoint(63, 64), dir_E, 8, 24);
  //fPlayers[1].AddUnitGroup(ut_Cavalry, KMPoint(65, 64), dir_W, 8, 24);

  gHands[0].AddUnitGroup(utSwordsman, KMPoint(63, 64), TKMDirection(dirE), 8, 24);
  gHands[1].AddUnitGroup(utSwordsman, KMPoint(65, 64), TKMDirection(dirW), 8, 24);

  gHands[1].UnitGroups[0].OrderAttackUnit(gHands[0].Units[0], True);

  SimulateGame;

  fResults.Value[aRun, 0] := gHands[0].Stats.GetUnitQty(utAny);
  fResults.Value[aRun, 1] := gHands[1].Stats.GetUnitQty(utAny);

  gGameApp.StopGame(grSilent);
end;




{ TKMRunnerAIBuild }
procedure TKMRunnerAIBuild.SetUp;
begin
  inherited;
  if gLog = nil then
    gLog := TKMLog.Create(ExeDir + 'Utils\Runner\Runner_Log.log');

  fResults.ValueCount := 6;
//  fResults.TimesCount := 60*60*10;
  fResults.TimesCount := 10;
  HTotal := 0;
  HAver := 0;
  WTotal := 0;
  WAver := 0;
  GTotal := 0;
  GAver := 0;
  Runs := 0;
  Time := TimeGet;

  //SKIP_LOADING_CURSOR := True;
end;


procedure TKMRunnerAIBuild.TearDown;
begin
  //
  HAver := HTotal / (Runs*HandsCnt);
  WAver := WTotal / (Runs*HandsCnt);
  WFAver := WFTotal / (Runs*HandsCnt);
  GAver := GTotal / (Runs*HandsCnt);

  gLog.AddTime('==================================================================');
  gLog.AddTime(Format('HAver: %3.2f  WAver: %3.2f  WFAver: %3.2f  GAver: %5.2f', [HAver, WAver, WFAver, GAver]));
  gLog.AddTime('TimeAver: ' + IntToStr(Round(GetTimeSince(Time)/Runs)));
  gLog.AddTime('Time: ' + IntToStr(GetTimeSince(Time)));
  inherited;
end;


procedure TKMRunnerAIBuild.Execute(aRun: Integer);
var Str: String;
    I: Integer;
    HRun, HRunT, WRun, WRunT, WFRun, WFRunT, GRun, GRunT: Cardinal;
    StartT: Cardinal;
begin
  //gGameApp.NewSingleMap(ExtractFilePath(ParamStr(0)) + '..\..\MapsMP\Cursed Ravine\Cursed Ravine.dat', 'Cursed Ravine');
  gGameApp.NewSingleMap(ExtractFilePath(ParamStr(0)) + '..\..\Maps\GA_'+IntToStr(aRun+1)+'\GA_'+IntToStr(aRun+1)+'.dat', 'GA');
  Inc(Runs);
  gMySpectator.Hand.FogOfWar.RevealEverything;
  gGameApp.Game.GamePlayInterface.Viewport.PanTo(KMPointF(136, 25), 0);
  gGameApp.Game.GamePlayInterface.Viewport.Zoom := 0.25;

  SetKaMSeed(aRun + 1);
  StartT := TimeGet;

  SimulateGame;

  gGameApp.Game.Save('AI Build #' + IntToStr(aRun), Now);

  {fResults.Value[aRun, 0] := gHands[0].Stats.GetWarriorsTrained;
  fResults.Value[aRun, 1] := gHands[1].Stats.GetWarriorsTrained;
  fResults.Value[aRun, 2] := gHands[2].Stats.GetWarriorsTrained;
  fResults.Value[aRun, 3] := gHands[3].Stats.GetWarriorsTrained;
  fResults.Value[aRun, 4] := gHands[4].Stats.GetWarriorsTrained;
  fResults.Value[aRun, 5] := gHands[5].Stats.GetWarriorsTrained;}

  {fResults.Value[aRun, 0] := gHands[0].Stats.GetGoodsProduced(rt_Stone);
  fResults.Value[aRun, 1] := gHands[1].Stats.GetGoodsProduced(rt_Stone);
  fResults.Value[aRun, 2] := gHands[2].Stats.GetGoodsProduced(rt_Stone);
  fResults.Value[aRun, 3] := gHands[3].Stats.GetGoodsProduced(rt_Stone);
  fResults.Value[aRun, 4] := gHands[4].Stats.GetGoodsProduced(rt_Stone);}

//  fResults.Value[aRun, 0] := gHands[0].Stats.GetHousesBuilt;
//  fResults.Value[aRun, 1] := gHands[1].Stats.GetHousesBuilt;
//  fResults.Value[aRun, 2] := gHands[2].Stats.GetHousesBuilt;
//  fResults.Value[aRun, 3] := gHands[3].Stats.GetHousesBuilt;
//  fResults.Value[aRun, 4] := gHands[4].Stats.GetHousesBuilt;
//  fResults.Value[aRun, 5] := gHands[5].Stats.GetHousesBuilt;

  gLog.AddTime('------- Run ' + IntToStr(Runs));
  HandsCnt := gHands.Count - 1;
  HRunT := 0;
  WRunT := 0;
  WFRunT := 0;
  GRunT := 0;
  for I := 1 to HandsCnt do
  begin
    Str := '';
    HRun := gHands[I].Stats.GetHousesBuilt;
    HRunT := HRunT + HRun;
    HTotal := HTotal + HRun;
    WRun := gHands[I].Stats.GetWarriorsTrained;
    WTotal := WTotal + WRun;
    WRunT := WRunT + WRun;
    WFRun := gHands[I].Stats.GetWaresProduced(wtWarfare);
    WFTotal := WFTotal + WFRun;
    WFRunT := WFRunT + WFRun;
    GRun := gHands[I].Stats.GetWaresProduced(wtAll);
    GTotal := GTotal + GRun;
    GRunT := GRunT + GRun;
    Str := Str + Format('Hand%d: H: %d  W: %d  WF: %d  G: %d', [I, HRun, WRun, WFRun, GRun]);
    gLog.AddTime(Str);
  end;
  gLog.AddTime(Format('HRunAver: %3.2f  WRunAver: %3.2f  WFRunAver: %3.2f  GRunAver: %5.2f',
               [HRunT/HandsCnt, WRunT/HandsCnt, WFRunT/HandsCnt,  GRunT/HandsCnt]));
  gLog.AddTime('Time: ' + IntToStr(GetTimeSince(StartT)));

  gGameApp.StopGame(grSilent);
end;




{ TKMVortamicPF }
procedure TKMVortamicPF.SetUp;
begin
  inherited;
  fResults.ValueCount := 1;
//  fResults.TimesCount := 5*60*10;
end;

procedure TKMVortamicPF.TearDown;
begin
  inherited;

end;

procedure TKMVortamicPF.Execute(aRun: Integer);
var
  T: Cardinal;
begin
  inherited;

  //Intended to be run multiple of 4 times to compare different PF algorithms
//  PathFinderToUse := (aRun mod 4) div 2; //01230123 > 00110011
//  CACHE_PATHFINDING := Boolean(aRun mod 2);  //0101

  gGameApp.NewSingleMap(ExtractFilePath(ParamStr(0)) + '..\..\Maps\Vortamic\Vortamic.dat', 'Across the Desert');

  SetKaMSeed(aRun div 4 + 1); //11112222

  T := TimeGet;
  SimulateGame;
  fResults.Value[aRun, 0] := TimeGet - T;

  gGameApp.StopGame(grSilent);
end;




{ TKMReplay }
procedure TKMReplay.SetUp;
begin
  inherited;
  fResults.ValueCount := 1;
//  fResults.TimesCount := 2*60*60*10;
end;

procedure TKMReplay.TearDown;
begin
  inherited;

end;

procedure TKMReplay.Execute(aRun: Integer);
var
  T: Cardinal;
begin
  inherited;

  gGameApp.NewReplay(ExtractFilePath(ParamStr(0)) + '\runner_replay.bas');

  //Don't set random seed or the replay won't work

  T := TimeGet;
  SimulateGame;
  fResults.Value[aRun, 0] := TimeGet - T;

  gGameApp.StopGame(grSilent);
end;




{ TKMVas01 }
procedure TKMVas01.SetUp;
begin
  inherited;
  fResults.ValueCount := 1;
//  fResults.TimesCount := 2*60*10;
end;

procedure TKMVas01.TearDown;
begin
  inherited;

end;

procedure TKMVas01.Execute(aRun: Integer);
const
  cmp: TKMCampaignId = (Byte('V'), Byte('A'), Byte('S'));
var
  C: TKMCampaign;
  T: Cardinal;
begin
  inherited;

  C := gGameApp.Campaigns.CampaignById(cmp);
  gGameApp.NewCampaignMap(C, 1);

  gMySpectator.FOWIndex := -1;
  gGameApp.Game.GamePlayInterface.Viewport.PanTo(KMPointF(162, 26), 0);
  gGameApp.Game.GamePlayInterface.Viewport.Zoom := 0.5;

  //Don't set random seed or the replay won't work

  T := TimeGet;
  SimulateGame;
  fResults.Value[aRun, 0] := TimeGet - T;

  gGameApp.StopGame(grSilent);
end;




{ TKMStabilityTest }
procedure TKMStabilityTest.SetUp;
begin
  inherited;
  // Do something before simulation
  if gLog = nil then
    gLog := TKMLog.Create(Format('%s\Utils\Runner\Runner_Log.log',[ExeDir]));

  fTime := TimeGet;
end;


procedure TKMStabilityTest.TearDown;
begin
  // Do something after simulation
  gLog.AddTime('TimeAver: ' + IntToStr(Round(GetTimeSince(fTime)/fRuns)));
  gLog.AddTime('Time: ' + IntToStr(GetTimeSince(fTime)));

  inherited;
end;


procedure TKMStabilityTest.Execute(aRun: Integer);
const
  MAPS_COUNT = 1;
var
  aIdx: Integer;
begin
  Inc(fRuns);
  for aIdx := 0 to MAPS_COUNT - 1 do
  begin
	  gGameApp.NewSingleMap(ExtractFilePath(ParamStr(0)) + '..\..\MapsMP\Cursed Ravine\Cursed Ravine.dat', 'GA');
	  // Set Runner interface (only in case that you want to watch game in real time)
	  //gMySpectator.Hand.FogOfWar.RevealEverything;
	  //gGameApp.Game.GamePlayInterface.Viewport.PanTo(KMPointF(0, 60), 0);
	  //gGameApp.Game.GamePlayInterface.Viewport.Zoom := 0.25;
	  // Set seed
	  SetKaMSeed(aRun + 1);
	  // Save game before starts (save map and seed)
	  gGameApp.Game.Save('Stability Test ' + IntToStr(aRun) + ' map number ' + IntToStr(aIdx), Now);
	  SimulateGame;
	  // Save after is simulation done
	  //gGameApp.Game.Save('Stability Test #' + IntToStr(aRun) + '; map number: ' + IntToStr(aIdx), Now);
  end;

  gGameApp.StopGame(grSilent);
end;


initialization
  RegisterRunner(TKMRunnerGA_TestParRun);
  RegisterRunner(TKMRunnerGA_HandLogistics);
  RegisterRunner(TKMRunnerGA_Manager);
  RegisterRunner(TKMRunnerGA_RoadPlanner);
  RegisterRunner(TKMRunnerGA_Farm);
  RegisterRunner(TKMRunnerGA_Quarry);
  RegisterRunner(TKMRunnerGA_Forest);
  RegisterRunner(TKMRunnerGA_CityBuilder);
  RegisterRunner(TKMRunnerGA_CityPlanner);
  RegisterRunner(TKMRunnerFindBugs);
  RegisterRunner(TKMRunnerStone);
  RegisterRunner(TKMRunnerFight95);
  RegisterRunner(TKMRunnerAIBuild);
  RegisterRunner(TKMVortamicPF);
  RegisterRunner(TKMReplay);
  RegisterRunner(TKMVas01);
  RegisterRunner(TKMStabilityTest);
end.
