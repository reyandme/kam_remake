unit KM_ResTilesetTypes;
{$I KaM_Remake.inc}
interface

const
  TILES_CNT = 597;
  MAX_TILE_TO_SHOW = TILES_CNT;
  MAX_STATIC_TERRAIN_ID = 9997;

type
  //TKMTileProperty = set of (tpWalkable, tpRoadable);

  TKMTileMaskType = (tmtNone,
    tmt2Straight, // A A
                  // B B

    tmt2Diagonal, // A A
                  // B A

    tmt2Corner,   // A B
                  // B B

    tmt2Opposite, // A B
                  // B A

    tmt3Straight, // A A
                  // C D

    tmt3Opposite, // A B
                  // D A

    tmt4Square);  // A B
                  // D C

  TKMTileMaskSubType = (mstMain, mstExtra);

  TKMTileMaskKind = (mkNone, mkSoft1, mkSoft2, mkSoft3, mkStraight, mkGradient);

  // Mask usage: as a pixel mask, or as a gradient mask
  TKMTileMaskKindUse = (mkuPixel, mkuAlpha);

  TKMMaskFullType = record
    Kind: TKMTileMaskKind;
    MType: TKMTileMaskType;
    SubType: TKMTileMaskSubType;
  end;

  PKMMaskFullType = ^TKMMaskFullType;

  TKMTerrainKind = (
//    tkNone,
    tkCustom,     //0
    tkGrass,      //1
    tkMoss,       //2
    tkPaleGrass,  //3
    tkCoastSand,  //4
    tkGrassSand1, //5
    tkGrassSand2, //6
    tkGrassSand3, //7
    tkSand,       //8
    tkGrassDirt,  //9
    tkDirt,       //10
    tkCobbleStone,//11
    tkGrassyWater,//12
    tkSwamp,      //13
    tkIce,        //14
    tkSnowOnGrass,//15
    tkSnowOnDirt, //16
    tkSnow,       //17
    tkDeepSnow,   //18
    tkStone,      //19
    tkGoldMount,  //20
    tkIronMount,  //21
    tkAbyss,      //22
    tkGravel,     //23
    tkCoal,       //24
    tkGold,       //25
    tkIron,       //26
    tkWater,      //27
    tkFastWater,  //28
    tkLava);      //29


  TKMTerrainKindsArray = array of TKMTerrainKind;

  TKMTerrainKindSet = set of TKMTerrainKind;

  TKMTerrainKindCorners = array[0..3] of TKMTerrainKind;


const
  MAX_TILE_ANIM_LAYERS_CNT = 3; // Max number of animation layers
  MAX_TILE_ANIMLAYER_ANIM_CNT = 12; // Max number of animations per tile on the animation layer

type
  TKMTileAnimLayer = record
    Count: Byte;
    Frames: Byte;
    Anims: array of Word;
    function GetAnim(aAnimStep: Integer): Word;
    function HasAnim: Boolean;
  end;

  TKMTileAnim = record
    LayersCnt: Byte;
    Layers: array of TKMTileAnimLayer;
    function HasAnim: Boolean;
  end;

  TKMTileParams = record
    ID: Word;
//    MinimapColor
    Walkable: Boolean;
    Roadable: Boolean;
    Stone: Byte;
    Coal: Byte;
    Iron: Byte;
    Gold: Byte;
    Water: Boolean;
    HasWater: Boolean;
    Ice: Boolean;
    Sand: Boolean;
    Snow: Boolean;
    Soil: Boolean;
    Corn: Boolean;
    Wine: Boolean;
    Factorable: Boolean;
    IronMinable: Boolean;
    GoldMinable: Boolean;
    Animation: TKMTileAnim;
    TerKinds: array[0..3] of TKMTerrainKind; //Corners: LeftTop - RightTop - RightBottom - LeftBottom
//    Corner: Boolean;
//    Edge: Boolean;
  end;

const
  TER_KIND_ORDER: array[tkCustom..tkLava] of Integer =
    (0,1,2,3,4,5,6,7,8,9,10,11,
      -1,    // To make Water/FastWater-GrassyWater transition possible with layers we need GrassyWater to be above Water because of animation (water above grassy anim looks ugly)
      13,
      -2,
      15,16,17,18,19,20,21,22,23,24,25,26,
      -4,-3, // Put GrassyWater/Water/FastWater always to the base layer, because of animation
      29);

  BASE_TERRAIN: array[TKMTerrainKind] of Word = //tkCustom..tkLava] of Word =
    (0, 0, 8, 17, 32, 26, 27, 28, 29, 34, 35, 215, 48, 40, 44, 315, 47, 46, 45, 132, 159, 164, 245, 20, 155, 147, 151, 192, 209, 7);

//  TILE_MASKS: array[mt_2Straight..mt_4Square] of Word =
//      (279, 278, 280, 281, 282, 277);

  TILE_MASKS_LAYERS_CNT: array[TKMTileMaskType] of Byte =
    (1, 2, 2, 2, 2, 3, 3, 4);

  TILE_MASK_KINDS_PREVIEW: array[TKMTileMaskKind] of Integer =
    (-1, 4951, 4961, 4971, 4981, 4991); //+1 here, so -1 is no image, and not grass

  TILE_MASK_KIND_USAGE: array [TKMTileMaskKind] of TKMTileMaskKindUse =
    (mkuPixel, mkuPixel, mkuPixel, mkuPixel, mkuPixel, mkuAlpha);


  TILE_MASKS_FOR_LAYERS:  array[Succ(Low(TKMTileMaskKind))..High(TKMTileMaskKind)]
                            of array[Succ(Low(TKMTileMaskType))..High(TKMTileMaskType)]
                              of array[TKMTileMaskSubType] of Integer =
     //Softest
    (((4949, -1),
      (4950, -1),
      (4951, -1),
      (4952, -1),
      (4951, 4949),
      (4951, 4952),
      (4951, -1)),
     //Soft
     ((4959, -1),
      (4960, -1),
      (4961, -1),
      (4962, -1),
      (4961, 4959),
      (4961, 4962),
      (4961, -1)),
     //Soft2
     ((4969, -1),
      (4970, -1),
      (4971, -1),
      (4972, -1),
      (4971, 4969),
      (4971, 4972),
      (4971, -1)),
     //Hard
     ((4979, -1),
      (4980, -1),
      (4981, -1),
      (4982, -1),
      (4981, 4979),
      (4981, 4982),
      (4981, -1)),
     //Gradient
     ((4989, -1),
      (4990, -1),
      (4991, -1),
      (4992, -1),
      (4991, 4989),
      (4991, 4992),
      (4991, -1))
      //Hard2
     {((569, -1),
      (570, -1),
      (571, -1),
      (572, -1),
      (573, 574),
      (575, 576),
      (577, -1)),}
      //Hard3
     {((569, -1),
      (570, -1),
      (571, -1),
      (572, -1),
      (571, 569),
      (571, 572),
      (571, -1))}
      );

  // Does masks apply Walkable/Buildable restrictions on tile.
  // F.e. mt_2Corner mask does not add any restrictions
//  TILE_MASKS_PASS_RESTRICTIONS: array[mt_2Straight..mt_4Square] of array[TKMTileMaskSubType]
//                            of array[0..1] of Byte =  // (Walkable, Buildable) (0,1): 0 = False/1 = True
//     (((0,1), (0,0)),  // mt_2Straight
//      ((1,1), (0,0)),  // mt_2Diagonal
//      ((0,0), (0,0)),  // mt_2Corner
//      ((0,1), (0,0)),  // mt_2Opposite
//      ((0,0), (0,1)),  // mt_3Straight
//      ((0,0), (0,1)),  // mt_3Opposite
//      ((0,0), (0,0))); // mt_4Square


  TERRAIN_EQUALITY_PAIRS: array[0..1] of record
      TK1, TK2: TKMTerrainKind;
    end =
      (
//        (TK1: tkGold; TK2: tkGoldMount),
//        (TK1: tkIron; TK2: tkIronMount),
        (TK1: tkWater; TK2: tkFastWater),
        (TK1: tkSnowOnGrass; TK2: tkSnowOnDirt)
      );


  // Terrain tiles animation mapping
  // code generated via Batcher on anim tiles numbers at rev ~13000
var
  TERRAIN_ANIM: array [0..MAX_TILE_TO_SHOW-1] of TKMTileAnim;// =
