unit KM_GUIMapEdRMG;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLType, {$ENDIF}
  Classes,
  Math, SysUtils, KM_Utils,
  KM_Controls, KM_Defaults, KM_Pics,
  KM_RandomMapGenerator, KM_CommonUtils;

type

  TKMMapEdRMG = class
  private
    fMapSizeIndicator: Boolean;
    fRMG: TKMRandomMapGenerator;

    function NextLine(var Line: Integer; const LINE_Y: Byte = 20): Integer;
    procedure RMG_Change(Sender: TObject);
    procedure RMG_Close(Sender: TObject);
    procedure RMG_Generate_Map(Sender: TObject);
    procedure RMG_Generate_New_Seed(Sender: TObject);
    function GetVisible: Boolean;
  protected
    Panel_RMG: TKMPanel;
    CheckGroup_Grass: TKMRadioGroup;
    CheckGroup_LocPosition: TKMRadioGroup;

    Label_Locations, Label_LocRadius, Label_LocLayout,
    Label_Res_Stones, Label_Res_Gold, Label_Res_Iron,
    Label_NonWalk_Size, Label_NonWalk_Density, Label_NonWalk_Variance,
    Label_NonWalk_Ratio, Label_NonWalk_EGold, Label_NonWalk_EIron, Label_NonWalk_Swamp, Label_NonWalk_Wetland, Label_NonWalk_Water,
    Label_Biomes, Label_FirstLayer, Label_FirstLayer_Step, Label_FirstLayer_Limit, Label_SecondLayer, Label_SecondLayer_Step, Label_SecondLayer_Limit,
    Label_HeightStep, Label_HeightSlope, Label_HeightHeight, Label_InacessiblePlaces,
    Label_Density, Label_Forests, Label_Trees,
    Label_Seed, Label_MapSize: TKMLabel;

    Check_Biomes, Check_Ground,Check_Snow,Check_Sand,
    Check_Obstacles,
    Check_Locs, Check_Resources, Check_ConnectLocs, Check_MineFix,
    Check_Height, Check_HideNonSmoothTransition,
    Check_NoGo, Check_ReplaceTerrain,
    Check_Objects, Check_Animals: TKMCheckBox;

    TBar_Players, TBar_ProtectedRadius, TBar_Res_Stone, TBar_Res_Gold, TBar_Res_Iron,
    TBar_NonWalk_Size, TBar_NonWalk_Density, TBar_NonWalk_Variance, TBar_NonWalk_EGold, TBar_NonWalk_EIron, TBar_NonWalk_Swamp, TBar_NonWalk_Wetland, TBar_NonWalk_Water,
    TBar_Biomes1_Step, TBar_Biomes1_Limit, TBar_Biomes2_Step, TBar_Biomes2_Limit,
    TBar_HeightStep, TBar_HeightSlope, TBar_HeightHeight,
    TBar_Height1, TBar_Height2, TBar_Height3, TBar_Height4, TBar_ObjectDensity, TBar_Forests, TBar_Trees: TKMTrackBar;

    {$IFDEF DEBUG_RMG}
    Check_BasicTiles,Check_CA: TKMCheckBox;
    {$ENDIF}

    NumPlayers,NumSeed: TKMNumericEdit;

    Button_RMG_Generate_New_Seed: TKMButton;
    Button_RMG_Generate: TKMButton;
    Button_RMG_Cancel: TKMButton;
  public
    constructor Create(aParent: TKMPanel);
    destructor Destroy; override;

    property Visible: Boolean read GetVisible;
    procedure Show();
  end;



implementation
uses
  KM_HandsCollection, KM_ResTexts, KM_RenderUI, KM_ResFonts, KM_Hand,
  KM_TerrainSelection, KM_Terrain;


{ TKMGUIMapEdGoal }
constructor TKMMapEdRMG.Create(aParent: TKMPanel);
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
      Check_BasicTiles.Checked := False;
      Check_CA.Checked := True;
    {$ENDIF}
  end;
