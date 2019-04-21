unit KM_Hand;
{$I KaM_Remake.inc}
interface
uses
  KM_AI, KM_AIArmyEvaluation,
  KM_Units, KM_UnitsCollection, KM_UnitGroup, KM_UnitWarrior,
  KM_Houses, KM_HouseCollection, KM_HouseInn,
  KM_HandLogistics, KM_HandLocks, KM_HandStats,
  KM_FogOfWar, KM_BuildList, KM_MessageLog, KM_ResHouses,
  KM_CommonClasses, KM_CommonTypes, KM_Defaults, KM_Points;


type
  TKMHandType = (
        hndHuman,
        hndComputer);

  //Player manages its assets
  TKMHandCommon = class
  private
    fID: TKMHandID; //Index of this hand in gHands
    fUnits: TKMUnitsCollection;
  public
    constructor Create(aHandIndex: TKMHandID);
    destructor Destroy; override;
    property ID: TKMHandID read fID;
    property Units: TKMUnitsCollection read fUnits;

    function AddUnit(aUnitType: TKMUnitType; const aLoc: TKMPoint): TKMUnit;
    procedure RemUnit(const Position: TKMPoint);
    function UnitsHitTest(const aLoc: TKMPoint; const UT: TKMUnitType = utAny): TKMUnit; overload;
    function UnitsHitTest(X, Y: Integer; const UT: TKMUnitType = utAny): TKMUnit; overload;

    procedure Save(SaveStream: TKMemoryStream); virtual;
    procedure Load(LoadStream: TKMemoryStream); virtual;
    procedure SyncLoad; virtual;

    procedure UpdateState(aTick: Cardinal); virtual;
    procedure Paint(const aRect: TKMRect); virtual;
  end;


  TKMHand = class(TKMHandCommon)
  private
    fAI: TKMHandAI;
    fBuildList: TKMBuildList; //Not the best name for buildingManagement
    fDeliveries: TKMHandLogistics;
    fFogOfWar: TKMFogOfWar; //Stores FOW info for current player, which includes
    fHouses: TKMHousesCollection;
    fLocks: TKMHandLocks;
    fRoadsList: TKMPointList; //Used only once to speedup mission loading, then freed
    fStats: TKMHandStats;
    fUnitGroups: TKMUnitGroups;
    fMessageLog: TKMMessageLog;

    fOwnerNikname: AnsiString; //Multiplayer owner nikname
    fHandType: TKMHandType;
    fCanBeHuman: Boolean;
    fHandAITypes: TKMAITypeSet;
    fFlagColor: Cardinal;
    fTeamColor: Cardinal;
    fCenterScreen: TKMPoint;
    fAlliances: array [0 .. MAX_HANDS - 1] of TKMAllianceType;
    fShareFOW: array [0 .. MAX_HANDS - 1] of Boolean;
    fShareBeacons: array [0 .. MAX_HANDS - 1] of Boolean;

    //House sketch fields, used to GetNextHouseWSameType
    fHSketch: TKMHouseSketchEdit;
    fFirstHSketch: TKMHouseSketchEdit;
    fFoundHSketch: TKMHouseSketchEdit;

    fOnAllianceChange: TEvent;

    function GetColorIndex: Byte;

    function  GetAlliances(aIndex: Integer): TKMAllianceType; inline;
    procedure SetAlliances(aIndex: Integer; aValue: TKMAllianceType); inline;
    function  GetShareFOW(aIndex: Integer): Boolean;
    procedure SetShareFOW(aIndex: Integer; aValue: Boolean);
    function  GetShareBeacons(aIndex: Integer): Boolean;
    procedure SetShareBeacons(aIndex: Integer; aValue: Boolean);
    procedure GroupDied(aGroup: TKMUnitGroup);
    procedure HouseDestroyed(aHouse: TKMHouse; aFrom: TKMHandID);
    procedure UnitDied(aUnit: TKMUnit; aFrom: TKMHandID);
    procedure UnitTrained(aUnit: TKMUnit);
    procedure WarriorWalkedOut(aUnit: TKMUnitWarrior);
    function LocHasNoAllyPlans(const aLoc: TKMPoint): Boolean;
    function GetGameFlagColor: Cardinal;
    function GetOwnerNiknameU: UnicodeString;
  public
    Enabled: Boolean;
    InCinematic: Boolean;

    //Used for syncing hotkeys in multiplayer saves only. UI keeps local value to avoid GIP delays
    SelectionHotkeys: array[0..DYNAMIC_HOTKEYS_NUM-1] of Integer;

    constructor Create(aHandIndex: TKMHandID; aOnAllianceChange: TEvent);
    destructor Destroy; override;

    property AI: TKMHandAI read fAI;
    property BuildList: TKMBuildList read fBuildList;
    property Deliveries: TKMHandLogistics read fDeliveries;
    property Houses: TKMHousesCollection read fHouses;
    property Locks: TKMHandLocks read fLocks;
    property Stats: TKMHandStats read fStats;
    property FogOfWar: TKMFogOfWar read fFogOfWar;
    property UnitGroups: TKMUnitGroups read fUnitGroups;
    property MessageLog: TKMMessageLog read fMessageLog;

    procedure SetHandIndex(aNewIndex: TKMHandID);
    procedure SetOwnerNikname(const aName: AnsiString); //MP owner nikname (empty in SP)
    property OwnerNikname: AnsiString read fOwnerNikname;
    property OwnerNiknameU: UnicodeString read GetOwnerNiknameU;
    function OwnerName(aNumberedAIs: Boolean = True): UnicodeString; //Universal owner name
    function GetOwnerName: UnicodeString;
    function GetOwnerNameColored: AnsiString;
    function GetOwnerNameColoredU: UnicodeString;
    function HasAssets: Boolean;
    property HandType: TKMHandType read fHandType write fHandType; //Is it Human or AI
    property CanBeHuman: Boolean read fCanBeHuman write fCanBeHuman;
    property HandAITypes: TKMAITypeSet read fHandAITypes;
    property FlagColor: Cardinal read fFlagColor write fFlagColor;
    property TeamColor: Cardinal read fTeamColor write fTeamColor;
    property GameFlagColor: Cardinal read GetGameFlagColor;
    property FlagColorIndex: Byte read GetColorIndex;
    property Alliances[aIndex: Integer]: TKMAllianceType read GetAlliances write SetAlliances;
    property ShareFOW[aIndex: Integer]: Boolean read GetShareFOW write SetShareFOW;
    property ShareBeacons[aIndex: Integer]: Boolean read GetShareBeacons write SetShareBeacons;
    property CenterScreen: TKMPoint read fCenterScreen write fCenterScreen;

    procedure AddAIType(aHandAIType: TKMAIType);

    procedure PostLoadMission;

    function IsHuman: Boolean;
    function IsComputer: Boolean;

    procedure AfterMissionInit(aFlattenRoads: Boolean);

    function AddUnit(aUnitType: TKMUnitType; const aLoc: TKMPoint; AutoPlace: Boolean = True; aRequiredWalkConnect: Byte = 0; aCheat: Boolean = False): TKMUnit; reintroduce;
    function AddUnitGroup(aUnitType: TKMUnitType; const Position: TKMPoint; aDir: TKMDirection; aUnitPerRow, aCount: Word): TKMUnitGroup;

    function TrainUnit(aUnitType: TKMUnitType; const Position: TKMPoint): TKMUnit;

    function GetNextHouseWSameType(aHouseType: TKMHouseType; aStartFromUID: Cardinal): TKMHouse; overload;
    function GetNextHouseWSameType(aHouseType: TKMHouseType; aStartFromUID: Cardinal;
                                   out aHouseSketch: TKMHouseSketchEdit;
                                   aSketchTypesSet: TKMHouseSketchTypeSet = [hstHouse]): TKMHouse; overload;
    function GetNextHouseWSameType(aHouseType: TKMHouseType; aStartFromUID: Cardinal;
                                   out aHouseSketch: TKMHouseSketchEdit;
                                   aSketchTypesSet: TKMHouseSketchTypeSet;
                                   aVerifySketch: TAnonHouseSketchBoolFn;
                                   aVerifySketchBoolParam: Boolean): TKMHouse; overload;
    function GetNextUnitWSameType(aUnitType: TKMUnitType; aStartFromUID: Cardinal): TKMUnit;
    function GetNextGroupWSameType(aUnitType: TKMUnitType; aStartFromUID: Cardinal): TKMUnitGroup;

    function CanAddFieldPlan(const aLoc: TKMPoint; aFieldType: TKMFieldType): Boolean;
    function CanAddFakeFieldPlan(const aLoc: TKMPoint; aFieldType: TKMFieldType): Boolean;
    function CanRemFakeFieldPlan(const aLoc: TKMPoint; aFieldType: TKMFieldType): Boolean;
    function CanAddHousePlan(const aLoc: TKMPoint; aHouseType: TKMHouseType): Boolean;
    function CanAddHousePlanAI(aX, aY: Word; aHouseType: TKMHouseType; aCheckInfluence: Boolean): Boolean;

    procedure AddRoadToList(const aLoc: TKMPoint);
    procedure AddRoad(const aLoc: TKMPoint);
    procedure AddField(const aLoc: TKMPoint; aFieldType: TKMFieldType; aStage: Byte = 0; aKeepOldObject: Boolean = False);
    procedure ToggleFieldPlan(const aLoc: TKMPoint; aFieldType: TKMFieldType; aMakeSound: Boolean);
    procedure ToggleFakeFieldPlan(const aLoc: TKMPoint; aFieldType: TKMFieldType);
    function AddHouse(aHouseType: TKMHouseType; PosX, PosY:word; RelativeEntrace: Boolean): TKMHouse;
    procedure AddHousePlan(aHouseType: TKMHouseType; const aLoc: TKMPoint);
    function AddHouseWIP(aHouseType: TKMHouseType; const aLoc: TKMPoint): TKMHouse;
    procedure RemGroup(const Position: TKMPoint);
    procedure RemHouse(const Position: TKMPoint; DoSilent: Boolean; IsEditor: Boolean = False);
    procedure RemHousePlan(const Position: TKMPoint);
    procedure RemFieldPlan(const Position: TKMPoint; aMakeSound:Boolean);
    procedure RemFakeFieldPlan(const Position: TKMPoint);
    function FindInn(Loc: TKMPoint; aUnit: TKMUnit; UnitIsAtHome: Boolean = False): TKMHouseInn;
    function FindHouse(aType: TKMHouseType; const aPosition: TKMPoint; Index: Byte = 1): TKMHouse; overload;
    function FindHouse(aType: TKMHouseType; Index: Byte=1): TKMHouse; overload;
    function FindHousesInRadius(const aLoc: TKMPoint; aSqrRadius: Single; aTypes: THouseTypeSet = [HOUSE_MIN..HOUSE_MAX]; aOnlyCompleted: Boolean = True): TKMHouseArray;
    function HitTest(X,Y: Integer): TObject;
    function HousesHitTest(X, Y: Integer): TKMHouse;
    function GroupsHitTest(X, Y: Integer): TKMUnitGroup;
    function ObjectByUID(aUID: Integer): TObject;
    procedure GetHouseMarks(const aLoc: TKMPoint; aHouseType: TKMHouseType; aList: TKMPointTagList; aIgnoreFOW: Boolean = False);

    function GetFieldsCount: Integer;
    procedure GetFieldPlans(aList: TKMPointTagList; const aRect: TKMRect; aIncludeFake: Boolean);
    procedure GetHousePlans(aList: TKMPointDirList; const aRect: TKMRect);
    procedure GetPlansTablets(aList: TKMPointTagList; const aRect: TKMRect);

    function CanDoStatsUpdate(aTick: Cardinal): Boolean;

    procedure Save(SaveStream: TKMemoryStream); override;
    procedure Load(LoadStream: TKMemoryStream); override;
    procedure SyncLoad; override;
    procedure IncAnimStep;
    procedure UpdateState(aTick: Cardinal); override;
    procedure Paint(const aRect: TKMRect); override;
  end;


  TKMHandAnimals = class (TKMHandCommon)
  public
    function GetFishInWaterBody(aWaterID: Byte; FindHighestCount: Boolean=True): TKMUnitAnimal;
  end;

  function GetStatsUpdatePeriod: Integer;


