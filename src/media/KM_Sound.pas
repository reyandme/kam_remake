unit KM_Sound;
{$I KaM_Remake.inc}
interface
uses
  Generics.Collections,
  OpenAL,
  KM_ResSound,
  KM_Defaults, KM_CommonClasses, KM_CommonTypes, KM_Points;


const
  MAX_SOUNDS = 32; //64 looks like the limit, depends on hardware
  MAX_SCRIPT_SOUNDS = 12; //Save rest for the game
  MAX_LOOP_SOUNDS = 6;
  WAV_FILE_EXT = '.wav';
  OGG_FILE_EXT = '.ogg';

type
  TKMSoundPlayer = class
  private
    fALDevice: PALCdevice;

    fListener: record
      Pos: array [1..3] of TALfloat; //Position in 3D space
      Vel: array [1..3] of TALfloat; //Velocity, used in doppler effect calculation
      Ori: array [1..6] of TALfloat; //Orientation LookingAt and UpVector
    end;
    fIsSoundInitialized: Boolean;
    fInitComplete: Boolean;

    fALSounds: array [0..MAX_SOUNDS-1] of record
      ALBuffer: TALuint;
      ALSource: TALuint;
      Name: UnicodeString;
      Position: TKMPointF;
      Duration: cardinal; //MSec
      PlaySince: cardinal;
      Volume: Single;
      Looped: Boolean;
      FromScript: Boolean;
      FadesMusic: Boolean;
    end;

    fScriptSoundALIndex: array[0..MAX_SCRIPT_SOUNDS-1] of Integer;

    fLastMessageNoticeTime: Cardinal; // Last time message notice were played

    fVolume: Single; // aka "Global volume"
    fPrevVolume: Single; // Volume before sound was 'muted'

    fMusicIsFaded: Boolean;

    fOnFadeMusic: TKMEvent;
    fOnUnfadeMusic: TKMEvent;
    procedure CheckOpenALError;
    function IsSoundPlaying(aIndex: Integer): Boolean;

    function PlayWave(const aFile: UnicodeString; const aLoc: TKMPointF; aSoundType: TKMSoundType; aAttenuated: Boolean = True;
                      aVolume: Single = 1; aFadeMusic: Boolean = False; aLoop: Boolean = False): Integer;
    function PlaySound(aSoundID: TSoundFX; const aFile: UnicodeString; const Loc: TKMPointF; aSoundType: TKMSoundType;
                       aAttenuated: Boolean; aVolume: Single; aRadius: Single; aFadeMusic, aLooped: Boolean; aFromScript: Boolean = False): Integer;
    function CanAddLoopSound: Boolean;

    function GetMuted: Boolean;
    procedure SetMuted(const aMuted: Boolean);

    function GetPrevVolume: Single;
    function GetIsReady: Boolean;

    property PrevVolume: Single read GetPrevVolume write fPrevVolume;

    procedure Init;
  public
    constructor Create(aVolume: Single);
    destructor Destroy; override;
    function ActiveCount: Byte;

    property OnRequestFade: TKMEvent write fOnFadeMusic;
    property OnRequestUnfade: TKMEvent write fOnUnfadeMusic;
    procedure AbortAllFadeSounds;
    procedure AbortAllScriptSounds;
    procedure AbortAllLongSounds;

    procedure UpdateListener(X,Y: Single);
    procedure UpdateSoundVolume(aValue: Single);
    property Volume: Single read fVolume write UpdateSoundVolume;
    procedure ToggleMuted;

    property IsReady: Boolean read GetIsReady;
    property Muted: Boolean read GetMuted write SetMuted;

    function IsScriptSoundPlaying(aScriptIndex: Integer): Boolean;

    procedure PlayNotification(aSound: TAttackNotification);

    procedure PlayCitizen(aUnitType: TKMUnitType; aSound: TWarriorSpeech); overload;
    procedure PlayCitizen(aUnitType: TKMUnitType; aSound: TWarriorSpeech; const aLoc: TKMPointF); overload;
    procedure PlayWarrior(aUnitType: TKMUnitType; aSound: TWarriorSpeech); overload;
    procedure PlayWarrior(aUnitType: TKMUnitType; aSound: TWarriorSpeech; const aLoc: TKMPointF); overload;
    procedure Play(aSoundID: TSoundFX; aVolume: Single = 1); overload;
    procedure Play(aSoundID: TSoundFX; aLoc: TKMPoint; aAttenuated: Boolean = True; aVolume: Single = 1); overload;
    procedure Play(aSoundID: TSoundFX; aLoc: TKMPointF; aAttenuated: Boolean = True; aVolume: Single = 1); overload;

    procedure Play(aSoundID: TSoundFXNew; aVolume: Single = 1; aFadeMusic: Boolean = False); overload;
    procedure Play(aSoundID: TSoundFXNew; aLoc: TKMPoint; aAttenuated: Boolean = True; aVolume: Single = 1; aFadeMusic: Boolean = False); overload;

    function PlayScriptSound(const aFile: UnicodeString; aLoc: TKMPointF; aAttenuate: Boolean; aVolume: Single; aRadius: Single; aFadeMusic, aLooped: Boolean): Integer;
    procedure StopScriptSound(aIndex: Integer);

    procedure Paint;
    procedure UpdateStateIdle;
  end;

