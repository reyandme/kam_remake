unit KM_ResSprites;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  Classes, Math, SysUtils, Generics.Collections,
  Graphics,
  KM_CommonTypes, KM_Defaults,
  KM_Pics, KM_IoPNG, KM_RenderTypes,
  KM_ResTexts, KM_ResTileset, KM_ResHouses, KM_ResTypes, KM_ResTilesetTypes,
  KM_BinPacking
  {$IFDEF FPC}, zstream {$ENDIF}
  {$IFDEF WDC}, ZLib {$ENDIF};


type
  // How do we want to soften the sprite
  TKMSpriteSoftening = (ssNone, ssOnlyShadow, ssWhole);

  TKMRXXFormat = (
    rxxUnknown, // Unknown header, probably not an RXX file at all
    rxxZero,    // Legacy KMR format
    rxxOne,     // Same as previous, but with an explicit header and SizeNoShadow
    rxxTwo      // Same as previous, but with dynamic length text in header
  );

const
  RXX_HEADER_LENGTH = 4;
  RXX_HEADER: array [TKMRXXFormat] of AnsiString = ('', '', 'RXX1', 'RXX2');

type
  {$IFDEF LOAD_GAME_RES_ASYNC}
  TTGameResourceLoader = class;
  {$ENDIF}

  // Atlas data, needed for Texture Atlas Generation
  TKMSpriteAtlasData = record
    Container: TKMBinItem;
    TexType: TKMTexFormat;
    Data: TKMCardinalArray;
  end;

  TKMSpriteAtlases = array [TKMSpriteAtlasType] of array {atlas number} of TKMSpriteAtlasData;

  // Base class for Sprite loading
  TKMSpritePack = class
  private
    fTemp: Boolean;
    fPad: Byte; // Padding between sprites to avoid neighbour edge visibility

    {$IFNDEF NO_OGL}
    procedure SetGFXData(aTexID: Cardinal; aSpriteInfo: TKMBinItem; aAtlasType: TKMSpriteAtlasType);
    procedure PrepareAtlases(aSpriteInfo: TBinArray; aMode: TKMSpriteAtlasType; aTexType: TKMTexFormat; var aBaseRAM, aColorRAM, aTexCount: Cardinal;
                             aFillGFXData: Boolean = True; aOnCheckTerminated: TBooleanFuncSimple = nil);
    {$ENDIF}
  protected
    fRT: TRXType;
    fRXData: TRXData;

    fAtlases: TKMSpriteAtlases;
    procedure Allocate(aCount: Integer); virtual; //Allocate space for data that is being loaded
    procedure AllocateTemp(aCount: Integer);
    procedure ReadRXZHeader(aStream: TStream; out aFormat: TKMRXXFormat);
    procedure CollectSpriteFilesToOverloadInFolder(const aFolder: string; aFileList: TStringList);
    {$IFNDEF NO_OGL}
    procedure MakeGFX_BinPacking(aTexType: TKMTexFormat; aIDList: TList<Integer>; var aBaseRAM, aColorRAM, aTexCount: Cardinal;
                                 aFillGFXData: Boolean = True; aOnCheckTerminated: TBooleanFuncSimple = nil); overload;
    procedure MakeGFX_BinPacking(aTexType: TKMTexFormat; aStartingIndex: Integer; var aBaseRAM, aColorRAM, aTexCount: Cardinal;
                                 aFillGFXData: Boolean = True; aOnCheckTerminated: TBooleanFuncSimple = nil); overload;
    {$ENDIF}
  public
    constructor Create(aRT: TRXType; aTemp: Boolean = False);

    procedure AddImage(const aFolder, aFilename: string; aIndex: Integer; aEnlargeOnly: Boolean = False);

    property RT: TRXType read fRT;
    property RXData: TRXData read fRXData;
    property Padding: Byte read fPad write fPad;
    property Atlases: TKMSpriteAtlases read fAtlases;

    {$IFNDEF NO_OGL}
    procedure MakeGFX(aAlphaShadows: Boolean; aStartingIndex: Integer = 1; aFillGFXData: Boolean = True; aOnCheckTerminated: TBooleanFuncSimple = nil); overload;
    procedure MakeGFX(aAlphaShadows: Boolean; aIDList: TList<Integer>; aFillGFXData: Boolean = True; aOnCheckTerminated: TBooleanFuncSimple = nil); overload;
    {$ENDIF}
    procedure DeleteSpriteTexture(aIndex: Integer);

    //Load from atlas format, no MakeGFX bin packing needed
    procedure LoadFromRXAFile(const aFileName: string);
    procedure LoadFromRXAAndGenTextures(const aFileName: string);
    procedure OverloadGeneratedFromFolder(aAlphaShadows: Boolean; const aFolder: string; aSoftenShadows: Boolean = True;
                                          aOnCheckTerminated: TBooleanFuncSimple = nil);

    procedure LoadFromRXXFile(const aFileName: string; aStartingIndex: Integer = 1);
    procedure OverloadRXDataFromFolder(const aFolder: string; aOnProgress: TProc<string>; aSoftenShadows: Boolean = True);

    function GetSoftenShadowType(aID: Integer): TKMSpriteSoftening;

    procedure SoftenShadowsList(aIdList: TList<Integer>);
    procedure SoftenShadowsRange(aFrom, aTo: Integer; aOnlyShadows: Boolean = True);

    procedure DetermineImagesObjectSizeAll;
    procedure DetermineImagesObjectSizeList(aIdList: TList<Integer>);

    procedure RemoveMarketWaresShadows(aResHouses: TKMResHouses);
    procedure RemoveSnowHouseShadows(aResHouses: TKMResHouses);
    procedure RemoveHouseWorkBackgrounds(aResHouses: TKMResHouses);

    function GetAverageSpriteColors(aCount: Integer): TKMColor3bArray;

    function IsEmpty: Boolean;

    procedure ExportAllSpritesFromRXData(const aFolder: string);
    procedure ExportFullImageData(const aFolder: string; aIndex: Integer);
    procedure ExportImage(const aFile: string; aIndex: Integer);
    procedure ExportMask(const aFile: string; aIndex: Integer);

    procedure ClearGameResGenTemp;

    {$IFDEF LOAD_GAME_RES_ASYNC}
    procedure GenerateTexturesFromLoadedRXZ(aIsRXA: Boolean);
    {$ENDIF}

    procedure ClearTemp; virtual;//Release non-required data
  end;


  TKMResSprites = class
  private
    fAlphaShadows: Boolean; //Remember which state we loaded
    fSprites: array [TRXType] of TKMSpritePack;
    fStepProgress: TKMEvent;
    fStepCaption: TUnicodeStringEvent;
    fGenTexIdStartI: Integer;
    fGenTexIdStartILegacy: Integer;
    fGenTerrainToTerKind: array of TKMGenTerrainInfo;
    fGenTerrainToTerKindLegacy: array of TKMGenTerrainInfo;

    fGameRXTypes: TStringList; //list of TRXType for game resources
    fTemp: Boolean;
    {$IFDEF LOAD_GAME_RES_ASYNC}
    fGameResLoader: TTGameResourceLoader; // thread of game resource loader
    fGameResLoadCompleted: Boolean; // Flag to show Game Resource Loading is completed
    {$ENDIF}

    fGenTerrainTransitions: array[Succ(tkCustom)..High(TKMTerrainKind)]
                              of array[Succ(mkNone)..High(TKMTileMaskKind)]
                                of array[Succ(tmtNone)..High(TKMTileMaskType)]
                                  of array[TKMTileMaskSubType] //mask components (subtypes)
  //                                  of array[0..3] //Terrain Rotation
                                      of Word;

    fGenTerrainTransitionsLegacy: array[Succ(tkCustom)..High(TKMTerrainKind)]
                                    of array[Succ(mkNone)..High(TKMTileMaskKind)]
                                      of array[Succ(tmtNone)..High(TKMTileMaskType)]
                                        of array[TKMTileMaskSubType] //mask components (subtypes)
  //                                        of array[0..3] //Terrain Rotation
                                            of Word;

    function GetGenTerrainTransitions(aTerKind: TKMTerrainKind; aMaskKind: TKMTileMaskKind; aMaskType: TKMTileMaskType; aMaskSubtype: TKMTileMaskSubType): Word;

    function GetRXFileName(aRX: TRXType): string;
    function GetSprites(aRT: TRXType): TKMSpritePack;

    function GetSpritesRXAFilePath(aRT: TRXType): string;

    {$IFDEF LOAD_GAME_RES_ASYNC}
    procedure ManageAsyncResLoader(const aCallerName: String);
    procedure StopAsyncResourceLoader;
    function GetNextLoadRxTypeIndex(aRT: TRXType): Integer;
    {$ENDIF}
  public
    constructor Create(aStepProgress: TKMEvent = nil; aStepCaption: TUnicodeStringEvent = nil; aTemp: Boolean = False);
    destructor Destroy; override;

    procedure LoadMenuResources;
    procedure LoadGameResources(aAlphaShadows: Boolean; aForceReload: Boolean = False);
    procedure ClearTemp;

    class function AllTilesOnOneAtlas: Boolean;

    procedure GenerateTerrainTransitions(aSprites: TKMSpritePack; aLegacyGeneration: Boolean = False);

    function GetGenTerrainInfo(aTerrain: Integer): TKMGenTerrainInfo;
    function GetGenTerrainInfoLegacy(aTerrain: Integer): TKMGenTerrainInfo;

    property Sprites[aRT: TRXType]: TKMSpritePack read GetSprites; default;
    property GenTerrainTransitions[aTerKind: TKMTerrainKind; aMaskKind: TKMTileMaskKind; aMaskType: TKMTileMaskType; aMaskSubtype: TKMTileMaskSubType]: Word read GetGenTerrainTransitions;

    {$IFDEF LOAD_GAME_RES_ASYNC}
    property GameResLoadCompleted: Boolean read fGameResLoadCompleted;
    {$ENDIF}

    //Used externally to access raw RGBA data (e.g. by ExportAnim)
    function LoadSprites(aRT: TRXType; aAlphaShadows: Boolean): Boolean;
    function LoadRXASprites(aRT: TRXType): Boolean;
    function LoadRXASpritesAndGenTextures(aRT: TRXType): Boolean;
    procedure ExportToPNG(aRT: TRXType);

    property AlphaShadows: Boolean read fAlphaShadows;
    property FileName[aRX: TRXType]: string read GetRXFileName;

    procedure UpdateStateIdle;
  end;

  TKMAsyncLoadStage = (lsLoad, lsGenMain, lsOverload, lsGenOverload);

  {$IFDEF LOAD_GAME_RES_ASYNC}
  // Game resource loader thread
  TTGameResourceLoader = class(TThread)
  private
    fResSprites: TKMResSprites;
    fAlphaShadows: Boolean;
    function IsTerminated: Boolean;
    procedure Log(const aString: string);
  public
    RXType: TRXType;
    LoadStepDone: LongBool;  // flag to show, when another RXX / RXA load is completed
    LastLoadedRXA: LongBool; // flag to show, what type of RX we were loading: RXA or RXX
    LoadStage: TKMAsyncLoadStage;
    constructor Create(aResSprites: TKMResSprites; aAlphaShadows: Boolean; aRxType: TRXType);
    destructor Destroy; override;

    procedure Execute; override;
  end;
  {$ENDIF}

  TKMTexCoords = record
    TexID: Cardinal;
    u1,v1,u2,v2: Single; //Top-Left, Bottom-Right uv coords
  end;

