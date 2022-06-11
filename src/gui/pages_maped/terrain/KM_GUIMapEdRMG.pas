unit KM_GUIMapEdRMG;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLType, {$ENDIF}
  Classes,
  Math, SysUtils,
  KM_Controls, KM_ControlsBase, KM_ControlsDrop, KM_ControlsEdit, KM_ControlsMinimapView, KM_ControlsSwitch, KM_ControlsTrackBar,
  KM_Defaults, KM_Pics, KM_Minimap,
  KM_RandomMapGenerator;

type
  TKMRMGCallback = procedure() of object;

  TKMMapEdRMG = class
  private
    fMPLobby: Boolean;
    fMapSizeIndicator: Boolean;
    fMinimap: TKMMinimap;
    fRMG: TKMRandomMapGenerator;
    fOnNewMap,fOnCloseGUI: TKMRMGCallback;

    procedure RMG_Change(Sender: TObject);
    procedure RMG_Close(Sender: TObject);
    procedure RMG_Generate_Map(Sender: TObject);
    procedure RMG_Generate_New_Seed(Sender: TObject);
    function GetVisible: Boolean;

    procedure PanelRMG_PositionChanged(Sender: TObject);
    procedure RefreshMinimap();
  protected
    Panel_RMG: TKMPanel;
    CheckGroup_Grass: TKMRadioGroup;
    CheckGroup_LocPosition: TKMRadioGroup;

    MinimapView: TKMMinimapView;

    Check_Biomes, Check_Ground,Check_Snow,Check_Sand,
    Check_Obstacles,
    Check_Locs, Check_Resources, Check_ConnectLocs, Check_MineFix,
    Check_Height, Check_HideNonSmoothTransition,
    Check_NoGo, Check_ReplaceTerrain,
    Check_Objects, Check_Animals: TKMCheckBox;

    TBar_Players, TBar_ProtectedRadius, TBar_Res_Stone, TBar_Res_Gold, TBar_Res_Iron,
    TBar_NonWalk_Size, TBar_NonWalk_Density, TBar_NonWalk_Variance, TBar_NonWalk_EGold, TBar_NonWalk_EIron, TBar_NonWalk_Swamp, TBar_NonWalk_Wetland, TBar_NonWalk_Water,
    TBar_Biomes1_Step, TBar_Biomes1_Limit, TBar_Biomes2_Step, TBar_Biomes2_Limit,
    TBar_HeightStep, TBar_HeightSlope, TBar_HeightSmoothPeaks, TBar_HeightHeight,
    TBar_ObjectDensity, TBar_Forests, TBar_Trees: TKMTrackBar;

    {$IFDEF DEBUG_RMG}
    Check_Decomposition,Check_BasicTiles,Check_CA: TKMCheckBox;
    {$ENDIF}

    DList_MapSize, DList_InitRes, DList_PreCfg: TKMDropList;
    Label_MapSize: TKMLabel;

    NumPlayers,NumSeed: TKMNumericEdit;

    Button_RMG_Generate_New_Seed: TKMButton;
    Button_RMG_Generate: TKMButton;
    Button_RMG_Close: TKMButton;
  public
    constructor Create(aParent: TKMPanel; aMinimap: TKMMinimap = nil; aMP: Boolean = False);
    destructor Destroy; override;

    property Visible: Boolean read GetVisible;
    property OnNewMap: TKMRMGCallback write fOnNewMap;
    property OnCloseGUI: TKMRMGCallback write fOnCloseGUI;
    procedure Show();
    procedure Hide();
  end;


implementation
uses
  KM_Game, KM_GameTypes,
  KM_Terrain,
  KM_RenderUI,
  KM_ResTexts, KM_ResFonts, KM_ResTypes;


{ TKMMapEdRMG }
constructor TKMMapEdRMG.Create(aParent: TKMPanel; aMinimap: TKMMinimap = nil; aMP: Boolean = False);
  procedure SetDebugSettings();
  begin
    // COLUMN 1: Locs + Resources
      Check_Locs.Checked := False;
      TBar_Players.Position := 1;
      TBar_ProtectedRadius.Position := 6;
      CheckGroup_LocPosition.ItemIndex := 0;
      Check_Resources.Checked := True;
        Check_ConnectLocs.Checked := True;
        Check_MineFix.Checked := True;
        TBar_Res_Stone.Position := 1000;
        TBar_Res_Gold.Position := 0;
        TBar_Res_Iron.Position := 0;

    // COLUMN 2: NonWalk textures column
      Check_Obstacles.Checked := False;
      TBar_NonWalk_Size.Position := 20;
      TBar_NonWalk_Density.Position := 10;
      TBar_NonWalk_Variance.Position := 10;
      // Ratio of biomes
      TBar_NonWalk_EGold.Position := 8;
      TBar_NonWalk_EIron.Position := 7;
      TBar_NonWalk_Swamp.Position := 0;
      TBar_NonWalk_Wetland.Position := 0;
      TBar_NonWalk_Water.Position := 0;

    // COLUMN 3: Walk textures
      Check_Biomes.Checked := True;
      Check_Ground.Checked := True;
      Check_Snow.Checked := True;
      Check_Sand.Checked := True;
      // First Layer
      TBar_Biomes1_Step.Position := 5;
      TBar_Biomes1_Limit.Position := 6;
      // Second Layer
      TBar_Biomes2_Step.Position := 5;
      TBar_Biomes2_Limit.Position := 6;

    // COLUMN 4: Height
      Check_Height.Checked := True;
      TBar_HeightStep.Position := 4;
      TBar_HeightSlope.Position := 40;
      TBar_HeightHeight.Step := 10;
      Check_HideNonSmoothTransition.Checked := True;
    // COLUMN 4: One path fix (it gives no-walk object to islands and create only 1 walkable area - in KaM is possible to have max 255 separated areas and RMG sometimes makes more which cause crash of the game)
      Check_NoGo.Checked := True;
      Check_ReplaceTerrain.Checked := True;
    // COLUMN 4: Objects
      Check_Objects.Checked := False;
      Check_Animals.Checked := True;
      TBar_ObjectDensity.Position := 6;
      TBar_Forests.Position := 10;
      TBar_Trees.Position := 20;

    // COLUMN 4: Seed
      NumSeed.Value := 417;

    // DEBUG (COLUMN 4)
    {$IFDEF DEBUG_RMG}
      Check_Decomposition.Checked := False;
      Check_BasicTiles.Checked := False;
      Check_CA.Checked := True;
    {$ENDIF}
  end;

  function NextLine(var Line: Integer; const LINE_Y: Integer = 20): Integer;
  begin
    Line := Line + LINE_Y;
    Result := Line;
  end;

