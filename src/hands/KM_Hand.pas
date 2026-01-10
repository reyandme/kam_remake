unit KM_Hand;
{$I KaM_Remake.inc}
interface
uses
  Generics.Collections,
  KM_AI,
  KM_Units, KM_UnitsCollection, KM_UnitGroup, KM_UnitWarrior,
  KM_Houses, KM_HouseCollection, KM_HouseInn,
  KM_HandLogistics, KM_HandLocks, KM_HandStats, KM_GameTypes,
  KM_FogOfWar, KM_HandConstructions, KM_MessageLog, KM_ResHouses,
  KM_CommonClasses, KM_CommonTypes, KM_Defaults, KM_Points,
  KM_HandEntity, KM_HandTypes, KM_CommonClassesExt,
  KM_ResTypes, KM_ResFonts;


type
  TKMChooseLoc = record
    Allowed, Placed: Boolean;
    Resources: array[WARE_MIN..WARE_MAX] of Word;
    Units: array[CITIZEN_MIN..CITIZEN_MAX] of Byte;
  end;

  // Hand manages its assets
  TKMHandCommon = class abstract
  private
    fID: TKMHandID; //Index of this hand in gHands
    fUnits: TKMUnitsCollection;
  public
    constructor Create(aHandIndex: TKMHandID);
    destructor Destroy; override;
    property ID: TKMHandID read fID;
    property Units: TKMUnitsCollection read fUnits;

    function AddUnit(aUnitType: TKMUnitType; const aLoc: TKMPoint): TKMUnit;
    function RemUnit(const Position: TKMPoint): Boolean; overload;
    function RemUnit(const Position: TKMPoint; out aUnitType: TKMUnitType): Boolean; overload;
    function UnitsHitTest(const aLoc: TKMPoint; const UT: TKMUnitType = utAny): TKMUnit; overload;
    function UnitsHitTest(X, Y: Integer; const UT: TKMUnitType = utAny): TKMUnit; overload;

    procedure Save(SaveStream: TKMemoryStream); virtual;
    procedure Load(LoadStream: TKMemoryStream); virtual;
    procedure SyncLoad; virtual;

    procedure UpdateState(aTick: Cardinal); virtual;
    procedure UpdateVisualState;
    procedure Paint(const aRect: TKMRect; aTickLag: Single); virtual;
  end;


  TKMHand = class(TKMHandCommon)
  private
    fAI: TKMHandAI;
    fEnabled: Boolean;
    fConstructions: TKMHandConstructions;
    fDeliveries: TKMHandLogistics;
    fFogOfWar: TKMFogOfWar; //Stores FOW info for current player, which includes
    fHouses: TKMHousesCollection;
    fLocks: TKMHandLocks;
    fRoadsList: TKMPointList; //Used only once to speedup mission loading, then freed
    fStats: TKMHandStats;
    fUnitGroups: TKMUnitGroups;
    fMessageLog: TKMMessageLog;

    fOwnerNickname: AnsiString; //Multiplayer owner nickname
    fHandType: TKMHandType;
    fCanBeHuman: Boolean;
    fCanBeAITypes: TKMAITypeSet;
    fFlagColor: Cardinal;
    fTeam: Integer;
    fTeamColor: Cardinal;
    fCenterScreen: TKMPoint;
    fChooseLocation: TKMChooseLoc;
    fAlliances: array [0 .. MAX_HANDS - 1] of TKMAllianceType;
    fShareFOW: array [0 .. MAX_HANDS - 1] of Boolean;
    fShareBeacons: array [0 .. MAX_HANDS - 1] of Boolean;

    // Overlays
    fOverlayText: UnicodeString; //Needed for replays. Not saved since it's translated
    fOverlayMarkup: AnsiString;
    fOverlayParams: TKMVarValueList;
    fOverlayTextSettings: TKMOverlayTextSettings;

    //House sketch fields, used to GetNextHouseWSameType
    fHSketch: TKMHouseSketchEdit;
    fFirstHSketch: TKMHouseSketchEdit;
    fFoundHSketch: TKMHouseSketchEdit;

    fOnAllianceChange: TKMEvent;

    function IsDisabled: Boolean;
    function GetColorIndex: Byte;

    function  GetAlliances(aIndex: Integer): TKMAllianceType; inline;
    procedure SetAlliances(aIndex: Integer; aValue: TKMAllianceType); inline;
    function  GetShareFOW(aIndex: Integer): Boolean;
    procedure SetShareFOW(aIndex: Integer; aValue: Boolean);
    function  GetShareBeacons(aIndex: Integer): Boolean;
    procedure SetShareBeacons(aIndex: Integer; aValue: Boolean);

    procedure EntityDestroyed(aEntity: TKMHandEntity);
    procedure GroupDied(aGroup: TKMUnitGroup);
    procedure HouseDestroyed(aHouse: TKMHouse; aFrom: TKMHandID);
    procedure UnitDied(aUnit: TKMUnit);

    procedure UnitTrained(aUnit: TKMUnit);
    procedure WarriorWalkedOut(aWarrior: TKMUnitWarrior);
    function LocHasNoAllyPlans(const aLoc: TKMPoint): Boolean;
    function GetGameFlagColor: Cardinal;
    function GetOwnerNicknameU: UnicodeString;
    procedure ChooseFirstStorehouse();

    function GetAI: TKMHandAI;
    procedure SetFlagColor(const Value: Cardinal);

    procedure SetOwnerNickname(const aName: AnsiString);
    function GetDeliveries: TKMHandLogistics;
    procedure SetHandType(const Value: TKMHandType);
    procedure SetEnabled(const Value: Boolean);
    function GetFlagTextColor: Cardinal;
  public

    InCinematic: Boolean;

    //Used for syncing hotkeys in multiplayer saves only. UI keeps local value to avoid GIP delays
    SelectionHotkeys: array[0..DYNAMIC_HOTKEYS_NUM-1] of Integer;

    constructor Create(aHandIndex: TKMHandID; aOnAllianceChange: TKMEvent);
    destructor Destroy; override;

    property AI: TKMHandAI read GetAI;
    property Constructions: TKMHandConstructions read fConstructions;
    property Deliveries: TKMHandLogistics read GetDeliveries;
    property Houses: TKMHousesCollection read fHouses;
    property Locks: TKMHandLocks read fLocks;
    property Stats: TKMHandStats read fStats;
    property FogOfWar: TKMFogOfWar read fFogOfWar;
    property UnitGroups: TKMUnitGroups read fUnitGroups;
    property MessageLog: TKMMessageLog read fMessageLog;

    property Enabled: Boolean read fEnabled write SetEnabled;
    property Disabled: Boolean read IsDisabled;

    procedure SetHandIndex(aNewIndex: TKMHandID);
    property OwnerNickname: AnsiString read fOwnerNickname write SetOwnerNickname; //MP owner nickname (empty in SP)
    property OwnerNicknameU: UnicodeString read GetOwnerNicknameU;
    function CalcOwnerName: UnicodeString; //Universal owner name
    function OwnerName(aNumberedAIs: Boolean = True; aLocalized: Boolean = True): UnicodeString; //Universal owner name
    function GetHandOwnerName(aIsHuman, aIsAdvAI: Boolean; aNumberedAIs: Boolean = True; aLocalized: Boolean = True): UnicodeString;
    function GetOwnerName: UnicodeString;
    function GetOwnerNameColored: AnsiString;
    function GetOwnerNameColoredU: UnicodeString;
    function HasAssets: Boolean;
    property HandType: TKMHandType read fHandType write SetHandType; //Is it Human or AI
    property CanBeHuman: Boolean read fCanBeHuman write fCanBeHuman;
    property CanBeAITypes: TKMAITypeSet read fCanBeAITypes;
    property FlagColor: Cardinal read fFlagColor write SetFlagColor;
    property FlagTextColor: Cardinal read GetFlagTextColor;
    property Team: Integer read fTeam write fTeam;
    property TeamColor: Cardinal read fTeamColor write fTeamColor;
    property GameFlagColor: Cardinal read GetGameFlagColor;
    property FlagColorIndex: Byte read GetColorIndex;
    property Alliances[aIndex: Integer]: TKMAllianceType read GetAlliances write SetAlliances;
    property ShareFOW[aIndex: Integer]: Boolean read GetShareFOW write SetShareFOW;
    property ShareBeacons[aIndex: Integer]: Boolean read GetShareBeacons write SetShareBeacons;
    property CenterScreen: TKMPoint read fCenterScreen write fCenterScreen;
    property ChooseLocation: TKMChooseLoc read fChooseLocation write fChooseLocation;

    property OverlayText: UnicodeString read fOverlayText write fOverlayText;
    property OverlayTextSettings: TKMOverlayTextSettings read fOverlayTextSettings;
    property OverlayMarkup: AnsiString read fOverlayMarkup write fOverlayMarkup;
    property OverlayParams: TKMVarValueList read fOverlayParams;
    procedure SetOverlayTextWordWrap(aWordWrap: Boolean);
    procedure SetOverlayTextFont(aFont: TKMFont);

    procedure AddAIType(aHandAIType: TKMAIType);

    procedure PostLoadMission;

    function IsAnimal: Boolean;
    function IsHuman: Boolean;
    function IsComputer: Boolean;
    function IsAdvancedAI: Boolean;
    function IsClassicAI: Boolean;

    function CanBeAI: Boolean;

    procedure AfterMissionInit(aFlattenRoads: Boolean);

    function AddUnit(aUnitType: TKMUnitType; const aLoc: TKMPoint; aAutoPlace: Boolean = True;
                     aRequiredWalkConnect: Byte = 0; aCheat: Boolean = False): TKMUnit; reintroduce; overload;
    function AddUnit(aUnitType: TKMUnitType; const aLoc: TKMPointDir; aAutoPlace: Boolean = True;
                     aRequiredWalkConnect: Byte = 0; aCheat: Boolean = False): TKMUnit; reintroduce; overload;
    function AddUnitGroup(aUnitType: TKMUnitType; const Position: TKMPoint; aDir: TKMDirection; aUnitPerRow, aCount: Word): TKMUnitGroup;

    function TrainUnit(aUnitType: TKMUnitType; aInHouse: TKMHouse): TKMUnit;

    function GetNextHouseWSameType(aHouseType: TKMHouseType; aStartFromUID: Integer): TKMHouse; overload;
    function GetNextHouseWSameType(aHouseType: TKMHouseType; aStartFromUID: Integer;
                                   out aHouseSketch: TKMHouseSketchEdit;
                                   aSketchTypesSet: TKMHouseSketchTypeSet = [hstHouse]): TKMHouse; overload;
    function GetNextHouseWSameType(aHouseType: TKMHouseType; aStartFromUID: Integer;
                                   out aHouseSketch: TKMHouseSketchEdit;
                                   aSketchTypesSet: TKMHouseSketchTypeSet;
                                   aVerifySketch: TAnonHouseSketchBoolFn;
                                   aVerifySketchBoolParam: Boolean): TKMHouse; overload;
    function GetNextUnitWSameType(aUnitType: TKMUnitType; aStartFromUID: Integer): TKMUnit;
    function GetNextGroupWSameType(aUnitType: TKMUnitType; aStartFromUID: Integer): TKMUnitGroup;

    function CanAddFieldPlan(const aLoc: TKMPoint; aFieldType: TKMFieldType): Boolean;
    function CanAddFakeFieldPlan(const aLoc: TKMPoint; aFieldType: TKMFieldType): Boolean;
    function CanRemFakeFieldPlan(const aLoc: TKMPoint; aFieldType: TKMFieldType): Boolean;
    function CanAddHousePlan(const aLoc: TKMPoint; aHouseType: TKMHouseType): Boolean;
    function CanAddHousePlanAI(aX, aY: Word; aHouseType: TKMHouseType; aCheckInfluence: Boolean): Boolean;

    procedure AddFirstStorehouse(aEntrance: TKMPoint);
    procedure ResetChooseLocation;
    function NeedToChooseFirstStorehouse: Boolean;
    function NeedToChooseFirstStorehouseInGame: Boolean;
    procedure AddRoadToList(const aLoc: TKMPoint);
    procedure AddRoad(const aLoc: TKMPoint);
    procedure AddField(const aLoc: TKMPoint; aFieldType: TKMFieldType; aStage: Byte = 0; aKeepOldObject: Boolean = False;
                       aRemoveOverlay: Boolean = True);
    procedure ToggleFieldPlan(const aLoc: TKMPoint; aFieldType: TKMFieldType; aMakeSound: Boolean);
    procedure ToggleFakeFieldPlan(const aLoc: TKMPoint; aFieldType: TKMFieldType);
    function AddHouse(aHouseType: TKMHouseType; PosX, PosY: Word; RelativeEntrace: Boolean): TKMHouse;
    procedure AddHousePlan(aHouseType: TKMHouseType; const aLoc: TKMPoint);
    function HasHousePlan(const aLoc: TKMPoint): Boolean;
    function AddHouseWIP(aHouseType: TKMHouseType; const aLoc: TKMPoint): TKMHouse;
    function RemGroup(const Position: TKMPoint): Boolean;
    procedure RemHouse(const Position: TKMPoint; DoSilent: Boolean; IsEditor: Boolean = False);
    procedure RemHousePlan(const Position: TKMPoint);
    procedure RemFieldPlan(const Position: TKMPoint; aMakeSound:Boolean);
    procedure RemFakeFieldPlan(const Position: TKMPoint);
    function FindInn(Loc: TKMPoint; aUnit: TKMUnit; UnitIsAtHome: Boolean = False): TKMHouseInn;
    function FindHouse(aType: TKMHouseType; const aPosition: TKMPoint; Index: Byte = 1): TKMHouse; overload;
    function FindHouse(aType: TKMHouseType; Index: Byte=1): TKMHouse; overload;
    function FindHousesInRadius(const aLoc: TKMPoint; aSqrRadius: Single; aTypes: TKMHouseTypeSet = HOUSES_VALID; aOnlyCompleted: Boolean = True): TKMHouseArray;
    function FindCityCenter: TKMPoint;
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
    function DoCheckGoals: Boolean;

    procedure Save(SaveStream: TKMemoryStream); override;
    procedure Load(LoadStream: TKMemoryStream); override;
    procedure SyncLoad; override;
    procedure IncAnimStep;
    procedure UpdateState(aTick: Cardinal); override;
    procedure Paint(const aRect: TKMRect; aTickLag: Single); override;
    function ObjToString(aSeparator: string = ' '): string;
  end;


  TKMHandAnimals = class(TKMHandCommon)
  public
    function GetFishInWaterBody(aWaterID: Byte; FindHighestCount: Boolean = True): TKMUnitFish;
  end;

