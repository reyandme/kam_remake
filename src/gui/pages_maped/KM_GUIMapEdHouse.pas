unit KM_GUIMapEdHouse;
{$I KaM_Remake.inc}
interface
uses
   Classes, Math, StrUtils, SysUtils,
   Controls,
   KM_Controls, KM_ControlsBase, KM_ControlsProgressBar, KM_ControlsWaresRow,
   KM_Defaults, KM_Pics, KM_Houses, KM_InterfaceGame, KM_ResHouses;

type
  TKMMapEdHouse = class
  private
    fHouse: TKMHouse;

    fStorehouseItem: Byte; //Selected ware in storehouse
    fBarracksItem: ShortInt; //Selected ware in barracks, or -1 for recruit

    procedure Create_Common(aParent: TKMPanel);
    procedure Create_Store;
    procedure Create_Barracks;
    procedure Create_TownHall;
    procedure Create_Woodcutters;

    procedure HouseChange(Sender: TObject; const aValue: Integer);
    procedure HouseHealthChange(Sender: TObject; Shift: TShiftState);
    procedure HouseHealthClickHold(Sender: TObject; AButton: TMouseButton; var aHandled: Boolean);

    procedure House_UpdateDeliveryMode(aMode: TKMDeliveryMode);
    procedure House_DeliveryModeToggle(Sender: TObject; Shift: TShiftState);
    procedure House_RepairToggle(Sender: TObject);
    procedure House_ClosedForWorkerToggle(Sender: TObject);
    procedure HandleHouseClosedForWorker(aHouse: TKMHouse);

    procedure House_RefreshRepair;
    procedure House_RefreshCommon;
    procedure BarracksRefresh;
    procedure TownHallRefresh;
    procedure WoodcuttersRefresh;
    procedure StoreRefresh;

    procedure BarracksSelectWare(Sender: TObject);
    procedure SetRallyPointClick(Sender: TObject);

    procedure BarracksChange(Sender: TObject; Shift: TShiftState);
    procedure TownHallChange(Sender: TObject; const aValue: Integer);
    procedure StoreChange(Sender: TObject; Shift: TShiftState);

    procedure StoreSelectWare(Sender: TObject);

    procedure ShowCommonResources;
    procedure HideAllCommonResources;
  protected
    Panel_House: TKMPanel;
      Label_House: TKMLabel;
      Image_House_Logo: TKMImage;
      Image_House_Worker: TKMImage;
      Button_HouseDeliveryMode: TKMButton;
      Button_HouseRepair: TKMButton;
      Image_House_Worker_Closed: TKMImage;
      Button_House_Worker: TKMButton;
      HealthBar_House: TKMPercentBar;
      Button_HouseHealthDec: TKMButton;
      Button_HouseHealthInc: TKMButton;
      Label_House_Input: TKMLabel;
      Label_House_Output: TKMLabel;
      ResRow_Ware_Input: array [0..3] of TKMWareOrderRow;
      ResRow_Ware_Output: array [0..3] of TKMWareOrderRow;

    Panel_HouseWoodcutters: TKMPanel;
      Button_Woodcutters_CuttingPoint: TKMButtonFlat;

    Panel_HouseStore: TKMPanel;
      Button_Store: array [1..STORE_RES_COUNT] of TKMButtonFlat;
      Label_Store_WareCount: TKMLabel;
      Button_StoreDec100, Button_StoreDec: TKMButton;
      Button_StoreInc100, Button_StoreInc: TKMButton;

    Panel_HouseBarracks: TKMPanel;
      Button_Barracks_RallyPoint: TKMButtonFlat;
      Button_Barracks: array [1..BARRACKS_RES_COUNT] of TKMButtonFlat;
      Button_Barracks_Recruit: TKMButtonFlat;
      Label_Barracks_WareCount: TKMLabel;
      Button_BarracksDec100, Button_BarracksDec: TKMButton;
      Button_BarracksInc100, Button_BarracksInc: TKMButton;

    Panel_HouseTownHall: TKMPanel;
      Button_TownHall_RallyPoint: TKMButtonFlat;
      WaresRow_TH_Gold_Input: TKMWareOrderRow;
  public
    constructor Create(aParent: TKMPanel);

    procedure KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);

    procedure Show(aHouse: TKMHouse);
    procedure Hide;
    function Visible: Boolean;
    procedure UpdateState;
  end;


implementation
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLType, {$ENDIF}
  KM_HandsCollection, KM_HandTypes, KM_HandEntity,
  KM_ResTexts, KM_Resource, KM_RenderUI, KM_ResUnits,
  KM_HouseBarracks, KM_HouseTownHall, KM_HouseStore,
  KM_ResFonts, KM_ResTypes,
  KM_Cursor, KM_UtilsExt;


