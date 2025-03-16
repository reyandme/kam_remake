unit KM_GUIGameResultsSP;
{$I KaM_Remake.inc}
interface
uses
  SysUtils,
  KM_Controls, KM_ControlsBase, KM_ControlsChart, KM_Defaults, KM_Pics,
  KM_InterfaceDefaults, KM_MapTypes, KM_CampaignClasses,
  KM_GameTypes, KM_CommonTypes;


type
  TKMGameResultsSP = class
  private
    fOnStopGame: TUnicodeStringWDefEvent; //will be in ancestor class
    fOnShowDetailedStats: TEvent; //will be in ancestor class
    fGameResultMsg: TKMGameResultMsg; //So we know where to go after results screen
    fGameMode: TKMGameMode;

    //Story behind these seemingly superflous elements that
    //we need to carry on from previous Game:
    //- Mission script does not knows GameName
    //- Mission does not knows to which CampaignName/Map it belongs
    //- PathName to mission and savegame (incase mission is missing we can load .bas)
    fRepeatGameName: UnicodeString;
    fRepeatMissionFileRel: UnicodeString;
    fRepeatSave: UnicodeString;
    fRepeatCampName: TKMCampaignId;
    fRepeatCampMap: Byte;
    fRepeatLocation: Byte;
    fRepeatColor: Cardinal;
    fRepeatDifficulty: TKMMissionDifficulty;
    fRepeatAIType: TKMAIType;

    fReinitedLastTime: Boolean;

    procedure Create_Results(aParent: TKMPanel);
    procedure Reinit;

    procedure GraphToggle(Sender: TObject);

    procedure MoreStatsClick(Sender: TObject);
    procedure BackClick(Sender: TObject);
    procedure ContinueClick(Sender: TObject);
    procedure RepeatClick(Sender: TObject);
  protected
    Panel_Results: TKMPanel;
      Label_Results: TKMLabel;
      Panel_Stats: TKMPanel;
        Label_MissionTime: TKMLabel;
        Label_Stat: array [1..10] of TKMLabel;
      Panel_StatsCharts: TKMPanel;
        Button_ResultsArmy,
        Button_ResultsCitizens,
        Button_ResultsHouses,
        Button_ResultsWares,
        Button_MoreStats: TKMButtonFlat;
        Chart_Army: TKMChart;
        Chart_Citizens: TKMChart;
        Chart_Houses: TKMChart;
        Chart_Wares: TKMChart;
      Button_Back,
      Button_Restart,
      Button_ContinueCampaign: TKMButton;
  public
    constructor Create(aParent: TKMPanel; aOnStopGame: TUnicodeStringWDefEvent; aOnShowDetailedStats: TEvent);

    property GameResultMsg: TKMGameResultMsg read fGameResultMsg;

    procedure Show(aMsg: TKMGameResultMsg; aReinitLastTime: Boolean = False);
    function Visible: Boolean;
    procedure Hide;
    procedure UpdateState(aTick: Cardinal);
  end;


implementation
uses
  KM_ResTexts, KM_Game, KM_GameApp, KM_GameParams, KM_HandsCollection,
  KM_CommonUtils, KM_Resource, KM_Hand, KM_RenderUI, KM_ResFonts,
  KM_ResWares, KM_HandStats,
  KM_ResTypes,
  KM_InterfaceTypes;

const
  BTN_ROW_1 = 570;
  BTN_ROW_2 = 620;
  BTN_ROW_3 = 670;

  STAT_MISSION_TIME_LBL_TX_CONTINUES: array[Boolean] of Integer =
                                          (TX_RESULTS_MISSION_COMPLETED_IN,
                                           TX_RESULTS_MISSION_TIME);

{ TKMGUIMenuResultsSP }
constructor TKMGameResultsSP.Create(aParent: TKMPanel; aOnStopGame: TUnicodeStringWDefEvent; aOnShowDetailedStats: TEvent);
begin
  inherited Create;

  fOnStopGame := aOnStopGame;
  fOnShowDetailedStats := aOnShowDetailedStats;
  Create_Results(aParent);
end;


