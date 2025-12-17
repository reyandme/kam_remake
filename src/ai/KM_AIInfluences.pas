unit KM_AIInfluences;
{$I KaM_Remake.inc}
interface
uses
  Math,
  KM_CommonClasses, KM_CommonTypes, KM_Defaults, KM_Points,
  KM_Units, KM_UnitGroup,
  KM_NavMesh, KM_NavMeshGenerator, KM_NavMeshInfluences,
  KM_NavMeshFloodFill;


const
  // Avoid bulding values of specific actions (tile lock by specific action)
  AVOID_BUILDING_UNLOCK = 0;
  AVOID_BUILDING_HOUSE_OUTSIDE_LOCK = 10;
  AVOID_BUILDING_HOUSE_INSIDE_LOCK = 15;
  AVOID_BUILDING_HOUSE_ENTRANCE = 20;
  AVOID_BUILDING_COAL_TILE = 25;
  AVOID_BUILDING_NODE_LOCK_FIELD = 30;
  AVOID_BUILDING_NODE_LOCK_ROAD = 35;
  AVOID_BUILDING_MINE_TILE = 40;
  AVOID_BUILDING_FOREST_RANGE = 200; // Value: 255 <-> AVOID_BUILDING_FOREST_VARIANCE which may forest tiles have
  AVOID_BUILDING_FOREST_MINIMUM = 254 - AVOID_BUILDING_FOREST_RANGE; // Minimum value of forest reservation tiles


type
  // Collection of influence maps
  TKMInfluences = class
  private
    fMapX, fMapY, fPolyCnt: Word; // Limits of arrays

    fAlli2PL: TKMHandID2Array;

    fAvoidBuilding: TKMByteArray; //Common map of areas where building is undesired (around Store, Mines, Woodcutters)
    fUpdateCityIdx, fUpdateArmyIdx: TKMHandID; // Update index
    fPresence: TKMWordArray; // Military presence
    fOwnership: TKMByteArray; // City mark the space around itself

    fInfluenceFloodFill: TKMInfluenceFloodFill;
    fInfluenceSearch: TNavMeshInfluenceSearch;
    fNavMesh: TKMNavMesh;

    {$IFDEF DEBUG_AIInfluences}
    fTimeAvrgOwnership, fTimeAvrgPresence: Int64;
    fTimePeakOwnership, fTimePeakPresence: Int64;
    {$ENDIF}

    // Avoid building
    procedure InitAvoidBuilding();
    function GetAvoidBuilding(const aY,aX: Word): Byte;
    procedure SetAvoidBuilding(const aY,aX: Word; const aValue: Byte);
    // Army presence
    function GetPresence(const aAlliance, aIdx: Word; const aGT: TKMGroupType): Word;
    procedure SetPresence(const aAlliance, aIdx: Word; const aGT: TKMGroupType; const aPresence: Word); inline;
    procedure SetIncPresence(const aAlliance, aIdx: Word; const aGT: TKMGroupType; const aPresence: Word); inline;
    procedure UpdateMilitaryPresence(aAllianceIdx: Integer);
    procedure SetLengthOfPresence();
    // City influence
    function GetOwnership(const aPL: TKMHandID; const aIdx: Word): Byte; inline;
    procedure SetOwnership(const aPL: TKMHandID; const aIdx: Word; const aOwnership: Byte); inline;
    function GetOwnershipFromCoords(const aPL: TKMHandID; const aY, aX: Word): Byte; inline; // For property -> aY, aX are switched!
    procedure SetOwnershipFromCoords(const aPL: TKMHandID; const aY, aX: Word; const aOwnership: Byte); inline; // For property -> aY, aX are switched!
    function GetOwnershipFromPoint(const aPL: TKMHandID; const aPoint: TKMPoint): Byte; inline;
    procedure SetOwnershipFromPoint(const aPL: TKMHandID; const aPoint: TKMPoint; const aOwnership: Byte); inline;
    procedure UpdateOwnership(const aPL: TKMHandID);
  public
    constructor Create(aNavMesh: TKMNavMesh);
    destructor Destroy(); override;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

    // Avoid building
    property AvoidBuilding[const aY,aX: Word]: Byte read GetAvoidBuilding write SetAvoidBuilding;
    // Army presence
    property Presence[const aAlliance, aIdx: Word; const aGT: TKMGroupType]: Word read GetPresence write SetPresence;
    property IncPresence[const aAlliance, aIdx: Word; const aGT: TKMGroupType]: Word write SetIncPresence;
    // City influence
    property Ownership[const aPL: TKMHandID; const aY,aX: Word]: Byte read GetOwnershipFromCoords write SetOwnershipFromCoords; // To secure compatibility with old AI
    property OwnPoint[const aPL: TKMHandID; const aPoint: TKMPoint]: Byte read GetOwnershipFromPoint write SetOwnershipFromPoint;
    property OwnPoly[const aPL: TKMHandID; const aIdx: Word]: Byte read GetOwnership write SetOwnership;
    // Common
    property InfluenceSearch: TNavMeshInfluenceSearch read fInfluenceSearch write fInfluenceSearch;

    // Avoid building
    procedure AddAvoidBuilding(aX,aY: Word; aRad: Single);
    procedure RemAvoidBuilding(aArea: TKMRect);
    procedure MarkForest(aPoint: TKMPoint; aRad, aDecreaseCoef: Single; aOnlyUnmarkedArea: Boolean = False);
    // Army presence
    function GetAllianceIdx(const aPL: TKMHandID; var aIdx: Integer): Boolean;
    function GetArmyTraffic(const aAlliance, aIdx: Word): Word;
    // City influence
    function GetBestOwner(const aX,aY: Word): TKMHandID; overload;
    function GetBestOwner(const aIdx: Word): TKMHandID; overload;
    function GetBestAllianceOwner(const aPL: TKMHandID; const aPoint: TKMPoint; const aAllianceType: TKMAllianceType): TKMHandID;
    //function GetAllAllianceOwnership(const aPL: TKMHandIndex; const aX,aY: Word; const aAllianceType: TKMAllianceType): TKMHandIndexArray;
    function GetBestAllianceOwnership(const aPL: TKMHandID; const aX,aY: Word; const aAllianceType: TKMAllianceType): Byte; overload;
    function GetBestAllianceOwnership(const aPL: TKMHandID; const aIdx: Word; const aAllianceType: TKMAllianceType): Byte; overload;
    function GetOtherOwnerships(const aPL: TKMHandID; const aX, aY: Word): Word; overload;
    function GetOtherOwnerships(const aPL: TKMHandID; const aIdx: Word): Word; overload;
    function CanPlaceHouseByInfluence(const aPL: TKMHandID; const aX,aY: Word; const aIgnoreAllies: Boolean = False): Boolean; overload;
    function CanPlaceHouseByInfluence(const aPL: TKMHandID; const aIdx: Word; const aIgnoreAllies: Boolean = False): Boolean; overload;
    // Common
    procedure InitInfluences();

    procedure AfterMissionInit();
    procedure UpdateState(aTick: Cardinal);
    procedure UpdateAlliances(const aAlli2PL: TKMHandID2Array);
    procedure Paint(const aRect: TKMRect);
  end;

