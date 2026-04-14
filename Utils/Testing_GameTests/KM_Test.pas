unit KM_Test;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, SysUtils,
  KM_Defaults, KM_CommonClasses, KM_CommonTypes, KromUtils, KM_GameTypes,
  KM_GameApp, KM_Log, KM_CommonUtils, KM_RenderControl;


type
  TKMTest = class;
  TKMTestClass = class of TKMTest;

  TKMTestTag = (
    // Buildings
    tcArmorSmithy, tcArmorWorkshop, tcBakery, tcBarracks, tcButchers,
    tcCoalMine, tcFarm, tcFishermans, tcGoldMine, tcInn,
    tcIronMine, tcIronSmithy, tcMarket, tcMetallurgists, tcMill,
    tcQuarry, tcSawmill, tcSchool, tcSiegeWorkshop, tcStables,
    tcStore, tcSwine, tcTannery, tcTownHall, tcWatchTower,
    tcWeaponSmithy, tcWeaponWorkshop, tcVineyard, tcWoodcutters,

    // Units
    tcSerf, tcWoodcutter, tcMiner, tcAnimalBreeder, tcFarmer,
    tcCarpenter, tcBaker, tcButcher, tcFisher, tcBuilder,
    tcStonemason, tcSmith, tcMetallurgist, tcRecruit,

    tcMilitia, tcAxeFighter, tcSwordFighter, tcBowman, tcCrossbowman,
    tcLanceCarrier, tcPikeman, tcScout, tcKnight, tcBarbarian,

    tcRebel, tcRogue, tcWarrior, tcVagabond,

    tcWolf, tcFish, tcWatersnake, tcSeastar, tcCrab,
    tcWaterflower, tcWaterleaf, tcDuck,

    // General mechanics and logic
    tcProjectiles, tcPathfinding, tcPascalScript, tcHunger,
    tcEconomy, tcCombat, tcAI, tcNetworking, tcMultiplayer,
    tcChopTree, tcPlantTree, tcDeliveryIn, tcDeliveryOut
  );

  TKMTestTagSet = set of TKMTestTag;

  TKMTestResult = (trSuccess, trFailed, trException);
  ETestFailed = class(Exception);

  TKMRunResults = record
    RunCount: Integer;
    TestResults: array {Run} of TKMTestResult;
    TestMessages: array {Run} of string;
  end;

  TKMTest = class
  protected
    fRun: Integer;
    fResults: TKMRunResults;
    fOnProgress: TUnicodeStringEvent;
    fOnStop: TBooleanFuncSimple;
    function DoTick(aTick: Cardinal): Boolean; virtual;
    procedure SetUp; virtual; abstract;
    procedure TearDown; virtual;
    procedure Execute(aRun: Integer); virtual; abstract;
    procedure SimulateGame;
  public
    ThrottleRender: Boolean;
    Duration: Integer;
    Seed: Integer;
    DelayValue: Integer;
    constructor Create(aOnStop: TBooleanFuncSimple; aOnProgress: TUnicodeStringEvent); reintroduce;
    function Run(aCount: Integer): TKMRunResults;
    procedure AssertTrue(aCondition: Boolean; const aMessage: string);
    procedure AssertEquals(aExpected, aActual: Integer; const aMessage: string);
    procedure Fail(const aMessage: string);
    class function TestTags: TKMTestTagSet; virtual;
    class function TestDescription: string; virtual;
  end;

procedure RegisterTest(aTest: TKMTestClass);

var
  gTestList: array of TKMTestClass;


implementation


procedure RegisterTest(aTest: TKMTestClass);
begin
  SetLength(gTestList, Length(gTestList) + 1);
  gTestList[High(gTestList)] := aTest;
end;


{ TKMTest }
class function TKMTest.TestTags: TKMTestTagSet;
begin
  Result := [];
end;


class function TKMTest.TestDescription: string;
begin
  Result := 'No description provided.';
end;


constructor TKMTest.Create(aOnStop: TBooleanFuncSimple; aOnProgress: TUnicodeStringEvent);
begin
  inherited Create;

  fOnProgress := aOnProgress;
  fOnStop := aOnStop;

  ThrottleRender := True;
end;


function TKMTest.DoTick(aTick: Cardinal): Boolean;
begin
  // Continue game by default
  Result := True;
end;


function TKMTest.Run(aCount: Integer): TKMRunResults;
begin
  SetUp;

  fResults.RunCount := aCount;
  SetLength(fResults.TestResults, fResults.RunCount);
  SetLength(fResults.TestMessages, fResults.RunCount);

  for var I := 0 to aCount - 1 do
  begin
    if Assigned(fOnProgress) then
      fOnProgress(Format('%d', [I]));

    fRun := I;
    fResults.TestResults[I] := trSuccess;
    fResults.TestMessages[I] := '';

    try
      Execute(I);
    except
      on E: ETestFailed do
      begin
        fResults.TestResults[I] := trFailed;
        fResults.TestMessages[I] := E.Message;
      end;
      on E: Exception do
      begin
        fResults.TestResults[I] := trException;
        fResults.TestMessages[I] := E.Message;
      end;
    end;
  end;

  TearDown;

  Result := fResults;
end;


procedure TKMTest.AssertTrue(aCondition: Boolean; const aMessage: string);
begin
  if not aCondition then
    raise ETestFailed.Create(aMessage);
end;


procedure TKMTest.AssertEquals(aExpected, aActual: Integer; const aMessage: string);
begin
  if aExpected <> aActual then
    raise ETestFailed.Create(Format('%s (Expected: %d, Actual: %d)', [aMessage, aExpected, aActual]));
end;


procedure TKMTest.Fail(const aMessage: string);
begin
  raise ETestFailed.Create(aMessage);
end;


procedure TKMTest.TearDown;
begin
  if gGameApp.Game <> nil then
    gGameApp.StopGame(grSilent);

  if Assigned(fOnProgress) then
    fOnProgress('Done');
end;


procedure TKMTest.SimulateGame;
begin
  var lastRenderTime := TimeGet;

  for var I := 0 to Duration*60*10 - 1 do
  begin
    gGameApp.Game.UpdateGame;

    if ThrottleRender then
    begin
      if (TimeGet - lastRenderTime) > 100 then
      begin
        gGameApp.Render(False);
        lastRenderTime := TimeGet;
      end;
    end
    else
      gGameApp.Render(False);

    if SKIP_RENDER and (DelayValue > 0) then
      Sleep(DelayValue);

    if not DoTick(I+1) then
      Exit;

    if Assigned(fOnStop) and fOnStop then
      Exit;

    if gGameApp.Game.IsPaused then
      gGameApp.Game.Hold(False, grWin);

    if (I mod 60*10 = 0) and Assigned(fOnProgress) then
      fOnProgress(Format('%d (%d min)', [fRun + 1, I div 600]));
  end;
end;


end.
