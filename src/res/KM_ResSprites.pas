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
  TTGameResourceLoader = class;

  // Base class for Sprite loading
  TKMSpritePack = class
  private
    fTemp: Boolean;
    fPad: Byte; //Force padding between sprites to avoid neighbour edge visibility
    procedure SaveTextureToPNG(aWidth, aHeight: Word; const aFilename: string; var Data: TKMCardinalArray);
    procedure SetGFXData(aTx: Cardinal; aSpriteInfo: TBinItem; aAtlasType: TSpriteAtlasType);
  protected
    fRT: TRXType;
    fRXData: TRXData;

    fGFXPrepData: array [TSpriteAtlasType] of // for each atlas type
                    array of                  // Atlases
                      record                  // Atlas data, needed for Texture Atlas Generation
                        SpriteInfo: TBinItem;
                        TexType: TTexFormat;
                        Data: TKMCardinalArray;
                      end;
    procedure Allocate(aCount: Integer); virtual; //Allocate space for data that is being loaded
    {$IFNDEF NO_OGL}
    procedure MakeGFX_BinPacking(aTexType: TTexFormat; aStartingIndex: Integer; var BaseRAM, ColorRAM, TexCount: Cardinal;
                                 aFillGFXData: Boolean = True; aOnStopExecution: TBooleanFuncSimple = nil);
    {$ENDIF}
  public
    constructor Create(aRT: TRXType; aTemp: Boolean = False);

    procedure AddImage(const aFolder, aFilename: string; aIndex: Integer);
    property RXData: TRXData read fRXData;
    property Padding: Byte read fPad write fPad;

    procedure LoadFromRXXFile(const aFileName: string; aStartingIndex: Integer = 1);
    procedure OverloadFromFolder(const aFolder: string; aSoftenShadows: Boolean = True);
    {$IFNDEF NO_OGL}
    procedure MakeGFX(aAlphaShadows: Boolean; aStartingIndex: Integer = 1; aFillGFXData: Boolean = True; aOnStopExecution: TBooleanFuncSimple = nil);
    {$ENDIF}
    procedure DeleteSpriteTexture(aIndex: Integer);

    //Load from atlas format, no MakeGFX bin packing needed
    procedure LoadFromRXAAndGenTextures(const aFileName: string);
    procedure LoadFromRXAFile(const aFileName: string);
    procedure GenerateTexturesFromLoadedRXA;

    function GetSoftenShadowType(aID: Integer): TKMSoftenShadowType;
    procedure SoftenShadows(aIdList: TList<Integer>); overload;
    procedure SoftenShadows(aStart: Integer = 1; aEnd: Integer = -1; aOnlyShadows: Boolean = True); overload;
    procedure SoftenShadows(aID: Integer; aOnlyShadows: Boolean = True); overload;
    procedure DetermineImagesObjectSize(aStart: Integer = 1; aEnd: Integer = -1); overload;
    procedure DetermineImagesObjectSize(aIdList: TList<Integer>); overload;
    procedure RemoveMarketWaresShadows(aResHouses: TKMResHouses);
    procedure RemoveSnowHouseShadows(aResHouses: TKMResHouses);
    procedure RemoveHouseWorkBackgrounds(aResHouses: TKMResHouses);

    function GetSpriteColors(aCount: Integer): TKMColor3bArray;

    function IsEmpty: Boolean;

    procedure ExportAll(const aFolder: string);
    procedure ExportFullImageData(const aFolder: string; aIndex: Integer; aTempList: TStringList = nil);
    procedure ExportImage(const aFile: string; aIndex: Integer);
    procedure ExportMask(const aFile: string; aIndex: Integer);

    procedure ClearGameResGenTemp;
    {$IFDEF LOAD_GAME_RES_ASYNC}
    procedure GenerateTextureAtlasForGameRes;
    {$ENDIF}

    procedure ClearTemp; virtual;//Release non-required data
  end;


  TKMResSprites = class
  private
    fAlphaShadows: Boolean; //Remember which state we loaded
    fSprites: array [TRXType] of TKMSpritePack;
    fStepProgress: TEvent;
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

    {$IFDEF LOAD_GAME_RES_ASYNC}
    procedure ManageAsyncResLoader(const aCallerName: String);
    procedure StopAsyncResourceLoader;
    function GetNextLoadRxTypeIndex(aRT: TRXType): Integer;
    {$ENDIF}
  public
    constructor Create(aStepProgress: TEvent = nil; aStepCaption: TUnicodeStringEvent = nil; aTemp: Boolean = False);
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
    procedure ExportToPNG(aRT: TRXType);

    property AlphaShadows: Boolean read fAlphaShadows;
    property FileName[aRX: TRXType]: string read GetRXFileName;

    procedure UpdateStateIdle;
  end;

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
    constructor Create(aResSprites: TKMResSprites; aAlphaShadows: Boolean; aRxType: TRXType);
    destructor Destroy; override;

    procedure Execute; override;
  end;

  TKMTexCoords = record
    ID: Cardinal;
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
  KM_Log, KM_CommonUtils, KM_Points, KM_GameSettings;

const
  MAX_GAME_ATLAS_SIZE = 2048; //Max atlas size for KaM. No need for bigger atlases
  SPRITE_TYPE_EXPORT_NAME: array [TSpriteAtlasType] of string = ('Base', 'Mask');
  LOG_EXTRA_GFX: Boolean = False;

var
  AllTilesInOneTexture: Boolean = False;


function GetMaxAtlasSize: Integer;
begin
  Result := MAX_GAME_ATLAS_SIZE;
  {$IFNDEF NO_OGL}
  if gRender <> nil then
    Result := Min(Result, TRender.MaxTextureSize);
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
  if gGFXData[fRT, aIndex].Tex.ID <> 0 then
    TRender.DeleteTexture(gGFXData[fRT, aIndex].Tex.ID);
  if gGFXData[fRT, aIndex].Alt.ID <> 0 then
    TRender.DeleteTexture(gGFXData[fRT, aIndex].Alt.ID);

  gGFXData[fRT, aIndex].Tex.ID := 0;
  gGFXData[fRT, aIndex].Alt.ID := 0;
  {$ENDIF}
