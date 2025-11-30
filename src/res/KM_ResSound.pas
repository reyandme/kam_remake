unit KM_ResSound;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  KM_Defaults;

type
  TAttackNotification = (anCitizens, anTown, anTroops);

  // Original sound effects list from KaM
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

  // New sound effects added by KMR
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

  // Sounds to play on different warrior orders
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

  // Actually this is WAV structure
  TKMSoundData = record
    Head: TWAVHeaderEx;
    Data: array of Byte;
    Foot: array of Byte; // Contains optional WAV chunks

    // Our custom field, should be probably moved out
    IsLoaded: Boolean;
  end;

  TKMSoundProp = packed record
    SampleRate: Integer;
    Volume: Integer; // Untested, but I'm quite sure it is volume (see KM_SoundFX.pas from 14.07.2009)
    E, F, G, H, I, J, K, L: Word; // Unknown, but have some values
    Id: Word;
  end;

  TKMSoundType = (stGame, stMenu);

  TKMResSounds = class
  private
    fWavesCount: Integer;

    fWAVSize: array [1..200] of Integer;
    fTab2: array [1..200] of SmallInt;
    fWaveProps: array of TKMSoundProp;

    fLocaleString: AnsiString; //Locale used to access warrior sounds

    fWarriorUseBackup: array[WARRIOR_MIN..WARRIOR_MAX] of boolean;

    procedure LoadSoundsDAT;
    procedure ScanWarriorSounds;
    function LoadWarriorSoundsFromFile(const aFile: string): Boolean;
    procedure SaveWarriorSoundsToFile(const aFile: string);
    procedure ExportCSV(const aFilename: string);
  public
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
    function GetSoundSampleRate(aSFX: TSoundFX): Integer;

    property WavesCount: Integer read fWavesCount;

    procedure ExportSounds;
  end;


implementation
uses
  System.Classes, System.SysUtils, System.TypInfo, System.Math, System.StrUtils,
  KromUtils,
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


  // Const because RTTI is so clunky and slow
  SFX_NAME: array [TSoundFX] of string = (
    'sfxNone',
    'sfxCornCut',
    'sfxDig',
    'sfxPave',
    'sfxMineStone',
    'sfxCornSow',
    'sfxChopTree',
    'sfxhousebuild',
    'sfxplacemarker',
    'sfxClick',
    'sfxmill',
    'sfxsaw',
    'sfxwineStep',
    'sfxwineDrain',
    'sfxmetallurgists',
    'sfxcoalDown',
    'sfxPig1', 'sfxPig2', 'sfxPig3', 'sfxPig4',
    'sfxMine',
    'sfxunknown21', //Pig?
    'sfxLeather',
    'sfxBakerSlap',
    'sfxCoalMineThud',
    'sfxButcherCut',
    'sfxSausageString',
    'sfxQuarryClink',
    'sfxTreeDown',
    'sfxWoodcutterDig',
    'sfxCantPlace',
    'sfxMessageOpen',
    'sfxMessageClose',
    'sfxMessageNotice',
    //Usage of melee sounds can be found in Docs\Melee sounds in KaM.csv
    'sfxMelee34', 'sfxMelee35', 'sfxMelee36', 'sfxMelee37', 'sfxMelee38',
    'sfxMelee39', 'sfxMelee40', 'sfxMelee41', 'sfxMelee42', 'sfxMelee43',
    'sfxMelee44', 'sfxMelee45', 'sfxMelee46', 'sfxMelee47', 'sfxMelee48',
    'sfxMelee49', 'sfxMelee50', 'sfxMelee51', 'sfxMelee52', 'sfxMelee53',
    'sfxMelee54', 'sfxMelee55', 'sfxMelee56', 'sfxMelee57',
    'sfxBowDraw',
    'sfxArrowHit',
    'sfxCrossbowShoot',  //60
    'sfxCrossbowDraw',
    'sfxBowShoot',       //62
    'sfxBlacksmithBang',
    'sfxBlacksmithFire',
    'sfxCarpenterHammer', //65
    'sfxHorse1', 'sfxHorse2', 'sfxHorse3', 'sfxHorse4',
    'sfxRockThrow',
    'sfxHouseDestroy',
    'sfxSchoolDing',
    //Below are TPR sounds ...
    'sfxSlingerShoot',
    'sfxBalistaShoot',
    'sfxCatapultShoot',
    'sfxunknown76',
    'sfxCatapultReload',
    'sfxSiegeBuildingSmash'
  );


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
  Head: record Size, Count: Word; end;
  soundFlag: array [1..200] of Integer;
  footerSize: array [1..200] of Integer;
