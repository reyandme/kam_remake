unit KM_AIDefensePos;
{$I KaM_Remake.inc}
interface
uses
  Math,
  KM_Entity, KM_UnitGroup,
  KM_CommonClasses, KM_Defaults, KM_Points,
  KM_AITypes;


type
  TAIDefencePosition = class(TKMEntity)
  private
    fDefenceType: TKMAIDefencePosType; //Whether this is a front or back line defence position. See comments on TAIDefencePosType above
    fGroupType: TKMGroupType; //Type of group to defend this position (e.g. melee)
    fPosition: TKMPointDir; //Position and direction the group defending will stand
    fRadius: Integer; //If fighting (or houses being attacked) occurs within this radius from this defence position, this group will get involved

    fCurrentGroup: TKMUnitGroup; //Commander of group currently occupying position
    procedure SetCurrentGroup(aGroup: TKMUnitGroup);
    procedure SetGroupType(const Value: TKMGroupType);
    procedure SetDefenceType(const Value: TKMAIDefencePosType);
    procedure SetPosition(const Value: TKMPointDir);
  public
    constructor Create(aUID: Integer; const aPos: TKMPointDir; aGroupType: TKMGroupType; aRadius: Integer; aDefenceType: TKMAIDefencePosType);
    constructor Load(LoadStream: TKMemoryStream); override;
    destructor Destroy; override;

    property DefenceType: TKMAIDefencePosType read fDefenceType write SetDefenceType;
    property GroupType: TKMGroupType read fGroupType write SetGroupType; //Type of group to defend this position (e.g. melee)
    property Position: TKMPointDir read fPosition write SetPosition; //Position and direction the group defending will stand
    property Radius: Integer read fRadius write fRadius; //If fighting (or houses being attacked) occurs within this radius from this defence position, this group will get involved

    property CurrentGroup: TKMUnitGroup read fCurrentGroup write SetCurrentGroup;
    function CanAccept(aGroup: TKMUnitGroup; aMaxUnits: Integer): Boolean;
    procedure Save(SaveStream: TKMemoryStream); override;
    procedure SyncLoad;
    procedure UpdateState;
  end;


  TAIDefencePositions = class
  private
    fOwner: TKMHandID;
    fPositions: TKMList;
    function GetPosition(aIndex: Integer): TAIDefencePosition; inline;
    function GetCount: Integer; inline;
    function CreateDefPosition(const aPos: TKMPointDir; aGroupType: TKMGroupType; aRadius: Integer; aDefenceType: TKMAIDefencePosType): TAIDefencePosition;
  public
    //Defines how defending troops will be formatted. 0 means leave unchanged.
    TroopFormations: array [GROUP_TYPE_MIN..GROUP_TYPE_MAX] of TKMFormation;

    constructor Create(aPlayer: TKMHandID);
    destructor Destroy; override;

    function Add(const aPos: TKMPointDir; aGroupType: TKMGroupType; aRadius: Integer; aDefenceType: TKMAIDefencePosType): Integer;
    function Insert(aIndex: Integer; const aPos: TKMPointDir; aGroupType: TKMGroupType; aRadius: Integer; aDefenceType: TKMAIDefencePosType): Integer;
    procedure Clear;
    property Count: Integer read GetCount;
    procedure Delete(aIndex: Integer);
    property Positions[aIndex: Integer]: TAIDefencePosition read GetPosition; default;
    function GetBacklineCount: Integer;
    function AverageUnitsPerGroup: Integer;

    function FindPlaceForGroup(aGroup: TKMUnitGroup; aTakeClosest: Boolean): Boolean;

    function FindPositionAtLoc(aPos: TKMPoint ): TAIDefencePosition;

    procedure RestockPositionWith(aDefenceGroup, aGroup: TKMUnitGroup);
    function FindPositionOf(aGroup: TKMUnitGroup): TAIDefencePosition;
    procedure GetArmyDemand(out aFootmen: Integer; out aPikemen: Integer; out aHorsemen: Integer; out aArchers: Integer);

    procedure MoveUp(aIndex: Integer);
    procedure MoveDown(aIndex: Integer);

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad;
    procedure UpdateState;
    procedure Paint;
  end;


