unit KM_Campaigns;
{$I KaM_Remake.inc}
interface
uses
  Classes,
  KM_ResTexts, KM_Pics, KM_Maps, KM_MapTypes,
  KM_CommonClasses, KM_Points;


const
  MAX_CAMP_MAPS = 64;
  MAX_CAMP_NODES = 64;

type
  TKMBriefingCorner = (bcBottomRight, bcBottomLeft);
  //Unique campaign identification, stored as 3 ANSI letters (TSK, TPR, etc)
  //3 bytes are used to avoid string types issues
  TKMCampaignId = array [0..2] of Byte;

  TKMCampaignMapProgressData = record
    Completed: Boolean;
    BestCompleteDifficulty: TKMMissionDifficulty;
  end;

  TKMCampaignMapProgressDataArray = array of TKMCampaignMapProgressData;


  TKMCampaignMapData = record
    TxtInfo: TKMMapTxtInfo;
    MissionName: UnicodeString;
  end;

  TKMCampaignMapDataArray = array of TKMCampaignMapData;

  TKMCampaign = class
  private
    //Runtime variables
    fPath: UnicodeString;
    fTextLib: TKMTextLibrarySingle;
    fUnlockedMap: Byte;
    fScriptData: TKMemoryStreamBinary;

    //Saved in CMP
    fCampaignId: TKMCampaignId; //Used to identify the campaign
    fBackGroundPic: TKMPic;
    fMapCount: Byte;
    fShortName: UnicodeString;
    fViewed: Boolean;

    fMapsInfo: TKMCampaignMapDataArray;

    fMapsProgressData: TKMCampaignMapProgressDataArray; //Map data, saved in campaign progress

    function GetDefaultMissionTitle(aIndex: Byte): UnicodeString;

    procedure SetUnlockedMap(aValue: Byte);
    procedure SetMapCount(aValue: Byte);

    procedure LoadFromPath(const aPath: UnicodeString);
    procedure LoadMapsInfo;
    procedure LoadSprites;

    procedure SetCampaignId(aCampaignId: TKMCampaignId);
    procedure UpdateShortName;
  public
    Maps: array of record
      Flag: TKMPointW;
      NodeCount: Byte;
      Nodes: array [0 .. MAX_CAMP_NODES - 1] of TKMPointW;
      TextPos: TKMBriefingCorner;
    end;
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromFile(const aFileName: UnicodeString);
    procedure SaveToFile(const aFileName: UnicodeString);

    property Path: UnicodeString read fPath;
    property BackGroundPic: TKMPic read fBackGroundPic write fBackGroundPic;
    property MapCount: Byte read fMapCount write SetMapCount;
    property CampaignId: TKMCampaignId read fCampaignId write SetCampaignId;
    property ShortName: UnicodeString read fShortName;
    property UnlockedMap: Byte read fUnlockedMap write SetUnlockedMap;
    property ScriptData: TKMemoryStreamBinary read fScriptData;
    property MapsInfo: TKMCampaignMapDataArray read fMapsInfo;
    property MapsProgressData: TKMCampaignMapProgressDataArray read fMapsProgressData;
    property Viewed: Boolean read fViewed write fViewed;

    function GetCampaignTitle: UnicodeString;
    function GetCampaignDescription: UnicodeString;
    function GetCampaignMissionTitle(aIndex: Byte): String;
    function GetMissionFile(aIndex: Byte; const aExt: UnicodeString = '.dat'): String;
    function GetMissionName(aIndex: Byte): String;
    function GetMissionTitle(aIndex: Byte): String;
    function GetMissionBriefing(aIndex: Byte): String;
    function GetBreifingAudioFile(aIndex: Byte): String;
    function GetScriptDataTypeFile: UnicodeString;

    procedure UnlockAllMissions;
  end;


  TKMCampaignsCollection = class
  private
    fActiveCampaign: TKMCampaign; //Campaign we are playing
    fActiveCampaignMap: Byte; //Map of campaign we are playing, could be different than UnlockedMaps
    fList: TList;
    function GetCampaign(aIndex: Integer): TKMCampaign;
    procedure AddCampaign(const aPath: UnicodeString);

    procedure ScanFolder(const aPath: UnicodeString);
    procedure SortCampaigns;
    procedure LoadProgress(const aFileName: UnicodeString);
  public
    constructor Create;
    destructor Destroy; override;

    //Initialization
    procedure Load;
    procedure SaveProgress;

    //Usage
    property ActiveCampaign: TKMCampaign read fActiveCampaign;// write fActiveCampaign;
    function Count: Integer;
    property Campaigns[aIndex: Integer]: TKMCampaign read GetCampaign; default;
    function CampaignById(const aCampaignId: TKMCampaignId): TKMCampaign;
    procedure SetActive(aCampaign: TKMCampaign; aMap: Byte);
    procedure UnlockNextMap;

    procedure UnlockAllCampaignsMissions;
  end;


