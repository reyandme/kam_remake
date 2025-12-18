unit KM_Video;
{$I KaM_Remake.inc}
interface
uses
  SysUtils, SyncObjs, Types, Classes,
  Messages, Generics.Collections,
  KromOGLUtils
  {$IFDEF WDC} , UITypes {$ENDIF}
  {$IFDEF FPC} , Controls {$ENDIF}
  {$IFDEF VIDEOS} , KM_VLC {$ENDIF}
  ;

type
  TKMVideoPlayerCallback = reference to procedure;

  TKMVideoFileKind = (
    vfkNone,
    vfkStarting //Game starting video
  );

  TKMVideoFile = record
    Path: string;
    Kind: TKMVideoFileKind;
  end;

  TKMVideoPlayer = class
  {$IFDEF VIDEOS}
  private const
    VIDEOFILE_PATH = 'data' + PathDelim + 'gfx' + PathDelim + 'video' + PathDelim;
  {$ENDIF}
  private
    fPlayerEnabled: Boolean;
  {$IFDEF VIDEOS}
    fCriticalSection: TCriticalSection;

    fBuffer: array of Byte;

    fWidth: LongWord;
    fHeight: LongWord;

    fScreenWidth: Integer;
    fScreenHeight: Integer;

    fTexture: TTexture;

    fIndex: Integer;
    fLength: Int64;
    fTime: Int64;

    fCallback: TKMVideoPlayerCallback;
    fBrightness: Integer;

    fInstance: PVLCInstance;
    fMediaPlayer: PVLCMediaPlayer;

    fTrackList: TStringList;
    fVideoList: TList<TKMVideoFile>;

    function TryGetPathFile(const aPathRelative: string; var aFileName: string): Boolean;
    procedure SetTrackByLocale;
    function GetState: TVLCPlayerState;

    procedure StopVideo;

    procedure AddVideoToList(aPath: string; aKind: TKMVideoFileKind = vfkNone);
{$ENDIF}
    function GetPlayerEnabled: Boolean;
  public
    constructor Create(aPlayerEnabled: Boolean);
    destructor Destroy; override;

    property PlayerEnabled: Boolean read GetPlayerEnabled;

    procedure AddCampaignVideo(const aCampaignPath, aVideoName: string);
    procedure AddMissionVideo(const aMissionFile, aVideoName: string);
    procedure AddVideo(const AVideoName: String; aKind: TKMVideoFileKind = vfkNone);

    procedure Play;
    procedure Stop;
    procedure Pause;
    procedure Resume;
    procedure SetCallback(aCallback: TKMVideoPlayerCallback);

    procedure Resize(aWidth, aHeight: Integer);
    procedure UpdateState;
    procedure Paint;

    procedure KeyDown(Key: Word; Shift: TShiftState);
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);

    function IsActive: Boolean;
    function IsPlay: Boolean;
  end;

var
  gVideoPlayer: TKMVideoPlayer;

implementation
uses
  System.Math,
  dglOpenGL,
  KM_Render, KM_RenderTypes, KM_RenderUI, KM_ResLocales,
  KM_GameApp, KM_GameSettings,
  KM_Music, KM_Sound,
  KM_Defaults;

const
  FADE_MUSIC_TIME   = 500; // Music fade time, in ms
  UNFADE_MUSIC_TIME = 2000; // Music unfade time, in ms


{$IFDEF VIDEOS}
function VLCLock(aOpaque: Pointer; var aPlanes: Pointer): Pointer; cdecl;
begin
  gVideoPlayer.fCriticalSection.Enter;
  if Length(gVideoPlayer.fBuffer) > 0 then
    aPlanes := @(gVideoPlayer.fBuffer[0]);
  Result := nil;
end;


function VLCUnlock(aOpaque: Pointer; aPicture: Pointer; aPlanes: Pointer): Pointer; cdecl;
begin
  gVideoPlayer.fCriticalSection.Leave;
  Result := nil;
end;
{$ENDIF}


{ TKMVideoPlayer }
constructor TKMVideoPlayer.Create(aPlayerEnabled: Boolean);
begin
  inherited Create;

  fPlayerEnabled := aPlayerEnabled;

  if not fPlayerEnabled then Exit;

