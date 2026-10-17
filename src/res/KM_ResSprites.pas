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
    rxxTwo,     // Same as previous, but with dynamic length text in header
    rxxThree    // Same as previous, plus per-sprite Scale (HD multiplier, Single) and per-atlas HD flag in RXA
  );

const
  RXX_HEADER_LENGTH = 4;
  RXX_HEADER: array [TKMRXXFormat] of AnsiString = ('', '', 'RXX1', 'RXX2', 'RXX3');

type
  {$IFDEF LOAD_GAME_RES_ASYNC}
  TTGameResourceLoader = class;
  {$ENDIF}

  TKMTexCoords = record
    TexID: Cardinal;
    u1,v1,u2,v2: Single; //Top-Left, Bottom-Right uv coords
  end;

  TKMGFXDataItem = record
    Tex, Alt: TKMTexCoords; //AltID used for team colors and house building steps
    PxWidth, PxHeight: Word; // Real texture pixels
    Scale: Single;           // HD multiplier, copy of TRXData.Scale for consumers without an RXData at hand. Logical size = Px / Scale
  end;
  TKMGFXDataArray = array of TKMGFXDataItem;

  // Atlas data, needed for Texture Atlas Generation
  TKMSpriteAtlasData = record
    Container: TKMBinItem;
    TexType: TKMTexFormat;
    Data: TKMCardinalArray;
    HD: Boolean; // Atlas holds only HD (Scale > 1) sprites -> linear filter + mips. Not stored in RXA (RXA atlases are SD)
  end;

  TKMSpriteAtlases = array [TKMSpriteAtlasType] of array {atlas number} of TKMSpriteAtlasData;

  // Base class for Sprite loading
  TKMSpritePack = class
  private
    fTemp: Boolean;
    fPad: Byte; // Padding between sprites to avoid neighbour edge visibility
    fTilePx: Integer;  // rxTiles only: biggest tile edge in the loaded data (32 = SD, more = HD)
    fMipLevels: Byte;  // rxTiles only: extra mip levels to generate for the atlases (0 = none)

    {$IFNDEF NO_OGL}
    function GetTexFilter(aHD: Boolean; out aMipLevels: Byte): TKMFilterType;
    procedure SetGFXData(aTexID: Cardinal; aSpriteInfo: TKMBinItem; aAtlasType: TKMSpriteAtlasType);
    procedure PrepareAtlases(aSpriteInfo: TBinArray; aMode: TKMSpriteAtlasType; aTexType: TKMTexFormat; var aBaseRAM, aColorRAM, aTexCount: Cardinal;
                             aPad: Byte; aHD: Boolean; aAtlasOffset: Integer;
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

    procedure AddImage(const aFolder, aFilename: string; aIndex: Integer; aEnlargeOnly: Boolean = False; aExplicitScale: Integer = 0);

    property RT: TRXType read fRT;
    property RXData: TRXData read fRXData;
    // No record copy (TRXData has ~10 managed arrays). Re-read it per use: the HD/SD compare swap replaces the pack
    function RXDataP: PRXData;
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

    // HD/SD live switch: the set that is currently NOT displayed, per RX.
    // Loaded lazily on the first switch, so it costs nothing unless used
    fAltSprites: array [TRXType] of TKMSpritePack;
    fAltGFXData: array [TRXType] of TKMGFXDataArray;
    fAltAllTilesOneAtlas: Boolean;   // AllTilesInOneTexture of the set that is not displayed
    // Per RX, never one flag for all of them: an HD pack may cover only some RX (e.g. houses only)
    fIsHDDisplayed: array [TRXType] of Boolean; // the set on screen
    fIsHDParked: array [TRXType] of Boolean;    // the one in fAltSprites
    fIsHDLoaded: array [TRXType] of Boolean;    // the one the loader put into fSprites

    function GetGenTerrainTransitions(aTerKind: TKMTerrainKind; aMaskKind: TKMTileMaskKind; aMaskType: TKMTileMaskType; aMaskSubtype: TKMTileMaskSubType): Word;

    function GetRXFileName(aRX: TRXType): string;
    function GetSprites(aRT: TRXType): TKMSpritePack;

    function GetSpritesFolder(aHD: Boolean): string;
    function GetSpritesRXAFilePath(aRT: TRXType; aHD: Boolean = False): string;
    function GetSpritesRXXFilePath(aRT: TRXType; aAlphaShadows, aHD: Boolean): string;
    procedure SetHDLoaded(aRT: TRXType; aHD: Boolean);

    function IsHDWanted(aRT: TRXType): Boolean;
    function HasPackFor(aRT: TRXType; aHD: Boolean): Boolean;
    function GetHDActive: Boolean;
    function GetHDAvailable: Boolean;
    function GetHDState(aRT: TRXType): Boolean;
    function FirstSpritePx(aRT: TRXType): Integer;
    procedure GenerateAltTransitions(aPack: TKMSpritePack);
    function LoadAltSet(aRT: TRXType; aHD: Boolean): Boolean;
    procedure SwapAltSets(aRXs: TRXTypeSet);
    procedure FreeAltSets(aRXs: TRXTypeSet);
    procedure ResetHDSwap;

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

    // Switch the displayed graphics (terrain, trees, houses, units) between the stock and the HD packs.
    // aOnProgress is called with the translated RX name before each (slow) load. Returns True if anything changed
    function SetHDGraphics(aHD: Boolean; aOnProgress: TUnicodeStringEvent): Boolean;
    procedure ReleaseHiddenSets;
    function RXAAvailable(aRT: TRXType): Boolean;

    property HDActive: Boolean read GetHDActive;         // any RX showing its HD pack
    property HDAvailable: Boolean read GetHDAvailable;   // any HD pack installed
    property HDState[aRT: TRXType]: Boolean read GetHDState;

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

var
  gGFXData: array [TRXType] of TKMGFXDataArray;

  // Overload file name 'X_nnnn.png' / 'X_nnnn@Nx.png' -> id and explicit HD scale (0 = none). Exposed for unit tests
  function ParseOverloadFileName(const aFileName: string; out aId, aScale: Integer): Boolean;
  // Replicate the outermost sprite pixels into the aPad wide ring around it (atlas edge padding). Exposed for unit tests
  procedure ExtendSpriteEdges(var aAtlas: TKMCardinalArray; aAtlasW, aX, aY, aW, aH, aPad: Integer);
  // Bilinear, border-clamped, per byte channel sample (transition masks on HD tiles). Exposed for unit tests
  function SampleBilinearClamped(const aPixels: array of Cardinal; aSrcW, aSrcH, aDstW, aDstH, aX, aY: Integer): Cardinal;


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
  // HD terrain tiles
  TILE_SD_PX = 32;             // Original tile size. Anything bigger is treated as HD
  MAX_TILES_ATLAS_SIZE = 8192; // Tiles-only ceiling: 1646 tiles at 128px + padding need 8192. Other RX keep MAX_GAME_ATLAS_SIZE
  TILES_HD_MIP_LEVELS = 2;     // Extra mip levels for HD tiles (D6: limited chain). Atlas padding = 2^levels
  // HD sprites: Scale > 1 sprites are packed into their own atlases with linear filtering
  // and a short mip chain, so that the untouched SD sprites keep their nearest-filtered look
  SPRITES_HD_MIP_LEVELS = 2;
  SPRITES_HD_PAD = 1 shl SPRITES_HD_MIP_LEVELS;
  SPRITE_TYPE_EXPORT_NAME: array [TKMSpriteAtlasType] of string = ('Base', 'Mask');
  LOG_EXTRA_GFX: Boolean = False;
  OVERLOAD_SKIP_MASK = 'skip';
  // HD graphics: opt-in packs in data/Sprites/hd, switchable at runtime. Everything else stays stock
  HD_SPRITES_FOLDER = 'hd';
  HD_SWAP_RX: TRXTypeSet = [rxTiles, rxTrees, rxHouses, rxUnits];
  HD_SET_NAME: array [Boolean] of string = ('stock', 'HD'); // One wording for all the HD swap log lines

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


// Tiles have their own ceiling, so that the bigger atlas is not paid for by every other RX (bins are always full-size)
function GetMaxTilesAtlasSize: Integer;
begin
  Result := MAX_TILES_ATLAS_SIZE;
  {$IFNDEF NO_OGL}
  if gRender <> nil then
    Result := Min(Result, TKMRender.MaxTextureSize);
  {$ENDIF}
end;


// Replicate the outermost sprite pixels into the aPad wide ring around it.
// Needed so that linear filtering and mip levels never sample the neighbouring sprite.
procedure ExtendSpriteEdges(var aAtlas: TKMCardinalArray; aAtlasW, aX, aY, aW, aH, aPad: Integer);
var
  P, I: Integer;
begin
  if (aW = 0) or (aH = 0) or (aPad = 0) then Exit;

  // Rows above and below
  for P := 1 to aPad do
    for I := 0 to aW - 1 do
    begin
      aAtlas[(aY - P) * aAtlasW + aX + I]          := aAtlas[aY * aAtlasW + aX + I];
      aAtlas[(aY + aH - 1 + P) * aAtlasW + aX + I] := aAtlas[(aY + aH - 1) * aAtlasW + aX + I];
    end;

  // Columns left and right, over the already extended row range (this fills the corners too)
  for P := 1 to aPad do
    for I := -aPad to aH - 1 + aPad do
    begin
      aAtlas[(aY + I) * aAtlasW + aX - P]          := aAtlas[(aY + I) * aAtlasW + aX];
      aAtlas[(aY + I) * aAtlasW + aX + aW - 1 + P] := aAtlas[(aY + I) * aAtlasW + aX + aW - 1];
    end;
end;


// Bilinear sample of an aSrcW x aSrcH image at the centre of pixel (aX, aY) of an aDstW x aDstH grid, per byte channel.
// Used to put the 32px transition masks on HD tiles: nearest sampling turned every dithered mask pixel into a hard block.
// Clamped, not wrapped: a mask edge has to stay its original edge, because the neighbouring tile's mask continues it
function SampleBilinearClamped(const aPixels: array of Cardinal; aSrcW, aSrcH, aDstW, aDstH, aX, aY: Integer): Cardinal;
const
  PIXEL_CENTER = 0.5;
  CHANNEL_COUNT = 4;
  CHANNEL_BITS = 8;
  CHANNEL_MASK = $FF;
var
  srcX, srcY, fracX, fracY, top, bottom: Single;
  x0, y0, x1, y1, C, shift: Integer;
  p00, p10, p01, p11: Cardinal;
begin
  // Only the low side needs a clamp: x1 / y1 below never step past the last pixel
  srcX := (aX + PIXEL_CENTER) * aSrcW / aDstW - PIXEL_CENTER;
  srcY := (aY + PIXEL_CENTER) * aSrcH / aDstH - PIXEL_CENTER;
  if srcX < 0 then srcX := 0;
  if srcY < 0 then srcY := 0;
  x0 := Trunc(srcX);
  y0 := Trunc(srcY);
  x1 := Min(x0 + 1, aSrcW - 1);
  y1 := Min(y0 + 1, aSrcH - 1);
  fracX := srcX - x0;
  fracY := srcY - y0;

  p00 := aPixels[y0 * aSrcW + x0];
  p10 := aPixels[y0 * aSrcW + x1];
  p01 := aPixels[y1 * aSrcW + x0];
  p11 := aPixels[y1 * aSrcW + x1];

  Result := 0;
  for C := 0 to CHANNEL_COUNT - 1 do
  begin
    shift := C * CHANNEL_BITS;
    top    := ((p00 shr shift) and CHANNEL_MASK) * (1 - fracX) + ((p10 shr shift) and CHANNEL_MASK) * fracX;
    bottom := ((p01 shr shift) and CHANNEL_MASK) * (1 - fracX) + ((p11 shr shift) and CHANNEL_MASK) * fracX;
    Result := Result or (Cardinal(Trunc(top + (bottom - top) * fracY + PIXEL_CENTER)) shl shift);
  end;
end;


// Parse an overload file name: 'X_nnnn.png' or 'X_nnnn@Nx.png'.
// aScale = N for the '@Nx' form, 0 when there is no explicit HD marker. Companion files (a/m.png, .txt) are not accepted here
function ParseOverloadFileName(const aFileName: string; out aId, aScale: Integer): Boolean;
var
  s: string;
  p: Integer;
begin
  aId := 0;
  aScale := 0;
  s := ChangeFileExt(ExtractFileName(aFileName), '');
  p := Pos('@', s);
  if p > 0 then
  begin
    // '...@4x' -> 4
    if ((s[Length(s)] <> 'x') and (s[Length(s)] <> 'X'))
    or not TryStrToInt(Copy(s, p + 1, Length(s) - p - 1), aScale)
    or (aScale < 1) then
      Exit(False);
    Delete(s, p, Length(s));
  end;
  // 'X_' prefix, then only digits
  Result := (Length(s) > 2) and TryStrToInt(Copy(s, 3, Length(s) - 2), aId);
end;


// TThread.CheckTerminated raises EThreadExternalException when called from a thread that was not created by TThread
// (the main thread included). The loaders run both in the async loader thread and, in the sync path, on the main thread
function LoaderThreadTerminated: Boolean;
begin
  Result := not TThread.CurrentThread.ExternalThread and TThread.CheckTerminated;
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
function TKMSpritePack.RXDataP: PRXData;
begin
  Result := @fRXData;
end;


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
      // HD replacements (Scale > 1) are used as they are: they come with real alpha, the legacy checkerboard-shadow
      // converter has nothing to detect on them, it would only zero the RGB of transparent pixels (breaking the
      // colour bleed needed for linear filtering) and cost a 5x5 blur pass per pixel on 16x the pixels
      if (fRXData.Flag[id] <> 0) and (fRXData.ScaleOf(id) <= 1) then
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
var
  I, oldLen: Integer;
begin
  fRXData.Count := aCount;

  aCount := fRXData.Count + 1;
  if not fTemp then
  begin
    oldLen := Length(gGFXData[fRT]);
    SetLength(gGFXData[fRT],      aCount);
    for I := oldLen to aCount - 1 do
      gGFXData[fRT, I].Scale := 1;
  end;
  SetLength(fRXData.Flag,         aCount);
  SetLength(fRXData.Size,         aCount);
  SetLength(fRXData.Pivot,        aCount);
  // Scale defaults to 1 (original resolution); SetLength zero-fills, so init the new tail explicitly
  oldLen := Length(fRXData.Scale);
  SetLength(fRXData.Scale,        aCount);
  for I := oldLen to aCount - 1 do
    fRXData.Scale[I] := 1;
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
procedure TKMSpritePack.AddImage(const aFolder, aFilename: string; aIndex: Integer; aEnlargeOnly: Boolean = False; aExplicitScale: Integer = 0);
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
  oldCount: Integer;
  oldScale, scale, sx, sy: Single;
begin
  Assert(SameText(ExtractFileExt(aFilename), '.png'));

  oldCount := fRXData.Count;
  if aIndex > fRXData.Count then
    Allocate(aIndex)
  else
  // RGBA / Mask / HasMask arrays are cleared after 1st usage, so we should reallocate memory for them
  if aEnlargeOnly then
    AllocateTemp(aIndex);

  LoadFromPng(aFolder + aFilename, pngWidth, pngHeight, pngData);
  Assert((pngWidth <= MAX_GAME_ATLAS_SIZE) and (pngHeight <= MAX_GAME_ATLAS_SIZE),
         Format('Image size should be less than %dx%d pixels', [MAX_GAME_ATLAS_SIZE, MAX_GAME_ATLAS_SIZE]));

  // HD scale derivation: a replacement PNG that is an integer multiple
  // (2x..) of the original sprite's *logical* size in both axes is an HD version of it, not a bigger object.
  // Compared against the logical size so that re-loading the same file from a second overload folder is stable.
  scale := 1;
  oldScale := fRXData.ScaleOf(aIndex);
  if aExplicitScale > 0 then
    // Stage 2: an explicit '@Nx' in the file name wins over derivation (the only option for brand-new sprites)
    scale := aExplicitScale
  else
  if (aIndex <= oldCount) and (fRXData.Size[aIndex].X > 0) and (fRXData.Size[aIndex].Y > 0) then
  begin
    sx := pngWidth  / (fRXData.Size[aIndex].X / oldScale);
    sy := pngHeight / (fRXData.Size[aIndex].Y / oldScale);
    if (Round(sx) >= 2) and (Round(sx) = Round(sy))
    and (Abs(sx - Round(sx)) <= 0.02) and (Abs(sy - Round(sy)) <= 0.02) then
      scale := Round(sx)
    else
    if (Abs(sx - 1) > 0.02) or (Abs(sy - 1) > 0.02) then
      gLog.AddTime(Format('Overload %s: %dx%d replaces logical %dx%d - not a uniform HD multiple, using scale 1 (object will change size)',
                          [aFilename, pngWidth, pngHeight,
                           Round(fRXData.Size[aIndex].X / oldScale), Round(fRXData.Size[aIndex].Y / oldScale)]));
  end;
  fRXData.Scale[aIndex] := scale;
  // Keep the pivot in real texels of the new image. A .txt next to the PNG overrides this below (in the PNG's own pixels)
  if scale <> oldScale then
  begin
    fRXData.Pivot[aIndex].X := Round(fRXData.Pivot[aIndex].X / oldScale * scale);
    fRXData.Pivot[aIndex].Y := Round(fRXData.Pivot[aIndex].Y / oldScale * scale);
  end;

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
  if (strFormat = RXX_HEADER[rxxTwo]) or (strFormat = RXX_HEADER[rxxThree]) then
  begin
    if strFormat = RXX_HEADER[rxxTwo] then
      aFormat := rxxTwo
    else
      aFormat := rxxThree;

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
          // HD scale (RXX3). Older formats have none: Allocate defaulted it to 1
          if rxxFormat = rxxThree then
            decompressionStream.Read(fRXData.Scale[I], SizeOf(fRXData.Scale[I]));
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
          // HD scale (RXA3). Older formats have none: Allocate defaulted it to 1
          if rxxFormat = rxxThree then
            decompressionStream.Read(fRXData.Scale[I], SizeOf(fRXData.Scale[I]));
          decompressionStream.Read(fRXData.HasMask[I], 1);

          // Check if our load resource thread was terminated
          if LoaderThreadTerminated then Exit;
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
            // HD atlas flag (RXA3): decides linear filtering + mips at texture generation. Older RXA are all SD (False)
            if rxxFormat = rxxThree then
              decompressionStream.Read(HD, SizeOf(HD));
            decompressionStream.Read(dataCount, 4);
            SetLength(Data, dataCount);
            decompressionStream.Read(Data[0], dataCount*SizeOf(Data[0]));

            // Check if our load resource thread was terminated
            if LoaderThreadTerminated then Exit;
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
      tmp, tmpScale: Integer;
    begin
      if ExtractRelativePath(aFolder, aPath).Contains(OVERLOAD_SKIP_MASK) then Exit(False);

      // Search filter we are using makes sure we get only X_*****.png filenames
      // Hence we need to check only for the ***** being digits (optionally followed by '@Nx')
      Result := ParseOverloadFileName(aSearchRec.Name, tmp, tmpScale);
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
    I, id, scale: Integer;
    fileList: TStringList;
  begin
    fileList := TStringList.Create;
    CollectSpriteFilesToOverloadInFolder(aFolder, fileList);
    try
      // Going in reverse allows us to allocate max required sprites early on (since filesnames usually come sorted by name)
      for I := fileList.Count - 1 downto 0 do
      begin
        if ParseOverloadFileName(fileList.Strings[I], id, scale) then
        begin
          AddImage(aFolder, fileList.Strings[I], id, True, scale);
          idList.Add(id);
        end;
      end;

      // Soften shadows for overloaded sprites
      if aSoftenShadows then
        SoftenShadowsList(idList);

      // Determine objects size only for units (used for hitbox)
      //todo -cComplicated: do we need it for houses too ?
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
    I, id, scale: Integer;
    fileList: TStringList;
    idList: TList<Integer>;
  begin
    idList := TList<Integer>.Create;
    fileList := TStringList.Create;
    CollectSpriteFilesToOverloadInFolder(aFolder, fileList);
    try
      // Going in reverse allows us to allocate max required sprites early on (since filesnames usually come sorted by name)
      for I := fileList.Count - 1 downto 0 do
      begin
        if ParseOverloadFileName(fileList.Strings[I], id, scale) then
        begin
          AddImage(aFolder, fileList.Strings[I], id, False, scale);
          idList.Add(id);
        end;

        // When packing RXX with HD anims the sheer count is so large we need a progress updates
        if (fileList.Count - I) mod 2500 = 0 then
          if Assigned(aOnProgress) then
            aOnProgress(Format('Appending from folder %d/%d', [fileList.Count - I, fileList.Count]));
      end;

      if LOG_EXTRA_GFX and (idList.Count > 0) then
        gLog.AddTime(Format('Overload %s: %d PNGs loaded from %s', [RX_INFO[fRT].FileName, idList.Count, aFolder]));

      // Soften shadows for overloaded sprites
      if aSoftenShadows then
      begin
        SoftenShadowsList(idList);
        if LOG_EXTRA_GFX and (idList.Count > 0) then
          gLog.AddTime(Format('Overload %s: shadows softened', [RX_INFO[fRT].FileName]));
      end;

      // Determine objects size only for units (used for hitbox)
      //todo -cComplicated: do we need it for houses too ?
      if fRT = rxUnits then
      begin
        DetermineImagesObjectSizeList(idList);
        if LOG_EXTRA_GFX and (idList.Count > 0) then
          gLog.AddTime(Format('Overload %s: object sizes determined', [RX_INFO[fRT].FileName]));
      end;
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
      //todo -cPractical: Would be much simpler if we had our own folder parser ..
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
  if not LoaderThreadTerminated then
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



// Texture filtering for this pack's atlases. HD tiles get linear filtering with a short mip chain,
// everything else keeps the original nearest look.
function TKMSpritePack.GetTexFilter(aHD: Boolean; out aMipLevels: Byte): TKMFilterType;
begin
  Result := ftNearest;
  aMipLevels := 0;

  if LINEAR_FILTER_SPRITES and (fRT in [rxTrees, rxHouses, rxUnits]) then
    Result := ftLinear;

  if fRT = rxTiles then
  begin
    if fMipLevels > 0 then
    begin
      Result := ftLinear;
      aMipLevels := fMipLevels;
    end;
  end
  else
  if aHD then
  begin
    // HD sprite atlas: drawn minified ~Scale times at 100% zoom, so it needs linear filtering and a mip chain
    Result := ftLinear;
    aMipLevels := SPRITES_HD_MIP_LEVELS;
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
      gGFXData[fRT, spriteID].Scale := fRXData.ScaleOf(spriteID);
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


// aPad: padding ring the sprites were bin-packed with (edge-extended here)
// aHD: atlases hold HD sprites only -> linear filtering + mips (see GetTexFilter)
// aAtlasOffset: index of the first of these atlases in fAtlases[aMode] (SD and HD groups are appended one after another)
procedure TKMSpritePack.PrepareAtlases(aSpriteInfo: TBinArray; aMode: TKMSpriteAtlasType; aTexType: TKMTexFormat; var aBaseRAM, aColorRAM, aTexCount: Cardinal;
                                       aPad: Byte; aHD: Boolean; aAtlasOffset: Integer;
                                       aFillGFXData: Boolean = True; aOnCheckTerminated: TBooleanFuncSimple = nil);
var
  I, K, L, M: Integer;
  CT, CL, Pixel: Cardinal;
  texID: Cardinal;
  ID: Integer;
  atlasData: TKMCardinalArray;
  texFilter: TKMFilterType;
  mipLevels: Byte;
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
      CT := aSpriteInfo[I].Sprites[K].OriginY;
      CL := aSpriteInfo[I].Sprites[K].OriginX;
      for L := 0 to fRXData.Size[ID].Y - 1 do
      for M := 0 to fRXData.Size[ID].X - 1 do
      begin
        Pixel := (CT + L) * aSpriteInfo[I].Width + CL + M;
        if aMode = saBase then
          atlasData[Pixel] := fRXData.RGBA[ID, L * fRXData.Size[ID].X + M]
        else
          atlasData[Pixel] := $FFFFFF or (fRXData.Mask[ID, L * fRXData.Size[ID].X + M] shl 24);

        //Sprite outline
        if OUTLINE_ALL_SPRITES and (
          (L = 0) or (M = 0)
          or (L = fRXData.Size[ID].Y - 1)
          or (M = fRXData.Size[ID].X - 1)) then
          atlasData[Pixel] := $FF0000FF;
      end;

      //Fill padding with edge pixels (aPad wide ring; HD needs more than 1px because of linear filtering + mipmaps)
      if aPad > 0 then
        ExtendSpriteEdges(atlasData, aSpriteInfo[I].Width, CL, CT, fRXData.Size[ID].X, fRXData.Size[ID].Y, aPad);
    end;

    if aFillGFXData then
    begin
      //Generate texture once
      texFilter := GetTexFilter(aHD, mipLevels);

      texID := TKMRender.GenTexture(aSpriteInfo[I].Width, aSpriteInfo[I].Height, @atlasData[0], aTexType, texFilter, texFilter, mipLevels);

      //Now that we know texture IDs we can fill GFXData structure
      SetGFXData(texID, aSpriteInfo[I], aMode);
    end else
    begin
      Assert(InRange(aAtlasOffset + I, Low(fAtlases[aMode]), High(fAtlases[aMode])),
             Format('Preloading sprite index out of range: %d, range [%d;%d]', [aAtlasOffset + I, Low(fAtlases[aMode]), High(fAtlases[aMode])]));
      // Save prepared data for generating later (in main thread)
      fAtlases[aMode, aAtlasOffset + I].Container := aSpriteInfo[I];
      fAtlases[aMode, aAtlasOffset + I].TexType := aTexType;
      fAtlases[aMode, aAtlasOffset + I].Data := atlasData;
      fAtlases[aMode, aAtlasOffset + I].HD := aHD;
    end;

    if aMode = saBase then
      Inc(aBaseRAM, aSpriteInfo[I].Width * aSpriteInfo[I].Height * TEX_FORMAT_SIZE[aTexType])
    else
      Inc(aColorRAM, aSpriteInfo[I].Width * aSpriteInfo[I].Height * TEX_FORMAT_SIZE[aTexType]);

    Inc(aTexCount);

    if aFillGFXData and DBG_EXPORT_SPRITE_ATLASES and (fRT in EXPORT_SPRITE_ATLASES_LIST) then
      SaveToPng(aSpriteInfo[I].Width, aSpriteInfo[I].Height, atlasData,
        ExeDir + 'Export\GenTextures\' + RX_INFO[fRT].FileName + '_' + SPRITE_TYPE_EXPORT_NAME[aMode] + IntToStr(aAtlasOffset + I) + '.png');
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
  atlasSize: Integer;

  // Split the sprites by resolution class: SD (Scale = 1) and HD (Scale > 1) go into separate atlases,
  // because filtering and padding are per-texture. Tiles are never split (their whole pack is one class)
  procedure SplitByScale(const aAll: TIndexSizeArray; out aSD, aHD: TIndexSizeArray);
  var
    I, nSD, nHD: Integer;
  begin
    SetLength(aSD, Length(aAll));
    SetLength(aHD, Length(aAll));
    nSD := 0;
    nHD := 0;
    for I := 0 to High(aAll) do
      if (fRT <> rxTiles) and (fRXData.ScaleOf(aAll[I].ID) > 1) then
      begin
        aHD[nHD] := aAll[I];
        Inc(nHD);
      end else
      begin
        aSD[nSD] := aAll[I];
        Inc(nSD);
      end;
    SetLength(aSD, nSD);
    SetLength(aHD, nHD);
  end;

  // Bin-pack one resolution class and append its atlases to fAtlases[aMode]
  procedure PackGroup(const aSizes: TIndexSizeArray; aMode: TKMSpriteAtlasType; aGroupTexType: TKMTexFormat; aPad: Byte; aHD: Boolean);
  var
    spriteInfo: TBinArray;
    offset: Integer;
  begin
    if Length(aSizes) = 0 then Exit;

    SetLength(spriteInfo, 0);
    BinPack(aSizes, atlasSize, aPad, spriteInfo);

    if CheckTerminated then Exit; //Our thread could be terminated and asked to stop. Exit immediately then

    offset := Length(fAtlases[aMode]);
    SetLength(fAtlases[aMode], offset + Length(spriteInfo));

    PrepareAtlases(spriteInfo, aMode, aGroupTexType, aBaseRAM, aColorRAM, aTexCount, aPad, aHD, offset, aFillGFXData, aOnCheckTerminated);
  end;

var
  I, J, K: Integer;
  spriteSizes, sdSizes, hdSizes: TIndexSizeArray;
  allTilesAtlasSize: Integer;
begin
  aBaseRAM := 0;
  aColorRAM := 0;
  SetLength(fAtlases[saBase], 0);
  SetLength(fAtlases[saMask], 0);
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
    // Tile size is derived from the loaded data, not hardcoded: after a PNG overload tiles may be mixed (32 px and HD)
    fTilePx := TILE_SD_PX;
    for J := 0 to K - 1 do
      fTilePx := Max(fTilePx, Max(spriteSizes[J].X, spriteSizes[J].Y));

    // Padding is decided first (from the mip chain), then the atlas size is computed from it
    if fTilePx > TILE_SD_PX then
    begin
      fMipLevels := TILES_HD_MIP_LEVELS;
      fPad := 1 shl TILES_HD_MIP_LEVELS;
    end else
    begin
      fMipLevels := 0;
      fPad := 1;
    end;

    allTilesAtlasSize := MakePOT(Ceil(sqrt(K))*(fTilePx + 2*fPad));
    atlasSize := Min(GetMaxTilesAtlasSize, allTilesAtlasSize); //Use smallest possible atlas size for tiles
    AllTilesInOneTexture := (atlasSize = allTilesAtlasSize);
    if not AllTilesInOneTexture then
      gLog.AddTime(Format('WARNING: %d tiles of %dpx do not fit into one atlas (need %d, max %d) - terrain falls back to per-tile texture binds',
                          [K, fTilePx, allTilesAtlasSize, GetMaxTilesAtlasSize]));
  end else
    atlasSize := GetMaxAtlasSize;

  SplitByScale(spriteSizes, sdSizes, hdSizes);

  PackGroup(sdSizes, saBase, aTexType, fPad, False);
  if CheckTerminated then Exit;
  PackGroup(hdSizes, saBase, aTexType, SPRITES_HD_PAD, True);
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

  SplitByScale(spriteSizes, sdSizes, hdSizes);
  PackGroup(sdSizes, saMask, tfAlpha8, fPad, False);
  if CheckTerminated then Exit;
  PackGroup(hdSizes, saMask, tfAlpha8, SPRITES_HD_PAD, True);
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
  mipLevels: Byte;
{$ENDIF}
begin
  {$IFNDEF NO_OGL}
  for SAT := Low(fAtlases) to High(fAtlases) do
    for I := Low(fAtlases[SAT]) to High(fAtlases[SAT]) do
    begin
      with fAtlases[SAT,I] do
      begin
        texFilter := GetTexFilter(HD, mipLevels);

        texID := TKMRender.GenTexture(Container.Width, Container.Height, @Data[0], TexType, texFilter, texFilter, mipLevels);
        //Now that we know texture IDs we can fill GFXData structure
        SetGFXData(texID, Container, SAT);

        if ((not aIsRXA and DBG_EXPORT_SPRITE_ATLASES) or (aIsRXA and DBG_EXPORT_SPRITE_ATLASES_RXA))
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
  begin
    fSprites[RT].Free;
    fAltSprites[RT].Free;
  end;

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
  tileW, tileH, maskW, maskH: Integer;
  sameRes: Boolean;
  straightPx{, RotatePixel}, maskSample, maskCol: Cardinal;
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
                // Mask and base tile may differ in resolution (HD base tile + original 32px mask):
                // sample the mask bilinear in the base tile's pixel grid
                tileW := aSprites.fRXData.Size[terrainId].X;
                tileH := aSprites.fRXData.Size[terrainId].Y;
                maskW := aSprites.fRXData.Size[maskId].X;
                maskH := aSprites.fRXData.Size[maskId].Y;
                sameRes := (tileW = maskW) and (tileH = maskH);

                for L := 0 to tileH - 1 do
                  for M := 0 to tileW - 1 do
                  begin
      //              Rotate(K, L, M, P, Q, aSprites.fRXData.Size[TerrainId].X - 1);
                    straightPx := L * tileW + M;
      //              RotatePixel := StraightPixel; //P * aSprites.fRXData.Size[TerrainId].X  + Q;
                    if sameRes then
                      maskSample := aSprites.fRXData.RGBA[maskId, straightPx]
                    else
                      maskSample := SampleBilinearClamped(aSprites.fRXData.RGBA[maskId], maskW, maskH, tileW, tileH, M, L);

                    case TILE_MASK_KIND_USAGE[MK] of
                      mkuPixel: maskCol := ($FFFFFF or (maskSample shl 24));
                      mkuAlpha: maskCol := maskSample;
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


// data/Sprites holds the stock (SD) packs, data/Sprites/hd the optional HD ones
function TKMResSprites.GetSpritesFolder(aHD: Boolean): string;
begin
  Result := ExeDir + 'data' + PathDelim + 'Sprites' + PathDelim;
  if aHD then
    Result := Result + HD_SPRITES_FOLDER + PathDelim;
end;


function TKMResSprites.GetSpritesRXAFilePath(aRT: TRXType; aHD: Boolean = False): string;
begin
  Result := GetSpritesFolder(aHD) + RX_INFO[aRT].FileName + '.rxa';
end;


// Alpha shadows have their own '_a.rxx'. Returns '' if neither file exists
function TKMResSprites.GetSpritesRXXFilePath(aRT: TRXType; aAlphaShadows, aHD: Boolean): string;
var
  folder: string;
begin
  folder := GetSpritesFolder(aHD);

  if aAlphaShadows and FileExists(folder + RX_INFO[aRT].FileName + '_a.rxx') then
    Result := folder + RX_INFO[aRT].FileName + '_a.rxx'
  else
  if FileExists(folder + RX_INFO[aRT].FileName + '.rxx') then
    Result := folder + RX_INFO[aRT].FileName + '.rxx'
  else
    Result := '';
end;


// Does the player want the HD pack for this RX? Says nothing about it being installed, see HasPackFor
function TKMResSprites.IsHDWanted(aRT: TRXType): Boolean;
begin
  Result := gGameSettings.HDGraphics and (aRT in HD_SWAP_RX);
end;


// Is there an RXA (prepacked atlases) for the set we are going to load?
function TKMResSprites.RXAAvailable(aRT: TRXType): Boolean;
begin
  Result := FileExists(GetSpritesRXAFilePath(aRT, False))
            or (IsHDWanted(aRT) and FileExists(GetSpritesRXAFilePath(aRT, True)));
end;


// Is there a pack of this kind for this RX? HD is opt-in and may cover only some of them
function TKMResSprites.HasPackFor(aRT: TRXType; aHD: Boolean): Boolean;
begin
  Result := (fAlphaShadows and (aRT <> rxTiles) and FileExists(GetSpritesRXAFilePath(aRT, aHD)))
            or (GetSpritesRXXFilePath(aRT, fAlphaShadows, aHD) <> '');
end;


// Remember which set the loader actually put into fSprites, so that the live swap knows what the other one is.
// Right after a load the displayed set IS the loaded one
procedure TKMResSprites.SetHDLoaded(aRT: TRXType; aHD: Boolean);
begin
  if not (aRT in HD_SWAP_RX) then Exit;

  fIsHDLoaded[aRT] := aHD;
  fIsHDDisplayed[aRT] := aHD;

  gLog.AddTime(Format('HD state: %s loaded as %s', [RX_INFO[aRT].FileName, HD_SET_NAME[aHD]]));
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

        if fAlphaShadows and RXAAvailable(RT) then
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
  // The loader writes into fSprites / gGFXData: put the loaded set back and drop the alternate ones (reloaded lazily)
  ResetHDSwap;
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
var
  isHD: Boolean;
  rxxFile: string;
begin
  gLog.AddTime('Load Sprites started');
  Result := False;

  // HD pack if the player asked for it and it exists, stock otherwise
  isHD := IsHDWanted(aRT) and (GetSpritesRXXFilePath(aRT, aAlphaShadows, True) <> '');
  rxxFile := GetSpritesRXXFilePath(aRT, aAlphaShadows, isHD);
  if rxxFile = '' then Exit;

  fSprites[aRT].LoadFromRXXFile(rxxFile);
  SetHDLoaded(aRT, isHD);
  Result := True;

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
  isHD: Boolean;
  rxaFile: string;
begin
  Result := False;

  isHD := IsHDWanted(aRT) and FileExists(GetSpritesRXAFilePath(aRT, True));
  rxaFile := GetSpritesRXAFilePath(aRT, isHD);

  if not FileExists(rxaFile) then Exit;

  fSprites[aRT].LoadFromRXAFile(rxaFile);
  SetHDLoaded(aRT, isHD);

  Result := True;
end;


class function TKMResSprites.AllTilesOnOneAtlas: Boolean;
begin
  Result := AllTilesInOneTexture;
end;


// Transition tiles are generated from the base tiles, so each tileset needs its own generation pass.
// The index tables it fills are expected to be the same for both sets, since the generated ids start after
// the base tiles and both tilesets hold the same number of them. Verify it: a shifted start id would
// silently point the map's terrain ids at the wrong transitions
procedure TKMResSprites.GenerateAltTransitions(aPack: TKMSpritePack);
var
  genTexIdStartWas: Integer;
begin
  genTexIdStartWas := fGenTexIdStartI;
  GenerateTerrainTransitions(aPack);

  if (genTexIdStartWas <> 0) and (genTexIdStartWas <> fGenTexIdStartI) then
    raise Exception.CreateFmt('HD swap: tileset sprite count differs (generated tiles start at %d, was %d)',
                              [fGenTexIdStartI, genTexIdStartWas]);
end;


// Load the "other" set of aRT (HD if SD is live, SD if HD is live) into fAltSprites / fAltGFXData.
// Modding graphics overloads are NOT applied here: both sides come straight from the packed files
function TKMResSprites.LoadAltSet(aRT: TRXType; aHD: Boolean): Boolean;
var
  altPack: TKMSpritePack;
  liveGFX: TKMGFXDataArray;
  rxaFile, rxxFile: string;
  isRXASource: Boolean;
  allTilesOneAtlasLive: Boolean;
begin
  Result := False;

  rxaFile := GetSpritesRXAFilePath(aRT, aHD);
  rxxFile := GetSpritesRXXFilePath(aRT, fAlphaShadows, aHD);
  // Tiles are always packed from RXX, the other RX prefer the ready-made atlases
  isRXASource := fAlphaShadows and (aRT <> rxTiles) and FileExists(rxaFile);

  if not isRXASource and (rxxFile = '') then
  begin
    gLog.AddTime(Format('HD swap: no %s source for %s', [HD_SET_NAME[aHD], RX_INFO[aRT].FileName]));
    Exit;
  end;

  if isRXASource then
    gLog.AddTime('HD swap: loading ' + rxaFile)
  else
    gLog.AddTime('HD swap: loading ' + rxxFile);

  // Packs write their texture coords into the global gGFXData[aRT], so park the live array while the
  // new pack fills a fresh one. Nothing may render while it is parked
  altPack := TKMSpritePack.Create(aRT);
  try
    liveGFX := gGFXData[aRT];
    gGFXData[aRT] := nil;
    allTilesOneAtlasLive := AllTilesInOneTexture;
    try
      if isRXASource then
        altPack.LoadFromRXAAndGenTextures(rxaFile)
      else
      begin
        altPack.LoadFromRXXFile(rxxFile);
        if aRT = rxTiles then
          GenerateAltTransitions(altPack);
        {$IFNDEF NO_OGL}
        altPack.MakeGFX(fAlphaShadows or (aRT = rxTiles));
        {$ENDIF}
      end;
      altPack.ClearTemp;
      altPack.ClearGameResGenTemp;

      fAltGFXData[aRT] := gGFXData[aRT];
      if aRT = rxTiles then
      begin
        // MakeGFX set the unit-wide flag for the pack it just packed. Keep both values, swap them along with the sets
        fAltAllTilesOneAtlas := AllTilesInOneTexture;
        AllTilesInOneTexture := allTilesOneAtlasLive;
      end;
    finally
      gGFXData[aRT] := liveGFX;
    end;
  except
    altPack.Free;
    fAltGFXData[aRT] := nil;
    raise;
  end;

  if altPack.IsEmpty then
  begin
    gLog.AddTime('HD swap: source for ' + RX_INFO[aRT].FileName + ' is empty');
    altPack.Free;
    fAltGFXData[aRT] := nil;
    Exit;
  end;

  fAltSprites[aRT] := altPack;
  fIsHDParked[aRT] := aHD;
  Result := True;
end;


// Texture width of the first valid sprite of aRT, as the renderer sees it right now (diagnostics)
function TKMResSprites.FirstSpritePx(aRT: TRXType): Integer;
var
  I: Integer;
begin
  for I := 1 to High(gGFXData[aRT]) do
    if gGFXData[aRT, I].PxWidth > 0 then
      Exit(gGFXData[aRT, I].PxWidth);

  Result := 0;
end;


// Exchange live and alternate sets (packs and their gGFXData arrays). O(1): dynamic arrays and objects swap by reference
procedure TKMResSprites.SwapAltSets(aRXs: TRXTypeSet);
var
  RT: TRXType;
  tmpPack: TKMSpritePack;
  tmpGFX: TKMGFXDataArray;
  tmpBool: Boolean;
begin
  for RT in aRXs do
  begin
    if fAltSprites[RT] = nil then Continue;

    tmpPack := fSprites[RT];
    fSprites[RT] := fAltSprites[RT];
    fAltSprites[RT] := tmpPack;

    tmpGFX := gGFXData[RT];
    gGFXData[RT] := fAltGFXData[RT];
    fAltGFXData[RT] := tmpGFX;

    if RT = rxTiles then
    begin
      tmpBool := AllTilesInOneTexture;
      AllTilesInOneTexture := fAltAllTilesOneAtlas;
      fAltAllTilesOneAtlas := tmpBool;
    end;

    // The two sets exchanged roles
    tmpBool := fIsHDDisplayed[RT];
    fIsHDDisplayed[RT] := fIsHDParked[RT];
    fIsHDParked[RT] := tmpBool;
  end;
end;


// Bring every RX to aHD, as far as the installed packs allow. Works per RX, because an HD set may cover
// only some of them, and because a game resource reload rebuilds the sprites but not the tiles.
// The first call loads the other set, which takes seconds - the caller shows a loading screen and gets
// a progress call before each RX. Returns True if anything actually changed
function TKMResSprites.SetHDGraphics(aHD: Boolean; aOnProgress: TUnicodeStringEvent): Boolean;
var
  RT: TRXType;
  toSwap: TRXTypeSet;
begin
  Result := False;
  toSwap := [];

  {$IFDEF LOAD_GAME_RES_ASYNC}
  // The loader thread fills fSprites / gGFXData, don't touch them until it is done
  if not fGameResLoadCompleted then Exit;
  {$ENDIF}

  for RT in HD_SWAP_RX do
  begin
    if fIsHDDisplayed[RT] = aHD then Continue; // Already showing the wanted set

    // An HD set may cover only some RX (e.g. houses only). Those without one stay as they are
    if not HasPackFor(RT, aHD) then
    begin
      gLog.AddTime(Format('HD swap: no %s pack for %s, it stays as it is',
                          [HD_SET_NAME[aHD], RX_INFO[RT].FileName]));
      Continue;
    end;

    // A parked set of the wrong kind is of no use (can happen after a partial switch)
    if (fAltSprites[RT] <> nil) and (fIsHDParked[RT] <> aHD) then
      FreeAltSets([RT]);

    if fAltSprites[RT] = nil then
    begin
      if Assigned(aOnProgress) then
        aOnProgress(gResTexts[RX_INFO[RT].LoadingTextID]);
      try
        if not LoadAltSet(RT, aHD) then Continue;
      except
        // Graphics switching must not take the game down: log and leave this RX alone
        on E: Exception do
        begin
          gLog.AddTime('HD swap: loading ' + RX_INFO[RT].FileName + ' failed: ' + E.Message);
          Continue;
        end;
      end;
    end;

    toSwap := toSwap + [RT];
  end;

  if toSwap = [] then Exit;

  SwapAltSets(toSwap);
  // The px sizes come from live sprites: that is what is on screen, independent of the flags
  gLog.AddTime(Format('HD swap: houses = %s (%d px), tiles = %s (%d px)',
                      [HD_SET_NAME[fIsHDDisplayed[rxHouses]], FirstSpritePx(rxHouses),
                       HD_SET_NAME[fIsHDDisplayed[rxTiles]], FirstSpritePx(rxTiles)]));
  Result := True;
end;


// Free the not displayed sets of aRXs, textures included
procedure TKMResSprites.FreeAltSets(aRXs: TRXTypeSet);
var
  RT: TRXType;
  I: Integer;
begin
  for RT in aRXs do
  begin
    if fAltSprites[RT] = nil then Continue;

    {$IFNDEF NO_OGL}
    if gRender <> nil then
      for I := 1 to High(fAltGFXData[RT]) do
      begin
        if fAltGFXData[RT, I].Tex.TexID <> 0 then
          TKMRender.DeleteTexture(fAltGFXData[RT, I].Tex.TexID);
        if fAltGFXData[RT, I].Alt.TexID <> 0 then
          TKMRender.DeleteTexture(fAltGFXData[RT, I].Alt.TexID);
      end;
    {$ENDIF}

    FreeAndNil(fAltSprites[RT]);
    fAltGFXData[RT] := nil;
    gLog.AddTime('HD swap: released the hidden ' + RX_INFO[RT].FileName + ' set');
  end;
end;


// Drop the alternate sets before game resources are (re)loaded: the loader writes into fSprites, which must be the live set.
// Tiles are a MENU resource (LoadMenuResources), the game resource loader never touches them - so their swap stays as it is
procedure TKMResSprites.ResetHDSwap;
var
  RT: TRXType;
  toSwap: TRXTypeSet;
begin
  // Put the sets the loader owns back on screen before we free the other ones
  toSwap := [];
  for RT in HD_SWAP_RX - [rxTiles] do
    if fIsHDDisplayed[RT] <> fIsHDLoaded[RT] then
      toSwap := toSwap + [RT];

  SwapAltSets(toSwap);
  FreeAltSets(HD_SWAP_RX - [rxTiles]);

  for RT in HD_SWAP_RX - [rxTiles] do
    fIsHDDisplayed[RT] := fIsHDLoaded[RT];
end;


// Leaving the map: keep what is on screen, free the other set (~1.6 GB of textures for a full HD set).
// Switching inside a game stays instant, the next one after a menu trip loads again
procedure TKMResSprites.ReleaseHiddenSets;
var
  RT: TRXType;
begin
  FreeAltSets(HD_SWAP_RX);

  // What is displayed is now the only set we have. The game RX get rebuilt from the setting, which the
  // switch keeps in sync with the display, and the tiles are not reloaded at all - so this stays true
  for RT in HD_SWAP_RX do
    fIsHDLoaded[RT] := fIsHDDisplayed[RT];
end;


// Is any part of the graphics the HD one? Drives the options checkbox and the in-game label
function TKMResSprites.GetHDActive: Boolean;
var
  RT: TRXType;
begin
  for RT in HD_SWAP_RX do
    if fIsHDDisplayed[RT] then Exit(True);

  Result := False;
end;


// Is an HD pack installed at all? Without one the switch has nothing to offer
function TKMResSprites.GetHDAvailable: Boolean;
var
  RT: TRXType;
begin
  for RT in HD_SWAP_RX do
    if HasPackFor(RT, True) then Exit(True);

  Result := False;
end;


function TKMResSprites.GetHDState(aRT: TRXType): Boolean;
begin
  Result := fIsHDDisplayed[aRT];
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
      if DBG_SLOW_ASYNC_RES_LOADER then
        Sleep(5000);

      Log(Format('RT = %s Stage = %s', [GetEnumName(TypeInfo(TRXType), Integer(RXType)),
                                        GetEnumName(TypeInfo(TKMAsyncLoadStage), Integer(LoadStage))]));

      case LoadStage of
        lsLoad:         begin
                          if fAlphaShadows and fResSprites.RXAAvailable(RXType) then
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
                          // Only the RXA path needs a separate overload pass: LoadSprites (RXX path) already applied the
                          // folders, and the main thread ignores lsGenOverload results for RXX anyway. Doing it again here
                          // decoded every PNG twice and kept the unused atlases in RAM (with HD packs this was ~30 s and
                          // hundreds of MB for Houses alone)
                          if LastLoadedRXA then
                          begin
                            Log('OverloadFromFolder RT = ' + GetEnumName(TypeInfo(TRXType), Integer(RXType)));
                            fResSprites[RXType].OverloadGeneratedFromFolder(fAlphaShadows, ExeDir + 'Sprites' + PathDelim, True, IsTerminated); // Legacy support
                            // 'Sprites' folder name confused some of the players, cause there is already data/Sprites folder
                            fResSprites[RXType].OverloadGeneratedFromFolder(fAlphaShadows, ExeDir + 'Modding graphics' + PathDelim, True, IsTerminated);
                            Log('DONE OverloadFromFolder RT = ' + GetEnumName(TypeInfo(TRXType), Integer(RXType)));
                          end
                          else
                            Log('OverloadFromFolder skipped for RT = ' + GetEnumName(TypeInfo(TRXType), Integer(RXType)) + ' (RXX path, already overloaded in LoadSprites)');
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
