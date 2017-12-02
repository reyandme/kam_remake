unit KM_CityPredictor;
{$I KaM_Remake.inc}
interface
uses
  Classes, Graphics, KromUtils, Math, SysUtils,
  KM_Defaults, KM_Points, KM_CommonClasses, KM_CommonTypes,
  KM_ResHouses, KM_ResWares;

type
  TWareBalance = record
    Production, Consumption, Estimation, Derivation: Single;
    pom: Integer;
  end;
  // Information about city (it can be replaced by player's stats but it doesnt allow prediction with different values)
  TCityStats = record
    CitizensCnt, WarriorsCnt, HousesCnt: Word;
    Citizens: array[CITIZEN_MIN..CITIZEN_MAX] of Word;
    Warriors: array[WARRIOR_MIN..WARRIOR_MAX] of Word;
    Houses: array[HOUSE_MIN..HOUSE_MAX] of Word;
  end;
  TWareBalanceArray = array[WARE_MIN..WARE_MAX] of TWareBalance;
  TWarfareDemands = array[WARFARE_MIN..WARFARE_MAX] of Single;
  TRequiredHousesArray = array[HOUSE_MIN..HOUSE_MAX] of Integer;

  TKMCityPredictor = class
  private
    fOwner: TKMHandIndex;
    fCityStats: TCityStats;

    fWareBalance: TWareBalanceArray;

    procedure UpdateWareProduction(aWT: TWareType);
    procedure UpdateWareConsumption(aWT: TWareType);
    procedure UpdateFoodConsumption();
    procedure UpdateWareDerivation(aWT: TWareType);
    procedure UpdateWareBalance(aSkipWeaponsCalculation: Boolean = False);

    //procedure PlanCityStats();
    procedure UpdateBasicHouses(aInitialization: Boolean = False);
    procedure UpdateCityStats();
  public
    RequiredHouses: TRequiredHousesArray;

    constructor Create(aPlayer: TKMHandIndex);
    destructor Destroy(); override;
    procedure AfterMissionInit();
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

    property CityStats: TCityStats read fCityStats;
    property WareBalance: TWareBalanceArray read fWareBalance;

    procedure UpdateState(aTick: Cardinal);
    procedure CityInitialization(aGoldMineCnt, aIronMineCnt, aFieldCnt, aBuildCnt: Integer);
    procedure LogStatus(var aBalanceText: UnicodeString);
    procedure OwnerUpdate(aPlayer: TKMHandIndex);

  end;