{$IFDEF VIDEOS}
  fIndex := 0;
  fTexture.U := 1;
  fTexture.V := 1;
  fCallback := nil;
  fCriticalSection := TCriticalSection.Create;
  fVideoList := TList<TKMVideoFile>.Create;
  fTrackList :=  TStringList.Create;

  VLCLoadLibrary;
{$ENDIF}
end;


destructor TKMVideoPlayer.Destroy;
begin
  if fPlayerEnabled then
  begin
    {$IFDEF VIDEOS}
    if Assigned(fMediaPlayer) then
      libvlc_media_player_stop(fMediaPlayer); //Stop VLC

    VLCUnloadLibrary;
    fVideoList.Free;
    fTrackList.Free;
    fCriticalSection.Free;
    {$ENDIF}
  end;

  inherited;
end;


function TKMVideoPlayer.GetPlayerEnabled: Boolean;
begin
  if Self = nil then Exit(False);

  Result := fPlayerEnabled;
end;


{$IFDEF VIDEOS}
procedure TKMVideoPlayer.AddVideoToList(aPath: string; aKind: TKMVideoFileKind = vfkNone);
var
  videoFileData: TKMVideoFile;
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;

  videoFileData.Path := aPath;
  videoFileData.Kind := aKind;
  fVideoList.Add(videoFileData);
end;
{$ENDIF}


procedure TKMVideoPlayer.AddCampaignVideo(const aCampaignPath, aVideoName: string);
{$IFDEF VIDEOS}
var
  path: string;
{$ENDIF}
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;
{$IFDEF VIDEOS}
  if not gGameSettings.Video.Enabled then Exit;

  if TryGetPathFile(ExtractRelativePath(ExeDir, aCampaignPath) + aVideoName, path)
  or TryGetPathFile(VIDEOFILE_PATH + aVideoName, path) then
    AddVideoToList(path);
{$ENDIF}
end;


procedure TKMVideoPlayer.AddMissionVideo(const aMissionFile, aVideoName: string);
{$IFDEF VIDEOS}
var
  missionPath, fileName: string;
  path: string;
{$ENDIF}
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;
{$IFDEF VIDEOS}
  if not gGameSettings.Video.Enabled then Exit;

  missionPath := ExtractFilePath(aMissionFile);
  fileName := ExtractFileName(ChangeFileExt(aMissionFile, '')) + '.' + aVideoName;

  if TryGetPathFile(missionPath + fileName, path)
  or TryGetPathFile(missionPath + aVideoName, path)
  or TryGetPathFile(VIDEOFILE_PATH + aVideoName, path) then
    AddVideoToList(path);
{$ENDIF}
end;


procedure TKMVideoPlayer.AddVideo(const aVideoName: String; aKind: TKMVideoFileKind = vfkNone);
{$IFDEF VIDEOS}
var
  path: string;
{$ENDIF}
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;
{$IFDEF VIDEOS}
  if not gGameSettings.Video.Enabled then Exit;

  if TryGetPathFile(aVideoName, path)
  or TryGetPathFile(VIDEOFILE_PATH + aVideoName, path) then
    AddVideoToList(path, aKind);
{$ENDIF}
end;


procedure TKMVideoPlayer.Pause;
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;
{$IFDEF VIDEOS}
  if fMediaPlayer <> nil then
    libvlc_media_player_pause(fMediaPlayer);
{$ENDIF}
end;


procedure TKMVideoPlayer.Resume;
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;
{$IFDEF VIDEOS}
  if fMediaPlayer <> nil then
    libvlc_media_player_play(fMediaPlayer);
{$ENDIF}
end;


procedure TKMVideoPlayer.SetCallback(aCallback: TKMVideoPlayerCallback);
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;
{$IFDEF VIDEOS}
  fCallback := aCallback;
{$ENDIF}
end;


procedure TKMVideoPlayer.Resize(aWidth, aHeight: Integer);
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;
{$IFDEF VIDEOS}
  fScreenWidth := aWidth;
  fScreenHeight := aHeight;
{$ENDIF}
end;


