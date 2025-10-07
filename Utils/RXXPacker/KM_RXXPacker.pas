unit KM_RXXPacker;
{$I ..\..\KaM_Remake.inc}
interface
uses
  SysUtils, Windows, Generics.Collections,
  KM_ResTypes, KM_ResPalettes, KM_ResSprites;


type
  TKMRXXPacker = class
  private
    fSourcePathRX: string;
    fSourcePathInterp: string;
    fDestinationPath: string;

    procedure Pack(aRT: TRXType; aPalettes: TKMResPalettes; aOnMessage: TProc<string>);
    procedure SetDestinationPath(const aValue: string);
    procedure SetSourcePathInterp(const aValue: string);
    procedure SetSourcePathRX(const aValue: string);
  public
    PackToRXX: Boolean;
    PackToRXA: Boolean;
    RXXFormat: TKMRXXFormat;

    constructor Create;

    procedure PackSet(aRxSet: TRXTypeSet; aPalettes: TKMResPalettes; aOnMessage: TProc<string>);

    property SourcePathRX: string read fSourcePathRX write SetSourcePathRX;
    property SourcePathInterp: string read fSourcePathInterp write SetSourcePathInterp;
    property DestinationPath: string read fDestinationPath write SetDestinationPath;

    class function GetAvailableToPack(const aPath: string): TRXTypeSet;
  end;


implementation
uses
  KM_ResHouses, KM_ResUnits, KM_Points, KM_ResSpritesEdit, KM_Defaults, KM_Log;


{ TKMRXXPacker }
constructor TKMRXXPacker.Create;
begin
  inherited;

  // Default values
  PackToRXX := True;
  PackToRXA := False;
  RXXFormat := rxxTwo;
end;


class function TKMRXXPacker.GetAvailableToPack(const aPath: string): TRXTypeSet;
var
  RT: TRXType;
begin
  Result := [rxTiles]; //Tiles are always in the list

  for RT := Low(TRXType) to High(TRXType) do
    if FileExists(aPath + RX_INFO[RT].FileName + '.rx') then
      Result := Result + [RT];
end;


procedure TKMRXXPacker.Pack(aRT: TRXType; aPalettes: TKMResPalettes; aOnMessage: TProc<string>);

  procedure WrapMsg(const aMsg: string);
  begin
    aOnMessage(Format('[%s] %s', [RX_INFO[aRT].FileName, aMsg]));
  end;

var
  rxPath: string;
  deathAnimProcessed: TList<Integer>;
  spritePack: TKMSpritePackEdit;
  trimmedAmount: Cardinal;
  step, spriteID, rxCount: Integer;
  resHouses: TKMResHouses;
  resUnits: TKMResUnits;
  UT: TKMUnitType;
  dir: TKMDirection;
  path, msg: string;
