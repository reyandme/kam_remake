unit KM_HandsCollection;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, Generics.Collections,
  KM_Hand, KM_HandSpectator, KM_HouseCollection,
  KM_Houses, KM_ResHouses, KM_Units, KM_UnitGroup, KM_UnitWarrior,
  KM_CommonClasses, KM_CommonTypes, KM_Defaults, KM_Points,
  KM_HandEntity,
  KM_HandTypes,
  KM_GameTypes,
  KM_MapTypes,
  KM_ResTypes;


type
  // Hands are identified by their starting location
  TKMHandsCollection = class
  private
    fCount: Byte;
    fHandsList: array of TKMHand;
    fPlayerAnimals: TKMHandAnimals;
    fCheckGoals: Boolean; //Do we need to check goals. Used to prevent check goals for all hands if some hand does not choose first storehouse
    //Not saved
    fTeams: TKMByteSetArray;
    fTeamsDirty: Boolean; //Need to recalc teams

    function GetTeams: TKMByteSetArray;
    function GetTeamsLazy: TKMByteSetArray;
    function GetHand(aIndex: Integer): TKMHand; inline;
    procedure SetHandsTeamColors;
    procedure AllianceChanged;

    function FindPlaceForUnit(aX, aY: Integer; aUnit: TKMUnit; aUnitType: TKMUnitType; out aPlacePoint: TKMPoint; aRequiredWalkConnect: Byte): Boolean; overload;
    function GetCount: Byte;
  public
    constructor Create;
    destructor Destroy; override;

    property Count: Byte read GetCount;
    property Hands[aIndex: Integer]: TKMHand read GetHand; default;
    property PlayerAnimals: TKMHandAnimals read fPlayerAnimals;

    procedure AfterMissionInit;

    procedure AddPlayers(aCount: Byte); //Batch add several players

    procedure UpdateHandState(aHandID: TKMHandID; aHandType: TKMHandType; aAIType: TKMAIType);

    procedure RemoveEmptyPlayers;
    procedure RemoveEmptyPlayer(aIndex: TKMHandID);
    procedure RemoveAssetsOutOfBounds(const aInsetRect: TKMRect);
    procedure RemovePlayerAssets(aIndex: TKMHandID);

    function HousesHitTest(X,Y: Integer): TKMHouse;
    function UnitsHitTest(X, Y: Integer): TKMUnit;
    function GroupsHitTest(X, Y: Integer): TKMUnitGroup;

    function GetClosestGroup(const aLoc: TKMPoint; aIndex: TKMHandID; aAlliance: TKMAllianceType; aTypes: TKMGroupTypeSet = GROUP_TYPES_VALID): TKMUnitGroup;
    function GetGroupsInRadius(const aLoc: TKMPoint; aSqrRadius: Single; aIndex: TKMHandID; aAlliance: TKMAllianceType; aTypes: TKMGroupTypeSet = GROUP_TYPES_VALID): TKMUnitGroupArray;
    function GetGroupsMemberInRadius(const aLoc: TKMPoint; aSqrRadius: Single; aIndex: TKMHandID; aAlliance: TKMAllianceType; var aUGA: TKMUnitGroupArray; aTypes: TKMGroupTypeSet = GROUP_TYPES_VALID): TKMUnitArray;
    function GetClosestUnit(const aLoc: TKMPoint; aIndex: TKMHandID; aAlliance: TKMAllianceType): TKMUnit;
    function GetClosestHouse(const aLoc: TKMPoint; aIndex: TKMHandID; aAlliance: TKMAllianceType; aTypes: TKMHouseTypeSet = HOUSES_VALID; aOnlyCompleted: Boolean = True): TKMHouse;
    function GetHousesInRadius(const aLoc: TKMPoint; aSqrRadius: Single; aIndex: TKMHandID; aAlliance: TKMAllianceType; aTypes: TKMHouseTypeSet = HOUSES_VALID; aOnlyCompleted: Boolean = True): TKMHouseArray;
    function DistanceToEnemyTowers(const aLoc: TKMPoint; aIndex: TKMHandID): Single;

    procedure GetUnitsInRect(const aRect: TKMRect; List: TList<TKMUnit>);
    procedure GetGroupsInRect(const aRect: TKMRect; List: TList<TKMUnitGroup>);
    procedure GetHousesInRect(const aRect: TKMRect; List: TList<TKMHouse>);

    function GetHouseByUID(aUID: Integer): TKMHouse;
    function GetUnitByUID(aUID: Integer): TKMUnit;
    function GetGroupByUID(aUID: Integer): TKMUnitGroup;
    function GetObjectByUID(aUID: Integer): TKMHandEntity;

    function GetNextHouseWSameType(aHouse: TKMHouse): TKMHouse;
    function GetNextUnitWSameType(aUnit: TKMUnit): TKMUnit;
    function GetNextGroupWSameType(aUnitGroup: TKMUnitGroup): TKMUnitGroup;

    function GetGroupByMember(aWarrior: TKMUnitWarrior): TKMUnitGroup;
    function HitTest(X,Y: Integer): TObject;
    function UnitCount: Integer;

    function FindPlaceForUnit(aX, aY: Integer; aUnit: TKMUnit; var aPlacePoint: TKMPoint; aRequiredWalkConnect: Byte): Boolean; overload;
    function FindPlaceForUnit(aX, aY: Integer; aUnitType: TKMUnitType; var aPlacePoint: TKMPoint; aRequiredWalkConnect: Byte): Boolean; overload;

    //Check how Player1 feels towards Player2
    //Note: this is position dependant, e.g. Player1 may be allied with
    //      Player2, but Player2 could be an enemy to Player1
    function CheckAlliance(aPlay1, aPlay2: TKMHandID): TKMAllianceType;
    function GetTeamsOfAllies: TKMByteSetArray;
    property Teams: TKMByteSetArray read GetTeamsLazy;
    function GetHandToSpectate: TKMHandID;
    procedure CleanUpUnitPointer(var aUnit: TKMUnit);
    procedure CleanUpGroupPointer(var aGroup: TKMUnitGroup);
    procedure CleanUpHousePointer(var aHouse: TKMHouse);
    function RemAnyHouse(const Position: TKMPoint): Boolean;
    function RemAnyUnit(const Position: TKMPoint): Boolean;
    procedure RevealForTeam(aPlayer: TKMHandID; const Pos: TKMPoint; Radius,Amount: Word);
    procedure SyncFogOfWar;
    procedure AddDefaultGoalsToAll(aMissionMode: TKMissionMode);
    procedure UpdateGoalsForHand(aHandIndex: TKMHandID; aEnable: Boolean);
    function DoCheckGoals: Boolean;
    procedure PostLoadMission;

    function CanHaveAI: Boolean;
    function CanHaveAdvancedAI: Boolean;
    function HaveAI: Boolean;
    function HaveAdvancedAI: Boolean;
    function IsAllowedAIAtAnyHand: Boolean;
    function IsAllowedAdvancedAIAtAnyHand: Boolean;

    procedure Save(SaveStream: TKMemoryStream; aMultiplayer: Boolean);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad;
    procedure IncAnimStep;

    procedure UpdateState(aTick: Cardinal);
    procedure UpdateVisualState;
    procedure Paint(const aRect: TKMRect; aTickLag: Single);
    function ObjToString: String;

    procedure ExportGameStatsToCSV(const aPath: String; const aHeader: String = '');
  end;

