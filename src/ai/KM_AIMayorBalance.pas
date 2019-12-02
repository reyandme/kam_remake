unit KM_AIMayorBalance;
{$I KaM_Remake.inc}
interface
uses
  KM_ResWares, KM_ResHouses,
  KM_CommonClasses, KM_Defaults;

type
  //MayorBalance is a cluster of functions that choose optimal houses to build

  // Calculate various demands and save intermediate numbers in case we need them
  // in determing what exactly to build to satisfy demand the best
  // Production is how much of this resource gets made each minute
  //  - we evaluate each links theoretical production of end resource (f.e. 1 Corn = 3/5 Sausages)
  //  - in chain production the speed is limited by slowest link
  // todo: - resource in reserve adds to each production rate a fraction
  // Consumption is how much gets consumed
  // Balance = Production - Consumption;

  TKMCoreBalance = record
    StoreBalance, SchoolBalance, InnBalance, BarracksBalance, TowerBalance: Single;
    Balance: Single; //Resulting balance
  end;
  TKMMaterialsBalance = record
    WoodcutTheory, SawmillTheory: Single;
    WoodcutReserve, SawmillReserve: Single;
    StoneReserve: Single;
    StoneProduction, WoodProduction: Single;
    StoneBalance, WoodBalance: Single;
    Balance: Single; //Resulting balance
  end;
  TKMWareBalanceGold = record
    CoalTheory, GoldOreTheory, GoldTheory: Single;
    Production: Single; //How much do we produce
    Consumption: Single; //How much is used
    Reserve: Single; //
    Balance: Single; //Resulting balance
  end;
  TKMWareBalanceFood = record
    Bread: record
      FarmTheory, MillTheory, BakeryTheory: Single;
    end;
    Sausages: record
      FarmTheory, SwineTheory, ButchersTheory: Single;
    end;
    BreadProduction, SausagesProduction, WineProduction, FishProduction: Single;
    Production: Single; //How much food do we produce
    Consumption: Single; //How much food do we use
    Reserve: Single;
    Balance: Single; //Resulting balance
  end;
  TKMWareBalanceWarfare = record
    SteelWeapon: record
      CoalTheory, IronTheory, SteelTheory, SmithyTheory: Single;
    end;
    SteelArmor: record
      CoalTheory, IronTheory, SteelTheory, SmithyTheory: Single;
    end;
    WoodWeapon: record
      TrunkTheory, WoodTheory, WorkshopTheory: Single;
    end;
    LeatherArmor: record
      TrunkTheory, WoodTheory: Single; //Shields
      FarmTheory, SwineTheory, TanneryTheory: Single; //Armor
      WorkshopTheory: Single;
    end;
    Horse: record
      FarmTheory, StablesTheory: Single;
    end;

    //Ratios at which warfare should be produced in workshops/smithies
    OrderRatio: array[WEAPON_MIN..WEAPON_MAX] of Single;

    Warfare: array [WARFARE_MIN..WARFARE_MAX] of record
      Production, Demand, Balance: Single;
    end;

    Balance: Single; //Resulting balance
  end;

  TWarfareDemands = array[WARFARE_MIN..WARFARE_MAX] of Single;

type
  TKMayorBalance = class
  private
    fOwner: TKMHandID;

    fAdvice: array of TKMHouseType;

    //The following are recalculated before each use, so they don't need saving
    fCore: TKMCoreBalance;
    fMaterials: TKMMaterialsBalance;
    fGold: TKMWareBalanceGold;
    fFood: TKMWareBalanceFood;
    fWarfare: TKMWareBalanceWarfare;

    //For debugging (doesn't need saving)
    fCoreText: UnicodeString;
    fMaterialsText: UnicodeString;
    fGoldText: UnicodeString;
    fFoodText: UnicodeString;
    fWarfareText: UnicodeString;
    fAdviceText: UnicodeString;

    function WeaponUsed(aWare: TKMWareType): Boolean;
    function AdviceContains(aHouse: TKMHouseType): Boolean;

    procedure AppendCore;
    procedure AppendMaterials;
    procedure AppendGold;
    procedure AppendFood;
    procedure AppendWeaponry;

    procedure Append(aHouse: TKMHouseType; aCount: Byte = 1);
    function HouseCount(aHouse: TKMHouseType): Integer;

    procedure DistributeCorn;
    procedure DistributeCoal;
    procedure DistributeSteel;
    procedure DistributeWood;

    procedure UpdateBalanceGold;
    procedure UpdateBalanceCore;
    procedure UpdateBalanceMaterials;
    procedure UpdateBalanceFood;
    procedure UpdateBalanceLeather;
    procedure UpdateBalanceIron;
    procedure UpdateBalanceWarfare;
  public
    GoldNeed: Single; //How much gold the town needs per minute (may change over time)
    StoneNeed: Single; //How much building materials do we need for city development
    WoodNeed: Single; //How much building materials do we need for city development
    constructor Create(aPlayer: TKMHandID);

    procedure OwnerUpdate(aPlayer: TKMHandID);
    procedure Refresh;
    function Peek: TKMHouseType;
    procedure Take;
    procedure Reject;
    procedure SetArmyDemand(aNeeds: TWarfareDemands);
    function BalanceText: UnicodeString;

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
  end;


implementation
uses
  SysUtils, StrUtils, Math, KromUtils,
  KM_Hand, KM_HandsCollection, KM_Resource;


{ TKMayorBalance }
constructor TKMayorBalance.Create(aPlayer: TKMHandID);
begin
  inherited Create;
  fOwner := aPlayer;

  GoldNeed := 1;
  StoneNeed := 10;
  WoodNeed := 3.5;
end;


//How many houses of certain type we have (assume all wip houses will be finished)
function TKMayorBalance.HouseCount(aHouse: TKMHouseType): Integer;
begin
  Result := gHands[fOwner].Stats.GetHouseTotal(aHouse);
