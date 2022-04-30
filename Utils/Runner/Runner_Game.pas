unit Runner_Game;
{$I KaM_Remake.inc}
interface
uses
  Forms, Unit_Runner, Windows, SysUtils, Classes, KromUtils, Math,
  Generics.Collections, Generics.Defaults, System.Hash,
  KM_CommonClasses, KM_Defaults, KM_Points, KM_CommonUtils,
  KM_GameApp, KM_Log, KM_HandsCollection, KM_HouseCollection, KM_Resource,
  KM_Terrain, KM_Units, KM_Campaigns, KM_Houses,
  GeneticAlgorithm, GeneticAlgorithmParameters, KM_GameParams,
  ComInterface;


type
  //Typical usage:
  //SetUp, Execute(1), Execute(2) .. Execute(N), TearDown

  TKMRunnerGA_Common = class(TKMRunnerCommon)
  private
    fCrashDetectionMode: Boolean; // only for single thread
    fSaveGame: Boolean;
    fAlgorithm: TGAAlgorithm;
    fParametrization: TGAParameterization;
    fOldPopulation, fNewPopulation: TGAPopulation;
    //fFitnessCalc: TGAFitnessCalc;
    fLog, fLogPar: TKMLog;

    f_SIM_SimulationTimeInMin: Single; // Time of each simulation (GA doest not take simulation from game menu because it is only in minutes)
    f_SIM_NumberOfMaps: Word; // Count of simulated maps for each invididual
    f_SIM_PeaceTime: Word; // Peace time
    f_SIM_ThreadNumber: Word; // Number of thread (for saving maps)
    f_SIM_SimulationNumber: Word; // Number of thread (for saving maps)
    f_SIM_MapNamePrefix: String; // Prefix of map names
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
    procedure SimulateMap(aRun, aIdx, Seed: Integer; aSinglePLMapName: String); virtual;
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

  TKMRunnerGA_CityAllIn = class(TKMRunnerGA_Common)
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

  TKMRunnerGA_ArmyAttack = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
  end;

  TKMRunnerGA_ArmyAttackNew = class(TKMRunnerGA_Common)
  protected
    function CostFunction(): Single; override;
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

  TKMRunnerCombatAITest = class(TKMRunnerCommon)
  private
    fBestScore, fWorstScore, fAverageScore: Double;
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
    procedure Execute(aRun: Integer); override;
  end;

  TKMRunnerPushModes = class(TKMRunnerCommon)
  private
    fBestScore, fWorstScore, fAverageScore: Double;
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
    procedure Execute(aRun: Integer); override;
  end;

  TKMRunnerDesyncTest = class(TKMRunnerCommon)
  type
    TKMDesyncRunKind = (drkGame, drkReplay, drkGameCRC, drkReplayCRC, drkGameSave);
  private
    fGameModeSetEvent: TKMGameModeSetEvent;
    fRunSeed: Integer;
    fStartTime: Cardinal;
    fSaveName: string;
    fDesyncsDir: string;
    fRunKind: TKMDesyncRunKind;
    fRun: Integer;
    fMap: string;
    fSavePointTick: Cardinal;
    fRngMismatchFound: Boolean;
    fRngMismatchTick: Integer;
    fCRCDesyncFound: Boolean;
    fCRCDesyncTick: Integer;
    fTickCRC: array of Cardinal;
    procedure ReplayCrashed(aTick: Integer);
    function BeforeTickPlayed(aTick: Cardinal): Boolean;
    procedure SaveGame; overload;
    procedure SaveGame(aSaveName: string); overload;
    procedure MoveSave(aSaveName: string);
    procedure SaveGameAndMove; overload;
    procedure SaveGameAndMove(aSaveName: string); overload;
    function GetRunKindStr: string; overload;
    function GetRunKindStr(aRunKind: TKMDesyncRunKind): string; overload;
    function GetSaveName: string; overload;
    function GetSaveName(aRunKind: TKMDesyncRunKind; aTick: Integer): string; overload;
    function TickPlayed(aTick: Cardinal): Boolean;
    procedure Tick_GIPRandom;
    procedure Reset;
    function GetSaveDir(aSaveName: string): string;
    procedure Log(const aString: string);
  protected
    function DoCheckSavePoints: Boolean; virtual;
    procedure SetUp(); override;
    procedure TearDown(); override;
    procedure Execute(aRun: Integer); override;
  end;


  TKMRunnerCrashTest = class(TKMRunnerDesyncTest)
  protected
    function DoCheckSavePoints: Boolean; override;
  end;


  TKMRunnerAAIPerformance = class(TKMRunnerCommon)
  private
    fMap: string;
    fRun: Integer;
    fStartTime: Cardinal;
    procedure Reset;

    function TickPlayed(aTick: Cardinal): Boolean;
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
    procedure Execute(aRun: Integer); override;
  end;

  TKMRunnerCachePerformance = class(TKMRunnerCommon)
  type
    TKMRDeliveryBidKey = record
      FromP: TKMPoint; //House or Unit UID From where delivery path goes
      ToP: TKMPoint;   //same for To where delivery path goes
      function GetHashCode: Integer;
      function Compare(aOther: TKMRDeliveryBidKey): Integer;
    end;

    //Custom key comparator. Probably TDictionary can handle it himself, but lets try our custom comparator
    TKMRDeliveryBidKeyEqualityComparer = class(TEqualityComparer<TKMRDeliveryBidKey>)
      function Equals(const Left, Right: TKMRDeliveryBidKey): Boolean; override;
      function GetHashCode(const Value: TKMRDeliveryBidKey): Integer; override;
    end;

    //Comparer just to make some order by keys
    TKMRDeliveryBidKeyComparer = class(TComparer<TKMRDeliveryBidKey>)
      function Compare(const Left, Right: TKMRDeliveryBidKey): Integer; override;
    end;

    TKMRDeliveryBid = record
      Value: Single;
      TimeToLive: Integer; //Cached bid time to live, we have to update it from time to time
    end;

    TKMRDeliveryCache = class(TDictionary<TKMRDeliveryBidKey, TKMRDeliveryBid>)
    public
      function TryGetValue(const aKey: TKMRDeliveryBidKey; var aValue: TKMRDeliveryBid): Boolean; reintroduce;
      procedure Add(const FromP: TKMPoint; ToP: TKMPoint; const aValue: Single; const aTimeToLive: Word); reintroduce; overload;
      procedure Add(const aKey: TKMRDeliveryBidKey; const aValue: Single; const aTimeToLive: Word); reintroduce; overload;
      procedure Add(const aKey: TKMRDeliveryBidKey; const aBid: TKMRDeliveryBid); reintroduce; overload;
    end;

  private
    fCache: TKMRDeliveryCache;
    fStartTime: Cardinal;
    procedure Reset;
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
uses
  TypInfo, StrUtils, KM_CampaignTypes,
  KM_HandSpectator, KM_ResHouses, KM_Hand, KM_HandTypes, KM_UnitsCollection, KM_UnitGroup,
  KM_GameSettings,
  KM_CommonTypes, KM_MapTypes, KM_FileIO, KM_Game, KM_GameInputProcess, KM_GameTypes, KM_InterfaceGame,
  KM_UnitGroupTypes,
  KM_ResTypes;


{ TKMRunnerGA_Common }
procedure TKMRunnerGA_Common.InitGAParameters();
begin
  fSaveGame := False;
  fCrashDetectionMode := True;
  f_SIM_SimulationTimeInMin      := 40;
  f_SIM_NumberOfMaps             := 3;
  f_SIM_PeaceTime                := 70;
  f_SIM_ThreadNumber             := 1;
  f_SIM_SimulationNumber         := 1;
  f_SIM_MapNamePrefix            := 'GA_S1_%.3d';
  f_GA_POPULATION_CNT            := 4;
  f_GA_GENE_CNT                  := 5; // It will be overriden by class
  f_GA_START_TOURNAMENT_IndividualsCnt := 3;
  f_GA_FINAL_TOURNAMENT_IndividualsCnt := 4;
  f_GA_START_MUTATION_ResetGene  := 0.01;
  f_GA_FINAL_MUTATION_ResetGene  := 0.0001;
  f_GA_START_MUTATION_Gaussian   := 0.2;
  f_GA_FINAL_MUTATION_Gaussian   := 0.1;
  f_GA_START_MUTATION_Variance := 0.1;
  f_GA_FINAL_MUTATION_Variance := 0.01;
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
    {$IFDEF PARALLEL_RUNNER}
      THREAD_NUMBER := SimSetup.ThreadNumber;
    {$ENDIF}
    f_SIM_SimulationTimeInMin := SimSetup.SimTimeInMin;
    f_SIM_PeaceTime := SimSetup.PeaceTime;
    f_SIM_ThreadNumber := SimSetup.ThreadNumber;
    f_SIM_SimulationNumber := SimSetup.SimNumber;
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


procedure TKMRunnerGA_Common.SimulateMap(aRun, aIdx, Seed: Integer; aSinglePLMapName: String);
var
  pathToSave: String;
