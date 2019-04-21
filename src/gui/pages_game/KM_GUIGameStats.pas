unit KM_GUIGameStats;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, StrUtils, SysUtils,
  KM_Controls, KM_Defaults, KM_Houses,
  KM_InterfaceGame, KM_ResHouses, KM_CommonTypes;


type
  TKMGUIGameStats = class
  private
    fOnShowStats: TNotifyEvent;
    fHouseSketch: TKMHouseSketchEdit;
    fLastHouseUIDs: array [HOUSE_MIN..HOUSE_MAX] of Cardinal;
    fSetViewportEvent: TPointFEvent;
    procedure House_Stat_Clicked(Sender: TObject);
    procedure ResetUIDs;
  protected
    Panel_Stats: TKMPanel;
      Panel_StatBlock: array [0..STATS_LINES_CNT-1] of TKMPanel;
        Stat_HousePic: array [HOUSE_MIN..HOUSE_MAX] of TKMImage;
        Stat_UnitPic: array [CITIZEN_MIN..CITIZEN_MAX] of TKMImage;
        Stat_HouseQty, Stat_HouseWip: array [HOUSE_MIN..HOUSE_MAX] of TKMLabel;
        Stat_UnitQty, Stat_UnitWip: array [CITIZEN_MIN..CITIZEN_MAX] of TKMLabel;
      Button_ShowStats: TKMButtonFlat;
  public
    constructor Create(aParent: TKMPanel; aOnShowStats: TNotifyEvent; aSetViewportEvent: TPointFEvent);
    destructor Destroy; override;

    procedure Show;
    procedure Hide;
    procedure Resize;
    procedure UpdateState;
    function Visible: Boolean;
  end;


implementation
uses
  KM_RenderUI, KM_HandsCollection, KM_ResTexts, KM_Resource, KM_ResFonts, KM_ResUnits,
  KM_Hand, KM_Pics, KM_Points;


{ TKMGUIGameStats }
constructor TKMGUIGameStats.Create(aParent: TKMPanel; aOnShowStats: TNotifyEvent; aSetViewportEvent: TPointFEvent);
const
  HOUSE_W = 30;
  UNIT_W = 26;
  BEVEL_LAYER = 1;
  IMAGE_LAYER = 2;
  TEXT_LAYER = 3;
var
  I, K: Integer;
  HT: TKMHouseType;
  UT: TKMUnitType;
  OffX: Integer;