implementation
uses
  Classes, SysUtils, KromUtils, Math,
  KM_GameApp, KM_Game, KM_Terrain, KM_HouseBarracks, KM_HouseTownHall,
  KM_HandsCollection, KM_Sound, KM_AIFields,
  KM_Resource, KM_ResSound, KM_ResTexts, KM_ResMapElements, KM_ScriptingEvents,
  KM_GameTypes, KM_CommonUtils;


{ TKMHandCommon }
constructor TKMHandCommon.Create(aHandIndex: TKMHandID);
begin
  inherited Create;
  fID  := aHandIndex;
  fUnits        := TKMUnitsCollection.Create;
end;


destructor TKMHandCommon.Destroy;
begin
  FreeThenNil(fUnits);
  inherited;
end;


function TKMHandCommon.AddUnit(aUnitType: TKMUnitType; const aLoc: TKMPoint): TKMUnit;
begin
  //Animals are autoplaced by default
  Result := fUnits.AddUnit(fID, aUnitType, aLoc, True);
end;


procedure TKMHandCommon.Paint(const aRect: TKMRect);
begin
  if not gGame.IsMapEditor or (mlUnits in gGame.MapEditor.VisibleLayers) then
    fUnits.Paint(aRect);
end;


procedure TKMHandCommon.RemUnit(const Position: TKMPoint);
var U: TKMUnit;
begin
  Assert(gGame.IsMapEditor);

  U := fUnits.HitTest(Position.X, Position.Y);
  if U <> nil then
    fUnits.RemoveUnit(U);
end;


procedure TKMHandCommon.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.WriteA('PlayerCommon');
  fUnits.Save(SaveStream);
end;


procedure TKMHandCommon.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.ReadAssert('PlayerCommon');
  fUnits.Load(LoadStream);
end;


procedure TKMHandCommon.SyncLoad;
begin
  fUnits.SyncLoad;
end;


function TKMHandCommon.UnitsHitTest(const aLoc: TKMPoint; const UT: TKMUnitType = utAny): TKMUnit;
begin
  Result := UnitsHitTest(aLoc.X, aLoc.Y, UT);
end;


function TKMHandCommon.UnitsHitTest(X, Y: Integer; const UT: TKMUnitType = utAny): TKMUnit;
begin
  Result := fUnits.HitTest(X, Y, UT);
end;


procedure TKMHandCommon.UpdateState(aTick: Cardinal);
begin
  fUnits.UpdateState;
end;


{ TKMHand }
constructor TKMHand.Create(aHandIndex: TKMHandID; aOnAllianceChange: TEvent);
var
  I: Integer;
begin
  inherited Create(aHandIndex);

  Enabled := True;

  fOnAllianceChange := aOnAllianceChange;

  fAI           := TKMHandAI.Create(fID);
  fFogOfWar     := TKMFogOfWar.Create(gTerrain.MapX, gTerrain.MapY);
  fLocks        := TKMHandLocks.Create;
  fStats        := TKMHandStats.Create;
  fRoadsList    := TKMPointList.Create;
  fHouses       := TKMHousesCollection.Create;
  fDeliveries   := TKMHandLogistics.Create(fID);
  fBuildList    := TKMBuildList.Create;
  fUnitGroups   := TKMUnitGroups.Create;
  fMessageLog   := TKMMessageLog.Create;

  fOwnerNikname := '';
  fHandType     := hndComputer;
  fCanBeHuman   := False;
  fHandAITypes  := [];
  for I := 0 to MAX_HANDS - 1 do
  begin
    fShareFOW[I] := True; //Share FOW between allies by default (it only affects allied players)
    fShareBeacons[I] := True; //Share beacons between allies by default (it only affects allied players)
  end;
  for I := 0 to 9 do
    SelectionHotkeys[I] := -1; //Not set

  fAlliances[fID] := atAlly; //Others are set to enemy by default
  fFlagColor := DefaultTeamColors[fID]; //Init with default color, later replaced by Script
  fTeamColor := fFlagColor;

  fHSketch := TKMHouseSketchEdit.Create;
  fFirstHSketch := TKMHouseSketchEdit.Create;
  fFoundHSketch := TKMHouseSketchEdit.Create;
end;


//Destruction order is important as Houses and Units need to access
//Stats/Deliveries and other collection in their Destroy/Abandon/Demolish methods
destructor TKMHand.Destroy;
begin
  FreeAndNil(fHSketch);
  FreeAndNil(fFirstHSketch);
  FreeAndNil(fFoundHSketch);
  //Groups freed before units since we need to release pointers they have to units
  FreeThenNil(fUnitGroups);
  FreeThenNil(fMessageLog);

  //Free units
  inherited;

  FreeThenNil(fRoadsList);
  FreeThenNil(fHouses);

  //Should be freed after Houses and Units, as they write Stats on Destroy
  FreeThenNil(fLocks);
  FreeThenNil(fStats);
  FreeThenNil(fFogOfWar);
  FreeThenNil(fDeliveries);
  FreeThenNil(fBuildList);
  FreeThenNil(fAI);
end;


//Place unit of aUnitType to aLoc via script
//AutoPlace - add unit to nearest available spot if aLoc is already taken (or unwalkable)
function TKMHand.AddUnit(aUnitType: TKMUnitType; const aLoc: TKMPoint; AutoPlace: Boolean = True; aRequiredWalkConnect: Byte = 0; aCheat: Boolean = False): TKMUnit;
var
  G: TKMUnitGroup;