var
  gSoundPlayer: TKMSoundPlayer;


implementation
uses
  SysUtils, Classes, TypInfo, Math,
  Dialogs,
  {$IFDEF WDC} UITypes, {$ENDIF}
  {$IFNDEF NO_OGG_SOUND}
  Codec, VorbisFile,
  {$ENDIF}
  KromUtils,
  KM_Game, KM_Resource, 
  KM_HandsCollection, KM_HandTypes,
  KM_RenderAux,
  KM_Log, KM_CommonUtils;


const
  MAX_ATTENUATED_SOUNDS = (3/4) * MAX_SOUNDS; // Attenuated sounds are less important, always save space for others
  MAX_FAR_SOUNDS = (1/2) * MAX_SOUNDS;        // Sounds that are too far away can only access this many slots

  MAX_BUFFERS = 16;  // 16/24/32 looks like the limit, depends on hardware
  MAX_SOURCES = 32;  // Depends on hardware as well
  MAX_DISTANCE = 32; // After this distance sounds are completely mute
  MAX_PRIORITY_DISTANCE_FACTOR = (1/2); // Sounds past this distance will not play if there are few slots left (gives close sounds priority)
  MAX_DURATION_FROM_LAST_SND_MESSAGE_NOTICE = 100; // Maximum time in ms from last message notice. To avoid 'echo' effect for multiple messages at one time


{ TKMSoundPlayer }
constructor TKMSoundPlayer.Create(aVolume: Single);
begin
  inherited Create;

  Init;

  fVolume := aVolume;
  fPrevVolume := aVolume;
end;


destructor TKMSoundPlayer.Destroy;
var
  I: Integer;
begin
  if fIsSoundInitialized then
  begin
    for I := Low(fALSounds) to High(fALSounds) do
    begin
      AlDeleteBuffers(1, @fALSounds[I].ALBuffer);
      AlDeleteSources(1, @fALSounds[I].ALSource);
    end;
    AlutExit;
  end;
  inherited;
end;


procedure TKMSoundPlayer.Init;
var
  I: Integer;

begin
  for I := Low(fScriptSoundALIndex) to High(fScriptSoundALIndex) do
    fScriptSoundALIndex[I] := -1;

  if SKIP_SOUND then Exit;

  fInitComplete := False;

  TThread.CreateAnonymousThread(
    procedure
    var
      I: Integer;
      context: PALCcontext;
      numMono, numStereo: TALCint;
    begin
      gLog.AddTime('OpenAL init started');

      fIsSoundInitialized := InitOpenAL;
      Set8087CW($133F); //Above OpenAL call messes up FPU settings
      if not fIsSoundInitialized then
      begin
        gLog.AddNoTime('OpenAL warning. OpenAL could not be initialized.');
        //MessageDlg works better than Application.MessageBox or others, it stays on top and pauses here until the user clicks ok.
        MessageDlg('OpenAL could not be initialized. Please refer to Readme.html for solution', mtWarning, [mbOk], 0);
        fIsSoundInitialized := False;
        Exit;
      end;

      // Open device (this is quite slow, 700-800 ms)
      //todo -cPractical: OpenAL init can be perfomed in a thread
      fALDevice := alcOpenDevice(nil); // this is supposed to select the "preferred device"
      Set8087CW($133F); //Above OpenAL call messes up FPU settings
      if fALDevice = nil then
      begin
        gLog.AddNoTime('OpenAL warning. Device could not be opened.');
        //MessageDlg works better than Application.MessageBox or others, it stays on top and pauses here until the user clicks ok.
        MessageDlg('OpenAL device could not be opened. Please refer to Readme.html for solution', mtWarning, [mbOk], 0);
        fIsSoundInitialized := False;
        Exit;
      end;

      // Create context
      context := alcCreateContext(fALDevice, nil);
      Set8087CW($133F); //Above OpenAL call messes up FPU settings
      if context = nil then
      begin
        gLog.AddNoTime('OpenAL warning. Context could not be created.');
        //MessageDlg works better than Application.MessageBox or others, it stays on top and pauses here until the user clicks ok.
        MessageDlg('OpenAL context could not be created. Please refer to Readme.html for solution', mtWarning, [mbOk], 0);
        fIsSoundInitialized := False;
        Exit;
      end;

      // Set active context
      I := alcMakeContextCurrent(context);
      Set8087CW($133F); //Above OpenAL call messes up FPU settings
      if not (I in [AL_NO_ERROR, AL_TRUE]) then
      begin
        gLog.AddNoTime('OpenAL warning. Context could not be made current.');
        //MessageDlg works better than Application.MessageBox or others, it stays on top and pauses here until the user clicks ok.
        MessageDlg('OpenAL context could not be made current. Please refer to Readme.html for solution', mtWarning, [mbOk], 0);
        fIsSoundInitialized := False;
        Exit;
      end;

      CheckOpenALError;
      if not fIsSoundInitialized then Exit;

      // Set attenuation model
      alDistanceModel(AL_LINEAR_DISTANCE_CLAMPED);
      gLog.AddTime('Pre-LoadSFX init done');

      alcGetIntegerv(fALDevice, ALC_MONO_SOURCES, 4, @numMono);
      alcGetIntegerv(fALDevice, ALC_STEREO_SOURCES, 4, @numStereo);

      gLog.AddTime('ALC_MONO_SOURCES %d', [numMono]);
      gLog.AddTime('ALC_STEREO_SOURCES %d', [numStereo]);

      for I := Low(fALSounds) to High(fALSounds) do
      begin
        AlGenBuffers(1, @fALSounds[i].ALBuffer);
        AlGenSources(1, @fALSounds[i].ALSource);
      end;

      CheckOpenALError;
      if not fIsSoundInitialized then Exit;

      // Set default Listener orientation
      fListener.Ori[1] := 0; fListener.Ori[2] := 0; fListener.Ori[3] := -1; //Look-at vector
      fListener.Ori[4] := 0; fListener.Ori[5] := 1; fListener.Ori[6] := 0; //Up vector
      AlListenerfv(AL_ORIENTATION, @fListener.Ori);

      fInitComplete := True;
      gLog.AddTime('OpenAL init done');
    end).Start;
