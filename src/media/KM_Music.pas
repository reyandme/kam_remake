unit KM_Music;
{$I KaM_Remake.inc}
interface

//We have two choices for music libraries:
//BASS: Free for non-commercial projects. Requires bass.dll. Website: http://www.un4seen.com/
//ZLibPlay: GNU GPL license. Requires libzplay.dll. Website: http://libzplay.sourceforge.net/

//Comparison: - BASS's DLL is much smaller (102kb vs 2.13mb(!)) and BASS seems faster at loading tracks.
//            - ZLibPlay supports more formats, (FLAC, AC-3, AAC, PCM) but we don't care
//            - ZLibPlay is GPL but BASS is not, and BASS can only be used for free in non-commercial products

{$IFNDEF NO_MUSIC}
  {$DEFINE USEBASS}
  {$IFDEF MSWindows}
    {.$DEFINE USELIBZPLAY}
  {$ENDIF}
{$ENDIF}

uses
  Types
  {$IFDEF USEBASS}     , Bass {$ENDIF}
  {$IFDEF USELIBZPLAY} , libZPlay {$ENDIF}
  ;

type
  // We have two kinds of playable music:
  // Track/Song - song we are playing now from the list
  // Other/Briefing - voice file we play for campaign briefing
  //todo -cComplicated: Would be nice to choose just 2 terms and stick to them
  TKMMusicLib = class
  private type
    TKMFadeState = (fsNone, fsFadeOut, fsFadeIn, fsFaded);
  private
    fCount: Integer;
    fIndex: Integer; //Points to the index in TrackOrder of the current track
    fTracks: TStringDynArray;
    fTrackOrder: TIntegerDynArray; //Each index points to an index of MusicTracks
    //MIDICount,MIDIIndex:integer;
    //MIDITracks: array[1..256]of string;
    fIsInitialized: Boolean;
    fEnabled: Boolean;
    fPrevVolume: Single; // Volume before mute
    fVolume: Single;
    {$IFDEF USEBASS} fBassStream, fBassOtherStream: Cardinal; {$ENDIF}
    {$IFDEF USELIBZPLAY} ZPlayer, ZPlayerOther: ZPlay; {$ENDIF} //I dislike that it's not TZPlay... Guess they don't know Delphi conventions.
    fFadeState: TKMFadeState;
    fFadeStarted: Cardinal;
    fFadeTime: Integer;
    fToPlayAfterFade: UnicodeString;
    fFadedToPlayOther: Boolean;
    fOtherVolume: Single;
    procedure PlayFile(const FileName: UnicodeString);
    procedure PlayOtherFile(const FileName: UnicodeString);
    procedure ScanTracks(const aPath: UnicodeString);
    procedure ShuffleSongs; //should not be seen outside of this class
    procedure UnshuffleSongs;

    procedure SetVolume(aValue: Single);
    function GetVolume: Single;
    procedure SetMuted(const aMuted: Boolean);
    function GetMuted: Boolean;
    function GetPrevVolume: Single;

    property PrevVolume: Single read GetPrevVolume write fPrevVolume;
  public
    constructor Create(aVolume: Single);
    destructor Destroy; override;

    property Volume: Single read GetVolume write SetVolume;
    property Muted: Boolean read GetMuted write SetMuted;
    procedure SetPlayerVolume(aValue: Single);

    procedure PlayMenuTrack;
    procedure PlayNextTrack;
    procedure PlayPreviousTrack;
    function IsEnded: Boolean;
    function IsOtherEnded: Boolean;
    procedure Pause;
    procedure Resume;
    procedure Stop;
    procedure ToggleMuted;
    procedure ToggleEnabled(aEnableMusic: Boolean);
    procedure ToggleShuffle(aEnableShuffle: Boolean);
    procedure Fade; overload;
    procedure Fade(aFadeTime: Integer); overload;
    procedure UnfadeStarting;
    procedure Unfade; overload;
    procedure Unfade(aFadeTime: Integer; aHandleCrackling: Boolean = False); overload;
    procedure PauseToPlayFile(const aFileName: UnicodeString; aVolume: Single);
    procedure StopPlayingOtherFile;
    function GetTrackTitle: UnicodeString;
    procedure UpdateStateIdle; //Used for fading
  end;


var
  gMusic: TKMMusicLib;


implementation
uses
  SysUtils, KromUtils, Math,
  KM_Defaults,
  KM_Log, KM_CommonUtils;