begin
  inherited Create;

  fOnShowStats := aOnShowStats;
  fSetViewportEvent := aSetViewportEvent;
  fHouseSketch := TKMHouseSketchEdit.Create;
  ResetUIDs;

  Panel_Stats := TKMPanel.Create(aParent, TB_PAD, 44, TB_WIDTH, 332);
  Panel_Stats.Anchors := [anLeft, anTop, anBottom];

    for I := 0 to High(StatPlan) do
    begin
      //Houses block
      Panel_StatBlock[I] := TKMPanel.Create(Panel_Stats, 0, 0, 30, 30);
      with TKMBevel.Create(Panel_StatBlock[I], 0, 0, 30, 30, BEVEL_LAYER) do
        AnchorsStretch;

      OffX := 0;
      for K := Low(StatPlan[I].HouseType) to High(StatPlan[I].HouseType) do
        if StatPlan[I].HouseType[K] <> htNone then
        begin
          HT := StatPlan[I].HouseType[K];
          Stat_HousePic[HT] := TKMImage.Create(Panel_StatBlock[I], OffX, 0, HOUSE_W, 30, 41, rxGui, IMAGE_LAYER); //Filled with [?] at start
          Stat_HousePic[HT].Hint := gRes.Houses[HT].HouseName;
          Stat_HousePic[HT].ImageCenter;
          Stat_HousePic[HT].Tag := Byte(HT);
          Stat_HouseWip[HT] := TKMLabel.Create(Panel_StatBlock[I], OffX + HOUSE_W  ,  0,  '', fntGrey, taRight, TEXT_LAYER);
          Stat_HouseWip[HT].Hitable := False;
          Stat_HouseQty[HT] := TKMLabel.Create(Panel_StatBlock[I], OffX + HOUSE_W-2, 16, '-', fntGrey, taRight, TEXT_LAYER);
          Stat_HouseQty[HT].Hitable := False;
          Inc(OffX, HOUSE_W);
        end;

      for K := Low(StatPlan[I].UnitType) to High(StatPlan[I].UnitType) do
        if StatPlan[I].UnitType[K] <> utNone then
        begin
          UT := StatPlan[I].UnitType[K];
          Stat_UnitPic[UT] := TKMImage.Create(Panel_StatBlock[I], OffX, 0, UNIT_W, 30, gRes.Units[UT].GUIIcon, rxGui, IMAGE_LAYER);
          Stat_UnitPic[UT].Hint := gRes.Units[UT].GUIName;
          Stat_UnitPic[UT].ImageCenter;
          Stat_UnitWip[UT] := TKMLabel.Create(Panel_StatBlock[I], OffX + UNIT_W  ,  0,  '', fntGrey, taRight, TEXT_LAYER);
          Stat_UnitWip[UT].Hitable := False;
          Stat_UnitQty[UT] := TKMLabel.Create(Panel_StatBlock[I], OffX + UNIT_W-2, 16, '-', fntGrey, taRight, TEXT_LAYER);
          Stat_UnitQty[UT].Hitable := False;
          Inc(OffX, UNIT_W);
        end;
      Panel_StatBlock[I].Width := OffX;
    end;
    Button_ShowStats  := TKMButtonFlat.Create(Panel_Stats, TB_WIDTH - 30, 0, 30, 30, 669, rxGui);
    Button_ShowStats.OnClick := fOnShowStats;
    Button_ShowStats.Hint := gResTexts[TX_GAME_MENU_SHOW_STATS_HINT];
end;


destructor TKMGUIGameStats.Destroy;
begin
  FreeAndNil(fHouseSketch);

  inherited
end;


//Resize stats page in a way to display data in more readable form
//Try to keep items in corresponding pairs and stack them when dont fit otherwise
procedure TKMGUIGameStats.Resize;
const
  PAD_X = 4;
  PAD_Y = 4;
var
  Rows: Integer;
  I, K: Integer;
  OffX, NextWidth, LineHeight: Integer;
  NeedToCompact: Boolean;
begin
  LineHeight := Panel_StatBlock[0].Height + PAD_Y;
  //How many rows could fit
  Rows := Panel_Stats.Height div (LineHeight);

  //Reposition ShowStats button
  if Rows >= 12 then
    Button_ShowStats.Top := 0
  else if Rows = 11 then
    Button_ShowStats.Top := LineHeight
  else
    Button_ShowStats.Top := 2 * LineHeight;

  //Adjoin rows till they fit
  K := 0;
  OffX := 0;
  for I := 0 to High(StatPlan) do
  begin
    Panel_StatBlock[I].Left := OffX;
    Panel_StatBlock[I].Top := K * LineHeight;

    Inc(OffX, PAD_X + Panel_StatBlock[I].Width);

    //Return caret
    if I <> High(StatPlan) then
    begin
      NeedToCompact := (Length(StatPlan) - I) > (Rows - K);
      NextWidth := Panel_StatBlock[I].Width + PAD_X;
      if not NeedToCompact or (OffX + NextWidth > TB_WIDTH) then
      begin
        OffX := 0;
        Inc(K);
      end;
    end;
  end;
end;


procedure TKMGUIGameStats.UpdateState;
var
  HT: TKMHouseType;
  UT: TKMUnitType;
  Qty, WipQty, HTotalConstrOpenedQty: Integer;
  I,K: Integer;
  DoHighlight: Boolean;
