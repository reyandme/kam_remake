unit KM_ResHouses;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, SysUtils,
  KM_CommonClasses, KM_CommonTypes, KM_Defaults,
  KM_ResWares;


type
  TKMHouseType = (htNone, htAny,
    htArmorSmithy,     htArmorWorkshop,   htBakery,        htBarracks,      htButchers,
    htCoalMine,        htFarm,            htFisherHut,     htGoldMine,      htInn,
    htIronMine,        htIronSmithy,      htMarketplace,   htMetallurgists, htMill,
    htQuary,           htSawmill,         htSchool,        htSiegeWorkshop, htStables,
    htStore,           htSwine,           htTannery,       htTownHall,      htWatchTower,
    htWeaponSmithy,    htWeaponWorkshop,  htWineyard,      htWoodcutters    );

  THouseTypeSet = set of TKMHouseType;

const
  HOUSE_MIN = htArmorSmithy;
  HOUSE_MAX = htWoodcutters;
  HOUSE_WORKSHOP = [htWeaponSmithy, htArmorSmithy, htWeaponWorkshop, htArmorWorkshop];

type
  THouseAnim = array [TKMHouseActionType] of TKMAnimLoop;

  THouseBuildSupply = array [1..2,1..6] of packed record MoveX, MoveY: Integer; end;
  THouseSupply = array [1..4, 1..5] of SmallInt;

  //House fields as they are in a DAT file
  TKMHouseDat = packed record
    StonePic, WoodPic, WoodPal, StonePal: SmallInt;
    SupplyIn: THouseSupply;
    SupplyOut: THouseSupply;
    Anim: THouseAnim;
    WoodPicSteps, StonePicSteps: Word;
    a1: SmallInt;
    EntranceOffsetX, EntranceOffsetY: ShortInt;
    EntranceOffsetXpx, EntranceOffsetYpx: ShortInt; //When entering house units go for the door, which is offset by these values
    BuildArea: array [1..10,1..10] of ShortInt;
    WoodCost,StoneCost: Byte;
    BuildSupply: THouseBuildSupply;
    a5,SizeArea: SmallInt;
    SizeX,SizeY,sx2,sy2: ShortInt;
    WorkerWork,WorkerRest: SmallInt;
    ResInput,ResOutput: array [1..4] of ShortInt; //KaM_Remake will use its own tables for this matter
    ResProductionX: ShortInt;
    MaxHealth,Sight: SmallInt;
    OwnerType: ShortInt;
    Foot1: array [1..12] of ShortInt; //Sound indices
    Foot2: array [1..12] of SmallInt; //vs sprite ID
  end;

  THouseArea = array [1..4, 1..4] of Byte;
  THouseRes = array [1..4] of TKMWareType;

  //This class wraps KaM House info
  //it hides unused fields and adds new ones
  TKMHouseSpec = class
  private
    fHouseType: TKMHouseType; //Our class
    fNameTextID: Integer;
    fHouseDat: TKMHouseDat;
    function GetArea: THouseArea;
    function GetDoesOrders: Boolean;
    function GetGUIIcon: Word;
    function GetHouseName: UnicodeString;
    function GetResInput: THouseRes;
    function GetResOutput: THouseRes;
    function GetOwnerType: TKMUnitType;
    function GetReleasedBy: TKMHouseType;
    function GetTabletIcon: Word;
    function GetSnowPic: SmallInt;
    function GetUnoccupiedMsgId: SmallInt;
  public
    constructor Create(aHouseType: TKMHouseType);
    procedure LoadFromStream(Stream: TMemoryStream);
    //Property accessors:
    //Derived from KaM
    property StonePic:smallint read fHouseDat.StonePic;
    property WoodPic:smallint read fHouseDat.WoodPic;
    property WoodPal:smallint read fHouseDat.WoodPal;
    property StonePal:smallint read fHouseDat.StonePal;
    property SupplyIn: THouseSupply read fHouseDat.SupplyIn;
    property SupplyOut: THouseSupply read fHouseDat.SupplyOut;
    property Anim: THouseAnim read fHouseDat.Anim;
    property WoodPicSteps:word read fHouseDat.WoodPicSteps;
    property StonePicSteps:word read fHouseDat.StonePicSteps;
    property EntranceOffsetX:shortint read fHouseDat.EntranceOffsetX;
    property EntranceOffsetXpx:shortint read fHouseDat.EntranceOffsetXpx;
    property EntranceOffsetYpx:shortint read fHouseDat.EntranceOffsetYpx;
    property WoodCost:byte read fHouseDat.WoodCost;
    property StoneCost:byte read fHouseDat.StoneCost;
    property BuildSupply: THouseBuildSupply read fHouseDat.BuildSupply;
    property WorkerRest:smallint read fHouseDat.WorkerRest;
    property ResProductionX:shortint read fHouseDat.ResProductionX;
    property Sight:smallint read fHouseDat.Sight;
    property OwnerType: TKMUnitType read GetOwnerType;
    //Additional properties added by Remake
    property BuildArea: THouseArea read GetArea;
    property DoesOrders:boolean read GetDoesOrders;
    property GUIIcon:word read GetGUIIcon;
    property HouseName: UnicodeString read GetHouseName;
    property HouseNameTextID: Integer read fNameTextID;
    property ReleasedBy: TKMHouseType read GetReleasedBy;
    property ResInput: THouseRes read GetResInput;
    property ResOutput: THouseRes read GetResOutput;
    property TabletIcon:word read GetTabletIcon;
    property UnoccupiedMsgId:SmallInt read GetUnoccupiedMsgId;
    property SnowPic: SmallInt read GetSnowPic;
    //Functions
    function AcceptsWares: Boolean;
    function MaxHealth: Word;
    function ProducesWares: Boolean;
    procedure Outline(aList: TKMPointList);
  end;


  TKMResHouses = class
  private
    fCRC: Cardinal;
    fItems: array [HOUSE_MIN..HOUSE_MAX] of TKMHouseSpec;
    //Swine&Horses, 5 beasts in each house, 3 ages for each beast
    fBeastAnim: array [1..2,1..5,1..3] of TKMAnimLoop;
    fMarketBeastAnim: array [1..3] of TKMAnimLoop;
    function LoadHouseDat(const aPath: string): Cardinal;
    function GetHouseDat(aType: TKMHouseType): TKMHouseSpec; inline;
    function GetBeastAnim(aType: TKMHouseType; aBeast, aAge:integer): TKMAnimLoop;
  public
    constructor Create;
    destructor Destroy; override;

    function IsValid(aType: TKMHouseType): Boolean;

    property HouseDat[aType: TKMHouseType]: TKMHouseSpec read GetHouseDat; default;
    property BeastAnim[aType: TKMHouseType; aBeast, aAge: Integer]: TKMAnimLoop read GetBeastAnim;
    property CRC: Cardinal read fCRC; //Return hash of all values

    procedure ExportCSV(const aPath: string);
  end;


