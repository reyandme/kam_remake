unit KM_GUIMapEdTerrainObjects;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  Classes, Math, SysUtils,
  KM_InterfaceDefaults,
  KM_Controls, KM_Defaults, KM_Pics, KM_GameCursor, KM_Points, KM_CommonTypes;

type
  TKMTerrainObjectAttribute = (toaBlockDiagonal, toaBlockAllExceptBuild, toaBlockBuild, toaChoppableTree);

  TKMTerrainObjectAttributeSet = set of TKMTerrainObjectAttribute;

  TKMMapEdTerrainObjects = class(TKMMapEdSubMenuPage)
  private
    fHideAllPages: TEvent;
    //Objects in MapElem are placed sparsely, so we need to compact them
    //to use in MapEd palette
    fLastObjectIndex: Integer;
    fCountCompact: Integer;
    fCompactToMapElem: array [Byte] of Byte; //Pointers to valid MapElem's
    fMapElemToCompact: array [Byte] of Byte; //Pointers of valid MapElem's back to map objects. (reverse lookup to one above) 256 is no object.

    fObjPaletteTableSize: TKMPoint;
    fObjPaletteAttr: array of TKMTerrainObjectAttributeSet;

    function GetObjPaletteTableHeight: Integer;
    function GetObjPaletteTableWidth: Integer;

    procedure UpdatePaletteButton(aBtnID: Integer);
    function UpdateObjAttributesAndDesc(aBtn: TKMButtonFlat; aObjID: Integer): TKMTerrainObjectAttributeSet;
    procedure CompactMapElements;
    procedure ObjectsUpdate(aObjIndex: Integer);
    procedure UpdateObjectsScrollPosToIndex(aObjIndex: Integer);
    procedure ObjectsChange(Sender: TObject);
    procedure ObjectsBrushChange(Sender: TObject);
    procedure ObjectsRefresh(Sender: TObject);

    procedure ObjectsPalette_Refresh(Sender: TObject);
    procedure ObjPalette_UpdateControlsPosition;
    procedure ObjectsPalette_OnShow(Sender: TObject; aVisible: Boolean);
    procedure ObjPalette_ClickShift(Sender: TObject; Shift: TShiftState);

    procedure ObjectsPaletteButton_Click(Sender: TObject);
    procedure ObjectsPaletteClose_Click(Sender: TObject);
  protected
    Panel_Objects: TKMScrollPanel;
      ObjectErase: TKMButtonFlat;
      ObjectBlock: TKMButtonFlat;
      ObjectsPalette_Button: TKMButtonFlat;
      ObjectsTable: array [0..8] of TKMButtonFlat;
      ObjectsScroll: TKMScrollBar;
    PopUp_ObjectsPalette: TKMPopUpMenu;
      Bevel_ObjectsPalette: TKMBevel;
      Image_ObjectsPalette: TKMImage;
      Label_ObjectsPalette: TKMLabel;
      Button_ClosePalette: TKMButton;
      Button_ObjPaletteErase: TKMButtonFlat;
      Button_ObjPaletteBlock: TKMButtonFlat;
      ObjectsPaletteTable: array of TKMButtonFlat;
      Image_ObjectAttributes: array[0..2] of array of TKMImage;

      //Objects brush
      BrushSize, ForestDensity, ForestAge: TKMTrackBar;
      ObjectTypeSet: array [0..9] of  TKMButtonFlat;
      BrushCircle, BrushSquare: TKMButtonFlat;
      CleanBrush: TKMButtonFlat;
      Label_ForestAge: TKMLabel;
      OverrideObjects: TKMCheckBox;

      Scroll_ObjectsPalette: TKMScrollBar;
  public
    constructor Create(aParent: TKMPanel; aHideAllPages: TEvent);

    procedure KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);
    procedure KeyUp(Key: Word; Shift: TShiftState; var aHandled: Boolean);
    procedure MouseWheel(Shift: TShiftState; WheelSteps: Integer; X,Y: Integer; var aHandled: Boolean);

    procedure Show;
    function Visible: Boolean; override;
    procedure Hide;
    procedure Resize;
    procedure Cancel_Clicked(var aHandled: Boolean);
    procedure UpdateState;
  end;


implementation
uses
  KM_Main, KM_Resource, KM_ResFonts, KM_ResMapElements, KM_ResTexts, KM_ResKeys, KM_Terrain,
  KM_HandsCollection, KM_RenderUI, KM_InterfaceGame, KM_Utils,
  KM_ResTypes, KM_TerrainTypes;

type
  TKMObjBrushForestAge = (faAll, faAllButStomps, faYoung, faMedium, faBig, faChop, faStomp);

const
  OBJECTS_PALETTE_MAX_COLS_CNT = 17;
  OBJ_CELL_W = 68;
  OBJ_CELL_H = 84;

  OBJ_CELL_PALETTE_W = 68;
  OBJ_CELL_PALETTE_H = 84;

  OBJ_NONE_TAG = -100;
  OBJ_BLOCK_TAG = -200;
  //Objects brush bins
  BTN_BRUSH_TYPE_S = 30;
  BTN_BRUSH_SIZE = 36;

  OBJECT_MAX_DENSITY = 30;


  FOREST_AGE_THUMB_TX: array[TKMObjBrushForestAge] of Integer = (TX_MAPED_OBJECTS_BRUSH_TREES_AGE_ALL,
                                                                 TX_MAPED_OBJECTS_BRUSH_TREES_AGE_ALL_BUT_STOMP,
                                                                 TX_MAPED_OBJECTS_BRUSH_TREES_AGE_YOUNG,
                                                                 TX_MAPED_OBJECTS_BRUSH_TREES_AGE_MEDIUM,
                                                                 TX_MAPED_OBJECTS_BRUSH_TREES_AGE_BIG,
                                                                 TX_MAPED_OBJECTS_BRUSH_TREES_AGE_RDY_2CHOP,
                                                                 TX_MAPED_OBJECTS_BRUSH_TREES_AGE_STOMP);

  FOREST_AGE_HINT_TX: array[TKMObjBrushForestAge] of Integer = (TX_MAPED_OBJECTS_BRUSH_TREES_AGE_ALL_HINT,
                                                                TX_MAPED_OBJECTS_BRUSH_TREES_AGE_ALL_BUT_STOMP_HINT,
                                                                TX_MAPED_OBJECTS_BRUSH_TREES_AGE_YOUNG_HINT,
                                                                TX_MAPED_OBJECTS_BRUSH_TREES_AGE_MEDIUM_HINT,
                                                                TX_MAPED_OBJECTS_BRUSH_TREES_AGE_BIG_HINT,
                                                                TX_MAPED_OBJECTS_BRUSH_TREES_AGE_RDY_2CHOP_HINT,
                                                                TX_MAPED_OBJECTS_BRUSH_TREES_AGE_STOMP_HINT);