implementation
uses
  SysUtils, TypInfo,
  KM_Game, KM_GameUIDTracker, KM_GameParams, KM_HandsCollection, KM_RenderAux, KM_RenderPool, KM_Hand,
  KM_UnitGroupTypes, KM_InterfaceGame;


{ TAIDefencePosition }
constructor TAIDefencePosition.Create(aUID: Integer; const aPos: TKMPointDir; aGroupType: TKMGroupType; aRadius: Integer; aDefenceType: TKMAIDefencePosType);
begin
  inherited Create(aUID);

  Assert(aGroupType in GROUP_TYPES_VALID, 'Invalid group type: ' + GetEnumName(TypeInfo(TKMGroupType), Integer(aGroupType)));
  fPosition := aPos;
  fGroupType := aGroupType;
  fRadius := aRadius;
  fDefenceType := aDefenceType;
  CurrentGroup := nil; //Unoccupied
end;


destructor TAIDefencePosition.Destroy;
begin
  CurrentGroup := nil; //Ensure pointer is removed
  inherited;
end;


procedure TAIDefencePosition.SetCurrentGroup(aGroup: TKMUnitGroup);
begin
  //Release previous group
  gHands.CleanUpGroupPointer(fCurrentGroup);

  //Take new one
  if aGroup <> nil then
    fCurrentGroup := aGroup.GetPointer;
end;


procedure TAIDefencePosition.SetDefenceType(const Value: TKMAIDefencePosType);
begin
  Assert(gGameParams.IsMapEditor);
  fDefenceType := Value;
end;


procedure TAIDefencePosition.SetGroupType(const Value: TKMGroupType);
begin
  Assert(gGameParams.IsMapEditor);
  Assert(Value in GROUP_TYPES_VALID, 'Invalid group type: ' + GetEnumName(TypeInfo(TKMGroupType), Integer(Value)));
  fGroupType := Value;
end;


procedure TAIDefencePosition.SetPosition(const Value: TKMPointDir);
begin
  Assert(gGameParams.IsMapEditor);
  fPosition := Value;
end;


procedure TAIDefencePosition.Save(SaveStream: TKMemoryStream);
begin
  inherited;

  SaveStream.PlaceMarker('ClsDefencePos');
  SaveStream.Write(fPosition);
  SaveStream.Write(fGroupType, SizeOf(fGroupType));
  SaveStream.Write(fRadius);
  SaveStream.Write(fDefenceType, SizeOf(fDefenceType));
  SaveStream.Write(fCurrentGroup.UID); //Store ID
end;


constructor TAIDefencePosition.Load(LoadStream: TKMemoryStream);
begin
  inherited;

  LoadStream.CheckMarker('ClsDefencePos');
  LoadStream.Read(fPosition);
  LoadStream.Read(fGroupType, SizeOf(fGroupType));
  LoadStream.Read(fRadius);
  LoadStream.Read(fDefenceType, SizeOf(fDefenceType));
  LoadStream.Read(fCurrentGroup, 4); //subst on syncload
end;


procedure TAIDefencePosition.SyncLoad;
begin
  fCurrentGroup := gHands.GetGroupByUID(Integer(fCurrentGroup));
end;


function TAIDefencePosition.CanAccept(aGroup: TKMUnitGroup; aMaxUnits: Integer): Boolean;
begin
  Result := (fGroupType = UNIT_TO_GROUP_TYPE[aGroup.UnitType]);

  if not Result then Exit;

  // Empty position accepts anything (e.g. happens at mission start)
  // As checked in KaM - it did not link big groups to filled Positions
  Result := (CurrentGroup = nil) or
            (aGroup.Count = 1);

  Result := Result and ((CurrentGroup = nil) or (CurrentGroup.Count < aMaxUnits));
