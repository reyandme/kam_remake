unit KM_GUIMapEdTerrainTiles;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  Classes, Math, SysUtils,
  KM_InterfaceDefaults,
  KM_Controls, KM_ControlsBase, KM_ControlsEdit, KM_ControlsPopUp, KM_ControlsScroll, KM_ControlsSwitch,
  KM_Defaults, KM_Pics, KM_Points;


const
  //Tile table sizes
  MAPED_TILES_X = 6;
  MAPED_TILES_Y = 8;
  TABLE_ELEMS = 608;

type
  TKMMapEdTerrainTiles = class(TKMMapEdSubMenuPage)
  private
    fLastTile: Word;

    procedure TilesChange(Sender: TObject);
    procedure TilesSet(aIndex: Integer);
    procedure TilesRefresh(Sender: TObject);
    function GetTileTexIDFromTag(aTag: Byte; aScrollPosition: Integer = -1): Word;
    function IsTileVisible(aTextId: Integer): Boolean;
    procedure TilesPalette_ToggleVisibility(Sender: TObject);
  protected
    Panel_Tiles: TKMPanel;
      TilesTable: array [0..MAPED_TILES_X * MAPED_TILES_Y - 1] of TKMButtonFlat; //how many are visible?
      TilesScroll: TKMScrollBar;
      TilesRandom: TKMCheckBox;
      TilesMagicWater, TilesEyedropper, TilesRotate: TKMButtonFlat;
      NumEdit_SetTileNumber: TKMNumericEdit;
    TilesPalette_Button:  TKMButtonFlat;
    Panel_TilesPalettePopup: TKMPopUpPanel;
      Panel_TilesPalette: TKMScrollPanel;
        TilesPaletteTbl: array [0..TABLE_ELEMS - 1] of TKMButtonFlat;
        TilesPaletteRandom: TKMCheckBox;
        TilesPaletteMagicWater, TilesPaletteEyedropper, TilesPaletteRotate: TKMButtonFlat;
        NumEdit_SetTilePaletteNumber: TKMNumericEdit;
  public
    constructor Create(aParent: TKMPanel);

    procedure KeyDown(Key: Word; Shift: TShiftState; aIsFirst: Boolean; var aHandled: Boolean);

    procedure TilesTableSetTileTexId(aTexId: Integer);

    procedure Show;
    procedure Hide;

    function Visible: Boolean; override;
    function IsFocused: Boolean; override;
    function IsPaletteVisible: Boolean;
    procedure PaletteHide;

    procedure UpdateHotkeys;
    procedure UpdateState;
  end;


implementation
uses
  KM_Resource, KM_ResFonts, KM_ResTexts, KM_ResTilesetTypes, KM_ResKeys,
  KM_Cursor, KM_RenderUI, KM_InterfaceGame,
  KM_Utils, KM_CommonUtils,
  KM_ResTypes;

