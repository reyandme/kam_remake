unit KM_UnitWorkPlan;
{$I KaM_Remake.inc}
interface
uses
  KM_Defaults, KM_CommonClasses, KM_Points, KM_Terrain, KM_Units,
  KM_ResHouses, KM_ResWares;


const
  MAX_WORKPLAN = 24;

type
  TKMWorkPlanAllowedEvent = function(aProduct: TKMWareType): Boolean of object;

  TKMUnitWorkPlan = class
  private
    fHome: TKMHouseType;
    fIssued: Boolean;
    function ChooseTree(const aLoc, aAvoid: TKMPoint; aRadius: Integer; aPlantAct: TKMPlantAct; aUnit: TKMUnit;
                        out Tree: TKMPointDir; out PlantAct: TKMPlantAct): Boolean;
    procedure Clear;
    procedure WalkStyle(const aLoc2: TKMPointDir; aTo, aWork: TKMUnitActionType; aCycles, aDelay: Byte; aFrom: TKMUnitActionType; aScript: TKMGatheringScript);
    procedure SubActAdd(aAct: TKMHouseActionType; aCycles: Single);
    procedure ResourcePlan(Res1: TKMWareType; Qty1: Byte; Res2: TKMWareType; Qty2: Byte; Prod1: TKMWareType; Prod2: TKMWareType = wtNone);
  public
    HasToWalk: Boolean;
    Loc: TKMPoint;
    ActionWalkTo: TKMUnitActionType;
    ActionWorkType: TKMUnitActionType;
    WorkCyc: Integer;
    WorkDir: TKMDirection;
    GatheringScript: TKMGatheringScript;
    AfterWorkDelay: Integer;
    ActionWalkFrom: TKMUnitActionType;
    Resource1: TKMWareType; Count1: Byte;
    Resource2: TKMWareType; Count2: Byte;
    ActCount: Byte;
    HouseAct: array [0..MAX_WORKPLAN - 1] of record
      Act: TKMHouseActionType;
      TimeToWork: Word;
    end;
    Product1: TKMWareType; ProdCount1: Byte;
    Product2: TKMWareType; ProdCount2: Byte;
    AfterWorkIdle: Integer;
    ResourceDepleted: Boolean;
  public
    procedure FindPlan(aUnit: TKMUnit; aHome: TKMHouseType; aProduct: TKMWareType;
                       aLoc: TKMPoint; aPlantAct: TKMPlantAct);
    function FindDifferentResource(aUnit: TKMUnit; aLoc: TKMPoint; const aAvoidLoc: TKMPoint): Boolean;
    property IsIssued: Boolean read fIssued;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
  end;


implementation
uses
  SysUtils,
  KM_Hand, KM_ResUnits, KM_Houses, KM_HouseWoodcutters,
  KM_Resource, KM_CommonUtils;


{Houses are only a place on map, they should not issue or perform tasks (except Training)
Everything should be issued by units
Where to go, which walking style, what to do on location, for how long
How to go back in case success, incase bad luck
What to take from supply, how much, take2, much2
What to do, Work/Cycles, What resource to add to Output, how much
E.g. CoalMine: Miner arrives at home and Idles for 5sec, then takes a work task (depending on ResOut count)
Since Loc is 0,0 he immidietely skips to Phase X where he switches house to Work1 (and self busy for same framecount)
Then Work2 and Work3 same way. Then adds resource to out and everything to Idle for 5sec.
E.g. Farmer arrives at home and Idles for 5sec, then takes a work task (depending on ResOut count, HouseType and Need to sow corn)
...... then switches house to Work1 (and self busy for same framecount)
Then Work2 and Work3 same way. Then adds resource to out and everything to Idle for 5sec.}
procedure TKMUnitWorkPlan.Clear;
begin
  fIssued := False;
  HasToWalk := False;
  Loc := KMPOINT_ZERO;
  ActionWalkTo := uaWalk;
  ActionWorkType := uaWork;
  WorkCyc := 0;
  WorkDir := dirNA;
  GatheringScript := gsNone;
  AfterWorkDelay := 0;
  ActionWalkFrom := uaWalk;
  Resource1 := wtNone;
  Count1 := 0;
  Resource2 := wtNone;
  Count2 := 0;
  ActCount := 0;
  Product1 := wtNone;
  ProdCount1 := 0;
  Product2 := wtNone;
  ProdCount2 := 0;
  AfterWorkIdle := 0;
  ResourceDepleted := False;
