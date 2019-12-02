unit KM_AICityPlanner;
{$I KaM_Remake.inc}
interface
uses
  KM_TerrainFinder,
  KM_ResHouses, KM_ResWares,
  KM_CommonClasses, KM_Defaults, KM_Points;


type
  TFindNearest = (fnHouse, fnStone, fnTrees, fnSoil, fnWater, fnCoal, fnIron, fnGold);

  //Terrain finder optimized for CityPlanner demands of finding resources and houses
  TKMTerrainFinderCity = class(TKMTerrainFinderCommon)
  protected
    fOwner: TKMHandID;
    function CanWalkHere(const X,Y: Word): Boolean; override;
    function CanUse(const X,Y: Word): Boolean; override;
  public
    FindType: TFindNearest;
    HouseType: TKMHouseType;
    constructor Create(aOwner: TKMHandID);
    procedure OwnerUpdate(aPlayer: TKMHandID);
    procedure Save(SaveStream: TKMemoryStream); override;
    procedure Load(LoadStream: TKMemoryStream); override;
  end;

  TKMCityPlanner = class
  private
    fOwner: TKMHandID;
    fListGold: TKMPointList; //List of possible goldmine locations
    fFinder: TKMTerrainFinderCity;

    function GetSeeds(aHouseType: array of TKMHouseType): TKMPointArray;

    function NextToOre(aHouse: TKMHouseType; aOreType: TKMWareType; out aLoc: TKMPoint; aNearAnyHouse: Boolean = False): Boolean;
    function NextToHouse(aHouse: TKMHouseType; aSeed, aAvoid: array of TKMHouseType; out aLoc: TKMPoint): Boolean;
    function NextToStone(aHouse: TKMHouseType; out aLoc: TKMPoint): Boolean;
    function NextToTrees(aHouse: TKMHouseType; aSeed: array of TKMHouseType; out aLoc: TKMPoint): Boolean;
    function NextToGrass(aHouse: TKMHouseType; aSeed: array of TKMHouseType; out aLoc: TKMPoint): Boolean;
  public
    constructor Create(aPlayer: TKMHandID);
    destructor Destroy; override;

    procedure AfterMissionInit;

    function FindNearest(const aStart: TKMPoint; aRadius: Byte; aType: TFindNearest; out aResultLoc: TKMPoint): Boolean; overload;
    procedure FindNearest(const aStart: TKMPointArray; aRadius: Byte; aType: TFindNearest; aPass: TKMTerrainPassabilitySet; aMaxCount: Word; aLocs: TKMPointTagList); overload;
    procedure FindNearest(const aStart: TKMPointArray; aRadius: Byte; aHouse: TKMHouseType; aMaxCount: Word; aLocs: TKMPointTagList); overload;
    function FindPlaceForHouse(aHouse: TKMHouseType; out aLoc: TKMPoint): Boolean;
    procedure OwnerUpdate(aPlayer: TKMHandID);
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
  end;


const
  AI_FIELD_HEIGHT = 3;
  AI_FIELD_WIDTH = 4;
  AI_FIELD_MAX_AREA = (AI_FIELD_WIDTH * 2 + 1) * AI_FIELD_HEIGHT;


implementation
uses
  Math,
  KM_Hand, KM_AIFields, KM_AIInfluences,
  KM_Terrain, KM_HandsCollection,
  KM_Resource, KM_ResUnits, KM_NavMesh,
  KM_Houses, KM_CommonUtils, KM_CommonTypes;


{ TKMCityPlanner }
constructor TKMCityPlanner.Create(aPlayer: TKMHandID);
begin
  inherited Create;
  fOwner := aPlayer;
  fFinder := TKMTerrainFinderCity.Create(fOwner);

  fListGold := TKMPointList.Create;
end;


destructor TKMCityPlanner.Destroy;
begin
  fListGold.Free;
  fFinder.Free;

  inherited;
end;