end;


function TKMSpritePack.GetSoftenShadowType(aID: Integer): TKMSoftenShadowType;
var
  step, spriteID: Integer;
  UT: TKMUnitType;
  dir: TKMDirection;
begin
  Result := sstNone;

  case fRT of
    rxHouses: if InRange(aID, 889, 892)            //Smooth smoke
                or InRange(aID, 1615, 1638) then   //Smooth flame
                Result := sstBoth
              else
                Result := sstOnlyShadow;
    rxUnits:  begin
                if InRange(aID, 6251, 6322) then     //Smooth thought bubbles
                begin
                  Result := sstBoth;
                  Exit;
                end;
                //Smooth all death animations for all units
                for UT := HUMANS_MIN to HUMANS_MAX do
                  for dir := dirN to dirNW do
                    for step := 1 to 30 do
                    begin
                      spriteID := gRes.Units[UT].UnitAnim[uaDie,dir].Step[step]+1; //Sprites in units.dat are 0 indexed
                      if (aID = spriteID) and (spriteID > 0) then
                      begin
                        Result := sstBoth;
                        Exit;
                      end;
                    end;
                if Result = sstNone then
                  Result := sstOnlyShadow;
              end;
    rxTrees:  Result := sstOnlyShadow;
    rxGui:    if InRange(aID, 105, 128)         //Field plans
                or InRange(aID, 249, 281)       //House tablets only (shadow softening messes up other rxGui sprites)
                or InRange(aID, 461, 468)       //Field fences
                or InRange(aID, 660, 660) then  //Woodcutter cutting point sign
                Result := sstOnlyShadow;
  end;
end;


procedure TKMSpritePack.SoftenShadows(aIdList: TList<Integer>);
var
  I, id: Integer;
  shadowConverter: TKMSoftShadowConverter;
  softenShadowType: TKMSoftenShadowType;
begin
  if aIdList.Count = 0 then Exit;

  shadowConverter := TKMSoftShadowConverter.Create(Self);
  try
    for I := 0 to aIdList.Count - 1 do
    begin
      id := aIdList[I];
      if fRXData.Flag[id] <> 0 then
      begin
        softenShadowType := GetSoftenShadowType(id);
        case softenShadowType of
          sstNone: ;
          sstOnlyShadow:  shadowConverter.ConvertShadows(id, True);
          sstBoth:        begin
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


//Make old style KaM checkerboard shadows smooth and transparent
procedure TKMSpritePack.SoftenShadows(aStart: Integer = 1; aEnd: Integer = -1; aOnlyShadows: Boolean = True);
var
  I: Integer;
  shadowConverter: TKMSoftShadowConverter;
begin
  shadowConverter := TKMSoftShadowConverter.Create(Self);
  try
    if aEnd = -1 then aEnd := fRXData.Count;
    for I := aStart to aEnd do
      if (fRXData.Flag[I] <> 0) then
        shadowConverter.ConvertShadows(I, aOnlyShadows);
  finally
    shadowConverter.Free;
  end;
end;


procedure TKMSpritePack.DetermineImagesObjectSize(aStart: Integer = 1; aEnd: Integer = -1);
var
  I: Integer;
  shadowConverter: TKMSoftShadowConverter;
begin
  shadowConverter := TKMSoftShadowConverter.Create(Self);
  try
    if aEnd = -1 then aEnd := fRXData.Count;
    for I := aStart to aEnd do
      if (fRXData.Flag[I] <> 0) then
        shadowConverter.DetermineImageObjectSize(I);
  finally
    shadowConverter.Free;
  end;
end;


procedure TKMSpritePack.DetermineImagesObjectSize(aIdList: TList<Integer>);
var
  I, id: Integer;
  shadowConverter: TKMSoftShadowConverter;
begin
  if aIdList.Count = 0 then Exit;

  shadowConverter := TKMSoftShadowConverter.Create(Self);
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

  shadowConverter := TKMSoftShadowConverter.Create(Self);
  try
    for HT := HOUSE_MIN to HOUSE_MAX do
    begin
      snowID := aResHouses[HT].SnowPic + 1;
      if (fRXData.Flag[snowID] <> 0) then
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

  shadowConverter := TKMSoftShadowConverter.Create(Self);
  try
    for I := MARKET_WARES_TEX_START + 1 to MARKET_WARES_TEX_START + MARKET_WARES_TEX_CNT - 1 do
    if (fRXData.Flag[I] <> 0) then
      shadowConverter.RemoveShadow(I, False);
  finally
    shadowConverter.Free;
  end;
end;


procedure TKMSpritePack.SoftenShadows(aID: Integer; aOnlyShadows: Boolean = True);
var
  shadowConverter: TKMSoftShadowConverter;
begin
  shadowConverter := TKMSoftShadowConverter.Create(Self);
  try
    if (fRXData.Flag[aID] <> 0) then
      shadowConverter.ConvertShadows(aID, aOnlyShadows);
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
  SetLength(fRXData.RGBA,         aCount);
  SetLength(fRXData.Mask,         aCount);
  SetLength(fRXData.HasMask,      aCount);
end;


//Release RAM that is no longer needed
procedure TKMSpritePack.ClearTemp;
begin
  SetLength(fRXData.RGBA, 0);
  SetLength(fRXData.Mask, 0);
  SetLength(fRXData.HasMask, 0);
end;


