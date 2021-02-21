unit KM_HandEntity;
interface
uses
  KM_Defaults, KM_Points, KM_CommonClasses, KM_HandTypes;

type
  { Common class for TKMUnit / TKMHouse / TKMUnitGroup }
  TKMHandEntity = class abstract
  private
    fUID: Integer; //unique entity ID
    fType: TKMHandEntityType;
    fOwner: TKMHandID;
    function GetUID: Integer;
    function GetOwner: TKMHandID;
    function GetType: TKMHandEntityType;
  protected
    procedure SetUID(aUID: Integer);
    function GetPosition: TKMPoint; virtual; abstract;
    function GetPositionF: TKMPointF; virtual; abstract;
    procedure SetPositionF(const aPositionF: TKMPointF); virtual; abstract;
    procedure SetOwner(const aOwner: TKMHandID); virtual;
  public
    constructor Create(aType: TKMHandEntityType; aUID: Integer; aOwner: TKMHandID);
    constructor Load(LoadStream: TKMemoryStream); virtual;
    procedure Save(SaveStream: TKMemoryStream); virtual;

    property EntityType: TKMHandEntityType read GetType;
    property Owner: TKMHandID read GetOwner write SetOwner;

    property UID: Integer read GetUID;
    property Position: TKMPoint read GetPosition;
    property PositionF: TKMPointF read GetPositionF write SetPositionF;

    function IsSelectable: Boolean; virtual;

    function IsUnit: Boolean;
    function IsGroup: Boolean;
    function IsHouse: Boolean;

    function ObjToString(const aSeparator: String = '|'): String; virtual;
    function ObjToStringShort(const aSeparator: String = '|'): String; virtual;
  end;

  TKMHandEntityPointer<T> = class abstract(TKMHandEntity)
  private
    fPointerCount: Cardinal;
  protected
    function GetInstance: T; virtual; abstract;
  public
    constructor Create(aType: TKMHandEntityType; aUID: Integer; aOwner: TKMHandID);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure Save(SaveStream: TKMemoryStream); override;

    function GetPointer: T; //Returns self and adds one to the pointer counter
    procedure ReleasePointer;  //Decreases the pointer counter
    property PointerCount: Cardinal read fPointerCount;
  end;


implementation
uses
  SysUtils, KM_GameParams,
  KM_CommonExceptions;


{ TKMHandEntity }
constructor TKMHandEntity.Create(aType: TKMHandEntityType; aUID: Integer; aOwner: TKMHandID);
begin
  inherited Create;

  fType := aType;
  fUID := aUID;
  fOwner := aOwner;
end;


constructor TKMHandEntity.Load(LoadStream: TKMemoryStream);
begin
  inherited Create;

  LoadStream.CheckMarker('Entity');
  LoadStream.Read(fUID);
  LoadStream.Read(fType, SizeOf(fType));
  LoadStream.Read(fOwner, SizeOf(fOwner));
end;


procedure TKMHandEntity.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.PlaceMarker('Entity');
  SaveStream.Write(fUID);
  SaveStream.Write(fType, SizeOf(fType));
  SaveStream.Write(fOwner, SizeOf(fOwner));
end;


function TKMHandEntity.GetOwner: TKMHandID;
begin
  if Self = nil then Exit(-1); //@Rey: Better to use constant here, e.g. HAND_NONE

  Result := fOwner;
end;


function TKMHandEntity.GetType: TKMHandEntityType;
begin
  if Self = nil then Exit(etNone);

  Result := fType;
end;


function TKMHandEntity.GetUID: Integer;
begin
  if Self = nil then Exit(NO_ENTITY_UID); // Exit with 0, if object is not set. Good UID is always > 0

  Result := fUID;
end;


function TKMHandEntity.IsUnit: Boolean;
begin
  //@Rey: Why no `if Self = nil` check here?
  
  Result := fType = etUnit;
end;


function TKMHandEntity.IsGroup: Boolean;
begin
  if Self = nil then Exit(False);

  Result := fType = etGroup;
end;


function TKMHandEntity.IsHouse: Boolean;
begin
  if Self = nil then Exit(False);

  Result := fType = etHouse;
end;


function TKMHandEntity.IsSelectable: Boolean;
begin
  Result := False;
end;


procedure TKMHandEntity.SetOwner(const aOwner: TKMHandID);
begin
  fOwner := aOwner;
end;


procedure TKMHandEntity.SetUID(aUID: Integer);
begin
  fUID := aUID;
end;


function TKMHandEntity.ObjToString(const aSeparator: String = '|'): String;
begin
  Result := ''; // stub implementation
end;


function TKMHandEntity.ObjToStringShort(const aSeparator: String = '|'): String;
begin
  Result := ''; // stub implementation
end;


{ TKMHandEntityPointer }
constructor TKMHandEntityPointer<T>.Create(aType: TKMHandEntityType; aUID: Integer; aOwner: TKMHandID);
begin
  inherited Create(aType, aUID, aOwner);

  fPointerCount := 0;
end;


constructor TKMHandEntityPointer<T>.Load(LoadStream: TKMemoryStream);
begin
  inherited;

  LoadStream.Read(fPointerCount);
end;


procedure TKMHandEntityPointer<T>.Save(SaveStream: TKMemoryStream);
begin
  inherited;

  SaveStream.Write(fPointerCount);
end;


// Returns self and adds on to the pointer counter
function TKMHandEntityPointer<T>.GetPointer: T;
begin
  Assert(gGameParams.AllowPointerOperations, 'GetPointer is not allowed outside of game tick update procedure, it could cause game desync');

  Inc(fPointerCount);
  Result := GetInstance;
end;


{Decreases the pointer counter}
//Should be used only by gHands for clarity sake
procedure TKMHandEntityPointer<T>.ReleasePointer;
var
  ErrorMsg: UnicodeString;
begin
  Assert(gGameParams.AllowPointerOperations, 'ReleasePointer is not allowed outside of game tick update procedure, it could cause game desync');

  if fPointerCount < 1 then
  begin
    ErrorMsg := 'Unit remove pointer for U: ';
    try
      ErrorMsg := ErrorMsg + ObjToStringShort(',');
    except
      on E: Exception do
        ErrorMsg := ErrorMsg + IntToStr(UID) + ' Pos = ' + Position.ToString;
    end;
    raise ELocError.Create(ErrorMsg, Position);
  end;

  Dec(fPointerCount);
end;


end.
