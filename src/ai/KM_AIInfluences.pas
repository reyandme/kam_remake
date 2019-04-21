unit KM_AIInfluences;
{$I KaM_Remake.inc}
interface
uses
  Math,
  KM_CommonClasses, KM_CommonTypes, KM_CommonUtils, KM_Defaults, KM_Points,
  KM_Units, KM_UnitGroup,
  KM_NavMesh, KM_NavMeshGenerator, KM_NavMeshInfluences,
  KM_NavMeshFloodFill, KM_FloodFill;


const
  // Avoid bulding values of specific actions (tile lock by specific action)
  AVOID_BUILDING_UNLOCK = 0;
  AVOID_BUILDING_HOUSE_OUTSIDE_LOCK = 10;
  AVOID_BUILDING_HOUSE_INSIDE_LOCK = 15;
  AVOID_BUILDING_COAL_TILE = 20;
  AVOID_BUILDING_NODE_LOCK_FIELD = 25;
  AVOID_BUILDING_NODE_LOCK_ROAD = 30;
  AVOID_BUILDING_MINE_TILE = 40;
  AVOID_BUILDING_FOREST_RANGE = 200; // Value: 255 <-> AVOID_BUILDING_FOREST_VARIANCE which may forest tiles have
  AVOID_BUILDING_FOREST_MINIMUM = 254 - AVOID_BUILDING_FOREST_RANGE; // Minimum value of forest reservation tiles


type

  //Collection of influence maps
  TKMInfluences = class
  private
    fMapX, fMapY, fPolygons: Word; // Limits of arrays

    fAvoidBuilding: TKMByteArray; //Common map of areas where building is undesired (around Store, Mines, Woodcutters)
    fUpdateCityIdx, fUpdateArmyIdx: TKMHandID; // Update index
    fPresence: TKMWordArray; // Military presence
    fOwnership: TKMByteArray; // City mark the space around itself

    fInfluenceFloodFill: TKMInfluenceFloodFill;
    fInfluenceSearch: TNavMeshInfluenceSearch;
    fNavMesh: TKMNavMesh;

    // Avoid building
    procedure InitAvoidBuilding();
    function GetAvoidBuilding(const aY,aX: Word): Byte;
    procedure SetAvoidBuilding(const aY,aX: Word; const aValue: Byte);
    // Army presence
    function GetPresence(const aPL: TKMHandID; const aIdx: Word; const aGT: TKMGroupType): Word; inline;
    procedure SetPresence(const aPL: TKMHandID; const aIdx: Word; const aGT: TKMGroupType; const aPresence: Word); inline;
    procedure SetIncPresence(const aPL: TKMHandID; const aIdx: Word; const aGT: TKMGroupType; const aPresence: Word); inline;
    function GetAllPresences(const aPL: TKMHandID; const aIdx: Word): Word; inline;
    function GetArmyTraffic(const aOwner: TKMHandID; const aIdx: Word): Word;
    function GetEnemyGroupPresence(const aPL: TKMHandID; const aIdx: Word; const aGT: TKMGroupType): Word;
    //function GetAlliancePresence(const aPL: TKMHandIndex; aIdx: Word; const aAllianceType: TKMAllianceType): Word;
    procedure UpdateMilitaryPresence(const aPL: TKMHandID);
    // City influence
    function GetOwnership(const aPL: TKMHandID; const aIdx: Word): Byte; inline;
    procedure SetOwnership(const aPL: TKMHandID; const aIdx: Word; const aOwnership: Byte); inline;
    function GetOwnershipFromPoint(const aPL: TKMHandID; const aY, aX: Word): Byte; inline; // For property -> aY, aX are switched!
    procedure SetOwnershipFromPoint(const aPL: TKMHandID; const aY, aX: Word; const aOwnership: Byte); inline; // For property -> aY, aX are switched!
    procedure UpdateOwnership(const aPL: TKMHandID);
    // Common
    procedure InitArrays();
  public
    constructor Create(aNavMesh: TKMNavMesh);
    destructor Destroy(); override;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

    // Avoid building
    property AvoidBuilding[const aY,aX: Word]: Byte read GetAvoidBuilding write SetAvoidBuilding;
    // Army presence
    property Presence[const aPL: TKMHandID; const aIdx: Word; const aGT: TKMGroupType]: Word read GetPresence write SetPresence;
    property IncPresence[const aPL: TKMHandID; const aIdx: Word; const aGT: TKMGroupType]: Word write SetIncPresence;
    property PresenceAllGroups[const aPL: TKMHandID; const aIdx: Word]: Word read GetAllPresences;
    property ArmyTraffic[const aOwner: TKMHandID; const aIdx: Word]: Word read GetArmyTraffic;
    property EnemyGroupPresence[const aPL: TKMHandID; const aIdx: Word; const aGT: TKMGroupType]: Word read GetEnemyGroupPresence;
    //property AlliancePresence[const aPL: TKMHandIndex; aIdx: Word; const aAllianceType: TKMAllianceType]: Word read GetAlliancePresence;
    // City influence
    property Ownership[const aPL: TKMHandID; const aY,aX: Word]: Byte read GetOwnershipFromPoint write SetOwnershipFromPoint; // To secure compatibility with old AI
    property OwnPoly[const aPL: TKMHandID; const aIdx: Word]: Byte read GetOwnership write SetOwnership;
    // Common
    property InfluenceSearch: TNavMeshInfluenceSearch read fInfluenceSearch write fInfluenceSearch;

    // Avoid building
    procedure AddAvoidBuilding(aX,aY: Word; aRad: Single);
    procedure RemAvoidBuilding(aArea: TKMRect);
    procedure MarkForest(aPoint: TKMPoint; aRad, aDecreaseCoef: Single);
    // Army presence
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

    procedure AfterMissionInit();
    procedure UpdateState(aTick: Cardinal);
    procedure Paint(const aRect: TKMRect);
  end;