const

  {
  wt_None,
  wt_Trunk,   wt_Stone,   wt_Wood,        wt_IronOre,   wt_GoldOre,
  wt_Coal,    wt_Steel,   wt_Gold,        wt_Wine,      wt_Corn,
  wt_Bread,   wt_Flour,   wt_Leather,     wt_Sausages,  wt_Pig,
  wt_Skin,    wt_Shield,  wt_MetalShield, wt_Armor,     wt_MetalArmor,
  wt_Axe,     wt_Sword,   wt_Pike,        wt_Hallebard, wt_Bow,
  wt_Arbalet, wt_Horse,   wt_Fish,
  wt_All,     wt_Warfare, wt_Food
  }
  // Array of wares which are produced by specific houses
  PRODUCTION: array[WARE_MIN..WARE_MAX] of THouseType = (
    ht_Woodcutters,    ht_Quary,         ht_Sawmill,        ht_IronMine,      ht_GoldMine,
    ht_CoalMine,       ht_IronSmithy,    ht_Metallurgists,  ht_Wineyard,      ht_Farm,
    ht_Bakery,         ht_Mill,          ht_Tannery,        ht_Butchers,      ht_Swine,
    ht_Swine,          ht_ArmorWorkshop, ht_ArmorSmithy,    ht_ArmorWorkshop, ht_ArmorSmithy,
    ht_WeaponWorkshop, ht_WeaponSmithy,  ht_WeaponWorkshop, ht_WeaponSmithy,  ht_WeaponWorkshop,
    ht_WeaponSmithy,   ht_Stables,       ht_FisherHut
  );
  // Possible transformation of wares: resource -> product
  CONSUMPTION: array[WARE_MIN..WARE_MAX] of array[0..3] of TWareType = (
    (wt_Wood, wt_None, wt_None, wt_None), (wt_None, wt_None, wt_None, wt_None), (wt_Shield, wt_Axe, wt_None, wt_None), (wt_Steel, wt_None, wt_None, wt_None), (wt_Gold, wt_None, wt_None, wt_None),
    (wt_Steel, wt_Gold, wt_MetalArmor, wt_Sword), (wt_MetalArmor, wt_Sword, wt_None, wt_None), (wt_None, wt_None, wt_None, wt_None), (wt_None, wt_None, wt_None, wt_None), (wt_Flour, wt_Skin, wt_Horse, wt_None),
    (wt_None, wt_None, wt_None, wt_None), (wt_Bread, wt_None, wt_None, wt_None), (wt_Armor, wt_None, wt_None, wt_None), (wt_None, wt_None, wt_None, wt_None), (wt_Sausages, wt_None, wt_None, wt_None),
    (wt_Leather, wt_None, wt_None, wt_None), (wt_None, wt_None, wt_None, wt_None), (wt_None, wt_None, wt_None, wt_None), (wt_None, wt_None, wt_None, wt_None), (wt_None, wt_None, wt_None, wt_None),
    (wt_None, wt_None, wt_None, wt_None), (wt_None, wt_None, wt_None, wt_None), (wt_None, wt_None, wt_None, wt_None), (wt_None, wt_None, wt_None, wt_None), (wt_None, wt_None, wt_None, wt_None),
    (wt_None, wt_None, wt_None, wt_None), (wt_None, wt_None, wt_None, wt_None), (wt_None, wt_None, wt_None, wt_None)
  );
  // Array of wares which are consumed in specific amount to achieve specific production (because of exceptions in ht_WeaponWorkshop / ht_Swine / ht_Stables etc.)
  CONSUMPTION_RATIO: array[wt_Trunk..wt_Skin] of array[0..3] of Single = (
    // 1 trunk = 2 Wood                2 wood = 1 axe/bow/spear        1 GoldOre = 2 Gold (+ 1 Coal)
    (0.5, 1, 1, 1),   (1, 1, 1, 1),   (2, 1, 1, 1),   (1, 1, 1, 1),   (0.5, 1, 1, 1),
    // 1 coal = 2 gold (+ 1 gold ore)                                    BEAST_COST = 4 (per a pig / horse)
    (0.5, 1, 1, 1),   (1, 1, 1, 1),   (1, 1, 1, 1),   (1, 1, 1, 1),   (1, 4, 4, 1),
    //               1 flour = 2 bread                                 1 pig = 3 sausages
    (1, 1, 1, 1),   (0.5, 1, 1, 1),   (1, 1, 1, 1),   (1, 1, 1, 1),   (0.333, 1, 1, 1),
    // 1 skin = 2 leather
    (0.5, 1, 1, 1)
  );
  CONSUMPTION_ORDER: array[0..27] of TWareType = ( // Order of items in TWareType is "chaotic" this will sort it at least by order: resource -> product
    wt_Stone,   wt_Trunk,    wt_Wood,
    wt_Corn,    wt_Flour,    wt_Bread,     wt_Wine,        wt_Fish,
    wt_Pig,     wt_Sausages, wt_Skin,      wt_Leather,     wt_Horse,
    wt_GoldOre, wt_IronOre,  wt_Coal,      wt_Gold,        wt_Steel,
    wt_Axe,     wt_Bow,      wt_Pike,      wt_Shield,      wt_Armor,
    wt_Sword,   wt_Arbalet,  wt_Hallebard, wt_MetalShield, wt_MetalArmor
  );
  CO_WEAPONS_MIN = 18;
  CO_WEAPONS_MAX = 27;
  CO_WARE_MIN = 0;
  CO_WARE_MAX = 17;
  {
  // Array of wares which are consumed by specific houses
  CONSUMPTION: array[WARE_MIN..WARE_MAX] of array[0..3] of THouseType = (
    (ht_Sawmill, ht_None, ht_None, ht_None),   (ht_None, ht_None, ht_None, ht_None),   (ht_WeaponWorkshop, ht_ArmorWorkshop, ht_None, ht_None),   (ht_IronSmithy, ht_None, ht_None, ht_None),   (ht_Metallurgists, ht_None, ht_None, ht_None),
    (ht_Metallurgists, ht_IronSmithy, ht_ArmorSmithy, ht_WeaponSmithy),   (ht_ArmorSmithy, ht_WeaponSmithy, ht_None, ht_None),   (ht_None, ht_None, ht_None, ht_None),   (ht_None, ht_None, ht_None, ht_None),   (ht_Mill, ht_Swine, ht_Stables, ht_None),
    (ht_None, ht_None, ht_None, ht_None),   (ht_Bakery, ht_None, ht_None, ht_None),   (ht_ArmorWorkshop, ht_None, ht_None, ht_None),   (ht_None, ht_None, ht_None, ht_None),   (ht_Butchers, ht_None, ht_None, ht_None),
    (ht_Tannery, ht_None, ht_None, ht_None), (ht_None, ht_None, ht_None, ht_None), (ht_None, ht_None, ht_None, ht_None), (ht_None, ht_None, ht_None, ht_None), (ht_None, ht_None, ht_None, ht_None),
    (ht_None, ht_None, ht_None, ht_None), (ht_None, ht_None, ht_None, ht_None), (ht_None, ht_None, ht_None, ht_None), (ht_None, ht_None, ht_None, ht_None), (ht_None, ht_None, ht_None, ht_None),
    (ht_None, ht_None, ht_None, ht_None), (ht_None, ht_None, ht_None, ht_None), (ht_None, ht_None, ht_None, ht_None)
  );
  }