begin
  if not FileExists(ExeDir + 'data' + PathDelim + 'sfx' + PathDelim + 'sounds.dat') then Exit;

  var memoryStream := TMemoryStream.Create;
  try
    memoryStream.LoadFromFile(ExeDir + 'data' + PathDelim + 'sfx' + PathDelim + 'sounds.dat');
    memoryStream.Read(Head, 4);
    memoryStream.Read(fWAVSize, Head.Count*4); //Read Count*4bytes into WAVSize(WaveSizes)
    memoryStream.Read(fTab2, Head.Count*2); //Read Count*2bytes into Tab2(No idea what is it)

    fWavesCount := Head.Count;
    SetLength(fWaves, fWavesCount+1);

    for var I := 1 to Head.Count do
    begin
      footerSize[I] := 0;

      memoryStream.Read(soundFlag[I], 4); // Always '1' for existing waves

      if fWAVSize[I] <> 0 then
      begin
        // Wave header
        memoryStream.Read(fWaves[I].Head, SizeOf(fWaves[I].Head));

        // Wave data
        SetLength(fWaves[I].Data, fWaves[I].Head.DataSize);
        memoryStream.Read(fWaves[I].Data[0], fWaves[I].Head.DataSize);

        // Footer contains optional LIST INFO chunks (start is aligned to 2-byte boundaries):
        //  - ICOP - Copyright information about the file (e.g., "Copyright © Microsoft Corp. 1995")
        //  - ICRD - The date the subject of the file was created (e.g., "1995-10-24.A")
        //  - ISFT - Name of the software package used to create the file (e.g. "GoldWave v2.10 (C) Chris Craig")
        // Since these chunks do not bear any functional load, we just ignore them
        footerSize[I] := fWAVSize[I] - SizeOf(fWaves[I].Head) - fWaves[I].Head.DataSize;
        SetLength(fWaves[I].Foot, footerSize[I]);
        memoryStream.Read(fWaves[I].Foot[0], footerSize[I]);
      end;
      fWaves[I].IsLoaded := True;
    end;

    var numberOfEntries: Integer;
    memoryStream.Read(numberOfEntries, 4); // 400
    SetLength(fWaveProps, numberOfEntries+1);
    var t: Integer;
    memoryStream.Read(t, 4); // 78
    memoryStream.Read(t, 4); // 78
    memoryStream.Read(t, 4); // 77
    var entrySize: Integer;
    memoryStream.Read(entrySize, 4); // 26

    for var K := 1 to numberOfEntries do
      memoryStream.Read(fWaveProps[K], entrySize);
  finally
    memoryStream.Free;
  end;

  if DBG_EXPORT_SOUNDS_DAT then
    ExportCSV(ExeDir + 'export_sounds.original.csv');

  if DBG_EXPORT_SOUNDS_DAT then
  begin
    ExportCSV(ExeDir + 'export_sounds.remake.csv');
    Halt;
  end;
end;


procedure TKMResSounds.ExportCSV(const aFilename: string);
begin
  var sw := TStreamWriter.Create(aFilename);
  sw.WriteLine('Id,Name,WAVSize,Tab2,Rate,BPS,Length,|,Rate,Volume,E,F,G,H,I,J,K,L,Id');
  for var K := 1 to fWavesCount do
  if Length(fWaves[K].Data) > 0 then
  begin
    var dur := Round(fWaves[K].Head.DataSize / Max(fWaves[K].Head.BytesPerSecond, 1) * 1000);

    sw.Write(IntToStr(K) + ',');
    sw.Write(SFX_NAME[TSoundFX(K)] + ',');
    sw.Write(IntToStr(fWAVSize[K]) + ',');
    sw.Write(IntToStr(fTab2[K]) + ',');
    sw.Write(IntToStr(fWaves[K].Head.SampleRate) + ',');
    sw.Write(IntToStr(fWaves[K].Head.BitsPerSample) + 'bit,');
    sw.Write(IntToStr(dur) + 'ms,');
    sw.Write('|,');
    sw.Write(IntToStr(fWaveProps[K].SampleRate) + ',');
    sw.Write(IntToStr(fWaveProps[K].Volume) + ',');
    sw.Write(IntToStr(fWaveProps[K].E) + ',');
    sw.Write(IntToStr(fWaveProps[K].F) + ',');
    sw.Write(IntToStr(fWaveProps[K].G) + ',');
    sw.Write(IntToStr(fWaveProps[K].H) + ',');
    sw.Write(IntToStr(fWaveProps[K].I) + ',');
    sw.Write(IntToStr(fWaveProps[K].J) + ',');
    sw.Write(IntToStr(fWaveProps[K].K) + ',');
    sw.Write(IntToStr(fWaveProps[K].L) + ',');
    sw.Write(IntToStr(fWaveProps[K].Id) + ',');
    sw.WriteLine;
  end;
  sw.Free;
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


function TKMResSounds.GetSoundSampleRate(aSFX: TSoundFX): Integer;
begin
  // Unfortunately WaveProps are stored slightly unordered
  // It would be better to reorder them to be in sync with Waves later on
  var soundIndex := Ord(aSFX) - 1;

  Result := 0;
  for var I := 1 to High(fWaveProps) do
  if fWaveProps[I].Id = soundIndex then
    Exit(fWaveProps[I].SampleRate);
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
  memoryStream: TKMemoryStream;
begin
  Result := False;
  if not FileExists(aFile) then Exit;

  memoryStream := TKMemoryStreamBinary.Create;
  try
    memoryStream.LoadFromFile(aFile);
    memoryStream.ReadA(S);
    if S = AnsiString(GAME_REVISION) then
    begin
      memoryStream.Read(WarriorSoundCount, SizeOf(WarriorSoundCount));
      memoryStream.Read(fWarriorUseBackup, SizeOf(fWarriorUseBackup));
      memoryStream.Read(NotificationSoundCount, SizeOf(NotificationSoundCount));
      Result := True;
    end;
  finally
    memoryStream.Free;
  end;
end;


procedure TKMResSounds.SaveWarriorSoundsToFile(const aFile: string);
var
  memoryStream: TKMemoryStream;
begin
  memoryStream := TKMemoryStreamBinary.Create;
  try
    memoryStream.WriteA(GAME_REVISION);
    memoryStream.Write(WarriorSoundCount, SizeOf(WarriorSoundCount));
    memoryStream.Write(fWarriorUseBackup, SizeOf(fWarriorUseBackup));
    memoryStream.Write(NotificationSoundCount, SizeOf(NotificationSoundCount));
    memoryStream.SaveToFile(aFile);
  finally
    memoryStream.Free;
  end;
end;


end.
