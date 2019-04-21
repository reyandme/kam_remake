unit KM_CityPredictor;
{$I KaM_Remake.inc}
interface
uses
  Classes, Graphics, KromUtils, Math, SysUtils,
  KM_Defaults, KM_Points, KM_CommonClasses, KM_CommonTypes,
  KM_AISetup, KM_ResHouses, KM_ResWares, KM_HandStats;

var
  GA_PREDICTOR_STONE_NEED_PER_A_WORKER : Single = 0.648239613;
  GA_PREDICTOR_WOOD_NEED_PER_A_WORKER  : Single = 0.280672461;

type
  TWareBalance = record
    Production, ActualConsumption, FinalConsumption, Exhaustion, Fraction: Single;
  end;
  // Information about city (it can be replaced by player's stats but it doesnt allow prediction with different values)
  TCityStats = record
    CitizensCnt, WarriorsCnt, HousesCnt: Integer;
    Citizens: array[CITIZEN_MIN..CITIZEN_MAX] of Integer; // Stats sometimes throw negative number in case of Recruit so keep integer
    Warriors: array[WARRIOR_MIN..WARRIOR_MAX] of Integer;
    Houses: array[HOUSE_MIN..HOUSE_MAX] of Integer;
  end;
  THouseBuildHistory = record
    Count: Word;
    Quantity: TKMWordArray;
    Tick: TKMCardinalArray;
  end;
  TWareBalanceArray = array[WARE_MIN..WARE_MAX] of TWareBalance;
  //TWarfareDemands = array[WARFARE_MIN..WARFARE_MAX] of Single;
  TRequiredHousesArray = array[HOUSE_MIN..HOUSE_MAX] of Integer;

  // City predictor (calculation of required houses based on prediction of resource flow)
  TKMCityPredictor = class
  private
    fOwner: TKMHandID;
    fCityStats: TCityStats;
    fWorkerCount: Word;
    fGoldMineCnt, fIronMineCnt, fFieldCnt, fBuildCnt: Integer;
    fMaxIronWeapProd, fMaxWoodWeapProd, fMaxSoldiersInMin, fPeaceFactor, fUpdatedPeaceFactor: Single;
    fWareBalance: TWareBalanceArray;
    fFarmBuildHistory: THouseBuildHistory; // Farms are another exception in production (production is delayed and depends on position of each farm)
    fSetup: TKMHandAISetup;

    procedure UpdateWareProduction(aWT: TKMWareType);
    procedure UpdateWareConsumption(aWT: TKMWareType; aInitialization: Boolean = False);
    procedure UpdateFoodConsumption(aInitialization: Boolean = False);
    procedure UpdateGoldConsumption(aInitialization: Boolean = False);
    procedure UpdateBuildMaterialConsumption(aInitialization: Boolean = False);
    procedure UpdateWareDerivation(aWT: TKMWareType; aInitialization: Boolean = False);
    procedure UpdateWareBalance(aInitialization: Boolean = False);

    procedure UpdateBasicHouses(aTick: Cardinal; aInitialization: Boolean = False);
    procedure UpdateFinalProduction(aIncPeaceFactor: Single = 0);
    procedure UpdateCityStats();

    procedure FilterRequiredHouses(aTick: Cardinal);
  public
    RequiredHouses: TRequiredHousesArray;

    constructor Create(aPlayer: TKMHandID; aSetup: TKMHandAISetup);
    destructor Destroy(); override;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

    property CityStats: TCityStats read fCityStats;
    property WareBalance: TWareBalanceArray read fWareBalance;
    property WorkerCount: Word read fWorkerCount;
    property GoldMineCnt: Integer read fGoldMineCnt write fGoldMineCnt;
    property IronMineCnt: Integer read fIronMineCnt write fIronMineCnt;
    property FieldCnt: Integer read fFieldCnt write fFieldCnt;
    property BuildCnt: Integer read fBuildCnt write fBuildCnt;

    procedure AfterMissionInit();
    procedure UpdateState(aTick: Cardinal);
    procedure LogStatus(var aBalanceText: UnicodeString);
    procedure OwnerUpdate(aPlayer: TKMHandID);
    procedure MarkExhaustedIronMine();

  end;

