unit KM_Test_SaveLoad;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;


type
  // Saves the game and loads it straight back, checking the world came back the way it went in.
  // A test game runs without any UI at all, so this also covers the UI parts of a savegame being
  // written and read as stubs (see TKMGamePlayInterface.SaveStub / LoadStub)
  TKMTest_SaveLoad_RoundTrip = class(TKMTest)
  private
    fSaved: Boolean;
    fError: string;
    fHousesBefore, fHousesAfter: Integer;
    fUnitsBefore, fUnitsAfter: Integer;
    fRecruitsBefore, fRecruitsAfter: Integer;
    fGoldBefore, fGoldAfter: Word;
    fTickBefore, fTickAfter: Cardinal;
  protected
    procedure SetUp; override;
    function DoTick(aTick: Cardinal): Boolean; override;
    procedure CheckResult; override;
  public
    class function TestTags: TKMTestTagSet; override;
    class function TestDescription: string; override;
  end;


implementation
uses
  SysUtils,
  KM_GameApp, KM_HandsCollection, KM_Houses, KM_HouseBarracks, KM_HouseStore,
  KM_ResTypes;

const
  SAVE_NAME = 'game_test_save_load';


function FindBarracks: TKMHouseBarracks;
begin
  Result := nil;
  for var I := 0 to gHands[0].Houses.Count - 1 do
    if gHands[0].Houses[I] is TKMHouseBarracks then
      Exit(TKMHouseBarracks(gHands[0].Houses[I]));
end;


function FindStore: TKMHouseStore;
begin
  Result := nil;
  for var I := 0 to gHands[0].Houses.Count - 1 do
    if gHands[0].Houses[I] is TKMHouseStore then
      Exit(TKMHouseStore(gHands[0].Houses[I]));
end;


{ TKMTest_SaveLoad_RoundTrip }
procedure TKMTest_SaveLoad_RoundTrip.SetUp;
begin
  inherited;

  fDuration := 60;

  gGameApp.NewEmptyMap(32, 32);

  var barracks := TKMHouseBarracks(gHands[0].AddHouse(htBarracks, 16, 16, False));
  barracks.CreateRecruitInside(False);
  barracks.CreateRecruitInside(False);

  var store := TKMHouseStore(gHands[0].AddHouse(htStore, 10, 16, False));
  store.WareAddToIn(wtGold, 42);
end;


function TKMTest_SaveLoad_RoundTrip.DoTick(aTick: Cardinal): Boolean;
begin
  Result := True;

  if aTick <> 30 then Exit;

  fHousesBefore := gHands[0].Houses.Count;
  fUnitsBefore := gHands[0].Units.Count;
  fRecruitsBefore := FindBarracks.RecruitsCount;
  fGoldBefore := FindStore.CheckWareIn(wtGold);
  fTickBefore := gGameApp.Game.Params.Tick;

  // Catch it here - CheckResult runs from a finally block and would replace the exception
  try
    gGameApp.Game.SaveAndWait(SAVE_NAME);
    gGameApp.NewSingleSave(SAVE_NAME);
    fSaved := True;
  except
    on E: Exception do
    begin
      fError := E.ClassName + ': ' + E.Message
                {$IFDEF WDC} + ' | ' + StringReplace(E.StackTrace, sLineBreak, ' <- ', [rfReplaceAll]) {$ENDIF};
      Exit(False);
    end;
  end;

  // Everything has been rebuilt by the load, so look it all up again
  fHousesAfter := gHands[0].Houses.Count;
  fUnitsAfter := gHands[0].Units.Count;
  if FindBarracks <> nil then
    fRecruitsAfter := FindBarracks.RecruitsCount;
  if FindStore <> nil then
    fGoldAfter := FindStore.CheckWareIn(wtGold);
  fTickAfter := gGameApp.Game.Params.Tick;
end;


procedure TKMTest_SaveLoad_RoundTrip.CheckResult;
begin
  AssertTrue(fError = '', 'Save/load raised ' + fError);
  AssertTrue(fSaved, 'Game was expected to be saved and loaded back');

  AssertEquals(fHousesBefore, fHousesAfter, 'All houses should survive the round trip');
  AssertEquals(fUnitsBefore, fUnitsAfter, 'All units should survive the round trip');
  AssertEquals(fRecruitsBefore, fRecruitsAfter, 'Barracks should list the same recruits afterwards');
  AssertEquals(fGoldBefore, fGoldAfter, 'Store should hold the same gold afterwards');
  AssertEquals(fTickBefore, fTickAfter, 'Loaded game should carry on from the tick it was saved at');
end;


class function TKMTest_SaveLoad_RoundTrip.TestTags: TKMTestTagSet;
begin
  Result := [tcBarracks, tcStore, tcRecruit];
end;


class function TKMTest_SaveLoad_RoundTrip.TestDescription: string;
begin
  Result := 'Saving a game and loading it straight back should restore the world unchanged.';
end;


initialization
  RegisterTest(TKMTest_SaveLoad_RoundTrip);
end.
