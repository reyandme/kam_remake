unit KM_GUIMapEdTerrainBrushes;
{$I KaM_Remake.inc}
interface
uses
   Classes, Math, SysUtils,
   KM_Controls,
   KM_InterfaceDefaults,
   KM_Defaults, KM_Pics, KM_ResTileset;


const
  BRUSH_MAX_SIZE = 32;

type
  //Painting on terrain with terrain brushes
  TKMMapEdTerrainBrushes = class (TKMMapEdSubMenuPage)
  private
    fLastShape: TKMMapEdShape;
    fLastBrush: Integer;
    fLastMagicBrush: Boolean;
    procedure BrushChange(Sender: TObject);
    procedure BrushRefresh;
    procedure BrushSettings_Click(Sender: TObject);
    procedure BrushFixTerrain_Click(Sender: TObject);
    procedure FixTerrainBrushes(Sender: TObject);
  protected
    Panel_Brushes: TKMPanel;
      BrushSize: TKMTrackBar;
      BrushCircle: TKMButtonFlat;
      BrushSquare: TKMButtonFlat;
      BrushTable: array [0..6, 0..4] of TKMButtonFlat;
      BrushMasks: array [TKMTileMaskKind] of TKMButtonFlat;
      MagicBrush: TKMButtonFlat;
      BrushOptions: TKMButtonFlat;
      PopUp_BrushOptions: TKMPopUpPanel;
        RandomElements, ForcePaint: TKMCheckBox;
        Button_FixTerrainBrushes: TKMButton;
        Button_CloseOptions: TKMButton;
        PopUp_FixTerrainConfirm: TKMPopUpPanel;
          Button_FixTerrain_Yes, Button_FixTerrain_No: TKMButton;
  public
    constructor Create(aParent: TKMPanel);

    procedure Show;
    procedure Hide;
    function Visible: Boolean; override;
    procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer; X,Y: Integer; var aHandled: Boolean);
    procedure KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);
    procedure RightClickCancel;
    procedure UpdateState;
  end;


implementation
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLType, {$ENDIF}
  TypInfo, KM_ResFonts, KM_ResTexts, KM_Game, KM_GameCursor, KM_RenderUI, KM_ResKeys,
  KM_TerrainPainter, KM_InterfaceGame, KM_Utils;

type
  TMBrushButtonType = (bbtBrush = -1, bbtMask = -2);


{ TKMMapEdTerrainBrushes }
constructor TKMMapEdTerrainBrushes.Create(aParent: TKMPanel);
const
  SURFACES: array [0..5, 0..4] of TKMTerrainKind = (
    (tkGrass,       tkMoss,         tkPaleGrass,    tkGrassDirt,    tkDirt),
    (tkCoastSand,   tkGrassSand1,   tkGrassSand2,   tkGrassSand3,   tkSand),
    (tkSwamp,       tkGrassyWater,  tkWater,        tkFastWater,    tkCustom),
    (tkShallowSnow, tkSnow,         tkDeepSnow,     tkIce,          tkCustom),
    (tkStone,       tkGoldMount,    tkIronMount,    tkCobbleStone,  tkGravel),
    (tkCoal,        tkGold,         tkIron,         tkLava,         tkAbyss));
  MASKS_HINTS_TX: array [TKMTileMaskKind] of Integer =
                            (TX_MAPED_TERRAIN_NO_MASK_HINT, TX_MAPED_TERRAIN_MASK_1_HINT,
                             TX_MAPED_TERRAIN_MASK_2_HINT,  TX_MAPED_TERRAIN_MASK_3_HINT,
                             TX_MAPED_TERRAIN_MASK_3_HINT); //Not used
var
  I,K: Integer;
  MK: TKMTileMaskKind;
  HintStr: String;
