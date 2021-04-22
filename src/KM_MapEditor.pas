unit KM_MapEditor;
{$I KaM_Remake.inc}
interface
uses
  Classes, Controls,
  KM_RenderPool, KM_TerrainPainter, KM_TerrainDeposits, KM_TerrainSelection,
  KM_CommonTypes, KM_CommonClasses, KM_Defaults, KM_Points, KM_MapEditorHistory,
  KM_MapEdTypes, KM_ResTexts, KM_HandEntity;


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
    procedure UpdateField(aStageIncrement: Integer; aCheckPrevCell: Boolean);
    function EraseTerrainObject(var aRemoveTxID: Integer): Boolean;
    procedure EraseObject(aEraseAll: Boolean);
    function ChangeEntityOwner(aEntity: TKMHandEntity; aOwner: TKMHandID): Boolean;
    procedure ChangeOwner(aChangeOwnerForAll: Boolean);
    procedure PaintDefences(aLayer: TKMPaintLayer);
    procedure PaintRevealFOW(aLayer: TKMPaintLayer);
    procedure PaintCenterScreen(aLayer: TKMPaintLayer);
    procedure PaintAIStart(aLayer: TKMPaintLayer);

    procedure AddDefenceMarker(const aLoc: TKMPoint);

    function GetCheckpointObjectsStr(removeTxID: Integer = TX_WORD_OBJECT): string; overload;
    function GetCheckpointObjectsStr(aCell: TKMPoint; removeTxID: Integer = TX_WORD_OBJECT): string; overload;
    function GetHistory: TKMMapEditorHistory;

    function MapIsPlayable: Boolean;
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

    function OnlyAdvancedAIHand(aHandId: TKMHandID): Boolean;

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
  KM_GameParams, KM_GameCursor, KM_ResMapElements, KM_ResHouses, KM_Resource, KM_ResUnits,
  KM_RenderAux, KM_Hand, KM_HandsCollection, KM_CommonUtils, KM_RenderDebug,
  KM_HandEntityHelper,
  KM_UnitGroupTypes,
  KM_HandTypes,
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


procedure TKMMapEditor.DetectAttachedFiles(const aMissionFile: UnicodeString);

  procedure AddAttachment(var aAttachCnt: Integer; const aFileName: UnicodeString);
  begin
    if aAttachCnt >= Length(fAttachedFiles) then
      SetLength(fAttachedFiles, aAttachCnt + 8);

    fAttachedFiles[aAttachCnt] := aFileName;
    Inc(aAttachCnt);
  end;

var
  SearchRec: TSearchRec;
  MissionScriptFileName, MissionName, RecExt: UnicodeString;
  HasScript: Boolean;
  AttachCnt: Integer;
