unit KM_ResSound;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, TypInfo,
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  KromUtils, KM_Defaults;

type
  TAttackNotification = (anCitizens, anTown, anTroops);

  TSoundFX = (
    sfxNone=0,
    sfxCornCut,
    sfxDig,
    sfxPave,
    sfxMineStone,
    sfxCornSow,
    sfxChopTree,
    sfxhousebuild,
    sfxplacemarker,
    sfxClick,
    sfxmill,
    sfxsaw,
    sfxwineStep,
    sfxwineDrain,
    sfxmetallurgists,
    sfxcoalDown,
    sfxPig1,sfxPig2,sfxPig3,sfxPig4,
    sfxMine,
    sfxunknown21, //Pig?
    sfxLeather,
    sfxBakerSlap,
    sfxCoalMineThud,
    sfxButcherCut,
    sfxSausageString,
    sfxQuarryClink,
    sfxTreeDown,
    sfxWoodcutterDig,
    sfxCantPlace,
    sfxMessageOpen,
    sfxMessageClose,
    sfxMessageNotice,
    //Usage of melee sounds can be found in Docs\Melee sounds in KaM.csv
    sfxMelee34, sfxMelee35, sfxMelee36, sfxMelee37, sfxMelee38,
    sfxMelee39, sfxMelee40, sfxMelee41, sfxMelee42, sfxMelee43,
    sfxMelee44, sfxMelee45, sfxMelee46, sfxMelee47, sfxMelee48,
    sfxMelee49, sfxMelee50, sfxMelee51, sfxMelee52, sfxMelee53,
    sfxMelee54, sfxMelee55, sfxMelee56, sfxMelee57,
    sfxBowDraw,
    sfxArrowHit,
    sfxCrossbowShoot,  //60
    sfxCrossbowDraw,
    sfxBowShoot,       //62
    sfxBlacksmithBang,
    sfxBlacksmithFire,
    sfxCarpenterHammer, //65
    sfxHorse1,sfxHorse2,sfxHorse3,sfxHorse4,
    sfxRockThrow,
    sfxHouseDestroy,
    sfxSchoolDing,
    //Below are TPR sounds ...
    sfxSlingerShoot,
    sfxBalistaShoot,
    sfxCatapultShoot,
    sfxunknown76,
    sfxCatapultReload,
    sfxSiegeBuildingSmash);

  TSoundFXNew = (
    sfxnButtonClick,
    sfxnTrade,
    sfxnMPChatMessage,
    sfxnMPChatTeam,
    sfxnMPChatSystem,
    sfxnMPChatOpen,
    sfxnMPChatClose,
    sfxnVictory,
    sfxnDefeat,
    sfxnBeacon,
    sfxnError,
    sfxnPeacetime);

  //Sounds to play on different warrior orders
  TWarriorSpeech = (
    spSelect, spEat, spRotLeft, spRotRight, spSplit,
    spJoin, spHalt, spMove, spAttack, spFormation,
    spDeath, spBattleCry, spStormAttack);

  TWAVHeaderEx = record
    RIFFHeader: array [1..4] of AnsiChar;
    FileSize: Integer;
    WAVEHeader: array [1..4] of AnsiChar;
    FormatHeader: array [1..4] of AnsiChar;
    FormatHeaderSize: Integer;
    FormatCode: Word;
    ChannelNumber: Word;
    SampleRate: Integer;
    BytesPerSecond: Integer;
    BytesPerSample: Word;
    BitsPerSample: Word;
    DATAHeader: array [1..4] of AnsiChar; //Extension
    DataSize: Integer; //Extension
  end;

  TKMSoundData = record
    Head: TWAVHeaderEx;
    Data: array of byte;
    Foot: array of byte;
    IsLoaded: boolean;
  end;

  TKMSoundType = (stGame, stMenu);

  TKMResSounds = class
  private
    fLocaleString: AnsiString; //Locale used to access warrior sounds

    fWarriorUseBackup: array[WARRIOR_MIN..WARRIOR_MAX] of boolean;

    procedure LoadSoundsDAT;
    procedure ScanWarriorSounds;
    function LoadWarriorSoundsFromFile(const aFile: string): Boolean;
    procedure SaveWarriorSoundsToFile(const aFile: string);
  public
    fWavesCount: integer;
    fWaves: array of TKMSoundData;

    NotificationSoundCount: array[TAttackNotification] of byte;
    WarriorSoundCount: array[WARRIOR_MIN..WARRIOR_MAX, TWarriorSpeech] of byte;

    constructor Create(const aLocale, aFallback, aDefault: AnsiString);

    function FileOfCitizen(aUnitType: TKMUnitType; aSound: TWarriorSpeech): UnicodeString;
    function FileOfNewSFX(aSFX: TSoundFXNew): UnicodeString;
    function FileOfNotification(aSound: TAttackNotification; aNumber: Byte): UnicodeString;
    function FileOfWarrior(aUnitType: TKMUnitType; aSound: TWarriorSpeech; aNumber: Byte): UnicodeString;

    function GetSoundType(aNewSFX: TSoundFXNew): TKMSoundType; overload;
    function GetSoundType(aSFX: TSoundFX): TKMSoundType; overload;
    function GetSoundType(aSFX: TWarriorSpeech): TKMSoundType; overload;
    function GetSoundType(aSFX: TAttackNotification): TKMSoundType; overload;

    procedure ExportSounds;
  end;


