unit KM_Campaigns;
{$I KaM_Remake.inc}
interface
uses
  Classes, Generics.Collections, SyncObjs,
  KM_ResTexts, KM_Pics, KM_Maps, KM_MapTypes, KM_CampaignTypes,
  KM_CommonClasses, KM_Points;


const
  MAX_CAMP_MAPS = 64;
  MAX_CAMP_NODES = 64;

type
  TKMBriefingCorner = (bcBottomRight, bcBottomLeft);

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
    fScriptDataStream: TKMemoryStream;

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
    property ScriptDataStream: TKMemoryStream read fScriptDataStream;
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
    function GetBriefingAudioFile(aIndex: Byte): String;
    function GetCampaignDataScriptFilePath: UnicodeString;

    procedure UnlockAllMissions;
  end;


  TKMCampaignEvent = procedure (aCampaign: TKMCampaign) of object;

  TKMCampaignsScanner = class(TThread)
  private
    fOnAdd: TKMCampaignEvent;
    fOnAddDone: TNotifyEvent;
    fOnLoadProgress: TNotifyEvent;
    fOnComplete: TNotifyEvent;
  public
    constructor Create(aOnAdd: TKMCampaignEvent; aOnAddDone, aOnLoadProgress, aOnTerminate, aOnComplete: TNotifyEvent);
    procedure Execute; override;
  end;


  TKMCampaignsCollection = class
  private
    fActiveCampaign: TKMCampaign; //Campaign we are playing
    fActiveCampaignMap: Byte; //Map of campaign we are playing, could be different than UnlockedMaps
    fList: TList<TKMCampaign>;

    fOnRefresh: TNotifyEvent;
    fOnTerminate: TNotifyEvent;
    fOnComplete: TNotifyEvent;

    fCriticalSection: TCriticalSection;
    fScanner: TKMCampaignsScanner;
    fScanning: Boolean; //Flag if scan is in progress
    fUpdateNeeded: Boolean;

    function GetCampaign(aIndex: Integer): TKMCampaign;

    procedure CampaignAdd(aCampaign: TKMCampaign);
    procedure CampaignAddDone(Sender: TObject);
    procedure LoadProgress(Sender: TObject);
    procedure ScanTerminate(Sender: TObject);
    procedure ScanComplete(Sender: TObject);

    procedure Clear;
    procedure SortCampaigns;
    procedure LoadProgressFromFile(const aFileName: UnicodeString);
  public
    constructor Create;
    destructor Destroy; override;

    //Initialization
    procedure SaveProgress;

    procedure Lock;
    procedure Unlock;
    procedure TerminateScan;
    procedure Refresh(aOnRefresh: TNotifyEvent;  aOnTerminate: TNotifyEvent = nil;aOnComplete: TNotifyEvent = nil);

    //Usage
    property ActiveCampaign: TKMCampaign read fActiveCampaign;// write fActiveCampaign;
    function Count: Integer;
    property Campaigns[aIndex: Integer]: TKMCampaign read GetCampaign; default;
    function CampaignById(const aCampaignId: TKMCampaignId): TKMCampaign;
    procedure SetActive(aCampaign: TKMCampaign; aMap: Byte);
    procedure UnlockNextMap;

    procedure UnlockAllCampaignsMissions;

    procedure UpdateState;
  end;


const
  NO_CAMPAIGN: TKMCampaignId = (0, 0, 0);

implementation
uses
  SysUtils, Math, KromUtils,
  KM_GameParams,
  KM_Resource, KM_ResLocales, KM_ResSprites, KM_ResTypes,
  KM_Log, KM_Defaults, KM_CommonUtils, KM_FileIO, KM_Sort
  {$IFDEF FPC}
  , Generics.Defaults
  {$ENDIF}
  ;

const
  CAMP_HEADER_V1 = $FEED; //Just some header to separate right progress files from wrong
  CAMP_HEADER_V2 = $BEEF;
  CAMP_HEADER_V3 = $CEED;


{ TCampaignsCollection }
constructor TKMCampaignsCollection.Create;
begin
  inherited Create;

  fList := TObjectList<TKMCampaign>.Create(True);

  //CS is used to guard sections of code to allow only one thread at once to access them
  //We mostly don't need it, as UI should access Maps only when map events are signaled
  //it mostly acts as a safenet
  fCriticalSection := TCriticalSection.Create;