procedure TKMGameResultsSP.Reinit;
var
  tempGraphCount: Integer;
  tempGraphs: array [0..MAX_HANDS-1] of record
                                          OwnerName: UnicodeString;
                                          Color: Cardinal;
                                          G: TKMCardinalArray;
                                        end;

  //Temp graphs are used to adjoin same colored AI opponents into one chart
  procedure AddToTempGraph(const aOwnerName: UnicodeString; aColor: Cardinal; aGraph: TKMCardinalArray);
  var
    I, ID: Integer;
  begin
    ID := -1;
    for I := 0 to tempGraphCount - 1 do
      if aColor = tempGraphs[I].Color then
      begin
        ID := I;
        Break;
      end;
    if ID = -1 then
    begin
      ID := tempGraphCount;
      Inc(tempGraphCount);
      tempGraphs[ID].G := Copy(aGraph, Low(aGraph), Length(aGraph)); // Copy array contents, not assign it!
      tempGraphs[ID].Color := aColor;
      tempGraphs[ID].OwnerName := aOwnerName;
    end
    else
      for I := 0 to Length(aGraph) - 1 do
        Inc(tempGraphs[ID].G[I], aGraph[I]); //Add each element to the existing elements
  end;

var
  I: Integer;
  WT: TKMWareType;
  G: TKMCardinalArray;
  humanId: TKMHandID;
  showAIResults: Boolean;
  cap: UnicodeString;
begin
  fGameMode := gGameParams.Mode;

  //Remember which map we played so we could restart it
  fRepeatGameName := gGameParams.Name;
  fRepeatMissionFileRel := gGameParams.MissionFileRel;
  fRepeatSave := gGame.SaveFile;
  fRepeatCampName := gGame.CampaignName;
  fRepeatCampMap := gGame.CampaignMap;
  fRepeatLocation := gGame.PlayerLoc;
  fRepeatColor := gGame.PlayerColor;
  fRepeatDifficulty := gGameParams.MissionDifficulty;
  fRepeatAIType := gGame.AIType;

  // When exit mission update stats to build actual charts
  // without CHARTS_SAMPLING_FOR_TACTICS or CHARTS_SAMPLING_FOR_ECONOMY delays
  // so measurements for warriors/goods produces will not differ from charts