{ TKMMapEdHouse }
constructor TKMMapEdHouse.Create(aParent: TKMPanel);
begin
  inherited Create;

  fBarracksItem   := 1; //First ware selected by default
  fStorehouseItem := 1; //First ware selected by default

  Create_Common(aParent);
  Create_Store;
  Create_Barracks;
  Create_TownHall;
  Create_Woodcutters;
end;


procedure TKMMapEdHouse.Create_Common(aParent: TKMPanel);
var
  I: Integer;
begin
  Panel_House := TKMPanel.Create(aParent, TB_PAD, 45, TB_MAP_ED_WIDTH - TB_PAD, 400);
    //Thats common things
    Label_House := TKMLabel.Create(Panel_House, 0, 14, Panel_House.Width, 0, '', fntOutline, taCenter);

    Button_HouseDeliveryMode := TKMButton.Create(Panel_House,0,42,30,30,37, rxGui, bsGame);
    Button_HouseDeliveryMode.Hint := gResTexts[TX_HOUSE_TOGGLE_DELIVERS_HINT];
    Button_HouseDeliveryMode.OnClickShift := House_DeliveryModeToggle;
    Button_HouseRepair := TKMButton.Create(Panel_House,30,42,30,30,40, rxGui, bsGame);
    Button_HouseRepair.Hint := gResTexts[TX_HOUSE_TOGGLE_REPAIR_HINT];
    Button_HouseRepair.OnClick := House_RepairToggle;

    Image_House_Worker := TKMImage.Create(Panel_House,60,41,32,32,141);
    Image_House_Worker.ImageCenter;
    Button_House_Worker := TKMButton.Create(Panel_House,60,42,30,30,141, rxGui, bsGame);
    Button_House_Worker.OnClick := House_ClosedForWorkerToggle; //Clicking the button cycles it
    Image_House_Worker_Closed := TKMImage.Create(Panel_House,78,42,12,12,49); //Red triangle for house closed for worker
    Image_House_Worker_Closed.Hitable := False;
    Image_House_Worker_Closed.Hide;

    Image_House_Logo := TKMImage.Create(Panel_House,90,41,32,32,338);
    Image_House_Logo.ImageCenter;
    HealthBar_House := TKMPercentBar.Create(Panel_House, 134, 49, 42, 20);
    Button_HouseHealthDec := TKMButton.Create(Panel_House, 120, 49, 14, 20, '-', bsGame);
    Button_HouseHealthInc := TKMButton.Create(Panel_House, 175, 49, 14, 20, '+', bsGame);
    Button_HouseHealthDec.OnClickShift := HouseHealthChange;
    Button_HouseHealthInc.OnClickShift := HouseHealthChange;
    Button_HouseHealthDec.OnClickHold  := HouseHealthClickHold;
    Button_HouseHealthInc.OnClickHold  := HouseHealthClickHold;

    Label_House_Input := TKMLabel.Create(Panel_House, 0, 85, Panel_House.Width, 0, gResTexts[TX_HOUSE_NEEDS], fntGrey, taCenter);

    for I := 0 to 3 do
    begin
      ResRow_Ware_Input[I] := TKMWareOrderRow.Create(Panel_House, 0, 105 + I * 25, Panel_House.Width);
      ResRow_Ware_Input[I].WareRow.RX := rxGui;
      ResRow_Ware_Input[I].OnChange := HouseChange;
    end;
    Label_House_Output := TKMLabel.Create(Panel_House, 0, 155, Panel_House.Width, 0, gResTexts[TX_HOUSE_DELIVERS]+':', fntGrey, taCenter);
    for I := 0 to 3 do
    begin
      ResRow_Ware_Output[I] := TKMWareOrderRow.Create(Panel_House, 0, 175 + I * 25, Panel_House.Width);
      ResRow_Ware_Output[I].WareRow.RX := rxGui;
      ResRow_Ware_Output[I].OnChange := HouseChange;
    end;
end;


{Store page}
procedure TKMMapEdHouse.Create_Store;
var
  I: Integer;
