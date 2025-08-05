unit KM_MapEditorHistory;
{$I KaM_Remake.inc}
interface
uses
  Classes, Generics.Collections, SysUtils,
  KM_Defaults, KM_Points, KM_CommonTypes, KM_Houses,
  KM_ResHouses, KM_MapEdTypes, KM_TerrainTypes,
  KM_UnitGroupTypes,
  KM_ResTypes;


type
  TKMCheckpoint = class
  private
    fArea: TKMCheckpointArea;
    fCaption: string;
  public
    constructor Create(const aCaption: string); overload;
    class function FactoryCreate(aArea: TKMCheckpointArea; const aCaption: string): TKMCheckpoint;
    procedure Apply(aArea: TKMCheckpointArea = caAll; aUpdateImmediately: Boolean = True); virtual; abstract;
    property Caption: string read fCaption;
    property Area: TKMCheckpointArea read fArea;
    function CanAdjoin(aArea: TKMCheckpointArea): Boolean; virtual;
    procedure Adjoin; virtual;
  end;

  TKMCheckpointTerrain = class(TKMCheckpoint)
  private
    // Each Undo step stores whole terrain for simplicity (and ease of jumping to random checkpoint in the list)
    fData: array of array of TKMUndoTile;
    function MakeUndoTile(const aTile: TKMTerrainTile; const aPaintedTile: TKMPainterTile; const aMapEdTile: TKMMapEdTerrainTile): TKMUndoTile;
    procedure RestoreTileFromUndo(var aTile: TKMTerrainTile; var aTileExt: TKMTerrainTileExt; var aPaintedTile: TKMPainterTile;
      var aMapEdTile: TKMMapEdTerrainTile; aUndoTile: TKMUndoTile; aUnderHouse: Boolean);
  public
    constructor Create(const aCaption: string);
    procedure Apply(aArea: TKMCheckpointArea = caAll; aUpdateImmediately: Boolean = True); override;
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
//    procedure Apply(aArea: TKMCheckpointArea = caAll; aUpdateImmediately: Boolean = True); override;
//  end;


  TKMCheckpointUnits = class(TKMCheckpoint)
  private
    // Each Undo step stores all units for simplicity (and ease of jumping to random checkpoint in the list)
    fUnits: array of record
      UnitType: TKMUnitType;
      Position: TKMPoint;
      Dir: TKMDirection;
      Owner: TKMHandID;
      Condition: Integer;
      GroupMemberCount: Integer;
      GroupColumns: Integer;
      GroupOrder: TKMMapEdOrder;
	  FishCount: Byte;
    end;
  public
    constructor Create(const aCaption: string);
    procedure Apply(aArea: TKMCheckpointArea = caAll; aUpdateImmediately: Boolean = True); override;
  end;

  TKMCheckpointHouses = class(TKMCheckpoint)
  private
    // Each Undo step stores all houses for simplicity (and ease of jumping to random checkpoint in the list)
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
    procedure Apply(aArea: TKMCheckpointArea = caAll; aUpdateImmediately: Boolean = True); override;
  end;

  // Checkpoint for everything (used for initial state)
  TKMCheckpointAll = class(TKMCheckpoint)
  private
    fAreas: array [TKMCheckpointArea] of TKMCheckpoint;
  public
    constructor Create(const aCaption: string);
    destructor Destroy; override;
    procedure Apply(aArea: TKMCheckpointArea = caAll; aUpdateImmediately: Boolean = True); override;
  end;

  // Terrain helper that is used to undo/redo terrain changes in Map Editor
  TKMMapEditorHistory = class
  private
    // State change counter (to update UI)
    fCounter: Cardinal;

    fCheckpointPos: Integer;
    fCheckpoints: TObjectList<TKMCheckpoint>;

    fOnUndoRedo: TKMEvent;
    fOnAddCheckpoint: TKMEvent;

    function GetPrevAreaCheckpointPos(aPos: Integer; aArea: TKMCheckpointArea): Integer;

    procedure IncCounter;
    procedure UpdateAll;
    procedure JumpToAreas(aIndex: Integer; aAreas: TKMCheckpointAreaSet);
  public
    constructor Create;
    destructor Destroy; override;

    property OnUndoRedo: TKMEvent read fOnUndoRedo write fOnUndoRedo;
    property OnAddCheckpoint: TKMEvent read fOnAddCheckpoint write fOnAddCheckpoint;

    function CanUndo: Boolean;
    function CanRedo: Boolean;
    property Position: Integer read fCheckpointPos;
    property Counter: Cardinal read fCounter;
    procedure GetCheckpoints(aList: TStringList);
    procedure Clear;

    procedure MakeCheckpoint(aArea: TKMCheckpointArea; const aCaption: string);
    procedure JumpTo(aIndex: Integer);
    procedure Undo;
    procedure Redo;
  end;