function TKMCityPlanner.FindPlaceForHouse(aHouse: TKMHouseType; out aLoc: TKMPoint): Boolean;
begin
  Result := False;

  case aHouse of
    htStore:           Result := NextToHouse(aHouse, [htAny], [htStore], aLoc);
    htArmorSmithy:     Result := NextToHouse(aHouse, [htIronSmithy, htCoalMine, htBarracks], [], aLoc);
    htArmorWorkshop:   Result := NextToHouse(aHouse, [htTannery, htBarracks], [], aLoc);
    htBakery:          Result := NextToHouse(aHouse, [htMill], [], aLoc);
    htBarracks:        Result := NextToHouse(aHouse, [htAny], [], aLoc);
    htWatchTower:      Result := NextToHouse(aHouse, [htBarracks], [], aLoc);
    htButchers:        Result := NextToHouse(aHouse, [htSwine], [], aLoc);
    htInn:             Result := NextToHouse(aHouse, [htAny], [htInn], aLoc);
    htIronSmithy:      Result := NextToHouse(aHouse, [htIronMine, htCoalMine], [], aLoc);
    htMetallurgists:   Result := NextToHouse(aHouse, [htGoldMine], [], aLoc);
    htMill:            Result := NextToHouse(aHouse, [htFarm], [], aLoc);
    htSawmill:         Result := NextToHouse(aHouse, [htWoodcutters], [], aLoc);
    htSchool:          Result := NextToHouse(aHouse, [htStore, htBarracks], [], aLoc);
    htStables:         Result := NextToHouse(aHouse, [htFarm], [], aLoc);
    htSwine:           Result := NextToHouse(aHouse, [htFarm], [], aLoc);
    htTannery:         Result := NextToHouse(aHouse, [htSwine], [], aLoc);
    htWeaponSmithy:    Result := NextToHouse(aHouse, [htIronSmithy, htCoalMine, htBarracks], [], aLoc);
    htWeaponWorkshop:  Result := NextToHouse(aHouse, [htSawmill, htBarracks], [], aLoc);

    htCoalMine:      Result := NextToOre(aHouse, wtCoal, aLoc);
    htGoldMine:      Result := NextToOre(aHouse, wtGoldOre, aLoc);
    htIronMine:      Result := NextToOre(aHouse, wtIronOre, aLoc);

    htQuary:         Result := NextToStone(aHouse, aLoc);
    htWoodcutters:   Result := NextToTrees(aHouse, [htStore, htWoodcutters, htSawmill], aLoc);
    htFarm:          Result := NextToGrass(aHouse, [htAny], aLoc);
    htWineyard:      Result := NextToGrass(aHouse, [htAny], aLoc);
    htFisherHut:     {Result := NextToWater(aHouse, aLoc)};

    //htMarketplace:;
    //htSiegeWorkshop:;
    //htTownHall:;
    //htWatchTower:;
  end;

  //If we failed to find something, try to place the house anywhere (better than ignoring it)
  if not Result and not (aHouse in [htCoalMine, htGoldMine, htIronMine, htQuary, htFarm, htWineyard, htFisherHut]) then
    Result := NextToHouse(aHouse, [htAny], [], aLoc);
end;


//Receive list of desired house types
//Output list of locations below these houses
function TKMCityPlanner.GetSeeds(aHouseType: array of TKMHouseType): TKMPointArray;
var
  I, K: Integer;
  H: TKMHouseType;
  Count, HQty: Integer;
  House: TKMHouse;
begin
  Count := 0;
  SetLength(Result, Count);

  for I := Low(aHouseType) to High(aHouseType) do
  begin
    H := aHouseType[I];
    HQty := gHands[fOwner].Stats.GetHouseQty(H);
    //htAny picks three random houses for greater variety
    for K := 0 to 1 + Byte(H = htAny) * 2 do
    begin
      House := gHands[fOwner].Houses.FindHouse(H, 0, 0, KaMRandom(HQty, 'TKMCityPlanner.GetSeeds') + 1);
      if House <> nil then
      begin
        SetLength(Result, Count + 1);
        //Position is as good as Entrance for city planning
        Result[Count] := KMPointBelow(House.Position);
        Inc(Count);
      end;
    end;
  end;
end;


procedure TKMCityPlanner.AfterMissionInit;
var
  I,K: Integer;
begin
  //Mark all spots where we could possibly place a goldmine
  //some smarter logic can clip left/right edges later on?
  for I := 1 to gTerrain.MapY - 2 do
  for K := 1 to gTerrain.MapX - 2 do
  if gTerrain.TileGoodForGoldmine(K,I) then
    fListGold.Add(KMPoint(K,I));