begin
  Panel_HouseStore := TKMPanel.Create(Panel_House,0,76,Panel_House.Width,400);
    for I := 1 to STORE_RES_COUNT do
    begin
      Button_Store[I] := TKMButtonFlat.Create(Panel_HouseStore, 2 + ((I-1)mod 5)*36,8+((I-1)div 5)*42,32,36,0);
      Button_Store[I].TexID := gRes.Wares[StoreResType[I]].GUIIcon;
      Button_Store[I].Tag := I;
      Button_Store[I].Hint := gRes.Wares[StoreResType[I]].Title;
      Button_Store[I].OnClick := StoreSelectWare;
    end;

    Button_StoreDec100     := TKMButton.Create(Panel_HouseStore, 108, 218, 20, 20, '<', bsGame);
    Button_StoreDec100.Tag := 100;
    Button_StoreDec        := TKMButton.Create(Panel_HouseStore, 108, 238, 20, 20, '-', bsGame);
    Button_StoreDec.Tag    := 1;
    Label_Store_WareCount  := TKMLabel.Create (Panel_HouseStore, 128, 230, 50, 20, '',  fntMetal, taCenter);
    Button_StoreInc100     := TKMButton.Create(Panel_HouseStore, 178, 218, 20, 20, '>', bsGame);
    Button_StoreInc100.Tag := 100;
    Button_StoreInc        := TKMButton.Create(Panel_HouseStore, 178, 238, 20, 20, '+', bsGame);
    Button_StoreInc.Tag    := 1;
    Button_StoreDec100.OnClickShift := StoreChange;
    Button_StoreDec.OnClickShift    := StoreChange;
    Button_StoreInc100.OnClickShift := StoreChange;
    Button_StoreInc.OnClickShift    := StoreChange;
end;


procedure TKMMapEdHouse.Create_Woodcutters;
begin
  Panel_HouseWoodcutters := TKMPanel.Create(Panel_House,0,85,Panel_House.Width,40);
    Button_Woodcutters_CuttingPoint := TKMButtonFlat.Create(Panel_HouseWoodcutters, 0, 0, Panel_HouseWoodcutters.Width, 22, 0);
    Button_Woodcutters_CuttingPoint.CapOffsetY := -11;
    Button_Woodcutters_CuttingPoint.Caption := gResTexts[TX_HOUSES_WOODCUTTER_CUTTING_POINT];
    Button_Woodcutters_CuttingPoint.Hint := gResTexts[TX_MAPED_WOODCUTTER_CUTTING_POINT_HINT];
    Button_Woodcutters_CuttingPoint.OnClick := SetRallyPointClick;
end;


{Barracks page}
procedure TKMMapEdHouse.Create_Barracks;
var
  I, top, left: Integer;
begin
  Panel_HouseBarracks := TKMPanel.Create(Panel_House,0,76,Panel_House.Width,400);

    Button_Barracks_RallyPoint := TKMButtonFlat.Create(Panel_HouseBarracks, 0, 8, Panel_House.Width, 22, 0);
    Button_Barracks_RallyPoint.CapOffsetY := -11;
    Button_Barracks_RallyPoint.Caption := gResTexts[TX_HOUSES_RALLY_POINT];
    Button_Barracks_RallyPoint.Hint := Format(gResTexts[TX_MAPED_RALLY_POINT_HINT], [gRes.Houses[htBarracks].HouseName]);;
    Button_Barracks_RallyPoint.OnClick := SetRallyPointClick;

    for I := 1 to BARRACKS_RES_COUNT do
    begin
      Button_Barracks[I] := TKMButtonFlat.Create(Panel_HouseBarracks, ((I-1)mod 6)*31,26+8+((I-1)div 6)*42,28,38,0);
      Button_Barracks[I].Tag := I;
      Button_Barracks[I].TexID := gRes.Wares[BarracksResType[I]].GUIIcon;
      Button_Barracks[I].TexOffsetX := 1;
      Button_Barracks[I].TexOffsetY := 1;
      Button_Barracks[I].CapOffsetY := 2;
      Button_Barracks[I].Hint := gRes.Wares[BarracksResType[I]].Title;
      Button_Barracks[I].OnClick := BarracksSelectWare;
    end;
    Button_Barracks_Recruit := TKMButtonFlat.Create(Panel_HouseBarracks, (BARRACKS_RES_COUNT mod 6)*31,26+8+(BARRACKS_RES_COUNT div 6)*42,28,38,0);
    Button_Barracks_Recruit.Tag := -1;
    Button_Barracks_Recruit.TexOffsetX := 1;
    Button_Barracks_Recruit.TexOffsetY := 1;
    Button_Barracks_Recruit.CapOffsetY := 2;
    Button_Barracks_Recruit.TexID := gRes.Units[utRecruit].GUIIcon;
    Button_Barracks_Recruit.Hint := gRes.Units[utRecruit].GUIName;
    Button_Barracks_Recruit.OnClick := BarracksSelectWare;

    top := Button_Barracks_Recruit.Bottom + 20;
    left := 93;

    Button_BarracksDec100     := TKMButton.Create(Panel_HouseBarracks,left,      top,      20, 20, '<', bsGame);
    Button_BarracksDec100.Tag := 100;
    Button_BarracksDec        := TKMButton.Create(Panel_HouseBarracks,left,      top + 20, 20, 20, '-', bsGame);
    Button_BarracksDec.Tag    := 1;
    Label_Barracks_WareCount  := TKMLabel.Create (Panel_HouseBarracks,left + 20, top + 12, 50, 20, '', fntMetal, taCenter);
    Button_BarracksInc100     := TKMButton.Create(Panel_HouseBarracks,left + 70, top,      20, 20, '>', bsGame);
    Button_BarracksInc100.Tag := 100;
    Button_BarracksInc        := TKMButton.Create(Panel_HouseBarracks,left + 70, top + 20, 20, 20, '+', bsGame);
    Button_BarracksInc.Tag    := 1;
    Button_BarracksDec100.OnClickShift := BarracksChange;
    Button_BarracksDec.OnClickShift    := BarracksChange;
    Button_BarracksInc100.OnClickShift := BarracksChange;
    Button_BarracksInc.OnClickShift    := BarracksChange;
