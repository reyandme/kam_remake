unit KM_GameParams;
{$I KaM_Remake.inc}
interface
uses
  KM_Defaults, KM_CommonTypes, KM_GameTypes, KM_MapTypes;

type
  TKMGameModeSetEvent = procedure (aGameMode: TKMGameMode) of object;

  // This class represents some of the game parameters, kind of KM_Game light interface
  // Usefull to split KM_Game and to reduce units dependencies

  TKMGameParams = class
  private
    fMode: TKMGameMode;
    fMissionMode: TKMissionMode;
    fTick: Cardinal;
    fVisibleLayers: TKMMapVisibleLayerSet;

    fName: UnicodeString;
    fMapSimpleCRC: Cardinal; //CRC of map (based on Map and Dat) used in MapEd
    fMapFullCRC: Cardinal; //CRC of map for reporting stats to master server. Also used in MapEd
    fMissionFileRelSP: UnicodeString; //Relative pathname to mission we are playing, so it gets saved to crashreport. SP only, see GetMissionFile.

    fMissionDifficulty: TKMMissionDifficulty;

    fDynamicFOW: Boolean;

    fBlockPointerOperations: Boolean;

    fOnRecalcMapCRC: TEvent;

    // Do not saved fields
    // fMissionFullFilePath is not saved, so its only available when player start game, f.e. in the MapEditor
    // not available on game load, since we could not have the mission files at all, but only sve files
    fMissionFullFilePath: string;

    procedure SetTick(aGameTick: Cardinal);
    procedure SetMode(aGameMode: TKMGameMode);
    function GetMissionFileRel: UnicodeString;
    procedure SetMissionFileSP(const aMissionFileRelSP: UnicodeString);

    function GetDynamicFOW: Boolean;
    procedure SetDynamicFOW(const aDynamicFOW: Boolean);
    procedure SetBlockPointer(aBlockPointer: Boolean);
    function GetMapFullCRC: Cardinal;
    function GetMapSimpleCRC: Cardinal;
  public
    constructor Create(aGameMode: TKMGameMode; aOnRecalcMapCRC: TEvent; out aSetGameTickEvent: TCardinalEvent; out aSetGameModeEvent: TKMGameModeSetEvent;
                       out aSetMissionFileSP: TUnicodeStringEvent; out aSetBlockPointer: TBooleanEvent);
    destructor Destroy; override;

    property Mode: TKMGameMode read fMode;
    property MissionMode: TKMissionMode read fMissionMode write fMissionMode;
    property Tick: Cardinal read fTick;
    property VisibleLayers: TKMMapVisibleLayerSet read fVisibleLayers write fVisibleLayers;

    property Name: UnicodeString read fName write fName;
    property MapSimpleCRC: Cardinal read GetMapSimpleCRC write fMapSimpleCRC;
    property MapFullCRC: Cardinal read GetMapFullCRC write fMapFullCRC;
    property MissionFileRelSP: UnicodeString read fMissionFileRelSP;
    property MissionFileRel: UnicodeString read GetMissionFileRel;
    property MissionDifficulty: TKMMissionDifficulty read fMissionDifficulty write fMissionDifficulty;
    property DynamicFOW: Boolean read GetDynamicFOW write SetDynamicFOW;
    property BlockPointerOperations: Boolean read fBlockPointerOperations;

    property MissionFullFilePath: string read fMissionFullFilePath write fMissionFullFilePath;

    function IsCRCCalculated: Boolean;

    function IsMapEditor: Boolean;
    function IsCampaign: Boolean;
    function IsMultiPlayerOrSpec: Boolean;
    function IsMultiplayerGame: Boolean;
    function IsMultiplayer: Boolean;
    function IsReplay: Boolean;
    function IsReplayOrSpectate: Boolean;
    function IsSingleplayerGame: Boolean;
    function IsSingleplayer: Boolean;
    function IsNormalGame: Boolean;

    function IsTactic: Boolean;
    function IsNormalMission: Boolean;

    function HasMissionDifficulty: Boolean;

    function AllowPointerOperations: Boolean;

    {$IFDEF RUNNER}
    procedure GetGameModeSetEvent(out aSetGameModeEvent: TKMGameModeSetEvent);
    {$ENDIF}
  end;

var
  gGameParams: TKMGameParams;


implementation
uses
  KM_MapUtils;


{ TKMGameParams }
constructor TKMGameParams.Create(aGameMode: TKMGameMode; aOnRecalcMapCRC: TEvent; out aSetGameTickEvent: TCardinalEvent; out aSetGameModeEvent: TKMGameModeSetEvent;
                                 out aSetMissionFileSP: TUnicodeStringEvent; out aSetBlockPointer: TBooleanEvent);
