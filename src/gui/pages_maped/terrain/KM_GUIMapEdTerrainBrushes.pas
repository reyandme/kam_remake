unit KM_GUIMapEdTerrainBrushes;
{$I KaM_Remake.inc}
interface
uses
   Classes, Math, SysUtils,
   KM_Controls,
   KM_InterfaceDefaults,
   KM_Defaults, KM_Pics, KM_ResTileset;


type
  //Painting on terrain with terrain brushes
  TKMMapEdTerrainBrushes = class(TKMMapEdSubMenuPage)
  private
    fLastShape: TKMMapEdShape;
    fLastBrush: Integer;
    fLastMagicBrush: Boolean;
    procedure BrushChange(Sender: TObject);
    procedure BrushRefresh;
    procedure BrushFixTerrain_Click(Sender: TObject);
    procedure FixTerrainBrushes(Sender: TObject);
  protected
    Panel_Brushes: TKMScrollPanel;
      BrushSize: TKMTrackBar;
      BrushCircle: TKMButtonFlat;
      BrushSquare: TKMButtonFlat;
      BrushTable: array [0..6, 0..4] of TKMButtonFlat;
      BrushMasks: array [TKMTileMaskKind] of TKMButtonFlat;
      MagicBrush: TKMButtonFlat;
      BrushBlending: TKMTrackBar;
      RandomElements, OverrideCustomTiles, UseTerrainObjects: TKMCheckBox;
      Button_FixTerrainBrushes: TKMButton;
      PopUp_FixTerrainConfirm: TKMPopUpPanel;
        Button_FixTerrain_Yes, Button_FixTerrain_No: TKMButton;
  public
    constructor Create(aParent: TKMPanel);

    procedure Show;
    procedure Hide;
    function Visible: Boolean; override;
    procedure MouseWheel(Shift: TShiftState; WheelSteps: Integer; X,Y: Integer; var aHandled: Boolean);
    procedure KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);
    procedure Cancel_Clicked(var aHandled: Boolean);
    procedure UpdateState;
  end;


implementation
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLType, {$ENDIF}
  TypInfo, KM_ResFonts, KM_ResTexts, KM_Game, KM_GameCursor, KM_RenderUI,
  KM_TerrainPainter, KM_InterfaceGame, KM_Utils,
  KM_ResTypes;

const
  BTN_BRUSH_SIZE = 24;
  BTN_BRUSH_SIZE_W_SPACE = 30;
  BTN_TKIND_S = 34;
  BTN_TKIND_S_SP_X = 36;
  BTN_TKIND_S_SP_Y = 40;

type
  TMBrushButtonType = (bbtBrush = -1, bbtMask = -2);


{ TKMMapEdTerrainBrushes }
constructor TKMMapEdTerrainBrushes.Create(aParent: TKMPanel);
const
  SURF_ROW_LEN = 5;
  SURFACES_TAB = 18;

  SURFACES: array [0..5, 0..SURF_ROW_LEN-1] of TKMTerrainKind = (
    (tkGrass,       tkMoss,         tkPaleGrass,    tkGrassDirt,    tkDirt),
    (tkCoastSand,   tkGrassSand1,   tkGrassSand2,   tkGrassSand3,   tkSand),
    (tkSwamp,       tkGrassyWater,  tkWater,        tkFastWater,    tkCustom),
    (tkSnowOnGrass, tkSnowOnDirt,   tkSnow,         tkDeepSnow,     tkIce),
    (tkStone,       tkGoldMount,    tkIronMount,    tkCobbleStone,  tkGravel),
    (tkCoal,        tkGold,         tkIron,         tkLava,         tkAbyss));
  MASKS_HINTS_TX: array [TKMTileMaskKind] of Integer =
                            (TX_MAPED_TERRAIN_NO_MASK_HINT, TX_MAPED_TERRAIN_MASK_1_HINT,
                             TX_MAPED_TERRAIN_MASK_2_HINT, TX_MAPED_TERRAIN_MASK_3_HINT,
                             TX_MAPED_TERRAIN_MASK_4_HINT, TX_MAPED_TERRAIN_MASK_5_HINT);

