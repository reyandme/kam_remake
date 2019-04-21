unit KM_CityManagement;
{$I KaM_Remake.inc}
interface
uses
  Math, KM_CommonUtils, SysUtils, KM_Defaults, KM_CommonClasses, KM_Points,
  KM_AISetup, KM_ResHouses, KM_ResWares, KM_ResUnits, KM_HandStats, KM_HouseCollection,
  KM_CityPredictor, KM_CityBuilder, KM_CityPlanner, KM_AIArmyEvaluation;

var
  GA_MANAGER_CheckUnitCount_SerfCoef    : Single = 1.42; //0.193077
  GA_MANAGER_CheckUnitCount_SerfLimit   : Single = 1.432; //2.178943

type
  TKMWarfareArr = array[WARFARE_MIN..WARFARE_MAX] of record
    Available, Required: Word;
    Fraction: Single;
  end;
  TKMWarriorsDemands = array[WARRIOR_EQUIPABLE_MIN..WARRIOR_EQUIPABLE_MAX] of Integer;

  TKMCityManagement = class
  private
    fOwner: TKMHandID;
    fSetup: TKMHandAISetup;

    fBuilder: TKMCityBuilder;
    fPredictor: TKMCityPredictor;

    fRequiredWeapons: TKMWarfareArr;
    fWarriorsDemands: TKMWarriorsDemands;

    fBalanceText: UnicodeString;

    procedure CheckUnitCount(aTick: Cardinal);
    procedure CheckMarketplaces();
    procedure CheckStoreWares(aTick: Cardinal);
    procedure CheckExhaustedHouses();
    procedure CheckAutoRepair();
    procedure CheckWareDistribution();

    procedure WeaponsBalance();
    procedure OrderWeapons();

  public
    constructor Create(aPlayer: TKMHandID; aSetup: TKMHandAISetup);
    destructor Destroy(); override;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad();

    procedure AfterMissionInit();
    procedure OwnerUpdate(aPlayer: TKMHandID);

    property Builder: TKMCityBuilder read fBuilder write fBuilder;
    property Predictor: TKMCityPredictor read fPredictor;
    property WarriorsDemands: TKMWarriorsDemands read fWarriorsDemands;
    property BalanceText: UnicodeString read fBalanceText;

    procedure UpdateState(aTick: Cardinal);
    procedure LogStatus(var aBalanceText: UnicodeString);

  end;


implementation
uses
  Classes, KM_Game, KM_Houses, KM_HouseSchool, KM_HandsCollection, KM_Hand, KM_Resource,
  KM_AIFields, KM_Units, KM_UnitsCollection, KM_NavMesh, KM_HouseMarket;


const
  GOLD_SHORTAGE = 10;


{ TKMCityManagement }
constructor TKMCityManagement.Create(aPlayer: TKMHandID; aSetup: TKMHandAISetup);
begin
  inherited Create;

  fOwner := aPlayer;
  fSetup := aSetup;

  fPredictor := TKMCityPredictor.Create(aPlayer, aSetup);
  fBuilder := TKMCityBuilder.Create(aPlayer, fPredictor);
end;


destructor TKMCityManagement.Destroy();
begin
  fPredictor.Free;
  fBuilder.Free;

  inherited;
end;


procedure TKMCityManagement.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.WriteA('CityManagement');
  SaveStream.Write(fOwner);
  SaveStream.Write(fWarriorsDemands, SizeOf(fWarriorsDemands)); // Usend for Army management -> must be saved
  //SaveStream.Write(fRequiredWeapons, SizeOf(fRequiredWeapons)); // Computed every time

  fPredictor.Save(SaveStream);
  fBuilder.Save(SaveStream);
end;


procedure TKMCityManagement.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.ReadAssert('CityManagement');
  LoadStream.Read(fOwner);
  LoadStream.Read(fWarriorsDemands, SizeOf(fWarriorsDemands));
  //LoadStream.Read(fRequiredWeapons, SizeOf(fRequiredWeapons));

  fPredictor.Load(LoadStream);
  fBuilder.Load(LoadStream);
end;


procedure TKMCityManagement.SyncLoad();
begin
  fBuilder.SyncLoad();
end;


procedure TKMCityManagement.OwnerUpdate(aPlayer: TKMHandID);
begin
  fOwner := aPlayer;
  fPredictor.OwnerUpdate(aPlayer);
  fBuilder.OwnerUpdate(aPlayer);
end;


procedure TKMCityManagement.AfterMissionInit();
begin
  if SP_DEFAULT_ADVANCED_AI then
  begin
    //SetKaMSeed(773852237);
    //gGame.GameOptions.Peacetime := 60;//SP_DEFAULT_PEACETIME;
    fSetup.EnableAdvancedAI(True);
    //fSetup.EnableAdvancedAI(fOwner <= 3);
  end;

  // Find resources around Loc and change building policy
  gAIFields.Eye.ScanLoc();
  fPredictor.AfterMissionInit();
  fBuilder.AfterMissionInit();
end;


procedure TKMCityManagement.UpdateState(aTick: Cardinal);
const
  LONG_UPDATE = MAX_HANDS * 2; // 30 sec
var
  FreeWorkersCnt: Integer;
begin
  if fSetup.AutoBuild AND (aTick mod MAX_HANDS = fOwner) then
  begin
    FreeWorkersCnt := 0;
    fBuilder.UpdateState(aTick, FreeWorkersCnt);
    fPredictor.UpdateState(aTick);
    fBalanceText := '';
    if not SKIP_RENDER AND SHOW_AI_WARE_BALANCE then
      fPredictor.LogStatus(fBalanceText);
    fBuilder.ChooseHousesToBuild(FreeWorkersCnt, aTick);
    if not SKIP_RENDER AND SHOW_AI_WARE_BALANCE then // Builder LogStatus cannot be merged with predictor
    begin
      fBuilder.LogStatus(fBalanceText);
      LogStatus(fBalanceText);
    end;
  end;

  if (aTick mod LONG_UPDATE = fOwner) then
  begin
    CheckUnitCount(aTick);
    CheckMarketplaces();
    CheckStoreWares(aTick);
    if fSetup.AutoRepair then
      CheckAutoRepair();
    CheckWareDistribution();
    WeaponsBalance();
    OrderWeapons();
    CheckExhaustedHouses();
  end;
