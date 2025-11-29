unit KM_ResUnits;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils,
  KM_CommonClasses, KM_CommonTypes, KM_Defaults, KM_Points,
  KM_ResTypes;


type
  // Used to separate close-combat units from archers (they use different fighting logic)
  TKMFightType = (ftMelee, ftRanged);

  TKMUnitMoveType = (umtWalk, umtWalkDiag, umtStorm, umtStormDiag);

  TKMUnitSpecLegacy = packed record
    HitPoints: SmallInt;
    Attack: SmallInt;
    AttackHorse: SmallInt;
    x4: SmallInt;
    Defence: SmallInt;
    Speed: SmallInt;
    x7: SmallInt;
    Sight: SmallInt;
    x9: ShortInt;
    x10: ShortInt;
    CanWalkOut: SmallInt;
    x11: SmallInt;
  end;

  TKMUnitSprite = array [TKMUnitActionType, dirN..dirNW] of TKMAnimLoop;

  TKMUnitSpecInfo = record
    StepsPerTile: Byte;
    StepsPerTileDiag: Byte;
    StepsPerTileStorm: Byte;
    StepsPerTileStormDiag: Byte;
  end;

  TKMUnitSprite2 = array [1..18] of SmallInt; //Sound indices vs sprite ID

  // Common facade for unit specs that hides the legacy and modern complexities
  TKMUnitSpec = class
  private
    fUnitType: TKMUnitType;
    fUnitDat: TKMUnitSpecLegacy;
    fUnitSpecInfo: TKMUnitSpecInfo;
    fUnitSprite: TKMUnitSprite;
    fUnitSprite2: TKMUnitSprite2;
    function GetAllowedPassability: TKMTerrainPassability;
    function GetDescription: UnicodeString;
    function GetDesiredPassability: TKMTerrainPassability;
    function GetFightType: TKMFightType;
    function GetGUIIcon: Word;
    function GetGUIScroll: Word;
    function GetMinimapColor: Cardinal;
    function GetMiningRange: Byte;
    function GetSpeed: Single;
    function GetUnitAnim(aAction: TKMUnitActionType; aDir: TKMDirection): TKMAnimLoop;
    function GetUnitTextID: Integer;
    function GetUnitName: UnicodeString;
  public
    constructor Create(aType: TKMUnitType);
    function IsValid: Boolean;
    function IsAnimal: Boolean;
    function IsCitizen: Boolean;
    function IsWarrior: Boolean;
    function IsWarriorEquipable: Boolean;

    function GetDefenceVsProjectiles(aIsBolt: Boolean): Single;
    procedure LoadFromStream(Stream: TMemoryStream);
    //Derived from KaM
    property HitPoints: SmallInt read fUnitDat.HitPoints;
    property Attack: SmallInt read fUnitDat.Attack;
    property AttackHorse: SmallInt read fUnitDat.AttackHorse;
    property Defence: SmallInt read fUnitDat.Defence;
    property Description: UnicodeString read GetDescription;
    property Sight: SmallInt read fUnitDat.Sight;
    //Additional properties added by Remake
    property AllowedPassability: TKMTerrainPassability read GetAllowedPassability;
    property DesiredPassability: TKMTerrainPassability read GetDesiredPassability;
    property FightType: TKMFightType read GetFightType;
    property GUIIcon: Word read GetGUIIcon;
    property GUIScroll: Word read GetGUIScroll;
    property MinimapColor: Cardinal read GetMinimapColor;
    property MiningRange: Byte read GetMiningRange;
    property Speed: Single read GetSpeed;
    function GetEffectiveSpeed(aMovementType: TKMUnitMoveType): Single;
    function GetEffectiveWalkSpeed(aIsDiag: Boolean): Single;
    function GetEffectiveStormSpeed(aIsDiag: Boolean): Single;
    function SupportsAction(aAct: TKMUnitActionType): Boolean;
    property UnitAnim[aAction: TKMUnitActionType; aDir: TKMDirection]: TKMAnimLoop read GetUnitAnim;
    property GUIName: UnicodeString read GetUnitName;
    property GUITextID: Integer read GetUnitTextID;

    class function IsMelee(aUnitType: TKMUnitType): Boolean;
    class function IsMounted(aUnitType: TKMUnitType): Boolean;
    class function IsAntihorse(aUnitType: TKMUnitType): Boolean;
    class function IsRanged(aUnitType: TKMUnitType): Boolean;
  end;


  TKMResUnits = class
  private
    fCRC: Cardinal;
    fItems: array [TKMUnitType] of TKMUnitSpec;
    fSerfCarry: array [WARE_MIN..WARE_MAX, dirN..dirNW] of TKMAnimLoop;
    procedure LoadUnitsDat(const aPath: UnicodeString);
    procedure PatchUnitSpec;
    function GetItem(aType: TKMUnitType): TKMUnitSpec; inline;
    function GetSerfCarry(aType: TKMWareType; aDir: TKMDirection): TKMAnimLoop;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ResetToDefaults;

    property Items[aType: TKMUnitType]: TKMUnitSpec read GetItem; default;
    property SerfCarry[aType: TKMWareType; aDir: TKMDirection]: TKMAnimLoop read GetSerfCarry;
    property CRC: Cardinal read fCRC; //Return hash of all values

    procedure ExportCSV(const aPath: UnicodeString);

    procedure SaveCustomData(aSaveStream: TKMemoryStream);
    procedure LoadCustomData(aLoadStream: TKMemoryStream);
  end;

