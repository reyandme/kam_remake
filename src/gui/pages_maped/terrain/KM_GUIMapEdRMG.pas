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

    Check_Biomes, Check_Ground,Check_Snow,Check_Sand,
    Check_Obstacles,
    Check_Locs, Check_Resources, Check_ConnectLocs, Check_MineFix,
    Check_Height, Check_HideNonSmoothTransition,
    Check_NoGo, Check_ReplaceTerrain,
    Check_Objects, Check_Animals,
    Check_BasicTiles,Check_CA: TKMCheckBox;

    TBar_Biomes1_Step, TBar_Biomes1_Limit, TBar_Biomes2_Step, TBar_Biomes2_Limit,
    TBar_NonWalk_EGold, TBar_NonWalk_EIron, TBar_NonWalk_Swamp, TBar_NonWalk_Wetland, TBar_NonWalk_Water, TBar_ProtectedRadius, TBar_NonWalk_Density, TBar_NonWalk_Size, TBar_NonWalk_Variance,
    TBar_ObjectDensity, TBar_Forests, TBar_Trees,
    TBar_Res_Stone, TBar_Res_Gold, TBar_Res_Iron,
    TBar_Players: TKMTrackBar;

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
      CheckGroup_LocPosition.ItemIndex := 0;
      TBar_ProtectedRadius.Position := 6;
      Check_Resources.Checked := True;
      Check_ConnectLocs.Checked := True;
      Check_MineFix.Checked := True;
      TBar_Res_Stone.Position := 5;
      TBar_Res_Gold.Position := 5;
      TBar_Res_Iron.Position := 5;

    // COLUMN 2: NonWalk textures column
      Check_Obstacles.Checked := True;
      // Ratio of biomes
      TBar_NonWalk_EGold.Position := 8;
      TBar_NonWalk_EIron.Position := 7;
      TBar_NonWalk_Swamp.Position := 0;
      TBar_NonWalk_Wetland.Position := 0;
      TBar_NonWalk_Water.Position := 0;
      TBar_NonWalk_Density.Position := 1;
      TBar_NonWalk_Size.Position := 20;
      TBar_NonWalk_Variance.Position := 5;

    // COLUMN 3: Walk textures
      Check_Biomes.Checked := False;
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
      Check_HideNonSmoothTransition.Checked := True;
    // COLUMN 4: One path fix (it gives no-walk object to islands and create only 1 walkable area - in KaM is possible to have max 255 separated areas and RMG sometimes makes more which cause crash of the game)
      Check_NoGo.Checked := False;
      Check_ReplaceTerrain.Checked := False;
    // COLUMN 4: Objects
      Check_Objects.Checked := False;
      Check_Animals.Checked := False;
      TBar_ObjectDensity.Position := 6;
      TBar_Forests.Position := 10;
      TBar_Trees.Position := 20;

    // COLUMN 4: Seed
      NumSeed.Value := 417;
    // COLUMN 4: Players
      TBar_Players.Position := 1;

    // DEBUG (COLUMN 4)
      Check_BasicTiles.Checked := False;
      Check_CA.Checked := True;
  end;
const
  POS_X = 300;
  POS_Y = 0;
  SIZE_X = 700;
  SIZE_Y = 600;
  BOX_X = 200;
  BOX_Y = 60;
  Column_1_X = 20;
  Column_2_X = 195;
  Column_3_X = 350;
  Column_4_X = 500;
  OFFSET_1 = 20;
  OFFSET_2 = 30;
var
  Img: TKMImage;
  Column_1_Y, Column_2_Y, Column_3_Y, Column_4_Y: Integer;
  Panel_Settings: TKMPanel;
