unit KM_Test_FarmPlant;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMTest_FarmPlant = class(TKMTest)
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


{ TKMTest_FarmPlant }
procedure TKMTest_FarmPlant.SetUp;
begin
  inherited;

  gGameApp.NewEmptyMap(32, 32);

  gHands[0].AddHouse(htFarm, 16, 20, False);

  gHands[0].AddField(KMPoint(16, 22), ftCorn, 0, False, True);

  gHands[0].AddUnit(utFarmer, KMPoint(16, 21));
end;


function TKMTest_FarmPlant.DoTick(aTick: Cardinal): Boolean;
begin
  Result := not ObjectIsCorn(gTerrain.Land[22, 16].Obj); // ObjectIsCorn expects ID
end;


procedure TKMTest_FarmPlant.CheckResult;
begin
  var cornFound := ObjectIsCorn(gTerrain.Land[22, 16].Obj);
  AssertTrue(cornFound, 'Farmer should have planted corn');
end;


class function TKMTest_FarmPlant.TestTags: TKMTestTagSet;
begin
  Result := [tcFarm, tcPlantTree];
end;


class function TKMTest_FarmPlant.TestDescription: string;
begin
  Result := 'Tests a farmer''s ability to sow a clean field with wheat.';
end;


initialization
  RegisterTest(TKMTest_FarmPlant);
end.