const
  OFFSET_1 = 10;
  OFFSET_2 = 20;
  OFFSET_Column = 9;
  WIDTH_Column = 195;
  WIDTH_TrackBar = WIDTH_Column - OFFSET_Column;
  Column_1_X = OFFSET_Column;
  Column_2_X = OFFSET_Column + Column_1_X + WIDTH_Column;
  Column_3_X = OFFSET_Column + Column_2_X + WIDTH_Column;
  Column_4_X = OFFSET_Column + Column_3_X + WIDTH_Column;
  Column_5_X = OFFSET_Column + Column_4_X + WIDTH_Column;
  // Background
  SIZE_Y = 560;
  // Boxes
  BOX_X = WIDTH_Column - OFFSET_Column;
  BOX_Y = 20; // LINE_HEIGHT
  PARAGRAPH_HEIGHT = 30;
  // Bevel
  INDENTATION_Bevel = 4;
  SIZE_Bevel_X = WIDTH_Column;
  SIZE_Bevel_Y = SIZE_Y - 140;
  // Resources
  STONE_MAX = 3000;
  GOLD_MAX = 1000;
  IRON_MAX = 1000;
var
  sizeX: Integer;
  img: TKMImage;
  columnX, columnY: Integer;
  panelSettings: TKMPanel;
  lab: TKMLabel;
begin
  inherited Create;

  sizeX := WIDTH_Column * (Byte(not aMP) + 4) + 50;

  fMPLobby := aMP;
  fMapSizeIndicator := False;
  fMinimap := aMinimap;
  fRMG := TKMRandomMapGenerator.Create;
  fOnNewMap := nil;

  Panel_RMG := TKMPanel.Create(aParent, 0, (aParent.Height - SIZE_Y) div 2, sizeX, SIZE_Y);
  Panel_RMG.AnchorsCenter;
  Panel_RMG.Hide;
  Panel_RMG.PanelHandleMouseWheelByDefault := False; //Allow to zoom in/out while RMG settings window is open
  Panel_RMG.OnPositionSet := PanelRMG_PositionChanged;
  PanelRMG_PositionChanged(nil);

  if aMP then
  begin
    TKMBevel.Create(Panel_RMG, -2000,  -2000, 5000, 5000);
    img := TKMImage.Create(Panel_RMG, -20, -50, sizeX+40, SIZE_Y+60, 15, rxGuiMain);
    img.ImageStretch;
  end
  else
    TKMBevel.Create(Panel_RMG, 0, -15, sizeX, SIZE_Y);
  // Bevel panels
  TKMBevel.Create(Panel_RMG, Column_1_X-INDENTATION_Bevel, 60, SIZE_Bevel_X, SIZE_Bevel_Y);
  TKMBevel.Create(Panel_RMG, Column_2_X-INDENTATION_Bevel, 60, SIZE_Bevel_X, SIZE_Bevel_Y);
  TKMBevel.Create(Panel_RMG, Column_3_X-INDENTATION_Bevel, 60, SIZE_Bevel_X, SIZE_Bevel_Y);
  if aMP then
  begin
    TKMBevel.Create(Panel_RMG, Column_4_X-INDENTATION_Bevel, 60, SIZE_Bevel_X, 220 - 80);
    TKMBevel.Create(Panel_RMG, Column_4_X-INDENTATION_Bevel, 60+220+30 - 80, SIZE_Bevel_X, 170 - 30);
  end
  else
  begin
    TKMBevel.Create(Panel_RMG, Column_4_X-INDENTATION_Bevel, 60, SIZE_Bevel_X, 220 + 40);
    TKMBevel.Create(Panel_RMG, Column_5_X-INDENTATION_Bevel, 60, SIZE_Bevel_X, 170);
  end;

// Title
  TKMLabel.Create(Panel_RMG, sizeX div 2, -10, gResTexts[TX_MAPED_RMG_SETTINGS_TITLE], fntOutline, taCenter);

// RMG panel
  panelSettings := TKMPanel.Create(Panel_RMG, 0,  40, sizeX, SIZE_Y - 40);

