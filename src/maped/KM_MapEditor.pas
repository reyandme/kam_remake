unit KM_MapEditor;
{$I KaM_Remake.inc}
interface
uses
  Classes,
  Controls,
  KM_RenderPool, KM_TerrainPainter, KM_TerrainDeposits, KM_TerrainSelection,
  KM_CommonTypes, KM_CommonClasses, KM_Defaults, KM_Points, KM_MapEditorHistory,
  KM_MapEdTypes, KM_ResTexts, KM_HandEntity, KM_AITypes;


type
  //Collection of map editing classes and map editor specific data
  TKMMapEditor = class
  private
    fLandMapEd: TKMMapEdLand;
    fMainLandMapEd: PKMMapEdLand;
    fIsNewMap: Boolean;
    fSavedMapIsPlayable: Boolean; // Saved map is playable if there is at elast 1 enabled human loc with assets
    fTerrainPainter: TKMTerrainPainter;
    fHistory: TKMMapEditorHistory;
    fDeposits: TKMDeposits;
    fSelection: TKMSelection;
    fRevealers: array [0..MAX_HANDS-1] of TKMPointTagList;
    fVisibleLayers: TKMMapEdVisibleLayerSet;
    //When you load a map script/libx/wav/etc. files are "attached" then copied when
    //saving if the path is different
    fAttachedFiles: array of UnicodeString;

    fLastErasedObjectLoc: TKMPoint;
    fLastRemoveTxID: Integer;

    function GetRevealer(aIndex: Byte): TKMPointTagList;
    procedure ProceedRoadCursorMode;
    procedure ProceedUnitsCursorMode;
    procedure ProceedEraseCursorMode;
    procedure UpdateField;
    function EraseTerrainObject(var aRemoveTxID: Integer): Boolean;
    procedure EraseObject(aEraseAll: Boolean);
    function ChangeEntityOwner(aEntity: TKMHandEntity; aOwner: TKMHandID): Boolean;
    procedure ChangeOwner(aChangeOwnerForAll: Boolean);
    procedure PaintDefences(aLayer: TKMPaintLayer);
    procedure PaintRevealFOW(aLayer: TKMPaintLayer);
    procedure PaintCenterScreen(aLayer: TKMPaintLayer);
    procedure PaintAIStart(aLayer: TKMPaintLayer);

    procedure UpdateMapEdCursorParams(aMode: TKMChangeDefenceTypeMode; aDirInc: Integer = 1);  //change units and def pos direction

    procedure AddDefenceMarker(const aLoc: TKMPoint);

    function GetCheckpointObjectsStr(removeTxID: Integer = TX_WORD_OBJECT): string; overload;
    function GetCheckpointObjectsStr(aCell: TKMPoint; removeTxID: Integer = TX_WORD_OBJECT): string; overload;
    function GetHistory: TKMMapEditorHistory;

    procedure UpdateSavedInfo;
  public
    LandMapEd: PKMMapEdLand;

    MissionDefSavePath: UnicodeString;

    ActiveMarker: TKMMapEdMarker;

    ResizeMapRect: TKMRect;
    RevealAll: array [0..MAX_HANDS-1] of Boolean;
    DefaultHuman: TKMHandID;
    PlayerHuman: array [0..MAX_HANDS - 1] of Boolean;
    PlayerClassicAI: array [0..MAX_HANDS - 1] of Boolean;
    PlayerAdvancedAI: array [0..MAX_HANDS - 1] of Boolean;

    SavedPlayableLocs: array [0..MAX_HANDS - 1] of Boolean;

    OnEyedropper: TIntegerEvent;

    constructor Create(aNewMap: Boolean; aTerrainPainter: TKMTerrainPainter; aOnHistoryUndoRedo, aOnHistoryAddCheckpoint: TEvent);
    destructor Destroy; override;

    procedure AfterCreated;

    procedure SetMainLandMapEd;

    property MainLandMapEd: PKMMapEdLand read fMainLandMapEd; //readonly

    property Deposits: TKMDeposits read fDeposits;
    property VisibleLayers: TKMMapEdVisibleLayerSet read fVisibleLayers write fVisibleLayers;
    property Selection: TKMSelection read fSelection;
    property Revealers[aIndex: Byte]: TKMPointTagList read GetRevealer;
    property History: TKMMapEditorHistory read GetHistory write fHistory;

    property IsNewMap: Boolean read fIsNewMap;
    property SavedMapIsPlayable: Boolean read fSavedMapIsPlayable;
    procedure ValidatePlayerTypes;

    function CanHaveClassicAI: Boolean;
    function CanHaveAdvancedAI: Boolean;
    function OnlyAdvancedAIHand(aHandId: TKMHandID): Boolean;

    procedure DetermineGroupFormationAndDir(const aLoc: TKMPoint; aGroupType: TKMGroupType;
                                            out aFormation: TKMFormation; out aDir: TKMDirection);

    procedure ApplyAIMultiplayerSetup(aHandID: TKMHandID);

    procedure DetectAttachedFiles(const aMissionFile: UnicodeString);
    procedure SaveAttachements(const aMissionFile: UnicodeString);
    function HitTest(X,Y: Integer): TKMMapEdMarker;
    function HumanCount: Integer;
    procedure MouseDown(Button: TMouseButton);
    procedure MouseMove;
    procedure MouseUp(Button: TMouseButton; aOverMap: Boolean);
    procedure MouseWheel(Shift: TShiftState; WheelSteps: Integer; X,Y: Integer);
    procedure UpdateState;
    procedure UpdateStateIdle;
    procedure Paint(aLayer: TKMPaintLayer; const aClipRect: TKMRect);

    procedure Reset;

    procedure DeletePlayer(aIndex: TKMHandID);
  end;