implementation
uses
  KM_HandsCollection, KM_Hand, KM_Resource, KM_Game;


{ TKMCityPredictor }
constructor TKMCityPredictor.Create(aPlayer: TKMHandIndex);
begin
  inherited Create;
  fOwner := aPlayer;
end;

destructor TKMCityPredictor.Destroy();
begin
  inherited;
end;


procedure TKMCityPredictor.OwnerUpdate(aPlayer: TKMHandIndex);
begin
  fOwner := aPlayer;
end;


procedure TKMCityPredictor.AfterMissionInit;
var
  WT: TWareType;
begin
  for WT := Low(fWareBalance) to High(fWareBalance) do
    fWareBalance[WT].Estimation := gHands[fOwner].Stats.GetWareBalance(WT);
  // Top priority for gold mines
  gHands[fOwner].Stats.WareDistribution[wt_coal, ht_Metallurgists] := 5;
  gHands[fOwner].Stats.WareDistribution[wt_coal, ht_WeaponSmithy] := 3;
  gHands[fOwner].Stats.WareDistribution[wt_coal, ht_IronSmithy] := 4;
  gHands[fOwner].Stats.WareDistribution[wt_coal, ht_ArmorSmithy] := 3;

  gHands[fOwner].Houses.UpdateResRequest;
end;


// Update ware production
procedure TKMCityPredictor.UpdateWareProduction(aWT: TWareType);
begin
  fWareBalance[aWT].Production := fCityStats.Houses[PRODUCTION[aWT]] * ProductionRate[aWT];
end;


// Update ware consumption
procedure TKMCityPredictor.UpdateWareConsumption(aWT: TWareType);
var
  I: Integer;
  HousesConsumption: Single;
  HT: THouseType;
  WT: TWareType;