{ TKMMapEdTerrainObjects }
constructor TKMMapEdTerrainObjects.Create(aParent: TKMPanel; aHideAllPages: TEvent);

  function GetForestAgeThumbWidth(aFont: TKMFont): Integer;
  var
    BFA: TKMObjBrushForestAge;
  begin
    Result := 0;
    for BFA := Low(FOREST_AGE_THUMB_TX) to High(FOREST_AGE_THUMB_TX) do
      Result := Max(Result, gRes.Fonts[aFont].GetTextSize(gResTexts[FOREST_AGE_THUMB_TX[BFA]]).X);

    Inc(Result, TKMTrackBar.THUMB_WIDTH_ADD);
  end;

var
  top: Integer;

  function NextTop(aInc: Integer): Integer;
  begin
    Result := top;
    top := top + aInc;
  end;

var
  I, J: Integer;
//  TOA: TKMTerrainObjectAttribute;
  //For brushes
  rxIndex, K: Integer;
  objectsHint: String;

begin
  inherited Create;

  fHideAllPages := aHideAllPages;
  fLastObjectIndex := -1;

  CompactMapElements;

  Panel_Objects := TKMScrollPanel.Create(aParent, 0, 28, aParent.Width, aParent.Height - 28, [saVertical], bsMenu, ssCommon);
  Panel_Objects.Padding.SetBottom(10);
  Panel_Objects.ScrollV_PadTop := 10;
  Panel_Objects.ScrollV_PadBottom := 10;
  Panel_Objects.AnchorsStretch;

  with TKMLabel.Create(Panel_Objects, 0, TERRAIN_PAGE_TITLE_Y, Panel_Objects.Width, 0, gResTexts[TX_MAPED_OBJECTS], fntOutline, taCenter) do
    Anchors := [anLeft, anTop, anRight];

  ObjectsScroll := TKMScrollBar.Create(Panel_Objects, 9, 295, Panel_Objects.Width - 9, 20, saHorizontal, bsGame);
  ObjectsScroll.Anchors := [anLeft, anTop, anRight];
  ObjectsScroll.MinValue := 0;
  ObjectsScroll.MaxValue := (fCountCompact - 1) div 3 - 2;
  ObjectsScroll.Position := 0;
  ObjectsScroll.OnChange := ObjectsRefresh;
  for I := 0 to 2 do
    for J := 0 to 2 do
    begin
      ObjectsTable[I*3+J] := TKMButtonFlat.Create(Panel_Objects, 9 + I*(OBJ_CELL_W + 1), 40 + J*(OBJ_CELL_H + 1),
                                                  OBJ_CELL_W, OBJ_CELL_H, 1, rxTrees); //RXid=1  // 1 2
      ObjectsTable[I*3+J].CapOffsetY := 15;
      ObjectsTable[I*3+J].Tag := I*3+J; //Store ID
      ObjectsTable[I*3+J].OnClick := ObjectsChange;
      ObjectsTable[I*3+J].OnMouseWheel := ObjectsScroll.MouseWheel;
    end;
  ObjectErase := TKMButtonFlat.Create(Panel_Objects, 9, 4, 32, 32, 340);
  ObjectErase.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_OBJECTS_REMOVE, kfMapedSubMenuAction1);
  ObjectErase.Tag := OBJ_NONE_TAG; //no object
  ObjectErase.OnClick := ObjectsChange;

  ObjectBlock := TKMButtonFlat.Create(Panel_Objects, Panel_Objects.Width - 32, 4, 32, 32, 254,rxTrees);
  ObjectBlock.Anchors := [anTop, anRight];
  ObjectBlock.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_OBJECTS_BLOCK, kfMapedSubMenuAction2);
  ObjectBlock.Tag := OBJ_BLOCK_TAG; //block object
  ObjectBlock.OnClick := ObjectsChange;

  ObjectsPalette_Button := TKMButtonFlat.Create(Panel_Objects, 9, 320, Panel_Objects.Width - 9, 21, 0);
  ObjectsPalette_Button.Anchors := [anLeft, anTop, anRight];
  ObjectsPalette_Button.Caption := gResTexts[TX_MAPED_TERRAIN_OBJECTS_PALETTE];
  ObjectsPalette_Button.CapOffsetY := -11;
  ObjectsPalette_Button.Hint := GetHintWHotKey(TX_MAPED_TERRAIN_OBJECTS_PALETTE, kfMapedObjPalette);
  ObjectsPalette_Button.OnClick := ObjectsPaletteButton_Click;

  PopUp_ObjectsPalette := TKMPopUpMenu.Create(aParent.MasterParent, aParent.MasterParent.Width - 50);
  PopUp_ObjectsPalette.Height := aParent.MasterParent.Height - 50;
  PopUp_ObjectsPalette.OnChangeVisibility := ObjectsPalette_OnShow;
  // Keep the pop-up centered
  PopUp_ObjectsPalette.AnchorsCenter;
  PopUp_ObjectsPalette.Left := 25;
  PopUp_ObjectsPalette.Top := 25;

    Bevel_ObjectsPalette := TKMBevel.Create(PopUp_ObjectsPalette, -2000,  -2000, 5000, 5000);
    Bevel_ObjectsPalette.BackAlpha := 0.7;
    Bevel_ObjectsPalette.EdgeAlpha := 0.9;
    Bevel_ObjectsPalette.OnClickShift := ObjPalette_ClickShift;

    Image_ObjectsPalette := TKMImage.Create(PopUp_ObjectsPalette, 0, 0, PopUp_ObjectsPalette.Width, PopUp_ObjectsPalette.Height, 18, rxGuiMain);
    Image_ObjectsPalette.ImageStretch;
    Image_ObjectsPalette.OnClickShift := ObjPalette_ClickShift;

    Scroll_ObjectsPalette := TKMScrollBar.Create(PopUp_ObjectsPalette, PopUp_ObjectsPalette.Width - 20, 25, 20, PopUp_ObjectsPalette.Height - 75, saVertical, bsGame);
    Scroll_ObjectsPalette.MinValue := 0;
    Scroll_ObjectsPalette.Position := 0;
    Scroll_ObjectsPalette.OnChange := ObjectsPalette_Refresh;

    // Add event handlers after Scroll is created
    Image_ObjectsPalette.OnMouseWheel := Scroll_ObjectsPalette.MouseWheel;
    Bevel_ObjectsPalette.OnMouseWheel := Scroll_ObjectsPalette.MouseWheel;

    SetLength(ObjectsPaletteTable, fCountCompact);
    for I := 0 to fCountCompact - 1 do
    begin
      ObjectsPaletteTable[I] := TKMButtonFlat.Create(PopUp_ObjectsPalette, 0, 0, OBJ_CELL_PALETTE_W, OBJ_CELL_PALETTE_H, 1, rxTrees); // Left and Top will update later
      ObjectsPaletteTable[I].Tag := I; //Store ID
      ObjectsPaletteTable[I].CapOffsetY := 15;