implementation
uses
  KM_CommonClasses;


const
  WARRIOR_SFX_FOLDER: array[WARRIOR_MIN..WARRIOR_MAX] of string = (
    'militia', 'axeman', 'swordman', 'bowman', 'crossbowman',
    'lanceman', 'pikeman', 'cavalry', 'knights', 'barbarian',
    'rebel', 'rogue', 'warrior', 'vagabond');

  //TPR warriors reuse TSK voices in some languages, so if the specific ones don't exist use these
  WARRIOR_SFX_FOLDER_BACKUP: array[WARRIOR_MIN..WARRIOR_MAX] of string = (
    '', '', '', '', '',
    '', '', '', '', '',
    'bowman', 'lanceman', 'barbarian', 'cavalry');

  WARRIOR_SFX: array[TWarriorSpeech] of string = (
    'select', 'eat', 'left', 'right', 'halve',
    'join', 'halt', 'send', 'attack', 'format',
    'death', 'battle', 'storm');

  ATTACK_NOTIFICATION: array[TAttackNotification] of string = ('citiz', 'town', 'units');

  CITIZEN_SFX: array[CITIZEN_MIN..CITIZEN_MAX] of record
    WarriorVoice: TKMUnitType;
    SelectID, DeathID: byte;
  end = (
    (WarriorVoice: utMilitia;       SelectID:3; DeathID:1), //utSerf
    (WarriorVoice: utAxeFighter;    SelectID:0; DeathID:0), //utWoodcutter
    (WarriorVoice: utBowman;        SelectID:2; DeathID:1), //utMiner
    (WarriorVoice: utSwordFighter;  SelectID:0; DeathID:2), //utAnimalBreeder
    (WarriorVoice: utMilitia;       SelectID:1; DeathID:2), //utFarmer
    (WarriorVoice: utCrossbowman;   SelectID:1; DeathID:0), //utLamberjack
    (WarriorVoice: utLanceCarrier;  SelectID:1; DeathID:0), //utBaker
    (WarriorVoice: utScout;         SelectID:0; DeathID:2), //utButcher
    (WarriorVoice: utVagabond;      SelectID:2; DeathID:0), //utFisher
    (WarriorVoice: utKnight;        SelectID:1; DeathID:1), //utWorker
    (WarriorVoice: utPikeman;       SelectID:1; DeathID:1), //utStoneCutter
    (WarriorVoice: utKnight;        SelectID:3; DeathID:4), //utSmith
    (WarriorVoice: utPikeman;       SelectID:3; DeathID:2), //utMetallurgist
    (WarriorVoice: utBowman;        SelectID:3; DeathID:0)  //utRecruit
  );

  NEW_SFX_FOLDER = 'Sounds' + PathDelim;
  NEW_SFX_FILE: array [TSoundFXNew] of string = (
    'UI' + PathDelim + 'ButtonClick.wav',
    'Buildings' + PathDelim + 'MarketPlace' + PathDelim + 'Trade.wav',
    'Chat' + PathDelim + 'ChatArrive.wav',
    'Chat' + PathDelim +'ChatTeam.wav',
    'Chat' + PathDelim + 'ChatSystem.wav',
    'Chat' + PathDelim + 'ChatOpen.wav',
    'Chat' + PathDelim + 'ChatClose.wav',
    'Misc' + PathDelim + 'Victory.wav',
    'Misc' + PathDelim + 'Defeat.wav',
    'UI'   + PathDelim + 'Beacon.wav',
    'UI'   + PathDelim + 'Error.wav',
    'Misc' + PathDelim + 'PeaceTime.wav');