end;


function TKMCityPlanner.NextToGrass(aHouse: TKMHouseType; aSeed: array of TKMHouseType; out aLoc: TKMPoint): Boolean;
  function CanPlaceHouse(aHouse: TKMHouseType; aX, aY: Word): Boolean;
  var
    I, K: Integer;
    FieldCount: Integer;
  begin
    Result := False;
    if gHands[fOwner].CanAddHousePlanAI(aX, aY, aHouse, True) then
    begin
      FieldCount := 0;
      for I := Min(aY - 2, gTerrain.MapY - 1) to Max(aY + 2 + AI_FIELD_HEIGHT - 1, 1) do
      for K := Max(aX - AI_FIELD_WIDTH, 1) to Min(aX + AI_FIELD_WIDTH, gTerrain.MapX - 1) do
      if gHands[fOwner].CanAddFieldPlan(KMPoint(K,I), ftCorn)
      //Skip fields within actual house areas
      and ((aHouse <> htFarm)     or not InRange(I, aY-2, aY) or not InRange(K, aX-1, aX+2))
      and ((aHouse <> htWineyard) or not InRange(I, aY-1, aY) or not InRange(K, aX-2, aX)) then
      begin
        Inc(FieldCount);
        //Request slightly more than we need to have a good choice
        if FieldCount >= Min(AI_FIELD_MAX_AREA, IfThen(aHouse = htFarm, 16, 10)) then
        begin
          Result := True;
          Exit;
        end;
      end;
    end;
  end;
var
  I, K, J: Integer;
  Bid, BestBid: Single;
  SeedLocs: TKMPointArray;
  S: TKMPoint;
begin
  Result := False;
  Assert(aHouse in [htFarm, htWineyard]);

  SeedLocs := GetSeeds(aSeed);

  BestBid := MaxSingle;
  for J := Low(SeedLocs) to High(SeedLocs) do
  begin
    S := SeedLocs[J];
    for I := Max(S.Y - 7, 1) to Min(S.Y + 6, gTerrain.MapY - 1) do
    for K := Max(S.X - 7, 1) to Min(S.X + 7, gTerrain.MapX - 1) do
    if CanPlaceHouse(aHouse, K, I) then
    begin
      Bid := KMLength(KMPoint(K,I), S)
             - gAIFields.Influences.Ownership[fOwner, I, K] / 5
             + KaMRandom('TKMCityPlanner.NextToGrass') * 4;
      if Bid < BestBid then
      begin
        aLoc := KMPoint(K,I);
        BestBid := Bid;
        Result := True;
      end;
    end;
  end;
end;


function TKMCityPlanner.NextToHouse(aHouse: TKMHouseType; aSeed, aAvoid: array of TKMHouseType; out aLoc: TKMPoint): Boolean;
var
  I: Integer;
  Bid, BestBid: Single;
  SeedLocs: TKMPointArray;
  Locs: TKMPointTagList;
begin
  Result := False;

  SeedLocs := GetSeeds(aSeed);

  Locs := TKMPointTagList.Create;
  try
    FindNearest(SeedLocs, 32, aHouse, 12, Locs);

    BestBid := MaxSingle;
    for I := 0 to Locs.Count - 1 do
    begin
      Bid := Locs.Tag[I]
             - gAIFields.Influences.Ownership[fOwner,Locs[I].Y,Locs[I].X] / 5;
      if (Bid < BestBid) then
      begin
        aLoc := Locs[I];
        BestBid := Bid;
        Result := True;
      end;
    end;
  finally
    Locs.Free;
  end;
end;


//Called when AI needs to find a good spot for a new Quary
function TKMCityPlanner.NextToStone(aHouse: TKMHouseType; out aLoc: TKMPoint): Boolean;
const
  SEARCH_RAD = 8;
var
  I, K: Integer;
  Bid, BestBid: Single;
  StoneLoc: TKMPoint;
  Locs: TKMPointTagList;
  SeedLocs: TKMPointArray;
  J, M: Integer;
  tmp: TKMPointDir;