function GetStatsUpdatePeriod: Integer;


implementation
uses
  Classes, SysUtils, KromUtils, Math, TypInfo,
  KM_Entity,
  KM_Cursor, KM_Game, KM_GameParams, KM_Terrain,
  KM_HandsCollection, KM_Sound, KM_AIFields, KM_MapEdTypes,
  KM_Resource, KM_ResSound, KM_ResTexts, KM_ResMapElements, KM_ScriptingEvents, KM_ResUnits,
  KM_CommonUtils, KM_GameSettings,
  KM_UnitGroupTypes,
  KM_MapTypes;

const
  TIME_TO_SET_FIRST_STOREHOUSE = 10*60*2; //We give 2 minutes to set first storehouse, otherwise player will be defeated


{ TKMHandCommon }
constructor TKMHandCommon.Create(aHandIndex: TKMHandID);
begin
  inherited Create;

  fID := aHandIndex;
  fUnits := TKMUnitsCollection.Create;
end;


destructor TKMHandCommon.Destroy;
begin
  FreeThenNil(fUnits);

  inherited;
end;


function TKMHandCommon.AddUnit(aUnitType: TKMUnitType; const aLoc: TKMPoint): TKMUnit;
begin
  //Animals are autoplaced by default
  Result := fUnits.AddUnit(fID, aUnitType, KMPointDir(aLoc, dirS), True);
end;


procedure TKMHandCommon.Paint(const aRect: TKMRect; aTickLag: Single);
begin
  if mlUnits in gGameParams.VisibleLayers then
    fUnits.Paint(aRect, aTickLag);
end;


function TKMHandCommon.RemUnit(const Position: TKMPoint): Boolean;
var
  UnitType: TKMUnitType;
begin
  Result := RemUnit(Position, UnitType);
end;


function TKMHandCommon.RemUnit(const Position: TKMPoint; out aUnitType: TKMUnitType): Boolean;
var
  U: TKMUnit;
begin
  Assert(gGameParams.IsMapEditor);

  U := fUnits.HitTest(Position.X, Position.Y);

  Result := U <> nil;

  if Result then
  begin
    aUnitType := U.UnitType;
    fUnits.RemoveUnit(U);
  end;
end;


procedure TKMHandCommon.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.PlaceMarker('HandCommon');
  fUnits.Save(SaveStream);
end;


procedure TKMHandCommon.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.CheckMarker('HandCommon');
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
  fUnits.UpdateState(aTick);
end;


procedure TKMHandCommon.UpdateVisualState;
begin
  Assert(gGameParams.IsMapEditor);

  fUnits.UpdateVisualState;
end;


{ TKMHand }
constructor TKMHand.Create(aHandIndex: TKMHandID; aOnAllianceChange: TKMEvent);
var
  I: Integer;
begin
  inherited Create(aHandIndex);

  Enabled := True;

  fOnAllianceChange := aOnAllianceChange;

  fAI           := TKMHandAI.Create(fID);
  fFogOfWar     := TKMFogOfWar.Create(gTerrain.MapX, gTerrain.MapY, gGameParams.DynamicFOW);
  fLocks        := TKMHandLocks.Create;
  fStats        := TKMHandStats.Create;
  fRoadsList    := TKMPointList.Create;
  fHouses       := TKMHousesCollection.Create;
  fDeliveries   := TKMHandLogistics.Create(fID);
  fConstructions:= TKMHandConstructions.Create;
  fUnitGroups   := TKMUnitGroups.Create;
  fMessageLog   := TKMMessageLog.Create;

  fOwnerNickname := '';
  fHandType     := hndComputer;
  fCanBeHuman   := False;
  fCanBeAITypes  := [];
  for I := 0 to MAX_HANDS - 1 do
  begin
    fShareFOW[I] := True; //Share FOW between allies by default (it only affects allied players)
    fShareBeacons[I] := True; //Share beacons between allies by default (it only affects allied players)
  end;
  for I := 0 to 9 do
    SelectionHotkeys[I] := -1; //Not set

  fAlliances[fID] := atAlly; //Others are set to enemy by default
  fFlagColor := DEFAULT_PLAYERS_COLORS[fID]; //Init with default color, later replaced by Script
  fTeamColor := fFlagColor;
  fTeam := NO_TEAM;

  fOverlayParams := TKMVarValueList.Create;
  fOverlayTextSettings.WordWrap := False;
  fOverlayTextSettings.Font := fntMetal;

  fHSketch := TKMHouseSketchEdit.Create;
  fFirstHSketch := TKMHouseSketchEdit.Create;
  fFoundHSketch := TKMHouseSketchEdit.Create;

  ResetChooseLocation;
end;


//Destruction order is important as Houses and Units need to access
//Stats/Deliveries and other collection in their Destroy/Abandon/Demolish methods
destructor TKMHand.Destroy;
begin
  FreeAndNil(fHSketch);
  FreeAndNil(fFirstHSketch);
  FreeAndNil(fFoundHSketch);

  FreeAndNil(fOverlayParams);

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
  FreeThenNil(fConstructions);
  FreeThenNil(fAI);
