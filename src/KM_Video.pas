unit KM_Video;
{$I KaM_Remake.inc}
interface
uses
  SysUtils, SyncObjs, Types, Messages, Classes, Dialogs, KromOGLUtils, Generics.Collections
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
    FCriticalSection: TCriticalSection;

    FBuffer: array of Byte;

    FWidth: LongWord;
    FHeight: LongWord;

    FScreenWidth: Integer;
    FScreenHeight: Integer;

    FTexture: TTexture;

    FIndex: Integer;
    FLenght: Int64;
    FTime: Int64;

    FCallback: TKMVideoPlayerCallback;

    FInstance: PVLCInstance;
    FMediaPlayer: PVLCMediaPlayer;

    FTrackList: TStringList;
    FVideoList: TList<TKMVideoFile>;

    function TryGetPathFile(const aPath: string; var aFileName: string): Boolean;
    procedure SetTrackByLocale;
    function GetState: TVLCPlayerState;

    procedure StopVideo;

    procedure AddVideoToList(aPath: string; aKind: TKMVideoFileKind = vfkNone);
{$ENDIF}
  public
    constructor Create(aPlayerEnabled: Boolean);
    destructor Destroy; override;

    property PlayerEnabled: Boolean read fPlayerEnabled;

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
  KM_Render, KM_RenderTypes, KM_RenderUI, dglOpenGL, KM_ResLocales, KM_GameApp, KM_GameSettings, KM_Music, KM_Sound;

const
  FADE_MUSIC_TIME   = 500; // Music fade time, in ms
  UNFADE_MUSIC_TIME = 2000; // Music unfade time, in ms

{$IFDEF VIDEOS}

function VLCLock(aOpaque: Pointer; var aPlanes: Pointer): Pointer; cdecl;
begin
  gVideoPlayer.FCriticalSection.Enter;
  if Length(gVideoPlayer.FBuffer) > 0 then
    aPlanes := @(gVideoPlayer.FBuffer[0]);
  Result := nil;
end;

function VLCUnlock(aOpaque: Pointer; aPicture: Pointer; aPlanes: Pointer): Pointer; cdecl;
begin
  gVideoPlayer.FCriticalSection.Leave;
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
  FIndex := 0;
  FTexture.U := 1;
  FTexture.V := 1;
  FCallback := nil;
  FCriticalSection := TCriticalSection.Create;
  FVideoList := TList<TKMVideoFile>.Create;
  FTrackList :=  TStringList.Create;

  VLCLoadLibrary;
{$ENDIF}
end;


destructor TKMVideoPlayer.Destroy;
begin
  if fPlayerEnabled then
  begin
    {$IFDEF VIDEOS}
    if Assigned(FMediaPlayer) then
      libvlc_media_player_stop(FMediaPlayer); //Stop VLC

    VLCUnloadLibrary;
    FVideoList.Free;
    FTrackList.Free;
    FCriticalSection.Free;
    {$ENDIF}
  end;

  inherited;
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
  FVideoList.Add(videoFileData);
end;
{$ENDIF}


procedure TKMVideoPlayer.AddCampaignVideo(const aCampaignPath, aVideoName: string);
{$IFDEF VIDEOS}
var
  Path: string;
{$ENDIF}
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;
{$IFDEF VIDEOS}
  if not gGameSettings.VideoOn then
    Exit;

  if TryGetPathFile(aCampaignPath + aVideoName, Path) or
    TryGetPathFile(VIDEOFILE_PATH + aVideoName, Path) then
    AddVideoToList(Path);
{$ENDIF}
end;

procedure TKMVideoPlayer.AddMissionVideo(const aMissionFile, aVideoName: string);
{$IFDEF VIDEOS}
var
  MissionPath, FileName: string;
  Path: string;
{$ENDIF}
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;
{$IFDEF VIDEOS}
  if not gGameSettings.VideoOn then
    Exit;
  MissionPath := ExtractFilePath(aMissionFile);
  FileName := ExtractFileName(ChangeFileExt(aMissionFile, '')) + '.' + aVideoName;

  if TryGetPathFile(MissionPath + FileName, Path) or
    TryGetPathFile(MissionPath + aVideoName, Path) or
    TryGetPathFile(VIDEOFILE_PATH + aVideoName, Path) then
    AddVideoToList(Path);
{$ENDIF}
end;

