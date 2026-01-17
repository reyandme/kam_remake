unit KM_HandStats;
{$I KaM_Remake.inc}
interface
uses
  Classes,
  KM_WareDistribution,
  KM_ResHouses,
  KM_CommonClasses, KM_CommonTypes, KM_Defaults,
  KM_ResTypes;


//These are stats for each player
type
  TKMHouseStats = packed record
    Planned,             //Houseplans were placed
    PlanRemoved,         //Houseplans were removed
    Started,             //Construction started (WIP)
    RdyToBuild,          //Ready to be built
    BuildEnded,          //Build ended (either completed or destroyed)
    Ended,               //Construction ended (either done or destroyed/cancelled)
    Initial,             //created by script on mission start
    Built,               //constructed by player
    SelfDestruct,        //deconstructed by player
    Lost,                //lost from attacks and self-demolished
    Closed,              //closed for worker
    Destroyed: Cardinal; //damage to other players
  end;

  TKMUnitStats = packed record
    Initial,          //Provided at mission start
    Training,         //Currently in training queue
    Dismissing,       //Currently dismissing
    Trained,          //Trained by player
    Lost,             //Died of hunger or killed
    Retired,          //Retired Units Don't Count towards Units Lost
    Killed: Cardinal; //Killed (incl. self)
  end;

  TKMWareStats = packed record
    Initial: Cardinal;
    Produced: Cardinal;
    Consumed: Cardinal;
  end;

  // Army chart kind
  TKMChartArmyKind = (
    cakInstantaneous, // Charts of in game warriors quantities
    cakTotal,         // Charts of total army trained (includes initial army)
    cakDefeated,
    cakLost);

  //Player statistics (+ ratios, house unlock, trade permissions)
  TKMHandStats = class
  private
    fChartCount: Integer;
    fChartCapacity: Integer;
    fChartHouses: TKMCardinalArray;
    fChartCitizens: TKMCardinalArray;
    fChartArmy: array[TKMChartArmyKind] of array[WARRIOR_MIN..WARRIOR_MAX] of TKMCardinalArray;
    fChartWares: array [WARE_MIN..WARE_MAX] of TKMCardinalArray;
    // Has to save fArmyEmpty array, even thought it will be still same after load and 1 HandStats update (which we always do on game exit)
    // since we don't want army chart to be empty before 1st UpdateState (30 sec)
    // It's important to use cakTotal instead of cakInstantenious, because Inst. could be empty even after load and 1 update state!
    fArmyEmpty: array[cakTotal..cakLost] of array [WARRIOR_MIN..WARRIOR_MAX] of Boolean;

    Houses: array [TKMHouseType] of TKMHouseStats;
    Units: array [HUMANS_MIN..HUMANS_MAX] of TKMUnitStats;
    Wares: array [WARE_MIN..WARE_MAX] of TKMWareStats;

    fWareDistribution: TKMWareDistribution;
    function GetChartWares(aWare: TKMWareType): TKMCardinalArray;
    function GetChartArmy(aChartKind: TKMChartArmyKind; aWarrior: TKMUnitType): TKMCardinalArray;
    function GetArmyChartValue(aChartKind: TKMChartArmyKind; aUnitType: TKMUnitType): Integer;

    procedure HousesToCSV(aStrings: TStringList);
    procedure UnitsToCSV(aStrings: TStringList);
    procedure WaresToCSV(aStrings: TStringList);
  public
    constructor Create;
    destructor Destroy; override;

    //Input reported by Player
    procedure WareInitial(aWare: TKMWareType; aCount: Cardinal);
    procedure WareProduced(aWare: TKMWareType; aCount: Cardinal);
    procedure WareConsumed(aWare: TKMWareType; aCount: Cardinal = 1);
    procedure HousePlanned(aType: TKMHouseType);
    procedure HousePlanRemoved(aType: TKMHouseType);
    procedure HouseStarted(aType: TKMHouseType);
    procedure HouseRdyToBeBuilt(aType: TKMHouseType);
    procedure HouseBuildEnded(aType: TKMHouseType);
    procedure HouseClosed(aWasClosed: Boolean; aType: TKMHouseType);
    procedure HouseEnded(aType: TKMHouseType);
    procedure HouseCreated(aType: TKMHouseType; aWasBuilt: Boolean);
    procedure HouseLost(aType: TKMHouseType);
    procedure HouseSelfDestruct(aType: TKMHouseType);
    procedure HouseDestroyed(aType: TKMHouseType);
    procedure UnitCreated(aType: TKMUnitType; aWasTrained: Boolean{; aFromTownHall: Boolean = False});
    procedure UnitAddedToTrainingQueue(aType: TKMUnitType);
    procedure UnitRemovedFromTrainingQueue(aType: TKMUnitType);
    procedure UnitDismissed(aType: TKMUnitType);
    procedure UnitDismissCanceled(aType: TKMUnitType);
    procedure UnitLost(aType: TKMUnitType);
    procedure CitizenRetired(aType: TKMUnitType);
    procedure UnitKilled(aType: TKMUnitType);

    property WareDistribution: TKMWareDistribution read fWareDistribution;

    //Output
    function GetHouseQty(aType: TKMHouseType): Integer; overload;
    function GetHouseOpenedQty(aType: TKMHouseType): Integer; overload;
    function GetHouseQty(const aType: array of TKMHouseType): Integer; overload;
    function GetHouseWip(aType: TKMHouseType): Integer; overload;
    function GetHouseRdyToBeBuilt(aType: TKMHouseType): Integer;
    function GetHousePlans(aType: TKMHouseType): Integer; overload;
    function GetHouseWip(const aType: array of TKMHouseType): Integer; overload;
    function GetHouseTotal(aType: TKMHouseType): Integer;
    function GetUnitQty(aType: TKMUnitType): Integer;
    function GetUnitTraining(aType: TKMUnitType): Integer;
    function GetUnitDismissing(aType: TKMUnitType): Integer;
    function GetUnitKilledQty(aType: TKMUnitType): Integer;
    function GetUnitLostQty(aType: TKMUnitType): Integer;
    function GetWareBalance(aRT: TKMWareType): Integer;
    function GetArmyCount: Integer;
    function GetArmyPower: Single;
    function GetCitizensCount: Integer;

    function GetCitizensTrained: Cardinal;
    function GetCitizensLost: Cardinal;
    function GetCitizensKilled: Cardinal;
    function GetCitizensRetired: Cardinal;
    function GetHousesBuilt: Cardinal;
    function GetHousesLost: Cardinal;
    function GetHousesDestroyed: Cardinal;
    function GetWarriorsTrained: Cardinal;
    function GetWarriorsTotal(aWarriorType: TKMUnitType): Cardinal;
    function GetWarriorsKilled: Cardinal;
    function GetWarriorsLost: Cardinal;
    function GetWaresProduced(aRT: TKMWareType): Cardinal;
    function GetCivilProduced: Cardinal;
    function GetWeaponsProduced: Cardinal;
    function GetWarfareProduced: Cardinal;

    property ChartCount: Integer read fChartCount;
    property ChartHouses: TKMCardinalArray read fChartHouses;
    property ChartCitizens: TKMCardinalArray read fChartCitizens;
    property ChartWares[aWare: TKMWareType]: TKMCardinalArray read GetChartWares;

    property ChartArmy[aChartKind: TKMChartArmyKind; aWarrior: TKMUnitType]: TKMCardinalArray read GetChartArmy;
    function ChartWaresEmpty(aWare: TKMWareType): Boolean;
    function ChartArmyEmpty(aChartKind: TKMChartArmyKind; aWarrior: TKMUnitType): Boolean;

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

    procedure UpdateState;

    procedure ToCSV(aStrings: TStringList);
  end;