const
  STARTING_MUSIC_UNFADE_TIME = 500; //Time to unfade game starting music, in ms
  FADE_TIME = 2000; //Time that a fade takes to occur in ms


{ TKMMusicLib }
constructor TKMMusicLib.Create(aVolume: Single);
var
  I: Integer;
begin
  inherited Create;
  fIsInitialized := True;
  fEnabled := True;

  if not DirectoryExists(ExeDir + 'Music') then
    ForceDirectories(ExeDir + 'Music');

  ScanTracks(ExeDir + 'Music' + PathDelim);


  {$IFDEF USELIBZPLAY}
  ZPlayer := ZPlay.Create; //Note: They should have used TZPlay not ZPlay for a class
  ZPlayerOther := ZPlay.Create;
  {$ENDIF}

  {$IFDEF USEBASS}
  // Setup output - default device, 44100hz, stereo, 16 bits
  BASS_SetConfig(BASS_CONFIG_DEV_DEFAULT, 1);
  if not BASS_Init(-1, 44100, 0, 0, nil) then
  begin
    gLog.AddTime('Failed to initialize the music playback device');
    fIsInitialized := False;
  end;
  {$ENDIF}

  SetVolume(aVolume);

  // Initialise TrackOrder
  for I := 0 to fCount - 1 do
    fTrackOrder[I] := I;

  gLog.AddTime('Music init done, ' + IntToStr(fCount) + ' tracks found');
end;


destructor TKMMusicLib.Destroy;
begin
  {$IFDEF USELIBZPLAY}
  ZPlayer.Free;
  ZPlayerOther.Free;
  {$ENDIF}

  {$IFDEF USEBASS}
  BASS_Stop; //Stop all Bass output
  //Free the streams we may have used (will just return False if the stream is invalid)
  BASS_StreamFree(fBassStream);
  BASS_StreamFree(fBassOtherStream);
  BASS_Free; //Frees this usage of BASS, allowing it to be recreated successfully
  {$ENDIF}

  inherited;
end;


procedure TKMMusicLib.PlayFile(const FileName: UnicodeString);
{$IFDEF USEBASS}
var
  errorCode: Integer;
{$ENDIF}
begin
  if not fIsInitialized then Exit;
  if fFadeState <> fsNone then Exit; //Don't start a new track while fading or faded

  //Cancel previous sound
  {$IFDEF USELIBZPLAY} ZPlayer.StopPlayback; {$ENDIF}
  {$IFDEF USEBASS} BASS_ChannelStop(fBassStream); {$ENDIF}

  if not FileExists(FileName) then Exit; //Make it silent

  {$IFDEF USELIBZPLAY}
  if not ZPlayer.OpenFile(AnsiString(FileName), sfAutodetect) then //Detect file type automatically
    Exit; //File failed to load
  if not ZPlayer.StartPlayback then
    Exit; //Playback failed to start
  {$ENDIF}
  {$IFDEF USEBASS}
  BASS_StreamFree(fBassStream); //Free the existing stream (will just return False if the stream is invalid)
  fBassStream := BASS_StreamCreateFile(FALSE, PChar(FileName), 0, 0, BASS_STREAM_AUTOFREE {$IFDEF UNICODE} or BASS_UNICODE{$ENDIF});

  BASS_ChannelPlay(fBassStream, True); //Start playback from the beggining

  errorCode := BASS_ErrorGetCode;
  if errorCode <> BASS_OK then Exit; //Error
  {$ENDIF}

  SetVolume(fVolume); //Need to reset music volume after starting playback
end;