implementation
uses
  SysUtils, StrUtils, Math,
  KM_TerrainTypes, KM_Terrain, KM_FileIO,
  KM_AIDefensePos,
  KM_Units, KM_UnitGroup, KM_Houses, KM_HouseCollection,
  KM_GameParams, KM_Cursor, KM_ResMapElements, KM_ResHouses, KM_Resource, KM_ResUnits,
  KM_RenderAux, KM_RenderGameAux,
  KM_Hand, KM_HandsCollection, KM_HandEntityHelper, KM_HandTypes,
  KM_CommonUtils, KM_RenderDebug,
  KM_UnitGroupTypes,
  KM_ResTypes;

//defines default defence position radius for static AI 
const
  DEFAULT_DEFENCE_POSITION_RADIUS = 20;


{ TKMMapEditor }
constructor TKMMapEditor.Create(aNewMap: Boolean; aTerrainPainter: TKMTerrainPainter; aOnHistoryUndoRedo, aOnHistoryAddCheckpoint: TEvent);
var
  I: Integer;
begin
  inherited Create;

  SetMainLandMapEd;
  fMainLandMapEd := @fLandMapEd;

  MissionDefSavePath := '';

  fVisibleLayers := [melDeposits];
  fIsNewMap := aNewMap;

  FillChar(LandMapEd^[1,1], SizeOf(LandMapEd^[1,1])*MAX_MAP_SIZE*MAX_MAP_SIZE, #0);

  for I := 0 to MAX_HANDS - 1 do
  begin
    PlayerHuman[I] := True;
    PlayerClassicAI[I] := True;
    PlayerAdvancedAI[I] := True;
  end;

  fDeposits := TKMDeposits.Create;

  fTerrainPainter := aTerrainPainter;
  fSelection := TKMSelection.Create(fTerrainPainter);

  fHistory := TKMMapEditorHistory.Create;
  fHistory.OnUndoRedo := aOnHistoryUndoRedo;
  fHistory.OnAddCheckpoint := aOnHistoryAddCheckpoint;

  ResizeMapRect := KMRECT_ZERO;

  for I := Low(fRevealers) to High(fRevealers) do
    fRevealers[I] := TKMPointTagList.Create;
end;


destructor TKMMapEditor.Destroy;
var
  I: Integer;
begin
  FreeAndNil(fHistory);
  FreeAndNil(fDeposits);
  FreeAndNil(fSelection);

  for I := Low(fRevealers) to High(fRevealers) do
    fRevealers[I].Free;

  inherited;
end;


function TKMMapEditor.GetRevealer(aIndex: Byte): TKMPointTagList;
begin
  Result := fRevealers[aIndex];
end;


procedure TKMMapEditor.ApplyAIMultiplayerSetup(aHandID: TKMHandID);
begin
  PlayerClassicAI[aHandID] := True;
  PlayerAdvancedAI[aHandID] := True;
  gHands[aHandID].AI.General.DefencePositions.Clear;
  gHands[aHandID].AI.General.Attacks.Clear;
  //Setup Multiplayer setup, for ClassicAI. Anyway we will consider Old/New AI on the game start
  gHands[aHandID].AI.Setup.ApplyMultiplayerSetup(False);
end;


procedure TKMMapEditor.DetectAttachedFiles(const aMissionFile: UnicodeString);

  procedure AddAttachment(var aAttachCnt: Integer; const aFileName: UnicodeString);
  begin
    if aAttachCnt >= Length(fAttachedFiles) then
      SetLength(fAttachedFiles, aAttachCnt + 8);

    fAttachedFiles[aAttachCnt] := aFileName;
    Inc(aAttachCnt);
  end;

var
  searchRec: TSearchRec;
  missionScriptFileName, missionName, recExt: UnicodeString;
  hasScript: Boolean;
  attachCnt: Integer;
begin
  hasScript := False;
  attachCnt := 0;
  SetLength(fAttachedFiles, 8);
  MissionDefSavePath := aMissionFile;
  missionName := ChangeFileExt(ExtractFileName(aMissionFile), '');
  FindFirst(ChangeFileExt(aMissionFile, '.*'), faAnyFile - faDirectory, searchRec);
  try
    repeat
      if (searchRec.Name <> '') and (searchRec.Name <> '.') and (searchRec.Name <> '..') then
      begin
        //Can't use ExtractFileExt because we want .eng.libx not .libx
        recExt := RightStr(searchRec.Name, Length(searchRec.Name) - Length(missionName));
        if (LowerCase(recExt) = '.map')
          or (LowerCase(recExt) = '.dat')
          or (LowerCase(recExt) = '.mi' ) then
          Continue;

        if LowerCase(recExt) = EXT_FILE_SCRIPT_DOT then
          hasScript := True;

        AddAttachment(attachCnt, ExtractFilePath(aMissionFile) + searchRec.Name);
      end;
    until (FindNext(searchRec) <> 0);
  finally
    FindClose(searchRec);
  end;

  //Add all scripts if we find main script
  if hasScript then
  begin
    missionScriptFileName := missionName + EXT_FILE_SCRIPT_DOT;
    FindFirst(ExtractFilePath(aMissionFile) + '*' + EXT_FILE_SCRIPT_DOT, faAnyFile - faDirectory, searchRec);
    try
      repeat
        if (searchRec.Name <> '.') and (searchRec.Name <> '..')
          and (searchRec.Name <> missionScriptFileName) then
          AddAttachment(attachCnt, ExtractFilePath(aMissionFile) + searchRec.Name);
      until (FindNext(searchRec) <> 0);
    finally
      FindClose(searchRec);
    end;
  end;

  SetLength(fAttachedFiles, attachCnt);
end;


procedure TKMMapEditor.ValidatePlayerTypes;
var
  I: Integer;
  hasAssets, hasDefault, noAssetsAtAll: Boolean;
begin
  noAssetsAtAll := True;
  hasDefault := False;

  try
    for I := 0 to gHands.Count - 1 do
    begin
      hasAssets := gHands[I].HasAssets;
      noAssetsAtAll := noAssetsAtAll and not hasAssets;
      hasDefault := hasDefault or (hasAssets and (DefaultHuman = I));
    end;
    //No default human player chosen
    if not hasDefault then
    begin
      for I := 0 to gHands.Count - 1 do
      begin
        if gHands[I].HasAssets and PlayerHuman[I] then
        begin
          DefaultHuman := I;
          hasDefault := True;
          Exit;
        end;
      end;
      //Still no default is set (no humans)
      //Find first hand and set it as enabled for humans and as default
      if not hasDefault then
        for I := 0 to gHands.Count - 1 do
          if gHands[I].HasAssets then
          begin
            PlayerHuman[I] := True;
            DefaultHuman := I;
            hasDefault := True;
            Exit;
          end;
    end;
  finally
    Assert(noAssetsAtAll or hasDefault, 'Can not set default human');
  end;
end;


procedure TKMMapEditor.UpdateSavedInfo;
var
  I: Integer;
begin
  fSavedMapIsPlayable := False;

  for I := 0 to MAX_HANDS - 1 do
  begin
    SavedPlayableLocs[I] := PlayerHuman[I] and gHands[I].HasAssets;
    fSavedMapIsPlayable := fSavedMapIsPlayable or SavedPlayableLocs[I];
  end;

  ValidatePlayerTypes;
end;


procedure TKMMapEditor.AfterCreated;
begin
  UpdateSavedInfo;
end;


procedure TKMMapEditor.SetMainLandMapEd;
begin
  if Self = nil then Exit;

  LandMapEd := @fLandMapEd;
end;


procedure TKMMapEditor.SaveAttachements(const aMissionFile: UnicodeString);
var
  I: Integer;
  missionPath, missionNewName, missionOldName, destPath: UnicodeString;
begin
  if not fIsNewMap then
  begin
    missionPath := ExtractFilePath(aMissionFile);
    missionNewName := GetFileDirName(aMissionFile);
    missionOldName := '';

    //Copy all attachments files into new folder
    for I := 0 to High(fAttachedFiles) do
      if FileExists(fAttachedFiles[I]) then
      begin
        destPath := missionPath + ExtractFileName(fAttachedFiles[I]);

        //Get MissionOldName from first attachment file
        if missionOldName = '' then
          missionOldName := GetFileDirName(fAttachedFiles[I]);

        if not SameFileName(destPath, fAttachedFiles[I]) then
        begin
          if FileExists(destPath) then
            DeleteFile(destPath);
          KMCopyFile(fAttachedFiles[I], destPath);
        end;
      end;

    // Rename all files inside new saved map folder
    KMRenameFilesInFolder(missionPath, missionOldName, missionNewName);

    //Update attached files to be in the new path
    SetLength(fAttachedFiles, 0);
    DetectAttachedFiles(aMissionFile);
  end;

  fIsNewMap := False; //Map was saved, its not a new map anymore
  UpdateSavedInfo;
end;


function TKMMapEditor.CanHaveClassicAI: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to gHands.Count - 1 do
    Result := Result or (gHands[I].HasAssets and PlayerClassicAI[I]);
end;


function TKMMapEditor.CanHaveAdvancedAI: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to gHands.Count - 1 do
    Result := Result or (gHands[I].HasAssets and PlayerAdvancedAI[I]);
end;


function TKMMapEditor.OnlyAdvancedAIHand(aHandId: TKMHandID): Boolean;
begin
  Result := PlayerAdvancedAI[aHandId]
    and not PlayerClassicAI[aHandId]
    and not PlayerHuman[aHandId];
end;


function TKMMapEditor.HitTest(X, Y: Integer): TKMMapEdMarker;
var
  I, K: Integer;
begin
  if   (melDefences in fVisibleLayers)
    or (mlDefencesAll in gGameParams.VisibleLayers) then
  begin
    for I := 0 to gHands.Count - 1 do
      for K := 0 to gHands[I].AI.General.DefencePositions.Count - 1 do
        if (gHands[I].AI.General.DefencePositions[K].Position.Loc.X = X)
        and (gHands[I].AI.General.DefencePositions[K].Position.Loc.Y = Y) then
        begin
          Result.MarkerType := mmtDefence;
          Result.Owner := I;
          Result.Index := K;
          Exit;
        end;
  end;

  if melRevealFOW in fVisibleLayers then
  begin
    for I := 0 to gHands.Count - 1 do
      for K := 0 to fRevealers[I].Count - 1 do
        if (fRevealers[I][K].X = X) and (fRevealers[I][K].Y = Y) then
        begin
          Result.MarkerType := mmtRevealFOW;
          Result.Owner := I;
          Result.Index := K;
          Exit;
        end;
  end;

  //Else nothing is found
  Result.MarkerType := mmtNone;
  Result.Owner := HAND_NONE;
  Result.Index := -1;
end;


//How many human players there are in the mission
function TKMMapEditor.HumanCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(PlayerHuman) do
  if PlayerHuman[I] then
    Inc(Result);
end;


//aStageIncrement - stage increment, can be negative
procedure TKMMapEditor.UpdateField;
var
  P: TKMPoint;
  makeCheckpoint: Boolean;
begin
  P := gCursor.Cell;
  case gCursor.Mode of
    cmField:  begin
                if not gTerrain.TileIsCornField(P) and not gMySpectator.Hand.CanAddFieldPlan(P, ftCorn) then Exit;

                makeCheckpoint := not gTerrain.TileIsCornField(P);
                gMySpectator.Hand.AddField(P, ftCorn, gCursor.MapEdFieldAge);
                if makeCheckpoint then
                  fHistory.MakeCheckpoint(caTerrain, Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_ADD_SMTH],
                                                            [gResTexts[TX_WORD_CORN_FIELD], P.ToString]));
              end;
    cmWine:   begin
                if not gTerrain.TileIsWineField(P) and not gMySpectator.Hand.CanAddFieldPlan(P, ftWine) then Exit;

                makeCheckpoint := not gTerrain.TileIsWineField(P);
                gMySpectator.Hand.AddField(P, ftWine, gCursor.MapEdWineFieldAge);
                if makeCheckpoint then
                  fHistory.MakeCheckpoint(caTerrain, Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_ADD_SMTH],
                                                            [gResTexts[TX_WORD_WINE_FIELD], P.ToString]));
              end;
  end;
