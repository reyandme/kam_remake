unit KM_UnitTaskMining;
{$I KaM_Remake.inc}
interface
uses
  Math, SysUtils,
  KM_CommonClasses, KM_Defaults, KM_Points,
  KM_Units, KM_UnitWorkplan, KM_Terrain,
  KM_ResWares;


type
  // Resource mining task
  TKMTaskMining = class(TKMUnitTask)
  private
    fBeastID: Byte;
    fWorkPlan: TKMUnitWorkPlan;
    function ResourceExists: Boolean;
    function ResourceTileIsLocked: Boolean;
    function ChooseToCutOrPlant: TKMPlantAct;
    procedure FindAnotherWorkPlan;
  public
    constructor Create(aUnit: TKMUnit; aWare: TKMWareType);
    destructor Destroy; override;
    function WalkShouldAbandon: Boolean; override;
    constructor Load(LoadStream: TKMemoryStream); override;
    function GetActivityText: UnicodeString;
    property WorkPlan: TKMUnitWorkPlan read fWorkPlan;
    function Execute: TKMTaskResult; override;
    function CouldBeCancelled: Boolean; override;
    procedure Save(SaveStream: TKMemoryStream); override;
  end;


implementation
uses
  KM_Houses, KM_HouseWoodcutters, KM_HandsCollection,
  KM_Resource, KM_ResMapElements, KM_ResTexts, KM_ResHouses,
  KM_Hand, KM_ResUnits, KM_ScriptingEvents;


{ TTaskMining }
constructor TKMTaskMining.Create(aUnit: TKMUnit; aWare: TKMWareType);
begin
  inherited Create(aUnit);

  fType := uttMining;
  fWorkPlan := TKMUnitWorkPlan.Create;
  fBeastID  := 0;

  fWorkPlan.FindPlan( fUnit,
                      fUnit.Home.HouseType,
                      aWare,
                      aUnit.Home.PointBelowEntrance,
                      ChooseToCutOrPlant
                      );
end;


destructor TKMTaskMining.Destroy;
begin
  // Make sure we don't abandon and leave our house with "working" animations
  if (fUnit <> nil)
    and not fUnit.Home.IsDestroyed
    and (fUnit.Home.GetState = hstWork) then
    fUnit.Home.SetState(hstIdle);

  FreeAndNil(fWorkPlan);

  inherited;
end;


//Note: Phase is -1 because it will have been increased at the end of last Execute
function TKMTaskMining.WalkShouldAbandon: Boolean;
begin
  Result := false;
  Assert(fUnit is TKMUnitCitizen);
  if fPhase = 2 then //Unit is walking to mine-position
    Result := ResourceTileIsLocked or //If someone takes our place
              not ResourceExists or //Resource has gone
              not TKMUnitCitizen(fUnit).CanWorkAt(WorkPlan.Loc, WorkPlan.GatheringScript);
end;


//Chose if we don't care or prefer specific activity
//depending on orders or clogged output
function TKMTaskMining.ChooseToCutOrPlant: TKMPlantAct;
begin
  Result := taAny;

  case fUnit.Home.HouseType of
    htWoodcutters: case TKMHouseWoodcutters(fUnit.Home).WoodcutterMode of
                      wcmChop:         Result := taCut;
                      wcmPlant:        Result := taPlant;
                      wcmChopAndPlant: if fUnit.Home.CheckResOut(wtTrunk) >= MAX_WARES_IN_HOUSE then
                                          Result := taPlant
                                        else
                                          Result := taAny;
                    end;
    htFarm:        if fUnit.Home.CheckResOut(wtCorn) >= MAX_WARES_IN_HOUSE then
                      Result := taPlant
                    else
                      Result := taAny;
    else Result := taAny; //We don't care since other housetypes don't have concurent activities
  end;
end;


constructor TKMTaskMining.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  fWorkPlan := TKMUnitWorkPlan.Create;
  fWorkPlan.Load(LoadStream);
  LoadStream.Read(fBeastID);