const
  //This is a map of the valid values for !SET_UNIT,
  //TSK did not had place for new warriors that were inserted in the middle(!)
  UNIT_OLD_ID_TO_TYPE: array[0..31] of TKMUnitType = (
    utSerf,utWoodcutter,utMiner,utAnimalBreeder,utFarmer,
    utCarpenter,utBaker,utButcher,utFisher,utBuilder,
    utStonemason,utSmith,utMetallurgist,utRecruit, //Units
    utMilitia,utAxeFighter,utSwordFighter,utBowman,utCrossbowman,
    utLanceCarrier,utPikeman,utScout,utKnight,utBarbarian, //Troops
    utWolf,utFish,utWatersnake,utSeastar,utCrab,
    utWaterflower,utWaterleaf,utDuck); //Animals

  //and the corresponing unit that will be created (matches KaM behavior)
  UNIT_TYPE_TO_OLD_ID: array[TKMUnitType] of integer = (
    -1, -1, //utNone, utAny
    0,1,2,3,4,5,6,7,8,9,10,11,12,13, //Citizens
    14,15,16,17,18,19,20,21,22,23, //Warriors
    -1,-1,-1,-1, {-1,-1,} //TPR warriors (can't be placed with SET_UNIT)
    24,25,26,27,28,29,30,31); //Animals

  //This is a map of the valid values for !SET_GROUP, and the corresponing unit that will be created (matches KaM behavior)
  UNIT_ID_TO_TYPE: array[0..40] of TKMUnitType = (
    utSerf,utWoodcutter,utMiner,utAnimalBreeder,utFarmer,
    utCarpenter,utBaker,utButcher,utFisher,utBuilder,
    utStonemason,utSmith,utMetallurgist,utRecruit, //Units
    utMilitia,utAxeFighter,utSwordFighter,utBowman,utCrossbowman,
    utLanceCarrier,utPikeman,utScout,utKnight,utBarbarian, //TSK Troops
    utRebel,utRogue,utWarrior,utVagabond,
    {utCatapult,utBallista}utNone,utNone, //Placeholder for Seige weapons
    utWolf, utFish, utWatersnake, utSeastar, utCrab,
    utWaterflower, utWaterleaf, utDuck,
    utNone, utNone, utNone
    );

  UNIT_TYPE_TO_ID: array[TKMUnitType] of ShortInt = (
    -1, -1,                           // utNone, utAny
    0,1,2,3,4,5,6,7,8,9,10,11,12,13,  // Citizens
    14,15,16,17,18,19,20,21,22,23,    // Warriors
    24,25,26,27, {28,29,}             // TPR warriors
    30,31,32,33,34,35,36,37           // Animals
  );

  // Number means WareType as it is stored in Barracks, hence it's not wtSomething
  TROOP_COST: array [utMilitia..utKnight, 1..4] of TKMWareType = (
    (wtAxe,          wtNone,         wtNone,  wtNone ), // Militia
    (wtWoodenShield, wtLeatherArmor, wtAxe,   wtNone ), // Axefighter
    (wtIronShield,   wtIronArmor,    wtSword, wtNone ), // Swordfighter
    (wtLeatherArmor, wtBow,          wtNone,  wtNone ), // Bowman
    (wtIronArmor,    wtCrossbow,     wtNone,  wtNone ), // Crossbowman
    (wtLeatherArmor, wtLance,        wtNone,  wtNone ), // Lance Carrier
    (wtIronArmor,    wtPike,         wtNone,  wtNone ), // Pikeman
    (wtWoodenShield, wtLeatherArmor, wtAxe,   wtHorse), // Scout
    (wtIronShield,   wtIronArmor,    wtSword, wtHorse)  // Knight
  );

  // The frame shown when a unit is standing still in uaWalk. Same for all units!
  UNIT_STILL_FRAMES: array [TKMDirection] of Byte = (0,3,2,2,1,6,7,6,6);

