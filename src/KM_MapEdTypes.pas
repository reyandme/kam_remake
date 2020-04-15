unit KM_MapEdTypes;
{$I KaM_Remake.inc}
interface
uses
  KM_Defaults, KM_ResTileset, KM_Terrain;

type
  // same as TKMTerrainLayer, but packed
  TKMTerrainLayerPacked = packed record
    Terrain: Word;
    RotationAndCorners: Byte;
    procedure PackRotNCorners(aRotation: Byte; aCorners: TKMTileCorners);
    procedure UnpackRotAndCorners(out aRotation: Byte; out aCorners: TKMTileCorners);
  end;

  //Tile data that we store in undo checkpoints
  //TODO: pack UndoTile (f.e. blendingLvl + IsCustom could be packed into 1 byte etc)
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
  
implementation
uses
  KM_CommonUtils;


{ TKMTerrainLayerPacked }
procedure TKMTerrainLayerPacked.PackRotNCorners(aRotation: Byte; aCorners: TKMTileCorners);
var
  I: Integer;
begin
  RotationAndCorners := aRotation shl 4;
  for I := 0 to 3 do
    RotationAndCorners := RotationAndCorners or (Ord(aCorners[I]) shl I);
end;


procedure TKMTerrainLayerPacked.UnpackRotAndCorners(out aRotation: Byte; out aCorners: TKMTileCorners);
var
  I: Integer;
begin
  aRotation := RotationAndCorners shr 4;
  for I := 0 to 3 do
    aCorners[I] := ToBoolean((RotationAndCorners shr I) and $1);
end;


end.
 