//Add PNG images to spritepack if user has any addons in Sprites folder
procedure TKMSpritePack.AddImage(const aFolder, aFilename: string; aIndex: Integer);
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
    Allocate(aIndex);

  LoadFromPng(aFolder + aFilename, pngWidth, pngHeight, pngData);
  Assert((pngWidth <= 2048) and (pngHeight <= 2048), 'Image size should be less than 2048x2048 pixels');

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
        smtPlain:  begin
                    //For now process just red (assume pic is greyscale)
                    fRXData.Mask[aIndex, K*pngWidth+I] := pngData[K*pngWidth+I] and $FF;
                  end;
        smtSmart:  begin
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
      ReadLn(ft, fRXData.SizeNoShadow[aIndex].left);
      ReadLn(ft, fRXData.SizeNoShadow[aIndex].top);
      ReadLn(ft, fRXData.SizeNoShadow[aIndex].right);
      ReadLn(ft, fRXData.SizeNoShadow[aIndex].bottom);
    end;
    CloseFile(ft);
  end;
end;


procedure TKMSpritePack.LoadFromRXXFile(const aFileName: string; aStartingIndex: Integer = 1);
var
  I: Integer;
  rxxCount: Integer;
  inputStream: TFileStream;
  decompressionStream: TDecompressionStream;
begin
  case fRT of
    rxTiles: if SKIP_RENDER and not DO_NOT_SKIP_LOAD_TILESET then Exit;
    else     if SKIP_RENDER then Exit;
  end;

  if not FileExists(aFileName) then Exit;

  inputStream := TFileStream.Create(aFileName, fmOpenRead or fmShareDenyNone);
  decompressionStream := TDecompressionStream.Create(inputStream);

  try
    decompressionStream.Read(rxxCount, 4);
    if gLog <> nil then
      gLog.AddTime(RXInfo[fRT].FileName + ' -', rxxCount);

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
          decompressionStream.Read(fRXData.SizeNoShadow[I].left, SizeOf(fRXData.SizeNoShadow[I]));
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
    inputStream.Free;
  end;
end;


procedure TKMSpritePack.LoadFromRXAFile(const aFileName: string);
var
  I: Integer;
  SAT: TSpriteAtlasType;
  rxxCount, atlasCount, spriteCount, dataCount: Integer;
  inputStream: TFileStream;
  decompressionStream: TDecompressionStream;
begin
  {$IFNDEF NO_OGL}
  case fRT of
    rxTiles: if SKIP_RENDER and not DO_NOT_SKIP_LOAD_TILESET then Exit;
    else     if SKIP_RENDER then Exit;
  end;

  if not FileExists(aFileName) then Exit;

  inputStream := TFileStream.Create(aFileName, fmOpenRead or fmShareDenyNone);
  decompressionStream := TDecompressionStream.Create(inputStream);

  try
    decompressionStream.Read(rxxCount, 4);
    if gLog <> nil then
      gLog.AddTime(RXInfo[fRT].FileName + ' -', rxxCount);

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
          decompressionStream.Read(fRXData.SizeNoShadow[I].left, SizeOf(fRXData.SizeNoShadow[I]));
        decompressionStream.Read(fRXData.HasMask[I], 1);
      end;

    //Atlases
    for SAT := Low(TSpriteAtlasType) to High(TSpriteAtlasType) do
    begin
      decompressionStream.Read(atlasCount, 4);
      SetLength(fGFXPrepData[SAT], atlasCount);
      for I := Low(fGFXPrepData[SAT]) to High(fGFXPrepData[SAT]) do
        with fGFXPrepData[SAT, I] do
        begin
          decompressionStream.Read(SpriteInfo.Width, 2);
          decompressionStream.Read(SpriteInfo.Height, 2);
          decompressionStream.Read(spriteCount, 4);
          SetLength(SpriteInfo.Sprites, spriteCount);
          decompressionStream.Read(SpriteInfo.Sprites[0], spriteCount*SizeOf(SpriteInfo.Sprites[0]));
          decompressionStream.Read(TexType, SizeOf(TTexFormat));
          decompressionStream.Read(dataCount, 4);
          SetLength(Data, dataCount);
          decompressionStream.Read(Data[0], dataCount*SizeOf(Data[0]));
        end;
    end;
  finally
    decompressionStream.Free;
    inputStream.Free;
  end;
  {$ENDIF}
end;


// Generate texture atlases from previosly prepared SpriteInfo data (loaded from RXA, copied to atlas)
// Preparation was done asynchroniously by TTGameResourceLoader thread
// Texture generating task can be done only by main thread, as OpenGL does not work with multiple threads
// Note: this could be from the loader thread by using `Synchronise` procedure
procedure TKMSpritePack.GenerateTexturesFromLoadedRXA;
var
  I: Integer;
  SAT: TSpriteAtlasType;
  texFilter: TFilterType;
  Tx: Cardinal;
begin
  {$IFNDEF NO_OGL}
  for SAT := Low(TSpriteAtlasType) to High(TSpriteAtlasType) do
    for I := Low(fGFXPrepData[SAT]) to High(fGFXPrepData[SAT]) do
      with fGFXPrepData[SAT, I] do
      begin
        //Generate texture once
        texFilter := ftNearest;
        if LINEAR_FILTER_SPRITES and (fRT in [rxTrees, rxHouses, rxUnits]) then
          texFilter := ftLinear;

        Tx := TRender.GenTexture(SpriteInfo.Width, SpriteInfo.Height, @Data[0], TexType, texFilter, texFilter);

        //Now that we know texture IDs we can fill GFXData structure
        SetGFXData(Tx, SpriteInfo, SAT);

        if EXPORT_SPRITE_ATLASES_RXA then
          SaveTextureToPNG(SpriteInfo.Width, SpriteInfo.Height, RXInfo[fRT].FileName + '_rxa_' +
                           SPRITE_TYPE_EXPORT_NAME[SAT] + IntToStr(I), Data);
      end;
  {$ENDIF}
