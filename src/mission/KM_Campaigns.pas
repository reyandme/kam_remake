unit KM_Campaigns;
{$I KaM_Remake.inc}
interface
uses
  Classes, Generics.Collections, Generics.Defaults, SyncObjs,
  KM_ResTexts, KM_Pics, KM_Maps, KM_MapTypes,
  KM_CampaignClasses,
  KM_CommonTypes, KM_CommonClasses, KM_Points;


const
  MAX_CAMP_MAPS = 64;
  MAX_CAMP_NODES = 64;

type
  TKMBriefingCorner = (bcBottomRight, bcBottomLeft);

  TKMCampaignMapProgressData = record
    Completed: Boolean;
    BestCompletedDifficulty: TKMMissionDifficulty;
  end;

  TKMCampaignMapProgressDataArray = array of TKMCampaignMapProgressData;


  TKMCampaignMapData = record
    TxtInfo: TKMMapTxtInfo;
    MissionName: UnicodeString;
  end;

  TKMCampaignMapDataArray = array of TKMCampaignMapData;

  // Campaign specification, loaded from the Campaign folder (from .cmp, .txt, .libx)
  TKMCampaignSpec = class
  private
    // Saved in CMP
    fCampaignId: TKMCampaignId; // Used to identify the campaign

    fMapCount: Byte;

    fTextLib: TKMTextLibrarySingle;

    fMapsInfo: TKMCampaignMapDataArray; // Missions info (name + TxtInfo)

    function GetIDStr(): UnicodeString;

    procedure SetMapCount(aValue: Byte);
    procedure SetCampaignId(aCampaignId: TKMCampaignId);

    procedure LoadMapsInfo(const aPath: UnicodeString);

    function GetDefaultMissionTitle(aIndex: Byte): UnicodeString;
  public
    Maps: array of record
      Flag: TKMPointW;
      NodeCount: Byte;
      Nodes: array [0 .. MAX_CAMP_NODES - 1] of TKMPointW;
      TextPos: TKMBriefingCorner;
    end;

    constructor Create;
    destructor Destroy; override;

    procedure LoadCMP(const filePath: UnicodeString);
    procedure LoadFromFile(const aPath: UnicodeString); overload;
    procedure LoadFromFile(const aDir, aFileName: UnicodeString); overload;
    procedure SaveToFile(const aFileName: UnicodeString);

    property MissionsCount: Byte read fMapCount write SetMapCount;
    property CampaignId: TKMCampaignId read fCampaignId write SetCampaignId;
    property IdStr: UnicodeString read GetIDStr;
    property MapsInfo: TKMCampaignMapDataArray read fMapsInfo;
    property TextLib: TKMTextLibrarySingle read fTextLib;

    function GetCampaignTitle: UnicodeString;
    function GetCampaignDescription: UnicodeString;
    function GetCampaignMissionTitle(aIndex: Byte): String;
  end;


  // Campaign data (flags, mission info, progress, campaign script data)
  TKMCampaignSavedData = class
  private
    fCriticalSection: TCriticalSection;

    fCampaignSpec: TKMCampaignSpec;

    fCampaignWasOpened: Boolean;
    fUnlockedMission: Integer;
    fMapsProgressData: TKMCampaignMapProgressDataArray; // Map data, saved in campaign progress
    fScriptDataStream: TKMemoryStream;

    fIsScriptDataBase64Compressed: Boolean;

    procedure SetUnlockedMission(aValue: Integer);

    function GetCampaignProgressFilePath(): String;

    procedure Lock;
    procedure Unlock;
  public
    constructor Create(aCampaignSpec: TKMCampaignSpec);
    destructor Destroy; override;

    procedure SaveProgress();
    procedure LoadProgress();

    property CampaignWasOpened: Boolean read fCampaignWasOpened write fCampaignWasOpened;
    property UnlockedMission: Integer read fUnlockedMission write SetUnlockedMission;
    property ScriptDataStream: TKMemoryStream read fScriptDataStream;
    property MapsProgressData: TKMCampaignMapProgressDataArray read fMapsProgressData;

    procedure SetMapsCount(aMapsCount: Integer);
  end;


  TKMCampaign = class
  private
    // Runtime variables
    fPath: UnicodeString;

    fSpec: TKMCampaignSpec;
    fSavedData: TKMCampaignSavedData;

    // Saved in .rxx
    fBackGroundPic: TKMPic;

    procedure LoadFromPath(const aPath: UnicodeString);
    procedure LoadSprites;
    function GetSpec: TKMCampaignSpec;
  public
    constructor Create;
    destructor Destroy; override;

    property Path: UnicodeString read fPath;
    property BackGroundPic: TKMPic read fBackGroundPic write fBackGroundPic;

    property Spec: TKMCampaignSpec read GetSpec;
    property SavedData: TKMCampaignSavedData read fSavedData;

    function GetMissionFile(aIndex: Byte; const aExt: UnicodeString = '.dat'): String;
    function GetMissionName(aIndex: Byte): String;
    function GetMissionTitle(aIndex: Byte): String;
    function GetMissionBriefing(aIndex: Byte): String;
    function GetBriefingAudioFile(aIndex: Byte): String;
    function GetCampaignDataScriptFilePath: UnicodeString;

    procedure UnlockNextMission(aCurrentMission: Word);
    procedure UnlockAllMissions;
  end;


  TKMCampaignEvent = procedure (aCampaign: TKMCampaign) of object;

  TKMCampaignsScanner = class(TThread)
  private
    fOnAdd: TKMCampaignEvent;
    fOnAddDone: TNotifyEvent;
    fOnComplete: TNotifyEvent;
  public
    constructor Create(aOnAdd: TKMCampaignEvent; aOnAddDone, aOnTerminate, aOnComplete: TNotifyEvent);
    procedure Execute; override;
  end;


  TKMCampaignsCollection = class
  private
    fActiveCampaign: TKMCampaign; //Campaign we are playing
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
    procedure ScanTerminate(Sender: TObject);
    procedure ScanComplete(Sender: TObject);

    procedure Clear;
  public
    constructor Create;
    destructor Destroy; override;

    //Initialization
    procedure SaveProgress;

    procedure Lock;
    procedure Unlock;
    procedure TerminateScan;
    procedure Refresh(aOnRefresh, aOnTerminate, aOnComplete: TNotifyEvent);

    //Usage
    property ActiveCampaign: TKMCampaign read fActiveCampaign;
    function Count: Integer;
    property Campaigns[aIndex: Integer]: TKMCampaign read GetCampaign; default;
    function CampaignById(aCampaignId: TKMCampaignId): TKMCampaign; overload;
    function CampaignById(aCampaignIdStr: AnsiString): TKMCampaign; overload;
    function CampaignByIdU(aCampaignIdStr: string): TKMCampaign;
    procedure SetActive(aCampaign: TKMCampaign);

    procedure UnlockAllCampaignsMissions;

    procedure UpdateState;
  end;