begin
  fWareBalance[aWT].Consumption := 0;
  for I := Low(CONSUMPTION[aWT]) to High(CONSUMPTION[aWT]) do
    if (CONSUMPTION[aWT,I] <> wt_None) then
      fWareBalance[aWT].Consumption := fWareBalance[aWT].Consumption + fWareBalance[ CONSUMPTION[aWT,I] ].Consumption * CONSUMPTION_RATIO[aWT,I]
    else
      break;
  //gRes.Houses[HT].ResOutput[1]
end;


// Update food consumption
procedure TKMCityPredictor.UpdateFoodConsumption();
const
  CITIZEN_FOOD_COEF = 0.05; //On average citizen needs to eat each 40min but takes 2 food to full status = 1/20 = 0.05
  SOLDIER_FOOD_COEF = 0.025; //On average soldier needs to eat each 40min and takes 1 food to full status = 1/40 = 0.025
var
  Consumption: Single;
begin
  // Get consumption of city + army
  Consumption := (fCityStats.CitizensCnt * CITIZEN_FOOD_COEF) + (fCityStats.WarriorsCnt * SOLDIER_FOOD_COEF);
  // Calculate consumption of leather armor / min and pigs which are produced with this cycle
  // 2x armor = 2x leather = 1x skin = 1x pig = 3x sausages ... sausages = 3 / 2 * armor = 1.5 * armor
  fWareBalance[wt_Sausages].Consumption := Min(Consumption, fWareBalance[wt_Armor].Consumption * 1.5);
  // Split rest of consumtion into other houses
  Consumption := Max(0, Consumption - fWareBalance[wt_Sausages].Consumption);
  fWareBalance[wt_Bread].Consumption := Consumption * 0.7;
  fWareBalance[wt_Wine].Consumption := Consumption * 0.3;
  fWareBalance[wt_Fish].Consumption := 0;
end;


// Update ware derivation ( derivation * 100 = change of ware in 1 min in % )
procedure TKMCityPredictor.UpdateWareDerivation(aWT: TWareType);
const
  DERIVATION_LIMIT = -0.05; // Ignore changes into 5%
  BALANCE_TOLERANCE = 0.15; // Don't build house when there is balance under 10%
var
  HouseReqCnt: Integer;
begin
  HouseReqCnt := 0;
  with fWareBalance[aWT] do
  begin
    Estimation := Production - Consumption + gHands[fOwner].Stats.GetWareBalance(aWT); // Actualize estimator
    Derivation := (Estimation - gHands[fOwner].Stats.GetWareBalance(aWT));// Max(Estimation, 1); // Compute derivation using previous and current estimation
    if (Derivation < DERIVATION_LIMIT) then //AND ( (Production - Consumption) < BALANCE_TOLERANCE * Consumption ) then
    begin
      HouseReqCnt := Ceil((Consumption - Production) / ProductionRate[aWT]);
      pom := HouseReqCnt;
    end;
  end;
  RequiredHouses[PRODUCTION[aWT]] := Max( RequiredHouses[PRODUCTION[aWT]], HouseReqCnt);
end;


// Update ware consumption
procedure TKMCityPredictor.UpdateWareBalance(aSkipWeaponsCalculation: Boolean = False);
const
  STONE_NEED_PER_A_WORKER = 0.8;
  WOOD_NEED_PER_A_WORKER = 0.3;
  GOLD_FOR_A_SCHOOL = 2.5; // Amount of gold which requires school (in 1 minute)
var
  I: Integer;
