unit KM_CityPlanner;
{$I KaM_Remake.inc}
interface
uses
  Classes, Graphics, KromUtils, Math, SysUtils,
  KM_Defaults, KM_Points, KM_CommonClasses, KM_CommonTypes,
  KM_TerrainFinder, KM_PerfLog, KM_Houses, KM_ResHouses, KM_ResWares,
  KM_PathFindingRoad, KM_CityPredictor;

const
  MAX_SCAN_DIST_FROM_HOUSE = 6;
  MIN_SCAN_DIST_FROM_HOUSE = 2; // Houses must have at least 1 tile of space between them

var
  {
  GA_PLANNER_SnapCrit_SnapToHouse: Single = 1;
  GA_PLANNER_SnapCrit_SnapToRoad: Single = 1;
  GA_PLANNER_FindPlaceForHouse_SnapCrit: Single = 1;
  GA_PLANNER_FindPlaceForHouse_DistCrit: Single = 1;
  GA_PLANNER_FindPlaceForQuary_SnapCrit: Single = 1;
  GA_PLANNER_FindPlaceForQuary_DistCrit: Single = 10;
  GA_PLANNER_FindPlaceForWoodcutter_BLOCK_RAD: Single = 5.5;
  GA_PLANNER_FindPlaceForWoodcutter_DistCrit: Single = 1;
  GA_PLANNER_FindPlaceForWoodcutter_TreeCnt: Single = 1;
  GA_PLANNER_FindPlaceForWoodcutter_CanPlaceTreeCnt: Single = 1;
  GA_PLANNER_FindPlaceForWoodcutter_PlansAround: Single = 1;
  //}
  GA_PLANNER_SnapCrit_SnapToHouse                   : Single = 14.0250349;
  GA_PLANNER_SnapCrit_SnapToRoad                    : Single = 3.654827118;

  GA_PLANNER_DistCrit_Store                         : Single = 1;
  GA_PLANNER_DistCrit_School                        : Single = 1;
  GA_PLANNER_DistCrit_Inn_Store                     : Single = 1;
  GA_PLANNER_DistCrit_Inn_Inn                       : Single = 1;
  GA_PLANNER_DistCrit_Marketplace                   : Single = 1;
  GA_PLANNER_DistCrit_IronSmithy_Self               : Single = 1;
  GA_PLANNER_DistCrit_IronSmithy_Res                : Single = 1;
  GA_PLANNER_DistCrit_ArmorSmithy_Set               : Single = 1;
  GA_PLANNER_DistCrit_ArmorSmithy_Res               : Single = 1;
  GA_PLANNER_DistCrit_WeaponSmithy_Set              : Single = 1;
  GA_PLANNER_DistCrit_WeaponSmithy_Res              : Single = 1;
  GA_PLANNER_DistCrit_Tannery_Set                   : Single = 1;
  GA_PLANNER_DistCrit_ArmorWorkshop_Set             : Single = 1;
  GA_PLANNER_DistCrit_WeaponWorkshop_Set            : Single = 1;
  GA_PLANNER_DistCrit_Barracks_Set                  : Single = 1;

  GA_PLANNER_DistCrit_Bakery_Set                    : Single = 1;
  GA_PLANNER_DistCrit_Bakery_Res                    : Single = 1;
  GA_PLANNER_DistCrit_Butchers_Set                  : Single = 1;
  GA_PLANNER_DistCrit_Butchers_Res                  : Single = 1;
  GA_PLANNER_DistCrit_Mill_Set                      : Single = 1;
  GA_PLANNER_DistCrit_Mill_Res                      : Single = 1;
  GA_PLANNER_DistCrit_Swine_Set                     : Single = 1;
  GA_PLANNER_DistCrit_Swine_Res                     : Single = 1;
  GA_PLANNER_DistCrit_Stables_Set                   : Single = 1;
  GA_PLANNER_DistCrit_Stables_Res                   : Single = 1;
  GA_PLANNER_DistCrit_Farm_Set                      : Single = 1;
  GA_PLANNER_DistCrit_Farm_Res                      : Single = 1;
  GA_PLANNER_DistCrit_Wineyard_Set                  : Single = 1;
  GA_PLANNER_DistCrit_Wineyard_Res                  : Single = 1;

  GA_PLANNER_DistCrit_Metallurgists_Set             : Single = 1;
  GA_PLANNER_DistCrit_Metallurgists_Res             : Single = 1;
  GA_PLANNER_DistCrit_GoldMine_Set                  : Single = 1;
  GA_PLANNER_DistCrit_CoalMine_Set                  : Single = 1;
  GA_PLANNER_DistCrit_IronMine_Set                  : Single = 1;

  GA_PLANNER_DistCrit_Quary_Set                     : Single = 1;
  GA_PLANNER_DistCrit_Woodcutters_Set               : Single = 1;
  GA_PLANNER_DistCrit_Sawmill_Set                   : Single = 1;

  GA_PLANNER_FindPlaceForHouse_SnapCrit             : Single = 7.896635056;
  GA_PLANNER_FindPlaceForHouse_DistCrit             : Single = 8.259079933;
  GA_PLANNER_FindPlaceForQuary_SnapCrit             : Single = 2.169515848;
  GA_PLANNER_FindPlaceForQuary_DistCrit             : Single = 13.68480587;
  GA_PLANNER_FindPlaceForWoodcutter_BLOCK_RAD       : Single = 5;
  GA_PLANNER_FindPlaceForWoodcutter_DistCrit        : Single = 3.187745094;
  GA_PLANNER_FindPlaceForWoodcutter_TreeCnt         : Single = 20;
  GA_PLANNER_FindPlaceForWoodcutter_CanPlaceTreeCnt : Single = 0.180895254;
  GA_PLANNER_FindPlaceForWoodcutter_PlansAround     : Single = 13.12282181;

type
  TFindNearest = (fnHouse, fnSoil, fnWater, fnTrees, fnStone, fnCoal, fnIron, fnGold);       //ft_Corn,ft_Wine  ft_Road
  TPlanTiles = (pt_None, pt_House, pt_Road, pt_Wine, pt_Field);
  TPlanTiles2Array = array of array of TPlanTiles;
  THousePlan = record
    Placed, Exhausted, NearOwner: Boolean;  // EDIT
    Loc, SpecPoint: TKMPoint;
    Field: TKMPointTagList;
    House: TKMHouse;
    //TKMHouse.GetHousePointer: TKMHouse; TKMHouse.ReleaseHousePointer;
  end;
  TDirection = (dirN,dirE,dirS,dirW);
  THouseMaping = record
    Tiles: TKMPointArray;
    Surroundings: array[1..MAX_SCAN_DIST_FROM_HOUSE] of array[TDirection] of TKMPointArray;
    MoveToEntrance: array[TDirection] of TKMPoint;
  end;
  THouseMapingArray = array [HOUSE_MIN..HOUSE_MAX] of THouseMaping;
  TResourceTagArray = array [fnTrees..fnGold] of TKMPointTagList;
  TPlannedHousesArray = array [HOUSE_MIN..HOUSE_MAX] of array of THousePlan;

  // Terrain finder optimized for CityPlanner demands of finding resources and houses
  TKMTerrainFC = class(TKMTerrainFinderCommon)
  protected
    fOwner: TKMHandIndex;
    function CanWalkHere(const X,Y: Word): Boolean; override;
    function CanUse(const X,Y: Word): Boolean; override;
  public
    FindType: TFindNearest;
    HouseType: THouseType;
    constructor Create(aOwner: TKMHandIndex);
    procedure OwnerUpdate(aPlayer: TKMHandIndex);
    procedure Save(SaveStream: TKMemoryStream); override;
    procedure Load(LoadStream: TKMemoryStream); override;
  end;

  TPathFindingCityPlanner = class(TPathFindingRoad)
  private
    fPlanArr: TPlanTiles2Array;
  protected
    function IsWalkableTile(aX, aY: Word): Boolean; override;
    function MovementCost(aFromX, aFromY, aToX, aToY: Word): Word; override;
  public
    function Route_Make(aLocA, aLocB: TKMPoint; NodeList: TKMPointList; aPlanArr: TPlanTiles2Array): Boolean; reintroduce;
    //procedure Save(SaveStream: TKMemoryStream); override; // SAVE ADRESS OF POINTER TO ARRAY!!!!!!!!!!!
    //procedure Load(LoadStream: TKMemoryStream); override;
  end;

  // Create plan of city AfterMissionInit and update it during game (if it is required)
  TKMCityPlanner = class
  private
    fOwner: Byte;
    fPlanArr: TPlanTiles2Array;
    fPlannedHouses: TPlannedHousesArray;
    fResTagLists: TResourceTagArray;
    fFinder: TKMTerrainFC;
    fHouses: THouseMapingArray;
    fRoadPlanner: TPathFindingCityPlanner;

    procedure UpdatePlanArr();
    procedure FindPlaceForMines(aFindType: TFindNearest);
    procedure FindForests(aCenterPoints: TKMPointArray);
    function FindPlaceForWoodcutter(): Boolean;

    procedure AddPlan(aHT: THouseType; aLoc: TKMPoint); overload;
    procedure AddPlan(aHT: THouseType; aLoc: TKMPoint; aSpecPoint: TKMPoint); overload;
    function GetPlan(aHT: THouseType; out aLoc: TKMPoint; out aIdx: Integer): Boolean;
    procedure RemovePlan(aHT: THouseType; aIdx: Integer); overload;
    procedure RemovePlan(aHT: THouseType; aLoc: TKMPoint); overload;

    function CanAddHousePlan(aLoc: TKMPoint; aHT: THouseType; aIgnoreTrees: Boolean = False): Boolean;
    function FindPlaceForHouse(aHT: THouseType; out aBestLocs: TKMPointArray): Byte;
    procedure PlanFarmFields(aLoc: TKMPoint; var aNodeTagList: TKMPointTagList);
    procedure PlanWineFields(aLoc: TKMPoint; var aNodeTagList: TKMPointTagList);

    function SnapCrit(aHT: THouseType; aLoc: TKMPoint): Single;
    function DistCrit(aHT: THouseType; aLoc: TKMPoint): Single;
    function FieldCrit(aHT: THouseType; aLoc: TKMPoint): Single;

    procedure CreateSurroundingsTiles();
  public
    constructor Create(aPlayer: TKMHandIndex);
    destructor Destroy(); override;

    procedure AfterMissionInit();
    procedure OwnerUpdate(aPlayer: TKMHandIndex);
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

    function GetBlockingTrees(aHT: THouseType; aLoc: TKMPoint; var aTrees: TKMPointArray): Boolean;
    function GetBlockingFields(aHT: THouseType; aLoc: TKMPoint; var aFields: TKMPointArray): Boolean;

    // Properties for GA (in Runner)
    property Houses: THouseMapingArray read fHouses;
    property PlanArr: TPlanTiles2Array read fPlanArr;
    property ResTagLists: TResourceTagArray read fResTagLists;
    property PlannedHouses: TPlannedHousesArray read fPlannedHouses;

    procedure ScanLocResources(out aGoldMineCnt, aIronMineCnt, aFieldCnt, aBuildCnt: Integer);
    procedure CreateCityPlan(aHouses: TRequiredHousesArray);

    function CanPlaceHouse(aLoc: TKMPoint; aHT: THouseType; aIgnoreAvoidBuilding: Boolean = False; aIgnoreTrees: Boolean = False; aIgnorePlanArr: Boolean = False): Boolean;
    function GetHousePlan(aHT: THouseType; var aLoc: TKMPoint; var aIdx: Integer): Boolean;
    function GetRoadToHouse(aHT: THouseType; aIdx: Integer; var aField: TKMPointList; var aFieldType: TFieldType): Boolean;
    function GetRoadBetweenPoints(aStart, aEnd: TKMPoint; var aField: TKMPointList; var aFieldType: TFieldType): Boolean;
    function GetFieldToHouse(aHT: THouseType; aIdx: Integer; var aField: TKMPointList; var aFieldType: TFieldType): Boolean;
    function GetTreesInHousePlan(aHT: THouseType; aLoc: TKMPoint; var aField: TKMPointList): Boolean;

    procedure UpdateState(aTick: Cardinal);
    procedure Paint();
  end;



implementation
uses
  KM_Game, KM_HouseCollection, KM_HouseSchool, KM_HandsCollection, KM_Hand, KM_Terrain, KM_Resource,
  KM_AIFields, KM_Units, KM_UnitTaskDelivery, KM_UnitActionWalkTo, KM_UnitTaskGoEat, KM_UnitsCollection,
  KM_NavMesh, KM_HouseMarket, KM_CommonUtils,
  KM_RenderAux;






{ TKMCityPlanner }
constructor TKMCityPlanner.Create(aPlayer: TKMHandIndex);
var
  fnRes: TFindNearest;
begin
  fOwner := aPlayer;
  //fFinder := TKMTerrainFC.Create(fOwner);
  for fnRes := Low(fResTagLists) to High(fResTagLists) do
    fResTagLists[fnRes] := TKMPointTagList.Create;
  CreateSurroundingsTiles();
  fRoadPlanner := TPathFindingCityPlanner.Create(fOwner);
end;


destructor TKMCityPlanner.Destroy();
var
  I: Integer;
  fnRes: TFindNearest;
  HT: THouseType;
begin
  fFinder.Free;
  fRoadPlanner.Free;
  for fnRes := Low(fResTagLists) to High(fResTagLists) do
    fResTagLists[fnRes].Free;
  for HT := HOUSE_MIN to HOUSE_MAX do
    for I := Low(fPlannedHouses[HT]) to High(fPlannedHouses[HT]) do
      if (fPlannedHouses[HT,I].Field <> nil) then
        fPlannedHouses[HT,I].Field.Free;
  inherited;
end;


procedure TKMCityPlanner.AfterMissionInit();
  function GetSeeds(aHT: array of THouseType): TKMPointArray;
  var
    I, K: Integer;
    H: THouseType;
    Count, HQty: Integer;
    House: TKMHouse;
  begin
    Count := 0;
    for I := Low(aHT) to High(aHT) do
    begin
      H := aHT[I];
      HQty := gHands[fOwner].Stats.GetHouseQty(H);
      for K := 0 to Byte(H = ht_Any) * 2 do
      begin
        House := gHands[fOwner].Houses.FindHouse(H, 0, 0, KaMRandom(HQty) + 1);
        //House := gHands[fOwner].Houses.FindHouse(H, 0, 0, (HQty - KaMRandom(HQty div 2)));
        if (House <> nil) then
        begin
          SetLength(Result, Count + 1);
          Result[Count] := KMPointBelow(House.GetPosition);
          Exit;///EDIT THIS LINE!!!!!!!
          Inc(Count);
        end;
      end;
    end;
  end;
var
  HT: THouseType;
  fnRes: TFindNearest;
  SeedLocs: TKMPointArray;
begin
  // Check space with flood fill (maybe use influences?) and return count
  // Detect mines / resources
  // Draw snap area to farms (or maybe calc it universaly?)
  // Find mines just once after mission init
  fFinder := TKMTerrainFC.Create(fOwner); // MOVE INTO CREATE AFTER TEST IS DONE AND IS NOT PART OF MAP EDITOR !!!!!!!!!!!!!!!

  SetLength(fPlanArr, gTerrain.MapY+1, gTerrain.MapX+1);
  for HT := HOUSE_MIN to HOUSE_MAX do
    SetLength(fPlannedHouses[HT], gHands[fOwner].Stats.GetHouseQty(HT));
  UpdatePlanArr();

  SeedLocs := GetSeeds([ht_Store,ht_Any]);
  if (Length(SeedLocs) > 0) then
    for fnRes := fnStone to fnGold do
    begin
      fFinder.FindType := fnRes;
      fFinder.HouseType := ht_None;
      if (fnRes <> fnStone) then
      begin
        fFinder.FindNearest(SeedLocs, 200, [tpWalkRoad, tpMakeRoads], 1000, fResTagLists[fnRes]);
        fResTagLists[fnRes].SortByTag;
        FindPlaceForMines(fnRes);
      end
      else
      begin
        fFinder.FindNearest(SeedLocs, 200, [tpWalk], 1000, fResTagLists[fnRes]);
        fResTagLists[fnRes].SortByTag;
      end;
    end;
  FindForests(SeedLocs);

end;

procedure TKMCityPlanner.OwnerUpdate(aPlayer: TKMHandIndex);
begin
  fOwner := aPlayer;
  fFinder.OwnerUpdate(fOwner);
end;

procedure TKMCityPlanner.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.Write(fOwner);
  //fTagListGold.SaveToStream(SaveStream);

  fFinder.Save(SaveStream);
end;

procedure TKMCityPlanner.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.Read(fOwner);
  //fTagListGold.LoadFromStream(LoadStream);

  fFinder.Load(LoadStream);
  CreateSurroundingsTiles();
end;




procedure TKMCityPlanner.UpdateState(aTick: Cardinal);
var
  I,K: Integer;
  HT: THouseType;
  Loc: TKMPoint;
begin
  // ADD PRIORITY!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  for I := 0 to gHands[fOwner].Houses.Count - 1 do
  begin
    HT := gHands[fOwner].Houses[I].HouseType;
    Loc := gHands[fOwner].Houses[I].Entrance;
    for K := Low(fPlannedHouses[HT]) to High(fPlannedHouses[HT]) do
      if KMSamePoint(fPlannedHouses[HT,K].Loc, Loc) then
      begin
        //gHands[fOwner].Houses[I].IsComplete
        fPlannedHouses[HT,K].Placed := not gHands[fOwner].Houses[I].IsDestroyed;
        break;
      end;
  end;
end;


procedure TKMCityPlanner.AddPlan(aHT: THouseType; aLoc: TKMPoint);
begin
  AddPlan(aHT, aLoc, KMPOINT_ZERO); // Cannot declare KMPOINT_ZERO default value so overload method is used instead
end;

procedure TKMCityPlanner.AddPlan(aHT: THouseType; aLoc: TKMPoint; aSpecPoint: TKMPoint);
var
  X,Y,I: Integer;
begin
  SetLength(fPlannedHouses[aHT], Length(fPlannedHouses[aHT])+1); // EDIT IT
  with fPlannedHouses[aHT, High(fPlannedHouses[aHT])] do
  begin
    Exhausted := False;
    Placed := False;
    NearOwner := (gAIFields.Influences.GetBestOwner(aLoc.X, aLoc.Y) = fOwner);
    Loc := aLoc;
    SpecPoint := aSpecPoint;
    Field := nil;
    if (aHT = ht_Farm) then
    begin
      Field := TKMPointTagList.Create();
      PlanFarmFields(aLoc, Field);
    end
    else if (aHT = ht_Wineyard) then
    begin
      Field := TKMPointTagList.Create();
      PlanWineFields(aLoc, Field);
    end;
  end;
  for I := Low(fHouses[aHT].Tiles) to High(fHouses[aHT].Tiles) do
  begin
    X := aLoc.X + fHouses[aHT].Tiles[I].X;
    Y := aLoc.Y + fHouses[aHT].Tiles[I].Y;
    fPlanArr[Y,X] := pt_House;
  end;
end;


function TKMCityPlanner.GetPlan(aHT: THouseType; out aLoc: TKMPoint; out aIdx: Integer): Boolean;

  // Try find gold / iron in range of mine
  function IsExhaustedMine(aMineLoc: TKMPoint; aIsGold: Boolean): Boolean;
  var
    Y, X: Integer;
  begin
    Result := False;
    for X := Max(aMineLoc.X-4, 1) to Min(aMineLoc.X+3, gTerrain.MapX-1) do
    for Y := Max(aMineLoc.Y-8, 1) to aMineLoc.Y do
      if ( not aIsGold AND (gTerrain.TileIsIron(X, Y) > 0) )
          OR ( aIsGold AND (gTerrain.TileIsGold(X, Y) > 0) ) then
      Exit;
    Result := True;
  end;

  function IsExhaustedQuary(aQuaryLoc: TKMPoint): Boolean;
  var
    Y, X: Integer;
  const
    RADIUS = 6;
  begin
    Result := False;
    for Y := Max(aQuaryLoc.Y-RADIUS, 1) to Min(aQuaryLoc.Y+RADIUS, gTerrain.MapY-1) do
    for X := Max(aQuaryLoc.X-RADIUS, 1) to Min(aQuaryLoc.X+RADIUS, gTerrain.MapX-1) do
      if (gTerrain.TileIsStone(X, Y) > 1) then
        Exit;
    Result := True;
  end;

  function IsExhaustedCoalMine(aCoalLoc: TKMPoint): Boolean;
  var
    X,Y,I: Integer;
  begin
    Result := False;
    for I := Low(fHouses[ht_CoalMine].Tiles) to High(fHouses[ht_CoalMine].Tiles) do
    begin
      X := aCoalLoc.X + fHouses[ht_CoalMine].Tiles[I].X;
      Y := aCoalLoc.Y + fHouses[ht_CoalMine].Tiles[I].Y;
      if (gTerrain.TileIsCoal(X, Y) > 1) then
        Exit;
    end;
    Result := True;
  end;

  function CheckMine(aIdx: Integer): Boolean;
  begin
    case aHT of
      ht_GoldMine: fPlannedHouses[aHT,aIdx].Exhausted := fPlannedHouses[aHT,aIdx].Exhausted AND IsExhaustedMine(fPlannedHouses[aHT,aIdx].Loc, True);
      ht_IronMine: fPlannedHouses[aHT,aIdx].Exhausted := fPlannedHouses[aHT,aIdx].Exhausted AND IsExhaustedMine(fPlannedHouses[aHT,aIdx].Loc, False);
      ht_CoalMine: fPlannedHouses[aHT,aIdx].Exhausted := fPlannedHouses[aHT,aIdx].Exhausted AND IsExhaustedCoalMine(fPlannedHouses[aHT,aIdx].Loc);
      ht_Quary:    fPlannedHouses[aHT,aIdx].Exhausted := fPlannedHouses[aHT,aIdx].Exhausted AND IsExhaustedQuary(fPlannedHouses[aHT,aIdx].Loc);
      else
        begin
        end;
    end;
    Result := fPlannedHouses[aHT,aIdx].Exhausted;
  end;
var
  Output: Boolean;
  I: Integer;
begin
  Output := False;
  for I := Low(fPlannedHouses[aHT]) to High(fPlannedHouses[aHT]) do
    if not fPlannedHouses[aHT,I].Placed AND CanPlaceHouse(fPlannedHouses[aHT,I].Loc, aHT, True, True, True) then
    begin
      if (aHT in [ht_GoldMine, ht_IronMine, ht_CoalMine, ht_Quary]) AND CheckMine(I) then // Filter mines
        continue;
      aLoc := fPlannedHouses[aHT,I].Loc;
      aIdx := I;
      Output := True;
      break;
    end;
  Result := Output;
end;


procedure TKMCityPlanner.RemovePlan(aHT: THouseType; aIdx: Integer);
var
  X,Y,I: Integer;
begin
  if (aIdx > High(fPlannedHouses[aHT])) then
    Exit;
  fPlannedHouses[aHT,aIdx].Exhausted := True;
  for I := Low(fHouses[aHT].Tiles) to High(fHouses[aHT].Tiles) do
  begin
    X := fPlannedHouses[aHT,aIdx].Loc.X + fHouses[aHT].Tiles[I].X;
    Y := fPlannedHouses[aHT,aIdx].Loc.Y + fHouses[aHT].Tiles[I].Y;
    fPlanArr[Y,X] := pt_None;
  end;
end;

procedure TKMCityPlanner.RemovePlan(aHT: THouseType; aLoc: TKMPoint);
var
  Check: Boolean;
  X,Y,I: Integer;
begin
  Check := False;
  for I := Low(fPlannedHouses[aHT]) to High(fPlannedHouses[aHT]) do
    if KMSamePoint(fPlannedHouses[aHT,I].Loc,aLoc) then
    begin
      Check := True;
      break;
    end;
  if not Check then
    Exit;
  for I := Low(fHouses[aHT].Tiles) to High(fHouses[aHT].Tiles) do
  begin
    X := aLoc.X + fHouses[aHT].Tiles[I].X;
    Y := aLoc.Y + fHouses[aHT].Tiles[I].Y;
    fPlanArr[Y,X] := pt_None;
  end;
end;


function TKMCityPlanner.GetHousePlan(aHT: THouseType; var aLoc: TKMPoint; var aIdx: Integer): Boolean;
var
  Output: Boolean;
begin
  Output := False;
  if GetPlan(aHT, aLoc, aIdx) then
    Output := True;
  Result := Output;
end;


function TKMCityPlanner.GetRoadToHouse(aHT: THouseType; aIdx: Integer; var aField: TKMPointList; var aFieldType: TFieldType): Boolean;
var
  Output: Boolean;
  I: Integer;
  Loc: TKMPoint;
  H: TKMHouse;
begin
  Output := False;
  aFieldType := ft_Road;
  Loc := KMPointBelow(fPlannedHouses[aHT,aIdx].Loc);
  H := gHands[fOwner].Houses.FindHouse(ht_Any, Loc.X, Loc.Y, 1, True);
  if (H <> nil) AND fRoadPlanner.Route_Make(Loc, H.PointBelowEntrance, aField, fPlanArr) then
  begin
    Output := True;
    for I := 0 to aField.Count - 1 do
      fPlanArr[aField.Items[I].Y,aField.Items[I].X] := pt_Road;
  end;
  Result := Output;
end;


function TKMCityPlanner.GetRoadBetweenPoints(aStart, aEnd: TKMPoint; var aField: TKMPointList; var aFieldType: TFieldType): Boolean;
var
  Output: Boolean;
  I: Integer;
begin
  Output := False;
  aFieldType := ft_Road;
  if fRoadPlanner.Route_Make(aEnd, aStart, aField, fPlanArr) then
  begin
    Output := True;
    for I := 0 to aField.Count - 1 do
      fPlanArr[aField.Items[I].Y,aField.Items[I].X] := pt_Road;
  end;
  Result := Output;
end;


function TKMCityPlanner.GetFieldToHouse(aHT: THouseType; aIdx: Integer; var aField: TKMPointList; var aFieldType: TFieldType): Boolean;
  procedure CopyField(aMaxCnt: Integer; var aPlanField: TKMPointTagList);
  var
    I: Integer;
  begin
    for I := 0 to Min(aMaxCnt, aPlanField.Count - 1) do
      if not (fPlanArr[aPlanField.Items[I].Y,aPlanField.Items[I].X] in [pt_Road, pt_House]) then
        aField.Add(aPlanField.Items[I]);
  end;
const
  MAX_CORN_FIELDS = 31; // Real count of fields will be determined in CityBuilder
  MAX_WINE_FIELDS = 15;
var
  Output: Boolean;
  Field: TKMPointTagList;
begin
  Output := False;
  aField.Clear;
  Field := fPlannedHouses[aHT,aIdx].Field;
  if (Field <> nil) then
  begin
    Output := True;
    if (aHT = ht_Farm) then
    begin
      aFieldType := ft_Corn;
      CopyField(MAX_CORN_FIELDS, Field);
    end
    else if (aHT = ht_Wineyard) then
    begin
      Output := True;
      aFieldType := ft_Wine;
      CopyField(MAX_WINE_FIELDS, Field);
    end;
  end;
  Result := Output;
end;


function TKMCityPlanner.GetTreesInHousePlan(aHT: THouseType; aLoc: TKMPoint; var aField: TKMPointList): Boolean;
var
  I,X,Y: Integer;
begin
  aField.Clear;
  for I := Low(fHouses[aHT].Tiles) to High(fHouses[aHT].Tiles) do
  begin
    X := aLoc.X + fHouses[aHT].Tiles[I].X;
    Y := aLoc.Y + fHouses[aHT].Tiles[I].Y;
    if gTerrain.ObjectIsChopableTree(X, Y) then
      aField.Add(KMPoint(X,Y));
  end;
  Result := (aField.Count > 0);
end;


procedure TKMCityPlanner.ScanLocResources(out aGoldMineCnt, aIronMineCnt, aFieldCnt, aBuildCnt: Integer);
  function FindSeparateMines(aMineType: THouseType): Word;
  var
    I,K,X,Y, Output: Integer;
    InfluenceArr: array of Boolean;
  begin
    Output := 0;
    SetLength(InfluenceArr, Length(fPlannedHouses[aMineType]));
    for I := Low(InfluenceArr) to High(InfluenceArr) do
      InfluenceArr[I] := False;
    for I := Low(fPlannedHouses[aMineType]) to High(fPlannedHouses[aMineType]) do
    begin
      X := fPlannedHouses[aMineType,I].Loc.X;
      Y := fPlannedHouses[aMineType,I].Loc.Y;
      if (gAIFields.Influences.GetBestOwner(X, Y) = fOwner) then
      begin
        InfluenceArr[I] := True;
        Output := Output + 1;
        for K := Low(fPlannedHouses[aMineType]) to I-1 do
          if InfluenceArr[K] then
          begin
            if (fPlannedHouses[aMineType,K].Loc.Y <> fPlannedHouses[aMineType,I].Loc.Y)
              OR (  Abs(fPlannedHouses[aMineType,K].Loc.X - fPlannedHouses[aMineType,I].Loc.X) > (3 + Byte(aMineType = ht_IronMine)) ) then
              continue
            else
            begin
              Output := Output - 1;
              InfluenceArr[I] := False;
              break;
            end;
          end;
      end;
    end;
    Result := Output;
  end;
var
  X,Y: Integer;
begin
  aFieldCnt := 0;
  aBuildCnt := 0;
  for Y := 1 to gTerrain.MapY - 1 do
  for X := 1 to gTerrain.MapX - 1 do
    if (gAIFields.Influences.GetBestOwner(X, Y) = fOwner) then
    begin
      if not ([tpBuild] * gTerrain.Land[Y,X].Passability = []) then
        aBuildCnt := aBuildCnt + 1;
      if gHands[fOwner].CanAddFieldPlan(KMPoint(X,Y), ft_Corn) then
        aFieldCnt := aFieldCnt + 1;
    end;
  aIronMineCnt := FindSeparateMines(ht_IronMine);
  aGoldMineCnt := FindSeparateMines(ht_GoldMine);
end;


procedure TKMCityPlanner.CreateCityPlan(aHouses: TRequiredHousesArray);
  procedure PlanNewHouse(aHT: THouseType);
  var
    Cnt: Integer;
    BestLocs: TKMPointArray;
  begin
    aHouses[aHT] := aHouses[aHT] - 1;
    case aHT of
      ht_Woodcutters: FindPlaceForWoodcutter();
      ht_Quary: FindPlaceForMines(fnStone);
      ht_GoldMine, ht_CoalMine, ht_IronMine:
        begin
        end;
      else
      begin
        Cnt := FindPlaceForHouse(aHT, BestLocs);
        if Cnt > 0 then
          AddPlan(aHT, BestLocs[0]);
      end;
    end;
  end;

const
  ConstInitHouses: array[0..9] of THouseType = (
    ht_Store, ht_School, ht_Quary, ht_Quary, ht_Quary, ht_Quary, ht_Woodcutters, ht_Woodcutters, ht_Sawmill, ht_Inn
  );
  ConstCompleteCity: array[HOUSE_MIN..HOUSE_MAX] of Word = (
    2,4,2,1,2,7,12,0,3,3,2,2,2,2,2,6,3,2,0,1,1,4,2,0,0,1,3,3,6
  );
  PlanningOrder: array[0..22] of THouseType = (
    ht_Store,         ht_School,          ht_Inn,           ht_Butchers,      ht_Bakery,
    ht_Metallurgists, ht_Quary,           ht_Woodcutters,   ht_Sawmill,       ht_WeaponSmithy,
    ht_Tannery,       ht_WeaponWorkshop,  ht_Marketplace,
    ht_Mill,          ht_Swine,           ht_Stables,       ht_Farm,          ht_Wineyard,
    ht_FisherHut,
    ht_IronSmithy,    ht_ArmorSmithy,     ht_ArmorWorkshop, ht_Barracks
    //ht_GoldMine,        ht_CoalMine,        ht_IronMine,
    //ht_WatchTower, ht_SiegeWorkshop,   ht_TownHall
  );
var
  I: Integer;
begin
  {
  for HType := HOUSE_MIN to HOUSE_MAX do
    //aHouses[HType] := ConstCompleteCity[HType] - aHouses[HType] - gHands[fOwner].Stats.GetHouseQty(HType);
    aHouses[HType] := ConstCompleteCity[HType] - gHands[fOwner].Stats.GetHouseQty(HType);
  //}
  //{
  for I := Low(ConstInitHouses) to High(ConstInitHouses) do
    if aHouses[ ConstInitHouses[I] ] > 0 then
      PlanNewHouse(ConstInitHouses[I]);
  //}
  //{
  for I := Low(PlanningOrder) to High(PlanningOrder) do
    while (aHouses[ PlanningOrder[I] ] > 0) do
      PlanNewHouse(PlanningOrder[I]);
  //}
  {
  for HT := HOUSE_MIN to HOUSE_MAX do
    for I := Low(fPlannedHouses[HT]) to High(fPlannedHouses[HT]) do
      gHands[fOwner].AddHouse(HT, fPlannedHouses[HT, I].Loc.X, fPlannedHouses[HT, I].Loc.Y, True);
  for Y := 1 to gTerrain.MapY - 1 do
  for X := 1 to gTerrain.MapX - 1 do
    if (fPlanArr[Y,X] = pt_Wine) then
      gTerrain.SetField(KMPoint(X, Y), fOwner, ft_Wine)
    else if (fPlanArr[Y,X] = pt_Field) then
      gTerrain.SetField(KMPoint(X, Y), fOwner, ft_Corn);
  //}
end;


procedure TKMCityPlanner.UpdatePlanArr();
var
  X,Y,I,K: Integer;
  Houses: TKMHousesCollection;
  HType: THouseType;
  IdxArr: array [HOUSE_MIN..HOUSE_MAX] of Word;
begin
  for Y := Low(fPlanArr) to High(fPlanArr) do
    for X := Low(fPlanArr) to High(fPlanArr) do
      fPlanArr[Y,X] := pt_None;

  for HType := HOUSE_MIN to HOUSE_MAX do
    IdxArr[HType] := gHands[fOwner].Stats.GetHouseQty(HType);

  Houses := gHands[fOwner].Houses;
  for I := 0 to Houses.Count - 1 do
  begin
    HType := Houses[I].HouseType;
    Dec(IdxArr[HType], 1);
    fPlannedHouses[HType,IdxArr[HType]].Placed := True;
    fPlannedHouses[HType,IdxArr[HType]].Loc := Houses[I].Entrance;
    for K := Low(fHouses[HType].Tiles) to High(fHouses[HType].Tiles) do
    begin
      X := Houses[I].Entrance.X + fHouses[HType].Tiles[K].X;
      Y := Houses[I].Entrance.Y + fHouses[HType].Tiles[K].Y;
      fPlanArr[Y,X] := pt_House;
    end;
  end;

  {
  for Y := 1 to gTerrain.MapY do
  for X := 1 to gTerrain.MapX do
    if gTerrain.Land[Y,X].TileOverlay = to_Road then
      fPlanArr[Y,X] := pt_House
    else if gTerrain.TileIsWineField(KMPoint(X,Y))
    else if
  }
end;


function TKMCityPlanner.GetBlockingTrees(aHT: THouseType; aLoc: TKMPoint; var aTrees: TKMPointArray): Boolean;
var
  Output: Boolean;
  I,X,Y, TreeCnt: Integer;
begin
  Result := True;
  if (aHT in [ht_IronMine, ht_GoldMine, ht_CoalMine]) then
    Exit;

  SetLength(aTrees, Length(fHouses[aHT].Tiles));
  for I := Low(aTrees) to High(aTrees) do
    aTrees[I] := KMPOINT_ZERO;

  Output := True;
  TreeCnt := 0;
  for I := Low(fHouses[aHT].Tiles) to High(fHouses[aHT].Tiles) do
  begin
    X := aLoc.X + fHouses[aHT].Tiles[I].X;
    Y := aLoc.Y + fHouses[aHT].Tiles[I].Y;
    Output := Output AND (tpBuild in gTerrain.Land[Y,X].Passability);
    if gTerrain.ObjectIsChopableTree(X, Y) then
    begin
      aTrees[TreeCnt] := KMPoint(X,Y);
      TreeCnt := TreeCnt + 1;
    end;
    if not Output then
      break;
  end;
  Result := Output;
end;


function TKMCityPlanner.GetBlockingFields(aHT: THouseType; aLoc: TKMPoint; var aFields: TKMPointArray): Boolean;
var
  I,X,Y, FieldCnt: Integer;
begin
  Result := True;
  if (aHT in [ht_IronMine, ht_GoldMine, ht_CoalMine]) then
    Exit;

  SetLength(aFields, Length(fHouses[aHT].Tiles));
  for I := Low(aFields) to High(aFields) do
    aFields[I] := KMPOINT_ZERO;

  FieldCnt := 0;
  for I := Low(fHouses[aHT].Tiles) to High(fHouses[aHT].Tiles) do
  begin
    X := aLoc.X + fHouses[aHT].Tiles[I].X;
    Y := aLoc.Y + fHouses[aHT].Tiles[I].Y;
    aFields[FieldCnt] := KMPoint(X,Y);
    if     (gHands[fOwner].BuildList.FieldworksList.HasField(aFields[FieldCnt]) = ft_Wine)
        OR (gHands[fOwner].BuildList.FieldworksList.HasField(aFields[FieldCnt]) = ft_Corn) then
      FieldCnt := FieldCnt + 1;
  end;
  Result := (FieldCnt > 0);
end;


function TKMCityPlanner.CanAddHousePlan(aLoc: TKMPoint; aHT: THouseType; aIgnoreTrees: Boolean = False): Boolean;
var
  Output: Boolean;
  I,X,Y: Integer;
begin
  Output := True;
  for I := Low(fHouses[aHT].Tiles) to High(fHouses[aHT].Tiles) do
  begin
    X := aLoc.X + fHouses[aHT].Tiles[I].X;
    Y := aLoc.Y + fHouses[aHT].Tiles[I].Y;
    // Inset one tile from map edges
    Output := Output AND gTerrain.TileInMapCoords(X, Y, 1);
    // Mines have specific requirements
    case aHT of
      ht_IronMine: Output := Output AND gTerrain.TileGoodForIron(X, Y);
      ht_GoldMine: Output := Output AND gTerrain.CanPlaceGoldmine(X, Y);
      else         Output := Output AND (  (tpBuild in gTerrain.Land[Y,X].Passability) OR (aIgnoreTrees AND gTerrain.ObjectIsChopableTree(X, Y))  );
    end;
    if not Output then
      break;
  end;
  Result := Output;
end;


function TKMCityPlanner.CanPlaceHouse(aLoc: TKMPoint; aHT: THouseType; aIgnoreAvoidBuilding: Boolean = False; aIgnoreTrees: Boolean = False; aIgnorePlanArr: Boolean = False): Boolean;
var
  X, Y, I, K, PL: Integer;
  Dir: TDirection;
begin
  Result := False;

  // Check if we can place house on terrain, this also makes sure the house is
  // at least 1 tile away from map border (skip that below)
  if not CanAddHousePlan(aLoc, aHT, aIgnoreTrees) then
    Exit;

  // Scan tiles inside house plan
  for I := Low(fHouses[aHT].Tiles) to High(fHouses[aHT].Tiles) do
  begin
    X := aLoc.X + fHouses[aHT].Tiles[I].X;
    Y := aLoc.Y + fHouses[aHT].Tiles[I].Y;

    //Make sure we don't block existing roads
    //if gTerrain.CheckPassability(KMPoint(Tx, Ty), tpWalkRoad) then
    //  Exit;

    // Dont override existing plan
    if not aIgnorePlanArr AND (fPlanArr[Y,X] = pt_House) then
      Exit;

    // Check with AvoidBuilding array to secure that new house will not be build in forests / coal tiles
    if not aIgnoreAvoidBuilding then
      if (gAIFields.Influences.AvoidBuilding[Y, X] > 0) then
        Exit;

    //This tile must not contain fields/houseplans of allied players or self
    for PL := 0 to gHands.Count - 1 do
      if (gHands[fOwner].Alliances[PL] = at_Ally) then
        if (gHands[PL].BuildList.FieldworksList.HasField(KMPoint(X,Y)) <> ft_None) then
          Exit;
  end;

  // Scan tiles in distance 1 from house plan
  I := 1;
  if not (aHT in [ht_GoldMine, ht_IronMine]) then
    for Dir := Low(fHouses[aHT].Surroundings[I]) to High(fHouses[aHT].Surroundings[I]) do
    for K := Low(fHouses[aHT].Surroundings[I,Dir]) to High(fHouses[aHT].Surroundings[I,Dir]) do
    begin
      Y := aLoc.Y + fHouses[aHT].Surroundings[I,Dir,K].Y;
      X := aLoc.X + fHouses[aHT].Surroundings[I,Dir,K].X;
      // Dont place plan close to other houses
      if (fPlanArr[Y,X] = pt_House) then
        Exit;
      //Avoid placing houses in choke-points _/house\_ and make sure we can add road below house
      if (gTerrain.Land[Y,X].Passability * [tpMakeRoads, tpWalkRoad] = []) then
        Exit;
      // Surrounding tiles must not be a house
      for PL := 0 to gHands.Count - 1 do
        if (gHands[fOwner].Alliances[PL] = at_Ally) then
          if gHands[PL].BuildList.HousePlanList.HasPlan(KMPoint(X,Y)) then
            Exit;
    end;

  Result := True;
end;


procedure TKMCityPlanner.PlanWineFields(aLoc: TKMPoint; var aNodeTagList: TKMPointTagList);
const
  MAX_VINE = 10;
var
  I,Dist: Integer;
  Weight: Cardinal;
  Dir: TDirection;
  HT: THouseType;
  FieldLoc: TKMPoint;
begin
  HT := ht_Wineyard;
  for Dist := 1 to 4 do
  begin
    for Dir := Low(fHouses[HT].Surroundings[Dist]) to High(fHouses[HT].Surroundings[Dist]) do
    for I := Low(fHouses[HT].Surroundings[Dist,Dir]) to High(fHouses[HT].Surroundings[Dist,Dir]) do
    begin
      FieldLoc := KMPointAdd(aLoc, fHouses[HT].Surroundings[Dist,Dir,I]);
      if gTerrain.TileInMapCoords(FieldLoc.X, FieldLoc.Y)
        AND (fPlanArr[FieldLoc.Y,FieldLoc.X] = pt_None)
        AND gHands[fOwner].CanAddFieldPlan(FieldLoc, ft_Wine) then
      begin
        Weight := KMDistanceAbs(FieldLoc, aLoc) + (Dist shl 2);
        aNodeTagList.Add(FieldLoc, Weight);
      end;
    end;
    if (aNodeTagList.Count >= MAX_VINE) then
      break;
  end;
  aNodeTagList.SortByTag;
  for I := 0 to Min(aNodeTagList.Count, MAX_VINE) - 1 do
    fPlanArr[aNodeTagList.Items[I].Y,aNodeTagList.Items[I].X] := pt_Wine;
end;


procedure TKMCityPlanner.PlanFarmFields(aLoc: TKMPoint; var aNodeTagList: TKMPointTagList);
const
  MAX_VINE = 10;
var
  I,Dist: Integer;
  Weight: Cardinal;
  Dir: TDirection;
  HT: THouseType;
  FieldLoc: TKMPoint;
begin
  HT := ht_Farm;
  for Dist := 1 to 4 do
  begin
    for Dir := Low(fHouses[HT].Surroundings[Dist]) to High(fHouses[HT].Surroundings[Dist]) do
    for I := Low(fHouses[HT].Surroundings[Dist,Dir]) to High(fHouses[HT].Surroundings[Dist,Dir]) do
    begin
      FieldLoc := KMPointAdd(aLoc, fHouses[HT].Surroundings[Dist,Dir,I]);
      if gTerrain.TileInMapCoords(FieldLoc.X, FieldLoc.Y)
        AND (fPlanArr[FieldLoc.Y,FieldLoc.X] = pt_None)
        AND gHands[fOwner].CanAddFieldPlan(FieldLoc, ft_Corn) then
      begin
        Weight := KMDistanceAbs(FieldLoc, aLoc)
                  + Byte(Dir = dirN)*10 + Byte((Dir = dirW) OR (Dir = dirE))*5;
        aNodeTagList.Add(FieldLoc, Weight);
      end;
    end;
    //if (aNodeTagList.Count >= MAX_VINE) then
    //  break;
  end;
  aNodeTagList.SortByTag;
  for I := 0 to Min(aNodeTagList.Count, MAX_VINE) - 1 do
    fPlanArr[aNodeTagList.Items[I].Y,aNodeTagList.Items[I].X] := pt_Field;
end;


function TKMCityPlanner.SnapCrit(aHT: THouseType; aLoc: TKMPoint): Single;
var
  X,Y,I,Dist: Integer;
  Output: Single;
  Dir: TDirection;
begin
  Output := 0;
  Dist := 2;
  for Dir := Low(fHouses[aHT].Surroundings[Dist]) to High(fHouses[aHT].Surroundings[Dist]) do
  for I := Low(fHouses[aHT].Surroundings[Dist,Dir]) to High(fHouses[aHT].Surroundings[Dist,Dir]) do
  begin
    X := aLoc.X + fHouses[aHT].Surroundings[Dist,Dir,I].X;
    Y := aLoc.Y + fHouses[aHT].Surroundings[Dist,Dir,I].Y;
    Output := Output + Byte(fPlanArr[Y,X] = pt_House) * GA_PLANNER_SnapCrit_SnapToHouse + Byte(fPlanArr[Y,X] = pt_Road) * GA_PLANNER_SnapCrit_SnapToRoad;
  end;
  Result := Output;
end;


function TKMCityPlanner.DistCrit(aHT: THouseType; aLoc: TKMPoint): Single;
const
  MAX_BID = 1000000;

  function DistFromHouses(aHTs: array of THouseType): Single;
  var
    I,K: Integer;
    Output: Single;
  begin
    Output := 0;
    for I := Low(aHTs) to High(aHTs) do
    for K := Low(fPlannedHouses[ aHTs[I] ]) to Min(2, High(fPlannedHouses[ aHTs[I] ])) do
      Output := Output + KMDistanceAbs(aLoc, fPlannedHouses[ aHTs[I],K ].Loc);
    Result := Output;
  end;

  function DistFromHouse(aHTs: array of THouseType): Single;
  var
    I,K: Integer;
    Output, Bid, BestBid: Single;
  begin
    Output := MAX_BID;
    for I := Low(aHTs) to High(aHTs) do
    for K := Low(fPlannedHouses[ aHTs[I] ]) to Min(2, High(fPlannedHouses[ aHTs[I] ])) do
    begin
      Bid := KMDistanceAbs(aLoc, fPlannedHouses[ aHTs[I],K ].Loc);
      if (Bid < Output) then
        Output := Bid;
    end;
    if (Output = MAX_BID) then
      Output := 0;
    Result := Output;
  end;

  function DistFromResources(afnRes: array of TFindNearest): Single;
  var
    I,K: Integer;
    Output, Bid, BestBid: Single;
  begin
    Output := 0;
    for I := Low(afnRes) to High(afnRes) do
    begin
      BestBid := MAX_BID;
      for K := 0 to fResTagLists[afnRes[I]].Count-1 do
      begin
        Bid := KMDistanceAbs(aLoc, fResTagLists[afnRes[I]].Items[K]);
        if (Bid < BestBid) then
          BestBid := Bid;
      end;
      if not (BestBid = MAX_BID) then
        Output := Output + BestBid;
    end;
    Result := Output;
  end;
var
  Output: Single;
begin
  case aHT of
    ht_Store:          Output := + GA_PLANNER_DistCrit_Store * DistFromHouse([ht_Store]);
    ht_School:         Output := - GA_PLANNER_DistCrit_School * DistFromHouse([ht_Store,ht_Metallurgists]);
    ht_Inn:            Output := - GA_PLANNER_DistCrit_Inn_Store * DistFromHouse([ht_Store]) + GA_PLANNER_DistCrit_Inn_Inn * DistFromHouse([ht_Inn]);
    ht_Marketplace:    Output := - GA_PLANNER_DistCrit_Marketplace * DistFromHouse([ht_Store]);

    ht_IronSmithy:     Output := - GA_PLANNER_DistCrit_IronSmithy_Self * DistFromHouse([ht_IronSmithy]) - GA_PLANNER_DistCrit_IronSmithy_Res * DistFromHouse([ht_CoalMine, ht_IronMine]);
    ht_ArmorSmithy:    Output := - GA_PLANNER_DistCrit_ArmorSmithy_Set * DistFromHouse([ht_IronSmithy, ht_Barracks]) - GA_PLANNER_DistCrit_ArmorSmithy_Res * DistFromHouse([ht_CoalMine, ht_IronMine]);
    ht_WeaponSmithy:   Output := - GA_PLANNER_DistCrit_WeaponSmithy_Set * DistFromHouse([ht_IronSmithy, ht_Barracks]) - GA_PLANNER_DistCrit_WeaponSmithy_Res * DistFromHouse([ht_CoalMine, ht_IronMine]);
    ht_Tannery:        Output := - GA_PLANNER_DistCrit_Tannery_Set * DistFromHouse([ht_Swine, ht_WeaponWorkshop]);
    ht_ArmorWorkshop:  Output := - GA_PLANNER_DistCrit_ArmorWorkshop_Set * DistFromHouse([ht_Sawmill, ht_Barracks]);
    ht_WeaponWorkshop: Output := - GA_PLANNER_DistCrit_WeaponWorkshop_Set * DistFromHouse([ht_Tannery, ht_Barracks]);
    ht_Barracks:       Output := - GA_PLANNER_DistCrit_Barracks_Set * DistFromHouses([ht_ArmorSmithy, ht_ArmorWorkshop, ht_WeaponSmithy, ht_WeaponWorkshop]);

    ht_Bakery:         Output := - GA_PLANNER_DistCrit_Bakery_Set * DistFromHouses([ht_Store, ht_Inn, ht_Mill]) + GA_PLANNER_DistCrit_Bakery_Res * DistFromHouse([ht_IronMine, ht_GoldMine]);
    ht_Butchers:       Output := - GA_PLANNER_DistCrit_Butchers_Set * DistFromHouses([ht_Store, ht_Inn, ht_Swine]) + GA_PLANNER_DistCrit_Butchers_Res * DistFromHouse([ht_IronMine, ht_GoldMine]);
    ht_Mill:           Output := - GA_PLANNER_DistCrit_Mill_Set * DistFromHouses([ht_Farm, ht_Bakery]) + GA_PLANNER_DistCrit_Mill_Res * DistFromHouse([ht_IronMine, ht_GoldMine]);
    ht_Swine:          Output := - GA_PLANNER_DistCrit_Swine_Set * DistFromHouses([ht_Farm]) + GA_PLANNER_DistCrit_Swine_Res * DistFromHouse([ht_IronMine, ht_GoldMine]);
    ht_Stables:        Output := - GA_PLANNER_DistCrit_Stables_Set * DistFromHouses([ht_Farm]) + GA_PLANNER_DistCrit_Stables_Res * DistFromHouse([ht_IronMine, ht_GoldMine]);
    ht_Farm:           Output := - GA_PLANNER_DistCrit_Farm_Set * DistFromHouse([ht_Farm]) + GA_PLANNER_DistCrit_Farm_Res * DistFromHouse([ht_IronMine, ht_GoldMine]);
    ht_Wineyard:       Output := - GA_PLANNER_DistCrit_Wineyard_Set * DistFromHouse([ht_Inn]) + GA_PLANNER_DistCrit_Wineyard_Res * DistFromHouse([ht_IronMine, ht_GoldMine]);

    ht_Metallurgists:  Output := - GA_PLANNER_DistCrit_Metallurgists_Set * DistFromHouse([ht_School, ht_Store]) - GA_PLANNER_DistCrit_Metallurgists_Res * DistFromHouse([ht_GoldMine]);
    ht_GoldMine:       Output := - GA_PLANNER_DistCrit_GoldMine_Set * DistFromHouse([ht_Metallurgists]);
    ht_CoalMine:       Output := - GA_PLANNER_DistCrit_CoalMine_Set * DistFromHouse([ht_Metallurgists, ht_IronSmithy, ht_ArmorSmithy, ht_ArmorWorkshop]);
    ht_IronMine:       Output := - GA_PLANNER_DistCrit_IronMine_Set * DistFromHouse([ht_IronSmithy]);

    ht_Quary:          Output := - GA_PLANNER_DistCrit_Quary_Set * DistFromHouse([ht_Store]);
    ht_Woodcutters:    Output := - GA_PLANNER_DistCrit_Woodcutters_Set * DistFromHouse([ht_Store]); // EDIT
    ht_Sawmill:        Output := - GA_PLANNER_DistCrit_Sawmill_Set * DistFromHouse([ht_Woodcutters, ht_WeaponWorkshop]);
    else
      Output := 0;
  end;
  Result := Output;
end;


function TKMCityPlanner.FieldCrit(aHT: THouseType; aLoc: TKMPoint): Single;
  function GetCnt(aDist: Byte): Single;
  var
    X,Y,I: Integer;
    Output: Single;
    Dir: TDirection;
    HType: THouseType;
  begin
    Output := 0;
    HType := ht_Farm;
    for Dir := Low(fHouses[HType].Surroundings[aDist]) to High(fHouses[HType].Surroundings[aDist]) do
    for I := Low(fHouses[HType].Surroundings[aDist,Dir]) to High(fHouses[HType].Surroundings[aDist,Dir]) do
    begin
      X := aLoc.X + fHouses[HType].Surroundings[aDist,Dir,I].X;
      Y := aLoc.Y + fHouses[HType].Surroundings[aDist,Dir,I].Y;
      if gTerrain.TileInMapCoords(X,Y,1) AND gHands[fOwner].CanAddFieldPlan(KMPoint(X,Y), ft_Corn) then
        Output := Output + 1;
    end;
    Result := Output;
  end;
var
  C2,C3,C4: Single;
const
  MIN_CORN_FIELDS = 15;
  MIN_WINE_FIELDS = 9;
  DECREASE_CRIT = - 1000;
begin
  if (aHT = ht_Farm) then
  begin
    C2 := GetCnt(2);
    C3 := GetCnt(3);
    C4 := GetCnt(4);
    Result := DECREASE_CRIT * Byte(  (C2 + C3 + C4) < MIN_CORN_FIELDS  ) + C2 + C3 - C4
  end
  else if (aHT = ht_Wineyard) then
    Result := DECREASE_CRIT * Byte(  (GetCnt(1) + GetCnt(2)) < MIN_WINE_FIELDS  )
  else
    Result := 0;
end;


function TKMCityPlanner.FindPlaceForHouse(aHT: THouseType; out aBestLocs: TKMPointArray): Byte;
const
  BEST_PLANS_CNT = 5;
  INIT_BEST_BID = -1000000;
var
  I,K,L,Dist: Integer;
  Dir: TDirection;
  HType: THouseType;
  Loc: TKMPoint;
  Bid, POMBid: Single;
  BestBidArr: array[0..BEST_PLANS_CNT-1] of Single;
begin
  SetLength(aBestLocs, BEST_PLANS_CNT);
  for I := Low(BestBidArr) to High(BestBidArr) do
    BestBidArr[I] := INIT_BEST_BID;

  for HType := HOUSE_MIN to HOUSE_MAX do
  for I := 0 to Length(fPlannedHouses[HType])-1 do
  begin
    for Dist := 2 to MAX_SCAN_DIST_FROM_HOUSE do
    for Dir := Low(fHouses[HType].Surroundings[Dist]) to High(fHouses[HType].Surroundings[Dist]) do
    for K := Low(fHouses[HType].Surroundings[Dist,Dir]) to High(fHouses[HType].Surroundings[Dist,Dir]) do
    begin
      Loc := KMPointAdd(fPlannedHouses[HType,I].Loc, fHouses[HType].Surroundings[Dist,Dir,K], fHouses[aHT].MoveToEntrance[Dir]);
      if CanPlaceHouse(Loc, aHT, False, True) then
      begin
        Bid := + SnapCrit(aHT, Loc) * GA_PLANNER_FindPlaceForHouse_SnapCrit
               + DistCrit(aHT, Loc) * GA_PLANNER_FindPlaceForHouse_DistCrit
               - 100 * Byte(not fPlannedHouses[HType,I].NearOwner);
        if (aHT = ht_Farm) OR (aHT = ht_Wineyard) then
          Bid := Bid + FieldCrit(aHT, Loc);
        for L := Low(BestBidArr) to High(BestBidArr) do
          if KMSamePoint(Loc, aBestLocs[L]) then
            break
          else if (Bid > BestBidArr[L]) then
          begin
            KMSwapPoints(Loc, aBestLocs[L]);
            POMBid := BestBidArr[L];
            BestBidArr[L] := Bid;
            Bid := POMBid;
          end;
      end;
    end;
  end;
  for I := High(BestBidArr) downto Low(BestBidArr) do
    if (BestBidArr[I] <> INIT_BEST_BID) then
      break;
  Result := I;
end;


procedure TKMCityPlanner.FindPlaceForMines(aFindType: TFindNearest);
  // Save all mine locations
  procedure FindPlaceForMine(aHouse: THouseType; aTagPointList: TKMPointTagList);
  var
    I: Integer;
  begin
    for I := 0 to aTagPointList.Count - 1 do
      AddPlan(aHouse, aTagPointList.Items[I]);
  end;

  // Determine whether are coal tiles under coal mine plan in aCoalLoc
  function IsCoalUnderPlan(aCoalLoc: TKMPoint): Boolean;
  var
    Output: Boolean;
    X,Y,I: Integer;
  begin
    Output := True;
    for I := Low(fHouses[ht_CoalMine].Tiles) to High(fHouses[ht_CoalMine].Tiles) do
    begin
      X := aCoalLoc.X + fHouses[ht_CoalMine].Tiles[I].X;
      Y := aCoalLoc.Y + fHouses[ht_CoalMine].Tiles[I].Y;
      if not (gTerrain.TileIsCoal(X, Y) > 1) then
      begin
        Output := False;
        break;
      end;
    end;
    Result := Output;
  end;

  // Make coal mine network (mines with ideal distance 2 from each other = mine everything)
  procedure CoalMineNetwork(aBaseLoc: TKMPoint);
  var
    Check: Boolean;
    I,K,Dist: Integer;
    Loc: TKMPoint;
    Dir: TDirection;
  begin
    // Scan locs in distance 3 from aBaseLoc
    Dist := 3;
    for Dir := Low(fHouses[ht_CoalMine].Surroundings[Dist]) to High(fHouses[ht_CoalMine].Surroundings[Dist]) do
    for I := Low(fHouses[ht_CoalMine].Surroundings[Dist,Dir]) to High(fHouses[ht_CoalMine].Surroundings[Dist,Dir]) do
    begin
      Loc := KMPointAdd(aBaseLoc, fHouses[ht_CoalMine].Surroundings[Dist,Dir,I], fHouses[ht_CoalMine].MoveToEntrance[Dir]);
      gAIFields.Influences.AvoidBuilding[Loc.Y,Loc.X] := 155;
      if IsCoalUnderPlan(Loc) AND CanPlaceHouse(Loc, ht_CoalMine, True, False) then
      begin
        // Check whether is coal mine in distance 3 from other coal mines ...
        Check := True;
        for K := Low(fPlannedHouses[ht_CoalMine]) to High(fPlannedHouses[ht_CoalMine]) do
          if not (
               (Abs(fPlannedHouses[ht_CoalMine,K].Loc.X - Loc.X) > 4) OR
               (Abs(fPlannedHouses[ht_CoalMine,K].Loc.Y - Loc.Y) > 3)
             ) then
          begin
            Check := False;
            break;
          end;
        // ... if it is save new plan
        if Check then
        begin
          AddPlan(ht_CoalMine, Loc);
          CoalMineNetwork(Loc);
        end;
      end;
    end;
  end;

  // Coal mine planner
  procedure FindPlaceForCoalMine(aTagPointList: TKMPointTagList);
  var
    I: Integer;
  begin
    // For all coal tiles (in specific radius)
    for I := 0 to aTagPointList.Count - 1 do
      // Try place coal mine there and determine whether are coal tiles at least under house plan
      if IsCoalUnderPlan(aTagPointList.Items[I]) AND CanPlaceHouse(aTagPointList.Items[I], ht_CoalMine, True, False) then
      begin
        AddPlan(ht_CoalMine, aTagPointList.Items[I]);
        //CoalMineNetwork(aTagPointList.Items[I]);
      end;
  end;

  // Quarry planner
  procedure FindPlaceForQuary(aTagPointList: TKMPointTagList);
  const
    OVERFLOW = 10;
    OWNER_PENALIZATION = 50;
    SCAN_RAD = 6;
    USED_TILES_PER_A_MINE = 5;
    USED_TILE_PRICE = 5;
  var
    X,Y,I,K,L,Idx,POM,Dist, BestIdx, Counter: Integer;
    Bid, BestBid: Single;
    Loc, BestLoc: TKMPoint;
    ClosestIdxArr, ClosestValArr: array[1..USED_TILES_PER_A_MINE] of Integer;
  begin
    for Counter := 0 to OVERFLOW do
    begin
      // Find best points for Quary
      BestBid := High(Integer);
      for I := 0 to aTagPointList.Count - 1 do
      begin
        // Calculate criterium = distance from start search point (in initialization) + actual Tag2 (= used by other miners) + owner criterium
        Bid := aTagPointList.Tag[I] + aTagPointList.Tag2[I] + Byte(gAIFields.Influences.GetBestOwner(aTagPointList.Items[I].X, aTagPointList.Items[I].Y) <> fOwner) * OWNER_PENALIZATION;
        if (Bid < BestBid) then
        begin
          BestIdx := I;
          BestBid := Bid;
        end;
      end;

      // Exit procedure if we cannot find anything (should not happen)
      if BestBid = High(Integer) then
        Exit;

      // Find best loc for a Quary
      I := BestIdx;
      BestBid := High(Integer);
      for Y := Max(1,aTagPointList.Items[I].Y-SCAN_RAD) to Min(aTagPointList.Items[I].Y+SCAN_RAD,gTerrain.MapY-1) do
      for X := Max(1,aTagPointList.Items[I].X-SCAN_RAD) to Min(aTagPointList.Items[I].X+SCAN_RAD,gTerrain.MapX-1) do
      begin
        Loc := KMPoint(X,Y);
        if CanPlaceHouse(Loc, ht_Quary, False, False) then
        begin
          Bid := KMDistanceAbs(Loc, aTagPointList.Items[I]) * GA_PLANNER_FindPlaceForQuary_DistCrit - SnapCrit(ht_Quary, Loc) * GA_PLANNER_FindPlaceForQuary_SnapCrit;
          if (Bid < BestBid) then
          begin
            BestBid := Bid;
            BestLoc := Loc;
          end;
        end;
      end;

      // If there is not place remove point from list ...
      if (BestBid = High(Integer)) then
      begin
        aTagPointList.Delete(I);
        continue;
      end;
      // ... else add new plan
      AddPlan(ht_Quary, BestLoc);
      // Find closest tiles to the new loc and decrease price (Tag2)
      for K := Low(ClosestValArr) to High(ClosestValArr) do
      begin
        ClosestValArr[K] := High(Integer);
        ClosestIdxArr[K] := 0;
      end;
      for K := 0 to aTagPointList.Count - 1 do
        if (aTagPointList.Tag2[K] = 0) then
        begin
          Dist := KMDistanceAbs(Loc, aTagPointList.Items[K]);
          Idx := K;
          for L := Low(ClosestValArr) to High(ClosestValArr) do // Closest tiles are sorted (array of few elements so bubble is fast)
            if (Dist < ClosestValArr[L]) then
            begin
              POM := ClosestValArr[L];
              ClosestValArr[L] := Dist;
              Dist := ClosestValArr[L];
              POM := ClosestIdxArr[L];
              ClosestIdxArr[L] := Idx;
              Idx := POM;
            end;
        end;
      for K := Low(ClosestValArr) to High(ClosestValArr) do
        if (ClosestValArr[K] < High(Integer)) then
          aTagPointList.Tag2[ ClosestIdxArr[K] ] := aTagPointList.Tag2[ ClosestIdxArr[K] ] + USED_TILE_PRICE;
      Exit;
    end;
  end;

begin
  case aFindType of
    fnGold:  FindPlaceForMine(ht_GoldMine, fResTagLists[fnGold]);
    fnIron:  FindPlaceForMine(ht_IronMine, fResTagLists[fnIron]);
    fnCoal:  FindPlaceForCoalMine(fResTagLists[fnCoal]);
    fnStone: FindPlaceForQuary(fResTagLists[fnStone]);
    else
      begin
      end;
  end;
end;


function TKMCityPlanner.FindPlaceForWoodcutter(): Boolean;
const
  RADIUS = 8;
  MIN_BID = -100000;
  INC_USAGE = 150;
  SCAN_RAD = 4;
  // Find place for woodcutter
  function PlaceWoodcutter(aCenter: TKMPoint): Boolean;
  var
    Output: Boolean;
    X,Y: Integer;
    Bid, BestBid: Single;
    Loc, BestLoc: TKMPoint;
  begin
    Output := False;
    BestBid := MIN_BID;
    for Y := Max(1, aCenter.Y - RADIUS) to Min(gTerrain.MapY, aCenter.Y + RADIUS) do
    for X := Max(1, aCenter.X - RADIUS) to Min(gTerrain.MapX, aCenter.X + RADIUS) do
    begin
      Loc := KMPoint(X,Y);
      if CanPlaceHouse(Loc, ht_Woodcutters, False, False) then
      begin
        Bid := - KMDistanceAbs(aCenter, Loc) + DistCrit(ht_Woodcutters, Loc) + SnapCrit(ht_Woodcutters, Loc);
        if (Bid > BestBid) then
        begin
          BestBid := Bid;
          BestLoc := Loc;
        end;
      end;
    end;
    if (BestBid <> MIN_BID) then
    begin
      AddPlan(ht_Woodcutters, BestLoc, aCenter);
      Output := True;
    end;
    Result := Output;
  end;

  function FindPlansAround(aLoc: TKMPoint): Single;
  var
    X,Y: Integer;
    Output: Single;
  begin
    Output := 0;
    for Y := Max(1,aLoc.Y-SCAN_RAD) to Min(gTerrain.MapY,aLoc.Y+SCAN_RAD) do
    for X := Max(1,aLoc.X-SCAN_RAD) to Min(gTerrain.MapX,aLoc.X+SCAN_RAD) do
      if (fPlanArr[Y,X] <> pt_None) then
        Output := Output + 1;
    Result := Output;
  end;

var
  Output: Boolean;
  I, BestIdx: Integer;
  Bid, BestBid: Single;
  Forests: TKMPointTagList;
begin
  Output := False;
  Forests := fResTagLists[fnTrees];
  while not Output AND (Forests.Count > 0) do
  begin
    BestBid := MIN_BID;
    I := 0;
    while (I < Forests.Count) do
      if (gAIFields.Influences.AvoidBuilding[  Forests.Items[I].Y, Forests.Items[I].X  ] < 250) then
      begin
        Bid := + Forests.Tag[I] * GA_PLANNER_FindPlaceForWoodcutter_TreeCnt
               + Forests.Tag2[I] * GA_PLANNER_FindPlaceForWoodcutter_CanPlaceTreeCnt
               + DistCrit(ht_Woodcutters, Forests.Items[I]) * GA_PLANNER_FindPlaceForWoodcutter_DistCrit
               - FindPlansAround(Forests.Items[I]) * GA_PLANNER_FindPlaceForWoodcutter_PlansAround;
        if (Bid > BestBid) then
        begin
          BestBid := Bid;
          BestIdx := I;
        end;
        I := I + 1;
      end
      else
        Forests.Delete(I);
    if (BestBid <> MIN_BID) then
    begin
      Output := PlaceWoodcutter(Forests.Items[BestIdx]);
      if Output then
        gAIFields.Influences.AddAvoidBuilding(Forests.Items[BestIdx].X, Forests.Items[BestIdx].Y, GA_PLANNER_FindPlaceForWoodcutter_BLOCK_RAD, INC_USAGE)
      else
        Forests.Delete(BestIdx);
    end;
  end;
  Result := Output;
end;


procedure TKMCityPlanner.FindForests(aCenterPoints: TKMPointArray);
const
  MAX_DIST_TREES_IN_FOREST = 8;
  FOREST_RAD = 4;
var
  X,Y, I,K, BestIdx, Dist,MIN_Dist,MAX_Dist,MAX_DistIdx, Overflow: Integer;
  Trees, Forests: TKMPointTagList;
begin
  Forests := fResTagLists[fnTrees];
  Forests.Clear;
  Trees := TKMPointTagList.Create;
  try
    fFinder.FindType := fnTrees;
    fFinder.HouseType := ht_None;
    fFinder.FindNearest(aCenterPoints, 100, [tpWalkRoad, tpMakeRoads], 255, Trees);
    // MAX-MIN cluster algorithm (modification)
    if (Trees.Count > 0) then
    begin
      MAX_Dist := High(Integer);
      MAX_DistIdx := 0;
      Overflow := 0;
      while (MAX_Dist > MAX_DIST_TREES_IN_FOREST) AND (Overflow < 50) do
      begin
        Overflow := Overflow + 1;
        // If is maximal distance higher than specific constant create new cluster
        Forests.Add(Trees.Items[MAX_DistIdx], 0);
        MAX_Dist := 0;
        for I := 0 to Trees.Count - 1 do
        begin
          // Find MINimal distance between tree and clusters + save indexes
          MIN_Dist := High(Integer);
          for K := 0 to Forests.Count - 1 do
          begin
            Dist := KMDistanceAbs(Forests.Items[K], Trees.Items[I]);
            if (MIN_Dist > Dist) then
            begin
              MIN_Dist := Dist;
              BestIdx := K;
            end;
          end;
          Trees.Tag2[I] := BestIdx;
          // Find maximal distance from all minimal distances between tree and clusters
          if (MIN_Dist > MAX_Dist) then
          begin
            MAX_Dist := MIN_Dist;
            MAX_DistIdx := I;
          end;
        end;
      end;

      // Recalculate clusters centers (Forests.Tag1 = count of trees; Forests.Tag2 = tiles good for tree)
      // Final criterium may change during game so obtain only characteristics of each forest (at the start we need a forest as close as possible to the city and vice versa)
      for K := 0 to Forests.Count - 1 do
        Forests.Items[K] := KMPOINT_ZERO;
      for I := 0 to Trees.Count - 1 do
      begin
        Forests.Tag[ Trees.Tag2[I] ] := Forests.Tag[ Trees.Tag2[I] ] + 1;
        Forests.Items[ Trees.Tag2[I] ] := KMPointAdd(  Forests.Items[ Trees.Tag2[I] ], Trees.Items[I]  );
      end;
      for K := 0 to Forests.Count - 1 do
      begin
        Forests.Items[K] := KMPoint( Ceil(Forests.Items[K].X / (Forests.Tag[K]*1.0)), Ceil(Forests.Items[K].Y / (Forests.Tag[K]*1.0)) );

        for Y := Max(1, Forests.Items[K].Y - FOREST_RAD) to Min(gTerrain.MapY-1, Forests.Items[K].Y + FOREST_RAD) do
        for X := Max(1, Forests.Items[K].X - FOREST_RAD) to Min(gTerrain.MapX-1, Forests.Items[K].X + FOREST_RAD) do
          if gTerrain.TileGoodForTree(X, Y) then
            Forests.Tag2[K] := Forests.Tag2[K] + 1;
        // Debug
        //gAIFields.Influences.AvoidBuilding[Forests.Items[K].Y, Forests.Items[K].X] := 250; // Show center of cluster
      end;
    end;
  finally
    Trees.Free;
  end;
end;




// This SHOULD be global constant array (maybe save it into text file and rework it)
procedure TKMCityPlanner.CreateSurroundingsTiles();
var
  EnterOff: ShortInt;
  House: THouseType;
  POMArr: array[1-MAX_SCAN_DIST_FROM_HOUSE..4+MAX_SCAN_DIST_FROM_HOUSE,1-MAX_SCAN_DIST_FROM_HOUSE..4+MAX_SCAN_DIST_FROM_HOUSE] of Byte;
  CntArr, Index: array [TDirection] of Integer;

  procedure SearchAndFill(const aIdx: Integer; aFill: Boolean = False);
  var
    PointAdded: Boolean;
    X,Y: Integer;
    Dir: TDirection;
  begin
    for dir := Low(CntArr) to High(CntArr) do
      CntArr[dir] := 0;

    for Y := 1-aIdx to 4+aIdx do
    for X := 1-aIdx to 4+aIdx do
      if (POMArr[Y,X] = aIdx) then
      begin
        PointAdded := False;
        if (X = Index[dirW]-aIdx) then
        begin
          PointAdded := True;
          if aFill then
            fHouses[House].Surroundings[aIdx,dirW,CntArr[dirW]] := KMPoint(X - 3 - EnterOff, Y - 4);
          Inc(CntArr[dirW],1);
        end
        else if (X = Index[dirE]+aIdx) then
        begin
          PointAdded := True;
          if aFill then
            fHouses[House].Surroundings[aIdx,dirE,CntArr[dirE]] := KMPoint(X - 3 - EnterOff, Y - 4);
          Inc(CntArr[dirE],1);
        end;
        if (Y = Index[dirS]+aIdx) then
        begin
          if aFill then
            fHouses[House].Surroundings[aIdx,dirS,CntArr[dirS]] := KMPoint(X - 3 - EnterOff, Y - 4);
          Inc(CntArr[dirS],1);
        end
        else if not PointAdded OR (Y = Index[dirN]-aIdx) then // Plans with cutted top corners
        begin
          if aFill then
            fHouses[House].Surroundings[aIdx,dirN,CntArr[dirN]] := KMPoint(X - 3 - EnterOff, Y - 4);
          Inc(CntArr[dirN],1);
        end;
      end;
    if not aFill then
      for dir := Low(CntArr) to High(CntArr) do
        SetLength(fHouses[House].Surroundings[aIdx,dir], CntArr[dir]);
  end;

var
  I, X,Y,aX,aY, ActualIdx, Cnt: Integer;
  HA: THouseArea;
begin
  for House := HOUSE_MIN to HOUSE_MAX do
  begin
    EnterOff := gRes.Houses[House].EntranceOffsetX;

    // Init POMArr with value 255;
    for Y := Low(POMArr) to High(POMArr) do
    for X := Low(POMArr[Y]) to High(POMArr[Y]) do
      POMArr[Y,X] := 255;

    // Find house plan and save its shape into POMArr
    HA := gRes.Houses[House].BuildArea;
    Cnt := 0;
    for Y := 1 to 4 do
    for X := 1 to 4 do
      if (HA[Y,X] <> 0) then
      begin
        POMArr[Y,X] := 0;
        Inc(Cnt,1);
      end;

    // Save vectors from entrance to each tile which is in house plan
    SetLength(fHouses[House].Tiles, Cnt);
    Cnt := 0;
    for Y := 1 to 4 do
    for X := 1 to 4 do
      if (POMArr[Y,X] = 0) then
      begin
        fHouses[House].Tiles[Cnt] := KMPoint(X - 3 - EnterOff, Y - 4);
        Inc(Cnt);
      end;

    // Create around the house plan layers of increasing values in dependence on distance from the plan
    for I := 1 to MAX_SCAN_DIST_FROM_HOUSE do
    begin
      ActualIdx := I-1;
      for Y := 1-ActualIdx to 4+ActualIdx do
      for X := 1-ActualIdx to 4+ActualIdx do
        if (POMArr[Y,X] = ActualIdx) then
          for aY := -1 to 1 do
          for aX := -1 to 1 do
            if (POMArr[Y+aY,X+aX] > I) then
              POMArr[Y+aY,X+aX] := I;
    end;

    // Calculate size of plan
    Index[dirN] := 3 - Byte(POMArr[2,2] = 0) - Byte(POMArr[1,2] = 0);
    Index[dirS] := 4;
    Index[dirW] := 2 - Byte(POMArr[4,1] = 0);
    Index[dirE] := 3 + Byte(POMArr[4,4] = 0);

    // Get entrance with respect to array HA
    for X := 1 to 4 do
      if (HA[4,X] = 2) then
        break;
    fHouses[House].MoveToEntrance[dirN] := KMPoint(0, 0);
    fHouses[House].MoveToEntrance[dirS] := KMPoint(0, 4 - Index[dirN]);
    fHouses[House].MoveToEntrance[dirW] := KMPoint(X - Index[dirE], 0);
    fHouses[House].MoveToEntrance[dirE] := KMPoint(X - Index[dirW], 0);

    // Fill fHousesSurroundings
    for I := 1 to MAX_SCAN_DIST_FROM_HOUSE do
    begin
      SearchAndFill(I, False);
      SearchAndFill(I, True);
    end;

  end;
end;


procedure TKMCityPlanner.Paint();
const
  COLOR_WHITE = $80FFFFFF;
  COLOR_BLACK = $80000000;
  COLOR_GREEN = $8000FF00;
  COLOR_RED = $800000FF;
  COLOR_YELLOW = $8000FFFF;
  COLOR_GREEN_Field = $AA00FF00;
  COLOR_GREEN_Wine = $AA55FFFF;
  COLOR_BLUE = $80FF0000;
var
  I,K: Integer;
  HT: THouseType;
  Loc: TKMPoint;
  Color: Cardinal;
  Field: TKMPointList;
  FieldType: TFieldType;
begin
  Field := TKMPointList.Create();
  try
    for HT := HOUSE_MIN to HOUSE_MAX do
    begin
      case HT of
        ht_Store,ht_School,ht_Inn,ht_Marketplace: Color := COLOR_BLACK;
        ht_Quary,ht_Woodcutters,ht_Sawmill: Color := COLOR_BLUE;
        ht_GoldMine,ht_CoalMine,ht_IronMine,ht_Metallurgists: Color := COLOR_YELLOW;
        ht_IronSmithy,ht_ArmorSmithy,ht_WeaponSmithy,ht_Tannery,ht_ArmorWorkshop,ht_WeaponWorkshop,ht_Barracks: Color := COLOR_RED;
        ht_Bakery,ht_Butchers,ht_Mill,ht_Swine,ht_Stables,ht_Farm,ht_Wineyard: Color := COLOR_GREEN;
        else Color := COLOR_WHITE;
      end;
      for I := 0 to Length(fPlannedHouses[HT])-1 do
      begin
        for K := 0 to Length(fHouses[HT].Tiles)-1 do
        begin
          Loc := KMPointAdd(fPlannedHouses[HT,I].Loc, fHouses[HT].Tiles[K]);
          gRenderAux.Quad(Loc.X, Loc.Y, Color);
        end;
        if (HT = ht_Farm) then
        begin
          Color := COLOR_GREEN_Field;
          if GetFieldToHouse(HT, I, Field, FieldType) then
            for K := 0 to Field.Count-1 do
              gRenderAux.Quad(Field.Items[K].X, Field.Items[K].Y, Color);
        end
        else if (HT = ht_Wineyard) then
        begin
          Color := COLOR_GREEN_Wine;
          if GetFieldToHouse(HT, I, Field, FieldType) then
            for K := 0 to Field.Count-1 do
              gRenderAux.Quad(Field.Items[K].X, Field.Items[K].Y, Color);
        end;
      end;
    end;
    //fPlanArr[aNodeTagList.Items[I].Y,aNodeTagList.Items[I].X] := pt_Field;

  finally
    Field.Free;
  end;
end;




{ TPathFindingCityPlanner }
function TPathFindingCityPlanner.IsWalkableTile(aX, aY: Word): Boolean;
begin
  Result := (fPlanArr[aY,aX] <> pt_House) AND inherited;
end;


function TPathFindingCityPlanner.MovementCost(aFromX, aFromY, aToX, aToY: Word): Word;
var
  IsRoad: Boolean;
  X,Y: SmallInt;
begin
  Result := 0;
  IsRoad := (tpWalkRoad in gTerrain.Land[aToY, aToX].Passability)
            //or (gHands[fOwner].BuildList.FieldworksList.HasField(KMPoint(aToX, aToY)) = ft_Road)
            or (gTerrain.Land[aToY, aToX].TileLock = tlRoadWork);

  // Snap to no-build areas (1 tile from house)
  if not IsRoad then
    for Y := Max(0,aToY-1) to Min(gTerrain.MapY, aToY+1) do
    for X := Max(0,aToX-1) to Min(gTerrain.MapX, aToX+1) do
      if (fPlanArr[Y,X] <> pt_House) then
        Result := Result + 5;

  //Building roads over fields is discouraged unless unavoidable
  if gTerrain.TileIsCornField(KMPoint(aToX, aToY))
  or gTerrain.TileIsWineField(KMPoint(aToX, aToY))
  or (gAIFields.Influences.AvoidBuilding[aToY, aToX] > 0)
  or (fPlanArr[aToY,aToX] = pt_Wine)
  or (fPlanArr[aToY,aToX] = pt_Field) then // Don't build road through forest
    Inc(Result, 60); //60 points equals to 6 tiles penalty
end;


function TPathFindingCityPlanner.Route_Make(aLocA, aLocB: TKMPoint; NodeList: TKMPointList; aPlanArr: TPlanTiles2Array): Boolean;
begin
  fPlanArr := aPlanArr;
  Result := inherited Route_Make(aLocA, aLocB, NodeList);
end;







{ TKMTerrainFC }
constructor TKMTerrainFC.Create(aOwner: TKMHandIndex);
begin
  inherited Create;

  fOwner := aOwner;
end;


procedure TKMTerrainFC.OwnerUpdate(aPlayer: TKMHandIndex);
begin
  fOwner := aPlayer;
end;


function TKMTerrainFC.CanUse(const X, Y: Word): Boolean;
var
  I, K: Integer;
begin
  case FindType of
    fnTrees:  Result := gTerrain.ObjectIsChopableTree(X, Y) AND (gAIFields.Influences.AvoidBuilding[Y,X] < 255);

    fnStone:  Result := (gTerrain.TileIsStone(X, Max(Y-1, 1)) > 1);

    fnCoal:   Result := (gTerrain.TileIsCoal(X, Y) > 1);

    fnIron:   begin
                Result := gHands[fOwner].CanAddHousePlanAI(X, Y, ht_IronMine, False);
                //If we can build a mine here then search for ore
                if Result then
                  for I:=Max(X-4, 1) to Min(X+3, gTerrain.MapX-1) do
                    for K:=Max(Y-8, 1) to Y do
                      if (gTerrain.TileIsIron(I, K) > 0) then
                        Exit;
                Result := False; //Didn't find any ore
              end;

    fnGold:   begin
                Result := gHands[fOwner].CanAddHousePlanAI(X, Y, ht_GoldMine, False);
                //If we can build a mine here then search for ore
                if Result then
                  for I:=Max(X-4, 1) to Min(X+4, gTerrain.MapX-1) do
                    for K:=Max(Y-8, 1) to Y do
                      if (gTerrain.TileIsGold(I, K) > 0) then
                        Exit;
                Result := False; //Didn't find any ore
              end;

    else      Result := False;
  end;
end;


function TKMTerrainFC.CanWalkHere(const X,Y: Word): Boolean;
begin
  //Check for specific passabilities
  case FindType of
    fnIron:   Result := (fPassability * gTerrain.Land[Y,X].Passability <> [])
                        or gTerrain.TileGoodForIron(X, Y);

    fnGold:   Result := (fPassability * gTerrain.Land[Y,X].Passability <> [])
                        or gTerrain.TileGoodForGoldmine(X, Y);

    else      Result := (fPassability * gTerrain.Land[Y,X].Passability <> []);
  end;
end;


procedure TKMTerrainFC.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fOwner);
end;


procedure TKMTerrainFC.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.Read(fOwner);
end;

end.

