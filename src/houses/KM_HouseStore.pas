unit KM_HouseStore;
{$I KaM_Remake.inc}
interface
uses
  KM_Houses,
  KM_ResWares, KM_ResTypes,
  KM_Defaults, KM_CommonClasses;

type
  // Storehouse keeps all the resources and flags for them
  TKMHouseStore = class(TKMHouse)
  private
    fWaresCount: array [WARE_MIN .. WARE_MAX] of Word;
    procedure SetWareCnt(aWareType: TKMWareType; aValue: Word);
  protected
    procedure Activate(aWasBuilt: Boolean); override;
  public
    NotAcceptFlag: array [WARE_MIN .. WARE_MAX] of Boolean;
    NotAllowTakeOutFlag: array [WARE_MIN .. WARE_MAX] of Boolean;
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure Demolish(aFrom: TKMHandID; IsSilent: Boolean = False); override;
    function ShouldAbandonDeliveryTo(aWareType: TKMWareType): Boolean; override;
    function ShouldAbandonDeliveryFromTo(aToHouse: TKMHouse; aWareType: TKMWareType; aImmidiateCheck: Boolean): Boolean; override;
    procedure ToggleNotAcceptFlag(aWare: TKMWareType);
    procedure ToggleNotAcceptTakeOutFlag(aWare: TKMWareType);
    procedure ResAddToIn(aWare: TKMWareType; aCount: Integer = 1; aFromScript: Boolean = False); override;
    function CheckResIn(aWare: TKMWareType): Word; override;
    procedure ResTakeFromOut(aWare: TKMWareType; aCount: Word = 1; aFromScript: Boolean = False); override;
    function ResCanAddToIn(aWare: TKMWareType): Boolean; override;
    function ResOutputAvailable(aWare: TKMWareType; const aCount: Word): Boolean; override;
    procedure Save(SaveStream: TKMemoryStream); override;
  end;

implementation
uses
  SysUtils, Math,
  KM_CommonExceptions,
  KM_Game,
  KM_GameParams,
  KM_GameTypes,
  KM_HandsCollection,
  KM_ScriptingEvents;


{ TKMHouseStore }
procedure TKMHouseStore.Activate(aWasBuilt:boolean);
var
  FirstStore: TKMHouseStore;
  RT: TKMWareType;
begin
  inherited;
  //A new storehouse should inherrit the accept properies of the first storehouse of that player,
  //which stops a sudden flow of unwanted resources to it as soon as it is create.
  FirstStore := TKMHouseStore(gHands[Owner].FindHouse(htStore, 1));
  if (FirstStore <> nil) and not FirstStore.IsDestroyed then
    for RT := WARE_MIN to WARE_MAX do
    begin
      NotAcceptFlag[RT] := FirstStore.NotAcceptFlag[RT];
      NotAllowTakeOutFlag[RT] := FirstStore.NotAllowTakeOutFlag[RT];
    end;
end;


procedure TKMHouseStore.SetWareCnt(aWareType: TKMWareType; aValue: Word);
var
  cntChange: Integer;
begin
  Assert(aWareType in [WARE_MIN..WARE_MAX]);

  cntChange := aValue - fWaresCount[aWareType];

  fWaresCount[aWareType] := aValue;

  if cntChange <> 0 then
    gScriptEvents.ProcHouseWareCountChanged(Self, aWareType, aValue, cntChange);
end;


constructor TKMHouseStore.Load(LoadStream: TKMemoryStream);
begin
  inherited;

  LoadStream.CheckMarker('HouseStore');
  LoadStream.Read(fWaresCount, SizeOf(fWaresCount));
  LoadStream.Read(NotAcceptFlag, SizeOf(NotAcceptFlag));
  LoadStream.Read(NotAllowTakeOutFlag, SizeOf(NotAllowTakeOutFlag));
end;


procedure TKMHouseStore.ResAddToIn(aWare: TKMWareType; aCount: Integer = 1; aFromScript: Boolean = False);
var
  W: TKMWareType;
begin
  case aWare of
    wtAll:     for W := Low(fWaresCount) to High(fWaresCount) do begin
                  SetWareCnt(W, EnsureRange(fWaresCount[W] + aCount, 0, High(Word)));
                  gHands[Owner].Deliveries.Queue.AddOffer(Self, W, aCount);
                end;
    WARE_MIN..
    WARE_MAX:   begin
                  SetWareCnt(aWare, EnsureRange(fWaresCount[aWare] + aCount, 0, High(Word)));
                  gHands[Owner].Deliveries.Queue.AddOffer(Self,aWare,aCount);
                end;
    else        raise ELocError.Create('Cant''t add ' + gResWares[aWare].Title, Position);
  end;
end;


function TKMHouseStore.ResCanAddToIn(aWare: TKMWareType): Boolean;
begin
  Result := (aWare in [WARE_MIN..WARE_MAX]);
end;