end;


procedure TKMMapEdHouse.Create_TownHall;
begin
  Panel_HouseTownHall := TKMPanel.Create(Panel_House,0,76,Panel_House.Width,400);

    Button_TownHall_RallyPoint := TKMButtonFlat.Create(Panel_HouseTownHall, 0, 8, Panel_House.Width, 22, 0);
    Button_TownHall_RallyPoint.CapOffsetY := -11;
    Button_TownHall_RallyPoint.Caption := gResTexts[TX_HOUSES_RALLY_POINT];
    Button_TownHall_RallyPoint.Hint := Format(gResTexts[TX_MAPED_RALLY_POINT_HINT], [gRes.Houses[htTownhall].HouseName]);
    Button_TownHall_RallyPoint.OnClick := SetRallyPointClick;

    WaresRow_TH_Gold_Input := TKMWareOrderRow.Create(Panel_HouseTownHall, 0, 34, Panel_House.Width, TH_MAX_GOLDMAX_VALUE);
    WaresRow_TH_Gold_Input.WareRow.RX := rxGui;
    WaresRow_TH_Gold_Input.Hint := gRes.Wares[wtGold].Title;
    WaresRow_TH_Gold_Input.WareRow.TexID := gRes.Wares[wtGold].GUIIcon;
    WaresRow_TH_Gold_Input.WareRow.Caption := gRes.Wares[wtGold].Title;
    WaresRow_TH_Gold_Input.OnChange := TownHallChange;
end;


procedure TKMMapEdHouse.Hide;
begin
  Panel_House.Hide;
end;


function TKMMapEdHouse.Visible: Boolean;
begin
  Result := Panel_House.Visible;
end;


procedure TKMMapEdHouse.UpdateState;
begin
  if Visible then
    case fHouse.HouseType of
      htBarracks:    Button_Barracks_RallyPoint.Down := (gCursor.Mode = cmMarkers) and (gCursor.Tag1 = MARKER_RALLY_POINT);
      htTownHall:    Button_TownHall_RallyPoint.Down := (gCursor.Mode = cmMarkers) and (gCursor.Tag1 = MARKER_RALLY_POINT);
      htWoodcutters: Button_Woodcutters_CuttingPoint.Down := (gCursor.Mode = cmMarkers) and (gCursor.Tag1 = MARKER_RALLY_POINT);
    end;
end;


procedure TKMMapEdHouse.HideAllCommonResources;
var
  I: Integer;
begin
  Label_House_Input.Hide;
  Label_House_Output.Hide;
  for I := 0 to 3 do
  begin
    ResRow_Ware_Input[I].Hide;
    ResRow_Ware_Output[I].Hide;
  end;
end;


procedure TKMMapEdHouse.ShowCommonResources;
var
  I: Integer;
  ware: TKMWareType;
  houseSpec: TKMHouseSpec;