//    (
//      (Layers: (
//        (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)),
//        (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)),
//        (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)))),
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 0
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 1
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 2
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 3
//      (Count: 8; Frames: 1; Anims: (5001, 5002, 5003, 5004, 5005, 5006, 5007, 5008,    0,    0,    0,    0)), // 4
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 5
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 6
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 7
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 8
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 9
//
//      (Count: 8; Frames: 1; Anims: (5009, 5010, 5011, 5012, 5013, 5014, 5015, 5016,    0,    0,    0,    0)), // 10
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 11
//      (Count: 8; Frames: 1; Anims: (5017, 5018, 5019, 5020, 5021, 5022, 5023, 5024,    0,    0,    0,    0)), // 12
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 13
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 14
//      (Count: 3; Frames: 8; Anims: (5025, 5026, 5027,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 15
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 16
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 17
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 18
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 19
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 20
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 21
//      (Count: 8; Frames: 1; Anims: (5028, 5029, 5030, 5031, 5032, 5033, 5034, 5035,    0,    0,    0,    0)), // 22
//      (Count: 8; Frames: 1; Anims: (5036, 5037, 5038, 5039, 5040, 5041, 5042, 5043,    0,    0,    0,    0)), // 23
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 24
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 25
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 26
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 27
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 28
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 29
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 30
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 31
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 32
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 33
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 34
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 35
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 36
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 37
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 38
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 39
//
//      (Count: 3; Frames: 8; Anims: (5044, 5045, 5046,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 40
//      (Count: 3; Frames: 8; Anims: (5047, 5048, 5049,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 41
//      (Count: 3; Frames: 8; Anims: (5050, 5051, 5052,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 42
//      (Count: 3; Frames: 8; Anims: (5053, 5054, 5055,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 43
//      (Count: 8; Frames: 1; Anims: (5056, 5057, 5058, 5059, 5060, 5061, 5062, 5063,    0,    0,    0,    0)), // 44
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 45
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 46
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 47
//      (Count: 8; Frames: 1; Anims: (5064, 5065, 5066, 5067, 5068, 5069, 5070, 5071,    0,    0,    0,    0)), // 48
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 49
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 50
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 51
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 52
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 53
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 54
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 55
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 56
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 57
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 58
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 59
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 60
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 61
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 62
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 63
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 64
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 65
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 66
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 67
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 68
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 69
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 70
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 71
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 72
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 73
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 74
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 75
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 76
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 77
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 78
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 79
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 80
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 81
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 82
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 83
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 84
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 85
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 86
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 87
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 88
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 89
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 90
//      (Count: 3; Frames: 8; Anims: (5072, 5073, 5074,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 91
//      (Count: 3; Frames: 8; Anims: (5075, 5076, 5077,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 92
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 93
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 94
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 95
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 96
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 97
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 98
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 99
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 100
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 101
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 102
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 103
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 104
//      (Count: 8; Frames: 1; Anims: (5078, 5079, 5080, 5081, 5082, 5083, 5084, 5085,    0,    0,    0,    0)), // 105
//      (Count: 8; Frames: 1; Anims: (5086, 5087, 5088, 5089, 5090, 5091, 5092, 5093,    0,    0,    0,    0)), // 106
//      (Count: 8; Frames: 1; Anims: (5094, 5095, 5096, 5097, 5098, 5099, 5100, 5101,    0,    0,    0,    0)), // 107
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 108
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 109
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 110
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 111
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 112
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 113
//      (Count: 8; Frames: 1; Anims: (5102, 5103, 5104, 5105, 5106, 5107, 5108, 5109,    0,    0,    0,    0)), // 114
//      (Count: 8; Frames: 1; Anims: (5110, 5111, 5112, 5113, 5114, 5115, 5116, 5117,    0,    0,    0,    0)), // 115
//      (Count: 8; Frames: 1; Anims: (5118, 5119, 5120, 5121, 5122, 5123, 5124, 5125,    0,    0,    0,    0)), // 116
//      (Count: 8; Frames: 1; Anims: (5126, 5127, 5128, 5129, 5130, 5131, 5132, 5133,    0,    0,    0,    0)), // 117
//      (Count: 8; Frames: 1; Anims: (5134, 5135, 5136, 5137, 5138, 5139, 5140, 5141,    0,    0,    0,    0)), // 118
//      (Count: 8; Frames: 1; Anims: (5142, 5143, 5144, 5145, 5146, 5147, 5148, 5149,    0,    0,    0,    0)), // 119
//
//      (Count: 8; Frames: 1; Anims: (5150, 5151, 5152, 5153, 5154, 5155, 5156, 5157,    0,    0,    0,    0)), // 120
//      (Count: 8; Frames: 1; Anims: (5158, 5159, 5160, 5161, 5162, 5163, 5164, 5165,    0,    0,    0,    0)), // 121
//      (Count: 8; Frames: 1; Anims: (5166, 5167, 5168, 5169, 5170, 5171, 5172, 5173,    0,    0,    0,    0)), // 122
//      (Count: 8; Frames: 1; Anims: (5174, 5175, 5176, 5177, 5178, 5179, 5180, 5181,    0,    0,    0,    0)), // 123
//      (Count: 8; Frames: 1; Anims: (5182, 5183, 5184, 5185, 5186, 5187, 5188, 5189,    0,    0,    0,    0)), // 124
//      (Count: 8; Frames: 1; Anims: (5190, 5191, 5192, 5193, 5194, 5195, 5196, 5197,    0,    0,    0,    0)), // 125
//      (Count: 8; Frames: 1; Anims: (5198, 5199, 5200, 5201, 5202, 5203, 5204, 5205,    0,    0,    0,    0)), // 126
//      (Count: 8; Frames: 1; Anims: (5206, 5207, 5208, 5209, 5210, 5211, 5212, 5213,    0,    0,    0,    0)), // 127
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 128
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 129
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 130
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 131
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 132
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 133
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 134
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 135
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 136
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 137
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 138
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 139
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 140
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 141
//      (Count: 8; Frames: 1; Anims: (5214, 5215, 5216, 5217, 5218, 5219, 5220, 5221,    0,    0,    0,    0)), // 142
//      (Count: 8; Frames: 1; Anims: (5222, 5223, 5224, 5225, 5226, 5227, 5228, 5229,    0,    0,    0,    0)), // 143
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 144
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 145
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 146
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 147
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 148
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 149
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 150
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 151
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 152
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 153
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 154
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 155
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 156
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 157
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 158
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 159
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 160
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 161
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 162
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 163
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 164
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 165
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 166
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 167
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 168
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 169
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 170
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 171
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 172
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 173
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 174
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 175
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 176
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 177
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 178
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 179
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 180
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 181
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 182
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 183
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 184
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 185
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 186
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 187
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 188
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 189
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 190
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 191
//      (Count: 8; Frames: 1; Anims: (5230, 5231, 5232, 5233, 5234, 5235, 5236, 5237,    0,    0,    0,    0)), // 192
//      (Count: 8; Frames: 1; Anims: (5238, 5239, 5240, 5241, 5242, 5243, 5244, 5245,    0,    0,    0,    0)), // 193
//      (Count: 8; Frames: 1; Anims: (5246, 5247, 5248, 5249, 5250, 5251, 5252, 5253,    0,    0,    0,    0)), // 194
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 195
//      (Count: 8; Frames: 1; Anims: (5254, 5255, 5256, 5257, 5258, 5259, 5260, 5261,    0,    0,    0,    0)), // 196
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 197
//      (Count: 8; Frames: 1; Anims: (5262, 5263, 5264, 5265, 5266, 5267, 5268, 5269,    0,    0,    0,    0)), // 198
//      (Count: 8; Frames: 1; Anims: (5270, 5271, 5272, 5273, 5274, 5275, 5276, 5277,    0,    0,    0,    0)), // 199
//
//      (Count: 8; Frames: 1; Anims: (5278, 5279, 5280, 5281, 5282, 5283, 5284, 5285,    0,    0,    0,    0)), // 200
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 201
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 202
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 203
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 204
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 205
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 206
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 207
//      (Count: 8; Frames: 1; Anims: (5286, 5287, 5288, 5289, 5290, 5291, 5292, 5293,    0,    0,    0,    0)), // 208
//      (Count: 8; Frames: 1; Anims: (5294, 5295, 5296, 5297, 5298, 5299, 5300, 5301,    0,    0,    0,    0)), // 209
//
//      (Count: 8; Frames: 1; Anims: (5302, 5303, 5304, 5305, 5306, 5307, 5308, 5309,    0,    0,    0,    0)), // 210
//      (Count: 8; Frames: 1; Anims: (5310, 5311, 5312, 5313, 5314, 5315, 5316, 5317,    0,    0,    0,    0)), // 211
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 212
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 213
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 214
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 215
//      (Count: 8; Frames: 1; Anims: (5318, 5319, 5320, 5321, 5322, 5323, 5324, 5325,    0,    0,    0,    0)), // 216
//      (Count: 5; Frames: 1; Anims: (5326, 5327, 5328, 5329, 5330,    0,    0,    0,    0,    0,    0,    0)), // 217
//      (Count: 5; Frames: 1; Anims: (5331, 5332, 5333, 5334, 5335,    0,    0,    0,    0,    0,    0,    0)), // 218
//      (Count: 5; Frames: 1; Anims: (5336, 5337, 5338, 5339, 5340,    0,    0,    0,    0,    0,    0,    0)), // 219
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 220
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 221
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 222
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 223
//      (Count: 8; Frames: 1; Anims: (5341, 5342, 5343, 5344, 5345, 5346, 5347, 5348,    0,    0,    0,    0)), // 224
//      (Count: 5; Frames: 1; Anims: (5349, 5350, 5351, 5352, 5353,    0,    0,    0,    0,    0,    0,    0)), // 225
//      (Count: 5; Frames: 1; Anims: (5354, 5355, 5356, 5357, 5358,    0,    0,    0,    0,    0,    0,    0)), // 226
//      (Count: 5; Frames: 1; Anims: (5359, 5360, 5361, 5362, 5363,    0,    0,    0,    0,    0,    0,    0)), // 227
//      (Count: 5; Frames: 1; Anims: (5364, 5365, 5366, 5367, 5368,    0,    0,    0,    0,    0,    0,    0)), // 228
//      (Count: 5; Frames: 1; Anims: (5369, 5370, 5371, 5372, 5373,    0,    0,    0,    0,    0,    0,    0)), // 229
//
//      (Count: 8; Frames: 1; Anims: (5374, 5375, 5376, 5377, 5378, 5379, 5380, 5381,    0,    0,    0,    0)), // 230
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 231
//      (Count: 8; Frames: 1; Anims: (5382, 5383, 5384, 5385, 5386, 5387, 5388, 5389,    0,    0,    0,    0)), // 232
//      (Count: 8; Frames: 1; Anims: (5390, 5391, 5392, 5393, 5394, 5395, 5396, 5397,    0,    0,    0,    0)), // 233
//      (Count: 8; Frames: 1; Anims: (5398, 5399, 5400, 5401, 5402, 5403, 5404, 5405,    0,    0,    0,    0)), // 234
//      (Count: 8; Frames: 1; Anims: (5406, 5407, 5408, 5409, 5410, 5411, 5412, 5413,    0,    0,    0,    0)), // 235
//      (Count: 8; Frames: 1; Anims: (5414, 5415, 5416, 5417, 5418, 5419, 5420, 5421,    0,    0,    0,    0)), // 236
//      (Count: 8; Frames: 1; Anims: (5422, 5423, 5424, 5425, 5426, 5427, 5428, 5429,    0,    0,    0,    0)), // 237
//      (Count: 8; Frames: 1; Anims: (5430, 5431, 5432, 5433, 5434, 5435, 5436, 5437,    0,    0,    0,    0)), // 238
//      (Count: 8; Frames: 1; Anims: (5438, 5439, 5440, 5441, 5442, 5443, 5444, 5445,    0,    0,    0,    0)), // 239
//
//      (Count: 8; Frames: 1; Anims: (5446, 5447, 5448, 5449, 5450, 5451, 5452, 5453,    0,    0,    0,    0)), // 240
//      (Count: 8; Frames: 1; Anims: (5454, 5455, 5456, 5457, 5458, 5459, 5460, 5461,    0,    0,    0,    0)), // 241
//      (Count: 8; Frames: 1; Anims: (5462, 5463, 5464, 5465, 5466, 5467, 5468, 5469,    0,    0,    0,    0)), // 242
//      (Count: 8; Frames: 1; Anims: (5470, 5471, 5472, 5473, 5474, 5475, 5476, 5477,    0,    0,    0,    0)), // 243
//      (Count: 8; Frames: 1; Anims: (5478, 5479, 5480, 5481, 5482, 5483, 5484, 5485,    0,    0,    0,    0)), // 244
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 245
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 246
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 247
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 248
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 249
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 250
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 251
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 252
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 253
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 254
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 255
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 256
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 257
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 258
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 259
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 260
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 261
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 262
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 263
//      (Count: 8; Frames: 1; Anims: (5486, 5487, 5488, 5489, 5490, 5491, 5492, 5493,    0,    0,    0,    0)), // 264
//      (Count: 8; Frames: 1; Anims: (5494, 5495, 5496, 5497, 5498, 5499, 5500, 5501,    0,    0,    0,    0)), // 265
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 266
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 267
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 268
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 269
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 270
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 271
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 272
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 273
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 274
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 275
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 276
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 277
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 278
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 279
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 280
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 281
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 282
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 283
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 284
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 285
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 286
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 287
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 288
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 289
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 290
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 291
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 292
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 293
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 294
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 295
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 296
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 297
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 298
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 299
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 300
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 301
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 302
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 303
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 304
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 305
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 306
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 307
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 308
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 309
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 310
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 311
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 312
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 313
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 314
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 315
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 316
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 317
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 318
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 319
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 320
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 321
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 322
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 323
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 324
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 325
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 326
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 327
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 328
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 329
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 330
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 331
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 332
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 333
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 334
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 335
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 336
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 337
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 338
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 339
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 340
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 341
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 342
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 343
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 344
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 345
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 346
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 347
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 348
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 349
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 350
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 351
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 352
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 353
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 354
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 355
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 356
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 357
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 358
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 359
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 360
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 361
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 362
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 363
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 364
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 365
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 366
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 367
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 368
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 369
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 370
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 371
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 372
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 373
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 374
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 375
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 376
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 377
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 378
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 379
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 380
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 381
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 382
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 383
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 384
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 385
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 386
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 387
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 388
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 389
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 390
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 391
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 392
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 393
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 394
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 395
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 396
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 397
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 398
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 399
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 400
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 401
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 402
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 403
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 404
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 405
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 406
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 407
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 408
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 409
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 410
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 411
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 412
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 413
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 414
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 415
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 416
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 417
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 418
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 419
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 420
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 421
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 422
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 423
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 424
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 425
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 426
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 427
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 428
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 429
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 430
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 431
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 432
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 433
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 434
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 435
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 436
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 437
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 438
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 439
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 440
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 441
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 442
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 443
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 444
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 445
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 446
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 447
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 448
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 449
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 450
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 451
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 452
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 453
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 454
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 455
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 456
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 457
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 458
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 459
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 460
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 461
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 462
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 463
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 464
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 465
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 466
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 467
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 468
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 469
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 470
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 471
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 472
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 473
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 474
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 475
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 476
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 477
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 478
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 479
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 480
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 481
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 482
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 483
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 484
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 485
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 486
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 487
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 488
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 489
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 490
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 491
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 492
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 493
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 494
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 495
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 496
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 497
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 498
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 499
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 500
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 501
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 502
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 503
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 504
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 505
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 506
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 507
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 508
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 509
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 510
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 511
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 512
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 513
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 514
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 515
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 516
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 517
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 518
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 519
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 520
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 521
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 522
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 523
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 524
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 525
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 526
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 527
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 528
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 529
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 530
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 531
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 532
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 533
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 534
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 535
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 536
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 537
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 538
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 539
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 540
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 541
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 542
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 543
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 544
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 545
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 546
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 547
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 548
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 549
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 550
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 551
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 552
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 553
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 554
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 555
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 556
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 557
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 558
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 559
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 560
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 561
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 562
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 563
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 564
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 565
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 566
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 567
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 568
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 569
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 570
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 571
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 572
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 573
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 574
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 575
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 576
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 577
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 578
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 579
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 580
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 581
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 582
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 583
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 584
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 585
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 586
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 587
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 588
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 589
//
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 590
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 591
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 592
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 593
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 594
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0)), // 595
//      (Count: 0; Frames: 1; Anims: (   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0))  // 596
//    );