implementation
uses
  SysUtils,
  KM_Resource, KM_ResUnits;


{ TKMHandStats }
constructor TKMHandStats.Create;
var
  WT: TKMUnitType;
  CKind: TKMChartArmyKind;
begin
  inherited;

  fWareDistribution := TKMWareDistribution.Create;

  for CKind := cakTotal to cakLost do
    for WT := WARRIOR_MIN to WARRIOR_MAX do
      fArmyEmpty[CKind,WT] := True;
end;


destructor TKMHandStats.Destroy;
begin
  FreeAndNil(fWareDistribution);

  inherited;
end;


procedure TKMHandStats.HousePlanned(aType: TKMHouseType);
begin
  Inc(Houses[aType].Planned);
end;


procedure TKMHandStats.HousePlanRemoved(aType: TKMHouseType);
begin
  Inc(Houses[aType].PlanRemoved);
end;


//New house in progress
procedure TKMHandStats.HouseStarted(aType: TKMHouseType);
begin
  Inc(Houses[aType].Started);
end;


procedure TKMHandStats.HouseRdyToBeBuilt(aType: TKMHouseType);
begin
  Inc(Houses[aType].RdyToBuild);
end;


procedure TKMHandStats.HouseBuildEnded(aType: TKMHouseType);
begin
  Inc(Houses[aType].BuildEnded);
end;


//House building process was ended. We don't really know if it was canceled or destroyed or finished
//Other House** methods will handle that
procedure TKMHandStats.HouseEnded(aType: TKMHouseType);
begin
  Inc(Houses[aType].Ended);
end;


