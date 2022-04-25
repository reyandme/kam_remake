unit KM_GUIGameHouse;
{$I KaM_Remake.inc}
interface
uses
  StrUtils, SysUtils, Math, Classes,
  KM_Controls, KM_ControlsBase, KM_ControlsProgressBar, KM_ControlsSwitch, KM_ControlsWaresRow,
  KM_CommonClasses, KM_CommonTypes, KM_Defaults, KM_Pics,
  KM_InterfaceGame, KM_Houses, KM_HouseMarket, KM_ResWares;

const LINE_HEIGHT = 25; //Each new Line is placed ## pixels after previous

type
  TKMGUIGameHouse = class
  private
    fAnimStep: Cardinal;
    fLastSchoolUnit: Byte;  //Last unit that was selected in School, global for all schools player owns
    fLastBarracksUnit: Byte; //Last unit that was selected in Barracks, global for all barracks player owns
    fLastTHUnit: Byte; //Last unit that was selected in Townhall, global for all townhalls player owns

    fSetViewportEvent: TPointFEvent;

    procedure Create_HouseTownhall;
    procedure Create_HouseBarracks;
    procedure Create_HouseMarket;
    procedure Create_HouseSchool;
    procedure Create_HouseStore;
    procedure Create_HouseWoodcutter;
    procedure Create_HouseArmorWorkshop;

    procedure House_Demolish(Sender: TObject; Shift: TShiftState);
    procedure House_RepairToggle(Sender: TObject);
    procedure House_OrderChange(Sender: TObject; aValue: Integer);
    procedure House_DeliveryModeToggle(Sender: TObject; Shift: TShiftState);

    procedure House_ClosedForWorkerToggle(Sender: TObject);
    procedure HandleHouseClosedForWorker(aHouse: TKMHouse);

    procedure HouseLogo_Click(Sender: TObject);

    procedure House_BarracksItemClickShift(Sender: TObject; Shift: TShiftState);
    procedure House_BarracksUnitChange(Sender: TObject; Shift: TShiftState);

    procedure House_TownHall_Change(Sender: TObject; aChangeValue: Integer);
    procedure House_TH_UnitChange(Sender: TObject; Shift: TShiftState);

    procedure House_MarketFill(aMarket: TKMHouseMarket);
    procedure House_MarketOrderClick(Sender: TObject; Shift: TShiftState);
    procedure House_MarketSelect(Sender: TObject; Shift: TShiftState);

    procedure House_SchoolUnitChange(Sender: TObject; Shift: TShiftState);
    procedure House_SchoolUnitQueueClick(Sender: TObject; Shift: TShiftState);

    procedure House_StoreItemClickShift(Sender: TObject; Shift: TShiftState);
    procedure House_StoreFill;

    procedure House_WoodcutterClick(Sender: TObject; Shift: TShiftState);
    procedure House_WoodcutterChange(Sender: TObject);
    procedure House_ArmorWSDeliveryToggle(Sender: TObject);

    procedure ShowCommonDemand(aHouse: TKMHouse; Base: Integer; var Line: Integer; var RowRes: Integer);
    procedure ShowCommonOutput(aHouse: TKMHouse; Base: Integer; var Line: Integer; var RowRes: Integer);
    procedure ShowCommonOrders(aHouse: TKMHouse; Base: Integer; var Line: Integer; var RowRes: Integer);
    procedure ShowTownHall(aHouse: TKMHouse);
    procedure ShowArmorWorkshop(aHouse: TKMHouse);

    function GetEquipAmount(Shift: TShiftState): Integer;
  protected
    Panel_House: TKMPanel;
      Label_House: TKMLabel;
      Button_HouseDeliveryMode,Button_HouseRepair: TKMButton;
      Image_House_Logo,Image_House_Worker, Image_House_Worker_Closed: TKMImage;
      Button_House_Worker: TKMButton;
      HealthBar_House: TKMPercentBar;

    Panel_House_Common: TKMPanel;
      Image_PlayerFlag: TKMImage;
      Label_Common_Demand,Label_Common_Offer,Label_Common_Costs,
      Label_House_UnderConstruction,Label_House_Demolish: TKMLabel;
      Image_HouseConstructionWood, Image_HouseConstructionStone: TKMImage;
      Label_HouseConstructionWood, Label_HouseConstructionStone: TKMLabel;
      Button_House_DemolishYes,Button_House_DemolishNo: TKMButton;
      WaresRow_Common: array [1..4] of TKMWaresRow; //4 bars is the maximum
      WareOrderRow_Order: array [1..4] of TKMWareOrderRow; //3 bars is the maximum
      CostsRow_Costs: array [1..4] of TKMCostsRow; //3 bars is the maximum
      Label_DepletedMsg: TKMLabel;

    Panel_HouseMarket: TKMPanel;
      Button_Market: array [0..STORE_RES_COUNT-1] of TKMButtonFlat;
      Shape_Market_From, Shape_Market_To: TKMShape;
      Label_Market_In, Label_Market_Out: TKMLabel;
      Button_Market_In, Button_Market_Out: TKMButtonFlat;
      Button_Market_Add,Button_Market_Remove: TKMButton;
      Label_Market_FromAmount,Label_Market_ToAmount: TKMLabel;
    Panel_HouseStore: TKMPanel;
      Button_Store: array [1..STORE_RES_COUNT] of TKMButtonFlat;
      Image_Store_NotAccept: array [1..STORE_RES_COUNT] of TKMImage;
      Image_Store_NotAllowTakeOut: array [1..STORE_RES_COUNT] of TKMImage;
    Panel_House_School: TKMPanel;
      WaresRow_School_Gold: TKMWaresRow;
      Button_School_UnitWIP: TKMButton;
      Button_School_UnitWIPBar: TKMPercentBar;
      Button_School_UnitPlan: array [1..5] of TKMButtonFlat;
      Label_School_Unit: TKMLabel;
      Image_School_Right,Image_School_Train,Image_School_Left: TKMImage;
      Button_School_Right,Button_School_Train,Button_School_Left: TKMButton;
    Panel_HouseTownHall: TKMPanel;
      Label_TH_Demand,Label_TH_Costs: TKMLabel;
      ResRow_TH_Gold: TKMWaresRow;
      ResRow_TH_MaxGold: TKMWareOrderRow;
      Label_TH_Unit: TKMLabel;
      Image_TH_Right,Image_TH_Train,Image_TH_Left: TKMImage;
      Button_TH_Right,Button_TH_Train,Button_TH_Left: TKMButton;
      CostsRow_TH_Cost: TKMCostsRow;
    Panel_HouseBarracks: TKMPanel;
      Button_Barracks: array [1..BARRACKS_RES_COUNT] of TKMButtonFlat;
      Image_Barracks_NotAccept: array [1..BARRACKS_RES_COUNT] of TKMImage;
      Image_Barracks_NotAllowTakeOut: array [1..BARRACKS_RES_COUNT] of TKMImage;
      Button_BarracksRecruit: TKMButtonFlat;
      Image_Barracks_NotAcceptRecruit: TKMImage;
      Label_Barracks_Unit: TKMLabel;
      Image_Barracks_Right, Image_Barracks_Train, Image_Barracks_Left: TKMImage;
      Button_Barracks_Right, Button_Barracks_Train, Button_Barracks_Left: TKMButton;
    Panel_HouseWoodcutter: TKMPanel;
      Radio_Woodcutter: TKMRadioGroup;
      Button_Woodcutter: TKMButtonFlat;
    Panel_HouseArmorWorkshop: TKMPanel;
      Label_ArmorWS_Demand: TKMLabel;
      WaresRow_ArmorWS_Common: array [1..2] of TKMWaresRow; //2 bars
      Image_ArmorWS_Accept: array [1..2] of TKMImage;
  public
    AskDemolish: Boolean;
    OnHouseDemolish: TNotifyEventShift;

    constructor Create(aParent: TKMPanel; aSetViewportEvent: TPointFEvent);

    procedure Show(aHouse: TKMHouse); overload;
    procedure Show(aHouse: TKMHouse; aAskDemolish: Boolean); overload;
    procedure Hide;
    function Visible: Boolean;

    procedure KeyDown(Key: Word; aShift: TShiftState; var aHandled: Boolean);

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

    procedure UpdateHotkeys;
  end;


implementation
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  KM_Game, KM_GameInputProcess, KM_Hand,
  KM_InterfaceTypes,
  KM_HouseBarracks, KM_HouseSchool, KM_HouseTownHall, KM_HouseWoodcutters, KM_HouseStore, KM_HouseArmorWorkshop,
  KM_HandsCollection, KM_RenderUI, KM_ResKeys,
  KM_Resource, KM_ResFonts, KM_ResHouses, KM_ResTexts, KM_ResUnits, KM_Utils, KM_UtilsExt, KM_Points,
  KM_ResTypes;

const
  MAX_UNITS_TO_EQUIP = 100;
  HOUSE_FLAG_TEX_ID = 1159;
  HOUSE_FLAG_TEX_ID_FRAME = 5;
  HOUSE_ORDER_ROW_MOUSEWHEEL_STEP = 5;

  SCHOOL_CH_ORDER_TO_0_SHIFT = ssCtrl; // Shift state to change Unit order in queue to 0 in School
  SCHOOL_CH_ORDER_TO_1_SHIFT = ssAlt;  // Shift state to change Unit order in queue to 1 in School


constructor TKMGUIGameHouse.Create(aParent: TKMPanel; aSetViewportEvent: TPointFEvent);
var
  I: Integer;