var
  gGFXData: array [TRXType] of array of record
    Tex, Alt: TKMTexCoords; //AltID used for team colors and house building steps
    PxWidth, PxHeight: Word;
  end;


implementation
uses
  Types,
  {$IFDEF WDC}
  IOUtils,
  StrUtils,
  {$ENDIF}
  KromUtils,
  {$IFDEF LOAD_GAME_RES_ASYNC}

  {$ENDIF}
  KM_SoftShadows, KM_Resource, KM_ResUnits,
  {$IFNDEF NO_OGL}
  KM_Render,
  {$ENDIF}
  TypInfo,
  KM_Log, KM_CommonClasses,
  KM_FileIO,
  KM_CommonUtils, KM_Utils, KM_Points,
  KM_GameSettings;

const
  MAX_GAME_ATLAS_SIZE = 2048; //Max atlas size for KaM. No need for bigger atlases
  SPRITE_TYPE_EXPORT_NAME: array [TKMSpriteAtlasType] of string = ('Base', 'Mask');
  LOG_EXTRA_GFX: Boolean = False;
  OVERLOAD_SKIP_MASK = 'skip';

var
  AllTilesInOneTexture: Boolean = False;


function GetMaxAtlasSize: Integer;
begin
  Result := MAX_GAME_ATLAS_SIZE;
  {$IFNDEF NO_OGL}
  if gRender <> nil then
    Result := Min(Result, TKMRender.MaxTextureSize);
  {$ENDIF}
end;


{ TKMSpritePack }
constructor TKMSpritePack.Create(aRT: TRXType; aTemp: Boolean = False);
begin
  inherited Create;

  fRT := aRT;
  fTemp := aTemp;

  //Terrain tiles need padding to avoid edge bleeding
  if fRT = rxTiles then
    fPad := 1;
end;


//This is a crude solution to allow Campaigns to delete sprites they add
procedure TKMSpritePack.DeleteSpriteTexture(aIndex: Integer);
begin
  {$IFNDEF NO_OGL}
  if gGFXData[fRT, aIndex].Tex.TexID <> 0 then
    TKMRender.DeleteTexture(gGFXData[fRT, aIndex].Tex.TexID);
  if gGFXData[fRT, aIndex].Alt.TexID <> 0 then
    TKMRender.DeleteTexture(gGFXData[fRT, aIndex].Alt.TexID);

  gGFXData[fRT, aIndex].Tex.TexID := 0;
  gGFXData[fRT, aIndex].Alt.TexID := 0;
  {$ENDIF}
end;


function TKMSpritePack.GetSoftenShadowType(aID: Integer): TKMSpriteSoftening;
var
  step, spriteID: Integer;
  UT: TKMUnitType;
  dir: TKMDirection;
begin
  Result := ssNone;

  case fRT of
    rxHouses: // Smooth smoke and flame
              if InRange(aID, 889, 892)
              or InRange(aID, 1615, 1638) then
                Result := ssWhole
              else
                Result := ssOnlyShadow;
    rxUnits:  begin
                // Smooth thought bubbles
                if InRange(aID, 6251, 6322) then
                  Exit(ssWhole);

                // Smooth all death animations for all units
                for UT := HUMANS_MIN to HUMANS_MAX do
                  for dir := dirN to dirNW do
                    for step := 1 to 30 do
                    begin
                      spriteID := gRes.Units[UT].UnitAnim[uaDie, dir].Step[step] + 1; // Sprites in units.dat are 0 indexed
                      if (aID = spriteID) and (spriteID > 0) then
                        Exit(ssWhole);
                    end;
                if Result = ssNone then
                  Result := ssOnlyShadow;
              end;
    rxTrees:  Result := ssOnlyShadow;
    rxGui:    if InRange(aID, 105, 128)       // Field plans
              or InRange(aID, 249, 281)       // House tablets only (shadow softening messes up other rxGui sprites)
              or InRange(aID, 461, 468)       // Field fences
              or InRange(aID, 660, 660) then  // Woodcutter cutting point sign
                Result := ssOnlyShadow;
  end;
end;


procedure TKMSpritePack.SoftenShadowsList(aIdList: TList<Integer>);
var
  I, id: Integer;
  shadowConverter: TKMSoftShadowConverter;
  spriteSoftening: TKMSpriteSoftening;
begin
  if aIdList.Count = 0 then Exit;

  shadowConverter := TKMSoftShadowConverter.Create(@fRXData);
  try
    for I := 0 to aIdList.Count - 1 do
    begin
      id := aIdList[I];
      if fRXData.Flag[id] <> 0 then
      begin
        spriteSoftening := GetSoftenShadowType(id);
        case spriteSoftening of
          ssNone:       ;
          ssOnlyShadow: shadowConverter.ConvertShadows(id, True);
          ssWhole:      begin
                          shadowConverter.ConvertShadows(id, False);
                          shadowConverter.ConvertShadows(id, True);
                        end;
        end;
      end;
    end;
  finally
    shadowConverter.Free;
  end;
end;


// Make old style KaM checkerboard shadows smooth and transparent
procedure TKMSpritePack.SoftenShadowsRange(aFrom, aTo: Integer; aOnlyShadows: Boolean = True);
var
  I: Integer;
  shadowConverter: TKMSoftShadowConverter;
begin
  shadowConverter := TKMSoftShadowConverter.Create(@fRXData);
  try
    for I := aFrom to aTo do
      if fRXData.Flag[I] <> 0 then
        shadowConverter.ConvertShadows(I, aOnlyShadows);
  finally
    shadowConverter.Free;
  end;
end;


procedure TKMSpritePack.DetermineImagesObjectSizeAll;
var
  I: Integer;
  shadowConverter: TKMSoftShadowConverter;
begin
  shadowConverter := TKMSoftShadowConverter.Create(@fRXData);
  try
    for I := 1 to fRXData.Count do
      if fRXData.Flag[I] <> 0 then
        shadowConverter.DetermineImageObjectSize(I);
  finally
    shadowConverter.Free;
  end;
end;


procedure TKMSpritePack.DetermineImagesObjectSizeList(aIdList: TList<Integer>);
var
  I, id: Integer;
  shadowConverter: TKMSoftShadowConverter;
begin
  if aIdList.Count = 0 then Exit;

  shadowConverter := TKMSoftShadowConverter.Create(@fRXData);
  try
    for I := 0 to aIdList.Count - 1 do
    begin
      id := aIdList[I];
      if fRXData.Flag[id] <> 0 then
        shadowConverter.DetermineImageObjectSize(id);
    end;
  finally
    shadowConverter.Free;
  end;
end;


procedure TKMSpritePack.RemoveSnowHouseShadows(aResHouses: TKMResHouses);
var
  snowID: Integer;
  shadowConverter: TKMSoftShadowConverter;
  HT: TKMHouseType;
begin
  Assert(fRT = rxHouses);

  shadowConverter := TKMSoftShadowConverter.Create(@fRXData);
  try
    for HT := HOUSE_MIN to HOUSE_MAX do
    begin
      snowID := aResHouses[HT].SnowPic + 1;
      if fRXData.Flag[snowID] <> 0 then
        shadowConverter.RemoveShadow(snowID, True);
    end;
  finally
    shadowConverter.Free;
  end;
end;


procedure TKMSpritePack.RemoveHouseWorkBackgrounds(aResHouses: TKMResHouses);

  procedure RemoveBackground(SpriteF, SpriteB, OffsetX, OffsetY: Integer);

    function IsSame(XF, YF, XB, YB: Integer; TreatEdgeAsSame: Boolean): Boolean;
    var
      Foreground, Background: Cardinal;
    begin
      if (XF >= 0) and (YF >= 0) and (XB >= 0) and (YB >= 0)
      and (XB < fRXData.Size[SpriteB].X) and (YB < fRXData.Size[SpriteB].Y)
      and (XF < fRXData.Size[SpriteF].X) and (YF < fRXData.Size[SpriteF].Y) then
      begin
        Foreground := fRXData.RGBA[SpriteF, YF*fRXData.Size[SpriteF].X + XF];
        Background := fRXData.RGBA[SpriteB, YB*fRXData.Size[SpriteB].X + XB];
        Result := (Foreground shr 24 = 0) or (Foreground = Background);
      end
      else
        Result := TreatEdgeAsSame;
    end;

  var
    X, Y, I, K, XOff, YOff, MatchingNeighbours: Integer;
  begin
    for X := 0 to fRXData.Size[SpriteF].X - 1 do
      for Y := 0 to fRXData.Size[SpriteF].Y - 1 do
      begin
        XOff := X + OffsetX + fRXData.Pivot[SpriteF].X - fRXData.Pivot[SpriteB].X;
        YOff := Y + OffsetY + fRXData.Pivot[SpriteF].Y - fRXData.Pivot[SpriteB].Y;
        if IsSame(X, Y, XOff, YOff, False) then
        begin
          //To avoid making incorrect 1px holes, at least two direct neighbour must match too
          MatchingNeighbours := 0;
          for I := -1 to 1 do
            for K := -1 to 1 do
              if (K=0) xor (I=0) then
                if IsSame(X+I, Y+K, XOff+I, YOff+K, True) then
                  Inc(MatchingNeighbours);

          if MatchingNeighbours >= 2 then
            fRXData.RGBA[SpriteF, Y*fRXData.Size[SpriteF].X + X] := $0;
        end;
      end;
  end;

var
  HT: TKMHouseType;
  HA: TKMHouseActionType;
  A: TKMAnimLoop;
  Step, beastHouse, beast, beastAge: Integer;
const
  HOUSE_BEAST_LOOKUP: array[1..3] of TKMHouseType = (htSwine, htStables, htMarket);
begin
  //Actions
  for HT := HOUSE_MIN to HOUSE_MAX do
  begin
    for HA := Low(TKMHouseActionType) to High(TKMHouseActionType) do
    begin
      if HA in [haWork1..haWork5, haIdle] then
      begin
        A := aResHouses[HT].Anim[HA];
        for Step := 1 to A.Count do
        begin
          if A.Step[Step] > -1 then
          begin
            RemoveBackground(A.Step[Step]+1, aResHouses[HT].StonePic+1, A.MoveX, A.MoveY);
          end;
        end;
      end;
    end;
  end;

  //Beasts
  for beastHouse := 1 to 3 do
  begin
    for beast := 1 to 5 do
    begin
      for beastAge := 1 to 3 do
      begin
        //Market only has 2 beasts and no age
        if (beastHouse = 3) and ((beast > 3) or (beastAge <> 1)) then
          Continue;

        A := aResHouses.BeastAnim[HOUSE_BEAST_LOOKUP[beastHouse], beast, beastAge];
        for Step := 1 to A.Count do
        begin
          if A.Step[Step] > -1 then
          begin
            RemoveBackground(A.Step[Step]+1, aResHouses[HOUSE_BEAST_LOOKUP[beastHouse]].StonePic+1, A.MoveX, A.MoveY);
          end;
        end;
      end;
    end;
  end;
end;


procedure TKMSpritePack.RemoveMarketWaresShadows(aResHouses: TKMResHouses);
var
  I: Integer;
  shadowConverter: TKMSoftShadowConverter;
begin
  Assert(fRT = rxHouses);

  shadowConverter := TKMSoftShadowConverter.Create(@fRXData);
  try
    for I := MARKET_WARES_TEX_START + 1 to MARKET_WARES_TEX_START + MARKET_WARES_TEX_CNT - 1 do
    if fRXData.Flag[I] <> 0 then
      shadowConverter.RemoveShadow(I, False);
  finally
    shadowConverter.Free;
  end;