implementation
uses
  Math,
  KM_HandsCollection, KM_Hand, KM_HandTypes, KM_HandEntity,
  KM_Units, KM_UnitsCollection,
  KM_GameParams, KM_GameSettings,
  KM_Game, KM_CommonUtils, KM_Resource, KM_HouseTownhall, KM_HouseBarracks, KM_HouseStore,
  KM_UnitGroup, KM_Terrain;


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
    fData[I,K] := MakeUndoTile(gTerrain.MainLand^[I+1,K+1],
                               gGame.TerrainPainter.MainLandTerKind[I+1,K+1],
                               gGame.MapEditor.MainLandMapEd^[I+1,K+1]);
end;


function TKMCheckpointTerrain.MakeUndoTile(const aTile: TKMTerrainTile;
                                           const aPaintedTile: TKMPainterTile;
                                           const aMapEdTile: TKMMapEdTerrainTile): TKMUndoTile;
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
  Result.FieldAge           := aTile.FieldAge;
  Result.TileOverlay        := aTile.TileOverlay;
  Result.TileOwner          := aTile.TileOwner;
  Result.CornOrWine         := aMapEdTile.CornOrWine;
  Result.CornOrWineTerrain  := aMapEdTile.CornOrWineTerrain;

  SetLength(Result.Layer, aTile.LayersCnt);
  for L := 0 to aTile.LayersCnt - 1 do
  begin
    Result.Layer[L].Terrain   := aTile.Layer[L].Terrain;
    Result.Layer[L].PackRotNCorners(aTile.Layer[L].Rotation, aTile.Layer[L].Corners);
  end;
end;


procedure TKMCheckpointTerrain.RestoreTileFromUndo(var aTile: TKMTerrainTile; var aTileExt: TKMTerrainTileExt;
                                                   var aPaintedTile: TKMPainterTile; var aMapEdTile: TKMMapEdTerrainTile;
                                                   aUndoTile: TKMUndoTile; aUnderHouse: Boolean);
var
  L: Integer;
begin
  aTile.BaseLayer.Terrain   := aUndoTile.BaseLayer.Terrain;
  aUndoTile.BaseLayer.UnpackRotAndCorners(aTile.BaseLayer.Rotation, aTile.BaseLayer.Corners);

  aTile.LayersCnt               := aUndoTile.LayersCnt;
  aTile.Height                  := aUndoTile.Height;
  aTileExt.RenderHeight         := aTile.GetRenderHeight;
  aTile.Obj                     := aUndoTile.Obj;
  aTile.IsCustom                := aUndoTile.IsCustom;
  aTile.BlendingLvl             := aUndoTile.BlendingLvl;
  aPaintedTile.TerKind          := aUndoTile.TerKind;
  aPaintedTile.Tiles            := aUndoTile.Tiles;
  aPaintedTile.HeightAdd        := aUndoTile.HeightAdd;
  aTile.FieldAge                := aUndoTile.FieldAge;
  aMapEdTile.CornOrWine         := aUndoTile.CornOrWine;
  aMapEdTile.CornOrWineTerrain  := aUndoTile.CornOrWineTerrain;

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


procedure TKMCheckpointTerrain.Apply(aArea: TKMCheckpointArea = caAll; aUpdateImmediately: Boolean = True);
var
  I, K: Integer;