end;


procedure TKMCityManagement.CheckUnitCount(aTick: Cardinal);
type
  TKMTrainPriorityArr = array[0..13] of TKMUnitType;
  TKMSchoolHouseArray = array of TKMHouseSchool;
  TKMUnitReqArr = array[CITIZEN_MIN..CITIZEN_MAX] of Integer;
var
  P: TKMHand;
  Stats: TKMHandStats;

  function RecruitsNeeded(aCompletedWatchtowers: Word): Integer;
  const
    RECRUIT_PEACE_DELAY = 17 * 60 * 10;
    MIN_2_TICK = 600;
  var
    Output: Integer;
  begin
    Output := aCompletedWatchtowers;

    if (aTick + RECRUIT_PEACE_DELAY > gGame.GameOptions.Peacetime * MIN_2_TICK)
      AND (Stats.GetHouseQty(htBarracks) > 0)
      AND (aTick > fSetup.RecruitDelay * MIN_2_TICK) then
    begin
      if fSetup.UnlimitedEquip then
      begin
        // Iron soldiers
        Inc(  Output, Min( Stats.GetWareBalance(wtMetalArmor), Stats.GetWareBalance(wtArbalet) + Stats.GetWareBalance(wtHallebard) + Min( Stats.GetWareBalance(wtSword), Stats.GetWareBalance(wtMetalShield)) )  );
        // Leather soldiers we can make
        Inc(  Output, Min( Stats.GetWareBalance(wtArmor), Stats.GetWareBalance(wtBow) + Stats.GetWareBalance(wtPike) + Min(Stats.GetWareBalance(wtAxe), Stats.GetWareBalance(wtShield)) )  );
        // Militia with leftover axes
        Inc(  Output, Max( 0, Stats.GetWareBalance(wtAxe) - Min(Stats.GetWareBalance(wtArmor), Stats.GetWareBalance(wtShield)) )  );
      end
      else
        Output := Output + 10;
    end;
    Result := Output;
  end;

  function RequiredServCount(): Integer;
  var
    I,Serfs, Cnt: Integer;
  begin
    Serfs := gHands[fOwner].Stats.GetUnitQty(utSerf);
    Result := Max(0, Round(gHands[fOwner].Stats.GetUnitQty(utWorker) - Serfs));
    Cnt := 0;
    for I := 0 to P.Units.Count - 1 do
      if not P.Units[I].IsDeadOrDying
         AND (P.Units[I] is TKMUnitSerf)
         AND (P.Units[I].IsIdle) then
        Cnt := Cnt + 1;
    // Increase count of serfs carefully (compute fraction of serfs who does not have job)
    if (Cnt < GA_MANAGER_CheckUnitCount_SerfLimit)
       AND (Cnt / (Serfs*1.0) < GA_MANAGER_CheckUnitCount_SerfCoef) then
      Result := Max( 1 + Byte(Serfs < 40) + Byte(Serfs < 60), Result);
  end;

  procedure TrainByPriority(const aPrior: TKMTrainPriorityArr; var aUnitReq: TKMUnitReqArr; var aSchools: TKMSchoolHouseArray; aSchoolCnt: Integer);
  var
    K,L: Integer;
    UT: TKMUnitType;
  begin
    for K := Low(aPrior) to High(aPrior) do
    begin
      UT := aPrior[K];
      for L := 0 to aSchoolCnt - 1 do
        if (aUnitReq[UT] <= 0) then // Check unit requirements
          break
        else if (aSchools[L].QueueCount <= 2) then // Order citizen, decrease unit requirement
          Dec(  aUnitReq[UT], aSchools[L].AddUnitToQueue( UT, Min(aUnitReq[UT], 3-aSchools[L].QueueCount) )  )
    end;
  end;

const
  TRAINING_PRIORITY: TKMTrainPriorityArr = (
    utMiner, utMetallurgist, utStoneCutter, utWoodcutter, utLamberjack,
    utFarmer, utAnimalBreeder, utBaker, utButcher, utFisher, utSmith, utSerf, utWorker, utRecruit
  );
  TRAINING_PRIORITY_Serf: TKMTrainPriorityArr = (
    utMiner, utMetallurgist, utStoneCutter, utWoodcutter, utLamberjack, utSerf,
    utFarmer, utAnimalBreeder, utBaker, utButcher, utFisher, utSmith, utWorker, utRecruit
  );
var
  GoldShortage: Boolean;
  K,L,cnt: Integer;
  GoldProduced: Cardinal;
  H: TKMHouse;
  HT: TKMHouseType;
  UT: TKMUnitType;
  Schools: TKMSchoolHouseArray;
  Houses: array[HOUSE_MIN..HOUSE_MAX] of Integer;
  UnitReq: TKMUnitReqArr;