end;


function TKMMapEditor.EraseTerrainObject(var aRemoveTxID: Integer): Boolean;
var
  P: TKMPoint;
  isCorn, isWine: Boolean;
begin
  Result := False;
  P := gCursor.Cell;
  isCorn := gTerrain.TileIsCornField(P);
  isWine := gTerrain.TileIsWineField(P);

  //Delete tile object (including corn/wine objects as well)
  if (gTerrain.Land^[P.Y,P.X].Obj <> OBJ_NONE) then
  begin
    if isCorn and (gTerrain.GetCornStage(P) in [4,5]) then
    begin
      gTerrain.SetField(P, gTerrain.Land^[P.Y,P.X].TileOwner, ftCorn, 3); // For corn, when delete corn object reduce field stage to 3
      aRemoveTxID := TX_WORD_CORN_FIELD;
    end
    else
    if isWine then
    begin
      gTerrain.RemField(P);
      aRemoveTxID := TX_WORD_WINE_FIELD;
    end
    else
    begin
      gTerrain.SetObject(P, OBJ_NONE);
      aRemoveTxID := TX_WORD_OBJECT;
    end;
    Result := True; // We deleted smth here
  end;
end;


//aEraseAll - if true all objects under the cursor will be deleted
procedure TKMMapEditor.EraseObject(aEraseAll: Boolean);
var
  obj: TObject;
  P: TKMPoint;
  fieldsChanged, isCorn, isWine: Boolean;
  removeTxID: Integer;
