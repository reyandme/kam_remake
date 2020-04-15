unit KM_MapEditor;
{$I KaM_Remake.inc}
interface
uses
  Classes, Controls,
  KM_RenderPool, KM_TerrainPainter, KM_TerrainDeposits, KM_TerrainSelection,
  KM_CommonTypes, KM_CommonClasses, KM_Defaults, KM_Points, KM_MapEditorHistory;


type
  TKMMarkerType = (mtNone, mtDefence, mtRevealFOW);

  TKMMapEdMarker = record
    MarkerType: TKMMarkerType;
    Owner: TKMHandID;
    Index: SmallInt;
  end;

  //Collection of map editing classes and map editor specific data
  TKMMapEditor = class
  private
    fTerrainPainter: TKMTerrainPainter;
    fHistory: TKMMapEditorHistory;
    fDeposits: TKMDeposits;
    fSelection: TKMSelection;
    fRevealers: array [0..MAX_HANDS-1] of TKMPointTagList;
    fVisibleLayers: TKMMapEdLayerSet;
    //When you load a map script/libx/wav/etc. files are "attached" then copied when
    //saving if the path is different
    fAttachedFiles: array of UnicodeString;

    function GetRevealer(aIndex: Byte): TKMPointTagList;
    procedure ProceedRoadCursorMode;
    procedure ProceedUnitsCursorMode;
    procedure ProceedEraseCursorMode;
    procedure UpdateField(aStageIncrement: Integer; aCheckPrevCell: Boolean);
    procedure EraseObject(aEraseAll: Boolean);
    function ChangeObjectOwner(aObject: TObject; aOwner: TKMHandID): Boolean;
    procedure ChangeOwner(aChangeOwnerForAll: Boolean);
    procedure PaintDefences(aLayer: TKMPaintLayer);
    procedure PaintRevealFOW(aLayer: TKMPaintLayer);
    procedure PaintCenterScreen(aLayer: TKMPaintLayer);
    procedure PaintAIStart(aLayer: TKMPaintLayer);
    procedure PaintMiningRadius(aLayer: TKMPaintLayer);

    function GetCheckpointObjectsStr: string;
    function GetHistory: TKMMapEditorHistory;
  public
    MissionDefSavePath: UnicodeString;

    ActiveMarker: TKMMapEdMarker;

    ResizeMapRect: TKMRect;
    RevealAll: array [0..MAX_HANDS-1] of Boolean;
    DefaultHuman: TKMHandID;
    PlayerHuman: array [0..MAX_HANDS - 1] of Boolean;
    PlayerClassicAI: array [0..MAX_HANDS - 1] of Boolean;
    PlayerAdvancedAI: array [0..MAX_HANDS - 1] of Boolean;

    IsNewMap: Boolean;  // set True for new empty map
    WasSaved: Boolean; // set True when at least 1 map save has been done

    constructor Create(aTerrainPainter: TKMTerrainPainter; aOnHistoryUndoRedo, aOnHistoryAddCheckpoint: TEvent);
    destructor Destroy; override;
    property Deposits: TKMDeposits read fDeposits;
    property Selection: TKMSelection read fSelection;
    property Revealers[aIndex: Byte]: TKMPointTagList read GetRevealer;
    property VisibleLayers: TKMMapEdLayerSet read fVisibleLayers write fVisibleLayers;
    property History: TKMMapEditorHistory read GetHistory write fHistory;

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

    procedure DeletePlayer(aIndex: TKMHandID);
  end;


implementation
uses
  SysUtils, StrUtils, Math,
  KM_Terrain, KM_FileIO,
  KM_AIDefensePos, KM_ResTexts,
  KM_Units, KM_UnitGroup, KM_Houses, KM_HouseCollection, KM_HouseWoodcutters,
  KM_Game, KM_GameCursor, KM_ResMapElements, KM_ResHouses, KM_ResWares, KM_Resource, KM_ResUnits,
  KM_RenderAux, KM_Hand, KM_HandsCollection, KM_InterfaceMapEditor, KM_CommonUtils;