const
  //Sprites in the marketplace
  MarketWaresOffsetX = -93;
  MarketWaresOffsetY = -88;
  MarketWareTexStart = 1724; //ID of where market ware sprites start. Allows us to relocate them easily.
  MarketWares: array[TKMWareType] of record
                                         TexStart: Integer; //Tex ID for first sprite
                                         Count: Integer; //Total sprites for this resource
                                       end
  = (
      (TexStart: 0; Count: 0;), //rtNone

      (TexStart: MarketWareTexStart+237; Count: 20;), //rtTrunk
      (TexStart: MarketWareTexStart+47;  Count: 36;), //rtStone
      (TexStart: MarketWareTexStart+94;  Count: 19;), //rtWood
      (TexStart: MarketWareTexStart+113; Count: 11;), //rtIronOre
      (TexStart: MarketWareTexStart+135; Count: 12;), //rtGoldOre
      (TexStart: MarketWareTexStart+207; Count: 11;), //rtCoal
      (TexStart: MarketWareTexStart+130; Count: 5;),  //rtSteel
      (TexStart: MarketWareTexStart+147; Count: 9;),  //rtGold
      (TexStart: MarketWareTexStart+1;   Count: 23;), //rtWine
      (TexStart: MarketWareTexStart+24;  Count: 23;), //rtCorn
      (TexStart: MarketWareTexStart+218; Count: 12;), //rtBread
      (TexStart: MarketWareTexStart+186; Count: 12;), //rtFlour
      (TexStart: MarketWareTexStart+156; Count: 9;),  //rtLeather
      (TexStart: MarketWareTexStart+283; Count: 16;), //rtSausages
      (TexStart: MarketWareTexStart+299; Count: 6;),  //rtPig
      (TexStart: MarketWareTexStart+230; Count: 7;),  //rtSkin
      (TexStart: MarketWareTexStart+85;  Count: 9;),  //rtShield
      (TexStart: MarketWareTexStart+127; Count: 3;),  //rtMetalShield
      (TexStart: MarketWareTexStart+165; Count: 6;),  //rtArmor
      (TexStart: MarketWareTexStart+124; Count: 3;),  //rtMetalArmor
      (TexStart: MarketWareTexStart+201; Count: 6;),  //rtAxe
      (TexStart: MarketWareTexStart+183; Count: 3;),  //rtSword
      (TexStart: MarketWareTexStart+171; Count: 6;),  //rtPike
      (TexStart: MarketWareTexStart+198; Count: 3;),  //rtHallebard
      (TexStart: MarketWareTexStart+177; Count: 6;),  //rtBow
      (TexStart: MarketWareTexStart+83;  Count: 2;),  //rtArbalet
      (TexStart: 0;                      Count: 2;),  //rtHorse (defined in fMarketBeastAnim)
      (TexStart: MarketWareTexStart+305; Count: 19;), //rtFish

      (TexStart: 0; Count: 0;), //rtAll
      (TexStart: 0; Count: 0;), //rtWarfare
      (TexStart: 0; Count: 0;)  //rtFood
    );

  //These tables are used to convert between KaM script IDs and Remake enums
  HOUSE_DAT_COUNT = 30;
  //KaM scripts and HouseDat address houses in this order
  HouseIndexToType: array [0 .. HOUSE_DAT_COUNT - 1] of TKMHouseType = (
    htSawmill, htIronSmithy, htWeaponSmithy, htCoalMine, htIronMine,
    htGoldMine, htFisherHut, htBakery, htFarm, htWoodcutters,
    htArmorSmithy, htStore, htStables, htSchool, htQuary,
    htMetallurgists, htSwine, htWatchTower, htTownHall, htWeaponWorkshop,
    htArmorWorkshop, htBarracks, htMill, htSiegeWorkshop, htButchers,
    htTannery, htNone, htInn, htWineyard, htMarketplace);

  //TKMHouseType corresponds to this index in KaM scripts and libs
  //KaM scripts are 0 based, so we must use HouseTypeToIndex[H]-1 in script usage. Other cases are 1 based.
  HouseTypeToIndex: array [TKMHouseType] of Byte = (0, 0,
    11, 21, 8, 22, 25, 4, 9, 7, 6, 28,
    5, 2, 30, 16, 23, 15, 1, 14, 24, 13, 12,
    17, 26, 19, 18, 3, 20, 29, 10);