implementation
uses
  SysUtils, Math, KromUtils,
  KM_GameParams,
  KM_CampaignUtils, KM_CampaignTypes,
  KM_Resource, KM_ResLocales, KM_ResSprites, KM_ResTypes,
  KM_Log, KM_Defaults, KM_CommonUtils,
  KM_FileIO, KM_IoXML;


const
  CAMPAIGNS_DATA_XML_VERSION = '1.0';

  XML_ROOT_TAG = 'campaignData';


{ TKMCampaignsCollection }
constructor TKMCampaignsCollection.Create;
begin
  inherited;

  fList := TObjectList<TKMCampaign>.Create;

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


procedure TKMCampaignsCollection.SetActive(aCampaign: TKMCampaign);
begin
  fActiveCampaign := aCampaign;
end;


function TKMCampaignsCollection.GetCampaign(aIndex: Integer): TKMCampaign;
begin
  Result := fList[aIndex];
end;


procedure TKMCampaignsCollection.SaveProgress;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Campaigns[I].SavedData.SaveProgress;

  gLog.AddTime('All campaigns progress was saved');
end;


function TKMCampaignsCollection.Count: Integer;
begin
  Result := fList.Count;
end;


function TKMCampaignsCollection.CampaignById(aCampaignId: TKMCampaignId): TKMCampaign;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Count - 1 do
    if (Campaigns[I].Spec.CampaignId.ID = aCampaignId.ID) then
      Exit(Campaigns[I]);