//defines default defence position radius for static AI 
const
  DEFAULT_DEFENCE_POSITION_RADIUS = 20;


{ TKMMapEditor }
constructor TKMMapEditor.Create(aTerrainPainter: TKMTerrainPainter; aOnHistoryUndoRedo, aOnHistoryAddCheckpoint: TEvent);
var
  I: Integer;
begin
  inherited Create;

  MissionDefSavePath := '';

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

  fVisibleLayers := [mlObjects, mlHouses, mlUnits, mlOverlays, mlDeposits];

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


procedure TKMMapEditor.SaveAttachements(const aMissionFile: UnicodeString);
var
  I: Integer;
  MissionPath, MissionNewName, MissionOldName, DestPath: UnicodeString;
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


function TKMMapEditor.OnlyAdvancedAIHand(aHandId: TKMHandID): Boolean;
begin
  Result := PlayerAdvancedAI[aHandId]
    and not PlayerClassicAI[aHandId]
    and not PlayerHuman[aHandId];
end;


function TKMMapEditor.HitTest(X, Y: Integer): TKMMapEdMarker;
var I,K: Integer;
begin
  if mlDefences in fVisibleLayers then
  begin
    for I := 0 to gHands.Count - 1 do
      for K := 0 to gHands[I].AI.General.DefencePositions.Count - 1 do
        if (gHands[I].AI.General.DefencePositions[K].Position.Loc.X = X)
        and (gHands[I].AI.General.DefencePositions[K].Position.Loc.Y = Y) then
        begin
          Result.MarkerType := mtDefence;
          Result.Owner := I;
          Result.Index := K;
          Exit;
        end;
  end;

  if mlRevealFOW in fVisibleLayers then
  begin
    for I := 0 to gHands.Count - 1 do
      for K := 0 to fRevealers[I].Count - 1 do
        if (fRevealers[I][K].X = X) and (fRevealers[I][K].Y = Y) then
        begin
          Result.MarkerType := mtRevealFOW;
          Result.Owner := I;
          Result.Index := K;
          Exit;
        end;
  end;

  //Else nothing is found
  Result.MarkerType := mtNone;
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
      gHands.RemAnyUnit(TKMUnit(Obj).CurrPosition);
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

    //Delete tile object (including corn/wine objects as well)
    if (gTerrain.Land[P.Y,P.X].Obj <> OBJ_NONE) then
    begin
      if isCorn and (gTerrain.GetCornStage(P) in [4,5]) then
      begin
        gTerrain.SetField(P, gTerrain.Land[P.Y,P.X].TileOwner, ftCorn, 3); // For corn, when delete corn object reduce field stage to 3
        removeTxID := TX_WORD_CORN_FIELD;
      end
      else
      if isWine then
      begin
        gTerrain.RemField(P);
        removeTxID := TX_WORD_WINE_FIELD;
      end
      else
      begin
        gTerrain.SetObject(P, OBJ_NONE);
        removeTxID := TX_WORD_OBJECT;
      end;

      fieldsChanged := True; // We deleted smth here
      if not aEraseAll then Exit;
    end;

    //Delete tile overlay (road/corn/wine)
    if gTerrain.Land[P.Y,P.X].TileOverlay = toRoad then
    begin
      if not fieldsChanged then
        removeTxID := TX_WORD_ROAD;

      gTerrain.RemRoad(P);
      fieldsChanged := True;
    end else
    if gTerrain.Land[P.Y,P.X].TileOverlay <> toNone then
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
  if not ChangeObjectOwner(gMySpectator.HitTestCursorWGroup, gMySpectator.HandID) or aChangeOwnerForAll then
    //then try to change owner tile (road/field/wine)
    if ((gTerrain.Land[P.Y, P.X].TileOverlay = toRoad) or (gTerrain.Land[P.Y, P.X].CornOrWine <> 0))
      and (gTerrain.Land[P.Y, P.X].TileOwner <> gMySpectator.HandID) then
    begin
      gTerrain.Land[P.Y, P.X].TileOwner := gMySpectator.HandID;
      fHistory.MakeCheckpoint(caTerrain, Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_CHOWNER_SMTH], [P.ToString, '']));
    end;