end;


function TKMTaskMining.GetActivityText: UnicodeString;
begin
  case WorkPlan.GatheringScript of
    gsStoneCutter:     Result := gResTexts[TX_UNIT_TASK_STONE];
    gsFarmerSow:       Result := gResTexts[TX_UNIT_TASK_SOW_CORN];
    gsFarmerCorn:      Result := gResTexts[TX_UNIT_TASK_CUTTING_CORN];
    gsFarmerWine:      Result := gResTexts[TX_UNIT_TASK_GRAPES];
    gsFisherCatch:     Result := gResTexts[TX_UNIT_TASK_FISHING];
    gsWoodCutterCut:   Result := gResTexts[TX_UNIT_TASK_CUT_TREE];
    gsWoodCutterPlant: Result := gResTexts[TX_UNIT_TASK_PLANT_TREE];
    else                Result := 'Unknown';
  end;
end;


//Try to find alternative target for our WorkPlan
//Happens when we discover that resource is gone or is occupied by another busy unit
//Return false if new plan could not be found
procedure TKMTaskMining.FindAnotherWorkPlan;
var OldLoc: TKMPoint; OldDir: TKMDirection;
begin
  OldLoc := WorkPlan.Loc;
  OldDir := WorkPlan.WorkDir;

  //Tell the work plan to find a new resource of the same gathering script
  if WorkPlan.FindDifferentResource(fUnit, fUnit.Home.PointBelowEntrance, OldLoc) then
  begin
    //Must always give us a new location (or same location but different direction)
    Assert((OldDir <> WorkPlan.WorkDir) or not KMSamePoint(OldLoc, WorkPlan.Loc));
    fPhase := 0; //Set the walk again (Will become 1 after this loop)
    fUnit.SetActionLockedStay(0, WorkPlan.ActionWalkTo);
  end else
  begin
    fPhase := 99; //Abandon as there is no other work plan available (Exit the task on next update)
    fUnit.SetActionLockedStay(0, WorkPlan.ActionWalkTo);
  end;
end;


function TKMTaskMining.ResourceTileIsLocked: Boolean;
var P: TKMPoint;
begin
  if WorkPlan.GatheringScript = gsWoodCutterCut then
  begin
    P := KMGetVertexTile(WorkPlan.Loc, WorkPlan.WorkDir);
    //Check all tiles around the tree, like we do in TKMTerrain.FindTree
    Result := gTerrain.TileIsLocked(P)
      or ((P.X > 1) and gTerrain.TileIsLocked(KMPoint(P.X-1, P.Y))) //if K=1, K-1 will be off map
      or ((P.Y > 1) and gTerrain.TileIsLocked(KMPoint(P.X, P.Y-1)))
      or ((P.X > 1) and (P.Y > 1) and gTerrain.TileIsLocked(KMPoint(P.X-1, P.Y-1)))
  end
  else
    Result := gTerrain.TileIsLocked(WorkPlan.Loc);
end;


