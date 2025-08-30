unit KM_GUIGameResultsMP;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, StrUtils, SysUtils,
  KM_CommonTypes,
  KM_Controls, KM_ControlsBase, KM_ControlsChart, KM_ControlsList, KM_ControlsProgressBar, KM_ControlsSwitch,
  KM_Defaults,
  KM_InterfaceDefaults, KM_HandStats,
  KM_ResTypes;

const
  STAT_CATEGORY_CNT = 10;

type
  TKMStatType = (stByPlayers, stByTeams);

  TKMEconomyStatKind = (estCitizens, estHouses);

  // Army chart types (enum)
  TKMChartWarriorType = (cwtArmyPower, cwtAll,
    cwtMilitia,      cwtAxeFighter,   cwtSwordsman,     cwtBowman,
    cwtArbaletman,   cwtPikeman,      cwtHallebardman,  cwtHorseScout,
    cwtCavalry,      cwtBarbarian,
    cwtPeasant,      cwtSlingshot,    cwtMetalBarbarian, cwtHorseman);

  // Chart army type class
  TKMChartWarrior = class
  private
    fType: TKMChartWarriorType;
    fUnitType: TKMUnitType;
    function GetUnitType: TKMUnitType;
    function GetGUIName: UnicodeString;
    function GetGUIIcon: Word;
  public
    constructor Create(aType: TKMChartWarriorType);
    property UnitType: TKMUnitType read GetUnitType;
    property GUIName: UnicodeString read GetGUIName;
    property GUIIcon: Word read GetGUIIcon;
    function HasUnitType: Boolean;
  end;

  TKMChartArmyMP = class
  private
    fType: TKMChartWarrior;
    fKind: TKMChartArmyKind;
    fChart: TKMChart;
    function GetArmyPowerChartData(aPlayer: TKMHandID): TKMCardinalArray;
  public
    constructor Create(aType: TKMChartWarriorType; aKind: TKMChartArmyKind; aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer);
    destructor Destroy; override;
    function IsEmpty(aPlayer: TKMHandID): Boolean;
    function GetChartData(aPlayer: TKMHandID): TKMCardinalArray;
    property Chart: TKMChart read fChart;
    property ChartType: TKMChartWarrior read fType;
  end;

  TKMStatsValues = array[0..MAX_HANDS-1] of array [0..STAT_CATEGORY_CNT] of Cardinal;

  TKMGameResultsMP = class
  private
    fOnStopGame: TUnicodeStringWDefEvent;
    fOnShowSPStats: TKMEvent;

    fReinitedLastTime: Boolean;

    fGameResultMsg: TKMGameResultMsg; //So we know where to go after results screen
    fLegendLinesVisible: array [TKMStatType] of array [0 .. MAX_HANDS - 1] of Boolean;  //Remember visible players when toggling wares

    fStatType: TKMStatType;

    fNoEconomyChartData: Boolean;
    fNoArmyChartData: Boolean;
    fColumnBoxArmy_Rows: array[TKMChartArmyKind] of array of TKMChartWarriorType;

    fChartSeparatorsPos: array[TKMStatType] of TStringList;
    fNamesToShow: array[TKMStatType] of array[0 .. MAX_HANDS - 1] of String;
    fTeamMembersNames: array[0 .. MAX_HANDS - 1] of array[0 .. MAX_HANDS - 1] of String;
    fTeamMembersColors: array[0 .. MAX_HANDS - 1] of array[0 .. MAX_HANDS - 1] of Cardinal;
    fTeamMembersCounts: array[0 .. MAX_HANDS - 1] of Byte;
    fColorsToShow: array[TKMStatType] of array[0 .. MAX_HANDS - 1] of Cardinal;
    fListToShow: array[TKMStatType] of TStringList;
    fStatsValues: array[TKMStatType] of TKMStatsValues;

    fShowAIResults: Boolean;
    procedure FreeListToShow(aStatType: TKMStatType);
    procedure RecreateListToShow(aStatType: TKMStatType);
    procedure BackClick(Sender: TObject);
    function DoAdjoinSameColorHand(aHandId: Integer): Boolean;
    function GetSelectedChartArmyKind: TKMChartArmyKind;
    function GetChartWares(aPlayer: TKMHandID; aWare: TKMWareType; aUseGDP: Boolean): TKMCardinalArray;
    function DoShowHandStats(aHandId: Integer): Boolean;

    procedure Create_ResultsMP(aParent: TKMPanel);
    procedure CreateBars(aParent: TKMPanel);
    procedure CreateChartEconomy;
    procedure CreateChartWares(aParent: TKMPanel);
    procedure CreateChartArmy(aParent: TKMPanel);

    procedure UpdateVisibleTab;
    procedure TabChange(Sender: TObject);
    procedure StatTypeChange(Sender: TObject);
    procedure SwitchBars_Click(Sender: TObject);
    procedure BarsUpdate(aStatType: TKMStatType);
    procedure BarsUpdatePos;
    procedure EconomyUpdate(Sender: TObject);
    procedure WareUpdate(Sender: TObject);
    procedure ArmyUpdate(Sender: TObject);

    procedure Chart_LegendClick(Sender: TObject; aLineIndex: Integer; aLineVisible: Boolean);

    procedure RadioEconomyTypeChange(Sender: TObject);
    procedure RadioWareTypeChange(Sender: TObject);
    procedure RadioArmyTypeChange(Sender: TObject);

    function GetChartLegendDetailedTitles(aStatType: TKMStatType; aLineI: Integer): TKMStringArray;
    function GetChartLegendDetailedColors(aStatType: TKMStatType; aLineI: Integer): TKMCardinalArray;

    procedure Reinit;
    procedure ReinitPlayersToShow;
    procedure ReinitTeamsToShow;
    procedure ReinitBars;
    procedure ReinitChartEconomy;
    procedure ReinitChartWares;
    procedure ReinitChartArmy;

    procedure Resize(Sender: TObject; const aValue: Integer);
  protected
    Panel_ResultsMP: TKMPanel;
      Button_Bars,
      Button_Army,
      Button_Economy,
      Button_Wares,
      Button_SwitchBars,
      Button_Players,Button_Teams: TKMButtonFlat;
      Label_ResultsMP: TKMLabel;
      Panel_Bars: TKMPanel;
        Panel_BarsUpper, Panel_BarsLower: TKMPanel;
          Label_ResultsPlayerName1, Label_ResultsPlayerName2: array [0 .. MAX_HANDS - 1] of TKMLabel;
          Bar_Results: array [0 .. MAX_HANDS - 1, 0 .. STAT_CATEGORY_CNT] of TKMPercentBar;
          Image_ResultsRosette: array [0 .. MAX_HANDS - 1, 0 .. STAT_CATEGORY_CNT] of TKMImage;
      Panel_ChartsEconomy: TKMPanel;
        Chart_Players_Citizens: TKMChart;
        Chart_Players_Houses: TKMChart;
        Chart_Teams_Citizens: TKMChart;
        Chart_Teams_Houses: TKMChart;
        Label_NoEconomyData: TKMLabel;
        Panel_ChartEconomy_Type: TKMPanel;
          Radio_ChartEconomyType: TKMRadioGroup;
      Panel_ChartsWares: TKMPanel;
        Columnbox_Wares: TKMColumnBox;    //columnBox for Quantities charts
        Columnbox_WaresGDP: TKMColumnBox; //columnBox for GDP charts
        Charts_Wares: array[TKMStatType] of array[TKMWareType] of TKMChart; //One for each kind
        Charts_WaresGDP: array[TKMStatType] of array [0..2] of TKMChart;
        Label_NoWareData: TKMLabel;
        Panel_ChartWare_Type: TKMPanel;
          Radio_ChartWareType: TKMRadioGroup;
      Panel_ChartsArmy: TKMPanel;
        Columnbox_Army: TKMColumnBox;
        Charts_Army: array[TKMStatType] of array[TKMChartArmyKind] of array[TKMChartWarriorType] of TKMChartArmyMP;
        Label_NoArmyData: TKMLabel;
        Panel_ChartArmy_Type: TKMPanel;
          Radio_ChartArmyType: TKMRadioGroup;
      Button_Back: TKMButton;
      Button_BackToGame: TKMButton;
  public
    constructor Create(aParent: TKMPanel; aOnStopGame: TUnicodeStringWDefEvent; aOnShowSPStats: TKMEvent);
    destructor Destroy; override;

    property GameResultMsg: TKMGameResultMsg read fGameResultMsg;

    procedure ResetControls;
    procedure Show(aMsg: TKMGameResultMsg; aReinitLastTime: Boolean = False);
    function Visible: Boolean;
    procedure Hide;
    procedure UpdateState(aTick: Cardinal);
  end;


implementation
uses
  KM_Main, KM_ResTexts, KM_Game, KM_HandsCollection, KM_CommonUtils, KM_Resource, KM_ResFonts,
  KM_RenderUI, KM_Hand, KM_ResUnits, KM_MapTypes, KM_Pics,
  KM_GameParams, KM_GameTypes, KM_InterfaceTypes;


const
  PANES_TOP = 185-80;
  BAR_ROW_HEIGHT = 21;
  CHART_HEIGHT = 595;
  CHART_ECO_HEIGHT = 285;
  BACK_BTN_Y_TO_BOTTOM = 60;
  SUBMENU_RIGHT_WIDTH = 170;
  BTN_BACK_TO_GAME_LEFT = RESULTS_X_PADDING + 330;

  GDPWares: array [0..2] of TKMWareType = (wtAll, wtWarfare, wtFood);


function GetWareIdInGDPArr(aWare: TKMWareType): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to 2 do
    if aWare = GDPWares[I] then
      Exit(I);
end;


function GetOwnerName(aHandId: Integer): String;
begin
  Result := gHands[aHandId].OwnerName(not gGameParams.IsSingleplayer);
end;


function GetChartLegendCaption(aStatType: TKMStatType): String;
begin
  Result := '';
  case aStatType of
    stByPlayers: Result := gResTexts[TX_WORD_PLAYERS];
    stByTeams:   Result := gResTexts[TX_WORD_TEAMS];
  end;
end;


{TKMChartArmyType}
constructor TKMChartWarrior.Create(aType: TKMChartWarriorType);
begin
  fType := aType;
  case aType of
    cwtAll:                   fUnitType := utAny;
    cwtMilitia..cwtHorseman:  fUnitType := TKMUnitType(Ord(utMilitia) + Ord(aType) - Ord(cwtMilitia));
  end;
end;


function TKMChartWarrior.GetUnitType: TKMUnitType;
begin
  Assert(HasUnitType, 'ArmyPower has no UnitType match');
  Result := fUnitType;
end;


function TKMChartWarrior.HasUnitType: Boolean;
begin
  Result := fType <> cwtArmyPower;
end;


function TKMChartWarrior.GetGUIName: UnicodeString;
begin
  case fType of
    cwtArmyPower: Result := gResTexts[TX_RESULTS_ARMY_POWER];
    cwtAll:       Result := gResTexts[TX_RESULTS_ALL_SOLDIERS];
    else           Result := gRes.Units[UnitType].GUIName;
  end;