{ TKMResSounds }
constructor TKMResSounds.Create(const aLocale, aFallback, aDefault: AnsiString);
begin
  inherited Create;

  if SKIP_SOUND then Exit;

  if DirectoryExists(ExeDir + 'data' + PathDelim + 'sfx' + PathDelim + 'speech.' + UnicodeString(aLocale) + PathDelim) then
    fLocaleString := aLocale
  else
    // Note that starting from some Windows version, paths `\data\sfx\speech\` and `\data\sfx\speech.\` are treated identical by OS
    if (aFallback <> '') and DirectoryExists(ExeDir + 'data' + PathDelim + 'sfx' + PathDelim + 'speech.' + UnicodeString(aFallback) + PathDelim) then
      fLocaleString := aFallback // Use fallback voices when primary doesn't exist
    else
      fLocaleString := aDefault; //Use English voices when no language specific voices exist

  LoadSoundsDAT;
  ScanWarriorSounds;
end;


procedure TKMResSounds.LoadSoundsDAT;
var
  S: TMemoryStream;
  Head: record Size, Count: Word; end;
  Tab1: array[1..200] of Integer;
  Tab2: array[1..200] of SmallInt;
  I, Tmp: Integer;
begin
  if not FileExists(ExeDir + 'data' + PathDelim + 'sfx' + PathDelim + 'sounds.dat') then Exit;

  S := TMemoryStream.Create;
  S.LoadFromFile(ExeDir + 'data' + PathDelim + 'sfx' + PathDelim + 'sounds.dat');
  S.Read(Head, 4);
  S.Read(Tab1, Head.Count*4); //Read Count*4bytes into Tab1(WaveSizes)
  S.Read(Tab2, Head.Count*2); //Read Count*2bytes into Tab2(No idea what is it)

  fWavesCount := Head.Count;
  SetLength(fWaves, fWavesCount+1);

  for I := 1 to Head.Count do
  begin
    S.Read(Tmp, 4); //Always '1' for existing waves
    if Tab1[I] <> 0 then begin
      S.Read(fWaves[I].Head, SizeOf(fWaves[I].Head));
      SetLength(fWaves[I].Data, fWaves[I].Head.DataSize);
      S.Read(fWaves[I].Data[0], fWaves[I].Head.DataSize);
      SetLength(fWaves[I].Foot, Tab1[I]-SizeOf(fWaves[I].Head)-fWaves[I].Head.DataSize);
      S.Read(fWaves[I].Foot[0], Tab1[I]-SizeOf(fWaves[I].Head)-fWaves[I].Head.DataSize);
    end;
    fWaves[I].IsLoaded := True;
  end;

  {BlockRead(f,c,20);
  //Packed record
  //SampleRate,Volume,a,b:integer;
  //i,j,k,l,Index:word;
  BlockRead(f,Props[1],26*Head.Count);}

  S.Free;