begin
  inherited Create;

  fSetViewportEvent := aSetViewportEvent;
  fAnimStep := 0;

  Panel_House := TKMPanel.Create(aParent, TB_PAD, 44, TB_WIDTH, 332);
    //Thats common things
    //Custom things come in fixed size blocks (more smaller Panels?), and to be shown upon need
    Image_PlayerFlag := TKMImage.Create(Panel_House, 0, 17, 20, 13, 1159, rxHouses); // before house name label
    Label_House := TKMLabel.Create(Panel_House, 0, 14, TB_WIDTH, 0, '', fntOutline, taCenter);
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
    Image_House_Logo.HighlightOnMouseOver := True;
    Image_House_Logo.OnClick := HouseLogo_Click;
    Image_House_Logo.Hint := gResTexts[TX_HOUSE_LOGO_HINT];

    HealthBar_House := TKMPercentBar.Create(Panel_House,120,50,55,15);
    Label_House_UnderConstruction := TKMLabel.Create(Panel_House,0,110,TB_WIDTH,0,gResTexts[TX_HOUSE_UNDER_CONSTRUCTION],fntGrey,taCenter);

    Image_HouseConstructionWood  := TKMImage.Create(Panel_House,40,170,40,40,655);
    Image_HouseConstructionWood.ImageCenter;
    Image_HouseConstructionStone := TKMImage.Create(Panel_House,100,170,40,40,654);
    Image_HouseConstructionStone.ImageCenter;
    Label_HouseConstructionWood  := TKMLabel.Create(Panel_House,60,210,gResWares[wtTimber].Title,fntGrey,taCenter);
    Label_HouseConstructionStone := TKMLabel.Create(Panel_House,120,210,gResWares[wtStone].Title,fntGrey,taCenter);

    Label_House_Demolish := TKMLabel.Create(Panel_House,0,130,TB_WIDTH,0,gResTexts[TX_HOUSE_DEMOLISH],fntGrey,taCenter);
    Label_House_Demolish.WordWrap := True;
    Button_House_DemolishYes := TKMButton.Create(Panel_House,0,185,TB_WIDTH,30,gResTexts[TX_HOUSE_DEMOLISH_YES],bsGame);
    Button_House_DemolishNo  := TKMButton.Create(Panel_House,0,220,TB_WIDTH,30,gResTexts[TX_HOUSE_DEMOLISH_NO],bsGame);
    Button_House_DemolishYes.Hint := gResTexts[TX_HOUSE_DEMOLISH_YES_HINT];
    Button_House_DemolishNo.Hint  := gResTexts[TX_HOUSE_DEMOLISH_NO];
    Button_House_DemolishYes.OnClickShift := House_Demolish;
    Button_House_DemolishNo.OnClickShift  := House_Demolish;

    Panel_House_Common := TKMPanel.Create(Panel_House,0,76,200,310);
      Label_Common_Demand := TKMLabel.Create(Panel_House_Common,0,2,TB_WIDTH,0,gResTexts[TX_HOUSE_NEEDS],fntGrey,taCenter);
      Label_Common_Offer  := TKMLabel.Create(Panel_House_Common,0,2,TB_WIDTH,0,'',fntGrey,taCenter);
      Label_Common_Costs  := TKMLabel.Create(Panel_House_Common,0,2,TB_WIDTH,0,gResTexts[TX_HOUSE_WARE_COSTS],fntGrey,taCenter);

      //They get repositioned on display
      for I := 1 to 4 do
      begin
        WaresRow_Common[I] := TKMWaresRow.Create(Panel_House_Common, 0, 0, TB_WIDTH);
        WaresRow_Common[I].RX := rxGui;

        WareOrderRow_Order[I] := TKMWareOrderRow.Create(Panel_House_Common, 0, 0, TB_WIDTH, 999);
        WareOrderRow_Order[I].MouseWheelStep := HOUSE_ORDER_ROW_MOUSEWHEEL_STEP;
        WareOrderRow_Order[I].WareRow.RX := rxGui;
        WareOrderRow_Order[I].OnChange := House_OrderChange;
        WareOrderRow_Order[I].OrderRemHint := gResTexts[TX_HOUSE_ORDER_DEC_HINT];
        WareOrderRow_Order[I].OrderAddHint := gResTexts[TX_HOUSE_ORDER_INC_HINT];

        CostsRow_Costs[I] := TKMCostsRow.Create(Panel_House_Common, 0, 0, TB_WIDTH, 21);
        CostsRow_Costs[I].RX := rxGui;

        Label_DepletedMsg := TKMLabel.Create(Panel_House_Common,0,0,TB_WIDTH,0,'',fntGrey,taLeft);
        Label_DepletedMsg.WordWrap := True;
        Label_DepletedMsg.Hide;
      end;

  Create_HouseMarket;
  Create_HouseStore;
  Create_HouseSchool;
  Create_HouseBarracks;
  Create_HouseTownhall;
  Create_HouseWoodcutter;
  Create_HouseArmorWorkshop;
end;


// Market page
procedure TKMGUIGameHouse.Create_HouseMarket;
var
  I: Integer;
  lineH: Integer;
begin
  Panel_HouseMarket := TKMPanel.Create(Panel_House, 0, 76, TB_WIDTH, 266);

  for I := 0 to STORE_RES_COUNT - 1 do
  begin
    Button_Market[I] := TKMButtonFlat.Create(Panel_HouseMarket, (I mod 6)*31, 12 + (I div 6) * MARKET_RES_HEIGHT, 26, 31, 0);
    Button_Market[I].TexOffsetY := 1;
    Button_Market[I].TexID := gResWares[StoreResType[I+1]].GUIIcon;
    Button_Market[I].Hint := gResWares[StoreResType[I+1]].Title;
    Button_Market[I].Tag := Byte(StoreResType[I+1]);
    Button_Market[I].OnClickShift := House_MarketSelect;
  end;

  Shape_Market_From := TKMShape.Create(Panel_HouseMarket, 0, 0, 26, 30);
  Shape_Market_From.LineColor := $FF00B000;
  Shape_Market_From.LineWidth := 2;
  Shape_Market_From.Hitable := False;
  Shape_Market_From.Hide;
  Shape_Market_To := TKMShape.Create(Panel_HouseMarket, 0, 0, 26, 30);
  Shape_Market_To.LineColor := $FF0000B0;
  Shape_Market_To.LineWidth := 2;
  Shape_Market_To.Hitable := False;
  Shape_Market_To.Hide;

  lineH := 12 + ((STORE_RES_COUNT - 1) div 6 + 1) * MARKET_RES_HEIGHT;
  Label_Market_In  := TKMLabel.Create(Panel_HouseMarket, 0,lineH,85,0,'',fntGrey,taLeft);
  Label_Market_Out := TKMLabel.Create(Panel_HouseMarket, TB_WIDTH - 85,lineH,85,0,'',fntGrey,taRight);

  Inc(lineH, 20);
  Button_Market_In  := TKMButtonFlat.Create(Panel_HouseMarket,  0, lineH, 36, 40, 0);
  Button_Market_In.HideHighlight := True;
  Button_Market_In.Clickable := False;
  Button_Market_In.Hint := gResTexts[TX_HOUSES_MARKET_SELECT_LEFT];
  Button_Market_Out := TKMButtonFlat.Create(Panel_HouseMarket, TB_WIDTH - 36, lineH, 36, 40, 0);
  Button_Market_Out.HideHighlight := True;
  Button_Market_Out.Clickable := False;
  Button_Market_Out.Hint := gResTexts[TX_HOUSES_MARKET_SELECT_RIGHT];

  with TKMShape.Create(Panel_HouseMarket,  0, lineH, 36, 40) do
  begin
    LineColor := $FF00B000;
    LineWidth := 2;
    Hitable := False;
  end;
  with TKMShape.Create(Panel_HouseMarket, TB_WIDTH - 36, lineH, 36, 40) do
  begin
    LineColor := $FF0000B0;
    LineWidth := 2;
    Hitable := False;
  end;

  Inc(lineH, 10);

  Button_Market_Remove := TKMButton.Create(Panel_HouseMarket, TB_WIDTH div 2 - 20, lineH, 20, 20, '-', bsGame);
  Button_Market_Remove.Hint := gResTexts[TX_HOUSES_MARKET_HINT_REM];
  Button_Market_Remove.OnClickShift := House_MarketOrderClick;

  Button_Market_Add := TKMButton.Create(Panel_HouseMarket, TB_WIDTH div 2, lineH, 20, 20, '+', bsGame);
  Button_Market_Add.Hint := gResTexts[TX_HOUSES_MARKET_HINT_ADD];
  Button_Market_Add.OnClickShift := House_MarketOrderClick;

  Label_Market_FromAmount := TKMLabel.Create(Panel_HouseMarket,  53, lineH, '', fntGrey, taCenter);
  Label_Market_ToAmount   := TKMLabel.Create(Panel_HouseMarket, 127, lineH, '', fntGrey, taCenter);
end;


// Store page
procedure TKMGUIGameHouse.Create_HouseStore;
var
  I: Integer;
  dX, dY: Integer;
begin
  Panel_HouseStore := TKMPanel.Create(Panel_House, 0, 76, TB_WIDTH, 266);
  for I := 1 to STORE_RES_COUNT do
  begin
    dX := 2 + ((I - 1) mod 5) * 36;
    dY := 19 + ((I - 1) div 5) * 42;
    Button_Store[I] := TKMButtonFlat.Create(Panel_HouseStore, dX, dY, 32, 36, 0);
    Button_Store[I].TexID := gResWares[StoreResType[I]].GUIIcon;
    Button_Store[I].Tag := I;
    Button_Store[I].Hint := gResWares[StoreResType[I]].Title;
    Button_Store[I].OnClickShift := House_StoreItemClickShift;

    Image_Store_NotAccept[I] := TKMImage.Create(Panel_HouseStore, dX + 20, dY, 12, 12, 49);
    Image_Store_NotAccept[I].Hitable := False;
    Image_Store_NotAccept[I].Hint := Format(gResTexts[TX_HOUSE_DELIVERY_PROHIBITED_HINT], [gRes.Wares[StoreResType[I]].Title]);

    Image_Store_NotAllowTakeOut[I] := TKMImage.Create(Panel_HouseStore, dX, dY, 12, 12, 676);
    Image_Store_NotAllowTakeOut[I].Hitable := False;
    Image_Store_NotAllowTakeOut[I].Hint := Format(gResTexts[TX_HOUSE_TAKEOUT_PROHIBITED_HINT], [gRes.Wares[StoreResType[I]].Title]);
  end;
end;


// School page
procedure TKMGUIGameHouse.Create_HouseSchool;
var
  I: Integer;