var
  gHands: TKMHandsCollection;
  gMySpectator: TKMSpectator; //Wrap to access player/fow separately


implementation
uses
  SysUtils,
  KromUtils,
  KM_Game, KM_GameParams, KM_Terrain, KM_AIFields,
  KM_UnitsCollection, KM_MapEdTypes,
  KM_Resource, KM_ResUnits, KM_ResTexts,
  KM_Log, KM_CommonUtils, KM_DevPerfLog, KM_DevPerfLogTypes, KM_Entity;


{ TKMHandsCollection }
constructor TKMHandsCollection.Create;
begin
  inherited Create;

  fTeamsDirty := True;

  fPlayerAnimals := TKMHandAnimals.Create(HAND_ANIMAL); //Always create Animals
end;


destructor TKMHandsCollection.Destroy;
var
  I: Integer;
begin
  for I := 0 to fCount - 1 do
    FreeThenNil(fHandsList[I]);

  PlayerAnimals.Free;

  inherited;
end;


function TKMHandsCollection.GetHand(aIndex: Integer): TKMHand;
begin
  if (Self = nil) or not InRange(aIndex, 0, Length(fHandsList) - 1) then Exit(nil);

  //We have Range Checks enabled so such an error will be caught and reported already
  //Assert(InRange(aIndex, 0, fCount-1));
  Result := fHandsList[aIndex];
end;


procedure TKMHandsCollection.AddPlayers(aCount: Byte);
var
  I, K: Integer;
begin
  Assert(fCount + aCount <= MAX_HANDS);

  SetLength(fHandsList, fCount + aCount);

  for I := fCount to fCount + aCount - 1 do
    fHandsList[I] := TKMHand.Create(I, AllianceChanged);

  //Default alliance settings for new players:
  //Existing players treat any new players as enemies
  for I := 0 to fCount - 1 do
    for K := fCount to fCount + aCount - 1 do
      fHandsList[I].Alliances[K] := atEnemy;

  //New players treat all players as enemies except self
  for I := fCount to fCount + aCount - 1 do
  begin
    for K := 0 to MAX_HANDS - 1 do
      fHandsList[I].Alliances[K] := atEnemy;
    fHandsList[I].Alliances[I] := atAlly;
  end;

  fCount := fCount + aCount;
end;


// Update hand state (AI type)
procedure TKMHandsCollection.UpdateHandState(aHandID: TKMHandID; aHandType: TKMHandType; aAIType: TKMAIType);
begin
  fHandsList[aHandID].HandType := aHandType;

  if fHandsList[aHandID].IsComputer then
  begin
    //For MP locs we will set AI MP setup only when loc is allowed for humans too.
    //For only AI locs there we should use AI params set from MapEd
    case aAIType of
      aitAdvanced:  // Do not apply AI Multiplayer setup for special maps
                    if not gGame.MapTxtInfo.IsSpecial and fHandsList[aHandID].CanBeHuman then
                      fHandsList[aHandID].AI.Setup.ApplyMultiplayerSetup(True)
                    else
                      //Just enable Advanced AI, do not override MapEd AI params
                      fHandsList[aHandID].AI.Setup.EnableAdvancedAI(True);
                    // Do not enable MP setup for classic AI on the game start, only in the MapEd
      aitClassic:   fHandsList[aHandID].AI.Setup.EnableAdvancedAI(False);
    end;
  end
  else
  //We can start to play for defeated hand, f.e. if player just left the game and we restart from save with other player
  if fHandsList[aHandID].IsHuman and fHandsList[aHandID].AI.HasLost then
  begin
    fHandsList[aHandID].AI.ResetWonOrLost; //Reset WonOrLost status
    UpdateGoalsForHand(aHandID, True); //Enable this hand goals for all other hands
  end;
end;


procedure TKMHandsCollection.AfterMissionInit;
var
  I: Integer;
  canHaveAdvAIOnMap: Boolean;
  handsWithAIStartStorageI: TByteSet;
begin
  canHaveAdvAIOnMap := CanHaveAdvancedAI();

  // Find if there are some hands which has to place starting storehouse
  handsWithAIStartStorageI := [];
  if not gGameParams.IsMapEditor then
    for I := 0 to fCount - 1 do
      with fHandsList[I] do
        if Enabled and IsComputer and NeedToChooseFirstStorehouse() then
          handsWithAIStartStorageI := handsWithAIStartStorageI + [I];

  //RMG place storehouse before assembling NavMesh and create influences so AI initialize correctly
  if (handsWithAIStartStorageI <> []) or canHaveAdvAIOnMap then
    gAIFields.Eye.AfterMissionInit(); // Update Eye so it sees all mines on the map

  // Place first storehouse
  for I in handsWithAIStartStorageI do
    fHandsList[I].AI.PlaceFirstStorehouse(fHandsList[I].CenterScreen);

  // For quick play we allow AI opponents even when loc does not allow it...
  if CanHaveAI() then
    gAIFields.AfterMissionInit(canHaveAdvAIOnMap);

  GetTeamsLazy;

  for I := 0 to fCount - 1 do
    fHandsList[I].AfterMissionInit(not gGameParams.IsMapEditor); // Don't flatten roads in MapEd