const
  NO_CAMPAIGN: TKMCampaignId = (0, 0, 0);

implementation
uses
  SysUtils, Math, KromUtils,
  KM_Game, KM_Resource, KM_ResLocales, KM_ResSprites,
  KM_Log, KM_Defaults;


const
  CAMP_HEADER_V1 = $FEED; //Just some header to separate right progress files from wrong
  CAMP_HEADER_V2 = $BEEF;


{ TCampaignsCollection }
constructor TKMCampaignsCollection.Create;
begin
  inherited Create;

  fList := TList.Create;
end;


destructor TKMCampaignsCollection.Destroy;
var
  I: Integer;
begin
  //Free list objects
  for I := 0 to Count - 1 do
    Campaigns[I].Free;

  fList.Free;
  inherited;
end;


procedure TKMCampaignsCollection.AddCampaign(const aPath: UnicodeString);
var
  C: TKMCampaign;
begin
  C := TKMCampaign.Create;
  C.LoadFromPath(aPath);
  fList.Add(C);
end;


//Scan campaigns folder
procedure TKMCampaignsCollection.ScanFolder(const aPath: UnicodeString);
var
  SearchRec: TSearchRec;
begin
  if not DirectoryExists(aPath) then Exit;

  FindFirst(aPath + '*', faDirectory, SearchRec);
  try
    repeat
      if (SearchRec.Name <> '.') and (SearchRec.Name <> '..')
      and (SearchRec.Attr and faDirectory = faDirectory)
      and FileExists(aPath + SearchRec.Name + PathDelim+'info.cmp') then
        AddCampaign(aPath + SearchRec.Name + PathDelim);
    until (FindNext(SearchRec) <> 0);
  finally
    FindClose(SearchRec);
  end;

  SortCampaigns;
end;


procedure TKMCampaignsCollection.SortCampaigns;

  //Return True if items should be exchanged
  function Compare(A, B: TKMCampaign): Boolean;
  begin
    //TSK is first
    if      A.ShortName = 'TSK' then Result := False
    else if B.ShortName = 'TSK' then Result := True
    //TPR is second
    else if A.ShortName = 'TPR' then Result := False
    else if B.ShortName = 'TPR' then Result := True
    //Others are left in existing order (alphabetical)
    else                            Result := False;
  end;

var I, K: Integer;
begin
  for I := 0 to Count - 1 do
    for K := I to Count - 1 do
      if Compare(Campaigns[I], Campaigns[K]) then
        SwapInt(NativeUInt(fList.List[I]), NativeUInt(fList.List[K]));
end;


procedure TKMCampaignsCollection.SetActive(aCampaign: TKMCampaign; aMap: Byte);
begin
  fActiveCampaign := aCampaign;
  fActiveCampaignMap := aMap;
end;


function TKMCampaignsCollection.GetCampaign(aIndex: Integer): TKMCampaign;
begin
  Result := fList[aIndex];
end;


//Read progress from file trying to find matching campaigns
procedure TKMCampaignsCollection.LoadProgress(const aFileName: UnicodeString);
var
  M: TKMemoryStreamBinary;
  C: TKMCampaign;
  I, J, campCount: Integer;
  campName: TKMCampaignId;
  unlocked: Byte;
  HasScriptData: Boolean;
  ScriptDataSize: Cardinal;
begin
  if not FileExists(aFileName) then Exit;

  M := TKMemoryStreamBinary.Create;
  try
    M.LoadFromFile(aFileName);

    M.Read(I); //Check for wrong file format
    //All campaigns will be kept in initial state
    if (I <> CAMP_HEADER_V1) and (I <> CAMP_HEADER_V2) then Exit;
    HasScriptData := (I = CAMP_HEADER_V2);

    M.Read(campCount);
    for I := 0 to campCount - 1 do
    begin
      M.Read(campName, sizeOf(TKMCampaignId));
      M.Read(unlocked);
      C := CampaignById(campName);
      if C <> nil then
      begin
        C.Viewed := True;
        C.UnlockedMap := unlocked;
        for J := 0 to C.MapCount - 1 do
          M.Read(C.fMapsProgressData[J], SizeOf(C.fMapsProgressData[J]));

        C.ScriptData.Clear;
        if HasScriptData then
        begin
          M.Read(ScriptDataSize);
          C.ScriptData.Write(Pointer(Cardinal(M.Memory) + M.Position)^, ScriptDataSize);
          M.Seek(ScriptDataSize, soCurrent); //Seek past script data
        end;
      end;
    end;
  finally
    M.Free;
  end;