end;


procedure TKMHand.ResetChooseLocation;
begin
  if Self = nil then Exit;
  
  fChooseLocation.Allowed := False;
  fChooseLocation.Placed := False;
end;


function TKMHand.AddUnit(aUnitType: TKMUnitType; const aLoc: TKMPoint; aAutoPlace: Boolean = True;
                         aRequiredWalkConnect: Byte = 0; aCheat: Boolean = False): TKMUnit;
begin
  Result := AddUnit(aUnitType,  KMPointDir(aLoc, dirS), aAutoPlace, aRequiredWalkConnect, aCheat);
end;


//Place unit of aUnitType to aLoc via script
//AutoPlace - add unit to nearest available spot if aLoc is already taken (or unwalkable)
function TKMHand.AddUnit(aUnitType: TKMUnitType; const aLoc: TKMPointDir; aAutoPlace: Boolean = True;
                         aRequiredWalkConnect: Byte = 0; aCheat: Boolean = False): TKMUnit;
var
  G: TKMUnitGroup;
begin
  Result := fUnits.AddUnit(fID, aUnitType, aLoc, aAutoPlace, aRequiredWalkConnect);

  //Unit failed to add, that happens
  if Result = nil then Exit;

  if gGameParams.IsMapEditor then
    Exit;

  Result.OnUnitDied := UnitDied;
  Result.OnUnitTrained := UnitTrained; //Used for debug Scout placed by a cheat

  if Result is TKMUnitWarrior then
    TKMUnitWarrior(Result).OnWarriorWalkOut := WarriorWalkedOut;

  if Result is TKMUnitWorker then
    fConstructions.AddWorker(TKMUnitWorker(Result));
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
function TKMHand.TrainUnit(aUnitType: TKMUnitType; aInHouse: TKMHouse): TKMUnit;
begin
  Assert(aInHouse <> nil, 'House to train unit in could not be nil');
  // Add unit and specify that its made inside house (so there is no need to occupy terrain tile)
  Result := fUnits.AddUnit(fID, aUnitType, KMPointDir(aInHouse.Entrance, dirS), False, 0, aInHouse);
  Result.OnUnitDied := UnitDied;
  Result.OnUnitTrained := UnitTrained;

  if Result is TKMUnitWarrior then
    TKMUnitWarrior(Result).OnWarriorWalkOut := WarriorWalkedOut;

  //Do not add unit to statistic just yet, wait till it's training complete
end;


procedure TKMHand.UnitTrained(aUnit: TKMUnit);
begin
  if aUnit.UnitType = utBuilder then
    fConstructions.AddWorker(TKMUnitWorker(aUnit));
  if aUnit.UnitType = utSerf then
    fDeliveries.AddSerf(TKMUnitSerf(aUnit));

  //Warriors don't trigger "OnTrained" event, they trigger "WarriorEquipped" in WarriorWalkedOut below
  if not (aUnit is TKMUnitWarrior) then
    gScriptEvents.ProcUnitTrained(aUnit);

  fStats.UnitCreated(aUnit.UnitType, True{, (aUnit.InHouse <> nil) and (aUnit.InHouse.HouseType = htTownHall)});
end;


procedure TKMHand.WarriorWalkedOut(aWarrior: TKMUnitWarrior);
var
  G: TKMUnitGroup;
  H: TKMHouse;
  HWFP: TKMHouseWFlagPoint;
begin
  // Warrior could be killed before he walked out, f.e. by script OnTick ---> Actions.UnitKill
  // Then group will be assigned to invalid warrior and never gets removed from game
  if (aWarrior = nil) or aWarrior.IsDeadOrDying then
    Exit;

  G := fUnitGroups.WarriorTrained(aWarrior);
  Assert(G <> nil, 'It is certain that equipped warrior creates or finds some group to join to');
  G.OnGroupDied := GroupDied;
  if IsComputer then
  begin
    if AI.Setup.NewAI then
      AI.ArmyManagement.WarriorEquipped(G)
    else
      AI.General.WarriorEquipped(aWarrior);
    G := UnitGroups.GetGroupByMember(aWarrior); //AI might assign warrior to different group
  end
  else
    if G.Count = 1 then
    begin
      //If player is human and this is the first warrior in the group, send it to the rally point
      H := HousesHitTest(aWarrior.Position.X, aWarrior.Position.Y-1);
      if (H is TKMHouseWFlagPoint) then
      begin
        HWFP := TKMHouseWFlagPoint(H);
        HWFP.ValidateFlagPoint; // Validate Flag point first. It will set it to a proper walkable position
        if HWFP.IsFlagPointSet
        and G.CanWalkTo(HWFP.FlagPoint, 0) then
          G.OrderWalk(HWFP.FlagPoint, True, wtokFlagPoint);
      end;
    end;
  gScriptEvents.ProcWarriorEquipped(aWarrior, G);
end;


function TKMHand.AddUnitGroup(aUnitType: TKMUnitType; const Position: TKMPoint; aDir: TKMDirection; aUnitPerRow, aCount: Word): TKMUnitGroup;
var
  I: Integer;
begin
  Assert(aDir <> dirNA);
  Result := nil;

  if aUnitType in [CITIZEN_MIN..CITIZEN_MAX] then
    for I := 0 to aCount - 1 do
      AddUnit(aUnitType, Position)
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


function TKMHand.IsAnimal: Boolean;
begin
  Result := fID = HAND_ANIMAL;
end;


function TKMHand.IsComputer: Boolean;
begin
  Result := fHandType = hndComputer;
end;


function TKMHand.IsAdvancedAI: Boolean;
begin
  Result := IsComputer and fAI.Setup.NewAI;
end;


function TKMHand.IsClassicAI: Boolean;
begin
  Result := IsComputer and not fAI.Setup.NewAI;
end;


function TKMHand.CanBeAI: Boolean;
begin
  Result := (fCanBeAITypes <> []) and (fCanBeAITypes <> [aitNone]);
end;


//Lay out all roads at once to save time on Terrain lighting/passability recalculations
procedure TKMHand.AfterMissionInit(aFlattenRoads: Boolean);
begin
  if (Self = nil) or not Enabled then Exit;

  Assert(fRoadsList <> nil);

  gTerrain.SetRoads(fRoadsList, fID, not aFlattenRoads); //If we are flattening roads that will update WalkConnect anyway
  if aFlattenRoads then
    gTerrain.FlattenTerrain(fRoadsList);

  if not gGameParams.IsMapEditor then
    fAI.AfterMissionInit(fCanBeAITypes);
end;


function TKMHand.GetNextHouseWSameType(aHouseType: TKMHouseType; aStartFromUID: Integer): TKMHouse;
begin
  Result := GetNextHouseWSameType(aHouseType, aStartFromUID, TKMHouseSketchEdit.DummyHouseSketch);
end;


function TKMHand.GetNextHouseWSameType(aHouseType: TKMHouseType; aStartFromUID: Integer;
                                       out aHouseSketch: TKMHouseSketchEdit;
                                       aSketchTypesSet: TKMHouseSketchTypeSet = [hstHouse]): TKMHouse;
begin
  Result := GetNextHouseWSameType(aHouseType, aStartFromUID, aHouseSketch, aSketchTypesSet, nil, False);
end;


function TKMHand.GetNextHouseWSameType(aHouseType: TKMHouseType; aStartFromUID: Integer;
                                       out aHouseSketch: TKMHouseSketchEdit;
                                       aSketchTypesSet: TKMHouseSketchTypeSet;
                                       aVerifySketch: TAnonHouseSketchBoolFn;
                                       aVerifySketchBoolParam: Boolean): TKMHouse;

var
  resultSet: Boolean;

  procedure FillHSketchByHouse(out aHouseSketchTmp: TKMHouseSketchEdit; aHouse: TKMHouse);
  begin
    if not aHouse.IsDestroyed // not destroyed
      and (aHouse.HouseType = aHouseType)
      {and (not aConsiderHousePlan or aHouse.IsComplete)} then
    begin
      aHouseSketchTmp.Owner := fID;
      aHouseSketchTmp.SetHouseUID(aHouse.UID);
      aHouseSketchTmp.SetHouseType(aHouse.HouseType);
      aHouseSketchTmp.SetPosition(aHouse.Position);
    end;
  end;

  procedure FillHSketchByHPlan(out aHouseSketchTmp: TKMHouseSketchEdit; aHousePlan: TKMHousePlan);
  begin
    if not aHousePlan.IsEmpty
      and (aHousePlan.HouseType = aHouseType) then
    begin
      aHouseSketchTmp.Owner := fID;
      aHouseSketchTmp.SetHouseUID(aHousePlan.UID);
      aHouseSketchTmp.SetHouseType(aHousePlan.HouseType);
      aHouseSketchTmp.SetPosition(aHousePlan.Loc);
    end;
  end;

  function GetNextHSketch(aIndex: Integer; out aHouseSketchTmp: TKMHouseSketchEdit): Boolean;
  var
    sketch2Verify: TKMHouseSketch;
  begin
    aHouseSketchTmp.Clear;

    sketch2Verify := nil;

    if (hstHouse in aSketchTypesSet) and (aIndex < fHouses.Count) then
    begin
      FillHSketchByHouse(aHouseSketchTmp, fHouses[aIndex]);
      sketch2Verify := fHouses[aIndex];
    end else if (hstHousePlan in aSketchTypesSet) then
    begin
      FillHSketchByHPlan(aHouseSketchTmp, fConstructions.HousePlanList.Plans[aIndex - Byte(hstHouse in aSketchTypesSet)*fHouses.Count]);
      sketch2Verify := aHouseSketchTmp;
    end;

    Result := not aHouseSketchTmp.IsEmpty
              and (not Assigned(aVerifySketch) or aVerifySketch(sketch2Verify, aVerifySketchBoolParam));
  end;

  procedure FillResult(aIndex: Integer; aHSketch: TKMHouseSketchEdit);
  begin
    resultSet := True;
    if aHouseSketch <> nil then
      aHSketch.CopyTo(aHouseSketch);
    if aIndex < fHouses.Count then
      Result := fHouses[aIndex];
  end;

