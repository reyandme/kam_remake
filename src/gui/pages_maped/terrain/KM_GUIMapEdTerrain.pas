unit KM_GUIMapEdTerrain;
{$I KaM_Remake.inc}
interface
uses
   Classes, Math, SysUtils,
   KM_Controls, KM_Defaults, KM_Pics, KM_CommonTypes,
   KM_InterfaceDefaults,
   KM_GUIMapEdTerrainBrushes,
   KM_GUIMapEdTerrainHeights,
   KM_GUIMapEdTerrainTiles,
   KM_GUIMapEdTerrainObjects,
   KM_GUIMapEdTerrainSelection;


type
  TKMTerrainTab = (ttBrush, ttHeights, ttTile, ttObject, ttSelection);

  //Collection of terrain editing controls
  TKMMapEdTerrain = class (TKMMapEdMenuPage)
  private
    fOnPageChange: TNotifyEvent;

    fGuiBrushes: TKMMapEdTerrainBrushes;
    fGuiHeights: TKMMapEdTerrainHeights;
    fGuiTiles: TKMMapEdTerrainTiles;
    fGuiObjects: TKMMapEdTerrainObjects;
    fGuiSelection: TKMMapEdTerrainSelection;

    procedure PageChange(Sender: TObject);
    procedure UnRedoClick(Sender: TObject);
  protected
    Panel_Terrain: TKMPanel;
    Button_Terrain: array [TKMTerrainTab] of TKMButton;
    Button_TerrainUndo: TKMButton;
    Button_TerrainRedo: TKMButton;
    procedure DoShowSubMenu(aIndex: Byte); override;
    procedure DoExecuteSubMenuAction(aIndex: Byte); override;
  public
    constructor Create(aParent: TKMPanel; aOnPageChange: TNotifyEvent; aHideAllPages: TEvent);
    destructor Destroy; override;
    procedure KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);
    procedure KeyUp(Key: Word; Shift: TShiftState; var aHandled: Boolean);
    procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer; X,Y: Integer; var aHandled: Boolean);

    property GuiTiles: TKMMapEdTerrainTiles read fGuiTiles;
    property GuiSelection: TKMMapEdTerrainSelection read fGuiSelection;

    procedure Show(aTab: TKMTerrainTab);
    //procedure
    function IsVisible(aPage: TKMTerrainTab): Boolean;
    function Visible: Boolean;  override;
    procedure Resize;
    procedure UpdateState;
    procedure RightClickCancel;
  end;


implementation
uses
  KM_ResTexts, KM_Game, KM_GameCursor, KM_RenderUI, KM_InterfaceGame, KM_Utils;


{ TKMMapEdTerrain }
constructor TKMMapEdTerrain.Create(aParent: TKMPanel; aOnPageChange: TNotifyEvent; aHideAllPages: TEvent);
const
  BtnGlyph: array [TKMTerrainTab] of Word = (383, 388, 382, 385, 384);
  BtnHint: array [TKMTerrainTab] of Word = (
    TX_MAPED_TERRAIN_HINTS_BRUSHES,
    TX_MAPED_TERRAIN_HINTS_HEIGHTS,
    TX_MAPED_TERRAIN_HINTS_TILES,
    TX_MAPED_TERRAIN_HINTS_OBJECTS,
    TX_MAPED_COPY_TITLE);

  TB_PAD_TERRAIN_BTN_L = 9;

var
  I: TKMTerrainTab;
begin
  inherited Create;

  fOnPageChange := aOnPageChange;

  Panel_Terrain := TKMPanel.Create(aParent, 0, 45, TB_MAP_ED_WIDTH, 50);
    for I := Low(TKMTerrainTab) to High(TKMTerrainTab) do
    begin
      Button_Terrain[I] := TKMButton.Create(Panel_Terrain, TB_PAD_TERRAIN_BTN_L + SMALL_PAD_W * Byte(I), 0, SMALL_TAB_W, SMALL_TAB_H, BtnGlyph[I], rxGui, bsGame);
      Button_Terrain[I].Hint := GetHintWHotKey(BtnHint[I], MAPED_SUBMENU_HOTKEYS[Ord(I)]);
      Button_Terrain[I].OnClick := PageChange;
    end;

    Button_TerrainUndo := TKMButton.Create(Panel_Terrain, TB_PAD_TERRAIN_BTN_L + 151, 0, 15, SMALL_TAB_H, '<', bsGame);
    Button_TerrainUndo.Hint := gResTexts[TX_MAPED_UNDO_HINT]+ ' (''Ctrl+Z'')';
    Button_TerrainUndo.OnClick := UnRedoClick;
    Button_TerrainRedo := TKMButton.Create(Panel_Terrain, TB_PAD_TERRAIN_BTN_L + 166, 0, 15, SMALL_TAB_H, '>', bsGame);
    Button_TerrainRedo.Hint := gResTexts[TX_MAPED_REDO_HINT] + ' (''Ctrl+Y'' or ''Ctrl+Shift+Z'')';
    Button_TerrainRedo.OnClick := UnRedoClick;

    fGuiBrushes := TKMMapEdTerrainBrushes.Create(Panel_Terrain);
    fGuiHeights := TKMMapEdTerrainHeights.Create(Panel_Terrain);
    fGuiTiles := TKMMapEdTerrainTiles.Create(Panel_Terrain);
    fGuiObjects := TKMMapEdTerrainObjects.Create(Panel_Terrain, aHideAllPages);
    fGuiSelection := TKMMapEdTerrainSelection.Create(Panel_Terrain);
