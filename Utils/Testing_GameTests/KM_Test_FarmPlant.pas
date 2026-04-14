unit KM_Test_FarmPlant;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMTest_Farm_Plant = class(TKMTest)
  protected
    function DoTick(aTick: Cardinal): Boolean; override;
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
  public
    class function TestTags: TKMTestTagSet; override;
    class function TestDescription: string; override;
  end;

implementation
uses
  KM_Defaults, KM_Points, KM_CommonUtils,
  KM_GameApp, KM_HandsCollection, KM_Terrain,
  KM_ResMapElements, KM_ResTypes;


{ TKMTest_Farm_Plant }
procedure TKMTest_Farm_Plant.SetUp;
begin
  inherited;

  fResults.ValueCount := 1;
  gGameApp.NewEmptyMap(32, 32);

  gHands[0].AddHouse(htFarm, 16, 20, False);

  gHands[0].AddField(KMPoint(16, 22), ftCorn, 0, False, True);

  gHands[0].AddUnit(utFarmer, KMPoint(16, 21));
end;


function TKMTest_Farm_Plant.DoTick(aTick: Cardinal): Boolean;
begin
  Result := not ObjectIsCorn(gTerrain.Land[22, 16].Obj); // ObjectIsCorn expects ID
end;


procedure TKMTest_Farm_Plant.Execute(aRun: Integer);
begin
  SetKaMSeed(aRun+1);
  SimulateGame;

  fResults.Value[aRun, 0] := 0;
  if ObjectIsCorn(gTerrain.Land[22, 16].Obj) then
    fResults.Value[aRun, 0] := 1;

  AssertTrue(fResults.Value[aRun, 0] = 1, 'Farmer should have planted corn');

  gGameApp.StopGame(grSilent);
end;


class function TKMTest_Farm_Plant.TestTags: TKMTestTagSet;
begin
  Result := [tcFarm, tcPlantTree];
end;


class function TKMTest_Farm_Plant.TestDescription: string;
begin
  Result := 'Tests a farmer''s ability to sow a clean field with wheat.';
end;


initialization
  RegisterTest(TKMTest_Farm_Plant);
end.