end;


function TKMayorBalance.WeaponUsed(aWare: TKMWareType): Boolean;
begin
  case gHands[fOwner].AI.Setup.ArmyType of
    atLeather:         Result := aWare in [wtShield, wtArmor, wtAxe, wtPike, wtBow, wtHorse];
    atIron:            Result := aWare in [wtMetalShield, wtMetalArmor, wtSword, wtHallebard, wtArbalet, wtHorse];
    atIronAndLeather:  Result := True;
    atIronThenLeather: Result := True;
    else               Result := False;
  end;
end;


function TKMayorBalance.AdviceContains(aHouse: TKMHouseType): Boolean;
var I: Integer;
begin
  Result := False;
  for I := 0 to Length(fAdvice) - 1 do
    if fAdvice[I] = aHouse then
    begin
      Result := True;
      Exit;
    end;
end;


procedure TKMayorBalance.Append(aHouse: TKMHouseType; aCount: Byte = 1);
var
  I: Integer;
begin
  //ArmorWorkshop is needed to produce Shields before Tannery is made
  //Handle in generic way since in custom missions it might apply to other houses
  if not gHands[fOwner].Locks.HouseCanBuild(aHouse)
  and (gRes.Houses[aHouse].ReleasedBy <> htNone) //Storehouse might be blocked
  and (gHands[fOwner].Stats.GetHouseTotal(gRes.Houses[aHouse].ReleasedBy) = 0) then
    Append(gRes.Houses[aHouse].ReleasedBy);

  //If the same house is asked for independently then don't add it again, since f.e. gold and iron
  //might both ask for a coal mine, when only 1 extra is needed.
  for I := 0 to Length(fAdvice) - 1 do
    if fAdvice[I] = aHouse then
    begin
      Dec(aCount);
      if aCount = 0 then Exit;
    end;

  SetLength(fAdvice, Length(fAdvice) + aCount);
  for I := Length(fAdvice) - aCount to Length(fAdvice) - 1 do
    fAdvice[I] := aHouse;
end;


//These houses are core for town development
procedure TKMayorBalance.AppendCore;
begin
  with fCore do
  case PickMin([0, StoreBalance, SchoolBalance, InnBalance, BarracksBalance, TowerBalance]) of
    0: ;
    1: Append(htStore);
    2: Append(htSchool);
    3: Append(htInn);
    4: Append(htBarracks);
    5: Append(htWatchTower);
  end;
end;


procedure TKMayorBalance.AppendMaterials;
var
  List: array [0..2] of Single;
begin
  List[0] := fMaterials.StoneBalance;
  List[1] := fMaterials.WoodcutTheory - WoodNeed;
  List[2] := fMaterials.SawmillTheory - WoodNeed;

  repeat
    //Do not build extra houses if we are low on building materials
    if (gHands[fOwner].Stats.GetHouseQty(htQuary) = 0)
    and(gHands[fOwner].Stats.GetWareBalance(wtStone)
        - gHands[fOwner].BuildList.FieldworksList.FieldCount(ftRoad) < 40)
    and (AdviceContains(htQuary) or (gHands[fOwner].Stats.GetHouseWip(htQuary) > 1)) then
      Break;

    case PickMin([0, List[0], List[1], List[2]]) of
      0:  Break;
      1:  begin
            Append(htQuary);
            List[0] := List[0] + ProductionRate[wtStone];
          end;
      2:  begin
            Append(htWoodcutters);
            List[1] := List[1] + ProductionRate[wtTrunk] * 2; //Each trunk brings 2 wood
          end;
      3:  begin
            Append(htSawmill);
            List[2] := List[2] + ProductionRate[wtWood];
          end;
    end;

{  if (fPlayers[fOwner].Stats.GetHouseQty(htQuary) = 0)
  and (fPlayers[fOwner].Stats.GetWareBalance(wtStone) < 40) then
  while not (Result in [htNone, htSchool, htQuary]) do
  begin
    Take;
    Result := Peek;
  end;}
  
  until False;
end;


//Increase Gold production
procedure TKMayorBalance.AppendGold;
begin
  //If all 3 shares 0 we whould pick in that order Gold > Coal > Metallurgists
  with fGold do
  if Balance < 0 then
  case PickMin([GoldOreTheory, CoalTheory, GoldTheory]) of
    0:  Append(htGoldMine);
    1:  Append(htCoalMine, 2);
    2:  Append(htMetallurgists);
  end;
end;


procedure TKMayorBalance.AppendFood;
var SkipSausage: Boolean;
begin
  //When making iron only don't make sausages, they're inefficient if you don't use skins
  SkipSausage := gHands[fOwner].AI.Setup.ArmyType = atIron;
  
  //Pick smallest production and increase it
  //If all 3 shares 0 we whould pick Sausages first to ensure Leather supply
  with fFood do
  if Balance < 0 then
  case PickMin([SausagesProduction + 10000*Byte(SkipSausage), BreadProduction, WineProduction]) of
    0:  with Sausages do
        case PickMin([FarmTheory, SwineTheory, ButchersTheory]) of
          0:  Append(htFarm, 2);
          1:  Append(htSwine);
          2:  Append(htButchers);
        end;
    1:  with Bread do
        case PickMin([FarmTheory, MillTheory, BakeryTheory]) of
          0:  Append(htFarm, 2);
          1:  Append(htMill);
          2:  Append(htBakery);
        end;
    2:  Append(htWineyard);
  end;
end;


procedure TKMayorBalance.AppendWeaponry;
const
  MAX_WEAPON_TYPES = Byte(WARFARE_MAX) - Byte(WARFARE_MIN) + 1;
var
  I, TmpWare: TKMWareType;
  Tmp: Single;
  WeaponsCount, J, K: Integer;
  Weapons: array[0..MAX_WEAPON_TYPES-1] of TKMWareType;
  WeaponSatisfactions: array[0..MAX_WEAPON_TYPES-1] of Single;