const

  {
  TKMWareType:
  wtNone,
  wtTrunk,   wtStone,   wtWood,        wtIronOre,   wtGoldOre,
  wtCoal,    wtSteel,   wtGold,        wtWine,      wtCorn,
  wtBread,   wtFlour,   wtLeather,     wtSausages,  wtPig,
  wtSkin,    wtShield,  wtMetalShield, wtArmor,     wtMetalArmor,
  wtAxe,     wtSword,   wtPike,        wtHallebard, wtBow,
  wtArbalet, wtHorse,   wtFish,
  wtAll,     wtWarfare, wtFood
  }
  // Array of wares which are produced by specific houses
  PRODUCTION_WARE2HOUSE: array[WARE_MIN..WARE_MAX] of TKMHouseType = (
    htWoodcutters,    htQuary,         htSawmill,        htIronMine,      htGoldMine,
    htCoalMine,       htIronSmithy,    htMetallurgists,  htWineyard,      htFarm,
    htBakery,         htMill,          htTannery,        htButchers,      htSwine,
    htSwine,          htArmorWorkshop, htArmorSmithy,    htArmorWorkshop, htArmorSmithy,
    htWeaponWorkshop, htWeaponSmithy,  htWeaponWorkshop, htWeaponSmithy,  htWeaponWorkshop,
    htWeaponSmithy,   htStables,       htFisherHut
  );
  // Possible transformation of wares: resource -> product
  CONSUMPTION_WARE: array[WARE_MIN..WARE_MAX] of array[0..3] of TKMWareType = (         // wtShield are ignored
    (wtWood, wtNone, wtNone, wtNone), (wtNone, wtNone, wtNone, wtNone), (wtAxe, wtNone, wtNone, wtNone), (wtSteel, wtNone, wtNone, wtNone), (wtGold, wtNone, wtNone, wtNone),
    (wtSteel, wtGold, wtMetalArmor, wtSword), (wtMetalArmor, wtSword, wtNone, wtNone), (wtNone, wtNone, wtNone, wtNone), (wtNone, wtNone, wtNone, wtNone), (wtFlour, wtPig, wtHorse, wtNone),
    (wtNone, wtNone, wtNone, wtNone), (wtBread, wtNone, wtNone, wtNone), (wtArmor, wtNone, wtNone, wtNone), (wtNone, wtNone, wtNone, wtNone), (wtSausages, wtNone, wtNone, wtNone),
    (wtLeather, wtNone, wtNone, wtNone), (wtNone, wtNone, wtNone, wtNone), (wtNone, wtNone, wtNone, wtNone), (wtNone, wtNone, wtNone, wtNone), (wtNone, wtNone, wtNone, wtNone),
    (wtNone, wtNone, wtNone, wtNone), (wtNone, wtNone, wtNone, wtNone), (wtNone, wtNone, wtNone, wtNone), (wtNone, wtNone, wtNone, wtNone), (wtNone, wtNone, wtNone, wtNone),
    (wtNone, wtNone, wtNone, wtNone), (wtNone, wtNone, wtNone, wtNone), (wtNone, wtNone, wtNone, wtNone)
  );
  // Array of wares which are consumed in specific amount to achieve specific production (because of exceptions in htWeaponWorkshop / htSwine / htStables etc.)
  CONSUMPTION_RATIO: array[wtTrunk..wtSkin] of array[0..3] of Single = (
    // 1 trunk = 2 Wood                2 wood = 1 axe/bow/spear        1 GoldOre = 2 Gold (+ 1 Coal)
    (0.5, 1, 1, 1),   (1, 1, 1, 1),   (2, 1, 1, 1),   (1, 1, 1, 1),   (0.5, 1, 1, 1),
    // 1 coal = 2 gold (+ 1 gold ore)                                    BEAST_COST = 4 (per a pig / horse)
    (0.5, 1, 1, 1),   (1, 1, 1, 1),   (1, 1, 1, 1),   (1, 1, 1, 1),   (1, 4, 4, 1),
    //               1 flour = 2 bread                                 1 pig = 3 sausages
    (1, 1, 1, 1),   (0.5, 1, 1, 1),   (1, 1, 1, 1),   (1, 1, 1, 1),   (0.333, 1, 1, 1),
    // 1 skin = 2 leather
    (0.5, 1, 1, 1)
  );
  CONSUMPTION_ORDER: array[0..27] of TKMWareType = ( // Basicaly TKMWareType but sorted by order: resource -> product
    wtStone,   wtTrunk,    wtWood,
    wtCorn,    wtFlour,    wtBread,     wtWine,        wtFish,
    wtPig,     wtSausages, wtSkin,      wtLeather,     wtHorse,
    wtGoldOre, wtIronOre,  wtCoal,      wtGold,        wtSteel,
    wtAxe,     wtBow,      wtPike,      wtArmor,       wtShield,
    wtSword,   wtArbalet,  wtHallebard, wtMetalShield, wtMetalArmor
  );
  CO_WEAPONS_MIN = 18;
  CO_WEAPONS_MAX = 27;
    CO_IRON_WEAPONS_MIN = 23;
    CO_IRON_WEAPONS_MAX = 27;
    CO_WOOD_WEAPONS_MIN = 22;
    CO_WOOD_WEAPONS_MAX = 18;
  CO_WARE_MIN = 0;
  CO_WARE_MAX = 17;
  {
  // Array of wares which are consumed by specific houses
  CONSUMPTION_WARE: array[WARE_MIN..WARE_MAX] of array[0..3] of TKMHouseType = (
    (htSawmill, htNone, htNone, htNone),   (htNone, htNone, htNone, htNone),   (htWeaponWorkshop, htArmorWorkshop, htNone, htNone),   (htIronSmithy, htNone, htNone, htNone),   (htMetallurgists, htNone, htNone, htNone),
    (htMetallurgists, htIronSmithy, htArmorSmithy, htWeaponSmithy),   (htArmorSmithy, htWeaponSmithy, htNone, htNone),   (htNone, htNone, htNone, htNone),   (htNone, htNone, htNone, htNone),   (htMill, htSwine, htStables, htNone),
    (htNone, htNone, htNone, htNone),   (htBakery, htNone, htNone, htNone),   (htArmorWorkshop, htNone, htNone, htNone),   (htNone, htNone, htNone, htNone),   (htButchers, htNone, htNone, htNone),
    (htTannery, htNone, htNone, htNone), (htNone, htNone, htNone, htNone), (htNone, htNone, htNone, htNone), (htNone, htNone, htNone, htNone), (htNone, htNone, htNone, htNone),
    (htNone, htNone, htNone, htNone), (htNone, htNone, htNone, htNone), (htNone, htNone, htNone, htNone), (htNone, htNone, htNone, htNone), (htNone, htNone, htNone, htNone),
    (htNone, htNone, htNone, htNone), (htNone, htNone, htNone, htNone), (htNone, htNone, htNone, htNone)
  );
  }

implementation
uses
  KM_HandsCollection, KM_Hand, KM_Resource, KM_Game, KM_CityPlanner;


{ TKMCityPredictor }
constructor TKMCityPredictor.Create(aPlayer: TKMHandID; aSetup: TKMHandAISetup);
begin
  inherited Create;
  fOwner := aPlayer;
  fSetup := aSetup;
  fWorkerCount := 0;

  fGoldMineCnt := 0;
  fIronMineCnt := 0;
  fFieldCnt := 0;
  fBuildCnt := 0;

  fMaxIronWeapProd := 0;
  fMaxWoodWeapProd := 0;
  fMaxSoldiersInMin := 0;
  fPeaceFactor := 0;
  fUpdatedPeaceFactor := 0;

  with fFarmBuildHistory do
  begin
    Count := 1;
    SetLength(Quantity,1);
    SetLength(Tick,1);
    Quantity[0] := 0;
    Tick[0] := 10 * 60 * 10; // Init delay 10 min
  end;