begin
  //ruCustom sprite packs do not have a main RXX file so don't need packing
  if RX_INFO[aRT].Usage = ruCustom then Exit;

  rxPath := SourcePathRX + RX_INFO[aRT].FileName + '.rx';

  if (aRT <> rxTiles) and not FileExists(rxPath) then
    raise Exception.Create('Cannot find "' + rxPath + '" file.' + sLineBreak + 'Please copy the file from your KaM\data\gfx\res\ folder.');

  spritePack := TKMSpritePackEdit.Create(aRT, aPalettes);
  try
    // Load base sprites from original KaM RX packages
    if aRT <> rxTiles then
    begin
      // Load base RX
      spritePack.LoadFromRXFile(rxPath);
      WrapMsg('RX contains ' + IntToStr(spritePack.RXData.Count) + ' entries');

      // Overload (something we dont need in RXXPacker, cos all the custom sprites are in other folders)
      spritePack.OverloadRXDataFromFolder(SourcePathRX, False); // Do not soften shadows, it will be done later on
      WrapMsg('With overload contains ' + IntToStr(spritePack.RXData.Count) + ' entries');

      trimmedAmount := spritePack.TrimSprites;
      WrapMsg('  trimmed ' + IntToStr(trimmedAmount) + ' bytes');
    end
    else
      if DirectoryExists(SourcePathRX) then
      begin
        spritePack.OverloadRXDataFromFolder(SourcePathRX);
        WrapMsg('Overload contains ' + IntToStr(spritePack.RXData.Count) + ' entries');
        if spritePack.RXData.Count = 0 then
          WrapMsg('WARNING: no RX sprites were found!');
        // Tiles don't need to be trimmed
      end;

    // Houses need some special treatment to adapt to GL_ALPHA_TEST that we use for construction steps
    if aRT = rxHouses then
    begin
      WrapMsg('Pre-processing houses');
      resHouses := TKMResHouses.Create;
      spritePack.AdjoinHouseMasks(resHouses);
      spritePack.GrowHouseMasks(resHouses);
      spritePack.RemoveSnowHouseShadows(resHouses);
      spritePack.RemoveMarketWaresShadows(resHouses);
      resHouses.Free;
    end;

    // Determine objects size only for units (used for hitbox)
    //todo: do we need it for houses too ?
    if aRT = rxUnits then
    begin
      WrapMsg('Pre-processing units');
      spritePack.DetermineImagesObjectSizeAll;
    end;

    // The idea was to blur the water and make it semi-trasparent, but it did not work out as expected
    //if RT = rxTiles then
    //  SpritePack.SoftWater(nil);

    // Save
    if PackToRXX then
    begin
      WrapMsg('Saving RXX');
      spritePack.SaveToRXXFile(DestinationPath + RX_INFO[aRT].FileName + '.rxx', RXXFormat);
    end;

    // Generate alpha shadows for the following sprite packs
    if aRT in [rxHouses, rxUnits, rxGui, rxTrees] then
    begin
      if aRT = rxHouses then
      begin
        WrapMsg('Alpha shadows for houses');
        spritePack.SoftenShadowsRange(889, 892, False); // Smooth smoke
        spritePack.SoftenShadowsRange(1615, 1638, False); // Smooth flame
      end;

      if aRT = rxUnits then
      begin
        WrapMsg('Alpha shadows for units');
        spritePack.SoftenShadowsRange(6251, 6322, False); // Smooth thought bubbles

        resUnits := TKMResUnits.Create; // Smooth all death animations for all units
        deathAnimProcessed := TList<Integer>.Create; // We need to remember which ones we've done because units reuse them
        try
          for UT := HUMANS_MIN to HUMANS_MAX do
          for dir := dirN to dirNW do
          for step := 1 to 30 do
          begin
            spriteID := resUnits[UT].UnitAnim[uaDie,dir].Step[step]+1; //Sprites in units.dat are 0 indexed
            if (spriteID > 0)
            and not deathAnimProcessed.Contains(spriteID) then
            begin
              spritePack.SoftenShadowsRange(spriteID, spriteID, False);
              deathAnimProcessed.Add(spriteID);
            end;
          end;
        finally
          deathAnimProcessed.Free;
          resUnits.Free;
        end;
      end;

      if aRT = rxGui then
      begin
        WrapMsg('Alpha shadows for GUI');
        spritePack.SoftenShadowsRange(105, 128); //Field plans
        spritePack.SoftenShadowsRange(249, 281); //House tablets only (shadow softening messes up other rxGui sprites)
        spritePack.SoftenShadowsRange(461, 468); //Field fences
        spritePack.SoftenShadowsRange(660, 660); //Woodcutter cutting point sign
      end
      else
        spritePack.SoftenShadowsRange(1, spritePack.RXData.Count);

      if PackToRXX then
      begin
        WrapMsg('Saving _a.RXX');
        spritePack.SaveToRXXFile(DestinationPath + RX_INFO[aRT].FileName + '_a.rxx', RXXFormat);
      end;

      if PackToRXA then
      begin
        // There are no overloaded interp sprites for rxGui
        if aRT <> rxGui then
        begin
          path := SourcePathInterp + IntToStr(Ord(aRT)+1) + '\';
          // Append interpolated sprites
          if DirectoryExists(path) then
          begin
            rxCount := spritePack.RXData.Count;
            spritePack.OverloadRXDataFromFolder(SourcePathInterp + IntToStr(Ord(aRT)+1) + '\', False); // Shadows are already softened for interps
            WrapMsg(Format('Overload with interpolated sprites contains %d entries. Unique entries found in .rxa file: %d',
                              [spritePack.RXData.Count, spritePack.RXData.Count - rxCount]));
            if spritePack.RXData.Count = rxCount then
              WrapMsg('WARNING: No RXA sprites were found at ' + path);
          end
          else
            WrapMsg('WARNING: Directory of RXA sprites does not exist: ' + path);
        end;

        WrapMsg('Saving RXA');
        spritePack.SaveToRXAFile(DestinationPath + RX_INFO[aRT].FileName + '.rxa', RXXFormat);
      end;
    end;
  finally
    spritePack.Free;
  end;
end;


procedure TKMRXXPacker.PackSet(aRxSet: TRXTypeSet; aPalettes: TKMResPalettes; aOnMessage: TProc<string>);
var
  rxType: TRXType;
  tick, tickTotal: Cardinal;
begin
  if not DirectoryExists(SourcePathRX) then
  begin
    aOnMessage('Cannot find "' + SourcePathRX + '" folder.' + sLineBreak + 'Please make sure this folder exists and has data.');
    Exit;
  end;

  if PackToRXA and not DirectoryExists(SourcePathInterp) then
  begin
    aOnMessage('Cannot find "' + SourcePathInterp + '" folder.' + sLineBreak + 'Please make sure this folder exists and has data.');
    Exit;
  end;

  tickTotal := GetTickCount;

  for rxType := Low(TRXType) to High(TRXType) do
  if rxType in aRxSet then
  begin
    aOnMessage('Packing ' + RX_INFO[rxType].FileName + '.rxx ... ');
    tick := GetTickCount;
    Pack(rxType, aPalettes, aOnMessage);
    aOnMessage('... packed in ' + IntToStr(GetTickCount - tick) + ' ms');
  end;

  aOnMessage('Everything packed in ' + IntToStr(GetTickCount - tickTotal) + ' ms');
end;


procedure TKMRXXPacker.SetDestinationPath(const aValue: string);
begin
  fDestinationPath := IncludeTrailingPathDelimiter(aValue);
end;


procedure TKMRXXPacker.SetSourcePathInterp(const aValue: string);
begin
  fSourcePathInterp := IncludeTrailingPathDelimiter(aValue);
end;


procedure TKMRXXPacker.SetSourcePathRX(const aValue: string);
begin
  fSourcePathRX := IncludeTrailingPathDelimiter(aValue);
end;


end.
