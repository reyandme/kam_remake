unit KM_GUIMapEdTerrainHeights;
{$I KaM_Remake.inc}
interface
uses
   Classes, Math, SysUtils,
   KM_InterfaceDefaults,
   KM_Controls, KM_ControlsBase, KM_ControlsTrackBar,
   KM_Defaults;


type
  //Terrain height editing
  TKMMapEdTerrainHeights = class(TKMMapEdSubMenuPage)
  private
    fLastCursorMode: TKMCursorMode;
    fLastShape: TKMMapEdShape;
    procedure HeightChange(Sender: TObject);
    procedure HeightRefresh;
    procedure UpdateHeightParams;
  protected
    Panel_Heights: TKMPanel;
    HeightSize: TKMTrackBar;
    HeightSlope: TKMTrackBar;
    HeightSpeed: TKMTrackBar;
    HeightShapeLabel: TKMLabel;
    HeightCircle: TKMButtonFlat;
    HeightSquare: TKMButtonFlat;
    HeightElevate: TKMButtonFlat;
    HeightUnequalize: TKMButtonFlat;
    HeightConstant: TKMButtonFlat;
    HeightConstantNumber: TKMTrackBar;
    HeightElevateAll: TKMButtonFlat;
  public
    constructor Create(aParent: TKMPanel);

    procedure Show;
    procedure Hide;
    procedure MouseWheel(Shift: TShiftState; WheelSteps: Integer; X,Y: Integer; var aHandled: Boolean);
    function Visible: Boolean; override;

    procedure UpdateHotkeys;
  end;


implementation
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLType, LCLIntF, {$ENDIF}
  KM_Main, KM_ResFonts, KM_ResTexts, KM_Cursor, KM_RenderUI,
  KM_GameSettings,
  KM_InterfaceGame, KM_Utils,
  KM_ResTypes, KM_TerrainTypes;


