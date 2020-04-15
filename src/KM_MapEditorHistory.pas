unit KM_MapEditorHistory;
{$I KaM_Remake.inc}
interface
uses
  Classes, Generics.Collections, SysUtils,
  KM_Defaults, KM_Points, KM_CommonTypes, KM_Houses,
  KM_ResWares, KM_ResHouses, KM_MapEdTypes, KM_Terrain, KM_UnitGroup;


type
  TKMCheckpointArea = (
    caAll,        // Required for initial map state, when we need to Undo everything at once, not "by-area"
    caTerrain,
    caUnits,
    caHouses
//    caFields
    //todo -cPractical: Other areas
    // Dispositions
    // CenterScreen
    // FOW Revealers
    // Hand Flag Color
    //
  );

  TKMCheckpointAreaSet = set of TKMCheckpointArea;

  TKMCheckpoint = class
  private
    fArea: TKMCheckpointArea;
    fCaption: string;
  public
    constructor Create(const aCaption: string); overload;
    class function FactoryCreate(aArea: TKMCheckpointArea; const aCaption: string): TKMCheckpoint;
    procedure Apply(aArea: TKMCheckpointArea = caAll; aUpdateImmidiately: Boolean = True); virtual; abstract;
    property Caption: string read fCaption;
    property Area: TKMCheckpointArea read fArea;
    function CanAdjoin(aArea: TKMCheckpointArea): Boolean; virtual;
    procedure Adjoin; virtual;
  end;

  TKMCheckpointTerrain = class(TKMCheckpoint)
  private
    // Each Undo step stores whole terrain for simplicity
    fData: array of array of TKMUndoTile;
    function MakeUndoTile(aTile: TKMTerrainTile; aPaintedTile: TKMPainterTile): TKMUndoTile;
    procedure RestoreTileFromUndo(var aTile: TKMTerrainTile; var aPaintedTile: TKMPainterTile; aUndoTile: TKMUndoTile;
                                  aUnderHouse: Boolean);
  public
    constructor Create(const aCaption: string);
    procedure Apply(aArea: TKMCheckpointArea = caAll; aUpdateImmidiately: Boolean = True); override;
  end;