end;



procedure TKMSoundPlayer.CheckOpenALError;
var
  errCode: Integer;
begin
  errCode := alcGetError(fALDevice);
  if errCode <> ALC_NO_ERROR then begin
    gLog.AddNoTime('OpenAL warning. There is OpenAL error '+inttostr(errCode)+' raised. Sound will be disabled.');
    //MessageDlg works better than Application.MessageBox or others, it stays on top and pauses here until the user clicks ok.
    MessageDlg('There is OpenAL error '+IntToStr(errCode)+' raised. Sound will be disabled.', mtWarning, [mbOk], 0);
    fIsSoundInitialized := False;
  end;
end;


procedure TKMSoundPlayer.AbortAllFadeSounds;
var
  I: Integer;
begin
  if SKIP_SOUND or not fIsSoundInitialized then Exit;

  fMusicIsFaded := False;
  for I := Low(fALSounds) to High(fALSounds) do
    if fALSounds[I].FadesMusic then
      alSourceStop(fALSounds[i].ALSource);
end;


procedure TKMSoundPlayer.AbortAllLongSounds;
var
  I: Integer;
begin
  if SKIP_SOUND or not fIsSoundInitialized then Exit;

  //This is used to abort long sounds from the game when you quit so they don't play in the menu
  for I := Low(fALSounds) to High(fALSounds) do
    if (fALSounds[I].PlaySince <> 0) and (TimeSince(fALSounds[I].PlaySince) < fALSounds[I].Duration)
    and not fALSounds[I].FromScript //Looped sounds manage themselves
    and (fALSounds[I].Duration > 8000) then //Sounds <= 8 seconds can keep playing (e.g. victory music)
    begin
      fALSounds[I].PlaySince := 0;
      alSourceStop(fALSounds[i].ALSource);
    end;
end;


function TKMSoundPlayer.GetPrevVolume: Single;
begin
  Result := IfThen(fPrevVolume = 0, 0.5, fPrevVolume);
end;


function TKMSoundPlayer.GetIsReady: Boolean;
begin
  Result := fInitComplete and fIsSoundInitialized;
end;


function TKMSoundPlayer.GetMuted: Boolean;
begin
  Result := (fVolume = 0);
end;


procedure TKMSoundPlayer.SetMuted(const aMuted: Boolean);
begin
  if Muted = aMuted then Exit; // Nothing to change, just exit to avoid fPrevVolume overwrite

  if aMuted then
  begin
    fPrevVolume := fVolume;
    UpdateSoundVolume(0);
  end
  else
  begin
    UpdateSoundVolume(PrevVolume);
    fPrevVolume := 0;
  end;
end;


procedure TKMSoundPlayer.ToggleMuted;
begin
  SetMuted(not GetMuted);
end;