end;


//Change owner for specified object
//returns True if owner was changed successfully
function TKMMapEditor.ChangeObjectOwner(aObject: TObject; aOwner: TKMHandID): Boolean;
var
  House: TKMHouse;
begin
  Result := False;
  if (aObject = nil) then Exit;

  if aObject is TKMHouse then
  begin
    House := TKMHouse(aObject);
    if House.Owner <> aOwner then
    begin
      House.OwnerUpdate(aOwner, True);
      gTerrain.SetHouseAreaOwner(House.Position, House.HouseType, aOwner); // Update minimap colors
      Result := True;
      fHistory.MakeCheckpoint(caHouses, Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_CHOWNER_SMTH],
                                               [gRes.Houses[House.HouseType].HouseName, House.Entrance.ToString]));
    end;
  end
  else
  if aObject is TKMUnit then
  begin
    if (TKMUnit(aObject).Owner <> aOwner) and (TKMUnit(aObject).Owner <> PLAYER_ANIMAL) then
    begin
      TKMUnit(aObject).OwnerUpdate(aOwner, True);
      Result := True;
      fHistory.MakeCheckpoint(caUnits, Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_CHOWNER_SMTH],
                                              [gRes.Units[TKMUnit(aObject).UnitType].GUIName,
                                               TKMUnit(aObject).CurrPosition.ToString]));
    end;
  end
  else
  if aObject is TKMUnitGroup then
    if TKMUnitGroup(aObject).Owner <> aOwner then
    begin
      TKMUnitGroup(aObject).OwnerUpdate(aOwner, True);
      Result := True;
      fHistory.MakeCheckpoint(caUnits, Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_CHOWNER_SMTH],
                                              [gRes.Units[TKMUnitGroup(aObject).FlagBearer.UnitType].GUIName,
                                               TKMUnitGroup(aObject).FlagBearer.CurrPosition.ToString]));
    end
end;


procedure TKMMapEditor.MouseWheel(Shift: TShiftState; WheelSteps: Integer; X,Y: Integer);
begin
  UpdateField(WheelSteps, False);
end;


procedure TKMMapEditor.MouseDown(Button: TMouseButton);
begin
  if (Button = mbLeft) then
    case gGameCursor.Mode of
      cmSelection:  fSelection.Selection_Start;
      cmField,
      cmWine:       UpdateField(1, False);
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
  if gTerrain.Land[P.Y,P.X].TileOverlay = toRoad then
  begin
    gTerrain.RemRoad(P);
    fHistory.MakeCheckpoint(caTerrain, Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_REMOVE_SMTH],
                                             [gResTexts[TX_WORD_ROAD], P.ToString]));
  end else
  if gTerrain.Land[P.Y,P.X].TileOverlay <> toNone then
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
    cmSelection:  fSelection.Selection_Resize;
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
      gHands.RemAnyUnit(TKMUnit(Obj).CurrPosition);
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


function TKMMapEditor.GetCheckpointObjectsStr: string;
begin
  if gGameCursor.Tag1 = OBJ_NONE then
    Result := Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_REMOVE_SMTH], [gResTexts[TX_WORD_OBJECT], gGameCursor.Cell.ToString])
  else
    Result := Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_ADD_SMTH] + ' %s', [gResTexts[TX_WORD_OBJECT], IntToStr(gGameCursor.Tag1), gGameCursor.Cell.ToString])
end;