end;

destructor TKMCityPredictor.Destroy();
begin
  inherited;
end;


procedure TKMCityPredictor.Save(SaveStream: TKMemoryStream);
var
  WT: TKMWareType;
begin
  SaveStream.WriteA('CityPredictor');
  SaveStream.Write(fOwner);
  SaveStream.Write(fWorkerCount);

  SaveStream.Write(fGoldMineCnt);
  SaveStream.Write(fIronMineCnt);
  SaveStream.Write(fFieldCnt);
  SaveStream.Write(fBuildCnt);

  SaveStream.Write(fMaxIronWeapProd);
  SaveStream.Write(fMaxWoodWeapProd);
  SaveStream.Write(fMaxSoldiersInMin);
  SaveStream.Write(fPeaceFactor);
  SaveStream.Write(fUpdatedPeaceFactor);

  SaveStream.Write(fFarmBuildHistory.Count);
  if (fFarmBuildHistory.Count > 0) then
  begin
    SaveStream.Write(fFarmBuildHistory.Quantity[0], SizeOf(fFarmBuildHistory.Quantity[0]) * fFarmBuildHistory.Count);
    SaveStream.Write(fFarmBuildHistory.Tick[0], SizeOf(fFarmBuildHistory.Tick[0]) * fFarmBuildHistory.Count);
  end;

  // Requred houses should be saved because of public variable
  SaveStream.Write(RequiredHouses, SizeOf(TRequiredHousesArray));
  // fWareBalance must be saved because of FinalConsumption, Trading and building algorithm
  for WT := WARE_MIN to WARE_MAX do
    SaveStream.Write(fWareBalance[WT], SizeOf(TWareBalance));
  // Stats are updated each cycle and doesn't have to be saved
  //fCityStats: TCityStats;
end;


procedure TKMCityPredictor.Load(LoadStream: TKMemoryStream);
var
  WT: TKMWareType;
begin
  LoadStream.ReadAssert('CityPredictor');
  LoadStream.Read(fOwner);
  LoadStream.Read(fWorkerCount);
  LoadStream.Read(fGoldMineCnt);
  LoadStream.Read(fIronMineCnt);
  LoadStream.Read(fFieldCnt);
  LoadStream.Read(fBuildCnt);
  LoadStream.Read(fMaxIronWeapProd);
  LoadStream.Read(fMaxWoodWeapProd);
  LoadStream.Read(fMaxSoldiersInMin);
  LoadStream.Read(fPeaceFactor);
  LoadStream.Read(fUpdatedPeaceFactor);
  LoadStream.Read(fFarmBuildHistory.Count);
  if (fFarmBuildHistory.Count > 0) then
  begin
    SetLength(fFarmBuildHistory.Quantity, fFarmBuildHistory.Count);
    SetLength(fFarmBuildHistory.Tick, fFarmBuildHistory.Count);
    LoadStream.Read(fFarmBuildHistory.Quantity[0], SizeOf(fFarmBuildHistory.Quantity[0]) * fFarmBuildHistory.Count);
    LoadStream.Read(fFarmBuildHistory.Tick[0], SizeOf(fFarmBuildHistory.Tick[0]) * fFarmBuildHistory.Count);
  end;

  // Requred houses should be saved because of public variable
  LoadStream.Read(RequiredHouses, SizeOf(TRequiredHousesArray));
  // fWareBalance must be saved because of FinalConsumption
  for WT := WARE_MIN to WARE_MAX do
    LoadStream.Read(fWareBalance[WT], SizeOf(TWareBalance));
  // Stats are updated each cycle and doesn't have to be saved
  //fCityStats: TCityStats;
end;


procedure TKMCityPredictor.OwnerUpdate(aPlayer: TKMHandID);
begin
  fOwner := aPlayer;
end;


procedure TKMCityPredictor.MarkExhaustedIronMine();
begin
  fIronMineCnt := fIronMineCnt - 1;
  UpdateFinalProduction();
end;


// Update ware production
procedure TKMCityPredictor.UpdateWareProduction(aWT: TKMWareType);
begin
  fWareBalance[aWT].Production := fCityStats.Houses[ PRODUCTION_WARE2HOUSE[aWT] ] * ProductionRate[aWT];
end;


// Update ware consumption
procedure TKMCityPredictor.UpdateWareConsumption(aWT: TKMWareType; aInitialization: Boolean = False);
var
  I: Integer;
begin
  fWareBalance[aWT].ActualConsumption := 0;
  if aInitialization then
    fWareBalance[aWT].FinalConsumption := 0;
  for I := Low(CONSUMPTION_WARE[aWT]) to High(CONSUMPTION_WARE[aWT]) do
    if (CONSUMPTION_WARE[aWT,I] <> wtNone) then
    begin
      fWareBalance[aWT].ActualConsumption := fWareBalance[aWT].ActualConsumption + fWareBalance[ CONSUMPTION_WARE[aWT,I] ].ActualConsumption * CONSUMPTION_RATIO[aWT,I];
      if aInitialization then
        fWareBalance[aWT].FinalConsumption := fWareBalance[aWT].FinalConsumption + Max(fWareBalance[ CONSUMPTION_WARE[aWT,I] ].FinalConsumption, fWareBalance[ CONSUMPTION_WARE[aWT,I] ].ActualConsumption) * CONSUMPTION_RATIO[aWT,I];
    end
    else
      break;
end;


// Update food consumption
procedure TKMCityPredictor.UpdateFoodConsumption(aInitialization: Boolean = False);
const
  CITIZEN_FOOD_COEF = 0.05; // On average citizen needs to eat each 40min but takes 2 food to full status = 1/20 = 0.05
  SOLDIER_FOOD_COEF = 0.025; // On average soldier needs to eat each 40min and takes 1 food to full status = 1/40 = 0.025