procedure TKMMusicLib.PlayOtherFile(const FileName: UnicodeString);
{$IFDEF USEBASS}
var
  errorCode: Integer;
{$ENDIF}
begin
  if not fIsInitialized then Exit;

  //Cancel previous sound
  {$IFDEF USELIBZPLAY} ZPlayerOther.StopPlayback; {$ENDIF}
  {$IFDEF USEBASS} BASS_ChannelStop(fBassOtherStream); {$ENDIF}

  if not FileExists(FileName) then Exit; //Make it silent

  {$IFDEF USELIBZPLAY}
  if not ZPlayerOther.OpenFile(AnsiString(FileName), sfAutodetect) then //Detect file type automatically
    Exit; //File failed to load
  if not ZPlayerOther.StartPlayback then
    Exit; //Playback failed to start
  {$ENDIF}
  {$IFDEF USEBASS}
  BASS_StreamFree(fBassOtherStream); //Free the existing stream (will just return False if the stream is invalid)
  fBassOtherStream := BASS_StreamCreateFile(FALSE, PChar(FileName), 0, 0, BASS_STREAM_AUTOFREE {$IFDEF UNICODE} or BASS_UNICODE{$ENDIF});

  BASS_ChannelPlay(fBassOtherStream, True); //Start playback from the beggining

  errorCode := BASS_ErrorGetCode;
  if errorCode <> BASS_OK then Exit; //Error
  {$ENDIF}

  //Now set the volume to the desired level
  {$IFDEF USELIBZPLAY}
  ZPlayerOther.SetPlayerVolume(Round(fOtherVolume * 100), Round(fOtherVolume * 100)); //0=silent, 100=max
  {$ENDIF}
  {$IFDEF USEBASS}
  BASS_ChannelSetAttribute(fBassOtherStream, BASS_ATTRIB_VOL, fOtherVolume); //0=silent, 1=max
  {$ENDIF}
end;


{Update music gain (global volume for all sounds/music)}
procedure TKMMusicLib.SetVolume(aValue: Single);
begin
  if not fIsInitialized then Exit; //Keep silent
  if not fEnabled then Exit;

  fVolume := aValue;

  if fVolume > 0 then
    fPrevVolume := fVolume;

  SetPlayerVolume(fVolume);
end;


// Set player volume (game music volume stays unchanged)
procedure TKMMusicLib.SetPlayerVolume(aValue: Single);
begin
  {$IFDEF USELIBZPLAY}
  ZPlayer.SetPlayerVolume(Round(aValue * 100), Round(aValue * 100)); //0=silent, 100=max
  {$ENDIF}
  {$IFDEF USEBASS}
  BASS_ChannelSetAttribute(fBassStream, BASS_ATTRIB_VOL, aValue); //0=silent, 1=max
  {$ENDIF}
end;


function TKMMusicLib.GetVolume: Single;
{$IFDEF USELIBZPLAY}
var
  LeftVolume, RightVolume: Integer;
{$ENDIF}
begin
  Result := 0.0;

  {$IFDEF USELIBZPLAY}
  ZPlayer.GetPlayerVolume(LeftVolume, RightVolume); //0=silent, 100=max
  Result := LeftVolume / 100;
  {$ENDIF}
  {$IFDEF USEBASS}
  BASS_ChannelGetAttribute(fBassStream, BASS_ATTRIB_VOL, Result);
  {$ENDIF}
end;


procedure TKMMusicLib.ScanTracks(const aPath: UnicodeString);
var
  searchRec: TSearchRec;
begin
  if not fIsInitialized then Exit;
  fCount := 0;
  if not DirectoryExists(aPath) then Exit;

  SetLength(fTracks, 255);

  FindFirst(aPath + '*.*', faAnyFile - faDirectory, searchRec);
  try
    repeat
      if (GetFileExt(searchRec.Name) = 'MP3') //Allow all formats supported by both libraries
      or (GetFileExt(searchRec.Name) = 'MP2')
      or (GetFileExt(searchRec.Name) = 'MP1')
      or (GetFileExt(searchRec.Name) = 'WAV')
      or (GetFileExt(searchRec.Name) = 'OGG')
      {$IFDEF USEBASS} //Formats supported by BASS but not LibZPlay
      or (GetFileExt(SearchRec.Name) = 'AIFF')
      {$ENDIF}
      {$IFDEF USELIBZPLAY} //Formats supported by LibZPlay but not BASS
      or (GetFileExt(searchRec.Name) = 'FLAC')
      or (GetFileExt(searchRec.Name) = 'OGA')
      or (GetFileExt(searchRec.Name) = 'AC3')
      or (GetFileExt(searchRec.Name) = 'AAC')
      {$ENDIF}
      then
      begin
        Inc(fCount);
        if fCount > Length(fTracks) then
          SetLength(fTracks, Length(fTracks) + 32);

        fTracks[fCount - 1] := aPath + searchRec.Name;
      end;
      {if GetFileExt(SearchRec.Name)='MID' then
      begin
        Inc(MIDICount);
        MIDITracks[MIDICount] := Path + SearchRec.Name;
      end;}
    until (FindNext(searchRec) <> 0);
  finally
    FindClose(searchRec);
  end;

  //Cut to length
  SetLength(fTracks, fCount);
  SetLength(fTrackOrder, fCount);

  fIndex := -1;