procedure TKMVideoPlayer.AddVideo(const aVideoName: String; aKind: TKMVideoFileKind = vfkNone);
{$IFDEF VIDEOS}
var
  Path: string;
{$ENDIF}
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;
{$IFDEF VIDEOS}
  if not gGameSettings.VideoOn then
    Exit;
  if TryGetPathFile(aVideoName, Path) or
    TryGetPathFile(VIDEOFILE_PATH + aVideoName, Path) then
    AddVideoToList(Path, aKind);
{$ENDIF}
end;

procedure TKMVideoPlayer.Pause;
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;
{$IFDEF VIDEOS}
  if FMediaPlayer <> nil then
    libvlc_media_player_pause(FMediaPlayer);
{$ENDIF}
end;

procedure TKMVideoPlayer.Resume;
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;
{$IFDEF VIDEOS}
  if FMediaPlayer <> nil then
    libvlc_media_player_play(FMediaPlayer);
{$ENDIF}
end;

procedure TKMVideoPlayer.SetCallback(aCallback: TKMVideoPlayerCallback);
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;
{$IFDEF VIDEOS}
  FCallback := aCallback;
{$ENDIF}
end;

procedure TKMVideoPlayer.Resize(aWidth, aHeight: Integer);
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;
{$IFDEF VIDEOS}
  FScreenWidth := aWidth;
  FScreenHeight := aHeight;
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
    vlcpsPlaying:
      begin
        FTime := libvlc_media_player_get_time(FMediaPlayer);
        FLenght := libvlc_media_player_get_length(FMediaPlayer);
      end;
    vlcpsEnded:
        Stop;
  end;
{$ENDIF}
end;