var
  Consumption: Single;
begin
  // Get consumption of city + army
  Consumption := (fCityStats.CitizensCnt * CITIZEN_FOOD_COEF) + (fCityStats.WarriorsCnt * SOLDIER_FOOD_COEF);
  // Calculate consumption of leather armor / minute and pigs which are produced with this cycle
  // 2x armor = 2x leather = 1x skin = 1x pig = 3x sausages ... sausages = 3 / 2 * armor = 1.5 * armor
  fWareBalance[wtSausages].ActualConsumption := Min(Consumption, fWareBalance[wtArmor].FinalConsumption * 1.5);
  // Split rest of consumtion into other houses
  Consumption := Max(0, Consumption - fWareBalance[wtSausages].ActualConsumption);
  fWareBalance[wtBread].ActualConsumption := Consumption * 0.7;
  fWareBalance[wtWine].ActualConsumption := Consumption * 0.3;
  fWareBalance[wtFish].ActualConsumption := 0;
  // Expected food consumption of the final city size (it helps with build order to secure food and weapons production ASAP)
  if aInitialization then
  begin
    fWareBalance[wtSausages].FinalConsumption := fWareBalance[wtSausages].ActualConsumption;
    fWareBalance[wtBread].FinalConsumption := fWareBalance[wtBread].ActualConsumption;
    fWareBalance[wtWine].FinalConsumption := fWareBalance[wtWine].ActualConsumption;
    fWareBalance[wtFish].FinalConsumption := fWareBalance[wtFish].ActualConsumption;
  end;
end;


// Update gold consumption
procedure TKMCityPredictor.UpdateGoldConsumption(aInitialization: Boolean = False);
const
  GOLD_NEED_PER_A_SCHOOL = 3.5; // Amount of gold which requires school (in 1 minute)
begin
  fWareBalance[wtGold].ActualConsumption := Min(fMaxSoldiersInMin, (fCityStats.Houses[htSchool] + RequiredHouses[htSchool]) * GOLD_NEED_PER_A_SCHOOL);
end;


// Update build material consumption
procedure TKMCityPredictor.UpdateBuildMaterialConsumption(aInitialization: Boolean = False);
const
  STONE_NEED_PER_A_WORKER = 0.6;
  WOOD_NEED_PER_A_WORKER = 0.35;
begin
  // Worker count is decreased after peace time -> compute with maximal count
  fWareBalance[wtStone].ActualConsumption := Min(fCityStats.Citizens[utWorker]+8, fWorkerCount) * GA_PREDICTOR_STONE_NEED_PER_A_WORKER;
  fWareBalance[wtStone].FinalConsumption := Max(fCityStats.Citizens[utWorker], fWorkerCount) * GA_PREDICTOR_STONE_NEED_PER_A_WORKER;
  // Raw wood expectations
  UpdateWareConsumption(wtWood, aInitialization);
  fWareBalance[wtWood].ActualConsumption := Max(fWareBalance[wtWood].ActualConsumption, fCityStats.Citizens[utWorker] * GA_PREDICTOR_WOOD_NEED_PER_A_WORKER);
  fWareBalance[wtWood].FinalConsumption := Max(fWareBalance[wtWood].FinalConsumption, fWorkerCount * GA_PREDICTOR_WOOD_NEED_PER_A_WORKER);
end;


// Update ware derivation - 2 views:
// 1. Exhaustion = estimation of time when will be ware depleted (determine which house should be built at first)
// 2. Fraction = fraction of required and available houses
procedure TKMCityPredictor.UpdateWareDerivation(aWT: TKMWareType; aInitialization: Boolean = False);
var
  HouseReqCnt: Integer;
  HT: TKMHouseType;
begin
  HT := PRODUCTION_WARE2HOUSE[aWT];
  with fWareBalance[aWT] do
  begin
    // Calculate when will be ware depleted
    Exhaustion := 99;
    if (ActualConsumption - Production > 0) then
      Exhaustion := Min( Exhaustion, gHands[fOwner].Stats.GetWareBalance(aWT) / (ActualConsumption - Production) );
    HouseReqCnt := Ceil(( Max(ActualConsumption, FinalConsumption) - Production) / Max(0.0001, ProductionRate[aWT]*1.0));
    Fraction := HouseReqCnt / Max(1.0,((fCityStats.Houses[HT] + HouseReqCnt)*1.0));
  end;
  RequiredHouses[HT] := HouseReqCnt;
end;


// Update ware balance
procedure TKMCityPredictor.UpdateWareBalance(aInitialization: Boolean = False);
var
  I: Integer;
begin
  // Update weapons
  for I := CO_WEAPONS_MAX downto CO_WEAPONS_MIN do
  begin
    UpdateWareProduction(CONSUMPTION_ORDER[I]);
    // Final and actual consumptions for weapons are constant
    fWareBalance[ CONSUMPTION_ORDER[I] ].ActualConsumption :=  fWareBalance[ CONSUMPTION_ORDER[I] ].FinalConsumption;
    UpdateWareDerivation(CONSUMPTION_ORDER[I],aInitialization);
  end;

  // Update "Normal" ware flow
  UpdateFoodConsumption(aInitialization);
  UpdateGoldConsumption(aInitialization);
  UpdateBuildMaterialConsumption(aInitialization);
  for I := CO_WARE_MAX downto CO_WARE_MIN do
  begin
    UpdateWareProduction(CONSUMPTION_ORDER[I]);
    // Exeptions
    case CONSUMPTION_ORDER[I] of
      // Food was updated at once
      wtWine, wtBread, wtSausages, wtFish: begin end;
      // Update Gold
      wtGold: begin end;
      // Update materials
      wtStone: begin end;
      wtWood: begin end;
      // Other cases
      else
        UpdateWareConsumption(CONSUMPTION_ORDER[I], aInitialization);
    end;
    UpdateWareDerivation(CONSUMPTION_ORDER[I],aInitialization);
  end;