end;


procedure TKMSpritePack.Allocate(aCount: Integer);
begin
  fRXData.Count := aCount;

  aCount := fRXData.Count + 1;
  if not fTemp then
    SetLength(gGFXData[fRT],      aCount);
  SetLength(fRXData.Flag,         aCount);
  SetLength(fRXData.Size,         aCount);
  SetLength(fRXData.Pivot,        aCount);
  //SizeNoShadow is used only for Units
  if fRT = rxUnits then
    SetLength(fRXData.SizeNoShadow, aCount);

  // Next could be cleared
  SetLength(fRXData.RGBA,         aCount);
  SetLength(fRXData.Mask,         aCount);
  SetLength(fRXData.HasMask,      aCount);
end;


procedure TKMSpritePack.AllocateTemp(aCount: Integer);
var
  cnt: Integer;
begin
  cnt := aCount + 1;

  // Next array are cleared after loading, thus we have to allocate memory for them again
  if Length(fRXData.RGBA) < cnt then
    SetLength(fRXData.RGBA, cnt);

  if Length(fRXData.Mask) < cnt then
    SetLength(fRXData.Mask, cnt);

  if Length(fRXData.HasMask) < cnt then
    SetLength(fRXData.HasMask, cnt);
end;


//Release RAM that is no longer needed
procedure TKMSpritePack.ClearTemp;
begin
  // Clear only what we will not use for Render
  SetLength(fRXData.RGBA, 0);
  SetLength(fRXData.Mask, 0);
  SetLength(fRXData.HasMask, 0);
end;


//Add PNG images to spritepack if user has any addons in Sprites folder
procedure TKMSpritePack.AddImage(const aFolder, aFilename: string; aIndex: Integer; aEnlargeOnly: Boolean = False);
type
  TKMSpriteMaskType = (smtNone, smtPlain, smtSmart);
var
  I,K: Integer;
  Tr, Tg, Tb, T: Byte;
  Thue, Tsat, Tbri: Single;
  ft: TextFile;
  maskFile: array [TKMSpriteMaskType] of string;
  maskTyp: TKMSpriteMaskType;
  pngWidth, pngHeight: Word;
  pngData: TKMCardinalArray;
  txtFileName: string;
begin
  Assert(SameText(ExtractFileExt(aFilename), '.png'));

  if aIndex > fRXData.Count then
    Allocate(aIndex)
  else
  // RGBA / Mask / HasMask arrays are cleared after 1st usage, so we should reallocate memory for them
  if aEnlargeOnly then
    AllocateTemp(aIndex);

  LoadFromPng(aFolder + aFilename, pngWidth, pngHeight, pngData);
  Assert((pngWidth <= MAX_GAME_ATLAS_SIZE) and (pngHeight <= MAX_GAME_ATLAS_SIZE),
         Format('Image size should be less than %dx%d pixels', [MAX_GAME_ATLAS_SIZE, MAX_GAME_ATLAS_SIZE]));

  fRXData.Flag[aIndex] := Byte(pngWidth * pngHeight <> 0); //Mark as used (required for saving RXX)
  fRXData.Size[aIndex].X := pngWidth;
  fRXData.Size[aIndex].Y := pngHeight;

  SetLength(fRXData.RGBA[aIndex], pngWidth * pngHeight);
  SetLength(fRXData.Mask[aIndex], pngWidth * pngHeight); //Should allocate space for it's always comes along

  for K := 0 to pngHeight - 1 do
  for I := 0 to pngWidth - 1 do
    fRXData.RGBA[aIndex, K * pngWidth + I] := pngData[K * pngWidth + I];

  maskFile[smtPlain] := aFolder + StringReplace(aFilename, '.png', 'm.png', [rfReplaceAll, rfIgnoreCase]);
  maskFile[smtSmart] := aFolder + StringReplace(aFilename, '.png', 'a.png', [rfReplaceAll, rfIgnoreCase]);

  //Determine mask processing mode
  if FileExists(maskFile[smtPlain]) then
    maskTyp := smtPlain
  else
  if FileExists(maskFile[smtSmart]) then
    maskTyp := smtSmart
  else
    maskTyp := smtNone;

  fRXData.HasMask[aIndex] := maskTyp in [smtPlain, smtSmart];

  //Load and process the mask if it exists
  if fRXData.HasMask[aIndex] then
  begin
    //Plain masks are used 'as is'
    //Smart masks are designed for the artist, they convert color brightness into a mask

    LoadFromPng(maskFile[maskTyp], pngWidth, pngHeight, pngData);

    if (fRXData.Size[aIndex].X = pngWidth)
    and (fRXData.Size[aIndex].Y = pngHeight) then
    begin
      //We don't handle transparency in Masks
      for K := 0 to pngHeight - 1 do
      for I := 0 to pngWidth - 1 do
      case maskTyp of
        smtPlain: begin
                    //For now process just red (assume pic is greyscale)
                    fRXData.Mask[aIndex, K*pngWidth+I] := pngData[K*pngWidth+I] and $FF;
                  end;
        smtSmart: begin
                    if Cardinal(pngData[K*pngWidth+I] and $FFFFFF) <> 0 then
                    begin
                      Tr := fRXData.RGBA[aIndex, K*pngWidth+I] and $FF;
                      Tg := fRXData.RGBA[aIndex, K*pngWidth+I] shr 8 and $FF;
                      Tb := fRXData.RGBA[aIndex, K*pngWidth+I] shr 16 and $FF;

                      //Determine color brightness
                      ConvertRGB2HSB(Tr, Tg, Tb, Thue, Tsat, Tbri);

                      //Make background RGBA black or white for more saturated colors
                      if Tbri < 0.5 then
                        fRXData.RGBA[aIndex, K*pngWidth+I] := FLAG_COLOR_DARK
                      else
                        fRXData.RGBA[aIndex, K*pngWidth+I] := FLAG_COLOR_LITE;

                      //Map brightness from 0..1 to 0..255..0
                      T := Trunc((0.5 - Abs(Tbri - 0.5)) * 510);
                      fRXData.Mask[aIndex, K*pngWidth+I] := T;
                    end
                    else
                      fRXData.Mask[aIndex, K*pngWidth+I] := 0;
                 end;
        end;
    end;
  end;

  //Read pivot info
  txtFileName := aFolder + StringReplace(aFilename, '.png', '.txt', [rfReplaceAll, rfIgnoreCase]);
  if FileExists(txtFileName) then
  begin
    AssignFile(ft, txtFileName);
    Reset(ft);
    ReadLn(ft, fRXData.Pivot[aIndex].X);
    ReadLn(ft, fRXData.Pivot[aIndex].Y);

    //SizeNoShadow is used only for Units
    if fRT = rxUnits then
    begin
      ReadLn(ft, fRXData.SizeNoShadow[aIndex].Left);
      ReadLn(ft, fRXData.SizeNoShadow[aIndex].Top);
      ReadLn(ft, fRXData.SizeNoShadow[aIndex].Right);
      ReadLn(ft, fRXData.SizeNoShadow[aIndex].Bottom);
    end;
    CloseFile(ft);
  end;
end;


// Read header of the RXX / RXA files
procedure TKMSpritePack.ReadRXZHeader(aStream: TStream; out aFormat: TKMRXXFormat);
const
  ZLIB_HEADER: AnsiString = AnsiChar($78) + AnsiChar($DA); // Header of ZLIB archiver. We used for RXX before introducing RXX1 format version
var
  strFormat: AnsiString;
  metadataLen: Word;
begin
  SetLength(strFormat, RXX_HEADER_LENGTH);
  aStream.Read(strFormat[1], RXX_HEADER_LENGTH);

  if strFormat = RXX_HEADER[rxxOne] then
  begin
    aFormat := rxxOne;

    // Skip 32 bytes of metadata
    aStream.Seek(32, soFromCurrent);
  end else
  if strFormat = RXX_HEADER[rxxTwo] then
  begin
    aFormat := rxxTwo;

    // For now we just skip metadata (but in the future we could show it in e.g. RXXEditor)
    aStream.Read(metadataLen, SizeOf(metadataLen));
    aStream.Seek(metadataLen, soFromCurrent);
  end else
  if strFormat[1] + strFormat[2] = ZLIB_HEADER then
  begin
    aFormat := rxxZero;
    
    // Reset position
    aStream.Position := 0;
  end else
    aFormat := rxxUnknown;
end;


procedure TKMSpritePack.LoadFromRXXFile(const aFileName: string; aStartingIndex: Integer = 1);
var
  I: Integer;
  rxxCount: Integer;
  inputStream: TFileStream;
  decompressionStream: TDecompressionStream;
  rxxFormat: TKMRXXFormat;
begin
  case fRT of
    rxTiles: if SKIP_RENDER and not DO_NOT_SKIP_LOAD_TILESET then Exit;
    else     if SKIP_RENDER then Exit;
  end;

  if not FileExists(aFileName) then Exit;

  inputStream := TFileStream.Create(aFileName, fmOpenRead or fmShareDenyNone);
  try
    ReadRXZHeader(inputStream, rxxFormat);

    // Not sure what to do yet, silently "fail" for now
    if rxxFormat = rxxUnknown then
      Exit;

    decompressionStream := TDecompressionStream.Create(inputStream);
    try
      decompressionStream.Read(rxxCount, 4);
          
      gLog.AddTime(RX_INFO[fRT].FileName + ' - %d', [rxxCount]);

      if rxxCount = 0 then
        Exit;

      Allocate(aStartingIndex + rxxCount - 1);

      decompressionStream.Read(fRXData.Flag[aStartingIndex], rxxCount);

      for I := aStartingIndex to aStartingIndex + rxxCount - 1 do
        if fRXData.Flag[I] = 1 then
        begin
          decompressionStream.Read(fRXData.Size[I].X, SizeOf(fRXData.Size[I]));
          decompressionStream.Read(fRXData.Pivot[I].X, SizeOf(fRXData.Pivot[I]));
          //SizeNoShadow is used only for Units
          if fRT = rxUnits then
            decompressionStream.Read(fRXData.SizeNoShadow[I].Left, SizeOf(fRXData.SizeNoShadow[I]));
          //Data part of each sprite is 32BPP RGBA in Remake RXX files
          SetLength(fRXData.RGBA[I], fRXData.Size[I].X * fRXData.Size[I].Y);
          SetLength(fRXData.Mask[I], fRXData.Size[I].X * fRXData.Size[I].Y);
          decompressionStream.Read(fRXData.RGBA[I, 0], 4 * fRXData.Size[I].X * fRXData.Size[I].Y);
          decompressionStream.Read(fRXData.HasMask[I], 1);
          if fRXData.HasMask[I] then
            decompressionStream.Read(fRXData.Mask[I, 0], fRXData.Size[I].X * fRXData.Size[I].Y);
        end;
    finally
      decompressionStream.Free;
    end;
  finally
    inputStream.Free;
  end;
end;