//  if gGame.ReadyToStop then //Only if game is ready to stop the game
//    for I := 0 to gHands.Count - 1 do
//      gHands[I].Stats.UpdateState;

  //If the player canceled mission, hide the AI graph lines so he doesn't see secret info about enemy (e.g. army size)
  //That info should only be visible if the mission was won or a replay
  showAIResults := gGameParams.IsReplay
                   or (fGameResultMsg in [grWin, grReplayEnd])
                   or ((fGameResultMsg = grGameContinues) and (gMySpectator.Hand.AI.HasWon));

  Label_MissionTime.Caption := gResTexts[STAT_MISSION_TIME_LBL_TX_CONTINUES[fGameResultMsg = grGameContinues]];

  //Restart button is hidden if you won or if it is a replay
  Button_Restart.Visible := not (fGameResultMsg in [grReplayEnd, grWin, grGameContinues]);

  //Even if the campaign is complete Player can now return to it's screen to replay any of the maps
  Button_ContinueCampaign.Visible := (gGameApp.Campaigns.ActiveCampaign <> nil)
                                     and not (fGameResultMsg in [grReplayEnd, grGameContinues]);
  // Show 'Continue' or 'ToCamppaigMap'
  if fGameResultMsg = grWin then
    Button_ContinueCampaign.Caption := gResTexts[TX_MENU_MISSION_NEXT]
  else
    Button_ContinueCampaign.Caption := gResTexts[TX_MENU_MISSION_TO_CAMPAIGN_MAP];

  if fGameResultMsg = grGameContinues then
    Button_Back.Caption := gResTexts[TX_RESULTS_BACK_TO_GAME]
  else
    Button_Back.Caption := gResTexts[TX_MENU_BACK];  

  //Header
  case fGameResultMsg of
    grWin:           cap := gResTexts[TX_MENU_MISSION_VICTORY];
    grDefeat:        cap := gResTexts[TX_MENU_MISSION_DEFEAT];
    grCancel:        cap := gResTexts[TX_MENU_MISSION_CANCELED];
    grReplayEnd:     cap := gResTexts[TX_MENU_REPLAY_ENDED];
    grGameContinues: cap := ''; //Do not show game result, as game is still going
  else
    cap := NO_TEXT;
  end;
  Label_Results.Caption := cap;

  //Append mission name and time after the result message
  if Label_Results.Caption <> '' then
    Label_Results.Caption := Label_Results.Caption + ' - ';
  Label_Results.Caption := Label_Results.Caption + gGameParams.Name; //Don't show the mission time in SP because it's already shown elsewhere

  //Append difficulty level to game results caption
  if gGameParams.MissionDifficulty <> mdNone then
    Label_Results.Caption := Label_Results.Caption + ' (' + gResTexts[DIFFICULTY_LEVELS_TX[gGameParams.MissionDifficulty]] + ')';


  //This is SP menu, we are dead sure there's only one Human player (NOT REALLY)
  humanId := -1;
  for I := 0 to gHands.Count - 1 do
    if gHands[I].IsHuman then
    begin
      humanId := I;
      Break;
    end;

  //Still possible to have no Humans, if we play some MP replay in SP replay mode
  if humanId = -1 then
    humanId := 0;

  //List values (like old KaM did)
  with gHands[humanId].Stats do
  begin
    Label_Stat[1].Caption := IntToStr(GetCitizensLost + GetWarriorsLost - GetCitizensRetired);
    Label_Stat[2].Caption := IntToStr(GetCitizensRetired);
    Label_Stat[3].Caption := IntToStr(GetCitizensKilled + GetWarriorsKilled);
    Label_Stat[4].Caption := IntToStr(GetHousesLost);
    Label_Stat[5].Caption := IntToStr(GetHousesDestroyed);
    Label_Stat[6].Caption := IntToStr(GetHousesBuilt);
    Label_Stat[7].Caption := IntToStr(GetCitizensTrained);
    Label_Stat[8].Caption := IntToStr(GetWarfareProduced);
    Label_Stat[9].Caption := IntToStr(GetWarriorsTrained);
    Label_Stat[10].Caption := TimeToString(gGame.MissionTime);
  end;

  //Chart values
  Chart_Army.Clear;
  Chart_Citizens.Clear;
  Chart_Houses.Clear;
  Chart_Wares.Clear;
  Chart_Army.MaxLength      := gHands[humanId].Stats.ChartCount;
  Chart_Citizens.MaxLength  := gHands[humanId].Stats.ChartCount;
  Chart_Houses.MaxLength    := gHands[humanId].Stats.ChartCount;
  Chart_Wares.MaxLength     := gHands[humanId].Stats.ChartCount;

  Chart_Army.MaxTime      := gGameParams.Tick div 10;
  Chart_Citizens.MaxTime  := gGameParams.Tick div 10;
  Chart_Houses.MaxTime    := gGameParams.Tick div 10;
  Chart_Wares.MaxTime     := gGameParams.Tick div 10;

  //Citizens
  tempGraphCount := 0; //Reset
  for I := 0 to gHands.Count - 1 do
    with gHands[I] do
    begin
      if not Enabled then Continue;

      if IsComputer then
        AddToTempGraph(OwnerName(False), FlagColor, Stats.ChartCitizens)
      else
      begin
        Chart_Citizens.AddLine(OwnerName, FlagColor, Stats.ChartCitizens);
        //Recruits aren't that important, but if we want to include them they should be a separate graph
        //Chart_Citizens.AddAltLine(Stats.ChartRecruits);
      end;
    end;

  if showAIResults then
    for I := 0 to tempGraphCount - 1 do
      Chart_Citizens.AddLine(tempGraphs[I].OwnerName, tempGraphs[I].Color, tempGraphs[I].G);

  //Houses
  tempGraphCount := 0; //Reset
  for I := 0 to gHands.Count - 1 do
    with gHands[I] do
    begin
      if not Enabled then Continue;

      if IsComputer then
        AddToTempGraph(OwnerName(False), FlagColor, Stats.ChartHouses)
      else
        Chart_Houses.AddLine(OwnerName, FlagColor, Stats.ChartHouses);
    end;

  if showAIResults then
    for I := 0 to tempGraphCount - 1 do
      Chart_Houses.AddLine(tempGraphs[I].OwnerName, tempGraphs[I].Color, tempGraphs[I].G);

  //Wares
  for WT := WARE_MIN to WARE_MAX do
  begin
    G := gHands[humanId].Stats.ChartWares[WT];
    for I := 0 to High(G) do
      if G[I] <> 0 then
      begin
        Chart_Wares.AddLine(gRes.Wares[WT].Title, gRes.Wares[WT].GUIColor or $FF000000, G);
        Break;
      end;
  end;

  //Army
  tempGraphCount := 0; //Reset
  for I := 0 to gHands.Count - 1 do
    with gHands[I] do
    begin
      if not Enabled then Continue;

      if IsComputer then
        AddToTempGraph(OwnerName(False), FlagColor, Stats.ChartArmy[cakInstantaneous, utAny])
      else
        Chart_Army.AddLine(OwnerName, FlagColor, Stats.ChartArmy[cakInstantaneous, utAny]);
    end;

  if showAIResults then
    for I := 0 to tempGraphCount - 1 do
      Chart_Army.AddLine(tempGraphs[I].OwnerName, tempGraphs[I].Color, tempGraphs[I].G);

  Button_ResultsHouses.Enabled := gGameParams.IsNormalMission;
  Button_ResultsCitizens.Enabled := gGameParams.IsNormalMission;
  Button_ResultsWares.Enabled := gGameParams.IsNormalMission;