end;


function TKMHandsCollection.CanHaveAI: Boolean;
begin
  // SP game will set Classic AI by default, even if all AIs are prohibited on the loc
  Result := HaveAI or IsAllowedAIAtAnyHand;
end;


function TKMHandsCollection.CanHaveAdvancedAI: Boolean;
begin
  Result := HaveAdvancedAI or IsAllowedAdvancedAIAtAnyHand;
end;


function TKMHandsCollection.HaveAI: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to fCount - 1 do
    if fHandsList[I].IsComputer then
      Exit(True);
end;


function TKMHandsCollection.HaveAdvancedAI: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to fCount - 1 do
    if fHandsList[I].IsComputer and fHandsList[I].AI.Setup.NewAI then
      Exit(True);
end;


function TKMHandsCollection.IsAllowedAIAtAnyHand: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to fCount - 1 do
    if fHandsList[I].CanBeAITypes * [aitClassic, aitAdvanced] <> [] then // Some AI is allowed
      Exit(True);
end;


function TKMHandsCollection.IsAllowedAdvancedAIAtAnyHand: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to fCount - 1 do
    if aitAdvanced in fHandsList[I].CanBeAITypes then
      Exit(True);
end;


// Remove hand assets aout of bounds first (units / houses)
procedure TKMHandsCollection.RemoveAssetsOutOfBounds(const aInsetRect: TKMRect);
var
  I: Integer;
begin
  if aInsetRect = KMRECT_ZERO then Exit; //We have no bounds restriction - nothing to remove
  if    (aInsetRect.Left   <= 0)
    and (aInsetRect.Top    <= 0)
    and (aInsetRect.Right  >= 0)
    and (aInsetRect.Bottom >= 0) then Exit; //InsetRect enlarges current map rect - nothing to remove


  for I := 0 to Count - 1 do
  begin
    if not fHandsList[I].HasAssets then Continue;

    fHandsList[I].Houses.RemoveHousesOutOfBounds(aInsetRect);
    fHandsList[I].Units.RemoveUnitsOutOfBounds(aInsetRect);
  end;
end;


procedure TKMHandsCollection.RemovePlayerAssets(aIndex: TKMHandID);
begin
  if Self = nil then Exit;
  if fCount = 0 then Exit;
  if not InRange(aIndex, 0, fCount - 1) then Exit;

  fHandsList[aIndex].Units.RemoveAllUnits;
  fHandsList[aIndex].UnitGroups.RemAllGroups;
  fHandsList[aIndex].Houses.RemoveAllHouses;
  gTerrain.ClearPlayerLand(aIndex);
  fHandsList[aIndex].AI.Goals.Clear;
  fHandsList[aIndex].AI.General.Attacks.Clear;
  fHandsList[aIndex].AI.General.DefencePositions.Clear;
  fHandsList[aIndex].ResetChooseLocation;
end;


//We assume that if player has no assets it is unused and can be removed from end
//Don't remove players in the middle, if user uses players 1 and 8 then 2..7 are kept
//Accessed only by MapEditor when it needs to remove empty players before saving a map
procedure TKMHandsCollection.RemoveEmptyPlayers;
var
  I: Integer;
begin
  for I := Count - 1 downto 0 do
    if fHandsList[I].HasAssets then
      Exit //Exit as soon as we find a player with assets
    else
      RemoveEmptyPlayer(I);
end;


//Remove empty player 'aIndex'
//Accessed only by MapEditor when it needs to remove empty players before saving a map
procedure TKMHandsCollection.RemoveEmptyPlayer(aIndex: TKMHandID);
var
  I, K: Integer;
begin
  //Remove other players goals using this player
  for I := 0 to fCount - 1 do
    fHandsList[I].AI.Goals.RemoveReference(aIndex);

  FreeThenNil(fHandsList[aIndex]);

  for I := aIndex to fCount - 2 do
  begin
    fHandsList[I] := fHandsList[I + 1];
    fHandsList[I].SetHandIndex(I);
  end;

  Dec(fCount);
  SetLength(fHandsList, fCount);

  for I := 0 to fCount - 1 do
    for K := aIndex to fCount - 1 do
      fHandsList[I].Alliances[K] := fHandsList[I].Alliances[K + 1];

  gTerrain.RemovePlayer(aIndex);
end;


function TKMHandsCollection.HousesHitTest(X, Y: Integer): TKMHouse;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to fCount - 1 do
  begin
    Result := fHandsList[I].HousesHitTest(X, Y);
    if Result <> nil then
      Exit; //There can't be 2 houses on one tile
  end;
end;


function TKMHandsCollection.UnitsHitTest(X, Y: Integer): TKMUnit;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to fCount - 1 do
  begin
    Result := fHandsList[I].UnitsHitTest(X, Y);
    if Result <> nil then
      Exit; //There can't be 2 units on one tile
  end;
end;


function TKMHandsCollection.GroupsHitTest(X, Y: Integer): TKMUnitGroup;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to fCount - 1 do
  begin
    Result := fHandsList[I].GroupsHitTest(X, Y);
    if Result <> nil then
      Exit; //There can't be 2 groups on one tile
  end;
end;


//Check opponents for closest Unit with given Alliance setting
function TKMHandsCollection.GetClosestGroup(const  aLoc: TKMPoint; aIndex: TKMHandID; aAlliance: TKMAllianceType; aTypes: TKMGroupTypeSet = GROUP_TYPES_VALID): TKMUnitGroup;
var
  I: Integer;
  G: TKMUnitGroup;