begin
  Result := False;

  SeedLocs := GetSeeds([htAny]);

  Locs := TKMPointTagList.Create;
  try
    //Find all tiles from which stone can be mined, by walking to them
    FindNearest(SeedLocs, 32, fnStone, [tpWalk], 12, Locs);
    if Locs.Count = 0 then Exit;

    //Check few random tiles if we can build Quary nearby
    BestBid := MaxSingle;
    for J := 0 to 2 do
    begin
      M := KaMRandom(Locs.Count, 'TKMCityPlanner.NextToStone');
      StoneLoc := Locs[M];
      for I := Max(StoneLoc.Y - SEARCH_RAD, 1) to Min(StoneLoc.Y + SEARCH_RAD, gTerrain.MapY - 1) do
      for K := Max(StoneLoc.X - SEARCH_RAD, 1) to Min(StoneLoc.X + SEARCH_RAD, gTerrain.MapX - 1) do
      if gHands[fOwner].CanAddHousePlanAI(K, I, aHouse, True) then
      begin
        Bid := Locs.Tag[M]
               - gAIFields.Influences.Ownership[fOwner,I,K] / 10
               + KaMRandom('TKMCityPlanner.NextToStone_2') * 3
               + KMLengthDiag(K, I, StoneLoc); //Distance to stone is important
        if (Bid < BestBid) then
        begin
          aLoc := KMPoint(K,I);
          BestBid := Bid;
          Result := True;
        end;
      end;
    end;
  finally
    Locs.Free;
  end;

  //Make sure stonemason actually can reach some stone (avoid build-destroy loop)
  if Result then
    if not gTerrain.FindStone(aLoc, gRes.Units[utStoneCutter].MiningRange, KMPOINT_ZERO, True, tmp) then
      Result := False;
end;


function TKMCityPlanner.FindNearest(const aStart: TKMPoint; aRadius: Byte; aType: TFindNearest; out aResultLoc: TKMPoint): Boolean;
begin
  fFinder.FindType := aType;
  fFinder.HouseType := htNone;
  Result := fFinder.FindNearest(aStart, aRadius, [tpWalkRoad, tpMakeRoads], aResultLoc);
end;


procedure TKMCityPlanner.FindNearest(const aStart: TKMPointArray; aRadius: Byte; aType: TFindNearest; aPass: TKMTerrainPassabilitySet; aMaxCount: Word; aLocs: TKMPointTagList);
begin
  fFinder.FindType := aType;
  fFinder.HouseType := htNone;
  fFinder.FindNearest(aStart, aRadius, aPass, aMaxCount, aLocs);
end;


procedure TKMCityPlanner.FindNearest(const aStart: TKMPointArray; aRadius: Byte; aHouse: TKMHouseType; aMaxCount: Word; aLocs: TKMPointTagList);
begin
  fFinder.FindType := fnHouse;
  fFinder.HouseType := aHouse;
  fFinder.FindNearest(aStart, aRadius, [tpWalkRoad, tpMakeRoads], aMaxCount, aLocs);
end;


function TKMCityPlanner.NextToOre(aHouse: TKMHouseType; aOreType: TKMWareType; out aLoc: TKMPoint; aNearAnyHouse: Boolean = False): Boolean;
var
  P: TKMPoint;
  SeedLocs: TKMPointArray;