//House closed for worker
procedure TKMHandStats.HouseClosed(aWasClosed: Boolean; aType: TKMHouseType);
begin
  if aWasClosed then
    Inc(Houses[aType].Closed)
  else
    Dec(Houses[aType].Closed)
end;


//New house, either built by player or created by mission script
procedure TKMHandStats.HouseCreated(aType: TKMHouseType; aWasBuilt:boolean);
begin
  if aWasBuilt then
    Inc(Houses[aType].Built)
  else
    Inc(Houses[aType].Initial);
end;


//Destroyed by enemy
procedure TKMHandStats.HouseLost(aType: TKMHouseType);
begin
  Inc(Houses[aType].Lost);
end;


procedure TKMHandStats.HouseSelfDestruct(aType: TKMHouseType);
begin
  Inc(Houses[aType].SelfDestruct);
end;


//Player has destroyed an enemy house
procedure TKMHandStats.HouseDestroyed(aType: TKMHouseType);
begin
  Inc(Houses[aType].Destroyed);
end;


procedure TKMHandStats.UnitAddedToTrainingQueue(aType: TKMUnitType);
begin
  Inc(Units[aType].Training);
end;


procedure TKMHandStats.UnitRemovedFromTrainingQueue(aType: TKMUnitType);
begin
  Dec(Units[aType].Training);
end;


procedure TKMHandStats.UnitDismissed(aType: TKMUnitType);
begin
  Inc(Units[aType].Dismissing);
end;


procedure TKMHandStats.UnitDismissCanceled(aType: TKMUnitType);
begin
  Dec(Units[aType].Dismissing);
end;


procedure TKMHandStats.UnitCreated(aType: TKMUnitType; aWasTrained: Boolean{; aFromTownHall: Boolean = False});
begin
  if aWasTrained then
    Inc(Units[aType].Trained)
  else
    Inc(Units[aType].Initial);
end;


procedure TKMHandStats.UnitLost(aType: TKMUnitType);
begin
  Inc(Units[aType].Lost);
end;


procedure TKMHandStats.CitizenRetired(aType: TKMUnitType);
begin
  Inc(Units[aType].Retired);
end;


procedure TKMHandStats.UnitKilled(aType: TKMUnitType);
begin
  Inc(Units[aType].Killed);
end;


procedure TKMHandStats.WareInitial(aWare: TKMWareType; aCount: Cardinal);
begin
  if aWare <> wtNone then
    Inc(Wares[aWare].Initial, aCount);
end;


procedure TKMHandStats.WareProduced(aWare: TKMWareType; aCount: Cardinal);
var
  WT: TKMWareType;
begin
  case aWare of
    wtNone:     ;
    wtAll:      for WT := WARE_MIN to WARE_MAX do
                  Inc(Wares[WT].Produced, aCount);
    WARE_MIN..
    WARE_MAX:   Inc(Wares[aWare].Produced, aCount);
  else
    raise Exception.Create('Cant''t add produced ware ' + gRes.Wares[aWare].Title);
  end;
end;


procedure TKMHandStats.WareConsumed(aWare: TKMWareType; aCount: Cardinal = 1);
begin
  if aWare <> wtNone then
    Inc(Wares[aWare].Consumed, aCount);
end;


//How many complete houses are there
function TKMHandStats.GetHouseQty(aType: TKMHouseType): Integer;
var
  HT: TKMHouseType;
begin
  Result := 0;
  case aType of
    htNone:    ;
    htAny:     for HT := HOUSE_MIN to HOUSE_MAX do
                  Inc(Result, Houses[HT].Initial + Houses[HT].Built - Houses[HT].SelfDestruct - Houses[HT].Lost);
  else
    Result := Houses[aType].Initial + Houses[aType].Built - Houses[aType].SelfDestruct - Houses[aType].Lost;
  end;
end;


//How many complete opened houses are there
function TKMHandStats.GetHouseOpenedQty(aType: TKMHouseType): Integer;
var
  HT: TKMHouseType;
begin
  Result := 0;
  case aType of
    htNone:    ;
    htAny:     for HT := HOUSE_MIN to HOUSE_MAX do
                  Inc(Result, Houses[HT].Initial + Houses[HT].Built - Houses[HT].SelfDestruct - Houses[HT].Lost - Houses[HT].Closed);
  else
    Result := Houses[aType].Initial + Houses[aType].Built - Houses[aType].SelfDestruct - Houses[aType].Lost - Houses[aType].Closed;
  end;
end;


//How many complete houses there are
function TKMHandStats.GetHouseQty(const aType: array of TKMHouseType): Integer;
var
  I: Integer;
  HT: TKMHouseType;