const
  AVOID_TRAFFIC_IDX = 4; // Index of avoid traffic in the fOwnership array (0-3 are group types)

implementation
uses
  SysUtils, Classes,
  KM_RenderAux,
  {$IFDEF DEBUG_AIInfluences}
    KM_CommonUtils,
  {$ENDIF}
  KM_Terrain, KM_Houses, KM_HouseCollection,
  KM_Hand, KM_HandsCollection, KM_HandTypes,
  KM_ResTypes;

const
  PRESENCE_X = (GROUP_TYPES_CNT + 1); // number of group types (4) and 1 for traffic


{ TKMInfluenceMaps }
constructor TKMInfluences.Create(aNavMesh: TKMNavMesh);
begin
  inherited Create();

  fNavMesh := aNavMesh;
  fPolyCnt := 0;
  fUpdateCityIdx := 0;
  fUpdateArmyIdx := 0;
  fInfluenceFloodFill := TKMInfluenceFloodFill.Create(False); // Check if True is better
  fInfluenceSearch := TNavMeshInfluenceSearch.Create(False);
  {$IFDEF DEBUG_AIInfluences}
    fTimeAvrgOwnership := 0;
    fTimeAvrgPresence := 0;
    fTimePeakOwnership := 0;
    fTimePeakPresence := 0;
  {$ENDIF}
end;


destructor TKMInfluences.Destroy();
begin
  fInfluenceFloodFill.Free;
  fInfluenceSearch.Free;
  inherited;
end;


procedure TKMInfluences.Save(SaveStream: TKMemoryStream);
var
  K, Len: Integer;
begin

  SaveStream.PlaceMarker('Influences');
  SaveStream.Write(fMapX);
  SaveStream.Write(fMapY);
  SaveStream.Write(fPolyCnt);
  SaveStream.Write(fUpdateCityIdx,SizeOf(fUpdateCityIdx));
  SaveStream.Write(fUpdateArmyIdx,SizeOf(fUpdateArmyIdx));

  SaveStream.PlaceMarker('Alliances');
  SaveStream.Write( Integer(Length(fAlli2PL)) );
  for K := Low(fAlli2PL) to High(fAlli2PL) do
  begin
    SaveStream.Write( Integer(Length(fAlli2PL[K])) );
    SaveStream.Write(fAlli2PL[K,0], SizeOf(fAlli2PL[K,0])*Length(fAlli2PL[K]));
  end;

  SaveStream.PlaceMarker('AvoidBuilding');
  SaveStream.Write(fAvoidBuilding[0], SizeOf(fAvoidBuilding[0]) * Length(fAvoidBuilding));

  SaveStream.PlaceMarker('Ownership');
  Len := Length(fOwnership);
  SaveStream.Write(Len);
  if Len > 0 then
    SaveStream.Write(fOwnership[0], SizeOf(fOwnership[0]) * Len);

  SaveStream.PlaceMarker('ArmyPresence');
  Len := Length(fPresence);
  SaveStream.Write(Len);
  if Len > 0 then
    SaveStream.Write(fPresence[0], SizeOf(fPresence[0]) * Len);