begin
  //Update display values
  for I := 0 to High(StatPlan) do
  begin
    HTotalConstrOpenedQty := 0;
    for K := Low(StatPlan[I].HouseType) to High(StatPlan[I].HouseType) do
    if not (StatPlan[I].HouseType[K] in [htNone, htAny]) then
    begin
      HT := StatPlan[I].HouseType[K];
      Qty := gMySpectator.Hand.Stats.GetHouseQty(HT);
      WipQty := gMySpectator.Hand.Stats.GetHouseWip(HT);
      HTotalConstrOpenedQty := HTotalConstrOpenedQty + gMySpectator.Hand.Stats.GetHouseOpenedQty(HT); // count total constructed OPENED houses
      Stat_HouseQty[HT].Caption := IfThen(Qty  = 0, '-', IntToStr(Qty));
      Stat_HouseWip[HT].Caption := IfThen(WipQty = 0, '', '+' + IntToStr(WipQty));
      if gMySpectator.Hand.Locks.HouseCanBuild(HT) or (Qty > 0) then
      begin
        Stat_HousePic[HT].TexID := gRes.Houses[HT].GUIIcon;
        Stat_HousePic[HT].Hint := gRes.Houses[HT].HouseName;
      end
      else
      begin
        Stat_HousePic[HT].TexID := 41;
        Stat_HousePic[HT].Hint := gResTexts[TX_HOUSE_NOT_AVAILABLE]; //Building not available
      end;
      if Qty + WipQty > 0 then
      begin
        Stat_HousePic[HT].HighlightOnMouseOver := True;
        Stat_HousePic[HT].OnClick := House_Stat_Clicked;
      end else begin
        Stat_HousePic[HT].HighlightOnMouseOver := False;
        Stat_HousePic[HT].OnClick := nil;
      end;
    end;

    for K := Low(StatPlan[I].UnitType) to High(StatPlan[I].UnitType) do
    if StatPlan[I].UnitType[K] <> utNone then
    begin
      UT := StatPlan[I].UnitType[K];
      Qty := gMySpectator.Hand.Stats.GetUnitQty(UT);
      WipQty := gMySpectator.Hand.Stats.GetUnitWip(UT);

      //Hightlight unit qty, when there are not enought workers
      DoHighlight := (I < High(StatPlan) - 1) // do not highlight last 2 rows - Barracks/Watch tower and Storehouse/Inn/School
        and (HTotalConstrOpenedQty > Qty + WipQty);

      if DoHighlight then
        Stat_UnitQty[UT].FontColor := clStatsUnitMissingHL
      else
        Stat_UnitQty[UT].FontColor := clStatsUnitDefault;

      Stat_UnitQty[UT].Caption := IfThen(not DoHighlight and (Qty  = 0), '-', IntToStr(Qty));
      Stat_UnitWip[UT].Caption := IfThen(WipQty = 0, '', '+' + IntToStr(WipQty));
      Stat_UnitPic[UT].Hint := gRes.Units[UT].GUIName;
      Stat_UnitPic[UT].FlagColor := gMySpectator.Hand.FlagColor;
    end;
  end;
end;


procedure TKMGUIGameStats.ResetUIDs;
var
  HT: TKMHouseType;
begin
  for HT := Low(fLastHouseUIDs) to High(fLastHouseUIDs) do
    fLastHouseUIDs[HT] := 0;
end;


procedure TKMGUIGameStats.House_Stat_Clicked(Sender: TObject);
var
  HT: TKMHouseType;
begin
  Assert(Sender is TKMImage);
  if not Assigned(fSetViewportEvent) then Exit;

  HT := TKMHouseType(TKMImage(Sender).Tag);

  gMySpectator.Hand.GetNextHouseWSameType(HT, fLastHouseUIDs[HT], fHouseSketch, [hstHouse, hstHousePlan]);
  if not fHouseSketch.IsEmpty then
  begin
    gMySpectator.Highlight := fHouseSketch;
    fSetViewportEvent(KMPointF(fHouseSketch.Entrance)); //center viewport on that house
    fLastHouseUIDs[HT] := fHouseSketch.UID;
  end;
end;


procedure TKMGUIGameStats.Show;
begin
  UpdateState;
  Resize;
  Panel_Stats.Show;
end;


procedure TKMGUIGameStats.Hide;
begin
  Panel_Stats.Hide;
end;


function TKMGUIGameStats.Visible: Boolean;
begin
  Result := Panel_Stats.Visible;
end;


end.