const
  OFFSET_1 = 10;
  OFFSET_2 = 20;
  OFFSET_Column = 10;
  WIDTH_Column = 200;
  WIDTH_TrackBar = WIDTH_Column - OFFSET_Column;
  Column_1_X = OFFSET_Column;
  Column_2_X = OFFSET_Column + Column_1_X + WIDTH_Column;
  Column_3_X = OFFSET_Column + Column_2_X + WIDTH_Column;
  Column_4_X = OFFSET_Column + Column_3_X + WIDTH_Column;
  // Background
  SIZE_X = WIDTH_Column * 4 + 40;
  SIZE_Y = 560;
  // Boxes
  BOX_X = WIDTH_Column - OFFSET_Column;
  BOX_Y = 20; // LINE_HEIGHT
  PARAGRAPH_HEIGHT = 30;
  // Bevel
  INDENTATION_Bevel = 5;
  SIZE_Bevel_X = WIDTH_Column;
  SIZE_Bevel_Y = SIZE_Y - 140;
var
  Img: TKMImage;
  Column_X,Column_Y: Integer;
  Panel_Settings: TKMPanel;
begin
  inherited Create;

  fRMG := TKMRandomMapGenerator.Create;
  fMapSizeIndicator := False;

  Panel_RMG := TKMPanel.Create(aParent, (aParent.Width - SIZE_X) div 2, (aParent.Height - SIZE_Y) div 2, SIZE_X, SIZE_Y);
  Panel_RMG.AnchorsCenter;
  Panel_RMG.Hide;
  Panel_RMG.PanelHandleMouseWheelByDefault := False; //Allow to zoom in/out while RMG settings window is open

  TKMBevel.Create(Panel_RMG, -1000,  -1000, 4000, 4000);
  Img := TKMImage.Create(Panel_RMG, -20, -50, SIZE_X+40, SIZE_Y+60, 15, rxGuiMain);
  Img.ImageStretch;
  // Bevel panels
  TKMBevel.Create(Panel_RMG, Column_1_X-INDENTATION_Bevel, 60, SIZE_Bevel_X, SIZE_Bevel_Y);
  TKMBevel.Create(Panel_RMG, Column_2_X-INDENTATION_Bevel, 60, SIZE_Bevel_X, SIZE_Bevel_Y);
  TKMBevel.Create(Panel_RMG, Column_3_X-INDENTATION_Bevel, 60, SIZE_Bevel_X, SIZE_Bevel_Y);
  TKMBevel.Create(Panel_RMG, Column_4_X-INDENTATION_Bevel, 60, SIZE_Bevel_X, 220);
  TKMBevel.Create(Panel_RMG, Column_4_X-INDENTATION_Bevel, 60+220+30, SIZE_Bevel_X, 170);

// Title
  TKMLabel.Create(Panel_RMG, SIZE_X div 2, -20, gResTexts[TX_MAPED_RMG_SETTINGS_TITLE], fntOutline, taCenter);


// RMG panel
  Panel_Settings := TKMPanel.Create(Panel_RMG, 0,  40, SIZE_X, SIZE_Y - 110);