end;


procedure TKMMusicLib.PlayMenuTrack;
var
  prevVolume: Single;
begin
  if not fIsInitialized then Exit;
  if fCount = 0 then Exit; //no music files found
  if fIndex = 0 then Exit; //It's already playing
  fIndex := 0;
  // There was audio crackling after loading screen, here we fix it by setting a delay and fading the volume.
  prevVolume := fVolume;
  fVolume := 0;
  PlayFile(fTracks[0]);
  fVolume := prevVolume;
  UnfadeStarting;
end;


procedure TKMMusicLib.PlayNextTrack;
begin
  if not fIsInitialized then Exit;
  if fCount = 0 then Exit; //no music files found
  if fFadeState <> fsNone then Exit;

  //Set next index, looped or random
  fIndex := (fIndex + 1) mod fCount;
  PlayFile(fTracks[fTrackOrder[fIndex]]);
end;


procedure TKMMusicLib.PlayPreviousTrack;
begin
  if not fIsInitialized then Exit;
  if fCount = 0 then Exit; //no music files found
  if fFadeState <> fsNone then Exit;

  fIndex := (fIndex + fCount - 1) mod fCount;
  PlayFile(fTracks[fTrackOrder[fIndex]]);
end;


//Check if Music is not playing, to know when new mp3 should be feeded
function TKMMusicLib.IsEnded: Boolean;
{$IFDEF USELIBZPLAY}
var
  status: TStreamStatus;
{$ENDIF}
begin
  {$IFDEF USELIBZPLAY} ZPlayer.GetStatus(status); {$ENDIF}
  Result := fIsInitialized
            {$IFDEF USELIBZPLAY}
            and (not status.fPlay and not status.fPause) //Not playing and not paused due to fade
            {$ENDIF}
            {$IFDEF USEBASS}
            and (BASS_ChannelIsActive(fBassStream) = BASS_ACTIVE_STOPPED)
            {$ENDIF}
            ;
end;


//Check if other is not playing, to know when to return to the music
function TKMMusicLib.IsOtherEnded: Boolean;
{$IFDEF USELIBZPLAY}
var
  status: TStreamStatus;
{$ENDIF}
begin
  {$IFDEF USELIBZPLAY} ZPlayerOther.GetStatus(status); {$ENDIF}
  Result := fIsInitialized
            {$IFDEF USELIBZPLAY}
            and (not status.fPlay) //Not playing and not paused due to fade
            {$ENDIF}
            {$IFDEF USEBASS}
            and (BASS_ChannelIsActive(fBassOtherStream) = BASS_ACTIVE_STOPPED)
            {$ENDIF}
            ;
end;


procedure TKMMusicLib.Stop;
begin
  if (Self = nil) or not fIsInitialized then Exit;
  {$IFDEF USELIBZPLAY} ZPlayer.StopPlayback; {$ENDIF}
  {$IFDEF USEBASS} BASS_ChannelStop(fBassStream); {$ENDIF}
  fIndex := -1;
end;


procedure TKMMusicLib.ToggleEnabled(aEnableMusic: Boolean);
begin
  fEnabled := aEnableMusic;
  if aEnableMusic then
    PlayMenuTrack //Start with the default track
  else
    Stop;
end;


function TKMMusicLib.GetMuted: Boolean;
begin
  Result := (fVolume = 0);
end;


function TKMMusicLib.GetPrevVolume: Single;
begin
  Result := IfThen(fPrevVolume = 0, 0.5, fPrevVolume);
end;


procedure TKMMusicLib.SetMuted(const aMuted: Boolean);
begin
  if Muted = aMuted then Exit;  // Nothing to change, just exit to avoid fPrevVolume overwrite

  if aMuted then
  begin
    fPrevVolume := fVolume;
    Volume := 0;
  end
  else
  begin
    Volume := PrevVolume;
    fPrevVolume := 0;
  end;
end;


procedure TKMMusicLib.ToggleMuted;
begin
  SetMuted(not GetMuted);
end;


procedure TKMMusicLib.ToggleShuffle(aEnableShuffle: Boolean);
begin
  if aEnableShuffle then
    ShuffleSongs
  else
    UnshuffleSongs;
end;