begin
  DEFAULT_PEACE_TIME := f_SIM_PeaceTime;
  pathToSave := ExtractFilePath(ExcludeTrailingPathDelimiter(ExtractFilePath(ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))))));
  gGameApp.NewSingleMap(Format('%sMaps\%s\%s.dat',[pathToSave,aSinglePLMapName,aSinglePLMapName]), 'GA');
  //gGameApp.Game.GameOptions.Peacetime := f_SIM_PeaceTime;

  //gMySpectator.Hand.FogOfWar.RevealEverything;
  //gGameApp.Game.GamePlayInterface.Viewport.PanTo(KMPointF(0, 60), 0);
  //gGameApp.Game.GamePlayInterface.Viewport.Zoom := 0.25;

  //SetKaMSeed(Max(1,Seed));
  try
    SimulateGame(0, 100);
    if fCrashDetectionMode then
      gGameApp.Game.Save(Format('GA_S%.2d_T%.2d_%s',[f_SIM_SimulationNumber, f_SIM_ThreadNumber, aSinglePLMapName]), Now);
    SimulateGame(101, -1);
    if fCrashDetectionMode then
      KMDeleteFolder(Format('%sSaves\GA_S%.2d_T%.2d_%s',[pathToSave,f_SIM_SimulationNumber, f_SIM_ThreadNumber, aSinglePLMapName]));
  except
    // We have problem
  end;
  if fSaveGame then
    gGameApp.Game.Save(Format('GA_end_S%.2d_T%.2d_%s',[f_SIM_SimulationNumber, f_SIM_ThreadNumber, aSinglePLMapName]), Now);
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
  {
    utMilitia,      utAxeFighter,   utSwordFighter,  utBowman,
    utArbaletman,   utPikeman,      utHallebardman,  utHorseScout,
    utCavalry,      utBarbarian,
    utPeasant,      utSlingshot,    utMetalBarbarian,utHorseman,
  }
  WARRIOR_PRICE: array[WARRIOR_MIN..WARRIOR_MAX] of Integer = (
    1, 3, 6, 3+4, // Militia     AxeFighter  utSwordFighter  utBowman
    5+4, 3, 5, 4, // Arbaletman  Pikeman     Hallebardman    utHorseScout
    7, 6,       // Cavalry     Barbarian
    2, 2+4, 6, 3  // Peasant     Slingshot   MetalBarbarian  utHorseman
    );
var
  K, UnitKilledCnt, UnitSurvivedCnt, UnitSurvivedEnemyCnt: Integer;
  IronArmy, WoodArmy, Militia, Output: Single;
  UT: TKMUnitType;
begin
  // Production of weapons
  with gHands[PL].Stats do
  begin
    Output := + GetHouseQty(htAny) * HOUSE_WEIGHT
              + GetWeaponsProduced * WEAPONS_WEIGHT
              - GetCitizensLost * CITIZENS_LOST;
    IronArmy := Min( GetWaresProduced(wtIronArmor),
                       GetWaresProduced(wtPike)
                     + GetWaresProduced(wtCrossbow)
                     + Min(GetWaresProduced(wtSword), GetWaresProduced(wtIronShield))
                   );
    WoodArmy := Min( GetWaresProduced(wtLeatherArmor),
                       GetWaresProduced(wtBow)
                     + GetWaresProduced(wtPike)
                     + Min(GetWaresProduced(wtWoodenShield), GetWaresProduced(wtAxe))
                   );
    Militia := Min( Max(0,WoodArmy - GetWaresProduced(wtLeatherArmor)), GetWaresProduced(wtAxe));
    Output := Output
              + IronArmy * IRON_SOLDIER
              + WoodArmy * WOOD_SOLDIER
              + Militia * MILITIA_SOLDIER;
  end;
  // Completed houses
  for K := 0 to gHands[PL].Houses.Count - 1 do
    Output := Output + Byte(gHands[PL].Houses[K].IsComplete) * COMPLETE_HOUSE;

  // Defeated soldiers
  UnitKilledCnt := 0;
  UnitSurvivedCnt := 0;
  with gHands[PL].Stats do
  begin
    for UT := WARRIOR_MIN to WARRIOR_MAX do
    begin
      UnitKilledCnt := UnitKilledCnt + GetUnitKilledQty(UT);
      UnitSurvivedCnt := UnitSurvivedCnt + GetUnitQty(UT);
      Output := Output + (GetUnitQty(UT) - GetUnitLostQty(UT)) * WARRIOR_PRICE[UT];
      Output := Output + GetUnitKilledQty(UT) * WARRIOR_PRICE[UT] * 2;
    end;
    Output := Output - Byte(UnitKilledCnt = 0) * 500;
  end;

  // Check combat maps (GA_S2_...)
  UnitSurvivedEnemyCnt := 0;
  with gHands[0].Stats do
    for UT := WARRIOR_MIN to WARRIOR_MAX do
      UnitSurvivedEnemyCnt := UnitSurvivedEnemyCnt + GetUnitQty(UT);
  // Sometimes it is third player in GA_S2_... maps
  if (gHands.Count >= 3) then
    with gHands[2].Stats do
      for UT := WARRIOR_MIN to WARRIOR_MAX do
        UnitSurvivedEnemyCnt := UnitSurvivedEnemyCnt + GetUnitQty(UT);
  if (UnitSurvivedEnemyCnt > 0) AND (UnitSurvivedCnt > 0) then // The fight is not finished
    Output := Output - (UnitSurvivedEnemyCnt + UnitSurvivedCnt) * 30;

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
  if not PARALLEL_RUN then
    f_SIM_SimulationNumber := aRun + 1;
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
      SimulateMap(aRun, K, aRun, Format(f_SIM_MapNamePrefix,[MapNum]));// Name of maps are GA_001, GA_002 so use %.3d to fill zeros
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
          Fitness := 0.1 + Fitness - abs(L / fNewPopulation.Individual[K].GenesCount - fNewPopulation.Individual[K].Gene[L]);
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


{ TKMRunnerGA_CityAllIn }
procedure TKMRunnerGA_CityAllIn.InitGAParameters();
begin
  inherited;
  f_GA_GENE_CNT := fParametrization.GetParCnt('TKMRunnerGA_CityAllIn');
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

{ TKMRunnerGA_ArmyAttack }
procedure TKMRunnerGA_ArmyAttack.InitGAParameters();
begin
  inherited;
  f_SIM_SimulationTimeInMin := 10;
  f_SIM_PeaceTime := 0;
  f_SIM_NumberOfMaps  := 20;
  f_SIM_MapNamePrefix := 'GA_S2_%.3d';
  f_GA_GENE_CNT := fParametrization.GetParCnt('TKMRunnerGA_ArmyAttack');
end;