begin
  for I := 0 to gTerrain.MapY-1 do
  for K := 0 to gTerrain.MapX-1 do
    RestoreTileFromUndo(gTerrain.MainLand^[I+1,K+1],
                        gTerrain.LandExt^[I+1,K+1],
                        gGame.TerrainPainter.MainLandTerKind[I+1,K+1],
                        gGame.MapEditor.MainLandMapEd^[I+1,K+1],
                        fData[I,K], gHands.HousesHitTest(K+1,I+1) <> nil);

  if not aUpdateImmediately then Exit;

//  gTerrain.UpdatePassability(gTerrain.MapRect);
//  gTerrain.UpdateLighting(gTerrain.MapRect);

  gTerrain.CallOnMainLand(gTerrain.UpdateAll);
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
//    fData[I,K].Owner    := gTerrain.Land^[I+1,K+1].TileOwner;
//    fData[I,K].Stage    := gTerrain.GetFieldStage(P);
////    fData[I,K].Overlay  := gTerrain.Land^[I+1,K+1].TileOverlay;
//  end;
//end;
//
//
//procedure TKMCheckpointFields.Apply(aArea: TKMCheckpointArea = caAll; aUpdateImmediately: Boolean = True);
//var
//  I, K: Integer;
//  P: TKMPoint;
//begin
//  for I := 0 to gTerrain.MapY-1 do
//  for K := 0 to gTerrain.MapX-1 do
//  begin
//    P := KMPoint(K+1, I+1);
//
////    if gTerrain.Land^[I+1,K+1].TileOwner = HAND_NONE then Continue;
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
//  if not aUpdateImmediately then Exit;
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
      fUnits[L].Position := U.Position;
      fUnits[L].Owner := HAND_ANIMAL;

      fUnits[L].Condition := U.Condition;
      if (U.UnitType = utFish) then
		    fUnits[L].FishCount := TKMUNitFish(U).FishCount;
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
        fUnits[L].Position := U.Position;
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


procedure TKMCheckpointUnits.Apply(aArea: TKMCheckpointArea = caAll; aUpdateImmediately: Boolean = True);
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
	begin
      U := gHands.PlayerAnimals.AddUnit(fUnits[I].UnitType, fUnits[I].Position, False);
      if (U is TKMUNitFish) then
	    TKMUNitFish(U).FishCount := fUnits[I].FishCount;
	end;
    U.Condition := fUnits[I].Condition;
  end;
end;


{ TKMCheckpointHouses }
constructor TKMCheckpointHouses.Create(const aCaption: string);

  procedure AddHouse(aHouse: TKMHouse; var aCount: Integer);
  var
    I: Integer;
    WT: TKMWareType;
    houseSpec: TKMHouseSpec;
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

    houseSpec := gRes.Houses[aHouse.HouseType];

    case aHouse.HouseType of
      htTownHall:   begin
                      fHouses[aCount].WaresIn[0] := TKMHouseTownhall(aHouse).GoldCnt;
                    end;
      htStore:      begin
                      for WT := WARE_MIN to WARE_MAX do
                        fHouses[aCount].WaresIn[Ord(WT) - Ord(WARE_MIN)] := TKMHouseStore(aHouse).CheckWareIn(WT);
                    end;
      htBarracks:   begin
                      fHouses[aCount].WaresIn[0] := TKMHouseBarracks(aHouse).MapEdRecruitCount;
                      for WT := WARFARE_MIN to WARFARE_MAX do
                        fHouses[aCount].WaresIn[Ord(WT) - Ord(WARFARE_MIN) + 1] := TKMHouseBarracks(aHouse).CheckWareIn(WT);
                    end;
      htMarket:     ;
      else          begin
                      for I := 1 to 4 do
                        if houseSpec.WareInput[I] <> wtNone then
                          fHouses[aCount].WaresIn[I-1] := aHouse.CheckWareIn(houseSpec.WareInput[I])
                        else
                          fHouses[aCount].WaresIn[I-1] := 0;

                      for I := 1 to 4 do
                        if houseSpec.WareOutput[I] <> wtNone then
                          fHouses[aCount].WaresOut[I-1] := aHouse.CheckWareOut(houseSpec.WareOutput[I])
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


procedure TKMCheckpointHouses.Apply(aArea: TKMCheckpointArea = caAll; aUpdateImmediately: Boolean = True);
var
  I, K: Integer;
  H: TKMHouse;
  houseSpec: TKMHouseSpec;
  WT: TKMWareType;
