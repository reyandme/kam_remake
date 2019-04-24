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
  TKMMapEdTerrainObjects = class (TKMMapEdSubMenuPage)
  private
    fHideAllPages: TEvent;
    //Objects in MapElem are placed sparsely, so we need to compact them
    //to use in MapEd palette
    fLastObjectIndex: Integer;
    fCountCompact: Integer;
    fCompactToMapElem: array [Byte] of Byte; //Pointers to valid MapElem's
    fMapElemToCompact: array [Byte] of Byte; //Pointers of valid MapElem's back to map objects. (reverse lookup to one above) 256 is no object.

    fObjPaletteTableSize: TKMPoint;

    function GetObjPaletteTableHeight: Integer;
    function GetObjPaletteTableWidth: Integer;

    procedure UpdateObjButtonDescription(aBtn: TKMButtonFlat; aObjID: Integer);
    procedure CompactMapElements;
    procedure ObjectsUpdate(aObjIndex: Integer);
    procedure UpdateObjectsScrollPosToIndex(aObjIndex: Integer);
    procedure ObjectsChange(Sender: TObject);
    procedure ObjectsRefresh(Sender: TObject);

    procedure ObjectsPalette_Refresh(Sender: TObject);
    procedure ObjPalette_UpdateControlsPosition;
    procedure ObjectsPalette_OnShow(Sender: TObject; aVisible: Boolean);
    procedure ObjPalette_ClickShift(Sender: TObject; Shift: TShiftState);

    procedure ObjectsPaletteButton_Click(Sender: TObject);
    procedure ObjectsPaletteClose_Click(Sender: TObject);
  protected
    Panel_Objects: TKMPanel;
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
      Scroll_ObjectsPalette: TKMScrollBar;
  public
    constructor Create(aParent: TKMPanel; aHideAllPages: TEvent);

    procedure KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);
    procedure KeyUp(Key: Word; Shift: TShiftState; var aHandled: Boolean);

    procedure Show;
    function Visible: Boolean; override;
    procedure Hide;
    procedure Resize;
    procedure RightClickCancel;
    procedure UpdateState;
  end;


implementation
uses
  KM_Resource, KM_ResFonts, KM_ResMapElements, KM_ResTexts, KM_ResKeys, KM_Terrain,
  KM_HandsCollection, KM_RenderUI, KM_InterfaceGame, KM_Utils;

const
  OBJECTS_PALETTE_MAX_COLS_CNT = 17;
  OBJ_CELL_W = 64;
  OBJ_CELL_H = 84;

  OBJ_NONE_TAG = -100;
  OBJ_BLOCK_TAG = -200;


{ TKMMapEdTerrainObjects }
constructor TKMMapEdTerrainObjects.Create(aParent: TKMPanel; aHideAllPages: TEvent);
var
  I, J: Integer;
