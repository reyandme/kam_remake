unit KM_Resource;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  Classes, Graphics, SysUtils,
  KM_CommonTypes, KM_Defaults, KM_Pics, KM_WorkerThread,

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
  KM_ResWares;


type
  TResourceLoadState = (rlsNone, rlsMenu, rlsAll); //Resources are loaded in 2 steps, for menu and the rest

  TKMResource = class
  private
    fDataState: TResourceLoadState;

    fCursors: TKMResCursors;
    fFonts: TKMResFonts;
    fHouses: TKMResHouses;
    fUnits: TKMResUnits;
    fPalettes: TKMResPalettes;
    fWares: TKMResWares;
    fSounds: TKMResSounds;
    fSprites: TKMResSprites;
    fTileset: TKMResTileset;
    fMapElements: TKMResMapElements;

    fExportWorker: TKMWorkerThread;

    procedure StepRefresh;
    procedure StepCaption(const aCaption: UnicodeString);
    function GetHouses: TKMResHouses;

    function GetOrCreateExportWorker: TKMWorkerThread;
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
    property Cursors: TKMResCursors read fCursors;
    property Houses: TKMResHouses read GetHouses;
    property MapElements: TKMResMapElements read fMapElements;
    property Palettes: TKMResPalettes read fPalettes;
    property Fonts: TKMResFonts read fFonts;
    property Wares: TKMResWares read fWares;
    property Sounds: TKMResSounds read fSounds;
    property Sprites: TKMResSprites read fSprites;
    property Tileset: TKMResTileset read fTileset;
    property Units: TKMResUnits read fUnits;

    procedure UpdateStateIdle;

    function IsMsgHouseUnnocupied(aMsgId: Word): Boolean;

    procedure ExportTreeAnim(aOnDone: TProc<String> = nil);
    procedure ExportHouseAnim(aOnDone: TProc<String> = nil);
    procedure ExportUnitAnim(aUnitFrom, aUnitTo: TKMUnitType; aExportUnused: Boolean = False; aOnDone: TProc<String> = nil);
    procedure ExportSpritesToPNG(aRT: TRXType; aOnDone: TProc<String> = nil);
  end;


var
  gRes: TKMResource;


implementation
uses
  TypInfo, KromUtils, KM_Log, KM_Points, KM_ResTexts, KM_ResKeys,
  KM_ResTypes;


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
  FreeAndNil(fHouses);
  FreeAndNil(gResLocales);
  FreeAndNil(fMapElements);
  FreeAndNil(fPalettes);
  FreeAndNil(fFonts);
  FreeAndNil(fWares);
  FreeAndNil(fSprites);
  FreeAndNil(fSounds);
  FreeAndNil(gResTexts);
  FreeAndNil(fTileset);
  FreeAndNil(fUnits);
  FreeAndNil(gResKeys);

  if fExportWorker <> nil then
    //This will ensure all queued work is completed before destruction
    FreeAndNil(fExportWorker);

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
  Result := fHouses.CRC xor
            fUnits.CRC xor
            fMapElements.CRC xor
            fTileset.CRC;
end;


function TKMResource.GetHouses: TKMResHouses;
begin
  if Self = nil then Exit(nil);

  Result := fHouses;
end;


procedure TKMResource.LoadMainResources(const aLocale: AnsiString = ''; aLoadFullFonts: Boolean = True);
begin
  StepCaption('Reading palettes ...');
  fPalettes := TKMResPalettes.Create;
  //We are using only default palette in the game for now, so no need to load all palettes
  fPalettes.LoadDefaultPalette(ExeDir + 'data' + PathDelim + 'gfx' + PathDelim);
  gLog.AddTime('Reading palettes', True);


  fSprites := TKMResSprites.Create(StepRefresh, StepCaption);

  fCursors := TKMResCursors.Create;

  fUnits := TKMResUnits.Create; // Load units prior to Sprites, as we could use it on SoftenShadows override for png in Sprites folder
  fSprites.LoadMenuResources;
  fCursors.MakeCursors(fSprites[rxGui]);
  fCursors.Cursor := kmcDefault;

  gResKeys := TKMKeyLibrary.Create;

  LoadLocaleAndFonts(aLocale, aLoadFullFonts);

  fTileset := TKMResTileset.Create(ExeDir + 'data' + PathDelim + 'defines' + PathDelim + 'pattern.dat');
  if not SKIP_RENDER then
    fTileset.TileColor := fSprites.Sprites[rxTiles].GetSpriteColors(TILES_CNT);

  fMapElements := TKMResMapElements.Create;
  fMapElements.LoadFromFile(ExeDir + 'data' + PathDelim + 'defines' + PathDelim + 'mapelem.dat');

  fSprites.ClearTemp;

  fWares := TKMResWares.Create;
  fHouses := TKMResHouses.Create;

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

  gResLocales := TKMLocales.Create(ExeDir + 'data' + PathDelim + 'locales.txt', aLocale);

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
  DoForceReload: Boolean;