end;


procedure TKMResSounds.ExportSounds;
var
  I: Integer;
  S: TMemoryStream;
begin
  ForceDirectories(ExeDir + 'Export'+PathDelim+'SoundsDat'+PathDelim);

  for I := 1 to fWavesCount do
  if Length(fWaves[I].Data) > 0 then
  begin
    S := TMemoryStream.Create;
    S.Write(fWaves[I].Head, SizeOf(fWaves[I].Head));
    S.Write(fWaves[I].Data[0], Length(fWaves[I].Data));
    S.Write(fWaves[I].Foot[0], Length(fWaves[I].Foot));
    S.SaveToFile(ExeDir + 'Export'+PathDelim+'SoundsDat'+PathDelim+'sound_' + int2fix(I, 3) + '_' +
                 GetEnumName(TypeInfo(TSoundFX), I) + '.wav');
    S.Free;
  end;
end;


function TKMResSounds.FileOfCitizen(aUnitType: TKMUnitType; aSound: TWarriorSpeech): UnicodeString;
var
  soundID: Byte;
begin
  if not (aUnitType in [CITIZEN_MIN..CITIZEN_MAX]) then Exit;

  if aSound = spDeath then
    soundID := CITIZEN_SFX[aUnitType].DeathID
  else
    soundID := CITIZEN_SFX[aUnitType].SelectID;

  Result := FileOfWarrior(CITIZEN_SFX[aUnitType].WarriorVoice, aSound, soundID);
end;


function TKMResSounds.FileOfWarrior(aUnitType: TKMUnitType; aSound: TWarriorSpeech; aNumber: Byte): UnicodeString;
var
  S: UnicodeString;
begin
  S := ExeDir + 'data' + PathDelim + 'sfx' + PathDelim + 'speech.' + UnicodeString(fLocaleString) + PathDelim;
  if fWarriorUseBackup[aUnitType] then
    S := S + WARRIOR_SFX_FOLDER_BACKUP[aUnitType]
  else
    S := S + WARRIOR_SFX_FOLDER[aUnitType];
  S := S + PathDelim + WARRIOR_SFX[aSound] + IntToStr(aNumber);
  //All our files are WAV now. Don't accept SND files because TPR uses SND in a different
  //format which can cause OpenAL to crash if someone installs KMR over TPR folder (e.g. Steam)
  Result := S+'.wav';
end;


function TKMResSounds.FileOfNewSFX(aSFX: TSoundFXNew): UnicodeString;
begin
  Result := ExeDir + NEW_SFX_FOLDER + NEW_SFX_FILE[aSFX];
end;


function TKMResSounds.FileOfNotification(aSound: TAttackNotification; aNumber: Byte): UnicodeString;
var
  S: UnicodeString;
begin
  S := ExeDir + 'data'+PathDelim+'sfx'+PathDelim+'speech.'+UnicodeString(fLocaleString)+ PathDelim + ATTACK_NOTIFICATION[aSound] + int2fix(aNumber,2);
  Result := S+'.wav';
end;


function TKMResSounds.GetSoundType(aSFX: TSoundFX): TKMSoundType;
begin
  Result := stGame; //All TSoundFX sounds considered as game sounds
end;


function TKMResSounds.GetSoundType(aNewSFX: TSoundFXNew): TKMSoundType;
begin
  if aNewSFX in [sfxnButtonClick,
    sfxnMPChatMessage,
    sfxnMPChatTeam,
    sfxnMPChatSystem,
    sfxnMPChatOpen,
    sfxnMPChatClose,
//    sfxnVictory,
//    sfxnDefeat,
    sfxnError] then
    Result := stMenu
  else
    Result := stGame;