begin
  Result := fUnits.AddUnit(fID, aUnitType, aLoc, AutoPlace, aRequiredWalkConnect);

  //Unit failed to add, that happens
  if Result = nil then Exit;

  Result.OnUnitDied := UnitDied;
  Result.OnUnitTrained := UnitTrained; //Used for debug Scout placed by a cheat

  if Result is TKMUnitWarrior then
    TKMUnitWarrior(Result).OnWarriorWalkOut := WarriorWalkedOut;

  if Result is TKMUnitWorker then
    fBuildList.AddWorker(TKMUnitWorker(Result));
  if Result is TKMUnitSerf then
    fDeliveries.AddSerf(TKMUnitSerf(Result));

  if not aCheat then
    fStats.UnitCreated(aUnitType, False)
  else
    if Result is TKMUnitWarrior then
    begin
      //When we place a cheat Scout we want to rig it immediately

      //It's simpler to count cheat scouts as initial, rather than trained.
      //Then we don't need to mess with initial recruits.
      fStats.UnitCreated(aUnitType, False);

      G := fUnitGroups.WarriorTrained(TKMUnitWarrior(Result));
      Assert(G <> nil, 'It is certain that equipped warrior creates or finds some group to join to');
      G.OnGroupDied := GroupDied;

      //Scripting doesn't care about scouts added this way.
      //It could cause issues if the scripter assumes the warrior came from the player's barracks.
      //The event is "OnWarriorEquipped" not "OnWarriorCreated".
      //fScriptingESA.ProcWarriorEquipped(Result, G);
    end;
end;


//Start training unit in School/Barracks
//User can cancel the training, so we don't add unit to stats just yet
function TKMHand.TrainUnit(aUnitType: TKMUnitType; const Position: TKMPoint): TKMUnit;
begin
  Result := fUnits.AddUnit(fID, aUnitType, Position, False);
  Result.OnUnitDied := UnitDied;
  Result.OnUnitTrained := UnitTrained;

  if Result is TKMUnitWarrior then
    TKMUnitWarrior(Result).OnWarriorWalkOut := WarriorWalkedOut;

  //Adding a unit automatically sets gTerrain.IsUnit, but since the unit was trained
  //inside School/Barracks we don't need that
  gTerrain.UnitRem(Position);

  //Do not add unit to statistic just yet, wait till it's training complete
end;


procedure TKMHand.UnitTrained(aUnit: TKMUnit);
begin
  if aUnit.UnitType = utWorker then
    fBuildList.AddWorker(TKMUnitWorker(aUnit));
  if aUnit.UnitType = utSerf then
    fDeliveries.AddSerf(TKMUnitSerf(aUnit));

  //Warriors don't trigger "OnTrained" event, they trigger "WarriorEquipped" in WarriorWalkedOut below
  if not (aUnit is TKMUnitWarrior) then
    gScriptEvents.ProcUnitTrained(aUnit);

  fStats.UnitCreated(aUnit.UnitType, True, (aUnit.InHouse <> nil) and (aUnit.InHouse.HouseType = htTownHall));
end;


procedure TKMHand.WarriorWalkedOut(aUnit: TKMUnitWarrior);
var G: TKMUnitGroup;
    H: TKMHouse;
    HWFP: TKMHouseWFlagPoint;
begin
  //Warrior could be killed before he walked out, f.e. by script OnTick ---> Actions.UnitKill
  //Then group will be assigned to invalid warrior and never gets removed from game
  if (aUnit = nil)
  or aUnit.IsDeadOrDying then
    Exit;
  G := fUnitGroups.WarriorTrained(aUnit);
  Assert(G <> nil, 'It is certain that equipped warrior creates or finds some group to join to');
  G.OnGroupDied := GroupDied;
  if HandType = hndComputer then
  begin
    if AI.Setup.NewAI then
      AI.ArmyManagement.WarriorEquipped(G)
    else
      AI.General.WarriorEquipped(G);
    G := UnitGroups.GetGroupByMember(aUnit); //AI might assign warrior to different group
  end
  else
    if G.Count = 1 then
    begin
      //If player is human and this is the first warrior in the group, send it to the rally point
      H := HousesHitTest(aUnit.CurrPosition.X, aUnit.CurrPosition.Y-1);
      if (H is TKMHouseWFlagPoint) then
      begin
        HWFP := TKMHouseWFlagPoint(H);
        HWFP.ValidateFlagPoint; // Validate Flag point first. It will set it to a proper walkable position
        if HWFP.IsFlagPointSet
          and G.CanWalkTo(HWFP.FlagPoint, 0) then
          G.OrderWalk(HWFP.FlagPoint, True, wtokFlagPoint);
      end;
    end;
  gScriptEvents.ProcWarriorEquipped(aUnit, G);
end;


function TKMHand.AddUnitGroup(aUnitType: TKMUnitType; const Position: TKMPoint; aDir: TKMDirection; aUnitPerRow, aCount: Word): TKMUnitGroup;
var
  I: Integer;
begin
  Assert(aDir <> dirNA);
  Result := nil;

  if aUnitType in [CITIZEN_MIN..CITIZEN_MAX] then
    for I := 0 to aCount - 1 do
      AddUnit(aUnitType, Position, True)
  else
  if aUnitType in [WARRIOR_MIN..WARRIOR_MAX] then
    Result := fUnitGroups.AddGroup(fID, aUnitType, Position.X, Position.Y, aDir, aUnitPerRow, aCount);

  //Group can be nil if it fails to be placed on terrain (e.g. because of terrain height passability)
  if Result <> nil then
    Result.OnGroupDied := GroupDied;

  //Units will be added to statistic inside the function for some units may not fit on map
end;


//When adding roads from script we want to batch them all into one list to save time
//on WalkConnect and other calculations
procedure TKMHand.AddRoadToList(const aLoc: TKMPoint);
begin
  Assert(fRoadsList <> nil);

  //Sometimes maps can have roads placed outside of map bounds - ignore them
  //(on 80x80 map Loc range is 1..79, which is not obvious when placing roads manually in script)
  if gTerrain.TileInMapCoords(aLoc.X, aLoc.Y) then
    fRoadsList.Add(aLoc);
end;


function TKMHand.IsHuman: Boolean;
begin
  Result := fHandType = hndHuman;
end;


function TKMHand.IsComputer: Boolean;
begin
  Result := fHandType = hndComputer;
end;


//Lay out all roads at once to save time on Terrain lighting/passability recalculations
procedure TKMHand.AfterMissionInit(aFlattenRoads: Boolean);
begin
  Assert(fRoadsList <> nil);

  gTerrain.SetRoads(fRoadsList, fID, not aFlattenRoads); //If we are flattening roads that will update WalkConnect anyway
  if aFlattenRoads then
    gTerrain.FlattenTerrain(fRoadsList);

  FreeAndNil(fRoadsList);

  if not gGame.IsMapEditor then
    fAI.AfterMissionInit;
end;


function TKMHand.GetNextHouseWSameType(aHouseType: TKMHouseType; aStartFromUID: Cardinal): TKMHouse;
begin
  Result := GetNextHouseWSameType(aHouseType, aStartFromUID, TKMHouseSketchEdit.DummyHouseSketch);
end;


function TKMHand.GetNextHouseWSameType(aHouseType: TKMHouseType; aStartFromUID: Cardinal;
                                       out aHouseSketch: TKMHouseSketchEdit;
                                       aSketchTypesSet: TKMHouseSketchTypeSet = [hstHouse]): TKMHouse;
begin
  Result := GetNextHouseWSameType(aHouseType, aStartFromUID, aHouseSketch, aSketchTypesSet, nil, False);
end;


function TKMHand.GetNextHouseWSameType(aHouseType: TKMHouseType; aStartFromUID: Cardinal;
                                       out aHouseSketch: TKMHouseSketchEdit;
                                       aSketchTypesSet: TKMHouseSketchTypeSet;
                                       aVerifySketch: TAnonHouseSketchBoolFn;
                                       aVerifySketchBoolParam: Boolean): TKMHouse;