begin
  Result := nil;

  for I := 0 to fCount - 1 do
  if (I <> aIndex) and (fHandsList[aIndex].Alliances[I] = aAlliance) then
  begin
    G := fHandsList[I].UnitGroups.GetClosestGroup(aLoc, aTypes);
    if (G <> nil)
    and ((Result = nil) or (KMLengthSqr(G.Position, aLoc) < KMLengthSqr(Result.Position, aLoc))) then
      Result := G;
  end;
end;


function TKMHandsCollection.GetGroupsInRadius(const aLoc: TKMPoint; aSqrRadius: Single; aIndex: TKMHandID; aAlliance: TKMAllianceType; aTypes: TKMGroupTypeSet = GROUP_TYPES_VALID): TKMUnitGroupArray;
var
  I, K, idx: Integer;
  UGA: TKMUnitGroupArray;
begin
  idx := 0;
  for I := 0 to fCount - 1 do
  if (I <> aIndex) and (fHandsList[aIndex].Alliances[I] = aAlliance) then
  begin
    UGA := fHandsList[I].UnitGroups.GetGroupsInRadius(aLoc, aSqrRadius, aTypes);
    if (idx + Length(UGA) > Length(Result)) then
      SetLength(Result, idx + Length(UGA) + 12);
    for K := Low(UGA) to High(UGA) do
    begin
      Result[idx] := UGA[K];
      idx := idx + 1;
    end;
  end;

  SetLength(Result, idx);
end;


// Aproximative function to get closest units in specific radius
function TKMHandsCollection.GetGroupsMemberInRadius(const aLoc: TKMPoint; aSqrRadius: Single; aIndex: TKMHandID; aAlliance: TKMAllianceType; var aUGA: TKMUnitGroupArray; aTypes: TKMGroupTypeSet = GROUP_TYPES_VALID): TKMUnitArray;
var
  I, K, idx: Integer;
  UA: TKMUnitArray;
  UGA: TKMUnitGroupArray;
begin
  idx := 0;
  for I := 0 to fCount - 1 do
  if (I <> aIndex) and (fHandsList[aIndex].Alliances[I] = aAlliance) then
  begin
    UA := fHandsList[I].UnitGroups.GetGroupsMemberInRadius(aLoc, aSqrRadius, UGA, aTypes);
    if (idx + Length(UA) > Length(Result)) then
    begin
      SetLength(Result, idx + Length(UA) + 12);
      SetLength(aUGA, idx + Length(UA) + 12);
    end;
    for K := Low(UA) to High(UA) do
    begin
      Result[idx] := UA[K];
      aUGA[idx] := UGA[K];
      idx := idx + 1;
    end;
  end;

  SetLength(Result, idx);
end;


//Check opponents for closest Unit with given Alliance setting
function TKMHandsCollection.GetClosestUnit(const aLoc: TKMPoint; aIndex: TKMHandID; aAlliance: TKMAllianceType): TKMUnit;
var
  I: Integer;
  U: TKMUnit;
begin
  Result := nil;

  for I := 0 to fCount - 1 do
  if (I <> aIndex) and (fHandsList[aIndex].Alliances[I] = aAlliance) then
  begin
    U := fHandsList[I].Units.GetClosestUnit(aLoc);
    if (U <> nil)
    and ((Result = nil) or (KMLengthSqr(U.PositionF, KMPointF(aLoc)) < KMLengthSqr(Result.PositionF, KMPointF(aLoc)))) then
      Result := U;
  end;
end;


function TKMHandsCollection.GetCount: Byte;
begin
  if Self = nil then Exit(0);

  Result := fCount;
end;


//Check opponents for closest House with given Alliance setting
//Note: we check by house cells, not by entrance
function TKMHandsCollection.GetClosestHouse(const aLoc: TKMPoint; aIndex: TKMHandID; aAlliance: TKMAllianceType;
                                            aTypes: TKMHouseTypeSet = HOUSES_VALID; aOnlyCompleted: Boolean = True): TKMHouse;
var
  I: Integer;
  H: TKMHouse;
begin
  Result := nil;

  //Check all players
  for I := 0 to fCount - 1 do
  if (aIndex <> I) and (Hands[aIndex].Alliances[I] = aAlliance) then
  begin
    H := fHandsList[I].Houses.FindHouse(aTypes, aLoc.X, aLoc.Y, 1, aOnlyCompleted);
    if (H <> nil) and ((Result = nil) or (H.GetDistance(aLoc) < Result.GetDistance(aLoc))) then
      Result := H;
  end;
end;


function TKMHandsCollection.GetHousesInRadius(const aLoc: TKMPoint; aSqrRadius: Single; aIndex: TKMHandID; aAlliance: TKMAllianceType;
                                              aTypes: TKMHouseTypeSet = HOUSES_VALID; aOnlyCompleted: Boolean = True): TKMHouseArray;
var
  I, K, idx: Integer;
  HA: TKMHouseArray;
begin
  SetLength(Result, 12);

  idx := 0;
  for I := 0 to fCount - 1 do
  if (I <> aIndex) and (Hands[aIndex].Alliances[I] = aAlliance) then
  begin
    HA := fHandsList[I].Houses.FindHousesInRadius(aLoc, aSqrRadius, aTypes, aOnlyCompleted);
    if (idx + Length(HA) > Length(Result)) then
      SetLength(Result, idx + Length(HA) + 12);
    for K := Low(HA) to High(HA) do
    begin
      Result[idx] := HA[K];
      idx := idx + 1;
    end;
  end;
  SetLength(Result, idx);
end;


//Return distance from the tile to the closest enemy tower
function TKMHandsCollection.DistanceToEnemyTowers(const aLoc: TKMPoint; aIndex: TKMHandID): Single;
var
  I, K: Integer;
  H: TKMHouse;
begin
  Result := MaxSingle;
  for I := 0 to fCount - 1 do
  if Hands[aIndex].Alliances[I] = atEnemy then
  begin
    for K := fHandsList[I].Houses.Count - 1 downto 0 do
    begin
      H := fHandsList[I].Houses[K];
      if (H is TKMHouseTower) and H.IsComplete
      and not H.IsDestroyed and H.HasWorker
      and (H.CurrentAction.State <> hstEmpty) then
        //Don't use H.GetDistance (dist to any tile within house) as that's not how tower range works
        Result := Min(Result, KMLength(H.Position, aLoc));
    end;
  end;
