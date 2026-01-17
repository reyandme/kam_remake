{
Artificial intelligence
@author: Martin Toupal
@e-mail: poznamenany@gmail.com
}
unit KM_CityManagement;
{$I KaM_Remake.inc}
interface
uses
  Math, SysUtils, KM_Defaults, KM_CommonClasses, KM_Points,
  KM_AISetup, KM_ResHouses, KM_ResUnits, KM_ResTypes, KM_HandStats, KM_HouseCollection,
  KM_CityPredictor, KM_CityBuilder, KM_CityPlanner, KM_AIArmyEvaluation, KM_AIParameters;

type
  TKMWarfareArr = array[WARFARE_MIN..WARFARE_MAX] of record
    Available, Required: Integer;
    Fraction: Single;
  end;
  TKMWarriorsDemands = array[WARRIOR_EQUIPABLE_BARRACKS_MIN..WARRIOR_EQUIPABLE_BARRACKS_MAX] of Integer;

  TKMCityManagement = class
  private
    fOwner: TKMHandID;
    fUnitReqCnt: Word;
    fSetup: TKMHandAISetup;

    fBuilder: TKMCityBuilder;
    fPredictor: TKMCityPredictor;

    fRequiredWeapons: TKMWarfareArr;
    fWarriorsDemands: TKMWarriorsDemands;

    fBalanceText{, fUnitText}: UnicodeString;

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

    property RequiredUnitsCnt: Word read fUnitReqCnt;
    property Builder: TKMCityBuilder read fBuilder write fBuilder;
    property Predictor: TKMCityPredictor read fPredictor;
    property WarriorsDemands: TKMWarriorsDemands read fWarriorsDemands;
    property BalanceText: UnicodeString read fBalanceText;

    procedure UpdateState(aTick: Cardinal);
    procedure LogStatus(var aBalanceText: UnicodeString);

  end;


implementation
uses
  Classes, KM_Game, KM_Houses, KM_HouseSchool, KM_HandsCollection, KM_Hand, KM_Resource, KM_HouseStore,
  KM_AIFields, KM_Units, KM_UnitsCollection, KM_HouseMarket, KM_DevPerfLog, KM_DevPerfLogTypes,
  KM_HandTypes;


{ TKMCityManagement }
constructor TKMCityManagement.Create(aPlayer: TKMHandID; aSetup: TKMHandAISetup);
begin
  inherited Create;

  fOwner := aPlayer;
  fUnitReqCnt := 0;
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
  SaveStream.PlaceMarker('CityManagement');
  SaveStream.Write(fOwner);
  SaveStream.Write(fUnitReqCnt);
  SaveStream.Write(fWarriorsDemands, SizeOf(fWarriorsDemands)); // Used for Army management -> must be saved
  //SaveStream.Write(fRequiredWeapons, SizeOf(fRequiredWeapons)); // Computed every time

  fPredictor.Save(SaveStream);
  fBuilder.Save(SaveStream);
end;


procedure TKMCityManagement.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.CheckMarker('CityManagement');
  LoadStream.Read(fOwner);
  LoadStream.Read(fUnitReqCnt);
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
    fSetup.EnableAdvancedAI(True);
  end;

  // Find resources around Loc and change building policy
  gAIFields.Eye.ScanLoc();
  fPredictor.AfterMissionInit();
  fBuilder.AfterMissionInit();
end;


procedure TKMCityManagement.UpdateState(aTick: Cardinal);
const
  LONG_UPDATE = MAX_HANDS * 2;
begin
  {$IFDEF DBG_PERFLOG}
  gPerfLogs.SectionEnter(psAICityAdv);
  {$ENDIF}
  try
    if fSetup.AutoBuild AND (aTick mod MAX_HANDS = fOwner) then
    begin
      fBuilder.UpdateState(aTick);
      fPredictor.UpdateState(aTick);
      if not SKIP_RENDER AND SHOW_AI_WARE_BALANCE then
      begin
        fBalanceText := '';
        fPredictor.LogStatus(fBalanceText);
        fBalanceText := fBalanceText + Format('Management, unit count: %d',[fUnitReqCnt]);
      end;
      fBuilder.ChooseHousesToBuild(aTick);
      if not SKIP_RENDER AND SHOW_AI_WARE_BALANCE then
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
      if fSetup.IsRepairAlways then
        CheckAutoRepair();
      CheckWareDistribution();
      WeaponsBalance();
      OrderWeapons();
      CheckExhaustedHouses();
    end;
  finally
    {$IFDEF DBG_PERFLOG}
    gPerfLogs.SectionLeave(psAICityAdv);
    {$ENDIF}
  end;
end;


procedure TKMCityManagement.CheckUnitCount(aTick: Cardinal);
type
  TKMTrainPriorityArr = array[0..13] of TKMUnitType;
  TKMSchoolHouseArray = array of TKMHouseSchool;
  TKMHouseAvailArr = array[HOUSE_MIN..HOUSE_MAX] of Integer;
  TKMUnitReqArr = array[CITIZEN_MIN..CITIZEN_MAX] of Integer;