procedure TKMSpritePack.LoadFromRXAFile(const aFileName: string);
{$IFNDEF NO_OGL}
var
  I: Integer;
  SAT: TKMSpriteAtlasType;
  rxxCount, atlasCount, spriteCount, dataCount: Integer;
  inputStream: TFileStream;
  decompressionStream: TDecompressionStream;
  rxxFormat: TKMRXXFormat;
{$ENDIF}
begin
  if not FileExists(aFileName) then Exit;

  {$IFNDEF NO_OGL}
  case fRT of
    rxTiles: if SKIP_RENDER and not DO_NOT_SKIP_LOAD_TILESET then Exit;
    else     if SKIP_RENDER then Exit;
  end;

  inputStream := TFileStream.Create(aFileName, fmOpenRead or fmShareDenyNone);
  try
    ReadRXZHeader(inputStream, rxxFormat);

    // Not sure what to do yet, silently "fail" for now
    if rxxFormat = rxxUnknown then
      Exit;
    
    decompressionStream := TDecompressionStream.Create(inputStream);
    try
      decompressionStream.Read(rxxCount, 4);

      gLog.AddTime(RX_INFO[fRT].FileName + ' - %d', [rxxCount]);

      if rxxCount = 0 then
        Exit;

      Allocate(rxxCount);

      decompressionStream.Read(fRXData.Flag[1], fRXData.Count);

      //Sprite info
      for I := 1 to fRXData.Count do
        if fRXData.Flag[I] = 1 then
        begin
          decompressionStream.Read(fRXData.Size[I].X, SizeOf(fRXData.Size[I]));
          decompressionStream.Read(fRXData.Pivot[I].X, SizeOf(fRXData.Pivot[I]));
          //SizeNoShadow is used only for Units
          if fRT = rxUnits then
            decompressionStream.Read(fRXData.SizeNoShadow[I].Left, SizeOf(fRXData.SizeNoShadow[I]));
          decompressionStream.Read(fRXData.HasMask[I], 1);

          // Check if our load resource thread was terminated
          if TThread.CheckTerminated then Exit;
        end;

      //Atlases
      for SAT := Low(fAtlases) to High(fAtlases) do
      begin
        decompressionStream.Read(atlasCount, 4);
        SetLength(fAtlases[SAT], atlasCount);
        for I := Low(fAtlases[SAT]) to High(fAtlases[SAT]) do
          with fAtlases[SAT, I] do
          begin
            decompressionStream.Read(Container.Width, 2);
            decompressionStream.Read(Container.Height, 2);
            decompressionStream.Read(spriteCount, 4);
            SetLength(Container.Sprites, spriteCount);
            decompressionStream.Read(Container.Sprites[0], spriteCount * SizeOf(Container.Sprites[0]));
            decompressionStream.Read(TexType, SizeOf(TKMTexFormat));
            decompressionStream.Read(dataCount, 4);
            SetLength(Data, dataCount);
            decompressionStream.Read(Data[0], dataCount*SizeOf(Data[0]));

            // Check if our load resource thread was terminated
            if TThread.CheckTerminated then Exit;
          end;
      end;
    finally
      decompressionStream.Free;
    end;
  finally
    inputStream.Free;
  end;
  {$ENDIF}
end;


procedure TKMSpritePack.LoadFromRXAAndGenTextures(const aFileName: string);
begin
  LoadFromRXAFile(aFileName);
  {$IFDEF LOAD_GAME_RES_ASYNC}
  GenerateTexturesFromLoadedRXZ(True);
  {$ENDIF}
end;


procedure TKMSpritePack.CollectSpriteFilesToOverloadInFolder(const aFolder: string; aFileList: TStringList);
{$IFDEF WDC}
var
  filePath: string;
  filterPredicate: TDirectory.TFilterPredicate;
{$ENDIF}
begin
  {$IFDEF WDC}
  filterPredicate :=
    function(const aPath: string; const aSearchRec: TSearchRec): Boolean
    var
      tmp: Integer;
    begin
      if ExtractRelativePath(aFolder, aPath).Contains(OVERLOAD_SKIP_MASK) then Exit(False);

      // Search filter we are using makes sure we get only X_*****.png filenames
      // Hence we need to check only for the ***** being digits
      Result := TryStrToInt(Copy(aSearchRec.Name, 3, Length(aSearchRec.Name)-6), tmp);
    end;

  for filePath in TDirectory.GetFiles(aFolder, IntToStr(Ord(fRT) + 1) + '_*.png', TSearchOption.soAllDirectories, filterPredicate) do
    aFileList.Add(ExtractRelativePath(aFolder, filePath));
  {$ENDIF}
end;


procedure TKMSpritePack.OverloadGeneratedFromFolder(aAlphaShadows: Boolean; const aFolder: string; aSoftenShadows: Boolean = True;
                                                    aOnCheckTerminated: TBooleanFuncSimple = nil);
  // Append all PNGs including the subfolders
  // Pattern is X_nnnn.png, where nnnn is dynamic (1..n chars) for modders convenience
  procedure AppendFolder(idList: TList<Integer>);
  var
    I, id: Integer;
    fileList: TStringList;
    s: string;
  begin
    fileList := TStringList.Create;
    CollectSpriteFilesToOverloadInFolder(aFolder, fileList);
    try
      // Going in reverse allows us to allocate max required sprites early on (since filesnames usually come sorted by name)
      for I := fileList.Count - 1 downto 0 do
      begin
        s := ExtractFileName(fileList.Strings[I]);
        if TryStrToInt(Copy(s, 3, Length(s)-6), id) then
        begin
          AddImage(aFolder, fileList.Strings[I], id, True);
          idList.Add(id);
        end;
      end;

      // Soften shadows for overloaded sprites
      if aSoftenShadows then
        SoftenShadowsList(idList);

      // Determine objects size only for units (used for hitbox)
      //todo: do we need it for houses too ?
      if fRT = rxUnits then
        DetermineImagesObjectSizeList(idList);
    finally
      fileList.Free;
    end;
  end;

var
  idList: TList<Integer>;
begin
  if SKIP_RENDER then Exit;
  if not DirectoryExists(aFolder) then Exit;

  {$IFDEF WDC}
  idList := TList<Integer>.Create;
  try
    AppendFolder(idList);
    {$IFNDEF NO_OGL}
    MakeGFX(aAlphaShadows, idList, False, aOnCheckTerminated);
    {$ENDIF}
  finally
    idList.Free;
  end;
  {$ENDIF}
end;


// Parse all valid files in Sprites folder:
// - append or replace original sprites with new ones
// - exclude original sprites if necessary as well
procedure TKMSpritePack.OverloadRXDataFromFolder(const aFolder: string; aOnProgress: TProc<string>; aSoftenShadows: Boolean = True);
  {$IFDEF WDC}
  // Append all PNGs including the subfolders
  // Pattern is X_nnnn.png, where nnnn is dynamic (1..n chars) for modders convenience
  procedure AppendFolder;
  var
    I, id: Integer;
    fileList: TStringList;
    idList: TList<Integer>;
    s: string;
  begin
    idList := TList<Integer>.Create;
    fileList := TStringList.Create;
    CollectSpriteFilesToOverloadInFolder(aFolder, fileList);
    try
      // Going in reverse allows us to allocate max required sprites early on (since filesnames usually come sorted by name)
      for I := fileList.Count - 1 downto 0 do
      begin
        s := ExtractFileName(fileList.Strings[I]);
        if TryStrToInt(Copy(s, 3, Length(s)-6), id) then
        begin
          AddImage(aFolder, fileList.Strings[I], id);
          idList.Add(id);
        end;

        // When packing RXX with HD anims the sheer count is so large we need a progress updates
        if (fileList.Count - I) mod 2500 = 0 then
          if Assigned(aOnProgress) then
            aOnProgress(Format('Appending from folder %d/%d', [fileList.Count - I, fileList.Count]));
      end;

      // Soften shadows for overloaded sprites
      if aSoftenShadows then
        SoftenShadowsList(idList);

      // Determine objects size only for units (used for hitbox)
      //todo: do we need it for houses too ?
      if fRT = rxUnits then
        DetermineImagesObjectSizeList(idList);
    finally
      idList.Free;
      fileList.Free;
    end;
  end;

  // Delete the extra sprites denoted by the X_**** filenames (without extensions)
  procedure DeleteExtra;
  var
    id: Integer;
    filePath, s: string;
    filterPredicate: TDirectory.TFilterPredicate;
  begin
    filterPredicate :=
      function(const aPath: string; const aSearchRec: TSearchRec): Boolean
      var
        tmp: Integer;
      begin
        if ExtractRelativePath(aFolder, aPath).Contains(OVERLOAD_SKIP_MASK) then Exit(False);

        // Search filter we are using makes sure we get only X_***** filenames
        // Hence we need to check only for the ***** being digits
        Result := TryStrToInt(Copy(aSearchRec.Name, 3, Length(aSearchRec.Name)-2), tmp);
      end;

    for filePath in TDirectory.GetFiles(aFolder, IntToStr(Ord(fRT) + 1) + '_*', TSearchOption.soAllDirectories, filterPredicate) do
    begin
      //todo: Would be much simpler if we had our own folder parser ..
      // so we could do our thing right in the callback, without need to iterate over the temp string array
      s := ExtractFileName(filePath);
      if TryStrToInt(Copy(s, 3, Length(s)-2), id) then
        fRXData.Flag[id] := 0;
    end;
  end;
  {$ENDIF}
begin
  if SKIP_RENDER then Exit;
  if not DirectoryExists(aFolder) then Exit;

  {$IFDEF WDC}
  AppendFolder;
  DeleteExtra;
  {$ENDIF}
end;


// Export RX to Bitmaps without need to have GraphicsEditor, also this way we preserve image indexes
procedure TKMSpritePack.ExportAllSpritesFromRXData(const aFolder: string);
var
  I: Integer;
begin
  ForceDirectories(aFolder);

  for I := 1 to fRXData.Count do
  if not TThread.CheckTerminated then
    ExportFullImageData(aFolder, I);
end;


procedure TKMSpritePack.ExportFullImageData(const aFolder: string; aIndex: Integer);
var
  s: string;
begin
  if fRXData.Flag[aIndex] <> 1 then Exit;

  ExportImage(aFolder + Format('%d_%.4d.png', [Ord(fRT)+1, aIndex]), aIndex);

  if fRXData.HasMask[aIndex] then
    ExportMask(aFolder + Format('%d_%.4da.png', [Ord(fRT)+1, aIndex]), aIndex);

  // Pivot
  s := IntToStr(fRXData.Pivot[aIndex].x) + sLineBreak + IntToStr(fRXData.Pivot[aIndex].y) + sLineBreak;

  //SizeNoShadow is used only for Units
  if fRT = rxUnits then
    s := s + IntToStr(fRXData.SizeNoShadow[aIndex].Left) + sLineBreak +
      IntToStr(fRXData.SizeNoShadow[aIndex].Top) + sLineBreak +
      IntToStr(fRXData.SizeNoShadow[aIndex].Right) + sLineBreak +
      IntToStr(fRXData.SizeNoShadow[aIndex].Bottom) + sLineBreak;

  WriteTextUtf8(s, aFolder + Format('%d_%.4d.txt', [Ord(fRT)+1, aIndex]));
end;


procedure TKMSpritePack.ExportImage(const aFile: string; aIndex: Integer);
var
  I, K: Integer;
  M: Byte;
  treatMask: Boolean;
  pngWidth, pngHeight: Word;
  pngData: TKMCardinalArray;
