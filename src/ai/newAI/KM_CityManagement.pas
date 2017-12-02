unit KM_CityManagement;
{$I KaM_Remake.inc}
interface
uses
  Classes, KromUtils, Math, SysUtils,
  KM_Defaults, KM_CommonClasses, KM_CommonUtils, KM_Points,
  KM_AISetup, KM_ResHouses, KM_HandStats,
  KM_CityPredictor, KM_CityBuilder, KM_CityPlanner;

type

  //Mayor is the one who manages the town
  TKMCityManagement = class
  private
    fOwner: TKMHandIndex;
    fSetup: TKMHandAISetup;

    fBuilder: TKMCityBuilder;
    fPredictor: TKMCityPredictor;

    fBalanceText: UnicodeString;

    procedure CheckUnitCount();
    procedure CheckMarketplaces();
    procedure CheckStoreWares();
    procedure CheckExhaustedMines();
    procedure CheckWoodcutters();
    procedure CheckAutoRepair();

  public
    constructor Create(aPlayer: TKMHandIndex; aSetup: TKMHandAISetup);
    destructor Destroy(); override;

    procedure AfterMissionInit();
    procedure OwnerUpdate(aPlayer: TKMHandIndex);

    property Builder: TKMCityBuilder read fBuilder;
    property Predictor: TKMCityPredictor read fPredictor;
    property BalanceText: UnicodeString read fBalanceText;

    procedure UpdateState(aTick: Cardinal);
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

  end;


implementation
uses
  KM_Game, KM_Houses, KM_HouseCollection, KM_HouseSchool, KM_HandsCollection, KM_Hand, KM_Terrain, KM_Resource,
  KM_ResWares, KM_AIFields, KM_Units, KM_UnitTaskDelivery, KM_UnitActionWalkTo, KM_UnitTaskGoEat, KM_UnitsCollection,
  KM_NavMesh, KM_HouseMarket;


const
  LACK_OF_GOLD = 10;


{ TKMCityManagement }
constructor TKMCityManagement.Create(aPlayer: TKMHandIndex; aSetup: TKMHandAISetup);
begin
  inherited Create;

  fOwner := aPlayer;
  fSetup := aSetup;
  fSetup := TKMHandAISetup.Create; //DELETE!!!!!!!!!!!!!!!!!!!!
  fSetup.ApplyAgressiveBuilderSetup(True);

  fBuilder := TKMCityBuilder.Create(aPlayer);
  fPredictor := TKMCityPredictor.Create(aPlayer);
end;


destructor TKMCityManagement.Destroy();
begin
  fBuilder.Free;
  fPredictor.Free;

  inherited;
end;


procedure TKMCityManagement.AfterMissionInit();
var
  GoldCnt, IronCnt, FieldCnt, BuildCnt: Integer;
begin
  if (fOwner <> 1) then
    Exit;
  fPredictor.AfterMissionInit();
  fBuilder.AfterMissionInit(GoldCnt, IronCnt, FieldCnt, BuildCnt);


  fPredictor.CityInitialization(GoldCnt, IronCnt, FieldCnt, BuildCnt);

  fBuilder.Planner.CreateCityPlan(fPredictor.RequiredHouses);
  //SetKaMSeed(1);
end;


procedure TKMCityManagement.OwnerUpdate(aPlayer: TKMHandIndex);
begin
  fOwner := aPlayer;
  fBuilder.OwnerUpdate(aPlayer);
  fPredictor.OwnerUpdate(aPlayer);
end;


procedure TKMCityManagement.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.Write(fOwner);
  // fSetup IS NOT SAVED!!!!
  fBuilder.Save(SaveStream);
  fPredictor.Save(SaveStream);
end;


procedure TKMCityManagement.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.Read(fOwner);
  // fSetup IS NOT SAVED!!!!
  fBuilder.Load(LoadStream);
  fPredictor.Load(LoadStream);
end;


procedure TKMCityManagement.UpdateState(aTick: Cardinal);
var
  FreeWorkersCnt: Integer;
begin
  // Priorities
  if (aTick = 10) then
  begin
    //fPredictor.UpdateState();

  end;
  FreeWorkersCnt := 0;
  fBuilder.UpdateState(aTick, FreeWorkersCnt);
  if (FreeWorkersCnt > 0) AND (aTick mod 10 = 0) then
  begin
    fPredictor.UpdateState(aTick);
    fBuilder.ChooseHousesToBuild(3, fPredictor.RequiredHouses, fPredictor.WareBalance);
    //if SHOW_AI_WARE_BALANCE then
    //begin
      fPredictor.LogStatus(fBalanceText);
      fBuilder.LogStatus(fBalanceText);
      fBuilder.Planner.Paint();
    //end;
  end;

  if (aTick mod 120 = 0) then
  begin
    CheckUnitCount();
    //CheckMarketplaces();
    CheckStoreWares();
  end;

  //CheckUnitCount();