begin
  inherited Create;

  fLastShape := hsCircle;
  fLastBrush := Byte(SURFACES[0,0]);
  fLastMagicBrush := False;

  Panel_Brushes := TKMPanel.Create(aParent, 0, 28, TB_MAP_ED_WIDTH, 400);

  TKMLabel.Create(Panel_Brushes, 0, PAGE_TITLE_Y, TB_MAP_ED_WIDTH, 0, gResTexts[TX_MAPED_TERRAIN_BRUSH], fntOutline, taCenter);
  BrushSize   := TKMTrackBar.Create(Panel_Brushes, 9, 27, 36*5 - 60, 0, BRUSH_MAX_SIZE);
  BrushSize.Position := 4;
  BrushSize.OnChange := BrushChange;
  BrushSize.Hint := GetHintWHotKey(TX_MAPED_TERRAIN_HEIGHTS_SIZE_HINT, gResTexts[TX_KEY_CTRL_MOUSEWHEEL]);

  BrushCircle := TKMButtonFlat.Create(Panel_Brushes, 9 + 36*5 - 54 - 1, 25, 24, 24, 592);
  BrushCircle.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_HEIGHTS_CIRCLE, SC_MAPEDIT_SUB_MENU_ACTION_1);
  BrushCircle.OnClick := BrushChange;
  BrushCircle.TexOffsetX := 1;
  BrushCircle.TexOffsetY := 1;

  BrushSquare := TKMButtonFlat.Create(Panel_Brushes, 9 + 36*5 - 24 - 1, 25, 24, 24, 593);
  BrushSquare.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_HEIGHTS_SQUARE, SC_MAPEDIT_SUB_MENU_ACTION_2);
  BrushSquare.OnClick := BrushChange;
  BrushSquare.TexOffsetX := 1;
  BrushSquare.TexOffsetY := 1;

  for I := Low(SURFACES) to High(SURFACES) do
    for K := Low(SURFACES[I]) to High(SURFACES[I]) do
    if SURFACES[I,K] <> tkCustom then
    begin
      BrushTable[I,K] := TKMButtonFlat.Create(Panel_Brushes, 9 + K * 36, 55 + I * 40, 34, 34, Combo[SURFACES[I,K], SURFACES[I,K], 1] + 1, rxTiles); // grass
      BrushTable[I,K].Tag := Byte(SURFACES[I,K]);
      BrushTable[I,K].Tag2 := Byte(bbtBrush);
      HintStr := GetEnumName(TypeInfo(TKMTerrainKind), Integer(SURFACES[I,K]));
      BrushTable[I,K].Hint := Copy(HintStr, 3, Length(HintStr) - 2);
      BrushTable[I,K].OnClick := BrushChange;
    end;

  for MK := Low(TKMTileMaskKind) to High(TKMTileMaskKind) do
  begin
    BrushMasks[MK] := TKMButtonFlat.Create(Panel_Brushes, 9 + Byte(MK) * 36, 295, 34, 34, TILE_MASK_KINDS_PREVIEW[MK] + 1, rxTiles);
    BrushMasks[MK].Tag := Byte(MK);
    BrushMasks[MK].Tag2 := Byte(bbtMask);

    BrushMasks[MK].Hint := gResTexts[MASKS_HINTS_TX[MK]];
    BrushMasks[MK].OnClick := BrushChange;
  end;

  BrushMasks[mkHardest].Hide;

  MagicBrush := TKMButtonFlat.Create(Panel_Brushes, 9 + 36*4, 295, 34, 34, 673, rxGui);
  MagicBrush.Hint := gResTexts[TX_MAPED_TERRAIN_MAGIC_BRUSH_HINT];
  MagicBrush.OnClick := BrushChange;

  BrushOptions := TKMButtonFlat.Create(Panel_Brushes, 9 + 2, 335, TB_WIDTH - 2, 21, 0);
  BrushOptions.Caption := gResTexts[TX_MAPED_TERRAIN_BRUSH_OPTIONS];
  BrushOptions.CapOffsetY := -11;
  BrushOptions.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_BRUSH_OPTIONS_HINT, SC_MAPEDIT_SUB_MENU_ACTION_3);
  BrushOptions.OnClick := BrushSettings_Click;

  PopUp_BrushOptions := TKMPopUpPanel.Create(aParent.MasterParent, 400, 200, gResTexts[TX_MAPED_TERRAIN_BRUSH_OPTIONS_TITLE], pubgit_Gray);

    RandomElements := TKMCheckBox.Create(PopUp_BrushOptions, 10, 10, 280, 40, gResTexts[TX_MAPED_TERRAIN_BRUSH_RANDOM], fntMetal);
    RandomElements.OnClick := BrushChange;
    RandomElements.Hint := gResTexts[TX_MAPED_TERRAIN_BRUSH_RANDOM];

    ForcePaint := TKMCheckBox.Create(PopUp_BrushOptions, 10, 35, 280, 40, gResTexts[TX_MAPED_TERRAIN_FORCE_PAINT], fntMetal);
    ForcePaint.OnClick := BrushChange;
    ForcePaint.Hint := gResTexts[TX_MAPED_TERRAIN_FORCE_PAINT_HINT];

    Button_FixTerrainBrushes := TKMButton.Create(PopUp_BrushOptions, (PopUp_BrushOptions.Width div 2) - 190, 110,
                                                 380, 30, gResTexts[TX_MAPED_TERRAIN_BRUSH_FIX_TERRAIN], bsGame);
    Button_FixTerrainBrushes.Hint := gResTexts[TX_MAPED_TERRAIN_BRUSH_FIX_TERRAIN_HINT];
    Button_FixTerrainBrushes.OnClick := BrushFixTerrain_Click;

    PopUp_FixTerrainConfirm := TKMPopUpPanel.Create(aParent.MasterParent, 400, 200, gResTexts[TX_MAPED_TERRAIN_BRUSH_FIX_TERRAIN_TITLE], pubgit_Gray);
      TKMLabel.Create(PopUp_FixTerrainConfirm, PopUp_FixTerrainConfirm.Width div 2, 10, gResTexts[TX_MAPED_TERRAIN_BRUSH_FIX_TERRAIN_CONFIRM], fntGrey, taCenter);

      Button_FixTerrain_Yes := TKMButton.Create(PopUp_FixTerrainConfirm, 10, PopUp_FixTerrainConfirm.Height - 40, 
                                               (PopUp_FixTerrainConfirm.Width div 2) - 20, 30, gResTexts[TX_WORD_YES], bsGame);  
      Button_FixTerrain_Yes.OnClick := FixTerrainBrushes;
      Button_FixTerrain_No := TKMButton.Create(PopUp_FixTerrainConfirm, (PopUp_FixTerrainConfirm.Width div 2) + 10, PopUp_FixTerrainConfirm.Height - 40,
                                               (PopUp_FixTerrainConfirm.Width div 2) - 20, 30, gResTexts[TX_WORD_CANCEL], bsGame);  
      Button_FixTerrain_No.OnClick := BrushFixTerrain_Click;

    Button_CloseOptions  := TKMButton.Create(PopUp_BrushOptions, (PopUp_BrushOptions.Width div 2) - 60, PopUp_BrushOptions.Height - 40,
                                              120, 30, gResTexts[TX_WORD_CLOSE], bsGame);
    Button_CloseOptions.OnClick := BrushSettings_Click;

  fSubMenuActionsEvents[0] := BrushChange;
  fSubMenuActionsEvents[1] := BrushChange;
  fSubMenuActionsEvents[2] := BrushSettings_Click;

  fSubMenuActionsCtrls[0] := BrushCircle;
  fSubMenuActionsCtrls[1] := BrushSquare;
  fSubMenuActionsCtrls[2] := BrushOptions;