begin
  inherited Create;

  fMapSizeIndicator := False;

  Panel_RMG := TKMPanel.Create(aParent, (aParent.Width - SIZE_X) div 2, (aParent.Height - SIZE_Y) div 2, SIZE_X, SIZE_Y);
  Panel_RMG.AnchorsCenter;
  Panel_RMG.Hide;
  Panel_RMG.PanelHandleMouseWheelByDefault := False; //Allow to zoom in/out while RMG settings window is open

  TKMBevel.Create(Panel_RMG, -1000,  -1000, 4000, 4000);
  Img := TKMImage.Create(Panel_RMG, -20, -50, SIZE_X+40, SIZE_Y+60, 15, rxGuiMain);
  Img.ImageStretch;
  TKMBevel.Create(Panel_RMG,   0,  50, SIZE_X, SIZE_Y - 110);
  TKMLabel.Create(Panel_RMG, SIZE_X div 2, -20, gResTexts[TX_MAPED_RMG_SETTINGS_TITLE], fntOutline, taCenter);
  TKMLabel.Create(Panel_RMG, 10, (Panel_RMG.Height - 100), gResTexts[TX_MAPED_RMG_SETTINGS_MAP_SIZE], fntMetal, taLeft);

  fRMG := TKMRandomMapGenerator.Create;

// COLUMN 1: Locs + Resources
  Panel_Settings := TKMPanel.Create(Panel_RMG, 0,  50, SIZE_X, SIZE_Y - 110);
  Column_1_Y := 0;
  TKMLabel.Create(Panel_Settings, Column_1_X, NextLine(Column_1_Y), 280, 0, gResTexts[TX_MAPED_RMG_SETTINGS_LOCS], fntMetal, taLeft);
  Check_Locs := TKMCheckBox.Create(Panel_Settings, Column_1_X+OFFSET_1, NextLine(Column_1_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_ACTIVE], fntMetal);
    Check_Locs.Checked := True;
  TKMLabel.Create(Panel_Settings, Column_1_X, NextLine(Column_1_Y), 280, 0, gResTexts[TX_MAPED_RMG_SETTINGS_LAYOUT], fntMetal, taLeft);
    CheckGroup_LocPosition := TKMRadioGroup.Create(Panel_Settings, Column_1_X+OFFSET_1, NextLine(Column_1_Y), BOX_X, 100, fntMetal);
    CheckGroup_LocPosition.Add(gResTexts[TX_MAPED_RMG_SETTINGS_RECTANGLE], True);
    CheckGroup_LocPosition.Add(gResTexts[TX_MAPED_RMG_SETTINGS_VERTICAL], True);
    CheckGroup_LocPosition.Add(gResTexts[TX_MAPED_RMG_SETTINGS_HORISONTAL], True);
    CheckGroup_LocPosition.Add(gResTexts[TX_MAPED_RMG_SETTINGS_RANDOM], True);
    CheckGroup_LocPosition.Add(gResTexts[TX_MAPED_RMG_SETTINGS_CENTER_SCREEN], True);
    CheckGroup_LocPosition.ItemIndex := 0;
  NextLine(Column_1_Y,80);

  TKMLabel.Create(Panel_Settings, Column_1_X+OFFSET_1, NextLine(Column_1_Y), gResTexts[TX_MAPED_RMG_SETTINGS_LOC_RADIUS], fntMetal, taLeft);
  TBar_ProtectedRadius := TKMTrackBar.Create(Panel_Settings, Column_1_X, NextLine(Column_1_Y), 120, 1, 10);
    TBar_ProtectedRadius.Position := 6;
    Check_Resources := TKMCheckBox.Create(Panel_Settings, Column_1_X, NextLine(Column_1_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_RESOURCES], fntMetal);
    Check_Resources.Checked := True;
    Check_ConnectLocs := TKMCheckBox.Create(Panel_Settings, Column_1_X+OFFSET_1, NextLine(Column_1_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_CONNECT_LOCS], fntMetal);
    Check_ConnectLocs.Checked := True;
    Check_MineFix := TKMCheckBox.Create(Panel_Settings, Column_1_X+OFFSET_1, NextLine(Column_1_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_MINE_FIX], fntMetal);
    Check_MineFix.Checked := True;
  TKMLabel.Create(Panel_Settings, Column_1_X+OFFSET_1, NextLine(Column_1_Y), gResTexts[TX_RESOURCES_STONES] + '(x200)', fntMetal, taLeft);
    TBar_Res_Stone := TKMTrackBar.Create(Panel_Settings, Column_1_X, NextLine(Column_1_Y), 120, 0, 10);
    TBar_Res_Stone.Position := 5;
  TKMLabel.Create(Panel_Settings, Column_1_X+OFFSET_1, NextLine(Column_1_Y), gResTexts[TX_RESOURCES_GOLD] + ' (x50)', fntMetal, taLeft);
    TBar_Res_Gold := TKMTrackBar.Create(Panel_Settings, Column_1_X, NextLine(Column_1_Y), 120, 0, 10);
    TBar_Res_Gold.Position := 5;
  TKMLabel.Create(Panel_Settings, Column_1_X+OFFSET_1, NextLine(Column_1_Y), gResTexts[TX_RESOURCES_IRON] + ' (x50)', fntMetal, taLeft);
    TBar_Res_Iron := TKMTrackBar.Create(Panel_Settings, Column_1_X, NextLine(Column_1_Y), 120, 0, 10);
    TBar_Res_Iron.Position := 5;

