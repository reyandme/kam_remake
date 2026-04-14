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
    ChartsCount: Integer; //How many charts return
    ValueCount: Integer; //How many values
    ValueMin, ValueMax: Integer;
    Value: array {Run} of array {Value} of Integer;
    TimesCount: Integer;
    TimeMin, TimeMax: Integer;
    Times: array {Run} of array {Tick} of Cardinal;
    TestResults: array {Run} of TKMTestResult;
    TestMessages: array {Run} of string;
  end;

  TKMTest = class
  protected
    fRenderTarget: TKMRenderControl;
    fRun: Integer;
    fResults: TKMRunResults;
    fOnProgress: TUnicodeStringEvent;
    fOnStop: TBooleanFuncSimple;
    procedure EnsureResourcesLoaded;
    function DoTick(aTick: Cardinal): Boolean; virtual;
    procedure SetUp; virtual;
    procedure TearDown; virtual;
    procedure Execute(aRun: Integer); virtual; abstract;
    procedure SimulateGame(aStartTick: Integer = 0; aEndTick: Integer = -1);
    procedure ProcessRunResults;
  public
    ThrottleRender: Boolean;
    Duration: Integer;
    Seed: Integer;
    DelayValue: Integer;
    constructor Create(aRenderTarget: TKMRenderControl; {aOnPause, }aOnStop: TBooleanFuncSimple; aOnProgress: TUnicodeStringEvent); reintroduce;
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
uses
  KM_MainSettings, KM_GameSettings, KM_GameAppSettings;


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


constructor TKMTest.Create(aRenderTarget: TKMRenderControl; aOnStop: TBooleanFuncSimple; aOnProgress: TUnicodeStringEvent);
begin
  inherited Create;

  fRenderTarget := aRenderTarget;

  fOnProgress := aOnProgress;
  fOnStop := aOnStop;

  ThrottleRender := True;
end;


function TKMTest.DoTick(aTick: Cardinal): Boolean;
begin
  Result := True; // Продолжаем симуляцию по умолчанию
end;


function TKMTest.Run(aCount: Integer): TKMRunResults;
var
  I: Integer;
begin
  SetUp;

  fResults.ChartsCount := aCount;
  SetLength(fResults.Value, fResults.ChartsCount, fResults.ValueCount);
  SetLength(fResults.Times, fResults.ChartsCount, fResults.TimesCount);
  SetLength(fResults.TestResults, fResults.ChartsCount);
  SetLength(fResults.TestMessages, fResults.ChartsCount);

  for I := 0 to aCount - 1 do
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

  ProcessRunResults;
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


procedure TKMTest.ProcessRunResults;
var
  I, K: Integer;
begin
  //Get min max
  with fResults do
  if ValueCount > 0 then
  begin
    ValueMin := Value[0,0];
    ValueMax := Value[0,0];
    for I := 0 to ChartsCount - 1 do
    for K := 0 to ValueCount - 1 do
    begin
      ValueMin := Min(ValueMin, Value[I,K]);
      ValueMax := Max(ValueMax, Value[I,K]);
    end;
  end;

  //Get min max
  with fResults do
  if TimesCount > 0 then
  begin
    TimeMin := Times[0,0];
    TimeMax := Times[0,0];
    for I := 0 to ChartsCount - 1 do
    for K := 0 to TimesCount - 1 do
    begin
      TimeMin := Min(TimeMin, Times[I,K]);
      TimeMax := Max(TimeMax, Times[I,K]);
    end;
  end;
end;


procedure TKMTest.EnsureResourcesLoaded;
var
  tgtWidth, tgtHeight: Word;
begin
  if gGameApp <> nil then Exit;

  SKIP_SOUND := True;
  SKIP_LOADING_CURSOR := True;
  SKIP_SETTINGS_SAVE := True;
  ExeDir := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\');

  if fRenderTarget = nil then
  begin
    tgtWidth := 1024;
    tgtHeight := 768;
  end else
  begin
    tgtWidth := fRenderTarget.Width;
    tgtHeight := fRenderTarget.Height;
  end;

  // Init settings global variables
  gGameAppSettings := TKMGameAppSettings.Create(tgtWidth, tgtHeight);

  gGameApp := TKMGameApp.Create(fRenderTarget, tgtWidth, tgtHeight, False, nil, nil, nil, True);
  gGameSettings.Autosave := False;
  gGameSettings.SaveCheckpoints := False;
  gGameApp.PreloadGameResources;
end;


procedure TKMTest.SetUp;
begin
  fResults.TimesCount := Duration*60*10;
  EnsureResourcesLoaded;
end;


procedure TKMTest.TearDown;
begin
  if gGameApp.Game <> nil then
    gGameApp.StopGame(grSilent);

  if Assigned(fOnProgress) then
    fOnProgress('Done');
end;


procedure TKMTest.SimulateGame(aStartTick: Integer = 0; aEndTick: Integer = -1);
var
  I: Integer;
  VLastRenderTime: Cardinal;
begin
  if (aEndTick = -1) then
    aEndTick := fResults.TimesCount - 1
  else
    aEndTick := Min(aEndTick,fResults.TimesCount - 1);

  VLastRenderTime := TimeGet;

  for I := aStartTick to aEndTick do
  begin
    fResults.Times[fRun, I] := TimeGet;

    gGameApp.Game.UpdateGame;
    
    if ThrottleRender then
    begin
      if (TimeGet - VLastRenderTime) > 100 then
      begin
        gGameApp.Render(False);
        VLastRenderTime := TimeGet;
      end;
    end
    else
      gGameApp.Render(False);

    if SKIP_RENDER and (DelayValue > 0) then
      Sleep(DelayValue);

    if not DoTick(I+1) then
      Exit;

    if Assigned(fOnStop)
      and fOnStop then
      Exit;

    fResults.Times[fRun, I] := TimeGet - fResults.Times[fRun, I];

    if gGameApp.Game.IsPaused then
      gGameApp.Game.Hold(False, grWin);

    if (I mod 60*10 = 0) and Assigned(fOnProgress) then
      fOnProgress(Format('%d (%d min)', [fRun + 1, I div 600]));
  end;
end;


end.