begin
  fieldsChanged := False;
  P := gCursor.Cell;
  obj := gMySpectator.HitTestCursor(True);
  removeTxID := -1;

  try
    //Delete unit/house
    if obj is TKMUnit then
    begin
      gHands.RemAnyUnit(TKMUnit(obj).Position);
      if not aEraseAll then Exit;
    end
    else
    if obj is TKMHouse then
    begin
      gHands.RemAnyHouse(P);
      if not aEraseAll then Exit;
    end;

    isCorn := gTerrain.TileIsCornField(P);
    isWine := gTerrain.TileIsWineField(P);

    if EraseTerrainObject(removeTxID) and not aEraseAll then
      Exit;

    //Delete tile overlay (road/corn/wine)
    if gTerrain.Land^[P.Y,P.X].TileOverlay = toRoad then
    begin
      if not fieldsChanged then
        removeTxID := TX_WORD_ROAD;

      gTerrain.RemRoad(P);
      fieldsChanged := True;
    end else
    if gTerrain.Land^[P.Y,P.X].TileOverlay <> toNone then
    begin
      if not fieldsChanged then
        removeTxID := TX_WORD_OVERLAY;

      gTerrain.SetOverlay(P, toNone, True);
      fieldsChanged := True;
    end;

    if isCorn or isWine then
    begin
      if not fieldsChanged then
        removeTxID := IfThen(isCorn, TX_WORD_CORN_FIELD, TX_WORD_WINE_FIELD);

      gTerrain.RemField(P);
      fieldsChanged := True;
    end;
  finally
    if fieldsChanged then
    begin
      Assert(removeTxID <> -1);
      fHistory.MakeCheckpoint(caTerrain, Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_REMOVE_SMTH],
                                                [gResTexts[removeTxID], P.ToString]));
    end;
  end;
end;


procedure TKMMapEditor.DeletePlayer(aIndex: TKMHandID);
begin
  if gHands = nil then Exit;
  if gHands.Count = 0 then Exit;
  if not InRange(aIndex, 0, gHands.Count - 1) then Exit;

  Revealers[aIndex].Clear;

  gHands.RemovePlayerAssets(aIndex);
end;


procedure TKMMapEditor.ChangeOwner(aChangeOwnerForAll: Boolean);
var
  P: TKMPoint;
begin
  P := gCursor.Cell;
  //Fisrt try to change owner of object on tile
  if not ChangeEntityOwner(gMySpectator.HitTestCursorWGroup, gMySpectator.HandID) or aChangeOwnerForAll then
    //then try to change owner tile (road/field/wine)
    if ((gTerrain.Land^[P.Y, P.X].TileOverlay = toRoad) or (LandMapEd^[P.Y, P.X].CornOrWine <> 0))
      and (gTerrain.Land^[P.Y, P.X].TileOwner <> gMySpectator.HandID) then
    begin
      gTerrain.Land^[P.Y, P.X].TileOwner := gMySpectator.HandID;
      fHistory.MakeCheckpoint(caTerrain, Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_CHOWNER_SMTH], [P.ToString, '']));
    end;
end;


procedure TKMMapEditor.UpdateMapEdCursorParams(aMode: TKMChangeDefenceTypeMode; aDirInc: Integer = 1);
begin
  case aMode of
    //change direction forward
    cdmDir:         gCursor.MapEdDirection := KMAddDirection(gCursor.MapEdDirection, aDirInc);
    // change group type of defence position
    cdmGroupType:   if gCursor.MapEdDefPosGroupType = gtMounted then
                      gCursor.MapEdDefPosGroupType := gtMelee
                    else
                      gCursor.MapEdDefPosGroupType := TKMGroupType(Ord(gCursor.MapEdDefPosGroupType) + 1);
    //change defence type - defensive/attacking
    cdmDefPosType:  if gCursor.MapEdDefPosType = dtFrontLine then
                      gCursor.MapEdDefPosType := dtBackLine
                    else
                      gCursor.MapEdDefPosType := dtFrontLine;

  end;