var
  top: Integer;

  function NextTop(aInc: Integer): Integer;
  begin
    Result := top;
    top := top + aInc;
  end;

  procedure CreateBrushMaskBtn(aMK: TKMTileMaskKind);
  begin
    BrushMasks[aMK] := TKMButtonFlat.Create(Panel_Brushes, SURFACES_TAB
                                                           + ( (Ord(aMK) mod SURF_ROW_LEN)
                                                               + Min((Ord(aMK) div SURF_ROW_LEN), 1) // + 1 for the 2nd and further lines
                                                             ) * BTN_TKIND_S_SP_X,
                                                           305 + (Ord(aMK) div SURF_ROW_LEN)*BTN_TKIND_S_SP_Y,
                                                           BTN_TKIND_S, BTN_TKIND_S,
                                            TILE_MASK_KINDS_PREVIEW[aMK] + 1, rxTiles);
    BrushMasks[aMK].Anchors := [anTop];
    BrushMasks[aMK].Tag := Byte(aMK);
    BrushMasks[aMK].Tag2 := Byte(bbtMask);

    BrushMasks[aMK].Hint := gResTexts[MASKS_HINTS_TX[aMK]];
    BrushMasks[aMK].OnClick := BrushChange;
  end;

var
  I, K: Integer;
  MK: TKMTileMaskKind;
  hintStr: String;
begin
  inherited Create;

  fLastShape := hsCircle;
  fLastBrush := Byte(SURFACES[0,0]);
  fLastMagicBrush := False;

  Panel_Brushes := TKMScrollPanel.Create(aParent, 0, 28, aParent.Width, aParent.Height - 28, [saVertical], bsMenu, ssCommon);
  Panel_Brushes.Padding.SetBottom(10);
  Panel_Brushes.ScrollV_PadTop := 10;
  Panel_Brushes.ScrollV_PadBottom := 10;
  Panel_Brushes.AnchorsStretch;