implementation
uses
  KromUtils, KM_Outline, KM_Points, KM_PolySimplify, KM_ResTexts, KM_ResUnits;


type
  //Additional house info appended to classic format
  THouseInfo = record
    PlanYX: THouseArea;
    NeedsPlayerOrder: Boolean; //Does house output needs to be ordered by Player or it's producing by itself
    BuildIcon: Word;  //Icon in GUI
    TabletSpriteId: Word; //House area WIP tablet
    Input: THouseRes;
    Output: THouseRes;
    UnlockedByHouse: TKMHouseType; //Which house type allows to build this house type
    SnowSpriteId: SmallInt;
  end;

const
  //Remake stores additional house properties here. This looks like House.Dat, but hardcoded.
  HouseDatX: array [HOUSE_MIN..HOUSE_MAX] of THouseInfo = (
    ( //Armor smithy
    PlanYX:           ((0,0,0,0), (0,1,1,0), (1,1,1,1), (1,2,1,1));
    NeedsPlayerOrder: True;
    BuildIcon:        311;
    TabletSpriteId:   261;
    Input:            (wtCoal,       wtSteel,      wtNone,       wtNone);
    Output:           (wtMetalArmor, wtMetalShield,wtNone,       wtNone);
    UnlockedByHouse:  htIronSmithy;
    SnowSpriteId:     -1;
    ),
    ( //Armor workshop
    PlanYX:           ((0,0,0,0), (0,1,1,0), (0,1,1,1), (0,2,1,1));
    NeedsPlayerOrder: True;
    BuildIcon:        321;
    TabletSpriteId:   271;
    Input:            (wtLeather,    wtWood,       wtNone,       wtNone);
    Output:           (wtArmor,      wtShield,     wtNone,       wtNone);
    UnlockedByHouse:  htTannery;
    SnowSpriteId:     2067;
    ),
    ( //Bakery
    PlanYX:           ((0,0,0,0), (0,1,1,1), (0,1,1,1), (0,1,1,2));
    NeedsPlayerOrder: False;
    BuildIcon:        308;
    TabletSpriteId:   258;
    Input:            (wtFlour,      wtNone,       wtNone,       wtNone);
    Output:           (wtBread,      wtNone,       wtNone,       wtNone);
    UnlockedByHouse:  htMill;
    SnowSpriteId:     2054;
    ),
    ( //Barracks
    PlanYX:           ((1,1,1,1), (1,1,1,1), (1,1,1,1), (1,2,1,1));
    NeedsPlayerOrder: False;
    BuildIcon:        322;
    TabletSpriteId:   272;
    Input:            (wtWarfare,    wtNone,       wtNone,       wtNone);
    Output:           (wtNone,       wtNone,       wtNone,       wtNone);
    UnlockedByHouse:  htSawmill;
    SnowSpriteId:     -1;
    ),
    ( //Butchers
    PlanYX:           ((0,0,0,0), (0,1,1,0), (0,1,1,1), (0,1,1,2));
    NeedsPlayerOrder: False;
    BuildIcon:        325;
    TabletSpriteId:   275;
    Input:            (wtPig,        wtNone,       wtNone,       wtNone);
    Output:           (wtSausages,   wtNone,       wtNone,       wtNone);
    UnlockedByHouse:  htSwine;
    SnowSpriteId:     2066;
    ),
    ( //Coal mine
    PlanYX:           ((0,0,0,0), (0,0,0,0), (1,1,1,0), (1,2,1,0));
    NeedsPlayerOrder: False;
    BuildIcon:        304;
    TabletSpriteId:   254;
    Input:            (wtNone,       wtNone,       wtNone,       wtNone);
    Output:           (wtCoal,       wtNone,       wtNone,       wtNone);
    UnlockedByHouse:  htSawmill;
    SnowSpriteId:     -1;
    ),
    ( //Farm
    PlanYX:           ((0,0,0,0), (1,1,1,1), (1,1,1,1), (1,2,1,1));
    NeedsPlayerOrder: False;
    BuildIcon:        309;
    TabletSpriteId:   259;
    Input:            (wtNone,       wtNone,       wtNone,       wtNone);
    Output:           (wtCorn,       wtNone,       wtNone,       wtNone);
    UnlockedByHouse:  htSawmill;
    SnowSpriteId:     2055;
    ),
    ( //Fisher hut
    PlanYX:           ((0,0,0,0), (0,0,0,0), (0,1,1,0), (0,2,1,1));
    NeedsPlayerOrder: False;
    BuildIcon:        307;
    TabletSpriteId:   257;
    Input:            (wtNone,       wtNone,       wtNone,       wtNone);
    Output:           (wtFish,       wtNone,       wtNone,       wtNone);
    UnlockedByHouse:  htSawmill;
    SnowSpriteId:     2053;
    ),
    ( //Gold mine
    PlanYX:           ((0,0,0,0), (0,0,0,0), (0,0,0,0), (0,1,2,0));
    NeedsPlayerOrder: False;
    BuildIcon:        306;
    TabletSpriteId:   256;
    Input:            (wtNone,       wtNone,       wtNone,       wtNone);
    Output:           (wtGoldOre,    wtNone,       wtNone,       wtNone);
    UnlockedByHouse:  htSawmill;
    SnowSpriteId:     -1;
    ),
    ( //Inn
    PlanYX:           ((0,0,0,0), (0,1,1,1), (1,1,1,1), (1,2,1,1));
    NeedsPlayerOrder: False;
    BuildIcon:        328;
    TabletSpriteId:   278;
    Input:            (wtBread,      wtSausages,   wtWine,       wtFish);
    Output:           (wtNone,       wtNone,       wtNone,       wtNone);
    UnlockedByHouse:  htStore;
    SnowSpriteId:     2063;
    ),
    ( //Iron mine
    PlanYX:           ((0,0,0,0), (0,0,0,0), (0,0,0,0), (0,1,2,1));
    NeedsPlayerOrder: False;
    BuildIcon:        305;
    TabletSpriteId:   255;
    Input:            (wtNone,       wtNone,       wtNone,       wtNone);
    Output:           (wtIronOre,    wtNone,       wtNone,       wtNone);
    UnlockedByHouse:  htSawmill;
    SnowSpriteId:     2052;
    ),
    ( //Iron smithy
    PlanYX:           ((0,0,0,0), (0,0,0,0), (1,1,1,1), (1,1,2,1));
    NeedsPlayerOrder: False;
    BuildIcon:        302;
    TabletSpriteId:   252;
    Input:            (wtIronOre,    wtCoal,       wtNone,       wtNone);
    Output:           (wtSteel,      wtNone,       wtNone,       wtNone);
    UnlockedByHouse:  htIronMine;
    SnowSpriteId:     2051;
    ),
    ( //Marketplace
    PlanYX:           ((0,0,0,0), (0,1,1,1), (1,1,1,1), (1,1,1,2));
    NeedsPlayerOrder: False;
    BuildIcon:        327;
    TabletSpriteId:   277;
    Input:            (wtNone,       wtNone,       wtNone,       wtNone);
    Output:           (wtNone,       wtNone,       wtNone,       wtNone);
    UnlockedByHouse:  htSawmill;
    SnowSpriteId:     -1;
    ),
    ( //Metallurgist
    PlanYX:           ((0,0,0,0), (1,1,1,0), (1,1,1,0), (1,2,1,0));
    NeedsPlayerOrder: False;
    BuildIcon:        316;
    TabletSpriteId:   266;
    Input:            (wtGoldOre,    wtCoal,       wtNone,       wtNone);
    Output:           (wtGold,       wtNone,       wtNone,       wtNone);
    UnlockedByHouse:  htGoldMine;
    SnowSpriteId:     2068;
    ),
    ( //Mill
    PlanYX:           ((0,0,0,0), (0,0,0,0), (0,1,1,1), (0,1,2,1));
    NeedsPlayerOrder: False;
    BuildIcon:        323;
    TabletSpriteId:   273;
    Input:            (wtCorn,       wtNone,       wtNone,       wtNone);
    Output:           (wtFlour,      wtNone,       wtNone,       wtNone);
    UnlockedByHouse:  htFarm;
    SnowSpriteId:     2062;
    ),
    ( //Quarry
    PlanYX:           ((0,0,0,0), (0,0,0,0), (0,1,1,1), (0,1,2,1));
    NeedsPlayerOrder: False;
    BuildIcon:        315;
    TabletSpriteId:   265;
    Input:            (wtNone,       wtNone,       wtNone,       wtNone);
    Output:           (wtStone,      wtNone,       wtNone,       wtNone);
    UnlockedByHouse:  htSchool;
    SnowSpriteId:     2058;
    ),
    ( //Sawmill
    PlanYX:           ((0,0,0,0), (0,0,0,0), (1,1,1,1), (1,2,1,1));
    NeedsPlayerOrder: False;
    BuildIcon:        301;
    TabletSpriteId:   251;
    Input:            (wtTrunk,      wtNone,       wtNone,       wtNone);
    Output:           (wtWood,       wtNone,       wtNone,       wtNone);
    UnlockedByHouse:  htWoodcutters;
    SnowSpriteId:     2050;
    ),
    ( //School
    PlanYX:           ((0,0,0,0), (1,1,1,0), (1,1,1,0), (1,2,1,0));
    NeedsPlayerOrder: False;
    BuildIcon:        314;
    TabletSpriteId:   264;
    Input:            (wtGold,       wtNone,       wtNone,       wtNone);
    Output:           (wtNone,       wtNone,       wtNone,       wtNone);
    UnlockedByHouse:  htStore;
    SnowSpriteId:     2059;
    ),
    ( //Siege workshop
    PlanYX:           ((0,0,0,0), (0,0,0,0), (0,1,1,1), (0,2,1,1));
    NeedsPlayerOrder: True;
    BuildIcon:        324;
    TabletSpriteId:   274;
    Input:            (wtWood,       wtSteel,      wtNone,       wtNone);
    Output:           (wtNone,       wtNone,       wtNone,       wtNone);
    UnlockedByHouse:  htIronSmithy;
    SnowSpriteId:     -1;
    ),
    ( //Stables
    PlanYX:           ((0,0,0,0), (1,1,1,1), (1,1,1,1), (1,1,2,1));
    NeedsPlayerOrder: False;
    BuildIcon:        313;
    TabletSpriteId:   263;
    Input:            (wtCorn,       wtNone,       wtNone,       wtNone);
    Output:           (wtHorse,      wtNone,       wtNone,       wtNone);
    UnlockedByHouse:  htFarm;
    SnowSpriteId:     -1;
    ),
    ( //Store
    PlanYX:           ((0,0,0,0), (1,1,1,0), (1,1,1,0), (1,2,1,0));
    NeedsPlayerOrder: False;
    BuildIcon:        312;
    TabletSpriteId:   262;
    Input:            (wtAll,        wtNone,       wtNone,       wtNone);
    Output:           (wtAll,        wtNone,       wtNone,       wtNone);
    UnlockedByHouse:  htNone; //
    SnowSpriteId:     2056;
    ),
    ( //Swine
    PlanYX:           ((0,0,0,0), (0,1,1,1), (1,1,1,1), (1,1,1,2));
    NeedsPlayerOrder: False;
    BuildIcon:        317;
    TabletSpriteId:   267;
    Input:            (wtCorn,       wtNone,       wtNone,       wtNone);
    Output:           (wtPig,        wtSkin,       wtNone,       wtNone);
    UnlockedByHouse:  htFarm;
    SnowSpriteId:     2064;
    ),
    ( //Tannery
    PlanYX:           ((0,0,0,0), (0,0,0,0), (0,1,1,1), (0,1,2,1));
    NeedsPlayerOrder: False;
    BuildIcon:        326;
    TabletSpriteId:   276;
    Input:            (wtSkin,       wtNone,       wtNone,       wtNone);
    Output:           (wtLeather,    wtNone,       wtNone,       wtNone);
    UnlockedByHouse:  htSwine;
    SnowSpriteId:     -1;
    ),
    ( //Town hall
    PlanYX:           ((0,0,0,0), (1,1,1,1), (1,1,1,1), (1,2,1,1));
    NeedsPlayerOrder: False;
    BuildIcon:        319;
    TabletSpriteId:   269;
    Input:            (wtGold,       wtNone,       wtNone,       wtNone);
    Output:           (wtNone,       wtNone,       wtNone,       wtNone);
    UnlockedByHouse:  htMetallurgists;
    SnowSpriteId:     -1;
    ),
    ( //Watch tower
    PlanYX:   ((0,0,0,0), (0,0,0,0), (0,1,1,0), (0,1,2,0));
    NeedsPlayerOrder: False;
    BuildIcon:        318;
    TabletSpriteId:   268;
    Input:            (wtStone,      wtNone,       wtNone,       wtNone);
    Output:           (wtNone,       wtNone,       wtNone,       wtNone);
    UnlockedByHouse:  htQuary;
    SnowSpriteId:     2060;
    ),
    ( //Weapon smithy
    PlanYX:           ((0,0,0,0), (0,0,0,0), (1,1,1,1), (1,2,1,1));
    NeedsPlayerOrder: True;
    BuildIcon:        303;
    TabletSpriteId:   253;
    Input:            (wtCoal,       wtSteel,      wtNone,       wtNone);
    Output:           (wtSword,      wtHallebard,  wtArbalet,    wtNone);
    UnlockedByHouse:  htIronSmithy;
    SnowSpriteId:     -1;
    ),
    ( //Weapon workshop
    PlanYX:           ((0,0,0,0), (0,0,0,0), (1,1,1,1), (1,2,1,1));
    NeedsPlayerOrder: True;
    BuildIcon:        320;
    TabletSpriteId:   270;
    Input:            (wtWood,       wtNone,       wtNone,       wtNone);
    Output:           (wtAxe,        wtPike,       wtBow,        wtNone);
    UnlockedByHouse:  htSawmill;
    SnowSpriteId:     2061;
    ),
    ( //Wineyard
    PlanYX:           ((0,0,0,0), (0,0,0,0), (0,1,1,1), (0,1,1,2));
    NeedsPlayerOrder: False;
    BuildIcon:        329;
    TabletSpriteId:   279;
    Input:            (wtNone,       wtNone,       wtNone,       wtNone);
    Output:           (wtWine,       wtNone,       wtNone,       wtNone);
    UnlockedByHouse:  htSawmill;
    SnowSpriteId:     2065;
    ),
    ( //Woodcutter
    PlanYX:           ((0,0,0,0), (0,0,0,0), (1,1,1,0), (1,1,2,0));
    NeedsPlayerOrder: False;
    BuildIcon:        310;
    TabletSpriteId:   260;
    Input:            (wtNone,       wtNone,       wtNone,       wtNone);
    Output:           (wtTrunk,      wtNone,       wtNone,       wtNone);
    UnlockedByHouse:  htSchool;
    SnowSpriteId:     2057;
    )
    );


  //For some reason in KaM the piles of building supply are not aligned, each one has a different offset.
  //These values were taking from the barracks offsets and are for use with new houses.
  BuildSupplyOffsets: THouseBuildSupply = ( ((MoveX:  0; MoveY: 0), (MoveX: -7; MoveY: 0), (MoveX:-26; MoveY: 0),  //Wood 1-3
                                             (MoveX:-26; MoveY: 0), (MoveX:-26; MoveY:-1), (MoveX:-26; MoveY:-4)), //Wood 4-6
                                            ((MoveX:  0; MoveY: 0), (MoveX:  0; MoveY: 0), (MoveX: -7; MoveY: 0),  //Stone 1-3
                                             (MoveX: -7; MoveY:-4), (MoveX:-16; MoveY:-4), (MoveX:-16; MoveY:-4)));//Stone 4-6


  //'This house is unoccupied' msg index
  HouseTypeToUnoccupiedMsgIndex: array[TKMHouseType] of ShortInt = (
    -1, -1,     //utNone, utAny
    0,1,2,
    -1,         //htBarracks
    3,4,5,6,7,
    -1,         //htInn
    8,9,
    -1,         //htMarketplace
    10,11,12,13,
    -1,         //htSchool
    14,15,
    -1,         //htStore
    16,17,
    -1,         //htTownHall
    18,19,20,21,22);


