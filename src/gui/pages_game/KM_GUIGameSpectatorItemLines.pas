unit KM_GUIGameSpectatorItemLines;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, StrUtils, SysUtils,
  KM_GUIGameSpectator, KM_Controls,
  KM_HandsCollection, KM_Defaults, KM_Hand,
  KM_ResHouses, KM_Pics, KM_CommonTypes, KM_Points, KM_Houses;


type
  TKMGUIGameSpectatorItemLineResources = class(TKMGUIGameSpectatorItemLine)
  protected
    function CreateItem(aHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem; override;
    function GetTagCount: Integer; override;
    function GetTag(AIndex: Integer): Integer; override;
    function GetValue(aHandIndex: Integer; ATag: Integer): String; override;
  end;


  TKMGUIGameSpectatorItemLineWarfare = class(TKMGUIGameSpectatorItemLine)
  private
    class function GetIcon(aTag: Integer): Word;
    class function GetTitle(aTag: Integer): UnicodeString;
  protected
    function CreateItem(aHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem; override;
    function GetTagCount: Integer; override;
    function GetTag(AIndex: Integer): Integer; override;
    function GetValue(aHandIndex: Integer; ATag: Integer): String; override;
  end;

  // Buildings
  TKMGUIGameSpectatorItemLineCustomBuildings = class(TKMGUIGameSpectatorItemLine)
  private
    fHouseSketch: TKMHouseSketchEdit;
    fLastHouseUIDs: array [HOUSE_MIN..HOUSE_MAX] of Cardinal;
    procedure ResetUIDs;
    function CheckHighlight(aIndex: Integer): Boolean;
  protected
    function CreateItem(aHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem; override;
    function GetTagCount: Integer; override;
    function GetTag(AIndex: Integer): Integer; override;
    function GetNextLoc(aHandIndex: Integer; ATag: Integer; aMainFunction: Boolean): TKMPointF; override;
    function GetVerifyHouseSketchFn: TAnonHouseSketchBoolFn; virtual; abstract;
  public
    constructor Create(aParent: TKMPanel; aHandIndex: Integer; aOnJumpToPlayer: TIntegerEvent; aSetViewportPos: TPointFEvent;
                       aLinesAggregator: TKMGameSpectatorItemLinesAggregator = nil); override;
    destructor Destroy; override;
  end;

  TKMGUIGameSpectatorItemLineConstructing = class(TKMGUIGameSpectatorItemLineCustomBuildings)
  protected
    function GetValue(aHandIndex: Integer; ATag: Integer): String; override;
    function GetAdditionalValue(aHandIndex: Integer; ATag: Integer): String; override;
    function GetProgress(aHandIndex: Integer; ATag: Integer): Single; override;
    function GetVerifyHouseSketchFn: TAnonHouseSketchBoolFn; override;
  end;

  TKMGUIGameSpectatorItemLineHouses = class(TKMGUIGameSpectatorItemLineCustomBuildings)
  protected
    function CreateItem(aHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem; override;
    function GetValue(aHandIndex: Integer; ATag: Integer): String; override;
    function GetAdditionalValue(aHandIndex: Integer; ATag: Integer): String; override;
    function GetProgress(aHandIndex: Integer; ATag: Integer): Single; override;
    function GetVerifyHouseSketchFn: TAnonHouseSketchBoolFn; override;
  end;

  // Units
  TKMGUIGameSpectatorItemLinePopulation = class(TKMGUIGameSpectatorItemLine)
  protected
    function CreateItem(aHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem; override;
//    function GetTagCount: Integer; override;
//    function GetTag(AIndex: Integer): Integer; override;
    function GetValue(aHandIndex: Integer; ATag: Integer): String; override;
  end;

  TKMGUIGameSpectatorItemLinePopulationSLR = class(TKMGUIGameSpectatorItemLinePopulation)
  protected
    function GetTagCount: Integer; override;
    function GetTag(AIndex: Integer): Integer; override;
  end;

  TKMGUIGameSpectatorItemLinePopulationHouseWorkers = class(TKMGUIGameSpectatorItemLinePopulation)
  protected
    function GetTagCount: Integer; override;
    function GetTag(AIndex: Integer): Integer; override;
  end;

  TKMGUIGameSpectatorItemLineArmy = class(TKMGUIGameSpectatorItemLine)
  private
    fLastWarriorUIDs: array [WARRIOR_MIN..WARRIOR_MAX] of Cardinal;
    procedure ResetUIDs;
  protected
    function CreateItem(aHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem; override;
    function GetTagCount: Integer; override;
    function GetTag(AIndex: Integer): Integer; override;
    function GetNextLoc(aHandIndex: Integer; ATag: Integer; aMainFunction: Boolean): TKMPointF; override;
    function CheckHighlight(aIndex: Integer): Boolean; virtual;
  end;

  TKMGUIGameSpectatorItemLineArmyInstantenious = class(TKMGUIGameSpectatorItemLineArmy)
  protected
    function GetValue(aHandIndex: Integer; ATag: Integer): String; override;
    function CheckHighlight(aIndex: Integer): Boolean; override;
  end;

  TKMGUIGameSpectatorItemLineArmyTotal = class(TKMGUIGameSpectatorItemLineArmy)
  protected
    function GetValue(aHandIndex: Integer; ATag: Integer): String; override;
  end;

  TKMGUIGameSpectatorItemLineArmyKilling = class(TKMGUIGameSpectatorItemLineArmy)
  protected
    function GetValue(aHandIndex: Integer; ATag: Integer): String; override;
  end;

  TKMGUIGameSpectatorItemLineArmyLost = class(TKMGUIGameSpectatorItemLineArmy)
  protected
    function GetValue(aHandIndex: Integer; ATag: Integer): String; override;
  end;

implementation
uses
  KM_Entity,
  KM_Game, KM_HandTypes, KM_HandEntity,
  KM_InterfaceGamePlay, KM_InterfaceGame,
  KM_Resource,
  KM_UnitGroup, KM_HouseTownHall,
  KM_ResUnits, KM_ResTypes;


{ TKMGUIGameSpectatorItemLineResources }
function TKMGUIGameSpectatorItemLineResources.CreateItem(aHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem;
begin
  Result := TKMGUIGameSpectatorItem.Create(Self, ATag, gRes.Wares[TKMWareType(ATag)].GUIIcon, gRes.Wares[TKMWareType(ATag)].Title,
                                           aHandIndex, icBarColorGreen, DontHighlight, aOnItemClick);
  Result.Visible := False;
end;


function TKMGUIGameSpectatorItemLineResources.GetTagCount: Integer;
begin
  Result := WARE_CNT - WARFARE_CNT; //Do not show Warfare on resources page
end;


function TKMGUIGameSpectatorItemLineResources.GetTag(AIndex: Integer): Integer;
begin
  if AIndex = 0 then
    Result := Ord(wtFish)
  else
    Result := Ord(StoreResType[Length(StoreResType) - AIndex - WARFARE_CNT]); //opposite order, we draw items from the right
end;


function TKMGUIGameSpectatorItemLineResources.GetValue(aHandIndex: Integer; ATag: Integer): String;
var
  value: Integer;
begin
  value := gHands[aHandIndex].Stats.GetWareBalance(TKMWareType(ATag));
  Result := IfThen(value > 0, IntToStr(value));
end;


{ TKMGUIGameSpectatorItemLineWareFare }
const
  RECRUIT_TAG = -1;
  TH_GOLD_CHEST_TAG = -2;

function TKMGUIGameSpectatorItemLineWarfare.CreateItem(aHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem;
begin
  Result := TKMGUIGameSpectatorItem.Create(Self, ATag,
                                           TKMGUIGameSpectatorItemLineWarfare.GetIcon(ATag),
                                           TKMGUIGameSpectatorItemLineWarfare.GetTitle(ATag), aHandIndex,
                                           icBarColorGreen, DontHighlight, aOnItemClick);
  Result.Visible := False;
end;


class function TKMGUIGameSpectatorItemLineWarfare.GetIcon(aTag: Integer): Word;
begin
  if aTag = RECRUIT_TAG then
    Result := gRes.Units[utRecruit].GUIIcon
  else if aTag = TH_GOLD_CHEST_TAG then
    Result := gRes.Wares[wtGold].GUIIcon
  else
    Result := gRes.Wares[TKMWareType(ATag)].GUIIcon;
end;


class function TKMGUIGameSpectatorItemLineWarfare.GetTitle(aTag: Integer): UnicodeString;
begin
  if aTag = RECRUIT_TAG then
    Result := gRes.Units[utRecruit].GUIName
  else if aTag = TH_GOLD_CHEST_TAG then
    Result := gRes.Wares[wtGold].Title
  else
    Result := gRes.Wares[TKMWareType(ATag)].Title;
end;


function TKMGUIGameSpectatorItemLineWarfare.GetTagCount: Integer;
begin
  Result := WARFARE_CNT + 2; //+1 for recruit and +1 for gold chests in TownHall
end;


function TKMGUIGameSpectatorItemLineWarfare.GetTag(AIndex: Integer): Integer;
begin
  if AIndex = 0 then
    Result := RECRUIT_TAG //Recruit
  else if AIndex = 1 then
    Result := TH_GOLD_CHEST_TAG //TH GoldChest
  else
    //Recruit is the last
    Result := Integer(BarracksResType[Length(BarracksResType) - AIndex + 2]); //opposite order, we draw items from the right
end;


function TKMGUIGameSpectatorItemLineWarfare.GetValue(aHandIndex: Integer; ATag: Integer): String;
var
  I, value: Integer;
begin
  if aTag = RECRUIT_TAG then
    value := gHands[aHandIndex].Stats.GetUnitQty(utRecruit)
  else if aTag = TH_GOLD_CHEST_TAG then
  begin
    //Calc gold in all Townhalls (let's think its 'Warfare')
    value := 0;
    with gHands[aHandIndex].Houses do
      for I := 0 to Count - 1 do
      begin
        if Houses[I].HouseType = htTownHall then
          Inc(value, TKMHouseTownHall(Houses[I]).GoldCnt);
      end;
  end else
    value := gHands[aHandIndex].Stats.GetWareBalance(TKMWareType(ATag));

  Result := IfThen(value > 0, IntToStr(value));
end;


{ TKMGUIGameSpectatorItemLineCustomBuildings }
constructor TKMGUIGameSpectatorItemLineCustomBuildings.Create(aParent: TKMPanel; aHandIndex: Integer;
                                                              aOnJumpToPlayer: TIntegerEvent; aSetViewportPos: TPointFEvent;
                                                              aLinesAggregator: TKMGameSpectatorItemLinesAggregator = nil);
begin
  inherited Create(aParent, aHandIndex, aOnJumpToPlayer, aSetViewportPos, aLinesAggregator);

  fHouseSketch := TKMHouseSketchEdit.Create;
end;


destructor TKMGUIGameSpectatorItemLineCustomBuildings.Destroy;
begin
  FreeAndNil(fHouseSketch);

  inherited;
end;


function TKMGUIGameSpectatorItemLineCustomBuildings.CreateItem(aHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem;
begin
  Result := TKMGUIGameSpectatorItem.Create(Self, ATag,
                                           gRes.Houses[TKMHouseType(ATag)].GUIIcon,
                                           gRes.Houses[TKMHouseType(ATag)].HouseName, aHandIndex,
                                           icBarColorGreen, CheckHighlight, aOnItemClick);
  Result.Visible := False;
  ResetUIDs;
end;


function TKMGUIGameSpectatorItemLineCustomBuildings.CheckHighlight(aIndex: Integer): Boolean;
begin
  Result := (GetValue(HandIndex, aIndex) <> '') or
            (GetAdditionalValue(HandIndex, aIndex) <> '');
end;


function TKMGUIGameSpectatorItemLineCustomBuildings.GetTagCount: Integer;
begin
  Result := HOUSES_CNT - 1; //-1 for htSiegeWorkshop
end;


function TKMGUIGameSpectatorItemLineCustomBuildings.GetTag(AIndex: Integer): Integer;
begin
  Result := Integer(GUIHouseOrder[Length(GUIHouseOrder) - AIndex]); //opposite order, we draw items from the right
end;


procedure TKMGUIGameSpectatorItemLineCustomBuildings.ResetUIDs;
var
  HT: TKMHouseType;
begin
  for HT := Low(fLastHouseUIDs) to High(fLastHouseUIDs) do
    fLastHouseUIDs[HT] := 0;
end;


function TKMGUIGameSpectatorItemLineCustomBuildings.GetNextLoc(aHandIndex: Integer; ATag: Integer; aMainFunction: Boolean): TKMPointF;
var
  I: Integer;
  H: TKMHouse;
  HT: TKMHouseType;
  hasDamagedHouses: Boolean;
begin
  Result := KMPOINTF_INVALID_TILE;

  HT := TKMHouseType(ATag);

  hasDamagedHouses := False;
  for I := 0 to gHands[aHandIndex].Houses.Count - 1 do
    if gHands[aHandIndex].Houses[I].GetDamage > 0 then
    begin
      hasDamagedHouses := True;
      Break;
    end;

  //MainFunction - Left MB, Right MB
  //LMB - show only damaged houses or all houses
  //RMB - show all houses
  gHands[aHandIndex].GetNextHouseWSameType(HT, fLastHouseUIDs[HT], fHouseSketch, [hstHouse, hstHousePlan],
                                           GetVerifyHouseSketchFn(), hasDamagedHouses and aMainFunction);
  if not fHouseSketch.IsEmpty then
  begin
    gMySpectator.Highlight := fHouseSketch;
    H := gHands[aHandIndex].Houses.GetHouseByUID(fHouseSketch.UID);
    if H <> nil then
      gMySpectator.Selected := H
    else if fHouseSketch.Owner <> HAND_NONE then
    begin
      gMySpectator.Selected := nil; // Unselect previous house / entity / etc
      gMySpectator.HandId := fHouseSketch.Owner;
    end;

    gMySpectator.UpdateSelect(False);
    TKMGamePlayInterface(gGame.ActiveInterface).UpdateReplayView;

    Result := KMPointF(fHouseSketch.Entrance); //get position on that house
    fLastHouseUIDs[HT] := fHouseSketch.UID;
  end;
end;


{ TKMGUIGameSpectatorItemLineBuild }
function TKMGUIGameSpectatorItemLineConstructing.GetValue(aHandIndex: Integer; ATag: Integer): String;
var
  value: Integer;
begin
  value := gHands[aHandIndex].Stats.GetHouseRdyToBeBuilt(TKMHouseType(ATag));
  Result := IfThen(value > 0, IntToStr(value));
end;


function TKMGUIGameSpectatorItemLineConstructing.GetAdditionalValue(aHandIndex: Integer; ATag: Integer): String;
var
  value: Integer;
begin
  value := gHands[aHandIndex].Stats.GetHouseWip(TKMHouseType(ATag)) - gHands[aHandIndex].Stats.GetHouseRdyToBeBuilt(TKMHouseType(ATag));
  Result := IfThen(value > 0, '+' + IntToStr(value));
end;


function TKMGUIGameSpectatorItemLineConstructing.GetProgress(aHandIndex: Integer; ATag: Integer): Single;
var
  I: Integer;
  house, houseProgress: TKMHouse;
  houseType: TKMHouseType;
begin
  Result := inherited;
  if GetValue(aHandIndex, ATag) = '' then
    Exit;

  houseType := TKMHouseType(ATag);
  houseProgress := nil;
  for I := 0 to gHands[aHandIndex].Houses.Count - 1 do
  begin
    house := gHands[aHandIndex].Houses[I];
    if (house.HouseType = houseType)
      and (house.BuildingState in [hbsWood, hbsStone])
      and (not Assigned(houseProgress) or (house.BuildingProgress > houseProgress.BuildingProgress)) then
      houseProgress := house;
  end;

  if Assigned(houseProgress) then
    Result := houseProgress.BuildingProgress / houseProgress.MaxHealth;
end;


function ConstructingGetVerifyHouseSketchFnInline(aSketch: TKMHouseSketch; aBoolParam: Boolean): Boolean;
begin
  Result := (aSketch <> nil)
            and (not (aSketch is TKMHouse) or not TKMHouse(aSketch).IsComplete);
end;


function TKMGUIGameSpectatorItemLineConstructing.GetVerifyHouseSketchFn: TAnonHouseSketchBoolFn;
begin
  Result := ConstructingGetVerifyHouseSketchFnInline;
end;


{ TKMGUIGameSpectatorItemLineBuildings }
function TKMGUIGameSpectatorItemLineHouses.CreateItem(aHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem;
begin
  Result := inherited;
end;


function TKMGUIGameSpectatorItemLineHouses.GetValue(aHandIndex: Integer; ATag: Integer): String;
var
  value: Integer;
begin
  value := gHands[aHandIndex].Stats.GetHouseQty(TKMHouseType(ATag));
  Result := IfThen(value > 0, IntToStr(value));
end;


function TKMGUIGameSpectatorItemLineHouses.GetAdditionalValue(aHandIndex: Integer; ATag: Integer): String;
var
  value: Integer;
begin
  value := gHands[aHandIndex].Stats.GetHouseRdyToBeBuilt(TKMHouseType(ATag));
  Result := IfThen(value > 0, '+' + IntToStr(value));
end;


function TKMGUIGameSpectatorItemLineHouses.GetProgress(aHandIndex: Integer; ATag: Integer): Single;
var
  I: Integer;
  house, houseHealth: TKMHouse;
  houseType: TKMHouseType;
begin
  Result := inherited;
  if GetValue(aHandIndex, ATag) = '' then
    Exit;

  houseType := TKMHouseType(ATag);
  houseHealth := nil;
  for I := 0 to gHands[aHandIndex].Houses.Count - 1 do
  begin
    house := gHands[aHandIndex].Houses[I];
    if (house.HouseType = houseType)
      and (house.GetDamage > 0)
      and (not Assigned(houseHealth) or (house.GetDamage > houseHealth.GetDamage)) then
      houseHealth := house;
  end;

  if Assigned(houseHealth) then
    Result := houseHealth.GetHealth / houseHealth.MaxHealth;
end;


function HousesGetVerifyHouseSketchFnInline(aSketch: TKMHouseSketch; aBoolParam: Boolean): Boolean;
begin
  //Show only damaged houses or all houses, depending on param
  //param - do we have damaged houses (on LMB) or RMB (all houses)
  Result := (aSketch <> nil)
            and (not (aSketch is TKMHouse)
              or (TKMHouse(aSketch).GetDamage > 0)
              or not aBoolParam); //Show
end;


function TKMGUIGameSpectatorItemLineHouses.GetVerifyHouseSketchFn: TAnonHouseSketchBoolFn;
begin
  Result := HousesGetVerifyHouseSketchFnInline;
end;


{ TKMGUIGameSpectatorItemLinePopulation }
function TKMGUIGameSpectatorItemLinePopulation.CreateItem(aHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem;
begin
  Result := TKMGUIGameSpectatorItem.Create(Self, ATag,
                                           gRes.Units[TKMUnitType(ATag)].GUIIcon,
                                           gRes.Units[TKMUnitType(ATag)].GUIName, HandIndex,
                                           icBarColorGreen, DontHighlight, aOnItemClick);
end;


//function TKMGUIGameSpectatorItemLinePopulation.GetTagCount: Integer;
//begin
//  Result := CITIZENS_CNT;
//end;
//
//function TKMGUIGameSpectatorItemLinePopulation.GetTag(AIndex: Integer): Integer;
//begin
//  Result := Integer(School_Order[Length(School_Order) - AIndex - 1]); //opposite order, we draw items from the right
//end;


function TKMGUIGameSpectatorItemLinePopulation.GetValue(aHandIndex: Integer; ATag: Integer): String;
var
  value: Integer;
begin
  value := gHands[aHandIndex].Stats.GetUnitQty(TKMUnitType(ATag));
  Result := IfThen(value > 0, IntToStr(value));
end;


{ TKMGUIGameSpectatorItemLinePopulationSLR }
function TKMGUIGameSpectatorItemLinePopulationSLR.GetTagCount: Integer;
begin
  Result := 3; //Serfs / Labourers / Recruits
end;

function TKMGUIGameSpectatorItemLinePopulationSLR.GetTag(AIndex: Integer): Integer;
begin
  Result := -1;
  case AIndex of
    0: Result := Integer(utRecruit);
    1: Result := Integer(utBuilder);
    2: Result := Integer(utSerf);
  end;
  Assert(Result <> -1);
end;


{ TKMGUIGameSpectatorItemLinePopulationHouseWorkers }
function TKMGUIGameSpectatorItemLinePopulationHouseWorkers.GetTagCount: Integer;
begin
  Result := CITIZENS_CNT - 3; // All citizens except Serfs / Labourers / Recruits
end;


function TKMGUIGameSpectatorItemLinePopulationHouseWorkers.GetTag(AIndex: Integer): Integer;
begin
  Result := Integer(School_Order[Length(School_Order)
                                 - 1             //for serf and worker
                                 - AIndex - 1]); //opposite order, we draw items from the right;
end;


{ TKMGUIGameSpectatorItemLineArmy }
function TKMGUIGameSpectatorItemLineArmy.CreateItem(aHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem;
begin
  Result := TKMGUIGameSpectatorItem.Create(Self, ATag,
                                           gRes.Units[TKMUnitType(ATag)].GUIIcon,
                                           gRes.Units[TKMUnitType(ATag)].GUIName, HandIndex,
                                           icBarColorGreen, CheckHighlight, aOnItemClick);
  ResetUIDs;
end;


function TKMGUIGameSpectatorItemLineArmy.CheckHighlight(aIndex: Integer): Boolean;
begin
  Result := gHands[HandIndex].Stats.GetUnitQty(TKMUnitType(aIndex)) > 0;
end;


function TKMGUIGameSpectatorItemLineArmy.GetTagCount: Integer;
begin
  Result := WARRIORS_CNT;
end;


function TKMGUIGameSpectatorItemLineArmy.GetTag(AIndex: Integer): Integer;
begin
  Result := Integer(Soldiers_Order[Length(Soldiers_Order) - AIndex - 1]); //opposite order, we draw items from the right
end;


procedure TKMGUIGameSpectatorItemLineArmy.ResetUIDs;
var
  UT: TKMUnitType;
begin
  for UT := Low(fLastWarriorUIDs) to High(fLastWarriorUIDs) do
    fLastWarriorUIDs[UT] := 0;
end;


function TKMGUIGameSpectatorItemLineArmy.GetNextLoc(aHandIndex: Integer; ATag: Integer; aMainFunction: Boolean): TKMPointF;
var
  nextGroup: TKMUnitGroup;
  UT: TKMUnitType;
begin
  Result := KMPOINTF_INVALID_TILE;

  UT := TKMUnitType(ATag);

  nextGroup := gHands[aHandIndex].GetNextGroupWSameType(UT, fLastWarriorUIDs[UT]);
  if nextGroup <> nil then
  begin
    gMySpectator.Selected := nextGroup;
    gMySpectator.UpdateSelect(False);
    TKMGamePlayInterface(gGame.ActiveInterface).UpdateReplayView;

    Result := nextGroup.FlagBearer.PositionF; //get position on that warrior
    fLastWarriorUIDs[UT] := nextGroup.UID;
  end;
end;


{ TKMGUIGameSpectatorItemLineArmyInstantenious }
function TKMGUIGameSpectatorItemLineArmyInstantenious.GetValue(aHandIndex: Integer; ATag: Integer): String;
var
  value: Integer;
begin
  value := gHands[aHandIndex].Stats.GetUnitQty(TKMUnitType(ATag));
  Result := IfThen(value > 0, IntToStr(value));
end;


function TKMGUIGameSpectatorItemLineArmyInstantenious.CheckHighlight(aIndex: Integer): Boolean;
begin
  Result := True; //We always have soldiers to set viewport on
end;


{ TKMGUIGameSpectatorItemLineArmyTotal }
function TKMGUIGameSpectatorItemLineArmyTotal.GetValue(aHandIndex: Integer; ATag: Integer): String;
var
  value: Integer;
begin
  value := gHands[aHandIndex].Stats.GetWarriorsTotal(TKMUnitType(ATag));
  Result := IfThen(value > 0, IntToStr(value));
end;


{ TKMGUIGameSpectatorItemLineArmyKilling }
function TKMGUIGameSpectatorItemLineArmyKilling.GetValue(aHandIndex: Integer; ATag: Integer): String;
var
  value: Integer;
begin
  value := gHands[aHandIndex].Stats.GetUnitKilledQty(TKMUnitType(ATag));
  Result := IfThen(value > 0, IntToStr(value));
end;


{ TKMGUIGameSpectatorItemLineArmyLost }
function TKMGUIGameSpectatorItemLineArmyLost.GetValue(aHandIndex: Integer; ATag: Integer): String;
var
  value: Integer;
begin
  value := gHands[aHandIndex].Stats.GetUnitLostQty(TKMUnitType(ATag));
  Result := IfThen(value > 0, IntToStr(value));
end;


end.
