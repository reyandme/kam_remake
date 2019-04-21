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
    constructor Load(LoadStream:TKMemoryStream); override;
    function ActName: TKMUnitActionName; override;
    function CanBeInterrupted(aForced: Boolean = True): Boolean; override;
    function GetExplanation: UnicodeString; override;
    function Execute: TKMActionResult; override;
    procedure Save(SaveStream:TKMemoryStream); override;
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


constructor TKMUnitActionStay.Load(LoadStream:TKMemoryStream);
begin
  inherited;
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
  if gMySpectator.FogOfWar.CheckTileRevelation(fUnit.CurrPosition.X, fUnit.CurrPosition.Y) < 255 then exit;

  //Various UnitTypes and ActionTypes produce all the sounds
  case fUnit.UnitType of
    utWorker:      case ActionType of
                      uaWork:  if Step = 3 then gSoundPlayer.Play(sfxHousebuild,fUnit.PositionF);
                      uaWork1: if Step = 0 then gSoundPlayer.Play(sfxDig,fUnit.PositionF);
                      uaWork2: if Step = 8 then gSoundPlayer.Play(sfxPave,fUnit.PositionF);
                    end;
    utFarmer:      case ActionType of
                      uaWork:  if Step = 8 then gSoundPlayer.Play(sfxCornCut,fUnit.PositionF);
                      uaWork1: if Step = 0 then gSoundPlayer.Play(sfxCornSow,fUnit.PositionF,true,0.6);
                    end;
    utStoneCutter: if ActionType = uaWork then
                      if Step = 3 then gSoundPlayer.Play(sfxMinestone,fUnit.PositionF,true,1.4);
    utWoodCutter:  case ActionType of
                      uaWork: if (fUnit.AnimStep mod Cycle = 3) and (fUnit.Direction <> dirN) then gSoundPlayer.Play(sfxChopTree, fUnit.PositionF,true)
                      else     if (fUnit.AnimStep mod Cycle = 0) and (fUnit.Direction =  dirN) then gSoundPlayer.Play(sfxWoodcutterDig, fUnit.PositionF,true);
                    end;
  end;
end;


function TKMUnitActionStay.Execute: TKMActionResult;
var
  Cycle, Step: Byte;
begin
  if not StayStill then
  begin
    Cycle := Max(gRes.Units[fUnit.UnitType].UnitAnim[ActionType, fUnit.Direction].Count, 1);
    Step  := fUnit.AnimStep mod Cycle;

    StepDone := fUnit.AnimStep mod Cycle = 0;

    if TimeToStay >= 1 then MakeSound(Cycle, Step);

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


procedure TKMUnitActionStay.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  SaveStream.Write(StayStill);
  SaveStream.Write(TimeToStay);
  SaveStream.Write(StillFrame);
end;


function TKMUnitActionStay.CanBeInterrupted(aForced: Boolean = True): Boolean;
begin
  Result := not Locked; //Initial pause before leaving barracks is locked
end;


end.
