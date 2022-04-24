unit KM_MissionScript_Preview;
{$I KaM_Remake.inc}
interface
uses
  KM_MissionScript,
  KM_Defaults, KM_Points;


type
  TKMTilePreview = record
    TileID: Word;
    TileHeight: Byte; //Used for calculating light
    TileOwner: TKMHandID;
    Revealed: Boolean;
  end;

  TKMHandPreview = record
    Color: Cardinal;
    StartingLoc: TKMPoint;
    CanHuman, CanAI: Boolean;
  end;

  //Specially optimized mission parser for map previews
  TKMMissionParserPreview = class(TKMMissionParserCommon)
  private
    fMapX: Integer;
    fMapY: Integer;
    fHandPreview: array [0 .. MAX_HANDS-1] of TKMHandPreview;
    fMapPreview: array of TKMTilePreview;

    fRevealFor: array of TKMHandID;

    function GetTileInfo(X, Y: Integer): TKMTilePreview;
    function GetPlayerInfo(aIndex: Byte): TKMHandPreview;
    procedure LoadMapData(const aFileName: string);
  protected
    procedure ProcessCommand(CommandType: TKMCommandType; P: array of Integer; const TextParam: AnsiString = ''); override;
  public
    property MapPreview[X, Y: Integer]: TKMTilePreview read GetTileInfo;
    property PlayerPreview[aIndex: Byte]: TKMHandPreview read GetPlayerInfo;
    property MapX: Integer read fMapX;
    property MapY: Integer read fMapY;
    procedure LoadMission(const aFileName: string; const aRevealFor: array of TKMHandID); reintroduce;
  end;


implementation
uses
  Classes, SysUtils, Math,
  KM_TerrainUtils,
  KM_HandTypes,
  KM_Resource, KM_ResHouses, KM_ResUnits, KM_ResPalettes,
  KM_CommonClasses, KM_CommonUtils, KM_Utils,
  KM_ResTypes, KM_TerrainTypes;


{ TKMMissionParserPreview }
function TKMMissionParserPreview.GetTileInfo(X,Y: Integer): TKMTilePreview;
begin
  Result := fMapPreview[(Y-1)*fMapX + X-1];
end;


function TKMMissionParserPreview.GetPlayerInfo(aIndex: Byte): TKMHandPreview;
begin
  Result := fHandPreview[aIndex];
end;


// Load terrain data into liteweight structure, take only what we need for preview
procedure TKMMissionParserPreview.LoadMapData(const aFileName: string);
var
  I: Integer;
  S: TKMemoryStream;
  tileBasic: TKMTerrainTileBasic;
  gameRev: Integer;
begin
  if not FileExists(aFileName) then
    raise Exception.Create('Map file couldn''t be found');

  S := TKMemoryStreamBinary.Create;
  try
    gameRev := 0;
    S.LoadFromFile(aFileName);

    LoadMapHeader(S, fMapX, fMapY, gameRev);

    SetLength(fMapPreview, fMapX * fMapY);
     for I := 0 to fMapX * fMapY - 1 do
      begin
        ReadTileFromStream(S, tileBasic, gameRev);
        fMapPreview[I].TileID := tileBasic.BaseLayer.Terrain;
        fMapPreview[I].TileHeight := tileBasic.Height;

        // Fill in blanks
        fMapPreview[I].TileOwner := HAND_NONE;
        fMapPreview[I].Revealed := False;
      end;
  finally
    S.Free;
  end;
end;


procedure TKMMissionParserPreview.ProcessCommand(CommandType: TKMCommandType; P: array of Integer; const TextParam: AnsiString = '');

  function PointInMap(X, Y: Integer): Boolean;
  begin
    Result := InRange(X, 1, fMapX)
          and InRange(Y, 1, fMapY);
  end;

  procedure SetOwner(X,Y: Word);
  begin
    fMapPreview[X-1 + (Y-1)*fMapX].TileOwner := fLastHand;
  end;

  function RevealForPlayer(aPlayerIndex: TKMHandID): Boolean;
  var
    I: Integer;
  begin
    Result := False;
    for I := 0 to Length(fRevealFor)-1 do
    if (fRevealFor[I] = aPlayerIndex) then
      Exit(True);
  end;

  procedure RevealCircle(X,Y,Radius: Word);
  var
    I, K: Word;
  begin
    if not RevealForPlayer(fLastHand) then
      Exit;
    // Unknown which overload to take
    for I := Max(Integer(Y-Radius),1) to Min(Integer(Y+Radius),Integer(fMapY)) do
    for K := Max(Integer(X-Radius),1) to Min(Integer(X+Radius),Integer(fMapX)) do
    if (Sqr(X-K) + Sqr(Y-I)) <= Sqr(Radius) then
      fMapPreview[(I-1)*fMapX + K-1].Revealed := True;
  end;

var
  I, K: Integer;
  HA: THouseArea;
  valid: Boolean;
  loc: TKMPoint;
