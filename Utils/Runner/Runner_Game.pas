unit Runner_Game;
{$I KaM_Remake.inc}
interface
uses
  Forms, Unit_Runner, Windows, SysUtils, Classes, KromUtils, Math,
  KM_CommonClasses, KM_Defaults, KM_Points, KM_CommonUtils,
  KM_GameApp, KM_ResLocales, KM_Log, KM_HandsCollection, KM_ResTexts, KM_Resource,
  KM_Terrain, KM_Units, KM_UnitWarrior, KM_Campaigns, KM_AIFields, KM_Houses,
  GeneticAlgorithm, KM_AICityPlanner,
  KM_CityManagement, KM_CityPredictor, KM_CityBuilder, KM_CityPlanner, KM_Eye,
  KM_HandLogistics,
  ComInterface;


type
  //Typical usage:
  //SetUp, Execute(1), Execute(2) .. Execute(N), TearDown

  TKMRunnerGA_Common = class(TKMRunnerCommon)
  private
    fAlgorithm: TGAAlgorithm;
    OldPopulation, NewPopulation: TGAPopulation;
    //fFitnessCalc: TGAFitnessCalc;
    fLog, fLogPar: TKMLog;

    f_GA_SIMULATION_TIME_IN_MIN: Single; // Time of each simulation (GA doest not take simulation from game menu because it is only in minutes)
    f_GA_POPULATION_CNT: Word; // Population count
    f_GA_INDIVIDUALS_IN_TOURNAMENT: Word; // Count of individuals in tournament
    f_GA_GENE_CNT: Word; // Count of genes
    f_GA_MAPS_CNT: Word; // Count of simulated maps for each invididual
    f_GA_START_MUTATION: Single; // Initial mutation (first generation)
    f_GA_FINAL_MUTATION: Single; // Final mutation (last generation)
    f_GA_CROSSOVER_COEF: Single; // Crossover coefficient <0,1> = how many individuals will be taken from previous generation and how many will be randomly generated as a first generation

    procedure DefaultValues(); virtual;
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
    procedure InitGAParameters(); virtual;
    procedure SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False); virtual; abstract;
    procedure SimulateMap(aRun, aIdx, Seed: Integer; aSinglePLMapName: String; aSaveGame: Boolean = False); virtual;
    function Incr(var Idx: Integer): Integer;
    function CostFunction(): Single; virtual;
    procedure Execute(aRun: Integer); override;
  public
    SimSetup: TRunnerSetup;
    IOData: TGASetup;
  end;

  TKMRunnerGA_TestManager = class(TKMRunnerGA_Common)
  protected
    procedure Execute(aRun: Integer); override;
  end;

  TKMRunnerGA_HandLogistics = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
    procedure SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False); override;
  end;

  TKMRunnerGA_CityBuilder = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
    procedure SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False); override;
  end;

  TKMRunnerGA_CityRoadPlanner = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
    procedure SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False); override;
  end;

  TKMRunnerGA_Forest = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
    procedure SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False); override;
  end;

  TKMRunnerGA_Farm = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
    procedure SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False); override;
  end;

  TKMRunnerGA_CityPlanner = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
    procedure SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False); override;
    //function CostFunction(): Single; override;
  end;

  TKMRunnerGA_CityPredictor = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
    procedure SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False); override;
    //function CostFunction(): Single; override;
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
procedure TKMRunnerGA_Common.SetUp;
var
  I,K: Integer;
  Pop: TGAPopulation;
begin
  inherited;
  fResults.ValueCount := 1;
  // Do something before simulation
  InitGAParameters();
  fResults.TimesCount := Ceil(10*60 * f_GA_SIMULATION_TIME_IN_MIN);
  OldPopulation := nil;
  NewPopulation := TGAPopulation.Create(f_GA_POPULATION_CNT, f_GA_GENE_CNT, True);
  fAlgorithm := TGAAlgorithm.Create;
  //fFitnessCalc := TGAFitnessCalc.Create;
  DefaultValues();
  if not PARALLEL_RUN then
  begin
    fLog := TKMLog.Create(ExeDir + '\Utils\Runner\LOG_GA.log');
    fLogPar := TKMLog.Create(ExeDir + '\Utils\Runner\LOG_GA_PAR.log');
  end
  else
  begin

    fResults.TimesCount := Ceil(10*60 * SimSetup.SimTimeInMin);
    Pop := IOData.Population;
    f_GA_MAPS_CNT := IOData.MapCnt;
    f_GA_POPULATION_CNT := Pop.Count;
    f_GA_GENE_CNT := Pop.Individual[0].Count;
    if (Pop <> nil) then
    begin
      NewPopulation.Free;
      NewPopulation := TGAPopulation.Create(Pop.Count, Pop.Individual[0].Count, True);
      for I := 0 to NewPopulation.Count - 1 do
        for K := 0 to NewPopulation.Individual[I].Count - 1 do
          NewPopulation.Individual[I].Gene[K] := Pop.Individual[I].Gene[K];
    end;

  end;
end;


procedure TKMRunnerGA_Common.TearDown;
var
  I: Integer;
begin
  if PARALLEL_RUN then
  begin
    for I := 0 to OldPopulation.Count - 1 do
      IOData.Population.Individual[I].Fitness := OldPopulation.Individual[I].Fitness;
  end
  else
  begin
    fLog.Free;
    fLogPar.Free;
  end;
  // Do something after simulation
  OldPopulation.Free;
  NewPopulation.Free;
  fAlgorithm.Free;
  //fFitnessCalc.Free;
  inherited;
end;


procedure TKMRunnerGA_Common.DefaultValues();
var
  I,K: Integer;
  Idv: TGAIndividual;
begin
  for I := 0 to NewPopulation.Count - 1 do
  begin
    Idv := NewPopulation[I];
    for K := 0 to Idv.Count - 1 do
      Idv.Gene[K] := Random;
  end;