end;


function TKMChartWarrior.GetGUIIcon: Word;
begin
  case fType of
    cwtArmyPower: Result := 53;
    cwtAll:       Result := 665;
    else           Result := gRes.Units[UnitType].GUIIcon;
  end;
end;


{TKMChartArmy}
constructor TKMChartArmyMP.Create(aType: TKMChartWarriorType; aKind: TKMChartArmyKind; aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer);
begin
  inherited Create;

  fType := TKMChartWarrior.Create(aType);
  fKind := aKind;
  fChart := TKMChart.Create(aParent, aLeft, aTop, aWidth, aHeight);
end;


destructor TKMChartArmyMP.Destroy;
begin
  FreeAndNil(fType);
  // fChart is freed by GUI (MasterPanel and so on...)
  inherited;
end;


function TKMChartArmyMP.GetChartData(aPlayer: TKMHandID): TKMCardinalArray;
begin
  if fType.HasUnitType then
    Result := gHands[aPlayer].Stats.ChartArmy[fKind,fType.UnitType]
  else
    Result := GetArmyPowerChartData(aPlayer);
end;


function TKMChartArmyMP.GetArmyPowerChartData(aPlayer: TKMHandID): TKMCardinalArray;
var
  WT: TKMUnitType;
  I, ChartCnt: Integer;
  value: Single;
begin
  ChartCnt := gHands[aPlayer].Stats.ChartCount;
  //Create new array and fill it (otherwise we assign pointers and corrupt data)
  SetLength(Result, ChartCnt);
  for I := 0 to ChartCnt - 1 do
    Result[I] := 0;

  for I := 0 to ChartCnt - 1 do
  begin
    value := 0;
    for WT := WARRIOR_MIN to WARRIOR_MAX do
      value := value + gHands[aPlayer].Stats.ChartArmy[fKind,WT][I]*WARRIORS_POWER_RATES[WT];
    Result[I] := Result[I] + Round(value);
  end;
end;


function TKMChartArmyMP.IsEmpty(aPlayer: TKMHandID): Boolean;
begin
  if fType.HasUnitType then
    Result := gHands[aPlayer].Stats.ChartArmyEmpty(fKind, fType.UnitType)
  else
    Result := gHands[aPlayer].Stats.ChartArmyEmpty(fKind, utAny);
end;


{ TKMGUIMenuResultsMP }
constructor TKMGameResultsMP.Create(aParent: TKMPanel; aOnStopGame: TUnicodeStringWDefEvent; aOnShowSPStats: TKMEvent);
var
  ST: TKMStatType;
begin
  inherited Create;

  fOnStopGame := aOnStopGame;
  fOnShowSPStats := aOnShowSPStats;
  fReinitedLastTime := False;

  for ST := Low(TKMStatType) to High(TKMStatType) do
  begin
    fChartSeparatorsPos[ST] := TStringList.Create;
    fChartSeparatorsPos[ST].Sorted := True;
  end;

  Create_ResultsMP(aParent);
  ResetControls;
end;


destructor TKMGameResultsMP.Destroy;
var
  wType: TKMChartWarriorType;
  cKind: TKMChartArmyKind;
  ST: TKMStatType;
begin
  for ST := High(TKMStatType) downto Low(TKMStatType) do
  begin
    for cKind := High(TKMChartArmyKind) downto Low(TKMChartArmyKind) do
      for wType := High(TKMChartWarriorType) downto Low(TKMChartWarriorType) do
        FreeAndNil(Charts_Army[ST,cKind,wType]);

    FreeListToShow(ST);
    FreeAndNil(fChartSeparatorsPos[ST]);
  end;

  inherited;
end;


procedure TKMGameResultsMP.CreateBars(aParent: TKMPanel);
const
  BarStep = 150 - 15;
  BarWidth = BarStep - 10;
  BarHalf = BarWidth div 2;
  Columns1: array[0..5] of Integer = (TX_RESULTS_MP_CITIZENS_TRAINED, TX_RESULTS_MP_CITIZENS_DISMISSED, TX_RESULTS_MP_CITIZENS_LOST,
                                     TX_RESULTS_MP_SOLDIERS_EQUIPPED, TX_RESULTS_MP_SOLDIERS_LOST,
                                     TX_RESULTS_MP_SOLDIERS_DEFEATED);
  Columns2: array[0..4] of Integer = (TX_RESULTS_MP_BUILDINGS_CONSTRUCTED, TX_RESULTS_MP_BUILDINGS_LOST,
                                     TX_RESULTS_MP_BUILDINGS_DESTROYED,
                                     TX_RESULTS_MP_WARES_PRODUCED, TX_RESULTS_MP_WEAPONS_PRODUCED);
var
  I, K, middle: Integer;
begin
  Panel_Bars := TKMPanel.Create(aParent, RESULTS_X_PADDING, PANES_TOP, aParent.Width - 2*RESULTS_X_PADDING, aParent.Height - PANES_TOP - BACK_BTN_Y_TO_BOTTOM);
  Panel_Bars.AnchorsStretch;
  middle := Panel_Bars.Height div 2;

    //Composed of two sections each on own Panel to position them vertically according to player count

    Panel_BarsUpper := TKMPanel.Create(Panel_Bars, 0, 0, Panel_Bars.Width, middle - 3);
    Panel_BarsUpper.Anchors := [anTop];

      for I := 0 to MAX_HANDS - 1 do
        Label_ResultsPlayerName1[I] := TKMLabel.Create(Panel_BarsUpper, 0, 38+I*BAR_ROW_HEIGHT, 150, 20, '', fntMetal, taLeft);

      for K := 0 to 5 do
      begin
        TKMLabel.Create(Panel_BarsUpper, 160 + BarStep*K, 0, BarWidth+6, 40, gResTexts[Columns1[K]], fntMetal, taCenter).WordWrap := True;
        for I := 0 to MAX_HANDS - 1 do
        begin
          Bar_Results[I,K] := TKMPercentBar.Create(Panel_BarsUpper, 160 + K*BarStep, 35+I*BAR_ROW_HEIGHT, BarWidth, 20, fntGrey);
          Bar_Results[I,K].TextYOffset := -3;
          Image_ResultsRosette[I,K] := TKMImage.Create(Panel_BarsUpper, 164 + K*BarStep, 38+I*BAR_ROW_HEIGHT, 16, 16, 8, rxGuiMain);
        end;
      end;

    Panel_BarsLower := TKMPanel.Create(Panel_Bars, 0, middle+3, Panel_Bars.Width, middle - 10);
    Panel_BarsLower.Anchors := [anBottom];

      for I := 0 to MAX_HANDS - 1 do
        Label_ResultsPlayerName2[I] := TKMLabel.Create(Panel_BarsLower, 0, 38+I*BAR_ROW_HEIGHT, 150, 20, '', fntMetal, taLeft);

      for K := 0 to 4 do
      begin
        TKMLabel.Create(Panel_BarsLower, 160 + BarStep*K, 0, BarWidth+6, 40, gResTexts[Columns2[K]], fntMetal, taCenter).WordWrap := True;
        for I := 0 to MAX_HANDS - 1 do
        begin
          Bar_Results[I,K+6] := TKMPercentBar.Create(Panel_BarsLower, 160 + K*BarStep, 35+I*BAR_ROW_HEIGHT, BarWidth, 20, fntGrey);
          Bar_Results[I,K+6].TextYOffset := -3;
          Image_ResultsRosette[I,K+6] := TKMImage.Create(Panel_BarsLower, 164 + K*BarStep, 38+I*BAR_ROW_HEIGHT, 16, 16, 8, rxGuiMain);
        end;
      end;

    Button_SwitchBars := TKMButtonFlat.Create(Panel_Bars, 0, 0, 140, 20, 0, rxGui);
    Button_SwitchBars.TexOffsetX := -72;
    Button_SwitchBars.TexOffsetY := 6;
    Button_SwitchBars.Anchors := [anLeft, anTop];
    Button_SwitchBars.Caption := '>>';
    Button_SwitchBars.CapOffsetY := -11;
    Button_SwitchBars.OnClick := SwitchBars_Click;
end;


procedure TKMGameResultsMP.CreateChartEconomy;
const
  RADIO_ECO_HEIGHT = 80;
begin
  Panel_ChartsEconomy := TKMPanel.Create(Panel_ResultsMP, RESULTS_X_PADDING, PANES_TOP, Panel_ResultsMP.Width - 2*RESULTS_X_PADDING, CHART_HEIGHT);
  Panel_ChartsEconomy.AnchorsStretch;
    Chart_Players_Citizens := TKMChart.Create(Panel_ChartsEconomy, 0, 0, Panel_ChartsEconomy.Width, CHART_HEIGHT);
    Chart_Players_Citizens.Caption := gResTexts[TX_GRAPH_CITIZENS];
    Chart_Players_Citizens.LegendCaption := gResTexts[TX_WORD_PLAYERS];
    Chart_Players_Citizens.LegendWidth := SUBMENU_RIGHT_WIDTH;
    Chart_Players_Citizens.AnchorsStretch;
    Chart_Players_Citizens.OnLegendClick := Chart_LegendClick;

    Chart_Teams_Citizens := TKMChart.Create(Panel_ChartsEconomy, 0, 0, Panel_ChartsEconomy.Width, CHART_HEIGHT);
    Chart_Teams_Citizens.Caption := gResTexts[TX_GRAPH_CITIZENS];
    Chart_Teams_Citizens.LegendCaption := gResTexts[TX_WORD_TEAMS];
    Chart_Teams_Citizens.LegendWidth := SUBMENU_RIGHT_WIDTH;
    Chart_Teams_Citizens.AnchorsStretch;
    Chart_Teams_Citizens.OnLegendClick := Chart_LegendClick;

    Chart_Players_Houses := TKMChart.Create(Panel_ChartsEconomy, 0, 0, Panel_ChartsEconomy.Width, CHART_HEIGHT);
    Chart_Players_Houses.Caption := gResTexts[TX_GRAPH_HOUSES];
    Chart_Players_Houses.LegendCaption := gResTexts[TX_WORD_PLAYERS];
    Chart_Players_Houses.LegendWidth := SUBMENU_RIGHT_WIDTH;
    Chart_Players_Houses.AnchorsStretch;
    Chart_Players_Houses.Hide;
    Chart_Players_Houses.OnLegendClick := Chart_LegendClick;

    Chart_Teams_Houses := TKMChart.Create(Panel_ChartsEconomy, 0, 0, Panel_ChartsEconomy.Width, CHART_HEIGHT);
    Chart_Teams_Houses.Caption := gResTexts[TX_GRAPH_HOUSES];
    Chart_Teams_Houses.LegendCaption := gResTexts[TX_WORD_TEAMS];
    Chart_Teams_Houses.LegendWidth := SUBMENU_RIGHT_WIDTH;
    Chart_Teams_Houses.AnchorsStretch;
    Chart_Teams_Houses.Hide;
    Chart_Teams_Houses.OnLegendClick := Chart_LegendClick;

    Label_NoEconomyData := TKMLabel.Create(Panel_ChartsEconomy, Panel_ResultsMP.Width div 2, CHART_HEIGHT div 2, gResTexts[TX_GRAPH_NO_DATA], fntMetal, taCenter);
    Label_NoEconomyData.AnchorsCenter;

    Panel_ChartEconomy_Type := TKMPanel.Create(Panel_ChartsEconomy, Panel_ChartsEconomy.Width - SUBMENU_RIGHT_WIDTH + 5,
                                               CHART_HEIGHT - RADIO_ECO_HEIGHT - 20, SUBMENU_RIGHT_WIDTH, RADIO_ECO_HEIGHT);
    Panel_ChartEconomy_Type.Anchors := [anLeft, anBottom];
      with TKMShape.Create(Panel_ChartEconomy_Type, 0, 0, SUBMENU_RIGHT_WIDTH, RADIO_ECO_HEIGHT) do
      begin
        Anchors := [anLeft, anBottom];
        FillColor := icDarkestGrayTrans;
        LineColor := icGray;
        LineWidth := 1;
      end;

      with TKMLabel.Create(Panel_ChartEconomy_Type, 5, 8, SUBMENU_RIGHT_WIDTH - 10, 20, gResTexts[TX_RESULTS_CHART_TYPE], fntMetal, taCenter) do
        Anchors := [anLeft, anBottom];

      Radio_ChartEconomyType := TKMRadioGroup.Create(Panel_ChartEconomy_Type,5,35,SUBMENU_RIGHT_WIDTH - 10,RADIO_ECO_HEIGHT - 40,fntGrey);
      Radio_ChartEconomyType.Anchors := [anLeft, anBottom];
      Radio_ChartEconomyType.DrawChkboxOutline := True;
      Radio_ChartEconomyType.ItemIndex := 0;
      Radio_ChartEconomyType.Add(gResTexts[TX_GRAPH_CITIZENS]);
      Radio_ChartEconomyType.Add(gResTexts[TX_GRAPH_HOUSES]);
      Radio_ChartEconomyType.OnChange := RadioEconomyTypeChange;