procedure TKMVideoPlayer.UpdateState;
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;
{$IFDEF VIDEOS}
  if not IsActive then
    Exit;

  case GetState of
    vlcpsPlaying: begin
                    fTime := libvlc_media_player_get_time(fMediaPlayer);
                    fLength := libvlc_media_player_get_length(fMediaPlayer);
                  end;
    vlcpsEnded:   Stop;
  end;
{$ENDIF}
end;


procedure TKMVideoPlayer.Paint;
{$IFDEF VIDEOS}

  procedure FitToScreen(out aWidth, aHeight: Integer);
  var
    aspectRatio: Single;
  begin
    aspectRatio := fWidth / fHeight;
    if aspectRatio > fScreenWidth / fScreenHeight then
    begin
      aWidth := fScreenWidth;
      aHeight := Round(fScreenWidth / aspectRatio);
    end
    else
    begin
      aWidth := Round(fScreenHeight * aspectRatio);
      aHeight := fScreenHeight;
    end;
  end;

var
  width, height: Integer;
{$ENDIF}
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;
{$IFDEF VIDEOS}
  if IsPlay and (Length(fBuffer) > 0) and (fTexture.Tex > 0)  then
  begin
    glBindTexture(GL_TEXTURE_2D, fTexture.Tex);
    fCriticalSection.Enter;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, fWidth, fHeight, 0, GL_RGB, GL_UNSIGNED_BYTE, fBuffer);
    fCriticalSection.Leave;
    glBindTexture(GL_TEXTURE_2D, 0);

    if gGameSettings.Video.VideoStretch then
      FitToScreen(width, height)
    else
    begin
      if (fWidth < fScreenWidth) and (fHeight < fScreenHeight) then
      begin
        width := fWidth;
        height := fHeight;
      end
      else
        FitToScreen(width, height);
    end;

    TKMRenderUI.WriteTexture((fScreenWidth - width) div 2, (fScreenHeight - height) div 2, width, height, fTexture, $FFFFFFFF);
  end;
  {
  if IsActive and not IsPlay then
    TKMRenderUI.WriteText(10, 50, 1000, 'Wait', fntArial, taLeft);

  if IsPlay then
    TKMRenderUI.WriteText(100, 50, 1000, 'Play', fntArial, taLeft)
  else
    TKMRenderUI.WriteText(100, 50, 1000, 'Pause', fntArial, taLeft);

  TKMRenderUI.WriteText(200, 50, 1000, 'Index = ' + IntToStr(fIndex), fntArial, taLeft);
  TKMRenderUI.WriteText(350, 50, 1000, 'Size = ' + IntToStr(fWidth) + 'x' + IntToStr(fHeight), fntArial, taLeft);

  TKMRenderUI.WriteText(100, 100, 1000, IntToStr(fTime) + ' / ' + IntToStr(fLength), fntArial, taLeft)

  for i := 0 to fVideoList.Count - 1 do
  begin
    if i < fIndex then
      TKMRenderUI.WriteText(100, 100 + i * 20 + 20, 1000, fVideoList[i] + ' - Ok', fntArial, taLeft)
    else if i = fIndex then
      TKMRenderUI.WriteText(100, 100 + i * 20 + 20, 1000, fVideoList[i] + ' - ' + IntToStr(fTime) + ' / ' + IntToStr(fLength), fntArial, taLeft)
    else
      TKMRenderUI.WriteText(100, 100 + i * 20 + 20, 1000, fVideoList[i], fntArial, taLeft)
  end;
  }
{$ENDIF}
end;


procedure TKMVideoPlayer.KeyDown(Key: Word; Shift: TShiftState);
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;
{$IFDEF VIDEOS}
  if not IsActive then
    Exit;

  if Key in [vkEscape, vkSpace, vkReturn] then
    Stop;

  // Pause or Resume
  if Key = vkP then
  begin
    if IsPlay then
      Pause
    else
      Resume;
  end;

  // Back by 1 second
  if Key = vkLeft then
  begin
    fTime := Max(fTime - 1000, 0);
    libvlc_media_player_set_time(fMediaPlayer, fTime);
  end;

  // Forward by 1 second
  if Key = vkRight then
  begin
    fTime := Min(fTime + 1000, fLength);
    libvlc_media_player_set_time(fMediaPlayer, fTime);
  end;
{$ENDIF}
end;