const
  TRAINING_PRIORITY: TKMTrainPriorityArr = (
    utMiner, utMetallurgist, utStonemason, utWoodcutter, utCarpenter,
    utFarmer, utAnimalBreeder, utBaker, utButcher, utFisher, utSmith, utSerf, utBuilder, utRecruit
  );
  TRAINING_PRIORITY_Serf: TKMTrainPriorityArr = (
    utMiner, utMetallurgist, utStonemason, utWoodcutter, utCarpenter, utSerf,
    utFarmer, utAnimalBreeder, utBaker, utButcher, utFisher, utSmith, utBuilder, utRecruit
  );
  DISMISS_UNITS: set of TKMUnitType = [
    utMiner, utMetallurgist, utStonemason, utWoodcutter, utCarpenter, //utSerf,
    utFarmer, utAnimalBreeder, utBaker, utButcher, utFisher, utSmith, utBuilder // utRecruit
  ];
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

    if (aTick + RECRUIT_PEACE_DELAY > gGame.Options.Peacetime * MIN_2_TICK)
      AND (Stats.GetHouseQty(htBarracks) > 0)
      AND (aTick > fSetup.RecruitDelay * MIN_2_TICK) then
    begin
      if fSetup.UnlimitedEquip then
      begin
        // Iron soldiers
        Inc(  Output, Min( Stats.GetWareBalance(wtIronArmor), Stats.GetWareBalance(wtCrossbow) + Stats.GetWareBalance(wtPike) + Min( Stats.GetWareBalance(wtSword), Stats.GetWareBalance(wtIronShield)) )  );
        // Leather soldiers we can make
        Inc(  Output, Min( Stats.GetWareBalance(wtLeatherArmor), Stats.GetWareBalance(wtBow) + Stats.GetWareBalance(wtLance) + Min(Stats.GetWareBalance(wtAxe), Stats.GetWareBalance(wtWoodenShield)) )  );
        // Militia with leftover axes
        Inc(  Output, Max( 0, Stats.GetWareBalance(wtAxe) - Min(Stats.GetWareBalance(wtLeatherArmor), Stats.GetWareBalance(wtWoodenShield)) )  );
      end
      else
        Output := Output + 10;
    end;
    Result := Output;
  end;

  function RequiredSerfCount: Integer;
  var
    I, serfCount, idleCount: Integer;
  begin
    serfCount := gHands[fOwner].Stats.GetUnitQty(utSerf);
    Result := Max(0, Round(gHands[fOwner].Stats.GetUnitQty(utBuilder) - serfCount));

    idleCount := 0;
    for I := 0 to P.Units.Count - 1 do
      if not P.Units[I].IsDeadOrDying
         and (P.Units[I] is TKMUnitSerf)
         and P.Units[I].IsIdle then
        Inc(idleCount);

    // Increase count of serfs carefully (compute fraction of serfs who does not have job)
    if idleCount = 0 then
      Result := Max( 1
        + Ord(serfCount < AI_Par[MANAGEMENT_CheckUnitCount_SerfLimit1])
        + Ord(serfCount < AI_Par[MANAGEMENT_CheckUnitCount_SerfLimit2])
        + Ord(serfCount < AI_Par[MANAGEMENT_CheckUnitCount_SerfLimit3]), Result);
  end;

  procedure TrainByPriority(const aPrior: TKMTrainPriorityArr; var aUnitReq: TKMUnitReqArr; var aSchools: TKMSchoolHouseArray; aSchoolCnt: Integer);
  const
    MAX_QUEUE = 4;
  var
    K,L,MinQueue,MinQueueIdx: Integer;
    UT: TKMUnitType;
  begin
    for K := Low(aPrior) to High(aPrior) do
    begin
      UT := aPrior[K];
      while (aUnitReq[UT] > 0) do
      begin
        MinQueue := MAX_QUEUE;
        MinQueueIdx := 0;
        for L := 0 to aSchoolCnt - 1 do
          if (aSchools[L].QueueCount < MinQueue) then
          begin
            MinQueue := aSchools[L].QueueCount;
            MinQueueIdx := L;
          end;
        if (MinQueue < MAX_QUEUE) then // Order citizen, decrease unit requirement
          Dec(aUnitReq[UT], aSchools[MinQueueIdx].AddUnitToQueue(UT,1))
        else
          break;
      end;
    end;
  end;

  procedure Dismiss(var aUnitReq: TKMUnitReqArr);
  var
    K: Integer;
    UT: TKMUnitType;
    HT: TKMHouseType;
  begin
    // Adjust worker count
    aUnitReq[utBuilder] := aUnitReq[utBuilder] * Byte(fPredictor.CityCompleted);
    // Convert planned houses to units
    for HT := HOUSE_MIN to HOUSE_MAX do
      if gRes.Houses[HT].CanHasWorker AND (HT <> htBarracks) then
        Inc(aUnitReq[gRes.Houses[HT].WorkerType], fBuilder.Planner.PlannedHouses[HT].Count);
    // Dismiss units
    for UT in DISMISS_UNITS do
    begin
      K := 0;
      while (aUnitReq[UT] < -1) AND (K < gHands[fOwner].Units.Count) do // -1 for reserve
      begin
        if (gHands[fOwner].Units[K].UnitType = UT)
            AND (gHands[fOwner].Units[K].Home = nil)
            AND gHands[fOwner].Units[K].Dismissable then
        begin
          Inc(aUnitReq[UT]);
          gHands[fOwner].Units[K].Dismiss;
        end;
        Inc(K);
      end;
    end;
  end;

