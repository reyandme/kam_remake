unit GeneticAlgorithm;

interface
uses
  Classes, SysUtils, Math;

type
  TIntegerArray = array of Integer;

  TGAIndividual = class
  private
    fGenes: array of Single;
    fFitness: array of Single; // Fitness is obtained for each map separately

    function GetCount(): Integer;
    function GetFitnessCount(): Integer;
    function GetGene(aIdx: Integer): Single;
    procedure SetGene(aIdx: Integer; aValue: Single);
    function GetFitness(aIdx: Integer): Single;
    procedure SetFitness(aIdx: Integer; aValue: Single);
    function GetSumFitness(): Single;
  public
    constructor Create(aGeneCount,aMapsCount: Integer);
    destructor Destroy(); override;

    property GenesCount: Integer read GetCount;
    property FitnessCount: Integer read GetFitnessCount;
    property Gene[aIdx: Integer]: Single read GetGene write SetGene;
    property Fitness[aIdx: Integer]: Single read GetFitness write SetFitness;
    property FitnessSum: Single read GetSumFitness;
  end;

  TGAPopulation = class
  private
    fIndividuals: array of TGAIndividual;
    function GetIndividual(Idx: Integer): TGAIndividual;
    procedure SetIndividual(Idx: Integer; aIdv: TGAIndividual);
    function GetCount(): Integer;
  public
    constructor Create(aPopulationCount, aGeneCount, aMapsCount: Integer; aInitialise: Boolean);
    destructor Destroy(); override;

    property Individual[Idx: Integer]: TGAIndividual read GetIndividual write SetIndividual; default;
    property Count: Integer read GetCount;

    function GetFittest(aOnlySomeIdx: TIntegerArray = nil; aMapWeightedEval: Boolean = True): TGAIndividual; overload;
  end;

  TGAAlgorithm = class
  private
    fMutationResetGene, fMutationGaussian, fMutationVariance: Single;
    fIndividualsInTournamentCnt: Word;
    function TournamentSelection(var aPopulation: TGAPopulation): TGAIndividual;
    function Crossover(aIdv1, aIdv2: TGAIndividual): TGAIndividual;
    procedure Mutate(aIdv: TGAIndividual);
  public
    constructor Create();
    destructor Destroy(); override;

    property MutationResetGene: Single read fMutationResetGene write fMutationResetGene;
    property MutationGaussian: Single read fMutationGaussian write fMutationGaussian;
    property MutationVariance: Single read fMutationVariance write fMutationVariance;
    property IndividualsInTournament: Word read fIndividualsInTournamentCnt write fIndividualsInTournamentCnt;

    procedure EvolvePopulation(var aOldPopulation, aNewPopulation: TGAPopulation);
  end;

implementation





{ TGAAlgorithm }
constructor TGAAlgorithm.Create();
begin
  fMutationResetGene := 0;
  fMutationGaussian := 0;
  fMutationVariance := 0;
end;


destructor TGAAlgorithm.Destroy();
begin
  inherited;
end;


procedure TGAAlgorithm.EvolvePopulation(var aOldPopulation, aNewPopulation: TGAPopulation);
var
  K,L: Integer;
  Idv1, Idv2: TGAIndividual;
begin
  // Evolve population
  for K := 0 to aOldPopulation.Count - 1 do
  begin
    Idv1 := TournamentSelection(aOldPopulation);
    Idv2 := Idv1;
    L := 0;
    while (Idv2 = Idv1) AND (L < 20) do // Try to not pick up the same individual
    begin
      L := L + 1;
      Idv2 := TournamentSelection(aOldPopulation);
    end;
    aNewPopulation[K] := Crossover(Idv1, Idv2);
    Mutate(aNewPopulation[K]);
  end;
end;


function TGAAlgorithm.TournamentSelection(var aPopulation: TGAPopulation): TGAIndividual;
var
  K, TournamentCount: Integer;
  TournamentIdx: TIntegerArray;
begin
  TournamentCount := Min(fIndividualsInTournamentCnt, aPopulation.Count);
  SetLength(TournamentIdx, TournamentCount);
  for K := 0 to TournamentCount - 1 do
    TournamentIdx[K] := Random(aPopulation.Count);
  Result := aPopulation.GetFittest(TournamentIdx);
end;


function TGAAlgorithm.Crossover(aIdv1, aIdv2: TGAIndividual): TGAIndividual;
var
  K: Integer;
  Output: TGAIndividual;
begin
  Output := TGAIndividual.Create(aIdv1.GenesCount,aIdv1.FitnessCount);
  for K := 0 to aIdv1.GenesCount - 1 do
    if (Random() < 0.5) then
      Output.Gene[K] := aIdv1.Gene[K]
    else
      Output.Gene[K] := aIdv2.Gene[K];
  Result := Output;
end;


procedure TGAAlgorithm.Mutate(aIdv: TGAIndividual);
var
  K: Integer;