begin
  //List all the required weapons
  J := 0;
  for I := WARFARE_MIN to WARFARE_MAX do
    if WeaponUsed(I) and (fWarfare.Warfare[I].Demand > 0)
    and (fWarfare.Warfare[I].Production < fWarfare.Warfare[I].Demand) then
    begin
      Weapons[J] := I;
      //Calculate weapon production satisfaction rate (0..1)
      WeaponSatisfactions[J] := fWarfare.Warfare[I].Production / Max(0.01,fWarfare.Warfare[I].Demand);
      Inc(J);
    end;
  WeaponsCount := J;

  //Sort (since there's not many items bubble sort is okay for now)
  for J := WeaponsCount-1 downto 0 do
    for K := WeaponsCount-1 downto 0 do
      if WeaponSatisfactions[J] > WeaponSatisfactions[K] then
      begin
        Tmp := WeaponSatisfactions[J];
        WeaponSatisfactions[J] := WeaponSatisfactions[K];
        WeaponSatisfactions[K] := Tmp;

        TmpWare := Weapons[J];
        Weapons[J] := Weapons[K];
        Weapons[K] := TmpWare;
      end;

  for J := 0 to WeaponsCount-1 do
  case Weapons[J] of
    wtMetalShield,
    wtMetalArmor:  with fWarfare.SteelArmor do
                    case PickMin([CoalTheory, IronTheory, SteelTheory, SmithyTheory]) of
                      0: Append(htCoalMine);
                      1: Append(htIronMine);
                      2: Append(htIronSmithy);
                      3: Append(htArmorSmithy);
                    end;
    wtSword,
    wtHallebard,
    wtArbalet:     with fWarfare.SteelWeapon do
                    case PickMin([CoalTheory, IronTheory, SteelTheory, SmithyTheory]) of
                      0: Append(htCoalMine);
                      1: Append(htIronMine);
                      2: Append(htIronSmithy);
                      3: Append(htWeaponSmithy);
                    end;
    wtShield:      with fWarfare.LeatherArmor do
                    case PickMin([TrunkTheory, WoodTheory, WorkshopTheory*fWarfare.OrderRatio[wtShield]]) of
                      0: Append(htWoodcutters);
                      1: Append(htSawmill);
                      2: Append(htArmorWorkshop);
                    end;
    wtArmor:       with fWarfare.LeatherArmor do
                    case PickMin([FarmTheory, SwineTheory, TanneryTheory, WorkshopTheory*fWarfare.OrderRatio[wtArmor]]) of
                      0: Append(htFarm);
                      1: Append(htSwine);
                      2: Append(htTannery);
                      3: Append(htArmorWorkshop);
                    end;
    wtAxe,
    wtPike,
    wtBow:         with fWarfare.WoodWeapon do
                    case PickMin([TrunkTheory, WoodTheory, WorkshopTheory]) of
                      0: Append(htWoodcutters);
                      1: Append(htSawmill);
                      2: Append(htWeaponWorkshop);
                    end;
    wtHorse:       with fWarfare.Horse do
                    case PickMin([FarmTheory, StablesTheory]) of
                      0: Append(htFarm);
                      1: Append(htStables);
                    end;
  end;
end;


procedure TKMayorBalance.OwnerUpdate(aPlayer: TKMHandID);
begin
  fOwner := aPlayer;
end;


procedure TKMayorBalance.DistributeCoal;
var
  CoalProductionRate, CoalConsumptionRate, CoalReserve: Single;
  GoldPerMin, SteelPerMin, WeaponsPerMin, ArmorPerMin: Single;
  ExtraCoal, DeficitCoal: Single;
begin
  with fWarfare do
  begin
    //Theoretical gold production
    GoldPerMin := Min(HouseCount(htGoldMine) * ProductionRate[wtGoldOre] * 2,
                      HouseCount(htMetallurgists) * ProductionRate[wtGold]);

    //Theoretical steel production
    SteelPerMin := Min(HouseCount(htIronMine) * ProductionRate[wtIronOre],
                       HouseCount(htIronSmithy) * ProductionRate[wtSteel]);

    //Theoretical weapon production
    WeaponsPerMin := Min(HouseCount(htWeaponSmithy) * ProductionRate[wtSword],
                         Warfare[wtSword].Demand
                         + Warfare[wtHallebard].Demand
                         + Warfare[wtArbalet].Demand);

    //Theoretical armor production
    ArmorPerMin := Min(HouseCount(htArmorSmithy) * ProductionRate[wtMetalArmor],
                       Warfare[wtMetalShield].Demand + Warfare[wtMetalArmor].Demand);

    //Current coal consumption
    CoalConsumptionRate := GoldPerMin/2 + SteelPerMin + WeaponsPerMin + ArmorPerMin;
  end;
  CoalReserve := gHands[fOwner].Stats.GetWareBalance(wtCoal) / Max(1,CoalConsumptionRate);
  CoalProductionRate := HouseCount(htCoalMine) * ProductionRate[wtCoal] + Max(CoalReserve - 30, 0);

  if CoalProductionRate >= CoalConsumptionRate then
  begin
    //Let every industry think the extra belongs to it
    ExtraCoal := CoalProductionRate - CoalConsumptionRate;
    fGold.CoalTheory := GoldPerMin + ExtraCoal * 2;
    fWarfare.SteelWeapon.CoalTheory := WeaponsPerMin + ExtraCoal / 2; //Takes 2 coal to make each weapon
    fWarfare.SteelArmor.CoalTheory := ArmorPerMin + ExtraCoal / 2; //Takes 2 coal to make each armor
  end
  else
  begin
    //Sharing proportionaly doesn't work since closer houses get more.
    //Let every industry think the deficit belongs to it
    DeficitCoal := CoalConsumptionRate - CoalProductionRate;
    fGold.CoalTheory := Max(0, GoldPerMin - DeficitCoal * 2); //Each coal makes 2 gold
    fWarfare.SteelWeapon.CoalTheory := Max(0, WeaponsPerMin - DeficitCoal);
    fWarfare.SteelArmor.CoalTheory := Max(0, ArmorPerMin - DeficitCoal);
  end;
