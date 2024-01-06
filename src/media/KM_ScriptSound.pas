unit KM_ScriptSound;
{$I KaM_Remake.inc}
interface
uses
  Generics.Collections,
  KM_CommonClasses, KM_CommonTypes, KM_Defaults, KM_Points, KM_MediaTypes;

type
  TKMScriptSound = class
  public
    PlayingIndex: Integer; //Index in gSoundPlayer.fScriptSoundALIndex, or -1 if not playing
    RemoveRequestSent: Boolean; //Mark sound as 'to be removed' to don't send too many GIC commands
    //Fields below are saved
    Looped: Boolean;
    FadeMusic: Boolean;
    ScriptUID: Integer; //UID, that is returned to the script that could be used to stop sound from script in the future
    SoundName: AnsiString; //Just sound name, not the path
    AudioFormat: TKMAudioFormat;
    Volume: Single;
    Radius: Single;
    Attenuate: Boolean;
    Loc: TKMPoint;
    HandIndex: TKMHandID;

    constructor Create;
  end;

  TKMScriptSoundsManager = class
  private
    fListener: TKMPointF;
    fLastScriptUID: Integer; //Last Unique ID for playing sound from script
    fScriptSounds: TObjectList<TKMScriptSound>;

    fSoundRemoveRequests: TDictionary<Integer, TKMByteSet>;

    function CanPlay(aIndex: Integer): Boolean; overload;
    function CanPlay(const aScriptSound: TKMScriptSound): Boolean; overload;
    function StartSound(aIndex: Integer): Integer; overload;
    function StartSound(aScriptSound: TKMScriptSound): Integer; overload;
    procedure StopSound(aIndex: Integer);
    procedure RemoveSoundByIndex(aIndex: Integer);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

    function AddSound(aHandIndex: TKMHandID; const aSoundName: AnsiString; aSoundFormat: TKMAudioFormat; aLoc: TKMPoint;
                      aAttenuate: Boolean; aVolume: Single; aRadius: Single; aFadeMusic, aLooped: Boolean): Integer;
    procedure RemoveLoopSoundByUID(aScriptIndex: Integer);
    procedure RemoveSoundByUID(aScriptUID: Integer; aLoopedOnly: Boolean = False);
    procedure AddRemoveRequest(aScriptSoundUID: Integer; aHandID: TKMHandID; aActiveHandIDs: TKMByteSet);
    procedure UpdateListener(X,Y: Single);

    procedure UpdateStateGlobal;

    function GetDbgString: string;
  end;

var
  gScriptSounds: TKMScriptSoundsManager;


implementation
uses
  SysUtils,
  KM_Game,
  KM_HandsCollection, KM_HandTypes,
  KM_Sound
  {$IFDEF FPC}
  , KM_Sort
  {$ENDIF}
  ;


{ TKMScriptSound }
constructor TKMScriptSound.Create;
begin
  inherited;

  // Set in default values
  PlayingIndex := -1;
end;


{ TKMScriptSoundsManager }
constructor TKMScriptSoundsManager.Create;
begin
  inherited;

  fLastScriptUID := 0;
  fScriptSounds := TObjectList<TKMScriptSound>.Create;
  fSoundRemoveRequests := TDictionary<Integer, TKMByteSet>.Create;
end;


destructor TKMScriptSoundsManager.Destroy;
begin
  gSoundPlayer.AbortAllScriptSounds;
  fSoundRemoveRequests.Free;
  fScriptSounds.Free;

  inherited;
end;


procedure TKMScriptSoundsManager.AddRemoveRequest(aScriptSoundUID: Integer; aHandID: TKMHandID; aActiveHandIDs: TKMByteSet);
var
  I: Integer;
  requestHands: TKMByteSet;
  found: Boolean;
begin
  // Check if this sound is no longer exists (we could get old GIC to remove it)
  found := False;
  for I := 0 to fScriptSounds.Count - 1 do
    if aScriptSoundUID = fScriptSounds[I].ScriptUID then
    begin
      found := True;
      Break;
    end;

  if not found then
  begin
    fSoundRemoveRequests.Remove(aScriptSoundUID); //Sound is not in a list anymore
    Exit;
  end;

  if not fSoundRemoveRequests.TryGetValue(aScriptSoundUID, requestHands) then
    requestHands := [];

  Include(requestHands, aHandID);


  if requestHands * aActiveHandIDs <> aActiveHandIDs then
  begin
    // We have to wait for other requests to come, to remove script sound simultaneously, to keep save data in sync
    fSoundRemoveRequests.AddOrSetValue(aScriptSoundUID, requestHands);
    Exit;
  end;

  // We found all active hands in the requestsList, can remove sound now. It will keep save in sync
  // Stop and Remove from list
  RemoveSoundByUID(aScriptSoundUID);
  fSoundRemoveRequests.Remove(aScriptSoundUID); // This sound is deleted, no need to keep it anymore
end;


procedure TKMScriptSoundsManager.UpdateStateGlobal;
var
  I: Integer;