// COLUMN 1: Locs + Resources
  columnX := Column_1_X;
  columnY := 0;
  Check_Locs := TKMCheckBox.Create(panelSettings, columnX, NextLine(columnY, 0), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_LOCATIONS], fntMetal);
    Check_Locs.Checked := fRMG.RMGSettings.Locs.Active;
    Check_Locs.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_LOCATIONS_HINT];
    Check_Locs.Enabled := not aMP;
  // Locations
  lab := TKMLabel.Create(panelSettings, columnX, NextLine(columnY,PARAGRAPH_HEIGHT), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_NUMBER_OF_LOCATIONS], fntMetal, taLeft);
    lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_NUMBER_OF_LOCATIONS_HINT];
    TBar_Players := TKMTrackBar.Create(panelSettings, columnX, NextLine(columnY), WIDTH_TrackBar, 1, 12);
    TBar_Players.Position := fRMG.RMGSettings.Locs.Players;
    TBar_Players.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_NUMBER_OF_LOCATIONS_HINT];
  // Loc radius
  lab := TKMLabel.Create(panelSettings, columnX, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_PROTECTED_RADIUS], fntMetal, taLeft);
    lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_PROTECTED_RADIUS_HINT];
  TBar_ProtectedRadius := TKMTrackBar.Create(panelSettings, columnX, NextLine(columnY), WIDTH_TrackBar, 1+4*Ord(aMP), 10);
    TBar_ProtectedRadius.Position := fRMG.RMGSettings.Locs.ProtectedRadius;
    TBar_ProtectedRadius.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_PROTECTED_RADIUS_HINT];
  // Connect locs
  Check_ConnectLocs := TKMCheckBox.Create(panelSettings, columnX, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_CONNECT_LOCATIONS], fntMetal);
    Check_ConnectLocs.Checked := fRMG.RMGSettings.Locs.Resource.ConnectLocs;
    Check_ConnectLocs.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_CONNECT_LOCATIONS_HINT];
    Check_ConnectLocs.Enabled := not aMP;
    if aMP then Check_ConnectLocs.Hide;
  // Layout (Locs)
  lab := TKMLabel.Create(panelSettings, columnX, NextLine(columnY,PARAGRAPH_HEIGHT-20*Ord(aMP)), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_LAYOUT], fntMetal, taLeft);
    lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_LAYOUT_HINT];
    CheckGroup_LocPosition := TKMRadioGroup.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), BOX_X, 80 + 20*Ord(not aMP), fntMetal);
    CheckGroup_LocPosition.Add(gResTexts[TX_MAPED_RMG_SETTINGS_RECTANGLE], True);
    CheckGroup_LocPosition.Add(gResTexts[TX_MAPED_RMG_SETTINGS_VERTICAL], True);
    CheckGroup_LocPosition.Add(gResTexts[TX_MAPED_RMG_SETTINGS_HORIZONTAL], True);
    CheckGroup_LocPosition.Add(gResTexts[TX_MAPED_RMG_SETTINGS_RANDOM], True);
    if not aMP then
      CheckGroup_LocPosition.Add(gResTexts[TX_MAPED_RMG_SETTINGS_CENTER_SCREEN], True);
    CheckGroup_LocPosition.ItemIndex := fRMG.RMGSettings.Locs.Layout;
    CheckGroup_LocPosition.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_LAYOUT_HINT];
  NextLine(columnY, 60 + 20 * Ord(not aMP));
  // Resources
  Check_Resources := TKMCheckBox.Create(panelSettings, columnX, NextLine(columnY,PARAGRAPH_HEIGHT), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_RESOURCES], fntMetal);
    Check_Resources.Checked := fRMG.RMGSettings.Locs.Resource.Active;
    Check_Resources.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_RESOURCES_HINT];
    Check_Resources.Enabled := not aMP;
    // Mine fix
    Check_MineFix := TKMCheckBox.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_MINE_FIX], fntMetal);
      Check_MineFix.Checked := fRMG.RMGSettings.Locs.Resource.MineFix;
      Check_MineFix.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_MINE_FIX_HINT];
      Check_MineFix.Enabled := not aMP;
      if aMP then begin Check_MineFix.Hide; NextLine(columnY,-20) end;
    // Stones
    lab := TKMLabel.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_RESOURCES_STONES], fntMetal, taLeft);
      lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_STONE_HINT];
      TBar_Res_Stone := TKMTrackBar.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), WIDTH_TrackBar-OFFSET_1, 0+200*Ord(aMP), STONE_MAX);
      TBar_Res_Stone.Position := fRMG.RMGSettings.Locs.Resource.Stone;
      TBar_Res_Stone.Step := 200;
      TBar_Res_Stone.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_STONE_HINT];
    // Gold
    lab := TKMLabel.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_RESOURCES_GOLD], fntMetal, taLeft);
      lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_GOLD_HINT];
      TBar_Res_Gold := TKMTrackBar.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), WIDTH_TrackBar-OFFSET_1, 0, GOLD_MAX);
      TBar_Res_Gold.Position := fRMG.RMGSettings.Locs.Resource.Gold;
      TBar_Res_Gold.Step := 50;
      TBar_Res_Gold.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_GOLD_HINT];
    // Iron
    lab := TKMLabel.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_RESOURCES_IRON], fntMetal, taLeft);
      lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_IRON_HINT];
      TBar_Res_Iron := TKMTrackBar.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), WIDTH_TrackBar-OFFSET_1, 0, IRON_MAX);
      TBar_Res_Iron.Position := fRMG.RMGSettings.Locs.Resource.Iron;
      TBar_Res_Iron.Step := 50;
      TBar_Res_Iron.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_IRON_HINT];
  // Preselection of initial resources
    lab := TKMLabel.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_INITIAL_RESOURCES], fntMetal, taLeft);
      lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_INITIAL_RESOURCES_HINT];
      if not aMP then begin lab.Hide; NextLine(columnY,-20) end;
    DList_InitRes := TKMDropList.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), BOX_X-OFFSET_1, BOX_Y, fntMetal, '', bsMenu);
      DList_InitRes.Add(gResTexts[TX_MAPED_RMG_SETTINGS_LOW], 0);
      DList_InitRes.Add(gResTexts[TX_MAPED_RMG_SETTINGS_MEDIUM], 1);
      DList_InitRes.Add(gResTexts[TX_MAPED_RMG_SETTINGS_HIGH], 2);
      DList_InitRes.ItemIndex := 0;
      DList_InitRes.Enabled := aMP;
      DList_InitRes.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_INITIAL_RESOURCES_HINT];
      if not aMP then begin DList_InitRes.Hide; NextLine(columnY,-20) end;