end;


procedure TKMRunnerGA_Common.InitGAParameters();
begin
  f_GA_SIMULATION_TIME_IN_MIN    := 60;
  f_GA_POPULATION_CNT            := 40;
  f_GA_INDIVIDUALS_IN_TOURNAMENT := 3;
  f_GA_GENE_CNT                  := 5;
  f_GA_MAPS_CNT                  := 10;
  f_GA_START_MUTATION            := 0.1;
  f_GA_FINAL_MUTATION            := 0.05;
  f_GA_CROSSOVER_COEF            := 0.95;
end;


procedure TKMRunnerGA_Common.SimulateMap(aRun, aIdx, Seed: Integer; aSinglePLMapName: String; aSaveGame: Boolean = False);
begin
  gGameApp.NewSingleMap(ExtractFilePath(ParamStr(0)) + '..\..\Maps\' + aSinglePLMapName + '\' + aSinglePLMapName + '.dat', 'GA');

  gMySpectator.Hand.FogOfWar.RevealEverything;
  gGameApp.Game.GamePlayInterface.Viewport.PanTo(KMPointF(0, 60), 0);
  gGameApp.Game.GamePlayInterface.Viewport.Zoom := 0.25;
  //SetKaMSeed(Max(1,Seed));
  try
    SimulateGame;
  except
    SimulateMap(aRun + 1, aIdx, Round(Random()*10000)+1, aSinglePLMapName);
  end;
  if aSaveGame then
    gGameApp.Game.Save('GA Test #' + IntToStr(aRun) + 'n' + IntToStr(aIdx), Now);
end;


// Small helping function
function TKMRunnerGA_Common.Incr(var Idx: Integer): Integer;
begin
  Result := Idx;
  Inc(Idx);
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
  I, MapNum, Idx: Integer;
  Score, BestScore, MUTATION: Single;
  Idv: TGAIndividual;
begin
  // Run 1 generation of GA
  MUTATION := aRun / (fResults.ChartsCount * 1.0);
  MUTATION := Abs(f_GA_FINAL_MUTATION + (f_GA_START_MUTATION - f_GA_FINAL_MUTATION) * (1 - MUTATION));
  fAlgorithm.Mutation := MUTATION;
  fAlgorithm.CrossoverCoef := f_GA_CROSSOVER_COEF;
  fAlgorithm.IndividualsInTournament := f_GA_INDIVIDUALS_IN_TOURNAMENT; // This may be also changed during simulation

  // Evolve population in next run (used because of parallel run)
  if (OldPopulation <> nil) then
  begin
    fAlgorithm.EvolvePopulation(OldPopulation, NewPopulation);
    OldPopulation.Free;
  end;

  OldPopulation := NewPopulation;
  for MapNum := 1 to f_GA_MAPS_CNT do
  begin
    for I := 0 to f_GA_POPULATION_CNT - 1 do
    begin
      SetParameters(OldPopulation[I], False);
      SimulateMap(aRun, I, aRun, 'GA_S1_' + IntToStr(MapNum));// Name of maps is GA_1, GA_2 ...
      Score := CostFunction();
      OldPopulation[I].Fitness := OldPopulation[I].Fitness + Score;
    end;
  end;
  NewPopulation := TGAPopulation.Create(f_GA_POPULATION_CNT, f_GA_GENE_CNT, False);

  // Save best score + parameters of best individual
  Idx := 0;
  Idv := OldPopulation.GetFittest(Idx);
  fResults.Value[aRun, 0] := Round(Idv.Fitness);
  if not PARALLEL_RUN then
    fLog.AddTime('GA: ' + IntToStr(aRun) + '. run. Best score: ' + FloatToStr(Idv.Fitness) + '. Index of the best individual: ' + IntToStr(Idx));

  // Check history and find the most fitness individual
  BestScore := MIN_SCORE;
  for I := 0 to aRun - 1 do
    if (fResults.Value[I, 0] > BestScore) then
      BestScore := fResults.Value[I, 0];
  // If is the individual from the latest generation the best then log parameters
  if (BestScore < Idv.Fitness) then
    SetParameters(Idv, not PARALLEL_RUN);

  // Stop simulation
  gGameApp.StopGame(grSilent);
end;



{ TKMRunnerGA_TestManager }
procedure TKMRunnerGA_TestManager.Execute(aRun: Integer);
var
  I,K: Integer;
  Fitness: Single;
begin
  OldPopulation := NewPopulation;
  for I := 0 to NewPopulation.Count - 1 do
  begin
    Fitness := 0;
    for K := 0 to NewPopulation.Individual[I].Count - 1 do
      Fitness := Fitness + NewPopulation.Individual[I].Gene[K];
    NewPopulation.Individual[I].Fitness := Fitness;
  end;
  NewPopulation := nil;

  //Sleep(1000); // Debug sleep

  // Stop simulation
  gGameApp.StopGame(grSilent);
end;




{ TKMRunnerGA_HandLogistics }
procedure TKMRunnerGA_HandLogistics.InitGAParameters();
begin
  f_GA_SIMULATION_TIME_IN_MIN    := 65;
  f_GA_POPULATION_CNT            := 40;
  f_GA_INDIVIDUALS_IN_TOURNAMENT := 3;
  f_GA_GENE_CNT                  := 4;
  f_GA_MAPS_CNT                  := 20;
  f_GA_START_MUTATION            := 0.2;
  f_GA_FINAL_MUTATION            := 0.01;
  f_GA_CROSSOVER_COEF            := 1;
end;

procedure TKMRunnerGA_HandLogistics.SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False);
var
  I: Integer;
