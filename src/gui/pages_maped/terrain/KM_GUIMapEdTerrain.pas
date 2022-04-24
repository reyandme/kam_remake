unit KM_GUIMapEdTerrain;
{$I KaM_Remake.inc}
interface
uses
   Classes, Math, SysUtils,
   KM_Controls, KM_ControlsBase,
   KM_Defaults, KM_Pics, KM_CommonTypes,
   KM_InterfaceDefaults,
   KM_GUIMapEdTerrainBrushes,
   KM_GUIMapEdTerrainHeights,
   KM_GUIMapEdTerrainTiles,
   KM_GUIMapEdTerrainObjects,
   KM_GUIMapEdTerrainSelection,
   KM_GUIMapEdTerrainOverlays;


type
  TKMTerrainTab = (ttBrush, ttHeights, ttTile, ttOverlays, ttObject, ttSelection);

  //Collection of terrain editing controls
  TKMMapEdTerrain = class(TKMMapEdMenuPage)
  private
    fOnPageChange: TNotifyEvent;

    fGuiBrushes: TKMMapEdTerrainBrushes;
    fGuiHeights: TKMMapEdTerrainHeights;
    fGuiTiles: TKMMapEdTerrainTiles;
    fGuiObjects: TKMMapEdTerrainObjects;
    fGuiSelection: TKMMapEdTerrainSelection;
    fGuiOverlays: TKMMapEdTerrainOverlays;

    procedure PageChange(Sender: TObject);
    function GetGuiTiles: TKMMapEdTerrainTiles;
  protected
    Panel_Terrain: TKMPanel;
    Button_Terrain: array [TKMTerrainTab] of TKMButton;
    procedure DoShowSubMenu(aIndex: Byte); override;
    procedure DoExecuteSubMenuAction(aIndex: Byte; var aHandled: Boolean); override;
  public
    constructor Create(aParent: TKMPanel; aOnPageChange: TNotifyEvent; aHideAllPages: TEvent);
    destructor Destroy; override;
    procedure KeyDown(Key: Word; Shift: TShiftState; aIsFirst: Boolean; var aHandled: Boolean);
    procedure MouseWheel(Shift: TShiftState; WheelSteps: Integer; X,Y: Integer; var aHandled: Boolean);

    property GuiTiles: TKMMapEdTerrainTiles read GetGuiTiles;
    property GuiSelection: TKMMapEdTerrainSelection read fGuiSelection;

    procedure Show(aTab: TKMTerrainTab);
    //procedure
    function IsVisible(aPage: TKMTerrainTab): Boolean;
    function Visible: Boolean;  override;
    function IsFocused: Boolean;  override;
    procedure Resize;
    procedure UpdateHotkeys;
    procedure UpdateState;
    procedure Cancel_Clicked(var aHandled: Boolean);
  end;


implementation
uses
  KM_ResTexts, KM_ResTypes,
  KM_Cursor, KM_RenderUI, KM_InterfaceGame, KM_Utils;


{ TKMMapEdTerrain }
constructor TKMMapEdTerrain.Create(aParent: TKMPanel; aOnPageChange: TNotifyEvent; aHideAllPages: TEvent);
const
  TAB_GLYPH: array [TKMTerrainTab] of Word = (383, 388, 382, 400, 385, 384);
  TB_PAD_TERRAIN_BTN_L = 9;

var
  TT: TKMTerrainTab;
begin
  inherited Create;

  fOnPageChange := aOnPageChange;

  Panel_Terrain := TKMPanel.Create(aParent, 0, 45, aParent.Width, aParent.Height - 45);
  Panel_Terrain.AnchorsStretch;
    for TT := Low(TKMTerrainTab) to High(TKMTerrainTab) do
    begin
      Button_Terrain[TT] := TKMButton.Create(Panel_Terrain, TB_PAD_TERRAIN_BTN_L + (SMALL_PAD_W + 4) * Byte(TT), 0,
                                            SMALL_TAB_W + 4, SMALL_TAB_H + 4, TAB_GLYPH[TT], rxGui, bsGame);
      Button_Terrain[TT].OnClick := PageChange;
    end;

    fGuiBrushes := TKMMapEdTerrainBrushes.Create(Panel_Terrain);
    fGuiHeights := TKMMapEdTerrainHeights.Create(Panel_Terrain);
    fGuiTiles := TKMMapEdTerrainTiles.Create(Panel_Terrain);
    fGuiObjects := TKMMapEdTerrainObjects.Create(Panel_Terrain, aHideAllPages);
    fGuiSelection := TKMMapEdTerrainSelection.Create(Panel_Terrain);
    fGuiOverlays := TKMMapEdTerrainOverlays.Create(Panel_Terrain);
end;


destructor TKMMapEdTerrain.Destroy;
begin
  fGuiBrushes.Free;
  fGuiHeights.Free;
  fGuiTiles.Free;
  fGuiObjects.Free;
  fGuiSelection.Free;
  fGuiOverlays.Free;

  inherited;
end;


procedure TKMMapEdTerrain.KeyDown(Key: Word; Shift: TShiftState; aIsFirst: Boolean; var aHandled: Boolean);
begin
  if aHandled or not aIsFirst then Exit;

  fGuiBrushes.KeyDown(Key, Shift, aIsFirst, aHandled);


  fGuiTiles.KeyDown(Key, Shift, aIsFirst, aHandled);
  // Hide Objects palette if Tiles palette visible now
  if fGuiTiles.IsPaletteVisible then
    fGuiObjects.PaletteHide;

  fGuiObjects.KeyDown(Key, Shift, aIsFirst, aHandled);
  // Hide Tiles palette if Objects palette visible now
  if fGuiObjects.IsPaletteVisible then
    fGuiTiles.PaletteHide;

  fGuiSelection.KeyDown(Key, Shift, aIsFirst, aHandled);