procedure TKMMusicLib.ShuffleSongs;
var
  I, R, curSong: Integer;
begin
  if fIndex = -1 then Exit; // Music is disabled

  // Stay on the current song
  curSong := fTrackOrder[fIndex];

  // Shuffle everything except for first (menu) track
  for I := fCount - 1 downto 1 do
  begin
    R := RandomRange(1, I);
    KromUtils.SwapInt(fTrackOrder[R], fTrackOrder[I]);
    if fTrackOrder[I] = curSong then
      fIndex := I;
  end;
end;


procedure TKMMusicLib.UnshuffleSongs;
var
  I: Integer;
begin
  if fIndex = -1 then Exit; // Music is disabled
  fIndex := fTrackOrder[fIndex];

  //Reset every index of the TrackOrder array
  for I := 0 to fCount - 1 do
    fTrackOrder[I] := I;
end;


procedure TKMMusicLib.Fade;
begin
  Fade(FADE_TIME);
end;


procedure TKMMusicLib.Fade(aFadeTime: Integer);
{$IFDEF USELIBZPLAY}
var
  startTime, endTime: TStreamTime;
  left, right: Integer;
{$ENDIF}
begin
  if (not fIsInitialized) then Exit;
  fFadeTime := aFadeTime;
  fFadeState := fsFadeOut; //Fade it out
  fFadeStarted := TimeGet;
  {$IFDEF USELIBZPLAY}
  ZPlayer.GetPosition(startTime);
  endTime.ms := startTime.ms + aFadeTime;
  ZPlayer.GetPlayerVolume(left, right); //Start fade from the current volume
  ZPlayer.SlideVolume(tfMillisecond, startTime, left, right, tfMillisecond, endTime, 0, 0);
  {$ENDIF}
  {$IFDEF USEBASS}
  BASS_ChannelSlideAttribute(fBassStream, BASS_ATTRIB_VOL, 0, aFadeTime);
  {$ENDIF}
end;


procedure TKMMusicLib.UnfadeStarting;
begin
  Unfade(STARTING_MUSIC_UNFADE_TIME, True);
end;


procedure TKMMusicLib.Unfade;
begin
  Unfade(FADE_TIME);
end;


// aHandleCrackling flag is used to mitigate initial sound crackling
procedure TKMMusicLib.Unfade(aFadeTime: Integer; aHandleCrackling: Boolean = False);
{$IFDEF USELIBZPLAY}
var
  startTime, endTime: TStreamTime;
  left, right: Integer;
{$ENDIF}
begin
  if (not fIsInitialized) then Exit;
  fFadeTime := aFadeTime;
  fFadeState := fsFadeIn; //Fade it in
  fFadeStarted := TimeGet;
  {$IFDEF USELIBZPLAY}
  //LibZPlay has a nice SlideVolume function we can use
  ZPlayer.ResumePlayback; //Music may have been paused due to fade out
  if aHandleCrackling then Sleep(25);
  ZPlayer.GetPosition(startTime);
  endTime.ms := startTime.ms + aFadeTime;
  ZPlayer.GetPlayerVolume(left, right); //Start fade from the current volume
  ZPlayer.SlideVolume(tfMillisecond, startTime, left, right, tfMillisecond, endTime, Round(fVolume * 100), Round(fVolume * 100));
  {$ENDIF}
  {$IFDEF USEBASS}
  BASS_ChannelPlay(fBassStream, False); //Music may have been paused due to fade out
  if aHandleCrackling then Sleep(25);
  BASS_ChannelSlideAttribute(fBassStream, BASS_ATTRIB_VOL, fVolume, aFadeTime);
  {$ENDIF}
end;


procedure TKMMusicLib.UpdateStateIdle;
begin
  if not fIsInitialized then Exit;

  case fFadeState of
    fsFadeIn:   if TimeSince(fFadeStarted) > fFadeTime then
                  fFadeState := fsNone;
    fsFadeOut:  begin
                  if TimeSince(fFadeStarted) > fFadeTime then
                  begin
                    fFadeState := fsFaded;
                    {$IFDEF USELIBZPLAY} ZPlayer.PausePlayback; {$ENDIF}
                    {$IFDEF USEBASS} BASS_ChannelPause(fBassStream); {$ENDIF}
                  end
                  else
                  //Start playback of other file half way through the fade
                  if (TimeSince(fFadeStarted) > fFadeTime div 2)
                    and (fToPlayAfterFade <> '') then
                  begin
                    fFadedToPlayOther := True;
                    PlayOtherFile(fToPlayAfterFade);
                    fToPlayAfterFade := '';
                  end;
                end;
  end;

  if fFadedToPlayOther and (fFadeState = fsFaded) and IsOtherEnded then
  begin
    fFadedToPlayOther := False;
    Unfade;
  end;