{Update listener position in 3D space}
procedure TKMSoundPlayer.UpdateListener(X,Y:single);
begin
  if SKIP_SOUND or not fIsSoundInitialized then Exit;
  fListener.Pos[1] := X;
  fListener.Pos[2] := Y;
  fListener.Pos[3] := 24; //Place Listener above the surface
  AlListenerfv(AL_POSITION, @fListener.Pos);
end;


{ Update sound gain (global volume for all sounds) }
procedure TKMSoundPlayer.UpdateSoundVolume(aValue: Single);

  procedure UpdateSound(aI: Integer);
  begin
    AlSourcef(fALSounds[aI].ALSource, AL_GAIN, 1 * fALSounds[aI].Volume * fVolume);
  end;

var
  I: Integer;
begin
  if SKIP_SOUND or not fIsSoundInitialized then Exit;
  fVolume := aValue;
  if fVolume > 0 then
    fPrevVolume := fVolume;
  //alListenerf(AL_GAIN, fSoundGain); //Set in source property

  //Loop sounds must be updated separately
  for I := Low(fScriptSoundALIndex) to High(fScriptSoundALIndex) do
    if fScriptSoundALIndex[I] <> -1 then
      UpdateSound(fScriptSoundALIndex[I]);//AlSourcef(fSound[fScriptSoundIndex[I]].ALSource, AL_GAIN, 1 * fSound[fScriptSoundIndex[I]].Volume * fSoundGain);

  //Update the volume of all other playing sounds
  for I := Low(fALSounds) to High(fALSounds) do
    if not fALSounds[I].FromScript //Looped sounds are handled above
      and (fALSounds[I].PlaySince <> 0) and (TimeSince(fALSounds[I].PlaySince) < fALSounds[I].Duration) then
      UpdateSound(I);//AlSourcef(fSound[I].ALSource, AL_GAIN, 1 * fSound[I].Volume * fSoundGain);
end;


// Wrapper with fewer options for non-attenuated sounds
procedure TKMSoundPlayer.Play(aSoundID: TSoundFX; aVolume: Single = 1);
begin
  if SKIP_SOUND or not fIsSoundInitialized then Exit;

  // Check for consecutive messageNotices
  // When many warrior groups are hungry at the same time or many houses are not occupied at the same time
  // Sound should not be played N times, 1 is enough
  if aSoundID = sfxMessageNotice then
  begin
    if (fLastMessageNoticeTime > 0)
      and (TimeSince(fLastMessageNoticeTime) < MAX_DURATION_FROM_LAST_SND_MESSAGE_NOTICE) then
      Exit
    else
      fLastMessageNoticeTime := TimeGet;
  end;

  Play(aSoundID, KMPOINTF_ZERO, False, aVolume); // Redirect
end;


procedure TKMSoundPlayer.Play(aSoundID: TSoundFXNew; aVolume: Single = 1; aFadeMusic: Boolean = False);
begin
  if SKIP_SOUND or not fIsSoundInitialized then Exit;
  Play(aSoundID, KMPOINT_ZERO, False, aVolume, aFadeMusic);
end;


procedure TKMSoundPlayer.Play(aSoundID: TSoundFXNew; aLoc: TKMPoint; aAttenuated: Boolean = True; aVolume: Single = 1; aFadeMusic: Boolean = False);
begin
  if SKIP_SOUND or not fIsSoundInitialized then Exit;
  PlayWave(gRes.Sounds.FileOfNewSFX(aSoundID), KMPointF(aLoc), gRes.Sounds.GetSoundType(aSoundID), aAttenuated, aVolume, aFadeMusic);
end;


{Wrapper for TSoundFX}
procedure TKMSoundPlayer.Play(aSoundID: TSoundFX; aLoc: TKMPoint; aAttenuated: Boolean = True; aVolume: Single = 1);
begin
  if SKIP_SOUND or not fIsSoundInitialized then Exit;
  PlaySound(aSoundID, '', KMPointF(aLoc), gRes.Sounds.GetSoundType(aSoundID), aAttenuated, aVolume, MAX_DISTANCE, False, False); //Redirect
end;


procedure TKMSoundPlayer.Play(aSoundID: TSoundFX; aLoc: TKMPointF; aAttenuated: Boolean = True; aVolume: Single = 1);
begin
  if SKIP_SOUND or not fIsSoundInitialized then Exit;
  PlaySound(aSoundID, '', aLoc, gRes.Sounds.GetSoundType(aSoundID), aAttenuated, aVolume, MAX_DISTANCE, False, False); //Redirect
end;


{Wrapper WAV files}
function TKMSoundPlayer.PlayWave(const aFile: UnicodeString; const aLoc: TKMPointF; aSoundType: TKMSoundType; aAttenuated: Boolean = True;
                                 aVolume: Single = 1; aFadeMusic: Boolean = False; aLoop: Boolean = False): Integer;