begin
  case CommandType of
    ctSetCurrPlayer:   fLastHand := P[0];

    ctSetHouse:        if InRange(P[0], Low(HOUSE_ID_TO_TYPE), High(HOUSE_ID_TO_TYPE))
                          and PointInMap(P[1]+1, P[2]+1) then
                        begin
                          RevealCircle(P[1]+1, P[2]+1, gResHouses[HOUSE_ID_TO_TYPE[P[0]]].Sight);
                          HA := gResHouses[HOUSE_ID_TO_TYPE[P[0]]].BuildArea;
                          for i:=1 to 4 do for k:=1 to 4 do
                            if HA[i,k]<>0 then
                              if InRange(P[1]+1+k-3, 1, fMapX) and InRange(P[2]+1+i-4, 1, fMapY) then
                                SetOwner(P[1]+1+k-3, P[2]+1+i-4);
                        end;

    ctSetMapColor:     if InRange(fLastHand, 0, MAX_HANDS-1) then
                          fHandPreview[fLastHand].Color := gResPalettes.DefaultPalette.Color32(P[0]);

    ctSetRGBColor:     if InRange(fLastHand, 0, MAX_HANDS-1) then
                          fHandPreview[fLastHand].Color := P[0] or $FF000000;

    ctCenterScreen:    if PointInMap(P[0]+1, P[1]+1) then
                          fHandPreview[fLastHand].StartingLoc := KMPoint(P[0]+1,P[1]+1);

    ctHumanPlayer:     //Default human player can be human, obviously
                        fHandPreview[P[0]].CanHuman := True;

    ctUserPlayer:      if P[0] = -1 then
                          fHandPreview[fLastHand].CanHuman := True
                        else
                          fHandPreview[P[0]].CanHuman := True;

    ctAIPlayer,
    ctAdvancedAIPlayer:if P[0] = -1 then
                          fHandPreview[fLastHand].CanAI := True
                        else
                          fHandPreview[P[0]].CanAI := True;
    ctSetRoad,
    ctSetField,
    ctSetWinefield,
    ctSetFieldStaged,
    ctSetWinefieldStaged:
                        if PointInMap(P[0]+1, P[1]+1) then
                          SetOwner(P[0]+1, P[1]+1);

    ctSetUnit:         if PointInMap(P[1]+1, P[2]+1) and
                          not (UNIT_OLD_ID_TO_TYPE[P[0]] in [ANIMAL_MIN..ANIMAL_MAX]) then //Skip animals
                        begin
                          SetOwner(P[1]+1, P[2]+1);
                          RevealCircle(P[1]+1, P[2]+1, gRes.Units[UNIT_OLD_ID_TO_TYPE[P[0]]].Sight);
                        end;

    ctSetStock:        if PointInMap(P[1]+1, P[2]+1) then
                        begin
                          //Set Store and roads below
                          ProcessCommand(ctSetHouse,[11,P[0]+1,P[1]+1]);
                          ProcessCommand(ctSetRoad, [   P[0]-2,P[1]+1]);
                          ProcessCommand(ctSetRoad, [   P[0]-1,P[1]+1]);
                          ProcessCommand(ctSetRoad, [   P[0]  ,P[1]+1]);
                        end;

    ctSetGroup:        if InRange(P[0], Low(UNIT_ID_TO_TYPE), High(UNIT_ID_TO_TYPE)) and (UNIT_ID_TO_TYPE[P[0]] <> utNone)
                          and PointInMap(P[1]+1, P[2]+1) then
                          for I := 0 to P[5] - 1 do
                          begin
                            loc := GetPositionInGroup2(P[1]+1,P[2]+1,TKMDirection(P[3]+1), I, P[4],fMapX,fMapY,valid);
                            if valid then
                            begin
                              SetOwner(loc.X,loc.Y);
                              RevealCircle(P[1]+1, P[2]+1, gRes.Units[UNIT_OLD_ID_TO_TYPE[P[0]]].Sight);
                            end;
                          end;

    ctClearUp:         begin
                          if (P[0] = 255) then
                          begin
                            if RevealForPlayer(fLastHand) then
                              for I := 0 to fMapX * fMapY - 1 do
                                fMapPreview[I].Revealed := True;
                          end
                          else if PointInMap(P[0]+1, P[1]+1) then
                            RevealCircle(P[0]+1, P[1]+1, P[2]);
                        end;
  end;
end;


// We use custom mission loader for speed (compare only used commands)
procedure TKMMissionParserPreview.LoadMission(const aFileName: string; const aRevealFor: array of TKMHandID);
const
  ALLOWED_COMMANDS: array [0..16] of AnsiString = (
    '!SET_MAP', '!SET_MAP_COLOR', '!SET_RGB_COLOR', '!SET_AI_PLAYER', '!SET_ADVANCED_AI_PLAYER', '!CENTER_SCREEN',
    '!SET_CURR_PLAYER', '!SET_HUMAN_PLAYER', '!SET_USER_PLAYER',
    '!SET_STREET', '!SET_FIELD', '!SET_WINEFIELD', '!SET_STOCK',
    '!SET_HOUSE', '!CLEAR_UP', '!SET_UNIT', '!SET_GROUP');
var
  I: Integer;
  fileText: AnsiString;
begin
  inherited LoadMission(aFileName);

  SetLength(fRevealFor, Length(aRevealFor));
  for I := Low(aRevealFor) to High(aRevealFor) do
    fRevealFor[I] := aRevealFor[I];

  FillChar(fHandPreview, SizeOf(fHandPreview), #0);
  for I := 0 to MAX_HANDS-1 do
    fHandPreview[I].Color := DEFAULT_PLAYERS_COLORS[I];

  fileText := ReadMissionFile(aFileName);
  if fileText = '' then
    raise Exception.Create('Script is empty');

  // We need to load map dimensions first, so that SetGroup could access map bounds
  LoadMapData(ChangeFileExt(fMissionFileName, '.map'));

  TokenizeScript(fileText, 6, ALLOWED_COMMANDS);
end;


end.