end;


procedure TKMGameResultsSP.GraphToggle(Sender: TObject);
begin
  Chart_Army.Visible := Sender = Button_ResultsArmy;
  Chart_Citizens.Visible := Sender = Button_ResultsCitizens;
  Chart_Houses.Visible := Sender = Button_ResultsHouses;
  Chart_Wares.Visible := Sender = Button_ResultsWares;

  Button_ResultsArmy.Down := Sender = Button_ResultsArmy;
  Button_ResultsCitizens.Down := Sender = Button_ResultsCitizens;
  Button_ResultsHouses.Down := Sender = Button_ResultsHouses;
  Button_ResultsWares.Down := Sender = Button_ResultsWares;
end;


procedure TKMGameResultsSP.Show(aMsg: TKMGameResultMsg; aReinitLastTime: Boolean = False);
begin
  fGameResultMsg := aMsg;

//  fStatsLastUpdateTick := 0;
//  if (aMsg <> grGameContinues) and (fStatsLastUpdateTick = 0) then
//    fStatsLastUpdateTick := gHands.GetFirstEnabledHand.Stats.LastUpdateStateTick;

  if not fReinitedLastTime then
    Reinit;

  fReinitedLastTime := aReinitLastTime;

  GraphToggle(Button_ResultsArmy);

  Panel_Results.Show;
end;


procedure TKMGameResultsSP.Hide;
begin
  Panel_Results.Hide;
  Panel_Results.Parent.Hide;
end;


function TKMGameResultsSP.Visible: Boolean;
begin
  Result := Panel_Results.Visible;
end;


procedure TKMGameResultsSP.UpdateState(aTick: Cardinal);
begin
  if Visible and not gGame.ReadyToStop then
    Reinit;
end;


procedure TKMGameResultsSP.Create_Results(aParent: TKMPanel);
const
  LEGEND_WIDTH = 150;
  STAT_TEXT: array [1..10] of Word = (
    TX_RESULTS_UNITS_LOST,       TX_RESULTS_CITIZENS_DISMISSED, TX_RESULTS_UNITS_DEFEATED,   TX_RESULTS_HOUSES_LOST,
    TX_RESULTS_HOUSES_DESTROYED, TX_RESULTS_HOUSES_BUILT,     TX_RESULTS_UNITS_TRAINED,
    TX_RESULTS_WEAPONS_MADE,     TX_RESULTS_SOLDIERS_TRAINED, TX_RESULTS_MISSION_COMPLETED_IN);