begin
  houseSpec := gRes.Houses[fHouse.HouseType];

  Label_House_Input.Hide;
  for I := 0 to 3 do
  begin
    ware := houseSpec.WareInput[I+1];
    if gRes.Wares[ware].IsValid then
    begin
      ResRow_Ware_Input[I].WareRow.TexID := gRes.Wares[ware].GUIIcon;
      ResRow_Ware_Input[I].WareRow.Caption := gRes.Wares[ware].Title;
      ResRow_Ware_Input[I].Hint := gRes.Wares[ware].Title;
      ResRow_Ware_Input[I].WareRow.WareCount := fHouse.CheckWareIn(ware);
      ResRow_Ware_Input[I].OrderCount := fHouse.CheckWareIn(ware);
      ResRow_Ware_Input[I].Show;
      Label_House_Input.Show;
    end
    else
      ResRow_Ware_Input[I].Hide;
  end;

  Label_House_Output.Hide;
  for I := 0 to 3 do
  begin
    ware := houseSpec.WareOutput[I+1];
    if gRes.Wares[ware].IsValid then
    begin
      ResRow_Ware_Output[I].WareRow.TexID := gRes.Wares[ware].GUIIcon;
      ResRow_Ware_Output[I].WareRow.Caption := gRes.Wares[ware].Title;
      ResRow_Ware_Output[I].Hint := gRes.Wares[ware].Title;
      ResRow_Ware_Output[I].WareRow.WareCount := fHouse.CheckWareOut(ware);
      ResRow_Ware_Output[I].OrderCount := fHouse.CheckWareOut(ware);
      ResRow_Ware_Output[I].Show;
      Label_House_Output.Show;
    end
    else
      ResRow_Ware_Output[I].Hide;
  end;
end;


procedure TKMMapEdHouse.HandleHouseClosedForWorker(aHouse: TKMHouse);
begin
  if aHouse.IsClosedForWorker then
  begin
    Button_House_Worker.ShowImageEnabled := False;
    Image_House_Worker_Closed.Show;
  end else begin
    Button_House_Worker.ShowImageEnabled := aHouse.HasWorker;
    Image_House_Worker_Closed.Hide;
  end;
end;


procedure TKMMapEdHouse.Show(aHouse: TKMHouse);
var
  houseSpec: TKMHouseSpec;
begin
  fHouse := aHouse;
  if fHouse = nil then Exit;

  houseSpec := gRes.Houses[fHouse.HouseType];

  {Common data}
  Label_House.Caption := houseSpec.HouseName;
  Image_House_Logo.TexID := houseSpec.GUIIcon;

  HealthBar_House.Caption := IntToStr(Round(fHouse.GetHealth)) + '/' + IntToStr(houseSpec.MaxHealth);
  HealthBar_House.Position := fHouse.GetHealth / houseSpec.MaxHealth;

  if fHouse.HouseType <> htTownHall then //Do not show common resources input/output for TownHall
    ShowCommonResources
  else
    HideAllCommonResources;

  House_RefreshCommon;

  case fHouse.HouseType of
    htStore:       begin
                      Panel_HouseStore.Show;
                      StoreRefresh;
                      //Reselect the ware so the display is updated
                      StoreSelectWare(Button_Store[fStorehouseItem]);
                    end;
    htBarracks:   begin
                      Panel_HouseBarracks.Show;
                      BarracksRefresh;
                      //In the barrack the recruit icon is always enabled
                      Image_House_Worker.Show;
                      Image_House_Worker.Enable;
                      Button_House_Worker.Visible := False;
                      Button_Barracks_Recruit.FlagColor := gHands[fHouse.Owner].FlagColor;
                      //Reselect the ware so the display is updated
                      if fBarracksItem = -1 then
                        BarracksSelectWare(Button_Barracks_Recruit)
                      else
                        BarracksSelectWare(Button_Barracks[fBarracksItem]);
                    end;
    htTownHall:    begin
                      Panel_HouseTownHall.Show;
                      TownHallRefresh;
                    end;
    htWoodcutters: begin
                      Panel_HouseWoodcutters.Show;
                      WoodcuttersRefresh;
                    end;
  else
    Panel_HouseWoodcutters.Hide;
    Panel_House.Show;
  end;
end;


procedure TKMMapEdHouse.StoreRefresh;
var
  I, tmp: Integer;
begin
  for I := 1 to STORE_RES_COUNT do
  begin
    tmp := TKMHouseStore(fHouse).CheckWareIn(StoreResType[I]);
    Button_Store[I].Caption := IfThen(tmp = 0, '-', IntToKStr(tmp));
    Button_Store[I].Hint := IfThen(tmp = 0, '', IntToStr(tmp) + ' ' + gRes.Wares[StoreResType[I]].Title);
  end;
end;


procedure TKMMapEdHouse.House_RefreshRepair;
begin
  Button_HouseRepair.TexID := IfThen(fHouse.BuildingRepair, 39, 40);
  Button_HouseRepair.Show;
end;


procedure TKMMapEdHouse.House_RefreshCommon;
var
  houseSpec: TKMHouseSpec;