// COLUMN 1: Locs + Resources
  Column_X := Column_1_X;
  Column_Y := 0;
  Check_Locs := TKMCheckBox.Create(Panel_Settings, Column_X, NextLine(Column_Y, 0), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_LOCATIONS], fntMetal);
    Check_Locs.Checked := True;
    Check_Locs.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_LOCATIONS_HINT];
  // Locations
  Label_Locations := TKMLabel.Create(Panel_Settings, Column_X, NextLine(Column_Y,PARAGRAPH_HEIGHT), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_NUMBER_OF_LOCATIONS], fntMetal, taLeft);
    Label_Locations.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_NUMBER_OF_LOCATIONS_HINT];
    TBar_Players := TKMTrackBar.Create(Panel_Settings, Column_X, NextLine(Column_Y), WIDTH_TrackBar, 1, 12);
    TBar_Players.Position := 4;
    TBar_Players.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_NUMBER_OF_LOCATIONS_HINT];
  // Loc radius
  Label_LocRadius := TKMLabel.Create(Panel_Settings, Column_X, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_PROTECTED_RADIUS], fntMetal, taLeft);
    Label_LocRadius.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_PROTECTED_RADIUS_HINT];
  TBar_ProtectedRadius := TKMTrackBar.Create(Panel_Settings, Column_X, NextLine(Column_Y), WIDTH_TrackBar, 1, 10);
    TBar_ProtectedRadius.Position := 6;
    TBar_ProtectedRadius.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_PROTECTED_RADIUS_HINT];
  // Connect locs
  Check_ConnectLocs := TKMCheckBox.Create(Panel_Settings, Column_X, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_CONNECT_LOCATIONS], fntMetal);
    Check_ConnectLocs.Checked := True;
    Check_ConnectLocs.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_CONNECT_LOCATIONS_HINT];
  // Layout (Locs)
  Label_LocLayout := TKMLabel.Create(Panel_Settings, Column_X, NextLine(Column_Y,PARAGRAPH_HEIGHT), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_LAYOUT], fntMetal, taLeft);
    Label_LocLayout.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_LAYOUT_HINT];
    CheckGroup_LocPosition := TKMRadioGroup.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), BOX_X, 100, fntMetal);
    CheckGroup_LocPosition.Add(gResTexts[TX_MAPED_RMG_SETTINGS_RECTANGLE], True);
    CheckGroup_LocPosition.Add(gResTexts[TX_MAPED_RMG_SETTINGS_VERTICAL], True);
    CheckGroup_LocPosition.Add(gResTexts[TX_MAPED_RMG_SETTINGS_HORISONTAL], True);
    CheckGroup_LocPosition.Add(gResTexts[TX_MAPED_RMG_SETTINGS_RANDOM], True);
    CheckGroup_LocPosition.Add(gResTexts[TX_MAPED_RMG_SETTINGS_CENTER_SCREEN], True);
    CheckGroup_LocPosition.ItemIndex := 0;
    CheckGroup_LocPosition.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_LAYOUT_HINT];
  NextLine(Column_Y,80);
  // Resources
  Check_Resources := TKMCheckBox.Create(Panel_Settings, Column_X, NextLine(Column_Y,PARAGRAPH_HEIGHT), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_RESOURCES], fntMetal);
    Check_Resources.Checked := True;
    Check_Resources.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_RESOURCES_HINT];
    // Mine fix
    Check_MineFix := TKMCheckBox.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_MINE_FIX], fntMetal);
      Check_MineFix.Checked := True;
      Check_MineFix.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_MINE_FIX_HINT];
    // Stones
    Label_Res_Stones := TKMLabel.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_RESOURCES_STONES], fntMetal, taLeft);
      Label_Res_Stones.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_STONE_HINT];
      TBar_Res_Stone := TKMTrackBar.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), WIDTH_TrackBar-OFFSET_1, 0, 2000);
      TBar_Res_Stone.Position := 1000;
      TBar_Res_Stone.Step := 200;
      TBar_Res_Stone.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_STONE_HINT];
    // Gold
    Label_Res_Gold := TKMLabel.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_RESOURCES_GOLD], fntMetal, taLeft);
      Label_Res_Gold.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_GOLD_HINT];
      TBar_Res_Gold := TKMTrackBar.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), WIDTH_TrackBar-OFFSET_1, 0, 500);
      TBar_Res_Gold.Position := 300;
      TBar_Res_Gold.Step := 50;
      TBar_Res_Gold.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_GOLD_HINT];
    // Iron
    Label_Res_Iron := TKMLabel.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_RESOURCES_IRON], fntMetal, taLeft);
      Label_Res_Iron.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_IRON_HINT];
      TBar_Res_Iron := TKMTrackBar.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), WIDTH_TrackBar-OFFSET_1, 0, 500);
      TBar_Res_Iron.Position := 250;
      TBar_Res_Iron.Step := 50;
      TBar_Res_Iron.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_IRON_HINT];