end;


procedure TAIDefencePosition.UpdateState;
begin
  //If the group is Dead or too far away we should disassociate
  //them from the defence position so new warriors can take up the defence if needs be
  if (CurrentGroup = nil)
  or CurrentGroup.IsDead
  or ((CurrentGroup.InFight or (CurrentGroup.Order in [goAttackHouse, goAttackUnit]))
      and (Position.Loc.GetLengthDiag(CurrentGroup.Position) > Radius)) then
    CurrentGroup := nil;

  //Tell group to walk to its position
  //It's easier to repeat the order than check that all members are in place
  if (CurrentGroup <> nil)
  and CurrentGroup.IsIdleToAI([wtokFlagPoint, wtokHaltOrder])
  and CurrentGroup.CanWalkTo(Position.Loc, 0) then
    CurrentGroup.OrderWalk(Position.Loc, True, wtokAIGotoDefencePos, Position.Dir);
end;


{ TAIDefencePositions }
constructor TAIDefencePositions.Create(aPlayer: TKMHandID);
var
  GT: TKMGroupType;
begin
  inherited Create;

  fOwner := aPlayer;
  fPositions := TKMList.Create;

  for GT := GROUP_TYPE_MIN to GROUP_TYPE_MAX do
  begin
    TroopFormations[GT].NumUnits := 9; //These are the defaults in KaM
    TroopFormations[GT].UnitsPerRow := 3;
  end;
end;


destructor TAIDefencePositions.Destroy;
begin
  fPositions.Free;

  inherited;
end;


function TAIDefencePositions.GetCount: Integer;
begin
  Result := fPositions.Count;
end;


//Find DefencePosition at location
function TAIDefencePositions.FindPositionAtLoc(aPos: TKMPoint): TAIDefencePosition;
var
  I: Integer;
begin
  Result := nil;

  for I := 0 to Count - 1 do
    if Positions[I].Position.Loc = aPos then
      Exit(Positions[I]);
end;


function TAIDefencePositions.GetPosition(aIndex: Integer): TAIDefencePosition;
begin
  if not InRange(aIndex, 0, Count - 1) then Exit(nil);

  Result := fPositions[aIndex];
end;


function TAIDefencePositions.CreateDefPosition(const aPos: TKMPointDir; aGroupType: TKMGroupType; aRadius: Integer; aDefenceType: TKMAIDefencePosType): TAIDefencePosition;
begin
  Assert(aGroupType in GROUP_TYPES_VALID, 'Invalid group type: ' + GetEnumName(TypeInfo(TKMGroupType), Integer(aGroupType)));

  Result := TAIDefencePosition.Create(gUIDTracker.GetNewUID, aPos, aGroupType, aRadius, aDefenceType);
end;


function TAIDefencePositions.Add(const aPos: TKMPointDir; aGroupType: TKMGroupType; aRadius: Integer; aDefenceType: TKMAIDefencePosType): Integer;
var
  defPos: TAIDefencePosition;
begin
  defPos := CreateDefPosition(aPos, aGroupType, aRadius, aDefenceType);
  fPositions.Add(defPos);
  Result := defPos.UID;
end;


function TAIDefencePositions.Insert(aIndex: Integer; const aPos: TKMPointDir; aGroupType: TKMGroupType; aRadius: Integer; aDefenceType: TKMAIDefencePosType): Integer;
var
  defPos: TAIDefencePosition;
begin
  Assert(InRange(aIndex, 0, Count), 'Can''t insert defence position at position ' + IntToStr(aIndex));
  defPos := CreateDefPosition(aPos, aGroupType, aRadius, aDefenceType);

  fPositions.Insert(aIndex, defPos);

  Result := defPos.UID;