end;


// Basic house requirements
procedure TKMCityPredictor.UpdateBasicHouses(aTick: Cardinal; aInitialization: Boolean = False);
const
  INN_TIME_LIMIT = 60 * 10 * 14; // ~ 14 minutes from start
  SCHOOL_PRODUCTION = 3; // Amount of gold which requires school (in 1 minute) - in ideal case it requires only 3.5 in real there is not sometimes gold so it must be lower
  FIRST_MARKETPLACE = 10 * 60 * 60;
  SECOND_MARKETPLACE = 10 * 60 * 100;
  BARRACKS_PEACE_DELAY = 30; // Build barracks since 30 min
  BARRACKS_BEFORE_PEACE_END = 20; // Allow to build barracks before peace time end
begin
  // 1 Storehouse
  RequiredHouses[htStore] := 1 - fCityStats.Houses[htStore];
  // 1 Barracks (build only when we have weapons and (from X tick or Y ticks before peace end -> avoid to build barracks in 1 minute when is still peace and we have predefined weapons in storehouse))
  RequiredHouses[htBarracks] := Byte(aInitialization OR ((gHands[fOwner].Stats.GetWareBalance(wtWarfare) > 0) AND ((aTick > BARRACKS_PEACE_DELAY * 600) OR (aTick > (gGame.GameOptions.Peacetime - BARRACKS_BEFORE_PEACE_END) * 600)))) - fCityStats.Houses[htBarracks];
  // Schools (at least 1 + WarriorsPerMinute criterium)
  RequiredHouses[htSchool] := Max( 0,  Max(1, Byte(  (fCityStats.Houses[htBarracks] > 0) OR aInitialization ) * (Ceil(fMaxSoldiersInMin / SCHOOL_PRODUCTION))) - fCityStats.Houses[htSchool]  );
  // Inn (at least 1 after INN_TIME_LIMIT + CitizensCnt criterium)
  RequiredHouses[htInn] := Max(0, Ceil(  Byte( (aTick > INN_TIME_LIMIT) OR aInitialization ) * fCityStats.CitizensCnt / 80  ) - fCityStats.Houses[htInn]);
  // Marketplace - 1. after FIRST_MARKETPLACE; 2. after SECOND_MARKETPLACE
  RequiredHouses[htMarketplace] := Byte( aInitialization OR (aTick > FIRST_MARKETPLACE) ) + Byte( aInitialization OR (aTick > SECOND_MARKETPLACE) ) - fCityStats.Houses[htMarketplace];
end;


// Get players stats and store them into local variable (to be able to edit them later)
procedure TKMCityPredictor.UpdateCityStats();
var
  UT: TKMUnitType;
  HT: TKMHouseType;
  Planner: TKMCityPlanner;
begin
  Planner := gHands[fOwner].AI.CityManagement.Builder.Planner;
  with fCityStats do
  begin
    CitizensCnt := 0;
    for UT := Low(Citizens) to High(Citizens) do
    begin
      Citizens[UT] := gHands[fOwner].Stats.GetUnitQty(UT);
      CitizensCnt := CitizensCnt + Citizens[UT];
    end;
    CitizensCnt := CitizensCnt - Citizens[utRecruit]; // Count recruits as soldiers
    WarriorsCnt := Citizens[utRecruit];
    for UT := Low(Warriors) to High(Warriors) do
    begin
      Warriors[UT] := gHands[fOwner].Stats.GetUnitQty(UT);
      WarriorsCnt := WarriorsCnt + Warriors[UT];
    end;
    HousesCnt := 0;
    for HT := Low(Houses) to High(Houses) do
    begin
      //Houses[HT] := gHands[fOwner].Stats.GetHouseTotal(HT); // Does not consider planned houses
      Houses[HT] := Planner.PlannedHouses[HT].Completed + Planner.PlannedHouses[HT].UnderConstruction; // Consider only placed or planned houses (not destroyed houses - plans will remain in CityPlanner)
      HousesCnt := HousesCnt + Houses[HT];
    end;
  end;
end;


procedure TKMCityPredictor.UpdateFinalProduction(aIncPeaceFactor: Single = 0);
const
  IRON_WARFARE: set of TKMWareType = [wtMetalShield, wtMetalArmor, wtSword, wtHallebard, wtArbalet];
  WOOD_WARFARE: set of TKMWareType = [wtAxe, wtPike, wtBow];
  INV_AFTER_PEACE_SCALING = 1 / (30*10*60); // Peace factor will be completely removed after {30} mins since end of peace
  MIN_IRON_PRODUCTION = 2;
  MAX_IRON_PRODUCTION = 6;
  INV_REQUIRED_TILES_PER_IRON = 1/250;
  MIN_WOOD_PRODUCTION = 2;
  MAX_WOOD_PRODUCTION = 5;
  INV_REQUIRED_TILES_PER_WOOD = 1/450.0;
  TILE_RESERVE = 1000;
var
  MaxIronWeapProd, MaxWoodWeapProd, FreePlace: Single;
  WT: TKMWareType;