// COLUMN 2: NonWalk textures column
  columnX := Column_2_X;
  columnY := 0;
  Check_Obstacles := TKMCheckBox.Create(panelSettings, columnX, NextLine(columnY,0), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_OBSTACLES], fntMetal);
    Check_Obstacles.Checked := fRMG.RMGSettings.Obstacle.Active;
    Check_Obstacles.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_OBSTACLES_HINT];
    Check_Obstacles.Enabled := not aMP;
  // Size
  lab := TKMLabel.Create(panelSettings, columnX, NextLine(columnY,PARAGRAPH_HEIGHT), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_SIZE], fntMetal, taLeft);
    lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_SIZE_HINT];
    TBar_NonWalk_Size := TKMTrackBar.Create(panelSettings, columnX, NextLine(columnY), WIDTH_TrackBar, 1, 20);
    TBar_NonWalk_Size.Position := fRMG.RMGSettings.Obstacle.Size;
    TBar_NonWalk_Size.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_SIZE_HINT];
  // Density
  lab := TKMLabel.Create(panelSettings, columnX, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_DENSITY], fntMetal, taLeft);
    lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_DENSITY_HINT];
    TBar_NonWalk_Density := TKMTrackBar.Create(panelSettings, columnX, NextLine(columnY), WIDTH_TrackBar, 1, 20);
    TBar_NonWalk_Density.Position := fRMG.RMGSettings.Obstacle.Density;
    TBar_NonWalk_Density.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_DENSITY_HINT];
  // Variance
  lab := TKMLabel.Create(panelSettings, columnX, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_VARIANCE], fntMetal, taLeft);
    lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_VARIANCE_HINT];
    TBar_NonWalk_Variance := TKMTrackBar.Create(panelSettings, columnX, NextLine(columnY), WIDTH_TrackBar, 1, 10);
    TBar_NonWalk_Variance.Position := fRMG.RMGSettings.Obstacle.Variance;
    TBar_NonWalk_Variance.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_VARIANCE_HINT];
  // Ratio of biomes
  lab := TKMLabel.Create(panelSettings, columnX, NextLine(columnY,PARAGRAPH_HEIGHT), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_RATIO], fntMetal, taLeft);
  lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_RATIO_HINT];
  lab := TKMLabel.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_EMPTY_GOLD], fntMetal, taLeft);
    lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_EMPTY_GOLD_HINT];
    TBar_NonWalk_EGold := TKMTrackBar.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), WIDTH_TrackBar-OFFSET_1, 0, 10);
    TBar_NonWalk_EGold.Position := fRMG.RMGSettings.Obstacle.Ratio[otEgold];
    TBar_NonWalk_EGold.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_EMPTY_GOLD_HINT];
  lab := TKMLabel.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_EMPTY_IRON], fntMetal, taLeft);
    lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_EMPTY_IRON_HINT];
    TBar_NonWalk_EIron := TKMTrackBar.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), WIDTH_TrackBar-OFFSET_1, 0, 10);
    TBar_NonWalk_EIron.Position := fRMG.RMGSettings.Obstacle.Ratio[otEIron];
    TBar_NonWalk_EIron.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_EMPTY_IRON_HINT];
  lab := TKMLabel.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_SWAMP], fntMetal, taLeft);
    lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_SWAMP_HINT];
    TBar_NonWalk_Swamp := TKMTrackBar.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), WIDTH_TrackBar-OFFSET_1, 0, 10);
    TBar_NonWalk_Swamp.Position := fRMG.RMGSettings.Obstacle.Ratio[otSwamp];
    TBar_NonWalk_Swamp.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_SWAMP_HINT];
  lab := TKMLabel.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_WETLAND], fntMetal, taLeft);
    lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_WETLAND_HINT];
    TBar_NonWalk_Wetland := TKMTrackBar.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), WIDTH_TrackBar-OFFSET_1, 0, 10);
    TBar_NonWalk_Wetland.Position := fRMG.RMGSettings.Obstacle.Ratio[otWetland];
    TBar_NonWalk_Wetland.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_WETLAND_HINT];
  lab := TKMLabel.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_WATER], fntMetal, taLeft);
    lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_WATER_HINT];
    TBar_NonWalk_Water := TKMTrackBar.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), WIDTH_TrackBar-OFFSET_1, 0, 10);
    TBar_NonWalk_Water.Position := fRMG.RMGSettings.Obstacle.Ratio[otWater];
    TBar_NonWalk_Water.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_WATER_HINT];