end;


procedure TKMMapEdTerrainBrushes.BrushChange(Sender: TObject);
begin
  gGameCursor.MapEdSize := BrushSize.Position;
  gGame.MapEditor.TerrainPainter.RandomizeTiling := RandomElements.Checked;
  gGame.MapEditor.TerrainPainter.ForcePaint := ForcePaint.Checked;

  if gGameCursor.Mode <> cmBrush then
    gGameCursor.Mode := cmBrush;    // This will reset Tag

  if Sender = MagicBrush then
  begin
    gGameCursor.MapEdMagicBrush := True;
    fLastMagicBrush := True;
  end else
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
        gGameCursor.MapEdMagicBrush := False;
      end else
        gGameCursor.MapEdBrushMask := TKMButtonFlat(Sender).Tag;
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
  MagicBrush.Down  := gGameCursor.MapEdMagicBrush;
  for I := Low(BrushTable) to High(BrushTable) do
    for K := Low(BrushTable[I]) to High(BrushTable[I]) do
      if gGameCursor.MapEdMagicBrush then
      begin
        if BrushTable[I,K] <> nil then
          BrushTable[I,K].Down := False;
      end else
        if BrushTable[I,K] <> nil then
          BrushTable[I,K].Down := (BrushTable[I,K].Tag = gGameCursor.Tag1);

  for MK := Low(TKMTileMaskKind) to High(TKMTileMaskKind) do
    BrushMasks[MK].Down := (BrushMasks[MK].Tag = gGameCursor.MapEdBrushMask);