end;


procedure TKMInfluences.Load(LoadStream: TKMemoryStream);
var
  K, Len: Integer;
begin
  LoadStream.CheckMarker('Influences');
  LoadStream.Read(fMapX);
  LoadStream.Read(fMapY);
  LoadStream.Read(fPolyCnt);
  LoadStream.Read(fUpdateCityIdx,SizeOf(fUpdateCityIdx));
  LoadStream.Read(fUpdateArmyIdx,SizeOf(fUpdateArmyIdx));

  LoadStream.CheckMarker('Alliances');
  LoadStream.Read(Len);
  SetLength(fAlli2PL, Len);
  for K := Low(fAlli2PL) to High(fAlli2PL) do
  begin
    LoadStream.Read(Len);
    SetLength(fAlli2PL[K],Len);
    LoadStream.Read(fAlli2PL[K,0], SizeOf(fAlli2PL[K,0])*Length(fAlli2PL[K]));
  end;

  LoadStream.CheckMarker('AvoidBuilding');
  SetLength(fAvoidBuilding, fMapY * fMapX);
  LoadStream.Read(fAvoidBuilding[0], SizeOf(fAvoidBuilding[0]) * fMapY * fMapX);

  LoadStream.CheckMarker('Ownership');
  LoadStream.Read(Len);
  SetLength(fOwnership, Len);
  if Len > 0 then
    LoadStream.Read(fOwnership[0], SizeOf(fOwnership[0]) * Len);

  LoadStream.CheckMarker('ArmyPresence');
  LoadStream.Read(Len);
  SetLength(fPresence, Len);
  if Len > 0 then
    LoadStream.Read(fPresence[0], SizeOf(fPresence[0]) * Len);
end;


//Make the area around to be avoided by common houses
procedure TKMInfluences.AddAvoidBuilding(aX,aY: Word; aRad: Single);
var
  X,Y,Rad: Integer;
begin
  if (aRad = 0) then
    Exit;
  Rad := Ceil(aRad);
  for Y := Max(aY - Rad, 1) to Min(aY + Rad, fMapY - 1) do
  for X := Max(aX - Rad, 1) to Min(aX + Rad, fMapX - 1) do
    if (AvoidBuilding[Y,X] = 0) OR (AvoidBuilding[Y,X] >= AVOID_BUILDING_FOREST_MINIMUM)  // Protect reservation tiles
      AND (Sqr(aX-X) + Sqr(aY-Y) <= Sqr(aRad)) then
      AvoidBuilding[Y,X] := 255;
end;


procedure TKMInfluences.RemAvoidBuilding(aArea: TKMRect);
var
  X,Y: Integer;
begin
  for Y := Max(aArea.Top , 1) to Min(aArea.Bottom, fMapY - 1) do
  for X := Max(aArea.Left, 1) to Min(aArea.Right , fMapX - 1) do
    if (AvoidBuilding[Y,X] = AVOID_BUILDING_COAL_TILE) then // It is not used otherwise anyway
      AvoidBuilding[Y,X] := 0;
end;


procedure TKMInfluences.MarkForest(aPoint: TKMPoint; aRad, aDecreaseCoef: Single; aOnlyUnmarkedArea: Boolean = False);
var
  X,Y, Rad: Integer;
  SqrDist, SqrMaxDist: Single;
begin
  if (aRad = 0) then
    Exit;
  SqrMaxDist := Sqr(aRad);
  Rad := Ceil(aRad);
  for Y := Max(aPoint.Y - Rad, 1) to Min(aPoint.Y + Rad, fMapY - 1) do
  for X := Max(aPoint.X - Rad, 1) to Min(aPoint.X + Rad, fMapX - 1) do
    if (AvoidBuilding[Y,X] = 0) OR (AvoidBuilding[Y,X] >= AVOID_BUILDING_FOREST_MINIMUM) then // Protect reservation tiles
    begin
      SqrDist := Sqr(aPoint.X-X) + Sqr(aPoint.Y-Y);
      if (SqrDist <= SqrMaxDist) then
      begin
        if not aOnlyUnmarkedArea then
          AvoidBuilding[Y,X] := Min( 254, // Forest does not reach full 255
                                   Max( AVOID_BUILDING_FOREST_MINIMUM, // Forest start at this value
                                        AvoidBuilding[Y,X] + 254 - Round(SqrDist * aDecreaseCoef)
                                      )
                                 )
        else if (AvoidBuilding[Y,X] = 0) then
          AvoidBuilding[Y,X] := Min( 254, // Forest does not reach full 255
                                   Max( AVOID_BUILDING_FOREST_MINIMUM, // Forest start at this value
                                        254 - Round(SqrDist * aDecreaseCoef)
                                      )
                                 );
      end;
    end;