procedure TKMVideoPlayer.Paint;
{$IFDEF VIDEOS}
var
  AspectRatio: Single;
  Width, Height: Integer;
{$ENDIF}
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;
{$IFDEF VIDEOS}
  if IsPlay and (Length(FBuffer) > 0) and (FTexture.Tex > 0)  then
  begin
    glBindTexture(GL_TEXTURE_2D, FTexture.Tex);
    FCriticalSection.Enter;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, FWidth, FHeight, 0, GL_RGB, GL_UNSIGNED_BYTE, FBuffer);
    FCriticalSection.Leave;
    glBindTexture(GL_TEXTURE_2D, 0);

    if gGameSettings.VideoStretch then
    begin
      AspectRatio := FWidth / FHeight;
      if AspectRatio > FScreenWidth / FScreenHeight then
      begin
        Width := FScreenWidth;
        Height := Round(FScreenWidth / AspectRatio);
      end
      else
      begin
        Width := Round(FScreenHeight * AspectRatio);
        Height := FScreenHeight;
      end;
    end
    else
    begin
      Width := FWidth;
      Height := FHeight;
    end;

    TKMRenderUI.WriteTexture((FScreenWidth - Width) div 2, (FScreenHeight - Height) div 2, Width, Height, FTexture, $FFFFFFFF);
  end;
  {
  if IsActive and not IsPlay then
    TKMRenderUI.WriteText(10, 50, 1000, 'Wait', fntArial, taLeft);

  if IsPlay then
    TKMRenderUI.WriteText(100, 50, 1000, 'Play', fntArial, taLeft)
  else
    TKMRenderUI.WriteText(100, 50, 1000, 'Pause', fntArial, taLeft);

  TKMRenderUI.WriteText(200, 50, 1000, 'Index = ' + IntToStr(FIndex), fntArial, taLeft);
  TKMRenderUI.WriteText(350, 50, 1000, 'Size = ' + IntToStr(FWidth) + 'x' + IntToStr(FHeight), fntArial, taLeft);

  TKMRenderUI.WriteText(100, 100, 1000, IntToStr(FTime) + ' / ' + IntToStr(FLenght), fntArial, taLeft)

  for i := 0 to FVideoList.Count - 1 do
  begin
    if i < FIndex then
      TKMRenderUI.WriteText(100, 100 + i * 20 + 20, 1000, FVideoList[i] + ' - Ok', fntArial, taLeft)
    else if i = FIndex then
      TKMRenderUI.WriteText(100, 100 + i * 20 + 20, 1000, FVideoList[i] + ' - ' + IntToStr(FTime) + ' / ' + IntToStr(FLenght), fntArial, taLeft)
    else
      TKMRenderUI.WriteText(100, 100 + i * 20 + 20, 1000, FVideoList[i], fntArial, taLeft)
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

  //  Esc           Space         Enter
  if (Key = 27) or (Key = 32) or (Key = 13) then
    Stop;

  if Key = 80 then // P
  begin
    if IsPlay then
      Pause
    else
      Resume;
  end;

  if Key = 37 then
  begin
    FTime := FTime - 1000;
    if FTime <= 0 then
      FTime := 0;
    libvlc_media_player_set_time(FMediaPlayer, FTime);
  end;

  if Key = 39 then
  begin
    FTime := FTime + 1000;
    if FTime >= FLenght then
      FTime := FLenght;
    libvlc_media_player_set_time(FMediaPlayer, FTime);
  end;
{$ENDIF}
end;

function TKMVideoPlayer.IsActive: Boolean;
begin
  if Self = nil then Exit(False);
  if not fPlayerEnabled then Exit(False);
{$IFDEF VIDEOS}
  Result := Assigned(FMediaPlayer) or (FVideoList.Count > 0);
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
  Media: PVLCMedia;
  Tracks: TVLCMediaTrackList;
  TrackCount: LongWord;
  Track: PVLCMediaTrack;
{$ENDIF}
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;
{$IFDEF VIDEOS}
  if FIndex >= FVideoList.Count then Exit;

  if Assigned(gGameApp) then
  begin
    gSoundPlayer.AbortAllFadeSounds;
    gSoundPlayer.AbortAllScriptSounds;
    gSoundPlayer.AbortAllLongSounds;
    gMusic.StopPlayingOtherFile;

    // Fade music immediately for starting video
    if ( FVideoList[FIndex].Kind = vfkStarting ) then
      gMusic.Fade(0)
    else
      gMusic.Fade(FADE_MUSIC_TIME);
    // For unknown reason libzPlay lib will use higher volume when unfade (resume) music after video is stopped
    // We either can use BASS or set player volume to 0 here. Let's try the latter option for now
    gMusic.SetPlayerVolume(0);
  end;

  FTrackList.Clear;
  FWidth := 0;
  FHeight := 0;

  path := FVideoList[FIndex].Path;

  FInstance := libvlc_new(0, nil);
  Media := libvlc_media_new_path(FInstance, PAnsiChar(UTF8Encode((path))));
  try
    libvlc_media_parse(Media);
    TrackCount := libvlc_media_tracks_get(Media, Pointer(Tracks));

    if TrackCount > 0 then
    begin
      for I := 0 to TrackCount - 1 do
      begin
        Track := tracks[I];
        case Track.TrackType of
          vlcttVideo:
            begin
              FWidth := Track.Union.Video.Width;
              FHeight := Track.Union.Video.Height;
            end;
          vlcttAudio:
            begin
              if Track.Language <> nil then
                FTrackList.AddObject(UpperCase(string(Track.Language)), TObject(Track.Id));
            end;
        end;
      end;
    end;

    if(FWidth > 0) and (FHeight > 0) then
    begin
      SetLength(FBuffer, FWidth * FHeight * 3);
      FTexture.Tex := TRender.GenerateTextureCommon(ftLinear, ftLinear);

      FMediaPlayer := libvlc_media_player_new_from_media(Media);
      libvlc_video_set_format(FMediaPlayer, 'RV24', FWidth, FHeight, FWidth * 3);
      libvlc_video_set_callbacks(FMediaPlayer, @VLCLock, @VLCUnlock, nil, nil);
      //libvlc_media_player_set_hwnd(FMediaPlayer, Pointer(FPanel.Handle));
      libvlc_media_player_play(FMediaPlayer);
      SetTrackByLocale;
      libvlc_audio_set_volume(FMediaPlayer, Round(gGameSettings.VideoVolume * 100));
    end
    else
      Stop;

  finally
    libvlc_media_release(Media);
  end;
{$ENDIF}
end;

{$IFDEF VIDEOS}
procedure TKMVideoPlayer.StopVideo;
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;

  if Assigned(FMediaPlayer) then
  begin
    libvlc_media_player_stop(FMediaPlayer);
    while libvlc_media_player_is_playing(FMediaPlayer) = 1 do
      Sleep(100);

    libvlc_media_player_release(FMediaPlayer);
    FMediaPlayer := nil;
  end;

  if Assigned(FInstance) then
  begin
    libvlc_release(FInstance);
    FInstance := nil;
  end;

  if FTexture.Tex > 0 then
  begin
    TRender.DeleteTexture(FTexture.Tex);
    FTexture.Tex := 0;
  end;
  SetLength(FBuffer, 0);
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

  startingVideo := ( FVideoList[FIndex].Kind = vfkStarting );
  Inc(FIndex);
  if FIndex >= FVideoList.Count then
  begin
    FIndex := 0;
    FVideoList.Clear;
    if Assigned(gGameApp) then
    begin
      if startingVideo then
        gMusic.UnfadeStarting
      else
        gMusic.Unfade(UNFADE_MUSIC_TIME);
    end;

    if Assigned(FCallback) then
    begin
      FCallback;
      FCallback := nil;
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
function TKMVideoPlayer.TryGetPathFile(const aPath: string; var aFileName: string): Boolean;
var
  i: Integer;
  SearchRec: TSearchRec;
  FileName, Path, f: string;
  LocalePostfixes: TStringList;
begin
  if Self = nil then Exit(False);
  if not fPlayerEnabled then Exit(False);

  Result := False;
  aFileName := '';

  Path := ExtractFilePath(aPath);
  if not DirectoryExists(ExtractFilePath(ParamStr(0)) + Path) then
    Exit;

  LocalePostfixes := TStringList.Create;
  try
    LocalePostfixes.Add('.' + UnicodeString(gResLocales.UserLocale));
    LocalePostfixes.Add('.' + UnicodeString(gResLocales.FallbackLocale));
    LocalePostfixes.Add('.' + UnicodeString(gResLocales.DefaultLocale));
    LocalePostfixes.Add('');

    FileName := ExtractFileName(aPath);
    for i := 0 to LocalePostfixes.Count - 1 do
    begin
      try
        if FindFirst(Path + '*', faAnyFile, SearchRec) <> 0 then
          Continue;

        repeat
          if (SearchRec.Name = '.') or (SearchRec.Name = '..') then
            Continue;

          f := FileName + LocalePostfixes[i] + ExtractFileExt(SearchRec.Name);
          if CompareStr(SearchRec.Name, f) = 0 then
          begin
            aFileName := ExtractFilePath(ParamStr(0)) + Path + SearchRec.Name;
            Exit(True);
          end;

        until FindNext(SearchRec) <> 0;
      finally
        FindClose(SearchRec);
      end;
    end;
  finally
    LocalePostfixes.Free;
  end;
end;


procedure TKMVideoPlayer.SetTrackByLocale;
const
  TIME_STEP = 50;
var
  TrackId, TrackIndex: Integer;
begin
  if Self = nil then Exit;
  if not fPlayerEnabled then Exit;

  if FTrackList.Count = 0 then Exit;

  if not FTrackList.Find(UpperCase(string(gResLocales.UserLocale)), TrackIndex) and
    not FTrackList.Find(UpperCase(string(gResLocales.FallbackLocale)), TrackIndex) and
    not FTrackList.Find(UpperCase(string(gResLocales.DefaultLocale)), TrackIndex) then
    Exit;

  TrackId := Integer(FTrackList.Objects[TrackIndex]);

  while Assigned(FMediaPlayer) and (libvlc_audio_set_track(FMediaPlayer, TrackId) < 0) do
    Sleep(TIME_STEP);
end;

function TKMVideoPlayer.GetState: TVLCPlayerState;
begin
  Result := vlcpsNothingSpecial;
  if IsActive then
    Result := libvlc_media_player_get_state(FMediaPlayer);
end;

{$ENDIF}

end.