begin
  inherited Create;

  fHideAllPages := aHideAllPages;
  fLastObjectIndex := -1;

  CompactMapElements;

  Panel_Objects := TKMPanel.Create(aParent, 0, 28, TB_MAP_ED_WIDTH, 400);
  TKMLabel.Create(Panel_Objects, 0, PAGE_TITLE_Y, TB_MAP_ED_WIDTH, 0, gResTexts[TX_MAPED_OBJECTS], fntOutline, taCenter);
  ObjectsScroll := TKMScrollBar.Create(Panel_Objects, 7, 295, TB_MAP_ED_WIDTH - 7, 20, saHorizontal, bsGame);
  ObjectsScroll.MinValue := 0;
  ObjectsScroll.MaxValue := (fCountCompact - 1) div 3 - 2;
  ObjectsScroll.Position := 0;
  ObjectsScroll.OnChange := ObjectsRefresh;
  for I := 0 to 2 do
    for J := 0 to 2 do
    begin
      ObjectsTable[I*3+J] := TKMButtonFlat.Create(Panel_Objects, 2 + I*(OBJ_CELL_W + 1), 40 + J*(OBJ_CELL_H + 1),
                                                  OBJ_CELL_W, OBJ_CELL_H, 1, rxTrees); //RXid=1  // 1 2
      ObjectsTable[I*3+J].CapOffsetY := 15;
      ObjectsTable[I*3+J].Tag := I*3+J; //Store ID
      ObjectsTable[I*3+J].OnClick := ObjectsChange;
      ObjectsTable[I*3+J].OnMouseWheel := ObjectsScroll.MouseWheel;
    end;
  ObjectErase := TKMButtonFlat.Create(Panel_Objects, 9, 4, 32, 32, 340);
  ObjectErase.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_OBJECTS_REMOVE, SC_MAPEDIT_SUB_MENU_ACTION_1);
  ObjectErase.Tag := OBJ_NONE_TAG; //no object
  ObjectErase.OnClick := ObjectsChange;

  ObjectBlock := TKMButtonFlat.Create(Panel_Objects, TB_MAP_ED_WIDTH-32, 4, 32, 32, 254,rxTrees);
  ObjectBlock.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_OBJECTS_BLOCK, SC_MAPEDIT_SUB_MENU_ACTION_2);
  ObjectBlock.Tag := OBJ_BLOCK_TAG; //block object
  ObjectBlock.OnClick := ObjectsChange;

  ObjectsPalette_Button := TKMButtonFlat.Create(Panel_Objects, 7, 320, TB_MAP_ED_WIDTH - 7, 21, 0);
  ObjectsPalette_Button.Caption := gResTexts[TX_MAPED_TERRAIN_OBJECTS_PALETTE];
  ObjectsPalette_Button.CapOffsetY := -11;
  ObjectsPalette_Button.Hint := GetHintWHotKey(TX_MAPED_TERRAIN_OBJECTS_PALETTE, SC_MAPEDIT_OBJ_PALETTE);
  ObjectsPalette_Button.OnClick := ObjectsPaletteButton_Click;

  PopUp_ObjectsPalette := TKMPopUpMenu.Create(aParent.MasterParent, aParent.MasterParent.Width - 50);
  PopUp_ObjectsPalette.Height := aParent.MasterParent.Height - 50;
  PopUp_ObjectsPalette.OnChangeVisibility := ObjectsPalette_OnShow;
  // Keep the pop-up centered
  PopUp_ObjectsPalette.AnchorsCenter;
  PopUp_ObjectsPalette.Left := 25;
  PopUp_ObjectsPalette.Top := 25;

    Bevel_ObjectsPalette := TKMBevel.Create(PopUp_ObjectsPalette, -1000,  -1000, 4000, 4000);
    Bevel_ObjectsPalette.BackAlpha := 0.7;
    Bevel_ObjectsPalette.EdgeAlpha := 0.9;

    Image_ObjectsPalette := TKMImage.Create(PopUp_ObjectsPalette, 0, 0, PopUp_ObjectsPalette.Width, PopUp_ObjectsPalette.Height, 3, rxGuiMain);
    Image_ObjectsPalette.ImageStretch;

    Scroll_ObjectsPalette := TKMScrollBar.Create(PopUp_ObjectsPalette, PopUp_ObjectsPalette.Width - 20, 25, 20, PopUp_ObjectsPalette.Height - 75, saVertical, bsGame);
    Scroll_ObjectsPalette.MinValue := 0;
    Scroll_ObjectsPalette.Position := 0;
    Scroll_ObjectsPalette.OnChange := ObjectsPalette_Refresh;

    Image_ObjectsPalette.OnMouseWheel := Scroll_ObjectsPalette.MouseWheel;
    Image_ObjectsPalette.OnClickShift := ObjPalette_ClickShift;
    Bevel_ObjectsPalette.OnMouseWheel := Scroll_ObjectsPalette.MouseWheel;
    Bevel_ObjectsPalette.OnClickShift := ObjPalette_ClickShift;

    SetLength(ObjectsPaletteTable, fCountCompact);
    for I := 0 to fCountCompact - 1 do
    begin
      ObjectsPaletteTable[I] := TKMButtonFlat.Create(PopUp_ObjectsPalette, 0, 0, OBJ_CELL_W, OBJ_CELL_H, 1, rxTrees); // Left and Top will update later
      ObjectsPaletteTable[I].Tag := I; //Store ID
      ObjectsPaletteTable[I].CapOffsetY := 15;
      ObjectsPaletteTable[I].Enable;
      ObjectsPaletteTable[I].Hide;
      ObjectsPaletteTable[I].OnMouseWheel := Scroll_ObjectsPalette.MouseWheel;
      ObjectsPaletteTable[I].OnClickShift := ObjPalette_ClickShift;
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

  fSubMenuActionsEvents[0] := ObjectsChange;
  fSubMenuActionsEvents[1] := ObjectsChange;
  fSubMenuActionsEvents[2] := ObjectsPaletteButton_Click;

  fSubMenuActionsCtrls[0] := ObjectErase;
  fSubMenuActionsCtrls[1] := ObjectBlock;
  fSubMenuActionsCtrls[2] := ObjectsPalette_Button;
