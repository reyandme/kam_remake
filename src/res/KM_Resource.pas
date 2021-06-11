unit KM_Resource;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  Classes, SysUtils,
  KM_CommonTypes, KM_Defaults,
  KM_ResTypes,
  KM_ResCursors,
  KM_ResFonts,
  KM_ResHouses,
  KM_ResLocales,
  KM_ResMapElements,
  KM_ResPalettes,
  KM_ResSound,
  KM_ResSprites,
  KM_ResTileset,
  KM_ResUnits,
  KM_ResWares,
  KM_ResInterpolation;


type
  TResourceLoadState = (rlsNone, rlsMenu, rlsAll); //Resources are loaded in 2 steps, for menu and the rest

  TKMResource = class
  private
    fDataState: TResourceLoadState;

    fCursors: TKMResCursors;
    fFonts: TKMResFonts;
    fUnits: TKMResUnits;
    fSounds: TKMResSounds;
    fSprites: TKMResSprites;
    fTileset: TKMResTileset;
    fMapElements: TKMResMapElements;
    fInterpolation: TKMResInterpolation;

    procedure StepRefresh;
    procedure StepCaption(const aCaption: UnicodeString);

    function GetHouses: TKMResHouses;
    function GetWares: TKMResWares;
    function GetPalettes: TKMResPalettes;
  public
    OnLoadingStep: TEvent;
    OnLoadingText: TUnicodeStringEvent;

    constructor Create(aOnLoadingStep: TEvent; aOnLoadingText: TUnicodeStringEvent);
    destructor Destroy; override;

    function GetDATCRC: Cardinal;

    procedure LoadMainResources(const aLocale: AnsiString = ''; aLoadFullFonts: Boolean = True);
    procedure LoadLocaleAndFonts(const aLocale: AnsiString = ''; aLoadFullFonts: Boolean = True);
    procedure LoadLocaleResources(const aLocale: AnsiString = '');
    procedure LoadGameResources(aAlphaShadows: Boolean; aForceReload: Boolean = False);
    procedure LoadLocaleFonts(const aLocale: AnsiString; aLoadFullFonts: Boolean);

    property DataState: TResourceLoadState read fDataState;
    property Palettes: TKMResPalettes read GetPalettes;
    property Cursors: TKMResCursors read fCursors;
    property MapElements: TKMResMapElements read fMapElements;
    property Fonts: TKMResFonts read fFonts;
    property Sounds: TKMResSounds read fSounds;
    property Sprites: TKMResSprites read fSprites;
    property Tileset: TKMResTileset read fTileset;
    property Houses: TKMResHouses read GetHouses;
    property Units: TKMResUnits read fUnits;
    property Wares: TKMResWares read GetWares;
    property Interpolation: TKMResInterpolation read fInterpolation;

    procedure UpdateStateIdle;

    function IsMsgHouseUnnocupied(aMsgId: Word): Boolean;
  end;


var
  gRes: TKMResource;


implementation
uses
  TypInfo,
  {$IFNDEF NO_OGL}
  KM_System,
  {$ENDIF}
  KromUtils, KM_Log, KM_Points,
  KM_ResTexts, KM_ResKeys, KM_ResTilesetTypes;


{ TKMResource }
constructor TKMResource.Create(aOnLoadingStep: TEvent; aOnLoadingText: TUnicodeStringEvent);
begin
  inherited Create;

  fDataState := rlsNone;
  gLog.AddTime('Resource loading state - None');

  OnLoadingStep := aOnLoadingStep;
  OnLoadingText := aOnLoadingText;
end;


destructor TKMResource.Destroy;
begin
  FreeAndNil(fCursors);
  FreeAndNil(gResHouses);
  FreeAndNil(gResLocales);
  FreeAndNil(fMapElements);
  FreeAndNil(gResPalettes);
  FreeAndNil(fFonts);
  FreeAndNil(gResWares);
  FreeAndNil(fSprites);
  FreeAndNil(fSounds);
  FreeAndNil(gResTexts);
  FreeAndNil(fTileset);
  FreeAndNil(fUnits);
  FreeAndNil(gResKeys);

  inherited;
end;


procedure TKMResource.UpdateStateIdle;
begin
  fSprites.UpdateStateIdle;
end;


procedure TKMResource.StepRefresh;
begin
  if Assigned(OnLoadingStep) then OnLoadingStep;
end;


procedure TKMResource.StepCaption(const aCaption: UnicodeString);
begin
  if Assigned(OnLoadingText) then OnLoadingText(aCaption);
end;


//CRC of data files that can cause inconsitencies
function TKMResource.GetDATCRC: Cardinal;
begin
  Result := gResHouses.CRC xor
            fUnits.CRC xor
            fMapElements.CRC xor
            fTileset.CRC;
end;


function TKMResource.GetHouses: TKMResHouses;
begin
  Result := gResHouses;
end;