begin
  // Update weapons
  for I := CO_WEAPONS_MAX downto CO_WEAPONS_MIN do
  begin
    UpdateWareProduction(CONSUMPTION_ORDER[I]);
    // Consumption was set in initialization
    UpdateWareDerivation(CONSUMPTION_ORDER[I]);
  end;

  // Update "Normal" ware flow
  UpdateFoodConsumption(); // Update food at once
  for I := CO_WARE_MAX downto CO_WARE_MIN do
  begin
    UpdateWareProduction(CONSUMPTION_ORDER[I]);
    // Exeptions
    case CONSUMPTION_ORDER[I] of
      // Food was updated at once
      wt_Wine, wt_Bread, wt_Sausages, wt_Fish:
        begin
        end;
      // Update Materials / Gold
      wt_Gold:  fWareBalance[wt_Gold].Consumption := (fCityStats.Houses[ht_School] + RequiredHouses[ht_School]) * GOLD_FOR_A_SCHOOL;
      wt_Stone: fWareBalance[wt_Stone].Consumption := Min(fCityStats.Citizens[ut_Worker]+10, gHands[fOwner].AI.Setup.WorkerCount) * STONE_NEED_PER_A_WORKER;
      wt_Wood:
        begin
          UpdateWareConsumption(CONSUMPTION_ORDER[I]);
          fWareBalance[wt_Wood].Consumption := Max(fWareBalance[wt_Wood].Consumption, fCityStats.Citizens[ut_Worker] * WOOD_NEED_PER_A_WORKER);
        end;
      // Other cases
      else UpdateWareConsumption(CONSUMPTION_ORDER[I]);
    end;
    UpdateWareDerivation(CONSUMPTION_ORDER[I]);
  end;
end;


// Get players stats
procedure TKMCityPredictor.UpdateCityStats();
var
  UT: TUnitType;
  HT: THouseType;
begin
  with fCityStats do
  begin
    CitizensCnt := 0;
    for UT := Low(Citizens) to High(Citizens) do
    begin
      Citizens[UT] := gHands[fOwner].Stats.GetUnitQty(UT);
      CitizensCnt := CitizensCnt + Citizens[UT];
    end;
    WarriorsCnt := 0;
    for UT := Low(Warriors) to High(Warriors) do
    begin
      Warriors[UT] := gHands[fOwner].Stats.GetUnitQty(UT);
      WarriorsCnt := WarriorsCnt + Warriors[UT];
    end;
    HousesCnt := 0;
    for HT := Low(Houses) to High(Houses) do
    begin
      Houses[HT] := gHands[fOwner].Stats.GetHouseTotal(HT);
      HousesCnt := HousesCnt + Houses[HT];
    end;
  end;
end;


procedure TKMCityPredictor.UpdateBasicHouses(aInitialization: Boolean = False);
const
  INN_TIME_LIMIT = 7000; // ~ 12 minutes from start
  FIRST_MARKETPLACE = 20000;
  SECOND_MARKETPLACE = 30000;
var
  WT: TWareType;
begin
  // 1 Storehouse
  RequiredHouses[ht_Store] := 1 - fCityStats.Houses[ht_Store];
  // 1 Barracks (build only when we have or produce axe / armors)
  RequiredHouses[ht_Barracks] := Byte(aInitialization OR (gHands[fOwner].Stats.GetWareBalance(wt_Axe)+gHands[fOwner].Stats.GetWareBalance(wt_Armor)+gHands[fOwner].Stats.GetWareBalance(wt_MetalArmor) > 0)) - fCityStats.Houses[ht_Barracks];
  // Schools (at least 1 + WarriorsPerMinute criterium)
  RequiredHouses[ht_School] := 1 + Byte(  (fCityStats.Houses[ht_Barracks] > 0) OR aInitialization ) * (Round(gHands[fOwner].AI.Setup.WarriorsPerMinute) shr 1) - fCityStats.Houses[ht_School]; // CHANGE IT!!!!!!!!!
  // Inn (at least 1 after INN_TIME_LIMIT + CitizensCnt criterium)
  RequiredHouses[ht_Inn] := Max(0, Ceil(  Byte( (gGame.GameTickCount > INN_TIME_LIMIT) OR aInitialization ) * fCityStats.CitizensCnt / 80  ) - fCityStats.Houses[ht_Inn]);
  // Marketplace - 1. after FIRST_MARKETPLACE; 2. after SECOND_MARKETPLACE
  RequiredHouses[ht_MarketPlace] := Byte( aInitialization OR (gGame.GameTickCount > FIRST_MARKETPLACE) ) + Byte( aInitialization OR (gGame.GameTickCount > SECOND_MARKETPLACE) ) - fCityStats.Houses[ht_Marketplace];
