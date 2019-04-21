unit KM_ResUnits;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils,
  KM_CommonClasses, KM_CommonTypes, KM_Defaults, KM_Points,
  KM_ResWares;


//Used to separate close-combat units from archers (they use different fighting logic)
type
  TFightType = (ftMelee, ftRanged);

  TKMUnitDat = packed record
    HitPoints, Attack, AttackHorse, x4, Defence, Speed, x7, Sight: SmallInt;
    x9, x10: ShortInt;
    CanWalkOut, x11: SmallInt;
  end;

  TKMUnitSprite = packed record
    Act: array [TKMUnitActionType] of packed record
      Dir: array [dirN..dirNW] of TKMAnimLoop;
    end;
  end;

  TKMUnitSprite2 = array [1..18] of SmallInt; //Sound indices vs sprite ID

  TKMUnitSpec = class
  private
    fUnitType: TKMUnitType;
    fUnitDat: TKMUnitDat;
    fUnitSprite: TKMUnitSprite;
    fUnitSprite2: TKMUnitSprite2;
    function GetAllowedPassability: TKMTerrainPassability;
    function GetDescription: UnicodeString;
    function GetDesiredPassability: TKMTerrainPassability;
    function GetFightType: TFightType;
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
    property HitPoints:smallint read fUnitDat.HitPoints;
    property Attack:smallint read fUnitDat.Attack;
    property AttackHorse:smallint read fUnitDat.AttackHorse;
    property Defence:smallint read fUnitDat.Defence;
    property Description: UnicodeString read GetDescription;
    property Sight:smallint read fUnitDat.Sight;
    //Additional properties added by Remake
    property AllowedPassability:TKMTerrainPassability read GetAllowedPassability;
    property DesiredPassability:TKMTerrainPassability read GetDesiredPassability;
    property FightType:TFightType read GetFightType;
    property GUIIcon:word read GetGUIIcon;
    property GUIScroll:word read GetGUIScroll;
    property MinimapColor: Cardinal read GetMinimapColor;
    property MiningRange:byte read GetMiningRange;
    property Speed:single read GetSpeed;
    function SupportsAction(aAct: TKMUnitActionType):boolean;
    property UnitAnim[aAction:TKMUnitActionType; aDir:TKMDirection]: TKMAnimLoop read GetUnitAnim;
    property GUIName: UnicodeString read GetUnitName;
    property GUITextID: Integer read GetUnitTextID;
  end;


  TKMResUnits = class
  private
    fCRC: Cardinal;
    fItems: array [TKMUnitType] of TKMUnitSpec;
    fSerfCarry: array [WARE_MIN..WARE_MAX, dirN..dirNW] of TKMAnimLoop;
    function LoadUnitsDat(const aPath: UnicodeString): Cardinal;
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
  UnitOldIndexToType: array[0..31] of TKMUnitType = (
    utSerf,utWoodcutter,utMiner,utAnimalBreeder,utFarmer,
    utLamberjack,utBaker,utButcher,utFisher,utWorker,
    utStoneCutter,utSmith,utMetallurgist,utRecruit, //Units
    utMilitia,utAxeFighter,utSwordsman,utBowman,utArbaletman,
    utPikeman,utHallebardman,utHorseScout,utCavalry,utBarbarian, //Troops
    utWolf,utFish,utWatersnake,utSeastar,utCrab,
    utWaterflower,utWaterleaf,utDuck); //Animals

  //and the corresponing unit that will be created (matches KaM behavior)
  UnitTypeToOldIndex: array[TKMUnitType] of integer = (
  -1, -1, //utNone, utAny
  0,1,2,3,4,5,6,7,8,9,10,11,12,13, //Citizens
  14,15,16,17,18,19,20,21,22,23, //Warriors
  -1,-1,-1,-1, {-1,-1,} //TPR warriors (can't be placed with SET_UNIT)
  24,25,26,27,28,29,30,31); //Animals

  //This is a map of the valid values for !SET_GROUP, and the corresponing unit that will be created (matches KaM behavior)
  UnitIndexToType: array[0..40] of TKMUnitType = (
    utSerf,utWoodcutter,utMiner,utAnimalBreeder,utFarmer,
    utLamberjack,utBaker,utButcher,utFisher,utWorker,
    utStoneCutter,utSmith,utMetallurgist,utRecruit, //Units
    utMilitia,utAxeFighter,utSwordsman,utBowman,utArbaletman,
    utPikeman,utHallebardman,utHorseScout,utCavalry,utBarbarian, //TSK Troops
    utPeasant,utSlingshot,utMetalBarbarian,utHorseman,
    {utCatapult,utBallista}utNone,utNone, //Placeholder for Seige weapons
    utWolf, utFish, utWatersnake, utSeastar, utCrab,
    utWaterflower, utWaterleaf, utDuck,
    utNone, utNone, utNone
    );

  UnitTypeToIndex: array[TKMUnitType] of ShortInt = (
  -1, -1, //utNone, utAny
  0,1,2,3,4,5,6,7,8,9,10,11,12,13, //Citizens
  14,15,16,17,18,19,20,21,22,23, //Warriors
  24,25,26,27, {28,29,} //TPR warriors
  30,31,32,33,34,35,36,37); //Animals


  //Number means ResourceType as it is stored in Barracks, hence it's not rtSomething
  TROOP_COST: array [utMilitia..utCavalry, 1..4] of TKMWareType = (
    (wtAxe,          wtNone,        wtNone,  wtNone ), //Militia
    (wtShield,       wtArmor,       wtAxe,   wtNone ), //Axefighter
    (wtMetalShield,  wtMetalArmor,  wtSword, wtNone ), //Swordfighter
    (wtArmor,        wtBow,         wtNone,  wtNone ), //Bowman
    (wtMetalArmor,   wtArbalet,     wtNone,  wtNone ), //Crossbowman
    (wtArmor,        wtPike,        wtNone,  wtNone ), //Lance Carrier
    (wtMetalArmor,   wtHallebard,   wtNone,  wtNone ), //Pikeman
    (wtShield,       wtArmor,       wtAxe,   wtHorse), //Scout
    (wtMetalShield,  wtMetalArmor,  wtSword, wtHorse)  //Knight
  );



  //The frame shown when a unit is standing still in uaWalk. Same for all units!
  UnitStillFrames: array [TKMDirection] of Byte = (0,3,2,2,1,6,7,6,6);