begin
  pngWidth := fRXData.Size[aIndex].X;
  pngHeight := fRXData.Size[aIndex].Y;

  SetLength(pngData, pngWidth * pngHeight);

  //Export RGB values
  for I := 0 to pngHeight - 1 do
  for K := 0 to pngWidth - 1 do
  begin
    treatMask := fRXData.HasMask[aIndex] and (fRXData.Mask[aIndex, I*pngWidth + K] > 0);
    if (fRT = rxHouses)
      and ((aIndex < 680)
        or (aIndex = 1657)
        or (aIndex = 1659)
        or (aIndex = 1681)
        or (aIndex = 1683)
        or (aIndex > 2050)) then
      treatMask := False;

    if treatMask then
    begin
      M := fRXData.Mask[aIndex, I*pngWidth + K];

      //Replace background with corresponding brightness of Red
      if fRXData.RGBA[aIndex, I*pngWidth + K] = FLAG_COLOR_DARK then
        //Brightness < 0.5, mix with black
        pngData[I*pngWidth + K] := M
      else
        //Brightness > 0.5, mix with white
        pngData[I*pngWidth + K] := $FF + (255 - M) * $010100;
    end
    else
      pngData[I*pngWidth + K] := fRXData.RGBA[aIndex, I*pngWidth + K] and $FFFFFF;

    pngData[I*pngWidth + K] := pngData[I*pngWidth + K] or (fRXData.RGBA[aIndex, I*pngWidth + K] and $FF000000);
  end;

  //Mark pivot location with a dot
//  K := pngWidth + fRXData.Pivot[aIndex].x;
//  I := pngHeight + fRXData.Pivot[aIndex].y;
//  if InRange(I, 0, pngHeight-1) and InRange(K, 0, pngWidth-1) then
//    pngData[I*pngWidth + K] := $FFFF00FF;

  SaveToPng(pngWidth, pngHeight, pngData, aFile);
end;


procedure TKMSpritePack.ExportMask(const aFile: string; aIndex: Integer);
var
  I, K: Integer;
  pngWidth, pngHeight: Word;
  pngData: TKMCardinalArray;
  maskColor: Cardinal;
begin
  pngWidth := fRXData.Size[aIndex].X;
  pngHeight := fRXData.Size[aIndex].Y;

  SetLength(pngData, pngWidth * pngHeight);

  //Export Mask
  if fRXData.HasMask[aIndex] then
  begin
    for I := 0 to pngHeight - 1 do
      for K := 0 to pngWidth - 1 do
      begin
        if fRT = rxHouses then
        begin
          maskColor := fRXData.Mask[aIndex, I * pngWidth + K];
          if maskColor <> 0 then
            maskColor := GetGreyColor(maskColor) or $FF000000;
        end else
          maskColor := (Byte(fRXData.Mask[aIndex, I * pngWidth + K] > 0) * $FFFFFF) or $FF000000;
        pngData[I * pngWidth + K] := maskColor;
      end;

    SaveToPng(pngWidth, pngHeight, pngData, aFile);
  end;
end;


function TKMSpritePack.GetAverageSpriteColors(aCount: Integer): TKMColor3bArray;
var
  I, L, M: Integer;
  pixelCount: Cardinal;
  accR, accG, accB: Cardinal;
begin
  SetLength(Result, Min(fRXData.Count, aCount));

  for I := 1 to Min(fRXData.Count, aCount) do
  begin
    accR := 0;
    accG := 0;
    accB := 0;

    for L := 0 to fRXData.Size[I].Y - 1 do
    for M := 0 to fRXData.Size[I].X - 1 do
    begin
      Inc(accR, fRXData.RGBA[I, L * fRXData.Size[I].X + M] and $FF);
      Inc(accG, fRXData.RGBA[I, L * fRXData.Size[I].X + M] shr 8 and $FF);
      Inc(accB, fRXData.RGBA[I, L * fRXData.Size[I].X + M] shr 16 and $FF);
    end;

    pixelCount := Max(1, fRXData.Size[I].X * fRXData.Size[I].Y);
    Result[I-1].R := Round(accR / pixelCount);
    Result[I-1].G := Round(accG / pixelCount);
    Result[I-1].B := Round(accB / pixelCount);
  end;
end;


function TKMSpritePack.IsEmpty: Boolean;
begin
  Result := fRXData.Count = 0;
end;


{$IFNDEF NO_OGL}
// Take RX data and make nice atlas texture out of it
// Atlases should be POT to improve performance and avoid driver bugs
// In result we have GFXData structure filled
procedure TKMSpritePack.MakeGFX(aAlphaShadows: Boolean; aStartingIndex: Integer = 1; aFillGFXData: Boolean = True; aOnCheckTerminated: TBooleanFuncSimple = nil);
var
  I: Integer;
  idList: TList<Integer>;
begin
  idList := TList<Integer>.Create;
  try
    for I := aStartingIndex to fRXData.Count do
      idList.Add(I);

    MakeGFX(aAlphaShadows, idList, aFillGFXData, aOnCheckTerminated);
  finally
    idList.Free;
  end;
end;


procedure TKMSpritePack.MakeGFX(aAlphaShadows: Boolean; aIDList: TList<Integer>; aFillGFXData: Boolean = True; aOnCheckTerminated: TBooleanFuncSimple = nil);
var
  I, K: Integer;
  texType: TKMTexFormat;
  baseRAM, idealRAM, colorRAM, texCount: Cardinal;
begin
  if SKIP_RENDER then Exit;
  if fRXData.Count = 0 then Exit;

  if aAlphaShadows and (fRT in [rxTrees,rxHouses,rxUnits,rxGui,rxTiles]) or not aAlphaShadows and (fRT = rxGuiMain) then
    texType := tfRGBA8
  else
    texType := tfRGB5A1;

  MakeGFX_BinPacking(texType, aIDList, baseRAM, colorRAM, texCount, aFillGFXData, aOnCheckTerminated);

  if LOG_EXTRA_GFX then
  begin
    idealRAM := 0;
    for K := 0 to aIDList.Count - 1 do
    begin
      I := aIDList[K];
      if fRXData.Flag[I] <> 0 then
        Inc(idealRAM, fRXData.Size[I].X * fRXData.Size[I].Y * TEX_FORMAT_SIZE[texType]);
    end;

    gLog.AddTime(IntToStr(texCount) + ' Textures created');
    gLog.AddNoTime(Format('%d/%d', [baseRAM div 1024, idealRAM div 1024]) +
                  ' Kbytes allocated/ideal for ' + RX_INFO[fRT].FileName + ' GFX when using Packing');
    gLog.AddNoTime(IntToStr(colorRAM div 1024) + ' KBytes for team colors');
  end;
end;



//Set GFXData from SpriteInfo
procedure TKMSpritePack.SetGFXData(aTexID: Cardinal; aSpriteInfo: TKMBinItem; aAtlasType: TKMSpriteAtlasType);
var
  K: Integer;
  spriteID: Integer;
  txCoords: TKMTexCoords;
begin
  for K := 0 to High(aSpriteInfo.Sprites) do
  begin
    spriteID := aSpriteInfo.Sprites[K].SpriteID;

    txCoords.TexID := aTexID;
    txCoords.u1 := aSpriteInfo.Sprites[K].OriginX / aSpriteInfo.Width;
    txCoords.v1 := aSpriteInfo.Sprites[K].OriginY / aSpriteInfo.Height;
    txCoords.u2 := (aSpriteInfo.Sprites[K].OriginX + fRXData.Size[spriteID].X) / aSpriteInfo.Width;
    txCoords.v2 := (aSpriteInfo.Sprites[K].OriginY + fRXData.Size[spriteID].Y) / aSpriteInfo.Height;

    if aAtlasType = saBase then
    begin
      gGFXData[fRT, spriteID].Tex := txCoords;
      gGFXData[fRT, spriteID].PxWidth := fRXData.Size[spriteID].X;
      gGFXData[fRT, spriteID].PxHeight := fRXData.Size[spriteID].Y;
    end
    else
      gGFXData[fRT, spriteID].Alt := txCoords;
  end;
end;


procedure TKMSpritePack.MakeGFX_BinPacking(aTexType: TKMTexFormat; aStartingIndex: Integer; var aBaseRAM, aColorRAM, aTexCount: Cardinal;
                                           aFillGFXData: Boolean = True; aOnCheckTerminated: TBooleanFuncSimple = nil);
var
  I: Integer;
  idList: TList<Integer>;
begin
  idList := TList<Integer>.Create;
  try
    for I := aStartingIndex to fRXData.Count do
      idList.Add(I);

    MakeGFX_BinPacking(aTexType, idList, aBaseRAM, aColorRAM, aTexCount, aFillGFXData, aOnCheckTerminated);
  finally
    idList.Free;
  end;
end;


procedure TKMSpritePack.PrepareAtlases(aSpriteInfo: TBinArray; aMode: TKMSpriteAtlasType; aTexType: TKMTexFormat; var aBaseRAM, aColorRAM, aTexCount: Cardinal;
                                       aFillGFXData: Boolean = True; aOnCheckTerminated: TBooleanFuncSimple = nil);
var
  I, K, L, M: Integer;
  CT, CL, Pixel: Cardinal;
  texID: Cardinal;
  ID: Integer;
  atlasData: TKMCardinalArray;
  texFilter: TKMFilterType;
begin
//  gLog.AddTime('Length(aSpriteInfo) = ' + IntToStr(Length(aSpriteInfo)));
  //Prepare atlases
  for I := 0 to Length(aSpriteInfo) - 1 do
  begin