begin
  gLog.AddTime('LoadGameResources ... AlphaShadows: ' + BoolToStr(aAlphaShadows, True) + '. Forced: ' + BoolToStr(aForceReload, True));
  DoForceReload := aForceReload or (aAlphaShadows <> fSprites.AlphaShadows);
  if (fDataState <> rlsAll) or DoForceReload then
  begin
    fSprites.LoadGameResources(aAlphaShadows, DoForceReload);
    fDataState := rlsAll;
    fSprites.ClearTemp;
  end;

  gLog.AddTime('Resource loading state - Game');
end;


function TKMResource.IsMsgHouseUnnocupied(aMsgId: Word): Boolean;
begin
  Result := (aMsgId >= TX_MSG_HOUSE_UNOCCUPIED__22) and (aMsgId <= TX_MSG_HOUSE_UNOCCUPIED__22 + 22);
end;


function TKMResource.GetOrCreateExportWorker: TKMWorkerThread;
begin
  if fExportWorker = nil then
    fExportWorker := TKMWorkerThread.Create('ExportWorker');

  Result := fExportWorker;
end;


procedure TKMResource.ExportSpritesToPNG(aRT: TRXType; aOnDone: TProc<String> = nil);
begin
  GetOrCreateExportWorker.QueueWork(procedure
  var
    sprites: TKMResSprites;
  begin
    sprites := TKMResSprites.Create;
    try
      if sprites.LoadSprites(aRT, False) then
      begin
        sprites[aRT].ExportAll(ExeDir + 'Export' + PathDelim + RXInfo[aRT].FileName + '.rx' + PathDelim);
        sprites.ClearTemp;
      end;
    finally
      sprites.Free;
    end;
  end, aOnDone, 'Export ' + GetEnumName(TypeInfo(TRXType), Integer(aRT)));
end;