var
  //TownHall default units troops cost (number of gold chests needed)
  //Could be modified by script functions
  TH_TROOP_COST: array[0..5] of Byte;


implementation
uses
  KromUtils, KM_ResTexts;

const
  //TownHall default units troops cost (number of gold chests needed)
  TH_DEFAULT_TROOP_COST: array[0..5] of Byte = (
    3, 3, 3, 5, 10, 10
  );


{ TKMUnitsDatClass }
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
  Result := fUnitType in [WARRIOR_EQUIPABLE_MIN..WARRIOR_EQUIPABLE_MAX];
end;


function TKMUnitSpec.GetDefenceVsProjectiles(aIsBolt: Boolean): Single;
begin
  Result := Defence;
  //Shielded units get a small bonus
  if fUnitType in [utAxeFighter, utSwordsman, utHorseScout, utCavalry] then
    if aIsBolt then
      Result := Result + 0.25
    else
      Result := Result + 1;
end;


procedure TKMUnitSpec.LoadFromStream(Stream: TMemoryStream);
begin
  Stream.Read(fUnitDat, SizeOf(TKMUnitDat));
  Stream.Read(fUnitSprite, SizeOf(TKMUnitSprite));
  Stream.Read(fUnitSprite2, SizeOf(TKMUnitSprite2));
end;


function TKMUnitSpec.SupportsAction(aAct: TKMUnitActionType): Boolean;
const UnitSupportedActions: array [TKMUnitType] of TKMUnitActionTypeSet = (
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
    [uaWalk], [uaWalk], [uaWalk], [uaWalk], [uaWalk], [uaWalk], [uaWalk], [uaWalk]); //Animals
begin
  Result := aAct in UnitSupportedActions[fUnitType];
end;