var
  found: Boolean; //Flag when we find house sketch (House or HousePlan) with specified Starting UID
  I, firstHSketchI, foundSketchI, cnt: Integer;
begin
  Result := nil;
  aHouseSketch.Clear;

  found := False;
  resultSet := False;

  cnt :=   Byte(hstHouse in aSketchTypesSet)*fHouses.Count
         + Byte(hstHousePlan in aSketchTypesSet)*fConstructions.HousePlanList.Count;

  I := 0;
  firstHSketchI := 0;
  foundSketchI := 0;

  fHSketch.Clear;
  fFirstHSketch.Clear;
  fFoundHSketch.Clear;

  while I < cnt do
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
        found := True; // Mark that we found our house
        fHSketch.CopyTo(fFoundHSketch);
        foundSketchI := I;
      end
      else if found then
      begin
        FillResult(I, fHSketch); // Save the next house after Found to Result and Break
        Break;
      end else if fFirstHSketch.IsEmpty then
      begin
        fHSketch.CopyTo(fFirstHSketch); // Save 1st house in list in case our house is the last one
        firstHSketchI := I;
      end;
    finally
      Inc(I);
    end;
  end;

  if not resultSet then // Found should be always True here
  begin
    if found then
    begin
      if fFirstHSketch.IsEmpty then
        FillResult(foundSketchI, fFoundHSketch)   //Could happen, when we have only 1 house with that type...
      else
        FillResult(firstHSketchI, fFirstHSketch);
    end else if not fFirstHSketch.IsEmpty then
      FillResult(firstHSketchI, fFirstHSketch);
  end;
end;


function TKMHand.GetNextUnitWSameType(aUnitType: TKMUnitType; aStartFromUID: Integer): TKMUnit;
var
  I: Integer;
  U, firstU, lastU: TKMUnit;
  found: Boolean;
begin
  Result := nil;

  found := False;
  firstU := nil;
  lastU := nil;

  for I := 0 to fUnits.Count - 1 do
  begin
    U := fUnits[I];
    if (U = nil)
    or U.IsDeadOrDying
    or (U.UnitType <> aUnitType)
    or not U.Visible then
      Continue;

    // Just find any first unit
    if (aStartFromUID = 0) then
      Exit(U);

    lastU := U;

    if U.UID = aStartFromUID then
      found := True               // Mark that we found our unit
    else if found then
      Exit(U)                     // Save the next unit after Found to Result and Break
    else
    if firstU = nil then
      firstU := U;                // Save 1st unit in list in case our unit is the last one
  end;

  if found then          // Found should be always True here
  begin
    if firstU = nil then //Could happen, when we have only 1 unit with that type...
      Result := lastU
    else
      Result := firstU;
  end;
end;


function TKMHand.GetNextGroupWSameType(aUnitType: TKMUnitType; aStartFromUID: Integer): TKMUnitGroup;
var
  I: Integer;
  group, firstG, lastG: TKMUnitGroup;
  found: Boolean;
begin
  Result := nil;

  found := False;
  firstG := nil;
  lastG := nil;

  for I := 0 to UnitGroups.Count - 1 do
  begin
    group := UnitGroups[I];

    if (group = nil)
      or group.IsDead //check if group is dead
      or not group.HasUnitType(aUnitType) then // we are interested in groups with the same type only
      Continue;

    //Just find any first house
    if (aStartFromUID = 0) then
    begin
      Result := group;
      Break;
    end;

    lastG := group;

    if group.UID = aStartFromUID then
      found := True               // Mark that we found our group
    else if found then
    begin
      Result := group;            // Save the next group after Found to Result and Break
      Break;
    end else if firstG = nil then
      firstG := group;            // Save 1st group in list in case our group is the last one
  end;
  if (Result = nil) and found then // Found should be always True here
  begin
    if firstG = nil then  //Could happen, when we have only 1 group with that type...
      Result := lastG
    else
      Result := firstG;
  end;
end;


procedure TKMHand.SetHandIndex(aNewIndex: TKMHandID);
begin
  fID := aNewIndex;
  fUnits.OwnerUpdate(aNewIndex);
  fHouses.OwnerUpdate(aNewIndex);
  fAI.OwnerUpdate(aNewIndex);
end;


procedure TKMHand.SetHandType(const Value: TKMHandType);
begin
  fHandType := Value;
end;


procedure TKMHand.SetOverlayTextFont(aFont: TKMFont);
begin
  fOverlayTextSettings.Font := aFont;
end;


procedure TKMHand.SetOverlayTextWordWrap(aWordWrap: Boolean);
begin
  fOverlayTextSettings.WordWrap := aWordWrap;
end;


procedure TKMHand.SetOwnerNickname(const aName: AnsiString); //MP owner nickname (empty in SP)
begin
  fOwnerNickname := aName;
end;


procedure TKMHand.AddRoad(const aLoc: TKMPoint);
begin
  gTerrain.SetRoad(aLoc, fID);
end;


procedure TKMHand.AddField(const aLoc: TKMPoint; aFieldType: TKMFieldType; aStage: Byte = 0;
                           aKeepOldObject: Boolean = False; aRemoveOverlay: Boolean = True);
var
  isFieldSet: Boolean;
  obj: Word;
begin
  isFieldSet := False;
  obj := gTerrain.Land^[aLoc.Y,aLoc.X].Obj;
  //If we have corn/wine object on that tile, set appropriate field/wine stage
  if (aFieldType = ftCorn) and not gTerrain.TileIsCornField(aLoc) then
  begin
    if ObjectIsCorn(obj) then
    begin
      gTerrain.SetField(aLoc, fID, aFieldType, obj - 54, True, aKeepOldObject, aRemoveOverlay);
      isFieldSet := True;
    end;
  end else if (aFieldType = ftWine) and not gTerrain.TileIsWineField(aLoc) then
  begin
    if ObjectIsWine(obj) then
    begin
      gTerrain.SetField(aLoc, fID, aFieldType, obj - 54, True, aKeepOldObject, aRemoveOverlay);
      isFieldSet := True;
    end;
  end;

  if not isFieldSet then
    gTerrain.SetField(aLoc, fID, aFieldType, aStage, True, aKeepOldObject, aRemoveOverlay);
end;


function TKMHand.LocHasNoAllyPlans(const aLoc: TKMPoint): Boolean;
var
  I: Integer;
begin
  Result := True;
  //Don't allow placing on allies plans either
  for I := 0 to gHands.Count - 1 do
    if (I <> fID) and (fAlliances[I] = atAlly) then
      Result := Result and (gHands[I].fConstructions.FieldworksList.HasField(aLoc) = ftNone)
                       and not gHands[I].fConstructions.HousePlanList.HasPlan(aLoc);
end;


function TKMHand.GetGameFlagColor: Cardinal;
begin
  Result := fFlagColor;
  if gGame = nil then Exit;

  case gGameSettings.PlayersColorMode of
    pcmAllyEnemy: begin
                    if ID = gMySpectator.HandID then
                      Result := gGameSettings.PlayerColorSelf
                    else if (Alliances[gMySpectator.HandID] = atAlly) then
                      Result := gGameSettings.PlayerColorAlly
                    else
                      Result := gGameSettings.PlayerColorEnemy;
                  end;
    pcmTeams:     Result := fTeamColor;
  end;
end;


function TKMHand.GetOwnerNicknameU: UnicodeString;
begin
  Result := UnicodeString(fOwnerNickname);
end;


function TKMHand.IsDisabled: Boolean;
begin
  Result := not Enabled;
end;


//See comment on CanAddFakeFieldPlan
function TKMHand.CanAddFieldPlan(const aLoc: TKMPoint; aFieldType: TKMFieldType): Boolean;
begin
  Result := gTerrain.CanAddField(aLoc.X, aLoc.Y, aFieldType)
            and (fConstructions.FieldworksList.HasField(aLoc) = ftNone)
            and not fConstructions.HousePlanList.HasPlan(aLoc)
            and LocHasNoAllyPlans(aLoc);
end;


//This differs from above only in that it uses HasFakeField instead of HasField.
//We need it because the user expects to be blocked by fake field plans, but the gameplay should not.
//When the result effects the outcome of the game, the above function should be used instead.
function TKMHand.CanAddFakeFieldPlan(const aLoc: TKMPoint; aFieldType: TKMFieldType): Boolean;
begin
  Result := gTerrain.CanAddField(aLoc.X, aLoc.Y, aFieldType)
            and (fConstructions.FieldworksList.HasFakeField(aLoc) = ftNone)
            and not fConstructions.HousePlanList.HasPlan(aLoc)
            and LocHasNoAllyPlans(aLoc);
end;


// Same as for CanAddFakeFieldPlan, but check can we delete plan
function TKMHand.CanRemFakeFieldPlan(const aLoc: TKMPoint; aFieldType: TKMFieldType): Boolean;
begin
  Result := (fConstructions.FieldworksList.HasFakeField(aLoc) = aFieldType)
            and LocHasNoAllyPlans(aLoc);
end;