begin
  HasScript := False;
  AttachCnt := 0;
  SetLength(fAttachedFiles, 8);
  MissionDefSavePath := aMissionFile;
  MissionName := ChangeFileExt(ExtractFileName(aMissionFile), '');
  FindFirst(ChangeFileExt(aMissionFile, '.*'), faAnyFile - faDirectory, SearchRec);
  try
    repeat
      if (SearchRec.Name <> '') and (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
      begin
        //Can't use ExtractFileExt because we want .eng.libx not .libx
        RecExt := RightStr(SearchRec.Name, Length(SearchRec.Name) - Length(MissionName));
        if (LowerCase(RecExt) = '.map')
          or (LowerCase(RecExt) = '.dat')
          or (LowerCase(RecExt) = '.mi' ) then
          Continue;

        if LowerCase(RecExt) = EXT_FILE_SCRIPT_DOT then
          HasScript := True;

        AddAttachment(AttachCnt, ExtractFilePath(aMissionFile) + SearchRec.Name);
      end;
    until (FindNext(SearchRec) <> 0);
  finally
    FindClose(SearchRec);
  end;

  //Add all scripts if we find main script
  if HasScript then
  begin
    MissionScriptFileName := MissionName + EXT_FILE_SCRIPT_DOT;
    FindFirst(ExtractFilePath(aMissionFile) + '*' + EXT_FILE_SCRIPT_DOT, faAnyFile - faDirectory, SearchRec);
    try
      repeat
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..')
          and (SearchRec.Name <> MissionScriptFileName) then
          AddAttachment(AttachCnt, ExtractFilePath(aMissionFile) + SearchRec.Name);
      until (FindNext(SearchRec) <> 0);
    finally
      FindClose(SearchRec);
    end;
  end;

  SetLength(fAttachedFiles, AttachCnt);
end;


function TKMMapEditor.MapIsPlayable: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to MAX_HANDS - 1 do
    if PlayerHuman[I] and gHands[I].HasAssets then
      Exit(True);
end;


procedure TKMMapEditor.AfterCreated;
begin
  fSavedMapIsPlayable := MapIsPlayable;
end;


procedure TKMMapEditor.SetMainLandMapEd;
begin
  if Self = nil then Exit;

  LandMapEd := @fLandMapEd;
end;


procedure TKMMapEditor.SaveAttachements(const aMissionFile: UnicodeString);
var
  I: Integer;
  MissionPath, MissionNewName, MissionOldName, DestPath: UnicodeString;
begin
  if not fIsNewMap then
  begin
    MissionPath := ExtractFilePath(aMissionFile);
    MissionNewName := GetFileDirName(aMissionFile);
    MissionOldName := '';

    //Copy all attachments files into new folder
    for I := 0 to High(fAttachedFiles) do
      if FileExists(fAttachedFiles[I]) then
      begin
        DestPath := MissionPath + ExtractFileName(fAttachedFiles[I]);

        //Get MissionOldName from first attachment file
        if MissionOldName = '' then
          MissionOldName := GetFileDirName(fAttachedFiles[I]);

        if not SameFileName(DestPath, fAttachedFiles[I]) then
        begin
          if FileExists(DestPath) then
            DeleteFile(DestPath);
          KMCopyFile(fAttachedFiles[I], DestPath);
        end;
      end;

    // Rename all files inside new saved map folder
    KMRenameFilesInFolder(MissionPath, MissionOldName, MissionNewName);

    //Update attached files to be in the new path
    SetLength(fAttachedFiles, 0);
    DetectAttachedFiles(aMissionFile);
  end;

  fIsNewMap := False; //Map was saved, its not a new map anymore
  fSavedMapIsPlayable := MapIsPlayable;
end;


function TKMMapEditor.OnlyAdvancedAIHand(aHandId: TKMHandID): Boolean;
begin
  Result := PlayerAdvancedAI[aHandId]
    and not PlayerClassicAI[aHandId]
    and not PlayerHuman[aHandId];
end;


function TKMMapEditor.HitTest(X, Y: Integer): TKMMapEdMarker;
var
  I,K: Integer;
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
  Result.Owner := PLAYER_NONE;
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
//aCheckPrevCell - do we check prev cell under the cursor to differ from current cell under the cursor
procedure TKMMapEditor.UpdateField(aStageIncrement: Integer; aCheckPrevCell: Boolean);
var
  P: TKMPoint;
  FieldStage: Integer;
  makeCheckpoint: Boolean;
  fieldStr: string;
begin
  if aStageIncrement = 0 then Exit;

  FieldStage := -1;
  makeCheckpoint := False;
  fieldStr := '';
  P := gGameCursor.Cell;
  case gGameCursor.Mode of
    cmField:  begin
                if gTerrain.TileIsCornField(P) then
                begin
                  if not KMSamePoint(P, gGameCursor.PrevCell) or not aCheckPrevCell then
                    FieldStage := (gTerrain.GetCornStage(P) + aStageIncrement + CORN_STAGES_COUNT) mod CORN_STAGES_COUNT;
                end
                else
                if gMySpectator.Hand.CanAddFieldPlan(P, ftCorn) then
                begin
                  FieldStage := 0;
                  makeCheckpoint := True;
                  fieldStr := Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_ADD_SMTH], [gResTexts[TX_WORD_CORN_FIELD], P.ToString]);
                end;

                if FieldStage >= 0 then
                begin
                  gMySpectator.Hand.AddField(P, ftCorn, FieldStage);
                  if makeCheckpoint then
                    fHistory.MakeCheckpoint(caTerrain, fieldStr);
                end;
              end;
    cmWine:   begin
                if gTerrain.TileIsWineField(P) then
                begin
                  if not KMSamePoint(P, gGameCursor.PrevCell) or not aCheckPrevCell then
                    FieldStage := (gTerrain.GetWineStage(P) + aStageIncrement + WINE_STAGES_COUNT) mod WINE_STAGES_COUNT;
                end
                else
                if gMySpectator.Hand.CanAddFieldPlan(P, ftWine) then
                begin
                  FieldStage := 0;
                  makeCheckpoint := True;
                  fieldStr := Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_ADD_SMTH], [gResTexts[TX_WORD_WINE_FIELD], P.ToString]);
                end;

                if FieldStage >= 0 then
                begin
                  gMySpectator.Hand.AddField(P, ftWine, FieldStage);
                  if makeCheckpoint then
                    fHistory.MakeCheckpoint(caTerrain, fieldStr);
                end;
              end;
  end;
