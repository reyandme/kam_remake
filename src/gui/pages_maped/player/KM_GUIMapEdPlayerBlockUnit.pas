unit KM_GUIMapEdPlayerBlockUnit;
{$I KaM_Remake.inc}
interface
uses
  Classes,
  KM_Controls, KM_Pics, KM_InterfaceGame;

type
  TKMMapEdPlayerBlockUnit = class
  private
    procedure Player_BlockUnitClick(Sender: TObject);
    procedure Player_BlockBarracksWarriorsClick(Sender: TObject);
    procedure Player_BlockTHWarriorsClick(Sender: TObject);
    procedure Player_BlockUnitRefresh;
    procedure Player_BlockBarracksWarriorsRefresh;
    procedure Player_BlockTHWarriorsRefresh;
  protected
    Panel_BlockUnit: TKMPanel;
    Button_BlockUnit: array [0..13] of TKMButtonFlat;
    Button_BlockBarracksWarriors: array [0..High(Barracks_Order)] of TKMButtonFlat;
    Button_BlockTHWarriors: array [0..High(TownHall_Order)] of TKMButtonFlat;
    Image_BlockUnit: array [0..13] of TKMImage;
    Image_BlockBarracksWarriors: array[0..High(Barracks_Order)] of TKMImage;
    Image_BlockTHWarriors: array[0..High(TownHall_Order)] of TKMImage;
  public
    constructor Create(aParent: TKMPanel);
    procedure Show;
    function Visible: Boolean;
    procedure Hide;
    procedure UpdatePlayerColor;
  end;


implementation
uses
  KM_HandsCollection, KM_ResTexts, KM_ResUnits, KM_RenderUI, KM_ResFonts, KM_Resource, KM_Defaults,
  KM_HandStats, KM_Hand, KM_ResHouses;


{ TKMMapEdPlayerBlockUnit }
constructor TKMMapEdPlayerBlockUnit.Create(aParent: TKMPanel);
var
  I: Integer;
begin
  inherited Create;

  Panel_BlockUnit := TKMPanel.Create(aParent, 0, 28, TB_MAP_ED_WIDTH, 400);
  TKMLabel.Create(Panel_BlockUnit, 0, PAGE_TITLE_Y, TB_MAP_ED_WIDTH, 0, gResTexts[TX_MAPED_BLOCK_UNITS], fntOutline, taCenter);
  for I := 0 to High(Button_BlockUnit) do
  begin
    Button_BlockUnit[I] := TKMButtonFlat.Create(Panel_BlockUnit, 9 + (I mod 5)*37,30+(I div 5)*37,33,33,gRes.Units[School_Order[I]].GUIIcon);
    Button_BlockUnit[I].OnClick := Player_BlockUnitClick;
    Button_BlockUnit[I].Tag := I;
    Button_BlockUnit[I].Hint := gRes.Units[School_Order[I]].GUIName;
    Image_BlockUnit[I] := TKMImage.Create(Panel_BlockUnit, 9 + (I mod 5)*37 + 15,30+(I div 5)*37 + 15, 16, 16, 0, rxGuiMain);
    Image_BlockUnit[I].Hitable := False;
    Image_BlockUnit[I].ImageCenter;
  end;

  TKMLabel.Create(Panel_BlockUnit, 9, 146, TB_MAP_ED_WIDTH - 9, 0, gResTexts[TX_MAPED_BLOCK_UNITS_IN_BARRACKS], fntMetal, taLeft);
  for I := 0 to High(Button_BlockBarracksWarriors) do
  begin
    Button_BlockBarracksWarriors[I] := TKMButtonFlat.Create(Panel_BlockUnit,9 + (I mod 5)*37,20+146+(I div 5)*37,33,33,
                                                            gRes.Units[Barracks_Order[I]].GUIIcon, rxGui);
    Button_BlockBarracksWarriors[I].Hint := gRes.Units[Barracks_Order[I]].GUIName;
    Button_BlockBarracksWarriors[I].Tag := I;
    Button_BlockBarracksWarriors[I].OnClick := Player_BlockBarracksWarriorsClick;
    Image_BlockBarracksWarriors[I] := TKMImage.Create(Panel_BlockUnit, 9 + (I mod 5)*37 + 15,20+146+(I div 5)*37 + 15, 16, 16, 0, rxGuiMain);
    Image_BlockBarracksWarriors[I].Hitable := False;
    Image_BlockBarracksWarriors[I].ImageCenter;
  end;

  TKMLabel.Create(Panel_BlockUnit, 9, 245, TB_MAP_ED_WIDTH - 9, 0, gResTexts[TX_MAPED_BLOCK_UNITS_IN_TOWNHALL], fntMetal, taLeft);
  for I := 0 to High(Button_BlockTHWarriors) do
  begin
    Button_BlockTHWarriors[I] := TKMButtonFlat.Create(Panel_BlockUnit, 9 + (I mod 5)*37,265+(I div 5)*37,33,33, gRes.Units[TownHall_Order[I]].GUIIcon, rxGui);
    Button_BlockTHWarriors[I].Hint := gRes.Units[TownHall_Order[I]].GUIName;
    Button_BlockTHWarriors[I].Tag := I;
    Button_BlockTHWarriors[I].OnClick := Player_BlockTHWarriorsClick;
    Image_BlockTHWarriors[I] := TKMImage.Create(Panel_BlockUnit, 9 + (I mod 5)*37 + 15,265+(I div 5)*37 + 15, 16, 16, 0, rxGuiMain);
    Image_BlockTHWarriors[I].Hitable := False;
    Image_BlockTHWarriors[I].ImageCenter;
  end;