function TKMHouseStore.ResOutputAvailable(aWare: TKMWareType; const aCount: Word): Boolean;
begin
  Assert(aWare in [WARE_MIN..WARE_MAX]);
  Result := (fWaresCount[aWare] >= aCount);
end;


function TKMHouseStore.CheckResIn(aWare: TKMWareType): Word;
begin
  if aWare in [WARE_MIN..WARE_MAX] then
    Result := fWaresCount[aWare]
  else
    raise Exception.Create('Unexpected aWareType');
end;


procedure TKMHouseStore.Demolish(aFrom: TKMHandID; IsSilent: Boolean = False);
var
  W: TKMWareType;
begin
  for W := WARE_MIN to WARE_MAX do
    gHands[Owner].Stats.WareConsumed(W, fWaresCount[W]);

  inherited;
end;


procedure TKMHouseStore.ResTakeFromOut(aWare: TKMWareType; aCount: Word=1; aFromScript: Boolean = False);
begin
  if aFromScript then
  begin
    aCount := Min(aCount, fWaresCount[aWare]);
    if aCount > 0 then
    begin
      gHands[Owner].Stats.WareConsumed(aWare, aCount);
      gHands[Owner].Deliveries.Queue.RemOffer(Self, aWare, aCount);
    end;
  end;
  Assert(aCount <= fWaresCount[aWare]);

  SetWareCnt(aWare, fWaresCount[aWare] - aCount);
end;


procedure TKMHouseStore.ToggleNotAcceptFlag(aWare: TKMWareType);
const
  //Using shortints instead of bools makes it look much neater in code-view
  CHEAT_SP_PATTERN: array [WARE_MIN..WARE_MAX] of Byte = (
    0,0,1,0,0,
    0,1,0,1,0,
    1,0,0,0,1,
    1,0,0,0,1,
    1,1,1,1,1,
    0,0,0);
var
  ware: TKMWareType;
  cheatPattern: Boolean;
begin
  // Dunno why thats happening sometimes..
  Assert(aWare in [WARE_MIN .. WARE_MAX]);

  // We need to skip cheats in MP replays too, not just MP games, so don't use fGame.IsMultiplayer
  if CHEATS_SP_ENABLED and (MULTIPLAYER_CHEATS or not (gGameParams.Mode in [gmMulti, gmMultiSpectate, gmReplayMulti])) then
  begin
    // Check the cheat pattern
    cheatPattern := True;
    for ware := Low(fWaresCount) to High(fWaresCount) do
      cheatPattern := cheatPattern and (NotAcceptFlag[ware] = Boolean(CHEAT_SP_PATTERN[ware]));

    if cheatPattern then
      case aWare of
        wtCrossbow: begin
                      ResAddToIn(wtAll, 10);
                      gHands[Owner].Stats.WareProduced(wtAll, 10);
                      Exit;
                    end;
        wtHorse:   if not gGameParams.IsMultiPlayerOrSpec then
                    begin
                      // Game results cheats should not be used in MP even in debug
                      // MP does Win/Defeat differently (without Hold)
                      gGame.RequestHold(grWin);
                      Exit;
                    end;
        wtFish:    if not gGameParams.IsMultiPlayerOrSpec then
                    begin
                      // Game results cheats should not be used in MP even in debug
                      // MP does Win/Defeat differently (without Hold)
                      gGame.RequestHold(grDefeat);
                      Exit;
                    end;
      end;
  end;

  NotAcceptFlag[aWare] := not NotAcceptFlag[aWare];
end;


procedure TKMHouseStore.ToggleNotAcceptTakeOutFlag(aWare: TKMWareType);
begin
  NotAllowTakeOutFlag[aWare] := not NotAllowTakeOutFlag[aWare];
end;


procedure TKMHouseStore.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  SaveStream.PlaceMarker('HouseStore');
  SaveStream.Write(fWaresCount, SizeOf(fWaresCount));
  SaveStream.Write(NotAcceptFlag, SizeOf(NotAcceptFlag));
  SaveStream.Write(NotAllowTakeOutFlag, SizeOf(NotAllowTakeOutFlag));
end;


function TKMHouseStore.ShouldAbandonDeliveryTo(aWareType: TKMWareType): Boolean;
begin
  Result := inherited or NotAcceptFlag[aWareType];
end;


//Check if we should abandon TakeOut delivery (evacuate) from this house to aToHouse
function TKMHouseStore.ShouldAbandonDeliveryFromTo(aToHouse: TKMHouse; aWareType: TKMWareType; aImmidiateCheck: Boolean): Boolean;
begin
  Result := inherited or ((aToHouse <> nil)
                           and (aToHouse is TKMHouseStore)
                           and aToHouse.IsComplete
                           and ((GetDeliveryModeForCheck(aImmidiateCheck) <> dmTakeOut)
                                //Cancel delivery depends if we want to made immidiate check or not
                                //When Player sees "serf enters Store" then f.e. Player wants immidiately cancel this serf delivery
                                //In that case Delivery state will be set too late, and cancellation will be not applied
                                or NotAllowTakeOutFlag[aWareType]));
end;


end.