function TKMHand.CanAddHousePlan(const aLoc: TKMPoint; aHouseType: TKMHouseType): Boolean;
var
  I, K, J, S, T, Tx, Ty: Integer;
  HA: TKMHouseArea;
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
                     and (IsComputer
                      or (NeedToChooseFirstStorehouseInGame and fFogOfWar.CheckTileInitialRevelation(Tx, Ty)) //Use initial revelation for first storehouse
                      or (not NeedToChooseFirstStorehouseInGame and (fFogOfWar.CheckTileRevelation(Tx, Ty) > 0)));
    //This checks below require Tx;Ty to be within the map so exit immediately if they are not
    if not Result then Exit;

    //This tile must not contain fields/houses of allied players or self
    for J := 0 to gHands.Count - 1 do
      if fAlliances[J] = atAlly then
      begin
        Result := Result and (gHands[J].fConstructions.FieldworksList.HasField(KMPoint(Tx,Ty)) = ftNone);
        //Surrounding tiles must not be a house
        for S := -1 to 1 do
          for T := -1 to 1 do
            Result := Result and not gHands[J].fConstructions.HousePlanList.HasPlan(KMPoint(Tx+S,Ty+T));
      end;
  end;
end;


function TKMHand.CanAddHousePlanAI(aX, aY: Word; aHouseType: TKMHouseType; aCheckInfluence: Boolean): Boolean;
var
  I, K, J, S, T, Tx, Ty: Integer;
  HA: TKMHouseArea;
  enterOff: ShortInt;
  terOwner: TKMHandID;
begin
  Result := False;

  //Check if we can place house on terrain, this also makes sure the house is
  //at least 1 tile away from map border (skip that below)
  if not gTerrain.CanPlaceHouse(KMPoint(aX, aY), aHouseType) then
    Exit;

  //Perform additional cheks for AI
  HA := gRes.Houses[aHouseType].BuildArea;
  enterOff := gRes.Houses[aHouseType].EntranceOffsetX;
  for I := 1 to 4 do
  for K := 1 to 4 do
  if HA[I,K] <> 0 then
  begin
    Tx := aX + K - 3 - enterOff;
    Ty := aY + I - 4;

    //Make sure we don't block existing roads
    if gTerrain.CheckPassability(KMPoint(Tx, Ty), tpWalkRoad) then
      Exit;

    //Check with influence maps
    if aCheckInfluence and FEAT_AI_GENERATE_INFLUENCE then
    begin
      //Check if tile's blocked
      if (gAIFields.Influences.AvoidBuilding[Ty, Tx] > 0) then
        Exit;

      //Check ownership for entrance (good enough since it does not changes that fast)
      if (HA[I,K] = 2) then
      begin
        terOwner := gAIFields.Influences.GetBestOwner(Tx,Ty);
        if ((terOwner <> fID) and (terOwner <> HAND_NONE)) then
          Exit;
      end;
    end;

    //Avoid placing houses in choke-points _/house\_ by checking upper corners
    if not (aHouseType in [htGoldMine, htIronMine]) then
      if (gTerrain.Land^[Ty-1, Tx - 1].Passability * [tpMakeRoads, tpWalkRoad] = [])
      or (gTerrain.Land^[Ty-1, Tx + 1].Passability * [tpMakeRoads, tpWalkRoad] = [])
      then
        Exit;

    //Make sure we can add road below house, full width + 1 on each side
    //Terrain already checked we are 1 tile away from map edge
    if (I = 4) and not (aHouseType in [htGoldMine, htIronMine]) then
      if (gTerrain.Land^[Ty+1, Tx - 1].Passability * [tpMakeRoads, tpWalkRoad] = [])
      or (gTerrain.Land^[Ty+1, Tx    ].Passability * [tpMakeRoads, tpWalkRoad] = [])
      or (gTerrain.Land^[Ty+1, Tx + 1].Passability * [tpMakeRoads, tpWalkRoad] = [])
      then
        Exit;

    //This tile must not contain fields/houseplans of allied players or self
    for J := 0 to gHands.Count - 1 do
      if fAlliances[J] = atAlly then
      begin
        if (gHands[J].fConstructions.FieldworksList.HasField(KMPoint(Tx,Ty)) <> ftNone) then
          Exit;

        //Surrounding tiles must not be a house
        for S := -1 to 1 do
        for T := -1 to 1 do
        if gHands[J].fConstructions.HousePlanList.HasPlan(KMPoint(Tx+S,Ty+T)) then
          Exit;
      end;
  end;

  Result := True;
end;


//Due to lag there could be already plans placed by user in previous ticks
//Check if Plan can be placed once again, as we might have conflicting commands caused by lag
//This is called by GIP when a place field command is processed
procedure TKMHand.ToggleFieldPlan(const aLoc: TKMPoint; aFieldType: TKMFieldType; aMakeSound: Boolean);
var
  plan: TKMFieldType;
begin
  Assert(aFieldType in [ftRoad, ftCorn, ftWine], 'Placing wrong FieldType');

  plan := fConstructions.FieldworksList.HasField(aLoc);
  if aFieldType = plan then //Same plan - remove it
    RemFieldPlan(aLoc,aMakeSound)
  else
    if CanAddFieldPlan(aLoc, aFieldType) then
    begin
      if aMakeSound and not gGameParams.IsReplayOrSpectate
        and (ID = gMySpectator.HandID) then
        gSoundPlayer.Play(sfxPlaceMarker);
      fConstructions.FieldworksList.AddField(aLoc, aFieldType);
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
      if aMakeSound and not gGameParams.IsReplayOrSpectate
        and (ID = gMySpectator.HandID) then
        gSoundPlayer.Play(sfxCantPlace, 4);
      if plan = ftNone then //If we can't build because there's some other plan, that's ok
      begin
        //Can't build here anymore because something changed between click and command processing, so remove any fake plans
        fConstructions.FieldworksList.RemFakeField(aLoc);
        fConstructions.FieldworksList.RemFakeDeletedField(aLoc);
      end;
    end;
end;


//This procedure does not effect gameplay, it only changes fake field plans to make it look better for the user
//It is called when the user clicks to place a field plan
procedure TKMHand.ToggleFakeFieldPlan(const aLoc: TKMPoint; aFieldType: TKMFieldType);
var
  plan: TKMFieldType;
begin
  Assert(aFieldType in [ftRoad, ftCorn, ftWine], 'Placing wrong fake FieldType');

  plan := fConstructions.FieldworksList.HasFakeField(aLoc);
  if aFieldType = plan then //Same plan - remove it
  begin
    fConstructions.FieldworksList.RemFakeField(aLoc); //Remove our fake marker which is shown to the user
    fConstructions.FieldworksList.AddFakeDeletedField(aLoc); //This will hide the real field until it is deleted from game
    if ID = gMySpectator.HandID then gSoundPlayer.Play(sfxClick);
  end
  else
    if CanAddFakeFieldPlan(aLoc, aFieldType) then
    begin
      fConstructions.FieldworksList.AddFakeField(aLoc, aFieldType);
      if ID = gMySpectator.HandID then
        gSoundPlayer.Play(sfxPlaceMarker);
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


function TKMHand.AddHouse(aHouseType: TKMHouseType; PosX, PosY: Word; RelativeEntrace: Boolean): TKMHouse;
begin
  Result := fHouses.AddHouse(aHouseType, PosX, PosY, fID, RelativeEntrace);
  Result.OnDestroyed := HouseDestroyed;
end;


//Add plan of a house, house is not created until after worker flattens the terrain
procedure TKMHand.AddHousePlan(aHouseType: TKMHouseType; const aLoc: TKMPoint);
var
  loc: TKMPoint;
begin
  loc.X := aLoc.X - gRes.Houses[aHouseType].EntranceOffsetX;
  loc.Y := aLoc.Y;

  fConstructions.HousePlanList.AddPlan(aHouseType, loc);
  fStats.HousePlanned(aHouseType);
  gScriptEvents.EventHousePlanPlaced(fID, loc.X, loc.Y, aHouseType);

  if (ID = gMySpectator.HandID) and not gGameParams.IsReplayOrSpectate then
    gSoundPlayer.Play(sfxPlaceMarker);
end;


function TKMHand.HasHousePlan(const aLoc: TKMPoint): Boolean;
begin
  Result := fConstructions.HousePlanList.HasPlan(aLoc);
end;


function TKMHand.AddHouseWIP(aHouseType: TKMHouseType; const aLoc: TKMPoint): TKMHouse;
begin
  Result := fHouses.AddHouseWIP(aHouseType, aLoc.X, aLoc.Y, fID);
  Result.OnDestroyed := HouseDestroyed;

  fStats.HouseStarted(aHouseType);
end;


//Player wants to remove own house
procedure TKMHand.RemHouse(const Position: TKMPoint; DoSilent: Boolean; IsEditor: Boolean = False);
var
  H: TKMHouse;
begin
  //Sound is handled in Demolish
  H := fHouses.HitTest(Position.X, Position.Y);
  if H = nil then Exit; //Due to network delays the house might have already been destroyed by now

  H.Demolish(fID, IsEditor);
end;


procedure TKMHand.RemHousePlan(const Position: TKMPoint);
var
  hPlan: TKMHousePlan;
begin
  if not fConstructions.HousePlanList.TryGetPlan(Position, hPlan) then //Due to network delays house might not exist now
    Exit;

  fConstructions.HousePlanList.RemPlan(Position);
  fStats.HousePlanRemoved(hPlan.HouseType);
  gScriptEvents.EventHousePlanRemoved(fID, hPlan.Loc.X, hPlan.Loc.Y, hPlan.HouseType);
  if (ID = gMySpectator.HandID) and not gGameParams.IsReplayOrSpectate then
    gSoundPlayer.Play(sfxClick);
end;


//This is called by the GIP when an erase command is processed
procedure TKMHand.RemFieldPlan(const Position: TKMPoint; aMakeSound: Boolean);
var
  fieldType: TKMFieldType;