begin
  Panel_House_School := TKMPanel.Create(Panel_House, 0, 76, TB_WIDTH, 266);

    TKMLabel.Create(Panel_House_School,0,2,TB_WIDTH,30,gResTexts[TX_HOUSE_NEEDS],fntGrey,taCenter);

    WaresRow_School_Gold := TKMWaresRow.Create(Panel_House_School, 0, 21, TB_WIDTH);
    WaresRow_School_Gold.RX := rxGui;
    WaresRow_School_Gold.TexID := gResWares[wtGold].GUIIcon;
    WaresRow_School_Gold.Caption := gResWares[wtGold].Title;
    WaresRow_School_Gold.Hint := gResWares[wtGold].Title;

    Button_School_UnitWIP := TKMButton.Create(Panel_House_School,  0,48,32,32,0, rxGui, bsGame);
    Button_School_UnitWIP.Hint := gResTexts[TX_HOUSE_SCHOOL_WIP_HINT];
    Button_School_UnitWIP.Tag := 0;
    Button_School_UnitWIP.OnClickShift := House_SchoolUnitQueueClick;
    Button_School_UnitWIPBar := TKMPercentBar.Create(Panel_House_School,34,54,146,20);
    for I := 1 to 5 do
    begin
      Button_School_UnitPlan[i] := TKMButtonFlat.Create(Panel_House_School, (I-1) * 36, 80, 32, 32, 0);
      Button_School_UnitPlan[i].Tag := I;
      Button_School_UnitPlan[i].OnClickShift := House_SchoolUnitQueueClick;
    end;

    Label_School_Unit := TKMLabel.Create(Panel_House_School,   0,116,TB_WIDTH,30,'',fntOutline,taCenter);
    Image_School_Left := TKMImage.Create(Panel_House_School,   0,136,54,80,521);
    Image_School_Train := TKMImage.Create(Panel_House_School, 62,136,54,80,522);
    Image_School_Right := TKMImage.Create(Panel_House_School,124,136,54,80,523);
    Image_School_Left.Disable;
    Image_School_Right.Disable;
    Button_School_Left  := TKMButton.Create(Panel_House_School,  0,222,54,40,35, rxGui, bsGame);
    Button_School_Train := TKMButton.Create(Panel_House_School, 62,222,54,40,42, rxGui, bsGame);
    Button_School_Right := TKMButton.Create(Panel_House_School,124,222,54,40,36, rxGui, bsGame);
    Button_School_Left.OnClickShift  := House_SchoolUnitChange;
    Button_School_Train.OnClickShift := House_SchoolUnitChange;
    Button_School_Right.OnClickShift := House_SchoolUnitChange;

end;


// Barracks page
procedure TKMGUIGameHouse.Create_HouseTownhall;
var
  dy: Integer;
begin
  Panel_HouseTownhall := TKMPanel.Create(Panel_House, 0, 76, TB_WIDTH, 266);

    dy := 8;
//    Label_TH_Demand := TKMLabel.Create(Panel_HouseTownhall,0,dy,TB_WIDTH,0,gResTexts[TX_HOUSE_NEEDS],fntGrey,taCenter);
//    Inc(dy, 19);
    ResRow_TH_Gold := TKMWaresRow.Create(Panel_HouseTownhall, 0, dy, TB_WIDTH);
    ResRow_TH_Gold.RX := rxGui;
    ResRow_TH_Gold.TexID := gResWares[wtGold].GUIIcon;
    ResRow_TH_Gold.Caption := gResWares[wtGold].Title;
    ResRow_TH_Gold.Hint := gResWares[wtGold].Title;
    ResRow_TH_Gold.WareCntAsNumber := True;

    Inc(dy, 25);

    ResRow_TH_MaxGold := TKMWareOrderRow.Create(Panel_HouseTownhall, 0, dy, TB_WIDTH, TH_MAX_GOLDMAX_VALUE);
    ResRow_TH_MaxGold.MouseWheelStep := HOUSE_ORDER_ROW_MOUSEWHEEL_STEP;
    ResRow_TH_MaxGold.WareRow.RX := rxGui;
    ResRow_TH_MaxGold.WareRow.TexID := gResWares[wtGold].GUIIcon;
    ResRow_TH_MaxGold.WareRow.Caption := gResTexts[TX_HOUSES_TOWNHALL_MAX_GOLD];
    ResRow_TH_MaxGold.WareRow.WareCount := 1;
    ResRow_TH_MaxGold.Hint := gResTexts[TX_HOUSES_TOWNHALL_MAX_GOLD_HINT];
    ResRow_TH_MaxGold.OnChange := House_TownHall_Change;
    Inc(dy, 29);

    Label_TH_Unit := TKMLabel.Create(Panel_HouseTownhall, 0, dy, TB_WIDTH, 0, '', fntOutline, taCenter);
    Inc(dy, 20);

    Image_TH_Left  := TKMImage.Create(Panel_HouseTownhall,  0,dy,54,80,535);
    Image_TH_Left.Disable;
    Image_TH_Train := TKMImage.Create(Panel_HouseTownhall, 62,dy,54,80,536);
    Image_TH_Right := TKMImage.Create(Panel_HouseTownhall,124,dy,54,80,537);
    Image_TH_Right.Disable;
    Inc(dy, 106);

    Button_TH_Left  := TKMButton.Create(Panel_HouseTownhall,  0,dy,54,40,35, rxGui, bsGame);
    Button_TH_Train := TKMButton.Create(Panel_HouseTownhall, 62,dy,54,40,42, rxGui, bsGame);
    Button_TH_Right := TKMButton.Create(Panel_HouseTownhall,124,dy,54,40,36, rxGui, bsGame);
    Button_TH_Left.OnClickShift := House_TH_UnitChange;
    Button_TH_Train.OnClickShift := House_TH_UnitChange;
    Button_TH_Right.OnClickShift := House_TH_UnitChange;
    Button_TH_Train.Disable;

    Inc(dy, 46);
    Label_TH_Costs  := TKMLabel.Create(Panel_HouseTownhall,0,dy,TB_WIDTH,0,gResTexts[TX_HOUSE_WARE_COSTS],fntGrey,taCenter);
    Inc(dy, 20);
    CostsRow_TH_Cost := TKMCostsRow.Create(Panel_HouseTownhall, 0, dy, TB_WIDTH, 21);
    CostsRow_TH_Cost.RX := rxGui;
    CostsRow_TH_Cost.Visible := True;
    CostsRow_TH_Cost.Caption := gResWares[wtGold].Title;
    CostsRow_TH_Cost.TexID1 := gResWares[wtGold].GUIIcon;
end;


{Barracks page}
procedure TKMGUIGameHouse.Create_HouseBarracks;
var
  I: Integer;
  dX, dY: Integer;
begin
  Panel_HouseBarracks := TKMPanel.Create(Panel_House, 0, 76, TB_WIDTH, 266);
    for I := 1 to BARRACKS_RES_COUNT do
    begin
      dX := ((I - 1) mod 6) * 31;
      dY := 8 + ((I - 1) div 6) * 42;
      Button_Barracks[I] := TKMButtonFlat.Create(Panel_HouseBarracks, dX, dY, 28, 38, 0);
      Button_Barracks[I].TexOffsetX := 1;
      Button_Barracks[I].TexOffsetY := 1;
      Button_Barracks[I].CapOffsetY := 2;
      Button_Barracks[I].Tag := I;
      Button_Barracks[I].TexID := gResWares[BarracksResType[I]].GUIIcon;
      Button_Barracks[I].Hint := gResWares[BarracksResType[I]].Title;
      Button_Barracks[I].OnClickShift := House_BarracksItemClickShift;

      Image_Barracks_NotAccept[I] := TKMImage.Create(Panel_HouseBarracks, dX+16, dY, 12, 12, 49);
      Image_Barracks_NotAccept[I].Hitable := False;
      Image_Barracks_NotAccept[I].Hint := Format(gResTexts[TX_HOUSE_DELIVERY_PROHIBITED_HINT], [gRes.Wares[BarracksResType[I]].Title]);
      Image_Barracks_NotAllowTakeOut[I] := TKMImage.Create(Panel_HouseBarracks, dX, dY, 12, 12, 676);
      Image_Barracks_NotAllowTakeOut[I].Hitable := False;
      Image_Barracks_NotAllowTakeOut[I].Hint := Format(gResTexts[TX_HOUSE_TAKEOUT_PROHIBITED_HINT], [gRes.Wares[BarracksResType[I]].Title]);
    end;

    dX := (BARRACKS_RES_COUNT mod 6) * 31;
    dY := 8 + (BARRACKS_RES_COUNT div 6) * 42;
    Button_BarracksRecruit := TKMButtonFlat.Create(Panel_HouseBarracks, dX, dY, 28, 38, 0);
    Button_BarracksRecruit.TexOffsetX := 1;
    Button_BarracksRecruit.TexOffsetY := 1;
    Button_BarracksRecruit.CapOffsetY := 2;
    Button_BarracksRecruit.TexID := gRes.Units[utRecruit].GUIIcon;
    Button_BarracksRecruit.Hint := gRes.Units[utRecruit].GUIName;
    Button_BarracksRecruit.OnClickShift := House_BarracksItemClickShift;
    Image_Barracks_NotAcceptRecruit := TKMImage.Create(Panel_HouseBarracks, dX+16, dY, 12, 12, 49);
    Image_Barracks_NotAcceptRecruit.Hitable := False;
    Image_Barracks_NotAcceptRecruit.Hint := gResTexts[TX_HOUSE_BARRACKS_NOT_ACCEPT_RECRUIT_HINT];

    Label_Barracks_Unit := TKMLabel.Create(Panel_HouseBarracks, 0, 96, TB_WIDTH, 0, '', fntOutline, taCenter);

    Image_Barracks_Left  := TKMImage.Create(Panel_HouseBarracks,  0,116,54,80,535);
    Image_Barracks_Left.Disable;
    Image_Barracks_Train := TKMImage.Create(Panel_HouseBarracks, 62,116,54,80,536);
    Image_Barracks_Right := TKMImage.Create(Panel_HouseBarracks,124,116,54,80,537);
    Image_Barracks_Right.Disable;

    Button_Barracks_Left  := TKMButton.Create(Panel_HouseBarracks,  0,222,54,40,35, rxGui, bsGame);
    Button_Barracks_Train := TKMButton.Create(Panel_HouseBarracks, 62,222,54,40,42, rxGui, bsGame);
    Button_Barracks_Right := TKMButton.Create(Panel_HouseBarracks,124,222,54,40,36, rxGui, bsGame);
    Button_Barracks_Left.OnClickShift := House_BarracksUnitChange;
    Button_Barracks_Train.OnClickShift := House_BarracksUnitChange;
    Button_Barracks_Right.OnClickShift := House_BarracksUnitChange;

    Button_Barracks_Train.Disable;
end;


