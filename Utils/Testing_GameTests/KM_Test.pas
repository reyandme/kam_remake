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
    TestResult: TKMTestResult;
    TestMessage: string;
  end;

  TKMTest = class
  protected
    fDuration: Integer;
    fResults: TKMRunResults;
    fOnProgress: TUnicodeStringEvent;
    fOnStop: TBooleanFuncSimple;
    function DoTick(aTick: Cardinal): Boolean; virtual;
    procedure SetUp; virtual; abstract;
    procedure TearDown; virtual;
    procedure CheckResult; virtual; abstract;
    procedure Execute(aSeed: Integer); virtual;
  public
    ThrottleRender: Boolean;
    DelayValue: Integer;
    constructor Create(aOnStop: TBooleanFuncSimple; aOnProgress: TUnicodeStringEvent); reintroduce;
    function Run(aSeed: Integer): TKMRunResults;
    class function TestTags: TKMTestTagSet; virtual;
    class function TestDescription: string; virtual;
  end;

procedure AssertTrue(aCondition: Boolean; const aMessage: string);
procedure AssertEquals(aExpected, aActual: Integer; const aMessage: string);
procedure RegisterTest(aTest: TKMTestClass);

var
  gTestList: array of TKMTestClass;


implementation


procedure AssertTrue(aCondition: Boolean; const aMessage: string);
begin
  if not aCondition then
    raise ETestFailed.Create(aMessage);
end;


procedure AssertEquals(aExpected, aActual: Integer; const aMessage: string);
begin
  if aExpected <> aActual then
    raise ETestFailed.Create(Format('%s (Expected: %d, Actual: %d)', [aMessage, aExpected, aActual]));
end;


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

  fDuration := 10 * 60 * 10;

  ThrottleRender := True;
end;


function TKMTest.DoTick(aTick: Cardinal): Boolean;
begin
  // Continue game by default
  Result := True;
end;


procedure TKMTest.Execute(aSeed: Integer);
begin
  SetKaMSeed(aSeed);
  try
    var lastRenderTime := TimeGet;

    for var I := 0 to fDuration - 1 do
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
        fOnProgress(Format('%d min', [I div 600]));
    end;
  finally
    CheckResult;
    gGameApp.StopGame(grSilent);
  end;
end;


function TKMTest.Run(aSeed: Integer): TKMRunResults;
begin
  SetUp;

  fResults.TestResult := trSuccess;
  fResults.TestMessage := '';

  try
    Execute(aSeed);
  except
    on E: ETestFailed do
    begin
      fResults.TestResult := trFailed;
      fResults.TestMessage := E.Message;
    end;
    on E: Exception do
    begin
      fResults.TestResult := trException;
      fResults.TestMessage := E.Message;
    end;
  end;

  TearDown;

  Result := fResults;
end;


procedure TKMTest.TearDown;
begin
  if gGameApp.Game <> nil then
    gGameApp.StopGame(grSilent);

  if Assigned(fOnProgress) then
    fOnProgress('Done');
end;


end.