const
  //Tiles table was initially made by JBSnorro, thanks to him :)
  MapEdTileRemap: array [0..TABLE_ELEMS - 1] of Integer = (
     1,73,74,75, 37, 21, 22, 38, 33, 34, 32,181,173,177,129,130,131,132,133,  0,274,270,269,267,268,271,272,273,303, 49,193,197,217,225,  0,  0, 45, 24, 13, 23,208,224, 26,216,  8,  0, 359,358,367,362,363,366,382,384,387,455,454,463,458,459,462,515,514,523,518,519,522,538,540,543,575,574,583,578,579,582,
    27,76,77,78, 36, 39, 40,198,100,101,102,189,169,185,134,135,136,137,138,275,283,279,278,276,277,280,281,282,304,124,125,126,229,218,219,220, 46, 11,  5,  0,195, 25,203,207,301,  0, 361,360,368,364,365,369,383,385,386,457,456,464,460,461,465,517,516,524,520,521,525,539,541,542,577,576,584,580,581,585,
    28,79,80,81, 35, 88, 89, 90, 70, 71, 72,182,174,178,196,139,140,141,142,302,  0,309,310,  0,  0,311,312,  0,  0,127,128,  0,230,226,227,228, 47,204,205,206,199,200,265,266, 16,  0, 395,394,403,398,399,402,478,480,483,491,490,499,494,495,498,551,550,559,554,555,558,418,420,421,431,430,439,434,435,438,
    29,82,83,84, 85, 86, 87,  0,112,113,114,190,110,111,161,162,163,164,165,  0,291,287,286,284,285,288,289,290,305,106,107,108,233,234,231,  0, 48,221,213,214,352,353,354,347,348,349, 397,396,405,400,401,404,479,481,482,493,492,501,496,497,500,553,552,561,556,557,560,419,422,423,433,432,441,437,436,440,
    30,94,95,96, 57, 58, 59,  0,103,104,105,183,175,179,157,202,158,159,160,300,299,295,294,292,293,296,297,298,306,117,118,119,209,210,241,245,194,248, 65, 66,355,356,357,166, 51, 54, 371,370,379,374,375,378,388,390,391,467,466,475,470,471,474,527,526,535,530,531,534,544,546,547,587,586,595,590,591,594,
    31, 9,19,20, 41, 42, 43, 44,320,321,322,191,171,187,149,150,260,151,152,261,323,324,325,332,333,334,341,342,343,242,243,244,235,238,239,240,  0, 50,172, 52,257,258,259,246,232,  0, 373,372,381,376,377,380,389,392,393,469,468,476,472,473,477,529,528,536,532,533,537,545,548,549,589,588,596,592,593,597,
    18,67,68,69, 91, 92, 93,  0,  6,  7, 10,184,176,180,145,146,147,148,308,  0,326,327,328,335,336,337,344,345,346,115,116,120,236,237,143,144,  0, 53,167, 55,262,263,307,223,222,247, 407,406,415,410,411,414,484,486,487,503,502,511,506,507,510,563,562,571,566,567,570,424,426,427,443,442,451,446,447,450,
    17,97,98,99, 12, 14, 15,  0,  3,  4,  2,192,168,188,153,154,155,156,264,  0,329,330,331,338,339,340,  0,  0,  0,121,122,123,211,212,201,  0,316,317,318,319,313,314,315,215,350,351, 409,408,417,412,413,416,485,488,489,505,504,513,508,509,512,565,564,573,568,569,572,425,428,429,445,444,453,449,448,452
    );
    // 247 - doesn't work in game, replaced with random road

var
  TABLE_ELEMS_CNT: Integer;

const
  PAL_S = 34;

  PAL_ROWS: array [0..3] of Integer = (0, 29, 46, 76);
  PAL_Y_GAP = 5;
  MAX_ROW_SIZE = 30;


{ TKMMapEdTerrainTiles }
constructor TKMMapEdTerrainTiles.Create(aParent: TKMPanel);
const
  BTN_SIZE_S = 34;
  BTN_SIZE = 36;


  TB_TLS_M = 9;
  TB_TLS_R = 9;
  TB_TLS_S = 13;
  TB_TLS_T = 13;


var
  I,J,K,X,Y, lineWidthCnt, texID, palW, palH, row, index: Integer;
begin
  inherited Create;