begin
  I := 0;

  //GA_TCBB_BasicInit   := Max(1, Round(aIdv.Gene[Incr(I)] * 20));
  //GA_TCBB_BasicRnd    := Max(1, Round(aIdv.Gene[Incr(I)] * 60)+40);
  //GA_TCBB_NormRnd     := Max(1, Round(aIdv.Gene[Incr(I)] * 32));
  //GA_TCBB_Rnd         := Max(1, Round(aIdv.Gene[Incr(I)] * 50));
  //GA_TCBB_BasicPwr    := Max(1, Round(GA_TCBB_BasicRnd / 5)); // GA has discovered that this is best strategy
  //GA_TCBB_NormPwr     := Max(1, Round(GA_TCBB_NormRnd / 5));
  //
  //if aLogIt then
  //begin
  //  fLogPar.AddTime('GA_TCBB_BasicInit   : Integer = ' + IntToStr( GA_TCBB_BasicInit ) + ';');
  //  fLogPar.AddTime('GA_TCBB_BasicRnd    : Integer = ' + IntToStr( GA_TCBB_BasicRnd  ) + ';');
  //  fLogPar.AddTime('GA_TCBB_BasicPwr    : Integer = ' + IntToStr( GA_TCBB_BasicPwr  ) + ';');
  //  fLogPar.AddTime('GA_TCBB_NormRnd     : Integer = ' + IntToStr( GA_TCBB_NormRnd   ) + ';');
  //  fLogPar.AddTime('GA_TCBB_NormPwr     : Integer = ' + IntToStr( GA_TCBB_NormPwr   ) + ';');
  //  fLogPar.AddTime('GA_TCBB_Rnd         : Integer = ' + IntToStr( GA_TCBB_Rnd       ) + ';');
  //end;
end;


{ TKMRunnerGA_CityBuilder }
procedure TKMRunnerGA_CityBuilder.InitGAParameters();
begin
  f_GA_SIMULATION_TIME_IN_MIN    := 65;
  f_GA_POPULATION_CNT            := 40;
  f_GA_INDIVIDUALS_IN_TOURNAMENT := 3;
  f_GA_GENE_CNT                  := 13;
  f_GA_MAPS_CNT                  := 20;
  f_GA_START_MUTATION            := 0.2;
  f_GA_FINAL_MUTATION            := 0.01;
  f_GA_CROSSOVER_COEF            := 1;
end;

procedure TKMRunnerGA_CityBuilder.SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False);
var
  I: Integer;
begin
  I := 0;

  GA_BUILDER_BuildHouse_RoadMaxWork     := Max(1, aIdv.Gene[Incr(I)] * 15);
  GA_BUILDER_BuildHouse_FieldMaxWork    := Max(1, aIdv.Gene[Incr(I)] * 10);
  GA_BUILDER_BuildHouse_RTPMaxWork      := Max(1, aIdv.Gene[Incr(I)] * 20);
  GA_BUILDER_CreateShortcuts_MaxWork    := Max(1, aIdv.Gene[Incr(I)] * 15);
  GA_BUILDER_ChHTB_FractionCoef         := Max(1, aIdv.Gene[Incr(I)] * 80);
  GA_BUILDER_ChHTB_TrunkFactor          := Max(1, aIdv.Gene[Incr(I)] * 10);
  GA_BUILDER_ChHTB_TrunkBalance         := Max(1, aIdv.Gene[Incr(I)] * 15);
  GA_BUILDER_ChHTB_AllWorkerCoef        := Max(1, aIdv.Gene[Incr(I)] * 15);
  GA_BUILDER_ChHTB_FreeWorkerCoef       := Max(1, aIdv.Gene[Incr(I)] * 15);
  GA_BUILDER_TRUNK_SHORTAGE             := Max(1, aIdv.Gene[Incr(I)] * 20);
  GA_BUILDER_STONE_SHORTAGE             := Max(1, aIdv.Gene[Incr(I)] * 20);
  GA_BUILDER_WOOD_SHORTAGE              := Max(1, aIdv.Gene[Incr(I)] * 20);
  GA_BUILDER_GOLD_SHORTAGE              := Max(1, aIdv.Gene[Incr(I)] * 40);

  if aLogIt then
  begin
    fLogPar.AddTime('GA_BUILDER_BuildHouse_RoadMaxWork     : Single = ' + FloatToStr( GA_BUILDER_BuildHouse_RoadMaxWork    ) + ';');
    fLogPar.AddTime('GA_BUILDER_BuildHouse_FieldMaxWork    : Single = ' + FloatToStr( GA_BUILDER_BuildHouse_FieldMaxWork   ) + ';');
    fLogPar.AddTime('GA_BUILDER_BuildHouse_RTPMaxWork      : Single = ' + FloatToStr( GA_BUILDER_BuildHouse_RTPMaxWork     ) + ';');
    fLogPar.AddTime('GA_BUILDER_CreateShortcuts_MaxWork    : Single = ' + FloatToStr( GA_BUILDER_CreateShortcuts_MaxWork   ) + ';');
    fLogPar.AddTime('GA_BUILDER_ChHTB_FractionCoef         : Single = ' + FloatToStr( GA_BUILDER_ChHTB_FractionCoef        ) + ';');
    fLogPar.AddTime('GA_BUILDER_ChHTB_TrunkFactor          : Single = ' + FloatToStr( GA_BUILDER_ChHTB_TrunkFactor         ) + ';');
    fLogPar.AddTime('GA_BUILDER_ChHTB_TrunkBalance         : Single = ' + FloatToStr( GA_BUILDER_ChHTB_TrunkBalance        ) + ';');
    fLogPar.AddTime('GA_BUILDER_ChHTB_AllWorkerCoef        : Single = ' + FloatToStr( GA_BUILDER_ChHTB_AllWorkerCoef       ) + ';');
    fLogPar.AddTime('GA_BUILDER_ChHTB_FreeWorkerCoef       : Single = ' + FloatToStr( GA_BUILDER_ChHTB_FreeWorkerCoef      ) + ';');
    fLogPar.AddTime('GA_BUILDER_TRUNK_SHORTAGE             : Single = ' + FloatToStr( GA_BUILDER_TRUNK_SHORTAGE            ) + ';');
    fLogPar.AddTime('GA_BUILDER_STONE_SHORTAGE             : Single = ' + FloatToStr( GA_BUILDER_STONE_SHORTAGE            ) + ';');
    fLogPar.AddTime('GA_BUILDER_WOOD_SHORTAGE              : Single = ' + FloatToStr( GA_BUILDER_WOOD_SHORTAGE             ) + ';');
    fLogPar.AddTime('GA_BUILDER_GOLD_SHORTAGE              : Single = ' + FloatToStr( GA_BUILDER_GOLD_SHORTAGE             ) + ';');
  end;