begin
  // Update peace factor
  fUpdatedPeaceFactor := Min(1,fUpdatedPeaceFactor + aIncPeaceFactor);
  // Consider available space around loc
  // Iron weapons - use only fixed peace factor because mines will run out anyway
  FreePlace := Max( 0,
                    (Min(fBuildCnt,2000) - TILE_RESERVE) * INV_REQUIRED_TILES_PER_IRON
                  );
  MaxIronWeapProd := Min( Min( MAX_IRON_PRODUCTION, fIronMineCnt ),
                          Round(FreePlace * fPeaceFactor) + MIN_IRON_PRODUCTION
                        );
  // Wooden weapons
  FreePlace := Max( 0,
                    (Min(fFieldCnt,3000) - TILE_RESERVE) * INV_REQUIRED_TILES_PER_WOOD
                  );
  MaxWoodWeapProd := Min( MAX_WOOD_PRODUCTION,
                          Max( MIN_WOOD_PRODUCTION, Round(FreePlace * fUpdatedPeaceFactor) )
                        );
  // Consider Iron production
  MaxWoodWeapProd := Max( MIN_WOOD_PRODUCTION - Byte(MaxIronWeapProd > 0),
                          Round(MaxWoodWeapProd - MaxIronWeapProd * (1.0 - fUpdatedPeaceFactor) * 0.5)
                        );

  // Iron weapons
  MaxIronWeapProd := MaxIronWeapProd * ProductionRate[wtIronOre] * 0.5; // Division into half because of iron weapon and armor
  for WT in IRON_WARFARE do
    fWareBalance[WT].FinalConsumption := MaxIronWeapProd;

  // Wooden weapons
  MaxWoodWeapProd := MaxWoodWeapProd * ProductionRate[wtAxe]; // Production of weapons / armors is ~identical
  for WT in WOOD_WARFARE do
    fWareBalance[WT].FinalConsumption := MaxWoodWeapProd;
  // Exceptions
  fWareBalance[wtArmor].FinalConsumption := MaxWoodWeapProd;
  fWareBalance[wtShield].FinalConsumption := MaxWoodWeapProd / 5; // This only affect wood requirements, shields will be ordered by count of axes

  // Soldiers / min (only expected not final value)
  fMaxSoldiersInMin := MaxWoodWeapProd + MaxIronWeapProd;
  // Maybe there is no need to keep variable fMaxSoldiersInMin but I am afraid what scripters may do with fSetup
  if (fSetup.NewAI AND fSetup.UnlimitedEquip) then
  begin
    fSetup.EquipRateIron := Round(600 / Max(0.01, MaxIronWeapProd));
    fSetup.EquipRateLeather := Round(600 / Max(0.01, MaxWoodWeapProd));
  end;

  // Predict final city stats (by potential size of city)
  fCityStats.CitizensCnt := Round(  Max( 0, Min(fBuildCnt,4000)-1500 )*0.052+70  ); // Min cnt of citizens is 70 and max 200
  fCityStats.WarriorsCnt := Round(  Max( 0, Min(fBuildCnt,4000)-1500 )*0.042+50  ); // Min cnt of soldiers is 50 and max 150
  UpdateWareBalance(True);

  // Decide count of workers + build nodes
  // fSetup.WorkerCount -> better use local variable
  FreePlace := Max(  0, Min( 2000, Min(fFieldCnt,fBuildCnt) - 1000 )  ); // FreePlace in <0,2000>
  fWorkerCount := Round( Min( 30 - 20 * fUpdatedPeaceFactor * Byte(not gGame.IsPeaceTime), // Decrease count of required workers after peace
                              10 + FreePlace*0.008 + fPeaceFactor*8 )
                       );
end;


// City initialization, estimation of maximal possible production and restriction by peace time and loc properties
procedure TKMCityPredictor.AfterMissionInit;
const
  SCALE_MIN_PEACE_TIME = 50;
  SCALE_MAX_PEACE_TIME = 90;
  SCALE_PEACE_FACTOR = 1.0 / ((SCALE_MAX_PEACE_TIME - SCALE_MIN_PEACE_TIME)*1.0);
begin
  // PeaceFactor: 0 = peace <= SCALE_MIN_PEACE_TIME; 1 = peace >= SCALE_MAX_PEACE_TIME
  fPeaceFactor := Max(0,
                      (Min(SCALE_MAX_PEACE_TIME, gGame.GameOptions.Peacetime) - SCALE_MIN_PEACE_TIME)
                     ) * SCALE_PEACE_FACTOR;

  UpdateFinalProduction();
end;


procedure TKMCityPredictor.FilterRequiredHouses(aTick: Cardinal);
  function UpdateFarmHistory(): Boolean;
  const
    CORN_DELAY = 10 * 60 * 6; // Delay 6 minutes or use array ProductionLag from KM_ResWares
  var
    I, K, Cnt: Integer;
  begin
    with fFarmBuildHistory do
    begin
      // Remove old history
      if (Count > 1) then // Keep at least 1 element (the latest)
      begin
        I := 0;
        while (I < Count) do // Find the actual tick
        begin
          if (Tick[I] > aTick) then
            break;
          I := I + 1;
        end;
        if (I > 1) then // Keep the latest older element
        begin
          Cnt := 0;
          for K := I - 1 to Count - 1 do // Remove old ticks
          begin
            Quantity[Cnt] := Quantity[K];
            Tick[Cnt] := Tick[K];
            Cnt := Cnt + 1;
          end;
          Count := Cnt;
        end;
      end;
      Cnt := gHands[fOwner].Stats.GetHouseQty(htFarm);
      if (Quantity[Count-1] <> Cnt) then
      begin
        if (Length(Quantity) <= Count) then
        begin
          SetLength(Quantity, Length(Quantity) + 5);
          SetLength(Tick, Length(Tick) + 5);
        end;
        Quantity[Count] := Cnt;
        Tick[Count] := aTick + CORN_DELAY;
        Count := Count + 1;
      end;
    end;
    Result := + fWareBalance[wtFlour].Production
              + fWareBalance[wtPig].Production * 4
              + fWareBalance[wtHorse].Production * 4
              >=
              + fFarmBuildHistory.Quantity[0] * ProductionRate[wtCorn]
              + gHands[fOwner].Stats.GetWareBalance(wtCorn) * 0.25;
  end;

  procedure CheckPeaceFactor();
  const
    MINES: set of TKMHouseType = [htCoalMine, htGoldMine, htIronMine];
  var
    Cnt: Integer;
    HT: TKMHouseType;
  begin
    if (fUpdatedPeaceFactor < 1) then
    begin
      Cnt := 0;
      for HT := Low(RequiredHouses) to High(RequiredHouses) do
        if not (HT in MINES) then
          Inc(Cnt, RequiredHouses[HT]);
      if (Cnt = 0) then
        UpdateFinalProduction(0.1);
    end;
  end;