begin
  Result := 0;
  if (Length(aType) = 0) then
    raise Exception.Create('Quering wrong house type')
  else
  if (Length(aType) = 1) and (aType[0] = htAny) then
  begin
    for HT := HOUSE_MIN to HOUSE_MAX do
      Inc(Result, Houses[HT].Initial + Houses[HT].Built - Houses[HT].SelfDestruct - Houses[HT].Lost);
  end
  else
    for I := Low(aType) to High(aType) do
    if aType[I] in HOUSES_VALID then
      Inc(Result, Houses[aType[I]].Initial + Houses[aType[I]].Built - Houses[aType[I]].SelfDestruct - Houses[aType[I]].Lost)
    else
      raise Exception.Create('Quering wrong house type');
end;


//How many houses are planned and in progress
function TKMHandStats.GetHouseWip(aType: TKMHouseType): Integer;
var
  HT: TKMHouseType;
begin
  Result := 0;
  case aType of
    htNone:    ;
    htAny:     for HT := HOUSE_MIN to HOUSE_MAX do
                  Inc(Result, Houses[HT].Started + Houses[HT].Planned - Houses[HT].Ended - Houses[HT].PlanRemoved);
  else
    Result := Houses[aType].Started + Houses[aType].Planned - Houses[aType].Ended - Houses[aType].PlanRemoved;
  end;
end;


function TKMHandStats.GetHouseRdyToBeBuilt(aType: TKMHouseType): Integer;
var
  HT: TKMHouseType;
begin
  Result := 0;
  case aType of
    htNone:    ;
    htAny:     for HT := HOUSE_MIN to HOUSE_MAX do
                  Inc(Result, Houses[HT].RdyToBuild - Houses[HT].BuildEnded);
  else
    Result := Houses[aType].RdyToBuild - Houses[aType].BuildEnded;
  end;
end;


//How many house plans player has at certain moment...
function TKMHandStats.GetHousePlans(aType: TKMHouseType): Integer;
begin
  Result := Houses[aType].Planned - Houses[aType].PlanRemoved;
end;


//How many houses are planned in progress and ready
function TKMHandStats.GetHouseTotal(aType: TKMHouseType): Integer;
begin
  Result := GetHouseQty(aType) + GetHouseWip(aType);
end;


//How many houses are planned and in progress
function TKMHandStats.GetHouseWip(const aType: array of TKMHouseType): Integer;
var
  I: Integer;
  HT: TKMHouseType;
begin
  Result := 0;
  if Length(aType) = 0 then
    raise Exception.Create('Quering wrong house type')
  else
  if (Length(aType) = 1) and (aType[0] = htAny) then
  begin
    for HT := HOUSE_MIN to HOUSE_MAX do
      Inc(Result, Houses[HT].Started + Houses[HT].Planned - Houses[HT].Ended - Houses[HT].PlanRemoved);
  end
  else
    for I := Low(aType) to High(aType) do
    if aType[I] in HOUSES_VALID then
      Inc(Result, Houses[aType[I]].Started + Houses[aType[I]].Planned - Houses[aType[I]].Ended - Houses[aType[I]].PlanRemoved)
    else
      raise Exception.Create('Quering wrong house type');
end;


function TKMHandStats.GetUnitQty(aType: TKMUnitType): Integer;
var
  UT: TKMUnitType;
begin
  Result := 0;
  case aType of
    utNone: ;
    utAny:     for UT := HUMANS_MIN to HUMANS_MAX do
                  Inc(Result, Units[UT].Initial + Units[UT].Trained - Units[UT].Lost);
  else
    Result := Units[aType].Initial + Units[aType].Trained - Units[aType].Lost;
    if aType = utRecruit then
      for UT := WARRIOR_EQUIPABLE_BARRACKS_MIN to WARRIOR_EQUIPABLE_BARRACKS_MAX do
        Dec(Result, Units[UT].Trained); //Trained soldiers use a recruit
  end;
end;


function TKMHandStats.GetUnitTraining(aType: TKMUnitType): Integer;
var
  UT: TKMUnitType;
begin
  Result := 0;
  case aType of
    utNone: ;
    utAny:     for UT := HUMANS_MIN to HUMANS_MAX do
                  Inc(Result, Units[UT].Training);
  else
    Result := Units[aType].Training;
  end;
end;


function TKMHandStats.GetUnitDismissing(aType: TKMUnitType): Integer;
var
  UT: TKMUnitType;
begin
  Result := 0;
  case aType of
    utNone: ;
    utAny:      for UT := HUMANS_MIN to HUMANS_MAX do
                  Result := Result + Units[UT].Dismissing;
  else
    Result := Units[aType].Dismissing;
  end;
end;


function TKMHandStats.GetUnitKilledQty(aType: TKMUnitType): Integer;
var
  UT: TKMUnitType;
