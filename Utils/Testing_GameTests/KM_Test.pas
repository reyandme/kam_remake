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
    tcChopTree, tcPlantTree, tcDeliveryIn, tcDeliveryOut,
    tcSaveLoad
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
    fTickCountActual: Integer;
    fResults: TKMRunResults;
    fOnProgress: TUnicodeStringEvent;
    fOnShouldStop: TBooleanFuncSimple;
    function TimeIsOut: Boolean;
    procedure BeforeTick(aTick: Cardinal); virtual;
    procedure DoTick(aTick: Cardinal; var aKeepGoing: Boolean); virtual;
    procedure SetUp; virtual; abstract;
    procedure TearDown; virtual;
    procedure CheckResult; virtual; deprecated; //todo: Phase out, we can check everything in DoTick
    procedure Execute(aSeed: Integer); virtual;
  public
    PaceRender: Integer;
    PaceTicks: Integer;
    constructor Create(aOnShouldStop: TBooleanFuncSimple; aOnProgress: TUnicodeStringEvent); reintroduce;
    function Run(aSeed: Integer): TKMRunResults;
    class function TestTags: TKMTestTagSet; virtual;
    class function TestDescription: string; virtual;
    property TickCountActual: Integer read fTickCountActual;
  end;

procedure AssertFail(const aMessage: string);
procedure AssertTrue(aCondition: Boolean; const aMessage: string);
procedure AssertEquals(aExpected, aActual: Integer; const aMessage: string);
procedure RegisterTest(aTest: TKMTestClass);

var
  gTestList: array of TKMTestClass;


implementation


procedure AssertFail(const aMessage: string);
begin
  // Raising exceptions so that we also get a breakpoint in IDE
  raise ETestFailed.Create(aMessage);
end;


procedure AssertTrue(aCondition: Boolean; const aMessage: string);
begin
  if not aCondition then
    // Raising exceptions so that we also get a breakpoint in IDE
    raise ETestFailed.Create(aMessage);
end;


procedure AssertEquals(aExpected, aActual: Integer; const aMessage: string);
begin
  if aExpected <> aActual then
    // Raising exceptions so that we also get a breakpoint in IDE
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


constructor TKMTest.Create(aOnShouldStop: TBooleanFuncSimple; aOnProgress: TUnicodeStringEvent);
begin
  inherited Create;

  fOnProgress := aOnProgress;
  fOnShouldStop := aOnShouldStop;

  fDuration := 10 * 60 * 10;

  PaceRender := 100;
end;


function TKMTest.TimeIsOut: Boolean;
begin
  Result := fTickCountActual = fDuration;
end;


// Runs before the tick is played, where DoTick runs after it. Multiplayer tests pump the network
// here, so that packets are delivered before the tick that is meant to consume them
procedure TKMTest.BeforeTick(aTick: Cardinal);
begin
  //
end;


procedure TKMTest.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  //
end;


procedure TKMTest.CheckResult;
begin
  //
end;


procedure TKMTest.Execute(aSeed: Integer);
begin
  SetKaMSeed(aSeed);
  try
    var lastRenderTime := TimeGet;

    for var I := 0 to fDuration - 1 do
    begin
      BeforeTick(I + 1);

      gGameApp.Game.UpdateGame;

      if (TimeGet - lastRenderTime) >= PaceRender then
      begin
        gGameApp.Render(False);
        lastRenderTime := TimeGet;
      end;

      if PaceTicks > 0 then
        Sleep(PaceTicks);

      fTickCountActual := I + 1;
      var keepGoing := True;
      DoTick(fTickCountActual, keepGoing);
      if not keepGoing then
        Exit;

      if Assigned(fOnShouldStop) and fOnShouldStop then
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
  fResults.TestResult := trSuccess;
  fResults.TestMessage := '';

  try
    // SetUp runs inside the try so that a failure in it still reaches TearDown below. Otherwise a
    // half built test - a live server and open sockets, say - poisons every later test in the batch
    SetUp;
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