end;


procedure TKMGameResultsMP.RadioEconomyTypeChange(Sender: TObject);
begin
  EconomyUpdate(nil);
end;


procedure TKMGameResultsMP.CreateChartWares(aParent: TKMPanel);

  procedure SetupWareColumnBox(aColumnBox: TKMColumnBox);
  begin
    aColumnBox.Anchors := [anLeft, anTop, anBottom];
    aColumnBox.SetColumns(fntGame, ['', ''], [0, 20]);
    aColumnBox.ShowHeader := False;
    aColumnBox.ShowLines := False;
    aColumnBox.OnChange := WareUpdate;
  end;

  procedure SetupWareChart(aChart: TKMChart; aStatType: TKMStatType);
  begin
    aChart.AnchorsStretch;
    aChart.Caption := gResTexts[TX_GRAPH_TITLE_RESOURCES];
    aChart.LegendCaption := GetChartLegendCaption(aStatType);
    aChart.LegendWidth := SUBMENU_RIGHT_WIDTH;
    aChart.OnLegendClick := Chart_LegendClick;
    aChart.Font := fntMetal; //fntOutline doesn't work because player names blend badly with yellow
    aChart.Hide;
  end;

const
  WARES_TYPE_HEIGHT = 80;
var
  I: Integer;
  W: TKMWareType;
  ST: TKMStatType;
begin
  Panel_ChartsWares := TKMPanel.Create(aParent, RESULTS_X_PADDING, PANES_TOP, aParent.Width - 2*RESULTS_X_PADDING, CHART_HEIGHT);
  Panel_ChartsWares.AnchorsStretch;

    Columnbox_Wares := TKMColumnBox.Create(Panel_ChartsWares, 0, 0, 145, CHART_HEIGHT, fntGame, bsMenu);
    Columnbox_WaresGDP := TKMColumnBox.Create(Panel_ChartsWares, 0, 0, 145, CHART_HEIGHT, fntGame, bsMenu);
    SetupWareColumnBox(Columnbox_Wares);
    SetupWareColumnBox(Columnbox_WaresGDP);

    for ST := Low(TKMStatType) to High(TKMStatType) do
    begin
      for W := Low(TKMWareType) to High(TKMWareType) do
      begin
        Charts_Wares[ST,W] := TKMChart.Create(Panel_ChartsWares, 140, 0, Panel_ChartsWares.Width - 140, CHART_HEIGHT);
        SetupWareChart(Charts_Wares[ST,W], ST);
      end;

      for I := Low(GDPWares) to High(GDPWares) do
      begin
        Charts_WaresGDP[ST,I] := TKMChart.Create(Panel_ChartsWares, 140, 0, Panel_ChartsWares.Width - 140, CHART_HEIGHT);
        SetupWareChart(Charts_WaresGDP[ST,I], ST);
      end;
    end;

    Label_NoWareData := TKMLabel.Create(Panel_ChartsWares, Panel_ChartsWares.Width div 2, CHART_HEIGHT div 2, gResTexts[TX_GRAPH_NO_DATA], fntMetal, taCenter);
    Label_NoWareData.AnchorsCenter;

    Panel_ChartWare_Type := TKMPanel.Create(Panel_ChartsWares, Panel_ChartsWares.Width - SUBMENU_RIGHT_WIDTH + 5,
                                            CHART_HEIGHT - WARES_TYPE_HEIGHT - 20, SUBMENU_RIGHT_WIDTH, WARES_TYPE_HEIGHT);
    Panel_ChartWare_Type.Anchors := [anLeft, anBottom];
      with TKMShape.Create(Panel_ChartWare_Type, 0, 0, SUBMENU_RIGHT_WIDTH, WARES_TYPE_HEIGHT) do
      begin
        Anchors := [anLeft, anBottom];
        FillColor := icDarkestGrayTrans;
        LineColor := icGray;
        LineWidth := 1;
      end;

      with TKMLabel.Create(Panel_ChartWare_Type, 5, 8, SUBMENU_RIGHT_WIDTH - 10, 20, gResTexts[TX_RESULTS_CHART_TYPE], fntMetal, taCenter) do
        Anchors := [anLeft, anBottom];

      Radio_ChartWareType := TKMRadioGroup.Create(Panel_ChartWare_Type,5,35,SUBMENU_RIGHT_WIDTH - 10,WARES_TYPE_HEIGHT - 40,fntGrey);
      Radio_ChartWareType.Anchors := [anLeft, anBottom];
      Radio_ChartWareType.DrawChkboxOutline := True;
      Radio_ChartWareType.ItemIndex := 0;
      Radio_ChartWareType.Add(gResTexts[TX_RESULTS_WARES_QUANTITY]);
      Radio_ChartWareType.Add(gResTexts[TX_RESULTS_WARES_GDP]);
      Radio_ChartWareType.OnChange := RadioWareTypeChange;
end;


procedure TKMGameResultsMP.RadioWareTypeChange(Sender: TObject);
begin
  WareUpdate(Radio_ChartWareType);
end;


procedure TKMGameResultsMP.CreateChartArmy(aParent: TKMPanel);
const
  ARMY_TYPE_HEIGHT = 120;
var
  wType: TKMChartWarriorType;
  cKind: TKMChartArmyKind;
  ST: TKMStatType;
begin
  Panel_ChartsArmy := TKMPanel.Create(aParent, RESULTS_X_PADDING, PANES_TOP, aParent.Width - 2*RESULTS_X_PADDING, CHART_HEIGHT);
  Panel_ChartsArmy.AnchorsStretch;

    Columnbox_Army := TKMColumnBox.Create(Panel_ChartsArmy, 0, 0, 145, CHART_HEIGHT, fntGame, bsMenu);
    Columnbox_Army.Anchors := [anLeft, anTop, anBottom];
    Columnbox_Army.SetColumns(fntGame, ['', ''], [0, 33]);
    Columnbox_Army.ShowHeader := False;
    Columnbox_Army.ShowLines := False;
    Columnbox_Army.OnChange := ArmyUpdate;
    // 33 is a bit more then unit icons max height
    Columnbox_Army.ItemHeight := Min(Columnbox_Army.Height div 13, 33);

    for ST := Low(TKMStatType) to High(TKMStatType) do
      for cKind := Low(TKMChartArmyKind) to High(TKMChartArmyKind) do
        for wType := Low(TKMChartWarriorType) to High(TKMChartWarriorType) do
        begin
          Charts_Army[ST,cKind,wType] := TKMChartArmyMP.Create(wType, cKind, Panel_ChartsArmy, 140, 0, Panel_ChartsArmy.Width - 140, CHART_HEIGHT);
          Charts_Army[ST,cKind,wType].Chart.AnchorsStretch;
          Charts_Army[ST,cKind,wType].Chart.Caption := gResTexts[TX_GRAPH_ARMY];
          Charts_Army[ST,cKind,wType].Chart.LegendCaption := GetChartLegendCaption(ST);
          Charts_Army[ST,cKind,wType].Chart.LegendWidth := SUBMENU_RIGHT_WIDTH;
          Charts_Army[ST,cKind,wType].Chart.OnLegendClick := Chart_LegendClick;
          Charts_Army[ST,cKind,wType].Chart.Font := fntMetal; //fntOutline doesn't work because player names blend badly with yellow
          Charts_Army[ST,cKind,wType].Chart.Hide;
        end;

    Label_NoArmyData := TKMLabel.Create(Panel_ChartsArmy, Panel_ChartsArmy.Width div 2, CHART_HEIGHT div 2, gResTexts[TX_GRAPH_NO_DATA], fntMetal, taCenter);
    Label_NoArmyData.AnchorsCenter;

    Panel_ChartArmy_Type := TKMPanel.Create(Panel_ChartsArmy, Panel_ChartsArmy.Width - SUBMENU_RIGHT_WIDTH + 5,
                                            CHART_HEIGHT - ARMY_TYPE_HEIGHT - 20, SUBMENU_RIGHT_WIDTH, ARMY_TYPE_HEIGHT);
    Panel_ChartArmy_Type.Anchors := [anLeft, anBottom];
      with TKMShape.Create(Panel_ChartArmy_Type, 0, 0, SUBMENU_RIGHT_WIDTH, ARMY_TYPE_HEIGHT) do
      begin
        Anchors := [anLeft, anBottom];
        FillColor := icDarkestGrayTrans;
        LineColor := icGray;
        LineWidth := 1;
      end;

      with TKMLabel.Create(Panel_ChartArmy_Type, 5, 8, SUBMENU_RIGHT_WIDTH - 10, 20, gResTexts[TX_RESULTS_CHART_TYPE], fntMetal, taCenter) do
        Anchors := [anLeft, anBottom];

      Radio_ChartArmyType := TKMRadioGroup.Create(Panel_ChartArmy_Type,5,35,SUBMENU_RIGHT_WIDTH - 10,ARMY_TYPE_HEIGHT - 40,fntGrey);
      Radio_ChartArmyType.Anchors := [anLeft, anBottom];
      Radio_ChartArmyType.DrawChkboxOutline := True;
      Radio_ChartArmyType.ItemIndex := 0;
      Radio_ChartArmyType.Add(gResTexts[TX_RESULTS_ARMY_INSTANTANEOUS]);
      Radio_ChartArmyType.Add(gResTexts[TX_RESULTS_ARMY_TOTAL_EQUIPPED]);
      Radio_ChartArmyType.Add(gResTexts[TX_RESULTS_ARMY_DEFEATED]);
      Radio_ChartArmyType.Add(gResTexts[TX_RESULTS_ARMY_LOST]);
      Radio_ChartArmyType.OnChange := RadioArmyTypeChange;