end;


procedure TKMSpritePack.LoadFromRXAAndGenTextures(const aFileName: string);
begin
  LoadFromRXAFile(aFileName);
  GenerateTexturesFromLoadedRXA;
end;


// Parse all valid files in Sprites folder:
// - append or replace original sprites with new ones
// - exclude original sprites if necessary as well
procedure TKMSpritePack.OverloadFromFolder(const aFolder: string; aSoftenShadows: Boolean = True);
const
  SKIP_MASK = 'skip';
  {$IFDEF WDC}
  // Append all PNGs including the subfolders
  // Pattern is X_nnnn.png, where nnnn is dynamic (1..n chars) for modders convenience
  procedure AppendFolder;
  var
    I, id: Integer;
    fileList: TStringList;
    idList: TList<Integer>;
    filePath, s: string;
    filterPredicate: TDirectory.TFilterPredicate;
  begin
    fileList := TStringList.Create;
    idList := TList<Integer>.Create;
    try
      filterPredicate :=
        function(const aPath: string; const aSearchRec: TSearchRec): Boolean
        var
          tmp: Integer;
        begin
          if ExtractRelativePath(aFolder, aPath).Contains(SKIP_MASK) then Exit(False);

          // Search filter we are using makes sure we get only X_*****.png filenames
          // Hence we need to check only for the ***** being digits
          Result := TryStrToInt(Copy(aSearchRec.Name, 3, Length(aSearchRec.Name)-6), tmp);
        end;

      for filePath in TDirectory.GetFiles(aFolder, IntToStr(Ord(fRT) + 1) + '_*.png', TSearchOption.soAllDirectories, filterPredicate) do
        fileList.Add(ExtractRelativePath(aFolder, filePath));

      // Append/replace the sprites
      // Going in reverse allows us to allocate max required sprites early on (since filesnames usually come sorted by name)
      for I := fileList.Count - 1 downto 0 do
      begin
        s := ExtractFileName(fileList.Strings[I]);
        if TryStrToInt(Copy(s, 3, Length(s)-6), id) then
        begin
          AddImage(aFolder, fileList.Strings[I], id);
          idList.Add(id);
        end;
      end;

      // Soften shadows for overloaded sprites
      if aSoftenShadows then
        SoftenShadows(idList);

      // Determine objects size only for units (used for hitbox)
      //todo: do we need it for houses too ?
      if fRT = rxUnits then
        DetermineImagesObjectSize(idList);
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
        if ExtractRelativePath(aFolder, aPath).Contains(SKIP_MASK) then Exit(False);

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
procedure TKMSpritePack.ExportAll(const aFolder: string);
var
  I: Integer;
  SL: TStringList;
begin
  ForceDirectories(aFolder);

  SL := TStringList.Create;

  for I := 1 to fRXData.Count do
  begin
    ExportFullImageData(aFolder, I, SL);
    // Stop export if async thread is terminated by application
    if TThread.CheckTerminated then
      Exit;
  end;

  SL.Free;
end;


procedure TKMSpritePack.ExportFullImageData(const aFolder: string; aIndex: Integer; aTempList: TStringList = nil);
var
  listCreated: Boolean;
begin
  listCreated := False;
  if aTempList = nil then
  begin
    aTempList := TStringList.Create;
    listCreated := True;
  end;

  if fRXData.Flag[aIndex] = 1 then
  begin
    ExportImage(aFolder + Format('%d_%.4d.png', [Byte(fRT)+1, aIndex]), aIndex);

    if fRXData.HasMask[aIndex] then
      ExportMask(aFolder + Format('%d_%.4da.png', [Byte(fRT)+1, aIndex]), aIndex);

    //Export pivot
    aTempList.Clear;
    aTempList.Append(IntToStr(fRXData.Pivot[aIndex].x));
    aTempList.Append(IntToStr(fRXData.Pivot[aIndex].y));
    //SizeNoShadow is used only for Units
    if fRT = rxUnits then
    begin
      aTempList.Append(IntToStr(fRXData.SizeNoShadow[aIndex].left));
      aTempList.Append(IntToStr(fRXData.SizeNoShadow[aIndex].top));
      aTempList.Append(IntToStr(fRXData.SizeNoShadow[aIndex].right));
      aTempList.Append(IntToStr(fRXData.SizeNoShadow[aIndex].bottom));
    end;
    aTempList.SaveToFile(aFolder + Format('%d_%.4d.txt', [Byte(fRT)+1, aIndex]));
  end;

  if listCreated then
    aTempList.Free;
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


function TKMSpritePack.GetSpriteColors(aCount: Integer): TKMColor3bArray;
var
  I, L, M: Integer;
  pixelCount: Word;
  R,G,B: Integer;
begin
  SetLength(Result, Min(fRXData.Count, aCount));

  for I := 1 to Min(fRXData.Count, aCount) do
  begin
    R := 0;
    G := 0;
    B := 0;
    for L := 0 to fRXData.Size[I].Y - 1 do
    for M := 0 to fRXData.Size[I].X - 1 do
    begin
      Inc(R, fRXData.RGBA[I, L * fRXData.Size[I].X + M] and $FF);
      Inc(G, fRXData.RGBA[I, L * fRXData.Size[I].X + M] shr 8 and $FF);
      Inc(B, fRXData.RGBA[I, L * fRXData.Size[I].X + M] shr 16 and $FF);
    end;
    pixelCount := Max(1, fRXData.Size[I].X * fRXData.Size[I].Y);
    Result[I-1].R := Round(R / pixelCount);
    Result[I-1].G := Round(G / pixelCount);
    Result[I-1].B := Round(B / pixelCount);
  end;
end;


function TKMSpritePack.IsEmpty: Boolean;
begin
  Result := fRXData.Count = 0;
end;


