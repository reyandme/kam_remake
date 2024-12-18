unit KM_HandEntity;
{$I KaM_Remake.inc}
interface
uses
  KM_Defaults, KM_Points, KM_CommonClasses, KM_HandTypes, KM_Entity, KromOGLUtils;

type
  // Common class for TKMUnit / TKMHouse / TKMUnitGroup
  // "class abstract" disallows anyone from creating an instance of it (can create only child classes)
  TKMHandEntity = class abstract(TKMEntity)
  private
    fType: TKMHandEntityType;
    fOwner: TKMHandID;
    fAllowAllyToSelect: Boolean; // Allow ally to select entity
    function GetOwner: TKMHandID; inline;
    function GetType: TKMHandEntityType;
  protected
    function GetPositionForDisplayF: TKMPointF; virtual; abstract;

    procedure SetOwner(const aOwner: TKMHandID); virtual;
    function GetAllowAllyToSelect: Boolean; virtual;
    procedure SetAllowAllyToSelect(aAllow: Boolean); virtual;

    function GetIsSelectable: Boolean; virtual; abstract;
  public
    constructor Create(aType: TKMHandEntityType; aUID: Integer; aOwner: TKMHandID);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure Save(SaveStream: TKMemoryStream); override;

    property EntityType: TKMHandEntityType read GetType;
    property Owner: TKMHandID read GetOwner write SetOwner;

    property PositionForDisplayF: TKMPointF read GetPositionForDisplayF;

    property AllowAllyToSelect: Boolean read GetAllowAllyToSelect write SetAllowAllyToSelect;

    property IsSelectable: Boolean read GetIsSelectable;

    function IsUnit: Boolean;
    function IsGroup: Boolean;
    function IsHouse: Boolean;

    function ObjToStringBasic(const aSeparator: String = '|'): String;
    function ObjToString(const aSeparator: String = '|'): String; override;
    function ObjToStringShort(const aSeparator: String = '|'): String; override;
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

    function ObjToString(const aSeparator: String = '|'): String; override;
  end;

  TKMHighlightEntity = record
    Entity: TKMHandEntity;
    Color: TColor4;
    constructor New(aEntity: TKMHandEntity); overload;
    constructor New(aEntity: TKMHandEntity; aColor: TColor4); overload;

    procedure SetEntity(aEntity: TKMHandEntity);
    procedure SetColor(aColor: TColor4);

    function IsSet: Boolean;
    procedure Reset;
  end;

const
  DEFAULT_HIGHLIGHT_COL = icCyan;


implementation
uses
  SysUtils, KM_GameParams,
  KM_CommonExceptions;


{ TKMHandEntity }
constructor TKMHandEntity.Create(aType: TKMHandEntityType; aUID: Integer; aOwner: TKMHandID);
begin
  inherited Create(aUID);

  fType := aType;
  fOwner := aOwner;
  fAllowAllyToSelect := False; // Entity view for allies is blocked by default
end;


constructor TKMHandEntity.Load(LoadStream: TKMemoryStream);
begin
  inherited;

  LoadStream.Read(fType, SizeOf(fType));
  LoadStream.Read(fOwner, SizeOf(fOwner));
  LoadStream.Read(fAllowAllyToSelect);
end;


procedure TKMHandEntity.Save(SaveStream: TKMemoryStream);
begin
  inherited;

  SaveStream.Write(fType, SizeOf(fType));
  SaveStream.Write(fOwner, SizeOf(fOwner));
  SaveStream.Write(fAllowAllyToSelect);
end;


procedure TKMHandEntity.SetAllowAllyToSelect(aAllow: Boolean);
begin
  fAllowAllyToSelect := aAllow;
end;


function TKMHandEntity.GetAllowAllyToSelect: Boolean;
begin
  Result := ALLOW_SELECT_ALLIES and fAllowAllyToSelect;
end;


function TKMHandEntity.GetOwner: TKMHandID;
begin
  if Self = nil then Exit(HAND_NONE);

  Result := fOwner;
end;


function TKMHandEntity.GetType: TKMHandEntityType;
begin
  if Self = nil then Exit(etNone);

  Result := fType;
end;


function TKMHandEntity.IsUnit: Boolean;
begin
  if Self = nil then Exit(False);
  
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


procedure TKMHandEntity.SetOwner(const aOwner: TKMHandID);
begin
  fOwner := aOwner;
end;


function TKMHandEntity.ObjToStringBasic(const aSeparator: String = '|'): String;
begin
  Result := Format('UID = %d%sPos = %s', [UID, aSeparator, PositionForDisplayF.ToString]);
end;


function TKMHandEntity.ObjToStringShort(const aSeparator: String = '|'): String;
begin
  Result := inherited ObjToStringShort(aSeparator) +
            Format('%sPos = %s', [aSeparator, PositionForDisplayF.ToString]);
end;


function TKMHandEntity.ObjToString(const aSeparator: String = '|'): String;
begin
  Result := inherited ObjToString(aSeparator) +
            Format('%sOwner = %d%sPositionF = %s%sAllowAllyToSel = %s',
                   [aSeparator,
                    Owner, aSeparator,
                    PositionForDisplayF.ToString, aSeparator,
                    BoolToStr(AllowAllyToSelect, True)]);
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


function TKMHandEntityPointer<T>.ObjToString(const aSeparator: String = '|'): String;
begin
  Result := inherited ObjToString(aSeparator) + Format('%sPointerCnt = %d', [aSeparator, fPointerCount]);
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
        ErrorMsg := ErrorMsg + IntToStr(UID) + ' Pos = ' + PositionForDisplayF.ToString;
    end;
    raise ELocError.Create(ErrorMsg, KMPointRound(PositionForDisplayF));
  end;

  Dec(fPointerCount);
end;


{ TKMHighlightEntity }
constructor TKMHighlightEntity.New(aEntity: TKMHandEntity; aColor: TColor4);
begin
  Entity := aEntity;
  Color := aColor;
end;


constructor TKMHighlightEntity.New(aEntity: TKMHandEntity);
begin
  Entity := aEntity;
  Color := DEFAULT_HIGHLIGHT_COL;
end;


function TKMHighlightEntity.IsSet: Boolean;
begin
  Result := Entity <> nil;
end;


procedure TKMHighlightEntity.Reset;
begin
  Entity := nil;
  Color := DEFAULT_HIGHLIGHT_COL;
end;


procedure TKMHighlightEntity.SetColor(aColor: TColor4);
begin
  Color := aColor;
end;


procedure TKMHighlightEntity.SetEntity(aEntity: TKMHandEntity);
begin
  Entity := aEntity;
end;


end.
