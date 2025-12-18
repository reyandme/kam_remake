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

    fPalettes: TKMResPalettes;
    fOnMessage: TProc<string>;

    fTimeBegin: TDateTime;
    fCurrentRT: TRXType;

    procedure DoLog(aMsg: string);

    procedure Pack(aRT: TRXType);
    procedure SetDestinationPath(const aValue: string);
    procedure SetSourcePathInterp(const aValue: string);
    procedure SetSourcePathRX(const aValue: string);
  public
    PackToRXX: Boolean;
    PackToRXA: Boolean;
    RXXFormat: TKMRXXFormat;

    constructor Create(aPalettes: TKMResPalettes; aOnMessage: TProc<string>);

    procedure PackSet(aRxSet: TRXTypeSet);

    property SourcePathRX: string read fSourcePathRX write SetSourcePathRX;
    property SourcePathInterp: string read fSourcePathInterp write SetSourcePathInterp;
    property DestinationPath: string read fDestinationPath write SetDestinationPath;

    class function GetAvailableToPack(const aPath: string): TRXTypeSet;
  end;


implementation
uses
  KM_ResHouses, KM_ResUnits, KM_Points, KM_ResSpritesEdit, KM_Defaults, KM_Log;


{ TKMRXXPacker }
constructor TKMRXXPacker.Create(aPalettes: TKMResPalettes; aOnMessage: TProc<string>);
begin
  inherited Create;

  // Default values
  PackToRXX := True;
  PackToRXA := False;
  RXXFormat := rxxTwo;

  fPalettes := aPalettes;
  fOnMessage := aOnMessage;
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


procedure TKMRXXPacker.DoLog(aMsg: string);
begin
  // Packing is so lengthy, we show timestamp with minutes
  fOnMessage(Format('%s [%s] %s', [TimeToStr(Now - fTimeBegin), RX_INFO[fCurrentRT].FileName, aMsg]));
end;


procedure TKMRXXPacker.Pack(aRT: TRXType);
var
  tick: Cardinal;
  rxPath: string;
  deathAnimProcessed: TList<Integer>;
  spritePack: TKMSpritePackEdit;
  trimmedAmount: Cardinal;
  step, spriteID, rxCount: Integer;
  resHouses: TKMResHouses;
  resUnits: TKMResUnits;
  UT: TKMUnitType;
  dir: TKMDirection;
  path: string;
