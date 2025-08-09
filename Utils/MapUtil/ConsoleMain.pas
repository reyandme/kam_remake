unit ConsoleMain;
{$I KaM_Remake.inc}
interface
uses
  KM_MinimapMission,
  KM_Defaults, MapUtilTypes;

type
  TConsoleMain = class(TObject)
  private
    fMinimap: TKMMinimapMission;
    procedure GenerateAndSaveMapMinimapImage(const aMapDatPath: string; aFowType: TFOWType; const aOutputFile: string);
    procedure SaveToFile(const aFileName: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Start(const aParameterRecord: TCLIParamRecord);
    procedure ShowHelp;
  end;

const
  MAPUTIL_VERSION_MAJOR = '2';
  MAPUTIL_VERSION_MINOR = '03';

var
  MAPUTIL_VERSION: String;

const
  MAPUTIL_START_TEXT    = '' + sLineBreak +
    '++=====================================================================================++' + sLineBreak +
    '++=====================================================================================++' + sLineBreak +
    '||                             KaM Remake Map Utility                                  ||' + sLineBreak +
    '++=====================================================================================++' + sLineBreak +
    '++=====================================================================================++' + sLineBreak;
  MAPUTIL_HELP_TEXT     = '' +
    '++=====================================================================================++' + sLineBreak +
    '||                                                                                     ||' + sLineBreak +
    '||  Map Utility is the tool to generate a minimap PNG image from map files             ||' + sLineBreak +
    '||                                                                                     ||' + sLineBreak +
    '||=====================================================================================||' + sLineBreak +
    '||                                                                                     ||' + sLineBreak +
    '||  Usage:                                                                             ||' + sLineBreak +
    '||    MapUtil [OPTIONS] /PathToMap/PathToMap.dat                                       ||' + sLineBreak +
    '||                                                                                     ||' + sLineBreak +
    '||  Options:                                                                           ||' + sLineBreak +
    '||    -h / -help               - Will show this menu                                   ||' + sLineBreak +
    '||    -a / -revealAll          - Reveal whole map (default option)                     ||' + sLineBreak +
    '||    -p / -revealPlayers      - Reveal what players will see                          ||' + sLineBreak +
    '||    -m / -revealByMapSetting - Reveal according to the map setting `BlockMapPreview` ||' + sLineBreak +
    '||    -o / -outputFile         - Sets path to the output file                          ||' + sLineBreak +
    '||                                                                                     ||' + sLineBreak +
    '||  Examples:                                                                          ||' + sLineBreak +
    '||    MapUtil /NewMission/NewMission.dat                                               ||' + sLineBreak +
    '||    MapUtil -o image.png /NewMission/NewMission.dat                                  ||' + sLineBreak +
    '||    MapUtil -p /NewMission/NewMission.dat -o image.png                               ||' + sLineBreak +
    '||                                                                                     ||' + sLineBreak +
    '||=====================================================================================||' + sLineBreak;


implementation
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  SysUtils, Classes,
  {$IFDEF WDC}
  IOUtils,
  {$ENDIF}
  {$IFDEF FPC}
  LazFileUtils,
  {$ENDIF}
  KM_Maps, KM_Resource, KM_IoPNG,
  KM_CommonUtils, KM_Log;


{ TConsoleMain }
constructor TConsoleMain.Create;
begin
  inherited;

  fMinimap := TKMMinimapMission.Create(True);

  gRes := TKMResource.Create(nil, nil);
  gRes.LoadMainResources;
end;


destructor TConsoleMain.Destroy;
begin
  FreeAndNil(fMinimap);
  //@Rey: We might need to free what we have created
  //todo: FreeAndNil(gRes);
  //todo: FreeAndNil(gLog);

  inherited;
end;


procedure TConsoleMain.GenerateAndSaveMapMinimapImage(const aMapDatPath: string; aFowType: TFOWType; const aOutputFile: string);
var
  mapName, dir, pngFile: string;
  map: TKMMapInfo;
  doRevealAll: Boolean;
begin
  gLog.AddTime('generating png for a map ' + aMapDatPath);

  {$IFDEF WDC}
  mapName := TPath.GetFileNameWithoutExtension(aMapDatPath);
  {$ENDIF}
  {$IFDEF FPC}
  mapName := ExtractFileNameOnly(aMapDatPath);
  {$ENDIF}

  dir := ExtractFileDir(aMapDatPath) + PathDelim;

  map := TKMMapInfo.Create(dir, mapName, False);
  if not map.IsValid then
    raise Exception.Create('Map is not valid!');

  map.TxtInfo.LoadTXTInfo(ChangeFileExt(aMapDatPath, '.txt'));

  fMinimap.LoadFromMission(aMapDatPath, map.HumanUsableLocs);

  doRevealAll := True;
  case aFowType of
    ftRevealAll:      doRevealAll := True;
    ftRevealPlayers:  doRevealAll := False;
    ftMapSetting:     doRevealAll := not (map.IsSinglePlayer or map.TxtInfo.BlockFullMapPreview);
  end;

  fMinimap.Update(doRevealAll);

//  fMinimap.ConvertToBGR;

  if aOutputFile = '' then
    pngFile := ChangeFileExt(aMapDatPath, '.png')
  else
    pngFile := aOutputFile;

  SaveToFile(pngFile);
  gLog.AddTime('generated file: ' + pngFile);

  map.Free;
end;


procedure TConsoleMain.SaveToFile(const aFileName: string);
begin
  SaveToPng(fMinimap.MapX, fMinimap.MapY, fMinimap.Base, aFileName);
end;


procedure TConsoleMain.Start(const aParameterRecord: TCLIParamRecord);
begin
  GenerateAndSaveMapMinimapImage(aParameterRecord.MapDatPath, aParameterRecord.FOWType, aParameterRecord.OutputFile);
end;


procedure TConsoleMain.ShowHelp;
begin
  Writeln(MAPUTIL_HELP_TEXT);
end;


end.