var
  ResultSet: Boolean;

  procedure FillHSketchByHouse(out aHouseSketchTmp: TKMHouseSketchEdit; aHouse: TKMHouse);
  begin
    if not aHouse.IsDestroyed // not destroyed
      and (aHouse.HouseType = aHouseType)
      {and (not aConsiderHousePlan or aHouse.IsComplete)} then
    begin
      aHouseSketchTmp.SetUID(aHouse.UID);
      aHouseSketchTmp.SetHouseType(aHouse.HouseType);
      aHouseSketchTmp.SetPosition(aHouse.Position);
    end;
  end;

  procedure FillHSketchByHPlan(out aHouseSketchTmp: TKMHouseSketchEdit; aHousePlan: TKMHousePlan);
  begin
    if not aHousePlan.IsEmpty
      and (aHousePlan.HouseType = aHouseType) then
    begin
      aHouseSketchTmp.SetUID(aHousePlan.UID);
      aHouseSketchTmp.SetHouseType(aHousePlan.HouseType);
      aHouseSketchTmp.SetPosition(aHousePlan.Loc);
    end;
  end;

  function GetNextHSketch(aIndex: Integer; out aHouseSketchTmp: TKMHouseSketchEdit): Boolean;
  var
    Sketch2Verify: TKMHouseSketch;
  begin
    aHouseSketchTmp.Clear;

    Sketch2Verify := nil;

    if (hstHouse in aSketchTypesSet) and (aIndex < fHouses.Count) then
    begin
      FillHSketchByHouse(aHouseSketchTmp, fHouses[aIndex]);
      Sketch2Verify := fHouses[aIndex];
    end else if (hstHousePlan in aSketchTypesSet) then
    begin
      FillHSketchByHPlan(aHouseSketchTmp, fBuildList.HousePlanList.Plans[aIndex - Byte(hstHouse in aSketchTypesSet)*fHouses.Count]);
      Sketch2Verify := aHouseSketchTmp;
    end;

    Result := not aHouseSketchTmp.IsEmpty
              and (not Assigned(aVerifySketch) or aVerifySketch(Sketch2Verify, aVerifySketchBoolParam));
  end;

  procedure FillResult(aIndex: Integer; aHSketch: TKMHouseSketchEdit);
  begin
    ResultSet := True;
    if aHouseSketch <> nil then
      aHSketch.CopyTo(aHouseSketch);
    if aIndex < fHouses.Count then
      Result := fHouses[aIndex];
  end;

var
  Found: Boolean; //Flag when we find house sketch (House or HousePlan) with specified Starting UID
  I, FirstHSketchI, FoundSketchI, Cnt: Integer;
begin
  Result := nil;
  aHouseSketch.Clear;

  Found := False;
  ResultSet := False;

  Cnt :=   Byte(hstHouse in aSketchTypesSet)*fHouses.Count
         + Byte(hstHousePlan in aSketchTypesSet)*fBuildList.HousePlanList.Count;

  I := 0;
  FirstHSketchI := 0;
  FoundSketchI := 0;

  fHSketch.Clear;
  fFirstHSketch.Clear;
  fFoundHSketch.Clear;

  while I < Cnt do
  begin
    try
      if not GetNextHSketch(I, fHSketch) then
        Continue;

      //Just find any first house
      if (aStartFromUID = 0) then
      begin
        FillResult(I, fHSketch);
        Break;
      end;

      //Find first house from specified UID
      if (fHSketch.UID = aStartFromUID) then
      begin
        Found := True;               // Mark that we found our house
        fHSketch.CopyTo(fFoundHSketch);
        FoundSketchI := I;
      end
      else if Found then
      begin
        FillResult(I, fHSketch);           // Save the next house after Found to Result and Break
        Break;
      end else if fFirstHSketch.IsEmpty then
      begin
        fHSketch.CopyTo(fFirstHSketch);            // Save 1st house in list in case our house is the last one
        FirstHSketchI := I;
      end;
    finally
      Inc(I);
    end;
  end;

  if not ResultSet then // Found should be always True here
  begin
    if Found then
    begin
      if fFirstHSketch.IsEmpty then
        FillResult(FoundSketchI, fFoundHSketch)   //Could happen, when we have only 1 house with that type...
      else
        FillResult(FirstHSketchI, fFirstHSketch);
    end else if not fFirstHSketch.IsEmpty then
      FillResult(FirstHSketchI, fFirstHSketch);
  end;
end;


function TKMHand.GetNextUnitWSameType(aUnitType: TKMUnitType; aStartFromUID: Cardinal): TKMUnit;
var
  U, FirstU, LastU: TKMUnit;
  Found: Boolean;
  I: Integer;
begin
  Result := nil;

  Found := False;
  FirstU := nil;
  LastU := nil;

  for I := 0 to fUnits.Count - 1 do
  begin
    U := fUnits[I];
    if (U = nil)
      or U.IsDeadOrDying
      or (U.UnitType <> aUnitType)
      or not U.Visible then
      Continue;

    //Just find any first house
    if (aStartFromUID = 0) then
    begin
      Result := U;
      Break;
    end;

    LastU := U;

    if U.UID = aStartFromUID then
      Found := True                // Mark that we found our unit
    else if Found then
    begin
      Result := U;                 // Save the next unit after Found to Result and Break
      Break;
    end else if FirstU = nil then
      FirstU := U;                 // Save 1st unit in list in case our unit is the last one
  end;

  if (Result = nil) and Found then   // Found should be always True here
  begin
    if FirstU = nil then //Could happen, when we have only 1 unit with that type...
      Result := LastU
    else
      Result := FirstU;
  end;
end;


function TKMHand.GetNextGroupWSameType(aUnitType: TKMUnitType; aStartFromUID: Cardinal): TKMUnitGroup;
var
  Group, FirstG, LastG: TKMUnitGroup;
  Found: Boolean;
  I: Integer;
begin
  Result := nil;

  Found := False;
  FirstG := nil;
  LastG := nil;

  for I := 0 to UnitGroups.Count - 1 do
  begin
    Group := UnitGroups[I];

    if (Group = nil)
      or Group.IsDead //check if group is dead
      or not Group.HasUnitType(aUnitType) then // we are interested in groups with the same type only
      Continue;

    //Just find any first house
    if (aStartFromUID = 0) then
    begin
      Result := Group;
      Break;
    end;

    LastG := Group;

    if Group.UID = aStartFromUID then
      Found := True               // Mark that we found our group
    else if Found then
    begin
      Result := Group;            // Save the next group after Found to Result and Break
      Break;
    end else if FirstG = nil then
      FirstG := Group;            // Save 1st group in list in case our group is the last one
  end;
  if (Result = nil) and Found then // Found should be always True here
  begin
    if FirstG = nil then  //Could happen, when we have only 1 group with that type...
      Result := LastG
    else
      Result := FirstG;
  end;
end;


procedure TKMHand.SetHandIndex(aNewIndex: TKMHandID);
begin
  fID := aNewIndex;
  fUnits.OwnerUpdate(aNewIndex);
  fHouses.OwnerUpdate(aNewIndex);
  fAI.OwnerUpdate(aNewIndex);
end;


procedure TKMHand.SetOwnerNikname(const aName: AnsiString); //MP owner nikname (empty in SP)
begin
  fOwnerNikname := aName;
end;


procedure TKMHand.AddRoad(const aLoc: TKMPoint);
begin
  gTerrain.SetRoad(aLoc, fID);
end;


procedure TKMHand.AddField(const aLoc: TKMPoint; aFieldType: TKMFieldType; aStage: Byte = 0; aKeepOldObject: Boolean = False);
var
  IsFieldSet: Boolean;
  Obj: Word;
begin
  IsFieldSet := False;
  Obj := gTerrain.Land[aLoc.Y,aLoc.X].Obj;
  //If we have corn/wine object on that tile, set appropriate field/wine stage
  if (aFieldType = ftCorn) and not gTerrain.TileIsCornField(aLoc) then
  begin
    if ObjectIsCorn(Obj) then
    begin
      gTerrain.SetField(aLoc, fID, aFieldType, Obj - 54, True, aKeepOldObject);
      IsFieldSet := True;
    end;
  end else if (aFieldType = ftWine) and not gTerrain.TileIsWineField(aLoc) then
  begin
    if ObjectIsWine(Obj) then
    begin
      gTerrain.SetField(aLoc, fID, aFieldType, Obj - 54, True, aKeepOldObject);
      IsFieldSet := True;
    end;
  end;

  if not IsFieldSet then
    gTerrain.SetField(aLoc, fID, aFieldType, aStage, True, aKeepOldObject);
end;


function TKMHand.LocHasNoAllyPlans(const aLoc: TKMPoint): Boolean;
var
  I: Integer;
begin
  Result := True;
  //Don't allow placing on allies plans either
  for I := 0 to gHands.Count - 1 do
    if (I <> fID) and (fAlliances[I] = atAlly) then
      Result := Result and (gHands[i].fBuildList.FieldworksList.HasField(aLoc) = ftNone)
                       and not gHands[i].fBuildList.HousePlanList.HasPlan(aLoc);
end;


function TKMHand.GetGameFlagColor: Cardinal;
begin
  Result := fFlagColor;
  if (gGame <> nil) and not gGame.IsMapEditor then
  begin
    case gGameApp.GameSettings.PlayersColorMode of
      pcmAllyEnemy: begin
                      if ID = gMySpectator.HandID then
                        Result := gGameApp.GameSettings.PlayerColorSelf
                      else if (Alliances[gMySpectator.HandID] = atAlly) then
                        Result := gGameApp.GameSettings.PlayerColorAlly
                      else
                        Result := gGameApp.GameSettings.PlayerColorEnemy;
                    end;
      pcmTeams:     Result := fTeamColor;
    end;

  end;
end;


function TKMHand.GetOwnerNiknameU: UnicodeString;
begin
  Result := UnicodeString(fOwnerNikname);
end;