end;


function TKMMapEditor.EraseTerrainObject(var aRemoveTxID: Integer): Boolean;
var
  P: TKMPoint;
  isCorn, isWine: Boolean;
begin
  Result := False;
  P := gGameCursor.Cell;
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
  Obj: TObject;
  P: TKMPoint;
  fieldsChanged, isCorn, isWine: Boolean;
  removeTxID: Integer;
begin
  fieldsChanged := False;
  P := gGameCursor.Cell;
  Obj := gMySpectator.HitTestCursor(True);
  removeTxID := -1;

  try
    //Delete unit/house
    if Obj is TKMUnit then
    begin
      gHands.RemAnyUnit(TKMUnit(Obj).Position);
      if not aEraseAll then Exit;
    end
    else
    if Obj is TKMHouse then
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

  gHands.Hands[aIndex].Units.RemoveAllUnits;

  gHands.Hands[aIndex].UnitGroups.RemAllGroups;

  gHands.Hands[aIndex].Houses.RemoveAllHouses;

  gTerrain.ClearPlayerLand(aIndex);

  gHands.Hands[aIndex].AI.Goals.Clear;

  gHands.Hands[aIndex].AI.General.Attacks.Clear;

  gHands.Hands[aIndex].AI.General.DefencePositions.Clear;

  gHands.Hands[aIndex].ResetChooseLocation;

end;


procedure TKMMapEditor.ChangeOwner(aChangeOwnerForAll: Boolean);
var
  P: TKMPoint;
begin
  P := gGameCursor.Cell;
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
                                                         [gRes.Houses[house.HouseType].HouseName, house.Entrance.ToString]));
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
  UpdateField(WheelSteps, False);
end;


procedure TKMMapEditor.MouseDown(Button: TMouseButton);
begin
  if (Button = mbLeft) then
    case gGameCursor.Mode of
      cmSelection:  fSelection.Start;
      cmField,
      cmWine:       UpdateField(1, False);
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
  P := gGameCursor.Cell;
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
  P := gGameCursor.Cell;
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
  if not (ssLeft in gGameCursor.SState) then Exit;

  P := gGameCursor.Cell;
  case gGameCursor.Mode of
    cmRoad:       ProceedRoadCursorMode;
    cmField,
    cmWine:       UpdateField(1, True);
    cmUnits:      ProceedUnitsCursorMode;
    cmErase:      ProceedEraseCursorMode;
    cmSelection:  fSelection.Resize;
    cmObjects:    if gGameCursor.Tag1 = OBJ_NONE then
                  begin
                    if EraseTerrainObject(fLastRemoveTxID) then
                      fLastErasedObjectLoc := gGameCursor.Cell;
                  end;
    cmPaintBucket:      ChangeOwner(ssShift in gGameCursor.SState);
    cmUniversalEraser:  EraseObject(ssShift in gGameCursor.SState);
  end;