// COLUMN 2: NonWalk textures column
  Column_X := Column_2_X;
  Column_Y := 0;
  Check_Obstacles := TKMCheckBox.Create(Panel_Settings, Column_X, NextLine(Column_Y,0), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_OBSTACLES], fntMetal);
    Check_Obstacles.Checked := True;
    Check_Obstacles.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_OBSTACLES_HINT];
  // Size
  Label_NonWalk_Size := TKMLabel.Create(Panel_Settings, Column_X, NextLine(Column_Y,PARAGRAPH_HEIGHT), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_SIZE], fntMetal, taLeft);
    Label_NonWalk_Size.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_SIZE_HINT];
    TBar_NonWalk_Size := TKMTrackBar.Create(Panel_Settings, Column_X, NextLine(Column_Y), WIDTH_TrackBar, 1, 20);
    TBar_NonWalk_Size.Position := 10;
    TBar_NonWalk_Size.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_SIZE_HINT];
  // Density
  Label_NonWalk_Density := TKMLabel.Create(Panel_Settings, Column_X, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_DENSITY], fntMetal, taLeft);
    Label_NonWalk_Density.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_DENSITY_HINT];
    TBar_NonWalk_Density := TKMTrackBar.Create(Panel_Settings, Column_X, NextLine(Column_Y), WIDTH_TrackBar, 1, 20);
    TBar_NonWalk_Density.Position := 8;
    TBar_NonWalk_Density.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_DENSITY_HINT];
  // Variance
  Label_NonWalk_Variance := TKMLabel.Create(Panel_Settings, Column_X, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_VARIANCE], fntMetal, taLeft);
    Label_NonWalk_Variance.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_VARIANCE_HINT];
    TBar_NonWalk_Variance := TKMTrackBar.Create(Panel_Settings, Column_X, NextLine(Column_Y), WIDTH_TrackBar, 1, 10);
    TBar_NonWalk_Variance.Position := 5;
    TBar_NonWalk_Variance.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_VARIANCE_HINT];
  // Ratio of biomes
  Label_NonWalk_Ratio := TKMLabel.Create(Panel_Settings, Column_X, NextLine(Column_Y,PARAGRAPH_HEIGHT), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_RATIO], fntMetal, taLeft);
  Label_NonWalk_Ratio.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_RATIO_HINT];
  Label_NonWalk_EGold := TKMLabel.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_EMPTY_GOLD], fntMetal, taLeft);
    Label_NonWalk_EGold.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_EMPTY_GOLD_HINT];
    TBar_NonWalk_EGold := TKMTrackBar.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), WIDTH_TrackBar-OFFSET_1, 0, 10);
    TBar_NonWalk_EGold.Position := 8;
    TBar_NonWalk_EGold.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_EMPTY_GOLD_HINT];
  Label_NonWalk_EIron := TKMLabel.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_EMPTY_IRON], fntMetal, taLeft);
    Label_NonWalk_EIron.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_EMPTY_IRON_HINT];
    TBar_NonWalk_EIron := TKMTrackBar.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), WIDTH_TrackBar-OFFSET_1, 0, 10);
    TBar_NonWalk_EIron.Position := 7;
    TBar_NonWalk_EIron.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_EMPTY_IRON_HINT];
  Label_NonWalk_Swamp := TKMLabel.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_SWAMP], fntMetal, taLeft);
    Label_NonWalk_Swamp.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_SWAMP_HINT];
    TBar_NonWalk_Swamp := TKMTrackBar.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), WIDTH_TrackBar-OFFSET_1, 0, 10);
    TBar_NonWalk_Swamp.Position := 1;
    TBar_NonWalk_Swamp.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_SWAMP_HINT];
  Label_NonWalk_Wetland := TKMLabel.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_WETLAND], fntMetal, taLeft);
    Label_NonWalk_Wetland.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_WETLAND_HINT];
    TBar_NonWalk_Wetland := TKMTrackBar.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), WIDTH_TrackBar-OFFSET_1, 0, 10);
    TBar_NonWalk_Wetland.Position := 5;
    TBar_NonWalk_Wetland.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_WETLAND_HINT];
  Label_NonWalk_Water := TKMLabel.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_WATER], fntMetal, taLeft);
    Label_NonWalk_Water.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_WATER_HINT];
    TBar_NonWalk_Water := TKMTrackBar.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), WIDTH_TrackBar-OFFSET_1, 0, 10);
    TBar_NonWalk_Water.Position := 6;
    TBar_NonWalk_Water.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_WATER_HINT];