end;




{ TKMRunnerGA_Forest }
procedure TKMRunnerGA_Forest.InitGAParameters();
begin
  f_GA_SIMULATION_TIME_IN_MIN    := 60;
  f_GA_POPULATION_CNT            := 40;
  f_GA_INDIVIDUALS_IN_TOURNAMENT := 3;
  f_GA_GENE_CNT                  := 10;
  f_GA_MAPS_CNT                  := 20;
  f_GA_START_MUTATION            := 0.2;
  f_GA_FINAL_MUTATION            := 0.05;
  f_GA_CROSSOVER_COEF            := 1;
end;


procedure TKMRunnerGA_Forest.SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False);
var
  I: Integer;
begin
  I := 0;
  // Please do NOT break this order and style use alt + shift + click if you want select / edit multiple colums at once!!!

  GA_EYE_GetForests_SPRndOwnLimMin                  := Max(1, aIdv.Gene[Incr(I)] * 250);
  GA_EYE_GetForests_SPRndOwnLimMax                  := Max(1, aIdv.Gene[Incr(I)] * 250);
//  GA_EYE_GetForests_InflLimit                       := Max(1, aIdv.Gene[Incr(I)] * 50 + 200);
  //GA_EYE_GetForests_MinTrees                        := Max(1, aIdv.Gene[Incr(I)] * 5);
  //GA_EYE_GetForests_Radius                          := Max(4, aIdv.Gene[Incr(I)] * 2 + 4);
  GA_PLANNER_FindPlaceForWoodcutter_TreeCnt         := Max(1, aIdv.Gene[Incr(I)] * 80 + 120);
//  GA_PLANNER_FindPlaceForWoodcutter_PolyRoute       := Max(1, aIdv.Gene[Incr(I)] * 50);
//  GA_PLANNER_FindPlaceForWoodcutter_EvalArea        := Max(1, aIdv.Gene[Incr(I)] * 50);
  GA_PLANNER_FindPlaceForWoodcutter_ExistForest     := Max(1, aIdv.Gene[Incr(I)] * 50 + 100);
  GA_PLANNER_FindPlaceForWoodcutter_DistCrit        := Max(1, aIdv.Gene[Incr(I)] * 50 + 100);
  GA_PLANNER_FindPlaceForWoodcutter_Radius          := Max(1, aIdv.Gene[Incr(I)] * 10);
//  GA_PLANNER_FindPlaceForWoodcutter_AddAB           := Max(1, aIdv.Gene[Incr(I)] * 200);

  if aLogIt then
  begin
    fLogPar.AddTime('GA_EYE_GetForests_SPRndOwnLimMin                : Single = ' + FloatToStr( GA_EYE_GetForests_SPRndOwnLimMin              ) + ';');
    fLogPar.AddTime('GA_EYE_GetForests_SPRndOwnLimMax                : Single = ' + FloatToStr( GA_EYE_GetForests_SPRndOwnLimMax              ) + ';');
//    fLogPar.AddTime('GA_EYE_GetForests_InflLimit                     : Single = ' + FloatToStr( GA_EYE_GetForests_InflLimit                   ) + ';');
    //fLogPar.AddTime('GA_EYE_GetForests_MinTrees                      : Single = ' + FloatToStr( GA_EYE_GetForests_MinTrees                    ) + ';');
    //fLogPar.AddTime('GA_EYE_GetForests_Radius                        : Single = ' + FloatToStr( GA_EYE_GetForests_Radius                      ) + ';');
    fLogPar.AddTime('GA_PLANNER_FindPlaceForWoodcutter_TreeCnt       : Single = ' + FloatToStr( GA_PLANNER_FindPlaceForWoodcutter_TreeCnt     ) + ';');
//    fLogPar.AddTime('GA_PLANNER_FindPlaceForWoodcutter_PolyRoute     : Single = ' + FloatToStr( GA_PLANNER_FindPlaceForWoodcutter_PolyRoute   ) + ';');
//    fLogPar.AddTime('GA_PLANNER_FindPlaceForWoodcutter_EvalArea      : Single = ' + FloatToStr( GA_PLANNER_FindPlaceForWoodcutter_EvalArea    ) + ';');
    fLogPar.AddTime('GA_PLANNER_FindPlaceForWoodcutter_ExistForest   : Single = ' + FloatToStr( GA_PLANNER_FindPlaceForWoodcutter_ExistForest ) + ';');
    fLogPar.AddTime('GA_PLANNER_FindPlaceForWoodcutter_DistCrit      : Single = ' + FloatToStr( GA_PLANNER_FindPlaceForWoodcutter_DistCrit    ) + ';');
    fLogPar.AddTime('GA_PLANNER_FindPlaceForWoodcutter_Radius        : Single = ' + FloatToStr( GA_PLANNER_FindPlaceForWoodcutter_Radius      ) + ';');