begin
  fieldType := fConstructions.FieldworksList.HasField(Position);
  if fieldType = ftNone then Exit; //Can happen due to network delays
  fConstructions.FieldworksList.RemFieldPlan(Position);

  case fieldType of
    ftRoad: gScriptEvents.ProcPlanRoadRemoved(fID, Position.X, Position.Y);
    ftCorn: gScriptEvents.ProcPlanFieldRemoved(fID, Position.X, Position.Y);
    ftWine: gScriptEvents.ProcPlanWinefieldRemoved(fID, Position.X, Position.Y);
  else
    raise Exception.Create('Unknown fieldType');
  end;

  if aMakeSound and not gGameParams.IsReplayOrSpectate
  and (ID = gMySpectator.HandID) then
    gSoundPlayer.Play(sfxClick);
end;


function TKMHand.RemGroup(const Position: TKMPoint): Boolean;
var
  group: TKMUnitGroup;
begin
  Assert(gGameParams.IsMapEditor);

  group := fUnitGroups.HitTest(Position.X, Position.Y);
  Result := group <> nil;
  if Result then
    fUnitGroups.RemGroup(group);
end;


//This is called immediately when the user clicks erase on a field plan.
//We know that an erase command is queued and will be processed in some ticks,
//so we AddFakeDeletedField which lets the user think the field was removed,
//while the game does not know the difference.
procedure TKMHand.RemFakeFieldPlan(const Position: TKMPoint);
begin
  fConstructions.FieldworksList.RemFakeField(Position); //Remove our fake marker which is shown to the user
  fConstructions.FieldworksList.AddFakeDeletedField(Position); //This will hide the real field until it is deleted from game
  if ID = gMySpectator.HandID then gSoundPlayer.Play(sfxClick);
end;


function TKMHand.FindHouse(aType: TKMHouseType; const aPosition: TKMPoint; Index: Byte=1): TKMHouse;
begin
  Result := fHouses.FindHouse(aType, aPosition.X, aPosition.Y, Index);
end;


// Very rough but fast way to find approximate city center
function TKMHand.FindCityCenter: TKMPoint;
const
  IMPORTANT_HOUSES: array[0..4] of TKMHouseType = (htStore, htInn, htSchool, htBarracks, htTownHall);
var
  I: Integer;
  H: TKMHouse;
begin
  for I := 0 to High(IMPORTANT_HOUSES) do
  begin
    H := FindHouse(IMPORTANT_HOUSES[I]);
    if (H <> nil) and not H.IsDestroyed then
      Exit(H.Entrance);
  end;

  // Very rough approach. We suggest there will be at least 1 of the important houses 99.99% of times
  // Find any house then
  for I := 0 to fHouses.Count - 1 do
  begin
    H := fHouses[I];
    if (H <> nil) and not H.IsDestroyed then
      Exit(H.Entrance);
  end;
end;


function TKMHand.FindHouse(aType: TKMHouseType; Index: Byte=1): TKMHouse;
begin
  Result := fHouses.FindHouse(aType, 0, 0, Index);
end;


function TKMHand.FindHousesInRadius(const aLoc: TKMPoint; aSqrRadius: Single; aTypes: TKMHouseTypeSet = HOUSES_VALID; aOnlyCompleted: Boolean = True): TKMHouseArray;
begin
  Result := fHouses.FindHousesInRadius(aLoc, aSqrRadius, aTypes, aOnlyCompleted);
end;


function TKMHand.FindInn(Loc: TKMPoint; aUnit: TKMUnit; UnitIsAtHome: Boolean = False): TKMHouseInn;
var
  H: TKMHouseInn;
  I: Integer;
  dist, bestMatch: Single;
begin
  //This function will return the best inn for a unit at Loc, base on distance, food available and space available.
  //Will return nil if no suitable inn is available
  Result := nil;
  I := 1;
  bestMatch := MaxSingle;
  if UnitIsAtHome then Inc(Loc.Y); //From outside the door of the house

  H := TKMHouseInn(FindHouse(htInn));
  repeat
    //First make sure that it is valid
    if (H <> nil) and H.HasFood and H.HasSpace
    and aUnit.CanWalkTo(Loc, H.PointBelowEntrance, tpWalk, 0) then
    begin
      //Take the closest inn out of the ones that are suitable
      dist := KMLengthSqr(H.Position, Loc);
      if dist < bestMatch then
      begin
        Result := H;
        bestMatch := dist;
      end;
    end;

    Inc(I);
    H := TKMHouseInn(FindHouse(htInn, I));
  until(H = nil);
end;


//Does the player has any assets (without assets player is harmless)
function TKMHand.HasAssets: Boolean;
begin
  if Self = nil then Exit(False);
  
  Result := (Houses.Count > 0) or (Units.Count > 0) or (GetFieldsCount > 0)
            or NeedToChooseFirstStorehouse; //RMG - added ChooseLocation.Allowed option as a valid player
end;


// usually AIType is added by mission parser
procedure TKMHand.AddAIType(aHandAIType: TKMAIType);
begin
  Include(fCanBeAITypes, aHandAIType);
  AI.CanBeAITypes := fCanBeAITypes;
end;


procedure TKMHand.PostLoadMission;
var
  I: Integer;
begin
  if (Self = nil) or not Enabled then Exit;
  
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


// Some entity was destroyed, but gMySpectator could have pointer to this entity, we have to nil it then
procedure TKMHand.EntityDestroyed(aEntity: TKMHandEntity);
begin
  //gMySpectator is nil during loading, when houses can be destroyed at the start
  if gMySpectator = nil then Exit;

  if gMySpectator.Selected = aEntity then
    gMySpectator.Selected := nil;
  if gMySpectator.LastSelected = aEntity then
    gMySpectator.NilLastSelected;
  if gMySpectator.Highlight = aEntity then
    gMySpectator.Highlight := nil;
  if gMySpectator.HighlightDebug.Entity = aEntity then
    gMySpectator.HighlightDebug.Reset;
  if gMySpectator.HighlightDebug2.Entity = aEntity then
    gMySpectator.HighlightDebug2.Reset;
  if gMySpectator.HighlightDebug3.Entity = aEntity then
    gMySpectator.HighlightDebug3.Reset;
  if gMySpectator.HighlightRoute.Entity = aEntity then
    gMySpectator.HighlightRoute.Reset;
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
  begin
    fStats.HouseEnded(aHouse.HouseType);
    // Mark houses BuildEnded only for houses where ready to build
    if aHouse.IsReadyToBeBuilt then
      fStats.HouseBuildEnded(aHouse.HouseType);
  end
  else
  begin
    //We have to consider destroyed closed house as actually opened, otherwise closed houses stats will be corrupted
    if aHouse.IsClosedForWorker and not gGameParams.IsMapEditor then
      fStats.HouseClosed(False, aHouse.HouseType);

    //Distribute honors
    if aFrom = fID then
      fStats.HouseSelfDestruct(aHouse.HouseType)
    else
    begin
      Stats.HouseLost(aHouse.HouseType);

      if aFrom <> HAND_NONE then
        gHands[aFrom].Stats.HouseDestroyed(aHouse.HouseType);
    end;
  end;

  //Scripting events happen AFTER updating statistics
  gScriptEvents.ProcHouseDestroyed(aHouse, aFrom);

  EntityDestroyed(aHouse);
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


function TKMHand.GetDeliveries: TKMHandLogistics;
begin
  if Self = nil then Exit(nil);

  Result := fDeliveries;
end;


function TKMHand.CalcOwnerName: UnicodeString;
var
  numberedAIs: Boolean;
begin
  numberedAIs := not gGameParams.IsSingleplayer;
  //Default names
  if IsHuman then
    Result := gResTexts[TX_PLAYER_YOU]
  else
    if AI.Setup.NewAI then
    begin
      if numberedAIs then
        Result := Format(gResTexts[TX_ADVANCED_AI_PLAYER_SHORT_X], [fID + 1])
      else
        Result := gResTexts[TX_AI_PLAYER_ADVANCED_SHORT];
    end else begin
      if numberedAIs then
        Result := Format(gResTexts[TX_CLASSIC_AI_PLAYER_SHORT_X], [fID + 1])
      else
        Result := gResTexts[TX_AI_PLAYER_CLASSIC_SHORT];
    end;

  //Try to take player name from mission text if we are in SP
  //Do not use names in MP to avoid confusion of AI players with real player nicknames
  if gGameParams.Mode in [gmSingle, gmCampaign, gmMapEd, gmReplaySingle] then
    if gGame.TextMission.HasHandNameText(fID) then
      if IsHuman then
        Result := gResTexts[TX_PLAYER_YOU] + ' (' + gGame.TextMission.GetHandNameText(fID) + ')'
      else
        Result := gGame.TextMission.GetHandNameText(fID);

  //If this location is controlled by an MP player - show his nik
  if (fOwnerNickname <> '') and IsHuman then
    Result := UnicodeString(fOwnerNickname);
end;


function TKMHand.OwnerName(aNumberedAIs: Boolean = True; aLocalized: Boolean = True): UnicodeString;
begin
  Result := GetHandOwnerName(IsHuman, AI.Setup.NewAI, aNumberedAIs, aLocalized);
end;


function TKMHand.GetHandOwnerName(aIsHuman, aIsAdvAI: Boolean; aNumberedAIs: Boolean = True; aLocalized: Boolean = True): UnicodeString;

  function GetText(aId: Word; aLocalized: Boolean): UnicodeString; inline;
  begin
    if aLocalized then
      Result := gResTexts[aId]
    else
      Result := gResTexts.DefaultTexts[aId];
  end;