{ TKMHouseDatClass }
constructor TKMHouseSpec.Create(aHouseType: TKMHouseType);
begin
  inherited Create;
  fHouseType := aHouseType;
  fNameTextID := TX_HOUSES_NAMES__29 + HouseTypeToIndex[fHouseType] - 1; //May be overridden for new houses
end;


function TKMHouseSpec.AcceptsWares: boolean;
begin
  Result := (ResInput[1] <> wtNone)          //Exclude houses that do not receive wares
            or (fHouseType = htMarketplace); //Marketplace also accepts wares
end;


function TKMHouseSpec.GetArea: THouseArea;
begin
  Result := HouseDatX[fHouseType].PlanYX;
end;


function TKMHouseSpec.GetDoesOrders: Boolean;
begin
  Result := HouseDatX[fHouseType].NeedsPlayerOrder;
end;


function TKMHouseSpec.GetGUIIcon: Word;
begin
  Result := HouseDatX[fHouseType].BuildIcon;
end;


function TKMHouseSpec.GetHouseName: UnicodeString;
begin
  Result := gResTexts[fNameTextID];
end;


//MaxHealth is always a cost of construction * 50
function TKMHouseSpec.MaxHealth: Word;
begin
  Result := (fHouseDat.WoodCost + fHouseDat.StoneCost) * 50;