//  TABLE_ELEMS_CNT := Ceil(TILES_CNT / MAPED_TILES_Y) * MAPED_TILES_Y;
  TABLE_ELEMS_CNT := TABLE_ELEMS;

  Panel_Tiles := TKMPanel.Create(aParent, 0, 28, aParent.Width, 400);
  with TKMLabel.Create(Panel_Tiles, 0, TERRAIN_PAGE_TITLE_Y, Panel_Tiles.Width, 0, gResTexts[TX_MAPED_TERRAIN_HINTS_TILES], fntOutline, taCenter) do
    Anchors := [anLeft, anTop, anRight];

  TilesMagicWater := TKMButtonFlat.Create(Panel_Tiles, TB_TLS_M, 25, BTN_SIZE_S, BTN_SIZE_S, 670);
  TilesMagicWater.OnClick := TilesChange;

  TilesEyedropper := TKMButtonFlat.Create(Panel_Tiles, TB_TLS_M + BTN_SIZE_S + 2, 25, BTN_SIZE_S, BTN_SIZE_S, 671);
  TilesEyedropper.OnClick := TilesChange;

  TilesRotate := TKMButtonFlat.Create(Panel_Tiles, TB_TLS_R + 2*BTN_SIZE_S + 4, 25, BTN_SIZE_S, BTN_SIZE_S, 672);
  TilesRotate.OnClick := TilesChange;

  NumEdit_SetTileNumber := TKMNumericEdit.Create(Panel_Tiles, Panel_Tiles.Width - 73, 29, 0, MAX_TILE_TO_SHOW - 1);
  NumEdit_SetTileNumber.Anchors := [anTop, anRight];
  NumEdit_SetTileNumber.Hint := gResTexts[TX_MAPED_TERRAIN_TILE_ID_EDIT_HINT];
  NumEdit_SetTileNumber.OnChange := TilesChange;
  NumEdit_SetTileNumber.AutoFocusable := False;

  TilesRandom := TKMCheckBox.Create(Panel_Tiles, TB_TLS_R, 25 + BTN_SIZE + 5, Panel_Tiles.Width - TB_TLS_R, 20, gResTexts[TX_MAPED_TERRAIN_TILES_RANDOM], fntMetal);
  TilesRandom.Checked := True;
  TilesRandom.OnClick := TilesChange;

  //Create scroll first to link to its MouseWheel event
  TilesScroll := TKMScrollBar.Create(Panel_Tiles, TB_TLS_S, 23 + BTN_SIZE + 28 + 4 + MAPED_TILES_Y * 32, 194, 20, saHorizontal, bsGame);
  TilesScroll.MaxValue := (TABLE_ELEMS_CNT div MAPED_TILES_Y) - MAPED_TILES_X; // 32 - 6
  TilesScroll.Position := 0;
  TilesScroll.OnChange := TilesRefresh;

  for J := 0 to MAPED_TILES_Y - 1 do
    for K := 0 to MAPED_TILES_X - 1 do
    begin
      TilesTable[J * MAPED_TILES_X + K] := TKMButtonFlat.Create(Panel_Tiles, TB_TLS_T + K * 32, 23 + BTN_SIZE + 28 + J * 32, 32, 32, 1, rxTiles);
      TilesTable[J * MAPED_TILES_X + K].Tag :=  J * MAPED_TILES_X + K; //Store ID
      TilesTable[J * MAPED_TILES_X + K].OnClick := TilesChange;
      TilesTable[J * MAPED_TILES_X + K].OnMouseWheel := TilesScroll.MouseWheel;
    end;

  TilesPalette_Button := TKMButtonFlat.Create(Panel_Tiles, 9, 23 + BTN_SIZE + 28 + 4 + MAPED_TILES_Y * 32 + 25, Panel_Tiles.Width - 9, 21, 0);
  TilesPalette_Button.Anchors := [anLeft, anTop, anRight];
  TilesPalette_Button.Caption := gResTexts[TX_MAPED_TERRAIN_TILES_PALETTE];
  TilesPalette_Button.CapOffsetY := -11;
  TilesPalette_Button.OnClick := TilesPalette_ToggleVisibility;

  palW := MAX_ROW_SIZE * PAL_S + 50;
  palH := (Length(PAL_ROWS) - 1)*MAPED_TILES_Y*PAL_S + Length(PAL_ROWS) * PAL_Y_GAP + 40;

  Panel_TilesPalettePopup := TKMPopUpPanel.Create(aParent.MasterControl.MasterPanel,
                                                  palW,
                                                  palH,
                                                  gResTexts[TX_MAPED_TERRAIN_TILES_PALETTE],
                                                  pbYellow, True);
  Panel_TilesPalettePopup.DragEnabled := True;
  Panel_TilesPalettePopup.CapOffsetY := -5;
    Panel_TilesPalette := TKMScrollPanel.Create(Panel_TilesPalettePopup.ItemsPanel, 10, 5,
                                                Panel_TilesPalettePopup.ActualWidth - 40,
                                                Panel_TilesPalettePopup.ActualHeight - 40,
                                                [saHorizontal, saVertical], bsGame, ssCommon);