end;


//Change owner for specified object
//returns True if owner was changed successfully
function TKMMapEditor.ChangeEntityOwner(aEntity: TKMHandEntity; aOwner: TKMHandID): Boolean;
var
  house: TKMHouse;
begin
  Result := False;
  if (aEntity = nil) or (aEntity.Owner = aOwner) then Exit;

  case aEntity.EntityType of
    etNone:   ;
    etHouse:  begin
                house := aEntity.AsHouse;
                house.OwnerUpdate(aOwner, True);
                gTerrain.SetHouseAreaOwner(house.Position, house.HouseType, aOwner); // Update minimap colors
                Result := True;
                fHistory.MakeCheckpoint(caHouses, Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_CHOWNER_SMTH],
                                                         [gResHouses[house.HouseType].HouseName, house.Entrance.ToString]));
              end;
    etUnit:   begin
                if aEntity.AsUnit.IsAnimal then Exit;

                aEntity.AsUnit.OwnerUpdate(aOwner, True);
                Result := True;
                fHistory.MakeCheckpoint(caUnits, Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_CHOWNER_SMTH],
                                                        [gRes.Units[aEntity.AsUnit.UnitType].GUIName,
                                                         aEntity.AsUnit.Position.ToString]));
              end;
    etGroup:  begin
                aEntity.AsGroup.OwnerUpdate(aOwner, True);
                Result := True;
                fHistory.MakeCheckpoint(caUnits, Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_CHOWNER_SMTH],
                                                        [gRes.Units[aEntity.AsGroup.FlagBearer.UnitType].GUIName,
                                                         aEntity.AsGroup.FlagBearer.Position.ToString]));
              end;
  end;
end;


procedure TKMMapEditor.MouseWheel(Shift: TShiftState; WheelSteps: Integer; X,Y: Integer);
begin
  // not used atm
end;


procedure TKMMapEditor.MouseDown(Button: TMouseButton);
begin
  if (Button = mbLeft) then
    case gCursor.Mode of
      cmSelection:  fSelection.Start;
      cmField,
      cmWine:       UpdateField;
      cmObjects:    begin
                      fLastErasedObjectLoc := KMPOINT_INVALID_TILE;
                      fLastRemoveTxID := -1;
                    end;
  end;
end;


procedure TKMMapEditor.ProceedRoadCursorMode;
var
  P: TKMPoint;
begin
  P := gCursor.Cell;
  if gMySpectator.Hand.CanAddFieldPlan(P, ftRoad) then
  begin
    //If there's a field remove it first so we don't get road on top of the field tile (undesired in MapEd)
    if gTerrain.TileIsCornField(P) or gTerrain.TileIsWineField(P) then
      gTerrain.RemField(P);

    gMySpectator.Hand.AddRoad(P);
    fHistory.MakeCheckpoint(caTerrain, Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_ADD_SMTH], [gResTexts[TX_WORD_ROAD], P.ToString]));
  end;
end;


procedure TKMMapEditor.ProceedEraseCursorMode;
var
  P: TKMPoint;
begin
  P := gCursor.Cell;
  gHands.RemAnyHouse(P);
  if gTerrain.Land^[P.Y,P.X].TileOverlay = toRoad then
  begin
    gTerrain.RemRoad(P);
    fHistory.MakeCheckpoint(caTerrain, Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_REMOVE_SMTH],
                                              [gResTexts[TX_WORD_ROAD], P.ToString]));
  end else
  if gTerrain.Land^[P.Y,P.X].TileOverlay <> toNone then
  begin
    gTerrain.SetOverlay(P, toNone, True);
    fHistory.MakeCheckpoint(caTerrain, Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_REMOVE_SMTH],
                                              [gResTexts[TX_WORD_OVERLAY], P.ToString]));
  end;

  if gTerrain.TileIsCornField(P) then
  begin
    gTerrain.RemField(P);
    fHistory.MakeCheckpoint(caTerrain, Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_REMOVE_SMTH],
                                              [gResTexts[TX_WORD_CORN_FIELD], P.ToString]));
  end
  else
  if gTerrain.TileIsWineField(P) then
  begin
    gTerrain.RemField(P);
    fHistory.MakeCheckpoint(caTerrain, Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_REMOVE_SMTH],
                                              [gResTexts[TX_WORD_WINE_FIELD], P.ToString]));
  end;
end;


procedure TKMMapEditor.MouseMove;
var
  P: TKMPoint;
begin
  // Only allow placing of roads etc. with the left mouse button
  if not (ssLeft in gCursor.SState) then Exit;

  P := gCursor.Cell;
  case gCursor.Mode of
    cmRoad:       ProceedRoadCursorMode;
    cmField,
    cmWine:       UpdateField;
    cmUnits:      ProceedUnitsCursorMode;
    cmErase:      ProceedEraseCursorMode;
    cmSelection:  fSelection.Resize;
    cmObjects:    if gCursor.Tag1 = OBJ_NONE then
                  begin
                    if EraseTerrainObject(fLastRemoveTxID) then
                      fLastErasedObjectLoc := gCursor.Cell;
                  end;
    cmPaintBucket:      ChangeOwner(ssShift in gCursor.SState);
    cmUniversalEraser:  EraseObject(ssShift in gCursor.SState);
  end;
end;


procedure TKMMapEditor.DetermineGroupFormationAndDir(const aLoc: TKMPoint; aGroupType: TKMGroupType;
                                                     out aFormation: TKMFormation; out aDir: TKMDirection);
var
  DP: TAIDefencePosition;
  determined: Boolean;
