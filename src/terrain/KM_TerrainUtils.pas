unit KM_TerrainUtils;
{$I KaM_Remake.inc}
interface
uses
  KM_Defaults,
  KM_TerrainTypes,
  KM_CommonClasses;


  procedure WriteTileToStream(S: TKMemoryStream; const aTileBasic: TKMTerrainTileBasic; aTileOwner: TKMHandID; aGameSave: Boolean); overload;
  procedure WriteTileToStream(S: TKMemoryStream; const aTileBasic: TKMTerrainTileBasic; aTileOwner: TKMHandID; aGameSave: Boolean; var aMapDataSize: Cardinal); overload;
  procedure ReadTileFromStream(aStream: TKMemoryStream; var aTileBasic: TKMTerrainTileBasic; aGameRev: Integer = 0);


implementation
uses
  Classes,
  KM_Resource, KM_ResSprites,
  KM_HandTypes, KM_ResTypes, KM_ResTilesetTypes;


procedure WriteTileToStream(S: TKMemoryStream; const aTileBasic: TKMTerrainTileBasic; aTileOwner: TKMHandID; aGameSave: Boolean);
var
  mapDataSize: Cardinal;
begin
  WriteTileToStream(S, aTileBasic, aTileOwner, aGameSave, mapDataSize);
end;


procedure WriteTileToStream(S: TKMemoryStream; const aTileBasic: TKMTerrainTileBasic; aTileOwner: TKMHandID;
  aGameSave: Boolean; var aMapDataSize: Cardinal);

  function PackLayersCorners(const aTileBasic: TKMTerrainTileBasic): Byte;
  var
    I, L: Integer;
    layersCnt: Byte;
  begin
    Result := 0;
    //Layers corners are packed into 1 byte.
    //It contains info which layer 'owns' each corner
    //f.e. aCorners[0] contains layer number, which 'own' 0 corner.
    //0-layer means BaseLayer
    layersCnt := 0;
    for I := 3 downto 0 do  // go from 3 to 0, as we pack 3 corner to the most left
    begin
      if aTileBasic.BaseLayer.Corner[I] then
        layersCnt := 0
      else
        for L := 0 to 2 do
          if aTileBasic.Layer[L].Corner[I] then
          begin
            layersCnt := L + 1;
            Break;
          end;
      if I < 3 then //do not shl for first corner
        Result := Result shl 2;
      Result := Result or layersCnt;
    end;
  end;

  //Pack generated terrain id identification info into 2 bytes (Word)
  //6 bits are for terKind       (supports up to 64 terKinds)
  //2 bits for mask subType      (supports up to 4 mask subTypes)
  //4 bits for mask Kind         (supports up to 16 mask kinds)
  //4 bits for mask Type (MType) (supports up to 16 mask types)
  function PackTerrainGenInfo(aGenInfo: TKMGenTerrainInfo): Word;
  begin
    Result := Byte(aGenInfo.TerKind) shl 10;
    Result := Result or (Byte(aGenInfo.Mask.SubType) shl 8);
    Result := Result or (Byte(aGenInfo.Mask.Kind) shl 4);
    Result := Result or Byte(aGenInfo.Mask.MType);
  end;

var
  L: Integer;
  genInfo: TKMGenTerrainInfo;
  overlay: TKMTileOverlay;
begin
  S.Write(aTileBasic.BaseLayer.Terrain);  //1
  //Map file stores terrain, not the fields placed over it, so save OldRotation rather than Rotation
  S.Write(aTileBasic.BaseLayer.Rotation); //3
  S.Write(aTileBasic.Height);             //4
  S.Write(aTileBasic.Obj);                //5
  S.Write(aTileBasic.IsCustom);           //7

  overlay := toNone;
  // Player roads (when tile owner is specified) should not be saved as an overlay, when save .map file
  // since player roads are set for each player in the dat file
  // but they should for a game save or if they are made as an neutral road (so just simple overlay in the map file)
  if aGameSave or (aTileOwner = HAND_NONE) then
    overlay := aTileBasic.TileOverlay;

  S.Write(overlay, SizeOf(overlay)); //8
  S.Write(aTileBasic.LayersCnt);          //9
  Inc(aMapDataSize, 9); // obligatory 9 bytes per tile
  if aTileBasic.LayersCnt > 0 then
  begin
    S.Write(PackLayersCorners(aTileBasic));
    S.Write(aTileBasic.BlendingLvl);
    Inc(aMapDataSize, 2);
    for L := 0 to aTileBasic.LayersCnt - 1 do
    begin
      //We could add more masks and terKinds in future, so we can't stick with generated terrainId,
      //but need to save/load its generation parameters (terKind/mask types etc)
      genInfo := gRes.Sprites.GetGenTerrainInfo(aTileBasic.Layer[L].Terrain);
      S.Write(PackTerrainGenInfo(genInfo));
      S.Write(aTileBasic.Layer[L].Rotation);
      Inc(aMapDataSize, 3); // Terrain (2 bytes) + Rotation (1 byte)
    end;
  end;
end;