implementation
uses
  Classes, Graphics, SysUtils,
  KM_RenderAux, KM_Resource,
  KM_Terrain, KM_Houses, KM_HouseCollection,
  KM_Hand, KM_HandsCollection, KM_ResHouses,
  KM_AIFields;


{ TKMInfluenceMaps }
constructor TKMInfluences.Create(aNavMesh: TKMNavMesh);
begin
  inherited Create();

  fNavMesh := aNavMesh;
  fUpdateCityIdx := 0;
  fUpdateArmyIdx := 0;
  fInfluenceFloodFill := TKMInfluenceFloodFill.Create(False); // Check if True is better
  fInfluenceSearch := TNavMeshInfluenceSearch.Create(False);
end;


destructor TKMInfluences.Destroy();
begin
  fInfluenceFloodFill.Free;
  fInfluenceSearch.Free;
  inherited;
end;


procedure TKMInfluences.Save(SaveStream: TKMemoryStream);
var
  Len: Integer;
begin

  SaveStream.WriteA('Influences');
  SaveStream.Write(fMapX);
  SaveStream.Write(fMapY);
  SaveStream.Write(fPolygons);
  SaveStream.Write(fUpdateCityIdx,SizeOf(fUpdateCityIdx));
  SaveStream.Write(fUpdateArmyIdx,SizeOf(fUpdateArmyIdx));

  SaveStream.WriteA('AvoidBuilding');
  SaveStream.Write(fAvoidBuilding[0], SizeOf(fAvoidBuilding[0]) * Length(fAvoidBuilding));

  SaveStream.WriteA('Ownership');
  Len := Length(fOwnership);
  SaveStream.Write(Len);
  SaveStream.Write(fOwnership[0], SizeOf(fOwnership[0]) * Len);

  SaveStream.WriteA('ArmyPresence');
  Len := Length(fPresence);
  SaveStream.Write(Len);
  SaveStream.Write(fPresence[0], SizeOf(fPresence[0]) * Len);
end;