end;


procedure TKMMapEdPlayerBlockUnit.Player_BlockUnitClick(Sender: TObject);
var
  I: Integer;
  U: TKMUnitType;
begin
  I := TKMButtonFlat(Sender).Tag;
  U := School_Order[I];

  gMySpectator.Hand.Locks.SetUnitBlocked(not gMySpectator.Hand.Locks.GetUnitBlocked(U), U);

  Player_BlockUnitRefresh;
end;


procedure TKMMapEdPlayerBlockUnit.Player_BlockBarracksWarriorsClick(Sender: TObject);
var
  K: Integer;
  W: TKMUnitType;
begin
  K := TKMButtonFlat(Sender).Tag;
  W := Barracks_Order[K];

  gMySpectator.Hand.Locks.SetUnitBlocked(not gMySpectator.Hand.Locks.GetUnitBlocked(W), W);

  Player_BlockBarracksWarriorsRefresh;
end;


procedure TKMMapEdPlayerBlockUnit.Player_BlockTHWarriorsClick(Sender: TObject);
var
  K: Integer;
  W: TKMUnitType;
begin
  K := TKMButtonFlat(Sender).Tag;
  W := TownHall_Order[K];

  gMySpectator.Hand.Locks.SetUnitBlocked(not gMySpectator.Hand.Locks.GetUnitBlocked(W, True), W, True);

  Player_BlockTHWarriorsRefresh;
end;


procedure TKMMapEdPlayerBlockUnit.Player_BlockUnitRefresh;
var
  I: Integer;
  U: TKMUnitType;
  Blocked: Boolean;
begin
  for I := 0 to 13 do
  begin
    U := School_Order[I];
    Blocked := gMySpectator.Hand.Locks.GetUnitBlocked(U);
    if Blocked then
      Image_BlockUnit[I].TexID := 32
    else if not Blocked then
      Image_BlockUnit[I].TexID := 0
    else
      Image_BlockUnit[I].TexID := 24;
  end;
end;


procedure TKMMapEdPlayerBlockUnit.Player_BlockBarracksWarriorsRefresh;
var
  K: Integer;
  W: TKMUnitType;
  Blocked: Boolean;
begin
  for K := 0 to High(Barracks_Order) do
  begin
    W := Barracks_Order[K];
    Blocked := gMySpectator.Hand.Locks.GetUnitBlocked(W);
    if Blocked then
      Image_BlockBarracksWarriors[K].TexID := 32
    else if not Blocked then
      Image_BlockBarracksWarriors[K].TexID := 0
    else
      Image_BlockBarracksWarriors[K].TexID := 24;
  end;
end;


procedure TKMMapEdPlayerBlockUnit.Player_BlockTHWarriorsRefresh;
var
  K: Integer;
  W: TKMUnitType;
  Blocked: Boolean;
begin
  for K := 0 to High(TownHall_Order) do
  begin
    W := TownHall_Order[K];
    Blocked := gMySpectator.Hand.Locks.GetUnitBlocked(W, True);
    if Blocked then
      Image_BlockTHWarriors[K].TexID := 32
    else if not Blocked then
      Image_BlockTHWarriors[K].TexID := 0
    else
      Image_BlockTHWarriors[K].TexID := 24;
  end;
end;


procedure TKMMapEdPlayerBlockUnit.UpdatePlayerColor;
var
  I: Integer;
  Col: Cardinal;
begin
  Col := gMySpectator.Hand.FlagColor;

  for I := Low(Button_BlockUnit) to High(Button_BlockUnit) do
    Button_BlockUnit[I].FlagColor := Col;
  for I := Low(Button_BlockBarracksWarriors) to High(Button_BlockBarracksWarriors) do
    Button_BlockBarracksWarriors[I].FlagColor := Col;
  for I := Low(Button_BlockTHWarriors) to High(Button_BlockTHWarriors) do
    Button_BlockTHWarriors[I].FlagColor := Col;
end;


procedure TKMMapEdPlayerBlockUnit.Show;
begin
  Player_BlockUnitRefresh;
  Player_BlockBarracksWarriorsRefresh;
  Player_BlockTHWarriorsRefresh;
  Panel_BlockUnit.Show;
end;


procedure TKMMapEdPlayerBlockUnit.Hide;
begin
  Panel_BlockUnit.Hide;
end;


function TKMMapEdPlayerBlockUnit.Visible: Boolean;
begin
  Result := Panel_BlockUnit.Visible;
end;

end.