// COLUMN 3: Walk textures
  columnX := Column_3_X;
  columnY := 0;
  Check_Biomes := TKMCheckBox.Create(panelSettings, columnX, NextLine(columnY,0), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_BIOMES], fntMetal);
    Check_Biomes.Checked := fRMG.RMGSettings.Walkable.Active;
    Check_Biomes.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_BIOMES_HINT];
    Check_Biomes.Enabled := not aMP;
  lab := TKMLabel.Create(panelSettings, columnX, NextLine(columnY,PARAGRAPH_HEIGHT), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_TYPE_OF_BIOME], fntMetal, taLeft);
    lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_TYPE_OF_BIOME_HINT];
    CheckGroup_Grass := TKMRadioGroup.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), BOX_X, BOX_Y, fntMetal);
      CheckGroup_Grass.Add(gResTexts[TX_MAPED_RMG_SETTINGS_GRASS],False); // Just for information purposes (grass must be there always)
      CheckGroup_Grass.ItemIndex := 0;
      CheckGroup_Grass.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_GRASS_HINT];
    Check_Ground := TKMCheckBox.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_GROUND], fntMetal);
      Check_Ground.Checked := fRMG.RMGSettings.Walkable.Ground;
      Check_Ground.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_GROUND_HINT];
    Check_Snow := TKMCheckBox.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_SNOW], fntMetal);
      Check_Snow.Checked := fRMG.RMGSettings.Walkable.Snow;
      Check_Snow.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_SNOW_HINT];
    Check_Sand := TKMCheckBox.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_SAND], fntMetal);
      Check_Sand.Checked := fRMG.RMGSettings.Walkable.Sand;
      Check_Sand.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_SAND_HINT];
  // First Layer
  lab := TKMLabel.Create(panelSettings, columnX, NextLine(columnY,PARAGRAPH_HEIGHT), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_FIRST_LAYER], fntMetal, taLeft);
    lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_FIRST_LAYER_HINT];
    lab := TKMLabel.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_STEP], fntMetal, taLeft);
      lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_STEP_PRIM_HINT];
      TBar_Biomes1_Step := TKMTrackBar.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), WIDTH_TrackBar-OFFSET_1, 1, 10);
      TBar_Biomes1_Step.Position := fRMG.RMGSettings.Walkable.FirstLayerStep;
      TBar_Biomes1_Step.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_STEP_PRIM_HINT];
    lab := TKMLabel.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_LIMIT], fntMetal, taLeft);
      lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_LIMIT_HINT];
      TBar_Biomes1_Limit := TKMTrackBar.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), WIDTH_TrackBar-OFFSET_1, 1, 10);
      TBar_Biomes1_Limit.Position := fRMG.RMGSettings.Walkable.FirstLayerLimit;
      TBar_Biomes1_Limit.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_LIMIT_HINT];
  // Second Layer
  lab := TKMLabel.Create(panelSettings, columnX, NextLine(columnY,PARAGRAPH_HEIGHT), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_SECOND_LAYER], fntMetal, taLeft);
    lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_SECOND_LAYER_HINT];
    lab := TKMLabel.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_STEP], fntMetal, taLeft);
      lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_STEP_SEC_HINT];
      TBar_Biomes2_Step := TKMTrackBar.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), WIDTH_TrackBar-OFFSET_1, 3, 10);
      TBar_Biomes2_Step.Position := fRMG.RMGSettings.Walkable.SecondLayerStep;
      TBar_Biomes2_Step.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_STEP_SEC_HINT];
    lab := TKMLabel.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_LIMIT], fntMetal, taLeft);
      lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_LIMIT_HINT];
      TBar_Biomes2_Limit := TKMTrackBar.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), WIDTH_TrackBar-OFFSET_1, 1, 10);
      TBar_Biomes2_Limit.Position := fRMG.RMGSettings.Walkable.SecondLayerLimit;
      TBar_Biomes2_Limit.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_LIMIT_HINT];

// DEBUG (COLUMN 3)
  {$IFDEF DEBUG_RMG}
    Check_Decomposition := TKMCheckBox.Create(Panel_Settings, Column_X, NextLine(Column_Y,40), BOX_X, BOX_Y, 'Decomposition', fntMetal);
    Check_Decomposition.Checked := fRMG.RMGSettings.Decomposition;
    Check_Decomposition.Enabled := not aMP;
    Check_BasicTiles := TKMCheckBox.Create(Panel_Settings, Column_X, NextLine(Column_Y,40), BOX_X, BOX_Y, 'Basic tiles', fntMetal);
    Check_BasicTiles.Checked := fRMG.RMGSettings.BasicTiles;
    Check_BasicTiles.Enabled := not aMP;
    Check_CA := TKMCheckBox.Create(Panel_Settings, Column_X, NextLine(Column_Y), BOX_X, BOX_Y, 'Cellular automaton', fntMetal);
    Check_CA.Checked := fRMG.RMGSettings.CA;
    Check_CA.Enabled := not aMP;
  {$ENDIF}