end;


procedure TKMMapEdTerrainObjects.ObjectsPalette_OnShow(Sender: TObject; aVisible: Boolean);
begin
  if aVisible then
    ObjPalette_UpdateControlsPosition;
end;


function TKMMapEdTerrainObjects.GetObjPaletteTableHeight: Integer;
begin
  Result := (OBJ_CELL_H + 1)*Min(fObjPaletteTableSize.Y, ((fCountCompact - 1) div fObjPaletteTableSize.X) + 1);
end;


function TKMMapEdTerrainObjects.GetObjPaletteTableWidth: Integer;
begin
  Result := (OBJ_CELL_W + 1)*fObjPaletteTableSize.X;
end;


procedure TKMMapEdTerrainObjects.UpdateObjButtonDescription(aBtn: TKMButtonFlat; aObjID: Integer);
var
  ChoppableTree: Boolean;
begin
  aBtn.CapColor := icWhite;
  aBtn.Hint := aBtn.Caption;

  ChoppableTree := False;
  if ObjectIsChoppableTree(aObjID, [caAge1, caAge2, caAge3, caAgeFull]) then
  begin
    aBtn.CapColor := icRoyalYellow;
    aBtn.Hint := aBtn.Hint + ' / ' + gResTexts[TX_MAPED_OBJ_DESC_CHOPPABLE];
    ChoppableTree := True;
  end;

  if gMapElements[aObjID].DiagonalBlocked then
  begin
    aBtn.Hint := aBtn.Hint + ' / ' + gResTexts[TX_MAPED_OBJ_DESC_BLOCK_DIAG];
    if not ChoppableTree then
      aBtn.CapColor := icLightRed;
  end else
  if gMapElements[aObjID].AllBlocked then
  begin
    aBtn.Hint := aBtn.Hint + ' / ' + gResTexts[TX_MAPED_OBJ_DESC_BLOCK_ALL];
    if not ChoppableTree then
      aBtn.CapColor := icRed;
  end;
end;


procedure TKMMapEdTerrainObjects.ObjectsPalette_Refresh(Sender: TObject);
var
  I, J, K, LeftAdj, TopAdj: Integer;
begin
  LeftAdj := (PopUp_ObjectsPalette.Width - fObjPaletteTableSize.X*(OBJ_CELL_W + 1) - 25*Byte(Scroll_ObjectsPalette.Visible)) div 2;
  TopAdj := Image_ObjectsPalette.Top + 25;

  K := 0;

  Button_ObjPaletteErase.Left := LeftAdj;
  Button_ObjPaletteBlock.Left := LeftAdj + OBJ_CELL_W + 1;

  for I := 0 to fObjPaletteTableSize.Y - 1 do
    for J := 0 to fObjPaletteTableSize.X - 1 do
    begin
      K := (I + Scroll_ObjectsPalette.Position)*fObjPaletteTableSize.X + J;
      if K < fCountCompact then
      begin
        ObjectsPaletteTable[K].Left := J*(OBJ_CELL_W + 1) + LeftAdj;
        ObjectsPaletteTable[K].Top := 25 + I*(OBJ_CELL_H + 1)  + TopAdj;
        ObjectsPaletteTable[K].TexID := gMapElements[fCompactToMapElem[K]].Anim.Step[1] + 1;
        ObjectsPaletteTable[K].Caption := IntToStr(fCompactToMapElem[K]);

        UpdateObjButtonDescription(ObjectsPaletteTable[K], fCompactToMapElem[K]);

        ObjectsPaletteTable[K].Visible := True;
      end;
    end;

  // Make invisible all palette buttons at the end of the list, after shown buttons 'page'
  for I := K + 1 to fCountCompact - 1 do
    ObjectsPaletteTable[I].Visible := False;

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

  RowsCnt := Max(1, (PopUp_ObjectsPalette.Height - 80) div (OBJ_CELL_H + 1));
  //Calc cols count without Scroll first
  ColsCnt := EnsureRange(PopUp_ObjectsPalette.Width div (OBJ_CELL_W + 1), 1, OBJECTS_PALETTE_MAX_COLS_CNT);
  Scroll_ObjectsPalette.Visible := RowsCnt*ColsCnt < fCountCompact;
  //Recalc ColsCount considering possible scroll width
  ColsCnt := EnsureRange((PopUp_ObjectsPalette.Width - 25*Byte(Scroll_ObjectsPalette.Visible)) div (OBJ_CELL_W + 1), 1, OBJECTS_PALETTE_MAX_COLS_CNT);

  fObjPaletteTableSize := KMPoint(ColsCnt, RowsCnt);

  Image_ObjectsPalette.Width := GetObjPaletteTableWidth + 100;
  Image_ObjectsPalette.Height := GetObjPaletteTableHeight + 150;
  Image_ObjectsPalette.Left := (PopUp_ObjectsPalette.Width - Image_ObjectsPalette.Width) div 2;
  Image_ObjectsPalette.Top := ((PopUp_ObjectsPalette.Height - Image_ObjectsPalette.Height) div 2);

  Label_ObjectsPalette.Left := PopUp_ObjectsPalette.Center.X;
  Label_ObjectsPalette.Top := Image_ObjectsPalette.Top + 25;

  Button_ClosePalette.Left := PopUp_ObjectsPalette.Center.X - 100;
  Button_ClosePalette.Top := Image_ObjectsPalette.Bottom - 70;

  Button_ObjPaletteErase.Top := Image_ObjectsPalette.Bottom - 70;
  Button_ObjPaletteBlock.Top := Image_ObjectsPalette.Bottom - 70;

  Scroll_ObjectsPalette.Left := Image_ObjectsPalette.Right - 50;
  Scroll_ObjectsPalette.Top := Image_ObjectsPalette.Top + 50;
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



