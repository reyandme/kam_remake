unit KM_Audio;
{$I KaM_Remake.inc}
interface

type
  // Audio manager, dispatches audio between sound and music units
  TKMAudio = class
    class procedure PauseMusicToPlayFile(const aFileName: UnicodeString);
  end;


implementation
uses
  SysUtils,
  KM_Sound, KM_Music, KM_GameSettings;


class procedure TKMAudio.PauseMusicToPlayFile(const aFileName: UnicodeString);
begin
  if not FileExists(aFileName) then Exit;

  gSoundPlayer.AbortAllFadeSounds; //Victory/defeat sounds also fade music, so stop those in the rare chance they might still be playing
  gMusic.PauseToPlayFile(aFileName, gGameSettings.SoundFXVolume);
end;


end.