//    fLogPar.AddTime('GA_PLANNER_FindPlaceForWoodcutter_AddAB         : Single = ' + FloatToStr( GA_PLANNER_FindPlaceForWoodcutter_AddAB       ) + ';');
  end;
end;


{ TKMRunnerGA_CityRoadPlanner }
procedure TKMRunnerGA_CityRoadPlanner.InitGAParameters();
begin
  f_GA_SIMULATION_TIME_IN_MIN    := 70;
  f_GA_POPULATION_CNT            := 40;
  f_GA_INDIVIDUALS_IN_TOURNAMENT := 3;
  f_GA_GENE_CNT                  := 14;
  f_GA_MAPS_CNT                  := 9;
  f_GA_START_MUTATION            := 0.1;
  f_GA_FINAL_MUTATION            := 0.05;
  f_GA_CROSSOVER_COEF            := 0.95;
end;


procedure TKMRunnerGA_CityRoadPlanner.SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False);
var
  I: Integer;
begin
  I := 0;
  GA_PATHFINDING_BasePrice     := Round( Max(0, aIdv.Gene[Incr(I)] * 10) );
  GA_PATHFINDING_HouseOutside  := Round( Max(0, aIdv.Gene[Incr(I)] * 10) );
  GA_PATHFINDING_Field         := Round( Max(0, aIdv.Gene[Incr(I)] * 10) );
  GA_PATHFINDING_NoBuildArea   := Round( Max(0, aIdv.Gene[Incr(I)] * 10) );
  GA_PATHFINDING_Coal          := Round( Max(0, aIdv.Gene[Incr(I)] * 10) );
  GA_PATHFINDING_Forest        := Round( Max(0, aIdv.Gene[Incr(I)] * 10) );
  GA_PATHFINDING_OtherCase     := Round( Max(0, aIdv.Gene[Incr(I)] * 10) );

  GA_SHORTCUTS_BasePrice       := Round( Max(0, aIdv.Gene[Incr(I)] * 10) );
  GA_SHORTCUTS_HouseOutside    := Round( Max(0, aIdv.Gene[Incr(I)] * 10) );
  GA_SHORTCUTS_Field           := Round( Max(0, aIdv.Gene[Incr(I)] * 10) );
  GA_SHORTCUTS_NoBuildArea     := Round( Max(0, aIdv.Gene[Incr(I)] * 10) );
  GA_SHORTCUTS_Coal            := Round( Max(0, aIdv.Gene[Incr(I)] * 10) );
  GA_SHORTCUTS_Forest          := Round( Max(0, aIdv.Gene[Incr(I)] * 10) );
  GA_SHORTCUTS_OtherCase       := Round( Max(0, aIdv.Gene[Incr(I)] * 10) );

  if aLogIt then
  begin
    fLogPar.AddTime('GA_PATHFINDING_BasePrice    : Word = ' + IntToStr( GA_PATHFINDING_BasePrice    ) + ';');
    fLogPar.AddTime('GA_PATHFINDING_HouseOutside : Word = ' + IntToStr( GA_PATHFINDING_HouseOutside ) + ';');
    fLogPar.AddTime('GA_PATHFINDING_Field        : Word = ' + IntToStr( GA_PATHFINDING_Field        ) + ';');
    fLogPar.AddTime('GA_PATHFINDING_NoBuildArea  : Word = ' + IntToStr( GA_PATHFINDING_NoBuildArea  ) + ';');
    fLogPar.AddTime('GA_PATHFINDING_Coal         : Word = ' + IntToStr( GA_PATHFINDING_Coal         ) + ';');
    fLogPar.AddTime('GA_PATHFINDING_Forest       : Word = ' + IntToStr( GA_PATHFINDING_Forest       ) + ';');
    fLogPar.AddTime('GA_PATHFINDING_OtherCase    : Word = ' + IntToStr( GA_PATHFINDING_OtherCase    ) + ';');
    fLogPar.AddTime('GA_SHORTCUTS_BasePrice      : Word = ' + IntToStr( GA_SHORTCUTS_BasePrice      ) + ';');
    fLogPar.AddTime('GA_SHORTCUTS_HouseOutside   : Word = ' + IntToStr( GA_SHORTCUTS_HouseOutside   ) + ';');
    fLogPar.AddTime('GA_SHORTCUTS_Field          : Word = ' + IntToStr( GA_SHORTCUTS_Field          ) + ';');
    fLogPar.AddTime('GA_SHORTCUTS_NoBuildArea    : Word = ' + IntToStr( GA_SHORTCUTS_NoBuildArea    ) + ';');
    fLogPar.AddTime('GA_SHORTCUTS_Coal           : Word = ' + IntToStr( GA_SHORTCUTS_Coal           ) + ';');
    fLogPar.AddTime('GA_SHORTCUTS_Forest         : Word = ' + IntToStr( GA_SHORTCUTS_Forest         ) + ';');
    fLogPar.AddTime('GA_SHORTCUTS_OtherCase      : Word = ' + IntToStr( GA_SHORTCUTS_OtherCase      ) + ';');
  end;
end;


{ TKMRunnerGA_Farm }
procedure TKMRunnerGA_Farm.InitGAParameters();
begin
  f_GA_SIMULATION_TIME_IN_MIN    := 60;
  f_GA_POPULATION_CNT            := 39;
  f_GA_INDIVIDUALS_IN_TOURNAMENT := 3;
  f_GA_GENE_CNT                  := 2;
  f_GA_MAPS_CNT                  := 20;
  f_GA_START_MUTATION            := 0.2;
  f_GA_FINAL_MUTATION            := 0.01;
  f_GA_CROSSOVER_COEF            := 1;
end;


procedure TKMRunnerGA_Farm.SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False);
var
  I: Integer;
begin
  I := 0;
  //GA_PLANNER := True;
  // House build
  // Please do NOT break this order and style use alt + shift + click if you want select / edit multiple colums at once!!!