end;


procedure TKMayorBalance.DistributeSteel;
var
  WeaponsPerMin, ArmorPerMin: Single;

  SteelPerMin, SteelConsumptionRate: Single;
  ExtraSteel, DeficitSteel: Single;

  IronPerMin, IronProduction, IronConsumption, IronReserve: Single;
  ExtraIron, RateIron: Single;
begin
  SteelPerMin := HouseCount(htIronSmithy) * ProductionRate[wtSteel];
  IronPerMin := HouseCount(htIronMine) * ProductionRate[wtIronOre];

  with fWarfare do
  begin
    //Theoretical weapon production
    WeaponsPerMin := Min(HouseCount(htWeaponSmithy) * ProductionRate[wtSword],
                      Warfare[wtSword].Demand
                      + Warfare[wtHallebard].Demand
                      + Warfare[wtArbalet].Demand);

    //Theoretical armor production
    ArmorPerMin := Min(HouseCount(htArmorSmithy) * ProductionRate[wtMetalArmor],
                      Warfare[wtMetalArmor].Demand
                      + Warfare[wtMetalShield].Demand);
  end;

  //Current steel consumption
  SteelConsumptionRate := WeaponsPerMin + ArmorPerMin;

  if SteelPerMin >= SteelConsumptionRate then
  begin
    //Let every industry think the extra belongs to it
    ExtraSteel := SteelPerMin - SteelConsumptionRate;
    fWarfare.SteelWeapon.SteelTheory := WeaponsPerMin + ExtraSteel;
    fWarfare.SteelArmor.SteelTheory := ArmorPerMin + ExtraSteel;
  end
  else
  begin
    //Sharing proportionaly doesn't work since closer houses get more.
    //Let every industry think the deficit belongs to it
    DeficitSteel := SteelConsumptionRate - SteelPerMin;
    fWarfare.SteelWeapon.SteelTheory := Max(0, WeaponsPerMin - DeficitSteel);
    fWarfare.SteelArmor.SteelTheory := Max(0, ArmorPerMin - DeficitSteel);
  end;

  IronConsumption := SteelConsumptionRate; //Any not being used for steel is excess
  IronReserve := gHands[fOwner].Stats.GetWareBalance(wtIronOre) / Max(1,IronConsumption);
  IronProduction := IronPerMin + Max(IronReserve - 30, 0);

  if IronProduction >= IronConsumption then
  begin
    //Let every industry think the extra belongs to it
    ExtraIron := IronProduction - IronConsumption;
    fWarfare.SteelWeapon.IronTheory := WeaponsPerMin + ExtraIron;
    fWarfare.SteelArmor.IronTheory := ArmorPerMin + ExtraIron;
  end
  else
  begin
    //Share proportionaly
    RateIron := IronProduction / Max(1,IronConsumption);
    fWarfare.SteelWeapon.IronTheory := RateIron * IronPerMin;
    fWarfare.SteelArmor.IronTheory := RateIron * IronPerMin;
  end;
end;


procedure TKMayorBalance.DistributeWood;
const
  WEAP_COST = 2;
  WT = 2; //Wood from Trunk ratio
var
  TrunkPerMin, WoodPerMin: Single;
  WeaponsPerMin, ShieldsPerMin: Single;
  WoodProduction, WoodConsumption, WoodReserve: Single;
  TrunkProduction, TrunkConsumption, TrunkReserve: Single;
  ExtraWood, DeficitWood: Single;
  ExtraTrunk, DeficitTrunk: Single;
begin
  //Theoretical limit on Wood production
  TrunkPerMin := HouseCount(htWoodcutters) * ProductionRate[wtTrunk];
  WoodPerMin := HouseCount(htSawmill) * ProductionRate[wtWood];

  with fWarfare do
  begin
    //Theoretical weapon production
    WeaponsPerMin := Min(HouseCount(htWeaponWorkshop) * ProductionRate[wtAxe],
                      Warfare[wtAxe].Demand
                      + Warfare[wtPike].Demand
                      + Warfare[wtBow].Demand);

    //Min from available production (shields are only part of workshops orders) and demand
    ShieldsPerMin := Min(HouseCount(htArmorWorkshop) * OrderRatio[wtShield] * ProductionRate[wtShield],
                         Warfare[wtShield].Demand);

    //Current wood consumption
    WoodConsumption := WoodNeed + ShieldsPerMin + WeaponsPerMin * WEAP_COST;
    WoodReserve := gHands[fOwner].Stats.GetWareBalance(wtWood) / Max(1,WoodConsumption);
    WoodProduction := WoodPerMin + Max(WoodReserve - 30, 0);

    //Wood shares
    if WoodProduction >= WoodConsumption then
    begin
      //Let every industry think the extra belongs to it
      ExtraWood := WoodProduction - WoodConsumption;
      WoodWeapon.WoodTheory := WeaponsPerMin + ExtraWood / Max(1,WEAP_COST);
      LeatherArmor.WoodTheory := ShieldsPerMin + ExtraWood;
    end
    else
    begin
      //Sharing proportionaly doesn't work since closer houses get more.
      //Let every industry think the deficit belongs to it
      if (WoodConsumption > 0) and (WoodProduction > WoodNeed) then
      begin
        DeficitWood := WoodConsumption - WoodProduction;
        WoodWeapon.WoodTheory := Max(0, WeaponsPerMin - DeficitWood / Max(1,WEAP_COST));
        LeatherArmor.WoodTheory := Max(0, ShieldsPerMin - DeficitWood);
      end
      else
      begin
        WoodWeapon.WoodTheory := 0;
        LeatherArmor.WoodTheory := 0;
      end;
    end;

    TrunkConsumption := WoodPerMin / Max(1,WT);
    TrunkReserve := gHands[fOwner].Stats.GetWareBalance(wtTrunk) / Max(1,TrunkConsumption);
    TrunkProduction := TrunkPerMin + Max(TrunkReserve - 30, 0);

    //Trunk shares
    if TrunkProduction >= TrunkConsumption then
    begin
      //Let every industry think the extra belongs to it
      ExtraTrunk := TrunkProduction - TrunkConsumption;
      WoodWeapon.TrunkTheory := WeaponsPerMin + ExtraTrunk * WT / Max(1,WEAP_COST);
      LeatherArmor.TrunkTheory := ShieldsPerMin + ExtraTrunk * WT;
    end
    else
    begin
      //Sharing proportionaly doesn't work since closer houses get more.
      //Let every industry think the deficit belongs to it
      if TrunkConsumption <> 0 then
      begin
        DeficitTrunk := TrunkConsumption - TrunkProduction;
        WoodWeapon.TrunkTheory := Max(0, WeaponsPerMin - DeficitTrunk * WT / Max(1,WEAP_COST));
        LeatherArmor.TrunkTheory := Max(0, ShieldsPerMin - DeficitTrunk * WT);
      end
      else
      begin
        WoodWeapon.TrunkTheory := 0;
        LeatherArmor.TrunkTheory := 0;
      end;
    end;
  end;