end;


function TKMResSounds.GetSoundType(aSFX: TWarriorSpeech): TKMSoundType;
begin
  Result := stGame; //All TSoundFX sounds considered as game sounds
end;


function TKMResSounds.GetSoundType(aSFX: TAttackNotification): TKMSoundType;
begin
  Result := stGame; //All TSoundFX sounds considered as game sounds
end;


//Scan and count the number of warrior sounds
procedure TKMResSounds.ScanWarriorSounds;
var
  I: Integer;
  U: TKMUnitType;
  WS: TWarriorSpeech;
  AN: TAttackNotification;
  speechPath: string;
begin
  speechPath := ExeDir + 'data' + PathDelim + 'sfx' + PathDelim + 'speech.' + UnicodeString(fLocaleString) + PathDelim;

  //Reset counts from previous locale/unsuccessful load
  FillChar(WarriorSoundCount, SizeOf(WarriorSoundCount), #0);
  FillChar(NotificationSoundCount, SizeOf(NotificationSoundCount), #0);
  FillChar(fWarriorUseBackup, SizeOf(fWarriorUseBackup), #0);

  if not DirectoryExists(speechPath) then Exit;

  //Try to load counts from DAT,
  //otherwise we will rescan all the WAV files and write a new DAT
  if LoadWarriorSoundsFromFile(speechPath + 'count.dat') then
    Exit;

  //First inspect folders, if the prefered ones don't exist use the backups
  for U := WARRIOR_MIN to WARRIOR_MAX do
    if not DirectoryExists(speechPath + WARRIOR_SFX_FOLDER[U] + PathDelim) then
      fWarriorUseBackup[U] := True;

  //If the folder exists it is likely all the sounds are there
  for U := WARRIOR_MIN to WARRIOR_MAX do
    for WS := Low(TWarriorSpeech) to High(TWarriorSpeech) do
      for I := 0 to 255 do
        if not FileExists(FileOfWarrior(U, WS, I)) then
        begin
          WarriorSoundCount[U, WS] := I;
          Break;
        end;

  //Scan warning messages (e.g. under attack)
  for AN := Low(TAttackNotification) to High(TAttackNotification) do
    for I := 0 to 255 do
      if not FileExists(FileOfNotification(AN, I)) then
      begin
        NotificationSoundCount[AN] := I;
        Break;
      end;

  //Save counts to DAT file for faster access next time
  SaveWarriorSoundsToFile(speechPath + 'count.dat');
end;


function TKMResSounds.LoadWarriorSoundsFromFile(const aFile: string): Boolean;
var
  S: AnsiString;
  MS: TKMemoryStream;
begin
  Result := False;
  if not FileExists(aFile) then Exit;

  MS := TKMemoryStreamBinary.Create;
  try
    MS.LoadFromFile(aFile);
    MS.ReadA(S);
    if S = AnsiString(GAME_REVISION) then
    begin
      MS.Read(WarriorSoundCount, SizeOf(WarriorSoundCount));
      MS.Read(fWarriorUseBackup, SizeOf(fWarriorUseBackup));
      MS.Read(NotificationSoundCount, SizeOf(NotificationSoundCount));
      Result := True;
    end;
  finally
    MS.Free;
  end;
end;


procedure TKMResSounds.SaveWarriorSoundsToFile(const aFile: string);
var
  MS: TKMemoryStream;
begin
  MS := TKMemoryStreamBinary.Create;
  try
    MS.WriteA(GAME_REVISION);
    MS.Write(WarriorSoundCount, SizeOf(WarriorSoundCount));
    MS.Write(fWarriorUseBackup, SizeOf(fWarriorUseBackup));
    MS.Write(NotificationSoundCount, SizeOf(NotificationSoundCount));
    MS.SaveToFile(aFile);
  finally
    MS.Free;
  end;
end;


end.