end;


destructor TKMCampaignsCollection.Destroy;
begin
  //Terminate and release the Scanner if we have one working or finished
  TerminateScan;

  // Objects will be freed automatically since we use TObjectList
  fList.Free;

  fCriticalSection.Free;

  inherited;
end;


// Return True if A is considered less (<) than B, False otherwise
function TKMCampaignComparator(constref A, B: TKMCampaign): Boolean;
var
  aPrio, bPrio: Integer;
begin
  // TSK goes first
  if      A.ShortName = 'TSK' then aPrio := 0
  // TPR goes second
  else if A.ShortName = 'TPR' then aPrio := 1
  // Others go lexicographically sorted
  else                             aPrio := 2;

  if      B.ShortName = 'TSK' then bPrio := 0
  else if B.ShortName = 'TPR' then bPrio := 1
  else                             bPrio := 2;

  Result := (aPrio < bPrio)
             or ((2 = aPrio) and (aPrio = bPrio) and (A.ShortName < B.ShortName));
end;


{$IFDEF Unix}
// Return Negative if A < B, Positive if B < A, 0 otherwise
function TKMCampaignComparatorThreeWay(constref A, B: TKMCampaign): LongInt;
begin
  if      (TKMCampaignComparator(A, B)) then Result := -1
  else if (TKMCampaignComparator(B, A)) then Result := +1
  else                                       Result :=  0;
end;
{$ENDIF}


procedure TKMCampaignsCollection.SortCampaigns;
begin
  {$IFNDEF Unix}
  SelectionSort<TKMCampaign>(fList, 0, Count - 1, @TKMCampaignComparator);
  {$ELSE}
  fList.Sort(@TKMCampaignComparatorThreeWay);
  {$ENDIF}
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
procedure TKMCampaignsCollection.LoadProgressFromFile(const aFileName: UnicodeString);
var
  M: TKMemoryStream;
  camp: TKMCampaign;
  I, J, campCount: Integer;
  campName: TKMCampaignId;
  unlocked: Byte;
  hasScriptData, isViewed: Boolean;
  scriptDataSize: Cardinal;
begin
  if not FileExists(aFileName) then Exit;

  M := TKMemoryStreamBinary.Create;
  try
    M.LoadFromFile(aFileName);

    M.Read(I); //Check for wrong file format
    //All campaigns will be kept in initial state
    if (I <> CAMP_HEADER_V1)
      and (I <> CAMP_HEADER_V2)
      and (I <> CAMP_HEADER_V3) then Exit;
    hasScriptData := (I = CAMP_HEADER_V3);

    M.Read(campCount);
    for I := 0 to campCount - 1 do
    begin
      M.Read(isViewed);
      if isViewed then
      begin
        M.Read(campName, sizeOf(TKMCampaignId));
        M.Read(unlocked);
        camp := CampaignById(campName);
        if camp <> nil then
        begin
          camp.Viewed := True;
          camp.UnlockedMap := unlocked;
          for J := 0 to camp.MapCount - 1 do
            M.Read(camp.fMapsProgressData[J], SizeOf(camp.fMapsProgressData[J]));

          camp.ScriptDataStream.Clear;
          if hasScriptData then
          begin
            M.Read(scriptDataSize);
            camp.ScriptDataStream.Write(Pointer(NativeUInt(M.Memory) + M.Position)^, scriptDataSize);
            M.Seek(scriptDataSize, soCurrent); //Seek past script data
          end;
        end;
      end;
    end;
  finally
    M.Free;
  end;
end;


procedure TKMCampaignsCollection.SaveProgress;
var
  I, J: Integer;
  M: TKMemoryStream;
  filePath: UnicodeString;