// COLUMN 2: NonWalk textures column
  Column_2_Y := 0;
  TKMLabel.Create(Panel_Settings, Column_2_X, NextLine(Column_2_Y), 280, 0, gResTexts[TX_MAPED_RMG_SETTINGS_OBSTACLES], fntMetal, taLeft);
    Check_Obstacles := TKMCheckBox.Create(Panel_Settings, Column_2_X, NextLine(Column_2_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_OBSTACLES], fntMetal);
    Check_Obstacles.Checked := True;//True;
  // Ratio of biomes
  TKMLabel.Create(Panel_Settings, Column_2_X+OFFSET_1, NextLine(Column_2_Y), gResTexts[TX_MAPED_RMG_SETTINGS_EMPTY_GOLD], fntMetal, taLeft);
    TBar_NonWalk_EGold := TKMTrackBar.Create(Panel_Settings, Column_2_X, NextLine(Column_2_Y), 120, 0, 10);
    TBar_NonWalk_EGold.Position := 8;
  TKMLabel.Create(Panel_Settings, Column_2_X+OFFSET_1, NextLine(Column_2_Y), gResTexts[TX_MAPED_RMG_SETTINGS_EMPTY_IRON], fntMetal, taLeft);
    TBar_NonWalk_EIron := TKMTrackBar.Create(Panel_Settings, Column_2_X, NextLine(Column_2_Y), 120, 0, 10);
    TBar_NonWalk_EIron.Position := 7;
  TKMLabel.Create(Panel_Settings, Column_2_X+OFFSET_1, NextLine(Column_2_Y), gResTexts[TX_MAPED_RMG_SETTINGS_SWAMP], fntMetal, taLeft);
    TBar_NonWalk_Swamp := TKMTrackBar.Create(Panel_Settings, Column_2_X, NextLine(Column_2_Y), 120, 0, 10);
    TBar_NonWalk_Swamp.Position := 1;
  TKMLabel.Create(Panel_Settings, Column_2_X+OFFSET_1, NextLine(Column_2_Y), gResTexts[TX_MAPED_RMG_SETTINGS_WETLAND], fntMetal, taLeft);
    TBar_NonWalk_Wetland := TKMTrackBar.Create(Panel_Settings, Column_2_X, NextLine(Column_2_Y), 120, 0, 10);
    TBar_NonWalk_Wetland.Position := 5;
  TKMLabel.Create(Panel_Settings, Column_2_X+OFFSET_1, NextLine(Column_2_Y), gResTexts[TX_MAPED_RMG_SETTINGS_WATER], fntMetal, taLeft);
    TBar_NonWalk_Water := TKMTrackBar.Create(Panel_Settings, Column_2_X, NextLine(Column_2_Y), 120, 0, 10);
    TBar_NonWalk_Water.Position := 6;
  // Density
  TKMLabel.Create(Panel_Settings, Column_2_X+OFFSET_1, NextLine(Column_2_Y), gResTexts[TX_MAPED_RMG_SETTINGS_DENSITY], fntMetal, taLeft);
    TBar_NonWalk_Density := TKMTrackBar.Create(Panel_Settings, Column_2_X, NextLine(Column_2_Y), 120, 1, 20);
    TBar_NonWalk_Density.Position := 8;
  // Size
  TKMLabel.Create(Panel_Settings, Column_2_X+OFFSET_1, NextLine(Column_2_Y), gResTexts[TX_MAPED_RMG_SETTINGS_SIZE], fntMetal, taLeft);
    TBar_NonWalk_Size := TKMTrackBar.Create(Panel_Settings, Column_2_X, NextLine(Column_2_Y), 120, 1, 20);
    TBar_NonWalk_Size.Position := 10;
  // Variance
  TKMLabel.Create(Panel_Settings, Column_2_X+OFFSET_1, NextLine(Column_2_Y), gResTexts[TX_MAPED_RMG_SETTINGS_VARIANCE], fntMetal, taLeft);
    TBar_NonWalk_Variance := TKMTrackBar.Create(Panel_Settings, Column_2_X, NextLine(Column_2_Y), 120, 1, 10);
    TBar_NonWalk_Variance.Position := 5;