//  TKMScrollPanel.Create(Panel_MultiPlayer, 675, 240, SERVER_DETAILS_W, 465, [saVertical], bsMenu, ssCommon);

  with TKMLabel.Create(Panel_Brushes, 0, TERRAIN_PAGE_TITLE_Y, Panel_Brushes.Width, 0, gResTexts[TX_MAPED_TERRAIN_BRUSH], fntOutline, taCenter) do
    Anchors := [anLeft, anTop, anRight];
  BrushSize   := TKMTrackBar.Create(Panel_Brushes, 9, 27, (Panel_Brushes.Width - (BTN_BRUSH_SIZE * 2) - 18) - 18, 0, MAPED_BRUSH_MAX_SIZE);
  BrushSize.Anchors := [anLeft, anTop, anRight];
  BrushSize.Position := 4;
  BrushSize.OnChange := BrushChange;
  BrushSize.Hint := GetHintWHotKey(TX_MAPED_TERRAIN_HEIGHTS_SIZE_HINT, gResTexts[TX_KEY_CTRL_MOUSEWHEEL]);

  BrushCircle := TKMButtonFlat.Create(Panel_Brushes, Panel_Brushes.Width - (BTN_BRUSH_SIZE * 2) - 18,
                                                     25, BTN_BRUSH_SIZE, BTN_BRUSH_SIZE, 592);
  BrushCircle.Anchors := [anTop, anRight];
  BrushCircle.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_HEIGHTS_CIRCLE, kfMapedSubMenuAction1);
  BrushCircle.OnClick := BrushChange;
  BrushCircle.TexOffsetX := 1;
  BrushCircle.TexOffsetY := 1;

  BrushSquare := TKMButtonFlat.Create(Panel_Brushes, Panel_Brushes.Width - BTN_BRUSH_SIZE - 9, 25, BTN_BRUSH_SIZE, BTN_BRUSH_SIZE, 593);
  BrushSquare.Anchors := [anTop, anRight];
  BrushSquare.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_HEIGHTS_SQUARE, kfMapedSubMenuAction2);
  BrushSquare.OnClick := BrushChange;
  BrushSquare.TexOffsetX := 1;
  BrushSquare.TexOffsetY := 1;

  for I := Low(SURFACES) to High(SURFACES) do
    for K := Low(SURFACES[I]) to High(SURFACES[I]) do
    if SURFACES[I,K] <> tkCustom then
    begin
      BrushTable[I,K] := TKMButtonFlat.Create(Panel_Brushes, SURFACES_TAB + K*BTN_TKIND_S_SP_X, 55 + I * 40, BTN_TKIND_S, BTN_TKIND_S, Combo[SURFACES[I,K], SURFACES[I,K], 1] + 1, rxTiles); // grass
      BrushTable[I,K].Anchors := [anTop];
      BrushTable[I,K].Tag := Byte(SURFACES[I,K]);
      BrushTable[I,K].Tag2 := Byte(bbtBrush);
      hintStr := GetEnumName(TypeInfo(TKMTerrainKind), Integer(SURFACES[I,K]));
      BrushTable[I,K].Hint := Copy(hintStr, 3, Length(hintStr) - 2);
      BrushTable[I,K].OnClick := BrushChange;
    end;

  for MK := Low(TKMTileMaskKind) to High(TKMTileMaskKind) do
    CreateBrushMaskBtn(MK);


  MagicBrush := TKMButtonFlat.Create(Panel_Brushes, SURFACES_TAB + High(SURFACES[I])*BTN_TKIND_S_SP_X, 305 + BTN_TKIND_S_SP_Y, 34, 34, 673, rxGui);
  MagicBrush.Anchors := [anTop];
  MagicBrush.Hint := gResTexts[TX_MAPED_TERRAIN_MAGIC_BRUSH_HINT];
  MagicBrush.OnClick := BrushChange;

  top := 390;

  with TKMLabel.Create(Panel_Brushes, 9, NextTop(20), Panel_Brushes.Width - 9, 20, gResTexts[TX_MAPED_TERRAIN_BRUSH_BLENDING], fntMetal, taLeft) do
    Hint := gResTexts[TX_MAPED_TERRAIN_BRUSH_BLENDING_HINT];

  BrushBlending := TKMTrackBar.Create(Panel_Brushes, 9, NextTop(35), BTN_TKIND_S_SP_X*SURF_ROW_LEN, 0, TERRAIN_MAX_BLENDING_LEVEL);
  BrushBlending.Anchors := [anLeft, anTop, anRight];
  BrushBlending.Position := TERRAIN_DEF_BLENDING_LVL; //Default value
  BrushBlending.OnChange := BrushChange;
  BrushBlending.Hint := gResTexts[TX_MAPED_TERRAIN_BRUSH_BLENDING_HINT];

  RandomElements := TKMCheckBox.Create(Panel_Brushes, 9, NextTop(25), Panel_Brushes.Width - 9, 40, gResTexts[TX_MAPED_TERRAIN_BRUSH_RANDOM], fntMetal);
  RandomElements.OnClick := BrushChange;
  RandomElements.Hint := gResTexts[TX_MAPED_TERRAIN_BRUSH_RANDOM];

  OverrideCustomTiles := TKMCheckBox.Create(Panel_Brushes, 9, NextTop(40), Panel_Brushes.Width - 9, 40, gResTexts[TX_MAPED_TERRAIN_OVERRIDE_CUSTOM_TILES], fntMetal);
  OverrideCustomTiles.OnClick := BrushChange;
  OverrideCustomTiles.Hint := gResTexts[TX_MAPED_TERRAIN_OVERRIDE_CUSTOM_TILES_HINT];

  UseTerrainObjects := TKMCheckBox.Create(Panel_Brushes, 9, NextTop(30), Panel_Brushes.Width - 9, 40, gResTexts[TX_MAPED_TERRAIN_BRUSH_USE_OBJECTS], fntMetal);
  UseTerrainObjects.OnClick := BrushChange;
  UseTerrainObjects.Hint := gResTexts[TX_MAPED_TERRAIN_BRUSH_USE_OBJECTS_HINT];

  Button_FixTerrainBrushes := TKMButton.Create(Panel_Brushes, 9, NextTop(40), Panel_Brushes.Width - 16, 30, gResTexts[TX_MAPED_TERRAIN_BRUSH_FIX_TERRAIN], bsGame);
  Button_FixTerrainBrushes.Anchors := [anLeft, anTop, anRight];
  Button_FixTerrainBrushes.AutoHeight := True;
  Button_FixTerrainBrushes.Hint := gResTexts[TX_MAPED_TERRAIN_BRUSH_FIX_TERRAIN_HINT];
  Button_FixTerrainBrushes.OnClick := BrushFixTerrain_Click;

  PopUp_FixTerrainConfirm := TKMPopUpPanel.Create(aParent.MasterParent, 400, 200, gResTexts[TX_MAPED_TERRAIN_BRUSH_FIX_TERRAIN_TITLE], pubgitGray);
    TKMLabel.Create(PopUp_FixTerrainConfirm, PopUp_FixTerrainConfirm.Width div 2, 10, gResTexts[TX_MAPED_TERRAIN_BRUSH_FIX_TERRAIN_CONFIRM], fntGrey, taCenter);

    Button_FixTerrain_Yes := TKMButton.Create(PopUp_FixTerrainConfirm, 10, PopUp_FixTerrainConfirm.Height - 40,
                                             (PopUp_FixTerrainConfirm.Width div 2) - 20, 30, gResTexts[TX_WORD_YES], bsGame);
    Button_FixTerrain_Yes.OnClick := FixTerrainBrushes;
    Button_FixTerrain_No := TKMButton.Create(PopUp_FixTerrainConfirm, (PopUp_FixTerrainConfirm.Width div 2) + 10, PopUp_FixTerrainConfirm.Height - 40,
                                             (PopUp_FixTerrainConfirm.Width div 2) - 20, 30, gResTexts[TX_WORD_CANCEL], bsGame);
    Button_FixTerrain_No.OnClick := BrushFixTerrain_Click;

  fSubMenuActionsEvents[0] := BrushChange;
  fSubMenuActionsEvents[1] := BrushChange;

  fSubMenuActionsCtrls[0,0] := BrushCircle;
  fSubMenuActionsCtrls[1,0] := BrushSquare;