// COLUMN 4: Height
  columnX := Column_4_X;
  columnY := 0;
  Check_Height := TKMCheckBox.Create(panelSettings, columnX, NextLine(columnY,0), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_HEIGHT], fntMetal);
    Check_Height.Checked := fRMG.RMGSettings.Height.Active;
    Check_Height.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_HEIGHT_HINT];
    Check_Height.Enabled := not aMP;
  // Hide jagged edges
  Check_HideNonSmoothTransition := TKMCheckBox.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY,PARAGRAPH_HEIGHT), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_HIDE_ROUGHT_TRANSITIONS], fntMetal);
    Check_HideNonSmoothTransition.Checked := fRMG.RMGSettings.Height.HideNonSmoothTransition;
    Check_HideNonSmoothTransition.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_HIDE_ROUGHT_TRANSITIONS_HINT];
    if aMP then begin Check_HideNonSmoothTransition.Hide; NextLine(columnY,-20) end;
  // Step
  lab := TKMLabel.Create(panelSettings, columnX, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_STEP], fntMetal, taLeft);
    lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_HEIGHT_STEP_HINT];
  TBar_HeightStep := TKMTrackBar.Create(panelSettings, columnX, NextLine(columnY), WIDTH_TrackBar, 1, 7-2*Ord(aMP));
    TBar_HeightStep.Position := fRMG.RMGSettings.Height.Step;
    TBar_HeightStep.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_HEIGHT_STEP_HINT];
  // Slope
  lab := TKMLabel.Create(panelSettings, columnX, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_TERRAIN_HEIGHTS_SLOPE], fntMetal, taLeft);
    lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_HEIGHT_SLOPE_HINT];
  TBar_HeightSlope := TKMTrackBar.Create(panelSettings, columnX, NextLine(columnY), WIDTH_TrackBar, 0, 100-50*Ord(aMP));
    TBar_HeightSlope.Position := fRMG.RMGSettings.Height.Slope;
    TBar_HeightSlope.Step := 10;
    TBar_HeightSlope.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_HEIGHT_SLOPE_HINT];
  // SmoothOutMountainPeaks
  lab := TKMLabel.Create(panelSettings, columnX, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_HEIGHT_SMOOTH_PEAKS], fntMetal, taLeft);
    lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_HEIGHT_SMOOTH_PEAKS_HINT];
  TBar_HeightSmoothPeaks := TKMTrackBar.Create(panelSettings, columnX, NextLine(columnY), WIDTH_TrackBar, 1, 9);
    TBar_HeightSmoothPeaks.Position := fRMG.RMGSettings.Height.SmoothOutMountainPeaks;
    TBar_HeightSmoothPeaks.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_HEIGHT_SMOOTH_PEAKS_HINT];
  if aMP then
  begin
    lab.Hide;
    TBar_HeightSmoothPeaks.Hide;
    NextLine(columnY,-40);
  end;
  // Height
  lab := TKMLabel.Create(panelSettings, columnX, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_TERRAIN_HEIGHTS], fntMetal, taLeft);
    lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_HEIGHT_HEIGHTS_HINT];
  TBar_HeightHeight := TKMTrackBar.Create(panelSettings, columnX, NextLine(columnY), WIDTH_TrackBar, 0, 100-30*Ord(aMP));
    TBar_HeightHeight.Position := fRMG.RMGSettings.Height.Height;
    TBar_HeightHeight.Step := 10;
    TBar_HeightHeight.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_HEIGHT_HEIGHTS_HINT];
  // One path fix (it gives no-walk object to islands and create only 1 walkable area - in KaM is possible to have max 255 separated areas and RMG sometimes makes more which cause crash of the game)
  lab := TKMLabel.Create(panelSettings, columnX, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_INACCESIBLE_PLACES], fntMetal, taLeft);
    lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_INACCESIBLE_PLACES_HINT];
    if aMP then begin lab.Hide; NextLine(columnY,-20) end;
    Check_NoGo := TKMCheckBox.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_BLOCK_WALKING], fntMetal);
    Check_NoGo.Checked := fRMG.RMGSettings.OnePath.NoGoZones;
    Check_NoGo.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_BLOCK_WALKING_HINT];
    if aMP then begin Check_NoGo.Hide; NextLine(columnY,-20) end;
    Check_ReplaceTerrain := TKMCheckBox.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_CHANGE_TEXTURE], fntMetal);
    Check_ReplaceTerrain.Checked := fRMG.RMGSettings.OnePath.ReplaceTerrain;
    Check_ReplaceTerrain.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_CHANGE_TEXTURE_HINT];
    if aMP then begin Check_ReplaceTerrain.Hide; NextLine(columnY,-20) end;

// COLUMN 4-5: Objects
  if not aMP then
  begin
    columnX := Column_5_X;
    columnY := 0;
  end;

  Check_Objects := TKMCheckBox.Create(panelSettings, columnX, NextLine(columnY,Byte(aMP)*40), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_OBJECTS], fntMetal);
    Check_Objects.Checked := fRMG.RMGSettings.Objects.Active;
    Check_Objects.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_OBJECTS_HINT];
    Check_Objects.Enabled := not aMP;
  // Animals
  Check_Animals := TKMCheckBox.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY,PARAGRAPH_HEIGHT), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_ANIMALS], fntMetal);
    Check_Animals.Checked := fRMG.RMGSettings.Objects.Animals;
    Check_Animals.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_ANIMALS_HINT];
    if aMP then begin Check_Animals.Hide; NextLine(columnY,-20) end;
  // Object density
  lab := TKMLabel.Create(panelSettings, columnX, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_DENSITY], fntMetal, taLeft);
    lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_OBJECTS_DENSITY_HINT];
    TBar_ObjectDensity := TKMTrackBar.Create(panelSettings, columnX, NextLine(columnY), WIDTH_TrackBar, 0, 10);
    TBar_ObjectDensity.Position := fRMG.RMGSettings.Objects.ObjectDensity;
    TBar_ObjectDensity.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_OBJECTS_DENSITY_HINT];
  // Forests
  lab := TKMLabel.Create(panelSettings, columnX, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_FORESTS_DENSITY], fntMetal, taLeft);
    lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_FORESTS_DENSITY_HINT];
    TBar_Forests := TKMTrackBar.Create(panelSettings, columnX, NextLine(columnY), WIDTH_TrackBar, 0, 10 - Ord(aMP) * 2);
    TBar_Forests.Position := fRMG.RMGSettings.Objects.ForestDensity;
    TBar_Forests.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_FORESTS_DENSITY_HINT];
  // Trees in forest
  lab := TKMLabel.Create(panelSettings, columnX, NextLine(columnY), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_TREES], fntMetal, taLeft);
    lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_TREES_HINT];
    TBar_Trees := TKMTrackBar.Create(panelSettings, columnX, NextLine(columnY), WIDTH_TrackBar, 1, 30);
    TBar_Trees.Position := fRMG.RMGSettings.Objects.Trees;
    TBar_Trees.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_TREES_HINT];

  if aMP then
  begin
    MinimapView := TKMMinimapView.Create(fMinimap, panelSettings, columnX, NextLine(columnY,30), 192, 132, True);
    MinimapView.ShowLocs := True; //In the minimap we want player locations to be shown
    MinimapView.Show;
  end;

