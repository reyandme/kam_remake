unit MainForm;
interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.StrUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.ComCtrls, Vcl.Samples.Spin,
  MainSimThread, PlotGraph, Log, Vcl.Mask, Vcl.DBCtrls;

type
  TParaller_Runner = class(TForm)

    pcMainPages: TPageControl;
      tsFitness: TTabSheet;
        imgFitness: TImage;
      tsGenes: TTabSheet;
        tbGeneSwitch: TTrackBar;
        imgGenes: TImage;
      TabSheet3: TTabSheet;
        imgTimes: TImage;
      tsLog: TTabSheet;
        mLog: TMemo;

    gbSim: TGroupBox;
      lMaps: TLabel;
      lDuration: TLabel;
      lThreads: TLabel;
      seMaps: TSpinEdit;
      seDuration: TSpinEdit;
      seThreads: TSpinEdit;

    gbGA: TGroupBox;
      lPopulation: TLabel;
      lGenerations: TLabel;
      sePopulation: TSpinEdit;
      seGenerations: TSpinEdit;

      lTournament: TLabel;
      seEndTournament: TSpinEdit;
      lResetGene: TLabel;
      eStartResetGene: TEdit;
      eEndResetGene: TEdit;
      lNormalMutation: TLabel;
      eStartGaussMut: TEdit;
      eEndGaussMut: TEdit;
      lVariance: TLabel;
      eStartVariance: TEdit;
      eEndVariance: TEdit;
    gbLoad: TGroupBox;
    cbBackupClass: TComboBox;
    cbBackupDate: TComboBox;
    bLoad: TButton;
    lClass: TLabel;
    lDate: TLabel;
    seStartTournament: TSpinEdit;
    lbClasses: TListBox;
    bRunSimulation: TButton;
    lClasses: TLabel;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure bRunSimulationClick(Sender: TObject);
    procedure tbGeneSwitchChange(Sender: TObject);
    procedure bLoadClick(Sender: TObject);
    procedure cbBackupClassChange(Sender: TObject);
    procedure RefreshGraphs(Sender: TObject);
  private
    fBackups: TStringList;
    fPlot: TPlotGraph;
    fSim: TMainSimThread;
    procedure LoadCfg();
    procedure RefreshBackups();
  public
    procedure Log(const aText: String);
    procedure ClearLog();
  end;

var
  Paraller_Runner: TParaller_Runner;

implementation
{$R *.dfm}


const
  COLORS_COUNT = 8;




procedure TParaller_Runner.FormCreate(Sender: TObject);
var
  s: String;
begin
  fBackups := nil;
  s := ExtractFilePath(ParamStr(0));
  gLog := TLog.Create(Log);
  fPlot := TPlotGraph.Create(imgGenes,imgFitness,tbGeneSwitch);
  fSim := TMainSimThread.Create(fPlot,ExtractFilePath(ParamStr(0)));
  // Refresh images
  imgGenes.Canvas.Brush.Color := $00282828;
  imgGenes.Canvas.FillRect(imgGenes.Canvas.ClipRect);
  imgFitness.Canvas.Brush.Color := $00282828;
  imgFitness.Canvas.FillRect(imgFitness.Canvas.ClipRect);
  imgTimes.Canvas.Brush.Color := $00282828;
  imgTimes.Canvas.FillRect(imgTimes.Canvas.ClipRect);
  // Load default configuration
  LoadCfg();
  RefreshBackups();
end;


procedure TParaller_Runner.FormDestroy(Sender: TObject);
begin
  FreeAndNil(fPlot);
  fSim.SimulationRequest := srTerminate;
  Sleep(100);
  FreeAndNil(fBackups);
  FreeAndNil(fSim);
  FreeAndNil(gLog);
end;


procedure TParaller_Runner.LoadCfg();
var
  K: Integer;
begin
  with fSim do
    begin
      for K := 0 to lbClasses.Items.Count - 1 do
        if (CompareStr(SIM_Class,lbClasses.Items[K]) = 0) then
          lbClasses.ItemIndex := K;
      seMaps.Value            := GA_CountMaps;
      seDuration.Value        := SIM_TimeInMin;
      seThreads.Value         := SIM_CountThreads;

      sePopulation.Value      := GA_CountIndividuals;
      seGenerations.Value     := GA_Generations;

      seStartTournament.Value := GA_START_TOURNAMENT_IndividualsCnt;
      seEndTournament.Value   := GA_FINAL_TOURNAMENT_IndividualsCnt;
      eStartResetGene.Text    := FloatToStr(GA_START_MUTATION_ResetGene);
      eEndResetGene.Text      := FloatToStr(GA_FINAL_MUTATION_ResetGene);
      eStartGaussMut.Text     := FloatToStr(GA_START_MUTATION_Gaussian);
      eEndGaussMut.Text       := FloatToStr(GA_FINAL_MUTATION_Gaussian);
      eStartVariance.Text     := FloatToStr(GA_START_MUTATION_Variance);
      eEndVariance.Text       := FloatToStr(GA_FINAL_MUTATION_Variance);
    end;
end;


