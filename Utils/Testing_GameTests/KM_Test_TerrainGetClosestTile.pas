unit KM_Test_TerrainGetClosestTile;
{$I KaM_Remake.inc}
interface
uses
  KM_Test,
  KM_Points;


type
  // Check GetClosestTile
  TKMTest_TerrainGetClosestTile = class(TKMTest)
  protected
    fOrigin: TKMPoint;
    fFreeLoc: TKMPoint;
    fBusyLoc: TKMPoint;
    procedure SetUp; override;
    procedure DoTick(aTick: Cardinal; var aKeepGoing: Boolean); override;
    procedure CheckResult; override;
  public
    class function TestTags: TKMTestTagSet; override;
    class function TestDescription: string; override;
  end;


implementation
uses
  SysUtils,
  KM_Defaults,
  KM_GameApp, KM_HandsCollection, KM_HandTypes, KM_Terrain;


{ TKMTest_TerrainGetClosestTile }
procedure TKMTest_TerrainGetClosestTile.SetUp;
begin
  inherited;

  gGameApp.NewGameEmptyMap(32, 32);

  fOrigin := TKMPoint.New(12, 12);
  fFreeLoc := TKMPoint.New(16, 16);
  fBusyLoc := TKMPoint.New(20, 20);

  gHands[0].AddUnitGroup(utAxeFighter, fOrigin, dirN, 1, 1);
  gHands[0].AddUnitGroup(utAxeFighter, fBusyLoc, dirN, 1, 1);
end;


procedure TKMTest_TerrainGetClosestTile.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  aKeepGoing := False; // Nothing to simulate

  AssertTrue(gTerrain.RouteCanBeMade(fOrigin, fFreeLoc, tpWalk), 'Setup: the free target should be reachable');

  var closestTile: TKMPoint;
  closestTile := gTerrain.GetClosestTile(fFreeLoc, fOrigin, tpWalk, False);
  AssertTrue(KMSamePoint(closestTile, fFreeLoc), Format('GetClosestTile(target %s, origin %s) returned %s instead of the free target itself',
    [fFreeLoc.ToString, fOrigin.ToString, closestTile.ToString]));

  closestTile := gTerrain.GetClosestTile(fBusyLoc, fOrigin, tpWalk, False);
  AssertTrue(not KMSamePoint(closestTile, fBusyLoc),
    Format('GetClosestTile(target %s) returned the very tile another unit stands on', [fBusyLoc.ToString]));
  AssertTrue(closestTile.GetLengthDiag(fBusyLoc) <= 2,
    Format('GetClosestTile(target %s) returned %s, too far away to be the closest free tile', [fBusyLoc.ToString, closestTile.ToString]));
end;


procedure TKMTest_TerrainGetClosestTile.CheckResult;
begin
  // Everything is checked on the first tick
end;


class function TKMTest_TerrainGetClosestTile.TestTags: TKMTestTagSet;
begin
  Result := [tcPathfinding];
end;


class function TKMTest_TerrainGetClosestTile.TestDescription: string;
begin
  Result := 'GetClosestTile should return a free reachable tile, never one taken by another unit.';
end;


initialization
  RegisterTest(TKMTest_TerrainGetClosestTile);
end.
