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

    fOnFadeMusic: TEvent;
    fOnUnfadeMusic: TEvent;
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

    property PrevVolume: Single read GetPrevVolume write fPrevVolume;
  public
    constructor Create(aVolume: Single);
    destructor Destroy; override;
    function ActiveCount: Byte;

    property OnRequestFade: TEvent write fOnFadeMusic;
    property OnRequestUnfade: TEvent write fOnUnfadeMusic;
    procedure AbortAllFadeSounds;
    procedure AbortAllScriptSounds;
    procedure AbortAllLongSounds;

    procedure UpdateListener(X,Y: Single);
    procedure UpdateSoundVolume(aValue: Single);
    property Volume: Single read fVolume write UpdateSoundVolume;
    procedure ToggleMuted;

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

    function ToString: String; override;
  end;


var
  gSoundPlayer: TKMSoundPlayer;
  gScriptSounds: TKMScriptSoundsManager;


implementation
uses
  Classes, Dialogs, SysUtils, TypInfo, Math, KromUtils,
  {$IFDEF WDC} UITypes, {$ENDIF}
  {$IFNDEF NO_OGG_SOUND}
  Codec, VorbisFile,
  {$ENDIF}
  KM_Game, KM_Resource, KM_HandsCollection, KM_RenderAux,
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
var
  I: Integer;
  context: PALCcontext;
  numMono, numStereo: TALCint;