function TKMTaskMining.ResourceExists: Boolean;
var P: TKMPoint;
begin
  with gTerrain do
  case WorkPlan.GatheringScript of
    gsStoneCutter:     Result := TileHasStone(WorkPlan.Loc.X, WorkPlan.Loc.Y-1); //Check stone deposit above Loc, which is walkable tile
    gsFarmerSow:       Result := TileIsCornField(WorkPlan.Loc) and (Land[WorkPlan.Loc.Y, WorkPlan.Loc.X].FieldAge = 0);
    gsFarmerCorn:      begin
                          Result := TileIsCornField(WorkPlan.Loc) and (Land[WorkPlan.Loc.Y, WorkPlan.Loc.X].FieldAge = CORN_AGE_MAX);
                          if Result then exit; //Resource still exists so exit
                          //If corn has been cut we can possibly plant new corn here to save time
                          Result := TileIsCornField(WorkPlan.Loc) and (Land[WorkPlan.Loc.Y, WorkPlan.Loc.X].FieldAge = 0);
                          if Result then
                            with WorkPlan do
                            begin
                              GatheringScript := gsFarmerSow; //Switch to sowing corn rather than cutting
                              ActionWalkFrom  := uaWalkTool; //Carry our scythe back (without the corn) as the player saw us take it out
                              ActionWorkType  := uaWork1;
                              WorkCyc    := 10;
                              Product1   := wtNone; //Don't produce corn
                              ProdCount1 := 0;
                            end;
                        end;
    gsFarmerWine:      Result := TileIsWineField(WorkPlan.Loc) and (Land[WorkPlan.Loc.Y, WorkPlan.Loc.X].FieldAge = CORN_AGE_MAX);
    gsFisherCatch:     Result := CatchFish(KMPointDir(WorkPlan.Loc,WorkPlan.WorkDir),true);
    gsWoodCutterPlant: Result := TileGoodForTree(WorkPlan.Loc.X, WorkPlan.Loc.Y);
    gsWoodCutterCut:   begin
                          P := KMGetVertexTile(WorkPlan.Loc, WorkPlan.WorkDir);
                          Result := ObjectIsChopableTree(P, caAgeFull) and (Land[P.Y, P.X].TreeAge >= TREE_AGE_FULL);
                        end;
    else                Result := True;
  end;
end;


function TKMTaskMining.CouldBeCancelled: Boolean;
begin
  Result := (fPhase - 1) //phase was increased at the end of execution
              in [1, 7]; //Allow cancel task only at walking phases
end;


{This is execution of Resource mining}
function TKMTaskMining.Execute: TKMTaskResult;
const
  // Shortcuts to skip certain Phases
  SkipWalk = 9;
  SKIP_WORK = 11 + MAX_WORKPLAN; //Skip to certain Phases
var
  D: TKMDirection;
  TimeToWork, StillFrame: Integer;
  ResAcquired: Boolean;