//Take RX data and make nice atlas texture out of it
//Atlases should be POT to improve performance and avoid driver bugs
//In result we have GFXData structure filled
{$IFNDEF NO_OGL}
procedure TKMSpritePack.MakeGFX(aAlphaShadows: Boolean; aStartingIndex: Integer = 1; aFillGFXData: Boolean = True; aOnStopExecution: TBooleanFuncSimple = nil);
var
  I: Integer;
  texType: TTexFormat;
  baseRAM, idealRAM, colorRAM, texCount: Cardinal;
begin
  if SKIP_RENDER then Exit;
  if fRXData.Count = 0 then Exit;

  if aAlphaShadows and (fRT in [rxTrees,rxHouses,rxUnits,rxGui,rxTiles]) or not aAlphaShadows and (fRT = rxGuiMain) then
    texType := tfRGBA8
  else
    texType := tfRGB5A1;

  MakeGFX_BinPacking(texType, aStartingIndex, baseRAM, colorRAM, texCount, aFillGFXData, aOnStopExecution);

  if LOG_EXTRA_GFX then
  begin
    idealRAM := 0;
    for I := aStartingIndex to fRXData.Count do
    if fRXData.Flag[I] <> 0 then
      Inc(idealRAM, fRXData.Size[I].X * fRXData.Size[I].Y * TEX_FORMAT_SIZE[texType]);

    gLog.AddTime(IntToStr(texCount) + ' Textures created');
    gLog.AddNoTime(Format('%d/%d', [baseRAM div 1024, idealRAM div 1024]) +
                  ' Kbytes allocated/ideal for ' + RXInfo[fRT].FileName + ' GFX when using Packing');
    gLog.AddNoTime(IntToStr(colorRAM div 1024) + ' KBytes for team colors');
  end;
end;
{$ENDIF}


//Set GFXData from SpriteInfo
procedure TKMSpritePack.SetGFXData(aTx: Cardinal; aSpriteInfo: TBinItem; aAtlasType: TSpriteAtlasType);
var
  K: Integer;
  ID: Integer;
  txCoords: TKMTexCoords;
begin
  for K := 0 to High(aSpriteInfo.Sprites) do
  begin
    ID := aSpriteInfo.Sprites[K].SpriteID;

    txCoords.ID := aTx;
    txCoords.u1 := aSpriteInfo.Sprites[K].PosX / aSpriteInfo.Width;
    txCoords.v1 := aSpriteInfo.Sprites[K].PosY / aSpriteInfo.Height;
    txCoords.u2 := (aSpriteInfo.Sprites[K].PosX + fRXData.Size[ID].X) / aSpriteInfo.Width;
    txCoords.v2 := (aSpriteInfo.Sprites[K].PosY + fRXData.Size[ID].Y) / aSpriteInfo.Height;

    if aAtlasType = saBase then
    begin
      gGFXData[fRT, ID].Tex := txCoords;
      gGFXData[fRT, ID].PxWidth := fRXData.Size[ID].X;
      gGFXData[fRT, ID].PxHeight := fRXData.Size[ID].Y;
    end
    else
      gGFXData[fRT, ID].Alt := txCoords;
  end;
end;


{$IFNDEF NO_OGL}
//This algorithm is planned to take advantage of more efficient 2D bin packing
procedure TKMSpritePack.MakeGFX_BinPacking(aTexType: TTexFormat; aStartingIndex: Integer; var BaseRAM, ColorRAM, TexCount: Cardinal;
                                           aFillGFXData: Boolean = True; aOnStopExecution: TBooleanFuncSimple = nil);

  procedure PrepareAtlases(SpriteInfo: TBinArray; aMode: TSpriteAtlasType; aTexType: TTexFormat);
  var
    I, K, L, M: Integer;
    CT, CL, Pixel: Cardinal;
    Tx: Cardinal;
    ID: Integer;
    TD: TKMCardinalArray;
    texFilter: TFilterType;
  begin
    //Prepare atlases
    for I := 0 to High(SpriteInfo) do
    begin
      Assert(MakePOT(SpriteInfo[I].Width) = SpriteInfo[I].Width);
      Assert(MakePOT(SpriteInfo[I].Height) = SpriteInfo[I].Height);
      SetLength(TD, 0);
      SetLength(TD, SpriteInfo[I].Width * SpriteInfo[I].Height);

      //Copy sprite to Atlas
      for K := 0 to High(SpriteInfo[I].Sprites) do
      begin
        ID := SpriteInfo[I].Sprites[K].SpriteID;
        for L := 0 to fRXData.Size[ID].Y - 1 do
        for M := 0 to fRXData.Size[ID].X - 1 do
        begin
          CT := SpriteInfo[I].Sprites[K].PosY;
          CL := SpriteInfo[I].Sprites[K].PosX;
          Pixel := (CT + L) * SpriteInfo[I].Width + CL + M;
          if aMode = saBase then
            TD[Pixel] := fRXData.RGBA[ID, L * fRXData.Size[ID].X + M]
          else
            TD[Pixel] := $FFFFFF or (fRXData.Mask[ID, L * fRXData.Size[ID].X + M] shl 24);

          //Fill padding with edge pixels
          if fPad > 0 then
          begin
            if (M = 0) then
            begin
              TD[Pixel - 1] := TD[Pixel];
              if (L = 0) then
                TD[Pixel - SpriteInfo[I].Width - 1] := TD[Pixel]
              else
              if (L = fRXData.Size[ID].Y - 1) then
                TD[Pixel + SpriteInfo[I].Width - 1] := TD[Pixel];
            end;

            if (M = fRXData.Size[ID].X - 1) then
            begin
              TD[Pixel + 1] := TD[Pixel];
              if (L = 0) then
                TD[Pixel - SpriteInfo[I].Width + 1] := TD[Pixel]
              else
              if (L = fRXData.Size[ID].Y - 1) then
                TD[Pixel + SpriteInfo[I].Width + 1] := TD[Pixel];
            end;

            if (L = 0) then                       TD[Pixel - SpriteInfo[I].Width] := TD[Pixel];
            if (L = fRXData.Size[ID].Y - 1) then  TD[Pixel + SpriteInfo[I].Width] := TD[Pixel];
          end;

          //Sprite outline
          if OUTLINE_ALL_SPRITES and (
            (L = 0) or (M = 0)
            or (L = fRXData.Size[ID].Y - 1)
            or (M = fRXData.Size[ID].X - 1)) then
            TD[Pixel] := $FF0000FF;
        end;
      end;

      if aFillGFXData then
      begin
        //Generate texture once
        texFilter := ftNearest;
        if LINEAR_FILTER_SPRITES and (fRT in [rxTrees, rxHouses, rxUnits]) then
          texFilter := ftLinear;

        Tx := TRender.GenTexture(SpriteInfo[I].Width, SpriteInfo[I].Height, @TD[0], aTexType, texFilter, texFilter);
        //Now that we know texture IDs we can fill GFXData structure
        SetGFXData(Tx, SpriteInfo[I], aMode);
      end else begin
        Assert(InRange(I, Low(fGFXPrepData[aMode]), High(fGFXPrepData[aMode])),
               Format('Preloading sprite index out of range: %d, range [%d;%d]', [I, Low(fGFXPrepData[aMode]), High(fGFXPrepData[aMode])]));
        // Save prepared data for generating later (in main thread)
        fGFXPrepData[aMode, I].SpriteInfo := SpriteInfo[I];
        fGFXPrepData[aMode, I].TexType := aTexType;
        fGFXPrepData[aMode, I].Data := TD;
      end;

      if aMode = saBase then
        Inc(BaseRAM, SpriteInfo[I].Width * SpriteInfo[I].Height * TEX_FORMAT_SIZE[aTexType])
      else
        Inc(ColorRAM, SpriteInfo[I].Width * SpriteInfo[I].Height * TEX_FORMAT_SIZE[aTexType]);

      Inc(TexCount);

      if aFillGFXData and EXPORT_SPRITE_ATLASES then
        SaveTextureToPNG(SpriteInfo[I].Width, SpriteInfo[I].Height, RXInfo[fRT].FileName + '_' +
                         SPRITE_TYPE_EXPORT_NAME[aMode] + IntToStr(aStartingIndex+I), TD);
    end;
  end;

  function StopExec: Boolean;
  begin
    Result := Assigned(aOnStopExecution) and aOnStopExecution;
  end;