end;


procedure TKMCityPredictor.CityInitialization(aGoldMineCnt, aIronMineCnt, aFieldCnt, aBuildCnt: Integer);

  procedure AddCitizens(aUT: TUnitType; aCnt: Word; aOverride: Boolean = False);
  begin
    fCityStats.CitizensCnt := fCityStats.CitizensCnt - fCityStats.Citizens[aUT] * Byte(aOverride) + aCnt;
    fCityStats.Citizens[aUT] := fCityStats.Citizens[aUT] * Byte(not aOverride) + aCnt;
  end;
  procedure AddWarriors(aUT: TUnitType; aCnt: Word; aOverride: Boolean = False);
  begin
    fCityStats.WarriorsCnt := fCityStats.WarriorsCnt - fCityStats.Warriors[aUT] * Byte(aOverride) + aCnt;
    fCityStats.Warriors[aUT] := fCityStats.Warriors[aUT] * Byte(not aOverride) + aCnt;
  end;
  procedure AddHouses(aHT: THouseType; aCnt: Word; aOverride: Boolean = False);
  begin
    fCityStats.HousesCnt := fCityStats.HousesCnt - fCityStats.Houses[aHT] * Byte(aOverride) + aCnt;
    fCityStats.Houses[aHT] := fCityStats.Houses[aHT] * Byte(not aOverride) + aCnt;
  end;

var
  I: Integer;
  MaxWeaponProduction: Single;
  WT: TWareType;
  HT: THouseType;
const
  IRON_WARFARE: array[0..4] of TWareType = (wt_MetalShield, wt_MetalArmor, wt_Sword, wt_Hallebard, wt_Arbalet);
  STANDARD_WARFARE: array[0..4] of TWareType = (wt_Shield, wt_Armor, wt_Axe, wt_Pike, wt_Bow);
begin
  // Estimation of final weapons production
  // Iron weapons
  MaxWeaponProduction := 1*ProductionRate[wt_IronOre];//aIronMineCnt * ProductionRate[wt_IronOre];
  for I := Low(IRON_WARFARE) to High(IRON_WARFARE) do
    fWareBalance[ IRON_WARFARE[I] ].Consumption := MaxWeaponProduction / 2.0;
  // Standard weapons
  MaxWeaponProduction := 3*ProductionRate[wt_Axe];//(1.0 + Max(0, aBuildCnt - 1500) / 375) * ProductionRate[wt_Axe]; // 1 <-> 5 in matter of avaiable place
  for I := Low(STANDARD_WARFARE) to High(STANDARD_WARFARE) do
    fWareBalance[ STANDARD_WARFARE[I] ].Consumption := MaxWeaponProduction / 2.0;

  // Plan city stats
  UpdateCityStats(); // Compute what we have
  // Predict final city stats
  fCityStats.CitizensCnt := 150;  // Change it!!!!!!!!!!!!!!!!
  fCityStats.WarriorsCnt := 150;
  fCityStats.Citizens[ut_Worker] := gHands[fOwner].AI.Setup.WorkerCount;

  for HT := Low(RequiredHouses) to High(RequiredHouses) do
    RequiredHouses[HT] := 0;

  UpdateBasicHouses(True);

  UpdateWareBalance();

end;


procedure TKMCityPredictor.UpdateState(aTick: Cardinal);
var
  HT: THouseType;
begin
  for HT := Low(RequiredHouses) to High(RequiredHouses) do
    RequiredHouses[HT] := 0;
  UpdateCityStats();
  UpdateBasicHouses();
  UpdateWareBalance();
end;