begin
  // Remove all houses and apply them anew
  for I := 0 to gHands.Count - 1 do
  begin
    for K := gHands[I].Houses.Count - 1 downto 0 do
      gHands[I].Houses[K].Demolish(I, True);
    gHands[I].Houses.Clear;
  end;

  for I := 0 to High(fHouses) do
  begin
    H := gHands[fHouses[I].Owner].AddHouse(fHouses[I].HouseType, fHouses[I].Position.X, fHouses[I].Position.Y, False);
    H.AddDamage(H.MaxHealth - fHouses[I].Health, nil, True);

    houseSpec := gRes.Houses[fHouses[I].HouseType];
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
                        TKMHouseStore(H).WareAddToIn(WT, fHouses[I].WaresIn[Ord(WT) - Ord(WARE_MIN)]);
                    end;
      htBarracks:   begin
                      TKMHouseBarracks(H).MapEdRecruitCount := fHouses[I].WaresIn[0];
                      for WT := WARFARE_MIN to WARFARE_MAX do
                        TKMHouseBarracks(H).WareAddToIn(WT, fHouses[I].WaresIn[Ord(WT) - Ord(WARFARE_MIN) + 1]);
                    end;
      htMarket:     ;
    else
      // I know, weird, but code within `case of else [..] end` does not need begin/else
      for K := 1 to 4 do
        if houseSpec.WareInput[K] <> wtNone then
          H.WareAddToIn(houseSpec.WareInput[K], fHouses[I].WaresIn[K-1]);

      for K := 1 to 4 do
        if houseSpec.WareOutput[K] <> wtNone then
          H.WareAddToOut(houseSpec.WareOutput[K], fHouses[I].WaresOut[K-1]);
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


procedure TKMCheckpointAll.Apply(aArea: TKMCheckpointArea = caAll; aUpdateImmediately: Boolean = True);
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
    if fCheckpoints.Count >= gGameSettings.MapEdHistoryDepth then
      fCheckpoints.Delete(0);

    // Otherwise create new one
    cp := TKMCheckpoint.FactoryCreate(aArea, aCaption);
    fCheckpoints.Add(cp);
    fCheckpointPos := fCheckpoints.Count - 1;
    IncCounter;
  end;

  if Assigned(fOnAddCheckpoint) then
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


procedure TKMMapEditorHistory.JumpToAreas(aIndex: Integer; aAreas: TKMCheckpointAreaSet);
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
    // Collect areas of checkpoints that should be Undone
    for I := aIndex + 1 to fCheckpointPos do
      areas := areas + [fCheckpoints[I].Area]
  else
    // Collect areas from +1 pos upto index
    for I := fCheckpointPos + 1 to aIndex do
      areas := areas + [fCheckpoints[I].Area];

  JumpToAreas(aIndex, areas);

  if (areas * [caTerrain, caAll]) <> [] then
    UpdateAll;

  if undoRedoNeeded and Assigned(fOnUndoRedo) then
    fOnUndoRedo;
end;


procedure TKMMapEditorHistory.UpdateAll;
begin
  gTerrain.CallOnMainLand(gTerrain.UpdateAll);
end;


procedure TKMMapEditorHistory.Undo;
var
  prev: Integer;
begin
  if not CanUndo then Exit;

  prev := GetPrevAreaCheckpointPos(fCheckpointPos - 1, fCheckpoints[fCheckpointPos].Area);

  Assert(prev >= 0);

  // Apply only requested area (e.g. if we are undoing single change made to Houses at step 87 since editing start)
  fCheckpoints[prev].Apply(fCheckpoints[fCheckpointPos].Area, True);

  Dec(fCheckpointPos);

  IncCounter;

  if Assigned(fOnUndoRedo) then
    fOnUndoRedo;
end;


procedure TKMMapEditorHistory.Redo;
var
  next: Integer;
begin
  if not CanRedo then Exit;

  next := fCheckpointPos + 1;

  Assert(next <= fCheckpoints.Count - 1);

  fCheckpoints[next].Apply(caAll, True);

  fCheckpointPos := next;

  IncCounter;

  if Assigned(fOnUndoRedo) then
    fOnUndoRedo;
end;


end.