{Woodcutter page}
procedure TKMGUIGameHouse.Create_HouseWoodcutter;
begin
  Panel_HouseWoodcutter := TKMPanel.Create(Panel_House,TB_PAD,76,TB_WIDTH,266);
    Button_Woodcutter := TKMButtonFlat.Create(Panel_HouseWoodcutter,0,64,32,32,51,rxGui);
    Button_Woodcutter.OnClickShift := House_WoodcutterClick; //Clicking the button cycles it

    Radio_Woodcutter := TKMRadioGroup.Create(Panel_HouseWoodcutter,38,64,TB_WIDTH - 38,48,fntGrey);
    Radio_Woodcutter.ItemIndex := 0;
    Radio_Woodcutter.Add(gResTexts[TX_HOUSES_WOODCUTTER_PLANT_CHOP]);
    Radio_Woodcutter.Add(gResTexts[TX_HOUSES_WOODCUTTER_CHOP_ONLY]);
    Radio_Woodcutter.Add(gResTexts[TX_HOUSES_WOODCUTTER_PLANT_ONLY]);
    Radio_Woodcutter.OnChange := House_WoodcutterChange;
end;


{ArmorWorkshop page}
procedure TKMGUIGameHouse.Create_HouseArmorWorkshop;
var
  I: Integer;
begin
  // Panel should cover only 3 lines, to let common panel handle mouse events
  Panel_HouseArmorWorkshop := TKMPanel.Create(Panel_House, 0, 76, TB_WIDTH, LINE_HEIGHT*3);
    Label_ArmorWS_Demand := TKMLabel.Create(Panel_HouseArmorWorkshop,0,2,TB_WIDTH,0,gResTexts[TX_HOUSE_NEEDS],fntGrey,taCenter);

    //They get repositioned on display
    for I := 1 to 2 do
    begin
      WaresRow_ArmorWS_Common[I] := TKMWaresRow.Create(Panel_HouseArmorWorkshop, 0, 0, TB_WIDTH, True);
      WaresRow_ArmorWS_Common[I].RX := rxGui;
      WaresRow_ArmorWS_Common[I].OnClick := House_ArmorWSDeliveryToggle;
      WaresRow_ArmorWS_Common[I].Tag := I;
      Image_ArmorWS_Accept[I] := TKMImage.Create(Panel_HouseArmorWorkshop, TB_WIDTH - 12, 2+I*LINE_HEIGHT, 12, 12, 49);
      Image_ArmorWS_Accept[I].Hitable := False;
    end;
end;

procedure TKMGUIGameHouse.Show(aHouse: TKMHouse);
begin
  Show(aHouse, AskDemolish);
end;


procedure TKMGUIGameHouse.Show(aHouse: TKMHouse; aAskDemolish: Boolean);
const
  DO_NOT_DISABLE_CTRLS: array[0..1] of TKMControlClass = (TKMLabel, TKMImage);
var
  I, rowRes, base, line, hLabelWidth: Integer;
begin
  AskDemolish := aAskDemolish;

  Inc(fAnimStep);
  Image_PlayerFlag.TexID := HOUSE_FLAG_TEX_ID + fAnimStep mod HOUSE_FLAG_TEX_ID_FRAME;

  //Hide all House sub-pages
  for I := 0 to Panel_House.ChildCount - 1 do
    if Panel_House.Childs[I] is TKMPanel then
      Panel_House.Childs[I].Hide;

  Panel_House.SetCanChangeEnable(gMySpectator.IsSelectedMyObj, DO_NOT_DISABLE_CTRLS);

  if aHouse = nil then
  begin
    Hide;
    Exit;
  end;

  {Common data}
  Label_House.Caption        := gResHouses[aHouse.HouseType].HouseName;
  //Calc House caption position
  hLabelWidth := gRes.Fonts[fntOutline].GetTextSize(Label_House.Caption).X;
  if hLabelWidth <= TB_WIDTH - 2*Image_PlayerFlag.Width then
    Label_House.Left := 0
  else if hLabelWidth <= TB_WIDTH - Image_PlayerFlag.Width then
    Label_House.Left := Image_PlayerFlag.Width
  else
    Label_House.Left := Max(TB_WIDTH - hLabelWidth, 0);

  Label_House.Width := TB_WIDTH - Label_House.Left;

  Image_PlayerFlag.FlagColor := gHands[aHouse.Owner].FlagColor;
  Image_PlayerFlag.Hint      := Format(gResTexts[TX_PLAYER_FLAG_HINT], [gHands[aHouse.Owner].OwnerName]);
  Image_House_Logo.TexID     := gResHouses[aHouse.HouseType].GUIIcon;
  Image_House_Worker.TexID   := gRes.Units[gResHouses[aHouse.HouseType].WorkerType].GUIIcon;
  Image_House_Worker.Hint    := gRes.Units[gResHouses[aHouse.HouseType].WorkerType].GUIName;
  Image_House_Worker.FlagColor := gHands[aHouse.Owner].FlagColor;

  Button_House_Worker.TexID  := gRes.Units[gResHouses[aHouse.HouseType].WorkerType].GUIIcon;
  HandleHouseClosedForWorker(aHouse);
  Button_House_Worker.Hint := Format(gResTexts[TX_HOUSES_CLOSED_FOR_WORKER_HINT], [gRes.Units[gRes.Houses[aHouse.HouseType].WorkerType].GUIName]);
  Button_House_Worker.FlagColor := gHands[aHouse.Owner].FlagColor;

  HealthBar_House.Caption   := IntToStr(round(aHouse.GetHealth)) + '/' + IntToStr(gResHouses[aHouse.HouseType].MaxHealth);
  HealthBar_House.Position  := aHouse.GetHealth / gResHouses[aHouse.HouseType].MaxHealth;

  if AskDemolish then
  begin
    for I := 0 to Panel_House.ChildCount - 1 do
      Panel_House.Childs[I].Hide; //hide all
    Label_House_Demolish.Show;
    Button_House_DemolishYes.Show;
    Button_House_DemolishNo.Show;
    Label_House.Show;
    Image_PlayerFlag.Show;
    Image_House_Logo.Show;
    Image_House_Worker.Show;
    Button_House_Worker.Hide;
    HealthBar_House.Show;
    Panel_House.Show;
    Exit;
  end;

  if not aHouse.IsComplete then
  begin
    for I := 0 to Panel_House.ChildCount - 1 do
      Panel_House.Childs[I].Hide; //hide all
    Label_House_UnderConstruction.Show;
    Image_HouseConstructionWood.Show;
    Image_HouseConstructionStone.Show;
    Label_HouseConstructionWood.Show;
    Label_HouseConstructionStone.Show;
    Label_HouseConstructionWood.Caption := IntToStr(aHouse.GetBuildWoodDelivered) + ' / ' + IntToStr(gResHouses[aHouse.HouseType].WoodCost);
    Label_HouseConstructionStone.Caption := IntToStr(aHouse.GetBuildStoneDelivered) + ' / ' + IntToStr(gResHouses[aHouse.HouseType].StoneCost);
    Label_House.Show;
    Image_PlayerFlag.Show;
    Image_House_Logo.Show;
    Image_House_Worker.Visible := gResHouses[aHouse.HouseType].CanHasWorker;
    Button_House_Worker.Hide;
    HealthBar_House.Show;
    Panel_House.Show;
    Exit;
  end;

  Image_House_Worker.Hide;
  Button_House_Worker.Visible := gResHouses[aHouse.HouseType].CanHasWorker;

  Button_HouseDeliveryMode.Enabled := aHouse.AllowDeliveryModeChange;
  Button_HouseDeliveryMode.Show;
  Button_HouseRepair.Show;

  Button_HouseRepair.TexID := IfThen(aHouse.BuildingRepair, 39, 40);

  case aHouse.NewDeliveryMode of //Use NewDeliveryMode, as it is supposed to be in UI, instead of DeliveryMode
    dmDelivery: Button_HouseDeliveryMode.TexID := 37;
    dmClosed:   Button_HouseDeliveryMode.TexID := 38;
    dmTakeOut:  Button_HouseDeliveryMode.TexID := 664;
  end;

  Label_House_UnderConstruction.Hide;
  Image_HouseConstructionWood.Hide;
  Image_HouseConstructionStone.Hide;
  Label_HouseConstructionWood.Hide;
  Label_HouseConstructionStone.Hide;
  Label_House_Demolish.Hide;
  Button_House_DemolishYes.Hide;
  Button_House_DemolishNo.Hide;
  Panel_House.Show;

  case aHouse.HouseType of
    htMarket:
        begin
          House_MarketFill(TKMHouseMarket(aHouse));
          Panel_HouseMarket.Show;
        end;

    htStore:
        begin
          House_StoreFill;
          Panel_HouseStore.Show;
        end;

    htSchool:
        begin
          WaresRow_School_Gold.WareCount := aHouse.CheckResIn(wtGold) - Byte(TKMHouseSchool(aHouse).HideOneGold);
          Button_School_UnitWIP.FlagColor := gHands[aHouse.Owner].FlagColor;
          for I := 1 to 5 do
            Button_School_UnitPlan[I].FlagColor := gHands[aHouse.Owner].FlagColor;
          Image_School_Left.FlagColor  := gHands[aHouse.Owner].FlagColor;
          Image_School_Right.FlagColor := gHands[aHouse.Owner].FlagColor;
          Image_School_Train.FlagColor := gHands[aHouse.Owner].FlagColor;
          House_SchoolUnitChange(nil, []);
          Panel_House_School.Show;
        end;

    htBarracks:
        begin
          House_BarracksUnitChange(nil, []);
          Panel_HouseBarracks.Show;
        end;

    htWoodcutters:
        begin
          House_WoodcutterChange(nil);
          Panel_HouseWoodcutter.Show;

          //First thing - hide everything
          for I := 0 to Panel_House_Common.ChildCount - 1 do
            Panel_House_Common.Childs[I].Hide;

          Label_Common_Offer.Show;
          Label_Common_Offer.Caption := gResTexts[TX_HOUSE_DELIVERS]+'(x'+inttostr(gResHouses[aHouse.HouseType].ResProductionX)+'):';
          Label_Common_Offer.Top := 8;

          WaresRow_Common[1].TexID := gResWares[gResHouses[aHouse.HouseType].ResOutput[1]].GUIIcon;
          WaresRow_Common[1].WareCount := aHouse.CheckResOut(gResHouses[aHouse.HouseType].ResOutput[1]);
          WaresRow_Common[1].Caption := gResWares[gResHouses[aHouse.HouseType].ResOutput[1]].Title;
          WaresRow_Common[1].Hint := gResWares[gResHouses[aHouse.HouseType].ResOutput[1]].Title;
          WaresRow_Common[1].Show;
          WaresRow_Common[1].Top := 2 + LINE_HEIGHT;

          Label_DepletedMsg.Top := Radio_Woodcutter.Bottom + 5;
          Label_DepletedMsg.Visible := aHouse.ResourceDepleted;
          if aHouse.ResourceDepleted then
            Label_DepletedMsg.Caption := gResTexts[aHouse.GetResourceDepletedMessageId];
        end;
    htArmorWorkshop: ShowArmorWorkshop(aHouse);
    htTownHall:      ShowTownHall(aHouse);
    else
        begin
          //First thing - hide everything
          for I := 0 to Panel_House_Common.ChildCount - 1 do
            Panel_House_Common.Childs[I].Hide;

          //Now show only what we need
          rowRes := 1;
          line := 0;
          base := 2;

          //Show Demand
          ShowCommonDemand(aHouse, base, line, rowRes);

          //Show Output
          ShowCommonOutput(aHouse, base, line, rowRes);

          //Show Orders
          ShowCommonOrders(aHouse, base, line, rowRes);

          Panel_House_Common.Show;
        end;
  end;