//See comment on CanAddFakeFieldPlan
function TKMHand.CanAddFieldPlan(const aLoc: TKMPoint; aFieldType: TKMFieldType): Boolean;
begin
  Result := gTerrain.CanAddField(aLoc.X, aLoc.Y, aFieldType)
            and (fBuildList.FieldworksList.HasField(aLoc) = ftNone)
            and not fBuildList.HousePlanList.HasPlan(aLoc)
            and LocHasNoAllyPlans(aLoc);
end;


//This differs from above only in that it uses HasFakeField instead of HasField.
//We need it because the user expects to be blocked by fake field plans, but the gameplay should not.
//When the result effects the outcome of the game, the above function should be used instead.
function TKMHand.CanAddFakeFieldPlan(const aLoc: TKMPoint; aFieldType: TKMFieldType): Boolean;
begin
  Result := gTerrain.CanAddField(aLoc.X, aLoc.Y, aFieldType)
            and (fBuildList.FieldworksList.HasFakeField(aLoc) = ftNone)
            and not fBuildList.HousePlanList.HasPlan(aLoc)
            and LocHasNoAllyPlans(aLoc);
end;


// Same as for CanAddFakeFieldPlan, but check can we delete plan
function TKMHand.CanRemFakeFieldPlan(const aLoc: TKMPoint; aFieldType: TKMFieldType): Boolean;
begin
  Result := (fBuildList.FieldworksList.HasFakeField(aLoc) = aFieldType)
            and LocHasNoAllyPlans(aLoc);
end;


function TKMHand.CanAddHousePlan(const aLoc: TKMPoint; aHouseType: TKMHouseType): Boolean;
var I,K,J,S,T,Tx,Ty: Integer; HA: THouseArea;
begin
  Result := gTerrain.CanPlaceHouse(aLoc, aHouseType);
  if not Result then Exit;

  HA := gRes.Houses[aHouseType].BuildArea;
  for I := 1 to 4 do
  for K := 1 to 4 do
  if HA[I,K] <> 0 then
  begin
    Tx := aLoc.X - gRes.Houses[aHouseType].EntranceOffsetX + K - 3;
    Ty := aLoc.Y + I - 4;
    //AI ignores FOW (this function is used from scripting)
    Result := Result and gTerrain.TileInMapCoords(Tx, Ty, 1)
                     and ((fHandType = hndComputer) or (fFogOfWar.CheckTileRevelation(Tx, Ty) > 0));
    //This checks below require Tx;Ty to be within the map so exit immediately if they are not
    if not Result then exit;

    //This tile must not contain fields/houses of allied players or self
    for J := 0 to gHands.Count - 1 do
      if fAlliances[J] = atAlly then
      begin
        Result := Result and (gHands[J].fBuildList.FieldworksList.HasField(KMPoint(Tx,Ty)) = ftNone);
        //Surrounding tiles must not be a house
        for S := -1 to 1 do
          for T := -1 to 1 do
            Result := Result and not gHands[J].fBuildList.HousePlanList.HasPlan(KMPoint(Tx+S,Ty+T));
      end;
  end;
end;


function TKMHand.CanAddHousePlanAI(aX, aY: Word; aHouseType: TKMHouseType; aCheckInfluence: Boolean): Boolean;
var
  I, K, J, S, T, Tx, Ty: Integer;
  HA: THouseArea;
  EnterOff: ShortInt;
  TerOwner: TKMHandID;
begin
  Result := False;

  //Check if we can place house on terrain, this also makes sure the house is
  //at least 1 tile away from map border (skip that below)
  if not gTerrain.CanPlaceHouse(KMPoint(aX, aY), aHouseType) then
    Exit;

  //Perform additional cheks for AI
  HA := gRes.Houses[aHouseType].BuildArea;
  EnterOff := gRes.Houses[aHouseType].EntranceOffsetX;
  for I := 1 to 4 do
  for K := 1 to 4 do
  if HA[I,K] <> 0 then
  begin
    Tx := aX + K - 3 - EnterOff;
    Ty := aY + I - 4;

    //Make sure we don't block existing roads
    if gTerrain.CheckPassability(KMPoint(Tx, Ty), tpWalkRoad) then
      Exit;

    //Check with influence maps
    if aCheckInfluence and AI_GEN_INFLUENCE_MAPS then
    begin
      //Check if tile's blocked
      if (gAIFields.Influences.AvoidBuilding[Ty, Tx] > 0) then
        Exit;

      //Check ownership for entrance (good enough since it does not changes that fast)
      if (HA[I,K] = 2) then
      begin
        TerOwner := gAIFields.Influences.GetBestOwner(Tx,Ty);
        if ((TerOwner <> fID) and (TerOwner <> PLAYER_NONE)) then
          Exit;
      end;
    end;

    //Avoid placing houses in choke-points _/house\_ by checking upper corners
    if not (aHouseType in [htGoldMine, htIronMine]) then
      if (gTerrain.Land[Ty-1, Tx - 1].Passability * [tpMakeRoads, tpWalkRoad] = [])
      or (gTerrain.Land[Ty-1, Tx + 1].Passability * [tpMakeRoads, tpWalkRoad] = [])
      then
        Exit;

    //Make sure we can add road below house, full width + 1 on each side
    //Terrain already checked we are 1 tile away from map edge
    if (I = 4) and not (aHouseType in [htGoldMine, htIronMine]) then
      if (gTerrain.Land[Ty+1, Tx - 1].Passability * [tpMakeRoads, tpWalkRoad] = [])
      or (gTerrain.Land[Ty+1, Tx    ].Passability * [tpMakeRoads, tpWalkRoad] = [])
      or (gTerrain.Land[Ty+1, Tx + 1].Passability * [tpMakeRoads, tpWalkRoad] = [])
      then
        Exit;

    //This tile must not contain fields/houseplans of allied players or self
    for J := 0 to gHands.Count - 1 do
      if fAlliances[J] = atAlly then
      begin
        if (gHands[J].fBuildList.FieldworksList.HasField(KMPoint(Tx,Ty)) <> ftNone) then
          Exit;

        //Surrounding tiles must not be a house
        for S := -1 to 1 do
        for T := -1 to 1 do
        if gHands[J].fBuildList.HousePlanList.HasPlan(KMPoint(Tx+S,Ty+T)) then
          Exit;
      end;
  end;

  Result := True;
end;


//Due to lag there could be already plans placed by user in previous ticks
//Check if Plan can be placed once again, as we might have conflicting commands caused by lag
//This is called by GIP when a place field command is processed
procedure TKMHand.ToggleFieldPlan(const aLoc: TKMPoint; aFieldType: TKMFieldType; aMakeSound: Boolean);
var Plan: TKMFieldType;
begin
  Assert(aFieldType in [ftRoad, ftCorn, ftWine], 'Placing wrong FieldType');

  Plan := fBuildList.FieldworksList.HasField(aLoc);
  if aFieldType = Plan then //Same plan - remove it
    RemFieldPlan(aLoc,aMakeSound)
  else
    if CanAddFieldPlan(aLoc, aFieldType) then
    begin
      if aMakeSound and not (gGame.GameMode in [gmMultiSpectate, gmReplaySingle, gmReplayMulti])
        and (ID = gMySpectator.HandID) then
        gSoundPlayer.Play(sfxPlacemarker);
      fBuildList.FieldworksList.AddField(aLoc, aFieldType);
      case aFieldType of
         ftRoad: gScriptEvents.ProcPlanRoadPlaced(fID, aLoc.X, aLoc.Y);
         ftCorn: gScriptEvents.ProcPlanFieldPlaced(fID, aLoc.X, aLoc.Y);
         ftWine: gScriptEvents.ProcPlanWinefieldPlaced(fID, aLoc.X, aLoc.Y);
      else
        raise Exception.Create('Unknown aFieldType');
      end;
    end
    else
    begin
      if aMakeSound and not (gGame.GameMode in [gmMultiSpectate, gmReplaySingle, gmReplayMulti])
        and (ID = gMySpectator.HandID) then
        gSoundPlayer.Play(sfxCantPlace, 4);
      if Plan = ftNone then //If we can't build because there's some other plan, that's ok
      begin
        //Can't build here anymore because something changed between click and command processing, so remove any fake plans
        fBuildList.FieldworksList.RemFakeField(aLoc);
        fBuildList.FieldworksList.RemFakeDeletedField(aLoc);
      end;
    end;
end;