// COLUMN 3: Walk textures
  Column_3_Y := 0;
  TKMLabel.Create(Panel_Settings, Column_3_X, NextLine(Column_3_Y), 180, 0, gResTexts[TX_MAPED_RMG_SETTINGS_WALK_TEXTURES], fntMetal, taLeft);
  Check_Biomes := TKMCheckBox.Create(Panel_Settings, Column_3_X, NextLine(Column_3_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_BIOMES], fntMetal);
    Check_Biomes.Checked := True;
    CheckGroup_Grass := TKMRadioGroup.Create(Panel_Settings, Column_3_X+OFFSET_1, NextLine(Column_3_Y), BOX_X, BOX_Y, fntMetal);
      CheckGroup_Grass.Add(gResTexts[TX_MAPED_RMG_SETTINGS_GRASS],False); // Just for information purposes (grass must be there always)
      CheckGroup_Grass.ItemIndex := 0;
    Check_Ground := TKMCheckBox.Create(Panel_Settings, Column_3_X+OFFSET_1, NextLine(Column_3_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_GROUND], fntMetal);
      Check_Ground.Checked := True;
    Check_Snow := TKMCheckBox.Create(Panel_Settings, Column_3_X+OFFSET_1, NextLine(Column_3_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_SNOW], fntMetal);
      Check_Snow.Checked := True;
    Check_Sand := TKMCheckBox.Create(Panel_Settings, Column_3_X+OFFSET_1, NextLine(Column_3_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_SAND], fntMetal);
      Check_Sand.Checked := True;
  // First Layer
  TKMLabel.Create(Panel_Settings, Column_3_X, NextLine(Column_3_Y), 180, 0, gResTexts[TX_MAPED_RMG_SETTINGS_FIRST_LAYER], fntMetal, taLeft);
    TKMLabel.Create(Panel_Settings, Column_3_X+OFFSET_1, NextLine(Column_3_Y), 180, 0, gResTexts[TX_MAPED_RMG_SETTINGS_STEP], fntMetal, taLeft);
      TBar_Biomes1_Step := TKMTrackBar.Create(Panel_Settings, Column_3_X, NextLine(Column_3_Y), 120, 1, 10);
      TBar_Biomes1_Step.Position := 5;
    TKMLabel.Create(Panel_Settings, Column_3_X+OFFSET_1, NextLine(Column_3_Y), 220, 0, gResTexts[TX_MAPED_RMG_SETTINGS_LIMIT], fntMetal, taLeft);
      TBar_Biomes1_Limit := TKMTrackBar.Create(Panel_Settings, Column_3_X, NextLine(Column_3_Y), 120, 1, 10);
      TBar_Biomes1_Limit.Position := 6;
  // Second Layer
  TKMLabel.Create(Panel_Settings, Column_3_X, NextLine(Column_3_Y), 180, 0, gResTexts[TX_MAPED_RMG_SETTINGS_SECOND_LAYER], fntMetal, taLeft);
    TKMLabel.Create(Panel_Settings, Column_3_X+OFFSET_1, NextLine(Column_3_Y), 180, 0, gResTexts[TX_MAPED_RMG_SETTINGS_STEP], fntMetal, taLeft);
      TBar_Biomes2_Step := TKMTrackBar.Create(Panel_Settings, Column_3_X, NextLine(Column_3_Y), 120, 3, 10);
      TBar_Biomes2_Step.Position := 5;
    TKMLabel.Create(Panel_Settings, Column_3_X+OFFSET_1, NextLine(Column_3_Y), 180, 0, gResTexts[TX_MAPED_RMG_SETTINGS_LIMIT], fntMetal, taLeft);
      TBar_Biomes2_Limit := TKMTrackBar.Create(Panel_Settings, Column_3_X, NextLine(Column_3_Y), 120, 1, 10);
      TBar_Biomes2_Limit.Position := 6;