end;


procedure TKMUnitWorkPlan.WalkStyle(const aLoc2: TKMPointDir; aTo, aWork: TKMUnitActionType; aCycles,aDelay: Byte; aFrom: TKMUnitActionType; aScript: TKMGatheringScript);
begin
  Loc := aLoc2.Loc;
  HasToWalk := True;
  ActionWalkTo := aTo;
  ActionWorkType := aWork;
  WorkCyc := aCycles;
  AfterWorkDelay := aDelay;
  GatheringScript := aScript;
  ActionWalkFrom := aFrom;
  WorkDir := aLoc2.Dir;
end;


procedure TKMUnitWorkPlan.SubActAdd(aAct: TKMHouseActionType; aCycles: Single);
begin
  HouseAct[ActCount].Act := aAct;
  HouseAct[ActCount].TimeToWork := Round(gRes.Houses[fHome].Anim[aAct].Count * aCycles);
  Inc(ActCount);
end;


procedure TKMUnitWorkPlan.ResourcePlan(Res1: TKMWareType; Qty1: Byte; Res2: TKMWareType; Qty2: Byte; Prod1: TKMWareType; Prod2: TKMWareType = wtNone);
begin
  Resource1 := Res1; Count1 := Qty1;
  Resource2 := Res2; Count2 := Qty2;
  Product1 := Prod1; ProdCount1 := gRes.Houses[fHome].ResProductionX;
  if Prod2=wtNone then exit;
  Product2 := Prod2; ProdCount2 := gRes.Houses[fHome].ResProductionX;
end;


function TKMUnitWorkPlan.FindDifferentResource(aUnit: TKMUnit; aLoc: TKMPoint; const aAvoidLoc: TKMPoint): Boolean;
var
  NewLoc: TKMPointDir;
  PlantAct: TKMPlantAct;
  Found: boolean;
  HW: TKMHouseWoodcutters;
begin
  if (GatheringScript = gsWoodCutterCut) OR (GatheringScript = gsWoodCutterPlant) then
  begin
    HW := TKMHouseWoodcutters(aUnit.Home);
    HW.ValidateFlagPoint; //Validate Cutting point. It will be set to a valid one if needed.

    if HW.IsFlagPointSet then
      aLoc := HW.FlagPoint;
  end;

  with gTerrain do
  case GatheringScript of
    gsStoneCutter:     Found := FindStone(aLoc, gRes.Units[aUnit.UnitType].MiningRange, aAvoidLoc, False, NewLoc);
    gsFarmerSow:       Found := FindCornField(aLoc, gRes.Units[aUnit.UnitType].MiningRange, aAvoidLoc, taPlant, PlantAct, NewLoc);
    gsFarmerCorn:      begin
                          Found := FindCornField(aLoc, gRes.Units[aUnit.UnitType].MiningRange, aAvoidLoc, taAny, PlantAct, NewLoc);
                          if PlantAct = taPlant then
                          begin
                            GatheringScript := gsFarmerSow; //Switch to sowing corn rather than cutting
                            ActionWalkFrom  := uaWalkTool; //Carry our scythe back (without the corn) as the player saw us take it out
                            ActionWorkType  := uaWork1;
                            WorkCyc    := 10;
                            Product1   := wtNone; //Don't produce corn
                            ProdCount1 := 0;
                          end;
                        end;
    gsFarmerWine:      begin
                          Found := FindWineField(aLoc, gRes.Units[aUnit.UnitType].MiningRange, aAvoidLoc, NewLoc);
                          NewLoc.Dir := dirN; //The animation for picking grapes is only defined for facing north
                        end;
    gsFisherCatch:     Found := FindFishWater(aLoc, gRes.Units[aUnit.UnitType].MiningRange, aAvoidLoc, False, NewLoc);
    gsWoodCutterCut:   Found := ChooseTree(aLoc, KMGetVertexTile(aAvoidLoc, WorkDir), gRes.Units[aUnit.UnitType].MiningRange, taCut, aUnit, NewLoc, PlantAct);
    gsWoodCutterPlant: Found := ChooseTree(aLoc, aAvoidLoc, gRes.Units[aUnit.UnitType].MiningRange, taPlant, aUnit, NewLoc, PlantAct);
    else                Found := False; //Can find a new resource for an unknown gathering script, so return with false
  end;

  if Found then
  begin
    Loc := NewLoc.Loc;
    WorkDir := NewLoc.Dir;
    Result := True;
  end
  else
    Result := False;