begin
  // Reset gene mutation
  for K := 0 to aIdv.GenesCount - 1 do
    if (Random() <= fMutationResetGene) then
      aIdv.Gene[K] := Random();
  // Change gene value according to normal distribution
  for K := 0 to aIdv.GenesCount - 1 do
    if (Random() <= fMutationGaussian) then
      aIdv.Gene[K] := Min(1, Max( 0,
                        aIdv.Gene[K] + fMutationVariance * sqrt(  -2 * Ln( Max(1E-35,Random()) )  ) * cos( 2 * 3.1415 * Random() )
                      ));
end;




{ TGAPopulation }
constructor TGAPopulation.Create(aPopulationCount, aGeneCount, aMapsCount: Integer; aInitialise: Boolean);
var
  K: Integer;
begin
  SetLength(fIndividuals, aPopulationCount);
  for K := 0 to aPopulationCount - 1 do
  begin
    fIndividuals[K] := nil;
    if aInitialise then
      fIndividuals[K] := TGAIndividual.Create(aGeneCount,aMapsCount);
  end;
end;


destructor TGAPopulation.Destroy();
var
  K: Integer;
begin
  for K := 0 to Length(fIndividuals) - 1 do
    fIndividuals[K].Free;
  inherited;
end;


function TGAPopulation.GetIndividual(Idx: Integer): TGAIndividual;
begin
  Result := fIndividuals[Idx];
end;


procedure TGAPopulation.SetIndividual(Idx: Integer; aIdv: TGAIndividual);
begin
  fIndividuals[Idx] := aIdv;
end;


function TGAPopulation.GetFittest(aOnlySomeIdx: TIntegerArray = nil; aMapWeightedEval: Boolean = True): TGAIndividual;
var
  K,L: Integer;
  BestFit: Single;
  FitnessArr: array of Single;
  Fittest: TGAIndividual;
begin
  Fittest := nil;
  // Define Fitness array and clean it
  SetLength(FitnessArr,Length(fIndividuals));
  for K := Low(FitnessArr) to High(FitnessArr) do
    FitnessArr[K] := 0;
  // If no idexes are specified, select everything
  if (aOnlySomeIdx = nil) OR (Length(aOnlySomeIdx) <= 0) then
  begin
    SetLength(aOnlySomeIdx, Length(fIndividuals));
    for K := Low(fIndividuals) to High(fIndividuals) do
      aOnlySomeIdx[K] := K;
  end;
  // Calculate Fitness
  if aMapWeightedEval then
  begin
    for K := 0 to fIndividuals[0].FitnessCount - 1 do
    begin
      // Get best result
      BestFit := -1E30;
      for L in aOnlySomeIdx do
        if (BestFit < fIndividuals[L].Fitness[K]) then
          BestFit := fIndividuals[L].Fitness[K];
      if (BestFit = 0) then
        BestFit := 1;
      // Normalize fitness
      for L in aOnlySomeIdx do
        FitnessArr[L] := FitnessArr[L] + fIndividuals[L].Fitness[K] / abs(BestFit);
    end;
  end
  else
    for K in aOnlySomeIdx do
      FitnessArr[K] := fIndividuals[K].FitnessSum;
  // Find best individual
  L := 0; // For compiler
  for K in aOnlySomeIdx do
    if (Fittest = nil) OR (FitnessArr[L] < FitnessArr[K]) then
    begin
      Fittest := fIndividuals[K];
      L := K;
    end;
  Result := Fittest;
end;


function TGAPopulation.GetCount(): Integer;
begin
  Result := Length(fIndividuals);
end;





{ TGAIndividual }
constructor TGAIndividual.Create(aGeneCount,aMapsCount: Integer);
begin
  SetLength(fGenes,aGeneCount);
  SetLength(fFitness,aMapsCount);
  FillChar(fGenes[0], SizeOf(fGenes[0])*aGeneCount, #0);
  FillChar(fFitness[0], SizeOf(fFitness[0])*aMapsCount, #0);
end;


destructor TGAIndividual.Destroy();
begin
  inherited;
end;


function TGAIndividual.GetCount(): Integer;
begin
  Result := Length(fGenes);
end;


function TGAIndividual.GetFitnessCount(): Integer;
begin
  Result := Length(fFitness);
end;


function TGAIndividual.GetGene(aIdx: Integer): Single;
begin
  Result := -1;
  if (aIdx < GenesCount) then
    Result := fGenes[aIdx];
end;


procedure TGAIndividual.SetGene(aIdx: Integer; aValue: Single);
begin
  if (aIdx < GenesCount) then
    fGenes[aIdx] := aValue;
end;


function TGAIndividual.GetFitness(aIdx: Integer): Single;
begin
  Result := -1;
  if (aIdx < FitnessCount) then
    Result := fFitness[aIdx];
end;


procedure TGAIndividual.SetFitness(aIdx: Integer; aValue: Single);
begin
  if (aIdx < FitnessCount) then
    fFitness[aIdx] := aValue;
end;


function TGAIndividual.GetSumFitness(): Single;
var
  K: Integer;
begin
  Result := 0;
  for K := 0 to Length(fFitness) - 1 do
    Result := Result + fFitness[K];
end;

end.