end;


procedure TKMGameResultsMP.RadioArmyTypeChange(Sender: TObject);
begin
  ArmyUpdate(nil);
end;


procedure TKMGameResultsMP.StatTypeChange(Sender: TObject);
begin
  if Sender = Button_Players then
    fStatType := stByPlayers;

  if Sender = Button_Teams then
    fStatType := stByTeams;

  Button_Players.Down := fStatType = stByPlayers;
  Button_Teams.Down   := fStatType = stByTeams;

  UpdateVisibleTab;
end;


procedure TKMGameResultsMP.SwitchBars_Click(Sender: TObject);
begin
  if Button_SwitchBars.Caption = '>>' then
    Button_SwitchBars.Caption := '<<'
  else
    Button_SwitchBars.Caption := '>>';

  Panel_BarsUpper.Visible := not Panel_BarsUpper.Visible;
  Panel_BarsLower.Visible := not Panel_BarsLower.Visible;
end;


function TKMGameResultsMP.GetChartLegendDetailedTitles(aStatType: TKMStatType; aLineI: Integer): TKMStringArray;
var
  I: Integer;
begin
  case aStatType of
    stByPlayers: SetLength(Result, 0);
    stByTeams:   begin
                    SetLength(Result, fTeamMembersCounts[aLineI]);
                    for I := 0 to fTeamMembersCounts[aLineI] - 1 do
                      Result[I] := fTeamMembersNames[aLineI, I];
                  end;
  end;
end;


function TKMGameResultsMP.GetChartLegendDetailedColors(aStatType: TKMStatType; aLineI: Integer): TKMCardinalArray;
var
  I: Integer;
begin
  case aStatType of
    stByPlayers: SetLength(Result, 0);
    stByTeams:   begin
                    SetLength(Result, fTeamMembersCounts[aLineI]);
                    for I := 0 to fTeamMembersCounts[aLineI] - 1 do
                      Result[I] := fTeamMembersColors[aLineI, I];
                  end;
  end;
end;


procedure TKMGameResultsMP.UpdateVisibleTab;
begin
  if Panel_Bars.Visible then
    BarsUpdate(fStatType);
  if Panel_ChartsEconomy.Visible then
    EconomyUpdate(nil);
  if Panel_ChartsWares.Visible then
    WareUpdate(nil);
  if Panel_ChartsArmy.Visible then
    ArmyUpdate(nil);
end;


procedure TKMGameResultsMP.Resize(Sender: TObject; const aValue: Integer);
begin
  BarsUpdatePos;
end;


procedure TKMGameResultsMP.TabChange(Sender: TObject);
begin
  Button_Bars.Down := Sender = Button_Bars;
  Button_Army.Down := Sender = Button_Army;
  Button_Economy.Down := Sender = Button_Economy;
  Button_Wares.Down := Sender = Button_Wares;

  Panel_Bars.Visible          := Sender = Button_Bars;
  Panel_ChartsEconomy.Visible := Sender = Button_Economy;
  Panel_ChartsWares.Visible   := Sender = Button_Wares;
  Panel_ChartsArmy.Visible    := Sender = Button_Army;

  StatTypeChange(nil);
end;


procedure TKMGameResultsMP.BarsUpdatePos;
begin
  if fListToShow[stByPlayers] <> nil then
  begin
    //Update positioning
    Panel_BarsUpper.Height := 40 + fListToShow[stByPlayers].Count * BAR_ROW_HEIGHT;
    Panel_BarsLower.Height := 40 + fListToShow[stByPlayers].Count * BAR_ROW_HEIGHT;
    Panel_Bars.Height := Panel_Bars.Parent.Height - PANES_TOP - BACK_BTN_Y_TO_BOTTOM;

    if Panel_Bars.Height < Panel_BarsUpper.Height + Panel_BarsLower.Height + 10 then
    begin
      if Panel_BarsUpper.Visible and Panel_BarsLower.Visible then
      begin
        Panel_BarsLower.Hide;
        Button_SwitchBars.DoSetVisible;
        Button_SwitchBars.Caption := '>>';
        Panel_BarsUpper.Top := 0;
        Panel_BarsLower.Top := 0;
        Panel_BarsLower.Anchors := [anTop];
      end;
    end else begin
      Panel_BarsUpper.DoSetVisible;
      Panel_BarsLower.DoSetVisible;
      Panel_BarsLower.Anchors := [anBottom];
      Button_SwitchBars.Hide;

      //Second panel does not move from the middle of the screen: results always go above and below the middle
      Panel_BarsUpper.Top := Panel_Bars.Height div 2 - Panel_BarsUpper.Height - 5;
      Panel_BarsLower.Top := Panel_Bars.Height div 2 + 5;
    end;
  end;
end;


procedure TKMGameResultsMP.BarsUpdate(aStatType: TKMStatType);
const
  STATS_LOWER_IS_BETTER: set of Byte = [1,2,4,7];
  STATS_SKIP_BEST: set of Byte = [1];

  procedure SetPlayerControls(aPlayer: Integer; aEnabled: Boolean);
  var
    I: Integer;
  begin
    Label_ResultsPlayerName1[aPlayer].Visible := aEnabled;
    Label_ResultsPlayerName2[aPlayer].Visible := aEnabled;

    for I := 0 to STAT_CATEGORY_CNT do
    begin
      Bar_Results[aPlayer,I].Visible := aEnabled;
      Image_ResultsRosette[aPlayer,I].Visible := aEnabled;
    end;
  end;

var
  I,J,K: Integer;
  unitsMax, housesMax, waresMax, weaponsMax, maxValue: Integer;
  bests: array [0..STAT_CATEGORY_CNT] of Cardinal;
  totals: array [0..STAT_CATEGORY_CNT] of Cardinal;
  statValue: Cardinal;
  listToShow: TStringList;
  statsValues: TKMStatsValues;