end;


function TKMUnitWorkPlan.ChooseTree(const aLoc, aAvoid: TKMPoint; aRadius: Integer; aPlantAct: TKMPlantAct; aUnit: TKMUnit; out Tree: TKMPointDir; out PlantAct: TKMPlantAct): Boolean;
var
  I: Integer;
  T: TKMPoint;
  TreeList: TKMPointDirCenteredList;
  BestToPlant, SecondBestToPlant: TKMPointCenteredList;
begin
  TreeList := TKMPointDirCenteredList.Create(aLoc);
  BestToPlant := TKMPointCenteredList.Create(aLoc);
  SecondBestToPlant := TKMPointCenteredList.Create(aLoc);

  gTerrain.FindTree(aLoc, aRadius, aAvoid, aPlantAct, TreeList, BestToPlant, SecondBestToPlant);

  //Convert taAny to either a Tree or a Spot
  if (aPlantAct in [taCut, taAny])
  and ((TreeList.Count > 8) //Always chop the tree if there are many
       or (BestToPlant.Count + SecondBestToPlant.Count = 0)
       or ((TreeList.Count > 0) and (KaMRandom('TKMUnitWorkPlan.ChooseTree') < TreeList.Count / (TreeList.Count + (BestToPlant.Count + SecondBestToPlant.Count)/15)))
      ) then
  begin
    PlantAct := taCut;
    Result := TreeList.GetWeightedRandom(Tree);
  end
  else
  begin
    PlantAct := taPlant;
    //First try stumps list
    for I := BestToPlant.Count - 1 downto 0 do
      if not TKMUnitCitizen(aUnit).CanWorkAt(BestToPlant[I], gsWoodCutterPlant) then
        BestToPlant.Delete(I);
    Result := BestToPlant.GetWeightedRandom(T);
    //Trees must always be planted facing north as that is the direction the animation uses
    if Result then
      Tree := KMPointDir(T, dirN)
    else
    begin
      //Try empty places list
      for I := SecondBestToPlant.Count - 1 downto 0 do
        if not TKMUnitCitizen(aUnit).CanWorkAt(SecondBestToPlant[I], gsWoodCutterPlant) then
          SecondBestToPlant.Delete(I);
      Result := SecondBestToPlant.GetWeightedRandom(T);
      //Trees must always be planted facing north as that is the direction the animation uses
      if Result then
        Tree := KMPointDir(T, dirN);
    end;
  end;

  TreeList.Free;
  BestToPlant.Free;
  SecondBestToPlant.Free;
end;


procedure TKMUnitWorkPlan.FindPlan(aUnit: TKMUnit; aHome: TKMHouseType; aProduct: TKMWareType;
                                 aLoc: TKMPoint; aPlantAct: TKMPlantAct);
var
  I: Integer;
  Tmp: TKMPointDir;
  PlantAct: TKMPlantAct;
  HW: TKMHouseWoodcutters;