begin
  Result := -1;
  if not fIsSoundInitialized then Exit;
  Result := PlaySound(sfxNone, aFile, aLoc, aSoundType, aAttenuated, aVolume, MAX_DISTANCE, aFadeMusic, aLoop); //Redirect
end;


{Call to this procedure will find free spot and start to play sound immediately}
{Will need to make another one for unit sounds, which will take WAV file path as parameter}
{Attenuated means if sound should fade over distance or not}
//Returns index in fALSound array
function TKMSoundPlayer.PlaySound(aSoundID: TSoundFX; const aFile: UnicodeString; const Loc: TKMPointF; aSoundType: TKMSoundType;
                                  aAttenuated: Boolean; aVolume: Single; aRadius: Single; aFadeMusic, aLooped: Boolean;
                                  aFromScript: Boolean = False): Integer;
var
  dif: array[1..3]of Single;
  freeBuf{,FreeSrc}: Integer;
  {$IFNDEF NO_OGG_SOUND}
  oggOpenResult: Integer;
  {$ENDIF}
  distance: Single;
  alState: TALint;
  wavFormat: TALenum;
  wavData: TALvoid;
  wavSize: TALsizei;
  wavFreq: TALsizei;
  wavLoop: TALint;
  wavDuration: Cardinal;
  fileExt: String;
  {$IFNDEF NO_OGG_SOUND}
  oggFileStream: TFileStream;
  oggVorbisFile: OggVorbis_File;
  vorbisInfo: P_Vorbis_Info;
  oggBytesRead, oggBytesChanged: Longword;
  oggBuffer: PChar;
  {$ENDIF}
