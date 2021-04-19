unit KM_MapEdTypes;
{$I KaM_Remake.inc}
interface
uses
  KM_Defaults, KM_ResTileset, KM_TerrainTypes;

type
  TKMMapEdMarkerType = (mmtNone, mmtDefence, mmtRevealFOW);

  TKMMapEdMarker = record
    MarkerType: TKMMapEdMarkerType;
    Owner: TKMHandID;
    Index: SmallInt;
  end;

  TKMMapEdTerrainTile = record
    CornOrWine: Byte; //Indicate Corn or Wine field placed on the tile (without altering terrain)
    CornOrWineTerrain: Byte; //We use fake terrain for maped to be able delete or alter it if needed
  end;

  TKMMapEdLand = array [1..MAX_MAP_SIZE, 1..MAX_MAP_SIZE] of TKMMapEdTerrainTile;

  PKMMapEdLand = ^TKMMapEdLand;

  // same as TKMTerrainLayer, but packed
  TKMTerrainLayerPacked = packed record
    Terrain: Word;
    RotationAndCorners: Byte;
    procedure PackRotNCorners(aRotation: Byte; aCorners: Byte);
    procedure UnpackRotAndCorners(out aRotation: Byte; out aCorners: Byte);
  end;

  //Tile data that we store in undo checkpoints
  //todo: pack UndoTile (f.e. blendingLvl + IsCustom could be packed into 1 byte etc)
  TKMUndoTile = packed record
    BaseLayer: TKMTerrainLayerPacked;
    LayersCnt: Byte;
    Layer: array of TKMTerrainLayerPacked;
    Height: Byte;
    Obj: Word;
    IsCustom: Boolean;
    BlendingLvl: Byte;
    TerKind: TKMTerrainKind;
    Tiles: SmallInt;
    HeightAdd: Byte;
    TileOverlay: TKMTileOverlay;
    TileOwner: TKMHandID;
    FieldAge: Byte;
    CornOrWine: Byte;
    CornOrWineTerrain: Byte;
  end;

  TKMPainterTile = packed record
    TerKind: TKMTerrainKind; //Stores terrain type per node
    Tiles: SmallInt;  //Stores kind of transition tile used, no need to save into MAP footer
    HeightAdd: Byte; //Fraction part of height, for smooth height editing
  end;

  TKMPainterTileArray = array of TKMPainterTile;

  TKMLandTerKind = array of TKMPainterTileArray;

implementation


{ TKMTerrainLayerPacked }
procedure TKMTerrainLayerPacked.PackRotNCorners(aRotation: Byte; aCorners: Byte);
begin
  RotationAndCorners := (aRotation shl 4) or aCorners;
end;


procedure TKMTerrainLayerPacked.UnpackRotAndCorners(out aRotation: Byte; out aCorners: Byte);
begin
  aRotation := RotationAndCorners shr 4;
  aCorners := RotationAndCorners and $F;
end;


end.
 
