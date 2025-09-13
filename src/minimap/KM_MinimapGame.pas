unit KM_MinimapGame;
{$I KaM_Remake.inc}
interface
uses
  KM_Alerts,
  KM_Minimap;

type
  // Minimap loaded from the game terrain
  TKMMinimapGame = class(TKMMinimap)
  private
    fAlerts: TKMAlerts;
    fPaintVirtualGroups: Boolean; //Paint missing army memmbers
  protected
    procedure DoUpdate(aRevealAll: Boolean); override;
  public
    procedure LoadFromTerrain;

    property Alerts: TKMAlerts read fAlerts write fAlerts;
    property PaintVirtualGroups: Boolean read fPaintVirtualGroups write fPaintVirtualGroups;
  end;


implementation
uses
  Math,
  KM_Terrain, KM_TerrainTypes,
  KM_Game, KM_GameParams,
  KM_HandsCollection, KM_Hand, KM_HandTypes, KM_HandEntity,
  KM_Units, KM_UnitGroup,
  KM_Resource, KM_ResUnits,
  KM_Defaults, KM_Points, KM_CommonTypes, KM_CommonUtils,
  KM_DevPerfLog, KM_DevPerfLogTypes;


{ TKMMinimapGame }
procedure TKMMinimapGame.LoadFromTerrain;
var
  I: Integer;
begin
  Resize(gTerrain.MapX - 1, gTerrain.MapY - 1);

  for I := 0 to MAX_HANDS - 1 do
  begin
    HandColors[I] := $00000000;
    HandLocs[I] := KMPOINT_ZERO;
    HandShow[I] := False;
  end;
end;


//MapEditor stores only commanders instead of all groups members
procedure TKMMinimapGame.DoUpdate(aRevealAll: Boolean);
var
  I, J, K, MX, MY, tileID: Integer;
  fow: Byte;
  U: TKMUnit;
  P: TKMPoint;
  doesFit, isBorder, isBorderY: Boolean;
  light: SmallInt;
  group: TKMUnitGroup;
  tileOwner: TKMHandID;
  landPtr: ^TKMTerrainTile;
  col: TKMColor3b;
  gameFlagColors: array[0..MAX_HANDS-1] of Cardinal;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psMinimap);
  {$ENDIF}
  //if OVERLAY_OWNERSHIP then
  //begin
  //  for I := 0 to fMapY - 1 do
  //    for K := 0 to fMapX - 1 do
  //    begin
  //      Owner := gAIFields.Influences.GetBestOwner(K,I);
  //      if Owner <> HAND_NONE then
  //        fBase[I*fMapX + K] := ReduceBrightness(gHands[Owner].FlagColor, Byte(Max(gAIFields.Influences.Ownership[Owner,I,K],0)))
  //      else
  //        fBase[I*fMapX + K] := $FF000000;
  //    end;
  //  Exit;
  //end;

  // Cache flag colors
  for I := 0 to gHands.Count - 1 do
    gameFlagColors[I] := gHands[I].GameFlagColor;

  for I := 0 to fMapY - 1 do
  begin
    MY := I + 1;
    isBorderY := (I = 0) or (I = fMapY - 1);
    for K := 0 to fMapX - 1 do
    begin
      isBorder := isBorderY or (K = 0) or (K = fMapX - 1);
      MX := K + 1;
      fow := gMySpectator.FogOfWar.CheckTileRevelation(MX,MY);

      tileID := I*fMapX + K;

      if fow = 0 then
        fBase[tileID] := $FF000000
      else
      begin
        landPtr := @gTerrain.Land^[MY,MX];
        tileOwner := landPtr.TileOwner;
        if (tileOwner <> -1)
          and gTerrain.TileHasRoad(MX, MY)
          and (landPtr.IsUnit <> nil)
          and not TKMUnit(landPtr.IsUnit).IsAnimal then
          tileOwner := TKMUnit(landPtr.IsUnit).Owner;

        if (tileOwner <> -1)
          and not gTerrain.TileIsCornField(MX, MY) //Do not show corn and wine on minimap
          and not gTerrain.TileIsWineField(MX, MY) then
          fBase[tileID] := gameFlagColors[tileOwner]
        else
        begin
          U := landPtr.IsUnit;
          if U <> nil then
          begin
            if U.IsAnimal then
              fBase[tileID] := gRes.Units[U.UnitType].MinimapColor
            else
              fBase[tileID] := gameFlagColors[U.Owner];
          end
          else
          begin
            // Do not use gTerrain.Land^[].Light for borders of the map, because it is set to -1 for fading effect
            // So assume gTerrain.Land^[].Light as medium value in this case
            if isBorder then
              light := 255 - fow
            else
              light := Round(gTerrain.LandExt[MY,MX].RenderLight * 64) - (255 - fow); //it's -255..255 range now

            col := gRes.Tileset[landPtr.BaseLayer.Terrain].MainColor;
            fBase[tileID] := Byte(EnsureRange(col.R + light, 0, 255)) or
                             Byte(EnsureRange(col.G + light, 0, 255)) shl 8 or
                             Byte(EnsureRange(col.B + light, 0, 255)) shl 16 or $FF000000;
          end;
        end;
      end;
    end;
  end;

  //Scan all players units and paint all virtual group members in MapEd
  if fPaintVirtualGroups then
    for I := 0 to gHands.Count - 1 do
      for K := 0 to gHands[I].UnitGroups.Count - 1 do
      begin
        group := gHands[I].UnitGroups[K];
        for J := 1 to group.MapEdCount - 1 do
        begin
          //GetPositionInGroup2 operates with 1..N terrain, while Minimap uses 0..N-1, hence the +1 -1 fixes
          P := GetPositionInGroup2(group.Position.X, group.Position.Y, group.Direction, J, group.UnitsPerRow, fMapX+1, fMapY+1, doesFit);
          if not doesFit then Continue; //Don't render units that are off the map in the map editor
          fBase[(P.Y - 1) * fMapX + P.X - 1] := gHands[I].FlagColor;
        end;
      end;

  //Draw 'Resize map' feature on minimap
  if (gGame <> nil) and gGameParams.IsMapEditor
    and (melMapResize in gGame.MapEditor.VisibleLayers)
    and not KMSameRect(gGame.MapEditor.ResizeMapRect, KMRECT_ZERO) then
    for I := 0 to fMapY - 1 do
      for K := 0 to fMapX - 1 do
      begin
        if not KMInRect(KMPoint(K+1,I+1), gGame.MapEditor.ResizeMapRect) then
          fBase[I*fMapX + K] := ApplyColorCoef(fBase[I*fMapX + K], 1, 2, 1, 1); // make red margins where current map is cut
      end;

  {$IFDEF PERFLOG}
  gPerfLogs.SectionLeave(psMinimap);
  {$ENDIF}
end;


end.