procedure TKMResource.LoadMainResources(const aLocale: AnsiString = ''; aLoadFullFonts: Boolean = True);
var
  tileColors: TKMColor3bArray;
begin
  StepCaption('Reading palettes ...');
  gResPalettes := TKMResPalettes.Create;
  //We are using only default palette in the game for now, so no need to load all palettes
  gResPalettes.LoadDefaultPalette(ExeDir + 'data' + PathDelim + 'gfx' + PathDelim);
  gLog.AddTime('Reading palettes', True);

  fSprites := TKMResSprites.Create(StepRefresh, StepCaption);

  fCursors := TKMResCursors.Create;

  fUnits := TKMResUnits.Create; // Load units prior to Sprites, as we could use it on SoftenShadows override for png in Sprites folder
  fSprites.LoadMenuResources;

  {$IFNDEF NO_OGL}
  gSystem.MakeCursors(fSprites[rxGui]);
  gSystem.Cursor := kmcDefault;
  {$ENDIF}
  fCursors.SetRXDataPointer(@fSprites[rxGui].RXData);

  gResKeys := TKMResKeys.Create;

  LoadLocaleAndFonts(aLocale, aLoadFullFonts);

  fTileset := TKMResTileset.Create;
  if not SKIP_RENDER then
  begin
    tileColors := fSprites.Sprites[rxTiles].GetSpriteColors(TILES_CNT);
    fTileset.SetTilesColor(tileColors);
  end;

  fMapElements := TKMResMapElements.Create;
  fMapElements.LoadFromFile(ExeDir + 'data' + PathDelim + 'defines' + PathDelim + 'mapelem.dat');

  fSprites.ClearTemp;

  gResWares := TKMResWares.Create;
  gResHouses := TKMResHouses.Create;

  StepRefresh;
  gLog.AddTime('ReadGFX is done');
  fDataState := rlsMenu;
  gLog.AddTime('Resource loading state - Menu');
end;


procedure TKMResource.LoadLocaleResources(const aLocale: AnsiString = '');
begin
  FreeAndNil(gResLocales);
  FreeAndNil(gResTexts);
  FreeAndNil(fSounds);

  gResLocales := TKMResLocales.Create(ExeDir + 'data' + PathDelim + 'locales.txt', aLocale);

  gResTexts := TKMTextLibraryMulti.Create;
  gResTexts.LoadLocale(ExeDir + 'data' + PathDelim + 'text' + PathDelim + 'text.%s.libx');

  fSounds := TKMResSounds.Create(gResLocales.UserLocale, gResLocales.FallbackLocale, gResLocales.DefaultLocale);
end;


procedure TKMResource.LoadLocaleAndFonts(const aLocale: AnsiString = ''; aLoadFullFonts: Boolean = True);
begin
  // Locale info is needed for DAT export and font loading
  LoadLocaleResources(aLocale);

  StepCaption('Reading fonts ...');
  fFonts := TKMResFonts.Create;
  if aLoadFullFonts or gResLocales.LocaleByCode(aLocale).NeedsFullFonts then
    fFonts.LoadFonts(fllFull)
  else
    fFonts.LoadFonts(fllMinimal);
  gLog.AddTime('Read fonts is done');
end;


procedure TKMResource.LoadLocaleFonts(const aLocale: AnsiString; aLoadFullFonts: Boolean);
begin
  if (Fonts.LoadLevel <> fllFull)
    and (aLoadFullFonts or gResLocales.LocaleByCode(aLocale).NeedsFullFonts) then
    Fonts.LoadFonts(fllFull);
end;


procedure TKMResource.LoadGameResources(aAlphaShadows: Boolean; aForceReload: Boolean = False);
var
  doForceReload: Boolean;
begin
  if fInterpolation = nil then
  begin
    fInterpolation := TKMResInterpolation.Create;
    fInterpolation.LoadFromFile(ExeDir + 'data' + PathDelim + 'defines' + PathDelim + 'interp.dat');
  end;

  gLog.AddTime('LoadGameResources ... AlphaShadows: ' + BoolToStr(aAlphaShadows, True) + '. Forced: ' + BoolToStr(aForceReload, True));
  doForceReload := aForceReload or (aAlphaShadows <> fSprites.AlphaShadows);
  if (fDataState <> rlsAll) or doForceReload then
  begin
    fSprites.LoadGameResources(aAlphaShadows, doForceReload);
    fDataState := rlsAll;
    fSprites.ClearTemp;
  end;

  gLog.AddTime('Resource loading state - Game');
end;


function TKMResource.IsMsgHouseUnnocupied(aMsgId: Word): Boolean;
begin
  Result := (aMsgId >= TX_MSG_HOUSE_UNOCCUPIED__22) and (aMsgId <= TX_MSG_HOUSE_UNOCCUPIED__22 + 22);
end;


function TKMResource.GetPalettes: TKMResPalettes;
begin
  Result := gResPalettes;
end;


function TKMResource.GetWares: TKMResWares;
begin
  Result := gResWares;
end;


end.