var
  // TownHall default units troops cost (number of gold chests needed)
  // Could be modified by script functions
  TH_TROOP_COST: array[0..4] of Byte;


implementation
uses
  TypInfo,
  KromUtils, KM_ResTexts;

const
  STORM_SPEEDUP = 1.5;

  //TownHall default units troops cost (number of gold chests needed)
  TH_DEFAULT_TROOP_COST: array[0..4] of Byte = (
    2, 3, 5, 8, 8 //rebel / rogue / vagabond / barbarian / warrior
  );


{ TKMUnitSpec }
constructor TKMUnitSpec.Create(aType: TKMUnitType);
begin
  inherited Create;
  fUnitType := aType;
end;


function TKMUnitSpec.IsValid: boolean;
begin
  Result := not (fUnitType in [utNone, utAny]);
end;


function TKMUnitSpec.IsAnimal: boolean;
begin
  Result := fUnitType in [ANIMAL_MIN..ANIMAL_MAX];
end;


function TKMUnitSpec.IsCitizen: boolean;
begin
  Result := fUnitType in [CITIZEN_MIN..CITIZEN_MAX];
end;


function TKMUnitSpec.IsWarrior: boolean;
begin
  Result := fUnitType in [WARRIOR_MIN..WARRIOR_MAX];
end;


function TKMUnitSpec.IsWarriorEquipable: boolean;
begin
  Result := fUnitType in [WARRIOR_EQUIPABLE_BARRACKS_MIN..WARRIOR_EQUIPABLE_BARRACKS_MAX];
end;


function TKMUnitSpec.GetDefenceVsProjectiles(aIsBolt: Boolean): Single;
const
  SHEILD_DEFENCE_BONUS_AGAINST_XBOW = 0.5;
  SHEILD_DEFENCE_BONUS_AGAINST_BOW_N_SLING = 1;
begin
  Result := Defence;
  //Shielded units get a small bonus
  if fUnitType in [utAxeFighter, utSwordFighter, utScout, utKnight] then
  begin
    if aIsBolt then
      Result := Result + SHEILD_DEFENCE_BONUS_AGAINST_XBOW
    else
      Result := Result + SHEILD_DEFENCE_BONUS_AGAINST_BOW_N_SLING;
  end;
end;


procedure TKMUnitSpec.LoadFromStream(Stream: TMemoryStream);
begin
  Stream.Read(fUnitDat, SizeOf(TKMUnitSpecLegacy));
  Stream.Read(fUnitSprite, SizeOf(TKMUnitSprite));
  Stream.Read(fUnitSprite2, SizeOf(TKMUnitSprite2));
end;