end;


procedure TKMayorBalance.UpdateBalanceGold;
var GoldOreReserve: Single;
begin
  with fGold do
  begin
    //How much Gold do we need
    Consumption := GoldNeed + Byte(HouseCount(htBarracks) > 0) * gHands[fOwner].AI.Setup.WarriorsPerMinute;

    GoldOreReserve := gHands[fOwner].Stats.GetWareBalance(wtGoldOre) / Max(1,(2 * Consumption));

    //How much gold in theory we could get
    //CoalTheory - coal calculated separately
    GoldOreTheory := HouseCount(htGoldMine) * ProductionRate[wtGoldOre] * 2; //*2 since every Ore becomes 2 Gold
    GoldOreTheory := GoldOreTheory + Max(0, GoldOreReserve - 30);
    GoldTheory := HouseCount(htMetallurgists) * ProductionRate[wtGold];

    //Actual production is minimum of the above
    Production := Min(CoalTheory, GoldOreTheory, GoldTheory);

    //How much reserve do we have
    Reserve := gHands[fOwner].Stats.GetWareBalance(wtGold) / Max(1,Consumption);

    Balance := Production - Consumption + Max(Reserve - 30, 0);

    fGoldText := Format('%.2f Gold (%.2f - %.2f + %.2f)', [Balance, Production, Consumption, Reserve]);
  end;
end;


procedure TKMayorBalance.UpdateBalanceLeather;
begin
  with fWarfare do
  begin
    with WoodWeapon do
    begin
      //Trunk
      //Wood
      //All 3 produced at the same speed
      WorkshopTheory := HouseCount(htWeaponWorkshop) * ProductionRate[wtPike];

      Warfare[wtAxe].Production := Min(TrunkTheory, WoodTheory, WorkshopTheory) * OrderRatio[wtAxe];
      Warfare[wtPike].Production := Min(TrunkTheory, WoodTheory, WorkshopTheory) * OrderRatio[wtPike];
      Warfare[wtBow].Production := Min(TrunkTheory, WoodTheory, WorkshopTheory) * OrderRatio[wtBow];
    end;

    with LeatherArmor do
    begin
      //Trunk
      //Wood
      //FarmTheory calculated above
      SwineTheory := HouseCount(htSwine) * ProductionRate[wtSkin] * 2;
      TanneryTheory := HouseCount(htTannery) * ProductionRate[wtLeather];
      WorkshopTheory := HouseCount(htArmorWorkshop) * ProductionRate[wtArmor];

      Warfare[wtShield].Production := Min(TrunkTheory, WoodTheory, WorkshopTheory * OrderRatio[wtShield]);
      Warfare[wtArmor].Production := Min(Min(FarmTheory, SwineTheory), Min(TanneryTheory, WorkshopTheory * OrderRatio[wtArmor]));
    end;
  end;
end;


procedure TKMayorBalance.UpdateBalanceIron;
begin
  with fWarfare do
  begin
    //Weapon
    //Calculate how much Weapon each link could possibly produce
    with SteelWeapon do
    begin
      //Coal/steel/iron calculated above
      SmithyTheory := HouseCount(htWeaponSmithy) * ProductionRate[wtHallebard];

      //All 3 weapons are the same for now
      Warfare[wtSword].Production := Min(Min(CoalTheory, IronTheory), Min(SteelTheory, SmithyTheory)) * OrderRatio[wtSword];
      Warfare[wtHallebard].Production := Min(Min(CoalTheory, IronTheory), Min(SteelTheory, SmithyTheory)) * OrderRatio[wtHallebard];
      Warfare[wtArbalet].Production := Min(Min(CoalTheory, IronTheory), Min(SteelTheory, SmithyTheory)) * OrderRatio[wtArbalet];
    end;

    //Armor
    //Calculate how many Armor each link could possibly produce
    with SteelArmor do
    begin
      //Coal/steel/iron calculated above
      SmithyTheory := HouseCount(htArmorSmithy) * ProductionRate[wtMetalArmor];

      Warfare[wtMetalShield].Production := Min(Min(CoalTheory, IronTheory), Min(SteelTheory, SmithyTheory)) * OrderRatio[wtMetalShield];
      Warfare[wtMetalArmor].Production := Min(Min(CoalTheory, IronTheory), Min(SteelTheory, SmithyTheory)) * OrderRatio[wtMetalArmor];
    end;
  end;