//      ObjectsPaletteTable[I].TexOffsetY := 0;
      ObjectsPaletteTable[I].Enable;
      ObjectsPaletteTable[I].Hide;
      ObjectsPaletteTable[I].OnMouseWheel := Scroll_ObjectsPalette.MouseWheel;
      ObjectsPaletteTable[I].OnClickShift := ObjPalette_ClickShift;

    end;

    SetLength(fObjPaletteAttr, fCountCompact);
    for J := Low(Image_ObjectAttributes) to High(Image_ObjectAttributes) do
    begin
      SetLength(Image_ObjectAttributes[J], fCountCompact);
      for I := 0 to fCountCompact - 1 do
      begin
        Image_ObjectAttributes[J, I] := TKMImage.Create(PopUp_ObjectsPalette, 0, 0, 0, 0, 0);
        Image_ObjectAttributes[J, I].Hide;
        Image_ObjectAttributes[J, I].Hitable := False;
      end;
    end;

    Label_ObjectsPalette := TKMLabel.Create(PopUp_ObjectsPalette, PopUp_ObjectsPalette.Center.X, 0, gResTexts[TX_MAPED_TERRAIN_OBJECTS_PALETTE], fntOutline, taCenter);

    Button_ObjPaletteErase := TKMButtonFlat.Create(PopUp_ObjectsPalette, 0, 0, OBJ_CELL_W, 32, 340);
    Button_ObjPaletteErase.Hint := gResTexts[TX_MAPED_TERRAIN_OBJECTS_REMOVE];
    Button_ObjPaletteErase.Tag := OBJ_NONE_TAG; //no object
    Button_ObjPaletteErase.OnClickShift := ObjPalette_ClickShift;

    Button_ObjPaletteBlock := TKMButtonFlat.Create(PopUp_ObjectsPalette, 0, 0, OBJ_CELL_W, 32, 254, rxTrees);
    Button_ObjPaletteBlock.Hint := gResTexts[TX_MAPED_TERRAIN_OBJECTS_BLOCK];
    Button_ObjPaletteBlock.Tag := OBJ_BLOCK_TAG; //block object
    Button_ObjPaletteBlock.OnClickShift := ObjPalette_ClickShift;

    Button_ClosePalette  := TKMButton.Create(PopUp_ObjectsPalette, PopUp_ObjectsPalette.Center.X - 100, PopUp_ObjectsPalette.Bottom - 50,
                                             200, 30, gResTexts[TX_MAPED_TERRAIN_CLOSE_PALETTE], bsGame);
    Button_ClosePalette.Anchors := [anLeft,anBottom];
    Button_ClosePalette.OnClick := ObjectsPaletteClose_Click;

    ObjPalette_UpdateControlsPosition;


  // Objects brushes
  top := 355;

  with TKMLabel.Create(Panel_Objects, 9, NextTop(25), Panel_Objects.Width, 0, gResTexts[TX_MAPED_OBJECTS_BRUSH], fntOutline, taCenter) do
    Anchors := [anLeft, anTop, anRight];

  BrushSize := TKMTrackBar.Create(Panel_Objects, 9, top + 3, (Panel_Objects.Width - (BTN_BRUSH_TYPE_S * 2) - 18) - 18, 4, MAPED_BRUSH_MAX_SIZE);
  BrushSize.Anchors := [anLeft, anTop, anRight];
  BrushSize.Position := 1;
  BrushSize.OnChange := ObjectsBrushChange;
  BrushSize.Hint := GetHintWHotKey(TX_MAPED_TERRAIN_HEIGHTS_SIZE_HINT, gResTexts[TX_KEY_CTRL_MOUSEWHEEL]);

  BrushCircle := TKMButtonFlat.Create(Panel_Objects, Panel_Objects.Width - (BTN_BRUSH_TYPE_S * 2) - 18, top, BTN_BRUSH_TYPE_S, BTN_BRUSH_TYPE_S, 592);
  BrushCircle.Anchors := [anTop, anRight];
  BrushCircle.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_HEIGHTS_CIRCLE, kfMapedSubMenuAction3);
  BrushCircle.OnClick := ObjectsBrushChange;
  BrushCircle.TexOffsetX := 1;
  BrushCircle.TexOffsetY := 1;
  BrushCircle.Down := True;

  BrushSquare := TKMButtonFlat.Create(Panel_Objects, Panel_Objects.Width - BTN_BRUSH_TYPE_S - 9, top, BTN_BRUSH_TYPE_S, BTN_BRUSH_TYPE_S, 593);
  BrushSquare.Anchors := [anTop, anRight];
  BrushSquare.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_HEIGHTS_SQUARE, kfMapedSubMenuAction4);
  BrushSquare.OnClick := ObjectsBrushChange;
  BrushSquare.TexOffsetX := 1;
  BrushSquare.TexOffsetY := 1;

  NextTop(35);

  CleanBrush := TKMButtonFlat.Create(Panel_Objects, 9, NextTop(45), 34, 34, 673, rxGui);
  CleanBrush.Anchors := [anTop];
  CleanBrush.Hint := GetHintWHotkey(TX_MAPED_OBJECTS_BRUSH_CLEAN, kfMapedSubMenuAction5);
  CleanBrush.OnClick := ObjectsBrushChange;

  OverrideObjects := TKMCheckBox.Create(Panel_Objects, 9, NextTop(40), Panel_Objects.Width - 9, 40, gResTexts[TX_MAPED_OBJECTS_BRUSH_OVERRIDE_OBJECTS], fntMetal);
  OverrideObjects.OnClick := ObjectsBrushChange;
  OverrideObjects.Hint := gResTexts[TX_MAPED_OBJECTS_BRUSH_OVERRIDE_OBJECTS_HINT];


  rxIndex := 226;

  for I := 0 to 9 do
  begin
    case I of
       0: begin rxIndex := 226; objectsHint := GetHintWHotkey(TX_MAPED_OBJECTS_BRUSH_TREES, kfMapedSubMenuAction6); end;
       1: begin rxIndex := 34;  objectsHint := GetHintWHotkey(TX_MAPED_OBJECTS_BRUSH_ALL,   kfMapedSubMenuAction7); end;
       2: begin rxIndex := 14;  objectsHint := gResTexts[TX_MAPED_OBJECTS_BRUSH_FLOWERS];   end;
       3: begin rxIndex := 4;   objectsHint := gResTexts[TX_MAPED_OBJECTS_BRUSH_MUSHROOMS]; end;
       4: begin rxIndex := 26;  objectsHint := gResTexts[TX_MAPED_OBJECTS_BRUSH_TRUNKS];    end;

       5: begin rxIndex := 39;  objectsHint := gResTexts[TX_MAPED_OBJECTS_BRUSH_DEAD];      end;
       6: begin rxIndex := 21;  objectsHint := gResTexts[TX_MAPED_OBJECTS_BRUSH_STONES];    end;
       7: begin rxIndex := 143; objectsHint := gResTexts[TX_MAPED_OBJECTS_BRUSH_BUSH];      end;
       8: begin rxIndex := 173; objectsHint := gResTexts[TX_MAPED_OBJECTS_BRUSH_CACTUS];    end;
       9: begin rxIndex := 245; objectsHint := gResTexts[TX_MAPED_OBJECTS_BRUSH_RUINS];     end;
    end;

    J := I mod 5;
    K := I div 5;

    ObjectTypeSet[I] := TKMButtonFlat.Create(Panel_Objects, 9+BTN_BRUSH_SIZE*J, top + BTN_BRUSH_SIZE*K, 34, 34, rxIndex, rxTrees);

    ObjectTypeSet[I].OnClick := ObjectsBrushChange;
    ObjectTypeSet[I].Hint := objectsHint;
  end;

  NextTop(80);

  ForestDensity   := TKMTrackBar.Create(Panel_Objects, 9, NextTop(50), (Panel_Objects.Width) - 18, 1, OBJECT_MAX_DENSITY);
  ForestDensity.Anchors := [anLeft, anTop, anRight];
  ForestDensity.Caption := gResTexts[TX_MAPED_OBJECTS_BRUSH_DENSITY];
  ForestDensity.Position := 10;
  ForestDensity.OnChange := ObjectsBrushChange;
  ForestDensity.Hint := GetHintWHotKey(TX_MAPED_OBJECTS_BRUSH_DENSITY_HINT, gResTexts[TX_KEY_ALT_MOUSEWHEEL]);

  ForestAge := TKMTrackBar.Create(Panel_Objects, 9, NextTop(50), (Panel_Objects.Width) - 18,
                                  Ord(Low(TKMObjBrushForestAge)), Ord(High(TKMObjBrushForestAge)));
  ForestAge.Anchors := [anLeft, anTop, anRight];
  ForestAge.Caption := gResTexts[TX_MAPED_OBJECTS_BRUSH_AGE];
  ForestAge.Position := Ord(faAll); // All ages by default
  ForestAge.OnChange := ObjectsBrushChange;
  ForestAge.ThumbText := gResTexts[TX_MAPED_OBJECTS_BRUSH_TREES_AGE_ALL];
  ForestAge.Hint := GetHintWHotKey(TX_MAPED_OBJECTS_BRUSH_TREES_AGE_ALL_HINT, gResTexts[TX_KEY_SHIFT_MOUSEWHEEL]);

  ForestAge.FixedThumbWidth := True;
  ForestAge.ThumbWidth := GetForestAgeThumbWidth(ForestAge.Font);