procedure TKMCityPredictor.LogStatus(var aBalanceText: UnicodeString);
const
  COLOR_WHITE = '[$FFFFFF]';
  COLOR_RED = '[$0000FF]';
  COLOR_YELLOW = '[$00FFFF]';
  COLOR_GREEN = '[$00FF00]';
  WARE_TO_STRING: array[WARE_MIN..WARE_MAX] of UnicodeString = (
    'Trunk',   'Stone',   'Wood',        'IronOre',   'GoldOre',
    'Coal',    'Steel',   'Gold',        'Wine',      'Corn',
    'Bread',   'Flour',   'Leather',     'Sausages',  'Pig',
    'Skin',    'Shield',  'MetalShield', 'Armor',     'MetalArmor',
    'Axe',     'Sword',   'Pike',        'Hallebard', 'Bow',
    'Arbalet', 'Horse',   'Fish'
  );
  HOUSE_TO_STRING: array[HOUSE_MIN..HOUSE_MAX] of UnicodeString = (
    'ArmorSmithy',     'ArmorWorkshop',   'Bakery',        'Barracks',      'Butchers',
    'CoalMine',        'Farm',            'FisherHut',     'GoldMine',      'Inn',
    'IronMine',        'IronSmithy',      'Marketplace',   'Metallurgists', 'Mill',
    'Quary',           'Sawmill',         'School',        'SiegeWorkshop', 'Stables',
    'Store',           'Swine',           'Tannery',       'TownHall',      'WatchTower',
    'WeaponSmithy',    'WeaponWorkshop',  'Wineyard',      'Woodcutters'
  );

  procedure AddWare(aWT: TWareType; aSpecificText: UnicodeString);
  var
    ProductionColor, ConsumptionColor, DerivationColor: UnicodeString;
  begin
    with fWareBalance[aWT] do
    begin
      ProductionColor := COLOR_YELLOW;
      ConsumptionColor := COLOR_YELLOW;
      DerivationColor := COLOR_YELLOW;
      if (Production > 0) then
        ProductionColor := COLOR_GREEN;
      if (Consumption > 0) then
        ConsumptionColor := COLOR_RED;
      if (Derivation > 0) then
        DerivationColor := COLOR_GREEN
      else if (Derivation < 0) then
        DerivationColor := COLOR_RED;
      aBalanceText := aBalanceText + aSpecificText + Format(': ('+ProductionColor+'%.2f'+COLOR_WHITE+'; '+ConsumptionColor+'%.2f'+COLOR_WHITE+'; '+DerivationColor+'%.2f '+COLOR_WHITE+')|', [Production, Consumption, Derivation]);
    end;
  end;
var
  I: Integer;
  WT: TWareType;
  HT: THouseType;
begin
  aBalanceText := 'Ware balance (ware type -> production; consumption; derivation):|';
  //{
  for I := CO_WARE_MIN to CO_WARE_MAX do
    AddWare(CONSUMPTION_ORDER[I], WARE_TO_STRING[ CONSUMPTION_ORDER[I] ]);
  AddWare(wt_Armor, 'Armors');
  AddWare(wt_Axe, 'Weapons');
  AddWare(wt_MetalArmor, 'Iron Armors');
  AddWare(wt_Sword, 'Iron Weapons');
  //}
  aBalanceText := aBalanceText + '|Required houses: |';
  I := 0;
  for HT := Low(RequiredHouses) to High(RequiredHouses) do
    if (RequiredHouses[HT] > 0) then
    begin
      I := I + 1;
      if (I = 5) then
      begin
        I := 0;
        aBalanceText := aBalanceText + '|';
      end;
      aBalanceText := aBalanceText + Format('%Dx ', [ RequiredHouses[HT] ]) + HOUSE_TO_STRING[HT] + ';';
    end;


  //T%.1f W%.1f W%.1f|
end;






procedure TKMCityPredictor.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.Write(fOwner);

  //Save because there are demands for weaponry (set by General)

  //These are not saved because they are recalculated before each use
  {SaveStream.Write(fDemandCore, SizeOf(fDemandCore));}
end;


procedure TKMCityPredictor.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.Read(fOwner);

  //Load demands for weaponry set by General

  //These are not loaded because they are recalculated before each use
  {LoadStream.Read(fDemandCore, SizeOf(fDemandCore));}
end;


end.