end;


function TKMCampaignsCollection.CampaignById(aCampaignIdStr: AnsiString): TKMCampaign;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Count - 1 do
    if (Campaigns[I].Spec.CampaignId.ID = aCampaignIdStr) then
      Exit(Campaigns[I]);
end;


function TKMCampaignsCollection.CampaignByIdU(aCampaignIdStr: string): TKMCampaign;
begin
  Result := CampaignById(AnsiString(aCampaignIdStr));
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

    // Keep the campaigns properly sorted
    fList.Sort(TComparer<TKMCampaign>.Construct(
      function (const aLeft, aRight: TKMCampaign): Integer
      var
        sLeft, sRight: string;
      begin
        sLeft := aLeft.Spec.IdStr;
        sRight := aRight.Spec.IdStr;

        // Add extra sorting key to get TSK and TPR on top
        if sLeft = 'TSK' then sLeft := '1' + sLeft else
        if sLeft = 'TPR' then sLeft := '2' + sLeft else
          sLeft := '3' + sLeft;
        if sRight = 'TSK' then sRight := '1' + sRight else
        if sRight = 'TPR' then sRight := '2' + sRight else
          sRight := '3' + sRight;

        Result := CompareStr(sLeft, sRight);
      end));
  finally
    Unlock;
  end;
end;


procedure TKMCampaignsCollection.CampaignAddDone(Sender: TObject);
begin
  Lock;
  try
    fUpdateNeeded := True; //Next time the GUI thread calls UpdateState we will run fOnRefresh
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


// Refresh campaigns list
procedure TKMCampaignsCollection.Refresh(aOnRefresh, aOnTerminate, aOnComplete: TNotifyEvent);
begin
  // Terminate previous Scanner (e.g. on language change)
  TerminateScan;
  Clear;

  fOnRefresh := aOnRefresh;
  fOnComplete := aOnComplete;
  fOnTerminate := aOnTerminate;

  // Scanner will launch upon create automatically
  fScanning := True;
  fScanner := TKMCampaignsScanner.Create(CampaignAdd, CampaignAddDone, ScanTerminate, ScanComplete);
end;


procedure TKMCampaignsCollection.UpdateState;
begin
  if Self = nil then Exit;

  if not fUpdateNeeded then Exit;

  if Assigned(fOnRefresh) then
    fOnRefresh(Self);

  fUpdateNeeded := False;
end;


{ TKMCampaignSpec }
constructor TKMCampaignSpec.Create;
begin
  inherited;
end;


destructor TKMCampaignSpec.Destroy;
begin
  FreeAndNil(fTextLib);

  for var I := 0 to High(fMapsInfo) do
    FreeAndNil(fMapsInfo[I].TxtInfo);

  inherited;
end;


procedure TKMCampaignSpec.SetMapCount(aValue: Byte);
begin
  fMapCount := aValue;
  SetLength(Maps, fMapCount);
  SetLength(fMapsInfo, fMapCount);
end;


procedure TKMCampaignSpec.SetCampaignId(aCampaignId: TKMCampaignId);
begin
  fCampaignId := aCampaignId;
end;


procedure TKMCampaignSpec.LoadCMP(const filePath: UnicodeString);
var
  M: TKMemoryStream;
  cmp: TBytes;