//Export Units graphics categorized by Unit and Action
procedure TKMResource.ExportUnitAnim(aUnitFrom, aUnitTo: TKMUnitType; aExportUnused: Boolean = False; aOnDone: TProc<String> = nil);
begin

  // Asynchroniously export data
  GetOrCreateExportWorker.QueueWork(procedure
    var
      FullFolder,Folder: string;
      U: TKMUnitType;
      A: TKMUnitActionType;
      Anim: TKMAnimLoop;
      D: TKMDirection;
      R: TKMWareType;
      T: TKMUnitThought;
      i,ci:integer;
      Used:array of Boolean;
      RXData: TRXData;
      SpritePack: TKMSpritePack;
      SList: TStringList;
      FolderCreated: Boolean;
      sprites: TKMResSprites;
      units: TKMResUnits;
      resTexts: TKMTextLibraryMulti;
    begin

    sprites := TKMResSprites.Create;
    sprites.LoadSprites(rxUnits, False); //BMP can't show alpha shadows anyways
    SpritePack := sprites[rxUnits];
    RXData := SpritePack.RXData;

    units := TKMResUnits.Create;
    resTexts := TKMTextLibraryMulti.Create;
    resTexts.LoadLocale(ExeDir + 'data' + PathDelim + 'text' + PathDelim + 'text.%s.libx');
    resTexts.ForceDefaultLocale := True;

    Folder := ExeDir + 'Export' + PathDelim + 'UnitAnim' + PathDelim;
    ForceDirectories(Folder);

    SList := TStringList.Create;
    try
      for U := aUnitFrom to aUnitTo do
        for A := Low(TKMUnitActionType) to High(TKMUnitActionType) do
        begin
          FolderCreated := False;
          for D := dirN to dirNW do
            if units[U].UnitAnim[A,D].Step[1] <> -1 then
              for i := 1 to units[U].UnitAnim[A, D].Count do
              begin
                ci := units[U].UnitAnim[A,D].Step[i] + 1;
                if ci <> 0 then
                begin
                  if not FolderCreated then
                  begin
                    //Use default locale for Unit GUIName, as translation could be not good for file system (like russian '����������/�������' with slash in it)
                    FullFolder := Folder + resTexts.DefaultTexts[units[U].GUITextID] + PathDelim + UNIT_ACT_STR[A] + PathDelim;
                    ForceDirectories(FullFolder);
                    FolderCreated := True;
                  end;
                  SpritePack.ExportFullImageData(FullFolder, ci, SList);
                  // Stop export if async thread is terminated by application
                  if TThread.CheckTerminated then
                    Exit;
                end;
              end;
        end;

      SetLength(Used, Length(RXData.Size));

      //Exclude actions
      for U := Low(TKMUnitType) to High(TKMUnitType) do
        for A := Low(TKMUnitActionType) to High(TKMUnitActionType) do
          for D := dirN to dirNW do
            if units[U].UnitAnim[A,D].Step[1] <> -1 then
            for i := 1 to units[U].UnitAnim[A,D].Count do
            begin
              ci := units[U].UnitAnim[A,D].Step[i]+1;
              Used[ci] := ci <> 0;
            end;

      if utSerf in [aUnitFrom..aUnitTo] then
        //serfs carrying stuff
        for R := WARE_MIN to WARE_MAX do
        begin
          FolderCreated := False;
          for D := dirN to dirNW do
          begin
            Anim := units.SerfCarry[R, D];
            for i := 1 to Anim.Count do
            begin
              ci := Anim.Step[i]+1;
              if ci <> 0 then
              begin
                Used[ci] := True;
                if utSerf in [aUnitFrom..aUnitTo] then
                begin
                  if not FolderCreated then
                  begin
                    //Use default locale for Unit GUIName, as translation could be not good for file system (like russian '����������/�������' with slash in it)
                    FullFolder := Folder + resTexts.DefaultTexts[units[utSerf].GUITextID] + PathDelim + 'Delivery' + PathDelim
                                    + GetEnumName(TypeInfo(TKMWareType), Integer(R)) + PathDelim;
                    ForceDirectories(FullFolder);
                    FolderCreated := True;
                  end;
                  SpritePack.ExportFullImageData(FullFolder, ci, SList);
                  // Stop export if async thread is terminated by application
                  if TThread.CheckTerminated then
                    Exit;
                end;
              end;
            end;
          end;
        end;

      FullFolder := Folder + 'Thoughts' + PathDelim;
      ForceDirectories(FullFolder);
      for T := thEat to High(TKMUnitThought) do
        for I := THOUGHT_BOUNDS[T,1] to  THOUGHT_BOUNDS[T,2] do
        begin
          SpritePack.ExportFullImageData(FullFolder, I+1, SList);
          Used[I+1] := True;
        end;

      if not aExportUnused then Exit;

      FullFolder := Folder + '_Unused' + PathDelim;
      ForceDirectories(FullFolder);

      for ci := 1 to length(Used)-1 do
        if not Used[ci] then
        begin
          SpritePack.ExportFullImageData(FullFolder, ci, SList);
          // Stop export if async thread is terminated by application
          if TThread.CheckTerminated then
            Exit;
        end;
    finally
      sprites.ClearTemp;
      sprites.Free;
      units.Free;
      resTexts.Free;
      SList.Free;
    end;
  end, aOnDone, 'Export units anim');
end;