var
  GoldShortage: Boolean;
  K,L,cnt: Integer;
  GoldProduced: Cardinal;
  H: TKMHouse;
  HT: TKMHouseType;
  UT: TKMUnitType;
  Schools: TKMSchoolHouseArray;
  Houses: TKMHouseAvailArr;
  UnitReq, UnitTrain: TKMUnitReqArr;
begin
  P := gHands[fOwner];
  Stats := P.Stats;
  //Clear up
  FillChar(UnitReq, SizeOf(UnitReq), #0);
  FillChar(UnitTrain, SizeOf(UnitTrain), #0);
  FillChar(Houses, SizeOf(Houses), #0);

  //Citizens
  // Make sure we have enough gold left for self-sufficient city
  GoldProduced := Stats.GetWaresProduced(wtGold);
  GoldShortage := (Stats.GetWareBalance(wtGold) < AI_Par[MANAGEMENT_GoldShortage]) AND (GoldProduced = 0);
  if GoldShortage then
  begin
    UnitReq[utSerf] := 3; // 3x Serf
    UnitReq[utBuilder] := Byte((fPredictor.WorkerCount > 0) AND (fSetup.AutoBuild OR fSetup.IsRepairAlways));// 1x Worker
    UnitReq[utMiner] := Stats.GetHouseTotal(htCoalMine) + Stats.GetHouseTotal(htGoldMine) + Stats.GetHouseQty(htIronMine); // Miner can go into iron / gold / coal mines (idealy we need 1 gold and 1 coal but it is hard to catch it)
    UnitReq[utMetallurgist] := Stats.GetHouseTotal(htMetallurgists) + Stats.GetHouseQty(htIronSmithy); // Metallurgist (same problem like in case of miner)
    UnitReq[utWoodcutter] := Byte(Stats.GetHouseQty(htWoodcutters) > 0); // 1x Woodcutter
    UnitReq[utStonemason] := Byte(Stats.GetHouseQty(htQuarry) > 0); // 1x StoneCutter
    UnitReq[utCarpenter] := Byte(Stats.GetHouseQty(htSawmill) > 0); // 1x Lamberjack
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

    // Convert houses to required units
    for HT := HOUSE_MIN to HOUSE_MAX do
      if gRes.Houses[HT].CanHasWorker AND (HT <> htBarracks) then
        Inc(UnitTrain[gRes.Houses[HT].WorkerType], Houses[HT]);

    UnitReq[utRecruit] := 0;
    UnitReq[utSerf] := 0;
    UnitReq[utBuilder] := 0;
    if (Stats.GetWareBalance(wtGold) > AI_Par[MANAGEMENT_GoldShortage] * AI_Par[MANAGEMENT_CheckUnitCount_WorkerGoldCoef]) OR (GoldProduced > 0) then // Dont train servs / workers / recruits when we will be out of gold
    begin
      UnitReq[utBuilder] :=  fPredictor.WorkerCount * Byte(not gHands[fOwner].AI.ArmyManagement.Defence.CityUnderAttack) * Byte(fSetup.AutoBuild) + Byte(not fSetup.AutoBuild) * Byte(fSetup.IsRepairAlways) * 5;
      UnitReq[utRecruit] := RecruitsNeeded(Houses[htWatchTower]);
    end;
    if (Stats.GetWareBalance(wtGold) > AI_Par[MANAGEMENT_GoldShortage] * AI_Par[MANAGEMENT_CheckUnitCount_SerfGoldCoef]) OR (GoldProduced > 0) then // Dont train servs / workers / recruits when we will be out of gold
      UnitReq[utSerf] := Stats.GetUnitQty(utSerf) + RequiredSerfCount();
  end;

  // Consider existing units
  fUnitReqCnt := 0;
  for UT := Low(UnitReq) to High(UnitReq) do
  begin
    UnitReq[UT] := UnitReq[UT] - Stats.GetUnitQty(UT);
    UnitTrain[UT] := UnitTrain[UT] + UnitReq[UT];
    fUnitReqCnt := Min(fUnitReqCnt + Max(0,UnitReq[UT]), High(Word));
  end;

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
      if GoldShortage AND (Schools[cnt].CheckWareIn(wtGold) = 0) then // Ignore empty schools when we are out of gold
        Continue;
      for L := Schools[cnt].QueueLength - 1 downto 0 do
        if (Schools[cnt].Queue[L] <> utNone) then
        begin
          if L = 0 then // Queue is already active
            Dec(UnitTrain[ Schools[Cnt].Queue[L] ],1)
          else // Remove from Queue (it doesn't have to be actual ... when is city under attack we have to save gold)
            Schools[Cnt].RemUnitFromQueue(L);
        end;
      cnt := cnt + 1;
    end;


  // Order citizen training
  if (cnt > 0) then
  begin
    if (gHands[fOwner].Stats.GetUnitQty(utSerf) < gHands[fOwner].Stats.GetHouseQty(htAny)) then // Keep minimal amount of serfs
      TrainByPriority(TRAINING_PRIORITY_Serf, UnitTrain, Schools, cnt)
    else
      TrainByPriority(TRAINING_PRIORITY, UnitTrain, Schools, cnt);
  end;

  // Dismiss unused units
  Dismiss(UnitReq);
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

  procedure CheckTrades();
  const
    WARE_RESERVE = 3;
  var
    K: Integer;
    Houses: TKMHousesCollection;
    HM: TKMHouseMarket;
  begin
    Houses := gHands[fOwner].Houses;
    for K := 0 to Houses.Count - 1 do
      if (Houses[K] <> nil)
        AND not Houses[K].IsDestroyed
        AND Houses[K].IsComplete
        AND (Houses[K].HouseType = htMarket) then
      begin
        HM := TKMHouseMarket(Houses[K]);
        if (HM.WareOrder[0] > 0)
          AND (gHands[fOwner].Stats.GetWareBalance(HM.ResFrom) < HM.WareOrder[0] * HM.RatioFrom + WARE_RESERVE) then
          HM.WareOrder[0] := 0; // Cancel the trade
      end;
  end;

  procedure TryBuyItem(aResFrom, aResTo: TKMWareType);
  const
    TRADE_QUANTITY = 10;
  var
    K: Integer;
    Houses: TKMHousesCollection;
    HM, Market: TKMHouseMarket;
  begin
    Market := nil;
    Houses := gHands[fOwner].Houses;
    for K := 0 to Houses.Count - 1 do
      if (Houses[K] <> nil)
        AND not Houses[K].IsDestroyed
        AND (Houses[K].HouseType = htMarket)
        AND Houses[K].IsComplete then
      begin
        HM := TKMHouseMarket(Houses[K]);
        // Market have an order
        if (HM.WareOrder[0] > 0) then
        begin
          if (HM.ResTo = aResTo) then
            Exit;
        end
        // Market is free
        else if HM.AllowedToTrade(aResFrom) AND HM.AllowedToTrade(aResTo) then
          Market := HM;
      end;
    if (Market <> nil) then
    begin
      Market.WareOrder[0] := 0; //First we must cancel the current trade
      Market.ResFrom := aResFrom;
      Market.ResTo := aResTo;
      Market.WareOrder[0] := TRADE_QUANTITY; //Set the new trade
    end;
  end;
const
  SOLD_ORDER: array[0..19] of TKMWareType = (
    wtSausage,      wtWine,     wtBread, wtFish,
    wtWoodenShield, wtAxe,      wtLance, wtBow,      wtLeatherArmor,
    wtIronShield,   wtSword,    wtPike,  wtCrossbow, wtIronArmor,
    wtHorse,        wtFlour,
    wtSkin,         wtLeather,  wtPig,
    wtTrunk        //wtTimber,  wtCorn,
    //wtIron,        wtGold,     wtIronOre,    wtCoal,     wtGoldOre,
    //wtStone
  );
  LACK_OF_STONE = 50;
  WARFARE_SELL_LIMIT = 10;
  SELL_LIMIT = 30;
var
  minGoldAmount, MarketCnt, I, WareCnt: Integer;
  WT: TKMWareType;
begin

  MarketCnt := gHands[fOwner].Stats.GetHouseQty(htMarket);
  if MarketCnt = 0 then
    Exit
  else
    CheckTrades();

  RequiedCnt := 0;
  SetLength(RequiredWares,4);
  with gHands[fOwner].Stats do
  begin
    // Gold
    if (GetHouseQty(htMetallurgists) = 0)
       AND (GetWareBalance(wtGold) <= AI_Par[MANAGEMENT_GoldShortage]) then
       AddWare(wtGold);
    // Stone
    if (GetWareBalance(wtStone)-GetHouseQty(htWatchTower)*5 < LACK_OF_STONE)
      AND (Builder.Planner.PlannedHouses[htQuarry].Completed = 0) then
      AddWare(wtStone);
    // Gold ore
    minGoldAmount := Round(AI_Par[MANAGEMENT_GoldShortage] * 3);
    if ( fPredictor.WareBalance[wtGoldOre].Exhaustion < 20 )
      AND ( GetWareBalance(wtGold) < minGoldAmount )
      AND ( GetWareBalance(wtGoldOre) < minGoldAmount ) then
      AddWare(wtGoldOre);
    // Coal
    if ( fPredictor.WareBalance[wtCoal].Exhaustion < 50 )
      AND ( GetWareBalance(wtCoal) < minGoldAmount + 5 * (Builder.Planner.PlannedHouses[htWeaponSmithy].Completed + Builder.Planner.PlannedHouses[htIronSmithy].Completed + Builder.Planner.PlannedHouses[htArmorSmithy].Completed) )
      AND (Builder.Planner.PlannedHouses[htCoalMine].UnderConstruction = 0) then
      AddWare(wtCoal);
  end;

  if RequiedCnt = 0 then
    Exit;

  AvailableCnt := 0;
  SetLength(AvailableWares, RequiedCnt);
  for WT in SOLD_ORDER do
    if (AvailableCnt < RequiedCnt) then
    begin
      WareCnt := gHands[fOwner].Stats.GetWareBalance(WT);
      if (  (WT in [WARFARE_MIN..WARFARE_MAX]) AND (WareCnt > WARFARE_SELL_LIMIT)  )
         OR (  (WareCnt > SELL_LIMIT) AND (fPredictor.WareBalance[WT].Exhaustion > 90)  ) then
        AddWare(WT, False);
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
        S.NotAcceptFlag[wtTimber] := (S.CheckWareIn(wtTimber) > 20) OR (aTick > WOOD_STORE_DELAY);// AND (Predictor.WareBalance[wtWood].Exhaustion > 40);
        S.NotAcceptFlag[wtStone] := (aTick > STONE_STORE_DELAY) OR (S.CheckWareIn(wtStone) * AI_Par[MANAGEMENT_CheckStoreWares_Stone] > Stats.GetUnitQty(utBuilder));
        S.NotAcceptFlag[wtGold] := S.CheckWareIn(wtGold) > 400; // Everyone needs as much gold as possible

        // Food - don't store food when we have enough (it will cause trafic before storehouse)
        S.NotAcceptFlag[wtWine] := Stats.GetWareBalance(wtWine) > 100;
        S.NotAcceptFlag[wtSausage] := Stats.GetWareBalance(wtSausage) > 100;
        S.NotAcceptFlag[wtBread] := Stats.GetWareBalance(wtBread) > 100;
        S.NotAcceptFlag[wtFish] := Stats.GetWareBalance(wtFish) > 100;

        // Others
        S.NotAcceptFlag[wtGoldOre] := True;
        S.NotAcceptFlag[wtCoal] := True;
        S.NotAcceptFlag[wtIronOre] := Stats.GetHouseQty(htIronSmithy) > 0;
        S.NotAcceptFlag[wtIron] := Stats.GetHouseQty(htWeaponSmithy) +
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
      AND H.ResourceDepleted then
    begin
      H.IsClosedForWorker := True;
      if (H.CheckWareOut(wtAll) = 0) then
      begin
        Loc := H.Entrance;
        // Remove avoid building around coal mine
        if (H.HouseType = htCoalMine) then
          gAIFields.Influences.RemAvoidBuilding(KMRect(Loc.X-3, Loc.Y-3, Loc.X+4, Loc.Y+2));
        // Mark house plan as exhausted
        Builder.Planner.MarkAsExhausted(H.HouseType, Loc);
        H.Demolish(fOwner);
      end;
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
        Houses[I].BuildingRepair := False;
        if (Houses[I].HouseType = htWatchTower) AND (Houses[I].DeliveryMode = dmDelivery) then
          Houses[I].SetDeliveryModeInstantly(dmClosed);
      end;
    end
    else
    begin
      for I := 0 to Houses.Count - 1 do
      begin
        Houses[I].BuildingRepair := fSetup.IsRepairAlways;
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
          Inc(Deficit, H.CheckWareIn(wtGoldOre) + H.CheckWareOut(wtGoldOre) - H.CheckWareIn(wtCoal) - H.CheckWareOut(wtCoal));
        end;
    Result := (Deficit / HouseCnt) > MAX_DEFICIT;
  end;
begin
  with gHands[fOwner].Stats do
  begin
    // Wood
    if Builder.WoodShortage OR Builder.TrunkShortage then
    begin
      WareDistribution[wtTimber, htArmorWorkshop] := 0;
      WareDistribution[wtTimber, htWeaponWorkshop] := 2;
    end
    else
    begin
      WareDistribution[wtTimber, htArmorWorkshop] := 2;
      WareDistribution[wtTimber, htWeaponWorkshop] := 5;
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
      gHands[fOwner].Stats.WareDistribution[wtCoal, htIronSmithy] := 1;
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
    //gHands[fOwner].Stats.WareDistribution[wtIron, htWeaponSmithy] := 5;
    //gHands[fOwner].Stats.WareDistribution[wtIron, htArmorSmithy] := 5;

    gHands[fOwner].Houses.UpdateDemands;
  end;
end;


// Calculate weapons demand from combat AI requirements
procedure TKMCityManagement.WeaponsBalance();
var
  EnemyEval, AllyEval: TKMArmyEval;
  AllyCounterWeightRatio: array[GROUP_TYPE_MIN..GROUP_TYPE_MAX] of Single;

  procedure ComputeGroupDemands(aGT: TKMGroupType; aIronRatio: Single);
  const
    // It doesnt depends on future "optimalization" of parameters: against cav should be always good pikes etc. so this array doesnt have to be computed
    BEST_VERSUS_OPTION: array[GROUP_TYPE_MIN..GROUP_TYPE_MAX, GROUP_TYPE_MIN..GROUP_TYPE_MAX] of Single = (
        // Melee, AntiHorse, Ranged, Mounted
        (0.6, 0.0, 0.4, 0.0), // Melee
        (0.4, 0.0, 0.6, 0.0), // AntiHorse
        (0.0, 0.0, 0.7, 0.3), // Ranged
        (0.0, 0.8, 0.2, 0.0)  // Mounted
      );
  var
    I: Integer;
    EnemyStrength, UnitStrength, UnitsRequired, Wood, Iron: Single;
    UT: TKMUnitType;
    GT: TKMGroupType;
    UnitEval: TKMGroupEval;
  begin
    // Get best type of oponent and compute iron ratio
    Wood := 0;
    Iron := 0;
    for GT := GROUP_TYPE_MIN to GROUP_TYPE_MAX do
      if (BEST_VERSUS_OPTION[aGT,GT] > 0) then
        for I := 1 to 3 do
        begin
          UT := AI_TROOP_TRAIN_ORDER[GT,I];
          if (UT <> utNone) AND not gHands[fOwner].Locks.GetUnitBlocked(UT) then
            if (I = 1) then
              Iron := Iron + 1
            else
              Wood := Wood + 1;
        end;
    if (Wood = 0) AND (Iron = 0) then
      Exit
    else if (Wood > 0) AND (Iron = 0) then
      aIronRatio := 0
    else if (Wood = 0) AND (Iron > 0) then
      aIronRatio := 1;

    // Compute strength of specific enemy group
    EnemyStrength := 0;
    for GT := GROUP_TYPE_MIN to GROUP_TYPE_MAX do
      with EnemyEval.Groups[aGT] do
        EnemyStrength := EnemyStrength + BEST_VERSUS_OPTION[aGT,GT]
          * (Attack + AttackHorse * Byte(GT = gtMounted))
          * IfThen( (GT = gtRanged), DefenceProjectiles, Defence )
          * HitPoints;

    // Decrease strength by owner's existing units
    for GT := GROUP_TYPE_MIN to GROUP_TYPE_MAX do
      with AllyEval.Groups[GT] do
      begin
        EnemyStrength := EnemyStrength - BEST_VERSUS_OPTION[aGT,GT]
          * (Attack + AttackHorse * Byte(aGT = gtMounted))
          * IfThen( (aGT = gtRanged), DefenceProjectiles, Defence )
          * HitPoints;
        AllyCounterWeightRatio[GT] := AllyCounterWeightRatio[GT] + BEST_VERSUS_OPTION[aGT,GT] * Byte(EnemyEval.Groups[aGT].Count > 0);
      end;
    EnemyStrength := Max(0, EnemyStrength);

    // Compute unit requirements
    for GT := GROUP_TYPE_MIN to GROUP_TYPE_MAX do
      if (BEST_VERSUS_OPTION[aGT,GT] > 0) then
        for I := 1 to 3 do
        begin
          UT := AI_TROOP_TRAIN_ORDER[GT,I];
          // Skip unit type in case that it is blocked
          if (UT = utNone) OR gHands[fOwner].Locks.GetUnitBlocked(UT) then
            Continue;
          // Calculate required count of specific unit type
          UnitEval := gAIFields.Eye.ArmyEvaluation.UnitEvaluation(UT, True);
          with UnitEval do
            UnitStrength := (Attack + AttackHorse * Byte(aGT = gtMounted))
              * IfThen( (aGT = gtRanged), DefenceProjectiles, Defence )
              * HitPoints;

          UnitsRequired := BEST_VERSUS_OPTION[aGT,GT] * Power(EnemyStrength / Max(0.0001, UnitStrength), 1/3) * IfThen( (I = 1), aIronRatio, 1-aIronRatio );
          fWarriorsDemands[UT] := fWarriorsDemands[UT] + Max(0, Round(UnitsRequired));
          if (I = 2) then // In case that utAxeFighter is not blocked skip militia
            Break;
        end;
  end;

  procedure CheckMinArmyReq();
  const
    DEFAULT_COEFICIENT = 15;
    DEFAULT_ARMY_REQUIREMENTS: array[WARRIOR_EQUIPABLE_BARRACKS_MIN..WARRIOR_EQUIPABLE_BARRACKS_MAX] of Single = (
      1, 1, 1, 3,   // utMilitia,      utAxeFighter,   utSwordFighter,  utBowman,
      2, 1, 1, 0.5, // utCrossbowman,  utLanceCarrier, utPikeman,       utScout,
      0.5           // utKnight
    );
    WOOD_ARMY: set of TKMUnitType = [utAxeFighter, utBowman, utLanceCarrier];   // utScout,
    IRON_ARMY: set of TKMUnitType = [utSwordFighter, utCrossbowman, utPikeman]; // utKnight
  var
    I, WoodReq, IronReq: Integer;
    RatioSum: Single;
    UT: TKMUnitType;
    GT: TKMGroupType;
  begin
    // Get ratio of equiped soldiers
    RatioSum := 0;
    for GT := GROUP_TYPE_MIN to GROUP_TYPE_MAX do
      RatioSum := RatioSum + AllyCounterWeightRatio[GT];

    // Wood
    WoodReq := Max(+ fRequiredWeapons[wtLeatherArmor].Required - fRequiredWeapons[wtLeatherArmor].Available,
                   + fRequiredWeapons[wtAxe].Required - fRequiredWeapons[wtAxe].Available
                   + fRequiredWeapons[wtBow].Required - fRequiredWeapons[wtBow].Available
                   + fRequiredWeapons[wtLance].Required - fRequiredWeapons[wtLance].Available
                  );
    if (WoodReq < 5) then
    begin
      WoodReq := Round((DEFAULT_COEFICIENT - WoodReq) / 5.0); // 5 is equal to sum of all requirements in leather category
      for UT in WOOD_ARMY do
      begin
        GT := UNIT_TO_GROUP_TYPE[UT];
        if not gHands[fOwner].Locks.GetUnitBlocked(UT) AND ((RatioSum = 0) OR (AllyCounterWeightRatio[GT] > 0)) then
          for I := Low(TROOP_COST[UT]) to High(TROOP_COST[UT]) do
            if (TROOP_COST[UT,I] <> wtNone) then
              with fRequiredWeapons[ TROOP_COST[UT,I] ] do
                Required := Min(High(Word), Available + Round(DEFAULT_ARMY_REQUIREMENTS[UT] * WoodReq * max(1, AllyCounterWeightRatio[GT] / max(1,RatioSum)) ));
      end;
    end;

    // Iron
    IronReq := Max(+ fRequiredWeapons[wtIronArmor].Required - fRequiredWeapons[wtIronArmor].Available,
                   + fRequiredWeapons[wtSword].Required - fRequiredWeapons[wtSword].Available
                   + fRequiredWeapons[wtCrossbow].Required - fRequiredWeapons[wtCrossbow].Available
                   + fRequiredWeapons[wtPike].Required - fRequiredWeapons[wtPike].Available
                  );
    if (IronReq < 5) then
    begin
      //IronReq := Round((DEFAULT_COEFICIENT - IronReq) / 5.0); // 5 is equal to sum of all requirements in iron category
      for UT in IRON_ARMY do
        if not gHands[fOwner].Locks.GetUnitBlocked(UT) then
          for I := Low(TROOP_COST[UT]) to High(TROOP_COST[UT]) do
            if (TROOP_COST[UT,I] <> wtNone) then
              with fRequiredWeapons[ TROOP_COST[UT,I] ] do
                Required := Min(High(Word), Round(abs(IronReq) + DEFAULT_COEFICIENT * DEFAULT_ARMY_REQUIREMENTS[UT]));
      fRequiredWeapons[wtIronArmor].Required := fRequiredWeapons[wtIronArmor].Required * 3;
    end;
  end;
//AITroopTrainOrder: array [GROUP_TYPE_MIN..GROUP_TYPE_MAX, 1..3] of TKMUnitType = (
//  (utSwordFighter, utAxeFighter,   utMilitia),
//  (utPikeman,      utLanceCarrier, utNone),
//  (utCrossbowman,  utBowman,       utNone),
//  (utKnight,       utScout,        utNone)
//);
//UnitGroups: array [WARRIOR_MIN..WARRIOR_MAX] of TKMGroupType = (
//  gtMelee,gtMelee,gtMelee,  // utMilitia, utAxeFighter, utSwordFighter
//  gtRanged,gtRanged,        // utBowman, utCrossbowman
//  gtAntiHorse,gtAntiHorse,  // utLanceCarrier, utPikeman,
//  gtMounted,gtMounted,      // utScout, utKnight,
//  gtMelee,                  // utBarbarian
//  //TPR Army
//  gtAntiHorse,        // utRebel
//  gtRanged,           // utRogue
//  gtMelee,            // utWarrior
//  gtMounted           // utVagabond
//);
//TroopCost: array [utMilitia..utKnight, 1..4] of TKMWareType = (
//  (wtAxe,          wtNone,        wtNone,  wtNone ), // utMilitia
//  (wtWoodenShield, wtLeatherArmor,wtAxe,   wtNone ), // utAxeFighter
//  (wtIronShield,   wtIronArmor,   wtSword, wtNone ), // utSwordFighter
//  (wtLeatherArmor, wtBow,         wtNone,  wtNone ), // utBowman
//  (wtIronArmor,    wtCrossbow,    wtNone,  wtNone ), // utCrossbowman
//  (wtLeatherArmor, wtLance,       wtNone,  wtNone ), // utLanceCarrier
//  (wtIronArmor,    wtPike,        wtNone,  wtNone ), // utPikeman
//  (wtWoodenShield, wtLeatherArmor,wtAxe,   wtHorse), // utScout
//  (wtIronShield,   wtIronArmor,   wtSword, wtHorse)  // utKnight
//);
//WARRIOR_EQUIPABLE_MIN = utMilitia;
//WARRIOR_EQUIPABLE_MAX = utKnight;
//  utMilitia,     utAxeFighter,   utSwordFighter, utBowman,
//  utCrossbowman, utLanceCarrier, utPikeman,      utScout,
//  utKnight,      utBarbarian,

const
  IRON_WEAPONS: set of TKMWareType = [wtSword, wtPike, wtCrossbow];
  IRON_ARMORS: set of TKMWareType = [wtIronArmor, wtIronShield];
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
  //AllyEval := gAIFields.Eye.ArmyEvaluation.AllianceEvaluation(aPlayer, atAlly);
  AllyEval := gAIFields.Eye.ArmyEvaluation.PlayerEvaluation(fOwner);
  EnemyEval := gAIFields.Eye.ArmyEvaluation.AllianceEvaluation(fOwner, atEnemy);

  // Compute requirements of warriors
  FillChar(AllyCounterWeightRatio, sizeOf(AllyCounterWeightRatio),#0);
  FillChar(fWarriorsDemands, sizeOf(fWarriorsDemands),#0);
  for GT := GROUP_TYPE_MIN to GROUP_TYPE_MAX do
    ComputeGroupDemands(GT, IronRatio);

  // Get weapons reserves
  for WT := Low(fRequiredWeapons) to High(fRequiredWeapons) do
  begin
    fRequiredWeapons[WT].Available := gHands[fOwner].Stats.GetWareBalance(WT);
    fRequiredWeapons[WT].Required := 0;
  end;

  // Get count of needed weapons
  for UT := utAxeFighter to WARRIOR_EQUIPABLE_BARRACKS_MAX do // Skip militia
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
      Fraction := Max(1,Available) / Max(1,Required);

  // Dont produce bows and spears when we dont produce leather
  if (gGame.Options.Peacetime < 45) AND (
    (gHands[fOwner].Stats.GetWareBalance(wtLeather) = 0) AND
    (gHands[fOwner].Stats.GetWareBalance(wtLeatherArmor) = 0) ) then
  begin
    fRequiredWeapons[wtBow].Fraction := 1;
    fRequiredWeapons[wtLance].Fraction := 1;
    fRequiredWeapons[wtAxe].Fraction := 0;
  end;

  // Calculate mean fraction of iron weapons and distribute steal
  WeaponFraction := 0;
  for WT in IRON_WEAPONS do
    WeaponFraction := WeaponFraction + fRequiredWeapons[WT].Fraction;
  WeaponFraction := WeaponFraction / 3.0;
  if (fRequiredWeapons[wtIronArmor].Fraction > fRequiredWeapons[wtIronShield].Fraction) then
  begin
    ArmorFraction := 0;
    for WT in IRON_ARMORS do
      ArmorFraction := ArmorFraction + fRequiredWeapons[WT].Fraction;
    ArmorFraction := ArmorFraction / 2.0;
  end
  else
    ArmorFraction := fRequiredWeapons[wtIronArmor].Fraction; // Consider only metal armor in case that we have enough metal shields
  // We always want the higher requirements equal to 5 + something between 1 <-> 5 for second production
  IronShare := 5 * (WeaponFraction + ArmorFraction) / Max(WeaponFraction, ArmorFraction);
  // Ware distribution = fraction / sum of fractions * 5
  gHands[fOwner].Stats.WareDistribution[wtIron, htWeaponSmithy] := Max(  1, Min(5, Round( ArmorFraction / (WeaponFraction + ArmorFraction) * IronShare) )  );
  gHands[fOwner].Stats.WareDistribution[wtIron, htArmorSmithy] := Max(  1, Min(5, Round( WeaponFraction / (WeaponFraction + ArmorFraction) * IronShare) )  );
  gHands[fOwner].Houses.UpdateDemands;
end;


// Distribute required weapons into exist houses (first will be produced the larger amount of wares)
procedure TKMCityManagement.OrderWeapons();
const
  WEAPONS_PER_A_UPDATE = 25;
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
      Continue;
    // Find produced ware which is the most required
    MostRequired := 1.0;
    MaxWT := wtNone;
    for I := 1 to 4 do
    begin
      WT := gRes.Houses[HT].WareOutput[I];
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
            Continue;
          for K := 1 to 4 do
            H.WareOrder[K] := 0;
          H.WareOrder[MaxIdx] := WEAPONS_PER_A_UPDATE; // With update each 1-2 minutes there is not need to calculate something more
          if (HT = htArmorWorkshop) then
          begin
            for K := 1 to 4 do
            begin
              WT := gRes.Houses[HT].WareOutput[K];
              if (WT = wtLeatherArmor) then
              begin
                H.WareOrder[K] := 100;
                Break;
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
    ('Shield     ', 'IronShield',  'LeatherArmor','IronArmor',  'Axe         ', 'Sword      ',
     'Lance      ', 'Pike       ', 'Bow        ', 'Crossbow  ', 'Horse      ');
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

