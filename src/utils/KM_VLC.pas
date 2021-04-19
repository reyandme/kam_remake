unit KM_VLC;

{$I KaM_Remake.inc}

interface

{$IFDEF VIDEOS}

const
  VLC_PATH = 'lib\vlc';
  VOUT_MAX_PLANES = 5;

type
  TVLCPlayerState = (
    vlcpsNothingSpecial,
    vlcpsOpening,
    vlcpsBuffering,
    vlcpsPlaying,
    vlcpsPaused,
    vlcpsStopped,
    vlcpsEnded,
    vlcpsError
  );

  TVLCVideoOrient = (
    vlcvo_top_left,
    vlcvo_top_right,
    vlcvo_bottom_left,
    vlcvo_bottom_right,
    vlcvo_left_top,
    vlcvo_left_bottom,
    vlcvo_right_top,
    vlcvo_right_bottom
  );

  TVLCVideoProjection = (
    vlcvp_rectangular,
    vlcvp_equirectangular,
    vlcvp_cubemap_layout_standard = $100
  );

  TVLCTrackType = (
    vlcttUnknown = -1,
    vlcttAudio   = 0,
    vlcttVideo   = 1,
    vlcttText    = 2
  );

  PVLCInstance       = type Pointer;
  PVLCMediaPlayer    = type Pointer;
  PVLCMedia          = type Pointer;
  PVLCEventManager   = type Pointer;

  PVCBPlanes  = ^TVCBPlanes;
  TVCBPlanes  = packed array[0..VOUT_MAX_PLANES-1] of Pointer;

  TVLCVideoLock = function(aOpaque : Pointer; aPlanes: PVCBPlanes): Pointer; cdecl;
  TVLCVideoUnlock = procedure(aOpaque: Pointer; aPicture: Pointer; aPlanes: PVCBPlanes); cdecl;
  TVLCVideoDisplay = procedure(aOpaque: Pointer; aPicture : Pointer); cdecl;

  PVLCAudioTrack = ^TVLCAudioTrack;
  TVLCAudioTrack = record
    Channels : LongWord;
    Rate     : LongWord;
  end;

  TVLCVideoViewpoint = record
    Yaw         : Single;
    Pitch       : Single;
    Roll        : Single;
    FieldOfView : Single;
  end;

  PVLCVideoTrack = ^TVLCVideoTrack;
  TVLCVideoTrack = record
    Height       : LongWord;
    Width        : LongWord;
    SarNum       : LongWord;
    SarDen       : LongWord;
    FrameRateNum : LongWord;
    FrameRateDen : LongWord;
    Orientation  : TVLCVideoOrient;
    Projection   : TVLCVideoProjection;
    pose         : TVLCVideoViewpoint;
  end;

  PVLCSubtitleTrack = ^TVLCSubtitleTrack;
  TVLCSubtitleTrack = record
    Encoding : PAnsiChar;
  end;

  TVLCMediaTrackUnion = record
    case Byte of
      0: (Audio    : PVLCAudioTrack);
      1: (Video    : PVLCVideoTrack);
      2: (Subtitle : PVLCSubtitleTrack);
  end;

  PVLCMediaTrack = ^TVLCMediaTrack;
  TVLCMediaTrack = record
    Codec          : LongWord;
    OriginalFourcc : LongWord;
    Id             : Integer;
    TrackType      : TVLCTrackType;
    Profile        : Integer;
    Level          : Integer;
    Union          : TVLCMediaTrackUnion;
    Bitrate        : LongWord;
    Language       : PAnsiChar;
    Sescription    : PAnsiChar;
  end;

  TVLCMediaTrackList = array of PVLCMediaTrack;