// COLUMN 3: Walk textures
  Column_X := Column_3_X;
  Column_Y := 0;
  Check_Biomes := TKMCheckBox.Create(Panel_Settings, Column_X, NextLine(Column_Y,0), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_BIOMES], fntMetal);
    Check_Biomes.Checked := True;
    Check_Biomes.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_BIOMES_HINT];
  Label_Biomes := TKMLabel.Create(Panel_Settings, Column_X, NextLine(Column_Y,PARAGRAPH_HEIGHT), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_TYPE_OF_BIOME], fntMetal, taLeft);
    Label_Biomes.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_TYPE_OF_BIOME_HINT];
    CheckGroup_Grass := TKMRadioGroup.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), BOX_X, BOX_Y, fntMetal);
      CheckGroup_Grass.Add(gResTexts[TX_MAPED_RMG_SETTINGS_GRASS],False); // Just for information purposes (grass must be there always)
      CheckGroup_Grass.ItemIndex := 0;
      CheckGroup_Grass.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_GRASS_HINT];
    Check_Ground := TKMCheckBox.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_GROUND], fntMetal);
      Check_Ground.Checked := True;
      Check_Ground.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_GROUND_HINT];
    Check_Snow := TKMCheckBox.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_SNOW], fntMetal);
      Check_Snow.Checked := True;
      Check_Snow.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_SNOW_HINT];
    Check_Sand := TKMCheckBox.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_SAND], fntMetal);
      Check_Sand.Checked := True;
      Check_Sand.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_SAND_HINT];
  // First Layer
  Label_FirstLayer := TKMLabel.Create(Panel_Settings, Column_X, NextLine(Column_Y,PARAGRAPH_HEIGHT), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_FIRST_LAYER], fntMetal, taLeft);
    Label_FirstLayer.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_FIRST_LAYER_HINT];
    Label_FirstLayer_Step := TKMLabel.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_STEP], fntMetal, taLeft);
      Label_FirstLayer_Step.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_STEP_PRIM_HINT];
      TBar_Biomes1_Step := TKMTrackBar.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), WIDTH_TrackBar-OFFSET_1, 1, 10);
      TBar_Biomes1_Step.Position := 5;
      TBar_Biomes1_Step.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_STEP_PRIM_HINT];
    Label_FirstLayer_Limit := TKMLabel.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_LIMIT], fntMetal, taLeft);
      Label_FirstLayer_Limit.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_LIMIT_HINT];
      TBar_Biomes1_Limit := TKMTrackBar.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), WIDTH_TrackBar-OFFSET_1, 1, 10);
      TBar_Biomes1_Limit.Position := 6;
      TBar_Biomes1_Limit.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_LIMIT_HINT];
  // Second Layer
  Label_SecondLayer := TKMLabel.Create(Panel_Settings, Column_X, NextLine(Column_Y,PARAGRAPH_HEIGHT), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_SECOND_LAYER], fntMetal, taLeft);
    Label_SecondLayer.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_SECOND_LAYER_HINT];
    Label_SecondLayer_Step := TKMLabel.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_STEP], fntMetal, taLeft);
      Label_SecondLayer_Step.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_STEP_SEC_HINT];
      TBar_Biomes2_Step := TKMTrackBar.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), WIDTH_TrackBar-OFFSET_1, 3, 10);
      TBar_Biomes2_Step.Position := 5;
      TBar_Biomes2_Step.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_STEP_SEC_HINT];
    Label_SecondLayer_Limit := TKMLabel.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_LIMIT], fntMetal, taLeft);
      Label_SecondLayer_Limit.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_LIMIT_HINT];
      TBar_Biomes2_Limit := TKMTrackBar.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), WIDTH_TrackBar-OFFSET_1, 1, 10);
      TBar_Biomes2_Limit.Position := 6;
      TBar_Biomes2_Limit.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_LIMIT_HINT];