end;


// Check existing unit count vs house count and train missing citizens
procedure TKMCityManagement.CheckUnitCount();
var
  P: TKMHand;
  UnitReq: array [CITIZEN_MIN..CITIZEN_MAX] of Integer;

  function TryToTrain(aSchool: TKMHouseSchool; aUnitType: TUnitType; aRequiredCount: Integer): Boolean;
  begin
    // We summ up requirements for e.g. Recruits required at Towers and Barracks
    if P.Stats.GetUnitQty(aUnitType) < (aRequiredCount + UnitReq[aUnitType]) then
    begin
      Dec(UnitReq[aUnitType]); //So other schools don't order same unit
      aSchool.AddUnitToQueue(aUnitType, 1);
      Result := True;
    end
    else
      Result := False;
  end;

  function RecruitsNeeded: Integer;
  var AxesLeft: Integer;
  begin
    if P.Stats.GetHouseQty(ht_Barracks) = 0 then
      Result := 0
    else
      if gGame.IsPeaceTime then
      begin
        //Keep enough recruits to equip using all weapons once PT ends
        //Iron soldiers
        Result := Min(P.Stats.GetWareBalance(wt_MetalArmor),
                      P.Stats.GetWareBalance(wt_Arbalet) + P.Stats.GetWareBalance(wt_Hallebard)
                      + Min(P.Stats.GetWareBalance(wt_Sword), P.Stats.GetWareBalance(wt_MetalShield)));
        //Leather soldiers we can make
        Inc(Result, Min(P.Stats.GetWareBalance(wt_Armor),
                        P.Stats.GetWareBalance(wt_Bow) + P.Stats.GetWareBalance(wt_Pike)
                        + Min(P.Stats.GetWareBalance(wt_Axe), P.Stats.GetWareBalance(wt_Shield))));
        //Militia with leftover axes
        AxesLeft := P.Stats.GetWareBalance(wt_Axe) - Min(P.Stats.GetWareBalance(wt_Armor), P.Stats.GetWareBalance(wt_Shield));
        if AxesLeft > 0 then
          Inc(Result, AxesLeft);
      end
      else
        Result := fSetup.RecruitCount * P.Stats.GetHouseQty(ht_Barracks);
  end;

  function RequiredServCount: Byte;
  var I: Integer;
    Output: Byte;
  begin
    Result := 0;
    Output := Max(0, gHands[fOwner].Stats.GetUnitQty(ut_Worker) - gHands[fOwner].Stats.GetUnitQty(ut_Serf));
    for I := 0 to p.Units.Count - 1 do
      if not p.Units[I].IsDeadOrDying
         AND (p.Units[I] is TKMUnitSerf)
         AND (p.Units[I].UnitTask = nil) then
           Exit;
    // Increase count of serfs carefully
    if gHands[fOwner].Stats.GetUnitQty(ut_Serf) < 60 then
      Output := Max(4, Result)
    else if gHands[fOwner].Stats.GetUnitQty(ut_Serf) < 80 then
      Output := Max(2, Result)
    else
      Output := Max(1, Result);
    Result := Output;
  end;

var
  I,K: Integer;
  H: THouseType;
  UT: TUnitType;
  Schools: array of TKMHouseSchool;
  HS: TKMHouseSchool;
  //serfCount: Integer;
const
  PRIORITY_TRAINING: array[0..12] of TUnitType = (
    ut_Miner, ut_Metallurgist, ut_StoneCutter, ut_Woodcutter, ut_Lamberjack,
    ut_Farmer, ut_AnimalBreeder, ut_Baker, ut_Butcher, ut_Fisher, ut_Smith, ut_Serf, ut_Worker
  );