function TKMVideoPlayer.IsActive: Boolean;
begin
  if Self = nil then Exit(False);
  if not fPlayerEnabled then Exit(False);
{$IFDEF VIDEOS}
  Result := Assigned(fMediaPlayer) or (fVideoList.Count > 0);
{$else}
  Result := False;
{$ENDIF}
end;


function TKMVideoPlayer.IsPlay: Boolean;
begin
  if Self = nil then Exit(False);
  if not fPlayerEnabled then Exit(False);
{$IFDEF VIDEOS}
  Result := GetState in [vlcpsPlaying, vlcpsPaused, vlcpsBuffering];
{$else}
  Result := False;
{$ENDIF}
end;


procedure TKMVideoPlayer.Play;
{$IFDEF VIDEOS}
var
  I: Integer;
  path: string;
  media: PVLCMedia;
  tracks: TVLCMediaTrackList;
  trackCount: LongWord;
  track: PVLCMediaTrack;
{$ENDIF}
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;
{$IFDEF VIDEOS}
  if fIndex >= fVideoList.Count then Exit;

  if Assigned(gGameApp) then
  begin
    gSoundPlayer.AbortAllFadeSounds;
    gSoundPlayer.AbortAllScriptSounds;
    gSoundPlayer.AbortAllLongSounds;
    gMusic.StopPlayingOtherFile;

    // Fade music immediately for starting video
    if ( fVideoList[fIndex].Kind = vfkStarting ) then
      gMusic.Fade(0)
    else
      gMusic.Fade(FADE_MUSIC_TIME);
    // For unknown reason libzPlay lib will use higher volume when unfade (resume) music after video is stopped
    // We either can use BASS or set player volume to 0 here. Let's try the latter option for now
    gMusic.SetPlayerVolume(0);
  end;

  fTrackList.Clear;
  fWidth := 0;
  fHeight := 0;

  fBrightness := gGameSettings.GFX.Brightness;

  // Minimum brightness for video is 1, otherwise we would see white screen
  //todo -cComplicated: Check if render parameters are set correctly, because we probably help to draw it with our Brightness 1,
  // while it should be fine with Brightness 0 regardless
  if fBrightness = 0 then
    gGameSettings.GFX.Brightness := 1;

  path := fVideoList[fIndex].Path;

  fInstance := libvlc_new(0, nil);
  media := libvlc_media_new_path(fInstance, PAnsiChar(UTF8Encode((path))));
  try
    libvlc_media_parse(media);
    trackCount := libvlc_media_tracks_get(media, Pointer(tracks));

    if trackCount > 0 then
    begin
      for I := 0 to trackCount - 1 do
      begin
        track := tracks[I];
        case track.TrackType of
          vlcttVideo:
            begin
              fWidth := track.Union.Video.Width;
              fHeight := track.Union.Video.Height;
            end;
          vlcttAudio:
            begin
              if track.Language <> nil then
                fTrackList.AddObject(UpperCase(string(track.Language)), TObject(track.Id));
            end;
        end;
      end;
    end;

    if(fWidth > 0) and (fHeight > 0) then
    begin
      SetLength(fBuffer, fWidth * fHeight * 3);
      fTexture.Tex := TKMRender.GenerateTextureCommon(ftLinear, ftLinear);

      fMediaPlayer := libvlc_media_player_new_from_media(media);
      libvlc_video_set_format(fMediaPlayer, 'RV24', fWidth, fHeight, fWidth * 3);
      libvlc_video_set_callbacks(fMediaPlayer, @VLCLock, @VLCUnlock, nil, nil);
      //libvlc_media_player_set_hwnd(fMediaPlayer, Pointer(FPanel.Handle));
      libvlc_media_player_play(fMediaPlayer);
      SetTrackByLocale;
      libvlc_audio_set_volume(fMediaPlayer, Round(gGameSettings.Video.VideoVolume * 100));
    end
    else
      Stop;

  finally
    libvlc_media_release(media);
  end;
{$ENDIF}
end;


