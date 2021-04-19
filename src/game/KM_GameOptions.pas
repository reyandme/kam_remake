unit KM_GameOptions;
{$I KaM_Remake.inc}
interface
uses
  KM_CommonClasses, KM_MapTypes;


type
  //Game options set in MP lobby
  //(maybe later we could use some of these for SP games too)
  TKMGameOptions = class
  public
    Peacetime: Word; //Peacetime in minutes
    SpeedPT: Single; //Game speed during peacetime
    SpeedAfterPT: Single; //Game speed after peacetime (usually slower)
    RandomSeed: Integer;
    MissionDifficulty: TKMMissionDifficulty;
    constructor Create;
    procedure Reset;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    function ToString: string; reintroduce;
  end;


implementation
uses
  SysUtils, TypInfo, KM_Defaults;


{ TKMGameOptions }
constructor TKMGameOptions.Create;
begin
  inherited;

  //Default values are not always 0
  Reset;
end;


//Resets values to defaults
procedure TKMGameOptions.Reset;
begin
  Peacetime := DEFAULT_PEACE_TIME;
  SpeedPT := 1;
  SpeedAfterPT := 1;
  RandomSeed := 0; //Must be init later on. 0 is an erroneous value for KaMSeed
  MissionDifficulty := mdNone;
end;


procedure TKMGameOptions.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.Read(Peacetime);
  LoadStream.Read(SpeedPT);
  LoadStream.Read(SpeedAfterPT);
  LoadStream.Read(RandomSeed);
  LoadStream.Read(MissionDifficulty, SizeOf(MissionDifficulty));
end;


procedure TKMGameOptions.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.Write(Peacetime);
  SaveStream.Write(SpeedPT);
  SaveStream.Write(SpeedAfterPT);
  SaveStream.Write(RandomSeed);
  SaveStream.Write(MissionDifficulty, SizeOf(MissionDifficulty));
end;


function TKMGameOptions.ToString: string;
begin
  Result := Format('PT = %d; SpeedPT = %s; SpeedAfterPT = %s; Seed = %d; Difficulty = %s',
                   [Peacetime, FormatFloat('0.##', SpeedPT), FormatFloat('0.##', SpeedAfterPT),
                    RandomSeed, GetEnumName(TypeInfo(TKMMissionDifficulty), Integer(MissionDifficulty))]);
end;


end.