begin
  Result := 0;
  case aType of
    utNone: ;
    utAny:  for UT := HUMANS_MIN to HUMANS_MAX do
              Inc(Result, Units[UT].Killed);
  else
    Result := Units[aType].Killed;
  end;
end;


function TKMHandStats.GetUnitLostQty(aType: TKMUnitType): Integer;
var
  UT: TKMUnitType;
begin
  Result := 0;
  case aType of
    utNone: ;
    utAny:  for UT := HUMANS_MIN to HUMANS_MAX do
              Inc(Result, Units[UT].Lost);
  else
    Result := Units[aType].Lost;
  end;
end;


//How many wares player has right now
function TKMHandStats.GetWareBalance(aRT: TKMWareType): Integer;
var
  RT: TKMWareType;
begin
  Result := 0;
  case aRT of
    wtNone:    ;
    wtAll:     for RT := WARE_MIN to WARE_MAX do
                  Inc(Result, Wares[RT].Initial + Wares[RT].Produced - Wares[RT].Consumed);
    wtWarfare: for RT := WARFARE_MIN to WARFARE_MAX do
                  Inc(Result, Wares[RT].Initial + Wares[RT].Produced - Wares[RT].Consumed);
  else
    Result := Wares[aRT].Initial + Wares[aRT].Produced - Wares[aRT].Consumed;
  end;
end;


function TKMHandStats.GetArmyCount: Integer;
var
  UT: TKMUnitType;
begin
  Result := 0;
  for UT := WARRIOR_MIN to WARRIOR_MAX do
    Inc(Result, GetUnitQty(UT));
end;


function TKMHandStats.GetArmyPower: Single;
var
  UT: TKMUnitType;
begin
  Result := 0;
  for UT := WARRIOR_MIN to WARRIOR_MAX do
    Result := Result + GetUnitQty(UT) * gRes.Units[UT].ArmyPower;
end;


function TKMHandStats.GetCitizensCount: Integer;
var
  UT: TKMUnitType;
begin
  Result := 0;
  for UT := CITIZEN_MIN to CITIZEN_MAX do
    Inc(Result, GetUnitQty(UT));
end;


//The value includes only citizens, Warriors are counted separately
function TKMHandStats.GetCitizensTrained: Cardinal;
var
  UT: TKMUnitType;
begin
  Result := 0;
  for UT := CITIZEN_MIN to CITIZEN_MAX do
    Inc(Result, Units[UT].Trained);
end;


function TKMHandStats.GetCitizensLost: Cardinal;
var
  UT: TKMUnitType;
begin
  Result := 0;
  for UT := CITIZEN_MIN to CITIZEN_MAX do
    Inc(Result, Units[UT].Lost);
end;


function TKMHandStats.GetCitizensRetired: Cardinal;
var
  UT: TKMUnitType;
begin
  Result := 0;
  for UT := CITIZEN_MIN to CITIZEN_MAX do
    Inc(Result, Units[UT].Retired);
end;


function TKMHandStats.GetCitizensKilled: Cardinal;
var
  UT: TKMUnitType;
begin
  Result := 0;
  for UT := CITIZEN_MIN to CITIZEN_MAX do
    Inc(Result, Units[UT].Killed);
end;


function TKMHandStats.GetHousesBuilt: Cardinal;
var
  HT: TKMHouseType;
begin
  Result := 0;
  for HT := HOUSE_MIN to HOUSE_MAX do
    Inc(Result, Houses[HT].Built);
end;


function TKMHandStats.GetHousesLost: Cardinal;
var
  HT: TKMHouseType;
begin
  Result := 0;
  for HT := HOUSE_MIN to HOUSE_MAX do
    Inc(Result, Houses[HT].Lost);
end;


function TKMHandStats.GetHousesDestroyed: Cardinal;
var
  HT: TKMHouseType;
begin
  Result := 0;
  for HT := HOUSE_MIN to HOUSE_MAX do
    Inc(Result, Houses[HT].Destroyed);
end;


//The value includes all Warriors
function TKMHandStats.GetWarriorsTrained: Cardinal;
var
  UT: TKMUnitType;
begin
  Result := 0;
  for UT := WARRIOR_MIN to WARRIOR_MAX do
    Inc(Result, Units[UT].Trained);
end;


function TKMHandStats.GetWarriorsTotal(aWarriorType: TKMUnitType): Cardinal;
begin
  Result := Units[aWarriorType].Initial + Units[aWarriorType].Trained;
end;


function TKMHandStats.GetWarriorsLost: Cardinal;
var
  UT: TKMUnitType;
begin
  Result := 0;
  for UT := WARRIOR_MIN to WARRIOR_MAX do
    Inc(Result, Units[UT].Lost);
end;


function TKMHandStats.GetWarriorsKilled: Cardinal;
var
  UT: TKMUnitType;