const
  TILE_CORNERS_TERRAIN_KINDS: array [0..MAX_TILE_TO_SHOW-1]
                  of array[0..3] //Corners: LeftTop - RightTop - RightBottom - LeftBottom
                    of TKMTerrainKind = (
  (tkGrass,tkGrass,tkGrass,tkGrass), (tkGrass,tkGrass,tkGrass,tkGrass), (tkGrass,tkGrass,tkGrass,tkGrass),
  (tkGrass,tkGrass,tkGrass,tkGrass),
   //4
  (tkIce,tkIce,tkSnow,tkSnow),
  (tkGrass,tkGrass,tkGrass,tkGrass), (tkGrass,tkGrass,tkGrass,tkGrass),
   //7
  (tkLava,tkLava,tkLava,tkLava),
   //8
  (tkMoss,tkMoss,tkMoss,tkMoss), (tkMoss,tkMoss,tkMoss,tkMoss),
  //10
  (tkSnow,tkIce,tkSnow,tkSnow),      (tkGrass,tkGrass,tkGrass,tkGrass), (tkIce,tkIce,tkWater,tkWater),
  (tkGrass,tkGrass,tkGrass,tkGrass), (tkGrass,tkGrass,tkGrass,tkGrass), (tkGoldMount,tkLava,tkLava,tkLava),
   //16
  (tkPaleGrass,tkPaleGrass,tkPaleGrass,tkPaleGrass), (tkPaleGrass,tkPaleGrass,tkPaleGrass,tkPaleGrass),
  (tkGrass,tkGrass,tkMoss,tkMoss),   (tkMoss,tkGrass,tkMoss,tkMoss),    //??? not sure if they are good there
   //20
  (tkGravel,tkGravel,tkGravel,tkGravel), (tkGravel,tkGravel,tkGravel,tkGravel), (tkWater,tkIce,tkWater,tkWater),
  (tkIce,tkIce,tkIce,tkWater),           (tkCustom,tkCustom,tkCustom,tkCustom), (tkCustom,tkCustom,tkCustom,tkCustom),
   //26
  (tkGrassSand1,tkGrassSand1,tkGrassSand1,tkGrassSand1), (tkGrassSand2,tkGrassSand2,tkGrassSand2,tkGrassSand2),
  (tkGrassSand3,tkGrassSand3,tkGrassSand3,tkGrassSand3), (tkSand,tkSand,tkSand,tkSand),
   //30
  (tkSand,tkSand,tkSand,tkSand),                         (tkCoastSand,tkCoastSand,tkCoastSand,tkCoastSand),
  (tkCoastSand,tkCoastSand,tkCoastSand,tkCoastSand),     (tkCoastSand,tkCoastSand,tkCoastSand,tkCoastSand),
   //34
  (tkGrassDirt,tkGrassDirt,tkGrassDirt,tkGrassDirt),     (tkDirt,tkDirt,tkDirt,tkDirt), (tkDirt,tkDirt,tkDirt,tkDirt),
  (tkDirt,tkDirt,tkDirt,tkDirt),  (tkDirt,tkCobbleStone,tkDirt,tkDirt), (tkCobbleStone,tkCobbleStone,tkDirt,tkDirt),
   //40
  (tkSwamp,tkSwamp,tkSwamp,tkSwamp), (tkSwamp,tkSwamp,tkSwamp,tkSwamp), (tkSwamp,tkSwamp,tkSwamp,tkSwamp), (tkSwamp,tkSwamp,tkSwamp,tkSwamp),
  (tkIce,tkIce,tkIce,tkIce), (tkDeepSnow,tkDeepSnow,tkDeepSnow,tkDeepSnow), (tkSnow,tkSnow,tkSnow,tkSnow),
  (tkSnowOnDirt,tkSnowOnDirt,tkSnowOnDirt,tkSnowOnDirt),
   //48
  (tkGrassyWater,tkGrassyWater,tkGrassyWater,tkGrassyWater), (tkSnowOnDirt,tkSnowOnDirt,tkSnowOnDirt,tkGoldMount),
  (tkAbyss,tkAbyss,tkIronMount,tkIronMount),                 (tkGoldMount,tkSnowOnDirt,tkGoldMount,tkGoldMount),
   //52
  (tkSnow,tkIronMount,tkSnow,tkSnow), (tkIronMount,tkIronMount,tkIronMount,tkAbyss), (tkIronMount,tkIronMount,tkIronMount,tkSnow),
  (tkCustom,tkCustom,tkCustom,tkCustom), // Wine
   //56
  (tkGrass,tkDirt,tkGrass,tkGrass),(tkDirt,tkDirt,tkGrass,tkGrass), (tkDirt,tkDirt,tkDirt,tkGrass),
  (tkCustom,tkCustom,tkCustom,tkCustom), // Corn
   //60
  (tkCustom,tkCustom,tkCustom,tkCustom), (tkCustom,tkCustom,tkCustom,tkCustom), // Corn
  (tkCustom,tkCustom,tkCustom,tkCustom), (tkCustom,tkCustom,tkCustom,tkCustom), // Corn
   //64
  (tkSnowOnDirt,tkSnowOnDirt,tkDirt,tkDirt), (tkSnowOnDirt,tkSnowOnDirt,tkSnowOnDirt,tkDirt),
   //66
  (tkGrass,tkPaleGrass,tkGrass,tkGrass), (tkPaleGrass,tkPaleGrass,tkGrass,tkGrass), (tkPaleGrass,tkPaleGrass,tkPaleGrass,tkGrass),
   //69
  (tkGrass,tkCoastSand,tkGrass,tkGrass), (tkCoastSand,tkCoastSand,tkGrass,tkGrass), (tkCoastSand,tkCoastSand,tkCoastSand,tkGrass),
   //72
  (tkGrass,tkGrassSand1,tkGrass,tkGrass), (tkGrassSand1,tkGrassSand1,tkGrass,tkGrass), (tkGrassSand1,tkGrassSand1,tkGrassSand1,tkGrass),
   //75
  (tkGrassSand1,tkGrassSand2,tkGrassSand1,tkGrassSand1),(tkGrassSand2,tkGrassSand2,tkGrassSand1,tkGrassSand1),(tkGrassSand2,tkGrassSand2,tkGrassSand2,tkGrassSand1),
   //78
  (tkGrassSand2,tkGrassSand3,tkGrassSand2,tkGrassSand2),(tkGrassSand3,tkGrassSand3,tkGrassSand2,tkGrassSand2),(tkGrassSand3,tkGrassSand3,tkGrassSand3,tkGrassSand2),
   //81
  (tkGrassSand2,tkSand,tkGrassSand3,tkGrassSand3),(tkSand,tkSand,tkGrassSand3,tkGrassSand3),(tkSand,tkSand,tkSand,tkGrassSand3),
   //84
  (tkGrass,tkGrassDirt,tkGrass,tkGrass), (tkGrassDirt,tkGrassDirt,tkGrass,tkGrass), (tkGrassDirt,tkGrassDirt,tkGrassDirt,tkGrass),
   //87
  (tkGrassDirt,tkDirt,tkGrassDirt,tkGrassDirt), (tkDirt,tkDirt,tkGrassDirt,tkGrassDirt), (tkDirt,tkDirt,tkDirt,tkGrassDirt),
   //90
  (tkGrass,tkSwamp,tkGrass,tkGrass), (tkSwamp,tkSwamp,tkGrass,tkGrass), (tkSwamp,tkSwamp,tkSwamp,tkGrass),
   //93
  (tkGrass,tkGrassSand3,tkGrass,tkGrass), (tkGrassSand3,tkGrassSand3,tkGrass,tkGrass), (tkGrassSand3,tkGrassSand3,tkGrassSand3,tkGrass),
   //96
  (tkGrassDirt,tkPaleGrass,tkGrassDirt,tkGrassDirt), (tkPaleGrass,tkPaleGrass,tkGrassDirt,tkGrassDirt), (tkPaleGrass,tkPaleGrass,tkPaleGrass,tkGrassDirt),
   //99
  (tkCoastSand,tkSand,tkCoastSand,tkCoastSand), (tkSand,tkSand,tkCoastSand,tkCoastSand), (tkSand,tkSand,tkSand,tkCoastSand),
   //102
  (tkCoastSand,tkGrassSand2,tkCoastSand,tkCoastSand),(tkGrassSand2,tkGrassSand2,tkCoastSand,tkCoastSand),(tkGrassSand2,tkGrassSand2,tkGrassSand2,tkCoastSand),
   //105
  (tkWater,tkDirt,tkWater,tkWater), (tkDirt,tkDirt,tkWater,tkWater), (tkDirt,tkDirt,tkDirt,tkWater),
   //108
  (tkCoastSand,tkIronMount,tkCoastSand,tkCoastSand),(tkIronMount,tkIronMount,tkCoastSand,tkCoastSand),(tkIronMount,tkIronMount,tkIronMount,tkCoastSand),
   //111
  (tkDirt,tkCoastSand,tkDirt,tkDirt), (tkCoastSand,tkCoastSand,tkDirt,tkDirt), (tkCoastSand,tkCoastSand,tkCoastSand,tkDirt),
   //114
  (tkGrassyWater,tkWater,tkGrassyWater,tkGrassyWater), (tkWater,tkWater,tkGrassyWater,tkGrassyWater),
   //116
  (tkCoastSand,tkWater,tkCoastSand,tkCoastSand), (tkCoastSand,tkCoastSand,tkWater,tkWater), (tkWater,tkWater,tkWater,tkCoastSand),
   //119
  (tkWater,tkWater,tkWater,tkGrassyWater),
   //120
  (tkGrass,tkGrassyWater,tkGrass,tkGrass), (tkGrassyWater,tkGrassyWater,tkGrass,tkGrass), (tkGrassyWater,tkGrassyWater,tkGrassyWater,tkGrass),
   //123
  (tkGrass,tkWater,tkGrass,tkGrass), (tkGrass,tkGrass,tkWater,tkWater), (tkGrass,tkGrass,tkWater,tkWater),
  (tkWater,tkWater,tkWater,tkGrass), (tkWater,tkWater,tkWater,tkGrass),
   //128
  (tkStone,tkStone,tkStone,tkStone),(tkStone,tkStone,tkStone,tkStone),(tkStone,tkStone,tkStone,tkStone),
  (tkStone,tkStone,tkStone,tkStone),(tkStone,tkStone,tkStone,tkStone),(tkStone,tkStone,tkStone,tkStone),
  (tkStone,tkStone,tkStone,tkStone),(tkStone,tkStone,tkStone,tkStone),(tkStone,tkStone,tkStone,tkStone),
  (tkStone,tkStone,tkStone,tkStone),
   //138
  (tkStone,tkStone,tkStone,tkGrass), (tkStone,tkStone,tkGrass,tkGrass),
   //140
  (tkStone,tkStone,tkStone,tkStone), (tkStone,tkStone,tkStone,tkStone),
   //142
  (tkStone,tkStone,tkWater,tkStone), (tkStone,tkStone,tkStone,tkWater),
   //144
  (tkGoldMount,tkGold,tkGoldMount,tkGoldMount),(tkGold,tkGold,tkGoldMount,tkGoldMount), (tkGold,tkGold,tkGold,tkGoldMount),
   //147
  (tkGold,tkGold,tkGold,tkGold),
   //148
  (tkIronMount,tkIron,tkIronMount,tkIronMount), (tkIron,tkIron,tkIronMount,tkIronMount), (tkIron,tkIron,tkIron,tkIronMount),
   //151
  (tkIron,tkIron,tkIron,tkIron),
   //152
  (tkDirt,tkCoal,tkDirt,tkDirt), (tkCoal,tkCoal,tkDirt,tkDirt), (tkCoal,tkCoal,tkCoal,tkDirt),
   //155
  (tkCoal,tkCoal,tkCoal,tkCoal),
   //156
  (tkGoldMount,tkGoldMount,tkGoldMount,tkGoldMount), (tkGoldMount,tkGoldMount,tkGoldMount,tkGoldMount),
  (tkGoldMount,tkGoldMount,tkGoldMount,tkGoldMount), (tkGoldMount,tkGoldMount,tkGoldMount,tkGoldMount),
   //160
  (tkIronMount,tkIronMount,tkIronMount,tkIronMount), (tkIronMount,tkIronMount,tkIronMount,tkIronMount),
  (tkIronMount,tkIronMount,tkIronMount,tkIronMount), (tkIronMount,tkIronMount,tkIronMount,tkIronMount),
  (tkIronMount,tkIronMount,tkIronMount,tkIronMount),
   //165
  (tkAbyss,tkIronMount,tkAbyss,tkAbyss),
   //166
  (tkIronMount,tkIronMount,tkSnow,tkSnow), (tkIronMount,tkIronMount,tkDirt,tkDirt),
   //168
  (tkIronMount,tkIronMount,tkGrass,tkGrass), (tkIronMount,tkIronMount,tkCoastSand,tkCoastSand),
   //170
  (tkIronMount,tkIronMount,tkGrassSand2,tkGrassSand2),
   //171
  (tkGoldMount,tkGoldMount,tkSnowOnDirt,tkSnowOnDirt), (tkGoldMount,tkGoldMount,tkGrass,tkGrass),
   //173
  (tkGoldMount,tkGoldMount,tkCoastSand,tkCoastSand), (tkGoldMount,tkGoldMount,tkGrassSand2,tkGrassSand2),
  (tkGoldMount,tkGoldMount,tkDirt,tkDirt),
   //176
  (tkGoldMount,tkGoldMount,tkGoldMount,tkGrass),(tkGoldMount,tkGoldMount,tkGoldMount,tkCoastSand),
  (tkGoldMount,tkGoldMount,tkGoldMount,tkGrassSand2), (tkGoldMount,tkGoldMount,tkGoldMount,tkDirt),
   //180
  (tkGrass,tkGoldMount,tkGrass,tkGrass), (tkCoastSand,tkGoldMount,tkCoastSand,tkCoastSand),
  (tkGrassSand2,tkGoldMount,tkGrassSand2,tkGrassSand2), (tkDirt,tkGoldMount,tkDirt,tkDirt),
   //184
  (tkIronMount,tkIronMount,tkIronMount,tkGrass), (tkIronMount,tkCoastSand,tkIronMount,tkIronMount),
  (tkIronMount,tkGrassSand2,tkIronMount,tkIronMount), (tkIronMount,tkIronMount,tkIronMount,tkDirt),
   //188
  (tkGrass,tkIronMount,tkGrass,tkGrass), (tkCoastSand,tkIronMount,tkCoastSand,tkCoastSand),
   //190
  (tkGrassSand2,tkIronMount,tkGrassSand2,tkGrassSand2), (tkDirt,tkIronMount,tkDirt,tkDirt),
   //192
  (tkWater,tkWater,tkWater,tkWater), (tkWater,tkWater,tkWater,tkWater), (tkWater,tkWater,tkWater,tkWater),
   //195
  (tkStone,tkStone,tkStone,tkStone), (tkWater,tkWater,tkWater,tkWater),
   //197
  (tkCobbleStone,tkCobbleStone,tkCobbleStone,tkCobbleStone),
  (tkCustom,tkCustom,tkCustom,tkWater), (tkCustom,tkCustom,tkWater,tkCustom),
   //200
  (tkWater,tkWater,tkWater,tkWater),//(?)
  (tkGoldMount,tkGoldMount,tkGoldMount,tkGoldMount), (tkCustom,tkCustom,tkCustom,tkCustom),
   //203
  (tkSnow,tkDeepSnow,tkSnow,tkSnow), (tkDeepSnow,tkDeepSnow,tkSnow,tkSnow), (tkDeepSnow,tkDeepSnow,tkDeepSnow,tkSnow),
   //206
  (tkCustom,tkCustom,tkCustom,tkCustom), (tkCustom,tkCustom,tkCustom,tkCustom),
   //208
  (tkWater,tkWater,tkWater,tkWater), (tkFastWater,tkFastWater,tkFastWater,tkFastWater),
   //210
  (tkWater,tkWater,tkWater,tkWater),(tkWater,tkWater,tkWater,tkWater),//(?)
   //212
  (tkSnow,tkSnow,tkSnowOnDirt,tkSnowOnDirt), (tkSnow,tkSnow,tkSnow,tkSnowOnDirt),
   //214
  (tkCustom,tkCustom,tkCustom,tkCustom), (tkCobbleStone,tkCobbleStone,tkCobbleStone,tkCobbleStone),
   //216
  (tkCustom,tkCustom,tkCustom,tkCustom), (tkCustom,tkCustom,tkCustom,tkCustom),
  (tkCustom,tkCustom,tkCustom,tkCustom), (tkCustom,tkCustom,tkCustom,tkCustom),
   //220
  (tkSnowOnDirt,tkSnow,tkSnowOnDirt,tkSnowOnDirt),
   //221
  (tkCustom,tkCustom,tkCustom,tkCustom), (tkCustom,tkCustom,tkCustom,tkCustom), (tkCustom,tkCustom,tkCustom,tkCustom),
  (tkCustom,tkCustom,tkCustom,tkCustom), (tkCustom,tkCustom,tkCustom,tkCustom), (tkCustom,tkCustom,tkCustom,tkCustom),
  (tkCustom,tkCustom,tkCustom,tkCustom), (tkCustom,tkCustom,tkCustom,tkCustom), (tkCustom,tkCustom,tkCustom,tkCustom),
   //230
  (tkCustom,tkCustom,tkWater,tkWater), (tkCustom,tkCustom,tkAbyss,tkAbyss),
  (tkCustom,tkCustom,tkWater,tkWater), (tkCustom,tkCustom,tkWater,tkWater),
   //234
  (tkGoldMount,tkGoldMount,tkWater,tkGoldMount), (tkGoldMount,tkWater,tkWater,tkWater),
  (tkWater,tkGoldMount,tkWater,tkWater), (tkGoldMount,tkGoldMount,tkGoldMount,tkWater),
   //238
  (tkIronMount,tkIronMount,tkWater,tkIronMount), (tkIronMount,tkWater,tkIronMount,tkIronMount),
   //240
  (tkWater,tkWater,tkWater,tkWater),
   //241
  (tkWater, tkGrassSand2,tkWater,tkWater), (tkGrassSand2,tkGrassSand2,tkWater,tkWater), (tkGrassSand2,tkGrassSand2,tkGrassSand2,tkWater),
   //244
  (tkFastWater,tkFastWater,tkFastWater,tkFastWater), (tkAbyss,tkAbyss,tkAbyss,tkAbyss), (tkCustom,tkCustom,tkCustom,tkCustom),
   //247
  (tkDirt,tkSnowOnDirt,tkDirt,tkDirt),
  (tkCustom,tkCustom,tkCustom,tkCustom), (tkCustom,tkCustom,tkCustom,tkCustom), (tkCustom,tkCustom,tkCustom,tkCustom), (tkCustom,tkCustom,tkCustom,tkCustom),
  (tkCustom,tkCustom,tkCustom,tkCustom), (tkCustom,tkCustom,tkCustom,tkCustom), (tkCustom,tkCustom,tkCustom,tkCustom), (tkCustom,tkCustom,tkCustom,tkCustom),
   //256
  (tkSnowOnDirt,tkIronMount,tkSnowOnDirt,tkSnowOnDirt),(tkIronMount,tkIronMount,tkSnowOnDirt,tkSnowOnDirt), (tkIronMount,tkIronMount,tkIronMount,tkSnowOnDirt),
   //259
  (tkIron,tkIron,tkIron,tkIron), (tkIron,tkIron,tkIron,tkIron),
   //261
  (tkSnow,tkGoldMount,tkSnow,tkSnow), (tkGoldMount,tkGoldMount,tkSnow,tkSnow),
   //263
  (tkCoal,tkCoal,tkCoal,tkCoal), (tkCustom,tkCustom,tkCustom,tkIce), (tkCustom,tkCustom,tkIce,tkCustom),
   //266
  (tkStone,tkStone,tkStone,tkStone), (tkStone,tkStone,tkStone,tkStone),
  (tkStone,tkStone,tkStone,tkCoastSand), (tkStone,tkStone,tkCoastSand,tkCoastSand),
  (tkStone,tkStone,tkStone,tkStone), (tkStone,tkStone,tkStone,tkStone), (tkStone,tkStone,tkStone,tkStone),
  (tkCoastSand,tkStone,tkCoastSand,tkCoastSand),
   //274
  (tkGrass,tkStone,tkGrass,tkGrass),
   //275
  (tkStone,tkStone,tkStone,tkStone), (tkStone,tkStone,tkStone,tkStone),
  (tkStone,tkStone,tkStone,tkDirt), (tkStone,tkStone,tkDirt,tkDirt),
  (tkStone,tkStone,tkStone,tkStone), (tkStone,tkStone,tkStone,tkStone), (tkStone,tkStone,tkStone,tkStone),
  (tkDirt,tkStone,tkDirt,tkDirt),
   //283
  (tkStone,tkStone,tkStone,tkStone), (tkStone,tkStone,tkStone,tkStone),
  (tkStone,tkStone,tkStone,tkSnow), (tkStone,tkStone,tkSnow,tkSnow),
  (tkStone,tkStone,tkStone,tkStone), (tkStone,tkStone,tkStone,tkStone), (tkStone,tkStone,tkStone,tkStone),
  (tkSnow,tkStone,tkSnow,tkSnow),
   //291
  (tkStone,tkStone,tkStone,tkStone), (tkStone,tkStone,tkStone,tkStone),
  (tkStone,tkStone,tkStone,tkSnowOnDirt), (tkStone,tkStone,tkSnowOnDirt,tkSnowOnDirt),
  (tkStone,tkStone,tkStone,tkStone), (tkStone,tkStone,tkStone,tkStone), (tkStone,tkStone,tkStone,tkStone),
  (tkSnowOnDirt,tkStone,tkSnowOnDirt,tkSnowOnDirt),
   //299
  (tkGoldMount,tkIronMount,tkGoldMount,tkGoldMount), (tkIronMount,tkIronMount,tkLava,tkIronMount),
   //301
  (tkStone,tkStone,tkGrass,tkGrass), (tkStone,tkStone,tkCoastSand,tkCoastSand),
  (tkStone,tkStone,tkDirt,tkDirt),
   //304
  (tkStone,tkStone,tkSnow,tkSnow), (tkStone,tkStone,tkSnowOnDirt,tkSnowOnDirt),(tkGoldMount,tkGoldMount,tkGoldMount,tkSnow),
   //307
  (tkGold,tkGold,tkGold,tkGold),
   //308
  (tkStone,tkStone,tkDirt,tkDirt),(tkStone,tkStone,tkStone,tkDirt),
   //310
  (tkStone,tkStone,tkStone,tkStone),(tkStone,tkStone,tkStone,tkStone),
   //312
  (tkSnowOnGrass,tkSnowOnDirt,tkSnowOnGrass,tkSnowOnGrass),(tkSnowOnDirt,tkSnowOnDirt,tkSnowOnGrass,tkSnowOnGrass),
  (tkSnowOnDirt,tkSnowOnDirt,tkSnowOnDirt,tkSnowOnGrass),
   //315
  (tkSnowOnGrass,tkSnowOnGrass,tkSnowOnGrass,tkSnowOnGrass),(tkGrass,tkSnowOnGrass,tkGrass,tkGrass),
  (tkSnowOnGrass,tkSnowOnGrass,tkGrass,tkGrass),(tkSnowOnGrass,tkSnowOnGrass,tkSnowOnGrass,tkGrass),
   //319
  (tkCoastSand,tkGrassSand3,tkCoastSand,tkCoastSand),(tkGrassSand3,tkGrassSand3,tkCoastSand,tkCoastSand),(tkGrassSand3,tkGrassSand3,tkGrassSand3,tkCoastSand),
   //322
  (tkGoldMount,tkIronMount,tkGoldMount,tkGoldMount),(tkIronMount,tkIronMount,tkGoldMount,tkGoldMount),(tkIronMount,tkIronMount,tkIronMount,tkGoldMount),
   //325
  (tkGold,tkIron,tkGold,tkGold),(tkIron,tkIron,tkGold,tkGold),(tkIron,tkIron,tkIron,tkGold),
   //328
  (tkIronMount,tkIron,tkIronMount,tkIronMount),(tkIron,tkIron,tkIronMount,tkIronMount),(tkIron,tkIron,tkIron,tkIronMount),
   //331
  (tkStone,tkIronMount,tkStone,tkStone),(tkIronMount,tkIronMount,tkStone,tkStone),(tkIronMount,tkIronMount,tkIronMount,tkStone),
   //334
  (tkStone,tkIron,tkStone,tkStone),(tkIron,tkIron,tkStone,tkStone),(tkIron,tkIron,tkIron,tkStone),
   //337
  (tkGrass,tkIron,tkGrass,tkGrass),(tkIron,tkIron,tkGrass,tkGrass),(tkIron,tkIron,tkIron,tkGrass),
   //340
  (tkStone,tkGoldMount,tkStone,tkStone),(tkGoldMount,tkGoldMount,tkStone,tkStone),(tkGoldMount,tkGoldMount,tkGoldMount,tkStone),
   //343
  (tkStone,tkGold,tkStone,tkStone),(tkGold,tkGold,tkStone,tkStone),(tkGold,tkGold,tkGold,tkStone),
   //346
  (tkGoldMount,tkAbyss,tkGoldMount,tkGoldMount),(tkAbyss,tkAbyss,tkGoldMount,tkGoldMount),(tkAbyss,tkAbyss,tkAbyss,tkGoldMount),
   //349
  (tkCustom,tkCustom,tkCustom,tkCustom), (tkCustom,tkCustom,tkCustom,tkCustom),
   //351
  (tkGrassDirt,tkGoldMount,tkGrassDirt,tkGrassDirt), (tkGoldMount,tkGoldMount,tkGrassDirt,tkGrassDirt), (tkGoldMount,tkGoldMount,tkGoldMount,tkGrassDirt),
   //354
  (tkGrassDirt,tkIronMount,tkGrassDirt,tkGrassDirt), (tkIronMount,tkIronMount,tkGrassDirt,tkGrassDirt), (tkIronMount,tkIronMount,tkIronMount,tkGrassDirt),
   //357
  (tkGoldMount,tkGoldMount,tkDirt,tkGrass), (tkGoldMount,tkGoldMount,tkGrass,tkDirt), (tkGoldMount,tkGoldMount,tkDirt,tkGrass), (tkGoldMount,tkGoldMount,tkGrass,tkDirt),
   //361
  (tkGrass,tkGoldMount,tkDirt,tkGrass), (tkDirt,tkGoldMount,tkGrass,tkDirt), (tkGrass,tkGoldMount,tkDirt,tkDirt), (tkDirt,tkGoldMount,tkGrass,tkDirt),
   //365
  (tkGoldMount,tkDirt,tkDirt,tkGrass), (tkGoldMount,tkGrass,tkGrass,tkDirt), (tkGoldMount,tkGrass,tkDirt,tkDirt), (tkGoldMount,tkDirt,tkDirt,tkGrass),
   //369
  (tkIronMount,tkIronMount,tkDirt,tkGrass), (tkIronMount,tkIronMount,tkGrass,tkDirt), (tkIronMount,tkIronMount,tkDirt,tkGrass), (tkIronMount,tkIronMount,tkGrass,tkDirt),
   //373
  (tkGrass,tkIronMount,tkDirt,tkGrass), (tkDirt,tkIronMount,tkGrass,tkDirt), (tkGrass,tkIronMount,tkDirt,tkDirt), (tkDirt,tkIronMount,tkGrass,tkDirt),
   //377
  (tkIronMount,tkDirt,tkDirt,tkGrass), (tkIronMount,tkGrass,tkGrass,tkDirt), (tkIronMount,tkDirt,tkDirt,tkGrass), (tkIronMount,tkGrass,tkDirt,tkDirt),
   //381
  (tkGoldMount,tkGoldMount,tkGrass,tkGrass), (tkGoldMount,tkGoldMount,tkDirt,tkDirt), (tkDirt,tkGoldMount,tkGrass,tkGrass), (tkGrass,tkGoldMount,tkDirt,tkDirt),
   //385
  (tkGoldMount,tkGrass,tkDirt,tkDirt),(tkGoldMount,tkDirt,tkGrass,tkGrass), (tkIronMount,tkIronMount,tkGrass,tkGrass), (tkIronMount,tkIronMount,tkDirt,tkDirt),
   //389
  (tkDirt,tkIronMount,tkGrass,tkGrass), (tkIronMount,tkDirt,tkGrass,tkGrass), (tkGrass,tkIronMount,tkDirt,tkDirt),(tkIronMount,tkGrass,tkDirt,tkDirt),
   //393
  (tkGoldMount,tkGoldMount,tkDirt,tkGrass), (tkGoldMount,tkGoldMount,tkGrass,tkDirt), (tkGoldMount,tkGoldMount,tkDirt,tkDirt),(tkGoldMount,tkGoldMount,tkDirt,tkDirt),
   //397
  (tkDirt,tkGoldMount,tkDirt,tkGrass), (tkDirt,tkGoldMount,tkGrass,tkDirt), (tkGrass,tkGoldMount,tkDirt,tkDirt),(tkDirt,tkGoldMount,tkDirt,tkDirt),
   //401
  (tkGoldMount,tkDirt,tkDirt,tkGrass), (tkGoldMount,tkDirt,tkGrass,tkDirt), (tkGoldMount,tkDirt,tkDirt,tkDirt),(tkGoldMount,tkGrass,tkDirt,tkDirt),
   //405
  (tkIronMount,tkIronMount,tkDirt,tkGrass), (tkIronMount,tkIronMount,tkGrass,tkDirt), (tkIronMount,tkIronMount,tkDirt,tkDirt),(tkIronMount,tkIronMount,tkDirt,tkDirt),
   //409
  (tkDirt,tkIronMount,tkDirt,tkGrass), (tkDirt,tkIronMount,tkGrass,tkDirt), (tkGrass,tkIronMount,tkDirt,tkDirt),(tkDirt,tkIronMount,tkDirt,tkDirt),
   //413
  (tkIronMount,tkDirt,tkDirt,tkGrass), (tkIronMount,tkDirt,tkGrass,tkDirt), (tkIronMount,tkDirt,tkDirt,tkDirt),(tkIronMount,tkGrass,tkDirt,tkDirt),
   //417
  (tkGoldMount,tkGoldMount,tkDirt,tkDirt),(tkGoldMount,tkGoldMount,tkSnowOnDirt,tkSnowOnDirt), (tkSnowOnDirt,tkGoldMount,tkDirt,tkDirt), (tkGoldMount,tkSnowOnDirt,tkDirt,tkDirt),
   //421
  (tkDirt,tkGoldMount,tkSnowOnDirt,tkSnowOnDirt), (tkGoldMount,tkDirt,tkSnowOnDirt,tkSnowOnDirt), (tkIronMount,tkIronMount,tkDirt,tkDirt),(tkIronMount,tkIronMount,tkSnowOnDirt,tkSnowOnDirt),
   //425
  (tkSnowOnDirt,tkIronMount,tkDirt,tkDirt), (tkIronMount,tkSnowOnDirt,tkDirt,tkDirt), (tkDirt,tkIronMount,tkSnowOnDirt,tkSnowOnDirt), (tkIronMount,tkDirt,tkSnowOnDirt,tkSnowOnDirt),
   //429
  (tkGoldMount,tkGoldMount,tkSnowOnDirt,tkDirt), (tkGoldMount,tkGoldMount,tkDirt,tkSnowOnDirt), (tkGoldMount,tkGoldMount,tkSnowOnDirt,tkSnowOnDirt), (tkGoldMount,tkGoldMount,tkSnowOnDirt,tkSnowOnDirt),
   //433
  (tkSnowOnDirt,tkGoldMount,tkSnowOnDirt,tkDirt), (tkSnowOnDirt,tkGoldMount,tkDirt,tkSnowOnDirt), (tkSnowOnDirt,tkGoldMount,tkSnowOnDirt,tkSnowOnDirt), (tkDirt,tkGoldMount,tkSnowOnDirt,tkSnowOnDirt),
   //437
  (tkGoldMount,tkSnowOnDirt,tkSnowOnDirt,tkDirt), (tkGoldMount,tkSnowOnDirt,tkDirt,tkSnowOnDirt), (tkGoldMount,tkSnowOnDirt,tkSnowOnDirt,tkSnowOnDirt), (tkGoldMount,tkDirt,tkSnowOnDirt,tkSnowOnDirt),
   //441
   (tkIronMount,tkIronMount,tkSnowOnDirt,tkDirt), (tkIronMount,tkIronMount,tkDirt,tkSnowOnDirt), (tkIronMount,tkIronMount,tkSnowOnDirt,tkSnowOnDirt), (tkIronMount,tkIronMount,tkSnowOnDirt,tkSnowOnDirt),
   //445
  (tkSnowOnDirt,tkIronMount,tkSnowOnDirt,tkDirt), (tkSnowOnDirt,tkIronMount,tkDirt,tkSnowOnDirt), (tkSnowOnDirt,tkIronMount,tkSnowOnDirt,tkSnowOnDirt), (tkDirt,tkIronMount,tkSnowOnDirt,tkSnowOnDirt),
   //449
  (tkIronMount,tkSnowOnDirt,tkSnowOnDirt,tkDirt), (tkIronMount,tkSnowOnDirt,tkDirt,tkSnowOnDirt), (tkIronMount,tkSnowOnDirt,tkSnowOnDirt,tkSnowOnDirt), (tkIronMount,tkDirt,tkSnowOnDirt,tkSnowOnDirt),
   //453
  (tkGoldMount,tkGoldMount,tkGrass,tkGrass), (tkGoldMount,tkGoldMount,tkGrass,tkGrass), (tkGoldMount,tkGoldMount,tkCoastSand,tkGrass), (tkGoldMount,tkGoldMount,tkGrass,tkCoastSand),
   //457
  (tkGrass,tkGoldMount,tkGrass,tkGrass), (tkCoastSand,tkGoldMount,tkGrass,tkGrass), (tkGrass,tkGoldMount,tkCoastSand,tkGrass), (tkGrass,tkGoldMount,tkGrass,tkCoastSand),
   //461
  (tkGoldMount,tkCoastSand,tkGrass,tkGrass), (tkGoldMount,tkGrass,tkGrass,tkGrass), (tkGoldMount,tkGrass,tkGrass,tkCoastSand), (tkGoldMount,tkGrass,tkCoastSand,tkGrass),
   //465
  (tkIronMount,tkIronMount,tkGrass,tkGrass), (tkIronMount,tkIronMount,tkGrass,tkGrass), (tkIronMount,tkIronMount,tkCoastSand,tkGrass), (tkIronMount,tkIronMount,tkGrass,tkCoastSand),
   //469
  (tkGrass,tkIronMount,tkGrass,tkGrass), (tkCoastSand,tkIronMount,tkGrass,tkGrass), (tkGrass,tkIronMount,tkCoastSand,tkGrass), (tkGrass,tkIronMount,tkGrass,tkCoastSand),
   //473
  (tkIronMount,tkCoastSand,tkGrass,tkGrass), (tkIronMount,tkGrass,tkGrass,tkGrass), (tkIronMount,tkGrass,tkGrass,tkCoastSand), (tkIronMount,tkGrass,tkCoastSand,tkGrass),
   //477
  (tkGoldMount,tkGoldMount,tkGrass,tkGrass), (tkGoldMount,tkGoldMount,tkCoastSand,tkCoastSand), (tkCoastSand,tkGoldMount,tkGrass,tkGrass), (tkGrass,tkGoldMount,tkCoastSand,tkCoastSand),
   //481
  (tkGoldMount,tkGrass,tkCoastSand,tkCoastSand),(tkGoldMount,tkCoastSand,tkGrass,tkGrass), (tkIronMount,tkIronMount,tkGrass,tkGrass), (tkIronMount,tkIronMount,tkCoastSand,tkCoastSand),
   //485
  (tkCoastSand,tkIronMount,tkGrass,tkGrass), (tkIronMount,tkCoastSand,tkGrass,tkGrass), (tkGrass,tkIronMount,tkCoastSand,tkCoastSand),(tkIronMount,tkGrass,tkCoastSand,tkCoastSand),
   //489
  (tkGoldMount,tkGoldMount,tkCoastSand,tkGrass), (tkGoldMount,tkGoldMount,tkGrass,tkCoastSand), (tkGoldMount,tkGoldMount,tkCoastSand,tkCoastSand),(tkGoldMount,tkGoldMount,tkCoastSand,tkCoastSand),
   //493
  (tkCoastSand,tkGoldMount,tkCoastSand,tkGrass), (tkCoastSand,tkGoldMount,tkGrass,tkCoastSand), (tkGrass,tkGoldMount,tkCoastSand,tkCoastSand),(tkCoastSand,tkGoldMount,tkCoastSand,tkCoastSand),
   //497
  (tkGoldMount,tkCoastSand,tkCoastSand,tkGrass), (tkGoldMount,tkCoastSand,tkGrass,tkCoastSand), (tkGoldMount,tkCoastSand,tkCoastSand,tkCoastSand),(tkGoldMount,tkGrass,tkCoastSand,tkCoastSand),
   //501
  (tkIronMount,tkIronMount,tkCoastSand,tkGrass), (tkIronMount,tkIronMount,tkGrass,tkCoastSand), (tkIronMount,tkIronMount,tkCoastSand,tkCoastSand),(tkIronMount,tkIronMount,tkCoastSand,tkCoastSand),
   //505
  (tkCoastSand,tkIronMount,tkCoastSand,tkGrass), (tkCoastSand,tkIronMount,tkGrass,tkCoastSand), (tkGrass,tkIronMount,tkCoastSand,tkCoastSand),(tkCoastSand,tkIronMount,tkCoastSand,tkCoastSand),
   //509
  (tkIronMount,tkCoastSand,tkCoastSand,tkGrass), (tkIronMount,tkCoastSand,tkGrass,tkCoastSand), (tkIronMount,tkCoastSand,tkCoastSand,tkCoastSand),(tkIronMount,tkGrass,tkCoastSand,tkCoastSand),
   //513
  (tkGoldMount,tkGoldMount,tkDirt,tkDirt), (tkGoldMount,tkGoldMount,tkDirt,tkDirt), (tkGoldMount,tkGoldMount,tkCoastSand,tkDirt), (tkGoldMount,tkGoldMount,tkDirt,tkCoastSand),
   //517
  (tkDirt,tkGoldMount,tkDirt,tkDirt), (tkCoastSand,tkGoldMount,tkDirt,tkDirt), (tkDirt,tkGoldMount,tkCoastSand,tkDirt), (tkDirt,tkGoldMount,tkDirt,tkCoastSand),
   //521
  (tkGoldMount,tkCoastSand,tkDirt,tkDirt), (tkGoldMount,tkDirt,tkDirt,tkDirt), (tkGoldMount,tkDirt,tkDirt,tkCoastSand), (tkGoldMount,tkDirt,tkCoastSand,tkDirt),
   //525
  (tkIronMount,tkIronMount,tkDirt,tkDirt), (tkIronMount,tkIronMount,tkDirt,tkDirt), (tkIronMount,tkIronMount,tkCoastSand,tkDirt), (tkIronMount,tkIronMount,tkDirt,tkCoastSand),
   //529
  (tkDirt,tkIronMount,tkDirt,tkDirt), (tkCoastSand,tkIronMount,tkDirt,tkDirt), (tkDirt,tkIronMount,tkCoastSand,tkDirt), (tkDirt,tkIronMount,tkDirt,tkCoastSand),
   //533
  (tkIronMount,tkCoastSand,tkDirt,tkDirt), (tkIronMount,tkDirt,tkDirt,tkDirt), (tkIronMount,tkDirt,tkDirt,tkCoastSand), (tkIronMount,tkDirt,tkCoastSand,tkDirt),
   //537
  (tkGoldMount,tkDirt,tkCoastSand,tkCoastSand),(tkGoldMount,tkCoastSand,tkDirt,tkDirt), (tkIronMount,tkIronMount,tkDirt,tkDirt), (tkIronMount,tkIronMount,tkCoastSand,tkCoastSand),
   //541
  (tkCoastSand,tkIronMount,tkDirt,tkDirt), (tkIronMount,tkCoastSand,tkDirt,tkDirt), (tkDirt,tkIronMount,tkCoastSand,tkCoastSand),(tkIronMount,tkDirt,tkCoastSand,tkCoastSand),
   //545
  (tkGoldMount,tkGoldMount,tkCoastSand,tkDirt), (tkGoldMount,tkGoldMount,tkDirt,tkCoastSand), (tkGoldMount,tkGoldMount,tkCoastSand,tkCoastSand),(tkGoldMount,tkGoldMount,tkCoastSand,tkCoastSand),
   //549
   (tkGoldMount,tkGoldMount,tkCoastSand,tkDirt), (tkGoldMount,tkGoldMount,tkDirt,tkCoastSand), (tkGoldMount,tkGoldMount,tkCoastSand,tkCoastSand),(tkGoldMount,tkGoldMount,tkCoastSand,tkCoastSand),
   //553
  (tkCoastSand,tkGoldMount,tkCoastSand,tkDirt), (tkCoastSand,tkGoldMount,tkDirt,tkCoastSand), (tkDirt,tkGoldMount,tkCoastSand,tkCoastSand),(tkCoastSand,tkGoldMount,tkCoastSand,tkCoastSand),
   //557
  (tkGoldMount,tkCoastSand,tkCoastSand,tkDirt), (tkGoldMount,tkCoastSand,tkDirt,tkCoastSand), (tkGoldMount,tkCoastSand,tkCoastSand,tkCoastSand),(tkGoldMount,tkDirt,tkCoastSand,tkCoastSand),
   //561
  (tkIronMount,tkIronMount,tkCoastSand,tkDirt), (tkIronMount,tkIronMount,tkDirt,tkCoastSand), (tkIronMount,tkIronMount,tkCoastSand,tkCoastSand),(tkIronMount,tkIronMount,tkCoastSand,tkCoastSand),
   //565
  (tkCoastSand,tkIronMount,tkCoastSand,tkDirt), (tkCoastSand,tkIronMount,tkDirt,tkCoastSand), (tkDirt,tkIronMount,tkCoastSand,tkCoastSand),(tkCoastSand,tkIronMount,tkCoastSand,tkCoastSand),
   //569
  (tkIronMount,tkCoastSand,tkCoastSand,tkDirt), (tkIronMount,tkCoastSand,tkDirt,tkCoastSand), (tkIronMount,tkCoastSand,tkCoastSand,tkCoastSand),(tkIronMount,tkDirt,tkCoastSand,tkCoastSand),
   //573
  (tkGoldMount,tkGoldMount,tkDirt,tkDirt), (tkGoldMount,tkGoldMount,tkDirt,tkDirt), (tkGoldMount,tkGoldMount,tkSnowOnDirt,tkDirt), (tkGoldMount,tkGoldMount,tkDirt,tkSnowOnDirt),
   //577
  (tkDirt,tkGoldMount,tkDirt,tkDirt), (tkSnowOnDirt,tkGoldMount,tkDirt,tkDirt), (tkDirt,tkGoldMount,tkSnowOnDirt,tkDirt), (tkDirt,tkGoldMount,tkDirt,tkSnowOnDirt),
   //579
  (tkGoldMount,tkSnowOnDirt,tkDirt,tkDirt), (tkGoldMount,tkDirt,tkDirt,tkDirt), (tkGoldMount,tkDirt,tkDirt,tkSnowOnDirt), (tkGoldMount,tkDirt,tkSnowOnDirt,tkDirt),
   //585
  (tkIronMount,tkIronMount,tkDirt,tkDirt), (tkIronMount,tkIronMount,tkDirt,tkDirt), (tkIronMount,tkIronMount,tkSnowOnDirt,tkDirt), (tkIronMount,tkIronMount,tkDirt,tkSnowOnDirt),
   //589
  (tkDirt,tkIronMount,tkDirt,tkDirt), (tkSnowOnDirt,tkIronMount,tkDirt,tkDirt), (tkDirt,tkIronMount,tkSnowOnDirt,tkDirt), (tkDirt,tkIronMount,tkDirt,tkSnowOnDirt),
   //593
  (tkIronMount,tkSnowOnDirt,tkDirt,tkDirt), (tkIronMount,tkDirt,tkDirt,tkDirt), (tkIronMount,tkDirt,tkDirt,tkSnowOnDirt), (tkIronMount,tkDirt,tkSnowOnDirt,tkDirt)
  );

implementation


{ TKMTileAnim }
function TKMTileAnim.HasAnim: Boolean;
var
  I: Integer;
begin
  if LayersCnt = 0 then Exit(False);
  
  Result := False;
  
  for I := 0 to LayersCnt - 1 do
    Result := Result or Layers[I].HasAnim;
end;


{ TKMTileAnimLayer }
function TKMTileAnimLayer.HasAnim: Boolean;
begin
  Result := Count > 0;
end;


function TKMTileAnimLayer.GetAnim(aAnimStep: Integer): Word;
begin
  if Count = 0 then Exit(0);
  Assert(Frames > 0, 'Frames = 0!');

  Result := Anims[(aAnimStep div Frames) mod Count];

  if Result = 0 then Exit;

  // -1 because of difference in 0-based and 1-based in tiles numbering 
  // todo: refactor it to 0-based
  Dec(Result); 
end;

end.
