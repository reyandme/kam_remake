unit KM_GUIGameRatios;
{$I KaM_Remake.inc}
interface
uses
  KM_Controls, KM_ControlsBase, KM_ControlsTrackBar,
  KM_Pics;


type
  TKMRatioTab = (rtSteel, rtCoal, rtWood, rtCorn);

  TKMGUIGameRatios = class
  private
    fActiveTab: TKMRatioTab; // Active resource distribution tab
    fAllowEditing: Boolean;

    procedure RatioTabClick(Sender: TObject);
    procedure RatioTabSet(aTab: TKMRatioTab);
    procedure RatiosChange(Sender: TObject);
  protected
    Panel_Ratios: TKMPanel;
    Button_Ratios: array [TKMRatioTab] of TKMButton;
    Image_RatioHead: TKMImage;
    Label_RatioHead: TKMLabel;
    Image_RatioPic: array [0..3] of TKMImage;
    TrackBar_RatioValue: array [0..3] of TKMTrackBar;
  public
    constructor Create(aParent: TKMPanel; aAllowEditing: Boolean);

    procedure Show;
    procedure Hide;
    function Visible: Boolean;
    procedure UpdateState;
  end;


implementation
uses
  KM_InterfaceGame,
  KM_GameInputProcess, KM_GameSettings, KM_RenderUI, KM_HandsCollection, KM_ResTexts, KM_Game,
  KM_Resource, KM_ResFonts, KM_ResHouses, KM_ResTypes;


const
  RES_RATIO_TYPE: array [TKMRatioTab] of TKMWareType = (wtIron, wtCoal, wtTimber, wtCorn);
  //ResRatioHint: array [TKMRatioTab] of Word = (298, 300, 302, 304);
  RES_RATIO_HOUSE_CNT: array [TKMRatioTab] of Byte = (2, 4, 2, 3);
  RES_RATIO_HOUSE: array [TKMRatioTab, 0..3] of TKMHouseType = (
      (htWeaponSmithy,   htArmorSmithy,     htNone,          htNone),
      (htIronSmithy,     htMetallurgists,   htWeaponSmithy,  htArmorSmithy),
      (htArmorWorkshop,  htWeaponWorkshop,  htNone,          htNone),
      (htMill,           htSwine,           htStables,       htNone));

  HEADER_BASELINE_Y = 80;


{ TKMGUIGameRatios }
constructor TKMGUIGameRatios.Create(aParent: TKMPanel; aAllowEditing: Boolean);
const
  HEADER_IMAGE_SIZE = 18;
var
  I: TKMRatioTab;
  K: Integer;
begin
  inherited Create;

  fActiveTab := rtSteel;
  fAllowEditing := aAllowEditing;
  Panel_Ratios:=TKMPanel.Create(aParent, TB_PAD, 44, TB_WIDTH, 332);

  for I := Low(TKMRatioTab) to High(TKMRatioTab) do
  begin
    Button_Ratios[I]         := TKMButton.Create(Panel_Ratios, Byte(I) * 40, 20, 32, 32, 0, rxGui, bsGame);
    Button_Ratios[I].TexID   := gRes.Wares[RES_RATIO_TYPE[I]].GUIIcon;
    Button_Ratios[I].Hint    := gRes.Wares[RES_RATIO_TYPE[I]].Title;
    Button_Ratios[I].Tag     := Byte(I);
    Button_Ratios[I].OnClick := RatioTabClick;
  end;

  Image_RatioHead := TKMImage.Create(Panel_Ratios, 0,
                                                   HEADER_BASELINE_Y - HEADER_IMAGE_SIZE div 2,
                                                   32,
                                                   HEADER_IMAGE_SIZE,
                                                   327);
  Image_RatioHead.ImageAnchors := [];

  Label_RatioHead := TKMLabel.Create(Panel_Ratios, 36, HEADER_BASELINE_Y - 8, 148, 30, NO_TEXT, fntOutline, taLeft);

  for K := 0 to 3 do
  begin
    Image_RatioPic[K]               := TKMImage.Create(Panel_Ratios, 0, 122 + K * 50, 32, 32, 327);
    Image_RatioPic[K].ImageAnchors  := [anBottom];
    TrackBar_RatioValue[K]          := TKMTrackBar.Create(Panel_Ratios, 36, 116 + K * 50, 140, 0, 5);
    TrackBar_RatioValue[K].CaptionWidth := 150;
    TrackBar_RatioValue[K].Font     := fntGrey; //fntMetal doesn't fit the text
    TrackBar_RatioValue[K].Tag      := K;
    TrackBar_RatioValue[K].OnChange := RatiosChange;
    TrackBar_RatioValue[K].Enabled := fAllowEditing;
  end;