var
  libvlc_new : function(aArgc: Integer; aArgv: PAnsiChar): PVLCInstance; cdecl;
  libvlc_release : procedure(aInstance: PVLCInstance); cdecl;

  libvlc_media_new_path : function(aInstance: PVLCInstance; aPath: PAnsiChar): PVLCMedia; cdecl;
  libvlc_media_new_location : function(aInstance: PVLCInstance; aMrl: PAnsiChar): PVLCMedia; cdecl;
  libvlc_media_release : procedure(aMedia: PVLCMedia); cdecl;
  libvlc_media_parse : procedure(aMedia: PVLCMedia); cdecl;
  libvlc_media_tracks_get : function(aMedia: PVLCMedia; var aTracks: Pointer): LongWord; cdecl;

  libvlc_media_player_new_from_media : function(aMedia: PVLCMedia): PVLCMediaPlayer; cdecl;
  libvlc_media_player_set_hwnd : procedure(aMediaPlayer: PVLCMediaPlayer; drawable: Pointer); cdecl;
  libvlc_media_player_play : procedure(aMediaPlayer: PVLCMediaPlayer); cdecl;
  libvlc_media_player_pause : procedure(aMediaPlayer : PVLCMediaPlayer); cdecl;
  libvlc_media_player_stop : procedure(aMediaPlayer: PVLCMediaPlayer); cdecl;
  libvlc_media_player_release : procedure(aMediaPlayer: PVLCMediaPlayer); cdecl;
  libvlc_media_player_is_playing : function(aMediaPlayer: PVLCMediaPlayer): Integer; cdecl;
  libvlc_media_player_get_state : function(aMediaPlayer: PVLCMediaPlayer): TVLCPlayerState; cdecl;
  libvlc_media_player_get_length : function(aMediaPlayer: PVLCMediaPlayer): Int64; cdecl;
  libvlc_media_player_get_time : function(aMediaPlayer: PVLCMediaPlayer) : Int64; cdecl;
  libvlc_media_player_set_time : procedure(aMediaPlayer: PVLCMediaPlayer; aTime: Int64); cdecl;

  libvlc_video_set_format : procedure(aMediaPlayer: PVLCMediaPlayer; aChroma: PAnsiChar; aWidth: Longword; aHeight: Longword; aPitch: Longword); cdecl;
  libvlc_video_set_callbacks : procedure(aMediaPlayer: PVLCMediaPlayer; aLock: TVLCVideoLock; aUnlock: TVLCVideoUnlock; aDisplay: TVLCVideoDisplay; aOpaque: Pointer); cdecl;

  libvlc_audio_set_volume : function(aMediaPlayer: PVLCMediaPlayer; aVolume: Integer): Integer; cdecl;
  libvlc_audio_set_track : function(aMediaPlayer: PVLCMediaPlayer; aTrackId: Integer): Integer; cdecl;

  procedure VLCLoadLibrary;
  procedure VLCUnloadLibrary;

{$ENDIF}

implementation

uses
  Windows, Classes, Dialogs;

{$IFDEF VIDEOS}

var
  libvlccore: Integer = 0;
  libvlc: Integer = 0;

function GetAProcAddress(handle: integer; var addr: Pointer; const procName: string; failedList: TStringList): integer;
begin
  addr := GetProcAddress(handle, PWideChar(procName));
  if not Assigned(addr) then
  begin
    if Assigned(failedList) then
      failedList.Add(procName);
    Result := -1;
  end
  else
    Result := 0
end;

function LoadVLCFunctions(vlcHandle: integer; failedList: TStringList): Boolean;
begin
  GetAProcAddress(vlcHandle, @libvlc_new, 'libvlc_new', failedList);
  GetAProcAddress(vlcHandle, @libvlc_release, 'libvlc_release', failedList);

  GetAProcAddress(vlcHandle, @libvlc_media_new_path, 'libvlc_media_new_path', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_new_location, 'libvlc_media_new_location', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_release, 'libvlc_media_release', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_parse, 'libvlc_media_parse', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_tracks_get, 'libvlc_media_tracks_get', failedList);

  GetAProcAddress(vlcHandle, @libvlc_media_player_new_from_media, 'libvlc_media_player_new_from_media', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_player_set_hwnd, 'libvlc_media_player_set_hwnd', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_player_play, 'libvlc_media_player_play', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_player_pause, 'libvlc_media_player_pause', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_player_stop, 'libvlc_media_player_stop', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_player_release, 'libvlc_media_player_release', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_player_is_playing, 'libvlc_media_player_is_playing', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_player_get_state, 'libvlc_media_player_get_state', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_player_get_length, 'libvlc_media_player_get_length', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_player_get_time, 'libvlc_media_player_get_time', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_player_set_time, 'libvlc_media_player_set_time', failedList);

  GetAProcAddress(vlcHandle, @libvlc_video_set_format, 'libvlc_video_set_format', failedList);
  GetAProcAddress(vlcHandle, @libvlc_video_set_callbacks, 'libvlc_video_set_callbacks', failedList);

  GetAProcAddress(vlcHandle, @libvlc_audio_set_volume, 'libvlc_audio_set_volume', failedList);
  GetAProcAddress(vlcHandle, @libvlc_audio_set_track, 'libvlc_audio_set_track', failedList);

  Result := failedList.Count = 0;
end;

procedure VLCLoadLibrary;
var
  List: TStringList;
begin
  if libvlccore = 0 then
  begin
    libvlccore := LoadLibrary(PWideChar(VLC_PATH + '\libvlccore.dll'));
    if libvlccore = 0 then begin
      Showmessage('Load "' + VLC_PATH + '\libvlccore.dll" library failed');
      Exit;
    end;
  end;

  if libvlc = 0 then
  begin
    libvlc := LoadLibrary(PWideChar(VLC_PATH + '\libvlc.dll'));
    if libvlc = 0 then begin
      Showmessage('Load "' + VLC_PATH + '\libvlc.dll" library failed');
      Exit;
    end;

    List := TStringList.Create;
    try
      if not LoadVLCFunctions(libvlc, List) then
      begin
        Showmessage('Some functions failed to load : ' + #13#10 + List.Text);
        FreeLibrary(libvlc);
      end;
    finally
      List.Free;
    end;
  end;
end;

procedure VLCUnloadLibrary;
begin
//  if libvlccore <> 0 then
//    FreeLibrary(libvlccore);
//  libvlccore := 0;

  if libvlc <> 0 then
    FreeLibrary(libvlc);
  libvlc := 0;
end;

{$ENDIF}

end.