begin
  if not FileExists(filePath) then Exit;

  M := TKMemoryStreamBinary.Create;
  M.LoadFromFile(filePath);

  //Convert old AnsiString into new [0..2] Byte format
  M.ReadBytes(cmp);
  Assert(Length(cmp) = 3);

  var campIDStr := WideChar(cmp[0]) + WideChar(cmp[1]) + WideChar(cmp[2]);

  fCampaignId := TKMCampaignId.Create(AnsiString(campIDStr));

  M.Read(fMapCount);
  SetMapCount(fMapCount); //Update array's sizes

  for var I := 0 to fMapCount - 1 do
  begin
    M.Read(Maps[I].Flag);
    M.Read(Maps[I].NodeCount);
    for var K := 0 to Maps[I].NodeCount - 1 do
      M.Read(Maps[I].Nodes[K]);
    M.Read(Maps[I].TextPos, SizeOf(TKMBriefingCorner));
  end;

  M.Free;
end;


procedure TKMCampaignSpec.LoadFromFile(const aPath: UnicodeString);
begin
  LoadFromFile(ExtractFilePath(aPath), ExtractFileName(aPath));
end;


//Load campaign info from *.cmp file
//It should be private, but it is used by CampaignBuilder
procedure TKMCampaignSpec.LoadFromFile(const aDir, aFileName: UnicodeString);
var
  filePath: String;
begin
  filePath := aDir + aFileName;
  if not FileExists(filePath) then Exit;

  LoadCMP(filePath);

  FreeAndNil(fTextLib);
  fTextLib := TKMTextLibrarySingle.Create;
  fTextLib.LoadLocale(aDir + 'text.%s.libx');

  LoadMapsInfo(aDir);
end;


procedure TKMCampaignSpec.LoadMapsInfo(const aPath: UnicodeString);
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

      fMapsInfo[I].TxtInfo.LoadTXTInfo(TKMCampaignUtils.GetMissionFile(aPath, IdStr, I, '.txt'));

      fMapsInfo[I].MissionName := '';

      textMission.Clear; // Better clear object, than rectreate it for every map
      // Make a full scan for Libx top ID, to allow unordered Libx ID's by not carefull campaign makers
      textMission.LoadLocale(TKMCampaignUtils.GetMissionFile(aPath, IdStr, I, '.%s.libx'));

      if textMission.HasText(MISSION_NAME_LIBX_ID) then
        fMapsInfo[I].MissionName := StringReplace(textMission[MISSION_NAME_LIBX_ID], '|', ' ', [rfReplaceAll]); //Replace | with space
    end;
  finally
    FreeAndNil(textMission);
  end;
end;


procedure TKMCampaignSpec.SaveToFile(const aFileName: UnicodeString);
var
  M: TKMemoryStream;
  I, K: Integer;
begin
  Assert(aFileName <> '');

  M := TKMemoryStreamBinary.Create;
  fCampaignId.Save(M);
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


function TKMCampaignSpec.GetCampaignTitle: UnicodeString;
begin
  Result := fTextLib[0];
end;


function TKMCampaignSpec.GetCampaignDescription: UnicodeString;
begin
  Result := fTextLib[2];
end;


function TKMCampaignSpec.GetDefaultMissionTitle(aIndex: Byte): UnicodeString;
begin
  if fMapsInfo[aIndex].MissionName <> '' then
    Result := fMapsInfo[aIndex].MissionName
  else
    //Have nothing - use default mission name
    //Otherwise just Append (by default MissionName is empty anyway)
    Result := Format(gResTexts[TX_GAME_MISSION], [aIndex + 1]) + fMapsInfo[aIndex].MissionName;
end;


function TKMCampaignSpec.GetIDStr(): UnicodeString;
begin
  Result := UnicodeString(fCampaignId.ID);
end;


