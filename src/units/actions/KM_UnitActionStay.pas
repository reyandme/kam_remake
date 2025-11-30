unit KM_UnitActionStay;
{$I KaM_Remake.inc}
interface
uses
  Classes, KM_Defaults, KromUtils, KM_CommonClasses, KM_Units, SysUtils, Math, KM_Points;

type
  {Stay in place for set time}
  TKMUnitActionStay = class(TKMUnitAction)
  private
    StayStill:boolean;
    TimeToStay:integer;
    StillFrame:byte;
    procedure MakeSound(Cycle, Step: Byte);
  public
    constructor Create(aUnit: TKMUnit; aTimeToStay: Integer; aActionType: TKMUnitActionType; aStayStill: Boolean;
                       aStillFrame: Byte; aLocked: Boolean);
    constructor Load(LoadStream: TKMemoryStream); override;
    function ActName: TKMUnitActionName; override;
    function CanBeInterrupted(aForced: Boolean = True): Boolean; override;
    function GetExplanation: UnicodeString; override;
    function Execute: TKMActionResult; override;
    procedure Save(SaveStream: TKMemoryStream); override;

    function ObjToStringShort(const aSeparator: String = ' '): String; override;
  end;


implementation
uses
  KM_HandsCollection, KM_Sound, KM_ResSound, KM_Resource, KM_ResUnits;


{ TUnitActionStay }
constructor TKMUnitActionStay.Create(aUnit: TKMUnit; aTimeToStay: Integer; aActionType: TKMUnitActionType; aStayStill: Boolean;
                                     aStillFrame: Byte; aLocked: Boolean);
begin
  inherited Create(aUnit, aActionType, aLocked);

  StayStill   := aStayStill;
  TimeToStay  := aTimeToStay;
  StillFrame  := aStillFrame;
end;


constructor TKMUnitActionStay.Load(LoadStream: TKMemoryStream);
begin
  inherited;

  LoadStream.CheckMarker('UnitActionStay');
  LoadStream.Read(StayStill);
  LoadStream.Read(TimeToStay);
  LoadStream.Read(StillFrame);
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
  if gMySpectator.FogOfWar.CheckTileRevelation(fUnit.Position.X, fUnit.Position.Y) < 255 then exit;

  //Various UnitTypes and ActionTypes produce all the sounds
  case fUnit.UnitType of
    utBuilder:      case ActionType of
                      uaWork:  if Step = 3 then gSoundPlayer.Play(sfxHouseBuild, fUnit.PositionF);
                      uaWork1: if Step = 0 then gSoundPlayer.Play(sfxDig, fUnit.PositionF);
                      uaWork2: if Step = 8 then gSoundPlayer.Play(sfxPave, fUnit.PositionF);
                    end;
    utFarmer:      case ActionType of
                      uaWork:  if Step = 8 then gSoundPlayer.Play(sfxCornCut, fUnit.PositionF);
                      uaWork1: if Step = 0 then gSoundPlayer.Play(sfxCornSow, fUnit.PositionF,True,0.6);
                    end;
    utStonemason: if ActionType = uaWork then
                      if Step = 3 then gSoundPlayer.Play(sfxMinestone, fUnit.PositionF,True,1.4);
    utWoodCutter:  case ActionType of
                      uaWork: if (fUnit.AnimStep mod Cycle = 3) and (fUnit.Direction <> dirN) then gSoundPlayer.Play(sfxChopTree, fUnit.PositionF,True)
                      else     if (fUnit.AnimStep mod Cycle = 0) and (fUnit.Direction =  dirN) then gSoundPlayer.Play(sfxWoodcutterDig, fUnit.PositionF,True);
                    end;
  end;
end;


function TKMUnitActionStay.Execute: TKMActionResult;
var
  cycle, step: Byte;
begin
  if not StayStill then
  begin
    cycle := Max(gRes.Units[fUnit.UnitType].UnitAnim[ActionType, fUnit.Direction].Count, 1);
    step  := fUnit.AnimStep mod cycle;

    StepDone := fUnit.AnimStep mod cycle = 0;

    if TimeToStay >= 1 then MakeSound(cycle, step);

    Inc(fUnit.AnimStep);
  end
  else
  begin
    fUnit.AnimStep := StillFrame;
    StepDone := True;
  end;

  Dec(TimeToStay);
  if TimeToStay <= 0 then
    Result := arActDone
  else
    Result := arActContinues;
end;


procedure TKMUnitActionStay.Save(SaveStream: TKMemoryStream);
begin
  inherited;

  SaveStream.PlaceMarker('UnitActionStay');
  SaveStream.Write(StayStill);
  SaveStream.Write(TimeToStay);
  SaveStream.Write(StillFrame);
end;


function TKMUnitActionStay.CanBeInterrupted(aForced: Boolean = True): Boolean;
begin
  Result := not Locked; //Initial pause before leaving barracks is locked
end;


function TKMUnitActionStay.ObjToStringShort(const aSeparator: String): String;
begin
  Result := inherited + Format('%s[StayStill = %s%sTimeToStay = %d%sStillFrame = %d]', [
                               aSeparator,
                               BoolToStr(StayStill, True), aSeparator,
                               TimeToStay, aSeparator,
                               StillFrame]);
end;


end.
