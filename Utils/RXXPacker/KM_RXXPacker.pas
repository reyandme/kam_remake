unit KM_RXXPacker;
{$I ..\..\KaM_Remake.inc}
interface
uses
  System.SysUtils, System.Generics.Collections,
  KM_ResTypes, KM_ResPalettes, KM_ResSprites;


type
  TKMRXXPacker = class
  private
    fRT: TRXType;

    fSourcePathRX: string;
    fSourcePathInterp: string;
    fDestinationPath: string;

    fPackToRXX: Boolean;
    fPackToRXA: Boolean;
    fRXXFormat: TKMRXXFormat;

    fPalettes: TKMResPalettes;
    fOnMessage: TProc<string>;

    procedure DoLog(aMsg: string);
  public
    constructor Create(aRT: TRXType; aSourcePathRX, aSourcePathInterp, aDestinationPath: string; aPackToRXX, aPackToRXA: Boolean; aRXXFormat: TKMRXXFormat; aPalettes: TKMResPalettes;aOnMessage: TProc<string>);

    procedure Pack;
  end;


implementation
uses
  Winapi.Windows,
  KM_Defaults, KM_Points,
  KM_ResHouses, KM_ResSpritesEdit, KM_ResUnits;


{ TKMRXXPacker }
constructor TKMRXXPacker.Create(aRT: TRXType; aSourcePathRX, aSourcePathInterp, aDestinationPath: string; aPackToRXX, aPackToRXA: Boolean; aRXXFormat: TKMRXXFormat; aPalettes: TKMResPalettes; aOnMessage: TProc<string>);
begin
  inherited Create;

  fRT := aRT;

  fSourcePathRX := aSourcePathRX;
  fSourcePathInterp := aSourcePathInterp;
  fDestinationPath := aDestinationPath;

  fPackToRXX := aPackToRXX;
  fPackToRXA := aPackToRXA;
  fRXXFormat := aRXXFormat;

  fPalettes := aPalettes;
  fOnMessage := aOnMessage;
end;


procedure TKMRXXPacker.DoLog(aMsg: string);
begin
  fOnMessage(Format('[%s] %s', [RX_INFO[fRT].FileName, aMsg]));
end;


procedure TKMRXXPacker.Pack;
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
  tick := GetTickCount;
  DoLog('Packing ...');

  //ruCustom sprite packs do not have a main RXX file so don't need packing
  if RX_INFO[fRT].Usage = ruCustom then Exit;

  rxPath := fSourcePathRX + RX_INFO[fRT].FileName + '.rx';

  if (fRT <> rxTiles) and not FileExists(rxPath) then
    raise Exception.Create('Cannot find "' + rxPath + '" file.' + sLineBreak + 'Please copy the file from your KaM\data\gfx\res\ folder.');

  spritePack := TKMSpritePackEdit.Create(fRT, fPalettes);
  try
    // Load base sprites from original KaM RX packages
    if fRT <> rxTiles then
    begin
      // Load base RX
      spritePack.LoadFromRXFile(rxPath);
      DoLog('RX contains ' + IntToStr(spritePack.RXData.Count) + ' entries');

      // Overload (something we dont need in RXXPacker, cos all the custom sprites are in other folders)
      spritePack.OverloadRXDataFromFolder(fSourcePathRX, DoLog, False); // Do not soften shadows, it will be done later on
      DoLog('With overload contains ' + IntToStr(spritePack.RXData.Count) + ' entries');

      trimmedAmount := spritePack.TrimSprites;
      DoLog('  trimmed ' + IntToStr(trimmedAmount) + ' bytes');
    end
    else
      if DirectoryExists(fSourcePathRX) then
      begin
        spritePack.OverloadRXDataFromFolder(fSourcePathRX, DoLog);
        DoLog('Overload contains ' + IntToStr(spritePack.RXData.Count) + ' entries');
        if spritePack.RXData.Count = 0 then
          DoLog('WARNING: no RX sprites were found!');
        // Tiles don't need to be trimmed
      end;

    // Houses need some special treatment to adapt to GL_ALPHA_TEST that we use for construction steps
    if fRT = rxHouses then
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
    if fRT = rxUnits then
    begin
      DoLog('Pre-processing units');
      spritePack.DetermineImagesObjectSizeAll;
    end;

    // The idea was to blur the water and make it semi-trasparent, but it did not work out as expected
    //if RT = rxTiles then
    //  SpritePack.SoftWater(nil);

    // Save
    if fPackToRXX then
    begin
      DoLog('Saving RXX');
      spritePack.SaveToRXXFile(fDestinationPath + RX_INFO[fRT].FileName + '.rxx', fRXXFormat);
    end;

    // Generate alpha shadows for the following sprite packs
    if fRT in [rxHouses, rxUnits, rxGui, rxTrees] then
    begin
      if fRT = rxHouses then
      begin
        DoLog('Alpha shadows for houses');
        spritePack.SoftenShadowsRange(889, 892, False); // Smooth smoke
        spritePack.SoftenShadowsRange(1615, 1638, False); // Smooth flame
      end;

      if fRT = rxUnits then
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

      if fRT = rxGui then
      begin
        DoLog('Alpha shadows for GUI');
        spritePack.SoftenShadowsRange(105, 128); //Field plans
        spritePack.SoftenShadowsRange(249, 281); //House tablets only (shadow softening messes up other rxGui sprites)
        spritePack.SoftenShadowsRange(461, 468); //Field fences
        spritePack.SoftenShadowsRange(660, 660); //Woodcutter cutting point sign
      end
      else
        spritePack.SoftenShadowsRange(1, spritePack.RXData.Count);

      if fPackToRXX then
      begin
        DoLog('Saving _a.RXX');
        spritePack.SaveToRXXFile(fDestinationPath + RX_INFO[fRT].FileName + '_a.rxx', fRXXFormat);
      end;

      if fPackToRXA then
      begin
        // There are no overloaded interp sprites for rxGui
        if fRT <> rxGui then
        begin
          path := fSourcePathInterp + IntToStr(Ord(fRT)+1) + '\';
          // Append interpolated sprites
          if DirectoryExists(path) then
          begin
            rxCount := spritePack.RXData.Count;
            spritePack.OverloadRXDataFromFolder(fSourcePathInterp + IntToStr(Ord(fRT)+1) + '\', DoLog, False); // Shadows are already softened for interps
            DoLog(Format('Overload with interpolated sprites contains %d entries. Unique entries found in .rxa file: %d',
                              [spritePack.RXData.Count, spritePack.RXData.Count - rxCount]));
            if spritePack.RXData.Count = rxCount then
              DoLog('WARNING: No RXA sprites were found at ' + path);
          end
          else
            DoLog('WARNING: Directory of RXA sprites does not exist: ' + path);
        end;

        DoLog('Saving RXA');
        spritePack.SaveToRXAFile(fDestinationPath + RX_INFO[fRT].FileName + '.rxa', fRXXFormat);
      end;
    end;
  finally
    spritePack.Free;
  end;

  DoLog(Format('... packed in %dms', [GetTickCount - tick]));
end;


end.