var
  I, adv: Integer;
begin
  Panel_Results := TKMPanel.Create(aParent,0,0,aParent.Width, aParent.Height);
  Panel_Results.AnchorsStretch;
    //Background image
    with TKMImage.Create(Panel_Results,0,0,aParent.Width, aParent.Height,7,rxGuiMain) do
    begin
      ImageStretch;
      AnchorsCenter;
    end;
    //Fade to black by 62.5%
    with TKMShape.Create(Panel_Results,0,0,aParent.Width, aParent.Height) do
    begin
      AnchorsCenter;
      FillColor := $A0000000;
    end;

    Label_Results := TKMLabel.Create(Panel_Results,RESULTS_X_PADDING,70,900,20,NO_TEXT,fntMetal,taCenter);
    Label_Results.Anchors := [anLeft];

    Panel_Stats := TKMPanel.Create(Panel_Results, 20, 146, 360, 354);
    Panel_Stats.Anchors := [anLeft];

      //Backplate for column results
      with TKMImage.Create(Panel_Stats, -10, -10, 385, 374 + 25, 18, rxGuiMain) do
      begin
        ImageStretch;
        AnchorsCenter;
      end;

      adv := 0;
      for I := 1 to 10 do
      begin
        Inc(adv, 25);
        if I in [4,7,8] then inc(adv, 15);
        if I = 10 then
        begin
          Inc(adv, 45);
          Label_MissionTime := TKMLabel.Create(Panel_Stats, 20, adv, 240, 20, gResTexts[STAT_TEXT[I]], fntMetal, taLeft);
        end
        else
          TKMLabel.Create(Panel_Stats, 20, adv, 240, 20, gResTexts[STAT_TEXT[I]], fntMetal, taLeft);
        Label_Stat[I] := TKMLabel.Create(Panel_Stats, 260, adv, 80, 20, '00', fntMetal, taRight);
      end;

    Panel_StatsCharts := TKMPanel.Create(Panel_Results, 400, 100, 630, 420);
    Panel_StatsCharts.Anchors := [anLeft];

    Button_ResultsArmy := TKMButtonFlat.Create(Panel_StatsCharts, 40, 0, 208, 20, 53, rxGui);
    Button_ResultsArmy.TexOffsetX := -91;
    Button_ResultsArmy.TexOffsetY := 7;
    Button_ResultsArmy.Anchors := [anLeft];
    Button_ResultsArmy.Caption := gResTexts[TX_GRAPH_ARMY];
    Button_ResultsArmy.CapOffsetY := -11;
    Button_ResultsArmy.OnClick := GraphToggle;

    Button_ResultsCitizens := TKMButtonFlat.Create(Panel_StatsCharts, 40, 22, 208, 20, 588, rxGui);
    Button_ResultsCitizens.TexOffsetX := -92;
    Button_ResultsCitizens.TexOffsetY := 6;
    Button_ResultsCitizens.Anchors := [anLeft];
    Button_ResultsCitizens.Caption := gResTexts[TX_GRAPH_CITIZENS];
    Button_ResultsCitizens.CapOffsetY := -11;
    Button_ResultsCitizens.OnClick := GraphToggle;

    Button_ResultsHouses := TKMButtonFlat.Create(Panel_StatsCharts, 252, 0, 208, 20, 587, rxGui);
    Button_ResultsHouses.TexOffsetX := -93;
    Button_ResultsHouses.TexOffsetY := 6;
    Button_ResultsHouses.Anchors := [anLeft];
    Button_ResultsHouses.Caption := gResTexts[TX_GRAPH_HOUSES];
    Button_ResultsHouses.CapOffsetY := -11;
    Button_ResultsHouses.OnClick := GraphToggle;

    Button_ResultsWares := TKMButtonFlat.Create(Panel_StatsCharts, 252, 22, 208, 20, 360, rxGui);
    Button_ResultsWares.TexOffsetX := -93;
    Button_ResultsWares.TexOffsetY := 6;
    Button_ResultsWares.Anchors := [anLeft];
    Button_ResultsWares.Caption := gResTexts[TX_GRAPH_RESOURCES];
    Button_ResultsWares.CapOffsetY := -11;
    Button_ResultsWares.OnClick := GraphToggle;

    Chart_Army := TKMChart.Create(Panel_StatsCharts, 0, 46, 610, 574);
    Chart_Army.LegendWidth := LEGEND_WIDTH;
    Chart_Army.Caption := gResTexts[TX_GRAPH_ARMY];
    Chart_Army.Anchors := [anLeft];

    Chart_Citizens := TKMChart.Create(Panel_StatsCharts, 0, 46, 610, 574);
    Chart_Citizens.LegendWidth := LEGEND_WIDTH;
    Chart_Citizens.Caption := gResTexts[TX_GRAPH_CITIZENS];
    Chart_Citizens.Anchors := [anLeft];

    Chart_Houses := TKMChart.Create(Panel_StatsCharts, 0, 46, 610, 574);
    Chart_Houses.LegendWidth := LEGEND_WIDTH;
    Chart_Houses.Caption := gResTexts[TX_GRAPH_HOUSES];
    Chart_Houses.Anchors := [anLeft];

    Chart_Wares := TKMChart.Create(Panel_StatsCharts, 0, 46, 610, 574);
    Chart_Wares.LegendWidth := LEGEND_WIDTH;
    Chart_Wares.Caption := gResTexts[TX_GRAPH_TITLE_RESOURCES];
    Chart_Wares.Anchors := [anLeft];

    Button_MoreStats := TKMButtonFlat.Create(Panel_StatsCharts, 610 - LEGEND_WIDTH + 2, 0, LEGEND_WIDTH, 42, 663, rxGui);
    Button_MoreStats.TexOffsetX := -LEGEND_WIDTH div 2 + 14;
    Button_MoreStats.TexOffsetY := 6;
    Button_MoreStats.Anchors := [anLeft];
    Button_MoreStats.Caption := gResTexts[TX_RESULTS_MORE_STATS];
    Button_MoreStats.CapOffsetX := 12;
    Button_MoreStats.CapOffsetY := -20;
    Button_MoreStats.OnClick := MoreStatsClick;

    Button_ContinueCampaign := TKMButton.Create(Panel_Results, 30, BTN_ROW_1, 280, 30, gResTexts[TX_MENU_MISSION_NEXT], bsMenu);
    Button_ContinueCampaign.Anchors := [anLeft];
    Button_ContinueCampaign.OnClick := ContinueClick;

    Button_Restart := TKMButton.Create(Panel_Results, 30, BTN_ROW_2, 280, 30, gResTexts[TX_MENU_MISSION_REPEAT], bsMenu);
    Button_Restart.Anchors := [anLeft];
    Button_Restart.OnClick := RepeatClick;

    Button_Back := TKMButton.Create(Panel_Results, 30, BTN_ROW_3, 280, 30, gResTexts[TX_MENU_BACK], bsMenu);
    Button_Back.Anchors := [anLeft];
    Button_Back.OnClick := BackClick;
end;


procedure TKMGameResultsSP.MoreStatsClick(Sender: TObject);
begin
  fOnShowDetailedStats;
end;


procedure TKMGameResultsSP.BackClick(Sender: TObject);
begin
  //Depending on where we were created we need to return to a different place
  //Campaign game end     -> ResultsSP -> Main menu
  //Singleplayer game end -> ResultsSP -> Singleplayer
  //Replay end            -> ResultsSP -> Replays

  if fGameResultMsg = grGameContinues then
    Hide
  else begin
    fReinitedLastTime := False; //Reset to default Value for next game (before game stop)
    fOnStopGame;
  end;
end;


procedure TKMGameResultsSP.ContinueClick(Sender: TObject);
begin
  fOnStopGame(string(fRepeatCampName.ID));
end;


procedure TKMGameResultsSP.RepeatClick(Sender: TObject);
begin
  // Means replay last map
  gGameApp.NewRestartLast(fRepeatGameName, fRepeatMissionFileRel, fRepeatSave, fGameMode, fRepeatCampName, fRepeatCampMap,
                          fRepeatLocation, fRepeatColor, fRepeatDifficulty, fRepeatAIType);
end;


end.