end;


procedure TKMGUIGameHouse.ShowCommonDemand(aHouse: TKMHouse; Base: Integer; var Line, RowRes: Integer);
var
  I: Integer;
  hSpec: TKMHouseSpec;
begin
  hSpec := gResHouses[aHouse.HouseType];

  //Show Demand
  if hSpec.AcceptsWares then
  begin
    Label_Common_Demand.Show;
    Label_Common_Demand.Top := Base+Line*LINE_HEIGHT+6;
    Inc(Line);

    for I := 1 to 4 do
      if gResWares[hSpec.ResInput[I]].IsValid then
      begin
        WaresRow_Common[RowRes].TexID := gResWares[hSpec.ResInput[I]].GUIIcon;
        WaresRow_Common[RowRes].Caption := gResWares[hSpec.ResInput[I]].Title;
        WaresRow_Common[RowRes].Hint := gResWares[hSpec.ResInput[I]].Title;
        WaresRow_Common[RowRes].WareCount := aHouse.CheckResIn(hSpec.ResInput[I]);
        WaresRow_Common[RowRes].Top := Base + Line * LINE_HEIGHT;
        WaresRow_Common[RowRes].Show;
        Inc(Line);
        Inc(RowRes);
      end;
  end;
end;


procedure TKMGUIGameHouse.ShowCommonOutput(aHouse: TKMHouse; Base: Integer; var Line, RowRes: Integer);
var
  I: Integer;
  hSpec: TKMHouseSpec;
begin
  hSpec := gResHouses[aHouse.HouseType];

  //Show Output
  if not hSpec.DoesOrders then
    if hSpec.ProducesWares then
    begin
      Label_Common_Offer.Show;
      Label_Common_Offer.Caption := gResTexts[TX_HOUSE_DELIVERS] + '(x' + IntToStr(hSpec.ResProductionX) + '):';
      Label_Common_Offer.Top := Base+Line * LINE_HEIGHT + 6;
      Inc(Line);

      for I := 1 to 4 do
      if gResWares[hSpec.ResOutput[I]].IsValid then
      begin
        WaresRow_Common[RowRes].TexID     := gResWares[hSpec.ResOutput[I]].GUIIcon;
        WaresRow_Common[RowRes].WareCount := aHouse.CheckResOut(hSpec.ResOutput[I]);
        WaresRow_Common[RowRes].Caption   := gResWares[hSpec.ResOutput[I]].Title;
        WaresRow_Common[RowRes].Hint      := gResWares[hSpec.ResOutput[I]].Title;
        WaresRow_Common[RowRes].Show;
        WaresRow_Common[RowRes].Top       := Base + Line * LINE_HEIGHT;
        Inc(Line);
        Inc(RowRes);
      end;

      Label_DepletedMsg.Top := Base + Line * LINE_HEIGHT + 5;
      Label_DepletedMsg.Visible := aHouse.ResourceDepleted;
      if aHouse.ResourceDepleted then
        Label_DepletedMsg.Caption := gResTexts[aHouse.GetResourceDepletedMessageId];
    end;
end;


procedure TKMGUIGameHouse.ShowCommonOrders(aHouse: TKMHouse; Base: Integer; var Line, RowRes: Integer);
var
  I: Integer;
  W: TKMWareType;
begin
  //Show Orders
  if gResHouses[aHouse.HouseType].DoesOrders then
  begin
    Label_Common_Offer.Show;
    Label_Common_Offer.Caption := gResTexts[TX_HOUSE_DELIVERS] + '(x' + IntToStr(gResHouses[aHouse.HouseType].ResProductionX) + '):';
    Label_Common_Offer.Top:=Base + Line * LINE_HEIGHT + 6;
    Inc(Line);
    for I := 1 to 4 do //Orders
    begin
      W := gResHouses[aHouse.HouseType].ResOutput[I];
      if gResWares[W].IsValid then
      begin
        WareOrderRow_Order[I].WareRow.TexID := gResWares[W].GUIIcon;
        WareOrderRow_Order[I].WareRow.Caption := gResWares[W].Title;
        WareOrderRow_Order[I].Hint := gResWares[W].Title;
        WareOrderRow_Order[I].WareRow.WareCount := aHouse.CheckResOut(W);
        WareOrderRow_Order[I].OrderCount := aHouse.ResOrder[I];
        WareOrderRow_Order[I].Show;
        WareOrderRow_Order[I].Top := Base + Line * LINE_HEIGHT;
        Inc(Line);
      end;
    end;
    Label_Common_Costs.Show;
    Label_Common_Costs.Top := Base + Line * LINE_HEIGHT + 2;
    Inc(Line);
    for I := 1 to 4 do //Costs
    begin
      W := gResHouses[aHouse.HouseType].ResOutput[I];
      if gResWares[W].IsValid then
      begin
        CostsRow_Costs[I].Caption := gResWares[W].Title;
        CostsRow_Costs[I].RX := rxGui;
        //Hide the icons when they are not used
        if WARFARE_COSTS[W, 1] = wtNone then
          CostsRow_Costs[I].TexID1 := 0
        else
          CostsRow_Costs[I].TexID1 := gResWares[WARFARE_COSTS[W, 1]].GUIIcon;

        if WARFARE_COSTS[W, 2] = wtNone then
          CostsRow_Costs[I].TexID2 := 0
        else
          CostsRow_Costs[I].TexID2 := gResWares[WARFARE_COSTS[W, 2]].GUIIcon;

        CostsRow_Costs[I].Show;
        CostsRow_Costs[I].Top := Base + Line * LINE_HEIGHT - 2*I - 6; //Pack them closer so they fit on 1024x576
        Inc(Line);
      end;
    end;
  end;
end;


procedure TKMGUIGameHouse.ShowTownHall(aHouse: TKMHouse);
var
  TH: TKMHouseTownHall;
begin
  Assert(aHouse is TKMHouseTownHall);

  TH := TKMHouseTownHall(aHouse);

  House_TH_UnitChange(nil, []);
  ResRow_TH_Gold.WareCount := TH.GoldCnt;
  ResRow_TH_MaxGold.OrderCount := TH.GoldMaxCnt;

  Panel_HouseTownHall.Show;
end;


procedure TKMGUIGameHouse.UpdateHotkeys;
begin
  // School
  Button_School_Left.Hint := GetHintWHotkey(TX_HOUSE_SCHOOL_PREV_HINT, kfTrainGotoPrev);
  Button_School_Right.Hint := GetHintWHotkey(TX_HOUSE_SCHOOL_NEXT_HINT, kfTrainGotoNext);

  if not gMySpectator.Hand.Locks.GetUnitBlocked(School_Order[fLastSchoolUnit]) then
    Button_School_Train.Hint := GetHintWHotkey(TX_HOUSE_SCHOOL_TRAIN_HINT, kfTrainEquipUnit)
  else
    Button_School_Train.Hint := gResTexts[TX_HOUSE_SCHOOL_TRAIN_DISABLED_HINT];

  // Barracks
  Button_Barracks_Left.Hint := GetHintWHotkey(TX_HOUSE_BARRACKS_PREV_HINT, kfTrainGotoPrev);
  Button_Barracks_Right.Hint := GetHintWHotkey(TX_HOUSE_BARRACKS_NEXT_HINT, kfTrainGotoNext);

  if not gMySpectator.Hand.Locks.GetUnitBlocked(Barracks_Order[fLastBarracksUnit]) then
    Button_Barracks_Train.Hint := GetHintWHotkey(TX_HOUSE_BARRACKS_TRAIN_HINT, kfTrainEquipUnit)
  else
    Button_Barracks_Train.Hint := gResTexts[TX_HOUSE_BARRACKS_TRAIN_DISABLED_HINT];

  // Townhall
  Button_TH_Left.Hint := GetHintWHotkey(TX_HOUSE_BARRACKS_PREV_HINT, kfTrainGotoPrev);
  Button_TH_Right.Hint := GetHintWHotkey(TX_HOUSE_BARRACKS_NEXT_HINT, kfTrainGotoNext);

  if not gMySpectator.Hand.Locks.GetUnitBlocked(TownHall_Order[fLastTHUnit]) then
    Button_TH_Train.Hint := GetHintWHotkey(TX_HOUSE_BARRACKS_TRAIN_HINT, kfTrainEquipUnit)
  else
    Button_TH_Train.Hint := gResTexts[TX_HOUSE_BARRACKS_TRAIN_DISABLED_HINT];
end;


// Show Armorworskhop page
procedure TKMGUIGameHouse.ShowArmorWorkshop(aHouse: TKMHouse);
var
  I, rowRes, base, line: Integer;
  hSpec: TKMHouseSpec;