begin
  fCurrentRT := aRT;

  tick := GetTickCount;
  DoLog('Packing ...');

  //ruCustom sprite packs do not have a main RXX file so don't need packing
  if RX_INFO[aRT].Usage = ruCustom then Exit;

  rxPath := SourcePathRX + RX_INFO[aRT].FileName + '.rx';

  if (aRT <> rxTiles) and not FileExists(rxPath) then
    raise Exception.Create('Cannot find "' + rxPath + '" file.' + sLineBreak + 'Please copy the file from your KaM\data\gfx\res\ folder.');

  spritePack := TKMSpritePackEdit.Create(aRT, fPalettes);
  try
    // Load base sprites from original KaM RX packages
    if aRT <> rxTiles then
    begin
      // Load base RX
      spritePack.LoadFromRXFile(rxPath);
      DoLog('RX contains ' + IntToStr(spritePack.RXData.Count) + ' entries');

      // Overload (something we dont need in RXXPacker, cos all the custom sprites are in other folders)
      spritePack.OverloadRXDataFromFolder(SourcePathRX, DoLog, False); // Do not soften shadows, it will be done later on
      DoLog('With overload contains ' + IntToStr(spritePack.RXData.Count) + ' entries');

      trimmedAmount := spritePack.TrimSprites;
      DoLog('  trimmed ' + IntToStr(trimmedAmount) + ' bytes');
    end
    else
      if DirectoryExists(SourcePathRX) then
      begin
        spritePack.OverloadRXDataFromFolder(SourcePathRX, DoLog);
        DoLog('Overload contains ' + IntToStr(spritePack.RXData.Count) + ' entries');
        if spritePack.RXData.Count = 0 then
          DoLog('WARNING: no RX sprites were found!');
        // Tiles don't need to be trimmed
      end;

    // Houses need some special treatment to adapt to GL_ALPHA_TEST that we use for construction steps
    if aRT = rxHouses then
    begin
      DoLog('Pre-processing houses');
      resHouses := TKMResHouses.Create;
      spritePack.AdjoinHouseMasks(resHouses);
      spritePack.GrowHouseMasks(resHouses);
      spritePack.RemoveSnowHouseShadows(resHouses);
      spritePack.RemoveMarketWaresShadows(resHouses);
      resHouses.Free;
    end;

    // Determine objects size only for units (used for hitbox)
    //todo -cComplicated: do we need it for houses too ?
    if aRT = rxUnits then
    begin
      DoLog('Pre-processing units');
      spritePack.DetermineImagesObjectSizeAll;
    end;

    // The idea was to blur the water and make it semi-trasparent, but it did not work out as expected
    //if RT = rxTiles then
    //  SpritePack.SoftWater(nil);

    // Save
    if PackToRXX then
    begin
      DoLog('Saving RXX');
      spritePack.SaveToRXXFile(DestinationPath + RX_INFO[aRT].FileName + '.rxx', RXXFormat);
    end;

    // Generate alpha shadows for the following sprite packs
    if aRT in [rxHouses, rxUnits, rxGui, rxTrees] then
    begin
      if aRT = rxHouses then
      begin
        DoLog('Alpha shadows for houses');
        spritePack.SoftenShadowsRange(889, 892, False); // Smooth smoke
        spritePack.SoftenShadowsRange(1615, 1638, False); // Smooth flame
      end;

      if aRT = rxUnits then
      begin
        DoLog('Alpha shadows for units');
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
        DoLog('Alpha shadows for GUI');
        spritePack.SoftenShadowsRange(105, 128); //Field plans
        spritePack.SoftenShadowsRange(249, 281); //House tablets only (shadow softening messes up other rxGui sprites)
        spritePack.SoftenShadowsRange(461, 468); //Field fences
        spritePack.SoftenShadowsRange(660, 660); //Woodcutter cutting point sign
      end
      else
        spritePack.SoftenShadowsRange(1, spritePack.RXData.Count);

      if PackToRXX then
      begin
        DoLog('Saving _a.RXX');
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
            spritePack.OverloadRXDataFromFolder(SourcePathInterp + IntToStr(Ord(aRT)+1) + '\', DoLog, False); // Shadows are already softened for interps
            DoLog(Format('Overload with interpolated sprites contains %d entries. Unique entries found in .rxa file: %d',
                              [spritePack.RXData.Count, spritePack.RXData.Count - rxCount]));
            if spritePack.RXData.Count = rxCount then
              DoLog('WARNING: No RXA sprites were found at ' + path);
          end
          else
            DoLog('WARNING: Directory of RXA sprites does not exist: ' + path);
        end;

        DoLog('Saving RXA');
        spritePack.SaveToRXAFile(DestinationPath + RX_INFO[aRT].FileName + '.rxa', RXXFormat);
      end;
    end;
  finally
    spritePack.Free;
  end;

  DoLog(Format('... packed in %dms', [GetTickCount - tick]));
end;


procedure TKMRXXPacker.PackSet(aRxSet: TRXTypeSet);
var
  I: TRXType;
begin
  if not DirectoryExists(SourcePathRX) then
  begin
    fOnMessage('Cannot find "' + SourcePathRX + '" folder.' + sLineBreak + 'Please make sure this folder exists and has data.');
    Exit;
  end;

  if PackToRXA and not DirectoryExists(SourcePathInterp) then
  begin
    fOnMessage('Cannot find "' + SourcePathInterp + '" folder.' + sLineBreak + 'Please make sure this folder exists and has data.');
    Exit;
  end;

  fTimeBegin := Now;

  for I := Low(TRXType) to High(TRXType) do
  if I in aRxSet then
    Pack(I);

  fOnMessage(Format('Everything packed in %dsec', [Round((Now - fTimeBegin) * SecsPerDay)]));
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