procedure ReadTileFromStream(aStream: TKMemoryStream; var aTileBasic: TKMTerrainTileBasic; aGameRev: Integer = 0);

  //Unpack generated terrain id identification info from 2 bytes (Word)
  //6 bits are for terKind       (supports up to 64 terKinds)
  //2 bits for mask subType      (supports up to 4 mask subTypes)
  //4 bits for mask Kind         (supports up to 16 mask kinds)
  //4 bits for mask Type (MType) (supports up to 16 mask types)
  function UnpackTerrainGenInfo(aPackedInfo: Word): TKMGenTerrainInfo;
  begin
    Result.TerKind      := TKMTerrainKind((aPackedInfo shr 10) and 63);
    Result.Mask.SubType := TKMTileMaskSubType((aPackedInfo shr 8) and 3);
    Result.Mask.Kind    := TKMTileMaskKind((aPackedInfo shr 4) and 15);
    Result.Mask.MType   := TKMTileMaskType(aPackedInfo and 15);
  end;

var
  I: Integer;
  terrainB, objectB, rot, corners: Byte;
  layersCorners: array[0..3] of Byte;
  useKaMFormat: Boolean;
  terIdentInfo: Word;
  genInfo: TKMGenTerrainInfo;
begin
  useKaMFormat := (aGameRev = 0);

  if useKaMFormat then
  begin
    aStream.Read(terrainB);           //1
    aTileBasic.BaseLayer.Terrain := terrainB;
    aStream.Seek(1, soFromCurrent);
    aStream.Read(aTileBasic.Height);  //3
    aStream.Read(rot);                //4
    aTileBasic.BaseLayer.Rotation := rot mod 4; //Some original KaM maps have Rot > 3, mod 4 gives right result
    aStream.Seek(1, soFromCurrent);
    aStream.Read(objectB);     //6
    aTileBasic.Obj := objectB;
    aTileBasic.BaseLayer.SetAllCorners;
    aTileBasic.LayersCnt := 0;
    aTileBasic.IsCustom := False;
    aTileBasic.BlendingLvl := TERRAIN_DEF_BLENDING_LVL;
    aTileBasic.TileOverlay := toNone;
  end else begin
    aStream.Read(aTileBasic.BaseLayer.Terrain); //2
    aStream.Read(rot);                          //3
    aTileBasic.BaseLayer.Rotation := rot mod 4; //Some original KaM maps have Rot > 3, mod 4 gives right result
    aStream.Read(aTileBasic.Height);            //4
    aStream.Read(aTileBasic.Obj);               //5
    aStream.Read(aTileBasic.IsCustom);          //7
    aTileBasic.BlendingLvl := TERRAIN_DEF_BLENDING_LVL; //Default value;

    if aGameRev > 10968 then
      aStream.Read(aTileBasic.TileOverlay, SizeOf(aTileBasic.TileOverlay)) //8
    else
      aTileBasic.TileOverlay := toNone;

    // Load all layers info
    // First get layers count
    aStream.Read(aTileBasic.LayersCnt);         //9
    if aTileBasic.LayersCnt = 0 then            // No need to save corners, if we have no layers on that tile
      aTileBasic.BaseLayer.SetAllCorners // Set all corners then
    else begin
      // if there are some layers, then load base layer corners first
      aStream.Read(corners);

      //Layers corners are packed into 1 byte.
      //It contains info which layer 'owns' each corner
      //f.e. aCorners[0] contains layer number, which 'own' 0 corner.
      //0-layer means BaseLayer
      layersCorners[0] := corners and $3;
      layersCorners[1] := (corners shr 2) and $3;
      layersCorners[2] := (corners shr 4) and $3;
      layersCorners[3] := (corners shr 6) and $3;

      if aGameRev > 10745 then //Blending option appeared only after r10745
        aStream.Read(aTileBasic.BlendingLvl)
      else
        aTileBasic.BlendingLvl := TERRAIN_DEF_BLENDING_LVL;

      for I := 0 to aTileBasic.LayersCnt - 1 do
      begin
        if aGameRev <= 10745 then
        begin
          aStream.Read(aTileBasic.Layer[I].Terrain); //Old generated TerrainID
          //Get terrain generation info for pre 10745 maps
          genInfo := gRes.Sprites.GetGenTerrainInfoLegacy(aTileBasic.Layer[I].Terrain);
        end
        else
        begin
          aStream.Read(terIdentInfo); //Read packed info
          genInfo := UnpackTerrainGenInfo(terIdentInfo);
        end;
        //Get current generated terrain id by identification info
        //We could add more masks and terKinds in future, so we can't stick with generated terrainId,
        //but need to save/load its generation parameters (terKind/mask types etc)
        aTileBasic.Layer[I].Terrain := gRes.Sprites.GenTerrainTransitions[genInfo.TerKind, genInfo.Mask.Kind,
                                                                          genInfo.Mask.MType, genInfo.Mask.SubType];
        aStream.Read(aTileBasic.Layer[I].Rotation);
      end;

      aTileBasic.BaseLayer.ClearCorners;
      for I := 0 to 2 do
        aTileBasic.Layer[I].ClearCorners;

      for I := 0 to 3 do
        case layersCorners[I] of
          0:    aTileBasic.BaseLayer.Corner[I] := True;
        else
          aTileBasic.Layer[layersCorners[I]-1].Corner[I] := True;
        end;
    end;
  end;

  if useKaMFormat then
    aStream.Seek(17, soFromCurrent);
end;


end.