begin
  Clear;

  fHome := aHome;
  AfterWorkIdle := gRes.Houses[aHome].WorkerRest * 10;

  //Now we need to fill only specific properties
  case aUnit.UnitType of
    utWoodcutter:    if aHome = htWoodcutters then
                      begin
                        HW := TKMHouseWoodcutters(aUnit.Home);
                        HW.ValidateFlagPoint; //Validate Cutting point. It will be set to a valid one if needed.

                        if HW.IsFlagPointSet then
                          aLoc := HW.FlagPoint;

                        fIssued := ChooseTree(aLoc, KMPOINT_ZERO, gRes.Units[aUnit.UnitType].MiningRange, aPlantAct, aUnit, Tmp, PlantAct);
                        if fIssued then
                        begin
                          case PlantAct of
                            taCut:    begin //Cutting uses DirNW,DirSW,DirSE,DirNE (1,3,5,7) of uaWork
                                        ResourcePlan(wtNone,0,wtNone,0,wtTrunk);
                                        WalkStyle(Tmp, uaWalkBooty,uaWork,15,20,uaWalkTool2,gsWoodCutterCut);
                                      end;
                            taPlant:  begin //Planting uses DirN (0) of uaWork
                                        WalkStyle(Tmp, uaWalkTool,uaWork,12,0,uaWalk,gsWoodCutterPlant);
                                      end;
                            else      fIssued := False;
                          end;
                        end
                        else
                          case PlantAct of
                            taCut:    if not gTerrain.CanFindTree(aLoc, gRes.Units[aUnit.UnitType].MiningRange) then
                                        ResourceDepleted := True; //No more trees to cut
                            taPlant:  if HW.WoodcutterMode = wcmPlant then
                                        ResourceDepleted := True;   //No place for trees to plant
                          end;
                      end;
    utMiner:         if aHome = htCoalMine then
                      begin
                        fIssued := gTerrain.FindOre(aLoc, wtCoal, Tmp.Loc);
                        if fIssued then
                        begin
                          Loc := Tmp.Loc;
                          ResourcePlan(wtNone,0,wtNone,0,wtCoal);
                          GatheringScript := gsCoalMiner;
                          SubActAdd(haWork1,1);
                          SubActAdd(haWork2,23);
                          SubActAdd(haWork5,1);
                        end else
                          ResourceDepleted := True;
                      end else
                      if aHome = htIronMine then
                      begin
                        fIssued := gTerrain.FindOre(aLoc, wtIronOre, Tmp.Loc);
                        if fIssued then
                        begin
                          Loc := Tmp.Loc;
                          ResourcePlan(wtNone,0,wtNone,0,wtIronOre);
                          GatheringScript := gsIronMiner;
                          SubActAdd(haWork1,1);
                          SubActAdd(haWork2,24);
                          SubActAdd(haWork5,1);
                        end else
                          ResourceDepleted := True;
                      end else
                      if aHome = htGoldMine then
                      begin
                        fIssued := gTerrain.FindOre(aLoc, wtGoldOre, Tmp.Loc);
                        if fIssued then
                        begin
                          Loc := Tmp.Loc;
                          ResourcePlan(wtNone,0,wtNone,0,wtGoldOre);
                          GatheringScript := gsGoldMiner;
                          SubActAdd(haWork1,1);
                          SubActAdd(haWork2,24);
                          SubActAdd(haWork5,1);
                        end else
                          ResourceDepleted := True;
                      end;
    utAnimalBreeder: if aHome = htSwine then
                      begin
                        ResourcePlan(wtCorn,1,wtNone,0,wtPig,wtSkin);
                        GatheringScript := gsSwineBreeder;
                        for I := 0 to 3 do
                        begin
                          SubActAdd(haWork2,1);
                          SubActAdd(haWork3,1);
                        end;
                        SubActAdd(haWork2,1);
                        fIssued := True;
                      end else

                      if aHome = htStables then
                      begin
                        ResourcePlan(wtCorn,1,wtNone,0,wtHorse);
                        GatheringScript := gsHorseBreeder;
                        SubActAdd(haWork1,1);
                        SubActAdd(haWork2,1);
                        SubActAdd(haWork3,1);
                        SubActAdd(haWork4,1);
                        SubActAdd(haWork5,1);
                        fIssued := True;
                      end;
    utFarmer:        if aHome = htFarm then
                      begin
                        fIssued := gTerrain.FindCornField(aLoc, gRes.Units[aUnit.UnitType].MiningRange, KMPOINT_ZERO, aPlantAct, PlantAct, Tmp);
                        if fIssued then
                          case PlantAct of
                            taCut:    begin
                                        ResourcePlan(wtNone,0,wtNone,0,wtCorn);
                                        WalkStyle(Tmp, uaWalkTool,uaWork,6,0,uaWalkBooty,gsFarmerCorn);
                                      end;
                            taPlant:  WalkStyle(Tmp, uaWalk,uaWork1,10,0,uaWalk,gsFarmerSow);
                            else      fIssued := False;
                          end;
                      end else

                      if aHome = htWineyard then
                      begin
                        fIssued := gTerrain.FindWineField(aLoc, gRes.Units[aUnit.UnitType].MiningRange, KMPOINT_ZERO, Tmp);
                        if fIssued then
                        begin
                          ResourcePlan(wtNone,0,wtNone,0,wtWine);
                          WalkStyle(KMPointDir(Tmp.Loc,dirN), uaWalkTool2,uaWork2,5,0,uaWalkBooty2,gsFarmerWine); //The animation for picking grapes is only defined for facing north
                          SubActAdd(haWork1,1);
                          SubActAdd(haWork2,11);
                          SubActAdd(haWork5,1);
                        end;
                      end;
    utLamberjack:    if aHome = htSawmill then
                      begin
                        ResourcePlan(wtTrunk,1,wtNone,0,wtWood);
                        SubActAdd(haWork1,1);
                        SubActAdd(haWork2,25);
                        SubActAdd(haWork5,1);
                        fIssued := True;
                      end else

                      if (aHome = htArmorWorkshop) and (aProduct = wtArmor) then
                      begin
                        ResourcePlan(wtLeather,1,wtNone,0,wtArmor);
                        for I := 0 to 3 do
                        begin
                          SubActAdd(haWork2,1);
                          SubActAdd(haWork3,1);
                          SubActAdd(haWork4,1);
                        end;
                        SubActAdd(haWork2,0.25);
                        fIssued := True;
                      end else

                      if (aHome = htArmorWorkshop) and (aProduct = wtShield) then
                      begin
                        ResourcePlan(wtWood,1,wtNone,0,wtShield);
                        for I := 0 to 3 do
                        begin
                          SubActAdd(haWork2,1);
                          SubActAdd(haWork3,1);
                          SubActAdd(haWork4,1);
                        end;
                        SubActAdd(haWork2,0.25);
                        fIssued := True;
                      end else

                      if (aHome = htWeaponWorkshop) and (aProduct = wtAxe) then
                      begin
                        ResourcePlan(wtWood,2,wtNone,0,wtAxe);
                        SubActAdd(haWork1,1);
                        for I := 0 to 2 do
                        begin
                          SubActAdd(haWork2,1);
                          SubActAdd(haWork3,1);
                          SubActAdd(haWork4,1);
                        end;
                        SubActAdd(haWork5,1);
                        fIssued := True;
                      end else

                      if (aHome = htWeaponWorkshop) and (aProduct = wtPike) then
                      begin
                        ResourcePlan(wtWood,2,wtNone,0,wtPike);
                        SubActAdd(haWork1,1);
                        for I := 0 to 2 do
                        begin
                          SubActAdd(haWork2,1);
                          SubActAdd(haWork3,1);
                          SubActAdd(haWork4,1);
                        end;
                        SubActAdd(haWork5,1);
                        fIssued := True;
                      end else

                      if (aHome = htWeaponWorkshop) and (aProduct = wtBow) then
                      begin
                        ResourcePlan(wtWood,2,wtNone,0,wtBow);
                        SubActAdd(haWork1,1);
                        for I := 0 to 2 do
                        begin
                          SubActAdd(haWork2,1);
                          SubActAdd(haWork3,1);
                          SubActAdd(haWork4,1);
                        end;
                        SubActAdd(haWork5,1);
                        fIssued := True;
                      end;
    utBaker:         if aHome = htMill then
                      begin
                        ResourcePlan(wtCorn,1,wtNone,0,wtFlour);
                        SubActAdd(haWork2,47);
                        fIssued := True;
                      end else

                      if aHome = htBakery then
                      begin
                        ResourcePlan(wtFlour,1,wtNone,0,wtBread);
                        for I := 0 to 6 do
                        begin
                          SubActAdd(haWork2,1);
                          SubActAdd(haWork3,1);
                        end;
                        fIssued := True;
                      end;
    utButcher:       if aHome = htTannery then
                      begin
                        ResourcePlan(wtSkin,1,wtNone,0,wtLeather);
                        SubActAdd(haWork1,1);
                        SubActAdd(haWork2,29);
                        fIssued := True;
                      end else

                      if aHome = htButchers then
                      begin
                        ResourcePlan(wtPig,1,wtNone,0,wtSausages);
                        SubActAdd(haWork1,1);
                        for I := 0 to 5 do
                        begin
                          SubActAdd(haWork2,1);
                          SubActAdd(haWork4,1);
                          SubActAdd(haWork3,1);
                        end;
                        fIssued := True;
                      end;
    utFisher:        if aHome = htFisherHut then
                      begin
                        fIssued := gTerrain.FindFishWater(aLoc, gRes.Units[aUnit.UnitType].MiningRange, KMPOINT_ZERO, False, Tmp);
                        if fIssued then
                        begin
                          ResourcePlan(wtNone,0,wtNone,0,wtFish);
                          WalkStyle(Tmp,uaWalk,uaWork2,12,0,uaWalkTool,gsFisherCatch);
                        end else
                          //We must check again this time ignoring working units since they don't indicate the resource is depleted
                          ResourceDepleted := not gTerrain.FindFishWater(aLoc, gRes.Units[aUnit.UnitType].MiningRange, KMPOINT_ZERO, True, Tmp);
                      end;
    utStoneCutter:   if aHome = htQuary then
                      begin
                        fIssued := gTerrain.FindStone(aLoc, gRes.Units[aUnit.UnitType].MiningRange, KMPOINT_ZERO, False, Tmp);
                        if fIssued then
                        begin
                          ResourcePlan(wtNone,0,wtNone,0,wtStone);
                          WalkStyle(Tmp, uaWalk,uaWork,8,0,uaWalkTool,gsStoneCutter);
                          SubActAdd(haWork1,1);
                          SubActAdd(haWork2,9);
                          SubActAdd(haWork5,1);
                        end else
                          //We must check again this time ignoring working units since they don't indicate the resource is depleted
                          ResourceDepleted := not gTerrain.FindStone(aLoc, gRes.Units[aUnit.UnitType].MiningRange, KMPOINT_ZERO, True, Tmp);
                      end;
    utSmith:         if (aHome = htArmorSmithy) and (aProduct = wtMetalShield) then
                      begin
                        ResourcePlan(wtSteel,1,wtCoal,1,wtMetalShield);
                        for I := 0 to 3 do
                        begin
                          SubActAdd(haWork2,1);
                          SubActAdd(haWork3,1);
                          SubActAdd(haWork4,1);
                        end;
                        SubActAdd(haWork2,1);
                        SubActAdd(haWork5,1);
                        fIssued := True;
                      end else

                      if (aHome = htArmorSmithy) and (aProduct = wtMetalArmor) then
                      begin
                        ResourcePlan(wtSteel,1,wtCoal,1,wtMetalArmor);
                        for I := 0 to 3 do
                        begin
                          SubActAdd(haWork2,1);
                          SubActAdd(haWork3,1);
                          SubActAdd(haWork4,1);
                        end;
                        SubActAdd(haWork2,1);
                        SubActAdd(haWork5,1);
                        fIssued := True;
                      end else

                      if (aHome = htWeaponSmithy) and (aProduct = wtSword) then
                      begin
                        ResourcePlan(wtSteel,1,wtCoal,1,wtSword);
                        SubActAdd(haWork1,1);
                        for I := 0 to 2 do
                        begin
                          SubActAdd(haWork2,1);
                          SubActAdd(haWork3,1);
                          SubActAdd(haWork4,1);
                        end;
                        SubActAdd(haWork5,1);
                        fIssued := True;
                      end else

                      if (aHome = htWeaponSmithy) and (aProduct = wtHallebard) then
                      begin
                        ResourcePlan(wtSteel,1,wtCoal,1,wtHallebard);
                        SubActAdd(haWork1,1);
                        for I := 0 to 2 do
                        begin
                          SubActAdd(haWork2,1);
                          SubActAdd(haWork3,1);
                          SubActAdd(haWork4,1);
                        end;
                        SubActAdd(haWork5,1);
                        fIssued := True;
                      end else

                      if (aHome = htWeaponSmithy) and (aProduct = wtArbalet) then
                      begin
                        ResourcePlan(wtSteel,1,wtCoal,1,wtArbalet);
                        SubActAdd(haWork1,1);
                        for I := 0 to 2 do
                        begin
                          SubActAdd(haWork2,1);
                          SubActAdd(haWork3,1);
                          SubActAdd(haWork4,1);
                        end;
                        SubActAdd(haWork5,1);
                        fIssued := True;
                      end;
    utMetallurgist:  if aHome = htIronSmithy then
                      begin
                        ResourcePlan(wtIronOre,1,wtCoal,1,wtSteel);
                        for I := 0 to 3 do
                        begin
                          SubActAdd(haWork2,1);
                          SubActAdd(haWork3,1);
                        end;
                        SubActAdd(haWork2,1);
                        SubActAdd(haWork3,0.25);
                        fIssued := True;
                      end else
                      if aHome = htMetallurgists then
                      begin
                        ResourcePlan(wtGoldOre,1,wtCoal,1,wtGold);
                        for I := 0 to 3 do
                        begin
                          SubActAdd(haWork2,1);
                          SubActAdd(haWork3,1);
                          SubActAdd(haWork4,1);
                        end;
                        SubActAdd(haWork2,1);
                        SubActAdd(haWork3,0.1);
                        fIssued := True;
                      end;
  else
    raise Exception.Create('No work plan for ' +
                  gRes.Units[aUnit.UnitType].GUIName + ' in ' +
                  gRes.Houses[aHome].HouseName);
  end;