var
  I, K: Integer;
  spriteSizes: TIndexSizeArray;
  spriteInfo: TBinArray;
  atlasSize, allTilesAtlasSize: Integer;
begin
  BaseRAM := 0;
  ColorRAM := 0;
  //Prepare base atlases
  SetLength(spriteSizes, fRXData.Count - aStartingIndex + 1);
  K := 0;
  for I := aStartingIndex to fRXData.Count do
  if (fRXData.Size[I].X * fRXData.Size[I].Y <> 0) and (Length(fRXData.RGBA[I]) > 0) then
  begin
    spriteSizes[K].ID := I;
    spriteSizes[K].X := fRXData.Size[I].X;
    spriteSizes[K].Y := fRXData.Size[I].Y;
    Inc(K);
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

  if StopExec then Exit; //Our thread could be terminated and asked to stop. Exit immidiately then

  SetLength(fGFXPrepData[saBase], Length(spriteInfo));
  PrepareAtlases(spriteInfo, saBase, aTexType);

  if StopExec then Exit;

  //Prepare masking atlases
  SetLength(spriteSizes, fRXData.Count - aStartingIndex + 1);
  K := 0;
  for I := aStartingIndex to fRXData.Count do
  if (fRXData.Size[I].X * fRXData.Size[I].Y <> 0) and fRXData.HasMask[I] and (Length(fRXData.Mask[I]) > 0) then
  begin
    spriteSizes[K].ID := I;
    spriteSizes[K].X := fRXData.Size[I].X;
    spriteSizes[K].Y := fRXData.Size[I].Y;
    Inc(K);
  end;
  SetLength(spriteSizes, K);

  SetLength(spriteInfo, 0);
  BinPack(spriteSizes, atlasSize, fPad, spriteInfo);
  if StopExec then Exit;
  SetLength(fGFXPrepData[saMask], Length(spriteInfo));
  PrepareAtlases(spriteInfo, saMask, tfAlpha8);
end;
{$ENDIF}


procedure TKMSpritePack.SaveTextureToPNG(aWidth, aHeight: Word; const aFilename: string; var Data: TKMCardinalArray);
var
  I, K: Word;
  folder: string;
  pngWidth, pngHeight: Word;
  pngData: TKMCardinalArray;
begin
  folder := ExeDir + 'Export' + PathDelim + 'GenTextures' + PathDelim;
  ForceDirectories(folder);

  pngWidth := aWidth;
  pngHeight := aHeight;
  SetLength(pngData, pngWidth * pngHeight);

  for I := 0 to aHeight - 1 do
    for K := 0 to aWidth - 1 do
      pngData[I * aWidth + K] := (PCardinal(Cardinal(@Data[0]) + (I * aWidth + K) * 4))^;

  SaveToPng(pngWidth, pngHeight, pngData, folder + aFilename + '.png');
end;


procedure TKMSpritePack.ClearGameResGenTemp;
var
  SAT: TSpriteAtlasType;
begin
  for SAT := Low(TSpriteAtlasType) to High(TSpriteAtlasType) do
    SetLength(fGFXPrepData[SAT], 0);
end;