begin
  houseSpec := gRes.Houses[fHouse.HouseType];

  House_UpdateDeliveryMode(fHouse.DeliveryMode);
  Button_HouseDeliveryMode.Enabled := fHouse.AllowDeliveryModeChange;
  Button_HouseDeliveryMode.Show;

  House_RefreshRepair;

  Button_House_Worker.TexID  := gRes.Units[houseSpec.WorkerType].GUIIcon;
  HandleHouseClosedForWorker(fHouse);
  Button_House_Worker.Hint := Format(gResTexts[TX_HOUSES_CLOSED_FOR_WORKER_HINT], [gRes.Units[houseSpec.WorkerType].GUIName]);
  Button_House_Worker.FlagColor := gHands[fHouse.Owner].FlagColor;
  Button_House_Worker.Visible := gRes.Houses[fHouse.HouseType].CanHasWorker;
  Image_House_Worker.TexID := gRes.Units[houseSpec.WorkerType].GUIIcon;
  Image_House_Worker.FlagColor := gHands[fHouse.Owner].FlagColor;
  Image_House_Worker.Hint := gRes.Units[houseSpec.WorkerType].GUIName;
  Image_House_Worker.Hide; // show it on special pages (like Barracks, f.e.)
end;


procedure TKMMapEdHouse.BarracksRefresh;
var
  I, tmp: Integer;
begin
  for I := 1 to BARRACKS_RES_COUNT do
  begin
    tmp := TKMHouseBarracks(fHouse).CheckWareIn(BarracksResType[I]);
    Button_Barracks[I].Caption := IfThen(tmp = 0, '-', IntToKStr(tmp));
    Button_Barracks[I].Hint := IfThen(tmp = 0, '', IntToStr(tmp) + ' ' + gRes.Wares[BarracksResType[I]].Title);
  end;
  tmp := TKMHouseBarracks(fHouse).MapEdRecruitCount;
  Button_Barracks_Recruit.Caption := IfThen(tmp = 0, '-', IntToKStr(tmp));
  Button_Barracks_Recruit.Hint := IfThen(tmp = 0, '', IntToStr(tmp) + ' ' + gRes.Units[utRecruit].GUIName);
  Button_Barracks_RallyPoint.Down := (gCursor.Mode = cmMarkers) and (gCursor.Tag1 = MARKER_RALLY_POINT);
end;


procedure TKMMapEdHouse.TownHallRefresh;
begin
  Button_TownHall_RallyPoint.Down := (gCursor.Mode = cmMarkers) and (gCursor.Tag1 = MARKER_RALLY_POINT);
  WaresRow_TH_Gold_Input.OrderCount := fHouse.CheckWareIn(wtGold);
  WaresRow_TH_Gold_Input.WareRow.WareCount := Min(MAX_WARES_IN_HOUSE, WaresRow_TH_Gold_Input.OrderCount);
end;


procedure TKMMapEdHouse.WoodcuttersRefresh;
begin
  Button_Woodcutters_CuttingPoint.Down := (gCursor.Mode = cmMarkers) and (gCursor.Tag1 = MARKER_RALLY_POINT);
end;


procedure TKMMapEdHouse.HouseHealthChange(Sender: TObject; Shift: TShiftState);
var
  houseSpec: TKMHouseSpec;
begin
  if Sender = Button_HouseHealthDec then fHouse.AddDamage(GetMultiplicator(Shift), nil, True);
  if Sender = Button_HouseHealthInc then fHouse.AddRepair(GetMultiplicator(Shift));

  houseSpec := gRes.Houses[fHouse.HouseType];
  HealthBar_House.Caption := IntToStr(Round(fHouse.GetHealth)) + '/' + IntToStr(houseSpec.MaxHealth);
  HealthBar_House.Position := fHouse.GetHealth / houseSpec.MaxHealth;
end;


procedure TKMMapEdHouse.TownHallChange(Sender: TObject; const aValue: Integer);
var
  TH: TKMHouseTownHall;
  newValue, newCountAdd: Integer;
begin
  TH := TKMHouseTownHall(fHouse);
  if aValue > 0 then
  begin
    if TH.GoldMaxCnt < aValue + TH.GoldCnt then
      TH.GoldMaxCnt := aValue + TH.GoldCnt;
    newValue := Min(aValue, TH.GoldMaxCnt - TH.GoldCnt);
    fHouse.WareAddToIn(wtGold, newValue);
  end else
  if aValue < 0 then
  begin
    if TH.GoldMaxCnt > aValue + TH.GoldCnt then
      TH.GoldMaxCnt := Max(0, aValue + TH.GoldCnt);
    newCountAdd := Math.Min(Abs(aValue), fHouse.CheckWareIn(wtGold));
    fHouse.WareTakeFromIn(wtGold, newCountAdd);
  end;

  WaresRow_TH_Gold_Input.OrderCount := fHouse.CheckWareIn(wtGold);
  WaresRow_TH_Gold_Input.WareRow.WareCount := Min(MAX_WARES_IN_HOUSE, WaresRow_TH_Gold_Input.OrderCount);