begin
  Result := False;


  //Look for nearest Ore
  case aOreType of
    wtCoal:    begin
                  if aNearAnyHouse then
                    SeedLocs := GetSeeds([htAny])
                  else
                    if gHands[fOwner].Stats.GetHouseTotal(htCoalMine) > 0 then
                      SeedLocs := GetSeeds([htCoalMine])
                    else
                      SeedLocs := GetSeeds([htStore]);
                  if Length(SeedLocs) = 0 then Exit;
                  if not FindNearest(SeedLocs[KaMRandom(Length(SeedLocs), 'TKMCityPlanner.NextToOre')], 45, fnCoal, P) then
                    if aNearAnyHouse or not NextToOre(aHouse, aOreType, P, True) then
                      Exit;
                end;
    wtIronOre: begin
                  if aNearAnyHouse then
                    SeedLocs := GetSeeds([htAny])
                  else
                    if gHands[fOwner].Stats.GetHouseTotal(htIronMine) > 0 then
                      SeedLocs := GetSeeds([htIronMine, htCoalMine])
                    else
                      SeedLocs := GetSeeds([htCoalMine, htStore]);
                  if Length(SeedLocs) = 0 then Exit;
                  if not FindNearest(SeedLocs[KaMRandom(Length(SeedLocs), 'TKMCityPlanner.NextToOre_2')], 45, fnIron, P) then
                    if aNearAnyHouse or not NextToOre(aHouse, aOreType, P, True) then
                      Exit;
                end;
    wtGoldOre: begin
                  if aNearAnyHouse then
                    SeedLocs := GetSeeds([htAny])
                  else
                    if gHands[fOwner].Stats.GetHouseTotal(htGoldMine) > 0 then
                      SeedLocs := GetSeeds([htGoldMine, htCoalMine])
                    else
                      SeedLocs := GetSeeds([htCoalMine, htStore]);
                  if Length(SeedLocs) = 0 then Exit;
                  if not FindNearest(SeedLocs[KaMRandom(Length(SeedLocs), 'TKMCityPlanner.NextToOre_3')], 45, fnGold, P) then
                    if aNearAnyHouse or not NextToOre(aHouse, aOreType, P, True) then
                      Exit;
                end;
  end;

  //todo: If there's no ore AI should not keep calling this over and over again
  // Maybe AI can cache search results for such non-replenishing resources

  aLoc := P;
  Result := True;
end;


function TKMCityPlanner.NextToTrees(aHouse: TKMHouseType; aSeed: array of TKMHouseType; out aLoc: TKMPoint): Boolean;
const
  SEARCH_RES = 7;
  SEARCH_RAD = 20; //Search for forests within this radius
  SEARCH_DIV = (SEARCH_RAD * 2) div SEARCH_RES + 1;
  HUT_RAD = 6; //Search for the best place for a hut in this radius
var
  I, K: Integer;
  Bid, BestBid: Single;
  SeedLocs: TKMPointArray;
  seedLoc, TreeLoc: TKMPoint;
  Mx, My: SmallInt;
  MyForest: array [0..SEARCH_RES-1, 0..SEARCH_RES-1] of ShortInt;