end;


procedure TKMCampaignsCollection.SaveProgress;
var
  M: TKMemoryStreamBinary;
  I,J: Integer;
  FilePath: UnicodeString;
begin
  FilePath := ExeDir + SAVES_FOLDER_NAME + PathDelim + 'Campaigns.dat';
  //Makes the folder incase it is missing
  ForceDirectories(ExtractFilePath(FilePath));

  M := TKMemoryStreamBinary.Create;
  try
    M.Write(Integer(CAMP_HEADER_V2)); //Identify our format
    M.Write(Count);
    for I := 0 to Count - 1 do
      if Campaigns[I].Viewed then
      begin
        M.Write(Campaigns[I].CampaignId, SizeOf(TKMCampaignId));
        M.Write(Campaigns[I].UnlockedMap);
        for J := 0 to Campaigns[I].MapCount - 1 do
          M.Write(Campaigns[I].fMapsProgressData[J], SizeOf(Campaigns[I].fMapsProgressData[J]));
        M.Write(Cardinal(Campaigns[I].ScriptData.Size));
        M.Write(Campaigns[I].ScriptData.Memory^, Campaigns[I].ScriptData.Size);
      end;

    M.SaveToFile(FilePath);
  finally
    M.Free;
  end;

  gLog.AddTime('Campaigns.dat saved');
end;


procedure TKMCampaignsCollection.Load;
begin
  ScanFolder({ExeDir +} CAMPAIGNS_FOLDER_NAME + PathDelim);
  LoadProgress({ExeDir +} SAVES_FOLDER_NAME + PathDelim + 'Campaigns.dat');
end;


function TKMCampaignsCollection.Count: Integer;
begin
  Result := fList.Count;
end;


function TKMCampaignsCollection.CampaignById(const aCampaignId: TKMCampaignId): TKMCampaign;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Count - 1 do
    if (Campaigns[I].CampaignId[0] = aCampaignId[0])
    and (Campaigns[I].CampaignId[1] = aCampaignId[1])
    and (Campaigns[I].CampaignId[2] = aCampaignId[2]) then
      Result := Campaigns[I];
end;


procedure TKMCampaignsCollection.UnlockNextMap;
begin
  if ActiveCampaign <> nil then
  begin
    ActiveCampaign.UnlockedMap := fActiveCampaignMap + 1;
    ActiveCampaign.MapsProgressData[fActiveCampaignMap].Completed := True;
    //Update BestDifficulty if we won harder game
    if Byte(ActiveCampaign.MapsProgressData[fActiveCampaignMap].BestCompleteDifficulty) < Byte(gGame.MissionDifficulty)  then
      ActiveCampaign.MapsProgressData[fActiveCampaignMap].BestCompleteDifficulty := gGame.MissionDifficulty;
  end;
end;


procedure TKMCampaignsCollection.UnlockAllCampaignsMissions;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Campaigns[I].UnlockAllMissions;
end;


{ TKMCampaign }
constructor TKMCampaign.Create;
begin
  inherited;

  //1st map is always unlocked to allow to start campaign
  fViewed := False;
  fUnlockedMap := 0;
  fScriptData := TKMemoryStreamBinary.Create;
end;


destructor TKMCampaign.Destroy;
var
  I: Integer;
begin
  FreeAndNil(fTextLib);
  fScriptData.Free;

  for I := 0 to Length(fMapsInfo) - 1 do
    if fMapsInfo[I].TxtInfo <> nil then
      fMapsInfo[I].TxtInfo.Free;

  //Free background texture
  if fBackGroundPic.ID <> 0 then
    gRes.Sprites[rxCustom].DeleteSpriteTexture(fBackGroundPic.ID);

  inherited;
end;


procedure TKMCampaign.UpdateShortName;
begin
  fShortName := WideChar(fCampaignId[0]) + WideChar(fCampaignId[1]) + WideChar(fCampaignId[2]);
end;


//Load campaign info from *.cmp file
//It should be private, but it is used by CampaignBuilder
procedure TKMCampaign.LoadFromFile(const aFileName: UnicodeString);
var
  M: TKMemoryStreamBinary;
  I, K: Integer;
  cmp: TBytes;