end;


procedure TKMayorBalance.UpdateBalanceWarfare;
var
  I: TKMWareType;
  S: UnicodeString;
begin
  UpdateBalanceLeather;
  UpdateBalanceIron;

  with fWarfare do
  begin
    //Horse.FarmTheory calculated above
    Horse.StablesTheory := HouseCount(htStables) * ProductionRate[wtHorse];
    Warfare[wtHorse].Production := Min(Horse.FarmTheory, Horse.StablesTheory);

    for I := WARFARE_MIN to WARFARE_MAX do
      Warfare[I].Balance := Warfare[I].Production - Warfare[I].Demand;

    //Set Weaponry balance to the most required warfare kind
    Balance := MaxSingle;
    for I := WARFARE_MIN to WARFARE_MAX do
    if WeaponUsed(I) and (Warfare[I].Balance < Balance) then
      Balance := Warfare[I].Balance;

    S := Format('%.2f Weaponry: |', [Balance]);
    with fWarfare.LeatherArmor do
    begin
      S := S + Format('WoodShields: T%.1f : W%.1f : W%.1f|', [TrunkTheory, WoodTheory, WorkshopTheory*OrderRatio[wtShield]]);
      S := S + Format('LeatherArm: F%.1f : S%.1f : T%.1f : W%.1f|', [FarmTheory, SwineTheory, TanneryTheory, WorkshopTheory*OrderRatio[wtArmor]]);
    end;

    with fWarfare.WoodWeapon do
      S := S + Format('WoodWeap: T%.1f W%.1f W%.1f|', [TrunkTheory, WoodTheory, WorkshopTheory]);

    with fWarfare.SteelArmor do
      S := S + Format('SteelArmor: C%.1f : I%.1f : S%.1f : S%.1f|', [CoalTheory, IronTheory, SteelTheory, SmithyTheory]);

    with fWarfare.SteelWeapon do
      S := S + Format('SteelWeapon: C%.1f : I%.1f : S%.1f : S%.1f|', [CoalTheory, IronTheory, SteelTheory, SmithyTheory]);

    for I := WARFARE_MIN to WARFARE_MAX do
    if WeaponUsed(I) then
      S := S + Format('%s: %.2f - %.2f|', [gRes.Wares[I].Title,
                                                  Warfare[I].Production,
                                                  Warfare[I].Demand]);

    fWarfareText := S;
  end;
end;


procedure TKMayorBalance.UpdateBalanceCore;
var
  P: TKMHand;
begin
  P := gHands[fOwner];

  with fCore do
  begin
    //Balance = Available - Required + Reserve
    StoreBalance    := HouseCount(htStore)       - 1; //HouseCount(htAny) / 35;
    //Build 2 schools if we need to equip a lot of warriors per minute
    SchoolBalance   := HouseCount(htSchool)      - 1 - Byte((gHands[fOwner].Stats.GetHouseQty(htBarracks) > 0) and (gHands[fOwner].AI.Setup.WarriorsPerMinute > 2));
    InnBalance      := HouseCount(htInn)         - P.Stats.GetCitizensCount / 80;
    BarracksBalance := HouseCount(htBarracks)    - Byte(P.Stats.GetWarfareProduced > 0);
    TowerBalance    := HouseCount(htWatchTower)  - 1 * gHands[fOwner].Stats.GetHouseQty(htBarracks);

    Balance := Min([StoreBalance, SchoolBalance, InnBalance, BarracksBalance, TowerBalance]);
    fCoreText := Format
      ('%.2f Core: (Store %.2f, School %.2f, Inn %.2f, Barracks %.2f, Tower %.2f)',
      [Balance, StoreBalance, SchoolBalance, InnBalance, BarracksBalance, TowerBalance]);
  end;
end;


procedure TKMayorBalance.UpdateBalanceMaterials;
begin
  with fMaterials do
  begin
    //In some maps there is no stone so quarry is blocked
    if gHands[fOwner].Locks.HouseBlocked[htQuary] then
      StoneProduction := 99999
    else
    begin
      StoneReserve := gHands[fOwner].Stats.GetWareBalance(wtStone) / Max(0.001,StoneNeed);
      StoneProduction := HouseCount(htQuary) * ProductionRate[wtStone] + Max(StoneReserve - 30, 0);
    end;

    WoodcutReserve := gHands[fOwner].Stats.GetWareBalance(wtTrunk) * 2 / Max(0.001,WoodNeed);
    WoodcutTheory := HouseCount(htWoodcutters) * ProductionRate[wtTrunk] * 2 + Max(WoodcutReserve - 30, 0);

    SawmillReserve := gHands[fOwner].Stats.GetWareBalance(wtWood) / Max(0.001,WoodNeed);
    SawmillTheory := HouseCount(htSawmill) * ProductionRate[wtWood] + Max(SawmillReserve - 30, 0);
    WoodProduction := Min(WoodcutTheory, SawmillTheory);

    StoneBalance    := StoneProduction - StoneNeed;
    WoodBalance     := WoodProduction - WoodNeed;

    Balance := Min(StoneBalance, WoodBalance);
    fMaterialsText := Format('%.2f Materials: (Stone %.1f-%.1f, Wood (%.1f:%.1f)-%.1f)',
                             [Balance, StoneProduction, StoneNeed, WoodcutTheory, SawmillTheory, WoodNeed]);
  end;
end;


procedure TKMayorBalance.DistributeCorn;
const
  BEAST_COST = 4;
var
  CornProduction, CornConsumption, CornReserve: Single;
  FlourPerMin, PigPerMin, HorsePerMin: Single;
  CornExtra, CornDeficit: Single;