end;


procedure TKMMapEditor.ProceedUnitsCursorMode;
var
  P: TKMPoint;
  Obj: TObject;
begin
  P := gGameCursor.Cell;

  if gGameCursor.Tag1 = 255 then
  begin
    Obj := gMySpectator.HitTestCursor(True);
    if Obj is TKMUnit then
      gHands.RemAnyUnit(TKMUnit(Obj).Position);
  end else
  if gTerrain.CanPlaceUnit(P, TKMUnitType(gGameCursor.Tag1)) then
  begin
    //Check if we can really add a unit
    if TKMUnitType(gGameCursor.Tag1) in [CITIZEN_MIN..CITIZEN_MAX] then
      gMySpectator.Hand.AddUnit(TKMUnitType(gGameCursor.Tag1), P, False)
    else
    if TKMUnitType(gGameCursor.Tag1) in [WARRIOR_MIN..WARRIOR_MAX] then
      gMySpectator.Hand.AddUnitGroup(TKMUnitType(gGameCursor.Tag1), P, dirS, 1, 1)
    else
      gHands.PlayerAnimals.AddUnit(TKMUnitType(gGameCursor.Tag1), P);
  end;
end;


procedure TKMMapEditor.Reset;
begin
  if Self = nil then Exit;
  
  ActiveMarker.MarkerType := mmtNone;
end;


function TKMMapEditor.GetCheckpointObjectsStr(removeTxID: Integer = TX_WORD_OBJECT): string;
begin
  Result := GetCheckpointObjectsStr(gGameCursor.Cell, removeTxID);
end;


function TKMMapEditor.GetCheckpointObjectsStr(aCell: TKMPoint; removeTxID: Integer = TX_WORD_OBJECT): string;
begin
  if gGameCursor.Tag1 = OBJ_NONE then
    Result := Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_REMOVE_SMTH], [gResTexts[removeTxID], aCell.ToString])
  else
    Result := Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_ADD_SMTH] + ' %s', [gResTexts[removeTxID], IntToStr(gGameCursor.Tag1), aCell.ToString])
end;


function TKMMapEditor.GetHistory: TKMMapEditorHistory;
begin
  if Self = nil then Exit(nil);
  
  Result := fHistory;
end;


procedure TKMMapEditor.AddDefenceMarker(const aLoc: TKMPoint);
var
  groupType: TKMGroupType;
  dir: TKMDirection;
  G: TKMUnitGroup;
begin
  dir := dirN;
  groupType := gtMelee;
  G := gHands.GroupsHitTest(aLoc.X, aLoc.Y);
  if G <> nil then
  begin
    dir := G.Direction;
    groupType := G.GroupType;
  end;

  gMySpectator.Hand.AI.General.DefencePositions.Add(KMPointDir(aLoc, dir), groupType, DEFAULT_DEFENCE_POSITION_RADIUS, adtFrontLine);
end;