begin
  if not FileExists(aFileName) then Exit;

  M := TKMemoryStreamBinary.Create;
  M.LoadFromFile(aFileName);

  //Convert old AnsiString into new [0..2] Byte format
  M.ReadBytes(cmp);
  Assert(Length(cmp) = 3);
  fCampaignId[0] := cmp[0];
  fCampaignId[1] := cmp[1];
  fCampaignId[2] := cmp[2];

  UpdateShortName;

  M.Read(fMapCount);
  SetMapCount(fMapCount); //Update array's sizes

  for I := 0 to fMapCount - 1 do
  begin
    M.Read(Maps[I].Flag);
    M.Read(Maps[I].NodeCount);
    for K := 0 to Maps[I].NodeCount - 1 do
      M.Read(Maps[I].Nodes[K]);
    M.Read(Maps[I].TextPos, SizeOf(TKMBriefingCorner));
  end;

  M.Free;
end;


procedure TKMCampaign.SaveToFile(const aFileName: UnicodeString);
var
  M: TKMemoryStreamBinary;
  I, K: Integer;
  cmp: TBytes;
begin
  Assert(aFileName <> '');

  M := TKMemoryStreamBinary.Create;
  SetLength(cmp, 3);
  cmp[0] := fCampaignId[0];
  cmp[1] := fCampaignId[1];
  cmp[2] := fCampaignId[2];
  M.WriteBytes(cmp);
  M.Write(fMapCount);

  for I := 0 to fMapCount - 1 do
  begin
    M.Write(Maps[I].Flag);
    M.Write(Maps[I].NodeCount);
    for K := 0 to Maps[I].NodeCount - 1 do
    begin
      //One-time fix for campaigns made before r4880
      //Inc(Maps[I].Nodes[K].X, 5);
      //Inc(Maps[I].Nodes[K].Y, 5);
      M.Write(Maps[I].Nodes[K]);
    end;
    M.Write(Maps[I].TextPos, SizeOf(TKMBriefingCorner));
  end;

  M.SaveToFile(aFileName);
  M.Free;
end;


function TKMCampaign.GetScriptDataTypeFile: UnicodeString;
begin
  Result := fPath + 'campaigndata.script';
end;


procedure TKMCampaign.LoadMapsInfo;
var
  I: Integer;
  TextMission: TKMTextLibraryMulti;
begin
  for I := 0 to fMapCount - 1 do
  begin
    //Load TxtInfo
    if fMapsInfo[I].TxtInfo = nil then
      fMapsInfo[I].TxtInfo := TKMMapTxtInfo.Create
    else
      fMapsInfo[I].TxtInfo.ResetInfo;
    fMapsInfo[I].TxtInfo.LoadTXTInfo(GetMissionFile(I, '.txt'));

    fMapsInfo[I].MissionName := '';
    //Load mission name from mission Libx library
    TextMission := TKMTextLibraryMulti.Create;
    try
      TextMission.LoadLocale(GetMissionFile(I, '.%s.libx'));
      if TextMission.HasText(MISSION_NAME_LIBX_ID) then
        fMapsInfo[I].MissionName := StringReplace(TextMission[MISSION_NAME_LIBX_ID], '|', ' ', [rfReplaceAll]); //Replace | with space
    finally
      FreeAndNil(TextMission);
    end;
  end;
end;


procedure TKMCampaign.LoadSprites;
var
  SP: TKMSpritePack;
  FirstSpriteIndex: Word;
begin
  if gRes.Sprites <> nil then
  begin
    SP := gRes.Sprites[rxCustom];
    FirstSpriteIndex := SP.RXData.Count + 1;
    SP.LoadFromRXXFile(fPath + 'images.rxx', FirstSpriteIndex);

    if FirstSpriteIndex <= SP.RXData.Count then
    begin
      //Images were successfuly loaded
      SP.MakeGFX(False, FirstSpriteIndex);
      SP.ClearTemp;
      fBackGroundPic.RX := rxCustom;
      fBackGroundPic.ID := FirstSpriteIndex;
    end
    else
    begin
      //Images were not found - use blank
      fBackGroundPic.RX := rxCustom;
      fBackGroundPic.ID := 0;
    end;
  end;
end;


procedure TKMCampaign.LoadFromPath(const aPath: UnicodeString);
begin
  fPath := aPath;

  LoadFromFile(fPath + 'info.cmp');
  LoadMapsInfo;

  FreeAndNil(fTextLib);
  fTextLib := TKMTextLibrarySingle.Create;
  fTextLib.LoadLocale(fPath + 'text.%s.libx');

  LoadSprites;

  if UNLOCK_CAMPAIGN_MAPS then //Unlock more maps for debug
    fUnlockedMap := fMapCount - 1;
