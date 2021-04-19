unit KM_Entity;
interface
uses
  KM_CommonClasses;

type
  TKMEntity = class abstract
  private
    fUID: Integer; //unique entity ID
  protected
    function GetUID: Integer;
    procedure SetUID(aUID: Integer);
  public
    constructor Create(aUID: Integer);
    constructor Load(LoadStream: TKMemoryStream); virtual;
    procedure Save(SaveStream: TKMemoryStream); virtual;

    property UID: Integer read GetUID;

    function ObjToString(const aSeparator: String = '|'): String; virtual;
    function ObjToStringShort(const aSeparator: String = '|'): String; virtual;
  end;

const
  NO_ENTITY_UID = 0;


implementation
uses
  SysUtils;


constructor TKMEntity.Create(aUID: Integer);
begin
  inherited Create;

  fUID := aUID;
end;


constructor TKMEntity.Load(LoadStream: TKMemoryStream);
begin
  inherited Create;

  LoadStream.CheckMarker('Entity');
  LoadStream.Read(fUID);
end;


procedure TKMEntity.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.PlaceMarker('Entity');
  SaveStream.Write(fUID);
end;


procedure TKMEntity.SetUID(aUID: Integer);
begin
  fUID := aUID;
end;


function TKMEntity.GetUID: Integer;
begin
  if Self = nil then Exit(NO_ENTITY_UID); // Exit with 0, if object is not set. Good UID is always > 0

  Result := fUID;
end;


function TKMEntity.ObjToStringShort(const aSeparator: String = '|'): String;
begin
  Result := Format('UID = %d', [UID]);
end;


function TKMEntity.ObjToString(const aSeparator: String = '|'): String;
begin
  Result := ObjToStringShort(aSeparator);
end;


end.