//    Panel_TilesPalette.ScrollV.Left := Panel_TilesPalette.ScrollV.Left + 20;
    Panel_TilesPalette.Padding.SetRight(10);
    Panel_TilesPalette.Padding.SetBottom(10);
    Panel_TilesPalette.AnchorsStretch;
      lineWidthCnt := TABLE_ELEMS div MAPED_TILES_Y;
      for row := Low(PAL_ROWS) to High(PAL_ROWS) - 1 do
        for I := PAL_ROWS[row] to PAL_ROWS[row + 1] - 1 do
          for J := 0 to MAPED_TILES_Y - 1 do
          begin
            K := I - PAL_ROWS[row];
            index := J * lineWidthCnt + I;

            X := K * PAL_S;
            if row = 1 then
              X := X + 8 * PAL_S;
//              X := X + (MAX_ROW_SIZE - (PAL_ROWS[row + 1] - PAL_ROWS[row])) * PAL_S;

            Y := (J + MAPED_TILES_Y*row) * PAL_S + PAL_Y_GAP*row;

            texID := MapEdTileRemap[index];
            TilesPaletteTbl[index] := TKMButtonFlat.Create(Panel_TilesPalette, X, Y, 32, 32, texID, rxTiles);
            TilesPaletteTbl[index].Tag :=  J * lineWidthCnt + K; //Store ID
            TilesPaletteTbl[index].Clickable := texID <> 0;
            TilesPaletteTbl[index].HideHighlight := texID = 0;
            TilesPaletteTbl[index].OnClick := TilesChange;
            if texID = 0 then
              TilesPaletteTbl[index].Hint := ''
            else
              //Show 0..N-1 to be consistent with objects and script commands like States.MapTileObject
              TilesPaletteTbl[index].Hint := IntToStr(texID - 1);
          end;

      TilesPaletteMagicWater := TKMButtonFlat.Create(Panel_TilesPalette, 0, (MAPED_TILES_Y + 1)*PAL_S, BTN_SIZE_S, BTN_SIZE_S, 670);
      TilesPaletteMagicWater.OnClick := TilesChange;

      TilesPaletteEyedropper := TKMButtonFlat.Create(Panel_TilesPalette, BTN_SIZE_S + 2, (MAPED_TILES_Y + 1)*PAL_S, BTN_SIZE_S, BTN_SIZE_S, 671);
      TilesPaletteEyedropper.OnClick := TilesChange;

      TilesPaletteRotate := TKMButtonFlat.Create(Panel_TilesPalette, 2*BTN_SIZE_S + 4, (MAPED_TILES_Y + 1)*PAL_S, BTN_SIZE_S, BTN_SIZE_S, 672);
      TilesPaletteRotate.OnClick := TilesChange;

      NumEdit_SetTilePaletteNumber := TKMNumericEdit.Create(Panel_TilesPalette, 3*BTN_SIZE_S + 35, (MAPED_TILES_Y + 1)*PAL_S + ((PAL_S - 20) div 2), 0, MAX_TILE_TO_SHOW - 1);
      NumEdit_SetTilePaletteNumber.Hint := gResTexts[TX_MAPED_TERRAIN_TILE_ID_EDIT_HINT];
      NumEdit_SetTilePaletteNumber.OnChange := TilesChange;
      NumEdit_SetTilePaletteNumber.AutoFocusable := False;

      TilesPaletteRandom := TKMCheckBox.Create(Panel_TilesPalette, 0, (MAPED_TILES_Y + 1)*PAL_S + BTN_SIZE + 5, Panel_Tiles.Width - TB_TLS_R, 20, gResTexts[TX_MAPED_TERRAIN_TILES_RANDOM], fntMetal);
      TilesPaletteRandom.Checked := True;
      TilesPaletteRandom.OnClick := TilesChange;

  // Set actual width afterwards, so we will set proper BaseWidth on creation and other controls will fit in as they should
  Panel_TilesPalettePopup.ActualWidth  := Min(Panel_Tiles.Parent.MasterControl.MasterPanel.Width, palW);
  Panel_TilesPalettePopup.ActualHeight := Min(Panel_Tiles.Parent.MasterControl.MasterPanel.Height,palH);


  fSubMenuActionsEvents[0] := TilesChange;
  fSubMenuActionsEvents[1] := TilesChange;
  fSubMenuActionsEvents[2] := TilesChange;
  fSubMenuActionsEvents[3] := TilesChange;

  fSubMenuActionsCtrls[0,0] := TilesMagicWater;
  fSubMenuActionsCtrls[1,0] := TilesEyedropper;
  fSubMenuActionsCtrls[2,0] := TilesRotate;
  fSubMenuActionsCtrls[3,0] := TilesRandom;

  fSubMenuActionsCtrls[0,1] := TilesPaletteMagicWater;
  fSubMenuActionsCtrls[1,1] := TilesPaletteEyedropper;
  fSubMenuActionsCtrls[2,1] := TilesPaletteRotate;
  fSubMenuActionsCtrls[3,1] := TilesPaletteRandom;