//  ForestAge.AutoThumbWidth := True; // Auto calc thumb width

  Label_ForestAge := TKMLabel.Create(Panel_Objects, 9, NextTop(20) - 8, Panel_Objects.Width - 18, 20,
                                     gResTexts[TX_MAPED_OBJECTS_BRUSH_TREES_AGE_ALL_HINT], fntGrey, taRight);
  Label_ForestAge.Anchors := [anLeft, anTop, anRight];

  gGameCursor.MapEdObjectsType[0] := True;
  gGameCursor.MapEdObjectsType[1] := True;

  gGameCursor.MapEdForestAge := 1;
  gGameCursor.MapEdCleanBrush := False;

  // hotkeys for object functions
  fSubMenuActionsEvents[0] := ObjectsChange;
  fSubMenuActionsEvents[1] := ObjectsChange;
  fSubMenuActionsEvents[2] := ObjectsBrushChange;
  fSubMenuActionsEvents[3] := ObjectsBrushChange;
  fSubMenuActionsEvents[4] := ObjectsBrushChange;
  fSubMenuActionsEvents[5] := ObjectsBrushChange;
  fSubMenuActionsEvents[6] := ObjectsBrushChange;

  fSubMenuActionsCtrls[0,0] := ObjectErase;
  fSubMenuActionsCtrls[1,0] := ObjectBlock;
  fSubMenuActionsCtrls[2,0] := BrushCircle;
  fSubMenuActionsCtrls[3,0] := BrushSquare;
  fSubMenuActionsCtrls[4,0] := CleanBrush;
  fSubMenuActionsCtrls[5,0] := ObjectTypeSet[0];
  fSubMenuActionsCtrls[6,0] := ObjectTypeSet[1];
