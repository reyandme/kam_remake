unit KM_GUIGameResultsMP;
{$I KaM_Remake.inc}
interface
uses
  Classes, Controls, Math, StrUtils, SysUtils,
  KM_CommonTypes, KM_Controls, KM_Defaults, KM_Pics,
  KM_InterfaceDefaults, KM_ResWares, KM_HandStats;


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

  PKMChartArmyMP = ^TKMChartArmyMP;

  TKMStatsValues = array[0..MAX_HANDS-1] of array [0..9] of Cardinal;

  TKMGameResultsMP = class
  private
    fOnStopGame: TUnicodeStringWDefEvent;
    fOnShowSPStats: TEvent;

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

    procedure Chart_LegendClick(Sender: TObject; aLegendLineId: Integer; aLineVisible: Boolean);

    procedure RadioEconomyTypeChange(Sender: TObject);
    procedure RadioWareTypeChange(Sender: TObject);
    procedure RadioArmyTypeChange(Sender: TObject);

    function GetChartLegendDetailedTitles(aStatType: TKMStatType; aLineI: Integer): TStringArray;
    function GetChartLegendDetailedColors(aStatType: TKMStatType; aLineI: Integer): TKMCardinalArray;

    procedure Reinit;
    procedure ReinitPlayersToShow;
    procedure ReinitTeamsToShow;
    procedure ReinitBars;
    procedure ReinitChartEconomy;
    procedure ReinitChartWares;
    procedure ReinitChartArmy;

    procedure Resize(Sender: TObject; aValue: Integer);
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
          Label_ResultsPlayerName1, Label_ResultsPlayerName2: array [0 .. MAX_LOBBY_PLAYERS - 1] of TKMLabel;
          Bar_Results: array [0 .. MAX_LOBBY_PLAYERS - 1, 0 .. 9] of TKMPercentBar;
          Image_ResultsRosette: array [0 .. MAX_LOBBY_PLAYERS - 1, 0 .. 9] of TKMImage;
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
    constructor Create(aParent: TKMPanel; aOnStopGame: TUnicodeStringWDefEvent; aOnShowSPStats: TEvent);
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
  KM_RenderUI, KM_Hand, KM_ResUnits,
  KM_GameTypes;


const
  PANES_TOP = 185-80;
  BAR_ROW_HEIGHT = 21;
  CHART_HEIGHT = 595;
  CHART_ECO_HEIGHT = 285;
  BACK_BTN_Y_TO_BOTTOM = 60;
  SUBMENU_RIGHT_WIDTH = 170;
  BTN_BACK_TO_GAME_LEFT = RESULTS_X_PADDING + 330;

  WARRIORS_POWER_RATES: array [WARRIOR_MIN..WARRIOR_MAX] of Single = (
    1, 2.4, 5.2,    // utMilitia, utAxeFighter, utSwordsman
    2.2, 4,         // utBowman, utArbaletman
    2, 4,           // utPikeman, utHallebardman
    3.3, 6,         // utHorseScout, utCavalry
    5.3, 1.5, 1.5,  // utBarbarian, utPeasant, utSlingshot
    5.3, 2.1        // utMetalBarbarian, utHorseman
  );

  GDPWares: array [0..2] of TKMWareType = (wtAll, wtWarfare, wtFood);


function GetWareIdInGDPArr(aWare: TKMWareType): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to 2 do
    if aWare = GDPWares[I] then
    begin
      Result := I;
      Exit;
    end;
end;


function GetOwnerName(aHandId: Integer): String;
begin
  Result := gHands[aHandId].OwnerName(not (gGame.GameMode in [gmSingle, gmCampaign, gmReplaySingle]));
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
  if (fType.HasUnitType) then
    Result := gHands[aPlayer].Stats.ChartArmy[fKind,fType.UnitType]
  else
    Result := GetArmyPowerChartData(aPlayer);
end;


function TKMChartArmyMP.GetArmyPowerChartData(aPlayer: TKMHandID): TKMCardinalArray;
var
  WT: TKMUnitType;
  I, ChartCnt: Integer;
  Value: Single;
begin
  ChartCnt := gHands[aPlayer].Stats.ChartCount;
  //Create new array and fill it (otherwise we assign pointers and corrupt data)
  SetLength(Result, ChartCnt);
  for I := 0 to ChartCnt - 1 do
    Result[I] := 0;

  for I := 0 to ChartCnt - 1 do
  begin
    Value := 0;
    for WT := WARRIOR_MIN to WARRIOR_MAX do
      Value := Value + gHands[aPlayer].Stats.ChartArmy[fKind,WT][I]*WARRIORS_POWER_RATES[WT];
    Result[I] := Result[I] + Round(Value);
  end;
end;


function TKMChartArmyMP.IsEmpty(aPlayer: TKMHandID): Boolean;
begin
  if (fType.HasUnitType) then
    Result := gHands[aPlayer].Stats.ChartArmyEmpty(fKind, fType.UnitType)
  else
    Result := gHands[aPlayer].Stats.ChartArmyEmpty(fKind, utAny);
end;


{ TKMGUIMenuResultsMP }
constructor TKMGameResultsMP.Create(aParent: TKMPanel; aOnStopGame: TUnicodeStringWDefEvent; aOnShowSPStats: TEvent);
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
  WType: TKMChartWarriorType;
  CKind: TKMChartArmyKind;
  ST: TKMStatType;