end;


function TKMHandsCollection.GetHouseByUID(aUID: Integer): TKMHouse;
var
  I: Integer;
begin
  Result := nil;
  if aUID = UID_NONE then Exit;

  for I := 0 to fCount - 1 do
  begin
    Result := fHandsList[I].Houses.GetHouseByUID(aUID);
    if Result <> nil then Exit; //else keep on testing
  end;
end;


function TKMHandsCollection.GetUnitByUID(aUID: Integer): TKMUnit;
var
  I: Integer;
begin
  Result := nil;
  if aUID = UID_NONE then Exit;

  for I := 0 to fCount - 1 do
  begin
    Result := fHandsList[I].Units.GetUnitByUID(aUID);

    if Result <> nil then
      Break;
  end;

  if Result = nil then
    Result := PlayerAnimals.Units.GetUnitByUID(aUID);
end;


function TKMHandsCollection.GetGroupByUID(aUID: Integer): TKMUnitGroup;
var
  I: Integer;
begin
  Result := nil;
  if aUID = UID_NONE then Exit;

  for I := 0 to fCount - 1 do
  begin
    Result := fHandsList[I].UnitGroups.GetGroupByUID(aUID);
    if Result <> nil then Exit; //else keep on testing
  end;
end;


function TKMHandsCollection.GetObjectByUID(aUID: Integer): TKMHandEntity;
begin
  Result := GetHouseByUID(aUID);
  if Result = nil then
  begin
    Result := GetUnitByUID(aUID);
    if Result = nil then
      Result := GetGroupByUID(aUID);
  end;
end;


procedure TKMHandsCollection.PostLoadMission;
var
  I: Integer;
begin
  for I := 0 to fCount - 1 do
    fHandsList[I].PostLoadMission;

  fCheckGoals := False;
end;


{
Get next house in house list with the same type for the same owner
Result
    house: next house in unit list
    nil: if NO other house found
}
function TKMHandsCollection.GetNextHouseWSameType(aHouse: TKMHouse): TKMHouse;
begin
  Result := nil;
  if (aHouse = nil) or aHouse.IsDestroyed then Exit;

  Result := fHandsList[aHouse.Owner].GetNextHouseWSameType(aHouse.HouseType, aHouse.UID);
end;


{
Get next unit in unit list with the same type for the same owner
Result
    unit: next unit in unit list
    nil: if NO other unit found
}
function TKMHandsCollection.GetNextUnitWSameType(aUnit: TKMUnit): TKMUnit;
begin
  Result := nil;
  if (aUnit = nil) or aUnit.IsDeadOrDying then Exit;

  Result := fHandsList[aUnit.Owner].GetNextUnitWSameType(aUnit.UnitType, aUnit.UID);
end;


{
Get next unit group in group list with the same type for the same owner
Result
    unit group: next unit group in group list
    nil: if NO other group found
}
function TKMHandsCollection.GetNextGroupWSameType(aUnitGroup: TKMUnitGroup): TKMUnitGroup;
begin
  Result := nil;
  if (aUnitGroup = nil) or aUnitGroup.IsDead then Exit;

  Result := fHandsList[aUnitGroup.Owner].GetNextGroupWSameType(aUnitGroup.UnitType, aUnitGroup.UID);
end;


function TKMHandsCollection.GetGroupByMember(aWarrior: TKMUnitWarrior): TKMUnitGroup;
begin
  Result := nil;

  if (aWarrior <> nil) then
    Result := TKMUnitGroup(aWarrior.Group);
end;


function TKMHandsCollection.HitTest(X,Y: Integer): TObject;
var
  H: TKMHouse;
  U: TKMUnit;
  G: TKMUnitGroup;
begin
  //Houses have priority over units, so you can't select an occupant
  //Selection priority is as follows:
  //BuiltHouses > UnitGroups > Units > IncompleteHouses

  H := HousesHitTest(X,Y);
  if (H <> nil) and (H.BuildingState in [hbsStone, hbsDone]) then
    Result := H
  else begin
    G := GroupsHitTest(X,Y);
    if (G <> nil) then
      Result := G
    else
    begin
      U := UnitsHitTest(X,Y);
      if (U <> nil) and (not U.IsDeadOrDying) then
        Result := U
      else
        Result := H; //Incomplete house or nil
    end;
  end;
end;


//Get total unit count for statistics display
function TKMHandsCollection.UnitCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to fCount - 1 do
    Inc(Result, fHandsList[I].Units.Count);
end;


procedure TKMHandsCollection.GetUnitsInRect(const aRect: TKMRect; List: TList<TKMUnit>);
var
  I: Integer;
begin
  Assert(List.Count = 0);

  for I := 0 to fCount - 1 do
    fHandsList[I].Units.GetUnitsInRect(aRect, List);
end;


procedure TKMHandsCollection.GetGroupsInRect(const aRect: TKMRect; List: TList<TKMUnitGroup>);
var
  I: Integer;
begin
  Assert(List.Count = 0);

  for I := 0 to fCount - 1 do
    fHandsList[I].UnitGroups.GetGroupsInRect(aRect, List);
end;


procedure TKMHandsCollection.GetHousesInRect(const aRect: TKMRect; List: TList<TKMHouse>);
var
  I: Integer;
begin
  Assert(List.Count = 0);

  for I := 0 to fCount - 1 do
    fHandsList[I].Houses.GetHousesInRect(aRect, List);
end;


function TKMHandsCollection.FindPlaceForUnit(aX, aY: Integer; aUnit: TKMUnit; var aPlacePoint: TKMPoint; aRequiredWalkConnect: Byte): Boolean;
begin
  Result := FindPlaceForUnit(aX, aY, aUnit, aUnit.UnitType, aPlacePoint, aRequiredWalkConnect);
end;