function TKMMapEditor.GetHistory: TKMMapEditorHistory;
begin
  if Self = nil then Exit(nil);
  
  Result := fHistory;
end;


procedure TKMMapEditor.MouseUp(Button: TMouseButton; aOverMap: Boolean);
var
  P: TKMPoint;
begin
  //If the mouse is released over controls, most actions don't happen
  if not aOverMap then
  begin
    //Still need to make a checkpoint since painting has now stopped
    case gGameCursor.Mode of
      cmElevate:  fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_TERRAIN_HEIGHTS_ELEVATE]);
      cmEqualize: fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_TERRAIN_HEIGHTS_UNEQUALIZE]);
      cmBrush:    fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_TERRAIN_BRUSH]);
      cmObjects:  fHistory.MakeCheckpoint(caTerrain, GetCheckpointObjectsStr);
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
                cmBrush:      fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_TERRAIN_BRUSH]);
                cmObjects:    fHistory.MakeCheckpoint(caTerrain, GetCheckpointObjectsStr);
                cmTiles:      fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_TERRAIN_HINTS_TILES] + ' ' + P.ToString);
                cmOverlays:   fHistory.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_TERRAIN_OVERLAYS] + ' ' + P.ToString);
                cmMagicWater: fTerrainPainter.MagicWater(P);
                cmEyedropper: begin
                                fTerrainPainter.Eyedropper(P);
                                if (gGame.ActiveInterface is TKMapEdInterface) then
                                  TKMapEdInterface(gGame.ActiveInterface).GuiTerrain.GuiTiles.TilesTableSetTileTexId(gGameCursor.Tag1);
                                if not (ssShift in gGameCursor.SState) then  //Holding shift allows to choose another tile
                                  gGameCursor.Mode := cmTiles;
                              end;
                cmRotateTile: fTerrainPainter.RotateTile(P);
                cmUnits:      ProceedUnitsCursorMode;
                cmMarkers:    case gGameCursor.Tag1 of
                                MARKER_REVEAL:        fRevealers[gMySpectator.HandID].Add(P, gGameCursor.MapEdSize);
                                MARKER_DEFENCE:       gMySpectator.Hand.AI.General.DefencePositions.Add(KMPointDir(P, dirN), gtMelee, DEFAULT_DEFENCE_POSITION_RADIUS, adtFrontLine);
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
                cmObjects,
                cmEyedropper,
                cmRotateTile: gGameCursor.Mode := cmNone;
              end;
  end;
end;


procedure TKMMapEditor.PaintDefences(aLayer: TKMPaintLayer);
var
  I, K: Integer;
  DP: TAIDefencePosition;
begin
  if mlDefences in fVisibleLayers then
  begin
    case aLayer of
      plCursors:  for I := 0 to gHands.Count - 1 do
                    for K := 0 to gHands[I].AI.General.DefencePositions.Count - 1 do
                    begin
                      DP := gHands[I].AI.General.DefencePositions[K];
                      gRenderPool.RenderSpriteOnTile(DP.Position.Loc, 510 + Byte(DP.Position.Dir), gHands[I].FlagColor);
                    end;
      plTerrain:  if ActiveMarker.MarkerType = mtDefence then
                    //Render the radius only for the selected defence position, otherwise it's too much overlap
                    if InRange(ActiveMarker.Index, 0, gHands[ActiveMarker.Owner].AI.General.DefencePositions.Count - 1) then
                    begin
                      DP := gHands[ActiveMarker.Owner].AI.General.DefencePositions[ActiveMarker.Index];
                      gRenderAux.CircleOnTerrain(DP.Position.Loc.X-0.5, DP.Position.Loc.Y-0.5, DP.Radius,
                                                 gHands[ActiveMarker.Owner].FlagColor AND $40FFFF80,
                                                 gHands[ActiveMarker.Owner].FlagColor);
                    end;
    end;
  end;
end;