{ TKMMapEdTerrainHeights }
constructor TKMMapEdTerrainHeights.Create(aParent: TKMPanel);
begin
  inherited Create;

  fLastCursorMode := cmElevate;
  fLastShape := hsCircle;

  Panel_Heights := TKMPanel.Create(aParent, 0, 28, aParent.Width, 400);
  with TKMLabel.Create(Panel_Heights, 0, TERRAIN_PAGE_TITLE_Y, Panel_Heights.Width, 0, gResTexts[TX_MAPED_TERRAIN_HEIGHTS], fntOutline, taCenter) do
    Anchors := [anLeft, anTop, anRight];
  HeightShapeLabel := TKMLabel.Create(Panel_Heights, 9, 34, Panel_Heights.Width - 18, 0, gResTexts[TX_MAPED_TERRAIN_HEIGHTS_SHAPE], fntMetal, taLeft);

  HeightCircle := TKMButtonFlat.Create(Panel_Heights, Panel_Heights.Width - 48 - 9, 30, 24, 24, 592);
  HeightCircle.Anchors := [anTop, anRight];
  HeightCircle.OnClick  := HeightChange;

  HeightSquare := TKMButtonFlat.Create(Panel_Heights, Panel_Heights.Width - 24, 30, 24, 24, 593);
  HeightSquare.Anchors := [anTop, anRight];
  HeightSquare.OnClick  := HeightChange;

  HeightSize          := TKMTrackBar.Create(Panel_Heights, 9, 60, Panel_Heights.Width - 9, 1, 15); //1..15(4bit) for size
  HeightSize.Anchors := [anLeft, anTop, anRight];
  HeightSize.Caption  := gResTexts[TX_MAPED_TERRAIN_HEIGHTS_SIZE];
  HeightSize.Hint     := GetHintWHotkey(TX_MAPED_TERRAIN_HEIGHTS_SIZE_HINT, gResTexts[TX_KEY_CTRL_MOUSEWHEEL]);
  HeightSize.OnChange := HeightChange;

  HeightSlope           := TKMTrackBar.Create(Panel_Heights, 9, 115, Panel_Heights.Width - 9, 1, 15); //1..15(4bit) for slope shape
  HeightSlope.Anchors := [anLeft, anTop, anRight];
  HeightSlope.Caption   := gResTexts[TX_MAPED_TERRAIN_HEIGHTS_SLOPE];
  HeightSlope.Hint      := GetHintWHotkey(TX_MAPED_TERRAIN_HEIGHTS_SLOPE_HINT, gResTexts[TX_KEY_ALT_MOUSEWHEEL]);
  HeightSlope.OnChange  := HeightChange;

  HeightSpeed           := TKMTrackBar.Create(Panel_Heights, 9, 170, Panel_Heights.Width - 9, 1, 15); //1..15(4bit) for speed
  HeightSpeed.Anchors := [anLeft, anTop, anRight];
  HeightSpeed.Caption   := gResTexts[TX_MAPED_TERRAIN_HEIGHTS_SPEED];
  HeightSpeed.Hint      := GetHintWHotkey(TX_MAPED_TERRAIN_HEIGHTS_SPEED_HINT, gResTexts[TX_KEY_SHIFT_MOUSEWHEEL]);
  HeightSpeed.OnChange  := HeightChange;

  HeightElevate               := TKMButtonFlat.Create(Panel_Heights, 9, 225, Panel_Heights.Width - 9, 20, 0);
  HeightElevate.Anchors := [anLeft, anTop, anRight];
  HeightElevate.OnClick       := HeightChange;
  HeightElevate.Down          := True;
  HeightElevate.Caption       := gResTexts[TX_MAPED_TERRAIN_HEIGHTS_ELEVATE];
  HeightElevate.CapOffsetY    := -12;

  HeightUnequalize            := TKMButtonFlat.Create(Panel_Heights, 9, 255, Panel_Heights.Width - 9, 20, 0);
  HeightUnequalize.Anchors := [anLeft, anTop, anRight];
  HeightUnequalize.OnClick    := HeightChange;
  HeightUnequalize.Caption    := gResTexts[TX_MAPED_TERRAIN_HEIGHTS_UNEQUALIZE];
  HeightUnequalize.CapOffsetY := -12;

  HeightElevateAll               := TKMButtonFlat.Create(Panel_Heights, 9, 280, Panel_Heights.Width - 9, 20, 0);
  HeightElevateAll.Anchors := [anLeft, anTop, anRight];
  HeightElevateAll.OnClick       := HeightChange;
  HeightElevateAll.Down          := True;
  HeightElevateAll.Caption       := gResTexts[TX_MAPED_HEIGHTS_ELEVATE_ALL];
  HeightElevateAll.CapOffsetY    := -12;

  HeightConstant            := TKMButtonFlat.Create(Panel_Heights, 9, 305, Panel_Heights.Width - 9, 20, 0);
  HeightConstant.Anchors := [anLeft, anTop, anRight];
  HeightConstant.OnClick    := HeightChange;
  HeightConstant.Caption    := gResTexts[TX_MAPED_HEIGHTS_CONST];
  HeightConstant.CapOffsetY := -12;

  HeightConstantNumber           := TKMTrackBar.Create(Panel_Heights, 9, 340, Panel_Heights.Width - 9, 0, gGameSettings.MapEdMaxTerrainHeight); //1..100 Height level
  HeightConstantNumber.Anchors := [anLeft, anTop, anRight];
  HeightConstantNumber.Caption   := gResTexts[TX_MAPED_HEIGHTS_LEVEL_SET];
  HeightConstantNumber.Hint      := gResTexts[TX_MAPED_HEIGHTS_LEVEL_SET_HINT];
  HeightConstantNumber.OnChange  := HeightChange;



  fSubMenuActionsEvents[0] := HeightChange;
  fSubMenuActionsEvents[1] := HeightChange;
  fSubMenuActionsEvents[2] := HeightChange;
  fSubMenuActionsEvents[3] := HeightChange;
  fSubMenuActionsEvents[4] := HeightChange;
  fSubMenuActionsEvents[5] := HeightChange;

  fSubMenuActionsCtrls[0,0] := HeightCircle;
  fSubMenuActionsCtrls[1,0] := HeightSquare;
  fSubMenuActionsCtrls[2,0] := HeightElevate;
  fSubMenuActionsCtrls[3,0] := HeightUnequalize;
  fSubMenuActionsCtrls[4,0] := HeightElevateAll;
  fSubMenuActionsCtrls[5,0] := HeightConstant;
end;