end;


procedure TKMMapEdTerrainTiles.TilesChange(Sender: TObject);
var
  isMagicWater, isEyedropper, isRotate, isRandom, isTileNum: Boolean;
  value: Integer;
begin
  isMagicWater := (Sender = TilesMagicWater) or (Sender = TilesPaletteMagicWater);
  isEyedropper := (Sender = TilesEyedropper) or (Sender = TilesPaletteEyedropper);
  isRotate     := (Sender = TilesRotate) or (Sender = TilesPaletteRotate);
  isRandom     := (Sender = TilesRandom) or (Sender = TilesPaletteRandom);
  isTileNum    := (Sender = NumEdit_SetTileNumber) or (Sender = NumEdit_SetTilePaletteNumber);

  // Do not hide palette on random check
  if not isRandom and not isTileNum then
    Panel_TilesPalettePopup.Hide;

  TilesMagicWater.Down := isMagicWater and not TilesMagicWater.Down;
  TilesPaletteMagicWater.Down := TilesMagicWater.Down;

  TilesEyedropper.Down := isEyedropper and not TilesEyedropper.Down;
  TilesPaletteEyedropper.Down := TilesEyedropper.Down;

  TilesRotate.Down := isRotate and not TilesRotate.Down;
  TilesPaletteRotate.Down := TilesRotate.Down;

  if isMagicWater then
  begin
    if TilesMagicWater.Down then
      gCursor.Mode := cmMagicWater
    else
      gCursor.Mode := cmNone;
  end else

  if isEyedropper then
  begin
    if TilesEyedropper.Down then
      gCursor.Mode := cmEyedropper
    else
      gCursor.Mode := cmNone;
  end else

  if isRotate then
  begin
    if TilesRotate.Down then
      gCursor.Mode := cmRotateTile
    else
      gCursor.Mode := cmNone;
  end else

  if isRandom then
    gCursor.MapEdDir := 4 * Byte(TKMCheckBox(Sender).Checked) //Defined=0..3 or Random=4
  else

  if isTileNum then
  begin
    value := TKMNumericEdit(Sender).Value;
    NumEdit_SetTileNumber.Value := value;
    NumEdit_SetTilePaletteNumber.Value := value;

    if gRes.Tileset.TileIsAllowedToSet(value) then
    begin
      TilesSet(value + 1);
      TilesTableSetTileTexId(value);
    end
  end else

  if (Sender is TKMButtonFlat)
    and not (Sender = TilesMagicWater)
    and not (Sender = TilesRotate)
    and not (Sender = TilesEyedropper) then
    TilesSet(TKMButtonFlat(Sender).TexID);

  // Refresh immediately
  TilesRefresh(nil);