//  TKMCheckpointFields = class(TKMCheckpoint)
//  type
//    TKMTerrainFieldRec = record
//      Field: TKMFieldType;
//      Owner: TKMHandID;
//      Stage: Byte;
//      Overlay: TKMTileOverlay;
//    end;
//  private
//    // Each Undo step stores whole terrain for simplicity
//    fData: array of array of TKMTerrainFieldRec;
//  public
//    constructor Create(const aCaption: string);
//    procedure Apply(aArea: TKMCheckpointArea = caAll; aUpdateImmidiately: Boolean = True); override;
//  end;


  TKMCheckpointUnits = class(TKMCheckpoint)
  private
    // Each Undo step stores all units for simplicity
    fUnits: array of record
      UnitType: TKMUnitType;
      Position: TKMPoint;
      Dir: TKMDirection;
      Owner: TKMHandID;
      Condition: Integer;
      GroupMemberCount: Integer;
      GroupColumns: Integer;
      GroupOrder: TKMMapEdOrder;
    end;
  public
    constructor Create(const aCaption: string);
    procedure Apply(aArea: TKMCheckpointArea = caAll; aUpdateImmidiately: Boolean = True); override;
  end;

  TKMCheckpointHouses = class(TKMCheckpoint)
  private
    // Each Undo step stores all houses for simplicity
    fHouses: array of record
      HouseType: TKMHouseType;
      Position: TKMPoint;
      Owner: TKMHandID;
      Health: Integer;
      DeliveryMode: TKMDeliveryMode;
      Repair: Boolean;
      ClosedForWorker: Boolean;
      FlagPoint: TKMPoint;
      PlacedOverRoad: Boolean;
      WaresIn: array [0..Ord(High(TKMWareType))] of Integer;
      WaresOut: array [0..Ord(High(TKMWareType))] of Integer;
    end;
  public
    constructor Create(const aCaption: string);
    procedure Apply(aArea: TKMCheckpointArea = caAll; aUpdateImmidiately: Boolean = True); override;
  end;

  // Checkpoint for everything (used for initial state)
  TKMCheckpointAll = class(TKMCheckpoint)
  private
    fAreas: array [TKMCheckpointArea] of TKMCheckpoint;
  public
    constructor Create(const aCaption: string);
    destructor Destroy; override;
    procedure Apply(aArea: TKMCheckpointArea = caAll; aUpdateImmidiately: Boolean = True); override;
  end;

  // Terrain helper that is used to undo/redo terrain changes in Map Editor
  TKMMapEditorHistory = class
  private
    // State change counter (to update UI)
    fCounter: Cardinal;

    fCheckpointPos: Integer;
    fCheckpoints: TObjectList<TKMCheckpoint>;

    fOnUndoRedo: TEvent;
    fOnAddCheckpoint: TEvent;

    function GetPrevAreaCheckpointPos(aPos: Integer; aArea: TKMCheckpointArea): Integer;

    procedure IncCounter;
    procedure UpdateAll;
    procedure JumpTo(aIndex: Integer; aAreas: TKMCheckpointAreaSet); overload;
  public
    constructor Create;
    destructor Destroy; override;

    property OnUndoRedo: TEvent read fOnUndoRedo write fOnUndoRedo;
    property OnAddCheckpoint: TEvent read fOnAddCheckpoint write fOnAddCheckpoint;

    function CanUndo: Boolean;
    function CanRedo: Boolean;
    property Position: Integer read fCheckpointPos;
    property Counter: Cardinal read fCounter;
    procedure GetCheckpoints(aList: TStringList);
    procedure Clear;

    procedure MakeCheckpoint(aArea: TKMCheckpointArea; const aCaption: string);
    procedure JumpTo(aIndex: Integer); overload;
    procedure Undo(aUpdateImmidiately: Boolean = True);
    procedure Redo(aUpdateImmidiately: Boolean = True);
  end;


implementation
uses
  Math,
  KM_HandsCollection, KM_Hand, KM_Units, KM_UnitsCollection,
  KM_Game, KM_CommonUtils, KM_Resource, KM_HouseTownhall, KM_HouseBarracks;

const
  CHECKPOINTS_MAX_CNT = 500;


{ TKMCheckpoint }
constructor TKMCheckpoint.Create(const aCaption: string);
begin
  inherited Create;

  fCaption := aCaption;
end;


class function TKMCheckpoint.FactoryCreate(aArea: TKMCheckpointArea; const aCaption: string): TKMCheckpoint;
begin
  case aArea of
    caAll:        Result := TKMCheckpointAll.Create(aCaption);
    caTerrain:    Result := TKMCheckpointTerrain.Create(aCaption);
//    caFields:     Result := TKMCheckpointFields.Create(aCaption);
    caUnits:      Result := TKMCheckpointUnits.Create(aCaption);
    caHouses:     Result := TKMCheckpointHouses.Create(aCaption);
  else
    raise Exception.Create('Error Message');
  end;
end;


function TKMCheckpoint.CanAdjoin(aArea: TKMCheckpointArea): Boolean;
begin
  Result := False; // Typically not available
end;


procedure TKMCheckpoint.Adjoin;
begin
  // Do nothing as it is typically not available
end;


{ TKMCheckpointTerrain }
constructor TKMCheckpointTerrain.Create(const aCaption: string);
var
  I, K: Integer;
begin
  inherited Create(aCaption);

  fArea := caTerrain;

  SetLength(fData, gTerrain.MapY, gTerrain.MapX);

  for I := 0 to gTerrain.MapY - 1 do
  for K := 0 to gTerrain.MapX - 1 do
    fData[I,K] := MakeUndoTile(gTerrain.Land[I+1,K+1], gGame.TerrainPainter.LandTerKind[I+1,K+1]);