begin
  inherited Create;

  fOnRecalcMapCRC := aOnRecalcMapCRC;

  fVisibleLayers := [mlObjects, mlHouses, mlUnits, mlOverlays];

  fMode := aGameMode;
  fTick := 0;
  fMissionDifficulty := mdNone;
  DynamicFOW := False;

  aSetGameTickEvent := SetTick;
  aSetGameModeEvent := SetMode;
  aSetMissionFileSP := SetMissionFileSP;
  aSetBlockPointer  := SetBlockPointer;

  fBlockPointerOperations := False;

  gGameParams := Self;
end;


destructor TKMGameParams.Destroy;
begin
  gGameParams := nil; //should be destoryed by creator (KM_Game)

  inherited;
end;


{$IFDEF RUNNER}
procedure TKMGameParams.GetGameModeSetEvent(out aSetGameModeEvent: TKMGameModeSetEvent);
begin
  aSetGameModeEvent := SetMode;
end;
{$ENDIF}


function TKMGameParams.GetDynamicFOW: Boolean;
begin
  if Self = nil then Exit(DYNAMIC_FOG_OF_WAR);
  
  Result := fDynamicFOW;
end;


function TKMGameParams.GetMapFullCRC: Cardinal;
begin
  // Lazy load of MapCRC
  if fMapFullCRC = 0 then
    if Assigned(fOnRecalcMapCRC) then
      fOnRecalcMapCRC;

  Result := fMapFullCRC;
end;


function TKMGameParams.GetMapSimpleCRC: Cardinal;
begin
  // Lazy load of MapCRC
  if fMapSimpleCRC = 0 then
    if Assigned(fOnRecalcMapCRC) then
      fOnRecalcMapCRC;

  Result := fMapSimpleCRC;
end;


function TKMGameParams.GetMissionFileRel: UnicodeString;
begin
  Result := GuessMissionPathRel(fMissionFileRelSP, fName, fMapFullCRC, IsMultiplayer);
end;


procedure TKMGameParams.SetBlockPointer(aBlockPointer: Boolean);
begin
  fBlockPointerOperations := aBlockPointer;
end;


procedure TKMGameParams.SetDynamicFOW(const aDynamicFOW: Boolean);
begin
  fDynamicFOW := aDynamicFOW;
end;


procedure TKMGameParams.SetMode(aGameMode: TKMGameMode);
begin
  fMode := aGameMode;
end;


procedure TKMGameParams.SetTick(aGameTick: Cardinal);
begin
  fTick := aGameTick;
end;


procedure TKMGameParams.SetMissionFileSP(const aMissionFileRelSP: UnicodeString);
begin
  fMissionFileRelSP := aMissionFileRelSP;
end;


function TKMGameParams.IsMapEditor: Boolean;
begin
  Result := fMode = gmMapEd;
end;


function TKMGameParams.IsCampaign: Boolean;
begin
  Result := fMode = gmCampaign;
end;


function TKMGameParams.IsCRCCalculated: Boolean;
begin
  Result := (fMapSimpleCRC <> 0) and (fMapFullCRC <> 0);
end;


function TKMGameParams.IsTactic: Boolean;
begin
  Result := fMissionMode = mmTactic;
end;


function TKMGameParams.IsNormalMission: Boolean;
begin
  Result := fMissionMode = mmNormal;
end;


function TKMGameParams.IsMultiplayerGame: Boolean;
begin
  Result := fMode = gmMulti;
end;


// We often need to see if game is MP
function TKMGameParams.IsMultiPlayerOrSpec: Boolean;
begin
  Result := fMode in [gmMulti, gmMultiSpectate];
end;


function TKMGameParams.IsMultiplayer: Boolean;
begin
  Result := fMode in [gmMulti, gmMultiSpectate, gmReplayMulti];
end;


function TKMGameParams.IsSingleplayerGame: Boolean;
begin
  Result := fMode in [gmSingle, gmCampaign];
end;


function TKMGameParams.IsSingleplayer: Boolean;
begin
  Result := fMode in [gmSingle, gmCampaign, gmReplaySingle];
end;


function TKMGameParams.IsNormalGame: Boolean;
begin
  Result := fMode in [gmSingle, gmCampaign, gmMulti];
end;


function TKMGameParams.IsReplay: Boolean;
begin
  Result := fMode in [gmReplaySingle, gmReplayMulti];
end;


function TKMGameParams.IsReplayOrSpectate: Boolean;
begin
  Result := fMode in [gmMultiSpectate, gmReplaySingle, gmReplayMulti];
end;


function TKMGameParams.HasMissionDifficulty: Boolean;
begin
  Result := fMissionDifficulty <> mdNone;
end;


function TKMGameParams.AllowPointerOperations: Boolean;
begin
  Result := IsSingleplayerGame or IsMapEditor or not BlockPointerOperations {or SKIP_POINTER_REF_CHECK};
end;


end.