// DEBUG (COLUMN 3)
  {$IFDEF DEBUG_RMG}
    Check_BasicTiles := TKMCheckBox.Create(Panel_Settings, Column_X, NextLine(Column_Y,40), BOX_X, BOX_Y, 'Basic tiles', fntMetal);
    Check_BasicTiles.Checked := False;
    Check_CA := TKMCheckBox.Create(Panel_Settings, Column_X, NextLine(Column_Y), BOX_X, BOX_Y, 'Cellular automaton', fntMetal);
    Check_CA.Checked := True;
  {$ENDIF}


// COLUMN 4: Height
  Column_X := Column_4_X;
  Column_Y := 0;
  Check_Height := TKMCheckBox.Create(Panel_Settings, Column_X, NextLine(Column_Y,0), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_HEIGHT], fntMetal);
    Check_Height.Checked := True;
    Check_Height.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_HEIGHT_HINT];
  // Hide jagged edges
  Check_HideNonSmoothTransition := TKMCheckBox.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y,PARAGRAPH_HEIGHT), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_HIDE_ROUGHT_TRANSITIONS], fntMetal);
    Check_HideNonSmoothTransition.Checked := True;
    Check_HideNonSmoothTransition.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_HIDE_ROUGHT_TRANSITIONS_HINT];
  // Step
  Label_HeightStep := TKMLabel.Create(Panel_Settings, Column_X, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_STEP], fntMetal, taLeft);
    Label_HeightStep.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_HEIGHT_STEP_HINT];
  TBar_HeightStep := TKMTrackBar.Create(Panel_Settings, Column_X, NextLine(Column_Y), WIDTH_TrackBar, 1, 7);
    TBar_HeightStep.Position := 4;
    TBar_HeightStep.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_HEIGHT_STEP_HINT];
  // Slope
  Label_HeightSlope := TKMLabel.Create(Panel_Settings, Column_X, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_TERRAIN_HEIGHTS_SLOPE], fntMetal, taLeft);
    Label_HeightSlope.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_HEIGHT_SLOPE_HINT];
  TBar_HeightSlope := TKMTrackBar.Create(Panel_Settings, Column_X, NextLine(Column_Y), WIDTH_TrackBar, 0, 100);
    TBar_HeightSlope.Position := 30;
    TBar_HeightSlope.Step := 10;
    TBar_HeightSlope.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_HEIGHT_SLOPE_HINT];
  // Height
  Label_HeightHeight := TKMLabel.Create(Panel_Settings, Column_X, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_TERRAIN_HEIGHTS], fntMetal, taLeft);
    Label_HeightHeight.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_HEIGHT_HEIGHTS_HINT];
  TBar_HeightHeight := TKMTrackBar.Create(Panel_Settings, Column_X, NextLine(Column_Y), WIDTH_TrackBar, 0, 100);
    TBar_HeightHeight.Position := 60;
    TBar_HeightHeight.Step := 10;
    TBar_HeightHeight.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_HEIGHT_HEIGHTS_HINT];
  // One path fix (it gives no-walk object to islands and create only 1 walkable area - in KaM is possible to have max 255 separated areas and RMG sometimes makes more which cause crash of the game)
  Label_InacessiblePlaces := TKMLabel.Create(Panel_Settings, Column_X, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_INACCESIBLE_PLACES], fntMetal, taLeft);
    Label_InacessiblePlaces.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_INACCESIBLE_PLACES_HINT];
    Check_NoGo := TKMCheckBox.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_BLOCK_WALKING], fntMetal);
    Check_NoGo.Checked := True;
    Check_NoGo.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_BLOCK_WALKING_HINT];
    Check_ReplaceTerrain := TKMCheckBox.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_CHANGE_TEXTURE], fntMetal);
    Check_ReplaceTerrain.Checked := True;
    Check_ReplaceTerrain.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_CHANGE_TEXTURE_HINT];