end;


function TKMCheckpointTerrain.MakeUndoTile(aTile: TKMTerrainTile; aPaintedTile: TKMPainterTile): TKMUndoTile;
var
  L: Integer;
begin
  Result.BaseLayer.Terrain   := aTile.BaseLayer.Terrain;
  Result.BaseLayer.PackRotNCorners(aTile.BaseLayer.Rotation, aTile.BaseLayer.Corners);

  Result.LayersCnt          := aTile.LayersCnt;
  Result.Height             := aTile.Height;
  Result.Obj                := aTile.Obj;
  Result.IsCustom           := aTile.IsCustom;
  Result.BlendingLvl        := aTile.BlendingLvl;
  Result.TerKind            := aPaintedTile.TerKind;
  Result.Tiles              := aPaintedTile.Tiles;
  Result.HeightAdd          := aPaintedTile.HeightAdd;
  Result.TileOverlay        := aTile.TileOverlay;
  Result.TileOwner          := aTile.TileOwner;
  Result.CornOrWine         := aTile.CornOrWine;
  Result.CornOrWineTerrain  := aTile.CornOrWineTerrain;

  SetLength(Result.Layer, aTile.LayersCnt);
  for L := 0 to aTile.LayersCnt - 1 do
  begin
    Result.Layer[L].Terrain   := aTile.Layer[L].Terrain;
    Result.Layer[L].PackRotNCorners(aTile.Layer[L].Rotation, aTile.Layer[L].Corners);
  end;
end;


procedure TKMCheckpointTerrain.RestoreTileFromUndo(var aTile: TKMTerrainTile; var aPaintedTile: TKMPainterTile;
                                                   aUndoTile: TKMUndoTile; aUnderHouse: Boolean);
var
  L: Integer;
begin
  aTile.BaseLayer.Terrain   := aUndoTile.BaseLayer.Terrain;
  aUndoTile.BaseLayer.UnpackRotAndCorners(aTile.BaseLayer.Rotation, aTile.BaseLayer.Corners);

  aTile.LayersCnt           := aUndoTile.LayersCnt;
  aTile.Height              := aUndoTile.Height;
  aTile.Obj                 := aUndoTile.Obj;
  aTile.IsCustom            := aUndoTile.IsCustom;
  aTile.BlendingLvl         := aUndoTile.BlendingLvl;
  aPaintedTile.TerKind      := aUndoTile.TerKind;
  aPaintedTile.Tiles        := aUndoTile.Tiles;
  aPaintedTile.HeightAdd    := aUndoTile.HeightAdd;
  aTile.FieldAge            := aUndoTile.FieldAge;
  aTile.CornOrWine          := aUndoTile.CornOrWine;
  aTile.CornOrWineTerrain   := aUndoTile.CornOrWineTerrain;

  // Do not remove roads under houses and do not update owner under house
  if not aUnderHouse then
  begin
    aTile.TileOverlay       := aUndoTile.TileOverlay;
    aTile.TileOwner         := aUndoTile.TileOwner;
  end;

  for L := 0 to aUndoTile.LayersCnt - 1 do
  begin
    aTile.Layer[L].Terrain  := aUndoTile.Layer[L].Terrain;
    aUndoTile.Layer[L].UnpackRotAndCorners(aTile.Layer[L].Rotation, aTile.Layer[L].Corners);
  end;
end;


procedure TKMCheckpointTerrain.Apply(aArea: TKMCheckpointArea = caAll; aUpdateImmidiately: Boolean = True);
var
  I, K: Integer;
begin
  for I := 0 to gTerrain.MapY-1 do
  for K := 0 to gTerrain.MapX-1 do
    RestoreTileFromUndo(gTerrain.Land[I+1,K+1], gGame.TerrainPainter.LandTerKind[I+1,K+1], fData[I,K],
                        gHands.HousesHitTest(K+1,I+1) <> nil);

  if not aUpdateImmidiately then Exit;