begin

  //With stable production rate we can assume consumption rate that would be required
  FlourPerMin := HouseCount(htMill) * ProductionRate[wtFlour];
  PigPerMin   := HouseCount(htSwine) * ProductionRate[wtPig] * BEAST_COST;
  HorsePerMin := HouseCount(htStables) * ProductionRate[wtHorse] * BEAST_COST;
  CornConsumption := FlourPerMin + PigPerMin + HorsePerMin;
  CornReserve := gHands[fOwner].Stats.GetWareBalance(wtCorn) / Max(CornConsumption,0.001);
  CornProduction := HouseCount(htFarm) * ProductionRate[wtCorn] + Max(CornReserve - 30, 0);

  if CornProduction >= CornConsumption then
  begin
    //Let every industry think the extra belongs to it
    CornExtra := CornProduction - CornConsumption;
    fFood.Bread.FarmTheory := (FlourPerMin + CornExtra) * 2;
    fFood.Sausages.FarmTheory := (PigPerMin + CornExtra) / BEAST_COST * 3;
    fWarfare.LeatherArmor.FarmTheory := (PigPerMin + CornExtra) / BEAST_COST * 2;
    fWarfare.Horse.FarmTheory := (HorsePerMin + CornExtra) / BEAST_COST;
  end
  else
  begin
    //Sharing proportionaly doesn't work since closer houses get more.
    //Let every industry think the deficit belongs to it
    CornDeficit := CornConsumption - CornProduction;
    fFood.Bread.FarmTheory := Max(0, (FlourPerMin - CornDeficit) * 2);
    fFood.Sausages.FarmTheory := Max(0, (PigPerMin - CornDeficit) / BEAST_COST * 3);
    fWarfare.LeatherArmor.FarmTheory := Max(0, (PigPerMin - CornDeficit) / BEAST_COST * 2);
    fWarfare.Horse.FarmTheory := Max(0, (HorsePerMin - CornDeficit) / BEAST_COST);
  end;
end;


procedure TKMayorBalance.UpdateBalanceFood;
var
  P: TKMHand;
  UT: TKMUnitType;
begin
  P := gHands[fOwner];

  with fFood do
  begin
    //Bread
    //Calculate how much bread each link could possibly produce
    //Bread.FarmTheory calculated above
    Bread.MillTheory := HouseCount(htMill) * ProductionRate[wtFlour] * 2;
    Bread.BakeryTheory := HouseCount(htBakery) * ProductionRate[wtBread];
    BreadProduction := Min(Bread.FarmTheory, Bread.MillTheory, Bread.BakeryTheory);

    //Sausages
    //Calculate how many sausages each link could possibly produce
    //Sausages.FarmTheory calculated above
    Sausages.SwineTheory := HouseCount(htSwine) * ProductionRate[wtPig] * 3;
    Sausages.ButchersTheory := HouseCount(htButchers) * ProductionRate[wtSausages];
    SausagesProduction := Min(Sausages.FarmTheory, Sausages.SwineTheory, Sausages.ButchersTheory);

    //Wine, Fish
    WineProduction := HouseCount(htWineyard) * ProductionRate[wtWine];
    FishProduction := HouseCount(htFisherHut) * ProductionRate[wtFish];

    //Count in "food units per minute"
    Production := BreadProduction * BREAD_RESTORE +
                  SausagesProduction * SAUSAGE_RESTORE +
                  WineProduction *  WINE_RESTORE +
                  FishProduction * FISH_RESTORE;

    Consumption := 0;

    for UT := CITIZEN_MIN to CITIZEN_MAX do
       Consumption := Consumption + P.Stats.GetUnitQty(UT) / 40; //On average unit needs to eat each 40min

    Consumption := Consumption * 1.2; //Otherwise not enough food is made for citizens

    //Warriors eat on average half as much as citizens
    for UT := WARRIOR_MIN to WARRIOR_MAX do
       Consumption := Consumption + P.Stats.GetUnitQty(UT) / 2 / 40; //On average unit needs to eat each 40min

    Reserve := gHands[fOwner].Stats.GetWareBalance(wtBread) * BREAD_RESTORE +
               gHands[fOwner].Stats.GetWareBalance(wtSausages) * SAUSAGE_RESTORE +
               gHands[fOwner].Stats.GetWareBalance(wtWine) * WINE_RESTORE +
               gHands[fOwner].Stats.GetWareBalance(wtFish) * FISH_RESTORE;
    Reserve := Reserve / Max(1,Consumption);

    Balance := Production - Consumption + Max(Reserve - 30, 0);
    fFoodText := Format('%.2f Food: %.2f - %.2f + %.2f|', [Balance, Production, Consumption, Reserve])
               + Format('       Bread: min(F%.2f, M%.2f, B%.2f)|', [Bread.FarmTheory, Bread.MillTheory, Bread.BakeryTheory])
               + Format('    Sausages: min(F%.2f, S%.2f, B%.2f)|', [Sausages.FarmTheory, Sausages.SwineTheory, Sausages.ButchersTheory])
               + Format('        Wine: W%.2f)|', [WineProduction])
               + Format('        Fish: F%.2f)|', [FishProduction])
               + Format('  Food value: %.2f + %.2f + %.2f + %.2f|', [BreadProduction * BREAD_RESTORE, SausagesProduction * SAUSAGE_RESTORE, WineProduction * WINE_RESTORE, FishProduction * FISH_RESTORE]);
  end;
end;


//Tell Mayor what proportions of army is needed
procedure TKMayorBalance.SetArmyDemand(aNeeds: TWarfareDemands);
var
  WT: TKMWareType;
