unit KM_HandSpectator;
{$I KaM_Remake.inc}
interface
uses
  KM_Hand, KM_FogOfWar,
  KM_CommonClasses, KM_Defaults,
  KM_HandEntity;


type
  //Wrap to let choose FOW player sees (and let 1 player control several towns
  //or several players to control 1 town in future)
  TKMSpectator = class
  private
    fHandIndex: TKMHandID;
    fHighlight: TKMHighlightEntity; //Unit/House/Group that is shown highlighted to draw players attention
    fHighlightEnd: Cardinal; //Highlight has a short time to live
    fHighlightDebug: TKMHighlightEntity; //Unit/House/Group that is shown highlighted to draw players attention
    fHighlightDebug2: TKMHighlightEntity;
    fHighlightDebug3: TKMHighlightEntity;
    fHighlightRoute: TKMHighlightEntity;
    fSelected: TKMHandEntity;
    fLastSelected: TKMHandEntity;
    fIsSelectedMyObj: Boolean; // We can select ally's house/unit
    fLastSpecSelectedObjUID: array [0..MAX_HANDS-1] of Integer; //UIDs of last selected objects for each hand while spectating/watching replay
    fFOWIndex: TKMHandID; //Unit/House/Group selected by player and shown in UI
    fFogOfWarOpen: TKMFogOfWarOpen; //Stub for MapEd
    fFogOfWar: TKMFogOfWarCommon; //Pointer to current FOW view, updated by UpdateFogOfWarIndex
    procedure SetHighlight(Value: TKMHandEntity);
    procedure SetHighlightEntity(Value: TKMHighlightEntity);
    procedure SetSelected(Value: TKMHandEntity);
    function GetSelected: TKMHandEntity;
    procedure SetHandIndex(const Value: TKMHandID);
    procedure SetFOWIndex(const Value: TKMHandID);
    procedure UpdateFogOfWarIndex;
    function GetLastSpecSelectedEntity: TKMHandEntity;
    procedure UpdateNewSelected(var aNewSelected: TKMHandEntity); overload;
    function GetSelectedHandID: TKMHandID;
    function GetHighlight: TKMHandEntity;
  public
    constructor Create(aHandIndex: TKMHandID);
    destructor Destroy; override;
    property Highlight: TKMHandEntity read GetHighlight write SetHighlight;
    property HighlightEntity: TKMHighlightEntity read fHighlight write SetHighlightEntity;
    property HighlightDebug: TKMHighlightEntity read fHighlightDebug write fHighlightDebug;
    property HighlightDebug2: TKMHighlightEntity read fHighlightDebug2 write fHighlightDebug2;
    property HighlightDebug3: TKMHighlightEntity read fHighlightDebug3 write fHighlightDebug3;
    property HighlightRoute: TKMHighlightEntity read fHighlightRoute write fHighlightRoute;
    property Selected: TKMHandEntity read GetSelected write SetSelected;
    property LastSelected: TKMHandEntity read fLastSelected;
    procedure NilLastSelected;
    property IsSelectedMyObj: Boolean read fIsSelectedMyObj write fIsSelectedMyObj;
    function Hand: TKMHand;
    property HandID: TKMHandID read fHandIndex write SetHandIndex;
    property SelectedHandID: TKMHandID read GetSelectedHandID;
    property FOWIndex: TKMHandID read fFOWIndex write SetFOWIndex;
    property FogOfWar: TKMFogOfWarCommon read fFogOfWar;
    property LastSpecSelectedEntity: TKMHandEntity read GetLastSpecSelectedEntity;
    function HitTestCursor(aIncludeAnimals: Boolean = False): TKMHandEntity;
    function HitTestCursorWGroup(aIncludeAnimals: Boolean = False): TKMHandEntity;
    procedure UpdateNewSelected; overload;
    procedure UpdateSelect(aCheckUnderCursor: Boolean = True; aAllowAnimals: Boolean = False);
    procedure Load(LoadStream: TKMemoryStream);
    procedure Save(SaveStream: TKMemoryStream);
    procedure UpdateState(aTick: Cardinal);

    procedure ResetHighlightDebug;
  end;


implementation
uses
  KM_Entity, KM_HandEntityHelper,
  KM_GameParams, KM_Cursor,
  KM_HandsCollection, KM_HandTypes,
  KM_Units, KM_UnitGroup, KM_UnitWarrior, KM_Houses,
  KM_CommonUtils,
  KM_GameTypes,
  KM_Main;


{ TKMSpectator }
constructor TKMSpectator.Create(aHandIndex: TKMHandID);
var
  I: Integer;
begin
  inherited Create;

  fHandIndex := aHandIndex;

  fHighlight.Color        := DEFAULT_HIGHLIGHT_COL;
  fHighlightDebug.Color   := DEFAULT_HIGHLIGHT_COL;
  fHighlightDebug2.Color  := DEFAULT_HIGHLIGHT_COL;
  fHighlightRoute.Color   := DEFAULT_HIGHLIGHT_COL;

  //Stub that always returns REVEALED
  fFogOfWarOpen := TKMFogOfWarOpen.Create;
  UpdateFogOfWarIndex;

  for I := Low(fLastSpecSelectedObjUID) to High(fLastSpecSelectedObjUID) do
    fLastSpecSelectedObjUID[I] := UID_NONE;