end;


//Write houses outline into given list
procedure TKMHouseSpec.Outline(aList: TKMPointList);
var
  I, K: Integer;
  Tmp: TKMByte2Array;
  Outlines: TKMShapesArray;
begin
  aList.Clear;
  SetLength(Tmp, 6, 6);

  for I := 0 to 3 do
  for K := 0 to 3 do
    Tmp[I+1,K+1] := Byte(HouseDatX[fHouseType].PlanYX[I+1,K+1] > 0);

  GenerateOutline(Tmp, 2, Outlines);
  Assert(Outlines.Count = 1, 'Houses are expected to have single outline');

  for I := 0 to Outlines.Shape[0].Count - 1 do
    aList.Add(KMPoint(Outlines.Shape[0].Nodes[I].X, Outlines.Shape[0].Nodes[I].Y));
end;


function TKMHouseSpec.GetOwnerType: TKMUnitType;
begin
  //fHouseDat.OwnerType is read from DAT file and is shortint, it can be out of range (i.e. -1)
  if InRange(fHouseDat.OwnerType, Low(UnitIndexToType), High(UnitIndexToType)) then
    Result := UnitIndexToType[fHouseDat.OwnerType]
  else
    Result := utNone;
end;


function TKMHouseSpec.ProducesWares: Boolean;
begin
  Result := not (ResOutput[1] in [wtNone, wtAll, wtWarfare]); //Exclude aggregate types