begin
  filePath := ExeDir + SAVES_FOLDER_NAME + PathDelim + 'Campaigns.dat';
  //Makes the folder incase it is missing
  ForceDirectories(ExtractFilePath(filePath));

  M := TKMemoryStreamBinary.Create;
  try
    M.Write(Integer(CAMP_HEADER_V3)); //Identify our format
    M.Write(Count);
    for I := 0 to Count - 1 do
    begin
      M.Write(Campaigns[I].Viewed);
      if Campaigns[I].Viewed then
      begin
        M.Write(Campaigns[I].CampaignId, SizeOf(TKMCampaignId));
        M.Write(Campaigns[I].UnlockedMap);
        for J := 0 to Campaigns[I].MapCount - 1 do
          M.Write(Campaigns[I].fMapsProgressData[J], SizeOf(Campaigns[I].fMapsProgressData[J]));
        M.Write(Cardinal(Campaigns[I].ScriptDataStream.Size));
        M.Write(Campaigns[I].ScriptDataStream.Memory^, Campaigns[I].ScriptDataStream.Size);
      end;
    end;

    M.SaveToFile(filePath);
  finally
    M.Free;
  end;

  gLog.AddTime('Campaigns.dat saved');
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
    if Byte(ActiveCampaign.MapsProgressData[fActiveCampaignMap].BestCompleteDifficulty) < Byte(gGameParams.MissionDifficulty)  then
      ActiveCampaign.MapsProgressData[fActiveCampaignMap].BestCompleteDifficulty := gGameParams.MissionDifficulty;
  end;
end;


procedure TKMCampaignsCollection.UnlockAllCampaignsMissions;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Campaigns[I].UnlockAllMissions;
end;


procedure TKMCampaignsCollection.Lock;
begin
  fCriticalSection.Enter;
end;


procedure TKMCampaignsCollection.Unlock;
begin
  fCriticalSection.Leave;
end;


procedure TKMCampaignsCollection.CampaignAdd(aCampaign: TKMCampaign);
begin
  Lock;
  try
    fList.Add(aCampaign);

    //Set the scanning to False so we could Sort
    fScanning := False;

    //Keep the maps sorted
    //We signal from Locked section, so everything caused by event can safely access our Maps
    SortCampaigns;

    fScanning := True;
  finally
    Unlock;
  end;
end;


procedure TKMCampaignsCollection.CampaignAddDone(Sender: TObject);
begin
  fUpdateNeeded := True; //Next time the GUI thread calls UpdateState we will run fOnRefresh
end;


procedure TKMCampaignsCollection.LoadProgress(Sender: TObject);
begin
  Lock;
  try
    LoadProgressFromFile(ExeDir + SAVES_FOLDER_NAME + PathDelim + 'Campaigns.dat');
  finally
    Unlock;
  end;
end;


//Scan was terminated
//No need to resort since that was done in last MapAdd event
procedure TKMCampaignsCollection.ScanTerminate(Sender: TObject);
begin
  Lock;
  try
    fScanning := False;
    if Assigned(fOnTerminate) then
      fOnTerminate(Self);
  finally
    Unlock;
  end;
end;


//All maps have been scanned
//No need to resort since that was done in last MapAdd event
procedure TKMCampaignsCollection.ScanComplete(Sender: TObject);
begin
  Lock;
  try
    fScanning := False;
    if Assigned(fOnComplete) then
      fOnComplete(Self);
  finally
    Unlock;
  end;
end;


procedure TKMCampaignsCollection.TerminateScan;
begin
  if (fScanner <> nil) then
  begin
    fScanner.Terminate;
    fScanner.WaitFor;
    fScanner.Free;
    fScanner := nil;
    fScanning := False;
  end;
  fUpdateNeeded := False; //If the scan was terminated we should not run fOnRefresh next UpdateState
end;


procedure TKMCampaignsCollection.Clear;
var
  I: Integer;
begin
  Assert(not fScanning, 'Guarding from access to inconsistent data');
  Lock;
  try
    for I := fList.Count - 1 downto 0 do
      fList.Delete(I);
  finally
    Unlock;
  end;
end;


//Start the refresh of maplist
procedure TKMCampaignsCollection.Refresh(aOnRefresh: TNotifyEvent; aOnTerminate: TNotifyEvent = nil; aOnComplete: TNotifyEvent = nil);
begin
  //Terminate previous Scanner if two scans were launched consequentialy
  TerminateScan;
  Clear;

  fOnRefresh := aOnRefresh;
  fOnComplete := aOnComplete;
  fOnTerminate := aOnTerminate;

  //Scan will launch upon create automatically
  fScanning := True;
  fScanner := TKMCampaignsScanner.Create(CampaignAdd, CampaignAddDone, LoadProgress, ScanTerminate, ScanComplete);
end;