end;


procedure TKMMapEdTerrainObjects.ObjectsPalette_OnShow(Sender: TObject; aVisible: Boolean);
begin
  if aVisible then
    ObjPalette_UpdateControlsPosition;
end;


function TKMMapEdTerrainObjects.GetObjPaletteTableHeight: Integer;
begin
  Result := (OBJ_CELL_PALETTE_H + 1)*Min(fObjPaletteTableSize.Y, ((fCountCompact - 1) div fObjPaletteTableSize.X) + 1);
end;


function TKMMapEdTerrainObjects.GetObjPaletteTableWidth: Integer;
begin
  Result := (OBJ_CELL_PALETTE_W + 1)*fObjPaletteTableSize.X;
end;


procedure TKMMapEdTerrainObjects.UpdatePaletteButton(aBtnID: Integer);
const
  ATTR_IMG_SIZE = 25;
  IMG_ATTR_TEXID: array[TKMTerrainObjectAttribute] of Integer = (677, 340, 40, 371 {395});
  IMG_ATTR_W: array[TKMTerrainObjectAttribute] of Integer = (14, 19, 23, 18);
  IMG_ATTR_H: array[TKMTerrainObjectAttribute] of Integer = (14, 19, 22, 14);
var
  I, index: Integer;
  TOA: TKMTerrainObjectAttribute;
  attributes: TKMTerrainObjectAttributeSet;
begin
  attributes := UpdateObjAttributesAndDesc(ObjectsPaletteTable[aBtnID], fCompactToMapElem[aBtnID]);
  index := 0;
//  for TOA := Low(TKMTerrainObjectAttribute) to High(TKMTerrainObjectAttribute) do
  for TOA := toaChoppableTree to toaChoppableTree do
  begin
    if TOA in attributes then
    begin
      Image_ObjectAttributes[index, aBtnID].Visible := True;
      Image_ObjectAttributes[index, aBtnID].Left := ObjectsPaletteTable[aBtnID].Left + 2 + ATTR_IMG_SIZE*index;
      Image_ObjectAttributes[index, aBtnID].Top := ObjectsPaletteTable[aBtnID].Bottom - IMG_ATTR_H[TOA] - 10;
      Image_ObjectAttributes[index, aBtnID].Width := IMG_ATTR_W[TOA];
      Image_ObjectAttributes[index, aBtnID].Height := IMG_ATTR_H[TOA];
      Image_ObjectAttributes[index, aBtnID].TexID := IMG_ATTR_TEXID[TOA];
      Inc(index);
    end;
  end;
  for I := index to High(Image_ObjectAttributes) do
    Image_ObjectAttributes[I, aBtnID].Hide;
end;


function TKMMapEdTerrainObjects.UpdateObjAttributesAndDesc(aBtn: TKMButtonFlat; aObjID: Integer): TKMTerrainObjectAttributeSet;
begin
  Result := [];

  aBtn.CapColor := icWhite;
  aBtn.Hint := aBtn.Caption;

  if ObjectIsChoppableTree(aObjID, [caAge1, caAge2, caAge3, caAgeFull]) then
  begin
    Include(Result, toaChoppableTree);
    aBtn.CapColor := icRoyalYellow;
    aBtn.Hint := aBtn.Hint + ' / ' + gResTexts[TX_MAPED_OBJ_CHOPPABLE_HINT];
  end;

  if gMapElements[aObjID].DiagonalBlocked then
  begin
    Include(Result, toaBlockDiagonal);
    aBtn.Hint := aBtn.Hint + ' / ' + gResTexts[TX_MAPED_OBJ_BLOCK_WALK_DIAG_HINT];
    aBtn.CapColor := icLightRed;
  end;