begin
  //If this location is controlled by an MP player - show his nik
  if (fOwnerNickname <> '')
    and aIsHuman then //we could ask AI to play on ex human loc, so fOwnerNickname will be still some human name
    Exit(UnicodeString(fOwnerNickname));

  //Try to take player name from mission text if we are in SP
  //Do not use names in MP to avoid confusion of AI players with real player nicknames
  if (gGameParams.Mode in [gmSingle, gmCampaign, gmMapEd, gmReplaySingle])
    and gGame.TextMission.HasHandNameText(fID) then
  begin
    if aIsHuman then
      Result := GetText(TX_PLAYER_YOU, aLocalized) + ' (' + gGame.TextMission.GetHandNameText(fID) + ')'
    else
      Result := gGame.TextMission.GetHandNameText(fID);

    Exit;
  end;

  //Default names
  if aIsHuman then
    Result := GetText(TX_PLAYER_YOU, aLocalized)
  else
    if aIsAdvAI then
    begin
      if aNumberedAIs then
        Result := Format(GetText(TX_ADVANCED_AI_PLAYER_SHORT_X, aLocalized), [fID + 1])
      else
        Result := GetText(TX_AI_PLAYER_ADVANCED_SHORT, aLocalized);
    end else begin
      if aNumberedAIs then
        Result := Format(GetText(TX_CLASSIC_AI_PLAYER_SHORT_X, aLocalized), [fID + 1])
      else
        Result := GetText(TX_AI_PLAYER_CLASSIC_SHORT, aLocalized);
    end;
end;


function TKMHand.GetOwnerName: UnicodeString;
begin
  Result := OwnerName(not gGameParams.IsSingleplayer);
end;


function TKMHand.GetOwnerNameColored: AnsiString;
begin
  Result := WrapColorA(AnsiString(GetOwnerName), FlagColorToTextColor(FlagColor));
end;


function TKMHand.GetOwnerNameColoredU: UnicodeString;
begin
  Result := WrapColor(GetOwnerName, FlagColorToTextColor(FlagColor));
end;


function TKMHand.GetAI: TKMHandAI;
begin
  if Self = nil then Exit(nil);

  Result := fAI;
end;


function TKMHand.GetAlliances(aIndex: Integer): TKMAllianceType;
begin
  Result := fAlliances[aIndex];
end;


procedure TKMHand.SetAlliances(aIndex: Integer; aValue: TKMAllianceType);
begin
  if Self = nil then Exit;

  fAlliances[aIndex] := aValue;
  gAIFields.Supervisor.UpdateAlliances();

  if Assigned(fOnAllianceChange) then
    fOnAllianceChange;
end;


procedure TKMHand.SetEnabled(const Value: Boolean);
begin
  fEnabled := Value;
end;


procedure TKMHand.SetFlagColor(const Value: Cardinal);
begin
  if Self = nil then Exit;
  
  fFlagColor := Value;
end;


function  TKMHand.GetShareFOW(aIndex: Integer): Boolean;
begin
  Result := fShareFOW[aIndex];
end;


procedure TKMHand.SetShareFOW(aIndex: Integer; aValue: Boolean);
begin
  if Self = nil then Exit;

  fShareFOW[aIndex] := aValue;
end;


function  TKMHand.GetShareBeacons(aIndex: Integer): Boolean;
begin
  Result := fShareBeacons[aIndex];
end;


procedure TKMHand.SetShareBeacons(aIndex: Integer; aValue: Boolean);
begin
  if Self = nil then Exit;

  fShareBeacons[aIndex] := aValue;
end;


{ See if player owns any Fields/Roads/Walls (has any assets on Terrain)
  If Player has none and no Units/Houses we can assume it's empty and does not needs to be saved
  Queried by MapEditor.SaveDAT;
  Might also be used to show Players strength (or builder/warrior balance) in Tavern }
function TKMHand.GetFieldsCount: Integer;
var
  I, K: Integer;
begin
  Result := 0;
    for I := 1 to gTerrain.MapY do
      for K := 1 to gTerrain.MapX do
        if gTerrain.Land^[I,K].TileOwner = fID then
          Inc(Result);
end;


function TKMHand.GetFlagTextColor: Cardinal;
begin
  Result := FlagColorToTextColor(fFlagColor);
end;


procedure TKMHand.GetFieldPlans(aList: TKMPointTagList; const aRect: TKMRect; aIncludeFake: Boolean);
var
  I: TKMHandID;
begin
  //Include self and allies
  for I := 0 to gHands.Count - 1 do
    if gHands[fID].Alliances[I] = atAlly then
      gHands[I].Constructions.FieldworksList.GetFields(aList, aRect, aIncludeFake);
end;


procedure TKMHand.GetHousePlans(aList: TKMPointDirList; const aRect: TKMRect);
var
  I: TKMHandID;
begin
  //Include self and allies
  for I := 0 to gHands.Count - 1 do
    if gHands[fID].Alliances[I] = atAlly then
      gHands[I].Constructions.HousePlanList.GetOutlines(aList, aRect);
end;


procedure TKMHand.GetPlansTablets(aList: TKMPointTagList; const aRect: TKMRect);
var
  I: TKMHandID;
begin
  //Include self and allies
  for I := 0 to gHands.Count - 1 do
    if gHands[fID].Alliances[I] = atAlly then
      gHands[I].Constructions.HousePlanList.GetTablets(aList, aRect);
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
  I, K, J, S, T: Integer;
  P2: TKMPoint;
  allowBuild: Boolean;
  HA: TKMHouseArea;
begin
  //Get basic Marks
  gTerrain.GetHouseMarks(aLoc, aHouseType, aList);

  //Override marks if there are House/FieldPlans (only we know about our plans) and or FogOfWar
  HA := gRes.Houses[aHouseType].BuildArea;

  for I := 1 to 4 do
    for K := 1 to 4 do
      if (HA[I,K] <> 0)
        and gTerrain.TileInMapCoords(aLoc.X + K - 3 - gRes.Houses[aHouseType].EntranceOffsetX, aLoc.Y + I - 4, 1) then
      begin
        //This can't be done earlier since values can be off-map
        P2 := KMPoint(aLoc.X + K - 3 - gRes.Houses[aHouseType].EntranceOffsetX, aLoc.Y + I - 4);

        //Forbid planning on unrevealed areas and fieldplans
        allowBuild := aIgnoreFOW
                      or (NeedToChooseFirstStorehouseInGame and fFogOfWar.CheckTileInitialRevelation(P2.X, P2.Y)) //Use initial revelation for first storehouse
                      or (not NeedToChooseFirstStorehouseInGame and (fFogOfWar.CheckTileRevelation(P2.X, P2.Y) > 0));

        //This tile must not contain fields/houses of allied players or self
        if allowBuild then
          for J := 0 to gHands.Count - 1 do
            if (gHands[fID].Alliances[J] = atAlly)
              and ((gHands[J].fConstructions.FieldworksList.HasField(P2) <> ftNone)
                or gHands[J].fConstructions.HousePlanList.HasPlan(P2)) then
              allowBuild := False;

        //Check surrounding tiles in +/- 1 range for other houses pressence
        for S := -1 to 1 do
          for T := -1 to 1 do
            if (S <> 0) or (T <> 0) then //This is a surrounding tile, not the actual tile
              for J := 0 to gHands.Count - 1 do
                if (gHands[fID].Alliances[J] = atAlly)
                  and gHands[J].fConstructions.HousePlanList.HasPlan(KMPoint(P2.X + S, P2.Y + T)) then
                begin
                  BlockPoint(KMPoint(P2.X + S, P2.Y + T), TC_BLOCK); //Block surrounding points
                  allowBuild := False;
                end;

        //Mark the tile according to previous check results
        if not allowBuild then
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
  SaveStream.PlaceMarker('Hand');
  SaveStream.Write(fEnabled);
  SaveStream.Write(InCinematic);
  if not Enabled then Exit;

  inherited;
  fAI.Save(SaveStream);
  fConstructions.Save(SaveStream);
  fDeliveries.Save(SaveStream);
  fFogOfWar.Save(SaveStream);
  fHouses.Save(SaveStream);
  fLocks.Save(SaveStream);
  fStats.Save(SaveStream);
  fUnitGroups.Save(SaveStream);
  fMessageLog.Save(SaveStream);

  SaveStream.Write(fID);
  SaveStream.WriteA(fOwnerNickname);
  SaveStream.Write(fHandType, SizeOf(fHandType));
  SaveStream.Write(fCanBeHuman, SizeOf(fCanBeHuman));
  SaveStream.Write(fCanBeAITypes, SizeOf(fCanBeAITypes));
  SaveStream.Write(fAlliances, SizeOf(fAlliances));
  SaveStream.Write(fShareFOW, SizeOf(fShareFOW));
  SaveStream.Write(fShareBeacons, SizeOf(fShareBeacons));
  SaveStream.Write(fCenterScreen);
  SaveStream.Write(fFlagColor);
  SaveStream.Write(fTeam);
  SaveStream.Write(SelectionHotkeys, SizeOf(SelectionHotkeys));
  SaveStream.Write(fChooseLocation, SizeOf(TKMChooseLoc));

  // Overlay
  SaveStream.WriteA(fOverlayMarkup);
  SaveStream.Write(fOverlayTextSettings, SizeOf(fOverlayTextSettings));
  fOverlayParams.Save(SaveStream);
end;