//  gTerrain.UpdatePassability(gTerrain.MapRect);
//  gTerrain.UpdateLighting(gTerrain.MapRect);
  gTerrain.UpdateAll(gTerrain.MapRect);
end;



{ TKMCheckpointFields }
//constructor TKMCheckpointFields.Create(const aCaption: string);
//var
//  I, K: Integer;
//  P: TKMPoint;
//begin
//  inherited Create(aCaption);
//
//  fArea := caFields;
//
//  SetLength(fData, gTerrain.MapY, gTerrain.MapX);
//
//  for I := 0 to gTerrain.MapY-1 do
//  for K := 0 to gTerrain.MapX-1 do
//  begin
//    P := KMPoint(K+1,I+1);
//    fData[I,K].Field    := gTerrain.GetFieldType(P);
//    fData[I,K].Owner    := gTerrain.Land[I+1,K+1].TileOwner;
//    fData[I,K].Stage    := gTerrain.GetFieldStage(P);
////    fData[I,K].Overlay  := gTerrain.Land[I+1,K+1].TileOverlay;
//  end;
//end;
//
//
//procedure TKMCheckpointFields.Apply(aArea: TKMCheckpointArea = caAll; aUpdateImmidiately: Boolean = True);
//var
//  I, K: Integer;
//  P: TKMPoint;
//begin
//  for I := 0 to gTerrain.MapY-1 do
//  for K := 0 to gTerrain.MapX-1 do
//  begin
//    P := KMPoint(K+1, I+1);
//
////    if gTerrain.Land[I+1,K+1].TileOwner = PLAYER_NONE then Continue;
//
//    // Do not remove roads under houses
//    if (gHands.HousesHitTest(K+1,I+1) = nil) then
//      gTerrain.RemField(P, False, False, False); //Remove all fields first (without any updates)
//
//    case fData[I,K].Field of
//      ftNone: ;
//      ftRoad: gTerrain.SetRoad(P, fData[I,K].Owner, False);
//      ftCorn,
//      ftWine: gTerrain.SetFieldNoUpdate(P, fData[I,K].Owner, fData[I,K].Field, fData[I,K].Stage);
//    end;
//  end;
//
//  if not aUpdateImmidiately then Exit;
//
//  gTerrain.UpdatePassability(gTerrain.MapRect);
//  gTerrain.UpdateFences(gTerrain.MapRect);
//end;


{ TKMCheckpointUnits }
constructor TKMCheckpointUnits.Create(const aCaption: string);
var
  I, K, L: Integer;
  unitCount: Integer;
  U: TKMUnit;
  G: TKMUnitGroup;
begin
  inherited Create(aCaption);

  fArea := caUnits;

  unitCount := gHands.PlayerAnimals.Units.Count;
  for I := 0 to gHands.Count - 1 do
    Inc(unitCount, gHands[I].Units.Count);

  L := 0;
  SetLength(fUnits, unitCount);

  // Animals
  for K := 0 to gHands.PlayerAnimals.Units.Count - 1 do
  begin
    U := gHands.PlayerAnimals.Units[K];
    if (U.UnitType in [ANIMAL_MIN..ANIMAL_MAX])
      and not gHands.PlayerAnimals.Units[K].IsDeadOrDying then
    begin
      fUnits[L].UnitType := U.UnitType;
      fUnits[L].Position := U.CurrPosition;
      fUnits[L].Owner := PLAYER_ANIMAL;

      fUnits[L].Condition := U.Condition;

      Inc(L);
    end;
  end;

  for I := 0 to gHands.Count - 1 do
  begin
    // Units
    for K := 0 to gHands[I].Units.Count - 1 do
    if not gHands[I].Units[K].IsDeadOrDying then
    begin
      U := gHands[I].Units[K];
      if U.UnitType in [CITIZEN_MIN..CITIZEN_MAX] then
      begin
        fUnits[L].UnitType := U.UnitType;
        fUnits[L].Position := U.CurrPosition;
        fUnits[L].Owner := I;

        fUnits[L].Condition := U.Condition;

        Inc(L);
      end;
    end;

    // Groups
    for K := 0 to gHands[I].UnitGroups.Count - 1 do
    if not gHands[I].UnitGroups[K].IsDead then
    begin
      G := gHands[I].UnitGroups[K];
      fUnits[L].UnitType := G.UnitType;
      fUnits[L].Position := G.Position;
      fUnits[L].Dir := G.Direction;
      fUnits[L].Owner := I;
      fUnits[L].Condition := G.Condition;

      fUnits[L].GroupMemberCount := G.MapEdCount;
      fUnits[L].GroupColumns := G.UnitsPerRow;
      fUnits[L].GroupOrder := G.MapEdOrder;

      Inc(L);
    end;
  end;

  // Trim to actual length (which is always smaller due to erased(dead) units)
  SetLength(fUnits, L);