begin
  //todo: When training new units make sure we have enough gold left to train
  //stonemason-woodcutter-carpenter-2miners-metallurgist. In other words -
  //dont waste gold if it's not producing yet

  P := gHands[fOwner];
  FillChar(UnitReq, SizeOf(UnitReq), #0); //Clear up

  //Citizens
  // Make sure we have enough gold left for self-sufficient city
  if (P.Stats.GetWareBalance(wt_Gold) < LACK_OF_GOLD) AND (P.Stats.GetHouseQty(ht_Metallurgists) = 0) then
  begin
    Inc(UnitReq[ut_Serf], 3 * Byte(P.Stats.GetUnitQty(ut_Serf) < 3)); // 3x Serf
    Inc(UnitReq[ut_Worker], Byte((P.Stats.GetUnitQty(ut_Worker) = 0) AND (fSetup.WorkerCount > 0)));// 1x Worker
    Inc(UnitReq[ut_Miner], P.Stats.GetHouseQty(ht_CoalMine) + P.Stats.GetHouseQty(ht_IronMine) + P.Stats.GetHouseQty(ht_GoldMine) - P.Stats.GetUnitQty(ut_Miner)); // Miner can go into iron / gold / coal mines (idealy we need 1 gold and 1 coal but it is hard to catch it)
    Inc(UnitReq[ut_Metallurgist], P.Stats.GetHouseQty(ht_Metallurgists) + P.Stats.GetHouseQty(ht_IronSmithy) - P.Stats.GetUnitQty(ut_Metallurgist)); // Metallurgist (same problem like in case of miner)
    Inc(UnitReq[ut_Woodcutter], Byte(P.Stats.GetUnitQty(ut_Woodcutter) = 0)); // 1x Woodcutter
    Inc(UnitReq[ut_StoneCutter], Byte(P.Stats.GetUnitQty(ut_StoneCutter) = 0)); // 1x StoneCutter
    Inc(UnitReq[ut_Lamberjack], Byte(P.Stats.GetUnitQty(ut_Lamberjack) = 0)); // 1x Lamberjack
  end
  //Count overall unit requirement (excluding Barracks and ownerless houses)
  else
  begin
    for H := HOUSE_MIN to HOUSE_MAX do
      if (gRes.Houses[H].OwnerType <> ut_None) and (H <> ht_Barracks) then
        Inc(UnitReq[gRes.Houses[H].OwnerType], P.Stats.GetHouseQty(H));
    for UT := Low(UnitReq) to High(UnitReq) do
      Dec(UnitReq[UT], P.Stats.GetUnitQty(UT));
    //UnitReq[ut_Serf] := Round(fSetup.SerfsPerHouse * (P.Stats.GetHouseQty(ht_Any) + P.Stats.GetUnitQty(ut_Worker)/2));
    UnitReq[ut_Serf] := RequiredServCount;
    UnitReq[ut_Worker] := fSetup.WorkerCount - P.Stats.GetUnitQty(ut_Worker);
  end;

  //Schools
  //Count overall schools count and exclude already training units from UnitReq
  SetLength(Schools, P.Stats.GetHouseQty(ht_School));
  K := 1;
  HS := TKMHouseSchool(P.FindHouse(ht_School, K));
  while HS <> nil do
  begin
    Schools[K-1] := HS;
    for I := 0 to HS.QueueLength - 1 do //Decrease requirement for each unit in training
      if HS.Queue[I] <> ut_None then
      begin
        if I = 0 then // if Queue is already active
          Dec(UnitReq[HS.Queue[I]]) //Can be negative and compensated by e.g. ReqRecruits
        else // else remove from Queue (it doesn't have to be actual ... when is city under attack we have to save gold)
          HS.RemUnitFromQueue(I);
      end;
    Inc(K);
    HS := TKMHouseSchool(P.FindHouse(ht_School, K));
  end;

  //Order the training. Keep up to 2 units in the queue so the school doesn't have to wait
  for I := 0 to High(Schools) do
  begin
    HS := Schools[I];
    if (HS <> nil) then
    begin
      //Order citizen training
      for K := Low(PRIORITY_TRAINING) to High(PRIORITY_TRAINING) do
      begin
        UT := PRIORITY_TRAINING[K];
        if UnitReq[UT] > 0 then
        begin
          Dec(UnitReq[UT], HS.AddUnitToQueue(UT, Min(UnitReq[UT], 2))); //So other schools don't order same unit
          if HS.QueueCount > 1 then //Don't need more UnitTypes yet
            Break;
        end;
      end;

      // While still haven't found a match...
      while (HS.QueueCount < 2) do
      begin
        // If we are low on Gold don't hire more ppl (next school will fail this too, so we can exit)
        if P.Stats.GetWareBalance(wt_Gold) < LACK_OF_GOLD then
          break;

        if not gGame.CheckTime(fSetup.RecruitDelay) then //Recruits can only be trained after this time
          Break
        else
          if not TryToTrain(HS, ut_Recruit, RecruitsNeeded) then
            Break; //There's no unit demand at all
      end;
    end;
  end;
end;


//Check if specific woodcutters are in Fell only mode
procedure TKMCityManagement.CheckMarketplaces();
var
  MarketCnt, RequiedCnt, AvaiableCnt, L: Word;
  RequiredWares, AvaiableWares: array of TWareType;
const
  SOLD_ORDER: array[0..27] of TWareType = (
    wt_Sausages,     wt_Wine,     wt_Fish,       wt_Bread,
    wt_Skin,         wt_Leather,  wt_Pig,
    wt_Trunk,        wt_Stone,    wt_Wood,
    wt_Shield,       wt_Axe,      wt_Pike,       wt_Bow,      wt_Armor,
    wt_MetalShield,  wt_Sword,    wt_Hallebard,  wt_Arbalet,  wt_MetalArmor,
    wt_Horse,        wt_Corn,     wt_Flour,
    wt_Steel,        wt_Gold,     wt_IronOre,    wt_Coal,     wt_GoldOre
  );

  procedure AddWare(aWare: TWareType; IsRequired: Boolean = True);
  begin
    if IsRequired then
    begin
      RequiredWares[RequiedCnt] := aWare;
      Inc(RequiedCnt,1);
    end
    else
    begin
      AvaiableWares[AvaiableCnt] := aWare;
      Inc(AvaiableCnt,1);
    end;
  end;

  procedure TryBuyItem(aResFrom, aResTo: TWareType);
  var
    M: Integer;
    Houses: TKMHousesCollection;
    H: TKMHouseMarket;
  begin
    Houses := gHands[fOwner].Houses;
    for M := 0 to Houses.Count - 1 do
      if (Houses[M].HouseType = ht_Marketplace)
        AND Houses[M].IsComplete
        AND not Houses[M].IsDestroyed then
      begin
        H := TKMHouseMarket(Houses[M]);
        if (TKMHouseMarket(H).ResOrder[0] <> 0)
          AND (H.ResTo = aResTo) then
          Exit;
      end;
    for M := 0 to Houses.Count - 1 do
      if (Houses[M].HouseType = ht_Marketplace)
        AND Houses[M].IsComplete
        AND not Houses[M].IsDestroyed then
      begin
        H := TKMHouseMarket(Houses[M]);
        if H.AllowedToTrade(aResFrom)
          AND H.AllowedToTrade(aResTo)
          AND (TKMHouseMarket(H).ResOrder[0] = 0) then
        begin
          if (H.ResFrom <> aResFrom) or (H.ResTo <> aResTo) then
          begin
            //H.ResOrder[0] := 0; //First we must cancel the current trade
            H.ResFrom := aResFrom;
            H.ResTo := aResTo;
            H.ResOrder[0] := 20; //Set the new trade
            break;
          end;
        end;
      end;
  end;
const
  MIN_GOLD_AMOUNT = LACK_OF_GOLD * 3;
  LACK_OF_STONE = 50;
  SELL_LIMIT = 100;
begin


  MarketCnt := gHands[fOwner].Stats.GetHouseQty(ht_Marketplace);
  if MarketCnt = 0 then
    Exit;

  //TryBuyItem(wt_Coal, wt_GoldOre);
  //{
  RequiedCnt := 0;
  SetLength(RequiredWares,3);

  // Gold
  if (gHands[fOwner].Stats.GetHouseQty(ht_Metallurgists) = 0)
     AND (gHands[fOwner].Stats.GetWareBalance(wt_Gold) <= LACK_OF_GOLD) then
     AddWare(wt_Gold);
  // Gold ore
  if ( gHands[fOwner].Stats.GetHouseQty(ht_GoldMine) < gHands[fOwner].Stats.GetHouseQty(ht_Metallurgists) )
    AND ( gHands[fOwner].Stats.GetWareBalance(wt_Gold) < MIN_GOLD_AMOUNT )
    AND ( gHands[fOwner].Stats.GetWareBalance(wt_GoldOre) < MIN_GOLD_AMOUNT ) then
    AddWare(wt_GoldOre);
  // Coal
  if ( gHands[fOwner].Stats.GetHouseQty(ht_CoalMine) < (gHands[fOwner].Stats.GetHouseQty(ht_Metallurgists) + gHands[fOwner].Stats.GetHouseQty(ht_IronSmithy) + gHands[fOwner].Stats.GetHouseQty(ht_WeaponSmithy) + gHands[fOwner].Stats.GetHouseQty(ht_ArmorSmithy)) )
    AND ( gHands[fOwner].Stats.GetWareBalance(wt_Coal) < MIN_GOLD_AMOUNT ) then
    AddWare(wt_Coal);
  // Stone
  if (gHands[fOwner].Stats.GetWareBalance(wt_Gold) < LACK_OF_STONE)
    AND (gHands[fOwner].Stats.GetHouseQty(ht_Quary) = 0) then
    AddWare(wt_Stone);

  if RequiedCnt = 0 then
    Exit;

  AvaiableCnt := 0;
  SetLength(AvaiableWares, RequiedCnt);
  for L := Low(SOLD_ORDER) to High(SOLD_ORDER) do
    if gHands[fOwner].Stats.GetWareBalance( SOLD_ORDER[L] ) > SELL_LIMIT then
    begin
      if L >= RequiedCnt then
         break;
      AddWare(SOLD_ORDER[L], False);
    end;

  for L := 0 to RequiedCnt do
   if L < AvaiableCnt then
     TryBuyItem(AvaiableWares[L], RequiredWares[L])
   else
     break;
end;


procedure TKMCityManagement.CheckStoreWares();
var
  I: Integer;
  S: TKMHouseStore;
begin
  //Iterate through all Stores and block certain wares to reduce serf usage
  for I := 0 to gHands[fOwner].Houses.Count - 1 do
    if (gHands[fOwner].Houses[I].HouseType = ht_Store)
      AND gHands[fOwner].Houses[I].IsComplete
      AND not gHands[fOwner].Houses[I].IsDestroyed then
    begin
      S := TKMHouseStore(gHands[fOwner].Houses[I]);

      // Materials
      //S.NotAcceptFlag[wt_Trunk] := gHands[fOwner].Stats.GetWareBalance(wt_Trunk) > 30; // Trunk cannot be blocked because of forest cleaning
      S.NotAcceptFlag[wt_Wood] := S.CheckResIn(wt_Wood) > gHands[fOwner].Stats.GetUnitQty(ut_Worker);
      S.NotAcceptFlag[wt_Stone] := S.CheckResIn(wt_Stone) > gHands[fOwner].Stats.GetUnitQty(ut_Worker);
      //S.NotAcceptFlag[wt_Gold] := S.CheckResIn(wt_Gold) > 50; // Everyone needs as much gold as possible

      // Food - don't store food when we have enought (it will cause trafic before storehouse)
      S.NotAcceptFlag[wt_Wine] := gHands[fOwner].Stats.GetWareBalance(wt_Wine)  > 100;
      S.NotAcceptFlag[wt_Sausages] := gHands[fOwner].Stats.GetWareBalance(wt_Sausages) > 100;
      S.NotAcceptFlag[wt_Bread] := gHands[fOwner].Stats.GetWareBalance(wt_Bread) > 100;
      S.NotAcceptFlag[wt_Fish] := gHands[fOwner].Stats.GetWareBalance(wt_Fish) > 100;

      // Others
      S.NotAcceptFlag[wt_GoldOre] := gHands[fOwner].Stats.GetHouseQty(ht_Metallurgists) > 0;
      S.NotAcceptFlag[wt_IronOre] := gHands[fOwner].Stats.GetHouseQty(ht_IronSmithy) > 0;
      S.NotAcceptFlag[wt_Coal] := gHands[fOwner].Stats.GetHouseQty(ht_Metallurgists) +
                                  gHands[fOwner].Stats.GetHouseQty(ht_IronSmithy) > 0;
      S.NotAcceptFlag[wt_Steel] := gHands[fOwner].Stats.GetHouseQty(ht_WeaponSmithy) +
                                   gHands[fOwner].Stats.GetHouseQty(ht_ArmorSmithy) > 0;
      S.NotAcceptFlag[wt_Corn] := gHands[fOwner].Stats.GetHouseQty(ht_Mill) +
                                  gHands[fOwner].Stats.GetHouseQty(ht_Swine) +
                                  gHands[fOwner].Stats.GetHouseQty(ht_Stables) > 0;
      S.NotAcceptFlag[wt_Leather] := gHands[fOwner].Stats.GetHouseQty(ht_ArmorWorkshop) > 0;
      S.NotAcceptFlag[wt_Flour] := gHands[fOwner].Stats.GetHouseQty(ht_Bakery) > 0;
      //Pigs and skin cannot be blocked since if swinefarm is full of one it stops working (blocks other)
      //S.NotAcceptFlag[wt_Skin] := gHands[fOwner].Stats.GetHouseQty(ht_Tannery) > 0;
      //S.NotAcceptFlag[wt_Pig] := gHands[fOwner].Stats.GetHouseQty(ht_Butchers) > 0;
    end;
end;


//Demolish any exhausted mines, they will be rebuilt if needed
procedure TKMCityManagement.CheckExhaustedMines();
var
  I: Integer;
  Loc: TKMPoint;
begin
  //Wait until resource is depleted and output is empty
  for I := 0 to gHands[fOwner].Houses.Count - 1 do
  if not gHands[fOwner].Houses[I].IsDestroyed
    AND gHands[fOwner].Houses[I].ResourceDepletedMsgIssued
    AND (gHands[fOwner].Houses[I].CheckResOut(wt_All) = 0) then
  begin
    // Remove avoid building around coal mine
    if (gHands[fOwner].Houses[I].HouseType = ht_CoalMine) then
    begin
      Loc := gHands[fOwner].Houses[I].Entrance;
      gAIFields.Influences.RemAvoidBuilding(KMRect(Loc.X-3, Loc.Y-3, Loc.X+4, Loc.Y+2));
    end;
    gHands[fOwner].Houses[I].DemolishHouse(fOwner);
  end;
end;


//Check if specific woodcutters are in Fell only mode
procedure TKMCityManagement.CheckWoodcutters();
var
  I, J: Integer;
  Houses: TKMHousesCollection;
  H: TKMPoint;
  W: TKMHouseWoodcutters;
begin
  {
  if Length(fWoodcuttersManagement) > 0 then
  begin
    Houses := gHands[fOwner].Houses;

    for J := 0 to Houses.Count - 1 do
      if (Houses[J].HouseType = ht_Woodcutters)
      and Houses[J].IsComplete
      and not Houses[J].IsDestroyed then
      begin
        H := Houses[J].GetPosition;
        I := 0;
        while I < Length(fWoodcuttersManagement) do
        begin
          if (H.X = fWoodcuttersManagement[I].Loc.X) AND (H.Y = fWoodcuttersManagement[I].Loc.Y) then
          begin
            W := TKMHouseWoodcutters(Houses[J]);
            W.CuttingPoint := fWoodcuttersManagement[I].ForestCenterPoint;
            W.ValidateCuttingPoint;
            if fWoodcuttersManagement[I].ChopOnly then
              W.WoodcutterMode := wcm_Chop;
            fWoodcuttersManagement[I] := fWoodcuttersManagement[ High(fWoodcuttersManagement) ];
            SetLength(fWoodcuttersManagement, Length(fWoodcuttersManagement) - 1);
            break;
          end;
          Inc(I);
        end;
      end;
  end;
  }
end;


procedure TKMCityManagement.CheckAutoRepair();
var I: Integer;
begin
  with gHands[fOwner] do
    if (HandType = hndComputer) then
      for I := 0 to Houses.Count - 1 do
        Houses[I].BuildingRepair := fSetup.AutoRepair;
end;

{
//Check that we have weapons ordered for production
procedure TKMCityManagement.CheckWeaponOrderCount;
const
  //Order weapons in portions to avoid overproduction of one ware over another
  //(e.g. Shields in armory until Leather is available)
  PORTIONS = 8;
var
  I,K: Integer;
  H: TKMHouse;
  ResOrder: Integer;
begin
  for I := 0 to gHands[fOwner].Houses.Count - 1 do
  begin
    H := gHands[fOwner].Houses[I];

    ResOrder := H.ResOrder[1] + H.ResOrder[2] + H.ResOrder[3] + H.ResOrder[4];

    if not H.IsDestroyed and (ResOrder = 0) then
    case H.HouseType of
      ht_ArmorSmithy:     for K := 1 to 4 do
                            if gRes.Houses[H.HouseType].ResOutput[K] = wt_MetalShield then
                              H.ResOrder[K] := Round(WarfareRatios[wt_MetalShield] * PORTIONS)
                            else
                            if gRes.Houses[H.HouseType].ResOutput[K] = wt_MetalArmor then
                              H.ResOrder[K] := Round(WarfareRatios[wt_MetalArmor] * PORTIONS);
      ht_ArmorWorkshop:   for K := 1 to 4 do
                            if gRes.Houses[H.HouseType].ResOutput[K] = wt_Shield then
                              H.ResOrder[K] := Round(WarfareRatios[wt_Shield] * PORTIONS)
                            else
                            if gRes.Houses[H.HouseType].ResOutput[K] = wt_Armor then
                              H.ResOrder[K] := Round(WarfareRatios[wt_Armor] * PORTIONS);
      ht_WeaponSmithy:    for K := 1 to 4 do
                            if gRes.Houses[H.HouseType].ResOutput[K] = wt_Sword then
                              H.ResOrder[K] := Round(WarfareRatios[wt_Sword] * PORTIONS)
                            else
                            if gRes.Houses[H.HouseType].ResOutput[K] = wt_Hallebard then
                              H.ResOrder[K] := Round(WarfareRatios[wt_Hallebard] * PORTIONS)
                            else
                            if gRes.Houses[H.HouseType].ResOutput[K] = wt_Arbalet then
                              H.ResOrder[K] := Round(WarfareRatios[wt_Arbalet] * PORTIONS);
      ht_WeaponWorkshop:  for K := 1 to 4 do
                            if gRes.Houses[H.HouseType].ResOutput[K] = wt_Axe then
                              H.ResOrder[K] := Round(WarfareRatios[wt_Axe] * PORTIONS)
                            else
                            if gRes.Houses[H.HouseType].ResOutput[K] = wt_Pike then
                              H.ResOrder[K] := Round(WarfareRatios[wt_Pike] * PORTIONS)
                            else
                            if gRes.Houses[H.HouseType].ResOutput[K] = wt_Bow then
                              H.ResOrder[K] := Round(WarfareRatios[wt_Bow] * PORTIONS);
    end;
  end;
end;



//Tell Mayor what proportions of army is needed
//Input values are normalized
procedure TKMCityManagement.SetArmyDemand(aFootmen, aPikemen, aHorsemen, aArchers: Single);

  function IsIronProduced: Boolean;
  begin
    Result := (  gHands[fOwner].Stats.GetHouseQty(ht_IronMine)
               + gHands[fOwner].Stats.GetHouseWip(ht_IronMine)
               + gHands[fOwner].Stats.GetHousePlans(ht_IronMine)) > 0;
  end;

  function GroupBlocked(aGT: TGroupType; aIron: Boolean): Boolean;
  begin
    if aIron then
      case aGT of
        gt_Melee:     Result := gHands[fOwner].Locks.UnitBlocked[ut_Swordsman];
        gt_AntiHorse: Result := gHands[fOwner].Locks.UnitBlocked[ut_Hallebardman];
        gt_Ranged:    Result := gHands[fOwner].Locks.UnitBlocked[ut_Arbaletman];
        gt_Mounted:   Result := gHands[fOwner].Locks.UnitBlocked[ut_Cavalry];
        else          Result := True;
      end
    else
      case aGT of
        gt_Melee:     Result := gHands[fOwner].Locks.UnitBlocked[ut_Militia] and
                                gHands[fOwner].Locks.UnitBlocked[ut_AxeFighter];
        gt_AntiHorse: Result := gHands[fOwner].Locks.UnitBlocked[ut_Pikeman];
        gt_Ranged:    Result := gHands[fOwner].Locks.UnitBlocked[ut_Bowman];
        gt_Mounted:   Result := gHands[fOwner].Locks.UnitBlocked[ut_HorseScout];
        else          Result := True;
      end;
  end;

  function GetUnitRatio(aUT: TUnitType): Byte;
  begin
    if gHands[fOwner].Locks.UnitBlocked[aUT] then
      Result := 0 //This warrior is blocked
    else
      if (fSetup.ArmyType = atIronAndLeather)
      and GroupBlocked(UnitGroups[aUT], not (aUT in WARRIORS_IRON)) then
        Result := 2 //In mixed army type, if our compliment is blocked we need to make double
      else
        Result := 1;
  end;

var
  Summ: Single;
  Footmen, Pikemen, Horsemen, Archers: Single;
  IronPerMin, LeatherPerMin: Single;
  WT: TWareType;
  WarfarePerMinute: TWarfareDemands;
begin
  Summ := aFootmen + aPikemen + aHorsemen + aArchers;
  if Summ = 0 then
  begin
    Footmen := 0;
    Pikemen := 0;
    Horsemen := 0;
    Archers := 0;
  end
  else
  begin
    Footmen := aFootmen / Summ;
    Pikemen := aPikemen / Summ;
    Horsemen := aHorsemen / Summ;
    Archers := aArchers / Summ;
  end;

  //Store ratios localy in Mayor to place weapon orders
  //Leather
  WarfareRatios[wt_Armor] :=      Footmen  * GetUnitRatio(ut_AxeFighter)
                                 + Horsemen * GetUnitRatio(ut_HorseScout)
                                 + Pikemen  * GetUnitRatio(ut_Pikeman)
                                 + Archers  * GetUnitRatio(ut_Bowman);
  WarfareRatios[wt_Shield] :=     Footmen  * GetUnitRatio(ut_AxeFighter)
                                 + Horsemen * GetUnitRatio(ut_HorseScout);
  WarfareRatios[wt_Axe] :=        Footmen  * Max(GetUnitRatio(ut_AxeFighter), GetUnitRatio(ut_Militia))
                                 + Horsemen * GetUnitRatio(ut_HorseScout);
  WarfareRatios[wt_Pike] :=       Pikemen  * GetUnitRatio(ut_Pikeman);
  WarfareRatios[wt_Bow] :=        Archers  * GetUnitRatio(ut_Bowman);
  //Iron
  WarfareRatios[wt_MetalArmor] := Footmen  * GetUnitRatio(ut_Swordsman)
                                 + Horsemen * GetUnitRatio(ut_Cavalry)
                                 + Pikemen  * GetUnitRatio(ut_Hallebardman)
                                 + Archers  * GetUnitRatio(ut_Arbaletman);
  WarfareRatios[wt_MetalShield] :=Footmen  * GetUnitRatio(ut_Swordsman)
                                 + Horsemen * GetUnitRatio(ut_Cavalry);
  WarfareRatios[wt_Sword] :=      Footmen  * GetUnitRatio(ut_Swordsman)
                                 + Horsemen * GetUnitRatio(ut_Cavalry);
  WarfareRatios[wt_Hallebard] :=  Pikemen  * GetUnitRatio(ut_Hallebardman);
  WarfareRatios[wt_Arbalet] :=    Archers  * GetUnitRatio(ut_Arbaletman);

  WarfareRatios[wt_Horse] := Horsemen * (GetUnitRatio(ut_Cavalry) + GetUnitRatio(ut_HorseScout));

  //How many warriors we would need to equip per-minute
  IronPerMin := fSetup.WarriorsPerMinute(atIron);
  LeatherPerMin := fSetup.WarriorsPerMinute(atLeather);

  //If the AI is meant to make both but runs out, we must make it up with leather
  if (fSetup.ArmyType = atIronAndLeather) and not IsIronProduced then
    LeatherPerMin := LeatherPerMin + IronPerMin; //Once iron runs out start making leather to replace it

  //Make only iron first then if it runs out make leather
  if (fSetup.ArmyType = atIronThenLeather) and IsIronProduced then
    LeatherPerMin := 0; //Don't make leather until the iron runs out

  for WT := WEAPON_MIN to WEAPON_MAX do
    if WT in WARFARE_IRON then
      WarfarePerMinute[WT] := WarfareRatios[WT] * IronPerMin
    else
      WarfarePerMinute[WT] := WarfareRatios[WT] * LeatherPerMin;

  //Horses require separate calculation
  WarfarePerMinute[wt_Horse] := Horsemen * (  GetUnitRatio(ut_Cavalry) * IronPerMin
                                            + GetUnitRatio(ut_HorseScout) * LeatherPerMin);

  //Update warfare needs accordingly
  fBalance.SetArmyDemand(WarfarePerMinute);
end;













procedure TKMCityManagement.CheckHouseCount;
var
  P: TKMHand;

  function MaxPlansForTowers: Integer;
  begin
    Result := GetMaxPlans;
    //Once there are 2 towers wip then allow balance to build something
    if (fBalance.Peek <> ht_None) and (P.Stats.GetHouseWip(ht_WatchTower) >= 2) then
      Result := Result - 1;
    Result := Max(1, Result);
  end;

var
  count: Byte;
  H: THouseType;
begin
  P := gHands[fOwner];

  //Try to express needs in terms of Balance = Production - Demand
  fBalance.Refresh;

  //Peek - see if we can build this house
  //Take - take this house into building
  //Reject - we can't build this house (that could affect other houses in queue)

  //Build towers if village is done, or peacetime is nearly over
  if P.Locks.HouseCanBuild(ht_WatchTower) then
    if ((fBalance.Peek = ht_None) and (P.Stats.GetHouseWip(ht_Any) = 0)) //Finished building
    or ((gGame.GameOptions.Peacetime <> 0) and gGame.CheckTime(600 * Max(0, gGame.GameOptions.Peacetime - 15))) then
      PlanDefenceTowers;

  if fDefenceTowersPlanned then
    while (fDefenceTowers.Count > 0) and (P.Stats.GetHouseWip(ht_Any) < MaxPlansForTowers) do
      TryBuildDefenceTower;

  count := GetMaxPlans;
  while count > 0 do
  begin
    H := fBalance.Peek;

    //There are no more suggestions
    if H = ht_None then
      Break;

    // Gold as soon as possible
    if (P.Stats.GetWareBalance(wt_Gold) < LACK_OF_GOLD + 5)
      AND (P.Stats.GetHouseQty(ht_Metallurgists) = 0)
      AND not (H in [ht_GoldMine, ht_Metallurgists, ht_CoalMine]) then
    begin
      fBalance.Reject;
      Continue;
    end;

    //See if we can build that
    if TryBuildHouse(H) then
    begin
      Dec(count, 1);
      fBalance.Take;
      fBalance.Refresh; //Balance will be changed by the construction of this house
    end
    else
      fBalance.Reject;
  end;

  //Check if we need to demolish depleted houses
  CheckExhaustedMines;

  //Check finished woodcuters to switch them into Fell only mode
  CheckWoodcutters;

  //Verify all plans are being connected with roads
  CheckHousePlans;

  //Try trade when we have not enought resources
  CheckMarketplaces;
end;








procedure TKMCityManagement.CheckArmyDemand;
var Footmen, Pikemen, Horsemen, Archers: Integer;
begin
  gHands[fOwner].AI.General.DefencePositions.GetArmyDemand(Footmen, Pikemen, Horsemen, Archers);
  SetArmyDemand(Footmen, Pikemen, Horsemen, Archers);
end;




procedure TKMCityManagement.CheckAutoRepair;
var I: Integer;
begin
  with gHands[fOwner] do
    if HandType = hndComputer then
      for I := 0 to Houses.Count - 1 do
        Houses[I].BuildingRepair := fSetup.AutoRepair;
end;


function TKMCityManagement.BalanceText: UnicodeString;
begin
  Result := fBalance.BalanceText;
end;


procedure TKMCityManagement.UpdateState(aTick: Cardinal);
begin
  //Checking mod result against MAX_HANDS causes first update to happen ASAP
  if (aTick + Byte(fOwner)) mod (MAX_HANDS * 10) <> MAX_HANDS then Exit;

  CheckAutoRepair;

  //Train new units (citizens, serfs, workers and recruits) if needed
  CheckUnitCount;

  CheckArmyDemand;
  CheckWeaponOrderCount;

  if fSetup.AutoBuild then
  begin
    CheckHouseCount;

    //Manage wares ratios and block stone to Store
    CheckWareFlow;

    //Build more roads if necessary
    CheckRoadsCount;
  end;
end;
 //}



end.