end;


procedure TKMUnitWorkPlan.Load(LoadStream: TKMemoryStream);
var I: Integer;
begin
  LoadStream.CheckMarker('WorkPlan');
  LoadStream.Read(fHome, SizeOf(fHome));
  LoadStream.Read(fIssued);
//public
  LoadStream.Read(HasToWalk);
  LoadStream.Read(Loc);
  LoadStream.Read(ActionWalkTo, SizeOf(ActionWalkTo));
  LoadStream.Read(ActionWorkType, SizeOf(ActionWorkType));
  LoadStream.Read(WorkCyc);
  LoadStream.Read(WorkDir);
  LoadStream.Read(GatheringScript, SizeOf(GatheringScript));
  LoadStream.Read(AfterWorkDelay);
  LoadStream.Read(ActionWalkFrom, SizeOf(ActionWalkFrom));
  LoadStream.Read(Resource1, SizeOf(Resource1));
  LoadStream.Read(Count1);
  LoadStream.Read(Resource2, SizeOf(Resource2));
  LoadStream.Read(Count2);
  LoadStream.Read(ActCount);
  for I := 0 to ActCount - 1 do //Write only assigned
  begin
    LoadStream.Read(HouseAct[I].Act, SizeOf(HouseAct[I].Act));
    LoadStream.Read(HouseAct[I].TimeToWork);
  end;
  LoadStream.Read(Product1, SizeOf(Product1));
  LoadStream.Read(ProdCount1);
  LoadStream.Read(Product2, SizeOf(Product2));
  LoadStream.Read(ProdCount2);
  LoadStream.Read(AfterWorkIdle);
  LoadStream.Read(ResourceDepleted);