end;


procedure TKMMapEdTerrainBrushes.BrushChange(Sender: TObject);
begin
  gGameCursor.MapEdSize := BrushSize.Position;
  gGameCursor.MapEdRandomizeTiling := RandomElements.Checked;
  gGameCursor.MapEdOverrideCustomTiles := OverrideCustomTiles.Checked;
  gGameCursor.MapEdBlendingLvl := BrushBlending.Position;

  if Sender = UseTerrainObjects then
  begin
    gGameCursor.MapEdUseTerrainObjects:= UseTerrainObjects.Checked;
    if gGameCursor.MapEdObjectsDensity = 0 then
    begin
      gGameCursor.MapEdObjectsType[0] := True;
      gGameCursor.MapEdObjectsType[1] := True;
      gGameCursor.MapEdObjectsDensity := 10;
    end;
  end;

  if gGameCursor.Mode <> cmBrush then
    gGameCursor.Mode := cmBrush;    // This will reset Tag

  if Sender = MagicBrush then
  begin
    gGameCursor.MapEdUseMagicBrush := True;
    fLastMagicBrush := True;
  end
  else
  begin
    if Sender = BrushCircle then
    begin
      gGameCursor.MapEdShape := hsCircle;
      fLastShape := hsCircle;
    end
    else
    if Sender = BrushSquare then
    begin
      gGameCursor.MapEdShape := hsSquare;
      fLastShape := hsSquare;
    end
    else
    if Sender is TKMButtonFlat then
    begin
      if TKMButtonFlat(Sender).Tag2 = Byte(bbtBrush) then
      begin
        gGameCursor.Tag1 := TKMButtonFlat(Sender).Tag;
        fLastBrush := TKMButtonFlat(Sender).Tag;
        fLastMagicBrush := False;
        gGameCursor.MapEdUseMagicBrush := False;
      end else
        gGameCursor.MapEdBrushMask := TKMTileMaskKind(TKMButtonFlat(Sender).Tag);
    end;
  end;

  BrushRefresh;