begin
  for ST := High(TKMStatType) downto Low(TKMStatType) do
  begin
    for CKind := High(TKMChartArmyKind) downto Low(TKMChartArmyKind) do
      for WType := High(TKMChartWarriorType) downto Low(TKMChartWarriorType) do
        FreeAndNil(Charts_Army[ST,CKind,WType]);

    FreeListToShow(ST);
    FreeAndNil(fChartSeparatorsPos[ST]);
  end;
end;


procedure TKMGameResultsMP.CreateBars(aParent: TKMPanel);
const
  BarStep = 150;
  BarWidth = BarStep - 10;
  BarHalf = BarWidth div 2;
  Columns1: array[0..4] of Integer = (TX_RESULTS_MP_CITIZENS_TRAINED, TX_RESULTS_MP_CITIZENS_LOST,
                                     TX_RESULTS_MP_SOLDIERS_EQUIPPED, TX_RESULTS_MP_SOLDIERS_LOST,
                                     TX_RESULTS_MP_SOLDIERS_DEFEATED);
  Columns2: array[0..4] of Integer = (TX_RESULTS_MP_BUILDINGS_CONSTRUCTED, TX_RESULTS_MP_BUILDINGS_LOST,
                                     TX_RESULTS_MP_BUILDINGS_DESTROYED,
                                     TX_RESULTS_MP_WARES_PRODUCED, TX_RESULTS_MP_WEAPONS_PRODUCED);
var
  I,K, Middle: Integer;
begin
  Panel_Bars := TKMPanel.Create(aParent, RESULTS_X_PADDING, PANES_TOP, aParent.Width - 2*RESULTS_X_PADDING, aParent.Height - PANES_TOP - BACK_BTN_Y_TO_BOTTOM);
  Panel_Bars.AnchorsStretch;
  Middle := Panel_Bars.Height div 2;

    //Composed of two sections each on own Panel to position them vertically according to player count

    Panel_BarsUpper := TKMPanel.Create(Panel_Bars, 0, 0, Panel_Bars.Width, Middle - 3);
    Panel_BarsUpper.Anchors := [anTop];

      for I := 0 to MAX_LOBBY_PLAYERS - 1 do
        Label_ResultsPlayerName1[I] := TKMLabel.Create(Panel_BarsUpper, 0, 38+I*BAR_ROW_HEIGHT, 150, 20, '', fntMetal, taLeft);

      for K := 0 to 4 do
      begin
        with TKMLabel.Create(Panel_BarsUpper, 160 + BarStep*K, 0, BarWidth+6, 40, gResTexts[Columns1[K]], fntMetal, taCenter) do
          AutoWrap := True;
        for I := 0 to MAX_LOBBY_PLAYERS - 1 do
        begin
          Bar_Results[I,K] := TKMPercentBar.Create(Panel_BarsUpper, 160 + K*BarStep, 35+I*BAR_ROW_HEIGHT, BarWidth, 20, fntGrey);
          Bar_Results[I,K].TextYOffset := -3;
          Image_ResultsRosette[I,K] := TKMImage.Create(Panel_BarsUpper, 164 + K*BarStep, 38+I*BAR_ROW_HEIGHT, 16, 16, 8, rxGuiMain);
        end;
      end;

    Panel_BarsLower := TKMPanel.Create(Panel_Bars, 0, Middle+3, Panel_Bars.Width, Middle - 10);
    Panel_BarsLower.Anchors := [anBottom];

      for I := 0 to MAX_LOBBY_PLAYERS - 1 do
        Label_ResultsPlayerName2[I] := TKMLabel.Create(Panel_BarsLower, 0, 38+I*BAR_ROW_HEIGHT, 150, 20, '', fntMetal, taLeft);

      for K := 0 to 4 do
      begin
        with TKMLabel.Create(Panel_BarsLower, 160 + BarStep*K, 0, BarWidth+6, 40, gResTexts[Columns2[K]], fntMetal, taCenter) do
          AutoWrap := True;
        for I := 0 to MAX_LOBBY_PLAYERS - 1 do
        begin
          Bar_Results[I,K+5] := TKMPercentBar.Create(Panel_BarsLower, 160 + K*BarStep, 35+I*BAR_ROW_HEIGHT, BarWidth, 20, fntGrey);
          Bar_Results[I,K+5].TextYOffset := -3;
          Image_ResultsRosette[I,K+5] := TKMImage.Create(Panel_BarsLower, 164 + K*BarStep, 38+I*BAR_ROW_HEIGHT, 16, 16, 8, rxGuiMain);
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
  WType: TKMChartWarriorType;
  CKind: TKMChartArmyKind;
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
      for CKind := Low(TKMChartArmyKind) to High(TKMChartArmyKind) do
        for WType := Low(TKMChartWarriorType) to High(TKMChartWarriorType) do
        begin
          Charts_Army[ST,CKind,WType] := TKMChartArmyMP.Create(WType, CKind, Panel_ChartsArmy, 140, 0, Panel_ChartsArmy.Width - 140, CHART_HEIGHT);
          Charts_Army[ST,CKind,WType].Chart.AnchorsStretch;
          Charts_Army[ST,CKind,WType].Chart.Caption := gResTexts[TX_GRAPH_ARMY];
          Charts_Army[ST,CKind,WType].Chart.LegendCaption := GetChartLegendCaption(ST);
          Charts_Army[ST,CKind,WType].Chart.LegendWidth := SUBMENU_RIGHT_WIDTH;
          Charts_Army[ST,CKind,WType].Chart.OnLegendClick := Chart_LegendClick;
          Charts_Army[ST,CKind,WType].Chart.Font := fntMetal; //fntOutline doesn't work because player names blend badly with yellow
          Charts_Army[ST,CKind,WType].Chart.Hide;
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