begin
  Result := trTaskContinues;

  //there's no point in doing a task if we can't return home
  if (fUnit.Home <> nil) and fUnit.Home.IsDestroyed then
  begin
    Result := trTaskDone;
    Exit;
  end;

  with fUnit do
  case fPhase of
    0:  if WorkPlan.HasToWalk then
        begin
          Home.SetState(hstEmpty);
          SetActionGoIn(WorkPlan.ActionWalkTo, gdGoOutside, Home); //Walk outside the house

          //Woodcutter takes his axe with him when going to chop trees
          if (WorkPlan.GatheringScript = gsWoodCutterCut) then
            Home.CurrentAction.SubActionRem([haFlagpole]);
        end
        else
        begin
          fPhase := SkipWalk; //Skip walking part if there's no need in it, e.g. CoalMiner or Baker
          SetActionLockedStay(0, uaWalk);
          Exit;
        end;

    1:  //We cannot assume that the walk is still valid because the terrain could have changed while we were walking out of the house.
        SetActionWalkToSpot(WorkPlan.Loc, WorkPlan.ActionWalkTo);

    2: //Check if we are at the location. WalkTo could have failed or resource could have been exhausted
       if not KMSamePoint(NextPosition, WorkPlan.Loc) or not ResourceExists or
          not TKMUnitCitizen(fUnit).CanWorkAt(WorkPlan.Loc, WorkPlan.GatheringScript) then
         FindAnotherWorkPlan
       else
         SetActionLockedStay(0, WorkPlan.ActionWalkTo);

    3: //Before work tasks for specific mining jobs
       if WorkPlan.GatheringScript = gsFisherCatch then
       begin
         Direction := WorkPlan.WorkDir;
         SetActionLockedStay(13, uaWork1, false); //Throw the line out
       end else
         SetActionLockedStay(0, WorkPlan.ActionWalkTo);

    4: //Choose direction and time to work
       begin
         if WorkPlan.WorkDir <> dirNA then
           Direction := WorkPlan.WorkDir;

         if gRes.Units[UnitType].UnitAnim[WorkPlan.ActionWorkType, Direction].Count < 1 then
           for D := dirN to dirNW do
             if gRes.Units[UnitType].UnitAnim[WorkPlan.ActionWorkType, D].Count > 1 then
             begin
               Direction := D;
               Break;
             end;

         TimeToWork := WorkPlan.WorkCyc * Math.max(gRes.Units[UnitType].UnitAnim[WorkPlan.ActionWorkType, Direction].Count, 1);
         SetActionLockedStay(TimeToWork, WorkPlan.ActionWorkType, False);
       end;
    5: //After work tasks for specific mining jobs
       case WorkPlan.GatheringScript of
         gsWoodCutterCut:  SetActionLockedStay(10, WorkPlan.ActionWorkType, true, 5, 5); //Wait for the tree to start falling down
         gsFisherCatch:    SetActionLockedStay(15, uaWork, false); //Pull the line in
         else               SetActionLockedStay(0, WorkPlan.ActionWorkType);
       end;
    6: begin
         StillFrame := 0;
         case WorkPlan.GatheringScript of //Perform special tasks if required
           gsStoneCutter:      gTerrain.DecStoneDeposit(KMPoint(WorkPlan.Loc.X,WorkPlan.Loc.Y-1));
           gsFarmerSow:        gTerrain.SowCorn(WorkPlan.Loc);
           gsFarmerCorn:       gTerrain.CutCorn(WorkPlan.Loc);
           gsFarmerWine:       gTerrain.CutGrapes(WorkPlan.Loc);
           gsFisherCatch:      begin
                                  gTerrain.CatchFish(KMPointDir(WorkPlan.Loc,WorkPlan.WorkDir));
                                  WorkPlan.ActionWorkType := uaWalkTool;
                                end;
           gsWoodCutterPlant:  //If the player placed a house plan here while we were digging don't place the
                                //tree so the house plan isn't canceled. This is actually the same as TSK/TPR IIRC
                                if TKMUnitCitizen(fUnit).CanWorkAt(WorkPlan.Loc, gsWoodCutterPlant) then
                                  gTerrain.SetObject(WorkPlan.Loc, gTerrain.ChooseTreeToPlant(WorkPlan.Loc));
           gsWoodCutterCut:    begin
                                  gTerrain.FallTree(KMGetVertexTile(WorkPlan.Loc, WorkPlan.WorkDir));
                                  StillFrame := 5;
                                end;
         end;
         SetActionLockedStay(WorkPlan.AfterWorkDelay, WorkPlan.ActionWorkType, True, StillFrame, StillFrame);
       end;
    7: begin
         //Removing the tree and putting a stump is handled in gTerrain.UpdateState from FallingTrees list
         SetActionWalkToSpot(Home.PointBelowEntrance, WorkPlan.ActionWalkFrom); //Go home
         Thought := thHome;
       end;
    8: SetActionGoIn(WorkPlan.ActionWalkFrom, gdGoInside, Home); //Go inside

    {Unit back at home and can process its booty now}
    9:    begin
            Thought := thNone;
            fPhase2 := 0;
            Home.SetState(hstWork);

            //Take required resources
            if WorkPlan.Resource1 <> wtNone then Home.ResTakeFromIn(WorkPlan.Resource1, WorkPlan.Count1);
            if WorkPlan.Resource2 <> wtNone then Home.ResTakeFromIn(WorkPlan.Resource2, WorkPlan.Count2);
            gHands[fUnit.Owner].Stats.WareConsumed(WorkPlan.Resource1, WorkPlan.Count1);
            gHands[fUnit.Owner].Stats.WareConsumed(WorkPlan.Resource2, WorkPlan.Count2);

            Home.CurrentAction.SubActionAdd([haSmoke]);
            if WorkPlan.GatheringScript = gsSwineBreeder then
            begin //Swines get feed and taken immediately
              fBeastID := TKMHouseSwineStable(Home).FeedBeasts;
              TKMHouseSwineStable(Home).TakeBeast(fBeastID);
            end;

            if WorkPlan.ActCount >= fPhase2 then
            begin
              Home.CurrentAction.SubActionWork(WorkPlan.HouseAct[fPhase2].Act);
              //Keep unit idling till next Phase, Idle time is -1 to compensate TaskExecution Phase
              SetActionLockedStay(WorkPlan.HouseAct[fPhase2].TimeToWork-1, uaWalk);
            end
            else
            begin
              fPhase := SKIP_WORK; //Skip to work complete
              SetActionLockedStay(0, uaWalk);
              Exit;
            end;
          end;
    10..10 + MAX_WORKPLAN:
          begin
            Inc(fPhase2);

            //Feed a horse/pig
            if (WorkPlan.GatheringScript = gsHorseBreeder) and (fPhase2 = 1) then
              fBeastID := TKMHouseSwineStable(Home).FeedBeasts;

            //Keep on working
            if fPhase2 <= WorkPlan.ActCount then
            begin
              Home.CurrentAction.SubActionWork(WorkPlan.HouseAct[fPhase2].Act);
              if fPhase < WorkPlan.ActCount then
                SetActionLockedStay(WorkPlan.HouseAct[fPhase2].TimeToWork-1, uaWalk) //-1 to compensate units UpdateState run
              else
                SetActionLockedStay(WorkPlan.HouseAct[fPhase2].TimeToWork-2, uaWalk) //-2 to compensate 2 UpdateStates of a unit in last Act
            end
            else
            begin
              fPhase := SKIP_WORK; //Skip to step 31
              SetActionLockedStay(0, uaWalk);
              Exit;
            end;
          end;
    11 + MAX_WORKPLAN:
          begin
            if WorkPlan.GatheringScript = gsHorseBreeder then
              TKMHouseSwineStable(Home).TakeBeast(fBeastID); //Take the horse after feeding

            case WorkPlan.GatheringScript of
              gsCoalMiner:    ResAcquired := gTerrain.DecOreDeposit(WorkPlan.Loc, wtCoal);
              gsGoldMiner:    ResAcquired := gTerrain.DecOreDeposit(WorkPlan.Loc, wtGoldOre);
              gsIronMiner:    ResAcquired := gTerrain.DecOreDeposit(WorkPlan.Loc, wtIronOre);
              gsSwineBreeder: ResAcquired := fBeastID <> 0;
              gsHorseBreeder: ResAcquired := fBeastID <> 0;
              else             ResAcquired := true;
            end;

            if ResAcquired then
            begin
              Home.ResAddToOut(WorkPlan.Product1, WorkPlan.ProdCount1);
              Home.ResAddToOut(WorkPlan.Product2, WorkPlan.ProdCount2);
              gHands[fUnit.Owner].Stats.WareProduced(WorkPlan.Product1, WorkPlan.ProdCount1);
              gHands[fUnit.Owner].Stats.WareProduced(WorkPlan.Product2, WorkPlan.ProdCount2);
              gScriptEvents.ProcWareProduced(fUnit.Home, WorkPlan.Product1, WorkPlan.ProdCount1);
              gScriptEvents.ProcWareProduced(fUnit.Home, WorkPlan.Product2, WorkPlan.ProdCount2);
            end;

            Home.SetState(hstIdle);
            SetActionLockedStay(WorkPlan.AfterWorkIdle-1, uaWalk);
          end;
    else  Result := trTaskDone;
  end;
  Inc(fPhase);
end;


procedure TKMTaskMining.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  fWorkPlan.Save(SaveStream);
  SaveStream.Write(fBeastID);
end;


end.