procedure TKMMapEditor.MouseUp(Button: TMouseButton; aOverMap: Boolean);

  function IsObjectDeleting: Boolean;
  begin
    Result := gGameCursor.Tag1 = OBJ_NONE;
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
    case gGameCursor.Mode of
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

  P := gGameCursor.Cell; //Get cursor position tile-wise
  case Button of
    mbLeft:   case gGameCursor.Mode of
                cmRoad:       ProceedRoadCursorMode;
                cmHouses:     if gMySpectator.Hand.CanAddHousePlan(P, TKMHouseType(gGameCursor.Tag1)) then
                              begin
                                gMySpectator.Hand.AddHouse(TKMHouseType(gGameCursor.Tag1), P.X, P.Y, True);
                                fHistory.MakeCheckpoint(caHouses,
                                                        Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_ADD_SMTH],
                                                               [gRes.Houses[TKMHouseType(gGameCursor.Tag1)].HouseName,
                                                                P.ToString]));
                                //Holding shift allows to place that house multiple times
                                if not (ssShift in gGameCursor.SState) then
                                begin
                                  gGameCursor.Tag1 := 0; //Reset tag
                                  gGameCursor.Mode := cmRoad;
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
                                  OnEyedropper(gGameCursor.Tag1);

                                if not (ssShift in gGameCursor.SState) then  //Holding shift allows to choose another tile
                                  gGameCursor.Mode := cmTiles;
                              end;
                cmRotateTile: fTerrainPainter.RotateTile(P);
                cmUnits:      ProceedUnitsCursorMode;
                cmMarkers:    case gGameCursor.Tag1 of
                                MARKER_REVEAL:        fRevealers[gMySpectator.HandID].Add(P, gGameCursor.MapEdSize);
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
                cmPaintBucket:      ChangeOwner(ssShift in gGameCursor.SState);
                cmUniversalEraser:  EraseObject(ssShift in gGameCursor.SState);
              end;
    mbRight:  case gGameCursor.Mode of
                              //Actual change was made in UpdateStateIdle, we just register it is done here
                cmElevate:    fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_TERRAIN_HEIGHTS_ELEVATE]);
                cmEqualize:   fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_TERRAIN_HEIGHTS_UNEQUALIZE]);
                cmElevateAll: fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_HEIGHTS_ELEVATE_ALL]);
                cmObjects,
                cmEyedropper,
                cmRotateTile: gGameCursor.Mode := cmNone;
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
  Loc: TKMPoint;
begin
  if not (melRevealFOW in fVisibleLayers) then Exit;

  for I := 0 to gHands.Count - 1 do
    for K := 0 to fRevealers[I].Count - 1 do
    begin
      Loc := fRevealers[I][K];
      case aLayer of
        plTerrain:  gRenderAux.CircleOnTerrain(Loc.X-0.5, Loc.Y-0.5,
                                             fRevealers[I].Tag[K],
                                             gHands[I].FlagColor and $20FFFFFF,
                                             gHands[I].FlagColor);
        plCursors:  gRenderPool.RenderSpriteOnTile(Loc, 394, gHands[I].FlagColor);
      end;
    end;
end;


procedure TKMMapEditor.PaintCenterScreen(aLayer: TKMPaintLayer);
var
  I: Integer;
  Loc: TKMPoint;
begin
  if not (melCenterScreen in fVisibleLayers) then Exit;

  for I := 0 to gHands.Count - 1 do
    if gHands[I].HasAssets then
    begin
      Loc := gHands[I].CenterScreen;
      case aLayer of
        plTerrain:  gRenderAux.SquareOnTerrain(Loc.X - 3, Loc.Y - 2.5,
                                               Loc.X + 2, Loc.Y + 1.5,
                                               gHands[I].FlagColor);
        plCursors:  gRenderPool.RenderSpriteOnTile(Loc, 391, gHands[I].FlagColor);
      end;
    end;
end;


procedure TKMMapEditor.PaintAIStart(aLayer: TKMPaintLayer);
var
  I: Integer;
  Loc: TKMPoint;
begin
  if not (melAIStart in fVisibleLayers) then Exit;

  for I := 0 to gHands.Count - 1 do
    if gHands[I].HasAssets then
    begin
      Loc := gHands[I].AI.Setup.StartPosition;
      case aLayer of
        plTerrain:  gRenderAux.SquareOnTerrain(Loc.X - 3, Loc.Y - 2.5,
                                               Loc.X + 2, Loc.Y + 1.5,
                                               gHands[I].FlagColor);
        plCursors:  gRenderPool.RenderSpriteOnTile(Loc, 390, gHands[I].FlagColor);
      end;
    end;
end;


procedure TKMMapEditor.Paint(aLayer: TKMPaintLayer; const aClipRect: TKMRect);
var
  I, K: Integer;
  P: TKMPoint;
  G: TKMUnitGroup;
begin
  P := gGameCursor.Cell;

  if aLayer = plCursors then
    //With Buildings tab see if we can remove Fields or Houses
    if gGameCursor.Mode = cmErase then
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
    gRenderAux.RenderResizeMap(ResizeMapRect);

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