function TKMCampaignSpec.GetCampaignMissionTitle(aIndex: Byte): String;
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
        Result := Format(fTextLib[MISS_TEMPL_ID], [aIndex + 1, fMapsInfo[aIndex].MissionName])
      else
        Result := Format(fTextLib[MISS_TEMPL_ID], [fMapsInfo[aIndex].MissionName, aIndex+1]); //Then order: %s %d
    end else
      //Otherwise just Append (by default MissionName is empty anyway)
      Result := Format(fTextLib[MISS_TEMPL_ID], [aIndex + 1]) + fMapsInfo[aIndex].MissionName;
  end
  else
    Result := GetDefaultMissionTitle(aIndex);
end;



{ TKMCampaignSavedData }
constructor TKMCampaignSavedData.Create(aCampaignSpec: TKMCampaignSpec);
begin
  inherited Create;

  fCampaignSpec := aCampaignSpec;
  fScriptDataStream := TKMemoryStreamBinary.Create;
  fUnlockedMission := 0;

  // Default value
  fIsScriptDataBase64Compressed := True;

  fCriticalSection := TCriticalSection.Create;
end;


destructor TKMCampaignSavedData.Destroy;
begin
  FreeAndNil(fCriticalSection);

  FreeAndNil(fScriptDataStream);
  fCampaignSpec := nil;

  inherited;
end;


function TKMCampaignSavedData.GetCampaignProgressFilePath(): String;
begin
  Result := ExeDir + SAVES_CMP_FOLDER_NAME + PathDelim + fCampaignSpec.IdStr + '.xml';
end;


procedure TKMCampaignSavedData.SaveProgress();
var
  I: Integer;
  filePath: UnicodeString;
  newXML: TKMXMLDocument;
  nRoot, nCamp, nMissions, nMission, nScriptData: TKMXmlNode;