end;


procedure TKMCampaign.UnlockAllMissions;
begin
  fUnlockedMap := fMapCount - 1;
end;


procedure TKMCampaign.SetMapCount(aValue: Byte);
begin
  fMapCount := aValue;
  SetLength(Maps, fMapCount);
  SetLength(fMapsProgressData, fMapCount);
  SetLength(fMapsInfo, fMapCount);
end;

procedure TKMCampaign.SetCampaignId(aCampaignId: TKMCampaignId);
begin
  fCampaignId := aCampaignId;
  UpdateShortName;
end;


function TKMCampaign.GetCampaignTitle: UnicodeString;
begin
  Result := fTextLib[0];
end;


function TKMCampaign.GetCampaignDescription: UnicodeString;
begin
  Result := fTextLib[2];
end;


function TKMCampaign.GetDefaultMissionTitle(aIndex: Byte): UnicodeString;
begin
  if fMapsInfo[aIndex].MissionName <> '' then
    Result := fMapsInfo[aIndex].MissionName
  else
    //Have nothing - use default mission name
    //Otherwise just Append (by default MissionName is empty anyway)
    Result := Format(gResTexts[TX_GAME_MISSION], [aIndex+1]) + fMapsInfo[aIndex].MissionName;
end;


function TKMCampaign.GetCampaignMissionTitle(aIndex: Byte): String;
begin
  //We have template for mission name in 3:
  if fTextLib[3] <> '' then
  begin
    Assert(CountMatches(fTextLib[3], '%d') = 1, 'Custom campaign mission template must have a single "%d" in it.');

    //We have also %s for custom mission name
    if CountMatches(fTextLib[3], '%s') = 1 then
    begin
      //We can use different order for %d and %s, then choose Format 2 ways
      //First - %d %s
      if Pos('%d', fTextLib[3]) < Pos('%s', fTextLib[3]) then
        Result := Format(fTextLib[3], [aIndex+1, fMapsInfo[aIndex].MissionName])  
      else
        Result := Format(fTextLib[3], [fMapsInfo[aIndex].MissionName, aIndex+1]); //Then order: %s %d
    end else
      //Otherwise just Append (by default MissionName is empty anyway)
      Result := Format(fTextLib[3], [aIndex+1]) + fMapsInfo[aIndex].MissionName;
  end
  else
    Result := GetDefaultMissionTitle(aIndex);
end;


function TKMCampaign.GetMissionFile(aIndex: Byte; const aExt: UnicodeString = '.dat'): String;
begin
  Result := fPath + GetMissionName(aIndex) + PathDelim + GetMissionName(aIndex) + aExt;
end;


function TKMCampaign.GetMissionName(aIndex: Byte): String;
begin
  Result := ShortName + Format('%.2d', [aIndex + 1]);
end;


function TKMCampaign.GetMissionTitle(aIndex: Byte): String;
begin
  if fTextLib[1] <> '' then
    Result := Format(fTextLib[1], [aIndex+1]) //Save it for Legacy support
  else
    Result := GetDefaultMissionTitle(aIndex);
end;


//Mission texts of original campaigns are available in all languages,
//custom campaigns are unlikely to have more texts in more than 1-2 languages
function TKMCampaign.GetMissionBriefing(aIndex: Byte): String;
begin
  Result := fTextLib[10 + aIndex];
end;


function TKMCampaign.GetBreifingAudioFile(aIndex: Byte): String;
begin
  Result := fPath + ShortName + Format('%.2d', [aIndex+1]) + PathDelim +
            ShortName + Format('%.2d', [aIndex + 1]) + '.' + UnicodeString(gResLocales.UserLocale) + '.mp3';

  if not FileExists(Result) then
    Result := fPath + ShortName + Format('%.2d', [aIndex+1]) + PathDelim +
              ShortName + Format('%.2d', [aIndex + 1]) + '.' + UnicodeString(gResLocales.FallbackLocale) + '.mp3';

  if not FileExists(Result) then
    Result := fPath + ShortName + Format('%.2d', [aIndex+1]) + PathDelim +
              ShortName + Format('%.2d', [aIndex + 1]) + '.' + UnicodeString(gResLocales.DefaultLocale) + '.mp3';
end;


//When player completes one map we allow to reveal the next one, note that
//player may be replaying previous maps, in that case his progress remains the same
procedure TKMCampaign.SetUnlockedMap(aValue: Byte);
begin
  fUnlockedMap := EnsureRange(aValue, fUnlockedMap, fMapCount - 1);
end;


end.