end;


procedure TKMMapEdTerrainBrushes.BrushSettings_Click(Sender: TObject);
begin
  PopUp_BrushOptions.Visible := not PopUp_BrushOptions.Visible;
end;


procedure TKMMapEdTerrainBrushes.BrushFixTerrain_Click(Sender: TObject);
begin
  PopUp_FixTerrainConfirm.Visible := not PopUp_FixTerrainConfirm.Visible;
  PopUp_BrushOptions.Visible := not PopUp_BrushOptions.Visible;
end;


procedure TKMMapEdTerrainBrushes.FixTerrainBrushes(Sender: TObject);
begin
  gGame.MapEditor.TerrainPainter.FixTerrainKindInfo;
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
  gGameCursor.MapEdMagicBrush := fLastMagicBrush;
  if fLastBrush >= 0 then
    gGameCursor.Tag1 := fLastBrush;

  BrushChange(nil);

  Panel_Brushes.Show;
end;


function TKMMapEdTerrainBrushes.Visible: Boolean;
begin
  Result := Panel_Brushes.Visible;
end;


procedure TKMMapEdTerrainBrushes.MouseWheel(Shift: TShiftState; WheelDelta, X, Y: Integer; var aHandled: Boolean);
begin
  if not aHandled and Visible and (GetKeyState(VK_CONTROL) < 0) then // Do not use ssCtrl in SHift here, as it can sometimes be wrong values inside Shift (ssShift instead of ssCtrl)
  begin
    BrushSize.Position := Max(0, BrushSize.Position - (WheelDelta div 100)); //can't set negative number
    BrushChange(nil);
    aHandled := True;
  end;
end;


procedure TKMMapEdTerrainBrushes.KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);
begin
  if (Key = VK_ESCAPE) then
  begin
    if PopUp_BrushOptions.Visible then
    begin
      PopUp_BrushOptions.Hide;
      aHandled := True;
    end
    else
    if PopUp_FixTerrainConfirm.Visible then
    begin
      PopUp_FixTerrainConfirm.Hide;
      aHandled := True;
    end
  end;
end;


procedure TKMMapEdTerrainBrushes.RightClickCancel;
begin
  // Reset last object on RMB click
  if gGameCursor.Mode = cmBrush then
  begin
    fLastShape := hsCircle;
    fLastBrush := -1;
    fLastMagicBrush := False;
  end;
end;


procedure TKMMapEdTerrainBrushes.UpdateState;
begin
  BrushRefresh;
end;


end.