begin
  hSpec := gResHouses[aHouse.HouseType];

  House_ArmorWSDeliveryToggle(nil);
  Panel_HouseArmorWorkshop.Show;

  //First thing - hide everything
  for I := 0 to Panel_House_Common.ChildCount - 1 do
    Panel_House_Common.Childs[I].Hide;

  //Now show only what we need
  rowRes := 1;
  line := 0;
  base := 2;
          
  //Show Demand
  Label_ArmorWS_Demand.Show;
  Label_ArmorWS_Demand.Top := base + line*LINE_HEIGHT + 6;
  Inc(line);

  for I := 1 to 2 do
    if gResWares[gResHouses[aHouse.HouseType].ResInput[I]].IsValid then
    begin
      WaresRow_ArmorWS_Common[rowRes].TexID     := gResWares[hSpec.ResInput[I]].GUIIcon;
      WaresRow_ArmorWS_Common[rowRes].Caption   := gResWares[hSpec.ResInput[I]].Title;
      WaresRow_ArmorWS_Common[rowRes].Hint      := gResWares[hSpec.ResInput[I]].Title;
      WaresRow_ArmorWS_Common[rowRes].WareCount := aHouse.CheckResIn(hSpec.ResInput[I]);
      WaresRow_ArmorWS_Common[rowRes].Top       := base + line * LINE_HEIGHT;
      WaresRow_ArmorWS_Common[rowRes].Show;
      Inc(line);
      Inc(rowRes);
    end;

  //Show Output
  ShowCommonOutput(aHouse, base, line, rowRes);

  //Show Orders
  ShowCommonOrders(aHouse, base, line, rowRes);
end;


function TKMGUIGameHouse.GetEquipAmount(Shift: TShiftState): Integer;
begin
  // We use Left Click + Shift ro order 10
  // since its like we use it for an equip hotkey (Shift + S)
  // and to order 100 we can use Shift + Right Click
  if Shift = [ssLeft, ssShift] then
    Shift := [ssRight];

  Result := Min(GetMultiplicator(Shift), MAX_UNITS_TO_EQUIP);
end;


function TKMGUIGameHouse.Visible: Boolean;
begin
  Result := Panel_House.Visible;
end;


procedure TKMGUIGameHouse.Hide;
begin
  Panel_House.Hide;
end;


procedure TKMGUIGameHouse.House_Demolish(Sender: TObject; Shift: TShiftState);
begin
  if (gMySpectator.Selected = nil) or not (gMySpectator.Selected is TKMHouse) then
    Exit;

  if Sender = Button_House_DemolishYes then
  begin
    gGame.GameInputProcess.CmdBuild(gicBuildRemoveHouse, TKMHouse(gMySpectator.Selected).Position);
    gMySpectator.Selected := nil; //fPlayers.Selected MUST be reset before calling ShowHouseInfo
    Panel_House.Hide; //Simpliest way to reset page and ShownHouse
  end;

  AskDemolish := False;
  OnHouseDemolish(Sender, Shift); //Return to build menu
end;


procedure TKMGUIGameHouse.House_RepairToggle(Sender: TObject);
begin
  if (gMySpectator.Selected = nil) or not (gMySpectator.Selected is TKMHouse) then Exit;

  gGame.GameInputProcess.CmdHouse(gicHouseRepairToggle, TKMHouse(gMySpectator.Selected));
  Button_HouseRepair.TexID := IfThen(TKMHouse(gMySpectator.Selected).BuildingRepair, 39, 40);
end;


procedure TKMGUIGameHouse.House_DeliveryModeToggle(Sender: TObject; Shift: TShiftState);
begin
  if (gMySpectator.Selected = nil)
    or not (gMySpectator.Selected is TKMHouse)
    or not gMySpectator.IsSelectedMyObj then
    Exit;

  if ssLeft in Shift then
    gGame.GameInputProcess.CmdHouse(gicHouseDeliveryModeNext, TKMHouse(gMySpectator.Selected))
  else if ssRight in Shift then
    gGame.GameInputProcess.CmdHouse(gicHouseDeliveryModePrev, TKMHouse(gMySpectator.Selected));
end;


procedure TKMGUIGameHouse.House_ClosedForWorkerToggle(Sender: TObject);
var
  house: TKMHouse;
begin
  if (gMySpectator.Selected = nil) or not (gMySpectator.Selected is TKMHouse)
    or (gMySpectator.Selected is TKMHouseBarracks) then Exit;

  house := TKMHouse(gMySpectator.Selected);
  
  gGame.GameInputProcess.CmdHouse(gicHouseClosedForWorkerTgl, house);

  HandleHouseClosedForWorker(house);
end;


procedure TKMGUIGameHouse.HandleHouseClosedForWorker(aHouse: TKMHouse);
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


procedure TKMGUIGameHouse.HouseLogo_Click(Sender: TObject);
var
  H: TKMHouse;
begin
  if not (gMySpectator.Selected is TKMHouse) then Exit;

  H := TKMHouse(gMySpectator.Selected);
  if not H.IsDestroyed then
  begin
    if Assigned(fSetViewportEvent) then
    begin
      gMySpectator.Highlight := H;
      fSetViewportEvent(KMPointF(H.Entrance));
    end;
  end;
end;


procedure TKMGUIGameHouse.House_OrderChange(Sender: TObject; aValue: Integer);
var
  I: Integer;
  H: TKMHouse;
begin
  if not (gMySpectator.Selected is TKMHouse) then Exit;

  H := TKMHouse(gMySpectator.Selected);

  for I := 1 to 4 do
    if (Sender = WareOrderRow_Order[I]) then
      gGame.GameInputProcess.CmdHouse(gicHouseOrderProduct, H, I, aValue);
end;


procedure TKMGUIGameHouse.House_WoodcutterClick(Sender: TObject; Shift: TShiftState);
begin
  if Sender <> Button_Woodcutter then Exit;

  if ssLeft in Shift then
    Radio_Woodcutter.ItemIndex := (Radio_Woodcutter.ItemIndex + 1) mod 3 //Cycle
  else
  if ssRight in Shift then
    Radio_Woodcutter.ItemIndex := (Radio_Woodcutter.ItemIndex + 3 - 1) mod 3; //Cycle reverse

  House_WoodcutterChange( Button_Woodcutter );
end;


procedure TKMGUIGameHouse.House_WoodcutterChange(Sender: TObject);
var
  W: TKMHouseWoodcutters;
  wMode: TKMWoodcutterMode;
begin
  W := TKMHouseWoodcutters(gMySpectator.Selected);

  if (Sender = Button_Woodcutter) or (Sender = Radio_Woodcutter) then
  begin
    if Radio_Woodcutter.ItemIndex = 0 then
      wMode := wmChopAndPlant
    else if Radio_Woodcutter.ItemIndex = 1 then
      wMode := wmChop
    else
      wMode := wmPlant;
    gGame.GameInputProcess.CmdHouse(gicHouseWoodcutterMode, W, wMode);
  end;

  case W.WoodcutterMode of
    wmChopAndPlant: begin
                      Button_Woodcutter.TexID := 310;
                      Button_Woodcutter.RX := rxGui;
                      Radio_Woodcutter.ItemIndex := 0;
                    end;
    wmChop:         begin
                      Button_Woodcutter.TexID := 51;
                      Button_Woodcutter.RX := rxGui;
                      Radio_Woodcutter.ItemIndex := 1;
                    end;
    wmPlant:        begin
                      Button_Woodcutter.TexID := 666;
                      Button_Woodcutter.RX := rxGui;
                      Radio_Woodcutter.ItemIndex := 2;
                    end;
  end;
end;


procedure TKMGUIGameHouse.KeyDown(Key: Word; aShift: TShiftState; var aHandled: Boolean);
begin
  if aHandled then Exit;

  // Shift is 10 units order
  if ssShift in aShift then
  begin
    Exclude(aShift, ssShift);
    Include(aShift, ssRight);
  end
  else
    Include(aShift, ssLeft);

  //Prev unit
  if Key = gResKeys[kfTrainGotoPrev] then
  begin
    if Panel_House_School.Visible and Button_School_Left.Enabled then
    begin
      House_SchoolUnitChange(Button_School_Left, aShift);
      aHandled := True;
    end;

    if Panel_HouseBarracks.Visible and Button_Barracks_Left.Enabled then
    begin
      House_BarracksUnitChange(Button_Barracks_Left, aShift);
      aHandled := True;
    end;

    if Panel_HouseTownHall.Visible and Button_TH_Left.Enabled then
    begin
      House_TH_UnitChange(Button_TH_Left, aShift);
      aHandled := True;
    end;
  end;

  //Next unit
  if Key = gResKeys[kfTrainGotoNext] then
  begin
    if Panel_House_School.Visible and Button_School_Right.Enabled then
    begin
      House_SchoolUnitChange(Button_School_Right, aShift);
      aHandled := True;
    end;

    if Panel_HouseBarracks.Visible and Button_Barracks_Right.Enabled then
    begin
      House_BarracksUnitChange(Button_Barracks_Right, aShift);
      aHandled := True;
    end;

    if Panel_HouseTownHall.Visible and Button_TH_Right.Enabled then
    begin
      House_TH_UnitChange(Button_TH_Right, aShift);
      aHandled := True;
    end;
  end;

  //Hotkey for train / equip button
  if Key = gResKeys[kfTrainEquipUnit] then
  begin
    if Panel_House_School.Visible and Button_School_Train.Enabled then
    begin
      House_SchoolUnitChange(Button_School_Train, aShift);
      aHandled := True;
    end;

    if Panel_HouseBarracks.Visible and Button_Barracks_Train.Enabled then
    begin
      House_BarracksUnitChange(Button_Barracks_Train, aShift);
      aHandled := True;
    end;

    if Panel_HouseTownHall.Visible and Button_TH_Train.Enabled then
    begin
      House_TH_UnitChange(Button_TH_Train, aShift);
      aHandled := True;
    end;
  end;
end;


procedure TKMGUIGameHouse.House_BarracksUnitChange(Sender: TObject; Shift: TShiftState);
var
  I, K, tmp: Integer;
  barracks: TKMHouseBarracks;
