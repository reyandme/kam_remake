unit KM_GameUIDTracker;
interface
uses
  KM_CommonClasses;

type
  TKMGameUIDTracker = class
  private
    fUIDTracker: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    constructor Load(LoadStream: TKMemoryStream);
    procedure Save(SaveStream: TKMemoryStream);

    function GetNewUID: Integer;
  end;

var
  gGameUIDTracker: TKMGameUIDTracker;


implementation


{ TKMGameUIDTracker }
constructor TKMGameUIDTracker.Create;
begin
  inherited;

  fUIDTracker := 0;

  gGameUIDTracker := Self;
end;


destructor TKMGameUIDTracker.Destroy;
begin
  gGameUIDTracker := nil;

  inherited;
end;


constructor TKMGameUIDTracker.Load(LoadStream: TKMemoryStream);
begin
  inherited Create;

  LoadStream.Read(fUIDTracker);

//  gGameUIDTracker := Self;
end;


procedure TKMGameUIDTracker.Save(SaveStream: TKMemoryStream);
begin
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