// COLUMN 4: Objects
  Check_Objects := TKMCheckBox.Create(Panel_Settings, Column_X, NextLine(Column_Y,40), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_OBJECTS], fntMetal);
    Check_Objects.Checked := True;
    Check_Objects.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_OBJECTS_HINT];
  // Animals
  Check_Animals := TKMCheckBox.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y,PARAGRAPH_HEIGHT), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_ANIMALS], fntMetal);
    Check_Animals.Checked := True;
    Check_Animals.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_ANIMALS_HINT];
  // Object density
  Label_Density := TKMLabel.Create(Panel_Settings, Column_X, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_DENSITY], fntMetal, taLeft);
    Label_Density.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_OBJECTS_DENSITY_HINT];
    TBar_ObjectDensity := TKMTrackBar.Create(Panel_Settings, Column_X, NextLine(Column_Y), WIDTH_TrackBar, 0, 10);
    TBar_ObjectDensity.Position := 6;
    TBar_ObjectDensity.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_OBJECTS_DENSITY_HINT];
  // Forests
  Label_Forests := TKMLabel.Create(Panel_Settings, Column_X, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_FORESTS] + ' (x5)', fntMetal, taLeft);
    Label_Forests.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_FORESTS_HINT];
    TBar_Forests := TKMTrackBar.Create(Panel_Settings, Column_X, NextLine(Column_Y), WIDTH_TrackBar, 0, 100);
    TBar_Forests.Position := 10;
    TBar_Forests.Step := 5;
    TBar_Forests.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_FORESTS_HINT];
  // Trees in forest
  Label_Trees := TKMLabel.Create(Panel_Settings, Column_X, NextLine(Column_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_TREES], fntMetal, taLeft);
    Label_Trees.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_TREES_HINT];
    TBar_Trees := TKMTrackBar.Create(Panel_Settings, Column_X, NextLine(Column_Y), WIDTH_TrackBar, 1, 30);
    TBar_Trees.Position := 20;
    TBar_Trees.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_TREES_HINT];


// Map size
  Column_X := Column_1_X;
  Column_Y := SIZE_Y - 100;
  TKMLabel.Create(Panel_Settings, Column_X, NextLine(Column_Y,0), gResTexts[TX_MAPED_RMG_SETTINGS_MAP_SIZE], fntMetal, taLeft);
  TKMBevel.Create(Panel_Settings, Column_X, Column_Y+15, 130, 20);
  Label_MapSize := TKMLabel.Create(Panel_Settings, Column_X+OFFSET_1, NextLine(Column_Y), BOX_X, BOX_Y, ' ', fntMetal, taLeft);


// Seed
  Column_X := Column_1_X + 150;
  Column_Y := SIZE_Y - 100;
	Label_Seed := TKMLabel.Create(Panel_Settings, Column_X, NextLine(Column_Y,0), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_SEED], fntMetal, taLeft);
    Label_Seed.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_SEED_HINT];
  NumSeed := TKMNumericEdit.Create(Panel_Settings, Column_X, NextLine(Column_Y,15), Low( Integer ), High( Integer ));
    NumSeed.OnChange := RMG_Change;
    NumSeed.Value := Random( High(Integer) );
    NumSeed.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_SEED_HINT];

