unit KM_Test_MeleeEngagedJoiningFight;

{$I KaM_Remake.inc}
interface
uses
  KM_Test,
  KM_UnitWarrior;

type
  TKMTest_MeleeEngagedJoiningFight = class(TKMTest)
  protected
    procedure SetUp; override;
    procedure DoTick(aTick: Cardinal; var aKeepGoing: Boolean); override;
    procedure TearDown; override;
  public
    class function TestTags: TKMTestTagSet; override;
    class function TestDescription: string; override;
  end;


implementation
uses
  KM_Defaults,
  KM_GameApp, KM_HandsCollection, KM_HandTypes, KM_Terrain, KM_Points,
  KM_UnitGroupTypes;


procedure TKMTest_MeleeEngagedJoiningFight.SetUp;
begin
  inherited;

  //All soldiers should be in fight at this time.
  fDuration := 30;

  gGameApp.NewGameEmptyMap(32, 32);

  DYNAMIC_TERRAIN := False;

  if gGameApp.Game.ActiveInterface <> nil then
    gGameApp.Game.ActiveInterface.Viewport.Zoom := 0.8;

  gHands[0].HandType := hndHuman;
  gHands[1].HandType := hndHuman;

  //First line.
  gHands[0].AddUnitGroup(utKnight, TKMPoint.New(9, 13), dirE, 1, 1);
  gHands[1].AddUnitGroup(utKnight, TKMPoint.New(10, 13), dirW, 2, 2);
  gTerrain.SetObject(TKMPoint.New(10, 14), 94);

  gHands[0].AddUnitGroup(utKnight, TKMPoint.New(13, 13), dirS, 1, 1);
  gHands[1].AddUnitGroup(utKnight, TKMPoint.New(14, 14), dirN, 2, 2);
  gTerrain.SetObject(TKMPoint.New(14, 14), 94);

  gHands[0].AddUnitGroup(utKnight, TKMPoint.New(18, 13), dirW, 1, 1);
  gHands[1].AddUnitGroup(utKnight, TKMPoint.New(17, 14), dirE, 2, 2);
  gTerrain.SetObject(TKMPoint.New(18, 14), 94);

  gHands[0].AddUnitGroup(utKnight, TKMPoint.New(22, 13), dirS, 1, 1);
  gHands[1].AddUnitGroup(utKnight, TKMPoint.New(22, 14), dirN, 2, 2);
  gTerrain.SetObject(TKMPoint.New(22, 14), 94);

  //Second line.
  gHands[0].AddUnitGroup(utKnight, TKMPoint.New(9, 18), dirN, 1, 1);
  gHands[1].AddUnitGroup(utKnight, TKMPoint.New(9, 17), dirS, 2, 2);
  gTerrain.SetObject(TKMPoint.New(10, 18), 94);

  gHands[0].AddUnitGroup(utKnight, TKMPoint.New(13, 18), dirE, 1, 1);
  gHands[1].AddUnitGroup(utKnight, TKMPoint.New(14, 17), dirW, 2, 2);
  gTerrain.SetObject(TKMPoint.New(14, 18), 94);

  gHands[0].AddUnitGroup(utKnight, TKMPoint.New(18, 18), dirN, 1, 1);
  gHands[1].AddUnitGroup(utKnight, TKMPoint.New(17, 17), dirS, 2, 2);
  gTerrain.SetObject(TKMPoint.New(18, 18), 94);

  gHands[0].AddUnitGroup(utKnight, TKMPoint.New(22, 18), dirW, 1, 1);
  gHands[1].AddUnitGroup(utKnight, TKMPoint.New(21, 18), dirE, 2, 2);
  gTerrain.SetObject(TKMPoint.New(22, 18), 94);

  //Third line.
  gTerrain.SetObject(TKMPoint.New(9, 20), 8);
  gTerrain.SetObject(TKMPoint.New(10, 20), 8);
  gHands[0].AddUnitGroup(utKnight, TKMPoint.New(9, 21), dirE, 1, 1);
  gHands[1].AddUnitGroup(utKnight, TKMPoint.New(10, 21), dirW, 2, 2);
  gTerrain.SetObject(TKMPoint.New(10, 22), 94);


  gTerrain.SetObject(TKMPoint.New(14, 20), 8);
  gTerrain.SetObject(TKMPoint.New(15, 20), 8);
  gTerrain.SetObject(TKMPoint.New(16, 20), 8);
  gTerrain.SetObject(TKMPoint.New(17, 20), 8);
  gTerrain.SetObject(TKMPoint.New(14, 21), 8);
  gTerrain.SetObject(TKMPoint.New(17, 21), 8);
  gTerrain.SetObject(TKMPoint.New(14, 22), 8);
  gTerrain.SetObject(TKMPoint.New(17, 22), 8);
  gTerrain.SetObject(TKMPoint.New(14, 23), 8);
  gTerrain.SetObject(TKMPoint.New(15, 23), 8);
  gTerrain.SetObject(TKMPoint.New(16, 23), 8);
  gTerrain.SetObject(TKMPoint.New(17, 23), 8);
  gHands[0].AddUnitGroup(utKnight, TKMPoint.New(16, 21), dirW, 1, 1);
  gHands[1].AddUnitGroup(utKnight, TKMPoint.New(15, 22), dirE, 2, 2);
  gTerrain.SetObject(TKMPoint.New(16, 22), 94);


  gTerrain.SetObject(TKMPoint.New(21, 20), 8);
  gTerrain.SetObject(TKMPoint.New(22, 20), 8);
  gTerrain.SetObject(TKMPoint.New(23, 20), 8);
  gTerrain.SetObject(TKMPoint.New(24, 20), 8);
  gTerrain.SetObject(TKMPoint.New(24, 21), 8);
  gTerrain.SetObject(TKMPoint.New(24, 22), 8);
  gHands[0].AddUnitGroup(utKnight, TKMPoint.New(23, 21), dirS, 1, 1);
  gHands[1].AddUnitGroup(utKnight, TKMPoint.New(23, 22), dirN, 2, 2);
  gTerrain.SetObject(TKMPoint.New(23, 22), 94);

end;


procedure TKMTest_MeleeEngagedJoiningFight.TearDown;
begin
  inherited;
  DYNAMIC_TERRAIN := True;
end;


procedure TKMTest_MeleeEngagedJoiningFight.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  if TimeIsOut then
  begin
    var allInFight := true;

    for var I := 0 to gHands[1].Units.Count - 1 do
    begin
      var W := TKMUnitWarrior(gHands[1].Units[I]);

      if (W <> nil) and not W.InFight then
      begin
        allInFight := false;
        break;
      end;
    end;

    AssertTrue(allInFight, 'Not all soldiers started fighting.')
  end;
end;


class function TKMTest_MeleeEngagedJoiningFight.TestTags: TKMTestTagSet;
begin
  Result := [tcCombat];
end;


class function TKMTest_MeleeEngagedJoiningFight.TestDescription: string;
begin
  Result := 'After melee group gets into fight, members should help instead of staying idle if they can reach enemy.';
end;


initialization
  RegisterTest(TKMTest_MeleeEngagedJoiningFight);
end.