function TKMUnitSpec.SupportsAction(aAct: TKMUnitActionType): Boolean;
const
  UNIT_SUPPOSTED_ACTIONS: array [TKMUnitType] of TKMUnitActionTypeSet = (
    [], [], //None, Any
    [uaWalk, uaDie, uaEat, uaWalkArm], //Serf
    [uaWalk, uaWork, uaDie, uaWork1, uaEat..uaWalkTool2],
    [uaWalk, uaDie, uaEat],
    [uaWalk, uaDie, uaEat],
    [uaWalk, uaWork, uaDie..uaWalkBooty2],
    [uaWalk, uaDie, uaEat],
    [uaWalk, uaDie, uaEat],
    [uaWalk, uaDie, uaEat],
    [uaWalk, uaWork, uaDie, uaWork1..uaWalkBooty],
    [uaWalk, uaWork, uaDie, uaEat, uaWork1, uaWork2],
    [uaWalk, uaWork, uaDie, uaWork1, uaEat..uaWalkBooty],
    [uaWalk, uaDie, uaEat],
    [uaWalk, uaDie, uaEat],
    [uaWalk, uaSpec, uaDie, uaEat], //Recruit
    [uaWalk, uaWork, uaSpec, uaDie, uaEat], //Militia
    [uaWalk, uaWork, uaSpec, uaDie, uaEat], //Axeman
    [uaWalk, uaWork, uaSpec, uaDie, uaEat], //Swordsman
    [uaWalk, uaWork, uaSpec, uaDie, uaEat], //Bowman
    [uaWalk, uaWork, uaSpec, uaDie, uaEat], //Crossbowman
    [uaWalk, uaWork, uaDie, uaEat],
    [uaWalk, uaWork, uaDie, uaEat],
    [uaWalk, uaWork, uaDie, uaEat],
    [uaWalk, uaWork, uaDie, uaEat], //Cavalry
    [uaWalk, uaWork, uaSpec, uaDie, uaEat], //Barbarian
    [uaWalk, uaWork, uaDie, uaEat], //Rebel
    [uaWalk, uaWork, uaSpec, uaDie, uaEat], //Slingshot
    [uaWalk, uaWork, uaSpec, uaDie, uaEat], //Warrior
    [uaWalk, uaWork, uaDie, uaEat],
    [uaWalk], [uaWalk], [uaWalk], [uaWalk], [uaWalk], [uaWalk], [uaWalk], [uaWalk] //Animals
  );
begin
  Result := aAct in UNIT_SUPPOSTED_ACTIONS[fUnitType];
end;


function TKMUnitSpec.GetAllowedPassability: TKMTerrainPassability;
const
  // Defines which animal prefers which terrain
  ANIMAL_TERRAIN: array[ANIMAL_MIN .. ANIMAL_MAX] of TKMTerrainPassability = (
    tpWolf, tpFish, tpFish, tpFish, tpCrab, tpFish, tpFish, tpFish);
begin
  case fUnitType of
    ANIMAL_MIN..ANIMAL_MAX:  Result := ANIMAL_TERRAIN[fUnitType]; //Animals
  else
    Result := tpWalk; // Worker, Warriors
  end;
end;


// Where unit would like to be
function TKMUnitSpec.GetDesiredPassability: TKMTerrainPassability;
begin
  if fUnitType in [CITIZEN_MIN..CITIZEN_MAX] - [utBuilder] then
    Result := tpWalkRoad //Citizens except Worker
  else
    Result := GetAllowedPassability; //Workers, warriors, animals
end;