end;


procedure TKMMapEdTerrainTiles.TilesPalette_ToggleVisibility(Sender: TObject);
begin
  Panel_TilesPalettePopup.ToggleVisibility;
end;


function TKMMapEdTerrainTiles.IsTileVisible(aTextId: Integer): Boolean;
var
  I, K, rowStart: Integer;
begin
  Result := False;
  for I := 0 to MAPED_TILES_Y - 1 do
  begin
    rowStart := I * (TABLE_ELEMS_CNT div MAPED_TILES_Y) + TilesScroll.Position;
    for K := rowStart to rowStart + MAPED_TILES_X - 1 do
      if MapEdTileRemap[K] = aTextId + 1 then
      begin
        Result := True;
        Exit;
      end;
  end;

end;


procedure TKMMapEdTerrainTiles.KeyDown(Key: Word; Shift: TShiftState; aIsFirst: Boolean; var aHandled: Boolean);
begin
  if aHandled or not aIsFirst then Exit;

  if (Key = VK_ESCAPE) and Panel_TilesPalettePopup.Visible then
  begin
    Panel_TilesPalettePopup.Hide;
    aHandled := True;
  end
  else
  if Key = gResKeys[kfMapedTilesPalette] then
  begin
    Panel_TilesPalettePopup.ToggleVisibility;
    aHandled := True;
  end;
end;


procedure TKMMapEdTerrainTiles.TilesTableSetTileTexId(aTexId: Integer);
var
  I,K,L,SP: Integer;
begin
  if Self = nil then Exit;

  NumEdit_SetTileNumber.Value := aTexId;
  NumEdit_SetTilePaletteNumber.Value := aTexId;

  // Set proper scroll position
  if not IsTileVisible(aTexId) then
    for SP := 0 to TilesScroll.MaxValue do
      for I := 0 to MAPED_TILES_Y - 1 do
        for K := 0 to MAPED_TILES_X - 1 do
        begin
          L := I * MAPED_TILES_X + K;
          if aTexId = GetTileTexIDFromTag(L, SP) - 1 then
          begin
            if TilesScroll.Position = SP then
              Exit;
            TilesScroll.Position := SP;
            TilesRefresh(nil);
            Exit;
          end;
        end;
end;


procedure TKMMapEdTerrainTiles.TilesSet(aIndex: Integer);
begin
  TilesMagicWater.Down := False;
//  TilesEyedropper.Down := False;
  if aIndex <> 0 then
  begin
    gCursor.Mode := cmTiles;
    gCursor.Tag1 := aIndex - 1; //MapEdTileRemap is 1 based, tag is 0 based

    if TilesRandom.Checked then
      gCursor.MapEdDir := 4;

    //Remember last selected Tile
    fLastTile := aIndex;
  end;
  // Will also set proper scroll position
  // todo: reduce number of TilesRefresh calls
  TilesTableSetTileTexId(aIndex - 1);
  TilesRefresh(nil);
end;


function TKMMapEdTerrainTiles.GetTileTexIDFromTag(aTag: Byte; aScrollPosition: Integer = -1): Word;
var
  X,Y: Byte;
  tile: Word;
  scrollPosition: Integer;
begin
  scrollPosition := IfThen(aScrollPosition = -1, TilesScroll.Position, aScrollPosition);

  X := aTag mod MAPED_TILES_X + scrollPosition;
  Y := (aTag div MAPED_TILES_X);
  tile := (TABLE_ELEMS_CNT div MAPED_TILES_Y) * Y + X;
//  if Tile > TILES_CNT then
//    Result := 0;

  Result := MapEdTileRemap[tile];
end;


procedure TKMMapEdTerrainTiles.TilesRefresh(Sender: TObject);
var
  I,K,L: Integer;
  TileTexID, row: Integer;