procedure TKMHand.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.CheckMarker('Hand');
  LoadStream.Read(fEnabled);
  LoadStream.Read(InCinematic);
  if not Enabled then Exit;

  inherited;
  fAI.Load(LoadStream);
  fConstructions.Load(LoadStream);
  fDeliveries.Load(LoadStream);
  fFogOfWar.Load(LoadStream);
  fHouses.Load(LoadStream);
  fLocks.Load(LoadStream);
  fStats.Load(LoadStream);
  fUnitGroups.Load(LoadStream);
  fMessageLog.Load(LoadStream);

  LoadStream.Read(fID);
  LoadStream.ReadA(fOwnerNickname);
  LoadStream.Read(fHandType, SizeOf(fHandType));
  LoadStream.Read(fCanBeHuman, SizeOf(fCanBeHuman));
  LoadStream.Read(fCanBeAITypes, SizeOf(fCanBeAITypes));
  LoadStream.Read(fAlliances, SizeOf(fAlliances));
  LoadStream.Read(fShareFOW, SizeOf(fShareFOW));
  LoadStream.Read(fShareBeacons, SizeOf(fShareBeacons));
  LoadStream.Read(fCenterScreen);
  LoadStream.Read(fFlagColor);
  LoadStream.Read(fTeam);
  LoadStream.Read(SelectionHotkeys, SizeOf(SelectionHotkeys));
  LoadStream.Read(fChooseLocation, SizeOf(TKMChooseLoc));

  // Overlay
  LoadStream.ReadA(fOverlayMarkup);
  LoadStream.Read(fOverlayTextSettings, SizeOf(fOverlayTextSettings));
  fOverlayParams.Clear;
  fOverlayParams.Load(LoadStream);
end;


procedure TKMHand.SyncLoad;
var
  I: Integer;
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
  fConstructions.SyncLoad;
  fAI.SyncLoad;
end;


procedure TKMHand.IncAnimStep;
begin
  if not Enabled then Exit;

  fHouses.IncAnimStep;
end;


procedure TKMHand.UnitDied(aUnit: TKMUnit);
begin
  Stats.UnitLost(aUnit.UnitType);
  if aUnit.KilledBy <> HAND_NONE then
    gHands[aUnit.KilledBy].Stats.UnitKilled(aUnit.UnitType);

  //Demands: food for soldiers / stone or wood for workers
  Deliveries.Queue.RemDemand(aUnit);

  if aUnit is TKMUnitWarrior then
    AI.General.WarriorDied(TKMUnitWarrior(aUnit));

  //Call script event after updating statistics
  gScriptEvents.ProcUnitDied(aUnit, aUnit.KilledBy);

  EntityDestroyed(aUnit);
end;


procedure TKMHand.GroupDied(aGroup: TKMUnitGroup);
begin
  EntityDestroyed(aGroup);
end;


procedure TKMHand.UpdateState(aTick: Cardinal);
begin
  if not Enabled then Exit;

  //Player has to place first storehouse at some point or will be defeated
	if NeedToChooseFirstStorehouse and (aTick > TIME_TO_SET_FIRST_STOREHOUSE) then
	  AI.Defeat;
  
  //Update Groups logic before Units
  fUnitGroups.UpdateState;

  inherited;

  fHouses.UpdateState(aTick);
  fFogOfWar.UpdateState(gGameParams.DynamicFOW); //We might optimize it for AI somehow, to make it work coarse and faster

  //Distribute AI updates among different Ticks to avoid slowdowns
  if (aTick mod gHands.Count) = fID then
  begin
    fConstructions.UpdateState;
    fDeliveries.UpdateState(aTick);
  end;

  //AI update takes care of it's own interleaving, so run it every tick
  fAI.UpdateState(aTick, gHands.DoCheckGoals);

  //if (aTick + Byte(fPlayerIndex)) mod 20 = 0 then
    //fArmyEval.UpdateState;

  if CanDoStatsUpdate(aTick) then
    fStats.UpdateState;

  if not gGameParams.IsMapEditor //Do not place first storehouse in map editor etc
    and fChooseLocation.Allowed
    and not fChooseLocation.Placed then
    ChooseFirstStorehouse();
end;


function TKMHand.NeedToChooseFirstStorehouse: Boolean;
begin
  Result := fChooseLocation.Allowed and not fChooseLocation.Placed;
end;


function TKMHand.NeedToChooseFirstStorehouseInGame: Boolean;
begin
  Result := not gGameParams.IsMapEditor and NeedToChooseFirstStorehouse;
end;


procedure TKMHand.ChooseFirstStorehouse();
var
  I: Integer;
  entrance: TKMPoint;
begin
  if IsComputer then
    fChooseLocation.Placed := True
  // Check if storehouse has been placed
  else
  if (Stats.GetHouseTotal(htStore) > 0) then
  begin
    for I := 0 to fConstructions.HousePlanList.Count - 1 do
      with fConstructions.HousePlanList.Plans[I] do
        if (HouseType = htStore) then
        begin
          entrance := KMPointAdd( Loc, KMPoint(gRes.Houses[HouseType].EntranceOffsetX,0) );
          RemHousePlan(entrance);
          if CanAddFieldPlan(KMPoint(entrance.X, entrance.Y+1), ftRoad) then
            AddFirstStorehouse(entrance);
        end;
  end;

  // Preselect storehouse
  if not gGameParams.IsReplayOrSpectate
  and (gMySpectator.HandID = ID)
  and not fChooseLocation.Placed then
  begin
    gCursor.Mode := cmHouses;
    gCursor.Tag1 := Byte(htStore);
  end;
end;


procedure TKMHand.AddFirstStorehouse(aEntrance: TKMPoint);
  // Place road and return True if it is possible
  function AddRoad(aPoint: TKMPoint): Boolean;
  begin
    Result := CanAddFieldPlan(KMPoint(aPoint.X, aPoint.Y), ftRoad);
    if Result then
    begin
      gTerrain.SetRoad(aPoint, fID);
      //Terrain under roads is flattened (fields are not)
      gTerrain.FlattenTerrain(aPoint);
      if gMapElements[gTerrain.Land^[aPoint.Y,aPoint.X].Obj].WineOrCorn then
        gTerrain.RemoveObject(aPoint);
    end;
  end;
var
  I: Integer;
  H: TKMHouse;
  WT: TKMWareType;
  UT: TKMUnitType;
begin
  // Add Storehouse
  H := AddHouse(htStore, aEntrance.X, aEntrance.Y, True);
  // Add Wares
  for WT := Low(fChooseLocation.Resources) to High(fChooseLocation.Resources) do
    if H.WareCanAddToIn(WT) OR H.WareCanAddToOut(WT) then
    begin
      Stats.WareInitial(WT, fChooseLocation.Resources[WT]);
      H.WareAddToEitherFromScript(WT, fChooseLocation.Resources[WT]);
    end;
  // Add Roads
  AddRoad( KMPoint(aEntrance.X,  aEntrance.Y+1) );
  AddRoad( KMPoint(aEntrance.X-1,aEntrance.Y+1) );
  AddRoad( KMPoint(aEntrance.X+1,aEntrance.Y+1) );
  // Add Units
  for UT := Low(fChooseLocation.Units) to High(fChooseLocation.Units) do
    for I := 0 to fChooseLocation.Units[UT] - 1 do
      AddUnit(UT, KMPoint(aEntrance.X,aEntrance.Y+1));
  // Finish action
  fChooseLocation.Placed := True;
  gCursor.Mode := cmNone; // Reset cursor
end;


function TKMHand.CanDoStatsUpdate(aTick: Cardinal): Boolean;
begin
  Result := (aTick mod GetStatsUpdatePeriod = 0) or (aTick = 1);
end;


function TKMHand.DoCheckGoals: Boolean;
begin
  Result := not fChooseLocation.Allowed
            or (fChooseLocation.Allowed and fChooseLocation.Placed);
end;


procedure TKMHand.Paint(const aRect: TKMRect; aTickLag: Single);
begin
  if not Enabled then Exit;

  inherited;

  if mlUnits in gGameParams.VisibleLayers then
    fUnitGroups.Paint(aRect, aTickLag);

  if mlHouses in gGameParams.VisibleLayers then
    fHouses.Paint(aRect);

  if not SKIP_RENDER AND OVERLAY_DEFENCES AND not fAI.Setup.NewAI then
    if gMySpectator.SelectedHandID = fID then
      fAI.General.DefencePositions.Paint;

  if not SKIP_RENDER AND fAI.Setup.NewAI then
  begin
    if OVERLAY_AI_BUILD then
    begin
      fAI.CityManagement.Builder.Paint();
      fAI.CityManagement.Builder.Planner.Paint();
    end;
    if OVERLAY_AI_COMBAT then
      fAI.ArmyManagement.Paint();
  end;
end;


function TKMHand.ObjToString(aSeparator: string = ' '): string;
begin
  Result := Format('Enabled = %5s%sID = %d%sAI: [%s]%sOwner = %s%sHandType = %s',
                   [BoolToStr(Enabled, True), aSeparator,
                    fID, aSeparator,
                    AI.ObjToString, aSeparator,
                    OwnerName, aSeparator,
                    GetEnumName(TypeInfo(TKMHandType), Integer(fHandType))]);
end;


{ TKMHandAnimals }
function TKMHandAnimals.GetFishInWaterBody(aWaterID: Byte; FindHighestCount: Boolean = True): TKMUnitFish;
var
  I, highestGroupCount: Integer;
  U: TKMUnit;
begin
  Result := nil;
  if aWaterID = 0 then Exit; //Fish should always be in valid water
  highestGroupCount := 0;

  for I := 0 to fUnits.Count - 1 do
  begin
    U := fUnits[I]; //Store locally

    if (U <> nil)
    and (U.UnitType = utFish)
    and not U.IsDeadOrDying //Fish are killed when they are caught or become stuck
    and (gTerrain.Land^[U.Position.Y, U.Position.X].WalkConnect[wcFish] = aWaterID)
    and (TKMUnitFish(U).FishCount > highestGroupCount) then
    begin
      Result := TKMUnitFish(U);
      //This is for time saving when we don't actually care which group is returned
      if not FindHighestCount then Exit;
      highestGroupCount := Result.FishCount;
    end;
  end;
end;


//-----------
function GetStatsUpdatePeriod: Integer;
begin
  Result := 1000;
  case gGameParams.MissionMode of
    mmBuilding:  Result := CHARTS_SAMPLING_FOR_ECONOMY;
    mmFighting:  Result := CHARTS_SAMPLING_FOR_TACTICS;
  end;
end;


end.