procedure TKMInfluences.Load(LoadStream: TKMemoryStream);
var
  Len: Integer;
begin
  LoadStream.ReadAssert('Influences');
  LoadStream.Read(fMapX);
  LoadStream.Read(fMapY);
  LoadStream.Read(fPolygons);
  LoadStream.Read(fUpdateCityIdx,SizeOf(fUpdateCityIdx));
  LoadStream.Read(fUpdateArmyIdx,SizeOf(fUpdateArmyIdx));

  LoadStream.ReadAssert('AvoidBuilding');
  SetLength(fAvoidBuilding, fMapY * fMapX);
  LoadStream.Read(fAvoidBuilding[0], SizeOf(fAvoidBuilding[0]) * fMapY * fMapX);

  LoadStream.ReadAssert('Ownership');
  LoadStream.Read(Len);
  SetLength(fOwnership, Len);
  LoadStream.Read(fOwnership[0], SizeOf(fOwnership[0]) * Len);

  LoadStream.ReadAssert('ArmyPresence');
  LoadStream.Read(Len);
  SetLength(fPresence, Len);
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


procedure TKMInfluences.MarkForest(aPoint: TKMPoint; aRad, aDecreaseCoef: Single);
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
        AvoidBuilding[Y,X] := Min( 254, // Forest does not reach full 255
                                   Max( AVOID_BUILDING_FOREST_MINIMUM, // Forest start at this value
                                        AvoidBuilding[Y,X] + 254 - Round(SqrDist * aDecreaseCoef)
                                      )
                                 );
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
      AvoidBuilding[Y,X] := $FF;
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




function TKMInfluences.GetAllPresences(const aPL: TKMHandID; const aIdx: Word): Word;
var
  Idx: Integer;
  GT: TKMGroupType;
begin
  Result := 0;
  Idx := (aPL*fPolygons + aIdx) shl 2;
  for GT := Low(TKMGroupType) to High(TKMGroupType) do
    Result := Min(High(Word), Result + fPresence[Idx + Byte(GT)]);
end;


function TKMInfluences.GetArmyTraffic(const aOwner: TKMHandID; const aIdx: Word): Word;
const
  MAX_SOLDIERS_IN_POLYGON = 20; // Maximal count of soldiers in 1 triangle of NavMesh - it depends on NavMesh size!!!
var
  PL: TKMHandID;
begin
  Result := 0;
  for PL := 0 to gHands.Count - 1 do
    //if (PL <> aOwner) then
    begin
      Result := Result + GetAllPresences(PL, aIdx);
      if (Result > MAX_SOLDIERS_IN_POLYGON) then // Influences may overlap but in 1 polygon can be max [MAX_SOLDIERS_IN_POLYGON] soldiers
      begin
        Result := MAX_SOLDIERS_IN_POLYGON;
        break;
      end;
    end;
end;


function TKMInfluences.GetPresence(const aPL: TKMHandID; const aIdx: Word; const aGT: TKMGroupType): Word;
begin
  Result := fPresence[((aPL*fPolygons + aIdx)*4) + Byte(aGT)];
end;


procedure TKMInfluences.SetPresence(const aPL: TKMHandID; const aIdx: Word; const aGT: TKMGroupType; const aPresence: Word);
begin
  fPresence[((aPL*fPolygons + aIdx)*4) + Byte(aGT)] := aPresence;
end;


procedure TKMInfluences.SetIncPresence(const aPL: TKMHandID; const aIdx: Word; const aGT: TKMGroupType; const aPresence: Word);
begin
  Inc(  fPresence[ ((aPL*fPolygons + aIdx)*4) + Byte(aGT) ], aPresence  );
end;


function TKMInfluences.GetEnemyGroupPresence(const aPL: TKMHandID; const aIdx: Word; const aGT: TKMGroupType): Word;
var
  PL: TKMHandID;