begin
  determined := False;
  if (mlDefencesAll in gGameParams.VisibleLayers)
    or ((gCursor.Mode = cmMarkers) and (gCursor.Tag1 = MARKER_DEFENCE)) then
  begin
    DP := gMySpectator.Hand.AI.General.DefencePositions.FindPositionAtLoc(aLoc);
    if (DP <> nil) and (DP.GroupType = aGroupType) then
    begin
      aDir := DP.Position.Dir;
      aFormation.CopyFrom(gMySpectator.Hand.AI.General.DefencePositions.TroopFormations[aGroupType]);
      determined := True;
    end;
  end;

  if not determined then
  begin
    aDir := gCursor.MapEdDirection;
    if gCursor.MapEdGroupFormation.NumUnits > 0 then
      aFormation.CopyFrom(gCursor.MapEdGroupFormation)
    else
      aFormation.CopyFrom(gMySpectator.Hand.AI.General.DefencePositions.TroopFormations[aGroupType]);
  end;
end;


procedure TKMMapEditor.ProceedUnitsCursorMode;
var
  P: TKMPoint;
  obj: TObject;
  formation: TKMFormation;
  GT: TKMGroupType;
  dir: TKMDirection;
begin
  P := gCursor.Cell;
  if gCursor.Tag1 = 255 then
  begin
    obj := gMySpectator.HitTestCursor(True);
    if obj is TKMUnit then
      gHands.RemAnyUnit(TKMUnit(obj).Position);
  end
  else
  if gTerrain.CanPlaceUnit(P, TKMUnitType(gCursor.Tag1)) then
  begin
    formation.NumUnits := 1;
    formation.UnitsPerRow := 1;

    //Check if we can really add a unit
    if TKMUnitType(gCursor.Tag1) in UNITS_CITIZEN then
      gMySpectator.Hand.AddUnit(TKMUnitType(gCursor.Tag1), P, False)
    else
    if TKMUnitType(gCursor.Tag1) in UNITS_WARRIORS then
    begin
      GT := UNIT_TO_GROUP_TYPE[TKMUnitType(gCursor.Tag1)];

      DetermineGroupFormationAndDir(P, GT, formation, dir);

      gMySpectator.Hand.AddUnitGroup(TKMUnitType(gCursor.Tag1), P, dir, formation.UnitsPerRow, formation.NumUnits)
    end
    else
      gHands.PlayerAnimals.AddUnit(TKMUnitType(gCursor.Tag1), P);
  end;
end;


procedure TKMMapEditor.Reset;
begin
  if Self = nil then Exit;
  
  ActiveMarker.MarkerType := mmtNone;
end;


function TKMMapEditor.GetCheckpointObjectsStr(removeTxID: Integer = TX_WORD_OBJECT): string;
begin
  Result := GetCheckpointObjectsStr(gCursor.Cell, removeTxID);
end;


function TKMMapEditor.GetCheckpointObjectsStr(aCell: TKMPoint; removeTxID: Integer = TX_WORD_OBJECT): string;
begin
  if gCursor.Tag1 = OBJ_NONE then
    Result := Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_REMOVE_SMTH], [gResTexts[removeTxID], aCell.ToString])
  else
    Result := Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_ADD_SMTH] + ' %s', [gResTexts[removeTxID], IntToStr(gCursor.Tag1), aCell.ToString])
end;


function TKMMapEditor.GetHistory: TKMMapEditorHistory;
begin
  if Self = nil then Exit(nil);
  
  Result := fHistory;
end;


procedure TKMMapEditor.AddDefenceMarker(const aLoc: TKMPoint);
const
  UNIT_TYPES_BY_GT_LVL: array[GROUP_TYPE_MIN..GROUP_TYPE_MAX, TKMGroupLevel] of TKMUnitType =
                          ((utMilitia,  utAxeFighter,   utSwordFighter),
                           (utRebel,    utLanceCarrier, utPikeman),
                           (utRogue,    utBowman,       utCrossbowman),
                           (utVagabond, utScout,        utKnight));

var
  groupType: TKMGroupType;
  dir: TKMDirection;
  G: TKMUnitGroup;
  formation : TKMFormation;
begin
  dir := gCursor.MapEdDirection;
  groupType := gCursor.MapEdDefPosGroupType;

  G := gHands.GroupsHitTest(aLoc.X, aLoc.Y);
  if G <> nil then
  begin
    dir := G.Direction;
    groupType := G.GroupType;
  end;

  if gMySpectator.Hand.AI.General.DefencePositions.FindPositionAtLoc(aLoc) <> nil then
    Exit;

  if gCursor.MapEdDefPosSetGroup then
  begin
    formation := gMySpectator.Hand.AI.General.DefencePositions.TroopFormations[groupType];
    if G = nil then
      gMySpectator.Hand.AddUnitGroup(UNIT_TYPES_BY_GT_LVL[groupType, gCursor.MapEdDefPosGroupLevel],
                                     aLoc, dir, formation.UnitsPerRow, formation.NumUnits);
  end;

  gMySpectator.Hand.AI.General.DefencePositions.Add(KMPointDir(aLoc, dir),
                                                    groupType,
                                                    DEFAULT_DEFENCE_POSITION_RADIUS,
                                                    gCursor.MapEdDefPosType);

end;


procedure TKMMapEditor.MouseUp(Button: TMouseButton; aOverMap: Boolean);

  function IsObjectDeleting: Boolean;
  begin
    Result := gCursor.Tag1 = OBJ_NONE;
  end;

  procedure ManageObjects;
  begin
    if IsObjectDeleting then
    begin
      if (fLastErasedObjectLoc <> KMPOINT_INVALID_TILE) and (fLastRemoveTxID <> -1) then
        fHistory.MakeCheckpoint(caTerrain, GetCheckpointObjectsStr(fLastErasedObjectLoc, fLastRemoveTxID));
    end
    else
      fHistory.MakeCheckpoint(caTerrain, GetCheckpointObjectsStr);
  end;

var
  P: TKMPoint;
  removeTxID: Integer;