//This procedure does not effect gameplay, it only changes fake field plans to make it look better for the user
//It is called when the user clicks to place a field plan
procedure TKMHand.ToggleFakeFieldPlan(const aLoc: TKMPoint; aFieldType: TKMFieldType);
var Plan: TKMFieldType;
begin
  Assert(aFieldType in [ftRoad, ftCorn, ftWine], 'Placing wrong fake FieldType');

  Plan := fBuildList.FieldworksList.HasFakeField(aLoc);
  if aFieldType = Plan then //Same plan - remove it
  begin
    fBuildList.FieldworksList.RemFakeField(aLoc); //Remove our fake marker which is shown to the user
    fBuildList.FieldworksList.AddFakeDeletedField(aLoc); //This will hide the real field until it is deleted from game
    if ID = gMySpectator.HandID then gSoundPlayer.Play(sfxClick);
  end
  else
    if CanAddFakeFieldPlan(aLoc, aFieldType) then
    begin
      fBuildList.FieldworksList.AddFakeField(aLoc, aFieldType);
      if ID = gMySpectator.HandID then
        gSoundPlayer.Play(sfxPlacemarker);
    end
    else
      if ID = gMySpectator.HandID then
        gSoundPlayer.Play(sfxCantPlace, 4);
end;


//Used mainly for testing purposes
{procedure TKMHand.AddRoadConnect(LocA,LocB: TKMPoint);
var
  NodeList: TKMPointList;
  RoadExists: Boolean;
  I: Integer;
begin
  NodeList := TKMPointList.Create;
  try
    RoadExists := fTerrain.PathFinding.Route_Make(LocA, LocB, CanMakeRoads, 0, nil, NodeList);
    if RoadExists then
      for I := 1 to NodeList.Count do
        AddField(NodeList.List[i], ftRoad);
  finally
    FreeAndNil(NodeList);
  end;
end;}


function TKMHand.AddHouse(aHouseType: TKMHouseType; PosX, PosY:word; RelativeEntrace: Boolean): TKMHouse;
begin
  Result := fHouses.AddHouse(aHouseType, PosX, PosY, fID, RelativeEntrace);
  Result.OnDestroyed := HouseDestroyed;
end;


//Add plan of a house, house is not created until after worker flattens the terrain
procedure TKMHand.AddHousePlan(aHouseType: TKMHouseType; const aLoc: TKMPoint);
var
  Loc: TKMPoint;
begin
  Loc.X := aLoc.X - gRes.Houses[aHouseType].EntranceOffsetX;
  Loc.Y := aLoc.Y;

  fBuildList.HousePlanList.AddPlan(aHouseType, Loc);
  fStats.HousePlanned(aHouseType);
  gScriptEvents.ProcHousePlanPlaced(fID, Loc.X, Loc.Y, aHouseType);

  if (ID = gMySpectator.HandID) and not (gGame.GameMode in [gmMultiSpectate, gmReplaySingle, gmReplayMulti]) then
    gSoundPlayer.Play(sfxPlacemarker);
end;


function TKMHand.AddHouseWIP(aHouseType: TKMHouseType; const aLoc: TKMPoint): TKMHouse;
begin
  Result := fHouses.AddHouseWIP(aHouseType, aLoc.X, aLoc.Y, fID);
  Result.OnDestroyed := HouseDestroyed;

  fStats.HouseStarted(aHouseType);
end;


//Player wants to remove own house
procedure TKMHand.RemHouse(const Position: TKMPoint; DoSilent: Boolean; IsEditor: Boolean = False);
var H: TKMHouse;
begin
  //Sound is handled in DemolishHouse
  H := fHouses.HitTest(Position.X, Position.Y);
  if H = nil then Exit; //Due to network delays the house might have already been destroyed by now

  H.DemolishHouse(fID, IsEditor);
end;


procedure TKMHand.RemHousePlan(const Position: TKMPoint);
var
  HPlan: TKMHousePlan;
begin
  if not fBuildList.HousePlanList.TryGetPlan(Position, HPlan) then //Due to network delays house might not exist now
    Exit;

  fBuildList.HousePlanList.RemPlan(Position);
  fStats.HousePlanRemoved(HPlan.HouseType);
  gScriptEvents.ProcHousePlanRemoved(fID, HPlan.Loc.X, HPlan.Loc.Y, HPlan.HouseType);
  if (ID = gMySpectator.HandID) and not (gGame.GameMode in [gmMultiSpectate, gmReplaySingle, gmReplayMulti]) then
    gSoundPlayer.Play(sfxClick);
end;


//This is called by the GIP when an erase command is processed
procedure TKMHand.RemFieldPlan(const Position: TKMPoint; aMakeSound: Boolean);
var
  fieldType: TKMFieldType;
begin
  fieldType := fBuildList.FieldworksList.HasField(Position);
  if fieldType = ftNone then Exit; //Can happen due to network delays
  fBuildList.FieldworksList.RemFieldPlan(Position);

  case fieldType of
    ftRoad: gScriptEvents.ProcPlanRoadRemoved(fID, Position.X, Position.Y);
    ftCorn: gScriptEvents.ProcPlanFieldRemoved(fID, Position.X, Position.Y);
    ftWine: gScriptEvents.ProcPlanWinefieldRemoved(fID, Position.X, Position.Y);
  else
    raise Exception.Create('Unknown fieldType');
  end;

  if aMakeSound and not (gGame.GameMode in [gmMultiSpectate, gmReplaySingle, gmReplayMulti])
  and (ID = gMySpectator.HandID) then
    gSoundPlayer.Play(sfxClick);
end;


procedure TKMHand.RemGroup(const Position: TKMPoint);
var Group: TKMUnitGroup;
begin
  Assert(gGame.IsMapEditor);

  Group := fUnitGroups.HitTest(Position.X, Position.Y);
  if Group <> nil then
    fUnitGroups.RemGroup(Group);
end;


//This is called immediately when the user clicks erase on a field plan.
//We know that an erase command is queued and will be processed in some ticks,
//so we AddFakeDeletedField which lets the user think the field was removed,
//while the game does not know the difference.
procedure TKMHand.RemFakeFieldPlan(const Position: TKMPoint);
begin
  fBuildList.FieldworksList.RemFakeField(Position); //Remove our fake marker which is shown to the user
  fBuildList.FieldworksList.AddFakeDeletedField(Position); //This will hide the real field until it is deleted from game
  if ID = gMySpectator.HandID then gSoundPlayer.Play(sfxClick);
end;


function TKMHand.FindHouse(aType: TKMHouseType; const aPosition: TKMPoint; Index: Byte=1): TKMHouse;
begin
  Result := fHouses.FindHouse(aType, aPosition.X, aPosition.Y, Index);
end;


function TKMHand.FindHouse(aType: TKMHouseType; Index: Byte=1): TKMHouse;
begin
  Result := fHouses.FindHouse(aType, 0, 0, Index);
end;


function TKMHand.FindHousesInRadius(const aLoc: TKMPoint; aSqrRadius: Single; aTypes: THouseTypeSet = [HOUSE_MIN..HOUSE_MAX]; aOnlyCompleted: Boolean = True): TKMHouseArray;
begin
  Result := fHouses.FindHousesInRadius(aLoc, aSqrRadius, aTypes, aOnlyCompleted);
end;


function TKMHand.FindInn(Loc: TKMPoint; aUnit: TKMUnit; UnitIsAtHome: Boolean = False): TKMHouseInn;
var
  H: TKMHouseInn;
  I: Integer;
  Dist, BestMatch: Single;
begin
  //This function will return the best inn for a unit at Loc, base on distance, food available and space available.
  //Will return nil if no suitable inn is available
  Result := nil;
  I := 1;
  BestMatch := MaxSingle;
  if UnitIsAtHome then Inc(Loc.Y); //From outside the door of the house

  H := TKMHouseInn(FindHouse(htInn));
  repeat
    //First make sure that it is valid
    if (H <> nil) and H.HasFood and H.HasSpace
    and aUnit.CanWalkTo(Loc, H.PointBelowEntrance, tpWalk, 0) then
    begin
      //Take the closest inn out of the ones that are suitable
      Dist := KMLengthSqr(H.Position, Loc);
      if Dist < BestMatch then
      begin
        Result := H;
        BestMatch := Dist;
      end;
    end;

    inc(I);
    H := TKMHouseInn(FindHouse(htInn, I));
  until(H = nil);
end;


//Does the player has any assets (without assets player is harmless)
function TKMHand.HasAssets: Boolean;
begin
  Result := (GetFieldsCount > 0) or (Units.Count > 0) or (Houses.Count > 0);
end;


procedure TKMHand.AddAIType(aHandAIType: TKMAIType);
begin
  Include(fHandAITypes, aHandAIType);
end;


procedure TKMHand.PostLoadMission;
var
  I: Integer;
begin

  for I := 0 to fHouses.Count - 1 do
    fHouses[I].PostLoadMission;
end;


function TKMHand.HitTest(X, Y: Integer): TObject;
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
  else
  begin
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