end;


procedure TKMMapEdHouse.HouseChange(Sender: TObject; const aValue: Integer);
var
  I: Integer;
  ware: TKMWareType;
  newCountAdd: Integer;
  houseSpec: TKMHouseSpec;
begin
  House_RefreshCommon;

  houseSpec := gRes.Houses[fHouse.HouseType];
  for I := 0 to 3 do
  begin
    ware := houseSpec.WareInput[I+1];
    if not (ware in [WARE_MIN..WARE_MAX]) then Continue;

    if (Sender = ResRow_Ware_Input[I]) and (aValue > 0) then
    begin
      newCountAdd := Math.Min(aValue, MAX_WARES_IN_HOUSE - fHouse.CheckWareIn(ware));
      fHouse.WareAddToIn(ware, newCountAdd);
    end;

    if (Sender = ResRow_Ware_Input[I]) and (aValue < 0) then
    begin
      newCountAdd := Math.Min(Abs(aValue), fHouse.CheckWareIn(ware));
      fHouse.WareTakeFromIn(ware, newCountAdd);
    end;

    ResRow_Ware_Input[I].OrderCount := fHouse.CheckWareIn(ware);
    ResRow_Ware_Input[I].WareRow.WareCount := ResRow_Ware_Input[I].OrderCount;
  end;

  for I := 0 to 3 do
  begin
    ware := houseSpec.WareOutput[I+1];
    if not (ware in [WARE_MIN..WARE_MAX]) then Continue;

    if (Sender = ResRow_Ware_Output[I]) and (aValue > 0) then
    begin
      newCountAdd := Math.Min(aValue, MAX_WARES_IN_HOUSE - fHouse.CheckWareOut(ware));
      if gRes.Houses[fHouse.HouseType].IsWorkshop then
        newCountAdd := Math.Min(newCountAdd, MAX_WARES_OUT_WORKSHOP - fHouse.CheckWareOut(wtAll));
      fHouse.WareAddToOut(ware, newCountAdd);
    end;

    if (Sender = ResRow_Ware_Output[I]) and (aValue < 0) then
    begin
      newCountAdd := Math.Min(Abs(aValue), fHouse.CheckWareOut(ware));
      fHouse.WareTakeFromOut(ware, newCountAdd);
    end;

    ResRow_Ware_Output[I].OrderCount := fHouse.CheckWareOut(ware);
    ResRow_Ware_Output[I].WareRow.WareCount := ResRow_Ware_Output[I].OrderCount;
  end;
end;


procedure TKMMapEdHouse.HouseHealthClickHold(Sender: TObject; AButton: TMouseButton; var aHandled: Boolean);
var
  I: Integer;
begin
  for I := 0 to 3 do
    if (Sender = Button_HouseHealthDec) or (Sender = Button_HouseHealthInc) then
      HouseHealthChange(Sender, GetShiftState(AButton));
end;


procedure TKMMapEdHouse.SetRallyPointClick(Sender: TObject);
var
  btn: TKMButtonFlat;
begin
  if (Sender <> Button_Barracks_RallyPoint)
  and (Sender <> Button_TownHall_RallyPoint)
  and (Sender <> Button_Woodcutters_CuttingPoint) then
    Exit;

  btn := TKMButtonFlat(Sender);

  btn.Down := not btn.Down;
  if btn.Down then
  begin
    gCursor.Mode := cmMarkers;
    gCursor.Tag1 := MARKER_RALLY_POINT;
  end else
    gCursor.Mode := cmNone;
end;


procedure TKMMapEdHouse.House_UpdateDeliveryMode(aMode: TKMDeliveryMode);
begin
  Button_HouseDeliveryMode.TexID := DELIVERY_MODE_SPRITE[aMode];
end;


procedure TKMMapEdHouse.KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);
begin
  if aHandled then Exit;

  if (Key = VK_ESCAPE)
  and Visible
  and (gMySpectator.Selected <> nil) then
  begin
    gMySpectator.Selected := nil;
    Hide;
    aHandled := True;
  end;
end;

procedure TKMMapEdHouse.House_DeliveryModeToggle(Sender: TObject; Shift: TShiftState);
begin
  if ssLeft in Shift then
    fHouse.SetNextDeliveryMode
  else if ssRight in Shift then
    fHouse.SetPrevDeliveryMode;

  // Apply changes immediately
  fHouse.SetDeliveryModeInstantly(fHouse.NewDeliveryMode);

  House_UpdateDeliveryMode(fHouse.DeliveryMode);