begin
  Result := 0;
  for UT := WARRIOR_MIN to WARRIOR_MAX do
    Inc(Result, Units[UT].Killed);
end;


function TKMHandStats.GetWaresProduced(aRT: TKMWareType): Cardinal;
var
  WT: TKMWareType;
begin
  Result := 0;
  case aRT of
    wtNone:    ;
    wtAll:     for WT := WARE_MIN to WARE_MAX do
                  Inc(Result, Wares[WT].Produced);
    wtWarfare: for WT := WARFARE_MIN to WARFARE_MAX do
                  Inc(Result, Wares[WT].Produced);
  else
    Result := Wares[aRT].Produced;
  end;
end;


//Everything except weapons
function TKMHandStats.GetCivilProduced: Cardinal;
var
  WT: TKMWareType;
begin
  Result := 0;
  for WT := WARE_MIN to WARE_MAX do
  if not (WT in [WEAPON_MIN..WEAPON_MAX]) then
    Inc(Result, Wares[WT].Produced);
end;


//KaM includes all weapons and armor, but not horses
function TKMHandStats.GetWeaponsProduced: Cardinal;
var
  WT: TKMWareType;
begin
  Result := 0;
  for WT := WEAPON_MIN to WEAPON_MAX do
    Inc(Result, Wares[WT].Produced);
end;


function TKMHandStats.GetWarfareProduced: Cardinal;
var
  WT: TKMWareType;
begin
  Result := 0;
  for WT := WARFARE_MIN to WARFARE_MAX do
    Inc(Result, Wares[WT].Produced);
end;


function TKMHandStats.GetChartWares(aWare: TKMWareType): TKMCardinalArray;
var
  I: Integer;
  WT: TKMWareType;
begin
  case aWare of
    WARE_MIN..
    WARE_MAX:   Result := fChartWares[aWare];
    wtAll:      begin
                  //Create new array and fill it (otherwise we assign pointers and corrupt data)
                  SetLength(Result, fChartCount);
                  for I := 0 to fChartCount - 1 do
                    Result[I] := 0;
                  for WT := WARE_MIN to WARE_MAX do
                  for I := 0 to fChartCount - 1 do
                    Result[I] := Result[I] + fChartWares[WT][I];
                end;
    wtWarfare:  begin
                  //Create new array and fill it (otherwise we assign pointers and corrupt data)
                  SetLength(Result, fChartCount);
                  for I := 0 to fChartCount - 1 do
                    Result[I] := 0;
                  for WT := WARFARE_MIN to WARFARE_MAX do
                  for I := 0 to fChartCount - 1 do
                    Result[I] := Result[I] + fChartWares[WT][I];
                end;
    wtFood:     begin
                  //Create new array and fill it (otherwise we assign pointers and corrupt data)
                  SetLength(Result, fChartCount);
                  for I := 0 to fChartCount - 1 do
                    Result[I] := fChartWares[wtBread][I] + fChartWares[wtSausage][I] + fChartWares[wtWine][I] + fChartWares[wtFish][I];
                end;
  else
    //Return empty array
    SetLength(Result, fChartCount);
    for I := 0 to fChartCount - 1 do
      Result[I] := 0;
  end;
end;


function TKMHandStats.GetChartArmy(aChartKind: TKMChartArmyKind; aWarrior: TKMUnitType): TKMCardinalArray;
var
  WT: TKMUnitType;
  I: Integer;
begin
  case aWarrior of
    WARRIOR_MIN..
    WARRIOR_MAX:  Result := fChartArmy[aChartKind,aWarrior];
    utAny:        begin
                    //Create new array and fill it (otherwise we assign pointers and corrupt data)
                    SetLength(Result, fChartCount);
                    for I := 0 to fChartCount - 1 do
                      Result[I] := 0;
                    for WT := WARRIOR_MIN to WARRIOR_MAX do
                      for I := 0 to fChartCount - 1 do
                        Result[I] := Result[I] + fChartArmy[aChartKind,WT,I];
                  end;
  else
    //Return empty array
    SetLength(Result, fChartCount);
    for I := 0 to fChartCount - 1 do
      Result[I] := 0;
  end;
end;


function TKMHandStats.ChartWaresEmpty(aWare: TKMWareType): Boolean;
var
  WT: TKMWareType;
begin
  case aWare of
    WARE_MIN..
    WARE_MAX:   Result := (fChartCount = 0) or (ChartWares[aWare][fChartCount-1] = 0);
    wtAll:      begin
                  Result := True;
                  if fChartCount > 0 then
                    for WT := WARE_MIN to WARE_MAX do
                      if ChartWares[WT][fChartCount-1] <> 0 then
                        Exit(False);
                end;
    wtWarfare:  begin
                  Result := True;
                  if fChartCount > 0 then
                    for WT := WARFARE_MIN to WARFARE_MAX do
                      if ChartWares[WT][fChartCount-1] <> 0 then
                        Exit(False);
                end;
    wtFood:     Result := (fChartCount = 0) or
                            (ChartWares[wtWine][fChartCount-1] +
                            ChartWares[wtBread][fChartCount-1] +
                            ChartWares[wtSausage][fChartCount-1] +
                            ChartWares[wtFish][fChartCount-1] = 0);
  else
    Result := True;
  end;