begin
  if Self = nil then Exit;

  filePath := GetCampaignProgressFilePath;

  // Makes the folder incase it is missing
  ForceDirectories(ExtractFilePath(filePath));

  gLog.AddTime('Saving ' + fCampaignSpec.IdStr + ' campaign data to file ' + filePath + '''');

  // Save campaign data to XML
  newXML := TKMXMLDocument.Create(XML_ROOT_TAG);
  try
    nRoot := newXML.Root;

    nRoot.SetAttribute('version', CAMPAIGNS_DATA_XML_VERSION);

    nCamp := nRoot.AddOrFindChild('campaign');
    nCamp.SetAttribute('id', string(fCampaignSpec.CampaignId.ID));
    nCamp.SetAttribute('name', fCampaignSpec.GetCampaignTitle);

    nCamp.SetAttribute('wasOpened', fCampaignWasOpened);

    nCamp.SetAttribute('unlockedMission', fUnlockedMission);
    nMissions := nCamp.AddOrFindChild('missions');
    nMissions.Attributes['count'] := fCampaignSpec.MissionsCount;

    for I := 0 to fCampaignSpec.MissionsCount - 1 do
    begin
      nMission := nMissions.AddOrFindChild('mission' + IntToStr(I));
      nMission.SetAttribute('title', fCampaignSpec.GetCampaignMissionTitle(I));
      nMission.SetAttribute('completed', fMapsProgressData[I].Completed);
      nMission.SetAttribute('bestCompletedDifficulty', Ord(fMapsProgressData[I].BestCompletedDifficulty));
    end;

    nScriptData := nCamp.AddOrFindChild('scriptData');
    nScriptData.SetAttribute('compressed', fIsScriptDataBase64Compressed);

    if fIsScriptDataBase64Compressed then
      nScriptData.Attributes['data'] := fScriptDataStream.ToBase64Compressed
    else
      nScriptData.Attributes['data'] := fScriptDataStream.ToBase64;

    Lock;
    try
      if SLOW_CAMP_PROGRESS_SAVE_LOAD then
        Sleep(2000);

      newXML.SaveToFile(filePath);
    finally
      Unlock;
    end;
  finally
    newXML.Free;
  end;

  gLog.AddTime(fCampaignSpec.IdStr + ' progress saved to ');
end;


procedure TKMCampaignSavedData.LoadProgress();
var
  filePath: UnicodeString;
  campId: AnsiString;
  difficultyInt: Integer;
  newXML: TKMXMLDocument;
  nCamp, nMissions, nMission, nScriptData: TKMXmlNode;
begin
  filePath := GetCampaignProgressFilePath;

  if not FileExists(filePath) then
  begin
    gLog.AddTime('No file of campaign progress found: ' + filePath);
    Exit;
  end;

  ForceDirectories(ExtractFilePath(filePath));

  gLog.AddTime('Loading campaign from: ' + filePath);

  //Load campaign progress data from XML
  newXML := TKMXMLDocument.Create(XML_ROOT_TAG);
  try
    Lock;
    try
      newXML.LoadFromFile(filePath, XML_ROOT_TAG);
    finally
      Unlock;
    end;

    nCamp := newXML.Root.AddOrFindChild('campaign');

    if SLOW_CAMP_PROGRESS_SAVE_LOAD then
      Sleep(2000);

    campId := AnsiString(nCamp.Attributes['id'].AsString(''));

    if not TKMCampaignId.isIdValid(campId) or (campId <> fCampaignSpec.CampaignId.ID) then
    begin
      gLog.AddTime('Error loading CampaignID:');
      gLog.AddTime('CampaignID expected: "' + string(fCampaignSpec.CampaignId.ID) + '". Actual: "' + string(campId) + '"');
      Exit;
    end;

    fCampaignWasOpened := nCamp.Attributes['wasOpened'].AsBoolean(False);

    UnlockedMission := nCamp.Attributes['unlockedMission'].AsInteger(0);

    nMissions := nCamp.AddOrFindChild('missions');
    var missionsCnt := nMissions.Attributes['count'].AsInteger(0);
    for var I := 0 to Min(missionsCnt - 1, fCampaignSpec.MissionsCount - 1) do
    begin
      nMission := nMissions.AddOrFindChild('mission' + IntToStr(I));
      fMapsProgressData[I].Completed := nMission.Attributes['completed'].AsBoolean(False);
      difficultyInt := nMission.Attributes['bestCompletedDifficulty'].AsInteger(Ord(mdNone));
      difficultyInt := EnsureRange(difficultyInt, Ord(Low(TKMMissionDifficulty)), Ord(High(TKMMissionDifficulty)));
      fMapsProgressData[I].BestCompletedDifficulty := TKMMissionDifficulty(difficultyInt);
    end;

    nScriptData := nCamp.AddOrFindChild('scriptData');

    fIsScriptDataBase64Compressed := IfThenB(ALLOW_CAMP_SCRIPT_DATA_UNCOMPRESSED, nScriptData.Attributes['compressed'].AsBoolean(True), True);

    fScriptDataStream.Clear;

    var base64DataStr := nScriptData.Attributes['data'].AsString('');
    try
      if fIsScriptDataBase64Compressed then
        fScriptDataStream.LoadFromBase64Compressed(base64DataStr)
      else
        fScriptDataStream.LoadFromBase64(base64DataStr);
    except
      on E: Exception do
      begin
        // Just log an exception
        gLog.AddTime('Error loading script data from base64 string: "' + E.Message + '" base64string:');
        gLog.AddNoTime(base64DataStr);
      end;
    end;
  finally
    newXML.Free;
  end;

  gLog.AddTime('Campaign Progress Loaded: ' + fCampaignSpec.IdStr);
end;


//When player completes one map we allow to reveal the next one, note that
//player may be replaying previous maps, in that case his progress remains the same
procedure TKMCampaignSavedData.SetUnlockedMission(aValue: Integer);
begin
  fUnlockedMission := EnsureRange(aValue, fUnlockedMission, Max(0, fCampaignSpec.MissionsCount - 1));
end;


procedure TKMCampaignSavedData.SetMapsCount(aMapsCount: Integer);
begin
  SetLength(fMapsProgressData, aMapsCount);
end;


procedure TKMCampaignSavedData.Lock;
begin
  fCriticalSection.Enter;
end;


procedure TKMCampaignSavedData.Unlock;
begin
  fCriticalSection.Leave;
end;


{ TKMCampaign }
constructor TKMCampaign.Create;
begin
  inherited;

  fSpec := TKMCampaignSpec.Create;
  fSavedData := TKMCampaignSavedData.Create(fSpec);

  // 1st map is always unlocked to allow to start campaign
  fSavedData.UnlockedMission := 0;
  fSavedData.CampaignWasOpened := False;
end;


destructor TKMCampaign.Destroy;
//var
//  I: Integer;
begin
  // Free background texture
  if fBackGroundPic.ID <> 0 then
    gRes.Sprites[rxCustom].DeleteSpriteTexture(fBackGroundPic.ID);


  FreeAndNil(fSavedData);
  FreeAndNil(fSpec);

  inherited;
end;


function TKMCampaign.GetCampaignDataScriptFilePath: UnicodeString;
begin
  Result := fPath + CAMPAIGN_DATA_SCRIPT_FILENAME + EXT_FILE_SCRIPT_DOT;
end;


procedure TKMCampaign.LoadSprites;
var
  SP: TKMSpritePack;
  firstSpriteIndex: Word;
begin
  if gRes.Sprites  = nil then Exit;
  
  gLog.AddNoTime('Loading campaign images.rxx for ' + fSpec.IdStr);

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

  var t1 := TimeGetUsec;
  fSpec.LoadFromFile(fPath, 'info.cmp');
  var t2 := TimeSinceUSec(t1);
  t1 := TimeGetUsec;

  fSavedData.SetMapsCount(fSpec.MissionsCount);

  // We load Sprites separately by scanner
//  LoadSprites;

  var t3 := TimeSinceUSec(t1);

  gLog.AddTime('Load from ' + aPath);
  gLog.AddTime('fSpec.LoadFromFile = ' + IntToStr(t2) + ' LoadSprites = ' + IntToStr(t3));

  if UNLOCK_CAMPAIGN_MAPS then // Unlock more maps for debug
    UnlockAllMissions();
end;


procedure TKMCampaign.UnlockAllMissions;
begin
  fSavedData.UnlockedMission := fSpec.MissionsCount - 1;
end;


procedure TKMCampaign.UnlockNextMission(aCurrentMission: Word);
begin
  if Self = nil then Exit;

  fSavedData.UnlockedMission := aCurrentMission + 1;
  fSavedData.MapsProgressData[aCurrentMission].Completed := True;
  //Update BestDifficulty if we won harder game
  if Ord(fSavedData.MapsProgressData[aCurrentMission].BestCompletedDifficulty) < Ord(gGameParams.MissionDifficulty)  then
    fSavedData.MapsProgressData[aCurrentMission].BestCompletedDifficulty := gGameParams.MissionDifficulty;
end;


function TKMCampaign.GetSpec: TKMCampaignSpec;
begin
  if Self = nil then Exit(nil);

  Result := fSpec;
end;


function TKMCampaign.GetMissionFile(aIndex: Byte; const aExt: UnicodeString = '.dat'): String;
begin
  Result := TKMCampaignUtils.GetMissionFile(fPath, fSpec.IdStr, aIndex, aExt);
end;


function TKMCampaign.GetMissionName(aIndex: Byte): String;
begin
  Result := TKMCampaignUtils.GetMissionName(fSpec.IdStr, aIndex);
end;


function TKMCampaign.GetMissionTitle(aIndex: Byte): String;
begin
  if fSpec.TextLib[1] <> '' then
    Result := Format(fSpec.TextLib[1], [aIndex+1]) //Save it for Legacy support
  else
    Result := fSpec.GetDefaultMissionTitle(aIndex);
end;


//Mission texts of original campaigns are available in all languages,
//custom campaigns are unlikely to have more texts in more than 1-2 languages
function TKMCampaign.GetMissionBriefing(aIndex: Byte): String;
begin
  Result := fSpec.TextLib[10 + aIndex];
end;


// aIndex starts from 0
function TKMCampaign.GetBriefingAudioFile(aIndex: Byte): String;

  function GetBriefingPath(aLocale: AnsiString): string;
  begin
    // map index is 1-based in the file names
    Result := fPath + fSpec.IdStr + Format('%.2d', [aIndex + 1]) + PathDelim +
                      fSpec.IdStr + Format('%.2d', [aIndex + 1]) + '.' + UnicodeString(aLocale) + '.mp3';
  end;

begin
  Assert(InRange(aIndex, 0, MAX_CAMP_MAPS - 1));

  Result := GetBriefingPath(gResLocales.UserLocale);

  if not FileExists(Result) then
    Result := GetBriefingPath(gResLocales.FallbackLocale);

  if not FileExists(Result) then
    Result := GetBriefingPath(gResLocales.DefaultLocale);
end;



{ TKMCampaignsScanner }
//aOnAdd - signal that there's new campaign that should be added
//aOnAddDone - signal that campaign has been added
//aOnTerminate - scan was terminated (but could be not complete yet)
//aOnComplete - scan is complete
constructor TKMCampaignsScanner.Create(aOnAdd: TKMCampaignEvent; aOnAddDone, aOnTerminate, aOnComplete: TNotifyEvent);
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
  fOnComplete := aOnComplete;
  OnTerminate := aOnTerminate;
  FreeOnTerminate := False;
end;


procedure TKMCampaignsScanner.Execute;
var
  aPath: string;
  camp: TKMCampaign;
  searchRec: TSearchRec;
  campaigns: TObjectList<TKMCampaign>;
begin
  aPath := ExeDir + CAMPAIGNS_FOLDER_NAME + PathDelim;

  if not DirectoryExists(aPath) then Exit;

  var t1 := TimeGet;
  // Set OwnObjects to False, since we don't want to Free Campaign objects on the list destruction
  campaigns := TObjectList<TKMCampaign>.Create(False);
  try
    FindFirst(aPath + '*', faDirectory, searchRec);
    try
      repeat
        if (searchRec.Name <> '.') and (searchRec.Name <> '..')
          and (searchRec.Attr and faDirectory = faDirectory)
          and FileExists(aPath + searchRec.Name + PathDelim + 'info.cmp') then
        begin
          if SLOW_CAMPAIGN_SCAN then
            Sleep(2000);

          camp := TKMCampaign.Create;
          camp.LoadFromPath(aPath + searchRec.Name + PathDelim);
          fOnAdd(camp);
          // @Rey: This can be greatly improved:
          //     campaign scan needs to be much-MUCH faster. There's no real need to load all the campaign data (including sprites and etc) on scan.
          //     What is needed for the main menu is just the localized name and optionally missions counts. Everything else (that takes literal seconds on first
          //     scan) needs to be loaded async by demand. This will cut the scan time by x50 or more, from several seconds down to 100ms
          // @Krom
          // Sprites are loaded after campaign spec is loaded. It seems good enough for now
          camp.SavedData.LoadProgress;
          fOnAddDone(Self);

          // Add campaign to the list to load sprites afterwards
          campaigns.Add(camp);
        end;
      until (FindNext(searchRec) <> 0) or Terminated;
    finally
      FindClose(searchRec);
    end;

    // Load sprites afterwards, to make load faster
    for var I := 0 to campaigns.Count - 1 do
      campaigns[I].LoadSprites;

  finally
    campaigns.Free;
    if not Terminated and Assigned(fOnComplete) then
      fOnComplete(Self);
  end;

  gLog.AddTime('[Campaigns scanner] Campaigns were loaded in: ' + IntToStr(TimeSince(t1)) + 'ms');
end;


end.