begin
  listToShow := fListToShow[aStatType];
  statsValues := fStatsValues[aStatType];

  //Update visibility depending on players count (note, players may be sparsed)
  for I := 0 to MAX_HANDS - 1 do
    SetPlayerControls(I, False); //Disable them all to start

  for I := 0 to listToShow.Count - 1 do
  begin
    SetPlayerControls(I, True); //Enable used ones

    Label_ResultsPlayerName1[I].Caption   := fNamesToShow[fStatType, I];
    Label_ResultsPlayerName1[I].FontColor := FlagColorToTextColor(fColorsToShow[fStatType, I]);
    Label_ResultsPlayerName2[I].Caption   := Label_ResultsPlayerName1[I].Caption;
    Label_ResultsPlayerName2[I].FontColor := Label_ResultsPlayerName1[I].FontColor;
  end;

  BarsUpdatePos;

  //Calculate best scores
  FillChar(bests, SizeOf(bests), #0);
  //These are a special case: Less is better so we initialize them high
  bests[1] := High(Cardinal);
  bests[2] := High(Cardinal);
  bests[4] := High(Cardinal);
  bests[7] := High(Cardinal);
  FillChar(totals, SizeOf(totals), #0);

  //Calculate bests for each "section"
  for I := 0 to listToShow.Count - 1 do
  begin
    K := StrToInt(TStringList(listToShow.Objects[I])[0]);
    for J := 0 to STAT_CATEGORY_CNT do
    begin
      statValue := statsValues[K,J];
      if J in STATS_LOWER_IS_BETTER then
      begin
        if bests[J] > statValue then bests[J] := statValue;
      end else
        if bests[J] < statValue then bests[J] := statValue;

      Inc(totals[J], statValue);
    end;
  end;

  //Fill in raw values
  for I := 0 to listToShow.Count - 1 do
  begin
    K := StrToInt(TStringList(listToShow.Objects[I])[0]);
    for J := 0 to STAT_CATEGORY_CNT do
    begin
      statValue := statsValues[K,J];
      Bar_Results[I,J].Tag := statValue;
      if J in STATS_LOWER_IS_BETTER then
      begin
        Image_ResultsRosette[I,J].Visible := not (J in STATS_SKIP_BEST) and (listToShow.Count > 1) and (statValue <= bests[J]) and (totals[J] > 0);
      end else
        Image_ResultsRosette[I,J].Visible := not (J in STATS_SKIP_BEST) and (listToShow.Count > 1) and (statValue >= bests[J]) and (totals[J] > 0);
    end;
  end;

  //Update percent bars for each category
  unitsMax := 0;
  for K := 0 to 5 do for I := 0 to listToShow.Count - 1 do
    unitsMax := Max(Bar_Results[I,K].Tag, unitsMax);

  housesMax := 0;
  for K := 6 to 8 do for I := 0 to listToShow.Count - 1 do
    housesMax := Max(Bar_Results[I,K].Tag, housesMax);

  waresMax := 0;
  for I := 0 to listToShow.Count - 1 do
    waresMax := Max(Bar_Results[I,9].Tag, waresMax);

  weaponsMax := 0;
  for I := 0 to listToShow.Count - 1 do
    weaponsMax := Max(Bar_Results[I,10].Tag, weaponsMax);

  //Knowing Max in each category we may fill bars properly
  for K := 0 to STAT_CATEGORY_CNT do
  begin
    case K of
      0..5: maxValue := unitsMax;
      6..8: maxValue := housesMax;
      9:    maxValue := waresMax;
      else  maxValue := weaponsMax;
    end;
    for I := 0 to listToShow.Count - 1 do
    begin
      if maxValue <> 0 then
        Bar_Results[I,K].Position := Bar_Results[I,K].Tag / maxValue
      else
        Bar_Results[I,K].Position := 0;
      Bar_Results[I,K].Caption := IfThen(Bar_Results[I,K].Tag <> 0, IntToStr(Bar_Results[I,K].Tag), '-');
    end;
  end;
end;


procedure TKMGameResultsMP.EconomyUpdate(Sender: TObject);
var
  I: Integer;
begin
  //Hide everything first
  Chart_Players_Houses.Hide;
  Chart_Players_Citizens.Hide;
  Chart_Teams_Houses.Hide;
  Chart_Teams_Citizens.Hide;

  if fNoEconomyChartData then
  begin
    Label_NoEconomyData.DoSetVisible;
    Panel_ChartEconomy_Type.Hide;
    Exit;
  end;

  Label_NoEconomyData.Hide;
  Panel_ChartEconomy_Type.DoSetVisible;

  //Restore previously visible lines
  if fStatType = stByPlayers then
    for I := 0 to Chart_Players_Citizens.LineCount - 1 do
    begin
      Chart_Players_Citizens.SetLineVisible(I, fLegendLinesVisible[fStatType, Chart_Players_Citizens.Lines[I].Tag]);
      Chart_Players_Houses.SetLineVisible(I, fLegendLinesVisible[fStatType, Chart_Players_Houses.Lines[I].Tag]);
    end
  else
    for I := 0 to Chart_Teams_Citizens.LineCount - 1 do
    begin
      Chart_Teams_Citizens.SetLineVisible(I, fLegendLinesVisible[fStatType, Chart_Teams_Citizens.Lines[I].Tag]);
      Chart_Teams_Houses.SetLineVisible(I, fLegendLinesVisible[fStatType, Chart_Teams_Houses.Lines[I].Tag]);
    end;

  //Then show what is needed
  case Radio_ChartEconomyType.ItemIndex of
    0:  if fStatType = stByPlayers then
          Chart_Players_Citizens.DoSetVisible
        else
          Chart_Teams_Citizens.DoSetVisible;
    1:  if fStatType = stByPlayers then
          Chart_Players_Houses.DoSetVisible
        else
          Chart_Teams_Houses.DoSetVisible;
  end;
end;


procedure TKMGameResultsMP.WareUpdate(Sender: TObject);

  procedure ChangeWareChart(aChart: TKMChart; aUseGDP: Boolean);
  var
    W: TKMWareType;
    I: Integer;
    ST: TKMStatType;
  begin
    for ST := Low(TKMStatType) to High(TKMStatType) do
    begin
      //Find and hide old chart
      for I := Low(GDPWares) to High(GDPWares) do
        Charts_WaresGDP[ST,I].Visible := False;

      for W := Low(TKMWareType) to High(TKMWareType) do
        Charts_Wares[ST,W].Visible := False;
    end;

    aChart.Visible := True;

    //Restore previously visible lines
    for I := 0 to aChart.LineCount - 1 do
      aChart.SetLineVisible(I, fLegendLinesVisible[fStatType, aChart.Lines[I].Tag]);
  end;

var
  K, WareInGdpI: Integer;
  W: TKMWareType;
  ST: TKMStatType;
begin
  //Hide everything if no selection in columnbox
  if not Columnbox_Wares.IsSelected
    or not Columnbox_WaresGDP.IsSelected then
  begin
    Label_NoWareData.DoSetVisible;
    Columnbox_Wares.Hide;
    Columnbox_WaresGDP.Hide;
    Panel_ChartWare_Type.Hide;
    for ST := Low(TKMStatType) to High(TKMStatType) do
    begin
      for W := Low(TKMWareType) to High(TKMWareType) do
        Charts_Wares[ST,W].Hide;
      for K := Low(GDPWares) to High(GDPWares) do
        Charts_WaresGDP[ST,K].Hide;
    end;
    Exit;
  end;

  Label_NoWareData.Hide;
  Panel_ChartWare_Type.DoSetVisible;

  case Radio_ChartWareType.ItemIndex of
    0:  begin // Quantity chart
          if (Sender = Radio_ChartWareType) then
          begin
            if Columnbox_WaresGDP.IsSelected then
            begin
              if Columnbox_Wares.IsSelected then
              begin
                W := TKMWareType(Columnbox_Wares.Rows[Columnbox_Wares.ItemIndex].Tag);
                WareInGdpI := GetWareIdInGDPArr(W);
                //Update to AllWares/Food/Warfare only if we didn't choose some special ware
                if InRange(WareInGdpI, 0, 2) then
                  Columnbox_Wares.ItemIndex := Columnbox_WaresGDP.ItemIndex;
              end
              else
                Columnbox_Wares.ItemIndex := Columnbox_WaresGDP.ItemIndex;
            end;
          end;

          W := TKMWareType(Columnbox_Wares.Rows[Columnbox_Wares.ItemIndex].Tag);
          ChangeWareChart(Charts_Wares[fStatType, W], False);

          Columnbox_WaresGDP.Hide;
          Columnbox_Wares.DoSetVisible;
        end;
    1:  begin // GDP chart
          if (Sender = Radio_ChartWareType) then
          begin
            W := TKMWareType(Columnbox_Wares.Rows[Columnbox_Wares.ItemIndex].Tag);
            WareInGdpI := GetWareIdInGDPArr(W);
            if Columnbox_Wares.IsSelected and InRange(WareInGdpI, 0, 2) then
              Columnbox_WaresGDP.ItemIndex := Columnbox_Wares.ItemIndex;
          end;

          ChangeWareChart(Charts_WaresGDP[fStatType, Columnbox_WaresGDP.ItemIndex], True);

          Columnbox_Wares.Hide;
          Columnbox_WaresGDP.DoSetVisible;
        end;
  end;
end;


function TKMGameResultsMP.GetSelectedChartArmyKind: TKMChartArmyKind;
begin
  Result := TKMChartArmyKind(Radio_ChartArmyType.ItemIndex);
end;


procedure TKMGameResultsMP.ArmyUpdate(Sender: TObject);
var
  K: Integer;
  selectedWType, wType: TKMChartWarriorType;
  selectedCKind, cKind: TKMChartArmyKind;
  ST: TKMStatType;
  chart: TKMChart;
  selectedItemTag: Integer;
begin
  //Hide everything if there is no data
  if fNoArmyChartData then
  begin
    Label_NoArmyData.DoSetVisible;
    Columnbox_Army.Hide;
    Panel_ChartArmy_Type.Hide;
    for ST := Low(TKMStatType) to High(TKMStatType) do
      for cKind := Low(TKMChartArmyKind) to High(TKMChartArmyKind) do
        for wType := Low(TKMChartWarriorType) to High(TKMChartWarriorType) do
          Charts_Army[ST,cKind,wType].Chart.Hide;
    Exit;
  end;

  selectedItemTag := -1;
  if Columnbox_Army.IsSelected then
    selectedItemTag := Columnbox_Army.SelectedItem.Tag;

  selectedCKind := GetSelectedChartArmyKind;

  //Fill columnbox for selected CKind
  Columnbox_Army.Clear;
  for K := 0 to High(fColumnBoxArmy_Rows[selectedCKind]) do
  begin
    wType := fColumnBoxArmy_Rows[selectedCKind,K];
    Columnbox_Army.AddItem(MakeListRow(['', Charts_Army[fStatType,selectedCKind,wType].ChartType.GUIName],   //Does not matter what chart to use - they all have same GUIName and GUIIcon
                                        [gMySpectator.Hand.FlagColor, $FFFFFFFF],
                                        [MakePic(rxGui, Charts_Army[fStatType,selectedCKind,wType].ChartType.GUIIcon), MakePic(rxGui, 0)],
                                        Byte(wType)));
    if selectedItemTag = Byte(wType) then
      Columnbox_Army.ItemIndex := Columnbox_Army.RowCount - 1;
  end;

  if not Columnbox_Army.IsSelected then
    Columnbox_Army.ItemIndex := 0;  //Select 1st elem in column box, there should be always ArmyPower

  //Show columnbox and chart panel
  Label_NoArmyData.Hide;
  Columnbox_Army.DoSetVisible;
  Panel_ChartArmy_Type.DoSetVisible;

  //Find and hide old chart
  for ST := Low(TKMStatType) to High(TKMStatType) do
    for cKind := Low(TKMChartArmyKind) to High(TKMChartArmyKind) do
      for wType := Low(TKMChartWarriorType) to High(TKMChartWarriorType) do
        Charts_Army[ST,cKind,wType].Chart.Visible := False;

  selectedWType := TKMChartWarriorType(Columnbox_Army.Rows[Columnbox_Army.ItemIndex].Tag);

  chart := Charts_Army[fStatType,selectedCKind,selectedWType].Chart;
  chart.Visible := True;
  //Restore previously visible lines
  for K := 0 to chart.LineCount - 1 do
    chart.SetLineVisible(K, fLegendLinesVisible[fStatType, chart.Lines[K].Tag]);
end;


procedure TKMGameResultsMP.Chart_LegendClick(Sender: TObject; aLineIndex: Integer; aLineVisible: Boolean);
var
  chart: TKMChart;
begin
  Assert(Sender is TKMChart);

  chart := TKMChart(Sender);
  fLegendLinesVisible[fStatType, chart.Lines[aLineIndex].Tag] := aLineVisible;
end;


function TKMGameResultsMP.DoShowHandStats(aHandId: Integer): Boolean;
begin
  Result := gHands[aHandId].Enabled
    and (fShowAIResults or gHands[aHandId].IsHuman)
    and (
      (fGameResultMsg <> grGameContinues)
      or SHOW_ENEMIES_STATS
      or gGameParams.IsReplayOrSpectate
      or (gHands[aHandId].Alliances[gMySpectator.HandID] = atAlly)
      or gMySpectator.Hand.AI.HasWon);
end;


procedure TKMGameResultsMP.FreeListToShow(aStatType: TKMStatType);
begin
  //Free objects inside (there could be TStringList's)
  if fListToShow[aStatType] <> nil then
    fListToShow[aStatType].Clear;
  //Free list itself
  FreeAndNil(fListToShow[aStatType]);
end;


procedure TKMGameResultsMP.RecreateListToShow(aStatType: TKMStatType);
begin
  FreeListToShow(aStatType);

  fListToShow[aStatType] := TStringList.Create;
  fListToShow[aStatType].Sorted := False;     //Need to append players to show at the end of list
  fListToShow[aStatType].OwnsObjects := True; //Contains other TStringList'
end;


function TKMGameResultsMP.DoAdjoinSameColorHand(aHandId: Integer): Boolean;
begin
  Result := gHands[aHandId].IsComputer and gGameParams.IsSingleplayer; //Adjoin only AI's in SP games
end;


procedure TKMGameResultsMP.ReinitPlayersToShow;
var
  handsUniqueColorsCnt: Integer;
  handsUniqueColors: array[0..MAX_HANDS-1] of record
                                                HandId: Integer;
                                                Color: Cardinal;
                                              end;

  procedure AddOrFindHandColor(aHandId: Integer; aColor: Cardinal; var aOldI: Integer);
  var
    I: Integer;
  begin
    aOldI := -1;
    for I := 0 to handsUniqueColorsCnt - 1 do
      if handsUniqueColors[I].Color = aColor then
      begin
        aOldI := handsUniqueColors[I].HandId;
        Exit;
      end;
    handsUniqueColors[handsUniqueColorsCnt].Color := aColor;
    handsUniqueColors[handsUniqueColorsCnt].HandId := aHandId;
    Inc(handsUniqueColorsCnt);
  end;

  procedure TryAddHand(aHandId: TKMHandID);

    procedure AddNewHand;
    var
      playersIdList: TStringList;
    begin
      playersIdList := TStringList.Create;
      playersIdList.Add(IntToStr(aHandId));
      fListToShow[stByPlayers].AddObject(IntToStr(aHandId), playersIdList);
      fNamesToShow[stByPlayers, fListToShow[stByPlayers].Count - 1] := GetOwnerName(aHandId);
      fColorsToShow[stByPlayers, fListToShow[stByPlayers].Count - 1] := gHands[aHandId].FlagColor;
    end;

    procedure AddOldHand(aOldI: Integer);
    var
      listI: Integer;
    begin
      listI := fListToShow[stByPlayers].IndexOf(IntToStr(aOldI));
      if listI > -1 then //should be always True
        TStringList(fListToShow[stByPlayers].Objects[listI]).Add(IntToStr(aHandId)); //Add same color player to list
    end;

  var
    oldI: Integer;
  begin
    if DoShowHandStats(aHandId) then
    begin
      if DoAdjoinSameColorHand(aHandId) then // For SP game we have to adjoin same color hands
      begin
        AddOrFindHandColor(aHandId, gHands[aHandId].FlagColor, oldI); //Same colored players are adjoined into 1
        if oldI = -1 then
          AddNewHand
        else
          AddOldHand(oldI);
      end else
        AddNewHand;
    end;
  end;

var
  I, J, playersCntBeforeAdd: Integer;
  teams: TKMByteSetArray;
  nonTeamHands: set of Byte;
begin
  teams := gHands.GetTeamsOfAllies;
  nonTeamHands := [0..gHands.Count - 1];

  //Get non team hands
  for I := Low(teams) to High(teams) do
    nonTeamHands := nonTeamHands - teams[I];

  RecreateListToShow(stByPlayers);
  handsUniqueColorsCnt := 0;

  for I in nonTeamHands do
    TryAddHand(I);

  fChartSeparatorsPos[stByPlayers].Clear;
  for I := Low(teams) to High(teams) do
  begin
    playersCntBeforeAdd := fListToShow[stByPlayers].Count;
    for J in teams[I] do
      TryAddHand(J);
    // Add separator position
    if (playersCntBeforeAdd > 0)                            // Do not add separator at first pos
      and (playersCntBeforeAdd < fListToShow[stByPlayers].Count) then // Do not separator if team is 'empty'
      fChartSeparatorsPos[stByPlayers].Add(IntToStr(playersCntBeforeAdd));
  end;
end;


procedure TKMGameResultsMP.ReinitTeamsToShow;

  procedure AddToNewTeam(aFirstHandId: Integer; aPlayersList: TStringList);
  var
    playersList: TStringList;
    cnt: Integer;
  begin
    playersList := TStringList.Create;
    playersList.AddStrings(aPlayersList);
    fListToShow[stByTeams].AddObject(IntToStr(aFirstHandId), playersList);
    cnt := fListToShow[stByTeams].Count - 1;
    fNamesToShow[stByTeams, cnt] := gResTexts[TX_LOBBY_HEADER_TEAM] + ' ' + IntToStr(fListToShow[stByTeams].Count);
    fColorsToShow[stByTeams, cnt] := gHands[aFirstHandId].TeamColor;

    fTeamMembersNames[cnt][0] := GetOwnerName(aFirstHandId);
    fTeamMembersColors[cnt][0] := gHands[aFirstHandId].FlagColor;
    fTeamMembersCounts[cnt] := 1;
  end;

  procedure AddToTeam(aHandId, aTeamI: Integer; aPlayersList: TStringList);
  var
    playersList: TStringList;
    cnt: Integer;
  begin
    playersList := TStringList(fListToShow[stByTeams].Objects[aTeamI]);
    playersList.AddStrings(aPlayersList);
    cnt := fListToShow[stByTeams].Count - 1;

    fTeamMembersNames[cnt][fTeamMembersCounts[cnt]] := GetOwnerName(aHandId);
    fTeamMembersColors[cnt][fTeamMembersCounts[cnt]] := gHands[aHandId].FlagColor;
    Inc(fTeamMembersCounts[cnt]);
  end;

var
  I, J, handId, teamI: Integer;
  playersList: TStringList;
  teams: TKMByteSetArray;
  teamIsNew, doShowTeam: Boolean;
begin
  RecreateListToShow(stByTeams);
  fChartSeparatorsPos[stByTeams].Clear;
  teams := gHands.Teams;
  teamI := 0;

  for J := Low(teams) to High(teams) do
  begin
    teamIsNew := True;
    doShowTeam := False;
    for I := 0 to fListToShow[stByPlayers].Count - 1 do
    begin
      playersList := TStringList(fListToShow[stByPlayers].Objects[I]);
      handId := StrToInt(playersList[0]);

      if handId in teams[J] then
      begin
        doShowTeam := True; //Team could be hidden in case we show stats during the game
        if teamIsNew then
        begin
          teamIsNew := False;
          AddToNewTeam(handId, playersList);
        end else
          AddToTeam(handId, teamI, playersList);
      end;
    end;

    if not teamIsNew then //check if there was empty teams
      Inc(teamI);

    if doShowTeam and (J <> Low(teams)) then
      fChartSeparatorsPos[stByTeams].Add(IntToStr(J));
  end;

  //Remove detailed chart legend, if we have only 1 player in the team
  for I := 0 to fListToShow[stByTeams].Count - 1 do
  begin
    if fTeamMembersCounts[I] = 1 then
    begin
      fTeamMembersCounts[I] := 0;
      fNamesToShow[stByTeams, I] := fTeamMembersNames[I, 0];
    end;
  end;

  if fListToShow[stByTeams].Count <= 1 then
    fChartSeparatorsPos[stByTeams].Clear; //In case we have only 1 team to show (f.e. when stats are shown during the game)
end;


procedure TKMGameResultsMP.Reinit;
var
  resultsLabelCap: UnicodeString;
begin
  //MP Stats can be shown from SP stats page. We have to hide AI players then, depending on game result
  fShowAIResults := not gGameParams.IsSingleplayerGame
                    or (fGameResultMsg in [grWin, grReplayEnd])
                    or ((fGameResultMsg = grGameContinues) and gMySpectator.Hand.AI.HasWon);

  // When exit mission update stats to build actual charts
  // without CHARTS_SAMPLING_FOR_TACTICS or CHARTS_SAMPLING_FOR_ECONOMY delays
  // so measurements for warriors/goods produces will not differ from charts
//  for I := 0 to gHands.Count - 1 do
//    if DoShowHandStats(I) then
//      gHands[I].Stats.UpdateState;

  case fGameResultMsg of
    grWin:           resultsLabelCap := gResTexts[TX_MENU_MISSION_VICTORY];
    grDefeat:        resultsLabelCap := gResTexts[TX_MENU_MISSION_DEFEAT];
    grCancel:        resultsLabelCap := gResTexts[TX_MENU_MISSION_CANCELED];
    grReplayEnd:     resultsLabelCap := gResTexts[TX_MENU_REPLAY_ENDED];
    grGameContinues: resultsLabelCap := '';
    else              resultsLabelCap := NO_TEXT;
  end;

  //Append mission name and time after the result message
  Label_ResultsMP.Caption := resultsLabelCap;
  if resultsLabelCap <> '' then
    Label_ResultsMP.Caption := Label_ResultsMP.Caption + ' - ';

  Label_ResultsMP.Caption := Label_ResultsMP.Caption + gGameParams.Name;

  //Append difficulty level to game results caption
  if gGameParams.MissionDifficulty <> mdNone then
    Label_ResultsMP.Caption := Label_ResultsMP.Caption + ' (' + gResTexts[DIFFICULTY_LEVELS_TX[gGameParams.MissionDifficulty]] + ')';

  //Append mission time
  Label_ResultsMP.Caption := Label_ResultsMP.Caption + ' - ' + TimeToString(gGame.MissionTime);

  ReinitPlayersToShow;
  ReinitTeamsToShow; //Should be done after ReinitPlayersToShow
  ReinitBars;
  ReinitChartEconomy;
  ReinitChartWares;
  ReinitChartArmy;

  Button_Wares.Enabled := gGameParams.IsNormalMission;
  Button_Economy.Enabled := gGameParams.IsNormalMission;

  if fGameResultMsg = grGameContinues then
  begin
    Button_BackToGame.DoSetVisible;
    case gGameParams.Mode of
      gmSingle,
      gmCampaign,
      gmReplaySingle: begin
                        Button_Back.Caption := gResTexts[TX_RESULTS_BACK_TO_RESULTS];
                        Button_Back.DoSetVisible;
                        Button_BackToGame.Left := BTN_BACK_TO_GAME_LEFT;
                      end;
      else            begin
                        Button_BackToGame.Left := Button_Back.Left;
                        Button_Back.Hide;
                      end;
    end;
  end
  else
  begin
    Button_BackToGame.Hide;
    Button_Back.DoSetVisible;
    case gGameParams.Mode of
      gmSingle,
      gmCampaign,
      gmReplaySingle: Button_Back.Caption := gResTexts[TX_RESULTS_BACK_TO_RESULTS];
      gmReplayMulti:  Button_Back.Caption := gResTexts[TX_RESULTS_BACK_REPLAYS];
    else
      Button_Back.Caption := gResTexts[TX_RESULTS_BACK_MP];
    end;
  end;

  Button_Teams.Enabled := (fListToShow[stByPlayers].Count > fListToShow[stByTeams].Count); // Disable 'by Teams' btn for FFA game
end;


procedure TKMGameResultsMP.ReinitBars;

  function GetStatValue(aHandId, aStatId: Integer): Cardinal;
  begin
    with gHands[aHandId].Stats do
      case aStatId of
        0: Result := GetCitizensTrained;
        1: Result := GetCitizensRetired;
        2: Result := GetCitizensLost - GetCitizensRetired;
        3: Result := GetWarriorsTrained;
        4: Result := GetWarriorsLost;
        5: Result := GetWarriorsKilled;
        6: Result := GetHousesBuilt;
        7: Result := GetHousesLost;
        8: Result := GetHousesDestroyed;
        9: Result := GetCivilProduced;
        10: Result := GetWarfareProduced;
        else raise Exception.Create('Unknown stat id = ' + IntToStr(aStatId));
      end;
  end;

  procedure CollectStats(aStatType: TKMStatType);
  var
    I, J, K, handId: Integer;
    listToShow, handsInOne: TStringList;
  begin
    listToShow := fListToShow[aStatType];
    //Update visibility depending on players count (note, players may be sparsed)
    for I := 0 to MAX_HANDS - 1 do
      FillChar(fStatsValues[aStatType,I], SizeOf(fStatsValues[aStatType,I]), #0);

    for I := 0 to listToShow.Count - 1 do
    begin
      handsInOne := TStringList(listToShow.Objects[I]); //hands, that has to be shown as one statistics value

      for K := 0 to handsInOne.Count - 1 do
      begin
        handId := StrToInt(handsInOne[K]);
        for J := 0 to STAT_CATEGORY_CNT do
          Inc(fStatsValues[aStatType,StrToInt(handsInOne[0]),J], GetStatValue(handId,J)); // Adjoin data to 1st Hand in SameColorHands list
      end;
    end;
  end;

var
  ST: TKMStatType;
begin
  for ST := Low(TKMStatType) to High(TKMStatType) do
    CollectStats(ST);

  BarsUpdate(fStatType);
end;


function GetEconomyStatsData(aHandId: Integer; aEcoStatKind: TKMEconomyStatKind): PKMCardinalArray;
begin
  case aEcoStatKind of
    estCitizens: Result := @gHands[aHandId].Stats.ChartCitizens;
    estHouses:   Result := @gHands[aHandId].Stats.ChartHouses;
    else          raise Exception.Create('Unknown EconomyStatKind');
  end;
end;


procedure TKMGameResultsMP.ReinitChartEconomy;

  function GetEconomyChart(aStatType: TKMStatType; aEcoStatKind: TKMEconomyStatKind): TKMChart;
  begin
    case aStatType of
      stByPlayers: if aEcoStatKind = estCitizens then
                      Result := Chart_Players_Citizens
                    else
                      Result := Chart_Players_Houses;
      stByTeams:   if aEcoStatKind = estCitizens then
                      Result := Chart_Teams_Citizens
                    else
                      Result := Chart_Teams_Houses;
    else
      raise Exception.Create('Unknown Economy Chart type');
    end;
  end;

  procedure InitChart(aStatType: TKMStatType; aEcoStatKind: TKMEconomyStatKind);
  var
    chart: TKMChart;
  begin
    chart := GetEconomyChart(aStatType, aEcoStatKind);
    chart.Clear;
    chart.MaxLength := 0;
    chart.MaxTime   := gGameParams.Tick div 10;
    chart.Peacetime := 60*gGame.Options.Peacetime;
    chart.SetSeparatorPositions(fChartSeparatorsPos[aStatType]);
  end;

  procedure FillChart(aStatType: TKMStatType; aEcoStatKind: TKMEconomyStatKind);
  var
    I, J, handId: Integer;
    playersList, listToShow: TStringList;
    chartData: TKMCardinalArray;
    chart: TKMChart;
  begin
    listToShow := fListToShow[aStatType];
    chart := GetEconomyChart(aStatType, aEcoStatKind);
    for I := 0 to listToShow.Count - 1 do
    begin
      SetLength(chartData, 0);
      playersList := TStringList(listToShow.Objects[I]);

      for J := 0 to playersList.Count - 1 do
      begin
        handId := StrToInt(playersList[J]);
        KMSummAndEnlargeArr(@chartData, GetEconomyStatsData(handId, aEcoStatKind));
      end;

      if fNoEconomyChartData then
        for J := 0 to Length(chartData) - 1 do
          if chartData[J] <> 0 then
          begin
            fNoEconomyChartData := False;
            Break;
          end;

      handId := StrToInt(playersList[0]);
      chart.MaxLength := Max(chart.MaxLength, gHands[handId].Stats.ChartCount);
      chart.AddLine(fNamesToShow[aStatType, I], fColorsToShow[aStatType, I],
                     GetChartLegendDetailedTitles(aStatType, I),
                     GetChartLegendDetailedColors(aStatType, I),
                     chartData, I);
    end;
  end;

var
  ST: TKMStatType;
  ESK: TKMEconomyStatKind;
begin
  fNoEconomyChartData := True;
  for ST := Low(TKMStatType) to High(TKMStatType) do
    for ESK := Low(TKMEconomyStatKind) to High(TKMEconomyStatKind) do
    begin
      InitChart(ST, ESK);
      FillChart(ST, ESK);
    end;
  EconomyUpdate(nil);
end;


procedure TKMGameResultsMP.ReinitChartWares;
const
  WARES_CNT = 31;

  WARES: array [0..WARES_CNT-1] of TKMWareType = (
    wtAll,      wtWarfare,      wtFood,
    wtTrunk,    wtStone,        wtTimber,     wtIronOre,      wtGoldOre,
    wtCoal,     wtIron,         wtGold,       wtWine,         wtCorn,
    wtBread,    wtFlour,        wtLeather,    wtSausage,      wtPig,
    wtSkin,     wtWoodenShield, wtIronShield, wtLeatherArmor, wtIronArmor,
    wtAxe,      wtSword,        wtLance,      wtPike,         wtBow,
    wtCrossbow, wtHorse,        wtFish);

  procedure RefreshChart(aStatType: TKMStatType; W: TKMWareType; aChart: TKMChart; aUseGDP: Boolean);
  var
    I, K, handId: Integer;
    playersList: TStringList;
    chartData, chartWaresData: TKMCardinalArray;
  begin
    aChart.Clear;
    aChart.MaxLength := 0;
    aChart.MaxTime   := gGameParams.Tick div 10;
    aChart.Peacetime := 60*gGame.Options.Peacetime;
    aChart.SetSeparatorPositions(fChartSeparatorsPos[aStatType]);

    if aUseGDP then
      aChart.Caption   := gRes.Wares[W].Title + ' - ' + gResTexts[TX_RESULTS_WARES_GDP]
    else
      aChart.Caption   := gRes.Wares[W].Title + ' - ' + gResTexts[TX_GRAPH_TITLE_RESOURCES];

    for I := 0 to fListToShow[aStatType].Count - 1 do
    begin
      SetLength(chartData, 0);
      playersList := TStringList(fListToShow[aStatType].Objects[I]);

      for K := 0 to playersList.Count - 1 do
      begin
        handId := StrToInt(playersList[K]);
        chartWaresData := GetChartWares(handId, W, aUseGDP);
        KMSummAndEnlargeArr(@chartData, @chartWaresData);
      end;

      handId := StrToInt(playersList[0]);
      aChart.MaxLength := Max(aChart.MaxLength, gHands[handId].Stats.ChartCount);
      aChart.AddLine(fNamesToShow[aStatType, I], fColorsToShow[aStatType, I],
                      GetChartLegendDetailedTitles(aStatType, I),
                      GetChartLegendDetailedColors(aStatType, I),
                      chartData, I);
    end;
  end;

var
  I, K, J: Integer;
  wareInGDP, selectedItemTag, selectedGDPItemTag, selectedTopIndex, selectedGDPTopIndex: Integer;
  W: TKMWareType;
  listRow: TKMListRow;
  ST: TKMStatType;
begin
  selectedItemTag := -1;
  selectedGDPItemTag := -1;

  if Columnbox_Wares.IsSelected then
    selectedItemTag := Columnbox_Wares.SelectedItem.Tag;
  if Columnbox_WaresGDP.IsSelected then
    selectedGDPItemTag := Columnbox_WaresGDP.SelectedItem.Tag;

  selectedTopIndex := Columnbox_Wares.TopIndex;
  selectedGDPTopIndex := Columnbox_WaresGDP.TopIndex;
  //Prepare columnboxes
  Columnbox_Wares.Clear;
  Columnbox_WaresGDP.Clear;
  for I := Low(WARES) to High(WARES) do
  begin
    W := WARES[I];
    for K := 0 to gHands.Count - 1 do
    if DoShowHandStats(K)
      and not gHands[K].Stats.ChartWaresEmpty(W) then
    begin
      listRow := MakeListRow(['', gRes.Wares[W].Title],
                             [$FFFFFFFF, $FFFFFFFF],
                             [MakePic(rxGui, gRes.Wares[W].GUIIcon), MakePic(rxGui, 0)],
                             Byte(W));
      Columnbox_Wares.AddItem(listRow);
      if selectedItemTag = Byte(W) then
        Columnbox_Wares.ItemIndex := Columnbox_Wares.RowCount - 1;

      wareInGDP := GetWareIdInGDPArr(W);
      if wareInGDP <> -1 then
      begin
        Columnbox_WaresGDP.AddItem(listRow);
        if selectedGDPItemTag = Byte(W) then
          Columnbox_WaresGDP.ItemIndex := Columnbox_WaresGDP.RowCount - 1;
      end;
      Break;
    end;
  end;

  Columnbox_Wares.TopIndex := selectedTopIndex;
  Columnbox_WaresGDP.TopIndex := selectedGDPTopIndex;

  //Fill in chart values
  for ST := Low(TKMStatType) to High(TKMStatType) do
    for J := 0 to Columnbox_Wares.RowCount - 1 do
    begin
      W := TKMWareType(Columnbox_Wares.Rows[J].Tag);

      RefreshChart(ST, W, Charts_Wares[ST, W], False);
      wareInGDP := GetWareIdInGDPArr(W);
      if wareInGDP <> -1 then
        RefreshChart(ST, W, Charts_WaresGDP[ST, wareInGDP], True);
    end;

  if not Columnbox_Wares.IsSelected then
    Columnbox_Wares.ItemIndex := 0;  //Select 1st elem in column box, there should be always ArmyPower

  if not Columnbox_WaresGDP.IsSelected then
    Columnbox_WaresGDP.ItemIndex := 0;  //Select 1st elem in column box, there should be always ArmyPower

  Columnbox_Wares.ItemHeight := Min(Columnbox_Wares.Height div 15, 20);
  Columnbox_WaresGDP.ItemHeight := Min(Columnbox_WaresGDP.Height div 15, 20);

  WareUpdate(nil);
end;


procedure TKMGameResultsMP.ReinitChartArmy;
type
  TKMChartArmyCaptionIndex = array[TKMChartArmyKind] of Integer;
const
  CHART_ARMY_CAPTION_INDEX: TKMChartArmyCaptionIndex = (
    TX_RESULTS_ARMY_INSTANTANEOUS,
    TX_RESULTS_ARMY_TOTAL_EQUIPPED,
    TX_RESULTS_ARMY_DEFEATED,
    TX_RESULTS_ARMY_LOST
  );
var
  I, J, handId: Integer;
  playersList: TStringList;
  chartData, ChartArmyData: TKMCardinalArray;
  wType: TKMChartWarriorType;
  cKind: TKMChartArmyKind;
  ST: TKMStatType;
  chart: TKMChart;
  chartArmy: TKMChartArmyMP;
begin
  fNoArmyChartData := True;

  for cKind := Low(TKMChartArmyKind) to High(TKMChartArmyKind) do
  begin
    SetLength(fColumnBoxArmy_Rows[cKind], Integer(High(TKMChartWarriorType)) + 1); // Set max length for columnbox rows for all chart kinds
    I := 0;
    //Fill columnbox rows for every CKind. We have to do it now, when gHands is not free'd yet
    for wType := Low(TKMChartWarriorType) to High(TKMChartWarriorType) do
    begin
      for J := 0 to gHands.Count - 1 do
        if DoShowHandStats(J)
          and ((wType = cwtArmyPower)   // Always add ArmyPower chart, even if its empty
            or not Charts_Army[fStatType,cKind,wType].IsEmpty(J)) then
        begin
          fColumnBoxArmy_Rows[cKind, I] := wType;
          Inc(I);
          if wType <> cwtArmyPower then
            fNoArmyChartData := False;
          Break; // Found warriors data for at least 1 hand, that's enough to show warrior type in column box
        end;
    end;
    SetLength(fColumnBoxArmy_Rows[cKind], I); //Cut unused elements, so we will show only needed lines in ArmyChange
  end;

  // Fill in chart values
  for ST := Low(TKMStatType) to High(TKMStatType) do
    for cKind := Low(TKMChartArmyKind) to High(TKMChartArmyKind) do
      for wType := Low(TKMChartWarriorType) to High(TKMChartWarriorType) do
      begin
        chartArmy := Charts_Army[ST, cKind, wType];
        chart := chartArmy.Chart;
        chart.Clear;
        chart.MaxLength := 0;
        chart.MaxTime := gGameParams.Tick div 10;
        chart.Peacetime := 60 * gGame.Options.Peacetime;
        chart.SetSeparatorPositions(fChartSeparatorsPos[ST]);
        chart.Caption := chartArmy.ChartType.GUIName + ' - ' + gResTexts[CHART_ARMY_CAPTION_INDEX[cKind]];

        for I := 0 to fListToShow[ST].Count - 1 do
        begin
          SetLength(chartData, 0);
          playersList := TStringList(fListToShow[ST].Objects[I]);

          for J := 0 to playersList.Count - 1 do
          begin
            handId := StrToInt(playersList[J]);
            ChartArmyData := chartArmy.GetChartData(handId);
            KMSummAndEnlargeArr(@chartData, @ChartArmyData);
          end;

          handId := StrToInt(playersList[0]);
          chart.MaxLength := Max(chart.MaxLength, gHands[handId].Stats.ChartCount);
          chart.AddLine(fNamesToShow[ST, I], fColorsToShow[ST, I],
                         GetChartLegendDetailedTitles(ST, I),
                         GetChartLegendDetailedColors(ST, I),
                         chartData, I);
        end;

        chart.TrimToFirstVariation; // Trim Army charts, as usually they are same before PeaceTime
      end;

  ArmyUpdate(nil);
end;


procedure TKMGameResultsMP.Create_ResultsMP(aParent: TKMPanel);
const
  TABS_TOP = 75;

  procedure SetupButton(var aBtn: TKMButtonFlat; const aCaption: String; aTexOffX: ShortInt; aOnClick: TNotifyEvent;
                        aAnchors: TKMAnchorsSet = [anLeft, anTop]);
  begin
    aBtn.TexOffsetX := aTexOffX;
    aBtn.TexOffsetY := 6;
    aBtn.Anchors := aAnchors;
    aBtn.Caption := aCaption;
    aBtn.CapOffsetY := -11;
    aBtn.OnClick := aOnClick;
  end;

begin
  Panel_ResultsMP := TKMPanel.Create(aParent, 0, 0, aParent.Width, aParent.Height);
  Panel_ResultsMP.AnchorsStretch;

    with TKMImage.Create(Panel_ResultsMP,0,0,aParent.Width, aParent.Height,7,rxGuiMain) do
    begin
      ImageStretch;
      AnchorsCenter;
    end;
    with TKMShape.Create(Panel_ResultsMP,0,0,aParent.Width, aParent.Height) do
    begin
      AnchorsCenter;
      FillColor := $A0000000;
    end;

    Label_ResultsMP := TKMLabel.Create(Panel_ResultsMP,RESULTS_X_PADDING,TABS_TOP-30,Panel_ResultsMP.Width - 2*RESULTS_X_PADDING,20,NO_TEXT,fntMetal,taCenter);
    Label_ResultsMP.Anchors := [anLeft, anTop];

    Button_Bars := TKMButtonFlat.Create(Panel_ResultsMP, 160, TABS_TOP, 176, 20, 8, rxGuiMain);
    SetupButton(Button_Bars, gResTexts[TX_RESULTS_STATISTICS], -78, TabChange);

    Button_Army := TKMButtonFlat.Create(Panel_ResultsMP, 340, TABS_TOP, 176, 20, 53, rxGui);
    SetupButton(Button_Army, gResTexts[TX_GRAPH_ARMY], -76, TabChange);

    Button_Economy := TKMButtonFlat.Create(Panel_ResultsMP, 520, TABS_TOP, 176, 20, 589, rxGui);
    SetupButton(Button_Economy, gResTexts[TX_RESULTS_ECONOMY], -72, TabChange);

    Button_Wares := TKMButtonFlat.Create(Panel_ResultsMP, 700, TABS_TOP, 176, 20, 360, rxGui);
    SetupButton(Button_Wares, gResTexts[TX_GRAPH_RESOURCES], -77, TabChange);

    Button_Players := TKMButtonFlat.Create(Panel_ResultsMP, 605+RESULTS_X_PADDING+5, Panel_ResultsMP.Height - BACK_BTN_Y_TO_BOTTOM, 140, 30, 141, rxGui);
    SetupButton(Button_Players, gResTexts[TX_RESULTS_BY_PLAYERS], -Button_Players.Width div 2 + 12, StatTypeChange, [anLeft, anBottom]);
    Button_Players.CapOffsetX := 12;

    Button_Teams := TKMButtonFlat.Create(Panel_ResultsMP, 755+RESULTS_X_PADDING+5, Panel_ResultsMP.Height - BACK_BTN_Y_TO_BOTTOM, 140, 30, 392, rxGui);
    SetupButton(Button_Teams, gResTexts[TX_RESULTS_BY_TEAMS], -Button_Teams.Width div 2 + 20, StatTypeChange, [anLeft, anBottom]);
    Button_Teams.CapOffsetX := 20;

    fStatType := stByPlayers;

    CreateBars(Panel_ResultsMP);
    CreateChartEconomy;

    CreateChartWares(Panel_ResultsMP);
    CreateChartArmy(Panel_ResultsMP);

    Button_Back := TKMButton.Create(Panel_ResultsMP, 50 + RESULTS_X_PADDING, Panel_ResultsMP.Height - BACK_BTN_Y_TO_BOTTOM,
                                    270, 30, NO_TEXT, bsMenu);
    Button_Back.Anchors := [anLeft, anBottom];
    Button_Back.OnClick := BackClick;

    Button_BackToGame := TKMButton.Create(Panel_ResultsMP, BTN_BACK_TO_GAME_LEFT, Panel_ResultsMP.Height - BACK_BTN_Y_TO_BOTTOM,
                                          250, 30, gResTexts[TX_RESULTS_BACK_TO_GAME], bsMenu);
    Button_BackToGame.Anchors := [anLeft, anBottom];
    Button_BackToGame.OnClick := BackClick;

  Panel_ResultsMP.OnHeightChange := Resize;
end;


function TKMGameResultsMP.GetChartWares(aPlayer: TKMHandID; aWare: TKMWareType; aUseGDP: Boolean): TKMCardinalArray;
const
  FOOD_WARES: array[0..3] of TKMWareType = (wtBread, wtSausage, wtWine, wtFish);
  FOOD_WARES_RESTORE: array[0..3] of Single = (BREAD_RESTORE,SAUSAGE_RESTORE,WINE_RESTORE,FISH_RESTORE);
var
  RT: TKMWareType;
  I, J: Integer;
  tempResult: Single;
begin
  with gHands[aPlayer].Stats do
    case aWare of
      WARE_MIN..WARE_MAX: Result := ChartWares[aWare];
      wtAll:             begin
                            SetLength(Result, ChartCount);
                            for I := 0 to ChartCount - 1 do
                              Result[I] := 0;
                            for I := 0 to ChartCount - 1 do
                            begin
                              tempResult := 0;
                              for RT := WARE_MIN to WARE_MAX do
                                tempResult := tempResult + ChartWares[RT][I] * IfThen(aUseGDP, gRes.Wares[RT].MarketPrice, 1);
                              Result[I] := Round(tempResult);
                            end;
                          end;
      wtWarfare:         begin
                            SetLength(Result, ChartCount);
                            for I := 0 to ChartCount - 1 do
                              Result[I] := 0;
                            for I := 0 to ChartCount - 1 do
                            begin
                              tempResult := 0;
                              for RT := WARFARE_MIN to WARFARE_MAX do
                                tempResult := tempResult + ChartWares[RT][I] * IfThen(aUseGDP, gRes.Wares[RT].MarketPrice, 1);
                              Result[I] := Round(tempResult);
                            end;
                          end;
      wtFood:            begin
                            SetLength(Result, ChartCount);
                            for I := 0 to ChartCount - 1 do
                              Result[I] := 0;
                            for I := 0 to ChartCount - 1 do
                            begin
                              tempResult := 0;
                              for J := 0 to 3 do
                              begin
                                RT := FOOD_WARES[J];
                                if aUseGDP then
                                  tempResult := tempResult + ChartWares[RT][I] * gRes.Wares[RT].MarketPrice
                                else
                                  tempResult := tempResult + ChartWares[RT][I] * FOOD_WARES_RESTORE[J]; //Compute food value according to food types condition restore
                              end;
                              Result[I] := Round(tempResult);
                            end;
                          end;
  end;
end;


procedure TKMGameResultsMP.ResetControls;
var
  I: Integer;
  ST: TKMStatType;
begin
  Button_Players.Down := True;
  Button_Teams.Down := False;

  for I := 0 to MAX_HANDS - 1 do
    for ST := Low(TKMStatType) to High(TKMStatType) do
      fLegendLinesVisible[ST,I] := True;

  fStatType := stByPlayers;

  //Show first tab
  TabChange(Button_Bars);

  Radio_ChartArmyType.ItemIndex := 0;
  Radio_ChartEconomyType.ItemIndex := 0;
  Radio_ChartWareType.ItemIndex := 0;

  Columnbox_Army.Clear;
  Columnbox_Wares.Clear;
  Columnbox_WaresGDP.Clear;
end;


procedure TKMGameResultsMP.Show(aMsg: TKMGameResultMsg; aReinitLastTime: Boolean = False);
begin
  fGameResultMsg := aMsg;

  if not fReinitedLastTime then
    Reinit;

  fReinitedLastTime := aReinitLastTime;

  Panel_ResultsMP.Show;
  //ALERT !!!! Refactor
  gMain.ForceResize; //For some reason we could have wrong Panel_ResultsMP Panel position on screen, ForcedResize fix the Issue
  Resize(nil, 0);
end;


procedure TKMGameResultsMP.Hide;
begin
  Panel_ResultsMP.Hide;
  Panel_ResultsMP.Parent.Hide;
end;


function TKMGameResultsMP.Visible: Boolean;
begin
  Result := Panel_ResultsMP.Visible;
end;


procedure TKMGameResultsMP.UpdateState(aTick: Cardinal);
begin
  if Visible
    and not gGame.ReadyToStop then
    Reinit;
end;


procedure TKMGameResultsMP.BackClick(Sender: TObject);
begin
  //Depending on where we were created we need to return to a different place
  //Multiplayer game end   -> ResultsMP -> Multiplayer
  //Multiplayer replay end -> ResultsMP -> Replays
  //Results SP             -> ResultsMP -> ResultsSP
  if Sender = Button_Back then
  begin
    if gGameParams.IsSingleplayer then
      fOnShowSPStats
    else begin
      fReinitedLastTime := False; //Reset to default Value for next game (before game stop)
      fOnStopGame;
    end;
  end else
  if Sender = Button_BackToGame then
    Hide;
end;


end.