function TKMHandsCollection.FindPlaceForUnit(aX, aY: Integer; aUnitType: TKMUnitType; var aPlacePoint: TKMPoint; aRequiredWalkConnect: Byte): Boolean;
begin
  Result := FindPlaceForUnit(aX, aY, nil, aUnitType, aPlacePoint, aRequiredWalkConnect);
end;


{Should return closest position where unit can be placed}
function TKMHandsCollection.FindPlaceForUnit(aX, aY: Integer; aUnit: TKMUnit; aUnitType: TKMUnitType; out aPlacePoint: TKMPoint; aRequiredWalkConnect: Byte): Boolean;

  //Unit can be placed on terrain if this tile is not occupied, or if its already occupied by this one unit
  function CanPlaceUnitOnTerrain(P: TKMPoint): Boolean;
  begin
    Result := (gTerrain.Land^[P.Y,P.X].IsUnit = nil) or (aUnit = gTerrain.Land^[P.Y,P.X].IsUnit);
  end;

var
  I: Integer;
  P: TKMPoint;
  pass: TKMTerrainPassability; //temp for required passability
begin
  Result := False; // if function fails to find valid position
  pass := gRes.Units[aUnitType].AllowedPassability;

  for I := 0 to MAX_UNITS_AROUND_HOUSE do
  begin
    P := GetPositionFromIndex(KMPoint(aX, aY), I);
    if gTerrain.TileInMapCoords(P.X, P.Y) then
    begin
      if gTerrain.CheckPassability(P, pass)
        and CanPlaceUnitOnTerrain(P)
        //If RequiredWalkConnect is invalid (0) it means we don't care
        and ((aRequiredWalkConnect = 0) or (gTerrain.GetWalkConnectID(P) = aRequiredWalkConnect)) then
      begin
        aPlacePoint := P; // Assign if all test are passed
        Exit(True);
      end;
    end;
  end;
end;


{ Check how Player1 feels towards Player2. Note: this is position dependant,
e.g. Play1 may be allied with Play2, but Play2 may be enemy to Play1}
function TKMHandsCollection.CheckAlliance(aPlay1,aPlay2: TKMHandID): TKMAllianceType;
begin
  if (aPlay1 = HAND_ANIMAL) or (aPlay2 = HAND_ANIMAL) then
    Result := atAlly //In KaM animals are always friendly
  else
    Result := fHandsList[aPlay1].Alliances[aPlay2];
end;


//Get teams from alliances information
//We consider team as a group of hands, where all hands are symmetrically allied to each other and do not allied to any other hand outside of that group
//Basically that mean standart team in MP game.
//All other possible options, f.e. smth like 1-2 are allied to each other, 3-4 - are also allied, but 5 is allied to 1-2-3-4 we do not consider as team
//other example - 1-2-3 ally/4-5-6 ally/1-7 ally - we have one standart team here: 4-5-6. 1 is allied to 7, but 2 is not, so non of them can be considered as a 'team'
function TKMHandsCollection.GetTeamsOfAllies: TKMByteSetArray;
var
  I, J, K: Byte;
  allies: TKMByteSetArray;
  handsChecked: set of Byte;
  collisionFound: Boolean;
begin
  SetLength(allies, Count);
  SetLength(Result, Count);

  //Gather aliance info into 'Allies' variable
  for I := 0 to Count - 1 do
  begin
    if not fHandsList[I].Enabled then
      Continue;

    allies[I] := [I]; // every hand is Ally to himself by default
    for J := 0 to Count - 1 do
      if (I <> J) and (CheckAlliance(I,J) = atAlly) then
        Include(allies[I], J);
  end;

  K := 0;
  handsChecked := [];
  for I := 0 to Count - 1 do
  begin
    if not fHandsList[I].Enabled then
      Continue;
    collisionFound := False;
    if (allies[I] = [I])          //hand has no allies, so we can ignore it
      or (I in handsChecked) then //hand was checked in other iteration before, ignore it
      Continue;
    //Loop throught hand allies and check if all of them has same ally group
    for J in allies[I] do
    begin
      if I = J then
        Continue;
      //Check if I-hand and all its allias has absolutely same allies
      //If not - that means all I-Hand allies and J-hand allies can not be in any of teams
      //(f.e. 1-hand allied with 2 and 3, when 2 allied with 1,3 and 4, means all 1234 can not be in any of team (or what we called by standart 'team'))
      if allies[I] <> allies[J] then
      begin
        handsChecked := handsChecked + allies[I];
        handsChecked := handsChecked + allies[J];
        collisionFound := True;
      end;
    end;
    //If no team collisions were found, means that is correct team and we have to save it.
    if not collisionFound then
    begin
      Result[K] := allies[I];
      handsChecked := handsChecked + allies[I];
      Inc(K);
    end;
  end;
  SetLength(Result, K);
end;


//Return Teams and NonTeam members as team with 1 hand only
function TKMHandsCollection.GetTeams: TKMByteSetArray;
var
  I, K: Integer;
  teams: TKMByteSetArray;
  nonTeamHands: set of Byte;
begin
  SetLength(Result, Count);
  K := 0;

  teams := gHands.GetTeamsOfAllies;
  nonTeamHands := [0..gHands.Count - 1];

  //Get non team hands
  for I := Low(teams) to High(teams) do
    nonTeamHands := nonTeamHands - teams[I];

  for I in nonTeamHands do
    if fHandsList[I].Enabled then
    begin
      Include(Result[K], I);
      Inc(K);
    end;

  for I := Low(teams) to High(teams) do
  begin
    Result[K] := teams[I];
    Inc(K);
  end;

  SetLength(Result, K);
end;


//Lazy load for teams
function TKMHandsCollection.GetTeamsLazy: TKMByteSetArray;
begin
  if fTeamsDirty then
  begin
    fTeams := GetTeams;
    SetHandsTeamColors;
  end;

  fTeamsDirty := False;
  Result := fTeams;
end;


function TKMHandsCollection.GetHandToSpectate: TKMHandID;
var
  I: Integer;