{$IFDEF LOAD_GAME_RES_ASYNC}
// Generate texture atlases from previosly prepared SpriteInfo data (loaded from RXX, Bin Packed, copied to atlas)
// Preparation was done asynchroniously by TTGameResourceLoader thread
// Texture generating task can be done only by main thread, as OpenGL does not work with multiple threads
// Note: this could be from the loader thread by using `Synchronise` procedure
procedure TKMSpritePack.GenerateTextureAtlasForGameRes;
var
  I: Integer;
  SAT: TSpriteAtlasType;
  Tx: Cardinal;
  texFilter: TFilterType;
begin
  {$IFNDEF NO_OGL}
  gLog.AddTime('TKMSpritePack.GenerateTextureAtlasForGameRes');
  for SAT := Low(TSpriteAtlasType) to High(TSpriteAtlasType) do
    for I := Low(fGFXPrepData[SAT]) to High(fGFXPrepData[SAT]) do
    begin
      with fGFXPrepData[SAT,I] do
      begin
        texFilter := ftNearest;
        if LINEAR_FILTER_SPRITES and (fRT in [rxTrees, rxHouses, rxUnits]) then
          texFilter := ftLinear;

        Tx := TRender.GenTexture(SpriteInfo.Width, SpriteInfo.Height, @Data[0], TexType, texFilter, texFilter);
        //Now that we know texture IDs we can fill GFXData structure
        SetGFXData(Tx, SpriteInfo, SAT);

        if EXPORT_SPRITE_ATLASES then
          SaveTextureToPNG(SpriteInfo.Width, SpriteInfo.Height, RXInfo[fRT].FileName + '_' +
                           SPRITE_TYPE_EXPORT_NAME[SAT] + IntToStr(I+1), Data);
      end;
    end;
  {$ENDIF}
end;
{$ENDIF}


{ TKMResSprites }
constructor TKMResSprites.Create(aStepProgress: TEvent = nil; aStepCaption: TUnicodeStringEvent = nil; aTemp: Boolean = False);
var
  RT: TRXType;
begin
  inherited Create;
  fGameRXTypes := TStringList.Create;
  fTemp := aTemp;

  for RT := Low(TRXType) to High(TRXType) do
  begin
    fSprites[RT] := TKMSpritePack.Create(RT, fTemp);
    if RXInfo[RT].Usage = ruGame then
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
        Exit
      else begin
        Result := I + 1;
        Exit;
      end;
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
    gLog.AddTime(Format('Legacy: TexId = %d GenTilesCntTemp = %d', [texId, genTilesCntTemp]));
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
    gLog.AddTime(Format('TexId = %d GenTilesCnt = %d', [texId, genTilesCnt]));
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
              
    //          gLog.AddTime(Format('TerKind: %10s Mask: %10s TexId: %d ', [GetEnumName(TypeInfo(TKMTerrainKind), Integer(I)),
    //                                                        GetEnumName(TypeInfo(TKMTileMaskType), Integer(J)), TexId]));

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
      gLog.AddTime(Format('TexId = %d; TexId - fGenTexIdStartILegacy = %d; uniqueTex = %d; totalTex = %d', [texId, texId - fGenTexIdStartILegacy, uniqueTex, totalTex]));
    end
    else
    begin
      // There could be usused place in arrays, as we could use same mask image for different purposes
      aSprites.Allocate(texId);
      SetLength(fGenTerrainToTerKind, texId - fGenTexIdStartI);
      gLog.AddTime(Format('TexId = %d; TexId - fGenTexIdStartI = %d; uniqueTex = %d; totalTex = %d', [texId, texId - fGenTexIdStartI, uniqueTex, totalTex]));
    end;

  finally
    gLog.AddTime('GeneratedMasks cnt = ' + IntToStr(generatedMasks.Count));
    generatedMasks.Free;
  end;
  gLog.AddTime('GenerateTerrainTransitions Done.');
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
  Result := RXInfo[aRX].FileName;
end;


function TKMResSprites.GetSprites(aRT: TRXType): TKMSpritePack;
begin
  Result := fSprites[aRT];
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
    if RXInfo[RT].Usage = ruMenu then
    begin
      if Assigned(fStepCaption) then
        fStepCaption('Reading ' + RXInfo[RT].FileName + ' ...');

      gLog.AddTime('Reading ' + RXInfo[RT].FileName + '.rx');
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
    rxaFile: string;
  begin
    for RT := Low(TRXType) to High(TRXType) do
      if RXInfo[RT].Usage = ruGame then
      begin
        if Assigned(fStepCaption) then
          fStepCaption(gResTexts[RXInfo[RT].LoadingTextID]);

        rxaFile := ExeDir + 'data' + PathDelim + 'Sprites' + PathDelim + RXInfo[RT].FileName + '.rxa';
        if fAlphaShadows and FileExists(rxaFile) then
        begin
          gLog.AddTime('Reading ' + RXInfo[RT].FileName + '.rxa');
          fSprites[RT].LoadFromRXAAndGenTextures(rxaFile);

          fSprites[RT].OverloadFromFolder(ExeDir + 'Sprites' + PathDelim); // Legacy support
          // 'Sprites' folder name confused some of the players, cause there is already data/Sprites folder
          fSprites[RT].OverloadFromFolder(ExeDir + 'Modding graphics' + PathDelim);
        end
        else
        begin
          gLog.AddTime('Reading ' + RXInfo[RT].FileName + '.rx');
          LoadSprites(RT, fAlphaShadows);
          {$IFNDEF NO_OGL}
          fSprites[RT].MakeGFX(fAlphaShadows);
          {$ENDIF}
        end;
        // Clear temp data as fast as possible
        fSprites[RT].ClearTemp;
        fSprites[RT].ClearGameResGenTemp;
      end;

    fGameResLoadCompleted := True;
  end;