{$IFDEF VIDEOS}
procedure TKMVideoPlayer.StopVideo;
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;

  if Assigned(fMediaPlayer) then
  begin
    libvlc_media_player_stop(fMediaPlayer);
    while libvlc_media_player_is_playing(fMediaPlayer) = 1 do
      Sleep(100);

    libvlc_media_player_release(fMediaPlayer);
    fMediaPlayer := nil;
  end;

  if Assigned(fInstance) then
  begin
    libvlc_release(fInstance);
    fInstance := nil;
  end;

  if fTexture.Tex > 0 then
  begin
    TKMRender.DeleteTexture(fTexture.Tex);
    fTexture.Tex := 0;
  end;
  SetLength(fBuffer, 0);
end;
{$ENDIF}


procedure TKMVideoPlayer.Stop;
{$IFDEF VIDEOS}
var
  startingVideo: Boolean;
{$ENDIF}
begin
{$IFDEF VIDEOS}
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;

  StopVideo;

  startingVideo := ( fVideoList[fIndex].Kind = vfkStarting );
  Inc(fIndex);
  if fIndex >= fVideoList.Count then
  begin
    fIndex := 0;
    fVideoList.Clear;
    if Assigned(gGameApp) then
    begin
      if startingVideo then
        gMusic.UnfadeStarting
      else
        gMusic.Unfade(UNFADE_MUSIC_TIME);
    end;

    // Restore brightness
    gGameSettings.GFX.Brightness := fBrightness;

    if Assigned(fCallback) then
    begin
      fCallback;
      fCallback := nil;
    end;
  end
  else
    Play;
{$ENDIF}
end;


procedure TKMVideoPlayer.MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;
{$IFDEF VIDEOS}
  if not IsPlay then
    Exit;

  Stop;
{$ENDIF}
end;


{$IFDEF VIDEOS}
function TKMVideoPlayer.TryGetPathFile(const aPathRelative: string; var aFileName: string): Boolean;
var
  I: Integer;
  searchRec: TSearchRec;
  fileName, path, f: string;
  localePostfixes: TStringList;
begin
  if Self = nil then Exit(False);
  if not fPlayerEnabled then Exit(False);
  Assert(gResLocales <> nil, 'gResLocales should be already loaded!');

  Result := False;
  aFileName := '';

  path := ExtractFilePath(aPathRelative);
  if not DirectoryExists(ExeDir + path) then
    Exit;

  localePostfixes := TStringList.Create;
  try
    localePostfixes.Add('.' + UnicodeString(gResLocales.UserLocale));
    localePostfixes.Add('.' + UnicodeString(gResLocales.FallbackLocale));
    localePostfixes.Add('.' + UnicodeString(gResLocales.DefaultLocale));
    localePostfixes.Add('');

    fileName := ExtractFileName(aPathRelative);
    for I := 0 to localePostfixes.Count - 1 do
    begin
      try
        if FindFirst(path + '*', faAnyFile, searchRec) <> 0 then
          Continue;

        repeat
          if (searchRec.Name = '.') or (searchRec.Name = '..') then
            Continue;

          f := fileName + localePostfixes[I] + ExtractFileExt(searchRec.Name);
          if CompareStr(searchRec.Name, f) = 0 then
          begin
            aFileName := ExtractFilePath(ParamStr(0)) + path + searchRec.Name;
            Exit(True);
          end;

        until FindNext(searchRec) <> 0;
      finally
        FindClose(searchRec);
      end;
    end;
  finally
    localePostfixes.Free;
  end;
end;


procedure TKMVideoPlayer.SetTrackByLocale;
const
  TIME_STEP = 50;
var
  trackId, trackIndex: Integer;
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;

  if fTrackList.Count = 0 then Exit;

  if not fTrackList.Find(UpperCase(string(gResLocales.UserLocale)), trackIndex) and
    not fTrackList.Find(UpperCase(string(gResLocales.FallbackLocale)), trackIndex) and
    not fTrackList.Find(UpperCase(string(gResLocales.DefaultLocale)), trackIndex) then
    Exit;

  trackId := Integer(fTrackList.Objects[trackIndex]);

  while Assigned(fMediaPlayer) and (libvlc_audio_set_track(fMediaPlayer, trackId) < 0) do
    Sleep(TIME_STEP);
end;


function TKMVideoPlayer.GetState: TVLCPlayerState;
begin
  Result := vlcpsNothingSpecial;
  if IsActive then
    Result := libvlc_media_player_get_state(fMediaPlayer);
end;
{$ENDIF}


end.

