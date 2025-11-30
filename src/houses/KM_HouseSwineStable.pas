unit KM_HouseSwineStable;
{$I KaM_Remake.inc}
interface
uses
  KM_Houses,
  KM_CommonClasses;

type
  // SwineStable has unique property - it needs to accumulate some resource before production begins, also special animation
  TKMHouseSwineStable = class(TKMHouse)
  private
    BeastAge: array[1..5]of Byte; // Each beasts "age". Once Best reaches age 3+1 it's ready
  protected
    procedure MakeSound; override;
  public
    constructor Load(LoadStream: TKMemoryStream); override;
    function FeedBeasts: Byte;
    procedure TakeBeast(aID: Byte);

    procedure Save(SaveStream: TKMemoryStream); override;
    procedure Paint; override;
  end;

implementation
uses
  Math,
  KM_Sound,
  KM_ResSound,
  KM_ResTypes,
  KM_Hand, KM_HandsCollection, KM_HandTypes, KM_HandEntity,
  KM_RenderPool,
  KM_Defaults, KM_CommonUtils;


{ TKMHouseSwineStable }
constructor TKMHouseSwineStable.Load(LoadStream: TKMemoryStream);
begin
  inherited;

  LoadStream.CheckMarker('HouseSwineStable');
  LoadStream.Read(BeastAge, SizeOf(BeastAge));
end;


//Return ID of beast that has grown up
function TKMHouseSwineStable.FeedBeasts: Byte;
var
  I: Integer;
begin
  Result := 0;
  Inc(BeastAge[KaMRandom(5{$IFDEF RNG_SPY}, 'TKMHouseSwineStable.FeedBeasts'{$ENDIF}) + 1]); //Let's hope it never overflows MAX
  for I := 1 to Length(BeastAge) do
    if BeastAge[I] > 3 then
      Result := I;
end;


procedure TKMHouseSwineStable.TakeBeast(aID: Byte);
begin
  if (aID<>0) and (BeastAge[aID]>3) then
    BeastAge[aID] := 0;
end;


//Make beast noises - each beast makes a noise (if it exists) with two second pauses between each one
procedure TKMHouseSwineStable.MakeSound;
var
  I: Integer;
begin
  inherited;

  if gMySpectator.FogOfWar.CheckTileRevelation(fPosition.X, fPosition.Y) < 255 then Exit;

  for I := 0 to 4 do
  if BeastAge[I+1] > 0 then
  if (FlagAnimStep + 20*I) mod 100 = 0 then
  begin
    if HouseType = htStables then
      gSoundPlayer.Play(TKMSoundEffectOriginal(Ord(sfxHorse1) + Random(4)), fPosition); // sfxHorse1..sfxHorse4
    if HouseType = htSwine   then
      gSoundPlayer.Play(TKMSoundEffectOriginal(Ord(sfxPig1)   + Random(4)), fPosition); // sfxPig1..sfxPig4
  end;
end;


procedure TKMHouseSwineStable.Save(SaveStream: TKMemoryStream);
begin
  inherited;

  SaveStream.PlaceMarker('HouseSwineStable');
  SaveStream.Write(BeastAge, SizeOf(BeastAge));
end;


procedure TKMHouseSwineStable.Paint;
var
  I: Integer;
begin
  inherited;

  //We render beasts on top of the HouseWork (which is mostly flames in this case), because otherwise
  //Swinefarm looks okay, but Stables are totaly wrong - flames are right on horses backs!
  if fBuildState = hbsDone then
    for I := 1 to 5 do
      if BeastAge[I] > 0 then
        gRenderPool.AddHouseStableBeasts(HouseType, fPosition, I, Min(BeastAge[I],3), FlagAnimStep);

  //But Animal Breeders should be on top of beasts
  if CurrentAction <> nil then
    gRenderPool.AddHouseWork(HouseType, fPosition,
                            CurrentAction.SubAction * [haWork1, haWork2, haWork3, haWork4, haWork5],
                            WorkAnimStep, WorkAnimStepPrev, gHands[Owner].GameFlagColor);
end;


end.