begin
  Result := False;

  SeedLocs := GetSeeds(aSeed);
  if Length(SeedLocs) = 0 then Exit;

  // Pick one random seed loc from given
  seedLoc := SeedLocs[KaMRandom(Length(SeedLocs), 'TKMCityPlanner.NextToTrees')];

    //todo: Rework through FindNearest to avoid roundabouts
  //Fill in MyForest map
  FillChar(MyForest[0,0], SizeOf(MyForest), #0);
  for I := Max(seedLoc.Y - SEARCH_RAD, 1) to Min(seedLoc.Y + SEARCH_RAD, gTerrain.MapY - 1) do
  for K := Max(seedLoc.X - SEARCH_RAD, 1) to Min(seedLoc.X + SEARCH_RAD, gTerrain.MapX - 1) do
  if gTerrain.ObjectIsChopableTree(K, I) then
  begin
    Mx := (K - seedLoc.X + SEARCH_RAD) div SEARCH_DIV;
    My := (I - seedLoc.Y + SEARCH_RAD) div SEARCH_DIV;

    Inc(MyForest[My, Mx]);
  end;

  //Find cell with most trees
  BestBid := -MaxSingle;
  TreeLoc := seedLoc; //Init incase we cant find a spot at all
  for I := Low(MyForest) to High(MyForest) do
  for K := Low(MyForest[I]) to High(MyForest[I]) do
  begin
    Mx := Round(seedLoc.X - SEARCH_RAD + (K + 0.5) * SEARCH_DIV);
    My := Round(seedLoc.Y - SEARCH_RAD + (I + 0.5) * SEARCH_DIV);
    if InRange(Mx, 1, gTerrain.MapX - 1) and InRange(My, 1, gTerrain.MapY - 1)
    and (gAIFields.Influences.AvoidBuilding[My, Mx] = 0) then
    begin
      Bid := MyForest[I, K] + KaMRandom('TKMCityPlanner.NextToTrees_2') * 2; //Add some noise for varied results
      if Bid > BestBid then
      begin
        TreeLoc := KMPoint(Mx, My);
        BestBid := Bid;
      end;
    end;
  end;

  BestBid := MaxSingle;
  for I := Max(TreeLoc.Y - HUT_RAD, 1) to Min(TreeLoc.Y + HUT_RAD, gTerrain.MapY - 1) do
  for K := Max(TreeLoc.X - HUT_RAD, 1) to Min(TreeLoc.X + HUT_RAD, gTerrain.MapX - 1) do
    if gHands[fOwner].CanAddHousePlanAI(K, I, aHouse, True) then
    begin
      Bid := KMLength(KMPoint(K,I), seedLoc) + KaMRandom('TKMCityPlanner.NextToTrees_3') * 5;
      if (Bid < BestBid) then
      begin
        aLoc := KMPoint(K,I);
        BestBid := Bid;
        Result := True;
      end;
    end;
end;


procedure TKMCityPlanner.OwnerUpdate(aPlayer: TKMHandID);
begin
  fOwner := aPlayer;
  fFinder.OwnerUpdate(fOwner);
end;


procedure TKMCityPlanner.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.Write(fOwner);
  fFinder.Save(SaveStream);
  fListGold.SaveToStream(SaveStream);
end;


procedure TKMCityPlanner.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.Read(fOwner);
  fFinder.Load(LoadStream);
  fListGold.LoadFromStream(LoadStream);
end;


{ TKMTerrainFinderCity }
constructor TKMTerrainFinderCity.Create(aOwner: TKMHandID);
begin
  inherited Create;

  fOwner := aOwner;
end;


procedure TKMTerrainFinderCity.OwnerUpdate(aPlayer: TKMHandID);
begin
  fOwner := aPlayer;
end;


function TKMTerrainFinderCity.CanUse(const X, Y: Word): Boolean;
var
  I, K: Integer;
begin
  case FindType of
    fnHouse:  Result := gHands[fOwner].CanAddHousePlanAI(X, Y, HouseType, True);

    fnStone:  Result := (gTerrain.TileIsStone(X, Max(Y-1, 1)) > 1);

    fnCoal:   Result := (gTerrain.TileIsCoal(X, Y) > 1)
                         and gHands[fOwner].CanAddHousePlanAI(X, Y, htCoalMine, False);

    fnIron:   begin
                Result := gHands[fOwner].CanAddHousePlanAI(X, Y, htIronMine, False);
                //If we can build a mine here then search for ore
                if Result then
                  for I:=Max(X-4, 1) to Min(X+3, gTerrain.MapX) do
                    for K:=Max(Y-8, 1) to Y do
                      if gTerrain.TileHasIron(I, K) then
                        Exit;
                Result := False; //Didn't find any ore
              end;

    fnGold:   begin
                Result := gHands[fOwner].CanAddHousePlanAI(X, Y, htGoldMine, False);
                //If we can build a mine here then search for ore
                if Result then
                  for I:=Max(X-4, 1) to Min(X+4, gTerrain.MapX) do
                    for K:=Max(Y-8, 1) to Y do
                      if gTerrain.TileHasGold(I, K) then
                        Exit;
                Result := False; //Didn't find any ore
              end;

    else      Result := False;
  end;
end;


function TKMTerrainFinderCity.CanWalkHere(const X,Y: Word): Boolean;
var
  TerOwner: TKMHandID;
begin
  //Check for specific passabilities
  case FindType of
    fnIron:   Result := (fPassability * gTerrain.Land[Y,X].Passability <> [])
                        or gTerrain.CanPlaceIronMine(X, Y);

    fnGold:   Result := (fPassability * gTerrain.Land[Y,X].Passability <> [])
                        or gTerrain.TileGoodForGoldmine(X, Y);

    else      Result := (fPassability * gTerrain.Land[Y,X].Passability <> []);
  end;

  if not Result then Exit;

  //Don't build on allies and/or enemies territory
  TerOwner := gAIFields.Influences.GetBestOwner(X,Y);
  Result := ((TerOwner = fOwner) or (TerOwner = PLAYER_NONE));
end;


procedure TKMTerrainFinderCity.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  SaveStream.PlaceMarker('TerrainFinderCity');
  SaveStream.Write(fOwner);
end;


procedure TKMTerrainFinderCity.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.CheckMarker('TerrainFinderCity');
  LoadStream.Read(fOwner);
end;


end.