begin
  if gMySpectator.Selected = nil then
    Exit;
  if not (gMySpectator.Selected is TKMHouseBarracks) then
    Exit;

  barracks := TKMHouseBarracks(gMySpectator.Selected);

  //Update graphics owner color
  Button_House_Worker.Hide; //In the barrack the recruit icon is always enabled
  Image_House_Worker.Show;
  Image_Barracks_Left.FlagColor := gHands[barracks.Owner].FlagColor;
  Image_Barracks_Right.FlagColor := gHands[barracks.Owner].FlagColor;
  Image_Barracks_Train.FlagColor := gHands[barracks.Owner].FlagColor;
  Button_BarracksRecruit.FlagColor := gHands[barracks.Owner].FlagColor;

  //Supply
  for I := 1 to BARRACKS_RES_COUNT do
  begin
    tmp := barracks.CheckResIn(BarracksResType[I]);
    Button_Barracks[I].Caption := IfThen(tmp = 0, '-', IntToKStr(tmp));
    //Set highlights
    Button_Barracks[I].Down := False;
    for K := 1 to 4 do
      if BarracksResType[I] = TROOP_COST[Barracks_Order[fLastBarracksUnit], K] then
        Button_Barracks[I].Down := True;

    Image_Barracks_NotAccept[I].Visible := barracks.NotAcceptFlag[BarracksResType[I]];
    Image_Barracks_NotAllowTakeOut[I].Visible := barracks.NotAllowTakeOutFlag[BarracksResType[I]];
  end;

  tmp := barracks.RecruitsCount;
  Button_BarracksRecruit.Caption := IfThen(tmp = 0, '-', IntToKStr(tmp));
  Button_BarracksRecruit.Down := True; //Recruit is always enabled, all troops require one
  Image_Barracks_NotAcceptRecruit.Visible := barracks.NotAcceptRecruitFlag;


  if (Sender = Button_Barracks_Left) and (RMB_SHIFT_STATES * Shift <> []) then
    fLastBarracksUnit := 0;
  if (Sender = Button_Barracks_Right) and (RMB_SHIFT_STATES * Shift <> []) then
    fLastBarracksUnit := High(Barracks_Order);

  if (Sender = Button_Barracks_Left)and(fLastBarracksUnit > 0) then
    Dec(fLastBarracksUnit);
  if (Sender = Button_Barracks_Right)and(fLastBarracksUnit < High(Barracks_Order)) then
    Inc(fLastBarracksUnit);

  if Sender = Button_Barracks_Train then //Equip unit
    gGame.GameInputProcess.CmdHouse(gicHouseBarracksEquip, barracks, Barracks_Order[fLastBarracksUnit], GetEquipAmount(Shift));

  Button_Barracks_Train.Enabled := not gGame.IsPeaceTime and barracks.CanEquip(Barracks_Order[fLastBarracksUnit]);
  Button_Barracks_Left.Enabled := fLastBarracksUnit > 0;
  Button_Barracks_Right.Enabled := fLastBarracksUnit < High(Barracks_Order);
  Image_Barracks_Left.Visible:= Button_Barracks_Left.Enabled;
  Image_Barracks_Right.Visible:= Button_Barracks_Right.Enabled;

  if fLastBarracksUnit > 0 then
    Image_Barracks_Left.TexID := gRes.Units[Barracks_Order[fLastBarracksUnit-1]].GUIScroll;

  Image_Barracks_Train.TexID := gRes.Units[Barracks_Order[fLastBarracksUnit]].GUIScroll;
  Label_Barracks_Unit.Caption := gRes.Units[Barracks_Order[fLastBarracksUnit]].GUIName;

  Image_Barracks_Train.Enabled := not gMySpectator.Hand.Locks.GetUnitBlocked(Barracks_Order[fLastBarracksUnit]);

  if fLastBarracksUnit < High(Barracks_Order) then
    Image_Barracks_Right.TexID := gRes.Units[Barracks_Order[fLastBarracksUnit + 1]].GUIScroll;
end;


procedure TKMGUIGameHouse.House_TownHall_Change(Sender: TObject; aChangeValue: Integer);
var
  TH: TKMHouseTownHall;
  newValue: Integer;
begin
  TH := TKMHouseTownHall(gMySpectator.Selected);
  newValue := EnsureRange(TH.GoldMaxCnt + aChangeValue, 0, High(Word));
  gGame.GameInputProcess.CmdHouse(gicHouseTownHallMaxGold, TH, newValue);
end;


procedure TKMGUIGameHouse.House_TH_UnitChange(Sender: TObject; Shift: TShiftState);
var
  townHall: TKMHouseTownhall;
begin
  if gMySpectator.Selected = nil then Exit;
  if not (gMySpectator.Selected is TKMHouseTownhall) then Exit;

  townHall := TKMHouseTownHall(gMySpectator.Selected);

  //Update graphics owner color
  Button_House_Worker.Hide; //In the townhall the worker button is always hidden
  Image_House_Worker.Show;
  Image_TH_Left.FlagColor := gHands[townHall.Owner].FlagColor;
  Image_TH_Right.FlagColor := gHands[townHall.Owner].FlagColor;
  Image_TH_Train.FlagColor := gHands[townHall.Owner].FlagColor;

  if (Sender = Button_TH_Left) and (RMB_SHIFT_STATES * Shift <> []) then
    fLastTHUnit := 0;
  if (Sender = Button_TH_Right) and (RMB_SHIFT_STATES * Shift <> []) then
    fLastTHUnit := High(TownHall_Order);

  if (Sender = Button_TH_Left) and (fLastTHUnit > 0) then
    Dec(fLastTHUnit);
  if (Sender = Button_TH_Right) and (fLastTHUnit < High(TownHall_Order)) then
    Inc(fLastTHUnit);

  if Sender = Button_TH_Train then //Equip unit
    gGame.GameInputProcess.CmdHouse(gicHouseTownHallEquip, townHall, TownHall_Order[fLastTHUnit], GetEquipAmount(Shift));

  Button_TH_Train.Enabled := not gGame.IsPeaceTime and townHall.CanEquip(TownHall_Order[fLastTHUnit]);
  Button_TH_Left.Enabled := fLastTHUnit > 0;
  Button_TH_Right.Enabled := fLastTHUnit < High(TownHall_Order);
  Image_TH_Left.Visible:= Button_TH_Left.Enabled;
  Image_TH_Right.Visible:= Button_TH_Right.Enabled;

  if fLastTHUnit > 0 then
    Image_TH_Left.TexID := gRes.Units[TownHall_Order[fLastTHUnit-1]].GUIScroll;

  Image_TH_Train.TexID := gRes.Units[TownHall_Order[fLastTHUnit]].GUIScroll;
  Label_TH_Unit.Caption := gRes.Units[TownHall_Order[fLastTHUnit]].GUIName;

  Image_TH_Train.Enabled := not gMySpectator.Hand.Locks.GetUnitBlocked(TownHall_Order[fLastTHUnit], True);

  if not gMySpectator.Hand.Locks.GetUnitBlocked(TownHall_Order[fLastTHUnit], True) then
    Button_TH_Train.Hint := gResTexts[TX_HOUSE_BARRACKS_TRAIN_HINT]
  else
    Button_TH_Train.Hint := gResTexts[TX_HOUSE_BARRACKS_TRAIN_DISABLED_HINT];

  if fLastTHUnit < High(TownHall_Order) then
    Image_TH_Right.TexID := gRes.Units[TownHall_Order[fLastTHUnit + 1]].GUIScroll;

  CostsRow_TH_Cost.Count := TH_TROOP_COST[fLastTHUnit];
end;


// Process click on Left-Train-Right buttons of School
procedure TKMGUIGameHouse.House_SchoolUnitChange(Sender: TObject; Shift: TShiftState);
var
  I: Integer;
  school: TKMHouseSchool;
begin
  if gMySpectator.Selected = nil then
    Exit;
  if not (gMySpectator.Selected is TKMHouseSchool) then
    Exit;
  school := TKMHouseSchool(gMySpectator.Selected);

  if (RMB_SHIFT_STATES * Shift <> []) and (Sender = Button_School_Left) then
    fLastSchoolUnit := 0;
  if (RMB_SHIFT_STATES * Shift <> []) and (Sender = Button_School_Right) then
    fLastSchoolUnit := High(School_Order);

  if (Sender = Button_School_Left) and (fLastSchoolUnit > 0) then
    Dec(fLastSchoolUnit);
  if (Sender = Button_School_Right) and (fLastSchoolUnit < High(School_Order)) then
    Inc(fLastSchoolUnit);

  if Sender = Button_School_Train then
  begin
    // Right click - fill queue with same units
    if RMB_SHIFT_STATES * Shift <> [] then
      gGame.GameInputProcess.CmdHouse(gicHouseSchoolTrain, school, School_Order[fLastSchoolUnit], 10)
    else if (ssLeft in Shift) then
    begin
      // Left click - add Unit to queue
      gGame.GameInputProcess.CmdHouse(gicHouseSchoolTrain, school, School_Order[fLastSchoolUnit], 1);
      // If Ctrl is also pressed, then change last unit order to 0
      if SCHOOL_CH_ORDER_TO_0_SHIFT in Shift then
        gGame.GameInputProcess.CmdHouse(gicHouseSchoolTrainChLastUOrder, school, 0)
      // else If Alt is also pressed, then change last unit order to 1
      else if SCHOOL_CH_ORDER_TO_1_SHIFT in Shift then
        gGame.GameInputProcess.CmdHouse(gicHouseSchoolTrainChLastUOrder, school, 1);
    end;
  end;

  if school.Queue[0] <> utNone then
    Button_School_UnitWIP.TexID := gRes.Units[school.Queue[0]].GUIIcon
  else
    Button_School_UnitWIP.TexID := 41; //Question mark

  Button_School_UnitWIPBar.Position := school.GetTrainingProgress;

  for I := 1 to 5 do
    if school.Queue[I] <> utNone then
    begin
      Button_School_UnitPlan[I].TexID := gRes.Units[school.Queue[I]].GUIIcon;
      Button_School_UnitPlan[I].Hint := gRes.Units[school.Queue[I]].GUIName;
    end
    else
    begin
      Button_School_UnitPlan[I].TexID:=0;
      Button_School_UnitPlan[I].Hint:='';
    end;

  Button_School_Train.Enabled := (not school.QueueIsFull)
                                  and (not gMySpectator.Hand.Locks.GetUnitBlocked(School_Order[fLastSchoolUnit]));
  Button_School_Left.Enabled := fLastSchoolUnit > 0;
  Button_School_Right.Enabled := fLastSchoolUnit < High(School_Order);
  Image_School_Left.Visible := Button_School_Left.Enabled;
  Image_School_Right.Visible := Button_School_Right.Enabled;

  if fLastSchoolUnit > 0 then
    Image_School_Left.TexID := gRes.Units[School_Order[fLastSchoolUnit-1]].GUIScroll;

  Label_School_Unit.Caption := gRes.Units[School_Order[fLastSchoolUnit]].GUIName;
  Image_School_Train.TexID := gRes.Units[School_Order[fLastSchoolUnit]].GUIScroll;

  Image_School_Train.Enabled := not gMySpectator.Hand.Locks.GetUnitBlocked(School_Order[fLastSchoolUnit]);

  if fLastSchoolUnit < High(School_Order) then
    Image_School_Right.TexID := gRes.Units[School_Order[fLastSchoolUnit+1]].GUIScroll;
end;


