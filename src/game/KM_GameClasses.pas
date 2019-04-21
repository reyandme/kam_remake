unit KM_GameClasses;
interface
uses
  KM_Minimap,
  KM_CommonClasses;

type
  TKMGameLclDataLoadMinimapFn = reference to function(aStartLoc: Integer): Boolean;

  //MP Game local data, which should not be transfered over net (for different reasons described below)
  TKMGameMPLocalData = class
  private
    fLastReplayTick: Cardinal; //we can't put it into game, since this tick could be different for every player and we will get different save files CRC
    fStartLoc: Integer; //Starting loc is used to check if we are allowed to load minimap. F.e. we do not need to load minimap if we changed loc to other after back to lobby
    fMinimap: TKMMinimap; //Minimap could be unique for each player, then we can't save it to game it too
  public
    constructor Create; overload;
    constructor Create(aLastReplayTick: Cardinal; aStartLoc: Integer; aMinimap: TKMMinimap); overload;

    property LastReplayTick: Cardinal read fLastReplayTick write fLastReplayTick;

    procedure Save(aSaveStream: TKMemoryStream);
    procedure Load(aLoadStream: TKMemoryStream; aMinimap: TKMMinimap = nil);

    procedure SaveToFile(aFilePath: String);
    function LoadFromFile(aFilePath: String; aLoadMinimapFn: TKMGameLclDataLoadMinimapFn = nil): Boolean;
  end;

implementation
uses
  SysUtils;


constructor TKMGameMPLocalData.Create;
begin
  Create(0, -1, nil);
end;


constructor TKMGameMPLocalData.Create(aLastReplayTick: Cardinal; aStartLoc: Integer; aMinimap: TKMMinimap);
begin
  inherited Create;

  fLastReplayTick := aLastReplayTick;
  fStartLoc := aStartLoc;
  fMinimap := aMinimap;
end;


procedure TKMGameMPLocalData.Save(aSaveStream: TKMemoryStream);
begin
  aSaveStream.Write(fLastReplayTick);
  aSaveStream.Write(fStartLoc);
  if fMinimap <> nil then
    fMinimap.SaveToStream(aSaveStream);
end;


procedure TKMGameMPLocalData.Load(aLoadStream: TKMemoryStream; aMinimap: TKMMinimap = nil);
begin
  aLoadStream.Read(fLastReplayTick);
  aLoadStream.Read(fStartLoc);

  if aMinimap <> nil then
    aMinimap.LoadFromStream(aLoadStream);
end;


procedure TKMGameMPLocalData.SaveToFile(aFilePath: String);
var
  SaveStream: TKMemoryStream;
begin
  SaveStream := TKMemoryStream.Create;
  try
    Save(SaveStream);
    SaveStream.SaveToFile(aFilePath);
  finally
    SaveStream.Free;
  end;
end;


function TKMGameMPLocalData.LoadFromFile(aFilePath: String; aLoadMinimapFn: TKMGameLclDataLoadMinimapFn = nil): Boolean;
var
  LoadStream: TKMemoryStream;
begin
  Result := False;
  if FileExists(aFilePath) then
  begin
    LoadStream := TKMemoryStream.Create;
    try
      LoadStream.LoadFromFile(aFilePath);

      if Assigned(aLoadMinimapFn) and aLoadMinimapFn(fStartLoc) then
      begin
        Load(LoadStream, fMinimap);
        Result := True;
      end else
        Load(LoadStream);
    finally
      LoadStream.Free;
    end;
  end;
end;


end.