function TKMUnitSpec.GetAllowedPassability: TKMTerrainPassability;
//Defines which animal prefers which terrain
const AnimalTerrain: array[ANIMAL_MIN .. ANIMAL_MAX] of TKMTerrainPassability = (
    tpWolf, tpFish, tpFish, tpFish, tpCrab, tpFish, tpFish, tpFish);
begin
  case fUnitType of
    ANIMAL_MIN..ANIMAL_MAX:  Result := AnimalTerrain[fUnitType]; //Animals
    else                     Result := tpWalk; //Worker, Warriors
  end;
end;


//Where unit would like to be
function TKMUnitSpec.GetDesiredPassability: TKMTerrainPassability;
begin
  if fUnitType in [CITIZEN_MIN..CITIZEN_MAX] - [utWorker] then
    Result := tpWalkRoad //Citizens except Worker
  else
    Result := GetAllowedPassability; //Workers, warriors, animals
end;


function TKMUnitSpec.GetFightType: TFightType;
const WarriorFightType: array[WARRIOR_MIN..WARRIOR_MAX] of TFightType = (
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
  Assert(fUnitType in [Low(WarriorFightType)..High(WarriorFightType)]);
  Result := WarriorFightType[fUnitType];
end;


function TKMUnitSpec.GetGUIIcon: Word;
begin
  case fUnitType of
    utNone, utAny:  Result := 0;
    utBarbarian:     Result := 70;
  else
    if IsCitizen then
      Result := 141 + UnitTypeToIndex[fUnitType]
    else if IsWarriorEquipable then
      Result := 47 + UnitTypeToIndex[fUnitType]
    else if IsWarrior then
      Result := 55 + UnitTypeToIndex[fUnitType]
    else
      Result := 0;
  end;
end;


function TKMUnitSpec.GetGUIScroll: Word;
begin
  if IsValid then
    Result := 521 + UnitTypeToIndex[fUnitType]
  else
    Result := 0;
end;


//Units are rendered on minimap with their team color
//Animals don't have team and thus are rendered in their own prefered clors
function TKMUnitSpec.GetMinimapColor: Cardinal;
const
  MMColor:array[TKMUnitType] of Cardinal = (
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    $B0B0B0,$B08000,$B08000,$80B0B0,$00B0B0,$B080B0,$00B000,$80B0B0); //Exact colors can be tweaked
begin
  Result := MMColor[fUnitType] or $FF000000;
end;


//Unit mining ranges. (measured from KaM)
function TKMUnitSpec.GetMiningRange: byte;
begin
  case fUnitType of
    utWoodcutter:  Result := 10;
    utFarmer:      Result := 10;
    utStonecutter: Result := 16;
    utFisher:      Result := 14;
    else            raise Exception.Create(GUIName + ' has no mining range');
  end;
end;


function TKMUnitSpec.GetSpeed: single;
begin
  Result := fUnitDat.Speed / 240;
end;


function TKMUnitSpec.GetUnitAnim(aAction: TKMUnitActionType; aDir: TKMDirection): TKMAnimLoop;
begin
  Assert(aDir <> dirNA);
  Assert(aAction in [Low(TKMUnitActionType)..High(TKMUnitActionType)]);
  Result := fUnitSprite.Act[aAction].Dir[aDir];
end;


function TKMUnitSpec.GetUnitTextID: Integer;
begin
  if IsValid then
    case fUnitType of
      utWolf:        Result := TX_UNITS_WOLF;
      utFish:        Result := TX_UNITS_FISH;
      utWatersnake:  Result := TX_UNITS_WATERSNAKE;
      utSeastar:     Result := TX_UNITS_SEASTAR;
      utCrab:        Result := TX_UNITS_CRAB;
      utWaterflower: Result := TX_UNITS_WATERFLOWER;
      utWaterleaf:   Result := TX_UNITS_WATERLEAF;
      utDuck:        Result := TX_UNITS_DUCK;
      else            Result := TX_UNITS_NAMES__29 + UnitTypeToIndex[fUnitType];
    end
  else
    Result := -1;
end;


function TKMUnitSpec.GetUnitName: UnicodeString;
begin
  case fUnitType of
    utAny:             Result := gResTexts[TX_UNITS_ALL];
    utNone:            Result := 'N/A';
    else                Result := gResTexts[GetUnitTextID];
  end;
end;


function TKMUnitSpec.GetDescription: UnicodeString;
begin
  if IsValid and not IsAnimal then
    Result := gResTexts[TX_UNITS_DESCRIPTIONS__13 + UnitTypeToIndex[fUnitType]]
  else
    Result := 'N/A';
end;


{ TKMUnitsDatCollection }
constructor TKMResUnits.Create;
var
  U: TKMUnitType;
begin
  inherited;

  for U := Low(TKMUnitType) to High(TKMUnitType) do
    fItems[U] := TKMUnitSpec.Create(U);

  fCRC := LoadUnitsDat(ExeDir+'data' + PathDelim + 'defines' + PathDelim + 'unit.dat');
  fItems[utHorseScout].fUnitDat.Sight := 16;
  fItems[utHorseman].fUnitDat.Attack := 35;
  fItems[utPeasant].fUnitDat.AttackHorse := 55;
  //ExportCSV(ExeDir+'units.csv');
end;


destructor TKMResUnits.Destroy;
var U:TKMUnitType;
begin
  for U := Low(TKMUnitType) to High(TKMUnitType) do
    fItems[U].Free;

  inherited;
end;


procedure TKMResUnits.SaveCustomData(aSaveStream: TKMemoryStream);
begin
  aSaveStream.Write(TH_TROOP_COST, SizeOF(TH_TROOP_COST));
end;


procedure TKMResUnits.LoadCustomData(aLoadStream: TKMemoryStream);
begin
  aLoadStream.Read(TH_TROOP_COST, SizeOF(TH_TROOP_COST));
end;


procedure TKMResUnits.ExportCSV(const aPath: UnicodeString);
var ft:textfile; ii:TKMUnitType;
begin
    AssignFile(ft,aPath); rewrite(ft);
    writeln(ft,'Name;HitPoints;Attack;AttackHorse;Defence;Speed;Sight;');
    for ii:=Low(TKMUnitType) to High(TKMUnitType) do
    if Items[ii].IsValid then
    begin
      write(ft,Items[ii].GUIName+';');
      write(ft,inttostr(Items[ii].HitPoints)+';');
      write(ft,inttostr(Items[ii].Attack)+';');
      write(ft,inttostr(Items[ii].AttackHorse)+';');
      //write(ft,inttostr(Items[ii].x4)+';');
      write(ft,inttostr(Items[ii].Defence)+';');
      write(ft,floattostr(Items[ii].Speed)+';');
      //write(ft,inttostr(Items[ii].x7)+';');
      write(ft,inttostr(Items[ii].Sight)+';');
      //write(ft,inttostr(Items[ii].x9)+';');
      //write(ft,inttostr(Items[ii].x10)+';');
      //write(ft,inttostr(Items[ii].CanWalkOut)+';');
      //write(ft,inttostr(Items[ii].x11)+';');
      //for kk:=1 to 18 do
      //  write(ft,inttostr(UnitSprite2[ii,kk])+';');
      writeln(ft);
    end;
    closefile(ft);

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
  for I := 0 to 5 do
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


function TKMResUnits.LoadUnitsDat(const aPath: UnicodeString): Cardinal;
const UNIT_DAT_COUNT = 41;
var
  S: TKMemoryStream;
  I: Integer;
begin
  Assert(FileExists(aPath));

  S := TKMemoryStream.Create;
  try
    S.LoadFromFile(aPath);

    S.Read(fSerfCarry, SizeOf(fSerfCarry){28*8*70});

    for I := 0 to UNIT_DAT_COUNT - 1 do
    if UnitIndexToType[I] <> utNone then
      fItems[UnitIndexToType[I]].LoadFromStream(S)
    else //Skip
      S.Seek(SizeOf(TKMUnitDat) + SizeOf(TKMUnitSprite) + SizeOf(TKMUnitSprite2), soFromCurrent);

    Result := Adler32CRC(S);
  finally
    S.Free;
  end;
end;


end.