end;


destructor TKMSpectator.Destroy;
begin
  Highlight := nil;
  Selected := nil;
  fFogOfWarOpen.Free;
  inherited;
end;


procedure TKMSpectator.UpdateFogOfWarIndex;
begin
  //fGame = nil in Tests
  if (gGameParams <> nil) and (gGameParams.Mode in [gmMultiSpectate, gmMapEd, gmReplaySingle, gmReplayMulti]) then
    if FOWIndex = -1 then
      fFogOfWar := fFogOfWarOpen
    else
      fFogOfWar := gHands[FOWIndex].FogOfWar
  else
    fFogOfWar := gHands[HandID].FogOfWar;
end;



function TKMSpectator.GetHighlight: TKMHandEntity;
begin
  Result := fHighlight.Entity;
end;


//Return last seleted object for current chosen hand
function TKMSpectator.GetLastSpecSelectedEntity: TKMHandEntity;
var
  entity: TKMHandEntity;
  UID: Integer;
begin
  Result := nil;
  UID := fLastSpecSelectedObjUID[fHandIndex];
  if UID <> UID_NONE then
  begin
    entity := gHands.GetObjectByUID(UID);
    if (entity <> nil) and entity.IsSelectable then
      Result := entity
    else
      fLastSpecSelectedObjUID[fHandIndex] := UID_NONE;  // Last selected object is not valid anymore, so reset UID
  end;
end;


function TKMSpectator.GetSelected: TKMHandEntity;
begin
  if Self = nil then Exit(nil);

  Result := fSelected;
end;


function TKMSpectator.GetSelectedHandID: TKMHandID;
begin
  Result := fHandIndex;
  if Self = nil then Exit;

  if fSelected <> nil then
    Result := fSelected.Owner;
end;


procedure TKMSpectator.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.CheckMarker('Spectator');
  LoadStream.Read(fHandIndex);
  UpdateFogOfWarIndex;
end;


procedure TKMSpectator.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.PlaceMarker('Spectator');
  SaveStream.Write(fHandIndex);
end;


function TKMSpectator.Hand: TKMHand;
begin
  if Self = nil then Exit(nil);

  Result := gHands[fHandIndex];
end;


//Test if there's object below that player can interact with
//Units and Houses, not Groups
function TKMSpectator.HitTestCursor(aIncludeAnimals: Boolean = False): TKMHandEntity;
begin
  Result := gHands.GetUnitByUID(gCursor.ObjectUID);
  if ((Result is TKMUnit) and TKMUnit(Result).IsDeadOrDying)
  or ((Result is TKMUnitAnimal) and not aIncludeAnimals) then
    Result := nil;

  //If there's no unit try pick a house on the Cell below
  if Result = nil then
  begin
    Result := gHands.HousesHitTest(gCursor.Cell.X, gCursor.Cell.Y);
    if (Result is TKMHouse) and TKMHouse(Result).IsDestroyed then
      Result := nil;
  end;
end;


//Test if there's object below that player can interact with
//Units and Houses and Groups
function TKMSpectator.HitTestCursorWGroup(aIncludeAnimals: Boolean = False): TKMHandEntity;
var
  G: TKMUnitGroup;
begin
  Result := HitTestCursor(aIncludeAnimals);

  if Result is TKMUnitWarrior then
  begin
    if gGameParams.Mode in [gmMultiSpectate, gmMapEd, gmReplaySingle, gmReplayMulti]  then
      G := gHands.GetGroupByMember(TKMUnitWarrior(Result))
    else
      G := gHands[fHandIndex].UnitGroups.GetGroupByMember(TKMUnitWarrior(Result));

    //Warrior might not be assigned to a group while walking out of the Barracks
    if G <> nil then
      Result := G
    else
      Result := nil; //Can't select warriors until they have been assigned a group
  end;
end;


procedure TKMSpectator.UpdateNewSelected;
var
  tmpSelected: TKMHandEntity;
begin
  //We do not want to change Selected object actually, just update fIsSelectedMyObj field is good enough
  tmpSelected := Selected;
  UpdateNewSelected(tmpSelected);
end;


procedure TKMSpectator.UpdateNewSelected(var aNewSelected: TKMHandEntity);
begin
  if gGameParams.Mode in [gmMultiSpectate, gmMapEd, gmReplaySingle, gmReplayMulti] then
    Exit;

  if aNewSelected.Owner <> -1 then
  begin
    if aNewSelected.Owner <> fHandIndex then  // check if we selected our unit/ally's or enemy's
    begin
      if ALLOW_SELECT_ALL
        or (aNewSelected.AllowAllyToSelect and (Hand.Alliances[aNewSelected.Owner] = atAlly)) then
        fIsSelectedMyObj := False
      else
        aNewSelected := nil;
    end else
      fIsSelectedMyObj := True;
  end;
end;


