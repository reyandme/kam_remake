unit KM_MinimapMission;
{$I KaM_Remake.inc}
interface
uses
  KM_Minimap,
  KM_MissionScript_Preview,
  KM_Defaults;

type
  // Minimap loaded from the mission .map / .dat files via parser
  TKMMinimapMission = class(TKMMinimap)
  private
    fParser: TKMMissionParserPreview;
  protected
    procedure DoUpdate(aRevealAll: Boolean); override;
  public
    constructor Create(aSepia: Boolean);
    destructor Destroy; override;

    procedure LoadFromMission(const aMissionPath: string; const aRevealFor: array of TKMHandID);
  end;


implementation
uses
  SysUtils, Math,
  KM_Resource,
  KM_HandTypes;


{ TKMMinimapMission }
constructor TKMMinimapMission.Create(aSepia: Boolean);
begin
  inherited Create(aSepia);

  fParser := TKMMissionParserPreview.Create;
end;


destructor TKMMinimapMission.Destroy;
begin
  FreeAndNil(fParser);

  inherited;
end;


// Load map in a direct way, should be used only when in Menu
// aMissionPath - path to .dat file
procedure TKMMinimapMission.LoadFromMission(const aMissionPath: string; const aRevealFor: array of TKMHandID);
var
  I: Integer;
begin
  fParser.LoadMission(aMissionPath, aRevealFor);

  Resize(fParser.MapX - 1, fParser.MapY - 1);

  for I := 0 to MAX_HANDS - 1 do
  begin
    HandColors[I] := fParser.PlayerPreview[I].Color;
    HandLocs[I] := fParser.PlayerPreview[I].StartingLoc;
    HandShow[I] := fParser.PlayerPreview[I].CanHuman;
  end;
end;


procedure TKMMinimapMission.DoUpdate(aRevealAll: Boolean);
var
  I, K, N: Integer;
  light: SmallInt;
  x0,y2: Word;
begin
  for I := 1 to fMapY do
  for K := 1 to fMapX do
    with fParser.MapPreview[K,I] do
    begin
      N := (I-1) * fMapX + (K-1);
      if not aRevealAll and not Revealed then
        fBase[N] := $E0000000
      else
        if TileOwner <> HAND_NONE then
          fBase[N] := HandColors[TileOwner]
        else
        begin
          //Formula for lighting is the same as in TTerrain.RebuildLighting
          x0 := Max(K-1, 1);
          y2 := Min(I+1, fMapY);
          light := Round(EnsureRange((TileHeight - (fParser.MapPreview[K,y2].TileHeight + fParser.MapPreview[x0,I].TileHeight)/2)/22, -1, 1)*64);
          fBase[N] := Byte(EnsureRange(gRes.Tileset[TileID].MainColor.R+light, 0, 255)) +
                      Byte(EnsureRange(gRes.Tileset[TileID].MainColor.G+light, 0, 255)) shl 8 +
                      Byte(EnsureRange(gRes.Tileset[TileID].MainColor.B+light, 0, 255)) shl 16 or $FF000000;
        end;
    end;
end;

end.