end;


procedure TKMCheckpointUnits.Apply(aArea: TKMCheckpointArea = caAll; aUpdateImmidiately: Boolean = True);
var
  I: Integer;
  U: TKMUnit;
  G: TKMUnitGroup;
begin
  gHands.PlayerAnimals.Units.Clear;
  for I := 0 to gHands.Count - 1 do
  begin
    gHands[I].UnitGroups.Clear;
    gHands[I].Units.Clear;
  end;

  for I := 0 to High(fUnits) do
  begin
    if fUnits[I].UnitType in [CITIZEN_MIN..CITIZEN_MAX] then
      U := gHands[fUnits[I].Owner].AddUnit(fUnits[I].UnitType, fUnits[I].Position, False, 0, False, False)
    else
    if fUnits[I].UnitType in [WARRIOR_MIN..WARRIOR_MAX] then
    begin
      G := gHands[fUnits[I].Owner].AddUnitGroup(fUnits[I].UnitType, fUnits[I].Position, fUnits[I].Dir, 1, 1, False);
      U := G.FlagBearer;
      G.MapEdCount := fUnits[I].GroupMemberCount;
      G.UnitsPerRow := fUnits[I].GroupColumns;
      G.MapEdOrder := fUnits[I].GroupOrder;
    end
    else
      U := gHands.PlayerAnimals.AddUnit(fUnits[I].UnitType, fUnits[I].Position, False);

    U.Condition := fUnits[I].Condition;
  end;
end;


{ TKMCheckpointHouses }
constructor TKMCheckpointHouses.Create(const aCaption: string);
  procedure AddHouse(aHouse: TKMHouse; var aCount: Integer);
  var
    I: Integer;
    WT: TKMWareType;
    spec: TKMHouseSpec;
  begin
    fHouses[aCount].HouseType := aHouse.HouseType;
    fHouses[aCount].Position := aHouse.Position;
    fHouses[aCount].Owner := aHouse.Owner;
    fHouses[aCount].Health := aHouse.GetHealth;
    fHouses[aCount].DeliveryMode := aHouse.DeliveryMode;
    fHouses[aCount].Repair := aHouse.BuildingRepair;
    fHouses[aCount].ClosedForWorker := aHouse.IsClosedForWorker;
    fHouses[aCount].PlacedOverRoad := aHouse.PlacedOverRoad;

    if aHouse is TKMHouseWFlagPoint then
      fHouses[aCount].FlagPoint := TKMHouseWFlagPoint(aHouse).FlagPoint;

    spec := gRes.Houses[aHouse.HouseType];

    case aHouse.HouseType of
      htTownHall:   begin
                      fHouses[aCount].WaresIn[0] := TKMHouseTownhall(aHouse).GoldCnt;
                    end;
      htStore:      begin
                      for WT := WARE_MIN to WARE_MAX do
                        fHouses[aCount].WaresIn[Ord(WT) - Ord(WARE_MIN)] := TKMHouseStore(aHouse).CheckResIn(WT);
                    end;
      htBarracks:   begin
                      fHouses[aCount].WaresIn[0] := TKMHouseBarracks(aHouse).MapEdRecruitCount;
                      for WT := WARFARE_MIN to WARFARE_MAX do
                        fHouses[aCount].WaresIn[Ord(WT) - Ord(WARFARE_MIN) + 1] := TKMHouseBarracks(aHouse).CheckResIn(WT);
                    end;
      htMarketplace:;
      else          begin
                      for I := 1 to 4 do
                        if spec.ResInput[I] <> wtNone then
                          fHouses[aCount].WaresIn[I-1] := aHouse.CheckResIn(spec.ResInput[I])
                        else
                          fHouses[aCount].WaresIn[I-1] := 0;

                      for I := 1 to 4 do
                        if spec.ResOutput[I] <> wtNone then
                          fHouses[aCount].WaresOut[I-1] := aHouse.CheckResOut(spec.ResOutput[I])
                        else
                          fHouses[aCount].WaresOut[I-1] := 0;
                    end;
    end;

    Inc(aCount);
  end;