end;


procedure TKMGUIGameRatios.RatioTabClick(Sender: TObject);
begin
  RatioTabSet(TKMRatioTab(TKMButton(Sender).Tag));
end;


//Switch between tabs
procedure TKMGUIGameRatios.RatioTabSet(aTab: TKMRatioTab);
var
  I: Integer;
  HT: TKMHouseType;
begin
  //Hide everything but the tab buttons
  for I := 0 to Panel_Ratios.ChildCount - 1 do
    if not (Panel_Ratios.Childs[I] is TKMButton) then
      Panel_Ratios.Childs[I].Hide;

  fActiveTab := aTab;

  Image_RatioHead.TexID := gRes.Wares[RES_RATIO_TYPE[fActiveTab]].GUIIcon;//Show resource icon
  Label_RatioHead.Caption := gRes.Wares[RES_RATIO_TYPE[fActiveTab]].Title;
  Image_RatioHead.Show;
  Label_RatioHead.Show;

  for I := 0 to RES_RATIO_HOUSE_CNT[fActiveTab] - 1 do
  begin
    HT := RES_RATIO_HOUSE[fActiveTab, I];
    //Do not allow player to see blocked house (never able to build). Though house may be prebuilt and blocked
    if (not gMySpectator.Hand.Locks.HouseBlocked[HT])
    or (gMySpectator.Hand.Stats.GetHouseQty(HT) > 0) then
    begin
      Image_RatioPic[I].TexID := gRes.Houses[HT].GUIIcon;
      TrackBar_RatioValue[I].Caption := gRes.Houses[HT].HouseName;
      TrackBar_RatioValue[I].Position := gMySpectator.Hand.Stats.WareDistribution[RES_RATIO_TYPE[fActiveTab], HT];
      TrackBar_RatioValue[I].Enabled := fAllowEditing;
    end else begin
      Image_RatioPic[I].TexID := 41; //Question mark
      TrackBar_RatioValue[I].Caption := gResTexts[TX_GAMEPLAY_NOT_AVAILABLE];
      TrackBar_RatioValue[I].Position := 0;
      TrackBar_RatioValue[I].Disable;
    end;

    Image_RatioPic[I].Show;
    TrackBar_RatioValue[I].Show;
  end;
end;


procedure TKMGUIGameRatios.RatiosChange(Sender: TObject);
var
  ware: TKMWareType;
  house: TKMHouseType;
  value: Byte;
begin
  ware := RES_RATIO_TYPE[fActiveTab];
  house := RES_RATIO_HOUSE[fActiveTab, TKMTrackBar(Sender).Tag];
  value := TKMTrackBar(Sender).Position;

  if gGame.IsWareDistributionStoredBetweenGames then
    gGameSettings.WareDistribution[ware, house] := value;

  gGame.GameInputProcess.CmdWareDistribution(gicWareDistributionChange, ware, house, value);
end;


procedure TKMGUIGameRatios.Show;

  function CanUseTab(aTab: TKMRatioTab): Boolean;
  var
    K: Integer;
  begin
    Result := False;
    for K := 0 to RES_RATIO_HOUSE_CNT[aTab] - 1 do
      //Do not allow player to see blocked house (never able to build). Though house may be prebuilt and blocked
      if not gMySpectator.Hand.Locks.HouseBlocked[RES_RATIO_HOUSE[aTab, K]]
        or (gMySpectator.Hand.Stats.GetHouseQty(RES_RATIO_HOUSE[aTab, K]) > 0) then
      begin
        //Select first tab we find with an unblocked house
        RatioTabSet(aTab);
        Exit(True);
      end;
  end;

var
  TAB: TKMRatioTab;
begin
  Panel_Ratios.Show;
  //Select the default tab, which is the first tab with an unblocked house
  //(so f.e. steel isn't the default tab when it's blocked by mission)
  if not CanUseTab(fActiveTab) then
    for TAB := Low(TKMRatioTab) to High(TKMRatioTab) do
      if (TAB <> fActiveTab) and CanUseTab(TAB) then
        Exit;

  //All houses are blocked, so select the first tab
  RatioTabSet(fActiveTab);
end;


procedure TKMGUIGameRatios.Hide;
begin
  Panel_Ratios.Hide;
end;


function TKMGUIGameRatios.Visible: Boolean;
begin
  Result := Panel_Ratios.Visible;
end;


procedure TKMGUIGameRatios.UpdateState;
begin
  RatioTabSet(fActiveTab);
end;


end.