end;


//AI should avoid certain areas, keeping them for special houses
procedure TKMInfluences.InitAvoidBuilding();
  procedure CheckAndMarkMine(aX,aY: Integer; aHT: TKMHouseType);
  var
    X,Y,X2,Y2: Integer;
  begin
    for Y := Max(1,aY-3) to Min(fMapY-1,aY-1) do
    for X := Max(1,aX-1) to Min(fMapX-1,aX+1) do
      if   ((aHT = htIronMine) AND (gTerrain.TileIsIron(X,Y) > 1))
        OR ((aHT = htGoldMine) AND (gTerrain.TileIsGold(X,Y) > 1)) then
      begin
        for Y2 := aY to Min(fMapY-1,aY+1) do
        for X2 := Max(1,aX-2) to Min(fMapX-1,aX+1+Byte(aHT = htIronMine)) do
          AvoidBuilding[Y2, X2] := AVOID_BUILDING_MINE_TILE;
        Exit;
      end;
  end;
var
  H: TKMHouse;
  I,X,Y: Integer;
begin
  FillChar(fAvoidBuilding[0], SizeOf(fAvoidBuilding[0]) * Length(fAvoidBuilding), #0);

  //Avoid Coal fields (must be BEFORE Gold/Iron mines)
  for Y := 1 to fMapY - 1 do
  for X := 1 to fMapX - 1 do
    if (gTerrain.TileIsCoal(X, Y) > 1) then
      AvoidBuilding[Y,X] := AVOID_BUILDING_COAL_TILE;

  //Avoid areas where Gold/Iron mines should be
  for Y := 3 to fMapY - 2 do
  for X := 2 to fMapX - 2 do
    if gTerrain.CanPlaceHouse(KMPoint(X,Y), htIronMine) then
      CheckAndMarkMine(X,Y, htIronMine)
    else if gTerrain.CanPlaceHouse(KMPoint(X,Y), htGoldMine) then
      CheckAndMarkMine(X,Y, htGoldMine);

  //Leave free space BELOW all Stores
  for I := 0 to gHands.Count - 1 do
  begin
    H := gHands[I].FindHouse(htStore);
    if (H <> nil) then
    for Y := Max(H.Entrance.Y + 1, 1) to Min(H.Entrance.Y + 2, fMapY - 1) do
    for X := Max(H.Entrance.X - 1, 1) to Min(H.Entrance.X + 1, fMapX - 1) do
      AvoidBuilding[Y,X] := AVOID_BUILDING_HOUSE_ENTRANCE;
  end;
end;


function TKMInfluences.GetAvoidBuilding(const aY,aX: Word): Byte;
begin
  Result := fAvoidBuilding[aY*fMapX + aX];
end;


procedure TKMInfluences.SetAvoidBuilding(const aY,aX: Word; const aValue: Byte);
begin
  fAvoidBuilding[aY*fMapX + aX] := aValue;
end;


function TKMInfluences.GetArmyTraffic(const aAlliance, aIdx: Word): Word;
const
  MAX_SOLDIERS_IN_POLYGON = 20; // Maximal count of soldiers in 1 triangle of NavMesh - it depends on NavMesh size!!!
begin
  Result := Min(MAX_SOLDIERS_IN_POLYGON, fPresence[PRESENCE_X*(aAlliance*fPolyCnt + aIdx) + AVOID_TRAFFIC_IDX]);
end;


function TKMInfluences.GetPresence(const aAlliance, aIdx: Word; const aGT: TKMGroupType): Word;
begin
  Result := fPresence[PRESENCE_X*(aAlliance*fPolyCnt + aIdx) + Ord(aGT) - GROUP_TYPE_MIN_OFF];
end;


procedure TKMInfluences.SetPresence(const aAlliance, aIdx: Word; const aGT: TKMGroupType; const aPresence: Word);
begin
  fPresence[PRESENCE_X*(aAlliance*fPolyCnt + aIdx) + Ord(aGT) - GROUP_TYPE_MIN_OFF] := aPresence;
end;


procedure TKMInfluences.SetIncPresence(const aAlliance, aIdx: Word; const aGT: TKMGroupType; const aPresence: Word);
begin
  Inc(fPresence[PRESENCE_X*(aAlliance*fPolyCnt + aIdx) + Ord(aGT) - GROUP_TYPE_MIN_OFF], aPresence);
end;


procedure TKMInfluences.UpdateMilitaryPresence(aAllianceIdx: Integer);
const
  EACH_X_MEMBER_COEF = 5;
  PENALIZATION_ARR: array [GROUP_TYPE_MIN..GROUP_TYPE_MAX, GROUP_TYPE_MIN..GROUP_TYPE_MAX] of Single = (
    // gtMelee, gtAntiHorse, gtRanged, gtMounted
    (    1.0,      0.3,       0.0,      0.5), // gtMelee
    (    1.0,      1.0,       0.0,      0.0), // gtAntiHorse
    (    1.0,      1.0,       1.0,      2.0), // gtRanged
    (    1.0,      2.0,       0.0,      1.0)  // gtMounted
  );
  procedure EvaluatePolygon(aIdx: Cardinal; aEval: Word; aGT: TKMGroupType);
  begin
    Inc(fPresence[aIdx+0], Round(aEval*PENALIZATION_ARR[aGT,gtMelee]));
    Inc(fPresence[aIdx+1], Round(aEval*PENALIZATION_ARR[aGT,gtAntiHorse]));
    Inc(fPresence[aIdx+2], Round(aEval*PENALIZATION_ARR[aGT,gtRanged]));
    Inc(fPresence[aIdx+3], Round(aEval*PENALIZATION_ARR[aGT,gtMounted]));
  end;
var
  Increment: Word;
  K, L, M, PolyIdx: Integer;
  G: TKMUnitGroup;
  GT: TKMGroupType;
  U: TKMUnit;
  PL: TKMHandID;
begin
  if (Length(fPresence) <= 0) then
    Exit;
  // Length of fPresence = alliances * polygons * 5 (= 4 types of groups + traffic)
  FillChar(fPresence[aAllianceIdx*fPolyCnt*PRESENCE_X], SizeOf(fPresence[0]) * fPolyCnt * PRESENCE_X, #0);

  // Mark avoid traffic
  for PL in fAlli2PL[aAllianceIdx] do
    if gHands[PL].Enabled then
      for K := 0 to gHands[PL].UnitGroups.Count - 1 do
      begin
        G := gHands[PL].UnitGroups.Groups[K];
        if (G = nil) or G.IsDead then
          Continue;
        Increment := Min(G.Count, EACH_X_MEMBER_COEF);
        L := 0;
        while (L < G.Count) do
        begin
          U := G.Members[L];
          if (U <> nil) and not U.IsDeadOrDying then
          begin
            PolyIdx := fNavMesh.KMPoint2Polygon[U.Position];
            Inc(fPresence[PRESENCE_X*(aAllianceIdx*fPolyCnt + PolyIdx) + AVOID_TRAFFIC_IDX],Increment);
          end;
          L := L + EACH_X_MEMBER_COEF;
        end;
      end;

  // Mark enemy groups
  for PL := 0 to gHands.Count - 1 do
    if gHands[PL].Enabled and (gHands[fAlli2PL[aAllianceIdx,0]].Alliances[PL] = atEnemy) then
      for K := 0 to gHands[PL].UnitGroups.Count - 1 do
      begin
        G := gHands[PL].UnitGroups.Groups[K];
        if (G = nil) or G.IsDead then
          Continue;
        Increment := Min(G.Count, EACH_X_MEMBER_COEF);
        GT := G.GroupType;
        L := 0;
        while (L < G.Count) do
        begin
          U := G.Members[L];
          if (U <> nil) and not U.IsDeadOrDying then
          begin
            PolyIdx := fNavMesh.KMPoint2Polygon[U.Position];
            EvaluatePolygon(PRESENCE_X*(aAllianceIdx*fPolyCnt + PolyIdx), Increment, GT);
            with fNavMesh.Polygons[PolyIdx] do
              for M := 0 to NearbyCount - 1 do
                EvaluatePolygon(PRESENCE_X*(aAllianceIdx*fPolyCnt + Nearby[M]), Increment, GT);
          end;
          L := L + EACH_X_MEMBER_COEF;
        end;
      end;
end;


function TKMInfluences.GetOwnership(const aPL: TKMHandID; const aIdx: Word): Byte;
begin
  Result := fOwnership[aPL * fPolyCnt + aIdx];
end;


procedure TKMInfluences.SetOwnership(const aPL: TKMHandID; const aIdx: Word; const aOwnership: Byte);
begin
  fOwnership[aPL * fPolyCnt + aIdx] := aOwnership;
end;


function TKMInfluences.GetOwnershipFromCoords(const aPL: TKMHandID; const aY, aX: Word): Byte;
begin
  Result := GetOwnership(aPL, fNavMesh.Point2Polygon[aY,aX]);
end;


procedure TKMInfluences.SetOwnershipFromCoords(const aPL: TKMHandID; const aY, aX: Word; const aOwnership: Byte);
begin
  SetOwnership(aPL, fNavMesh.Point2Polygon[aY,aX], aOwnership);
end;


function TKMInfluences.GetOwnershipFromPoint(const aPL: TKMHandID; const aPoint: TKMPoint): Byte;
begin
  Result := GetOwnership(aPL, fNavMesh.KMPoint2Polygon[aPoint]);
end;


procedure TKMInfluences.SetOwnershipFromPoint(const aPL: TKMHandID; const aPoint: TKMPoint; const aOwnership: Byte);
begin
  SetOwnership(aPL, fNavMesh.KMPoint2Polygon[aPoint], aOwnership);
end;


function TKMInfluences.GetBestOwner(const aX,aY: Word): TKMHandID;
begin
  Result := GetBestOwner( fNavMesh.Point2Polygon[aY,aX] );
end;


function TKMInfluences.GetBestOwner(const aIdx: Word): TKMHandID;
var
  PL: TKMHandID;
  Best: Integer;
begin
  Result := HAND_NONE;
  if not FEAT_AI_GENERATE_INFLUENCE OR (aIdx = High(Word)) then
    Exit;

  Best := 0;
  for PL := 0 to gHands.Count - 1 do
    if (OwnPoly[PL,aIdx] > Best) then
    begin
      Best := OwnPoly[PL,aIdx];
      Result := PL;
    end;
end;


function TKMInfluences.GetBestAllianceOwner(const aPL: TKMHandID; const aPoint: TKMPoint; const aAllianceType: TKMAllianceType): TKMHandID;
var
  PL: TKMHandID;
  Idx: Word;
  Best: Integer;
begin
  Result := HAND_NONE;
  Idx := fNavMesh.Point2Polygon[aPoint.Y,aPoint.X];
  if not FEAT_AI_GENERATE_INFLUENCE OR (Idx = High(Word)) then
    Exit;

  Best := 0;
  for PL := 0 to gHands.Count - 1 do
    if (gHands[aPL].Alliances[PL] = aAllianceType) AND (OwnPoly[PL,Idx] > Best) then
    begin
      Best := OwnPoly[PL,Idx];
      Result := PL;
    end;
end;


//function TKMInfluences.GetAllAllianceOwnership(const aPL: TKMHandIndex; const aX,aY: Word; const aAllianceType: TKMAllianceType): TKMHandIndexArray;
//var
//  PL: TKMHandIndex;
//  I,K,Idx, Cnt: Integer;
//  Output: TKMHandIndexArray;
//begin
//  SetLength(Result,0);
//  if not FEAT_AI_GENERATE_INFLUENCE OR (aIdx = High(Word)) then
//    Exit;
//
//  SetLength(Output, MAX_HANDS);
//  Cnt := 0;
//  Idx := fNavMesh.Point2Polygon[aY,aX];
//  for PL := 0 to gHands.Count - 1 do
//    if (aPL <> PL) AND (gHands[aPL].Alliances[PL] = aAllianceType) AND (OwnPoly[PL,Idx] > 0) then
//    begin
//      Output[Cnt] := OwnPoly[PL,Idx];
//      Cnt := Cnt + 1;
//    end;
//  SetLength(Output, MAX_HANDS);
//  // Sort results by influence (in real game 1 <-> 3 elements)
//  for I := Cnt - 1 downto 0 do
//    for K := 0 to I - 1 do
//      if (OwnPoly[ Output[K],Idx ] < OwnPoly[ Output[K+1],Idx ]) then
//      begin
//        PL := Output[K];
//        Output[K] := Output[K+1];
//        Output[K+1] := K;
//      end;
//  Result := Output;
//end;


function TKMInfluences.GetBestAllianceOwnership(const aPL: TKMHandID; const aX,aY: Word; const aAllianceType: TKMAllianceType): Byte;
begin
  Result := GetBestAllianceOwnership(aPL, fNavMesh.Point2Polygon[aY,aX], aAllianceType);
end;


function TKMInfluences.GetBestAllianceOwnership(const aPL: TKMHandID; const aIdx: Word; const aAllianceType: TKMAllianceType): Byte;
var
  PL: TKMHandID;
begin
  Result := 0;
  if not FEAT_AI_GENERATE_INFLUENCE OR (aIdx = High(Word)) then
    Exit;

  for PL := 0 to gHands.Count - 1 do
    if (aPL <> PL) AND (gHands[aPL].Alliances[PL] = aAllianceType) AND (OwnPoly[PL,aIdx] > Result) then
      Result := OwnPoly[PL,aIdx];
end;


function TKMInfluences.GetOtherOwnerships(const aPL: TKMHandID; const aX, aY: Word): Word;
begin
  Result := GetOtherOwnerships(aPL, fNavMesh.Point2Polygon[aY,aX]);
end;


function TKMInfluences.GetOtherOwnerships(const aPL: TKMHandID; const aIdx: Word): Word;
const
  ENEMY_COEF = 2;
var
  PL: TKMHandID;
  Ownership: Byte;
begin
  Result := 0;
  if not FEAT_AI_GENERATE_INFLUENCE OR (aIdx = High(Word)) then
    Exit;

  Result := 0;
  for PL := 0 to gHands.Count - 1 do
    if (PL <> aPL) then
    begin
      Ownership := OwnPoly[PL,aIdx];
      Inc(Result, IfThen(gHands[aPL].Alliances[PL] = atAlly, Ownership, Ownership*ENEMY_COEF));
    end;
end;


function TKMInfluences.CanPlaceHouseByInfluence(const aPL: TKMHandID; const aX,aY: Word; const aIgnoreAllies: Boolean = False): Boolean;
begin
  Result := CanPlaceHouseByInfluence(aPL, fNavMesh.Point2Polygon[aY,aX], aIgnoreAllies);
end;


function TKMInfluences.CanPlaceHouseByInfluence(const aPL: TKMHandID; const aIdx: Word; const aIgnoreAllies: Boolean = False): Boolean;
var
  bestOwner: TKMHandID;
begin
  bestOwner := GetBestOwner(aIdx);
  Result := (bestOwner >= 0) AND (OwnPoly[aPL, aIdx] > 0) AND ((bestOwner = aPL) OR (not aIgnoreAllies AND (gHands[aPL].Alliances[bestOwner] = atAlly)));
end;


// Here is the main reason for reworking influences: only 1 flood fill for city per a update + ~25x less elements in array
procedure TKMInfluences.UpdateOwnership(const aPL: TKMHandID);
const
  INIT_HOUSE_INFLUENCE = 255;
  MAX_INFLUENCE_DISTANCE = 150;
var
  isAI: Boolean;
  I, cnt: Integer;
  H: TKMHouse;
  idxArray: TKMWordArray;
begin
  //Clear array (it is better to clear ~3000 polygons instead of 255*255 tiles)
  FillChar(fOwnership[aPL*fPolyCnt], SizeOf(fOwnership[0]) * fPolyCnt, #0);

  // Create array of polygon indexes
  SetLength(idxArray, gHands[aPL].Houses.Count);
  cnt := 0;
  isAI := gHands[aPL].IsComputer;
  for I := 0 to gHands[aPL].Houses.Count - 1 do
  begin
    H := gHands[aPL].Houses[I];
    if not H.IsDestroyed
    and not (H.HouseType in [htWatchTower, htWoodcutters])
    and (isAI or H.IsComplete) then // Player must finish the house to update influence so he cannot troll the AI
    begin
      // Use point below entrance to match NavMeshDefence algorithm and city center detection in Eye
      idxArray[cnt] := fNavMesh.KMPoint2Polygon[H.PointBelowEntrance];
      Inc(cnt);
    end;
  end;

  if cnt > 0 then
    fInfluenceFloodFill.HouseInfluence(aPL, INIT_HOUSE_INFLUENCE, MAX_INFLUENCE_DISTANCE, cnt - 1, idxArray);
end;


function TKMInfluences.GetAllianceIdx(const aPL: TKMHandID; var aIdx: Integer): Boolean;
var
  K, PL: TKMHandID;
begin
  Result := False;
  for K := Low(fAlli2PL) to High(fAlli2PL) do
    for PL in fAlli2PL[K] do
      if (PL = aPL) then
      begin
        aIdx := K;
        Exit(True);
      end
end;


procedure TKMInfluences.InitInfluences();
var
  Idx: Integer;
  PL: TKMHandID;
begin
  fPolyCnt := fNavMesh.PolygonsCnt;
  if (Length(fOwnership) < gHands.Count * fPolyCnt) then
    SetLength(fOwnership, gHands.Count * fPolyCnt);
  FillChar(fOwnership[0], SizeOf(fOwnership[0]) * Length(fOwnership), #0);
  for PL := 0 to gHands.Count - 1 do
    UpdateOwnership(PL);
  SetLengthOfPresence();
  for Idx := 0 to Length(fAlli2PL) - 1 do
    UpdateMilitaryPresence(Idx);
end;


procedure TKMInfluences.AfterMissionInit();
begin
  fMapX := gTerrain.MapX;
  fMapY := gTerrain.MapY;
  SetLength(fAvoidBuilding, fMapY * fMapX);
  InitAvoidBuilding();
end;


procedure TKMInfluences.UpdateState(aTick: Cardinal);
  {$IFDEF DEBUG_AIInfluences}
  var
    tStart,tStop: Int64;
  procedure UpdateTimer(var aTimeAvrg, aTimePeak: Int64);
  begin
    tStop := TimeGetUsec() - tStart;
    aTimePeak := Max(aTimePeak, tStop);
    aTimeAvrg := Round((aTimeAvrg * 5 + tStop)/6);
    tStart := TimeGetUsec();
  end;
  {$ENDIF}
begin
  {$IFDEF DEBUG_AIInfluences}
    tStart := TimeGetUsec();
  {$ENDIF}
  // City:
  if (aTick mod 150 = 15) then // Update every 15 sec 1 player
  begin
    fUpdateCityIdx := (fUpdateCityIdx + 1) mod gHands.Count;
    UpdateOwnership(fUpdateCityIdx);
    {$IFDEF DEBUG_AIInfluences}
      UpdateTimer(fTimeAvrgOwnership, fTimePeakOwnership);
    {$ENDIF}
  end;
  // Army:
  if (aTick mod 5 = 0) AND (Length(fAlli2PL) > 0) then // Update every 0.5 sec 1 player
  begin
    fUpdateArmyIdx := (fUpdateArmyIdx + 1) mod Length(fAlli2PL);
    UpdateMilitaryPresence(fUpdateArmyIdx);
    {$IFDEF DEBUG_AIInfluences}
      UpdateTimer(fTimeAvrgPresence, fTimePeakPresence);
    {$ENDIF}
  end;
end;


procedure TKMInfluences.UpdateAlliances(const aAlli2PL: TKMHandID2Array);
var
  K: Integer;
begin
  SetLength(fAlli2PL, Length(aAlli2PL));
  for K := Low(aAlli2PL) to High(aAlli2PL) do
  begin
    SetLength(fAlli2PL[K], Length(aAlli2PL[K]));
    Move(aAlli2PL[K,0], fAlli2PL[K,0], SizeOf(aAlli2PL[K,0]) * Length(aAlli2PL[K]));
  end;
  SetLengthOfPresence();
end;


procedure TKMInfluences.SetLengthOfPresence();
begin
  if (Length(fAlli2PL) * fPolyCnt * PRESENCE_X <> Length(fPresence)) then
  begin
    SetLength(fPresence, Length(fAlli2PL) * fPolyCnt * PRESENCE_X);
    FillChar(fPresence[0], SizeOf(fPresence[0]) * Length(fPresence), #0);
  end;
end;


//Render debug symbols
procedure TKMInfluences.Paint(const aRect: TKMRect);
var
  PL, WatchedPL: TKMHandID;
  K, X,Y, TeamIdx, Cnt: Integer;
  GT: TKMGroupType;
  Col: Cardinal;
begin

  if not FEAT_AI_GENERATE_NAVMESH OR not FEAT_AI_GENERATE_INFLUENCE then
    Exit;

  if OVERLAY_AVOID then
    for Y := aRect.Top to aRect.Bottom do
    for X := aRect.Left to aRect.Right do
    begin
      Col := AvoidBuilding[Y,X] * 65793 OR $80000000;
      gRenderAux.Quad(X, Y, Col);
    end;

  if (OVERLAY_INFLUENCE OR OVERLAY_OWNERSHIP) AND not OVERLAY_AI_COMBAT then
  begin
    for K := 0 to fPolyCnt - 1 do
    begin
      PL := GetBestOwner(K);
      if (PL = HAND_NONE) then
        Continue
      else
        fNavMesh.DrawPolygon(K, OwnPoly[PL,K], gHands[PL].FlagColor AND tcWhite);
    end;
  end;

  if (OVERLAY_INFLUENCE OR OVERLAY_OWNERSHIP) AND OVERLAY_AI_COMBAT then
  begin
    WatchedPL := gMySpectator.HandID;
    if (WatchedPL = HAND_NONE) then
      Exit;

    if not GetAllianceIdx(WatchedPL,TeamIdx) then
      Exit;

    for K := 0 to fPolyCnt - 1 do
    begin
      Cnt := 0;
      for GT := GROUP_TYPE_MIN to GROUP_TYPE_MAX do
        Cnt := Cnt + Presence[TeamIdx, K, GT];
      //NavMesh polys coverage
      if (Cnt > 0) then
        fNavMesh.DrawPolygon(K, Byte(Min(Max(Cnt,$1F),$F0)), tcRed);
      Cnt := GetArmyTraffic(TeamIdx, K);
      //NavMesh polys coverage
      if (Cnt > 0) then
        fNavMesh.DrawPolygon(K, Byte(Min(Max(Cnt,$3F),$F0)), tcYellow);
    end;
    {
    for I := 0 to fPolyCnt - 1 do
    begin
      BestCnt := 0;
      for PL := 0 to gHands.Count - 1 do
      begin
        Cnt := PresenceAllGroups[PL,I];
        if (Cnt > BestCnt) then
        begin
          BestCnt := Cnt;
          if (WatchedPL = PL) then
            Col := tcGreen
          else if (gHands[WatchedPL].Alliances[PL] = atAlly) then
            Col := tcBlue
          else
            Col := tcRed;
        end;
      end;
      if (BestCnt > 0) then
      begin
        BestCnt := Min(BestCnt,$9F);
        //NavMesh polys coverage
        fNavMesh.DrawPolygon(I, BestCnt, Col);
      end;
    end;
    //}
  end;
end;


end.