//This section is not needed, since every AllBlocked object is also blocks building
//  if gMapElements[aObjID].AllBlocked then
//  begin
//    Include(Result, toaBlockAllExceptBuild);
//    HintStr := ' / ' + gResTexts[TX_MAPED_OBJ_BLOCK_ALL_HINT];
//    aBtn.CapColor := icOrange;
//  end;

  if not gMapElements[aObjID].CanBeRemoved then
  begin
    Include(Result, toaBlockBuild);
    if gMapElements[aObjID].AllBlocked then
    begin
      Include(Result, toaBlockAllExceptBuild);
      aBtn.Hint := aBtn.Hint + ' / ' + gResTexts[TX_MAPED_OBJ_BLOCK_WALK_BUILD_HINT];
      aBtn.CapColor := icRed;
    end
    else
    begin
      aBtn.Hint := aBtn.Hint + ' / ' + gResTexts[TX_MAPED_OBJ_BLOCK_BUILD_HINT];
      if toaBlockDiagonal in Result then
        aBtn.CapColor := icOrange
      else
        aBtn.CapColor := icRoyalYellow;
    end;
  end;
end;


procedure TKMMapEdTerrainObjects.ObjectsPalette_Refresh(Sender: TObject);
var
  I, J, K, LeftAdj, TopAdj: Integer;
begin
  LeftAdj := (PopUp_ObjectsPalette.Width - fObjPaletteTableSize.X*(OBJ_CELL_W + 1) - 25*Byte(Scroll_ObjectsPalette.Visible)) div 2;
  TopAdj := Image_ObjectsPalette.Top + 60;

  K := 0;

  Button_ObjPaletteErase.Left := LeftAdj;
  Button_ObjPaletteBlock.Left := LeftAdj + OBJ_CELL_W + 1;

  for I := 0 to fObjPaletteTableSize.Y - 1 do
    for J := 0 to fObjPaletteTableSize.X - 1 do
    begin
      K := (I + Scroll_ObjectsPalette.Position)*fObjPaletteTableSize.X + J;
      if K < fCountCompact then
      begin
        ObjectsPaletteTable[K].Left := J*(OBJ_CELL_PALETTE_W + 1) + LeftAdj;
        ObjectsPaletteTable[K].Top := 25 + I*(OBJ_CELL_PALETTE_H + 1)  + TopAdj;
        ObjectsPaletteTable[K].TexID := gMapElements[fCompactToMapElem[K]].Anim.Step[1] + 1;
        ObjectsPaletteTable[K].Caption := IntToStr(fCompactToMapElem[K]);

        UpdatePaletteButton(K);

        ObjectsPaletteTable[K].Visible := True;
      end;
    end;

  // Make invisible all palette buttons at the end of the list, after shown buttons 'page'
  for I := K + 1 to fCountCompact - 1 do
  begin
    ObjectsPaletteTable[I].Visible := False;
    for J := Low(Image_ObjectAttributes) to High(Image_ObjectAttributes) do
      Image_ObjectAttributes[J, I].Hide;
  end;

  // Make invisible all palette buttons at the start of the list, before shown buttons 'page'
  for I := 0 to Scroll_ObjectsPalette.Position - 1 do
    for J := 0 to fObjPaletteTableSize.X - 1 do
    begin
      K := I*fObjPaletteTableSize.X + J;
      if K < fCountCompact then
        ObjectsPaletteTable[K].Visible := False;
    end;

  // Update palette buttons Down state
  for I := 0 to fCountCompact - 1 do
    ObjectsPaletteTable[I].Down := (gGameCursor.Mode = cmObjects)
                                and (gGameCursor.Tag1 <> OBJ_NONE)
                                and (gGameCursor.Tag1 <> OBJ_BLOCK)
                                and (ObjectsPaletteTable[I].Tag = fMapElemToCompact[gGameCursor.Tag1]);
end;


procedure TKMMapEdTerrainObjects.ObjPalette_UpdateControlsPosition;
var
  RowsCnt, ColsCnt: Integer;
begin
  PopUp_ObjectsPalette.Top := 25;
  PopUp_ObjectsPalette.Left := 25;
  PopUp_ObjectsPalette.Width := PopUp_ObjectsPalette.MasterParent.Width - 50;
  PopUp_ObjectsPalette.Height := PopUp_ObjectsPalette.MasterParent.Height - 50;

  RowsCnt := Max(1, (PopUp_ObjectsPalette.Height - 80) div (OBJ_CELL_PALETTE_H + 1));
  //Calc cols count without Scroll first
  ColsCnt := EnsureRange(PopUp_ObjectsPalette.Width div (OBJ_CELL_PALETTE_W + 1), 1, OBJECTS_PALETTE_MAX_COLS_CNT);
  Scroll_ObjectsPalette.Visible := RowsCnt*ColsCnt < fCountCompact;
  //Recalc ColsCount considering possible scroll width
  ColsCnt := EnsureRange((PopUp_ObjectsPalette.Width - 25*Byte(Scroll_ObjectsPalette.Visible)) div (OBJ_CELL_W + 1), 1, OBJECTS_PALETTE_MAX_COLS_CNT);

  fObjPaletteTableSize := KMPoint(ColsCnt, RowsCnt);

  Image_ObjectsPalette.Width := GetObjPaletteTableWidth + 150;
  Image_ObjectsPalette.Height := GetObjPaletteTableHeight + 220;
  Image_ObjectsPalette.Left := (PopUp_ObjectsPalette.Width - Image_ObjectsPalette.Width) div 2;
  Image_ObjectsPalette.Top := ((PopUp_ObjectsPalette.Height - Image_ObjectsPalette.Height) div 2) - 25;

  Label_ObjectsPalette.Left := PopUp_ObjectsPalette.Center.X - 30;
  Label_ObjectsPalette.Top := Image_ObjectsPalette.Top + 60;

  Button_ClosePalette.Left := PopUp_ObjectsPalette.Center.X - 125;
  Button_ClosePalette.Top := Image_ObjectsPalette.Bottom - 110;

  Button_ObjPaletteErase.Top := Image_ObjectsPalette.Bottom - 110;
  Button_ObjPaletteBlock.Top := Image_ObjectsPalette.Bottom - 110;

  Scroll_ObjectsPalette.Left := Image_ObjectsPalette.Right - 50;
  Scroll_ObjectsPalette.Top := Image_ObjectsPalette.Top + 80;
  Scroll_ObjectsPalette.Height := Image_ObjectsPalette.Height - 150;

  Scroll_ObjectsPalette.MaxValue := ((fCountCompact - 1) div ColsCnt) + 1 - RowsCnt;

  ObjectsPalette_Refresh(nil);