procedure TKMMapEdTerrainObjects.ObjectsChange(Sender: TObject);
var
  ObjIndex: Integer;
begin
  case TKMButtonFlat(Sender).Tag of
    OBJ_BLOCK_TAG,
    OBJ_NONE_TAG:  ObjIndex := TKMButtonFlat(Sender).Tag; // Block or Erase
    else           ObjIndex := ObjectsScroll.Position * 3 + TKMButtonFlat(Sender).Tag; //0..n-1
  end;

  ObjectsUpdate(ObjIndex);

  // Update Objects Palette scroll position
  if (ObjIndex <> OBJ_BLOCK_TAG) and (ObjIndex <> OBJ_NONE_TAG)
    and not InRange(ObjIndex,
                    Scroll_ObjectsPalette.Position*fObjPaletteTableSize.X,
                    Scroll_ObjectsPalette.Position*fObjPaletteTableSize.X + fObjPaletteTableSize.X*fObjPaletteTableSize.Y - 1) then
    Scroll_ObjectsPalette.Position := ((ObjIndex - 1) div fObjPaletteTableSize.X);
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

      UpdateObjButtonDescription(ObjectsTable[I], fCompactToMapElem[ObjIndex]);

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

  ObjectErase.Down := (gGameCursor.Mode = cmObjects) and (gGameCursor.Tag1 = OBJ_NONE);  //or delete button
  ObjectBlock.Down := (gGameCursor.Mode = cmObjects) and (gGameCursor.Tag1 = OBJ_BLOCK); //or block button
end;


procedure TKMMapEdTerrainObjects.Show;
begin
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
end;


procedure TKMMapEdTerrainObjects.KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);
begin
  aHandled := Key = gResKeys[SC_MAPEDIT_OBJ_PALETTE].Key;
  if (Key = VK_ESCAPE) and PopUp_ObjectsPalette.Visible then
  begin
    PopUp_ObjectsPalette.Hide;
    aHandled := True;
  end;
end;


procedure TKMMapEdTerrainObjects.KeyUp(Key: Word; Shift: TShiftState; var aHandled: Boolean);
begin
  aHandled := Key = gResKeys[SC_MAPEDIT_OBJ_PALETTE].Key;
  if aHandled then
  begin
    //Reset selected and hide all pages
    if Assigned(fHideAllPages) and (gMySpectator.Selected <> nil) then
    begin
      gMySpectator.Selected := nil;
      fHideAllPages;
    end;

    PopUp_ObjectsPalette.Show;
  end;
end;


procedure TKMMapEdTerrainObjects.Resize;
begin
  ObjPalette_UpdateControlsPosition;
end;


procedure TKMMapEdTerrainObjects.RightClickCancel;
begin
  // Reset last object on RMB click
  if gGameCursor.Mode = cmObjects then
    fLastObjectIndex := -1;
end;


procedure TKMMapEdTerrainObjects.UpdateState;
begin
  ObjectsRefresh(nil);
end;


end.