end;


destructor TKMMapEdTerrain.Destroy;
begin
  fGuiBrushes.Free;
  fGuiHeights.Free;
  fGuiTiles.Free;
  fGuiObjects.Free;
  fGuiSelection.Free;

  inherited;
end;


procedure TKMMapEdTerrain.KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);
begin
  fGuiBrushes.KeyDown(Key, Shift, aHandled);
  fGuiObjects.KeyDown(Key, Shift, aHandled);
end;


procedure TKMMapEdTerrain.KeyUp(Key: Word; Shift: TShiftState; var aHandled: Boolean);
begin
  if Visible then
  begin
    if (ssCtrl in Shift) and (Key = Ord('Y')) then
    begin
      Button_TerrainRedo.Click; //Ctrl+Y = Redo
      aHandled := True;
    end;
    if (ssCtrl in Shift) and (Key = Ord('Z')) then
    begin
      if ssShift in Shift then
        Button_TerrainRedo.Click //Ctrl+Shift+Z = Redo
      else
        Button_TerrainUndo.Click; //Ctrl+Z = Undo
      aHandled := True;
    end;
  end;
  fGuiObjects.KeyUp(Key, Shift, aHandled);
end;


procedure TKMMapEdTerrain.MouseWheel(Shift: TShiftState; WheelDelta, X, Y: Integer; var aHandled: Boolean);
begin
  fGuiBrushes.MouseWheel(Shift, WheelDelta, X, Y, aHandled);
  fGuiHeights.MouseWheel(Shift, WheelDelta, X, Y, aHandled);
end;


procedure TKMMapEdTerrain.PageChange(Sender: TObject);
begin
  //Reset cursor mode
  gGameCursor.Mode := cmNone;

  //Hide existing pages
  fGuiBrushes.Hide;
  fGuiHeights.Hide;
  fGuiTiles.Hide;
  fGuiObjects.Hide;
  fGuiSelection.Hide;

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
    fGuiSelection.Show;

  //Signal that active page has changed, that may affect layers visibility
  fOnPageChange(Self);
end;


procedure TKMMapEdTerrain.UnRedoClick(Sender: TObject);
begin
  if Sender = Button_TerrainUndo then
    gGame.MapEditor.TerrainPainter.Undo;

  if Sender = Button_TerrainRedo then
    gGame.MapEditor.TerrainPainter.Redo;

  Button_TerrainUndo.Enabled := gGame.MapEditor.TerrainPainter.CanUndo;
  Button_TerrainRedo.Enabled := gGame.MapEditor.TerrainPainter.CanRedo;
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


procedure TKMMapEdTerrain.DoExecuteSubMenuAction(aIndex: Byte);
begin
  inherited;

  fGuiBrushes.ExecuteSubMenuAction(aIndex);
  fGuiHeights.ExecuteSubMenuAction(aIndex);
  fGuiTiles.ExecuteSubMenuAction(aIndex);
  fGuiObjects.ExecuteSubMenuAction(aIndex);
  fGuiSelection.ExecuteSubMenuAction(aIndex);
end;


function TKMMapEdTerrain.Visible: Boolean;
begin
  Result := Panel_Terrain.Visible;
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
  end;
end;


procedure TKMMapEdTerrain.Resize;
begin
  fGuiObjects.Resize;
end;


procedure TKMMapEdTerrain.RightClickCancel;
begin
  fGuiObjects.RightClickCancel;
  fGuiBrushes.RightClickCancel;
end;


procedure TKMMapEdTerrain.UpdateState;
begin
  fGuiBrushes.UpdateState;
  fGuiTiles.UpdateState;
  fGuiObjects.UpdateState;
  fGuiSelection.UpdateState;

  Button_TerrainUndo.Enabled := gGame.MapEditor.TerrainPainter.CanUndo;
  Button_TerrainRedo.Enabled := gGame.MapEditor.TerrainPainter.CanRedo;
end;


end.