begin
  TilesRandom.Checked  := (gCursor.MapEdDir = 4);
  TilesMagicWater.Down := gCursor.Mode = cmMagicWater;
  TilesEyedropper.Down := gCursor.Mode = cmEyedropper;
  TilesRotate.Down     := gCursor.Mode = cmRotateTile;

  TilesPaletteRandom.Checked  := TilesRandom.Checked;
  TilesPaletteMagicWater.Down := TilesMagicWater.Down;
  TilesPaletteEyedropper.Down := TilesEyedropper.Down;
  TilesPaletteRotate.Down     := TilesRotate.Down;

  for I := 0 to MAPED_TILES_Y - 1 do
  for K := 0 to MAPED_TILES_X - 1 do
  begin
    L := I * MAPED_TILES_X + K;
    TileTexID := GetTileTexIDFromTag(L);
    TilesTable[L].TexID := TileTexID;
    //Don't disable it because then scrollwheel doesn't work
    TilesTable[L].HideHighlight := TileTexID = 0;
    TilesTable[L].Clickable := TileTexID <> 0;
    if TileTexID = 0 then
      TilesTable[L].Hint := ''
    else
      //Show 0..N-1 to be consistent with objects and script commands like States.MapTileObject
      TilesTable[L].Hint := IntToStr(TileTexID - 1);
    //If cursor has a tile then make sure its properly selected in table as well
    TilesTable[L].Down := (gCursor.Mode in [cmTiles, cmEyedropper]) and (gCursor.Tag1 = TileTexID - 1);
  end;

  row := TABLE_ELEMS div MAPED_TILES_Y;
  for I := 0 to MAPED_TILES_Y - 1 do
    for K := 0 to row - 1 do
      TilesPaletteTbl[I * row + K].Down := (gCursor.Mode in [cmTiles, cmEyedropper]) and (gCursor.Tag1 = MapEdTileRemap[I * row + K] - 1)
end;


procedure TKMMapEdTerrainTiles.Show;
begin
  TilesSet(fLastTile);
  gCursor.MapEdDir := 0;
  Panel_Tiles.Show;
end;


function TKMMapEdTerrainTiles.Visible: Boolean;
begin
  Result := Panel_Tiles.Visible;
end;


function TKMMapEdTerrainTiles.IsFocused: Boolean;
begin
  Result := Visible or Panel_TilesPalettePopup.Visible;
end;


function TKMMapEdTerrainTiles.IsPaletteVisible: Boolean;
begin
  Result := Panel_TilesPalettePopup.Visible;
end;


procedure TKMMapEdTerrainTiles.PaletteHide;
begin
  Panel_TilesPalettePopup.Hide;
end;


procedure TKMMapEdTerrainTiles.Hide;
begin
  Panel_Tiles.Hide;
end;


procedure TKMMapEdTerrainTiles.UpdateHotkeys;
begin
  TilesPalette_Button.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_TILES_PALETTE, kfMapedTilesPalette);

  TilesMagicWater.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_MAGIC_WATER_HINT,  kfMapedSubMenuAction1);
  TilesEyedropper.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_EYEDROPPER_HINT,   kfMapedSubMenuAction2);
  TilesRotate.Hint     := GetHintWHotkey(TX_MAPED_TERRAIN_ROTATE_TILE,       kfMapedSubMenuAction3);
  TilesRandom.Hint     := GetHintWHotkey(TX_MAPED_TERRAIN_TILES_RANDOM_HINT, kfMapedSubMenuAction4);

  TilesPaletteMagicWater.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_MAGIC_WATER_HINT,  kfMapedSubMenuAction1);
  TilesPaletteEyedropper.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_EYEDROPPER_HINT,   kfMapedSubMenuAction2);
  TilesPaletteRotate.Hint     := GetHintWHotkey(TX_MAPED_TERRAIN_ROTATE_TILE,       kfMapedSubMenuAction3);
  TilesPaletteRandom.Hint     := GetHintWHotkey(TX_MAPED_TERRAIN_TILES_RANDOM_HINT, kfMapedSubMenuAction4);
end;


procedure TKMMapEdTerrainTiles.UpdateState;
begin
  TilesRefresh(nil);
end;


end.