{ TKMRunnerGA_ArmyAttackNew }
procedure TKMRunnerGA_ArmyAttackNew.InitGAParameters();
begin
  inherited;
  f_SIM_SimulationTimeInMin := 10;
  f_SIM_PeaceTime := 0;
  f_SIM_MapNamePrefix := 'GA_S2_%.3d';
  //{
  f_SIM_NumberOfMaps  := 60;
  f_GA_POPULATION_CNT := 3;
  //}
  {
  f_SIM_NumberOfMaps  := 2;
  f_GA_POPULATION_CNT := 2;
  //}
  //fSaveGame := true;
  f_GA_GENE_CNT := fParametrization.GetParCnt('TKMRunnerGA_ArmyAttackNew');
end;

function TKMRunnerGA_ArmyAttackNew.CostFunction(): Single;

const
  TEST_PL = 1;
  AI_PL = 2;
  KILL_GAIN = 3;
  LOST_GAIN = 1;
  SURVIVE_GAIN = 1;
  SURVIVE_ENEMY_GAIN = 3;
  WARRIOR_PRICE: array[WARRIOR_MIN..WARRIOR_MAX] of Single = (
    1, 2, 3, 2+2,   // Militia     AxeFighter  Swordsman       utBowman
    3+2, 2, 3, 2+1, // Arbaletman  Pikeman     Hallebardman    utHorseScout
    3+1, 3,         // Cavalry     Barbarian
    1, 1+2, 3, 1+1  // Peasant     Slingshot   MetalBarbarian  utHorseman
    );
var
  PL, K, survivedAlly, survivedEnemy: Integer;
  IronArmy, WoodArmy, Militia, Output: Single;
  UT: TKMUnitType;
begin

  Result := 100000;
  with gHands[TEST_PL].Stats do
    for UT := WARRIOR_MIN to WARRIOR_MAX do
      Result := Result
        + WARRIOR_PRICE[UT] * GetUnitKilledQty(UT) * KILL_GAIN
        - WARRIOR_PRICE[UT] * GetUnitLostQty(UT) * LOST_GAIN
        + WARRIOR_PRICE[UT] * GetUnitQty(UT) * SURVIVE_GAIN;
        //- Byte(GetUnitKilledQty(utAny)) * 500;

  with gHands[AI_PL].Stats do
    for UT := WARRIOR_MIN to WARRIOR_MAX do
      Result := Result - GetUnitQty(UT) * SURVIVE_ENEMY_GAIN;

  survivedAlly := 0;
  for UT := WARRIOR_MIN to WARRIOR_MAX do
    survivedAlly := survivedAlly + gHands[TEST_PL].Stats.GetUnitQty(UT);

  survivedEnemy := 0;
  for UT := WARRIOR_MIN to WARRIOR_MAX do
    survivedEnemy := survivedEnemy + gHands[AI_PL].Stats.GetUnitQty(UT);

  if (survivedEnemy > 0) AND (survivedAlly > 0) then
    Result := Result - (survivedEnemy + survivedAlly) * SURVIVE_ENEMY_GAIN;
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
      IronArmy := Min( GetWaresProduced(wtIronArmor),
                         GetWaresProduced(wtPike)
                       + GetWaresProduced(wtCrossbow)
                       + Min(GetWaresProduced(wtSword), GetWaresProduced(wtIronShield))
                     );
      WoodArmy := Min( GetWaresProduced(wtLeatherArmor),
                         GetWaresProduced(wtBow)
                       + GetWaresProduced(wtPike)
                       + Min(GetWaresProduced(wtWoodenShield), GetWaresProduced(wtAxe))
                     );
      Militia := Min( Max(0,WoodArmy - GetWaresProduced(wtLeatherArmor)), GetWaresProduced(wtAxe));
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
  DEFAULT_PEACE_TIME := 60;
  for K := Low(MAPS) to High(MAPS) do
  begin
    fBestScore := -1e30;
    fAverageScore := 0;
    fWorstScore := 1e30;
    MapName := MAPS[K];
    for L := 1 to cnt_MAP_SIMULATIONS do
    begin
      OnProgress2(MapName + ' Run ' + IntToStr(L));
      gGameApp.NewSingleMap(Format('%s..\..\Maps\%s\%s.dat',[ExtractFilePath(ParamStr(0)),MapName,MapName]), MapName);

      SetKaMSeed(L + 1000);

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
    fAverageScore := fAverageScore / cnt_MAP_SIMULATIONS;
    gGameApp.Game.Save(Format('AVRG_%s__%.6d',[MapName, Round(fAverageScore)]), Now);
  end;

  gGameApp.StopGame(grSilent);
end;




{ TKMRunnerCombatAITest }
procedure TKMRunnerCombatAITest.SetUp();
begin
  inherited;
  // Deactivate KaM log
  if (gLog = nil) then
    gLog := TKMLog.Create(Format('%s\Utils\Runner\Runner_Log.log',[ExeDir]));
  gLog.MessageTypes := [];
end;


procedure TKMRunnerCombatAITest.TearDown();
begin
  inherited;
end;


procedure TKMRunnerCombatAITest.Execute(aRun: Integer);
  function EvalGame(): Double;
  const
    PL = 1;
  var
    UT: TKMUnitType;
  begin
    Result := 0;
    with gHands[PL].Stats do
      for UT := WARRIOR_MIN to WARRIOR_MAX do
        Result := Result + GetUnitQty(UT);
  end;
const
  // Maps for simulation (I dont use for loop in this array)
  //MAPS: array [1..27] of String = ('GA_S1_001','GA_S1_002','GA_S1_003','GA_S1_004','GA_S1_005','GA_S1_006','GA_S1_007','GA_S1_008','GA_S1_009','GA_S1_010','GA_S1_011','GA_S1_012','GA_S1_013','GA_S1_014','GA_S1_015','GA_S1_016','GA_S1_017','GA_S1_018','GA_S1_019','GA_S1_020','GA_S1_021','GA_S1_022','GA_S1_023','GA_S1_024','GA_S1_025','GA_S1_026','GA_S1_027');
  //MAPS: array [1..12] of String = ('GA_S1_002','GA_S1_003','GA_S1_007','GA_S1_008','GA_S1_010','GA_S1_014','GA_S1_015','GA_S1_019','GA_S1_023','GA_S1_024','GA_S1_026','GA_S1_027');
  MAPS: array [1..1] of String = ('IV_1v1');
  //MAPS: array [1..1] of String = ('IV_1v1_AdvOldC');
  cnt_MAP_SIMULATIONS = 100;
  CRASH_DETECTION_MODE = True;
var
  K,L,Wins: Integer;
  Score: Double;
  MapName: String;
begin
  for K := Low(MAPS) to High(MAPS) do
  begin
    fBestScore := -1e30;
    fAverageScore := 0;
    fWorstScore := 1e30;
    Wins := 0;
    MapName := MAPS[K];
    for L := 1 to cnt_MAP_SIMULATIONS do
    begin
      OnProgress2(MapName + ' Run ' + IntToStr(L));
      gGameApp.NewSingleMap(Format('%s..\..\Maps\%s\%s.dat',[ExtractFilePath(ParamStr(0)),MapName,MapName]), MapName);

      //SetKaMSeed(L + 1000);

      if CRASH_DETECTION_MODE then
        gGameApp.Game.Save('CrashDetection', Now);

      //SetKaMSeed(Max(1,Seed));
      SimulateGame();
      Score := Max(0,EvalGame());
      Wins := Wins + Byte(Score > 0);
      fAverageScore := fAverageScore + Score;
      //gGameApp.Game.Save(Format('%s__No_%.3d__Score_%.6d',[MapName, K, Round(Score)]), Now);
      if (Score <= fWorstScore) AND (cnt_MAP_SIMULATIONS > 1) then
      begin
        fWorstScore := Score;
        gGameApp.Game.Save(Format('W__%s__No_%.3d__Score_%.6d',[MapName, L, Round(Score)]), Now);
      end;

    end;
    fAverageScore := fAverageScore / cnt_MAP_SIMULATIONS;
    gGameApp.Game.Save(Format('AVRG_%s__%.6d',[MapName, Round(Wins)]), Now);
  end;

  gGameApp.StopGame(grSilent);
end;




{ TKMRunnerPushModes }
procedure TKMRunnerPushModes.SetUp();
begin
  inherited;

  // Deactivate KaM log
  if (gLog = nil) then
    gLog := TKMLog.Create(Format('%s\Utils\Runner\Runner_Log.log',[ExeDir]));
  gLog.MessageTypes := [];
end;


procedure TKMRunnerPushModes.TearDown();
begin
  inherited;
end;


procedure TKMRunnerPushModes.Execute(aRun: Integer);
const
  // Maps for simulation (I dont use for loop in this array)
  //MAPS: array [1..27] of String = ('GA_S1_001','GA_S1_002','GA_S1_003','GA_S1_004','GA_S1_005','GA_S1_006','GA_S1_007','GA_S1_008','GA_S1_009','GA_S1_010','GA_S1_011','GA_S1_012','GA_S1_013','GA_S1_014','GA_S1_015','GA_S1_016','GA_S1_017','GA_S1_018','GA_S1_019','GA_S1_020','GA_S1_021','GA_S1_022','GA_S1_023','GA_S1_024','GA_S1_025','GA_S1_026','GA_S1_027');
  MAPS: array [1..13] of String = ('Test1','Test2','Test3','Test4','Test5','Test6','Test7','Test8','Test9','Test10','Test11','Test12',
                                   'Test13');
  MAPS_V: array [1..13] of Integer = (10, 10, 10, 20, 20, 20, 10, 10, 10, 10, 10, 10,
                                      120);
  cnt_MAP_SIMULATIONS = 100;
var
  K,L: Integer;
  Score: Double;
  MapName: String;
begin
  for K := 1 to 13 do//High(MAPS) do
  begin
    fBestScore := -1e30;
    fAverageScore := 0;
    fWorstScore := 1e30;
    MapName := MAPS[K];
    fIntParam := 0;
    fIntParam2 := 0;
    if K <= 12 then
      fIntParam := MAPS_V[K]
    else
      fIntParam2 := MAPS_V[K];
    for L := 1 to cnt_MAP_SIMULATIONS do
    begin
      gGameApp.NewSingleMap(Format('%s..\..\Maps\%s\%s.dat',[ExtractFilePath(ParamStr(0)),MapName,MapName]), MapName);

      SetKaMSeed(Max(1,L));

      SimulateGame();
      Score := gGameApp.Game.Params.Tick;//Max(0,EvalGame());
      fAverageScore := fAverageScore + Score;
      //gGameApp.Game.Save(Format('%s__No_%.3d__Score_%.6d',[MapName, K, Round(Score)]), Now);
      if (Score < fWorstScore) AND (cnt_MAP_SIMULATIONS > 1) then
      begin
        fWorstScore := Score;
//        gGameApp.Game.Save(Format('W__%s__No_%.3d__Score_%.6d',[MapName, L, Round(Score)]), Now);
      end;
      if (Score > fBestScore) AND (cnt_MAP_SIMULATIONS > 1) then
      begin
        fBestScore := Score;
//        gGameApp.Game.Save(Format('B__%s__No_%.3d__Score_%.6d',[MapName, L, Round(Score)]), Now);
      end;
      OnProgress2(MapName + ' Run ' + IntToStr(L));
    end;
    fAverageScore := fAverageScore / cnt_MAP_SIMULATIONS;
//    gGameApp.Game.Save(Format('AVRG_%s__%.6d',[MapName, Round(fAverageScore)]), Now);
    gLog.SetDefaultMessageTypes;
    gLog.AddNoTime(Format('%d;%d;%d', [{MAPS[K], }Round(fAverageScore), Round(fWorstScore), Round(fBestScore)]), False);
    gLog.MessageTypes := [];
  end;

  gGameApp.StopGame(grSilent);
end;


const
  SAVE_LAST_SYNC_TICK = False;

{ TKMRunnerDesyncTest }
procedure TKMRunnerDesyncTest.SetUp();
begin
  DO_NOT_SKIP_LOAD_TILESET := True; //gGameApp will create game in the inherited call, we need to set this earlier

  inherited;

  fDesyncsDir := Format('%s..\Desyncs\', [ExeDir]);
  ForceDirectories(fDesyncsDir);

  SetLength(fTickCRC, fResults.TimesCount);

  fOnTick := TickPlayed;
  fOnBeforeTick := BeforeTickPlayed;

  // Deactivate KaM log
  if (gLog = nil) then
    gLog := TKMLog.Create(Format('%sUtils\Runner\Runner_Log.log',[ExeDir]));
  gLog.MessageTypes := [];

  gLog.SetDefaultMessageTypes;

//  Include(gLog.MessageTypes, lmtRandomChecks);
//  Include(gLog.MessageTypes, lmtCommands);

//  LOG_GAME_TICK := True;

//  LOG_GAME_TICK := True;
  CALC_EXPECTED_TICK := False;
  CRASH_ON_REPLAY := False;
  SAVE_GAME_AS_TEXT := True;
  ALLOW_SAVE_IN_REPLAY := True;
  SAVE_GAME_AS_TEXT := True;
  GAME_NO_UPDATE_ON_TIMER := True;
  GAME_SAVE_STRIP_FOR_CRC := True;
  SKIP_SAVE_SAVPTS_TO_FILE := True;
  SAVE_RANDOM_CHECKS := False;
  GAME_SAVE_CHECKPOINT_FREQ_MIN := 10;
  GAME_SAVE_CHECKPOINT_CNT_LIMIT_MAX := 1000;

//  Include(gLog.MessageTypes, lmtRandomChecks)
end;


procedure TKMRunnerDesyncTest.TearDown();
begin

  inherited;
end;


procedure TKMRunnerDesyncTest.Reset;
begin
  FillChar(fTickCRC, SizeOf(fTickCRC), #0);

  SetLength(fTickCRC, fResults.TimesCount);
end;


procedure TKMRunnerDesyncTest.ReplayCrashed(aTick: Integer);
begin
  Assert(fRunKind = drkReplay);

  fRngMismatchFound := True;
  fRngMismatchTick := gGameParams.Tick;

  OnProgress_Left2(Format('RNG mismatch: %d', [fRngMismatchTick]));
end;


procedure TKMRunnerDesyncTest.SaveGame;
begin
  SaveGame(GetSaveName);
end;


procedure TKMRunnerDesyncTest.SaveGame(aSaveName: string);
var
  gameMode: TKMGameMode;
begin
  gameMode := gGameParams.Mode;

  fGameModeSetEvent(gmSingle);
  gGame.SaveAndWait(aSaveName); //Save game and wait for async worker to complete all of his jobs
  fGameModeSetEvent(gameMode);
end;

procedure TKMRunnerDesyncTest.MoveSave(aSaveName: string);
begin
  KMMoveFolder(GetSaveDir(aSaveName), fDesyncsDir + aSaveName);
end;


procedure TKMRunnerDesyncTest.SaveGameAndMove;
begin
  SaveGameAndMove(GetSaveName);
end;


procedure TKMRunnerDesyncTest.SaveGameAndMove(aSaveName: string);
begin
  SaveGame(aSaveName);
  MoveSave(aSaveName);
end;


function TKMRunnerDesyncTest.GetRunKindStr: string;
begin
  Result := GetRunKindStr(fRunKind);
end;


function TKMRunnerDesyncTest.GetRunKindStr(aRunKind: TKMDesyncRunKind): string;
begin
  Result := GetEnumName(TypeInfo(TKMDesyncRunKind), Integer(aRunKind));
  Result := RightStr(Result, Length(Result) - 3);
end;


function TKMRunnerDesyncTest.GetSaveName: string;
begin
  Result := GetSaveName(fRunKind, gGameParams.Tick);
end;


function TKMRunnerDesyncTest.GetSaveName(aRunKind: TKMDesyncRunKind; aTick: Integer): string;
begin
  Result := Format('%s_%s_L%d_RNG%d_CRC%d', [fSaveName, GetRunKindStr(aRunKind), fSavePointTick, fRngMismatchTick, aTick]);
end;


function TKMRunnerDesyncTest.BeforeTickPlayed(aTick: Cardinal): Boolean;
begin
  Result := (fRunKind <> drkReplay) or not fRngMismatchFound;

  if SAVE_LAST_SYNC_TICK and (fRunKind = drkReplayCRC) then
    SaveGame; // Make replay save
end;


function TKMRunnerDesyncTest.TickPlayed(aTick: Cardinal): Boolean;

  procedure SetSymmetricalAlliance(aPL1, aPL2: TKMHandID; aAllianceType: TKMAllianceType);
  begin
    gGame.GameInputProcess.CmdPlayerAllianceSet(aPL1, aPL2, aAllianceType);
    gGame.GameInputProcess.CmdPlayerAllianceSet(aPL2, aPL1, aAllianceType);
  end;

var
  tickCRC, T: Cardinal;
  I, J, K, PL1, PL2, teamsCnt, teamMembersCnt, lastTeamCnt, cnt, rngIndex, membersCnt: Integer;
  allianceType: TKMAllianceType;
  playersTeam: array[0..MAX_HANDS - 1] of Byte;
  playerID: Byte;
  players: set of Byte;
begin
  Result := True;

  if gGameParams.Tick = 1 then
  begin
    gGame.GameInputProcess.CmdPlayerChanged(0, 'AI 1', hndComputer, AIType);

//    if gHands[0].CanBeHuman then
//      gHands[0].AI.Setup.ApplyMultiplayerSetup(AIType = aitAdvanced)
//    else
//      //Just enable Advanced AI, do not override MapEd AI params
//      gHands[0].AI.Setup.EnableAdvancedAI(AIType = aitAdvanced);

    case TeamType of
      rttFFA: ;
      rttRngAlliances:  for PL1 := 0 to gHands.Count - 1 do
                        begin
                          PL2 := KaMRandomWSeed(fRunSeed, gHands.Count - 1);
                          if PL2 <> PL1 then
                          begin
                            allianceType := TKMAllianceType(KaMRandomWSeed(fRunSeed, 2));
                            SetSymmetricalAlliance(PL1, PL2, allianceType);
                          end;
                        end;
      rttRngTeams:      begin
                          cnt := gHands.Count;
                          players := [];
                          FillChar(playersTeam, Length(playersTeam) * SizeOf(playersTeam[0]), #255);
                          for I := 0 to gHands.Count - 1 do
                            Include(players, I);

                          teamsCnt := KaMRandomWSeed(fRunSeed, Max(0, Min(gHands.Count div 2, 6) - 2)) + 2; //2..6 teams
                          teamMembersCnt := Round(gHands.Count / teamsCnt);
                          lastTeamCnt := gHands.Count - teamMembersCnt * (teamsCnt - 1);

                          for I := 0 to teamsCnt - 1 do //except last team
                          begin
                            membersCnt := IfThen(I = teamsCnt - 1, lastTeamCnt, teamMembersCnt);
                            for J := 0 to membersCnt - 1 do
                            begin    
                              rngIndex := KaMRandomWSeed(fRunSeed, cnt);
                              K := 0;
                              for playerID in players do
                              begin
                                if K = rngIndex then
                                begin  
                                  playersTeam[playerID] := I;
                                  Exclude(players, playerID);
                                  Break;
                                end;
                                Inc(K);
                              end;

                              Dec(cnt); 
                            end;
                          end;

                          for PL1 := 0 to gHands.Count - 1 do
                            for PL2 := 0 to gHands.Count - 1 do
                            begin
                              if PL1 = PL2 then Continue;

                              if playersTeam[PL1] = playersTeam[PL2] then
                                gGame.GameInputProcess.CmdPlayerAllianceSet(PL1, PL2, atAlly)
                              else
                                gGame.GameInputProcess.CmdPlayerAllianceSet(PL1, PL2, atEnemy);
                            end;

                          //Add default goals for all players after alliances were set
                          for PL1 := 0 to gHands.Count - 1 do
                            gGame.GameInputProcess.CmdPlayerAddDefaultGoals(PL1, MapsType <> rmtFight);
                        end;
    end;

//    SaveGame; //Skip initial game save
  end;

  case fRunKind of
    drkGame:      begin
//                    Tick_GIPRandom;
                  end;
    drkReplay:    ;
    drkGameCRC:   begin
                    if gGameParams.Tick >= fSavePointTick then
                    begin
                      tickCRC := gGame.GetCurrectTickSaveCRC;
                      fTickCRC[gGameParams.Tick - fSavePointTick] := tickCRC;

                      //SaveGame();
                    end;
                  end;
    drkReplayCRC: begin
                    tickCRC := gGame.GetCurrectTickSaveCRC;
                    if tickCRC <> fTickCRC[gGameParams.Tick - fSavePointTick] then
                    begin
                      SaveGameAndMove;
//                      MoveSave(GetSaveName(drkGameCRC, gGameParams.Tick));

                      //Move last sync saves
                      if SAVE_LAST_SYNC_TICK then
                      begin
                        MoveSave(GetSaveName(drkReplayCRC, gGameParams.Tick - 1));
                        MoveSave(GetSaveName(drkGameCRC, gGameParams.Tick - 1));
                      end;

                      fCRCDesyncFound := True;
                      fCRCDesyncTick := gGameParams.Tick;

                      OnProgress_Left3(Format('CRC desync: %d', [fCRCDesyncTick]));

                      Result := False; //Stop simulation
                    end;
                  end;
    drkGameSave:  begin
                    if gGameParams.Tick = fCRCDesyncTick then
                      SaveGameAndMove
                    else
                    if gGameParams.Tick = fRngMismatchTick then
                      SaveGameAndMove;
                  end;
  end;

  T := TimeSince(fStartTime);
  OnProgress2(Format('%s: %s R%d T%d', [GetRunKindStr, LeftStr(fMap, Min(Length(fMap), 17)), fRun, aTick]));
  OnProgress5(Format('Time elapsed: %.2d:%.2d:%.2d', [T div (60*60*1000), (T div (60*1000)) mod 60, (T div 1000) mod 60]));
end;


procedure TKMRunnerDesyncTest.Log(const aString: string);
begin
  gLog.AddNoTime('[DESYNC] ' + aString);
end;


function TKMRunnerDesyncTest.DoCheckSavePoints: Boolean;
begin
  Result := True;
end;


procedure TKMRunnerDesyncTest.Execute(aRun: Integer);
const
  // Maps for simulation (I dont use for loop in this array)
  MAPS: array [1..17] of String = ('Across the Desert','Mountainous Region','Battle Sun','Neighborhood Clash','Valley of the Equilibrium','Wilderness',
                                   'Border Rivers','Blood and Ice','A Midwinter''s Day','Coastal Expedition','Defending the Homeland','Eruption',
                                   'Forgotten Lands','Golden Cliffs','Rebound','Riverlands', 'Shadow Realm');
  MAPS_8P: array [1..29] of String = ('A War of Justice','Babylon','Back in the Desert','Center Castle Looting','Cold Water 8P',
                                   'Complication in Simplicity','Crystalline Falls','Cursed Ravine','Dance of Death','Dead of Winter',
                                   'Drastic Measures','Ending the Tyranny','Twin Peaks','Valley of the Equilibrium 8P', 'Frozen Waters',
                                   'Hand in Hand','Mega Land','Nibenay Basin','Paradise Island','Reborn','Rich Land','Tale of Two Lands',
                                   'The Final Frontier','The Last Port','The Same Rocks','The Valley of Dangers 2','Volcanic Violence',
                                   'Volcano Valley','Voros Arany');
  //Fighting maps
  FIGHT_MAPS: array[1..33] of string = ('Icewind Valley 6P', 'Red Valley', 'Clarity Falls - Escape', 'Enter the Heat', 'Pirate Bond',
                                  'Sharks Islands', 'Dangerous Shore', 'Ambushed', 'Bannockburn','Battle of Great Generals',
                                  'Gorges', 'Spring of Events', 'Inner Struggle', 'Last Fight for Oasis','Lost Road',
                                  'River Crossing','Shoulder to Shoulder','The Pirates','Unknown Danger','Battle in the Ruined City',
                                  'Lost City Struggle','Cross','Cursed Land','Gunplay','Icewind Valley','Rocky Mountains',
                                  'Shallows of Death','Snow Cross','The Citadel','The King Says','Tundra','Atoll','Coastal Encounter');

  COOP_MAPS: array[1..45] of string = ('A Clash of Kings', 'A Farmers Wish Coop', 'A Southern Journey', 'A Way East', 'Bridgecal Dundee',
                                  'Coalical Dundee', 'Dead Border','Hillycal Dundee','Lakeland','No Escape','Northern Islands I',
                                  'Return to Moorbach','Siege of Castle Fennford','The Cracker','The Dig','TPR 03','TPR 04','TPR 05',
                                  'TPR 06','TPR 07','TPR 08','TPR 09','TPR 10','TPR 11','TPR 12','TPR 13','TPR 14','Tropical Dundee',
                                  'TSK 03','TSK 06','TSK 07','TSK 08','TSK 09','TSK 10','TSK 11','TSK 12','TSK 13','TSK 14','TSK 15','TSK 16',
                                  'TSK 17','TSK 18','TSK 19','TSK 20','Waterfall Dundee');

  cnt_MAP_SIMULATIONS = 10;

  SIMUL_TIME_MAX: Integer = 10*60*180; //1 hour
  SAVEPT_FREQ: Integer = 10*60*1; //every 1 min
  REPLAY_LENGTH: Integer = 1500; // ticks to find RNG mismatch
//  SAVEPT_CNT = 1; //(SIMUL_TIME_MAX div SAVEPT_FREQ) - 1;
//  SAVEPT_CNT = (SIMUL_TIME_MAX div SAVEPT_FREQ) - 1;
  LOAD_SAVEPT_AT_TICK = 0;
  SKIP_FIRST_SAVEPT_CNT = 15; //Skip first savepoints to save some time

var
  K,L,I,M: Integer;
  desyncCnt, mapsCnt, savesFreq, savesCnt, replayLength: Integer;
  simulLastTick, totalRuns, totalLoads: Integer;

  procedure StartGame;
  var
    mapFullName: string;
  begin
    fRunSeed := L;

    mapFullName := Format('%sMapsMP\%s\%s.dat',[ExeDir,fMap,fMap]);
    gGameApp.NewSingleMap(mapFullName, fMap, -1, 0, mdNone, AIType);
    gGame.Params.GetGameModeSetEvent(fGameModeSetEvent);
  end;

begin
  PAUSE_GAME_BEFORE_TICK := -1;    //Pause at specified game tick
//  MAKE_SAVEPT_BEFORE_TICK := 40800;

  M := 0;
  desyncCnt := 0;
  totalRuns := 0;
  totalLoads := 0;
  fStartTime := TimeGet;

  mapsCnt := 0;

  case MapsType of
    rmtClassic: mapsCnt := Length(MAPS);
    rmtMP8:     mapsCnt := Length(MAPS_8P);
    rmtFight:   mapsCnt := Length(FIGHT_MAPS);
    rmtCoop:    mapsCnt := Length(COOP_MAPS);
  end;

  // Make more frequent saves and smaller replay length
  savesFreq := SAVEPT_FREQ div (1 + (Byte(MapsType = rmtFight)));
  savesCnt := (SIMUL_TIME_MAX div savesFreq);
  replayLength := REPLAY_LENGTH div (1 + 2*(Byte(MapsType = rmtFight)));

//  for K := Low(MAPS) to High(MAPS) do
//  for K := 5 to High(MAPS) do
  while M < mapsCnt do
  begin
    K := Random(mapsCnt) + 1;
//    fMap := COOP_MAPS[K];
    case MapsType of
      rmtClassic: fMap := MAPS[K];
      rmtMP8:     fMap := MAPS_8P[K];
      rmtFight:   fMap := FIGHT_MAPS[K];
      rmtCoop:    fMap := COOP_MAPS[K];
    end;

    Inc(M);

    for L := 1 to cnt_MAP_SIMULATIONS do
//    L := 1;
    begin
      Reset;
      Inc(totalRuns);
      fRun := L;
      CUSTOM_SEED_VALUE := L + M*cnt_MAP_SIMULATIONS + Seed;

      OnProgress3('Seed: ' + IntToStr(CUSTOM_SEED_VALUE));

      OnProgress_Left('');
      OnProgress_Left2('');
      OnProgress_Left3('');

      fSaveName := Format('%s_SD_%d_RN%.2d',[fMap, CUSTOM_SEED_VALUE, L]);

      fRunKind := drkGame;

      StartGame;

      gGameSettings.DebugSaveGameAsText := True;

      gGameSettings.SaveCheckpoints := DoCheckSavePoints;
      gGameSettings.SaveCheckpointsFreq := savesFreq;
      gGameSettings.SaveCheckpointsLimit := savesCnt;

//      LOG_GAME_TICK := True;
//      Include(gLog.MessageTypes, lmtCommands);

      SimulateGame(0, SIMUL_TIME_MAX);

      if not DoCheckSavePoints then
      begin
        if Assigned(fOnStop) and fOnStop then
          Exit;
        Continue;
      end;

//      SaveGame; //Skip game save at the end of the game

//      LOG_GAME_TICK := False;
//      Exclude(gLog.MessageTypes, lmtCommands);

      simulLastTick := min(SIMUL_TIME_MAX, fResults.TimesCount - 1);

      fRngMismatchFound := False;
      fRngMismatchTick := -1;

      fGameModeSetEvent(gmReplaySingle);

      for I := 0 to savesCnt - 1 do
      begin
        if LOAD_SAVEPT_AT_TICK <> 0 then
          fSavePointTick := LOAD_SAVEPT_AT_TICK
        else
          fSavePointTick := (I + Byte(MapsType <> rmtFight)*SKIP_FIRST_SAVEPT_CNT) * savesFreq - 1;

        if gGameApp.TryLoadSavePoint(fSavePointTick) then
        begin
          Inc(totalLoads);
          OnProgress_Left(Format('Load: %d', [fSavePointTick]));
          OnProgress4(Format('Desyncs: %d / %d / %d', [desyncCnt, totalRuns, totalLoads]));
          Log('SavePointTick = ' + IntToStr(fSavePointTick));

          fRunKind := drkReplay;
          gGame.GameInputProcess.OnReplayDesync := ReplayCrashed;

          SimulateGame(fSavePointTick + 1, Min(fSavePointTick + replayLength, simulLastTick));

          // RNG mismatch found. Simulate game to collect every tick save CRC
          if fRngMismatchFound then
          begin
            Log(Format('Found rng mismatch on ''%s'' at tick %d', [fMap, fRngMismatchTick]));
            Inc(desyncCnt);
            OnProgress4(Format('Desyncs: %d / %d / %d', [desyncCnt, totalRuns, totalLoads]));

            fRunKind := drkGameCRC;

            StartGame;

            SimulateGame(0, fRngMismatchTick - 1);

            fGameModeSetEvent(gmReplaySingle);

            fCRCDesyncFound := False;
            fCRCDesyncTick := -1;

            // Load at certain savepoint
            if gGameApp.TryLoadSavePoint(fSavePointTick) then
            begin
              fRunKind := drkReplayCRC;
              SimulateGame(fSavePointTick - 1, simulLastTick);

              // tick CRC desync found
              if fCRCDesyncFound then
              begin
                Log(Format('Found save CRC desync on ''%s'' Seed = %d at tick %d', [fMap, CUSTOM_SEED_VALUE, fCRCDesyncTick]));
                fRunKind := drkGameSave;
                StartGame;
                SimulateGame(0, Max(fCRCDesyncTick, fRngMismatchTick));
              end 
              else
                Log('!!! Could not find save CRC desync tick !!!');
            end;
            Break;
          end;
        end
        else
          OnProgress_Left('');

        if Assigned(fOnStop) and fOnStop then
          Exit;
      end;

      OnProgress2(fMap + ' Run ' + IntToStr(L));
      OnProgress4(Format('Desyncs: %d / %d / %d', [desyncCnt, totalRuns, totalLoads]));

      if Assigned(fOnStop)
        and fOnStop then
        Exit;
    end;
  end;

  gGameApp.StopGame(grSilent);
end;



function TKMRunnerDesyncTest.GetSaveDir(aSaveName: string): string;
begin
  Result := Format('%s..\..\Saves\%s\',[ExtractFilePath(ParamStr(0)), aSaveName]);
end;


procedure TKMRunnerDesyncTest.Tick_GIPRandom;
const
  FREQ = 50;
var
  hand, enemyHand: TKMHand;
  group, group2: TKMUnitGroup;
  enemyUnit: TKMUnit;
  house, enemyHouse: TKMHouse;
  ht: TKMHouseType;
  P: TKMPoint;
begin
  // Enable to allow gMySpectator.HandIndex change
//  SHOW_STATUS_BAR := True;
//  DEV_CHEATS := True;

  // We use gRandom.Get for repeatability in Stadium

  Log(Format('Tick: %5d %d' ,[gGameParams.Tick, fRunSeed]));
  if KaMRandomWSeed(fRunSeed, FREQ) = 0 then
  begin
    gMySpectator.HandID := KaMRandomWSeed(fRunSeed, gHands.Count);
    hand := gMySpectator.Hand;

    if hand.IsAnimal then Exit;

    // Army
    if hand.UnitGroups.Count > 0 then
    begin
      group := hand.UnitGroups[KaMRandomWSeed(fRunSeed, hand.UnitGroups.Count)];

      case KaMRandomWSeed(fRunSeed, FREQ) of
        0:  gGameApp.Game.GameInputProcess.CmdArmy(gicArmyFeed, group);
        1:  gGameApp.Game.GameInputProcess.CmdArmy(gicArmySplit, group);
        2:  gGameApp.Game.GameInputProcess.CmdArmy(gicArmySplitSingle, group);
        3:  gGameApp.Game.GameInputProcess.CmdArmy(gicArmyStorm, group);
        4:  gGameApp.Game.GameInputProcess.CmdArmy(gicArmyHalt, group);
      end;

      enemyHand := gHands[KaMRandomWSeed(fRunSeed, gHands.Count)];
      if enemyHand <> hand then
      if enemyHand.Units.Count > 0 then
      begin
        enemyUnit := enemyHand.Units[KaMRandomWSeed(fRunSeed, enemyHand.Units.Count)];

        if KaMRandomWSeed(fRunSeed, FREQ) = 0 then
          gGameApp.Game.GameInputProcess.CmdArmy(gicArmyAttackUnit, group, enemyUnit);
      end;

      group2 := hand.UnitGroups[KaMRandomWSeed(fRunSeed, hand.UnitGroups.Count)];

      if KaMRandomWSeed(fRunSeed, FREQ) = 0 then
        gGameApp.Game.GameInputProcess.CmdArmy(gicArmyLink, group, group2);

      if enemyHand.Houses.Count > 0 then
      begin
        enemyHouse := enemyHand.Houses[KaMRandomWSeed(fRunSeed, enemyHand.Houses.Count)];

        if KaMRandomWSeed(fRunSeed, FREQ) = 0 then
          gGameApp.Game.GameInputProcess.CmdArmy(gicArmyAttackHouse, group, enemyHouse);
      end;

//      if hand.Houses.Count > 0 then
//      begin
//        house := hand.Houses[KaMRandomWSeed(fRunSeed, hand.Houses.Count)];
//        if house.HouseType in [htTowerArrow, htTower2] then
//        if KaMRandomWSeed(fRunSeed, FREQ) = 0 then
//          gGameApp.Game.GameInputProcess.CmdArmyCrewTower(group, house);
//      end;

//      if group.IsInsideTower then
//      begin
//        if KaMRandomWSeed(fRunSeed, FREQ) = 0 then
//          gGameApp.Game.GameInputProcess.CmdArmyExitHouse(group, group.Members[0].InHouse);
//      end;

      if KaMRandomWSeed(fRunSeed, FREQ) = 0 then
        gGameApp.Game.GameInputProcess.CmdArmy(gicArmyFormation, group, KaMRandomWSeed(fRunSeed, 4), KaMRandomWSeed(fRunSeed, group.Count));
      if KaMRandomWSeed(fRunSeed, FREQ) = 0 then
        gGameApp.Game.GameInputProcess.CmdArmy(gicArmyWalk, group, TKMPoint.New(KaMRandomWSeed(fRunSeed, gTerrain.MapX-1), KaMRandomWSeed(fRunSeed, gTerrain.MapY-1)), TKMDirection(KaMRandomWSeed(fRunSeed, 9)));
    end;

    // Building
    begin
      // gicBuildRemoveFieldPlan
      P := gTerrain.EnsureTileInMapCoords(hand.CenterScreen + TKMPoint.New(KaMRandomWSeedI2(fRunSeed, 30), KaMRandomWSeedI2(fRunSeed, 30)));
      case KaMRandomWSeed(fRunSeed, FREQ) of
        0: gGameApp.Game.GameInputProcess.CmdBuild(gicBuildRemoveFieldPlan, P);
        1: gGameApp.Game.GameInputProcess.CmdBuild(gicBuildRemoveHouse, P);
        2: gGameApp.Game.GameInputProcess.CmdBuild(gicBuildRemoveHousePlan, P);
      end;

      P := gTerrain.EnsureTileInMapCoords(hand.CenterScreen + TKMPoint.New(KaMRandomWSeedI2(fRunSeed, 30), KaMRandomWSeedI2(fRunSeed, 30)));
      case KaMRandomWSeed(fRunSeed, FREQ) of
        0: gGameApp.Game.GameInputProcess.CmdBuild(gicBuildRemoveFieldPlan, P);
        1: gGameApp.Game.GameInputProcess.CmdBuild(gicBuildRemoveHouse, P);
        2: gGameApp.Game.GameInputProcess.CmdBuild(gicBuildRemoveHousePlan, P);
      end;

      // CmdBuildAddFieldPlan
      if KaMRandomWSeed(fRunSeed, FREQ) = 0 then
      begin
        P := gTerrain.EnsureTileInMapCoords(hand.CenterScreen + TKMPoint.New(KaMRandomWSeedI2(fRunSeed, 30), KaMRandomWSeedI2(fRunSeed, 30)));
        gGameApp.Game.GameInputProcess.CmdBuild(gicBuildToggleFieldPlan, P, TKMFieldType(KaMRandomWSeed(fRunSeed, 3) + 1))
      end;
//
      // CmdBuildAddHousePlan
      if KaMRandomWSeed(fRunSeed, FREQ * 5) = 0 then
      begin
        P := gTerrain.EnsureTileInMapCoords(hand.CenterScreen + TKMPoint.New(KaMRandomWSeedI2(fRunSeed, 30), KaMRandomWSeedI2(fRunSeed, 30)));
        ht := TKMHouseType(KaMRandomWSeed(fRunSeed, Ord(HOUSE_MAX) - Ord(HOUSE_MIN) + 1) + 2);
        if (ht <> htSiegeWorkshop)
          and gResHouses.IsValid(ht)
          {and gResHouses[ht].HouseEnabled
          and gResHouses[ht].Buildable} then
          gGameApp.Game.GameInputProcess.CmdBuild(gicBuildHousePlan, P, ht);
      end;
    end;

    // House
    if hand.Houses.Count > 0 then
    begin
      house := hand.Houses[KaMRandomWSeed(fRunSeed, hand.Houses.Count)];

      // gicHouseRepairToggle, gicHouseClosedForWorkerTgl, gicHBarracksAcceptRecruitsTgl, gicHouseDeliveryModeNext, gicHouseDeliveryModePrev
      case KaMRandomWSeed(fRunSeed, FREQ) of
        0:  gGameApp.Game.GameInputProcess.CmdHouse(gicHouseRepairToggle, house);
        1:  gGameApp.Game.GameInputProcess.CmdHouse(gicHouseClosedForWorkerTgl, house);
        2:  gGameApp.Game.GameInputProcess.CmdHouse(gicHBarracksAcceptRecruitsTgl, house);
        3:  gGameApp.Game.GameInputProcess.CmdHouse(gicHouseDeliveryModeNext, house);
        4:  gGameApp.Game.GameInputProcess.CmdHouse(gicHouseDeliveryModePrev, house);
      end;

      //gicHouseOrderProduct, gicHouseSchoolTrainChOrder
      if KaMRandomWSeed(fRunSeed, FREQ) = 0 then
        if house.IsComplete then
          if gResHouses[house.HouseType].DoesOrders then
            gGameApp.Game.GameInputProcess.CmdHouse(gicHouseOrderProduct, house, KaMRandomWSeed(fRunSeed, 4), KaMRandomWSeed(fRunSeed, 9));

      //gicHouseRemoveTrain gicHouseSchoolTrainChOrder gicHouseRemoveTrain gicHouseSchoolTrain gicHouseSchoolTrainChLastUOrder
      if house.IsComplete then
        if house.HouseType = htSchool then
          case KaMRandomWSeed(fRunSeed, FREQ) of
            0: gGameApp.Game.GameInputProcess.CmdHouse(gicHouseRemoveTrain, house, KaMRandomWSeed(fRunSeed, 5));
//            1: gGameApp.Game.GameInputProcess.CmdHouse(gicHouseSchoolTrainChOrder, house, KaMRandomWSeed(fRunSeed, 5), KaMRandomWSeed(fRunSeed, 5));
            2: gGameApp.Game.GameInputProcess.CmdHouse(gicHouseRemoveTrain, house, KaMRandomWSeed(fRunSeed, 5));
            3: gGameApp.Game.GameInputProcess.CmdHouse(gicHouseSchoolTrain, house, School_Order[KaMRandomWSeed(fRunSeed, Length(School_Order))], KaMRandomWSeed(fRunSeed, 10));
//            4: gGameApp.Game.GameInputProcess.CmdHouse(gicHouseSchoolTrainChLastUOrder, house, KaMRandomWSeed(fRunSeed, 2));
          end;


//      if KaMRandomWSeed(fRunSeed, FREQ) = 0 then
//        if gResHouses[house.HouseType].IsSpacious then
//          if (gResHouses[house.HouseType].WareInCount > 0) then
//            gGameApp.Game.GameInputProcess.CmdHouseWareBlock(
//              house, gResHouses[house.HouseType].WareInType[KaMRandomWSeed(fRunSeed, gResHouses[house.HouseType].WareInCount)]);
//
//    //procedure CmdHouseMarketFrom(aHouse: TKMHouse; aItem: TKMWareType);
//    //procedure CmdHouseMarketTo(aHouse: TKMHouse; aItem: TKMWareType);
//
//      if KaMRandomWSeed(fRunSeed, FREQ) = 0 then
//        if house.HouseType = htWoodcutters then
//          gGameApp.Game.GameInputProcess.CmdHouseWoodcutterMode(house, TKMWoodcutterMode(KaMRandomWSeed(fRunSeed, 3)));
//
//      if KaMRandomWSeed(fRunSeed, FREQ) = 0 then
//      if house.IsComplete then
//        if gResHouses[house.HouseType].TrainCount > 0 then
//          gGameApp.Game.GameInputProcess.CmdHouseTrainQueueAdd(
//            house, gResHouses[house.HouseType].Trains[KaMRandomWSeed(fRunSeed, gResHouses[house.HouseType].TrainCount)], KaMRandomWSeed(fRunSeed, 3));
//
//      if KaMRandomWSeed(fRunSeed, FREQ) = 0 then
//      if house.IsComplete then
//        if gResHouses[house.HouseType].TrainCount > 0 then
//          gGameApp.Game.GameInputProcess.CmdHouseTrainQueueRemoveIndex(
//            house, KaMRandomWSeed(fRunSeed, 3), KaMRandomWSeed(fRunSeed, 3));
    end;
  end;
end;


{ TKMRunnerAAIPerformanceTest }
procedure TKMRunnerAAIPerformance.Reset;
begin
  fStartTime := TimeGet;
end;


procedure TKMRunnerAAIPerformance.SetUp();
begin
  inherited;

//  fDesyncsDir := Format('%s..\Desyncs\', [ExeDir]);
//  ForceDirectories(fDesyncsDir);
//
//  SetLength(fTickCRC, fResults.TimesCount);
//
  fOnTick := TickPlayed;
//  fOnBeforeTick := BeforeTickPlayed;

  // Deactivate KaM log
  if (gLog = nil) then
    gLog := TKMLog.Create(Format('%sUtils\Runner\Runner_Log.log',[ExeDir]));
  gLog.MessageTypes := [];

  gLog.SetDefaultMessageTypes;

//  Include(gLog.MessageTypes, lmtRandomChecks);
//  Include(gLog.MessageTypes, lmtCommands);

//  LOG_GAME_TICK := True;

  CALC_EXPECTED_TICK := False;
  CRASH_ON_REPLAY := False;
  SAVE_GAME_AS_TEXT := True;
  ALLOW_SAVE_IN_REPLAY := True;
  SAVE_GAME_AS_TEXT := False;
  GAME_NO_UPDATE_ON_TIMER := True;
  GAME_SAVE_STRIP_FOR_CRC := True;
  SKIP_SAVE_SAVPTS_TO_FILE := True;
  SAVE_RANDOM_CHECKS := False;
  BLOCK_FILE_WRITE := True;
//  GAME_SAVE_CHECKPOINT_FREQ_MIN := 0;
//  GAME_SAVE_CHECKPOINT_CNT_LIMIT_MAX := 0;

//  Include(gLog.MessageTypes, lmtRandomChecks)
end;


procedure TKMRunnerAAIPerformance.TearDown();
begin

  inherited;
end;


function TKMRunnerAAIPerformance.TickPlayed(aTick: Cardinal): Boolean;
begin
  // good for debug
  Result := True;
end;


procedure TKMRunnerAAIPerformance.Execute(aRun: Integer);
const
  // Maps for simulation (I dont use for loop in this array)
  MAPS: array [1..18] of String = ('Stress_Test_200','Across the Desert','Mountainous Region','Battle Sun','Neighborhood Clash','Valley of the Equilibrium','Wilderness',
                                   'Border Rivers','Blood and Ice','A Midwinter''s Day','Coastal Expedition','Defending the Homeland','Eruption',
                                   'Forgotten Lands','Golden Cliffs','Rebound','Riverlands', 'Shadow Realm');
  MAPS_8P: array [1..29] of String = ('A War of Justice','Babylon','Back in the Desert','Center Castle Looting','Cold Water 8P',
                                   'Complication in Simplicity','Crystalline Falls','Cursed Ravine','Dance of Death','Dead of Winter',
                                   'Drastic Measures','Ending the Tyranny','Twin Peaks','Valley of the Equilibrium 8P', 'Frozen Waters',
                                   'Hand in Hand','Mega Land','Nibenay Basin','Paradise Island','Reborn','Rich Land','Tale of Two Lands',
                                   'The Final Frontier','The Last Port','The Same Rocks','The Valley of Dangers 2','Volcanic Violence',
                                   'Volcano Valley','Voros Arany');
  //Fighting maps
  FIGHT_MAPS: array[1..33] of string = ('Icewind Valley 6P', 'Red Valley', 'Clarity Falls - Escape', 'Enter the Heat', 'Pirate Bond',
                                  'Sharks Islands', 'Dangerous Shore', 'Ambushed', 'Bannockburn','Battle of Great Generals',
                                  'Gorges', 'Spring of Events', 'Inner Struggle', 'Last Fight for Oasis','Lost Road',
                                  'River Crossing','Shoulder to Shoulder','The Pirates','Unknown Danger','Battle in the Ruined City',
                                  'Lost City Struggle','Cross','Cursed Land','Gunplay','Icewind Valley','Rocky Mountains',
                                  'Shallows of Death','Snow Cross','The Citadel','The King Says','Tundra','Atoll','Coastal Encounter');

  COOP_MAPS: array[1..45] of string = ('A Clash of Kings', 'A Farmers Wish Coop', 'A Southern Journey', 'A Way East', 'Bridgecal Dundee',
                                  'Coalical Dundee', 'Dead Border','Hillycal Dundee','Lakeland','No Escape','Northern Islands I',
                                  'Return to Moorbach','Siege of Castle Fennford','The Cracker','The Dig','TPR 03','TPR 04','TPR 05',
                                  'TPR 06','TPR 07','TPR 08','TPR 09','TPR 10','TPR 11','TPR 12','TPR 13','TPR 14','Tropical Dundee',
                                  'TSK 03','TSK 06','TSK 07','TSK 08','TSK 09','TSK 10','TSK 11','TSK 12','TSK 13','TSK 14','TSK 15','TSK 16',
                                  'TSK 17','TSK 18','TSK 19','TSK 20','Waterfall Dundee');

  SIMUL_TIME_MAX: Integer = 10*60*180; //1 hour
  SAVEPT_FREQ: Integer = 10*60*1; //every 1 min
  REPLAY_LENGTH: Integer = 1500; // ticks to find RNG mismatch
//  SAVEPT_CNT = 1; //(SIMUL_TIME_MAX div SAVEPT_FREQ) - 1;
//  SAVEPT_CNT = (SIMUL_TIME_MAX div SAVEPT_FREQ) - 1;
  LOAD_SAVEPT_AT_TICK = 0;
  SKIP_FIRST_SAVEPT_CNT = 15; //Skip first savepoints to save some time

  MAPS_TO_TEST = 3;
  cnt_MAP_SIMULATIONS = 1;

  procedure StartGame;
  var
    mapFullName: string;
  begin
    mapFullName := Format('%sMapsMP\%s\%s.dat',[ExeDir,fMap,fMap]);
    gGameApp.NewSingleMap(mapFullName, fMap, -1, 0, mdNone, AIType);
  end;


var
  K,L: Integer;
//  mapsCnt: Integer;
  startMapI, simulLastTick, totalRuns: Integer;

  mapT1, mapT2, score: Cardinal;
begin
  DEFAULT_PEACE_TIME := 60;
  PAUSE_GAME_BEFORE_TICK := -1;    //Pause at specified game tick
//  MAKE_SAVEPT_BEFORE_TICK := 40800;

  totalRuns := 0;
  fStartTime := TimeGet;

//  mapsCnt := 0;
  score := 0;
  startMapI := 2;

  for K := startMapI to MAPS_TO_TEST + startMapI - 1 do
//  for K := 5 to High(MAPS) do
//  while M < mapsCnt do
  begin
//    K := Random(mapsCnt) + 1;
    fMap := MAPS[K];
//    case MapsType of
//      rmtClassic: fMap := MAPS[K];
//      rmtMP8:     fMap := MAPS_8P[K];
//      rmtFight:   fMap := FIGHT_MAPS[K];
//      rmtCoop:    fMap := COOP_MAPS[K];
//    end;

//    Inc(M);

    for L := 1 to cnt_MAP_SIMULATIONS do
//    L := 1;
    begin
      Reset;
      Inc(totalRuns);
      fRun := L;
      CUSTOM_SEED_VALUE := L + Seed;

      OnProgress3('Seed: ' + IntToStr(CUSTOM_SEED_VALUE));
      OnProgress2(fMap + ' Run ' + IntToStr(L));

      OnProgress_Left('');
      OnProgress_Left2('');
      OnProgress_Left3('');

      StartGame;

      gGameSettings.DebugSaveGameAsText := True;

      gGameSettings.SaveCheckpoints := False;

//      LOG_GAME_TICK := True;
//      Include(gLog.MessageTypes, lmtCommands);

      mapT1 := TimeGet;
      SimulateGame(0, DEFAULT_PEACE_TIME*60*10);
      mapT2 := TimeSince(mapT1);
      score := score + mapT2;

//      LOG_GAME_TICK := False;
//      Exclude(gLog.MessageTypes, lmtCommands);

      simulLastTick := min(SIMUL_TIME_MAX, fResults.TimesCount - 1);

      if Assigned(fOnStop)
        and fOnStop then
        Exit;
    end;
  end;

  OnProgress_Left(Format('Score: %d', [Round(score / totalRuns)]));

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

  gHands[0].AddUnitGroup(utSwordFighter, KMPoint(63, 64), TKMDirection(dirE), 8, 24);
  gHands[1].AddUnitGroup(utSwordFighter, KMPoint(65, 64), TKMDirection(dirW), 8, 24);

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
  gLog.AddTime('TimeAver: ' + IntToStr(Round(TimeSince(Time)/Runs)));
  gLog.AddTime('Time: ' + IntToStr(TimeSince(Time)));
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
  gLog.AddTime('Time: ' + IntToStr(TimeSince(StartT)));

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

  gGameApp.NewCampaignMap(cmp, 1);

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
  gLog.AddTime('TimeAver: ' + IntToStr(Round(TimeSince(fTime)/fRuns)));
  gLog.AddTime('Time: ' + IntToStr(TimeSince(fTime)));

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


{ TKMRunnerCachePerformanceTest }
procedure TKMRunnerCachePerformance.Execute(aRun: Integer);
const
  SIZE = 13;
  SIZE_HUGE = 100000000; //100 millions
var
  I, J, K, L, score: Integer;
  bidKey, bidKey2: TKMRDeliveryBidKey;
  bid: TKMRDeliveryBid;
  T1,T2: Int64;
begin
  inherited;

  fCache.Clear;
  SetKaMSeed(1);
  T1 := TimeGetUSec;


  bidKey.FromP := KMPoint(0, 5);
  bidKey.ToP := KMPoint(10, 15);
  bidKey2.FromP := KMPoint(20, 25);
  bidKey2.ToP := KMPoint(30, 35);
  for I := 0 to SIZE_HUGE - 1 do
  begin
//    bidKey.Compare(bidKey2);
    bidKey.GetHashCode;
  end;
//    for J := 0 to SIZE - 1 do
//    begin
//      bidKey.FromP := KMPoint(I, J);
//      for K := 0 to SIZE - 1 do
//        for L := 0 to SIZE - 1 do
//        begin
//          bidKey.ToP := KMPoint(K, L);
//          bidKey
////          bid.Value := KaMRandomS1(100, 'test');
////          bid.TimeToLive := 100;
////          fCache.Add(bidKey, bid);
//        end;
//    end;

  T2 := TimeSinceUSec(T1);

  OnProgress_Left(Format('Score: %d', [T2 div 1000]));
end;


procedure TKMRunnerCachePerformance.Reset;
begin

end;


procedure TKMRunnerCachePerformance.SetUp;
begin
  // inherited;

  fCache := TKMRDeliveryCache.Create(TKMRDeliveryBidKeyEqualityComparer.Create);

//  if (gLog = nil) then
//    gLog := TKMLog.Create(Format('%sUtils\Runner\Runner_Log.log',[ExeDir]));
//  gLog.MessageTypes := [];
end;


procedure TKMRunnerCachePerformance.TearDown;
begin
  // inherited;

  fCache.Free;
end;


{ TKMRunnerCachePerformanceTest.TKMRDeliveryBidKey }
//example taken from https://stackoverflow.com/questions/18068977/use-objects-as-keys-in-tobjectdictionary
{$IFOPT Q+}
  {$DEFINE OverflowChecksEnabled}
  {$Q-}
{$ENDIF}
function CombinedHash(const Values: array of Integer): Integer;
var
  Value: Integer;
begin
  Result := 17;
  for Value in Values do begin
    Result := Result*37 + Value;
  end;
end;
{$IFDEF OverflowChecksEnabled}
  {$Q+}
{$ENDIF}


function TKMRunnerCachePerformance.TKMRDeliveryBidKey.Compare(aOther: TKMRDeliveryBidKey): Integer;
begin
//  Result := GetHashCode - aOther.GetHashCode;
  if FromP = aOther.FromP then
    Result := ToP.Compare(aOther.ToP)
  else
    Result := FromP.Compare(aOther.FromP);
end;


function TKMRunnerCachePerformance.TKMRDeliveryBidKey.GetHashCode: Integer;
var
//  a,b,c,d,xTotal,yTotal: Integer;
//  totalCard: Cardinal;
  total: Int64;
begin
  //a, b, c, d should be the same if we swap From and To
//  a :=    (FromP.X + ToP.X);
//  b := Abs(FromP.X - ToP.X);
//  c :=     FromP.Y + ToP.Y;
//  d := Abs(FromP.Y - ToP.Y);
////  xTotal := (a shl 9) or b;
////  yTotal := (c shl 9) or d;
////  totalCard := (a shl 24) or (b shl 16) or (c shl 8) or d;
//  Int64Rec(total).Words[0] := a;
//  Int64Rec(total).Words[1] := b;
//  Int64Rec(total).Words[2] := c;
//  Int64Rec(total).Words[3] := d;
  Int64Rec(total).Words[0] := (FromP.X + ToP.X);
  Int64Rec(total).Words[1] := Abs(FromP.X - ToP.X);
  Int64Rec(total).Words[2] := FromP.Y + ToP.Y;
  Int64Rec(total).Words[3] := Abs(FromP.Y - ToP.Y);
  Result := THashBobJenkins.GetHashValue(total, SizeOf(Int64), 0);
//  Result := THashBobJenkins.GetHashValue(totalCard, SizeOf(Cardinal), 0);
//  Result := CombinedHash([THashBobJenkins.GetHashValue(xTotal, SizeOf(Integer), 0),
//                          THashBobJenkins.GetHashValue(yTotal, SizeOf(Integer), 0)]);
//  Result := CombinedHash([THashBobJenkins.GetHashValue(a, SizeOf(Integer), 0),
//                          THashBobJenkins.GetHashValue(b, SizeOf(Integer), 0),
//                          THashBobJenkins.GetHashValue(c, SizeOf(Integer), 0),
//                          THashBobJenkins.GetHashValue(d, SizeOf(Integer), 0)]);
end;


{ TKMRunnerCachePerformanceTest.TKMRDeliveryBidKeyEqualityComparer }
function TKMRunnerCachePerformance.TKMRDeliveryBidKeyEqualityComparer.Equals(const Left, Right: TKMRDeliveryBidKey): Boolean;
begin

end;


function TKMRunnerCachePerformance.TKMRDeliveryBidKeyEqualityComparer.GetHashCode(const Value: TKMRDeliveryBidKey): Integer;
begin

end;


{ TKMRunnerCachePerformanceTest.TKMRDeliveryCache }
procedure TKMRunnerCachePerformance.TKMRDeliveryCache.Add(const FromP: TKMPoint; ToP: TKMPoint; const aValue: Single;
                                                              const aTimeToLive: Word);
var
  key: TKMRDeliveryBidKey;
  bid: TKMRDeliveryBid;
begin
  if not CACHE_DELIVERY_BIDS then Exit;

  key.FromP := FromP;
  key.ToP := ToP;
  bid.Value := aValue;
  bid.TimeToLive := aTimeToLive;
  inherited Add(key, bid);
end;

procedure TKMRunnerCachePerformance.TKMRDeliveryCache.Add(const aKey: TKMRDeliveryBidKey; const aValue: Single;
                                                              const aTimeToLive: Word);
var
  value: TKMRDeliveryBid;
begin
  if not CACHE_DELIVERY_BIDS then Exit;

  value.Value := aValue;
  value.TimeToLive := aTimeToLive;
  inherited Add(aKey, value);
end;


procedure TKMRunnerCachePerformance.TKMRDeliveryCache.Add(const aKey: TKMRDeliveryBidKey; const aBid: TKMRDeliveryBid);
begin
  if not CACHE_DELIVERY_BIDS then Exit;

  inherited Add(aKey, aBid);
end;


function TKMRunnerCachePerformance.TKMRDeliveryCache.TryGetValue(const aKey: TKMRDeliveryBidKey;
                                                                     var aValue: TKMRDeliveryBid): Boolean;
begin
  Result := False;
  if inherited TryGetValue(aKey, aValue) then
  begin
    if aValue.TimeToLive <= 0 then //Don't return expired records
      Remove(aKey) //Remove expired record
    else
      Exit(True); // We found value
  end;
end;


{ TKMRunnerCachePerformanceTest.TKMRDeliveryBidKeyComparer }
function TKMRunnerCachePerformance.TKMRDeliveryBidKeyComparer.Compare(const Left, Right: TKMRDeliveryBidKey): Integer;
begin
  //  Result := Left.GetHashCode - Right.GetHashCode;
  if Left.FromP = Right.FromP then
    Result := Left.ToP.Compare(Right.ToP)
  else
    Result := Left.FromP.Compare(Right.FromP);
end;


{ TKMRunnerCrashTest }
function TKMRunnerCrashTest.DoCheckSavePoints: Boolean;
begin
  Result := False;
end;


initialization
  RegisterRunner(TKMRunnerDesyncTest);
  RegisterRunner(TKMRunnerCrashTest);
  RegisterRunner(TKMRunnerAAIPerformance);
  RegisterRunner(TKMRunnerCachePerformance);
  RegisterRunner(TKMRunnerPushModes);
  RegisterRunner(TKMRunnerGA_TestParRun);
  RegisterRunner(TKMRunnerGA_HandLogistics);
  RegisterRunner(TKMRunnerGA_Manager);
  RegisterRunner(TKMRunnerGA_RoadPlanner);
  RegisterRunner(TKMRunnerGA_Farm);
  RegisterRunner(TKMRunnerGA_Quarry);
  RegisterRunner(TKMRunnerGA_Forest);
  RegisterRunner(TKMRunnerGA_CityAllIn);
  RegisterRunner(TKMRunnerGA_CityBuilder);
  RegisterRunner(TKMRunnerGA_CityPlanner);
  RegisterRunner(TKMRunnerGA_ArmyAttack);
  RegisterRunner(TKMRunnerGA_ArmyAttackNew);
  RegisterRunner(TKMRunnerFindBugs);
  RegisterRunner(TKMRunnerCombatAITest);
  RegisterRunner(TKMRunnerStone);
  RegisterRunner(TKMRunnerFight95);
  RegisterRunner(TKMRunnerAIBuild);
  RegisterRunner(TKMVortamicPF);
  RegisterRunner(TKMReplay);
  RegisterRunner(TKMVas01);
  RegisterRunner(TKMStabilityTest);
end.
