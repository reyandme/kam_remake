unit KM_UnitActionStay;
{$I KaM_Remake.inc}
interface
uses
  KM_Defaults, KM_CommonClasses, KM_Units;

type
  // Stay in place for set time
  TKMUnitActionStay = class(TKMUnitAction)
  private
    fStayStill: Boolean;
    fTimeToStay: Integer;
    fStillFrame: Byte;
    procedure MakeSound(Cycle, Step: Byte);
  public
    constructor Create(aUnit: TKMUnit; aTimeToStay: Integer; aActionType: TKMUnitActionType; aStayStill: Boolean; aStillFrame: Byte; aLocked: Boolean);
    constructor Load(LoadStream: TKMemoryStream); override;
    function ActName: TKMUnitActionName; override;
    function CanBeInterrupted(aForced: Boolean = True): Boolean; override;
    function GetExplanation: UnicodeString; override;
    function Execute: TKMActionResult; override;
    procedure Save(SaveStream: TKMemoryStream); override;

    function ObjToStringShort(const aSeparator: string = ' '): string; override;
  end;


implementation
uses
  Math, SysUtils,
  KM_Points, KM_HandsCollection, KM_Sound, KM_Resource, KM_ResSound;


{ TKMUnitActionStay }
constructor TKMUnitActionStay.Create(aUnit: TKMUnit; aTimeToStay: Integer; aActionType: TKMUnitActionType; aStayStill: Boolean; aStillFrame: Byte; aLocked: Boolean);
begin
  inherited Create(aUnit, aActionType, aLocked);

  fStayStill   := aStayStill;
  fTimeToStay  := aTimeToStay;
  fStillFrame  := aStillFrame;
end;


constructor TKMUnitActionStay.Load(LoadStream: TKMemoryStream);
begin
  inherited;

  LoadStream.CheckMarker('UnitActionStay');
  LoadStream.Read(fStayStill);
  LoadStream.Read(fTimeToStay);
  LoadStream.Read(fStillFrame);
end;


function TKMUnitActionStay.ActName: TKMUnitActionName;
begin
  Result := uanStay;
end;


function TKMUnitActionStay.GetExplanation: UnicodeString;
begin
  Result := 'Staying';
end;


procedure TKMUnitActionStay.MakeSound(Cycle, Step: Byte);
begin
  if SKIP_SOUND then Exit;

  //Do not play sounds if unit is invisible to gMySpectator
  if gMySpectator.FogOfWar.CheckTileRevelation(fUnit.Position.X, fUnit.Position.Y) < 255 then Exit;

  //Various UnitTypes and ActionTypes produce all the sounds
  case fUnit.UnitType of
    utBuilder:    case ActionType of
                    uaWork:  if Step = 3 then gSoundPlayer.Play(sfxHouseBuild, fUnit.PositionF);
                    uaWork1: if Step = 0 then gSoundPlayer.Play(sfxDig, fUnit.PositionF);
                    uaWork2: if Step = 8 then gSoundPlayer.Play(sfxPave, fUnit.PositionF);
                  end;
    utFarmer:     case ActionType of
                    uaWork:  if Step = 8 then gSoundPlayer.Play(sfxCornCut, fUnit.PositionF);
                    uaWork1: if Step = 0 then gSoundPlayer.Play(sfxCornSow, fUnit.PositionF, True, 0.6);
                  end;
    utStonemason: if ActionType = uaWork then
                    if Step = 3 then gSoundPlayer.Play(sfxMinestone, fUnit.PositionF, True, 1.4);
    utWoodCutter: case ActionType of
                    uaWork: if (fUnit.AnimStep mod Cycle = 3) and (fUnit.Direction <> dirN) then gSoundPlayer.Play(sfxChopTree, fUnit.PositionF, True)
                  else
                    if (fUnit.AnimStep mod Cycle = 0) and (fUnit.Direction = dirN) then gSoundPlayer.Play(sfxWoodcutterDig, fUnit.PositionF, True);
                  end;
  end;
end;


function TKMUnitActionStay.Execute: TKMActionResult;
var
  cycle, step: Byte;
begin
  if not fStayStill then
  begin
    cycle := Max(gRes.Units[fUnit.UnitType].UnitAnim[ActionType, fUnit.Direction].Count, 1);
    step  := fUnit.AnimStep mod cycle;

    StepDone := fUnit.AnimStep mod cycle = 0;

    if fTimeToStay >= 1 then MakeSound(cycle, step);

    Inc(fUnit.AnimStep);
  end else
  begin
    fUnit.AnimStep := fStillFrame;
    StepDone := True;
  end;

  Dec(fTimeToStay);
  if fTimeToStay <= 0 then
    Result := arActDone
  else
    Result := arActContinues;
end;


procedure TKMUnitActionStay.Save(SaveStream: TKMemoryStream);
begin
  inherited;

  SaveStream.PlaceMarker('UnitActionStay');
  SaveStream.Write(fStayStill);
  SaveStream.Write(fTimeToStay);
  SaveStream.Write(fStillFrame);
end;


function TKMUnitActionStay.CanBeInterrupted(aForced: Boolean = True): Boolean;
begin
  Result := not Locked; //Initial pause before leaving barracks is locked
end;


function TKMUnitActionStay.ObjToStringShort(const aSeparator: string): string;
begin
  Result := inherited + Format('%s[StayStill = %s%sTimeToStay = %d%sStillFrame = %d]', [
                               aSeparator,
                               BoolToStr(fStayStill, True), aSeparator,
                               fTimeToStay, aSeparator,
                               fStillFrame]);
end;


end.