end;


function TKMHouseSpec.GetReleasedBy: TKMHouseType;
begin
  Result := HouseDatX[fHouseType].UnlockedByHouse;
end;


function TKMHouseSpec.GetResInput: THouseRes;
begin
  Result := HouseDatX[fHouseType].Input;
end;


function TKMHouseSpec.GetResOutput: THouseRes;
begin
  Result := HouseDatX[fHouseType].Output;
end;


function TKMHouseSpec.GetSnowPic: SmallInt;
begin
  Result := HouseDatX[fHouseType].SnowSpriteId;
end;


function TKMHouseSpec.GetTabletIcon: Word;
begin
  Result := HouseDatX[fHouseType].TabletSpriteId;
end;


function TKMHouseSpec.GetUnoccupiedMsgId: SmallInt;
var HouseUnnocupiedMsgIndex: ShortInt;
begin
  Result := -1;
  HouseUnnocupiedMsgIndex := HouseTypeToUnoccupiedMsgIndex[fHouseType];
  if HouseUnnocupiedMsgIndex <> -1 then
    Result := TX_MSG_HOUSE_UNOCCUPIED__22 + HouseUnnocupiedMsgIndex;
end;


procedure TKMHouseSpec.LoadFromStream(Stream: TMemoryStream);
begin
  Stream.Read(fHouseDat, SizeOf(TKMHouseDat));