var
  I, K, houseCount: Integer;
begin
  inherited Create(aCaption);

  fArea := caHouses;

  houseCount := 0;
  for I := 0 to gHands.Count - 1 do
    Inc(houseCount, gHands[I].Houses.Count);
  SetLength(fHouses, houseCount);
  houseCount := 0;

  for I := 0 to gHands.Count - 1 do
  for K := 0 to gHands[I].Houses.Count - 1 do
  if not gHands[I].Houses[K].IsDestroyed then
    AddHouse(gHands[I].Houses[K], houseCount);

  // Trim to actual length (which is always smaller due to erased(dead) Houses)
  SetLength(fHouses, houseCount);
end;


procedure TKMCheckpointHouses.Apply(aArea: TKMCheckpointArea = caAll; aUpdateImmidiately: Boolean = True);
var
  I, K: Integer;
  H: TKMHouse;
  spec: TKMHouseSpec;
  WT: TKMWareType;
begin
  // Remove all houses and apply them anew
  for I := 0 to gHands.Count - 1 do
  begin
    for K := gHands[I].Houses.Count - 1 downto 0 do
      gHands[I].Houses[K].DemolishHouse(I, True);
    gHands[I].Houses.Clear;
  end;

  for I := 0 to High(fHouses) do
  begin
    H := gHands[fHouses[I].Owner].AddHouse(fHouses[I].HouseType, fHouses[I].Position.X, fHouses[I].Position.Y, False);
    H.AddDamage(H.MaxHealth - fHouses[I].Health, nil, True);

    spec := gRes.Houses[fHouses[I].HouseType];
    H.SetDeliveryModeInstantly(fHouses[I].DeliveryMode);
    H.BuildingRepair := fHouses[I].Repair;
    H.IsClosedForWorker := fHouses[I].ClosedForWorker;
    H.PlacedOverRoad := fHouses[I].PlacedOverRoad;

    if H is TKMHouseWFlagPoint then
      TKMHouseWFlagPoint(H).FlagPoint := fHouses[I].FlagPoint;

    case H.HouseType of
      htTownHall:   begin
                      TKMHouseTownhall(H).GoldCnt := fHouses[I].WaresIn[0];
                    end;
      htStore:      begin
                      for WT := WARE_MIN to WARE_MAX do
                        TKMHouseStore(H).ResAddToIn(WT, fHouses[I].WaresIn[Ord(WT) - Ord(WARE_MIN)]);
                    end;
      htBarracks:   begin
                      TKMHouseBarracks(H).MapEdRecruitCount := fHouses[I].WaresIn[0];
                      for WT := WARFARE_MIN to WARFARE_MAX do
                        TKMHouseBarracks(H).ResAddToIn(WT, fHouses[I].WaresIn[Ord(WT) - Ord(WARFARE_MIN) + 1]);
                    end;
      htMarketplace:;
      else          begin
                      for K := 1 to 4 do
                        if spec.ResInput[K] <> wtNone then
                          H.ResAddToIn(spec.ResInput[K], fHouses[I].WaresIn[K-1]);

                      for K := 1 to 4 do
                        if spec.ResOutput[K] <> wtNone then
                          H.ResAddToOut(spec.ResOutput[K], fHouses[I].WaresOut[K-1]);
                    end;
    end;
  end;