//    if I * 2 + 1 >= I - 1 then
//      gLog.AddTime('I = ' + IntToStr(I));
    Assert(MakePOT(aSpriteInfo[I].Width) = aSpriteInfo[I].Width);
    Assert(MakePOT(aSpriteInfo[I].Height) = aSpriteInfo[I].Height);
    SetLength(atlasData, 0);
    SetLength(atlasData, aSpriteInfo[I].Width * aSpriteInfo[I].Height);

    //Copy sprite to Atlas
    for K := 0 to High(aSpriteInfo[I].Sprites) do
    begin
      ID := aSpriteInfo[I].Sprites[K].SpriteID;
      for L := 0 to fRXData.Size[ID].Y - 1 do
      for M := 0 to fRXData.Size[ID].X - 1 do
      begin
        CT := aSpriteInfo[I].Sprites[K].OriginY;
        CL := aSpriteInfo[I].Sprites[K].OriginX;
        Pixel := (CT + L) * aSpriteInfo[I].Width + CL + M;
        if aMode = saBase then
          atlasData[Pixel] := fRXData.RGBA[ID, L * fRXData.Size[ID].X + M]
        else
          atlasData[Pixel] := $FFFFFF or (fRXData.Mask[ID, L * fRXData.Size[ID].X + M] shl 24);

        //Fill padding with edge pixels
        if fPad > 0 then
        begin
          if (M = 0) then
          begin
            atlasData[Pixel - 1] := atlasData[Pixel];
            if (L = 0) then
              atlasData[Pixel - aSpriteInfo[I].Width - 1] := atlasData[Pixel]
            else
            if (L = fRXData.Size[ID].Y - 1) then
              atlasData[Pixel + aSpriteInfo[I].Width - 1] := atlasData[Pixel];
          end;

          if (M = fRXData.Size[ID].X - 1) then
          begin
            atlasData[Pixel + 1] := atlasData[Pixel];
            if (L = 0) then
              atlasData[Pixel - aSpriteInfo[I].Width + 1] := atlasData[Pixel]
            else
            if (L = fRXData.Size[ID].Y - 1) then
              atlasData[Pixel + aSpriteInfo[I].Width + 1] := atlasData[Pixel];
          end;

          if (L = 0) then                       atlasData[Pixel - aSpriteInfo[I].Width] := atlasData[Pixel];
          if (L = fRXData.Size[ID].Y - 1) then  atlasData[Pixel + aSpriteInfo[I].Width] := atlasData[Pixel];
        end;

        //Sprite outline
        if OUTLINE_ALL_SPRITES and (
          (L = 0) or (M = 0)
          or (L = fRXData.Size[ID].Y - 1)
          or (M = fRXData.Size[ID].X - 1)) then
          atlasData[Pixel] := $FF0000FF;
      end;
    end;

    if aFillGFXData then
    begin
      //Generate texture once
      texFilter := ftNearest;
      if LINEAR_FILTER_SPRITES and (fRT in [rxTrees, rxHouses, rxUnits]) then
        texFilter := ftLinear;

      texID := TKMRender.GenTexture(aSpriteInfo[I].Width, aSpriteInfo[I].Height, @atlasData[0], aTexType, texFilter, texFilter);

      //Now that we know texture IDs we can fill GFXData structure
      SetGFXData(texID, aSpriteInfo[I], aMode);
    end else
    begin
      Assert(InRange(I, Low(fAtlases[aMode]), High(fAtlases[aMode])),
             Format('Preloading sprite index out of range: %d, range [%d;%d]', [I, Low(fAtlases[aMode]), High(fAtlases[aMode])]));
      // Save prepared data for generating later (in main thread)
      fAtlases[aMode, I].Container := aSpriteInfo[I];
      fAtlases[aMode, I].TexType := aTexType;
      fAtlases[aMode, I].Data := atlasData;
    end;

    if aMode = saBase then
      Inc(aBaseRAM, aSpriteInfo[I].Width * aSpriteInfo[I].Height * TEX_FORMAT_SIZE[aTexType])
    else
      Inc(aColorRAM, aSpriteInfo[I].Width * aSpriteInfo[I].Height * TEX_FORMAT_SIZE[aTexType]);

    Inc(aTexCount);

    if aFillGFXData and EXPORT_SPRITE_ATLASES and (fRT in EXPORT_SPRITE_ATLASES_LIST) then
      SaveToPng(aSpriteInfo[I].Width, aSpriteInfo[I].Height, atlasData,
        ExeDir + 'Export\GenTextures\' + RX_INFO[fRT].FileName + '_' + SPRITE_TYPE_EXPORT_NAME[aMode] + IntToStr(I) + '.png');
  end;
end;


// This algorithm is planned to take advantage of more efficient 2D bin packing
procedure TKMSpritePack.MakeGFX_BinPacking(aTexType: TKMTexFormat; aIDList: TList<Integer>; var aBaseRAM, aColorRAM, aTexCount: Cardinal;
                                           aFillGFXData: Boolean = True; aOnCheckTerminated: TBooleanFuncSimple = nil);
  function CheckTerminated: Boolean;
  begin
    Result := Assigned(aOnCheckTerminated) and aOnCheckTerminated;
  end;

var
  I, J, K: Integer;
  spriteSizes: TIndexSizeArray;
  spriteInfo: TBinArray;
  atlasSize, allTilesAtlasSize: Integer;
begin
  aBaseRAM := 0;
  aColorRAM := 0;
  //Prepare base atlases
  SetLength(spriteSizes, aIDList.Count);// fRXData.Count - aStartingIndex + 1);
  K := 0;
  for J := 0 to aIDList.Count - 1 do
  begin
    I := aIDList[J];
    if (fRXData.Size[I].X * fRXData.Size[I].Y <> 0) and (Length(fRXData.RGBA[I]) > 0) then
    begin
      spriteSizes[K].ID := I;
      spriteSizes[K].X := fRXData.Size[I].X;
      spriteSizes[K].Y := fRXData.Size[I].Y;
      Inc(K);
    end;
  end;
  SetLength(spriteSizes, K);

  //For RX with only 1 texture we can set small size, as 512, it will be auto enlarged to POT(image size)
  if K = 1 then
    atlasSize := 512
  else if fRT = rxTiles then
  begin
    allTilesAtlasSize := MakePOT(Ceil(sqrt(K))*(32+2*fPad)); //Tiles are 32x32
    atlasSize := Min(GetMaxAtlasSize, allTilesAtlasSize);       //Use smallest possible atlas size for tiles (should be 1024, until many new tiles were added)
    if atlasSize = allTilesAtlasSize then
      AllTilesInOneTexture := True;
  end else
    atlasSize := GetMaxAtlasSize;

  SetLength(spriteInfo, 0);
  BinPack(spriteSizes, atlasSize, fPad, spriteInfo);

  if CheckTerminated then Exit; //Our thread could be terminated and asked to stop. Exit immediately then

  SetLength(fAtlases[saBase], Length(spriteInfo));

  PrepareAtlases(spriteInfo, saBase, aTexType, aBaseRAM, aColorRAM, aTexCount, aFillGFXData, aOnCheckTerminated);

  if CheckTerminated then Exit;

  //Prepare masking atlases
  SetLength(spriteSizes, aIDList.Count);
  K := 0;
  for J := 0 to aIDList.Count - 1 do
  begin
    I := aIDList[J];
    if (fRXData.Size[I].X * fRXData.Size[I].Y <> 0) and fRXData.HasMask[I] and (Length(fRXData.Mask[I]) > 0) then
    begin
      spriteSizes[K].ID := I;
      spriteSizes[K].X := fRXData.Size[I].X;
      spriteSizes[K].Y := fRXData.Size[I].Y;
      Inc(K);
    end;
  end;
  SetLength(spriteSizes, K);

  SetLength(spriteInfo, 0);
  BinPack(spriteSizes, atlasSize, fPad, spriteInfo);
  if CheckTerminated then Exit;
  SetLength(fAtlases[saMask], Length(spriteInfo));
  PrepareAtlases(spriteInfo, saMask, tfAlpha8, aBaseRAM, aColorRAM, aTexCount, aFillGFXData, aOnCheckTerminated);
end;
{$ENDIF}


procedure TKMSpritePack.ClearGameResGenTemp;
var
  SAT: TKMSpriteAtlasType;
begin
  for SAT := Low(fAtlases) to High(fAtlases) do
    SetLength(fAtlases[SAT], 0);
end;


{$IFDEF LOAD_GAME_RES_ASYNC}
// Generate texture atlases from previosly prepared SpriteInfo data (loaded from RXX, Bin Packed, copied to atlas)
// Preparation was done asynchroniously by TTGameResourceLoader thread
// Texture generating task can be done only by main thread, as OpenGL does not work with multiple threads
// Note: this could be from the loader thread by using `Synchronise` procedure
procedure TKMSpritePack.GenerateTexturesFromLoadedRXZ(aIsRXA: Boolean);
{$IFNDEF NO_OGL}
var
  I: Integer;
  SAT: TKMSpriteAtlasType;
  texID: Cardinal;
  texFilter: TKMFilterType;
{$ENDIF}
begin
  {$IFNDEF NO_OGL}
  for SAT := Low(fAtlases) to High(fAtlases) do
    for I := Low(fAtlases[SAT]) to High(fAtlases[SAT]) do
    begin
      with fAtlases[SAT,I] do
      begin
        texFilter := ftNearest;
        if LINEAR_FILTER_SPRITES and (fRT in [rxTrees, rxHouses, rxUnits]) then
          texFilter := ftLinear;

        texID := TKMRender.GenTexture(Container.Width, Container.Height, @Data[0], TexType, texFilter, texFilter);
        //Now that we know texture IDs we can fill GFXData structure
        SetGFXData(texID, Container, SAT);

        if ((not aIsRXA and EXPORT_SPRITE_ATLASES) or (aIsRXA and EXPORT_SPRITE_ATLASES_RXA))
        and (fRT in EXPORT_SPRITE_ATLASES_LIST) then
          SaveToPng(Container.Width, Container.Height, Data,
            ExeDir + 'Export\GenTextures\' + RX_INFO[fRT].FileName + IfThen(aIsRXA, '_rxa_', '_') + SPRITE_TYPE_EXPORT_NAME[SAT] + IntToStr(texID) + '.png');
      end;
    end;
  {$ENDIF}
end;
{$ENDIF}


{ TKMResSprites }
constructor TKMResSprites.Create(aStepProgress: TKMEvent = nil; aStepCaption: TUnicodeStringEvent = nil; aTemp: Boolean = False);
var
  RT: TRXType;
begin
  inherited Create;

  fGameRXTypes := TStringList.Create;
  fTemp := aTemp;

  for RT := Low(TRXType) to High(TRXType) do
  begin
    fSprites[RT] := TKMSpritePack.Create(RT, fTemp);
    if RX_INFO[RT].Usage = ruGame then
      fGameRXTypes.Add(IntToStr(Integer(RT)));
  end;

  fStepProgress := aStepProgress;
  fStepCaption := aStepCaption;
end;


destructor TKMResSprites.Destroy;
var
  RT: TRXType;
begin
  fGameRXTypes.Free;
  {$IFDEF LOAD_GAME_RES_ASYNC}
  // Stop resource loader before Freeing SpritePack, as loader use fRXData and could get an exception there on game exit
  if fGameResLoader <> nil then
    StopAsyncResourceLoader;
  {$ENDIF}

  for RT := Low(TRXType) to High(TRXType) do
    fSprites[RT].Free;

  inherited;
end;


//Clear unused RAM
procedure TKMResSprites.ClearTemp;
var
  RT: TRXType;
begin
  for RT := Low(TRXType) to High(TRXType) do
  begin
    fSprites[RT].ClearTemp;
    fSprites[RT].ClearGameResGenTemp; //Its probably empty for a menu resources, but anyway
  end;
end;


{$IFDEF LOAD_GAME_RES_ASYNC}
//Get next game resource RXType to load. Returns -1 if its the last one
function TKMResSprites.GetNextLoadRxTypeIndex(aRT: TRXType): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to fGameRXTypes.Count - 1 do
    if StrToInt(fGameRXTypes[I]) = Integer(aRT) then
    begin
      if I = fGameRXTypes.Count - 1 then
        Exit(-1)
      else
        Exit(I + 1);
    end;
end;
{$ENDIF}


//aLegacyGeneration - support for maps with rev <= r10745, where transitions were written as generated terrain Id
//instead of generation parameters (TekKind + FullMaskType)
//Also there was no mkSoft mask and tkSnowOnTerrain terrain kind
procedure TKMResSprites.GenerateTerrainTransitions(aSprites: TKMSpritePack; aLegacyGeneration: Boolean = False);
//  procedure Rotate(aAngle: Byte; aXFrom, aYFrom: Integer; var aXTo, aYTo: Integer; aBase: Integer);
//  begin
//    case aAngle of
//      0:  begin
//            aXTo := aXFrom;
//            aYTo := aYFrom;
//          end;
//      1:  begin
//            aYTo := aXFrom;
//            aXTo := aBase - aYFrom;
//          end;
//      2:  begin
//            aXTo := aBase - aXFrom;
//            aYTo := aBase - aYFrom;
//          end;
//      3:  begin
//            aXTo := aYFrom;
//            aYTo := aBase - aXFrom;
//          end
//      else raise Exception.Create('Wrong Rotate angle');
//    end;
//
//  end;

var
  TK: TKMTerrainKind;
  MK: TKMTileMaskKind;
  MT: TKMTileMaskType;
  MST: TKMTileMaskSubType;
  terrainId, maskId: Word;
  maskFullType: TKMMaskFullType;
  genTerrainInfo: TKMGenTerrainInfo;

  texId,{ K,} L, M, tmp, totalTex, uniqueTex: Integer;
  genTilesCnt, genTilesCntTemp: Integer;
  straightPx{, RotatePixel}, maskCol: Cardinal;
  generatedMasks: TDictionary<Integer, TKMMaskFullType>;
begin
  Assert(not aLegacyGeneration or (aSprites = nil));

  gLog.AddTime('GenerateTerrainTransitions started. Legacy = ' + BoolToStr(aLegacyGeneration, True));

  if aLegacyGeneration then
  begin
    //static arrays could be reset via its variable
    FillChar(fGenTerrainTransitionsLegacy, SizeOf(fGenTerrainTransitionsLegacy), #0); //Init array, it could be init on previous tileset load
    texId := 4999;
    fGenTexIdStartILegacy := texId;
    genTilesCntTemp := (Integer(High(TKMTerrainKind)) - 1)*Integer(High(TKMTileMaskKind))
                   *Integer(High(TKMTileMaskType))*(Integer(High(TKMTileMaskSubType)) + 1);
    SetLength(fGenTerrainToTerKindLegacy, genTilesCntTemp);
    FillChar(fGenTerrainToTerKindLegacy[0], SizeOf(fGenTerrainToTerKindLegacy[0])*GenTilesCntTemp, #0);
    gLog.AddTime('Legacy: TexId = %d GenTilesCntTemp = %d', [texId, genTilesCntTemp]);
  end
  else
  begin
    //static arrays could be reset via its variable
    FillChar(fGenTerrainTransitions, SizeOf(fGenTerrainTransitions), #0); //Init array, it could be init on previous tileset load
    texId := Length(aSprites.fRXData.RGBA) + 1;
    fGenTexIdStartI := texId;
    genTilesCnt := Integer(High(TKMTerrainKind))*Integer(High(TKMTileMaskKind))
                   *Integer(High(TKMTileMaskType))*(Integer(High(TKMTileMaskSubType)) + 1);
    SetLength(fGenTerrainToTerKind, genTilesCnt);
    aSprites.Allocate(texId + genTilesCnt);
    FillChar(fGenTerrainToTerKind[0], SizeOf(fGenTerrainToTerKind[0])*GenTilesCnt, #0);
    gLog.AddTime('TexId = %d GenTilesCnt = %d', [texId, genTilesCnt]);
  end;

  generatedMasks := TDictionary<Integer, TKMMaskFullType>.Create;
  totalTex := 0;
  uniqueTex := 0;
//  K := 0;
  try
    //for all Terrain Kinds
    for TK := Succ(tkCustom) to High(TKMTerrainKind) do
    begin
      if aLegacyGeneration and (TK = tkSnowOnGrass) then Continue;

      terrainId := BASE_TERRAIN[TK] + 1; // in fRXData Tiles are 1-based

      //for all Mask Kinds
      for MK := Succ(mkNone) to High(TKMTileMaskKind) do
      begin
        if aLegacyGeneration and (MK = mkSoft2) then Continue;

        //for all Mask Types
        for MT := Succ(tmtNone) to High(TKMTileMaskType) do
        begin
          // for all Mask subtypes
          for MST := Low(TKMTileMaskSubType) to High(TKMTileMaskSubType) do //Mask subtypes (actual masks for layers)
          begin
            maskId := TILE_MASKS_FOR_LAYERS[MK, MT, MST] + 1;
            if maskId = 0 then Continue;   //Ignore non existent masks

            Inc(totalTex);

            // We could use same mask image for several masktypes/subtypes
            if generatedMasks.TryGetValue(maskId, maskFullType) then
            begin
              if aLegacyGeneration then
                tmp := fGenTerrainTransitionsLegacy[TK, maskFullType.Kind, maskFullType.MType, maskFullType.SubType]
              else
                tmp := fGenTerrainTransitions[TK, maskFullType.Kind, maskFullType.MType, maskFullType.SubType];

              if tmp <> 0 then
              begin
                if aLegacyGeneration then
                  fGenTerrainTransitionsLegacy[TK, MK, MT, MST] := tmp
                else
                  fGenTerrainTransitions[TK, MK, MT, MST] := tmp;
                Continue;
              end;
            end else begin
              maskFullType.Kind := MK;
              maskFullType.MType := MT;
              maskFullType.SubType := MST;
              generatedMasks.Add(maskId, maskFullType);
            end;

    //        for K := 0 to 3 do //Rotation
    //        begin
              genTerrainInfo.TerKind := TK;
              genTerrainInfo.Mask.Kind := MK;
              genTerrainInfo.Mask.MType := MT;
              genTerrainInfo.Mask.SubType := MST;

              if aLegacyGeneration then
              begin
                fGenTerrainTransitionsLegacy[TK, MK, MT, MST] := texId - 1;
                fGenTerrainToTerKindLegacy[texId - fGenTexIdStartILegacy] := genTerrainInfo;
              end
              else
              begin
                SetLength(aSprites.fRXData.RGBA[texId], aSprites.fRXData.Size[terrainId].X*aSprites.fRXData.Size[terrainId].Y); //32*32 actually...
                SetLength(aSprites.fRXData.Mask[texId], aSprites.fRXData.Size[terrainId].X*aSprites.fRXData.Size[terrainId].Y);
                aSprites.fRXData.Flag[texId] := aSprites.fRXData.Flag[terrainId];
                aSprites.fRXData.Size[texId].X := aSprites.fRXData.Size[terrainId].X;
                aSprites.fRXData.Size[texId].Y := aSprites.fRXData.Size[terrainId].Y;
                aSprites.fRXData.Pivot[texId] := aSprites.fRXData.Pivot[terrainId];
                aSprites.fRXData.HasMask[texId] := False;
                fGenTerrainTransitions[TK, MK, MT, MST] := texId - 1; //TexId is 1-based, but textures we use - 0 based
                fGenTerrainToTerKind[texId - fGenTexIdStartI] := genTerrainInfo;
              
    //          gLog.AddTime('TerKind: %10s Mask: %10s TexId: %d ', [
    //            GetEnumName(TypeInfo(TKMTerrainKind), Integer(I)),
    //            GetEnumName(TypeInfo(TKMTileMaskType), Integer(J)), TexId]);

    //          fGenTerrainToTerKind.Add(IntToStr(TexId) + '=' + IntToStr(Integer(I)));
                for L := 0 to aSprites.fRXData.Size[terrainId].Y - 1 do
                  for M := 0 to aSprites.fRXData.Size[terrainId].X - 1 do
                  begin
      //              Rotate(K, L, M, P, Q, aSprites.fRXData.Size[TerrainId].X - 1);
                    straightPx := L * aSprites.fRXData.Size[terrainId].X  + M;
      //              RotatePixel := StraightPixel; //P * aSprites.fRXData.Size[TerrainId].X  + Q;

                    case TILE_MASK_KIND_USAGE[MK] of
                      mkuPixel: maskCol := ($FFFFFF or (aSprites.fRXData.RGBA[maskId, straightPx] shl 24));
                      mkuAlpha: maskCol := aSprites.fRXData.RGBA[maskId, straightPx];
                    else
                      raise Exception.Create('Unexpected type');
                    end;

                    aSprites.fRXData.RGBA[texId, straightPx] := maskCol and aSprites.fRXData.RGBA[terrainId, straightPx{RotatePixel}];
                  end;
              end;
              Inc(uniqueTex);
              Inc(texId);
    //        end;
          end;
        end;
      end;
    end;

    if aLegacyGeneration then
    begin
      SetLength(fGenTerrainToTerKindLegacy, texId - fGenTexIdStartILegacy);
      gLog.AddTime('TexId = %d; TexId - fGenTexIdStartILegacy = %d; uniqueTex = %d; totalTex = %d', [texId, texId - fGenTexIdStartILegacy, uniqueTex, totalTex]);
    end
    else
    begin
      // There could be usused place in arrays, as we could use same mask image for different purposes
      aSprites.Allocate(texId);
      SetLength(fGenTerrainToTerKind, texId - fGenTexIdStartI);
      gLog.AddTime('TexId = %d; TexId - fGenTexIdStartI = %d; uniqueTex = %d; totalTex = %d', [texId, texId - fGenTexIdStartI, uniqueTex, totalTex]);
    end;

  finally
    gLog.AddTime('GeneratedMasks cnt = ' + IntToStr(generatedMasks.Count));
    generatedMasks.Free;
  end;
  gLog.AddTime('GenerateTerrainTransitions Done');
end;


function TKMResSprites.GetGenTerrainInfo(aTerrain: Integer): TKMGenTerrainInfo;
begin
  Assert(aTerrain + 1 - fGenTexIdStartI < Length(fGenTerrainToTerKind),
         Format('Trying to get terrain info out of range: TileID = %d, GenStart = %d, GenTerrain arr length = %d',
                [aTerrain, fGenTexIdStartI, Length(fGenTerrainToTerKind)]));

  Result := fGenTerrainToTerKind[aTerrain + 1 - fGenTexIdStartI]; //TexId is 1-based, but textures we use - 0 based
end;


function TKMResSprites.GetGenTerrainInfoLegacy(aTerrain: Integer): TKMGenTerrainInfo;
begin
  Assert(aTerrain + 1 - fGenTexIdStartILegacy < Length(fGenTerrainToTerKindLegacy),
         Format('Trying to get terrain info LEGACY out of range: TileID = %d, GenStart = %d, GenTerrain arr length = %d',
                [aTerrain, fGenTexIdStartILegacy, Length(fGenTerrainToTerKindLegacy)]));

  Result := fGenTerrainToTerKindLegacy[aTerrain + 1 - fGenTexIdStartILegacy]; //TexId is 1-based, but textures we use - 0 based
end;


function TKMResSprites.GetRXFileName(aRX: TRXType): string;
begin
  Result := RX_INFO[aRX].FileName;
end;


function TKMResSprites.GetSprites(aRT: TRXType): TKMSpritePack;
begin
  Result := fSprites[aRT];
end;


function TKMResSprites.GetSpritesRXAFilePath(aRT: TRXType): string;
begin
  Result := ExeDir + 'data' + PathDelim + 'Sprites' + PathDelim + RX_INFO[aRT].FileName + '.rxa';
end;


function TKMResSprites.GetGenTerrainTransitions(aTerKind: TKMTerrainKind; aMaskKind: TKMTileMaskKind; aMaskType: TKMTileMaskType; aMaskSubtype: TKMTileMaskSubType): Word;
begin
  Result := fGenTerrainTransitions[aTerKind, aMaskKind, aMaskType, aMaskSubtype];
end;


procedure TKMResSprites.LoadMenuResources;
var
  RT: TRXType;
begin
  for RT := Low(TRXType) to High(TRXType) do
    if RX_INFO[RT].Usage = ruMenu then
    begin
      if Assigned(fStepCaption) then
        fStepCaption('Reading ' + RX_INFO[RT].FileName + ' ...');

      gLog.AddTime('Reading ' + RX_INFO[RT].FileName + '.rx');
      // Only GUI needs alpha channel for shadows
      LoadSprites(RT, RT = rxGUI);
      // We also use alpha channel in the generated tiles
      {$IFNDEF NO_OGL}
      fSprites[RT].MakeGFX(RT in [rxGUI, rxTiles]);
      {$ENDIF}

      if Assigned(fStepProgress) then
        fStepProgress;
    end;
end;


{$IFDEF LOAD_GAME_RES_ASYNC}
procedure TKMResSprites.StopAsyncResourceLoader;
begin
  fGameResLoader.Terminate;
  fGameResLoader.WaitFor;
  FreeThenNil(fGameResLoader);
end;
{$ENDIF}


procedure TKMResSprites.LoadGameResources(aAlphaShadows: Boolean; aForceReload: Boolean = False);

  procedure LoadAllResources;
  var
    RT: TRXType;
  begin
    for RT := Low(TRXType) to High(TRXType) do
      if RX_INFO[RT].Usage = ruGame then
      begin
        if Assigned(fStepCaption) then
          fStepCaption(gResTexts[RX_INFO[RT].LoadingTextID]);

        if fAlphaShadows and FileExists(GetSpritesRXAFilePath(RT)) then
        begin
          gLog.AddTime('Reading ' + RX_INFO[RT].FileName + '.rxa');
          LoadRXASpritesAndGenTextures(RT);
        end
        else
        begin
          gLog.AddTime('Reading ' + RX_INFO[RT].FileName + '.rx');
          LoadSprites(RT, fAlphaShadows);
          {$IFNDEF NO_OGL}
          fSprites[RT].MakeGFX(fAlphaShadows);
          {$ENDIF}
        end;
        // Clear temp data as fast as possible
        fSprites[RT].ClearTemp;
        fSprites[RT].ClearGameResGenTemp;
      end;

    {$IFDEF LOAD_GAME_RES_ASYNC}
    fGameResLoadCompleted := True;
    {$ENDIF}
  end;

begin
  gLog.AddTime('TKMResSprites.LoadGameResources');
  //Remember which version we load, so if it changes inbetween games we reload it
  fAlphaShadows := aAlphaShadows;
  {$IFDEF LOAD_GAME_RES_ASYNC}
  fGameResLoadCompleted := False;
  if gGameSettings.AsyncGameResLoader then
  begin
    if fGameResLoader <> nil then
    begin
      if aForceReload then
        StopAsyncResourceLoader
      else begin
        while not fGameResLoadCompleted do
        begin
          ManageAsyncResLoader('LoadGameResources'); //check if we have some work to do in this thread
          Sleep(5); // wait till load will be completed by fGameResLoader thread
        end;
        Exit;
      end;
    end;

    if aForceReload then
    begin
      fGameResLoadCompleted := False;
      fGameResLoader := TTGameResourceLoader.Create(Self, fAlphaShadows, TRXType(StrToInt(fGameRXTypes[0])));
    end;
  end
  else
    LoadAllResources;
    
  {$ELSE}
  LoadAllResources;
  {$ENDIF}
end;


//Try to load RXX first, then RX, then use Folder
function TKMResSprites.LoadSprites(aRT: TRXType; aAlphaShadows: Boolean): Boolean;
begin
  gLog.AddTime('Load Sprites started');
  Result := False;
  if aAlphaShadows and FileExists(ExeDir + 'data' + PathDelim + 'Sprites' + PathDelim + RX_INFO[aRT].FileName + '_a.rxx') then
  begin
    fSprites[aRT].LoadFromRXXFile(ExeDir + 'data' + PathDelim + 'Sprites' + PathDelim + RX_INFO[aRT].FileName + '_a.rxx');
    Result := True;
  end
  else
  if FileExists(ExeDir + 'data' + PathDelim + 'Sprites' + PathDelim + RX_INFO[aRT].FileName + '.rxx') then
  begin
    fSprites[aRT].LoadFromRXXFile(ExeDir + 'data' + PathDelim + 'Sprites' + PathDelim + RX_INFO[aRT].FileName + '.rxx');
    Result := True;
  end
  else
    Exit;

  fSprites[aRT].OverloadRXDataFromFolder(ExeDir + 'Sprites' + PathDelim, nil); // Legacy support
  // 'Sprites' folder name confused some of the players, cause there is already data/Sprites folder
  fSprites[aRT].OverloadRXDataFromFolder(ExeDir + 'Modding graphics' + PathDelim, nil);

  gLog.AddTime('Load Sprites Done');

  // Generate terrain transitions
  if aRT = rxTiles then
  begin
    GenerateTerrainTransitions(fSprites[aRT]);
    GenerateTerrainTransitions(nil, True); //To get support for maps rev <= 10745
  end;
end;


function TKMResSprites.LoadRXASpritesAndGenTextures(aRT: TRXType): Boolean;
begin
  Result := LoadRXASprites(aRT);

  {$IFDEF LOAD_GAME_RES_ASYNC}
  if Result then
    fSprites[aRT].GenerateTexturesFromLoadedRXZ(True);
  {$ENDIF}
end;


function TKMResSprites.LoadRXASprites(aRT: TRXType): Boolean;
var
  rxaFile: string;
begin
  Result := False;

  rxaFile := GetSpritesRXAFilePath(aRT);

  if not FileExists(rxaFile) then Exit;

  fSprites[aRT].LoadFromRXAFile(rxaFile);

  Result := True;
end;


class function TKMResSprites.AllTilesOnOneAtlas: Boolean;
begin
  Result := AllTilesInOneTexture;
end;


{$IFDEF LOAD_GAME_RES_ASYNC}
procedure TKMResSprites.ManageAsyncResLoader(const aCallerName: String);
var
  nextRXTypeI: Integer;
begin
  if gGameSettings.AsyncGameResLoader
    and (fGameResLoader <> nil)
    and fGameResLoader.LoadStepDone then
  begin
    gLog.AddTime('[AsyncGameResLoader MainTh] [%s] GenTextures RT = %s Stage = %s',
                 [aCallerName,
                  GetEnumName(TypeInfo(TRXType), Integer(fGameResLoader.RXType)),
                  GetEnumName(TypeInfo(TKMAsyncLoadStage), Integer(fGameResLoader.LoadStage))]);

    case fGameResLoader.LoadStage of
      lsLoad:         ;
      lsGenMain:      begin
                        if Assigned(fStepCaption) then
                          fStepCaption(gResTexts[RX_INFO[fGameResLoader.RXType].LoadingTextID]);
                        // Generate texture atlas from prepared data for game resources
                        // OpenGL work mainly with 1 thread only, so we have to call gl functions only from main thread
                        // That is why we need call this method from main thread only

                        // Note: this could be from the loader thread by using `Synchronise` procedure
                        fSprites[fGameResLoader.RXType].GenerateTexturesFromLoadedRXZ(fGameResLoader.LastLoadedRXA);

                        fSprites[fGameResLoader.RXType].ClearTemp;      //Clear fRXData sprites temp data, which is not needed anymore
                        fSprites[fGameResLoader.RXType].ClearGameResGenTemp; //Clear all the temp data used for atlas texture generating
                      end;
      lsOverload:     ;
      lsGenOverload:  begin
                        if fGameResLoader.LastLoadedRXA then
                        begin
                          fSprites[fGameResLoader.RXType].GenerateTexturesFromLoadedRXZ(True);
                        end;

                        nextRXTypeI := GetNextLoadRxTypeIndex(fGameResLoader.RXType); // get next RXType to load
                        if (nextRXTypeI = -1) then
                        begin
                          //Load is completed, we can stop loading thread
                          StopAsyncResourceLoader;
                          fGameResLoadCompleted := True; // mark loading game res as completed
                        end
                        else
                          fGameResLoader.RXType := TRXType(StrToInt(fGameRXTypes[nextRXTypeI]));
                      end;
    end;

    if fGameResLoader <> nil then
    begin
      fGameResLoader.LoadStage := TKMAsyncLoadStage((Ord(fGameResLoader.LoadStage) + 1) mod 4);

      // Make this atomic, since LoadStepDone is accessed in different threads
      AtomicExchange(Integer(fGameResLoader.LoadStepDone), Integer(False));
    end;

    gLog.AddTime('[AsyncGameResLoader MainTh] [' + aCallerName + '] DONE');
  end;
end;
{$ENDIF}


procedure TKMResSprites.UpdateStateIdle;
begin
  {$IFDEF LOAD_GAME_RES_ASYNC}
  ManageAsyncResLoader('UpdateStateIdle');
  {$ENDIF}
end;


procedure TKMResSprites.ExportToPNG(aRT: TRXType);
begin
  if LoadSprites(aRT, False) then
  begin
    fSprites[aRT].ExportAllSpritesFromRXData(ExeDir + 'Export' + PathDelim + RX_INFO[aRT].FileName + '.rx' + PathDelim);
    ClearTemp;
  end;
end;


{$IFDEF LOAD_GAME_RES_ASYNC}
{ TTGameResourceLoader }
constructor TTGameResourceLoader.Create(aResSprites: TKMResSprites; aAlphaShadows: Boolean; aRxType: TRXType);
begin
  inherited Create(False);

  {$IFDEF DEBUG}
  TThread.NameThreadForDebugging('GameResourceLoader', ThreadID);
  {$ENDIF}

  fResSprites := aResSprites;
  fAlphaShadows := aAlphaShadows;
  RXType := aRxType;
  FreeOnTerminate := False; //object can be automatically removed after its termination
  LoadStage := lsLoad;

  Log('Started');
end;


destructor TTGameResourceLoader.Destroy;
begin
  Log('Stopped');

  inherited;
end;


procedure TTGameResourceLoader.Log(const aString: string);
begin
  gLog.AddTime('[AsyncGameResLoader Thread] ' + aString);
end;


procedure TTGameResourceLoader.Execute;
begin
  inherited;

  while not Terminated do
  begin
    if not LoadStepDone then
    begin
      if SLOW_ASYNC_RES_LOADER then
        Sleep(5000);

      Log(Format('RT = %s Stage = %s', [GetEnumName(TypeInfo(TRXType), Integer(RXType)),
                                        GetEnumName(TypeInfo(TKMAsyncLoadStage), Integer(LoadStage))]));

      case LoadStage of
        lsLoad:         begin
                          if fAlphaShadows and FileExists(fResSprites.GetSpritesRXAFilePath(RXType)) then
                          begin
                            Log('Start Load RXA ''' + RX_INFO[RXType].FileName + '.rxa''');
                            fResSprites.LoadRXASprites(RXType);
                            if Terminated then Exit;

                            AtomicExchange(Integer(LastLoadedRXA), Integer(True));
                            Log('DONE Load RXA ''' + RX_INFO[RXType].FileName + '.rxa''');
                          end
                          else
                          begin
                            Log('Start Load RXX ''' + RX_INFO[RXType].FileName + '.rxx''');
                            fResSprites.LoadSprites(RXType, fAlphaShadows);
                            if Terminated then Exit;

                            {$IFNDEF NO_OGL}
                            fResSprites.fSprites[RXType].MakeGFX(fAlphaShadows, 1, False, IsTerminated);
                            {$ENDIF}

                            AtomicExchange(Integer(LastLoadedRXA), Integer(False));
                            Log('DONE Load RXX ''' + RX_INFO[RXType].FileName + '.rxa''');
                          end;
                        end;
        lsGenMain:      ;
        lsOverload:     begin
                          Log('OverloadFromFolder RT = ' + GetEnumName(TypeInfo(TRXType), Integer(RXType)));
                          fResSprites[RXType].OverloadGeneratedFromFolder(fAlphaShadows, ExeDir + 'Sprites' + PathDelim, True, IsTerminated); // Legacy support
                          // 'Sprites' folder name confused some of the players, cause there is already data/Sprites folder
                          fResSprites[RXType].OverloadGeneratedFromFolder(fAlphaShadows, ExeDir + 'Modding graphics' + PathDelim, True, IsTerminated);
                          Log('DONE OverloadFromFolder RT = ' + GetEnumName(TypeInfo(TRXType), Integer(RXType)));
                        end;
        lsGenOverload:  ;
      end;

      LoadStage := TKMAsyncLoadStage((Ord(LoadStage) + 1) mod 4);

      // Make this atomic, since LoadStepDone is accessed in different threads
      AtomicExchange(Integer(LoadStepDone), Integer(True));
    end;
    Sleep(1); // sleep for a bit
  end;
end;


function TTGameResourceLoader.IsTerminated: Boolean;
begin
  Result := Terminated;
end;
{$ENDIF}


end.