function TKMGameResultsMP.GetChartLegendDetailedTitles(aStatType: TKMStatType; aLineI: Integer): TStringArray;
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


procedure TKMGameResultsMP.Resize(Sender: TObject; aValue: Integer);
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
  STATS_LOWER_IS_BETTER: set of Byte = [1,3,6];

  procedure SetPlayerControls(aPlayer: Integer; aEnabled: Boolean);
  var
    I: Integer;
  begin
    Label_ResultsPlayerName1[aPlayer].Visible := aEnabled;
    Label_ResultsPlayerName2[aPlayer].Visible := aEnabled;

    for I := 0 to 9 do
    begin
      Bar_Results[aPlayer,I].Visible := aEnabled;
      Image_ResultsRosette[aPlayer,I].Visible := aEnabled;
    end;
  end;

var
  I,J,K: Integer;
  UnitsMax, HousesMax, WaresMax, WeaponsMax, MaxValue: Integer;
  Bests: array [0..9] of Cardinal;
  Totals: array [0..9] of Cardinal;
  StatValue: Cardinal;
  ListToShow, HandsInOne: TStringList;
  StatsValues: TKMStatsValues;
begin
  ListToShow := fListToShow[aStatType];
  StatsValues := fStatsValues[aStatType];

  //Update visibility depending on players count (note, players may be sparsed)
  for I := 0 to MAX_LOBBY_PLAYERS - 1 do
    SetPlayerControls(I, False); //Disable them all to start

  for I := 0 to ListToShow.Count - 1 do
  begin
    SetPlayerControls(I, True); //Enable used ones

    Label_ResultsPlayerName1[I].Caption   := fNamesToShow[fStatType, I];
    Label_ResultsPlayerName1[I].FontColor := FlagColorToTextColor(fColorsToShow[fStatType, I]);
    Label_ResultsPlayerName2[I].Caption   := Label_ResultsPlayerName1[I].Caption;
    Label_ResultsPlayerName2[I].FontColor := Label_ResultsPlayerName1[I].FontColor;
  end;

  BarsUpdatePos;

  //Calculate best scores
  FillChar(Bests, SizeOf(Bests), #0);
  //These are a special case: Less is better so we initialize them high
  Bests[1] := High(Cardinal);
  Bests[3] := High(Cardinal);
  Bests[6] := High(Cardinal);
  FillChar(Totals, SizeOf(Totals), #0);

  //Calculate bests for each "section"
  for I := 0 to ListToShow.Count - 1 do
  begin
    K := StrToInt(TStringList(ListToShow.Objects[I])[0]);
    for J := 0 to 9 do
    begin
      StatValue := StatsValues[K,J];
      if J in STATS_LOWER_IS_BETTER then
      begin
        if Bests[J] > StatValue then Bests[J] := StatValue;
      end else
        if Bests[J] < StatValue then Bests[J] := StatValue;

      Inc(Totals[J], StatValue);
    end;
  end;

  //Fill in raw values
  for I := 0 to ListToShow.Count - 1 do
  begin
    K := StrToInt(TStringList(ListToShow.Objects[I])[0]);
    for J := 0 to 9 do
    begin
      StatValue := StatsValues[K,J];
      Bar_Results[I,J].Tag := StatValue;
      if J in STATS_LOWER_IS_BETTER then
      begin
        Image_ResultsRosette[I,J].Visible := (StatValue <= Bests[J]) and (Totals[J] > 0);
      end else
        Image_ResultsRosette[I,J].Visible := (StatValue >= Bests[J]) and (Totals[J] > 0);
    end;
  end;

  //Update percent bars for each category
  UnitsMax := 0;
  for K := 0 to 4 do for I := 0 to ListToShow.Count - 1 do
    UnitsMax := Max(Bar_Results[I,K].Tag, UnitsMax);

  HousesMax := 0;
  for K := 5 to 7 do for I := 0 to ListToShow.Count - 1 do
    HousesMax := Max(Bar_Results[I,K].Tag, HousesMax);

  WaresMax := 0;
  for I := 0 to ListToShow.Count - 1 do
    WaresMax := Max(Bar_Results[I,8].Tag, WaresMax);

  WeaponsMax := 0;
  for I := 0 to ListToShow.Count - 1 do
    WeaponsMax := Max(Bar_Results[I,9].Tag, WeaponsMax);

  //Knowing Max in each category we may fill bars properly
  for K := 0 to 9 do
  begin
    case K of
      0..4: MaxValue := UnitsMax;
      5..7: MaxValue := HousesMax;
      8:    MaxValue := WaresMax;
      else  MaxValue := WeaponsMax;
    end;
    for I := 0 to ListToShow.Count - 1 do
    begin
      if MaxValue <> 0 then
        Bar_Results[I,K].Position := Bar_Results[I,K].Tag / MaxValue
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
                Columnbox_Wares.ItemIndex := Columnbox_WaresGDP.ItemIndex
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
  SelectedWType, WType: TKMChartWarriorType;
  SelectedCKind,CKind: TKMChartArmyKind;
  ST: TKMStatType;
  Chart: PKMChart;
  SelectedItemTag: Integer;
begin
  //Hide everything if there is no data
  if fNoArmyChartData then
  begin
    Label_NoArmyData.DoSetVisible;
    Columnbox_Army.Hide;
    Panel_ChartArmy_Type.Hide;
    for ST := Low(TKMStatType) to High(TKMStatType) do
      for CKind := Low(TKMChartArmyKind) to High(TKMChartArmyKind) do
        for WType := Low(TKMChartWarriorType) to High(TKMChartWarriorType) do
          Charts_Army[ST,CKind,WType].Chart.Hide;
    Exit;
  end;

  SelectedItemTag := -1;
  if Columnbox_Army.IsSelected then
    SelectedItemTag := Columnbox_Army.SelectedItem.Tag;

  SelectedCKind := GetSelectedChartArmyKind;

  //Fill columnbox for selected CKind
  Columnbox_Army.Clear;
  for K := 0 to High(fColumnBoxArmy_Rows[SelectedCKind]) do
  begin
    WType := fColumnBoxArmy_Rows[SelectedCKind,K];
    Columnbox_Army.AddItem(MakeListRow(['', Charts_Army[fStatType,SelectedCKind,WType].ChartType.GUIName],   //Does not matter what chart to use - they all have same GUIName and GUIIcon
                                        [gMySpectator.Hand.FlagColor, $FFFFFFFF],
                                        [MakePic(rxGui, Charts_Army[fStatType,SelectedCKind,WType].ChartType.GUIIcon), MakePic(rxGui, 0)],
                                        Byte(WType)));
    if SelectedItemTag = Byte(WType) then
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
    for CKind := Low(TKMChartArmyKind) to High(TKMChartArmyKind) do
      for WType := Low(TKMChartWarriorType) to High(TKMChartWarriorType) do
        Charts_Army[ST,CKind,WType].Chart.Visible := False;

  SelectedWType := TKMChartWarriorType(Columnbox_Army.Rows[Columnbox_Army.ItemIndex].Tag);

  Chart := @Charts_Army[fStatType,SelectedCKind,SelectedWType].Chart;
  Chart^.Visible := True;
  //Restore previously visible lines
  for K := 0 to Chart^.LineCount - 1 do
    Chart^.SetLineVisible(K, fLegendLinesVisible[fStatType, Chart^.Lines[K].Tag]);
end;


procedure TKMGameResultsMP.Chart_LegendClick(Sender: TObject; aLegendLineId: Integer; aLineVisible: Boolean);
var
  Chart: TKMChart;
begin
  Assert(Sender is TKMChart);

  Chart := TKMChart(Sender);
  fLegendLinesVisible[fStatType, Chart.Lines[aLegendLineId].Tag] := aLineVisible;
end;


function TKMGameResultsMP.DoShowHandStats(aHandId: Integer): Boolean;
begin
  Result := gHands[aHandId].Enabled
    and (fShowAIResults or gHands[aHandId].IsHuman)
    and (
      (fGameResultMsg <> grGameContinues)
      or SHOW_ENEMIES_STATS
      or (gGame.GameMode in [gmMultiSpectate, gmReplaySingle, gmReplayMulti])
      or (gHands[aHandId].Alliances[gMySpectator.HandID] = atAlly));
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
  Result := gHands[aHandId].IsComputer and (gGame.GameMode in [gmSingle, gmCampaign, gmReplaySingle]); //Adjoin only AI's in SP games
end;


procedure TKMGameResultsMP.ReinitPlayersToShow;
var
  HandsUniqueColorsCnt: Integer;
  HandsUniqueColors: array[0..MAX_HANDS-1] of record
                                                HandId: Integer;
                                                Color: Cardinal;
                                              end;

  procedure AddOrFindHandColor(aHandId: Integer; aColor: Cardinal; var aOldI: Integer);
  var
    I: Integer;
  begin
    aOldI := -1;
    for I := 0 to HandsUniqueColorsCnt - 1 do
      if HandsUniqueColors[I].Color = aColor then
      begin
        aOldI := HandsUniqueColors[I].HandId;
        Exit;
      end;
    HandsUniqueColors[HandsUniqueColorsCnt].Color := aColor;
    HandsUniqueColors[HandsUniqueColorsCnt].HandId := aHandId;
    Inc(HandsUniqueColorsCnt);
  end;

  procedure TryAddHand(aHandId: TKMHandID);
    procedure AddNewHand;
    var PlayersIdList: TStringList;
    begin
      PlayersIdList := TStringList.Create;
      PlayersIdList.Add(IntToStr(aHandId));
      fListToShow[stByPlayers].AddObject(IntToStr(aHandId), PlayersIdList);
      fNamesToShow[stByPlayers, fListToShow[stByPlayers].Count - 1] := GetOwnerName(aHandId);
      fColorsToShow[stByPlayers, fListToShow[stByPlayers].Count - 1] := gHands[aHandId].FlagColor;
    end;

    procedure AddOldHand(aOldI: Integer);
    var ListI: Integer;
    begin
      ListI := fListToShow[stByPlayers].IndexOf(IntToStr(aOldI));
      if ListI > -1 then //should be always true
        TStringList(fListToShow[stByPlayers].Objects[ListI]).Add(IntToStr(aHandId)); //Add same color player to list
    end;
  var
    OldI: Integer;
  begin
    if DoShowHandStats(aHandId) then
    begin
      if DoAdjoinSameColorHand(aHandId) then // For SP game we have to adjoin same color hands
      begin
        AddOrFindHandColor(aHandId, gHands[aHandId].FlagColor, OldI); //Same colored players are adjoined into 1
        if OldI = -1 then
          AddNewHand
        else
          AddOldHand(OldI);
      end else
        AddNewHand;
    end;
  end;

var
  I, J, PlayersCntBeforeAdd: Integer;
  Teams: TKMByteSetArray;
  NonTeamHands: set of Byte;
begin
  Teams := gHands.GetTeamsOfAllies;
  NonTeamHands := [0..gHands.Count - 1];

  //Get non team hands
  for I := Low(Teams) to High(Teams) do
    NonTeamHands := NonTeamHands - Teams[I];

  RecreateListToShow(stByPlayers);
  HandsUniqueColorsCnt := 0;

  for I in NonTeamHands do
    TryAddHand(I);

  fChartSeparatorsPos[stByPlayers].Clear;
  for I := Low(Teams) to High(Teams) do
  begin
    PlayersCntBeforeAdd := fListToShow[stByPlayers].Count;
    for J in Teams[I] do
      TryAddHand(J);
    // Add separator position
    if (PlayersCntBeforeAdd > 0)                            // Do not add separator at first pos
      and (PlayersCntBeforeAdd < fListToShow[stByPlayers].Count) then // Do not separator if team is 'empty'
      fChartSeparatorsPos[stByPlayers].Add(IntToStr(PlayersCntBeforeAdd));
  end;
end;


procedure TKMGameResultsMP.ReinitTeamsToShow;
  procedure AddToNewTeam(aFirstHandId: Integer; aPlayersList: TStringList);
  var
    PlayersList: TStringList;
    Cnt: Integer;
  begin
    PlayersList := TStringList.Create;
    PlayersList.AddStrings(aPlayersList);
    fListToShow[stByTeams].AddObject(IntToStr(aFirstHandId), PlayersList);
    Cnt := fListToShow[stByTeams].Count - 1;
    fNamesToShow[stByTeams, Cnt] := gResTexts[TX_LOBBY_HEADER_TEAM] + ' ' + IntToStr(fListToShow[stByTeams].Count);
    fColorsToShow[stByTeams, Cnt] := gHands[aFirstHandId].FlagColor;

    fTeamMembersNames[Cnt][0] := GetOwnerName(aFirstHandId);
    fTeamMembersColors[Cnt][0] := gHands[aFirstHandId].FlagColor;
    fTeamMembersCounts[Cnt] := 1;
  end;

  procedure AddToTeam(aHandId, aTeamI: Integer; aPlayersList: TStringList);
  var
    PlayersList: TStringList;
    Cnt: Integer;
  begin
    PlayersList := TStringList(fListToShow[stByTeams].Objects[aTeamI]);
    PlayersList.AddStrings(aPlayersList);
    Cnt := fListToShow[stByTeams].Count - 1;

    fTeamMembersNames[Cnt][fTeamMembersCounts[Cnt]] := GetOwnerName(aHandId);
    fTeamMembersColors[Cnt][fTeamMembersCounts[Cnt]] := gHands[aHandId].FlagColor;
    Inc(fTeamMembersCounts[Cnt]);
  end;

var
  I,J,HandId,TeamI: Integer;
  PlayersList: TStringList;
  Teams: TKMByteSetArray;
  TeamIsNew, DoShowTeam: Boolean;
begin
  RecreateListToShow(stByTeams);
  fChartSeparatorsPos[stByTeams].Clear;
  Teams := gHands.Teams;
  TeamI := 0;

  for J := Low(Teams) to High(Teams) do
  begin
    TeamIsNew := True;
    DoShowTeam := False;
    for I := 0 to fListToShow[stByPlayers].Count - 1 do
    begin
      PlayersList := TStringList(fListToShow[stByPlayers].Objects[I]);
      HandId := StrToInt(PlayersList[0]);

      if HandId in Teams[J] then
      begin
        DoShowTeam := True; //Team could be hidden in case we show stats during the game
        if TeamIsNew then
        begin
          TeamIsNew := False;
          AddToNewTeam(HandId, PlayersList);
        end else
          AddToTeam(HandId, TeamI, PlayersList);
      end;
    end;

    if not TeamIsNew then //check if there was empty teams
      Inc(TeamI);

    if DoShowTeam and (J <> Low(Teams)) then
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
  ResultsLabelCap: UnicodeString;
begin
  //MP Stats can be shown from SP stats page. We have to hide AI players then, depending on game result
  fShowAIResults := not (gGame.GameMode in [gmSingle, gmCampaign]) or (fGameResultMsg in [grWin, grReplayEnd]);

  // When exit mission update stats to build actual charts
  // without CHARTS_SAMPLING_FOR_TACTICS or CHARTS_SAMPLING_FOR_ECONOMY delays
  // so measurements for warriors/goods produces will not differ from charts
//  for I := 0 to gHands.Count - 1 do
//    if DoShowHandStats(I) then
//      gHands[I].Stats.UpdateState;

  case fGameResultMsg of
    grWin:           ResultsLabelCap := gResTexts[TX_MENU_MISSION_VICTORY];
    grDefeat:        ResultsLabelCap := gResTexts[TX_MENU_MISSION_DEFEAT];
    grCancel:        ResultsLabelCap := gResTexts[TX_MENU_MISSION_CANCELED];
    grReplayEnd:     ResultsLabelCap := gResTexts[TX_MENU_REPLAY_ENDED];
    grGameContinues: ResultsLabelCap := '';
    else              ResultsLabelCap := NO_TEXT;
  end;

  //Append mission name and time after the result message
  Label_ResultsMP.Caption := ResultsLabelCap;
  if ResultsLabelCap <> '' then
    Label_ResultsMP.Caption := Label_ResultsMP.Caption + ' - ';

  Label_ResultsMP.Caption := Label_ResultsMP.Caption + gGame.GameName + ' - ' + TimeToString(gGame.MissionTime);

  ReinitPlayersToShow;
  ReinitTeamsToShow; //Should be done after ReinitPlayersToShow
  ReinitBars;
  ReinitChartEconomy;
  ReinitChartWares;
  ReinitChartArmy;

  Button_Wares.Enabled := (gGame.MissionMode = mmNormal);
  Button_Economy.Enabled := (gGame.MissionMode = mmNormal);

  if fGameResultMsg = grGameContinues then
  begin
    Button_BackToGame.DoSetVisible;
    case gGame.GameMode of
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
    case gGame.GameMode of
      gmSingle,
      gmCampaign,
      gmReplaySingle: begin
                        Button_Back.Caption := gResTexts[TX_RESULTS_BACK_TO_RESULTS];
                      end;
      gmReplayMulti:  begin
                        Button_Back.Caption := gResTexts[TX_RESULTS_BACK_REPLAYS];
                      end
      else            begin
                        Button_Back.Caption := gResTexts[TX_RESULTS_BACK_MP];
                      end;
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
        1: Result := GetCitizensLost;
        2: Result := GetWarriorsTrained;
        3: Result := GetWarriorsLost;
        4: Result := GetWarriorsKilled;
        5: Result := GetHousesBuilt;
        6: Result := GetHousesLost;
        7: Result := GetHousesDestroyed;
        8: Result := GetCivilProduced;
        9: Result := GetWarfareProduced;
        else raise Exception.Create('Unknown stat id = ' + IntToStr(aStatId));
      end;
  end;

  procedure CollectStats(aStatType: TKMStatType);
  var
    I,J,K,HandId: Integer;
    ListToShow,HandsInOne: TStringList;
  begin
    ListToShow := fListToShow[aStatType];
    //Update visibility depending on players count (note, players may be sparsed)
    for I := 0 to MAX_LOBBY_PLAYERS - 1 do
      FillChar(fStatsValues[aStatType,I], SizeOf(fStatsValues[aStatType,I]), #0);

    for I := 0 to ListToShow.Count - 1 do
    begin
      HandsInOne := TStringList(ListToShow.Objects[I]); //hands, that has to be shown as one statistics value

      for K := 0 to HandsInOne.Count - 1 do
      begin
        HandId := StrToInt(HandsInOne[K]);
        for J := 0 to 9 do
          Inc(fStatsValues[aStatType,StrToInt(HandsInOne[0]),J], GetStatValue(HandId,J)); // Adjoin data to 1st Hand in SameColorHands list
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

  function GetEconomyChart(aStatType: TKMStatType; aEcoStatKind: TKMEconomyStatKind): PKMChart;
  begin
    case aStatType of
      stByPlayers: if aEcoStatKind = estCitizens then
                      Result := @Chart_Players_Citizens
                    else
                      Result := @Chart_Players_Houses;
      stByTeams:   if aEcoStatKind = estCitizens then
                      Result := @Chart_Teams_Citizens
                    else
                      Result := @Chart_Teams_Houses;
      else          raise Exception.Create('Unknown Economy Chart type');
    end;
  end;

  procedure InitChart(aStatType: TKMStatType; aEcoStatKind: TKMEconomyStatKind);
  var
    Chart: PKMChart;
  begin
    Chart := GetEconomyChart(aStatType, aEcoStatKind);
    Chart^.Clear;
    Chart^.MaxLength := 0;
    Chart^.MaxTime   := gGame.GameTick div 10;
    Chart^.Peacetime := 60*gGame.GameOptions.Peacetime;
    Chart^.SetSeparatorPositions(fChartSeparatorsPos[aStatType]);
  end;

  procedure FillChart(aStatType: TKMStatType; aEcoStatKind: TKMEconomyStatKind);
  var
    I, J, HandId: Integer;
    PlayersList, ListToShow: TStringList;
    ChartData: TKMCardinalArray;
    Chart: PKMChart;
  begin
    ListToShow := fListToShow[aStatType];
    Chart := GetEconomyChart(aStatType, aEcoStatKind);
    for I := 0 to ListToShow.Count - 1 do
    begin
      SetLength(ChartData, 0);
      PlayersList := TStringList(ListToShow.Objects[I]);

      for J := 0 to PlayersList.Count - 1 do
      begin
        HandId := StrToInt(PlayersList[J]);
        KMSummAndEnlargeArr(@ChartData, GetEconomyStatsData(HandId, aEcoStatKind));
      end;

      if fNoEconomyChartData then
        for J := 0 to Length(ChartData) - 1 do
          if ChartData[J] <> 0 then
          begin
            fNoEconomyChartData := False;
            Break;
          end;

      HandId := StrToInt(PlayersList[0]);
      Chart^.MaxLength := Max(Chart^.MaxLength, gHands[HandId].Stats.ChartCount);
      Chart^.AddLine(fNamesToShow[aStatType, I], fColorsToShow[aStatType, I],
                     GetChartLegendDetailedTitles(aStatType, I),
                     GetChartLegendDetailedColors(aStatType, I),
                     ChartData, I);
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

  Wares: array [0..WARES_CNT-1] of TKMWareType = (
    wtAll,     wtWarfare, wtFood,
    wtTrunk,   wtStone,   wtWood,        wtIronOre,   wtGoldOre,
    wtCoal,    wtSteel,   wtGold,        wtWine,      wtCorn,
    wtBread,   wtFlour,   wtLeather,     wtSausages,  wtPig,
    wtSkin,    wtShield,  wtMetalShield, wtArmor,     wtMetalArmor,
    wtAxe,     wtSword,   wtPike,        wtHallebard, wtBow,
    wtArbalet, wtHorse,   wtFish);

  procedure RefreshChart(aStatType: TKMStatType; W: TKMWareType; aChart: PKMChart; aUseGDP: Boolean);
  var
    I, K, HandId: Integer;
    PlayersList: TStringList;
    ChartData, ChartWaresData: TKMCardinalArray;
  begin
    aChart^.Clear;
    aChart^.MaxLength := 0;
    aChart^.MaxTime   := gGame.GameTick div 10;
    aChart^.Peacetime := 60*gGame.GameOptions.Peacetime;
    aChart^.SetSeparatorPositions(fChartSeparatorsPos[aStatType]);

    if aUseGDP then
      aChart^.Caption   := gRes.Wares[W].Title + ' - ' + gResTexts[TX_RESULTS_WARES_GDP]
    else
      aChart^.Caption   := gRes.Wares[W].Title + ' - ' + gResTexts[TX_GRAPH_TITLE_RESOURCES];

    for I := 0 to fListToShow[aStatType].Count - 1 do
    begin
      SetLength(ChartData, 0);
      PlayersList := TStringList(fListToShow[aStatType].Objects[I]);

      for K := 0 to PlayersList.Count - 1 do
      begin
        HandId := StrToInt(PlayersList[K]);
        ChartWaresData := GetChartWares(HandId, W, aUseGDP);
        KMSummAndEnlargeArr(@ChartData, @ChartWaresData);
      end;

      HandId := StrToInt(PlayersList[0]);
      aChart^.MaxLength := Max(aChart^.MaxLength, gHands[HandId].Stats.ChartCount);
      aChart^.AddLine(fNamesToShow[aStatType, I], fColorsToShow[aStatType, I],
                      GetChartLegendDetailedTitles(aStatType, I),
                      GetChartLegendDetailedColors(aStatType, I),
                      ChartData, I);
    end;
  end;

var
  I,K,J,WareInGDP, SelectedItemTag, SelectedGDPItemTag: Integer;
  W: TKMWareType;
  ListRow: TKMListRow;
  ST: TKMStatType;
begin
  SelectedItemTag := -1;
  SelectedGDPItemTag := -1;

  if Columnbox_Wares.IsSelected then
    SelectedItemTag := Columnbox_Wares.SelectedItem.Tag;
  if Columnbox_WaresGDP.IsSelected then
    SelectedGDPItemTag := Columnbox_WaresGDP.SelectedItem.Tag;

  //Prepare columnboxes
  Columnbox_Wares.Clear;
  Columnbox_WaresGDP.Clear;
  for I := Low(Wares) to High(Wares) do
  begin
    W := Wares[I];
    for K := 0 to gHands.Count - 1 do
    if DoShowHandStats(K)
      and not gHands[K].Stats.ChartWaresEmpty(W) then
    begin
      ListRow := MakeListRow(['', gRes.Wares[W].Title],
                             [$FFFFFFFF, $FFFFFFFF],
                             [MakePic(rxGui, gRes.Wares[W].GUIIcon), MakePic(rxGui, 0)],
                             Byte(W));
      Columnbox_Wares.AddItem(ListRow);
      if SelectedItemTag = Byte(W) then
        Columnbox_Wares.ItemIndex := Columnbox_Wares.RowCount - 1;

      WareInGDP := GetWareIdInGDPArr(W);
      if WareInGDP <> -1 then
      begin
        Columnbox_WaresGDP.AddItem(ListRow);
        if SelectedGDPItemTag = Byte(W) then
          Columnbox_WaresGDP.ItemIndex := Columnbox_WaresGDP.RowCount - 1;
      end;
      Break;
    end;
  end;

  //Fill in chart values
  for ST := Low(TKMStatType) to High(TKMStatType) do
    for J := 0 to Columnbox_Wares.RowCount - 1 do
    begin
      W := TKMWareType(Columnbox_Wares.Rows[J].Tag);

      RefreshChart(ST, W, @Charts_Wares[ST, W], False);
      WareInGDP := GetWareIdInGDPArr(W);
      if WareInGDP <> -1 then
        RefreshChart(ST, W, @Charts_WaresGDP[ST, WareInGDP], True);
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
  CHART_ARMY_CAPTION_INDEX: TKMChartArmyCaptionIndex = (TX_RESULTS_ARMY_INSTANTANEOUS,
                                                        TX_RESULTS_ARMY_TOTAL_EQUIPPED,
                                                        TX_RESULTS_ARMY_DEFEATED,
                                                        TX_RESULTS_ARMY_LOST);
var
  I,J, HandId: Integer;
  PlayersList: TStringList;
  ChartData, ChartArmyData: TKMCardinalArray;
  WType: TKMChartWarriorType;
  CKind: TKMChartArmyKind;
  ST: TKMStatType;
  Chart: PKMChart;
  ChartArmy: PKMChartArmyMP;
begin
  fNoArmyChartData := True;

  for CKind := Low(TKMChartArmyKind) to High(TKMChartArmyKind) do
  begin
    SetLength(fColumnBoxArmy_Rows[CKind], Integer(High(TKMChartWarriorType)) + 1); // Set max length for columnbox rows for all chart kinds
    I := 0;
    //Fill columnbox rows for every CKind. We have to do it now, when gHands is not free'd yet
    for WType := Low(TKMChartWarriorType) to High(TKMChartWarriorType) do
    begin
      for J := 0 to gHands.Count - 1 do
        if DoShowHandStats(J)
          and ((WType = cwtArmyPower)   // Always add ArmyPower chart, even if its empty
            or not Charts_Army[fStatType,CKind,WType].IsEmpty(J)) then
        begin
          fColumnBoxArmy_Rows[CKind, I] := WType;
          Inc(I);
          if WType <> cwtArmyPower then
            fNoArmyChartData := False;
          Break; // Found warriors data for at least 1 hand, that's enought to show warrior type in column box
        end;
    end;
    SetLength(fColumnBoxArmy_Rows[CKind], I); //Cut unused elements, so we will show only needed lines in ArmyChange
  end;

  //Fill in chart values
  for ST := Low(TKMStatType) to High(TKMStatType) do
    for CKind := Low(TKMChartArmyKind) to High(TKMChartArmyKind) do
      for WType := Low(TKMChartWarriorType) to High(TKMChartWarriorType) do
      begin
        ChartArmy := @Charts_Army[ST,CKind,WType];
        Chart := @ChartArmy^.Chart;
        Chart^.Clear;
        Chart^.MaxLength := 0;
        Chart^.MaxTime := gGame.GameTick div 10;
        Chart^.Peacetime := 60*gGame.GameOptions.Peacetime;
        Chart^.SetSeparatorPositions(fChartSeparatorsPos[ST]);
        Chart^.Caption := ChartArmy^.ChartType.GUIName + ' - ' + gResTexts[CHART_ARMY_CAPTION_INDEX[CKind]];

        for I := 0 to fListToShow[ST].Count - 1 do
        begin
          SetLength(ChartData, 0);
          PlayersList := TStringList(fListToShow[ST].Objects[I]);

          for J := 0 to PlayersList.Count - 1 do
          begin
            HandId := StrToInt(PlayersList[J]);
            ChartArmyData := ChartArmy^.GetChartData(HandId);
            KMSummAndEnlargeArr(@ChartData, @ChartArmyData);
          end;

          HandId := StrToInt(PlayersList[0]);
          Chart^.MaxLength := Max(Chart^.MaxLength, gHands[HandId].Stats.ChartCount);
          Chart^.AddLine(fNamesToShow[ST, I], fColorsToShow[ST, I],
                         GetChartLegendDetailedTitles(ST, I),
                         GetChartLegendDetailedColors(ST, I),
                         ChartData, I);
        end;

        Chart^.TrimToFirstVariation; // Trim Army charts, as usually they are same before PeaceTime
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
  FoodWares: array[0..3] of TKMWareType = (wtBread, wtSausages, wtWine, wtFish);
  FoodWaresRestore: array[0..3] of Single = (BREAD_RESTORE,SAUSAGE_RESTORE,WINE_RESTORE,FISH_RESTORE);
var
  RT: TKMWareType;
  I,J: Integer;
  TempResult: Single;
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
                              TempResult := 0;
                              for RT := WARE_MIN to WARE_MAX do
                                TempResult := TempResult + ChartWares[RT][I] * IfThen(aUseGDP, gRes.Wares[RT].MarketPrice, 1);
                              Result[I] := Round(TempResult);
                            end;
                          end;
      wtWarfare:         begin
                            SetLength(Result, ChartCount);
                            for I := 0 to ChartCount - 1 do
                              Result[I] := 0;
                            for I := 0 to ChartCount - 1 do
                            begin
                              TempResult := 0;
                              for RT := WARFARE_MIN to WARFARE_MAX do
                                TempResult := TempResult + ChartWares[RT][I] * IfThen(aUseGDP, gRes.Wares[RT].MarketPrice, 1);
                              Result[I] := Round(TempResult);
                            end;
                          end;
      wtFood:            begin
                            SetLength(Result, ChartCount);
                            for I := 0 to ChartCount - 1 do
                              Result[I] := 0;
                            for I := 0 to ChartCount - 1 do
                            begin
                              TempResult := 0;
                              for J := 0 to 3 do
                              begin
                                RT := FoodWares[J];
                                if aUseGDP then
                                  TempResult := TempResult + ChartWares[RT][I] * gRes.Wares[RT].MarketPrice
                                else
                                  TempResult := TempResult + ChartWares[RT][I] * FoodWaresRestore[J]; //Compute food value according to food types condition restore
                              end;
                              Result[I] := Round(TempResult);
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
    if gGame.GameMode in [gmSingle, gmCampaign, gmReplaySingle] then
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