//Export Houses graphics categorized by House and Action
procedure TKMResource.ExportHouseAnim(aOnDone: TProc<String> = nil);
begin

  // Asynchroniously export data
  GetOrCreateExportWorker.QueueWork(procedure
  var
    FullFolder,Folder: string;
    houses: TKMResHouses;
    ID: TKMHouseType;
    Ac: TKMHouseActionType;
    Q, Beast, I, K, ci: Integer;
    SpritePack: TKMSpritePack;
    SList: TStringList;

    sprites: TKMResSprites;
    resTexts: TKMTextLibraryMulti;
  begin
    sprites := TKMResSprites.Create;
    sprites.LoadSprites(rxHouses, False); //BMP can't show alpha shadows anyways
    SpritePack := sprites[rxHouses];

    Folder := ExeDir + 'Export' + PathDelim + 'HouseAnim' + PathDelim;
    ForceDirectories(Folder);

    SList := TStringList.Create;
    houses := TKMResHouses.Create;

    resTexts := TKMTextLibraryMulti.Create;
    resTexts.LoadLocale(ExeDir + 'data' + PathDelim + 'text' + PathDelim + 'text.%s.libx');
    resTexts.ForceDefaultLocale := True;
    try
      for ID := HOUSE_MIN to HOUSE_MAX do
        for Ac := haWork1 to haFlag3 do
          for K := 1 to houses[ID].Anim[Ac].Count do
          begin                                      //HouseNameTextID    resTexts.DefaultTexts
            FullFolder := Folder + resTexts.DefaultTexts[houses[ID].HouseNameTextID] + PathDelim + HOUSE_ACTION_STR[Ac] + PathDelim;
            ForceDirectories(FullFolder);
            ci := houses[ID].Anim[Ac].Step[K] + 1;
            if ci <> 0 then
              SpritePack.ExportFullImageData(FullFolder, ci, SList);
            // Stop export if async thread is terminated by application
            if TThread.CheckTerminated then
              Exit;
          end;

      for Q := 1 to 2 do
      begin
        if Q = 1 then
          ID := htSwine
        else
          ID := htStables;
        ForceDirectories(Folder + '_' + resTexts.DefaultTexts[houses[ID].HouseNameTextID] + PathDelim);
        for Beast := 1 to 5 do
          for I := 1 to 3 do
            for K := 1 to houses.BeastAnim[ID,Beast,I].Count do
            begin
              FullFolder := Folder + resTexts.DefaultTexts[houses[ID].HouseNameTextID] + PathDelim + 'Beast' + PathDelim + int2fix(Beast,2) + PathDelim;
              ForceDirectories(FullFolder);
              ci := houses.BeastAnim[ID,Beast,I].Step[K]+1;
              if ci <> 0 then
                SpritePack.ExportFullImageData(FullFolder, ci, SList);
              // Stop export if async thread is terminated by application
              if TThread.CheckTerminated then
                Exit;
            end;
      end;
    finally
      houses.Free;
      SList.Free;
      sprites.ClearTemp;
      sprites.Free;
    end;
  end, aOnDone, 'Export house anim');
end;


//Export Trees graphics categorized by ID
procedure TKMResource.ExportTreeAnim(aOnDone: TProc<String> = nil);
begin
  // Asynchroniously export data
  GetOrCreateExportWorker.QueueWork(procedure
  var
    FullFolder, Folder: string;
    I, K: Integer;

    sprites: TKMResSprites;
    SpriteID: Integer;
    SpritePack: TKMSpritePack;
    SList: TStringList;
  begin
    sprites := TKMResSprites.Create;
    sprites.LoadSprites(rxTrees, False);
    SpritePack := sprites[rxTrees];

    Folder := ExeDir + 'Export' + PathDelim + 'TreeAnim' + PathDelim;
    ForceDirectories(Folder);

    SList := TStringList.Create;

    try
      for I := 0 to fMapElements.Count - 1 do
      if (gMapElements[I].Anim.Count > 0) and (gMapElements[I].Anim.Step[1] > 0) then
      begin
        for K := 1 to gMapElements[I].Anim.Count do
        begin
          SpriteID := gMapElements[I].Anim.Step[K] + 1;
          if SpriteID <> 0 then
          begin
            if gMapElements[I].Anim.Count > 1 then
            begin
              FullFolder := Folder + IntToStr(I) + PathDelim;
              ForceDirectories(FullFolder);
            end else
              FullFolder := Folder;
            SpritePack.ExportFullImageData(FullFolder, SpriteID, SList);
            // Stop export if async thread is terminated by application
            if TThread.CheckTerminated then
              Exit;
          end;
        end;
      end;
    finally
      sprites.ClearTemp;
      sprites.Free;
      SList.Free;
    end;
  end, aOnDone, 'Export tree anim');
end;


end.