begin
  Result := -1;
  if not fIsSoundInitialized then Exit;
  if (aSoundID = sfxNone) and (aFile = '') then Exit;

  // Do not play game sounds, if game is ready to stop
  if (aSoundType = stGame) and (gGame <> nil) and gGame.ReadyToStop then
    Exit;

  if aAttenuated then
  begin
    distance := GetLength(Loc.X-fListener.Pos[1], Loc.Y-fListener.Pos[2]);
    //If sound source is further than Radius away then don't play it. This stops the buffer being filled with sounds on the other side of the map.
    if (distance >= aRadius) then Exit;
    //If the sounds is a fairly long way away it should not play when we are short of slots
    if (distance >= aRadius*MAX_PRIORITY_DISTANCE_FACTOR) and (ActiveCount >= MAX_FAR_SOUNDS) then Exit;
    //Attenuated sounds are always lower priority, so save a few slots for non-attenuated so that troops
    //and menus always make sounds
    if (ActiveCount >= MAX_ATTENUATED_SOUNDS) then Exit;
  end;

  //Here should be some sort of RenderQueue/List/Clip

  //1. Find matching buffer
  //Found - add refCount and reference it
  //Not found
  //2. Find free buffer
  //


  //Find free buffer and use it
  freeBuf := -1;
  for var I := Low(fALSounds) to High(fALSounds) do
  begin
    alGetSourcei(fALSounds[i].ALSource, AL_SOURCE_STATE, @alState);
    if alState <> AL_PLAYING then
    begin
      freeBuf := I;
      Break;
    end;
  end;
  if freeBuf = -1 then Exit;//Don't play if there's no room left

  //Fade music if required (don't fade it if the user has SoundGain = 0, that's confusing)
  if aFadeMusic and (fVolume > 0) and not fMusicIsFaded then
  begin
    if Assigned(fOnFadeMusic) then fOnFadeMusic;
    fMusicIsFaded := True;
  end;

  //Stop previously playing sound and release buffer
  AlSourceStop(fALSounds[freeBuf].ALSource);
  AlSourcei(fALSounds[freeBuf].ALSource, AL_BUFFER, 0);

  //Assign new data to buffer and assign it to source
  if aSoundID = sfxNone then
  begin
    // Can not find sound file, silently Exit...
    if not FileExists(aFile) then
      Exit;

    fileExt := ExtractFileExt(aFile);
    try
      if LowerCase(fileExt) = WAV_FILE_EXT then
      begin
        alutLoadWAVFile(aFile,wavFormat,wavData,wavSize,wavFreq,wavLoop);
        AlBufferData(fALSounds[freeBuf].ALBuffer,wavFormat,wavData,wavSize,wavFreq);
        alutUnloadWAV(wavFormat,wavData,wavSize,wavFreq);
      end else if LowerCase(fileExt) = OGG_FILE_EXT then
      begin
        {$IFNDEF NO_OGG_SOUND}
        oggFileStream := TFileStream.Create(aFile, fmOpenRead or fmShareDenyNone);
        try
          oggOpenResult := ov_open_callbacks(oggFileStream, oggVorbisFile, nil, 0, ops_callbacks);
          if oggOpenResult <> 0 then
          begin
            gLog.AddTime('Error loading OGG sound file "%s": %s', [aFile, GetVorbisErrorName(oggOpenResult)]);
            Exit; // Ignore all errors
          end;

          // get ogg file info
          vorbisInfo := ov_info(oggVorbisFile, -1);

          if vorbisInfo.Channels = 1 then
            wavFormat := AL_FORMAT_MONO16
          else
            wavFormat := AL_FORMAT_STEREO16;

          wavSize := ov_pcm_total(oggVorbisFile, -1) * 4;
          wavFreq := vorbisInfo.Rate;

          GetMem(oggBuffer, wavSize);
          try
            oggBytesRead := 0;
            // Load ogg file into the buffer with ov_read
            repeat
              oggBytesChanged := ov_read(oggVorbisFile, PKMStaticByteArray(oggBuffer)^[oggBytesRead], wavSize - oggBytesRead, 0, 2, 1, nil);
              oggBytesRead := oggBytesRead + oggBytesChanged;
            until (oggBytesChanged = 0) or (oggBytesRead >= wavSize);

            AlBufferData(fALSounds[freeBuf].ALBuffer,wavFormat,oggBuffer,wavSize,wavFreq);
          finally
            FreeMem(oggBuffer, wavSize);
          end;
        finally
          oggFileStream.Free;
        end;
        {$ENDIF}
      end
      else
        raise Exception.Create('Unsupported sound file format: ' + fileExt);

      wavDuration := round(wavSize / wavFreq * 1000);
      case wavFormat of
        AL_FORMAT_STEREO16: wavDuration := wavDuration div 4;
        AL_FORMAT_STEREO8: wavDuration := wavDuration div 2;
        AL_FORMAT_MONO16: wavDuration := wavDuration div 2;
      end;
    except
      //This happens regularly if you run two copies of the game out of one folder and they share the MP chat sound.
      //We ignore the error to make it possible to run two copies out of one folder (especially for debugging) without
      //continual clashes over sound files.
      on E: EFOpenError do
      begin
        gLog.AddTime('Error loading sound file: ' + E.Message);
        Exit;
      end;
    end;
  end
  else
  begin
    var soundId := word(aSoundID);
    // Can not find sound with this Id, silently Exit...
    if soundId > gRes.Sounds.WavesCount then
      Exit;

    var W := gRes.Sounds.fWaves[soundId];

    Assert(W.IsLoaded, 'Sounds.dat seems to be short');

    if FEAT_SFX_ADJUSTED_SAMPLE_RATE then
    begin
      case W.Head.BitsPerSample of
        8:  wavFormat := AL_FORMAT_MONO8;
        16: wavFormat := AL_FORMAT_MONO16;
      else
        raise Exception.Create('Unexpected wave bit depth');
      end;

      var wavSampleRate := gRes.Sounds.fWaveProps[soundId].SampleRate;
      AlBufferData(fALSounds[freeBuf].ALBuffer, wavFormat, @W.Data[0], W.Head.DataSize, wavSampleRate);
      wavDuration := Round(W.Head.DataSize / wavSampleRate / W.Head.BytesPerSample * 1000);
    end else
    begin
      AlBufferData(fALSounds[freeBuf].ALBuffer, AL_FORMAT_MONO8, @W.Data[0], W.Head.DataSize, W.Head.SampleRate);
      wavSize := W.Head.FileSize;
      wavFreq := W.Head.BytesPerSecond;
      wavDuration := round(wavSize / wavFreq * 1000);
    end;
  end;

  //Set source properties
  AlSourcei(fALSounds[freeBuf].ALSource, AL_BUFFER, fALSounds[freeBuf].ALBuffer);
  AlSourcef(fALSounds[freeBuf].ALSource, AL_PITCH, 1);
  AlSourcef(fALSounds[freeBuf].ALSource, AL_GAIN, 1 * aVolume * fVolume);
  if aAttenuated then
  begin
    dif[1]:=Loc.X; dif[2]:=Loc.Y; dif[3]:=0;
    AlSourcefv(fALSounds[freeBuf].ALSource, AL_POSITION, @dif[1]);
    AlSourcei(fALSounds[freeBuf].ALSource, AL_SOURCE_RELATIVE, AL_FALSE); //If Attenuated then it is not relative to the listener
  end else
  begin
    //For sounds that do not change over distance, set to SOURCE_RELATIVE and make the position be 0,0,0 which means it will follow the listener
    //Do not simply set position to the listener as the listener could change while the sound is playing
    dif[1]:=0; dif[2]:=0; dif[3]:=0;
    AlSourcefv(fALSounds[freeBuf].ALSource, AL_POSITION, @dif[1]);
    AlSourcei(fALSounds[freeBuf].ALSource, AL_SOURCE_RELATIVE, AL_TRUE); //Relative to the listener, meaning it follows us
  end;
  AlSourcef(fALSounds[freeBuf].ALSource, AL_REFERENCE_DISTANCE, 4);
  AlSourcef(fALSounds[freeBuf].ALSource, AL_MAX_DISTANCE, aRadius);
  AlSourcef(fALSounds[freeBuf].ALSource, AL_ROLLOFF_FACTOR, 1);

  if aLooped then
    AlSourcei(fALSounds[freeBuf].ALSource, AL_LOOPING, AL_TRUE)
  else
    AlSourcei(fALSounds[freeBuf].ALSource, AL_LOOPING, AL_FALSE);

  //Start playing
  AlSourcePlay(fALSounds[freeBuf].ALSource);
  if aSoundID <> sfxNone then
    fALSounds[freeBuf].Name := GetEnumName(TypeInfo(TSoundFX), Integer(aSoundID))
  else
    fALSounds[freeBuf].Name := ExtractFileName(aFile);
  fALSounds[freeBuf].Position := Loc;
  fALSounds[freeBuf].Duration := wavDuration;
  fALSounds[freeBuf].PlaySince := TimeGet;
  fALSounds[freeBuf].Volume := aVolume;
  fALSounds[freeBuf].FromScript := aFromScript;
  fALSounds[freeBuf].Looped := aLooped;
  fALSounds[freeBuf].FadesMusic := aFadeMusic;

  Result := freeBuf;