procedure TKMMapEditor.PaintRevealFOW(aLayer: TKMPaintLayer);
var
  I, K: Integer;
  Loc: TKMPoint;
begin
  if mlRevealFOW in fVisibleLayers then
    for I := 0 to gHands.Count - 1 do
      for K := 0 to fRevealers[I].Count - 1 do
      begin
        Loc := fRevealers[I][K];
        case aLayer of
          plTerrain:  gRenderAux.CircleOnTerrain(Loc.X-0.5, Loc.Y-0.5,
                                               fRevealers[I].Tag[K],
                                               gHands[I].FlagColor and $20FFFFFF,
                                               gHands[I].FlagColor);
          plCursors:  gRenderPool.RenderSpriteOnTile(Loc,
                          394, gHands[I].FlagColor);
        end;
      end;
end;


procedure TKMMapEditor.PaintCenterScreen(aLayer: TKMPaintLayer);
var
  I: Integer;
  Loc: TKMPoint;
begin
  if mlCenterScreen in fVisibleLayers then
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
  if mlAIStart in fVisibleLayers then
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


procedure TKMMapEditor.PaintMiningRadius(aLayer: TKMPaintLayer);
const
  GOLD_ORE_COLOR = icYellow;
  IRON_ORE_COLOR = icSteelBlue;
  COAL_ORE_COLOR = icGray;
  WOODCUTTER_COLOR = icGreen;
  QUARRY_COLOR = icBlack;
  FISHERHUT_COLOR = icBlue;
  FARM_COLOR = icYellow;
  WINEYARD_COLOR = icLightCyan;
  SELECTED_ORE_COLOR = icLight2Red;

  procedure AddOrePoints(aOreP, aAllOreP: TKMPointListArray);
  var
    I,J,K: Integer;
    Skip: Boolean;
  begin
    for I := 0 to Length(aOreP) - 1 do
    begin
      for J := 0 to aOreP[I].Count - 1 do
      begin
        Skip := False;
        //Skip if we already have this point in upper layer
        for K := 0 to I do
          if aAllOreP[K].Contains(aOreP[I][J]) then
          begin
            Skip := True;
            Break;
          end;
        if not Skip then
        begin
          aAllOreP[I].Add(aOreP[I][J]); //Couild be Add actually, as we checked Contains already
          //Remove added points from lowered layers
          for K := I + 1 to 2 do
            aAllOreP[K].Remove(aOreP[I][J]);
        end;
      end;
    end;
  end;

  procedure PaintOrePoints(aOreP: TKMPointListArray; Color: Cardinal; aHighlight: Boolean = False);
  var
    I, K, L: Integer;
    Color2: Cardinal;
    Coef: Single;
  begin
    Coef := 0.15;
    if aHighlight then
    begin
      Color := SELECTED_ORE_COLOR;
      Coef := 0.3;
    end;

    for I := 1 to Length(aOreP) - 1 do
    begin
      Color := Color and $40FFFFFF; //Add some transparency
      Color := MultiplyBrightnessByFactor(Color, Coef);
      for K := Length(aOreP) - 1 downto 0 do
        for L := 0 to aOreP[K].Count - 1 do
        begin
          Color2 := Color;
          if K = 1 then
            Color2 := MultiplyBrightnessByFactor(Color, 4);
          if K = 2 then
            Color2 := MultiplyBrightnessByFactor(Color, 7);
          gRenderAux.Quad(aOreP[K][L].X, aOreP[K][L].Y, Color2);
        end;
    end;
  end;

  procedure PaintMiningPoints(aPoints: TKMPointList; Color: Cardinal; aHighlight: Boolean = False; aDeepCl: Boolean = False);
  var
    I: Integer;
    Coef: Single;
  begin
    Coef := 0.15;
    if aHighlight then
    begin
      Color := SELECTED_ORE_COLOR;
      Coef := 0.3;
    end;

    if aDeepCl then
      Color := Color and $80FFFFFF //Add some transparency
    else
      Color := Color and $40FFFFFF; //Add more transparency
    Color := MultiplyBrightnessByFactor(Color, Coef);

    for I := 0 to aPoints.Count - 1 do
      gRenderAux.Quad(aPoints[I].X, aPoints[I].Y, Color);
  end;

