unit KM_ResTileset;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, KromUtils,
  KM_Defaults, KM_CommonTypes;


const
  TILES_CNT = 597;
  MAX_TILE_TO_SHOW = TILES_CNT;
  MAX_STATIC_TERRAIN_ID = 9997;

type
  //TKMTileProperty = set of (tpWalkable, tpRoadable);

  TKMTileMaskType = (mtNone,
    mt_2Straight, // A A
                  // B B

    mt_2Diagonal, // A A
                  // B A

    mt_2Corner,   // A B
                  // B B

    mt_2Opposite, // A B
                  // B A

    mt_3Straight, // A A
                  // C D

    mt_3Opposite, // A B
                  // D A

    mt_4Square);  // A B
                  // D C

  TKMTileMaskSubType = (mstMain, mstExtra);

  TKMTileMaskKind = (mkNone, mkSoft1, mkSoft2, mkSoft3, mkStraight);

  TKMMaskFullType = record
    Kind: TKMTileMaskKind;
    MType: TKMTileMaskType;
    SubType: TKMTileMaskSubType;
  end;

  PKMMaskFullType = ^TKMMaskFullType;

  TKMTerrainKind = (
//    tkNone,
    tkCustom,
    tkGrass,
    tkMoss,
    tkPaleGrass,
    tkCoastSand,
    tkGrassSand1,
    tkGrassSand2,
    tkGrassSand3,
    tkSand,       //8
    tkGrassDirt,
    tkDirt,       //10
    tkCobbleStone,
    tkGrassyWater,//12
    tkSwamp,      //13
    tkIce,        //14
    tkSnowOnGrass,
    tkSnowOnDirt,
    tkSnow,
    tkDeepSnow,
    tkStone,
    tkGoldMount,
    tkIronMount,  //21
    tkAbyss,
    tkGravel,
    tkCoal,
    tkGold,
    tkIron,
    tkWater,
    tkFastWater,
    tkLava);


  TKMTerrainKindsArray = array of TKMTerrainKind;

  TKMTerrainKindSet = set of TKMTerrainKind;

  TKMTerrainKindCorners = array[0..3] of TKMTerrainKind;

const
  TER_KIND_ORDER: array[tkCustom..tkLava] of Integer =
    (0,1,2,3,4,5,6,7,8,9,10,11,
      -1,    // To make Water/FastWater-GrassyWater transition possible with layers we need GrassyWater to be above Water because of animation (water above grassy anim looks ugly)
      13,
      -2,
      15,16,17,18,19,20,21,22,23,24,25,26,
      -4,-3, // Put GrassyWater/Water/FastWater always to the base layer, because of animation
      28);

  BASE_TERRAIN: array[TKMTerrainKind] of Word = //tkCustom..tkLava] of Word =
    (0, 0, 8, 17, 32, 26, 27, 28, 29, 34, 35, 215, 48, 40, 44, 315, 47, 46, 45, 132, 159, 164, 245, 20, 155, 147, 151, 192, 209, 7);

