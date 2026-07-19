unit KM_GameUIDTracker;
{$I KaM_Remake.inc}
interface
uses
  KM_CommonClasses;

type
  // Units-Houses tracker, to issue unique IDs
  TKMGameUIDTracker = class
  private
    fUIDTracker: Integer;
  public
    constructor Create;

    procedure Load(LoadStream: TKMemoryStream);
    procedure Save(SaveStream: TKMemoryStream);

    function GetNewUID: Integer;
  end;

var
  gUIDTracker: TKMGameUIDTracker;


implementation


{ TKMGameUIDTracker }
constructor TKMGameUIDTracker.Create;
begin
  inherited;

  fUIDTracker := 0;
end;


procedure TKMGameUIDTracker.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.CheckMarker('UIDTracker');
  LoadStream.Read(fUIDTracker);
end;


procedure TKMGameUIDTracker.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.PlaceMarker('UIDTracker');
  SaveStream.Write(fUIDTracker);
end;


function TKMGameUIDTracker.GetNewUID: Integer;
const
  //Prime numbers let us generate sequence of non-repeating values of max_value length
  MAX_VALUE = 16777213;
  STEP = 8765423;
begin
  //UIDs have the following properties:
  // - allow -1 to indicate no UID (const UID_NONE = -1)
  // - fit within 24bit (we can use that much for RGB colorcoding in unit picking)
  // - Start from 1, so that black colorcode can be detected in render and then re-mapped to -1

  fUIDTracker := (fUIDTracker + STEP) mod MAX_VALUE + 1; //1..N range, 0 is nothing for colorpicker
  Result := fUIDTracker;
end;


end.