// Map size
  columnX := Column_1_X;
  columnY := SIZE_Y - 100;
  lab := TKMLabel.Create(panelSettings, columnX, NextLine(columnY,0), gResTexts[TX_MAPED_RMG_SETTINGS_MAP_SIZE], fntMetal, taLeft);
  lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_MAP_SIZE];
  if aMP then
  begin
    Label_MapSize := nil;
    DList_MapSize := TKMDropList.Create(panelSettings, columnX, NextLine(columnY,15), 100, BOX_Y, fntMetal, '', bsMenu);
      DList_MapSize.Add('128x128', 0);
      DList_MapSize.Add('160x160', 1);
      DList_MapSize.Add('192x192', 2);
      DList_MapSize.Add('224x224', 3);
      DList_MapSize.Add('256x256', 4);
      DList_MapSize.ItemIndex := 2;
      DList_MapSize.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_MAP_SIZE_HINT];
  end
  else
  begin
    DList_MapSize := nil;
    TKMBevel.Create(panelSettings, columnX, columnY+15, 100, 20);
    Label_MapSize := TKMLabel.Create(panelSettings, columnX+OFFSET_1, NextLine(columnY), BOX_X, BOX_Y, ' ', fntMetal, taLeft);
  end;


// Seed
  columnX := Column_1_X + 110;
  columnY := SIZE_Y - 100;
	lab := TKMLabel.Create(panelSettings, columnX, NextLine(columnY,0), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_SEED], fntMetal, taLeft);
    lab.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_SEED_HINT];
  NumSeed := TKMNumericEdit.Create(panelSettings, columnX, NextLine(columnY,15), Low( Integer ), High( Integer ));
    NumSeed.OnChange := RMG_Change;
    NumSeed.Value := Random( High(Integer) );
    NumSeed.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_SEED_HINT];
    NumSeed.AutoFocusable := False;


// Preselection of configuration
  {
  Column_X := Column_1_X + 370;
  Column_Y := SIZE_Y - 100;
	Lab := TKMLabel.Create(Panel_Settings, Column_X, NextLine(Column_Y,0), BOX_X, BOX_Y, 'Load', fntMetal, taLeft);
    Lab.Hint := 'Load configuration';
  DList_PreCfg := TKMDropList.Create(Panel_Settings, Column_X, NextLine(Column_Y,15), 130, BOX_Y, fntMetal, '', bsMenu);
  //DList_PreCfg.Add('Cfg 1', 0);
  DList_PreCfg.ItemIndex := 0;
  //DList_PreCfg.Enabled := aMP;
  DList_PreCfg.Enabled := False;
  }


// Buttons
  columnX := sizeX - 160;// - 215 * Ord(aMP);
  columnY := SIZE_Y - 50;
  Button_RMG_Generate_New_Seed := TKMButton.Create(Panel_RMG, columnX-320-60, columnY, 200, 30, gResTexts[TX_MAPED_RMG_SETTINGS_NEW_RANDOM_SEED], bsMenu);
  Button_RMG_Generate_New_Seed.OnClick := RMG_Generate_New_Seed;
  Button_RMG_Generate_New_Seed.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_NEW_RANDOM_SEED_HINT];
  //if aMP then Button_RMG_Generate_New_Seed.Hide;
  Button_RMG_Generate := TKMButton.Create(Panel_RMG, columnX-160-10, columnY, 160, 30, gResTexts[TX_MAPED_RMG_SETTINGS_GENERATE_MAP], bsMenu);
  Button_RMG_Generate.OnClick := RMG_Generate_Map;
  Button_RMG_Generate.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_GENERATE_MAP_HINT];
  Button_RMG_Close := TKMButton.Create(Panel_RMG, columnX, columnY, 150, 30, gResTexts[TX_MAPED_CLOSE], bsMenu);
  Button_RMG_Close.OnClick := RMG_Close;
  Button_RMG_Close.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_CLOSE_RMG_HINT];


  {$IFDEF DEBUG_RMG}
    //SetDebugSettings();
  {$ENDIF}
end;


destructor TKMMapEdRMG.Destroy;
begin
  FreeAndNil(fRMG);

  inherited;
end;


procedure TKMMapEdRMG.RMG_Change(Sender: TObject);
begin
  //Settings get saved on close, now we just toggle fields
  //because certain combinations can't coexist
  //NumSeed.Enabled := TGoalCondition(Radio_2.ItemIndex) <> gcTime;
end;


procedure TKMMapEdRMG.RMG_Generate_New_Seed(Sender: TObject);
begin
  //NumSeed.Value := Round(1000*KaMRandom('TKMMapEdRMG.RMG_Generate_New_Seed'));
  // PLEASE USE Random() function - this have no effect to game synchronization
  NumSeed.Value := Random( High(Integer) );
  RMG_Generate_Map(Sender);
end;