// Process click on Units queue buttons of School
procedure TKMGUIGameHouse.House_SchoolUnitQueueClick(Sender: TObject; Shift: TShiftState);
var
  I, id: Integer;
  school: TKMHouseSchool;
begin
  school := TKMHouseSchool(gMySpectator.Selected);
  id := TKMControl(Sender).Tag; //Item number that was clicked from the school queue

  //Right click clears entire queue after this item.
  //In that case we remove the same id repeatedly because they're automatically move along
  if RMB_SHIFT_STATES * Shift <> [] then
    for I := school.QueueLength - 1 downto id do
      gGame.GameInputProcess.CmdHouse(gicHouseRemoveTrain, school, I)
  else if SCHOOL_CH_ORDER_TO_0_SHIFT in Shift then
    // Left click + Shift - change Unit order in queue to 0
    gGame.GameInputProcess.CmdHouse(gicHouseSchoolTrainChOrder, school, id, 0)
  else if SCHOOL_CH_ORDER_TO_1_SHIFT in Shift then
    // Left click + Ctrl - change Unit order in queue to 1
    gGame.GameInputProcess.CmdHouse(gicHouseSchoolTrainChOrder, school, id, Min(id, 1))
  else
    //Left click removes 1 unit from queue
    gGame.GameInputProcess.CmdHouse(gicHouseRemoveTrain, school, id);

  House_SchoolUnitChange(nil, []);
end;


// Toggle ware delivery for separate resources (wood, leather) in Armor workshop
procedure TKMGUIGameHouse.House_ArmorWSDeliveryToggle(Sender: TObject);
var
  I: Integer;
  armorWS: TKMHouseArmorWorkshop;
begin
  armorWS := TKMHouseArmorWorkshop(gMySpectator.Selected);
  for I := 1 to 2 do
  begin
    if Sender = WaresRow_ArmorWS_Common[I] then
      gGame.GameInputProcess.CmdHouse(gicHouseArmorWSDeliveryToggle, armorWS, gResHouses[htArmorWorkshop].ResInput[I]);

    Image_ArmorWS_Accept[I].Visible := not armorWS.AcceptWareForDelivery(gResHouses[htArmorWorkshop].ResInput[I]);
  end;
end;


// That small red triangle blocking delivery of wares to Barracks
// Ware determined by Button.Tag property
procedure TKMGUIGameHouse.House_BarracksItemClickShift(Sender: TObject; Shift: TShiftState);
begin
  if gMySpectator.Selected = nil then
    Exit;
  if not (gMySpectator.Selected is TKMHouseBarracks) then
    Exit;
  //Red triangle - block delivery to barracks
  if ssLeft in Shift then
  begin
    if Sender <> Button_BarracksRecruit then
      gGame.GameInputProcess.CmdHouse(gicHouseBarracksAcceptFlag, TKMHouse(gMySpectator.Selected), BarracksResType[(Sender as TKMControl).Tag])
    else
      gGame.GameInputProcess.CmdHouse(gicHBarracksAcceptRecruitsTgl, TKMHouse(gMySpectator.Selected));
  end
  else
  //Orange triange - block take resources from
  if ssRight in Shift then
  begin
    if Sender <> Button_BarracksRecruit then
      gGame.GameInputProcess.CmdHouse(gicHBarracksNotAllowTakeOutFlag, TKMHouse(gMySpectator.Selected), BarracksResType[(Sender as TKMControl).Tag]);
  end;
end;


// That small red triangle blocking delivery of wares to Storehouse
// Ware determined by Button.Tag property
procedure TKMGUIGameHouse.House_StoreItemClickShift(Sender: TObject; Shift: TShiftState);
begin
  if gMySpectator.Selected = nil then
    Exit;
  if not (gMySpectator.Selected is TKMHouseStore) then
    Exit;
  //Red triangle - block delivery to barracks
  if ssLeft in Shift then
    gGame.GameInputProcess.CmdHouse(gicHouseStoreNotAcceptFlag, TKMHouse(gMySpectator.Selected), StoreResType[(Sender as TKMControl).Tag])
  else
  //Orange triange - block take resources from
  if ssRight in Shift then
    gGame.GameInputProcess.CmdHouse(gicHStoreNotAllowTakeOutFlag, TKMHouse(gMySpectator.Selected), StoreResType[(Sender as TKMControl).Tag])
end;


procedure TKMGUIGameHouse.House_MarketFill(aMarket: TKMHouseMarket);
var
  I, tmp: Integer;
  W: TKMWareType;
begin
  for I := 0 to STORE_RES_COUNT - 1 do
  begin
    W := TKMWareType(Button_Market[I].Tag);
    if aMarket.AllowedToTrade(W) then
    begin
      Button_Market[I].TexID := gResWares[W].GUIIcon;
      Button_Market[I].Hint := gResWares[W].Title;
      tmp := aMarket.GetResTotal(W);
      Button_Market[I].Caption := IfThen(tmp = 0, '-', IntToKStr(tmp, 1000)); // Convert 1234 -> '1k'
    end
    else
    begin
      Button_Market[I].TexID := 41;
      Button_Market[I].Hint := gResTexts[TX_HOUSES_MARKET_HINT_BLOCKED];
      Button_Market[I].Caption := '-';
    end;

    //Disabling buttons will let player know that he cant select new trade without canceling current one
    Button_Market[I].Enabled := (W in [aMarket.ResFrom, aMarket.ResTo]) or not aMarket.TradeInProgress;
  end;

  //Position the shape that marks the FROM ware
  Shape_Market_From.Visible := aMarket.ResFrom <> wtNone;
  if aMarket.ResFrom <> wtNone then
  begin
    Shape_Market_From.Left := ((Byte(aMarket.ResFrom)-1) mod 6) * 31;
    Shape_Market_From.Top := 12 + ((Byte(aMarket.ResFrom)-1) div 6) * MARKET_RES_HEIGHT;
    Label_Market_In.Caption := Format(gResTexts[TX_HOUSES_MARKET_FROM], [aMarket.RatioFrom]);
    Button_Market_In.TexID := gResWares[aMarket.ResFrom].GUIIcon;
    Button_Market_In.Caption := IntToStr(aMarket.GetResTotal(aMarket.ResFrom));
  end else begin
    Label_Market_In.Caption := Format(gResTexts[TX_HOUSES_MARKET_FROM],[0]);
    Button_Market_In.TexID := gResWares[wtNone].GUIIcon;
    Button_Market_In.Caption := '-';
  end;

  //Position the shape that marks the TO ware
  Shape_Market_To.Visible := aMarket.ResTo <> wtNone;
  if aMarket.ResTo <> wtNone then
  begin
    Shape_Market_To.Left := ((Byte(aMarket.ResTo)-1) mod 6) * 31;
    Shape_Market_To.Top := 12 + ((Byte(aMarket.ResTo)-1) div 6) * MARKET_RES_HEIGHT;
    Label_Market_Out.Caption := Format(gResTexts[TX_HOUSES_MARKET_TO], [aMarket.RatioTo]);
    Button_Market_Out.Caption := IntToStr(aMarket.GetResTotal(aMarket.ResTo));
    Button_Market_Out.TexID := gResWares[aMarket.ResTo].GUIIcon;
  end else begin
    Label_Market_Out.Caption := Format(gResTexts[TX_HOUSES_MARKET_TO], [0]);
    Button_Market_Out.TexID := gResWares[wtNone].GUIIcon;
    Button_Market_Out.Caption := '-';
  end;

  Button_Market_Remove.Enabled := (aMarket.ResFrom <> wtNone) and (aMarket.ResTo <> wtNone);
  Button_Market_Add.Enabled := Button_Market_Remove.Enabled;
  Label_Market_FromAmount.Caption := IntToStr(aMarket.RatioFrom * aMarket.ResOrder[1]);
  Label_Market_ToAmount.Caption := IntToStr(aMarket.RatioTo * aMarket.ResOrder[1]);
end;


procedure TKMGUIGameHouse.House_MarketOrderClick(Sender: TObject; Shift: TShiftState);
var
  M: TKMHouseMarket;
begin
  if not (gMySpectator.Selected is TKMHouseMarket) then Exit;

  M := TKMHouseMarket(gMySpectator.Selected);

  if Sender = Button_Market_Remove then
    gGame.GameInputProcess.CmdHouse(gicHouseOrderProduct, M, 1, -GetMultiplicator(Shift));
  if Sender = Button_Market_Add then
    gGame.GameInputProcess.CmdHouse(gicHouseOrderProduct, M, 1, GetMultiplicator(Shift));
end;


procedure TKMGUIGameHouse.House_MarketSelect(Sender: TObject; Shift: TShiftState);
var
  M: TKMHouseMarket;
begin
  if not (gMySpectator.Selected is TKMHouseMarket) then Exit;

  M := TKMHouseMarket(gMySpectator.Selected);

  if Shift = [ssLeft] then
    gGame.GameInputProcess.CmdHouse(gicHouseMarketFrom, M, TKMWareType(TKMButtonFlat(Sender).Tag));
  if Shift = [ssRight] then
    gGame.GameInputProcess.CmdHouse(gicHouseMarketTo, M, TKMWareType(TKMButtonFlat(Sender).Tag));

  House_MarketFill(M); //Update costs and order count
end;


procedure TKMGUIGameHouse.House_StoreFill;
var
  I, tmp: Integer;
begin
  if gMySpectator.Selected = nil then Exit;
  if not (gMySpectator.Selected is TKMHouseStore) then Exit;

  for I := 1 to STORE_RES_COUNT do
  begin
    tmp := TKMHouseStore(gMySpectator.Selected).CheckResIn(StoreResType[I]);
    Button_Store[I].Caption := IfThen(tmp = 0, '-', IntToKStr(tmp));
    Image_Store_NotAccept[I].Visible := TKMHouseStore(gMySpectator.Selected).NotAcceptFlag[StoreResType[I]];
    Image_Store_NotAllowTakeOut[I].Visible := TKMHouseStore(gMySpectator.Selected).NotAllowTakeOutFlag[StoreResType[I]];
  end;
end;


procedure TKMGUIGameHouse.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.Write(fLastSchoolUnit);
  SaveStream.Write(fLastBarracksUnit);
  SaveStream.Write(fLastTHUnit);
end;


procedure TKMGUIGameHouse.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.Read(fLastSchoolUnit);
  LoadStream.Read(fLastBarracksUnit);
  LoadStream.Read(fLastTHUnit);
end;


end.