end;


{ TKMResHouses }
constructor TKMResHouses.Create;

  procedure AddAnimation(aHouse: TKMHouseType; aAnim: TKMHouseActionType; aMoveX, aMoveY: Integer; const aSteps: array of SmallInt);
  var I: Integer;
  begin
    with fItems[aHouse].fHouseDat.Anim[aAnim] do
    begin
      MoveX := aMoveX;
      MoveY := aMoveY;
      Count := length(aSteps);
      for I := 1 to Count do
        Step[I] := aSteps[I-1];
    end;
  end;

  procedure AddMarketBeastAnim(aBeast: Integer; const aStep: array of SmallInt);
  var I: Integer;
  begin
    // Beast anims are 0 indexed
    for I := 1 to 30 do
      fMarketBeastAnim[aBeast].Step[I] := aStep[I - 1] + MarketWareTexStart - 1;
  end;

var H: TKMHouseType; I: Integer;
begin
  inherited;

  for H := HOUSE_MIN to HOUSE_MAX do
    fItems[H] := TKMHouseSpec.Create(H);

  fCRC := LoadHouseDat(ExeDir+'data' + PathDelim + 'defines' + PathDelim + 'houses.dat');

  fItems[htTannery].fHouseDat.Anim[haFlag3].Count := 0; //fix for tannery 2 flags at one place. Flag3 is unnecessary

  fItems[htMarketplace].fHouseType := htMarketplace;
  fItems[htMarketplace].fHouseDat.OwnerType := -1; //No unit works here (yet anyway)
  fItems[htMarketplace].fHouseDat.StonePic := 150;
  fItems[htMarketplace].fHouseDat.WoodPic := 151;
  fItems[htMarketplace].fHouseDat.WoodPal := 152;
  fItems[htMarketplace].fHouseDat.StonePal := 153;
  fItems[htMarketplace].fHouseDat.SupplyIn[1,1] := 154;
  fItems[htMarketplace].fHouseDat.SupplyIn[1,2] := 155;
  fItems[htMarketplace].fHouseDat.SupplyIn[1,3] := 156;
  fItems[htMarketplace].fHouseDat.SupplyIn[1,4] := 157;
  fItems[htMarketplace].fHouseDat.SupplyIn[1,5] := 158;
  fItems[htMarketplace].fHouseDat.WoodPicSteps := 23;
  fItems[htMarketplace].fHouseDat.StonePicSteps := 140;
  fItems[htMarketplace].fHouseDat.EntranceOffsetX := 1;
  fItems[htMarketplace].fHouseDat.EntranceOffsetXpx := 4; //Enterance is slightly to the left
  fItems[htMarketplace].fHouseDat.EntranceOffsetYpx := 10;
  fItems[htMarketplace].fHouseDat.WoodCost := 5;
  fItems[htMarketplace].fHouseDat.StoneCost := 6;
  for I := 1 to 6 do begin
    fItems[htMarketplace].fHouseDat.BuildSupply[1,I].MoveX := -55+ BuildSupplyOffsets[1,I].MoveX;
    fItems[htMarketplace].fHouseDat.BuildSupply[1,I].MoveY := 15 + BuildSupplyOffsets[1,I].MoveY;
    fItems[htMarketplace].fHouseDat.BuildSupply[2,I].MoveX := 28 + BuildSupplyOffsets[2,I].MoveX;
    fItems[htMarketplace].fHouseDat.BuildSupply[2,I].MoveY := 20 + BuildSupplyOffsets[2,I].MoveY;
  end;
  fItems[htMarketplace].fHouseDat.Sight := 10;
  fItems[htMarketplace].fHouseDat.SizeArea := 11;
  fItems[htMarketplace].fHouseDat.SizeX := 4;
  fItems[htMarketplace].fHouseDat.SizeY := 3;
  fItems[htMarketplace].fHouseDat.MaxHealth := 550;
  AddAnimation(htMarketplace, haFlag1, -80, -33, [1165,1166,1167,1163,1164]);
  AddAnimation(htMarketplace, haFlag2, -73, -7, [1163,1164,1165,1166,1167]);
  AddAnimation(htMarketplace, haFlag3, 73, -80, [1161,1162,1158,1159,1160]);
  AddAnimation(htMarketplace, haFire1, 18, -83, [1623,1624,1625,1620,1621,1622]);
  AddAnimation(htMarketplace, haFire2, 78, -67, [1637,1632,1633,1634,1635,1636]);
  AddAnimation(htMarketplace, haFire3, -30, -103, [1620,1621,1622,1623,1624,1625]);
  AddAnimation(htMarketplace, haFire4, -3, -54, [1617,1618,1619,1614,1615,1616]);
  AddAnimation(htMarketplace, haFire5, -12, -38, [1632,1633,1634,1635,1636,1637]);
  AddAnimation(htMarketplace, haFire6, 39, -47, [1629,1630,1631,1626,1627,1628]);
  AddAnimation(htMarketplace, haFire7, 25, 13, [1635,1636,1637,1632,1633,1634]);
  AddAnimation(htMarketplace, haFire8, -82, -40, [1621,1622,1623,1624,1625,1620]);
  //Now add horse animations for the market
  AddMarketBeastAnim(1,[278, 277, 276, 275, 274, 273, 272, 271, 271, 271, 271, 271, 272,
                        273, 274, 275, 276, 277, 277, 278, 279, 280, 281, 282, 282, 282,
                        282, 281, 280, 279]);
  fMarketBeastAnim[1].Count := 30;
  fMarketBeastAnim[1].MoveX := MarketWaresOffsetX;
  fMarketBeastAnim[1].MoveY := MarketWaresOffsetY;
  AddMarketBeastAnim(2,[266, 265, 264, 263, 262, 261, 260, 259, 258, 257, 258, 259, 260,
                        261, 262, 263, 264, 265, 266, 267, 268, 269, 270, 270, 270, 270,
                        270, 269, 268, 267]);
  fMarketBeastAnim[2].Count := 30;
  fMarketBeastAnim[2].MoveX := MarketWaresOffsetX;
  fMarketBeastAnim[2].MoveY := MarketWaresOffsetY;

  //ExportCSV(ExeDir+'Houses.csv');