end;


//Map sparse objects into a tight lookup array
procedure TKMMapEdTerrainObjects.CompactMapElements;
var
  I: Integer;
begin
  fCountCompact := 0;
  for I := 0 to gRes.MapElements.Count - 1 do
    if (I <> OBJ_BLOCK_TAG) and (gMapElements[I].Anim.Count > 0) and (gMapElements[I].Anim.Step[1] > 0)
      and (gMapElements[I].Stump = -1) then //Hide falling trees and invisible wall (61)
    begin
      fCompactToMapElem[fCountCompact] := I; //pointer
      fMapElemToCompact[I] := fCountCompact; //Reverse lookup
      Inc(fCountCompact);
    end;
end;


//aObjIndex - Object index which should be visible after update
procedure TKMMapEdTerrainObjects.UpdateObjectsScrollPosToIndex(aObjIndex: Integer);
begin
  // Update Scroll position for objects panel in the menu
  if (aObjIndex >= 0) and not InRange(aObjIndex, ObjectsScroll.Position * 3, ObjectsScroll.Position * 3 + 8) then
    ObjectsScroll.Position := (aObjIndex div 3) - 1; // set scroll so object is in the mid of table
end;


procedure TKMMapEdTerrainObjects.ObjPalette_ClickShift(Sender: TObject; Shift: TShiftState);
var
  ObjIndex: Integer;
begin
  if ssRight in Shift then
    PopUp_ObjectsPalette.Hide
  else if (ssLeft in Shift) and (Sender is TKMButtonFlat) then
  begin
    PopUp_ObjectsPalette.Hide;
    ObjIndex := TKMButtonFlat(Sender).Tag;
    ObjectsUpdate(ObjIndex);

    if (Sender <> Button_ObjPaletteErase)
      and (Sender <> Button_ObjPaletteBlock) then
      UpdateObjectsScrollPosToIndex(ObjIndex);
  end;
end;


procedure TKMMapEdTerrainObjects.ObjectsBrushChange(Sender: TObject);
var
  I, treeAgeHintTX: Integer;
begin
  gGameCursor.Mode := cmObjectsBrush;

  ForestAge.ThumbText := gResTexts[FOREST_AGE_THUMB_TX[TKMObjBrushForestAge(ForestAge.Position)]];
  treeAgeHintTX := FOREST_AGE_HINT_TX[TKMObjBrushForestAge(ForestAge.Position)];

  Label_ForestAge.Caption := gResTexts[treeAgeHintTX];

  ForestAge.Hint := GetHintWHotKey(treeAgeHintTX, gResTexts[TX_KEY_SHIFT_MOUSEWHEEL]);

  for I := 0 to 9 do
    if Sender = ObjectTypeSet[I] then
      gGameCursor.MapEdObjectsType[I] := not gGameCursor.MapEdObjectsType[I];

  if Sender = CleanBrush then
  begin
    if CleanBrush.Down = False then
    begin
      gGameCursor.MapEdCleanBrush := True;
      CleanBrush.Down := True;
    end
    else
    begin
      gGameCursor.MapEdCleanBrush := False;
      CleanBrush.Down := False;
    end;
  end;
  if Sender = BrushCircle then
  begin
    gGameCursor.MapEdShape := hsCircle;
    BrushCircle.Down := True;
    BrushSquare.Down := False;
  end
  else
  if Sender = BrushSquare then
  begin
    gGameCursor.MapEdShape := hsSquare;
  end;
  if gGameCursor.MapEdShape = hsSquare then
  begin
    BrushCircle.Down := False;
    BrushSquare.Down := True;
  end;

  gGameCursor.MapEdOverrideObjects := OverrideObjects.Checked;
  gGameCursor.MapEdSize := BrushSize.Position;
  gGameCursor.MapEdForestAge := ForestAge.Position;
  gGameCursor.MapEdObjectsDensity := ForestDensity.Position;
end;


procedure TKMMapEdTerrainObjects.ObjectsChange(Sender: TObject);
var
  objIndex: Integer;
begin
  case TKMButtonFlat(Sender).Tag of
    OBJ_BLOCK_TAG,
    OBJ_NONE_TAG:  objIndex := TKMButtonFlat(Sender).Tag; // Block or Erase
    else           objIndex := ObjectsScroll.Position * 3 + TKMButtonFlat(Sender).Tag; //0..n-1
  end;

  ObjectsUpdate(objIndex);

  // Update Objects Palette scroll position
  if (objIndex <> OBJ_BLOCK_TAG) and (objIndex <> OBJ_NONE_TAG)
    and not InRange(objIndex,
                    Scroll_ObjectsPalette.Position*fObjPaletteTableSize.X,
                    Scroll_ObjectsPalette.Position*fObjPaletteTableSize.X + fObjPaletteTableSize.X*fObjPaletteTableSize.Y - 1) then
    Scroll_ObjectsPalette.Position := ((objIndex - 1) div fObjPaletteTableSize.X);
end;


procedure TKMMapEdTerrainObjects.ObjectsUpdate(aObjIndex: Integer);
begin
  //Skip indexes out of range
  if not InRange(aObjIndex, 0, fCountCompact - 1)
    and (aObjIndex <> OBJ_BLOCK_TAG)
    and (aObjIndex <> OBJ_NONE_TAG) then
    Exit;

  gGameCursor.Mode := cmObjects;
  case aObjIndex of
    OBJ_BLOCK_TAG:  gGameCursor.Tag1 := OBJ_BLOCK; //Block
    OBJ_NONE_TAG:   gGameCursor.Tag1 := OBJ_NONE; //Erase
    else gGameCursor.Tag1 := fCompactToMapElem[aObjIndex];
  end;

  //Remember last selected object
  fLastObjectIndex := aObjIndex;

  ObjectsRefresh(nil);