begin
  // Find the 1st enabled human hand to be spectating initially.
  // Otherwise find the 1st enabled hand
  // Otherwise return 1st hand
  Result := -1;
  for I := 0 to Count - 1 do
    if fHandsList[I].Enabled then
    begin
      if fHandsList[I].IsHuman then
        Exit(I);

      if Result = -1 then  // save only first index
        Result := I;
    end;

  if Result = -1 then // Should never happen, cause there should be at least 1 enabled hand.
    Result := 0;
end;


procedure TKMHandsCollection.SetHandsTeamColors;
var
  I, J: Integer;
  useMPTeamColors: Boolean;
  teamColorInit: Boolean;
  teamColor: Cardinal;
begin
  // For FFA games we can't use predefined team colors
  useMPTeamColors := Length(fTeams) <= MAX_TEAMS;

  teamColor := icBlack;
  for I := 0 to Length(fTeams) - 1 do
  begin
    teamColorInit := False;
    for J in fTeams[I] do
    begin
      // Use predefined team colors, if possible
      if useMPTeamColors then
        fHandsList[J].TeamColor := MP_TEAM_COLORS[I]
      else
      begin
        // Otherwise use color of the first team member as a 'team color'
        if not teamColorInit then
        begin
          teamColorInit := True;
          teamColor := fHandsList[J].FlagColor;
        end;
        fHandsList[J].TeamColor := teamColor;
      end;
    end;
  end;
end;


procedure TKMHandsCollection.AllianceChanged;
begin
  fTeamsDirty := True; //Forced re
end;


//We need to clean pointers through this method because on games exit we free all objects and in
//destructor we must release all pointers. It is common that there are cross-pointers (units in fight f.e.) that cant be cross-freed
procedure TKMHandsCollection.CleanUpUnitPointer(var aUnit: TKMUnit);
begin
  if (aUnit <> nil) and (gGame <> nil) and not gGame.IsExiting then
    aUnit.ReleasePointer;
  aUnit := nil;
end;


procedure TKMHandsCollection.CleanUpGroupPointer(var aGroup: TKMUnitGroup);
begin
  if (aGroup <> nil) and (gGame <> nil) and not gGame.IsExiting then
    aGroup.ReleasePointer;
  aGroup := nil;
end;


procedure TKMHandsCollection.CleanUpHousePointer(var aHouse: TKMHouse);
begin
  if (aHouse <> nil) and (gGame <> nil) and not gGame.IsExiting then
    aHouse.ReleasePointer;
  aHouse := nil;
end;


//MapEd procedure to remove any house under cursor
function TKMHandsCollection.RemAnyHouse(const Position: TKMPoint): Boolean;
var
  H: TKMHouse;
begin
  Assert(gGameParams.IsMapEditor, 'RemAnyHouse is not allowed outside of MapEditor');

  H := HousesHitTest(Position.X, Position.Y);
  Result := H <> nil;
  if Result then
  begin
    H.Remove;

    gGame.MapEditor.History.MakeCheckpoint(caHouses, Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_REMOVE_SMTH],
                                                            [gRes.Houses[H.HouseType].HouseName, H.Entrance.ToString]));
  end;
end;


// MapEd procedure to remove any unit under cursor
//todo -cPractical: Since it gets a Unit.Position, we could refactor it into "procedure TKMHandsCollection.RemUnit(aUnit: TKMUnit);"
function TKMHandsCollection.RemAnyUnit(const Position: TKMPoint): Boolean;
var
  I: Integer;
  UT: TKMUnitType;
begin
  Assert(gGameParams.IsMapEditor, 'RemAnyUnit is not allowed outside of MapEditor');

  UT := utNone;
  Result := False;
  for I := 0 to fCount - 1 do
    Result := fHandsList[I].RemGroup(Position); //We just remove group from list there, no actual unit was removed yet
  for I := 0 to fCount - 1 do
    Result := fHandsList[I].RemUnit(Position, UT) or Result; //Should remove Unit as well after remove group

  Result := fPlayerAnimals.RemUnit(Position, UT) or Result;
end;


//Reveal portion of terrain for said player and his allies (if they share vision)
//In singleplayer KaM sometimes you should not see your allies till some time
procedure TKMHandsCollection.RevealForTeam(aPlayer: TKMHandID; const Pos: TKMPoint; Radius, Amount: Word);
var
  I: Integer;
begin
  fHandsList[aPlayer].FogOfWar.RevealCircle(Pos,Radius,Amount);

  for I := 0 to fCount - 1 do
    if (I <> aPlayer) and (fHandsList[aPlayer].Alliances[I] = atAlly) and fHandsList[aPlayer].ShareFOW[I] then
      fHandsList[I].FogOfWar.RevealCircle(Pos, Radius, Amount);
end;


//Synchronize FOW between players (e.g. when alliances change)
procedure TKMHandsCollection.SyncFogOfWar;
var
  I, K: Integer;
begin
  for I := 0 to fCount - 1 do
  for K := 0 to fCount - 1 do
  if (I <> K) and (fHandsList[I].Alliances[K] = atAlly) and fHandsList[I].ShareFOW[K] then
    fHandsList[K].FogOfWar.SyncFOW(fHandsList[I].FogOfWar);
end;


procedure TKMHandsCollection.AddDefaultGoalsToAll(aMissionMode: TKMissionMode);
var
  I: Integer;
begin
  for I := 0 to fCount - 1 do
    fHandsList[I].AI.AddDefaultGoals(aMissionMode <> mmFighting);
end;


function TKMHandsCollection.DoCheckGoals: Boolean;
var
  I: Integer;
begin
  Result := True;

  if fCheckGoals then //Already set all to True
    Exit;

  for I := 0 to fCount - 1 do
    Result := Result and (fHandsList[I].Disabled or fHandsList[I].DoCheckGoals);

  if Result then
    fCheckGoals := True;
end;


procedure TKMHandsCollection.UpdateGoalsForHand(aHandIndex: TKMHandID; aEnable: Boolean);
var
  I: Integer;
begin
  for I := 0 to fCount - 1 do
    if I <> aHandIndex then
    begin
      fHandsList[I].AI.Goals.UpdateGoalsForHand(aHandIndex, aEnable);
      fHandsList[I].AI.RecheckGoals;
    end;