end;


destructor TKMResHouses.Destroy;
var H: TKMHouseType;
begin
  for H := HOUSE_MIN to HOUSE_MAX do
    FreeAndNil(fItems[H]);

  inherited;
end;


function TKMResHouses.GetHouseDat(aType: TKMHouseType): TKMHouseSpec;
begin
  Result := fItems[aType];
end;


function TKMResHouses.IsValid(aType: TKMHouseType): Boolean;
begin
  Result := aType in [HOUSE_MIN..HOUSE_MAX];
end;


function TKMResHouses.GetBeastAnim(aType: TKMHouseType; aBeast, aAge: Integer): TKMAnimLoop;
begin
  Assert(aType in [htSwine, htStables, htMarketplace]);
  Assert(InRange(aBeast, 1, 5));
  Assert(InRange(aAge, 1, 3));
  case aType of
    htSwine:       Result := fBeastAnim[1, aBeast, aAge];
    htStables:     Result := fBeastAnim[2, aBeast, aAge];
    htMarketplace: Result := fMarketBeastAnim[aBeast];
  end;
end;


//Return CRC of loaded file
//CRC should be calculated right away, cos file may be swapped after loading
function TKMResHouses.LoadHouseDat(const aPath: string): Cardinal;
var
  S: TKMemoryStream;
  i:integer;
begin
  Assert(FileExists(aPath));

  S := TKMemoryStream.Create;
  try
    S.LoadFromFile(aPath);

    S.Read(fBeastAnim, SizeOf(fBeastAnim){30*70}); //Swine&Horses animations

    //Read the records one by one because we need to reorder them and skip one in the middle
    for i:=0 to 28 do //KaM has only 28 houses
    if HouseIndexToType[i] <> htNone then
      fItems[HouseIndexToType[i]].LoadFromStream(S)
    else
      S.Seek(SizeOf(TKMHouseDat), soFromCurrent);

    Result := Adler32CRC(S);
  finally
    S.Free;
  end;
end;


procedure TKMResHouses.ExportCSV(const aPath: string);
var
  HT: TKMHouseType;
  S: string;
  SL: TStringList;
  I, K: Integer;
  procedure AddField(const aField: string); overload;
  begin S := S + aField + ';'; end;
  procedure AddField(aField: Integer); overload;
  begin S := S + IntToStr(aField) + ';'; end;

begin
  SL := TStringList.Create;

  S := 'House name;WoodCost;StoneCost;ResProductionX';
  SL.Append(S);

  for HT := HOUSE_MIN to HOUSE_MAX do
  begin
    S := '';
    AddField(fItems[HT].HouseName);
    AddField(fItems[HT].WoodCost);
    AddField(fItems[HT].StoneCost);
    AddField(fItems[HT].ResProductionX);
    SL.Append(S);
    for I := 1 to 4 do
    begin
      S := '';
      for K := 1 to 4 do
        AddField(fItems[HT].BuildArea[I, K]);
      SL.Append(S);
    end;
    S := '';
    SL.Append(S);
  end;

  ForceDirectories(ExtractFilePath(aPath));

  SL.SaveToFile(aPath);
  SL.Free;
end;


end.