begin
  gLog.AddTime('TKMResSprites.LoadGameResources');
  fGameResLoadCompleted := False;
  //Remember which version we load, so if it changes inbetween games we reload it
  fAlphaShadows := aAlphaShadows;
  {$IFDEF LOAD_GAME_RES_ASYNC}
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
  Result := False;
  if aAlphaShadows and FileExists(ExeDir + 'data' + PathDelim + 'Sprites' + PathDelim + RXInfo[aRT].FileName + '_a.rxx') then
  begin
    fSprites[aRT].LoadFromRXXFile(ExeDir + 'data' + PathDelim + 'Sprites' + PathDelim + RXInfo[aRT].FileName + '_a.rxx');
    Result := True;
  end
  else
  if FileExists(ExeDir + 'data' + PathDelim + 'Sprites' + PathDelim + RXInfo[aRT].FileName + '.rxx') then
  begin
    fSprites[aRT].LoadFromRXXFile(ExeDir + 'data' + PathDelim + 'Sprites' + PathDelim + RXInfo[aRT].FileName + '.rxx');
    Result := True;
  end
  else
    Exit;

  fSprites[aRT].OverloadFromFolder(ExeDir + 'Sprites' + PathDelim); // Legacy support
  // 'Sprites' folder name confused some of the players, cause there is already data/Sprites folder
  fSprites[aRT].OverloadFromFolder(ExeDir + 'Modding graphics' + PathDelim);

  // Generate terrain transitions
  if aRT = rxTiles then
  begin
    GenerateTerrainTransitions(fSprites[aRT]);
    GenerateTerrainTransitions(nil, True); //To get support for maps rev <= 10745
  end;
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
    if Assigned(fStepCaption) then
      fStepCaption(gResTexts[RXInfo[fGameResLoader.RXType].LoadingTextID]);

    gLog.AddTime('[AsyncGameResLoader MainTh] [' + aCallerName + '] GenTextures for RT = ' + GetEnumName(TypeInfo(TRXType), Integer(fGameResLoader.RXType)));

    // Generate texture atlas from prepared data for game resources
    // OpenGL work mainly with 1 thread only, so we have to call gl functions only from main thread
    // That is why we need call this method from main thread only

    // Note: this could be from the loader thread by using `Synchronise` procedure
    if fGameResLoader.LastLoadedRXA then
      fSprites[fGameResLoader.RXType].GenerateTexturesFromLoadedRXA
    else
      fSprites[fGameResLoader.RXType].GenerateTextureAtlasForGameRes;

    fSprites[fGameResLoader.RXType].ClearTemp;      //Clear fRXData sprites temp data, which is not needed anymore
    fSprites[fGameResLoader.RXType].ClearGameResGenTemp; //Clear all the temp data used for atlas texture generating
    nextRXTypeI := GetNextLoadRxTypeIndex(fGameResLoader.RXType); // get next RXType to load
    if nextRXTypeI = -1 then
    begin
      //Load is completed, we can stop loading thread
      StopAsyncResourceLoader;
      fGameResLoadCompleted := True; // mark loading game res as completed
    end else begin
      fGameResLoader.RXType := TRXType(StrToInt(fGameRXTypes[nextRXTypeI]));

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
    fSprites[aRT].ExportAll(ExeDir + 'Export' + PathDelim + RXInfo[aRT].FileName + '.rx' + PathDelim);
    ClearTemp;
  end;
end;


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
  gLog.MultithreadLogging := True;

  Log('Started');
end;


destructor TTGameResourceLoader.Destroy;
begin
  Log('Stopped');

  gLog.MultithreadLogging := False;

  inherited;
end;


procedure TTGameResourceLoader.Log(const aString: string);
begin
  gLog.AddTime('[AsyncGameResLoader Thread] ' + aString);
end;


procedure TTGameResourceLoader.Execute;
var
  rxaFile: string;
begin
  inherited;

  while not Terminated do
  begin
    if not LoadStepDone then
    begin
      Log('Load RT = ' + GetEnumName(TypeInfo(TRXType), Integer(RXType)));

      if SLOW_ASYNC_RES_LOADER then
        Sleep(5000);

      rxaFile := ExeDir + 'data' + PathDelim + 'Sprites' + PathDelim + RXInfo[RXType].FileName + '.rxa';
      if fAlphaShadows and FileExists(rxaFile) then
      begin
        Log('Start Load RXA ''' + RXInfo[RXType].FileName + '.rxa''');
        fResSprites.fSprites[RXType].LoadFromRXAFile(rxaFile);
        if Terminated then Exit;

        fResSprites.fSprites[RXType].OverloadFromFolder(ExeDir + 'Sprites' + PathDelim); // Legacy support
        // 'Sprites' folder name confused some of the players, cause there is already data/Sprites folder
        fResSprites.fSprites[RXType].OverloadFromFolder(ExeDir + 'Modding graphics' + PathDelim);

        AtomicExchange(Integer(LastLoadedRXA), Integer(True));
        Log('DONE Load RXA ''' + RXInfo[RXType].FileName + '.rxa''');
      end
      else
      begin
        Log('Start Load RXX ''' + RXInfo[RXType].FileName + '.rxx''');
        fResSprites.LoadSprites(RXType, fAlphaShadows);
        if Terminated then Exit;

        {$IFNDEF NO_OGL}
        fResSprites.fSprites[RXType].MakeGFX(fAlphaShadows, 1, False, IsTerminated);
        {$ENDIF}

        AtomicExchange(Integer(LastLoadedRXA), Integer(False));
        Log('DONE Load RXX ''' + RXInfo[RXType].FileName + '.rxa''');
      end;

      // Make this atomic, since LoadStepDone is accessed in different threads
      AtomicExchange(Integer(LoadStepDone), Integer(True));
    end;
    Sleep(1); // sleep a a bit
  end;
end;


function TTGameResourceLoader.IsTerminated: Boolean;
begin
  Result := Terminated;
end;


end.