procedure TKMMapEdRMG.RMG_Generate_Map(Sender: TObject);
  procedure GetSettingsFromGUI();
  begin
    with fRMG.RMGSettings do
    begin
      with Locs do
      begin
        Active := Check_Locs.Checked;
        Players := TBar_Players.Position;
        Layout := CheckGroup_LocPosition.ItemIndex;
        ProtectedRadius := TBar_ProtectedRadius.Position;
        with Resource do
        begin
          Active := Check_Resources.Checked;
          ConnectLocs := Check_ConnectLocs.Checked;
          MineFix := Check_MineFix.Checked;
          Stone := TBar_Res_Stone.Position;
          Gold := TBar_Res_Gold.Position;
          Iron := TBar_Res_Iron.Position;
        end;
        if (DList_InitRes <> nil)
          and fMPLobby then
          InitialResources := DList_InitRes.ItemIndex;
      end;
      with Obstacle do
      begin
        Active := Check_Obstacles.Checked;
        Ratio[otEgold] := TBar_NonWalk_EGold.Position;
        Ratio[otEIron] := TBar_NonWalk_EIron.Position;
        Ratio[otSwamp] := TBar_NonWalk_Swamp.Position;
        Ratio[otWetland] := TBar_NonWalk_Wetland.Position;
        Ratio[otWater] := TBar_NonWalk_Water.Position;
        Density := TBar_NonWalk_Density.Position;
        Size := TBar_NonWalk_Size.Position;
        Variance := TBar_NonWalk_Variance.Position;
      end;
      with Walkable do
      begin
        Active := Check_Biomes.Checked;
        Grass := Boolean(CheckGroup_Grass.ItemIndex = 0);
        Ground := Check_Ground.Checked;
        Snow := Check_Snow.Checked;
        Sand := Check_Sand.Checked;
        FirstLayerStep := TBar_Biomes1_Step.Position;
        FirstLayerLimit := TBar_Biomes1_Limit.Position;
        SecondLayerStep := TBar_Biomes2_Step.Position;
        SecondLayerLimit := TBar_Biomes2_Limit.Position;
      end;
      with Height do
      begin
        Step := TBar_HeightStep.Position;
        Slope := TBar_HeightSlope.Position;
        SmoothOutMountainPeaks := TBar_HeightSmoothPeaks.Position;
        Height := TBar_HeightHeight.Position;
        Active := Check_Height.Checked;
        HideNonSmoothTransition := Check_HideNonSmoothTransition.Checked;
      end;
      with OnePath do
      begin
        NoGoZones := Check_NoGo.Checked;
        ReplaceTerrain := Check_ReplaceTerrain.Checked;
      end;
      with Objects do
      begin
        Active := Check_Objects.Checked;
        ObjectDensity := TBar_ObjectDensity.Position;
        ForestDensity := TBar_Forests.Position;
        Trees := TBar_Trees.Position;
        Animals := Check_Animals.Checked;
      end;
      Seed := NumSeed.Value;

      {$IFDEF DEBUG_RMG}
        Decomposition := Check_Decomposition.Checked;
        BasicTiles := Check_BasicTiles.Checked;
        CA := Check_CA.Checked;
      {$ELSE}
        Decomposition := False;
        BasicTiles := False;
        CA := True;
      {$ENDIF}
    end;
  end;
var
  mapX, mapY: Word;
begin
  if fMPLobby AND (gGame = nil) then
  begin
    // Create fake game
    gGame := TKMGame.Create(gmMapEd);
    try
      mapX := 192;
      mapY := 192;
      if (DList_MapSize <> nil) then
        case DList_MapSize.ItemIndex of
          0: begin mapX := 128; mapY := 128; end;
          1: begin mapX := 160; mapY := 160; end;
          2: begin mapX := 192; mapY := 192; end;
          3: begin mapX := 224; mapY := 224; end;
          4: begin mapX := 256; mapY := 256; end;
        end;
      // Create empty map in background
      gGame.MapEdStartEmptyMap(mapX, mapY);
      // Get RMG config
      GetSettingsFromGUI();
      // Call RMG
      fRMG.GenerateMap(True);
      // Save map
      gGame.SaveMapEditor(Format('%s\%s\%s\%s.dat',[ExtractFilePath(ParamStr(0)), MAPS_MP_FOLDER_NAME, MAPS_RMG_NAME, MAPS_RMG_NAME]));
    finally
      gGame.Free;
      gGame := nil;
      //FreeThenNil(gGame);
    end;
  end
  else if (gGame <> nil) then
  begin
    GetSettingsFromGUI();
    fRMG.GenerateMap(False);
  end;
  if Assigned(fOnNewMap) then
    fOnNewMap();
  RefreshMinimap();
end;


function TKMMapEdRMG.GetVisible: Boolean;
begin
  Result := Panel_RMG.Visible;
end;


procedure TKMMapEdRMG.RMG_Close(Sender: TObject);
begin
  Panel_RMG.Hide;
  if Assigned(fOnCloseGUI) then
    fOnCloseGUI();
end;


procedure TKMMapEdRMG.Hide();
begin
  Panel_RMG.Hide;
end;


procedure TKMMapEdRMG.Show();
begin
  Panel_RMG.Show;
  if not fMapSizeIndicator AND not fMPLobby AND (Label_MapSize <> nil) then
  begin
    fMapSizeIndicator := True;
    Label_MapSize.Caption := Format('%dx%d',[gTerrain.MapX,gTerrain.MapY]);
  end;
end;


procedure TKMMapEdRMG.RefreshMinimap();
begin
  if MinimapView = nil then Exit;

  MinimapView.Hide;
  if Assigned(fMinimap) then
  begin
    fMinimap.Update(True);
    MinimapView.Show;
  end;
end;


procedure TKMMapEdRMG.PanelRMG_PositionChanged(Sender: TObject);
var
  left, right: Integer;
begin
  left := (Panel_RMG.Parent.Width - Panel_RMG.Width) div 2;

  if not fMPLobby then
  begin
    left := Max(left, MAPED_TOOLBAR_WIDTH);
    right := Max(0, Panel_RMG.Parent.Width - left - Panel_RMG.Width);
    left := Panel_RMG.Parent.Width - right - Panel_RMG.Width;
  end;

  Panel_RMG.OnPositionSet := nil;

  Panel_RMG.Left := left;

  Panel_RMG.OnPositionSet := PanelRMG_PositionChanged;
end;


end.