end;


// aMultiplayer - savegames should be identical when in MP mode
procedure TKMHandsCollection.Save(SaveStream: TKMemoryStream; aMultiplayer: Boolean);
var
  I: Integer;
begin
  SaveStream.PlaceMarker('Players');
  SaveStream.Write(fCount);
  SaveStream.Write(fCheckGoals);
  for I := 0 to fCount - 1 do
    fHandsList[I].Save(SaveStream);
  PlayerAnimals.Save(SaveStream);
end;


procedure TKMHandsCollection.Load(LoadStream: TKMemoryStream);
var
  I: Integer;
begin
  LoadStream.CheckMarker('Players');
  LoadStream.Read(fCount);
  LoadStream.Read(fCheckGoals);

  if fCount > MAX_HANDS then
    gLog.AddAssert('Player count in savegame exceeds MAX_PLAYERS allowed by Remake');

  SetLength(fHandsList, fCount);

  for I := 0 to fCount - 1 do
  begin
    fHandsList[I] := TKMHand.Create(0, AllianceChanged);
    fHandsList[I].Load(LoadStream);
  end;
  PlayerAnimals.Load(LoadStream);

  fTeamsDirty := True; //Always reload teams after load
end;


procedure TKMHandsCollection.SyncLoad;
var
  I: Integer;
begin
  for I := 0 to fCount - 1 do
    fHandsList[I].SyncLoad;

  PlayerAnimals.SyncLoad;

  GetTeamsLazy;
end;


procedure TKMHandsCollection.IncAnimStep;
var
  I: Integer;
begin
  for I := 0 to fCount - 1 do
    fHandsList[I].IncAnimStep;
end;


procedure TKMHandsCollection.UpdateState(aTick: Cardinal);
var
  I: Integer;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psHands);
  {$ENDIF}
  try
    for I := 0 to Count - 1 do
    if (gGame <> nil) and not gGame.IsPaused and not gGame.IsExiting then
      fHandsList[I].UpdateState(aTick)
    else
      //PlayerAI can stop the game and clear everything
      Exit;

    PlayerAnimals.UpdateState(aTick); //Animals don't have any AI yet
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psHands);
    {$ENDIF}
  end;
end;


procedure TKMHandsCollection.UpdateVisualState;
var
  I: Integer;
begin
  Assert(gGameParams.IsMapEditor);

  for I := 0 to Count - 1 do
    fHandsList[I].UpdateVisualState;
end;


procedure TKMHandsCollection.ExportGameStatsToCSV(const aPath: String; const aHeader: String = '');
var
  I, J, K: Integer;
  SL: TStringList;
  teams: TKMByteSetArray;
  tStr: UnicodeString;
  MS: TKMemoryStream;
  CRC: Cardinal;
begin
  SL := TStringList.Create;

  try
    SL.Append('Game revision: ' + UnicodeString(GAME_REVISION));
    SL.Append(aHeader);
    SL.Append('');

    SL.Append('Game time:;' + TimeToString(gGame.MissionTime));

    //Teams info
    teams := GetTeams;

    tStr := 'Teams: ';
    for J := Low(teams) to High(teams) do
    begin
      if J <> Low(teams) then
        tStr := tStr + ' vs ';

      tStr := tStr + '[ ';
      K := 0;
      for I in teams[J] do
      begin
        if K > 0 then
          tStr := tStr + ' + ';

        tStr := tStr + fHandsList[I].CalcOwnerName;

        Inc(K);
      end;
      tStr := tStr + ' ]';
    end;

    SL.Append(tStr);
    SL.Append('');

    //Game stats
    for I := 0 to fCount - 1 do
      if fHandsList[I].Enabled then
      begin
        SL.Append(Format('Player ''%s'' at Location %d. Player game result: %s',
                         [fHandsList[I].GetOwnerName, I, fHandsList[I].AI.GetWonOrLostString]));
        fHandsList[I].Stats.ToCSV(SL);
        SL.Append('');
      end;

    //Stats fields legend
    SL.Append('');
    SL.Append('House fields legend:');
    SL.Append('Planned;Houseplans were placed');
    SL.Append('PlanRemoved;Houseplans were removed');
    SL.Append('Started;Construction started');
    SL.Append('Ended;Construction ended (either done or destroyed/cancelled)');
    SL.Append('Initial;Created by script on mission start');
    SL.Append('Built;Constructed by player');
    SL.Append('SelfDestruct;Deconstructed by player');
    SL.Append('Lost;Lost from attacks and self-demolished');
    SL.Append('ClosedATM;Closed for worker at the current moment');
    SL.Append('Destroyed;Destroyed other players houses');
    SL.Append('');
    SL.Append('Unit fields legend:');
    SL.Append('Initial;Provided at mission start');
    SL.Append('Training;Currently in training queue (at this current moment)');
    SL.Append('Trained;Trained by player');
    SL.Append('Lost;Died of hunger or killed');
    SL.Append('Killed;Killed (including friendly)');

    MS := TKMemoryStreamBinary.Create;
    try
      MS.WriteHugeString(AnsiString(SL.Text));
      CRC := Adler32CRC(MS);
    finally
      MS.Free;
    end;

    //Put CRC at first row
    SL.Insert(0, IntToStr(CRC));

    ForceDirectories(ExtractFilePath(aPath));

    SL.SaveToFile(aPath);
  finally
    SL.Free;
  end;
end;


procedure TKMHandsCollection.Paint(const aRect: TKMRect; aTickLag: Single);
var
  I: Integer;
begin
  for I := 0 to fCount - 1 do
    fHandsList[I].Paint(aRect, aTickLag);

  PlayerAnimals.Paint(aRect, aTickLag);
end;


function TKMHandsCollection.ObjToString: String;
var
  I: Integer;
begin
  Result := '|Hands: ';
  for I := 0 to fCount - 1 do
    Result := Format('%s|%d:' + #9 + '%s', [Result, I, fHandsList[I].ObjToString(#9)]);
end;


end.