//Which house whas destroyed and by whom
procedure TKMHand.HouseDestroyed(aHouse: TKMHouse; aFrom: TKMHandID);
begin
  //Dispose of delivery tasks performed in DeliverQueue unit
  if aHouse.BuildingState in [hbsWood .. hbsDone] then
  begin
    Deliveries.Queue.RemAllOffers(aHouse);
    Deliveries.Queue.RemDemand(aHouse);
  end;

  //Only Done houses are treated as Self-Destruct, Lost, Destroyed
  if aHouse.BuildingState in [hbsNoGlyph .. hbsStone] then
    fStats.HouseEnded(aHouse.HouseType)
  else
  begin
    //We have to consider destroyed closed house as actually opened, otherwise closed houses stats will be corrupted
    if aHouse.IsClosedForWorker then
      fStats.HouseClosed(False, aHouse.HouseType);

    //Distribute honors
    if aFrom = fID then
      fStats.HouseSelfDestruct(aHouse.HouseType)
    else
    begin
      Stats.HouseLost(aHouse.HouseType);

      if aFrom <> PLAYER_NONE then
        gHands[aFrom].Stats.HouseDestroyed(aHouse.HouseType);
    end;
  end;

  //Scripting events happen AFTER updating statistics
  gScriptEvents.ProcHouseDestroyed(aHouse, aFrom);

  //gMySpectator is nil during loading, when houses can be destroyed at the start
  if gMySpectator <> nil then
  begin
    if gMySpectator.Highlight = aHouse then
      gMySpectator.Highlight := nil;
    if gMySpectator.Selected = aHouse then
      gMySpectator.Selected := nil;
  end;
end;


function TKMHand.HousesHitTest(X, Y: Integer): TKMHouse;
begin
  Result:= fHouses.HitTest(X, Y);
end;


function TKMHand.GroupsHitTest(X, Y: Integer): TKMUnitGroup;
begin
  Result:= fUnitGroups.HitTest(X, Y);
end;


function TKMHand.ObjectByUID(aUID: Integer): TObject;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Units.Count - 1 do
    if aUID = Units[I].UID then
    begin
      Result := Units[I];
      Exit;
    end;
end;


function TKMHand.GetColorIndex: Byte;
var
  I: Integer;
begin
  Result := 3; //3 = Black which can be the default when a non-palette 32 bit color value is used
  for I := 0 to 255 do
    if gRes.Palettes.DefaultPalette.Color32(I) = fFlagColor then
      Result := I;
end;


function TKMHand.OwnerName(aNumberedAIs: Boolean = True): UnicodeString;
begin
  //Default names
  if HandType = hndHuman then
    Result := gResTexts[TX_PLAYER_YOU]
  else
    if AI.Setup.NewAI then
    begin
      if aNumberedAIs then
        Result := Format(gResTexts[TX_ADVANCED_AI_PLAYER_SHORT_X], [fID + 1])
      else
        Result := gResTexts[TX_AI_PLAYER_ADVANCED_SHORT];
    end else begin
      if aNumberedAIs then
        Result := Format(gResTexts[TX_CLASSIC_AI_PLAYER_SHORT_X], [fID + 1])
      else
        Result := gResTexts[TX_AI_PLAYER_CLASSIC_SHORT];
    end;

  //Try to take player name from mission text if we are in SP
  //Do not use names in MP ot avoid confusion of AI players with real player niknames
  if gGame.GameMode in [gmSingle, gmCampaign, gmMapEd, gmReplaySingle] then
    if gGame.TextMission.HasText(HANDS_NAMES_OFFSET + fID) then
      if HandType = hndHuman then
        Result := gResTexts[TX_PLAYER_YOU] + ' (' + gGame.TextMission[HANDS_NAMES_OFFSET + fID] + ')'
      else
        Result := gGame.TextMission[HANDS_NAMES_OFFSET + fID];

  //If this location is controlled by an MP player - show his nik
  if fOwnerNikname <> '' then
    Result := UnicodeString(fOwnerNikname);
end;


function TKMHand.GetOwnerName: UnicodeString;
begin
  Result := OwnerName(not (gGame.GameMode in [gmSingle, gmCampaign, gmReplaySingle]));
end;


function TKMHand.GetOwnerNameColored: AnsiString;
begin
  Result := WrapColorA(AnsiString(GetOwnerName), FlagColorToTextColor(FlagColor));
end;


function TKMHand.GetOwnerNameColoredU: UnicodeString;
begin
  Result := WrapColor(GetOwnerName, FlagColorToTextColor(FlagColor));
end;



function TKMHand.GetAlliances(aIndex: Integer): TKMAllianceType;
begin
  Result := fAlliances[aIndex];
end;


procedure TKMHand.SetAlliances(aIndex: Integer; aValue: TKMAllianceType);
begin
  fAlliances[aIndex] := aValue;
  gAIFields.Supervisor.UpdateAlliances();

  if Assigned(fOnAllianceChange) then
    fOnAllianceChange;
end;


function  TKMHand.GetShareFOW(aIndex: Integer): Boolean;
begin
  Result := fShareFOW[aIndex];
end;


procedure TKMHand.SetShareFOW(aIndex: Integer; aValue: Boolean);
begin
  fShareFOW[aIndex] := aValue;
end;


function  TKMHand.GetShareBeacons(aIndex: Integer): Boolean;
begin
  Result := fShareBeacons[aIndex];
end;


procedure TKMHand.SetShareBeacons(aIndex: Integer; aValue: Boolean);
begin
  fShareBeacons[aIndex] := aValue;
end;


{ See if player owns any Fields/Roads/Walls (has any assets on Terrain)
  If Player has none and no Units/Houses we can assume it's empty and does not needs to be saved
  Queried by MapEditor.SaveDAT;
  Might also be used to show Players strength (or builder/warrior balance) in Tavern }
function TKMHand.GetFieldsCount: Integer;
var
  I,K: Integer;
begin
  Result := 0;
  for I := 1 to gTerrain.MapY do
  for K := 1 to gTerrain.MapX do
    if gTerrain.Land[I,K].TileOwner = fID then
      Inc(Result);
end;


procedure TKMHand.GetFieldPlans(aList: TKMPointTagList; const aRect: TKMRect; aIncludeFake: Boolean);
var
  I: TKMHandID;
begin
  //Include self and allies
  for I := 0 to gHands.Count - 1 do
    if gHands[fID].Alliances[I] = atAlly then
      gHands[I].BuildList.FieldworksList.GetFields(aList, aRect, aIncludeFake);
end;


procedure TKMHand.GetHousePlans(aList: TKMPointDirList; const aRect: TKMRect);
var
  I: TKMHandID;
begin
  //Include self and allies
  for I := 0 to gHands.Count - 1 do
    if gHands[fID].Alliances[I] = atAlly then
      gHands[I].BuildList.HousePlanList.GetOutlines(aList, aRect);
end;


procedure TKMHand.GetPlansTablets(aList: TKMPointTagList; const aRect: TKMRect);
var
  I: TKMHandID;
begin
  //Include self and allies
  for I := 0 to gHands.Count - 1 do
    if gHands[fID].Alliances[I] = atAlly then
      gHands[I].BuildList.HousePlanList.GetTablets(aList, aRect);
end;


procedure TKMHand.GetHouseMarks(const aLoc: TKMPoint; aHouseType: TKMHouseType; aList: TKMPointTagList; aIgnoreFOW: Boolean = False);
  //Replace existing icon with a Block
  procedure BlockPoint(const aPoint: TKMPoint; aID: Integer);
  var I: Integer;
  begin
    //Remove all existing marks on this tile (entrance can have 2 entries)
    for I := aList.Count - 1 downto 0 do
      if KMSamePoint(aList[I], aPoint) then
        aList.Remove(aPoint);

    aList.Add(aPoint, aID);
  end;

var
  I,K,J,S,T: Integer;
  P2: TKMPoint;
  AllowBuild: Boolean;
  HA: THouseArea;
begin
  //Get basic Marks
  gTerrain.GetHouseMarks(aLoc, aHouseType, aList);

  //Override marks if there are House/FieldPlans (only we know about our plans) and or FogOfWar
  HA := gRes.Houses[aHouseType].BuildArea;

  for I := 1 to 4 do
    for K := 1 to 4 do
      if (HA[I,K] <> 0)
        and gTerrain.TileInMapCoords(aLoc.X+K-3-gRes.Houses[aHouseType].EntranceOffsetX, aLoc.Y+I-4, 1) then
      begin
        //This can't be done earlier since values can be off-map
        P2 := KMPoint(aLoc.X+K-3-gRes.Houses[aHouseType].EntranceOffsetX, aLoc.Y+I-4);

        //Forbid planning on unrevealed areas and fieldplans
        AllowBuild := aIgnoreFOW or (fFogOfWar.CheckTileRevelation(P2.X, P2.Y) > 0);

        //This tile must not contain fields/houses of allied players or self
        if AllowBuild then
          for J := 0 to gHands.Count - 1 do
            if (gHands[fID].Alliances[J] = atAlly)
              and ((gHands[J].fBuildList.FieldworksList.HasField(P2) <> ftNone)
                or gHands[J].fBuildList.HousePlanList.HasPlan(P2)) then
              AllowBuild := False;

        //Check surrounding tiles in +/- 1 range for other houses pressence
        for S := -1 to 1 do
          for T := -1 to 1 do
            if (S <> 0) or (T <> 0) then //This is a surrounding tile, not the actual tile
              for J := 0 to gHands.Count - 1 do
                if (gHands[fID].Alliances[J] = atAlly)
                  and gHands[J].fBuildList.HousePlanList.HasPlan(KMPoint(P2.X+S,P2.Y+T)) then
                begin
                  BlockPoint(KMPoint(P2.X+S,P2.Y+T), TC_BLOCK); //Block surrounding points
                  AllowBuild := False;
                end;

        //Mark the tile according to previous check results
        if not AllowBuild then
          if HA[I,K] = 2 then
            BlockPoint(P2, TC_BLOCK_ENTRANCE)
          else
            if aHouseType in [htGoldMine, htIronMine] then
              BlockPoint(P2, TC_BLOCK_MINE)
            else
              BlockPoint(P2, TC_BLOCK);
      end;