begin
  //Convert army request into how many weapons are needed
  with fWarfare do
  begin
    for WT := WARFARE_MIN to WARFARE_MAX do
      Warfare[WT].Demand := aNeeds[WT];

    //Calculate ratios at which warfare should be produced in workshops
    OrderRatio[wtShield] := aNeeds[wtShield] / Max(0.001,(aNeeds[wtShield] + aNeeds[wtArmor]));
    OrderRatio[wtArmor]  := aNeeds[wtArmor]  / Max(0.001,(aNeeds[wtShield] + aNeeds[wtArmor]));
    OrderRatio[wtAxe]  := aNeeds[wtAxe]  / Max(0.001,(aNeeds[wtAxe] + aNeeds[wtPike] + aNeeds[wtBow]));
    OrderRatio[wtPike] := aNeeds[wtPike] / Max(0.001,(aNeeds[wtAxe] + aNeeds[wtPike] + aNeeds[wtBow]));
    OrderRatio[wtBow]  := aNeeds[wtBow]  / Max(0.001,(aNeeds[wtAxe] + aNeeds[wtPike] + aNeeds[wtBow]));

    OrderRatio[wtMetalShield] := aNeeds[wtMetalShield] / Max(0.001,(aNeeds[wtMetalShield] + aNeeds[wtMetalArmor]));
    OrderRatio[wtMetalArmor]  := aNeeds[wtMetalArmor]  / Max(0.001,(aNeeds[wtMetalShield] + aNeeds[wtMetalArmor]));
    OrderRatio[wtSword]     := aNeeds[wtSword]     / Max(0.001,(aNeeds[wtSword] + aNeeds[wtHallebard] + aNeeds[wtArbalet]));
    OrderRatio[wtHallebard] := aNeeds[wtHallebard] / Max(0.001,(aNeeds[wtSword] + aNeeds[wtHallebard] + aNeeds[wtArbalet]));
    OrderRatio[wtArbalet]   := aNeeds[wtArbalet]   / Max(0.001,(aNeeds[wtSword] + aNeeds[wtHallebard] + aNeeds[wtArbalet]));
  end;
end;


function TKMayorBalance.BalanceText: UnicodeString;
begin
  Result := fCoreText + '|' +
            fMaterialsText + '|' +
            fGoldText + '|' +
            fFoodText + '|' +
            fWarfareText + '|' +
            fAdviceText;
end;


procedure TKMayorBalance.Refresh;
var
  I: Integer;
begin
  SetLength(fAdvice, 0);
  try
    //Refresh balance of each industry
    //Try to express needs in terms of Balance = Production - Demand
    UpdateBalanceCore;
    AppendCore;

    //Don't build anything if we don't have a working School
    if gHands[fOwner].Stats.GetHouseQty(htSchool) = 0 then Exit;

    UpdateBalanceMaterials;
    AppendMaterials;

    //Don't build anything if we are short on materials
    if (fMaterials.StoneProduction < 0.5)
    or (fMaterials.WoodProduction < 0.5) then Exit;

    DistributeCorn;
    DistributeCoal;
    DistributeSteel;
    DistributeWood;

    UpdateBalanceGold;
    AppendGold;

    UpdateBalanceFood;
    AppendFood;

    UpdateBalanceWarfare;
    AppendWeaponry;

  finally
    fAdviceText := 'Advice: ';
    for I := 0 to High(fAdvice) do
      fAdviceText := fAdviceText + gRes.Houses[fAdvice[I]].HouseName + IfThen(I < High(fAdvice), ', ', '.');
  end;
end;


//Look at next item in advice queue
function TKMayorBalance.Peek: TKMHouseType;
begin
  //Take element from fAdvice queue
  if Length(fAdvice) > 0 then
    Result := fAdvice[0]
  else
    Result := htNone;
end;


//Reject the item because it could not be built
procedure TKMayorBalance.Reject;
begin
  Take;

  //Some logic that would not build anything and waste resources on that
  //if we dont have e.g. gold supply
end;


//Advised item was taken and most certainly will be finished
procedure TKMayorBalance.Take;
begin
  if Length(fAdvice) > 1 then
    Move(fAdvice[1], fAdvice[0], Length(fAdvice) - 1);

  //Trim last element
  SetLength(fAdvice, Length(fAdvice) - 1);
end;


procedure TKMayorBalance.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.Write(fOwner);

  SaveStream.Write(GoldNeed);
  SaveStream.Write(StoneNeed);
  SaveStream.Write(WoodNeed);

  //Save because there are demands for weaponry (set by General)
  SaveStream.Write(fWarfare.Warfare, SizeOf(fWarfare.Warfare));
  SaveStream.Write(fWarfare.OrderRatio, SizeOf(fWarfare.OrderRatio));

  //These are not saved because they are recalculated before each use
  {LoadStream.Read(fDemandCore, SizeOf(fDemandCore));
  LoadStream.Read(fDemandMaterials, SizeOf(fDemandMaterials));
  LoadStream.Read(fDemandGold, SizeOf(fDemandGold));
  LoadStream.Read(fDemandFood, SizeOf(fDemandFood));
  LoadStream.Read(fDemandWeaponry, SizeOf(fDemandWeaponry));}
end;


procedure TKMayorBalance.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.Read(fOwner);

  LoadStream.Read(GoldNeed);
  LoadStream.Read(StoneNeed);
  LoadStream.Read(WoodNeed);

  //Load demands for weaponry set by General
  LoadStream.Read(fWarfare.Warfare, SizeOf(fWarfare.Warfare));
  LoadStream.Read(fWarfare.OrderRatio, SizeOf(fWarfare.OrderRatio));

  //These are not saved because they are recalculated before each use
  {LoadStream.Read(fDemandCore, SizeOf(fDemandCore));
  LoadStream.Read(fDemandMaterials, SizeOf(fDemandMaterials));
  LoadStream.Read(fDemandGold, SizeOf(fDemandGold));
  LoadStream.Read(fDemandFood, SizeOf(fDemandFood));
  LoadStream.Read(fDemandWeaponry, SizeOf(fDemandWeaponry));}
end;


end.