end;


procedure TKMSoundPlayer.PlayCitizen(aUnitType: TKMUnitType; aSound: TWarriorSpeech);
begin
  if SKIP_SOUND
    or not fIsSoundInitialized
    or ((gMySpectator.Selected <> nil) and not gMySpectator.IsSelectedMyObj) then // Do not play sound for ally's citizens selection
    Exit;

  PlayCitizen(aUnitType, aSound, KMPOINTF_ZERO);
end;


procedure TKMSoundPlayer.PlayCitizen(aUnitType: TKMUnitType; aSound: TWarriorSpeech; const aLoc: TKMPointF);
var
  wave: UnicodeString;
  hasLoc: Boolean;
begin
  if SKIP_SOUND or not fIsSoundInitialized then Exit;
  if not (aUnitType in [CITIZEN_MIN..CITIZEN_MAX]) then Exit;

  hasLoc := not KMSamePointF(aLoc, KMPOINTF_ZERO);
  wave := gRes.Sounds.FileOfCitizen(aUnitType, aSound);
  if FileExists(wave) then
    PlayWave(wave, aLoc, gRes.Sounds.GetSoundType(aSound), hasLoc, 1 + 3*byte(hasLoc)); //Attenuate sounds when aLoc is valid
end;


procedure TKMSoundPlayer.PlayNotification(aSound: TAttackNotification);
var
  wave: UnicodeString;
  count: Byte;
begin
  if SKIP_SOUND or not fIsSoundInitialized then Exit;

  count := gRes.Sounds.NotificationSoundCount[aSound];

  wave := gRes.Sounds.FileOfNotification(aSound, Random(count));
  if FileExists(wave) then
    PlayWave(wave, KMPOINTF_ZERO, gRes.Sounds.GetSoundType(aSound), False, 1);
end;


procedure TKMSoundPlayer.PlayWarrior(aUnitType: TKMUnitType; aSound: TWarriorSpeech);
begin
  if SKIP_SOUND
    or not fIsSoundInitialized
    or ((gMySpectator.Selected <> nil) and not gMySpectator.IsSelectedMyObj) then // Do not play sound for ally's warriors
    Exit;

  PlayWarrior(aUnitType, aSound, KMPOINTF_ZERO);
end;


procedure TKMSoundPlayer.PlayWarrior(aUnitType: TKMUnitType; aSound: TWarriorSpeech; const aLoc: TKMPointF);
var
  wave: UnicodeString;
  hasLoc: Boolean;
  count: Byte;
begin
  if SKIP_SOUND or not fIsSoundInitialized then Exit;
  if not (aUnitType in [WARRIOR_MIN..WARRIOR_MAX]) then Exit;

  count := gRes.Sounds.WarriorSoundCount[aUnitType, aSound];

  hasLoc := not KMSamePointF(aLoc, KMPOINTF_ZERO);
  wave := gRes.Sounds.FileOfWarrior(aUnitType, aSound, Random(count));
  if FileExists(wave) then
    PlayWave(wave, aLoc, gRes.Sounds.GetSoundType(aSound), hasLoc, 1 + 3*Byte(hasLoc)); //Attenuate sounds when aLoc is valid
end;


function TKMSoundPlayer.CanAddLoopSound: Boolean;
var
  I, cnt: Integer;