end;


procedure TKMMapEdHouse.House_RepairToggle(Sender: TObject);
begin
  fHouse.BuildingRepair := not fHouse.BuildingRepair;
  House_RefreshRepair;
end;


procedure TKMMapEdHouse.House_ClosedForWorkerToggle(Sender: TObject);
begin
  fHouse.IsClosedForWorker := not fHouse.IsClosedForWorker;
  House_RefreshCommon;
end;


procedure TKMMapEdHouse.BarracksSelectWare(Sender: TObject);
var
  I: Integer;
begin
  if not Panel_HouseBarracks.Visible then Exit;
  if not (Sender is TKMButtonFlat) then Exit; //Only FlatButtons
  if TKMButtonFlat(Sender).Tag = 0 then Exit; //with set Tag

  Button_Barracks_Recruit.Down := False;
  for I := 1 to BARRACKS_RES_COUNT do
    Button_Barracks[I].Down := False;
  TKMButtonFlat(Sender).Down := True;
  fBarracksItem := TKMButtonFlat(Sender).Tag;
  BarracksChange(Sender, []);
end;


procedure TKMMapEdHouse.StoreSelectWare(Sender: TObject);
var
  I: Integer;
begin
  if not Panel_HouseStore.Visible then Exit;
  if not (Sender is TKMButtonFlat) then Exit; //Only FlatButtons
  if TKMButtonFlat(Sender).Tag = 0 then Exit; //with set Tag

  for I := 1 to Length(Button_Store) do
    Button_Store[I].Down := False;

  TKMButtonFlat(Sender).Down := True;
  fStorehouseItem := TKMButtonFlat(Sender).Tag;
  StoreChange(Sender, []);
end;


procedure TKMMapEdHouse.BarracksChange(Sender: TObject; Shift: TShiftState);
var
  ware: TKMWareType;
  barracks: TKMHouseBarracks;
  newCount: Word;
begin
  barracks := TKMHouseBarracks(fHouse);
  if fBarracksItem = -1 then
  begin
    // Recruits
    if (Sender = Button_BarracksDec100) or (Sender = Button_BarracksDec) then
      barracks.MapEdRecruitCount := Math.Max(0, barracks.MapEdRecruitCount - GetMultiplicator(Shift) * TKMButton(Sender).Tag);

    if (Sender = Button_BarracksInc100) or (Sender = Button_BarracksInc) then
      barracks.MapEdRecruitCount := Math.Min(High(Word), barracks.MapEdRecruitCount + GetMultiplicator(Shift) * TKMButton(Sender).Tag);

    Label_Barracks_WareCount.Caption := IntToStr(barracks.MapEdRecruitCount);
  end else
  begin
    // Wares
    ware := BarracksResType[fBarracksItem];

    if (Sender = Button_BarracksDec100) or (Sender = Button_BarracksDec) then
    begin
      newCount := Math.Min(barracks.CheckWareIn(ware), GetMultiplicator(Shift) * TKMButton(Sender).Tag);
      barracks.WareTakeFromOut(ware, newCount);
    end;

    if (Sender = Button_BarracksInc100) or (Sender = Button_BarracksInc) then
    begin
      newCount := Math.Min(High(Word) - barracks.CheckWareIn(ware), GetMultiplicator(Shift) * TKMButton(Sender).Tag);
      barracks.WareAddToIn(ware, newCount);
    end;

    Label_Barracks_WareCount.Caption := IntToStr(barracks.CheckWareIn(ware));
  end;

  BarracksRefresh;
end;


procedure TKMMapEdHouse.StoreChange(Sender: TObject; Shift: TShiftState);
var
  ware: TKMWareType;
  store: TKMHouseStore;
  newCount: Word;
begin
  store := TKMHouseStore(fHouse);
  ware := StoreResType[fStorehouseItem];

  //We need to take no more than it is there, thats part of bugtracking idea
  if (Sender = Button_StoreDec100) or (Sender = Button_StoreDec) then begin
    newCount := Math.Min(store.CheckWareIn(ware), GetMultiplicator(Shift) * TKMButton(Sender).Tag);
    store.WareTakeFromOut(ware, newCount);
  end;

  //We can always add any amount of resource, it will be capped by Store
  if (Sender = Button_StoreInc100) or (Sender = Button_StoreInc) then
    store.WareAddToIn(ware, GetMultiplicator(Shift) * TKMButton(Sender).Tag);

  Label_Store_WareCount.Caption := inttostr(store.CheckWareIn(ware));
  StoreRefresh;
end;


end.
