unit KM_ResTileset;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, KromUtils,
  KM_Defaults, KM_CommonTypes;


const
  TILES_CNT = 349;
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



  TERRAIN_EQUALITY_PAIRS: array[0..0] of record
      TK1, TK2: TKMTerrainKind;
    end =
      (
//        (TK1: tkGold; TK2: tkGoldMount),
//        (TK1: tkIron; TK2: tkIronMount),
        (TK1: tkWater; TK2: tkFastWater)
      );


  TILE_CORNERS_TERRAIN_KINDS: array [0..MAX_TILE_TO_SHOW-1]
                  of array[0..3] //Corners: LeftTop - RightTop - RightBottom - LeftBottom
                    of TKMTerrainKind = (
  (tkGrass,tkGrass,tkGrass,tkGrass), (tkGrass,tkGrass,tkGrass,tkGrass), (tkGrass,tkGrass,tkGrass,tkGrass),
  (tkGrass,tkGrass,tkGrass,tkGrass), (tkIce,tkIce,tkSnow,tkSnow),       (tkGrass,tkGrass,tkGrass,tkGrass),
  (tkGrass,tkGrass,tkGrass,tkGrass), (tkLava,tkLava,tkLava,tkLava),     (tkMoss,tkMoss,tkMoss,tkMoss),
  (tkMoss,tkMoss,tkMoss,tkMoss),
  //10
  (tkSnow,tkIce,tkSnow,tkSnow),      (tkGrass,tkGrass,tkGrass,tkGrass), (tkIce,tkIce,tkWater,tkWater),
  (tkGrass,tkGrass,tkGrass,tkGrass), (tkGrass,tkGrass,tkGrass,tkGrass), (tkGoldMount,tkLava,tkLava,tkLava),
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
  (tkGrass,tkDirt,tkGrass,tkGrass),
  (tkDirt,tkDirt,tkGrass,tkGrass), (tkDirt,tkDirt,tkDirt,tkGrass),
  (tkCustom,tkCustom,tkCustom,tkCustom), // Corn
   //60
  (tkCustom,tkCustom,tkCustom,tkCustom), (tkCustom,tkCustom,tkCustom,tkCustom), // Corn
  (tkCustom,tkCustom,tkCustom,tkCustom), (tkCustom,tkCustom,tkCustom,tkCustom), // Corn
   //64
  (tkSnowOnDirt,tkSnowOnDirt,tkDirt,tkDirt), (tkSnowOnDirt,tkSnowOnDirt,tkSnowOnDirt,tkDirt),
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
  (tkGoldMount,tkAbyss,tkGoldMount,tkGoldMount),(tkAbyss,tkAbyss,tkGoldMount,tkGoldMount),(tkAbyss,tkAbyss,tkAbyss,tkGoldMount)
  );

type
  TKMResTileset = class
  private
    fCRC: Cardinal;
    TileTable: array [1 .. 30, 1 .. 30] of packed record
      Tile1, Tile2, Tile3: byte;
      b1, b2, b3, b4, b5, b6, b7: boolean;
    end;

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

    class function TileIsAllowedToSet(aTile: Word): Boolean;
  end;


implementation
uses
  KM_CommonUtils;

const
  TILES_NOT_ALLOWED_TO_SET: array[0..16] of Word = (55,59,60,61,62,63, //wine and corn
                                                    189,169,185, //duplicates of 108,109,110
                                                    248,249,250,251,252,253,254,255); //roads and overlays


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
  WalkBuild:     array[0..23] of Integer = (257,262,264,274,275,283,291,299,302,303,304,305,306,313,314,315,316,317,318,319,//20
                                            320,321,322,338);
  WalkNoBuild:   array[0..22] of Integer = (258,263,269,270,271,272,278,279,280,281,286,287,288,289,294,295,296,297,309,310,//20
                                            311,312,339);
  NoWalkNoBuild: array[0..42] of Integer = (259,260,261,265,266,267,268,273,276,277,282,284,285,290,292,293,298,300,301,307,//20
                                            308,323,324,325,326,327,328,329,330,331,332,333,334,335,336,337,340,341,342,343,//40
                                            344,345,346);