end;


{ TKMCheckpointAll }
constructor TKMCheckpointAll.Create(const aCaption: string);
var
  I: TKMCheckpointArea;
begin
  inherited Create(aCaption);

  fArea := caAll;

  for I := Low(TKMCheckpointArea) to High(TKMCheckpointArea) do
  if I <> caAll then
    fAreas[I] := TKMCheckpoint.FactoryCreate(I, aCaption);
end;


destructor TKMCheckpointAll.Destroy;
var
  I: TKMCheckpointArea;
begin
  for I := Low(TKMCheckpointArea) to High(TKMCheckpointArea) do
    if I <> caAll then
      fAreas[I].Free;

  inherited;
end;


procedure TKMCheckpointAll.Apply(aArea: TKMCheckpointArea = caAll; aUpdateImmidiately: Boolean = True);
var
  I: TKMCheckpointArea;
begin
  for I := Low(TKMCheckpointArea) to High(TKMCheckpointArea) do
  if (I <> caAll) and ((aArea = caAll) or (I = aArea)) then
    fAreas[I].Apply;
end;


{ TKMMapEditorHistory }
constructor TKMMapEditorHistory.Create;
begin
  inherited;

  fCheckpoints := TObjectList<TKMCheckpoint>.Create;
end;


destructor TKMMapEditorHistory.Destroy;
begin
  fCheckpoints.Free;

  inherited;
end;


procedure TKMMapEditorHistory.MakeCheckpoint(aArea: TKMCheckpointArea; const aCaption: string);
var
  cp: TKMCheckpoint;
begin
  if Self = nil then Exit;

  // Delete all Redo checkpoints, as they've become invalid with this new change
  while fCheckpointPos < fCheckpoints.Count - 1 do
    fCheckpoints.Delete(fCheckpoints.Count - 1);

  // Register change
  if (fCheckpoints.Count > 0) and fCheckpoints.Last.CanAdjoin(aArea) then
  begin
    // Sometimes we can adjoin checkpoints
    fCheckpoints.Last.Adjoin;
  end else
  begin
    // Delete the very first checkpoint when we reached the limit
    if fCheckpoints.Count >= CHECKPOINTS_MAX_CNT then
      fCheckpoints.Delete(0);

    // Otherwise create new one
    cp := TKMCheckpoint.FactoryCreate(aArea, aCaption);
    fCheckpoints.Add(cp);
    fCheckpointPos := fCheckpoints.Count - 1;
    IncCounter;
  end;

  if Assigned (fOnAddCheckpoint) then
    fOnAddCheckpoint;
end;


function TKMMapEditorHistory.CanUndo: Boolean;
begin
  Result := fCheckpointPos > 0;
end;


function TKMMapEditorHistory.CanRedo: Boolean;
begin
  Result := fCheckpointPos < fCheckpoints.Count - 1;
end;


procedure TKMMapEditorHistory.Clear;
begin
  fCheckpoints.Clear;
  fCounter := 0;
  fCheckpointPos := 0;
end;


// Get list of available checkpoints (tag current/prev/next with a color)
procedure TKMMapEditorHistory.GetCheckpoints(aList: TStringList);
var
  I: Integer;
  s: string;