//Select anything player CAN select below cursor
procedure TKMSpectator.UpdateSelect(aCheckUnderCursor: Boolean = True; aAllowAnimals: Boolean = False);
var
  newSelected: TKMHandEntity;
  UID: Integer;
begin
  newSelected := nil;

  if aCheckUnderCursor then
  begin
    newSelected := gHands.GetUnitByUID(gCursor.ObjectUID);

    //In-game player can select only own and ally Units
    UpdateNewSelected(newSelected);

    //Don't allow the player to select dead units
    if ((newSelected is TKMUnit) and TKMUnit(newSelected).IsDeadOrDying)
      or (not aAllowAnimals and (newSelected is TKMUnitAnimal)) then //...or animals
      newSelected := nil;

    //If Id belongs to some Warrior, try to select his group instead
    if newSelected is TKMUnitWarrior then
    begin
      newSelected := gHands.GetGroupByMember(TKMUnitWarrior(newSelected));
      UpdateNewSelected(newSelected);
    end;

    //Update selected groups selected unit
    if newSelected is TKMUnitGroup then
      TKMUnitGroup(newSelected).SelectedUnit := TKMUnitGroup(newSelected).MemberByUID(gCursor.ObjectUID);

    //If there's no unit try pick a house on the Cell below
    if newSelected = nil then
    begin
      newSelected := gHands.HousesHitTest(gCursor.Cell.X, gCursor.Cell.Y);

      //In-game player can select only own and ally Units
      if (newSelected is TKMHouse) then
        UpdateNewSelected(newSelected);

      //Don't allow the player to select destroyed houses
      if (newSelected is TKMHouse) and TKMHouse(newSelected).IsDestroyed then
        newSelected := nil;
    end;

    //Don't clear the old selection unless we found something new
    if newSelected <> nil then
      Selected := newSelected;
  end
  else
  begin
    newSelected := Selected; //To avoid nil-ing of fSelected
    //In-game player can select only own and ally Units
    UpdateNewSelected(newSelected); //Updates fIsSelectedMyObj
  end;

  // In a replay we want in-game statistics (and other things) to be shown for the owner of the last select object
  if gGameParams.IsReplayOrSpectate then
  begin
    UID := UID_NONE;
    if Selected is TKMHouse then
    begin
      HandID := TKMHouse(Selected).Owner;
      UID := TKMHouse(Selected).UID;
    end;
    if Selected is TKMUnit then
    begin
      HandID := TKMUnit(Selected).Owner;
      UID := TKMUnit(Selected).UID;
    end;
    if Selected is TKMUnitGroup then
    begin
      HandID := TKMUnitGroup(Selected).Owner;
      UID := TKMUnitGroup(Selected).UID;
    end;
    if (Selected <> nil) and (UID <> UID_NONE) then
      fLastSpecSelectedObjUID[fHandIndex] := UID;
  end;

  // Update F11 Debug panel  UIDs
  if gMain <> nil then
    gMain.FormMain.SetEntitySelected(Selected.UID, Selected.AsGroup.SelectedUnit.UID);
end;


procedure TKMSpectator.SetFOWIndex(const Value: TKMHandID);
begin
  fFOWIndex := Value;
  UpdateFogOfWarIndex;
end;


procedure TKMSpectator.SetHighlight(Value: TKMHandEntity);
begin
  //We don't increase PointersCount of object because of savegames identicality over MP
  //Objects report on their destruction and set it to nil
  fHighlight.Entity := Value;
  fHighlight.Color := DEFAULT_HIGHLIGHT_COL;
  fHighlightEnd := TimeGet + 3000;
end;


procedure TKMSpectator.SetHighlightEntity(Value: TKMHighlightEntity);
begin
  fHighlight := Value;
  SetHighlight(Value.Entity);
end;


procedure TKMSpectator.SetHandIndex(const Value: TKMHandID);
begin
  Assert(MULTIPLAYER_CHEATS or (gGameParams.Mode <> gmMulti));
  fHandIndex := Value;

  if not (gGameParams.Mode in [gmMultiSpectate, gmMapEd, gmReplaySingle, gmReplayMulti]) then
    Selected := nil;

  UpdateFogOfWarIndex;
end;


procedure TKMSpectator.SetSelected(Value: TKMHandEntity);
begin
  if Self  = nil then Exit;

  fLastSelected := fSelected;

  //We don't increase PointersCount of object because of savegames identicality over MP
  //Objects report on their destruction and set it to nil
  fSelected := Value;
end;


procedure TKMSpectator.NilLastSelected;
begin
  fLastSelected := nil;
end;


procedure TKMSpectator.ResetHighlightDebug;
begin
  if Self = nil then Exit;
  
  fHighlightDebug.Reset;
  fHighlightDebug2.Reset;
  fHighlightDebug3.Reset;
  fHighlightRoute.Reset;
end;


procedure TKMSpectator.UpdateState;
begin
  //Hide the highlight
  if TimeGet > fHighlightEnd then
    fHighlight.Reset;
  //Units should be deselected when they go inside a house
  if Selected is TKMUnit then
    if not TKMUnit(Selected).Visible then
      Selected := nil;
end;


end.