begin
  P := gHands[fOwner];
  Stats := P.Stats;
  FillChar(UnitReq, SizeOf(UnitReq), #0); //Clear up
  FillChar(Houses, SizeOf(Houses), #0); //Clear up

  //Citizens
  // Make sure we have enough gold left for self-sufficient city
  GoldProduced := Stats.GetWaresProduced(wtGold);
  GoldShortage := (Stats.GetWareBalance(wtGold) < GOLD_SHORTAGE) AND (GoldProduced = 0);
  if GoldShortage then
  begin
    UnitReq[utSerf] := 3; // 3x Serf
    UnitReq[utWorker] := Byte(fPredictor.WorkerCount > 0);// 1x Worker
    UnitReq[utMiner] := Stats.GetHouseTotal(htCoalMine) + Stats.GetHouseTotal(htGoldMine) + Stats.GetHouseQty(htIronMine); // Miner can go into iron / gold / coal mines (idealy we need 1 gold and 1 coal but it is hard to catch it)
    UnitReq[utMetallurgist] := Stats.GetHouseTotal(htMetallurgists) + Stats.GetHouseQty(htIronSmithy); // Metallurgist (same problem like in case of miner)
    UnitReq[utWoodcutter] := Byte(Stats.GetHouseQty(htWoodcutters) > 0); // 1x Woodcutter
    UnitReq[utStoneCutter] := Byte(Stats.GetHouseQty(htQuary) > 0); // 1x StoneCutter
    UnitReq[utLamberjack] := Byte(Stats.GetHouseQty(htSawmill) > 0); // 1x Lamberjack
  end
  //Count overall unit requirement (excluding Barracks and ownerless houses)
  else
  begin
    // We need completed houses, houses in specific stage of construction and only completed watchtowers -> we have to scan houses
    for K := 0 to gHands[fOwner].Houses.Count - 1 do
    begin
      H := gHands[fOwner].Houses[K];
      if (H <> nil) AND not H.IsDestroyed then
      begin
        if H.IsComplete then
          Inc(Houses[H.HouseType], 1)
        else if (H.BuildingProgress > 0) AND (H.HouseType <> htWatchTower) then
          Inc(Houses[H.HouseType], 1);
      end;
    end;

    for HT := HOUSE_MIN to HOUSE_MAX do
      if (gRes.Houses[HT].OwnerType <> utNone) AND (HT <> htBarracks) then
        Inc(UnitReq[gRes.Houses[HT].OwnerType], Houses[HT]);

    UnitReq[utRecruit] := 0;
    UnitReq[utSerf] := 0;
    UnitReq[utWorker] := 0;
    if (Stats.GetWareBalance(wtGold) > GOLD_SHORTAGE * 2.5) OR (GoldProduced > 0) then // Dont train servs / workers / recruits when we will be out of gold
    begin
      UnitReq[utWorker] :=  fPredictor.WorkerCount * Byte(not gHands[fOwner].AI.ArmyManagement.Defence.CityUnderAttack) + Byte(not fSetup.AutoBuild) * Byte(fSetup.AutoRepair) * 5;
      UnitReq[utRecruit] := RecruitsNeeded(Houses[htWatchTower]);
    end;
    if (Stats.GetWareBalance(wtGold) > GOLD_SHORTAGE * 1.5) OR (GoldProduced > 0) then // Dont train servs / workers / recruits when we will be out of gold
      UnitReq[utSerf] := Stats.GetUnitQty(utSerf) + RequiredServCount();
  end;

  // Get required houses
  for UT := Low(UnitReq) to High(UnitReq) do
    Dec(UnitReq[UT], Stats.GetUnitQty(UT));

  // Find completed schools, decrease UnitReq by already trained citizens
  cnt := 0;
  SetLength(Schools, Stats.GetHouseQty(htSchool));
  for K := 0 to P.Houses.Count - 1 do
    if (P.Houses[K] <> nil)
       AND not (P.Houses[K].IsDestroyed)
       AND (P.Houses[K].IsComplete)
       AND (P.Houses[K].HouseType = htSchool) then
    begin
      Schools[cnt] := TKMHouseSchool(P.Houses[K]);
      if GoldShortage AND (Schools[cnt].CheckResIn(wtGold) = 0) then // Ignore empty schools when we are out of gold
        continue;
      for L := Schools[cnt].QueueLength - 1 downto 0 do
        if (Schools[cnt].Queue[L] <> utNone) then
        begin
          if L = 0 then // Queue is already active
            Dec(UnitReq[ Schools[Cnt].Queue[L] ],1)
          else // Remove from Queue (it doesn't have to be actual ... when is city under attack we have to save gold)
            Schools[Cnt].RemUnitFromQueue(L);
        end;
      cnt := cnt + 1;
    end;

  //Order citizen training
  if (gHands[fOwner].Stats.GetUnitQty(utSerf) < gHands[fOwner].Stats.GetHouseQty(htAny)) then // Keep minimal amount of serfs
    TrainByPriority(TRAINING_PRIORITY_Serf, UnitReq, Schools, cnt)
  else
    TrainByPriority(TRAINING_PRIORITY, UnitReq, Schools, cnt);

end;


// Try trade
procedure TKMCityManagement.CheckMarketplaces();
var
  RequiedCnt, AvailableCnt: Word;
  RequiredWares, AvailableWares: array of TKMWareType;
  procedure AddWare(aWare: TKMWareType; IsRequired: Boolean = True);
  begin
    if IsRequired then
    begin
      RequiredWares[RequiedCnt] := aWare;
      RequiedCnt := RequiedCnt + 1;
    end
    else
    begin
      AvailableWares[AvailableCnt] := aWare;
      AvailableCnt := AvailableCnt + 1;
    end;
  end;

  procedure TryBuyItem(aResFrom, aResTo: TKMWareType);
  const
    TRADE_RESERVE = 5;
    TRADE_QUANTITY = 20;
  var
    I: Integer;
    Houses: TKMHousesCollection;
    HM, IdleHM: TKMHouseMarket;
  begin
    Houses := gHands[fOwner].Houses;
    IdleHM := nil;
    for I := 0 to Houses.Count - 1 do
      if (Houses[I] <> nil)
        AND not Houses[I].IsDestroyed
        AND (Houses[I].HouseType = htMarketplace)
        AND Houses[I].IsComplete then
      begin
        HM := TKMHouseMarket(Houses[I]);
        if (TKMHouseMarket(HM).ResOrder[0] <> 0) then
        begin
          if (HM.ResTo = aResTo) then
            Exit;
          if (gHands[fOwner].Stats.GetWareBalance(aResFrom) > TKMHouseMarket(HM).ResOrder[0]) then
            continue;
        end;
        if HM.AllowedToTrade(aResFrom) AND HM.AllowedToTrade(aResTo) then
        begin
          IdleHM := HM;
          break;
        end;
      end;
    if (IdleHM <> nil) then  // AND (IdleHM.ResFrom <> aResFrom) or (IdleHM.ResTo <> aResTo) then
    begin
      IdleHM.ResOrder[0] := 0; //First we must cancel the current trade
      IdleHM.ResFrom := aResFrom;
      IdleHM.ResTo := aResTo;
      IdleHM.ResOrder[0] := TRADE_QUANTITY; //Set the new trade
    end;
  end;
const
  SOLD_ORDER: array[0..21] of TKMWareType = (
    wtSausages,     wtWine,     wtFish,       wtBread,
    wtSkin,         wtLeather,  wtPig,
    wtTrunk,        wtWood,
    wtShield,       wtAxe,      wtPike,       wtBow,      wtArmor,
    wtMetalShield,  wtSword,    wtHallebard,  wtArbalet,  wtMetalArmor,
    wtHorse,        wtCorn,     wtFlour
    //wtSteel,        wtGold,     wtIronOre,    wtCoal,     wtGoldOre,
    //wtStone
  );
  MIN_GOLD_AMOUNT = GOLD_SHORTAGE * 3;
  LACK_OF_STONE = 50;
  WARFARE_SELL_LIMIT = 20;
  SELL_LIMIT = 30;
var
  MarketCnt, I, WareCnt: Word;
begin

  MarketCnt := gHands[fOwner].Stats.GetHouseQty(htMarketplace);
  if MarketCnt = 0 then
    Exit;

  RequiedCnt := 0;
  SetLength(RequiredWares,4);
  with gHands[fOwner].Stats do
  begin
    // Gold
    if (GetHouseQty(htMetallurgists) = 0)
       AND (GetWareBalance(wtGold) <= GOLD_SHORTAGE) then
       AddWare(wtGold);
    // Stone
    if (GetWareBalance(wtStone)-GetHouseQty(htWatchTower)*5 < LACK_OF_STONE)
      AND (Builder.Planner.PlannedHouses[htQuary].Completed = 0) then
      AddWare(wtStone);
    // Gold ore
    if ( fPredictor.WareBalance[wtGoldOre].Exhaustion < 20 )
      AND ( GetWareBalance(wtGold) < MIN_GOLD_AMOUNT )
      AND ( GetWareBalance(wtGoldOre) < MIN_GOLD_AMOUNT ) then
      AddWare(wtGoldOre);
    // Coal
    if ( fPredictor.WareBalance[wtCoal].Exhaustion < 50 )
      AND ( GetWareBalance(wtCoal) < MIN_GOLD_AMOUNT )
      AND (Builder.Planner.PlannedHouses[htCoalMine].UnderConstruction = 0) then
      AddWare(wtCoal);
  end;

  if RequiedCnt = 0 then
    Exit;

  AvailableCnt := 0;
  SetLength(AvailableWares, RequiedCnt);
  for I := 0 to Length(SOLD_ORDER) - 1 do
    if (AvailableCnt < RequiedCnt) then
    begin
      WareCnt := gHands[fOwner].Stats.GetWareBalance( SOLD_ORDER[I] );
      if (  (SOLD_ORDER[I] in [WARFARE_MIN..WARFARE_MAX]) AND (WareCnt > WARFARE_SELL_LIMIT)  )
         OR (  (WareCnt > SELL_LIMIT) AND (fPredictor.WareBalance[ SOLD_ORDER[I] ].Exhaustion > 90)  ) then
        AddWare(SOLD_ORDER[I], False);
    end;

  for I := 0 to RequiedCnt - 1 do
    if (I < AvailableCnt) then
      TryBuyItem(AvailableWares[I], RequiredWares[I])
  else
    break;
end;


procedure TKMCityManagement.CheckStoreWares(aTick: Cardinal);
const
  TRUNK_STORE_DELAY = 45 * 60 * 10;
  WOOD_STORE_DELAY = 60 * 60 * 10;
  STONE_STORE_DELAY = 60 * 60 * 10;
  CORN_STORE_DELAY = 60 * 60 * 10;
var
  I: Integer;
  S: TKMHouseStore;
begin
  //Iterate through all Stores and block certain wares to reduce serf usage
  for I := 0 to gHands[fOwner].Houses.Count - 1 do
    with gHands[fOwner] do
      if (Houses[I] <> nil)
        AND not Houses[I].IsDestroyed
        AND (Houses[I].HouseType = htStore)
        AND Houses[I].IsComplete then
      begin
        S := TKMHouseStore(Houses[I]);

        // Materials
        S.NotAcceptFlag[wtTrunk] := (aTick > TRUNK_STORE_DELAY); // Trunk should not be blocked because of forest cleaning
        S.NotAcceptFlag[wtWood] := (S.CheckResIn(wtWood) > 20) OR (aTick > WOOD_STORE_DELAY);// AND (Predictor.WareBalance[wtWood].Exhaustion > 40);
        S.NotAcceptFlag[wtStone] := (aTick > STONE_STORE_DELAY) OR (S.CheckResIn(wtStone)*2 > Stats.GetUnitQty(utWorker));
        S.NotAcceptFlag[wtGold] := S.CheckResIn(wtGold) > 400; // Everyone needs as much gold as possible

        // Food - don't store food when we have enought (it will cause trafic before storehouse)
        S.NotAcceptFlag[wtWine] := Stats.GetWareBalance(wtWine) > 100;
        S.NotAcceptFlag[wtSausages] := Stats.GetWareBalance(wtSausages) > 100;
        S.NotAcceptFlag[wtBread] := Stats.GetWareBalance(wtBread) > 100;
        S.NotAcceptFlag[wtFish] := Stats.GetWareBalance(wtFish) > 100;

        // Others
        S.NotAcceptFlag[wtGoldOre] := True;
        S.NotAcceptFlag[wtCoal] := True;
        S.NotAcceptFlag[wtIronOre] := Stats.GetHouseQty(htIronSmithy) > 0;
        S.NotAcceptFlag[wtSteel] := Stats.GetHouseQty(htWeaponSmithy) +
                                     Stats.GetHouseQty(htArmorSmithy) > 0;
        S.NotAcceptFlag[wtCorn] := (aTick > CORN_STORE_DELAY);
        S.NotAcceptFlag[wtLeather] := True;
        S.NotAcceptFlag[wtFlour] := True;
        //Pigs and skin cannot be blocked since if swinefarm is full of one it stops working (blocks other)
        //S.NotAcceptFlag[wtSkin] := Stats.GetHouseQty(htTannery) > 0;
        //S.NotAcceptFlag[wtPig] := Stats.GetHouseQty(htButchers) > 0;
      end;
end;


//Demolish any exhausted mines, they will be rebuilt if needed
procedure TKMCityManagement.CheckExhaustedHouses();
var
  I: Integer;
  Loc: TKMPoint;
  H: TKMHouse;
begin
  //Wait until resource is depleted and output is empty
  for I := 0 to gHands[fOwner].Houses.Count - 1 do
  begin
    H := gHands[fOwner].Houses[I];
    if not H.IsDestroyed
      AND H.ResourceDepletedMsgIssued
      AND (H.CheckResOut(wtAll) = 0) then
    begin
      Loc := H.Entrance;
      // Remove avoid building around coal mine
      if (H.HouseType = htCoalMine) then
        gAIFields.Influences.RemAvoidBuilding(KMRect(Loc.X-3, Loc.Y-3, Loc.X+4, Loc.Y+2));
      // Mark house plan as exhausted
      Builder.Planner.MarkAsExhausted(H.HouseType, Loc);
      H.DemolishHouse(fOwner);
    end;
  end;
end;


// Allow auto repair procedure
procedure TKMCityManagement.CheckAutoRepair();
var
  I: Integer;
begin
  if (gHands[fOwner].HandType <> hndComputer) then
    Exit;
  with gHands[fOwner] do
    if gHands[fOwner].AI.ArmyManagement.Defence.CityUnderAttack then
    begin
      for I := 0 to Houses.Count - 1 do
      begin
        Houses[I].BuildingRepair := false;
        if (Houses[I].HouseType = htWatchTower) AND (Houses[I].DeliveryMode = dmDelivery) then
          Houses[I].SetDeliveryModeInstantly(dmClosed);
      end;
    end
    else
    begin
      for I := 0 to Houses.Count - 1 do
      begin
        Houses[I].BuildingRepair := fSetup.AutoRepair;
        if (Houses[I].HouseType = htWatchTower) AND (Houses[I].DeliveryMode = dmClosed) then
          Houses[I].SetDeliveryModeInstantly(dmDelivery);
      end;
    end;
end;


procedure TKMCityManagement.CheckWareDistribution();
  // Serfs are too ill to bring coal to metallurgists if AI place it 1 tile farther than iron production so there has to be created this function
  function GetGoldBalance(): Boolean;
  const
    MAX_DEFICIT = 2;
  var
    I, Deficit, HouseCnt: Integer;
    H: TKMHouse;
  begin
    HouseCnt := 0;
    Deficit := 0;
    with Builder.Planner.PlannedHouses[htMetallurgists] do
      for I := 0 to Count - 1 do
        if (Plans[I].House <> nil) AND not (Plans[I].House.IsDestroyed) then
        begin
          Inc(HouseCnt);
          H := Plans[I].House;
          Inc(Deficit, H.CheckResIn(wtGoldOre) + H.CheckResOut(wtGoldOre) - H.CheckResIn(wtCoal) - H.CheckResOut(wtCoal));
        end;
    Result := (Deficit / HouseCnt) > MAX_DEFICIT;
  end;
begin
  with gHands[fOwner].Stats do
  begin
    // Wood
    if Builder.WoodShortage OR Builder.TrunkShortage then
    begin
      WareDistribution[wtWood, htArmorWorkshop] := 0;
      WareDistribution[wtWood, htWeaponWorkshop] := 2;
    end
    else
    begin
      WareDistribution[wtWood, htArmorWorkshop] := 2;
      WareDistribution[wtWood, htWeaponWorkshop] := 5;
    end;
    // Coal
    if Builder.GoldShortage then
    begin
      gHands[fOwner].Stats.WareDistribution[wtCoal, htMetallurgists] := 5;
      gHands[fOwner].Stats.WareDistribution[wtCoal, htIronSmithy] := 1;
      gHands[fOwner].Stats.WareDistribution[wtCoal, htWeaponSmithy] := 0;
      gHands[fOwner].Stats.WareDistribution[wtCoal, htArmorSmithy] := 0;
    end
    else if GetGoldBalance() then
    begin
      gHands[fOwner].Stats.WareDistribution[wtCoal, htMetallurgists] := 5;
      gHands[fOwner].Stats.WareDistribution[wtCoal, htIronSmithy] := 2;
      gHands[fOwner].Stats.WareDistribution[wtCoal, htWeaponSmithy] := 1;
      gHands[fOwner].Stats.WareDistribution[wtCoal, htArmorSmithy] := 1;
    end
    else
    begin
      gHands[fOwner].Stats.WareDistribution[wtCoal, htMetallurgists] := 5;
      gHands[fOwner].Stats.WareDistribution[wtCoal, htIronSmithy] := 4;
      gHands[fOwner].Stats.WareDistribution[wtCoal, htWeaponSmithy] := 4;
      gHands[fOwner].Stats.WareDistribution[wtCoal, htArmorSmithy] := 4;
    end;
    // Corn
    if (gHands[fOwner].Stats.GetWareBalance(wtBread) > 20) then
    begin
      gHands[fOwner].Stats.WareDistribution[wtCorn, htMill] := 2;
      gHands[fOwner].Stats.WareDistribution[wtCorn, htSwine] := 5;
      gHands[fOwner].Stats.WareDistribution[wtCorn, htStables] := 4;
    end
    else
    begin
      gHands[fOwner].Stats.WareDistribution[wtCorn, htMill] := 4;
      gHands[fOwner].Stats.WareDistribution[wtCorn, htSwine] := 5;
      gHands[fOwner].Stats.WareDistribution[wtCorn, htStables] := 3;
    end;
    // Steel is updated in WeaponsBalance
    //gHands[fOwner].Stats.WareDistribution[wtSteel, htWeaponSmithy] := 5;
    //gHands[fOwner].Stats.WareDistribution[wtSteel, htArmorSmithy] := 5;

    gHands[fOwner].Houses.UpdateResRequest;
  end;
end;


// Calculate weapons demand from combat AI requirements
procedure TKMCityManagement.WeaponsBalance();
var
  EnemyEval, AllyEval: TKMArmyEval;

  procedure ComputeGroupDemands(aGT: TKMGroupType; aIronRatio: Single);
  const
    // It doesnt depends on future "optimalization" of parameters: against cav should be always good pikes etc. so this array doesnt have to be computed
    BEST_VERSUS_OPTION: array[TKMGroupType] of TKMGroupType = (gtMelee, gtMelee, gtRanged, gtAntiHorse);
  var
    Wood, Iron: Boolean;
    I: Integer;
    EnemyStrength, UnitStrength, UnitsRequired: Single;
    UT: TKMUnitType;
    antiGT: TKMGroupType;
    UnitEval: TKMGroupEval;
  begin
    // Get best type of oponent and compute iron ratio
    antiGT := BEST_VERSUS_OPTION[aGT];
    Wood := False;
    Iron := False;
    for I := 1 to 3 do
    begin
      UT := AITroopTrainOrder[antiGT,I];
      if (UT <> utNone) AND not gHands[fOwner].Locks.GetUnitBlocked(UT) then
        if (I = 1) then
          Iron := True
        else
          Wood := True;
    end;
    if Wood AND not Iron then
      aIronRatio := 0
    else if not Wood AND Iron then
      aIronRatio := 1
    else if not Wood AND not Iron then
      Exit;

    // Compute strength of specific enemy group
    with EnemyEval.Groups[aGT] do
      EnemyStrength := (Attack + AttackHorse * Byte(antiGT = gtMounted))
                        * ifthen( (antiGT = gtRanged), DefenceProjectiles, Defence )
                        * HitPoints;

    // Decrease strength by owner's existing units
    with AllyEval.Groups[antiGT] do
      EnemyStrength := Max(0, EnemyStrength - (Attack + AttackHorse * Byte(aGT = gtMounted))
                                               * ifthen( (aGT = gtRanged), DefenceProjectiles, Defence )
                                               * HitPoints);

    // Compute unit requirements
    for I := 1 to 3 do
    begin
      UT := AITroopTrainOrder[antiGT,I];
      // Skip unit type in case that it is blocked
      if (UT = utNone) OR gHands[fOwner].Locks.GetUnitBlocked(UT) then
        continue;
      // Calculate required count of specific unit type
      UnitEval := gAIFields.Eye.ArmyEvaluation.UnitEvaluation[UT, True];
      with UnitEval do
        UnitStrength := Max(0, Attack + AttackHorse * Byte(aGT = gtMounted)
                               * ifthen( (aGT = gtRanged), DefenceProjectiles, Defence )
                               * HitPoints);

      UnitsRequired := Power(EnemyStrength / UnitStrength, 1/3) * ifthen( (I = 1), aIronRatio, 1-aIronRatio );
      fWarriorsDemands[UT] := fWarriorsDemands[UT] + Max(0, Round(UnitsRequired)   );
      if (I = 2) then // In case that utAxeFighter is not blocked skip militia
        break;
    end;
  end;

  procedure CheckMinArmyReq();
  const
    DEFAULT_COEFICIENT = 15;
    DEFAULT_ARMY_REQUIREMENTS: array[WARRIOR_EQUIPABLE_MIN..WARRIOR_EQUIPABLE_MAX] of Single = (
      1, 1, 1, 3,//utMilitia,      utAxeFighter,   utSwordsman,     utBowman,
      3, 1, 1, 0.5,//utArbaletman,   utPikeman,      utHallebardman,  utHorseScout,
      0.5//utCavalry
    );
    WOOD_ARMY: set of TKMUnitType = [utAxeFighter, utBowman, utPikeman]; //utHorseScout,
    IRON_ARMY: set of TKMUnitType = [utSwordsman, utArbaletman, utHallebardman]; //utCavalry
  var
    I, WoodReq, IronReq: Integer;
    UT: TKMUnitType;
  begin
    WoodReq := Max(+ fRequiredWeapons[wtArmor].Required - fRequiredWeapons[wtArmor].Available,
                   + fRequiredWeapons[wtAxe].Required - fRequiredWeapons[wtAxe].Available
                   + fRequiredWeapons[wtBow].Required - fRequiredWeapons[wtBow].Available
                   + fRequiredWeapons[wtPike].Required - fRequiredWeapons[wtPike].Available
                  );
    if (WoodReq < 5) then
    begin
      WoodReq := Round((DEFAULT_COEFICIENT - WoodReq) / 5.0); // 5 is equal to sum of all requirements in leather category
      for UT in WOOD_ARMY do
        if not gHands[fOwner].Locks.GetUnitBlocked(UT) then
          for I := Low(TROOP_COST[UT]) to High(TROOP_COST[UT]) do
            if (TROOP_COST[UT,I] <> wtNone) then
              with fRequiredWeapons[ TROOP_COST[UT,I] ] do
                Required := Required + Round(DEFAULT_ARMY_REQUIREMENTS[UT] * WoodReq);
    end;

    IronReq := Max(+ fRequiredWeapons[wtMetalArmor].Required - fRequiredWeapons[wtMetalArmor].Available,
                   + fRequiredWeapons[wtSword].Required - fRequiredWeapons[wtSword].Available
                   + fRequiredWeapons[wtArbalet].Required - fRequiredWeapons[wtArbalet].Available
                   + fRequiredWeapons[wtHallebard].Required - fRequiredWeapons[wtHallebard].Available
                  );
    if (IronReq < 5) then
    begin
      IronReq := Round((DEFAULT_COEFICIENT - IronReq) / 5.0); // 5 is equal to sum of all requirements in iron category
      for UT in IRON_ARMY do
        if not gHands[fOwner].Locks.GetUnitBlocked(UT) then
          for I := Low(TROOP_COST[UT]) to High(TROOP_COST[UT]) do
            if (TROOP_COST[UT,I] <> wtNone) then
              with fRequiredWeapons[ TROOP_COST[UT,I] ] do
                Required := Required + Round(DEFAULT_ARMY_REQUIREMENTS[UT] * IronReq);
    end;
  end;
//AITroopTrainOrder: array [TKMGroupType, 1..3] of TKMUnitType = (
//  (utSwordsman,    utAxeFighter, utMilitia),
//  (utHallebardman, utPikeman,    utNone),
//  (utArbaletman,   utBowman,     utNone),
//  (utCavalry,      utHorseScout, utNone)
//);
//UnitGroups: array [WARRIOR_MIN..WARRIOR_MAX] of TKMGroupType = (
//  gtMelee,gtMelee,gtMelee, //utMilitia, utAxeFighter, utSwordsman
//  gtRanged,gtRanged,        //utBowman, utArbaletman
//  gtAntiHorse,gtAntiHorse,  //utPikeman, utHallebardman,
//  gtMounted,gtMounted,      //utHorseScout, utCavalry,
//  gtMelee,                   //utBarbarian
//  //TPR Army
//  gtAntiHorse,        //utPeasant
//  gtRanged,           //utSlingshot
//  gtMelee,            //utMetalBarbarian
//  gtMounted           //utHorseman
//);
//TroopCost: array [utMilitia..utCavalry, 1..4] of TKMWareType = (
//  (wtAxe,          wtNone,        wtNone,  wtNone ), //Militia
//  (wtShield,       wtArmor,       wtAxe,   wtNone ), //Axefighter
//  (wtMetalShield,  wtMetalArmor,  wtSword, wtNone ), //Swordfighter
//  (wtArmor,        wtBow,         wtNone,  wtNone ), //Bowman
//  (wtMetalArmor,   wtArbalet,     wtNone,  wtNone ), //Crossbowman
//  (wtArmor,        wtPike,        wtNone,  wtNone ), //Lance Carrier
//  (wtMetalArmor,   wtHallebard,   wtNone,  wtNone ), //Pikeman
//  (wtShield,       wtArmor,       wtAxe,   wtHorse), //Scout
//  (wtMetalShield,  wtMetalArmor,  wtSword, wtHorse)  //Knight
//);
//WARRIOR_EQUIPABLE_MIN = utMilitia;
//WARRIOR_EQUIPABLE_MAX = utCavalry;
//  utMilitia,      utAxeFighter,   utSwordsman,     utBowman,
//  utArbaletman,   utPikeman,      utHallebardman,  utHorseScout,
//  utCavalry,      utBarbarian,

const
  IRON_WEAPONS: set of TKMWareType = [wtSword, wtHallebard, wtArbalet];
  IRON_ARMORS: set of TKMWareType = [wtMetalArmor, wtMetalShield];
var
  I, SmithyCnt, WorkshopCnt, ArmorCnt: Integer;
  IronRatio, WeaponFraction, ArmorFraction, IronShare: Single;
  WT: TKMWareType;
  GT: TKMGroupType;
  UT: TKMUnitType;
begin
  ArmorCnt := gHands[fOwner].Stats.GetHouseQty(htArmorSmithy) + gHands[fOwner].Stats.GetHouseQty(htArmorWorkshop);
  SmithyCnt := gHands[fOwner].Stats.GetHouseQty(htWeaponSmithy);
  WorkshopCnt := gHands[fOwner].Stats.GetHouseQty(htWeaponWorkshop);
  if (ArmorCnt + SmithyCnt + WorkshopCnt = 0) then // Save time when nothing can be produced
    Exit;
  IronRatio := 0.5;
  if (SmithyCnt + WorkshopCnt > 0) then // This will avoid to divide by zero
    IronRatio := SmithyCnt / ((SmithyCnt + WorkshopCnt)*1.0);

  // Humans may spam archers -> AI will not produce long-range support because of balancing units in team
  // So it is better to calculate AllyEval just for Owner
  //AllyEval := gAIFields.Eye.ArmyEvaluation.GetAllianceStrength(aPlayer, atAlly);
  AllyEval := gAIFields.Eye.ArmyEvaluation.Evaluation[fOwner];
  EnemyEval := gAIFields.Eye.ArmyEvaluation.AllianceEvaluation[fOwner, atEnemy];

  // Compute requirements of warriors
  for UT := Low(fWarriorsDemands) to High(fWarriorsDemands) do
    fWarriorsDemands[UT] := 0;
  for GT := Low(TKMGroupType) to High(TKMGroupType) do
    ComputeGroupDemands(GT, IronRatio);

  // Get weapons reserves
  for WT := Low(fRequiredWeapons) to High(fRequiredWeapons) do
  begin
    fRequiredWeapons[WT].Available := gHands[fOwner].Stats.GetWareBalance(WT);
    fRequiredWeapons[WT].Required := 0;
  end;

  // Get count of needed weapons
  for UT := utAxeFighter to WARRIOR_EQUIPABLE_MAX do // Skip militia
    for I := Low(TROOP_COST[UT]) to High(TROOP_COST[UT]) do
      if (TROOP_COST[UT,I] <> wtNone) then
      begin
        WT := TROOP_COST[UT,I];
        fRequiredWeapons[WT].Required := fRequiredWeapons[WT].Required + fWarriorsDemands[UT];
      end
      else
        break;

  // Make sure that we always produce something
  CheckMinArmyReq();

  // Calculate fraction of demands
  for WT := Low(fRequiredWeapons) to High(fRequiredWeapons) do
    with fRequiredWeapons[WT] do
      Fraction := Available / Max(1,Required);

  // Calculate mean fraction of iron weapons and distribute steal
  WeaponFraction := 0;
  for WT in IRON_WEAPONS do
    WeaponFraction := WeaponFraction + fRequiredWeapons[WT].Fraction;
  WeaponFraction := WeaponFraction / 3.0;
  if (fRequiredWeapons[wtMetalArmor].Fraction > fRequiredWeapons[wtMetalShield].Fraction) then
  begin
    ArmorFraction := 0;
    for WT in IRON_ARMORS do
      ArmorFraction := ArmorFraction + fRequiredWeapons[WT].Fraction;
    ArmorFraction := ArmorFraction / 2.0;
  end
  else
    ArmorFraction := fRequiredWeapons[wtMetalArmor].Fraction; // Consider only metal armor in case that we have enought metal shields
  // We always want the higher requirements equal to 5 + something between 1 <-> 5 for second production
  IronShare := 5 * (WeaponFraction + ArmorFraction) / Max(WeaponFraction, ArmorFraction);
  // Ware distribution = fraction / sum of fractions * 5
  gHands[fOwner].Stats.WareDistribution[wtSteel, htWeaponSmithy] := Max(  1, Min(5, Round( ArmorFraction / (WeaponFraction + ArmorFraction) * IronShare) )  );
  gHands[fOwner].Stats.WareDistribution[wtSteel, htArmorSmithy] := Max(  1, Min(5, Round( WeaponFraction / (WeaponFraction + ArmorFraction) * IronShare) )  );
  gHands[fOwner].Houses.UpdateResRequest;
end;


// Distribute required weapons into exist houses (first will be produced the larger amount of wares)
procedure TKMCityManagement.OrderWeapons();
const
  WEAPONS_PER_A_UPDATE = 3;
  PRODUCTION_HOUSES = [htArmorSmithy, htArmorWorkshop, htWeaponSmithy, htWeaponWorkshop];
var
  I, K, MaxIdx, HouseCnt: Integer;
  MostRequired: Single;
  HT: TKMHouseType;
  WT, MaxWT: TKMWareType;
  H: TKMHouse;
begin
  MaxIdx := 0; // For compiler
  for HT in PRODUCTION_HOUSES do
  begin
    // Check house cnt
    HouseCnt := gHands[fOwner].Stats.GetHouseQty(HT);
    if (HouseCnt = 0) then
      continue;
    // Find produced ware which is the most required
    MostRequired := 1.0;
    MaxWT := wtNone;
    for I := 1 to 4 do
    begin
      WT := gRes.Houses[HT].ResOutput[I];
      if (WT <> wtNone) AND (fRequiredWeapons[WT].Fraction < MostRequired) then
      begin
        MostRequired := fRequiredWeapons[WT].Fraction;
        MaxWT := WT;
        MaxIdx := I;
      end;
    end;
    // Set order
    if (MaxWT <> wtNone) then
      for I := 0 to gHands[fOwner].Houses.Count - 1 do
        if not gHands[fOwner].Houses[I].IsDestroyed then
        begin
          H := gHands[fOwner].Houses[I];
          if (H.HouseType <> HT) then
            continue;
          for K := 1 to 4 do
            H.ResOrder[K] := 0;
          H.ResOrder[MaxIdx] := WEAPONS_PER_A_UPDATE; // With update each 1-2 minutes there is not need to calculate something more
          if (HT = htArmorWorkshop) then
          begin
            for K := 1 to 4 do
            begin
              WT := gRes.Houses[HT].ResOutput[K];
              if (WT = wtArmor) then
              begin
                H.ResOrder[K] := 10;
                break;
              end;
            end;
          end;
        end;
  end;
end;


procedure TKMCityManagement.LogStatus(var aBalanceText: UnicodeString);
const
  COLOR_WHITE = '[$FFFFFF]';
  COLOR_RED = '[$0000FF]';
  COLOR_YELLOW = '[$00FFFF]';
  COLOR_GREEN = '[$00FF00]';
  WARFARE: array[WARFARE_MIN..WARFARE_MAX] of UnicodeString =
    ('Shield     ', 'MetalShield', 'Armor      ', 'MetalArmor', 'Axe         ', 'Sword      ',
     'Pike       ', 'Hallebard  ', 'Bow        ', 'Arbalet   ', 'Horse      ');
var
  WT: TKMWareType;
begin
  aBalanceText := aBalanceText + '||Weapons orders (weapon: Available, required, fraction)|';
  for WT := Low(fRequiredWeapons) to High(fRequiredWeapons) do
    with fRequiredWeapons[WT] do
      aBalanceText := aBalanceText + WARFARE[WT] + #9 + '('
                      + Format(
                         COLOR_GREEN+'%D'+COLOR_WHITE+';' + #9
                        +COLOR_RED+'%D'+COLOR_WHITE+';' + #9
                        +COLOR_YELLOW+'%.2f'+COLOR_WHITE+')|', [Available, Required, Fraction]
                      );
end;

end.