begin
  Result := 0;
  for PL := 0 to gHands.Count - 1 do
    if gHands[PL].Enabled AND (gHands[aPL].Alliances[PL] = atEnemy) then
      Result := Result + Presence[PL, aIdx, aGT];
end;


procedure TKMInfluences.UpdateMilitaryPresence(const aPL: TKMHandID);
const
  EACH_X_MEMBER_COEF = 10;
  MAX_DISTANCE = 20;
var
  I, K, Cnt: Integer;
  G: TKMUnitGroup;
  U: TKMUnit;
  PointArr: TKMWordArray;
begin
  FillChar(fPresence[aPL*fPolygons*4], SizeOf(fPresence[0]) * fPolygons * 4, #0);

  SetLength(PointArr,16);
  for I := 0 to gHands[aPL].UnitGroups.Count-1 do
  begin
    G := gHands[aPL].UnitGroups.Groups[I];
    if (G = nil) OR G.IsDead then
      continue;
    K := 0;
    Cnt := 0;
    while (K < G.Count) do
    begin
      U := G.Members[K];
      if (U <> nil) AND not U.IsDeadOrDying then
      begin
        if (Length(PointArr) <= Cnt) then
          SetLength(PointArr, Cnt + 16);
        PointArr[Cnt] := gAIFields.NavMesh.KMPoint2Polygon[ U.CurrPosition ];
        Cnt := Cnt + 1;
      end;
      K := K + EACH_X_MEMBER_COEF; // Pick each X member (Huge groups cover large areas so be sure that influence will be accurate)
    end;

    if (Cnt > 0) then
      //fFloodFill.MilitaryPresence(aPL, gAIFields.Eye.ArmyEvaluation.GroupStrength(G), MAX_DISTANCE, Cnt-1, G.GroupType, PointArr);
      fInfluenceFloodFill.MilitaryPresence(aPL, Min(G.Count,30), MAX_DISTANCE, Cnt-1, G.GroupType, PointArr);
  end;
end;






function TKMInfluences.GetOwnership(const aPL: TKMHandID; const aIdx: Word): Byte;
begin
  Result := fOwnership[aPL * fPolygons + aIdx];
end;


procedure TKMInfluences.SetOwnership(const aPL: TKMHandID; const aIdx: Word; const aOwnership: Byte);
begin
  fOwnership[aPL * fPolygons + aIdx] := aOwnership;
end;


function TKMInfluences.GetOwnershipFromPoint(const aPL: TKMHandID; const aY, aX: Word): Byte;
begin
  Result := GetOwnership(aPL, fNavMesh.Point2Polygon[aY,aX]);
end;


procedure TKMInfluences.SetOwnershipFromPoint(const aPL: TKMHandID; const aY, aX: Word; const aOwnership: Byte);
begin
  SetOwnership(aPL, fNavMesh.Point2Polygon[aY,aX], aOwnership);
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
  Result := PLAYER_NONE;
  if not AI_GEN_INFLUENCE_MAPS OR (aIdx = High(Word)) then
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
  Result := PLAYER_NONE;
  Idx := fNavMesh.Point2Polygon[aPoint.Y,aPoint.X];
  if not AI_GEN_INFLUENCE_MAPS OR (Idx = High(Word)) then
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
//  if not AI_GEN_INFLUENCE_MAPS then
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
  if not AI_GEN_INFLUENCE_MAPS then
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
  if not AI_GEN_INFLUENCE_MAPS then
    Exit;

  Result := 0;
  for PL := 0 to gHands.Count - 1 do
    if (PL <> aPL) then
    begin
      Ownership := OwnPoly[PL,aIdx];
      Inc(Result, ifthen(gHands[aPL].Alliances[PL] = atAlly, Ownership, Ownership*ENEMY_COEF));
    end;
end;


function TKMInfluences.CanPlaceHouseByInfluence(const aPL: TKMHandID; const aX,aY: Word; const aIgnoreAllies: Boolean = False): Boolean;
begin
  Result := CanPlaceHouseByInfluence(aPL, fNavMesh.Point2Polygon[aY,aX], aIgnoreAllies);
end;


function TKMInfluences.CanPlaceHouseByInfluence(const aPL: TKMHandID; const aIdx: Word; const aIgnoreAllies: Boolean = False): Boolean;
var
  BestOwner: TKMHandID;
begin
  BestOwner := GetBestOwner(aIdx);
  Result := (BestOwner >= 0) AND (OwnPoly[aPL, aIdx] > 0) AND ((BestOwner = aPL) OR (not aIgnoreAllies AND (gHands[aPL].Alliances[BestOwner] = atAlly)));
end;


// Here is the main reason for reworking influences: only 1 flood fill for city per a update + ~25x less elements in array
procedure TKMInfluences.UpdateOwnership(const aPL: TKMHandID);
const
  INIT_HOUSE_INFLUENCE = 255;
  MAX_INFLUENCE_DISTANCE = 150;
var
  I, Cnt: Integer;
  H: TKMHouse;
  IdxArray: TKMWordArray;
begin
  //Clear array (is better to clear ~3000 polygons instead of 255*255 tiles)
  FillChar(fOwnership[aPL*fPolygons], SizeOf(fOwnership[0]) * fPolygons, #0);

  // Create array of polygon indexes
  SetLength(IdxArray, gHands[aPL].Houses.Count);
  Cnt := 0;
  for I := 0 to gHands[aPL].Houses.Count - 1 do
  begin
    H := gHands[aPL].Houses[I];
    if not H.IsDestroyed AND not (H.HouseType in [htWatchTower, htWoodcutters]) then
    begin
        IdxArray[Cnt] := fNavMesh.KMPoint2Polygon[ H.Position ];
        Cnt := Cnt + 1;
    end;
  end;

  if (Cnt > 0) then
    fInfluenceFloodFill.HouseInfluence(aPL, INIT_HOUSE_INFLUENCE, MAX_INFLUENCE_DISTANCE, Cnt - 1, IdxArray);
end;



procedure TKMInfluences.InitArrays();
var
  PL: TKMHandID;
begin
  if (fPolygons < Length(gAIFields.NavMesh.Polygons)) then
  begin
    fPolygons := Length(gAIFields.NavMesh.Polygons);
    SetLength(fPresence, gHands.Count * fPolygons * 4);
    SetLength(fOwnership, gHands.Count * fPolygons);
  end;
  FillChar(fPresence[0], SizeOf(fPresence[0]) * Length(fPresence), #0);
  FillChar(fOwnership[0], SizeOf(fOwnership[0]) * Length(fOwnership), #0);
  if AI_GEN_INFLUENCE_MAPS then
    for PL := 0 to gHands.Count - 1 do
    begin
      UpdateMilitaryPresence(PL);
      UpdateOwnership(PL);
    end;
end;


procedure TKMInfluences.AfterMissionInit();
begin
  fMapX := gTerrain.MapX;
  fMapY := gTerrain.MapY;
  SetLength(fAvoidBuilding, fMapY * fMapX);

  InitAvoidBuilding();
  InitArrays();
end;


procedure TKMInfluences.UpdateState(aTick: Cardinal);
begin
  // City:
  if aTick mod 150 = 15 then // Update every 15 sec 1 player
  begin
    fUpdateCityIdx := (fUpdateCityIdx + 1) mod gHands.Count;
    UpdateOwnership(fUpdateCityIdx);
  end;
  // Army:
  if (aTick mod 5 = 0) then // Update every 0.5 sec 1 player
  begin
    fUpdateArmyIdx := (fUpdateArmyIdx + 1) mod gHands.Count;
    UpdateMilitaryPresence(fUpdateArmyIdx);
  end;
end;


//Render debug symbols
procedure TKMInfluences.Paint(const aRect: TKMRect);
const
  COLOR_WHITE = $FFFFFF;
  COLOR_BLACK = $000000;
  COLOR_GREEN = $00FF00;
  COLOR_RED = $0000FF;
  COLOR_YELLOW = $00FFFF;
  COLOR_BLUE = $FF0000;
var
  PL, WatchedPL: TKMHandID;
  I, Cnt: Word;
  X,Y: Integer;
  PolyArr: TPolygonArray;
  NodeArr: TKMPointArray;
  Col: Cardinal;
begin

  if not AI_GEN_NAVMESH OR not AI_GEN_INFLUENCE_MAPS then
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
    PolyArr := fNavMesh.Polygons;
    NodeArr := fNavMesh.Nodes;
    for I := 0 to fPolygons - 1 do
    begin
      PL := GetBestOwner(I);
      if (PL = PLAYER_NONE) then
        continue
      else
        Col := (gHands[PL].FlagColor AND COLOR_WHITE) OR (OwnPoly[PL,I] shl 24);

      //NavMesh polys coverage
      gRenderAux.TriangleOnTerrain(
        NodeArr[PolyArr[I].Indices[0]].X,
        NodeArr[PolyArr[I].Indices[0]].Y,
        NodeArr[PolyArr[I].Indices[1]].X,
        NodeArr[PolyArr[I].Indices[1]].Y,
        NodeArr[PolyArr[I].Indices[2]].X,
        NodeArr[PolyArr[I].Indices[2]].Y, Col);
    end;
  end;

  if (OVERLAY_INFLUENCE OR OVERLAY_OWNERSHIP) AND OVERLAY_AI_COMBAT then
  begin
    WatchedPL := gMySpectator.HandID;
    if (WatchedPL = PLAYER_NONE) then
      Exit;

    PolyArr := fNavMesh.Polygons;
    NodeArr := fNavMesh.Nodes;

    for PL := 0 to gHands.Count - 1 do
    begin
      if (WatchedPL = PL) then
        Col := COLOR_GREEN
      else if (gHands[WatchedPL].Alliances[PL] = atAlly) then
        Col := COLOR_BLUE
      else
        Col := COLOR_RED;

      for I := 0 to fPolygons - 1 do
      begin
        Cnt := PresenceAllGroups[PL,I];
        if (Cnt > 0) then
        begin
          Cnt := Min(Max(Cnt,$3F),$FF);
          //NavMesh polys coverage
          gRenderAux.TriangleOnTerrain(
            NodeArr[PolyArr[I].Indices[0]].X,
            NodeArr[PolyArr[I].Indices[0]].Y,
            NodeArr[PolyArr[I].Indices[1]].X,
            NodeArr[PolyArr[I].Indices[1]].Y,
            NodeArr[PolyArr[I].Indices[2]].X,
            NodeArr[PolyArr[I].Indices[2]].Y, (Col OR (Cnt shl 24)) ); // (Col OR $50000000)
        end;
      end;
    end;
    {
    for I := 0 to fPolygons - 1 do
    begin
      BestCnt := 0;
      for PL := 0 to gHands.Count - 1 do
      begin
        Cnt := PresenceAllGroups[PL,I];
        if (Cnt > BestCnt) then
        begin
          BestCnt := Cnt;
          if (WatchedPL = PL) then
            Col := COLOR_GREEN
          else if (gHands[WatchedPL].Alliances[PL] = atAlly) then
            Col := COLOR_BLUE
          else
            Col := COLOR_RED;
        end;
      end;
      if (BestCnt > 0) then
      begin
        BestCnt := Min(BestCnt,$9F);
        //NavMesh polys coverage
        gRenderAux.TriangleOnTerrain(
          NodeArr[PolyArr[I].Indices[0]].X,
          NodeArr[PolyArr[I].Indices[0]].Y,
          NodeArr[PolyArr[I].Indices[1]].X,
          NodeArr[PolyArr[I].Indices[1]].Y,
          NodeArr[PolyArr[I].Indices[2]].X,
          NodeArr[PolyArr[I].Indices[2]].Y, (Col OR (BestCnt shl 24)) );
      end;
    end;
    //}
  end;
end;


end.