begin
  if (Self = nil) or (aList = nil) then Exit;

  aList.Clear;

  for I := 0 to fCheckpoints.Count - 1 do
  begin
    s := IntToStr(I + 1) + '. ' + fCheckpoints[I].Caption;
    
    // Undo checkpoints are white (no color-wrap)
    // Current checkpoint highlighted in yellow
    // Redo checkpoints highlighted in light-grey
    if I = fCheckpointPos then
      s := WrapColor(s, $88FFFF)
    else
    if I > fCheckpointPos then
      s := WrapColor(s, $AAAAAA);

    aList.Append(s);
  end;
end;


procedure TKMMapEditorHistory.IncCounter;
begin
  Inc(fCounter);
end;


function TKMMapEditorHistory.GetPrevAreaCheckpointPos(aPos: Integer; aArea: TKMCheckpointArea): Integer;
begin
  if aPos <= 0 then Exit(0);

  // Find previous state of area we are undoing ("Initial" state at 0 being our last chance)
  Result := aPos;
  while Result > 0 do
  begin
    if fCheckpoints[Result].Area = aArea then
      Break;
    Dec(Result);
  end;
end;


procedure TKMMapEditorHistory.JumpTo(aIndex: Integer; aAreas: TKMCheckpointAreaSet);
var
  A: TKMCheckpointArea;
  prev: Integer;
begin
  for A in aAreas do
  begin
    if A = caAll then
      prev := 0
    else
      prev := GetPrevAreaCheckpointPos(aIndex, A);

    fCheckpoints[prev].Apply(A, False);
    fCheckpointPos := aIndex;
    IncCounter;
  end;
end;


procedure TKMMapEditorHistory.JumpTo(aIndex: Integer);
var
  I: Integer;
  undoRedoNeeded: Boolean;
  areas: TKMCheckpointAreaSet;
begin
  aIndex := EnsureRange(aIndex, 0, fCheckpoints.Count - 1);
  undoRedoNeeded := (aIndex <> fCheckpointPos);

  if not undoRedoNeeded then Exit;

  areas := [];
  if aIndex < fCheckpointPos then
    for I := aIndex + 1 to fCheckpointPos do //Collect areas of checkpoints that should be Undone
      areas := areas + [fCheckpoints[I].Area]
  else
  for I := fCheckpointPos + 1 to aIndex do // Collect areas from +1 pos upto index
    areas := areas + [fCheckpoints[I].Area];

  JumpTo(aIndex, areas);

  if (areas * [caTerrain, caAll]) <> [] then
      UpdateAll;

  if undoRedoNeeded and Assigned(fOnUndoRedo) then
    fOnUndoRedo;
end;


procedure TKMMapEditorHistory.UpdateAll;
begin
  gTerrain.UpdateAll(gTerrain.MapRect);
end;


procedure TKMMapEditorHistory.Undo(aUpdateImmidiately: Boolean = True);
var
  prev: Integer;
begin
  if not CanUndo then Exit;

  prev := GetPrevAreaCheckpointPos(fCheckpointPos - 1, fCheckpoints[fCheckpointPos].Area);

  Assert(prev >= 0);

  // Apply only requested area (e.g. if we are undoing single change made to Houses at step 87 since editing start)
  fCheckpoints[prev].Apply(fCheckpoints[fCheckpointPos].Area, aUpdateImmidiately);

  Dec(fCheckpointPos);

  IncCounter;

  if aUpdateImmidiately and Assigned(fOnUndoRedo) then
    fOnUndoRedo;
end;


procedure TKMMapEditorHistory.Redo(aUpdateImmidiately: Boolean = True);
var
  next: Integer;
begin
  if not CanRedo then Exit;

  next := fCheckpointPos + 1;

  Assert(next <= fCheckpoints.Count - 1);

  fCheckpoints[next].Apply(caAll, aUpdateImmidiately);

  fCheckpointPos := next;

  IncCounter;

  if aUpdateImmidiately and Assigned(fOnUndoRedo) then
    fOnUndoRedo;
end;


end.