end;


procedure TKMMapEdTerrain.MouseWheel(Shift: TShiftState; WheelSteps, X, Y: Integer; var aHandled: Boolean);
begin
  fGuiBrushes.MouseWheel(Shift, WheelSteps, X, Y, aHandled);
  fGuiHeights.MouseWheel(Shift, WheelSteps, X, Y, aHandled);
  fGuiObjects.MouseWheel(Shift, WheelSteps, X, Y, aHandled);
end;


procedure TKMMapEdTerrain.PageChange(Sender: TObject);
begin
  //Reset cursor mode
  gCursor.Mode := cmNone;

  //Hide existing pages
  fGuiBrushes.Hide;
  fGuiHeights.Hide;
  fGuiTiles.Hide;
  fGuiObjects.Hide;
  fGuiSelection.Hide;
  fGuiOverlays.Hide;

  if (Sender = Button_Terrain[ttBrush]) then
    fGuiBrushes.Show
  else
  if (Sender = Button_Terrain[ttHeights]) then
    fGuiHeights.Show
  else
  if (Sender = Button_Terrain[ttTile]) then
    fGuiTiles.Show
  else
  if (Sender = Button_Terrain[ttObject]) then
    fGuiObjects.Show
  else
  if (Sender = Button_Terrain[ttSelection]) then
    fGuiSelection.Show
  else
  if (Sender = Button_Terrain[ttOverlays]) then
    fGuiOverlays.Show;

  //Signal that active page has changed, that may affect layers visibility
  fOnPageChange(Self);
end;


procedure TKMMapEdTerrain.Show(aTab: TKMTerrainTab);
begin
  Panel_Terrain.Show;
  PageChange(Button_Terrain[aTab]);
end;


procedure TKMMapEdTerrain.DoShowSubMenu(aIndex: Byte);
begin
  inherited;

  if (aIndex in [Byte(Low(TKMTerrainTab))..Byte(High(TKMTerrainTab))])
    and Button_Terrain[TKMTerrainTab(aIndex)].Enabled then
    Show(TKMTerrainTab(aIndex));
end;


function TKMMapEdTerrain.GetGuiTiles: TKMMapEdTerrainTiles;
begin
  if Self = nil then Exit(nil);

  Result := fGuiTiles;
end;


procedure TKMMapEdTerrain.DoExecuteSubMenuAction(aIndex: Byte; var aHandled: Boolean);
begin
  inherited;

  // Tiles go first because of Tiles palette (it must have priority over normal left sub-menus
  fGuiTiles.ExecuteSubMenuAction(aIndex, aHandled);

  fGuiBrushes.ExecuteSubMenuAction(aIndex, aHandled);
  fGuiHeights.ExecuteSubMenuAction(aIndex, aHandled);
  fGuiObjects.ExecuteSubMenuAction(aIndex, aHandled);
  fGuiSelection.ExecuteSubMenuAction(aIndex, aHandled);
  fGuiOverlays.ExecuteSubMenuAction(aIndex, aHandled);
end;


function TKMMapEdTerrain.Visible: Boolean;
begin
  Result := Panel_Terrain.Visible;
end;


function TKMMapEdTerrain.IsFocused: Boolean;
begin
  Result := Visible or fGuiTiles.IsFocused;
end;


//Check if specific page is visble
function TKMMapEdTerrain.IsVisible(aPage: TKMTerrainTab): Boolean;
begin
  Result := False;
  case aPage of
    ttBrush:      Result := fGuiBrushes.Visible;
    ttHeights:    Result := fGuiHeights.Visible;
    ttTile:       Result := fGuiTiles.Visible;
    ttObject:     Result := fGuiObjects.Visible;
    ttSelection:  Result := fGuiSelection.Visible;
    ttOverlays:   Result := fGuiOverlays.Visible;
  end;
end;


procedure TKMMapEdTerrain.Resize;
begin
  fGuiObjects.Resize;
end;


procedure TKMMapEdTerrain.Cancel_Clicked(var aHandled: Boolean);
begin
  if aHandled then Exit;

  fGuiObjects.Cancel_Clicked(aHandled);
  fGuiBrushes.Cancel_Clicked(aHandled);
end;


procedure TKMMapEdTerrain.UpdateHotkeys;
const
  TAB_HINT: array [TKMTerrainTab] of Word = (
    TX_MAPED_TERRAIN_HINTS_BRUSHES,
    TX_MAPED_TERRAIN_HINTS_HEIGHTS,
    TX_MAPED_TERRAIN_HINTS_TILES,
    TX_MAPED_TERRAIN_HINTS_OVERLAYS,
    TX_MAPED_TERRAIN_HINTS_OBJECTS,
    TX_MAPED_COPY_TITLE);
var
  TT: TKMTerrainTab;
begin
  for TT := Low(TKMTerrainTab) to High(TKMTerrainTab) do
    Button_Terrain[TT].Hint := GetHintWHotkey(TAB_HINT[TT], MAPED_SUBMENU_HOTKEYS[Ord(TT)]);

  fGuiBrushes.UpdateHotkeys;
  fGuiHeights.UpdateHotkeys;
  fGuiTiles.UpdateHotkeys;
  fGuiObjects.UpdateHotkeys;
  fGuiSelection.UpdateHotkeys;
end;


procedure TKMMapEdTerrain.UpdateState;
begin
  fGuiBrushes.UpdateState;
  fGuiTiles.UpdateState;
  fGuiObjects.UpdateState;
  fGuiSelection.UpdateState;
  fGuiOverlays.UpdateState;
end;


end.