begin
  Result := True;
  cnt := 0;
  for I := Low(fScriptSoundALIndex) to High(fScriptSoundALIndex) do
  begin
    if (fScriptSoundALIndex[I] <> -1) and fALSounds[fScriptSoundALIndex[I]].Looped then
      Inc(cnt);
    if cnt >= MAX_LOOP_SOUNDS then
      Exit(False);
  end;
end;


//Returns -1 if it was not possible to start play sound (f.e. sounds queue is overloaded)
//        Script Sound Index in fScriptSoundALIndex array
function TKMSoundPlayer.PlayScriptSound(const aFile: UnicodeString; aLoc: TKMPointF; aAttenuate: Boolean; aVolume: Single;
                                        aRadius: Single; aFadeMusic, aLooped: Boolean): Integer;
var
  I: Integer;
begin
  Result := -1; //Failed to play

  //Do not allow too many loop sounds
  if aLooped and not CanAddLoopSound then
    Exit;

  for I := Low(fScriptSoundALIndex) to High(fScriptSoundALIndex) do
    if fScriptSoundALIndex[I] = -1 then //Empty slot here
    begin
      //Save sound index from fALSound array
      fScriptSoundALIndex[I] := PlaySound(sfxNone, aFile, aLoc, stGame, aAttenuate, aVolume, aRadius, aFadeMusic, aLooped, True);
      if fScriptSoundALIndex[I] <> -1 then
        Result := I; //Successfully playing
      Exit;
    end;
end;


procedure TKMSoundPlayer.StopScriptSound(aIndex: Integer);
begin
  if not fIsSoundInitialized then Exit;
  if fScriptSoundALIndex[aIndex] = -1 then Exit;

  //Stop previously playing sound and release buffer
  AlSourceStop(fALSounds[fScriptSoundALIndex[aIndex]].ALSource);
  AlSourcei(fALSounds[fScriptSoundALIndex[aIndex]].ALSource, AL_BUFFER, 0);

  fALSounds[fScriptSoundALIndex[aIndex]].PlaySince := 0;
  fScriptSoundALIndex[aIndex] := -1;
end;


procedure TKMSoundPlayer.AbortAllScriptSounds;
var
  I: Integer;
begin
  for I := Low(fScriptSoundALIndex) to High(fScriptSoundALIndex) do
    StopScriptSound(I);
end;


function TKMSoundPlayer.IsSoundPlaying(aIndex: Integer): Boolean;
begin
  if aIndex < 0 then Exit(False);

  Result := (fALSounds[aIndex].PlaySince <> 0)
      and ((TimeSince(fALSounds[aIndex].PlaySince) < fALSounds[aIndex].Duration) or fALSounds[aIndex].Looped);
end;


function TKMSoundPlayer.IsScriptSoundPlaying(aScriptIndex: Integer): Boolean;
begin
  Assert(InRange(aScriptIndex, Low(fScriptSoundALIndex), High(fScriptSoundALIndex)),
    Format('Script sounds index [ %d ] is not in range!', [aScriptIndex]));

  Result := IsSoundPlaying(fScriptSoundALIndex[aScriptIndex]);
end;


function TKMSoundPlayer.ActiveCount: Byte;
var
  I: Integer;
begin
  Result := 0;
  for I := Low(fALSounds) to High(fALSounds) do
    if IsSoundPlaying(I) then
      Inc(Result)
    else
      fALSounds[I].PlaySince := 0;
end;


procedure TKMSoundPlayer.Paint;
var
  I: Integer;
begin
  gRenderAux.CircleOnTerrain(fListener.Pos[1], fListener.Pos[2], MAX_DISTANCE, $00000000, $FFFFFFFF);
  for I := Low(fALSounds) to High(fALSounds) do
    if IsSoundPlaying(I) then
    begin
      gRenderAux.CircleOnTerrain(fALSounds[I].Position.X, fALSounds[I].Position.Y, 5, $4000FFFF, $FFFFFFFF);
      gRenderAux.Text(Round(fALSounds[I].Position.X), Round(fALSounds[I].Position.Y), fALSounds[I].Name, $FFFFFFFF);
    end else
      fALSounds[I].PlaySince := 0;
end;


procedure TKMSoundPlayer.UpdateStateIdle;
var
  I: Integer;
begin
  if not fMusicIsFaded then Exit;

  for I := Low(fALSounds) to High(fALSounds) do
    if fALSounds[I].FadesMusic then
    begin
      if (fALSounds[I].PlaySince <> 0) and (TimeSince(fALSounds[I].PlaySince) < fALSounds[I].Duration) then
        Exit //There is still a faded sound playing
      else
        fALSounds[I].FadesMusic := False; //Make sure we don't resume more than once for this sound
    end;
  //If we reached the end without exiting then we need to resume the music
  fMusicIsFaded := False;
  if Assigned(fOnUnfadeMusic) then
    fOnUnfadeMusic;
end;


end.
