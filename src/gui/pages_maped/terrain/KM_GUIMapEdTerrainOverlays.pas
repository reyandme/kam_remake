unit KM_GUIMapEdTerrainOverlays;
{$I KaM_Remake.inc}
interface
uses
   Math, SysUtils,
   KM_InterfaceDefaults,
   KM_Controls, KM_ControlsBase,
   KM_Defaults, KM_Pics, KM_TerrainTypes;


type
  TKMMapEdTerrainOverlays = class(TKMMapEdSubMenuPage)
  private
    fLastOverlay: Word;

    procedure OverlayChange(Sender: TObject);
    procedure OverlaySet(aIndex: Integer);
    procedure OverlayRefresh(Sender: TObject);
  protected
    Panel_Overlays: TKMPanel;
    OverlaysTable: array [toNone..toRoad] of TKMButtonFlat;
  public
    constructor Create(aParent: TKMPanel);

    procedure Show;
    procedure Hide;
    procedure UpdateState;
    function Visible: Boolean; override;
  end;


implementation
uses
  TypInfo,
  KM_ResFonts, KM_ResTexts, KM_ResTypes,
  KM_Cursor, KM_RenderUI, KM_InterfaceGame;


constructor TKMMapEdTerrainOverlays.Create(aParent: TKMPanel);
const
  BTN_SIZE = 36;
  BTNS_PER_ROW = 5;

  OVERLAY_HINTS_TX: array [toNone..toRoad] of Integer =
                            (TX_MAPED_TERRAIN_OVERLAY_TO_NONE, TX_MAPED_TERRAIN_OVERLAY_TO_DIG1,
                             TX_MAPED_TERRAIN_OVERLAY_TO_DIG2, TX_MAPED_TERRAIN_OVERLAY_TO_DIG3,
                             TX_MAPED_TERRAIN_OVERLAY_TO_DIG4, TX_MAPED_TERRAIN_OVERLAY_TO_ROAD);
var
  TTO: TKMTileOverlay;
begin
  inherited Create;

  Panel_Overlays := TKMPanel.Create(aParent, 0, 28, aParent.Width, 400);
  with TKMLabel.Create(Panel_Overlays, 0, TERRAIN_PAGE_TITLE_Y, Panel_Overlays.Width, 0, gResTexts[TX_MAPED_TERRAIN_OVERLAYS], fntOutline, taCenter) do
    Anchors := [anLeft, anTop, anRight];
  for TTO := Low(OverlaysTable) to High(OverlaysTable) do
  begin
    OverlaysTable[TTO] := TKMButtonFlat.Create(Panel_Overlays, 9 + (Byte(TTO) mod BTNS_PER_ROW) * BTN_SIZE,
                                                             BTN_SIZE + (Byte(TTO) div BTNS_PER_ROW) * BTN_SIZE,
                                                             BTN_SIZE,
                                                             BTN_SIZE,
                                                             IfThen(TILE_OVERLAY_IDS[TTO] > 0, TILE_OVERLAY_IDS[TTO] + 1, 0),
                                                             rxTiles);
    OverlaysTable[TTO].Tag := TILE_OVERLAY_IDS[TTO];
//    OverlaysTable[J].Caption := IntToStr(OverlaysTable[J].Tag);
//    OverlaysTable[J].CapOffsetY := -8;
//    OverlaysTable[J].TexOffsetY := 6;
//    OverlaysTable[J].CapColor := icYellow;
    OverlaysTable[TTO].Hint := gResTexts[OVERLAY_HINTS_TX[TTO]];
    OverlaysTable[TTO].OnClick := OverlayChange;
  end;
end;


procedure TKMMapEdTerrainOverlays.OverlayChange(Sender: TObject);
var
  TTO: TKMTileOverlay;
begin
  for TTO := Low(OverlaysTable) to High(OverlaysTable) do
    if Sender = OverlaysTable[TTO] then
    begin
      gCursor.Mode := cmOverlays;
      gCursor.Tag1 := Byte(TTO);
    end;
end;


procedure TKMMapEdTerrainOverlays.OverlaySet(aIndex: Integer);
begin
  if aIndex > 0 then
  begin
    gCursor.Mode := cmOverlays;
    gCursor.Tag1 := aIndex;
    fLastOverlay := aIndex;
  end;

  OverlayRefresh(nil);
end;


procedure TKMMapEdTerrainOverlays.OverlayRefresh(Sender: TObject);
var
  TTO: TKMTileOverlay;
begin
  for TTO := Low(OverlaysTable) to High(OverlaysTable) do
    OverlaysTable[TTO].Down := (gCursor.Mode = cmOverlays) and (gCursor.Tag1 = Byte(TTO));
end;


procedure TKMMapEdTerrainOverlays.Show;
begin
  OverlaySet(fLastOverlay);
  gCursor.MapEdDir := 0;
  Panel_Overlays.Show;
end;


function TKMMapEdTerrainOverlays.Visible: Boolean;
begin
  Result := Panel_Overlays.Visible;
end;


procedure TKMMapEdTerrainOverlays.Hide;
begin
  Panel_Overlays.Hide;
end;


procedure TKMMapEdTerrainOverlays.UpdateState;
begin
  OverlayRefresh(nil);
end;


end.