procedure TParaller_Runner.RefreshBackups();
  procedure ExtractParts(aBackup: String; var aClass,aDate: String);
  begin
    aClass := ExtractFileName(aBackup); // Remove path to folder
    aDate := LeftStr(RightStr(aClass,25),21); // Remove class name and .txt
    aClass := LeftStr(aClass,Length(aClass)-26); // Remove date and .txt
  end;
var
  Check: Boolean;
  K, L: Integer;
  BckpClass,BckpDate, NewClass,NewDate: String;
begin
  // Save previous selection
  BckpClass := cbBackupClass.Items[cbBackupClass.ItemIndex];
  BckpDate := cbBackupDate.Items[cbBackupDate.ItemIndex];

  // Refresh list
  fSim.GetBackups(fBackups);
  // Check preselection or select the oldest backup as default
  if (fBackups.Count > 0) then
  begin
    Check := False;
    for K := 0 to fBackups.Count - 1 do
      Check := Check OR ContainsText(fBackups[K],BckpClass);
    if not Check OR (CompareStr(BckpClass,'') = 0) then
      ExtractParts(fBackups[ fBackups.Count-1 ], BckpClass, BckpDate);
  end;

  // Update GUI with classes
  cbBackupClass.Clear;
  for K := 0 to fBackups.Count - 1 do
  begin
    ExtractParts(fBackups[K], NewClass, NewDate);
    // Check duplicities
    Check := False;
    for L := 0 to cbBackupClass.Items.Count - 1 do
      Check := Check OR (CompareStr(cbBackupClass.Items[L],NewClass) = 0);
    if not Check then
      cbBackupClass.Items.Add( NewClass );
    if (CompareStr(BckpClass,NewClass) = 0) then
      cbBackupClass.ItemIndex := K;
  end;

  // Update GUI with dates
  cbBackupDate.Clear;
  for K := 0 to fBackups.Count - 1 do
  begin
    ExtractParts(fBackups[K], NewClass, NewDate);
    if (CompareStr(BckpClass,NewClass) = 0) then
    begin
      cbBackupDate.Items.Add( NewDate );
      if (CompareStr(BckpDate,NewDate) = 0) then
        cbBackupDate.ItemIndex := K;
    end;
  end;
end;


procedure TParaller_Runner.RefreshGraphs(Sender: TObject);
begin
  fPlot.RefreshGraphs();
end;


procedure TParaller_Runner.cbBackupClassChange(Sender: TObject);
begin
  RefreshBackups();
end;


procedure TParaller_Runner.bLoadClick(Sender: TObject);
var
  BackupName: String;
begin
  if (fSim.SimulationRequest = srNone) then
  begin
    // Get name of the Backup file
    BackupName := Format('%s\%s_%s.txt',[ dir_BACKUPS, cbBackupClass.Items[cbBackupClass.ItemIndex], cbBackupDate.Items[cbBackupDate.ItemIndex] ]);
    if fSim.InitSimulation(BackupName) then
    begin
      gLog.Log('Simulation was loaded');
      // Load default configuration so GA can continue
      LoadCfg();
    end
    else
      gLog.Log('Simulation could not be loaded');
  end;
end;


procedure TParaller_Runner.bRunSimulationClick(Sender: TObject);
begin
  if (fSim.SimulationRequest = srNone) then
  begin
    mLog.Clear;

    with fSim do
    begin
      SIM_Class := lbClasses.Items[ lbClasses.ItemIndex ];
      GA_CountGenes                          := Parametrization.GetParCnt(SIM_Class);
      GA_CountMaps	                         := seMaps.Value;
      SIM_TimeInMin                          := seDuration.Value;
      SIM_CountThreads                       := seThreads.Value;

      GA_CountIndividuals                    := sePopulation.Value;
      GA_Generations                         := seGenerations.Value;

      GA_START_TOURNAMENT_IndividualsCnt     := seStartTournament.Value;
      GA_FINAL_TOURNAMENT_IndividualsCnt     := seEndTournament.Value;
      try
        GA_START_MUTATION_ResetGene          := StrToFloat(eStartResetGene.Text);
        GA_FINAL_MUTATION_ResetGene          := StrToFloat(eEndResetGene.Text  );
        GA_START_MUTATION_Gaussian           := StrToFloat(eStartGaussMut.Text );
        GA_FINAL_MUTATION_Gaussian           := StrToFloat(eEndGaussMut.Text   );
        GA_START_MUTATION_Variance           := StrToFloat(eStartVariance.Text );
        GA_FINAL_MUTATION_Variance           := StrToFloat(eEndVariance.Text   );
      except
        On E : Exception do
          Log('Exception StringToFloat');
      end;
    end;

    fSim.SimulationRequest := srRun;
  end
  else if (fSim.SimulationRequest = srRun) then
    fSim.SimulationRequest := srNone;
end;


procedure TParaller_Runner.ClearLog();
begin
  mLog.Clear;
end;


procedure TParaller_Runner.Log(const aText: String);
begin
  mLog.Lines.Append(aText);
  SendMessage(mLog.Handle, EM_LINESCROLL, 0,mLog.Lines.Count);
end;


procedure TParaller_Runner.tbGeneSwitchChange(Sender: TObject);
begin
  TThread.Synchronize(nil,
    procedure
    begin
      fPlot.PlotGenes(tbGeneSwitch.Position);
    end
  );
  RefreshBackups();
end;


end.