begin
  inherited Create;

  for I := Low(fScriptSoundALIndex) to High(fScriptSoundALIndex) do
    fScriptSoundALIndex[I] := -1;

  if SKIP_SOUND then Exit;

  fIsSoundInitialized := InitOpenAL;
  Set8087CW($133F); //Above OpenAL call messes up FPU settings
  if not fIsSoundInitialized then begin
    gLog.AddNoTime('OpenAL warning. OpenAL could not be initialized.');
    //MessageDlg works better than Application.MessageBox or others, it stays on top and pauses here until the user clicks ok.
    MessageDlg('OpenAL could not be initialized. Please refer to Readme.html for solution', mtWarning, [mbOk], 0);
    fIsSoundInitialized := false;
    Exit;
  end;

  //Open device
  fALDevice := alcOpenDevice(nil); // this is supposed to select the "preferred device"
  Set8087CW($133F); //Above OpenAL call messes up FPU settings
  if fALDevice = nil then begin
    gLog.AddNoTime('OpenAL warning. Device could not be opened.');
    //MessageDlg works better than Application.MessageBox or others, it stays on top and pauses here until the user clicks ok.
    MessageDlg('OpenAL device could not be opened. Please refer to Readme.html for solution', mtWarning, [mbOk], 0);
    fIsSoundInitialized := false;
    Exit;
  end;

  //Create context(s)
  context := alcCreateContext(fALDevice, nil);
  Set8087CW($133F); //Above OpenAL call messes up FPU settings
  if context = nil then begin
    gLog.AddNoTime('OpenAL warning. Context could not be created.');
    //MessageDlg works better than Application.MessageBox or others, it stays on top and pauses here until the user clicks ok.
    MessageDlg('OpenAL context could not be created. Please refer to Readme.html for solution', mtWarning, [mbOk], 0);
    fIsSoundInitialized := false;
    Exit;
  end;

  //Set active context
  I := alcMakeContextCurrent(context);
  Set8087CW($133F); //Above OpenAL call messes up FPU settings
  if I > 1 then begin //valid returns are AL_NO_ERROR=0 and AL_TRUE=1
    gLog.AddNoTime('OpenAL warning. Context could not be made current.');
    //MessageDlg works better than Application.MessageBox or others, it stays on top and pauses here until the user clicks ok.
    MessageDlg('OpenAL context could not be made current. Please refer to Readme.html for solution', mtWarning, [mbOk], 0);
    fIsSoundInitialized := false;
    Exit;
  end;

  CheckOpenALError;
  if not fIsSoundInitialized then Exit;

  //Set attenuation model
  alDistanceModel(AL_LINEAR_DISTANCE_CLAMPED);
  gLog.AddTime('Pre-LoadSFX init', True);

  alcGetIntegerv(fALDevice, ALC_MONO_SOURCES, 4, @numMono);
  alcGetIntegerv(fALDevice, ALC_STEREO_SOURCES, 4, @numStereo);

  gLog.AddTime('ALC_MONO_SOURCES',numMono);
  gLog.AddTime('ALC_STEREO_SOURCES',numStereo);

  for I := Low(fALSounds) to High(fALSounds) do
  begin
    AlGenBuffers(1, @fALSounds[i].ALBuffer);
    AlGenSources(1, @fALSounds[i].ALSource);
  end;

  CheckOpenALError;
  if not fIsSoundInitialized then Exit;

  //Set default Listener orientation
  fListener.Ori[1] := 0; fListener.Ori[2] := 0; fListener.Ori[3] := -1; //Look-at vector
  fListener.Ori[4] := 0; fListener.Ori[5] := 1; fListener.Ori[6] := 0; //Up vector
  AlListenerfv(AL_ORIENTATION, @fListener.Ori);
  fVolume := aVolume;
  fPrevVolume := aVolume;

  gLog.AddTime('OpenAL init done');
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

  Play(aSoundID, KMPOINTF_ZERO, false, aVolume); // Redirect
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
  I, ID, oggOpenResult: Integer;
  W: TKMSoundData;
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

  //Do not play game sounds, if game is ready to stop
  if (aSoundType = stGame) and (gGame <> nil) and (gGame.ReadyToStop) then
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
  for I := Low(fALSounds) to High(fALSounds) do
  begin
    alGetSourcei(fALSounds[i].ALSource, AL_SOURCE_STATE, @alState);
    if alState<>AL_PLAYING then
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
    fMusicIsFaded := true;
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
            gLog.AddTime('Error loading OGG sound file ''' + aFile + ''': ' + GetVorbisErrorName(oggOpenResult));
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
    ID := word(aSoundID);
    // Can not find sound with ID, silently Exit...
    if ID > gRes.Sounds.fWavesCount then
      Exit;

    W := gRes.Sounds.fWaves[ID];

    Assert(W.IsLoaded and (ID <= gRes.Sounds.fWavesCount), 'Sounds.dat seems to be short');
    AlBufferData(fALSounds[freeBuf].ALBuffer, AL_FORMAT_MONO8, @W.Data[0], W.Head.DataSize, W.Head.SampleRate);
    wavSize := W.Head.FileSize;
    wavFreq := W.Head.BytesPerSecond;
    wavDuration := round(wavSize / wavFreq * 1000);
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
      and ((TimeSince(fALSounds[aIndex].PlaySince) < fALSounds[aIndex].Duration) or fALSounds[aIndex].Looped)
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


{ TKMLoopSoundsManager }
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
  Result := ((aScriptSound.HandIndex = gMySpectator.HandID) or (aScriptSound.HandIndex = PLAYER_NONE))
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
  TArray.Sort<Integer>(keyArray);
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


function TKMScriptSoundsManager.ToString: String;
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

  Result := Format('|Script sounds cnt = %d|RemoveRequests: CNT = %d:|%s', [fScriptSounds.Count, fSoundRemoveRequests.Count, str]);
end;


{ TKMScriptSound }
constructor TKMScriptSound.Create;
begin
  PlayingIndex := -1;
  RemoveRequestSent := False;
  Looped := False;
  FadeMusic := False;
  ScriptUID := 0;
  SoundName := '';
  AudioFormat := Low(TKMAudioFormat);
  Volume := 0.0;
  Radius := 0.0;
  Attenuate := False;
  Loc := KMPoint(0,0);
  HandIndex := 0;
end;


end.