procedure TKMMapEdTerrainHeights.HeightChange(Sender: TObject);
begin
  gCursor.MapEdSize := HeightSize.Position;
  gCursor.MapEdSlope := HeightSlope.Position;
  gCursor.MapEdSpeed := HeightSpeed.Position;

  //Shape
  if Sender = HeightCircle then
  begin
    gCursor.MapEdShape := hsCircle;
    fLastShape := hsCircle;
  end
  else
  if Sender = HeightSquare then
  begin
    gCursor.MapEdShape := hsSquare;
    fLastShape := hsSquare;
  end;

  //Kind
  if Sender = HeightElevate then
  begin
    gCursor.Mode := cmElevate;
    fLastCursorMode := cmElevate;
  end else
  if Sender = HeightUnequalize then
  begin
    gCursor.Mode := cmEqualize;
    fLastCursorMode := cmEqualize;
  end;

  if Sender = HeightConstant then
  begin
    gCursor.Mode := cmConstHeight;
    fLastCursorMode := cmConstHeight;
  end;

  if Sender = HeightElevateAll then
  begin
    gCursor.Mode := cmElevateAll;
    fLastCursorMode := cmElevateAll;
  end;
  HeightRefresh;
end;


procedure TKMMapEdTerrainHeights.HeightRefresh;
begin
  HeightCircle.Down := (gCursor.MapEdShape = hsCircle);
  HeightSquare.Down := (gCursor.MapEdShape = hsSquare);

  HeightElevate.Down := (gCursor.Mode = cmElevate);
  HeightUnequalize.Down := (gCursor.Mode = cmEqualize);

  HeightConstant.Down := (gCursor.Mode = cmConstHeight);
  HeightElevateAll.Down := (gCursor.Mode = cmElevateAll);
  gCursor.MapEdConstHeight := HeightConstantNumber.Position;
end;


procedure TKMMapEdTerrainHeights.UpdateHeightParams;
begin
  gCursor.MapEdSize  := HeightSize.Position;
  gCursor.MapEdSlope := HeightSlope.Position;
  gCursor.MapEdSpeed := HeightSpeed.Position;
end;


procedure TKMMapEdTerrainHeights.UpdateHotkeys;
begin
  HeightCircle.Hint     := GetHintWHotkey(TX_MAPED_TERRAIN_HEIGHTS_CIRCLE,          kfMapedSubMenuAction1);
  HeightSquare.Hint     := GetHintWHotkey(TX_MAPED_TERRAIN_HEIGHTS_SQUARE,          kfMapedSubMenuAction2);
  HeightElevate.Hint    := GetHintWHotkey(TX_MAPED_TERRAIN_HEIGHTS_ELEVATE_HINT,    kfMapedSubMenuAction3);
  HeightUnequalize.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_HEIGHTS_UNEQUALIZE_HINT, kfMapedSubMenuAction4);
  HeightElevateAll.Hint := GetHintWHotkey(TX_MAPED_HEIGHTS_ELEVATE_ALL_HINT,        kfMapedSubMenuAction5);
  HeightConstant.Hint   := GetHintWHotkey(TX_MAPED_HEIGHTS_CONST_HINT,              kfMapedSubMenuAction6);
end;


procedure TKMMapEdTerrainHeights.Show;
begin
  gMain.FormMain.SuppressAltForMenu := True;
  gCursor.Mode := fLastCursorMode;
  gCursor.MapEdShape := fLastShape;
  UpdateHeightParams;
  gCursor.MapEdSpeed := HeightSpeed.Position;
  HeightRefresh;
  Panel_Heights.Show;
end;


procedure TKMMapEdTerrainHeights.MouseWheel(Shift: TShiftState; WheelSteps, X, Y: Integer; var aHandled: Boolean);
begin
  if aHandled or not Visible then
    Exit;

  // Do not use ssCtrl in Shift here, as it can sometimes be wrong values inside Shift (ssShift instead of ssCtrl)
  if GetKeyState(VK_CONTROL) < 0 then
  begin
    HeightSize.Position := Max(0, HeightSize.Position - WheelSteps); //can't set negative number
    aHandled := True;
  end;

  if GetKeyState(VK_MENU) < 0 then
  begin
    HeightSlope.Position := Max(0, HeightSlope.Position - WheelSteps); //can't set negative number
    aHandled := True;
  end;

  if GetKeyState(VK_SHIFT) < 0 then
  begin
    HeightSpeed.Position := Max(0, HeightSpeed.Position - WheelSteps); //can't set negative number
    aHandled := True;
  end;

  if aHandled then
    UpdateHeightParams;
end;


function TKMMapEdTerrainHeights.Visible: Boolean;
begin
  Result := Panel_Heights.Visible;
end;


procedure TKMMapEdTerrainHeights.Hide;
begin
  Panel_Heights.Hide;
  gMain.FormMain.SuppressAltForMenu := False;
end;


end.
