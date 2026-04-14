unit KM_Test_FarmHarvest;
{$I KaM_Remake.inc}
interface
uses
  KM_Test, KM_Houses;

type
  TKMTest_FarmHarvest = class(TKMTest)
  private
    fFarm: TKMHouse;
  protected
    function DoTick(aTick: Cardinal): Boolean; override;
    procedure SetUp; override;
    procedure CheckResult; override;
  public
    class function TestTags: TKMTestTagSet; override;
    class function TestDescription: string; override;
  end;

implementation
uses
  KM_Defaults, KM_Points, KM_CommonUtils,
  KM_GameApp, KM_HandsCollection, KM_Terrain,
  KM_ResMapElements, KM_ResTypes;


procedure TKMTest_FarmHarvest.SetUp;
begin
  inherited;

  gGameApp.NewEmptyMap(32, 32);

  fFarm := gHands[0].AddHouse(htFarm, 16, 20, False);

  // Field plan at (16, 12) -> Stage 5 is ready to harvest
  gHands[0].AddField(KMPoint(16, 22), ftCorn, 5, False, True);
  
  // Add the farmer unit
  gHands[0].AddUnit(utFarmer, KMPoint(16, 21));
end;


function TKMTest_FarmHarvest.DoTick(aTick: Cardinal): Boolean;
begin
  Result := True;
  if fFarm.ResOut[1] > 0 then
    Result := False;
end;


procedure TKMTest_FarmHarvest.CheckResult;
begin
  AssertTrue(fFarm.ResOut[1] > 0, 'Farmer should have harvested corn and delivered it to farm');
end;


class function TKMTest_FarmHarvest.TestTags: TKMTestTagSet;
begin
  Result := [tcFarm, tcChopTree];
end;


class function TKMTest_FarmHarvest.TestDescription: string;
begin
  Result := 'Tests a farmer''s ability to collect ripe wheat and carry it back to the farm.';
end;


initialization
  RegisterTest(TKMTest_FarmHarvest);
end.