end;


function GetArmyEmptyCKind(aChartKind: TKMChartArmyKind): TKMChartArmyKind;
begin
  //Total and Instantaneous are always empty at the same time, so we can use only one of them
  //Important is that Total will be not empty even after game load, but instantenious could be empty after load.
  //That is why we can omit saving fArmyEmpty array, and need to use Total instead of Instantenious for fArmyEmpty
  if aChartKind = cakInstantaneous then
    Result := cakTotal
  else
    Result := aChartKind;
end;


function TKMHandStats.ChartArmyEmpty(aChartKind: TKMChartArmyKind; aWarrior: TKMUnitType): Boolean;
var
  WT: TKMUnitType;
  CKind: TKMChartArmyKind;
begin
  CKind := GetArmyEmptyCKind(aChartKind);
  case aWarrior of
    WARRIOR_MIN..
    WARRIOR_MAX:  Result := (fChartCount = 0) or (fArmyEmpty[CKind,aWarrior]);
    utAny:        begin
                    Result := True;
                    if fChartCount > 0 then
                      for WT := WARRIOR_MIN to WARRIOR_MAX do
                        if not fArmyEmpty[CKind,WT] then
                          Exit(False);
                  end;
  else
    Result := True;
  end;
end;


procedure TKMHandStats.Save(SaveStream: TKMemoryStream);
var
  WT: TKMWareType;
  UT: TKMUnitType;
  CKind: TKMChartArmyKind;
begin
  SaveStream.PlaceMarker('PlayerStats');
  SaveStream.Write(Houses, SizeOf(Houses));
  SaveStream.Write(Units, SizeOf(Units));
  SaveStream.Write(Wares, SizeOf(Wares));
  fWareDistribution.Save(SaveStream);

  SaveStream.Write(fChartCount);
  if fChartCount <> 0 then
  begin
    SaveStream.Write(fChartHouses[0], SizeOf(fChartHouses[0]) * fChartCount);
    SaveStream.Write(fChartCitizens[0], SizeOf(fChartCitizens[0]) * fChartCount);

    for WT := WARE_MIN to WARE_MAX do
      SaveStream.Write(fChartWares[WT][0], SizeOf(fChartWares[WT][0]) * fChartCount);

    for CKind := Low(TKMChartArmyKind) to High(TKMChartArmyKind) do
      for UT := WARRIOR_MIN to WARRIOR_MAX do
        SaveStream.Write(fChartArmy[CKind,UT,0], SizeOf(fChartArmy[CKind,UT,0]) * fChartCount);

    SaveStream.Write(fArmyEmpty, SizeOf(fArmyEmpty));
  end;
end;


procedure TKMHandStats.Load(LoadStream: TKMemoryStream);
var
  WT: TKMWareType;
  UT: TKMUnitType;
  CKind: TKMChartArmyKind;
begin
  LoadStream.CheckMarker('PlayerStats');
  LoadStream.Read(Houses, SizeOf(Houses));
  LoadStream.Read(Units, SizeOf(Units));
  LoadStream.Read(Wares, SizeOf(Wares));
  fWareDistribution.Load(LoadStream);

  LoadStream.Read(fChartCount);

  if fChartCount <> 0 then
  begin
    fChartCapacity := fChartCount;
    SetLength(fChartHouses, fChartCount);
    SetLength(fChartCitizens, fChartCount);
    LoadStream.Read(fChartHouses[0], SizeOf(fChartHouses[0]) * fChartCount);
    LoadStream.Read(fChartCitizens[0], SizeOf(fChartCitizens[0]) * fChartCount);

    for WT := WARE_MIN to WARE_MAX do
    begin
      SetLength(fChartWares[WT], fChartCount);
      LoadStream.Read(fChartWares[WT][0], SizeOf(fChartWares[WT][0]) * fChartCount);
    end;

    for CKind := Low(TKMChartArmyKind) to High(TKMChartArmyKind) do
      for UT := WARRIOR_MIN to WARRIOR_MAX do
      begin
        SetLength(fChartArmy[CKind,UT], fChartCount);
        LoadStream.Read(fChartArmy[CKind,UT,0], SizeOf(fChartArmy[CKind,UT,0]) * fChartCount);
      end;

    LoadStream.Read(fArmyEmpty, SizeOf(fArmyEmpty));
  end;