//  GA_PLANNER_FieldCrit_FarmPolyRoute                := Max(1, aIdv.Gene[Incr(I)] * 100);
//  GA_PLANNER_FieldCrit_EvalArea                     := Max(1, aIdv.Gene[Incr(I)] * 100);

  if aLogIt then
  begin
//    fLogPar.AddTime('GA_PLANNER_FieldCrit_FarmPolyRoute                  : Single = ' + FloatToStr( GA_PLANNER_FieldCrit_FarmPolyRoute                ) + ';');
//    fLogPar.AddTime('GA_PLANNER_FieldCrit_EvalArea                       : Single = ' + FloatToStr( GA_PLANNER_FieldCrit_EvalArea                     ) + ';');
  end;
end;


{ TKMRunnerGA_CityPlanner }
procedure TKMRunnerGA_CityPlanner.InitGAParameters();
begin
  f_GA_SIMULATION_TIME_IN_MIN    := 60;
  f_GA_POPULATION_CNT            := 1;//50;
  f_GA_INDIVIDUALS_IN_TOURNAMENT := 4;
  f_GA_GENE_CNT                  := 12;
  f_GA_MAPS_CNT                  := 20;//9;
  f_GA_START_MUTATION            := 0.2;
  f_GA_FINAL_MUTATION            := 0.01;
  f_GA_CROSSOVER_COEF            := 1;
end;


procedure TKMRunnerGA_CityPlanner.SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False);
var
  I: Integer;
begin
  I := 0;
  //GA_PLANNER := True;
  // House build
  // Please do NOT break this order and style use alt + shift + click if you want select / edit multiple colums at once!!!
  GA_PLANNER_ObstaclesInHousePlan_Tree              := Max(1, aIdv.Gene[Incr(I)] * 100 + 75);
  GA_PLANNER_ObstaclesInHousePlan_Road              := Max(1, aIdv.Gene[Incr(I)] * 100 + 75);
//  GA_PLANNER_FieldCrit_FarmPolyRoute                := Max(1, aIdv.Gene[Incr(I)] * 100);
//  GA_PLANNER_FieldCrit_EvalArea                     := Max(1, aIdv.Gene[Incr(I)] * 100);
  GA_PLANNER_SnapCrit_SnapToHouse                   := Max(1, aIdv.Gene[Incr(I)] * 50);
  GA_PLANNER_SnapCrit_SnapToFields                  := Max(1, aIdv.Gene[Incr(I)] * 50);
  GA_PLANNER_SnapCrit_SnapToRoads                   := Max(1, aIdv.Gene[Incr(I)] * 100 + 50);
  GA_PLANNER_SnapCrit_ClearEntrance                 := Max(1, aIdv.Gene[Incr(I)] * 50 + 50);
  //GA_PLANNER_FindPlaceForHouse_CloseWorker          := Max(1, aIdv.Gene[Incr(I)] * 100);
  GA_PLANNER_FindPlaceForHouse_SnapCrit             := Max(1, aIdv.Gene[Incr(I)] * 50);
//  GA_PLANNER_FindPlaceForHouse_DistCrit             := Max(1, aIdv.Gene[Incr(I)] * 50);
  GA_PLANNER_FindPlaceForHouse_CityCenter           := Max(1, aIdv.Gene[Incr(I)] * 75);
//  GA_PLANNER_FindPlaceForHouse_EvalArea             := Max(1, aIdv.Gene[Incr(I)] * 100 + 50);

  if aLogIt then
  begin
    fLogPar.AddTime('GA_PLANNER_ObstaclesInHousePlan_Tree                : Single = ' + FloatToStr( GA_PLANNER_ObstaclesInHousePlan_Tree              ) + ';');
    fLogPar.AddTime('GA_PLANNER_ObstaclesInHousePlan_Road                : Single = ' + FloatToStr( GA_PLANNER_ObstaclesInHousePlan_Road              ) + ';');
//    fLogPar.AddTime('GA_PLANNER_FieldCrit_FarmPolyRoute                  : Single = ' + FloatToStr( GA_PLANNER_FieldCrit_FarmPolyRoute                ) + ';');
//    fLogPar.AddTime('GA_PLANNER_FieldCrit_EvalArea                       : Single = ' + FloatToStr( GA_PLANNER_FieldCrit_EvalArea                     ) + ';');
    fLogPar.AddTime('GA_PLANNER_SnapCrit_SnapToHouse                     : Single = ' + FloatToStr( GA_PLANNER_SnapCrit_SnapToHouse                   ) + ';');
    fLogPar.AddTime('GA_PLANNER_SnapCrit_SnapToFields                    : Single = ' + FloatToStr( GA_PLANNER_SnapCrit_SnapToFields                  ) + ';');
    fLogPar.AddTime('GA_PLANNER_SnapCrit_SnapToRoads                     : Single = ' + FloatToStr( GA_PLANNER_SnapCrit_SnapToRoads                   ) + ';');
    fLogPar.AddTime('GA_PLANNER_SnapCrit_ClearEntrance                   : Single = ' + FloatToStr( GA_PLANNER_SnapCrit_ClearEntrance                 ) + ';');
    //fLogPar.AddTime('GA_PLANNER_FindPlaceForHouse_CloseWorker            : Single = ' + FloatToStr( GA_PLANNER_FindPlaceForHouse_CloseWorker          ) + ';');
    fLogPar.AddTime('GA_PLANNER_FindPlaceForHouse_SnapCrit               : Single = ' + FloatToStr( GA_PLANNER_FindPlaceForHouse_SnapCrit             ) + ';');
//    fLogPar.AddTime('GA_PLANNER_FindPlaceForHouse_DistCrit               : Single = ' + FloatToStr( GA_PLANNER_FindPlaceForHouse_DistCrit             ) + ';');
    fLogPar.AddTime('GA_PLANNER_FindPlaceForHouse_CityCenter             : Single = ' + FloatToStr( GA_PLANNER_FindPlaceForHouse_CityCenter           ) + ';');
