unit KM_Test_Hungarian;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMRunnerTestHungarian = class(TKMTest)
  protected
    function OnTickCondition(aTick: Cardinal): Boolean; override;
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
  end;

implementation
uses
  Windows, SysUtils, Classes, Math,
  Generics.Collections, Generics.Defaults,
  KM_CommonClasses, KM_Defaults, KM_Points, KM_CommonUtils,
  KM_GameApp, KM_Log, KM_HandsCollection, KM_HouseCollection, KM_Resource,
  KM_Terrain, KM_Units, KM_Campaigns, KM_Houses,
  KM_GameParams,
  KM_Exceptions,
  KM_UnitActionWalkTo, KM_UnitWarrior,
  KM_CampaignTypes,
  KM_HandSpectator, KM_ResHouses, KM_Hand, KM_HandTypes, KM_UnitsCollection, KM_UnitGroup,
  KM_GameSettings,
  KM_CommonTypes, KM_MapTypes, KM_FileIO, KM_Game, KM_GameInputProcess, KM_GameTypes, KM_InterfaceGame,
  KM_UnitGroupTypes,
  KM_ResTypes, KM_CampaignClasses, KM_Hungarian;

{ TKMRunnerTestHungarian }
procedure TKMRunnerTestHungarian.SetUp;
begin
  inherited;
  fResults.ValueCount := 0;
  DYNAMIC_TERRAIN := False;
  SHOW_UNIT_ROUTES := True;
  //SHOW_UNIT_ROUTES_STEPS := True;

  gGameApp.NewEmptyMap(64, 64);

  if gGame.ActiveInterface <> nil then
  begin
    gGame.ActiveInterface.Viewport.Zoom := 0.5;
    gGame.ActiveInterface.Viewport.Position := KMPointF(
      32,
      19
    );
  end;
    gHands[0].AddField(KMPoint(45, 19), ftCorn, 0, False, True);
    gHands[0].AddField(KMPoint(19, 19), ftCorn, 0, False, True);
//  gHands[0].AddField(KMPoint(45, 21), ftCorn, 0, False, True);
//  gHands[0].AddField(KMPoint(40, 34), ftCorn, 0, False, True);

  // Group 1: 30 * 7 = 210 units
  gHands[0].AddUnitGroup(utBowman, KMPoint(32, 30), TKMDirection(dirN), 30, 210);

  // Group 2: 30 * 7 = 210 units, 5 cells apart (started at Y=15, dirS means facing south)
  gHands[1].AddUnitGroup(utBowman, KMPoint(32, 20), TKMDirection(dirS), 30, 210);
end;

function TKMRunnerTestHungarian.OnTickCondition(aTick: Cardinal): Boolean;
var
  iH: Integer;
  iG: Integer;
  iM: Integer;
  distance: Integer;
  warrior: TKMUnitWarrior;
  action: TKMUnitActionWalkTo;
begin
  // Continue simulation (True) until one of armies are destroyed
  Result := (gHands[0].Stats.GetUnitQty(utAny) > 0)
    and (gHands[1].Stats.GetUnitQty(utAny) > 0);

  if not Result then
    Exit;

  for iH := 0 to 1 do
    for iG := 0 to gHands[iH].UnitGroups.Count - 1 do
      for iM := 0 to gHands[iH].UnitGroups.Groups[iG].Count - 1 do
        begin
          warrior := gHands[iH].UnitGroups.Groups[iG].Members[iM];
//          if not KMSamePoint(warrior.PositionNext, warrior.Position) then
          if warrior.Action is TKMUnitActionWalkTo then
          begin
            action := TKMUnitActionWalkTo(warrior.Action);
            distance := KMDistanceAbs(action.WalkFrom, action.WalkTo);
            //if distance > 10 then

              //raise ETestFailed.Create('bug found');
          end;
        end;

end;

procedure TKMRunnerTestHungarian.Execute(aRun: Integer);
var
  Group1, Group2: TKMUnitGroup;
  I: Integer;
  Agents, Tasks: TKMPointList;
  NewOrder: TKMCardinalArray;
  MaxDist, Dist: Single;
begin
  SetKaMSeed(aRun + 1);

  SimulateGame;

//  // We want to test that if we merge them, the new tasks (formations)
//  // will force some unit to walk more than 5 cells distance.
//  Agents := TKMPointList.Create;
//  Tasks := TKMPointList.Create;
//
//  try
//    // Populate agents with actual positions from both groups
//    for I := 0 to Group1.Count - 1 do
//      Agents.Add(Group1.Members[I].Position);
//
//    for I := 0 to Group2.Count - 1 do
//      Agents.Add(Group2.Members[I].Position);
//
//    // Populate tasks - a 30x14 block at Group1's position
//    for I := 0 to Agents.Count - 1 do
//    begin
//      // A simple representation of target formation (30 units per row, from 32,20)
//      // Note: Group1 is facing South (dirS).
//      // X = 32 - 15 + (I mod 30)
//      // Y = 20 - (I div 30)
//      // This matches roughly what GetMemberLoc does for a 30-width group.
//      Tasks.Add(KMPoint(32 - 15 + (I mod 30), 20 - (I div 30)));
//    end;
//
//    // Use THungarianOptimisation huIndividual
//    NewOrder := HungarianMatchPoints(Tasks, Agents, huIndividual);
//
//    MaxDist := 0;
//    for I := 0 to Agents.Count - 1 do
//    begin
//      Dist := KMLength(Agents[NewOrder[I]], Tasks[I]);
//      if Dist > MaxDist then
//        MaxDist := Dist;
//    end;
//
//    AssertTrue(MaxDist >= 5.0, Format('Expected some unit to walk >= 5 cells, but max dist was %.2f', [MaxDist]));
//
//  finally
//    Agents.Free;
//    Tasks.Free;
//  end;

  gGameApp.StopGame(grSilent);
end;

initialization
  RegisterTest(TKMRunnerTestHungarian);
end.