end;


procedure TKMUnitWorkPlan.Save(SaveStream: TKMemoryStream);
var I: Integer;
begin
  SaveStream.PlaceMarker('WorkPlan');
  SaveStream.Write(fHome, SizeOf(fHome));
  SaveStream.Write(fIssued);
//public
  SaveStream.Write(HasToWalk);
  SaveStream.Write(Loc);
  SaveStream.Write(ActionWalkTo, SizeOf(ActionWalkTo));
  SaveStream.Write(ActionWorkType, SizeOf(ActionWorkType));
  SaveStream.Write(WorkCyc);
  SaveStream.Write(WorkDir);
  SaveStream.Write(GatheringScript, SizeOf(GatheringScript));
  SaveStream.Write(AfterWorkDelay);
  SaveStream.Write(ActionWalkFrom, SizeOf(ActionWalkFrom));
  SaveStream.Write(Resource1, SizeOf(Resource1));
  SaveStream.Write(Count1);
  SaveStream.Write(Resource2, SizeOf(Resource2));
  SaveStream.Write(Count2);
  SaveStream.Write(ActCount);
  for I := 0 to ActCount - 1 do //Write only assigned
  begin
    SaveStream.Write(HouseAct[I].Act, SizeOf(HouseAct[I].Act));
    SaveStream.Write(HouseAct[I].TimeToWork);
  end;
  SaveStream.Write(Product1, SizeOf(Product1));
  SaveStream.Write(ProdCount1);
  SaveStream.Write(Product2, SizeOf(Product2));
  SaveStream.Write(ProdCount2);
  SaveStream.Write(AfterWorkIdle);
  SaveStream.Write(ResourceDepleted);
end;


end.