end;


procedure TKMMapEdTerrainBrushes.BrushRefresh;
var
  I,K: Integer;
  MK: TKMTileMaskKind;
begin
  BrushCircle.Down := (gGameCursor.MapEdShape = hsCircle);
  BrushSquare.Down := (gGameCursor.MapEdShape = hsSquare);
  MagicBrush.Down  := gGameCursor.MapEdUseMagicBrush;

  for I := Low(BrushTable) to High(BrushTable) do
    for K := Low(BrushTable[I]) to High(BrushTable[I]) do
      if gGameCursor.MapEdUseMagicBrush then
      begin
        if BrushTable[I,K] <> nil then
          BrushTable[I,K].Down := False;
      end else
        if BrushTable[I,K] <> nil then
          BrushTable[I,K].Down := (BrushTable[I,K].Tag = gGameCursor.Tag1);

  for MK := Low(TKMTileMaskKind) to High(TKMTileMaskKind) do
    BrushMasks[MK].Down := (BrushMasks[MK].Tag = Byte(gGameCursor.MapEdBrushMask));
end;


procedure TKMMapEdTerrainBrushes.BrushFixTerrain_Click(Sender: TObject);
begin
  PopUp_FixTerrainConfirm.Visible := not PopUp_FixTerrainConfirm.Visible;
end;


procedure TKMMapEdTerrainBrushes.FixTerrainBrushes(Sender: TObject);
begin
  gGame.TerrainPainter.FixTerrainKindInfo;
  PopUp_FixTerrainConfirm.Hide;
end;


procedure TKMMapEdTerrainBrushes.Hide;
begin
  Panel_Brushes.Hide;
end;


procedure TKMMapEdTerrainBrushes.Show;
begin
  if gGameCursor.Mode <> cmBrush then
    gGameCursor.Mode := cmBrush;    // This will reset Tag

  gGameCursor.MapEdShape := fLastShape;
  gGameCursor.MapEdUseMagicBrush := fLastMagicBrush;
  if fLastBrush >= 0 then
    gGameCursor.Tag1 := fLastBrush;

  BrushChange(nil);

  Panel_Brushes.Show;
end;


function TKMMapEdTerrainBrushes.Visible: Boolean;
begin
  Result := Panel_Brushes.Visible;
end;


procedure TKMMapEdTerrainBrushes.MouseWheel(Shift: TShiftState; WheelSteps, X, Y: Integer; var aHandled: Boolean);
begin
  if not aHandled and Visible and (GetKeyState(VK_CONTROL) < 0) then // Do not use ssCtrl in SHift here, as it can sometimes be wrong values inside Shift (ssShift instead of ssCtrl)
  begin
    BrushSize.Position := Max(0, BrushSize.Position - WheelSteps); //can't set negative number
    BrushChange(nil);
    aHandled := True;
  end;
end;


procedure TKMMapEdTerrainBrushes.KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);
begin
  if aHandled then Exit;

  if (Key = VK_ESCAPE) then
  begin
    if PopUp_FixTerrainConfirm.Visible then
    begin
      PopUp_FixTerrainConfirm.Hide;
      aHandled := True;
    end
  end;
end;


procedure TKMMapEdTerrainBrushes.Cancel_Clicked(var aHandled: Boolean);
begin
  if aHandled then Exit;

  // Reset last object on RMB click
  if gGameCursor.Mode = cmBrush then
  begin
    fLastShape := hsCircle;
    fLastBrush := -1;
    fLastMagicBrush := False;
    aHandled := True;
  end;
end;


procedure TKMMapEdTerrainBrushes.UpdateState;
begin
  BrushRefresh;
end;


end.