// COLUMN 4: Height
  Column_4_Y := 0;
  TKMLabel.Create(Panel_Settings, Column_4_X, NextLine(Column_4_Y), gResTexts[TX_MAPED_RMG_SETTINGS_HEIGHT], fntMetal, taLeft);
    Check_Height := TKMCheckBox.Create(Panel_Settings, Column_4_X+OFFSET_1, NextLine(Column_4_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_ACTIVE], fntMetal);
    Check_Height.Checked := True;//True;
    Check_HideNonSmoothTransition := TKMCheckBox.Create(Panel_Settings, Column_4_X+OFFSET_1, NextLine(Column_4_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_H_N_S_T], fntMetal);
    Check_HideNonSmoothTransition.Checked := True;
// COLUMN 4: One path fix (it gives no-walk object to islands and create only 1 walkable area - in KaM is possible to have max 255 separated areas and RMG sometimes makes more which cause crash of the game)
  TKMLabel.Create(Panel_Settings, Column_4_X, NextLine(Column_4_Y), gResTexts[TX_MAPED_RMG_SETTINGS_INACCESIBLE_PLACES], fntMetal, taLeft);
    Check_NoGo := TKMCheckBox.Create(Panel_Settings, Column_4_X+OFFSET_1, NextLine(Column_4_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_NOGO_ZONES], fntMetal);
    Check_NoGo.Checked := True;
    Check_ReplaceTerrain := TKMCheckBox.Create(Panel_Settings, Column_4_X+OFFSET_1, NextLine(Column_4_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_RPLC_MNT_TERRAIN], fntMetal);
    Check_ReplaceTerrain.Checked := True;
// COLUMN 4: Objects
  TKMLabel.Create(Panel_Settings, Column_4_X, NextLine(Column_4_Y), gResTexts[TX_MAPED_RMG_SETTINGS_OBJECTS], fntMetal, taLeft);
  Check_Objects := TKMCheckBox.Create(Panel_Settings, Column_4_X, NextLine(Column_4_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_ACTIVE], fntMetal);
    Check_Objects.Checked := True;
  Check_Animals := TKMCheckBox.Create(Panel_Settings, Column_4_X+OFFSET_1, NextLine(Column_4_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_ANIMALS], fntMetal);
    Check_Animals.Checked := True;
  TKMLabel.Create(Panel_Settings, Column_4_X+OFFSET_1, NextLine(Column_4_Y), gResTexts[TX_MAPED_RMG_SETTINGS_DENSITY], fntMetal, taLeft);
    TBar_ObjectDensity := TKMTrackBar.Create(Panel_Settings, Column_4_X, NextLine(Column_4_Y), 120, 0, 10);
    TBar_ObjectDensity.Position := 6;
  TKMLabel.Create(Panel_Settings, Column_4_X+OFFSET_1, NextLine(Column_4_Y), gResTexts[TX_MAPED_RMG_SETTINGS_FORESTS] + ' (x5)', fntMetal, taLeft);
    TBar_Forests := TKMTrackBar.Create(Panel_Settings, Column_4_X, NextLine(Column_4_Y), 120, 0, 20);
    TBar_Forests.Position := 10;
  TKMLabel.Create(Panel_Settings, Column_4_X+OFFSET_1, NextLine(Column_4_Y), gResTexts[TX_MAPED_RMG_SETTINGS_TREES], fntMetal, taLeft);
    TBar_Trees := TKMTrackBar.Create(Panel_Settings, Column_4_X, NextLine(Column_4_Y), 120, 1, 30);
    TBar_Trees.Position := 20;