begin
  if Self = nil then Exit;

  //Check whether a sound needs starting or stopping
  for I := fScriptSounds.Count - 1 downto 0 do
    if fScriptSounds[I].Looped then
    begin
      if (fScriptSounds[I].PlayingIndex = -1) and CanPlay(I) then
        StartSound(I)
      else
        if (fScriptSounds[I].PlayingIndex <> -1) and not CanPlay(I) then
          StopSound(I);
    end
    else
    begin
      if not fScriptSounds[I].RemoveRequestSent
       and ((fScriptSounds[I].PlayingIndex = -1)
         or not gSoundPlayer.IsScriptSoundPlaying(fScriptSounds[I].PlayingIndex)) then
      begin
        fScriptSounds[I].RemoveRequestSent := True; // Mark sound as 'remove requested', to avoid GIC spam
        // We can't rely on local IsSoundPlaying, because it could easily get in desync with other players,
        // because of network lags or desync in GlobalTickCount (there is no guarantee global tick is somehow in sync)
        gGame.GameInputProcess.CmdScriptSoundRemoveRequest(fScriptSounds[I].ScriptUID);
      end;
    end;
end;


function TKMScriptSoundsManager.CanPlay(aIndex: Integer): Boolean;
begin
  Result := CanPlay(fScriptSounds[aIndex]);
end;


function TKMScriptSoundsManager.CanPlay(const aScriptSound: TKMScriptSound): Boolean;
var
  distanceSqr: Single;
begin
  Result := ((aScriptSound.HandIndex = gMySpectator.HandID) or (aScriptSound.HandIndex = HAND_NONE))
             and (not aScriptSound.Attenuate
                  or (gMySpectator.FogOfWar.CheckTileRevelation(aScriptSound.Loc.X, aScriptSound.Loc.Y) > 0));
  if not Result then Exit;

  if aScriptSound.Attenuate then
  begin
    distanceSqr := KMDistanceSqr(KMPointF(aScriptSound.Loc), fListener);
    Result := Result and (distanceSqr < Sqr(aScriptSound.Radius));
  end;
end;


function TKMScriptSoundsManager.StartSound(aIndex: Integer): Integer;
begin
  Result := StartSound(fScriptSounds[aIndex]);
end;


function TKMScriptSoundsManager.StartSound(aScriptSound: TKMScriptSound): Integer;
var
  soundFile: UnicodeString;
begin
  Result := -1;
  soundFile := gGame.GetScriptSoundFilePath(aScriptSound.SoundName, aScriptSound.AudioFormat);

  //Silently ignore missing files
  if not FileExists(soundFile) or not CanPlay(aScriptSound) then
    Exit;

  with aScriptSound do
  begin
    PlayingIndex := gSoundPlayer.PlayScriptSound(soundFile, KMPointF(Loc), Attenuate, Volume, Radius, FadeMusic, Looped);
    Result := PlayingIndex;
  end;
end;


procedure TKMScriptSoundsManager.StopSound(aIndex: Integer);
begin
  if fScriptSounds[aIndex].PlayingIndex = -1 then Exit;

  gSoundPlayer.StopScriptSound(fScriptSounds[aIndex].PlayingIndex);
  fScriptSounds[aIndex].PlayingIndex := -1;
end;


function TKMScriptSoundsManager.AddSound(aHandIndex: TKMHandID; const aSoundName: AnsiString; aSoundFormat: TKMAudioFormat;
                                         aLoc: TKMPoint; aAttenuate: Boolean; aVolume: Single; aRadius: Single; aFadeMusic, aLooped: Boolean): Integer;
const
  ERROR_EXIT_CODE = -1;
var
  S: TKMScriptSound;
begin
  if Self = nil then Exit(ERROR_EXIT_CODE);

  Inc(fLastScriptUID); // fLastScriptUID always increases

  S := TKMScriptSound.Create;

  S.ScriptUID := fLastScriptUID;
  S.PlayingIndex := -1;
  S.Looped := aLooped;
  S.FadeMusic := aFadeMusic;
  S.SoundName := aSoundName;
  S.AudioFormat := aSoundFormat;
  S.Loc := aLoc;
  S.Attenuate := aAttenuate;
  S.Volume := aVolume;
  S.Radius := aRadius;
  S.HandIndex := aHandIndex;

  StartSound(fScriptSounds.Add(S));

  // Always return ScriptUID, since game logic should not depend on client sound subsystem
  Result := fLastScriptUID;
end;


// Remove sound by its index in list
procedure TKMScriptSoundsManager.RemoveSoundByIndex(aIndex: Integer);
begin
  StopSound(aIndex);
  fScriptSounds.Delete(aIndex);
end;


procedure TKMScriptSoundsManager.RemoveLoopSoundByUID(aScriptIndex: Integer);
begin
  RemoveSoundByUID(aScriptIndex, True);
end;


//Remove sound by its ScriptUID
procedure TKMScriptSoundsManager.RemoveSoundByUID(aScriptUID: Integer; aLoopedOnly: Boolean = False);
var
  I: Integer;