end;


procedure TAIDefencePositions.Clear;
begin
  fPositions.Clear;
end;


procedure TAIDefencePositions.Delete(aIndex: Integer);
begin
  //Note: Order of positions is important (AI fills them with troops from 0 to N)
  fPositions.Delete(aIndex);
end;


function TAIDefencePositions.GetBacklineCount: Integer;
var I: Integer;
begin
  Result := 0;
  for I := 0 to Count - 1 do
    if Positions[I].fDefenceType = dtBackLine then
      Inc(Result);
end;


function TAIDefencePositions.AverageUnitsPerGroup: Integer;
var
  GT: TKMGroupType;
  TypeCount: Integer;
begin
  Result := 0;
  TypeCount := 0;
  for GT := GROUP_TYPE_MIN to GROUP_TYPE_MAX do
  begin
    Result := Result + TroopFormations[GT].NumUnits;
    Inc(TypeCount);
  end;
  Result := Result div TypeCount;
end;


function TAIDefencePositions.FindPlaceForGroup(aGroup: TKMUnitGroup; aTakeClosest: Boolean): Boolean;
var
  I, Matched: Integer;
  Distance, Best: Single;
begin
  Result := False;
  Matched := -1;
  Best := MaxSingle;

  //Try to link to existing group
  for I := 0 to Count - 1 do
  if Positions[I].CanAccept(aGroup, TroopFormations[aGroup.GroupType].NumUnits) then
  begin
    //Take closest position that is empty or requries restocking
    Distance := KMLengthSqr(aGroup.Position, Positions[I].Position.Loc);
    if Distance < Best then
    begin
      Matched := I;
      Best := Distance;
      //KaM fills defence positions by their order of creation
      //Take first one we find - that's what KaM does
      if not aTakeClosest then Break;
    end;
  end;

  if Matched <> -1 then
  begin
    Result := True;
    if Positions[Matched].CurrentGroup = nil then
    begin
      //New position
      Positions[Matched].CurrentGroup := aGroup;
      if aGroup.UnitsPerRow < TroopFormations[aGroup.GroupType].UnitsPerRow then
        aGroup.UnitsPerRow := TroopFormations[aGroup.GroupType].UnitsPerRow;
      aGroup.OrderWalk(Positions[Matched].Position.Loc, True, wtokAIGotoDefencePos);
    end
    else
      //Append to existing position
      RestockPositionWith(Positions[Matched].CurrentGroup, aGroup);
  end;
end;


procedure TAIDefencePositions.RestockPositionWith(aDefenceGroup, aGroup: TKMUnitGroup);
var
  Needed: integer;
begin
  Needed := TroopFormations[aDefenceGroup.GroupType].NumUnits - aDefenceGroup.Count;
  if Needed <= 0 then exit;
  if aGroup.Count <= Needed then
    aGroup.OrderLinkTo(aDefenceGroup, True) //Link entire group
  else
    aGroup.OrderSplitLinkTo(aDefenceGroup, Needed, True); //Link only as many units as are needed

  if aDefenceGroup.UnitsPerRow < TroopFormations[aDefenceGroup.GroupType].UnitsPerRow then
    aDefenceGroup.UnitsPerRow := TroopFormations[aDefenceGroup.GroupType].UnitsPerRow;
end;


//Find DefencePosition to which this Commander belongs
//(Result could be nil if CommanderCount > PositionsCount
function TAIDefencePositions.FindPositionOf(aGroup: TKMUnitGroup): TAIDefencePosition;
var
  I: Integer;
begin
  Result := nil;

  for I := 0 to Count - 1 do
  if Positions[I].CurrentGroup = aGroup then
  begin
    Result := Positions[I];
    Break;
  end;
end;