end;


procedure TKMMusicLib.Pause;
begin
  if not fIsInitialized then Exit;

  {$IFDEF USELIBZPLAY} ZPlayerOther.PausePlayback; {$ENDIF}
  {$IFDEF USEBASS} BASS_ChannelPause(fBassStream); {$ENDIF}
end;


procedure TKMMusicLib.Resume;
begin
  if not fIsInitialized then Exit;

  {$IFDEF USELIBZPLAY} ZPlayer.ResumePlayback; {$ENDIF}
  {$IFDEF USEBASS} BASS_ChannelPlay(fBassStream, False); {$ENDIF}
end;


procedure TKMMusicLib.PauseToPlayFile(const aFileName: UnicodeString; aVolume: single);
begin
  fOtherVolume := aVolume;
  if fFadeState in [fsNone, fsFadeIn] then
  begin
    Fade;
    fToPlayAfterFade := aFilename
  end
  else
    if (fFadeState = fsFaded) or ((fFadeState = fsFadeOut) and fFadedToPlayOther) then
    begin
      fFadedToPlayOther := True;
      PlayOtherFile(aFilename) //Switch playback immediately
    end
    else
      fToPlayAfterFade := aFilename; //We're still in the process of fading out, the file hasn't started yet
end;


procedure TKMMusicLib.StopPlayingOtherFile;
begin
  if not fIsInitialized then Exit;
  {$IFDEF USELIBZPLAY} ZPlayerOther.StopPlayback; {$ENDIF}
  {$IFDEF USEBASS} BASS_ChannelStop(fBassOtherStream); {$ENDIF}
  fToPlayAfterFade := '';
  if fFadeState = fsFadeOut then
    fFadedToPlayOther := True; //Make sure the music starts again if we are currently fading out
end;


function TKMMusicLib.GetTrackTitle: UnicodeString;
begin
  if not fIsInitialized then Exit;
  if not InRange(fIndex, Low(fTracks), High(fTracks)) then Exit;

  Result := TruncateExt(ExtractFileName(fTracks[fTrackOrder[fIndex]]));
end;


(*
//Doesn't work unless you change volume in Windows?
s:= ExeDir + 'Music\SpiritOrig.mid';
{PlayMidiFile(s);
{StartSound(Form1.Handle, s);}
MCISendString(PChar('play ' + s), nil, 0, 0);}
*)


(*
function PlayMidiFile(FileName: UnicodeString):word;
var
  wdeviceid: integer;
  mciOpen: tmci_open_parms;
  mciPlay: tmci_play_parms;
  mciStat: tmci_status_parms;
begin
  // Open the device by specifying the device and filename.
  // MCI will attempt to choose the MIDI mapper as the output port.
  mciopen.lpstrDeviceType := 'sequencer';
  mciopen.lpstrElementName := pchar (filename);
  Result := mciSendCommand ($0, mci_open , mci_open_type or mci_open_element, longint (@mciopen));
  if Result <> 0 then Exit;
  // The device opened successfully; get the device ID.
  // Check if the output port is the MIDI mapper.
  wDeviceID := mciOpen.wDeviceID;
  mciStat.dwItem := MCI_SEQ_STATUS_PORT;
  Result := mciSendCommand (wDeviceID, MCI_STATUS, MCI_STATUS_ITEM, longint (@mciStat));
  if Result <> 0 then
  begin
    mciSendCommand (wDeviceID, MCI_CLOSE, 0, 0);
    Exit;
  end;
  // Begin playback. The window procedure function for the parent
  // Window will be notified with an MM_MCINOTIFY message when
  // Playback is complete. At this time, the window procedure closes
  // The device.
  mciPlay.dwCallback := Form1.Handle;
  Result := mciSendCommand (wDeviceID, MCI_PLAY,
  MCI_NOTIFY, longint (@mciPlay));
  if Result <> 0 then
  begin
    mciSendCommand (wDeviceID, MCI_CLOSE, 0, 0);
    Exit;
  end;
end;
*)


end.