begin
  if Self = nil then Exit;

  Assert(aScriptUID > 0, 'Script sounds UID should be > 0');
  for I := fScriptSounds.Count - 1 downto 0 do
    if (not aLoopedOnly or fScriptSounds[I].Looped) and (fScriptSounds[I].ScriptUID = aScriptUID) then
    begin
      RemoveSoundByIndex(I);
      Exit; //Only one sound will have this aScriptIndex
    end;
end;


procedure TKMScriptSoundsManager.UpdateListener(X,Y: Single);
begin
  fListener := KMPointF(X, Y);
end;

function CompareKeys(const aKey1, aKey2): Integer;
var
  k1: Integer absolute aKey1;
  k2: Integer absolute aKey2;
begin
  if      k1 < k2 then Result := -1
  else if k1 > k2 then Result := +1
  else                 Result :=  0;
end;

procedure TKMScriptSoundsManager.Save(SaveStream: TKMemoryStream);
var
  I: Integer;
  key: Integer;
  keyArray : TArray<Integer>;
  handIDsSet: TKMByteSet;
begin
  SaveStream.PlaceMarker('ScriptSoundsManager');
  SaveStream.Write(fLastScriptUID);
  SaveStream.Write(fScriptSounds.Count);

  for I := 0 to fScriptSounds.Count - 1 do
  begin
    SaveStream.Write(fScriptSounds[I].Looped);
    SaveStream.Write(fScriptSounds[I].FadeMusic);
    SaveStream.Write(fScriptSounds[I].ScriptUID);
    SaveStream.WriteA(fScriptSounds[I].SoundName);
    SaveStream.Write(fScriptSounds[I].AudioFormat, SizeOf(fScriptSounds[I].AudioFormat));
    SaveStream.Write(fScriptSounds[I].Volume);
    SaveStream.Write(fScriptSounds[I].Radius);
    SaveStream.Write(fScriptSounds[I].Attenuate);
    SaveStream.Write(fScriptSounds[I].Loc);
    SaveStream.Write(fScriptSounds[I].HandIndex);
  end;

  SaveStream.PlaceMarker('ScriptSoundsRemoveRq');
  SaveStream.Write(fSoundRemoveRequests.Count);

  keyArray := fSoundRemoveRequests.Keys.ToArray;
  {$IFNDEF FPC}
  TArray.Sort<Integer>(keyArray);
  {$ELSE}
  SortCustom(keyArray, Low(keyArray), High(keyArray), SizeOf(keyArray[0]), CompareKeys);
  {$ENDIF}
  for key in keyArray do
  begin
    SaveStream.Write(key);

    handIDsSet := fSoundRemoveRequests[key];
    SaveStream.Write(handIDsSet, SizeOf(TKMByteSet));
  end;
end;


procedure TKMScriptSoundsManager.Load(LoadStream: TKMemoryStream);
var
  I, sndCount, key: Integer;
  scriptSnd: TKMScriptSound;
  handIDsSet: TKMByteSet;
begin
  LoadStream.CheckMarker('ScriptSoundsManager');
  LoadStream.Read(fLastScriptUID);
  LoadStream.Read(sndCount);
  fScriptSounds.Clear;
  for I := 0 to sndCount - 1 do
  begin
    scriptSnd := TKMScriptSound.Create;
    LoadStream.Read(scriptSnd.Looped);
    LoadStream.Read(scriptSnd.FadeMusic);
    LoadStream.Read(scriptSnd.ScriptUID);
    LoadStream.ReadA(scriptSnd.SoundName);
    LoadStream.Read(scriptSnd.AudioFormat, SizeOf(scriptSnd.AudioFormat));
    LoadStream.Read(scriptSnd.Volume);
    LoadStream.Read(scriptSnd.Radius);
    LoadStream.Read(scriptSnd.Attenuate);
    LoadStream.Read(scriptSnd.Loc);
    LoadStream.Read(scriptSnd.HandIndex);
    scriptSnd.PlayingIndex := -1; //Indicates that it is not currently playing
    fScriptSounds.Add(scriptSnd);
  end;

  LoadStream.CheckMarker('ScriptSoundsRemoveRq');
  LoadStream.Read(sndCount);
  for I := 0 to sndCount - 1 do
  begin
    LoadStream.Read(key);

    LoadStream.Read(handIDsSet, SizeOf(TKMByteSet));

    fSoundRemoveRequests.Add(key, handIDsSet);
  end;
end;


function TKMScriptSoundsManager.GetDbgString: string;
var
  I: Byte;
  pair: TPair<Integer, TKMByteSet>;
  str: string;
begin
  str := '';

  for pair in fSoundRemoveRequests do
  begin
    str := str + IntToStr(pair.Key) + '|';

    for I in pair.Value do
      str := str + ' ' + IntToStr(I);

    str := str + '|';
  end;

  Result := Format('Script sounds cnt = %d|RemoveRequests: CNT = %d:|%s', [fScriptSounds.Count, fSoundRemoveRequests.Count, str]);
end;


end.