const
  WEAP_WORKSHOP_DELAY = 35 * 60 * 10;
  WINEYARD_DELAY = 50 * 60 * 10;
var
  Stats: TKMHandStats;
  Planner: TKMCityPlanner;
begin
  Planner := gHands[fOwner].AI.CityManagement.Builder.Planner;
  Stats := gHands[fOwner].Stats;

  // Dont build anything if there is not completed school
  if (fCityStats.Houses[htSchool] = 0)
    OR ( (fCityStats.Houses[htSchool] = 1)
         AND (not (Planner.PlannedHouses[htSchool].Plans[0].Placed)
              OR not ( (Planner.PlannedHouses[htSchool].Plans[0].House <> nil)
                       AND Planner.PlannedHouses[htSchool].Plans[0].House.IsComplete
                     )
             )
       ) then
  begin
    FillChar(RequiredHouses, SizeOf(RequiredHouses), #0);
    // Allow to reserve quarries
    UpdateWareProduction(wtStone);
    fWareBalance[wtStone].ActualConsumption := Min(fCityStats.Citizens[utWorker]+8, fWorkerCount) * GA_PREDICTOR_STONE_NEED_PER_A_WORKER;
    fWareBalance[wtStone].FinalConsumption := Max(fCityStats.Citizens[utWorker], fWorkerCount) * GA_PREDICTOR_STONE_NEED_PER_A_WORKER;
    UpdateWareDerivation(wtStone);
    RequiredHouses[htSchool] := Max(0, 1 - Planner.PlannedHouses[htSchool].Count);
    Exit;
  end;

  // Check requirements
  CheckPeaceFactor();

  // Remove unused houses (iron production)
  if (RequiredHouses[htIronSmithy] < 0) AND (Stats.GetWareBalance(wtIronOre) < 20) then // Dont destroy iron production when there is still iron ore
    Planner.RemoveHouseType(htIronSmithy);
  if (RequiredHouses[htArmorSmithy] < 0) AND (RequiredHouses[htIronSmithy] = 0) then // And dont destroy following production if you dont want to destroy IronSmithy
    Planner.RemoveHouseType(htArmorSmithy);
  if (RequiredHouses[htWeaponSmithy] < 0) AND (RequiredHouses[htIronSmithy] = 0) then
    Planner.RemoveHouseType(htWeaponSmithy);


  // Change house requirements due to nonlinear delay, toons of exceptions and unlock order
  // Dont build wineyard too early
  if (gGame.GameTick < WINEYARD_DELAY) then
    RequiredHouses[htWineyard] := 0;
  // Consideration of corn delay - only remove all required houses, builder will find the right one if they are not removed
  if UpdateFarmHistory() AND not gHands[fOwner].Locks.HouseBlocked[htFarm] then
  begin
    RequiredHouses[htMill] := Byte(fCityStats.Houses[htMill] = 0); // Allow 1 mill from the start
    RequiredHouses[htSwine] := 0;
    RequiredHouses[htStables] := 0;
  end;
  // Houses in dependence on corn delay
  RequiredHouses[htBakery] := Min(RequiredHouses[htBakery], Stats.GetHouseQty(htMill) - fCityStats.Houses[htBakery]);
  RequiredHouses[htButchers] := Min(RequiredHouses[htButchers], Ceil(Stats.GetHouseQty(htSwine)/3 - fCityStats.Houses[htButchers]));
  RequiredHouses[htTannery] := Min(RequiredHouses[htTannery], Ceil(Stats.GetHouseQty(htSwine)/2 - fCityStats.Houses[htTannery]));
  RequiredHouses[htArmorWorkshop] := Min(RequiredHouses[htArmorWorkshop], Stats.GetHouseTotal(htTannery)*2 - fCityStats.Houses[htArmorWorkshop]);
  // Consideration of wood production
  RequiredHouses[htWeaponWorkshop] := RequiredHouses[htWeaponWorkshop] * Byte( (RequiredHouses[htTannery] > 0) OR (WEAP_WORKSHOP_DELAY < aTick) OR (aTick > (gGame.GameOptions.Peacetime-20) * 10 * 60) );

  // Coal mines are used by top priority houses (Metallurgists) and low priority houses (smithy)
  // To get reasonable production there should be something like following logic, good luck with understanding ;)
  RequiredHouses[htCoalMine] := Min( RequiredHouses[htCoalMine],
                                     Max( Max( Planner.PlannedHouses[htMetallurgists].Count, // Gold production requirements
                                               Planner.PlannedHouses[htGoldMine].Count
                                             ),
                                          RequiredHouses[htGoldMine] // Build coal mine in parallel to gold mine
                                        )
                                     - Planner.PlannedHouses[htCoalMine].Count
                                     + Stats.GetHouseTotal(htIronSmithy) // Iron production requirements
                                     + Stats.GetHouseTotal(htArmorSmithy)
                                     + Stats.GetHouseTotal(htWeaponSmithy)
                                   );

  // Loghical house requirements (delay takes too long so it is not used)
  {
  RequiredHouses[htSwine] := RequiredHouses[htSwine] * Byte(Stats.GetWareBalance(wtCorn) > 0);
  RequiredHouses[htButchers] := RequiredHouses[htButchers] * Byte(Stats.GetWareBalance(wtPig) > 0);
  RequiredHouses[htTannery] := RequiredHouses[htTannery] * Byte(Stats.GetWareBalance(wtLeather) > 0);
  RequiredHouses[htArmorWorkshop] := RequiredHouses[htArmorWorkshop] * Byte(Stats.GetWareBalance(wtSkin) > 0);
  RequiredHouses[htMill] := RequiredHouses[htMill] * Byte(Stats.GetWareBalance(wtFlour) > 0);
  RequiredHouses[htBakery] := RequiredHouses[htBakery] * Byte(Stats.GetWareBalance(wtCorn) > 0);
  //}
  // Iron production (it will give time to build more mines)
  {
  RequiredHouses[htIronSmithy] := RequiredHouses[htIronSmithy] * Byte(Stats.GetWareBalance(wtIronOre) > 0);
  RequiredHouses[htWeaponSmithy] := RequiredHouses[htWeaponSmithy] * Byte(Stats.GetWareBalance(wtSteel) > 0);
  RequiredHouses[htArmorSmithy] := RequiredHouses[htArmorSmithy] * Byte(Stats.GetWareBalance(wtSteel) > 0);
  //}
end;


procedure TKMCityPredictor.UpdateState(aTick: Cardinal);
const
  UPDATE_PRODUCTION = MAX_HANDS * 60 * 5;
begin
  // Update final production (based on size of city, mines etc.)
  if (aTick mod UPDATE_PRODUCTION = fOwner) then
    UpdateFinalProduction();
  // Clear required houses
  FillChar(RequiredHouses, SizeOf(RequiredHouses), #0);
  // Update city stats
  UpdateCityStats();
  // Update required basic houses (main buildings)
  UpdateBasicHouses(aTick, False);
  // Update prediction and other houses (production of ware)
  UpdateWareBalance();

  // Filter required houses
  FilterRequiredHouses(aTick);
  //
end;


procedure TKMCityPredictor.LogStatus(var aBalanceText: UnicodeString);
const
  COLOR_WHITE = '[$FFFFFF]';
  COLOR_RED = '[$0000FF]';
  COLOR_YELLOW = '[$00FFFF]';
  COLOR_GREEN = '[$00FF00]';
  WARE_TO_STRING: array[WARE_MIN..WARE_MAX] of UnicodeString = (
    'Trunk       ', 'Stone       ',  'Wood        ', 'IronOre     ', 'GoldOre     ',
    'Coal        ', 'Steel       ',  'Gold        ', 'Wine        ', 'Corn        ',
    'Bread       ', 'Flour       ',  'Leather     ', 'Sausages  ',   'Pig         ',
    'Skin        ', 'Shield      ',  'MetalShield ', 'Armor       ', 'MetalArmor  ',
    'Axe         ', 'Sword       ',  'Pike        ', 'Hallebard   ', 'Bow         ',
    'Arbalet     ', 'Horse       ',  'Fish        '
  );
  //HOUSE_TO_STRING: array[HOUSE_MIN..HOUSE_MAX] of UnicodeString = (
  //  'ArmorSmithy',     'ArmorWorkshop',   'Bakery',        'Barracks',      'Butchers',
  //  'CoalMine',        'Farm',            'FisherHut',     'GoldMine',      'Inn',
  //  'IronMine',        'IronSmithy',      'Marketplace',   'Metallurgists', 'Mill',
  //  'Quary',           'Sawmill',         'School',        'SiegeWorkshop', 'Stables',
  //  'Store',           'Swine',           'Tannery',       'TownHall',      'WatchTower',
  //  'WeaponSmithy',    'WeaponWorkshop',  'Wineyard',      'Woodcutters'
  //);

  procedure AddWare(aWT: TKMWareType; const aSpecificText: String);
  var
    HouseCntColor, ProductionColor, ActualConsumptionColor, FinalConsumptionColor, FractionColor, ExhaustionColor: UnicodeString;
    Cnt: Integer;
  begin
    Cnt := RequiredHouses[ PRODUCTION_WARE2HOUSE[aWT] ];
    HouseCntColor := COLOR_WHITE;
    if (Cnt > 0) then
      HouseCntColor := COLOR_RED;
    with fWareBalance[aWT] do
    begin
      ProductionColor := COLOR_YELLOW;
      ActualConsumptionColor := COLOR_YELLOW;
      FinalConsumptionColor := COLOR_YELLOW;
      FractionColor := COLOR_YELLOW;
      ExhaustionColor := COLOR_RED;
      if (Production > 0) then         ProductionColor := COLOR_GREEN;
      if (ActualConsumption > 0) then  ActualConsumptionColor := COLOR_RED;
      if (FinalConsumption > 0) then   FinalConsumptionColor := COLOR_RED;
      if (Fraction <= 0.1) then        FractionColor := COLOR_GREEN
      else                             FractionColor := COLOR_RED;
      if (Exhaustion > 10) then        ExhaustionColor := COLOR_GREEN
      else if (Exhaustion > 1) then    ExhaustionColor := COLOR_YELLOW;
      aBalanceText := aBalanceText + Format(HouseCntColor+'%dx '+COLOR_WHITE, [Cnt]) //
                        + Format(#9 + '%s ' + #9 + '('
                          + ProductionColor+'%3.2f'+COLOR_WHITE+';' + #9
                          + ActualConsumptionColor+'%3.2f'+COLOR_WHITE+';' + #9
                          + FinalConsumptionColor+'%3.2f'+COLOR_WHITE+';'  + #9
                          + FractionColor+'%3.2f'+COLOR_WHITE+';' + #9
                          + ExhaustionColor+'%3.2f'+COLOR_WHITE+')|',
                          [aSpecificText, Production, ActualConsumption, FinalConsumption, Fraction, Exhaustion]);
    end;
  end;
var
  I: Integer;
begin
  aBalanceText := aBalanceText + 'Ware balance|Required houses (ware type ->   production;   actual consumption;   final consumption;   fraction;   exhaustion):|';
  for I := CO_WARE_MIN to CO_WARE_MAX do
    AddWare(CONSUMPTION_ORDER[I], WARE_TO_STRING[ CONSUMPTION_ORDER[I] ]);
  AddWare(wtArmor, 'Armor           ');
  AddWare(wtAxe, 'Weapon       ');
  AddWare(wtMetalArmor, 'Iron Armor   ');
  AddWare(wtSword, 'Iron Weapon');
  aBalanceText := aBalanceText + 'Max Workers: ' + IntToStr(fWorkerCount) + '|';
end;




end.