procedure TAIDefencePositions.GetArmyDemand(out aFootmen: Integer; out aPikemen: Integer; out aHorsemen: Integer; out aArchers: Integer);
var I, Required: Integer;
begin
  aFootmen := 0;
  aPikemen := 0;
  aHorsemen := 0;
  aArchers := 0;
  for I := 0 to Count - 1 do
  begin
    Required := TroopFormations[Positions[I].GroupType].NumUnits;
    case Positions[I].GroupType of
      gtMelee:     Inc(aFootmen, Required);
      gtAntiHorse: Inc(aPikemen, Required);
      gtRanged:    Inc(aArchers, Required);
      gtMounted:   Inc(aHorsemen, Required);
    end;
  end;
end;


procedure TAIDefencePositions.MoveUp(aIndex: Integer);
begin
  if aIndex < Count-1 then
    fPositions.Exchange(aIndex, aIndex+1);
end;


procedure TAIDefencePositions.MoveDown(aIndex: Integer);
begin
  if aIndex > 0 then
    fPositions.Exchange(aIndex, aIndex-1);
end;


procedure TAIDefencePositions.Save(SaveStream: TKMemoryStream);
var I: Integer;
begin
  SaveStream.PlaceMarker('ClsDefencePositions');
  SaveStream.Write(fOwner);
  SaveStream.Write(TroopFormations, SizeOf(TroopFormations));
  SaveStream.Write(Count);

  for I := 0 to Count - 1 do
    Positions[I].Save(SaveStream);
end;


procedure TAIDefencePositions.Load(LoadStream: TKMemoryStream);
var I, NewCount: Integer;
begin
  LoadStream.CheckMarker('ClsDefencePositions');
  LoadStream.Read(fOwner);
  LoadStream.Read(TroopFormations, SizeOf(TroopFormations));
  LoadStream.Read(NewCount);

  for I := 0 to NewCount - 1 do
    fPositions.Add(TAIDefencePosition.Load(LoadStream));
end;


procedure TAIDefencePositions.SyncLoad;
var I: Integer;
begin
  for I := 0 to Count - 1 do
    Positions[I].SyncLoad;
end;


procedure TAIDefencePositions.UpdateState;
var I,K: Integer;
begin
  //Make sure no defence position Group is dead
  for I := 0 to Count - 1 do
    Positions[I].UpdateState;

  //In KaM the order of defence positions is the priority: The first defined is higher priority
  for I := 0 to Count - 1 do
  if (Positions[I].CurrentGroup = nil) then
    for K := I + 1 to Count - 1 do
    if Positions[I].GroupType = Positions[K].GroupType then
    begin
      Positions[I].CurrentGroup := Positions[K].CurrentGroup; //Take new position
      Positions[K].CurrentGroup := nil; //Leave current position
      Break;
    end;
end;


procedure TAIDefencePositions.Paint;
var
  I: Integer;
  str: string;
begin
  for I := 0 to Count - 1 do
  begin
    gRenderAux.Quad(Positions[I].Position.Loc.X, Positions[I].fPosition.Loc.Y, DEFENCE_LINE_TYPE_COL[Positions[I].fDefenceType]);

    gRenderPool.RenderSpriteOnTile(Positions[I].Position.Loc, 510 + Byte(Positions[I].Position.Dir), gHands[fOwner].FlagColor);
    gRenderAux.CircleOnTerrain(Positions[I].Position.Loc.X-0.5, Positions[I].Position.Loc.Y-0.5, Positions[I].Radius,
                               gHands[fOwner].FlagColor AND $08FFFFFF,
                               gHands[fOwner].FlagColor);
    //group type and position number will be painted by InterfaceMapEditor

    if not gGameParams.IsMapEditor then
    begin
      str := 'nil';
      if Positions[I].CurrentGroup <> nil then
        str := IntToStr(Positions[I].CurrentGroup.UID);

      gRenderAux.Text(Positions[I].fPosition.Loc.X, Positions[I].fPosition.Loc.Y, str, icRed);
    end;
  end;
end;


end.