procedure TKMCampaignsCollection.UpdateState;
begin
  if Self = nil then Exit;

  if not fUpdateNeeded then Exit;

  if Assigned(fOnRefresh) then
    fOnRefresh(Self);

  fUpdateNeeded := False;
end;


{ TKMCampaign }
constructor TKMCampaign.Create;
begin
  inherited;

  //1st map is always unlocked to allow to start campaign
  fViewed := False;
  fUnlockedMap := 0;
  fScriptDataStream := TKMemoryStreamBinary.Create;
end;


destructor TKMCampaign.Destroy;
var
  I: Integer;
begin
  FreeAndNil(fTextLib);
  fScriptDataStream.Free;

  for I := 0 to High(fMapsInfo) do
    FreeAndNil(fMapsInfo[I].TxtInfo);

  // Free background texture
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
  M: TKMemoryStream;
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
  M: TKMemoryStream;
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


function TKMCampaign.GetCampaignDataScriptFilePath: UnicodeString;
begin
  Result := fPath + CAMPAIGN_DATA_FILENAME + EXT_FILE_SCRIPT_DOT;
end;


procedure TKMCampaign.LoadMapsInfo;
var
  I: Integer;
  textMission: TKMTextLibraryMulti;
begin
  //Load mission name from mission Libx library
  textMission := TKMTextLibraryMulti.Create;
  try
    for I := 0 to fMapCount - 1 do
    begin
      //Load TxtInfo
      if fMapsInfo[I].TxtInfo = nil then
        fMapsInfo[I].TxtInfo := TKMMapTxtInfo.Create
      else
        fMapsInfo[I].TxtInfo.ResetInfo;

      fMapsInfo[I].TxtInfo.LoadTXTInfo(GetMissionFile(I, '.txt'));

      fMapsInfo[I].MissionName := '';

      textMission.Clear; // Better clear object, than rectreate it for every map
      // Make a full scan for Libx top ID, to allow unordered Libx ID's by not carefull campaign makers
      textMission.LoadLocale(GetMissionFile(I, '.%s.libx'));//, True);

      if textMission.HasText(MISSION_NAME_LIBX_ID) then
        fMapsInfo[I].MissionName := StringReplace(textMission[MISSION_NAME_LIBX_ID], '|', ' ', [rfReplaceAll]); //Replace | with space
    end;
  finally
    FreeAndNil(textMission);
  end;
end;


procedure TKMCampaign.LoadSprites;
var
  SP: TKMSpritePack;
  firstSpriteIndex: Word;
begin
  if gRes.Sprites  = nil then Exit;
  
  gLog.AddNoTime('Loading campaign images.rxx for ' + fShortName);

  SP := gRes.Sprites[rxCustom];
  firstSpriteIndex := SP.RXData.Count + 1;

  SP.LoadFromRXXFile(fPath + 'images.rxx', firstSpriteIndex);

  if firstSpriteIndex <= SP.RXData.Count then
  begin
    // Make campaign sprite GFX in the main thread only
    TThread.Synchronize(TThread.CurrentThread, procedure
      begin
        //Images were successfully loaded
        {$IFNDEF NO_OGL}
        SP.MakeGFX(False, firstSpriteIndex);
        {$ENDIF}
      end
    );

    SP.ClearTemp;
    fBackGroundPic.RX := rxCustom;
    fBackGroundPic.ID := firstSpriteIndex;
  end
  else
  begin
    //Images were not found - use blank
    fBackGroundPic.RX := rxCustom;
    fBackGroundPic.ID := 0;
  end;
end;


procedure TKMCampaign.LoadFromPath(const aPath: UnicodeString);
begin
  // Load times are about:
  // LoadMapsInfo - 20-80ms,  LoadLocale 0.5 ms, LoadSprites ~50ms
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
const
  MISS_TEMPL_ID = 3; //We have template for mission name in 3:
begin
  if fTextLib.IsIndexValid(MISS_TEMPL_ID) and (fTextLib[MISS_TEMPL_ID] <> '') then
  begin
    Assert(CountMatches(fTextLib[MISS_TEMPL_ID], '%d') = 1, 'Custom campaign mission template must have a single "%d" in it.');

    //We have also %s for custom mission name
    if CountMatches(fTextLib[MISS_TEMPL_ID], '%s') = 1 then
    begin
      //We can use different order for %d and %s, then choose Format 2 ways
      //First - %d %s
      if Pos('%d', fTextLib[MISS_TEMPL_ID]) < Pos('%s', fTextLib[MISS_TEMPL_ID]) then
        Result := Format(fTextLib[MISS_TEMPL_ID], [aIndex+1, fMapsInfo[aIndex].MissionName])
      else
        Result := Format(fTextLib[MISS_TEMPL_ID], [fMapsInfo[aIndex].MissionName, aIndex+1]); //Then order: %s %d
    end else
      //Otherwise just Append (by default MissionName is empty anyway)
      Result := Format(fTextLib[MISS_TEMPL_ID], [aIndex+1]) + fMapsInfo[aIndex].MissionName;
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


// aIndex starts from 0
function TKMCampaign.GetBriefingAudioFile(aIndex: Byte): String;

  function GetBriefingPath(aLocale: AnsiString): string;
  begin
    // map index is 1-based in the file names
    Result := fPath + ShortName + Format('%.2d', [aIndex + 1]) + PathDelim +
                      ShortName + Format('%.2d', [aIndex + 1]) + '.' + UnicodeString(aLocale) + '.mp3';
  end;

begin
  Assert(InRange(aIndex, 0, MAX_CAMP_MAPS - 1));

  Result := GetBriefingPath(gResLocales.UserLocale);

  if not FileExists(Result) then
    Result := GetBriefingPath(gResLocales.FallbackLocale);

  if not FileExists(Result) then
    Result := GetBriefingPath(gResLocales.DefaultLocale);
end;


//When player completes one map we allow to reveal the next one, note that
//player may be replaying previous maps, in that case his progress remains the same
procedure TKMCampaign.SetUnlockedMap(aValue: Byte);
begin
  fUnlockedMap := EnsureRange(aValue, fUnlockedMap, fMapCount - 1);
end;


{ TKMCampaignsScanner }
//aOnAdd - signal that there's new campaign that should be added
//aOnAddDone - signal that campaign has been added
//aOnTerminate - scan was terminated (but could be not complete yet)
//aOnComplete - scan is complete
constructor TKMCampaignsScanner.Create(aOnAdd: TKMCampaignEvent; aOnAddDone, aOnLoadProgress, aOnTerminate, aOnComplete: TNotifyEvent);
begin
  //Thread isn't started until all constructors have run to completion
  //so Create(False) may be put in front as well
  inherited Create(False);

  Assert(Assigned(aOnAdd));

  {$IFDEF DEBUG}
  TThread.NameThreadForDebugging('SavesScanner', ThreadID);
  {$ENDIF}

  fOnAdd := aOnAdd;
  fOnAddDone := aOnAddDone;
  fOnLoadProgress := aOnLoadProgress;
  fOnComplete := aOnComplete;
  OnTerminate := aOnTerminate;
  FreeOnTerminate := False;
end;


procedure TKMCampaignsScanner.Execute;
var
  aPath: string;
  camp: TKMCampaign;
  searchRec: TSearchRec;
begin
  aPath := ExeDir + CAMPAIGNS_FOLDER_NAME + PathDelim;

  if not DirectoryExists(aPath) then Exit;

  gLog.MultithreadLogging := True; // We could log smth while doing saves scan

  try
    try
      FindFirst(aPath + '*', faDirectory, searchRec);
      try
        repeat
          if (searchRec.Name <> '.') and (searchRec.Name <> '..')
            and (searchRec.Attr and faDirectory = faDirectory)
            and FileExists(aPath + searchRec.Name + PathDelim + 'info.cmp') then
          begin
            if SLOW_CAMPAIGN_SCAN then
              Sleep(150);

            camp := TKMCampaign.Create;
            camp.LoadFromPath(aPath + searchRec.Name + PathDelim);
            fOnAdd(camp);
            // Load progress after each loaded campaign to collect info about unlocked maps before showing the campaign in the list
            // Its an overkill, but not a huge one, since everything is done in async thread anyway
            fOnLoadProgress(Self);
            fOnAddDone(Self);
          end;
        until (FindNext(searchRec) <> 0);
      finally
        FindClose(searchRec);
      end;
    finally
      if not Terminated and Assigned(fOnComplete) then
        fOnComplete(Self);
    end;
  finally
    gLog.MultithreadLogging := False;
  end;
end;


end.