var
  I: Integer;
begin
  for I := Low(WalkBuild) to High(WalkBuild) do
  begin
    Assert(WalkBuild[I] > 255); //We init only new tiles with ID > 255
    PatternDAT[WalkBuild[I]].Walkable := 1;
    PatternDAT[WalkBuild[I]].Buildable := 1;
  end;

  for I := Low(WalkNoBuild) to High(WalkNoBuild) do
  begin
    Assert(WalkNoBuild[I] > 255); //We init only new tiles with ID > 255
    PatternDAT[WalkNoBuild[I]].Walkable := 1;
    PatternDAT[WalkNoBuild[I]].Buildable := 0;
  end;

  for I := Low(NoWalkNoBuild) to High(NoWalkNoBuild) do
  begin
    Assert(NoWalkNoBuild[I] > 255); //We init only new tiles with ID > 255
    PatternDAT[NoWalkNoBuild[I]].Walkable := 0;
    PatternDAT[NoWalkNoBuild[I]].Buildable := 0;
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


{Check if requested tile is water suitable for fish and/or sail. No waterfalls, but swamps/shallow water allowed}
function TKMResTileset.TileIsWater(aTile: Word): Boolean;
begin
  Result := aTile in [48,114,115,119,192,193,194,196, 200, 208..211, 235,236, 240,244];
end;


//Check if requested tile has ice
function TKMResTileset.TileIsIce(aTile: Word): Boolean;
begin
  Result := aTile in [4, 10, 12, 22, 23, 44];
end;


//Check if requested tile has any water, including ground-water transitions
function TKMResTileset.TileHasWater(aTile: Word): Boolean;
begin
  Result := aTile in [48,105..107,114..127,142,143,192..194,196,198..200,208..211,230,232..244];
end;


{Check if requested tile is sand suitable for crabs}
function TKMResTileset.TileIsSand(aTile: Word): Boolean;
const
  SAND_TILES: array[0..23] of Word =
                (31,32,33,70,71,99,100,102,103,108,109,112,113,116,117,169,173,181,189,269,273,302,319,320);
begin
  Result := ArrayContains(aTile, SAND_TILES);
end;


{Check if requested tile is Stone and returns Stone deposit}
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


{Check if requested tile is sand suitable for crabs}
function TKMResTileset.TileIsSnow(aTile: Word): Boolean;
const
  SNOW_TILES: array[0..30] of Word =
                (45, 46, 47, 49, 52, 64, 65, 166, 171, 203, 204, 205, 212, 213, 220, 256, 257, 261, 262,
                 286, 290, 294, 298, 304, 305, 312,313,314,315,317,318);
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
begin
  Result := (aTile in [109,166..170]) or (aTile = 338);
end;


function TKMResTileset.TileIsGoodForGoldMine(aTile: Word): Boolean;
begin
  Result := aTile in [171..175];
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


{Check if requested tile is soil suitable for fields and trees}
function TKMResTileset.TileIsSoil(aTile: Word): Boolean;
const
  SOIL_TILES: array[0..79] of Word =
                (0,1,2,3,5,6, 8,9,11,13,14, 16,17,18,19,20,21, 26,27,28, 34,35,36,37,38,39, 47, 49, 55,56,
                57,58,64,65,66,67,68,69,71,72,73,74,75,76,77,78,79,80, 84,85,86,87,88,89, 93,94,95,96,97,98,
                180,182,183,188,190,191,220,247,274,282,301,303, 312,313,314,315,316,317,318,337);
begin
  Result := ArrayContains(aTile, SOIL_TILES);
end;


{Check if requested tile is generally walkable}
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


{Check if requested tile is generally suitable for road building}
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


function TKMResTileset.TileIsFactorable(aTile: Word): Boolean;
begin
  //List of tiles that cannot be factored (coordinates outside the map return true)
  Result := not (aTile in [7,15,24,50,53,144..151,156..165,198,199,202,206])
            and (aTile <> 300);
end;


class function TKMResTileset.TileIsAllowedToSet(aTile: Word): Boolean;
begin
  Result := not ArrayContains(aTile, TILES_NOT_ALLOWED_TO_SET);
end;


end.