// Buttons
  Button_RMG_Generate_New_Seed := TKMButton.Create(Panel_RMG, SIZE_X-480-60, SIZE_Y - 50, 200, 30, gResTexts[TX_MAPED_RMG_SETTINGS_NEW_RANDOM_SEED], bsMenu);
  Button_RMG_Generate_New_Seed.OnClick := RMG_Generate_New_Seed;
  Button_RMG_Generate_New_Seed.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_NEW_RANDOM_SEED_HINT];
  Button_RMG_Generate := TKMButton.Create(Panel_RMG, SIZE_X-320-10, SIZE_Y - 50, 160, 30, gResTexts[TX_MAPED_RMG_SETTINGS_GENERATE_MAP], bsMenu);
  Button_RMG_Generate.OnClick := RMG_Generate_Map;
  Button_RMG_Generate.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_GENERATE_MAP_HINT];
  Button_RMG_Cancel := TKMButton.Create(Panel_RMG, SIZE_X-160, SIZE_Y - 50, 160, 30, gResTexts[TX_MAPED_CANCEL], bsMenu);
  Button_RMG_Cancel.OnClick := RMG_Close;
  Button_RMG_Cancel.Hint := gResTexts[TX_MAPED_RMG_SETTINGS_CLOSE_RMG_HINT];


  {$IFDEF DEBUG_RMG}
    //SetDebugSettings();
  {$ENDIF}
end;


destructor TKMMapEdRMG.Destroy;
begin
  FreeAndNil(fRMG);

  inherited;
end;



function TKMMapEdRMG.NextLine(var Line: Integer; const LINE_Y: Byte = 20): Integer;
begin
  Line := Line + LINE_Y;
  Result := Line;
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
var Tiles: TKMTerrainTileBriefArray;
    Errors: TKMTerrainTileChangeErrorArray;
begin
  with fRMG.RMGSettings do
  begin
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
    with Locs do
    begin
      Active := Check_Locs.Checked;
      Players := TBar_Players.Position;
      LocsPosition := CheckGroup_LocPosition.ItemIndex;
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
    end;
    with OnePath do
    begin
      NoGoZones := Check_NoGo.Checked;
      ReplaceTerrain := Check_ReplaceTerrain.Checked;
    end;
    with Height do
    begin
      Step := TBar_HeightStep.Position;
      Slope := TBar_HeightSlope.Position;
      Height := TBar_HeightHeight.Position;
      Active := Check_Height.Checked;
      HideNonSmoothTransition := Check_HideNonSmoothTransition.Checked;
    end;
    with Objects do
    begin
      Active := Check_Objects.Checked;
      ObjectDensity := TBar_ObjectDensity.Position;
      Forests := TBar_Forests.Position;
      Trees := TBar_Trees.Position;
      Animals := Check_Animals.Checked;
    end;
    Seed := NumSeed.Value;

    {$IFDEF DEBUG_RMG}
      BasicTiles := Check_BasicTiles.Checked;
      CA := Check_CA.Checked;
    {$ELSE}
      BasicTiles := False;
      CA := True;
    {$ENDIF}
  end;
  SetLength(Tiles, 16);
  fRMG.GenerateMap(Tiles);
  SetLength(Errors, 16);
  gTerrain.ScriptTrySetTilesArray(Tiles, False, Errors);
end;


function TKMMapEdRMG.GetVisible: Boolean;
begin
  Result := Panel_RMG.Visible;
end;


procedure TKMMapEdRMG.RMG_Close(Sender: TObject);
begin
  Panel_RMG.Hide;
end;


procedure TKMMapEdRMG.Show();
begin
  Panel_RMG.Show;
  if not fMapSizeIndicator then
  begin
    fMapSizeIndicator := True;
    Label_MapSize.Caption := Format('X: %d, Y: %d',[gTerrain.MapX,gTerrain.MapY]);
  end;
end;


end.