//    fLogPar.AddTime('GA_PLANNER_FindPlaceForHouse_EvalArea               : Single = ' + FloatToStr( GA_PLANNER_FindPlaceForHouse_EvalArea             ) + ';');
  end;
end;


{ TKMRunnerGA_CityPredictor }
procedure TKMRunnerGA_CityPredictor.InitGAParameters();
begin
  f_GA_SIMULATION_TIME_IN_MIN    := 10;
  f_GA_POPULATION_CNT            := 2;
  f_GA_INDIVIDUALS_IN_TOURNAMENT := 2;
  f_GA_GENE_CNT                  := 8;
  f_GA_MAPS_CNT                  := 9;
  f_GA_START_MUTATION            := 0.2;
  f_GA_FINAL_MUTATION            := 0.01;
  f_GA_CROSSOVER_COEF            := 1;
end;


procedure TKMRunnerGA_CityPredictor.SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False);
var
  I: Integer;
begin
  I := 0;
//  GA_PREDICTOR_CityInitialization_Space        := aIdv.Gene[Incr(I)] * 1 / 500.0;
//  GA_PREDICTOR_CityInitialization_Fertility    := aIdv.Gene[Incr(I)] * 1 / 500.0;
//  GA_PREDICTOR_CityInitialization_Worker       := aIdv.Gene[Incr(I)] * 1 / 10.0;
  GA_PREDICTOR_STONE_NEED_PER_A_WORKER         := aIdv.Gene[Incr(I)] * 1;
  GA_PREDICTOR_WOOD_NEED_PER_A_WORKER          := aIdv.Gene[Incr(I)] * 1;
  GA_MANAGER_CheckUnitCount_SerfCoef           := aIdv.Gene[Incr(I)] * 1;
  GA_MANAGER_CheckUnitCount_SerfLimit          := Max(1, aIdv.Gene[Incr(I)] * 10);
  GA_BUILDER_STONE_SHORTAGE                    := Max(1, aIdv.Gene[Incr(I)] * 10);

  if aLogIt then
  begin
//    fLogPar.AddTime('GA_PREDICTOR_CityInitialization_Space          : Single = ' + FloatToStr( GA_PREDICTOR_CityInitialization_Space     ) + ';');
//    fLogPar.AddTime('GA_PREDICTOR_CityInitialization_Fertility      : Single = ' + FloatToStr( GA_PREDICTOR_CityInitialization_Fertility ) + ';');
//    fLogPar.AddTime('GA_PREDICTOR_CityInitialization_Worker         : Single = ' + FloatToStr( GA_PREDICTOR_CityInitialization_Worker    ) + ';');
    fLogPar.AddTime('GA_PREDICTOR_STONE_NEED_PER_A_WORKER           : Single = ' + FloatToStr( GA_PREDICTOR_STONE_NEED_PER_A_WORKER      ) + ';');
    fLogPar.AddTime('GA_PREDICTOR_WOOD_NEED_PER_A_WORKER            : Single = ' + FloatToStr( GA_PREDICTOR_WOOD_NEED_PER_A_WORKER       ) + ';');
    fLogPar.AddTime('GA_MANAGER_CheckUnitCount_SerfCoef             : Single = ' + FloatToStr( GA_MANAGER_CheckUnitCount_SerfCoef        ) + ';');
    fLogPar.AddTime('GA_MANAGER_CheckUnitCount_SerfLimit            : Single = ' + FloatToStr( GA_MANAGER_CheckUnitCount_SerfLimit       ) + ';');
    fLogPar.AddTime('GA_BUILDER_STONE_SHORTAGE                      : Single = ' + FloatToStr( GA_BUILDER_STONE_SHORTAGE                 ) + ';');
  end;
end;

