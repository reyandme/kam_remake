unit KM_PathFindingRoad;
{$I KaM_Remake.inc}
interface
uses
  SysUtils,
  KM_CommonClasses, KM_Defaults, KM_PathFinding, KM_PathFindingAStarNew, KM_Points;


type
  // Pathfinding that finds a route for a road to be built
  //todo: Maybe it is worth trying to make Roadfinder a house-aware algo,
  // to prefer connecting to supply/demand houses
  TKMPathFindingRoad = class(TKMPathFindingAStarNew)
  private
    fRoadConnectID: Byte;
  protected
    fOwner: TKMHandID; // fOwner MUST BE VISIBLE for child-classes
    function CanWalkTo(const aFrom: TKMPoint; aToX, aToY: SmallInt): Boolean; override;
    function DestinationReached(aX, aY: Word): Boolean; override;
    function IsWalkableTile(aX, aY: Word): Boolean; override;
    function MovementCost(aFromX, aFromY, aToX, aToY: Word): Cardinal; override;
    function EstimateToFinish(aX, aY: Word): Cardinal; override;
  public
    constructor Create(aOwner: TKMHandID);

    procedure OwnerUpdate(aPlayer: TKMHandID);
    function Route_Make(const aLocA, aLocB: TKMPoint; NodeList: TKMPointList): Boolean; reintroduce;
    function Route_ReturnToWalkable(const aLocA, aLocB: TKMPoint; aRoadConnectID: Byte; NodeList: TKMPointList): Boolean; reintroduce;
    procedure Save(SaveStream: TKMemoryStream); override;
    procedure Load(LoadStream: TKMemoryStream); override;
  end;

  // Minor variation on class above for creating shortcuts in AI road network
  TKMPathFindingRoadShortcuts = class(TKMPathFindingRoad)
  protected
    function DestinationReached(aX, aY: Word): Boolean; override;
    function MovementCost(aFromX, aFromY, aToX, aToY: Word): Cardinal; override;
  end;


implementation
uses
  KM_HandsCollection, KM_TerrainTypes, KM_Terrain, KM_Hand;


{ TKMPathFindingRoad }
constructor TKMPathFindingRoad.Create(aOwner: TKMHandID);
begin
  inherited Create;
  fOwner := aOwner;
end;


procedure TKMPathFindingRoad.OwnerUpdate(aPlayer: TKMHandID);
begin
  fOwner := aPlayer;
end;


procedure TKMPathFindingRoad.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  SaveStream.PlaceMarker('PathFindingRoad');
  SaveStream.Write(fOwner);
  SaveStream.Write(fRoadConnectID);
end;


procedure TKMPathFindingRoad.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.CheckMarker('PathFindingRoad');
  LoadStream.Read(fOwner);
  LoadStream.Read(fRoadConnectID);
end;


function TKMPathFindingRoad.CanWalkTo(const aFrom: TKMPoint; aToX, aToY: SmallInt): Boolean;
begin
  //Roads can't go diagonally, only in 90 turns
  Result := (aToX = aFrom.X) or (aToY = aFrom.Y);
end;


function TKMPathFindingRoad.MovementCost(aFromX, aFromY, aToX, aToY: Word): Cardinal;
var
  isRoad: Boolean;
begin
  isRoad := (tpWalkRoad in gTerrain.Land^[aToY, aToX].Passability)
            or (gHands[fOwner].Constructions.FieldworksList.HasField(KMPoint(aToX, aToY)) = ftRoad)
            or (gTerrain.Land^[aToY, aToX].TileLock = tlRoadWork);

  //Since we don't allow roads to be built diagonally we can assume
  //path is always 1 tile = 1 point
  if isRoad then
    Result := 0
  else
    Result := 1;

  //Building roads over fields is discouraged unless unavoidable
  if gTerrain.TileIsCornField(KMPoint(aToX, aToY))
  or gTerrain.TileIsWineField(KMPoint(aToX, aToY)) then
    Inc(Result, 6); //6 tiles penalty
end;


function TKMPathFindingRoad.EstimateToFinish(aX, aY: Word): Cardinal;
begin
  case fDestination of
    pdLocation:    //Rough estimation
                    Result := (Abs(aX - fLocB.X) + Abs(aY - fLocB.Y));

    pdPassability: //Every direction is equaly good
                    Result := 0;
    else            Result := 0;
  end;
end;


function TKMPathFindingRoad.IsWalkableTile(aX, aY: Word): Boolean;
begin
  Result := ( ([tpMakeRoads, tpWalkRoad] * gTerrain.Land^[aY,aX].Passability <> []) OR (gTerrain.Land^[aY, aX].TileLock = tlRoadWork) )
            and (gHands[fOwner].Constructions.FieldworksList.HasField(KMPoint(aX, aY)) in [ftNone, ftRoad])
            and not gHands[fOwner].Constructions.HousePlanList.HasPlan(KMPoint(aX, aY)); // This will ignore allied plans but I guess that it will not cause trouble
end;


function TKMPathFindingRoad.DestinationReached(aX, aY: Word): Boolean;
begin
  Result := ((aX = fLocB.X) and (aY = fLocB.Y)) //We reached destination point
            or ((gTerrain.Land^[aY, aX].TileOverlay = toRoad) //We reached destination road network
               and (fRoadConnectID <> 0) //No network
               and (gTerrain.GetRoadConnectID(KMPoint(aX, aY)) = fRoadConnectID));
end;


function TKMPathFindingRoad.Route_Make(const aLocA, aLocB: TKMPoint; NodeList: TKMPointList): Boolean;
begin
  Result := inherited Route_Make(aLocA, aLocB, [tpMakeRoads, tpWalkRoad], 0, nil, NodeList);
end;


//Even though we are only going to a road network it is useful to know where our target is so we start off in the right direction (makes algorithm faster/work over long distances)
function TKMPathFindingRoad.Route_ReturnToWalkable(const aLocA, aLocB: TKMPoint; aRoadConnectID: Byte; NodeList: TKMPointList): Boolean;
begin
  fRoadConnectID := aRoadConnectID;
  Result := inherited Route_ReturnToWalkable(aLocA, aLocB, wcRoad, 0, [tpMakeRoads, tpWalkRoad], NodeList);
end;


{ TKMPathFindingRoadShortcuts }
function TKMPathFindingRoadShortcuts.MovementCost(aFromX, aFromY, aToX, aToY: Word): Cardinal;
var
  isRoad: Boolean;
begin
  //Since we don't allow roads to be built diagonally we can assume
  //path is always 1 tile
  Result := 1;

  //Off road costs extra
  isRoad := (tpWalkRoad in gTerrain.Land^[aToY, aToX].Passability)
            or (gHands[fOwner].Constructions.FieldworksList.HasField(KMPoint(aToX, aToY)) = ftRoad)
            or (gTerrain.Land^[aToY, aToX].TileLock = tlRoadWork);

  if not isRoad then
    Inc(Result, 3);

  //Building roads over fields is discouraged unless unavoidable
  if gTerrain.TileIsCornField(KMPoint(aToX, aToY))
  or gTerrain.TileIsWineField(KMPoint(aToX, aToY)) then
    Inc(Result, 4);
end;


function TKMPathFindingRoadShortcuts.DestinationReached(aX, aY: Word): Boolean;
begin
  Result := ((aX = fLocB.X) and (aY = fLocB.Y)); //We reached destination point
end;


end.