end;


procedure TKMMapEdTerrainObjects.ObjectsPaletteButton_Click(Sender: TObject);
begin
  PopUp_ObjectsPalette.Show;
end;


procedure TKMMapEdTerrainObjects.ObjectsPaletteClose_Click(Sender: TObject);
begin
  PopUp_ObjectsPalette.Hide;
end;


procedure TKMMapEdTerrainObjects.ObjectsRefresh(Sender: TObject);
var
  I: Integer;
  ObjIndex: Integer;
begin
  for I := 0 to 8 do
  begin
    ObjIndex := ObjectsScroll.Position * 3 + I;
    if ObjIndex < fCountCompact then
    begin
      ObjectsTable[I].TexID := gMapElements[fCompactToMapElem[ObjIndex]].Anim.Step[1] + 1;
      ObjectsTable[I].Caption := IntToStr(fCompactToMapElem[ObjIndex]);

      UpdateObjAttributesAndDesc(ObjectsTable[I], fCompactToMapElem[ObjIndex]);

      ObjectsTable[I].Enable;
    end
    else
    begin
      ObjectsTable[I].TexID := 0;
      ObjectsTable[I].Caption := '';
      ObjectsTable[I].Disable;
    end;
    //Mark the selected one using reverse lookup
    ObjectsTable[I].Down := (gGameCursor.Mode = cmObjects)
                             and (gGameCursor.Tag1 <> OBJ_NONE)
                             and (gGameCursor.Tag1 <> OBJ_BLOCK)
                             and (ObjIndex = fMapElemToCompact[gGameCursor.Tag1]);
  end;

  for I := 0 to 9 do
    ObjectTypeSet[I].Down := gGameCursor.MapEdObjectsType[I];

  ObjectErase.Down := (gGameCursor.Mode = cmObjects) and (gGameCursor.Tag1 = OBJ_NONE);  //or delete button
  ObjectBlock.Down := (gGameCursor.Mode = cmObjects) and (gGameCursor.Tag1 = OBJ_BLOCK); //or block button
end;


procedure TKMMapEdTerrainObjects.Show;
begin
  gMain.FormMain.SuppressAltForMenu := True;
  
  case fLastObjectIndex of
    -1:   ; // Do not update Objects if no last object was selected
    OBJ_BLOCK_TAG: ObjectsChange(ObjectBlock);
    OBJ_NONE_TAG:  ObjectsChange(ObjectErase);
    else  begin
            UpdateObjectsScrollPosToIndex(fLastObjectIndex);
            ObjectsChange(ObjectsTable[fLastObjectIndex - ObjectsScroll.Position*3]);
          end;
  end;
  Panel_Objects.Show;
end;


function TKMMapEdTerrainObjects.Visible: Boolean;
begin
  Result := Panel_Objects.Visible;
end;


procedure TKMMapEdTerrainObjects.Hide;
begin
  Panel_Objects.Hide;
  PopUp_ObjectsPalette.Hide;
  gMain.FormMain.SuppressAltForMenu := False;
end;


procedure TKMMapEdTerrainObjects.MouseWheel(Shift: TShiftState; WheelSteps, X, Y: Integer; var aHandled: Boolean);
begin
  // Do not use ssCtrl in Shift here, as it can sometimes be wrong values inside Shift (ssShift instead of ssCtrl)
  if aHandled or not Visible then
    Exit;

  if GetKeyState(VK_CONTROL) < 0 then
  begin
    BrushSize.Position := Max(0, BrushSize.Position - WheelSteps); //can't set negative number
    aHandled := True;
  end;

  if GetKeyState(VK_MENU) < 0 then
  begin
    ForestDensity.Position := Max(0, ForestDensity.Position - WheelSteps); //can't set negative number
    aHandled := True;
  end;

  if GetKeyState(VK_SHIFT) < 0 then
  begin
    ForestAge.Position := Max(0, ForestAge.Position - WheelSteps); //can't set negative number
    aHandled := True;
  end;

  if aHandled then
    ObjectsBrushChange(nil);   
end;


procedure TKMMapEdTerrainObjects.KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);
begin
  if aHandled then Exit;

  aHandled := Key = gResKeys[kfMapedObjPalette].Key;
  if (Key = VK_ESCAPE) and PopUp_ObjectsPalette.Visible then
  begin
    PopUp_ObjectsPalette.Hide;
    aHandled := True;
  end;
end;


procedure TKMMapEdTerrainObjects.KeyUp(Key: Word; Shift: TShiftState; var aHandled: Boolean);
begin
  aHandled := Key = gResKeys[kfMapedObjPalette].Key;
  if aHandled then
  begin
    //Reset selected and hide all pages
    if Assigned(fHideAllPages) and (gMySpectator.Selected <> nil) then
    begin
      gMySpectator.Selected := nil;
      fHideAllPages;
    end;

    PopUp_ObjectsPalette.ToggleVisibility;
  end;
end;


procedure TKMMapEdTerrainObjects.Resize;
begin
  ObjPalette_UpdateControlsPosition;
end;


procedure TKMMapEdTerrainObjects.Cancel_Clicked(var aHandled: Boolean);
begin
  if aHandled then Exit;

  // Reset last object on RMB click
  if gGameCursor.Mode = cmObjects then
  begin
    fLastObjectIndex := -1;
    aHandled := True;
  end;
end;


procedure TKMMapEdTerrainObjects.UpdateState;
begin
  ObjectsRefresh(nil);
end;


end.