{
function TKMRunnerGA_CityPlanner.CostFunction(): Single;
const
  MAX_BID = 1000000;
var
  HMA: THouseMappingArray;
  PlannedHouses: TPlannedHousesArray;
  Loc: TKMPoint;

  function IsCompletedRoad(aPoint: TKMPoint): Boolean; inline;
  begin
    Result := gTerrain.TileIsWalkableRoad(aPoint);
  end;
  function IsCompletedField(aPoint: TKMPoint): Boolean; inline;
  begin
    Result := gTerrain.TileIsCornField(aPoint);
  end;
  function IsCompletedWine(aPoint: TKMPoint): Boolean; inline;
  begin
    Result := gTerrain.TileIsWineField(aPoint);
  end;

  function ClosestDistance(aHT: THouseType): Single;
  const
    MAX_DIST = 1000;
  var
    I: Integer;
    Output, Bid: Single;
    HT: THouseType;
  begin
    Output := MAX_DIST;
    for HT in HOUSE_DEPENDENCE[aHT] do
      for I := 0 to PlannedHouses[HT].Count - 1 do
      begin
        Bid := KMDistanceAbs(Loc, PlannedHouses[HT].Plans[I].Loc);
        if (Bid < Output) then
          Output := Bid;
      end;
    if (Output = MAX_DIST) then
      Output := 0;
    Result := Output;
  end;

  function AllDistances(aHT: THouseType): Single;
  var
    I: Integer;
    HT: THouseType;
  begin
    Result := 0;
    for HT in HOUSE_DEPENDENCE[aHT] do
      for I := 0 to PlannedHouses[HT].Count - 1 do
        Result := Result + KMDistanceAbs(Loc, PlannedHouses[HT].Plans[I].Loc);
  end;

  function SnapCrit(aHT: THouseType): Single;
  const
    SNAP_TO_HOUSE = 5;
    SNAP_TO_ROAD = 4;
    SNAP_TO_FIELD = 2;
  var
    I,Dist: Integer;
    Point: TKMPoint;
    Output: Single;
    Dir: TDirection;
  begin
    Output := 0;
    // Snap to road / field / wine / house / edge of map / mountains
    Dist := 1;
    for Dir := Low(HMA[aHT].Surroundings[Dist]) to High(HMA[aHT].Surroundings[Dist]) do
      for I := Low(HMA[aHT].Surroundings[Dist,Dir]) to High(HMA[aHT].Surroundings[Dist,Dir]) do
      begin
        Point := KMPointAdd(Loc, HMA[aHT].Surroundings[Dist,Dir,I]);
        Output := Output
                  + Byte(not (tpBuild in gTerrain.Land[Point.Y,Point.X].Passability)) * SNAP_TO_HOUSE
                  + Byte(IsCompletedRoad(Point)) * SNAP_TO_ROAD
                  + Byte(IsCompletedField(Point) OR IsCompletedWine(Point)) * SNAP_TO_FIELD;
      end;
    Result := Output;
  end;

  function WoodcutCrit(aIdx: Integer): Single;
  const
    SCAN_RAD = 5;
    PLAN_PENALIZATION = 4;
    POTENTIAL_TREE_PRICE = 3;
    TREE_PRICE = 5;
    EDGE_RAD = 8;
    EDGE_PRICE = 2;
  var
    X,Y,minL,maxL: Integer;
    FLoc: TKMPoint;
    Output: Single;
  begin
    FLoc := PlannedHouses[htWoodcutters].Plans[aIdx].SpecPoint;
    Output := + 4*Abs(KMDistanceAbs(FLoc, PlannedHouses[htWoodcutters].Plans[aIdx].Loc)-2); // Place woocutter close to cutting point
    Output := Output - ClosestDistance(htStore); // We want wodcutter near city
    for Y := Max(1,FLoc.Y-SCAN_RAD) to Min(gTerrain.MapY,FLoc.Y+SCAN_RAD) do
    for X := Max(1,FLoc.X-SCAN_RAD) to Min(gTerrain.MapX,FLoc.X+SCAN_RAD) do
    begin
      if not (tpBuild in gTerrain.Land[Y,X].Passability) then // No plans around forest
        Output := Output - PLAN_PENALIZATION;
      if gTerrain.ObjectIsChopableTree(X, Y) then // Trees in forest
        Output := Output + TREE_PRICE;
      if gTerrain.TileGoodForTree(X, Y) then
        Output := Output + POTENTIAL_TREE_PRICE;
    end;
    minL := FLoc.Y-EDGE_RAD;
    maxL := FLoc.Y+EDGE_RAD;
    for X := Max(1,FLoc.X-EDGE_RAD) to Min(gTerrain.MapX-1,FLoc.X+EDGE_RAD) do
    begin
      if (minL < 1) OR not gRes.Tileset.TileIsRoadable( gTerrain.Land[minL,X].Terrain ) then
        Output := Output + EDGE_PRICE;
      if (maxL > gTerrain.MapY-1) OR not gRes.Tileset.TileIsRoadable( gTerrain.Land[maxL,X].Terrain ) then
        Output := Output + EDGE_PRICE;
    end;
    // Snap forest to edge
    minL := FLoc.X-EDGE_RAD;
    maxL := FLoc.X+EDGE_RAD;
    for Y := Max(1,FLoc.Y-EDGE_RAD) to Min(gTerrain.MapY-1,FLoc.Y+EDGE_RAD) do
    begin
      if (minL < 1) OR not gRes.Tileset.TileIsRoadable( gTerrain.Land[Y,minL].Terrain ) then
        Output := Output + EDGE_PRICE;
      if (maxL > gTerrain.MapX-1) OR not gRes.Tileset.TileIsRoadable( gTerrain.Land[Y,maxL].Terrain ) then
        Output := Output + EDGE_PRICE;
    end;
    Result := Output;
  end;

const
  PL = 1;
  WEAPONS_WEIGHT = 50;
  CITIZENS_LOST = 25;
var
  K: Integer;
  Output: Single;
  HT: THouseType;
begin
  Output := 0.0;
  HMA := gAIFields.Eye.HousesMapping;
  PlannedHouses := gHands.Hands[PL].AI.CityManagement.Builder.Planner.PlannedHouses;

  for HT := HOUSE_MIN to HOUSE_MAX do
    for K := 0 to PlannedHouses[HT].Count - 1 do
    begin
      Loc := PlannedHouses[HT].Plans[K].Loc;
      Output := Output + SnapCrit(HT) + AllDistances(HT);
    end;

  Output := Output
            + gHands[PL].Stats.GetWeaponsProduced * WEAPONS_WEIGHT
            - gHands[PL].Stats.GetCitizensLost * CITIZENS_LOST;
  Result := Output;
end;
//}





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
    gLog := TKMLog.Create(ExeDir + 'Utils\Runner\Runner_Log.log');

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
  RegisterRunner(TKMRunnerGA_TestManager);
  RegisterRunner(TKMRunnerGA_HandLogistics);
  RegisterRunner(TKMRunnerGA_CityRoadPlanner);
  RegisterRunner(TKMRunnerGA_Forest);
  RegisterRunner(TKMRunnerGA_Farm);
  RegisterRunner(TKMRunnerGA_CityBuilder);
  RegisterRunner(TKMRunnerGA_CityPlanner);
  RegisterRunner(TKMRunnerGA_CityPredictor);
  RegisterRunner(TKMRunnerStone);
  RegisterRunner(TKMRunnerFight95);
  RegisterRunner(TKMRunnerAIBuild);
  RegisterRunner(TKMVortamicPF);
  RegisterRunner(TKMReplay);
  RegisterRunner(TKMVas01);
  RegisterRunner(TKMStabilityTest);
end.