function TKMUnitSpec.GetFightType: TKMFightType;
const
  WARRIOR_FIGHT_TYPE: array[WARRIOR_MIN..WARRIOR_MAX] of TKMFightType = (
    ftMelee,ftMelee,ftMelee, //Militia, AxeFighter, Swordsman
    ftRanged,ftRanged,        //Bowman, Arbaletman
    ftMelee,ftMelee,          //Pikeman, Hallebardman,
    ftMelee,ftMelee,          //HorseScout, Cavalry,
    ftMelee,                   //Barbarian
    ftMelee,                   //Peasant
    ftRanged,                  //utSlingshot
    ftMelee,                   //utMetalBarbarian
    ftMelee                    //utHorseman
    {ftRanged,ftRanged,       //utCatapult, utBallista,}
  );
begin
  Assert(fUnitType in [Low(WARRIOR_FIGHT_TYPE)..High(WARRIOR_FIGHT_TYPE)]);
  Result := WARRIOR_FIGHT_TYPE[fUnitType];
end;


function TKMUnitSpec.GetGUIIcon: Word;
begin
  case fUnitType of
    utNone, utAny:  Result := 0;
    utBarbarian:    Result := 70;
  else
    if IsCitizen then
      Result := 141 + UNIT_TYPE_TO_ID[fUnitType]
    else if IsWarriorEquipable then
      Result := 47 + UNIT_TYPE_TO_ID[fUnitType]
    else if IsWarrior then
      Result := 55 + UNIT_TYPE_TO_ID[fUnitType]
    else
      Result := 0;
  end;
end;


function TKMUnitSpec.GetGUIScroll: Word;
begin
  if IsValid then
    Result := 521 + UNIT_TYPE_TO_ID[fUnitType]
  else
    Result := 0;
end;


//Units are rendered on minimap with their team color
//Animals don't have team and thus are rendered in their own prefered clors
function TKMUnitSpec.GetMinimapColor: Cardinal;
const
  MINIMAP_COLOR: array [TKMUnitType] of Cardinal = (
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    $B0B0B0,$B08000,$B08000,$80B0B0,$00B0B0,$B080B0,$00B000,$80B0B0); // Exact colors can be tweaked
begin
  Result := MINIMAP_COLOR[fUnitType] or $FF000000;
end;


// Unit mining ranges. (measured from KaM)
function TKMUnitSpec.GetMiningRange: Byte;
begin
  case fUnitType of
    utWoodcutter:  Result := 10;
    utFarmer:      Result := 10;
    utStonemason:  Result := 16;
    utFisher:      Result := 14;
  else
    raise Exception.Create(GUIName + ' has no mining range');
  end;
end;


function TKMUnitSpec.GetSpeed: Single;
begin
  // Return speed in tiles per tick (usually 0.1)
  Result := fUnitDat.Speed / 240;
end;


function TKMUnitSpec.GetEffectiveSpeed(aMovementType: TKMUnitMoveType): Single;
begin
  case aMovementType of
    umtWalk:      Result := 1 / fUnitSpecInfo.StepsPerTile;
    umtWalkDiag:  Result := 1 / fUnitSpecInfo.StepsPerTileDiag;
    umtStorm:     Result := 1 / fUnitSpecInfo.StepsPerTileStorm;
    umtStormDiag: Result := 1 / fUnitSpecInfo.StepsPerTileStormDiag;
  else
    raise Exception.Create('Unexpected type');
  end;
end;


function TKMUnitSpec.GetEffectiveWalkSpeed(aIsDiag: Boolean): Single;
begin
  if aIsDiag then
    Result := GetEffectiveSpeed(umtWalkDiag)
  else
    Result := GetEffectiveSpeed(umtWalk);
end;


function TKMUnitSpec.GetEffectiveStormSpeed(aIsDiag: Boolean): Single;
begin
  if aIsDiag then
    Result := GetEffectiveSpeed(umtStormDiag)
  else
    Result := GetEffectiveSpeed(umtStorm);
end;


function TKMUnitSpec.GetUnitAnim(aAction: TKMUnitActionType; aDir: TKMDirection): TKMAnimLoop;
begin
  Assert(aDir <> dirNA);
  Assert(aAction in [Low(TKMUnitActionType)..High(TKMUnitActionType)]);
  Result := fUnitSprite[aAction, aDir];
end;


function TKMUnitSpec.GetUnitTextID: Integer;
begin
  if not IsValid then Exit(-1);

  case fUnitType of
    utWolf:        Result := TX_UNITS_WOLF;
    utFish:        Result := TX_UNITS_FISH;
    utWatersnake:  Result := TX_UNITS_WATERSNAKE;
    utSeastar:     Result := TX_UNITS_SEASTAR;
    utCrab:        Result := TX_UNITS_CRAB;
    utWaterflower: Result := TX_UNITS_WATERFLOWER;
    utWaterleaf:   Result := TX_UNITS_WATERLEAF;
    utDuck:        Result := TX_UNITS_DUCK;
  else
    Result := TX_UNITS_NAMES__29 + UNIT_TYPE_TO_ID[fUnitType];
  end;
end;


function TKMUnitSpec.GetUnitName: UnicodeString;
begin
  case fUnitType of
    utAny:             Result := gResTexts[TX_UNITS_ALL];
    utNone:            Result := 'N/A';
  else
    Result := gResTexts[GetUnitTextID];
  end;
end;


function TKMUnitSpec.GetDescription: UnicodeString;
begin
  if IsValid and not IsAnimal then
    Result := gResTexts[TX_UNITS_DESCRIPTIONS__13 + UNIT_TYPE_TO_ID[fUnitType]]
  else
    Result := 'N/A';
end;


class function TKMUnitSpec.IsMelee(aUnitType: TKMUnitType): Boolean;
begin
  Result := aUnitType in [utMilitia, utAxeFighter, utSwordFighter, utBarbarian, utWarrior];
end;


class function TKMUnitSpec.IsMounted(aUnitType: TKMUnitType): Boolean;
begin
  Result := aUnitType in [utScout, utKnight, utVagabond];
end;


class function TKMUnitSpec.IsAntihorse(aUnitType: TKMUnitType): Boolean;
begin
  Result := aUnitType in [utLanceCarrier, utPikeman, utRebel];
end;


class function TKMUnitSpec.IsRanged(aUnitType: TKMUnitType): Boolean;
begin
  Result := aUnitType in [utBowman, utCrossbowman, utRogue];
end;


{ TKMUnitsDatCollection }
constructor TKMResUnits.Create;
var
  UT: TKMUnitType;
begin
  inherited;

  for UT := Low(TKMUnitType) to High(TKMUnitType) do
    fItems[UT] := TKMUnitSpec.Create(UT);

  LoadUnitsDat(ExeDir + 'data' + PathDelim + 'defines' + PathDelim + 'unit.dat');

  //ExportCSV(ExeDir + 'units.original.csv');
  PatchUnitSpec;

  //ExportCSV(ExeDir + 'units.remake.csv');
  //Halt;
end;


destructor TKMResUnits.Destroy;
var
  UT: TKMUnitType;
begin
  for UT := Low(TKMUnitType) to High(TKMUnitType) do
    fItems[UT].Free;

  inherited;
end;


procedure TKMResUnits.SaveCustomData(aSaveStream: TKMemoryStream);
begin
  aSaveStream.PlaceMarker('UnitsCustomData');
  aSaveStream.Write(TH_TROOP_COST, SizeOF(TH_TROOP_COST));
end;


procedure TKMResUnits.LoadCustomData(aLoadStream: TKMemoryStream);
begin
  aLoadStream.CheckMarker('UnitsCustomData');
  aLoadStream.Read(TH_TROOP_COST, SizeOF(TH_TROOP_COST));
end;


procedure TKMResUnits.PatchUnitSpec;
const
  DEF_SCOUT_SIGHT = 9;
  DEF_HORSEMAN_ATTACK = 40;
  DEF_PEASANT_ATTACK_HORSE = 60;
  DEF_PIKEMAN_ATTACK_HORSE = 55;
  DEF_MOUNTED_SPEED = 39;
var
  UT: TKMUnitType;
begin
  // Overwrite units stats only if they are set for default values from original game
  // We don't want to update them, in case player manually edited unit.dat file
  if fItems[utScout].fUnitDat.Sight = DEF_SCOUT_SIGHT then
    fItems[utScout].fUnitDat.Sight := 13;

  if fItems[utVagabond].fUnitDat.Attack = DEF_HORSEMAN_ATTACK then
    fItems[utVagabond].fUnitDat.Attack := 35;

  if fItems[utRebel].fUnitDat.AttackHorse = DEF_PEASANT_ATTACK_HORSE then
    fItems[utRebel].fUnitDat.AttackHorse := 50;

  if fItems[utLanceCarrier].fUnitDat.AttackHorse = DEF_PIKEMAN_ATTACK_HORSE then
    fItems[utLanceCarrier].fUnitDat.AttackHorse := 60;

  // .Dat mounted speed is 39, but it makes 9 steps per diagonal tile after rounding, while we used to 8 steps
  if fItems[utScout].fUnitDat.Speed = DEF_MOUNTED_SPEED then
    fItems[utScout].fUnitDat.Speed := 40;

  if fItems[utKnight].fUnitDat.Speed = DEF_MOUNTED_SPEED then
    fItems[utKnight].fUnitDat.Speed := 40;

  if fItems[utVagabond].fUnitDat.Speed = DEF_MOUNTED_SPEED then
    fItems[utVagabond].fUnitDat.Speed := 40;

  for UT := UNIT_MIN to UNIT_MAX do
  begin
    fItems[UT].fUnitSpecInfo.StepsPerTile          := Round(1    / fItems[UT].Speed);
    fItems[UT].fUnitSpecInfo.StepsPerTileDiag      := Round(1.41 / fItems[UT].Speed);
    fItems[UT].fUnitSpecInfo.StepsPerTileStorm     := Round(1    / (fItems[UT].Speed * STORM_SPEEDUP));
    fItems[UT].fUnitSpecInfo.StepsPerTileStormDiag := Round(1.41 / (fItems[UT].Speed * STORM_SPEEDUP));
  end;
end;


procedure TKMResUnits.ExportCSV(const aPath: UnicodeString);
var
  sw: TStreamWriter;
  UT: TKMUnitType;
begin
  sw := TStreamWriter.Create(aPath);
  sw.WriteLine('Name,HitPoints,Attack,AttackHorse,x4,Defence,Speed,x7,Sight,x9,x10,CanWalkOut,x11');
  for UT := Low(TKMUnitType) to High(TKMUnitType) do
  if Items[UT].IsValid then
  begin
    sw.Write(GetEnumName(TypeInfo(TKMUnitType), Ord(UT)) + ',');
    sw.Write(IntToStr(Items[UT].HitPoints) + ',');
    sw.Write(IntToStr(Items[UT].Attack) + ',');
    sw.Write(IntToStr(Items[UT].AttackHorse) + ',');
    sw.Write(IntToStr(Items[UT].fUnitDat.x4) + ',');
    sw.Write(IntToStr(Items[UT].Defence) + ',');
    sw.Write(IntToStr(Items[UT].fUnitDat.Speed) + ',');
    sw.Write(IntToStr(Items[UT].fUnitDat.x7) + ',');
    sw.Write(IntToStr(Items[UT].Sight) + ',');
    sw.Write(IntToStr(Items[UT].fUnitDat.x9) + ',');
    sw.Write(IntToStr(Items[UT].fUnitDat.x10) + ',');
    sw.Write(IntToStr(Items[UT].fUnitDat.CanWalkOut) + ',');
    sw.Write(IntToStr(Items[UT].fUnitDat.x11) + ',');
    // for kk:=1 to 18 do
    // sw.Write(IntToStr(UnitSprite2[UT,kk])+',');
    sw.WriteLine;
  end;
  sw.Free;

  {AssignFile(ft,ExeDir+'Units.txt'); rewrite(ft);
  for ii:=Low(TKMUnitType) to High(TKMUnitType) do
  if UnitsDat[ii].IsValid then
  begin
    writeln(ft);
    writeln(ft);
    writeln(ft,'NewUnit'+inttostr(ii));
    for kk:=1 to 14 do
    for hh:=1 to 8 do
    //  if UnitSprite[ii].Act[kk].Dir[hh].Step[1]>0 then
        begin
          write(ft,inttostr(kk)+'.'+inttostr(hh)+#9);
          for jj:=1 to 30 do
          if UnitSprite[ii].Act[kk].Dir[hh].Step[jj]>0 then //write(ft,'#');
          write(ft,inttostr(UnitSprite[ii].Act[kk].Dir[hh].Step[jj])+'. ');
          write(ft,inttostr(UnitSprite[ii].Act[kk].Dir[hh].Count)+' ');
          write(ft,inttostr(UnitSprite[ii].Act[kk].Dir[hh].MoveX)+' ');
          write(ft,inttostr(UnitSprite[ii].Act[kk].Dir[hh].MoveY)+' ');
          writeln(ft);
        end;
  end;
  closefile(ft);}
end;


procedure TKMResUnits.ResetToDefaults;
var
  I: Integer;
begin
  for I := Low(TH_TROOP_COST) to High(TH_TROOP_COST) do
    TH_TROOP_COST[I] := TH_DEFAULT_TROOP_COST[I];
end;


function TKMResUnits.GetSerfCarry(aType: TKMWareType; aDir: TKMDirection): TKMAnimLoop;
begin
  Assert(aType in [WARE_MIN .. WARE_MAX]);
  Result := fSerfCarry[aType, aDir];
end;


function TKMResUnits.GetItem(aType: TKMUnitType): TKMUnitSpec;
begin
  Result := fItems[aType];
end;


procedure TKMResUnits.LoadUnitsDat(const aPath: UnicodeString);
const
  UNIT_DAT_COUNT = 41;
var
  S: TKMemoryStream;
  I: Integer;
begin
  Assert(FileExists(aPath), Format('unit.dat can not be found at "%s"', [ExtractRelativePath(ExeDir, aPath)]));

  S := TKMemoryStreamBinary.Create;
  try
    S.LoadFromFile(aPath);

    S.Read(fSerfCarry, SizeOf(fSerfCarry){28*8*70});

    for I := 0 to UNIT_DAT_COUNT - 1 do
    if UNIT_ID_TO_TYPE[I] <> utNone then
      fItems[UNIT_ID_TO_TYPE[I]].LoadFromStream(S)
    else //Skip
      S.Seek(SizeOf(TKMUnitSpecLegacy) + SizeOf(TKMUnitSprite) + SizeOf(TKMUnitSprite2), soFromCurrent);

    fCRC := Adler32CRC(S);
  finally
    S.Free;
  end;
end;


end.