// COLUMN 4: Seed
  TKMLabel.Create(Panel_Settings, Column_4_X, NextLine(Column_4_Y), gResTexts[TX_MAPED_RMG_SETTINGS_SEED], fntMetal, taLeft);
    NumSeed := TKMNumericEdit.Create(Panel_Settings, Column_4_X, NextLine(Column_4_Y), Low( Integer ), High( Integer ));
    NumSeed.OnChange := RMG_Change;
// COLUMN 4: Players
  TKMLabel.Create(Panel_Settings, Column_4_X, NextLine(Column_4_Y), gResTexts[TX_WORD_PLAYERS], fntMetal, taLeft);
    TBar_Players := TKMTrackBar.Create(Panel_Settings, Column_4_X, NextLine(Column_4_Y), 120, 1, 12);
    TBar_Players.Position := 4;

// DEBUG (COLUMN 4)
  NextLine(Column_4_Y);
  NextLine(Column_4_Y);
  Check_BasicTiles := TKMCheckBox.Create(Panel_Settings, Column_4_X, NextLine(Column_4_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_BASIC_TILES], fntMetal);
  Check_BasicTiles.Checked := False;
  Check_CA := TKMCheckBox.Create(Panel_Settings, Column_4_X, NextLine(Column_4_Y), BOX_X, BOX_Y, gResTexts[TX_MAPED_RMG_SETTINGS_CELLULAR_AUTOMATON], fntMetal);
  Check_CA.Checked := True;


  Button_RMG_Generate_New_Seed := TKMButton.Create(Panel_RMG, SIZE_X-480-60, SIZE_Y - 50, 200, 30, gResTexts[TX_MAPED_RMG_SETTINGS_NEW_RANDOM_SEED], bsMenu);
  Button_RMG_Generate_New_Seed.OnClick := RMG_Generate_New_Seed;
  Button_RMG_Generate := TKMButton.Create(Panel_RMG, SIZE_X-320-10, SIZE_Y - 50, 160, 30, gResTexts[TX_MAPED_RMG_SETTINGS_GENERATE_MAP], bsMenu);
  Button_RMG_Generate.OnClick := RMG_Generate_Map;
  Button_RMG_Cancel := TKMButton.Create(Panel_RMG, SIZE_X-160, SIZE_Y - 50, 160, 30, gResTexts[TX_MAPED_CANCEL], bsMenu);
  Button_RMG_Cancel.OnClick := RMG_Close;

  //SetDebugSettings();
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
  NumSeed.Value := Round(1000*KaMRandom('TKMMapEdRMG.RMG_Generate_New_Seed'));
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
      ProtectedRadius := TBar_ProtectedRadius.Position;
    end;
    with Locs do
    begin
      Active := Check_Locs.Checked;
      Players := TBar_Players.Position;
      LocsPosition := CheckGroup_LocPosition.ItemIndex;
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
    BasicTiles := Check_BasicTiles.Checked;
    CA := Check_CA.Checked;
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
    TKMLabel.Create(Panel_RMG, 10, (Panel_RMG.Height - 80), 200, 20, 'X: '+IntToStr(gTerrain.MapX)+', Y: '+IntToStr(gTerrain.MapY), fntMetal, taLeft);
  end;
end;


end.