var
  I, J, K: Integer;
  H: TKMHouse;
  IronOreP, GoldOreP, CoalOreP, OreP, SelectedOreP: TKMPointListArray;
  WoodcutterPts, QuarryPts, FisherHutPts, FarmPts, WineyardPts: TKMPointList;
  HouseDirPts: TKMPointDirList;
  HousePts, SelectedPts: TKMPointList;
begin
  if (mlMiningRadius in fVisibleLayers) and (aLayer = plTerrain) then
  begin
    SetLength(OreP, 3);
    SetLength(IronOreP, 3);
    SetLength(GoldOreP, 3);
    SetLength(CoalOreP, 3);
    SetLength(SelectedOreP, 3);

    for I := 0 to Length(OreP) - 1 do
    begin
      OreP[I] := TKMPointList.Create;
      IronOreP[I] := TKMPointList.Create;
      GoldOreP[I] := TKMPointList.Create;
      CoalOreP[I] := TKMPointList.Create;
      SelectedOreP[I] := TKMPointList.Create;
    end;

    WoodcutterPts := TKMPointList.Create;
    QuarryPts := TKMPointList.Create;
    FisherHutPts := TKMPointList.Create;
    FarmPts := TKMPointList.Create;
    WineyardPts := TKMPointList.Create;
    HousePts := TKMPointList.Create;
    HouseDirPts := TKMPointDirList.Create;
    SelectedPts := TKMPointList.Create;

    for I := 0 to gHands.Count - 1 do
    begin
      for J := 0 to gHands[I].Houses.Count - 1 do
      begin
        HousePts.Clear;
        HouseDirPts.Clear;
        H := gHands[I].Houses[J];
        case H.HouseType of
          htIronMine:   begin
                          gTerrain.FindOrePointsByDistance(H.PointBelowEntrance, wtIronOre, OreP);
                          AddOrePoints(OreP, IronOreP);
                        end;
          htGoldMine:   begin
                          gTerrain.FindOrePointsByDistance(H.PointBelowEntrance, wtGoldOre, OreP);
                          AddOrePoints(OreP, GoldOreP);
                        end;
          htCoalMine:   begin
                          gTerrain.FindOrePointsByDistance(H.PointBelowEntrance, wtCoal, OreP);
                          AddOrePoints(OreP, CoalOreP);
                        end;
          htWoodcutters:begin
                          gTerrain.FindPossibleTreePoints(TKMHouseWoodcutters(H).FlagPoint,
                                                          gRes.Units[utWoodcutter].MiningRange,
                                                          HousePts);
                          WoodcutterPts.AddList(HousePts);
                        end;
          htQuary:      begin
                          gTerrain.FindStoneLocs(H.PointBelowEntrance,
                                                 gRes.Units[utStoneCutter].MiningRange,
                                                 KMPOINT_ZERO, True, HousePts);
                          QuarryPts.AddList(HousePts);
                        end;
          htFisherHut:  begin
                          gTerrain.FindFishWaterLocs(H.PointBelowEntrance,
                                                     gRes.Units[utFisher].MiningRange,
                                                     KMPOINT_ZERO, True, HouseDirPts);
                          HouseDirPts.ToPointList(HousePts, True);
                          FisherHutPts.AddList(HousePts);
                        end;
          htFarm:       begin
                          gTerrain.FindCornFieldLocs(H.PointBelowEntrance,
                                                     gRes.Units[utFarmer].MiningRange,
                                                     HousePts);
                          FarmPts.AddList(HousePts);
                        end;
          htWineyard:   begin
                          gTerrain.FindWineFieldLocs(H.PointBelowEntrance,
                                                     gRes.Units[utFarmer].MiningRange,
                                                     HousePts);
                          WineyardPts.AddList(HousePts);
                        end;
          else Continue;
        end;

        if gMySpectator.Selected = H then
        begin
          if H.HouseType in [htIronMine, htGoldMine, htCoalMine] then
          begin
            for K := 0 to Length(OreP) - 1 do
              SelectedOreP[K].AddList(OreP[K]);
          end
          else
            SelectedPts.AddList(HousePts);
        end;

        for K := 0 to Length(OreP) - 1 do
          OreP[K].Clear;
      end;
    end;

    PaintOrePoints(IronOreP, IRON_ORE_COLOR);
    PaintOrePoints(GoldOreP, GOLD_ORE_COLOR);
    PaintOrePoints(CoalOreP, COAL_ORE_COLOR);
    PaintOrePoints(SelectedOreP, 0, True);

    PaintMiningPoints(WoodcutterPts, WOODCUTTER_COLOR);
    PaintMiningPoints(QuarryPts, QUARRY_COLOR);
    PaintMiningPoints(FisherHutPts, FISHERHUT_COLOR);
    PaintMiningPoints(FarmPts, FARM_COLOR, False, True);
    PaintMiningPoints(WineyardPts, WINEYARD_COLOR);
    PaintMiningPoints(SelectedPts, 0, True);

    for I := 0 to Length(OreP) - 1 do
    begin
      OreP[I].Free;
      IronOreP[I].Free;
      GoldOreP[I].Free;
      CoalOreP[I].Free;
      SelectedOreP[I].Free;
    end;
    WoodcutterPts.Free;
    QuarryPts.Free;
    FisherHutPts.Free;
    FarmPts.Free;
    WineyardPts.Free;
    HousePts.Free;
    HouseDirPts.Free;
    SelectedPts.Free;
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
        or (gTerrain.Land[P.Y,P.X].TileOverlay = toRoad)
        or (gHands.HousesHitTest(P.X, P.Y) <> nil) then
        gRenderPool.RenderWireTile(P, icCyan) //Cyan quad
      else
        gRenderPool.RenderSpriteOnTile(P, TC_BLOCK); //Red X

  PaintDefences(aLayer);
  PaintRevealFOW(aLayer);
  PaintCenterScreen(aLayer);
  PaintAIStart(aLayer);
  PaintMiningRadius(aLayer);

  if mlSelection in fVisibleLayers then
    fSelection.Paint(aLayer, aClipRect);

  if (mlMapResize in fVisibleLayers) and not KMSameRect(ResizeMapRect, KMRECT_ZERO) then
    gRenderAux.RenderResizeMap(ResizeMapRect);

  if mlWaterFlow in fVisibleLayers then
  begin
    for I := aClipRect.Top to aClipRect.Bottom do
    for K := aClipRect.Left to aClipRect.Right do
    if gTerrain.TileIsWater(K,I) then
    begin
      //TODO: Waterflow indication here
      //gRenderPool.RenderSpriteOnTile(KMPoint(K,I), )
    end;
  end;


  //Show selected group order target
  if gMySpectator.Selected is TKMUnitGroup then
  begin
    G := TKMUnitGroup(gMySpectator.Selected);
    if G.MapEdOrder.Order <> ioNoOrder then
    begin
      gRenderAux.Quad(G.MapEdOrder.Pos.Loc.X, G.MapEdOrder.Pos.Loc.Y, $40FF00FF);
      gRenderAux.LineOnTerrain(G.Position.X - 0.5, G.Position.Y - 0.5, G.MapEdOrder.Pos.Loc.X - 0.5, G.MapEdOrder.Pos.Loc.Y - 0.5, $FF0000FF);
    end;
  end;
end;


procedure TKMMapEditor.UpdateState;
begin
  if mlDeposits in VisibleLayers then
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