end;


procedure TKMHandStats.ToCSV(aStrings: TStringList);
begin
  HousesToCSV(aStrings);
  aStrings.Append('');
  UnitsToCSV(aStrings);
  aStrings.Append('');
  WaresToCSV(aStrings);
end;


procedure TKMHandStats.HousesToCSV(aStrings: TStringList);
var
  HT: TKMHouseType;
begin
  aStrings.Append('Houses stats');
  aStrings.Append('Name;Planned;PlanRemoved;Started;Ended;Initial;Built;SelfDestruct;Lost;ClosedATM;Destroyed');

  for HT := HOUSE_MIN to HOUSE_MAX do
    if HT <> htSiegeWorkshop then
      with Houses[HT] do
        aStrings.Append(Format('%s;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;', [gRes.Houses[HT].HouseName,
          Planned, PlanRemoved, Started, Ended, Initial, Built, SelfDestruct, Lost, Closed, Destroyed]));
end;


procedure TKMHandStats.UnitsToCSV(aStrings: TStringList);
var
  UT: TKMUnitType;
begin
  aStrings.Append('Units stats');
  aStrings.Append('Name;Initial;TrainingATM;Dismissing;Trained;Lost;Killed');

  for UT := HUMANS_MIN to HUMANS_MAX do
    with Units[UT] do
      aStrings.Append(Format('%s;%d;%d;%d;%d;%d;%d;', [gRes.Units[UT].GUIName, Initial, Training, Dismissing, Trained, Lost, Killed]));
end;


procedure TKMHandStats.WaresToCSV(aStrings: TStringList);
var
  WT: TKMWareType;
begin
  aStrings.Append('Wares stats');
  aStrings.Append('Name;Initial;Produced;Consumed');

  for WT := WARE_MIN to WARE_MAX do
    with Wares[WT] do
      aStrings.Append(Format('%s;%d;%d;%d;', [gRes.Wares[WT].Title, Initial, Produced, Consumed]));
end;


function TKMHandStats.GetArmyChartValue(aChartKind: TKMChartArmyKind; aUnitType: TKMUnitType): Integer;
begin
  case aChartKind of
    cakInstantaneous:  Result := GetUnitQty(aUnitType);
    cakTotal:          Result := GetWarriorsTotal(aUnitType);
    cakDefeated:       Result := GetUnitKilledQty(aUnitType);
    cakLost:           Result := GetUnitLostQty(aUnitType);
  else
    raise Exception.Create('Unknown chart army kind');
  end;
end;


procedure TKMHandStats.UpdateState;
var
  I: TKMWareType;
  W: TKMUnitType;
  armyQty: Integer;
  CKind, armyEmptyCKind: TKMChartArmyKind;
begin
  //Store player stats in Chart

  //Grow the list
  if fChartCount >= fChartCapacity then
  begin
    fChartCapacity := fChartCount + 32;
    SetLength(fChartHouses, fChartCapacity);
    SetLength(fChartCitizens, fChartCapacity);
    for I := WARE_MIN to WARE_MAX do
      SetLength(fChartWares[I], fChartCapacity);
    for CKind := Low(TKMChartArmyKind) to High(TKMChartArmyKind) do
      for W := WARRIOR_MIN to WARRIOR_MAX do
        SetLength(fChartArmy[CKind,W], fChartCapacity);
  end;
  fChartHouses[fChartCount] := GetHouseQty(htAny);
  //We don't want recruits on the citizens Chart on the results screen.
  //If we include recruits the citizens Chart drops by 50-100 at peacetime because all the recruits
  //become soldiers, and continually fluctuates. Recruits dominate the Chart, meaning you can't use
  //it for the intended purpose of looking at your villagers. The army Chart already indicates when
  //you trained soldiers, no need to see big variations in the citizens Chart because of recruits.
  fChartCitizens[fChartCount] := GetCitizensCount - GetUnitQty(utRecruit);

  for I := WARE_MIN to WARE_MAX do
    fChartWares[I, fChartCount] := Wares[I].Produced;

  for CKind := Low(TKMChartArmyKind) to High(TKMChartArmyKind) do
    for W := WARRIOR_MIN to WARRIOR_MAX do
    begin
      armyQty := GetArmyChartValue(CKind,W);
      fChartArmy[CKind, W, fChartCount] := armyQty;
      // for Army empty we use special CKind, because Total equipped and Instantenious are empty simultaneously
      armyEmptyCKind := GetArmyEmptyCKind(CKind);
      if (fArmyEmpty[armyEmptyCKind,W] and (armyQty > 0)) then
        fArmyEmpty[armyEmptyCKind,W] := False;
    end;

  Inc(fChartCount);
end;


end.