begin
  //If the mouse is released over controls, most actions don't happen
  if not aOverMap then
  begin
    //Still need to make a checkpoint since painting has now stopped
    case gCursor.Mode of
      cmElevate:  fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_TERRAIN_HEIGHTS_ELEVATE]);
      cmEqualize: fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_TERRAIN_HEIGHTS_UNEQUALIZE]);
      cmElevateAll:   fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_HEIGHTS_ELEVATE_ALL]);
      cmConstHeight:  fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_HEIGHTS_CONST]);
      cmBrush:    fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_TERRAIN_BRUSH]);
      cmObjects:  ManageObjects;
      cmObjectsBrush: fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_OBJECTS_BRUSH]);
      cmTiles:    fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_TERRAIN_HINTS_TILES]);
      cmOverlays: fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_TERRAIN_OVERLAYS]);
    end;
    Exit;
  end;

  P := gCursor.Cell; //Get cursor position tile-wise
  case Button of
    mbLeft:   case gCursor.Mode of
                cmRoad:       ProceedRoadCursorMode;
                cmHouses:     if gMySpectator.Hand.CanAddHousePlan(P, TKMHouseType(gCursor.Tag1)) then
                              begin
                                gMySpectator.Hand.AddHouse(TKMHouseType(gCursor.Tag1), P.X, P.Y, True);
                                fHistory.MakeCheckpoint(caHouses,
                                                        Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_ADD_SMTH],
                                                               [gResHouses[TKMHouseType(gCursor.Tag1)].HouseName,
                                                                P.ToString]));
                                //Holding shift allows to place that house multiple times
                                if not (ssShift in gCursor.SState) then
                                begin
                                  gCursor.Tag1 := 0; //Reset tag
                                  gCursor.Mode := cmRoad;
                                end;
                              end;
                cmElevate:    fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_TERRAIN_HEIGHTS_ELEVATE]);
                cmEqualize:   fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_TERRAIN_HEIGHTS_UNEQUALIZE]);
                cmElevateAll: fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_HEIGHTS_ELEVATE_ALL]);
                cmConstHeight: fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_HEIGHTS_CONST]);
                cmBrush:      fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_TERRAIN_BRUSH]);
                cmObjects:    if IsObjectDeleting then
                              begin
                                if EraseTerrainObject(removeTxID) then
                                  fHistory.MakeCheckpoint(caTerrain, GetCheckpointObjectsStr(removeTxID))
                                else
                                  ManageObjects;
                              end
                              else
                                fHistory.MakeCheckpoint(caTerrain, GetCheckpointObjectsStr);
                cmObjectsBrush: fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_OBJECTS_BRUSH]);
                cmTiles:      fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_TERRAIN_HINTS_TILES] + ' ' + P.ToString);
                cmOverlays:   fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_TERRAIN_OVERLAYS] + ' ' + P.ToString);
                cmMagicWater: fTerrainPainter.MagicWater(P);
                cmEyedropper: begin
                                fTerrainPainter.Eyedropper(P);

                                if Assigned(OnEyedropper) then
                                  OnEyedropper(gCursor.Tag1);

                                if not (ssShift in gCursor.SState) then  //Holding shift allows to choose another tile
                                  gCursor.Mode := cmTiles;
                              end;
                cmRotateTile: fTerrainPainter.RotateTile(P);
                cmUnits:      ProceedUnitsCursorMode;
                cmMarkers:    case gCursor.Tag1 of
                                MARKER_REVEAL:        fRevealers[gMySpectator.HandID].Add(P, gCursor.MapEdSize);
                                MARKER_DEFENCE:       AddDefenceMarker(P);
                                MARKER_CENTERSCREEN:  begin
                                                        gMySpectator.Hand.CenterScreen := P;
                                                        //Updating XY display is done in InterfaceMapEd
                                                      end;
                                MARKER_AISTART:       gMySpectator.Hand.AI.Setup.StartPosition := P;
                                MARKER_RALLY_POINT:   if gMySpectator.Selected is TKMHouseWFlagPoint then
                                                        TKMHouseWFlagPoint(gMySpectator.Selected).FlagPoint := P;
                              end;
                cmErase:      ProceedEraseCursorMode;
                cmPaintBucket:      ChangeOwner(ssShift in gCursor.SState);
                cmUniversalEraser:  EraseObject(ssShift in gCursor.SState);
              end;
    mbRight:  case gCursor.Mode of
                              //Actual change was made in UpdateStateIdle, we just register it is done here
                cmElevate:    fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_TERRAIN_HEIGHTS_ELEVATE]);
                cmEqualize:   fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_TERRAIN_HEIGHTS_UNEQUALIZE]);
                cmElevateAll: fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_HEIGHTS_ELEVATE_ALL]);
                cmObjects,
                cmEyedropper,
                cmRotateTile: gCursor.Mode := cmNone;

                cmMarkers:    case gCursor.Tag1 of
                                MARKER_DEFENCE:       begin
                                                        if ssCtrl in gCursor.SState then
                                                          UpdateMapEdCursorParams(cdmDir, -1)//change dir backward
                                                        else
                                                        if ssShift in gCursor.SState then
                                                          UpdateMapEdCursorParams(cdmGroupType)//change gtype
                                                        else
                                                        if ssAlt in gCursor.SState then
                                                          UpdateMapEdCursorParams(cdmDefPosType)//change att/def
                                                        else
                                                          UpdateMapEdCursorParams(cdmDir);//change dir
                                                      end;
                              end;

                cmUnits:      if ssCtrl in gCursor.SState then
                                UpdateMapEdCursorParams(cdmDir, -1)
                              else
                              if ssShift in gCursor.SState then
                                UpdateMapEdCursorParams(cdmDir, 4)
                              else
                                UpdateMapEdCursorParams(cdmDir);
              end;
  end;
end;


procedure TKMMapEditor.PaintDefences(aLayer: TKMPaintLayer);
var
  DP: TAIDefencePosition;