//  TILE_MASKS: array[mt_2Straight..mt_4Square] of Word =
//      (279, 278, 280, 281, 282, 277);

  TILE_MASKS_LAYERS_CNT: array[TKMTileMaskType] of Byte =
    (1, 2, 2, 2, 2, 3, 3, 4);

  TILE_MASK_KINDS_PREVIEW: array[TKMTileMaskKind] of Integer =
    (-1, 5551, 5561, 5571, 5581); //+1 here, so -1 is no image, and not grass

  TILE_MASKS_FOR_LAYERS: array[mkSoft1..mkStraight] of array[mt_2Straight..mt_4Square] of array[TKMTileMaskSubType] of Integer =
     //Softest
    (((5549, -1),
      (5550, -1),
      (5551, -1),
      (5552, -1),
      (5551, 5549),
      (5551, 5552),
      (5551, -1)),
     //Soft
     ((5559, -1),
      (5560, -1),
      (5561, -1),
      (5562, -1),
      (5561, 5559),
      (5561, 5562),
      (5561, -1)),
     //Soft2
     ((5569, -1),
      (5570, -1),
      (5571, -1),
      (5572, -1),
      (5571, 5569),
      (5571, 5572),
      (5571, -1)),
     //Hard
     ((5579, -1),
      (5580, -1),
      (5581, -1),
      (5582, -1),
      (5581, 5579),
      (5581, 5582),
      (5581, -1))
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

var
  // Mirror tiles arrays, according to the tiles corners terrain kinds
  // If no mirror tile is found, then self tile is set by default
  // for tiles below 256 we set default tiles (themselfs)
  ResTileset_MirrorTilesH: array [0..TILES_CNT-1] of Integer; // mirror horisontally
  ResTileset_MirrorTilesV: array [0..TILES_CNT-1] of Integer; // mirror vertically

type
  TKMResTileset = class
  private
    fCRC: Cardinal;
    TileTable: array [1 .. 30, 1 .. 30] of packed record
      Tile1, Tile2, Tile3: Byte;
      b1, b2, b3, b4, b5, b6, b7: Boolean;
    end;

    function GetTerKindsCnt(aTile: Word): Integer;

    function LoadPatternDAT(const FileName: string): Boolean;
    procedure InitRemakeTiles;
  public
    PatternDAT: array [1..TILES_CNT] of packed record
      MinimapColor: Byte;
      Walkable: Byte;  //This looks like a bitfield, but everything besides <>0 seems to have no logical explanation
      Buildable: Byte; //This looks like a bitfield, but everything besides <>0 seems to have no logical explanation
      u1: Byte; // 1/2/4/8/16 bitfield, seems to have no logical explanation
      u2: Byte; // 0/1 Boolean? seems to have no logical explanation
      u3: Byte; // 1/2/4/8 bitfield, seems to have no logical explanation
    end;

    TileColor: TRGBArray;

    constructor Create(const aPatternPath: string);

    property CRC: Cardinal read fCRC;

    procedure ExportPatternDat(const aFilename: string);

    function TileIsWater(aTile: Word): Boolean;
    function TileHasWater(aTile: Word): Boolean;
    function TileIsIce(aTile: Word): Boolean;
    function TileIsSand(aTile: Word): Boolean;
    function TileIsStone(aTile: Word): Word;
    function TileIsSnow(aTile: Word): Boolean;
    function TileIsCoal(aTile: Word): Word;
    function TileIsIron(aTile: Word): Word;
    function TileIsGold(aTile: Word): Word;
    function TileIsSoil(aTile: Word): Boolean;
    function TileIsWalkable(aTile: Word): Boolean;
    function TileIsRoadable(aTile: Word): Boolean;
    function TileIsCornField(aTile: Word): Boolean;
    function TileIsWineField(aTile: Word): Boolean;
    function TileIsFactorable(aTile: Word): Boolean;

    function TileIsGoodForIronMine(aTile: Word): Boolean;
    function TileIsGoodForGoldMine(aTile: Word): Boolean;

    function TileIsCorner(aTile: Word): Boolean;
    function TileIsEdge(aTile: Word): Boolean;

    class function TileIsAllowedToSet(aTile: Word): Boolean;
  end;


implementation
uses
  KM_CommonUtils, KM_CommonClassesExt;

const
  TILES_NOT_ALLOWED_TO_SET: array [0..16] of Word = (
    55,59,60,61,62,63,              // wine and corn
    189,169,185,                    // duplicates of 108,109,110
    248,249,250,251,252,253,254,255 // roads and overlays
  );


{ TKMResTileset }
constructor TKMResTileset.Create(const aPatternPath: string);
begin
  inherited Create;

  LoadPatternDAT(aPatternPath);
  InitRemakeTiles;
end;


procedure TKMResTileset.InitRemakeTiles;
const
  //ID in png_name
  WALK_BUILD:     array[0..185] of Integer = (257,262,264,274,275,283,291,299,302,303,304,305,306,313,314,315,316,317,318,319,//20
                                              320,321,322,338,352,355,362,363,364,365,366,367,368,369,374,375,376,377,378,379,//40
                                              380,381,384,385,386,387,390,391,392,393,398,399,400,401,402,403,404,405,410,411,//60
                                              412,413,414,415,416,417,420,421,422,423,426,427,428,429,434,435,436,437,438,439,//80
                                              440,441,446,447,448,449,450,451,452,453,458,459,460,461,462,463,464,465,470,471,//100
                                              472,473,474,475,476,477,480,481,482,483,486,487,488,489,494,495,496,497,498,499,//120
                                              500,501,506,507,508,509,510,511,512,513,518,519,520,521,522,523,524,525,530,531,//140
                                              532,533,534,535,536,537,540,541,542,543,546,547,548,549,554,555,556,557,558,559,//160
                                              560,561,566,567,568,569,570,571,572,573,578,579,580,581,582,583,584,585,590,591,//180
                                              592,593,594,595,596,597);
  WALK_NO_BUILD:   array[0..106] of Integer = (258,263,269,270,271,272,278,279,280,281,286,287,288,289,294,295,296,297,309,310,//20
                                              311,312,339,350,351,353,356,358,359,360,361,370,371,372,373,382,383,388,389,394,//40
                                              395,396,397,406,407,408,409,418,419,424,425,430,431,432,433,442,443,444,445,454,//60
                                              455,456,457,466,467,468,469,478,479,484,485,490,491,492,493,502,503,504,505,514,//80
                                              515,516,517,526,527,528,529,538,539,544,545,550,551,552,553,562,563,564,565,574,//100
                                              575,576,577,586,587,588,589);
  NO_WALK_NO_BUILD: array[0..44] of Integer = (259,260,261,265,266,267,268,273,276,277,282,284,285,290,292,293,298,300,301,307,//20
                                              308,323,324,325,326,327,328,329,330,331,332,333,334,335,336,337,340,341,342,343,//40
                                              344,345,346,354,357);
  MIRROR_TILES_INIT_FROM = 256;
var
  I, J, K: Integer;
  skipH, skipV: Boolean;
begin
  for I := Low(WALK_BUILD) to High(WALK_BUILD) do
  begin
    Assert(WALK_BUILD[I] > 255); //We init only new tiles with ID > 255
    PatternDAT[WALK_BUILD[I]].Walkable := 1;
    PatternDAT[WALK_BUILD[I]].Buildable := 1;
  end;

  for I := Low(WALK_NO_BUILD) to High(WALK_NO_BUILD) do
  begin
    Assert(WALK_NO_BUILD[I] > 255); //We init only new tiles with ID > 255
    PatternDAT[WALK_NO_BUILD[I]].Walkable := 1;
    PatternDAT[WALK_NO_BUILD[I]].Buildable := 0;
  end;

  for I := Low(NO_WALK_NO_BUILD) to High(NO_WALK_NO_BUILD) do
  begin
    Assert(NO_WALK_NO_BUILD[I] > 255); //We init only new tiles with ID > 255
    PatternDAT[NO_WALK_NO_BUILD[I]].Walkable := 0;
    PatternDAT[NO_WALK_NO_BUILD[I]].Buildable := 0;
  end;

  // Init MirrorTilesH and MirrorTilesV
  // We can put into const arrays though, if needed for speedup the process
  for I := Low(TILE_CORNERS_TERRAIN_KINDS) to High(TILE_CORNERS_TERRAIN_KINDS) do
  begin
    skipH := False;
    skipV := False;

    // 'Self' mirror by default
    ResTileset_MirrorTilesH[I] := I;
    ResTileset_MirrorTilesV[I] := I;

    if I < MIRROR_TILES_INIT_FROM then
      Continue;

    // Skip if we have custom terrain here (maybe we can use it too?)
    for J := 0 to 3 do
      if TILE_CORNERS_TERRAIN_KINDS[I][J] = tkCustom then
      begin
        skipH := True;
        skipV := True;
        Break;
      end;

    // Check if mirror tile is needed
    if (TILE_CORNERS_TERRAIN_KINDS[I][0] = TILE_CORNERS_TERRAIN_KINDS[I][1])
      and (TILE_CORNERS_TERRAIN_KINDS[I][2] = TILE_CORNERS_TERRAIN_KINDS[I][3]) then
      skipH := True;

    if (TILE_CORNERS_TERRAIN_KINDS[I][0] = TILE_CORNERS_TERRAIN_KINDS[I][3])
      and (TILE_CORNERS_TERRAIN_KINDS[I][1] = TILE_CORNERS_TERRAIN_KINDS[I][2]) then
      skipV := True;

    // try to find mirror tiles based on corners terrain kinds
    for K := MIRROR_TILES_INIT_FROM to High(TILE_CORNERS_TERRAIN_KINDS) do
    begin
      if skipH and skipV then
        Break;

      if not skipH
        and (TILE_CORNERS_TERRAIN_KINDS[I][0] = TILE_CORNERS_TERRAIN_KINDS[K][1])
        and (TILE_CORNERS_TERRAIN_KINDS[I][1] = TILE_CORNERS_TERRAIN_KINDS[K][0])
        and (TILE_CORNERS_TERRAIN_KINDS[I][2] = TILE_CORNERS_TERRAIN_KINDS[K][3])
        and (TILE_CORNERS_TERRAIN_KINDS[I][3] = TILE_CORNERS_TERRAIN_KINDS[K][2]) then
      begin
        ResTileset_MirrorTilesH[I] := K;
        skipH := True;
      end;

      if not skipV
        and (TILE_CORNERS_TERRAIN_KINDS[I][0] = TILE_CORNERS_TERRAIN_KINDS[K][3])
        and (TILE_CORNERS_TERRAIN_KINDS[I][3] = TILE_CORNERS_TERRAIN_KINDS[K][0])
        and (TILE_CORNERS_TERRAIN_KINDS[I][1] = TILE_CORNERS_TERRAIN_KINDS[K][2])
        and (TILE_CORNERS_TERRAIN_KINDS[I][2] = TILE_CORNERS_TERRAIN_KINDS[K][1]) then
      begin
        ResTileset_MirrorTilesV[I] := K;
        skipV := True;
      end;
    end;
  end;
end;


//Reading pattern data (tile info)
function TKMResTileset.LoadPatternDAT(const FileName: string): Boolean;
var
  I: Integer;
  f: file;
  s: Word;
begin
  Result := false;
  if not FileExists(FileName) then
    Exit;
  AssignFile(f, FileName);
  FileMode := fmOpenRead;
  Reset(f, 1);
  BlockRead(f, PatternDAT[1], 6 * 256);
  for I := 1 to 30 do
  begin
    BlockRead(f, TileTable[I, 1], 30 * 10);
    BlockRead(f, s, 1);
  end;

  CloseFile(f);
  fCRC := Adler32CRC(FileName);

  if WriteResourceInfoToTXT then
    ExportPatternDat(ExeDir + 'Export'+PathDelim+'Pattern.csv');

  Result := true;
end;


procedure TKMResTileset.ExportPatternDat(const aFileName: string);
var
  I, K: Integer;
  ft: TextFile;
begin
  AssignFile(ft, ExeDir + 'Pattern.csv');
  Rewrite(ft);
  Writeln(ft, 'PatternDAT');
  for I := 0 to 15 do
  begin
    for K := 1 to 16 do
      write(ft, inttostr(I * 16 + K), ' ', PatternDAT[I * 16 + K].u1, ';');
    writeln(ft);
  end;
  writeln(ft, 'TileTable');
  for I := 1 to 30 do
  begin
    for K := 1 to 30 do
    begin
      write(ft, inttostr(TileTable[I, K].Tile1) + '_' + inttostr(TileTable[I, K].Tile2) + '_' +
        inttostr(TileTable[I, K].Tile3) + ' ');
      write(ft, inttostr(Word(TileTable[I, K].b1)));
      write(ft, inttostr(Word(TileTable[I, K].b2)));
      write(ft, inttostr(Word(TileTable[I, K].b3)));
      write(ft, inttostr(Word(TileTable[I, K].b4)));
      write(ft, inttostr(Word(TileTable[I, K].b5)));
      write(ft, inttostr(Word(TileTable[I, K].b6)));
      write(ft, inttostr(Word(TileTable[I, K].b7)));
      write(ft, ';');
    end;

    writeln(ft);
  end;
  closefile(ft);
end;


function TKMResTileset.GetTerKindsCnt(aTile: Word): Integer;
var
  I: Integer;
  terKinds: TKMTerrainKindSet;
begin
  terKinds := [];

  for I := 0 to 3 do
    Include(terKinds, TILE_CORNERS_TERRAIN_KINDS[aTile][I]);

  Result := TSet<TKMTerrainKindSet>.Cardinality(terKinds);
end;


function TKMResTileset.TileIsCorner(aTile: Word): Boolean;
const
  CORNERS = [10,15,18,21..23,25,38,49,51..54,56,58,65,66,68..69,71,72,74,78,80,81,83,84,86..87,89,90,92,93,95,96,98,99,
             101,102,104,105,107..108,110..111,113,114,116,118,119,120,122,123,126..127,138,142,143,165,176..193,196,
             202,203,205,213,220,234..241,243,247];
begin
  if aTile in CORNERS then
    Exit(True);

  Result := GetTerKindsCnt(aTile) = 2;
end;


function TKMResTileset.TileIsEdge(aTile: Word): Boolean;
const
  EDGES = [4,12,19,39,50,57,64,67,70,73,76,79,82,85,88,91,94,97,
           100,103,106,109,112,115,117,121,124..125,139,141,166..175,194,198..200,
           204,206..212,216..219,223,224..233,242,244];
begin
  if aTile in EDGES then
    Exit(True);

  Result :=    ((TILE_CORNERS_TERRAIN_KINDS[aTile][0] = TILE_CORNERS_TERRAIN_KINDS[aTile][1])
            and (TILE_CORNERS_TERRAIN_KINDS[aTile][2] = TILE_CORNERS_TERRAIN_KINDS[aTile][3]))
          or   ((TILE_CORNERS_TERRAIN_KINDS[aTile][0] = TILE_CORNERS_TERRAIN_KINDS[aTile][3])
            and (TILE_CORNERS_TERRAIN_KINDS[aTile][1] = TILE_CORNERS_TERRAIN_KINDS[aTile][2]));
end;


// Check if requested tile is water suitable for fish and/or sail. No waterfalls, but swamps/shallow water allowed
function TKMResTileset.TileIsWater(aTile: Word): Boolean;
begin
  Result := aTile in [48,114,115,119,192,193,194,196, 200, 208..211, 235,236, 240,244];
end;


// Check if requested tile has ice
function TKMResTileset.TileIsIce(aTile: Word): Boolean;
begin
  Result := aTile in [4, 10, 12, 22, 23, 44];
end;


// Check if requested tile has any water, including ground-water transitions
function TKMResTileset.TileHasWater(aTile: Word): Boolean;
begin
  Result := aTile in [48,105..107,114..127,142,143,192..194,196,198..200,208..211,230,232..244];
end;


// Check if requested tile is sand suitable for crabs
function TKMResTileset.TileIsSand(aTile: Word): Boolean;
const
  SAND_TILES: array[0..55] of Word =
                (31,32,33,70,71,99,100,102,103,108,109,112,113,116,117,169,173,181,189,269,273,302,319,320,
                 493,494,495,496,497,498,499,500,505,506,507,508,509,510,511,512,553,554,555,556,557,558,
                 559,560,565,566,567,568,569,570,571,572);
begin
  Result := ArrayContains(aTile, SAND_TILES);
end;


// Check if requested tile is Stone and returns Stone deposit
function TKMResTileset.TileIsStone(aTile: Word): Word;
begin
  case aTile of
    132,137: Result := 5;
    131,136: Result := 4;
    130,135: Result := 3;
    129,134,266,267,275,276,283,284,291,292: Result := 2;
    128,133: Result := 1;
    else     Result := 0;
  end;
end;


// Check if requested tile is snow
function TKMResTileset.TileIsSnow(aTile: Word): Boolean;
const
  SNOW_TILES: array[0..46] of Word =
                (45, 46, 47, 49, 52, 64, 65, 166, 171, 203, 204, 205, 212, 213, 220, 256, 257, 261, 262,
                 286, 290, 294, 298, 304, 305, 312,313,314,315,317,318,433,434,435,436,437,438,439,440,
                 445,446,447,448,449,450,451,452);
begin
  Result := ArrayContains(aTile, SNOW_TILES);
end;


function TKMResTileset.TileIsCoal(aTile: Word): Word;
begin
  Result := 0;
  if aTile > 151 then
  begin
    if aTile < 156 then
      Result := aTile - 151
    else
      if aTile = 263 then
        Result := 5;
  end;
end;


function TKMResTileset.TileIsGoodForIronMine(aTile: Word): Boolean;
const
  IRON_MINE_TILES: array[0..58] of Word =
                      (109,166,167,168,169,170,257,338,355,369,370,371,372,387,
                       388,405,406,407,408,423,424,441,442,443,444,465,466,467,
                       468,483,484,501,502,503,504,525,526,527,528,483,484,501,
                       502,503,504,525,526,527,528,543,544,561,562,563,564,585,
                       586,587,588);
begin
  Result := ArrayContains(aTile, IRON_MINE_TILES);
end;


function TKMResTileset.TileIsGoodForGoldMine(aTile: Word): Boolean;
const
  GOLD_MINE_TILES: array[0..46] of Word =
                      (171,172,173,174,175,262,352,357,358,359,360,381,382,393,394,395,
                       396,417,418,429,430,431,432,453,454,455,456,477,478,489,490,491,
                       492,505,513,515,516,537,538,549,550,551,552,573,574,575,576);
begin
  Result := ArrayContains(aTile, GOLD_MINE_TILES);
end;


function TKMResTileset.TileIsIron(aTile: Word): Word;
begin
  Result := 0;
  if aTile > 147 then
  begin
    if aTile < 152 then
      Result := aTile - 147
    else
      case aTile of
        259: Result := 3;
        260: Result := 5;
      end;
  end;
end;


function TKMResTileset.TileIsGold(aTile: Word): Word;
begin
  Result := 0;
  if aTile > 143 then
  begin
    if aTile < 148 then
      Result := aTile - 143
    else
      if aTile = 307 then
        Result := 5;
  end;
end;


// Check if requested tile is soil suitable for fields and trees
function TKMResTileset.TileIsSoil(aTile: Word): Boolean;
const
  SOIL_TILES: array[0..176] of Word =
                (0,1,2,3,5,6, 8,9,11,13,14, 16,17,18,19,20,21, 26,27,28, 34,35,36,37,38,39, 47, 49, 55,56,
                57,58,64,65,66,67,68,69,72,73,74,75,76,77,78,79,80, 84,85,86,87,88,89, 93,94,95,96,97,98,
                180,182,183,188,190,191,220,247,274,282,301,303, 312,313,314,315,316,317,318,337,351,354,
                361,362,363,364,365,366,367,368,373,374,375,376,377,378,379,380,383,384,385,386,389,390,
                391,392,397,398,399,400,401,402,403,404,409,410,411,412,413,414,415,416,419,420,421,422,
                425,426,427,428,433,434,435,436,437,438,439,440,445,446,447,448,449,450,451,452,457,458,
                459,460,461,462,463,464,469,470,471,472,473,474,475,476,577,578,579,580,581,582,583,584,
                589,590,591,592,593,594,595,596);
begin
  Result := ArrayContains(aTile, SOIL_TILES);
end;


// Check if requested tile is generally walkable
function TKMResTileset.TileIsWalkable(aTile: Word): Boolean;
begin
  //Includes 1/2 and 3/4 walkable as walkable
  //Result := Land[Loc.Y,Loc.X].BaseLayer.Terrain in [0..6, 8..11,13,14, 16..22, 25..31, 32..39, 44..47, 49,52,55, 56..63,
  //                                        64..71, 72..79, 80..87, 88..95, 96..103, 104,106..109,111, 112,113,116,117, 123..125,
  //                                        138..139, 152..155, 166,167, 168..175, 180..183, 188..191,
  //                                        197, 203..205,207, 212..215, 220..223, 242,243,247];
  //Values can be 1 or 2, What 2 does is unknown
  Result := PatternDAT[aTile+1].Walkable <> 0;
end;


// Check if requested tile is generally suitable for road building
function TKMResTileset.TileIsRoadable(aTile: Word): Boolean;
begin
  //Do not include 1/2 and 1/4 walkable as roadable
  //Result := Land[Loc.Y,Loc.X].BaseLayer.Terrain in [0..3,5,6, 8,9,11,13,14, 16..21, 26..31, 32..39, 45..47, 49, 52, 55, 56..63,
  //                                        64..71, 72..79, 80..87, 88..95, 96..103, 104,108,111, 112,113,
  //                                        152..155,180..183,188..191,
  //                                        203..205, 212,213,215, 220, 247];
  Result := PatternDAT[aTile+1].Buildable <> 0;
end;


function TKMResTileset.TileIsCornField(aTile: Word): Boolean;
begin
  Result := aTile in [59..63];
end;


function TKMResTileset.TileIsWineField(aTile: Word): Boolean;
begin
  Result := aTile = 55;
end;


//@Deprecated. To be removed when?
function TKMResTileset.TileIsFactorable(aTile: Word): Boolean;
begin
  //List of tiles that cannot be factored (coordinates outside the map return true)
  Result := not (aTile in [7,15,24,50,53,144..151,156..165,198,199,202,206]);
end;


class function TKMResTileset.TileIsAllowedToSet(aTile: Word): Boolean;
begin
  Result := not ArrayContains(aTile, TILES_NOT_ALLOWED_TO_SET);
end;


end.