end;


procedure TKMHand.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.Write(Enabled);
  SaveStream.Write(InCinematic);
  if not Enabled then Exit;

  inherited;
  fAI.Save(SaveStream);
  fBuildList.Save(SaveStream);
  fDeliveries.Save(SaveStream);
  fFogOfWar.Save(SaveStream);
  fHouses.Save(SaveStream);
  fLocks.Save(SaveStream);
  fStats.Save(SaveStream);
  fUnitGroups.Save(SaveStream);
  fMessageLog.Save(SaveStream);

  SaveStream.Write(fID);
  SaveStream.WriteA(fOwnerNikname);
  SaveStream.Write(fHandType, SizeOf(fHandType));
  SaveStream.Write(fCanBeHuman, SizeOf(fCanBeHuman));
  SaveStream.Write(fHandAITypes, SizeOf(fHandAITypes));
  SaveStream.Write(fAlliances, SizeOf(fAlliances));
  SaveStream.Write(fShareFOW, SizeOf(fShareFOW));
  SaveStream.Write(fShareBeacons, SizeOf(fShareBeacons));
  SaveStream.Write(fCenterScreen);
  SaveStream.Write(fFlagColor);
  SaveStream.Write(SelectionHotkeys, SizeOf(SelectionHotkeys));
end;


procedure TKMHand.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.Read(Enabled);
  LoadStream.Read(InCinematic);
  if not Enabled then Exit;

  inherited;
  fAI.Load(LoadStream);
  fBuildList.Load(LoadStream);
  fDeliveries.Load(LoadStream);
  fFogOfWar.Load(LoadStream);
  fHouses.Load(LoadStream);
  fLocks.Load(LoadStream);
  fStats.Load(LoadStream);
  fUnitGroups.Load(LoadStream);
  fMessageLog.Load(LoadStream);

  LoadStream.Read(fID);
  LoadStream.ReadA(fOwnerNikname);
  LoadStream.Read(fHandType, SizeOf(fHandType));
  LoadStream.Read(fCanBeHuman, SizeOf(fCanBeHuman));
  LoadStream.Read(fHandAITypes, SizeOf(fHandAITypes));
  LoadStream.Read(fAlliances, SizeOf(fAlliances));
  LoadStream.Read(fShareFOW, SizeOf(fShareFOW));
  LoadStream.Read(fShareBeacons, SizeOf(fShareBeacons));
  LoadStream.Read(fCenterScreen);
  LoadStream.Read(fFlagColor);
  LoadStream.Read(SelectionHotkeys, SizeOf(SelectionHotkeys));
end;


procedure TKMHand.SyncLoad;
var I: Integer;
begin
  if not Enabled then Exit;

  inherited;

  //Assign event handler after load
  for I := 0 to fUnits.Count - 1 do
  begin
    fUnits[I].OnUnitDied := UnitDied;
    fUnits[I].OnUnitTrained := UnitTrained;
    if fUnits[I] is TKMUnitWarrior then
      TKMUnitWarrior(fUnits[I]).OnWarriorWalkOut := WarriorWalkedOut;
  end;

  fUnitGroups.SyncLoad;

  //Assign event handler after load
  for I := 0 to fUnitGroups.Count - 1 do
    fUnitGroups[I].OnGroupDied := GroupDied;

  fHouses.SyncLoad;

  //Assign event handler after load
  for I := 0 to fHouses.Count - 1 do
    fHouses[I].OnDestroyed := HouseDestroyed;

  fDeliveries.SyncLoad;
  fBuildList.SyncLoad;
  fAI.SyncLoad;
end;


procedure TKMHand.IncAnimStep;
begin
  if not Enabled then Exit;

  fHouses.IncAnimStep;
end;


procedure TKMHand.UnitDied(aUnit: TKMUnit; aFrom: TKMHandID);
begin
  Stats.UnitLost(aUnit.UnitType);
  if aFrom <> PLAYER_NONE then
    gHands[aFrom].Stats.UnitKilled(aUnit.UnitType);

  //Call script event after updating statistics
  gScriptEvents.ProcUnitDied(aUnit, aFrom);

  //gMySpectator is nil during loading
  if gMySpectator <> nil then
  begin
    if gMySpectator.Highlight = aUnit then
      gMySpectator.Highlight := nil;
    if gMySpectator.Selected = aUnit then
      gMySpectator.Selected := nil;
  end;
end;


procedure TKMHand.GroupDied(aGroup: TKMUnitGroup);
begin
  //Groups arent counted in statistics
  if gMySpectator.Highlight = aGroup then
    gMySpectator.Highlight := nil;
  if gMySpectator.Selected = aGroup then
    gMySpectator.Selected := nil;
end;


procedure TKMHand.UpdateState(aTick: Cardinal);
begin
  if not Enabled then Exit;

  //Update Groups logic before Units
  fUnitGroups.UpdateState;

  inherited;

  fHouses.UpdateState(aTick);
  fFogOfWar.UpdateState; //We might optimize it for AI somehow, to make it work coarse and faster

  //Distribute AI updates among different Ticks to avoid slowdowns
  if (aTick + Byte(fID)) mod 10 = 0 then
  begin
    fBuildList.UpdateState;
    fDeliveries.UpdateState(aTick);
  end;

  //AI update takes care of it's own interleaving, so run it every tick
  fAI.UpdateState(aTick);

  //if (aTick + Byte(fPlayerIndex)) mod 20 = 0 then
    //fArmyEval.UpdateState;

  if CanDoStatsUpdate(aTick) then
    fStats.UpdateState;
end;


function TKMHand.CanDoStatsUpdate(aTick: Cardinal): Boolean;
begin
  Result := (aTick mod GetStatsUpdatePeriod = 0) or (aTick = 1);
end;


procedure TKMHand.Paint(const aRect: TKMRect);
begin
  if not Enabled then Exit;

  inherited;

  if not gGame.IsMapEditor or (mlUnits in gGame.MapEditor.VisibleLayers) then
    fUnitGroups.Paint(aRect);

  if not gGame.IsMapEditor or (mlHouses in gGame.MapEditor.VisibleLayers) then
    fHouses.Paint(aRect);

  if not SKIP_RENDER AND OVERLAY_DEFENCES AND not fAI.Setup.NewAI then
    fAI.General.DefencePositions.Paint;

  if not SKIP_RENDER AND fAI.Setup.NewAI then
  begin
    if OVERLAY_AI_BUILD then
    begin
      fAI.CityManagement.Builder.Paint();
      fAI.CityManagement.Builder.Planner.Paint();
    end;
    if OVERLAY_AI_COMBAT then
    begin
      fAI.ArmyManagement.Paint();
      fAI.ArmyManagement.Attack.Paint();
      fAI.ArmyManagement.Defence.Paint();
    end;
  end;
end;


{ TKMHandAnimals }
function TKMHandAnimals.GetFishInWaterBody(aWaterID: Byte; FindHighestCount: Boolean=True): TKMUnitAnimal;
var
  I, HighestGroupCount: Integer;
  U: TKMUnit;
begin
  Result := nil;
  if aWaterID = 0 then Exit; //Fish should always be in valid water
  HighestGroupCount := 0;

  for I := 0 to fUnits.Count - 1 do
  begin
    U := fUnits[I]; //Store locally

    if (U <> nil)
    and (U.UnitType = utFish)
    and (not U.IsDeadOrDying) //Fish are killed when they are caught or become stuck
    and (gTerrain.Land[U.CurrPosition.Y, U.CurrPosition.X].WalkConnect[wcFish] = aWaterID)
    and (TKMUnitAnimal(U).FishCount > HighestGroupCount) then
    begin
      Result := TKMUnitAnimal(U);
      //This is for time saving when we don't actually care which group is returned
      if not FindHighestCount then Exit;
      HighestGroupCount := Result.FishCount;
    end;
  end;
end;


//-----------
function GetStatsUpdatePeriod: Integer;
begin
  Result := 1000;
  case gGame.MissionMode of
    mmNormal:  Result := CHARTS_SAMPLING_FOR_ECONOMY;
    mmTactic:  Result := CHARTS_SAMPLING_FOR_TACTICS;
  end;
end;


end.