begin
  if not (melDefences in fVisibleLayers) then Exit;

  case aLayer of
    plTerrain:  if ActiveMarker.MarkerType = mmtDefence then
                  //Render defence position tiles covered
                  if InRange(ActiveMarker.Index, 0, gHands[ActiveMarker.Owner].AI.General.DefencePositions.Count - 1) then
                  begin
                    DP := gHands[ActiveMarker.Owner].AI.General.DefencePositions[ActiveMarker.Index];
                    gRenderPool.RenderDebug.RenderTiledArea(DP.Position.Loc, 0, DP.Radius, KMLengthDiag,
                                                            gHands[ActiveMarker.Owner].FlagColor AND $60FFFFFF,
                                                            icCyan);
                  end;
  end;
end;


procedure TKMMapEditor.PaintRevealFOW(aLayer: TKMPaintLayer);
var
  I, K: Integer;
  loc: TKMPoint;
begin
  if not (melRevealFOW in fVisibleLayers) then Exit;

  for I := 0 to gHands.Count - 1 do
    for K := 0 to fRevealers[I].Count - 1 do
    begin
      loc := fRevealers[I][K];
      case aLayer of
        plTerrain:  gRenderAux.CircleOnTerrain(loc.X-0.5, loc.Y-0.5,
                                             fRevealers[I].Tag[K],
                                             gHands[I].FlagColor and $20FFFFFF,
                                             gHands[I].FlagColor);
        plCursors:  gRenderPool.RenderSpriteOnTile(loc, 394, gHands[I].FlagColor);
      end;
    end;
end;


procedure TKMMapEditor.PaintCenterScreen(aLayer: TKMPaintLayer);
var
  I: Integer;
  loc: TKMPoint;
begin
  if not (melCenterScreen in fVisibleLayers) then Exit;

  for I := 0 to gHands.Count - 1 do
    if gHands[I].HasAssets then
    begin
      loc := gHands[I].CenterScreen;
      case aLayer of
        plTerrain:  gRenderAux.SquareOnTerrain(loc.X - 3, loc.Y - 2.5,
                                               loc.X + 2, loc.Y + 1.5,
                                               gHands[I].FlagColor);
        plCursors:  gRenderPool.RenderSpriteOnTile(loc, 391, gHands[I].FlagColor);
      end;
    end;
end;


procedure TKMMapEditor.PaintAIStart(aLayer: TKMPaintLayer);
var
  I: Integer;
  loc: TKMPoint;
begin
  if not (melAIStart in fVisibleLayers) then Exit;

  for I := 0 to gHands.Count - 1 do
    if gHands[I].HasAssets then
    begin
      loc := gHands[I].AI.Setup.StartPosition;
      case aLayer of
        plTerrain:  gRenderAux.SquareOnTerrain(loc.X - 3, loc.Y - 2.5,
                                               loc.X + 2, loc.Y + 1.5,
                                               gHands[I].FlagColor);
        plCursors:  gRenderPool.RenderSpriteOnTile(loc, 390, gHands[I].FlagColor);
      end;
    end;
end;


procedure TKMMapEditor.Paint(aLayer: TKMPaintLayer; const aClipRect: TKMRect);
var
  I, K: Integer;
  P: TKMPoint;
  G: TKMUnitGroup;
begin
  P := gCursor.Cell;

  if aLayer = plCursors then
    //With Buildings tab see if we can remove Fields or Houses
    if gCursor.Mode = cmErase then
      if gTerrain.TileIsCornField(P)
        or gTerrain.TileIsWineField(P)
        or (gTerrain.Land^[P.Y,P.X].TileOverlay = toRoad)
        or (gHands.HousesHitTest(P.X, P.Y) <> nil) then
        gRenderPool.RenderWireTile(P, icCyan) //Cyan quad
      else
        gRenderPool.RenderSpriteOnTile(P, TC_BLOCK); //Red X

  PaintDefences(aLayer);
  PaintRevealFOW(aLayer);
  PaintCenterScreen(aLayer);
  PaintAIStart(aLayer);

  if melSelection in fVisibleLayers then
    fSelection.Paint(aLayer, aClipRect);

  if (melMapResize in fVisibleLayers) and not KMSameRect(ResizeMapRect, KMRECT_ZERO) then
    gRenderGameAux.RenderResizeMap(ResizeMapRect);

  if melWaterFlow in fVisibleLayers then
  begin
    for I := aClipRect.Top to aClipRect.Bottom do
    for K := aClipRect.Left to aClipRect.Right do
    if gTerrain.TileIsWater(K,I) then
    begin
      //todo: Waterflow indication here
      //gRenderPool.RenderSpriteOnTile(KMPoint(K,I), )
    end;
  end;


  //Show selected group order target
  if gMySpectator.Selected is TKMUnitGroup then
  begin
    G := TKMUnitGroup(gMySpectator.Selected);
    if G.MapEdOrder.Order <> gioNoOrder then
    begin
      gRenderAux.Quad(G.MapEdOrder.Pos.Loc.X, G.MapEdOrder.Pos.Loc.Y, $40FF00FF);
      gRenderAux.LineOnTerrain(G.Position.X - 0.5, G.Position.Y - 0.5, G.MapEdOrder.Pos.Loc.X - 0.5, G.MapEdOrder.Pos.Loc.Y - 0.5, $FF0000FF);
    end;
  end;
end;


procedure TKMMapEditor.UpdateState;
begin
  if Self = nil then Exit;

  if melDeposits in fVisibleLayers then
    fDeposits.UpdateAreas([rdStone, rdCoal, rdIron, rdGold, rdFish]);

  fTerrainPainter.UpdateState;

  //todo: if mlNavMesh in VisibleLayers then
    //gAIFields.NavMesh.Init;
end;


procedure TKMMapEditor.UpdateStateIdle;
begin
  fTerrainPainter.UpdateStateIdle;
end;


end.

